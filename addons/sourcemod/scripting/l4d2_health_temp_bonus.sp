/**
 * L4D2 Competitive Health Bonus Scoring System.
 * 
 * -------
 * ConVars
 * -------
 * 
 * sm_perm_ratio [0.0, 1.0]
 *  
 * Defines how much permanent health should be worth 
 * compared to temporary health.
 *
 * ~~~~~
 *
 * sm_health_bonus_divisor [1.0, INT_MAX]
 * 
 * Defines the overall bonus divisor. Use this to make 
 * the bonus worth more (or less) compared to map distance.
 *
 * ~~~~~
 *
 * sm_pain_pills_add_pool [0, INT_MAX]
 *
 * Defines how much temporary health each set of pain pills add to the
 * temporary health pool.
 * 
 * --------------
 * Implementation
 * --------------
 *
 * There's a permanent health pool and a temporary health pool.
 *
 * The permanent health pool represents the total amount of permanent health
 * that survivors have.
 *
 * The temporary health pool represents the total amount of temporary health
 * that survivors have + pain pills health + temporary health that survivors
 * get for free after a revive.
 *
 * Both pools are subjected to these factors:
 *
 * - Maximum map distance
 * - Permanent health ratio (defined by the cvar sm_perm_ratio) 
 * - Health divisor (defined by the cvar sm_health_bonus_divisor)
 * - Number of times the survivors have been incapacitated / killed.
 *
 * Survivor deaths have the same kind of penalty on the bonus as incaps.
 *
 * -------
 * Credits
 * -------
 * 
 * Author: Luckylock
 * 
 * Testers and feedback: Adam, Hib, Sir, Dusty
 */

#include <sourcemod>
#include <left4downtown>
#include <sdktools>
#include <l4d2lib>
#include <colors>

#define DEBUG 0

/* Ratio */
#define PERM_RATIO GetConVarFloat(cvarPermRatio)

/* ConVars */
#define SURVIVOR_REVIVE_HEALTH GetConVarInt(cvarSurvivorReviveHealth)
#define SURVIVOR_LIMIT GetConVarInt(cvarSurvivorLimit)
#define SURVIVOR_MAX_INCAPACITATED_COUNT GetConVarInt(cvarSurvivorMaxIncapCount)
#define MAX_REVIVES (SURVIVOR_LIMIT * SURVIVOR_MAX_INCAPACITATED_COUNT)
#define STOCK_TEMP_HEALTH (SURVIVOR_MAX_INCAPACITATED_COUNT * SURVIVOR_LIMIT * SURVIVOR_REVIVE_HEALTH)
#define PAIN_PILLS_HEALTH GetConVarInt(cvarPainPillsAddPool)

/* Health divisor to keep bonus at reasonable numbers */
#define HEALTH_DIVISOR GetConVarInt(cvarHealthBonusDivisor) 

/* Health Index values */
#define HEALTH_TABLE_SIZE 6
#define PERM_HEALTH_INDEX 0
#define TEMP_HEALTH_INDEX 1
#define STOCK_TEMP_HEALTH_INDEX 2
#define PILLS_HEALTH_INDEX 3 
#define REVIVE_COUNT_INDEX 4
#define ALIVE_COUNT_INDEX 5

new Handle:hCvarValveSurvivalBonus;
new Handle:hCvarValveTieBreaker;
new Handle:cvarPermRatio;
new Handle:cvarSurvivorReviveHealth;
new Handle:cvarSurvivorLimit;
new Handle:cvarSurvivorMaxIncapCount;
new Handle:cvarPainPillsAddPool;
new Handle:cvarHealthBonusDivisor;
new firstRoundBonus;
new firstRoundHealth[HEALTH_TABLE_SIZE];
new currentRoundBonus;
new currentRoundHealth[HEALTH_TABLE_SIZE];

public Plugin myinfo =
{
	name = "L4D2 Competitive Health Bonus System",
	author = "Luckylock",
	description = "Scoring system for l4d2 competitive",
	version = "3.1.1",
	url = "https://github.com/LuckyServ/"
};

