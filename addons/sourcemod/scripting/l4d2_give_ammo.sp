#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define L4D2_TEAM_SURVIVOR 2

public Plugin myinfo =
{
	name		= "L4D2 - Give ammo",
	author		= "Altair Sossai",
	description = "Reloads every player's weapon",
	version		= "1.0.0",
	url			= "https://github.com/altair-sossai/l4d2-zone-server"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_giveammo", GiveAmmoCmd, ADMFLAG_BAN);
}

public void OnRoundIsLive()
{
    GiveAmmo();
}

public Action GiveAmmoCmd(int client, int args)
{
	GiveAmmo();
	return Plugin_Handled;
}

public void GiveAmmo()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || IsFakeClient(client) || !SurvivorTeam(client))
			continue;

		new flags = GetCommandFlags("give");
		SetCommandFlags("give", flags ^ FCVAR_CHEAT);
		FakeClientCommand(client, "give ammo");
		SetCommandFlags("give", flags);
	}
}

public bool SurvivorTeam(int client)
{
	int clientTeam = GetClientTeam(client);
	
	return clientTeam == L4D2_TEAM_SURVIVOR;
}