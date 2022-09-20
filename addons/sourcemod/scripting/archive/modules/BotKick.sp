#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

static 			BK_iEnable;
static Handle:	BK_hEnable;

static 			BK_lastvalidbot = -1;

static const Float:CHECKALLOWEDTIME = 0.1;
static const Float:BOTREPLACEVALIDTIME = 0.2;


BK_OnModuleStart()
{
	HookEvent("player_bot_replace", BK_PlayerBotReplace);
	
	BK_hEnable = CreateConVarEx("blockinfectedbots","1","Blocks infected bots from joining the game, minus when a tank spawns (1 allows bots from tank spawns, 2 removes all infected bots)");
	HookConVarChange(BK_hEnable,BK_ConVarChange);
	
	BK_iEnable = GetConVarInt(BK_hEnable);
}

public BK_ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	BK_iEnable = GetConVarInt(BK_hEnable);
}

public BK_PlayerBotReplace(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!IsTankInPlay()) return;
	new client = GetClientOfUserId(GetEventInt(event, "player"));
	if(client && IsClientInGame(client) && GetClientTeam(client) == 3)
	{
		BK_lastvalidbot = GetClientOfUserId(GetEventInt(event, "bot"));
		CreateTimer(BOTREPLACEVALIDTIME, BK_CancelValidBot_Timer);
	}

}

public Action:BK_CancelValidBot_Timer(Handle:timer)
{
	BK_lastvalidbot = -1;
}

public Action:BK_CheckInfBotReplace_Timer(Handle:timer, any:data)
{
	new client = data;
	if(client != BK_lastvalidbot && IsClientInGame(client) && IsFakeClient(client))
	{
		KickClient(client,"[Confogl] Kicking late infected bot...");
	}
	else
	{
		BK_lastvalidbot = -1;
	}
	return Plugin_Handled;
}

public bool:OnClientConnect(client, String:rejectmsg[],maxlen)
{
	if(!IsFakeClient(client) || !BK_iEnable || !IsPluginEnabled()) // If the BK_iEnable is false, we don't do anything
	{
		return true;
	}
	
	decl String:name[11];
	GetClientName(client, name, sizeof(name));
	
	if(StrContains(name, "smoker", false) == -1 && // If the client doesn't have a bot infected's name, let it in
		StrContains(name, "boomer", false) == -1 && 
		StrContains(name, "hunter", false) == -1 && 
		StrContains(name, "spitter", false) == -1 && 
		StrContains(name, "jockey", false) == -1 && 
		StrContains(name, "charger", false) == -1)
	{
		return true;
	}
		
	if(BK_iEnable == 1 && IsTankInPlay()) // Bots only allowed to try to connect when there's a tank in play.
	{
		// Check this bot in CHECKALLOWEDTIME seconds to see if he's supposed to be allowed.
		CreateTimer(CHECKALLOWEDTIME, BK_CheckInfBotReplace_Timer, client);
		//BK_bAllowBot = false;
		return true;
	}
	
	KickClient(client,"[Confogl] Kicking infected bot..."); // If all else fails, bots arent allowed and must be kicked
	
	return false;
}