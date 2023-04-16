#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sourcescramble>
#include <collisionhook>
#include <left4dhooks_lux_library>

#define PLUGIN_VERSION "1.2.1"

public Plugin myinfo = 
{
	name = "[L4D & 2] Fix Punch Block",
	author = "Forgetest",
	description = "Fix common infected blocking the punch tracing.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins",
}

#define GAMEDATA_FILE "l4d_fix_punch_block"
#define KEY_SWEEPFIST "CTankClaw::SweepFist"
#define KEY_PATCH_SURFIX "__AddEntityToIgnore_dummypatch"
#define KEY_SETPASSENTITY "CTraceFilterSimple::SetPassEntity"

int g_iTankClass;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	switch (GetEngineVersion())
	{
		case Engine_Left4Dead: g_iTankClass = 5;
		case Engine_Left4Dead2: g_iTankClass = 8;
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
	Handle conf = LoadGameConfigFile(GAMEDATA_FILE);
	if (!conf)
		SetFailState("Missing gamedata \""...GAMEDATA_FILE..."\"");
	
	MemoryPatch hPatch = MemoryPatch.CreateFromConf(conf, KEY_SWEEPFIST...KEY_PATCH_SURFIX);
	if (!hPatch.Enable())
		SetFailState("Failed to enable patch \""...KEY_SWEEPFIST...KEY_PATCH_SURFIX..."\"");
	
	int offs = GameConfGetOffset(conf, "OS");
	if (offs == -1)
		SetFailState("Failed to get offset of \"OS\"");
	
	Address addr = GameConfGetAddress(conf, KEY_SETPASSENTITY);
	if (addr == Address_Null)
		SetFailState("Failed to get address of \""...KEY_SETPASSENTITY..."\"");
	
	if (offs == 0) // windows
	{
		addr = LoadFromAddress(addr, NumberType_Int32);
		if (addr == Address_Null)
			SetFailState("Failed to deref pointer to \""...KEY_SETPASSENTITY..."\"");
	}
	
	delete conf;
	
	PatchNearJump(0xE8, hPatch.Address, addr);
}

public Action CH_PassFilter(int touch, int pass, bool &result)
{
	// (pass == tank) && (touch == infected)
	if (!pass || pass > MaxClients || touch <= MaxClients)
		return Plugin_Continue;
	
	if (!IsClientInGame(pass))
		return Plugin_Continue;
	
	if (GetClientTeam(pass) != 3 || GetEntProp(pass, Prop_Send, "m_zombieClass") != g_iTankClass)
		return Plugin_Continue;
	
	static char cls[64];
	if (!GetEdictClassname(touch, cls, sizeof(cls)) || strcmp(cls, "infected") != 0)
		return Plugin_Continue;
	
	if (!IsPlayerAlive(pass) || GetEntProp(pass, Prop_Send, "m_isIncapacitated"))
		return Plugin_Continue;
	
	int weapon = GetEntPropEnt(pass, Prop_Send, "m_hActiveWeapon");
	if (weapon != -1 && GetEntPropFloat(weapon, Prop_Send, "m_swingTimer", 1) >= GetGameTime())
	{
		static int m_vSwingPosition = -1;
		if (m_vSwingPosition == -1)
			m_vSwingPosition = FindSendPropInfo("CTankClaw", "m_lowAttackDurationTimer") + 32;
		
		static float vPos[3], vSwingPos[3], vEntPos[3];
		GetClientEyePosition(pass, vPos);
		GetAbsOrigin(touch, vEntPos, true);
		GetEntDataVector(weapon, m_vSwingPosition, vSwingPos);
		
		float radius2 = GetEntPropFloat(touch, Prop_Data, "m_flRadius");
		radius2 = radius2 * radius2;
		
		if (GetVectorDistance(vPos, vEntPos, true) <= radius2 || GetVectorDistance(vSwingPos, vEntPos, true) <= radius2)
		{
			result = false;
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

void PatchNearJump(int instruction, Address src, Address dest)
{
	StoreToAddress(src, instruction, NumberType_Int8);
	StoreToAddress(src + view_as<Address>(1), view_as<int>(dest - src) - 5, NumberType_Int32);
}