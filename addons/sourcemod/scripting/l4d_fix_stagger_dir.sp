#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
// #include <dhooks>
#include <left4dhooks>

#define PLUGIN_VERSION "1.2"

public Plugin myinfo = 
{
	name = "[L4D & 2] Fix Stagger Direction",
	author = "Forgetest",
	description = "Fix survivors getting stumbled to the \"opposite\" direction.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins",
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
	// public DynamicDetour CreateDetourOrFail(
	// 		const char[] name,
	// 		DHookCallback preHook = INVALID_FUNCTION,
	// 		DHookCallback postHook = INVALID_FUNCTION) {
	// 	DynamicDetour hSetup = DynamicDetour.FromConf(this, name);
	// 	if (!hSetup)
	// 		SetFailState("Missing detour setup \"%s\"", name);
	// 	if (preHook != INVALID_FUNCTION && !hSetup.Enable(Hook_Pre, preHook))
	// 		SetFailState("Failed to pre-detour \"%s\"", name);
	// 	if (postHook != INVALID_FUNCTION && !hSetup.Enable(Hook_Post, postHook))
	// 		SetFailState("Failed to post-detour \"%s\"", name);
	// 	return hSetup;
	// }
}

int g_iOffs_m_PlayerAnimState;
int g_iOffs_m_flEyeYaw;

methodmap Address {}
methodmap PlayerAnimStateEx < Address
{
	public static PlayerAnimStateEx FromPlayer(int client) {
		return view_as<PlayerAnimStateEx>(GetEntData(client, g_iOffs_m_PlayerAnimState));
	}

	property float m_flEyeYaw {
		public set(float flAimYaw) { StoreToAddress(this + view_as<Address>(g_iOffs_m_flEyeYaw), flAimYaw, NumberType_Int32); }
	}
}

public void OnPluginStart()
{
	GameDataWrapper gd = new GameDataWrapper("l4d_fix_stagger_dir");
	g_iOffs_m_PlayerAnimState = gd.GetOffset("CTerrorPlayer::m_PlayerAnimState");
	g_iOffs_m_flEyeYaw = gd.GetOffset("m_flEyeYaw");

	// https://github.com/Target5150/MoYu_Server_Stupid_Plugins/issues/70
	// delete gd.CreateDetourOrFail("CTerrorPlayer::OnShovedBySurvivor", DTR_OnShovedBySurvivor);
	// delete gd.CreateDetourOrFail("CTerrorPlayer::OnStaggered", DTR_OnStaggered);
	delete gd;
}

public Action L4D_OnShovedBySurvivor(int client, int victim, const float vecDir[3])
{
	if (IsClientInGame(victim))
	{
		float ang[3];
		GetClientAbsAngles(victim, ang);
		PlayerAnimStateEx.FromPlayer(victim).m_flEyeYaw = ang[1];
	}

	return Plugin_Continue;
}

public Action L4D2_OnStagger(int client, int source)
{
	if (IsClientInGame(client))
	{
		float ang[3];
		GetClientAbsAngles(client, ang);
		PlayerAnimStateEx.FromPlayer(client).m_flEyeYaw = ang[1];
	}

	return Plugin_Continue;
}

// MRESReturn DTR_OnShovedBySurvivor(DHookParam hParams)
// {
// 	int client = hParams.Get(1);
// 	if (IsClientInGame(client))
// 	{
// 		float ang[3];
// 		GetClientAbsAngles(client, ang);
// 		PlayerAnimStateEx.FromPlayer(client).m_flEyeYaw = ang[1];
// 	}

// 	return MRES_Ignored;
// }

// MRESReturn DTR_OnStaggered(int client, DHookParam hParams)
// {
// 	if (IsClientInGame(client))
// 	{
// 		float ang[3];
// 		GetClientAbsAngles(client, ang);
// 		PlayerAnimStateEx.FromPlayer(client).m_flEyeYaw = ang[1];
// 	}

// 	return MRES_Ignored;
// }