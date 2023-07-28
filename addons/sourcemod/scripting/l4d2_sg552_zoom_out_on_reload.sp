#include <sourcemod>

public Plugin:myinfo = 
{
	name = "[L4D2] SG552 - Zoom out on reload",
	author = "Altair Sossai",
	description = "Remove zoom from the SG552 weapon when reloading, preventing the player's camera from getting stuck",
	version = "1.0",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
}

public OnPluginStart()
{
	HookEvent("weapon_reload", WeaponReload_Event);
}

public void WeaponReload_Event(Event hEvent, const char[] eName, bool dontBroadcast)
{
	int userid = GetEventInt(hEvent, "userid");
	int client = GetClientOfUserId(userid);
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

	char classname[256];
	GetEntityClassname(weapon, classname, sizeof(classname));

	if(StrContains(classname, "sg552", false) == -1)
		return;

	SetEntPropFloat(client, Prop_Send, "m_flFOVTime", 0.0);
	SetEntPropFloat(client, Prop_Send, "m_flFOVRate", 0.0);
	SetEntProp(client, Prop_Send, "m_iFOV", 0);
}