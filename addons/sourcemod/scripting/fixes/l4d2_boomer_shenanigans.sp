#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>

public Plugin myinfo =
{
	name = "L4D2 Boomer Shenanigans",
	author = "Sir",
	description = "Make sure Boomers are unable to bile Survivors during a stumble (basically reinforce shoves)",
	version = "1.0",
	url = "None."
};

public Action L4D_OnShovedBySurvivor(int client, int victim, const float vecDirection[3])
{
	// Make sure we've got a Boomer on our hands.
	// (L4D2 only uses this on Special Infected so we don't need to check Client Team for the victim)
	// We're only checking Valid Client because it's Valve. ;D
	if (!IsValidClient(victim) ||
	!IsValidClient(client) ||
	GetEntProp(victim, Prop_Send, "m_zombieClass") != 2)
		return Plugin_Continue;

	// Get the Ability
	int iAbility = GetEntPropEnt(victim, Prop_Send,"m_customAbility")

	// Make sure it's a valid Ability.
	if (!IsValidEntity(iAbility)) return Plugin_Continue;

	// timestamp is when the Boomer can boom again.
	float timestamp = GetEntPropFloat(iAbility, Prop_Send, "m_timestamp");
	float gametime = GetGameTime();
	int bUsed = GetEntProp(iAbility, Prop_Send, "m_hasBeenUsed");

	// - 2 Scenarios where we'll have to "reinforce" the shove.
	// If bUsed is false the Boomer hasn't boomed yet in this lifetime (Respawning will reset this to false)
	// If bUsed is true but the Boomer is able to bile (If boomer kept his spawn and is going for another attack)
	if (!bUsed ||
	gametime >= timestamp) 
		SetEntPropFloat(iAbility, Prop_Send, "m_timestamp", gametime + 1.0);

	return Plugin_Continue;
}

stock bool IsValidClient(int client)
{
	if (client <= 0 || 
	client > MaxClients || 
	!IsClientConnected(client) ||
	!IsClientInGame(client)) return false;
	return true; 
}