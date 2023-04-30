#if defined _ripext_included_
	#endinput
#endif
#define _ripext_included_

#include <ripext/json>
#include <ripext/http>

/**
 * Do not edit below this line!
 */
public Extension __ext_rip =
{
	name = "REST in Pawn",
	file = "rip.ext",
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
