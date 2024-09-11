#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>

#define PLUGIN_VERSION "1.0"

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

int g_iOffs_m_PlayerAnimState;
int g_iOffs_m_flEyeYaw;

methodmap Address {}
methodmap PlayerAnimState < Address {
	public static PlayerAnimState FromPlayer(int client) {
		return view_as<PlayerAnimState>(GetEntData(client, g_iOffs_m_PlayerAnimState));
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

	delete gd.CreateDetourOrFail("CTerrorPlayer::OnStaggered", DTR_OnStaggered);
	delete gd;
}

MRESReturn DTR_OnStaggered(int client, DHookParam hParams)
{
	if (IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		float ang[3];
		GetClientAbsAngles(client, ang);
		PlayerAnimState.FromPlayer(client).m_flEyeYaw = ang[1];
	}

	return MRES_Ignored;
}