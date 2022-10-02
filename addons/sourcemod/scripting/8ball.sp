#pragma semicolon 1
#pragma newdecls required

#include <colors>
#include <sourcemod>

public Plugin myinfo =
{
	name        = "8Ball",
	description = "Simple 8Ball Game Plugin. Works the same as Coinflip / Dice Roll.",
	author      = "spoon",
	version     = "1.3",
	url         = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	LoadTranslations("8ball.phrases");
	RegConsoleCmd("sm_8ball", Command_8ball);
}

public Action Command_8ball(int iClient, int iArgs)
{
	if (iArgs == 0)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "Usage");
		return Plugin_Handled;
	}

	char sQuestion[192];
	GetCmdArgString(sQuestion, sizeof(sQuestion));
	StripQuotes(sQuestion);

	CPrintToChatAll("%t %t", "Tag", "Asked", iClient, sQuestion);

	int iResult = GetURandomInt() % 6;
	switch (iResult)
	{
		case 0:
		{
			CPrintToChatAll("%t %t", "Tag", "WithYes");
		}
		case 1:
		{
			CPrintToChatAll("%t %t", "Tag", "WithNo");
		}
		case 2:
		{
			CPrintToChatAll("%t %t", "Tag", "Yikes");
		}
		case 3:
		{
			CPrintToChatAll("%t %t", "Tag", "Sure");
		}
		case 4:
		{
			CPrintToChatAll("%t %t", "Tag", "AbsolutelyNot");
		}
		case 5:
		{
			CPrintToChatAll("%t %t", "Tag", "Yeah");
		}
	}

	return Plugin_Handled;
}