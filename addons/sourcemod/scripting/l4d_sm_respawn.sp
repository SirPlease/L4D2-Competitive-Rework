#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <adminmenu>

#define PLUGIN_VERSION "3.7"

#define CVAR_FLAGS	FCVAR_NOTIFY

public Plugin myinfo =
{
	name = "[L4D1 & L4D2] SM Respawn Improved",
	author = "AtomicStryker & Ivailosp (Modified by Crasher, SilverShot), fork by Dragokas",
	description = "Allows players to be respawned at one's crosshair.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=323220"
};

#define DEBUG 0

#define TEAM_DEFAULT		-1
#define TEAM_SPECTATOR		1
#define TEAM_SURVIVORS 		2
#define TEAM_INFECTED 		3

enum
{
	CVAR_TEAM_SPECTATOR 		= 2,
	CVAR_TEAM_SURVIVORS 		= 4,
	CVAR_TEAM_INFECTED 			= 8,
	CVAR_TEAM_DEAD				= 16,
	CVAR_TEAM_NO_SURVIVOR_BOTS 	= 32,
	CVAR_TEAM_NO_INFECTED_BOTS 	= 64
}

enum SPAWN_POSITION
{
	SPAWN_POSITION_OBSOLETE		= 0,
	SPAWN_POSITION_ORIGIN 		= 1,
	SPAWN_POSITION_CROSSHAIR 	= 2,
	SPAWN_POSITION_VECTOR 		= 4,
	SPAWN_POSITION_SAFEROOM 	= 8,
	SPAWN_POSITION_CONVAR 		= 16,
	SPAWN_POSITION_TAKEOVER_BOT = 32,
	SPAWN_POSITION_TELEPORT_EVEN_IF_TAKEOVER = 64
}

const float DUCK_HEIGHT_DELTA = 18.0;

ConVar g_cvLoadout, g_cvShowAction, g_cvAddTopMenu, g_cvPosition, g_cvTeams, g_cvAccessFlag, g_cvGameMode, g_cvAsGhost;
bool g_bLeft4dead2, g_bMenuAdded, g_bHeartbeatPlugin, g_bVersus, g_bDedicated;
Handle g_hSDK_RespawnPlayer, g_hSDK_GhostPlayer, g_hSDK_StateTransition, g_hSDK_TakeOverBot, g_hSDK_SetHumanSpec; //, g_hSDK_TakeOverZombieBot;
Address g_Address_Respawn, g_Address_ResetStatCondition;
TopMenuObject hAdminSpawnItem;
int g_iDeadBody[MAXPLAYERS+1], g_iRespawnTarget[MAXPLAYERS+1], g_iShowTeams;

