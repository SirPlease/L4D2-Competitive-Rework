#include <ripext>
#include <sourcemod>

public Plugin myinfo =
{
	name		= "L4D2 - DDoS protection",
	author		= "Altair Sossai",
	description = "Allows you to close and open server ports",
	version		= "1.0.0",
	url			= "https://github.com/altair-sossai/l4d2-server-manager-client"
};

ConVar cvar_ddos_protection_endpoint;
ConVar cvar_ddos_protection_access_token;
String:port[6];

public void OnPluginStart()
{
	cvar_ddos_protection_endpoint	  = CreateConVar("ddos_protection_endpoint", "https://l4d2-server-manager-api.azurewebsites.net", "DDoS endpoint", FCVAR_PROTECTED);
	cvar_ddos_protection_access_token = CreateConVar("ddos_protection_access_token", "", "DDoS Access Token", FCVAR_PROTECTED);

	IntToString(GetConVarInt(FindConVar("hostport")), port, sizeof(port));

	RegAdminCmd("sm_ddos", DDoS, ADMFLAG_BAN);
}

public Action:DDoS(client, args)
{
	decl String:command[32];
	GetCmdArgString(command, sizeof(command));

	if (StrEqual(command, "close"))
		ClosePort();

	else if (StrEqual(command, "open"))
		OpenPort();

	else if (StrEqual(command, "status"))
		PortStatus();

	else
		OpenPortIP(command);
}

void ClosePort()
{
	PrintToChatAll("Fechando porta do servidor...");

	new String:endpoint[255] = "/api/server/";
	StrCat(endpoint, sizeof(endpoint), port);
	StrCat(endpoint, sizeof(endpoint), "/close-port");

	JSONObject command = new JSONObject();

	HTTPRequest request = BuildHTTPRequest(endpoint);
	request.Put(command, ClosePortResponse);
}

void ClosePortResponse(HTTPResponse httpResponse, any value)
{
	if (httpResponse.Status != HTTPStatus_OK)
	{
		PrintToChatAll("\x04Falha ao fechar a porta do servidor");
		return;
	}

	PrintToChatAll("\x04[X] \x01- \x03Porta fechada com sucesso");
}

void OpenPort()
{
	PrintToChatAll("Abrindo porta do servidor...");

	new String:endpoint[255] = "/api/server/";
	StrCat(endpoint, sizeof(endpoint), port);
	StrCat(endpoint, sizeof(endpoint), "/open-port");

	JSONObject command = new JSONObject();
	command.SetString("ranges", "*");

	HTTPRequest request = BuildHTTPRequest(endpoint);
	request.Put(command, OpenPortResponse);
}

void OpenPortResponse(HTTPResponse httpResponse, any value)
{
	if (httpResponse.Status != HTTPStatus_OK)
	{
		PrintToChatAll("\x04Falha ao abrir a porta do servidor");
		return;
	}

	PrintToChatAll("\x04[  ] \x01- \x03Porta aberta com sucesso");
}

void OpenPortIP(char[] ip)
{
	PrintToChatAll("\x01Abrindo porta do servidor para o IP \x03%s\x01...", ip);

	new String:endpoint[255] = "/api/server/";
	StrCat(endpoint, sizeof(endpoint), port);
	StrCat(endpoint, sizeof(endpoint), "/open-port");

	JSONObject command = new JSONObject();
	command.SetString("ranges", ip);

	HTTPRequest request = BuildHTTPRequest(endpoint);
	request.Put(command, OpenPortIPResponse);
}

void OpenPortIPResponse(HTTPResponse httpResponse, any value)
{
	if (httpResponse.Status != HTTPStatus_OK)
	{
		PrintToChatAll("\x04Falha ao abrir a porta do servidor para o IP informado");
		return;
	}

	PrintToChatAll("\x04[ * ] \x01- \x03Porta aberta com sucesso para o IP informado");
}

void PortStatus()
{
	PrintToChatAll("Consultando status da porta do servidor...");

	new String:endpoint[255] = "/api/server/";
	StrCat(endpoint, sizeof(endpoint), port);

	HTTPRequest request = BuildHTTPRequest(endpoint);
	request.Get(PortStatusResponse);
}

void PortStatusResponse(HTTPResponse httpResponse, any value)
{
	if (httpResponse.Status != HTTPStatus_OK)
	{
		PrintToChatAll("\x04Falha ao consultar o status da porta do servidor");
		return;
	}

	JSONObject response = view_as<JSONObject>(httpResponse.Data);
	JSONObject portInfo = view_as<JSONObject>(response.Get("portInfo"));

	int status = portInfo.GetInt("status");

	char rules[32];
	portInfo.GetString("rules", rules, sizeof(rules));

	if (status == 0 && StrEqual(rules, "*"))
		PrintToChatAll("\x04[  ] \x01- \x01Porta do servidor aberta");

	else if (status == 0 && !StrEqual(rules, "*"))
		PrintToChatAll("\x04[ * ] \x01- \x01Porta do servidor aberta para o IP \x03%s", rules);

	else if (status == 1)
		PrintToChatAll("\x04[X] \x01- \x01Porta do servidor fechada");
}

HTTPRequest BuildHTTPRequest(char[] path)
{
	new String:endpoint[255];
	GetConVarString(cvar_ddos_protection_endpoint, endpoint, sizeof(endpoint));
	StrCat(endpoint, sizeof(endpoint), path);

	new String:access_token[100];
	GetConVarString(cvar_ddos_protection_access_token, access_token, sizeof(access_token));

	HTTPRequest request = new HTTPRequest(endpoint);
	request.SetHeader("Authorization", access_token);

	return request;
}