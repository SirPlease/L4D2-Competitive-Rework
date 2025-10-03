#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sourcescramble>

#define BULLET_MAX_SIZE		4
#define GAMEDATA_FILE		"code_patcher"
#define KEY_SGSPREAD		"sgspread"

// Original code & Notes: https://github.com/Jahze/l4d2_plugins/tree/master/spread_patch
// Static Shotgun Spread leverages code_patcher (code_patcher.txt gamedata)
// to replace RNG in pellet spread with static factors.
// This plugin allows you to adjust the spread characteristics, by live patching operands in the custom ASM.

// You can use the visualise_impacts.smx plugin to test the resulting spread.
// It will render small purple boxes where the server-side pellets land.

enum
{
	eWindows = 0,
	eLinux,
	/* eMac, joke:) */

	ePlatform_Size
};

int
	g_ePlatform = eLinux;

static const int
	g_BulletOffsets[ePlatform_Size][BULLET_MAX_SIZE] = {
		{ 0xf, 0x21, 0x30, 0x3f },	// Windows
		{ 0x11, 0x22, 0x2f, 0x43 }	// Linux
	},
	g_FactorOffset[ePlatform_Size] = {
		0x36,	// Windows
		0x34	// Linux
	},
	g_CenterPelletOffset[ePlatform_Size] = {
		-0x36,	// Windows
		-0x1c	// Linux
	};

MemoryPatch
	g_hPatchSgSpread = null;

ConVar
	g_hCvarRing1Bullets = null,
	g_hCvarRing1Factor = null,
	g_hCvarhCenterPellet = null;

public Plugin myinfo =
{
	name = "L4D2 Static Shotgun Spread",
	author = "Jahze, Visor, A1m`, Rena",
	version = "1.6.3",
	description = "Changes the values in the sgspread patch",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	InitGameData();

	g_hCvarRing1Bullets = CreateConVar("sgspread_ring1_bullets", "3", "Number of bullets for the first ring, the remaining bullets will be in the second ring.");
	g_hCvarRing1Factor = CreateConVar("sgspread_ring1_factor", "2", "Determines how far or closer the bullets will be from the center for the first ring.");
	g_hCvarhCenterPellet = CreateConVar("sgspread_center_pellet", "1", "Center pellet: 0 - off, 1 - on.", _, true, 0.0, true, 1.0);

	InitPlugin();
}

void InitGameData()
{
	Handle hConf = LoadGameConfigFile(GAMEDATA_FILE);
	if (hConf == null) {
		SetFailState("Missing gamedata \"" ... GAMEDATA_FILE ... "\"");
	}

	g_ePlatform = GameConfGetOffset(hConf, "OS");
	if (g_ePlatform == -1) {
		SetFailState("Failed to retrieve offset \"OS\"");
	}

	g_hPatchSgSpread = MemoryPatch.CreateFromConf(hConf, KEY_SGSPREAD);
	if (g_hPatchSgSpread == null || !g_hPatchSgSpread.Validate()) {
		SetFailState("Failed to validate MemoryPatch \"" ... KEY_SGSPREAD ... "\"");
	}

	Address pFinalAddr = g_hPatchSgSpread.Address + view_as<Address>(g_CenterPelletOffset[g_ePlatform]);
	int iCurrentValue = LoadFromAddress(pFinalAddr, NumberType_Int8);
	if (iCurrentValue != 1) {
		SetFailState("Center pellet offset is uncorrect! CheckByte: %x", iCurrentValue);
	}

	if (!g_hPatchSgSpread.Enable()) {
		SetFailState("Failed to enable MemoryPatch \"" ... KEY_SGSPREAD ... "\"");
	}

	delete hConf;
}

void InitPlugin()
{
	HotPatchBullets(g_hCvarRing1Bullets.IntValue);
	HotPatchFactor(g_hCvarRing1Factor.IntValue);
	HotPatchCenterPellet(g_hCvarhCenterPellet.BoolValue);

	g_hCvarRing1Bullets.AddChangeHook(OnRing1BulletsChange);
	g_hCvarRing1Factor.AddChangeHook(OnRing1FactorChange);
	g_hCvarhCenterPellet.AddChangeHook(OnCenterPelletChange);
}

public void OnPluginEnd()
{
	Address pFinalAddr = g_hPatchSgSpread.Address + view_as<Address>(g_CenterPelletOffset[g_ePlatform]);
	int iCurrentValue = LoadFromAddress(pFinalAddr, NumberType_Int8);
	if (iCurrentValue != 1) {
		StoreToAddress(pFinalAddr, 1, NumberType_Int8);
	}
}

void OnRing1BulletsChange(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	HotPatchBullets(hConVar.IntValue);
}

void OnRing1FactorChange(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	HotPatchFactor(hConVar.IntValue);
}

void OnCenterPelletChange(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	HotPatchCenterPellet(hConVar.BoolValue);
}

void HotPatchBullets(int iBullets)
{
	bool bCenterpellet = !g_hCvarhCenterPellet.BoolValue;
	float fDegree = 0.0;

	if (g_ePlatform == eWindows) {
		fDegree = 360.0 / float(iBullets);
	} else {
		fDegree = 360.0 / (2.0 * float(iBullets));
	}

	Address pAddr = g_hPatchSgSpread.Address;

	StoreToAddress(pAddr + view_as<Address>(g_BulletOffsets[g_ePlatform][0]), iBullets + (1 - view_as<int>(bCenterpellet)), NumberType_Int8);
	StoreToAddress(pAddr + view_as<Address>(g_BulletOffsets[g_ePlatform][1]), iBullets + (1 - view_as<int>(bCenterpellet)), NumberType_Int8);
	StoreToAddress(pAddr + view_as<Address>(g_BulletOffsets[g_ePlatform][2]), iBullets + (2 - view_as<int>(bCenterpellet)), NumberType_Int8);

	StoreToAddress(pAddr + view_as<Address>(g_BulletOffsets[g_ePlatform][3]), view_as<int>(fDegree), NumberType_Int32);
}

void HotPatchFactor(int fFactor)
{
	Address pAddr = g_hPatchSgSpread.Address;

	if (g_ePlatform == eWindows) {
		// Asm patch on windows need the float type !
		StoreToAddress(pAddr + view_as<Address>(g_FactorOffset[eWindows]), view_as<int>(float(fFactor)), NumberType_Int32);
		return;
	}

	StoreToAddress(pAddr + view_as<Address>(g_FactorOffset[eLinux]), fFactor, NumberType_Int32);
}

void HotPatchCenterPellet(bool bNewValue)
{
	Address pAddr = g_hPatchSgSpread.Address;

	bool iCurrentValue = LoadFromAddress(pAddr + view_as<Address>(g_CenterPelletOffset[g_ePlatform]), NumberType_Int8);
	if (iCurrentValue == bNewValue) {
		return;
	}

	int iBullets = g_hCvarRing1Bullets.IntValue;

	StoreToAddress(pAddr + view_as<Address>(g_CenterPelletOffset[g_ePlatform]), view_as<int>(bNewValue), NumberType_Int8);

	StoreToAddress(pAddr + view_as<Address>(g_BulletOffsets[g_ePlatform][0]), iBullets + (1 - view_as<int>(!bNewValue)), NumberType_Int8);
	StoreToAddress(pAddr + view_as<Address>(g_BulletOffsets[g_ePlatform][1]), iBullets + (1 - view_as<int>(!bNewValue)), NumberType_Int8);
	StoreToAddress(pAddr + view_as<Address>(g_BulletOffsets[g_ePlatform][2]), iBullets + (2 - view_as<int>(!bNewValue)), NumberType_Int8);
}
