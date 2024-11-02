/*
    In these cases plugin will print damage:
    1.After tank dead;
    2.Round is end.
*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <colors>

#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3
#define ZOMBIECLASS_TANK_L4D2 8

int
    g_iDamage[MAXPLAYERS + 1][MAXPLAYERS + 1],
    g_iLastTankHealth[MAXPLAYERS + 1],
    g_iCurrentTank = -1,
    // if tank pass for many times
    g_iYourTank[MAXPLAYERS + 1];

float
    g_fMaxTankHealth = 6000.0;

ConVar
    g_hCvarEnabled,
    g_hCvarTankHealth,
    g_hCvarGamemode,
    g_hCvarDifficulty;

public Plugin myinfo =
{
    name = "Tank Damage Announce L4D2",
    author = "Hitomi",
    description = "Announce damage dealt to tanks by survivors",
    version = "1.0",
    url = "https://github.com.cy115/"
};

public void OnPluginStart()
{
    // Plugin Cvars
    g_hCvarEnabled = CreateConVar("l4d_tankdamage_enabled", "1", "Announce damage done to tanks when enabled");
    // Game Native Cvars
    g_hCvarTankHealth = FindConVar("z_tank_health");
    g_hCvarGamemode = FindConVar("mp_gamemode");
    g_hCvarDifficulty = FindConVar("z_difficulty");

    HookEventHandle();
    CalculateTankHealth();

    HookConVarChange(g_hCvarEnabled, Cvar_EnabledChanged);
    HookConVarChange(g_hCvarGamemode, Cvar_TankHealthChanged);
    HookConVarChange(g_hCvarTankHealth, Cvar_TankHealthChanged);

    for (int i = 1; i <= MaxClients; i++) {
        ClearTankDamage(i);
    }
}

void HookEventHandle()
{
    // Don`t hook event if people don`t need this funciton
    if (g_hCvarEnabled.BoolValue) {
        HookEvent("tank_spawn", Event_TankSpawn);
        HookEvent("player_hurt", Event_PlayerHurt);
        HookEvent("player_death", Event_PlayerDeath);
        HookEvent("round_end", Event_RoundEnd);
    }
    else {
        UnhookEvent("tank_spawn", Event_TankSpawn);
        UnhookEvent("player_hurt", Event_PlayerHurt);
        UnhookEvent("player_death", Event_PlayerDeath);
        UnhookEvent("round_end", Event_RoundEnd);
    }
}

void Cvar_EnabledChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
    HookEventHandle();
}

void Cvar_TankHealthChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
    CalculateTankHealth();
}

public void OnMapStart()
{
    for (int i = 1; i <= MaxClients; i++) {
        ClearTankDamage(i);
    }
}

public void OnClientDisconnect_Post(int client)
{
    if (g_iYourTank[client] == client) {
        CreateTimer(0.1, Timer_CheckPassTank, client, TIMER_FLAG_NO_MAPCHANGE);
    }
}

// Events
void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int tank = GetClientOfUserId(event.GetInt("userid"));
    g_iYourTank[tank] = tank;
    g_iLastTankHealth[tank] = GetClientHealth(tank);
}

void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    if (!IsValidAliveTank(victim) || IsTankDying(victim)) {
        return;
    }

    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    if (!IsValidSurvivor(attacker)) {
        return;
    }

    g_iDamage[victim][attacker] += event.GetInt("dmg_health");
    g_iLastTankHealth[victim] = event.GetInt("health");
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    if (!IsValidClient(victim) || GetClientTeam(victim) != TEAM_INFECTED || GetEntProp(victim, Prop_Send, "m_zombieClass") != ZOMBIECLASS_TANK_L4D2) {
        return;
    }

    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    if (IsValidSurvivor(attacker)) {
        g_iDamage[victim][attacker] += g_iLastTankHealth[victim];
    }

    PrintTankDamageAnnounce(victim, true);
    ClearTankDamage(victim);
}

public void L4D_OnReplaceTank(int tank, int newtank)
{
    g_iYourTank[tank] = newtank;
    g_iLastTankHealth[newtank] = GetClientHealth(newtank);
    CreateTimer(0.1, Timer_CheckPassTank, tank, TIMER_FLAG_NO_MAPCHANGE);
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    if (IsTankAlive()) {
        for (int i = 1; i <= MaxClients; i++) {
            if (!IsValidAliveTank(i)) {
                continue;
            }

            PrintTankDamageAnnounce(i);
            ClearTankDamage(i);
        }
    }
}

// Functions
Action Timer_CheckPassTank(Handle timer, int tank)
{
    // tank was passed to another player
    if (g_iYourTank[tank] != tank) {
        g_iYourTank[tank] = -1;
        CPrintToChatAll("{default}[{green}!{default}] {blue}Tank had been passed {default}({green}%d {default}health remaining)", g_iLastTankHealth[tank]);
        ClearTankDamage(tank);
    }
    else {
        PrintTankDamageAnnounce(tank, true);
        ClearTankDamage(tank);
    }

    return Plugin_Stop;
}

void CalculateTankHealth()
{
    static char sGamemode[32];
    GetConVarString(FindConVar("mp_gamemode"), sGamemode, sizeof(sGamemode));
    g_fMaxTankHealth = g_hCvarTankHealth.FloatValue;
    if (g_fMaxTankHealth <= 0.0) {
        g_fMaxTankHealth = 1.0;
    }

    if (StrEqual(sGamemode, "versus") || StrEqual(sGamemode, "mutation12")) {
        g_fMaxTankHealth *= 1.5;
    }
    else {
        g_fMaxTankHealth = g_hCvarTankHealth.FloatValue;
        static char sDifficulty[16];
        GetConVarString(g_hCvarDifficulty, sDifficulty, sizeof(sDifficulty));
        if (sDifficulty[0] == 'E') {
            g_fMaxTankHealth *= 0.75;
        }
        else if (sDifficulty[0] == 'E' || sDifficulty[0] == 'e') {
            g_fMaxTankHealth *= 2.0;
        }
    }
}

/*
    tank            the tank will appear in chat
    isDead          the tank is dead or not
*/
void PrintTankDamageAnnounce(int tank, bool isDead = false)
{
    char sTankName[MAX_NAME_LENGTH];
    if (IsFakeClient(tank)) {
        sTankName = "AI";
    }
    else {
        GetClientName(tank, sTankName, sizeof(sTankName));
    }
    if (!isDead) {
        CPrintToChatAll("{default}[{green}!{default}] {blue}Tank {default}({olive}%s{default}) had {green}%d {default}health remaining", sTankName, g_iLastTankHealth[tank]);
    }

    CPrintToChatAll("{default}[{green}!{default}] {blue}Damage {default}dealt to {blue}Tank {default}({olive}%s{default})", sTankName);

    // Print Damage:
    int
        percent_total, damage_total,
        survivor_index,
        percent_damage, damage;

    int[] survivor_clients = new int[GetSurvivorCount()];

    for (int client = 1; client <= MaxClients; client++) {
        if (!IsValidSurvivor(client) || g_iDamage[tank][client] <= 0) {
            continue;
        }

        survivor_clients[survivor_index++] = client;
        damage = g_iDamage[tank][client];
        damage_total += damage;
        percent_damage = GetDamageAsPercent(damage);
        percent_total += percent_damage;
    }

    g_iCurrentTank = tank;
    SortCustom1D(survivor_clients, survivor_index, SortByDamageDesc);

    int percent_adjustment;
    if ((percent_total < 100 && float(damage_total) > (g_fMaxTankHealth - (g_fMaxTankHealth / 200.0)))) {
        percent_adjustment = 100 - percent_total;
    }

    int
        last_percent = 100,
        adjusted_percent_damage;

    for (int i; i <= survivor_index; i++) {
        int client = survivor_clients[i];
        damage = g_iDamage[tank][client];
        percent_damage = GetDamageAsPercent(damage);

        if (percent_adjustment != 0 && damage > 0 && !IsExactPercent(damage)) {
            adjusted_percent_damage = percent_damage + percent_adjustment;
            if (adjusted_percent_damage <= last_percent) {
                percent_damage = adjusted_percent_damage;
                percent_adjustment = 0;
            }
        }

        last_percent = percent_damage;
        for (int j = 1; j <= MaxClients; j++) {
            if (IsClientInGame(j) && client != 0) {
                CPrintToChat(j, "{blue}[{default}%d{blue}] ({default}%i%%{blue}) {olive}%N", damage, percent_damage, client);
            }
        }
    }

    g_iCurrentTank = -1;
}

