#define PLUGIN_VERSION		"2.0.2"
#define PLUGIN_PREFIX		"l4d_"
#define PLUGIN_NAME			"gametime"
#define PLUGIN_NAME_FULL	"[L4D & L4D2] GameTime Announcer <fork>"
#define PLUGIN_DESCRIPTION	"announce profile game time for every player"
#define PLUGIN_AUTHOR		"NoroHime"
#define PLUGIN_LINK			"https://forums.alliedmods.net/showthread.php?t=341707"

/**
 *	v2.0 (Start at 26-January-2023, Released at 8-February-2023)
 *		- all translation support
 *		- completely rewrite
 *		- validate response http status and validate response JSON
 *		- support lateload mode 
 *		- merge Profile and Stats features on single plugin
 *		- fix player disconnected during requesting
 *		- remove color.inc requirement, but not {red} support anymore
 *		- solve memory leaks for handles
 *		- prefer mode
 *		- command access permission
 *		- support L4D1
 *		- dynamic wait dev key inputs
 *		- show all player GameTime when message receive available
 *		- sm_gametime [override *_prefer] display all of players gametime
 *		- command support console view all data
 *		- optional request failure actions
 *	 v2.0.1 (8-March-2023)
 *	 	- fix delay authorization cause gametime display not work
 *	 v2.0.2 (28-May-2023)
 *	 	- fix RESTInPawn extension not load automatically, thanks to Silvers
 */

#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>

public Plugin myinfo = {
	name =			PLUGIN_NAME_FULL,
	author =		PLUGIN_AUTHOR,
	description =	PLUGIN_DESCRIPTION,
	version =		PLUGIN_VERSION,
	url = 			PLUGIN_LINK
};


int timeProfilePlayed [MAXPLAYERS + 1];
int timeStatsRecorded [MAXPLAYERS + 1];
bool hasTranslations;
bool bLateLoad;
int iQuerying [MAXPLAYERS + 1];

// HTTPClient can be reuse rather than HTTPRequest
HTTPClient requester;

ConVar cDevKey;		char sDevKey[64];
ConVar cQueries;	int iQueries;
ConVar cFailure;	int iFailure;
ConVar cAccess;		int iAccess;
ConVar cPrefer;		int iPrefer;

EngineVersion ENGINE;

#define PATH_PROFILE					"IPlayerService/GetOwnedGames/v0001/?format=json&appids_filter[0]=%d"
#define PATH_STATS						"ISteamUserStats/GetUserStatsForGame/v0002/?appid=%d"
#define ACHIEVEMEMTKEY_GAMETIME_L4D		"TD3.TotalPlayTime.Total"
#define ACHIEVEMEMTKEY_GAMETIME_L4D2	"Stat.TotalPlayTime.Total"
#define HOST_STEAMAPI					"http://api.steampowered.com"
#define APPID_L4D2						550
#define APPID_L4D						500

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {

	if (late)
		bLateLoad = true;

	switch ( ENGINE = GetEngineVersion() ) {

		case Engine_Left4Dead, Engine_Left4Dead2 : {}

		default : {
			strcopy(error, err_max, "plugin " ... PLUGIN_NAME_FULL ... "only supports L4D & L4D2");
			return APLRes_Failure;
		}
	}

	return APLRes_Success;
}

