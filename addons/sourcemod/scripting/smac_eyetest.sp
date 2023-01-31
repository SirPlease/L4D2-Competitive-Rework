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
#include <sdkhooks>
#include <smac>

/* Plugin Info */
public Plugin myinfo =
{
    name =          "SMAC Eye Angle Test",
    author =        SMAC_AUTHOR,
    description =   "Detects eye angle violations used in cheats",
    version =       SMAC_VERSION,
    url =           SMAC_URL
};

/* Globals */
enum ResetStatus {
    State_Okay = 0,
    State_Resetting,
    State_Reset
};

GameType g_Game = Game_Unknown;

ConVar g_hCvarBan = null;
ConVar g_hCvarCompat = null;
float g_fDetectedTime[MAXPLAYERS+1];

bool g_bInMinigun[MAXPLAYERS+1];

bool g_bPrevAlive[MAXPLAYERS+1];
int g_iPrevButtons[MAXPLAYERS+1] = {-1, ...};
int g_iPrevCmdNum[MAXPLAYERS+1] = {-1, ...};
int g_iPrevTickCount[MAXPLAYERS+1] = {-1, ...};
int g_iCmdNumOffset[MAXPLAYERS+1] = {1, ...};

ResetStatus g_TickStatus[MAXPLAYERS+1];
bool g_bLateLoad = false;

// Arbitrary group names for the purpose of differentiating eye angle detections.
enum EngineGroup {
    Group_Ignore = 0,
    Group_EP1,
    Group_EP2V,
    Group_L4D2
};

EngineVersion g_EngineVersion = Engine_Unknown;
EngineGroup g_EngineGroup = Group_Ignore;

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
    g_hCvarBan = SMAC_CreateConVar("smac_eyetest_ban", "0", "Automatically ban players on eye test detections.", 0, true, 0.0, true, 1.0);
    g_hCvarCompat = SMAC_CreateConVar("smac_eyetest_compat", "1", "Enable compatibility mode with third-party plugins. This will disable some detection methods.", 0, true, 0.0, true, 1.0);

    // Cache engine version and game type.
    g_EngineVersion = GetEngineVersion();

    if (g_EngineVersion == Engine_Unknown)
    {
        char sGame[64];
        GetGameFolderName(sGame, sizeof(sGame));
        SetFailState("Engine Version could not be determined for game: %s", sGame);
    }

    switch (g_EngineVersion)
    {
        case Engine_Original, Engine_DarkMessiah, Engine_SourceSDK2006, Engine_SourceSDK2007, Engine_BloodyGoodTime, Engine_EYE:
        {
            g_EngineGroup = Group_EP1;
        }
        case Engine_CSS, Engine_DODS, Engine_HL2DM, Engine_TF2:
        {
            g_EngineGroup = Group_EP2V;
        }
        case Engine_Left4Dead, Engine_Left4Dead2, Engine_NuclearDawn, Engine_CSGO:
        {
            g_EngineGroup = Group_L4D2;
        }
    }

    // Initialize.
    g_Game = SMAC_GetGameType();
    RequireFeature(FeatureType_Capability, FEATURECAP_PLAYERRUNCMD_11PARAMS, "This module requires a newer version of SourceMod.");

    // Check for existing minigun entities on late-load.
    if (g_bLateLoad && (g_Game == Game_L4D || g_Game == Game_L4D2))
    {
        char sClassname[32];
        int maxEdicts = GetEntityCount();
        for (int i = MaxClients + 1; i < maxEdicts; i++)
        {
            if (IsValidEdict(i) && GetEdictClassname(i, sClassname, sizeof(sClassname)))
            {
                OnEntityCreated(i, sClassname);
            }
        }

        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i))
            {
                g_bInMinigun[i] = true;
            }
        }
    }
}

