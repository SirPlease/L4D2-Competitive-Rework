#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <l4d2util_constants>
#include <builtinvotes>
#include <sdktools>
#include <colors>
#undef REQUIRE_PLUGIN
#include <readyup>

#define USE_GIVEPLAYERITEM 0 // Works correctly only in the latest version of sourcemod 1.11 (GivePlayerItem sourcemod native)
#define MAX_ENTITY_NAME_LENGTH 64

enum
{
	eUndecided = 0,		// 0: Undecided.
	ePumpShotgun,		// 1: Pump Shotgun.
	eChromeShotgun,		// 2: Chrome Shotgun.
	eUzi,				// 3: Uzi.
	eSilencedUzi,		// 4: Silenced Uzi.
	eScout,				// 5: Scout.
	eAwp,				// 6: AWP.
	eGrenadeLauncher,	// 7: Grenade Launcher.
	eDeagle				// 8: Deagle.
};

static const char sGiveWeaponNames[][] =
{
	"",							// 0: Undecided.
	"weapon_pumpshotgun",		// 1: Pump Shotgun.
	"weapon_shotgun_chrome",	// 2: Chrome Shotgun.
	"weapon_smg",				// 3: Uzi.
	"weapon_smg_silenced",		// 4: Silenced Uzi.
	"weapon_sniper_scout",		// 5: Scout.
	"weapon_sniper_awp",		// 6: AWP.
	"weapon_grenade_launcher",	// 7: Grenade Launcher.
	"weapon_pistol_magnum"		// 8: Deagle.
};

static const char sRemoveWeaponNames[][] =
{
	"shotgun_chrome_spawn",
	"spawn",
	"ammo_spawn",
	"smg",
	"smg_silenced",
	"shotgun_chrome",
	"pumpshotgun",
	"hunting_rifle",
	"pistol",
	"pistol_magnum"
};

int
	g_iCurrentMode = eUndecided,
	g_iVotingMode = 0;

bool
	g_bIsAdminVote = false,
	g_bVoteUnderstood[MAXPLAYERS + 1] = {false, ...};

Menu
	g_hMenu = null;

Handle
	g_hVote = null;

public Plugin myinfo =
{
	name = "Weapon Loadout",
	author = "Sir, A1m`",
	description = "Allows the Players to choose which weapons to play the mode in.",
	version = "2.3",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_team", Event_PlayerTeam);

	RegConsoleCmd("sm_mode", Cmd_VoteMode, "Opens the Voting menu");

	RegAdminCmd("sm_forcemode", Cmd_ForceVoteMode, ADMFLAG_ROOT, "Forces the Voting menu");

	InitMenu();
}

