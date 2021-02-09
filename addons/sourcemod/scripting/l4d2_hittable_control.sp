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

bool bIsBridge;		//for parish bridge cars
bool bIsStadium;	//for suicide blitz finale hittables
float fOverkill[MAXPLAYERS + 1][2048]; // Overkill, prolly don't need this big of a global array, could also use adt_array.
float fSpecialOverkill[MAXPLAYERS + 1][2]; // Dealing with breakable pieces that will cause multiple hits in a row (unintended behaviour)
bool bLateLoad;   // Late load support!

//cvars
ConVar hBridgeCarDamage;
ConVar hStadiumCarDamage;
ConVar hLogStandingDamage;
ConVar hCarStandingDamage;
ConVar hBumperCarStandingDamage;
ConVar hHandtruckStandingDamage;
ConVar hForkliftStandingDamage;
ConVar hBrokenForkliftStandingDamage;
ConVar hBHLogStandingDamage;
ConVar hDumpsterStandingDamage;
ConVar hHaybaleStandingDamage;
ConVar hBaggageStandingDamage;
ConVar hStandardIncapDamage;
ConVar hTankSelfDamage;
ConVar hOverHitInterval;
ConVar hOverHitDebug;

public Plugin myinfo = 
{
    name = "L4D2 Hittable Control",
    author = "Stabby, Visor, Sir",
    version = "0.6",
    description = "Allows for customisation of hittable damage values (and debugging)"
};

public void OnPluginStart()
{
	hBridgeCarDamage		= CreateConVar( "hc_bridge_car_damage",			"25.0",
											"Damage of cars in the parish bridge finale. Overrides standard incap damage on incapacitated players.",
											FCVAR_NONE, true, 0.0, true, 300.0 );
	hStadiumCarDamage		= CreateConVar( "hc_stadium_car_damage",			"25.0",
											"Damage of cars and carts in the Suicide Blitz 2 finale. Overrides standard incap damage on incapacitated players.",
											FCVAR_NONE, true, 0.0, true, 300.0 );
	hLogStandingDamage		= CreateConVar( "hc_sflog_standing_damage",		"48.0",
											"Damage of hittable swamp fever logs to non-incapped survivors.",
											FCVAR_NONE, true, 0.0, true, 300.0 );
	hBHLogStandingDamage	= CreateConVar( "hc_bhlog_standing_damage",		"100.0",
											"Damage of hittable blood harvest logs to non-incapped survivors.",
											FCVAR_NONE, true, 0.0, true, 300.0 );
	hCarStandingDamage		= CreateConVar( "hc_car_standing_damage",		"100.0",
											"Damage of hittable non-parish-bridge cars to non-incapped survivors.",
											FCVAR_NONE, true, 0.0, true, 300.0 );
	hBumperCarStandingDamage= CreateConVar( "hc_bumpercar_standing_damage",	"100.0",
											"Damage of hittable bumper cars to non-incapped survivors.",
											FCVAR_NONE, true, 0.0, true, 300.0 );
	hHandtruckStandingDamage= CreateConVar( "hc_handtruck_standing_damage",	"8.0",
											"Damage of hittable handtrucks (aka dollies) to non-incapped survivors.",
											FCVAR_NONE, true, 0.0, true, 300.0 );
	hForkliftStandingDamage= CreateConVar(  "hc_forklift_standing_damage",	"100.0",
											"Damage of hittable forklifts to non-incapped survivors.",
											FCVAR_NONE, true, 0.0, true, 300.0 );
	hBrokenForkliftStandingDamage= CreateConVar(  "hc_broken_forklift_standing_damage",	"100.0",
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
	hStandardIncapDamage	= CreateConVar( "hc_incap_standard_damage",		"100",
											"Damage of all hittables to incapped players. -1 will have incap damage default to valve's standard incoherent damages. -2 will have incap damage default to each hittable's corresponding standing damage.",
											FCVAR_NONE, true, -2.0, true, 300.0 );
	hTankSelfDamage			= CreateConVar( "hc_disable_self_damage",		"0",
											"If set, tank will not damage itself with hittables.",
											FCVAR_NONE, true, 0.0, true, 1.0 );
	hOverHitInterval		= CreateConVar( "hc_overhit_time",				"1.2",
											"The amount of time to wait before allowing consecutive hits from the same hittable to register. Recommended values: 0.0-0.5: instant kill; 0.5-0.7: sizeable overhit; 0.7-1.0: standard overhit; 1.0-1.2: reduced overhit; 1.2+: no overhit unless the car rolls back on top. Set to tank's punch interval (default 1.5) to fully remove all possibility of overhit.",
											FCVAR_NONE, true, 0.0, false );
	hOverHitDebug		    = CreateConVar( "hc_debug",				"0",
											"0: Disable Debug - 1: Enable Debug",
											FCVAR_NONE, true, 0.0, false );

	if (bLateLoad)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			  SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}

	HookEvent("round_start", Event_RoundStart);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	bLateLoad = late;
	return APLRes_Success;
}

