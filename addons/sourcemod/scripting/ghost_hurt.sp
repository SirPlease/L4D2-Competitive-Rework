#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <readyup>

ConVar
	g_hGhostHurtType = null;

bool
	g_bReadyUpAvailable = false;

public Plugin myinfo =
{
	name = "Ghost Hurt Management",
	author = "Jacob",
	description = "Allows for modifications of trigger_hurt_ghost",
	version = "1.1",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	g_hGhostHurtType = CreateConVar("ghost_hurt_type", "0", "When should trigger_hurt_ghost be enabled? 0 = Never, 1 = On Round Start", _, true, 0.0, true, 1.0);

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);

	RegServerCmd("sm_reset_ghost_hurt", Cmd_ResetGhostHurt, "Used to reset trigger_hurt_ghost between matches.  This should be in confogl_off.cfg or equivalent for your system");
}

public void OnAllPluginsLoaded()
{
	g_bReadyUpAvailable = LibraryExists("readyup");
}

public void OnLibraryRemoved(const char[] sName)
{
	if (strcmp(sName, "readyup", true) == 0) {
		g_bReadyUpAvailable = false;
	}
}

public void OnLibraryAdded(const char[] sName)
{
	if (strcmp(sName, "readyup", true) == 0) {
		g_bReadyUpAvailable = true;
	}
}

public void OnRoundIsLive()
{
	EnableGhostHurt();
}

public Action L4D_OnFirstSurvivorLeftSafeArea(int iClient)
{
	if (!g_bReadyUpAvailable) {
		EnableGhostHurt();
	}

	return Plugin_Continue;
}

public void OnMapStart()
{
	DisableGhostHurt();
}

public void Event_RoundStart(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	DisableGhostHurt();
}

public Action Cmd_ResetGhostHurt(int iArgs)
{
	DisableGhostHurt();
	PrintToServer("DisableGhostHurt()");

	return Plugin_Handled;
}

void DisableGhostHurt()
{
	ModifyEntity("trigger_hurt_ghost", "Disable");
}

void EnableGhostHurt()
{
	if (g_hGhostHurtType.BoolValue) {
		ModifyEntity("trigger_hurt_ghost", "Enable");
	}
}

void ModifyEntity(const char[] sClassName, const char[] sInputName)
{
	int iEntity = -1;

	while ((iEntity = FindEntityByClassname(iEntity, sClassName)) != -1) {
		if (!IsValidEdict(iEntity) || !IsValidEntity(iEntity)) {
			continue;
		}

		AcceptEntityInput(iEntity, sInputName);
	}
}
