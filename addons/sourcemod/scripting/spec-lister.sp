#include <sourcemod>
#include <sdktools>

#define VOICE_NORMAL	0	/**< Allow the client to listen and speak normally. */
#define VOICE_MUTED		1	/**< Mutes the client from speaking to everyone. */
#define VOICE_SPEAKALL	2	/**< Allow the client to speak to everyone. */
#define VOICE_LISTENALL	4	/**< Allow the client to listen to everyone. */
#define VOICE_TEAM		8	/**< Allow the client to always speak to team, even when dead. */
#define VOICE_LISTENTEAM	16	/**< Allow the client to always hear teammates, including dead ones. */

#define TEAM_SPEC 1
#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3


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
	HookEvent("player_team",Event_PlayerChangeTeam);
	RegConsoleCmd("hear", Panel_hear);

}
public PanelHandler1(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		PrintToConsole(param1, "You selected item: %d", param2)
		if(param2==1)
			{
			SetClientListeningFlags(param1, VOICE_LISTENALL);
			PrintToChat(param1,"\x04[listen]\x03enable" );
			}
		else
			{
			SetClientListeningFlags(param1, VOICE_NORMAL);
			PrintToChat(param1,"\x04[listen]\x03disable" );
			}
		
	} else if (action == MenuAction_Cancel) {
		PrintToServer("Client %d's menu was cancelled.  Reason: %d", param1, param2);
	}
}


public Action:Panel_hear(client,args)
{
	if(GetClientTeam(client)!=TEAM_SPEC)
		return Plugin_Handled;
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "Enable listen mode ?");
	DrawPanelItem(panel, "yes");
	DrawPanelItem(panel, "no");
 
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
	PrintToChat(client,"\x04[listen]enable for spector only¡G\03!hear" );
}

public Event_PlayerChangeTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userID = GetClientOfUserId(GetEventInt(event, "userid"));
	new userTeam = GetEventInt(event, "team");
	if(userID==0)
		return ;

	//PrintToChat(userID,"\x02X02 \x03X03 \x04X04 \x05X05 ");\\ \x02:color:default \x03:lightgreen \x04:orange \x05:darkgreen
	
	if(userTeam==TEAM_SPEC)
	{
		SetClientListeningFlags(userID, VOICE_LISTENALL);
		PrintToChat(userID,"\x04[listen]\x03enable" )
		
	}
	else
	{
		SetClientListeningFlags(userID, VOICE_NORMAL);
		PrintToChat(userID,"\x04[listen]\x03disable" )
	}
}
	
