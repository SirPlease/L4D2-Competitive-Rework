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

bool bIsGauntletFinale = false; //Gauntlet finales do reduced hittable damage
float fOverkill[MAXPLAYERS + 1][2048]; // Overkill, prolly don't need this big of a global array, could also use adt_array.
float fSpecialOverkill[MAXPLAYERS + 1][3]; // Dealing with breakable pieces that will cause multiple hits in a row (unintended behaviour)
bool bLateLoad;   // Late load support!

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
ConVar hDiescraperBallDamage;
ConVar hVanDamage;
ConVar hStandardIncapDamage;
ConVar hTankSelfDamage;
ConVar hOverHitInterval;
ConVar hOverHitDebug;
ConVar hUnbreakableForklifts;

public Plugin myinfo = 
{
    name = "L4D2 Hittable Control",
    author = "Stabby, Visor, Sir, Derpduck, Forgetest",
    version = "0.7",
    description = "Allows for customisation of hittable damage values (and debugging)"
};

public void OnPluginStart()
{
	hGauntletFinaleMulti	= CreateConVar( "hc_gauntlet_finale_multiplier",		"0.25",
											"Multiplier of damage that hittables deal on gauntlet finales.",
											FCVAR_NONE, true, 0.0, true, 4.0 );
	hLogStandingDamage		= CreateConVar( "hc_sflog_standing_damage",		"48.0",
											"Damage of hittable swamp fever logs to non-incapped survivors.",
											FCVAR_NONE, true, 0.0, true, 300.0 );
	hBHLogStandingDamage	= CreateConVar( "hc_bhlog_standing_damage",		"100.0",
											"Damage of hittable blood harvest logs to non-incapped survivors.",
											FCVAR_NONE, true, 0.0, true, 300.0 );
	hCarStandingDamage		= CreateConVar( "hc_car_standing_damage",		"100.0",
											"Damage of hittable cars to non-incapped survivors.",
											FCVAR_NONE, true, 0.0, true, 300.0 );
	hBumperCarStandingDamage= CreateConVar( "hc_bumpercar_standing_damage",	"100.0",
											"Damage of hittable bumper cars to non-incapped survivors.",
											FCVAR_NONE, true, 0.0, true, 300.0 );
	hHandtruckStandingDamage= CreateConVar( "hc_handtruck_standing_damage",	"8.0",
											"Damage of hittable handtrucks (aka dollies) to non-incapped survivors.",
											FCVAR_NONE, true, 0.0, true, 300.0 );
	hForkliftStandingDamage	= CreateConVar( "hc_forklift_standing_damage",	"100.0",
											"Damage of hittable forklifts to non-incapped survivors.",
											FCVAR_NONE, true, 0.0, true, 300.0 );
	hBrokenForkliftStandingDamage= CreateConVar( "hc_broken_forklift_standing_damage",	"100.0",
											"Damage of hittable broken forklifts to non-incapped survivors.",
											FCVAR_NONE, true, 0.0, true, 300.0 );
	hDumpsterStandingDamage	= CreateConVar( "hc_dumpster_standing_damage",	"100.0",
											"Damage of hittable dumpsters to non-incapped survivors.",
											FCVAR_NONE, true, 0.0, true, 300.0 );
	hHaybaleStandingDamage	= CreateConVar( "hc_haybale_standing_damage",	"48.0",
											"Damage of hittable haybales to non-incapped survivors.",
											FCVAR_NONE, true, 0.0, true, 300.0 );
	hBaggageStandingDamage	= CreateConVar( "hc_baggage_standing_damage",	"48.0",
											"Damage of hittable baggage carts to non-incapped survivors.",
											FCVAR_NONE, true, 0.0, true, 300.0 );
	hGeneratorTrailerStandingDamage	= CreateConVar( "hc_generator_trailer_standing_damage",	"48.0",
											"Damage of hittable generator trailers to non-incapped survivors.",
											FCVAR_NONE, true, 0.0, true, 300.0 );
	hMilitiaRockStandingDamage= CreateConVar( "hc_militia_rock_standing_damage",	"100.0",
											"Damage of hittable militia rocks to non-incapped survivors.",
											FCVAR_NONE, true, 0.0, true, 300.0 );
	hSofaChairStandingDamage= CreateConVar( "hc_sofa_chair_standing_damage",	"100.0",
											"Damage of hittable sofa chair on Blood Harvest finale to non-incapped survivors. Applies only to sofa chair with a targetname of 'hittable_chair_l4d1' to emulate L4D1 behaviour, the hittable chair from TLS update is parented to a bumper car.",
											FCVAR_NONE, true, 0.0, true, 300.0 );
	hAtlasBallDamage		= CreateConVar( "hc_atlas_ball_standing_damage",	"100.0",
											"Damage of hittable atlas balls to non-incapped survivors.",
											FCVAR_NONE, true, 0.0, true, 300.0 );
	hIBeamDamage			= CreateConVar( "hc_ibeam_standing_damage",	"48.0",
											"Damage of ibeams to non-incapped survivors.",
											FCVAR_NONE, true, 0.0, true, 300.0 );
	hDiescraperBallDamage	= CreateConVar( "hc_diescraper_ball_standing_damage",	"100.0",
											"Damage of hittable ball statue on Diescraper finale to non-incapped survivors.",
											FCVAR_NONE, true, 0.0, true, 300.0 );
	hVanDamage				= CreateConVar( "hc_van_standing_damage",	"100.0",
											"Damage of hittable van on Detour Ahead map 2 to non-incapped survivors.",
											FCVAR_NONE, true, 0.0, true, 300.0 );
	hStandardIncapDamage	= CreateConVar( "hc_incap_standard_damage",		"100",
											"Damage of all hittables to incapped players. -1 will have incap damage default to valve's standard incoherent damages. -2 will have incap damage default to each hittable's corresponding standing damage.",
											FCVAR_NONE, true, -2.0, true, 300.0 );
	hTankSelfDamage			= CreateConVar( "hc_disable_self_damage",		"0",
											"If set, tank will not damage itself with hittables. (0.6.1 simply prevents all damage from Prop_Physics & Alarm Cars to cover for the event a Tank punches a hittable into another and gets hit)",
											FCVAR_NONE, true, 0.0, true, 1.0 );
	hOverHitInterval		= CreateConVar( "hc_overhit_time",				"1.2",
											"The amount of time to wait before allowing consecutive hits from the same hittable to register. Recommended values: 0.0-0.5: instant kill; 0.5-0.7: sizeable overhit; 0.7-1.0: standard overhit; 1.0-1.2: reduced overhit; 1.2+: no overhit unless the car rolls back on top. Set to tank's punch interval (default 1.5) to fully remove all possibility of overhit.",
											FCVAR_NONE, true, 0.0, false );
	hOverHitDebug		    = CreateConVar( "hc_debug",				"0",
											"0: Disable Debug - 1: Enable Debug",
											FCVAR_NONE, true, 0.0, false );
	hUnbreakableForklifts	= CreateConVar( "hc_unbreakable_forklifts",	"0",
											"Prevents forklifts breaking into pieces when hit by a tank.",
											FCVAR_NONE, true, 0.0, false );

	if (bLateLoad)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			  OnClientPutInServer(i);
		}
	}

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("gauntlet_finale_start", Event_GauntletFinaleStart, EventHookMode_PostNoCopy);
	
	hUnbreakableForklifts.AddChangeHook(ConVarChanged_UnbreakableForklifts);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	bLateLoad = late;
	CreateNative("AreForkliftsUnbreakable", Native_UnbreakableForklifts);
	RegPluginLibrary("l4d2_hittable_control");
	return APLRes_Success;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	// Reset everything to make sure we don't run into issues when a map is restarted (as GameTime resets)
	for (int i = 1; i <= MaxClients; i++)
	{
		for (int e = 0; e < sizeof(fOverkill[]); e++)
		{
			fOverkill[i][e] = 0.0;
		}
		fSpecialOverkill[i][0] = 0.0;
		fSpecialOverkill[i][1] = 0.0;
		fSpecialOverkill[i][2] = 0.0;
	}
	
	bIsGauntletFinale = false;
	
	// Delay breakable forklift patch as it must run after vscripts
	if (hUnbreakableForklifts.BoolValue)
	{
		CreateTimer(20.0, PatchBreakableForklifts);
	}
	else
	{
		CreateTimer(20.0, UnpatchBreakableForklifts);
	}
}

