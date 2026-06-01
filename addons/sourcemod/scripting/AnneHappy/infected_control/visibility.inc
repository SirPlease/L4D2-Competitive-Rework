#if defined _infected_control_visibility_included
    #endinput
#endif
#define _infected_control_visibility_included

bool RayClear(const float src[3], const float dst[3], int mask)
{
    Handle tr = TR_TraceRayFilterEx(src, dst, mask, RayType_EndPoint, TraceFilter);
    bool ok = (!TR_DidHit(tr) || TR_GetFraction(tr) >= 0.99);
    delete tr;
    return ok;
}

bool IsPosVisibleSDK(float pos[3], bool teleportMode)
{
    float head[3];
    head[0] = pos[0]; head[1] = pos[1]; head[2] = pos[2] + 62.0;

    float chest[3];
    chest[0] = pos[0]; chest[1] = pos[1]; chest[2] = pos[2] + 32.0;

    const int visMask = (MASK_VISIBLE & MASK_SHOT);
    const float SIDE = 16.0;

    int effMode = gCV.iVisRayMode;
    if (effMode == 2)
        effMode = (CountAliveSurvivors() > 4) ? 0 : 1;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || GetClientTeam(i) != TEAM_SURVIVOR || !IsPlayerAlive(i))
            continue;
        if (teleportMode && L4D_IsPlayerIncapacitated(i) && gCV.bIgnoreIncapSight)
            continue;

        float eyes[3];
        GetClientEyePosition(i, eyes);

        if (effMode != 1 && RayClear(eyes, head, visMask))
            return true;

        if (effMode == 1)
        {
            float ang[3], fwd[3], right[3], up[3];
            GetClientEyeAngles(i, ang);
            GetAngleVectors(ang, fwd, right, up);

            float eyesL[3];
            eyesL[0] = eyes[0] - right[0] * SIDE;
            eyesL[1] = eyes[1] - right[1] * SIDE;
            eyesL[2] = eyes[2] - right[2] * SIDE;

            float eyesR[3];
            eyesR[0] = eyes[0] + right[0] * SIDE;
            eyesR[1] = eyes[1] + right[1] * SIDE;
            eyesR[2] = eyes[2] + right[2] * SIDE;

            if (RayClear(eyesL, head, visMask) || RayClear(eyesR, head, visMask))
                return true;
        }

        if (L4D2_IsVisibleToPlayer(i, TEAM_SURVIVOR, TEAM_INFECTED, 0, chest))
            return true;
    }

    return false;
}

stock bool TraceFilter_Stuck(int entity, int contentsMask)
{
    if (entity <= MaxClients || !IsValidEntity(entity))
        return false;

    static char sClassName[20];
    GetEntityClassname(entity, sClassName, sizeof(sClassName));
    if (strcmp(sClassName, "env_physics_blocker") == 0 && !EnvBlockType(entity))
        return false;

    return true;
}

stock bool EnvBlockType(int entity)
{
    int BlockType = GetEntProp(entity, Prop_Data, "m_nBlockType");
    return !(BlockType == 1 || BlockType == 2);
}

bool WillStuck(const float at[3])
{
    static const float mins[3] = { -16.0, -16.0, 0.0 };
    static const float maxs[3] = {  16.0,  16.0, 71.0 };
    Handle tr = TR_TraceHullFilterEx(at, at, mins, maxs, MASK_PLAYERSOLID, TraceFilter_Stuck);
    bool hit = TR_DidHit(tr);
    delete tr;
    return hit;
}

stock bool TraceFilter(int entity, int contentsMask)
{
    if (entity <= MaxClients || !IsValidEntity(entity))
        return false;

    static char sClassName[9];
    GetEntityClassname(entity, sClassName, sizeof(sClassName));
    if (strcmp(sClassName, "infected") == 0 || strcmp(sClassName, "witch") == 0)
        return false;

    return true;
}
