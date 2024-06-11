/*
	SourcePawn is Copyright (C) 2006-2008 AlliedModders LLC.  All rights reserved.
	SourceMod is Copyright (C) 2006-2008 AlliedModders LLC.  All rights reserved.
	Pawn and SMALL are Copyright (C) 1997-2008 ITB CompuPhase.
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
#include <sdktools>
#include <sdkhooks>
#include <colors>


/*
* Version 0.1b
* - Catches Damage done to Witch
* - Prints to Chat on Witch Death.
* 
* Version 0.2b
* - Fixed Percentages not adding up to 100 because Damage doesn't equal Witch's health.
* - Prints Damage and Remaining Health when Witch Survives (Both when someone gets killed or when Witch incaps last person alive)
* 
* Version 1.0 <Public Release>
* - Fixed Damage Prints either being over or under Witch's Health
* - Only Show people that did damage to the Witch, the Witch is not something you need to gang up on.
* 
* Version 1.0a
* - Blocked SI Damage to Witch (Except for Tank) - This also fixes less than 1000 Damage/100 %
* - Allows Console Witch Spawns. (Doesn't support Multiple Witches at the same time)
* 
* Version 1.1
* - Added "Tank-Kill" Notifier when Tank kills Witch.
* - Added Cvar to enable or disable SI from causing the witch to get startled. (FF to Witch is always blocked)
* 
* Version 1.1b
* - Last Fix for Damage/Percentages; not adding up to 1000/100%.
* - Changed print format a bit.
* 
* Version 1.1c
* - Removed the witch FF code since it logically belongs to the si_ff_block plugin
*
* Version 1.2
* - Color Prints!
*/

new const TEAM_SURVIVOR = 2;
static const String:CLASSNAME_WITCH[]  	= "witch";


new bool: bRoundOver;                //Did Round End?
new bool: bWitchSpawned;             //Did Witch Spawn?
new bool: bHasPrinted;               //Did we Print?
new iDamageWitch[MAXPLAYERS + 1];    //Damage done to Witch, client tracking.
new DamageWitchTotal;                //Total Damage done to Witch.

//Witch's Standard health
new Float: g_fWitchHealth            = 1000.0;    

//In case a CFG uses a different Witch Health, adjust to it.
new Handle: g_hCvarWitchHealth       = INVALID_HANDLE;

//Survivor Array - Store Survivors in here for Damage Print.
new g_iSurvivorLimit = 4;   

//Handles Cvars
new Handle:cvar_witch_true_damage;

public Plugin:myinfo = 
{
	name = "Witch Damage Announce",
	author = "Sir",
	description = "Print Witch Damage to chat",
	version = "1.2",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
}

public OnPluginStart()
{
	cvar_witch_true_damage=CreateConVar("witch_show_true_damage", "0", "Show damage output rather than actual damage the witch receives? - 0 = Health Damage");

	//In case Witch survives.
	HookEvent("player_death", PlayerDied_Event, EventHookMode_Post);
	HookEvent("round_start", RoundStart_Event, EventHookMode_PostNoCopy);
	HookEvent("round_end", RoundEnd_Event, EventHookMode_PostNoCopy);

	//Get Witch's Health in case Config has a different health value.
	g_hCvarWitchHealth = FindConVar("z_witch_health");

	//Damage Calculation & Death Print.
	HookEvent("infected_hurt", WitchHurt_Event, EventHookMode_Post);
	HookEvent("witch_killed", WitchDeath_Event, EventHookMode_Post);
}

public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual(classname, CLASSNAME_WITCH, false))
	{
		//Get Health
		bWitchSpawned = true;
		bHasPrinted = false;
		g_fWitchHealth = GetConVarFloat(g_hCvarWitchHealth);
	}
}

public WitchHurt_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Catch damage done to Witch
	new victimEntId = GetEventInt(event, "entityid");

	if (IsWitch(victimEntId))
	{
		new attackerId = GetEventInt(event, "attacker");
		new attacker = GetClientOfUserId(attackerId);
		new damageDone = GetEventInt(event, "amount");
		
		// Just count Survivor Damage
		
		if (IsValidClient(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR)
		{
			DamageWitchTotal += damageDone;
			
			//If Damage is higher than Max Health, Adjust.
			if (!GetConVarBool(cvar_witch_true_damage) && DamageWitchTotal > g_fWitchHealth) iDamageWitch[attacker] += (damageDone - (DamageWitchTotal - RoundToFloor(g_fWitchHealth)));
			else iDamageWitch[attacker] += damageDone;	
		}
	}
}

public RoundStart_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Clear Witch Damage
	ClearDamage();

	//Fresh Start
	bRoundOver = false;
	bWitchSpawned = false;
	bHasPrinted = false;
}

public RoundEnd_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (bWitchSpawned)
	{
		bRoundOver = true;
		
		if(DamageWitchTotal > 0) CalculateWitch();
		
		bWitchSpawned = false;
	}
}

public WitchDeath_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new killerId = GetEventInt(event, "userid");
	new killer = GetClientOfUserId(killerId);

	//Check if Tank Killed the Witch.
	if (IsValidClient(killer) && GetClientTeam(killer) == 3 && IsTank(killer))
	{
		CPrintToChatAll("{default}[{green}!{default}] {red}Tank {default}({olive}%N{default}) killed the {red}Witch", killer);
		bWitchSpawned = false;
		ClearDamage();
		return;
	}

	//If Damage is lower than Max Health, Adjust.
	if (DamageWitchTotal < g_fWitchHealth)
	{
		iDamageWitch[killer] += (RoundToFloor(g_fWitchHealth - DamageWitchTotal));
		DamageWitchTotal = RoundToFloor(g_fWitchHealth);
	}

	if (!bRoundOver)
	{	
		bWitchSpawned = false;
		CalculateWitch();
		ClearDamage();
	}
}

