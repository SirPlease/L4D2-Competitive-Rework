#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sourcescramble>

#define BULLET_MAX_SIZE		3
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
	g_iBulletOffsets[ePlatform_Size][BULLET_MAX_SIZE] = {
		{ 0xf, 0x21, 0x30 },	// Windows
		{ 0x11, 0x22, 0x2f }	// Linux
	},
	g_iDegreeOffsets[ePlatform_Size] = {
		0x3f,	// Windows
		0x43	// Linux
	},
	g_iFactorOffset[ePlatform_Size] = {
		0x36,	// Windows
		0x34	// Linux
	},
	g_iCenterPelletOffset[ePlatform_Size] = {
		-0x36,	// Windows
		-0x1c	// Linux
	};

Address
	g_pBullets[BULLET_MAX_SIZE] = {Address_Null, ...},
	g_pDegree = Address_Null,
	g_pFactor = Address_Null,
	g_pCenterPellet = Address_Null;

MemoryPatch
	g_hPatchSgSpread = null;

ConVar
	g_hCvarRing1Bullets = null,
	g_hCvarRing1Factor = null,
	g_hCvarCenterPellet = null;

public Plugin myinfo =
{
	name = "L4D2 Static Shotgun Spread",
	author = "Jahze, Visor, A1m`, Rena",
	version = "1.6.5",
	description = "Changes the values in the sgspread patch",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	InitGameData();

	g_hCvarRing1Bullets = CreateConVar("sgspread_ring1_bullets", "3", "Number of bullets for the first ring, the remaining bullets will be in the second ring.");
	g_hCvarRing1Factor = CreateConVar("sgspread_ring1_factor", "2", "Determines how far or closer the bullets will be from the center for the first ring.");
	g_hCvarCenterPellet = CreateConVar("sgspread_center_pellet", "1", "Center pellet: 0 - off, 1 - on.", _, true, 0.0, true, 1.0);

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

	Address pFinalAddr = g_hPatchSgSpread.Address + view_as<Address>(g_iCenterPelletOffset[g_ePlatform]);
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
	for (int i = 0; i < BULLET_MAX_SIZE; i++) {
		g_pBullets[i] = g_hPatchSgSpread.Address + view_as<Address>(g_iBulletOffsets[g_ePlatform][i]);
	}

	g_pDegree = g_hPatchSgSpread.Address + view_as<Address>(g_iDegreeOffsets[g_ePlatform]);
	g_pFactor = g_hPatchSgSpread.Address + view_as<Address>(g_iFactorOffset[g_ePlatform]);
	g_pCenterPellet = g_hPatchSgSpread.Address + view_as<Address>(g_iCenterPelletOffset[g_ePlatform]);

	HotPatchBullets(g_hCvarRing1Bullets.IntValue);
	HotPatchFactor(g_hCvarRing1Factor.IntValue);
	HotPatchCenterPellet(g_hCvarCenterPellet.BoolValue);

	g_hCvarRing1Bullets.AddChangeHook(OnRing1BulletsChange);
	g_hCvarRing1Factor.AddChangeHook(OnRing1FactorChange);
	g_hCvarCenterPellet.AddChangeHook(OnCenterPelletChange);
}

public void OnPluginEnd()
{
	if (g_pCenterPellet != Address_Null) {
		int iCurrentValue = LoadFromAddress(g_pCenterPellet, NumberType_Int8);

		if (iCurrentValue != 1) {
			StoreToAddress(g_pCenterPellet, 1, NumberType_Int8);
		}
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
	PatchBullets(iBullets, g_hCvarCenterPellet.BoolValue);

	float fBullets = float(iBullets);
	if (g_ePlatform == eLinux) {
		fBullets *= 2.0;
	}

	StoreToAddress(g_pDegree, view_as<int>(360.0 / fBullets), NumberType_Int32);
}

void HotPatchFactor(int iFactor)
{
	// Asm patch on windows need the float type !
	int iSetFactor = (g_ePlatform == eWindows) ? view_as<int>(float(iFactor)) : iFactor;
	StoreToAddress(g_pFactor, iSetFactor, NumberType_Int32);
}

void HotPatchCenterPellet(bool bNewValue)
{
	bool iCurrentValue = LoadFromAddress(g_pCenterPellet, NumberType_Int8);
	if (iCurrentValue == bNewValue) {
		return;
	}

	StoreToAddress(g_pCenterPellet, view_as<int>(bNewValue), NumberType_Int8);

	PatchBullets(g_hCvarRing1Bullets.IntValue, bNewValue);
}

void PatchBullets(int iBullets, bool bCenterPellet)
{
	int iOffset1 = iBullets + (bCenterPellet ? 1 : 0);
	int iOffset2 = iBullets + (bCenterPellet ? 2 : 1);

	StoreToAddress(g_pBullets[0], iOffset1, NumberType_Int8);
	StoreToAddress(g_pBullets[1], iOffset1, NumberType_Int8);
	StoreToAddress(g_pBullets[2], iOffset2, NumberType_Int8);
}
