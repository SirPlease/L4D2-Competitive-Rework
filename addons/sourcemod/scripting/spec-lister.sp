#include <sourcemod>
#include <sdktools>

#define VOICE_NORMAL 0	
#define VOICE_SPEAKALL 2	
#define VOICE_LISTENALL 4	
#define TEAM_SPEC 1

public Plugin:myinfo = 
{
	name = "SpecLister",
	author = "waertf & bear",
	description = "Allows spectator listen others team voice for l4d",
	version = "1.0",
	url = "http://forums.alliedmods.net/showthread.php?t=95474"
}

public OnPluginStart()
{
	HookEvent("player_team", PlayerChangeTeamEvent);

	RegConsoleCmd("hear", PanelCommand);
}

public PlayerChangeTeamEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userId = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userId);
	new team = GetEventInt(event, "team");
	
	if(client == 0)
		return ;

	SetClientListeningFlags(client, team == TEAM_SPEC ? VOICE_LISTENALL : VOICE_NORMAL);
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

public PanelHandler(Handle:menu, MenuAction:action, client, selectedValue)
{
	if (action != MenuAction_Select)
		return;

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

public OnClientPutInServer(client)
{
	CreateTimer(20.0, TimerAnnounce, client);
}

public Action:TimerAnnounce(Handle:timer, any:client)
{
	if (!IsClientInGame(client))
		return;

	PrintToChat(client, "\x04[Ouvir] \x01Para ouvir os jogadores digite: \03!hear");
}