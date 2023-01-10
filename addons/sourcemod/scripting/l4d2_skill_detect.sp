/**
 *  L4D2_skill_detect
 *
 *  Plugin to detect and forward reports about 'skill'-actions,
 *  such as skeets, crowns, levels, dp's.
 *  Works in campaign and versus modes.
 *
 *  m_isAttemptingToPounce  can only be trusted for
 *  AI hunters -- for human hunters this gets cleared
 *  instantly on taking killing damage
 *
 *  Shotgun skeets and teamskeets are only counted if the
 *  added up damage to pounce_interrupt is done by shotguns
 *  only. 'Skeeting' chipped hunters shouldn't count, IMO.
 *
 *  This performs global forward calls to:
 *      OnSkeet( survivor, hunter )
 *      OnSkeetMelee( survivor, hunter )
 *      OnSkeetGL( survivor, hunter )
 *      OnSkeetSniper( survivor, hunter )
 *      OnSkeetHurt( survivor, hunter, damage, isOverkill )
 *      OnSkeetMeleeHurt( survivor, hunter, damage, isOverkill )
 *      OnSkeetSniperHurt( survivor, hunter, damage, isOverkill )
 *      OnHunterDeadstop( survivor, hunter )
 *      OnBoomerPop( survivor, boomer, shoveCount, Float:timeAlive )
 *      OnChargerLevel( survivor, charger )
 *      OnChargerLevelHurt( survivor, charger, damage )
 *      OnWitchCrown( survivor, damage )
 *      OnWitchCrownHurt( survivor, damage, chipdamage )
 *      OnTongueCut( survivor, smoker )
 *      OnSmokerSelfClear( survivor, smoker, withShove )
 *      OnTankRockSkeeted( survivor, tank )
 *      OnTankRockEaten( tank, survivor )
 *      OnHunterHighPounce( hunter, victim, actualDamage, Float:calculatedDamage, Float:height, bool:bReportedHigh, bool:bPlayerIncapped )
 *      OnJockeyHighPounce( jockey, victim, Float:height, bool:bReportedHigh )
 *      OnDeathCharge( charger, victim, Float: height, Float: distance, wasCarried )
 *      OnSpecialShoved( survivor, infected, zombieClass )
 *      OnSpecialClear( clearer, pinner, pinvictim, zombieClass, Float:timeA, Float:timeB, withShove )
 *      OnBoomerVomitLanded( boomer, amount )
 *      OnBunnyHopStreak( survivor, streak, Float:maxVelocity )
 *      OnCarAlarmTriggered( survivor, infected, reason )
 *
 *      OnDeathChargeAssist( assister, charger, victim )    [ not done yet ]
 *      OnBHop( player, isInfected, speed, streak )         [ not done yet ]
 *
 *  Where survivor == -2 if it was a team effort, -1 or 0 if unknown or invalid client.
 *  damage is the amount of damage done (that didn't add up to skeeting damage),
 *  and isOverkill indicates whether the shot would've been a skeet if the hunter
 *  had not been chipped.
 *
 *  @author         Tabun
 *  @libraryname    skill_detect
 */

#pragma semicolon 1
#pragma newdecls required

#include <colors>
#include <left4dhooks>
#include <sdkhooks>
#include <sdktools>
#include <sourcemod>

#define PLUGIN_VERSION		 "1.1"

#define SHOTGUN_BLAST_TIME	 0.1
#define POUNCE_CHECK_TIME	 0.1
#define HOP_CHECK_TIME		 0.1
#define HOPEND_CHECK_TIME	 0.1	// after streak end (potentially) detected, to check for realz?
#define SHOVE_TIME			 0.05
#define MAX_CHARGE_TIME		 12.0	 // maximum time to pass before charge checking ends
#define CHARGE_CHECK_TIME	 0.25	 // check interval for survivors flying from impacts
#define CHARGE_END_CHECK	 2.5	 // after client hits ground after getting impact-charged: when to check whether it was a death
#define CHARGE_END_RECHECK	 3.0	 // safeguard wait to recheck on someone getting incapped out of bounds
#define VOMIT_DURATION_TIME	 2.25	 // how long the boomer vomit stream lasts -- when to check for boom count
#define ROCK_CHECK_TIME		 0.34	 // how long to wait after rock entity is destroyed before checking for skeet/eat (high to avoid lag issues)
#define CARALARM_MIN_TIME	 0.11	 // maximum time after touch/shot => alarm to connect the two events (test this for LAG)

#define WITCH_CHECK_TIME	 0.1	 // time to wait before checking for witch crown after shoots fired
#define WITCH_DELETE_TIME	 0.15	 // time to wait before deleting entry from witch trie after entity is destroyed

#define MIN_DC_TRIGGER_DMG	 300	  // minimum amount a 'trigger' / drown must do before counted as a death action
#define MIN_DC_FALL_DMG		 175	  // minimum amount of fall damage counts as death-falling for a deathcharge
#define WEIRD_FLOW_THRESH	 900.0	  // -9999 seems to be break flow.. but meh
#define MIN_FLOWDROPHEIGHT	 350.0	  // minimum height a survivor has to have dropped before a WEIRD_FLOW value is treated as a DC spot
#define MIN_DC_RECHECK_DMG	 100	  // minimum damage from map to have taken on first check, to warrant recheck

