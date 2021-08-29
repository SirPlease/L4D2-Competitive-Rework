#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <colors>

public Plugin myinfo =
{
	name = "8Ball",
	description = "Simple 8Ball Game Plugin. Works the same as Coinflip / Dice Roll.",
	author = "spoon",
	version = "1.3",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_8ball", Command_8ball);
}

public Action Command_8ball(int iClient, int iArgs)
{
	if (iArgs == 0) {
		CPrintToChat(iClient, "{default}[{green}8Ball{default}] Usage: !8ball <question>");
		return Plugin_Handled;
	}
	
	char sQuestion[192];
	GetCmdArgString(sQuestion, sizeof(sQuestion));
	StripQuotes(sQuestion);
	
	PrintToChatAll("\x01[\x048Ball\x01] \x03%N\x01 Asked: \x05%s\x01", iClient, sQuestion);
	
	int iResult = GetURandomInt() % 6;
	switch(iResult) {
		case 0: {
			CPrintToChatAll("{default}[{green}8Ball{default}] I'm going with {olive}Yes{default}!");
		}
		case 1: {
			CPrintToChatAll("{default}[{green}8Ball{default}] I'm going with a {red}No{default}!");
		}
		case 2: {
			CPrintToChatAll("{default}[{green}8Ball{default}] Yikes. {red}No{default}!");
		}
		case 3: {
			CPrintToChatAll("{default}[{green}8Ball{default}] Uhhhhh... {olive}Sure{default}?");
		}
		case 4: {
			CPrintToChatAll("{default}[{green}8Ball{default}] LOL {red}Absolutely Not{default}!");
		}
		case 5: {
			CPrintToChatAll("{default}[{green}8Ball{default}] You know what? {olive}Yeah{default}!");
		}
	}
	
	return Plugin_Handled;
}