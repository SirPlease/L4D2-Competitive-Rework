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
#undef REQUIRE_EXTENSIONS
#tryinclude <connect>

/* Plugin Info */
public Plugin myinfo =
{
    name =          "SMAC Client Protection",
    author =        SMAC_AUTHOR,
    description =   "Blocks general client exploits",
    version =       SMAC_VERSION,
    url =           SMAC_URL
};

/* Globals */
ConVar g_hCvarConnectSpam = null;
ConVar g_hCvarValidateAuth = null;
Handle g_hClientConnections = INVALID_HANDLE;
float g_fTeamJoinTime[MAXPLAYERS+1][6];
int g_iNameChanges[MAXPLAYERS+1];
int g_iAchievements[MAXPLAYERS+1];
bool g_bMapStarted = false;
bool g_bConnectExt = false;

/* Plugin Functions */
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    g_bMapStarted = late;
    return APLRes_Success;
}

public void OnPluginStart()
{
    LoadTranslations("smac.phrases");

    // Convars.
    g_hCvarConnectSpam = SMAC_CreateConVar("smac_antispam_connect", "2", "Block reconnection attempts for X seconds. (0 = Disabled)", 0, true, 0.0);
    g_hCvarValidateAuth = SMAC_CreateConVar("smac_validate_auth", "0", "Kick clients that fail to authenticate within 10 seconds of joining the server.", 0, true, 0.0, true, 1.0);
    g_hClientConnections = CreateTrie();

    // Hooks.
    if (SMAC_GetGameType() == Game_CSS || SMAC_GetGameType() == Game_TF2)
    {
        HookUserMessage(GetUserMessageId("TextMsg"), Hook_TextMsg, true);
    }

    HookEventEx("player_team", Event_PlayerTeam, EventHookMode_Pre);
    HookEvent("player_changename", Event_PlayerChangeName, EventHookMode_Post);
    HookEventEx("achievement_earned", Event_AchievementEarned, EventHookMode_Pre);
    CreateTimer(10.0, Timer_DecreaseCount, _, TIMER_REPEAT);

    // Check all clients.
    if (g_bMapStarted)
    {
        char sReason[256];

        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientConnected(i) && !OnClientConnect(i, sReason, sizeof(sReason)))
            {
                KickClient(i, "%s", sReason);
            }
        }
    }
}