native void Heartbeat_SetRevives(int client, int reviveCount, bool reviveLogic = true);

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion evEngine = GetEngineVersion();
	if( evEngine != Engine_Left4Dead && evEngine != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "SM Respawn only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	g_bLeft4dead2 = (evEngine == Engine_Left4Dead2);
	g_bDedicated = IsDedicatedServer();
	CreateNative("SM_Respawn", NATIVE_Respawn);
	MarkNativeAsOptional("Heartbeat_SetRevives");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("l4d_sm_respawn.phrases");
	
	CreateConVar("l4d_sm_respawn2_version", PLUGIN_VERSION, "SM Respawn Version", CVAR_FLAGS | FCVAR_DONTRECORD);
	g_cvLoadout = 		CreateConVar("l4d_sm_respawn_loadout", 		"smg,pistol,pain_pills", "Respawn survivor players with this loadout", CVAR_FLAGS);
	g_cvShowAction = 	CreateConVar("l4d_sm_respawn_showaction", 	"1", 	"Notify in chat and log about the respawn action? (0 - No, 1 - Yes)", CVAR_FLAGS);
	g_cvAddTopMenu = 	CreateConVar("l4d_sm_respawn_adminmenu", 	"1", 	"Add 'Respawn player' item in admin menu under 'Player commands' category? (0 - No, 1 - Yes)", CVAR_FLAGS);
	g_cvPosition = 		CreateConVar("l4d_sm_respawn_position", 	"34", 	"Where to respawn? (1 - next to you or alive player, 2 - at your crosshair, 32 - TakeOver bot firstly. You can combine with SPAWN_POSITION values, see .inc file)", CVAR_FLAGS);
	g_cvTeams = 		CreateConVar("l4d_sm_respawn_teams", 		"78", 	"What teams to display in respawn menu? (2 - Spectators, 4 - Survivors, 8 - Infected, 16 - Dead only, 32 - No surv.bots, 64 - No inf.bots. You can combine)", CVAR_FLAGS);
	g_cvAsGhost = 		CreateConVar("l4d_sm_respawn_ghost",		"1",	"Respawn infected player as ghost? (1 - Yes, No - instant respawn)", CVAR_FLAGS );
	g_cvAccessFlag = 	CreateConVar("l4d_sm_respawn_accessflag",	"d",	"Admin flag(s) required to use the respawn command", CVAR_FLAGS );
	AutoExecConfig(true, "l4d_sm_respawn");
	
	g_cvGameMode = FindConVar("mp_gamemode");
	
	Handle hGameData = LoadGameConfigFile("l4d_respawn_improved");
	if( hGameData == null ) SetFailState("Could not find gamedata file at addons/sourcemod/gamedata/l4d_respawn_improved.txt , you FAILED AT INSTALLING");
	
	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "RoundRespawn") == false )
	{
		SetFailState("Failed to find signature: CTerrorPlayer::RoundRespawn");
	}
	else {
		//PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain); // WTF not work
		g_hSDK_RespawnPlayer = EndPrepSDKCall();
		if( g_hSDK_RespawnPlayer == null ) SetFailState("Failed to create SDKCall: CTerrorPlayer::RoundRespawn");
	}
	
	int iOffset = GameConfGetOffset(hGameData, "RoundRespawn_Offset");
	if( iOffset == -1 ) SetFailState("Failed to load \"RoundRespawn_Offset\" offset.");

	int iByteMatch = GameConfGetOffset(hGameData, "RoundRespawn_Byte");
	if( iByteMatch == -1 ) SetFailState("Failed to load \"RoundRespawn_Byte\" byte.");

	g_Address_Respawn = GameConfGetAddress(hGameData, "RoundRespawn");
	if( !g_Address_Respawn ) SetFailState("Failed to load \"RoundRespawn\" address.");
	
	g_Address_ResetStatCondition = g_Address_Respawn + view_as<Address>(iOffset);
	
	int iByteOrigin = LoadFromAddress(g_Address_ResetStatCondition, NumberType_Int8);
	if( iByteOrigin != iByteMatch ) SetFailState("Failed to load, byte mis-match @ %d (0x%02X != 0x%02X)", iOffset, iByteOrigin, iByteMatch);
	
	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "BecomeGhost") == false )
	{
		LogError("Failed to find signature: CTerrorPlayer::BecomeGhost");
	}
	else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		if( !g_bLeft4dead2 ) PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_GhostPlayer = EndPrepSDKCall();
		if( g_hSDK_GhostPlayer == null ) LogError("Failed to create SDKCall: CTerrorPlayer::BecomeGhost");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "State_Transition") == false )
	{
		LogError("Failed to find signature: CCSPlayer::State_Transition");
	}
	else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_StateTransition = EndPrepSDKCall();
		if( g_hSDK_StateTransition == null ) LogError("Failed to create SDKCall: CCSPlayer::State_Transition");
	}
	
	/* 
	// bugged, require a lot investments to make a walkaround:
	// sometimes you take bot control as a half-class, like boomer + smoker (seen in L4D1, versus):
	// * top of the model is boomer
	// * feet from smoker ^_^
	// * special ability from boomer 
	// * voice from smoker ^_^
	// * cannot move, however, CAN move if "duck" button is pressed.
	
	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "TakeOverZombieBot") == false )
	{
		LogError("Failed to find signature: CTerrorPlayer::TakeOverZombieBot");
	}
	else {
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		g_hSDK_TakeOverZombieBot = EndPrepSDKCall();
		if( g_hSDK_TakeOverZombieBot == null ) LogError("Failed to create SDKCall: CTerrorPlayer::TakeOverZombieBot");
	}
	*/
	
	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "TakeOverBot") == false )
	{
		LogError("Failed to find signature: CTerrorPlayer::TakeOverBot");
	}
	else {
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		g_hSDK_TakeOverBot = EndPrepSDKCall();
		if( g_hSDK_TakeOverBot == null ) LogError("Failed to create SDKCall: CTerrorPlayer::TakeOverBot");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "SetHumanSpec") == false )
	{
		LogError("Failed to find signature: SurvivorBot::SetHumanSpectator");
	}
	else {
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		g_hSDK_SetHumanSpec = EndPrepSDKCall();
		if( g_hSDK_SetHumanSpec == null ) LogError("Failed to create SDKCall: SurvivorBot::SetHumanSpectator");
	}
	
	delete hGameData;
	
	if( g_bLeft4dead2 )
	{
		HookEvent("dead_survivor_visible", Event_DeadSurvivorVisible);
	}
	
	RegConsoleCmd("sm_respawn", 		CmdRespawn, 	"<opt.target(s)> Respawn player(s) at your crosshair. Without argument - opens menu to select players");
	RegConsoleCmd("sm_respawnex", 		CmdRespawnEx,	"<arguments of native>. This command respawns the player with additional options, identical to SM_Respawn() native.");
	
	#if( DEBUG )
		RegAdminCmd("sm_afk",	CmdSpec,	ADMFLAG_ROOT);
		RegAdminCmd("sm_inf",	CmdInf,		ADMFLAG_ROOT);
		RegAdminCmd("sm_sur",	CmdSur,		ADMFLAG_ROOT);
	#endif
	
	g_cvAddTopMenu.AddChangeHook(OnCvarChanged);
	g_cvGameMode.AddChangeHook(OnCvarChanged);
	g_cvTeams.AddChangeHook(OnCvarChanged);
	GetCvars();
	
	OnAdminMenuReady(null);
}

public void OnPluginEnd()
{
	PatchAddress(false);
	RemoveAdminItem();
}

public void OnCvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if( convar == g_cvAddTopMenu )
	{
		OnAdminMenuReady(null);
	}
	GetCvars();
}

void GetCvars()
{
	char sGameMode[16];
	g_cvGameMode.GetString(sGameMode, sizeof(sGameMode));
	g_bVersus = (0 == strcmp(sGameMode, "versus"));
	g_iShowTeams = g_cvTeams.IntValue;
}

public void OnAllPluginsLoaded()
{
	if( GetFeatureStatus(FeatureType_Native, "Heartbeat_SetRevives") == FeatureStatus_Available )
	{
		g_bHeartbeatPlugin = true;
	}
}

