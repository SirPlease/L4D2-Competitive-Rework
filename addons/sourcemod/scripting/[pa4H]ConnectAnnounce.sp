#include <sourcemod>
#include <sdktools>
#include <geoip>
#include <colors>
#include <ripext> // Rest In Pawn. Либа для работы с http

char PREFIX[16]; char txtBufer[256];

char keyAPI[64]; // Ключ для Steam API

int playTime[MAXPLAYERS + 1]; // Наигранное время

Handle g_hSteamAPI_Key; // Для работы с sm_cvar SteamAPI_Key

public Plugin:myinfo =  {
	name = "Connect Announce", 
	author = "pa4H", 
	description = "", 
	version = "1.0", 
	url = "vk.com/pa4h1337"
};

public OnPluginStart() {
	RegAdminCmd("sm_hoursTest", hoursTest, ADMFLAG_BAN);
	//RegAdminCmd("sm_joinMessage", createJoinMessage, ADMFLAG_BAN);
	
	HookEvent("player_disconnect", PlayerDisconnect_Event, EventHookMode_Pre);
	
	// Создаем sm_cvar SteamAPI_Key
	g_hSteamAPI_Key = CreateConVar("SteamAPI_Key", "", "Your SteamAPI Key. Can get it on https://steamcommunity.com/dev/apikey", FCVAR_CHEAT);
	GetConVarString(g_hSteamAPI_Key, keyAPI, sizeof(keyAPI)); // И сразу его читаем
	HookConVarChange(g_hSteamAPI_Key, OnConVarChange);
	LoadTranslations("pa4HConAnnounce.phrases");
	
	//AutoExecConfig(true, "SteamAPI_Hours"); // Создаем .cfg файл в cfg/sourcemod
	FormatEx(PREFIX, sizeof(PREFIX), "%t", "PREFIX"); // Сразу помещаем префикс в переменную
}

public OnConVarChange(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetConVarString(g_hSteamAPI_Key, keyAPI, sizeof(keyAPI));
}

stock Action hoursTest(client, args) {
	//SteamAPI_GetHours("76561198037667913", client); // Для теста берём мой SteamID
	//SteamAPI_GetHours("76561198192540713", client);
	return Plugin_Handled;
}

public OnClientAuthorized(client) // Когда игрок только-только подключился к серверу (Загружается)
{
	if (!IsFakeClient(client))
	{
		char nick[64]; char steamId[64];
		
		GetClientName(client, nick, sizeof(nick));
		GetClientAuthId(client, AuthId_SteamID64, steamId, sizeof(steamId)); // Получаем SteamID64. Мой id: 76561198037667913 
		PrintToServer("STEAMID: %s", steamId); // debug
		playTime[client] = 0; // Обнуляем количество часов клиента
		SteamAPI_GetHours(steamId, client); // Получаем часы. Они будут храниться в массиве playTime
		
		FormatEx(txtBufer, sizeof(txtBufer), "%t", "PlayerLoading", PREFIX, nick);
		CPrintToChatAll(txtBufer);
	}
}

public Action PlayerDisconnect_Event(Handle event, const char[] name, bool dontBroadcast) // https://wiki.alliedmods.net/Generic_Source_Server_Events#player_disconnect
{
	char nick[64]; char reason[64];
	int client = GetClientOfUserId(GetEventInt(event, "userid")); // Получаем номер клиента
	
	if (IsValidClient(client)) {
		GetEventString(event, "name", nick, sizeof(nick)); // Получаем ник игрока
		GetEventString(event, "reason", reason, sizeof(reason)); // Получаем причину выхода
		ReplaceString(reason, sizeof(reason), ".", "")
		
		FormatEx(txtBufer, sizeof(txtBufer), "%t", "PlayerDisconnect", PREFIX, nick, reason);
		CPrintToChatAll(txtBufer);
	}
	return Plugin_Handled;
}

public OnClientPutInServer(client) // Игрок загрузился
{
	if (!IsFakeClient(client)) {
		char Name[64]; char Country[4]; char IP[32]; char City[32]; char Hours[8];
		GetClientName(client, Name, sizeof(Name)); // Получаем имя игрока
		GetClientIP(client, IP, sizeof(IP), true); // Получаем IP игрока
		if (!GeoipCode3(IP, Country)) {  // Получаем RUS KAZ USA
			Country = "???"; // Если не удалось получить страну
		}
		if (!GeoipCity(IP, City, sizeof(City), -1)) {  // Получаем Barnaul Moscow
			City = "???";
		}
		
		if (playTime[client] == 0) {  // 0 - не удалось получить часы
			Hours = "?";
		} else {
			IntToString(playTime[client], Hours, sizeof(Hours)); // Переводим playTime в String
		}
		FormatEx(txtBufer, sizeof(txtBufer), "%t", "PlayerJoin", PREFIX, Name, Country, City, Hours); //"{1} Игрок {2} ({3}, {4}) подключился! {5}ч"
		CPrintToChatAll(txtBufer);
	}
}
stock Action createJoinMessage(int client, int args) {  // Недопилил
	
	char clientNumber[4]
	char mess[64];
	char steamId[24];
	if (args != 2) {
		ReplyToCommand(client, "[SM] Usage: sm_joinMessage <client> <joinMessage>");
		return Plugin_Handled;
	}
	GetCmdArg(1, clientNumber, sizeof(clientNumber)); // номер клиента
	GetCmdArg(2, mess, sizeof(mess)); // message
	GetClientAuthId(StringToInt(clientNumber), AuthId_Steam3, steamId, sizeof(steamId))
	//Записываем SteamID и сообщение в конфиг
	return Plugin_Handled;
}

