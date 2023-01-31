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
#include <smac>
#include <smac_cvars>
#undef REQUIRE_PLUGIN
#include <basecomm>

/* Plugin Info */
public Plugin myinfo =
{
    name =          "SMAC ConVar Checker",
    author =        SMAC_AUTHOR,
    description =   "Checks for players using exploitative cvars",
    version =       SMAC_VERSION,
    url =           SMAC_URL
};

/* Globals */
#define CVAR_REPLICATION_DELAY 30

#define TIME_REQUERY_FIRST 20.0
#define TIME_REQUERY_SUBSEQUENT 10.0

#define MAX_REQUERY_ATTEMPTS 4

// cvar data
Handle g_hCvarTrie = INVALID_HANDLE;
Handle g_hCvarADT = INVALID_HANDLE;
int g_iADTSize;

// client data
Handle g_hTimer[MAXPLAYERS+1];
int g_iRequeryCount[MAXPLAYERS+1];

int g_iADTIndex[MAXPLAYERS+1] = {-1, ...};
Handle g_hCurDataTrie[MAXPLAYERS+1];

// plugin state
bool g_bLateLoad;
bool g_bPluginStarted;

/* Plugin Functions */
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    g_bLateLoad = late;
    return APLRes_Success;
}

public void OnPluginStart()
{
    LoadTranslations("smac.phrases");
    
    g_hCvarTrie = CreateTrie();
    g_hCvarADT = CreateArray();
    
    // Check for plugins first.
    AddCvar(Order_First, "0penscript",                  Comp_NonExist, Action_Ban);
    AddCvar(Order_First, "aim_bot",                     Comp_NonExist, Action_Ban);
    AddCvar(Order_First, "aim_fov",                     Comp_NonExist, Action_Ban);
    AddCvar(Order_First, "bat_version",                 Comp_NonExist, Action_Kick);
    AddCvar(Order_First, "beetlesmod_version",          Comp_NonExist, Action_Kick);
    AddCvar(Order_First, "est_version",                 Comp_NonExist, Action_Kick);
    AddCvar(Order_First, "eventscripts_ver",            Comp_NonExist, Action_Kick);
    AddCvar(Order_First, "fm_attackmode",               Comp_NonExist, Action_Ban);
    AddCvar(Order_First, "lua-engine",                  Comp_NonExist, Action_Ban);
    AddCvar(Order_First, "lua_open",                    Comp_NonExist, Action_Ban);
    AddCvar(Order_First, "mani_admin_plugin_version",   Comp_NonExist, Action_Kick);
    AddCvar(Order_First, "maniadminhacker",             Comp_NonExist, Action_Ban);
    AddCvar(Order_First, "maniadmintakeover",           Comp_NonExist, Action_Ban);
    AddCvar(Order_First, "metamod_version",             Comp_NonExist, Action_Kick);
    AddCvar(Order_First, "openscript",                  Comp_NonExist, Action_Ban);
    AddCvar(Order_First, "openscript_version",          Comp_NonExist, Action_Ban);
    AddCvar(Order_First, "runnscript",                  Comp_NonExist, Action_Ban);
    AddCvar(Order_First, "smadmintakeover",             Comp_NonExist, Action_Ban);
    AddCvar(Order_First, "sourcemod_version",           Comp_NonExist, Action_Kick);
    AddCvar(Order_First, "tb_enabled",                  Comp_NonExist, Action_Ban);
    AddCvar(Order_First, "zb_version",                  Comp_NonExist, Action_Kick);

    // Check for everything else last.
    AddCvar(Order_Last, "cl_clock_correction",          Comp_Equal, Action_Ban, "1.0");
    AddCvar(Order_Last, "cl_leveloverview",             Comp_Equal, Action_Ban, "0.0");
    AddCvar(Order_Last, "cl_overdraw_test",             Comp_Equal, Action_Ban, "0.0");
    AddCvar(Order_Last, "cl_phys_timescale",            Comp_Equal, Action_Ban, "1.0");
    AddCvar(Order_Last, "cl_showevents",                Comp_Equal, Action_Ban, "0.0");

    // Insurgency does not mark this as a cheat.
    if (SMAC_GetGameType() == Game_INS)
    {
        AddCvar(Order_Last, "fog_enable",               Comp_Equal, Action_Kick, "1.0");
    }
    else
    {
        AddCvar(Order_Last, "fog_enable",               Comp_Equal, Action_Ban, "1.0");
    }

    AddCvar(Order_Last, "host_timescale",               Comp_Replicated, Action_Ban);
    AddCvar(Order_Last, "mat_dxlevel",                  Comp_Greater, Action_Kick, "80.0");
    AddCvar(Order_Last, "mat_fillrate",                 Comp_Equal, Action_Ban, "0.0");
    AddCvar(Order_Last, "mat_measurefillrate",          Comp_Equal, Action_Ban, "0.0");
    AddCvar(Order_Last, "mat_proxy",                    Comp_Equal, Action_Ban, "0.0");
    AddCvar(Order_Last, "mat_showlowresimage",          Comp_Equal, Action_Ban, "0.0");
    AddCvar(Order_Last, "mat_wireframe",                Comp_Equal, Action_Ban, "0.0");
    AddCvar(Order_Last, "mem_force_flush",              Comp_Equal, Action_Ban, "0.0");
    AddCvar(Order_Last, "mp_fadetoblack",               Comp_Replicated, Action_Ban);
    AddCvar(Order_Last, "r_aspectratio",                Comp_Equal, Action_Ban, "0.0");
    AddCvar(Order_Last, "r_colorstaticprops",           Comp_Equal, Action_Ban, "0.0");
    AddCvar(Order_Last, "r_dispwalkable",               Comp_Equal, Action_Ban, "0.0");
    AddCvar(Order_Last, "r_drawbeams",                  Comp_Equal, Action_Ban, "1.0");
    AddCvar(Order_Last, "r_drawbrushmodels",            Comp_Equal, Action_Ban, "1.0");
    AddCvar(Order_Last, "r_drawclipbrushes",            Comp_Equal, Action_Ban, "0.0");
    AddCvar(Order_Last, "r_drawdecals",                 Comp_Equal, Action_Ban, "1.0");
    AddCvar(Order_Last, "r_drawentities",               Comp_Equal, Action_Ban, "1.0");
    AddCvar(Order_Last, "r_drawmodelstatsoverlay",      Comp_Equal, Action_Ban, "0.0");
    AddCvar(Order_Last, "r_drawopaqueworld",            Comp_Equal, Action_Ban, "1.0");
    AddCvar(Order_Last, "r_drawothermodels",            Comp_Equal, Action_Ban, "1.0");
    AddCvar(Order_Last, "r_drawparticles",              Comp_Equal, Action_Ban, "1.0");
    AddCvar(Order_Last, "r_drawrenderboxes",            Comp_Equal, Action_Ban, "0.0");
    AddCvar(Order_Last, "r_drawskybox",                 Comp_Equal, Action_Ban, "1.0");
    AddCvar(Order_Last, "r_drawtranslucentworld",       Comp_Equal, Action_Ban, "1.0");
    AddCvar(Order_Last, "r_shadowwireframe",            Comp_Equal, Action_Ban, "0.0");
    AddCvar(Order_Last, "r_skybox",                     Comp_Equal, Action_Ban, "1.0");
    AddCvar(Order_Last, "r_visocclusion",               Comp_Equal, Action_Ban, "0.0");
    AddCvar(Order_Last, "snd_show",                     Comp_Equal, Action_Ban, "0.0");
    AddCvar(Order_Last, "snd_visualize",                Comp_Equal, Action_Ban, "0.0");
    AddCvar(Order_Last, "sv_allowminmodels",            Comp_Replicated, Action_Ban);
    AddCvar(Order_Last, "sv_cheats",                    Comp_Replicated, Action_Ban);
    AddCvar(Order_Last, "sv_competitive_minspec",       Comp_Replicated, Action_Ban);
    AddCvar(Order_Last, "sv_consistency",               Comp_Replicated, Action_Ban);
    AddCvar(Order_Last, "sv_footsteps",                 Comp_Replicated, Action_Ban);
    AddCvar(Order_Last, "vcollide_wireframe",           Comp_Equal, Action_Ban, "0.0");
    
    // Commands.
    RegAdminCmd("smac_addcvar", Command_AddCvar, ADMFLAG_ROOT, "Add cvar to checking.");
    RegAdminCmd("smac_removecvar", Command_RemCvar, ADMFLAG_ROOT, "Remove cvar from checking.");
    
    // scramble ordering.
    if (g_iADTSize)
    {
        ScrambleCvars();
    }
    
    // Start on all clients.
    if (g_bLateLoad)
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && IsClientAuthorized(i))
            {
                OnClientPostAdminCheck(i);
            }
        }
    }
    
    g_bPluginStarted = true;
}