public Action PatchBreakableForklifts(Handle timer)
{
	int forklift = -1;

	while ((forklift = FindEntityByClassname(forklift, "prop_physics")) != -1)
	{
		char sModelName[PLATFORM_MAX_PATH];
		GetEntPropString(forklift, Prop_Data, "m_ModelName", sModelName, sizeof(sModelName));
		ReplaceString(sModelName, sizeof(sModelName), "\\", "/", false);
		
		if (StrEqual(sModelName, "models/props/cs_assault/forklift.mdl", false))
		{
			SetEntProp(forklift, Prop_Data, "m_iMinHealthDmg", 0);
			SetEntProp(forklift, Prop_Data, "m_takedamage", 1);
		}
	}

	return Plugin_Stop;
}

public Action UnpatchBreakableForklifts(Handle timer)
{
	int forklift = -1;

	while ((forklift = FindEntityByClassname(forklift, "prop_physics")) != -1)
	{
		char sModelName[PLATFORM_MAX_PATH];
		GetEntPropString(forklift, Prop_Data, "m_ModelName", sModelName, sizeof(sModelName));
		ReplaceString(sModelName, sizeof(sModelName), "\\", "/", false);
		
		if (StrEqual(sModelName, "models/props/cs_assault/forklift.mdl", false))
		{
			SetEntProp(forklift, Prop_Data, "m_iMinHealthDmg", 400);
			SetEntProp(forklift, Prop_Data, "m_takedamage", 3);
		}
	}

	return Plugin_Stop;
}

