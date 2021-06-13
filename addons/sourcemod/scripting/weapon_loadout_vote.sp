#include <colors>
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <readyup>
#define REQUIRE_PLUGIN
#include <builtinvotes>

// 0: Undecided.
// 1: Pump Shotgun.
// 2: Chrome Shotgun.
// 3: Uzi.
// 4: Silenced Uzi.
// 5: Scout.
// 6: AWP.
// 7: Grenade Launcher.
// 8: Deagle.
int iCurrentMode;
int bv_VotingMode;
bool bAdminVote;
bool bVoteUnderstood[MAXPLAYERS + 1];

Menu g_hMenu;
Handle bv_hVote;

public Plugin myinfo = 
{
	name = "Weapon Loadout", 
	author = "Sir", 
	description = "Allows the Players to choose which weapons to play the mode in.", 
	version = "1.0", 
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_team", Event_PlayerTeam);
	RegConsoleCmd("sm_mode", Command_VoteMode, "Opens the Voting menu");
	RegAdminCmd("sm_forcemode", Command_ForceVoteMode, ADMFLAG_ROOT, "Forces the Voting menu");
	g_hMenu = new Menu(VoteMenuHandler);

	g_hMenu.SetTitle("Hunters vs ???");
	g_hMenu.AddItem("Pump Shotguns", "Pump Shotgun");
	g_hMenu.AddItem("Chrome Shotguns", "Chrome Shotgun");
	g_hMenu.AddItem("Uzis", "Uzi");
	g_hMenu.AddItem("Silenced Uzis", "Silenced Uzi");
	g_hMenu.AddItem("Scouts", "Scout");
	g_hMenu.AddItem("AWPs", "AWP");
	g_hMenu.AddItem("Grenade Launchers", "Grenade Launcher");
	g_hMenu.AddItem("Deagles", "Deagle");
	g_hMenu.ExitButton = true;
}

public Action Event_PlayerTeam(Event event, char[] name , bool dontBroadcast)
{
	int iPlayer = GetClientOfUserId(event.GetInt("userid"));
	int team = event.GetInt("team");

	// Mode not picked, don't care.
	if (iCurrentMode == 0) return;

	// Only care about Survivors (Team 2)
	if (team != 2) return;

	// Only during Ready-up
	if (!IsInReady()) return;

	CreateTimer(0.1, PlayerTimer, iPlayer);
}

public Action PlayerTimer(Handle timer, any iPlayer)
{
	if (iPlayer > 0 && 
	iPlayer <= MaxClients &&
	IsClientConnected(iPlayer) &&
	GetClientTeam(iPlayer) == 2)
	{
		GiveSurvivorsWeapons(iPlayer, true);
	}
}

public Action Event_RoundStart(Event event, char[] name , bool dontBroadcast)
{
	CreateTimer(0.5, Timer_ClearMap); // Clear all Weapons on this delayed timer.

	// Let players know they can vote for their mode if the mode is undecided.
	if (iCurrentMode == 0)
	{
		CreateTimer(15.0, Timer_InformPlayers, _, TIMER_REPEAT);
	}
	else GiveSurvivorsWeapons();
}

public Action Command_VoteMode(int client, int args)
{
	// Don't care about non-loaded players or Spectators.
	if (!IsClientInGame(client) || 
	GetClientTeam(client) == 1) return Plugin_Handled;

	// We've already decided on a mode.
	if (!IsInReady() || InSecondHalfOfRound())
	{
		CPrintToChat(client, "{blue}[{green}Zone{blue}]{default}: You can only call for the vote during the first ready-up of a round")
		return Plugin_Handled;
	}

	// This player understands what to do.
	bVoteUnderstood[client] = true;

	// Is a new vote allowed?
	if (!IsNewBuiltinVoteAllowed()) 
	{
		CPrintToChat(client, "A vote cannot be called at this moment, try again in a second or five.")
		return Plugin_Handled;
	}

	// Check if all players are present, if not.. tell them about it.
	if (ReadyPlayers() != MaxPlayers())
	{
		CPrintToChat(client, "{blue}[{green}Zone{blue}]{default}: Both teams need to be full.")
		return Plugin_Handled;
	}

	// Show the Menu.
	ShowMenu(client);
	return Plugin_Handled;
}

public Action Command_ForceVoteMode(int client, int args)
{
	// This player understands what to do.
	bVoteUnderstood[client] = true;

	// Is a new vote allowed?
	if (!IsNewBuiltinVoteAllowed()) 
	{
		CPrintToChat(client, "A vote cannot be called at this moment, try again in a second or five.")
		return Plugin_Handled;
	}

	// Show the Menu.
	ShowMenu(client);
	return Plugin_Handled;
}

void ShowMenu(int client)
{
	if (IsInReady()) FakeClientCommand(client, "sm_hide");
	g_hMenu.Display(client, MENU_TIME_FOREVER);
}