#define HOP_ACCEL_THRESH	 0.01	 // bhop speed increase must be higher than this for it to count as part of a hop streak

#define ZC_SMOKER			 1
#define ZC_BOOMER			 2
#define ZC_HUNTER			 3
#define ZC_JOCKEY			 5
#define ZC_CHARGER			 6
#define ZC_TANK				 8
#define HITGROUP_HEAD		 1

#define DMG_CRUSH			 (1 << 0)	  // crushed by falling or moving object.
#define DMG_BULLET			 (1 << 1)	  // shot
#define DMG_SLASH			 (1 << 2)	  // cut, clawed, stabbed
#define DMG_CLUB			 (1 << 7)	  // crowbar, punch, headbutt
#define DMG_BUCKSHOT		 (1 << 29)	  // not quite a bullet. Little, rounder, different.

#define DMGARRAYEXT			 7	  // MAXPLAYERS+# -- extra indices in witch_dmg_array + 1

#define CUT_SHOVED			 1	  // smoker got shoved
#define CUT_SHOVEDSURV		 2	  // survivor got shoved
#define CUT_KILL			 3	  // reason for tongue break (release_type)
#define CUT_SLASH			 4	  // this is used for others shoving a survivor free too, don't trust .. it involves tongue damage?

#define VICFLG_CARRIED		 (1 << 0)	 // was the one that the charger carried (not impacted)
#define VICFLG_FALL			 (1 << 1)	 // flags stored per charge victim, to check for deathchargeroony -- fallen
#define VICFLG_DROWN		 (1 << 2)	 // drowned
#define VICFLG_HURTLOTS		 (1 << 3)	 // whether the victim was hurt by 400 dmg+ at once
#define VICFLG_TRIGGER		 (1 << 4)	 // killed by trigger_hurt
#define VICFLG_AIRDEATH		 (1 << 5)	 // died before they hit the ground (impact check)
#define VICFLG_KILLEDBYOTHER (1 << 6)	 // if the survivor was killed by an SI other than the charger
#define VICFLG_WEIRDFLOW	 (1 << 7)	 // when survivors get out of the map and such
#define VICFLG_WEIRDFLOWDONE (1 << 8)	 //      checked, don't recheck for this

// trie values: weapon type
enum strWeaponType
{
	WPTYPE_SNIPER,
	WPTYPE_MAGNUM,
	WPTYPE_GL
};

// trie values: OnEntityCreated classname
enum strOEC
{
	OEC_WITCH,
	OEC_TANKROCK,
	OEC_TRIGGER,
	OEC_CARALARM,
	OEC_CARGLASS
};

// trie values: special abilities
enum strAbility
{
	ABL_HUNTERLUNGE,
	ABL_ROCKTHROW
};

enum
{
	rckDamage,
	rckTank,
	rckSkeeter,
	strRockData
};

// witch array entries (maxplayers+index)
enum
{
	WTCH_NONE,
	WTCH_HEALTH,
	WTCH_GOTSLASH,
	WTCH_STARTLED,
	WTCH_CROWNER,
	WTCH_CROWNSHOT,
	WTCH_CROWNTYPE,
	strWitchArray
};

enum
{
	CALARM_UNKNOWN,
	CALARM_HIT,
	CALARM_TOUCHED,
	CALARM_EXPLOSION,
	CALARM_BOOMER,
	enAlarmReasons
};

char g_csSIClassName[][] = {
	"",
	"smoker",
	"boomer",
	"hunter",
	"spitter",
	"jockey",
	"charger",
	"witch",
	"tank"
};

char g_sDebugFile[256];	 // debug file name
bool g_bLateLoad = false;	 // whether we're loading late (after map has started)

