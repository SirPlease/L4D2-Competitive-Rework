#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sourcescramble>

#define PLUGIN_VERSION "1.0"
//PS插件来自音理，Forgetest编写，但是没有源码，我反编译了一下，并且用AI模仿Forgetest的写法编写了源码
public Plugin myinfo = 
{
	name = "[L4D & 2] Fix Smoker Bot Float",
	author = "Forgetest",
	description = "Fixes smoker bot floating in mid-air using a binary patch.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
};

#define GAMEDATA_FILE "l4d_fix_smokerbot_float"
#define PATCH_SKIP_ZEROING_VELOCITY "skip_zeroing_velocity"

MemoryPatch g_hPatch;

public void OnPluginStart()
{
	GameData gd = new GameData(GAMEDATA_FILE);
	if (!gd)
	{
		SetFailState("Missing gamedata \"%s\"", GAMEDATA_FILE);
	}

	g_hPatch = MemoryPatch.CreateFromConf(gd, PATCH_SKIP_ZEROING_VELOCITY);
	if (!g_hPatch.Validate())
	{
		SetFailState("Failed to validate patch \"%s\"", PATCH_SKIP_ZEROING_VELOCITY);
	}

	if (!g_hPatch.Enable())
	{
		SetFailState("Failed to enable patch \"%s\"", PATCH_SKIP_ZEROING_VELOCITY);
	}

	delete gd;
}

public void OnPluginEnd()
{
	if (g_hPatch != null)
	{
		g_hPatch.Disable();
		delete g_hPatch;
	}
}
