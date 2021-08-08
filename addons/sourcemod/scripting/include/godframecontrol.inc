#if defined _godframecontrol_included_
	#endinput
#endif
#define _godframecontrol_included_

/**
 * Gives a specified client god frames for x amount of time
 *
 * @param client   	The client to give godframes to.
 * @param time   	Amount of times the godframes will last.
 * @param time   	The ZClass of the attacker.
 * @return          True if successful, false otherwise.
 */
native void GiveClientGodFrames(int client, float time, int zclass);

public SharedPlugin __pl_godframecontrol =
{
	name = "l4d2_godframes_control_merge",
	file = "l4d2_godframes_control_merge.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_godframecontrol_SetNTVOptional()
{
	MarkNativeAsOptional("GiveClientGodFrames");
}
#endif
