#include <sourcemod>
#include <sdktools_client>
#include <builtinvotes>
#include <colors>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0"

public Plugin myinfo = 
{
	name = "L4D2 Caster System (Original built in readyup)",
	author = "CanadaRox, Forgetest",
	description = "Standalone caster handler.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
};

#define L4D2Team_Spectator 1

#define TRANSLATION_COMMON "common.phrases"
#define TRANSLATION_CASTER "caster_system.phrases"

// Caster System
StringMap casterTrie;
StringMap allowedCastersTrie;
bool forbidSelfRegister;

ConVar g_hDisableAddons;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("IsClientCaster", Native_IsClientCaster);
	CreateNative("IsIDCaster", Native_IsIDCaster);
	RegPluginLibrary("caster_system");
}

public void OnPluginStart()
{
	LoadPluginTranslation();
	
	casterTrie = new StringMap();
	allowedCastersTrie = new StringMap();
	
	g_hDisableAddons = CreateConVar("caster_disable_addons", "0", "Whether to disallow addons on casters", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hDisableAddons.AddChangeHook(OnAddonsSettingChanged);
	
	// Caster Registration
	RegAdminCmd("sm_caster",			Caster_Cmd, ADMFLAG_BAN, "Registers a player as a caster");
	RegAdminCmd("sm_resetcasters",		ResetCaster_Cmd, ADMFLAG_BAN, "Used to reset casters between matches.  This should be in confogl_off.cfg or equivalent for your system");
	RegAdminCmd("sm_add_caster_id",		AddCasterSteamID_Cmd, ADMFLAG_BAN, "Used for adding casters to the whitelist -- i.e. who's allowed to self-register as a caster");
	RegAdminCmd("sm_remove_caster_id",	RemoveCasterSteamID_Cmd, ADMFLAG_BAN, "Used for removing casters to the whitelist -- i.e. who's allowed to self-register as a caster");
	RegAdminCmd("sm_printcasters",		PrintCasters_Cmd, ADMFLAG_BAN, "Used for print casters in the whitelist");
	RegConsoleCmd("sm_cast",			Cast_Cmd, "Registers the calling player as a caster");
	RegConsoleCmd("sm_notcasting",		NotCasting_Cmd, "Deregister yourself as a caster or allow admins to deregister other players");
	RegConsoleCmd("sm_uncast",			NotCasting_Cmd, "Deregister yourself as a caster or allow admins to deregister other players");
	
	// Kick Specs
	RegConsoleCmd("sm_kickspecs",		KickSpecs_Cmd, "Let's vote to kick those Spectators!");
	
	HookEvent("player_team", PlayerTeam_Event);
}

void LoadPluginTranslation()
{
	char sPath[PLATFORM_MAX_PATH];
	
	BuildPath(Path_SM, sPath, sizeof sPath, "translations/" ... TRANSLATION_COMMON ... ".txt");
	if (!FileExists(sPath))
	{
		SetFailState("Missing translation file \"" ... TRANSLATION_COMMON ... ".txt\"");
	}
	LoadTranslations(TRANSLATION_COMMON);
	
	BuildPath(Path_SM, sPath, sizeof sPath, "translations/" ... TRANSLATION_CASTER ... ".txt");
	if (!FileExists(sPath))
	{
		SetFailState("Missing translation file \"" ... TRANSLATION_CASTER ... ".txt\"");
	}
	LoadTranslations(TRANSLATION_CASTER);
}



// ========================
//  Natives
// ========================

public int Native_IsClientCaster(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return IsClientCaster(client);
}

public int Native_IsIDCaster(Handle plugin, int numParams)
{
	char buffer[64];
	GetNativeString(1, buffer, sizeof(buffer));
	return IsIDCaster(buffer);
}

bool IsClientCaster(int client)
{
	char buffer[64];
	return GetClientAuthId(client, AuthId_Steam2, buffer, sizeof(buffer)) && IsIDCaster(buffer);
}

bool IsIDCaster(const char[] AuthID)
{
	bool dummy;
	return GetTrieValue(casterTrie, AuthID, dummy);
}



// ========================
//  Caster Addons
// ========================

public void OnAddonsSettingChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	bool disable = !!StringToInt(newValue);
	bool previous = !!StringToInt(oldValue);
	
	if (disable == previous) return;
	
	if (disable)
	{
		ArrayList hCastersList = new ArrayList();
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsClientCaster(i))
			{
				CPrintToChat(i, "%t", "ForbidAddons");
				CPrintToChat(i, "%t", "Reconnect1");
				CPrintToChat(i, "%t", "Reconnect2");
				hCastersList.Push(GetClientUserId(i));
			}
		}
		
		if (!hCastersList.Length)
		{
			delete hCastersList;
			return;
		}
		
		// Reconnection to disable their addons
		CreateTimer(3.0, Timer_ReconnectCasters, hCastersList, TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE);
	}
	else
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsClientCaster(i))
			{
				CPrintToChat(i, "%t", "AllowAddons");
				CPrintToChat(i, "%t", "SelfCast2");
			}
		}
	}
}

