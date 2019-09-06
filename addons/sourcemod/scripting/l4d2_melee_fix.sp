#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>

Handle hCvarDmg;
float fCvarDmg;
bool bLateLoad;

public Plugin myinfo = 
{
    name = "Fix Melee Weapons",
    author = "Sir",
    description = "Fix those darn Melee Weapons not applying correct damage values and allows for a way to manipulate damage on Chargers.",
    version = "1.1",
    url = "https://github.com/SirPlease/SirCoding"
}

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int errMax)
{
    bLateLoad = late;
    return APLRes_Success;
}

public void OnPluginStart()
{
    hCvarDmg = CreateConVar("melee_damage_charger", "0.0", "Damage dealt to Chargers per swing, 0.0 to leave in default behaviour");
    fCvarDmg = GetConVarFloat(hCvarDmg);
    HookConVarChange(hCvarDmg, cvarChanged);

    if (bLateLoad)
    {
        for (int i = 1; i < MaxClients + 1; i++) 
        {
            if (IsValidClient(i)) SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
        }
    }
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if (IsSurvivor(attacker) && IsSi(victim) && GetEntProp(victim, Prop_Send, "m_zombieClass") <= 6 && damage != 0.0)
    {
        char sWeapon[32];
        GetEdictClassname(inflictor, sWeapon, sizeof(sWeapon));
    
        if(StrEqual(sWeapon, "weapon_melee"))
        {
            int class = GetEntProp(victim, Prop_Send, "m_zombieClass");

             // Testing showed that only the L4D1 SI: Hunter, Smoker and Boomer have issues with correct Melee Damage values being applied, check for Spitter and Jockey anyway!
            if (class <= 5)
            { 
                damage = float(GetClientHealth(victim));
                return Plugin_Changed;
            }

            // Are we modifying Melee vs Charger behaviour?
            if (fCvarDmg != 0.0)
            {
                // Take care of low health Chargers to prevent Overkill damage.
                if (float(GetClientHealth(victim)) < fCvarDmg) damage = float(GetClientHealth(victim));

                // Deal requested Damage to Chargers.
                else damage = fCvarDmg;

                return Plugin_Changed;
            }
        }
    }
    return Plugin_Continue;
}

stock bool IsValidClient(int client) 
{ 
    if (client <= 0 || client > MaxClients || !IsClientConnected(client)) return false; 
    return IsClientInGame(client); 
} 

stock bool IsSurvivor(int client) 
{
    return IsValidClient(client) && GetClientTeam(client) == 2;
}

stock bool IsSi(int client) 
{
    return IsValidClient(client) && GetClientTeam(client) == 3;
}

public void cvarChanged(Handle cvar, char[] oldValue, char[] newValue)
{
    fCvarDmg = GetConVarFloat(hCvarDmg);
}