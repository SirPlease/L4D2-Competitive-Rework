#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>

#define PLUGIN_VERSION "1.0"

public Plugin myinfo = 
{
	name = "[L4D & 2] Fix Rocket Jump",
	author = "Forgetest",
	description = "Fix some \"grounds\" launching survivors into the air.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins",
}

methodmap GameDataWrapper < GameData {
	public GameDataWrapper(const char[] file) {
		GameData gd = new GameData(file);
		if (!gd) SetFailState("Missing gamedata \"%s\"", file);
		return view_as<GameDataWrapper>(gd);
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

public void OnPluginStart()
{
	GameDataWrapper gd = new GameDataWrapper("l4d_fix_rocket_jump");
	delete gd.CreateDetourOrFail("CGameMovement::SetGroundEntity", DTR_SetGroundEntity, DTR_SetGroundEntity_Post);
	delete gd;
}

// https://github.com/ValveSoftware/source-sdk-2013/blob/39f6dde8fbc238727c020d13b05ecadd31bda4c0/src/game/shared/gamemovement.cpp#L3611
static bool g_bRestore[MAXPLAYERS+1];
static float g_vecSavedBaseVel[MAXPLAYERS+1][3];
MRESReturn DTR_SetGroundEntity(DHookParam hParams)
{
	int client = hParams.GetObjectVar(1, 4, ObjectValueType_CBaseEntityPtr);

	int oldground = GetEntPropEnt(client, Prop_Send, "m_hGroundEntity");
	int newground = !hParams.IsNull(2) ? hParams.GetObjectVar(2, 76, ObjectValueType_CBaseEntityPtr) : -1;

	g_bRestore[client] = false;

	if ((oldground == -1 && newground != -1) || (oldground != -1 && newground == -1))
	{
		g_bRestore[client] = !PassStandableGround(client, newground == -1 ? oldground : newground);
	}

	if (g_bRestore[client])
	{
		GetEntPropVector(client, Prop_Data, "m_vecBaseVelocity", g_vecSavedBaseVel[client]);
	}

	return MRES_Ignored;
}

MRESReturn DTR_SetGroundEntity_Post(DHookParam hParams)
{
	int client = hParams.GetObjectVar(1, 4, ObjectValueType_CBaseEntityPtr);

	if (g_bRestore[client])
	{
		SetEntPropVector(client, Prop_Data, "m_vecBaseVelocity", g_vecSavedBaseVel[client]);
	}

	return MRES_Ignored;
}

bool PassStandableGround(int client, int entity)
{
	if (entity > MaxClients)
	{
		char cls[64];
		GetEntityClassname(entity, cls, sizeof(cls));

		if (!strcmp(cls, "witch") || !strcmp(cls, "infected"))
			return false;
		
		if (StrContains(cls, "_projectile") != -1)
			return false;
	}
	else if (entity > 0)
	{
		if (GetClientTeam(client) == 2 && GetClientTeam(entity) == 3)
			return false;
	}
	
	return true;
}

// Reverse bot's aim pitch for solo testing GL jump with "bot_mimic" on.
/*
#include <sdktools_hooks>

methodmap CUserCmd
{
	property float viewangles_x {
		public get() { return LoadFromAddress(view_as<Address>(this) + view_as<Address>(12), NumberType_Int32); }
		public set(float x) { StoreToAddress(view_as<Address>(this) + view_as<Address>(12), x, NumberType_Int32); }
	}
}

int g_iRestoreMimic = -1;
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	static ConVar bot_mimic = null;
	if (bot_mimic == null)
		bot_mimic = FindConVar("bot_mimic");
	
	if (!IsClientInGame(client) || !IsFakeClient(client))
		return Plugin_Continue;

	int player = bot_mimic.IntValue;
	if (player <= 0 || player > MaxClients || !IsClientInGame(player))
		return Plugin_Continue;

	g_iRestoreMimic = player;
	GetPlayerLastCommand(player).viewangles_x = -GetPlayerLastCommand(player).viewangles_x;
	return Plugin_Continue;
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	if (g_iRestoreMimic != -1)
	{
		GetPlayerLastCommand(g_iRestoreMimic).viewangles_x = -GetPlayerLastCommand(g_iRestoreMimic).viewangles_x;
		g_iRestoreMimic = -1;
	}
}

CUserCmd GetPlayerLastCommand(int player)
{
	static int s_iOffs_m_LastCmd = -1;
	if (s_iOffs_m_LastCmd == -1)
		s_iOffs_m_LastCmd = FindDataMapInfo(player, "m_hViewModel")
									+ 4*2; // CHandle<CBaseViewModel> * MAX_VIEWMODELS

	return view_as<CUserCmd>(GetEntityAddress(player) +  view_as<Address>(s_iOffs_m_LastCmd));
}
*/