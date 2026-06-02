#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <colors>
#include <adminmenu>

#define PLUGIN_VERSION "v2.2"

public Plugin:myinfo=
{
	name = "Kills Statistic",
	author = "Lin,Hoongdou",
	description = "Kills Statistic",
	version = PLUGIN_VERSION,
	url = "N/A"
};

#define TEAM_SPECTATORS 1
#define TEAM_SURVIVORS 2
#define TEAM_INFECTED 3

#define IsValidClient(%1)		(1 <= %1 <= MaxClients && IsClientInGame(%1))
#define IsValidAliveClient(%1)	(1 <= %1 <= MaxClients && IsClientInGame(%1) && IsPlayerAlive(%1))

new iSmoker[MAXPLAYERS+1];
new iHunter[MAXPLAYERS+1];
new iBoomer[MAXPLAYERS+1];
new iCharger[MAXPLAYERS+1];
new iJockey[MAXPLAYERS+1];
new iTankRock[MAXPLAYERS+1];
new iTankClaw[MAXPLAYERS+1];
bool
	g_bIsPrintInfo;

public OnPluginStart()
{
	LoadTranslations("HitStatistics.phrases");
	decl String:Game_Name[64];
	GetGameFolderName(Game_Name, sizeof(Game_Name));
	if(!StrEqual(Game_Name, "left4dead2", false))
	{
		SetFailState("Mvp Statistic %d插件仅支持L4D2!", PLUGIN_VERSION);
	}

	HookEvents();
	RegConsoleCmd("sm_kills", Command_Kills, "MVP Statistic");
	RegConsoleCmd("sm_killsme", Command_KillsMe, "MyKills Statistic");
}

HookEvents()
{
    HookEvent("round_start", RoundStart_Event, EventHookMode_PostNoCopy);
    HookEvent("round_end",				Event_RoundEnd);
    HookEvent("tongue_grab",			Event_SmokerGrabbed);
    HookEvent("lunge_pounce",			Event_HunterPounced);
    HookEvent("player_now_it",			Event_BoomerAttackEXP);
    HookEvent("charger_pummel_start",	Event_ChargerPummel);
    HookEvent("charger_impact",			Event_ChargerImpact);
    HookEvent("jockey_ride",			Event_JockeyRide);
    HookEvent("player_hurt", 			Event_PlayerHurt);
}


public Action:Command_Kills(Client, args)
{
    if (IsValidClient(Client) && !IsFakeClient(Client))
    {
        KillsStatistic();
    }
    return Plugin_Handled;
}

public Action:Command_KillsMe(Client, args)
{
    MyKillsStatistic(Client);
    return Plugin_Handled;
}

public KillsStatistic()
{
	decl String:line[256];
	for (int i = 1; i <= MaxClients; i++)
	{
	    if(IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVORS)
		{
			Format(line, sizeof(line), "{green}[ {green}被拉 {red}%d {green}][ 被扑 {red}%d {green}][ 被吐 {red}%d {green}][ 被撞 {red}%d {green}][ 被骑 {red}%d {green}] {olive}%N ", iSmoker[i], iHunter[i], iBoomer[i], iCharger[i], iJockey[i], i);
			CPrintToChatAll(line);
		}
	}
}


public MyKillsStatistic(Client)
{
	if(IsValidClient(Client) && GetClientTeam(Client) == TEAM_SURVIVORS)
	{
		decl String:line[256];
		Format(line, sizeof(line), "{green}[ {green}被拉 {red}%d {green}][ 被扑 {red}%d {green}][ 被吐 {red}%d {green}][ 被撞 {red}%d {green}][ 被骑 {red}%d {green}] {olive}%N", iSmoker[Client], iHunter[Client], iBoomer[Client], iCharger[Client], iJockey[Client], Client);
		CPrintToChat(Client, line);
                Format(line, sizeof(line), "{green}[拳头 {red}%d {green}][石头 {red}%d {green}] {olive}%N", iTankClaw[Client], iTankRock[Client], Client);
        	CPrintToChat(Client, line);
	}
	else
	{
		CPrintToChat(Client, "%t", "HitStatistics_NotSurvivor");
	}
}

public Action Event_RoundEnd(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if(g_bIsPrintInfo){
		return Plugin_Handled;
	}else{
		g_bIsPrintInfo = true;
	}
	KillsStatistic();
	return Plugin_Continue;
}

public ScavRoundStart(Handle:event)
{
    // clear mvp stats
    for (new i = 1; i <= MaxClients; i++)
    {
		iSmoker[i] = 0;
		iHunter[i] = 0;
		iBoomer[i] = 0;
		iCharger[i] = 0;
		iJockey[i] = 0;
		iTankRock[i] = 0;
		iTankClaw[i] = 0;
		g_bIsPrintInfo = false;
    }
}

public RoundStart_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
    for (new i = 1; i <= MaxClients; i++)
    {
        iSmoker[i] = 0;
        iHunter[i] = 0;
        iBoomer[i] = 0;
        iCharger[i] = 0;
        iJockey[i] = 0;
        iTankRock[i] = 0;
        iTankClaw[i] = 0;
    }
}



/* Smoker拉扯幸存者 */
public Action:Event_SmokerGrabbed(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));

	if (IsValidAliveClient(victim))
	{
		if (GetClientTeam(victim) == TEAM_SURVIVORS)
		{
			iSmoker[victim]++;
		}
	}
	return Plugin_Continue;
}

/* Hunter突袭幸存者 */
public Action:Event_HunterPounced(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));

	if (IsValidAliveClient(victim))
	{
		if (GetClientTeam(victim) == TEAM_SURVIVORS)
		{
			iHunter[victim]++;
		}
	}
	return Plugin_Continue;
}
/* Boomer呕吐幸存者 */
public Action:Event_BoomerAttackEXP(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsValidAliveClient(victim))
	{
		if (GetClientTeam(victim) == TEAM_SURVIVORS)
		{
			iBoomer[victim]++;
		}
	}
	return Plugin_Continue;
}
/* Charger撞到并捉住幸存者 */
public Action:Event_ChargerPummel(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));

	if (IsValidAliveClient(victim))
	{
		if (GetClientTeam(victim) == TEAM_SURVIVORS)
		{
			iCharger[victim]++;
		}
	}
	return Plugin_Continue;
}

/* Charger撞到并撞开其他幸存者 */
public Action:Event_ChargerImpact(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));

	if (IsValidAliveClient(victim))
	{
		if (GetClientTeam(victim) == TEAM_SURVIVORS)
		{
			iCharger[victim]++;
		}
	}
	return Plugin_Continue;
}

/* Jockey骑到幸存者 */
public Action:Event_JockeyRide(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));

	if (IsValidAliveClient(victim))
	{
		if (GetClientTeam(victim) == TEAM_SURVIVORS)
		{
			iJockey[victim]++;
		}
	}
	return Plugin_Continue;
}

/* Tank攻击生还者 */
public Action:Event_PlayerHurt(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidAliveClient(victim) && GetClientTeam(victim) == TEAM_SURVIVORS)
	{
		decl String:WeaponUsed[256];
		GetEventString(event, "weapon", WeaponUsed, sizeof(WeaponUsed));

		if (StrEqual(WeaponUsed,"tank_claw"))
		{
		    iTankClaw[victim]++;
		}
		else if (StrEqual(WeaponUsed,"tank_rock"))
		{
		    iTankRock[victim]++;
		}
	}
	return Plugin_Continue;
	}

