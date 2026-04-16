#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

/******************************************************************
*
* v0.1 ~ v0.4 by Visor and Stabby.
* ------------------------
* ------- Details: -------
* ------------------------
* > Applies configurable damage to Players depending on model.
* > Allows for "Overkill" to be ignored (Meaning extra hittable hits won't deal damage to the player before a timer expires)
*
* v0.5 by Sir
* ------------------------
* ------- Details: -------
* ------------------------
* > Updated the code to new Syntax.
* > Added Late Load support, just cause.
* > Added a suggested fix by Wicket to apply configurable damage value for the new forklift model.
* > Updated the method used to prevent "Overkill" from hittables, making it count per hittable as well as fixing damage not being applied at all.
* | -> this is to prevent prop_physics flying into players (dealing 0-1 damage) and then making the Survivor invulnerable to the actual hittable.
*
******************************************************************/

#define DEBUG 0
#define MAX_EDICTS 2048

enum struct SDKCallParamsWrapper {
	SDKType type;
	SDKPassMethod pass;
	int decflags;
	int encflags;
}

methodmap GameDataWrapper < GameData {
	public GameDataWrapper(const char[] file) {
		GameData gd = new GameData(file);
		if (!gd) SetFailState("Missing gamedata \"%s\"", file);
		return view_as<GameDataWrapper>(gd);
	}
	public Handle CreateSDKCallOrFail(
			SDKCallType type,
			SDKFuncConfSource src,
			const char[] name,
			const SDKCallParamsWrapper[] params = {},
			int numParams = 0,
			bool hasReturnValue = false,
			const SDKCallParamsWrapper ret = {}) {
		static const char k_sSDKFuncConfSource[SDKFuncConfSource][] = { "offset", "signature", "address" };
		Handle result;
		StartPrepSDKCall(type);
		if (!PrepSDKCall_SetFromConf(this, src, name))
			SetFailState("Missing %s \"%s\"", k_sSDKFuncConfSource[src], name);
		for (int i = 0; i < numParams; ++i)
			PrepSDKCall_AddParameter(params[i].type, params[i].pass, params[i].decflags, params[i].encflags);
		if (hasReturnValue)
			PrepSDKCall_SetReturnInfo(ret.type, ret.pass, ret.decflags, ret.encflags);
		if (!(result = EndPrepSDKCall()))
			SetFailState("Failed to prep sdkcall \"%s\"", name);
		return result;
	}
}

bool bIsGauntletFinale = false; //Gauntlet finales do reduced hittable damage

enum struct PhysicsHitInfo
{
	float nextDamageTime[MAXPLAYERS+1];
	int lastAttackerId;
	float lastAttackerTime;

	void Init()
	{
		for (int i = 1; i <= MaxClients; ++i)
		{
			this.nextDamageTime[i] = -1.0;
		}
		this.lastAttackerId = 0;
		this.lastAttackerTime = -1.0;
	}
}
int g_nPhysicsHitInfoEntry[MAX_EDICTS] = { -1, ... };
int g_iPhysicsDamage[MAX_EDICTS] = { -1, ... };
ArrayList g_PhysicsHitInfos;

bool g_bMapStarted;

//cvars
ConVar hGauntletFinaleMulti;
ConVar hLogStandingDamage;
ConVar hBHLogStandingDamage;
ConVar hCarStandingDamage;
ConVar hBumperCarStandingDamage;
ConVar hHandtruckStandingDamage;
ConVar hForkliftStandingDamage;
ConVar hBrokenForkliftStandingDamage;
ConVar hDumpsterStandingDamage;
ConVar hHaybaleStandingDamage;
ConVar hBaggageStandingDamage;
ConVar hGeneratorTrailerStandingDamage;
ConVar hMilitiaRockStandingDamage;
ConVar hSofaChairStandingDamage;
ConVar hAtlasBallDamage;
ConVar hIBeamDamage;
ConVar hBrickPalletsPiecesDamage;
ConVar hBoatSmashPiecesDamage;
ConVar hConcretePillerPiecesDamage;
ConVar hDiescraperBallDamage;
ConVar hVanDamage;
ConVar hStandardIncapDamage;
ConVar hTankSelfDamage;
ConVar hOverHitInterval;
ConVar hOverHitDebug;
ConVar hUnbreakableForklifts;
ConVar hPhysMassIncapThres;

