#pragma semicolon 1

#include <sourcemod>
#include <colors>

public Plugin:myinfo =
{
	name = "L4D2 Change Log Command",
	description = "Does things :)",
	author = "Spoon",
	version = "3.0.5",
	url = "https://github.com/spoon-l4d2/"
};

new Handle:linkCVar;

public OnPluginStart()
{
	linkCVar = CreateConVar("l4d2_cl_link", "https://github.com/spoon-l4d2/NextMod", "The to your change log");
	RegConsoleCmd("sm_changelog", ChangeLog_CMD);
}

public Action:ChangeLog_CMD(client, args)
{
	new String:link[128];
	GetConVarString(linkCVar, link, sizeof(link));
	CPrintToChat(client, "{blue}[{green}ChangeLog{blue}]{default} You can view the change log @ {blue}%s", link);
}