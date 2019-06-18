#if defined l4d2util_survivors_inc_
    #endinput
#endif
#define l4d2util_survivors_inc_

static Handle:hSurvivorModelsTrie = INVALID_HANDLE;

/**
 * Returns true if the player is currently on the survivor team. 
 *
 * @param client client ID
 * @return bool
 */
stock bool:IsSurvivor(client) {
    if (!IsClientInGame(client) || L4D2_Team:GetClientTeam(client) != L4D2Team_Survivor) {
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
stock bool:IsIncapacitated(client) {
    return bool:GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

/**
 * Returns the amount of permanent health a survivor has. 
 *
 * @param client client ID
 * @return bool
 */
stock GetSurvivorPermanentHealth(client) {
    return GetEntProp(client, Prop_Send, "m_iHealth");
}

/**
 * Returns the amount of temporary health a survivor has. 
 *
 * @param client client ID
 * @return bool
 */
stock GetSurvivorTemporaryHealth(client) {
    new Float:fDecayRate = GetConVarFloat(FindConVar("pain_pills_decay_rate"));
    new Float:fHealthBuffer = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
    new Float:fHealthBufferTime = GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
    new iTempHp = RoundToCeil(fHealthBuffer - ((GetGameTime() - fHealthBufferTime) * fDecayRate)) - 1;
    return iTempHp > 0 ? iTempHp : 0;
}

/**
 * The number of times a survivor has been incapacitated.
 *
 * @param client client ID
 * @return incap count
 */
stock GetSurvivorIncapCount(client) {
    return GetEntProp(client, Prop_Send, "m_currentReviveCount");
}

/**
 * Returns true if the survivor is hanging onto a ledge (or falling from one to their doom).
 *
 * @param client client ID
 * @return bool
 */
stock bool:IsHangingFromLedge(client) {
    return bool:(GetEntProp(client, Prop_Send, "m_isHangingFromLedge") || GetEntProp(client, Prop_Send, "m_isFallingFromLedge"));
}

/**
 * Initializes internal structure necessary for IdentifySurvivor() function
 * @remark It is recommended that you run this function on plugin start, but not necessary
 *
 * @noreturn
 */
stock InitSurvivorModelTrie()
{
    hSurvivorModelsTrie = CreateTrie();
    for(new i = 0; i < _:SurvivorCharacter; i++)
    {
        SetTrieValue(hSurvivorModelsTrie, SurvivorModels[SurvivorCharacter:i], i);
    }
}

/**
 * Identifies a client's survivor character based on their current model.
 * @remark SC_NONE on errors
 *
 * @param client                Survivor client to identify
 * @return SurvivorCharacter    index identifying the survivor, or SC_NONE if not identified.
 */
stock SurvivorCharacter:IdentifySurvivor(client)
{
    if (!client || !IsClientInGame(client) || !IsSurvivor(client))
    {
        return SC_NONE;
    }
    decl String:clientModel[42];
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
stock SurvivorCharacter:ClientModelToSC(const String:model[])
{
    if(hSurvivorModelsTrie == INVALID_HANDLE)
    {
        InitSurvivorModelTrie();
    }
    new SurvivorCharacter:sc;
    if(GetTrieValue(hSurvivorModelsTrie, model, sc))
    {
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
stock bool:GetSurvivorName(SurvivorCharacter:character, String:buffer[], length)
{
    if (character == SC_NONE)
        return false;

    strcopy(buffer, length, SurvivorNames[_:character]);
    return true;
}