Handle g_call_IPhysicsObject_GetMass;
float GetPropPhysicsMass(int entity)
{
	static int offs_m_pPhysicsObject = -1;
	if (offs_m_pPhysicsObject == -1)
	{
		offs_m_pPhysicsObject = FindDataMapInfo(entity, "m_pPhysicsObject");
		if (offs_m_pPhysicsObject == -1)
			return 1.0;
	}

	Address physobj = view_as<Address>(GetEntData(entity, offs_m_pPhysicsObject));
	if (physobj == Address_Null)
		return 1.0;
	
	return SDKCall(g_call_IPhysicsObject_GetMass, physobj);
}

public Plugin myinfo = 
{
	name = "L4D2 Hittable Control",
	author = "Stabby, Visor, Sir, Derpduck, Forgetest",
	version = "0.9.1",
	description = "Allows for customisation of hittable damage values (and debugging)"
};

public void OnPluginStart()
{
	GameDataWrapper gd = new GameDataWrapper("l4d2_hittable_control");

	SDKCallParamsWrapper params[] = {
		{SDKType_Float, SDKPass_Plain},
	};
	g_call_IPhysicsObject_GetMass = gd.CreateSDKCallOrFail(SDKCall_Raw, SDKConf_Virtual, "IPhysicsObject::GetMass", _, 0, true, params[0]);

	delete gd;

	ClearPhysicsHitInfos();

	hGauntletFinaleMulti	= CreateConVar( "hc_gauntlet_finale_multiplier",		"0.25",
											"Multiplier of damage that hittables deal on gauntlet finales.",
											FCVAR_NONE, true, 0.0, true, 4.0 );
	hLogStandingDamage		= CreateConVar( "hc_sflog_standing_damage",		"48.0",
											"Damage of hittable swamp fever logs to non-incapped survivors.",
											FCVAR_NONE, true, -2.0, false, 0.0 );
	hBHLogStandingDamage	= CreateConVar( "hc_bhlog_standing_damage",		"100.0",
											"Damage of hittable blood harvest logs to non-incapped survivors.",
											FCVAR_NONE, true, -2.0, false, 0.0 );
	hCarStandingDamage		= CreateConVar( "hc_car_standing_damage",		"100.0",
											"Damage of hittable cars to non-incapped survivors.",
											FCVAR_NONE, true, -2.0, false, 0.0 );
	hBumperCarStandingDamage= CreateConVar( "hc_bumpercar_standing_damage",	"100.0",
											"Damage of hittable bumper cars to non-incapped survivors.",
											FCVAR_NONE, true, -2.0, false, 0.0 );
	hHandtruckStandingDamage= CreateConVar( "hc_handtruck_standing_damage",	"8.0",
											"Damage of hittable handtrucks (aka dollies) to non-incapped survivors.",
											FCVAR_NONE, true, -2.0, false, 0.0 );
	hForkliftStandingDamage	= CreateConVar( "hc_forklift_standing_damage",	"100.0",
											"Damage of hittable forklifts to non-incapped survivors.",
											FCVAR_NONE, true, -2.0, false, 0.0 );
	hBrokenForkliftStandingDamage= CreateConVar( "hc_broken_forklift_standing_damage",	"100.0",
											"Damage of hittable broken forklifts to non-incapped survivors.",
											FCVAR_NONE, true, -2.0, false, 0.0 );
	hDumpsterStandingDamage	= CreateConVar( "hc_dumpster_standing_damage",	"100.0",
											"Damage of hittable dumpsters to non-incapped survivors.",
											FCVAR_NONE, true, -2.0, false, 0.0 );
	hHaybaleStandingDamage	= CreateConVar( "hc_haybale_standing_damage",	"48.0",
											"Damage of hittable haybales to non-incapped survivors.",
											FCVAR_NONE, true, -2.0, false, 0.0 );
	hBaggageStandingDamage	= CreateConVar( "hc_baggage_standing_damage",	"48.0",
											"Damage of hittable baggage carts to non-incapped survivors.",
											FCVAR_NONE, true, -2.0, false, 0.0 );
	hGeneratorTrailerStandingDamage	= CreateConVar( "hc_generator_trailer_standing_damage",	"48.0",
											"Damage of hittable generator trailers to non-incapped survivors.",
											FCVAR_NONE, true, -2.0, false, 0.0 );
	hMilitiaRockStandingDamage= CreateConVar( "hc_militia_rock_standing_damage",	"100.0",
											"Damage of hittable militia rocks to non-incapped survivors.",
											FCVAR_NONE, true, -2.0, false, 0.0 );
	hSofaChairStandingDamage= CreateConVar( "hc_sofa_chair_standing_damage",	"100.0",
											"Damage of hittable sofa chair on Blood Harvest finale to non-incapped survivors. Applies only to sofa chair with a targetname of 'hittable_chair_l4d1' to emulate L4D1 behaviour, the hittable chair from TLS update is parented to a bumper car.",
											FCVAR_NONE, true, -2.0, false, 0.0 );
	hAtlasBallDamage		= CreateConVar( "hc_atlas_ball_standing_damage",	"100.0",
											"Damage of hittable atlas balls to non-incapped survivors.",
											FCVAR_NONE, true, -2.0, false, 0.0 );
	hIBeamDamage			= CreateConVar( "hc_ibeam_standing_damage",	"48.0",
											"Damage of ibeams to non-incapped survivors.",
											FCVAR_NONE, true, -2.0, false, 0.0 );
	hBrickPalletsPiecesDamage	= CreateConVar( "hc_brick_pallets_standing_damage",	"13.0",
											"Damage of hittable brick pallets pieces to non-incapped survivors.",
											FCVAR_NONE, true, -2.0, false, 0.0 );
	hBoatSmashPiecesDamage		= CreateConVar( "hc_boat_smash_standing_damage",	"23.0",
											"Damage of hittable boat smash pieces to non-incapped survivors.",
											FCVAR_NONE, true, -2.0, false, 0.0 );
	hConcretePillerPiecesDamage	= CreateConVar( "hc_concrete_piller_standing_damage",	"8.0",
											"Damage of hittable concrete piller pieces to non-incapped survivors.",
											FCVAR_NONE, true, -2.0, false, 0.0 );
	hDiescraperBallDamage	= CreateConVar( "hc_diescraper_ball_standing_damage",	"100.0",
											"Damage of hittable ball statue on Diescraper finale to non-incapped survivors.",
											FCVAR_NONE, true, -2.0, false, 0.0 );
	hVanDamage				= CreateConVar( "hc_van_standing_damage",	"100.0",
											"Damage of hittable van on Detour Ahead map 2 to non-incapped survivors.",
											FCVAR_NONE, true, -2.0, false, 0.0 );
	hStandardIncapDamage	= CreateConVar( "hc_incap_standard_damage",		"100",
											"Damage of all hittables to incapped players. -1 will have incap damage default to valve's standard incoherent damages. -2 will have incap damage default to each hittable's corresponding standing damage.",
											FCVAR_NONE, true, -2.0, false, 0.0 );
	hTankSelfDamage			= CreateConVar( "hc_disable_self_damage",		"0",
											"If set, tank will not damage itself with hittables. (1: simply prevents all damage from Prop_Physics & Alarm Cars to cover for the event a Tank punches a hittable into another and gets hit)",
											FCVAR_NONE, true, 0.0, true, 1.0 );
	hOverHitInterval		= CreateConVar( "hc_overhit_time",				"1.2",
											"The amount of time to wait before allowing consecutive hits from the same hittable to register. Recommended values: 0.0-0.5: instant kill; 0.5-0.7: sizeable overhit; 0.7-1.0: standard overhit; 1.0-1.2: reduced overhit; 1.2+: no overhit unless the car rolls back on top. Set to tank's punch interval (default 1.5) to fully remove all possibility of overhit.",
											FCVAR_NONE, true, 0.0, false );
	hOverHitDebug			= CreateConVar( "hc_debug",				"0",
											"0: Disable Debug - 1: Enable Debug",
											FCVAR_NONE, true, 0.0, true, 1.0 );
	hUnbreakableForklifts	= CreateConVar( "hc_unbreakable_forklifts",	"0",
											"Prevents forklifts breaking into pieces when hit by a tank.",
											FCVAR_NONE, true, 0.0, false );
	hPhysMassIncapThres		= CreateConVar( "hc_phys_mass_incap_threshold",	"500.0",
											"Hittable that weights more than this mass incapacitates survivors on hit. 0.0 to disable",
											FCVAR_NONE, true, 0.0, false );

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("gauntlet_finale_start", Event_GauntletFinaleStart, EventHookMode_PostNoCopy);
	HookEvent("player_bot_replace", Event_player_bot_replace);
	HookEvent("bot_player_replace", Event_bot_player_replace);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("AreForkliftsUnbreakable", Native_UnbreakableForklifts);
	RegPluginLibrary("l4d2_hittable_control");
	return APLRes_Success;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnMapStart()
{
	g_bMapStarted = true;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
			OnClientPutInServer(i);
	}

	int entity = INVALID_ENT_REFERENCE;
	while ((entity = FindEntityByClassname(entity, "prop_physics*")) != INVALID_ENT_REFERENCE)
	{
		Physics_OnSpawnPost(entity);
	}

	entity = INVALID_ENT_REFERENCE;
	while ((entity = FindEntityByClassname(entity, "prop_car_alarm")) != INVALID_ENT_REFERENCE)
	{
		Physics_OnSpawnPost(entity);
	}
}

