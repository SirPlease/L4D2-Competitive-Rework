#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>
#include <sourcescramble>

#define PLUGIN_VERSION "1.0"

public Plugin myinfo = 
{
	name = "[L4D & 2] Prop Touching Rules",
	author = "Forgetest",
	description = "Rules of props' move away, moved above props.",
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

MemoryPatch g_Patch_MoveAwayMassThres;
MemoryBlock g_Block_MoveAwayMassThres;
MemoryPatch g_Patch_MoveAway;
MemoryPatch g_Patch_HeavyMoveAbove;
DynamicDetour g_Detour_PhysicsDamage;
int g_iMoveAboveFlags;

public void OnPluginStart()
{
	GameDataWrapper gd = new GameDataWrapper("l4d_prop_touching_rules");

	g_Block_MoveAwayMassThres = new MemoryBlock(4);
	g_Patch_MoveAwayMassThres = gd.CreatePatchOrFail("prop_moveaway_mass_thres", true);
	StoreToAddress(g_Patch_MoveAwayMassThres.Address + view_as<Address>(4), g_Block_MoveAwayMassThres.Address, NumberType_Int32, false);

	g_Patch_MoveAway = gd.CreatePatchOrFail("prop_medium_touching_moveaway", false);
	g_Patch_HeavyMoveAbove = gd.CreatePatchOrFail("prop_heavy_touching_move_above", false);
	g_Detour_PhysicsDamage = gd.CreateDetourOrFail("PhysicsDamage::operator()");
	delete gd;

	CreateConVarHook("prop_moveaway_mass_thres",
		"900.0",
		"Maximum mass for props allowed to be moved away on touching.\n\
		NOTE: Unused if \"prop_touching_moveaway\" is disabled.",
		FCVAR_NONE,
		true, 0.0, false, 0.0, CvarChg_MoveAwayMassThres);
	CreateConVarHook(
		"prop_touching_moveaway",
		"1",
		"Move away medium-weight props on touching.",
		FCVAR_NONE,
		true, 0.0, true, 1.0, CvarChg_MoveAway);
	CreateConVarHook(
		"prop_heavy_touching_move_above",
		"0",
		"Stop players being moved above heavy props on touching.\n\
		0 = Disable, 1 = Survivors, 2 = Special except tank, 4 = Tank, 7 = All",
		FCVAR_NONE,
		true, 0.0, false, 7.0, CvarChg_HeavyMoveAbove);
}

void CvarChg_MoveAwayMassThres(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_Block_MoveAwayMassThres.StoreToOffset(0, view_as<int>(convar.FloatValue), NumberType_Int32);
}

void CvarChg_MoveAway(ConVar convar, const char[] oldValue, const char[] newValue)
{
	TogglePatch_MoveAway(!convar.BoolValue);
}

void CvarChg_HeavyMoveAbove(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iMoveAboveFlags = convar.IntValue;
	ToggleDetour_PhysicsDamage(g_iMoveAboveFlags != 0);
}

MRESReturn DTR_OnPhysicsDamage(DHookReturn hReturn, DHookParam hParams)
{
	int client = hParams.Get(1);
	if (client == -1 || !IsClientInGame(client))
		return MRES_Ignored;
	
	if( (GetClientTeam(client) == 2 && !(g_iMoveAboveFlags & 1))
	 || (GetClientTeam(client) == 3 && !L4D_IsClassTank(client) && !(g_iMoveAboveFlags & 2))
	 || (GetClientTeam(client) == 3 && L4D_IsClassTank(client) && !(g_iMoveAboveFlags & 4)) )
		return MRES_Ignored;
	
	TogglePatch_HeavyMoveAbove(true);
	return MRES_Ignored;
}

MRESReturn DTR_OnPhysicsDamage_Post(DHookReturn hReturn, DHookParam hParams)
{
	TogglePatch_HeavyMoveAbove(false);
	return MRES_Ignored;
}

void TogglePatch_MoveAway(bool enable)
{
	static bool state = false;

	if (state == enable)
		return;
	
	state = enable;
	if (state)
		g_Patch_MoveAway.Enable();
	else 
		g_Patch_MoveAway.Disable();
}

void TogglePatch_HeavyMoveAbove(bool enable)
{
	static bool state = false;

	if (state == enable)
		return;
	
	state = enable;
	if (state)
		g_Patch_HeavyMoveAbove.Enable();
	else 
		g_Patch_HeavyMoveAbove.Disable();
}

void ToggleDetour_PhysicsDamage(bool enable)
{
	static bool state = false;

	if (state == enable)
		return;
	
	state = enable;
	if (state)
	{
		g_Detour_PhysicsDamage.Enable(Hook_Pre, DTR_OnPhysicsDamage);
		g_Detour_PhysicsDamage.Enable(Hook_Post, DTR_OnPhysicsDamage_Post);
	}
	else
	{
		g_Detour_PhysicsDamage.Disable(Hook_Pre, DTR_OnPhysicsDamage);
		g_Detour_PhysicsDamage.Disable(Hook_Post, DTR_OnPhysicsDamage_Post);
	}
}

bool L4D_IsClassTank(int client)
{
	static int class = -1;
	if (class == -1)
	{
		if (GetEngineVersion() == Engine_Left4Dead)
			class = 5;
		else if (GetEngineVersion() == Engine_Left4Dead2)
			class = 8;
	}

	return GetEntProp(client, Prop_Send, "m_zombieClass") == class;
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
	
	Call_StartFunction(INVALID_HANDLE, callback);
	Call_PushCell(cv);
	Call_PushNullString();
	Call_PushNullString();
	Call_Finish();
	
	cv.AddChangeHook(callback);
	
	return cv;
}
