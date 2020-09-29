#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

new Handle:hCvarMotdTitle;
new Handle:hCvarMotdUrl;

public Plugin:myinfo =
{
	name = "Config Description",
	author = "Visor",
	description = "Displays a descriptive MOTD on desire",
	version = "0.2",
	url = "https://github.com/Attano/smplugins"
};

public OnPluginStart()
{
    hCvarMotdTitle = CreateConVar("sm_cfgmotd_title", "ZoneMod", "Custom MOTD title");
    hCvarMotdUrl = CreateConVar("sm_cfgmotd_url", "https://github.com/SirPlease/ZoneMod/blob/master/README.md", "Custom MOTD url");

    RegConsoleCmd("sm_changelog", ShowMOTD, "Show a MOTD describing the current config");
    RegConsoleCmd("sm_cfg", ShowMOTD, "Show a MOTD describing the current config");
}

public Action:ShowMOTD(client, args) 
{
    decl String:title[64], String:url[192];
    
    GetConVarString(hCvarMotdTitle, title, sizeof(title));
    GetConVarString(hCvarMotdUrl, url, sizeof(url));
    
    ShowMOTDPanel(client, title, url, MOTDPANEL_TYPE_URL);
}