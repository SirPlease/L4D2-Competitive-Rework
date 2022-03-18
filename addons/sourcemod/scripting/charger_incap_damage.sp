#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>

#define TEAM_SURVIVOR           2 
#define TEAM_INFECTED           3
#define ZC_CHARGER              6
#define CHARGER_DMG_POUND       15.0

bool bLateLoad;
ConVar hDmgIncappedPound;

public Plugin myinfo = 
{
    name = "Incapped Charger Damage",
    author = "Sir",
    description = "Modify Charger pummel damage done to Survivors",
    version = "1.0",
    url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
}

/* -------------------------------
 *      Init
 * ------------------------------- */

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int errMax)
{
    bLateLoad = late;
    return APLRes_Success;
}

public void OnPluginStart()
{
    // hook already existing clients if loading late
    if (bLateLoad) {
        for (int i = 1; i < MaxClients+1; i++) {
            if (IsClientInGame(i)) {
                SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
            }
        }
    }
    hDmgIncappedPound = CreateConVar("charger_dmg_incapped", "15.0", "Pound Damage dealt to incapped Survivors.");
}


/* -------------------------------
 *      General hooks / events
 * ------------------------------- */

public void OnClientPostAdminCheck(int client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

/* --------------------------------------
 *     GOT MY EYES ON YOU, DAMAGE
 * -------------------------------------- */

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
    if (!inflictor || !attacker || !victim || !IsValidEdict(victim) || !IsValidEdict(inflictor)) { return Plugin_Continue; }

    // only check player-to-player damage
    if (!IsClientAndInGame(attacker) || !IsClientAndInGame(victim)) { return Plugin_Continue; }

    // check teams
    if (GetClientTeam(attacker) != TEAM_INFECTED || GetClientTeam(victim) != TEAM_SURVIVOR) { return Plugin_Continue; }

    // only allow chargers
    if (GetEntProp(attacker, Prop_Send, "m_zombieClass") != ZC_CHARGER) { return Plugin_Continue; }

    if (damage == CHARGER_DMG_POUND && (damageForce[0] == 0.0 && damageForce[1] == 0.0 && damageForce[2] == 0.0))
    {
        // POUND
        damage = IsIncapped(victim) ? GetConVarFloat(hDmgIncappedPound) : damage;
        return Plugin_Changed;
    }
    return Plugin_Continue;
}
    
/* --------------------------------------
 *     Shared function(s)
 * -------------------------------------- */

bool IsClientAndInGame(int index)
{
    return (index > 0 && index <= MaxClients && IsClientInGame(index));
}

bool IsIncapped(int client)
{
    return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated"));
}