/*
	SourcePawn is Copyright (C) 2006-2015 AlliedModders LLC.  All rights reserved.
	SourceMod is Copyright (C) 2006-2015 AlliedModders LLC.  All rights reserved.
	Pawn and SMALL are Copyright (C) 1997-2015 ITB CompuPhase.
	Source is Copyright (C) Valve Corporation.
	All trademarks are property of their respective owners.

	This program is free software: you can redistribute it and/or modify it
	under the terms of the GNU General Public License as published by the
	Free Software Foundation, either version 3 of the License, or (at your
	option) any later version.

	This program is distributed in the hope that it will be useful, but
	WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
	General Public License for more details.

	You should have received a copy of the GNU General Public License along
	with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>
#include <l4d2util_stocks>

#define SURVIVOR_RUNSPEED		220.0
#define SURVIVOR_WATERSPEED_VS	170.0

#define TEAM_SURVIVORS 2
#define TEAM_INFECTED 3
#define Z_TANK 8

ConVar
	hCvarSdPistolMod,
	hCvarSdDeagleMod,
	hCvarSdUziMod,
	hCvarSdMacMod,
	hCvarSdAkMod,
	hCvarSdM4Mod,
	hCvarSdScarMod,
	hCvarSdPumpMod,
	hCvarSdChromeMod,
	hCvarSdAutoMod,
	hCvarSdRifleMod,
	hCvarSdScoutMod,
	hCvarSdMilitaryMod,
	hCvarSdGunfireSi,
	hCvarSdGunfireTank,
	hCvarSdInwaterTank,
	hCvarSdInwaterSurvivor,
	hCvarSdInwaterDuringTank,
	hCvarSurvivorLimpspeed,
	hCvarTankSpeedVS;

float
	fTankWaterSpeed,
	fSurvWaterSpeed,
	fSurvWaterSpeedDuringTank,
	fTankRunSpeed;

bool
	tankInPlay = false;

public Plugin myinfo =
{
	name = "L4D2 Slowdown Control",
	author = "Visor, Sir, darkid, Forgetest, A1m`",
	version = "2.6.6",
	description = "Manages the water/gunfire slowdown for both teams",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	hCvarSdGunfireSi = CreateConVar("l4d2_slowdown_gunfire_si", "0.0", "Maximum slowdown from gunfire for SI (-1: native slowdown; 0.0: No slowdown, 0.01-1.0: 1%%-100%% slowdown)", _, true, -1.0, true, 1.0);
	hCvarSdGunfireTank = CreateConVar("l4d2_slowdown_gunfire_tank", "0.2", "Maximum slowdown from gunfire for the Tank (-1: native slowdown; 0.0: No slowdown, 0.01-1.0: 1%%-100%% slowdown)", _, true, -1.0, true, 1.0);
	hCvarSdInwaterTank = CreateConVar("l4d2_slowdown_water_tank", "-1", "Maximum tank speed in the water (-1: ignore setting; 0: default; 210: default Tank Speed)", _, true, -1.0);
	hCvarSdInwaterSurvivor = CreateConVar("l4d2_slowdown_water_survivors", "-1", "Maximum survivor speed in the water outside of Tank fights (-1: ignore setting; 0: default; 220: default Survivor speed)", _, true, -1.0);
	hCvarSdInwaterDuringTank = CreateConVar("l4d2_slowdown_water_survivors_during_tank", "0", "Maximum survivor speed in the water during Tank fights (0: ignore setting; 220: default Survivor speed)", _, true, 0.0);

	hCvarSdPistolMod = CreateConVar("l4d2_slowdown_pistol_percent", "0.0", "Pistols cause this much slowdown * l4d2_slowdown_gunfire at maximum damage.");
	hCvarSdDeagleMod = CreateConVar("l4d2_slowdown_deagle_percent", "0.1", "Deagles cause this much slowdown * l4d2_slowdown_gunfire at maximum damage.");
	hCvarSdUziMod = CreateConVar("l4d2_slowdown_uzi_percent", "0.8", "Unsilenced uzis cause this much slowdown * l4d2_slowdown_gunfire at maximum damage.");
	hCvarSdMacMod = CreateConVar("l4d2_slowdown_mac_percent", "0.8", "Silenced Uzis cause this much slowdown * l4d2_slowdown_gunfire at maximum damage.");
	hCvarSdAkMod = CreateConVar("l4d2_slowdown_ak_percent", "0.8", "AKs cause this much slowdown * l4d2_slowdown_gunfire at maximum damage.");
	hCvarSdM4Mod = CreateConVar("l4d2_slowdown_m4_percent", "0.8", "M4s cause this much slowdown * l4d2_slowdown_gunfire at maximum damage.");
	hCvarSdScarMod = CreateConVar("l4d2_slowdown_scar_percent", "0.8", "Scars cause this much slowdown * l4d2_slowdown_gunfire at maximum damage.");
	hCvarSdPumpMod = CreateConVar("l4d2_slowdown_pump_percent", "0.5", "Pump Shotguns cause this much slowdown * l4d2_slowdown_gunfire at maximum damage.");
	hCvarSdChromeMod = CreateConVar("l4d2_slowdown_chrome_percent", "0.5", "Chrome Shotguns cause this much slowdown * l4d2_slowdown_gunfire at maximum damage.");
	hCvarSdAutoMod = CreateConVar("l4d2_slowdown_auto_percent", "0.5", "Auto Shotguns cause this much slowdown * l4d2_slowdown_gunfire at maximum damage.");
	hCvarSdRifleMod = CreateConVar("l4d2_slowdown_rifle_percent", "0.1", "Hunting Rifles cause this much slowdown * l4d2_slowdown_gunfire at maximum damage.");
	hCvarSdScoutMod = CreateConVar("l4d2_slowdown_scout_percent", "0.1", "Scouts cause this much slowdown * l4d2_slowdown_gunfire at maximum damage.");
	hCvarSdMilitaryMod = CreateConVar("l4d2_slowdown_military_percent", "0.1", "Military Rifles cause this much slowdown * l4d2_slowdown_gunfire at maximum damage.");

	hCvarSurvivorLimpspeed = FindConVar("survivor_limp_health");
	hCvarTankSpeedVS = FindConVar("z_tank_speed_vs");
	
	hCvarSdInwaterTank.AddChangeHook(OnConVarChanged);
	hCvarSdInwaterSurvivor.AddChangeHook(OnConVarChanged);
	hCvarSdInwaterDuringTank.AddChangeHook(OnConVarChanged);
	hCvarTankSpeedVS.AddChangeHook(OnConVarChanged);

	HookEvent("tank_spawn", TankSpawn, EventHookMode_PostNoCopy);
	HookEvent("round_start", RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_hurt", PlayerHurt);
	HookEvent("player_death", TankDeath);
}

public void OnConfigsExecuted()
{
	CvarsToType();
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	CvarsToType();
}

void CvarsToType()
{
	fTankWaterSpeed = hCvarSdInwaterTank.FloatValue;
	fSurvWaterSpeed = hCvarSdInwaterSurvivor.FloatValue;
	fSurvWaterSpeedDuringTank = hCvarSdInwaterDuringTank.FloatValue;
	fTankRunSpeed = hCvarTankSpeedVS.FloatValue;
}

public Action TankSpawn(Event event, const char[] name, bool dontBroadcast) 
{
	if (!tankInPlay) {
		tankInPlay = true;
		if (fSurvWaterSpeedDuringTank > 0.0) {
			PrintToChatAll("\x05Water Slowdown\x01 has been reduced while Tank is in play.");
		}
	}
}

public Action TankDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0 && IsInfected(client) && IsTank(client)) {
		CreateTimer(0.1, Timer_CheckTank);
	}
}

public Action Timer_CheckTank(Handle timer)
{
	int tankclient = FindTankClient();
	if (!tankclient || !IsPlayerAlive(tankclient)) {
		tankInPlay = false;
		if (fSurvWaterSpeedDuringTank > 0.0) {
			PrintToChatAll("\x05Water Slowdown\x01 has been restored to normal.");
		}
	}
}

public Action RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	tankInPlay = false;
}

/**
 *
 * Slowdown from gunfire: Tank & SI
 *
**/
public Action PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0 && IsInfected(client)) {
		float slowdown = IsTank(client) ? GetActualValue(hCvarSdGunfireTank) : GetActualValue(hCvarSdGunfireSi);
		if (slowdown == 1.0) {
			ApplySlowdown(client, slowdown);
		} else if (slowdown > 0.0) {
			int damage = GetEventInt(event, "dmg_health");
			char weapon[64];
			GetEventString(event, "weapon", weapon, sizeof(weapon));

			float scale;
			float modifier;
			GetScaleAndModifier(scale, modifier, weapon, damage);
			ApplySlowdown(client, 1 - modifier * scale * slowdown);
		}
	}
}

