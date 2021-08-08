#if defined _lerpmonitor
	#endinput
#endif
#define _lerpmonitor

 /**
 * @brief				Get the player's saved lerp value
 * @param	client		Client index
 *
 * @return				-1.0 if the current lerp time has not been saved, otherwise current lerp value
 * @error				If the client is not connected or the index is invalid.
 */
native float LM_GetLerpTime(int client);

 /**
 * @brief				Get the player's current lerp
 * @param	client		Client index
 *
 * @return				Current lerp value
 * @error				Invalid client index, or client not connected.
 */
native float LM_GetCurrentLerpTime(int client);

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
	MarkNativeAsOptional("NM_GetLerpTime");
	MarkNativeAsOptional("LM_GetCurrentLerpTime");
}
#endif