public void OnClientDisconnect(int client)
{
    // Clients don't actually disconnect on map change. They start sending the new cmdnums before _Post fires.
    g_bInMinigun[client] = false;
    g_bPrevAlive[client] = false;
    g_iPrevButtons[client] = -1;
    g_iPrevCmdNum[client] = -1;
    g_iPrevTickCount[client] = -1;
    g_iCmdNumOffset[client] = 1;
    g_TickStatus[client] = State_Okay;
}

public void OnClientDisconnect_Post(int client)
{
    g_fDetectedTime[client] = 0.0;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, 
                                int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	// Ignore bots
    if (IsFakeClient(client))
    {
        return Plugin_Continue;
    }
    
    // NULL commands
    if (cmdnum <= 0)
    {
        return Plugin_Handled;
    }
    
    // Block old cmds after a client resets their tickcount.
    if (tickcount <= 0)
    {
        g_TickStatus[client] = State_Resetting;
    }
    
    // Fixes issues caused by client timeouts.
    bool bAlive = IsPlayerAlive(client);
    if (!bAlive || !g_bPrevAlive[client] || GetGameTime() <= g_fDetectedTime[client])
    {
        g_bPrevAlive[client] = bAlive;
        g_iPrevButtons[client] = buttons;

        if (g_iPrevCmdNum[client] >= cmdnum)
        {
            if (g_TickStatus[client] == State_Resetting)
            {
                g_TickStatus[client] = State_Reset;
            }
            
            g_iCmdNumOffset[client]++;
        }
        else
        {
            if (g_TickStatus[client] == State_Reset)
            {
                g_TickStatus[client] = State_Okay;
            }

            g_iPrevCmdNum[client] = cmdnum;
            g_iCmdNumOffset[client] = 1;
        }

        g_iPrevTickCount[client] = tickcount;

        return Plugin_Continue;
    }

    // Check for valid cmd values being sent. The command number cannot decrement.
    if (g_iPrevCmdNum[client] > cmdnum)
    {
        if (g_TickStatus[client] != State_Okay)
        {
            g_TickStatus[client] = State_Reset;
            return Plugin_Handled;
        }

        g_fDetectedTime[client] = GetGameTime() + 30.0;

        Handle info = CreateKeyValues("");
        KvSetNum(info, "cmdnum", cmdnum);
        KvSetNum(info, "prevcmdnum", g_iPrevCmdNum[client]);
        KvSetNum(info, "tickcount", tickcount);
        KvSetNum(info, "prevtickcount", g_iPrevTickCount[client]);
        KvSetNum(info, "gametickcount", GetGameTickCount());

        if (SMAC_CheatDetected(client, Detection_UserCmdReuse, info) == Plugin_Continue)
        {
            SMAC_PrintAdminNotice("%t", "SMAC_EyetestDetected", client);

            if (GetConVarBool(g_hCvarBan))
            {
                SMAC_LogAction(client, "was banned for reusing old movement commands. CmdNum: %d PrevCmdNum: %d | [%d:%d:%d]", 
                                    cmdnum, g_iPrevCmdNum[client], g_iPrevTickCount[client], tickcount, GetGameTickCount());
                SMAC_Ban(client, "Eye Test Violation");
            }
            else
            {
                SMAC_LogAction(client, "is suspected of reusing old movement commands. CmdNum: %d PrevCmdNum: %d | [%d:%d:%d]", 
                                    cmdnum, g_iPrevCmdNum[client], g_iPrevTickCount[client], tickcount, GetGameTickCount());
            }
        }

        CloseHandle(info);
        return Plugin_Handled;
    }

    // Other than the incremented tickcount, nothing should have changed.
    if (g_iPrevCmdNum[client] == cmdnum)
    {
        if (g_TickStatus[client] != State_Okay)
        {
            g_TickStatus[client] = State_Reset;
            return Plugin_Handled;
        }

        // The tickcount should be incremented.
        // No longer true in CS:GO (https://forums.alliedmods.net/showthread.php?t=267559)
        if (g_iPrevTickCount[client] != tickcount && g_iPrevTickCount[client]+1 != tickcount && tickcount != GetGameTickCount())
        {
            g_fDetectedTime[client] = GetGameTime() + 30.0;

            Handle info = CreateKeyValues("");
            KvSetNum(info, "cmdnum", cmdnum);
            KvSetNum(info, "tickcount", tickcount);
            KvSetNum(info, "prevtickcount", g_iPrevTickCount[client]);
            KvSetNum(info, "gametickcount", GetGameTickCount());

            if (SMAC_CheatDetected(client, Detection_UserCmdTamperingTickcount, info) == Plugin_Continue)
            {
                SMAC_PrintAdminNotice("%t", "SMAC_EyetestDetected", client);

                if (GetConVarBool(g_hCvarBan))
                {
                    SMAC_LogAction(client, "was banned for tampering with an old movement command (tickcount). CmdNum: %d | [%d:%d:%d]", 
                                        cmdnum, g_iPrevTickCount[client], tickcount, GetGameTickCount());
                    SMAC_Ban(client, "Eye Test Violation");
                }
                else
                {
                    SMAC_LogAction(client, "is suspected of tampering with an old movement command (tickcount). CmdNum: %d | [%d:%d:%d]", 
                                        cmdnum, g_iPrevTickCount[client], tickcount, GetGameTickCount());
                }
            }

            CloseHandle(info);
            return Plugin_Handled;
        }

        // Check for specific buttons in order to avoid compatibility issues with server-side plugins.
        if (!GetConVarBool(g_hCvarCompat) && ((g_iPrevButtons[client] ^ buttons) & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT|IN_SCORE)))
        {
            g_fDetectedTime[client] = GetGameTime() + 30.0;

            Handle info = CreateKeyValues("");
            KvSetNum(info, "cmdnum", cmdnum);
            KvSetNum(info, "prevbuttons", g_iPrevButtons[client]);
            KvSetNum(info, "buttons", buttons);

            if (SMAC_CheatDetected(client, Detection_UserCmdTamperingButtons, info) == Plugin_Continue)
            {
                SMAC_PrintAdminNotice("%t", "SMAC_EyetestDetected", client);

                if (GetConVarBool(g_hCvarBan))
                {
                    SMAC_LogAction(client, "was banned for tampering with an old movement command (buttons). CmdNum: %d | [%d:%d]", cmdnum, g_iPrevButtons[client], buttons);
                    SMAC_Ban(client, "Eye Test Violation");
                }
                else
                {
                    SMAC_LogAction(client, "is suspected of tampering with an old movement command (buttons). CmdNum: %d | [%d:%d]", cmdnum, g_iPrevButtons[client], buttons);
                }
            }

            CloseHandle(info);
            return Plugin_Handled;
        }

        // Track so we can predict the next cmdnum.
        g_iCmdNumOffset[client]++;
    }
    else
    {
        // Passively block cheats from skipping to desired seeds.
        if ((buttons & IN_ATTACK) && g_iPrevCmdNum[client] + g_iCmdNumOffset[client] != cmdnum && g_iPrevCmdNum[client] > 0)
        {
            seed = GetURandomInt();
        }

        g_iCmdNumOffset[client] = 1;
    }

    g_iPrevButtons[client] = buttons;
    g_iPrevCmdNum[client] = cmdnum;
    g_iPrevTickCount[client] = tickcount;

    if (g_TickStatus[client] == State_Reset)
    {
        g_TickStatus[client] = State_Okay;
    }

    // Check for valid eye angles.
    switch (g_EngineGroup)
    {
        case Group_L4D2:
        {
            // In L4D+ engines the client can alternate between ±180 and 0-360.
            if (angles[0] > -135.0 && angles[0] < 135.0 && angles[1] > -270.0 && angles[1] < 420.0)
            {
                g_bInMinigun[client] = false;
                return Plugin_Continue;
            }

            if (g_bInMinigun[client])
            {
                return Plugin_Continue;
            }
        }
        case Group_EP2V:
        {
            // ± normal limit * 1.5 as a buffer zone.
            // TF2 taunts conflict with yaw checks.
            if (angles[0] > -135.0 && angles[0] < 135.0 && (g_EngineVersion == Engine_TF2 || (angles[1] > -270.0 && angles[1] < 270.0)))
            {
                return Plugin_Continue;
            }
        }
        case Group_EP1:
        {
            // Older engine support.
            float vTemp[3];
            vTemp = angles;

            if (vTemp[0] > 180.0)
            {
                vTemp[0] -= 360.0;
            }

            if (vTemp[2] > 180.0)
            {
                vTemp[2] -= 360.0;
            }

            if (vTemp[0] >= -90.0 && vTemp[0] <= 90.0 && vTemp[2] >= -90.0 && vTemp[2] <= 90.0)
            {
                return Plugin_Continue;
            }
        }
        default:
        {
            // Ignore angles for this engine.
            return Plugin_Continue;
        }
    }

    // Game specific checks.
    switch (g_Game)
    {
        case Game_DODS:
        {
            // Ignore prone players.
            if (DODS_IsPlayerProne(client))
            {
                return Plugin_Continue;
            }
        }
        case Game_L4D:
        {
            // Only check survivors in first-person view.
            if (GetClientTeam(client) != 2 || L4D_IsSurvivorBusy(client))
            {
                return Plugin_Continue;
            }
        }
        case Game_L4D2:
        {
            // Only check survivors in first-person view.
            if (GetClientTeam(client) != 2 || L4D2_IsSurvivorBusy(client))
            {
                return Plugin_Continue;
            }
        }
        case Game_ND:
        {
            if (ND_IsPlayerCommander(client))
            {
                return Plugin_Continue;
            }
        }
    }

    // Ignore clients that are interacting with the map.
    int flags = GetEntityFlags(client);

    if (flags & FL_FROZEN || flags & FL_ATCONTROLS)
    {
        return Plugin_Continue;
    }

    // The client failed all checks.
    g_fDetectedTime[client] = GetGameTime() + 30.0;

    // Strict bot checking - https://bugs.alliedmods.net/show_bug.cgi?id=5294
    char sAuthID[MAX_AUTHID_LENGTH];

    Handle info = CreateKeyValues("");
    KvSetVector(info, "angles", angles);

    if (GetClientAuthId(client, AuthId_Steam2, sAuthID, sizeof(sAuthID), false) && !StrEqual(sAuthID, "BOT") 
            && SMAC_CheatDetected(client, Detection_Eyeangles, info) == Plugin_Continue)
    {
        SMAC_PrintAdminNotice("%t", "SMAC_EyetestDetected", client);

        if (GetConVarBool(g_hCvarBan))
        {
            SMAC_LogAction(client, "was banned for cheating with their eye angles. Eye Angles: %.0f %.0f %.0f", angles[0], angles[1], angles[2]);
            SMAC_Ban(client, "Eye Test Violation");
        }
        else
        {
            SMAC_LogAction(client, "is suspected of cheating with their eye angles. Eye Angles: %.0f %.0f %.0f", angles[0], angles[1], angles[2]);
        }
    }

    CloseHandle(info);
    return Plugin_Continue;
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (g_Game != Game_L4D && g_Game != Game_L4D2)
    {
        return;
    }

    if (StrEqual(classname, "prop_minigun") || 
        StrEqual(classname, "prop_minigun_l4d1") || 
        StrEqual(classname, "prop_mounted_machine_gun"))
    {
        SDKHook(entity, SDKHook_Use, Hook_MinigunUse);
    }
}

public Action Hook_MinigunUse(int entity, int activator, int caller, UseType type, float value)
{
    // This will forward Use_Set on each tick, and then Use_Off when released.
    if (IS_CLIENT(activator) && type == Use_Set)
    {
        g_bInMinigun[activator] = true;
    }

    return Plugin_Continue;
}