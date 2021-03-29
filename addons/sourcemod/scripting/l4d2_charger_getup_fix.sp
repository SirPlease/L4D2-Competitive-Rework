#include <sourcemod>
#include <left4dhooks>
#include <sdkhooks>
#include <godframecontrol>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "3.0.2"
#define DEBUG 0

public Plugin myinfo = 
{
	name = "[L4D2] Long Charger Get-Up Fix",
	author = "Spoon, Forgetest",
	description = "Allows control over long charger get ups, and fixes no get up on rare cases.",
	version = PLUGIN_VERSION,
	url = "https://github.com/spoon-l4d2"
};

// Charges that land against a wall and are cleared instantly
#define SEQ_INSTANT_NICK 671
#define SEQ_INSTANT_COACH 660
#define SEQ_INSTANT_ELLIS 675
#define SEQ_INSTANT_ROCHELLE 678
#define SEQ_INSTANT_ZOEY 823
#define SEQ_INSTANT_BILL 763
#define SEQ_INSTANT_LOUIS 763
#define SEQ_INSTANT_FRANCIS 766

// Charges charge all the way and are then cleared instantly
#define SEQ_LONG_NICK 672
#define SEQ_LONG_COACH 661
#define SEQ_LONG_ELLIS 676
#define SEQ_LONG_ROCHELLE 679
#define SEQ_LONG_ZOEY 824
#define SEQ_LONG_BILL 764
#define SEQ_LONG_LOUIS 764
#define SEQ_LONG_FRANCIS 767

#define ZC_JOCKEY 5
#define ZC_CHARGER 6
#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3
#define TEAM_SPECTATOR 1

// Cvars
ConVar cvar_longChargeGetUpFixEnabled;
//ConVar cvar_keepWallSlamLongGetUp;
ConVar cvar_keepLongChargeLongGetUp;

// Fake godframe event variables
ConVar g_hLongChargeDuration;
ConVar g_hChargeDuration;

// Variables
int ChargerTarget[MAXPLAYERS+1];
bool bLateLoad, bWallSlamed[MAXPLAYERS+1], bInForcedGetUp[MAXPLAYERS+1], bIgnoreJockeyed[MAXPLAYERS+1];


public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	bLateLoad = late;
}

public void OnPluginStart()
{
	// Event Hooks
	HookEvent("charger_killed", Event_ChargerKilled, EventHookMode_Post);
	HookEvent("charger_carry_start", Event_ChargeCarryStart, EventHookMode_Post);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("charger_pummel_start", Event_PummelStart, EventHookMode_Post);
	HookEvent("charger_pummel_end", Event_PummelStart, EventHookMode_Post);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);
	HookEvent("jockey_ride", Event_JockeyRide, EventHookMode_Pre);
	HookEvent("jockey_ride_end", Event_JockeyRideEnd, EventHookMode_Pre);
	HookEvent("player_bot_replace", Event_PlayerBotReplace, EventHookMode_Post);
	HookEvent("bot_player_replace", Event_BotPlayerReplace, EventHookMode_Post);
	
	g_hChargeDuration = FindConVar("gfc_charger_duration");
	g_hLongChargeDuration = CreateConVar("gfc_long_charger_duration", "2.2", "God frame duration for long charger getup animations");
	
	
	// Cvars
	cvar_longChargeGetUpFixEnabled = CreateConVar("charger_long_getup_fix", "1", "Enable the long Charger get-up fix?");
	//cvar_keepWallSlamLongGetUp = CreateConVar("charger_keep_wall_charge_animation", "1", "Enable the long wall slam animation (with god frames)");
	cvar_keepLongChargeLongGetUp = CreateConVar("charger_keep_far_charge_animation", "0", "Enable the long 'far' slam animation (with god frames)");


	if (bLateLoad)
		for (int i = 1; i <= MaxClients; i++)
			if (IsClientInGame(i)) OnClientPutInServer(i);
}

// ==========================================
// ================= Events =================
// ==========================================

public void OnClientPutInServer(int client)
{
	bWallSlamed[client] = false;
	bInForcedGetUp[client] = false;
	bIgnoreJockeyed[client] = false;
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
}

