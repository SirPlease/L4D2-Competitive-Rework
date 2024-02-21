#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
//#include <sdktools>
//#include <sdkhooks>
#include <left4dhooks>

#define PLUGIN_NAME					"SafeArea Teleport"
#define PLUGIN_AUTHOR				"sorallll"
#define PLUGIN_DESCRIPTION			""
#define PLUGIN_VERSION				"1.2.0"
#define PLUGIN_URL					"https://forums.alliedmods.net/showthread.php?p=2766514#post2766514"

#define DEBUG						0
#define CVAR_FLAGS					FCVAR_NOTIFY

#define SAFE_ROOM					(1 << 0)
#define RESCUE_VEHICLE				(1 << 1)

#define GAMEDATA					"safearea_teleport"
#define SOUND_COUNTDOWN 			"buttons/blip1.wav"

Handle
	g_hTimer,
	g_hSDK_CTerrorPlayer_CleanupPlayerState,
	g_hSDK_TerrorNavMesh_GetLastCheckpoint,
	g_hSDK_Checkpoint_ContainsArea,
	g_hSDK_Checkpoint_GetLargestArea,
	g_hSDK_CDirectorChallengeMode_FindRescueAreaTrigger,
	g_hSDK_CBaseTrigger_IsTouching;

Address
	g_pTheCount;

ArrayList
	g_aEndNavArea,
	g_aRescueVehicle;

ConVar
	g_hCvarAllow,
	g_hCvarModes,
	g_hCvarModesOff,
	g_hCvarModesTog,
	g_hCvarMPGameMode,
	g_hSafeAreaFlags,
	g_hSafeAreaType,
	g_hSafeAreaTime,
	g_hMinSurvivorPercent;

int
	g_iTheCount,
	g_iCountdown,
	g_iChangelevel,
	g_iRescueVehicle,
	g_iTriggerFinale,
	g_iOff_m_flow,
	g_iSafeAreaFlags,
	g_iSafeAreaType,
	g_iSafeAreaTime,
	g_iMinSurvivorPercent;

float
	g_vMins[3],
	g_vMaxs[3],
	g_vOrigin[3];

bool
	g_bCvarAllow,
	g_bMapStarted,
	g_bTranslation,
	g_bIsFinalMap,
	g_bIsTriggered,
	g_bIsSacrificeFinale,
	g_bFinaleVehicleReady;

enum struct Door {
	int entRef;
	float m_flSpeed;
}

Door
	g_LastDoor;

methodmap TerrorNavArea {
	public bool IsNull() {
		return view_as<Address>(this) == Address_Null;
	}

	public void Mins(float result[3]) {
		result[0] = view_as<float>(LoadFromAddress(view_as<Address>(this) + view_as<Address>(4), NumberType_Int32));
		result[1] = view_as<float>(LoadFromAddress(view_as<Address>(this) + view_as<Address>(8), NumberType_Int32));
		result[2] = view_as<float>(LoadFromAddress(view_as<Address>(this) + view_as<Address>(12), NumberType_Int32));
	}

	public void Maxs(float result[3]) {
		result[0] = view_as<float>(LoadFromAddress(view_as<Address>(this) + view_as<Address>(16), NumberType_Int32));
		result[1] = view_as<float>(LoadFromAddress(view_as<Address>(this) + view_as<Address>(20), NumberType_Int32));
		result[2] = view_as<float>(LoadFromAddress(view_as<Address>(this) + view_as<Address>(24), NumberType_Int32));
	}

	public void Center(float result[3]) {
		float vMins[3];
		float vMaxs[3];
		this.Mins(vMins);
		this.Maxs(vMaxs);

		AddVectors(vMins, vMaxs, result);
		ScaleVector(result, 0.5);
	}

	public void FindRandomSpot(float result[3]) {
		L4D_FindRandomSpot(view_as<int>(this), result);
	}

	property float m_flow {
		public get() {
			return view_as<float>(LoadFromAddress(view_as<Address>(this) + view_as<Address>(g_iOff_m_flow), NumberType_Int32));
		}
	}
	
	property int m_attributeFlags {
		public get() {
			return L4D_GetNavArea_AttributeFlags(view_as<Address>(this));
		}
	}

	property int m_spawnAttributes {
		public get() {
			return L4D_GetNavArea_SpawnAttributes(view_as<Address>(this));
		}
	}
};

