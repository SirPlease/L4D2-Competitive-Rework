/*
*	https://github.com/LuxLuma/Left-4-fix
*/

#if defined _l4d2_changelevel_included
#endinput
#endif
#define _l4d2_changelevel_included

/**
*	Changes level using SDKCall on info_Changelevel.
*	@param	sMapName	Map String without .bsp
*	@return	true Was able to change map, false otherwise.
*/
native void L4D2_ChangeLevel(const char[] sMapName);

public SharedPlugin __pl_l4d2_changelevel = 
{
	name = "l4d2_changelevel",
	file = "l4d2_changelevel.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_l4d2_changelevel_SetNTVOptional()
{
	MarkNativeAsOptional("L4D2_ChangeLevel");
}
#endif