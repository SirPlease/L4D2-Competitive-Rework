/*
    SourceMod Anti-Cheat
    Copyright (C) 2011-2016 SMAC Development Team
    Copyright (C) 2007-2011 CodingDirect LLC

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
#pragma semicolon 1
#pragma newdecls required

/* SM Includes */
#include <sourcemod>
#include <sdktools>
#include <smac>
#include <colors>

/* Plugin Info */
public Plugin myinfo =
{
    name =          "SourceMod Anti-Cheat",
    author =        SMAC_AUTHOR,
    description =   "Open source anti-cheat plugin for SourceMod",
    version =       SMAC_VERSION,
    url =           SMAC_URL
};

/* Globals */
#define SOURCEBANS_AVAILABLE()      (GetFeatureStatus(FeatureType_Native, "SBBanPlayer") == FeatureStatus_Available) // Depreciated in SB++, leaving in for legacy/compatibility!
#define SBPP_AVAILABLE()            (GetFeatureStatus(FeatureType_Native, "SBPP_BanPlayer") == FeatureStatus_Available)
#define SOURCEIRC_AVAILABLE()       (GetFeatureStatus(FeatureType_Native, "IRC_MsgFlaggedChannels") == FeatureStatus_Available)
#define IRCRELAY_AVAILABLE()        (GetFeatureStatus(FeatureType_Native, "IRC_Broadcast") == FeatureStatus_Available)

enum IrcChannel
{
    IrcChannel_Public  = 1,
    IrcChannel_Private = 2,
    IrcChannel_Both    = 3
}

native void SBBanPlayer(int client,int target,int time, char[] reason); // Depreciated in SB++, leaving in for legacy/compatibility!
native void SBPP_BanPlayer(int client,int target,int time, char[] reason);
native any IRC_MsgFlaggedChannels(const char[] flag, const char[] format, any ...);
native any IRC_Broadcast(IrcChannel type, const char[] format, any ...);

GameType g_Game = Game_Unknown;
ConVar g_hCvarVersion = null;
ConVar g_hCvarWelcomeMsg = null;
ConVar g_hCvarBanDuration = null;
ConVar g_hCvarLogVerbose = null;
ConVar g_hCvarIrcMode = null;
char g_sLogPath[PLATFORM_MAX_PATH];

/* Plugin Functions */
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    // Detect game.
    char sGame[64];
    GetGameFolderName(sGame, sizeof(sGame));
    EngineVersion iEngine = GetEngineVersion();

    /*
        Notes: Removed GMOD support as SourceMod doesn't support Gmod anymore.

        Todo: Figure out which EngineVersion INSMod, FoF, HL2CTF, HIDDEN and ZPS use
        from https://sm.alliedmods.net/new-api/halflife/EngineVersion

        Those could be switched over too. Also, is cstrike_beta even still a thing?
    */
 
    if (iEngine == Engine_TF2) 
    {
        g_Game = Game_TF2;
    }
    else if (iEngine == Engine_CSS) 
    {
        g_Game = Game_CSS;
    }
    else if (iEngine == Engine_CSGO)
    {
        g_Game = Game_CSGO;
    }
    else if (iEngine == Engine_DODS) 
    {
        g_Game = Game_DODS;
    }
    else if (iEngine == Engine_Left4Dead)
    {
        g_Game = Game_L4D;
    }
    else if (iEngine == Engine_Left4Dead2)
    {
        g_Game = Game_L4D2;
    }
    else if (iEngine == Engine_HL2DM)
    {
        g_Game = Game_HL2DM;
    }
    else if (iEngine == Engine_NuclearDawn)
    {
        g_Game = Game_ND;
    }
    else if (iEngine == Engine_Insurgency)
    {    
        g_Game = Game_INS;
    }
    else if (iEngine ==  Engine_BlackMesa)
    {
        g_Game = Game_BM;
    }
    else if (iEngine == Engine_SDK2013)
    {
        if (StrEqual(sGame, "fof"))
        {        
            g_Game = Game_FOF;
        }
        else if (StrEqual(sGame, "zps")) 
        {
            g_Game = Game_ZPS;
        }
        else if (StrEqual(sGame, "zps")) 
        {
            g_Game = Game_ZMR;
        }
        else
        {
            g_Game = Game_Unknown;
        }
    }
    else if (iEngine == Engine_SourceSDK2006)
    {
        if (StrEqual(sGame, "hl2ctf"))
        {        
            g_Game = Game_HL2CTF;
        }
        else if (StrEqual(sGame, "hidden")) 
        {
            g_Game = Game_HIDDEN;
        }
        else
        {
            g_Game = Game_Unknown;
        }
    }
    else if (iEngine == Engine_Unknown) 
    {
        g_Game = Game_Unknown;
    }
    else
    {
        g_Game = Game_Unknown;
    }
    
    // Path used for logging.
    BuildPath(Path_SM, g_sLogPath, sizeof(g_sLogPath), "logs/SMAC.log");

    // Optional dependencies.
    MarkNativeAsOptional("SBBanPlayer");
    MarkNativeAsOptional("SBPP_BanPlayer");
    MarkNativeAsOptional("IRC_MsgFlaggedChannels");
    MarkNativeAsOptional("IRC_Broadcast");

    API_Init();
    RegPluginLibrary("smac");

    return APLRes_Success;
}

