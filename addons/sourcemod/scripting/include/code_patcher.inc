#pragma semicolon 1

#if defined codepatcher_inc_
	#endinput
#endif
#define codepatcher_inc_

native bool:IsPatchApplied(const String:name[]);

native Address:GetPatchAddress(const String:name[]);

native bool:IsPlatformWindows();

forward OnPatchApplied(const String:name[]);

public SharedPlugin:__pl_l4d2util =
{
	name = "code_patcher",
	file = "code_patcher.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

public __pl_lgofnoc_SetNTVOptional()
{
	MarkNativeAsOptional("IsPatchApplied");
	MarkNativeAsOptional("GetPatchAddress");
	MarkNativeAsOptional("IsPlatformWindows");
}
