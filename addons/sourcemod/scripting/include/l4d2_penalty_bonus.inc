/*
  Includes for Penalty bonus system (l4d2_penalty_bonus)
  ------------------------------------------------------
*/

/**
 *  Called when a round is about to end. 
 *  The update value is passed by reference and increased by any plugin using this forward
 *  before the next. Do an update += <update value> and return the new update.
 *  PBonus will apply the last value of that update to the round's penalty bonus (without reporting).
 *
 *  @param  int     update              (by reference) the value of the cumulative update PBonus needs to know
 *  @return int     the update value to add to the round's bonus
 */
forward OnHoldOutBonusSet( &update );


// Get the bonus for the current round
//    returns int
native PBONUS_GetRoundBonus();

// Resets the bonus for the current round to 0 (does not do a change-report!)
native PBONUS_ResetRoundBonus();

// Set the bonus for the current round
native PBONUS_SetRoundBonus(bonus);

// Adds points to the bonus for the current round
native PBONUS_AddRoundBonus(bonus, bool:bNoReport=false);

// Get the amount of defibs used in the current round
//    returns int
native PBONUS_GetDefibsUsed();

// Set the (current) defib penalty
native PBONUS_SetDefibPenalty(penalty);
