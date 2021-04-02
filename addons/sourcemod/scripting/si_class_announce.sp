#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <colors>
#undef REQUIRE_PLUGIN
#include <readyup>
#define REQUIRE_PLUGIN

#define IS_VALID_CLIENT(%1)     (%1 > 0 && %1 <= MaxClients)
#define IS_SURVIVOR(%1)         (GetClientTeam(%1) == 2)
#define IS_INFECTED(%1)         (GetClientTeam(%1) == 3)
#define IS_VALID_INGAME(%1)     (IS_VALID_CLIENT(%1) && IsClientInGame(%1))
#define IS_VALID_SURVIVOR(%1)   (IS_VALID_INGAME(%1) && IS_SURVIVOR(%1))
#define IS_VALID_INFECTED(%1)   (IS_VALID_INGAME(%1) && IS_INFECTED(%1))
#define IS_SURVIVOR_ALIVE(%1)   (IS_VALID_SURVIVOR(%1) && IsPlayerAlive(%1))
#define IS_INFECTED_ALIVE(%1)   (IS_VALID_INFECTED(%1) && IsPlayerAlive(%1))

#define ZC_SMOKER               1
#define ZC_BOOMER               2
#define ZC_HUNTER               3
#define ZC_SPITTER              4
#define ZC_JOCKEY               5
#define ZC_CHARGER              6
#define ZC_WITCH                7
#define ZC_TANK                 8

#define MAXSPAWNS               8

new     bool:   g_bReadyUpAvailable     = false;

bool	g_bFooterAdded;
bool	g_bUndone;

ConVar g_cvMaxSI;
int g_iMaxSI;


new const String: g_csSIClassName[][] =
{
    "",
    "Smoker",
    "Boomer",
    "Hunter",
    "Spitter",
    "Jockey",
    "Charger",
    "Witch",
    "Tank"
};


public Plugin:myinfo = 
{
    name = "Special Infected Class Announce",
    author = "Tabun",
    description = "Report what SI classes are up when the round starts.",
    version = "0.9.3",
    url = "none"
}

public OnPluginStart()
{
	g_cvMaxSI = FindConVar("z_max_player_zombies");
	g_cvMaxSI.AddChangeHook(OnCvarChanged);
	g_iMaxSI = g_cvMaxSI.IntValue;
	
	HookEvent("player_team", OnPlayerTeam);
	HookEvent("round_start", EventHook:Event_RoundStart, EventHookMode_PostNoCopy);
}

public void OnCvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iMaxSI = g_cvMaxSI.IntValue;
}

public OnAllPluginsLoaded()
{
    g_bReadyUpAvailable = LibraryExists("readyup");
}
public OnLibraryRemoved(const String:name[])
{
    if ( StrEqual(name, "readyup") ) { g_bReadyUpAvailable = false; }
}
public OnLibraryAdded(const String:name[])
{
    if ( StrEqual(name, "readyup") ) { g_bReadyUpAvailable = true; }
}

public void Event_RoundStart()
{
	g_bFooterAdded = false;
	g_bUndone = false;
	
	CreateTimer(7.0, UpdateReadyUpFooter);
}

public void OnPlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bReadyUpAvailable || g_bFooterAdded || !g_bUndone) return;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	int team = event.GetInt("team");
	
	if (!IS_VALID_INGAME(client) || team != 3) return;
	
	CreateTimer(1.0, UpdateReadyUpFooter);
}

public Action UpdateReadyUpFooter(Handle timer)
{
	if (!g_bReadyUpAvailable) return Plugin_Handled;
	
	if (!IsInfectedTeamFullAlive() || g_bFooterAdded)
	{
		g_bUndone = true;
		return Plugin_Handled;
	}
	
	char msg[256];
	ProcessSIString(msg, sizeof(msg), false);
	AddStringToReadyFooter(msg);
	g_bFooterAdded = true;
	
	return Plugin_Handled;
}

public OnRoundIsLive()
{
    g_bUndone = false;
    // announce SI classes up now
    char msg[256];
    ProcessSIString(msg, sizeof(msg));
    PrintToClientExInfected(msg);
}

public Action: L4D_OnFirstSurvivorLeftSafeArea( client )
{   
    // if no readyup, use this as the starting event
    if (!g_bReadyUpAvailable) {
        char msg[256];
        ProcessSIString(msg, sizeof(msg));
        PrintToClientExInfected(msg);
    }
}

stock void ProcessSIString(char[] msg, int maxlength, bool long=true)
{
    // get currently active SI classes
    new iSpawns;
    new iSpawnClass[MAXSPAWNS+1];
    
    for (new i = 1; i <= MaxClients && iSpawns < MAXSPAWNS; i++) {
        if (!IS_INFECTED_ALIVE(i)) { continue; }

        iSpawnClass[iSpawns] = GetEntProp(i, Prop_Send, "m_zombieClass");
        iSpawns++;
    }
    
    // print classes, according to amount of spawns found
    switch (iSpawns) {
        case 4: {
            Format(	msg,
            		maxlength,
                    "{red}%s{default}, {red}%s{default}, {red}%s{default}, {red}%s{default}",
                    g_csSIClassName[iSpawnClass[0]],
                    g_csSIClassName[iSpawnClass[1]],
                    g_csSIClassName[iSpawnClass[2]],
                    g_csSIClassName[iSpawnClass[3]]
                );
        }
        case 3: {
            Format(	msg,
            		maxlength,
                    "{red}%s\x01, {red}%s\x01, {red}%s{default}",
                    g_csSIClassName[iSpawnClass[0]],
                    g_csSIClassName[iSpawnClass[1]],
                    g_csSIClassName[iSpawnClass[2]]
                );
        }
        case 2: {
            Format(	msg,
            		maxlength,
                    "{red}%s{default}, {red}%s{default}",
                    g_csSIClassName[iSpawnClass[0]],
                    g_csSIClassName[iSpawnClass[1]]
                );
        }
        case 1: {
            Format(	msg,
            		maxlength,
                    "{red}%s{default}",
                    g_csSIClassName[iSpawnClass[0]]
                );
        }
    }
    
    if (long) {
    	Format(msg, maxlength, "Special Infected: %s", msg);
    } else {
    	CRemoveTags(msg, maxlength);
    	Format(msg, maxlength, "SI: %s", msg);
    }
}

stock void PrintToClientExInfected(const char[] Message)
{
	for (int i = 1; i <= MaxClients; i++) {
		if (!IS_VALID_INGAME(i) || IS_INFECTED(i) || (IsFakeClient(i) && !IsClientSourceTV(i))) { continue; }

		CPrintToChat(i, Message);
		//PrintHintText(i, Message2);
    }
}

stock bool IsInfectedTeamFullAlive()
{
	int players = 0;
	for (int i = 1; i <= MaxClients; i++) {
		if (IS_INFECTED_ALIVE(i)) players++;
	}
	return players >= g_iMaxSI;
}

stock bool InSecondHalfOfRound()
{
	return !!GameRules_GetProp("m_bInSecondHalfOfRound");
}