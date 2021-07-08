#if defined l4d2util_infected_inc_
	#endinput
#endif
#define l4d2util_infected_inc_

#include <sdktools>
#include <l4d2util_constants>

#define UTIL_ARRAY_INDEX_DURATION 0
#define UTIL_ARRAY_INDEX_TIMESTAMP 1

// Internal array of strings for timer ability timer entity classnames
stock const char L4D2_InfectedTimerEntities[8][] =
{
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
stock const char L4D2_InfectedVictimNetprops[8][] =
{
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
stock bool IsInfected(int client)
{
	return (IsClientInGame(client) && view_as<L4D2_Team>(GetClientTeam(client)) == L4D2Team_Infected);
}

/**
 * Returns the ID of the client's infected class. Use GetInfectedClassName()
 * to convert it to a string.
 *
 * @param client client ID
 * @return class ID
 */
stock L4D2_Infected GetInfectedClass(int client)
{
	return view_as<L4D2_Infected>(GetEntProp(client, Prop_Send, "m_zombieClass"));
}

/**
 * Return true if the infected is in ghost (spawn) mode.
 *
 * @param client client ID
 * @return bool
 */
stock bool IsInfectedGhost(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isGhost"));
}

/**
 * Converts an infected type ID to a string.
 *
 * @param iClass infected class ID
 * @param sBuffer buffer to store the class name in
 * @param iBufLen size of sBuffer
 * @noreturn
 */
stock void GetInfectedClassName(L4D2_Infected iClass, char[] sBuffer, const int iBufLen)
{
	strcopy(sBuffer, iBufLen, L4D2_InfectedNames[view_as<int>(iClass) - 1]);
}

/**
 * Internal function for retrieving the game entity associtated with an ability
 *
 * @param owner client ID of the entity's owner
 * @param type classname of entity
 * @return entity ID or -1
 */
stock int GetInfectedAbilityEntity(int owner)
{
	return GetEntPropEnt(owner, Prop_Send, "m_customAbility");
}

/**
 * Get the timestamp and duration of an SI's ability timer
 *
 * @param client whose timer to get
 * @param timestamp output parameter for the timestamp
 * @param duration output parameter for the duration
 * @return true if the timer was found otherwise false
 */
stock bool GetInfectedAbilityTimer(int client, float &timestamp, float &duration)
{
	L4D2_Infected zClass = GetInfectedClass(client);
	if (strlen(L4D2_InfectedTimerEntities[view_as<int>(zClass) - 1]) == 0) {
		return false;
	}

	int ability = GetInfectedAbilityEntity(client);
	if (ability == -1 || !IsValidEntity(ability)) {
		return false;
	}
	
	/*
	 * Table: m_nextActivationTimer (offset 1104) (type DT_CountdownTimer)
	 *	Member: m_duration (offset 4) (type float) (bits 0) (NoScale)
	 *	Member: m_timestamp (offset 8) (type float) (bits 0) (NoScale)
	*/
	duration = GetEntPropFloat(ability, Prop_Send, "m_nextActivationTimer", UTIL_ARRAY_INDEX_DURATION);
	timestamp = GetEntPropFloat(ability, Prop_Send, "m_nextActivationTimer", UTIL_ARRAY_INDEX_TIMESTAMP);

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
stock bool SetInfectedAbilityTimer(int client, float &timestamp, float &duration)
{
	L4D2_Infected zClass = GetInfectedClass(client);

	if (strlen(L4D2_InfectedTimerEntities[view_as<int>(zClass) - 1]) == 0) {
		return false;
	}

	int ability = GetInfectedAbilityEntity(client);
	if (ability == -1 || !IsValidEntity(ability)) {
		return false;
	}
	
	/*
	 * Table: m_nextActivationTimer (offset 1104) (type DT_CountdownTimer)
	 *	Member: m_duration (offset 4) (type float) (bits 0) (NoScale)
	 *	Member: m_timestamp (offset 8) (type float) (bits 0) (NoScale)
	*/
	SetEntPropFloat(ability, Prop_Send, "m_nextActivationTimer", duration, UTIL_ARRAY_INDEX_DURATION);
	SetEntPropFloat(ability, Prop_Send, "m_nextActivationTimer", timestamp, UTIL_ARRAY_INDEX_TIMESTAMP);

	return true;
}

/**
 * Gets an infected's victim. A victim is a survivor who is currently being dominated, i.e. smoked, charged, hunted or jockeyed.
 *
 * @param client whose victim to get
 * @return client ID or -1 on error
 */
stock int GetInfectedVictim(int client)
{
	L4D2_Infected zClass = GetInfectedClass(client);

	if (strlen(L4D2_InfectedVictimNetprops[view_as<int>(zClass) - 1]) == 0) {
		return -1;
	}

	return GetEntPropEnt(client, Prop_Send, L4D2_InfectedVictimNetprops[view_as<int>(zClass) - 1]);
}

/**
 * Gets an entity's gender
 *
 * @param entity
 * @return L4D_Gender
 */
stock L4D2_Gender GetGender(int entity)
{
	return view_as<L4D2_Gender>(GetEntProp(entity, Prop_Send, "m_Gender"));
}