public OnPluginStart() 
{
    RegConsoleCmd("sm_health", Cmd_ShowBonus, "Show current bonus");
    RegConsoleCmd("sm_mapinfo", Cmd_ShowInfo, "Show map info");

    CreateConVar("sm_perm_ratio", "0.8", "Permanent health to temporary health ratio", 
        FCVAR_NONE, true, 0.0, true, 1.0);
    CreateConVar("sm_health_bonus_divisor", "200.0", "Health divisor to keep bonus at reasonable numbers",
        FCVAR_NONE, true, 1.0);
    CreateConVar("sm_pain_pills_add_pool", "75", "How much temporary health pain pills add to the pool",
        FCVAR_NONE, true, 0.0);

    hCvarValveSurvivalBonus = FindConVar("vs_survival_bonus");
    hCvarValveTieBreaker = FindConVar("vs_tiebreak_bonus");
    cvarPermRatio = FindConVar("sm_perm_ratio");
    cvarSurvivorReviveHealth = FindConVar("survivor_revive_health");
    cvarSurvivorLimit = FindConVar("survivor_limit");
    cvarSurvivorMaxIncapCount = FindConVar("survivor_max_incapacitated_count");
    cvarPainPillsAddPool = FindConVar("sm_pain_pills_add_pool");
    cvarHealthBonusDivisor = FindConVar("sm_health_bonus_divisor");
}

public OnConfigsExecuted()
{
	L4D_SetVersusMaxCompletionScore(L4D2_GetMapValueInt("max_distance", L4D_GetVersusMaxCompletionScore()));
}

/**
 * Shows health bonus to client.
 */
public Action Cmd_ShowBonus(client, args) 
{
    new health[HEALTH_TABLE_SIZE] = {0, 0, 0, 0, 0, 0};
    FillHealthTable(health);
    new totalBonus = CalculateTotalBonus(health);
    
    if (InSecondHalfOfRound()) {
        PrintRoundBonusClient(client, true, firstRoundHealth, firstRoundBonus);    
        PrintRoundBonusClient(client, false, health, totalBonus);    
    } else {
        PrintRoundBonusClient(client, true, health, totalBonus);
    }
}

public Action Cmd_ShowInfo(client, args)
{
    new maxHealth[HEALTH_TABLE_SIZE] = {0, 0, 0, 0, 0, 0};    
    FillMaxHealthTable(maxHealth);
    new maxBonus = CalculateTotalBonus(maxHealth);

    CPrintToChat(client, "[Map Info] {default}({green}max distance{default}): {olive}%d{default}", L4D2_GetMapValueInt("max_distance", L4D_GetVersusMaxCompletionScore())); 
    CPrintToChat(client, "[Map Info] {default}({green}max bonus{default}): {olive}%d {default}[ Perm: {lightgreen}%d {default}| Temp: {lightgreen}%d {default} | Pills: {lightgreen}%d {default}]", 
        maxBonus, maxHealth[PERM_HEALTH_INDEX], maxHealth[TEMP_HEALTH_INDEX] + maxHealth[STOCK_TEMP_HEALTH_INDEX], 
        maxHealth[PILLS_HEALTH_INDEX]); 
}

/**
 * Fills max health values
 */
public void FillMaxHealthTable(int health[HEALTH_TABLE_SIZE]) {
    health[PERM_HEALTH_INDEX] = 100 * SURVIVOR_LIMIT;
    health[TEMP_HEALTH_INDEX] = 0;
    health[STOCK_TEMP_HEALTH_INDEX] = STOCK_TEMP_HEALTH;
    health[PILLS_HEALTH_INDEX] = PAIN_PILLS_HEALTH * SURVIVOR_LIMIT;
    health[REVIVE_COUNT_INDEX] = 0;
    health[ALIVE_COUNT_INDEX] = SURVIVOR_LIMIT;
}

/**
 * Calculates and fills health values (permanent and temporary)
 */
