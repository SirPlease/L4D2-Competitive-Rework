#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>
#include <@Forgetest/gamedatawrapper>

#define PLUGIN_VERSION "1.0"

public Plugin myinfo = 
{
	name = "[L4D & 2] Fix Prop LOS",
	author = "Forgetest",
	description = "Fix thin/small 'prop_*' entity not blocking LOS.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins",
}

public void OnPluginStart()
{
	GameDataWrapper gd = new GameDataWrapper("l4d_fix_prop_los");
	delete gd.CreateDetourOrFail("l4d_fix_prop_los::CBaseProp::CalculateBlockLOS", DTR_CalculateBlockLOS);
	delete gd;
}

MRESReturn DTR_CalculateBlockLOS(int entity)
{
	return MRES_Supercede;
}