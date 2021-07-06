#if defined l4d2util_rounds_inc_
	#endinput
#endif
#define l4d2util_rounds_inc_

#include <sdktools>

#if !defined L4D2UTIL_STOCKS_ONLY
#if !defined __IN_L4D2UTIL__

/**
 * Called when a new round begins.
 *
 * @noreturn
 */ 
forward void OnRoundStart();

/**
 * Called when a round ends.
 *
 * @noreturn
 */
forward void OnRoundEnd();

#endif // __IN_L4D2UTIL__
#endif // L4D2UTIL_STOCKS_ONLY


/**
 * Is the second round of this map currently being played?
 *
 * @return bool
 */
stock bool InSecondHalfOfRound()
{
	return view_as<bool>(GameRules_GetProp("m_bInSecondHalfOfRound"));
}
