#if defined l4d2util_survivors_inc_
	#endinput
#endif
#define l4d2util_survivors_inc_

#include <sdktools>
#include <l4d2util_constants>
#include <l4d2util_stocks>

// In order to quickly get the index of a survivor character.
// Much faster than searching by model in the StringMap.
stock const int g_iGenderToSurvivorIndex[L4D2Gender_MaxSize] =
{
	SurvivorCharacter_Invalid, // L4D2Gender_Neutral = 0,
	SurvivorCharacter_Invalid, // L4D2Gender_Male = 1,
	SurvivorCharacter_Invalid, // L4D2Gender_Female = 2,
	SurvivorCharacter_Bill, // L4D2Gender_Nanvet = 3, // Bill
	SurvivorCharacter_Zoey, // L4D2Gender_TeenGirl = 4, // Zoey
	SurvivorCharacter_Francis, // L4D2Gender_Biker = 5, // Francis
	SurvivorCharacter_Louis, // L4D2Gender_Manager = 6, // Louis
	SurvivorCharacter_Nick, // L4D2Gender_Gambler = 7, // Nick
	SurvivorCharacter_Rochelle, // L4D2Gender_Producer = 8, // Rochelle
	SurvivorCharacter_Coach, // L4D2Gender_Coach = 9, // Coach
	SurvivorCharacter_Ellis, // L4D2Gender_Mechanic = 10, // Ellis
	SurvivorCharacter_Invalid, // L4D2Gender_Ceda = 11,
	SurvivorCharacter_Invalid, // L4D2Gender_Crawler = 12, // Mudman
	SurvivorCharacter_Invalid, // L4D2Gender_Undistractable = 13, // Workman (class not reacting to the pipe bomb)
	SurvivorCharacter_Invalid, // L4D2Gender_Fallen = 14,
	SurvivorCharacter_Invalid, // L4D2Gender_Riot_Control = 15, // RiotCop
	SurvivorCharacter_Invalid, // L4D2Gender_Clown = 16,
	SurvivorCharacter_Invalid, // L4D2Gender_Jimmy = 17, // JimmyGibbs
	SurvivorCharacter_Invalid, // L4D2Gender_Hospital_Patient = 18,
	SurvivorCharacter_Invalid, // L4D2Gender_Witch_Bride = 19,
	SurvivorCharacter_Invalid, // L4D2Gender_Police = 20, // l4d1 RiotCop (was removed from the game)
	SurvivorCharacter_Invalid, // L4D2Gender_Male_L4D1 = 21,
	SurvivorCharacter_Invalid, // L4D2Gender_Female_L4D1 = 22
};

stock const char L4D2_AttackerNetProps[][] =
{
	"m_tongueOwner",	// Smoker
	"m_pounceAttacker",	// Hunter
	"m_jockeyAttacker",	// Jockey
	"m_carryAttacker", // Charger carry
	"m_pummelAttacker",	// Charger pummel
};

/**
 * Returns true if the survivor was attacked
 *
 * @param client client ID
 * @return bool
 */
stock bool IsSurvivorAttacked(int survivor)
{
	for (int i = 0; i < sizeof(L4D2_AttackerNetProps); i++) {
		if (GetEntPropEnt(survivor, Prop_Send, L4D2_AttackerNetProps[i]) != -1) {
			return true;
		}
	}

	return false;
}

/**
 * Returns true if the client is currently on the survivor team. 
 *
 * @param client client ID
 * @return bool
 */
stock bool IsSurvivor(int client)
{
	return (IsClientInGame(client) && GetClientTeam(client) == L4D2Team_Survivor);
}

/**
 * Return true if the valid client index and is client on the survivor team.
 *
 * @param client client ID
 * @return bool
 */
stock bool IsValidSurvivor(int client)
{
	return (IsValidClientIndex(client) && IsSurvivor(client));
}

/**
 * Returns true if the player is incapacitated. 
 *
 * @param client client ID
 * @return bool
 */
stock bool IsIncapacitated(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated", 1));
}

/**
 * Returns the amount of permanent health a survivor has. 
 *
 * @param client client ID
 * @return int
 */
stock int GetSurvivorPermanentHealth(int client)
{
	return GetEntProp(client, Prop_Send, "m_iHealth");
}

