/*
 * @Author:             派蒙
 * @Last Modified by:   我是派蒙啊
 * @Create Date:        2022-01-14 11:54:43
 * @Last Modified time: 2023-05-26 15:45:54
 * @Github:             http://github.com/PaimonQwQ
 */

/* #################################################################### *
                                L4D2 Tools
                            Author: 我是派蒙啊
                           Version: 2023.05.26
 * #################################################################### */

#if defined _l4d2tools_included
    #endinput
#endif
#define _l4d2tools_included

#define TEAM_SPECTATOR 1
#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

enum
{
    Team_Spectator = 1,
    Team_Survivor,
    Team_Infected
};

enum
{
    ZC_Smoker = 1,
    ZC_Boomer,
    ZC_Hunter,
    ZC_Spitter,
    ZC_Jockey,
    ZC_Charger,
    ZC_Witch,
    ZC_Tank
};

enum
{
    PC_UpperCut = 40,
    PC_RightHook = 43,
    PC_LeftHook = 45,
    PC_PoundGround1 = 46,
    PC_PoundGround2 = 47,
    TH_UnderCut = 48,
    TH_OverHand = 49,
    TH_FromHip = 50,
    TH_OverHead = 51
};

enum
{
    CMDBOT_ATTACK = 0,     // Force the bot to attack a specific target, even bypassing CTerrorPlayer::SetSenseFlags (DirectorScript.BOT_CANT_SEE).
    CMDBOT_MOVE = 1,       // Force the bot to move to a specific location, which then they will do it unconditionally without performing any other AI behaviours controlled by themselves.
                            // This means that Survivor Bots and most player-controllable Special Infected won't attack anything when commanded, but Common Infected still automatically attack enemies if they close in enough.
    CMDBOT_RETREAT = 2,    // Force the bot to retreat from a target entity. Only works when used on Survivor Bots, and if target is a Tank.
    CMDBOT_RESET = 3       // Removes the active bot command and lets the AI resume controlling the bot.
};


/**
 * @brief Returns true if client is correct.
 *
 * @param client    Client index.
 * @return          True if client is correct. False otherwise.
 */
stock bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client));
}

/**
 * @brief Returns true if client is a survivor.
 * 
 * @param client    Client index.
 * @return          True if client is a survivor. False otherwise.
 */
stock bool IsSurvivor(int client)
{
    return (IsValidClient(client) && GetClientTeam(client) == view_as<int>(Team_Survivor));
}

/**
 * @brief Returns true if client is a SI(Special Infected).
 * 
 * @param client    Client index.
 * @return          True if client is a SI. False otherwise.
 */
stock bool IsInfected(int client)
{
    return (IsValidClient(client) && GetClientTeam(client) == view_as<int>(Team_Infected));
}

/**
 * @brief Returns true if client is a spectator.
 * 
 * @param client    Client index.
 * @return          True if client is a spectator. False otherwise.
 */
stock bool IsSpectator(int client)
{
    return (IsValidClient(client) && GetClientTeam(client) == view_as<int>(Team_Spectator));
}

/**
 * @brief Returns true if client is in ghost mode.
 * 
 * @param client    Client index.
 * @return          True if client is in ghost mode. False otherwise.
 */
stock bool IsGhost(int client)
{
    return (IsValidClient(client) && view_as<bool>(GetEntProp(client, Prop_Send, "m_isGhost")));
}

/**
 * @brief Returns true if client is a tank.
 * 
 * @param client    Client index.
 * @return          True if client is a tank. False otherwise.
 */
stock bool IsTank(int client)
{
    return (IsValidClient(client) && GetEntProp(client, Prop_Send, "m_zombieClass") == view_as<int>(ZC_Tank));
}

/**
 * @brief Returns true if client is being pinned.
 * 
 * @param client    Client index.
 * @return          True if client is being pinned. False otherwise.
 */
stock bool IsSurvivorPinned(int client)
{
    return (IsSurvivor(client) &&
            (GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0      || //smoker grabbed
            GetEntPropEnt(client, Prop_Send, "m_carryAttacker") > 0     || //hunter pounded
            GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0    || //charger carred
            GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") > 0    || //charger pounded
            GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0));     //jockey ridden
}

/**
 * @brief Returns who is pinning a client.
 * 
 * @param client    Client index.
 * @return          Entity index if client is being pinned. -1 otherwise.
 */
