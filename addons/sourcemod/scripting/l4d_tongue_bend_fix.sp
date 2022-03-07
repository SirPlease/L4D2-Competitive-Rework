#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sourcescramble>

#define PLUGIN_VERSION "1.0"

public Plugin myinfo =
{
	name = "[L4D & 2] Tongue Bend Fix",
	author = "Forgetest",
	description = "Fix unexpected tongue breaks for \"bending too many times\".",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
}

#define GAMEDATA_FILE "l4d_tongue_bend_fix"
#define PATCH_KEY "CTongue::OnUpdateAttachedToTargetState__UpdateBend_jump_patch"

public void OnPluginStart()
{
	Handle conf = LoadGameConfigFile(GAMEDATA_FILE);
	if (!conf) SetFailState("Missing gamedata \""...GAMEDATA_FILE..."\"");
	
	MemoryPatch hPatch = MemoryPatch.CreateFromConf(conf, PATCH_KEY);
	if (!hPatch.Validate()) SetFailState("Failed to validate patch \""...PATCH_KEY..."\"");
	
	delete conf;
	
	if (!hPatch.Enable()) SetFailState("Failed to enable patch \""...PATCH_KEY..."\"");
}