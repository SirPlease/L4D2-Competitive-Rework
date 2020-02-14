/*
//-------------------------------------------------------------------------------------------------------------------
// Version 1: Prevents Survivors from picking up Players in the following situations:
//-------------------------------------------------------------------------------------------------------------------
// - Incapped Player is taking Spit Damage.
// - Players doing the pick-up gets hit by the Tank (Punch or Rock)
//
//-------------------------------------------------------------------------------------------------------------------
// Version 1.1: Prevents Survivors from switching from their current item to another without client requesting so:
//-------------------------------------------------------------------------------------------------------------------
// - Player no longer switches to pills when a teammate passes them pills through "M2".
// - Player picks up a Secondary Weapon while not on their Secondary Weapon. (Dual Pistol will force a switch though)
// - Added CVars for Pick-ups/Switching Item
//
//-------------------------------------------------------------------------------------------------------------------
// Version 1.2: Added Client-side Flags so that players can choose whether or not to make use of the Server's flags.
//-------------------------------------------------------------------------------------------------------------------
// - Welp, there's only one change.. so yeah. Enjoy!
//
//-------------------------------------------------------------------------------------------------------------------
// TODO:
//-------------------------------------------------------------------------------------------------------------------
// - Be a nice guy and less lazy, allow the plugin to work flawlessly with other's peoples needs.. It doesn't require much attention.
// - Find cleaner methods to detect and handle functions.
// - Find a reliable way to detect Dual Pistol pick-up. 
*/

#include <sourcemod>
#include <sdkhooks>
#include <weapons>
#include <colors>

#define FLAGS_SWITCH_MELEE                1
#define FLAGS_SWITCH_PILLS                2

#define FLAGS_INCAP_SPIT                  1
#define FLAGS_INCAP_TANKPUNCH             2
#define FLAGS_INCAP_TANKROCK              4

new bool:bLateLoad;
new bool:bTanked[MAXPLAYERS + 1];
new bool:bCantSwitchHealth[MAXPLAYERS + 1];
new bool:bCantSwitchSecondary[MAXPLAYERS + 1];
new bool:bPreventValveSwitch[MAXPLAYERS +1];
new Handle:hSecondary[MAXPLAYERS + 1];
new Handle:hHealth[MAXPLAYERS + 1];
new Handle:hTanked[MAXPLAYERS + 1];
new Handle:hValveSwitch[MAXPLAYERS + 1];
new Handle:hSwitchFlags;
new Handle:hIncapPickupFlags;
new iSwitchFlags[MAXPLAYERS + 1];
new SwitchFlags;
new IncapFlags;

public Plugin:myinfo = 
{
    name = "L4D2 Pick-up Changes",
    author = "Sir",
    description = "Alters a few things regarding picking up/giving items and incapped Players.",
    version = "1.2",
    url = "Nawl."
}

public APLRes:AskPluginLoad2( Handle:plugin, bool:late, String:error[], errMax)
{
    bLateLoad = late;
    return APLRes_Success;
}

public OnPluginStart()
{
    hSwitchFlags = CreateConVar("pickup_switch_flags", "3", "Flags for Switching from current item (1:Melee Weapons, 2: Passed Pills)");
    hIncapPickupFlags = CreateConVar("pickup_incap_flags", "7", "Flags for Stopping Pick-up progress on Incapped Survivors (1:Spit Damage, 2:TankPunch, 4:TankRock");
    HookConVarChange(hSwitchFlags, CVarChanged);
    HookConVarChange(hIncapPickupFlags, CVarChanged);
    SwitchFlags = GetConVarInt(hSwitchFlags);
    IncapFlags = GetConVarInt(hIncapPickupFlags);
    RegConsoleCmd("sm_secondary", ChangeSecondaryFlags);
    if (bLateLoad) { for (new i = 1; i < MaxClients + 1; i++) { HookValidClient(i, true); } }
}

/* ---------------------------------
//                                 |
//       Standard Client Stuff     |
//                                 |
// -------------------------------*/

public OnClientPutInServer(client)
{
    HookValidClient(client, true);
    if (iSwitchFlags[client] < 2)
    {
        iSwitchFlags[client] = SwitchFlags;
    }
}

public OnClientDisconnect_Post(client)
{
    KillActiveTimers(client);
    HookValidClient(client, false);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if (bTanked[client])
    {
        buttons &= ~IN_USE;
        if (hTanked[client] == INVALID_HANDLE) hTanked[client] = CreateTimer(0.2, DelayUse, client)
    }
    return Plugin_Continue;
}

public Action:ChangeSecondaryFlags(client, args)
{   
    if (IsValidClient(client))
    {
        if (iSwitchFlags[client] != 3) 
        {
            iSwitchFlags[client] = 3;
            CPrintToChat(client, "{blue}[{default}ItemSwitch{blue}] {default}Switch to Melee on pick-up: {blue}OFF");
        }
        else
        {
            iSwitchFlags[client] = 2;
            CPrintToChat(client, "{blue}[{default}ItemSwitch{blue}] {default}Switch to Melee on pick-up: {blue}ON");
        }
    }
    return Plugin_Handled;
}