public void OnPluginStart()
{
    LoadTranslations("smac.phrases");

    // Convars.
    g_hCvarVersion = CreateConVar("smac_version", SMAC_VERSION, "SourceMod Anti-Cheat", FCVAR_NOTIFY|FCVAR_DONTRECORD);
    OnVersionChanged(g_hCvarVersion, "", "");
    g_hCvarVersion.AddChangeHook(OnVersionChanged);

    g_hCvarWelcomeMsg = CreateConVar("smac_welcomemsg", "0", "Display a message saying that your server is protected.", 0, true, 0.0, true, 1.0);
    g_hCvarBanDuration = CreateConVar("smac_ban_duration", "0", "The duration in minutes used for automatic bans. (0 = Permanent)", 0, true, 0.0);
    g_hCvarLogVerbose = CreateConVar("smac_log_verbose", "0", "Include extra information about a client being logged.", 0, true, 0.0, true, 1.0);
    g_hCvarIrcMode = CreateConVar("smac_irc_mode", "1", "Which messages should be sent to IRC plugins. (1 = Admin notices, 2 = Mimic log)", 0, true, 1.0, true, 2.0);

    // Commands.
    RegAdminCmd("smac_status", Command_Status, ADMFLAG_GENERIC, "View the server's player status.");
}

public void OnAllPluginsLoaded()
{
    // Don't clutter the config if they aren't using IRC anyway.
    if (!SOURCEIRC_AVAILABLE() && !IRCRELAY_AVAILABLE())
    {
        g_hCvarVersion.Flags |= FCVAR_DONTRECORD;
    }

    // Wait for other modules to create their convars.
    AutoExecConfig(true, "smac");

    PrintToServer("SourceMod Anti-Cheat %s has been successfully loaded.", SMAC_VERSION);
}

public void OnVersionChanged(ConVar convar, char[] oldValue, char[] newValue)
{
    if (!StrEqual(newValue, SMAC_VERSION))
    {
        convar.SetString(SMAC_VERSION, false, false);
    }
}

