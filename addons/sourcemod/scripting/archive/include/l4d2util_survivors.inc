#if defined l4d2util_survivors_inc_
	#endinput
#endif
#define l4d2util_survivors_inc_

#include <sdktools>
#include <l4d2util_constants>
#include <l4d2util_stocks>

stock static StringMap hSurvivorModelsTrie = null;

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
	return (IsClientInGame(client) && GetClientTeam(client) == view_as<int>(L4D2Team_Survivor));
}

/**
 * Return true if the valid client index and is client on the survivor team.
 *
 * @param client client ID
 * @return bool
 */
stock bool IsValidSurvivor(int client)
{
	return (L4D2Util_IsValidClient(client) && IsSurvivor(client));
}

/**
 * Returns true if the player is incapacitated. 
 *
 * @param client client ID
 * @return bool
 */
stock bool IsIncapacitated(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated"));
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
	return (view_as<bool>(GetEntProp(client, Prop_Send, "m_isHangingFromLedge")) 
		|| view_as<bool>(GetEntProp(client, Prop_Send, "m_isFallingFromLedge")));
}

/**
 * Initializes internal structure necessary for IdentifySurvivor() function
 * @remark It is recommended that you run this function on plugin start, but not necessary
 *
 * @noreturn
 */
stock void InitSurvivorModelTrie()
{
	hSurvivorModelsTrie = new StringMap();
	for (int i = 0; i < view_as<int>(SurvivorCharacter_Size); i++) {
		hSurvivorModelsTrie.SetValue(SurvivorModels[i], i);
	}
}

/**
 * Identifies a client's survivor character based on their current model.
 * @remark SurvivorCharacter_Invalid on errors
 *
 * @param client                Survivor client to identify
 * @return SurvivorCharacter    index identifying the survivor, or SurvivorCharacter_Invalid if not identified.
 */
stock SurvivorCharacter IdentifySurvivor(int client)
{
	if (!client || !IsSurvivor(client)) {
		return SurvivorCharacter_Invalid;
	}

	char clientModel[42];
	GetClientModel(client, clientModel, sizeof(clientModel));

	return ClientModelToSC(clientModel);
}

/**
 * Identifies the survivor character corresponding to a player model.
 * @remark SurvivorCharacter_Invalid on errors, uses SurvivorModelTrie
 *
 * @param model                 Player model to identify
 * @return SurvivorCharacter    index identifying the model, or SurvivorCharacter_Invalid if not identified.
 */
stock SurvivorCharacter ClientModelToSC(const char[] model)
{
	if (hSurvivorModelsTrie == null) {
		InitSurvivorModelTrie();
	}
	
	SurvivorCharacter sc;
	if (hSurvivorModelsTrie.GetValue(model, sc)) {
		return sc;
	}

	return SurvivorCharacter_Invalid;
}

/**
 * Get the name of a survivor character. 
 * Will write to string 'None' in case of error.
 * 
 * @param character     SurvivorCharacter to get the name of
 * @param buffer        buffer to store name
 * @param length        length of buffer
 * @return bool         false if SurvivorCharacter_Invalid, otherwise true
 */
stock bool GetSurvivorName(SurvivorCharacter character, char[] buffer, const int length)
{
	if (character == SurvivorCharacter_Invalid) {
		strcopy(buffer, length, "None");
		return false;
	}

	strcopy(buffer, length, SurvivorNames[view_as<int>(character)]);

	return true;
}

/**
 * Get the name of a survivor character through client index.
 * Will write to string 'None' in case of error.
 *
 * @param client        client index
 * @param buffer        buffer to store name
 * @param length        length of buffer
 * @return bool         false if SurvivorCharacter_Invalid, otherwise true
 */
stock bool GetClientSurvivorName(int client, char[] buffer, const int length)
{
	SurvivorCharacter character = IdentifySurvivor(client);
	if (character == SurvivorCharacter_Invalid) {
		strcopy(buffer, length, "None");
		return false;
	}

	strcopy(buffer, length, SurvivorNames[view_as<int>(character)]);

	return true;
}
