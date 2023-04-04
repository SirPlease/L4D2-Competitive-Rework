#include <sourcemod>
#include <sdktools>
#include <colors>

char txtBufer[256];
bool early;

public Plugin:myinfo =  {
	name = "Connect Announce", 
	author = "pa4H", 
	description = "", 
	version = "1.0", 
	url = "vk.com/pa4h1337"
};

public OnPluginStart()
{
	HookEvent("player_disconnect", PlayerDisconnect_Event, EventHookMode_Pre);
	LoadTranslations("l4d2_connect_announce.phrases");

	early = true;
}

public void OnMapStart()
{
	early = true;
	CreateTimer(30.0, EarlyTimer);
}

public Action EarlyTimer(Handle timer)
{
	early = false;
	return Plugin_Stop;
}

public OnClientAuthorized(client)
{
	if (early || IsFakeClient(client))
		return;

	char clientName[64]; 
	GetClientName(client, clientName, sizeof(clientName));
	
	FormatEx(txtBufer, sizeof(txtBufer), "%t", "PlayerLoading", clientName);
	CPrintToChatAll(txtBufer);
}

public Action PlayerDisconnect_Event(Handle event, const char[] param, bool dontBroadcast)
{
	if (early)
		return Plugin_Handled;

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!IsValidClient(client)) 
		return Plugin_Handled;

	char name[64]; 
	GetEventString(event, "name", name, sizeof(name));
	
	char reason[64];
	GetEventString(event, "reason", reason, sizeof(reason));
	ReplaceString(reason, sizeof(reason), ".", "")
	
	FormatEx(txtBufer, sizeof(txtBufer), "%t", "PlayerDisconnect", name, reason);
	CPrintToChatAll(txtBufer);

	return Plugin_Handled;
}

public OnClientPutInServer(client)
{
	if (early || IsFakeClient(client))
		return;

	char clientName[64]; 
	GetClientName(client, clientName, sizeof(clientName));

	FormatEx(txtBufer, sizeof(txtBufer), "%t", "PlayerJoin", clientName);
	CPrintToChatAll(txtBufer);
}

stock bool IsValidClient(client)
{
	return client > 0 && client <= MaxClients && IsClientConnected(client) && !IsFakeClient(client);
}