#include <sourcemod>

#if defined __survs__
#endinput
#endif
#define __survs__

/* Global Vars */
static iSurvivorIndex[MAXPLAYERS + 1];
static iSurvivorCount = 0;


Survivors_RebuildArray_Delay()
{
        CreateTimer(0.3, BuildArray_Timer);
}

public Action:BuildArray_Timer(Handle:timer)
{
        Survivors_RebuildArray();
}

Survivors_RebuildArray()
{
        if (!IsServerProcessing()) return;
        iSurvivorCount = 0;
        
        for (new i = 0; i <= MAXPLAYERS; i++) iSurvivorIndex[i] = 0;

        for (new i = 1; i <= MaxClients; i++)
        {
                if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
                {
                        iSurvivorIndex[iSurvivorCount] = i;
                        iSurvivorCount++;
                }
        }
}

stock GetSurvivorCount() return iSurvivorCount;

stock GetSurvivorOfIndex(index) return iSurvivorIndex[index];