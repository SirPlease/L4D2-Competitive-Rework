#include <sourcemod>
#include <left4dhooks>

#define L4D2_TEAM_INFECTED 3

public Plugin myinfo =
{
	name = "L4D2 - Prevent killing yourself as infected",
	author = "Altair Sossai",
	description = "Prevents the player from killing himself while infected",
	version = "1.0.0",
	url = "https://github.com/altair-sossai/l4d2-zone-server"
};

public void OnPluginStart()
{
	AddCommandListener(SpectateCmd, "sm_spectate");
	AddCommandListener(SpectateCmd, "sm_spec");
	AddCommandListener(SpectateCmd, "sm_s");
}

public Action SpectateCmd(int client, const char[] command, int argc) 
{
	if (!IsAliveInfected(client))
		return Plugin_Continue;

	WarnExploiting(client);

	return Plugin_Stop;
}

bool IsAliveInfected(int client)
{
	if (client <= 0 || client > MaxClients)
		return false;

	if (!IsClientInGame(client) || IsFakeClient(client))
		return false;

	int team = GetClientTeam(client);
	if (team != L4D2_TEAM_INFECTED)
		return false;

	return IsPlayerAlive(client) && !GetEntProp(client, Prop_Send, "m_isGhost");
}

void WarnExploiting(int client)
{
	PrintToChat(client, "\x01You can't go to \x04spec\x01 while is alive");
}