/* ---------------------------------
//                                 |
//       Yucky Timer Method~       |
//                                 |
// -------------------------------*/

public Action:DelayUse(Handle:timer, any:client)
{
    bTanked[client] = false;
    hTanked[client] = INVALID_HANDLE;
}

public Action:DelaySwitchHealth(Handle:timer, any:client)
{
    bCantSwitchHealth[client] = false;
    hHealth[client] = INVALID_HANDLE;
}

public Action:DelaySwitchSecondary(Handle:timer, any:client)
{
    bCantSwitchSecondary[client] = false;
    hSecondary[client] = INVALID_HANDLE;
}

public Action:DelayValveSwitch(Handle:timer, any:client)
{
    bPreventValveSwitch[client] = false;
    hValveSwitch[client] = INVALID_HANDLE;
}


/* ---------------------------------
//                                 |
//         SDK Hooks, Fun!         |
//                                 |
// -------------------------------*/


public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damageType, &weapon, Float:damageForce[3], Float:damagePosition[3]) 
{
    if (victim <= 0 || victim > MaxClients || !(IsSurvivor(victim)) || !IsValidEdict(inflictor)) return Plugin_Continue;

    // Spitter damaging player that's being picked up.
    // Read the damage input differently, forcing the pick-up to end with every damage tick. (NOTE: Bots still bypass this)
    if ((IncapFlags & FLAGS_INCAP_SPIT) && IsIncapacitated(victim))
    {
        decl String:classname[64];
        GetEdictClassname(inflictor, classname, sizeof(classname));
        if (StrEqual(classname, "insect_swarm"))
        {
            damageType = DMG_GENERIC;
            return Plugin_Changed;
        }
    }

    // Tank Rock or Punch.
    if (IsPlayerTank(attacker))
    {
        if (IsTankRock(inflictor)) { if (IncapFlags & FLAGS_INCAP_TANKROCK) bTanked[victim] = true; }
        else if (IncapFlags & FLAGS_INCAP_TANKPUNCH) bTanked[victim] = true;
    }

    return Plugin_Continue;
}

public Action:WeaponCanSwitchTo(client, weapon)
{
    if (!IsValidEntity(weapon)) return Plugin_Continue;
    
    decl String:sWeapon[64]; 
    GetEntityClassname(weapon, sWeapon, sizeof(sWeapon)); 
    new WeaponId:wep = WeaponNameToId(sWeapon);

    // Health Items.
    if ((iSwitchFlags[client] & FLAGS_SWITCH_PILLS) && (wep == WEPID_PAIN_PILLS || wep == WEPID_ADRENALINE) && bCantSwitchHealth[client]) return Plugin_Stop;

    //Weapons.
    if ((iSwitchFlags[client] & FLAGS_SWITCH_MELEE) && (wep == WEPID_MELEE || wep == WEPID_PISTOL_MAGNUM || wep == WEPID_PISTOL) && bCantSwitchSecondary[client]) return Plugin_Stop;

    return Plugin_Continue;
}

public Action:WeaponEquip(client, weapon)
{
    if (!IsValidEntity(weapon)) return Plugin_Continue;

    // Weapon Currently Using
    decl String:weapon_name[64];
    GetClientWeapon(client, weapon_name, sizeof(weapon_name));
    new WeaponId:wepname = WeaponNameToId(weapon_name);

    // New Weapon
    decl String:sWeapon[64]; 
    GetEntityClassname(weapon, sWeapon, sizeof(sWeapon)); 
    new WeaponId:wep = WeaponNameToId(sWeapon);

    // Health Items.
    if (wep == WEPID_PAIN_PILLS || wep == WEPID_ADRENALINE)
    {
        bCantSwitchHealth[client] = true;
        hHealth[client] = CreateTimer(0.1, DelaySwitchHealth, client)
    }

    // Also Check if Survivor is incapped to make sure no issues occur (Melee players get given a pistol for example)
    else if (!IsIncapacitated(client) && !bPreventValveSwitch[client])
    {
        // New Weapon is a Secondary?
        if (wep == WEPID_MELEE || wep == WEPID_PISTOL_MAGNUM || wep == WEPID_PISTOL)
        {
            // Is Currently used Weapon a Secondary?
            if (wepname == WEPID_MELEE || wepname == WEPID_PISTOL || wepname == WEPID_PISTOL_MAGNUM) return Plugin_Continue;

            bCantSwitchSecondary[client] = true;
            hSecondary[client] = CreateTimer(0.1, DelaySwitchSecondary, client);
        }
    }
    return Plugin_Continue;
}

