#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>

#define PLUGIN_VERSION "1.0"
#define GAMEDATA_FILE  "l4d2_fix_tank_rock_handoff"

Handle g_hCThrow_OnStunned = null;

public Plugin myinfo =
{
	name = "[L4D2] Fix Tank Rock Stuck",
	author = "Sir",
	description = "Cancels tank rocks that are in the middle of a throw when passing to another player/AI.",
	version = PLUGIN_VERSION,
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	GameData gd = new GameData(GAMEDATA_FILE);
	if (!gd) SetFailState("Missing gamedata \"" ... GAMEDATA_FILE ... ".txt\"");

	StartPrepSDKCall(SDKCall_Entity);
	if (!PrepSDKCall_SetFromConf(gd, SDKConf_Signature, "CThrow::OnStunned"))
	{
		delete gd;
		SetFailState("Failed to find signature \"CThrow::OnStunned\"");
	}
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	g_hCThrow_OnStunned = EndPrepSDKCall();
	delete gd;

	if (g_hCThrow_OnStunned == null)
		SetFailState("Failed to prep SDKCall for CThrow::OnStunned");

	HookEvent("player_bot_replace", Event_PlayerBotReplace, EventHookMode_Post);
	HookEvent("bot_player_replace", Event_BotPlayerReplace, EventHookMode_Post);
}

/* Covers Player to Player passes (including forced) */
public void L4D_OnReplaceTank(int oldTank, int newTank)
{
	CancelPossibleTankThrow(newTank);
}

/* Covers Player to Bot passes */
void Event_PlayerBotReplace(Event event, const char[] name, bool dontBroadcast)
{
	int bot = GetClientOfUserId(event.GetInt("bot"));
	CancelPossibleTankThrow(bot);
}

/* Covers Bot to Player passes (as we do in some plugins) */
void Event_BotPlayerReplace(Event event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(event.GetInt("player"));
	CancelPossibleTankThrow(player);
}

void CancelPossibleTankThrow(int client)
{
	if (!IsTank(client))
		return;

	int ability = GetEntPropEnt(client, Prop_Send, "m_customAbility");
	if (ability == -1)
		return;

	SDKCall(g_hCThrow_OnStunned, ability, 0.0);
}

bool IsTank(int client)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client))
		return false;

	if (GetClientTeam(client) != L4D_TEAM_INFECTED)
		return false;

	return GetEntProp(client, Prop_Send, "m_zombieClass") == L4D2_ZOMBIE_CLASS_TANK;
}