Handle
	g_hForwardSkeet			  = INVALID_HANDLE,
	g_hForwardSkeetHurt		  = INVALID_HANDLE,
	g_hForwardSkeetMelee	  = INVALID_HANDLE,
	g_hForwardSkeetMeleeHurt  = INVALID_HANDLE,
	g_hForwardSkeetSniper	  = INVALID_HANDLE,
	g_hForwardSkeetSniperHurt = INVALID_HANDLE,
	g_hForwardSkeetGL		  = INVALID_HANDLE,
	g_hForwardHunterDeadstop  = INVALID_HANDLE,
	g_hForwardSIShove		  = INVALID_HANDLE,
	g_hForwardBoomerPop		  = INVALID_HANDLE,
	g_hForwardLevel			  = INVALID_HANDLE,
	g_hForwardLevelHurt		  = INVALID_HANDLE,
	g_hForwardCrown			  = INVALID_HANDLE,
	g_hForwardDrawCrown		  = INVALID_HANDLE,
	g_hForwardTongueCut		  = INVALID_HANDLE,
	g_hForwardSmokerSelfClear = INVALID_HANDLE,
	g_hForwardRockSkeeted	  = INVALID_HANDLE,
	g_hForwardRockEaten		  = INVALID_HANDLE,
	g_hForwardHunterDP		  = INVALID_HANDLE,
	g_hForwardJockeyDP		  = INVALID_HANDLE,
	g_hForwardDeathCharge	  = INVALID_HANDLE,
	g_hForwardClear			  = INVALID_HANDLE,
	g_hForwardVomitLanded	  = INVALID_HANDLE,
	g_hForwardBHopStreak	  = INVALID_HANDLE,
	g_hForwardAlarmTriggered  = INVALID_HANDLE,

	g_hTrieWeapons			  = INVALID_HANDLE,	   // weapon check
	g_hTrieEntityCreated	  = INVALID_HANDLE,	   // getting classname of entity created
	g_hTrieAbility			  = INVALID_HANDLE,	   // ability check
	g_hWitchTrie			  = INVALID_HANDLE,	   // witch tracking (Crox)
	g_hRockTrie				  = INVALID_HANDLE,	   // tank rock tracking
	g_hCarTrie				  = INVALID_HANDLE;	   // car alarm tracking

// all SI / pinners
float
	g_fSpawnTime[MAXPLAYERS + 1],	  // time the SI spawned up
	g_fPinTime[MAXPLAYERS + 1][2];	  // time the SI pinned a target: 0 = start of pin (tongue pull, charger carry); 1 = carry end / tongue reigned in
int
	  g_iSpecialVictim[MAXPLAYERS + 1];	   // current victim (set in traceattack, so we can check on death)

// hunters: skeets/pounces
int	  g_iHunterShotDmgTeam[MAXPLAYERS + 1];					 // counting shotgun blast damage for hunter, counting entire survivor team's damage
int	  g_iHunterShotDmg[MAXPLAYERS + 1][MAXPLAYERS + 1];		 // counting shotgun blast damage for hunter / skeeter combo
float g_fHunterShotStart[MAXPLAYERS + 1][MAXPLAYERS + 1];	 // when the last shotgun blast on hunter started (if at any time) by an attacker
float g_fHunterTracePouncing[MAXPLAYERS + 1];				 // time when the hunter was still pouncing (in traceattack) -- used to detect pouncing status
float g_fHunterLastShot[MAXPLAYERS + 1];					 // when the last shotgun damage was done (by anyone) on a hunter
int	  g_iHunterLastHealth[MAXPLAYERS + 1];					 // last time hunter took any damage, how much health did it have left?
int	  g_iHunterOverkill[MAXPLAYERS + 1];					 // how much more damage a hunter would've taken if it wasn't already dead
bool  g_bHunterKilledPouncing[MAXPLAYERS + 1];				 // whether the hunter was killed when actually pouncing
int	  g_iPounceDamage[MAXPLAYERS + 1];						 // how much damage on last 'highpounce' done
float g_fPouncePosition[MAXPLAYERS + 1][3];					 // position that a hunter (jockey?) pounced from (or charger started his carry)

// deadstops
float g_fVictimLastShove[MAXPLAYERS + 1][MAXPLAYERS + 1];	 // when was the player shoved last by attacker? (to prevent doubles)

// levels / charges
int	  g_iChargerHealth[MAXPLAYERS + 1];			// how much health the charger had the last time it was seen taking damage
float g_fChargeTime[MAXPLAYERS + 1];			// time the charger's charge last started, or if victim, when impact started
int	  g_iChargeVictim[MAXPLAYERS + 1];			// who got charged
float g_fChargeVictimPos[MAXPLAYERS + 1][3];	// location of each survivor when it got hit by the charger
int	  g_iVictimCharger[MAXPLAYERS + 1];			// for a victim, by whom they got charge(impacted)
int	  g_iVictimFlags[MAXPLAYERS + 1];			// flags stored per charge victim: VICFLAGS_
int	  g_iVictimMapDmg[MAXPLAYERS + 1];			// for a victim, how much the cumulative map damage is so far (trigger hurt / drowning)

// pops
bool  g_bBoomerHitSomebody[MAXPLAYERS + 1];	   // false if boomer didn't puke/exploded on anybody
int	  g_iBoomerGotShoved[MAXPLAYERS + 1];	   // count boomer was shoved at any point
int	  g_iBoomerVomitHits[MAXPLAYERS + 1];	   // how many booms in one vomit so far

// crowns
float g_fWitchShotStart[MAXPLAYERS + 1];	// when the last shotgun blast from a survivor started (on any witch)

// smoker clears
bool  g_bSmokerClearCheck[MAXPLAYERS + 1];		// [smoker] smoker dies and this is set, it's a self-clear if g_iSmokerVictim is the killer
int	  g_iSmokerVictim[MAXPLAYERS + 1];			// [smoker] the one that's being pulled
int	  g_iSmokerVictimDamage[MAXPLAYERS + 1];	// [smoker] amount of damage done to a smoker by the one he pulled
bool  g_bSmokerShoved[MAXPLAYERS + 1];			// [smoker] set if the victim of a pull manages to shove the smoker