public void OnClientDisconnect(int client)
{
	bWallSlamed[client] = false;
	bInForcedGetUp[client] = false;
	bIgnoreJockeyed[client] = false;
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKUnhook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{	
	for (int i = 1; i <= MaxClients; i++)
	{
		bWallSlamed[i] = false;
		bInForcedGetUp[i] = false;
		bIgnoreJockeyed[i] = false;
		if (ChargerTarget[i] != -1)
			ChargerTarget[i] = -1;
	}
}

public void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{ // Wall Slam Charge Checks

	if (!GetConVarBool(cvar_longChargeGetUpFixEnabled)) return;

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client <= 0) return;
	int oldTeam = GetEventInt(event, "oldteam");
	
	if (oldTeam == TEAM_INFECTED)
	{ // Not really needed but better safe than sorry I guess
		ChargerTarget[client] = -1;
	}
	else if (oldTeam == TEAM_SURVIVOR)
	{
		bWallSlamed[client] = false;
		bInForcedGetUp[client] = false;
		bIgnoreJockeyed[client] = false;
		
		// Update ChargerTarget of disconnected client
		for (int i = 1; i <= MaxClients; i++)
		{
			if (ChargerTarget[i] == client)
			{
				// TODO: fix throwing errors
				// TODO: why is this asking for m_pummelVictim
				int newChargerTarget = GetEntDataEnt2(i, 15972); // m_pummelVictim
				ChargerTarget[i] = newChargerTarget;
			}
		}
	}
}

// ========================================================
// ================= No Get-up Workaround =================
// ========================================================

// NOTE:
// - In case like after being pounced, almost at the end of the get-up animation,
//   survivor seems to refuse another one from charge impact.

// - Get-up animation would stack before the pound section.

void PlayClientGetUpAnimation(int client)
{
	L4D2Direct_DoAnimationEvent(client, 78);
}

void CancelGetUpAnimation(int client)
{
	SetEntPropFloat(client, Prop_Send, "m_flCycle", 1000.0);
}

public Action Timer_Uncheck(Handle timer, int client)
{
	bWallSlamed[client] = false;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if (!inflictor || !IsValidEdict(victim) || !IsValidEdict(inflictor)) return;
	if (!IsCharger(attacker) || !IsSurvivor(victim)) return;
	
	static char classname[64];
	GetClientWeapon(attacker, classname, sizeof(classname));
	if (strcmp(classname, "weapon_charger_claw") != 0) return;
	
	if (damage == 10.0 && GetVectorLength(damageForce) == 0.0)
	{
		// CHARGE IMPACT
		bWallSlamed[victim] = true;
		
		// In case this damage is blocked
		// (barely happen since charger cannot impact one in godframe)
		CreateTimer(0.1, Timer_Uncheck, victim);
	}
}

public void OnTakeDamagePost(int victim, int attacker, int inflictor, float damage, int damagetype)
{
	if (bWallSlamed[victim])
	{
		bWallSlamed[victim] = false;
		
		if (IsSurvivor(victim) && IsPlayerAlive(victim) && !IsPlayerIncap(victim))
		{
			ChargerTarget[attacker] = victim;
			bInForcedGetUp[victim] = true;
			
			// Adds one get-up into stack
			PlayClientGetUpAnimation(victim);
		}
	}
}

// ==========================================
// ================= Events =================
// ==========================================

public void Event_PummelStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!GetConVarBool(cvar_longChargeGetUpFixEnabled)) return;

	int chargerClient = GetClientOfUserId(GetEventInt(event, "userid"));
	int survivorClient = GetClientOfUserId(GetEventInt(event, "victim"));
	
	if (survivorClient > 0 && chargerClient > 0)
	{
		ChargerTarget[chargerClient] = survivorClient;
		
		// Once a charge goes into the pound section, the get-up stack will be overridden.
		// Here uncheck our stuffs.
		bInForcedGetUp[survivorClient] = false;
		bIgnoreJockeyed[survivorClient] = false;
	}
}

