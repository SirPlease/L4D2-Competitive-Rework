#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define GAMEDATA "l4d2_notankautoaim"

ConVar
	hPatchEnable = null;

bool
	IsPatched = false,
	IsWindows = false;

Address
	pAddress = Address_Null;

public Plugin myinfo =
{
	name = "L4D2 Tank Claw Fix",
	author = "Jahze(patch data), Visor(SM), A1m`",
	description = "Removes the Tank claw's undocumented auto-aiming ability",
	version = "0.5",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework/"
}

public void OnPluginStart()
{
	InitGameData();

	hPatchEnable = CreateConVar("l4d2_notankautoaim", "1", "Remove the Tank claw's undocumented auto-aiming ability (1 - enable, 0 - disable)", _, true, 0.0, true, 1.0);
	
	CheckPatch(hPatchEnable.BoolValue);
	
	hPatchEnable.AddChangeHook(Cvars_Changed);
}

void InitGameData()
{
	Handle hGamedata = LoadGameConfigFile(GAMEDATA);
	
	if (!hGamedata) {
		SetFailState("Gamedata '%s.txt' missing or corrupt", GAMEDATA);
	}
	
	pAddress = GameConfGetAddress(hGamedata, "OnWindupFinished_Sig");
	if (!pAddress) {
		SetFailState("Couldn't find the 'OnWindupFinished_Sig' address");
	}
	
	int iPlatform = GameConfGetOffset(hGamedata, "Platform");
	if (iPlatform != 0 && iPlatform != 1) {
		SetFailState("Invalid offset 'WanderersCondition'.");
	}
	
	int iOffset = GameConfGetOffset(hGamedata, "ClawTargetScan");
	if (iOffset == -1) {
		SetFailState("Invalid offset 'ClawTargetScan'.");
	}
	
	IsWindows = (GameConfGetOffset(hGamedata, "Platform") == 1);
	
	pAddress += view_as<Address>(iOffset);
	
	delete hGamedata;
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
	int iSize = (IsWindows) ? 2 : 3;
	int[] originalBytes = new int[iSize];
	int[] patchBytes = new int[iSize];
	
	if (IsWindows) {
		//jz short loc_103DF2D4 -> jmp short loc_103DF2D4, jump if zero -> unconditional jump to eyeangle check
		originalBytes[0] = 0x74;
		originalBytes[1] = 0x29;
		patchBytes[0] = 0xEB;
		patchBytes[1] = 0x29;
	} else {
		//jz loc_54E670 -> jmp loc_54E670, jump if zero -> unconditional jump to eyeangle check
		originalBytes[0] = 0x0F;
		originalBytes[1] = 0x84;
		originalBytes[2] = 0x95;
		patchBytes[0] = 0xE9;
		patchBytes[1] = 0x96;
		patchBytes[2] = 0x00;
	}
	
	if (IsPatch) {
		CheckBytes(pAddress, originalBytes, iSize);
		PatchBytes(pAddress, patchBytes, iSize);
		IsPatched = true;
	} else {
		CheckBytes(pAddress, patchBytes, iSize);
		PatchBytes(pAddress, originalBytes, iSize);
		IsPatched = false;
	}
}

void CheckBytes(const Address ptrAddress, int[] checkBytes, const int iPatchSize)
{
	int iReadByte;
	for (int i = 0; i < iPatchSize; i++) {
		iReadByte = LoadFromAddress(ptrAddress + view_as<Address>(i), NumberType_Int8);
		if (checkBytes[i] < 0 || iReadByte != checkBytes[i]) {
			PrintToServer("Check bytes failed. Invalid byte (read: %x@%i, expected byte: %x@%i). Check offset 'ClawTargetScan'.", 
			iReadByte, i, checkBytes[i], i);
			SetFailState("Check bytes failed. Invalid byte (read: %x@%i, expected byte: %x@%i). Check offset 'ClawTargetScan'.", 
			iReadByte, i, checkBytes[i], i);
		}
	}
}

void PatchBytes(const Address ptrAddress, int[] patchBytes, const int iPatchSize)
{
	for (int i = 0; i < iPatchSize; i++) {
		if (patchBytes[i] < 0) {
			PrintToServer("Patch bytes failed. Invalid write byte: %x@%i. Check offset 'ClawTargetScan'.", patchBytes[i], i);
			SetFailState("Patch bytes failed. Invalid write byte: %x@%i. Check offset 'ClawTargetScan'.", patchBytes[i], i);
		}
		
		StoreToAddress(ptrAddress + view_as<Address>(i), patchBytes[i], NumberType_Int8);
		PrintToServer("[%s] Write byte %x@%i", GAMEDATA, patchBytes[i], i); //GAMEDATA == plugin name
	}
}
