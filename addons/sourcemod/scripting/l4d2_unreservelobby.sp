#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <left4dhooks>

#define PLUGIN_NAME				"L4D 1/2 Remove Lobby Reservation"
#define PLUGIN_AUTHOR			"Downtown1, Anime4000, sorallll"
#define PLUGIN_DESCRIPTION		"Removes lobby reservation when server is full"
#define PLUGIN_VERSION			"2.0.3"
#define PLUGIN_URL				"http://forums.alliedmods.net/showthread.php?t=87759"

ConVar
	g_cvGameMode,
	g_cvUnreserve,
	g_cvAutoLobby,
	g_cvSvAllowLobbyCo;

bool
	g_bManually,
	g_bUnreserve,
	g_bAutoLobby;

char
	g_sReservation[20];

public Plugin myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public void OnPluginStart() {
	CreateConVar("l4d_unreserve_version", PLUGIN_VERSION, "动态大厅插件的版本.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_cvUnreserve =			CreateConVar("l4d_unreserve_full",	"1",	"玩家加入游戏后自动删除大厅匹配(短时间里还是有匹配,因为游戏里删除大厅后还是匹配优先级最高). 0=禁用,1=启用.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_cvAutoLobby =			CreateConVar("l4d_autolobby",		"1",	"自动设置 sv_allow_lobby_connect_only 参数,删除大厅匹配后自动设置为:0,开启大厅匹配后自动设置参数值为:1. 0=禁用,1=启用.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_cvGameMode = 			FindConVar("mp_gamemode");
	g_cvSvAllowLobbyCo =	FindConVar("sv_allow_lobby_connect_only");

	g_cvUnreserve.AddChangeHook(CvarChanged);
	g_cvAutoLobby.AddChangeHook(CvarChanged);

	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);

	RegAdminCmd("sm_unreserve", cmdUnreserve, ADMFLAG_BAN, "sm_unreserve - manually force removes the lobby reservation");

	AutoExecConfig(true, "l4d2_unreservelobby");//生成指定文件名的CFG.
}

Action cmdUnreserve(int client, int args) {
	if (!g_sReservation[0] && L4D_LobbyIsReserved())
		L4D_GetLobbyReservation(g_sReservation, sizeof g_sReservation);

	L4D_LobbyUnreserve();
	SetAllowLobby(0);
	g_bManually = true;
	ReplyToCommand(client, "[提示]当前服务器已删除大厅匹配.");
	return Plugin_Handled;
}

public void OnConfigsExecuted() {
	GetCvars();
}

void CvarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	GetCvars();
}

void GetCvars() {
	g_bUnreserve = g_cvUnreserve.BoolValue;
	g_bAutoLobby = g_cvAutoLobby.BoolValue;
}

public void OnClientConnected(int client) {
	if (g_bManually)
		return;

	if (!g_bUnreserve)
		return;

	if (IsFakeClient(client))
		return;

	if (!IsSessionFull(-1))
		return;

	if (!g_sReservation[0] && L4D_LobbyIsReserved())
		L4D_GetLobbyReservation(g_sReservation, sizeof g_sReservation);

	L4D_LobbyUnreserve();
	SetAllowLobby(0);
}

//OnClientDisconnect will fired when changing map, issued by gH0sTy at http://docs.sourcemod.net/api/index.php?fastload=show&id=390&
void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast) {
	if (g_bManually)
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client)
		return;

	if (IsFakeClient(client))
		return;

	if (IsSessionFull(client))
		return;

	if (g_sReservation[0])
		L4D_SetLobbyReservation(g_sReservation);

	SetAllowLobby(1);
}

bool IsSessionFull(int client) {
	return GetConnectedPlayer(client) >= SessionSlots();
}

// https://developer.valvesoftware.com/wiki/Mutation_Gametype_(L4D2)
int SessionSlots() {
	char sGameMode[32];
	g_cvGameMode.GetString(sGameMode, sizeof sGameMode);
	return (StrContains(sGameMode, "versus") > -1 || StrContains(sGameMode, "scavenge") > -1) ? 8 : 4/*LoadFromAddress(L4D_GetPointer(POINTER_SERVER) + view_as<Address>(L4D_GetServerOS() ? 380 : 384), NumberType_Int32)*/;
}

int GetConnectedPlayer(int client) {
	int count;
	for (int i = 1; i <= MaxClients; i++) {
		if (i != client && IsClientConnected(i) && !IsFakeClient(i))
			count++;
	}
	return count;
}

void SetAllowLobby(int value) {
	if (g_bAutoLobby)
		g_cvSvAllowLobbyCo.IntValue = value;
}
