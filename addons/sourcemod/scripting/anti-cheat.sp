#include <ripext>
#include <sourcemod>

int sync_is_running = 0;
int server_ping_is_running = 0;

String:AreNotUsing[30][25];

public Plugin myinfo =
{
	name		= "L4D2 - Anti-cheat",
	author		= "Altair Sossai",
	description = "Custom anti-cheat designed to capture information directly in the user's client",
	version		= "1.0.0",
	url			= "https://github.com/altair-sossai/l4d2-server-manager-client"
};

ConVar cvar_anti_cheat_endpoint;
ConVar cvar_anti_cheat_access_token;

public void OnPluginStart()
{
	cvar_anti_cheat_endpoint = CreateConVar("anti_cheat_endpoint", "https://l4d2-server-manager-api.azurewebsites.net", "Anti-cheat endpoint", FCVAR_PROTECTED);
	cvar_anti_cheat_access_token = CreateConVar("anti_cheat_access_token", "", "Anti-cheat Access Token", FCVAR_PROTECTED);

	RegAdminCmd("sm_addsusp", AddSuspected, ADMFLAG_BAN);
	RegAdminCmd("sm_addallsusp", AddAllSuspected, ADMFLAG_BAN);
	RegAdminCmd("sm_remsusp", RemoveSuspected, ADMFLAG_BAN);

	HookEvent("player_team", PlayerTeam_Event);

	CreateTimer(30.0, RefreshSuspectsListTick, _, TIMER_REPEAT);
	CreateTimer(4.0, MoveToSpectatedPlayersWithoutAntiCheatTick, _, TIMER_REPEAT);
	CreateTimer(60.0, ServerPingTick, _, TIMER_REPEAT);
	
	RefreshSuspectsList();
	ServerPing();
}

public OnClientPutInServer(client)
{
	RefreshSuspectsList();
	RegisterPlayerIp(client);
}

public Action:AddSuspected(client, args)
{
	decl String:suspected[64];
	GetCmdArgString(suspected, sizeof(suspected));

	JSONObject command = new JSONObject();
	command.SetString("account", suspected);

	HTTPRequest request = BuildHTTPRequest("/api/suspected-players");
	request.Post(command, AddSuspectedResponse);
}

public Action:AddAllSuspected(param1, args)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || IsFakeClient(client))
			continue;

		int clientTeam = GetClientTeam(client);
		if (clientTeam != 2 && clientTeam != 3)
			continue;

		new String:communityId[25];
		GetClientAuthId(client, AuthId_SteamID64, communityId, sizeof(communityId));

		JSONObject command = new JSONObject();
		command.SetString("account", communityId);

		HTTPRequest request = BuildHTTPRequest("/api/suspected-players");
		request.Post(command, AddSuspectedResponse);
	}
}

void AddSuspectedResponse(HTTPResponse httpResponse, any value)
{
	if (httpResponse.Status != HTTPStatus_OK)
	{
		PrintToChatAll("\x04Falha ao adicionar jogador suspeito.");
		return;
	}

	JSONObject response = view_as<JSONObject>(httpResponse.Data);

	new String:name[255];
	response.GetString("name", name, sizeof(name));
	PrintToChatAll("\x04%s\x01 adicionado como suspeito.", name);

	RefreshSuspectsList();
}

public Action:RemoveSuspected(client, args)
{
	decl String:suspected[64];
	GetCmdArgString(suspected, sizeof(suspected));

	JSONObject command = new JSONObject();
	command.SetString("account", suspected);

	HTTPRequest request = BuildHTTPRequest("/api/suspected-players/delete");
	request.Post(command, RemoveSuspectedResponse);
}

void RemoveSuspectedResponse(HTTPResponse httpResponse, any value)
{
	if (httpResponse.Status != HTTPStatus_OK)
	{
		PrintToChatAll("\x04Falha ao remover jogador suspeito.");
		return;
	}

	PrintToChatAll("\x03Jogador removido da lista de suspeito.");

	RefreshSuspectsList();
}

public PlayerTeam_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	RefreshSuspectsList();
}

public Action RefreshSuspectsListTick(Handle timer)
{
	sync_is_running = 0;

	RefreshSuspectsList();

	return Plugin_Continue;
}

public Action MoveToSpectatedPlayersWithoutAntiCheatTick(Handle timer)
{
	MoveToSpectatedPlayersWithoutAntiCheat();

	return Plugin_Continue;
}

public Action ServerPingTick(Handle timer)
{
	server_ping_is_running = 0;

	if (NumberOfConnectedPlayers() > 0)
		ServerPing();

	return Plugin_Continue;
}

public void RefreshSuspectsList()
{
	if (sync_is_running == 1)
		return;

	sync_is_running = 1;

	JSONObject command = new JSONObject();
	JSONArray suspecteds = new JSONArray();

	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || IsFakeClient(client))
			continue;

		int clientTeam = GetClientTeam(client);
		if (clientTeam != 1 && clientTeam != 2 && clientTeam != 3)
			continue;

		new String:communityId[25];
		GetClientAuthId(client, AuthId_SteamID64, communityId, sizeof(communityId));

		suspecteds.PushString(communityId);
	}

	command.Set("suspecteds", suspecteds);

	HTTPRequest request = BuildHTTPRequest("/api/suspected-players-activity/check-anti-cheat-usage");
	request.Post(command, RefreshSuspectsListResponse);
}

