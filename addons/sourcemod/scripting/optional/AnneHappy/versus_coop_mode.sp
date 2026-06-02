#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <dhooks>
#include <left4dhooks>
#include <sourcescramble>

#define PLUGIN_NAME						"Versus Coop Mode"
#define PLUGIN_AUTHOR					"sorallll"
#define PLUGIN_DESCRIPTION				""
#define PLUGIN_VERSION					"1.0.3"
#define PLUGIN_URL						""

#define GAMEDATA						"versus_coop_mode"

#define OFFSET_ISFIRSTROUNDFINISHED		"m_bIsFirstRoundFinished"
#define OFFSET_ISSECONDROUNDFINISHED	"m_bIsSecondRoundFinished"

#define PATCH_SWAPTEAMS_PATCH1			"SwapTeams::Patch1"
#define PATCH_SWAPTEAMS_PATCH2			"SwapTeams::Patch2"
#define PATCH_CLEANUPMAP_PATCH			"CleanUpMap::ShouldCreateEntity::Patch"

#define DETOUR_RESTARTVSMODE			"DD::CDirectorVersusMode::RestartVsMode"

bool
	g_bTransitionFired;

int
	m_bIsFirstRoundFinished,
	m_bIsSecondRoundFinished;

public Plugin myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public void OnPluginStart() {
	InitGameData();
	CreateConVar("versus_coop_mode_version", PLUGIN_VERSION, "Versus Coop Mode plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	HookUserMessage(GetUserMessageId("VGUIMenu"), umVGUIMenu, true);
	HookEvent("round_start",	Event_RoundStart,		EventHookMode_PostNoCopy);
	HookEvent("map_transition", Event_MapTransition,	EventHookMode_Pre);
}

void InitGameData() {
	char buffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, buffer, sizeof buffer, "gamedata/%s.txt", GAMEDATA);
	if (!FileExists(buffer))
		SetFailState("\n==========\nMissing required file: \"%s\".\n==========", buffer);

	GameData hGameData = new GameData(GAMEDATA);
	if (!hGameData)
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	GetOffsets(hGameData);
	InitPatchs(hGameData);
	SetupDetours(hGameData);

	delete hGameData;
}

void GetOffsets(GameData hGameData = null) {
	Offset(hGameData, OFFSET_ISFIRSTROUNDFINISHED, m_bIsFirstRoundFinished);
	Offset(hGameData, OFFSET_ISSECONDROUNDFINISHED, m_bIsSecondRoundFinished);
}

void Offset(GameData hGameData = null, const char[] name, int &offset) {
	offset = hGameData.GetOffset(name);
	if (offset == -1)
		SetFailState("Failed to find offset: \"%s\"", name);
}

void InitPatchs(GameData hGameData = null) {
	MemoryPatch patch;
	Patch(hGameData, patch, PATCH_SWAPTEAMS_PATCH1);
	Patch(hGameData, patch, PATCH_SWAPTEAMS_PATCH2);
	Patch(hGameData, patch, PATCH_CLEANUPMAP_PATCH);
}

void Patch(GameData hGameData = null, MemoryPatch &patch, const char[] name) {
	patch = MemoryPatch.CreateFromConf(hGameData, name);
	if (!patch.Validate())
		SetFailState("Failed to verify patch: \"%s\"", name);
	else if (patch.Enable())
		PrintToServer("[%s] Enabled patch: \"%s\"", PLUGIN_NAME, name);
}

void SetupDetours(GameData hGameData = null) {
	DynamicDetour dDetour = DynamicDetour.FromConf(hGameData, DETOUR_RESTARTVSMODE);
	if (!dDetour)
		SetFailState("Failed to create DynamicDetour: \"%s\"", DETOUR_RESTARTVSMODE);

	if (!dDetour.Enable(Hook_Pre, DD_CDirectorVersusMode_RestartVsMode_Pre))
		SetFailState("Failed to detour pre: \"%s\"", DETOUR_RESTARTVSMODE);
		
	if (!dDetour.Enable(Hook_Post, DD_CDirectorVersusMode_RestartVsMode_Post))
		SetFailState("Failed to detour post: \"%s\"", DETOUR_RESTARTVSMODE);
}

MRESReturn DD_CDirectorVersusMode_RestartVsMode_Pre(Address pThis, DHookReturn hReturn) {
	StoreToAddress(L4D_GetPointer(POINTER_DIRECTOR) + view_as<Address>(m_bIsFirstRoundFinished), g_bTransitionFired ? 1 : 0, NumberType_Int32);
	return MRES_Ignored;
}

MRESReturn DD_CDirectorVersusMode_RestartVsMode_Post(Address pThis, DHookReturn hReturn) {
	if (!g_bTransitionFired) {
		StoreToAddress(L4D_GetPointer(POINTER_DIRECTOR) + view_as<Address>(m_bIsFirstRoundFinished), 0, NumberType_Int32);
		StoreToAddress(L4D_GetPointer(POINTER_DIRECTOR) + view_as<Address>(m_bIsSecondRoundFinished), 0, NumberType_Int32);
	}

	g_bTransitionFired = false;
	return MRES_Ignored;
}

Action umVGUIMenu(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init) {
	static char buffer[26];
	msg.ReadString(buffer, sizeof buffer, true);
	if (strcmp(buffer, "fullscreen_vs_scoreboard") == 0)
		return Plugin_Handled;

	return Plugin_Continue;
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast) {
	g_bTransitionFired = false;
}

Action Event_MapTransition(Event event, const char[] name, bool dontBroadcast) {
	if (!L4D_IsVersusMode())
		return Plugin_Continue;

	if (!OnChangelevelStart()) {
		g_bTransitionFired = false;
		return Plugin_Handled;
	}

	g_bTransitionFired = true;
	return Plugin_Continue;
}

/* ZombieManager::OnChangelevelStart(ZombieManager *__hidden this) */
bool OnChangelevelStart() {
	return !LoadFromAddress(L4D_GetPointer(POINTER_ZOMBIEMANAGER) + view_as<Address>(4), NumberType_Int32);
}