public void OnClientPutInServer(int client)
{
    if (g_hCvarWelcomeMsg.BoolValue)
    {
        CreateTimer(10.0, Timer_WelcomeMsg, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action Timer_WelcomeMsg(Handle timer, any serial)
{
    int client = GetClientFromSerial(serial);

    if (IS_CLIENT(client) && IsClientInGame(client))
    {
        CPrintToChat(client, "%t%t", "SMAC_Tag", "SMAC_WelcomeMsg");
    }

    return Plugin_Stop;
}

public Action Command_Status(int client, int args)
{
    PrintToConsole(client, "%s  %-40s %s", "UserID", "AuthID", "Name");

    char sAuthID[MAX_AUTHID_LENGTH];

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientConnected(i))
        {
            continue;
        }
        
        if (!GetClientAuthId(i, AuthId_Steam2, sAuthID, sizeof(sAuthID), true))
        {
            if (GetClientAuthId(i, AuthId_Steam2, sAuthID, sizeof(sAuthID), false))
            {
                Format(sAuthID, sizeof(sAuthID), "%s (Not Validated)", sAuthID);
            }
            else
            {
                strcopy(sAuthID, sizeof(sAuthID), "Unknown");
            }
        }

        PrintToConsole(client, "%6d  %-40s %N", GetClientUserId(i), sAuthID, i);
    }

    return Plugin_Handled;
}

void SMAC_RelayToIRC(const char[] format, any ...)
{
    char sBuffer[256];
    SetGlobalTransTarget(LANG_SERVER);
    VFormat(sBuffer, sizeof(sBuffer), format, 2);

    if (SOURCEIRC_AVAILABLE())
    {
        IRC_MsgFlaggedChannels("ticket", sBuffer);
    }
    if (IRCRELAY_AVAILABLE())
    {
        IRC_Broadcast(IrcChannel_Private, sBuffer);
    }
}

/* API - Natives & Forwards */

Handle g_OnCheatDetected = INVALID_HANDLE;

void API_Init()
{
    CreateNative("SMAC_GetGameType",        Native_GetGameType);
    CreateNative("SMAC_Log",                Native_Log);
    CreateNative("SMAC_LogAction",          Native_LogAction);
    CreateNative("SMAC_Ban",                Native_Ban);
    CreateNative("SMAC_PrintAdminNotice",   Native_PrintAdminNotice);
    CreateNative("SMAC_CreateConVar",       Native_CreateConVar);
    CreateNative("SMAC_CheatDetected",      Native_CheatDetected);

    g_OnCheatDetected = CreateGlobalForward("SMAC_OnCheatDetected", ET_Event, Param_Cell, Param_String, Param_Cell, Param_Cell);
}

// native GameType:SMAC_GetGameType();
public any Native_GetGameType(Handle plugin, int numParams)
{
    return view_as<GameType>(g_Game);
}

// native SMAC_Log(const String:format[], any:...);
public any Native_Log(Handle plugin, int numParams)
{
    char sFilename[64], sBuffer[256];
    GetPluginBasename(plugin, sFilename, sizeof(sFilename));
    FormatNativeString(0, 1, 2, sizeof(sBuffer), _, sBuffer);
    LogToFileEx(g_sLogPath, "[%s] %s", sFilename, sBuffer);

    // Relay log to IRC.
    if (GetConVarInt(g_hCvarIrcMode) == 2)
    {
        SMAC_RelayToIRC("[%s] %s", sFilename, sBuffer);
    }
}

// native SMAC_LogAction(client, const String:format[], any:...);
public any Native_LogAction(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    if (!IS_CLIENT(client) || !IsClientConnected(client))
    {
        ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
    }

    char sAuthID[MAX_AUTHID_LENGTH];
    if (!GetClientAuthId(client, AuthId_Steam2, sAuthID, sizeof(sAuthID), true))
    {
        if (GetClientAuthId(client, AuthId_Steam2, sAuthID, sizeof(sAuthID), false))
        {
            Format(sAuthID, sizeof(sAuthID), "%s (Not Validated)", sAuthID);
        }
        else
        {
            strcopy(sAuthID, sizeof(sAuthID), "Unknown");
        }
    }

    char sIP[17];
    if (!GetClientIP(client, sIP, sizeof(sIP)))
    {
        strcopy(sIP, sizeof(sIP), "Unknown");
    }

    char sVersion[16], sFilename[64], sBuffer[512];
    GetPluginInfo(plugin, PlInfo_Version, sVersion, sizeof(sVersion));
    GetPluginBasename(plugin, sFilename, sizeof(sFilename));
    FormatNativeString(0, 2, 3, sizeof(sBuffer), _, sBuffer);

    // Verbose client logging.
    if (GetConVarBool(g_hCvarLogVerbose) && IsClientInGame(client))
    {
        char sMap[MAX_MAPNAME_LENGTH], sWeapon[32];
        float vOrigin[3], vAngles[3];
        int iTeam, iLatency;

        GetCurrentMap(sMap, sizeof(sMap));
        GetClientAbsOrigin(client, vOrigin);
        GetClientEyeAngles(client, vAngles);
        GetClientWeapon(client, sWeapon, sizeof(sWeapon));
        iTeam = GetClientTeam(client);
        iLatency = RoundToNearest(GetClientAvgLatency(client, NetFlow_Outgoing) * 1000.0);

        LogToFileEx(g_sLogPath,
        "[%s | %s] %N (ID: %s | IP: %s) %s\n\tMap: %s | Origin: %.0f %.0f %.0f | Angles: %.0f %.0f %.0f | Weapon: %s | Team: %i | Latency: %ims",
            sFilename,
            sVersion,
            client,
            sAuthID,
            sIP,
            sBuffer,
            sMap,
            vOrigin[0], vOrigin[1], vOrigin[2],
            vAngles[0], vAngles[1], vAngles[2],
            sWeapon,
            iTeam,
            iLatency);
    }
    else
    {
        LogToFileEx(g_sLogPath, "[%s | %s] %N (ID: %s | IP: %s) %s", sFilename, sVersion, client, sAuthID, sIP, sBuffer);
    }

    // Relay minimal log to IRC.
    if (GetConVarInt(g_hCvarIrcMode) == 2)
    {
        SMAC_RelayToIRC("[%s | %s] %N (ID: %s | IP: %s) %s", sFilename, sVersion, client, sAuthID, sIP, sBuffer);
    }
}

// native SMAC_Ban(client, const String:reason[], any:...);
public any Native_Ban(Handle plugin, int numParams)
{
    char sVersion[16], sReason[256];
    int client = GetNativeCell(1);
    int duration = g_hCvarBanDuration.IntValue;

    GetPluginInfo(plugin, PlInfo_Version, sVersion, sizeof(sVersion));
    FormatNativeString(0, 2, 3, sizeof(sReason), _, sReason);
    Format(sReason, sizeof(sReason), "SMAC %s: %s", sVersion, sReason);

    if (SBPP_AVAILABLE())
    {
        SBPP_BanPlayer(0, client, duration, sReason);
    }
    else if (SOURCEBANS_AVAILABLE())
    {
        SBBanPlayer(0, client, duration, sReason);
    }
    else
    {
        char sKickMsg[256];
        FormatEx(sKickMsg, sizeof(sKickMsg), "%T", "SMAC_Banned", client);
        BanClient(client, duration, BANFLAG_AUTO, sReason, sKickMsg, "SMAC");
    }

    if(IsClientConnected(client))
    {
        KickClient(client, sReason);
    }
}

// native SMAC_PrintAdminNotice(const String:format[], any:...);
public any Native_PrintAdminNotice(Handle plugin, int numParams)
{
    char sBuffer[192];

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && CheckCommandAccess(i, "smac_admin_notices", ADMFLAG_GENERIC, true))
        {
            SetGlobalTransTarget(i);
            FormatNativeString(0, 1, 2, sizeof(sBuffer), _, sBuffer);
            CPrintToChat(i, "%t%s", "SMAC_Tag", sBuffer);
        }
    }

    // Relay admin notice to IRC.
    if (g_hCvarIrcMode.IntValue == 1)
    {
        SetGlobalTransTarget(LANG_SERVER);
        FormatNativeString(0, 1, 2, sizeof(sBuffer), _, sBuffer);
        Format(sBuffer, sizeof(sBuffer), "%t%s", "SMAC_Tag", sBuffer);
        CRemoveTags(sBuffer, sizeof(sBuffer));
        SMAC_RelayToIRC(sBuffer);
    }
}