public void OnClientPostAdminCheck(int client)
{
    if (!IsFakeClient(client))
    {
        SetTimer(g_hTimer[client], CreateTimer(0.1, Timer_QueryNextCvar, client, TIMER_REPEAT));
    }
}

public void OnClientDisconnect(int client)
{
    if (!IsFakeClient(client))
    {
        g_hCurDataTrie[client] = INVALID_HANDLE;
        g_iADTIndex[client] = -1;
        g_iRequeryCount[client] = 0;
        SetTimer(g_hTimer[client], INVALID_HANDLE);
    }
}

public Action Command_AddCvar(int client,int args)
{
    if (args >= 3 && args <= 5)
    {
        char sCvar[MAX_CVAR_NAME_LEN];
        GetCmdArg(1, sCvar, sizeof(sCvar));

        if (!IsValidConVarName(sCvar))
        {
            ReplyToCommand(client, "\"%s\" is not a valid convar.", sCvar);
            return Plugin_Handled;
        }

        char sCompType[16], sAction[16];

        GetCmdArg(2, sCompType, sizeof(sCompType));
        GetCmdArg(3, sAction, sizeof(sAction));

        char sValue[MAX_CVAR_VALUE_LEN], sValue2[MAX_CVAR_VALUE_LEN];

        if (args >= 4)
        {
            GetCmdArg(4, sValue, sizeof(sValue));
        }
        
        if (args >= 5)
        {
            GetCmdArg(5, sValue2, sizeof(sValue2));
        }

        if (AddCvar(Order_Last, sCvar, GetCompTypeInt(sCompType), GetCActionInt(sAction), sValue, sValue2))
        {
            ReplyToCommand(client, "%s successfully added.", sCvar);
            return Plugin_Handled;
        }
    }

    ReplyToCommand(client, "Usage: smac_addcvar <cvar> <comptype> <action> <value> <value2>");
    return Plugin_Handled;
}

