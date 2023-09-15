#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <dhooks>
#undef REQUIRE_PLUGIN
#include <l4d2_hittable_control>

#define Z_TANK			8
#define TEAM_INFECTED	3
#define TEAM_SPECTATOR	1

#define MAX_EDICTS		2048 //(1 << 11)

ConVar
	g_hTankPropFade = null,
	g_hCvartankPropsGlow = null,
	g_hCvarRange = null,
	g_hCvarRangeMin = null,
	g_hCvarColor = null,
	g_hCvarTankOnly = null,
	g_hCvarTankSpec = null,
	g_hCvarTankPropsBeGone = null;

ArrayList
	g_hTankProps = null,
	g_hTankPropsHit = null;

int
	g_iEntityList[MAX_EDICTS] = {-1, ...},
	g_iTankClient = -1,
	g_iCvarRange = 0,
	g_iCvarRangeMin = 0,
	g_iCvarColor = 0;

bool
	g_bCvarTankOnly = false,
	g_bCvarTankSpec = false,
	g_bTankSpawned = false,
	g_bHittableControlExists = false;

public Plugin myinfo =
{
	name = "L4D2 Tank Hittable Glow",
	author = "Harry Potter, Sir, A1m`, Derpduck",
	version = "2.5",
	description = "Stop tank props from fading whilst the tank is alive + add Hittable Glow."
};

public void OnPluginStart()
{
	g_hCvartankPropsGlow = CreateConVar("l4d_tank_props_glow", "1", "Show Hittable Glow for infected team while the tank is alive", FCVAR_NOTIFY);
	g_hCvarColor = CreateConVar("l4d2_tank_prop_glow_color", "255 255 255", "Prop Glow Color, three values between 0-255 separated by spaces. RGB Color255 - Red Green Blue.", FCVAR_NOTIFY);
	g_hCvarRange = CreateConVar("l4d2_tank_prop_glow_range", "4500", "How near to props do players need to be to enable their glow.", FCVAR_NOTIFY);
	g_hCvarRangeMin = CreateConVar("l4d2_tank_prop_glow_range_min", "256", "How near to props do players need to be to disable their glow.", FCVAR_NOTIFY);
	g_hCvarTankOnly = CreateConVar("l4d2_tank_prop_glow_only", "0", "Only Tank can see the glow", FCVAR_NOTIFY);
	g_hCvarTankSpec = CreateConVar("l4d2_tank_prop_glow_spectators", "1", "Spectators can see the glow too", FCVAR_NOTIFY);
	g_hCvarTankPropsBeGone = CreateConVar("l4d2_tank_prop_dissapear_time", "10.0", "Time it takes for hittables that were punched by Tank to dissapear after the Tank dies.", FCVAR_NOTIFY);

	GetCvars();

	g_hTankPropFade = FindConVar("sv_tankpropfade");
	g_hCvartankPropsGlow.AddChangeHook(TankPropsGlowAllow);
	g_hCvarColor.AddChangeHook(ConVarChanged_Glow);
	g_hCvarRange.AddChangeHook(ConVarChanged_Range);
	g_hCvarRangeMin.AddChangeHook(ConVarChanged_RangeMin);
	g_hCvarTankOnly.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTankSpec.AddChangeHook(ConVarChanged_Cvars);

	PluginEnable();
}

public void OnAllPluginsLoaded()
{
	g_bHittableControlExists = LibraryExists("l4d2_hittable_control");
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "l4d2_hittable_control", true)) {
		g_bHittableControlExists = false;
	}
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "l4d2_hittable_control", true)) {
		g_bHittableControlExists = true;
	}
}

public void ConVarChanged_Cvars(ConVar hConvar, const char[] sOldValue, const char[] sNewValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bCvarTankOnly = g_hCvarTankOnly.BoolValue;
	g_bCvarTankSpec = g_hCvarTankSpec.BoolValue;
	g_iCvarRange = g_hCvarRange.IntValue;
	g_iCvarRangeMin = g_hCvarRangeMin.IntValue;

	char sColor[16];
	g_hCvarColor.GetString(sColor, sizeof(sColor));
	g_iCvarColor = GetColor(sColor);
}

public void TankPropsGlowAllow(Handle hConVar, const char[] sOldValue, const char[] sNewValue)
{
	if (!g_hCvartankPropsGlow.BoolValue) {
		PluginDisable();
	} else {
		PluginEnable();
	}
}

