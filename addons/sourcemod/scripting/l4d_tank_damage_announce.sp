/*        L4D_TANK_DAMAGE_ANNOUNCE
 *         L4D_TANK_DAMAGE_ANNOUNCE
 */

#pragma semicolon 1

#include <colors>
#include <sdktools>
#include <sourcemod>

#define TEAM_SURVIVOR     2
#define TEAM_INFECTED     3
#define ZOMBIECLASS_TANK  8    // Zombie class of the tank, used to find tank after he have been passed to another player

bool
	g_bEnabled            = true,
	g_bAnnounceTankDamage = false,    // Whether or not tank damage should be announced
	g_bIsTankInPlay       = false,    // Whether or not the tank is active
	bPrintedHealth        = false;    // Is Remaining Health showed?
int
	g_iWasTank[MAXPLAYERS + 1]	= { 0, ... },	// Was Player Tank before he died.
	g_iWasTankAI                = 0,
	g_iOffset_Incapacitated 	= 0,			// Used to check if tank is dying
	g_iTankClient               = 0,    		// Which client is currently playing as tank
	g_iLastTankHealth           = 0,    		// Used to award the killing blow the exact right amount of damage
	g_iSurvivorLimit            = 4,    		// For survivor array in damage print
	g_iDamage[MAXPLAYERS + 1];
float
	g_fMaxTankHealth = 6000.0;
ConVar
	g_cvarEnabled,
	g_cvarTankHealth,
	g_cvarDifficulty,
	g_cvarSurvivorLimit;
Handle
	fwdOnTankDeath = INVALID_HANDLE;

/*
* Version 0.6.6
* - Better looking Output.
* - Added Tank Name display when Tank dies, normally it only showed the Tank's name if the Tank survived
*
* Version 0.6.6b
* - Fixed Printing Two Tanks when last map Tank survived.
* Added by; Sir

* Version 0.6.7
* - Added Campaign Difficulty Support.
* Added by; Sir
*/
public Plugin myinfo = {
	name        = "Tank Damage Announce L4D2",
	author      = "Griffin and Blade",
	description = "Announce damage dealt to tanks by survivors",
	version     = "0.6.7",
}

