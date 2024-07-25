#if defined _specrates_included
 #endinput
#endif
#define _specrates_included

enum StatusRates
{
	RatesLimit = 0,
	RatesFree  = 1,
}

/**
 * Sets the status rates for a specific client.
 *
 * @param client The client index.
 * @param Status The status rates to set.
 */
native void SetStatusRates(int client, StatusRates Status);

/**
 * Retrieves the status rates for a given client.
 *
 * @param client The client index.
 * @return The StatusRates structure containing the status rates.
 */
native StatusRates GetStatusRates(int client);

public SharedPlugin __pl_specrates =
{
	name = "specrates",
	file = "specrates.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_specrates_SetNTVOptional()
{
	MarkNativeAsOptional("SetStatusRates");
	MarkNativeAsOptional("GetStatusRates");
}
#endif