public void ConVarChanged_Glow(Handle hConVar, const char[] sOldValue, const char[] sNewValue)
{
	GetCvars();

	if (!g_bTankSpawned) {
		return;
	}

	int iRef = INVALID_ENT_REFERENCE, iValue = 0, iSize = g_hTankPropsHit.Length;
	for (int i = 0; i < iSize; i++) {
		iValue = g_hTankPropsHit.Get(i);

		if (iValue > 0 && IsValidEdict(iValue)) {
			iRef = g_iEntityList[iValue];

			if (IsValidEntRef(iRef)) {
				SetEntProp(iRef, Prop_Send, "m_iGlowType", 3);
				SetEntProp(iRef, Prop_Send, "m_glowColorOverride", g_iCvarColor);
			}
		}
	}
}

public void ConVarChanged_Range(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	GetCvars();

	if (!g_bTankSpawned) {
		return;
	}

	int iRef = INVALID_ENT_REFERENCE, iValue = -1, iSize = g_hTankPropsHit.Length;
	for (int i = 0; i < iSize; i++) {
		iValue = g_hTankPropsHit.Get(i);

		if (iValue > 0 && IsValidEdict(iValue)) {
			iRef = g_iEntityList[iValue];

			if (IsValidEntRef(iRef)) {
				SetEntProp(iRef, Prop_Send, "m_nGlowRange", g_iCvarRange);
			}
		}
	}
}

public void ConVarChanged_RangeMin(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	GetCvars();

	if (!g_bTankSpawned) {
		return;
	}

	int iRef = INVALID_ENT_REFERENCE, iValue = -1, iSize = g_hTankPropsHit.Length;
	for (int i = 0; i < iSize; i++) {
		iValue = g_hTankPropsHit.Get(i);

		if (iValue > 0 && IsValidEdict(iValue)) {
			iRef = g_iEntityList[iValue];

			if (IsValidEntRef(iRef)) {
				SetEntProp(iRef, Prop_Send, "m_nGlowRangeMin", g_iCvarRangeMin);
			}
		}
	}
}

void PluginEnable()
{
	g_hTankPropFade.SetBool(false);

	g_hTankProps = new ArrayList();
	g_hTankPropsHit = new ArrayList();

	HookEvent("round_start", TankPropRoundReset, EventHookMode_PostNoCopy);
	HookEvent("round_end", TankPropRoundReset, EventHookMode_PostNoCopy);
	HookEvent("tank_spawn", TankPropTankSpawn, EventHookMode_PostNoCopy);
	HookEvent("player_death", TankPropTankKilled, EventHookMode_PostNoCopy);

	char sColor[16];
	g_hCvarColor.GetString(sColor, sizeof(sColor));
	g_iCvarColor = GetColor(sColor);
	g_iCvarRange = g_hCvarRange.IntValue;
	g_iCvarRangeMin = g_hCvarRangeMin.IntValue;
	g_bCvarTankOnly = g_hCvarTankOnly.BoolValue;
}

void PluginDisable()
{
	g_hTankPropFade.SetBool(true);

	UnhookEvent("round_start", TankPropRoundReset, EventHookMode_PostNoCopy);
	UnhookEvent("round_end", TankPropRoundReset, EventHookMode_PostNoCopy);
	UnhookEvent("tank_spawn", TankPropTankSpawn, EventHookMode_PostNoCopy);
	UnhookEvent("player_death", TankPropTankKilled, EventHookMode_PostNoCopy);

	if (!g_bTankSpawned) {
		return;
	}

	int iRef = INVALID_ENT_REFERENCE, iValue = -1, iSize = g_hTankPropsHit.Length;

	for (int i = 0; i < iSize; i++) {
		iValue = g_hTankPropsHit.Get(i);

		if (iValue > 0 && IsValidEdict(iValue)) {
			iRef = g_iEntityList[iValue];

			if (IsValidEntRef(iRef)) {
				KillEntity(iRef);
			}
		}
	}

	g_bTankSpawned = false;

	delete g_hTankProps;
	g_hTankProps = null;

	delete g_hTankPropsHit;
	g_hTankPropsHit = null;
}

public void OnMapEnd()
{
	DHookRemoveEntityListener(ListenType_Created, PossibleTankPropCreated);

	g_hTankProps.Clear();
	g_hTankPropsHit.Clear();
}

public void TankPropRoundReset(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	DHookRemoveEntityListener(ListenType_Created, PossibleTankPropCreated);

	g_bTankSpawned = false;

	UnhookTankProps();
	g_hTankPropsHit.Clear();
}

public void TankPropTankSpawn(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	if (g_bTankSpawned) {
		return;
	}

	UnhookTankProps();
	g_hTankPropsHit.Clear();

	HookTankProps();

	DHookAddEntityListener(ListenType_Created, PossibleTankPropCreated);

	g_bTankSpawned = true;
}

