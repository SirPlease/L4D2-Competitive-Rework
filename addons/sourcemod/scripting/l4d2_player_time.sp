#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <ripext>
#include <colors>

#define HOST_PATH					"http://api.steampowered.com"
#define TOTAL_PLAYTIME_URL			"IPlayerService/GetOwnedGames/v1/?format=json&appids_filter[0]=550"
#define REAL_PLAYTIME_URL			"ISteamUserStats/GetUserStatsForGame/v2/?appid=550"
#define VALVEKEY					"C7B3FC46E6E6D5C87700963F0688FCB4"

enum struct PlayerStruct {
	int totalplaytime;
	int realplaytime;
	int last2weektime;
	bool Displayed;
}
PlayerStruct player[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = "[L4D2]时长检测",
	author = "奈",
	description = "display time",
	version = "1.3",
	url = "https://github.com/NanakaNeko/l4d2_plugins_coop"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_time", Display_Time, "查询自己游戏时间");
	RegConsoleCmd("sm_alltime", Display_AllTime, "查询所有人游戏时间");
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
}

public void OnClientPostAdminCheck(int client)
{
	if(IsValidClient(client) && !IsFakeClient(client) && !player[client].Displayed)
	{
		GetPlayerTime(client);
		CreateTimer(3.0, announcetime, client);
	}
}

public Action Display_Time(int client, int args)
{
	if(IsValidClient(client) && !IsFakeClient(client))
	{
		GetPlayerTime(client);
		DisplayTime(client);
	}
	return Plugin_Handled;
}

public Action Display_AllTime(int client, int args)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && !IsFakeClient(i))
		{
			GetPlayerTime(i);
			DisplayTime2(client, i);
		}
	}
	
	return Plugin_Handled;
}

public Action announcetime(Handle timer, int client)
{
	if(IsValidClient(client) && !IsFakeClient(client))
	{
		DisplayTime(client);
		player[client].Displayed = true;
	}
	return Plugin_Continue;
}

void DisplayTime(int client)
{
	if(player[client].totalplaytime || player[client].realplaytime || player[client].last2weektime)
		CPrintToChatAll("{default}[{green}时长检测{default}] {olive}玩家{blue}%N{olive}总游玩时间:{green}%.1f小时{olive}(实际:{green}%.1f小时{olive}),最近两周时间:{green}%.1f小时",client, player[client].totalplaytime/60.0, player[client].realplaytime/60.0, player[client].last2weektime/60.0);
	else
		CPrintToChatAll("{default}[{green}时长检测{default}] {olive}玩家{blue}%N{olive}游玩时间:{green}未知",client);
}

void DisplayTime2(int show, int client)
{
	if(player[client].totalplaytime || player[client].realplaytime || player[client].last2weektime)
		CPrintToChat(show, "{default}[{green}时长检测{default}] {olive}玩家{blue}%N{olive}总游玩时间:{green}%.1f小时{olive}(实际:{green}%.1f小时{olive}),最近两周时间:{green}%.1f小时",client, player[client].totalplaytime/60.0, player[client].realplaytime/60.0, player[client].last2weektime/60.0);
	else
		CPrintToChat(show, "{default}[{green}时长检测{default}] {olive}玩家{blue}%N{olive}游玩时间:{green}未知",client);
}

void GetPlayerTime(int client)
{
	char authId64[65], URL[1024];
	GetClientAuthId(client, AuthId_SteamID64, authId64, sizeof(authId64));
	if(StrEqual(authId64,"STEAM_ID_STOP_IGNORING_RETVALS")) return;
	HTTPClient httpClient = new HTTPClient(HOST_PATH);
	Format(URL,sizeof(URL),"%s&key=%s&steamid=%s",TOTAL_PLAYTIME_URL,VALVEKEY,authId64);
	httpClient.Get(URL, HTTPResponse_GetOwnedGames, client);
	
	CreateTimer(1.0, GetRealTime, client);
}