/**
 * Returns the amount of temporary health a survivor has. 
 *
 * @param client client ID
 * @return int
 */
stock int GetSurvivorTemporaryHealth(int client)
{
	static ConVar pain_pills_decay_rate = null;
	if (pain_pills_decay_rate == null)
	{
		pain_pills_decay_rate = FindConVar("pain_pills_decay_rate");
	}
	
	float fDecayRate = pain_pills_decay_rate.FloatValue;

	float fHealthBuffer = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	float fHealthBufferTimeStamp = GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
	
	float fHealthBufferDuration = GetGameTime() - fHealthBufferTimeStamp;

	int iTempHp = RoundToCeil(fHealthBuffer - (fHealthBufferDuration * fDecayRate)) - 1;

	return (iTempHp > 0) ? iTempHp : 0;
}

/**
 * The number of times a survivor has been incapacitated.
 *
 * @param client client ID
 * @return incap count
 */
stock int GetSurvivorIncapCount(int client)
{
	return GetEntProp(client, Prop_Send, "m_currentReviveCount");
}

/**
 * Returns true if the survivor is hanging onto a ledge (or falling from one to their doom).
 *
 * @param client client ID
 * @return bool
 */
stock bool IsHangingFromLedge(int client)
{
	return (view_as<bool>(GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1))
		|| view_as<bool>(GetEntProp(client, Prop_Send, "m_isFallingFromLedge", 1)));
}

/**
 * Identifies the survivor character based on netprop 'm_Gender'.
 * Contains checks for a valid player.
 *
 * @remark SurvivorCharacter_Invalid on errors
 *
 * @param client				Survivor client to identify
 *
 * @return int					index identifying the survivor, or SurvivorCharacter_Invalid if not identified.
 */
stock int IdentifySurvivor(int iClient)
{
	if (iClient < 1 || iClient > MaxClients || !IsClientInGame(iClient)) {
		return SurvivorCharacter_Invalid;
	}

	int iGender = GetEntProp(iClient, Prop_Send, "m_Gender");
	return g_iGenderToSurvivorIndex[iGender];
}

/**
 * Identifies the survivor character based on netprop 'm_Gender'.
 * Does not contain checks for a valid player.
 *
 * @remark SurvivorCharacter_Invalid on errors
 *
 * @param client				Survivor client to identify
 *
 * @return int					index identifying the survivor, or SurvivorCharacter_Invalid if not identified.
 */
stock int IdentifySurvivorFast(int iClient)
{
	int iGender = GetEntProp(iClient, Prop_Send, "m_Gender");
	return g_iGenderToSurvivorIndex[iGender];
}

/**
 * Get the display name of a survivor character. 
 * Will write to string 'Invalid' in case of error.
 * Contains checks for the index of the survivor character.
 *
 * @param character     int to get the name of
 * @param buffer        buffer to store name
 * @param length        length of buffer
 *
 * @return bool         false if SurvivorCharacter_Invalid, otherwise true
 */
stock bool GetSurvivorDisplayNameByIndex(int iCharacter, char[] sBuffer, const int iLength)
{
	if (iCharacter < SurvivorCharacter_Nick || iCharacter > SurvivorCharacter_Invalid) {
		strcopy(sBuffer, iLength, g_sSurvivorDisplayName[SurvivorCharacter_Invalid]);

		//LogError("[GetSurvivorDisplayNameByIndex] Invalid survivor character index passed!");

		return false;
	}

	strcopy(sBuffer, iLength, g_sSurvivorDisplayName[iCharacter]);

	return (iCharacter == SurvivorCharacter_Invalid) ? false : true;
}

/**
 * Get the display name of a survivor character. 
 * Will write to string 'Invalid' in case of error.
 * Does not contain checks for the index of the survivor character.
 *
 * @param character     int to get the name of
 * @param buffer        buffer to store name
 * @param length        length of buffer
 *
 * @noreturn bool
 */
stock void GetSurvivorDisplayNameByIndexFast(int iCharacter, char[] sBuffer, const int iLength)
{
	strcopy(sBuffer, iLength, g_sSurvivorDisplayName[iCharacter]);
}

