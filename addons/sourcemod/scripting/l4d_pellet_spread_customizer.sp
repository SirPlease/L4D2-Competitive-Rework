#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>
#include <left4dhooks>
#include <sourcescramble>

#define DEBUG 0
#define PLUGIN_VERSION "1.0"

public Plugin myinfo = 
{
	name = "[L4D & 2] Pellet Spread Customizer",
	author = "Forgetest",
	description = "Customize spread pattern for pellet-shooting guns.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins",
}

methodmap GameDataWrapper < GameData {
	public GameDataWrapper(const char[] file) {
		GameData gd = new GameData(file);
		if (!gd) SetFailState("Missing gamedata \"%s\"", file);
		return view_as<GameDataWrapper>(gd);
	}
	public MemoryPatch CreatePatchOrFail(const char[] name, bool enable = false) {
		MemoryPatch hPatch = MemoryPatch.CreateFromConf(this, name);
		if (!(enable ? hPatch.Enable() : hPatch.Validate()))
			SetFailState("Failed to patch \"%s\"", name);
		return hPatch;
	}
	public DynamicDetour CreateDetourOrFail(
			const char[] name,
			DHookCallback preHook = INVALID_FUNCTION,
			DHookCallback postHook = INVALID_FUNCTION) {
		DynamicDetour hSetup = DynamicDetour.FromConf(this, name);
		if (!hSetup)
			SetFailState("Missing detour setup \"%s\"", name);
		if (preHook != INVALID_FUNCTION && !hSetup.Enable(Hook_Pre, preHook))
			SetFailState("Failed to pre-detour \"%s\"", name);
		if (postHook != INVALID_FUNCTION && !hSetup.Enable(Hook_Post, postHook))
			SetFailState("Failed to post-detour \"%s\"", name);
		return hSetup;
	}
}

MemoryPatch g_patch_CenterPellet;

GlobalForward g_fwd_CenterPellet;
GlobalForward g_fwd_SpreadMod;
GlobalForward g_fwd_SpreadDIrMod;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_fwd_CenterPellet = new GlobalForward("L4D_OnPelletFirstBullet", ET_Event, Param_Cell);
	g_fwd_SpreadMod = new GlobalForward("L4D_OnPelletSpread", ET_Event, Param_Cell, Param_FloatByRef, Param_Cell, Param_Cell);
	g_fwd_SpreadDIrMod = new GlobalForward("L4D_OnPelletSpreadDir", ET_Event, Param_Cell, Param_FloatByRef, Param_Cell, Param_Cell);

	RegPluginLibrary("l4d_pellet_spread_customizer");
	return APLRes_Success;
}

public void OnPluginStart()
{
	GameDataWrapper gd = new GameDataWrapper("l4d_pellet_spread_customizer");
	g_patch_CenterPellet = gd.CreatePatchOrFail("center_pellet", false);
	delete gd.CreateDetourOrFail("CTerrorGun::FireBullet", DTR_CTerrorGun_FireBullet, DTR_CTerrorGun_FireBullet_Post);
	delete gd.CreateDetourOrFail("SharedRandomFloat", _, DTR_SharedRandomFloat_Post);
	delete gd;
}

void ToggleCenterPelletPatch(bool enable)
{
	static bool status = false;

	if (status == enable)
		return;
	
	status = enable;
	if (status)
		g_patch_CenterPellet.Enable();
	else
		g_patch_CenterPellet.Disable();
}

bool ShouldUseCenterPellet(int weapon)
{
	if (g_fwd_CenterPellet.FunctionCount == 0)
		return true;
	
	Action result = Plugin_Continue;
	Call_StartForward(g_fwd_CenterPellet);
	Call_PushCell(weapon);
	Call_Finish(result);

	return result == Plugin_Continue;
}

static int g_nMaxBullets;
static bool g_bCenterPellet;
static int g_iFireBulletWeapon = -1;
MRESReturn DTR_CTerrorGun_FireBullet(int weapon)
{
	g_nMaxBullets = GetWeaponMaxBullets(weapon);
	g_iFireBulletWeapon = weapon;

	if (ShouldUseCenterPellet(weapon))
	{
		g_bCenterPellet = true;
		ToggleCenterPelletPatch(false);
	}
	else
	{
		g_bCenterPellet = false;
		ToggleCenterPelletPatch(true);
	}

	return MRES_Ignored;
}

