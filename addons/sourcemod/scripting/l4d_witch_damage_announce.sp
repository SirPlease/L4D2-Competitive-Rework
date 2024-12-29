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
*
* Version 1.4
* - Resolve errors for setups that don't remove the upperbound value for survivor_limit while still having over 4 Survivors.
* - Officially support damage recording for multiple witches at the same time.
* - Updated IsTank check to account for L4D1 Servers running this plugin.
* - Add a ConVar to control whether we print on incaps or not (Default OFF).
* - Add a ConVar to control whether we combine percentages lower than a minimum percentage (Default OFF).
* - Add a ConVar to limit the total amount of damage lines printed (Default OFF).
*   - Setting this to "5" would limit the prints to either 5 Survivors or 4 (+ "The Other Survivors") when 6 players damaged the witch.
* - Add a ConVar for the combination name (Default: "The Other Survivors").
*/

#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3
#define L4D1_ZOMBIECLASS_TANK 5
#define L4D2_ZOMBIECLASS_TANK 8

int
    currentWitch,
    witchMaxHealth,
    damageToWitch[MAXPLAYERS + 1][2048],
    damageWitchTotal[2048],
    printMinimum,
    printMaxLines;

bool
    hasPrinted[2048];
    roundIsLive;
    printOnIncap;

ConVar
    cvarValveWitchHealth,
    cvarPrintOnIncap,
    cvarPrintMinimum,
    cvarPrintMaxLines,
    cvarCombinationName;

char combinationName[32];

public Plugin myinfo =
{
    name = "Witch Damage Announce",
    author = "Sir",
    description = "Print Witch Damage to chat.",
    version = "1.4",
    url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
}

public void OnPluginStart()
{
    // Lateload
    roundIsLive = true;

    HookEvent("infected_hurt", WitchHurt_Event);
    HookEvent("witch_killed", WitchDeath_Event);
    HookEvent("player_incapacitated_start", PlayerIncapStart_Event);
    HookEvent("player_death", PlayerDied_Event);
    HookEvent("round_start", RoundStart_Event, EventHookMode_PostNoCopy);
    HookEvent("round_end", RoundEnd_Event, EventHookMode_PostNoCopy);

    cvarValveWitchHealth = FindConVar("z_witch_health");
    witchMaxHealth  = cvarValveWitchHealth.IntValue;
    cvarValveWitchHealth.AddChangeHook(cvarChanged);

    cvarPrintOnIncap = CreateConVar("l4d_wda_print_incap", "0", "Do we print the Witch's remaining health when she incapacitates a survivor?");
    printOnIncap = cvarPrintOnIncap.BoolValue;
    cvarPrintOnIncap.AddChangeHook(cvarChanged);

    cvarPrintMinimum = CreateConVar("l4d_wda_print_minimum", "0", "What's the minimum percentage of damage we need to do to be listed? 0 = Disabled, everyone listed.");
    printMinimum = cvarPrintMinimum.IntValue;
    cvarPrintMinimum.AddChangeHook(cvarChanged);

    cvarPrintMaxLines = CreateConVar("l4d_wda_print_max_lines", "0", "Maximum amount of damage lines we list (Survivors + Rest), 0 = Disabled, everyone listed.");
    printMaxLines = cvarPrintMaxLines.IntValue;
    cvarPrintMaxLines.AddChangeHook(cvarChanged);

    cvarCombinationName = CreateConVar("l4d_wda_combination_name", "The Other Survivors", "What do we call the combined players? Character limit of 32.");
    cvarCombinationName.GetString(combinationName, 32);
    cvarCombinationName.AddChangeHook(cvarChanged);
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (StrContains(classname, "witch") != -1)
    {
        hasPrinted[entity] = false;
        ClearDamage(entity);
    }
}

void RoundStart_Event(Event hEvent, const char[] name, bool dontBroadcast) { roundIsLive = true; }
void RoundEnd_Event(Event hEvent, const char[] name, bool dontBroadcast) { roundIsLive = false; }