/**
 * Get the name of a survivor character.
 * Will write to string 'Invalid' in case of error.
 * Contains checks for the index of the survivor character.
 *
 * @param character     int to get the name of
 * @param buffer        buffer to store name
 * @param length        length of buffer
 *
 * @return bool         false if SurvivorCharacter_Invalid, otherwise true
 */
stock bool GetSurvivorNameByIndex(int iCharacter, char[] sBuffer, const int iLength)
{
	if (iCharacter < SurvivorCharacter_Nick || iCharacter > SurvivorCharacter_Invalid) {
		strcopy(sBuffer, iLength, g_sSurvivorName[SurvivorCharacter_Invalid]);

		//LogError("[GetSurvivorNameByIndex] Invalid survivor character index passed!");

		return false;
	}

	strcopy(sBuffer, iLength, g_sSurvivorName[iCharacter]);

	return (iCharacter == SurvivorCharacter_Invalid) ? false : true;
}

/**
 * Get the name of a survivor character.
 * Will write to string 'Invalid' in case of error.
 * Does not contain checks for the index of the survivor character.
 *
 * @param character     int to get the name of
 * @param buffer        buffer to store name
 * @param length        length of buffer
 *
 * @noreturn
 */
stock void GetSurvivorNameByIndexFast(int iCharacter, char[] sBuffer, const int iLength)
{
	strcopy(sBuffer, iLength, g_sSurvivorName[iCharacter]);
}

/**
 * Get the display name of a survivor character through client index.
 * Will write to string 'Invalid' in case of error.
 * Contains checks for a valid player.
 *
 * @param client        client index
 * @param buffer        buffer to store name
 * @param length        length of buffer
 *
 * @return bool         false if SurvivorCharacter_Invalid, otherwise true
 */
stock bool GetSurvivorDisplayName(int iClient, char[] sBuffer, const int iLength)
{
	if (iClient < 1 || iClient > MaxClients || !IsClientInGame(iClient)) {
		return false;
	}

	int iCharacter = g_iGenderToSurvivorIndex[GetEntProp(iClient, Prop_Send, "m_Gender")];

	strcopy(sBuffer, iLength, g_sSurvivorDisplayName[iCharacter]);

	return (iCharacter == SurvivorCharacter_Invalid) ? false : true;
}

/**
 * Get the display name of a survivor character through client index.
 * Will write to string 'Invalid' in case of error.
 * Does not contain checks for a valid player.
 *
 * @param client        client index
 * @param buffer        buffer to store name
 * @param length        length of buffer
 *
 * @noreturn
 */
stock void GetSurvivorDisplayNameFast(int iClient, char[] sBuffer, const int iLength)
{
	int iCharacter = g_iGenderToSurvivorIndex[GetEntProp(iClient, Prop_Send, "m_Gender")];

	strcopy(sBuffer, iLength, g_sSurvivorDisplayName[iCharacter]);
}

/**
 * Get the name of a survivor character through client index.
 * Will write to string 'Invalid' in case of error.
 * Contains checks for a valid player.
 *
 * @param client        client index
 * @param buffer        buffer to store name
 * @param length        length of buffer
 *
 * @return bool         false if SurvivorCharacter_Invalid, otherwise true
 */
stock bool GetSurvivorName(int iClient, char[] sBuffer, const int iLength)
{
	if (iClient < 1 || iClient > MaxClients || !IsClientInGame(iClient)) {
		return false;
	}

	int iCharacter = g_iGenderToSurvivorIndex[GetEntProp(iClient, Prop_Send, "m_Gender")];

	strcopy(sBuffer, iLength, g_sSurvivorName[iCharacter]);

	return (iCharacter == SurvivorCharacter_Invalid) ? false : true;
}

/**
 * Get the name of a survivor character through client index.
 * Will write to string 'Invalid' in case of error.
 * Does not contain checks for a valid player.
 *
 * @param client        client index
 * @param buffer        buffer to store name
 * @param length        length of buffer
 *
 * @noreturn
 */
stock void GetSurvivorNameFast(int iClient, char[] sBuffer, const int iLength)
{
	int iCharacter = g_iGenderToSurvivorIndex[GetEntProp(iClient, Prop_Send, "m_Gender")];

	strcopy(sBuffer, iLength, g_sSurvivorName[iCharacter]);
}
