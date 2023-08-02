#include <sourcemod>

public Plugin:myinfo = 
{
	name = "[L4D2] SG552 - Zoom fix",
	author = "Altair Sossai",
	description = "Fix SG552 zoom, preventing the player's camera from getting stuck",
	version = "1.0",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
}

public OnPluginStart()
{
	HookEvent("weapon_zoom", WeaponZoom_Event);
}

public void WeaponZoom_Event(Event hEvent, const char[] eName, bool dontBroadcast)
{
	int userid = GetEventInt(hEvent, "userid");
	int client = GetClientOfUserId(userid);

	if (GetEntProp(client, Prop_Send, "m_hZoomOwner") == -1 && UsingTheGunSG552(client))
		UnZoom(client);
}

stock void UnZoom(int client)
{
	SetEntPropFloat(client, Prop_Send, "m_flFOVTime", 0.0);
	SetEntPropFloat(client, Prop_Send, "m_flFOVRate", 0.0);
	SetEntProp(client, Prop_Send, "m_iFOV", 0);
}

stock bool UsingTheGunSG552(int client)
{
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

	char classname[256];
	GetEntityClassname(weapon, classname, sizeof(classname));

	return StrEqual(classname, "weapon_rifle_sg552");
}