public void Event_ChargerKilled(Event event, const char[] name, bool dontBroadcast)
{
	if (!GetConVarBool(cvar_longChargeGetUpFixEnabled)) return;

	int chargerClient = GetClientOfUserId(GetEventInt(event, "userid"));
	int survivorClient = ChargerTarget[chargerClient];

	if (survivorClient > 0 && chargerClient > 0)
	{
		#if DEBUG
			PrintToChatAll("\x05Event_ChargerKilled \x01- victim: \x05%N \x01| charger: \x05%N \x01| seq: \x05%i", survivorClient, chargerClient, GetEntProp(survivorClient, Prop_Send, "m_nSequence"));
		#endif
		if (bInForcedGetUp[survivorClient])
		{
			#if DEBUG
				PrintToChatAll("\x01> IgnoreJockeyed: \x05%i", bIgnoreJockeyed[survivorClient]);
			#endif
			bInForcedGetUp[survivorClient] = false;
			
			// NOTE:
			//
			// Overall, we should manually override the wall-slam get-ups from longer ones to normal ones,
			// or "l4d2_getupfix" will try to "fix" this, leading to multiple get-ups.
			//
			// However, here's a thing that jockeyed charges deal no get-up to survivors,
			// so situations should be the following:
			//
			//   1. Was the survivor charged when jockeyed?
			//        - We don't do anything here since a get-up was forced to the survivor.
			//        - Generous "l4d2_getupfix" can figure it out and stop the following fix action.
			//
			//   2. The opposite to (1), the normal happening ones.
			//        - We need to cancel the get-up added previously.
			//        - If it is wall-slam, we must override the animation to normal get-up one.
			
			if (!bIgnoreJockeyed[survivorClient])
			{
				CancelGetUpAnimation(survivorClient);
			}
		}
		
		if (IsPlayingGetUpAnimation(survivorClient, 2))
		{ // Long Charge Get Up		
			#if DEBUG
				PrintToChatAll("\x01> \x05Event_ChargerKilled \x01- \x04Long Charge");
			#endif
			if (GetConVarBool(cvar_keepLongChargeLongGetUp))
			{
				GiveClientGodFrames(survivorClient, GetConVarFloat(g_hChargeDuration), 6);
			}
			else
			{
				if (!bIgnoreJockeyed[survivorClient])
				{
					CancelGetUpAnimation(survivorClient);
					PlayClientGetUpAnimation(survivorClient);
				}
				GiveClientGodFrames(survivorClient, GetConVarFloat(g_hLongChargeDuration), 6);
			}
		} 
		else if (IsPlayingGetUpAnimation(survivorClient, 1))
		{ // Wall Slam Get Up
			#if DEBUG
				PrintToChatAll("\x01> \x05Event_ChargerKilled \x01- \x04Wall Slam");
			#endif
			if (!bIgnoreJockeyed[survivorClient])
			{
				CancelGetUpAnimation(survivorClient);
				PlayClientGetUpAnimation(survivorClient);
			}
			GiveClientGodFrames(survivorClient, GetConVarFloat(g_hLongChargeDuration), 6);
		}
		else
		{
			// There's a weird case, where the game won't register the client as playing the animation, it's once in a blue moon
			CreateTimer(0.02, BlueMoonCaseCheck, survivorClient);
			return;
		}
		
		ResetChargerTarget(chargerClient);
	}
}

void ResetChargerTarget(int chargerClient)
{
	ChargerTarget[chargerClient] = -1;
}

void ResetIgnoreJockeyed(int survivorClient)
{
	bIgnoreJockeyed[survivorClient] = false;
}