bool AddCvar(CvarOrder COrder, char[] sCvar, CvarComp CCompType, CvarAction CAction, const char[] sValue = "", const char[] sValue2 = "")
{
    if (CCompType == Comp_Invalid || CAction == Action_Invalid)
    {
        return false;
    }
    
    // Trie is case sensitive.
    StringToLower(sCvar);

    char sNewValue[MAX_CVAR_VALUE_LEN];
    ConVar hCvar;

    if (CCompType == Comp_Replicated)
    {
        hCvar = FindConVar(sCvar);

        if (hCvar == INVALID_HANDLE || !(GetConVarFlags(hCvar) & FCVAR_REPLICATED))
        {
            return false;
        }
        
        GetConVarString(hCvar, sNewValue, sizeof(sNewValue));
    }
    else
    {
        strcopy(sNewValue, sizeof(sNewValue), sValue);
    }

    Handle hDataTrie;

    if (GetTrieValue(g_hCvarTrie, sCvar, hDataTrie))
    {
        //SetTrieValue(hDataTrie, Cvar_Order, COrder);
        SetTrieString(hDataTrie, Cvar_Name, sCvar);
        SetTrieValue(hDataTrie, Cvar_CompType, CCompType);
        SetTrieValue(hDataTrie, Cvar_Action, CAction);
        SetTrieString(hDataTrie, Cvar_Value, sNewValue);
        SetTrieString(hDataTrie, Cvar_Value2, sValue2);
        //SetTrieValue(hDataTrie, Cvar_ReplicatedTime, 0);
    }
    else
    {
        // Setup cvar data
        hDataTrie = CreateTrie();

        SetTrieValue(hDataTrie, Cvar_Order, COrder);
        SetTrieString(hDataTrie, Cvar_Name, sCvar);
        SetTrieValue(hDataTrie, Cvar_CompType, CCompType);
        SetTrieValue(hDataTrie, Cvar_Action, CAction);
        SetTrieString(hDataTrie, Cvar_Value, sNewValue);
        SetTrieString(hDataTrie, Cvar_Value2, sValue2);
        SetTrieValue(hDataTrie, Cvar_ReplicatedTime, 0);

        // Add cvar to lists
        SetTrieValue(g_hCvarTrie, sCvar, hDataTrie);
        PushArrayCell(g_hCvarADT, hDataTrie);
        g_iADTSize = GetArraySize(g_hCvarADT);

        // Begin replication
        if (CCompType == Comp_Replicated)
        {
            HookConVarChange(hCvar, OnConVarChanged);
            ReplicateToAll(hCvar, sNewValue);
        }

        // Scramble
        if (g_bPluginStarted)
        {
            ScrambleCvars();
        }
    }

    return true;
}

