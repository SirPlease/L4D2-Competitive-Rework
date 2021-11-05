#if defined l4d2util_tanks_inc_
	#endinput
#endif
#define l4d2util_tanks_inc_

#include <l4d2util_constants>

/**
 * Is the player the tank? 
 *
 * @param client client ID
 * @return bool
 */
stock bool IsTank(int client)
{
	return (IsClientInGame(client)
		&& GetClientTeam(client) == L4D2Team_Infected
		&& GetEntProp(client, Prop_Send, "m_zombieClass") == L4D2Infected_Tank);
}

stock bool IsValidTank(int client)
{
	return (IsValidClientIndex(client) && IsTank(client));
}

/**
 * Is the tank able to punch the entity with the tank for instant incaps? 
 *
 * @param iEntity entity ID
 * @return bool
 */
stock bool IsTankHittable(int iEntity)
{
	if (!IsValidEntity(iEntity)) {
		return false;
	}

	char className[64];
	GetEdictClassname(iEntity, className, sizeof(className));
	
	if (strcmp(className, "prop_physics") == 0) {
		if (GetEntProp(iEntity, Prop_Send, "m_hasTankGlow", 1)) {
			return true;
		}
	} else if (strcmp(className, "prop_car_alarm") == 0) {
		return true;
	}

	return false;
}

/**
 * Tanks frustation level in the range 0-100, where 100 is when the rage meter
 * is full.
 *
 * @param iTankClient tank's client ID
 * @return frustration level
 */
stock int GetTankFrustration(int iTankClient)
{
	int iFrustration = 100 - GetEntProp(iTankClient, Prop_Send, "m_frustration");

	return iFrustration;
}

/**
 * Sets the tank's frustration level.
 *
 * @param iTankClient tank's client ID
 * @param iFrustration frustration level (0-100)
 * @noreturn
 */
stock void SetTankFrustration(int iTankClient, int iFrustration)
{
	if (iFrustration < 0 || iFrustration > 100) {
		ThrowError("Native SetTankFrustration. Invalid parameter passed: %d", iFrustration);
	}
	
	int iSetFrustration = 100 - iFrustration;
	SetEntProp(iTankClient, Prop_Send, "m_frustration", iSetFrustration);
}

/**
 * Returns true if the entity or player is on fire.
 *
 * @param entity entity index
 * @return bool
 */
stock bool IsEntityOnFire(int entity)
{
	return ((GetEntityFlags(entity) & FL_ONFIRE) != 0);
}

/**
 * Searches for a player who is in control of a tank.
 *
 * @param iTankClient client index to begin searching from
 * @return client ID or -1 if not found
 */
stock int FindTankClient(int iTankClient)
{
	int i = (iTankClient < 0) ? 1 : iTankClient + 1;
	
	for (; i <= MaxClients; i++) {
		if (IsTank(i)) {
			return i;
		}
	}

	return -1;
}

/**
 * Searches for a live player who is in control of a tank.
 *
 * @param iTankClient client index to begin searching from
 * @return client ID or -1 if not found
 */
stock int FindAliveTankClient()
{
	for (int i = 1; i <= MaxClients; i++) {
		if (IsTank(i) && IsPlayerAlive(i)) {
			return i;
		}
	}

	return -1;
}

/**
 * Is there a tank currently in play?
 *
 * @return bool
 */
stock bool IsTankInPlay()
{
	return (FindTankClient(-1) != -1);
}

/**
 * Counts the number of tanks currently in play.
 *
 * @return number of tanks in play
 */
stock int NumTanksInPlay()
{
	int count = 0;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsTank(i)) {
			count++;
		}
	}
	
	return count;
}
