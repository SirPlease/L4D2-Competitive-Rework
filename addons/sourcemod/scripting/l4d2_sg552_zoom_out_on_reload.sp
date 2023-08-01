#include <sourcemod>

public Plugin:myinfo = 
{
	name = "[L4D2] SG552 - Zoom out on reload",
	author = "Altair Sossai",
	description = "Remove zoom from the SG552 weapon when reloading, preventing the player's camera from getting stuck",
	version = "1.0",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
}

bool bZoom[MAXPLAYERS + 1];

public OnPluginStart()
{
	HookEvent("weapon_zoom", WeaponZoom_Event);
	HookEvent("weapon_reload", WeaponReload_Event);
}

public void WeaponZoom_Event(Event hEvent, const char[] eName, bool dontBroadcast)
{
	int userid = GetEventInt(hEvent, "userid");
	int client = GetClientOfUserId(userid);

	bZoom[client] = UsingTheGunSG552(client);
}

public void WeaponReload_Event(Event hEvent, const char[] eName, bool dontBroadcast)
{
	int userid = GetEventInt(hEvent, "userid");
	int client = GetClientOfUserId(userid);

	if (!bZoom[client])
		return;

	bZoom[client] = false;

	if (!UsingTheGunSG552(client))
		return;

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