public void FillHealthTable(int health[HEALTH_TABLE_SIZE]) 
{
    new revives = 0;

    for(new client = 1; client <= MaxClients; ++client) {
        if (IsSurvivor(client)) {
            if (IsPlayerAlive(client) && !L4D_IsPlayerIncapacitated(client)) {
                health[PERM_HEALTH_INDEX] += GetSurvivorPermanentHealth(client);
                health[TEMP_HEALTH_INDEX] += GetSurvivorTempHealth(client); 
                revives += L4D_GetPlayerReviveCount(client);
                health[ALIVE_COUNT_INDEX]++;
                if (HasPills(client)) {
                    health[PILLS_HEALTH_INDEX] += PAIN_PILLS_HEALTH; 
                }
            } else {
                revives += SURVIVOR_MAX_INCAPACITATED_COUNT; 
            }
        }
    }

    health[STOCK_TEMP_HEALTH_INDEX] = STOCK_TEMP_HEALTH - (revives * SURVIVOR_REVIVE_HEALTH);
    health[REVIVE_COUNT_INDEX] = revives;

#if DEBUG
    for (new i = 0; i < HEALTH_TABLE_SIZE; ++i) {
        PrintToChatAll("health[%d] = %d", i, health[i]);
    }
#endif
}

/**
 * Calculates the total bonus; health table is changed after this call.
 */
public int CalculateTotalBonus(health[HEALTH_TABLE_SIZE]) 
{
    ApplyBonusFactors(health, PERM_RATIO, PERM_HEALTH_INDEX);

    for (new i = TEMP_HEALTH_INDEX; i <= PILLS_HEALTH_INDEX; ++i) {
        ApplyBonusFactors(health, 1.0 - PERM_RATIO, i);
    }

    return health[PERM_HEALTH_INDEX] 
            + health[TEMP_HEALTH_INDEX] 
            + health[STOCK_TEMP_HEALTH_INDEX]
            + health[PILLS_HEALTH_INDEX]; 
}

/**
 * Applies factors to health values.
 */
public void ApplyBonusFactors(health[HEALTH_TABLE_SIZE], float ratio, index)
{
        health[index] = 
            RoundFloat(health[index]
            * L4D_GetVersusMaxCompletionScore() 
            * ratio / HEALTH_DIVISOR
            / (MAX_REVIVES + SURVIVOR_LIMIT) 
            * (MAX_REVIVES + SURVIVOR_LIMIT - health[REVIVE_COUNT_INDEX] - (SURVIVOR_LIMIT - health[ALIVE_COUNT_INDEX])));
}

/** 
 * https://forums.alliedmods.net/showthread.php?t=144780 
 */
public int GetSurvivorTempHealth(client) 
{
    new Float:buffer = GetEntPropFloat(client, Prop_Send, "m_healthBuffer"); 
    new Float:TempHealth = 0.0;

    if (buffer > 0) {
        new Float:difference = GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
        new Float:decay = GetConVarFloat(FindConVar("pain_pills_decay_rate"));
        new Float:constant = 1.0/decay;
        TempHealth = buffer - (difference / constant);
    }

    if (TempHealth < 0) {
        return 0;
    } else {
        return RoundFloat(TempHealth);
    }
}

public void OnMapStart() {
    firstRoundBonus = 0;
    firstRoundHealth = {0, 0, 0, 0, 0, 0};
}

public Action L4D2_OnEndVersusModeRound(bool:countSurvivors) 
{
    currentRoundHealth = {0, 0, 0, 0, 0, 0};
    FillHealthTable(currentRoundHealth);
    currentRoundBonus = CalculateTotalBonus(currentRoundHealth);
    new survivalBonus = currentRoundHealth[ALIVE_COUNT_INDEX] > 0 ? 
        RoundFloat(float(currentRoundBonus) / currentRoundHealth[ALIVE_COUNT_INDEX]) : 0;

    SetConVarInt(hCvarValveSurvivalBonus, survivalBonus); 
    SetConVarInt(hCvarValveTieBreaker, 0);

    CreateTimer(3.0, PrintEndBonus);

    return Plugin_Continue;
}