// native Handle:SMAC_CreateConVar(const String:name[], const String:defaultValue[], const String:description[]="", flags=0, bool:hasMin=false, Float:min=0.0, bool:hasMax=false, Float:max=0.0);
public any Native_CreateConVar(Handle plugin, int numParams)
{
    char name[64], defaultValue[16], description[192];
    GetNativeString(1, name, sizeof(name));
    GetNativeString(2, defaultValue, sizeof(defaultValue));
    GetNativeString(3, description, sizeof(description));

    int flags = GetNativeCell(4);
    bool hasMin = view_as<bool>(GetNativeCell(5));
    float min = view_as<float>(GetNativeCell(6));
    bool hasMax = view_as<bool>(GetNativeCell(7));
    float max = view_as<float>(GetNativeCell(8));

    char sFilename[64];
    GetPluginBasename(plugin, sFilename, sizeof(sFilename));
    Format(description, sizeof(description), "[%s] %s", sFilename, description);

    return CreateConVar(name, defaultValue, description, flags, hasMin, min, hasMax, max);
}

// native Action:SMAC_CheatDetected(client, DetectionType:type = Detection_Unknown, Handle:info = INVALID_HANDLE);
public int Native_CheatDetected(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    if (!IS_CLIENT(client) || !IsClientConnected(client))
    {
        ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
    }

    // Block duplicate detections.
    if (IsClientInKickQueue(client))
    {
        return view_as<int>(Plugin_Handled);
    }

    char sFilename[64];
    GetPluginBasename(plugin, sFilename, sizeof(sFilename));

    DetectionType type = Detection_Unknown;
    Handle info = INVALID_HANDLE;

    if (numParams == 3)
    {
        // caller is using newer cheat detected native
        type = view_as<DetectionType>(GetNativeCell(2));
        info = view_as<Handle>(GetNativeCell(3));
    }

    // forward Action:SMAC_OnCheatDetected(client, const String:module[], DetectionType:type, Handle:info);
    Action result = Plugin_Continue;
    Call_StartForward(g_OnCheatDetected);
    Call_PushCell(client);
    Call_PushString(sFilename);
    Call_PushCell(type);
    Call_PushCell(info);
    Call_Finish(result);

    return view_as<int>(result);
}
