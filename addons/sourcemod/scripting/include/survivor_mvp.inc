#if defined _survivor_mvp_included_
	#endinput
#endif
#define _survivor_mvp_included_

/**
 * Current round MVP.
 * 
 * @return          Client index.
 */
native int SURVMVP_GetMVP();

/**
 * Damage of client.
 *
 * @param client    Client to check.
 * @return          Damage.
 */
native int SURVMVP_GetMVPDmgCount(int client);

/**
 * SI kills of client.
 *
 * @param client    Client to check.
 * @return          SI Kills.
 */
native int SURVMVP_GetMVPKills(int client);

/**
 * Damage percent of client.
 *
 * @param client    Client to check.
 * @return          Damage.
 */
native float SURVMVP_GetMVPDmgPercent(int client);

/**
 * Current round MVP client (Common)
 * 
 * @return          Client index.
 */
native int SURVMVP_GetMVPCI();

/**
 * Common kills for client.
 *
 * @param client    Client to check.
 * @return          Kills.
 */
native int SURVMVP_GetMVPCIKills(int client);

/**
 * CI percent of client.
 *
 * @param client    Client to check.
 * @return          CI Percent.
 */
native float SURVMVP_GetMVPCIPercent(int client);

public SharedPlugin __pl_l4d2lib =
{
	name = "survivor_mvp",
	file = "survivor_mvp.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_l4d2lib_SetNTVOptional()
{
	MarkNativeAsOptional("SURVMVP_GetMVP");
	MarkNativeAsOptional("SURVMVP_GetMVPDmgCount");
	MarkNativeAsOptional("SURVMVP_GetMVPKills");
	MarkNativeAsOptional("SURVMVP_GetMVPDmgPercent");
	MarkNativeAsOptional("SURVMVP_GetMVPCI");
	MarkNativeAsOptional("SURVMVP_GetMVPCIKills");
	MarkNativeAsOptional("SURVMVP_GetMVPCIPercent");
}
#endif