/**
 *
 * Slowdown from water: Tank & Survivors
 *
**/
public Action L4D_OnGetRunTopSpeed(int client, float &retVal)
{
	if (!IsClientInGame(client)) { 
		return Plugin_Continue;
	}
	
	bool bInWater = (GetEntityFlags(client) & FL_INWATER) ? true : false;
	
	switch (GetClientTeam(client)) {
		case TEAM_SURVIVORS: {
			// Adrenaline = Don't care, don't mess with it.
			// Limping = 260 speed (both in water and on the ground)
			// Healthy = 260 speed (both in water and on the ground)
			bool bAdrenaline = GetEntProp(client, Prop_Send, "m_bAdrenalineActive") ? true : false;
			if (bAdrenaline) {
				return Plugin_Continue;
			}
			
			// Only bother if survivor is in water and healthy
			if (bInWater && !IsLimping(client)) {
				// speed of survivors in water during Tank fights
				if (tankInPlay) {
					if (fSurvWaterSpeedDuringTank == 0.0) {
						return Plugin_Continue; // Vanilla YEEEEEEEEEEEEEEEs
					} else {
						retVal = fSurvWaterSpeedDuringTank;
						return Plugin_Handled;
					}
				} else if (fSurvWaterSpeed != -1.0) { // speed of survivors in water outside of Tank fights
					// slowdown off
					if (fSurvWaterSpeed == 0.0) {
						retVal = SURVIVOR_RUNSPEED;
						return Plugin_Handled;
					} else { // specific speed
						retVal = fSurvWaterSpeed;
						return Plugin_Handled;
					}
				}
			}
		}
		case TEAM_INFECTED: {
			if (IsTank(client)) {
				// Only bother the actual speed if player is a tank moving in water
				if (bInWater && fTankWaterSpeed != -1.0) {
					// slowdown off
					if (fTankWaterSpeed == 0.0) {
						retVal = fTankRunSpeed;
						return Plugin_Handled;
					} else {// specific speed
						retVal = fTankWaterSpeed;
						return Plugin_Handled;
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

// The old slowdown plugin's cvars weren't quite intuitive, so I'll try to fix it this time
float GetActualValue(ConVar cvar)
{
	float value = GetConVarFloat(cvar);
	if (value == -1.0) { // native slowdown
		return -1.0;
	}
	
	if (value == 0.0) { // slowdown off
		return 1.0;
	}
	
	return L4D2Util_ClampFloat(value, 0.01, 2.0); // slowdown multiplier
}

void ApplySlowdown(int client, float value)
{
	if (value == -1.0) {
		return;
	}
	
	SetEntPropFloat(client, Prop_Send, "m_flVelocityModifier", value);
}

void GetScaleAndModifier(float &scale, float &modifier, const char[] weapon, int damage)
{
	// If max slowdown is 20%, and tank takes 10 damage from a chrome shotgun shell, they recieve:
	//// 1 - .5 * 0.434 * .2 = 0.9566 -> 95.6% base speed, or 4.4% slowdown.
	// If max slowdown is 20%, and tank takes 6 damage from a silenced uzi bullet, they recieve:
	//// 1 - .8 * 0.0625 * .2 = 0.99 -> 99% base speed, or 1% slowdown.

	// Weapon  | Max | Min
	// Pistol  | 32  | 9
	// Deagle  | 78  | 19
	// Uzi     | 19  | 9
	// Mac     | 24  | 0 <- Deals no damage at long range.
	// AK      | 57  | 0 <- Deals no damage at long range.
	// M4      | 32  | 0
	// Scar    | 43  | 1
	// Pump    | 13  | 2
	// Chrome  | 15  | 2
	// Auto    | 19  | 2
	// Spas    | 23  | 3
	// HR      | 90  | 90 <- No fall-off
	// Scout   | 90  | 90 <- No fall-off
	// Military| 90  | 90 <- No fall-off
	// SMGs and Shotguns are using quadratic scaling, meaning that shooting long ranged is punished more harshly.
	float fDamage = float(damage);
	if (strcmp(weapon, "melee") == 0) {
		// Melee damage scales with tank health, so don't bother handling it here.
		scale = 1.0;
		modifier = 0.0;
	} else if (strcmp(weapon, "pistol") == 0) {
		scale = fScaleFloat(fDamage, 9.0, 32.0);
		modifier = GetConVarFloat(hCvarSdPistolMod);
	} else if (strcmp(weapon, "pistol_magnum") == 0) {
		scale = fScaleFloat(fDamage, 19.0, 78.0);
		modifier = GetConVarFloat(hCvarSdDeagleMod);
	} else if (strcmp(weapon, "smg") == 0) {
		scale = fScaleFloat2(fDamage, 9.0, 19.0);
		modifier = GetConVarFloat(hCvarSdUziMod);
	} else if (strcmp(weapon, "smg_silenced") == 0) {
		scale = fScaleFloat2(fDamage, 0.0, 24.0);
		modifier = GetConVarFloat(hCvarSdMacMod);
	} else if (strcmp(weapon, "rifle_ak47") == 0) {
		scale = fScaleFloat2(fDamage, 0.0, 57.0);
		modifier = GetConVarFloat(hCvarSdAkMod);
	} else if (strcmp(weapon, "rifle") == 0) {
		scale = fScaleFloat2(fDamage, 0.0, 32.0);
		modifier = GetConVarFloat(hCvarSdM4Mod);
	} else if (strcmp(weapon, "rifle_desert") == 0) {
		scale = fScaleFloat2(fDamage, 1.0, 43.0);
		modifier = GetConVarFloat(hCvarSdScarMod);
	} else if (strcmp(weapon, "pumpshotgun") == 0) {
		scale = fScaleFloat2(fDamage, 2.0, 13.0);
		modifier = GetConVarFloat(hCvarSdPumpMod);
	} else if (strcmp(weapon, "shotgun_chrome") == 0) {
		scale = fScaleFloat2(fDamage, 2.0, 15.0);
		modifier = GetConVarFloat(hCvarSdChromeMod);
	} else if (strcmp(weapon, "autoshotgun") == 0) {
		scale = fScaleFloat2(fDamage, 2.0, 19.0);
		modifier = GetConVarFloat(hCvarSdAutoMod);
	} else if (strcmp(weapon, "shotgun_spas") == 0) {
		scale = fScaleFloat2(fDamage, 3.0, 23.0);
		modifier = GetConVarFloat(hCvarSdAutoMod);
	} else if (strcmp(weapon, "hunting_rifle") == 0) {
		scale = fScaleFloat(fDamage, 90.0, 90.0);
		modifier = GetConVarFloat(hCvarSdRifleMod);
	} else if (strcmp(weapon, "sniper_scout") == 0) {
		scale = fScaleFloat(fDamage, 90.0, 90.0);
		modifier = GetConVarFloat(hCvarSdScoutMod);
	} else if (strcmp(weapon, "sniper_military") == 0) {
		scale = fScaleFloat(fDamage, 90.0, 90.0);
		modifier = GetConVarFloat(hCvarSdMilitaryMod);
	} else {
		scale = 1.0;
		modifier = 0.0;
	}
}

int FindTankClient()
{
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsInfected(i) || !IsTank(i) || !IsPlayerAlive(i)) {
			continue;
		}
		
		return i; // Found tank, return
	}
	return 0;
}

bool IsInfected(int client)
{
	return (IsClientInGame(client) && GetClientTeam(client) == TEAM_INFECTED);
}

bool IsTank(int client)
{
	return (GetEntProp(client, Prop_Send, "m_zombieClass") == Z_TANK);
}

bool IsLimping(int client)
{
	// Assume Clientchecks and the like have been done already
	int PermHealth = GetClientHealth(client);

	float buffer = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	float bleedTime = GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
	float decay = GetConVarFloat(FindConVar("pain_pills_decay_rate"));
	
	float fCalculations = buffer - (bleedTime * decay);
	float TempHealth = L4D2Util_ClampFloat(fCalculations, 0.0, 100.0); // buffer may be negative, also if pills bleed out then bleedTime may be too large.

	return RoundToFloor(PermHealth + TempHealth) < hCvarSurvivorLimpspeed.IntValue;
}

float fScaleFloat(float inc, float low, float high)
{
	/* @A1m:
	 * This macros has been removed because it is considered unsafe.
	 * Besides, there are problems when assembling in sourcemod 1.11.
	 * The compiler ignores the data type when assembling.
	 *
	 * Linear scale %0 between %1 and %2.
	 * #define SCALE(%0,%1,%2) CLAMP((%0-%1)/(%2-%1), 0.0, 1.0)
	*/
	float fCalculations = ((inc - low) / (high - low));
	return L4D2Util_ClampFloat(fCalculations, 0.0, 1.0);
}

float fScaleFloat2(float inc, float low, float high)
{
	/* @A1m:
	 * This macros has been removed because it is considered unsafe.
	 * Besides, there are problems when assembling in sourcemod 1.11.
	 * The compiler ignores the data type when assembling.
	 *
	 * Quadratic scale %0 between %1 and %2
	* #define SCALE2(%0,%1,%2) SCALE(%0*%0, %1*%1, %2*%2)
	*/
	return fScaleFloat((inc * inc), (low * low), (high * high));
}
