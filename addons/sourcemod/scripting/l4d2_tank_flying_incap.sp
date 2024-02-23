#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#define L4D2UTIL_STOCKS_ONLY 1
#include <l4d2util>

int iSurvivorIncapHealth = 300;

bool 
    bLateLoad,
    bDebug = false;

ConVar 
    convarDebug,
    convarSurvivorIncapHealth = null;

public Plugin myinfo =
{
    name = "[L4D2] Flying Incap - Tank Punch",
    author = "Sir",
    description = "Sends Survivors flying on the incapping punch.",
    version = "1.0",
    url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int errMax)
{
    bLateLoad = late;
    return APLRes_Success;
}

public void OnPluginStart()
{
    if (bLateLoad) 
    {
        for (int i = 1; i < MaxClients+1; i++) 
        {
            if (IsClientInGame(i)) 
            {
                OnClientPutInServer(i);
            }
        }
    }

    convarDebug = CreateConVar("l4d2_tank_flying_incap_debug", "0", "Are we debugging?");
    convarSurvivorIncapHealth = FindConVar("survivor_incap_health");
    bDebug = convarDebug.BoolValue;
    iSurvivorIncapHealth = convarSurvivorIncapHealth.IntValue;
    convarDebug.AddChangeHook(CvarsChanged);
    convarSurvivorIncapHealth.AddChangeHook(CvarsChanged);
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnClientDisconnect(int client)
{
    SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if (damagetype != DMG_CLUB)
        return Plugin_Continue;

    if (!IsValidSurvivor(victim) || !IsValidTank(attacker))
        return Plugin_Continue;

    if (inflictor <= MaxClients || !IsValidEdict(inflictor))
        return Plugin_Continue;

    char sClassName[ENTITY_MAX_NAME_LENGTH];
    GetEdictClassname(inflictor, sClassName, sizeof(sClassName));
	
    if (strcmp("weapon_tank_claw", sClassName) == 0) 
    {
        if (!IsIncapacitated(victim))
        {
            int iTotalHealth = GetSurvivorPermanentHealth(victim) + GetSurvivorTemporaryHealth(victim);

            if (iTotalHealth <= damage)
            {
                if (bDebug)
                    PrintToChatAll("[FlyingIncap]: %N got hit by Tank and has %i HP on incapping punch", victim, iTotalHealth);

                DataPack dp;
                CreateDataTimer(0.4, Timer_ApplyDamageLater, dp, TIMER_FLAG_NO_MAPCHANGE);
                dp.WriteCell(GetClientUserId(victim));
                dp.WriteCell(GetClientUserId(attacker));
                dp.WriteCell(inflictor);
                dp.WriteCell(iTotalHealth);
                
                SetEntityHealth(victim, 1);
                SetTempHealth(victim, 0.0);
                damage = 0.0;
                return Plugin_Changed;
            }
        }
    }
    return Plugin_Continue;
}

Action Timer_ApplyDamageLater(Handle timer, DataPack dp)
{
    dp.Reset();
    int iSurvivor = GetClientOfUserId(dp.ReadCell());
    int iTank = GetClientOfUserId(dp.ReadCell());
    int iInflictor = dp.ReadCell();
    float damage = float(dp.ReadCell());
    damage = damage >= 1.0 ? damage : 1.0;

    if (iSurvivor > 0)
    {
        iTank = iTank > 0 ? iTank : 0;

        if (bDebug)
            PrintToChatAll("[FlyingIncap]: Applied %0.2f damage to %N", damage, iSurvivor);

        SDKHooks_TakeDamage(iSurvivor, iInflictor, iTank, damage, DMG_CLUB, WEPID_TANK_CLAW);

        if (IsIncapacitated(iSurvivor))
            SetEntityHealth(iSurvivor, iSurvivorIncapHealth);
    }

    return Plugin_Stop;
}

void CvarsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    bDebug = convarDebug.BoolValue;
    iSurvivorIncapHealth = convarSurvivorIncapHealth.IntValue;
}

void SetTempHealth(int client, float fHealth)
{
    SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
    SetEntPropFloat(client, Prop_Send, "m_healthBuffer", fHealth);
}