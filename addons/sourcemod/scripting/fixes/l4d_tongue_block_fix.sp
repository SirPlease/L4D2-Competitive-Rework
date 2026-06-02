#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <collisionhook>
#include <sourcescramble>
#include <dhooks>

#define PLUGIN_VERSION "1.2.1"

public Plugin myinfo = 
{
	name = "[L4D & 2] Tongue Block Fix",
	author = "Forgetest",
	description = "Fix infected teammate blocking tongue chasing.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins",
}

#define GAMEDATA_FILE "l4d_tongue_block_fix"
#define KEY_FUNCTION "CTongue::OnUpdateExtendingState"
#define KEY_FUNCTION_2 "CTongue::UpdateTongueTarget"
#define KEY_FUNCTION_3 "TongueTargetScan<CTerrorPlayer>::IsTargetVisible"
#define KEY_PATCH_SURFIX "__AddEntityToIgnore_argpatch"
#define KEY_PATCH_SURFIX_2 "__TraceFilterTongue_passentpatch"
#define KEY_PATCH_SURFIX_3 "__AddEntityToIgnore_dummypatch"
#define KEY_SETPASSENTITY "CTraceFilterSimple::SetPassEntity"

DynamicDetour g_hDetour;

int
	g_iTankClass,
	g_iTipFlag,
	g_iFlyFlag;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	switch (GetEngineVersion())
	{
		case Engine_Left4Dead: { g_iTankClass = 5; }
		case Engine_Left4Dead2: { g_iTankClass = 8; }
		default:
		{
			strcopy(error, err_max, "Plugin supports Left 4 Dead & 2 only.");
			return APLRes_SilentFailure;
		}
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	GameData conf = new GameData(GAMEDATA_FILE);
	if (!conf)
		SetFailState("Missing gamedata \""...GAMEDATA_FILE..."\"");
	
	int os = conf.GetOffset("OS");
	if (os == -1)
		SetFailState("Failed to get offset of \"OS\"");
	
	Address addr = conf.GetAddress(KEY_SETPASSENTITY);
	if (addr == Address_Null)
		SetFailState("Failed to get address of \""...KEY_SETPASSENTITY..."\"");
	
	if (os == 0) // windows
	{
		addr = LoadFromAddress(addr, NumberType_Int32);
		if (addr == Address_Null)
			SetFailState("Failed to deref pointer to \""...KEY_SETPASSENTITY..."\"");
	}
	
	MemoryPatch hPatch = MemoryPatch.CreateFromConf(conf, KEY_FUNCTION...KEY_PATCH_SURFIX);
	if (!hPatch.Enable())
		SetFailState("Failed to enable patch \""...KEY_FUNCTION...KEY_PATCH_SURFIX..."\"");
	
	hPatch = MemoryPatch.CreateFromConf(conf, KEY_FUNCTION...KEY_PATCH_SURFIX_2);
	if (!hPatch.Enable())
		SetFailState("Failed to enable patch \""...KEY_FUNCTION...KEY_PATCH_SURFIX_2..."\"");
	
	hPatch = MemoryPatch.CreateFromConf(conf, KEY_FUNCTION...KEY_PATCH_SURFIX_3);
	if (!hPatch.Enable())
		SetFailState("Failed to enable patch \""...KEY_FUNCTION...KEY_PATCH_SURFIX_3..."\"");
	
	PatchNearJump(0xE8, hPatch.Address, addr);
	
	if (GetEngineVersion() == Engine_Left4Dead)
	{
		hPatch = MemoryPatch.CreateFromConf(conf, KEY_FUNCTION_3...KEY_PATCH_SURFIX_3);
		if (!hPatch.Enable())
			SetFailState("Failed to enable patch \""...KEY_FUNCTION_3...KEY_PATCH_SURFIX_3..."\"");
		
		PatchNearJump(0xE8, hPatch.Address, addr);
	}
	
	g_hDetour = DynamicDetour.FromConf(conf, KEY_FUNCTION_2);
	if (!g_hDetour)
		SetFailState("Missing detour setup \""...KEY_FUNCTION_2..."\"");
	
	delete conf;
	
	ConVar cv = CreateConVar("tongue_tip_through_teammate",
								"0",
								"Whether smoker can shoot his tongue through his teammates.\n"
							...	"1 = Through generic SIs, 2 = Through Tank, 3 = All, 0 = Disabled",
								FCVAR_SPONLY,
								true, 0.0, true, 3.0);
	CvarChg_TipThroughTeammate(cv, "", "");
	cv.AddChangeHook(CvarChg_TipThroughTeammate);
	
	cv = CreateConVar("tongue_fly_through_teammate",
								"1",
								"Whether tongue can go through his teammates once shot.\n"
							...	"1 = Through generic SIs, 2 = Through Tank, 3 = All, 0 = Disabled",
								FCVAR_SPONLY,
								true, 0.0, true, 3.0);
	CvarChg_FlyThroughTeammate(cv, "", "");
	cv.AddChangeHook(CvarChg_FlyThroughTeammate);
}

