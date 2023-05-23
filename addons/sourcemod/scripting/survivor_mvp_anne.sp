#pragma semicolon 1
#pragma newdecls required
#pragma tabsize 0
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colors>
#include <left4dhooks>
#define ZC_SMOKER               1
#define ZC_BOOMER               2
#define ZC_HUNTER               3
#define ZC_SPITTER              4
#define ZC_JOCKEY               5
#define ZC_CHARGER              6
#define ZC_WITCH                7
#define ZC_TANK                 8
int 
	iDidDamage[MAXPLAYERS + 1],
	KillInfected[MAXPLAYERS+1],
	KillSpecial[MAXPLAYERS+1],
	FriendDamage[MAXPLAYERS+1],
	DamageFriend[MAXPLAYERS+1];
bool
	g_bIsPrintInfo;
public void OnPluginStart()
{
	RegConsoleCmd("sm_mvp", MVPinfo);
	RegConsoleCmd("sm_kills", MVPinfo);
	HookEvent("player_death", player_death);
	HookEvent("infected_death", infected_death);
	HookEvent("player_hurt",Event_PlayerHurt);
	HookEvent("round_start", event_RoundStart);
	//HookEvent("map_transition", PrintInfo, EventHookMode_PostNoCopy);
	HookEvent("round_end", PrintInfo, EventHookMode_PostNoCopy);
	//HookEvent("finale_win", PrintInfo, EventHookMode_PostNoCopy);
}

public void event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{ 
		KillInfected[i] = 0; 
		KillSpecial[i] = 0; 
		FriendDamage[i] =0 ;
		DamageFriend[i] =0 ;
		iDidDamage[i] = 0;
		g_bIsPrintInfo = false;
	}
}
public Action L4D_OnFirstSurvivorLeftSafeArea()
{
	for (int i = 1; i <= MaxClients; i++)
	{ 
		KillInfected[i] = 0; 
		KillSpecial[i] = 0; 
		FriendDamage[i] =0 ;
		DamageFriend[i] =0 ;
		iDidDamage[i] = 0;
	}
	return Plugin_Continue;
}
public Action PrintInfo(Handle event, const char[] name, bool dontBroadcast)
{
	if(g_bIsPrintInfo){
		return Plugin_Handled;
	}else{
		g_bIsPrintInfo = true;
	}
	PrintToChatAll("\x03[MVP统计]");
	displaykillinfected();
	return Plugin_Continue;
}
public Action MVPinfo(int client, int args) 
{
	PrintToChatAll("\x03[MVP统计]",client);
	displaykillinfected();
	return Plugin_Handled;
}
public Action Event_PlayerHurt(Handle event, const char[] name, bool dontBroadcast)
{
	int zombieClass = 0;
    int victimId = GetEventInt(event, "userid");
    int victim = GetClientOfUserId(victimId);
    int attackerId = GetEventInt(event, "attacker");
    int attacker = GetClientOfUserId(attackerId);
    int damageDone = GetEventInt(event, "dmg_health");
	
	if(IsValidClient(victim) && IsValidClient(attacker) && GetClientTeam(attacker)==2 && GetClientTeam(victim)== 2 && GetEntProp(victim, Prop_Send, "m_isIncapacitated") < 1)
	{
		FriendDamage[attacker]+=damageDone;
		DamageFriend[victim]+=damageDone;
	}
	if (victimId && attackerId && IsClientAndInGame(victim) && IsClientAndInGame(attacker))
    {
        if (GetClientTeam(attacker) == 2 && GetClientTeam(victim) == 3)
        {
			zombieClass = GetEntProp(victim, Prop_Send, "m_zombieClass");
			if (zombieClass >= ZC_SMOKER && zombieClass < ZC_WITCH)
            {
				if (zombieClass == ZC_SMOKER && damageDone > 250)
				{
					damageDone = 250;
				}
				if (zombieClass == ZC_HUNTER && damageDone > 250)
				{
					damageDone = 250;
				} 
				if (zombieClass == ZC_BOOMER && damageDone > 50)
				{
					damageDone = 50;
				} 
				if (zombieClass == ZC_CHARGER && damageDone > 600)
				{
					damageDone = 600;
				} 
				if (zombieClass == ZC_SPITTER && damageDone > 100)
				{
					damageDone = 100;
				} 
				if (zombieClass == ZC_JOCKEY && damageDone > 325)
				{
					damageDone = 325;
				} 
				iDidDamage[attacker] += damageDone;
			}
        }
    }
	return Plugin_Continue;
}
public Action infected_death(Handle event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(IsValidClient(attacker) && GetClientTeam(attacker) == 2)
	{
		KillInfected[attacker] += 1;
	}
	return Plugin_Continue;
}
public Action player_death(Handle event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidClient(attacker) && IsValidClient(client))
	{
		if(GetClientTeam(attacker) == 2 && GetClientTeam(client) == 3)
		{
			KillSpecial[attacker] += 1;
		}
	}
	return Plugin_Continue;
}
void displaykillinfected()
{
	int client;
	int players;
	int players_clients[MAXPLAYERS+1];
	for (client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client) == 2) 
			players_clients[players++] = client;
	}
	SortCustom1D(players_clients, 8, SortByDamageDesc);
	for (int i; i <= 8; i++)
	{
		client = players_clients[i];
		if (IsValidClient(client) && GetClientTeam(client) == 2) 
		{
			PrintToChatAll("\x03特感\x04%2d \x03丧尸\x04%3d \x03黑/被黑\x04%2d/%2d \x03伤害\x04%4d \x05%N",KillSpecial[client], KillInfected[client],FriendDamage[client],DamageFriend[client],iDidDamage[client], client);
		}
	}
}
public int SortByDamageDesc(int elem1, int elem2, const int[] array, Handle hndl)
{
	if (iDidDamage[elem1] > iDidDamage[elem2]) return -1;
	else if (iDidDamage[elem2] > iDidDamage[elem1]) return 1;
	else if (elem1 > elem2) return -1;
	else if (elem2 > elem1) return 1;
	return 0;
}
stock bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client));
}
stock bool IsClientAndInGame(int index)
{
    return (index > 0 && index <= MaxClients && IsClientInGame(index));
}
stock bool IsClientInGameEx(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
	{return true;} else {return false;}
}
stock bool IsInfected(int client) 
{
	if(IsClientInGame(client) && GetClientTeam(client) == 3) 
	{
		return true;
	} 
	else 
	{
		return false;
	}
}