public void SteamAPI_GetHours(char[] steamId, int client) {
	//PrintToServer("GET GET GET"); // debug
	// Формируем адрес: https://api.steampowered.com/IPlayerService/GetRecentlyPlayedGames/v0001/?key=keyAPI&steamid=steamId&format=json
	HTTPRequest request = new HTTPRequest("https://api.steampowered.com/IPlayerService/GetRecentlyPlayedGames/v0001");
	request.AppendQueryParam("key", "%s", keyAPI);
	request.AppendQueryParam("steamid", "%s", steamId);
	request.AppendQueryParam("format", "json");
	request.Get(OnTodosReceived, client); // Отправляем HTTP Get запрос
}

public void OnTodosReceived(HTTPResponse resp, any client) {  // Обработчик нашего запроса
	if (resp.Status != HTTPStatus_OK) {  // Проверка на ошибку запроса
		PrintToServer("SteamAPI GET Error");
		playTime[client] = 0; // Если не удалось получить часы, выдаём 0
		return;
	}
	
	JSONObject json_file = view_as<JSONObject>(resp.Data); // Сохраняем содержимое GET запроса
	JSONObject json_response = view_as<JSONObject>(json_file.Get("response")); // Получаем объект "response"
	if (json_response.Size >= 2) // Получаем количество объектов. Должно быть 2
	{
		JSONArray json_games = view_as<JSONArray>(json_response.Get("games")); // В объекте "response" получаем массив "games"		
		JSONObject todo; // Объект JSON'a с которым мы будем работать
		char gameName[32]; // Название игры
		
		for (int i = 0; i < json_games.Length; i++) // Проходим по всем объектам в массиве "games" // Количество объектов в массиве. Их будет 5
		{
			todo = view_as<JSONObject>(json_games.Get(i)); // Получаем объект под номером i
			todo.GetString("name", gameName, sizeof(gameName)); // Получаем ключ "name"
			
			if (StrContains(gameName, "Left 4 Dead", false) != -1) // Если "name": "Left 4 Dead 2", то...
			{
				playTime[client] = todo.GetInt("playtime_forever"); // Получаем параметр "playtime_forever"
				playTime[client] /= 60; // Делим полученные минуты на 60 и получаем ЧАСЫ
				PrintToServer("client: %i name: %s hours: %i", client, gameName, playTime[client]); // debug
				break; // Нашли что искали? Выходим из цикла
			}
			//playTime[client] = 0; // Если ничего не нашли. Приравниваем к 0. На всякий случай пусть дублируется
		}
		
		delete json_games; // Чистим за собой
		delete todo;
	}
	else // У игрока скрытый профиль. 0 часов
	{
		playTime[client] = 0;
		PrintToServer("Private Profile"); // debug
	}
	delete json_file; // Чисти
	delete json_response; // Чисти
}

stock bool IsValidClient(client)
{
	if (client > 0 && client <= MaxClients && IsClientConnected(client) && !IsFakeClient(client))
	{
		return true;
	}
	return false;
}

/*
{
  "response": { // Объект. В нем есть ключ "total_count" и массив "games"
    "total_count": 5, // Тот самый    ключ 
    "games": [ // Тот самый массив. Массивы в JSON обозначаются квадратными скобками [ ]
      { // 1 объект в массиве "games"
        "appid": 550, // Ключ содержащий значение 550
        "name": "Left 4 Dead 2", // Ключ содержащий значение Left 4 Dead 2
        "playtime_2weeks": 2521,
        "playtime_forever": 253167, // Ключ содержащий количество наигранных минут. Делим на 60 и получаем часы :)
		
		//Остальное нам не надо...		
		
        "img_icon_url": "7d5a243f9500d2f8467312822f8af2a2928777ed",
        "playtime_windows_forever": 179601,
        "playtime_mac_forever": 0,
        "playtime_linux_forever": 0
      },
      { // 2 объект в массиве "games"
        "appid": 221100,
        "name": "DayZ",
        "playtime_2weeks": 349,
        "playtime_forever": 26998,
        "img_icon_url": "16a985dfee9b093d76a0ffc4cf4c77ba20c2eb0d",
        "playtime_windows_forever": 25598,
        "playtime_mac_forever": 0,
        "playtime_linux_forever": 0
      },
      { // 3 объект в массиве "games" и тд...
        "appid": 578080,
        "name": "PUBG: BATTLEGROUNDS",
        "playtime_2weeks": 347,
        "playtime_forever": 16578,
        "img_icon_url": "609f27278aa70697c13bf99f32c5a0248c381f9d",
        "playtime_windows_forever": 2907,
        "playtime_mac_forever": 0,
        "playtime_linux_forever": 0
      },
      {
        "appid": 70,
        "name": "Half-Life",
        "playtime_2weeks": 69,
        "playtime_forever": 6860,
        "img_icon_url": "95be6d131fc61f145797317ca437c9765f24b41c",
        "playtime_windows_forever": 1175,
        "playtime_mac_forever": 0,
        "playtime_linux_forever": 0
      },
      {
        "appid": 10,
        "name": "Counter-Strike",
        "playtime_2weeks": 1,
        "playtime_forever": 1650,
        "img_icon_url": "6b0312cda02f5f777efa2f3318c307ff9acafbb5",
        "playtime_windows_forever": 39,
        "playtime_mac_forever": 0,
        "playtime_linux_forever": 0
      }
    ]
  }
}
*/