void WitchHurt_Event(Event hEvent, const char[] name, bool dontBroadcast)
{
    int victim = hEvent.GetInt("entityid");

    if (IsWitch(victim))
    {
        int attacker = GetClientOfUserId(hEvent.GetInt("attacker"));
        int damageDone = hEvent.GetInt("amount");

        if (IsClientAndInGame(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR)
        {
            int newTotalDamage = damageWitchTotal[victim] + damageDone;
            damageDone = newTotalDamage > witchMaxHealth ? damageDone - (newTotalDamage - witchMaxHealth) : damageDone

            damageWitchTotal[victim] += damageDone;
            damageToWitch[attacker][victim] += damageDone;
        }
    }
}

void WitchDeath_Event(Event hEvent, const char[] name, bool dontBroadcast)
{
    int witch = hEvent.GetInt("witchid");
    int killer = GetClientOfUserId(hEvent.GetInt("userid"));

    // Check if Tank Killed the Witch.
    if (IsClientAndInGame(killer) && GetClientTeam(killer) == TEAM_INFECTED && IsTank(killer))
    {
        CPrintToChatAll("{default}[{green}!{default}] {red}Tank {default}({olive}%N{default}) killed the {red}Witch", killer);
        return;
    }

    // If Damage is lower than Max Health, Adjust.
    if (damageWitchTotal[witch] < witchMaxHealth)
    {
        damageToWitch[killer][witch] += witchMaxHealth - damageWitchTotal[witch];
        damageWitchTotal[witch] = witchMaxHealth;
    }

    CalculateWitch(witch);
}

void PlayerIncapStart_Event(Event hEvent, const char[] name, bool dontBroadcast)
{
    if (!printOnIncap)
        return;

    int victim = GetClientOfUserId(hEvent.GetInt("userid"));
    int attacker = hEvent.GetInt("attackerentid");

    if (IsClientAndInGame(victim) && GetClientTeam(victim) == TEAM_SURVIVOR && IsWitch(attacker))
        CalculateWitch(attacker);
}

void PlayerDied_Event(Event hEvent, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(hEvent.GetInt("userid"));
    int attacker = hEvent.GetInt("attackerentid");

    if (IsClientAndInGame(victim) && GetClientTeam(victim) == TEAM_SURVIVOR && IsWitch(attacker))
        CalculateWitch(attacker);
}

void CalculateWitch(int witch)
{
    if (GetEntProp(witch, Prop_Data, "m_iHealth") > 0)
    {
        PrintWitchDamage(witch, true);
        hasPrinted[witch] = true;
    }
    else
        PrintWitchDamage(witch);
}

void PrintWitchDamage(int witch, bool witchAlive = false)
{
    if (!roundIsLive || hasPrinted[witch])
        return;

    if (witchAlive)
        CPrintToChatAll("{default}[{green}!{default}] {blue}Witch {default}had {olive}%d {default}health remaining", witchMaxHealth - damageWitchTotal[witch]);
    else
        CPrintToChatAll("{default}[{green}!{default}] {blue}Damage {default}dealt to {blue}Witch:");

    int
        totalPercent,
        survivorIndex,
        percentDamage,
        damage,
        percentAdjustment,
        adjustedPercentDamage;

    int[] survivorClients = new int[GetSurvivorCount()];

    int lastPercent = 100;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || GetClientTeam(i) != TEAM_SURVIVOR || damageToWitch[i][witch] == 0)
            continue;

        survivorClients[survivorIndex++] = i;
        damage = damageToWitch[i][witch];
        percentDamage = GetDamageAsPercent(damage);
        totalPercent += percentDamage;
    }

    currentWitch = witch;
    SortCustom1D(survivorClients, survivorIndex, SortByDamageDesc);

    // Percents add up to less than 100% AND > 99.5% damage was dealt to witch
    if ((totalPercent < 100 && float(damageWitchTotal[witch]) > (float(witchMaxHealth) - (float(witchMaxHealth) / 200.0))))
    {
        percentAdjustment = 100 - totalPercent;
    }

    int restDamage;
    int restPercent;

    for (int k; k < survivorIndex; k++)
    {
        int client = survivorClients[k];
        damage = damageToWitch[client][witch];
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

        /*
            Minimum damage percentage (cvarPrintMinimum):
            - When damage is lower than minimum, get combined.

            Maximum damage lines (cvarPrintMaxLines):
            - Check if Survivor count that has damaged the witch would exceed the max lines, if so combine the ones with the lowest damage.
        */

        if ((printMinimum && percentDamage < printMinimum)
        || printMaxLines && survivorIndex > printMaxLines && k + 1 >= printMaxLines)
        {
            restDamage += damage;
            restPercent += percentDamage;
            continue;
        }

        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i))
            {
                CPrintToChat(i, "{blue}[{default}%d{blue}] ({default}%i%%{blue}) {olive}%N", damage, percentDamage, client);
            }
        }
    }

    if (restDamage)
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i))
            {
                CPrintToChat(i, "{blue}[{default}%d{blue}] ({default}%i%%{blue}) {green}%s", restDamage, restPercent, combinationName);
            }
        }
    }
}

int GetDamageAsPercent(int damage)
{
    return RoundToNearest((damage / float(witchMaxHealth)) * 100.0);
}

bool IsExactPercent(int damage)
{
    float fDamageAsPercent = (damage / float(witchMaxHealth)) * 100.0;
    float fDifference = float(GetDamageAsPercent(damage)) - fDamageAsPercent;
    return (FloatAbs(fDifference) < 0.001) ? true : false;
}

bool IsTank(int client)
{
    return (GetEngineVersion() == Engine_Left4Dead2 ? GetEntProp(client, Prop_Send, "m_zombieClass") == L4D2_ZOMBIECLASS_TANK
        : GetEntProp(client, Prop_Send, "m_zombieClass") == L4D1_ZOMBIECLASS_TANK);
}

int SortByDamageDesc(int elem1, int elem2, const array[], Handle hndl)
{
    // By damage, then by client index, descending
    if (damageToWitch[elem1][currentWitch] > damageToWitch[elem2][currentWitch]) return -1;
    else if (damageToWitch[elem2][currentWitch] > damageToWitch[elem1][currentWitch]) return 1;
    else if (elem1 > elem2) return -1;
    else if (elem2 > elem1) return 1;
    return 0;
}

int GetSurvivorCount()
{
    int count;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR)
            count++;
    }

    return count;
}

void ClearDamage(int witch)
{
    for (int i = 1; i <= MaxClients; i++)
        damageToWitch[i][witch] = 0;

    damageWitchTotal[witch] = 0;
}

bool IsClientAndInGame(int index)
{
    return (index > 0 && index <= MaxClients && IsClientInGame(index));
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

void cvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    witchMaxHealth = cvarValveWitchHealth.IntValue;
    printOnIncap = cvarPrintOnIncap.BoolValue;
    printMinimum = cvarPrintMinimum.IntValue;
    printMaxLines = cvarPrintMaxLines.IntValue;
    cvarCombinationName.GetString(combinationName, 32);
}