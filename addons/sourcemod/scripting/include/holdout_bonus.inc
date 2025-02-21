#if defined _holdoutbonus_included_
	#endinput
#endif
#define _holdoutbonus_included_

/**
 *  Called when a holdout bonus is set up for the round. This will be
 *  called once for each versus roundhalf, when the round goes live (or
 *  survivors leave saferoom).
 *
 *  @param  int     bonus               the amount of points in the total bonus
 *  @param  int     distance            the (new) distance for the map
 *  @param  int     time                the time duration of the event in seconds
 *  @param  bool    distanceChanged     whether the distance has been altered by holdout_bonus
 */
forward void OnHoldOutBonusSet(int bonus, int distance, int time, bool distanceChanged);

/**
 *  Called whenever a holdout bonus event starts.
 *
 *  @param  int     time                the total time duration of the event in seconds
 */
forward void OnHoldOutBonusStart(int time);

/**
 *  Called whenever a holdout bonus event ends. This can be either due to the
 *  survivors surviving the event, or by them wiping during it.
 *
 *  @param  int     bonus               the actual bonus awarded to the survivors
 *  @param  int     time                the time the survivors managed to survive
 */
forward void OnHoldOutBonusEnd(int bonus, int time);

public SharedPlugin __pl_holdoutbonus =
{
	name = "holdout_bonus",
	file = "holdout_bonus.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};
