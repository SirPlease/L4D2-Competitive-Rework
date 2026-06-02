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
*
* Version 1.3
* - Mulit Witch Damage Announce Support!
* - Translation Support!
*/

const TEAM_SURVIVOR = 2;
const TEAM_INFECTED = 3;
static const String:CLASSNAME_WITCH[]  	= "witch";


bool bRoundOver;                //Did Round End?
//new bool: bWitchSpawned;             //Did Witch Spawn?
//new bool: bHasPrinted;               //Did we Print?
//new iDamageWitch[MAXPLAYERS + 1];    //Damage done to Witch, client tracking.
//new DamageWitchTotal;                //Total Damage done to Witch.


//Witch's Standard health
//new Float: g_fWitchHealth            = 1000.0;    

//In case a CFG uses a different Witch Health, adjust to it.
Handle g_hCvarWitchHealth       = INVALID_HANDLE;

//Survivor Array - Store Survivors in here for Damage Print.
int g_iSurvivorLimit = 4;   

//Handles Cvars
Handle cvar_witch_true_damage;
int WitchNum = 0;
enum struct WitchDetail{
	int iDamageWitch[MAXPLAYERS + 1];
	int DamageWitchTotal;                //Total Damage done to Witch.
	int DamageInfectedTeamTotal;
	int DamageTankTotal;
	int EntityIndex;
	int KilledClient; //击杀Witch的玩家
	bool bWitchSpawned;
	bool bHasPrinted;
	bool bIsTankKilled; //是不是Tank击杀的Witch
	float fWitchHealth;
	void SpawnInit(int index){
		for(int i = 0; i < MAXPLAYERS; i++)
		{
			this.iDamageWitch[i] = 0;
		}
		this.EntityIndex = index;
		this.DamageWitchTotal = 0;
		this.DamageInfectedTeamTotal = 0;
		this.DamageTankTotal = 0;
		this.KilledClient = 0;
		this.bWitchSpawned = true;
		this.bHasPrinted = false;
		this.bIsTankKilled = false;
		this.fWitchHealth = GetConVarFloat(g_hCvarWitchHealth);
	}
	void ClearDamage()
	{
		for(int i = 0; i < MAXPLAYERS; i++)
		{
			this.iDamageWitch[i] = 0;
		}
		this.DamageWitchTotal = 0;
		this.DamageInfectedTeamTotal = 0;
		this.DamageTankTotal = 0;
	}
	void ResetStatus()
	{
		this.bWitchSpawned = false;
		this.bHasPrinted = false;
		this.bIsTankKilled = false;
		this.KilledClient = 0;
		this.EntityIndex = 0;
		//this.fWitchHealth = 1000.0;
	}
	void CalculateWitch()
	{
		if (this.bHasPrinted) return;
	
		if (!bRoundOver && !this.bWitchSpawned) this.PrintWitchDamage();
		else
		{
			this.PrintWitchRemainingHealth();
			this.PrintWitchDamage();
		}
		this.bHasPrinted = true;
	}

	void PrintWitchRemainingHealth()
	{
		CPrintToChatAll("%t", "WitchRemainedHealth", RoundToFloor(this.fWitchHealth) - this.DamageWitchTotal);
	}

