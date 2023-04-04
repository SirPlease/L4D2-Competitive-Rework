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
	LoadTranslations("l4d2_connect_announce.phrases");

	early = true;
}

public void OnMapStart()
{
	early = true;
	CreateTimer(25.0, EarlyTimer);
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