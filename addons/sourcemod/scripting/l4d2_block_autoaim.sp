#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>

#define PLUGIN_VERSION "1.0"
#define GAMEDATA_FILE  "l4d2_block_autoaim"
#define FUNCTION_NAME  "CBasePlayer::ShouldAutoaim"

public Plugin myinfo =
{
	name = "[L4D2] Block Autoaim",
	author = "Sir",
	description = "Strips Auto-Aim from the game entirely (disables controller aim-assist + patches an exploit)",
	version = PLUGIN_VERSION,
	url = ""
};

ConVar g_cvEnabled;
DynamicDetour g_hDetour;
bool g_bDetourEnabled;

public void OnPluginStart()
{
	GameData gd = new GameData(GAMEDATA_FILE);
	if (!gd) {
		SetFailState("Missing gamedata \"" ... GAMEDATA_FILE ... ".txt\"");
	}

	g_hDetour = DynamicDetour.FromConf(gd, FUNCTION_NAME);
	delete gd;

	if (!g_hDetour) {
		SetFailState("Failed to set up detour for \"" ... FUNCTION_NAME ... "\"");
	}

	g_cvEnabled = CreateConVar(
		"l4d2_block_autoaim",
		"1",
		"Disable Auto-Aim",
		FCVAR_NOTIFY,
		true, 0.0, true, 1.0
	);
	g_cvEnabled.AddChangeHook(OnEnabledChanged);

	ApplyDetourState(g_cvEnabled.BoolValue);
}

public void OnPluginEnd()
{
	ApplyDetourState(false);
}

void OnEnabledChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	ApplyDetourState(convar.BoolValue);
}

void ApplyDetourState(bool enable)
{
	if (enable == g_bDetourEnabled) {
		return;
	}

	if (enable) {
		if (!g_hDetour.Enable(Hook_Pre, Detour_ShouldAutoaim)) {
			SetFailState("Failed to enable detour on \"" ... FUNCTION_NAME ... "\"");
		}
		g_bDetourEnabled = true;
	} else {
		g_hDetour.Disable(Hook_Pre, Detour_ShouldAutoaim);
		g_bDetourEnabled = false;
	}
}

MRESReturn Detour_ShouldAutoaim(int pPlayer, DHookReturn hReturn)
{
	hReturn.Value = 0;
	return MRES_Supercede;
}
