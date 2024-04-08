/*
    SourcePawn is Copyright (C) 2006-2015 AlliedModders LLC.  All rights reserved.
    SourceMod is Copyright (C) 2006-2015 AlliedModders LLC.  All rights reserved.
    Pawn and SMALL are Copyright (C) 1997-2015 ITB CompuPhase.
    Source is Copyright (C) Valve Corporation.
    All trademarks are property of their respective owners.

    This program is free software: you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by the
    Free Software Foundation, either version 3 of the License, or (at your
    option) any later version.

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>
#include <colors>

#undef REQUIRE_PLUGIN
#include <readyup>
#include <pause>

#define DEBUG_SM   1
#define DEBUG_CHAT 2

char sDebugMessage[256];

public Plugin myinfo =
{
    name = "L4D2 Auto-pause",
    author = "Darkid, Griffin, StarterX4",
    description = "When a player disconnects due to crash, automatically pause the game. When they rejoin, give them a correct spawn timer.",
    version = "2.2",
    url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
}

ConVar 
    convarEnabled,
    convarForce,
    convarForceUnpause,
    convarDebug;

Handle
    crashedPlayers,
    generalCrashers,
    infectedPlayers,
    survivorPlayers;

bool
    bReadyUpIsAvailable,
    bPauseIsAvailable,
    bRoundEnd;

public void OnPluginStart() 
{
    convarEnabled = CreateConVar("autopause_enable", "1", "Whether or not to automatically pause when a player crashes.");
    convarForce = CreateConVar("autopause_force", "0", "Whether or not to force pause when a player crashes.");
    convarForceUnpause = CreateConVar("autopause_forceunpause", "0", "Whether or not we force unpause when the crashed players have loaded back in");
    convarDebug = CreateConVar("autopause_apdebug", "0", "0: No Debugging - 1: Sourcemod Logs - 2: PrintToChat - 3: Both", _, true, 0.0, true, 3.0);

    crashedPlayers = CreateTrie();
    generalCrashers = CreateArray(64);
    infectedPlayers = CreateArray(64);
    survivorPlayers = CreateArray(64);

    HookEvent("round_start", Event_RoundStart);
    HookEvent("round_end", Event_RoundEnd);
    HookEvent("player_team", Event_PlayerTeam);
    HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
}

public void OnAllPluginsLoaded()
{
    bReadyUpIsAvailable = LibraryExists("readyup");
    bPauseIsAvailable = LibraryExists("pause");
}

public void OnLibraryRemoved(const char[] name)
{
    if (strcmp(name, "readyup") == 0)
        bReadyUpIsAvailable = false;

    if (strcmp(name, "pause") == 0)
        bPauseIsAvailable = false;
}

public void OnLibraryAdded(const char[] name)
{
    if (strcmp(name, "readyup") == 0)
        bReadyUpIsAvailable = true;

    if (strcmp(name, "pause") == 0)
        bPauseIsAvailable = true;
}

public void OnClientPutInServer(int client)
{
    char sAuthId[64];
    GetClientAuthId(client, AuthId_Steam2, sAuthId, sizeof(sAuthId));

    if (strcmp(sAuthId, "BOT") == 0) 
        return;

    int crasherIndex = FindStringInArray(generalCrashers, sAuthId);

    if (crasherIndex == -1) 
        return;

    RemoveFromArray(generalCrashers, crasherIndex);
    int remainingCrashers = GetArraySize(generalCrashers);

    if (convarDebug.BoolValue)
    {
        Format(sDebugMessage, sizeof(sDebugMessage), "[Autopause (OnClientPutInServer)] Crashed Player %s rejoined.", sAuthId);
        DebugLog(sDebugMessage);
    }

    if (convarForceUnpause.BoolValue && bPauseIsAvailable && IsInPause())
    {
        if (!remainingCrashers)
        {
            CPrintToChatAll("{blue}[{default}AutoPause{blue}] {default}All {green}crashed {default}players have reconnected.. {blue}Unpausing{default}!");
            ServerCommand("sm_forceunpause");

            if (convarDebug.BoolValue)
            {
                Format(sDebugMessage, sizeof(sDebugMessage), "[Autopause (OnClientPutInServer)] All crashed players rejoined. Force Unpause was triggered.");
                DebugLog(sDebugMessage);
            }
        }
        else
            CPrintToChatAll("{blue}[{default}AutoPause{blue}] {default}Waiting for {olive}%i {default}more {green}crashed {default}player%s {default}before automatic {blue}Unpause{default}!", remainingCrashers, remainingCrashers > 1 ? "s" : "");
    }
}

public void Event_RoundStart(Event hEvent, char[] sEventName, bool dontBroadcast) 
{
    ClearTrie(crashedPlayers);
    ClearArray(generalCrashers);
    ClearArray(infectedPlayers);
    ClearArray(survivorPlayers);
    bRoundEnd = false;
}

public void Event_RoundEnd(Event hEvent, char[] sEventName, bool dontBroadcast)
{
    bRoundEnd = true;
}

public void Event_PlayerTeam(Event hEvent, char[] sEventName, bool dontBroadcast) 
{
    int client = GetClientOfUserId(hEvent.GetInt("userid"));

    if (client <= 0 || client > MaxClients)
        return;

    char sAuthId[64];
    GetClientAuthId(client, AuthId_Steam2, sAuthId, sizeof(sAuthId));

    if (strcmp(sAuthId, "BOT") == 0) 
        return;

    int survivorIndex = FindStringInArray(survivorPlayers, sAuthId);
    int infectedIndex = FindStringInArray(infectedPlayers, sAuthId);

    if (survivorIndex != -1)
    {
        RemoveFromArray(survivorPlayers, survivorIndex);

        if (convarDebug.BoolValue)
        {
            Format(sDebugMessage, sizeof(sDebugMessage), "[AutoPause (%s)] Removed player %s from the survivor team.", sEventName, sAuthId);
            DebugLog(sDebugMessage);
        }
    }

    if (infectedIndex != -1)
    {
        RemoveFromArray(infectedPlayers, infectedIndex);

        if (convarDebug.BoolValue)
        {
            Format(sDebugMessage, sizeof(sDebugMessage), "[AutoPause (%s)] Removed player %s from the infected team.", sEventName, sAuthId);
            DebugLog(sDebugMessage);
        }
    }

    int newTeam = hEvent.GetInt("team");

    if (newTeam == L4D_TEAM_SURVIVOR)
    {
        PushArrayString(survivorPlayers, sAuthId);

        if (convarDebug.BoolValue)
        {
            Format(sDebugMessage, sizeof(sDebugMessage), "[AutoPause (%s)] Added player %s to the survivor team.", sEventName, sAuthId);
            DebugLog(sDebugMessage);
        }
    }
    else if (newTeam == L4D_TEAM_INFECTED) 
    {
        float fSpawnTime;

        if (GetTrieValue(crashedPlayers, sAuthId, fSpawnTime)) 
        {
            CountdownTimer CTimer_SpawnTimer = L4D2Direct_GetSpawnTimer(client);
            CTimer_Start(CTimer_SpawnTimer, fSpawnTime);
            RemoveFromTrie(crashedPlayers, sAuthId);

            if (convarDebug.BoolValue)
            {
                Format(sDebugMessage, sizeof(sDebugMessage), "[AutoPause (%s)] Player %s rejoined the infected, set spawn timer to %f.", sEventName, sAuthId, fSpawnTime);
                DebugLog(sDebugMessage);
            }
        } 
        
        PushArrayString(infectedPlayers, sAuthId);

        if (convarDebug.BoolValue)
        {
            Format(sDebugMessage, sizeof(sDebugMessage), "[AutoPause (%s)] Added player %s to the infected team.", sEventName, sAuthId);
            DebugLog(sDebugMessage);
        }
    }
}

public void Event_PlayerDisconnect(Event hEvent, char[] sEventName, bool dontBroadcast)
{
    int client = GetClientOfUserId(hEvent.GetInt("userid"));

    if (client <= 0 || client > MaxClients)
        return;

    char sAuthId[64];
    GetClientAuthId(client, AuthId_Steam2, sAuthId, sizeof(sAuthId));

    if (strcmp(sAuthId, "BOT") == 0) 
        return;

    if (FindStringInArray(infectedPlayers, sAuthId) == -1 && FindStringInArray(survivorPlayers, sAuthId) == -1) 
        return;

    if (GetClientTeam(client) == L4D_TEAM_SURVIVOR && !IsPlayerAlive(client))
    {
        if (convarDebug.BoolValue)
        {
            Format(sDebugMessage, sizeof(sDebugMessage), "[AutoPause (%s)] Player %N left the game but is a dead Survivor", sEventName, client);
            DebugLog(sDebugMessage);
        }
        return;
    }

    char sReason[128];
    hEvent.GetString("reason", sReason, sizeof(sReason));

    char sTimedOut[64];
    Format(sTimedOut, sizeof(sTimedOut), "%N timed out", client);

    if (convarDebug.BoolValue)
    {
        Format(sDebugMessage, sizeof(sDebugMessage), "[AutoPause (%s)] Player %N (%s) left the game: %s", sEventName, client, sAuthId, sReason);
        DebugLog(sDebugMessage);
    }

    if (strcmp(sReason, sTimedOut) == 0 || strcmp(sReason, "No Steam logon") == 0)
    {
        if (convarEnabled.BoolValue && (!bReadyUpIsAvailable || !IsInReady()) && !bRoundEnd) 
        {
            if (convarForce.BoolValue) 
                ServerCommand("sm_forcepause");
            else 
                FakeClientCommand(client, "sm_pause");

            if (FindStringInArray(generalCrashers, sAuthId) == -1)
                PushArrayString(generalCrashers, sAuthId);
                
            CPrintToChatAll("{blue}[{default}AutoPause{blue}] {olive}%N {default}crashed.", client);
        }
    }

    if (FindStringInArray(infectedPlayers, sAuthId) != -1) 
    {
        CountdownTimer CTimer_SpawnTimer = L4D2Direct_GetSpawnTimer(client);
        if (CTimer_SpawnTimer != CTimer_Null) 
        {
            float fTimeLeft = CTimer_GetRemainingTime(CTimer_SpawnTimer);

            if (convarDebug.BoolValue)
            {
                Format(sDebugMessage, sizeof(sDebugMessage), "[AutoPause (%s)] Player %s left the game with %f time until spawn.", sEventName, sAuthId, fTimeLeft);
                DebugLog(sDebugMessage);
            }

            SetTrieValue(crashedPlayers, sAuthId, fTimeLeft);
        }
    }
}

void DebugLog(char[] sMessage)
{
    int flags = convarDebug.IntValue;

    if (flags & DEBUG_SM)
        LogMessage(sMessage);
    
    if (flags & DEBUG_CHAT)
        PrintToChatAll(sMessage);
}