#pragma semicolon 1
#pragma newdecls required

#include <colors>
#include <left4dhooks>
#include <sdkhooks>
#include <sdktools>
#include <sourcemod>

#define STR_MAX_WEAPON_LEN 32

#define SHOTGUN_TIME 0.25
#define MELEE_TIME   0.25
#define POUNCE_TIMER 0.1

#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

#define HITGROUP_HEAD 1

#define BREV_SI    1
#define BREV_CI    2
#define BREV_ACC   4
#define BREV_SKEET 8

#define BREV_MELEE 32
#define BREV_DMG   64

// zombie classes
#define ZC_SMOKER  1
#define ZC_BOOMER  2
#define ZC_HUNTER  3
#define ZC_SPITTER 4
#define ZC_JOCKEY  5
#define ZC_CHARGER 6
#define ZC_WITCH   7
#define ZC_TANK    8

// weapon types
#define WPTYPE_NONE    0
#define WPTYPE_SHELLS  1
#define WPTYPE_MELEE   2
#define WPTYPE_BULLETS 3

// weapons
#define WP_MELEE 19

#define WP_PISTOL        1
#define WP_PISTOL_MAGNUM 32

#define WP_SMG          2
#define WP_SMG_SILENCED 7

#define WP_HUNTING_RIFLE   6
#define WP_SNIPER_MILITARY 10

#define WP_PUMPSHOTGUN    3
#define WP_SHOTGUN_CHROME 8
#define WP_AUTOSHOTGUN    4
#define WP_SHOTGUN_SPAS   11

#define WP_RIFLE        5
#define WP_RIFLE_DESERT 9
#define WP_RIFLE_AK47   26

#define WP_MOLOTOV   13
#define WP_PIPE_BOMB 14
#define WP_VOMITJAR  25

#define WP_SMG_MP5      33
#define WP_RIFLE_SG552  34
#define WP_SNIPER_AWP   35
#define WP_SNIPER_SCOUT 36

#define WP_FIRST_AID_KIT 12
#define WP_PAIN_PILLS    15
#define WP_ADRENALINE    23
#define WP_MACHINEGUN    45

/*
    Changelog
    ---------

        0.1f
            - fixed more error spam in error logs
        0.1e
            - fixed error spam in error logs
        0.1d
            - melee accuracy now hidden by default
            - built in some better safeguards against client index out of bounds probs
 */
public Plugin myinfo =
{
	name        = "1v1 SkeetStats",
	author      = "Tabun",
	description = "Shows 1v1-relevant info at end of round.",
	version     = "0.1f",
	url         = "nope"
};

// Handle hPluginEnabled;
// bool bPluginEnabled;

Handle
	hPounceDmgInt     = INVALID_HANDLE,    // skeet-damage per pounce
	hRUPActive        = INVALID_HANDLE,    // whether the ready up mod is active
	hCountTankDamage  = INVALID_HANDLE,    // whether we're tracking tank damage
	hCountWitchDamage = INVALID_HANDLE,    // whether we're tracking witch damage
	hBrevityFlags     = INVALID_HANDLE;    // how verbose/brief the output should be:
/*
        1       leave out Kill stats
        2       leave out CI stats
        4       leave out Accuracy stats
        8       leave out Skeet stats
        32      leave out Melee accuracy
        64      leave out Damage count
*/
bool
	bCountTankDamage,
	bCountWitchDamage,
	bRUPActive;
int
	iBrevityFlags,
	iPounceDmgInt;

char sClientName[MAXPLAYERS + 1][64];    // which name is connected to the clientId?

int
	iGotKills[MAXPLAYERS + 1],          // SI kills             track for each client
	iGotCommon[MAXPLAYERS + 1],         // CI kills
	iDidDamage[MAXPLAYERS + 1],         // SI only              these are a bit redundant, but will keep anyway for now
	iDidDamageAll[MAXPLAYERS + 1],      // SI + tank + witch
	iDidDamageTank[MAXPLAYERS + 1],     // tank only
	iDidDamageWitch[MAXPLAYERS + 1];    // witch only

int
	iShotsFired[MAXPLAYERS + 1],      // shots total
	iPelletsFired[MAXPLAYERS + 1],    // shotgun pellets total
	iShotsHit[MAXPLAYERS + 1],        // shots hit
	iPelletsHit[MAXPLAYERS + 1],      // shotgun pellets hit
	iMeleesFired[MAXPLAYERS + 1],     // melees total
	iMeleesHit[MAXPLAYERS + 1];       // melees hit

int
	iDeadStops[MAXPLAYERS + 1],        // all hunter deadstops (lunging hunters only)
	iHuntSkeets[MAXPLAYERS + 1],       // actual skeets (lunging hunter kills, full/normal)
	iHuntSkeetsInj[MAXPLAYERS + 1],    // injured skeets (< 150.0, on injured hunters)
	iHuntHeadShots[MAXPLAYERS + 1];    // all headshots on hunters (non-skeets too)