void ClearTankDamage(int tank)
{
    for (int i = 1; i <= MaxClients; i++) {
        g_iDamage[tank][i] = 0;
    }
}

// Tools
stock bool IsValidClient(int client) {
    return client > 0 && client <= MaxClients && IsClientInGame(client);
}

stock bool IsValidSurvivor(int client) {
    return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == TEAM_SURVIVOR && IsPlayerAlive(client);
}

stock bool IsValidAliveTank(int client) {
    return client > 0 && client <= MaxClients && 
            IsClientInGame(client) && GetClientTeam(client) == TEAM_INFECTED && 
            IsPlayerAlive(client) && GetEntProp(client, Prop_Send, "m_zombieClass") == ZOMBIECLASS_TANK_L4D2;
}

stock bool IsExactPercent(int damage) {
    float
        fDamageAsPercent = (damage / g_fMaxTankHealth) * 100.0,
        fDifference = float(GetDamageAsPercent(damage)) - fDamageAsPercent;

    return (FloatAbs(fDifference) < 0.001) ? true : false;
}

stock bool IsTankDying(int tank) {
    return (GetEntData(tank, FindSendPropInfo("Tank", "m_isIncapacitated")) == 1) ? true : false;
}

stock bool IsTankAlive() {
    for (int i = 1; i <= MaxClients; i++) {
        if (!IsValidAliveTank(i)) {
            continue;
        }
        
        return true;
    }

    return false;
}

stock int GetDamageAsPercent(int damage) {
    return RoundToNearest((damage / g_fMaxTankHealth) * 100.0);
}

stock int SortByDamageDesc(int elem1, int elem2, const int[] array, Handle hndl) {
    if (g_iCurrentTank == -1) {
        return 0;
    }

    if (g_iDamage[g_iCurrentTank][elem1] > g_iDamage[g_iCurrentTank][elem2]) {
        return -1;
    }
    else if (g_iDamage[g_iCurrentTank][elem2] > g_iDamage[g_iCurrentTank][elem1]) {
        return 1;
    }
    else if (elem1 > elem2) {
        return -1;
    }
    else if (elem2 > elem1) {
        return 1;
    }

    return 0;
}

stock int GetSurvivorCount()
{
    int count;
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR) {
            count++;
        }
    }

    return count;
}