public PlayerDied_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userId = GetEventInt(event, "userid");
	new victim = GetClientOfUserId(userId);
	new attacker = GetEventInt(event, "attackerentid");

	if (IsClientAndInGame(victim) && GetClientTeam(victim) == TEAM_SURVIVOR && IsWitch(attacker))
	{
		//Delayed Timer in case Witch gets killed while she's running off.
		CreateTimer(3.0, PrintAnyway)
	}
}

public Action:PrintAnyway(Handle:timer)
{
    CalculateWitch();
    ClearDamage();
}

CalculateWitch()
{
	if (bHasPrinted) return;

	if (!bRoundOver && !bWitchSpawned) PrintWitchDamage();
	else
	{
		PrintWitchRemainingHealth();
		PrintWitchDamage();
	}
	bHasPrinted = true;
}

PrintWitchRemainingHealth()
{
	CPrintToChatAll("{default}[{green}!{default}] {blue}Witch {default}had {olive}%d {default}health remaining", RoundToFloor(g_fWitchHealth) - DamageWitchTotal);
}

PrintWitchDamage()
{
	if (!bWitchSpawned)
	{
		CPrintToChatAll("{default}[{green}!{default}] {blue}Damage {default}dealt to {blue}Witch:");
	}

	new client;
	new percent_total; // Accumulated total of calculated percents, for fudging out numbers at the end
	new damage_total; // Accumulated total damage dealt by survivors, to see if we need to fudge upwards to 100%
	new survivor_index = -1;
	new survivor_clients[g_iSurvivorLimit]; // Array to store survivor client indexes in, for the display iteration
	decl percent_damage, damage;

	for (client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || GetClientTeam(client) != TEAM_SURVIVOR || iDamageWitch[client] == 0)  continue;
		survivor_index++;
		survivor_clients[survivor_index] = client;
		damage = iDamageWitch[client];
		damage_total += damage;
		percent_damage = GetDamageAsPercent(damage);
		percent_total += percent_damage;
	}
	SortCustom1D(survivor_clients, g_iSurvivorLimit, SortByDamageDesc);

	new percent_adjustment;
	// Percents add up to less than 100% AND > 99.5% damage was dealt to witch
	if ((percent_total < 100 && float(damage_total) > (g_fWitchHealth - (g_fWitchHealth / 200.0))))
	{
		percent_adjustment = 100 - percent_total;
	}

	new last_percent = 100; // Used to store the last percent in iteration to make sure an adjusted percent doesn't exceed the previous percent
	decl adjusted_percent_damage;
	for (new k; k <= survivor_index; k++)
	{
		client = survivor_clients[k];
		damage = iDamageWitch[client];
		percent_damage = GetDamageAsPercent(damage);
		// Attempt to adjust the top damager's percent, defer adjustment to next player if it's an exact percent
		if (percent_adjustment != 0 && // Is there percent to adjust
		damage > 0 &&  // Is damage dealt > 0%
		!IsExactPercent(damage) // Percent representation is not exact.
		)
		{
			adjusted_percent_damage = percent_damage + percent_adjustment;
			if (adjusted_percent_damage <= last_percent) // Make sure adjusted percent is not higher than previous percent, order must be maintained
			{
				percent_damage = adjusted_percent_damage;
				percent_adjustment = 0;
			}
		}
		last_percent = percent_damage;
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				CPrintToChat(i, "{blue}[{default}%d{blue}] ({default}%i%%{blue}) {olive}%N", damage, percent_damage, client);
			}
		}
	}
}

stock bool:IsWitch(iEntity)
{
	if(iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
	{
		decl String:strClassName[64];
		GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
		return StrEqual(strClassName, "witch");
	}
	return false;
}

stock bool:IsClientAndInGame(index)
{
	return (index > 0 && index <= MaxClients && IsClientInGame(index));
}

int GetDamageAsPercent(int damage)
{
	return RoundToNearest((damage / g_fWitchHealth) * 100.0);
}

//comparing the type of int with the float, how different is it
bool IsExactPercent(int damage)
{
	float fDamageAsPercent = (damage / g_fWitchHealth) * 100.0;
	float fDifference = float(GetDamageAsPercent(damage)) - fDamageAsPercent;
	return (FloatAbs(fDifference) < 0.001) ? true : false;
}

stock bool IsTank(int client)
{
	return (GetEntProp(client, Prop_Send, "m_zombieClass") == 8);
}

bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
}

public SortByDamageDesc(elem1, elem2, const array[], Handle:hndl)
{
	// By damage, then by client index, descending
	if (iDamageWitch[elem1] > iDamageWitch[elem2]) return -1;
	else if (iDamageWitch[elem2] > iDamageWitch[elem1]) return 1;
	else if (elem1 > elem2) return -1;
	else if (elem2 > elem1) return 1;
	return 0;
}

ClearDamage()
{
	new i, maxplayers = MaxClients;
	for (i = 1; i <= maxplayers; i++) iDamageWitch[i] = 0;
	DamageWitchTotal = 0;
}
