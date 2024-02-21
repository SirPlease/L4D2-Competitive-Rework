#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

new Handle:PS_hPassword;
new Handle:PS_hReloaded;
new bool:PS_bIsPassworded = false;
new bool:PS_bSuppress = false;
new String:PS_sPassword[128];

PS_OnModuleStart()
{
	PS_hPassword = CreateConVarEx("password", "", "Set a password on the server, if empty password disabled. See Confogl's wiki for more information",FCVAR_DONTRECORD|FCVAR_PROTECTED);
	
	HookConVarChange(PS_hPassword,PS_ConVarChange);
	HookEvent("player_disconnect", PS_SuppressDisconnectMsg, EventHookMode_Pre);
	
	PS_hReloaded = FindConVarEx("password_reloaded");
	if(PS_hReloaded == INVALID_HANDLE)
	{
		PS_hReloaded = CreateConVarEx("password_reloaded", "", "DONT TOUCH THIS CVAR! This will is to make sure that the password gets set upon the plugin is reloaded",FCVAR_DONTRECORD|FCVAR_UNLOGGED);
	}
	else
	{
		decl String:sBuffer[128];
		GetConVarString(PS_hReloaded,sBuffer,sizeof(sBuffer));
		
		SetConVarString(PS_hPassword,sBuffer);
		SetConVarString(PS_hReloaded,"");
		
		GetConVarString(PS_hPassword,PS_sPassword,128);
		PS_bIsPassworded = true;
		PS_SetPasswordOnClients();
	}
}

PS_OnModuleEnd()
{
	if(!PS_bIsPassworded){return;}
	SetConVarString(PS_hReloaded,PS_sPassword);
}

PS_CheckPassword(client)
{
	if(!PS_bIsPassworded || !IsPluginEnabled()){return;}
	CreateTimer(0.1,PS_CheckPassword_Timer,client,TIMER_REPEAT);
}

public Action:PS_CheckPassword_Timer(Handle:timer,any:client)
{
	if(!IsClientConnected(client) || IsFakeClient(client)){return Plugin_Stop;}
	if(!IsClientInGame(client)){return Plugin_Continue;}
	QueryClientConVar(client, "sv_password", PS_ConVarDone);
	return Plugin_Stop;
}

public PS_ConVarDone(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[], any:value)
{
	if(result == ConVarQuery_Okay)
	{
		decl String:buffer[128];
		GetConVarString(PS_hPassword,buffer,128);
		
		if(StrEqual(buffer,cvarValue))
		{
			return;
		}
	}
	
	PS_bSuppress = true;
	KickClient(client,"Bad password");
}

public PS_ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	GetConVarString(PS_hPassword,PS_sPassword,128);
	if(strlen(PS_sPassword) > 0)
	{
		PS_bIsPassworded = true;
		PS_SetPasswordOnClients();
	}
	else
	{
		PS_bIsPassworded = false;
	}
}

public Action:PS_SuppressDisconnectMsg(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(dontBroadcast || !PS_bSuppress){return Plugin_Continue;}
	
	decl String:clientName[33], String:networkID[22], String:reason[65];
	GetEventString(event, "name", clientName, sizeof(clientName));
	GetEventString(event, "networkid", networkID, sizeof(networkID));
	GetEventString(event, "reason", reason, sizeof(reason));
	
	new Handle:newEvent = CreateEvent("player_disconnect", true);
	SetEventInt(newEvent, "userid", GetEventInt(event, "userid"));
	SetEventString(newEvent, "reason", reason);
	SetEventString(newEvent, "name", clientName);        
	SetEventString(newEvent, "networkid", networkID);
	FireEvent(newEvent, true);
	
	PS_bSuppress = false;
	return Plugin_Handled;
}

PS_OnMapEnd()
{
	PS_SetPasswordOnClients();
}

PS_OnClientPutInServer(client)
{
	PS_CheckPassword(client);
}

PS_SetPasswordOnClients()
{
	decl String:pwbuffer[128];
	GetConVarString(PS_hPassword,pwbuffer,128);
	
	for(new client = 1;client<=MaxClients;client++)
	{
		if(!IsClientInGame(client) || IsFakeClient(client)){continue;}
		LogMessage("Set password on %N, password %s",client,pwbuffer);
		ClientCommand(client,"sv_password \"%s\"",pwbuffer);
	}
}