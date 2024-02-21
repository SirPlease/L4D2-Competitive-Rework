#if defined _CreateSurvivorBot_included
 #endinput
#endif
#define _CreateSurvivorBot_included

native int NextBotCreatePlayerBotSurvivorBot(const char[] _szName = NULL_STRING);

native bool CTerrorPlayerRoundRespawn(int _iClientIndex);

stock int CreateSurvivorBot()
{
	int bot = NextBotCreatePlayerBotSurvivorBot(NULL_STRING);
	if( IsValidEntity(bot) )
	{
		ChangeClientTeam(bot, 2);
		
		if( !IsPlayerAlive(bot) )
		{
			CTerrorPlayerRoundRespawn(bot);
		}
		return bot;
	}
	return -1;
}

public SharedPlugin __pl_shope =
{
	name = "CreateSurvivorBot",
	file = "CreateSurvivorBot.smx",
	#if defined REQUIRE_PLUGIN
	required = 1
	#else
	required = 0
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_CreateSurvivorBot_SetNTVOptional()
{
	MarkNativeAsOptional("NextBotCreatePlayerBotSurvivorBot");
	MarkNativeAsOptional("CTerrorPlayerRoundRespawn");
}
#endif