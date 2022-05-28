#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>

#define PLUGIN_VERSION "3.0"

public Plugin myinfo =
{
	name = "[L4D & 2] Tongue Bend Fix",
	author = "Forgetest",
	description = "Fix unexpected tongue breaks for \"bending too many times\".",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
}

#define GAMEDATA_FILE "l4d_tongue_bend_fix"
#define KEY_UPDATEBEND "CTongue::UpdateBend"

public void OnPluginStart()
{
	Handle conf = LoadGameConfigFile(GAMEDATA_FILE);
	if (!conf) SetFailState("Missing gamedata \""...GAMEDATA_FILE..."\"");
	
	DynamicDetour hDetour = DynamicDetour.FromConf(conf, KEY_UPDATEBEND);
	if (!hDetour) SetFailState("Missing signature \""...KEY_UPDATEBEND..."\"");
	if (!hDetour.Enable(Hook_Pre, DTR_OnUpdateBend)) SetFailState("Failed to pre-detour \""...KEY_UPDATEBEND..."\"");
	
	delete conf;
}

MRESReturn DTR_OnUpdateBend(int pThis, DHookReturn hReturn)
{
	if (GetEntProp(pThis, Prop_Send, "m_bendPointCount") > 9)
	{
		// should be bugged, ignore now.
		hReturn.Value = 0;
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}