public void OnPluginStart() {

	CreateConVar			(PLUGIN_NAME, PLUGIN_VERSION,		"Version of " ... PLUGIN_NAME_FULL, FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cDevKey =	CreateConVar(PLUGIN_NAME ... "_devkey", "",		"valve dev key to query, get on https://steamcommunity.com/dev", FCVAR_NOTIFY);
	cQueries =	CreateConVar(PLUGIN_NAME ... "_queries", "3",	"which gametime data sources to be query 1=steam profile 2=stats of achievement 3=both", FCVAR_NOTIFY);
	cFailure =	CreateConVar(PLUGIN_NAME ... "_failure", "8",	"query failed actions 1=dump to console 2=make public chat 4=wipe old data 8=retry once(if send fail)", FCVAR_NOTIFY);
	cAccess =	CreateConVar(PLUGIN_NAME ... "_access", "",		"admin flag to access sm_gametime command and receives query results,\na=reserved slots, empty=everyone, see more in /configs/admin_levels.cfg", FCVAR_NOTIFY);
	cPrefer =	CreateConVar(PLUGIN_NAME ... "_prefer", "2",	"which query is prefer, if got once then dont announce another, 1=steam profile 2=achievement stats 0=display every", FCVAR_NOTIFY);

	AutoExecConfig(true, PLUGIN_PREFIX ... PLUGIN_NAME);

	cDevKey.AddChangeHook(OnConVarChanged);
	cQueries.AddChangeHook(OnConVarChanged);
	cFailure.AddChangeHook(OnConVarChanged);
	cAccess.AddChangeHook(OnConVarChanged);
	cPrefer.AddChangeHook(OnConVarChanged);

	RegConsoleCmd("sm_gametime", CommandGameTime, "sm_gametime [override *_prefer] display all of players gametime");

	// load translation phrases file
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "translations/" ... PLUGIN_PREFIX ... PLUGIN_NAME ... ".phrases.txt");
	hasTranslations = FileExists(path);
	if (hasTranslations)
		LoadTranslations(PLUGIN_PREFIX ... PLUGIN_NAME ... ".phrases");
	else
		LogError("not translations file %s found yet, please check install guide for %s", PLUGIN_PREFIX ... PLUGIN_NAME ... ".phrases.txt", PLUGIN_NAME_FULL);

	LoadTranslations("core.phrases");

	requester = new HTTPClient(HOST_STEAMAPI);

	if (bLateLoad && sDevKey[0])
		LateLoad();
}

void ApplyCvars() {

	static char sBuffer[128];

	cDevKey.GetString(sBuffer, sizeof(sBuffer));
	iQueries = cQueries.IntValue;
	iFailure = cFailure.IntValue;
	iPrefer = cPrefer.IntValue;

	if (sBuffer[0]) {

		strcopy(sDevKey, sizeof(sDevKey), sBuffer);

		if (bLateLoad)
			LateLoad();

	} else {

		bLateLoad = true;
		LogError(PLUGIN_NAME_FULL ... ": not steam developer key found, please setup ConVar " ... PLUGIN_NAME ... "_devkey");
	}

	cAccess.GetString(sBuffer, sizeof(sBuffer));
	iAccess = sBuffer[0] ? ReadFlagString(sBuffer) : 0;
}

void LateLoad() {

	for(int i = 1; i <= MaxClients; i++)
		if(IsClientAuthorized(i) && IsClientInGame(i))
			OnClientPostAdminCheck(i);

	bLateLoad = false;
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}

public void OnConfigsExecuted() {
	ApplyCvars();
}

bool HasPermission(int client, int flag) {

	if (client && flag)
		return view_as<bool>(GetUserFlagBits(client) & (ADMFLAG_ROOT | flag));

	return true;
}

Action CommandGameTime(int client, int args) {

	if (!HasPermission(client, iAccess)) {
		ReplyToCommand(client, "%t", "No Access");
		return Plugin_Handled;
	}

	for (int i = 1; i <= MaxClients; i++)
		if (IsClientAuthorized(i) && !IsFakeClient(i))
			DisplayGameTime(
				i,
				client,
				GetCmdReplySource() == SM_REPLY_TO_CONSOLE ? MSG_CONSOLE : MSG_CHAT,
				args > 0 ? GetCmdArgInt(1) : -1
			);

	return Plugin_Handled;
}

enum {
	QUERY_NOPREFER =	0,
	QUERY_PROFILE = 	(1 << 0),
	QUERY_STATS = 		(1 << 1),
	// RETRIED_PROFILE =	(1 << 2),
	// RETRIED_STATS =		(1 << 3),
}

