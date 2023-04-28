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
	RegConsoleCmd("hear", PanelCommand);
}

public PanelHandler(Handle:menu, MenuAction:action, client, selectedValue)
{
	if (action == MenuAction_Select)
	{
		PrintToConsole(client, "You selected item: %d", selectedValue)

		if(selectedValue == 1)
		{
			SetClientListeningFlags(client, VOICE_LISTENALL);
			PrintToChat(client,"\x04[Ouvir] \x03Habilitado");
		}
		else
		{
			SetClientListeningFlags(client, VOICE_NORMAL);
			PrintToChat(client,"\x04[Ouvir] \x03Desabilitado");
		}
	} 
}

public Action:PanelCommand(client,args)
{
	if(GetClientTeam(client) != TEAM_SPEC)
		return Plugin_Handled;

	new Handle:panel = CreatePanel();

	SetPanelTitle(panel, "Deseja ouvir os jogadores?");
	DrawPanelItem(panel, "Sim");
	DrawPanelItem(panel, "Não");
 
	SendPanelToClient(panel, client, PanelHandler, 20);
 
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
		PrintToChat(client,"\x04[Ouvir] Para ouvir os jogadores digite: \03!hear");
}