public void ConVarChanged_UnbreakableForklifts(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	if (hUnbreakableForklifts.BoolValue)
	{
		CreateTimer(1.0, PatchBreakableForklifts);
	}
	else
	{
		CreateTimer(1.0, UnpatchBreakableForklifts);
	}
}

public int Native_UnbreakableForklifts(Handle plugin, int numParams) {
	return hUnbreakableForklifts.BoolValue;
}

public void Event_GauntletFinaleStart(Event event, const char[] name, bool dontBroadcast)
{
	bIsGauntletFinale = true;
}

bool ProcessSpecialHittables(int victim, int &attacker, int &inflictor, float &damage)
{
	char sModelName[PLATFORM_MAX_PATH];
	GetEntityModel(inflictor, sModelName, sizeof(sModelName));
	
	// Special Overkill section
	if (StrContains(sModelName, "brickpallets_break", false) != -1) // [0]
	{
		if (fSpecialOverkill[victim][0] - GetGameTime() > 0) return true;
		fSpecialOverkill[victim][0] = GetGameTime() + hOverHitInterval.FloatValue;
		damage = 13.0;
		attacker = FindTank();
	}
	else if (StrContains(sModelName, "boat_smash_break", false) != -1) // [1]
	{
		if (fSpecialOverkill[victim][1] - GetGameTime() > 0) return true;
		fSpecialOverkill[victim][1] = GetGameTime() + hOverHitInterval.FloatValue;
		damage = 23.0;
		attacker = FindTank();
	}
	else if (StrContains(sModelName, "concretepiller01_dm01", false) != -1) // [2]
	{
		if (fSpecialOverkill[victim][2] - GetGameTime() > 0) return true;
		fSpecialOverkill[victim][2] = GetGameTime() + hOverHitInterval.FloatValue;
		damage = 8.0;
		attacker = FindTank();
	}
	
	return false;
}

