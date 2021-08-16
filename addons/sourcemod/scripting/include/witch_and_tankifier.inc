#if defined _witch_and_tankifier_included
 #endinput
#endif
#define _witch_and_tankifier_included

/**
 * @brief Check if the current map contains a static witch spawn.
 * @remarks Map string will be converted to lowercase internally.
 *
 * @param	map				Specific map to query, or current map if empty.
 *
 * @return					True on contains a static spawn, false otherwise.
 */
native bool IsStaticWitchMap(const char[] map = "");

/**
 * @brief Check if the current map contains a static tank spawn.
 * @remarks Map string will be converted to lowercase internally.
 *
 * @param	map				Specific map to query, or current map if empty.
 *
 * @return					True on contains a static spawn, false otherwise.
 */
native bool IsStaticTankMap(const char[] map = "");

/**
 * @brief Validate the flow percentage of tank on current map.
 * @remarks Passing 0 is allowed and considered disabling.
 *
 * @param	percent			Flow percentage to check.
 *
 * @return					True on valid, false otherwise.
 */
native bool IsTankPercentValid(int percent);

/**
 * @brief Validate the flow percentage of witch on current map.
 * @remarks Passing 0 is allowed and considered disabling.
 *
 * @param	percent			Flow percentage to check.
 *
 * @return					True on valid, false otherwise.
 */
native bool IsWitchPercentValid(int percent);

/**
 * @brief Set the flow percentage of tank on current map.
 * @remarks Passing 0 is allowed and will disable flow tank.
 *
 * @param	percent			Flow percentage to check.
 *
 * @return					True on success, false otherwise.
 */
native bool SetTankPercent(int percent);

/**
 * @brief Set the flow percentage of witch on current map.
 * @remarks Passing 0 is allowed and will disable flow witch.
 *
 * @param	percent			Flow percentage to check.
 *
 * @return					True on success, false otherwise.
 */
native bool SetWitchPercent(int percent);

public SharedPlugin __pl_witch_and_tankifier =
{
	name = "witch_and_tankifier",
	file = "witch_and_tankifier.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_witch_and_tankifier_SetNTVOptional()
{
	MarkNativeAsOptional("IsStaticWitchMap");
	MarkNativeAsOptional("IsStaticTankMap");
	MarkNativeAsOptional("IsTankPercentValid");
	MarkNativeAsOptional("IsWitchPercentValid");
	MarkNativeAsOptional("SetTankPercent");
	MarkNativeAsOptional("SetWitchPercent");
}
#endif