// 如果签名失效，请到此处更新https://github.com/Psykotikism/L4D1-2_Signatures
public Plugin myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public void OnPluginStart() {
	InitData();
	g_aEndNavArea = new ArrayList();
	g_aRescueVehicle = new ArrayList();

	CreateConVar("safearea_teleport_version", PLUGIN_VERSION, "SafeArea Teleport plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hCvarAllow =			CreateConVar("st_allow",		"1",	"0=Plugin off, 1=Plugin on.", CVAR_FLAGS);
	g_hCvarModes =			CreateConVar("st_modes",		"",		"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS);
	g_hCvarModesOff =		CreateConVar("st_modes_off",	"",		"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS);
	g_hCvarModesTog =		CreateConVar("st_modes_tog",	"0",	"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS);

	g_hSafeAreaFlags =		CreateConVar("st_enable",		"3",	"Where is it enabled? (1=Safe Room, 2=Rescue Vehicle, 3=Both)", CVAR_FLAGS);
	g_hSafeAreaType =		CreateConVar("st_type",			"1",	"How to deal with players who have not entered the destination safe area (1=teleport, 2=slay)", CVAR_FLAGS);
	g_hSafeAreaTime =		CreateConVar("st_time",			"30",	"How many seconds to count down before processing", CVAR_FLAGS);
	g_hMinSurvivorPercent =	CreateConVar("st_min_percent",	"100",	"What percentage of the survivors start the countdown when they reach the finish area", CVAR_FLAGS);
	
	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(CvarChanged_Allow);
	g_hCvarAllow.AddChangeHook(CvarChanged_Allow);
	g_hCvarModes.AddChangeHook(CvarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(CvarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(CvarChanged_Allow);

	g_hSafeAreaFlags.AddChangeHook(CvarChanged);
	g_hSafeAreaType.AddChangeHook(CvarChanged);
	g_hSafeAreaTime.AddChangeHook(CvarChanged);
	g_hMinSurvivorPercent.AddChangeHook(CvarChanged);

	AutoExecConfig(true);

	RegAdminCmd("sm_warpend", cmdWarpEnd, ADMFLAG_RCON, "Send all survivors to the destination safe area");
	RegAdminCmd("sm_st", cmdSt, ADMFLAG_ROOT, "Test");
	
	HookEntityOutput("trigger_finale", "FinaleStart", OnFinaleStart);
}

void OnFinaleStart(const char[] output, int caller, int activator, float delay) {
	if (!g_bIsFinalMap || g_iSafeAreaFlags & RESCUE_VEHICLE == 0 || IsValidEntRef(g_iTriggerFinale))
		return;

	g_iTriggerFinale = EntIndexToEntRef(caller);
	g_bIsSacrificeFinale = !!GetEntProp(g_iTriggerFinale, Prop_Data, "m_bIsSacrificeFinale");

	if (g_bIsSacrificeFinale) {
		if (g_bTranslation)
			PrintToChatAll("\x05%t", "IsSacrificeFinale");
		else
			PrintToChatAll("\x05该地图是牺牲结局, 已关闭当前功能");

		int entRef;
		int count = g_aRescueVehicle.Length;
		for (int i; i < count; i++) {
			if (EntRefToEntIndex((entRef = g_aRescueVehicle.Get(i))) != INVALID_ENT_REFERENCE) {
				UnhookSingleEntityOutput(entRef, "OnStartTouch",  OnStartTouch);
				UnhookSingleEntityOutput(entRef, "OnEndTouch", OnEndTouch);
			}
		}
	}
}

Action cmdWarpEnd(int client, int args) {
	if (!g_aEndNavArea.Length) {
		ReplyToCommand(client, "No endpoint nav area found");
		return Plugin_Handled;
	}

	Perform(1);
	return Plugin_Handled;
}

Action cmdSt(int client, int args) {
	ReplyToCommand(client, "ChangeLevel->%d RescueAreaTrigger->%d EndNavArea->%d", g_iChangelevel ? EntRefToEntIndex(g_iChangelevel) : -1, SDKCall(g_hSDK_CDirectorChallengeMode_FindRescueAreaTrigger), g_aEndNavArea.Length);
	return Plugin_Handled;
}

public void OnConfigsExecuted() {
	IsAllowed();
}

void CvarChanged_Allow(ConVar convar, const char[] oldValue, const char[] newValue) {
	IsAllowed();
}

void CvarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	GetCvars();
}

void GetCvars() {
	int last = g_iSafeAreaFlags;
	g_iSafeAreaFlags = g_hSafeAreaFlags.IntValue;
	g_iSafeAreaType = g_hSafeAreaType.IntValue;
	g_iSafeAreaTime = g_hSafeAreaTime.IntValue;
	g_iMinSurvivorPercent = g_hMinSurvivorPercent.IntValue;

	if (last != g_iSafeAreaFlags) {
		if (IsValidEntRef(g_iChangelevel)) {
			UnhookSingleEntityOutput(g_iChangelevel, "OnStartTouch",  OnStartTouch);
			UnhookSingleEntityOutput(g_iChangelevel, "OnEndTouch", OnEndTouch);
		}

		int i;
		int entRef;
		int count = g_aRescueVehicle.Length;
		for (; i < count; i++) {
			if ((entRef = g_aRescueVehicle.Get(i)) != g_iRescueVehicle && EntRefToEntIndex(entRef) != INVALID_ENT_REFERENCE) {
				UnhookSingleEntityOutput(entRef, "OnStartTouch",  OnStartTouch);
				UnhookSingleEntityOutput(entRef, "OnEndTouch", OnEndTouch);
			}
		}

		CreateTimer(6.5, tmrInitPlugin, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

// credit to Silvers
void IsAllowed() {
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if (g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true) {
		g_bCvarAllow = true;

		CreateTimer(6.5, tmrInitPlugin, _, TIMER_FLAG_NO_MAPCHANGE);

		HookEvent("round_end", 				Event_RoundEnd, 			EventHookMode_PostNoCopy);
		HookEvent("map_transition", 		Event_RoundEnd, 			EventHookMode_PostNoCopy);
		HookEvent("finale_vehicle_leaving", Event_RoundEnd, 			EventHookMode_PostNoCopy);
		HookEvent("round_start_post_nav", 	Event_RoundStartPostNav,	EventHookMode_PostNoCopy);
		HookEvent("finale_vehicle_ready",	Event_FinaleVehicleReady, 	EventHookMode_PostNoCopy);
	}
	else if (g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false)) {
		g_bCvarAllow = false;

		UnhookEvent("round_end", 				Event_RoundEnd, 			EventHookMode_PostNoCopy);
		UnhookEvent("map_transition", 			Event_RoundEnd, 			EventHookMode_PostNoCopy);
		UnhookEvent("finale_vehicle_leaving",	Event_RoundEnd, 			EventHookMode_PostNoCopy);
		UnhookEvent("round_start_post_nav", 	Event_RoundStartPostNav,	EventHookMode_PostNoCopy);
		UnhookEvent("finale_vehicle_ready",		Event_FinaleVehicleReady, 	EventHookMode_PostNoCopy);

		ResetPlugin();
		delete g_hTimer;

		if (IsValidEntRef(g_iChangelevel)) {
			UnhookSingleEntityOutput(g_iChangelevel, "OnStartTouch",  OnStartTouch);
			UnhookSingleEntityOutput(g_iChangelevel, "OnEndTouch", OnEndTouch);
		}

		int i;
		int entRef;
		int count = g_aRescueVehicle.Length;
		for (; i < count; i++) {
			if ((entRef = g_aRescueVehicle.Get(i)) != g_iRescueVehicle && EntRefToEntIndex(entRef) != INVALID_ENT_REFERENCE) {
				UnhookSingleEntityOutput(entRef, "OnStartTouch",  OnStartTouch);
				UnhookSingleEntityOutput(entRef, "OnEndTouch", OnEndTouch);
			}
		}
	}
}

int g_iCurrentMode;
public void L4D_OnGameModeChange(int gamemode) {
	g_iCurrentMode = gamemode;
}

bool IsAllowedGameMode() {
	if (!g_hCvarMPGameMode)
		return false;

	if (!g_iCurrentMode)
		g_iCurrentMode = L4D_GetGameModeType();

	if (!g_bMapStarted)
		return false;

	int iCvarModesTog = g_hCvarModesTog.IntValue;
	if (iCvarModesTog && !(iCvarModesTog & g_iCurrentMode))
		return false;

	char sGameModes[64], sGameMode[64];
	g_hCvarMPGameMode.GetString(sGameMode, sizeof sGameMode);
	Format(sGameMode, sizeof sGameMode, ",%s,", sGameMode);

	g_hCvarModes.GetString(sGameModes, sizeof sGameModes);
	if (sGameModes[0]) {
		Format(sGameModes, sizeof sGameModes, ",%s,", sGameModes);
		if (StrContains(sGameModes, sGameMode, false) == -1)
			return false;
	}

	g_hCvarModesOff.GetString(sGameModes, sizeof sGameModes);
	if (sGameModes[0]) {
		Format(sGameModes, sizeof sGameModes, ",%s,", sGameModes);
		if (StrContains(sGameModes, sGameMode, false) != -1)
			return false;
	}

	return true;
}

public void OnMapStart() {
	g_bMapStarted = true;
	PrecacheSound(SOUND_COUNTDOWN);
	g_bIsFinalMap = L4D_IsMissionFinalMap();
}

public void OnMapEnd() {
	ResetPlugin();
	delete g_hTimer;
	g_iTheCount = 0;
	g_aEndNavArea.Clear();
	g_bMapStarted = false;
}

void ResetPlugin() {
	g_bIsTriggered = false;
	g_bIsSacrificeFinale = false;
	g_bFinaleVehicleReady = false;
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) {
	if (strcmp(name, "round_end") == 0)
		ResetPlugin();

	delete g_hTimer;
}

void Event_RoundStartPostNav(Event event, const char[] name, bool dontBroadcast) {
	CreateTimer(6.5, tmrInitPlugin, _, TIMER_FLAG_NO_MAPCHANGE);
}

void Event_FinaleVehicleReady(Event event, const char[] name, bool dontBroadcast) {
	g_bFinaleVehicleReady = true;
}

Action tmrInitPlugin(Handle timer) {
	InitPlugin();
	return Plugin_Continue;
}

void InitPlugin() {
	if (!g_bIsFinalMap)
		g_bFinaleVehicleReady = true;

	if (GetNavAreaCount() && FindEndNavAreas()) {
		HookEndAreaEntity();
		FindSafeRoomDoors();
	}
}

bool FindEndNavAreas() {
	if (g_aEndNavArea.Length)
		return true;

	if (g_bIsFinalMap) {
		if (g_iSafeAreaFlags & RESCUE_VEHICLE == 0)
			return false;
	}
	else {
		if (g_iSafeAreaFlags & SAFE_ROOM == 0)
			return false;
	}

	int spawnAttributes;
	TerrorNavArea area;

	Address pLastCheckpoint;
	if (!g_bIsFinalMap)
		pLastCheckpoint = SDKCall(g_hSDK_TerrorNavMesh_GetLastCheckpoint, L4D_GetPointer(POINTER_NAVMESH));

	Address pTheNavAreas = view_as<Address>(LoadFromAddress(g_pTheCount + view_as<Address>(4), NumberType_Int32));
	if (!pTheNavAreas)
		SetFailState("Failed to find address: TheNavAreas");

	for (int i; i < g_iTheCount; i++) {
		if ((area = view_as<TerrorNavArea>(LoadFromAddress(pTheNavAreas + view_as<Address>(i * 4), NumberType_Int32))).IsNull())
			continue;

		if (area.m_flow == -9999.0)
			continue;
	
		if (area.m_attributeFlags & NAV_BASE_OUTSIDE_WORLD)
			continue;

		spawnAttributes = area.m_spawnAttributes;
		if (g_bIsFinalMap) {
			if (spawnAttributes & NAV_SPAWN_RESCUE_VEHICLE)
				g_aEndNavArea.Push(area);
		}
		else {
			if (spawnAttributes & NAV_SPAWN_CHECKPOINT == 0 || spawnAttributes & NAV_SPAWN_DESTROYED_DOOR)
				continue;
			
			if (SDKCall(g_hSDK_Checkpoint_ContainsArea, pLastCheckpoint, area))
				g_aEndNavArea.Push(area);
		}
	}

	return g_aEndNavArea.Length > 0;
}

void HookEndAreaEntity() {
	g_iChangelevel = 0;
	g_iTriggerFinale = 0;
	g_iRescueVehicle = 0;

	g_aRescueVehicle.Clear();

	g_vMins = NULL_VECTOR;
	g_vMaxs = NULL_VECTOR;
	g_vOrigin = NULL_VECTOR;

	if (!g_iSafeAreaFlags)
		return;

	int entity = INVALID_ENT_REFERENCE;
	if ((entity = FindEntityByClassname(MaxClients + 1, "info_changelevel")) == INVALID_ENT_REFERENCE)
		entity = FindEntityByClassname(MaxClients + 1, "trigger_changelevel");

	if (entity != INVALID_ENT_REFERENCE) {
		if (g_iSafeAreaFlags & SAFE_ROOM) {
			GetBrushEntityVector((g_iChangelevel = EntIndexToEntRef(entity)));
			HookSingleEntityOutput(entity, "OnStartTouch", OnStartTouch);
			HookSingleEntityOutput(entity, "OnEndTouch", OnEndTouch);
		}
	}
	else if (g_iSafeAreaFlags & RESCUE_VEHICLE) {
		entity = FindEntityByClassname(MaxClients + 1, "trigger_finale");
		if (entity != INVALID_ENT_REFERENCE) {
			g_iTriggerFinale = EntIndexToEntRef(entity);
			g_bIsSacrificeFinale = !!GetEntProp(g_iTriggerFinale, Prop_Data, "m_bIsSacrificeFinale");
		}

		if (g_bIsSacrificeFinale) {
			if (g_bTranslation)
				PrintToChatAll("\x05%t", "IsSacrificeFinale");
			else
				PrintToChatAll("\x05该地图是牺牲结局, 已关闭当前功能");
		}
		else {
			entity = MaxClients + 1;
			while ((entity = FindEntityByClassname(entity, "trigger_multiple")) != INVALID_ENT_REFERENCE) {
				if (GetEntProp(entity, Prop_Data, "m_iEntireTeam") != 2)
					continue;

				g_aRescueVehicle.Push(EntIndexToEntRef(entity));
				HookSingleEntityOutput(entity, "OnStartTouch",  OnStartTouch);
				HookSingleEntityOutput(entity, "OnEndTouch", OnEndTouch);
			}

			if (g_aRescueVehicle.Length == 1)
				GetBrushEntityVector((g_iRescueVehicle = g_aRescueVehicle.Get(0)));
		}
	}
}

void GetBrushEntityVector(int entity) {
	GetEntPropVector(entity, Prop_Send, "m_vecMins", g_vMins);
	GetEntPropVector(entity, Prop_Send, "m_vecMaxs", g_vMaxs);
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", g_vOrigin);
}

// https://forums.alliedmods.net/showpost.php?p=2680639&postcount=3
void CalculateBoundingBoxSize(float vMins[3], float vMaxs[3], const float vOrigin[3]) {
	AddVectors(vOrigin, vMins, vMins);
	AddVectors(vOrigin, vMaxs, vMaxs);
}

void FindSafeRoomDoors() {
	g_LastDoor.entRef = 0;
	g_LastDoor.m_flSpeed = 0.0;

	if (g_bIsFinalMap || g_iSafeAreaFlags & SAFE_ROOM == 0)
		return;

	if (!IsValidEntRef(g_iChangelevel))
		return;

	int ent = L4D_GetCheckpointLast();
	if (ent != -1) {
		g_LastDoor.entRef = EntIndexToEntRef(ent);
		g_LastDoor.m_flSpeed = GetEntPropFloat(ent, Prop_Data, "m_flSpeed");
	}
}

void  OnStartTouch(const char[] output, int caller, int activator, float delay) {
	if (g_bIsTriggered || g_bIsSacrificeFinale || !g_bFinaleVehicleReady || !g_iSafeAreaTime || activator < 1 || activator > MaxClients || !IsClientInGame(activator) || GetClientTeam(activator) != 2 || !IsPlayerAlive(activator))
		return;
	
	static int value;
	if (!g_iChangelevel && !g_iRescueVehicle) {
		if (caller != SDKCall(g_hSDK_CDirectorChallengeMode_FindRescueAreaTrigger))
			return;

		GetBrushEntityVector((g_iRescueVehicle = EntIndexToEntRef(caller)));

		value = 0;
		int entRef;
		int count = g_aRescueVehicle.Length;
		for (; value < count; value++) {
			if ((entRef = g_aRescueVehicle.Get(value)) != g_iRescueVehicle && EntRefToEntIndex(entRef) != INVALID_ENT_REFERENCE) {
				UnhookSingleEntityOutput(entRef, "OnStartTouch",  OnStartTouch);
				UnhookSingleEntityOutput(entRef, "OnEndTouch", OnEndTouch);
			}
		}

		float vMins[3];
		float vMaxs[3];
		float vOrigin[3];
		vMins = g_vMins;
		vMaxs = g_vMaxs;
		vOrigin = g_vOrigin;

		vMins[0] -= 33.0;
		vMins[1] -= 33.0;
		vMins[2] -= 33.0;
		vMaxs[0] += 33.0;
		vMaxs[1] += 33.0;
		vMaxs[2] += 33.0;
		CalculateBoundingBoxSize(vMins, vMaxs, vOrigin);

		value = 0;
		count = g_aEndNavArea.Length;
		while (value < count) {
			view_as<TerrorNavArea>(g_aEndNavArea.Get(value)).Center(vOrigin);
			if (!IsPosInArea(vOrigin, vMins, vMaxs)) {
				g_aEndNavArea.Erase(value);
				count--;
			}
			else
				value++;
		}
	}

	if (!g_aEndNavArea.Length) {
		g_bIsTriggered = true;
		return;
	}

	value = 0;
	int reached;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i)) {
			value++;
			if (IsPlayerInEndArea(i, false))
				reached++;
		}	
	}

	value = RoundToCeil(g_iMinSurvivorPercent / 100.0 * value);
	if (reached < value) {
		if (reached) {
			if (g_bTranslation)
				PrintHintToSurvivor("%t", "SurvivorReached", reached, value);
			else
				PrintHintToSurvivor("%d名生还者已到达终点区域(需要%d名)", reached, value);
		}
		return;
	}

	g_bIsTriggered = true;
	g_iCountdown = g_iSafeAreaTime;

	delete g_hTimer;
	g_hTimer = CreateTimer(1.0, tmrCountdown, _, TIMER_REPEAT);
}

void OnEndTouch(const char[] output, int caller, int activator, float delay) {
	if (g_bIsTriggered || g_bIsSacrificeFinale || !g_bFinaleVehicleReady || !g_iSafeAreaTime || activator < 1 || activator > MaxClients || !IsClientInGame(activator) || GetClientTeam(activator) != 2)
		return;
	
	static int value;
	if (!g_iChangelevel && !g_iRescueVehicle) {
		if (caller != SDKCall(g_hSDK_CDirectorChallengeMode_FindRescueAreaTrigger))
			return;

		GetBrushEntityVector((g_iRescueVehicle = EntIndexToEntRef(caller)));

		value = 0;
		int entRef;
		int count = g_aRescueVehicle.Length;
		for (; value < count; value++) {
			if ((entRef = g_aRescueVehicle.Get(value)) != g_iRescueVehicle && EntRefToEntIndex(entRef) != INVALID_ENT_REFERENCE) {
				UnhookSingleEntityOutput(entRef, "OnStartTouch",  OnStartTouch);
				UnhookSingleEntityOutput(entRef, "OnEndTouch", OnEndTouch);
			}
		}

		float vMins[3];
		float vMaxs[3];
		float vOrigin[3];
		vMins = g_vMins;
		vMaxs = g_vMaxs;
		vOrigin = g_vOrigin;

		vMins[0] -= 33.0;
		vMins[1] -= 33.0;
		vMins[2] -= 33.0;
		vMaxs[0] += 33.0;
		vMaxs[1] += 33.0;
		vMaxs[2] += 33.0;
		CalculateBoundingBoxSize(vMins, vMaxs, vOrigin);

		
		value = 0;
		count = g_aEndNavArea.Length;
		while (value < count) {
			view_as<TerrorNavArea>(g_aEndNavArea.Get(value)).Center(vOrigin);
			if (!IsPosInArea(vOrigin, vMins, vMaxs)) {
				g_aEndNavArea.Erase(value);
				count--;
			}
			else
				value++;
		}
	}

	if (!g_aEndNavArea.Length) {
		g_bIsTriggered = true;
		return;
	}

	value = 0;
	int reached;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i)) {
			value++;
			if (IsPlayerInEndArea(i, false))
				reached++;
		}	
	}

	value = RoundToCeil(g_iMinSurvivorPercent / 100.0 * value);
	if (reached < value) {
		if (reached) {
			if (g_bTranslation)
				PrintHintToSurvivor("%t", "SurvivorReached", reached, value);
			else
				PrintHintToSurvivor("%d名生还者已到达终点区域(需要%d名)", reached, value);
		}
		return;
	}

	g_bIsTriggered = true;
	g_iCountdown = g_iSafeAreaTime;

	delete g_hTimer;
	g_hTimer = CreateTimer(1.0, tmrCountdown, _, TIMER_REPEAT);
}

Action tmrCountdown(Handle timer) {
	if (g_iCountdown > 0) {
		if (g_bTranslation) {
			switch (g_iSafeAreaType) {
				case 1:
					PrintHintToSurvivor("%t", "Countdown_Send", g_iCountdown--);

				case 2:
					PrintHintToSurvivor("%t", "Countdown_Slay", g_iCountdown--);
			}
		}
		else
			PrintHintToSurvivor("%d 秒后%s未进入终点区域的生还者", g_iCountdown--, g_iSafeAreaType == 1 ? "传送" : "处死");

		EmitSoundToSurvivor(SOUND_COUNTDOWN, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	}
	else if (g_iCountdown <= 0) {
		Perform(g_iSafeAreaType);
		g_hTimer = null;
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

void PrintHintToSurvivor(const char[] format, any ...) {
	static char buffer[254];
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2) {
			SetGlobalTransTarget(i);
			VFormat(buffer, sizeof buffer, format, 2);
			PrintHintText(i, "%s", buffer);
		}
	}
}

void Perform(int type) {
	switch (type) {
		case 1: {
			if (!g_bIsFinalMap)
				CloseAndLockLastSafeDoor();

			CreateTimer(0.5, tmrTeleportToEndArea, _, TIMER_FLAG_NO_MAPCHANGE);
		}
		
		case 2: {
			for (int i = 1; i <= MaxClients; i++) {
				if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && !IsPlayerInEndArea(i, false))
					ForcePlayerSuicide(i);
			}
		}
	}
}

void CloseAndLockLastSafeDoor() {
	int entRef = g_LastDoor.entRef;
	if (EntRefToEntIndex(entRef) != INVALID_ENT_REFERENCE) {
		char buffer[64];
		SetEntPropFloat(entRef, Prop_Data, "m_flSpeed", 1000.0);
		SetEntProp(entRef, Prop_Data, "m_hasUnlockSequence", 0);
		AcceptEntityInput(entRef, "DisableCollision");
		AcceptEntityInput(entRef, "Unlock");
		AcceptEntityInput(entRef, "Close");
		AcceptEntityInput(entRef, "forceclosed");
		AcceptEntityInput(entRef, "Lock");
		SetEntProp(entRef, Prop_Data, "m_hasUnlockSequence", 1);

		SetVariantString("OnUser1 !self:EnableCollision::1.0:-1");
		AcceptEntityInput(entRef, "AddOutput");
		SetVariantString("OnUser1 !self:Unlock::5.0:-1");
		AcceptEntityInput(entRef, "AddOutput");
		FloatToString(g_LastDoor.m_flSpeed, buffer, sizeof buffer);
		Format(buffer, sizeof buffer, "OnUser1 !self:SetSpeed:%s:5.0:-1", buffer);
		SetVariantString(buffer);
		AcceptEntityInput(entRef, "AddOutput");
		AcceptEntityInput(entRef, "FireUser1");
	}
}

Action tmrTeleportToEndArea(Handle timer) {
	TeleportToEndArea();
	return Plugin_Continue;
}

void TeleportToEndArea() {
	int count = g_aEndNavArea.Length;
	if (count > 0) {
		RemoveInfecteds();

		int i = 1;
		for (; i <= MaxClients; i++) {
			if (IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i)) {
				SDKCall(g_hSDK_CTerrorPlayer_CleanupPlayerState, i);
				ForcePlayerSuicide(i);
			}
		}

		float vPos[3];
		TerrorNavArea largest;

		if (!g_bIsFinalMap)
			largest = SDKCall(g_hSDK_Checkpoint_GetLargestArea, SDKCall(g_hSDK_TerrorNavMesh_GetLastCheckpoint, L4D_GetPointer(POINTER_NAVMESH)));

		if (largest) {
			for (i = 1; i <= MaxClients; i++) {
				if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && !IsPlayerInEndArea(i)) {
					TeleportFix(i);

					largest.FindRandomSpot(vPos);
					TeleportEntity(i, vPos, NULL_VECTOR, NULL_VECTOR);
				}
			}
		}
		else {
			for (i = 1; i <= MaxClients; i++) {
				if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && !IsPlayerInEndArea(i)) {
					TeleportFix(i);

					view_as<TerrorNavArea>(g_aEndNavArea.Get(GetRandomInt(0, count - 1))).FindRandomSpot(vPos);
					TeleportEntity(i, vPos, NULL_VECTOR, NULL_VECTOR);
				}
			}
		}
	}
}