stock int GetSurvivorPinner(int client)
{
    if(!IsSurvivor(client)) return -1;

    return (GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0 ?     //smoker grabbed
            GetEntPropEnt(client, Prop_Send, "m_tongueOwner") : 
            GetEntPropEnt(client, Prop_Send, "m_carryAttacker") > 0 ?   //hunter pounded
            GetEntPropEnt(client, Prop_Send, "m_carryAttacker") : 
            GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0 ?  //charger carred
            GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") : 
            GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") > 0 ?  //charger pounded
            GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") :
            GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0 ?  //jockey ridden
            GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") : -1);
}

/**
 * @brief Returns true if client is pinning a survivor.
 * 
 * @param client    Client index.
 * @return          Survivor index for closest client. -1 otherwise.
 */
stock int GetClosestSurvivor(int client, bool incap = false)
{
    if(!IsValidClient(client)) return -1;

    int target = -1;
    float pos[3], tarPos[3], minDis = -1.0;
    GetClientAbsOrigin(client, pos);
    for(int i = 1; i <= MaxClients; i++)
    {
        if(!IsSurvivor(i) || !IsPlayerAlive(i) ||
            (!incap && IsPlayerIncap(i))) continue;
        GetClientAbsOrigin(i, tarPos);
        float dis = GetVectorDistance(pos, tarPos);
        if(dis >= minDis && minDis != -1.0)
            continue;
        minDis = dis;
        target = i;
    }

    return target;
}

/**
 * @brief Returns true if client is pinning a survivor.
 * 
 * @param client    Client index.
 * @return          Survivor index if client is pinning a survivor. -1 otherwise.
 */
stock int GetPinningSurvivor(int client)
{
    if(!IsInfected(client)) return -1;
    return (GetEntPropEnt(client, Prop_Send, "m_tongueVictim") > 0 ?     //smoker grabbed
            GetEntPropEnt(client, Prop_Send, "m_tongueVictim") : 
            GetEntPropEnt(client, Prop_Send, "m_pounceVictim") > 0 ?   //hunter pounded
            GetEntPropEnt(client, Prop_Send, "m_pounceVictim") : 
            GetEntPropEnt(client, Prop_Send, "m_carryVictim") > 0 ?  //charger carred
            GetEntPropEnt(client, Prop_Send, "m_carryVictim") : 
            GetEntPropEnt(client, Prop_Send, "m_pummelVictim") > 0 ?  //charger pounded
            GetEntPropEnt(client, Prop_Send, "m_pummelVictim") :
            GetEntPropEnt(client, Prop_Send, "m_jockeyVictim") > 0 ?  //jockey ridden
            GetEntPropEnt(client, Prop_Send, "m_jockeyVictim") : -1);
}

/**
 * @brief Returns true if client is pinning a survivor.
 * 
 * @param client    Client index.
 * @return          True if client is pinning a survivor. False otherwise.
 */
stock bool IsPinningASurvivor(int client)
{
    return (IsInfected(client) &&
            (GetEntPropEnt(client, Prop_Send, "m_tongueVictim") > 0     || //smoker grabbing
            GetEntPropEnt(client, Prop_Send, "m_pounceVictim") > 0      || //hunter pounding
            GetEntPropEnt(client, Prop_Send, "m_carryVictim") > 0       || //charger carrying
            GetEntPropEnt(client, Prop_Send, "m_pummelVictim") > 0      || //charger pounding
            GetEntPropEnt(client, Prop_Send, "m_jockeyVictim") > 0));      //jockey riding
}

/**
 * @brief Returns true if client is incapacitated.
 * 
 * @param client    Client index.
 * @return          True if client is incapacitated. False otherwise.
 */
stock bool IsPlayerIncap(int client)
{
    return (IsValidClient(client) && view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated")));
}

/**
 * @brief Returns true if survivor team is full.
 * 
 * @return          True if survivor team is full. False otherwise.
 */
stock bool IsSurvivorTeamFull()
{
    for (int i = 1; i <= MaxClients; i++)
        if (IsSurvivor(i) && IsPlayerAlive(i) && IsFakeClient(i))
            return false;

    return true;
}

/**
 * @brief Returns true if survivors are all pinnded.
 * 
 * @return          True if survivors are all pinnded. False otherwise.
 */
stock bool IsAllSurvivorPinned()
{
    for (int i = 1; i <= MaxClients; i++)
        if (IsSurvivor(i) && IsPlayerAlive(i) && !(IsSurvivorPinned(i) || IsPlayerIncap(i)))
            return false;

    return true;
}

/**
 * @brief Returns true if survivors are all incapped.
 * 
 * @return          True if survivora are all incapped. False otherwise.
 */
stock bool IsAllSurvivorIncapped()
{
    for(int i = 1; i <= MaxClients; i++)
        if (IsSurvivor(i) && !IsPlayerIncap(i))
            return false;
    
    return true;
}

/**
 * @brief Returns true if player can see threats.
 * 
 * @param client    Client index.
 * @return              True if player can see threats. False otherwise.
 */
stock bool CanPlayerSeeThreats(int client)
{
    return (IsValidClient(client) && view_as<bool>(GetEntProp(client, Prop_Send, "m_hasVisibleThreats")));
}

/**
 * @brief Returns true if any survivor alives.
 * 
 * @return          True if any survivor alives. False otherwise.
 */
stock bool HasSurvivorAlive()
{
    for (int i = 1; i <= MaxClients; i++)
        if (IsSurvivor(i) && IsPlayerAlive(i))
            return true;

    return false;
}

/**
 * @brief Returns true if any SI(Special Infected) but not tank alives.
 * 
 * @return          True if any SI(Special Infected) but not tank alives. False otherwise.
 */
stock bool HasInfectedAlive()
{
    for (int i = 1; i <= MaxClients; i++)
        if (IsInfected(i) && IsPlayerAlive(i) && !IsTank(i))
            return true;

    return false;
}

/**
 * @brief Get tank's frustration.
 * 
 * @param tankClient    Client index.
 * @return              Tank's frustration. -1 for false.
 */
stock int GetTankFrustration(int tankClient)
{
    return IsValidClient(tankClient) ? 100 - GetEntProp(tankClient, Prop_Send, "m_frustration") : -1;
}

/**
 * @brief Set tank's frustration.
 * 
 * @param tankClient    Client index.
 * @param frustration   Frustration value.
 * @return              True if succeed. False otherwise.
 */
stock bool SetTankFrustration(int tankClient, int frustration)
{
    if (!IsValidClient(tankClient)) return false;
    if (frustration < 0 || frustration > 100) return false;

    SetEntProp(tankClient, Prop_Send, "m_frustration", 100 - frustration);
    return true;
}

/**
 * @brief Get player's health.
 * 
 * @param client    Client index.
 * @return          Player's health. -1 for false.
 */
stock int GetPlayerHealth(int client)
{
    return IsValidClient(client) ? GetEntProp(client, Prop_Send, "m_iHealth") : -1;
}

/**
 * @brief Set player's health.
 * 
 * @param client    Client index.
 * @param health    Health value.
 * @return          True if succeed. False otherwise.
 */
stock bool SetPlayerHealth(int client, int health)
{
    if (!IsValidClient(client)) return false;
    if (health < 0) return false;

    SetEntProp(client, Prop_Send, "m_iHealth", health);
    return true;
}

/**
 * @brief Execute a command.
 * 
 * @param client    Client index.
 * @param strCmd    Command string.
 * @param strPrm    CmdParam string.
 * @return          True if succeed. False otherwise.
 */
stock bool ExecuteCommand(int client, const char[] strCmd, const char[] strPrm = "")
{
    if (!IsValidClient(client)) return false;

    int flags = GetCommandFlags(strCmd);
    SetCommandFlags(strCmd, flags & (~FCVAR_CHEAT));
    FakeClientCommand(client, "%s %s", strCmd, strPrm);
    SetCommandFlags(strCmd, flags);
    
    return true;
}

/**
 * @brief Get client SI(Special Infected) class.
 * 
 * @param client    Client index.
 * @return          SI class. -1 for false.
 */
stock int GetInfectedClass(int client)
{
    if(!IsValidClient(client) || !IsInfected(client)) return -1;

    return GetEntProp(client, Prop_Send, "m_zombieClass");
}

/**
 * @brief Get survivor count.
 * 
 * @return          Survivor count.
 */
stock int GetSurvivorCount()
{
    int count = 0;
    for (int i = 1; i <= MaxClients; i++)
        if (IsSurvivor(i))
            count++;

    return count;
}

/**
 * @brief Get SI(Special Infected) count.
 * 
 * @return          SI count.
 */
stock int GetSInfectedCount()
{
    int count = 0;
    for (int i = 1; i <= MaxClients; i++)
        if (IsInfected(i))
            count++;

    return count;
}


/**
 * @brief Get client count without special infected.
 * 
 * @return          Client count without special infected.
 */
stock int GetClientNoSICount()
{
    int count = 0;
    for (int i = 1; i <= MaxClients; i++)
        if (IsValidClient(i) && IsClientInGame(i) && !IsInfected(i))
            count++;

    return count;
}

/**
 * @brief Get player survivor count.
 * 
 * @return          Player survivor count.
 */
stock int GetSurvivorPlayerCount()
{
    int count = 0;
    for (int i = 1; i <= MaxClients; i++)
        if (IsSurvivor(i) && !IsFakeClient(i))
            count++;

    return count;
}

/**
 * @brief Get player SI(Special Infected) count.
 * 
 * @return          Player SI count.
 */
stock int GetInfectedPlayerCount()
{
    int count = 0;
    for (int i = 1; i <= MaxClients; i++)
        if (IsInfected(i) && !IsFakeClient(i))
            count++;

    return count;
}

/**
 * @brief Get alive survivor count.
 * 
 * @return          Alive survivor count.
 */
stock int GetAliveSurvivorCount()
{
    int count = 0;
    for (int i = 1; i <= MaxClients; i++)
        if (IsSurvivor(i) && IsPlayerAlive(i))
            count++;

    return count;
}

/**
 * @brief Get alive SI count.
 * 
 * @return          Alive SI count.
 */
stock int GetAliveInfectedCount()
{
    int count = 0;
    for (int i = 1; i <= MaxClients; i++)
        if (IsInfected(i) && IsPlayerAlive(i))
            count++;

    return count;
}

/**
 * @brief Delete client items
 * 
 * @return          No return.
 */
stock void DeleteInventoryItem(int client)
{
    if (!IsValidClient(client)) return;

    for(int s = 0; s < 5; s++)
    {
        int item = GetPlayerWeaponSlot(client, s);
        if (item > 0)
            RemovePlayerItem(client, item);
    }
}

/**
 * @brief Uses the VScript "CommandABot" function to command a bot to attack, move, retreat or reset previous command
 *
 * @param entity      The bot or infected to command
 * @param target      The Special Infected to target (used for types "CMDBOT_ATTACK" and "CMDBOT_RETREAT")
 * @param type        Type of command
 * @param vecPos      Move to this location (Used for type "CMDBOT_MOVE")
 *
 * @return  Returns false when unable to perform, true otherwise.
 */
stock bool CommandABot(int entity, int target, int type, float pos[3] = NULL_VECTOR)
{
    if(!IsValidClient(entity) || !IsFakeClient(entity)) return false;
    char param[PLATFORM_MAX_PATH];
    switch(type)
    {
        case CMDBOT_ATTACK, CMDBOT_RETREAT:
            Format(param, sizeof(param), "CommandABot({cmd = %d, bot = GetPlayerFromUserID(%i), target = GetPlayerFromUserID(%i)})", type, GetClientUserId(entity), GetClientUserId(target));
        case CMDBOT_MOVE:
            Format(param, sizeof(param), "CommandABot({cmd = %d, pos = Vector(%f, %f, %f), bot = GetPlayerFromUserID(%i)})", type, pos[0], pos[1], pos[2], GetClientUserId(entity));
        case CMDBOT_RESET:
            Format(param, sizeof(param), "CommandABot({cmd = %d, bot = GetPlayerFromUserID(%i)})", type, GetClientUserId(entity));

        default:
            return false;
    }
    ExecuteCommand(entity, "script", param);

    return true;
}

/**
 * @brief Runs a specified VScript code and returns values from it.
 *
 * @param code            The VScript code to execute. Maximum length seems to be 1006 characters.
 * @param result          Buffer to copy return data to. You can use StringToInt or StringToFloat if required.
 * @param maxlength       Maximum size of the result.
 *
 * @return                True on success, false otherwise.
 */
#pragma deprecated This is nonachievement.
stock bool ExecuteVscript(char[] code, char[] result, int maxlength)
{
    int script = CreateEntityByName("logic_script");
    if(!IsValidEdict(script)) return false;
    DispatchSpawn(script);

    if((StrContains(code, "<r>") | StrContains(code, "</r>")) < 0) return false;

    char buffer[1024], put[] = "NetProps.SetPropString(%d, \"m_iName\", ";
    Format(put, sizeof(put), put, script);
    strcopy(buffer, sizeof(buffer), code);
    ReplaceString(buffer, sizeof(buffer), "<r>", put);
    ReplaceString(buffer, sizeof(buffer), "</r>", ");");
    SetVariantString(buffer);
    PrintToChatAll("%s", buffer);

    AcceptEntityInput(script, "RunScriptCode");
    GetEntPropString(script, Prop_Data, "m_iName", result, maxlength);

    AcceptEntityInput(script, "Kill");
    RemoveEdict(script);

    return true;
}

/**
 * Sets custom ability cooldown of client.
 *
 * Note: Used for the Infected class abilities.
 *
 * @param client        Client index.
 * @param time          How long before client can use their custom ability.
 *
 * @return              True if set, false if no ability found.
 */
stock bool SetAbilityCooldown(int client, float time)
{
    int ability = GetEntPropEnt(client, Prop_Send, "m_customAbility");
    if (ability > 0 && IsValidEdict(ability))
    {
        SetEntPropFloat(ability, Prop_Send, "m_duration", time);
        SetEntPropFloat(ability, Prop_Send, "m_timestamp", GetGameTime() + time);
        return true;
    }
    return false;
}