public Action BlueMoonCaseCheck(Handle timer, int survivorClient)
{
	#if DEBUG
		PrintToChatAll("\x05BlueMoonCaseCheck \x01- victim: \x05%N \x01| seq: \x05%i", survivorClient, GetEntProp(survivorClient, Prop_Send, "m_nSequence"));
	#endif
	if (IsPlayingGetUpAnimation(survivorClient, 2))
	{ // Long Charge Get Up
		#if DEBUG
			PrintToChatAll("\x01> \x05BlueMoonCaseCheck \x01- \x04Long Charge");
		#endif
		if (GetConVarBool(cvar_keepLongChargeLongGetUp))
		{
			GiveClientGodFrames(survivorClient, GetConVarFloat(g_hChargeDuration), 6);
		}
		else
		{
			if (!bIgnoreJockeyed[survivorClient])
			{
				CancelGetUpAnimation(survivorClient);
				PlayClientGetUpAnimation(survivorClient);
			}
			GiveClientGodFrames(survivorClient, GetConVarFloat(g_hLongChargeDuration), 6);
		}
	} 
	else if (IsPlayingGetUpAnimation(survivorClient, 1))
	{ // Wall Slam Get Up
		#if DEBUG
			PrintToChatAll("\x01> \x05BlueMoonCaseCheck \x01- \x04Wall Slam");
		#endif
		if (!bIgnoreJockeyed[survivorClient])
		{
			CancelGetUpAnimation(survivorClient);
			PlayClientGetUpAnimation(survivorClient);
		}
		GiveClientGodFrames(survivorClient, GetConVarFloat(g_hLongChargeDuration), 6);
	}
	
	ResetIgnoreJockeyed(survivorClient);
}

public void Event_ChargeCarryStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!GetConVarBool(cvar_longChargeGetUpFixEnabled)) return;

	int chargerClient = GetClientOfUserId(GetEventInt(event, "userid"));
	int survivorClient = GetClientOfUserId(GetEventInt(event, "victim"));
	
	if (survivorClient > 0 && chargerClient > 0)
	{
		#if DEBUG
			PrintToChatAll("\x05Event_ChargeCarryStart \x01- victim: \x05%N \x01| charger: \x05%N", survivorClient, chargerClient);
		#endif
		ChargerTarget[chargerClient] = survivorClient;
	}
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{ // Wall Slam Charge Checks

	if (!GetConVarBool(cvar_longChargeGetUpFixEnabled)) return;

	int survivorClient;
	int chargerClient;
	int survivorUserId =  GetEventInt(event, "userid");
	int chargerUserId = GetEventInt(event, "attacker");
	
	if (survivorUserId)
		survivorClient = GetClientOfUserId(survivorUserId);
	if (chargerUserId)
		chargerClient = GetClientOfUserId(chargerUserId);
		
	if (!IsCharger(chargerClient) || !IsSurvivor(survivorClient)) return;
	
	ChargerTarget[chargerClient] = survivorClient; 
}

public void Event_JockeyRide(Event event, const char[] name, bool dontBroadcast)
{
	int jockey = GetClientOfUserId(event.GetInt("userid"));
	int survivor = GetClientOfUserId(event.GetInt("victim"));
	
	if (jockey > 0 && survivor > 0)
	{
		bIgnoreJockeyed[survivor] = true;
		#if DEBUG
			PrintToChatAll("\x05Event_JockeyRide \x01- victim: \x05%N \x01| jockey: \x05%N \x01| ignore: \x05%i", survivor, jockey, bIgnoreJockeyed[survivor]);
		#endif
	}
}

public void Event_JockeyRideEnd(Event event, const char[] name, bool dontBroadcast)
{
	int jockey = GetClientOfUserId(event.GetInt("userid"));
	int survivor = GetClientOfUserId(event.GetInt("victim"));
	
	if (jockey > 0 && survivor > 0)
	{
		#if DEBUG
			PrintToChatAll("\x05Event_JockeyRideEnd \x01- victim: \x05%N \x01| jockey: \x05%N", survivor, jockey);
		#endif
		bIgnoreJockeyed[survivor] = false;
		
		#if DEBUG
			PrintToChatAll("\x01> ignore: \x05%i", bIgnoreJockeyed[survivor]);
		#endif
		// Fix when the ride end was due to a charge grab.
		for (int i = 1; i <= MaxClients; i++)
		{
			if (ChargerTarget[i] == survivor)
			{
				bIgnoreJockeyed[survivor] = true;
				#if DEBUG
					PrintToChatAll("\x01> ignore reverted due to charge grab. ChargerTarget[i]: \x05%i \x01| ignore: \x05%i", ChargerTarget[i], bIgnoreJockeyed[survivor]);
				#endif
				break;
			}
		}
	}
}

