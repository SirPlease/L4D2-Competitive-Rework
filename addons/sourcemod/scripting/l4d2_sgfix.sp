#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "[L4D2] SG552 Reload Fix",
	author = "McFlurry, Altair Sossai",
	description = "Fixes the reload time of SG552",
	version = PLUGIN_VERSION,
	url = "N/A"
}

public OnPluginStart()
{
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("Plugin supports Left 4 Dead 2 only.");
	}

	HookEvent("weapon_reload", Event_ReloadStart);
}

public Action:Event_ReloadStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	new String:classname[256];

	GetEntityClassname(weapon, classname, sizeof(classname));

	if(StrContains(classname, "sg552", false) > -1)
	{
		new Float:nextattack;
		nextattack = GetEntPropFloat(client, Prop_Send, "m_flNextAttack");
		nextattack -= 0.6;
		SetEntPropFloat(client, Prop_Send, "m_flNextAttack", nextattack);
		SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", nextattack);
		SetEntPropEnt(client, Prop_Send, "m_hZoomOwner", -1);
		SetEntPropFloat(client, Prop_Send, "m_flFOVTime", 0.0);
		SetEntPropFloat(client, Prop_Send, "m_flFOVRate", 0.0);
		SetEntProp(client, Prop_Send, "m_iFOV", 0);
	}	
}