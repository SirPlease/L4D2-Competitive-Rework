#pragma semicolon 1

#include <sourcemod>
#include <left4dhooks>

public Plugin myinfo =
{
	name = "No Tank",
	author = "Don, Forgetest",
	description = "Slays any tanks that spawn. Designed for 1v1 configs.",
	version = "1.2",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	char sGame[12];
	GetGameFolderName(sGame, sizeof(sGame));
	if (StrEqual(sGame, "left4dead") || StrEqual(sGame, "left4dead2"))	// Only load the plugin if the server is running Left 4 Dead or Left 4 Dead 2.
	{
		return APLRes_Success;
	}
	else
	{
		strcopy(error, err_max, "Plugin only supports L4D1/2");
		return APLRes_Failure;
	}
}

public Action L4D_OnSpawnTank(const float vecPos[3], const float vecAng[3])
{
	return Plugin_Handled;
}