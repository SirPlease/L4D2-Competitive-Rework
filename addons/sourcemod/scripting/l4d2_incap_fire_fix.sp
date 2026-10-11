#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define BUFFER_TIME 0.5
bool g_bBlocked[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name        = "[L4D/2] Incap Fire Fix",
	author      = "Sir",
	description = "Lets incapacitated survivors fire their weapon normally (with sound) while holding shove",
	version     = "1.0.1",
	url         = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (!IsClientInGame(client) || GetClientTeam(client) != 2)
		return Plugin_Continue;

	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) > 0)
	{
		int wep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (wep != -1 && GetEntProp(wep, Prop_Send, "m_iClip1") > 0)
		{
			SetEntPropFloat(wep, Prop_Send, "m_flNextSecondaryAttack", GetGameTime() + BUFFER_TIME);
			g_bBlocked[client] = true;
		}
	}
	else if (g_bBlocked[client])
	{
		int wep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (wep != -1)
			SetEntPropFloat(wep, Prop_Send, "m_flNextSecondaryAttack", GetGameTime());

		g_bBlocked[client] = false;
	}

	return Plugin_Continue;
}
