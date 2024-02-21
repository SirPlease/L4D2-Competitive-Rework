#if defined _cccm_included
  #endinput
#endif
#define _cccm_included

/**
 * Checks if client tag is hidden
 *
 * @param client		Client index
 * @return				True if hidden, else false
 */
native bool CCCM_IsTagHidden(int client);

public SharedPlugin __pl_cccm = {
	name = "cccm",
	file = "custom-chatcolors-menu.smx",
#if defined REQUIRE_PLUGIN
	required = 1
#else
	required = 0
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_cccm_SetNTVOptional() {
	MarkNativeAsOptional("CCCM_IsTagHidden");
}
#endif