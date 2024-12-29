/*
Includes for Penalty bonus system (l4d2_penalty_bonus)
------------------------------------------------------
*/

#if defined  _l4d2_penalty_bonus_included_
#endinput
#endif
#define _l4d2_penalty_bonus_included_

/**
 *  Called when a round is about to end. 
 *  The update value is passed by reference and increased by any plugin using this forward
 *  before the next. Do an update += <update value> and return the new update.
 *  PBonus will apply the last value of that update to the round's penalty bonus (without reporting).
 *
 *  @param  int     update              (by reference) the value of the cumulative update PBonus needs to know
 *  @return int     the update value to add to the round's bonus
 */
forward int PBONUS_RequestFinalUpdate( int &update );


// Get the bonus for the current round
//    returns int
native int PBONUS_GetRoundBonus();

// Resets the bonus for the current round to 0 (does not do a change-report!)
native void PBONUS_ResetRoundBonus();

// Set the bonus for the current round
native void PBONUS_SetRoundBonus(int bonus);

// Adds points to the bonus for the current round
native void PBONUS_AddRoundBonus(int bonus, bool bNoReport=false);

// Get the amount of defibs used in the current round
//    returns int
native int PBONUS_GetDefibsUsed();

// Set the (current) defib penalty
native void PBONUS_SetDefibPenalty(penalty);

public SharedPlugin __pl_l4d2_penalty_bonus =
{
    name = "penaltybonus",
    file = "l4d2_penalty_bonus.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_l4d2_penalty_bonus_SetNTVOptional()
{
    MarkNativeAsOptional("PBONUS_GetRoundBonus");
    MarkNativeAsOptional("PBONUS_ResetRoundBonus");
    MarkNativeAsOptional("PBONUS_SetRoundBonus");
    MarkNativeAsOptional("PBONUS_AddRoundBonus");
    MarkNativeAsOptional("PBONUS_GetDefibsUsed");
    MarkNativeAsOptional("PBONUS_SetDefibPenalty");
}
#endif