public Action Command_RemCvar(int client,int args)
{
    if (args == 1)
    {
        char sCvar[MAX_CVAR_NAME_LEN];
        GetCmdArg(1, sCvar, sizeof(sCvar));

        if (RemCvar(sCvar))
        {
            ReplyToCommand(client, "%s successfully removed.", sCvar);
        }
        else
        {
            ReplyToCommand(client, "%s was not found.", sCvar);
        }
        
        return Plugin_Handled;
    }

    ReplyToCommand(client, "Usage: smac_removecvar <cvar>");
    return Plugin_Handled;
}

bool RemCvar(char[] sCvar)
{
    Handle hDataTrie;
    
    // Trie is case sensitive.
    StringToLower(sCvar);
    
    // Are you listed?
    if (!GetTrieValue(g_hCvarTrie, sCvar, hDataTrie))
    {
        return false;
    }

    // Invalidate active queries.
    for (int i = 1; i <= MaxClients; i++)
    {
        if (g_hCurDataTrie[i] == hDataTrie)
        {
            g_hCurDataTrie[i] = INVALID_HANDLE;
        }
    }

    // Disable replication
    CvarComp SCCompType;
    GetTrieValue(hDataTrie, Cvar_CompType, SCCompType);

    if (SCCompType == Comp_Replicated)
    {
        UnhookConVarChange(FindConVar(sCvar), OnConVarChanged);
    }

    // Remove relevant entries
    RemoveFromTrie(g_hCvarTrie, sCvar);
    RemoveFromArray(g_hCvarADT, FindValueInArray(g_hCvarADT, hDataTrie));
    g_iADTSize = GetArraySize(g_hCvarADT);
    CloseHandle(hDataTrie);

    return true;
}

public Action Timer_QueryNextCvar(Handle timer, any client)
{
    // No cvars in the list
    if (!g_iADTSize)
    {
        return Plugin_Continue;
    }

    // Get next cvar
    if (++g_iADTIndex[client] >= g_iADTSize)
    {
        g_iADTIndex[client] = 0;
    }

    Handle hDataTrie = GetArrayCell(g_hCvarADT, g_iADTIndex[client]);

    if (IsReplicating(hDataTrie))
    {
        return Plugin_Continue;
    }

    // Attempt to query it
    char sCvar[MAX_CVAR_NAME_LEN];
    GetTrieString(hDataTrie, Cvar_Name, sCvar, sizeof(sCvar));

    if (QueryClientConVar(client, sCvar, OnConVarQueryFinished, GetClientSerial(client)) == QUERYCOOKIE_FAILED)
    {
        return Plugin_Continue;
    }

    // Success!
    g_hCurDataTrie[client] = hDataTrie;
    g_hTimer[client] = CreateTimer(TIME_REQUERY_FIRST, Timer_RequeryCvar, client);
    return Plugin_Stop;
}

public Action Timer_RequeryCvar(Handle timer, any client)
{
    // Have we had enough?
    if (++g_iRequeryCount[client] > MAX_REQUERY_ATTEMPTS)
    {
        g_hTimer[client] = INVALID_HANDLE;
        KickClient(client, "%t", "SMAC_FailedToReply");
        return Plugin_Stop;
    }

    // Did the query get invalidated?
    if (g_hCurDataTrie[client] != INVALID_HANDLE && !IsReplicating(g_hCurDataTrie[client]))
    {
        char sCvar[MAX_CVAR_NAME_LEN];
        GetTrieString(g_hCurDataTrie[client], Cvar_Name, sCvar, sizeof(sCvar));

        if (QueryClientConVar(client, sCvar, OnConVarQueryFinished, GetClientSerial(client)) != QUERYCOOKIE_FAILED)
        {
            g_hTimer[client] = CreateTimer(TIME_REQUERY_SUBSEQUENT, Timer_RequeryCvar, client);
            return Plugin_Stop;
        }
    }
    
    g_hTimer[client] = CreateTimer(0.1, Timer_QueryNextCvar, client, TIMER_REPEAT);
    return Plugin_Stop;
}

