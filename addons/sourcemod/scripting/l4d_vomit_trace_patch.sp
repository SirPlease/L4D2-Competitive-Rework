#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <dhooks>
#include <sourcescramble>

#define PLUGIN_VERSION "2.5"

public Plugin myinfo =
{
	name = "[L4D & 2] Vomit Trace Patch",
	author = "Forgetest",
	description = "Fix vomit stuck on Infected teammates & allow stricter collision test.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
}

methodmap GameDataWrapper < GameData {
	public GameDataWrapper(const char[] file) {
		GameData gd = new GameData(file);
		if (!gd) SetFailState("Missing gamedata \"%s\"", file);
		return view_as<GameDataWrapper>(gd);
	}
	property GameData Super {
		public get() { return view_as<GameData>(this); }
	}
	public int GetOffset(const char[] key) {
		int offset = this.Super.GetOffset(key);
		if (offset == -1) SetFailState("Missing offset \"%s\"", key);
		return offset;
	}
	public Address GetAddress(const char[] key) {
		Address ptr = this.Super.GetAddress(key);
		if (ptr == Address_Null) SetFailState("Missing address \"%s\"", key);
		return ptr;
	}
	public MemoryPatch CreatePatchOrFail(const char[] name, bool enable = false) {
		MemoryPatch hPatch = MemoryPatch.CreateFromConf(this, name);
		if (!(enable ? hPatch.Enable() : hPatch.Validate()))
			SetFailState("Failed to patch \"%s\"", name);
		return hPatch;
	}
	public DynamicHook CreateDHookOrFail(const char[] name) {
		DynamicHook hSetup = DynamicHook.FromConf(this, name);
		if (!hSetup)
			SetFailState("Missing dhook setup \"%s\"", name);
		return hSetup;
	}
}

#define OP_CALL_SIZE 5

bool g_bLeft4Dead2;

MemoryPatch g_hPatch;
DynamicHook g_hDHook;
int g_iPatchOffs, g_iFuncOffs;

DynamicHook g_hDHook_PhysicsSolidMaskForEntity;

ConVar g_cvStrictCollide;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	switch (GetEngineVersion())
	{
		case Engine_Left4Dead: { g_bLeft4Dead2 = false; }
		case Engine_Left4Dead2: { g_bLeft4Dead2 = true; }
		default: { strcopy(error, err_max, "Plugin supports L4D & 2 only."); return APLRes_SilentFailure; }
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	GameDataWrapper conf = new GameDataWrapper("l4d_vomit_trace_patch");

	g_hDHook_PhysicsSolidMaskForEntity = conf.CreateDHookOrFail("CBaseEntity::PhysicsSolidMaskForEntity");

	if (!g_bLeft4Dead2)
	{
		g_hPatch = conf.CreatePatchOrFail("ShouldHitEntity_MyInfectedPointer", false);
		g_hDHook = conf.CreateDHookOrFail("CBaseAbility::UpdateAbility");
		
		Address pGetTeamNumberFuncAddr = conf.GetAddress("CBaseEntity_GetTeamNumber");
		g_iPatchOffs = conf.GetOffset("PatchOffset");
		g_iFuncOffs =
			view_as<int>(pGetTeamNumberFuncAddr) - (view_as<int>(g_hPatch.Address) + (g_iPatchOffs - 1) + OP_CALL_SIZE);
		
		conf.CreatePatchOrFail("OnVomitCollide__TraceRayMask_patch", true);
		conf.CreatePatchOrFail("OnVomitCollide__ClipRayMask_patch", true);
	}
	
	delete conf;

	g_cvStrictCollide = CreateConVar("vomit_collide_strict", "1", "Stricter vomit collision against hitbox instead of bounding box.", FCVAR_NONE, true, 0.0, true, 1.0);
}

void ApplyPatch(bool patch)
{
	static bool patched = false;
	if (patch && !patched)
	{
		if (!g_hPatch.Enable())
			SetFailState("Failed to enable patch \"ShouldHitEntity_MyInfectedPointer\"");
		
		StoreToAddress(g_hPatch.Address + view_as<Address>(g_iPatchOffs), g_iFuncOffs, NumberType_Int32);
		patched = true;
	}
	else if (!patch && patched)
	{
		g_hPatch.Disable();
		patched = false;
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (classname[0] == 'a')
	{
		if (!strcmp(classname, "ability_vomit"))
		{
			if (!g_bLeft4Dead2)
			{
				g_hDHook.HookEntity(Hook_Pre, entity, CVomit_UpdateAbility);
				g_hDHook.HookEntity(Hook_Post, entity, CVomit_UpdateAbility_Post);
			}
			
			g_hDHook_PhysicsSolidMaskForEntity.HookEntity(Hook_Post, entity, CVomit_PhysicsSolidMaskForEntity_Post);
		}
	}
	else if (classname[0] == 'v')
	{
		if (!strcmp(classname, "vomit_particle"))
		{
			g_hDHook_PhysicsSolidMaskForEntity.HookEntity(Hook_Post, entity, CVomitParticle_PhysicsSolidMaskForEntity_Post);
		}
	}
}

MRESReturn CVomit_UpdateAbility(int pThis)
{
	if (GetEntProp(pThis, Prop_Send, "m_isSpraying"))
	{
		ApplyPatch(true);
	}
	
	return MRES_Ignored;
}

MRESReturn CVomit_UpdateAbility_Post(int pThis)
{
	ApplyPatch(false);
	
	return MRES_Ignored;
}

MRESReturn CVomit_PhysicsSolidMaskForEntity_Post(DHookReturn hReturn)
{
	// (L4D1) 0x200400B -> MASK_SOLID
	// (L4D2) 0x2004003 -> MASK_SOLID & ~CONTENTS_GRATE

	int flags = hReturn.Value;
	
	flags &= (~CONTENTS_GRATE);		// Unnecessary for L4D2 though

	if (g_cvStrictCollide.BoolValue)
	{
		flags |= CONTENTS_HITBOX;
	}

	hReturn.Value = flags;
	return MRES_Override;
}

MRESReturn CVomitParticle_PhysicsSolidMaskForEntity_Post(DHookReturn hReturn)
{
	return CVomit_PhysicsSolidMaskForEntity_Post(hReturn);
}