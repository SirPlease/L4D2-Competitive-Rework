#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colors>

#define GAMEDATA_FILE "l4d_tankpunchstuckfix"
#define SIGNATURE_NAME "CTerrorPlayer::WarpToValidPositionIfStuck"

#define DEBUG_MODE				0

#define TEAM_SPECTATOR			1
#define TEAM_SURVIVOR			2
#define TEAM_INFECTED			3

#define SEQ_FLIGHT_COACH		629
#define SEQ_FLIGHT_ELLIS		634
#define SEQ_FLIGHT_ROCHELLE		637
#define SEQ_FLIGHT_BILL			537
#define SEQ_FLIGHT_FRANCIS		540
#define SEQ_FLIGHT_ZOEY			546

#define TIMER_CHECKPUNCH		0.025		// interval for checking 'flight' of punched survivors
#define TIME_CHECK_UNTIL		0.5			// try this long to find a stuck-position, then assume it's OK

Handle
	g_hWarpToValidPositionSDKCall = null;

bool
	g_bLateLoad = false,
	g_bPlayerFlight[MAXPLAYERS + 1];		// is a player in (potentially stuckable) punched flight?

float
	g_fPlayerPunch[MAXPLAYERS + 1],			// when was the last tank punch on this player?
	g_fPlayerStuck[MAXPLAYERS + 1],			// when did the (potential) 'stuckness' occur?
	g_fPlayerLocation[MAXPLAYERS + 1][3];	// where was the survivor last during the flight?

ConVar
	g_hCvarDeStuckTime = null,				// convar: how long to wait and de-stuckify a punched player
	tpsf_debug_print = null;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public Plugin myinfo = 
{
	name = "Tank Punch Ceiling Stuck Fix",
	author = "Tabun, Visor, A1m`",
	description = "Fixes the problem where tank-punches get a survivor stuck in the roof.",
	version = "1.3",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	InitGameData();
	
	// cvars
	g_hCvarDeStuckTime = CreateConVar("sm_punchstuckfix_unstucktime", "1.0", "How many seconds to wait before detecting and unstucking a punched motionless player.", _, true, 0.05, false);
	tpsf_debug_print = CreateConVar("tpsf_debug_print", "1","Enable the Debug Print?", _, true, 0.0, true, 1.0);

	// hooks
	HookEvent("round_start", Event_Reset, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_Reset, EventHookMode_PostNoCopy);
	
#if DEBUG_MODE
	RegConsoleCmd("sm_warp_me", Cmd_WarpMe);
#endif

	// hook already existing clients if loading late
	if (g_bLateLoad) {
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i)) {
				OnClientPostAdminCheck(i);
			}
		}
	}
}

void InitGameData()
{
	Handle hGameData = LoadGameConfigFile(GAMEDATA_FILE);
	if (!hGameData) {
		SetFailState("Could not load gamedata/%s.txt", GAMEDATA_FILE);
	}

	StartPrepSDKCall(SDKCall_Player);
	
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, SIGNATURE_NAME)) {
		SetFailState("Function '%s' not found", SIGNATURE_NAME);
	}
	
	g_hWarpToValidPositionSDKCall = EndPrepSDKCall();
	
	if (g_hWarpToValidPositionSDKCall == null) {
		SetFailState("Function '%s' found, but something went wrong", SIGNATURE_NAME);
	}

	delete hGameData;
}