void InitMenu()
{
	g_hMenu = new Menu(Menu_VoteMenuHandler);

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

public void Event_PlayerTeam(Event hEvent, char[] sEventName , bool bDontBroadcast)
{
	// Mode not picked, don't care.
	if (g_iCurrentMode == eUndecided) {
		return;
	}

	// Only during Ready-up
	if (!IsInReady()) {
		return;
	}
	
	int iTeam = hEvent.GetInt("team");
	// Only care about Survivors (Team 2)
	if (iTeam != L4D2Team_Survivor) {
		return;
	}

	int iUserId = hEvent.GetInt("userid");
	CreateTimer(0.2, Timer_ChangeTeamDelay, iUserId, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_ChangeTeamDelay(Handle hTimer, any iUserId)
{
	int iPlayer = GetClientOfUserId(iUserId);
	if (iPlayer > 0 && GetClientTeam(iPlayer) == L4D2Team_Survivor) {
		GiveSurvivorsWeapons(iPlayer, true);
	}

	return Plugin_Stop;
}

public void Event_RoundStart(Event hEvent, char[] sEventName, bool bDontBroadcast)
{
	CreateTimer(0.5, Timer_ClearMap, _, TIMER_FLAG_NO_MAPCHANGE); // Clear all Weapons on this delayed timer.

	// Let players know they can vote for their mode if the mode is undecided.
	if (g_iCurrentMode == eUndecided) {
		CreateTimer(15.0, Timer_InformPlayers, _, TIMER_REPEAT);
		return;
	}

	// Workaround for not receiving guns on second half.
	CreateTimer(2.0, Timer_GiveWeapons, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Cmd_VoteMode(int iClient, int iArgs)
{
	// Don't care about non-loaded players or Spectators.
	if (iClient == 0 || GetClientTeam(iClient) < L4D2Team_Survivor) {
		return Plugin_Handled;
	}

	// We've already decided on a mode.
	if (!IsInReady() || InSecondHalfOfRound()) {
		CPrintToChat(iClient, "{blue}[{green}Zone{blue}]{default}: You can only call for the vote during the first ready-up of a round");
		return Plugin_Handled;
	}

	// This player understands what to do.
	g_bVoteUnderstood[iClient] = true;

	// Is a new vote allowed?
	if (!IsNewBuiltinVoteAllowed()) {
		CPrintToChat(iClient, "A vote cannot be called at this moment, try again in a second or five.");
		return Plugin_Handled;
	}

	// Check if all players are present, if not.. tell them about it.
	if (ReadyPlayers() != GetMaxPlayers()) {
		CPrintToChat(iClient, "{blue}[{green}Zone{blue}]{default}: Both teams need to be full.");
		return Plugin_Handled;
	}

	// Show the Menu.
	ShowMenu(iClient);
	return Plugin_Handled;
}

public Action Cmd_ForceVoteMode(int iClient, int iArgs)
{
	if (iClient == 0) {
		return Plugin_Handled;
	}

	// This player understands what to do.
	g_bVoteUnderstood[iClient] = true;

	// Is a new vote allowed?
	if (!IsNewBuiltinVoteAllowed()) {
		CPrintToChat(iClient, "A vote cannot be called at this moment, try again in a second or five.");
		return Plugin_Handled;
	}

	// Show the Menu.
	ShowMenu(iClient);
	return Plugin_Handled;
}

void ShowMenu(int iClient)
{
	if (IsInReady()) {
		FakeClientCommand(iClient, "sm_hide");
	}

	g_hMenu.Display(iClient, MENU_TIME_FOREVER);
}

public int Menu_VoteMenuHandler(Menu hMenu, MenuAction iAction, int iClient, int iIndex)
{
	switch (iAction) {
		case MenuAction_Select: {
			// Is a new vote allowed?
			if (!IsNewBuiltinVoteAllowed()) {
				CPrintToChat(iClient, "A vote cannot be called at this moment, try again in a second or five.");
				return 0;
			}

			char sInfo[32], sVoteTitle[64];
			if (hMenu.GetItem(iIndex, sInfo, sizeof(sInfo))) {
				Format(sVoteTitle, sizeof(sVoteTitle), "Survivors get %s?", sInfo);
				g_iVotingMode = iIndex + 1;

				// Get all non-spectating players
				int iNumPlayers;
				int[] iPlayers = new int[MaxClients];

				for (int i = 1; i <= MaxClients; i++) {
					if (!IsClientInGame(i) || IsFakeClient(i) || (GetClientTeam(i) == L4D2Team_Spectator)) {
						continue;
					}

					iPlayers[iNumPlayers++] = i;
				}

				g_hVote = CreateBuiltinVote(BV_VoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);
				SetBuiltinVoteArgument(g_hVote, sVoteTitle);
				SetBuiltinVoteInitiator(g_hVote, iClient);
				SetBuiltinVoteResultCallback(g_hVote, BV_VoteResultHandler);
				DisplayBuiltinVote(g_hVote, iPlayers, iNumPlayers, 20);

				if (CheckCommandAccess(iClient, "sm_kick", ADMFLAG_KICK, false)) {
					g_bIsAdminVote = true;
				}

				FakeClientCommand(iClient, "Vote Yes");
			}
		}
		case MenuAction_Cancel: {
			FakeClientCommand(iClient, "sm_show");
		}
	}

	return 0;
}

public void BV_VoteActionHandler(Handle hVote, BuiltinVoteAction iAction, int iParam1, int iParam2)
{
	switch (iAction) {
		case BuiltinVoteAction_End: {
			delete hVote;
			g_hVote = null;
		}
		case BuiltinVoteAction_Cancel: {
			DisplayBuiltinVoteFail(hVote, view_as<BuiltinVoteFailReason>(iParam1));
		}
	}
}

public void BV_VoteResultHandler(Handle vote, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
	ReturnReadyUpPanel();

	for (int i = 0; i < num_items; i++) {
		if (item_info[i][BUILTINVOTEINFO_ITEM_INDEX] == BUILTINVOTES_VOTE_YES) {
			if (item_info[i][BUILTINVOTEINFO_ITEM_VOTES] > (num_clients / 2)) {
				// One last ready-up check (Let it go through if we don't have weapons set)
				// Allow Admins though
				if (!IsInReady() && g_iCurrentMode != eUndecided && !g_bIsAdminVote) {
					DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
					CPrintToChatAll("{blue}[{green}Zone{blue}]{default}: Vote didn't pass before you left ready-up.");
					return;
				}

				g_bIsAdminVote = false;
				DisplayBuiltinVotePass(vote, "Survivor Weapons Set!");
				g_iCurrentMode = g_iVotingMode;
				GiveSurvivorsWeapons();
				return;
			}
		}
	}

	g_bIsAdminVote = false;
	// Vote Failed
	DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
	return;
}

public Action Timer_ClearMap(Handle hTimer)
{
	char sEntityName[MAX_ENTITY_NAME_LENGTH];
	int iOwner = -1, iEntity = INVALID_ENT_REFERENCE;

	// Converted Weapons
	while ((iEntity = FindEntityByClassname(iEntity, "weapon_*")) != INVALID_ENT_REFERENCE) {
		if (iEntity <= MaxClients || !IsValidEntity(iEntity)) {
			continue;
		}

		GetEntityClassname(iEntity, sEntityName, sizeof(sEntityName));
		for (int i = 0; i < sizeof(sRemoveWeaponNames); i++) {
			// weapon_ - 7
			if (strcmp(sEntityName[7], sRemoveWeaponNames[i]) == 0) {
				iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
				if (iOwner == -1 || !IsClientInGame(iOwner)) {
					KillEntity(iEntity);
				}

				break;
			}
		}
	}
	return Plugin_Stop;
}

public Action Timer_GiveWeapons(Handle hTimer) {
	GiveSurvivorsWeapons();
	return Plugin_Stop;
}

public void OnRoundIsLive()
{
	g_hMenu.Cancel();
}

int ReadyPlayers()
{
	int iPlayersCount = 0;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) > L4D2Team_Spectator) {
			iPlayersCount++;
		}
	}

	return iPlayersCount;
}

void GiveSurvivorsWeapons(int iClient = 0, bool bOnlyIfSurvivorEmpty = false)
{
	// Establish what Weapon we're going for and format its name into a String.
	char sWeapon[MAX_ENTITY_NAME_LENGTH];

	strcopy(sWeapon, sizeof(sWeapon), sGiveWeaponNames[g_iCurrentMode]);

	if (strlen(sWeapon) == 0) {
		LogError("Failed to get the name of the weapon! Current mode: %d", g_iCurrentMode);
		return;
	}

	// Loop through Clients, clear their current primary weapons (if they have one)
	if (iClient != 0) {
		GiveAndRemovePlayerWeapon(iClient, sWeapon, bOnlyIfSurvivorEmpty);
		return;
	}

	for (int i = 1; i <= MaxClients; i++) {
		GiveAndRemovePlayerWeapon(i, sWeapon, bOnlyIfSurvivorEmpty);
	}
}

void GiveAndRemovePlayerWeapon(int iClient, const char[] sWeaponName, bool bOnlyIfSurvivorEmpty = false)
{
	if (!IsClientInGame(iClient) || GetClientTeam(iClient) != L4D2Team_Survivor || !IsPlayerAlive(iClient)) {
		return;
	}

	int iCurrMainWeapon = GetPlayerWeaponSlot(iClient, L4D2WeaponSlot_Primary);
	int iCurrSecondaryWeapon = GetPlayerWeaponSlot(iClient, L4D2WeaponSlot_Secondary);

	// Does the player already have an item in this slot?
	if (iCurrMainWeapon != -1) {
		// If we only want to give weapons to empty handed players, don't do anything for this player.
		if (bOnlyIfSurvivorEmpty) {
			return;
		}

		// Remove current Weapon.
		RemovePlayerItem(iClient, iCurrMainWeapon);
		KillEntity(iCurrMainWeapon);
	}

	if (iCurrSecondaryWeapon != -1) {
		// Remove current Weapon.
		RemovePlayerItem(iClient, iCurrSecondaryWeapon);
		KillEntity(iCurrSecondaryWeapon);
	}

#if (SOURCEMOD_V_MINOR == 11) || USE_GIVEPLAYERITEM
	GivePlayerItem(iClient, sWeaponName); // Fixed only in the latest version of sourcemod 1.11
#else
	int iEntity = CreateEntityByName(sWeaponName);
	if (iEntity == -1) {
		return;
	}

	DispatchSpawn(iEntity);
	EquipPlayerWeapon(iClient, iEntity);
#endif
}

public Action Timer_InformPlayers(Handle hTimer)
{
	static int iNumPrinted = 0;

	// Don't annoy the players, remind them a maximum of 6 times.
	if (iNumPrinted >= 6 || g_iCurrentMode != eUndecided) {
		iNumPrinted = 0;
		return Plugin_Stop;
	}

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) != L4D2Team_Spectator && !g_bVoteUnderstood[i]) {
			CPrintToChat(i, "{blue}[{green}Zone{blue}]{default}: Welcome to {blue}Zone{green}Hunters{default}.");
			CPrintToChat(i, "{blue}[{green}Zone{blue}]{default}: Type {olive}!mode {default}in chat to vote on weapons used.");
		}
	}

	iNumPrinted++;
	return Plugin_Continue;
}

void ReturnReadyUpPanel()
{
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) > L4D2Team_Spectator) {
			FakeClientCommand(i, "sm_show");
		}
	}
}

int GetMaxPlayers()
{
	return FindConVar("survivor_limit").IntValue + FindConVar("z_max_player_zombies").IntValue;
}

bool InSecondHalfOfRound()
{
	return view_as<bool>(GameRules_GetProp("m_bInSecondHalfOfRound", 1));
}

void KillEntity(int iEntity)
{
#if SOURCEMOD_V_MINOR > 8
	RemoveEntity(iEntity);
#else
	AcceptEntityInput(iEntity, "Kill");
#endif
}
