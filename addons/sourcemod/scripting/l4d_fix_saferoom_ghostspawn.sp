#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sourcescramble>

#define PLUGIN_VERSION "1.0"

public Plugin myinfo =
{
    name = "[L4D & 2] Fix Saferoom Ghost Spawn",
    author = "Forgetest",
    description = "Fix a glitch that ghost can spawn in saferoom while it shouldn't.",
    version = PLUGIN_VERSION,
    url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
};

public void OnPluginStart()
{
    GameData gd = new GameData("l4d_fix_saferoom_ghostspawn");
    if (!gd)
        SetFailState("Missing gamedata \"l4d_fix_saferoom_ghostspawn\"");
	
    if (!MemoryPatch.CreateFromConf(gd, "CTerrorPlayer::OnPreThinkGhostState__IsOverlapping_conditional_move").Enable())
        SetFailState("Failed to patch \"CTerrorPlayer::OnPreThinkGhostState__IsOverlapping_conditional_move\"");
	
    delete gd;
}