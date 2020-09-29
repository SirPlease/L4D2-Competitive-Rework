#include <sourcemod>

#if defined __tanks__
#endinput
#endif
#define __tanks__

/* Global Vars */
new Handle:hFwdFirstTankSpawn;
new Handle:hFwdTankPassControl;
new Handle:hFwdTankDeath;
new Handle:hTankDeathTimer;

static bool:bIsTankActive;
static iTankClient = -1;
static iTankPassCount = 0;

ResetStatus()
{
        bIsTankActive = false;
        iTankClient = -1;
        iTankPassCount = 0;
        
        if (hTankDeathTimer != INVALID_HANDLE)
        {
                KillTimer(hTankDeathTimer);
                hTankDeathTimer = INVALID_HANDLE;
        }
}

Tanks_OnMapStart()
{
        ResetStatus();
}

Tanks_RoundStart()
{
        ResetStatus();
}

Tanks_TankSpawn(Handle:event)
{
        if (bIsTankActive) return;
        bIsTankActive = true;
        
        iTankClient = GetClientOfUserId(GetEventInt(event, "userid"));
        
        Call_StartForward(hFwdFirstTankSpawn);
        Call_PushCell(iTankClient);
        Call_Finish();
}

Tanks_ItemPickup(Handle:event)
{
        if (!bIsTankActive) return;
        
        decl String:item[64];
        GetEventString(event, "item", item, sizeof(item));
        
        if (StrEqual(item, "tank_claw"))
        {
                new iPrevTank = iTankClient;
                iTankClient = GetClientOfUserId(GetEventInt(event, "userid"));
                if (hTankDeathTimer != INVALID_HANDLE)
                {
                        KillTimer(hTankDeathTimer);
                        hTankDeathTimer = INVALID_HANDLE;
                }
                Call_StartForward(hFwdTankPassControl);
                Call_PushCell(iPrevTank);
                Call_PushCell(iTankClient);
                Call_PushCell(iTankPassCount);
                Call_Finish();
                iTankPassCount++;
        }
}

Tanks_PlayerDeath(Handle:event)
{
        if (!bIsTankActive) return;
        new client = GetClientOfUserId(GetEventInt(event, "userid"));
        if (client != iTankClient) return;
        hTankDeathTimer = CreateTimer(0.5, TankDeath_Timer);
}

public Action:TankDeath_Timer(Handle:timer)
{
        Call_StartForward(hFwdTankDeath);
        Call_PushCell(iTankClient);
        Call_Finish();
        ResetStatus();
}