#if defined _caster_system_included
 #endinput
#endif
#define _caster_system_included

/**
 * If this in-game and fully connected client is a caster or not
 *
 * @return          True if this is a registered caster
 */
native bool IsClientCaster(int client);

/**
 * If this Steam ID is a registered caster or not
 *
 * @param           String containing the user's auth id
 * @return          True if this is a registered caster
 */
native bool IsIDCaster(const char[] AuthID);

public SharedPlugin __pl_caster_system =
{
	name = "caster_system",
	file = "caster_system.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_caster_system_SetNTVOptional()
{
	MarkNativeAsOptional("IsClientCaster");
	MarkNativeAsOptional("IsIDCaster");
}
#endif