public void OnPluginStart()
{
	LoadTranslation("l4d_tank_damage_announce.phrases");
	g_bIsTankInPlay       = false;
	g_bAnnounceTankDamage = false;
	g_iTankClient         = 0;
	ClearTankDamage();
	HookEvent("tank_spawn", Event_TankSpawn);
	HookEvent("player_death", Event_PlayerKilled);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_hurt", Event_PlayerHurt);

	g_cvarEnabled       = CreateConVar("l4d_tankdamage_enabled", "1", "Announce damage done to tanks when enabled", FCVAR_NONE | FCVAR_SPONLY | FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarSurvivorLimit = FindConVar("survivor_limit");
	g_cvarTankHealth    = FindConVar("z_tank_health");
	g_cvarDifficulty    = FindConVar("z_difficulty");

	HookConVarChange(g_cvarEnabled, Cvar_Enabled);
	HookConVarChange(g_cvarSurvivorLimit, Cvar_SurvivorLimit);
	HookConVarChange(g_cvarTankHealth, Cvar_TankHealth);
	HookConVarChange(g_cvarDifficulty, Cvar_TankHealth);
	HookConVarChange(FindConVar("mp_gamemode"), Cvar_TankHealth);

	g_bEnabled = g_cvarEnabled.BoolValue;
	CalculateTankHealth();

	g_iOffset_Incapacitated = FindSendPropInfo("Tank", "m_isIncapacitated");
	fwdOnTankDeath          = CreateGlobalForward("OnTankDeath", ET_Event);
}

void LoadTranslation(char[] sTranslation)
{
	char
		sPath[PLATFORM_MAX_PATH],
		sName[64];

	Format(sName, sizeof(sName), "translations/%s.txt", sTranslation);
	BuildPath(Path_SM, sPath, sizeof(sPath), sName);
	if (!FileExists(sPath))
	{
		SetFailState("Missing translation file %s.txt", sTranslation);
	}
	LoadTranslations(sTranslation);
}

public void OnMapStart()
{
	// In cases where a tank spawns and map is changed manually, bypassing round end
	ClearTankDamage();

	PrecacheSound("ui/pickup_secret01.wav");
}

public void OnClientDisconnect_Post(int client)
{
	if (!g_bIsTankInPlay || client != g_iTankClient) return;
	CreateTimer(0.1, Timer_CheckTank, client);    // Use a delayed timer due to bugs where the tank passes to another player
}

public void Cvar_Enabled(Handle convar, const char[] oldValue, const char[] newValue)
{
	g_bEnabled = StringToInt(newValue) > 0 ? true : false;
}

public void Cvar_SurvivorLimit(Handle convar, const char[] oldValue, const char[] newValue)
{
	g_iSurvivorLimit = StringToInt(newValue);
}

public void Cvar_TankHealth(Handle convar, const char[] oldValue, const char[] newValue)
{
	CalculateTankHealth();
}

void CalculateTankHealth()
{
	char sGameMode[32];
	GetConVarString(FindConVar("mp_gamemode"), sGameMode, sizeof(sGameMode));

	g_fMaxTankHealth = g_cvarTankHealth.FloatValue;
	if (g_fMaxTankHealth <= 0.0) g_fMaxTankHealth = 1.0;

	// Versus or Realism Versus
	if (StrEqual(sGameMode, "versus") || StrEqual(sGameMode, "mutation12"))
		g_fMaxTankHealth *= 1.5;

	// Anything else (should be fine...?)
	else
	{
		g_fMaxTankHealth = g_cvarTankHealth.FloatValue;

		char sDifficulty[16];
		GetConVarString(g_cvarDifficulty, sDifficulty, sizeof(sDifficulty));

		if (sDifficulty[0] == 'E') g_fMaxTankHealth *= 0.75;    // Easy
		else if (sDifficulty[0] == 'H'
		         || sDifficulty[0] == 'I') g_fMaxTankHealth *= 2.0;    // Advanced or Expert
	}
}

public void Event_PlayerHurt(Handle event, const char[] name, bool dontBroadcast)
{
	if (!g_bIsTankInPlay)
		return;    // No tank in play; no damage to record

	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (victim != GetTankClient() || IsTankDying()) 
		return;

	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	// We only care about damage dealt by survivors, though it can be funny to see
	// claw/self inflicted hittable damage, so maybe in the future we'll do that
	if (attacker == 0 || !IsClientInGame(attacker) || GetClientTeam(attacker) != TEAM_SURVIVOR)
		return;

	g_iDamage[attacker] += GetEventInt(event, "dmg_health");
	g_iLastTankHealth = GetEventInt(event, "health");
}

public void Event_PlayerKilled(Handle event, const char[] name, bool dontBroadcast)
{
	if (!g_bIsTankInPlay)
		return;    // No tank in play; no damage to record

	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (victim != g_iTankClient)
		return;

	// Award the killing blow's damage to the attacker; we don't award
	// damage from player_hurt after the tank has died/is dying
	// If we don't do it this way, we get wonky/inaccurate damage values
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (attacker && IsClientInGame(attacker)) g_iDamage[attacker] += g_iLastTankHealth;

	// Player was Tank
	if (!IsFakeClient(victim)) g_iWasTank[victim] = 1;
	else g_iWasTankAI = 1;
	// Damage announce could probably happen right here...
	CreateTimer(0.1, Timer_CheckTank, victim);    // Use a delayed timer due to bugs where the tank passes to another player
}

public void Event_TankSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client    = GetClientOfUserId(GetEventInt(event, "userid"));
	g_iTankClient = client;

	if (g_bIsTankInPlay)
		return;    // Tank passed

	EmitSoundToAll("ui/pickup_secret01.wav", _, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.8);
	// New tank, damage has not been announced
	g_bAnnounceTankDamage = true;
	g_bIsTankInPlay       = true;
	// Set health for damage print in case it doesn't get set by player_hurt (aka no one shoots the tank)
	g_iLastTankHealth     = GetClientHealth(client);
}

public void Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	bPrintedHealth  = false;
	g_bIsTankInPlay = false;
	g_iTankClient   = 0;
	ClearTankDamage();    // Probably redundant
}

// When survivors wipe or juke tank, announce damage
public void Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	// But only if a tank that hasn't been killed exists
	if (g_bAnnounceTankDamage)
	{
		PrintRemainingHealth();
		PrintTankDamage();
	}
	ClearTankDamage();
}

public Action Timer_CheckTank(Handle timer, int oldtankclient)
{
	if (g_iTankClient != oldtankclient)
		return Plugin_Continue;    // Tank passed

	int tankclient = FindTankClient();
	if (tankclient && tankclient != oldtankclient)
	{
		g_iTankClient = tankclient;
		return Plugin_Continue;    // Found tank, done
	}

	if (g_bAnnounceTankDamage) 
		PrintTankDamage();
	ClearTankDamage();
	g_bIsTankInPlay = false;    // No tank in play
	Call_StartForward(fwdOnTankDeath);
	Call_Finish();
	return Plugin_Continue;
}

bool IsTankDying()
{
	int tankclient = GetTankClient();
	if (!tankclient)
		return false;
	
	return view_as<bool>(GetEntData(tankclient, g_iOffset_Incapacitated));
}

void PrintRemainingHealth()
{
	bPrintedHealth = true;
	if (!g_bEnabled)
		return;
	int tankclient = GetTankClient();
	if (!tankclient)
		return;

	char
		sName[MAX_NAME_LENGTH],
		sIAName[8];
	Format(sIAName, sizeof(sIAName), "%t", "AI");
	GetClientName(tankclient, sName, sizeof(sName));
	CPrintToChatAll("%t %t", "Tag", "HealthRemaining", IsFakeClient(tankclient) ? sIAName : sName, g_iLastTankHealth);
}