public void OnConVarQueryFinished(QueryCookie cookie,int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, any serial)
{
    if (GetClientFromSerial(serial) != client)
    {
        return;
    }
    
    // Trie is case sensitive.
    char sCvar[MAX_CVAR_NAME_LEN];
    Handle hDataTrie;

    strcopy(sCvar, sizeof(sCvar), cvarName);
    StringToLower(sCvar);

    // Did we expect this query?
    if (!GetTrieValue(g_hCvarTrie, sCvar, hDataTrie) || hDataTrie != g_hCurDataTrie[client])
    {
        return;
    }

    // Prepare the next query.
    g_hCurDataTrie[client] = INVALID_HANDLE;
    g_iRequeryCount[client] = 0;
    SetTimer(g_hTimer[client], CreateTimer(0.1, Timer_QueryNextCvar, client, TIMER_REPEAT));

    // Initialize data
    CvarComp SCCompType; 
    char sValue[MAX_CVAR_VALUE_LEN], sValue2[MAX_CVAR_VALUE_LEN], sKickMessage[255];
    GetTrieValue(hDataTrie, Cvar_CompType, SCCompType);
    GetTrieString(hDataTrie, Cvar_Value, sValue, sizeof(sValue));
    GetTrieString(hDataTrie, Cvar_Value2, sValue2, sizeof(sValue2));

    // Check query results
    if (result == ConVarQuery_Okay)
    {
        if (IsReplicating(hDataTrie))
        {
            return;
        }

        switch (SCCompType)
        {
            case Comp_Equal:
            {
                if (StringToFloat(cvarValue) == StringToFloat(sValue))
                {
                    return;
                }

                FormatEx(sKickMessage, sizeof(sKickMessage), "%T", "SMAC_ShouldEqual", client, sCvar, sValue, cvarValue);
            }
            case Comp_StrEqual, Comp_Replicated:
            {
                if (StrEqual(cvarValue, sValue))
                {
                    return;
                }

                FormatEx(sKickMessage, sizeof(sKickMessage), "%T", "SMAC_ShouldEqual", client, sCvar, sValue, cvarValue);
            }
            case Comp_Greater:
            {
                if (StringToFloat(cvarValue) >= StringToFloat(sValue))
                {
                    return;
                }

                FormatEx(sKickMessage, sizeof(sKickMessage), "%T", "SMAC_ShouldBeGreater", client, sCvar, sValue, cvarValue);
            }
            case Comp_Less:
            {
                if (StringToFloat(cvarValue) <= StringToFloat(sValue))
                {
                    return;
                }

                FormatEx(sKickMessage, sizeof(sKickMessage), "%T", "SMAC_ShouldBeLess", client, sCvar, sValue, cvarValue);
            }
            case Comp_Between:
            {
                if (StringToFloat(cvarValue) >= StringToFloat(sValue) && StringToFloat(cvarValue) <= StringToFloat(sValue2))
                {
                    return;
                }
                
                FormatEx(sKickMessage, sizeof(sKickMessage), "%T", "SMAC_ShouldBeBetween", client, sCvar, sValue, sValue2, cvarValue);
            }
            case Comp_Outside:
            {
                if (StringToFloat(cvarValue) < StringToFloat(sValue) || StringToFloat(cvarValue) > StringToFloat(sValue2))
                {
                    return;
                }
                
                FormatEx(sKickMessage, sizeof(sKickMessage), "%T", "SMAC_ShouldBeOutside", client, sCvar, sValue, sValue2, cvarValue);
            }
            default:
            {
                FormatEx(sKickMessage, sizeof(sKickMessage), "ConVar %s violation", sCvar);
            }
        }
    }
    else if (SCCompType == Comp_NonExist)
    {
        if (result == ConVarQuery_NotFound)
        {
            return;
        }

        FormatEx(sKickMessage, sizeof(sKickMessage), "ConVar %s violation", sCvar);
    }

    // The client failed relevant checks.
    CvarAction CAction;
    GetTrieValue(hDataTrie, Cvar_Action, CAction);

    Handle info = CreateKeyValues("");

    KvSetString(info, "cvar", sCvar);
    KvSetNum(info, "comptype", view_as<int>(SCCompType));
    KvSetNum(info, "actiontype", view_as<int>(CAction));
    KvSetString(info, "cvarvalue", cvarValue);
    KvSetString(info, "value", sValue);
    KvSetString(info, "value2", sValue2);
    KvSetNum(info, "result", view_as<int>(result));

    if (SMAC_CheatDetected(client, Detection_CvarViolation, info) == Plugin_Continue)
    {
        SMAC_PrintAdminNotice("%t", "SMAC_CvarViolation", client, sCvar);

        char sResult[16], sCompType[16];
        GetQueryResultString(result, sResult, sizeof(sResult));
        GetCompTypeString(SCCompType, sCompType, sizeof(sCompType));

        switch (CAction)
        {
            case Action_Mute:
            {
                if (!BaseComm_IsClientMuted(client))
                {
                    PrintToChatAll("%t%t", "SMAC_Tag", "SMAC_Muted", client);
                    BaseComm_SetClientMute(client, true);
                }
            }
            case Action_Kick:
            {
                SMAC_LogAction(client, "was kicked for failing checks on convar \"%s\". result \"%s\" | CompType: \"%s\" | cvarValue \"%s\" | value: \"%s\" | value2: \"%s\"", 
                                    sCvar, sResult, sCompType, cvarValue, sValue, sValue2);
                KickClient(client, "\n%s", sKickMessage);
            }
            case Action_Ban:
            {
                SMAC_LogAction(client, "was banned for failing checks on convar \"%s\". result \"%s\" | CompType: \"%s\" | cvarValue \"%s\" | value: \"%s\" | value2: \"%s\"", 
                                    sCvar, sResult, sCompType, cvarValue, sValue, sValue2);
                SMAC_Ban(client, "ConVar %s violation", sCvar);
            }
        }
    }

    CloseHandle(info);
}