// rocks
int	  g_iTankRock[MAXPLAYERS + 1];	   // rock entity per tank
int	  g_iRocksBeingThrown[10];		   // 10 tanks max simultanously throwing rocks should be ok (this stores the tank client)
int	  g_iRocksBeingThrownCount = 0;	   // so we can do a push/pop type check for who is throwing a created rock

// hops
bool  g_bIsHopping[MAXPLAYERS + 1];			// currently in a hop streak
bool  g_bHopCheck[MAXPLAYERS + 1];			// flag to check whether a hopstreak has ended (if on ground for too long.. ends)
int	  g_iHops[MAXPLAYERS + 1];				// amount of hops in streak
float g_fLastHop[MAXPLAYERS + 1][3];		// velocity vector of last jump
float g_fHopTopVelocity[MAXPLAYERS + 1];	// maximum velocity in hopping streak

// alarms
float g_fLastCarAlarm = 0.0;					// time when last car alarm went off
int	  g_iLastCarAlarmReason[MAXPLAYERS + 1];	// what this survivor did to set the last alarm off
int	  g_iLastCarAlarmBoomer;					// if a boomer triggered an alarm, remember it

// cvars
ConVar
	g_cvarDebug,

	g_cvarReport,
	g_cvarRepSkeet,
	g_cvarRepHurtSkeet,
	g_cvarRepLevel,
	g_cvarRepHurtLevel,
	g_cvarRepCrow,
	g_cvarRepDrawCrow,
	g_cvarRepTongueCut,
	g_cvarRepSelfClear,
	g_cvarRepSelfClearShove,
	g_cvarRepRockSkeet,
	g_cvarRepRockName,
	g_cvarRepDeadStop,
	g_cvarRepPop,
	g_cvarRepShove,
	g_cvarRepHunterDP,
	g_cvarRepJockeyDP,
	g_cvarRepDeathCharge,
	g_cvarRepInstanClear,
	g_cvarRepBhopStreak,
	g_cvarRepCarAlarm,

	g_cvarAllowMelee,			// cvar whether to count melee skeets
	g_cvarAllowSniper,			// cvar whether to count sniper headshot skeets
	g_cvarAllowGLSkeet,			// cvar whether to count direct hit GL skeets
	g_cvarDrawCrownThresh,		// cvar damage in final shot for drawcrown-req.
	g_cvarSelfClearThresh,		// cvar damage while self-clearing from smokers
	g_cvarHunterDPThresh,		// cvar damage for hunter highpounce
	g_cvarJockeyDPThresh,		// cvar distance for jockey highpounce
	g_cvarHideFakeDamage,		// cvar damage while self-clearing from smokers
	g_cvarDeathChargeHeight,	// cvar how high a charger must have come in order for a DC to count
	g_cvarInstaTime,			// cvar clear within this time or lower for instaclear
	g_cvarBHopMinStreak,		// cvar this many hops in a row+ = streak
	g_cvarBHopMinInitSpeed,		// cvar lower than this and the first jump won't be seen as the start of a streak
	g_cvarBHopContSpeed,		// cvar

	g_cvarPounceInterrupt = null;	 // z_pounce_damage_interrupt
int
	g_iPounceInterrupt = 150;

ConVar
	g_cvarChargerHealth		  = null,	 // z_charger_health
	g_cvarWitchHealth		  = null,	 // z_witch_health
	g_cvarMaxPounceDistance	  = null,	 // z_pounce_damage_range_max
	g_cvarMinPounceDistance	  = null,	 // z_pounce_damage_range_min
	g_cvarMaxPounceDamage	  = null,	 // z_hunter_max_pounce_bonus_damage;
	g_hCvarPainPillsDecayRate = null;

