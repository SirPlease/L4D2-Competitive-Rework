#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <code_patcher>

#define BULLET_MAX_SIZE 4

// Original code & Notes: https://github.com/Jahze/l4d2_plugins/tree/master/spread_patch
// Static Shotgun Spread leverages code_patcher (code_patcher.txt gamedata)
// to replace RNG in pellet spread with static factors.
// This plugin allows you to adjust the spread characteristics, by live patching operands in the custom ASM.

// You can use the visualise_impacts.smx plugin to test the resulting spread.
// It will render small purple boxes where the server-side pellets land.

ConVar
	hRing1BulletsCvar,
	hRing1FactorCvar,
	hCenterPelletCvar;

static const int g_BulletWindowsOffsets[BULLET_MAX_SIZE] = { 0xf, 0x21, 0x30, 0x3f };
static const int g_FactorWindowsOffset = 0x36;
static const int g_CenterWindowsPelletOffset = -0x30;

static const int g_BulletLinuxOffsets[BULLET_MAX_SIZE] = { 0x11, 0x1c, 0x29, 0x3d };
static const int g_FactorLinuxOffset = 0x2e;
static const int g_CenterLinuxPelletOffset = -0x1c;

public Plugin myinfo = 
{
	name = "L4D2 Static Shotgun Spread",
	author = "Jahze, Visor, A1m`, Rena",
	version = "1.3",
	description = "Changes the values in the sgspread patch",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	hRing1BulletsCvar = CreateConVar("sgspread_ring1_bullets", "3");
	hRing1FactorCvar = CreateConVar("sgspread_ring1_factor", "2");
	hCenterPelletCvar = CreateConVar("sgspread_center_pellet", "1", "0 : center pellet off; 1 : on", _, true, 0.0, true, 1.0);

	HookConVarChange(hRing1BulletsCvar, OnRing1BulletsChange);
	HookConVarChange(hRing1FactorCvar, OnRing1FactorChange);
	HookConVarChange(hCenterPelletCvar, OnCenterPelletChange);
}

static void HotPatchCenterPellet(int newValue)
{
	int iCenterPelletOffset = (IsPlatformWindows()) ? g_CenterWindowsPelletOffset : g_CenterLinuxPelletOffset;
	
	Address pAddr = GetPatchAddress("sgspread");
	
	LoadFromAddress(pAddr + view_as<Address>(iCenterPelletOffset), NumberType_Int8);
	
	int currentValue = LoadFromAddress(pAddr + view_as<Address>(iCenterPelletOffset), NumberType_Int8);

	if (currentValue == newValue) {
		return;
	}
	
	StoreToAddress(pAddr + view_as<Address>(iCenterPelletOffset), newValue, NumberType_Int8);
}

static void HotPatchBullets(int nBullets)
{
	if (IsPlatformWindows()) {
		Address pAddr = GetPatchAddress("sgspread");
		
		StoreToAddress(pAddr + view_as<Address>(g_BulletWindowsOffsets[0]), nBullets + 1, NumberType_Int8);
		StoreToAddress(pAddr + view_as<Address>(g_BulletWindowsOffsets[1]), nBullets + 1, NumberType_Int8);
		StoreToAddress(pAddr + view_as<Address>(g_BulletWindowsOffsets[2]), nBullets + 2, NumberType_Int8);

		float degree = 360.0 / float(nBullets);
		
		StoreToAddress(pAddr + view_as<Address>(g_BulletWindowsOffsets[3]), view_as<int>(degree), NumberType_Int32);
		return;
	}
	
	Address pAddr = GetPatchAddress("sgspread");
	
	StoreToAddress(pAddr + view_as<Address>(g_BulletLinuxOffsets[0]), nBullets + 1, NumberType_Int8);
	StoreToAddress(pAddr + view_as<Address>(g_BulletLinuxOffsets[1]), nBullets + 1, NumberType_Int8);
	StoreToAddress(pAddr + view_as<Address>(g_BulletLinuxOffsets[2]), nBullets + 2, NumberType_Int8);

	float degree = 360.0 / (2.0 * float(nBullets));
	
	StoreToAddress(pAddr + view_as<Address>(g_BulletLinuxOffsets[3]), view_as<int>(degree), NumberType_Int32);
}

static void HotPatchFactor(int factor)
{
	Address pAddr = GetPatchAddress("sgspread");

	if (IsPlatformWindows()) {
		StoreToAddress(pAddr + view_as<Address>(g_FactorWindowsOffset), view_as<int>(float(factor)), NumberType_Int32);
		return;
	}
	
	StoreToAddress(pAddr + view_as<Address>(g_FactorLinuxOffset), factor, NumberType_Int32);
}

public void OnRing1BulletsChange(ConVar hCvar, const char[] oldVal, const char[] newVal)
{
	int nBullets = StringToInt(newVal);

	if (IsPatchApplied("sgspread")) {
		HotPatchBullets(nBullets);
	}
}

public void OnRing1FactorChange(ConVar hCvar, const char[] oldVal, const char[] newVal)
{
	int factor = StringToInt(newVal);

	if (IsPatchApplied("sgspread")) {
		HotPatchFactor(factor);
	}
}

public void OnCenterPelletChange(ConVar hCvar, const char[] oldVal, const char[] newVal)
{
	int value = StringToInt(newVal);

	if (IsPatchApplied("sgspread")) {
		HotPatchCenterPellet(value);
	}
}

public void OnPatchApplied(const char[] name)
{
	if (strcmp("sgspread", name) == 0) {
		HotPatchBullets(hRing1BulletsCvar.IntValue);
		HotPatchFactor(hRing1FactorCvar.IntValue);
		HotPatchCenterPellet(hCenterPelletCvar.IntValue);
	}
}