public void OnConVarChanged(ConVar convar, char[] oldValue, char[] newValue)
{
    char sCvar[MAX_CVAR_NAME_LEN];
    Handle hDataTrie;

    convar.GetName(sCvar, sizeof(sCvar));
    StringToLower(sCvar);

    if (!GetTrieValue(g_hCvarTrie, sCvar, hDataTrie))
    {
        return;
    }

    SetTrieString(hDataTrie, Cvar_Value, newValue);
    SetTrieValue(hDataTrie, Cvar_ReplicatedTime, GetTime() + CVAR_REPLICATION_DELAY);

    // sv_cheats, if enabled, will false positive on client-side cheat commands.
    if (StrEqual(sCvar, "sv_cheats") && StringToInt(newValue) != 0)
    {
        SetConVarInt(convar, 0, true, true);
        return;
    }

    ReplicateToAll(convar, newValue);
}

void ScrambleCvars()
{
    Handle[][] hCvarADTs = new Handle[view_as<int>(Order_MAX)][g_iADTSize];
    Handle hDataTrie;
    int iOrder, iADTIndex[view_as<int>(CvarOrder)];

    for (int i = 0; i < g_iADTSize; i++)
    {
        hDataTrie = GetArrayCell(g_hCvarADT, i);
        GetTrieValue(hDataTrie, Cvar_Order, iOrder);

        hCvarADTs[iOrder][iADTIndex[iOrder]++] = hDataTrie;
    }

    ClearArray(g_hCvarADT);

    for (int i = 0; i < view_as<int>(CvarOrder); i++)
    {
        if (iADTIndex[i] > 0)
        {
            SortIntegers(view_as<int>(hCvarADTs[i]), iADTIndex[i], Sort_Random);

            for (int j = 0; j < iADTIndex[i]; j++)
            {
                PushArrayCell(g_hCvarADT, hCvarADTs[i][j]);
            }
        }
    }
}

bool IsReplicating(Handle hDataTrie)
{
    int iReplicatedTime;
    GetTrieValue(hDataTrie, Cvar_ReplicatedTime, iReplicatedTime);

    return (iReplicatedTime > GetTime());
}