void PrintTankDamage()
{
	if (!g_bEnabled)
		return;

	if (!bPrintedHealth)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (g_iWasTank[i] > 0)
			{
				char sName[MAX_NAME_LENGTH];
				GetClientName(i, sName, sizeof(sName));
				CPrintToChatAll("%t %t", "Tag", "DealtToTank", sName);
				g_iWasTank[i] = 0;
			}
			else if (g_iWasTankAI > 0)
			{
				char sIAName[8];
				Format(sIAName, sizeof(sIAName), "%t", "AI");
				CPrintToChatAll("%t %t", "Tag", "DealtToTank", sIAName);
			}
			g_iWasTankAI = 0;
		}
	}

	int
		client,
		percent_total,    // Accumulated total of calculated percents, for fudging out numbers at the end
		damage_total,     // Accumulated total damage dealt by survivors, to see if we need to fudge upwards to 100%
		survivor_index = -1,
		percent_damage,
		damage;
	int[] survivor_clients = new int[g_iSurvivorLimit];    // Array to store survivor client indexes in, for the display iteration
	for (client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || GetClientTeam(client) != TEAM_SURVIVOR || g_iDamage[client] == 0) continue;
		survivor_index++;
		survivor_clients[survivor_index] = client;
		damage                           = g_iDamage[client];
		damage_total += damage;
		percent_damage = GetDamageAsPercent(damage);
		percent_total += percent_damage;
	}
	SortCustom1D(survivor_clients, g_iSurvivorLimit, SortByDamageDesc);

	int percent_adjustment;
	// Percents add up to less than 100% AND > 99.5% damage was dealt to tank
	if ((percent_total < 100 && float(damage_total) > (g_fMaxTankHealth - (g_fMaxTankHealth / 200.0))))
	{
		percent_adjustment = 100 - percent_total;
	}

	int
		last_percent = 100,    // Used to store the last percent in iteration to make sure an adjusted percent doesn't exceed the previous percent
		adjusted_percent_damage;
	for (int k; k <= survivor_index; k++)
	{
		client         = survivor_clients[k];
		damage         = g_iDamage[client];
		percent_damage = GetDamageAsPercent(damage);
		// Attempt to adjust the top damager's percent, defer adjustment to next player if it's an exact percent
		// e.g. 3000 damage on 6k health tank shouldn't be adjusted
		if (percent_adjustment != 0 &&    // Is there percent to adjust
		    damage > 0 &&                 // Is damage dealt > 0%
		    !IsExactPercent(damage)       // Percent representation is not exact, e.g. 3000 damage on 6k tank = 50%
		)
		{
			adjusted_percent_damage = percent_damage + percent_adjustment;
			if (adjusted_percent_damage <= last_percent)    // Make sure adjusted percent is not higher than previous percent, order must be maintained
			{
				percent_damage     = adjusted_percent_damage;
				percent_adjustment = 0;
			}
		}
		last_percent = percent_damage;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				CPrintToChat(i, "%t", "PercentDamage", damage, percent_damage, client);
			}
		}
	}
}

void ClearTankDamage()
{
	g_iLastTankHealth = 0;
	g_iWasTankAI      = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		g_iDamage[i]  = 0;
		g_iWasTank[i] = 0;
	}
	g_bAnnounceTankDamage = false;
}

int GetTankClient()
{
	if (!g_bIsTankInPlay) 
		return 0;

	int tankclient = g_iTankClient;

	if (!IsClientInGame(tankclient))    // If tank somehow is no longer in the game (kicked, hence events didn't fire)
	{
		tankclient = FindTankClient();    // find the tank client
		if (!tankclient) 
			return 0;
		g_iTankClient = tankclient;
	}

	return tankclient;
}

int FindTankClient()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || GetClientTeam(client) != TEAM_INFECTED || !IsPlayerAlive(client) || GetEntProp(client, Prop_Send, "m_zombieClass") != ZOMBIECLASS_TANK)
			continue;

		return client;    // Found tank, return
	}
	return 0;
}

int GetDamageAsPercent(int damage)
{
	return RoundToNearest((damage / g_fMaxTankHealth) * 100.0);
}

// comparing the type of int with the float, how different is it
bool IsExactPercent(int damage)
{
	float fDamageAsPercent = (damage / g_fMaxTankHealth) * 100.0;
	float fDifference      = float(GetDamageAsPercent(damage)) - fDamageAsPercent;
	return (FloatAbs(fDifference) < 0.001) ? true : false;
}

public int SortByDamageDesc(elem1, elem2, const array[], Handle hndl)
{
	// By damage, then by client index, descending
	if (g_iDamage[elem1] > g_iDamage[elem2]) return -1;
	else if (g_iDamage[elem2] > g_iDamage[elem1]) return 1;
	else if (elem1 > elem2) return -1;
	else if (elem2 > elem1) return 1;
	return 0;
}