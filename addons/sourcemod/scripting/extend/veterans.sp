#pragma semicolon 1
#pragma dynamic 645221
#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS
#define PLUGIN_VERSION "1.4"
#define MAX_FLOAT 99999999.0

#include <colors>
#include <ripext>
#include <l4dstats>
#include <veterans>
#define HOST_PATH "https://api.steampowered.com"
#define TOTAL_PLAYTIME_URL "/IPlayerService/GetOwnedGames/v1"
#define REAL_PLAYTIME_URL "/ISteamUserStats/GetUserStatsForGame/v2"
#define GROUP_URL "/ISteamUser/GetUserGroupList/v1"
new String:CacheFile[PLATFORM_MAX_PATH];
new String:ExcludeFile[PLATFORM_MAX_PATH];
new bool:isBlocked = false;

//new Handle:cvar_url;
new Handle:cvar_enable;
new Handle:cvar_minPlaytime;
new Handle:cvar_minPlaytimeExcludingLast2Weeks;
new Handle:cvar_cacheTime;
new Handle:cvar_excludeGroupMemberPlay;
new Handle:cvar_excludeReservedSlots;
new Handle:cvar_excludePrivileged;
new Handle:cvar_excludeGroupMember;
new Handle:cvar_excludeGroupMemberCount;
new Handle:cvar_groupID;
new Handle:cvar_banTime;
new Handle:cvar_gameId;
new Handle:cvar_minServerPlaytime;

enum struct PlayerStruct{
	int totalplaytime;
	int realplaytime;
	int last2weektime;
	int servertime;
	int isGroupMember;
	int excludetotaltime(){
		return this.totalplaytime-this.last2weektime;
	}
	int excluderealtime(){
		return this.realplaytime-this.last2weektime;
	}
}
PlayerStruct player[32];
new Handle:g_cvAPIkey;
// --------------------------------- PLUGIN DETAILS ---------------------------------
public Plugin:myinfo = 
{
	name = "VeteransOnly",
	author = "Soroush Falahati, 东",
	description = "Kicks the players without enough playtime in the game",
	version = PLUGIN_VERSION,
	url = "https://falahati.net/"
}

//创建Native函数给其他插件使用
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	//API
	RegPluginLibrary("veterans");
	
	CreateNative("Veterans_Get", Native_GetValve);
	
	return APLRes_Success;
}

