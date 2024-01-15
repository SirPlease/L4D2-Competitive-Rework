#include <sourcemod>
#include <left4dhooks>
#include <colors>
#undef REQUIRE_PLUGIN
#include <l4d2_boss_percents>

ConVar convarRageFlowPercent;
ConVar convarRageFreezeTime;
ConVar convarDebug;
ConVar g_hVsBossBuffer;

Handle hTankTimer;

bool 
    bHaveHadFlowOrStaticTank, 
    libraryBossPercentAvailable = false;

int iTank = -1;
int tankSpawnedSurvivorFlow = 0;

public Plugin myinfo =
{
    name = "L4D2 Tank Rage",
    author = "Sir",
    description = "Manage Tank Rage when Survivors are running back.",
    version = "1.0",
    url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
    g_hVsBossBuffer = FindConVar("versus_boss_buffer");
    convarRageFlowPercent = CreateConVar("l4d2_tankrage_flowpercent", "7", "The percentage in flow the survival have to run back to grant frustration freeze (Furthest Survivor)");
    convarRageFreezeTime  = CreateConVar("l4d2_tankrage_freezetime", "4.0", "Time in seconds to freeze the Tank's frustration when survivors have ran back per <flowpercent>.");
    convarDebug = CreateConVar("l4d2_tankrage_debug", "0", "Are we debugging?");
    HookEvent("tank_spawn", Event_TankSpawn);
    HookEvent("round_start", Event_ResetTank, EventHookMode_PostNoCopy);
    HookEvent("player_death", Event_ResetTank, EventHookMode_Post);
}

public void OnAllPluginsLoaded()
{
    libraryBossPercentAvailable = LibraryExists("l4d_boss_percent");
}

public void OnLibraryRemoved(const char[] name)
{
    if (strcmp(name, "l4d_boss_percent") == 0) libraryBossPercentAvailable = false;
}

public void OnLibraryAdded(const char[] name)
{
    if (strcmp(name, "l4d_boss_percent") == 0) libraryBossPercentAvailable = true;
}

public void L4D_OnFirstSurvivorLeftSafeArea_Post()
{
    if (libraryBossPercentAvailable)
        tankSpawnedSurvivorFlow = GetStoredTankPercent();
    else
        tankSpawnedSurvivorFlow = L4D2Direct_GetVSTankFlowPercent(InSecondHalfOfRound()) ? RoundToNearest(L4D2Direct_GetVSTankFlowPercent(InSecondHalfOfRound()) * 100.0) : 0;
}

public void Event_TankSpawn(Event hEvent, char[] sEventName, bool dontBroadcast)
{
    iTank = GetClientOfUserId(hEvent.GetInt("userid"));

    if (convarDebug.BoolValue) 
        PrintToChatAll("[%s]: %N is Tank", sEventName, iTank);

    if (bHaveHadFlowOrStaticTank)
        return;

    /*
        This is needed for maps that do not have a flow tank.
        We will however be checking if the map is the last map in the campaign as we don't want to mess with finale tanks
        tankSpawnedSuvivorFlow will always be 0 for static tanks, so we need to rely on another method in this check.
    */
    if (tankSpawnedSurvivorFlow == 0)
    {
        if (L4D_IsMissionFinalMap())
            return;

        tankSpawnedSurvivorFlow = min(RoundToNearest(((L4D2_GetFurthestSurvivorFlow() + g_hVsBossBuffer.FloatValue) / L4D2Direct_GetMapMaxFlowDistance()) * 100.0), 100);
    }

    if (!IsFakeClient(iTank))
    {
        CPrintToChatAll("{red}[{default}Tank Rage{red}] {default}For every {olive}%i{green}%% {default}Survivors run back, the Tank will have their frustration frozen for {olive}%0.1f {green}seconds{default}.", convarRageFlowPercent.IntValue, convarRageFreezeTime.FloatValue);
        hTankTimer = CreateTimer(0.1, timerTank, _, TIMER_REPEAT)
        bHaveHadFlowOrStaticTank = true;
    }
}