public void OnMapStart()
{
	char buffer[64];
	GetCurrentMap(buffer, sizeof(buffer));
	if (StrContains(buffer, "c5m5") != -1)	//so it works for darkparish. should probably find out what causes the changes to the cars though, this is ugly
	  bIsBridge = true;

	else if (StrContains(buffer, "l4d2_stadium5") != -1)	//suicide blitz finale
	  bIsStadium = true;

	else
	{
		bIsBridge = false;	//in case of map changes or something
		bIsStadium = false;
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	// Reset everything to make sure we don't run into issues when a map is restarted (as GameTime resets)
	for (int i = 1; i <= MaxClients; i++)
	{
		for (int e = 0; e++ <= 2047; e++)
		{
			fOverkill[i][e] = 0.0;
		}
		fSpecialOverkill[i][0] = 0.0;
		fSpecialOverkill[i][1] = 0.0;
	}
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

	if (StrEqual(sClass,"prop_physics") || 
	StrEqual(sClass,"prop_car_alarm"))
	{
		if (fOverkill[victim][inflictor] - GetGameTime() > 0.0)
			return Plugin_Handled; // Overkill on this Hittable.

		if (victim == attacker 
		&& GetConVarBool(hTankSelfDamage))
		  return Plugin_Handled; // Tank is hitting himself with the Hittable.

		if (GetClientTeam(victim) != 2)
		  return Plugin_Continue; // Victim is not a Survivor.
		
		char sModelName[128];
		GetEntPropString(inflictor, Prop_Data, "m_ModelName", sModelName, 128);
		float interval = GetConVarFloat(hOverHitInterval);

		// Special Overkill section
		if (StrContains(sModelName, "brickpallets_break") != -1) // [0]
		{
			if (fSpecialOverkill[victim][0] - GetGameTime() > 0) return Plugin_Handled;
			fSpecialOverkill[victim][0] = GetGameTime() + interval;
			damage = 13.0;
			attacker = FindTank();
		}
		else if (StrContains(sModelName, "boat_smash_break") != -1) // [1]
		{
			if (fSpecialOverkill[victim][1] - GetGameTime() > 0) return Plugin_Handled;
			fSpecialOverkill[victim][1] = GetGameTime() + interval;
			damage = 23.0;
			attacker = FindTank();
		}
		
		float val = GetConVarFloat(hStandardIncapDamage);
		if (GetEntProp(victim, Prop_Send, "m_isIncapacitated") 
		&& val != -2) // Survivor is Incapped. (Damage)
		{
			if (val >= 0.0)
				damage = val;

			else return Plugin_Continue;
		}
		else 
		{
			if (StrContains(sModelName, "cara_") != -1 
			|| StrContains(sModelName, "taxi_") != -1 
			|| StrContains(sModelName, "police_car") != -1)
			{
				if (bIsBridge)
				{
					damage = 4.0*GetConVarFloat(hBridgeCarDamage);
				}
				else if (bIsStadium)
				{
					damage = 4.0*GetConVarFloat(hStadiumCarDamage);
				}
				else
				{
					damage = GetConVarFloat(hCarStandingDamage);
				}
			}
			else if (StrContains(sModelName, "dumpster") != -1)
			{
				damage = GetConVarFloat(hDumpsterStandingDamage);
			}
			else if (StrEqual(sModelName, "models/props/cs_assault/forklift.mdl"))
			{
				damage = GetConVarFloat(hForkliftStandingDamage);
			}
			else if (StrContains(sModelName, "forklift_brokenlift") != -1)
			{
				damage = GetConVarFloat(hBrokenForkliftStandingDamage);
			}		
			else if (StrEqual(sModelName, "models/props_vehicles/airport_baggage_cart2.mdl"))
			{
				damage = GetConVarFloat(hBaggageStandingDamage);
			}
			else if (StrEqual(sModelName, "models/props_unique/haybails_single.mdl"))
			{
				damage = GetConVarFloat(hHaybaleStandingDamage);
			}
			else if (StrEqual(sModelName, "models/props_foliage/Swamp_FallenTree01_bare.mdl"))
			{
				damage = GetConVarFloat(hLogStandingDamage);
			}
			else if (StrEqual(sModelName, "models/props_foliage/tree_trunk_fallen.mdl"))
			{
				damage = GetConVarFloat(hBHLogStandingDamage);
			}
			else if (StrEqual(sModelName, "models/props_fairgrounds/bumpercar.mdl"))
			{
				damage = GetConVarFloat(hBumperCarStandingDamage);
			}
			else if (StrEqual(sModelName, "models/props/cs_assault/handtruck.mdl"))
			{
				damage = GetConVarFloat(hHandtruckStandingDamage);
			}
			else if (StrEqual(sModelName, "models/sblitz/field_equipment_cart.mdl"))
			{
				damage = 4.0*GetConVarFloat(hStadiumCarDamage);
			}
		}
			
		if (interval >= 0.0)
		{
			fOverkill[victim][inflictor] = GetGameTime() + interval;	//standardise them bitchin over-hits
		}
		inflictor = 0; // We have to set set the inflictor to 0 or else it will sometimes just refuse to apply damage.

		if (GetConVarBool(hOverHitDebug)) PrintToChatAll("[l4d2_hittable_control]: \x03%N \x01was hit by \x04%s \x01for \x03%i \x01damage", victim, sModelName, RoundToNearest(damage));

		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

int FindTank()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i)
		&& GetClientTeam(i) == 3
		&& GetEntProp(i, Prop_Send, "m_zombieClass") == 8)
		{
			return i;
		}
	}
	return 0;
}