public void OnMapEnd()
{
	g_bMapStarted = false;
}

void ClearPhysicsHitInfos()
{
	for (int i = 0; i < MAX_EDICTS; ++i)
	{
		g_nPhysicsHitInfoEntry[i] = -1;
		g_iPhysicsDamage[i] = -1;
	}

	delete g_PhysicsHitInfos;
	g_PhysicsHitInfos = new ArrayList(sizeof(PhysicsHitInfo));
}

int NewPhysicsHitInfo()
{
	PhysicsHitInfo info;
	info.Init();
	return g_PhysicsHitInfos.PushArray(info);
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	// Reset everything to make sure we don't run into issues when a map is restarted (as GameTime resets)
	ClearPhysicsHitInfos();

	bIsGauntletFinale = false;
}

int Native_UnbreakableForklifts(Handle plugin, int numParams) {
	return hUnbreakableForklifts.BoolValue;
}

void Event_GauntletFinaleStart(Event event, const char[] name, bool dontBroadcast)
{
	bIsGauntletFinale = true;
}

void Event_player_bot_replace(Event event, const char[] name, bool dontBroadcast)
{
	HandlePlayerReplace(GetClientOfUserId(event.GetInt("bot")), GetClientOfUserId(event.GetInt("player")));
}

void Event_bot_player_replace(Event event, const char[] name, bool dontBroadcast)
{
	HandlePlayerReplace(GetClientOfUserId(event.GetInt("player")), GetClientOfUserId(event.GetInt("bot")));
}

