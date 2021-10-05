#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define ADDRESS_KEY "ProcessClientInfo"
#define OFFSET_KEY "hltv_write"
#define GAMEDATA "l4d2_hltv_crash_fix"

enum
{
	eLinux = 0,
	eWindows,
	/* eMac, joke:) */
};

int
	g_iPlatform = eLinux;

bool
	g_bIsPatched = false;

Address
	g_pPatchAddress = Address_Null;

/* Windows:
 * 8A 4F 5C			mov		cl, [edi+5Ch]
 * Change to:
 * B1 00			mov		cl, 0
 * 90				NOP
*/
static const int
	g_iWinPatchBytes[] = {
		0xB1, 0x00, 0x90		// Windows
	},
	g_iWinOriginalBytes[] = {
		0x8A, 0x4F, 0x5C		// Windows
	};

/* Linux:
 * 0F B6 46 54		movzx eax, byte ptr [esi+54h]
 * Change to:
 * 31, C0,			xor eax, eax
 * 66, 90			66 NOP (two byte nop)
*/
static const int
	g_iLinPatchBytes[] = {
		0x31, 0xC0, 0x66, 0x90	// Linux
	},
	g_iLinOriginalBytes[] = {
		0x0F, 0xB6, 0x46, 0x54	// Linux
	};

public Plugin myinfo =
{
	name = "L4D2 HLTV Crash Exploit Fix",
	author = "backwards, ProdigySim, A1m`",
	description = "Prevents Exploit That Crashes Servers",
	version = "2.2",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	if (GetEngineVersion() != Engine_Left4Dead2) {
		SetFailState("This plugin is only for L4D2!");
	}
	
	Handle hGameData = LoadGameConfigFile(GAMEDATA);
	if (!hGameData) {
		SetFailState("Gamedata '%s.txt' missing or corrupt.", GAMEDATA);
	}
	
	g_pPatchAddress = GameConfGetAddress(hGameData, ADDRESS_KEY);
	if (g_pPatchAddress == Address_Null) {
		SetFailState("Failed to get address of '%s'", ADDRESS_KEY);
	}
	
	int iOffset = GameConfGetOffset(hGameData, OFFSET_KEY);
	if (iOffset == -1) {
		SetFailState("Failed to get offset from '%s'", OFFSET_KEY);
	}
	
	g_iPlatform = GameConfGetOffset(hGameData, "Platform");
	if (g_iPlatform != eWindows && g_iPlatform != eLinux) {
		SetFailState("Section not specified 'Platform'.");
	}
	
	g_pPatchAddress += view_as<Address>(iOffset);
	
	CheckPatch(true);
	
	delete hGameData;
}

/*public void OnPluginEnd()
{
	CheckPatch(false);
}*/

void CheckPatch(bool bIsPatch)
{
	if (bIsPatch) {
		if (g_bIsPatched) {
			PrintToServer("[%s] Plugin already enabled", GAMEDATA);
			return;
		}
		
		if (g_iPlatform == eLinux) {
			CheckAndPatchBytes(g_pPatchAddress, g_iLinOriginalBytes, g_iLinPatchBytes, sizeof(g_iLinOriginalBytes));
		} else {
			CheckAndPatchBytes(g_pPatchAddress, g_iWinOriginalBytes, g_iWinPatchBytes, sizeof(g_iWinOriginalBytes));
		}
		
		g_bIsPatched = true;
	} else {
		if (!g_bIsPatched) {
			PrintToServer("[%s] Plugin already disabled", GAMEDATA);
			return;
		}
		
		if (g_iPlatform == eLinux) {
			PatchBytes(g_pPatchAddress, g_iLinOriginalBytes, sizeof(g_iLinPatchBytes));
		} else {
			PatchBytes(g_pPatchAddress, g_iWinOriginalBytes, sizeof(g_iWinOriginalBytes));
		}
		
		g_bIsPatched = false;
	}
}

void CheckAndPatchBytes(const Address pAddress, const int[] iCheckBytes, const int[] iPatchBytes, const int iPatchSize)
{
	int iReadByte = -1, iByteCount = 0;
	
	for (int i = 0; i < iPatchSize; i++) {
		iReadByte = LoadFromAddress(pAddress + view_as<Address>(i), NumberType_Int8);
		
		if (iCheckBytes[i] < 0 || iReadByte != iCheckBytes[i]) {
			if (iReadByte == iPatchBytes[i]) {
				iByteCount++;
				continue;
			}
			
			PrintToServer("Check bytes failed. Invalid byte (read: %x@%i, expected byte: %x@%i). Check offset '%s'.", iReadByte, i, iCheckBytes[i], i, OFFSET_KEY);
			SetFailState("Check bytes failed. Invalid byte (read: %x@%i, expected byte: %x@%i). Check offset '%s'.", iReadByte, i, iCheckBytes[i], i, OFFSET_KEY);
		}
	}
	
	if (iByteCount == iPatchSize) {
		PrintToServer("[%s] The patch is already installed.", GAMEDATA);
		return;
	}
	
	PatchBytes(pAddress, iPatchBytes, iPatchSize);
}

void PatchBytes(const Address pAddress, const int[] iPatchBytes, const int iPatchSize)
{
	for (int i = 0; i < iPatchSize; i++) {
		if (iPatchBytes[i] < 0) {
			PrintToServer("Patch bytes failed. Invalid write byte: %x@%i. Check offset '%s'.", iPatchBytes[i], i, OFFSET_KEY);
			SetFailState("Patch bytes failed. Invalid write byte: %x@%i. Check offset '%s'.", iPatchBytes[i], i, OFFSET_KEY);
		}
		
		StoreToAddress(pAddress + view_as<Address>(i), iPatchBytes[i], NumberType_Int8);
		PrintToServer("[%s] Write byte %x@%i", GAMEDATA, iPatchBytes[i], i);
	}
}
