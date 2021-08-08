#if defined _l4d2_scoremod_included
	#endinput
#endif
#define _l4d2_scoremod_included

native int HealthBonus();

public SharedPlugin __pl_l4d2_scoremod =
{
	name = "l4d2_scoremod",
	file = "l4d2_scoremod.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_l4d2_scoremod_SetNTVOptional()
{
	MarkNativeAsOptional("HealthBonus");
}
#endif