public void OnMapStart()
{
    // Give time for players to connect before we start checking for spam.
    CreateTimer(20.0, Timer_MapStarted, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_MapStarted(Handle timer)
{
    g_bMapStarted = true;
    return Plugin_Stop;
}

public void OnMapEnd()
{
    g_bMapStarted = false;
    ClearTrie(g_hClientConnections);
}

public bool OnClientPreConnectEx(const char[] name, char password[255], const char[] ip, const char[] steamID, char rejectReason[255])
{
    g_bConnectExt = true;

    if (IsConnectSpamming(ip))
    {
        if (ShouldLogIP(ip))
        {
            SMAC_Log("%s (ID: %s | IP: %s) was temporarily banned for connection spam.", name, steamID, ip);
        }

        BanIdentity(ip, 1, BANFLAG_IP, "Spam Connecting", "SMAC");
        FormatEx(rejectReason, sizeof(rejectReason), "%T.", "SMAC_PleaseWait", LANG_SERVER);
        return false;
    }

    return true;
}

public bool OnClientConnect(int client, char[] rejectmsg,int size)
{
    if (IsFakeClient(client))
    {
        return true;
    }

    if (!g_bConnectExt)
    {
        char sIP[17];
        GetClientIP(client, sIP, sizeof(sIP));

        if (IsConnectSpamming(sIP))
        {
            if (ShouldLogIP(sIP))
            {
                SMAC_LogAction(client, "was temporarily banned for connection spam.");
            }

            BanIdentity(sIP, 1, BANFLAG_IP, "Spam Connecting", "SMAC");
            FormatEx(rejectmsg, size, "%T", "SMAC_PleaseWait", client);
            return false;
        }
    }

    if (!IsClientNameValid(client))
    {
        FormatEx(rejectmsg, size, "%T", "SMAC_ChangeName", client);
        return false;
    }

    return true;
}

public void OnClientPutInServer(int client)
{
    if (IsClientNew(client))
    {
        g_iNameChanges[client] = 0;
        g_iAchievements[client] = 0;
    }

    // Give the client 10s to fully authenticate.
    if (!IsFakeClient(client) && !IsClientAuthorized(client) && GetConVarBool(g_hCvarValidateAuth))
    {
        CreateTimer(10.0, Timer_ValidateAuth, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action Timer_ValidateAuth(Handle timer, any serial)
{
    int client = GetClientFromSerial(serial);

    if (IS_CLIENT(client) && !IsClientAuthorized(client))
    {
        KickClient(client, "%t", "SMAC_FailedAuth");
    }

    return Plugin_Stop;
}

public void OnClientSettingsChanged(int client)
{
    if (!IsFakeClient(client) && !IsClientNameValid(client))
    {
        KickClient(client, "%t", "SMAC_ChangeName");
    }
}

public void OnClientDisconnect_Post(int client)
{
    for (int i = 0; i < sizeof(g_fTeamJoinTime[]); i++)
    {
        g_fTeamJoinTime[client][i] = 0.0;
    }
}

public Action Hook_TextMsg(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
    // Name spam notices will only be sent to the offending client.
    if (!reliable || playersNum != 1)
    {
        return Plugin_Continue;
    }

    // The message we are looking for is sent to chat.
    int destination = BfReadByte(msg);

    if (destination != 3)
    {
        return Plugin_Continue;
    }

    char sBuffer[64];
    BfReadString(msg, sBuffer, sizeof(sBuffer));

    if (StrEqual(sBuffer, "#Name_change_limit_exceeded"))
    {
        int client = players[0];

        if (!IsFakeClient(client) && SMAC_CheatDetected(client, Detection_NameChangeSpam, INVALID_HANDLE) == Plugin_Continue)
        {
            SMAC_LogAction(client, "was kicked for name change spam.");
            KickClient(client, "%t", "SMAC_CommandSpamKick");
        }
    }

    return Plugin_Continue;
}

public Action Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
    if (dontBroadcast)
    {
        return Plugin_Continue;
    }

    // Don't broadcast team changes if they're being spammed.
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    
    if (IS_CLIENT(client))
    {
        float fGameTime = GetGameTime();
        int team = GetEventInt(event, "team");

        if (team < 0 || team >= sizeof(g_fTeamJoinTime[]))
        {
            team = 0;
        }

        if (g_fTeamJoinTime[client][team] > fGameTime)
        {
            SetEventBroadcast(event, true);
        }

        g_fTeamJoinTime[client][team] = fGameTime + 30.0;
    }

    return Plugin_Continue;
}

public Action Event_PlayerChangeName(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if (IS_CLIENT(client) && IsClientInGame(client) && !IsFakeClient(client) && ++g_iNameChanges[client] >= 5)
    {
        if (SMAC_CheatDetected(client, Detection_NameChangeSpam, INVALID_HANDLE) == Plugin_Continue)
        {
            SMAC_LogAction(client, "was kicked for name change spam.");
            KickClient(client, "%t", "SMAC_CommandSpamKick");
        }

        g_iNameChanges[client] = 0;
    }
}

public Action Event_AchievementEarned(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetEventInt(event, "player");

    if (IS_CLIENT(client) && ++g_iAchievements[client] >= 5)
    {
        return Plugin_Stop;
    }

    return Plugin_Continue;
}

public Action Timer_DecreaseCount(Handle timer)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (g_iNameChanges[i])
        {
            g_iNameChanges[i]--;
        }

        if (g_iAchievements[i])
        {
        	g_iAchievements[i]--;
        }
    }

    return Plugin_Continue;
}

bool IsClientNameValid(int client)
{
    char sName[MAX_NAME_LENGTH], sChar;

    GetClientName(client, sName, sizeof(sName));
    int iSize = strlen(sName);

    if (iSize < 2 || sName[0] == '&' || IsCharSpace(sName[0]) || IsCharSpace(sName[iSize-1]))
    {
        return false;
    }

    for (int i = 0; i < iSize; i++)
    {
        sChar = sName[i];

        // Check unicode characters.
        int bytes = IsCharMB(sChar);

        if (bytes > 1)
        {
            if (!IsMBCharValid(sName[i], bytes))
            {
                return false;
            }

            i += bytes - 1;
        }
        else if (sChar < 32 || sChar == '%' || sChar == 0x7F)
        {
            return false;
        }
    }

    return true;
}

bool IsMBCharValid(const char[] mbchar,int numbytes)
{
    /*
    * A blacklist of unicode characters.
    * Mostly a variation of zero-width and spaces.
    */
    int wchar = UTF8ToWChar(mbchar, numbytes);

    if (wchar == -1)
    {
        return false;
    }

    // Check to see if any of these characters exist in the name.
    // If so, it is not valid.
    switch (wchar)
    {
        case
            0x00AD,     // Soft Hyphen (shows as white space)
            0x05BF,     // Hebrew Point Rafe
            0x0670,     // Latin Small Letter Turned K
            0x06E7,     // Arabic Small High Yeh
            0x06E8,     // Arabic Small High Noon
            0x0711,     // Caron
            0x0A51,     // Gurmukhi Sign Udaat
            0x0E31,     // Thai Character Mai Han-Akat
            0x0EB1,     // Lao Vowel Sign Mai Kan
            0x0EBB,     // Lao Vowel Sign Mai Kon
            0x0EBC,     // Lao Semivowel Sign Lo
            0x0F18,     // Tibetan Astrological Sign -Khyud Pa
            0x0F19,     // Tibetan Astrological Sign Sdong Tshugs
            0x0F35,     // Tibetan Mark Ngas Bzung Nyi Zla
            0x0F37,     // Tibetan Mark Ngas Bzung Sgor Rtags
            0x0F39,     // Tibetan Mark Tsa -Phru
            0x135F,     // Ethiopic Combining Gemination Mark
            0x18A9,     // Mongolian Letter Ali Gali Dagalga
            0x20F0,     // Combining Asterisk Above
            0x2800,     // Gujarati Abbreviation Sign
            0x3000,     // Tamil Letter Sa
            0x3164,     // Telugu (unicode group, no name, just white space)
            0xFB1E,     // Hebrew Point Judeo-Spanish Varika
            0xFEFF,     // Zero Width No-Break Space
            0xFFA0:     // Halfwidth Hangul Filler (white space)
                return false;
    }

    // If any unicode characters in a players name are between any of these
    // unicode values, it is not a valid character!
    if ((0x0080 <= wchar <= 0x00A0) ||
        (0x0300 <= wchar <= 0x036F) ||
        (0x0483 <= wchar <= 0x0487) ||
        (0x0591 <= wchar <= 0x05BD) ||
        (0x05C1 <= wchar <= 0x05C5) ||
        (0x0610 <= wchar <= 0x061A) ||
        (0x064B <= wchar <= 0x065F) ||
        (0x06D6 <= wchar <= 0x06DC) ||
        (0x06DF <= wchar <= 0x06E4) ||
        (0x06EA <= wchar <= 0x06ED) ||
        (0x0730 <= wchar <= 0x074A) ||
        (0x07A6 <= wchar <= 0x07B0) ||
        (0x07EB <= wchar <= 0x07F3) ||
        (0x0E34 <= wchar <= 0x0E3A) ||
        (0x0E47 <= wchar <= 0x0E4E) ||
        (0x0EB4 <= wchar <= 0x0EB9) ||
        (0x0EC8 <= wchar <= 0x0ECD) ||
        (0x0F71 <= wchar <= 0x0F7E) ||
        (0x0F80 <= wchar <= 0x0F87) ||
        (0x0F8D <= wchar <= 0x0F97) ||
        (0x115A <= wchar <= 0x1160) ||
        (0x11A3 <= wchar <= 0x11A7) ||
        (0x180B <= wchar <= 0x180F) ||
        (0x1DC0 <= wchar <= 0x1DCA) ||
        (0x1DFC <= wchar <= 0x1DFF) ||
        (0x2000 <= wchar <= 0x200F) ||
        (0x2028 <= wchar <= 0x202F) ||
        (0x205F <= wchar <= 0x206F) ||
        (0x302A <= wchar <= 0x302D) ||
        (0x3099 <= wchar <= 0x309A) ||
        (0xFE20 <= wchar <= 0xFE26) ||
        (0xFFF9 <= wchar <= 0xFFFF))
        return false;

    return true;
}

int UTF8ToWChar(const char[] mbchar,int numbytes)
{
    static const int mask[] = { 0, 0x7F, 0x1F, 0x0F, 0x07, 0x03, 0x01 };

    if (numbytes > 6)
    {
        return -1;
    }

    // First byte minus length tag
    int wchar = (mbchar[0] & mask[numbytes]);

    for (int i = 1; i < numbytes; i++)
    {
        // Subsequent bytes must start with 10
        if ((mbchar[i] & 0xC0) != 0x80)
        {
            return -1;
        }

        wchar <<= 6; // 6 bits of data in each subsequent byte
        wchar |= (mbchar[i] & 0x3F);
    }

    return wchar;
}

bool IsConnectSpamming(const char[] ip)
{
    if (!g_bMapStarted || !IsServerProcessing())
    {
        return false;
    }

    static Handle hIgnoreList = INVALID_HANDLE;

    if (hIgnoreList == INVALID_HANDLE)
    {
        hIgnoreList = CreateTrie();
    }

    float fSpamTime = GetConVarFloat(g_hCvarConnectSpam);

    if (fSpamTime > 0.0)
    {
        char sTempIP[17], dummy;

        // Add any LAN IPs to the ignore list.
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientAuthorized(i) && GetClientIP(i, sTempIP, sizeof(sTempIP)) && StrEqual(ip, sTempIP))
            {
                SetTrieValue(hIgnoreList, ip, 1);
                break;
            }
        }

        if (!GetTrieValue(hIgnoreList, ip, dummy))
        {
            if (GetTrieValue(g_hClientConnections, ip, dummy))
            {
                return true;
            }
            else if (SetTrieValue(g_hClientConnections, ip, 1))
            {
                CreateTimer(fSpamTime, Timer_AntiSpamConnect, IPToLong(ip));
            }
        }
    }

    return false;
}

bool ShouldLogIP(const char[] ip)
{
    /* Only log each IP once to prevent log spam. */
    static Handle hLogList = INVALID_HANDLE;

    if (hLogList == INVALID_HANDLE)
    {
        hLogList = CreateTrie();
    }

    int dummy;

    if (GetTrieValue(hLogList, ip, dummy))
    {
        return false;
    }

    SetTrieValue(hLogList, ip, 1);
    return true;
}

public Action Timer_AntiSpamConnect(Handle timer, any ip)
{
    char sIP[17];
    LongToIP(ip, sIP, sizeof(sIP));
    RemoveFromTrie(g_hClientConnections, sIP);

    return Plugin_Stop;
}
