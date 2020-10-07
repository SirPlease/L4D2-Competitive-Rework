#include <sourcemod>

new Handle:hCvarMaxZombies;

public Plugin:myinfo = {
	name = "Character Fix",
	author = "someone",
	version = "0.1",
	description = "Fixes character change exploit in 1v1, 2v2, 3v3"
};

public OnPluginStart() {
	AddCommandListener(TeamCmd, "jointeam")
	hCvarMaxZombies = FindConVar("z_max_player_zombies");
}

public Action:TeamCmd(client, const String:command[], argc) {
	if (client && argc > 0)
	{
		static String:sBuffer[128];
		GetCmdArg(1, sBuffer, sizeof(sBuffer));
		new newteam = StringToInt(sBuffer);
		if (GetClientTeam(client)==2 && (StrEqual("Infected", sBuffer, false) || newteam==3))
		{
			new zombies = 0;
			for (new i=1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && GetClientTeam(i)==3)
					zombies++;
			}
			if (zombies>=GetConVarInt(hCvarMaxZombies))
				return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}