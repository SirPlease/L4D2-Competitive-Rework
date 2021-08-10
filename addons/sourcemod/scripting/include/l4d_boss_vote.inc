#if defined _l4d_boss_vote_included
 #endinput
#endif
#define _l4d_boss_vote_included

/**
 * @brief Called when the boss percents are updated.
 * @remarks Triggered via boss votes, force tanks, force witches.
 * @remarks Special value: -1 indicates ignored in change, 0 disabled (no spawn).
 */
forward void OnUpdateBosses(int iTankFlow, int iWitchFlow);

public SharedPlugin __pl_l4d_boss_vote = 
{
	name = "l4d_boss_vote",
	file = "l4d_boss_vote.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};