enum {
	FAILURE_CONSOLE =	(1 << 0),
	FAILURE_CHAT = 		(1 << 1),
	FAILURE_WIPE =		(1 << 2),
	// FAILURE_RETRY =		(1 << 3)
}

public void OnClientPostAdminCheck(int client) {

	if (IsFakeClient(client))
		return;

	if (!sDevKey[0]) {
		LogError(PLUGIN_NAME_FULL ... ": not steam developer key found, please setup ConVar " ... PLUGIN_NAME ... "_devkey");
		return;
	}

	static char Url[254], SteamID64[64];

	GetClientAuthId(client, AuthId_SteamID64, SteamID64, sizeof(SteamID64));

	if (iQueries & QUERY_PROFILE) {

		// build url for appid
		FormatEx(Url, sizeof(Url), PATH_PROFILE, ENGINE == Engine_Left4Dead2 ? APPID_L4D2 : APPID_L4D);
		// build url for devkey, gamer
		Format(Url, sizeof(Url), "%s&key=%s&steamid=%s", Url, sDevKey, SteamID64);
		// log request
		Announce(TARGET_SERVER, MSG_CONSOLE, "%t (%s/%s)", "Requesting", client, "Profile", HOST_STEAMAPI, Url);
		// mark as querying
		iQuerying[client] |= QUERY_PROFILE;

		requester.Get(Url, OnProfileResponded, GetClientUserId(client));
	}

	if (iQueries & QUERY_STATS) {

		FormatEx(Url, sizeof(Url), PATH_STATS, ENGINE == Engine_Left4Dead2 ? APPID_L4D2 : APPID_L4D);
		Format(Url, sizeof(Url), "%s&key=%s&steamid=%s", Url, sDevKey, SteamID64);
		Announce(TARGET_SERVER, MSG_CONSOLE, "%t (%s/%s)", "Requesting", client, "AchievementStats", HOST_STEAMAPI, Url);
		iQuerying[client] |= QUERY_STATS;
		requester.Get(Url, OnStatsResponded, GetClientUserId(client));
	}
}

// dont put on LateLoad, just wait until client can receive messages
public void OnClientPutInServer(int client) {

	if (!HasPermission(client, iAccess))
		return;

	for (int i = 1; i <= MaxClients; i++)
		if (IsClientAuthorized(i) && !IsFakeClient(i))
			DisplayGameTime(i, client, MSG_CHAT);
}

void BroadcastGameTime(int gamer, int query = -1) {

	for (int receiver = 1; receiver <= MaxClients; receiver++)
		if (IsClientInGame(receiver) && !IsFakeClient(receiver) && HasPermission(receiver, iAccess))
			DisplayGameTime(gamer, receiver, MSG_CHAT);

	DisplayGameTime(gamer, TARGET_SERVER, MSG_CHAT, query);
}

void DisplayGameTime(int gamer, int receiver, int type_message, int preferOverride = -1) {

	if (preferOverride == -1)
		preferOverride = iPrefer;

	if (!(preferOverride & QUERY_PROFILE) && timeStatsRecorded[gamer] > 0)
		Announce(receiver, type_message, "%t", "GameTime", gamer, timeStatsRecorded[gamer] / 3600, timeStatsRecorded[gamer] / 60 % 60, "AchievementStats");

	if (!(preferOverride & QUERY_STATS) && timeProfilePlayed[gamer] > 0)
		Announce(receiver, type_message, "%t", "GameTime", gamer, timeProfilePlayed[gamer] / 60, timeProfilePlayed[gamer] % 60, "Profile");

}

JSONObject data;