public void OnLibraryAdded(const char[] name)
{
	if( strcmp(name, "l4d_heartbeat") == 0 )
	{
		g_bHeartbeatPlugin = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if( strcmp(name, "l4d_heartbeat") == 0 )
	{
		g_bHeartbeatPlugin = false;
	}
	else if( strcmp(name, "adminmenu") == 0 )
	{
		g_bMenuAdded = false;
		hAdminSpawnItem = INVALID_TOPMENUOBJECT;
	}
}

public void OnAdminMenuReady(Handle hTopMenu)
{
	AddAdminItem(hTopMenu);
}

stock void RemoveAdminItem()
{
	AddAdminItem(null, true);
}

void AddAdminItem(Handle hTopMenu, bool bRemoveItem = false)
{
	TopMenu hAdminMenu;
	
	if( hTopMenu != null )
	{
		hAdminMenu = TopMenu.FromHandle(hTopMenu);
	}
	else {
		if( !LibraryExists("adminmenu") || null == (hAdminMenu = GetAdminTopMenu()) )
		{
			return;
		}
	}
	
	if( g_bMenuAdded )
	{
		if( (bRemoveItem || !g_cvAddTopMenu.BoolValue) && hAdminSpawnItem != INVALID_TOPMENUOBJECT )
		{
			hAdminMenu.Remove(hAdminSpawnItem);
			g_bMenuAdded = false;
		}
	}
	else {
		if( g_cvAddTopMenu.BoolValue )
		{
			TopMenuObject hMenuCategory = hAdminMenu.FindCategory(ADMINMENU_PLAYERCOMMANDS);

			if( hMenuCategory )
			{
				char sBits[32];
				g_cvAccessFlag.GetString(sBits, sizeof(sBits));
				int iAccessFlags = ReadFlagString(sBits);
				hAdminSpawnItem = hAdminMenu.AddItem("L4D_SM_RespawnPlayer_Item", AdminMenuSpawnHandler, hMenuCategory, "sm_respawn", iAccessFlags, "Respawn a player at your crosshair");
				g_bMenuAdded = true;
			}
		}
	}
}

public void AdminMenuSpawnHandler(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	if( action == TopMenuAction_SelectOption )
	{
		MenuClientsToSpawn(param);
	}
	else if( action == TopMenuAction_DisplayOption )
	{
		FormatEx(buffer, maxlength, "%T", "Respawn_Player", param);
	}
}

void MenuClientsToSpawn(int client, int item = 0)
{
	Menu menu = new Menu(MenuHandler_MenuListClients, MENU_ACTIONS_DEFAULT);
	menu.SetTitle("%T", "List_Players", client);
	
	int iTargetTeam;
	static char sId[16], name[64];
	
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && IsTeamComply(i) )
		{
			iTargetTeam = GetClientTeam(i);
			
			if( iTargetTeam == TEAM_SPECTATOR && IsFakeClient(i) ) // skip spectator bots
			{
				continue;
			}
			
			FormatEx(sId, sizeof(sId), "%i", GetClientUserId(i));
			FormatEx(name, sizeof(name), "%N%T%T",
				i,
				iTargetTeam == TEAM_SPECTATOR ? "Spectator" : "Dummy", client,
				iTargetTeam != TEAM_SPECTATOR && !IsPlayerAlive(i) ? "Dead" : "Dummy", client
				);
			
			menu.AddItem(sId, name);
		}
	}
	menu.DisplayAt(client, item, MENU_TIME_FOREVER);
}

public int MenuHandler_MenuListClients(Menu menu, MenuAction action, int param1, int param2)
{
	switch( action )
	{
		case MenuAction_End:
			delete menu;
		
		case MenuAction_Select:
		{
			int client = param1;
			int ItemIndex = param2;
			
			static char sUserId[16];
			menu.GetItem(ItemIndex, sUserId, sizeof(sUserId));
			
			int UserId = StringToInt(sUserId);
			int target = GetClientOfUserId(UserId);
			
			if( target && IsClientInGame(target) )
			{
				if( g_bVersus && GetClientTeam(target) == TEAM_SPECTATOR ) // Spectator in versus => allow to choose the desired team
				{
					g_iRespawnTarget[client] = target;
					ShowTeamSelectMenu(client);
					return;
				}
				else {
					vRespawnPlayer(client, target);
				}
			}
			CreateTimer(0.1, Timer_DisplayMenuDelayed, GetClientUserId(client) + (menu.Selection << 16), TIMER_FLAG_NO_MAPCHANGE); // give a time for engine to kick a bot
		}
	}
}

public Action Timer_DisplayMenuDelayed(Handle timer, int data)
{
	int client = GetClientOfUserId(data & 0xFFFF); // data = UserId (UShort) + menu item position (Bit 16+)
	if( client && IsClientInGame(client) )
	{
		MenuClientsToSpawn(client, data >> 16);
	}
}

