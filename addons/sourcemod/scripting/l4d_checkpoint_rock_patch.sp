#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.1"

public Plugin myinfo = 
{
	name = "[L4D & 2] Checkpoint Rock Patch",
	author = "Forgetest",
	description = "Memory patch for rock hitbox being stricter to land survivors in saferoom.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
};

#define GAMEDATA_FILE "l4d_checkpoint_rock_patch"
#define PATCH_KEY "ForEachPlayer_ProximityCheck"

#define JZ_SHORT_OPCODE 0x74
#define JMP_SHORT_OPCODE 0xEB

Address g_pAddress;

public void OnPluginStart()
{
	Handle conf = LoadGameConfigFile(GAMEDATA_FILE);
	if (conf == null)
		SetFailState("Missing gamedata \"" ... GAMEDATA_FILE ... "\"");
	
	g_pAddress = GameConfGetAddress(conf, PATCH_KEY);
	if (g_pAddress == Address_Null)
		SetFailState("Failed to get address of \"" ... PATCH_KEY ... "\"");
		
	int offset = GameConfGetOffset(conf, "PatchOffset");
	if (offset == -1)
		SetFailState("Failed to get offset from \"PatchOffset\"");
	
	delete conf;
	
	g_pAddress += view_as<Address>(offset);
	
	ApplyPatch(true);
}

public void OnPluginEnd()
{
	ApplyPatch(false);
}

void ApplyPatch(bool patch)
{
	static bool patched = false;
	if (patch && !patched)
	{
		int byte = LoadFromAddress(g_pAddress, NumberType_Int8);
		if (byte != JZ_SHORT_OPCODE)
			SetFailState("Failed to apply patch \"" ... PATCH_KEY ... "\"");
			
		StoreToAddress(g_pAddress, JMP_SHORT_OPCODE, NumberType_Int8);
	}
	else if (!patch && patched)
	{
		int byte = LoadFromAddress(g_pAddress, NumberType_Int8);
		if (byte != JMP_SHORT_OPCODE)
			SetFailState("Failed to apply patch \"" ... PATCH_KEY ... "\"");
			
		StoreToAddress(g_pAddress, JZ_SHORT_OPCODE, NumberType_Int8);
	}
}