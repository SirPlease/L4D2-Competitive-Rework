#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <left4dhooks>

#define PLUGIN_NAME				"Coop Round Restart Delay"
#define PLUGIN_AUTHOR			"sorallll"
#define PLUGIN_DESCRIPTION		""
#define PLUGIN_VERSION			"1.0.0"
#define PLUGIN_URL				""

#define CVAR_FLAGS 				FCVAR_NOTIFY

ConVar
	g_cRestartDelay;

float
	g_fRestartDelay;

public Plugin myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public void OnPluginStart() {
	CreateConVar("coop_round_restart_delay_version", PLUGIN_VERSION, "Coop Round Restart Delay plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_cRestartDelay = CreateConVar("coop_round_restart_delay", "2.0", "战役模式回合重开延迟时间", CVAR_FLAGS, true, 0.0);
	g_cRestartDelay.AddChangeHook(CvarChanged);

	HookUserMessage(GetUserMessageId("Fade"), umFade, true);
	HookEvent("mission_lost", Event_MissionLost, EventHookMode_PostNoCopy);
}

public void OnConfigsExecuted() {
	GetCvars();
}

void CvarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	GetCvars();
}

void GetCvars() {
	g_fRestartDelay = g_cRestartDelay.FloatValue;
}

Action umFade(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init) {
	if (!g_fRestartDelay && view_as<float>(LoadFromAddress(L4D_GetPointer(POINTER_DIRECTOR) + view_as<Address>(616 + 8), NumberType_Int32)) > 0.0)
		return Plugin_Handled;

	return Plugin_Continue;
}

void Event_MissionLost(Event event, const char[] name, bool dontBroadcast) {
	StoreToAddress(L4D_GetPointer(POINTER_DIRECTOR) + view_as<Address>(616 + 4), view_as<int>(g_fRestartDelay), NumberType_Int32);
	StoreToAddress(L4D_GetPointer(POINTER_DIRECTOR) + view_as<Address>(616 + 8), view_as<int>(GetGameTime() + g_fRestartDelay), NumberType_Int32);
}