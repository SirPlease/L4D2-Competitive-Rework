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
    name = "SMAC ESEA Global Banlist",
    author = SMAC_AUTHOR,
    description = "Kicks players on the E-Sports Entertainment banlist",
    version = SMAC_VERSION,
    url = "www.ESEA.net"
};

/* Globals */
#define ESEA_HOSTNAME	"play.esea.net"
#define ESEA_QUERY		"index.php?s=support&d=ban_list&type=1&format=csv"

ConVar g_hCvarKick;
Handle g_hBanlist = INVALID_HANDLE;

/* Plugin Functions */
public void OnPluginStart()
{
    LoadTranslations("smac.phrases");

    // Convars.
    g_hCvarKick = SMAC_CreateConVar("smac_esea_kick", "1", "Automatically kick players on the ESEA banlist.", 0, true, 0.0, true, 1.0);

    // Initialize.
    g_hBanlist = CreateTrie();

    ESEA_DownloadBanlist();
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

    bool bShouldLog;

    if (GetTrieValue(g_hBanlist, sAuthID, bShouldLog) && SMAC_CheatDetected(client, Detection_GlobalBanned_ESEA, INVALID_HANDLE) == Plugin_Continue)
    {
        if (bShouldLog)
        {
            SMAC_PrintAdminNotice("%N | %s | ESEA Ban", client, sAuthID);
            SetTrieValue(g_hBanlist, sAuthID, 0);
        }

        if (GetConVarBool(g_hCvarKick))
        {
            if (bShouldLog)
            {
                SMAC_LogAction(client, "was kicked.");
            }

            KickClient(client, "%t", "SMAC_GlobalBanned", "ESEA", "www.ESEA.net");
        }
        else if (bShouldLog)
        {
            SMAC_LogAction(client, "is on the banlist.");
        }
    }
}

void ESEA_DownloadBanlist()
{
    // Begin downloading the banlist in memory.
    Handle socket = SocketCreate(SOCKET_TCP, OnSocketError);
    SocketSetOption(socket, ConcatenateCallbacks, 8192);
    SocketConnect(socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, ESEA_HOSTNAME, 80);
}

void ESEA_ParseBan(char[] baninfo)
{
    if (baninfo[0] != '"')
    {
        return;
    }
    
    // Parse one line of the CSV banlist.
    char sAuthID[MAX_AUTHID_LENGTH];

    int length = FindCharInString(baninfo[3], '"') + 9;
    FormatEx(sAuthID, length, "STEAM_0:%s", baninfo[3]);

    SetTrieValue(g_hBanlist, sAuthID, 1);
}

public void OnSocketConnected(Handle socket, any arg)
{
    char sRequest[256];

    FormatEx(sRequest,
        sizeof(sRequest),
        "GET /%s HTTP/1.0\r\nHost: %s\r\nCookie: viewed_welcome_page=1\r\nConnection: close\r\n\r\n",
        ESEA_QUERY,
        ESEA_HOSTNAME);

    SocketSend(socket, sRequest);
}

public void OnSocketReceive(Handle socket, char[] data, const int size, any arg)
{
    // Parse raw data as it's received.
    static bool bParsedHeader, bSplitData;
    char sBuffer[256];
    int idx, length;

    if (!bParsedHeader)
    {
        // Parse and skip header data.
        if ((idx = StrContains(data, "\r\n\r\n")) == -1)
        {
            return;
        }
        
        idx += 4;

        // Skip the first line as well (column names).
        int offset = FindCharInString(data[idx], '\n');

        if (offset == -1)
        {
            return;
        }

        idx += offset + 1;
        bParsedHeader = true;
    }

    // Check if we had split data from the previous callback.
    if (bSplitData)
    {
        length = FindCharInString(data[idx], '\n');

        if (length == -1)
        {
            return;
        }

        length += 1;
        int maxsize = strlen(sBuffer) + length;

        if (maxsize <= sizeof(sBuffer))
        {
            Format(sBuffer, maxsize, "%s%s", sBuffer, data[idx]);
            ESEA_ParseBan(sBuffer);
        }

        idx += length;
        bSplitData = false;
    }

    // Parse incoming data.
    while (idx < size)
    {
        length = FindCharInString(data[idx], '\n');

        if (length == -1)
        {
            FormatEx(sBuffer, sizeof(sBuffer), "%s", data[idx]);

            bSplitData = true;
            return;
        }
        else if (length < sizeof(sBuffer))
        {
            length += 1;

            FormatEx(sBuffer, length, "%s", data[idx]);
            ESEA_ParseBan(sBuffer);

            idx += length;
        }
    }
}

public void OnSocketDisconnected(Handle socket, any arg)
{
    CloseHandle(socket);

    // Check all players against the new list.
    char sAuthID[MAX_AUTHID_LENGTH];

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientAuthorized(i) && GetClientAuthId(i, AuthId_Steam2, sAuthID, sizeof(sAuthID), false))
        {
            OnClientAuthorized(i, sAuthID);
        }
    }
}

public void OnSocketError(Handle socket, const int errorType, const int errorNum, any arg)
{
    CloseHandle(socket);
}