void OnProfileResponded(HTTPResponse response, int client) {
	// prevent client disconnected during query
	client = GetClientOfUserId(client);
	// mark as quried
	iQuerying[client] &= ~QUERY_PROFILE;

	if ((1 <= client <= MaxClients) && response.Status == HTTPStatus_OK) {

		if (data)
			delete data;

		data = view_as<JSONObject>(response.Data);

		if (data && data.HasKey("response")) {
			//data.response
			data = view_as<JSONObject>(data.Get("response"));
			//data.response.games
			if (data.HasKey("games")) {

				JSONArray games = view_as<JSONArray>(data.Get("games"));
				data = view_as<JSONObject>(games.Get(0));

				timeProfilePlayed[client] = data.GetInt("playtime_forever");

				if (timeProfilePlayed[client] > 0) {

					if (iPrefer & QUERY_STATS && (iQuerying[client] & QUERY_STATS || timeStatsRecorded[client] > 0))
						return;

					BroadcastGameTime(client, QUERY_PROFILE);
				}
				return;
			}
		}
	}

	timeProfilePlayed[client] = 0;

	if (iFailure & FAILURE_CONSOLE)
		Announce(TARGET_SERVER, MSG_CONSOLE, "%t (http code: %d)", "NoData", client, "Profile", response.Status);

	if (iFailure & FAILURE_CHAT)
		for (int receiver = 1; receiver <= MaxClients; receiver++)
			if (IsClientInGame(receiver) && !IsFakeClient(receiver) && HasPermission(receiver, iAccess))
				Announce(receiver, MSG_CHAT, "%t", "UnknownGameTime", client, "Profile");

	if (iPrefer & QUERY_STATS && timeStatsRecorded[client] > 0)
		BroadcastGameTime(client, QUERY_STATS);

	// todo
	/*if (iFailure & FAILURE_RETRY && iQuerying & RETRIED_PROFILE == 0) {
		// retry profile
		iQuerying[client] |= RETRIED_PROFILE;
	}*/
}

void OnStatsResponded(HTTPResponse response, int client) {

	client = GetClientOfUserId(client);

	iQuerying[client] &= ~QUERY_STATS;

	if ((1 <= client <= MaxClients) && response.Status == HTTPStatus_OK) {

		if (data)
			delete data;

		data = view_as<JSONObject>(response.Data);

		if (data && data.HasKey("playerstats")) {
			//data.playerstats
			data = view_as<JSONObject>(data.Get("playerstats"));
			//data.playerstats.stats
			if (data.HasKey("stats")) {

				JSONArray stats = view_as<JSONArray>(data.Get("stats"));
				data = view_as<JSONObject>(stats.Get(0));

				for (int i = 0; i < stats.Length; i++) {

					static char name_stat[64];

					data = view_as<JSONObject>(stats.Get(i));
					data.GetString("name", name_stat, sizeof(name_stat));

					if (strcmp(name_stat, ENGINE == Engine_Left4Dead2 ? ACHIEVEMEMTKEY_GAMETIME_L4D2 : ACHIEVEMEMTKEY_GAMETIME_L4D) == 0) {

						timeStatsRecorded[client] = data.GetInt("value");

						if (timeStatsRecorded[client] > 0) {

							if (iPrefer & QUERY_PROFILE && (iQuerying[client] & QUERY_PROFILE || timeStatsRecorded[client] > 0))
								return;

							BroadcastGameTime(client, QUERY_STATS);
						}
						return;
					}
				}
			}
		}
	}

	timeStatsRecorded[client] = 0;

	if (iFailure & FAILURE_CONSOLE)
		Announce(TARGET_SERVER, MSG_CONSOLE, "%t (http code: %d)", "NoData", client, "AchievementStats", response.Status);

	if (iFailure & FAILURE_CHAT)
		for (int receiver = 1; receiver <= MaxClients; receiver++)
			if (IsClientInGame(receiver) && !IsFakeClient(receiver) && HasPermission(receiver, iAccess))
				Announce(receiver, MSG_CHAT, "%t", "UnknownGameTime", client, "AchievementStats");

	if (iPrefer & QUERY_PROFILE && timeProfilePlayed[client] > 0)
		BroadcastGameTime(client, QUERY_PROFILE);
}

