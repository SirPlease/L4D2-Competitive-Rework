#if defined codepatcher_inc_
	#endinput
#endif
#define codepatcher_inc_

native bool IsPatchApplied(const char[] name);

native Address GetPatchAddress(const char[] name);

native bool IsPlatformWindows();

forward void OnPatchApplied(const char[] name);

public SharedPlugin __pl_code_patcher =
{
	name = "code_patcher",
	file = "code_patcher.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

public void __pl_code_patcher_SetNTVOptional()
{
	MarkNativeAsOptional("IsPatchApplied");
	MarkNativeAsOptional("GetPatchAddress");
	MarkNativeAsOptional("IsPlatformWindows");
}
