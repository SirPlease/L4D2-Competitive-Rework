#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>

#define Z_HUNTER 3
#define TEAM_INFECTED 3

#define GAMEDATA "l4d2_si_ability"

int
	LungeActivateAbilityOffset;

Handle
	hCLunge_ActivateAbility;

float
	fSuspectedBackjump[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = "L4D2 No Backjump",
	author = "Visor, A1m`",
	description = "Look at the title",
	version = "1.2.3",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	InitGameData();
	
	hCLunge_ActivateAbility = DHookCreate(LungeActivateAbilityOffset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, CLunge_ActivateAbility);

	HookEvent("round_start", ResetEvent, EventHookMode_PostNoCopy);
	HookEvent("round_end",  ResetEvent, EventHookMode_PostNoCopy);
	
	HookEvent("player_jump", OnPlayerJump, EventHookMode_Post);
}

void InitGameData()
{
	Handle hGamedata = LoadGameConfigFile(GAMEDATA);

	if (!hGamedata) {
		SetFailState("Gamedata '%s.txt' missing or corrupt.", GAMEDATA);
	}
	
	LungeActivateAbilityOffset = GameConfGetOffset(hGamedata, "CBaseAbility::ActivateAbility");
	if (LungeActivateAbilityOffset == -1) {
		SetFailState("Failed to get offset 'CBaseAbility::ActivateAbility'.");
	}

	delete hGamedata;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (strcmp(classname, "ability_lunge") == 0) {
		DHookEntity(hCLunge_ActivateAbility, false, entity); 
	}
}

public void ResetEvent(Event hEvent, const char[] eName, bool dontBroadcast)
{
	for (int i = 0; i <= MAXPLAYERS; i++) {
		fSuspectedBackjump[i] = 0.0;
	}
}

public void OnPlayerJump(Event hEvent, const char[] eName, bool dontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));

	if (IsHunter(client) && !IsGhost(client) && IsOutwardJump(client)) {
		fSuspectedBackjump[client] = GetGameTime();
	}
}

public MRESReturn CLunge_ActivateAbility(int ability)
{
	int client = GetEntPropEnt(ability, Prop_Send, "m_owner");
	if (fSuspectedBackjump[client] + 1.5 > GetGameTime()) {
		//PrintToChat(client, "\x01[SM] No \x03backjumps\x01, sorry");
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

bool IsOutwardJump(int client)
{
	bool IsGround = view_as<bool>(GetEntityFlags(client) & FL_ONGROUND);
	bool IsAttemptingToPounce = view_as<bool>(GetEntProp(client, Prop_Send, "m_isAttemptingToPounce", 1));

	return (!IsAttemptingToPounce && !IsGround);
}

bool IsHunter(int client)
{
	return (client > 0 
		/*&& client <= MaxClients*/ //GetClientOfUserId return 0, if not found
		&& IsClientInGame(client)
		&& IsPlayerAlive(client)
		&& GetClientTeam(client) == TEAM_INFECTED
		&& GetEntProp(client, Prop_Send, "m_zombieClass") == Z_HUNTER);
}

bool IsGhost(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isGhost", 1));
}
