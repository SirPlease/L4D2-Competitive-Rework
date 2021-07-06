#if defined l4d2util_survivors_inc_
	#endinput
#endif
#define l4d2util_survivors_inc_

stock static Handle hSurvivorModelsTrie = null;

/**
 * Returns true if the player is currently on the survivor team. 
 *
 * @param client client ID
 * @return bool
 */
stock bool IsSurvivor(int client)
{
	if (!IsClientInGame(client) || view_as<L4D2_Team>(GetClientTeam(client)) != L4D2Team_Survivor) {
		return false;
	}

	return true;
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
	float fDecayRate = (FindConVar("pain_pills_decay_rate")).FloatValue;

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
	hSurvivorModelsTrie = CreateTrie();
	for (int i = 0; i < view_as<int>(SurvivorCharacter); i++) {
		SetTrieValue(hSurvivorModelsTrie, SurvivorModels[i], i);
	}
}

/**
 * Identifies a client's survivor character based on their current model.
 * @remark SC_NONE on errors
 *
 * @param client                Survivor client to identify
 * @return SurvivorCharacter    index identifying the survivor, or SC_NONE if not identified.
 */
stock SurvivorCharacter IdentifySurvivor(int client)
{
	if (!client || !IsClientInGame(client) || !IsSurvivor(client)) {
		return SC_NONE;
	}

	char clientModel[42];
	GetClientModel(client, clientModel, sizeof(clientModel));

	return ClientModelToSC(clientModel);
}

/**
 * Identifies the survivor character corresponding to a player model.
 * @remark SC_NONE on errors, uses SurvivorModelTrie
 *
 * @param model                 Player model to identify
 * @return SurvivorCharacter    index identifying the model, or SC_NONE if not identified.
 */
stock SurvivorCharacter ClientModelToSC(const char[] model)
{
	if (hSurvivorModelsTrie == null) {
		InitSurvivorModelTrie();
	}
	
	SurvivorCharacter sc;
	if (GetTrieValue(hSurvivorModelsTrie, model, sc)) {
		return sc;
	}

	return SC_NONE;
}

/**
 * Get the name of a survivor character.
 *
 * @param character     SurvivorCharacter to get the name of
 * @param buffer        buffer to store name
 * @param length        length of buffer
 * @return bool         false if SC_NONE, otherwise true
 */
stock bool GetSurvivorName(SurvivorCharacter character, char[] buffer, const int length)
{
	if (character == SC_NONE) {
		return false;
	}

	strcopy(buffer, length, SurvivorNames[view_as<int>(character)]);

	return true;
}

