/*    
		Teamflip

   by purpletreefactory
   Credit for the idea goes to Fig
   This version was made out of convenience
   
 */
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <colors>

enum L4D2Team
{
	L4D2Team_None = 0,
	L4D2Team_Spectator,
	L4D2Team_Survivor,
	L4D2Team_Infected,
	
	L4D2Team_Size //4 size
}

int
	result_int,
	previous_timeC = 0, // Used for teamflip
	current_timeC = 0; // Used for teamflip
char
	client_name[32]; // Used to store the client_name of the player who calls teamflip
ConVar
	delay_time; // Handle for the teamflip_delay cvar
bool
	swaptoIsAvailable;

public Plugin myinfo =
{
	name = "Teamflip",
	author = "purpletreefactory, epilimic",
	description = "coinflip, but for teams!",
	version = "1.0.1.0.1.0.1.0",
	url = "http://www.sourcemod.net/"
}
 
public void OnPluginStart()
{
	LoadTranslation("teamflip.phrases");
	delay_time = CreateConVar("teamflip_delay","-1", "Time delay in seconds between allowed teamflips. Set at -1 if no delay at all is desired.", FCVAR_NONE, true, -1.0);

	RegConsoleCmd("sm_teamflip", Command_teamflip);
	RegConsoleCmd("sm_tf", Command_teamflip);
}

public void OnAllPluginsLoaded()
{
	swaptoIsAvailable = CommandExists("sm_swapto");
}

void LoadTranslation(char[] sTranslation)
{
	char 
		sPath[PLATFORM_MAX_PATH],
		sName[64];

	Format(sName, sizeof(sName), "translations/%s.txt", sTranslation);
	BuildPath(Path_SM, sPath, sizeof(sPath), sName);
	if (!FileExists(sPath))
	{
		SetFailState("Missing translation file %s.txt", sTranslation);
	}
	LoadTranslations(sTranslation);
}

public Action Command_teamflip(int client, int args)
{
	current_timeC = GetTime();
	
	if((current_timeC - previous_timeC) > delay_time.IntValue) // Only perform a teamflip if enough time has passed since the last one. This prevents spamming.
	{
		result_int = GetURandomInt() % 2; // Gets a random integer and checks to see whether it's odd or even
		GetClientName(client, client_name, sizeof(client_name)); // Gets the client_name of the person using the command
		
		if(result_int == 0)
		{
			CPrintToChatAll("%t %t", "Tag", "FlippedSurvivor", client_name); // Here {green} is actually yellow
			if(swaptoIsAvailable && GetClientTeamEx(client) != L4D2Team_Survivor)
			{
				ServerCommand("sm_swapto 2 #%i", GetClientUserId(client));
			}
		}
		else
		{
			CPrintToChatAll("%t %t", "Tag", "FlippedInfected", client_name);
			if(swaptoIsAvailable && GetClientTeamEx(client) != L4D2Team_Infected)
			{
				ServerCommand("sm_swapto 3 #%i", GetClientUserId(client));
			}
		}
		previous_timeC = current_timeC; // Update the previous time
	}
	else
	{
		PrintToConsole(client, "%t", "Wait", delay_time.IntValue);
	}
	
	return Plugin_Handled;
}

stock L4D2Team GetClientTeamEx(int client)
{
	return view_as<L4D2Team>(GetClientTeam(client));
}