void CvarChg_TipThroughTeammate(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iTipFlag = convar.IntValue;
	ToggleDetour(g_iTipFlag > 0);
}

void CvarChg_FlyThroughTeammate(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iFlyFlag = convar.IntValue;
}

void ToggleDetour(bool enable)
{
	static bool enabled = false;
	if (enable && !enabled)
	{
		if (!g_hDetour.Enable(Hook_Pre, DTR_OnUpdateTongueTarget))
			SetFailState("Failed to pre-detour \""...KEY_FUNCTION_2..."\"");
		if (!g_hDetour.Enable(Hook_Post, DTR_OnUpdateTongueTarget_Post))
			SetFailState("Failed to post-detour \""...KEY_FUNCTION_2..."\"");
		enabled = true;
	}
	else if (!enable && enabled)
	{
		if (!g_hDetour.Disable(Hook_Pre, DTR_OnUpdateTongueTarget))
			SetFailState("Failed to remove pre-detour \""...KEY_FUNCTION_2..."\"");
		if (!g_hDetour.Disable(Hook_Post, DTR_OnUpdateTongueTarget_Post))
			SetFailState("Failed to remove post-detour \""...KEY_FUNCTION_2..."\"");
		enabled = false;
	}
}

bool g_bUpdateTongueTarget = false;
MRESReturn DTR_OnUpdateTongueTarget(int pThis)
{
	g_bUpdateTongueTarget = true;
	return MRES_Ignored;
}

MRESReturn DTR_OnUpdateTongueTarget_Post(int pThis)
{
	g_bUpdateTongueTarget = false;
	return MRES_Ignored;
}

public Action CH_PassFilter(int touch, int pass, bool &result)
{
	if (!touch || touch > MaxClients || !IsClientInGame(touch))
		return Plugin_Continue;
	
	if (GetClientTeam(touch) != 3)
		return Plugin_Continue;
		
	if (!g_bUpdateTongueTarget)
	{
		if (pass <= MaxClients)
			return Plugin_Continue;
		
		static char cls[64];
		if (!GetEdictClassname(pass, cls, sizeof(cls)))
			return Plugin_Continue;
		
		if (strcmp(cls, "ability_tongue") != 0)
			return Plugin_Continue;
		
		if (touch == GetEntPropEnt(pass, Prop_Send, "m_owner")) // probably won't happen
			return Plugin_Continue;
			
		if (GetEntProp(touch, Prop_Send, "m_zombieClass") == g_iTankClass)
		{
			if (~g_iFlyFlag & 2)
				return Plugin_Continue;
		}
		else if (~g_iFlyFlag & 1)
			return Plugin_Continue;
	}
	else
	{
		if (!pass || pass > MaxClients)
			return Plugin_Continue;
		
		if (!IsClientInGame(pass))
			return Plugin_Continue;
		
		if (GetClientTeam(pass) != 3 || GetEntProp(pass, Prop_Send, "m_zombieClass") != 1)
			return Plugin_Continue;
			
		if (GetEntProp(touch, Prop_Send, "m_zombieClass") == g_iTankClass)
		{
			if (~g_iTipFlag & 2)
				return Plugin_Continue;
		}
		else if (~g_iTipFlag & 1)
			return Plugin_Continue;
	}
	
	result = false;
	return Plugin_Handled;
}

void PatchNearJump(int instruction, Address src, Address dest)
{
	StoreToAddress(src, instruction, NumberType_Int8);
	StoreToAddress(src + view_as<Address>(1), view_as<int>(dest - src) - 5, NumberType_Int32);
}