#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define FINALE_STAGE_TANK 8

new Handle:hFinaleExceptionMaps;

new iTankCount[2];

public Plugin:myinfo =
{
	name = "Finale Even-Numbered Tank Blocker",
	author = "Stabby, Visor",
	description = "Blocks even-numbered non-flow finale tanks.",
	version = "2",
	url = "http://github.com/ConfoglTeam/ProMod"
};

public OnPluginStart()
{
	RegServerCmd("finale_tank_default", SetFinaleExceptionMap);

	hFinaleExceptionMaps = CreateTrie();
}

public Action:SetFinaleExceptionMap(args)
{
	decl String:mapname[64];
	GetCmdArg(1, mapname, sizeof(mapname));
	SetTrieValue(hFinaleExceptionMaps, mapname, true);
}

public Action:L4D2_OnChangeFinaleStage(&finaleType, const String:arg[])
{
	decl String:mapname[64];
	GetCurrentMap(mapname, sizeof(mapname));

	decl dummy;
	if (GetTrieValue(hFinaleExceptionMaps, mapname, dummy))
		return Plugin_Continue;

	if (finaleType == FINALE_STAGE_TANK)
	{
		if (++iTankCount[GameRules_GetProp("m_bInSecondHalfOfRound")] % 2 == 0)
			return Plugin_Handled;
	}
	return Plugin_Continue;
}

public OnMapEnd()
{
	iTankCount[0] = 0;
	iTankCount[1] = 0;
}