public Action GetRealTime(Handle hTimer, int client)
{
	char authId64[65], URL[1024];
	GetClientAuthId(client, AuthId_SteamID64, authId64, sizeof(authId64));
	
	HTTPClient httpClient = new HTTPClient(HOST_PATH);
	Format(URL,sizeof(URL),"%s&key=%s&steamid=%s",REAL_PLAYTIME_URL,VALVEKEY,authId64);
	httpClient.Get(URL, HTTPResponse_GetUserStatsForGame, client);
	return Plugin_Continue;
}

//获取总游戏时长
public void HTTPResponse_GetOwnedGames(HTTPResponse response, int client)
{
	if (response.Status != HTTPStatus_OK || response.Data == null)
	{
		LogError("Failed to retrieve response (GetOwnedGames) - HTTPStatus: %i", view_as<int>(response.Status));
		return;
	}
	
	// go to response body
	JSONObject dataObj = view_as<JSONObject>(view_as<JSONObject>(response.Data).Get("response"));
	
	// invalid json data due to privacy?
	if (!dataObj)
	{
		player[client].totalplaytime = 0;
		player[client].last2weektime = 0;
		return;
	}
	if (!dataObj.Size || !dataObj.HasKey("games") || dataObj.IsNull("games"))
	{
		player[client].totalplaytime = 0;
		player[client].last2weektime = 0;
		delete dataObj;
		return;
	}
	
	// jump to "games" array section
	JSONArray jsonArray = view_as<JSONArray>(dataObj.Get("games"));
	delete dataObj;
	
	// right here is the data requested
	dataObj = view_as<JSONObject>(jsonArray.Get(0));
	
	// playtime is formatted in minutes
	player[client].totalplaytime = dataObj.GetInt("playtime_forever");
	player[client].last2weektime = dataObj.GetInt("playtime_2weeks");
	delete jsonArray;
	delete dataObj;
}

//获取真实时间
public void HTTPResponse_GetUserStatsForGame(HTTPResponse response, int client)
{	
	if (response.Status != HTTPStatus_OK || response.Data == null)
	{
		LogError("Failed to retrieve response (GetUserStatsForGame) - HTTPStatus: %i", view_as<int>(response.Status));
		
		// seems chances that this error represents privacy as well.
		if (response.Status == HTTPStatus_InternalServerError)
		{
			player[client].realplaytime = 0;
		}
		
		return;
	}
	
	// go to response body
	JSONObject dataObj = view_as<JSONObject>(view_as<JSONObject>(response.Data).Get("playerstats"));
	
	// invalid json data due to privacy?
	if (dataObj)
	{
		if ( !dataObj.Size
			|| !dataObj.HasKey("stats")
			|| dataObj.IsNull("stats") )
		{
			player[client].realplaytime = 0;
			delete dataObj;
			return;
		}
	}
	else
	{
		player[client].realplaytime = 0;
		return;
	}
	
	// jump to "stats" array section
	JSONArray jsonArray = view_as<JSONArray>(dataObj.Get("stats"));
	
	char keyname[64];
	int size = jsonArray.Length;
	for (int i = 0; i < size; i++)
	{
		delete dataObj;
		dataObj = view_as<JSONObject>(jsonArray.Get(i));
		
		if ( dataObj.GetString("name", keyname, sizeof(keyname))
			&& strcmp(keyname, "Stat.TotalPlayTime.Total") == 0 )
		{
			// playtime is formatted in seconds
			player[client].realplaytime = dataObj.GetInt("value")/60;
			break;
		}
	}
	
	delete jsonArray;
	delete dataObj;
}

//玩家离开游戏
public void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event,"userid"));

	if (!(1 <= client <= MaxClients))
		return;

	if (IsFakeClient(client))
		return;

	player[client].totalplaytime = 0;
	player[client].realplaytime = 0;
	player[client].last2weektime = 0;
	player[client].Displayed = false;
}

stock bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}
