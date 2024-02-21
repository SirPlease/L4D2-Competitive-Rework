#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#undef REQUIRE_PLUGIN
#include <CreateSurvivorBot>

#define PLUGIN_VERSION 				"1.0"

public Plugin myinfo = 
{
	name 			= "[L4D2] CreateSurvivorBot Test",
	author 			= "MicroLeo (port by Dragokas)",
	description 	= "Test CreateSurvivorBot Native",
	version 		= PLUGIN_VERSION,
	url 			= "https://github.com/dragokas"
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_newbot", CmdAddBot, "test CreateSurvivorBot function");
}

public Action CmdAddBot(int client, int args)
{
	if( GetFeatureStatus(FeatureType_Native, "NextBotCreatePlayerBotSurvivorBot") != FeatureStatus_Available )
	{
		ReplyToCommand(client, "Cannot find required native!");
		return Plugin_Handled;
	}
	
	int bot = CreateSurvivorBot();
	if( IsValidEdict(bot) )
	{
		ReplyToCommand(client, "Created SurvivorBot: %d", bot);
	}
	return Plugin_Handled;
}