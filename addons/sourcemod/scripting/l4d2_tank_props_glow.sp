#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <l4d2_hittable_control>

#define ZC_TANK			8
#define TEAM_SPECTATOR	1
#define TEAM_INFECTED	3

#define MAX_EDICTS		2048 //(1 << 11)
#define MODEL_FORKLIFT	"models/props/cs_assault/forklift.mdl"

ConVar
	g_hCvarEnable = null,
	g_hCvarColor = null,
	g_hCvarRange = null,
	g_hCvarRangeMin = null,
	g_hCvarTankOnly = null,
	g_hCvarSpectators = null,
	g_hCvarRemoveTime = null,
	g_hTankPropFade = null;

Handle
	g_hRemoveTimer = null;

int
	g_iGlowRef[MAX_EDICTS], // Glow entity of every hittable the Tank has hit, indexed by the hittable
	g_iColor = 0,
	g_iRange = 0,
	g_iRangeMin = 0;

bool
	g_bEnabled = false,
	g_bTankOnly = false,
	g_bSpectators = false,
	g_bTankAlive = false,
	g_bRecreatePending = false,
	g_bGlowSent[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = "L4D2 Tank Hittable Glow",
	author = "Harry Potter, Sir, A1m`, Derpduck",
	version = "3.0",
	description = "Stop tank props from fading whilst the tank is alive + add Hittable Glow."
};

public void OnPluginStart()
{
	g_hCvarEnable = CreateConVar("l4d_tank_props_glow", "1", "Show Hittable Glow for infected team while the tank is alive", FCVAR_NOTIFY);
	g_hCvarColor = CreateConVar("l4d2_tank_prop_glow_color", "255 255 255", "Prop Glow Color, three values between 0-255 separated by spaces. RGB Color255 - Red Green Blue.", FCVAR_NOTIFY);
	g_hCvarRange = CreateConVar("l4d2_tank_prop_glow_range", "4500", "How near to props do players need to be to enable their glow.", FCVAR_NOTIFY);
	g_hCvarRangeMin = CreateConVar("l4d2_tank_prop_glow_range_min", "256", "How near to props do players need to be to disable their glow.", FCVAR_NOTIFY);
	g_hCvarTankOnly = CreateConVar("l4d2_tank_prop_glow_only", "0", "Only Tank can see the glow", FCVAR_NOTIFY);
	g_hCvarSpectators = CreateConVar("l4d2_tank_prop_glow_spectators", "1", "Spectators can see the glow too", FCVAR_NOTIFY);
	g_hCvarRemoveTime = CreateConVar("l4d2_tank_prop_dissapear_time", "10.0", "Time it takes for hittables that were punched by Tank to dissapear after the Tank dies.", FCVAR_NOTIFY);
	g_hTankPropFade = FindConVar("sv_tankpropfade");

	g_hCvarEnable.AddChangeHook(CvarChanged_Enable);
	g_hCvarColor.AddChangeHook(CvarChanged_Glow);
	g_hCvarRange.AddChangeHook(CvarChanged_Glow);
	g_hCvarRangeMin.AddChangeHook(CvarChanged_Glow);
	g_hCvarTankOnly.AddChangeHook(CvarChanged_Visibility);
	g_hCvarSpectators.AddChangeHook(CvarChanged_Visibility);

	CvarChanged_Enable(g_hCvarEnable, "", "");

	HookEvent("round_start", Event_RoundReset, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundReset, EventHookMode_PostNoCopy);
	HookEvent("tank_spawn", Event_TankSpawn, EventHookMode_PostNoCopy);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_PostNoCopy);
}

void GetCvars()
{
	g_bEnabled = g_hCvarEnable.BoolValue;
	g_bTankOnly = g_hCvarTankOnly.BoolValue;
	g_bSpectators = g_hCvarSpectators.BoolValue;
	g_iRange = g_hCvarRange.IntValue;
	g_iRangeMin = g_hCvarRangeMin.IntValue;

	char sColor[16], sParts[3][4];
	g_hCvarColor.GetString(sColor, sizeof(sColor));
	g_iColor = (ExplodeString(sColor, " ", sParts, sizeof(sParts), sizeof(sParts[])) == 3)
		? StringToInt(sParts[0]) + 256 * StringToInt(sParts[1]) + 65536 * StringToInt(sParts[2])
		: 0;
}

void CvarChanged_Enable(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	GetCvars();
	g_hTankPropFade.SetBool(!g_bEnabled);

	if (!g_bEnabled) {
		g_bTankAlive = false;
		delete g_hRemoveTimer;
		ClearGlows(false);
	}
}

