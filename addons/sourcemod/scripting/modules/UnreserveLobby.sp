#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <left4downtown>

new Handle:UL_hEnable;
// native L4D_LobbyUnreserve();

UL_OnModuleStart()
{
	UL_hEnable	= CreateConVarEx("match_killlobbyres", "1", "Sets whether the plugin will clear lobby reservation once a match have begun");
	RegAdminCmd("sm_killlobbyres", UL_KillLobbyRes, ADMFLAG_BAN, "Forces the plugin to kill lobby reservation");
	// MarkNativeAsOptional("L4D_LobbyUnreserve");
}

bool:UL_CheckVersion()
{
	if(FindConVar("left4downtown_version") != INVALID_HANDLE) 
	{
		return false;
	}
	
	return true;
}

UL_OnClientPutInServer()
{
	if(!IsPluginEnabled() || !GetConVarBool(UL_hEnable)){return;}
	
	if(UL_CheckVersion())
	{
		LogError("Failed to unreserve lobby. Left4Downtown is outdated!");
		return;
	}
	
	L4D_LobbyUnreserve();
}

public Action:UL_KillLobbyRes(client,args)
{
	if(UL_CheckVersion())
	{
		LogError("Failed to unreserve lobby. Left4Downtown is outdated!");
		return;
	}
	
	L4D_LobbyUnreserve();
}