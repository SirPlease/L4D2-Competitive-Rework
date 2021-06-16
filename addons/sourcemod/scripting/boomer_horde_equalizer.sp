#pragma semicolon 1

#include <sourcemod>
#include <left4dhooks>

#define GAMEDATA "boomer_horde_equalizer"
#define MAX_PATCH_SIZE 4

ConVar z_mob_spawn_max_size;

static const int patchBytes[MAX_PATCH_SIZE] = {0x90, 0x90, 0x90, 0x90};
static const int originalBytes[MAX_PATCH_SIZE] = {0x39, 0xF3, 0x7D, 0x13};

public Plugin myinfo = 
{
	name = "Boomer Horde Equalizer",
	author = "Visor, Jacob, A1m`",
	version = "1.3",
	description = "Fixes boomer hordes being different sizes based on wandering commons.",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	z_mob_spawn_max_size = FindConVar("z_mob_spawn_max_size");
	
	PatchWanderersCheck(true);
}

public void OnPluginEnd()
{
	PatchWanderersCheck(false);
}

public Action L4D_OnSpawnITMob(int &amount)
{
	amount = GetConVarInt(z_mob_spawn_max_size);
	return Plugin_Changed;
}

void PatchWanderersCheck(bool IsEnable)
{
	Handle hGamedata = LoadGameConfigFile(GAMEDATA);

	if (!hGamedata) {
		SetFailState("Gamedata '%s.txt' missing or corrupt.", GAMEDATA);
	}
	
	Address pAddress = GameConfGetAddress(hGamedata, "OnCharacterVomitedUpon_Sig");
	if (!pAddress) {
		SetFailState("Couldn't find the 'OnCharacterVomitedUpon_Sig' address.");
	}
	
	int iOffset = GameConfGetOffset(hGamedata, "WanderersCondition");
	if (iOffset == -1) {
		SetFailState("Invalid offset 'WanderersCondition'.");
	}
	
	int iArrayBytes[MAX_PATCH_SIZE], iReadByte;
	for (int i = 0; i < MAX_PATCH_SIZE; i++) {
		iArrayBytes[i] = (IsEnable) ? originalBytes[i] : patchBytes[i];
		iReadByte = LoadFromAddress(pAddress + view_as<Address>((iOffset + i)), NumberType_Int8);
		if (iArrayBytes[i] < 0 || iReadByte != iArrayBytes[i]) {
			SetFailState("%s attempt failed. Invalid byte (read: %x@%i, expected byte: %x@%i). Check offset 'WanderersCondition'.", (IsEnable) ? "Patch" : "Unpatch", iReadByte, i, iArrayBytes[i], i);
		}
	}
	
	for (int i = 0; i < MAX_PATCH_SIZE; i++) {
		iArrayBytes[i] = (IsEnable) ? patchBytes[i] : originalBytes[i];
		if (iArrayBytes[i] < 0) {
			SetFailState("Failed %s. Invalid write byte: %x@%i. Check offset 'WanderersCondition'.", (IsEnable) ? "patch" : "unpatch", iArrayBytes[i], i);
		}
		
		StoreToAddress(pAddress + view_as<Address>((iOffset + i)), iArrayBytes[i], NumberType_Int8);
		PrintToServer("[boomer_horde_equalizer] Write byte %x@%i", iArrayBytes[i], i);
	}
	
	delete hGamedata;
}
