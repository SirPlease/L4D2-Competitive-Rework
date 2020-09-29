#include <sourcemod> 
#include <colors>  

new result_int;
new String:client_name[32];
public Plugin:myinfo =
{
	name = "8Ball",
	description = "Simple 8Ball Game Plugin. Works the same as Coinflip / Dice Roll.",
	author = "spoon",
	version = "1.2.7",
	url = "http://www.sourcemod.net/"
};


public OnPluginStart()
{
	RegConsoleCmd("sm_8ball", Command_8ball, "", 0);
}

stock Action:Command_8ball(client, args)
{		
	if (args == 0)
	{
		CPrintToChat(client, "{default}[{green}8Ball{default}] Usage: !8ball <question>");
		return;
	}
	else 
	{
		decl String:question[192];
						
		result_int = GetURandomInt() % 6;
	
		GetClientName(client, client_name, 32);	
		
		GetCmdArgString(question, sizeof(question));
		StripQuotes(question);
		
		PrintToChatAll("\x01[\x048Ball\x01] \x03%s\x01 Asked: \x05%s\x01", client_name, question[0]);
	
		switch(result_int){
		case 0: CPrintToChatAll("{default}[{green}8Ball{default}] I'm going with {olive}Yes{default}!");
		case 1: CPrintToChatAll("{default}[{green}8Ball{default}] I'm going with a {red}No{default}!");
		case 2: CPrintToChatAll("{default}[{green}8Ball{default}] Yikes. {red}No{default}!");
		case 3: CPrintToChatAll("{default}[{green}8Ball{default}] Uhhhhh... {olive}Sure{default}?");
		case 4: CPrintToChatAll("{default}[{green}8Ball{default}] LOL {red}Absolutely Not{default}!");
		case 5: CPrintToChatAll("{default}[{green}8Ball{default}] You know what? {olive}Yeah{default}!");
		}			
	}
}