	void PrintWitchDamage()
	{
		//没打出伤害，不显示伤害列表
		if (this.DamageWitchTotal == 0)
			return;
			
		if (!this.bWitchSpawned && this.DamageTankTotal < 1000)
		{
			CPrintToChatAll("%t", "DamageToWitch");
		}

		int client;
		int percent_total; // Accumulated total of calculated percents, for fudging out numbers at the end
		int damage_total; // Accumulated total damage dealt by survivors, to see if we need to fudge upwards to 100%
		int survivor_index = -1;
		int survivor_clients[4]; // Array to store survivor client indexes in, for the display iteration
		int percent_damage, damage;
	
		for (client = 1; client <= MaxClients; client++)
		{
			if (!IsClientInGame(client) || GetClientTeam(client) != TEAM_SURVIVOR || this.iDamageWitch[client] == 0)  continue;
			survivor_index++;
			survivor_clients[survivor_index] = client;
			damage = this.iDamageWitch[client];
			damage_total += damage;
			percent_damage = this.GetDamageAsPercent(damage);
			percent_total += percent_damage;
		}
		//自定义Witch伤害排序
		SortWitchDamageIndex(this.EntityIndex, survivor_clients, g_iSurvivorLimit);
		//增加Infected和Tank的伤害统计
		if(this.DamageInfectedTeamTotal > 0)
		{
			damage = this.DamageInfectedTeamTotal;
			damage_total += damage;
			percent_damage = this.GetDamageAsPercent(damage);
			percent_total += percent_damage;
		}
		if(this.DamageTankTotal > 0)
		{
			damage = this.DamageTankTotal;
			damage_total += damage;
			percent_damage = this.GetDamageAsPercent(damage);
			percent_total += percent_damage;
		}
		
		int percent_adjustment;
		// Percents add up to less than 100% AND > 99.5% damage was dealt to witch
		if ((percent_total < 100 && float(damage_total) > (this.fWitchHealth - (this.fWitchHealth / 200.0))))
		{
			percent_adjustment = 100 - percent_total;
		}
	
		int last_percent = 100; // Used to store the last percent in iteration to make sure an adjusted percent doesn't exceed the previous percent
		int adjusted_percent_damage;
		for (int k; k <= survivor_index; k++)
		{
			client = survivor_clients[k];
			damage = this.iDamageWitch[client];
			percent_damage = this.GetDamageAsPercent(damage);
			// Attempt to adjust the top damager's percent, defer adjustment to next player if it's an exact percent
			if (percent_adjustment != 0 && // Is there percent to adjust
			damage > 0 &&  // Is damage dealt > 0%
			!this.IsExactPercent(damage) // Percent representation is not exact.
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
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i))
				{
					if(damage == 1000)
					{
						CPrintToChat(i, "%t", "PrefectWitchCrown", damage, percent_damage, client);
					}
					else if(IsValidClient(this.KilledClient) && client == this.KilledClient)
					{
						CPrintToChat(i, "%t", "FinalShotWitchCrown", damage, percent_damage, client);
					}
					else
						CPrintToChat(i, "%t", "AssistanceWitchCrown", damage, percent_damage, client);
				}
			}			
		}
		if(this.DamageInfectedTeamTotal > 0)
		{
			if(IsValidClient(this.KilledClient) && GetClientTeam(this.KilledClient) == 3 && !this.bIsTankKilled)
				CPrintToChatAll("%t", "FinalShotInfWitchCrown", this.DamageInfectedTeamTotal, this.GetDamageAsPercent(this.DamageInfectedTeamTotal), this.KilledClient);
			else
				CPrintToChatAll("%t", "AssistanceInfWitchCrown", this.DamageInfectedTeamTotal, this.GetDamageAsPercent(this.DamageInfectedTeamTotal));
		}
		if(this.DamageTankTotal > 0)
		{
			if(this.bIsTankKilled)
				CPrintToChatAll("%t", "FinalShotTankWitchCrown", this.DamageTankTotal, this.GetDamageAsPercent(this.DamageTankTotal));
			else
				CPrintToChatAll("%t", "AssistanceTankWitchCrown", this.DamageTankTotal, this.GetDamageAsPercent(this.DamageTankTotal));
		}
		//CPrintToChatAll("{blue}[{default}WitchNum: {blue}%d] ({default}Entityid:{blue}%d) ", WitchNum, this.EntityIndex);
	}
	
	int GetDamageAsPercent(int damage)
	{
		return RoundToNearest((damage / this.fWitchHealth) * 100.0);
	}
	
	//comparing the type of int with the float, how different is it
	bool IsExactPercent(int damage)
	{
		float fDamageAsPercent = (damage / this.fWitchHealth) * 100.0;
		float fDifference = float(this.GetDamageAsPercent(damage)) - fDamageAsPercent;
		return (FloatAbs(fDifference) < 0.001) ? true : false;
	}
}
WitchDetail witch[512];

public Plugin:myinfo = 
{
	name = "Witch Damage Announce",
	author = "Sir, morzlee",
	description = "Print Witch Damage to chat",
	version = "1.3",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
}

#define TRANSLATION_FILE "witch_damage_announce.phrases"
void LoadPluginTranslations()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "translations/"...TRANSLATION_FILE...".txt");
	if (!FileExists(sPath))
	{
		SetFailState("Missing translation \""...TRANSLATION_FILE..."\"");
	}
	LoadTranslations(TRANSLATION_FILE);
}

