#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>

#define Z_JOCKEY			5

#define TEAM_SURVIVOR		2
#define TEAM_INFECTED		3

#define GAMEDATA			"l4d2_si_ability"
#define L4D2_MAXPLAYERS		32

enum struct eShovedInfo
{
	int eiUserId;
	float efBlockUntil;
}

ConVar g_hCvarJumpCapBlockTime = null;

Handle g_hCLeap_OnTouch = null;

eShovedInfo g_esShovedInfo[L4D2_MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = "L4D2 Jockey Jump-Cap Patch",
	author = "Visor, A1m`",
	description = "Prevent Jockeys from being able to land caps with non-ability jumps in unfair situations",
	version = "1.6",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	InitGameData();

	g_hCvarJumpCapBlockTime = CreateConVar(
		"l4d2_jumpcap_block_time",
		"3.0",
		"Sets the block duration for jockey jumpcaps (in seconds)", 
		_, true, 1.0, true, 10.0
	);

	HookEvent("round_start", Event_Reset, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_Reset, EventHookMode_PostNoCopy);
	HookEvent("player_shoved", Event_PlayerShoved);
}

void InitGameData()
{
	Handle hGamedata = LoadGameConfigFile(GAMEDATA);

	if (!hGamedata) {
		SetFailState("Gamedata '%s.txt' missing or corrupt.", GAMEDATA);
	}

	int iCleapOnTouchOffset = GameConfGetOffset(hGamedata, "CBaseAbility::OnTouch");
	if (iCleapOnTouchOffset == -1) {
		SetFailState("Failed to get offset 'CBaseAbility::OnTouch'.");
	}

	g_hCLeap_OnTouch = DHookCreate(iCleapOnTouchOffset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, CLeap_OnTouch);
	DHookAddParam(g_hCLeap_OnTouch, HookParamType_CBaseEntity);

	delete hGamedata;
}

void Event_Reset(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	for (int i = 0; i <= L4D2_MAXPLAYERS; i++) {
		g_esShovedInfo[i].eiUserId = 0;
		g_esShovedInfo[i].efBlockUntil = 0.0;
	}
}

public void OnEntityCreated(int iEntity, const char[] sClassName)
{
	if (strcmp(sClassName, "ability_leap") == 0) {
		DHookEntity(g_hCLeap_OnTouch, false, iEntity);
	}
}

void Event_PlayerShoved(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int iShover = GetClientOfUserId(hEvent.GetInt("attacker"));
	if (!IsSurvivor(iShover)) {
		return;
	}

	int iShoveeUserId = hEvent.GetInt("userid");
	int iShovee = GetClientOfUserId(iShoveeUserId);
	if (IsJockey(iShovee)) {
		g_esShovedInfo[iShovee].eiUserId = iShoveeUserId;
		g_esShovedInfo[iShovee].efBlockUntil = GetGameTime() + g_hCvarJumpCapBlockTime.FloatValue;
	}
}

MRESReturn CLeap_OnTouch(int iAbility, DHookParam hParams)
{
	int iJockey = GetEntPropEnt(iAbility, Prop_Send, "m_owner");
	if (!IsJockey(iJockey) || IsFakeClient(iJockey)) {
		return MRES_Ignored;
	}

	int iSurvivor = hParams.Get(1);
	if (!IsSurvivor(iSurvivor)) {
		return MRES_Ignored;
	}

	if (!IsAbilityActive(iAbility) && IsJumpBlocked(iJockey)) {
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

bool IsJumpBlocked(int iClient)
{
    return (g_esShovedInfo[iClient].eiUserId == GetClientUserId(iClient)
        && g_esShovedInfo[iClient].efBlockUntil >= GetGameTime());
}

bool IsAbilityActive(int iAbility)
{
	return (GetEntProp(iAbility, Prop_Send, "m_isLeaping", 1) > 0);
}

bool IsJockey(int iClient)
{
	return (iClient > 0
		&& iClient <= MaxClients
		&& IsClientInGame(iClient)
		&& GetClientTeam(iClient) == TEAM_INFECTED
		&& GetEntProp(iClient, Prop_Send, "m_zombieClass") == Z_JOCKEY);
}

bool IsSurvivor(int iClient)
{
	return (iClient > 0
		&& iClient <= MaxClients
		&& IsClientInGame(iClient)
		&& GetClientTeam(iClient) == TEAM_SURVIVOR);
}
