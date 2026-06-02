#if defined _infected_control_si_cap_included
    #endinput
#endif
#define _infected_control_si_cap_included

// 按当前在场特感和 CVar 上限刷新剩余额度。
void ResetMatchState()
{
    gST.totalSI = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsInfectedBot(i) && IsPlayerAlive(i))
        {
            gST.teleCount[i] = 0;
            int zc = GetEntProp(i, Prop_Send, "m_zombieClass");
            if (zc >= 1 && zc <= SI_COUNT)
            {
                gST.siAlive[zc - 1]++;
                gST.totalSI++;
            }
        }
        if (IsValidSurvivor(i) && !IsPlayerAlive(i))
            L4D_RespawnPlayer(i);
    }

    ResetDeathState();
}

static void ApplyForcedClassMode()
{
    int forced = 0;
    if (gCV.AllHunter.BoolValue)  forced = view_as<int>(SI_Hunter);
    if (gCV.AllCharger.BoolValue) forced = view_as<int>(SI_Charger);
    if (forced == 0) return;

    for (int i = 0; i < SI_COUNT; i++) gST.siCap[i] = 0;
    int idx = forced - 1;
    int want = gCV.iSiLimit - gST.siAlive[idx];
    if (want < 0) want = 0;
    gST.siCap[idx] = want;
}

void RecalcSiCapFromAlive(bool log = false)
{
    for (int i = 0; i < SI_COUNT; i++) gST.siAlive[i] = 0;
    gST.totalSI = 0;

    for (int c = 1; c <= MaxClients; c++)
    {
        if (IsInfectedBot(c) && IsPlayerAlive(c))
        {
            int zc = GetEntProp(c, Prop_Send, "m_zombieClass");
            if (1 <= zc && zc <= SI_COUNT)
            {
                gST.siAlive[zc - 1]++;
                gST.totalSI++;
            }
        }
    }

    int baseCap[SI_COUNT];
    baseCap[0] = gCV.ZSmokerLimit.IntValue;
    baseCap[1] = gCV.ZBoomerLimit.IntValue;
    baseCap[2] = gCV.ZHunterLimit.IntValue;
    baseCap[3] = gCV.ZSpitterLimit.IntValue;
    baseCap[4] = gCV.ZJockeyLimit.IntValue;
    baseCap[5] = gCV.ZChargerLimit.IntValue;

    for (int i = 0; i < SI_COUNT; i++)
    {
        int remain = baseCap[i] - gST.siAlive[i];
        if (remain < 0) remain = 0;
        gST.siCap[i] = remain;
    }

    ApplyForcedClassMode();

    if (log) Debug_Print("[CAP] remain S=%d B=%d H=%d P=%d J=%d C=%d | alive S=%d B=%d H=%d P=%d J=%d C=%d | total=%d",
        gST.siCap[0], gST.siCap[1], gST.siCap[2], gST.siCap[3], gST.siCap[4], gST.siCap[5],
        gST.siAlive[0], gST.siAlive[1], gST.siAlive[2], gST.siAlive[3], gST.siAlive[4], gST.siAlive[5],
        gST.totalSI);
}

void ReadSiCap()
{
    gST.siCap[0] = gCV.ZSmokerLimit.IntValue;
    gST.siCap[1] = gCV.ZBoomerLimit.IntValue;
    gST.siCap[2] = gCV.ZHunterLimit.IntValue;
    gST.siCap[3] = gCV.ZSpitterLimit.IntValue;
    gST.siCap[4] = gCV.ZJockeyLimit.IntValue;
    gST.siCap[5] = gCV.ZChargerLimit.IntValue;

    ApplyForcedClassMode();

    Debug_Print("[CAP] caps S=%d B=%d H=%d P=%d J=%d C=%d",
        gST.siCap[0], gST.siCap[1], gST.siCap[2], gST.siCap[3], gST.siCap[4], gST.siCap[5]);
}
