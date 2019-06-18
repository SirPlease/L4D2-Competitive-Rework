#if defined l4d2util_infected_inc_
    #endinput
#endif
#define l4d2util_infected_inc_

#include <sdktools>

// Internal array of strings for timer ability timer entity classnames
new const String:L4D2_InfectedTimerEntities[8][] = {
    "ability_tongue",
    "ability_vomit",
    "ability_lunge",
    "ability_spit",
    "ability_leap",
    "ability_charge",
    "",
    ""
};

// Internal array of strings for Infected victim netprops
new const String:L4D2_InfectedVictimNetprops[8][] = {
    "m_tongueVictim",
    "",
    "m_pounceVictim",
    "",
    "m_jockeyVictim",
    "m_pummelVictim",
    "",
    ""
};

/**
 * Return true if the client is on the infected team.
 *
 * @param client client ID
 * @return bool
 */
stock bool:IsInfected(client) {
    if (!IsClientInGame(client) || L4D2_Team:GetClientTeam(client) != L4D2Team_Infected) {
        return false;
    }
    return true;
}

/**
 * Returns the ID of the client's infected class. Use GetInfectedClassName()
 * to convert it to a string.
 *
 * @param client client ID
 * @return class ID
 */
stock L4D2_Infected:GetInfectedClass(client) {
    return L4D2_Infected:GetEntProp(client, Prop_Send, "m_zombieClass");
}

/**
 * Return true if the infected is in ghost (spawn) mode.
 *
 * @param client client ID
 * @return bool
 */
stock bool:IsInfectedGhost(client) {
    return bool:GetEntProp(client, Prop_Send, "m_isGhost");
}

/**
 * Converts an infected type ID to a string.
 *
 * @param iClass infected class ID
 * @param sBuffer buffer to store the class name in
 * @param iBufLen size of sBuffer
 * @noreturn
 */
stock GetInfectedClassName(L4D2_Infected:iClass, String:sBuffer[], iBufLen) {
    strcopy(sBuffer, iBufLen, L4D2_InfectedNames[_:iClass-1]); 
}

/**
 * Internal function for retrieving the game entity associtated with an ability
 *
 * @param owner client ID of the entity's owner
 * @param type classname of entity
 * @return entity ID or -1
 */
stock GetInfectedAbilityTimerEntity(owner, const String:type[]) {
    new iEntity = -1;
    while ((iEntity = FindEntityByClassname(iEntity, type)) != -1) {
        if (GetEntPropEnt(iEntity, Prop_Send, "m_owner") == owner) {
            break;
        }
    }
    return iEntity;
}

/**
 * Get the timestamp and duration of an SI's ability timer
 *
 * @param client whose timer to get
 * @param timestamp output parameter for the timestamp
 * @param duration output parameter for the duration
 * @return true if the timer was found otherwise false
 */
stock bool:GetInfectedAbilityTimer(client, &Float:timestamp, &Float:duration) {
    new L4D2_Infected:zClass = GetInfectedClass(client);
    new ability = -1;
    
    if (strlen(L4D2_InfectedTimerEntities[_:zClass-1]) == 0) {
        return false;
    }
    
    ability = GetInfectedAbilityTimerEntity(client, L4D2_InfectedTimerEntities[_:zClass-1]);
    if (ability == -1) {
        return false;
    }
    
    timestamp = GetEntPropFloat(ability, Prop_Send, "m_timestamp");
    duration = GetEntPropFloat(ability, Prop_Send, "m_duration");
    return true;
}

/**
 * Set the timestamp and duration of an SI's ability timer
 *
 * @param client whose timer to set
 * @param timestamp
 * @param duration
 * @return true if the timer was found otherwise false
 */
stock bool:SetInfectedAbilityTimer(client, Float:timestamp, Float:duration) {
    new L4D2_Infected:zClass = GetInfectedClass(client);
    new ability = -1;
    
    if (strlen(L4D2_InfectedTimerEntities[_:zClass-1]) == 0) {
        return false;
    }
    
    ability = GetInfectedAbilityTimerEntity(client, L4D2_InfectedTimerEntities[_:zClass-1]);
    if (ability == -1) {
        return false;
    }
    
    SetEntPropFloat(ability, Prop_Send, "m_timestamp", timestamp);
    SetEntPropFloat(ability, Prop_Send, "m_duration", duration);
    return true;
}

/**
 * Gets an infected's victim. A victim is a survivor who is currently being dominated, i.e. smoked, charged, hunted or jockeyed.
 *
 * @param client whose victim to get
 * @return client ID or -1 on error
 */
stock GetInfectedVictim(client) {
    new L4D2_Infected:zClass = GetInfectedClass(client);
    
    if (strlen(L4D2_InfectedVictimNetprops[_:zClass-1]) == 0) {
        return -1;
    }
    
    return GetEntPropEnt(client, Prop_Send, L4D2_InfectedVictimNetprops[_:zClass-1]);
}

/**
 * Gets an entity's gender
 *
 * @param entity
 * @return L4D_Gender
 */
stock L4D2_Gender:GetGender(entity) {
    return L4D2_Gender:GetEntProp(entity, Prop_Send, "m_Gender");
}
