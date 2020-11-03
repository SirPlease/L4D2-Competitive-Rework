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
#include <sourcemod>
#include <sdkhooks>
#include <left4dhooks>

#pragma semicolon 1
#pragma newdecls required

// Force %0 to be between %1 and %2.
#define CLAMP(%0,%1,%2) (((%0) > (%2)) ? (%2) : (((%0) < (%1)) ? (%1) : (%0)))
// Linear scale %0 between %1 and %2.
#define SCALE(%0,%1,%2) CLAMP((%0-%1)/(%2-%1), 0.0, 1.0)
// Quadratic scale %0 between %1 and %2
#define SCALE2(%0,%1,%2) SCALE(%0*%0, %1*%1, %2*%2)

#define SURVIVOR_RUNSPEED		220.0
#define SURVIVOR_WATERSPEED_VS	170.0
#define TANK_RUNSPEED_VS		GetConVarFloat(FindConVar("z_tank_speed_vs"))

ConVar hCvarSdPistolMod;
ConVar hCvarSdDeagleMod;
ConVar hCvarSdUziMod;
ConVar hCvarSdMacMod;
ConVar hCvarSdAkMod;
ConVar hCvarSdM4Mod;
ConVar hCvarSdScarMod;
ConVar hCvarSdPumpMod;
ConVar hCvarSdChromeMod;
ConVar hCvarSdAutoMod;
ConVar hCvarSdRifleMod;
ConVar hCvarSdScoutMod;
ConVar hCvarSdMilitaryMod;

ConVar hCvarSdGunfireSi;
ConVar hCvarSdGunfireTank;
ConVar hCvarSdInwaterTank;
ConVar hCvarSdInwaterSurvivor;
ConVar hCvarSdInwaterDuringTank;
ConVar hCvarSurvivorLimpspeed;

bool tankInPlay = false;

float fModifier[MAXPLAYERS+1] = -1.0;

public Plugin myinfo =
{
	name = "L4D2 Slowdown Control",
	author = "Visor, Sir, darkid, Forgetest",
	version = "2.6.2",
	description = "Manages the water/gunfire slowdown for both teams",
	url = "https://github.com/ConfoglTeam/ProMod"
};

public void OnPluginStart()
{
	hCvarSdGunfireSi = CreateConVar("l4d2_slowdown_gunfire_si", "0.0", "Maximum slowdown from gunfire for SI (-1: native slowdown; 0.0: No slowdown, 0.01-1.0: 1%%-100%% slowdown)", FCVAR_NONE, true, -1.0, true, 1.0);
	hCvarSdGunfireTank = CreateConVar("l4d2_slowdown_gunfire_tank", "0.2", "Maximum slowdown from gunfire for the Tank (-1: native slowdown; 0.0: No slowdown, 0.01-1.0: 1%%-100%% slowdown)", FCVAR_NONE, true, -1.0, true, 1.0);
	hCvarSdInwaterTank = CreateConVar("l4d2_slowdown_water_tank", "-1", "Maximum tank speed in the water (-1: ignore setting; 0: default; 210: default Tank Speed)", FCVAR_NONE, true, -1.0);
	hCvarSdInwaterSurvivor = CreateConVar("l4d2_slowdown_water_survivors", "-1", "Maximum survivor speed in the water outside of Tank fights (-1: ignore setting; 0: default; 220: default Survivor speed)", FCVAR_NONE, true, -1.0);
	hCvarSdInwaterDuringTank = CreateConVar("l4d2_slowdown_water_survivors_during_tank", "0", "Maximum survivor speed in the water during Tank fights (0: ignore setting; 220: default Survivor speed)", FCVAR_NONE, true, 0.0);

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

	HookEvent("player_hurt", PlayerHurt);
	HookEvent("tank_spawn", TankSpawn);
	HookEvent("player_death", TankDeath);
	HookEvent("round_end", RoundEnd);
}

public void OnClientPutInServer(int client)
{
	fModifier[client] = -1.0;
}

public void OnClientDisconnect(int client)
{
	fModifier[client] = -1.0;
}

