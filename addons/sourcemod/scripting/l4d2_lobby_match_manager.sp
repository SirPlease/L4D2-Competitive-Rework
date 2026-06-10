/*
## 关于动态大厅
大厅的部分信息是保存在客户端，最先进入服务器的玩家是大厅厅长(CSysSessionHost)，其他玩家加入服务器会和大厅厅长通信，判断是否能进入服务器(CSysSessionHost::Process_RequestJoinData)
大厅厅长那边的数据如何更新和继承尚不清楚，这些都发生在客户端运行的 matchmaking.so 中，服务端无法干涉。
在客户端启动项参数加上-debug -dev，客户端控制台输入 mm_debugprint 命令会看到更多信息
*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>
#include <sourcescramble>			// https://github.com/nosoop/SMExt-SourceScramble
#include <l4d2_source_keyvalues>	// https://github.com/fdxx/l4d2_source_keyvalues

#define VERSION "0.8"

#define RMFLAG_NO_MODE_CHANGE			1
#define RMFLAG_NO_DIFFICULTY_CHANGE		2
#define RMFLAG_FORCE_ACCESS_PUBLIC		4	// private, friends -> public
#define RMFLAG_FORCE_OFFICIAL_MAP		8	// unofficial map -> official map

#define UNRESERVE_ALWAYS	1
#define UNRESERVE_WHEN_FULL	2
#define UNRESERVE_DEFAULT_EMPTY	3

#define MAX_COOKIE_LENGTH	20

ConVar
	mp_gamemode,
	z_difficulty,
	sv_allow_lobby_connect_only,
	sv_hosting_lobby,
	sv_reservation_timeout,
	g_cvUnreserveType,
	g_cvReserveModifyFlags;

char
	g_sGameMode[64],
	g_sDifficulty[64];

MemoryPatch
	g_mBlockReserve;

int
	g_iUnreserveType,
	g_iReserveModifyFlags;

bool
	g_bLobbyReservationObserved;

Address
	g_pMatchExtL4D,
	g_pReservationCookie;

Handle
	g_hSDKUpdateGameType,
	g_hSDKGetGameModeInfo,
	g_hSDKGetMapInfo;

public Plugin myinfo = 
{
	name = "L4D2 Lobby match manager",
	author = "fdxx",
	version = VERSION,
	url = "https://github.com/fdxx/l4d2_plugins"
};

public void OnPluginStart()
{
	Init();

	mp_gamemode = FindConVar("mp_gamemode");
	z_difficulty = FindConVar("z_difficulty");
	sv_allow_lobby_connect_only = FindConVar("sv_allow_lobby_connect_only");
	sv_hosting_lobby = FindConVar("sv_hosting_lobby");
	sv_reservation_timeout = FindConVar("sv_reservation_timeout");

	CreateConVar("l4d2_lobby_match_manager_version", VERSION, "version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_cvUnreserveType =			CreateConVar("l4d2_lmm_unreserve_type",				"3",	"0=Keep reservation, 1=Always unreserve and reject reservations, 2=Unreserve when lobby full, 3=Default/no mode: clear stale reservation while empty, but keep player-created lobby matchmaking.");
	g_cvReserveModifyFlags =	CreateConVar("l4d2_lmm_reservation_modify_flags",	"7",	"Modify the lobby settings applied by the client to the server.\nSee RMFLAG_* (need cvar l4d2_lmm_unreserve_type != 1).");
	
	OnConVarChanged(null, "", "");
	
	mp_gamemode.AddChangeHook(OnConVarChanged);
	z_difficulty.AddChangeHook(OnConVarChanged);
	g_cvUnreserveType.AddChangeHook(OnConVarChanged);
	g_cvReserveModifyFlags.AddChangeHook(OnConVarChanged);

	RegAdminCmd("sm_lobby_status", Cmd_Status, ADMFLAG_ROOT);
	RegAdminCmd("sm_lobby_set", Cmd_Set, ADMFLAG_ROOT);
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	mp_gamemode.GetString(g_sGameMode, sizeof(g_sGameMode));
	z_difficulty.GetString(g_sDifficulty, sizeof(g_sDifficulty));
	g_iUnreserveType = g_cvUnreserveType.IntValue;
	g_iReserveModifyFlags = g_cvReserveModifyFlags.IntValue;

	g_mBlockReserve.Disable();
	if (g_iUnreserveType == UNRESERVE_ALWAYS)
	{
		OnConfigsExecuted();
		if (!g_mBlockReserve.Enable())
			SetFailState("Failed to enable patch.");
	}
	else if (g_iUnreserveType == UNRESERVE_DEFAULT_EMPTY)
	{
		ClearDefaultLobbyIfIdle(false);
	}
}

public void OnConfigsExecuted()
{
	sv_reservation_timeout.IntValue = 30;
	
	if (g_iUnreserveType == UNRESERVE_ALWAYS)
	{
		SetReservationCookie(false);
		sv_allow_lobby_connect_only.BoolValue = false;
	}
	else if (g_iUnreserveType == UNRESERVE_DEFAULT_EMPTY)
	{
		ClearDefaultLobbyIfIdle(false);
	}
}

MRESReturn OnApplyGameSettingsPre(Address pThis, DHookParam hParams)
{
	if (g_iUnreserveType == UNRESERVE_ALWAYS || hParams.IsNull(1))
		return MRES_Ignored;

	char sBuffer[256];
	SourceKeyValues kv = view_as<SourceKeyValues>(hParams.GetAddress(1));

	kv.GetName(sBuffer, sizeof(sBuffer));
	if (strcmp(sBuffer, "left4dead2", false)) // Exclude ExecGameTypeCfg
		return MRES_Ignored;

	g_bLobbyReservationObserved = true;

	if (!g_iReserveModifyFlags)
		return MRES_Ignored;

	if (g_iReserveModifyFlags & RMFLAG_NO_MODE_CHANGE)
		kv.SetString("Game/mode", g_sGameMode);

	if (g_iReserveModifyFlags & RMFLAG_NO_DIFFICULTY_CHANGE)
		kv.SetString("Game/difficulty", g_sDifficulty);

	if (g_iReserveModifyFlags & RMFLAG_FORCE_ACCESS_PUBLIC)
		kv.SetString("System/access", "public");

	if (g_iReserveModifyFlags & RMFLAG_FORCE_OFFICIAL_MAP)
	{
		if (IsNeedForceOfficialMap(kv))
		{
			kv.SetString("Game/campaign", "L4D2C2");
			kv.SetInt("Game/chapter", 1);
		}
	}

	return MRES_Ignored;
}

bool IsNeedForceOfficialMap(SourceKeyValues kvSettings)
{
	char sApplyCampaign[256], sApplyMap[256], sCurMap[256];
	kvSettings.GetString("Game/campaign", sApplyCampaign, sizeof(sApplyCampaign));

	// Allow changes to official maps.
	if (!strncmp(sApplyCampaign, "L4D2C", 5, false))
		return false;

	SourceKeyValues kvMapInfo = SDKCall(g_hSDKGetMapInfo, g_pMatchExtL4D, kvSettings, 0);
	if (!kvMapInfo)
		return false;

	kvMapInfo.GetString("Map", sApplyMap, sizeof(sApplyMap));
	GetCurrentMap(sCurMap, sizeof(sCurMap));

	// if the client changed the map.
	return strcmp(sApplyMap, sCurMap) != 0;
}

public void OnClientPutInServer(int client)
{
	if (IsFakeClient(client))
		return;

	if (HasReservationCookie())
		g_bLobbyReservationObserved = true;

	if (g_iUnreserveType == UNRESERVE_WHEN_FULL)
		CreateTimer(1.0, Timer_ClearLobbyIfFull, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public void OnClientDisconnect(int client)
{
	if (IsFakeClient(client))
		return;

	if (g_iUnreserveType == UNRESERVE_DEFAULT_EMPTY)
		CreateTimer(1.0, Timer_ClearDefaultLobbyIfEmpty, _, TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_ClearDefaultLobbyIfEmpty(Handle timer)
{
	ClearDefaultLobbyIfIdle(true);
	return Plugin_Stop;
}

Action Timer_ClearLobbyIfFull(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (client < 1 || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Stop;

	if (g_iUnreserveType != UNRESERVE_WHEN_FULL)
		return Plugin_Stop;

	if (GetPlayerCount() >= GetMaxLobbySlots(g_sGameMode))
	{
		SetReservationCookie(false);
		sv_allow_lobby_connect_only.BoolValue = false;
	}

	return Plugin_Stop;
}

void ClearDefaultLobbyIfIdle(bool forceClearObserved)
{
	if (g_iUnreserveType != UNRESERVE_DEFAULT_EMPTY || GetPlayerCount() > 0)
		return;

	if (!forceClearObserved && g_bLobbyReservationObserved)
		return;

	SetReservationCookie(false);
	sv_allow_lobby_connect_only.BoolValue = false;
}

Action Cmd_Status(int client, int args)
{
	int iCookie[2];
	char sCookie[MAX_COOKIE_LENGTH];

	GetReservationCookie(iCookie);
	if (iCookie[1])
		FormatEx(sCookie, sizeof(sCookie), "%x%08x", iCookie[1], iCookie[0]);
	else 
		FormatEx(sCookie, sizeof(sCookie), "%x", iCookie[0]);

	ReplyToCommand(client, "g_iUnreserveType = %i, iPlayers = %i, iMaxLobbySlots = %i, sv_allow_lobby_connect_only = %i, sCookie = %s", g_iUnreserveType, GetPlayerCount(), GetMaxLobbySlots(g_sGameMode), sv_allow_lobby_connect_only.IntValue, sCookie);
	return Plugin_Handled;
}

Action Cmd_Set(int client, int args)
{
	if (args != 4)
	{
		ReplyToCommand(client, "sm_lobby_set sCookie bAllowLobbyConnectOnly bHostingLobby bUpdateGameType");
		return Plugin_Handled;
	}

	int iCookie[2];
	char sCookie[MAX_COOKIE_LENGTH];

	GetCmdArg(1, sCookie, sizeof(sCookie));
	StringToInt64(sCookie, iCookie, 16);
	StoreToAddress(g_pReservationCookie, iCookie[0], NumberType_Int32);
	StoreToAddress(g_pReservationCookie + view_as<Address>(4), iCookie[1], NumberType_Int32);

	sv_allow_lobby_connect_only.BoolValue = GetCmdArgInt(2) > 0;
	sv_hosting_lobby.BoolValue = GetCmdArgInt(3) > 0;
	
	if (GetCmdArgInt(4) > 0)
		SDKCall(g_hSDKUpdateGameType);

	Cmd_Status(client, 0);
	return Plugin_Handled;
}

int GetPlayerCount(int exclude = 0)
{
	int iPlayers;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i != exclude && IsClientConnected(i) && !IsFakeClient(i))
			iPlayers++;
	}
	return iPlayers;
}

int GetMaxLobbySlots(const char[] mode)
{
	SourceKeyValues kv = SDKCall(g_hSDKGetGameModeInfo, g_pMatchExtL4D, mode);
	if (kv)
		return kv.GetInt("maxplayers", 4);
	return 4;
}

void GetReservationCookie(int cookie[2])
{
	cookie[0] = LoadFromAddress(g_pReservationCookie, NumberType_Int32);
	cookie[1] = LoadFromAddress(g_pReservationCookie + view_as<Address>(4), NumberType_Int32);
}

bool HasReservationCookie()
{
	int cookie[2];
	GetReservationCookie(cookie);
	return cookie[0] != 0 || cookie[1] != 0;
}

void SetReservationCookie(bool reservation, const int cookie[2]={0, 0})
{
	StoreToAddress(g_pReservationCookie, cookie[0], NumberType_Int32);
	StoreToAddress(g_pReservationCookie + view_as<Address>(4), cookie[1], NumberType_Int32);
	SDKCall(g_hSDKUpdateGameType);
	sv_hosting_lobby.BoolValue = reservation;
	g_bLobbyReservationObserved = reservation;
}

void Init()
{
	char sBuffer[128];

	strcopy(sBuffer, sizeof(sBuffer), "l4d2_lobby_match_manager");
	GameData hGameData = new GameData(sBuffer);
	if (hGameData == null)
		SetFailState("Failed to load \"%s.txt\" gamedata.", sBuffer);

	strcopy(sBuffer, sizeof(sBuffer), "CServerGameDLL::ApplyGameSettings");
	DynamicDetour detour = DynamicDetour.FromConf(hGameData, sBuffer);
	if (detour == null)
		SetFailState("Failed to create DynamicDetour: %s", sBuffer);
	if (!detour.Enable(Hook_Pre, OnApplyGameSettingsPre))
		SetFailState("Failed to detour pre: %s", sBuffer);

	strcopy(sBuffer, sizeof(sBuffer), "CBaseServer::ReplyReservationRequest");
	g_mBlockReserve = MemoryPatch.CreateFromConf(hGameData, sBuffer);
	if (!g_mBlockReserve.Validate())
		SetFailState("Failed to verify patch: %s", sBuffer);
	
	strcopy(sBuffer, sizeof(sBuffer), "g_pMatchExtL4D");
	g_pMatchExtL4D = hGameData.GetAddress(sBuffer);
	if (g_pMatchExtL4D == Address_Null)
		SetFailState("Failed to get address: %s", sBuffer);

	strcopy(sBuffer, sizeof(sBuffer), "CBaseServer::m_nReservationCookie");
	g_pReservationCookie = hGameData.GetAddress(sBuffer);
	if (g_pReservationCookie == Address_Null)
		SetFailState("Failed to get address: %s", sBuffer);

	strcopy(sBuffer, sizeof(sBuffer), "CBaseServer::UpdateGameType");
	StartPrepSDKCall(SDKCall_Server);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, sBuffer);
	g_hSDKUpdateGameType = EndPrepSDKCall();
	if (g_hSDKUpdateGameType == null)
		SetFailState("Failed to create SDKCall: %s", sBuffer);

	strcopy(sBuffer, sizeof(sBuffer), "CMatchExtL4D::GetGameModeInfo");
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, sBuffer);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKGetGameModeInfo = EndPrepSDKCall();
	if (g_hSDKGetGameModeInfo == null)
		SetFailState("Failed to create SDKCall: %s", sBuffer);

	// KeyValues * CMatchExtL4D::GetMapInfo( KeyValues *pSettings, KeyValues **ppMissionInfo )
	strcopy(sBuffer, sizeof(sBuffer), "CMatchExtL4D::GetMapInfo");
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, sBuffer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKGetMapInfo = EndPrepSDKCall();
	if (g_hSDKGetMapInfo == null)
		SetFailState("Failed to create SDKCall: %s", sBuffer);

		

	delete hGameData;
}