void RefreshSuspectsListResponse(HTTPResponse httpResponse, any value)
{
	sync_is_running = 0;

	if (httpResponse.Status != HTTPStatus_OK)
		return;

	for (int i = 0; i < 30; i++)
		AreNotUsing[i] = "";

	JSONObject response = view_as<JSONObject>(httpResponse.Data);
	JSONArray areNotUsing = view_as<JSONArray>(response.Get("areNotUsing"));

	for (int i = 0; i < areNotUsing.Length; i++)
	{
		JSONObject suspectedPlayer = view_as<JSONObject>(areNotUsing.Get(i));

		new String:communityId[25];
		suspectedPlayer.GetString("communityId", communityId, sizeof(communityId));

		AreNotUsing[i] = communityId;
	}

	MoveToSpectatedPlayersWithoutAntiCheat();
}

public void ServerPing()
{
	if (server_ping_is_running == 1)
		return;

	server_ping_is_running = 1;

	JSONObject command = new JSONObject();
	HTTPRequest request = BuildHTTPRequest("/api/server-ping");
	request.Post(command, ServerPingResponse);
}

void ServerPingResponse(HTTPResponse httpResponse, any value)
{
	server_ping_is_running = 0;
}

void RegisterPlayerIp(client)
{
	if (!IsClientInGame(client) || IsFakeClient(client))
		return;

	JSONObject command = new JSONObject();
	
	new String:communityId[25];
	GetClientAuthId(client, AuthId_SteamID64, communityId, sizeof(communityId));
	command.SetString("communityId", communityId);

	new String:ip[32];
	GetClientIP(client, ip, sizeof(ip));
	command.SetString("ip", ip);

	HTTPRequest request = BuildHTTPRequest("/api/player-ip");
	request.Post(command, RegisterPlayerIpResponse);
}

void RegisterPlayerIpResponse(HTTPResponse httpResponse, any value)
{
	if (httpResponse.Status != HTTPStatus_OK)
		return;

	JSONObject response = view_as<JSONObject>(httpResponse.Data);
	JSONArray withSameIp = view_as<JSONArray>(response.Get("withSameIp"));
	if (withSameIp.Length == 0)
		return;

	JSONObject player = view_as<JSONObject>(response.Get("player"));

	char playerName[256];
	player.GetString("name", playerName, sizeof(playerName));

	PrintToChatAll("******************************************");
	PrintToChatAll("\x01O jogador \x03%s\x01 utiliza o mesmo IP do(s) jogador(es) abaixo:", playerName);

	for (int i = 0; i < withSameIp.Length; i++)
	{
		JSONObject sameIp = view_as<JSONObject>(withSameIp.Get(i));
		
		char name[256];
		sameIp.GetString("name", name, sizeof(name));

		char profileUrl[256];
		sameIp.GetString("profileUrl", profileUrl, sizeof(profileUrl));

		PrintToChatAll("\x04%s: \x01%s", name, profileUrl);
	}

	PrintToChatAll("******************************************");
}

public void MoveToSpectatedPlayersWithoutAntiCheat()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || IsFakeClient(client))
			continue;

		int clientTeam = GetClientTeam(client);
		if (clientTeam != 2 && clientTeam != 3)
			continue;

		new String:communityId[25];
		GetClientAuthId(client, AuthId_SteamID64, communityId, sizeof(communityId));

		for (int i = 0; i < 30; i++)
		{
			if(StrEqual(AreNotUsing[i], ""))
				break;

			if(!StrEqual(AreNotUsing[i], communityId))
				continue;

			ChangeClientTeam(client, 1);
			PrintToChat(client, "******************************************");
			PrintToChat(client, "Você foi movido para a lista de suspeitos.");
			PrintToChat(client, "Para continuar jogando instale o Anti-cheat.");
			PrintToChat(client, "\x04Download: \x03https://zeatslauncherstorage.blob.core.windows.net/installers/l4d2-anti-cheat.exe");
			PrintToChat(client, "******************************************");

			break;
		}
	}
}

int NumberOfConnectedPlayers()
{
	int players = 0;

	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || IsFakeClient(client))
			continue;

		int clientTeam = GetClientTeam(client);
		if (clientTeam != 1 && clientTeam != 2 && clientTeam != 3)
			continue;

		players++;
	}

	return players;
}

HTTPRequest BuildHTTPRequest(char[] path)
{
	new String:endpoint[255];
	GetConVarString(cvar_anti_cheat_endpoint, endpoint, sizeof(endpoint));
	StrCat(endpoint, sizeof(endpoint), path);

	new String:access_token[100];
	GetConVarString(cvar_anti_cheat_access_token, access_token, sizeof(access_token));

	HTTPRequest request = new HTTPRequest(endpoint);
	request.SetHeader("Authorization", access_token);

	return request;
}