public int VoteMenuHandler(Menu menu, MenuAction action, int client, int index)
{
	if(action == MenuAction_Select)
	{
		// Is a new vote allowed?
		if (!IsNewBuiltinVoteAllowed()) 
		{
			CPrintToChat(client, "A vote cannot be called at this moment, try again in a second or five.")
			return;
		}

		char info[16];
		char bv_voteTitle[32];
		bool found = menu.GetItem(index, info, sizeof(info));
		if (found)
		{
			Format(bv_voteTitle, sizeof(bv_voteTitle), "Survivors get %s?", info)
			bv_VotingMode = index + 1;

			// Get all non-spectating players
			int iNumPlayers;
			int[] iPlayers = new int[MaxClients];

			for (int i=1; i<=MaxClients; i++)
			{
				if (!IsClientInGame(i) || IsFakeClient(i) || (GetClientTeam(i) == 1))
				{
					continue;
				}
				iPlayers[iNumPlayers++] = i;
			}

			bv_hVote = CreateBuiltinVote(bv_VoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);
			SetBuiltinVoteArgument(bv_hVote, bv_voteTitle);
			SetBuiltinVoteInitiator(bv_hVote, client);
			SetBuiltinVoteResultCallback(bv_hVote, bv_VoteResultHandler);
			DisplayBuiltinVote(bv_hVote, iPlayers, iNumPlayers, 20);
			if (CheckCommandAccess(client, "sm_kick", ADMFLAG_KICK, false)) bAdminVote = true;
			FakeClientCommand(client, "Vote Yes");
		}
	}
	else if (action == MenuAction_Cancel) 
	{
		FakeClientCommand(client, "sm_show");
	}
}

public void bv_VoteActionHandler(Handle vote, BuiltinVoteAction action, int param1, int param2)
{
	switch (action)
	{
		case BuiltinVoteAction_End:
		{
			bv_hVote = INVALID_HANDLE;
			CloseHandle(vote);
		}
		case BuiltinVoteAction_Cancel:
		{
			DisplayBuiltinVoteFail(vote, view_as<BuiltinVoteFailReason>(param1));
		}
	}
}

public void bv_VoteResultHandler(Handle vote, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
	for (int i=1; i<=MaxClients; i++)
	{
		if (!IsClientInGame(i) || 
		IsFakeClient(i) || 
		(GetClientTeam(i) == 1))
		{
			continue;
		}
		FakeClientCommand(i, "sm_show");
	}

	for (int i=0; i<num_items; i++)
	{
		if (item_info[i][BUILTINVOTEINFO_ITEM_INDEX] == BUILTINVOTES_VOTE_YES)
		{
			if (item_info[i][BUILTINVOTEINFO_ITEM_VOTES] > (num_clients / 2))
			{
			
				// One last ready-up check (Let it go through if we don't have weapons set)
				// Allow Admins though
				if (!IsInReady() && iCurrentMode != 0 && !bAdminVote)  
				{
					DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
					CPrintToChatAll("{blue}[{green}Zone{blue}]{default}: Vote didn't pass before you left ready-up.");
					return;
				}
				
				bAdminVote = false;
				DisplayBuiltinVotePass(vote, "Survivor Weapons Set!");
				iCurrentMode = bv_VotingMode;
				GiveSurvivorsWeapons();
				return;
			}
		}
	}
	
	bAdminVote = false;
	// Vote Failed
	DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
	return;
}

public Action Timer_ClearMap(Handle timer)
{
	// We only clear Chrome Shotguns because we need weaponrules to be loaded for pistols and deagles, so we converted everything to chromes in it. :D
	// After the weaponrules timer, we strike.
	// Surely you can do better than this Sir, get to this when you have time.
	int ent = -1;

	// Converted Weapons
	while ((ent = FindEntityByClassname(ent, "weapon_shotgun_chrome_spawn")) != -1)
	{
		AcceptEntityInput(ent, "Kill");
	}
	// Director
	while ((ent = FindEntityByClassname(ent, "weapon_spawn")) != -1)
	{
		AcceptEntityInput(ent, "Kill");
	}
	// Forced stripper spawns
	while ((ent = FindEntityByClassname(ent, "weapon_ammo_spawn")) != -1)
	{
		AcceptEntityInput(ent, "Kill");
	}
	while ((ent = FindEntityByClassname(ent, "weapon_smg")) != -1)
	{
		int iOwner = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
		if (!IsValidSurvivor(iOwner))
		  AcceptEntityInput(ent, "Kill");
	}
	while ((ent = FindEntityByClassname(ent, "weapon_smg_silenced")) != -1)
	{
		int iOwner = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
		if (!IsValidSurvivor(iOwner))
		  AcceptEntityInput(ent, "Kill");
	}
	while ((ent = FindEntityByClassname(ent, "weapon_shotgun_chrome")) != -1)
	{
		int iOwner = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
		if (!IsValidSurvivor(iOwner))
		  AcceptEntityInput(ent, "Kill");
	}
	while ((ent = FindEntityByClassname(ent, "weapon_pumpshotgun")) != -1)
	{
		int iOwner = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
		if (!IsValidSurvivor(iOwner))
		  AcceptEntityInput(ent, "Kill");
	}
	while ((ent = FindEntityByClassname(ent, "weapon_hunting_rifle")) != -1)
	{
		int iOwner = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
		if (!IsValidSurvivor(iOwner))
		  AcceptEntityInput(ent, "Kill");
	}
	while ((ent = FindEntityByClassname(ent, "weapon_pistol")) != -1)
	{
		int iOwner = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
		if (!IsValidSurvivor(iOwner))
		  AcceptEntityInput(ent, "Kill");
	}
	while ((ent = FindEntityByClassname(ent, "weapon_pistol_magnum")) != -1)
	{
		int iOwner = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
		if (!IsValidSurvivor(iOwner))
		  AcceptEntityInput(ent, "Kill");
	}
}