public void OnClientPostAdminCheck(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnMapEnd()
{
	fClearArrays();
}

public void Event_Reset(Event hEvent, const char[] name, bool dontBroadcast)
{
	fClearArrays();
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (damagetype != DMG_CLUB || !IsTankWeapon(inflictor)) {
		return Plugin_Continue;
	}
	
	if (!IsClientAndInGame(victim) || !IsSurvivor(victim)) {
		return Plugin_Continue;
	}
	
#if DEBUG_MODE
	PrintToChatAll("IsTankWeapon - victim: (%N) %d, attacker: (%N) %d, inflictor: %d, damage: %f, damagetype: %d", victim, victim, attacker, attacker, inflictor, damage, damagetype);
#endif

	// tank punched survivor, check the result
	fClearArrayIndex(victim);
	g_fPlayerPunch[victim] = GetTickedTime();
	
	CreateTimer(TIMER_CHECKPUNCH, Timer_CheckPunch, GetClientUserId(victim), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}

public Action Timer_CheckPunch(Handle hTimer, any userid)
{
	int client = GetClientOfUserId(userid);
	// stop the timer when we no longer have a proper client
	if (client < 1 || !IsSurvivor(client)) { 
		return Plugin_Stop; 
	}

	// stop the time if we're passed the time for checking
	if (GetTickedTime() - g_fPlayerPunch[client] > TIME_CHECK_UNTIL && g_fPlayerStuck[client]) {
		fClearStuckArrayIndex(client);
		return Plugin_Stop;
	}

	// get current animation frame and location of survivor
	int iSeq = GetEntProp(client, Prop_Send, "m_nSequence");

	// if the player is not in flight, check if they are
	if (iSeq == SEQ_FLIGHT_COACH || iSeq == SEQ_FLIGHT_ELLIS
		|| iSeq == SEQ_FLIGHT_ROCHELLE || iSeq == SEQ_FLIGHT_BILL
		|| iSeq == SEQ_FLIGHT_FRANCIS || iSeq == SEQ_FLIGHT_ZOEY
	) {
		static float vOrigin[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", vOrigin);
		
		if (!g_bPlayerFlight[client]) {
			// if the player is not detected as in punch-flight, they are now
			g_bPlayerFlight[client] = true;
			g_fPlayerLocation[client] = vOrigin;
			
			#if DEBUG_MODE
				PrintDebug("[test] %i - flight start [seq:%4i][loc:%.f %.f %.f]", client, iSeq, vOrigin[0], vOrigin[1], vOrigin[2]);
			#endif
			
		} else {
			// if the player is in punch-flight, check location / difference to detect stuckness
			if (GetVectorDistance(g_fPlayerLocation[client], vOrigin) == 0.0) {
				// are we /still/ in the same position? (ie. if stucktime is recorded)
				if (g_fPlayerStuck[client]) {
					g_fPlayerStuck[client] = GetTickedTime();
					
					#if DEBUG_MODE
						PrintDebug("[test] %i - stuck start [loc:%.f %.f %.f]", client, vOrigin[0], vOrigin[1], vOrigin[2]);
					#endif
					
				} else {
					if (GetTickedTime() - g_fPlayerStuck[client] > g_hCvarDeStuckTime.FloatValue) {
						// time passed, player is stuck! fix.
						
						#if DEBUG_MODE
							PrintDebug("[test] %i - stuckness FIX triggered!", client);
						#endif
						
						fClearStuckArrayIndex(client);
						
						CTerrorPlayer_WarpToValidPositionIfStuck(client);
						if (tpsf_debug_print.BoolValue) {
							CPrintToChatAll("<{olive}TankPunchStuck{default}> Found {blue}%N{default} stuck after a punch. Warped him to a valid position.", client);
						}
						return Plugin_Stop;
					}
				}
			} else {
				// if we were detected as stuck, undetect
				if (g_fPlayerStuck[client]) {
					g_fPlayerStuck[client] = 0.0;
					
					#if DEBUG_MODE
						PrintDebug("[test] %i - stuck end (previously detected, now gone) [loc:%.f %.f %.f]", client, vOrigin[0], vOrigin[1], vOrigin[2]);
					#endif
				}
			}
		}
	} else if (iSeq == (SEQ_FLIGHT_COACH + 1) ||  iSeq == (SEQ_FLIGHT_ELLIS + 1)
		|| iSeq == (SEQ_FLIGHT_ROCHELLE + 1) ||  iSeq == (SEQ_FLIGHT_BILL + 1)
		|| iSeq == (SEQ_FLIGHT_FRANCIS + 1) ||  iSeq == (SEQ_FLIGHT_ZOEY + 1)
	) {
		if (g_bPlayerFlight[client]) {
			// landing frame, so not stuck
			fClearStuckArrayIndex(client);
			
			#if DEBUG_MODE
				PrintDebug("[test] %i - flight end (natural)", client);
			#endif
		}
		
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

bool IsClientAndInGame(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

bool IsSurvivor(int client)
{
	return (GetClientTeam(client) == TEAM_SURVIVOR);
}

bool IsTankWeapon(int entity)
{
	if (IsValidEntity(entity)) {
		char eName[32];
		GetEntityClassname(entity, eName, sizeof(eName));
		return (strcmp("weapon_tank_claw", eName) == 0/* || strcmp("tank_rock", eName) == 0*/);
	}

	return false;
}

void fClearArrays()
{
	for (int i = 0; i <= MAXPLAYERS; i++) {
		fClearArrayIndex(i);
	}
}

void fClearArrayIndex(int index)
{
	fClearStuckArrayIndex(index);
	for (int j = 0; j < 3; j++) {
		g_fPlayerLocation[index][j] = 0.0;
	}
}

void fClearStuckArrayIndex(int index)
{
	g_fPlayerPunch[index] = 0.0;
	g_bPlayerFlight[index] = false;
	g_fPlayerStuck[index] = 0.0;
}

void CTerrorPlayer_WarpToValidPositionIfStuck(int client)
{
	SDKCall(g_hWarpToValidPositionSDKCall, client, 0);
}

#if DEBUG_MODE
stock void PrintDebug(const char[] Message, any ...)
{
	char DebugBuff[256];
	VFormat(DebugBuff, sizeof(DebugBuff), Message, 2);
	//LogMessage(DebugBuff);
	//PrintToServer(DebugBuff);
	PrintToChatAll(DebugBuff);
}

public Action Cmd_WarpMe(int client, int args)
{
	if (client == 0 || !IsSurvivor(client) || !IsPlayerAlive(client)) {
		PrintToChat(client, "Only a living survivor can use this command!");
		return Plugin_Handled;
	}
	
	CTerrorPlayer_WarpToValidPositionIfStuck(client);
	PrintToChat(client, "WarpToValidPositionIfStuck call!");
	return Plugin_Handled;
}
#endif