bool GetHittableDamage(int entity, float &damage)
{
	char sModelName[PLATFORM_MAX_PATH];
	GetEntityModel(entity, sModelName, sizeof(sModelName));
	
	if (StrContains(sModelName, "cara_", false) != -1 
	|| StrContains(sModelName, "taxi_", false) != -1 
	|| StrContains(sModelName, "police_car", false) != -1
	|| StrContains(sModelName, "utility_truck", false) != -1)
	{
		damage = hCarStandingDamage.FloatValue;
	}
	else if (StrContains(sModelName, "dumpster", false) != -1)
	{
		damage = hDumpsterStandingDamage.FloatValue;
	}
	else if (StrEqual(sModelName, "models/props/cs_assault/forklift.mdl", false))
	{
		damage = hForkliftStandingDamage.FloatValue;
	}
	else if (StrContains(sModelName, "forklift_brokenlift", false) != -1)
	{
		damage = hBrokenForkliftStandingDamage.FloatValue;
	}		
	else if (StrEqual(sModelName, "models/props_vehicles/airport_baggage_cart2.mdl", false))
	{
		damage = hBaggageStandingDamage.FloatValue;
	}
	else if (StrEqual(sModelName, "models/props_unique/haybails_single.mdl", false))
	{
		damage = hHaybaleStandingDamage.FloatValue;
	}
	else if (StrEqual(sModelName, "models/props_foliage/swamp_fallentree01_bare.mdl", false))
	{
		damage = hLogStandingDamage.FloatValue;
	}
	else if (StrEqual(sModelName, "models/props_foliage/tree_trunk_fallen.mdl", false))
	{
		damage = hBHLogStandingDamage.FloatValue;
	}
	else if (StrEqual(sModelName, "models/props_fairgrounds/bumpercar.mdl", false))
	{
		damage = hBumperCarStandingDamage.FloatValue;
	}
	else if (StrEqual(sModelName, "models/props/cs_assault/handtruck.mdl", false))
	{
		damage = hHandtruckStandingDamage.FloatValue;
	}
	else if (StrEqual(sModelName, "models/props_vehicles/generatortrailer01.mdl", false))
	{
		damage = hGeneratorTrailerStandingDamage.FloatValue;
	}
	else if (StrEqual(sModelName, "models/props/cs_militia/militiarock01.mdl", false))
	{
		damage = hMilitiaRockStandingDamage.FloatValue;
	}
	else if (StrEqual(sModelName, "models/props_interiors/sofa_chair02.mdl", false))
	{
		char targetname[128];
		GetEntPropString(entity, Prop_Data, "m_iName", targetname, 128);
		if (StrEqual(targetname, "hittable_chair_l4d1", false))
		{
			damage = hSofaChairStandingDamage.FloatValue;
		}
	}
	else if (StrEqual(sModelName, "models/props_vehicles/van.mdl", false))
	{
		damage = hVanDamage.FloatValue;
	}
	else if (StrContains(sModelName, "atlas_break_ball.mdl", false) != -1)
	{
		damage = hAtlasBallDamage.FloatValue;
	}
	else if (StrContains(sModelName, "ibeam_breakable01", false) != -1)
	{
		damage = hIBeamDamage.FloatValue;
	}
	else if (StrEqual(sModelName, "models/props_diescraper/statue_break_ball.mdl", false))
	{
		damage = hDiescraperBallDamage.FloatValue;
	}
	else if (StrEqual(sModelName, "models/sblitz/field_equipment_cart.mdl", false))
	{
		damage = hBaggageStandingDamage.FloatValue;
	}
	else
	{
		return false;
	}
	
	return true;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	// Hey, we don't care.
	if (!IsValidEdict(attacker) || 
	!IsValidEdict(victim) || 
	!IsValidEdict(inflictor))
	  return Plugin_Continue;
	
	char sClass[64];
	GetEdictClassname(inflictor, sClass, sizeof(sClass));

	if (!StrEqual(sClass,"prop_physics") && !StrEqual(sClass,"prop_car_alarm"))
		return Plugin_Continue;
	
	if (fOverkill[victim][inflictor] - GetGameTime() > 0.0)
		return Plugin_Handled; // Overkill on this Hittable.

	if (IsTank(victim) && hTankSelfDamage.BoolValue)
		return Plugin_Handled; // Tank is hitting himself with the Hittable (+added usecase when the Tank would be hit by a hittable that he punched a hittable against before it hit him)

	if (GetClientTeam(victim) != 2)
		return Plugin_Continue; // Victim is not a Survivor.
	
	if (ProcessSpecialHittables(victim, attacker, inflictor, damage))
		return Plugin_Handled;
	
	float val = hStandardIncapDamage.FloatValue;
	if (GetEntProp(victim, Prop_Send, "m_isIncapacitated") 
	&& val != -2) // Survivor is Incapped. (Damage)
	{
		if (val >= 0.0)
		{
			damage = val;
		}
		else return Plugin_Continue;
	}
	else 
	{
		GetHittableDamage(inflictor, damage);
	}
	
	// Use standard damage on gauntlet finales
	if (bIsGauntletFinale)
	{
		damage = damage * 4.0 * hGauntletFinaleMulti.FloatValue;
	}
	
	fOverkill[victim][inflictor] = GetGameTime() + hOverHitInterval.FloatValue;	//standardise them bitchin over-hits
	
	// inflictor = 0; // We have to set set the inflictor to 0 or else it will sometimes just refuse to apply damage.
	InvalidatePhysOverhitTimer(victim);
	
	if (hOverHitDebug.BoolValue) 
	{
		char sModelName[PLATFORM_MAX_PATH];
		GetEntityModel(inflictor, sModelName, sizeof(sModelName));
		PrintToChatAll("[l4d2_hittable_control]: \x03%N \x01was hit by \x04%s \x01for \x03%i \x01damage. Gauntlet: %b", victim, sModelName, RoundToNearest(damage), bIsGauntletFinale);
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

int FindTank()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsTank(i))
		{
			return i;
		}
	}
	return 0;
}

bool IsTank(int client)
{
	return GetClientTeam(client) == 3
		&& GetEntProp(client, Prop_Send, "m_zombieClass") == 8;
}