void HandlePlayerReplace(int client, int replaced)
{
	PhysicsHitInfo info;
	for (int i = g_PhysicsHitInfos.Length-1; i >= 0; --i)
	{
		g_PhysicsHitInfos.GetArray(i, info);

		info.nextDamageTime[client] = info.nextDamageTime[replaced];
		info.nextDamageTime[replaced] = -1.0;

		// TODO: Swap lastAttackerId?
		g_PhysicsHitInfos.SetArray(i, info);
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!g_bMapStarted)
		return;

	if (classname[0] == 'p'
	 && (!strncmp(classname, "prop_physics", 12)
	  || !strcmp(classname, "physics_prop")
	  || !strcmp(classname, "prop_car_alarm")))
	{
		SDKHook(entity, SDKHook_SpawnPost, Physics_OnSpawnPost);
	}
}

public void OnEntityDestroyed(int entity)
{
	if (entity > 0 && entity < MAX_EDICTS)
	{
		g_nPhysicsHitInfoEntry[entity] = -1;
	}
}

void Physics_OnSpawnPost(int entity)
{
	int parent = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if (parent != -1)
	{
		g_nPhysicsHitInfoEntry[entity] = g_nPhysicsHitInfoEntry[parent];
	}
	g_iPhysicsDamage[entity] = -1;

	char modelname[PLATFORM_MAX_PATH];
	GetEntityModel(entity, modelname, sizeof(modelname));

	if (!strcmp(modelname, "models/props/cs_assault/forklift.mdl", false))
	{
		SDKHook(entity, SDKHook_OnTakeDamage, Forklift_OnTakeDamage);
	}
	SDKHook(entity, SDKHook_OnTakeDamage, Physics_OnTakeDamage);

	DebugMsg("Physics_OnSpawnPost (%s) (#%d) [#%d]", parent == -1 ? "new" : "child", entity, g_nPhysicsHitInfoEntry[entity]);
}

