#include <ripext>
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

public Plugin myinfo =
{
	name		= "L4D2 - Restart match",
	author		= "Altair Sossai",
	description = "Restarts the server at the start of a new campaign",
	version		= "1.0.0",
	url			= "https://github.com/altair-sossai/l4d2-server-manager-client"
};

ConVar cvar_reset_match_enabled;
ConVar cvar_reset_match_matchname;
ConVar cvar_reset_match_endpoint;
ConVar cvar_reset_match_access_token;

String:port[6];

int savedScore = 0;

public void OnPluginStart()
{
	cvar_reset_match_enabled	  = CreateConVar("reset_match_enabled", "0", "Restart is enabled", FCVAR_PROTECTED);
	cvar_reset_match_matchname	  = CreateConVar("reset_match_matchname", "", "Match name", FCVAR_PROTECTED);
	cvar_reset_match_endpoint	  = CreateConVar("reset_match_endpoint", "https://l4d2-server-manager-api.azurewebsites.net", "API endpoint", FCVAR_PROTECTED);
	cvar_reset_match_access_token = CreateConVar("reset_match_access_token", "", "API Access Token", FCVAR_PROTECTED);

	IntToString(GetConVarInt(FindConVar("hostport")), port, sizeof(port));

	HookEvent("round_start", RoundStart_Event);
}

public void L4D2_OnEndVersusModeRound_Post()
{
	SaveCurrentScore();
}

public void RoundStart_Event(Handle event, const char[] name, bool dontBroadcast)
{
	if (!GetConVarBool(cvar_reset_match_enabled) || savedScore == 0)
		return;

	CreateTimer(30.0, ResetMatch_Timer);
}

public Action ResetMatch_Timer(Handle timer)
{
	int currentScore = GetCurrentScore();
	if (currentScore != 0)
		return Plugin_Continue;

	PrintToChatAll("Reiniciando servidor...");

	new String:endpoint[255] = "/api/server/";
	StrCat(endpoint, sizeof(endpoint), port);
	StrCat(endpoint, sizeof(endpoint), "/reset-match");

	JSONObject command = new JSONObject();

	new String:matchName[255];
	GetConVarString(cvar_reset_match_matchname, matchName, sizeof(matchName));
	command.SetString("matchName", matchName);

	HTTPRequest request = BuildHTTPRequest(endpoint);

	request.Put(command, ResetMatchResponse);

	return Plugin_Continue;
}

void ResetMatchResponse(HTTPResponse httpResponse, any value)
{
	if (httpResponse.Status != HTTPStatus_OK)
	{
		PrintToChatAll("\x04Falha ao reiniciar o servidor");
		return;
	}
}

void SaveCurrentScore()
{
	savedScore = GetCurrentScore();
}

int GetCurrentScore()
{
	return L4D2Direct_GetVSCampaignScore(0) + L4D2Direct_GetVSCampaignScore(1);
}

HTTPRequest BuildHTTPRequest(char[] path)
{
	new String:endpoint[255];
	GetConVarString(cvar_reset_match_endpoint, endpoint, sizeof(endpoint));
	StrCat(endpoint, sizeof(endpoint), path);

	new String:access_token[100];
	GetConVarString(cvar_reset_match_access_token, access_token, sizeof(access_token));

	HTTPRequest request = new HTTPRequest(endpoint);
	request.SetHeader("Authorization", access_token);

	return request;
}