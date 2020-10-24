#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>
#include <sdkhooks>
#include <sdktools>

ConVar hDropMethod;
int iDropMethod;

public Plugin myinfo =
{
    name = "Shove Shenanigans - REVAMPED",
    author = "Sir",
    description = "Stops Shoves slowing the Tank and Charger, gives control over what happens when a Survivor is punched while having a melee out.",
    version = "1.3",
    url = ""
}

public void OnPluginStart()
{
    HookEvent("player_hurt", PlayerHit);
    hDropMethod = CreateConVar("l4d2_melee_drop_method", "2", "What to do when a Tank punches a Survivor that's holding out a melee weapon? 0: Nothing. 1: Drop Melee Weapon. 2: Force Switch to Primary Weapon.");
    iDropMethod = GetConVarInt(hDropMethod);
    hDropMethod.AddChangeHook(ConVarChange);
}

public Action PlayerHit(Handle event, char[] event_name, bool dontBroadcast)
{
    int Player = GetClientOfUserId(GetEventInt(event, "userid"));
    char Weapon[256];  
    GetEventString(event, "weapon", Weapon, sizeof(Weapon));
    if (IsSurvivor(Player) && StrEqual(Weapon, "tank_claw"))
    {
        int activeweapon = GetEntPropEnt(Player, Prop_Send, "m_hActiveWeapon");
        if (IsValidEdict(activeweapon))
        {
            char weaponname[64];
            GetEdictClassname(activeweapon, weaponname, sizeof(weaponname));    
            
            if (StrEqual(weaponname, "weapon_melee", false) && 
            GetPlayerWeaponSlot(Player, 0) != -1) // Must have a Primary Weapon.
            {
                switch(iDropMethod)
                {
                    case 0: return Plugin_Continue; // Don't care.
                    case 1: SDKHooks_DropWeapon(Player, activeweapon); // Drop Melee, will most likely fly away as Tank's punch will cause it to launch far away, can test some stuff with the Vector or perhaps a delayed timer.
                    case 2: // Force a weapon switch
                    {
                        // Note: If a player's primary weapon is empty, it will still switch to the primary weapon, but then instantly switch back to the melee weapon.
                        int PrimaryWeapon = GetPlayerWeaponSlot(Player, 0);
                        SetEntPropEnt(Player, Prop_Send, "m_hActiveWeapon", PrimaryWeapon); 
                        SetEntPropFloat(PrimaryWeapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 0.1); // Prevent players instantly firing their Primary Weapon when they're holding down M1 with their melee.
                    }
                }
            }
        }
    }
    return Plugin_Continue;
}

public Action L4D_OnShovedBySurvivor(int shover, int shovee, const float vector[3])
{
    if (!IsSurvivor(shover) || !IsInfected(shovee)) return Plugin_Continue;
    if (IsTankOrCharger(shovee)) return Plugin_Handled;
    return Plugin_Continue;
}
 
public Action L4D2_OnEntityShoved(int shover, int shovee_ent, int weapon, float vector[3], bool bIsHunterDeadstop)
{
    if (!IsSurvivor(shover) || !IsInfected(shovee_ent)) return Plugin_Continue;
    if (IsTankOrCharger(shovee_ent)) return Plugin_Handled;
    return Plugin_Continue;
}

stock bool IsValidClient(int client)
{
    return client > 0 && client <= MaxClients && IsClientInGame(client);
}

stock bool IsSurvivor(int client)
{
    return IsValidClient(client) && GetClientTeam(client) == 2;
}
 
stock bool IsInfected(int client)
{
    return IsValidClient(client) && GetClientTeam(client) == 3;
}
 
stock bool IsTankOrCharger(int client)  
{
    if (!IsPlayerAlive(client))
        return false;
 
    if (GetEntProp(client, Prop_Send, "m_zombieClass") == 8)
        return true;
 
    if (GetEntProp(client, Prop_Send, "m_zombieClass") == 6)
        return true;
 
    return false;
}

public void ConVarChange(ConVar convar, char[] oldValue, char[] newValue)
{
    iDropMethod = StringToInt(newValue);
}