public void OnClientDisconnect_Post(int client) {
	timeProfilePlayed[client] = 0;
	timeStatsRecorded[client] = 0;
	iQuerying[client] = 0;
}

#define MAX_MESSAGE_LENGTH	254

enum {
	TARGET_INFECTEDS =	-32,
	TARGET_SURVIVORS,
	TARGET_ALL,
	TARGET_SERVER = LANG_SERVER,
}

enum {
	MSG_CONSOLE =		(1 << 0),
	MSG_CHAT =			(1 << 1),
	MSG_CENTER =		(1 << 2),
	MSG_HINT =			(1 << 3),
}

void Announce(int target, int type, const char[] format, any ...) {

	if (!type)
		return;

	static ArrayList targets;

	if (!targets)
		targets = new ArrayList();

	targets.Clear();

	if ( (1 <= target <= MaxClients) )

		targets.Push(target);

	else {

		switch (target) {

			case TARGET_SERVER :
				targets.Push(0);

			case TARGET_ALL : {

				for (int client = 1; client <= MaxClients; client++)
					if (IsClientInGame(client))
						targets.Push(client);

				targets.Push(0);
			}

			case TARGET_SURVIVORS, TARGET_INFECTEDS : 
				for (int client = 1; client <= MaxClients; client++)
					if (IsClientInGame(client) && GetClientTeam(client) == (target == TARGET_SURVIVORS ? 2 : 3))
						targets.Push(client);
		}
	}

	for (int i = 0; i < targets.Length; i++) {

		int client = targets.Get(i);

		static char message[MAX_MESSAGE_LENGTH];

		SetGlobalTransTarget(client);

		// only print console for host
		if (client == LANG_SERVER)
			type = MSG_CONSOLE;

		// process color tag message first
		if (type & MSG_CHAT) {
			VFormat(message, sizeof(message), format, 4);
			ApplyColorTag(message, sizeof(message));
			PrintToChat(client, "%s", message);
		}

		// process non-color message if still things to do
		if (type & MSG_CHAT != MSG_CHAT) {

			// refetch from argument
			VFormat(message, sizeof(message), format, 4);
			RemoveColorTag(message, sizeof(message));

			if (type & MSG_CONSOLE) {

				if (client == 0)
					PrintToServer("%s", message);
				else
					PrintToConsole(client, "%s", message);
			}

			if (type & MSG_CENTER)
				PrintCenterText(client, "%s", message);

			if (type & MSG_HINT)
				PrintHintText(client, "%s", message);
		}
	}
}

void ApplyColorTag(char[] message, int maxLen) {

	ReplaceString(message, maxLen, "{white}", "\x01", false);
	ReplaceString(message, maxLen, "{default}", "\x01", false);
	ReplaceString(message, maxLen, "{cyan}", "\x03", false);
	ReplaceString(message, maxLen, "{lightgreen}", "\x03", false);
	ReplaceString(message, maxLen, "{orange}", "\x04", false);
	ReplaceString(message, maxLen, "{olive}", "\x04", false);
	ReplaceString(message, maxLen, "{green}", "\x05", false);
}

void RemoveColorTag(char[] message, int maxLen) {

	ReplaceString(message, maxLen, "{white}", "", false);
	ReplaceString(message, maxLen, "{default}", "", false);
	ReplaceString(message, maxLen, "{cyan}", "", false);
	ReplaceString(message, maxLen, "{lightgreen}", "", false);
	ReplaceString(message, maxLen, "{orange}", "", false);
	ReplaceString(message, maxLen, "{olive}", "", false);
	ReplaceString(message, maxLen, "{green}", "", false);
}

// http.inc
enum HTTPStatus
{
	HTTPStatus_Invalid = 0,

	// 1xx Informational
	HTTPStatus_Continue = 100,
	HTTPStatus_SwitchingProtocols = 101,

