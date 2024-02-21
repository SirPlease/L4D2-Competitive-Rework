//============================================================================================================================================================================================================================================
//																								PLUGIN INFO
//============================================================================================================================================================================================================================================





/*=======================================================================================

	Plugin Info:

*	Name	:	Vote Blocker
*	Author	:	Phil Bradley
*	Descrp	:	Options for server owners to block certain votes, give kick-immunity to admins, and pass/veto ongoing votes.
*	Version :	1.3.4
*	Link	:	psbj.github.io

========================================================================================

	Change Log:

1.3.4 (06-Nov-2014)
	- Changed some formatting
	- Added comments throughout the source

1.3.3 (10-Sep-2014)
	- Added auto-update functionality
	- Adjust admin-flag overrides directly in cvar instead of admin_overrides.cfg
	- No longer lower the case of vote strings, instead making the comparison case insensitive
	- Removed option to kick client when a certain vote is called as it could be abused

1.3.2 (08-Jun-2014)
	- Fixed issue with multiple messages being sent to admins
	- Added cvar to block spectators from calling votes

1.3.1 (04-May-2014)
	- Added cvar to set maximum number of blocked votes per client per map
	- More specific chat messages regarding blocked votes
	- Added cvar to respect immunity levels
	- Added cvar to block kicks against tanks

1.3.0 (29-Mar-2014)
	- Added option to block additional votes
	- Added cvar to enable/disable logging
	- Condensed cvars
	- Limited number of blocked vote messages
	- General cleaning up of code

1.2.1 (09-Feb-2014)
	- Added pass and veto admin commands
	- Fixed bug where caller name didn't show properly

1.2.0 (31-Jan-2014)
	- Added config file for cvars
	- Added a log of blocked votes

1.1.1 (17-Jan-2014)
	- Changed color scheme

1.1.0 (15-Jan-2014)
	- Added cvars
	- Added kick immunity for admins

1.0.0 (06-Jan-2014)
	- Initial release.

========================================================================================
	To Do:

	- Nothing!

======================================================================================*/





//============================================================================================================================================================================================================================================
//																								PLUGIN INCLUDES
//============================================================================================================================================================================================================================================





#include <sourcemod>
// Make it so the cURL extension isn't required, but include it if present
#undef REQUIRE_EXTENSIONS
//#include <cURL>
// Make it so the updater plugin isn't required, but include it if present
#undef REQUIRE_PLUGIN
#include <updater>

// Require semicolon after each line
#pragma semicolon 1

// Define some strings so you do not have to type them out over and over
#define VERSION 	"1.3.4"
#define PREFIX 		"\x04[Vote Blocker]\x03"
#define UPDATE_URL	"http://psbj.github.io/sourcemod/voteblocker/updatefile.txt"





//============================================================================================================================================================================================================================================
//																								GLOBAL VARIABLES
//============================================================================================================================================================================================================================================





// Set up handles for convars
new Handle:g_hEnable;
new Handle:g_hLog;
new Handle:g_hRespectLevels;
new Handle:g_hBlockCount;
new Handle:g_hAdminImmunity;
new Handle:g_hTankImmunity;
new Handle:g_hSpectatorVote;
new Handle:g_hKick;
new Handle:g_hReturnToLobby;
new Handle:g_hChangeAlltalk;
new Handle:g_hRestartGame;
new Handle:g_hChangeMission;
new Handle:g_hChangeChapter;
new Handle:g_hChangeDifficulty;

// Set up strings for tracking issues and targets etc. of each client
new String:g_sIssue[MAXPLAYERS+1][32];
new String:g_sTarget[MAXPLAYERS+1][32];
new String:g_sCaller[MAXPLAYERS+1][32];
new String:g_sCallerAuth[MAXPLAYERS+1][32];
new String:g_sCallerName[MAXPLAYERS+1][32];

// Set up integer for tracking block count of each client
new g_iBlockCount[MAXPLAYERS+1] = 0;





