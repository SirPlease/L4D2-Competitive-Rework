#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <l4d2_saferoom_detect>

/**
 * Saferoom Medkit Dynamic
 * -----------------------
 * - Removes all medkit spawns and entities inside both the start and end saferooms.
 * - When survivors leave the start saferoom, give one medkit to each alive survivor.
 */

#define PLUGIN_NAME        "Saferoom Medkit Dynamic"
#define PLUGIN_AUTHOR      "morzlee, edited for AnneHappy"
#define PLUGIN_VERSION     "2.0.0"

#define SLOT_HEAVY_HEALTH  3

public Plugin myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = "Remove saferoom medkits and hand them out on exit based on survivor count.",
    version     = PLUGIN_VERSION,
    url         = ""
};

// ======================
// Configurable ConVars
// ======================
ConVar gC_Enable;       // sr_medkit_enable
ConVar gC_RemoveDelay;  // sr_medkit_scan_delay
ConVar gC_Debug;        // sr_medkit_debug

bool  g_bEnable;
float g_fRemoveDelay;
bool  g_bDebug;
bool  g_bKitsGiven;

// ======================
// Utils
// ======================
stock void Dbg(const char[] fmt, any ...)
{
    if (!g_bDebug) return;
    char buffer[256];
    VFormat(buffer, sizeof(buffer), fmt, 2);
    PrintToServer("[SRMedkitKV] %s", buffer);
}

bool IsValidClientSurvivor(int client)
{
    return (1 <= client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}

void KillEntitySafe(int ent)
{
    if (!IsValidEntity(ent) || ent <= MaxClients)
        return;

#if SOURCEMOD_V_MINOR >= 9
    RemoveEntity(ent);
#else
    AcceptEntityInput(ent, "Kill");
#endif
}

// ======================
// Lifecycle & Events
// ======================
public void OnPluginStart()
{
    gC_Enable      = CreateConVar("sr_medkit_enable", "1", "Enable saferoom medkit control (1=on, 0=off).", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    gC_RemoveDelay = CreateConVar("sr_medkit_scan_delay", "1.5", "Delay after round_start before stripping saferoom medkits.", FCVAR_NOTIFY, true, 0.0, true, 10.0);
    gC_Debug       = CreateConVar("sr_medkit_debug", "0", "Debug logging.", FCVAR_NONE, true, 0.0, true, 1.0);

    AutoExecConfig(true, "sr_medkit_refill_kv");

    HookEvent("round_start", Evt_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("player_left_start_area", Evt_PlayerLeftStartArea, EventHookMode_PostNoCopy);

    HookConVarChange(gC_Enable,      CvarChanged);
    HookConVarChange(gC_RemoveDelay, CvarChanged);
    HookConVarChange(gC_Debug,       CvarChanged);

    RegAdminCmd("sm_srmedkit_apply", Cmd_ApplyNow, ADMFLAG_GENERIC, "Remove saferoom medkits now and distribute by survivor count.");

    ReadCvars();
}

void ReadCvars()
{
    g_bEnable      = gC_Enable.BoolValue;
    g_fRemoveDelay = gC_RemoveDelay.FloatValue;
    g_bDebug       = gC_Debug.BoolValue;
}

public void CvarChanged(ConVar cvar, const char[] oldValue, const char[] newValue)
{
    ReadCvars();
}

public void Evt_RoundStart(Event e, const char[] name, bool dontBroadcast)
{
    g_bKitsGiven = false;

    if (!g_bEnable)
        return;

    CreateTimer(g_fRemoveDelay, Timer_RemoveSaferoomMedkits, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void Evt_PlayerLeftStartArea(Event e, const char[] name, bool dontBroadcast)
{
    if (!g_bEnable || g_bKitsGiven)
        return;

    int client = GetClientOfUserId(e.GetInt("userid"));
    if (!IsValidClientSurvivor(client))
        return;

    GiveMedkitsBasedOnPlayers();
}

public Action Cmd_ApplyNow(int client, int args)
{
    RemoveSaferoomMedkits();
    GiveMedkitsBasedOnPlayers();

    ReplyToCommand(client, "[SRMedkitKV] removed saferoom medkits and distributed kits.");
    return Plugin_Handled;
}

// ======================
// Core
// ======================
public Action Timer_RemoveSaferoomMedkits(Handle timer)
{
    if (!g_bEnable)
        return Plugin_Stop;

    int removed = RemoveSaferoomMedkits();
    Dbg("removed %d medkits inside saferooms", removed);
    return Plugin_Stop;
}

int RemoveSaferoomMedkits()
{
    int total = 0;
    total += RemoveMedkitsByClass("weapon_first_aid_kit_spawn");
    total += RemoveMedkitsByClass("weapon_first_aid_kit");
    return total;
}

int RemoveMedkitsByClass(const char[] classname)
{
    int count = 0;
    int ent = -1;
    while ((ent = FindEntityByClassname(ent, classname)) != -1)
    {
        if (!IsValidEntity(ent))
            continue;

        if (IsEntityInAnySaferoom(ent))
        {
            KillEntitySafe(ent);
            count++;
        }
    }
    return count;
}

bool IsEntityInAnySaferoom(int ent)
{
    return (SAFEDETECT_IsEntityInStartSaferoom(ent) || SAFEDETECT_IsEntityInEndSaferoom(ent));
}

void GiveMedkitsBasedOnPlayers()
{
    g_bKitsGiven = true;

    int survivors = 0;
    int given = 0;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsValidClientSurvivor(i) || !IsPlayerAlive(i))
            continue;

        survivors++;
        given += GiveMedkitToClient(i);
    }

    Dbg("distributed medkits: survivors=%d, kits_given=%d", survivors, given);
}

int GiveMedkitToClient(int client)
{
    int slot = GetPlayerWeaponSlot(client, SLOT_HEAVY_HEALTH);
    if (slot != -1 && IsValidEntity(slot))
    {
        RemovePlayerItem(client, slot);
        KillEntitySafe(slot);
    }

    int kit = CreateEntityByName("weapon_first_aid_kit");
    if (kit == -1)
        return 0;

    DispatchSpawn(kit);
    EquipPlayerWeapon(client, kit);
    return 1;
}
