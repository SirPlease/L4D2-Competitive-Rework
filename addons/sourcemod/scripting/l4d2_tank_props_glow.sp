#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <dhooks>

#define TANK_ZOMBIE_CLASS   8
ConVar g_hCvartankPropsGlow,g_hCvarRange,g_hCvarColor,g_hCvarTankOnly,g_hCvarTankSpec, g_hCvarTankPropsBeGone;
int g_iCvarRange,g_iCvarColor;
bool g_iCvarTankOnly,g_iCvarTankSpec;

Handle hTankProps;
Handle hTankPropsHit;
int i_Ent[2048] = -1;
int iTankClient = -1;
bool tankSpawned;

public Plugin myinfo = {
	name        = "L4D2 Tank Hittable Glow",
	author      = "Harry Potter, Sir",
	version     = "2.0",
	description = "Stop tank props from fading whilst the tank is alive + add Hittable Glow."
};

public void OnPluginStart() {
	g_hCvartankPropsGlow = CreateConVar("l4d_tank_props_glow", "1", "Show Hittable Glow for infected team while the tank is alive", FCVAR_NOTIFY);
	g_hCvarColor =	CreateConVar(	"l4d2_tank_prop_glow_color",		"255 255 255",			"Prop Glow Color, three values between 0-255 separated by spaces. RGB Color255 - Red Green Blue.", FCVAR_NOTIFY);
	g_hCvarRange =	CreateConVar(	"l4d2_tank_prop_glow_range",		"4500",				"How near to props do players need to be to enable their glow.", FCVAR_NOTIFY);
	g_hCvarTankOnly =	CreateConVar(	"l4d2_tank_prop_glow_only",		"0",				"Only Tank can see the glow", FCVAR_NOTIFY);
	g_hCvarTankSpec =	CreateConVar(	"l4d2_tank_prop_glow_spectators",		"1",				"Spectators can see the glow too", FCVAR_NOTIFY);
	g_hCvarTankPropsBeGone = CreateConVar("l4d2_tank_prop_dissapear_time", "10.0", "Time it takes for hittables that were punched by Tank to dissapear after the Tank dies.", FCVAR_NOTIFY);

	GetCvars();
	g_hCvartankPropsGlow.AddChangeHook(TankPropsGlowAllow);
	g_hCvarColor.AddChangeHook(ConVarChanged_Glow);
	g_hCvarRange.AddChangeHook(ConVarChanged_Range);
	g_hCvarTankOnly.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTankSpec.AddChangeHook(ConVarChanged_Cvars);

	PluginEnable();
}

void PluginEnable() {
	SetConVarBool(FindConVar("sv_tankpropfade"), false);

	hTankProps = CreateArray();
	hTankPropsHit = CreateArray();

	HookEvent("round_start", TankPropRoundReset);
	HookEvent("round_end", TankPropRoundReset);
	HookEvent("tank_spawn", TankPropTankSpawn);
	HookEvent("player_death", TankPropTankKilled);

	char sColor[16];
	g_hCvarColor.GetString(sColor, sizeof(sColor));
	g_iCvarColor = GetColor(sColor);
	g_iCvarRange = GetConVarInt(g_hCvarRange);
	g_iCvarTankOnly = GetConVarBool(g_hCvarTankOnly);
	
}

void PluginDisable() {
	SetConVarBool(FindConVar("sv_tankpropfade"), true);

	UnhookEvent("round_start", TankPropRoundReset);
	UnhookEvent("round_end", TankPropRoundReset);
	UnhookEvent("tank_spawn", TankPropTankSpawn);
	UnhookEvent("player_death", TankPropTankKilled);

	if(!tankSpawned) return;

	int ref;
	for ( int i = 0; i < GetArraySize(hTankPropsHit); i++ ) {
		if ( IsValidEdict(GetArrayCell(hTankPropsHit, i)) ) {
			ref = i_Ent[GetArrayCell(hTankPropsHit, i)];
			if(IsValidEntRef(ref))
				RemoveEntity(ref);
		}
	}
	tankSpawned = false;

	CloseHandle(hTankProps);
	CloseHandle(hTankPropsHit);
}

public Action TankPropRoundReset( Handle event, const char[] name, bool dontBroadcast ) {
	tankSpawned = false;
	
	UnhookTankProps();
	ClearArray(hTankPropsHit);
}

public Action TankPropTankSpawn( Handle event, const char[] name, bool dontBroadcast ) {
	if ( !tankSpawned ) {
		UnhookTankProps();
		ClearArray(hTankPropsHit);
		
		HookTankProps();
		
		DHookAddEntityListener(ListenType_Created, PossibleTankPropCreated);

		tankSpawned = true;
	}    
}