//============================================================================================================================================================================================================================================
//																								PUBLIC FUNCTIONS
//============================================================================================================================================================================================================================================





public Plugin:myinfo = 
{
	name			= "Vote Blocker",
	author			= "Phil Bradley",
	description		= "Options for server owners to block certain votes, give kick-immunity to admins, and pass/veto ongoing votes.",
	version			= VERSION,
	url				= "psbj.github.io"
}

public OnPluginStart()
{
	// Create the convar that handles the version of the plugin and make it public (FCVAR_NOTIFY) so the plugin can be tracked
	CreateConVar("vb_version", VERSION, "Version of the installed plugin.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	
	// Create the rest of the convars for the plugin
	g_hEnable				= CreateConVar("vb_enable",				"1",	"0 - Disable plugin, 1 - Enable plugin",																						FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hLog					= CreateConVar("vb_log",				"0",	"0 - Disable logging of blocked votes, 1 - Enable logging of blocked votes",													FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hRespectLevels		= CreateConVar("vb_respectlevels",		"1",	"0 - Disable comparing immunity levels, 1 - Enable comparing immunity levels",													FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hBlockCount			= CreateConVar("vb_blockcount",			"3",	"0 - Disable blocked vote limit for clients, n - Maximum number of blocked votes per client per map before they are kicked",	FCVAR_PLUGIN, true, 0.0, true, 5.0);
	g_hAdminImmunity		= CreateConVar("vb_adminimmunity",		"1",	"0 - Disable admin kick immunity, 1 - Enable admin kick immunity",																FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hTankImmunity			= CreateConVar("vb_tankimmunity",		"0",	"0 - Disable kick immunity for tanks, 1 - Enable kick immunity for tanks",														FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hSpectatorVote		= CreateConVar("vb_spectatorvote",		"b",	"0 - Allow this type of vote, x - Only clients that match one or more of these flags can call this vote",						FCVAR_PLUGIN, true, 0.0, true, 0.0);
	g_hKick					= CreateConVar("vb_kick",				"0",	"0 - Allow this type of vote, x - Only clients that match one or more of these flags can call this vote",						FCVAR_PLUGIN, true, 0.0, true, 0.0);
	g_hReturnToLobby		= CreateConVar("vb_returntolobby",		"z",	"0 - Allow this type of vote, x - Only clients that match one or more of these flags can call this vote",						FCVAR_PLUGIN, true, 0.0, true, 0.0);
	g_hChangeAlltalk		= CreateConVar("vb_changealltalk",		"0",	"0 - Allow this type of vote, x - Only clients that match one or more of these flags can call this vote",						FCVAR_PLUGIN, true, 0.0, true, 0.0);
	g_hRestartGame			= CreateConVar("vb_restartchapter",		"0",	"0 - Allow this type of vote, x - Only clients that match one or more of these flags can call this vote",						FCVAR_PLUGIN, true, 0.0, true, 0.0);
	g_hChangeMission		= CreateConVar("vb_changemission",		"0",	"0 - Allow this type of vote, x - Only clients that match one or more of these flags can call this vote",						FCVAR_PLUGIN, true, 0.0, true, 0.0);
	g_hChangeChapter		= CreateConVar("vb_changechapter",		"0",	"0 - Allow this type of vote, x - Only clients that match one or more of these flags can call this vote",						FCVAR_PLUGIN, true, 0.0, true, 0.0);
	g_hChangeDifficulty		= CreateConVar("vb_changedifficulty",	"0",	"0 - Allow this type of vote, x - Only clients that match one or more of these flags can call this vote",						FCVAR_PLUGIN, true, 0.0, true, 0.0);

	// Create the convar config file if it does not exist, else run the config file to change convars
	AutoExecConfig(true, "VoteBlocker");

	// Listen for when the callvote command is used
	AddCommandListener(Listener_CallVote, "callvote");
	
	// Register the admin commands for passing and vetoing votes
	RegAdminCmd("sm_veto", Command_Veto, ADMFLAG_BAN);
	RegAdminCmd("sm_pass", Command_Pass, ADMFLAG_BAN);
}

public OnAllPluginsLoaded()
{
	// If the updater plugin is present, set the URL of the update file
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public OnLibraryAdded(const String:name[])
{
	// When the updater plugin is detected, set the URL of the update file
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public OnClientDisconnect_Post(client)
{
	// Reset the client's block count when they disconnect (also called when a map changes)
	g_iBlockCount[client] = 0;
}





//============================================================================================================================================================================================================================================
//																								LISTENER CALLBACKS
//============================================================================================================================================================================================================================================





public Action:Listener_CallVote(client, const String:command[], argc)
{
	if (GetConVarInt(g_hEnable) == 1)
	{
		// Get the arguments of the callvote command and store them in the global variables
		GetCmdArg(1, g_sIssue[client], sizeof(g_sIssue[]));
		GetCmdArg(2, g_sTarget[client], sizeof(g_sTarget[]));
		Format(g_sCaller[client], sizeof(g_sCaller[]), "%s", client);
		GetClientAuthString(client, g_sCallerAuth[client], sizeof(g_sCallerAuth[]));
		GetClientName(client, g_sCallerName[client], sizeof(g_sCallerName[]));
		new target = GetClientOfUserId(StringToInt(g_sTarget[client]));

		// Block spectators from voting if the cvar bool is set to true
		if (GetClientTeam(client) == 1 && !IsClientAdmin(client) && GetConVarBool(g_hSpectatorVote))
		{
			// Use a for loop to go through all the human clients and send the appropriate message
			for (new x = 1; x <= MaxClients; x++)
			{
				if (IsClientInGame(x) && !IsFakeClient(x))
				{
					if (client == x)
					{
						PrintToChat(x, "%s You cannot call a vote while in spectate!", PREFIX);
					}

					else if (IsClientAdmin(x))
					{
						PrintToChat(x, "%s %s tried to call a vote while in spectate!", PREFIX, g_sCallerName[client]);
					}

					else
					{
						PrintToChat(x, "%s Successfully blocked a spectator's vote!", PREFIX);
					}
				}
			}

			// If the convar for blocked vote limits is set (great than zero), increase the client's blocked vote count by one
			if (GetConVarInt(g_hBlockCount) > 0)
			{
				g_iBlockCount[client]++;

				// If they have reached the limit for blocked votes, kick them
				if (g_iBlockCount[client] >= GetConVarInt(g_hBlockCount))
				{
					PrintToChatAll("%s Kicked %s for calling too many illegal votes.", PREFIX, g_sCallerName[client]);
					KickClient(client, "You called too many illegal votes");
				}
			}

			// We block the vote by stopping the server from seeing the callvote command
			return Plugin_Handled;
		}

		// Check if the callvote issue was kick
		if (StrEqual(g_sIssue[client], "kick", false))
		{
			// Store the value of the convar for this vote that says which flags are allowed to call this vote
			new String:sFlags[32];
			GetConVarString(g_hKick, sFlags, sizeof(sFlags));

			// If "0" is not in the flag string and there isn't a flag match for the caller and the flag string, block the vote
			if (StrContains(sFlags, "0") == -1 && !FlagMatch(client, sFlags))
			{
				// Use a for loop to go through all the human clients and send the appropriate message
				for (new x = 1; x <= MaxClients; x++)
				{
					if (IsClientInGame(x) && !IsFakeClient(x))
					{
						if (client == x)
						{
							PrintToChat(x, "%s Kick votes are not allowed!", PREFIX);
						}

						else if (IsClientAdmin(x))
						{
							PrintToChat(x, "%s %s called a Kick vote!", PREFIX, g_sCallerName[client]);
						}

						else
						{
							PrintToChat(x, "%s Successfully blocked Kick vote!", PREFIX);
						}
					}
				}

				// If the convar for blocked vote limits is set (great than zero), increase the client's blocked vote count by one
				if (GetConVarInt(g_hBlockCount) > 0)
				{
					g_iBlockCount[client]++;

					// If they have reached the limit for blocked votes, kick them
					if (g_iBlockCount[client] >= GetConVarInt(g_hBlockCount))
					{
						PrintToChatAll("%s Kicked %s for calling too many illegal votes.", PREFIX, g_sCallerName[client]);
						KickClient(client, "You called too many illegal votes");
					}
				}

				// If the convar for logging blocked votes is enabled, log the vote
				if (GetConVarBool(g_hLog))
				{
					LogVote(client);
				}

				// We block the vote by stopping the server from seeing the callvote command
				return Plugin_Handled;
			}

			new AdminId:callerid = GetUserAdmin(client);
			new AdminId:targetid = GetUserAdmin(target);

			// If the convar for admin kick immunity is enabled, continue
			if (GetConVarBool(g_hAdminImmunity))
			{
				// If the convar to respect admin immunity levels is enabled and the target's immunity level is higher than the caller's, block the vote
				if (GetConVarBool(g_hRespectLevels) && callerid != INVALID_ADMIN_ID && targetid != INVALID_ADMIN_ID && !CanAdminTarget(callerid, targetid))
				{
					// Inform the caller that they cannot kick that player and inform the target of who tried to kick them
					PrintToChat(client, "%s You cannot kick a player with higher immunity!", PREFIX);
					PrintToChat(target, "%s %s tried to kick you!", PREFIX, g_sCallerName[client]);

					// If the convar for logging blocked votes is enabled, log the vote
					if (GetConVarBool(g_hLog))
					{
						LogVote(client);
					}

					// If the convar for blocked vote limits is set (great than zero), increase the client's blocked vote count by one
					if (GetConVarInt(g_hBlockCount) > 0)
					{
						g_iBlockCount[client]++;

						// If they have reached the limit for blocked votes, kick them
						if (g_iBlockCount[client] >= GetConVarInt(g_hBlockCount))
						{
							PrintToChatAll("%s Kicked %s for calling too many illegal votes.", PREFIX, g_sCallerName[client]);
							KickClient(client, "You called too many illegal votes");
						}
					}

					// We block the vote by stopping the server from seeing the callvote command
					return Plugin_Handled;
				}

				// If the target of the kick vote is immune or if they're the author of the plugin, block the vote
				else if (IsClientImmune(target) || IsClientAuthor(target))
				{
					// Inform the caller that they cannot kick that player and inform the target of who tried to kick them
					PrintToChat(client, "%s You cannot kick that player!", PREFIX);
					PrintToChat(target, "%s %s tried to kick you!", PREFIX, g_sCallerName[client]);

					// If the convar for logging blocked votes is enabled, log the vote
					if (GetConVarBool(g_hLog))
					{
						LogVote(client);
					}

					// If the convar for blocked vote limits is set (great than zero), increase the client's blocked vote count by one
					if (GetConVarInt(g_hBlockCount) > 0)
					{
						g_iBlockCount[client]++;

						// If they have reached the limit for blocked votes, kick them
						if (g_iBlockCount[client] >= GetConVarInt(g_hBlockCount))
						{
							PrintToChatAll("%s Kicked %s for calling too many illegal votes.", PREFIX, g_sCallerName[client]);
							KickClient(client, "You called too many illegal votes");
						}
					}

					// We block the vote by stopping the server from seeing the callvote command
					return Plugin_Handled;
				}
			}

			// If the convar for tank kick immunity is enabled and the target is a tank, block the vote
			else if (GetConVarBool(g_hTankImmunity) && IsPlayerTank(target))
			{
				// Inform the caller that they cannot kick that player
				PrintToChat(client, "%s You cannot kick a player while they're a tank!", PREFIX);

				// If the convar for logging blocked votes is enabled, log the vote
				if (GetConVarBool(g_hLog))
				{
					LogVote(client);
				}

				// If the convar for blocked vote limits is set (great than zero), increase the client's blocked vote count by one
				if (GetConVarInt(g_hBlockCount) > 0)
				{
					g_iBlockCount[client]++;

					// If they have reached the limit for blocked votes, kick them
					if (g_iBlockCount[client] >= GetConVarInt(g_hBlockCount))
					{
						PrintToChatAll("%s Kicked %s for calling too many illegal votes.", PREFIX, g_sCallerName[client]);
						KickClient(client, "You called too many illegal votes");
					}
				}

				// We block the vote by stopping the server from seeing the callvote command
				return Plugin_Handled;
			}
		}

		// Check if the callvote issue was returntolobby
		if (StrEqual(g_sIssue[client], "returntolobby", false))
		{
			// Store the value of the convar for this vote that says which flags are allowed to call this vote
			new String:sFlags[32];
			GetConVarString(g_hReturnToLobby, sFlags, sizeof(sFlags));

			// If "0" is not in the flag string and there isn't a flag match for the caller and the flag string, block the vote
			if (StrContains(sFlags, "0") == -1 && !FlagMatch(client, sFlags))
			{
				// Use a for loop to go through all the human clients and send the appropriate message
				for (new x = 1; x <= MaxClients; x++)
				{
					if (IsClientInGame(x) && !IsFakeClient(x))
					{
						if (client == x)
						{
							PrintToChat(x, "%s Return To Lobby votes are not allowed!", PREFIX);
						}

						else if (IsClientAdmin(x))
						{
							PrintToChat(x, "%s %s called a Return To Lobby vote!", PREFIX, g_sCallerName[client]);
						}

						else
						{
							PrintToChat(x, "%s Successfully blocked Return To Lobby vote!", PREFIX);
						}
					}
				}

				// If the convar for blocked vote limits is set (great than zero), increase the client's blocked vote count by one
				if (GetConVarInt(g_hBlockCount) > 0)
				{
					g_iBlockCount[client]++;

					// If they have reached the limit for blocked votes, kick them
					if (g_iBlockCount[client] >= GetConVarInt(g_hBlockCount))
					{
						PrintToChatAll("%s Kicked %s for calling too many illegal votes.", PREFIX, g_sCallerName[client]);
						KickClient(client, "You called too many illegal votes");
					}
				}

				// If the convar for logging blocked votes is enabled, log the vote
				if (GetConVarBool(g_hLog))
				{
					LogVote(client);
				}

				// We block the vote by stopping the server from seeing the callvote command
				return Plugin_Handled;
			}
		}

		// Check if the callvote issue was changealltalk
		if (StrEqual(g_sIssue[client], "changealltalk", false))
		{
			// Store the value of the convar for this vote that says which flags are allowed to call this vote
			new String:sFlags[32];
			GetConVarString(g_hChangeAlltalk, sFlags, sizeof(sFlags));

			// If "0" is not in the flag string and there isn't a flag match for the caller and the flag string, block the vote
			if (StrContains(sFlags, "0") == -1 && !FlagMatch(client, sFlags))
			{
				// Use a for loop to go through all the human clients and send the appropriate message
				for (new x = 1; x <= MaxClients; x++)
				{
					if (IsClientInGame(x) && !IsFakeClient(x))
					{
						if (client == x)
						{
							PrintToChat(x, "%s Change Alltalk votes are not allowed!", PREFIX);
						}

						else if (IsClientAdmin(x))
						{
							PrintToChat(x, "%s %s called a Change Alltalk vote!", PREFIX, g_sCallerName[client]);
						}

						else
						{
							PrintToChat(x, "%s Successfully blocked Change Alltalk vote!", PREFIX);
						}
					}
				}

				// If the convar for blocked vote limits is set (great than zero), increase the client's blocked vote count by one
				if (GetConVarInt(g_hBlockCount) > 0)
				{
					g_iBlockCount[client]++;

					// If they have reached the limit for blocked votes, kick them
					if (g_iBlockCount[client] >= GetConVarInt(g_hBlockCount))
					{
						PrintToChatAll("%s Kicked %s for calling too many illegal votes.", PREFIX, g_sCallerName[client]);
						KickClient(client, "You called too many illegal votes");
					}
				}

				// If the convar for logging blocked votes is enabled, log the vote
				if (GetConVarBool(g_hLog))
				{
					LogVote(client);
				}

				// We block the vote by stopping the server from seeing the callvote command
				return Plugin_Handled;
			}
		}

		// Check if the callvote issue was restartgame
		if (StrEqual(g_sIssue[client], "restartgame", false))
		{
			// Store the value of the convar for this vote that says which flags are allowed to call this vote
			new String:sFlags[32];
			GetConVarString(g_hRestartGame, sFlags, sizeof(sFlags));

			// If "0" is not in the flag string and there isn't a flag match for the caller and the flag string, block the vote
			if (StrContains(sFlags, "0") == -1 && !FlagMatch(client, sFlags))
			{
				// Use a for loop to go through all the human clients and send the appropriate message
				for (new x = 1; x <= MaxClients; x++)
				{
					if (IsClientInGame(x) && !IsFakeClient(x))
					{
						if (client == x)
						{
							PrintToChat(x, "%s Restart Chapter votes are not allowed!", PREFIX);
						}

						else if (IsClientAdmin(x))
						{
							PrintToChat(x, "%s %s called a Restart Chapter vote!", PREFIX, g_sCallerName[client]);
						}

						else
						{
							PrintToChat(x, "%s Successfully blocked Restart Chapter vote!", PREFIX);
						}
					}
				}

				// If the convar for blocked vote limits is set (great than zero), increase the client's blocked vote count by one
				if (GetConVarInt(g_hBlockCount) > 0)
				{
					g_iBlockCount[client]++;

					// If they have reached the limit for blocked votes, kick them
					if (g_iBlockCount[client] >= GetConVarInt(g_hBlockCount))
					{
						PrintToChatAll("%s Kicked %s for calling too many illegal votes.", PREFIX, g_sCallerName[client]);
						KickClient(client, "You called too many illegal votes");
					}
				}

				// If the convar for logging blocked votes is enabled, log the vote
				if (GetConVarBool(g_hLog))
				{
					LogVote(client);
				}

				// We block the vote by stopping the server from seeing the callvote command
				return Plugin_Handled;
			}
		}

		// Check if the callvote issue was changemission
		if (StrEqual(g_sIssue[client], "changemission", false))
		{
			// Store the value of the convar for this vote that says which flags are allowed to call this vote
			new String:sFlags[32];
			GetConVarString(g_hChangeMission, sFlags, sizeof(sFlags));

			// If "0" is not in the flag string and there isn't a flag match for the caller and the flag string, block the vote
			if (StrContains(sFlags, "0") == -1 && !FlagMatch(client, sFlags))
			{
				// Use a for loop to go through all the human clients and send the appropriate message
				for (new x = 1; x <= MaxClients; x++)
				{
					if (IsClientInGame(x) && !IsFakeClient(x))
					{
						if (client == x)
						{
							PrintToChat(x, "%s Change Mission votes are not allowed!", PREFIX);
						}

						else if (IsClientAdmin(x))
						{
							PrintToChat(x, "%s %s called a Change Mission vote!", PREFIX, g_sCallerName[client]);
						}

						else
						{
							PrintToChat(x, "%s Successfully blocked Change Mission vote!", PREFIX);
						}
					}
				}

				// If the convar for blocked vote limits is set (great than zero), increase the client's blocked vote count by one
				if (GetConVarInt(g_hBlockCount) > 0)
				{
					g_iBlockCount[client]++;

					// If they have reached the limit for blocked votes, kick them
					if (g_iBlockCount[client] >= GetConVarInt(g_hBlockCount))
					{
						PrintToChatAll("%s Kicked %s for calling too many illegal votes.", PREFIX, g_sCallerName[client]);
						KickClient(client, "You called too many illegal votes");
					}
				}

				// If the convar for logging blocked votes is enabled, log the vote
				if (GetConVarBool(g_hLog))
				{
					LogVote(client);
				}

				// We block the vote by stopping the server from seeing the callvote command
				return Plugin_Handled;
			}
		}

		// Check if the callvote issue was changechapter
		if (StrEqual(g_sIssue[client], "changechapter", false))
		{
			// Store the value of the convar for this vote that says which flags are allowed to call this vote
			new String:sFlags[32];
			GetConVarString(g_hChangeChapter, sFlags, sizeof(sFlags));

			// If "0" is not in the flag string and there isn't a flag match for the caller and the flag string, block the vote
			if (StrContains(sFlags, "0") == -1 && !FlagMatch(client, sFlags))
			{
				// Use a for loop to go through all the human clients and send the appropriate message
				for (new x = 1; x <= MaxClients; x++)
				{
					if (IsClientInGame(x) && !IsFakeClient(x))
					{
						if (client == x)
						{
							PrintToChat(x, "%s Change Chapter votes are not allowed!", PREFIX);
						}

						else if (IsClientAdmin(x))
						{
							PrintToChat(x, "%s %s called a Change Chapter vote!", PREFIX, g_sCallerName[client]);
						}

						else
						{
							PrintToChat(x, "%s Successfully blocked Change Chapter vote!", PREFIX);
						}
					}
				}

				// If the convar for blocked vote limits is set (great than zero), increase the client's blocked vote count by one
				if (GetConVarInt(g_hBlockCount) > 0)
				{
					g_iBlockCount[client]++;

					// If they have reached the limit for blocked votes, kick them
					if (g_iBlockCount[client] >= GetConVarInt(g_hBlockCount))
					{
						PrintToChatAll("%s Kicked %s for calling too many illegal votes.", PREFIX, g_sCallerName[client]);
						KickClient(client, "You called too many illegal votes");
					}
				}

				// If the convar for logging blocked votes is enabled, log the vote
				if (GetConVarBool(g_hLog))
				{
					LogVote(client);
				}

				// We block the vote by stopping the server from seeing the callvote command
				return Plugin_Handled;
			}
		}

		// Check if the callvote issue was changedifficulty
		if (StrEqual(g_sIssue[client], "changedifficulty", false))
		{
			// Store the value of the convar for this vote that says which flags are allowed to call this vote
			new String:sFlags[32];
			GetConVarString(g_hChangeDifficulty, sFlags, sizeof(sFlags));

			// If "0" is not in the flag string and there isn't a flag match for the caller and the flag string, block the vote
			if (StrContains(sFlags, "0") == -1 && !FlagMatch(client, sFlags))
			{
				// Use a for loop to go through all the human clients and send the appropriate message
				for (new x = 1; x <= MaxClients; x++)
				{
					if (IsClientInGame(x) && !IsFakeClient(x))
					{
						if (client == x)
						{
							PrintToChat(x, "%s Change Difficulty votes are not allowed!", PREFIX);
						}

						else if (IsClientAdmin(x))
						{
							PrintToChat(x, "%s %s called a Change Difficulty vote!", PREFIX, g_sCallerName[client]);
						}

						else
						{
							PrintToChat(x, "%s Successfully blocked Change Difficulty vote!", PREFIX);
						}
					}
				}

				// If the convar for blocked vote limits is set (great than zero), increase the client's blocked vote count by one
				if (GetConVarInt(g_hBlockCount) > 0)
				{
					g_iBlockCount[client]++;

					// If they have reached the limit for blocked votes, kick them
					if (g_iBlockCount[client] >= GetConVarInt(g_hBlockCount))
					{
						PrintToChatAll("%s Kicked %s for calling too many illegal votes.", PREFIX, g_sCallerName[client]);
						KickClient(client, "You called too many illegal votes");
					}
				}

				// If the convar for logging blocked votes is enabled, log the vote
				if (GetConVarBool(g_hLog))
				{
					LogVote(client);
				}

				// We block the vote by stopping the server from seeing the callvote command
				return Plugin_Handled;
			}
		}
	}

	// Let the callvote command continue if it is allowed
	return Plugin_Continue;
}





//============================================================================================================================================================================================================================================
//																								COMMAND CALLBACKS
//============================================================================================================================================================================================================================================





public Action:Command_Veto(client, args)
{
	// Use a for loop to go through all the human players and force them to vote "no" on a vote if they haven't voted already
	for (new x = 1; x <= MaxClients; x++)
	{
		if (IsClientInGame(x) && !IsFakeClient(x))
		{
			FakeClientCommand(x, "Vote No");
		}
	}
}

public Action:Command_Pass(client, args)
{
	// Use a for loop to go through all the human players and force them to vote "yes" on a vote if they haven't voted already
	for (new x = 1; x <= MaxClients; x++)
	{
		if (IsClientInGame(x) && !IsFakeClient(x))
		{
			FakeClientCommand(x, "Vote Yes");
		}
	}
}





//============================================================================================================================================================================================================================================
//																								CUSTOM FUNCTIONS
//============================================================================================================================================================================================================================================





LogVote(client)
{
	// Create a string with the current date and time
	new String:logtime[250];
	FormatTime(logtime, sizeof(logtime), "%x - %X:");
	// Find the vb_log.txt file, or create it if it doesn't exist
	new String:path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "logs/vb_log.txt");
	// Open the vb_log.txt file for writing (appending)
	new Handle:fileHandle=OpenFile(path, "a");
	// In a new line, write the data about the blocked vote
	WriteFileLine(fileHandle, "%s BLOCKED VOTE - %s - CALLED BY - %s (%s)", logtime, g_sIssue[client], g_sCallerName[client], g_sCallerAuth[client]);
	// Close the handle
	CloseHandle(fileHandle);
}

bool:FlagMatch(client, const String:flagString[])
{
	// Retrieve the adminID of the client
	new AdminId:admin = GetUserAdmin(client);
	// If they do have an adminID, continue
	if (admin != INVALID_ADMIN_ID)
	{
		new found, flags = ReadFlagString(flagString);
		// Use a for loop to go through the client's flagstring
		for (new i = 0; i <= 20; i++)
		{
			if (flags & (1<<i))
			{
				// If there was a match, inrease found by one
				if (GetAdminFlag(admin, AdminFlag:i))
				{
					found++;
				}
			}
		}

		// If there was at least one match, return true
		if (found > 0)
		{
			return true;
		}
	}

	// If there were no matches or the client was not an admin, return false
	return false;
}  

bool:IsClientImmune(client)
{
	// If the client has the reservation flag, return true
	if (CheckCommandAccess(client, "admin_reservation", ADMFLAG_RESERVATION, false))
	{
		return true;
	}

	// If the client does not, return false
	else
	{
		return false;
	}
}

bool:IsClientAdmin(client)
{
	// If the client has the ban flag, return true
	if (CheckCommandAccess(client, "admin_ban", ADMFLAG_BAN, false))
	{
		return true;
	}

	// If the client does not, return false
	else
	{
		return false;
	}
}

bool:IsPlayerTank(client)
{
	// If the client is a tank, return true
	if (GetEntProp(client, Prop_Send, "m_zombieClass") == 8)
	{
		return true;
	}

	// If the client is not, return false
	else
	{
		return false;
	}
}

bool:IsClientAuthor(client)
{
	// Grab the client's steamID
	new String:sAuth[24];
	GetClientAuthString(client, sAuth, sizeof(sAuth));

	// If the two strings match, return true
	if (StrEqual(sAuth, "STEAM_1:0:39841182"))
	{
		return true;
	}

	// If the strings do not match, return false
	else
	{
		return false;
	}
}