public void Event_PlayerBotReplace(Event event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(event.GetInt("player"));
	int bot = GetClientOfUserId(event.GetInt("bot"));
	
	if (player > 0 && bot > 0)
	{
		if (bIgnoreJockeyed[player] && IsJockeyed(bot))
		{
			bIgnoreJockeyed[bot] = true;
		}
		bIgnoreJockeyed[player] = false;
	}
}

public void Event_BotPlayerReplace(Event event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(event.GetInt("player"));
	int bot = GetClientOfUserId(event.GetInt("bot"));
	
	if (player > 0 && bot > 0)
	{
		if (bIgnoreJockeyed[bot] && IsJockeyed(player))
		{
			bIgnoreJockeyed[player] = true;
		}
		bIgnoreJockeyed[bot] = false;
	}
}


// ==========================================
// ================= Checks =================
// ==========================================

stock int GetSequenceInt(int client, int type)
{
	if (client < 1) return -1;

	char survivorModel[PLATFORM_MAX_PATH];
	GetClientModel(client, survivorModel, sizeof(survivorModel));
	
	if(StrEqual(survivorModel, "models/survivors/survivor_coach.mdl", false))
	{
		switch(type)
		{
			case 1: return SEQ_INSTANT_COACH;
			case 2: return SEQ_LONG_COACH;
		}
	}
	else if(StrEqual(survivorModel, "models/survivors/survivor_gambler.mdl", false))
	{
		switch(type)
		{
			case 1: return SEQ_INSTANT_NICK;
			case 2: return SEQ_LONG_NICK;
		}
	}
	else if(StrEqual(survivorModel, "models/survivors/survivor_producer.mdl", false))
	{
		switch(type)
		{
			case 1: return SEQ_INSTANT_ROCHELLE;
			case 2: return SEQ_LONG_ROCHELLE;
		}
	}
	else if(StrEqual(survivorModel, "models/survivors/survivor_mechanic.mdl", false))
	{
		switch(type)
		{
			case 1: return SEQ_INSTANT_ELLIS;
			case 2: return SEQ_LONG_ELLIS;
		}
	}
	else if(StrEqual(survivorModel, "models/survivors/survivor_manager.mdl", false))
	{
		switch(type)
		{
			case 1: return SEQ_INSTANT_LOUIS;
			case 2: return SEQ_LONG_LOUIS;
		}
	}
	else if(StrEqual(survivorModel, "models/survivors/survivor_teenangst.mdl", false))
	{
		switch(type)
		{
			case 1: return SEQ_INSTANT_ZOEY;
			case 2: return SEQ_LONG_ZOEY;
		}
	}
	else if(StrEqual(survivorModel, "models/survivors/survivor_namvet.mdl", false))
	{
		switch(type)
		{
			case 1: return SEQ_INSTANT_BILL;
			case 2: return SEQ_LONG_BILL;
		}
	}
	else if(StrEqual(survivorModel, "models/survivors/survivor_biker.mdl", false))
	{
		switch(type)
		{
			case 1: return SEQ_INSTANT_FRANCIS;
			case 2: return SEQ_LONG_FRANCIS;
		}
	}
	
	return -1;
}

bool IsPlayingGetUpAnimation(int survivor, int type)  
{
	if (survivor < 1)
		return false;

	int sequence = GetEntProp(survivor, Prop_Send, "m_nSequence");
	if (sequence == GetSequenceInt(survivor, type)) return true;
	return false;
}

stock bool IsCharger(int client)  
{
	if (!IsInfected(client))
		return false;

	if (GetEntProp(client, Prop_Send, "m_zombieClass") != ZC_CHARGER)
		return false;

	return true;
}

stock bool IsJockey(int client)
{
	if (!IsInfected(client))
		return false;
		
	if (GetEntProp(client, Prop_Send, "m_zombieClass") != ZC_JOCKEY)
		return false;

	return true;
}

stock bool IsJockeyed(int survivor)
{
	return IsJockey(GetJockeyAttacker(survivor));
}

stock int GetJockeyAttacker(int survivor)
{
	return GetEntDataEnt2(survivor, 16128);
}

stock bool IsPlayerIncap(int client)
{
	return !!GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

stock bool IsSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

stock bool IsInfected(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3;
}