public void PD_ev_EntityKilled(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	if (!g_bTankSpawned) {
		return;
	}

	int iClient = hEvent.GetInt("entindex_killed");

	if (IsValidAliveTank(iClient)) {
		CreateTimer(1.5, TankDeadCheck, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void TankPropTankKilled(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	if (!g_bTankSpawned) {
		return;
	}

	CreateTimer(0.5, TankDeadCheck, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action TankDeadCheck(Handle hTimer)
{
	if (GetTankClient() == -1) {
		CreateTimer(g_hCvarTankPropsBeGone.FloatValue, TankPropsBeGone);

		DHookRemoveEntityListener(ListenType_Created, PossibleTankPropCreated);

		g_bTankSpawned = false;
	}

	return Plugin_Stop;
}

public Action TankPropsBeGone(Handle hTimer)
{
	UnhookTankProps();

	return Plugin_Stop;
}

public void PropDamaged(int iVictim, int iAttacker, int iInflictor, float fDamage, int iDamageType)
{
	if (IsValidAliveTank(iAttacker) || g_hTankPropsHit.FindValue(iInflictor) != -1) {
		//PrintToChatAll("tank hit %d", iVictim);

		if (g_hTankPropsHit.FindValue(iVictim) == -1) {
			g_hTankPropsHit.Push(iVictim);
			CreateTankPropGlow(iVictim);
		}
	}
}

void CreateTankPropGlow(int iTarget)
{
	// Spawn dynamic prop entity
	int iEntity = CreateEntityByName("prop_dynamic_override");
	if (iEntity == -1) {
		return;
	}

	// Get position of hittable
	float vOrigin[3];
	float vAngles[3];
	GetEntPropVector(iTarget, Prop_Send, "m_vecOrigin", vOrigin);
	GetEntPropVector(iTarget, Prop_Data, "m_angRotation", vAngles);

	// Get Client Model
	char sModelName[PLATFORM_MAX_PATH];
	GetEntPropString(iTarget, Prop_Data, "m_ModelName", sModelName, sizeof(sModelName));

	// Set new fake model
	SetEntityModel(iEntity, sModelName);
	DispatchSpawn(iEntity);

	// Set outline glow color
	SetEntProp(iEntity, Prop_Send, "m_CollisionGroup", 0);
	SetEntProp(iEntity, Prop_Send, "m_nSolidType", 0);
	SetEntProp(iEntity, Prop_Send, "m_nGlowRange", g_iCvarRange);
	SetEntProp(iEntity, Prop_Send, "m_nGlowRangeMin", g_iCvarRangeMin);
	SetEntProp(iEntity, Prop_Send, "m_iGlowType", 2);
	SetEntProp(iEntity, Prop_Send, "m_glowColorOverride", g_iCvarColor);
	AcceptEntityInput(iEntity, "StartGlowing");

	// Set model invisible
	SetEntityRenderMode(iEntity, RENDER_NONE);
	SetEntityRenderColor(iEntity, 0, 0, 0, 0);

	// Set model to hittable position
	TeleportEntity(iEntity, vOrigin, vAngles, NULL_VECTOR);

	// Set model attach to client, and always synchronize
	SetVariantString("!activator");
	AcceptEntityInput(iEntity, "SetParent", iTarget);

	SDKHook(iEntity, SDKHook_SetTransmit, OnTransmit);
	g_iEntityList[iTarget] = EntIndexToEntRef(iEntity);

	// Fix PVS glow issues while inside walls (by Mart)
	SetEdictFlags(iTarget, GetEdictFlags(iTarget) | FL_EDICT_ALWAYS);
}

public Action OnTransmit(int iEntity, int iClient)
{
	switch (GetClientTeam(iClient)) {
		case TEAM_INFECTED: {
			if (!g_bCvarTankOnly) {
				return Plugin_Continue;
			}

			if (IsTank(iClient)) {
				return Plugin_Continue;
			}

			return Plugin_Handled;
		}
		case TEAM_SPECTATOR: {
			return (g_bCvarTankSpec) ? Plugin_Continue : Plugin_Handled;
		}
	}

	return Plugin_Handled;
}

bool IsTankProp(int iEntity)
{
	if (!IsValidEdict(iEntity)) {
		return false;
	}

	// CPhysicsProp only
	if (!HasEntProp(iEntity, Prop_Send, "m_hasTankGlow")) {
		return false;
	}

	bool bHasTankGlow = (GetEntProp(iEntity, Prop_Send, "m_hasTankGlow", 1) == 1);
	if (!bHasTankGlow) {
		return false;
	}

	// Exception
	bool bAreForkliftsUnbreakable;
	if (g_bHittableControlExists)
	{
		bAreForkliftsUnbreakable = AreForkliftsUnbreakable();
	}
	else
	{
		bAreForkliftsUnbreakable = false;
	}

	char sModel[PLATFORM_MAX_PATH];
	GetEntPropString(iEntity, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
	if (strcmp("models/props/cs_assault/forklift.mdl", sModel) == 0 && bAreForkliftsUnbreakable == false) {
		return false;
	}

	return true;
}

void HookTankProps()
{
	int iEntCount = GetMaxEntities();

	for (int i = MaxClients; i < iEntCount; i++) {
		if (IsTankProp(i)) {
			SDKHook(i, SDKHook_OnTakeDamagePost, PropDamaged);
			g_hTankProps.Push(i);
		}
	}
}

void UnhookTankProps()
{
	int iValue = 0, iSize = g_hTankProps.Length;

	for (int i = 0; i < iSize; i++) {
		iValue = g_hTankProps.Get(i);
		SDKUnhook(iValue, SDKHook_OnTakeDamagePost, PropDamaged);
	}

	iValue = 0;
	iSize = g_hTankPropsHit.Length;

	for (int i = 0; i < iSize; i++) {
		iValue = g_hTankPropsHit.Get(i);

		if (iValue > 0 && IsValidEdict(iValue)) {
			KillEntity(iValue);
			//PrintToChatAll("remove %d", iValue);
		}
	}

	g_hTankProps.Clear();
	g_hTankPropsHit.Clear();
}

//analogue public void OnEntityCreated(int iEntity, const char[] sClassName)
public void PossibleTankPropCreated(int iEntity, const char[] sClassName)
{
	if (sClassName[0] != 'p') {
		return;
	}

	if (strcmp(sClassName, "prop_physics") != 0) { // Hooks c11m4_terminal World Sphere
		return;
	}

	// Use SpawnPost to just push it into the Array right away.
	// These entities get spawned after the Tank has punched them, so doing anything here will not work smoothly.
	SDKHook(iEntity, SDKHook_SpawnPost, Hook_PropSpawned);
}

public void Hook_PropSpawned(int iEntity)
{
	if (iEntity < MaxClients || !IsValidEntity(iEntity)) {
		return;
	}

	if (g_hTankProps.FindValue(iEntity) == -1) {
		char sModelName[PLATFORM_MAX_PATH];
		GetEntPropString(iEntity, Prop_Data, "m_ModelName", sModelName, sizeof(sModelName));

		if (StrContains(sModelName, "atlas_break_ball") != -1 || StrContains(sModelName, "forklift_brokenlift.mdl") != -1) {
			g_hTankProps.Push(iEntity);
			g_hTankPropsHit.Push(iEntity);
			CreateTankPropGlow(iEntity);
		} else if (StrContains(sModelName, "forklift_brokenfork.mdl") != -1) {
			KillEntity(iEntity);
		}
	}
}

bool IsValidEntRef(int iRef)
{
	return (iRef > 0 && EntRefToEntIndex(iRef) != INVALID_ENT_REFERENCE);
}

int GetColor(char[] sTemp)
{
	if (strcmp(sTemp, "") == 0) {
		return 0;
	}

	char sColors[3][4];
	int iColor = ExplodeString(sTemp, " ", sColors, 3, 4);

	if (iColor != 3) {
		return 0;
	}

	iColor = StringToInt(sColors[0]);
	iColor += 256 * StringToInt(sColors[1]);
	iColor += 65536 * StringToInt(sColors[2]);

	return iColor;
}

int GetTankClient()
{
	if (g_iTankClient == -1 || !IsValidAliveTank(g_iTankClient)) {
		g_iTankClient = FindTank();
	}

	return g_iTankClient;
}

int FindTank()
{
	for (int i = 1; i <= MaxClients; i++) {
		if (IsAliveTank(i)) {
			return i;
		}
	}

	return -1;
}

bool IsValidAliveTank(int iClient)
{
	return (iClient > 0 && iClient <= MaxClients && IsAliveTank(iClient));
}

bool IsAliveTank(int iClient)
{
	return (IsClientInGame(iClient) && GetClientTeam(iClient) == TEAM_INFECTED && IsTank(iClient));
}

bool IsTank(int iClient)
{
	return (GetEntProp(iClient, Prop_Send, "m_zombieClass") == Z_TANK && IsPlayerAlive(iClient));
}

void KillEntity(int iEntity)
{
#if SOURCEMOD_V_MINOR > 8
	RemoveEntity(iEntity);
#else
	AcceptEntityInput(iEntity, "Kill");
#endif
}