void TeleportFix(int client) {
	if (GetEntProp(client, Prop_Send, "m_isHangingFromLedge"))
		L4D_ReviveSurvivor(client);

	SetEntityMoveType(client, MOVETYPE_WALK);
	SetEntProp(client, Prop_Send, "m_fFlags", GetEntProp(client, Prop_Send, "m_fFlags") & ~FL_FROZEN);

	SetEntProp(client, Prop_Send, "m_bDucked", 1);
	SetEntProp(client, Prop_Send, "m_fFlags", GetEntProp(client, Prop_Send, "m_fFlags") | FL_DUCKING);
}

void RemoveInfecteds() {
	float vMins[3];
	float vMaxs[3];
	float vOrigin[3];
	vMins = g_vMins;
	vMaxs = g_vMaxs;
	vOrigin = g_vOrigin;

	vMins[0] -= 33.0;
	vMins[1] -= 33.0;
	vMins[2] -= 33.0;
	vMaxs[0] += 33.0;
	vMaxs[1] += 33.0;
	vMaxs[2] += 33.0;
	CalculateBoundingBoxSize(vMins, vMaxs, vOrigin);

	char classname[9];
	int maxEnts = GetMaxEntities();
	for (int i = MaxClients + 1; i <= maxEnts; i++) {
		if (!IsValidEntity(i))
			continue;

		GetEntityClassname(i, classname, sizeof classname);
		if (strcmp(classname, "infected") != 0 && strcmp(classname, "witch") != 0)
			continue;
	
		GetEntPropVector(i, Prop_Send, "m_vecOrigin", vOrigin);
		if (!IsPosInArea(vOrigin, vMins, vMaxs))
			continue;

		RemoveEntity(i);
	}
}