bool
	bIsHurt[MAXPLAYERS + 1],        // if a hunter player has been damaged (below 150)
	bIsPouncing[MAXPLAYERS + 1];    // if a hunter player is currently pouncing

int
	iDmgDuringPounce[MAXPLAYERS + 1],    // how much total damage in a single pounce (cumulative)
	iClientPlaying,                      // which clientId is the survivor this round?
	iRoundNumber;

bool
	bLateLoad,
	bInRound,
	bPlayerLeftStartArea;    // used for tracking FF when RUP enabled

float fPreviousShot[MAXPLAYERS + 1];    // when was the previous shotgun blast? (to collect all hits for 1 shot)
int
	iPreviousShotType[MAXPLAYERS + 1],    // weapon id for shotgun/melee that fired previous shot
	bCurrentShotHit[MAXPLAYERS + 1],      // whether we got a hit for the shot
	iCurrentShotDmg[MAXPLAYERS + 1];      // counting shotgun blast damage
/*
int bCurrentShotSkeet[MAXPLAYERS + 1];          // whether we got a full skeet with the shot
int bCurrentShotSkeetInj[MAXPLAYERS + 1];       // whether we got an injured skeet with the shot
*/

/*
 *      init
 *      ====
 */
public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int errMax)
{
	bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("1v1_skeetstats.phrases");
	// Round triggers
	//  HookEvent("door_close", DoorClose_Event);
	//  HookEvent("finale_vehicle_leaving", FinaleVehicleLeaving_Event, EventHookMode_PostNoCopy);
	HookEvent("round_start", RoundStart_Event, EventHookMode_PostNoCopy);
	HookEvent("round_end", RoundEnd_Event, EventHookMode_PostNoCopy);
	HookEvent("player_left_start_area", PlayerLeftStartArea);

	// Catching data
	HookEvent("player_hurt", PlayerHurt_Event, EventHookMode_Post);
	HookEvent("player_death", PlayerDeath_Event, EventHookMode_Post);
	HookEvent("player_shoved", PlayerShoved_Event, EventHookMode_Post);
	HookEvent("infected_hurt", InfectedHurt_Event, EventHookMode_Post);
	HookEvent("infected_death", InfectedDeath_Event, EventHookMode_Post);

	HookEvent("weapon_fire", WeaponFire_Event, EventHookMode_Post);
	HookEvent("ability_use", AbilityUse_Event, EventHookMode_Post);

	// HookEvent("hunter_punched", HunterPunched_Event, EventHookMode_Post);             <== doesn't work, doesn't fire ever
	// HookEvent("hunter_headshot", HunterHeadshot_Event, EventHookMode_Post);           <== doesn't work, doesn't fire ever

	// Cvars
	hCountTankDamage  = CreateConVar("sm_skeetstat_counttank", "0", "Damage on tank counts towards totals if enabled.", FCVAR_NONE, true, 0.0, true, 1.0);
	hCountWitchDamage = CreateConVar("sm_skeetstat_countwitch", "0", "Damage on witch counts towards totals if enabled.", FCVAR_NONE, true, 0.0, true, 1.0);
	hBrevityFlags     = CreateConVar("sm_skeetstat_brevity", "32", "Flags for setting brevity of the report (hide 1:SI, 2:CI, 4:Accuracy, 8:Skeets/Deadstops, 32: melee acc, 64: damage count).", FCVAR_NONE, true, 0.0);

	bCountTankDamage  = GetConVarBool(hCountTankDamage);
	bCountWitchDamage = GetConVarBool(hCountWitchDamage);
	iBrevityFlags     = GetConVarInt(hBrevityFlags);

	HookConVarChange(hCountTankDamage, ConVarChange_CountTankDamage);
	HookConVarChange(hCountWitchDamage, ConVarChange_CountWitchDamage);
	HookConVarChange(hBrevityFlags, ConVarChange_BrevityFlags);

	hPounceDmgInt = FindConVar("z_pounce_damage_interrupt");
	iPounceDmgInt = GetConVarInt(hPounceDmgInt);
	HookConVarChange(hPounceDmgInt, ConVarChange_PounceDmgInt);

	// RUP?
	hRUPActive = FindConVar("l4d_ready_enabled");
	if (hRUPActive != INVALID_HANDLE)
	{
		// hook changes for this, and set state appropriately
		bRUPActive = GetConVarBool(hRUPActive);
		HookConVarChange(hRUPActive, ConVarChange_RUPActive);
	}
	else {
		// not loaded
		bRUPActive = false;
	}
	bPlayerLeftStartArea = false;

	// Commands
	RegConsoleCmd("sm_skeets", SkeetStat_Cmd, "Prints the current skeetstats.");

	RegConsoleCmd("say", Say_Cmd);
	RegConsoleCmd("say_team", Say_Cmd);

	// late loading
	if (bLateLoad)
	{
		bPlayerLeftStartArea = true;                    // assume they left it
		iClientPlaying       = GetCurrentSurvivor();    // find survivor again
	}
}

