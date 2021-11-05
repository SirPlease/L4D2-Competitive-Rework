#if defined l4d2util_rounds_inc_
	#endinput
#endif
#define l4d2util_rounds_inc_

#include <sdktools_gamerules>

/**
 * Is the second round of this map currently being played?
 *
 * @return bool
 */
stock bool InSecondHalfOfRound()
{
	return view_as<bool>(GameRules_GetProp("m_bInSecondHalfOfRound"));
}
