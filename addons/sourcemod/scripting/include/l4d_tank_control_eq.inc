#if defined _l4d_tank_control_eq_included
	#endinput
#endif
#define _l4d_tank_control_eq_included

native int GetTankSelection();

/**
* @brief Gets an array of steam IDs of players who have had tank.
*
* @return            ArrayList containing steam IDs, must be freed by caller.
*/
native ArrayList GetWhosHadTank();

/**
* @brief Gets an array of steam IDs of players who have not had tank.
*
* @return            ArrayList containing steam IDs, must be freed by caller.
*/
native ArrayList GetWhosNotHadTank();

/**
* @brief Clears the list of players who have had tank.
*
* @return            True if successful, false otherwise.
*/
native bool ClearWhosHadTank();

/**
* @brief Gets the current tank pool.
*
* @return            ArrayList containing steam IDs of players in tank pool, must be freed by caller.
*/
native ArrayList GetTankPool();

/**
* @brief Sets the tank to a specific player
* 
* @param steamId    Steam ID of the player to set as tank
* @return          True if successful, false otherwise
*/
native bool SetTank(const char[] steamId);

/**
* @brief Gets the current tank queue
*
* @return            ArrayList containing steam IDs in queue order, must be freed by caller.
*/
native ArrayList GetTankQueue();

/**
* @brief Adds a player to the tank queue at specified position
* 
* @param steamId    Steam ID of the player to add
* @param position   Position in queue (0 = end, 1 = first, etc)
* @return          True if successful, false if player already in queue
*/
native bool AddToTankQueue(const char[] steamId, int position = 0);

/**
* @brief Removes a player from the tank queue
* 
* @param steamId    Steam ID of the player to remove
* @return          True if successful, false if player not in queue
*/
native bool RemoveFromTankQueue(const char[] steamId);

/**
* @brief Called when plugin tries to offer tank to a bot
* 
* @param sQueuedTank    Steam ID of queued tank
*/
forward void TankControl_OnTryOfferingTankBot(char sQueuedTank[64]);

/**
* @brief Called when a tank is selected
* 
* @param sQueuedTank    Steam ID of selected tank
*/
forward void TankControl_OnTankSelection(char sQueuedTank[64]);

/**
* @brief Called when tank control is reset
*/
forward void OnTankControlReset();

/**
* @brief Called when choosing tank
* 
* @return Plugin_Handled to override tank selection, Plugin_Continue to allow default behavior
*/
forward Action OnChooseTank();

/**
* @brief Called when tank is given to a player
* 
* @param steamId    Steam ID of the player who received tank
*/
forward void OnTankGiven(const char[] steamId);

/**
* @brief Called when the tank queue is modified
*/
forward void OnTankQueueChanged();

public SharedPlugin __pl_l4d_tank_control_eq =
{
	name = "l4d_tank_control_eq",
	file = "l4d_tank_control_eq.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_l4d_tank_control_eq_SetNTVOptional()
{
	MarkNativeAsOptional("GetTankSelection");
	MarkNativeAsOptional("GetWhosHadTank");
	MarkNativeAsOptional("GetWhosNotHadTank");
	MarkNativeAsOptional("GetTankQueue");
	MarkNativeAsOptional("ClearWhosHadTank");
	MarkNativeAsOptional("AddToTankQueue");
	MarkNativeAsOptional("RemoveFromTankQueue");
	MarkNativeAsOptional("GetTankPool");
	MarkNativeAsOptional("SetTank");
}
#endif