/*
public OnPluginEnd()
{
    // nothing
}
*/
public void OnClientPutInServer(int client)
{
	char tmpBuffer[64];
	GetClientName(client, tmpBuffer, sizeof(tmpBuffer));

	// if previously stored name for same client is not the same, delete stats & overwrite name
	if (strcmp(tmpBuffer, sClientName[client], true) != 0)
	{
		ClearClientSkeetStats(client);

		// store name for later reference
		strcopy(sClientName[client], 64, tmpBuffer);
	}
}

/*
 *      convar changes  (phase this out later)
 *      ==============
 */
public void ConVarChange_CountTankDamage(Handle cvar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 0)
	{
		bCountTankDamage = false;
	}
	else
	{
		bCountTankDamage = true;
	}
}

public void ConVarChange_CountWitchDamage(Handle cvar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 0)
	{
		bCountWitchDamage = false;
	}
	else
	{
		bCountWitchDamage = true;
	}
}

public void ConVarChange_BrevityFlags(Handle cvar, const char[] oldValue, const char[] newValue)
{
	iBrevityFlags = StringToInt(newValue);
}

public void ConVarChange_RUPActive(Handle cvar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 0)
	{
		bRUPActive = false;
	}
	else
	{
		bRUPActive = true;
	}
}

public void ConVarChange_PounceDmgInt(Handle cvar, const char[] oldValue, const char[] newValue)
{
	iPounceDmgInt = StringToInt(newValue);
}

/*
 *      map load / round start/end
 *      ==========================
 */
public Action PlayerLeftStartArea(Handle event, const char[] name, bool dontBroadcast)
{
	iClientPlaying       = GetCurrentSurvivor();
	bPlayerLeftStartArea = true;    // if RUP active, now we can start tracking
	return Plugin_Continue;
}

public void OnMapStart()
{
	if (!bLateLoad)    // apparently mapstart gets called even after.. it has already started
	{
		bPlayerLeftStartArea = false;
	}
	bLateLoad = false;    // make sure leftstartarea gets reset after a lateload
}

public void OnMapEnd()
{
	iRoundNumber = 0;
	bInRound     = false;
}

public void RoundStart_Event(Handle event, const char[] name, bool dontBroadcast)
{
	iClientPlaying       = GetCurrentSurvivor();
	bPlayerLeftStartArea = false;

	if (!bInRound)
	{
		bInRound = true;
		iRoundNumber++;
	}

	// clear mvp stats
	int i,
		maxplayers = MaxClients;
	for (i = 1; i <= maxplayers; i++)
	{
		ClearClientSkeetStats(i);
	}
}

public void RoundEnd_Event(Handle event, const char[] name, bool dontBroadcast)
{
	// only show / log stuff when the round is done "the first time"
	if (bInRound)
	{
		ResolveOpenShots();    // just in case there are any shots opened.
		CreateTimer(3.0, delayedSkeetStatPrint);
		bInRound = false;
	}
}

/*
 *      cmds / reports
 *      ==============
 */