public void OnPluginEnd()
{
	// Without the transmit hook every client would see the glows
	ClearGlows(false);
}

void CvarChanged_Glow(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	GetCvars();

	int iGlow;
	for (int i = MaxClients + 1; i < MAX_EDICTS; i++) {
		if ((iGlow = GetGlow(i)) != -1) {
			SetGlowProps(iGlow);
		}
	}
}

void CvarChanged_Visibility(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	GetCvars();
	CheckStaleGlowClients();
}

public void OnMapEnd()
{
	g_hRemoveTimer = null;
	g_bTankAlive = false;
}

public void OnClientDisconnect(int iClient)
{
	g_bGlowSent[iClient] = false;
}

void Event_RoundReset(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	g_bTankAlive = false;
	RemoveHitProps();
}

void Event_TankSpawn(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	if (g_bTankAlive || !g_bEnabled) {
		return;
	}

	g_bTankAlive = true;
	RemoveHitProps();

	bool bForkliftsUnbreakable = (GetFeatureStatus(FeatureType_Native, "AreForkliftsUnbreakable") == FeatureStatus_Available
		&& AreForkliftsUnbreakable());

	char sModel[PLATFORM_MAX_PATH];
	for (int i = MaxClients + 1, iMax = GetMaxEntities(); i < iMax; i++) {
		// CPhysicsProp only
		if (!IsValidEdict(i) || !HasEntProp(i, Prop_Send, "m_hasTankGlow") || !GetEntProp(i, Prop_Send, "m_hasTankGlow", 1)) {
			continue;
		}

		if (!bForkliftsUnbreakable) {
			GetEntPropString(i, Prop_Data, "m_ModelName", sModel, sizeof(sModel));

			if (strcmp(sModel, MODEL_FORKLIFT) == 0) {
				continue;
			}
		}

		// Hooks are kept until the entity is gone, so never add a second one
		SDKUnhook(i, SDKHook_OnTakeDamagePost, OnPropDamaged);
		SDKHook(i, SDKHook_OnTakeDamagePost, OnPropDamaged);
	}
}