bool IsPosInArea(const float vPos[3], const float vMins[3], const float vMaxs[3]) {
	return vMins[0] <= vPos[0] <= vMaxs[0] && vMins[1] <= vPos[1] <= vMaxs[1] && vMins[2] <= vPos[2] <= vMaxs[2];
}

bool IsValidEntRef(int entity) {
	return entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE;
}

void EmitSoundToSurvivor(const char[] sample,
				 int entity = SOUND_FROM_PLAYER,
				 int channel = SNDCHAN_AUTO,
				 int level = SNDLEVEL_NORMAL,
				 int flags = SND_NOFLAGS,
				 float volume = SNDVOL_NORMAL,
				 int pitch = SNDPITCH_NORMAL,
				 int speakerentity = -1,
				 const float origin[3] = NULL_VECTOR,
				 const float dir[3] = NULL_VECTOR,
				 bool updatePos = true,
				 float soundtime = 0.0)
{
	int[] clients = new int[MaxClients];
	int total;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2)
			clients[total++] = i;
	}

	if (total) {
		EmitSound(clients, total, sample, entity, channel,
			level, flags, volume, pitch, speakerentity,
			origin, dir, updatePos, soundtime);
	}
}

void InitData() {
	char buffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, buffer, PLATFORM_MAX_PATH, "translations/safearea_teleport.phrases.txt");
	if (FileExists(buffer)) {
		LoadTranslations("safearea_teleport.phrases");
		g_bTranslation = true;
	}

	BuildPath(Path_SM, buffer, sizeof buffer, "gamedata/%s.txt", GAMEDATA);
	if (!FileExists(buffer))
		SetFailState("\n==========\nMissing required file: \"%s\".\n==========", buffer);

	GameData hGameData = new GameData(GAMEDATA);
	if (!hGameData)
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	g_pTheCount = hGameData.GetAddress("TheCount");
	if (!g_pTheCount)
		SetFailState("Failed to find address: TheCount");

	g_iOff_m_flow = hGameData.GetOffset("m_flow");
	if (g_iOff_m_flow == -1)
		SetFailState("Failed to find offset: m_flow");

	StartPrepSDKCall(SDKCall_Player);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::CleanupPlayerState"))
		SetFailState("Failed to find signature: CTerrorPlayer::CleanupPlayerState");
	if (!(g_hSDK_CTerrorPlayer_CleanupPlayerState = EndPrepSDKCall()))
		SetFailState("Failed to create SDKCall: CTerrorPlayer::CleanupPlayerState");

	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "TerrorNavMesh::GetLastCheckpoint"))
		SetFailState("Failed to find signature: TerrorNavMesh::GetLastCheckpoint");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	if (!(g_hSDK_TerrorNavMesh_GetLastCheckpoint = EndPrepSDKCall()))
		SetFailState("Failed to create SDKCall: TerrorNavMesh::GetLastCheckpoint");

	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "Checkpoint::ContainsArea"))
		SetFailState("Failed to find signature: Checkpoint::ContainsArea");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	if (!(g_hSDK_Checkpoint_ContainsArea = EndPrepSDKCall()))
		SetFailState("Failed to create SDKCall: Checkpoint::ContainsArea");

	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "Checkpoint::GetLargestArea"))
		SetFailState("Failed to find signature: Checkpoint::GetLargestArea");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	if (!(g_hSDK_Checkpoint_GetLargestArea = EndPrepSDKCall()))
		SetFailState("Failed to create SDKCall: Checkpoint::GetLargestArea");

	StartPrepSDKCall(SDKCall_GameRules);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirectorChallengeMode::FindRescueAreaTrigger"))
		SetFailState("Failed to find signature: CDirectorChallengeMode::FindRescueAreaTrigger");
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	if (!(g_hSDK_CDirectorChallengeMode_FindRescueAreaTrigger = EndPrepSDKCall()))
		SetFailState("Failed to create SDKCall: CDirectorChallengeMode::FindRescueAreaTrigger");

	StartPrepSDKCall(SDKCall_Entity);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CBaseTrigger::IsTouching"))
		SetFailState("Failed to find signature: CBaseTrigger::IsTouching");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	if (!(g_hSDK_CBaseTrigger_IsTouching = EndPrepSDKCall()))
		SetFailState("Failed to create SDKCall: CBaseTrigger::IsTouching");

	delete hGameData;
}

bool GetNavAreaCount() {
	if (g_iTheCount)
		return true;

	g_iTheCount = LoadFromAddress(g_pTheCount, NumberType_Int32);
	if (!g_iTheCount) {
		#if DEBUG
		PrintToServer("The current number of Nav areas is 0, which may be some test maps");
		#endif

		return false;
	}

	return true;
}

bool IsPlayerInEndArea(int client, bool checkArea = true) {
	int area = L4D_GetLastKnownArea(client);
	if (!area)
		return false;

	if (checkArea && g_aEndNavArea.FindValue(area) == -1)
		return false;

	if (g_bIsFinalMap)
		return IsValidEntRef(g_iRescueVehicle) && SDKCall(g_hSDK_CBaseTrigger_IsTouching, g_iRescueVehicle, client);
	
	return IsValidEntRef(g_iChangelevel) && SDKCall(g_hSDK_CBaseTrigger_IsTouching, g_iChangelevel, client);
}