public Action Say_Cmd(int client, int args)
{
	if (!client)
	{
		return Plugin_Continue;
	}

	char sMessage[MAX_NAME_LENGTH];
	GetCmdArg(1, sMessage, sizeof(sMessage));

	if (StrEqual(sMessage, "!skeets"))
	{
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action SkeetStat_Cmd(int client, int args)
{
	// FloatSub(GetEngineTime(), fPreviousShot[user]) < SHOTGUN_TIME             // <-- use this to avoid the following from affecting stats.. maybe.
	ResolveOpenShots();    // make sure we're up to date (this *might* affect the stats, but it'd have to be insanely badly timed
	PrintSkeetStats(client);
	return Plugin_Handled;
}

public Action delayedSkeetStatPrint(Handle timer)
{
	PrintSkeetStats(0);
	return Plugin_Continue;
}

/*
 *      track damage/kills & accuracy
 *      =============================
 */
public void PlayerHurt_Event(Handle event, const char[] name, bool dontBroadcast)
{
	int zombieClass = 0;

	int victimId = GetEventInt(event, "userid");
	int victim   = GetClientOfUserId(victimId);

	int attackerId = GetEventInt(event, "attacker");
	int attacker   = GetClientOfUserId(attackerId);

	if (attacker != iClientPlaying)    // ignore shots fired by anyone but survivor player
	{
		return;
	}
	if (GetClientTeam(victim) != TEAM_INFECTED)    // safeguard
	{
		return;
	}

	int damage     = GetEventInt(event, "dmg_health");
	int damagetype = GetEventInt(event, "type");
	int hitgroup   = GetEventInt(event, "hitgroup");

	// accuracy track
	if (damagetype & DMG_BUCKSHOT)
	{
		// shotgun

		// this is still part of the (previous) shotgun blast
		iCurrentShotDmg[iClientPlaying] += damage;

		// are we skeeting hunters?
		if (bIsPouncing[victim])
		{
			iDmgDuringPounce[victim] += damage;
			// CPrintToChatAll("[test] pounce/SG dmg: %d (total: %d / duringpounce: %d / remain: %d)", damage, iCurrentShotDmg[iClientPlaying], iDmgDuringPounce[victim], health);
		}
		if (!bCurrentShotHit[iClientPlaying])    // only count headshot once for shotgun blast (not that it matters, but this might miss some hs's)
		{
			if (hitgroup == HITGROUP_HEAD)
			{
				iHuntHeadShots[iClientPlaying]++;
			}
		}

		bCurrentShotHit[iClientPlaying] = true;
	}
	else if (damagetype & DMG_BULLET)
	{
		// for bullets, simply count all hits
		iShotsHit[iClientPlaying]++;
		if (hitgroup == HITGROUP_HEAD)
		{
			iHuntHeadShots[iClientPlaying]++;
		}

		// are we skeeting hunters?
		if (bIsPouncing[victim])
		{
			iDmgDuringPounce[victim] += damage;
			// CPrintToChatAll("[test] pounce/BUL dmg: %d (duringpounce: %d / remain: %d)", damage, iDmgDuringPounce[victim], health);
		}
	}
	else if (damagetype & DMG_SLASH || damagetype & DMG_CLUB)
	{
		// for melees, like shotgun (multiple hits for one, so just count once)
		if (iPreviousShotType[iClientPlaying] == WP_MELEE && (GetEngineTime() - fPreviousShot[iClientPlaying]) < MELEE_TIME)
		{
			bCurrentShotHit[iClientPlaying] = true;
		}
	}

	// track damage

	// survivor on zombie action
	zombieClass = GetEntProp(victim, Prop_Send, "m_zombieClass");

	// separately store SI and tank damage
	if (zombieClass >= ZC_SMOKER && zombieClass < ZC_WITCH)
	{
		iDidDamage[attacker] += damage;
		iDidDamageAll[attacker] += damage;
	}
	else if (zombieClass == ZC_TANK && bCountTankDamage)
	{
		iDidDamageAll[attacker] += damage;
		iDidDamageTank[attacker] += damage;
	}
}

public void InfectedHurt_Event(Handle event, const char[] name, bool dontBroadcast)
{
	// check user
	int userId = GetEventInt(event, "attacker");
	int user   = GetClientOfUserId(userId);

	if (user != iClientPlaying)    // ignore shots fired by anyone but survivor player
	{
		return;
	}

	// check if round started
	if (!bPlayerLeftStartArea)    // don't count saferoom shooting for now.
	{
		return;
	}
	if (bRUPActive && GetEntityMoveType(user) == MOVETYPE_NONE)    // ignore any shots by RUP-frozen player
	{
		return;
	}

	int damage      = GetEventInt(event, "amount");
	int damageType  = GetEventInt(event, "type");
	int victimEntId = GetEventInt(event, "entityid");

	// accuracy track

	/*---- Test -------------------------------------
	char weapon[STR_MAX_WEAPON_LEN];
	GetClientWeapon(user, weapon, sizeof(weapon));
	int weaponId = WeaponNameToId(weapon);
	int weaponType = GetWeaponType(weaponId);
	char tmp[STR_MAX_WEAPON_LEN];
	if (damageType & DMG_BULLET)
	{
	    tmp = "bullet";
	}
	if (damageType & DMG_SLASH)
	{
	    tmp = "slash";
	}
	if (damageType & DMG_CLUB)
	{
	    tmp = "club";
	}
	if (damageType & DMG_BUCKSHOT)
	{
	    tmp = "buckshot";
	}
	CPrintToChatAll("InfHurt WP: %s [%d] - dmg: %d / type: %s", weapon, WeaponNameToId(weapon), damage, tmp); */
	//---- Test -------------------------------------

	// shotgun
	if (damageType & DMG_BUCKSHOT)
	{
		// if (FloatSub(GetEngineTime(), fPreviousShot[user]) < SHOTGUN_TIME) { // don't do this for now, open/close shotgun is otherwise resolved

		// this is still part of the (previous) shotgun blast
		bCurrentShotHit[iClientPlaying] = true;
		if (IsCommonInfected(victimEntId))
		{
			switch (iPreviousShotType[iClientPlaying])
			{
				case WP_PUMPSHOTGUN:    // max 123 on common (250)
				{
					damage = RoundFloat(float(damage) * 2.03);
				}
				case WP_SHOTGUN_CHROME:    // max 151 on common (248)
				{
					damage = RoundFloat(float(damage) * 1.64);
				}
				case WP_AUTOSHOTGUN:    // max 113 on common (253)
				{
					damage = RoundFloat(float(damage) * 2.29);
				}
				case WP_SHOTGUN_SPAS:    // max 137 on common (252)
				{
					damage = RoundFloat(float(damage) * 1.84);
				}
			}
		}
		else if (IsWitch(victimEntId))
		{
			int damageDone = damage;

			// event called per pellet
			switch (iPreviousShotType[iClientPlaying])
			{
				case WP_PUMPSHOTGUN:
				{
					damage = 25;
				}
				case WP_SHOTGUN_CHROME:
				{
					damage = 31;
				}
				case WP_AUTOSHOTGUN:
				{
					damage = 23;
				}
				case WP_SHOTGUN_SPAS:
				{
					damage = 28;
				}
			}
			// also note that crowns do 1 pellet damage less than actual, for some reason, so add it:
			//          each pellet doing > 100 means close enough to the crown
			if (iCurrentShotDmg[iClientPlaying] + damage > 200 && damageDone > 100) { damage = damage * 2; }
		}
		iCurrentShotDmg[iClientPlaying] += damage;
	}
	else if (damageType & DMG_BULLET)
	{
		// for bullets, simply count all hits
		iShotsHit[iClientPlaying]++;
	}
	else if (damageType & DMG_SLASH || damageType & DMG_CLUB)
	{
		// for melees, like shotgun (multiple hits for one, so just count once)
		if (iPreviousShotType[iClientPlaying] == WP_MELEE && (GetEngineTime() - fPreviousShot[iClientPlaying]) < MELEE_TIME)
		{
			bCurrentShotHit[iClientPlaying] = true;
		}
	}

	// witch (damage)
	if (IsWitch(victimEntId))
	{
		int damageDone = GetEventInt(event, "amount");

		// no world damage or flukes or whatevs, no bot attackers
		if (bCountWitchDamage)
		{
			iDidDamageAll[user] += damageDone;
			iDidDamageWitch[user] += damageDone;
		}
	}
}

public void PlayerDeath_Event(Handle event, const char[] name, bool dontBroadcast)
{
	int zombieClass = 0;

	int victimId = GetEventInt(event, "userid");
	int victim   = GetClientOfUserId(victimId);

	int attackerId = GetEventInt(event, "attacker");
	int attacker   = GetClientOfUserId(attackerId);

	if (attacker != iClientPlaying)    // ignore shots fired by anyone but survivor player
	{
		return;
	}
	if (!IsClientAndInGame(victim))    // safeguard
	{
		return;
	}
	if (GetClientTeam(victim) != TEAM_INFECTED)    // safeguard
	{
		return;
	}

	int damagetype = GetEventInt(event, "type");

	// skeet check
	if (damagetype & DMG_BUCKSHOT || damagetype & DMG_BULLET)
	{
		// shotgun

		// CPrintToChatAll("[test] death: (pounce: %d, abort: %d, ishurt: %d, total dmg: %d / duringpounce: %d)", bIsPouncing[victim], GetEventBool(event, "abort"), bIsHurt[victim], iCurrentShotDmg[iClientPlaying], iDmgDuringPounce[victim]);

		// did we skeet a hunter?
		if (bIsPouncing[victim])
		{
			if (bIsHurt[victim])    // inj. skeet
			{
				iHuntSkeetsInj[iClientPlaying]++;
			}
			else    // normal/full skeet
			{
				iHuntSkeets[iClientPlaying]++;
			}
			bIsPouncing[victim]      = false;
			iDmgDuringPounce[victim] = 0;
		}
	}

	// kill-count
	zombieClass = GetEntProp(victim, Prop_Send, "m_zombieClass");

	// only SI, not the tank && only player-attackers
	if (zombieClass >= ZC_SMOKER && zombieClass < ZC_WITCH)
	{
		// store kill to count for attacker id
		iGotKills[attacker]++;

		if (zombieClass == ZC_HUNTER)
		{
			// check if we just skeeted this
		}
	}
}

public void InfectedDeath_Event(Handle event, const char[] name, bool dontBroadcast)
{
	int attackerId = GetEventInt(event, "attacker");
	int attacker   = GetClientOfUserId(attackerId);

	if (attackerId && IsClientAndInGame(attacker))
	{
		if ((GetClientTeam(attacker) == TEAM_SURVIVOR))
		{
			iGotCommon[attacker]++;
		}
	}
}

public void PlayerShoved_Event(Handle event, const char[] name, bool dontBroadcast)
{
	// check user
	int userId = GetEventInt(event, "attacker");
	int user   = GetClientOfUserId(userId);

	if (user != iClientPlaying)    // ignore actions by anyone else
	{
		return;
	}

	// get hunter player
	int victimId = GetEventInt(event, "userId");
	int victim   = GetClientOfUserId(victimId);

	if (bIsPouncing[victim])
	{
		iDeadStops[user]++;
		bIsPouncing[victim]      = false;
		iDmgDuringPounce[victim] = 0;
	}
}

// hunters pouncing / tracking
public void AbilityUse_Event(Handle event, const char[] name, bool dontBroadcast)
{
	// track hunters pouncing
	int  userId = GetEventInt(event, "userid");
	int  user   = GetClientOfUserId(userId);
	char abilityName[64];

	GetEventString(event, "ability", abilityName, sizeof(abilityName));

	if (IsClientAndInGame(user) && strcmp(abilityName, "ability_lunge", false) == 0 && !bIsPouncing[user])
	{
		// Hunter pounce
		bIsPouncing[user]      = true;
		iDmgDuringPounce[user] = 0;    // use this to track skeet-damage
		bIsHurt[user]          = (GetClientHealth(user) < iPounceDmgInt);
		CreateTimer(POUNCE_TIMER, groundTouchTimer, user, TIMER_REPEAT);    // check every TIMER whether the pounce has ended
		                                                                    // If the hunter lands on another player's head, they're technically grounded.
		                                                                    // Instead of using isGrounded, this uses the bIsPouncing[] array with less precise timer

		// CPrintToChatAll("[test] pounce starts: (ishurt: %d / h: %d)", bIsHurt[user], GetClientHealth(user));
	}
}

public Action groundTouchTimer(Handle timer, int client)
{
	if (IsClientAndInGame(client) && (isGrounded(client) || !IsPlayerAlive(client)))
	{
		// Reached the ground or died in mid-air
		bIsPouncing[client] = false;
		KillTimer(timer);
	}
	return Plugin_Continue;
}

public bool isGrounded(int client)
{
	return (GetEntProp(client, Prop_Data, "m_fFlags") & FL_ONGROUND) > 0;
}

// accuracy:
public void WeaponFire_Event(Handle event, const char[] name, bool dontBroadcast)
{
	// check user
	int userId = GetEventInt(event, "userid");
	int user   = GetClientOfUserId(userId);
	if (user != iClientPlaying)    // ignore shots fired by anyone but survivor player
	{
		return;
	}

	// check if round started
	if (!bPlayerLeftStartArea)    // don't count saferoom shooting for now.
	{
		return;
	}
	if (bRUPActive && GetEntityMoveType(user) == MOVETYPE_NONE)    // ignore any shots by RUP-frozen player
	{
		return;
	}

	int weaponId = GetEventInt(event, "weaponid");
	int count    = GetEventInt(event, "count");

	//-- test -------------------------------------
	/*
	decl String:weapon[64];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	CPrintToChatAll("WF: %s [%d] - cnt: %d .", weapon, weaponId, count);
	*/
	//-- test -------------------------------------

	// differentiate between weapon types
	int weaponType = GetWeaponType(weaponId);

	// 1. shotgun blasts (keep track of pellets, separate shot accuracy from pellet accuracy
	if (weaponType == WPTYPE_SHELLS)
	{
		// handle previous shot, if any open
		ResolveOpenShots();

		// open new shot
		iShotsFired[iClientPlaying]++;
		iPelletsFired[iClientPlaying] += count;
		fPreviousShot[iClientPlaying]     = GetEngineTime();    // track shot from this time
		bCurrentShotHit[iClientPlaying]   = false;              // so we can check just 1 hit for the shot
		iCurrentShotDmg[iClientPlaying]   = 0;                  // reset, count damage for this shot
		iPreviousShotType[iClientPlaying] = weaponId;           // so we know what kind of shotgun blast it was
		return;
	}

	// 2. melee
	if (weaponType == WPTYPE_MELEE)
	{
		// handle previous shot, if any open
		ResolveOpenShots();

		iMeleesFired[iClientPlaying]++;
		fPreviousShot[iClientPlaying]     = GetEngineTime();    // track shot from this time
		bCurrentShotHit[iClientPlaying]   = false;              // so we can check just 1 hit for the swing
		iCurrentShotDmg[iClientPlaying]   = 0;                  // reset, count damage for this shot
		iPreviousShotType[iClientPlaying] = WP_MELEE;           // so we know a melee is 'out'
		return;
	}

	// 3. rifles / snipers / pistols (per shot accuracy)
	if (weaponType == WPTYPE_BULLETS)
	{
		iShotsFired[iClientPlaying]++;
		return;
	}

	// 4. weird cases: pain pills / medkits
	// not relevant, ignore for now
}

/*
 *      Stat string
 *      ======================
 */

void PrintSkeetStats(int toClient)
{
	char printBuffer[512];
	char tmpBuffer[256];

	printBuffer = "";

	if (iClientPlaying <= 0)
	{
		return;
	}

	/*
	//decl String:tmpName[64];
	if (!IsClientConnected(iClientPlaying)) {
	    tmpName = sClientName[iClientPlaying];
	} else {
	    Format(tmpName, sizeof(tmpName),"%N", iClientPlaying);
	} */

	// no need to calculate, show stats
	//  1. SI damage & SI kills
	//  2. skeets
	//  3. accuracy
	//  4. common kills

	/*
	    TODO: make it so:
	    1v1Stat - Kills: (934 Dmg, 4 Kills) (23 Common)
	    1v1Stat - Skeet: (1 Normal, 3 Injured) (5 Deadstops)
	    1v1Stat - Acc. : (Total [72%], Per Pellet [25%]) (3 Headshots)
	*/

	// report
	// 1
	if (!(iBrevityFlags & BREV_SI))
	{
		if (!(iBrevityFlags & BREV_DMG))
		{
			if (!(iBrevityFlags & BREV_CI))
			{
				Format(tmpBuffer, sizeof(tmpBuffer), "%t %t", "TagKills", "SI_DMG_CI", iDidDamageAll[iClientPlaying], iGotKills[iClientPlaying], iGotCommon[iClientPlaying]);
			}
			else
			{
				Format(tmpBuffer, sizeof(tmpBuffer), "%t %t", "TagKills", "SI_DMG", iDidDamageAll[iClientPlaying], iGotKills[iClientPlaying]);
			}
		}
		else
		{
			if (!(iBrevityFlags & BREV_CI))
			{
				Format(tmpBuffer, sizeof(tmpBuffer), "%t %t", "TagKills", "SI_CI", iGotKills[iClientPlaying], iGotCommon[iClientPlaying]);
			}
			else
			{
				Format(tmpBuffer, sizeof(tmpBuffer), "%t %t", "TagKills", "SI", iGotKills[iClientPlaying]);
			}
		}
		StrCat(printBuffer, sizeof(printBuffer), tmpBuffer);

		if (!toClient)
		{
			CPrintToChatAll("%s", printBuffer);
		}
		else if (IsClientAndInGame(toClient))
		{
			CPrintToChat(toClient, "%s", printBuffer);
		}
		printBuffer = "";
	}

	if (!(iBrevityFlags & BREV_SKEET))
	{
		Format(tmpBuffer, sizeof(tmpBuffer), "%t %t", "TagSkeet", "SKEET", iHuntSkeets[iClientPlaying], iHuntSkeetsInj[iClientPlaying], iDeadStops[iClientPlaying]);
		StrCat(printBuffer, sizeof(printBuffer), tmpBuffer);

		if (!toClient)
		{
			CPrintToChatAll("%s", printBuffer);
		}
		else if (IsClientAndInGame(toClient))
		{
			CPrintToChat(toClient, "%s", printBuffer);
		}
		printBuffer = "";
	}

	if (!(iBrevityFlags & BREV_ACC))
	{
		if (iShotsFired[iClientPlaying] || (iMeleesFired[iClientPlaying] && !(iBrevityFlags & BREV_MELEE)))
		{
			if (iShotsFired[iClientPlaying])
			{
				Format(tmpBuffer, sizeof(tmpBuffer), "%t %t", "TagAcc", "ACC_AllShots", float(iShotsHit[iClientPlaying]) / float(iShotsFired[iClientPlaying]) * 100);
			}
			else {
				Format(tmpBuffer, sizeof(tmpBuffer), "%t %t", "TagAcc", "ACC_AllShots", 0.0);
			}
			if (iPelletsFired[iClientPlaying])
			{
				StrCat(printBuffer, sizeof(printBuffer), tmpBuffer);
				Format(tmpBuffer, sizeof(tmpBuffer), "%t", "ACC_BuckShot", float(iPelletsHit[iClientPlaying]) / float(iPelletsFired[iClientPlaying]) * 100);
			}
			if (iMeleesFired[iClientPlaying] && !(iBrevityFlags & BREV_MELEE))
			{
				StrCat(printBuffer, sizeof(printBuffer), tmpBuffer);
				Format(tmpBuffer, sizeof(tmpBuffer), "%t", "ACC_Melee", float(iMeleesHit[iClientPlaying]) / float(iMeleesFired[iClientPlaying]) * 100);
			}
			StrCat(printBuffer, sizeof(printBuffer), tmpBuffer);
			Format(tmpBuffer, sizeof(tmpBuffer), "\n");
		}
		else
		{
			Format(tmpBuffer, sizeof(tmpBuffer), "%t %t", "TagAcc", "ACC_NoShotsFired");
		}
		StrCat(printBuffer, sizeof(printBuffer), tmpBuffer);

		if (!toClient)
		{
			CPrintToChatAll("%s", printBuffer);
		}
		else if (IsClientAndInGame(toClient))
		{
			CPrintToChat(toClient, "%s", printBuffer);
		}
		printBuffer = "";
	}
}

/*
 *      general functions
 *      =================
 */

// resolve hits, for the final shotgun blasts before wipe/saferoom
public void ResolveOpenShots()
{
	if (iClientPlaying <= 0)
	{
		return;
	}

	// if there's any shotgun blast not 'closed', close it
	if (iPreviousShotType[iClientPlaying])
	{
		if (bCurrentShotHit[iClientPlaying])
		{
			if (iPreviousShotType[iClientPlaying] == WP_MELEE)
			{
				// melee hit
				iMeleesHit[iClientPlaying]++;
			}
			else
			{
				// shotgun hit
				iShotsHit[iClientPlaying]++;

				// base hit pellets on amount of damage done
				// based on weaponId differences aswell since shotties do different amounts of damage
				// what to do about damage dropoff? ignore?
				if (iCurrentShotDmg[iClientPlaying])
				{
					int
						iTotalPellets,
						iPelletDamage;
					switch (iPreviousShotType[iClientPlaying])
					{
						case WP_PUMPSHOTGUN:
						{
							iTotalPellets = 10;
							iPelletDamage = 25;
						}
						case WP_SHOTGUN_CHROME:
						{
							iTotalPellets = 8;
							iPelletDamage = 31;
						}
						case WP_AUTOSHOTGUN:
						{
							iTotalPellets = 11;
							iPelletDamage = 23;
						}
						case WP_SHOTGUN_SPAS:
						{
							iTotalPellets = 9;
							iPelletDamage = 28;
						}
					}
					if (iTotalPellets)
					{
						int addPellets = RoundFloat(float(iCurrentShotDmg[iClientPlaying] / iPelletDamage));
						iPelletsHit[iClientPlaying] += (addPellets <= iTotalPellets) ? addPellets : iTotalPellets;
					}
					// test
					// CPrintToChatAll("RESOLVE: %d hit, damage %d, dmg/pellet %d", RoundFloat(float(iCurrentShotDmg[iClientPlaying] / iPelletDamage )), iCurrentShotDmg[iClientPlaying], iPelletDamage);
				}
			}
		}
		iPreviousShotType[iClientPlaying] = 0;
	}
}

// get type of weapon fired, diff between shotgun, melee and bullets
stock int GetWeaponType(int weaponId)
{
	// 1. shotgun
	if (weaponId == WP_PUMPSHOTGUN
	    || weaponId == WP_SHOTGUN_CHROME
	    || weaponId == WP_AUTOSHOTGUN
	    || weaponId == WP_SHOTGUN_SPAS)
	{
		return WPTYPE_SHELLS;
	}

	// 2. melee
	if (weaponId == WP_MELEE)
	{
		return WPTYPE_MELEE;
	}

	// 3. rifles / snipers / pistols (per shot accuracy)
	if (weaponId == WP_PISTOL
	    || weaponId == WP_PISTOL_MAGNUM
	    || weaponId == WP_SMG
	    || weaponId == WP_SMG_SILENCED
	    || weaponId == WP_SMG_MP5
	    || weaponId == WP_HUNTING_RIFLE
	    || weaponId == WP_SNIPER_MILITARY
	    || weaponId == WP_RIFLE
	    || weaponId == WP_RIFLE_DESERT
	    || weaponId == WP_RIFLE_AK47
	    || weaponId == WP_RIFLE_SG552
	    || weaponId == WP_SNIPER_AWP
	    || weaponId == WP_SNIPER_SCOUT
	    || weaponId == WP_MACHINEGUN)
	{
		return WPTYPE_BULLETS;
	}
	return WPTYPE_NONE;
}

// get 1v1 survivor player
stock int GetCurrentSurvivor()
{
	// assuming only 1, just get the first one
	int i,
		maxplayers = MaxClients;
	for (i = 1; i <= maxplayers; i++)
	{
		if (IsSurvivor(i))
		{
			return i;
		}
	}
	return -1;
}

// clear all stats for client
stock void ClearClientSkeetStats(int client)
{
	iGotKills[client]       = 0;
	iGotCommon[client]      = 0;
	iDidDamage[client]      = 0;
	iDidDamageAll[client]   = 0;
	iDidDamageWitch[client] = 0;
	iDidDamageTank[client]  = 0;

	iShotsFired[client]    = 0;
	iPelletsFired[client]  = 0;
	iShotsHit[client]      = 0;
	iPelletsHit[client]    = 0;
	iMeleesFired[client]   = 0;
	iMeleesHit[client]     = 0;
	iDeadStops[client]     = 0;
	iHuntSkeets[client]    = 0;
	iHuntSkeetsInj[client] = 0;
	iHuntHeadShots[client] = 0;

	fPreviousShot[client]     = 0.0;
	iPreviousShotType[client] = 0;
	bCurrentShotHit[client]   = 0;
	iCurrentShotDmg[client]   = 0;

	bIsPouncing[client]      = false;
	bIsHurt[client]          = false;
	iDmgDuringPounce[client] = 0;
}

stock bool IsClientAndInGame(int index)
{
	return (index > 0 && index <= MaxClients && IsClientInGame(index));
}

stock bool IsSurvivor(int client)
{
	return IsClientAndInGame(client) && GetClientTeam(client) == TEAM_SURVIVOR;
}

stock bool IsInfected(int client)
{
	return IsClientAndInGame(client) && GetClientTeam(client) == TEAM_INFECTED;
}

stock bool IsWitch(int iEntity)
{
	if (iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
	{
		char strClassName[64];
		GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
		return StrEqual(strClassName, "witch");
	}
	return false;
}

stock bool IsCommonInfected(int iEntity)
{
	if (iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
	{
		char strClassName[64];
		GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
		return StrEqual(strClassName, "infected");
	}
	return false;
}