public Action PD_ev_EntityKilled( Handle event, const char[] name, bool dontBroadcast )
{
	int client;
	if (tankSpawned && IsTank((client = GetEventInt(event, "entindex_killed"))))
	{
		CreateTimer(1.5, TankDeadCheck, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action TankPropTankKilled( Handle event, const char[] name, bool dontBroadcast ) {
	if ( !tankSpawned ) {
		return;
	}
	
	CreateTimer(0.5, TankDeadCheck);
}

public Action TankDeadCheck( Handle timer ) {
	if ( GetTankClient() == -1 ) 
	{
		CreateTimer(g_hCvarTankPropsBeGone.FloatValue, TankPropsBeGone);
		DHookRemoveEntityListener(ListenType_Created, PossibleTankPropCreated);
		tankSpawned = false;
	}
}

public Action TankPropsBeGone(Handle timer)
{
	UnhookTankProps();
}

public void PropDamaged(int victim, int attacker, int inflictor, float damage, int damageType) {
	if ( IsTank(attacker) || FindValueInArray(hTankPropsHit, inflictor) != -1 ) {
		//PrintToChatAll("tank hit %d",victim);
		if ( FindValueInArray(hTankPropsHit, victim) == -1 ) {
			PushArrayCell(hTankPropsHit, victim);			
			CreateTankPropGlow(victim);
		}
	}
}

void CreateTankPropGlow(int target)
{
	// Get Client Model
	char sModelName[64];
	GetEntPropString(target, Prop_Data, "m_ModelName", sModelName, sizeof(sModelName));
	
	// Spawn dynamic prop entity
	int entity = CreateEntityByName("prop_dynamic_ornament");
	if (entity == -1) return;
	
	// Set new fake model
	PrecacheModel(sModelName);
	SetEntityModel(entity, sModelName);
	DispatchSpawn(entity);

	// Set outline glow color
	SetEntProp(entity, Prop_Send, "m_CollisionGroup", 0);
	SetEntProp(entity, Prop_Send, "m_nSolidType", 0);
	SetEntProp(entity, Prop_Send, "m_nGlowRange", g_iCvarRange);
	SetEntProp(entity, Prop_Send, "m_iGlowType", 2);
	SetEntProp(entity, Prop_Send, "m_glowColorOverride", g_iCvarColor);
	AcceptEntityInput(entity, "StartGlowing");

	// Set model invisible
	SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
	SetEntityRenderColor(entity, 0, 0, 0, 0);

	// Set model attach to client, and always synchronize
	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetAttached", target);
	AcceptEntityInput(entity, "TurnOn");

	SDKHook(entity, SDKHook_SetTransmit, OnTransmit);
	i_Ent[target] = EntIndexToEntRef(entity);
}

public Action OnTransmit(int entity, int client)
{
	
	if (GetClientTeam(client) == 3)
	{
		if(IsTank(client))
			return Plugin_Continue;
		else
		{
			if(g_iCvarTankOnly == false)
				return Plugin_Continue;
			else
				return Plugin_Handled;
		}
	}
	else if ( GetClientTeam(client) == 1 && g_iCvarTankSpec == true)
	{
		return Plugin_Continue;
	}
	
	return Plugin_Handled;
}

bool IsTankProp(int iEntity ) {
	if ( !IsValidEdict(iEntity) ) {
		return false;
	}
	
	char className[64];
	
	GetEdictClassname(iEntity, className, sizeof(className));
	if (StrEqual(className, "prop_physics")) 
	{
		if (GetEntProp(iEntity, Prop_Send, "m_hasTankGlow", 1)) 
		{
			char sModel[64];
			GetEntPropString(iEntity, Prop_Data, "m_ModelName", sModel, sizeof(sModel));

			if (StrEqual("models/props/cs_assault/forklift.mdl", sModel))
			{
				return false;
			}
			return true;
		}

		static char m_ModelName[PLATFORM_MAX_PATH];
		GetEntPropString(iEntity, Prop_Data, "m_ModelName", m_ModelName, sizeof(m_ModelName));
		if (StrContains(m_ModelName, "atlas_break_ball") != -1) {
			return true;
		}
	}
	else if (StrEqual(className, "prop_car_alarm")) {
		return true;
	}
	
	return false;
}

void HookTankProps() {
	int iEntCount = GetMaxEntities();
	
	for ( int i = 1; i <= iEntCount; i++ ) {
		if ( IsTankProp(i) ) {
			SDKHook(i, SDKHook_OnTakeDamagePost, PropDamaged);
			PushArrayCell(hTankProps, i);
		}
	}
}

void UnhookTankProps() {
	for ( int i = 0; i < GetArraySize(hTankProps); i++ ) {
		SDKUnhook(GetArrayCell(hTankProps, i), SDKHook_OnTakeDamagePost, PropDamaged);
	}

	int entity;
	for ( int i = 0; i < GetArraySize(hTankPropsHit); i++ ) {
		entity = GetArrayCell(hTankPropsHit, i);
		if ( IsValidEdict(entity) ) {
			RemoveEntity(entity);
			//PrintToChatAll("remove %d", entity);
		}
	}
	ClearArray(hTankProps);
	ClearArray(hTankPropsHit);
}

int GetTankClient() {
	if ( iTankClient == -1 || !IsTank(iTankClient) ) {
		iTankClient = FindTank();
	}
	
	return iTankClient;
}

int FindTank() {
	for ( int i = 1; i <= MaxClients; i++ ) {
		if ( IsTank(i) ) {
			return i;
		}
	}
	
	return -1;
}

bool IsTank( int client ) {
	if ( client <= 0
	|| client > MaxClients
	|| !IsClientInGame(client)
	|| GetClientTeam(client) != 3
	|| !IsPlayerAlive(client) ) {
		return false;
	}

	if ( GetEntProp(client, Prop_Send, "m_zombieClass") == TANK_ZOMBIE_CLASS ) {
		return true;
	}

	return false;
}

public void TankPropsGlowAllow(Handle convar, const char[] oldValue, const char[] newValue) {
 
	if ( g_hCvartankPropsGlow.BoolValue == false ) {
		PluginDisable();
	}
	else {
		PluginEnable();
	}
}

public void ConVarChanged_Glow( ConVar convar, const char[] oldValue, const char[] newValue ) {

	GetCvars();

	if(!tankSpawned) return;

	int ref;
	for ( int i = 0; i < GetArraySize(hTankPropsHit); i++ ) {
		if ( IsValidEdict(GetArrayCell(hTankPropsHit, i)) ) {
			ref = i_Ent[GetArrayCell(hTankPropsHit, i)];
			if( IsValidEntRef(ref) )
			{
				SetEntProp(ref, Prop_Send, "m_iGlowType", 3);
				SetEntProp(ref, Prop_Send, "m_glowColorOverride", g_iCvarColor);
			}
		}
	}
}

public void ConVarChanged_Range( ConVar convar, const char[] oldValue, const char[] newValue ) {

	GetCvars();

	if(!tankSpawned) return;

	int ref;
	for ( int i = 0; i < GetArraySize(hTankPropsHit); i++ ) {
		if ( IsValidEdict(GetArrayCell(hTankPropsHit, i)) ) {
			ref = i_Ent[GetArrayCell(hTankPropsHit, i)];
			if( IsValidEntRef(ref) )
			{
				SetEntProp(ref, Prop_Send, "m_nGlowRange", g_iCvarRange);
			}
		} 
	}
}

public void ConVarChanged_Cvars( ConVar convar, const char[] oldValue, const char[] newValue ) {
	GetCvars();
}

void GetCvars()
{
	g_iCvarTankOnly = g_hCvarTankOnly.BoolValue;
	g_iCvarTankSpec	= g_hCvarTankSpec.BoolValue;
	g_iCvarRange = g_hCvarRange.IntValue;

	char sColor[16];
	g_hCvarColor.GetString(sColor, sizeof(sColor));
	g_iCvarColor = GetColor(sColor);
}

int GetColor(char[] sTemp)
{
	if( strcmp(sTemp, "") == 0)
		return 0;

	char sColors[3][4];
	int color = ExplodeString(sTemp, " ", sColors, 3, 4);

	if( color != 3 )
		return 0;

	color = StringToInt(sColors[0]);
	color += 256 * StringToInt(sColors[1]);
	color += 65536 * StringToInt(sColors[2]);

	return color;
}

bool IsValidEntRef(int ref)
{
	if( ref && EntRefToEntIndex(ref) != INVALID_ENT_REFERENCE)
		return true;
	return false;
}

public void PossibleTankPropCreated(int entity, const char[] classname)
{
	if (StrEqual(classname, "prop_physics")) // Hooks c11m4_terminal World Sphere
	{
		char m_ModelName[64];
		GetEntPropString(entity, Prop_Data, "m_ModelName", m_ModelName, sizeof(m_ModelName));

		// Use SpawnPost to just push it into the Array right away.
		// These entities get spawned after the Tank has punched them, so doing anything here will not work smoothly.
		SDKHook(entity, SDKHook_SpawnPost, PropSpawned);
	}
}

void PropSpawned(int entity)
{
	if (!IsValidEntity(entity)) return;

	if (FindValueInArray(hTankProps, entity) == -1)
	{
		static char m_ModelName[PLATFORM_MAX_PATH];
		GetEntPropString(entity, Prop_Data, "m_ModelName", m_ModelName, sizeof(m_ModelName));
		if (StrContains(m_ModelName, "atlas_break_ball") != -1 || StrContains(m_ModelName, "forklift_brokenlift.mdl") != -1) 
		{
			PushArrayCell(hTankProps, entity);
			PushArrayCell(hTankPropsHit, entity);			
			CreateTankPropGlow(entity);
		}
		else if (StrContains(m_ModelName, "forklift_brokenfork.mdl") != -1)
		{
			AcceptEntityInput(entity, "Kill");
		}
	}
}