public Action Timer_ReconnectCasters(Handle timer, ArrayList aList)
{
	int size = aList.Length;
	for (int i = 0; i < size; i++)
	{
		int client = GetClientOfUserId(aList.Get(i));
		if (client > 0) ReconnectClient(client);
	}
}

public Action L4D2_OnClientDisableAddons(const char[] SteamID)
{
	return (!g_hDisableAddons.BoolValue && IsIDCaster(SteamID)) ? Plugin_Handled : Plugin_Continue;
}

public void PlayerTeam_Event(Event event, const char[] name, bool dontBroadcast)
{
	if (event.GetInt("team") != L4D2Team_Spectator)
	{
		int userid = event.GetInt("userid");
		CreateTimer(1.0, CasterCheck, userid, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action CasterCheck(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (client && IsClientInGame(client) && GetClientTeam(client) != L4D2Team_Spectator && IsClientCaster(client))
	{
		CPrintToChat(client, "%t", "CasterCheck1");
		CPrintToChat(client, "%t", "CasterCheck2");
		ChangeClientTeam(client, L4D2Team_Spectator);
	}
}

// ========================
//  Caster Registration
// ========================

public Action Cast_Cmd(int client, int args)
{
	if (!client) return Plugin_Continue;
	
 	char buffer[64];
	GetClientAuthId(client, AuthId_Steam2, buffer, sizeof(buffer));
	
	bool temp;
	if (forbidSelfRegister)
	{
		if (!allowedCastersTrie.GetValue(buffer, temp))
		{
			CPrintToChat(client, "%t", "SelfCastNotAllowed");
			return Plugin_Handled;
		}
	}
	
	if (!casterTrie.GetValue(buffer, temp))
	{
		if (GetClientTeam(client) != L4D2Team_Spectator)
		{
			ChangeClientTeam(client, L4D2Team_Spectator);
		}
		casterTrie.SetValue(buffer, true);
		CPrintToChat(client, "%t", "SelfCast1");
		CPrintToChat(client, "%t", "SelfCast2");
	}
	
	return Plugin_Handled;
}

public Action Caster_Cmd(int client, int args)
{	
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_caster <player>");
		return Plugin_Handled;
	}
	
	char buffer[64];
	GetCmdArg(1, buffer, sizeof(buffer));
	
	int target = FindTarget(client, buffer, true, false);
	if (target > 0) // If FindTarget fails we don't need to print anything as it prints it for us!
	{
		if (GetClientAuthId(target, AuthId_Steam2, buffer, sizeof(buffer)))
		{
			casterTrie.SetValue(buffer, true);
			ReplyToCommand(client, "\x01%t", "RegCasterReply", target);
			CPrintToChat(target, "%t", "RegCasterTarget", client);
			CPrintToChat(target, "%t", "SelfCast2");
		}
		else
		{
			ReplyToCommand(client, "\x01%t", "CasterSteamIDError");
		}
	}
	
	return Plugin_Handled;
}

public Action NotCasting_Cmd(int client, int args)
{
	char buffer[64];
	
	if (args < 1) // If no target is specified, assumes self-uncasting
	{
		GetClientAuthId(client, AuthId_Steam2, buffer, sizeof(buffer));
		if (casterTrie.Remove(buffer))
		{
			CPrintToChat(client, "%t", "Reconnect1");
			CPrintToChat(client, "%t", "Reconnect2");
			
			// Reconnection to disable their addons
			CreateTimer(3.0, Reconnect, client);
		}
	}
	else // If a target is specified
	{
		AdminId id = GetUserAdmin(client);
		if (id == INVALID_ADMIN_ID || !GetAdminFlag(id, Admin_Ban)) // Check for specific admin flag
		{
			ReplyToCommand(client, "\x01%t", "UnregCasterNonAdmin");
			return Plugin_Handled;
		}
		
		GetCmdArg(1, buffer, sizeof(buffer));
		
		int target = FindTarget(client, buffer, true, true);
		if (target > 0) // If FindTarget fails we don't need to print anything as it prints it for us!
		{
			if (GetClientAuthId(target, AuthId_Steam2, buffer, sizeof(buffer)))
			{
				if (casterTrie.Remove(buffer))
				{
					CPrintToChat(target, "%t", "UnregCasterTarget", client);
					NotCasting_Cmd(target, 0);
				}
				ReplyToCommand(client, "\x01%t", "UnregCasterSuccess", target);
			}
			else
			{
				ReplyToCommand(client, "\x01%t", "CasterSteamIDError");
			}
		}
	}
	return Plugin_Handled;
}

public Action Reconnect(Handle timer, int client)
{
	if (IsClientConnected(client)) ReconnectClient(client);
}

public Action ResetCaster_Cmd(int client, int args)
{
	casterTrie.Clear();
	forbidSelfRegister = false;
	ReplyToCommand(client, "\x01%t", "CasterDBReset");
	return Plugin_Handled;
}

public Action AddCasterSteamID_Cmd(int client, int args)
{
	char buffer[128];
	GetCmdArg(1, buffer, sizeof(buffer));
	if (buffer[0] != EOS) 
	{
		forbidSelfRegister = true;
		if (allowedCastersTrie.SetValue(buffer, 1, false))
		{
			ReplyToCommand(client, "\x01%t", "CasterDBAdd", buffer);
		}
		else ReplyToCommand(client, "\x01%t", "CasterDBFound", buffer);
	}
	else ReplyToCommand(client, "\x01%t", "CasterDBError");
	return Plugin_Handled;
}

public Action RemoveCasterSteamID_Cmd(int client, int args)
{
	char buffer[128];
	GetCmdArg(1, buffer, sizeof(buffer));
	if (buffer[0] != EOS) 
	{
		int dummy;
		if (allowedCastersTrie.GetValue(buffer, dummy))
		{
			allowedCastersTrie.Remove(buffer);
			if (allowedCastersTrie.Size == 0) forbidSelfRegister = false;
			ReplyToCommand(client, "\x01%t", "CasterDBRemove", buffer);
		}
		else ReplyToCommand(client, "\x01%t", "CasterDBFound", buffer);
	}
	else ReplyToCommand(client, "\x01%t", "CasterDBError");
	return Plugin_Handled;
}

public Action PrintCasters_Cmd(int client, int args)
{
	StringMapSnapshot ss = allowedCastersTrie.Snapshot();
	char buffer[128];
	
	if (GetCmdReplySource() == SM_REPLY_TO_CHAT)
	{
		if (client > 0) PrintToChat(client, "[casters_database] List is printed in console");
	}
	
	PrintToConsole(client, "/***********[casters_database]***********\\");
	
	int len = ss.Length;
	for (int i = 0; i < len; i++)
	{
		ss.GetKey(i, buffer, sizeof buffer);
		PrintToConsole(client, "Caster #%i: %s", i+1, buffer);
	}
	PrintToConsole(client, ">* Total Casters: %i", len);
	
	delete ss;
	return Plugin_Handled;
}



// ========================
//  Kick Specs
// ========================

public Action KickSpecs_Cmd(int client, int args)
{
	AdminId id = GetUserAdmin(client);
	if (id != INVALID_ADMIN_ID && GetAdminFlag(id, Admin_Ban)) // Check for specific admin flag
	{
		CreateTimer(2.0, Timer_KickSpecs);
		CPrintToChatAll("%t", "KickSpecsAdmin", client);
		return Plugin_Handled;
	}
	
	// Filter spectator
	if (GetClientTeam(client) == L4D2Team_Spectator)
	{
		CPrintToChat(client, "%t", "KickSpecsVoteSpec");
		return Plugin_Handled;
	}
	
	StartKickSpecsVote(client);
	return Plugin_Handled;
}

// ========================
//  Vote
// ========================

void StartKickSpecsVote(int client)
{
	if (IsBuiltinVoteInProgress())
	{
		CPrintToChat(client, "%t", "VoteInProgress");
		return;
	}
	if (CheckBuiltinVoteDelay() > 0)
	{
		CPrintToChat(client, "%t", "VoteDelay", CheckBuiltinVoteDelay());
		return;
	}
	
	Handle hVote = CreateBuiltinVote(VoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);

	char sBuffer[128];
	FormatEx(sBuffer, sizeof(sBuffer), "%T", "KickSpecsVoteTitle", LANG_SERVER);
	SetBuiltinVoteArgument(hVote, sBuffer);
	SetBuiltinVoteInitiator(hVote, client);
	SetBuiltinVoteResultCallback(hVote, KickSpecsVoteResultHandler);
	
	// Display to players
	int total = 0;
	int[] players = new int[MaxClients];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || GetClientTeam(i) == L4D2Team_Spectator)
			continue;
		players[total++] = i;
	}
	DisplayBuiltinVote(hVote, players, total, FindConVar("sv_vote_timer_duration").IntValue);

	// Client is voting for
	FakeClientCommand(client, "Vote Yes");
}