Action Physics_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!IsValidEdict(attacker))
		return Plugin_Continue;

	DebugMsg("(#%d) Physics_OnTakeDamage (attacker %d)", victim, attacker);

	if (attacker > 0 && attacker <= MaxClients && IsTank(attacker))
	{
		// A tank punches me, create a new entry if not
		if (g_nPhysicsHitInfoEntry[victim] == -1)
		{
			g_nPhysicsHitInfoEntry[victim] = NewPhysicsHitInfo();
			DebugMsg("(#%d) Physics_OnTakeDamage (new) [#%d]", victim, g_nPhysicsHitInfoEntry[victim]);
		}

		PhysicsHitInfo info;
		g_PhysicsHitInfos.GetArray(g_nPhysicsHitInfoEntry[victim], info);

		info.lastAttackerId = GetClientUserId(attacker);
		info.lastAttackerTime = GetGameTime();

		g_PhysicsHitInfos.SetArray(g_nPhysicsHitInfoEntry[victim], info);
		DebugMsg("(#%d) Physics_OnTakeDamage [%N]", victim, attacker);
	}
	else if (IsEntityClassname(attacker, "prop_physics*"))
	{
		// Collides with other physics, clone their hit info
		if (g_nPhysicsHitInfoEntry[attacker] != -1)
		{
			PhysicsHitInfo parentInfo;
			g_PhysicsHitInfos.GetArray(g_nPhysicsHitInfoEntry[attacker], parentInfo);

			if (parentInfo.lastAttackerId)
			{
				// Create an entry if not
				if (g_nPhysicsHitInfoEntry[victim] == -1)
				{
					g_nPhysicsHitInfoEntry[victim] = NewPhysicsHitInfo();
					DebugMsg("(#%d) Physics_OnTakeDamage (new) [#%d]", victim, g_nPhysicsHitInfoEntry[victim]);
				}

				PhysicsHitInfo selfinfo;
				g_PhysicsHitInfos.GetArray(g_nPhysicsHitInfoEntry[victim], selfinfo);

				selfinfo.lastAttackerId = parentInfo.lastAttackerId;
				selfinfo.lastAttackerTime = GetGameTime();

				g_PhysicsHitInfos.SetArray(g_nPhysicsHitInfoEntry[victim], selfinfo);
				DebugMsg("(#%d) Physics_OnTakeDamage prop_physics (#%d) [%d]", victim, g_nPhysicsHitInfoEntry[attacker], selfinfo.lastAttackerId);
			}
		}
		else
		{
			DebugMsg("(#%d) Physics_OnTakeDamage prop_physics (#%d)", victim, g_nPhysicsHitInfoEntry[attacker]);
		}
	}

	return Plugin_Continue;
}

Action Forklift_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (hUnbreakableForklifts.BoolValue)
	{
		SetEntProp(victim, Prop_Data, "m_createTick", GetGameTickCount());
	}

	return Plugin_Continue;
}

// -1 = no data, -2 = incap damage, actual dmg amount if any > 0
int GetHittableDamage(int entity)
{
	if (g_iPhysicsDamage[entity] == -1)
	{
		g_iPhysicsDamage[entity] = HittableDamageFromModel(entity);
		if (g_iPhysicsDamage[entity] == -1)
		{
			g_iPhysicsDamage[entity] = -3; // no more searching
			
			float mass = GetPropPhysicsMass(entity);
			if (mass >= hPhysMassIncapThres.FloatValue)
			{
				g_iPhysicsDamage[entity] = -2;
			}

			{
				char sModelName[PLATFORM_MAX_PATH];
				GetEntityModel(entity, sModelName, sizeof(sModelName));
				DebugMsg("Hittable (#%d) model (%s) not listed, setting damage (%.1f) by mass (%.1f)", entity, sModelName, g_iPhysicsDamage[entity], mass);
			}
		}
	}

	if (g_iPhysicsDamage[entity] == -2 || g_iPhysicsDamage[entity] >= 0)
		return g_iPhysicsDamage[entity];
	
	return -1;
}

