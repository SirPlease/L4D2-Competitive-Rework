#if defined _kento_rankme_included
	#endinput
#endif
#define _kento_rankme_included

public SharedPlugin __pl_kento_rankme =
{
	name = "rankme",
	file = "rankme.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_kento_rankme_SetNTVOptional()
{
	MarkNativeAsOptional("RankMe_GetPoints");
	MarkNativeAsOptional("RankMe_GetRank");
}
#endif

native int RankMe_GetPoints(int client);
native void RankMe_GetRank(int client, Function callback, any data = 0);
