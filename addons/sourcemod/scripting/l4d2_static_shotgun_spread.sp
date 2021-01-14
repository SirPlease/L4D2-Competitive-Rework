#pragma semicolon 1

#include <code_patcher>

// Original code & Notes: https://github.com/Jahze/l4d2_plugins/tree/master/spread_patch
// Static Shotgun Spread leverages code_patcher (code_patcher.txt gamedata)
// to replace RNG in pellet spread with static factors.
// This plugin allows you to adjust the spread characteristics, by live patching operands in the custom ASM.

// You can use the visualise_impacts.smx plugin to test the resulting spread.
// It will render small purple boxes where the server-side pellets land.

new Handle:hRing1BulletsCvar;
new Handle:hRing1FactorCvar;
new Handle:hCenterPelletCvar;

new g_BulletOffsets[] = { 0x11, 0x1c, 0x29, 0x3d };
new g_FactorOffset = 0x2e;
new g_CenterPelletOffset = -0x31;

public Plugin:myinfo = 
{
    name = "L4D2 Static Shotgun Spread",
    author = "Jahze, Visor",
    version = "1.1",
    description = "^",
	url = "https://github.com/Attano"
};

public OnPluginStart()
{
	hRing1BulletsCvar = CreateConVar("sgspread_ring1_bullets", "3");
	hRing1FactorCvar = CreateConVar("sgspread_ring1_factor", "2");
	hCenterPelletCvar = CreateConVar("sgspread_center_pellet", "1", "0 : center pellet off; 1 : on", FCVAR_NONE, true, 0.0, true, 1.0);

	HookConVarChange(hRing1BulletsCvar, OnRing1BulletsChange);
	HookConVarChange(hRing1FactorCvar, OnRing1FactorChange);
	HookConVarChange(hCenterPelletCvar, OnCenterPelletChange);
}

static HotPatchCenterPellet(newValue)
{
	if (IsPlatformWindows())
	{
		LogMessage("Static shotgun spread not supported on windows");
		return;
	}

	new Address:addr = GetPatchAddress("sgspread");
	
	new currentValue = LoadFromAddress(addr + Address:g_CenterPelletOffset, NumberType_Int8);
	if (currentValue == newValue)
	{
		return;
	}
	
	StoreToAddress(addr + Address:g_CenterPelletOffset, newValue, NumberType_Int8);
}

static HotPatchBullets(nBullets)
{
	if (IsPlatformWindows())
	{
		LogMessage("Static shotgun spread not supported on windows");
		return;
	}

	new Address:addr = GetPatchAddress("sgspread");

	StoreToAddress(addr + Address:g_BulletOffsets[0], nBullets + 1, NumberType_Int8);
	StoreToAddress(addr + Address:g_BulletOffsets[1], nBullets + 2, NumberType_Int8);
	StoreToAddress(addr + Address:g_BulletOffsets[2], nBullets + 2, NumberType_Int8);

	new Float:degree = 360.0 / (2.0*float(nBullets));

	StoreToAddress(addr + Address:g_BulletOffsets[3], _:degree, NumberType_Int32);
}

static HotPatchFactor(factor)
{
	if (IsPlatformWindows())
	{
		LogMessage("Static shotgun spread not supported on windows");
		return;
	}

	new Address:addr = GetPatchAddress("sgspread");

	StoreToAddress(addr + Address:g_FactorOffset, factor, NumberType_Int32);
}

public OnRing1BulletsChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	new nBullets = StringToInt(newVal);

	if (IsPatchApplied("sgspread"))
		HotPatchBullets(nBullets);
}

public OnRing1FactorChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	new factor = StringToInt(newVal);

	if (IsPatchApplied("sgspread"))
		HotPatchFactor(factor);
}

public OnCenterPelletChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	new value = StringToInt(newVal);

	if (IsPatchApplied("sgspread"))
		HotPatchCenterPellet(value);
}

public OnPatchApplied(const String:name[])
{
	if (StrEqual("sgspread", name))
	{
		HotPatchBullets(GetConVarInt(hRing1BulletsCvar));
		HotPatchFactor(GetConVarInt(hRing1FactorCvar));
		HotPatchCenterPellet(GetConVarInt(hCenterPelletCvar));
	}
}
