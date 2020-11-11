#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <timers.inc>

#define DEBUG                   false

#define MAX_SOUNDFILE_LENGTH    64
#define MAX_JOCKEYSOUND         17

#define JOCKEY_VOICE_TIMEOUT    2.0
#define SOUND_CHECK_INTERVAL    3.0

#define TEAM_INFECTED 		3
#define ZC_JOCKEY               5
#define SNDCHAN_VOICE           2


new Handle: hPluginEnabled;                                             // convar: enable fix
new Handle: hJockeySoundAlways;                                         // convar: whether to always play sound or not
new Handle: hJockeySoundTime;                                           // convar: how soon to play sound

new Float: fJockeyLaughingStop[MAXPLAYERS+1];
new Handle: hJockeyLaughingTimer[MAXPLAYERS+1];

new const String: sJockeySound[MAX_JOCKEYSOUND+1][] =
{
    "player/jockey/voice/idle/jockey_recognize02.wav",
    "player/jockey/voice/idle/jockey_recognize06.wav",
    "player/jockey/voice/idle/jockey_recognize07.wav",
    "player/jockey/voice/idle/jockey_recognize08.wav",
    "player/jockey/voice/idle/jockey_recognize09.wav",
    "player/jockey/voice/idle/jockey_recognize10.wav",
    "player/jockey/voice/idle/jockey_recognize11.wav",
    "player/jockey/voice/idle/jockey_recognize12.wav",
    "player/jockey/voice/idle/jockey_recognize13.wav",
    "player/jockey/voice/idle/jockey_recognize15.wav",
    "player/jockey/voice/idle/jockey_recognize16.wav",
    "player/jockey/voice/idle/jockey_recognize17.wav",
    "player/jockey/voice/idle/jockey_recognize18.wav",
    "player/jockey/voice/idle/jockey_recognize19.wav",
    "player/jockey/voice/idle/jockey_recognize20.wav",
    "player/jockey/voice/idle/jockey_recognize24.wav",
    "player/jockey/voice/idle/jockey_lurk04.wav",
    "player/jockey/voice/idle/jockey_lurk05.wav"
};

/*
-----------------------------------------------------------------------------------------------------------------------------------------------------

To-Do:
---------
- find a way to make the sound hook removal/addition work reliably

Changelog
---------
0.1b
- fix error log spam
0.1a
- plays sound at set time after jockey spawns up
- but only if the jockey isn't already making noise

-----------------------------------------------------------------------------------------------------------------------------------------------------
*/

public Plugin:myinfo = 
{
    name = "Unsilent Jockey",
    author = "Tabun",
    description = "Makes jockeys emit sound when just spawned up.",
    version = "0.1b",
    url = "nope"
}

/* -------------------------------
*      Init
* ------------------------------- */

public OnPluginStart()
{
    // cvars
    hPluginEnabled =     CreateConVar("sm_unsilentjockey_enabled", "1",   "Enable unsilent jockey mode.", FCVAR_NONE, true, 0.0, true, 1.0);
    hJockeySoundAlways = CreateConVar("sm_unsilentjockey_always",  "0",   "Whether to play jockey spawn sound even if it is not detected as silent.", FCVAR_NONE, true, 0.0, true, 1.0);
    hJockeySoundTime =   CreateConVar("sm_unsilentjockey_time",    "0.1", "How soon to play sound after spawning (in seconds).", FCVAR_NONE, true, 0.0, true, 10.0);
    
    // hooks / events
    AddNormalSoundHook(NormalSHook:HookSound_Callback);
    HookEvent("player_spawn", PlayerSpawn_Event);
    //HookConVarChange(hJockeySoundAlways, ConVarChange_JockeySoundAlways);     // attempt to remove sound hook when forcing, but seems problematic.
}

public OnMapStart()
{
    // precache sounds
    for (new i = 0; i <= MAX_JOCKEYSOUND; i++)
    {
        PrefetchSound(sJockeySound[i]);
        PrecacheSound(sJockeySound[i], true);
    }
}

/*
public ConVarChange_JockeySoundAlways(Handle:cvar, const String:oldValue[], const String:newValue[]) {
if (StringToInt(newValue) == 0) {
RemoveNormalSoundHook(NormalSHook:HookSound_Callback);
} else {
AddNormalSoundHook(NormalSHook:HookSound_Callback);
}
}
*/


/* -------------------------------
*      Events
* ------------------------------- */

public Action:PlayerSpawn_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (!GetConVarBool(hPluginEnabled))                                 { return Plugin_Continue; }
    
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    
    // the usual checks, only actual jockeys
    if (!IsClientAndInGame(client))                                     { return Plugin_Continue; }
    if (GetClientTeam(client) != TEAM_INFECTED)                         { return Plugin_Continue; }
    if (GetEntProp(client, Prop_Send, "m_zombieClass") != ZC_JOCKEY)    { return Plugin_Continue; }
    
    // play random sound (delayed
    CreateTimer(GetConVarFloat(hJockeySoundTime), delayedJockeySound, client);
    
    return Plugin_Continue;
}


public Action:delayedJockeySound(Handle:timer, any:client)
{
    new bForced = GetConVarBool(hJockeySoundAlways);
    
    // play only if jockey is silent (or if forced)
    if (hJockeyLaughingTimer[client] && !bForced) {
        PrintToServer("[uj] Jockey [%d] was not silent.", client);
        return;
    }
    
    PrintToServer("[uj] Jockey [%d] unsilenced.%s", client, (bForced)?" (forced)":"");
    
    new rndPick = GetRandomInt(0, MAX_JOCKEYSOUND);
    EmitSoundToAll(sJockeySound[rndPick], client, SNDCHAN_VOICE);
}



// for checking if jockey is really silent

public Action:HookSound_Callback(Clients[64], &NumClients, String:StrSample[PLATFORM_MAX_PATH], &Entity)
{
    // ignore any other sound than jockey voice
    if (StrContains(StrSample, "/jockey/voice/", false) == -1)  return Plugin_Continue;
    //if (StrContains(StrSample, "/idle/", false) == -1)          return Plugin_Continue;
    
    #if DEBUG
    PrintToChatAll("[uj] Jockey [%d] making noise [%s]...", Entity, StrSample);
    #endif
    
    if (!IsClientAndInGame(Entity)) { return Plugin_Continue; }
    fJockeyLaughingStop[Entity] = GetTickedTime() + JOCKEY_VOICE_TIMEOUT;
    if (hJockeyLaughingTimer[Entity] == INVALID_HANDLE) {
        hJockeyLaughingTimer[Entity] = CreateTimer(SOUND_CHECK_INTERVAL, Timer_IsJockeyLaughing, Entity, TIMER_REPEAT);
    }
    
    return Plugin_Continue;
}

public Action:Timer_IsJockeyLaughing(Handle:hTimer, any:Client)
{
    if (fJockeyLaughingStop[Client] >= GetTickedTime()) {
        if (IsClientAndInGame(Client)) {
            if (IsPlayerAlive(Client)) {
                #if DEBUG
                PrintToChatAll("[uj] Jockey [%d] still making noise...",Client);
                #endif
                return Plugin_Continue;
            }
        }
    }
    
    hJockeyLaughingTimer[Client] = INVALID_HANDLE;
    return Plugin_Stop;
}  

/* --------------------------------------
*     Shared function(s)
* -------------------------------------- */

bool:IsClientAndInGame(index)
{
    return (index > 0 && index <= MaxClients && IsClientInGame(index));
}