public void VoteActionHandler(Handle vote, BuiltinVoteAction action, int param1, int param2)
{
	switch (action)
	{
		case BuiltinVoteAction_End:
		{
			CloseHandle(vote);
		}
		case BuiltinVoteAction_Cancel:
		{
			DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Generic);
		}
	}
}

public void KickSpecsVoteResultHandler(Handle vote, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
	for (int i = 0; i < num_items; i++)
	{
		if (item_info[i][BUILTINVOTEINFO_ITEM_INDEX] == BUILTINVOTES_VOTE_YES)
		{
			if (item_info[i][BUILTINVOTEINFO_ITEM_VOTES] > (num_clients / 2))
			{
				char buffer[64];
				FormatEx(buffer, sizeof(buffer), "%T", "KickSpecsVoteSuccess", LANG_SERVER);
				DisplayBuiltinVotePass(vote, buffer);
				
				float delay = FindConVar("sv_vote_command_delay").FloatValue;
				CreateTimer(delay, Timer_KickSpecs);
				return;
			}
		}
	}

	DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
}

public Action Timer_KickSpecs(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i)) { continue; }
		if (GetClientTeam(i) != L4D2Team_Spectator) { continue; }
		if (IsClientCaster(i)) { continue; }
		if (GetUserAdmin(i) != INVALID_ADMIN_ID) { continue; }
					
		KickClient(i, "%t", "KickSpecsReason");
	}
}