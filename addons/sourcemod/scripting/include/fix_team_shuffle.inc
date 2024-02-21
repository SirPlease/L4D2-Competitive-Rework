#if defined _fix_team_shuffle_included
 #endinput
#endif
#define _fix_team_shuffle_included


/**
 * 返回现在是否正在运行防错位
 */
native bool isFixTeamShuffleRunning();


public SharedPlugin __pl_fix_team_shuffle = 
{
	name = "fix_team_shuffle",
	file = "l4d2_fix_team_shuffle.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_exp_interface_SetNTVOptional()
{
	MarkNativeAsOptional("isFixTeamShuffleRunning");
}
#endif