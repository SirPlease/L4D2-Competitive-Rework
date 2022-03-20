#if defined _custom_fakelag_included
#endinput
#endif
#define _custom_fakelag_included

/**
 * @brief Set custom fake latency for the given player.
 *
 * @param client	Client index of the player to lag.
 * @param lagTime Amount of time to lag the packet, in milliseconds.
 */
 native void CFakeLag_SetPlayerLatency(int client, float lagTime);

/**
 * @brief Get custom fake latency amount for the given player.
 *
 * @param client	Client index of the player to check latency for.
 */
 native float CFakeLag_GetPlayerLatency(int client);


public Extension __ext_custom_fakelag =
{
	name = "custom_fakelag",
	file = "custom_fakelag.ext",
#if defined AUTOLOAD_EXTENSIONS
	autoload = 1,
#else
	autoload = 0,
#endif
#if defined REQUIRE_EXTENSIONS
	required = 1,
#else
	required = 0,
#endif
};