public OnPluginStart()
{
	LoadPluginTranslations();
	cvar_witch_true_damage=CreateConVar("witch_show_true_damage", "0", "Show damage output rather than actual damage the witch receives? - 0 = Health Damage");

	//In case Witch survives.
	HookEvent("player_death", PlayerDied_Event, EventHookMode_Post);
	HookEvent("round_start", RoundStart_Event, EventHookMode_PostNoCopy);
	HookEvent("round_end", RoundEnd_Event, EventHookMode_PostNoCopy);
	
	
//	HookEvent("witch_spawn", Event_WitchSpawn, EventHookMode_Post);

	//Get Witch's Health in case Config has a different health value.
	g_hCvarWitchHealth = FindConVar("z_witch_health");

	//Damage Calculation & Death Print.
	HookEvent("player_incapacitated", PlayerIncap_Event, EventHookMode_Post);
	HookEvent("infected_hurt", WitchHurt_Event, EventHookMode_Post);
	HookEvent("witch_killed", WitchDeath_Event, EventHookMode_Post);
}


public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual(classname, CLASSNAME_WITCH, false))
	{
		//Get Health
		//witch[entity].bWitchSpawned = true;
		//witch[entity].bHasPrinted = false;
		//witch[entity].g_fWitchHealth = GetConVarFloat(g_hCvarWitchHealth);
		witch[WitchNum].SpawnInit(entity);
		//CPrintToChatAll("{blue}Witch生成，WitchNum为：%d %d %d",WitchNum, entity, witch[WitchNum].EntityIndex);
		WitchNum++;
	}
}


public void Event_WitchSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int iWitch = event.GetInt("witchid");
	witch[iWitch].SpawnInit(iWitch);
	//CPrintToChatAll("{blue}Witch生成，WitchNum为：%d %d %d",WitchNum, iWitch, witch[WitchNum].EntityIndex);
	WitchNum++;
}

public int FindIndexByEntityid(int entityid)
{
	for(int i = 0; i < WitchNum; i++)
	{
		if(witch[i].EntityIndex == entityid)
			return i;
	}
	return 0;
}

public WitchHurt_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Catch damage done to Witch
	new victim = GetEventInt(event, "entityid");
	
	if (IsWitch(victim))
	{
		new attackerId = GetEventInt(event, "attacker");
		new attacker = GetClientOfUserId(attackerId);
		new damageDone = GetEventInt(event, "amount");
		int victimEntId = FindIndexByEntityid(victim);
		// Just count Survivor Damage
		
		if (IsValidClient(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR)
		{
			witch[victimEntId].DamageWitchTotal += damageDone;
			
			//If Damage is higher than Max Health, Adjust.
			if (!GetConVarBool(cvar_witch_true_damage) && witch[victimEntId].DamageWitchTotal > witch[victimEntId].fWitchHealth) witch[victimEntId].iDamageWitch[attacker] += (damageDone - (witch[victimEntId].DamageWitchTotal - RoundToFloor(witch[victimEntId].fWitchHealth)));
			else witch[victimEntId].iDamageWitch[attacker] += damageDone;	
		}
		
		//Add Infected Damage Calculate
		if (IsValidClient(attacker) && GetClientTeam(attacker) == TEAM_INFECTED && IsTank(attacker))
		{
			witch[victimEntId].DamageWitchTotal += damageDone;
			
			//If Damage is higher than Max Health, Adjust.
			if (!GetConVarBool(cvar_witch_true_damage) && witch[victimEntId].DamageWitchTotal > witch[victimEntId].fWitchHealth) witch[victimEntId].DamageTankTotal += (damageDone - (witch[victimEntId].DamageWitchTotal - RoundToFloor(witch[victimEntId].fWitchHealth)));
			else witch[victimEntId].DamageTankTotal += damageDone;	
		}
		if (IsValidClient(attacker) && GetClientTeam(attacker) == TEAM_INFECTED && !IsTank(attacker))
		{
			witch[victimEntId].DamageWitchTotal += damageDone;
			
			//If Damage is higher than Max Health, Adjust.
			if (!GetConVarBool(cvar_witch_true_damage) && witch[victimEntId].DamageWitchTotal > witch[victimEntId].fWitchHealth) witch[victimEntId].DamageInfectedTeamTotal += (damageDone - (witch[victimEntId].DamageWitchTotal - RoundToFloor(witch[victimEntId].fWitchHealth)));
			else witch[victimEntId].DamageInfectedTeamTotal += damageDone;	
		}
	}
}

public RoundStart_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Clear Witch Damage
	//ClearDamage();
	for(int i = 0; i < WitchNum; i++)
		if(IsWitch(i))
		{
			witch[i].ClearDamage();
			witch[i].ResetStatus();
		}
			

	//Fresh Start
	bRoundOver = false;
	WitchNum = 0;
	//bWitchSpawned = false;
	//bHasPrinted = false;
}

