#if defined __lerpmonitor_included
	#endinput
#endif
#define __lerpmonitor_included

/**
 * @brief				Get the player's stored lerp time, if the stored value is not found in the array,
 * 						then the current lerp time will be returned.
 * @param client		Client index.
 *
 * @return				The current lerp, if the value was not stored, otherwise the stored value from the array.
 * @error				If the client is not connected or the index is invalid.
**/
native float LM_GetLerpTime(int client);

/**
 * @brief				Get the player's current lerp time.
 * @param client		Client index.
 *
 * @return				Current lerp time.
 * @error				Invalid client index, or client not connected.
**/
native float LM_GetCurrentLerpTime(int client);

/**
 * @brief				Get the player's lerp time stored in the array.
 * @param client		Client index.
 *
 * @return				Return -1.0 if the lerp time has not been saved, otherwise the stored lerp time.
 * @error				Invalid client index, or client not connected.
**/
native float LM_GetStoredLerpTime(int client);

public SharedPlugin __lerpmonitor =
{
	name = "LerpMonitor++",
	file = "lerpmonitor.smx",
#if defined REQUIRE_PLUGIN
	required = 1
#else
	required = 0
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_lerpmonitor_SetNTVOptional()
{
	MarkNativeAsOptional("LM_GetLerpTime");
	MarkNativeAsOptional("LM_GetCurrentLerpTime");
	MarkNativeAsOptional("LM_GetStoredLerpTime");
}
#endif
