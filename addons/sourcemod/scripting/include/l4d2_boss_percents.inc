/*
** https://github.com/spoon-l4d2/Plugins
*/

#if defined _l4d2_boss_percents_included
 #endinput
#endif
#define _l4d2_boss_percents_included

/**
 * @brief Called when the boss percents are updated.
 * @remarks Triggered via boss votes, force tanks, force witches.
 */
forward void OnUpdateBosses();



/**
 * @brief Set the tank as "disabled" on the ready up, and when the !boss command is used.
 * @remarks YOU NEED TO SET THIS EVERY MAP.
 *
 * @param disable			Boolean to set
 *
 * @noreturn
 */
native void SetTankDisabled(bool disable);

/**
 * @brief Set the witch as "disabled" on the ready up, and when the !boss command is used.
 * @remarks YOU NEED TO SET THIS EVERY MAP.
 *
 * @param disable			Boolean to set
 *
 * @noreturn
 */
native void SetWitchDisabled(bool disable);

/**
 * @brief Update the boss percentages.
 *
 * @noreturn
 */
native void UpdateBossPercents();

/**
 * @brief Check if the current map contains a static witch spawn.
 *
 * @return					True on contains a static spawn, false otherwise.
 */
native bool IsStaticWitchMap();

/**
 * @brief Check if the current map contains a static tank spawn.
 *
 * @return					True on contains a static spawn, false otherwise.
 */
native bool IsStaticTankMap();

/**
 * @brief Get the stored tank percent.
 *
 * @return					Integer of the percentage, 0 if spawn disabled or spawn static, -1 if unsupported game.
 */
native int GetStoredTankPercent();

/**
 * @brief Get the stored witch percent.
 *
 * @return					Integer of the percentage, 0 if spawn disabled or spawn static, -1 if unsupported game.
 */
native int GetStoredWitchPercent();

/**
 * @brief Get the ready footer index of the boss percents.
 * @remarks Safe to use no matter readyup is available or not.
 *
 * @return					Index of the ready up footer, -1 if readyup is not available.
 */
native int GetReadyUpFooterIndex();

/**
 * @brief Refresh the boss percents on the ready up.
 * @remarks All hooks are removed on map change.
 *
 * @return					True on success, false if readyup is not available.
 */
native bool RefreshBossPercentReadyUp();

/**
 * @brief Check if the current map is Dark Carnival: Remix.
 * @remarks Dark Carnival: Remix uses built-in custom boss system, which is not the usual way that the game performs.
 *
 * @return					True if current map is Dark Carnival: Remix, false otherwise.
 */
native bool IsDarkCarniRemix();


public SharedPlugin __pl_l4d2_boss_percents = 
{
	name = "l4d_boss_percent",
	file = "l4d_boss_percent.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_l4d2_boss_percents_SetNTVOptional()
{
	MarkNativeAsOptional("SetTankDisabled");
	MarkNativeAsOptional("SetWitchDisabled");
	MarkNativeAsOptional("UpdateBossPercents");
	MarkNativeAsOptional("IsStaticWitchMap");
	MarkNativeAsOptional("IsStaticTankMap");
	MarkNativeAsOptional("GetStoredTankPercent");
	MarkNativeAsOptional("GetStoredWitchPercent");
	MarkNativeAsOptional("GetReadyUpFooterIndex");
	MarkNativeAsOptional("RefreshBossPercentReadyUp");
	MarkNativeAsOptional("IsDarkCarniRemix");
}
#endif