public Action PrintEndBonus(Handle timer, Handle hndl) 
{
    if (InSecondHalfOfRound()) {
        PrintRoundBonusAll(true, firstRoundHealth, firstRoundBonus); 
        PrintRoundBonusAll(false, currentRoundHealth, currentRoundBonus);    
    } else {
        firstRoundBonus = currentRoundBonus;
        copyTableValues(currentRoundHealth, firstRoundHealth);
        PrintRoundBonusAll(true, firstRoundHealth, firstRoundBonus);
    }
}

public void PrintRoundBonusAll(bool firstRound, int health[HEALTH_TABLE_SIZE], int totalBonus)
{
    new maxHealth[HEALTH_TABLE_SIZE] = {0, 0, 0, 0, 0, 0};    
    FillMaxHealthTable(maxHealth);
    new maxBonus = CalculateTotalBonus(maxHealth);

    if (totalBonus > 0) {
        PrintToChatAll("\x01R\x04#%d \x01Bonus: \x05%d \x01<\x03%.1f%%\x01> \x01[ Perm: \x03%d \x01| Temp: \x03%d \x01 | Pills: \x03%d \x01]", 
            firstRound ? 1 : 2, totalBonus, float(totalBonus) / maxBonus * 100, health[PERM_HEALTH_INDEX], health[TEMP_HEALTH_INDEX] + health[STOCK_TEMP_HEALTH_INDEX], 
            health[PILLS_HEALTH_INDEX]); 
    } else {
        PrintToChatAll("\x01R\x04#%d \x01Bonus: \x05%d", firstRound ? 1 : 2, totalBonus)
    }
}

public void PrintRoundBonusClient(int client, bool firstRound, int health[HEALTH_TABLE_SIZE], int totalBonus)
{
    new maxHealth[HEALTH_TABLE_SIZE] = {0, 0, 0, 0, 0, 0};    
    FillMaxHealthTable(maxHealth);
    new maxBonus = CalculateTotalBonus(maxHealth);

    if (totalBonus > 0) {
        PrintToChat(client, "\x01R\x04#%d \x01Bonus: \x05%d \x01<\x03%.1f%%\x01> \x01[ Perm: \x03%d \x01| Temp: \x03%d \x01 | Pills: \x03%d \x01]", 
            firstRound ? 1 : 2, totalBonus, float(totalBonus) / maxBonus * 100, health[PERM_HEALTH_INDEX], health[TEMP_HEALTH_INDEX] + health[STOCK_TEMP_HEALTH_INDEX], 
            health[PILLS_HEALTH_INDEX]); 
    } else {
        PrintToChat(client, "\x01R\x04#%d \x01Bonus: \x05%d", firstRound ? 1 : 2, totalBonus); 
    }
}

public void copyTableValues(int health[HEALTH_TABLE_SIZE], int healthCopy[HEALTH_TABLE_SIZE])
{
    for (new i = 0; i < HEALTH_TABLE_SIZE; ++i) {
        healthCopy[i] = health[i];
    }
}

stock bool:IsSurvivor(client)                                                   
{                                                                               
    return client > 0 
        && client <= MaxClients
        && IsClientInGame(client) 
        && GetClientTeam(client) == 2; 
}

stock bool:L4D_IsPlayerIncapacitated(client)
{
	return bool:GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

stock L4D_GetPlayerReviveCount(client) 
{
	return GetEntProp(client, Prop_Send, "m_currentReviveCount");
}

stock bool HasPills(client)
{
	new item = GetPlayerWeaponSlot(client, 4);

	if (IsValidEdict(item))
	{
		decl String:buffer[64];
		GetEdictClassname(item, buffer, sizeof(buffer));
		return StrEqual(buffer, "weapon_pain_pills");
	}

	return false;
}

InSecondHalfOfRound()
{
    return GameRules_GetProp("m_bInSecondHalfOfRound");
}

/*
 * Credits to Visor for this one. 
 */
GetSurvivorPermanentHealth(client)
{
	return L4D_GetPlayerReviveCount(client) > 0 ? 
        0 : (GetEntProp(client, Prop_Send, "m_iHealth") > 0 ? 
            GetEntProp(client, Prop_Send, "m_iHealth") : 0);
}
