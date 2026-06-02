#if defined _materialadmin_included
	#endinput
#endif
#define _materialadmin_included

#define MA_BAN_STEAM 1
#define MA_BAN_IP 2

public SharedPlugin __pl_materialadmin =
{
	name = "materialadmin",
	file = "materialadmin.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_materialadmin_SetNTVOptional()
{
	MarkNativeAsOptional("MABanPlayer");
}
#endif

native void MABanPlayer(int admin, int client, int banType, int minutes, const char[] reason);
