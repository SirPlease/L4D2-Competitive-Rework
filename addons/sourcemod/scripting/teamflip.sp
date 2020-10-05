/*    
		Teamflip

   by purpletreefactory
   Credit for the idea goes to Fig
   This version was made out of convenience
   
 */
 
#include <sourcemod>
#include <sdktools>

new result_int;
new String:client_name[32]; // Used to store the client_name of the player who calls teamflip
new previous_timeC = 0; // Used for teamflip
new current_timeC = 0; // Used for teamflip
new Handle:delay_time; // Handle for the teamflip_delay cvar

public Plugin:myinfo =
{
	name = "Teamflip",
	author = "purpletreefactory, epilimic",
	description = "coinflip, but for teams!",
	version = "1.0.1.0.1.0",
	url = "http://www.sourcemod.net/"
}
 
public OnPluginStart()
{
	delay_time = CreateConVar("teamflip_delay","-1", "Time delay in seconds between allowed teamflips. Set at -1 if no delay at all is desired.");

	RegConsoleCmd("sm_teamflip", Command_teamflip);
	RegConsoleCmd("sm_tf", Command_teamflip);
}

public Action:Command_teamflip(client, args)
{
	current_timeC = GetTime();
	
	if((current_timeC - previous_timeC) > GetConVarInt(delay_time)) // Only perform a teamflip if enough time has passed since the last one. This prevents spamming.
	{
		result_int = GetURandomInt() % 2; // Gets a random integer and checks to see whether it's odd or even
		GetClientName(client, client_name, sizeof(client_name)); // Gets the client_name of the person using the command
		
		if(result_int == 0)
			PrintToChatAll("\x01[\x05Teamflip\x01] \x03%s\x01 flipped a team and is on the \x03Survivor \x01team!", client_name); // Here {green} is actually yellow
		else
			PrintToChatAll("\x01[\x05Teamflip\x01] \x03%s\x01 flipped a team and is on the \x03Infected \x01team!", client_name);
		
		previous_timeC = current_timeC; // Update the previous time
	}
	else
	{
		PrintToConsole(client, "[Teamflip] Whoa there buddy, slow down. Wait at least %d seconds.", GetConVarInt(delay_time));
	}
	
	return Plugin_Handled;
}