void ShowTeamSelectMenu(int client)
{
	Menu menu = new Menu(MenuHandler_MenuListTeams, MENU_ACTIONS_DEFAULT);
	menu.SetTitle("%T", "List_Teams", client);
	menu.AddItem("", Translate(client, "%t", "Survivors"));
	menu.AddItem("", Translate(client, "%t", "Infected"));
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_MenuListTeams(Menu menu, MenuAction action, int param1, int param2)
{
	switch( action )
	{
		case MenuAction_End:
			delete menu;
		
		case MenuAction_Select:
		{
			int client = param1;
			int team = param2 + 2; // position starts from 0
			vRespawnPlayer(client, g_iRespawnTarget[client], _, team);
		}
	}
}

public int NATIVE_Respawn(Handle plugin, int numParams)
{
	if( numParams < 1 )
		ThrowNativeError(SP_ERROR_PARAM, "Invalid numParams");
	
	int iTarget = GetNativeCell(1);
	int iClient;
	float vec[3];
	SPAWN_POSITION overridePosition = SPAWN_POSITION_CONVAR;
	int overrideTeam = TEAM_DEFAULT;
	
	if( numParams >= 2 )
	{
		iClient = GetNativeCell(2);
	}
	if( numParams >= 3 )
	{
		overridePosition = GetNativeCell(3);
	}
	if( numParams >= 4 )
	{
		overrideTeam = GetNativeCell(4);
	}
	if( numParams >= 5 )
	{
		GetNativeArray(5, vec, 3);
	}
	return vRespawnPlayer(iClient, iTarget, overridePosition, overrideTeam, vec);
}

public void Event_DeadSurvivorVisible(Event event, const char[] name, bool dontBroadcast)
{
	int iDeadBody = event.GetInt("subject");
	int iDeadPlayer = GetClientOfUserId(event.GetInt("deadplayer"));
	
	if( iDeadPlayer && iDeadBody && IsValidEntity(iDeadBody) )
	{
		g_iDeadBody[iDeadPlayer] = EntIndexToEntRef(iDeadBody);
	}
}

public Action CmdRespawnMenu(int client, int args)
{
	MenuClientsToSpawn(client);
	return Plugin_Handled;
}

public Action CmdSpec(int client, int args)
{
	ChangeClientTeam(client, TEAM_SPECTATOR);
}
public Action CmdSur(int client, int args)
{
	ChangeClientTeam(client, TEAM_SURVIVORS);
}
public Action CmdInf(int client, int args)
{
	ChangeClientTeam(client, TEAM_INFECTED);
}

public Action CmdRespawnEx(int client, int numParams)
{
	client = iGetListenServerHost(client, g_bDedicated);
	
	if( client && !HasCommandAccessFlag(client) )
	{
		ReplyToCommand(client, "No access.");
		return Plugin_Handled;
	}
	if( numParams < 2 )
	{
		ReplyToCommand(client, "sm_respawnex [target] [issuer] <enum.position> <team> <\"vector\">");
		return Plugin_Handled;
	}
	
	char arg[MAX_TARGET_LENGTH], target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count, overrideTeam = TEAM_DEFAULT;
	bool tn_is_ml;
	float vec[3];
	SPAWN_POSITION overridePosition = SPAWN_POSITION_CONVAR;
	
	GetCmdArg(2, arg, sizeof(arg));
	
	int iClient = 0;
	if( (target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) > 0 )
	{
		iClient = target_list[0];
	}
	
	if( numParams >= 3 )
	{
		GetCmdArg(3, arg, sizeof(arg));
		overridePosition = view_as<SPAWN_POSITION>(StringToInt(arg));
	}
	if( numParams >= 4 )
	{
		GetCmdArg(4, arg, sizeof(arg));
		overrideTeam = StringToInt(arg);
	}
	if( numParams >= 5 )
	{
		GetCmdArg(5, arg, sizeof(arg));
		char axis[3][16];
		ExplodeString(arg, " ", axis, sizeof(axis), sizeof(axis[]));
		vec[0] = StringToFloat(axis[0]);
		vec[1] = StringToFloat(axis[1]);
		vec[2] = StringToFloat(axis[2]);
	}
	
	GetCmdArg(1, arg, sizeof(arg));
	
	if( (target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0 )
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for( int i = 0; i < target_count; i++ )
	{
		vRespawnPlayer(iClient, target_list[i], overridePosition, overrideTeam, vec);
	}
	return Plugin_Handled;
}

public Action CmdRespawn(int client, int args)
{
	client = iGetListenServerHost(client, g_bDedicated);

	if( client && !HasCommandAccessFlag(client) )
	{
		ReplyToCommand(client, "No access.");
		return Plugin_Handled;
	}
	if( args < 1 )
	{
		if( GetCmdReplySource() == SM_REPLY_TO_CONSOLE )
		{
			PrintToConsole(client, "[SM] Usage: sm_respawn <player1> [player2] ... [playerN] - respawn all listed players");
		}
		CmdRespawnMenu(client, 0);
		return Plugin_Handled;
	}
	char arg1[MAX_TARGET_LENGTH], target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count, target;
	bool tn_is_ml;
	int goal_team = GetClientTeam(client);
	
	GetCmdArg(1, arg1, sizeof(arg1));
	if( (target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0 )
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for( int i = 0; i < target_count; i++ )
	{
		target = target_list[i];
		
		if( target && IsClientInGame(target) )
		{
			if( goal_team == 1 || goal_team == GetClientTeam(target) )
			{
				vRespawnPlayer(client, target);
			}
		}
	}
	return Plugin_Handled;
}

bool vRespawnPlayer(
	int client,
	int target,
	SPAWN_POSITION overridePosition = SPAWN_POSITION_CONVAR,
	int overrideTeam = TEAM_DEFAULT,
	float vec[3] = {0.0, 0.0, 0.0}
	)
{
	int desiredTeam, iCharacter;
	float ang[3];
	bool bShouldTeleport, bShouldModel, bShouldRespawn = true;
	static char sModel[PLATFORM_MAX_PATH];
	
	SPAWN_POSITION spawnPos;
	
	if( overridePosition == SPAWN_POSITION_CONVAR )
	{
		spawnPos = view_as<SPAWN_POSITION>(g_cvPosition.IntValue);
		
		if( spawnPos == SPAWN_POSITION_OBSOLETE ) // backward compatibility
		{
			spawnPos = SPAWN_POSITION_CROSSHAIR;
		}
	}
	else {
		spawnPos = overridePosition;
	}
	
	if( overrideTeam == TEAM_DEFAULT )
	{
		desiredTeam = GetClientTeam(target);
		
		if( desiredTeam == TEAM_SPECTATOR )
		{
			desiredTeam = TEAM_SURVIVORS;
		}
	}
	else {
		desiredTeam = overrideTeam;
		
		if( desiredTeam == TEAM_SPECTATOR )
		{
			LogError("Wrong team is selected. Cannot respawn as a Spectator.");
			return false;
		}
	}
	
	if( spawnPos & SPAWN_POSITION_CROSSHAIR )
	{
		if( client && GetSpawnEndPoint(client, desiredTeam, vec) )
		{
			bShouldTeleport = true;
		}
	}
	else if( spawnPos & SPAWN_POSITION_ORIGIN )
	{
		if( GetRandomSpawnPos(client, target, desiredTeam, vec) )
		{
			bShouldTeleport = true;
		}
	}
	else if( spawnPos & SPAWN_POSITION_VECTOR )
	{
		bShouldTeleport = true;
	}
	else if( spawnPos & SPAWN_POSITION_SAFEROOM )
	{
		if( desiredTeam == TEAM_SURVIVORS )
		{
			bShouldTeleport = false;
		}
		else {
			int saferoom = FindEntityByClassname(-1, "info_survivor_position"); // prevents infected from stuck in 0 0 0 position
			if( saferoom != -1 )
			{
				GetEntPropVector(saferoom, Prop_Data, "m_vecOrigin", vec);
				bShouldTeleport = true;
			}
		}
	}
	
	if( client )
	{
		GetClientEyeAngles(client, ang);
	}
	
	switch( GetClientTeam(target) ) // firstly, try to takeover / change team, if required
	{
		case TEAM_SPECTATOR:
		{
			if( desiredTeam == TEAM_SURVIVORS )
			{
				int bot = -1;
				if( spawnPos & SPAWN_POSITION_TAKEOVER_BOT )
				{
					bot = FindBotToTakeOver(target, TEAM_SURVIVORS);
					
					if( bot != -1 )
					{
						SDKCall(g_hSDK_SetHumanSpec, bot, target);
						SDKCall(g_hSDK_TakeOverBot, target, true);
					
						if( !(spawnPos & SPAWN_POSITION_TELEPORT_EVEN_IF_TAKEOVER) )
						{
							bShouldTeleport = false;
						}
						bShouldRespawn = false;
					}
				}
				if( bShouldRespawn )
				{
					ChangeClientTeam(target, TEAM_SURVIVORS);
				}
			}
			else if( desiredTeam == TEAM_INFECTED )
			{
				ChangeClientTeam(target, TEAM_INFECTED);
			}
		}
		case TEAM_SURVIVORS:
		{
			if( IsPlayerAlive(target) )
			{
				AcceptEntityInput(target, "clearparent"); // clearparent jockey bug switching teams (thanks to Lux)
				
				iCharacter = GetEntProp(target, Prop_Send, "m_survivorCharacter");
				GetClientModel(target, sModel, sizeof(sModel));
				bShouldModel = true;
			}
			if( desiredTeam == TEAM_INFECTED )
			{
				ChangeClientTeam(target, TEAM_INFECTED);
			}
		}
		case TEAM_INFECTED:
		{
			if( desiredTeam == TEAM_SURVIVORS )
			{
				ChangeClientTeam(target, TEAM_SURVIVORS);
			}
		}
	}
	
	if( bShouldRespawn )
	{
		switch( GetClientTeam(target) )
		{
			case TEAM_SURVIVORS:
			{
				if( IsPlayerAlive(target) )
				{
					StopReviveAction(target); // prevents revive stuck glitch
				}
			
				PatchAddress(true);
				SDKCall(g_hSDK_RespawnPlayer, target);
				PatchAddress(false);
				
				GiveLoadOut(target);
				
				if( bShouldModel )
				{
					SetEntProp(target, Prop_Send, "m_survivorCharacter", iCharacter);
					SetEntityModel(target, sModel);
				}
				
				SetEntProp(target, Prop_Send, "m_bDucked", 1); // force crouch pose to allow respawn in transport / duct ...
				SetEntProp(target, Prop_Send, "m_fFlags", GetEntProp(target, Prop_Send, "m_fFlags") | FL_DUCKING);
				
				if( g_bHeartbeatPlugin )
				{
					Heartbeat_SetRevives(target, 0, false);
				}
			}
			case TEAM_INFECTED:
			{
				if( g_cvAsGhost.IntValue == 1 && !IsFakeClient(target) )
				{
					if( g_bLeft4dead2 )
					{
						SDKCall(g_hSDK_StateTransition, target, 8);
						SDKCall(g_hSDK_GhostPlayer, target, 1);
						SDKCall(g_hSDK_StateTransition, target, 6);
						SDKCall(g_hSDK_GhostPlayer, target, 1);
					}
					else {
						SDKCall(g_hSDK_StateTransition, target, 8);
						SDKCall(g_hSDK_GhostPlayer, target, 6, 1);
						SDKCall(g_hSDK_StateTransition, target, 6);
						SDKCall(g_hSDK_GhostPlayer, target, 6, 1);
					}
				}
				else {
					PatchAddress(true);
					SDKCall(g_hSDK_RespawnPlayer, target);
					PatchAddress(false);
				}
			}
		}
	}
	
	if( GetClientTeam(target) != TEAM_SPECTATOR && IsPlayerAlive(target) )
	{
		if( bShouldTeleport )
		{
			vPerformTeleport(client, target, vec, ang);
		}
		if( g_cvShowAction.BoolValue && client )
		{
			ShowActivity2(client, "[SM] ", "%t", "Respawn_Info", target); // "Respawned player '%N'"
		}
	}
	
	if( g_iDeadBody[target] ) // attempt to remove the old dead body
	{
		int iDeadBody = EntRefToEntIndex(g_iDeadBody[target]);
		
		if( iDeadBody && iDeadBody != INVALID_ENT_REFERENCE && IsValidEntity(iDeadBody) )
		{
			AcceptEntityInput(iDeadBody, "kill");
		}
	}
	return false;
}

void GiveLoadOut(int target)
{
	char sItems[6][64], sLoadout[512];
	
	g_cvLoadout.GetString(sLoadout, sizeof(sLoadout));
	ExplodeString(sLoadout, ",", sItems, sizeof(sItems), sizeof(sItems[]));
	
	for( int iItem = 0; iItem < sizeof(sItems); iItem++ )
	{
		if ( sItems[iItem][0] != '\0' )
		{
			vCheatCommand(target, "give", sItems[iItem]);
		}
	}
}

public bool TraceRay_NoPlayers(int entity, int contentsMask)
{
	return (entity > MaxClients);
}

bool GetSpawnEndPoint(int client, int team, float vSpawnVec[3]) // Returns the position for respawn which is located at the end of client's eyes view angle direction.
{
	float vEnd[3], vEye[3];
	if( GetDirectionEndPoint(client, vEnd) )
	{
		GetClientEyePosition(client, vEye);
		ScaleVectorDirection(vEye, vEnd, 0.1); // get a point which is a little deeper to allow next collision to be happen
		
		if( GetNonCollideEndPoint(client, team, vEnd, vSpawnVec) ) // get position in respect to the player's size
		{
			return true;
		}
	}
	GetClientAbsOrigin(client, vSpawnVec); // if ray methods failed for some reason, just use the command issuer location
	return true;
}

void ScaleVectorDirection(float vStart[3], float vEnd[3], float fMultiple) // lengthens the line which built from vStart to vEnd in vEnd direction and returns new vEnd position
{
    float dir[3];
    SubtractVectors(vEnd, vStart, dir);
    ScaleVector(dir, fMultiple);
    AddVectors(vEnd, dir, vEnd);
}

stock bool GetDirectionEndPoint(int client, float vEndPos[3]) // builds simple ray from the client's eyes origin to vEndPos position and returns new vEndPos of non-collide position
{
	float vDir[3], vPos[3];
	GetClientEyePosition(client, vPos);
	GetClientEyeAngles(client, vDir);
	
	Handle hTrace = TR_TraceRayFilterEx(vPos, vDir, MASK_PLAYERSOLID, RayType_Infinite, TraceRay_NoPlayers);
	if( hTrace )
	{
		if( TR_DidHit(hTrace) )
		{
			TR_GetEndPosition(vEndPos, hTrace);
			delete hTrace;
			return true;
		}
		delete hTrace;
	}
	return false;
}

stock bool GetNonCollideEndPoint(int client, int team, float vEnd[3], float vEndNonCol[3], bool bEyeOrigin = true) // similar to GetDirectionEndPoint, but with respect to player size
{
	float vMin[3], vMax[3], vStart[3];
	if( bEyeOrigin )
	{
		GetClientEyePosition(client, vStart);
		
		if( IsTeamStuckPos(team, vStart) ) // If we attempting to spawn from stucked position, let's start our hull trace from the middle of the ray in hope there are no collision
		{
			float vMiddle[3];
			AddVectors(vStart, vEnd, vMiddle);
			ScaleVector(vMiddle, 0.5);
			vStart = vMiddle;
		}
	}
	else {
		GetClientAbsOrigin(client, vStart);
	}
	GetTeamClientSize(team, vMin, vMax);
	
	Handle hTrace = TR_TraceHullFilterEx(vStart, vEnd, vMin, vMax, MASK_PLAYERSOLID, TraceRay_NoPlayers);
	if( hTrace != INVALID_HANDLE )
	{
		if( TR_DidHit(hTrace) )
		{
			TR_GetEndPosition(vEndNonCol, hTrace);
			delete hTrace;
			if( bEyeOrigin )
			{
				if( IsTeamStuckPos(team, vEndNonCol) ) // if eyes position doesn't allow to build reliable TraceHull, repeat from the feet (client's origin)
				{
					GetNonCollideEndPoint(client, team, vEnd, vEndNonCol, false);
				}
			}
			return true;
		}
		delete hTrace;
	}
	return false;
}

void GetTeamClientSize(int team, float vMin[3], float vMax[3])
{
	if( team == TEAM_SURVIVORS ) // GetClientMins & GetClientMaxs are not reliable when applied to dead or spectator, so we are using pre-defined values per team
	{
		vMin[0] = -16.0; 	vMin[1] = -16.0; 	vMin[2] = 0.0;
		vMax[0] = 16.0; 	vMax[1] = 16.0; 	vMax[2] = 71.0;
	}
	else { // GetClientMins & GetClientMaxs return the same values for infected team, even for Tank! (that's very strange O_o)
		vMin[0] = -16.0; 	vMin[1] = -16.0; 	vMin[2] = 0.0;
		vMax[0] = 16.0; 	vMax[1] = 16.0; 	vMax[2] = 71.0;
	}
}

bool IsTeamStuckPos(int team, float vPos[3], bool bDuck = false) // check if the position applicable to respawn a client of a given size without collision
{
	float vMin[3], vMax[3];
	Handle hTrace;
	bool bHit;
	GetTeamClientSize(team, vMin, vMax);
	if( bDuck )
	{
		vMax[2] -= DUCK_HEIGHT_DELTA;
	}
	hTrace = TR_TraceHullFilterEx(vPos, vPos, vMin, vMax, MASK_PLAYERSOLID, TraceRay_NoPlayers);
	if( hTrace ) {
		bHit = TR_DidHit(hTrace);
		delete hTrace;
	}
	return bHit;
}

bool GetRandomSpawnPos(int client, int target, int team, float vec[3]) // returns the origin of the command issuer if he is alive, otherwise the origin of random player
{
	if( client && IsClientInGame(client) && IsPlayerAlive(client) )
	{
		if( team == -1 || GetClientTeam(client) == team )
		{
			GetClientAbsOrigin(client, vec);
			return true;
		}
	}
	ArrayList al = new ArrayList(ByteCountToCells(4));
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( i != target && i != client && IsClientInGame(i) && GetClientTeam(i) == team && IsPlayerAlive(i) )
		{
			al.Push(i);
		}
	}
	if( al.Length > 0 ) // take the spot next to random player
	{
		client = al.Get(GetRandomInt(0, al.Length - 1));
		GetClientAbsOrigin(client, vec);
		delete al;
		return true;
	}
	delete al;
	return false;
}

void vPerformTeleport(int client, int target, float pos[3], float ang[3])
{
	TeleportEntity(target, pos, ang, NULL_VECTOR);
	if( g_cvShowAction.BoolValue && client )
	{
		LogAction(client, target, "\"%L\" teleported \"%L\" after respawning him" , client, target);
	}
}

void vCheatCommand(int client, char[] command, char[] arguments = "")
{
	int bits = GetUserFlagBits(client);
	int iCmdFlags = GetCommandFlags(command);
	SetCommandFlags(command, iCmdFlags & ~FCVAR_CHEAT);
	SetUserFlagBits(client, ADMFLAG_ROOT); // to prevent conflict with AdminCheats crazy plugin ^_^
	FakeClientCommand(client, "%s %s", command, arguments);
	SetUserFlagBits(client, bits);
	SetCommandFlags(command, iCmdFlags);
}

void PatchAddress(bool patch) // Prevents respawn command from reset the player's statistics
{
	static bool patched;

	if( !patched && patch )
	{
		patched = true;
		StoreToAddress(g_Address_ResetStatCondition, 0x79, NumberType_Int8); // if (!bool) - 0x75 JNZ => 0x78 JNS (jump short if not sign) - always not jump
	}
	else if( patched && !patch )
	{
		patched = false;
		StoreToAddress(g_Address_ResetStatCondition, 0x75, NumberType_Int8);
	}
}

bool IsTeamComply(int client)
{
	int team = GetClientTeam(client);
	if( (1 << team) & g_iShowTeams )
	{
		if( g_iShowTeams & CVAR_TEAM_DEAD )
		{
			if( team != TEAM_SPECTATOR && IsPlayerAlive(client) )
			{
				return false;
			}
		}
		if( g_iShowTeams & CVAR_TEAM_NO_SURVIVOR_BOTS )
		{
			if( team == TEAM_SURVIVORS && IsFakeClient(client) )
			{
				return false;
			}
		}
		if( g_iShowTeams & CVAR_TEAM_NO_INFECTED_BOTS )
		{
			if( team == TEAM_INFECTED && IsFakeClient(client) )
			{
				return false;
			}
		}
		return true;
	}
	return false;
}

void StopReviveAction(int client)
{
	int owner_save = -1;
	int target_save = -1;
	int owner = GetEntPropEnt(client, Prop_Send, "m_reviveOwner"); // when you reviving somebody, this is -1. When somebody revive you, this is somebody's id
	int target = GetEntPropEnt(client, Prop_Send, "m_reviveTarget"); // when you reviving somebody, this is somebody's id. When somebody revive you, this is -1
	SetEntPropEnt(client, Prop_Send, "m_reviveOwner", -1);
	SetEntPropEnt(client, Prop_Send, "m_reviveTarget", -1);
	if( owner != -1 ) // we must reset flag for both - for you, and who you revive
	{
		SetEntPropEnt(owner, Prop_Send, "m_reviveOwner", -1);
		SetEntPropEnt(owner, Prop_Send, "m_reviveTarget", -1);
		owner_save = owner;
	}
	if( target != -1 )
	{
		SetEntPropEnt(target, Prop_Send, "m_reviveOwner", -1);
		SetEntPropEnt(target, Prop_Send, "m_reviveTarget", -1);
		target_save = target;
	}
	
	if( g_bLeft4dead2 )
	{
		owner = GetEntPropEnt(client, Prop_Send, "m_useActionOwner");		// used when healing e.t.c.
		target = GetEntPropEnt(client, Prop_Send, "m_useActionTarget");
		SetEntPropEnt(client, Prop_Send, "m_useActionOwner", -1);
		SetEntPropEnt(client, Prop_Send, "m_useActionTarget", -1);
		if( owner != -1 )
		{
			SetEntPropEnt(owner, Prop_Send, "m_useActionOwner", -1);
			SetEntPropEnt(owner, Prop_Send, "m_useActionTarget", -1);
			owner_save = owner;
		}
		if( target != -1 )
		{
			SetEntPropEnt(target, Prop_Send, "m_useActionOwner", -1);
			SetEntPropEnt(target, Prop_Send, "m_useActionTarget", -1);
			target_save = target;
		}
		
		SetEntProp(client, Prop_Send, "m_iCurrentUseAction", 0);
		SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
		
		if( owner_save != -1 )
		{
			SetEntProp(owner_save, Prop_Send, "m_iCurrentUseAction", 0);
			SetEntPropFloat(owner_save, Prop_Send, "m_flProgressBarDuration", 0.0);
		}
		if( target_save != -1 )
		{
			SetEntProp(target_save, Prop_Send, "m_iCurrentUseAction", 0);
			SetEntPropFloat(target_save, Prop_Send, "m_flProgressBarDuration", 0.0);
		}
	}
	else {
		owner = GetEntPropEnt(client, Prop_Send, "m_healOwner");		// used when healing
		target = GetEntPropEnt(client, Prop_Send, "m_healTarget");
		SetEntPropEnt(client, Prop_Send, "m_healOwner", -1);
		SetEntPropEnt(client, Prop_Send, "m_healTarget", -1);
		if( owner != -1 )
		{
			SetEntPropEnt(owner, Prop_Send, "m_healOwner", -1);
			SetEntPropEnt(owner, Prop_Send, "m_healTarget", -1);
			owner_save = owner;
		}
		if( target != -1 )
		{
			SetEntPropEnt(target, Prop_Send, "m_healOwner", -1);
			SetEntPropEnt(target, Prop_Send, "m_healTarget", -1);
			target_save = target;
		}
		
		SetEntProp(client, Prop_Send, "m_iProgressBarDuration", 0);
		
		if( owner_save != -1 )
		{
			SetEntProp(owner_save, Prop_Send, "m_iProgressBarDuration", 0);
		}
		if( target_save != -1 )
		{
			SetEntProp(target_save, Prop_Send, "m_iProgressBarDuration", 0);
		}
	}
}

bool HasCommandAccessFlag(int client)
{
	int iUserFlag = GetUserFlagBits(client);
	if( iUserFlag & ADMFLAG_ROOT ) return true;
	char sReq[32];
	g_cvAccessFlag.GetString(sReq, sizeof(sReq));
	if( sReq[0] == 0 ) return true;
	int iReqFlags = ReadFlagString(sReq);
	return (iUserFlag & iReqFlags != 0);
}

int FindBotToTakeOver(int target, int team)
{
	static char sNetClass[16];

	int targetUId = GetClientUserId(target);
	
	if( team == TEAM_SURVIVORS ) // if a survivor bot is already belongs to our target (IDLE)
	{
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) && GetClientTeam(i) == team && IsFakeClient(i) && IsPlayerAlive(i) )
			{
				GetEntityNetClass(i, sNetClass, sizeof(sNetClass));
				
				if( strcmp(sNetClass, "SurvivorBot") == 0 ) // there are reports, that team + IsFakeClient check are not enough for some (?) reason. What kind of bot is that???
				{
					if( targetUId == GetEntProp(i, Prop_Send, "m_humanSpectatorUserID") )
					{
						return i;
					}
				}
			}
		}
	}
	for( int i = 1; i <= MaxClients; i++ ) // take any other free bot
	{
		if( IsClientInGame(i) && GetClientTeam(i) == team && IsFakeClient(i) && IsPlayerAlive(i) )
		{
			if( team == TEAM_SURVIVORS )
			{
				GetEntityNetClass(i, sNetClass, sizeof(sNetClass));
				
				if( strcmp(sNetClass, "SurvivorBot") == 0 )
				{
					if( 0 == GetEntProp(i, Prop_Send, "m_humanSpectatorUserID")) // forbid takeover other people's bot
					{
						return i;
					}
				}
			}
			else {
				return i;
			}
		}
	}
	return -1;
}

stock char[] Translate(int client, const char[] format, any ...) // inline translation support
{
	static char buffer[192];
	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), format, 3);
	return buffer;
}

int iGetListenServerHost(int client, bool dedicated) // Thanks to @Marttt
{
	if( client == 0 && !dedicated )
	{
		int iManager = FindEntityByClassname(-1, "terror_player_manager");
		if( iManager != -1 && IsValidEntity(iManager) )
		{
			int iHostOffset = FindSendPropInfo("CTerrorPlayerResource", "m_listenServerHost");
			if( iHostOffset != -1 )
			{
				bool bHost[MAXPLAYERS + 1];
				GetEntDataArray(iManager, iHostOffset, bHost, (MAXPLAYERS + 1), 1);
				for( int iPlayer = 1; iPlayer < sizeof(bHost); iPlayer++ )
				{
					if( bHost[iPlayer] )
					{
						return iPlayer;
					}
				}
			}
		}
	}
	return client;
}