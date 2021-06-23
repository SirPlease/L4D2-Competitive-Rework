#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>

#define Z_JOCKEY 5
#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

#define GAMEDATA "l4d2_si_ability"

Handle hCLeap_OnTouch;

bool blockJumpCap[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = "L4D2 Jockey Jump-Cap Patch",
	author = "Visor, A1m`",
	description = "Prevent Jockeys from being able to land caps with non-ability jumps in unfair situations",
	version = "1.3",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	Handle hGamedata = LoadGameConfigFile(GAMEDATA);

	if (!hGamedata) {
		SetFailState("Gamedata '%s.txt' missing or corrupt.", GAMEDATA);
	}
	
	int iCleapOnTouch = GameConfGetOffset(hGamedata, "CBaseAbility::OnTouch");
	if (iCleapOnTouch == -1) {
		SetFailState("Failed to get offset 'CBaseAbility::OnTouch'.");
	}

	hCLeap_OnTouch = DHookCreate(iCleapOnTouch, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, CLeap_OnTouch);
	DHookAddParam(hCLeap_OnTouch, HookParamType_CBaseEntity);
	
	HookEvent("round_start", view_as<EventHook>(ResetEvent), EventHookMode_PostNoCopy);
	HookEvent("round_end", view_as<EventHook>(ResetEvent), EventHookMode_PostNoCopy);
	HookEvent("player_shoved", OnPlayerShoved);
	
	delete hGamedata;
}

public void ResetEvent()
{
	for (int i = 0; i <= MAXPLAYERS; i++) {
		blockJumpCap[i] = false;
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (strcmp(classname, "ability_leap") == 0) {
		DHookEntity(hCLeap_OnTouch, false, entity); 
	}
}

public void OnPlayerShoved(Event hEvent, const char[] name, bool dontBroadcast)
{
	int shovee = GetClientOfUserId(hEvent.GetInt("userid"));
	int shover = GetClientOfUserId(hEvent.GetInt("attacker"));
	
	if (IsSurvivor(shover) && IsJockey(shovee)) {
		blockJumpCap[shovee] = true;
		CreateTimer(3.0, ResetJumpcapState, shovee, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action ResetJumpcapState(Handle hTimer, any jockey)
{
	blockJumpCap[jockey] = false;
	return Plugin_Handled;
}

public MRESReturn CLeap_OnTouch(int ability, Handle hParams)
{
	int jockey = GetEntPropEnt(ability, Prop_Send, "m_owner");
	if (IsJockey(jockey) && !IsFakeClient(jockey)) {
		int survivor = DHookGetParam(hParams, 1);
		if (IsSurvivor(survivor)) {
			if (!IsAbilityActive(ability) && blockJumpCap[jockey]) {
				return MRES_Supercede;
			}
		}
	}
	return MRES_Ignored;
}

bool IsAbilityActive(int ability)
{
	return view_as<bool>(GetEntProp(ability, Prop_Send, "m_isLeaping"));
}

bool IsJockey(int client)
{
	return (client > 0 
		&& client <= MaxClients 
		&& IsClientInGame(client) 
		&& GetClientTeam(client) == TEAM_INFECTED 
		&& GetEntProp(client, Prop_Send, "m_zombieClass") == Z_JOCKEY);
}

bool IsSurvivor(int client)
{
	return (client > 0 
		&& client <= MaxClients 
		&& IsClientInGame(client) 
		&& GetClientTeam(client) == TEAM_SURVIVOR);
}