/*
	Reports:
	--------
	Damage shown is damage done in the last shot/slash. So for crowns, this means
	that the 'damage' value is one shotgun blast


	Quirks:
	-------
	Does not report people cutting smoker tongues that target players other
	than themselves. Could be done, but would require (too much) tracking.

	Actual damage done, on Hunter DPs, is low when the survivor gets incapped
	by (a fraction of) the total pounce damage.


	Fake Damage
	-----------
	Hiding of fake damage has the following consequences:
		- Drawcrowns are less likely to be registered: if a witch takes too
		  much chip before the crowning shot, the final shot will be considered
		  as doing too little damage for a crown (even if it would have been a crown
		  had the witch had more health).
		- Charger levels are harder to get on chipped chargers. Any charger that
		  has taken (600 - 390 =) 210 damage or more cannot be leveled (even if
		  the melee swing would've killed the charger (1559 damage) if it'd have
		  had full health).
	I strongly recommend leaving fakedamage visible: it will offer more feedback on
	the survivor's action and reward survivors doing (what would be) full crowns and
	levels on chipped targets.


	To Do
	-----

	- fix:  tank rock owner is not reliable for the RockEaten forward
	- fix:  tank rock skeets still unreliable detection (often triggers a 'skeet' when actually landed on someone)

	- fix:  apparently some HR4 cars generate car alarm messages when shot, even when no alarm goes off
			(combination with car equalize plugin?)
			- see below: the single hook might also fix this.. -- if not, hook for sound
			- do a hookoutput on prop_car_alarm's and use that to track the actual alarm
				going off (might help in the case 2 alarms go off exactly at the same time?)
	- fix:  double prints on car alarms (sometimes? epi + m60)

	- fix:  sometimes instaclear reports double for single clear (0.16s / 0.19s) epi saw this, was for hunter
	- fix:  deadstops and m2s don't always register .. no idea why..
	- fix:  sometimes a (first?) round doesn't work for skeet detection.. no hurt/full skeets are reported or counted

	- make forwards fire for every potential action,
		- include the relevant values, so other plugins can decide for themselves what to consider it

	- test chargers getting dislodged with boomer pops?

	- add commonhop check
	- add deathcharge assist check
		- smoker
		- jockey

	- add deathcharge coordinates for some areas
		- DT4 next to saferoom
		- DA1 near the lower roof, on sidewalk next to fence (no hurttrigger there)
		- DA2 next to crane roof to the right of window
			DA2 charge down into start area, after everyone's jumped the fence

	- count rock hits even if they do no damage [epi request]
	- sir
		- make separate teamskeet forward, with (for now, up to) 4 skeeters + the damage each did
	- xan
		- add detection/display of unsuccesful witch crowns (witch death + info)

	detect...
		- ? add jockey deadstops (and change forward to reflect type)
		- ? speedcrown detection?
		- ? spit-on-cap detection

	---
	done:
		- applied sanity bounds to calculated damage for hunter dps
		- removed tank's name from rock skeet print
		- 300+ speed hops are considered hops even if no increase
*/

/*****************************************************************
			L I B R A R Y   I N C L U D E S
*****************************************************************/
#include "l4d2_skill_detect/tracking.sp"
#include "l4d2_skill_detect/report.sp"

public Plugin myinfo =
{
	name		= "Skill Detection (skeets, crowns, levels)",
	author		= "Tabun",
	description = "Detects and reports skeets, crowns, levels, highpounces, etc.",
	version		= PLUGIN_VERSION,
	url			= "https://github.com/Tabbernaut/L4D2-Plugins"


}

