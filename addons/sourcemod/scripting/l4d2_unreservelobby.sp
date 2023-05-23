#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <left4dhooks>

#define PLUGIN_NAME				"L4D 1/2 Remove Lobby Reservation"
#define PLUGIN_AUTHOR			"Downtown1, Anime4000, sorallll"
#define PLUGIN_DESCRIPTION		"Removes lobby reservation when server is full"
#define PLUGIN_VERSION			"2.0.1"
#define PLUGIN_URL				"http://forums.alliedmods.net/showthread.php?t=87759"

ConVar
	g_cvUnreserve,
	g_cvAutoLobby,
	g_cvSvAllowLobbyCo;

bool
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
	CreateConVar("l4d_unreserve_version", PLUGIN_VERSION, "Version of the Lobby Unreserve plugin.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_cvUnreserve =			CreateConVar("l4d_unreserve_full",	"1",	"Automatically unreserve server after a full lobby joins", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_cvAutoLobby =			CreateConVar("l4d_autolobby",		"1",	"Automatically adjust sv_allow_lobby_connect_only. When lobby full it set to 0, when server empty it set to 1", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_cvSvAllowLobbyCo =	FindConVar("sv_allow_lobby_connect_only");

	g_cvUnreserve.AddChangeHook(CvarChanged);
	g_cvAutoLobby.AddChangeHook(CvarChanged);

	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);

	RegAdminCmd("sm_unreserve", cmdUnreserve, ADMFLAG_BAN, "sm_unreserve - manually force removes the lobby reservation");
}

Action cmdUnreserve(int client, int args) {
	if (!g_sReservation[0] && L4D_LobbyIsReserved())
		L4D_GetLobbyReservation(g_sReservation, sizeof g_sReservation);

	L4D_LobbyUnreserve();
	SetAllowLobby(0);
	ReplyToCommand(client, "[UL] Lobby reservation has been removed.");
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

public void OnClientPutInServer(int client) {
	if (!g_bUnreserve)
		return;

	if (IsFakeClient(client))
		return;

	if (!IsServerLobbyFull(-1))
		return;

	if (!g_sReservation[0] && L4D_LobbyIsReserved())
		L4D_GetLobbyReservation(g_sReservation, sizeof g_sReservation);

	L4D_LobbyUnreserve();
	SetAllowLobby(0);
}

//OnClientDisconnect will fired when changing map, issued by gH0sTy at http://docs.sourcemod.net/api/index.php?fastload=show&id=390&
void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client)
		return;

	if (IsFakeClient(client))
		return;

	if (IsServerLobbyFull(client))
		return;

	if (g_sReservation[0])
		L4D_SetLobbyReservation(g_sReservation);

	SetAllowLobby(1);
}

bool IsServerLobbyFull(int client) {
	return GetConnectedPlayer(client) >= numSlots();
}

int numSlots() {
	return LoadFromAddress(L4D_GetPointer(POINTER_SERVER) + view_as<Address>(L4D_GetServerOS() ? 380 : 384), NumberType_Int32);
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