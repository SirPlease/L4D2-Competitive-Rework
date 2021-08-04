#if defined _l4d2_hybrid_scoremod
	#endinput
#endif
#define _l4d2_hybrid_scoremod

native int SMPlus_GetHealthBonus();
native int SMPlus_GetDamageBonus();
native int SMPlus_GetPillsBonus();
native int SMPlus_GetMaxHealthBonus();
native int SMPlus_GetMaxDamageBonus();
native int SMPlus_GetMaxPillsBonus();

public SharedPlugin __pl_l4d2_hybrid_scoremod =
{
	name = "l4d2_hybrid_scoremod",
	file = "l4d2_hybrid_scoremod.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_l4d2_hybrid_scoremod_SetNTVOptional()
{
	MarkNativeAsOptional("SMPlus_GetHealthBonus");
	MarkNativeAsOptional("SMPlus_GetDamageBonus");
	MarkNativeAsOptional("SMPlus_GetPillsBonus");
	MarkNativeAsOptional("SMPlus_GetMaxHealthBonus");
	MarkNativeAsOptional("SMPlus_GetMaxDamageBonus");
	MarkNativeAsOptional("SMPlus_GetMaxPillsBonus");
}
#endif
