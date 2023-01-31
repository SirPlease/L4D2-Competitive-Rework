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
#include <socket>
#include <smac>

/* Plugin Info */
public Plugin myinfo =
{
    name = "SMAC EAC Global Banlist",
    author = SMAC_AUTHOR,
    description = "Kicks players on the EasyAntiCheat banlist",
    version = SMAC_VERSION,
    url = "www.EasyAntiCheat.net"
};

/* Globals */
#define EAC_HOSTNAME	"easyanticheat.net"
#define EAC_QUERY		"check_guid.php?id="

enum BanType {
    Ban_None = 0,
    Ban_EAC,
    Ban_VAC
};

ConVar g_hCvarKick;
ConVar g_hCvarVAC;
Handle g_hBanlist = INVALID_HANDLE;
bool g_bLateLoad = false;

/* Plugin Functions */
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    g_bLateLoad = late;
    return APLRes_Success;
}

public void OnPluginStart()
{
    LoadTranslations("smac.phrases");

    // Convars.
    g_hCvarKick = SMAC_CreateConVar("smac_eac_kick", "1", "Automatically kick players on the EAC banlist.", 0, true, 0.0, true, 1.0);
    g_hCvarVAC = SMAC_CreateConVar("smac_eac_vac", "0", "Check players for previous VAC bans.", 0, true, 0.0, true, 1.0);

    // Initialize.
    g_hBanlist = CreateTrie();

    if (g_bLateLoad)
    {
        char sAuthID[MAX_AUTHID_LENGTH];

        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientAuthorized(i) && GetClientAuthId(i, AuthId_Steam2, sAuthID, sizeof(sAuthID), false))
            {
                OnClientAuthorized(i, sAuthID);
            }
        }
    }
}

public void OnClientAuthorized(int client, const char[] auth)
{
    if (IsFakeClient(client))
    {
        return;
    }
    
    // Workaround for universe digit change on L4D+ engines.
    char sAuthID[MAX_AUTHID_LENGTH];
    FormatEx(sAuthID, sizeof(sAuthID), "STEAM_0:%s", auth[8]);

    // Check the cache first.
    BanType banValue = Ban_None;

    if (GetTrieValue(g_hBanlist, sAuthID, banValue))
    {
        if (banValue == Ban_EAC || (banValue == Ban_VAC && GetConVarBool(g_hCvarVAC)))
        {
            if (GetConVarBool(g_hCvarKick) && SMAC_CheatDetected(client, Detection_GlobalBanned_EAC, INVALID_HANDLE) == Plugin_Continue)
            {
                KickClient(client, "%t", "SMAC_GlobalBanned", "EAC", "www.EasyAntiCheat.net");
            }
        }

        return;
    }
	
    // Clear a large cache to prevent slowdowns. Shouldn't reach this size anyway.
    if (GetTrieSize(g_hBanlist) > 50000)
    {
        ClearTrie(g_hBanlist);
    }
    
    // Check the banlist.
    Handle hPack = CreateDataPack();
    WritePackCell(hPack, GetClientUserId(client));
    WritePackString(hPack, sAuthID);

    Handle socket = SocketCreate(SOCKET_TCP, OnSocketError);
    SocketSetArg(socket, hPack);
    SocketSetOption(socket, ConcatenateCallbacks, 4096);
    SocketConnect(socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, EAC_HOSTNAME, 80);
}

public void OnSocketConnected(Handle socket, any hPack)
{
    char sAuthID[MAX_AUTHID_LENGTH], sRequest[256];
    ResetPack(hPack);
    ReadPackCell(hPack);
    ReadPackString(hPack, sAuthID, sizeof(sAuthID));
    FormatEx(sRequest, sizeof(sRequest), "GET /%s%s HTTP/1.0\r\nHost: %s\r\nConnection: close\r\n\r\n", EAC_QUERY, sAuthID, EAC_HOSTNAME);
    SocketSend(socket, sRequest);
}

public void OnSocketReceive(Handle socket, char[] data, const int size, any hPack)
{
    char sAuthID[MAX_AUTHID_LENGTH];
    int idx;
    ResetPack(hPack);
    ReadPackCell(hPack);
    ReadPackString(hPack, sAuthID, sizeof(sAuthID));

    // Check if we already have the result we needed.
    if (GetTrieValue(g_hBanlist, sAuthID, idx))
    {
        return;
    }

    // Make sure we're reading the actual banlist.
    if ((idx = StrContains(data, "[BEGIN LIST]")) == -1)
    {
        return;
    }

    // Look for the SteamID.
    int offset = StrContains(data[idx], sAuthID);

    if (offset == -1)
    {
        // Not on the banlist.
        SetTrieValue(g_hBanlist, sAuthID, Ban_None);
        return;
    }

    idx += offset;

    // Get ban info string.
    int length = FindCharInString(data[idx], '\n') + 1;

    char[] sBanInfo = new char[view_as<int>(length)];
    strcopy(sBanInfo, length, data[idx]);

    // 0 - SteamID
    // 1 - Ban reason
    // 2 - Ban date
    // 3 - Expiration date
    char sBanChunks[4][64];
    if (ExplodeString(sBanInfo, "|", sBanChunks, sizeof(sBanChunks), sizeof(sBanChunks[])) != 4)
    {
        return;
    }

    // Check if it's a VAC ban.
    if (StrEqual(sBanChunks[1], "VAC Banned"))
    {
        SetTrieValue(g_hBanlist, sAuthID, Ban_VAC);

        if (!GetConVarBool(g_hCvarVAC))
        {
            return;
        }
    }
    else
    {
        SetTrieValue(g_hBanlist, sAuthID, Ban_EAC);
    }

    // Notify and log.
    ResetPack(hPack);

    int client = GetClientOfUserId(ReadPackCell(hPack));

    if (!IS_CLIENT(client) || SMAC_CheatDetected(client, Detection_GlobalBanned_EAC, INVALID_HANDLE) != Plugin_Continue)
    {
        return;
    }

    SMAC_PrintAdminNotice("%N | %s | EAC: %s", client, sBanChunks[0], sBanChunks[1]);

    if (GetConVarBool(g_hCvarKick))
    {
        SMAC_LogAction(client, "was kicked. (Reason: %s | Expires: %s)", sBanChunks[1], sBanChunks[3]);
        KickClient(client, "%t", "SMAC_GlobalBanned", "EAC", "www.EasyAntiCheat.net");
    }
    else
    {
        SMAC_LogAction(client, "is on the banlist. (Reason: %s | Expires: %s)", sBanChunks[1], sBanChunks[3]);
    }
}

public void OnSocketDisconnected(Handle socket, any hPack)
{
    CloseHandle(hPack);
    CloseHandle(socket);
}

public void OnSocketError(Handle socket, const int errorType, const int errorNum, any hPack)
{
    CloseHandle(hPack);
    CloseHandle(socket);
}