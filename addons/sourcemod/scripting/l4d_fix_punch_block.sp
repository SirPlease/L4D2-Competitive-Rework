#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sourcescramble>
#include <collisionhook>
#include <left4dhooks>

#define PLUGIN_VERSION "1.2.3"

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

#define MAX_EDICTS 2048

int
	g_iTankClass,
	g_iZombieClassOffset,
	g_iIncapOffset,
	g_iIncapSize,
	g_iActiveWeaponOffset,
	g_iSwingTimestampOffset,
	g_iSwingPositionOffset,
	g_iAbsOriginOffset = -1,
	g_iMinsOffset,
	g_iMaxsOffset,
	g_iRadiusOffset;

bool g_bIsCommon[MAX_EDICTS + 1];

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

	g_iZombieClassOffset = FindSendPropOffset("CTerrorPlayer", "m_zombieClass");
	g_iIncapOffset = FindSendPropOffset("CTerrorPlayer", "m_isIncapacitated", g_iIncapSize);
	g_iActiveWeaponOffset = FindSendPropOffset("CTerrorPlayer", "m_hActiveWeapon");
	g_iSwingTimestampOffset = FindSendPropOffset("CTankClaw", "m_swingTimer") + 8; // CountdownTimer::m_timestamp
	g_iSwingPositionOffset = FindSendPropOffset("CTankClaw", "m_lowAttackDurationTimer") + 32;

	// late load
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "infected")) != -1)
	{
		if (entity > MaxClients && entity <= MAX_EDICTS)
			g_bIsCommon[entity] = true;
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (entity > MaxClients && entity <= MAX_EDICTS)
		g_bIsCommon[entity] = (strcmp(classname, "infected") == 0);
}

public Action CH_PassFilter(int touch, int pass, bool &result)
{
	// (pass == tank) && (touch == infected)
	if (touch <= MaxClients || touch > MAX_EDICTS || !g_bIsCommon[touch])
		return Plugin_Continue;

	if (pass < 1 || pass > MaxClients || !IsClientInGame(pass))
		return Plugin_Continue;

	if (GetClientTeam(pass) != 3 || GetEntData(pass, g_iZombieClassOffset) != g_iTankClass)
		return Plugin_Continue;

	if (!IsPlayerAlive(pass) || GetEntData(pass, g_iIncapOffset, g_iIncapSize))
		return Plugin_Continue;

	int weapon = GetEntDataEnt2(pass, g_iActiveWeaponOffset);
	if (weapon != -1 && GetEntDataFloat(weapon, g_iSwingTimestampOffset) >= GetGameTime())
	{
		// datamap offsets need an entity, take them from the first common
		if (g_iAbsOriginOffset == -1)
			FindCommonOffsets(touch);

		static float vPos[3], vSwingPos[3], vEntPos[3], vMins[3], vMaxs[3];
		GetClientEyePosition(pass, vPos);
		GetEntDataVector(weapon, g_iSwingPositionOffset, vSwingPos);

		// world space center
		GetEntDataVector(touch, g_iAbsOriginOffset, vEntPos);
		GetEntDataVector(touch, g_iMinsOffset, vMins);
		GetEntDataVector(touch, g_iMaxsOffset, vMaxs);
		vEntPos[0] += (vMins[0] + vMaxs[0]) * 0.5;
		vEntPos[1] += (vMins[1] + vMaxs[1]) * 0.5;
		vEntPos[2] += (vMins[2] + vMaxs[2]) * 0.5;

		float radius2 = GetEntDataFloat(touch, g_iRadiusOffset);
		radius2 = radius2 * radius2;

		if (GetVectorDistance(vPos, vEntPos, true) <= radius2 || GetVectorDistance(vSwingPos, vEntPos, true) <= radius2)
		{
			result = false;
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

void FindCommonOffsets(int common)
{
	char netclass[64];
	GetEntityNetClass(common, netclass, sizeof(netclass));

	g_iMinsOffset = FindSendPropOffset(netclass, "m_vecMins");
	g_iMaxsOffset = FindSendPropOffset(netclass, "m_vecMaxs");
	g_iRadiusOffset = FindDataMapInfo(common, "m_flRadius");
	g_iAbsOriginOffset = FindDataMapInfo(common, "m_vecAbsOrigin");

	if (g_iRadiusOffset == -1 || g_iAbsOriginOffset == -1)
		SetFailState("Failed to find datamap offsets of \"%s\"", netclass);
}

int FindSendPropOffset(const char[] cls, const char[] prop, int &size = 0)
{
	int bits;
	int offset = FindSendPropInfo(cls, prop, _, bits);
	if (offset <= 0)
		SetFailState("Failed to find offset of \"%s::%s\"", cls, prop);

	/*
		GetEntData reads 4 bytes by default, but GetEntProp only reads the property's own size
		Lets get the proper size so GetEntData can read the same value as GetEntProp (need it for m_isIncapacitated)
	*/
	if (bits > 16)
		size = 4;
	else if (bits > 8)
		size = 2;
	else
		size = 1;

	return offset;
}

void PatchNearJump(int instruction, Address src, Address dest)
{
	StoreToAddress(src, instruction, NumberType_Int8);
	StoreToAddress(src + view_as<Address>(1), view_as<int>(dest - src) - 5, NumberType_Int32);
}