public Action:WeaponDrop(client, weapon)
{
    if (!IsValidEntity(weapon)) return Plugin_Continue;
    // Weapon Currently Using
    decl String:weapon_name[64];
    GetClientWeapon(client, weapon_name, sizeof(weapon_name));
    new WeaponId:wepname = WeaponNameToId(weapon_name);

    // Secondary Weapon
    new Secondary = GetPlayerWeaponSlot(client, 1);

    // Weapon Dropping
    decl String:sWeapon[64]; 
    GetEntityClassname(weapon, sWeapon, sizeof(sWeapon)); 
    new WeaponId:wep = WeaponNameToId(sWeapon);

    // Check if Player is Alive/Incapped and just dropped his secondary for a different one
    if (!IsIncapacitated(client) && IsPlayerAlive(client)) 
    {
        // Annoying workaround to fix Dual Pistols.
        if (wep == WEPID_PISTOL && GetEntProp(Secondary, Prop_Send, "m_isDualWielding") && wepname != WEPID_MELEE && wepname != WEPID_PISTOL && wepname != WEPID_PISTOL_MAGNUM)
        {
            SetEntProp(Secondary, Prop_Send, "m_isDualWielding", 0);
            SDKHooks_DropWeapon(client, Secondary);
            SetEntProp(Secondary, Prop_Send, "m_isDualWielding", 1);
        }
        else if ((wep == WEPID_MELEE || wep == WEPID_PISTOL || wep == WEPID_PISTOL_MAGNUM) && (wepname == WEPID_MELEE || wepname == WEPID_PISTOL || wepname == WEPID_PISTOL_MAGNUM))
        {
            bPreventValveSwitch[client] = true;
            hValveSwitch[client] = CreateTimer(0.1, DelayValveSwitch, client);
        }
    }
    return Plugin_Continue;
}


/* ---------------------------------
//                                 |
//        Stocks, Functions        |
//                                 |
// -------------------------------*/


bool:IsValidClient(client) 
{ 
    if (client <= 0 || client > MaxClients || !IsClientConnected(client)) return false; 
    return IsClientInGame(client); 
} 

bool:IsSurvivor(client)
{
    return IsValidClient(client) && GetClientTeam(client) == 2;
}

bool:IsIncapacitated(client) 
{
    new bool:bIsIncapped = false;
    if ( IsSurvivor(client) ) {
        if (GetEntProp(client, Prop_Send, "m_isIncapacitated") > 0) bIsIncapped = true;
        if (!IsPlayerAlive(client)) bIsIncapped = true;
    }
    return bIsIncapped;
}

bool:IsPlayerTank(client)
{
    return (IsValidClient(client) && GetEntProp(client, Prop_Send, "m_zombieClass") == 8);
}

bool:IsTankRock(entity)
{
    if (entity > 0 && IsValidEntity(entity) && IsValidEdict(entity))
    {
        decl String:classname[64];
        GetEdictClassname(entity, classname, sizeof(classname));
        return StrEqual(classname, "tank_rock");
    }
    return false;
}

KillActiveTimers(client)
{
    if (hTanked[client] != INVALID_HANDLE) KillTimer(hTanked[client]);
    if (hHealth[client] != INVALID_HANDLE) KillTimer(hHealth[client]);
    if (hSecondary[client] != INVALID_HANDLE) KillTimer(hSecondary[client]);
    if (hValveSwitch[client] != INVALID_HANDLE) KillTimer(hValveSwitch[client]);

    hTanked[client] = INVALID_HANDLE;
    hHealth[client] = INVALID_HANDLE;
    hSecondary[client] = INVALID_HANDLE;
    hValveSwitch[client] = INVALID_HANDLE;
    bCantSwitchHealth[client] = false;
    bCantSwitchSecondary[client] = false;
    bPreventValveSwitch[client] = false;
    bTanked[client] = false;
    iSwitchFlags[client] = -1;
}

HookValidClient(client, bool:Hook)
{
    if (IsValidClient(client))
    {
        if (Hook)
        {
            SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
            SDKHook(client, SDKHook_WeaponCanSwitchTo, WeaponCanSwitchTo);
            SDKHook(client, SDKHook_WeaponEquip, WeaponEquip);
            SDKHook(client, SDKHook_WeaponDrop, WeaponDrop);
        }
        else
        {
            SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
            SDKUnhook(client, SDKHook_WeaponCanSwitchTo, WeaponCanSwitchTo);
            SDKUnhook(client, SDKHook_WeaponEquip, WeaponEquip);
            SDKUnhook(client, SDKHook_WeaponDrop, WeaponDrop);            
        }
    }
}


/* ---------------------------------
//                                 |
//          Cvar Changes!          |
//                                 |
// -------------------------------*/


public CVarChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
    IncapFlags = GetConVarInt(hIncapPickupFlags);
    SwitchFlags = GetConVarInt(hSwitchFlags);
}