int HittableDamageFromModel(int entity)
{
	char sModelName[PLATFORM_MAX_PATH];
	GetEntityModel(entity, sModelName, sizeof(sModelName));

	if (StrContains(sModelName, "cara_", false) != -1 
	|| StrContains(sModelName, "taxi_", false) != -1 
	|| StrContains(sModelName, "police_car", false) != -1
	|| StrContains(sModelName, "utility_truck", false) != -1)
	{
		return hCarStandingDamage.IntValue;
	}
	else if (StrContains(sModelName, "dumpster", false) != -1)
	{
		return hDumpsterStandingDamage.IntValue;
	}
	else if (StrEqual(sModelName, "models/props/cs_assault/forklift.mdl", false))
	{
		return hForkliftStandingDamage.IntValue;
	}
	else if (StrEqual(sModelName, "models/props_vehicles/airport_baggage_cart2.mdl", false))
	{
		return hBaggageStandingDamage.IntValue;
	}
	else if (StrEqual(sModelName, "models/props_unique/haybails_single.mdl", false))
	{
		return hHaybaleStandingDamage.IntValue;
	}
	else if (StrEqual(sModelName, "models/props_foliage/swamp_fallentree01_bare.mdl", false))
	{
		return hLogStandingDamage.IntValue;
	}
	else if (StrEqual(sModelName, "models/props_foliage/tree_trunk_fallen.mdl", false))
	{
		return hBHLogStandingDamage.IntValue;
	}
	else if (StrEqual(sModelName, "models/props_fairgrounds/bumpercar.mdl", false))
	{
		return hBumperCarStandingDamage.IntValue;
	}
	else if (StrEqual(sModelName, "models/props/cs_assault/handtruck.mdl", false))
	{
		return hHandtruckStandingDamage.IntValue;
	}
	else if (StrEqual(sModelName, "models/props_vehicles/generatortrailer01.mdl", false))
	{
		return hGeneratorTrailerStandingDamage.IntValue;
	}
	else if (StrEqual(sModelName, "models/props/cs_militia/militiarock01.mdl", false))
	{
		return hMilitiaRockStandingDamage.IntValue;
	}
	else if (StrEqual(sModelName, "models/props_interiors/sofa_chair02.mdl", false))
	{
		char targetname[128];
		GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));
		if (StrEqual(targetname, "hittable_chair_l4d1", false))
		{
			return hSofaChairStandingDamage.IntValue;
		}
	}
	else if (StrEqual(sModelName, "models/props_vehicles/van.mdl", false))
	{
		return hVanDamage.IntValue;
	}
	else if (StrEqual(sModelName, "models/props_diescraper/statue_break_ball.mdl", false))
	{
		return hDiescraperBallDamage.IntValue;
	}
	else if (StrEqual(sModelName, "models/sblitz/field_equipment_cart.mdl", false))
	{
		return hBaggageStandingDamage.IntValue;
	}
	else if (StrContains(sModelName, "forklift_brokenlift", false) != -1)
	{
		return hBrokenForkliftStandingDamage.IntValue;
	}
	else if (StrContains(sModelName, "atlas_break_ball.mdl", false) != -1)
	{
		return hAtlasBallDamage.IntValue;
	}
	else if (StrContains(sModelName, "ibeam_breakable01", false) != -1)
	{
		return hIBeamDamage.IntValue;
	}
	// Special Overkill section
	else if (StrContains(sModelName, "brickpallets_break", false) != -1)
	{
		return hBrickPalletsPiecesDamage.IntValue;
	}
	else if (StrContains(sModelName, "boat_smash_break", false) != -1)
	{
		return hBoatSmashPiecesDamage.IntValue;
	}
	else if (StrContains(sModelName, "concretepiller01_dm01", false) != -1)
	{
		return hConcretePillerPiecesDamage.IntValue;
	}
	
	return -1;
}

Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	// Hey, we don't care.
	if (!IsValidEdict(attacker)
	 || !IsValidEdict(inflictor)
	 || g_nPhysicsHitInfoEntry[inflictor] == -1)
		return Plugin_Continue;
	
	if (IsTank(victim) && hTankSelfDamage.BoolValue)
		return Plugin_Handled; // Tank is hitting himself with the Hittable (+added usecase when the Tank would be hit by a hittable that he punched a hittable against before it hit him)

	PhysicsHitInfo hitinfo;
	g_PhysicsHitInfos.GetArray(g_nPhysicsHitInfoEntry[inflictor], hitinfo);
	
	if (hitinfo.nextDamageTime[victim] > 0.0 && GetGameTime() <= hitinfo.nextDamageTime[victim])
	{
		damage = 0.0; // Overkill on this Hittable.
		return Plugin_Changed; 
	}

	hitinfo.nextDamageTime[victim] = GetGameTime() + hOverHitInterval.FloatValue;	//standardise them bitchin over-hits
	g_PhysicsHitInfos.SetArray(g_nPhysicsHitInfoEntry[inflictor], hitinfo);

	if (GetClientTeam(victim) != 2)
		return Plugin_Continue; // Victim is not a Survivor.
	
	int val = hStandardIncapDamage.IntValue;
	if (GetEntProp(victim, Prop_Send, "m_isIncapacitated") 
	 && val != -2) // Survivor is Incapped. (Damage)
	{
		if (val >= 0)
		{
			damage = float(val);
		}
		else return Plugin_Continue;
	}
	else 
	{
		int newDamage = GetHittableDamage(inflictor);
		if (newDamage == -2)
			damage = float(GetEntProp(victim, Prop_Data, "m_iMaxHealth"));
		else if (newDamage >= 0)
			damage = float(newDamage);
	}

	if (IsEntityClassname(attacker, "prop_physics*") || IsEntityClassname(attacker, "prop_car_alarm"))
	{
		if (hitinfo.lastAttackerTime > 0.0 && GetGameTime() <= hitinfo.lastAttackerTime + 60.0) // ignore info that's too ancient
		{
			int lastAttacker = GetClientOfUserId(hitinfo.lastAttackerId);
			if (lastAttacker > 0
			 && IsClientInGame(lastAttacker)
			 && GetClientTeam(lastAttacker) == 3)
			{
				attacker = lastAttacker;
			}
		}
	}
	
	// Use standard damage on gauntlet finales
	if (bIsGauntletFinale)
	{
		damage = damage * 4.0 * hGauntletFinaleMulti.FloatValue;
	}
	
	// inflictor = 0; // We have to set set the inflictor to 0 or else it will sometimes just refuse to apply damage.
	InvalidatePhysOverhitTimer(victim);
	
	{
		char sModelName[PLATFORM_MAX_PATH];
		GetEntityModel(inflictor, sModelName, sizeof(sModelName));
		DebugMsg("[l4d2_hittable_control]: \x03%N \x01was hit by \x04%s \x01for \x03%i \x01damage. Gauntlet: %b", victim, sModelName, RoundToNearest(damage), bIsGauntletFinale);
	}
	
	return Plugin_Changed;
}