void Event_PlayerDeath(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	if (!g_bTankAlive) {
		return;
	}

	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if (iClient && GetEntProp(iClient, Prop_Send, "m_zombieClass") == ZC_TANK) {
		CreateTimer(0.5, Timer_TankDeadCheck, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

Action Timer_TankDeadCheck(Handle hTimer)
{
	if (g_bTankAlive && !IsTankInPlay()) {
		g_bTankAlive = false;
		g_hRemoveTimer = CreateTimer(g_hCvarRemoveTime.FloatValue, Timer_RemoveHitProps, _, TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Stop;
}

Action Timer_RemoveHitProps(Handle hTimer)
{
	g_hRemoveTimer = null;
	ClearGlows(true);

	return Plugin_Stop;
}

void RemoveHitProps()
{
	delete g_hRemoveTimer;
	ClearGlows(true);
}

void OnPropDamaged(int iVictim, int iAttacker, int iInflictor, float fDamage, int iDamageType)
{
	// Hooks outlive the Tank, so only act while it's alive or until its hittables are removed
	if ((!g_bTankAlive && g_hRemoveTimer == null) || GetGlow(iVictim) != -1) {
		return;
	}

	// Hit by the Tank, or by a hittable the Tank sent flying
	if ((iAttacker > 0 && iAttacker <= MaxClients && IsClientInGame(iAttacker) && GetClientTeam(iAttacker) == TEAM_INFECTED && IsTank(iAttacker))
		|| (iInflictor > MaxClients && iInflictor < MAX_EDICTS && GetGlow(iInflictor) != -1)) {
		CreateGlow(iVictim);
	}
}

public void OnEntityCreated(int iEntity, const char[] sClassName)
{
	// Hooks c11m4_terminal World Sphere
	if (g_bTankAlive && strcmp(sClassName, "prop_physics") == 0) {
		// These entities get spawned after the Tank has punched them, so doing anything here will not work smoothly.
		SDKHook(iEntity, SDKHook_SpawnPost, OnPhysicsPropSpawned);
	}
}

void OnPhysicsPropSpawned(int iEntity)
{
	char sModel[PLATFORM_MAX_PATH];
	GetEntPropString(iEntity, Prop_Data, "m_ModelName", sModel, sizeof(sModel));

	if (StrContains(sModel, "atlas_break_ball") != -1 || StrContains(sModel, "forklift_brokenlift.mdl") != -1) {
		CreateGlow(iEntity);
	} else if (StrContains(sModel, "forklift_brokenfork.mdl") != -1) {
		RemoveEntity(iEntity);
	}
}

void CreateGlow(int iProp)
{
	int iGlow = CreateEntityByName("prop_dynamic_override");
	if (iGlow == -1) {
		return;
	}

	char sModel[PLATFORM_MAX_PATH];
	float vOrigin[3], vAngles[3];
	GetEntPropString(iProp, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
	GetEntPropVector(iProp, Prop_Send, "m_vecOrigin", vOrigin);
	GetEntPropVector(iProp, Prop_Data, "m_angRotation", vAngles);

	// Invisible, non-solid copy of the hittable that only draws the outline
	SetEntityModel(iGlow, sModel);
	DispatchSpawn(iGlow);
	SetEntProp(iGlow, Prop_Send, "m_CollisionGroup", 0);
	SetEntProp(iGlow, Prop_Send, "m_nSolidType", 0);
	SetEntityRenderMode(iGlow, RENDER_NONE);
	SetEntityRenderColor(iGlow, 0, 0, 0, 0);
	SetGlowProps(iGlow);
	AcceptEntityInput(iGlow, "StartGlowing"); // m_iGlowType 3

	TeleportEntity(iGlow, vOrigin, vAngles, NULL_VECTOR);
	SetVariantString("!activator");
	AcceptEntityInput(iGlow, "SetParent", iProp);

	SDKHook(iGlow, SDKHook_SetTransmit, OnGlowTransmit);
	g_iGlowRef[iProp] = EntIndexToEntRef(iGlow);
}

void SetGlowProps(int iGlow)
{
	SetEntProp(iGlow, Prop_Send, "m_nGlowRange", g_iRange);
	SetEntProp(iGlow, Prop_Send, "m_nGlowRangeMin", g_iRangeMin);
	SetEntProp(iGlow, Prop_Send, "m_glowColorOverride", g_iColor);
}

int GetGlow(int iProp)
{
	int iGlow = EntRefToEntIndex(g_iGlowRef[iProp]);
	return (iGlow > MaxClients) ? iGlow : -1;
}

// Clear just the glow or the hittable as well?
void ClearGlows(bool bRemoveProps)
{
	int iGlow;
	for (int i = MaxClients + 1; i < MAX_EDICTS; i++) {
		if ((iGlow = GetGlow(i)) != -1) {
			RemoveEntity(bRemoveProps ? i : iGlow);
		}

		g_iGlowRef[i] = 0;
	}
}

Action OnGlowTransmit(int iGlow, int iClient)
{
	if (CanSeeGlow(iClient)) {
		g_bGlowSent[iClient] = true;
		return Plugin_Continue;
	}

	if (g_bGlowSent[iClient]) {
		RequestGlowRecreate();
	}

	return Plugin_Handled;
}

bool CanSeeGlow(int iClient)
{
	switch (GetClientTeam(iClient)) {
		case TEAM_INFECTED: {
			return (!g_bTankOnly || IsTank(iClient));
		}
		case TEAM_SPECTATOR: {
			return g_bSpectators;
		}
	}

	return false;
}

void Event_PlayerTeam(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	// player_team fires before the team actually changes, delay a frame
	RequestFrame(Frame_CheckStaleGlowClients);
}

void Frame_CheckStaleGlowClients(any data)
{
	CheckStaleGlowClients();
}

/*
	A client that stops being sent a glow entity still has the glow effect now stuck in place.
	The only way to get rid of it to delete the glow and recreate it, not too expensive considering...
*/
void CheckStaleGlowClients()
{
	for (int i = 1; i <= MaxClients; i++) {
		if (g_bGlowSent[i] && IsClientInGame(i) && !CanSeeGlow(i)) {
			RequestGlowRecreate();
			return;
		}
	}
}

void RequestGlowRecreate()
{
	if (g_bRecreatePending) {
		return;
	}

	g_bRecreatePending = true;
	RequestFrame(Frame_RecreateGlows);
}

void Frame_RecreateGlows(any data)
{
	g_bRecreatePending = false;

	for (int i = 1; i <= MaxClients; i++) {
		g_bGlowSent[i] = false;
	}

	int iGlow;
	for (int i = MaxClients + 1; i < MAX_EDICTS; i++) {
		if ((iGlow = GetGlow(i)) != -1) {
			RemoveEntity(iGlow);
			CreateGlow(i);
		}
	}
}

bool IsTankInPlay()
{
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_INFECTED && IsTank(i)) {
			return true;
		}
	}

	return false;
}

bool IsTank(int iClient)
{
	return (GetEntProp(iClient, Prop_Send, "m_zombieClass") == ZC_TANK && IsPlayerAlive(iClient));
}