public void OnRoundIsLive()
{
	g_hMenu.Cancel();
}

int ReadyPlayers()
{
	int players;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && 
			GetClientTeam(i) != 1)
				players++;
	}
	return players;
}

void GiveSurvivorsWeapons(int player = 0, bool OnlyIfSurvivorEmpty = false)
{
	// Establish what Weapon we're going for and format its name into a String.
	char sWeapon[32]

	switch (iCurrentMode)
	{
		case 1: Format(sWeapon, sizeof(sWeapon), "weapon_pumpshotgun");
		case 2: Format(sWeapon, sizeof(sWeapon), "weapon_shotgun_chrome");
		case 3: Format(sWeapon, sizeof(sWeapon), "weapon_smg");
		case 4: Format(sWeapon, sizeof(sWeapon), "weapon_smg_silenced");
		case 5: Format(sWeapon, sizeof(sWeapon), "weapon_sniper_scout");
		case 6: Format(sWeapon, sizeof(sWeapon), "weapon_sniper_awp");
		case 7: Format(sWeapon, sizeof(sWeapon), "weapon_grenade_launcher");
		case 8: Format(sWeapon, sizeof(sWeapon), "weapon_pistol_magnum");
	}

	// Loop through Clients, clear their current primary weapons (if they have one)
	if (!player)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && 
			GetClientTeam(i) == 2)
			{
				int iCurrMainWeapon = GetPlayerWeaponSlot(i, 0);
				int iCurrSecondaryWeapon = GetPlayerWeaponSlot(i, 1);

				// Does the player already have an item in this slot?
				if (iCurrMainWeapon != -1) 
				{
					// If we only want to give weapons to empty handed players, don't do anything for this player.
					if (OnlyIfSurvivorEmpty) continue;

					// Remove current Weapon.
					AcceptEntityInput(iCurrMainWeapon, "Kill");
				}
				if (iCurrSecondaryWeapon != -1)
				{
					// Remove current Weapon.
					AcceptEntityInput(iCurrSecondaryWeapon, "Kill");
				}

				int ent;
				ent = CreateEntityByName(sWeapon);
				DispatchSpawn(ent);
				EquipPlayerWeapon(i, ent);
			}
		}
	}
	else
	{
		if (IsClientInGame(player) && 
		GetClientTeam(player) == 2)
		{
			int iCurrMainWeapon = GetPlayerWeaponSlot(player, 0);
			int iCurrSecondaryWeapon = GetPlayerWeaponSlot(player, 1);

			// Does the player already have an item in this slot?
			if (iCurrMainWeapon != -1) 
			{
				// If we only want to give weapons to empty handed players, don't do anything for this player.
				if (OnlyIfSurvivorEmpty) return;

				// Remove current Weapon.
				AcceptEntityInput(iCurrMainWeapon, "Kill");
			}
			if (iCurrSecondaryWeapon != -1)
			{
				// Remove current Weapon.
				AcceptEntityInput(iCurrSecondaryWeapon, "Kill");
			}

			int ent;
			ent = CreateEntityByName(sWeapon);
			DispatchSpawn(ent);
			EquipPlayerWeapon(player, ent);
		}
	}
}

int MaxPlayers()
{
	return GetConVarInt(FindConVar("survivor_limit")) + GetConVarInt(FindConVar("z_max_player_zombies"));
}

bool InSecondHalfOfRound()
{
	return view_as<bool>(GameRules_GetProp("m_bInSecondHalfOfRound"))
}

public Action Timer_InformPlayers(Handle timer)
{
	static int numPrinted = 0;
 
	// Don't annoy the players, remind them a maximum of 6 times.
	if (numPrinted >= 6 || iCurrentMode != 0) 
	{
		numPrinted = 0;
		return Plugin_Stop;
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) != 1 && !bVoteUnderstood[i])
		{
			CPrintToChat(i, "{blue}[{green}Zone{blue}]{default}: Welcome to {blue}Zone{green}Hunters{default}.");
			CPrintToChat(i, "{blue}[{green}Zone{blue}]{default}: Type {olive}!mode {default}in chat to vote on weapons used.");
		}
	}
	numPrinted++;
 
	return Plugin_Continue;
}

stock bool IsValidSurvivor(int client)
{
    if (client <= 0 || client > MaxClients || !IsClientConnected(client)) return false;
    if (!IsClientInGame(client)) return false;
    if (GetClientTeam(client) != 2) return false;
    return true; 
}