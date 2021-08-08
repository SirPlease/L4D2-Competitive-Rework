#if defined _l4d2_health_temp_bonus_included
	#endinput
#endif
#define _l4d2_health_temp_bonus_included

native int SMNext_GetPermBonus();
native int SMNext_GetTempBonus();
native int SMNext_GetPillsBonus();
native int SMNext_GetMaxPermBonus();
native int SMNext_GetMaxTempBonus();
native int SMNext_GetMaxPillsBonus();

public SharedPlugin __pl_l4d2_health_temp_bonus =
{
	name = "l4d2_health_temp_bonus",
	file = "l4d2_health_temp_bonus.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_l4d2_health_temp_bonus_SetNTVOptional()
{
	MarkNativeAsOptional("SMNext_GetPermBonus");
	MarkNativeAsOptional("SMNext_GetTempBonus");
	MarkNativeAsOptional("SMNext_GetPillsBonus");
	MarkNativeAsOptional("SMNext_GetMaxPermBonus");
	MarkNativeAsOptional("SMNext_GetMaxTempBonus");
	MarkNativeAsOptional("SMNext_GetMaxPillsBonus");
}
#endif
