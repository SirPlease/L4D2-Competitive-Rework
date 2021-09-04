#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>

#define GAMEDATA "boomer_horde_equalizer"
#define MAX_PATCH_SIZE 4

enum
{
	eWindows = 0,
	eLinux,
	/* eMac, joke:) */
	ePlatform_Size
};

/* Windows:
 * 3B FE			cmp		edi, esi
 * 7D 0E			jge		short loc_104A5BBB
 * Change to nop -> 90 90 90 90
*/
/* Linux:
 * 39 F3			cmp		ebx, esi
 * 7D 13			jge		short loc_743BA0
 * Change to nop -> 90 90 90 90
*/
static const int
	patchBytes[ePlatform_Size][MAX_PATCH_SIZE] = {
		{0x90, 0x90, 0x90, 0x90}, // Windows
		{0x90, 0x90, 0x90, 0x90}, // Linux
	},
	originalBytes[ePlatform_Size][MAX_PATCH_SIZE] = {
		{0x3B, 0xFE, 0x7D, 0x0E}, // Windows
		{0x39, 0xF3, 0x7D, 0x13} // Linux
	};

ConVar
	g_hPatchEnable = null,
	g_hzMobSpawnMaxSize = null;

bool
	g_bIsPatched = false,
	g_bIsWindows = false;

Address
	g_aPatchAddress = Address_Null;

public Plugin myinfo = 
{
	name = "Boomer Horde Equalizer",
	author = "Visor, Jacob, A1m`",
	version = "1.5",
	description = "Fixes boomer hordes being different sizes based on wandering commons.",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	InitGameData();

	g_hPatchEnable = CreateConVar("boomer_horde_equalizer", "1", "Fix boomer hordes being different sizes based on wandering commons. (1 - enable, 0 - disable)", _, true, 0.0, true, 1.0);

	CheckPatch(g_hPatchEnable.BoolValue);
	
	g_hPatchEnable.AddChangeHook(Cvars_Changed);
	
	g_hzMobSpawnMaxSize = FindConVar("z_mob_spawn_max_size");
}

void InitGameData()
{
	Handle hGamedata = LoadGameConfigFile(GAMEDATA);

	if (!hGamedata) {
		SetFailState("Gamedata '%s.txt' missing or corrupt.", GAMEDATA);
	}
	
	Address pAddress = GameConfGetAddress(hGamedata, "OnCharacterVomitedUpon_Sig");
	if (!pAddress) {
		SetFailState("Couldn't find the 'OnCharacterVomitedUpon_Sig' address.");
	}
	
	int iPlatform = GameConfGetOffset(hGamedata, "Platform");
	if (iPlatform != 0 && iPlatform != 1) {
		SetFailState("Section not specified 'Platform'.");
	}
	
	int iOffset = GameConfGetOffset(hGamedata, "WanderersCondition");
	if (iOffset == -1) {
		SetFailState("Invalid offset 'WanderersCondition'.");
	}
	
	g_bIsWindows = (GameConfGetOffset(hGamedata, "Platform") == 1);
	
	g_aPatchAddress = pAddress + view_as<Address>(iOffset);

	delete hGamedata;
}

public Action L4D_OnSpawnITMob(int &iAmount)
{
	iAmount = g_hzMobSpawnMaxSize.IntValue;
	return Plugin_Changed;
}

public void Cvars_Changed(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	CheckPatch(hConVar.BoolValue);
}

public void OnPluginEnd()
{
	CheckPatch(false);
}

void CheckPatch(bool bIsPatch)
{
	if (bIsPatch) {
		if (g_bIsPatched) {
			PrintToServer("[%s] Plugin already enabled", GAMEDATA);
			return;
		}
		SelectBytes(true);
	} else {
		if (!g_bIsPatched) {
			PrintToServer("[%s] Plugin already disabled", GAMEDATA);
			return;
		}
		SelectBytes(false);
	}
}

void SelectBytes(bool bIsPatch)
{
	int iPlatform = (g_bIsWindows) ? eWindows : eLinux;

	if (bIsPatch) {
		CheckBytes(g_aPatchAddress, originalBytes[iPlatform], MAX_PATCH_SIZE);
		PatchBytes(g_aPatchAddress, patchBytes[iPlatform], MAX_PATCH_SIZE);
		g_bIsPatched = true;
	} else {
		CheckBytes(g_aPatchAddress, patchBytes[iPlatform], MAX_PATCH_SIZE);
		PatchBytes(g_aPatchAddress, originalBytes[iPlatform], MAX_PATCH_SIZE);
		g_bIsPatched = false;
	}
}

void CheckBytes(const Address ptrAddress, int iCheckBytes[MAX_PATCH_SIZE], const int iPatchSize)
{
	int iReadByte;
	for (int i = 0; i < iPatchSize; i++) {
		iReadByte = LoadFromAddress(ptrAddress + view_as<Address>(i), NumberType_Int8);
		if (iCheckBytes[i] < 0 || iReadByte != iCheckBytes[i]) {
			PrintToServer("Check bytes failed. Invalid byte (read: %x@%i, expected byte: %x@%i). Check offset 'WanderersCondition'.", 
			iReadByte, i, iCheckBytes[i], i);
			SetFailState("Check bytes failed. Invalid byte (read: %x@%i, expected byte: %x@%i). Check offset 'WanderersCondition'.", 
			iReadByte, i, iCheckBytes[i], i);
		}
	}
}

void PatchBytes(const Address ptrAddress, int iPatchBytes[MAX_PATCH_SIZE], const int iPatchSize)
{
	for (int i = 0; i < iPatchSize; i++) {
		if (iPatchBytes[i] < 0) {
			PrintToServer("Patch bytes failed. Invalid write byte: %x@%i. Check offset 'WanderersCondition'.", iPatchBytes[i], i);
			SetFailState("Patch bytes failed. Invalid write byte: %x@%i. Check offset 'WanderersCondition'.", iPatchBytes[i], i);
		}
		
		StoreToAddress(ptrAddress + view_as<Address>(i), iPatchBytes[i], NumberType_Int8);
		PrintToServer("[%s] Write byte %x@%i", GAMEDATA, iPatchBytes[i], i); //GAMEDATA == plugin name
	}
}