public APLRes
	AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("skill_detect");

	g_hForwardSkeet			  = CreateGlobalForward("OnSkeet", ET_Ignore, Param_Cell, Param_Cell);
	g_hForwardSkeetHurt		  = CreateGlobalForward("OnSkeetHurt", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	g_hForwardSkeetMelee	  = CreateGlobalForward("OnSkeetMelee", ET_Ignore, Param_Cell, Param_Cell);
	g_hForwardSkeetMeleeHurt  = CreateGlobalForward("OnSkeetMeleeHurt", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	g_hForwardSkeetSniper	  = CreateGlobalForward("OnSkeetSniper", ET_Ignore, Param_Cell, Param_Cell);
	g_hForwardSkeetSniperHurt = CreateGlobalForward("OnSkeetSniperHurt", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	g_hForwardSkeetGL		  = CreateGlobalForward("OnSkeetGL", ET_Ignore, Param_Cell, Param_Cell);
	g_hForwardSIShove		  = CreateGlobalForward("OnSpecialShoved", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_hForwardHunterDeadstop  = CreateGlobalForward("OnHunterDeadstop", ET_Ignore, Param_Cell, Param_Cell);
	g_hForwardBoomerPop		  = CreateGlobalForward("OnBoomerPop", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Float);
	g_hForwardLevel			  = CreateGlobalForward("OnChargerLevel", ET_Ignore, Param_Cell, Param_Cell);
	g_hForwardLevelHurt		  = CreateGlobalForward("OnChargerLevelHurt", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_hForwardCrown			  = CreateGlobalForward("OnWitchCrown", ET_Ignore, Param_Cell, Param_Cell);
	g_hForwardDrawCrown		  = CreateGlobalForward("OnWitchDrawCrown", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_hForwardTongueCut		  = CreateGlobalForward("OnTongueCut", ET_Ignore, Param_Cell, Param_Cell);
	g_hForwardSmokerSelfClear = CreateGlobalForward("OnSmokerSelfClear", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_hForwardRockSkeeted	  = CreateGlobalForward("OnTankRockSkeeted", ET_Ignore, Param_Cell, Param_Cell);
	g_hForwardRockEaten		  = CreateGlobalForward("OnTankRockEaten", ET_Ignore, Param_Cell, Param_Cell);
	g_hForwardHunterDP		  = CreateGlobalForward("OnHunterHighPounce", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Float, Param_Float, Param_Cell, Param_Cell);
	g_hForwardJockeyDP		  = CreateGlobalForward("OnJockeyHighPounce", ET_Ignore, Param_Cell, Param_Cell, Param_Float, Param_Cell);
	g_hForwardDeathCharge	  = CreateGlobalForward("OnDeathCharge", ET_Ignore, Param_Cell, Param_Cell, Param_Float, Param_Float, Param_Cell);
	g_hForwardClear			  = CreateGlobalForward("OnSpecialClear", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Float, Param_Float, Param_Cell);
	g_hForwardVomitLanded	  = CreateGlobalForward("OnBoomerVomitLanded", ET_Ignore, Param_Cell, Param_Cell);
	g_hForwardBHopStreak	  = CreateGlobalForward("OnBunnyHopStreak", ET_Ignore, Param_Cell, Param_Cell, Param_Float);
	g_hForwardAlarmTriggered  = CreateGlobalForward("OnCarAlarmTriggered", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_bLateLoad				  = late;

	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslation("l4d2_skill_detect.phrases");

	// hooks
	OnHookEvent();

	// version cvar
	CreateConVar("sm_skill_detect_version", PLUGIN_VERSION, "Skill detect plugin version.", FCVAR_NOTIFY | FCVAR_REPLICATED | FCVAR_DONTRECORD);
	g_cvarDebug = CreateConVar("sm_skill_detect_debug", "0", "Enable debug messages.", FCVAR_NOTIFY | FCVAR_REPLICATED | FCVAR_DONTRECORD);

	// cvars: config
	g_cvarReport			= CreateConVar("sm_skill_report_enable", "0", "Whether to report in chat.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarRepSkeet			= CreateConVar("sm_skill_report_skeet", "0", "Enable skeet reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarRepHurtSkeet		= CreateConVar("sm_skill_report_hurtskeet", "0", "Enable hurt-skeet reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarRepLevel			= CreateConVar("sm_skill_report_level", "1", "Enable level reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarRepHurtLevel		= CreateConVar("sm_skill_report_hurtlevel", "1", "Enable hurt-level reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarRepCrow			= CreateConVar("sm_skill_report_crow", "0", "Enable crow reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarRepDrawCrow		= CreateConVar("sm_skill_report_drawcrow", "0", "Enable draw-crow reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarRepTongueCut		= CreateConVar("sm_skill_report_tonguecut", "1", "Enable tongue-cut reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarRepSelfClear		= CreateConVar("sm_skill_report_sc", "1", "Enable self clear reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarRepSelfClearShove = CreateConVar("sm_skill_report_scs", "1", "Enable self clear Shove reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarRepRockSkeet		= CreateConVar("sm_skill_report_rockskeet", "1", "Enable rock-skeet reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarRepRockName		= CreateConVar("sm_skill_report_rockname", "0", "Enable Tank name reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarRepDeadStop		= CreateConVar("sm_skill_report_deadstop", "0", "Enable deadstop reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarRepPop			= CreateConVar("sm_skill_report_pop", "0", "Enable pop reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarRepShove			= CreateConVar("sm_skill_report_shove", "0", "Enable shove reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarRepHunterDP		= CreateConVar("sm_skill_report_hunterdp", "1", "Enable hunter DP reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarRepJockeyDP		= CreateConVar("sm_skill_report_jockeydp", "1", "Enable jockey DP reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarRepDeathCharge	= CreateConVar("sm_skill_report_deadcharger", "1", "Enable deadcharger reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarRepInstanClear	= CreateConVar("sm_skill_report_instanclear", "1", "Enable instan-clear reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarRepBhopStreak		= CreateConVar("sm_skill_report_bhop", "1", "Enable bhop streak reporting.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarRepCarAlarm		= CreateConVar("sm_skill_report_caralarm", "0", "Enable car alarm reporting.", FCVAR_NONE, true, 0.0, true, 1.0);

	g_cvarAllowMelee		= CreateConVar("sm_skill_skeet_allowmelee", "1", "Whether to count/forward melee skeets.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarAllowSniper		= CreateConVar("sm_skill_skeet_allowsniper", "1", "Whether to count/forward sniper/magnum headshots as skeets.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarAllowGLSkeet		= CreateConVar("sm_skill_skeet_allowgl", "1", "Whether to count/forward direct GL hits as skeets.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarDrawCrownThresh	= CreateConVar("sm_skill_drawcrown_damage", "500", "How much damage a survivor must at least do in the final shot for it to count as a drawcrown.", FCVAR_NONE, true, 0.0, false);
	g_cvarSelfClearThresh	= CreateConVar("sm_skill_selfclear_damage", "200", "How much damage a survivor must at least do to a smoker for him to count as self-clearing.", FCVAR_NONE, true, 0.0, false);
	g_cvarHunterDPThresh	= CreateConVar("sm_skill_hunterdp_height", "400", "Minimum height of hunter pounce for it to count as a DP.", FCVAR_NONE, true, 0.0, false);
	g_cvarJockeyDPThresh	= CreateConVar("sm_skill_jockeydp_height", "300", "How much height distance a jockey must make for his 'DP' to count as a reportable highpounce.", FCVAR_NONE, true, 0.0, false);
	g_cvarHideFakeDamage	= CreateConVar("sm_skill_hidefakedamage", "0", "If set, any damage done that exceeds the health of a victim is hidden in reports.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarDeathChargeHeight = CreateConVar("sm_skill_deathcharge_height", "400", "How much height distance a charger must take its victim for a deathcharge to be reported.", FCVAR_NONE, true, 0.0, false);
	g_cvarInstaTime			= CreateConVar("sm_skill_instaclear_time", "0.75", "A clear within this time (in seconds) counts as an insta-clear.", FCVAR_NONE, true, 0.0, false);
	g_cvarBHopMinStreak		= CreateConVar("sm_skill_bhopstreak", "3", "The lowest bunnyhop streak that will be reported.", FCVAR_NONE, true, 0.0, false);
	g_cvarBHopMinInitSpeed	= CreateConVar("sm_skill_bhopinitspeed", "150", "The minimal speed of the first jump of a bunnyhopstreak (0 to allow 'hops' from standstill).", FCVAR_NONE, true, 0.0, false);
	g_cvarBHopContSpeed		= CreateConVar("sm_skill_bhopkeepspeed", "300", "The minimal speed at which hops are considered succesful even if not speed increase is made.", FCVAR_NONE, true, 0.0, false);

	// cvars: built in
	g_cvarPounceInterrupt	= FindConVar("z_pounce_damage_interrupt");
	HookConVarChange(g_cvarPounceInterrupt, CvarChange_PounceInterrupt);
	g_iPounceInterrupt		  = g_cvarPounceInterrupt.IntValue;

	g_cvarChargerHealth		  = FindConVar("z_charger_health");
	g_cvarWitchHealth		  = FindConVar("z_witch_health");

	g_cvarMaxPounceDistance	  = FindConVar("z_pounce_damage_range_max");
	g_cvarMinPounceDistance	  = FindConVar("z_pounce_damage_range_min");
	g_cvarMaxPounceDamage	  = FindConVar("z_hunter_max_pounce_bonus_damage");
	g_hCvarPainPillsDecayRate = FindConVar("pain_pills_decay_rate");

	if (g_cvarMaxPounceDistance == null)
		g_cvarMaxPounceDistance = CreateConVar("z_pounce_damage_range_max", "1000.0", "Not available on this server, added by l4d2_skill_detect.", FCVAR_NONE, true, 0.0, false);
	if (g_cvarMinPounceDistance == null)
		g_cvarMinPounceDistance = CreateConVar("z_pounce_damage_range_min", "300.0", "Not available on this server, added by l4d2_skill_detect.", FCVAR_NONE, true, 0.0, false);
	if (g_cvarMaxPounceDamage == null)
		g_cvarMaxPounceDamage = CreateConVar("z_hunter_max_pounce_bonus_damage", "49", "Not available on this server, added by l4d2_skill_detect.", FCVAR_NONE, true, 0.0, false);

	// tries
	g_hTrieWeapons = CreateTrie();
	SetTrieValue(g_hTrieWeapons, "hunting_rifle", WPTYPE_SNIPER);
	SetTrieValue(g_hTrieWeapons, "sniper_military", WPTYPE_SNIPER);
	SetTrieValue(g_hTrieWeapons, "sniper_awp", WPTYPE_SNIPER);
	SetTrieValue(g_hTrieWeapons, "sniper_scout", WPTYPE_SNIPER);
	SetTrieValue(g_hTrieWeapons, "pistol_magnum", WPTYPE_MAGNUM);
	SetTrieValue(g_hTrieWeapons, "grenade_launcher_projectile", WPTYPE_GL);

	g_hTrieEntityCreated = CreateTrie();
	SetTrieValue(g_hTrieEntityCreated, "tank_rock", OEC_TANKROCK);
	SetTrieValue(g_hTrieEntityCreated, "witch", OEC_WITCH);
	SetTrieValue(g_hTrieEntityCreated, "trigger_hurt", OEC_TRIGGER);
	SetTrieValue(g_hTrieEntityCreated, "prop_car_alarm", OEC_CARALARM);
	SetTrieValue(g_hTrieEntityCreated, "prop_car_glass", OEC_CARGLASS);

	g_hTrieAbility = CreateTrie();
	SetTrieValue(g_hTrieAbility, "ability_lunge", ABL_HUNTERLUNGE);
	SetTrieValue(g_hTrieAbility, "ability_throw", ABL_ROCKTHROW);

	g_hWitchTrie = CreateTrie();
	g_hRockTrie	 = CreateTrie();
	g_hCarTrie	 = CreateTrie();

	static char logFile[PLATFORM_MAX_PATH];
	Format(logFile, sizeof(logFile), "/logs/l4d2_skill_detect.log");
	BuildPath(Path_SM, g_sDebugFile, PLATFORM_MAX_PATH, logFile);	

	if (g_bLateLoad)
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsValidClientInGame(client))
			{
				SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamageByWitch);
			}
		}
	}
}

public void OnHookEvent()
{
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("scavenge_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);

	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("ability_use", Event_AbilityUse, EventHookMode_Post);
	HookEvent("lunge_pounce", Event_LungePounce, EventHookMode_Post);
	HookEvent("player_shoved", Event_PlayerShoved, EventHookMode_Post);
	HookEvent("player_jump", Event_PlayerJumped, EventHookMode_Post);
	HookEvent("player_jump_apex", Event_PlayerJumpApex, EventHookMode_Post);

	HookEvent("player_now_it", Event_PlayerBoomed, EventHookMode_Post);
	HookEvent("boomer_exploded", Event_BoomerExploded, EventHookMode_Post);

	HookEvent("witch_spawn", Event_WitchSpawned, EventHookMode_Post);
	HookEvent("witch_killed", Event_WitchKilled, EventHookMode_Post);
	HookEvent("witch_harasser_set", Event_WitchHarasserSet, EventHookMode_Post);

	HookEvent("tongue_grab", Event_TongueGrab, EventHookMode_Post);
	HookEvent("tongue_pull_stopped", Event_TonguePullStopped, EventHookMode_Post);
	HookEvent("choke_start", Event_ChokeStart, EventHookMode_Post);
	HookEvent("choke_stopped", Event_ChokeStop, EventHookMode_Post);
	HookEvent("jockey_ride", Event_JockeyRide, EventHookMode_Post);
	HookEvent("charger_carry_start", Event_ChargeCarryStart, EventHookMode_Post);
	HookEvent("charger_carry_end", Event_ChargeCarryEnd, EventHookMode_Post);
	HookEvent("charger_impact", Event_ChargeImpact, EventHookMode_Post);
	HookEvent("charger_pummel_start", Event_ChargePummelStart, EventHookMode_Post);

	HookEvent("player_incapacitated_start", Event_IncapStart, EventHookMode_Post);
	HookEvent("triggered_car_alarm", Event_CarAlarmGoesOff, EventHookMode_Post);
}

public void CvarChange_PounceInterrupt(Handle convar, const char[] oldValue, const char[] newValue)
{
	g_iPounceInterrupt = GetConVarInt(convar);
}

public void OnClientPostAdminCheck(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamageByWitch);
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamageByWitch);
}

/*
	--------
	support
	--------
*/

stock int GetSurvivorPermanentHealth(int client)
{
	return GetEntProp(client, Prop_Send, "m_iHealth");
}

stock int GetSurvivorTempHealth(int client)
{
	float fHealthBuffer			= GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	float fHealthBufferDuration = GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");

	int	  iTempHp				= RoundToCeil(fHealthBuffer - (fHealthBufferDuration * g_hCvarPainPillsDecayRate.FloatValue)) - 1;

	return (iTempHp > 0) ? iTempHp : 0;
}

stock float GetSurvivorDistance(int client)
{
	return L4D2Direct_GetFlowDistance(client);
}

stock int ShiftTankThrower()
{
	int tank = -1;

	if (!g_iRocksBeingThrownCount)
		return -1;

	tank = g_iRocksBeingThrown[0];

	// shift the tank array downwards, if there are more than 1 throwers
	if (g_iRocksBeingThrownCount > 1)
	{
		for (int x = 1; x <= g_iRocksBeingThrownCount; x++)
		{
			g_iRocksBeingThrown[x - 1] = g_iRocksBeingThrown[x];
		}
	}

	g_iRocksBeingThrownCount--;

	return tank;
}

stock void PrintDebug(const char[] Message, any ...)
{
	if(!g_cvarDebug.BoolValue)
		return;

	static char sFormat[256];
	VFormat(sFormat, sizeof(sFormat), Message, 2);

	LogToFileEx(g_sDebugFile, sFormat);
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

stock bool IsValidClientIndex(int client)
{
	return (client > 0 && client <= MaxClients);
}

stock bool IsValidClientInGame(int client)
{
	return (IsValidClientIndex(client) && IsClientInGame(client));
}

/**
 * Returns true if the client is currently on the survivor team.
 *
 * @param client client ID
 * @return bool
 */
stock bool IsSurvivor(int client)
{
	return (L4D_GetClientTeam(client) == L4DTeam_Survivor);
}

/**
 * Return true if the client is on the infected team.
 *
 * @param client client ID
 * @return bool
 */
stock bool IsInfected(int client)
{
	return (L4D_GetClientTeam(client) == L4DTeam_Infected);
}

/**
 * Return true if the valid client index and is client on the survivor team.
 *
 * @param client client ID
 * @return bool
 */
stock bool IsValidSurvivor(int client)
{
	return (IsValidClientInGame(client) && IsSurvivor(client));
}

/**
 * Return true if the valid client index and is client on the infected team.
 *
 * @param client client ID
 * @return bool
 */
stock bool IsValidInfected(int client)
{
	return (IsValidClientInGame(client) && IsInfected(client));
}

/**
 * Check if the translation file exists
 *
 * @param translation       translation file name
 */
stock void LoadTranslation(const char[] translation)
{
	char
		sPath[PLATFORM_MAX_PATH],
		sName[64];

	Format(sName, sizeof(sName), "translations/%s.txt", translation);
	BuildPath(Path_SM, sPath, sizeof(sPath), sName);
	if (!FileExists(sPath))
	{
		SetFailState("Missing translation file %s.txt", translation);
	}
	LoadTranslations(translation);
}