MRESReturn DTR_CTerrorGun_FireBullet_Post(int weapon)
{
	g_iFireBulletWeapon = -1;
	ToggleCenterPelletPatch(false);
	return MRES_Ignored;
}

bool ApplyPelletSpreadMod(int weapon, float &spread, int nPellet, int nMaxPellets)
{
	if (g_fwd_SpreadMod.FunctionCount == 0)
		return false;
	
	Action result = Plugin_Continue;
	Call_StartForward(g_fwd_SpreadMod);
	Call_PushCell(weapon);
	Call_PushFloatRef(spread);
	Call_PushCell(nPellet);
	Call_PushCell(nMaxPellets);
	Call_Finish(result);

	return result == Plugin_Changed;
}

bool ApplyPelletSpreadDirMod(int weapon, float &angle, int nPellet, int nMaxPellets)
{
	if (g_fwd_SpreadDIrMod.FunctionCount == 0)
		return false;
	
	Action result = Plugin_Continue;
	Call_StartForward(g_fwd_SpreadDIrMod);
	Call_PushCell(weapon);
	Call_PushFloatRef(angle);
	Call_PushCell(nPellet);
	Call_PushCell(nMaxPellets);
	Call_Finish(result);

	return result == Plugin_Changed;
}

MRESReturn DTR_SharedRandomFloat_Post(DHookReturn hReturn, DHookParam hParams)
{
	if (g_iFireBulletWeapon == -1)
		return MRES_Ignored;
	
	Assert(g_nMaxBullets > 0);
	
	char name[64];
	hParams.GetString(1, name, sizeof(name));

	if (strncmp(name, "CTerrorPlayer::FireBullet Spread", 32))
		return MRES_Ignored;
	
	int nPellet = hParams.Get(4);
	int nMaxPellets = g_nMaxBullets;

	if (g_bCenterPellet)
	{
		nPellet -= 1;
		nMaxPellets -= 1;
	}
	
	if (!strcmp(name[32], "Dir"))
	{
		// SpreadDir
		float angle = hReturn.Value;
		if (ApplyPelletSpreadDirMod(g_iFireBulletWeapon, angle, nPellet, nMaxPellets))
		{
			DebugChatMsg("#%d angle %.1f", nPellet, angle);
			hReturn.Value = angle;
			return MRES_Override;
		}
	}
	else
	{
		// Spread
		float flSpread = hParams.Get(3);
		if (ApplyPelletSpreadMod(g_iFireBulletWeapon, flSpread, nPellet, nMaxPellets))
		{
			DebugChatMsg("#%d spread %.1f", nPellet, flSpread);
			hReturn.Value = flSpread;
			return MRES_Override;
		}
	}

	return MRES_Ignored;
}

int GetWeaponMaxBullets(int weapon)
{
	char weaponname[64];
	GetEdictClassname(weapon, weaponname, sizeof(weaponname));
	return L4D2_GetIntWeaponAttribute(weaponname, L4D2IWA_Bullets);
}

void DebugChatMsg(const char[] format, any ...)
{
#if DEBUG
	char buffer[512];
	VFormat(buffer, sizeof(buffer), format, 2);
	PrintToChatAll("[DEBUG] %s", buffer);
#else
	#pragma unused format
#endif
}

void Assert(bool expr, const char[] msg = "")
{
#if DEBUG
	if (!expr)
	{
		if (msg[0])
			ThrowError("Assertion failed! (%s)", msg);
		else
			ThrowError("Assertion failed!");
	}
#else
	#pragma unused expr
	#pragma unused msg
#endif
}

stock ConVar CreateConVarHook(const char[] name,
	const char[] defaultValue,
	const char[] description="",
	int flags=0,
	bool hasMin=false, float min=0.0,
	bool hasMax=false, float max=0.0,
	ConVarChanged callback)
{
	ConVar cv = CreateConVar(name, defaultValue, description, flags, hasMin, min, hasMax, max);

	char value[512];
	cv.GetString(value, sizeof(value));
	
	Call_StartFunction(INVALID_HANDLE, callback);
	Call_PushCell(cv);
	Call_PushString(value);
	Call_PushString(value);
	Call_Finish();
	
	cv.AddChangeHook(callback);
	
	return cv;
}
