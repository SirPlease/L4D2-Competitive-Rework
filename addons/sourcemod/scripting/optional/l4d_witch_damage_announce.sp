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
* - Syntax Update
* - Remove comments for self explanatory code
* - Removed unnecessary code
* - Fix issues caused by relying on hardcoded values
*/

#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

bool
    bRoundOver,             
    bWitchSpawned,
    bHasPrinted;

int
    iDamageWitch[MAXPLAYERS + 1],
    damageWitchTotal,
    iSurvivorLimit;

float fHealthWitch;

ConVar 
    cvarWitchHealth,
    cvarSurvivorLimit;

public Plugin myinfo = 
{
    name = "Witch Damage Announce",
    author = "Sir",
    description = "Print Witch Damage to chat",
    version = "1.3",
    url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
}

public void OnPluginStart()
{
    HookEvent("player_death", PlayerDied_Event, EventHookMode_Post);
    HookEvent("round_start", RoundStart_Event, EventHookMode_PostNoCopy);
    HookEvent("round_end", RoundEnd_Event, EventHookMode_PostNoCopy);
    HookEvent("infected_hurt", WitchHurt_Event, EventHookMode_Post);
    HookEvent("witch_killed", WitchDeath_Event, EventHookMode_Post);

    cvarWitchHealth = FindConVar("z_witch_health");
    cvarSurvivorLimit = FindConVar("survivor_limit");
    fHealthWitch = cvarWitchHealth.FloatValue;
    iSurvivorLimit = cvarSurvivorLimit.IntValue;
    cvarWitchHealth.AddChangeHook(cvarChanged)
    cvarSurvivorLimit.AddChangeHook(cvarChanged)
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (StrContains(classname, "witch") != -1)
    {
        bWitchSpawned = true;
        bHasPrinted = false;
    }
}