public Action TankSpawn(Event event, const char[] name, bool dontBroadcast) 
{
	if (!tankInPlay) 
	{
		tankInPlay = true;
		if (GetConVarFloat(hCvarSdInwaterDuringTank) > 0.0) 
		{
			PrintToChatAll("\x05Water Slowdown\x01 has been reduced while Tank is in play.");
		}
	}
}

public Action TankDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsInfected(client) && IsTank(client) && !FindTankClient()) 
	{
		tankInPlay = false;
		if (GetConVarFloat(hCvarSdInwaterDuringTank) > 0.0) {
		
			PrintToChatAll("\x05Water Slowdown\x01 has been restored to normal.");
		}
	}
}

public Action RoundEnd(Event event, const char[] name, bool dontBroadcast)
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
	if (IsInfected(client)) 
	{
		float slowdown = IsTank(client) ? GetActualValue(hCvarSdGunfireTank) : GetActualValue(hCvarSdGunfireSi);
		if (slowdown == 1.0)
		{
			ApplySlowdown(client, slowdown);
		}
		else if (slowdown > 0.0)
		{
			int damage = GetEventInt(event, "dmg_health");
			static char weapon[64];
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
 * Slowdown application: Infected & Survivors
 *
**/

public Action L4D_OnGetRunTopSpeed(int client, float &retVal)
{
	if (!IsClientInGame(client)) return Plugin_Continue;
	
	bool bInWater = (GetEntityFlags(client) & FL_INWATER) ? true : false;
	bool bAdrenaline = GetEntProp(client, Prop_Send, "m_bAdrenalineActive") ? true : false;
	
	if (IsSurvivor(client))
	{
		// Adrenaline = Don't care, don't mess with it.
		// Limping = 260 speed (both in water and on the ground)
		// Healthy = 260 speed (both in water and on the ground)
		if (bAdrenaline) 
		  return Plugin_Continue;

		// Only bother if survivor is in water and healthy
		if (bInWater && !IsLimping(client))
		{
			// speed of survivors in water during Tank fights
			if (tankInPlay && GetConVarFloat(hCvarSdInwaterDuringTank) > 0.0) 
			{
				retVal = GetConVarFloat(hCvarSdInwaterDuringTank);
				return Plugin_Handled;
			}
			
			// speed of survivors in water outside of Tank fights
			else if (GetConVarFloat(hCvarSdInwaterSurvivor) != -1.0)
			{
				// slowdown off
				if (GetConVarFloat(hCvarSdInwaterSurvivor) == 0.0)
				{
					retVal = SURVIVOR_RUNSPEED;
					return Plugin_Handled;
				}
					
				// specific speed
				else
				{
					retVal = GetConVarFloat(hCvarSdInwaterSurvivor);
					return Plugin_Handled;
				}
			}
		}
	}
	
	else if (IsInfected(client)) 
	{
		// boolean to store whether the speed is changed (probably no need, but for safety)
		bool bOverride = false;
		
		// Only bother the actual speed if player is a tank moving in water
		if (bInWater && IsTank(client) && GetConVarFloat(hCvarSdInwaterTank) != -1.0)
		{
			// slowdown off
			if (GetConVarFloat(hCvarSdInwaterTank) == 0.0)
			{
				retVal = TANK_RUNSPEED_VS;
				bOverride = true;
			}
			
			// specific speed
			else
			{
				retVal = GetConVarFloat(hCvarSdInwaterTank);
				bOverride = true;
			}
		}
		
		// The player (SI or Tank) is getting slowdown due to gunfire
		if (fModifier[client] != -1.0)
		{
			retVal *= fModifier[client];
			fModifier[client] = -1.0;
			bOverride = true;
		}
		
		// The final value is either changed or unchanged
		if (bOverride) return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

// The old slowdown plugin's cvars weren't quite intuitive, so I'll try to fix it this time
float GetActualValue(ConVar cvar)
{
	float value = GetConVarFloat(cvar);
	if (value == -1.0)  // native slowdown
		return -1.0;
		
	if (value == 0.0)   // slowdown off
		return 1.0;

	return CLAMP(value, 0.01, 2.0); // slowdown multiplier
}

void ApplySlowdown(int client, float value)
{
	if (value == -1.0)
		return;

	// Await to be checked and used in L4D_OnGetRunTopSpeed
	fModifier[client] = value;
	
	// We don't need this old-school method anymore,
	// in which any speed is affected, such as jumping speed.
	
	//SetEntPropFloat(client, Prop_Send, "m_flVelocityModifier", value);
}

stock int FindTankClient()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsInfected(i) || !IsTank(i) || !IsPlayerAlive(i))
			continue;

		return i; // Found tank, return
	}
	return 0;
}

bool IsSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

bool IsInfected(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3;
}

bool IsTank(int client)
{
	return GetEntProp(client, Prop_Send, "m_zombieClass") == 8;
}

bool IsLimping(int client)
{
	// Assume Clientchecks and the like have been done already
	int PermHealth = GetClientHealth(client);

	float buffer = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	float bleedTime = GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
	float decay = GetConVarFloat(FindConVar("pain_pills_decay_rate"));

	float TempHealth = CLAMP(buffer - (bleedTime * decay), 0.0, 100.0); // buffer may be negative, also if pills bleed out then bleedTime may be too large.

	return RoundToFloor(PermHealth + TempHealth) < GetConVarInt(hCvarSurvivorLimpspeed);
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
	if (strcmp(weapon, "melee") == 0) 
	{
		// Melee damage scales with tank health, so don't bother handling it here.
		scale = 1.0;
		modifier = 0.0;
	}
	else if (strcmp(weapon, "pistol") == 0)
	{
		scale = SCALE(damage, 9.0, 32.0);
		modifier = GetConVarFloat(hCvarSdPistolMod);
	}
	else if (strcmp(weapon, "pistol_magnum") == 0)
	{
		scale = SCALE(damage, 19.0, 78.0);
		modifier = GetConVarFloat(hCvarSdDeagleMod);
	}
	else if (strcmp(weapon, "smg") == 0)
	{
		scale = SCALE2(damage, 9.0, 19.0);
		modifier = GetConVarFloat(hCvarSdUziMod);
	}
	else if (strcmp(weapon, "smg_silenced") == 0)
	{
		scale = SCALE2(damage, 0.0, 24.0);
		modifier = GetConVarFloat(hCvarSdMacMod);
	}
	else if (strcmp(weapon, "rifle_ak47") == 0)
	{
		scale = SCALE2(damage, 0.0, 57.0);
		modifier = GetConVarFloat(hCvarSdAkMod);
	}
	else if (strcmp(weapon, "rifle") == 0)
	{
		scale = SCALE2(damage, 0.0, 32.0);
		modifier = GetConVarFloat(hCvarSdM4Mod);
	}
	else if (strcmp(weapon, "rifle_desert") == 0)
	{
		scale = SCALE2(damage, 1.0, 43.0);
		modifier = GetConVarFloat(hCvarSdScarMod);
	}
	else if (strcmp(weapon, "pumpshotgun") == 0)
	{
		scale = SCALE2(damage, 2.0, 13.0);
		modifier = GetConVarFloat(hCvarSdPumpMod);
	}
	else if (strcmp(weapon, "shotgun_chrome") == 0)
	{
		scale = SCALE2(damage, 2.0, 15.0);
		modifier = GetConVarFloat(hCvarSdChromeMod);
	}
	else if (strcmp(weapon, "autoshotgun") == 0)
	{
		scale = SCALE2(damage, 2.0, 19.0);
		modifier = GetConVarFloat(hCvarSdAutoMod);
	}
	else if (strcmp(weapon, "shotgun_spas") == 0)
	{
		scale = SCALE2(damage, 3.0, 23.0);
		modifier = GetConVarFloat(hCvarSdAutoMod);
	}
	else if (strcmp(weapon, "hunting_rifle") == 0)
	{
		scale = SCALE(damage, 90.0, 90.0);
		modifier = GetConVarFloat(hCvarSdRifleMod);
	}
	else if (strcmp(weapon, "sniper_scout") == 0)
	{
		scale = SCALE(damage, 90.0, 90.0);
		modifier = GetConVarFloat(hCvarSdScoutMod);
	}
	else if (strcmp(weapon, "sniper_military") == 0)
	{
		scale = SCALE(damage, 90.0, 90.0);
		modifier = GetConVarFloat(hCvarSdMilitaryMod);
	}
	else
	{
		scale = 1.0;
		modifier = 0.0;
	}
}