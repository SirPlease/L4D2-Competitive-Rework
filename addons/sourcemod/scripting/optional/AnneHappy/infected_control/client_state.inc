#if defined _infected_control_client_state_included
    #endinput
#endif
#define _infected_control_client_state_included

bool IsInfectedBot(int client)
{
    return client > 0 && client <= MaxClients && IsClientInGame(client) && IsFakeClient(client)
           && GetClientTeam(client) == TEAM_INFECTED && (GetEntProp(client, Prop_Send, "m_zombieClass") >= 1 && GetEntProp(client, Prop_Send, "m_zombieClass") <= 6);
}

stock bool IsSmokerReadyToAttack(int client)
{
    if (!IsAiSmoker(client))
        return false;

    static int ability;
    ability = GetEntPropEnt(client, Prop_Send, "m_customAbility");
    if (!IsValidEdict(ability))
        return false;

    static char clsName[32];
    GetEntityClassname(ability, clsName, sizeof(clsName));
    if (strcmp(clsName, "ability_tongue", false) != 0)
        return false;

    static float timestamp;
    timestamp = GetEntPropFloat(ability, Prop_Send, "m_timestamp");
    return GetGameTime() >= timestamp;
}

bool IsValidClient(int c)
{
    return c > 0 && c <= MaxClients && IsClientInGame(c);
}

bool IsValidSurvivor(int c)
{
    return IsValidClient(c) && GetClientTeam(c) == TEAM_SURVIVOR;
}

bool IsSpitter(int client)
{
    return IsInfectedBot(client) && IsPlayerAlive(client) && GetEntProp(client, Prop_Send, "m_zombieClass") == view_as<int>(SI_Spitter);
}

int GetInfectedClass(int client)
{
    return GetEntProp(client, Prop_Send, "m_zombieClass");
}

bool IsGhost(int client)
{
    return IsValidClient(client) && view_as<bool>(GetEntProp(client, Prop_Send, "m_isGhost"));
}

bool IsAiSmoker(int c)
{
    return c && c <= MaxClients && IsClientInGame(c) && IsPlayerAlive(c) && IsFakeClient(c)
        && GetClientTeam(c) == TEAM_INFECTED && GetEntProp(c, Prop_Send, "m_zombieClass") == view_as<int>(SI_Smoker) && !IsGhost(c);
}

bool IsAiTank(int c)
{
    return c && c <= MaxClients && IsClientInGame(c) && IsPlayerAlive(c) && IsFakeClient(c)
        && GetClientTeam(c) == TEAM_INFECTED && GetEntProp(c, Prop_Send, "m_zombieClass") == ZC_TANK && !IsGhost(c);
}

bool IsPinned(int client)
{
    if (!(IsValidSurvivor(client) && IsPlayerAlive(client))) return false;
    return GetEntPropEnt(client, Prop_Send, "m_tongueOwner")    > 0
        || GetEntPropEnt(client, Prop_Send, "m_carryAttacker")  > 0
        || GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0
        || GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0
        || GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") > 0;
}

bool IsPinningSomeone(int client)
{
    if (!IsInfectedBot(client)) return false;
    return GetEntPropEnt(client, Prop_Send, "m_tongueVictim")  > 0
        || GetEntPropEnt(client, Prop_Send, "m_jockeyVictim")  > 0
        || GetEntPropEnt(client, Prop_Send, "m_pounceVictim")  > 0
        || GetEntPropEnt(client, Prop_Send, "m_pummelVictim")  > 0
        || GetEntPropEnt(client, Prop_Send, "m_carryVictim")   > 0;
}

float GetClosestSurvivorDistance(int client)
{
    float p[3];
    GetClientAbsOrigin(client, p);

    float best = 999999.0;
    float s[3];
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsValidSurvivor(i) || !IsPlayerAlive(i)) continue;
        GetClientAbsOrigin(i, s);
        float d = GetVectorDistance(p, s);
        if (d < best) best = d;
    }
    return best;
}

bool CanBeTeleport(int client)
{
    if (!IsInfectedBot(client) || !IsClientInGame(client) || !IsPlayerAlive(client))
        return false;
    if (GetEntProp(client, Prop_Send, "m_zombieClass") == ZC_TANK)
        return false;
    if (IsPinningSomeone(client))
        return false;

    if (gCV.fTeleportSpawnGrace > 0.0)
    {
        float born = g_LastSpawnTime[client];
        if (born > 0.0 && (GetGameTime() - born) < gCV.fTeleportSpawnGrace)
            return false;
    }

    if (IsSpitter(client) && (GetGameTime() - gST.spitterSpitTime[client]) < SPIT_INTERVAL)
        return false;

    if (GetClosestSurvivorDistance(client) < gCV.fSpawnMin)
        return false;

    if (IsAiSmoker(client) && g_bSmokerLib && !IsSmokerReadyToAttack(client))
        return false;

    float p[3];
    GetClientAbsOrigin(client, p);
    if (IsPosAheadOfHighest(p))
        return false;

    return true;
}

bool Survivors_AllPinnedOrDown()
{
    int ns = 0;
    int pinned = 0;

    for (int c = 1; c <= MaxClients; c++)
    {
        if (IsValidSurvivor(c) && IsPlayerAlive(c))
        {
            ns++;
            if (IsPinned(c) || L4D_IsPlayerIncapacitated(c))
                pinned++;
        }
    }

    return (ns > 0 && pinned == ns);
}

bool IsAnyTankOrAboveHalfSurvivorDownOrDied(int limit = 0)
{
    int down = 0;
    int survMax = (gCV.SurvivorLimit != null) ? gCV.SurvivorLimit.IntValue : 4;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsAiTank(i)) return true;
        if (IsValidSurvivor(i) && (L4D_IsPlayerIncapacitated(i) || !IsPlayerAlive(i))) down++;
    }
    if (limit == 0)
        return down >= RoundToCeil(float(survMax) / 2.0);
    else
        return down >= limit;
}

void EmitRushmanForward(int survivor)
{
    if (g_hRushManNotifyForward != INVALID_HANDLE)
    {
        Call_StartForward(g_hRushManNotifyForward);
        Call_PushCell(survivor);
        Call_Finish();
    }
}