	// 2xx Success
	HTTPStatus_OK = 200,
	HTTPStatus_Created = 201,
	HTTPStatus_Accepted = 202,
	HTTPStatus_NonAuthoritativeInformation = 203,
	HTTPStatus_NoContent = 204,
	HTTPStatus_ResetContent = 205,
	HTTPStatus_PartialContent = 206,

	// 3xx Redirection
	HTTPStatus_MultipleChoices = 300,
	HTTPStatus_MovedPermanently = 301,
	HTTPStatus_Found = 302,
	HTTPStatus_SeeOther = 303,
	HTTPStatus_NotModified = 304,
	HTTPStatus_UseProxy = 305,
	HTTPStatus_TemporaryRedirect = 307,
	HTTPStatus_PermanentRedirect = 308,

	// 4xx Client Error
	HTTPStatus_BadRequest = 400,
	HTTPStatus_Unauthorized = 401,
	HTTPStatus_PaymentRequired = 402,
	HTTPStatus_Forbidden = 403,
	HTTPStatus_NotFound = 404,
	HTTPStatus_MethodNotAllowed = 405,
	HTTPStatus_NotAcceptable = 406,
	HTTPStatus_ProxyAuthenticationRequired = 407,
	HTTPStatus_RequestTimeout = 408,
	HTTPStatus_Conflict = 409,
	HTTPStatus_Gone = 410,
	HTTPStatus_LengthRequired = 411,
	HTTPStatus_PreconditionFailed = 412,
	HTTPStatus_RequestEntityTooLarge = 413,
	HTTPStatus_RequestURITooLong = 414,
	HTTPStatus_UnsupportedMediaType = 415,
	HTTPStatus_RequestedRangeNotSatisfiable = 416,
	HTTPStatus_ExpectationFailed = 417,
	HTTPStatus_MisdirectedRequest = 421,
	HTTPStatus_TooEarly = 425,
	HTTPStatus_UpgradeRequired = 426,
	HTTPStatus_PreconditionRequired = 428,
	HTTPStatus_TooManyRequests = 429,
	HTTPStatus_RequestHeaderFieldsTooLarge = 431,
	HTTPStatus_UnavailableForLegalReasons = 451,

	// 5xx Server Error
	HTTPStatus_InternalServerError = 500,
	HTTPStatus_NotImplemented = 501,
	HTTPStatus_BadGateway = 502,
	HTTPStatus_ServiceUnavailable = 503,
	HTTPStatus_GatewayTimeout = 504,
	HTTPStatus_HTTPVersionNotSupported = 505,
	HTTPStatus_VariantAlsoNegotiates = 506,
	HTTPStatus_NotExtended = 510,
	HTTPStatus_NetworkAuthenticationRequired = 511,
};

typeset HTTPRequestCallback {
	function void (HTTPResponse response, any value);
};


methodmap HTTPResponse {
	property JSON Data {
		public native get();
	}

	property HTTPStatus Status {
		public native get();
	}
};

methodmap HTTPClient < Handle {
	public native HTTPClient(const char[] baseURL);
	public native void Get(const char[] endpoint, HTTPRequestCallback callback, any value = 0);
}

// json.inc

methodmap JSON < Handle {
};

methodmap JSONObject < JSON
{
	public native JSONObject();
	public native JSON Get(const char[] key);
	public native int GetInt(const char[] key);
	public native bool GetString(const char[] key, char[] buffer, int maxlength);
	public native bool HasKey(const char[] key);
};

methodmap JSONArray < JSON
{
	public native JSONArray();
	public native JSON Get(int index);
	public native int GetInt(int index);
	public native bool GetString(int index, char[] buffer, int maxlength);
	property int Length {
		public native get();
	}
};

// mark as extension autoload
public Extension __ext_rip =
{
	name = "REST in Pawn",
	file = "rip.ext",
	autoload = 1,
	required = 1,
};
