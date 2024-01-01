#if defined _playstats_included_
	#endinput
#endif
#define _playstats_included_

native void PLAYSTATS_BroadcastRoundStats();
native void PLAYSTATS_BroadcastGameStats();

public SharedPlugin __pl_l4d2playstats =
{
	name = "l4d2_playstats",
	file = "l4d2_playstats.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_l4d2playstats_SetNTVOptional()
{
	MarkNativeAsOptional("PLAYSTATS_BroadcastRoundStats");
	MarkNativeAsOptional("PLAYSTATS_BroadcastGameStats");
}
#endif
