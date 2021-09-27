#if defined _l4d2_hittable_control_included
 #endinput
#endif
#define _l4d2_hittable_control_included

/**
 * @brief Returns if forklifts are set to be unbreakable
 *
 * @return					True on forklifts set to not break, false otherwise.
 */
native bool AreForkliftsUnbreakable();

public SharedPlugin __pl_l4d2_hittable_control =
{
	name = "l4d2_hittable_control",
	file = "l4d2_hittable_control.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_l4d2_hittable_control_SetNTVOptional()
{
	MarkNativeAsOptional("AreForkliftsUnbreakable");
}
#endif