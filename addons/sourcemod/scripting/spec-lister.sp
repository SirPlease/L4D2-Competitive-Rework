#include <sourcemod>
#include <sdktools>

#define VOICE_NORMAL	0	
#define VOICE_SPEAKALL	2	
#define VOICE_LISTENALL	4	
#define TEAM_SPEC 1
#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "SpecLister",
	author = "waertf & bear",
	description = "Allows spectator listen others team voice for l4d",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=95474"
}

public OnPluginStart()
{
	RegConsoleCmd("hear", Panel_hear);
}

public PanelHandler1(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		PrintToConsole(param1, "You selected item: %d", param2)

		if(param2 == 1)
		{
			SetClientListeningFlags(param1, VOICE_LISTENALL);
			PrintToChat(param1,"\x04[Ouvir]\x03Habilitado");
		}
		else
		{
			SetClientListeningFlags(param1, VOICE_NORMAL);
			PrintToChat(param1,"\x04[Ouvir]\x03Desabilitado");
		}
	} 
	else if (action == MenuAction_Cancel) 
	{
		PrintToServer("Client %d's menu foi cancelado.  Reason: %d", param1, param2);
	}
}

public Action:Panel_hear(client,args)
{
	if(GetClientTeam(client) != TEAM_SPEC)
		return Plugin_Handled;

	new Handle:panel = CreatePanel();

	SetPanelTitle(panel, "Deseja ouvir os jogadores?");
	DrawPanelItem(panel, "Sim");
	DrawPanelItem(panel, "Não");
 
	SendPanelToClient(panel, client, PanelHandler1, 20);
 
	CloseHandle(panel);
 
	return Plugin_Handled;
}

public OnClientPutInServer(client)
{
	CreateTimer(40.0, TimerAnnounce, client);
}

public Action:TimerAnnounce(Handle:timer, any:client)
{
	if (IsClientInGame(client))
		PrintToChat(client,"\x04[Ouvir]Para ouvir os jogadores digite: \03!hear");
}