public RoundEnd_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	bRoundOver = true;
	for(int i = 0; i < WitchNum; i++)
	{
		if (witch[WitchNum].bWitchSpawned)
		{
			if(IsWitch(witch[i].EntityIndex))
			{
				if(witch[i].DamageWitchTotal > 0) witch[i].CalculateWitch();
				witch[i].bWitchSpawned = false;
			}
		}
	}
	WitchNum = 0;
}

public WitchDeath_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new killerId = GetEventInt(event, "userid");
	new killer = GetClientOfUserId(killerId);
	if (!IsValidClient(killer))
		return;
	new witchtemp = GetEventInt(event, "witchid");
	int witchEntity = FindIndexByEntityid(witchtemp);
	//If Damage is lower than Max Health, Adjust.
	if (witch[witchEntity].DamageWitchTotal < witch[witchEntity].fWitchHealth)
	{
		if(GetClientTeam(killer) == TEAM_SURVIVOR){
			witch[witchEntity].iDamageWitch[killer] += (RoundToFloor(witch[witchEntity].fWitchHealth - witch[witchEntity].DamageWitchTotal));
			witch[witchEntity].DamageWitchTotal = RoundToFloor(witch[witchEntity].fWitchHealth);
		}
		if(GetClientTeam(killer) == TEAM_INFECTED)
		{
			if(IsTank(killer))
			{
				witch[witchEntity].DamageTankTotal += (RoundToFloor(witch[witchEntity].fWitchHealth - witch[witchEntity].DamageWitchTotal));
				witch[witchEntity].bIsTankKilled = true;
			}		
			else
			{
				witch[witchEntity].DamageInfectedTeamTotal += (RoundToFloor(witch[witchEntity].fWitchHealth - witch[witchEntity].DamageWitchTotal));
			}			
			witch[witchEntity].DamageWitchTotal = RoundToFloor(witch[witchEntity].fWitchHealth);
		}
	}
	witch[witchEntity].KilledClient = killer;
	
	//Check if Tank Killed the Witch.
	if (IsValidClient(killer) && GetClientTeam(killer) == 3 && IsTank(killer))
	{
		if(witch[witchEntity].DamageTankTotal == 1000)
			CPrintToChatAll("%t", "TankKillWitch", killer);
		witch[witchEntity].bWitchSpawned = false;
		witch[witchEntity].CalculateWitch();
		witch[witchEntity].ClearDamage();
		witch[witchEntity].ResetStatus();
		return;
	}
	if (!bRoundOver)
	{	
		witch[witchEntity].bWitchSpawned = false;
		witch[witchEntity].CalculateWitch();
		witch[witchEntity].ClearDamage();
		witch[witchEntity].ResetStatus();
	}
}

public PlayerIncap_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userId = GetEventInt(event, "userid");
	new victim = GetClientOfUserId(userId);
	new attackerid = GetEventInt(event, "attackerentid");
	//new attacker = GetClientOfUserId(attackerid);
	new num = FindIndexByEntityid(attackerid)
	if (IsClientAndInGame(victim) && GetClientTeam(victim) == TEAM_SURVIVOR && IsWitch(attackerid))
	{
		//显示猪鼻秒妹失败被挠倒了
		CPrintToChatAll("%t", "FailWitchCrown", victim);
		witch[num].PrintWitchRemainingHealth();
	}
}

public PlayerDied_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userId = GetEventInt(event, "userid");
	new victim = GetClientOfUserId(userId);
	new attackerid = GetEventInt(event, "attackerentid");
	new attacker = GetClientOfUserId(attackerid);
	
	if (IsClientAndInGame(victim) && GetClientTeam(victim) == TEAM_SURVIVOR && IsWitch(attackerid))
	{
		//Delayed Timer in case Witch gets killed while she's running off.
		CreateTimer(3.0, PrintAnyway, attacker)
	}
}

public Action:PrintAnyway(Handle:timer, int client)
{
    witch[client].CalculateWitch();
    witch[client].ClearDamage();
    witch[client].ResetStatus();
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


void SortWitchDamageIndex(int witchentity, int[] array, int array_size)
{
	int temp;
	int num = FindIndexByEntityid(witchentity);
	for(int i = 0; i < array_size; i++)
	{
		for(int j = i + 1; j < array_size; j++)
		{
			if(witch[num].iDamageWitch[array[i]] < witch[num].iDamageWitch[array[j]])
			{
				temp = array[i];
				array[i] = array[j];
				array[j]= temp;
			}
		}
	}	
}