void GetEntityModel(int entity, char[] buffer, int maxlength)
{
	GetEntPropString(entity, Prop_Data, "m_ModelName", buffer, maxlength);
	ReplaceString(buffer, maxlength, "\\", "/", false);
}

void InvalidatePhysOverhitTimer(int client)
{
	static int s_iOffs_m_physOverhitTimer = -1;
	if (s_iOffs_m_physOverhitTimer == -1)
		s_iOffs_m_physOverhitTimer = FindSendPropInfo("CTerrorPlayer", "m_knockdownTimer") + 32;
	
	SetEntDataFloat(client, s_iOffs_m_physOverhitTimer + 8, -1.0);
}

// int FindTank()
// {
// 	for (int i = 1; i <= MaxClients; i++)
// 	{
// 		if (IsClientInGame(i) && IsTank(i))
// 		{
// 			return i;
// 		}
// 	}
// 	return 0;
// }

bool IsTank(int client)
{
	return GetClientTeam(client) == 3
		&& GetEntProp(client, Prop_Send, "m_zombieClass") == 8;
}

bool IsEntityClassname(int entity, const char[] classname)
{
	int len = strlen(classname);
	if (len == 0)
		return false;

	char buffer[64];
	GetEntityClassname(entity, buffer, sizeof(buffer));
	return classname[len-1] == '*' ? !strncmp(buffer, classname, len-1) : !strcmp(buffer, classname);
}

stock void Assert(bool cond, const char[] msg = "")
{
#if DEBUG
	if (!cond)
	{
		LogError("Assertion failed! (%s)", msg);
	}
#else
	#pragma unused cond
	#pragma unused msg
#endif
}

stock void DebugMsg(const char[] format, any ...)
{
	if (hOverHitDebug.BoolValue)
	{
		char buffer[512];
		VFormat(buffer, sizeof(buffer), format, 2);
		PrintToConsoleAll("%s", buffer);
		// PrintToServer("%s", buffer);
		// LogMessage("%s", buffer);
	}
}
