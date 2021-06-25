#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>

#define GAMEDATA "boomer_horde_equalizer"
#define MAX_PATCH_SIZE 4

ConVar 
	hPatchEnable = null,
	z_mob_spawn_max_size = null;

bool
	IsPatched = false,
	IsWindows = false;

Address
	patchAddress = Address_Null;

public Plugin myinfo = 
{
	name = "Boomer Horde Equalizer",
	author = "Visor, Jacob, A1m`",
	version = "1.4",
	description = "Fixes boomer hordes being different sizes based on wandering commons.",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	InitGameData();

	hPatchEnable = CreateConVar("boomer_horde_equalizer", "1", "Fix boomer hordes being different sizes based on wandering commons. (1 - enable, 0 - disable)", _, true, 0.0, true, 1.0);
	
	CheckPatch(hPatchEnable.BoolValue);
	
	hPatchEnable.AddChangeHook(Cvars_Changed);
	
	z_mob_spawn_max_size = FindConVar("z_mob_spawn_max_size");
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
	
	IsWindows = (GameConfGetOffset(hGamedata, "Platform") == 1);
	
	patchAddress = pAddress + view_as<Address>(iOffset);

	delete hGamedata;
}

public Action L4D_OnSpawnITMob(int &amount)
{
	amount = z_mob_spawn_max_size.IntValue;
	return Plugin_Changed;
}

public void Cvars_Changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	CheckPatch(convar.BoolValue);
}

public void OnPluginEnd()
{
	CheckPatch(false);
}

void CheckPatch(bool IsPatch)
{
	if (IsPatch) {
		if (IsPatched) {
			PrintToServer("[%s] Plugin already enabled", GAMEDATA);
			return;
		}
		SelectBytes(true);
	} else {
		if (!IsPatched) {
			PrintToServer("[%s] Plugin already disabled", GAMEDATA);
			return;
		}
		SelectBytes(false);
	}
}

void SelectBytes(bool IsPatch)
{
	int patchBytes[MAX_PATCH_SIZE];
	int originalBytes[MAX_PATCH_SIZE];

	if (IsWindows) {
		//3B FE			cmp		edi, esi
		//7D 0E			jge		short loc_104A5BBB
		//change to nop -> 90 90 90 90
		patchBytes = {0x90, 0x90, 0x90, 0x90};
		originalBytes = {0x3B, 0xFE, 0x7D, 0x0E};
	} else {
		//39 F3			cmp		ebx, esi
		//7D 13			jge		short loc_743BA0
		//change to nop -> 90 90 90 90
		patchBytes = {0x90, 0x90, 0x90, 0x90};
		originalBytes = {0x39, 0xF3, 0x7D, 0x13};
	}
	
	if (IsPatch) {
		CheckBytes(patchAddress, originalBytes, MAX_PATCH_SIZE);
		PatchBytes(patchAddress, patchBytes, MAX_PATCH_SIZE);
		IsPatched = true;
	} else {
		CheckBytes(patchAddress, patchBytes, MAX_PATCH_SIZE);
		PatchBytes(patchAddress, originalBytes, MAX_PATCH_SIZE);
		IsPatched = false;
	}
}

void CheckBytes(const Address ptrAddress, int[] checkBytes, const int iPatchSize)
{
	int iReadByte;
	for (int i = 0; i < iPatchSize; i++) {
		iReadByte = LoadFromAddress(ptrAddress + view_as<Address>(i), NumberType_Int8);
		if (checkBytes[i] < 0 || iReadByte != checkBytes[i]) {
			PrintToServer("Check bytes failed. Invalid byte (read: %x@%i, expected byte: %x@%i). Check offset 'WanderersCondition'.", 
			iReadByte, i, checkBytes[i], i);
			SetFailState("Check bytes failed. Invalid byte (read: %x@%i, expected byte: %x@%i). Check offset 'WanderersCondition'.", 
			iReadByte, i, checkBytes[i], i);
		}
	}
}

void PatchBytes(const Address ptrAddress, int[] patchBytes, const int iPatchSize)
{
	for (int i = 0; i < iPatchSize; i++) {
		if (patchBytes[i] < 0) {
			PrintToServer("Patch bytes failed. Invalid write byte: %x@%i. Check offset 'WanderersCondition'.", patchBytes[i], i);
			SetFailState("Patch bytes failed. Invalid write byte: %x@%i. Check offset 'WanderersCondition'.", patchBytes[i], i);
		}
		
		StoreToAddress(ptrAddress + view_as<Address>(i), patchBytes[i], NumberType_Int8);
		PrintToServer("[%s] Write byte %x@%i", GAMEDATA, patchBytes[i], i); //GAMEDATA == plugin name
	}
}
