#if defined _l4d_tank_control_eq_included
	#endinput
#endif
#define _l4d_tank_control_eq_included

/**
 * @brief Retrieves the selected tank's client index.
 *
 * @return			Client id of the selected tank, -1 if no one is selected.
 */
native int GetTankSelection();

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
}
#endif