public void Event_ResetTank(Event hEvent, char[] sEventName, bool dontBroadcast)
{
    if (strcmp(sEventName, "player_death") == 0)
    {
        char sVictimName[32];
        hEvent.GetString("victimname", sVictimName, sizeof(sVictimName), "None");

        if (strcmp(sVictimName, "Tank") != 0)
            return;
    }
    else
    {
        bHaveHadFlowOrStaticTank = false;
        tankSpawnedSurvivorFlow = 0;
        iTank = -1;

        if (convarDebug.BoolValue) 
            PrintToChatAll("[%s]: Everything is reset!", sEventName);
    }
    
    delete hTankTimer;
}

public Action timerTank(Handle timer)
{
    if (IsClientInGame(iTank) && !IsFakeClient(iTank))
    {
        int current = GetBossProximity();

        if (current == 0) 
          return Plugin_Continue;

        int diff = tankSpawnedSurvivorFlow - current;
        int flowPercent = convarRageFlowPercent.IntValue;

        if (diff >= flowPercent)
        {
            float fTimeToAdd = 0.0;

            for (int i = diff; i >= flowPercent; i -= flowPercent)
            {
                tankSpawnedSurvivorFlow -= flowPercent;
                fTimeToAdd += convarRageFreezeTime.FloatValue;
            }

            int tankFrustration = 100 - L4D_GetTankFrustration(iTank);
            float fTankGrace = CTimer_GetRemainingTime(GetFrustrationTimer(iTank));

            if (fTankGrace < 0.0) fTankGrace = 0.0;

            if (convarDebug.BoolValue)
            {
                PrintToChatAll("\x04[\x03%N\x04]\x01: Flow Difference since last check: %i", iTank, diff);
                PrintToChatAll("\x04[\x03%N\x04]\x01: Frus: \x03%i \x01- Grace: \x03%f\x04s", iTank, tankFrustration, fTankGrace);
                PrintToChatAll("\x04[\x03%N\x04]\x01: Set Grace To: \x03%f\x04s", iTank, fTankGrace + fTimeToAdd);
            }

            fTankGrace += fTimeToAdd;
            CTimer_Start(GetFrustrationTimer(iTank), fTankGrace);
        }
    }
    
    return Plugin_Continue;
}

int GetBossProximity()
{
    float fSurvivorCompletion = GetMaxSurvivorCompletion();

    if (fSurvivorCompletion == 0.0) 
        return 0;

    float proximity = fSurvivorCompletion + g_hVsBossBuffer.FloatValue / L4D2Direct_GetMapMaxFlowDistance();

    return RoundToNearest(((proximity > 1.0) ? 1.0 : proximity) * 100.0);
}

float GetMaxSurvivorCompletion()
{
    float flow = 0.0, tmp_flow = 0.0, origin[3];
    Address pNavArea;
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i)) {
            GetClientAbsOrigin(i, origin);
            pNavArea = L4D2Direct_GetTerrorNavArea(origin);
            if (pNavArea != Address_Null) {
                tmp_flow = L4D2Direct_GetTerrorNavAreaFlow(pNavArea);
                flow = (flow > tmp_flow) ? flow : tmp_flow;
            }
            else return 0.0;
        }
    }

    return (flow / L4D2Direct_GetMapMaxFlowDistance());
}

CountdownTimer GetFrustrationTimer(int client)
{
    static int s_iOffs_m_frustrationTimer = -1;
    if (s_iOffs_m_frustrationTimer == -1)
        s_iOffs_m_frustrationTimer = FindSendPropInfo("CTerrorPlayer", "m_frustration") + 4;
    
    return view_as<CountdownTimer>(GetEntityAddress(client) + view_as<Address>(s_iOffs_m_frustrationTimer));
}

InSecondHalfOfRound()
{
    return GameRules_GetProp("m_bInSecondHalfOfRound");
}

int min(int a, int b) 
{
    return a < b ? a : b;
}
