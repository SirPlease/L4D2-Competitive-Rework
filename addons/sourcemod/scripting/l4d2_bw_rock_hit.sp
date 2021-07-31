#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define DEBUG 0

#define GAMEDATA_FILE "l4d2_bw_rock_hit"
#define SIGNATURE_NAME "CTankRock::Detonate"

#define Z_TANK 8

#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

float
	g_fPainPillsDecayRate = 0.0;

int
	g_iSurvivorMaxIncapCount = 0,
	g_iVsTankDamage = 0;

ConVar
	g_hSurvivorMaxIncapCount = null,
	g_hVsTankDamage = null,
	g_hPainPillsDecayRate = null;

bool
	g_bLateLoad = false;

Handle
	g_hTankRockDetonate = null;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public Plugin myinfo =
{
	name = "L4D2 Black&White Rock Hit",
	author = "Visor, A1m`",
	description = "Stops rocks from passing through soon-to-be-dead Survivors",
	version = "1.2",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	InitGameData();

	g_hSurvivorMaxIncapCount = FindConVar("survivor_max_incapacitated_count");
	g_hVsTankDamage = FindConVar("vs_tank_damage");
	g_hPainPillsDecayRate = FindConVar("pain_pills_decay_rate");
	
	CvarsToType();

	g_hSurvivorMaxIncapCount.AddChangeHook(CvarsChanged);

#if DEBUG
	RegConsoleCmd("sm_detonate_rock", Cmd_DetonateRock);
#endif

	if (g_bLateLoad) {
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i)) {
				OnClientPutInServer(i);
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

	StartPrepSDKCall(SDKCall_Entity);
	
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, SIGNATURE_NAME)) {
		SetFailState("Function '%s' not found", SIGNATURE_NAME);
	}
	
	g_hTankRockDetonate = EndPrepSDKCall();
	
	if (g_hTankRockDetonate == INVALID_HANDLE) {
		SetFailState("Function '%s' found, but something went wrong", SIGNATURE_NAME);
	}

	delete hGameData;
}

public void CvarsChanged(ConVar hConVar, const char[] oldValue, const char[] newValue)
{
	CvarsToType();
}

void CvarsToType()
{
	g_iSurvivorMaxIncapCount = g_hSurvivorMaxIncapCount.IntValue;
	g_iVsTankDamage = g_hVsTankDamage.IntValue;
	g_fPainPillsDecayRate = g_hPainPillsDecayRate.FloatValue;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if (damagetype != DMG_CLUB || !IsTankRock(inflictor)) {
		return Plugin_Continue;
	}
	
	if (!IsSurvivor(victim)/* || !IsTank(attacker)*/) {
		return Plugin_Continue;
	}
	
#if DEBUG
	char classname[64];
	GetEdictClassname(inflictor, classname, sizeof(classname));
	PrintToChatAll("Victim %d attacker %d inflictor %d damageType %d weapon %d", victim, attacker, inflictor, damagetype, weapon);
	PrintToChatAll("Victim %N(%i/%i) attacker %N classname %s", victim, GetSurvivorPermanentHealth(victim), GetSurvivorTemporaryHealth(victim), attacker, classname);
#endif

	// Not b&w
	if (!IsOnCriticalStrike(victim)) {
		return Plugin_Continue;
	}
	
	// Gotcha
	if (GetSurvivorTemporaryHealth(victim) <= g_iVsTankDamage) {
		// SDKHooks_TakeDamage(inflictor, attacker, attacker, 300.0, DMG_CLUB, GetActiveWeapon(victim));
		// AcceptEntityInput(inflictor, "Kill");
		// StopSound(attacker, SNDCHAN_AUTO, "player/tank/attack/thrown_missile_loop_1.wav");
		CTankRock__Detonate(inflictor);
	}

	return Plugin_Continue;
}

int GetSurvivorTemporaryHealth(int client)
{
	int temphp = RoundToCeil(GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * g_fPainPillsDecayRate)) - 1;
	return (temphp > 0 ? temphp : 0);
}

bool IsOnCriticalStrike(int client)
{
	return (g_iSurvivorMaxIncapCount == GetEntProp(client, Prop_Send, "m_currentReviveCount"));
}

bool IsSurvivor(int client)
{
	return (client > 0
		&& client <= MaxClients
		&& IsClientInGame(client)
		&& GetClientTeam(client) == TEAM_SURVIVOR);
}

/*bool IsTank(int client)
{
	return (client > 0
		&& client <= MaxClients
		&& IsClientInGame(client)
		&& GetClientTeam(client) == TEAM_INFECTED 
		&& GetEntProp(client, Prop_Send, "m_zombieClass") == Z_TANK
		&& IsPlayerAlive(client));
}*/

bool IsTankRock(int entity)
{
	if (/*entity > 0 && */IsValidEntity(entity)) {
		char classname[64];
		GetEdictClassname(entity, classname, sizeof(classname));
		return (strcmp(classname, "tank_rock") == 0);
	}

	return false;
}

void CTankRock__Detonate(int iTankRock)
{
#if DEBUG
	PrintToChatAll("CTankRock__Detonate: %d", iTankRock);
#endif

	SDKCall(g_hTankRockDetonate, iTankRock);
}

#if DEBUG
public Action Cmd_DetonateRock(int client, int args)
{
	int iEntity = -1;
	while ((iEntity = FindEntityByClassname(iEntity, "tank_rock")) != -1) {
		int iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");

		CTankRock__Detonate(iEntity);
		
		if (iOwner > 0 && IsClientInGame(iOwner)) {
			PrintToChatAll("Owner: %N (%d). Tank rock %d detonate)", iOwner, iOwner, iEntity);
		} else {
			PrintToChatAll("Unknown owner: %d. Tank rock %d detonate)", iOwner, iEntity);
		}
	}

	return Plugin_Handled;
}

int GetSurvivorPermanentHealth(int client)
{
	if (GetEntProp(client, Prop_Send, "m_currentReviveCount") > 0) {
		return 0;
	}
	
	int iHealth = GetEntProp(client, Prop_Send, "m_iHealth");
	return (iHealth > 0) ? iHealth : 0;
}
#endif