//API
public any Native_GetValve(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int option = GetNativeCell(2);
	
	if (client < 1 || client > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	if (!IsClientConnected(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
	}
	switch( view_as<TARGET_OPTION_INDEX>(option) )
	{
		case TIME_TOTAL:		return player[client].totalplaytime;
		case TIME_REAL:			return player[client].realplaytime;
		case TIME_SERVER:		return player[client].servertime;
		case TIME_2WEEK:		return player[client].last2weektime;
		case GOURP_MEMBER:		return player[client].isGroupMember;
	}
	//Debug_Print("GetClientTargetNum Native called");
	
	return 0;
}


// --------------------------------- PLUGIN LOGIC ---------------------------------
public OnPluginStart()
{	
	//AddServerTag2("Veterans");
	LoadTranslations("veterans.phrases");	
	CreateConVar("sm_veterans_version", PLUGIN_VERSION, "Veterans Only Version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_cvAPIkey = CreateConVar("l4d2_playtime_apikey", "C7B3FC46E6E6D5C87700963F0688FCB4", "Steam developer web API key", FCVAR_PROTECTED);
	/*
	cvar_url = CreateConVar(
		"sm_veterans_url",
		"http://home.trygek.com:8880/queryPlaytime.php",
		"Address of the PHP file responsible for getting user played time.",
		FCVAR_PROTECTED
	);
	*/
	cvar_enable = CreateConVar(
		"sm_veterans_enable",
		"1",
		"Is VeteransOnly plugin enable?", 
		FCVAR_NONE, true, 0.0, true, 1.0
	);
	cvar_gameId = CreateConVar(
		"sm_veterans_gameid",
		"550",
		"Steam's store id of the game you want to check the player time of.",
		FCVAR_NONE, true, 0.0, true, MAX_FLOAT
	);
	cvar_excludeGroupMemberPlay = CreateConVar(
		"sm_veterans_excludegroupmemberplay",
		"1",
		"Should we  let exclude group member but not rechach mititaion to play",
		FCVAR_NONE, true, 0.0, true, 1.0
	);
	cvar_excludeReservedSlots = CreateConVar(
		"sm_veterans_excludereservedslots",
		"1",
		"Should we exclude players that have a reserved slot from punishment?",
		FCVAR_NONE, true, 0.0, true, 1.0
	);
	cvar_excludePrivileged = CreateConVar(
		"sm_veterans_excludeprivileged",
		"1",
		"Should we exclude privileged players from punishment?",
		FCVAR_NONE, true, 0.0, true, 1.0
	);
	cvar_excludeGroupMember = CreateConVar(
		"sm_veterans_excludegroupmember",
		"1",
		"Should we exclude players that are members of our Steam group?",
		FCVAR_NONE, true, 0.0, true, 1.0
	);
	cvar_excludeGroupMemberCount = CreateConVar(
		"sm_veterans_excludegroupmembercount",
		"2",
		"How many leading sv_steamgroup groups should be excluded from advertisement/time punishment? 0 disables group count matching.",
		FCVAR_NONE, true, 0.0, true, MAX_FLOAT
	);
	/*
	cvar_groupID = CreateConVar(
		"sm_veterans_groupid",
		"",
		"Steam Group ID (same as your sv_steamgroup)",
		FCVAR_NONE
	);
	*/
	cvar_groupID = FindConVar("sv_steamgroup");
	cvar_banTime = CreateConVar(
		"sm_veterans_bantime",
		"10",
		"Should me ban the player instead of kicking and if we should, for how long (in minutes)?",
		FCVAR_NONE, true, 0.0, true, MAX_FLOAT
	);
	cvar_minPlaytime = CreateConVar(
		"sm_veterans_mintotal",
		"0",
		"Minimum total playtime amount that player needs to have (in minutes)?",
		FCVAR_NONE, true, 0.0, true, MAX_FLOAT
	);
	cvar_minServerPlaytime = CreateConVar(
		"sm_veterans_minServertotal",
		"0",
		"Minimum total Server playtime amount that player needs to have (in minutes)?",
		FCVAR_NONE, true, 0.0, true, MAX_FLOAT
	);
	cvar_minPlaytimeExcludingLast2Weeks = CreateConVar(
		"sm_veterans_mintotalminuslastweeks",
		"0",
		"Minimum total playtime amount (excluding last 2 weeks) that player needs to have (in minutes)?",
		FCVAR_NONE, true, 0.0, true, MAX_FLOAT
	);
	
	cvar_cacheTime = CreateConVar(
		"sm_veterans_cachetime",
		"14400",
		"Amount of time in seconds that we should not send a delicate request for the same query.",
		FCVAR_NONE, true, 0.0, true, MAX_FLOAT
	);

	CleanupPlaytimeCache(true);

	RegAdminCmd("sm_veterans_exclude", AddToWhitelist, ADMFLAG_GENERIC, "Exludes a user from veterans plugin", "", 0);
	RegAdminCmd("sm_veterans_include", RemoveFromWhitelist, ADMFLAG_GENERIC, "Includes an already excluded user from veterans plugin", "", 0);
	RegAdminCmd("sm_clear", ClearPlaytimeCache, ADMFLAG_GENERIC, "Clear cache", "", 0);
	RegAdminCmd("sm_timeall", showallplayertime, ADMFLAG_GENERIC, "显示所有玩家时间", "", 0);
	RegConsoleCmd("sm_time", showplayertime, "显示时间", 0);

	//AutoExecConfig(true, "veterans");
	new iPort = GetConVarInt(FindConVar("hostport"));
	HookEvent("player_team", event_PlayerTeam, EventHookMode_Post); // When a survivor changes team...
	BuildPath(Path_SM, CacheFile, sizeof(CacheFile), "data/veterans_cache_%d.txt", iPort);
	BuildPath(Path_SM, ExcludeFile, sizeof(ExcludeFile), "data/veterans_exclude.txt");
}

public void l4dstats_AnnounceGameTime(int client)
{
	CreateTimer(0.3,announcetime,client);
}

public Action:event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Player = GetClientOfUserId(GetEventInt(event, "userid"));
	char steamId[64];
	GetClientAuthId(Player, AuthId_Steam2, steamId, sizeof(steamId));

	new NewTeam = GetEventInt(event, "team");
	if(!IsClientInGame(Player) || IsFakeClient(Player) )
		return Plugin_Continue;
	if(NewTeam == 2 || NewTeam == 3)
	{
		//QueryCachedData(SteamIdToInt(steamId), player[Player].totalplaytime, player[Player].last2weektime, player[Player].isGroupMember, player[Player].servertime, player[Player].realplaytime);
		if(!HasEnoughPlaytime(player[Player].servertime) && player[Player].isGroupMember && !GetConVarBool(cvar_excludeGroupMemberPlay))
		{
			CPrintToChat(Player, "{default}[{green}玩家时长检测{default}] 你因为 {blue}不满足 {default}时长要求，只允许观战.");
			return Plugin_Stop;
		}
	}

	return Plugin_Continue;
}


public Action announcetime(Handle timer, any client){
	if(IsClientConnected(client) && !IsFakeClient(client) )
	{
		if(player[client].totalplaytime || player[client].realplaytime)
			CPrintToChatAll("{default}[{green}玩家时长检测{default}] 玩家 {blue}%N {default}总共游玩时间共：{green}%.1f小时{default}(实际：{green}%.1f小时{default})，本服务器内游玩总时长为：{green}%.1f小时{default}.",client, player[client].totalplaytime/60.0, player[client].realplaytime/60.0, player[client].servertime/60.0);
		else
			CPrintToChatAll("{default}[{green}玩家时长检测{default}] 玩家 {blue}%N {default}游玩时间：{green}未知{default}，本服务器内游玩总时长为：{green}%.1f小时{default}.",client, player[client].servertime/60.0);
	}
	return Plugin_Continue;
}

public OnPluginEnd()
{
	//RemoveServerTag2("Veterans");
}

public OnMapStart()
{
	CleanupPlaytimeCache(false);
	
	isBlocked = false;
}


public void InitPlayerStats(client)
{
	player[client].servertime = 0;
	player[client].realplaytime = 0;
	player[client].totalplaytime = 0;
	player[client].last2weektime = 0;
	player[client].isGroupMember = 0;
}


public OnClientAuthorized(client, const String:steamId[])
{
	if (isBlocked || !GetConVarBool(cvar_enable))
	{
		return;
	}
	
	
	// Exclude bots
	if (StrEqual(steamId, "BOT", false)) {
		return;
	}
	
	InitPlayerStats(client);

	AdminId adminId = GetUserAdmin(client);

	if (adminId != INVALID_ADMIN_ID) {
		// Exclude privileged
		if (GetConVarBool(cvar_excludePrivileged)) {
			CPrintToChatAll("{default}[{green}玩家时长检测{default}] 管理员 {blue}%N {default}免去时长检测.",client);
			return;
		}
		
		// Exclude reserved slots
		if (GetConVarBool(cvar_excludeReservedSlots) && GetAdminFlag(adminId, Admin_Reservation)) {
			CPrintToChatAll("{default}[{green}玩家时长检测{default}] 管理员 {blue}%N {default}免去时长检测.",client);
			return;
		}

		// Exclude admins
		if (GetAdminFlag(adminId, Admin_Generic) || GetAdminFlag(adminId, Admin_Root)) {
			CPrintToChatAll("{default}[{green}玩家时长检测{default}] 管理员 {blue}%N {default}免去时长检测.",client);
			return;
		}
	}

	// Exclude whitelisted
	if (IsWhitelisted(steamId)) {
		return;
	}
	if (QueryCachedData(SteamIdToInt(steamId), player[client].totalplaytime, player[client].last2weektime, player[client].isGroupMember, player[client].servertime, player[client].realplaytime))
	{

		//LogError("VeteransOnly: New client, playtime loaded from cache for SteamId %s", steamId);
		//CheckIfUserQualified(client);
	}else {
		//LogError("VeteransOnly: New client, requesting playtime for SteamId %s", steamId);
		RequestUserInfo(client);
	}
}

public void l4dstats_SuccessGetPlayerTime(int client){
	player[client].servertime = l4dstats_GetClientPlayTime(client);
	CheckIfUserQualified(client);
}



// --------------------------------- PLAYER TIME DECISION ---------------------------------
CheckIfUserQualified(client)
{
	
	if (HasEnoughPlaytime(player[client].servertime))
	{	
		return;
	}else{
		if (GetConVarBool(cvar_excludeGroupMember) && player[client].isGroupMember)
		{
			if(GetConVarBool(cvar_excludeGroupMemberPlay))
				CPrintToChatAll("{default}[{green}玩家时长检测{default}] 玩家 {blue}%N {{default}在本服务器游戏时长{green}不达标{default}，是电信服务器组玩家，允许正常游玩", client);
			else
				CPrintToChatAll("{default}[{green}玩家时长检测{default}] 玩家 {blue}%N {{default}在本服务器游戏时长{green}不达标{default}，是电信服务器组玩家，允许旁观不允许游玩", client);
			//PrintToServer("VeteransOnly: Excluded for being a group member");
			return;
		}
		else{
			CPrintToChatAll("{default}[{green}玩家时长检测{default}] 玩家 {blue}%N {default}在本服务器游戏时长{green}不达标{default}，且不为电信服务器组玩家，已经自动请去休息.",client);
		}		
	}

	float minPlaytime = GetConVarFloat(cvar_minPlaytime) / 60;
	float minServerPlayTime = GetConVarFloat(cvar_minServerPlaytime) /60;
	float minPlaytimeExcludingLast2Weeks = GetConVarFloat(cvar_minPlaytimeExcludingLast2Weeks) / 60;
	decl String:formated[256];
	Format(
		formated, 
		sizeof (formated),
		"%T", 
		"REJECTED", 
		client, 
		minServerPlayTime, 
		minPlaytime, 
		minPlaytimeExcludingLast2Weeks	
	);
	ThrowPlayerOut(client, formated);	
}

bool:HasEnoughPlaytime(int ServerPlayTime)
{
	//PrintToServer("VeteransOnly: Deciding for Total of %d minutes, last two weeks %d minutes", totalTime, last2WeeksTime);

	//float minPlaytime = GetConVarFloat(cvar_minPlaytime);
	//float minPlaytimeExcludingLast2Weeks = GetConVarFloat(cvar_minPlaytimeExcludingLast2Weeks);
	float minServerPlayTime = GetConVarFloat(cvar_minServerPlaytime);
	//int playtimeExcludingLast2Weeks = totalTime > last2WeeksTime ? totalTime - last2WeeksTime : 0;

	return ServerPlayTime >= minServerPlayTime;
}

// --------------------------------- PLAYER EXCEPTIONS ---------------------------------
public Action:AddToWhitelist(int client, int args)
{
	if (args < 1) {
		ReplyToCommand(client, "Usage: !sm_veterans_exclude <steamid1> <steamid2> ...");
		return Plugin_Handled;
	}

	new Handle:kv = CreateKeyValues("VeteranExcludedPlayers");
	FileToKeyValues(kv, ExcludeFile);

	do
	{
		decl String:steamId[32];
		if (GetCmdArg(args, steamId, strlen(steamId)) == 18) {
			KvJumpToKey(kv, steamId, true);
			KvSetNum(kv, "Excluded", 1);
			KvRewind(kv);

			decl String:formated[256];
			Format(
				formated,
				sizeof(formated),
				"%T",
				"EXCLUDED", 
				client,
				steamId
			);
			ReplyToCommand(client, formated);
		}
		args--;
	} while (args > 0);

	KeyValuesToFile(kv, ExcludeFile);
	CloseHandle(kv);
	return Plugin_Handled;
} 

public Action:RemoveFromWhitelist(int client, int args)
{
	if (args < 1) {
		ReplyToCommand(client, "Usage: !sm_veterans_include <steamid1> <steamid2> ...");
		return Plugin_Handled;
	}

	new Handle:kv = CreateKeyValues("VeteranExcludedPlayers");
	FileToKeyValues(kv, ExcludeFile);

	do
	{
		decl String:steamId[32];
		if (GetCmdArg(args, steamId, strlen(steamId)) == 18) {
			if (KvJumpToKey(kv, steamId, false)) {
				KvSetNum(kv, "Excluded", 0);
				KvDeleteThis(kv);
				KvRewind(kv);
			}
			decl String:formated[256];
			Format(
				formated,
				sizeof(formated),
				"%T",
				"INCLUDED", 
				client,
				steamId
			);
			ReplyToCommand(client, formated);
		}
		args--;
	} while (args > 0);

	KeyValuesToFile(kv, ExcludeFile);
	CloseHandle(kv);
	return Plugin_Handled;
}

bool:IsWhitelisted(const String:steamId[]) 
{
	new Handle:kv = CreateKeyValues("VeteranExcludedPlayers");
	FileToKeyValues(kv, ExcludeFile);

	if (!KvJumpToKey(kv, steamId)) {
		CloseHandle(kv);
		return false;
	}

	if (KvGetNum(kv, "Excluded") > 0) {
		CloseHandle(kv);
		return true;
	} else {
		CloseHandle(kv);
		return false;
	}
}

// --------------------------------- WEB COMMUNICATION ---------------------------------
RequestUserInfo(client)
{
	//LogError("获取游戏时长");
	int gameId = GetConVarInt(cvar_gameId);
	//GetConVarString(cvar_gameId, gameId, sizeof gameId);
	/*
	decl String:url[256];
	GetConVarString(cvar_url, url, sizeof url);
	
	new Handle:hRequest = SteamWorks_CreateHTTPRequest(EHTTPMethod:k_EHTTPMethodGET, url);
	
	SteamWorks_SetHTTPRequestNetworkActivityTimeout(hRequest, GetConVarInt(cvar_connectionTimeout));

	SteamWorks_SetHTTPRequestGetOrPostParameter(hRequest, "gameId", gameId);
	SteamWorks_SetHTTPRequestGetOrPostParameter(hRequest, "steamId", steamId);
	if (GetConVarBool(cvar_excludeGroupMember))
	{
		decl String:groupId[16];
		GetConVarString(cvar_groupID, groupId, sizeof groupId);
		SteamWorks_SetHTTPRequestGetOrPostParameter(hRequest, "groupId", groupId);
	}

	SteamWorks_SetHTTPCallbacks(hRequest, UserInfoRetrieved);
	SteamWorks_SetHTTPRequestContextValue(hRequest, SteamIdToInt(steamId), GetClientUserId(client));
	
	SteamWorks_SendHTTPRequest(hRequest);
	*/
	char authId64[65];
	GetClientAuthId(client, AuthId_SteamID64, authId64, sizeof(authId64));
	
	char apikey[65];
	GetConVarString(g_cvAPIkey, apikey, sizeof(apikey));
	/*
	DataPack dp = new DataPack();
	dp.WriteCell(client);
	DataPack dp2 = view_as<DataPack>(CloneHandle(dp));
	DataPack dp3 = view_as<DataPack>(CloneHandle(dp2));
	*/

	
	HTTPRequest request = new HTTPRequest(HOST_PATH...TOTAL_PLAYTIME_URL);
	request.AppendQueryParam("key", "%s", apikey);
	request.AppendQueryParam("steamid", "%s", authId64);
	request.AppendQueryParam("appids_filter[0]", "%i", gameId);
	request.AppendQueryParam("include_appinfo", "%i", 0);
	request.AppendQueryParam("include_played_free_games", "%i", 0);
	request.Get(HTTPResponse_GetOwnedGames, client);
	
	CreateTimer(1.0, GetRealTime, client);
	
	CreateTimer(2.0, GetGroup, client);
	//CreateTimer(10.0, CheckPlayer, client);
	CreateTimer(35.0, CachePlayer, client);
}

public Action GetRealTime(Handle hTimer, any client){
	int gameId = GetConVarInt(cvar_gameId);
	char authId64[65];
	GetClientAuthId(client, AuthId_SteamID64, authId64, sizeof(authId64));
	
	char apikey[65];
	GetConVarString(g_cvAPIkey, apikey, sizeof(apikey));
	HTTPRequest request = new HTTPRequest(HOST_PATH...REAL_PLAYTIME_URL);
	request.AppendQueryParam("key", "%s", apikey);
	request.AppendQueryParam("steamid", "%s", authId64);
	request.AppendQueryParam("appid", "%i", gameId);
	request.Get(HTTPResponse_GetUserStatsForGame, client);
	return Plugin_Continue;
}

public Action GetGroup(Handle hTimer, any client){
	char authId64[65];
	GetClientAuthId(client, AuthId_SteamID64, authId64, sizeof(authId64));
	
	char apikey[65];
	GetConVarString(g_cvAPIkey, apikey, sizeof(apikey));
	HTTPRequest request = new HTTPRequest(HOST_PATH...GROUP_URL);
	request.AppendQueryParam("key", "%s", apikey);
	request.AppendQueryParam("steamid", "%s", authId64);
	request.Get(HTTPResponse_GetUserGroups, client);
	//CreateTimer(3.0, CheckPlayer, client);	
	return Plugin_Continue;
}



public Action CachePlayer(Handle hTimer, any client){
	if(!IsClientConnected(client))
		return Plugin_Handled;
	char steamId[64];
	GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
	CacheUserData(SteamIdToInt(steamId), player[client].totalplaytime, player[client].last2weektime, player[client].isGroupMember, player[client].servertime, player[client].realplaytime);
	//LogError("%N: 总时长：%i 最近2周：%i 组成员：%i 服务器时长：%i 真实时长：%i(时长单位min)", client, player[client].totalplaytime, player[client].last2weektime, player[client].isGroupMember, player[client].servertime, player[client].realplaytime);
	return Plugin_Continue;
}

public void HTTPResponse_GetOwnedGames(HTTPResponse response, int client)
{
	//LogError("获取总游戏时长");
	
	if (response.Status != HTTPStatus_OK || response.Data == null)
	{
		LogError("Failed to retrieve response (GetOwnedGames) - HTTPStatus: %i", view_as<int>(response.Status));
		return;
	}
	
	/*
	{
		"response":
		{
			"game_count":1,
			"games": [
			{
				"appid":550,
				"playtime_2weeks":0,
				"playtime_forever":0,
				"playtime_windows_forever":0,
				"playtime_mac_forever":0,
				"playtime_linux_forever":0
			}]
		}
	}
	*/
	
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

	if (!jsonArray || jsonArray.Length <= 0)
	{
		player[client].totalplaytime = 0;
		player[client].last2weektime = 0;
		delete jsonArray;
		return;
	}
	
	// right here is the data requested
	dataObj = view_as<JSONObject>(jsonArray.Get(0));

	if (!dataObj)
	{
		player[client].totalplaytime = 0;
		player[client].last2weektime = 0;
		delete jsonArray;
		return;
	}
	
	// playtime is formatted in minutes
	player[client].totalplaytime = dataObj.HasKey("playtime_forever") ? dataObj.GetInt("playtime_forever") : 0;
	player[client].last2weektime = dataObj.HasKey("playtime_2weeks") ? dataObj.GetInt("playtime_2weeks") : 0;
	//LogError("%i %i", player[client].totalplaytime, player[client].last2weektime);
	delete jsonArray;
	delete dataObj;
}

public void HTTPResponse_GetUserGroups(HTTPResponse response, int client)
{	
	if (response.Status != HTTPStatus_OK || response.Data == null)
	{
		LogError("Failed to retrieve response (GetGroupinf) - HTTPStatus: %i", view_as<int>(response.Status));
		return;
	}
	
	/*
	{
		"response":
		{
			"success":true,
			"groups":[{"gid":"3284297"},{"gid":"25622692"},{"gid":"26419628"},{"gid":"26736028"},{"gid":"33699572"}]
		}
	}
	*/
	
	// go to response body
	JSONObject dataObj = view_as<JSONObject>(view_as<JSONObject>(response.Data).Get("response"));
	
	// invalid json data due to privacy?
	if (!dataObj)
	{
		player[client].isGroupMember = 0;
		return;
	}
	if (!dataObj.Size || !dataObj.HasKey("groups") || dataObj.IsNull("groups"))
	{
		player[client].isGroupMember = 0;
		delete dataObj;
		return;
	}
	
	// jump to "games" array section
	JSONArray jsonArray = view_as<JSONArray>(dataObj.Get("groups"));
	
	char keyname[64];
	int size = jsonArray.Length;
	for (int i = 0; i < size; ++i)
	{
		delete dataObj;
		dataObj = view_as<JSONObject>(jsonArray.Get(i));
		if ( dataObj.GetString("gid", keyname, sizeof(keyname))
			&& IsConfiguredGroupExempt(keyname) )
		{
			player[client].isGroupMember = 1;
			break;
		}
	}
	
	delete jsonArray;
	delete dataObj;
}

bool:IsConfiguredGroupExempt(const String:steamGroupId[])
{
	int exemptCount = GetConVarInt(cvar_excludeGroupMemberCount);
	if (exemptCount <= 0)
	{
		return false;
	}

	char groupIDs[256];
	GetConVarString(cvar_groupID, groupIDs, sizeof(groupIDs));

	char groups[32][32];
	int groupCount = ExplodeString(groupIDs, ",", groups, sizeof(groups), sizeof(groups[]));
	if (groupCount > exemptCount)
	{
		groupCount = exemptCount;
	}

	for (int i = 0; i < groupCount; ++i)
	{
		TrimString(groups[i]);
		if (StrEqual(groups[i], steamGroupId, false))
		{
			return true;
		}
	}

	return false;
}

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
	
	/*
	{
		"playerstats":
		{
			"steamID":"STEAM64",
			"gameName":"",
			"achievements":[
				{"name": "...", "achieved": 1},
				...
			],
			"stats":[
				...,
				{"name": "Stat.TotalPlayTime.Total", "value": ?},
				...
			]
		}
	}
	*/
	
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
	for (int i = 0; i < size; ++i)
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

/*
public UserInfoRetrieved(Handle:HTTPRequest, bool:bFailure, bool:bRequestSuccessful, EHTTPStatusCode:eStatusCode, any:steamIntId, any:userId)
{
	new client = GetClientOfUserId(userId);
	if(!client)
	{
		CloseHandle(HTTPRequest);
		return;
	}
	new totalTime, last2WeeksTime, isGroupMember, ServerPlayTime; 

	if(!bRequestSuccessful || eStatusCode != EHTTPStatusCode:k_EHTTPStatusCode200OK)
	{
		if(bRequestSuccessful)
		{
			CloseHandle(HTTPRequest);
		}
		last2WeeksTime = 0;
		totalTime	   = 0;
		isGroupMember  = 0;
		//CPrintToChatAll("{default}[{green}玩家时长检测{default}] 玩家 {blue}%N {default} 游戏时长获取失败.",client);
		LogError("VeteransOnly: Failed to retrieve user's playtime (HTTP status: %d)", eStatusCode);
		LogError("[玩家时长检测] 玩家 %N 总共游玩时间共：%.1f小时，两周内游玩时长为：%.1f小时，本服务器内游玩时长为：%.1f小时.",client, totalTime/60.0, last2WeeksTime/60.0,ServerPlayTime/60.0);
		//CacheUserData(steamIntId, totalTime, last2WeeksTime, isGroupMember, ServerPlayTime);
		//CheckIfUserQualified(client, totalTime, last2WeeksTime, isGroupMember, ServerPlayTime);
		//return;
	}	

	new iBodySize;
	if (SteamWorks_GetHTTPResponseBodySize(HTTPRequest, iBodySize))
	{
		decl String:sBody[iBodySize + 1];
		SteamWorks_GetHTTPResponseBodyData(HTTPRequest, sBody, iBodySize);
		if (iBodySize <= 6 || StrContains(sBody, "|0|0|0|") != -1)
		{
					last2WeeksTime = 0;
					totalTime	   = 0;
					isGroupMember  = 0;
		} else if (StrContains(sBody, "|") >= 0) {
			decl String:times[5][10];
			ExplodeString(sBody, "|", times, sizeof times, sizeof times[]);
			totalTime = StringToInt(times[1]);
			last2WeeksTime = StringToInt(times[2]);
			isGroupMember = StringToInt(times[3]);
		}
		//CacheUserData(steamIntId, totalTime, last2WeeksTime, isGroupMember, ServerPlayTime);
		//CheckIfUserQualified(client, totalTime, last2WeeksTime, isGroupMember, ServerPlayTime);
		LogError("[玩家时长检测] 玩家 %N 总共游玩时间共：%.1f小时，两周内游玩时长为：%.1f小时，本服务器内游玩时长为：%.1f小时.",client, totalTime/60.0, last2WeeksTime/60.0,ServerPlayTime/60.0);
		//return;
	}
	ServerPlayTime = l4dstats_GetClientPlayTime(client);
	if (ServerPlayTime < GetConVarInt(cvar_minServerPlaytime) && !isGroupMember)
	{	
		decl String:formated[128];
		Format(formated, sizeof(formated), "%T", "REJECTED", client, GetConVarInt(cvar_minServerPlaytime)/60.0);
		ThrowPlayerOut(client, formated);
	}
	CacheUserData(steamIntId, totalTime, last2WeeksTime, isGroupMember, ServerPlayTime);
	CheckIfUserQualified(client, totalTime, last2WeeksTime, isGroupMember, ServerPlayTime);
	return;
}
*/
// --------------------------------- PLAYER TIME CACHE ---------------------------------
public Action:ClearPlaytimeCache(client, int args)
{
	CleanupPlaytimeCache(true);
}

public Action:showplayertime(client, int args)
{
	CPrintToChat(client, "{default}[{green}玩家时长检测{default}] 玩家 {blue}%N {default}总共游玩时间共：{green}%.1f小时{default}(实际：{green}%.1f小时{default})，本服务器内游玩总时长为：{green}%.1f小时{default}.",client, player[client].totalplaytime/60.0, player[client].realplaytime/60.0, player[client].servertime/60.0);
}

public Action:showallplayertime(client, int args)
{
	for(int i=1; i <= MaxClients ; i ++)
		if(IsClientConnected(i) && !IsFakeClient(i))
			CPrintToChat(client, "{default}[{green}玩家时长检测{default}] 玩家 {blue}%N {default}总共游玩时间共：{green}%.1f小时{default}(实际：{green}%.1f小时{default})，本服务器内游玩总时长为：{green}%.1f小时{default}.",i, player[i].totalplaytime/60.0, player[i].realplaytime/60.0, player[i].servertime/60.0);
}

CleanupPlaytimeCache(bool:clearAll)
{
	new Handle:kv = CreateKeyValues("VeteranPlayersCache");
	FileToKeyValues(kv, CacheFile);
 	if (!KvGotoFirstSubKey(kv))
	{
		return;
	}

	new lastUpdate, maxTime, currentTime;
	maxTime = GetConVarInt(cvar_cacheTime);
	currentTime = GetTime();
	do
	{
		lastUpdate =		KvGetNum(kv, "LastUpdate");
		if ((clearAll || lastUpdate + maxTime < currentTime))
		{
			KvDeleteThis(kv);
		}
	} while (KvGotoNextKey(kv));
	KvRewind(kv);
	KeyValuesToFile(kv, CacheFile);
	CloseHandle(kv);
}

CacheUserData(int steamIntId, int totalTime, int last2WeeksTime, int isGroupMember, int ServerPlayTime, int realplaytime)
{
	decl String:steamId[32];
	IntToString(steamIntId, steamId, sizeof steamId);

	new Handle:kv = CreateKeyValues("VeteranPlayersCache");
	FileToKeyValues(kv, CacheFile);
	KvJumpToKey(kv, steamId, true);
	KvSetNum(kv, "LastUpdate", GetTime());
	KvSetNum(kv, "TotalTime", totalTime);
	KvSetNum(kv, "Last2WeeksTime", last2WeeksTime);
	KvSetNum(kv, "isGroupMember", isGroupMember);
	KvSetNum(kv, "ServerPlayTime", ServerPlayTime);
	KvSetNum(kv, "realplaytime", realplaytime);
	KvRewind(kv);
	KeyValuesToFile(kv, CacheFile);
	CloseHandle(kv);
}

bool:QueryCachedData(int steamIntId, int &totalTime, int &last2WeeksTime, int &isGroupMember, int &ServerPlayTime, int &realPlaytime)
{
	decl String:steamId[32];
	IntToString(steamIntId, steamId, sizeof steamId);

	totalTime = 0;
	last2WeeksTime = 0;
	new Handle:kv = CreateKeyValues("VeteranPlayersCache");
	FileToKeyValues(kv, CacheFile);
	if (!KvJumpToKey(kv, steamId))
	{
		CloseHandle(kv);
		return false;
	}
	totalTime =			KvGetNum(kv, "TotalTime");
	last2WeeksTime =	KvGetNum(kv, "Last2WeeksTime");
	isGroupMember =		KvGetNum(kv, "isGroupMember");
	ServerPlayTime =    KvGetNum(kv, "ServerPlayTime");
	realPlaytime = 		KvGetNum(kv, "realPlaytime");
	CloseHandle(kv);
	return true;
}

// --------------------------------- HELPER FUNCTIONS ---------------------------------
int SteamIdToInt(const String:steamId[])
{
    decl String:subinfo[3][16];
    ExplodeString(steamId, ":", subinfo, sizeof subinfo, sizeof subinfo[]);
    return (StringToInt(subinfo[2]) * 2) + StringToInt(subinfo[1]);
}

ThrowPlayerOut(client, const String:reason[])
{
	int banTime = GetConVarInt(cvar_banTime);
	if (banTime > 0)
	{
		BanClient(client, banTime, BANFLAG_AUTHID, reason, reason);
	}
	else
	{
		KickClient(client, reason);
	}
}

// --------------------------------- SERVER TAGS ---------------------------------
stock AddServerTag2(const String:tag[])
{
    new Handle:hTags = INVALID_HANDLE;
    hTags = FindConVar("sv_tags");
    if(hTags != INVALID_HANDLE)
    {
        new String:tags[256];
        GetConVarString(hTags, tags, sizeof(tags));
        if(StrContains(tags, tag, true) > 0) return;
        if(strlen(tags) == 0)
        {
            Format(tags, sizeof(tags), tag);
        }
        else
        {
            Format(tags, sizeof(tags), "%s,%s", tags, tag);
        }
        SetConVarString(hTags, tags, true);
    }
}

stock RemoveServerTag2(const String:tag[])
{
    new Handle:hTags = INVALID_HANDLE;
    hTags = FindConVar("sv_tags");
    if(hTags != INVALID_HANDLE)
    {
        decl String:tags[50]; //max size of sv_tags cvar
        GetConVarString(hTags, tags, sizeof(tags));
        if(StrEqual(tags, tag, true))
        {
            Format(tags, sizeof(tags), "");
            SetConVarString(hTags, tags, true);
            return;
        }
        new pos = StrContains(tags, tag, true);
        new len = strlen(tags);
        if(len > 0 && pos > -1)
        {
            new bool:found;
            decl String:taglist[50][50];
            ExplodeString(tags, ",", taglist, sizeof(taglist[]), sizeof(taglist));
            for(new i;i < sizeof(taglist[]);i++)
            {
                if(StrEqual(taglist[i], tag, true))
                {
                    Format(taglist[i], sizeof(taglist), "");
                    found = true;
                    break;
                }
            }    
            if(!found) return;
            ImplodeStrings(taglist, sizeof(taglist[]), ",", tags, sizeof(tags));
            if(pos == 0)
            {
                tags[0] = 0x20;
            }    
            else if(pos == len-1)
            {
                Format(tags[strlen(tags)-1], sizeof(tags), "");
            }    
            else
            {
                ReplaceString(tags, sizeof(tags), ",,", ",");
            }    
            SetConVarString(hTags, tags, true);
        }
    }    
}  
