#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define TEAM_INFECTED 3
#define Z_TANK 8

ConVar
	g_hKillOnCrash = null;

public Plugin myinfo = 
{
	name = "AI Tank Gank",
	author = "Stabby",
	version = "0.3",
	description = "Kills tanks on pass to AI."
};

public void OnPluginStart()
{
	g_hKillOnCrash = CreateConVar( \
		"tankgank_killoncrash", \
		"0", \
		"If 0, tank will not be killed if the player that controlled it crashes.", \
		_, true,  0.0, true, 1.0 \
	);
	
	HookEvent("player_bot_replace", OnTankGoneAi);
}

public void OnTankGoneAi(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int iNewTank = GetClientOfUserId(hEvent.GetInt("bot"));
	
	if (GetClientTeam(iNewTank) == TEAM_INFECTED && GetEntProp(iNewTank, Prop_Send, "m_zombieClass") == Z_TANK) {
		int iFormerTank = GetClientOfUserId(hEvent.GetInt("player"));
		if (iFormerTank == 0 && !g_hKillOnCrash.BoolValue) {//if people disconnect, iFormerTank = 0 instead of the old player's id
			CreateTimer(1.0, Timed_CheckAndKill, iNewTank, TIMER_FLAG_NO_MAPCHANGE);
			return;
		}
		
		ForcePlayerSuicide(iNewTank);
	}
}

public Action Timed_CheckAndKill(Handle hTimer, any iNewTank)
{
	if (IsFakeClient(iNewTank) && IsPlayerAlive(iNewTank)) {
		ForcePlayerSuicide(iNewTank);
	}

	return Plugin_Stop;
}
