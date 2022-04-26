#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sourcescramble>

#define PLUGIN_VERSION "1.0"

public Plugin myinfo = 
{
	name = "[L4D & 2] Fix Finale Breakable",
	author = "Forgetest",
	description = "Fix SI being unable to break props/walls within finale area before finale starts.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
};

public void OnPluginStart()
{
	Handle conf = LoadGameConfigFile("l4d_fix_finale_breakable");
	if (conf == null)
		SetFailState("Missing gamedata \"l4d_fix_finale_breakable\"");
	
	if (!MemoryPatch.CreateFromConf(conf, "CBreakableProp::OnTakeDamage__IsFinale_force_jump").Enable())
		SetFailState("Failed to patch \"CBreakableProp::OnTakeDamage__IsFinale_force_jump\"");
	
	delete conf;
}