public void WitchHurt_Event(Event hEvent, const char[] name, bool dontBroadcast)
{
    int victimEntId = hEvent.GetInt("entityid");

    if (IsWitch(victimEntId))
    {
        int attackerId = hEvent.GetInt("attacker");
        int attacker = GetClientOfUserId(attackerId);
        int damageDone = hEvent.GetInt("amount");
        
        if (IsClientAndInGame(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR)
        {
            int newTotalDamage = damageWitchTotal + damageDone;
            int health = RoundToFloor(fHealthWitch);
            damageDone = newTotalDamage > health ? damageDone - (newTotalDamage - health) : damageDone

            damageWitchTotal += damageDone;
            iDamageWitch[attacker] += damageDone;	
        }
    }
}

public void RoundStart_Event(Event hEvent, const char[] name, bool dontBroadcast)
{
    ClearDamage();

    bRoundOver = false;
    bWitchSpawned = false;
    bHasPrinted = false;
}

public void RoundEnd_Event(Event hEvent, const char[] name, bool dontBroadcast)
{
    if (bWitchSpawned)
    {
        bRoundOver = true;
        
        if(damageWitchTotal > 0) 
            CalculateWitch();

        bWitchSpawned = false;
    }
}

public void WitchDeath_Event(Event hEvent, const char[] name, bool dontBroadcast)
{
    int killerId = hEvent.GetInt("userid");
    int killer = GetClientOfUserId(killerId);

    //Check if Tank Killed the Witch.
    if (IsClientAndInGame(killer) && GetClientTeam(killer) == TEAM_INFECTED && IsTank(killer))
    {
        CPrintToChatAll("{default}[{green}!{default}] {red}Tank {default}({olive}%N{default}) killed the {red}Witch", killer);
        bWitchSpawned = false;
        ClearDamage();
        return;
    }

    //If Damage is lower than Max Health, Adjust.
    if (damageWitchTotal < fHealthWitch)
    {
        iDamageWitch[killer] += (RoundToFloor(fHealthWitch - damageWitchTotal));
        damageWitchTotal = RoundToFloor(fHealthWitch);
    }

    if (!bRoundOver)
    {	
        bWitchSpawned = false;
        CalculateWitch();
        ClearDamage();
    }
}

public void PlayerDied_Event(Event hEvent, const char[] name, bool dontBroadcast)
{
    int userId = hEvent.GetInt("userid");
    int victim = GetClientOfUserId(userId);
    int attacker = hEvent.GetInt("attackerentid");

    if (IsClientAndInGame(victim) && GetClientTeam(victim) == TEAM_SURVIVOR && IsWitch(attacker))
        CreateTimer(3.0, PrintAnyway)
}

Action PrintAnyway(Handle timer)
{
    CalculateWitch();
    ClearDamage();
    return Plugin_Stop;
}

void CalculateWitch()
{
    if (bHasPrinted) 
        return;

    if (!bRoundOver && !bWitchSpawned) 
        PrintWitchDamage();

    else
    {
        PrintWitchRemainingHealth();
        PrintWitchDamage();
    }

    bHasPrinted = true;
}

void PrintWitchRemainingHealth()
{
    CPrintToChatAll("{default}[{green}!{default}] {blue}Witch {default}had {olive}%d {default}health remaining", RoundToFloor(fHealthWitch) - damageWitchTotal);
}

void PrintWitchDamage()
{
    if (!bWitchSpawned)
    {
        CPrintToChatAll("{default}[{green}!{default}] {blue}Damage {default}dealt to {blue}Witch:");
    }

    int 
        totalPercent, totalDamage, survivorIndex,
        percentDamage, damage, percentAdjustment, adjustedPercentDamage;

    int[] survivorClients = new int[iSurvivorLimit]

    int lastPercent = 100;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || GetClientTeam(i) != TEAM_SURVIVOR || iDamageWitch[i] == 0) 
            continue;

        survivorClients[survivorIndex++] = i;
        damage = iDamageWitch[i];
        totalDamage += damage;
        percentDamage = GetDamageAsPercent(damage);
        totalPercent += percentDamage;
    }
    SortCustom1D(survivorClients, survivorIndex, SortByDamageDesc);

    // Percents add up to less than 100% AND > 99.5% damage was dealt to witch
    if ((totalPercent < 100 && float(totalDamage) > (fHealthWitch - (fHealthWitch / 200.0))))
    {
        percentAdjustment = 100 - totalPercent;
    }

    for (int k; k < survivorIndex; k++)
    {
        int client = survivorClients[k];
        damage = iDamageWitch[client];
        percentDamage = GetDamageAsPercent(damage);

        if (percentAdjustment != 0 && damage > 0 && !IsExactPercent(damage))
        {
            adjustedPercentDamage = percentDamage + percentAdjustment;
            if (adjustedPercentDamage <= lastPercent)
            {
                percentDamage = adjustedPercentDamage;
                percentAdjustment = 0;
            }
        }

        lastPercent = percentDamage;

        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i))
            {
                CPrintToChat(i, "{blue}[{default}%d{blue}] ({default}%i%%{blue}) {olive}%N", damage, percentDamage, client);
            }
        }
    }
}

bool IsWitch(int iEntity)
{
    if(iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
    {
        char strClassName[64];
        GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
        return StrContains(strClassName, "witch") != -1;
    }
    return false;
}

bool IsClientAndInGame(int index)
{
    return (index > 0 && index <= MaxClients && IsClientInGame(index));
}

int GetDamageAsPercent(int damage)
{
    return RoundToNearest((damage / fHealthWitch) * 100.0);
}

//comparing the type of int with the float, how different is it
bool IsExactPercent(int damage)
{
    float fDamageAsPercent = (damage / fHealthWitch) * 100.0;
    float fDifference = float(GetDamageAsPercent(damage)) - fDamageAsPercent;
    return (FloatAbs(fDifference) < 0.001) ? true : false;
}

bool IsTank(int client)
{
    return (GetEntProp(client, Prop_Send, "m_zombieClass") == 8);
}

int SortByDamageDesc(int elem1, int elem2, const array[], Handle hndl)
{
    // By damage, then by client index, descending
    if (iDamageWitch[elem1] > iDamageWitch[elem2]) return -1;
    else if (iDamageWitch[elem2] > iDamageWitch[elem1]) return 1;
    else if (elem1 > elem2) return -1;
    else if (elem2 > elem1) return 1;
    return 0;
}

void ClearDamage()
{
    for (int i = 1; i <= MaxClients; i++) 
        iDamageWitch[i] = 0;

    damageWitchTotal = 0;
}

void cvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    fHealthWitch = cvarWitchHealth.FloatValue;
    iSurvivorLimit = cvarSurvivorLimit.IntValue;
}