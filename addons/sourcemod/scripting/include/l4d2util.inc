#if defined l4d2util_inc_
	#endinput
#endif
#define l4d2util_inc_

#pragma semicolon 1

#include <l4d2util_constants>
#include <l4d2util_infected>
#include <l4d2util_rounds>
#include <l4d2util_survivors>
#include <l4d2util_tanks>
#include <l4d2util_weapons>

#if !defined L4D2UTIL_STOCKS_ONLY
#if !defined __IN_L4D2UTIL__

public SharedPlugin __pl_l4d2util =
{
	name = "l4d2util",
	file = "l4d2util.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

public void __pl_l4d2util_SetNTVOptional()
{
	// Stub
}

#endif // __IN_L4D2UTIL__
#endif // L4D2UTIL_STOCKS_ONLY
