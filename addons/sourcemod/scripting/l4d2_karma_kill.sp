#pragma newdecls required
#pragma semicolon 1

#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#include <left4dhooks>
#include <multicolors>

#define PLUGIN_VERSION "4.2"

#define CVAR_FLAGS                    FCVAR_NOTIFY
#define CVAR_FLAGS_PLUGIN_VERSION     FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY

bool TEST_DEBUG = false;

static const float NO_MERCY_DEBUG_ORIGIN[] = { 7547.976563, 3661.247803, 78.031250 };

// All of these must be 0.1 * n, basically 0.1, 0.2, 0.3, 0.4...
// All of these are seconds after you reach the height you jumped from.

bool g_bMapStarted   = false;
bool g_bRoundStarted = false;

float JOCKEY_JUMP_SECONDS_NEEDED_AGAINST_LEDGE_HANG_PER_FORCE = 0.3;
float IMPACT_SECONDS_NEEDED_AGAINST_LEDGE_HANG                = 0.3;
float SMOKE_SECONDS_NEEDED_AGAINST_LEDGE_HANG                 = 0.3;
float PUNCH_SECONDS_NEEDED_AGAINST_LEDGE_HANG                 = 0.3;
float FLING_SECONDS_NEEDED_AGAINST_LEDGE_HANG                 = 0.3;

float CHARGE_CHECKING_INTERVAL = 0.1;

float ANGLE_STRAIGHT_DOWN[3] = { 90.0, 0.0, 0.0 };
char  SOUND_EFFECT[]         = "./level/loud/climber.wav";

ConVar cvarisEnabled, cvarNoFallDamageOnCarry, cvarNoFallDamageProtectFromIncap;
ConVar karmaPrefix, karmaJump, karmaAwardConfirmed, karmaDamageAwardConfirmed, karmaOnlyConfirmed,
	karmaBirdCharge, karmaSlowTimeOnServer, karmaSlowTimeOnCouple, karmaSlow, cvarModeSwitch,
	cvarCooldown, cvarAllowDefib;
bool g_bEnabled, g_bNoFallDamageOnCarry, g_bkarmaJump, g_bkarmaOnlyConfirmed, g_bkarmaBirdCharge,
	g_bNoFallDamageProtectFromIncap, g_bModeSwitch, g_bAllowDefib;
int g_ikarmaAwardConfirmed;
float g_fkarmaSlowTimeOnServer, g_fkarmaSlowTimeOnCouple, g_fkarmaSlow, g_fCooldown;
char g_sPrefix[64];

ConVar cvarFatalFallDamage;
float g_fFatalFallDamage;


Handle fw_OnKarmaEventPost = INVALID_HANDLE;
Handle fw_OnKarmaJumpPost  = INVALID_HANDLE;

enum
{
	KT_Charge = 0,
	KT_Impact,
	KT_Jockey,
	KT_Slap,
	KT_Punch,
	KT_Smoke,
	KT_Stagger,
	KT_Jump,
	KarmaType_MAX
};

char karmaNames[KarmaType_MAX][] = {
	"Charge",
	"Impact",
	"Jockey",
	"Slap",
	"Punch",
	"Smoke",
	"Stagger",
	"Jump",
};

// I'll probably eventually add a logger for karma jumps and add "lastDistance" to this enum struct that dictates the closest special infected if maybe something messed up.
enum struct enLastKarma
{
	// Artist is 0 when no karma is found, and set to -1 when a karma artist is not present
	int  artist;
	char artistName[64];
	char artistSteamId[35];

	// lastPos is only for karma jumps, it is the last origin a victim was before the jump.
	float lastPos[3];

	// artistHealth is only for karma jumps. It is the health the player had prior to the jump.
	// artistWeapons is only for karma jumps. It is the list of weapon refs the player had prior to the jump.
	// artistTimestamp is only for karma jumps, it is the timestamp
	int   artistHealth[2];
	int   artistWeapons[64];
	float artistTimestamp;
}

enLastKarma LastKarma[MAXPLAYERS + 1][KarmaType_MAX];

float preJumpHeight[MAXPLAYERS + 1];
float apexHeight[MAXPLAYERS + 1];
// Height at which we caught a survivor as charger
// This is set to current height whenever the charger is on the ground.
float catchHeight[MAXPLAYERS + 1];

Handle chargerTimer[MAXPLAYERS] = { INVALID_HANDLE, ... };

enum struct enVictimTimer
{
	Handle   timer;
	DataPack dp;
}

enVictimTimer victimTimer[MAXPLAYERS];
Handle        ledgeTimer[MAXPLAYERS] = { INVALID_HANDLE, ... };

/* Blockers have two purposes:
1. For the duration they are there, the last responsible karma maker cannot change.
2. BlockAllChange must be active to register a karma that isn't height check based. This is because it is triggered upon the survivor being hurt.
*/

bool   BlockAnnounce[MAXPLAYERS + 1];
Handle AllKarmaRegisterTimer[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };
Handle BlockRegisterTimer[MAXPLAYERS + 1]    = { INVALID_HANDLE, ... };
Handle JockRegisterTimer[MAXPLAYERS + 1]     = { INVALID_HANDLE, ... };
Handle SlapRegisterTimer[MAXPLAYERS + 1]     = { INVALID_HANDLE, ... };
Handle PunchRegisterTimer[MAXPLAYERS + 1]    = { INVALID_HANDLE, ... };
Handle SmokeRegisterTimer[MAXPLAYERS + 1]    = { INVALID_HANDLE, ... };
Handle JumpRegisterTimer[MAXPLAYERS + 1]     = { INVALID_HANDLE, ... };

Handle cooldownTimer = INVALID_HANDLE;

float fLogHeight[MAXPLAYERS + 1] = { -1.0, ... };

public Plugin myinfo =
{
	name        = "L4D2 Karma Kill System",
	author      = "AtomicStryker, heavy edit by Eyal282, Harry",
	description = "Very Very loudly announces the predicted event of a player leaving the map and or life through height or drown.",
	version     = PLUGIN_VERSION,
	url         = "http://forums.alliedmods.net/showthread.php?p=1239108"

};

bool bLate;
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion test = GetEngineVersion();

    if( test != Engine_Left4Dead2 )
    {
        strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
        return APLRes_SilentFailure;
    }

    bLate = late;
    return APLRes_Success;
}

public void fuckZones_OnStartTouchZone_Post(int client, int entity, const char[] zone_name, int type)
{
	OnCheckKarmaZoneTouch(client, entity, zone_name);
}

void OnCheckKarmaZoneTouch(int victim, int entity, const char[] zone_name, int pinner = 0)
{
	if (!IsPlayerAlive(victim) || L4D_IsPlayerGhost(victim))
		return;

	// This is for bad out of bounds areas that we don't want to exist.
	if (StrContains(zone_name, "ForcePummel", false) != -1)
	{
		L4DTeam team = L4D_GetClientTeam(victim);

		if (team == L4DTeam_Infected)
		{
			if (L4D2_GetPlayerZombieClass(victim) == L4D2ZombieClass_Charger)
			{
				int trueVictim = L4D_GetVictimCarry(victim);

				if (trueVictim != 0)
				{
					int ability = L4D_GetPlayerCustomAbility(victim);

					if (ability != -1)
					{
						// Make game think we're on ground because you don't pummel mid-air.
						SetEntityFlags(victim, GetEntityFlags(victim) | FL_ONGROUND);

						// Set time at which we started charging to the beginning of the map, usually over 100 seconds.
						SetEntPropFloat(ability, Prop_Send, "m_chargeStartTime", 0.0);

						SetEntityFlags(victim, GetEntityFlags(victim) | FL_ONGROUND);

						TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, view_as<float>({ 0.0, 0.0, 0.0 }));
					}
				}
			}
		}
	}

	if (StrContains(zone_name, "KarmaKill", false) == -1)
		return;

	L4DTeam team = L4D_GetClientTeam(victim);

	int trueVictim = 0;

	if (team == L4DTeam_Infected)
	{
		trueVictim = L4D_GetPinnedSurvivor(victim);

		if (trueVictim != 0)
		{
			OnCheckKarmaZoneTouch(trueVictim, entity, zone_name, victim);

			if (!IsPlayerAlive(trueVictim))
				CreateTimer(0.1, Timer_ResetAbility, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);
		}
	}

	bool bInfectedKiller = false;

	if (StrContains(zone_name, "KarmaKillAll", false) != -1 || StrContains(zone_name, "KarmaKillAny", false) != -1)
		bInfectedKiller = true;

	if (team == L4DTeam_Infected && !bInfectedKiller)
		return;

	float fOrigin[3], fZoneOrigin[3];

	GetEntPropVector(victim, Prop_Data, "m_vecAbsOrigin", fOrigin);
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", fZoneOrigin);

	// 62.0 is player height
	if (fOrigin[2] + 62.0 < fZoneOrigin[2])
	{
		float fVelocity[3];
		GetEntPropVector(victim, Prop_Data, "m_vecVelocity", fVelocity);

		if (fVelocity[2] > 0.0)
			fVelocity[2] = 0.0;

		TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, fVelocity);

		return;
	}

	if (team == L4DTeam_Survivor)
	{
		if (IsDoubleCharged(victim) && pinner != 0)
		{
			ClearAllPinners(victim);

			float fPinnerOrigin[3];

			GetEntPropVector(pinner, Prop_Data, "m_vecAbsOrigin", fPinnerOrigin);

			TeleportEntity(victim, fPinnerOrigin, NULL_VECTOR, NULL_VECTOR);
		}

		// Enable ability to register karma kills by simulating fall damage
		if (AllKarmaRegisterTimer[victim] != INVALID_HANDLE)
		{
			CloseHandle(AllKarmaRegisterTimer[victim]);
			AllKarmaRegisterTimer[victim] = INVALID_HANDLE;
		}

		AllKarmaRegisterTimer[victim] = CreateTimer(3.0, RegisterAllKarmaDelay, victim);

		if (g_bAllowDefib)
		{
		// Makes body undefibable.
		SetEntProp(victim, Prop_Send, "m_isFallingFromLedge", true);
		}

		// Incap & kill, this should not trigger the SDKHook_OnTakeDamage
		SDKHooks_TakeDamage(victim, victim, victim, 10000.0, DMG_FALL);
		SDKHooks_TakeDamage(victim, victim, victim, 10000.0, DMG_FALL);

		// Safety measures.
		if (IsPlayerAlive(victim))
		{
			ForcePlayerSuicide(victim);

			int type;
			int lastKarma = GetAnyLastKarma(victim, type);

			if (lastKarma != 0)
				AnnounceKarma(lastKarma, victim, type, false, true);
		}
	}
}

public void OnPluginStart()
{
	HookEvent("player_jump", event_PlayerJump, EventHookMode_Post);

	HookEvent("player_bot_replace", event_BotReplacesAPlayer, EventHookMode_Post);
	HookEvent("bot_player_replace", event_PlayerReplacesABot, EventHookMode_Post);
	HookEvent("player_spawn", event_PlayerSpawn, EventHookMode_Post);

	HookEvent("charger_carry_kill", event_ChargerKill, EventHookMode_Post);
	HookEvent("charger_carry_start", event_ChargerGrab, EventHookMode_Post);
	HookEvent("charger_carry_end", event_GrabEnded, EventHookMode_Post);
	HookEvent("jockey_ride", event_jockeyRideStart, EventHookMode_Post);
	HookEvent("jockey_ride_end", event_jockeyRideEndPre, EventHookMode_Pre);
	HookEvent("tongue_grab", event_tongueGrabOrRelease, EventHookMode_Post);
	HookEvent("tongue_release", event_tongueGrabOrRelease, EventHookMode_Post);
	HookEvent("charger_impact", event_ChargerImpact, EventHookMode_Post);
	HookEvent("player_ledge_grab", Event_PlayerLedgeGrab, EventHookMode_Post);
	HookEvent("player_death", event_playerDeathPre, EventHookMode_Pre);
	HookEvent("round_start_post_nav", event_RoundStartPostNav, EventHookMode_Post);
	HookEvent("round_start", event_RoundStart, EventHookMode_Post);
	HookEvent("round_end", event_RoundEnd, EventHookMode_Post);

	cvarFatalFallDamage = FindConVar("survivor_incap_max_fall_damage");

	karmaPrefix                      = CreateConVar("l4d2_karma_charge_prefix", "提示", "公告的前缀. 对颜色代码之间的内容 .例如: [{olive}%s{default}]", CVAR_FLAGS);
	karmaJump                        = CreateConVar("l4d2_karma_jump", "1", "启用慢动作跳跃. 仅确认必定击杀时才会出现慢动作特效.", CVAR_FLAGS, true, 0.0, true, 1.0);
	karmaAwardConfirmed              = CreateConVar("l4d2_karma_award_confirmed", "1", "用玩家的死亡事件奖励一个确认的慢动作制造者.", CVAR_FLAGS, true, 0.0, true, 1.0);
	karmaDamageAwardConfirmed        = CreateConVar("l4d2_karma_damage_award_confirmed", "300", "在确认击杀后获得伤害分数奖励, 或者-1表示禁用.要求l4d2_karma_award_confirmed设置为1.", CVAR_FLAGS, true, -1.0);
	karmaOnlyConfirmed               = CreateConVar("l4d2_karma_only_confirmed", "0", "仅死亡还是任意时刻出现慢动作特效", CVAR_FLAGS, true, 0.0, true, 1.0);
	karmaBirdCharge                  = CreateConVar("l4d2_karma_kill_bird", "1", "当charger从高度撞下玩家时(即使不致命), 是否进行慢动作特效", CVAR_FLAGS, true, 0.0, true, 1.0);
	karmaSlowTimeOnServer            = CreateConVar("l4d2_karma_kill_slowtime_on_server", "5.0", " 对服务器来说, 时间会被减慢多长时间", CVAR_FLAGS, true, 1.0);
	karmaSlowTimeOnCouple            = CreateConVar("l4d2_karma_kill_slowtime_on_couple", "3.0", " 时间会在多长的时间内被放慢, 以便于衔接慢动作特效", CVAR_FLAGS, true, 1.0);
	karmaSlow                        = CreateConVar("l4d2_karma_kill_slowspeed", "0.2", " 时间变慢多少倍. 最好是不低于0.03，否则服务器就会崩溃", CVAR_FLAGS, true, 0.03);
	cvarisEnabled                    = CreateConVar("l4d2_karma_kill_enabled", "1", " 是否启用慢动作特效 ", CVAR_FLAGS, true, 0.0, true, 1.0);
	cvarNoFallDamageOnCarry          = CreateConVar("l4d2_karma_kill_no_fall_damage_on_carry", "1", "通过禁用携带时的坠落伤害来解决这个问题: https://streamable.com/xuipb6", CVAR_FLAGS, true, 0.0, true, 1.0);
	cvarNoFallDamageProtectFromIncap = CreateConVar("l4d2_karma_kill_no_fall_damage_protect_from_incap", "0", "如果倒地时受到超过224的伤害则死亡.", CVAR_FLAGS, true, 0.0, true, 1.0);
	cvarModeSwitch                   = CreateConVar("l4d2_karma_kill_slowmode", "0", " 0 - 整个服务器都会搜到慢动作特效, 1 - 只有Charger和携带的生还者有慢动作特效", CVAR_FLAGS, true, 0.0, true, 1.0);
	cvarCooldown                     = CreateConVar("l4d2_karma_kill_cooldown", "0.0", "如果slowmode为0, 下一个慢动作特效需要多长时间来冻结整个地图. 从上一次冻结的结束时间开始计算", CVAR_FLAGS, true, 0.0);
	cvarAllowDefib                   = CreateConVar("l4d2_karma_kill_allow_defib", "0", " 是否运行电击器复活因慢动作特效死亡的生还者? 0 - 否, 1 - 是.", CVAR_FLAGS, true, 0.0, true, 1.0);
	CreateConVar("l4d2_karma_charge_version", PLUGIN_VERSION, " L4D2 Karma Charge Plugin Version ", CVAR_FLAGS_PLUGIN_VERSION);
	AutoExecConfig(true, "l4d2_karma_kill");

	GetCvars();
	cvarFatalFallDamage.AddChangeHook(ConVarChanged_Cvars);
	karmaPrefix.AddChangeHook(ConVarChanged_Cvars);
	karmaJump.AddChangeHook(ConVarChanged_Cvars);
	karmaAwardConfirmed.AddChangeHook(ConVarChanged_Cvars);
	karmaDamageAwardConfirmed.AddChangeHook(ConVarChanged_Cvars);
	karmaOnlyConfirmed.AddChangeHook(ConVarChanged_Cvars);
	karmaBirdCharge.AddChangeHook(ConVarChanged_Cvars);
	karmaSlowTimeOnServer.AddChangeHook(ConVarChanged_Cvars);
	karmaSlowTimeOnCouple.AddChangeHook(ConVarChanged_Cvars);
	karmaSlow.AddChangeHook(ConVarChanged_Cvars);
	cvarisEnabled.AddChangeHook(ConVarChanged_Cvars);
	cvarNoFallDamageOnCarry.AddChangeHook(ConVarChanged_Cvars);
	cvarNoFallDamageProtectFromIncap.AddChangeHook(ConVarChanged_Cvars);
	cvarModeSwitch.AddChangeHook(ConVarChanged_Cvars);
	cvarCooldown.AddChangeHook(ConVarChanged_Cvars);
	cvarAllowDefib.AddChangeHook(ConVarChanged_Cvars);

	fw_OnKarmaEventPost = CreateGlobalForward("KarmaKillSystem_OnKarmaEventPost", ET_Ignore, Param_Cell, Param_Cell, Param_String, Param_Cell, Param_Cell, Param_Cell);
	fw_OnKarmaJumpPost  = CreateGlobalForward("KarmaKillSystem_OnKarmaJumpPost", ET_Ignore, Param_Cell, Param_Array, Param_Array, Param_Array, Param_Cell, Param_String, Param_String);

	//RegConsoleCmd("sm_xyz", Command_XYZ);
	//RegAdminCmd("sm_ultimateheightdebug", Command_UltimateKarma, ADMFLAG_ROOT);

	if(bLate)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i))
				continue;

			OnClientPutInServer(i);
		}

		g_bRoundStarted = true;
	}
}

/**
 * Description
 *
 * @param victim             Muse that was honored to model a karma event
 * @param attacker           Artist that crafted the karma event. The only way to check if attacker is valid is: if(attacker > 0)
 * @param KarmaName          Name of karma: "Charge", "Impact", "Jockey", "Slap", "Punch", "Smoke"
 * @param bBird              true if a bird charge event occured, false if a karma kill was detected or performed.
 * @param bKillConfirmed     Whether or not this indicates the complete death of the player. This is NOT just !IsPlayerAlive(victim)
 * @param bOnlyConfirmed     Whether or not only kill confirmed are allowed.

 * @noreturn
 * @note					This can be called more than once. One for the announcement, one for the kill confirmed.
                            If you want to reward both killconfirmed and killunconfirmed you should reward when killconfirmed is false.
                            If you want to reward if killconfirmed you should reward when killconfirmed is true.

 * @note					If the plugin makes a kill confirmed without a previous announcement without kill confirmed,
                            it compensates by sending two consecutive events, one without kill confirmed, one with kill confirmed.



 */
forward void KarmaKillSystem_OnKarmaEventPost(int victim, int attacker, const char[] KarmaName, bool bBird, bool bKillConfirmed, bool bOnlyConfirmed);

/**
 * Description
 *
 * @param victim             Player who got killed by the karma jump. This can be anybody. Useful to revive the victim.
 * @param lastPos            Origin from which the jump began.
 * @param jumperWeapons		 Weapon Refs of the jumper at the moment of the jump. Every invalid slot is -1
 * @param jumperHealth    	 jumperHealth[0] and jumperHealth[1] = Health and Temp health from which the jump began.
 * @param jumperTimestamp    Timestamp from which the jump began.
 * @param jumperSteamId      jumper's Steam ID.
 * @param jumperName     	 jumper's name

 * @noreturn

 */
forward void KarmaKillSystem_OnKarmaJumpPost(int victim, float lastPos[3], int jumperWeapons[64], int jumperHealth[2], float jumperTimestamp, char[] jumperSteamId, char[] jumperName);

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, SDKEvent_OnTakeDamage);
}

// I don't know why, but player_hurt won't trigger on incap in the boathouse finale...
public Action SDKEvent_OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	if (L4D_GetClientTeam(victim) != L4DTeam_Survivor)
		return Plugin_Continue;

	// In Last Stand you can take shallow drown damage similar to cstrike drowning, gotta ensure at least 100 damage.
	// Dead Air has a spot where you take 5000 crush damage.
	if (damage >= 100.0 && (damagetype == DMG_DROWN || damagetype == DMG_FALL || damage >= 5000.0))
	{
		if (fLogHeight[victim] != -1.0)
		{
			DebugLogToFile("karma_var.log", "{ %.1f, %f },", fLogHeight[victim], damage);
			SetEntityHealth(victim, 65535);
			// fLogHeight[victim] += 2.5;
			fLogHeight[victim] -= 2.5;
		}

		if (AllKarmaRegisterTimer[victim] != INVALID_HANDLE)
		{
			CloseHandle(AllKarmaRegisterTimer[victim]);
			AllKarmaRegisterTimer[victim] = INVALID_HANDLE;
		}

		AllKarmaRegisterTimer[victim] = CreateTimer(3.0, RegisterAllKarmaDelay, victim);

		RegisterCaptor(victim);

		if (g_bAllowDefib)
		{
			SetEntProp(victim, Prop_Send, "m_isFallingFromLedge", false);
		}
		if (g_bNoFallDamageOnCarry && L4D_GetAttackerCarry(victim) != 0)
		{
			damage = 0.0;
			return Plugin_Changed;
		}

		else if (g_bNoFallDamageProtectFromIncap && damage >= g_fFatalFallDamage && L4D_IsPlayerIncapacitated(victim))
		{
			// Spike it!
			damage *= 64.0;
			return Plugin_Changed;
		}
	}

	return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
	if (chargerTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(chargerTimer[client]);
		chargerTimer[client] = INVALID_HANDLE;
	}

	if (victimTimer[client].timer != INVALID_HANDLE)
	{
		CloseHandle(victimTimer[client].timer);
		victimTimer[client].timer = INVALID_HANDLE;
		victimTimer[client].dp    = null;
	}

	if (ledgeTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(ledgeTimer[client]);
		ledgeTimer[client] = INVALID_HANDLE;
	}

	if (IsFakeClient(client))
	{
		StripKarmaArtistFromVictim(client, KarmaType_MAX);
		StripKarmaVictimsFromArtist(client, KarmaType_MAX);
	}
}

public void OnMapEnd()
{
	g_bMapStarted = false;
}

public void OnMapStart()
{
	g_bMapStarted = true;

	PrefetchSound(SOUND_EFFECT);
	PrecacheSound(SOUND_EFFECT);

	for (int i = 1; i <= MaxClients; i++)
	{
		delete chargerTimer[i];
		delete ledgeTimer[i];
		delete victimTimer[i].timer;
		victimTimer[i].dp = null;

		delete AllKarmaRegisterTimer[i];
		delete BlockRegisterTimer[i];
		delete JockRegisterTimer[i];
		delete SlapRegisterTimer[i];
		delete PunchRegisterTimer[i];
		delete SmokeRegisterTimer[i];
		delete JumpRegisterTimer[i];

		apexHeight[i]  = -65535.0;
		catchHeight[i] = -65535.0;
		fLogHeight[i]  = -1.0;
	}

	cooldownTimer = INVALID_HANDLE;
}

public void ConVarChanged_Cvars(Handle hCvar, const char[] sOldVal, const char[] sNewVal)
{
	GetCvars();
}

void GetCvars()
{
	g_fFatalFallDamage = cvarFatalFallDamage.FloatValue;
	karmaPrefix.GetString(g_sPrefix, sizeof(g_sPrefix));
	g_bkarmaJump = karmaJump.BoolValue;
	g_ikarmaAwardConfirmed = karmaDamageAwardConfirmed.IntValue;
	g_bkarmaOnlyConfirmed = karmaOnlyConfirmed.BoolValue;
	g_bkarmaBirdCharge = karmaBirdCharge.BoolValue;
	g_fkarmaSlowTimeOnServer = karmaSlowTimeOnServer.FloatValue;
	g_fkarmaSlowTimeOnCouple = karmaSlowTimeOnCouple.FloatValue;
	g_fkarmaSlow = karmaSlow.FloatValue;
	g_bEnabled = cvarisEnabled.BoolValue;
	g_bNoFallDamageOnCarry = cvarNoFallDamageOnCarry.BoolValue;
	g_bNoFallDamageProtectFromIncap = cvarNoFallDamageProtectFromIncap.BoolValue;
	g_bModeSwitch = cvarModeSwitch.BoolValue;
	g_fCooldown = cvarCooldown.FloatValue;
	g_bAllowDefib = cvarAllowDefib.BoolValue;
}

public void Plugins_OnJockeyJumpPost(int victim, int jockey, float fForce)
{
	AttachKarmaToVictim(victim, jockey, KT_Jockey);

	JockRegisterTimer[victim] = CreateTimer(0.7, EndLastJockey, victim);

	if (victimTimer[victim].timer != INVALID_HANDLE)
	{
		CloseHandle(victimTimer[victim].timer);
		victimTimer[victim].timer = INVALID_HANDLE;
		victimTimer[victim].dp    = null;
	}

	victimTimer[victim].timer = CreateDataTimer(CHARGE_CHECKING_INTERVAL, Timer_CheckVictim, victimTimer[victim].dp, TIMER_REPEAT);

	victimTimer[victim].dp.WriteFloat(JOCKEY_JUMP_SECONDS_NEEDED_AGAINST_LEDGE_HANG_PER_FORCE * (fForce / 500.0));
	victimTimer[victim].dp.WriteCell(victim);
	victimTimer[victim].dp.WriteCell(INVALID_HANDLE);
}

public void L4D2_OnPounceOrLeapStumble_Post(int victim, int attacker)
{
	if (victim < 1 || victim > MaxClients || attacker < 1 || attacker > MaxClients)
		return;

	else if (L4D_GetClientTeam(victim) != L4DTeam_Survivor || L4D_GetClientTeam(attacker) != L4DTeam_Infected)
		return;

	DettachKarmaFromVictim(victim, KT_Jump);

	// No need to set up a remove timer, because as long as the player is under stagger, the player is saving the status.
}

public void L4D2_OnStagger_Post(int victim, int attacker)
{
	if (victim < 1 || victim > MaxClients || attacker < 1 || attacker > MaxClients)
		return;

	else if (L4D_GetClientTeam(victim) != L4DTeam_Survivor || L4D_GetClientTeam(attacker) != L4DTeam_Infected)
		return;

	AttachKarmaToVictim(victim, attacker, KT_Stagger);

	return;
}

public void L4D2_OnPlayerFling_Post(int victim, int attacker, const float vecDir[3])
{
	if (victim < 1 || victim > MaxClients || attacker < 1 || attacker > MaxClients)
		return;

	else if (L4D_GetClientTeam(victim) != L4DTeam_Survivor || L4D_GetClientTeam(attacker) != L4DTeam_Infected)
		return;

	L4D2ZombieClassType class = L4D2_GetPlayerZombieClass(attacker);

	if (class == L4D2ZombieClass_Boomer)    // Boomer
	{
		AttachKarmaToVictim(victim, attacker, KT_Slap);

		if (SlapRegisterTimer[victim] != INVALID_HANDLE)
		{
			CloseHandle(SlapRegisterTimer[victim]);
			SlapRegisterTimer[victim] = INVALID_HANDLE;
		}

		SlapRegisterTimer[victim] = CreateTimer(0.25, RegisterSlapDelay, victim);

		if (victimTimer[victim].timer != INVALID_HANDLE)
		{
			CloseHandle(victimTimer[victim].timer);
			victimTimer[victim].timer = INVALID_HANDLE;
			victimTimer[victim].dp    = null;
		}

		victimTimer[victim].timer = CreateDataTimer(CHARGE_CHECKING_INTERVAL, Timer_CheckVictim, victimTimer[victim].dp, TIMER_REPEAT);

		victimTimer[victim].dp.WriteFloat(FLING_SECONDS_NEEDED_AGAINST_LEDGE_HANG);
		victimTimer[victim].dp.WriteCell(victim);
		victimTimer[victim].dp.WriteCell(INVALID_HANDLE);
	}
}

public Action Timer_CheckVictim(Handle timer, DataPack DP)
{
	DP.Reset();

	float secondsLeft = DP.ReadFloat();
	int   client      = DP.ReadCell();

	Handle hIgnoreTimer = DP.ReadCell();

	if (!IsClientInGame(client))
	{
		victimTimer[client].timer = INVALID_HANDLE;
		victimTimer[client].dp    = null;
		return Plugin_Stop;
	}

	if (!IsPlayerAlive(client))
	{
		victimTimer[client].timer = INVALID_HANDLE;
		victimTimer[client].dp    = null;
		return Plugin_Stop;
	}

	int type;
	int lastKarma = GetAnyLastKarma(client, type);

	if (lastKarma == 0)
	{
		victimTimer[client].timer = INVALID_HANDLE;
		victimTimer[client].dp    = null;
		return Plugin_Stop;
	}

	else if (GetEntProp(client, Prop_Send, "m_isHangingFromLedge"))
	{
		victimTimer[client].timer = INVALID_HANDLE;
		victimTimer[client].dp    = null;
		return Plugin_Stop;
	}

	else if (L4D_GetAttackerSmoker(client) > 0)
		return Plugin_Continue;

	float fOrigin[3], fEndOrigin[3], fEndPredictedOrigin[3], fMins[3], fMaxs[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", fOrigin);

	if (fOrigin[2] > preJumpHeight[client])
		return Plugin_Continue;

	// Cannot hang to a ledge when this much lower than jump height
	else if (preJumpHeight[client] > fOrigin[2] + 64.0)
		secondsLeft = 0.0;

	ArrayList aEntities = new ArrayList(1);

	GetClientMins(client, fMins);
	GetClientMaxs(client, fMaxs);

	TR_TraceRayFilter(fOrigin, ANGLE_STRAIGHT_DOWN, MASK_PLAYERSOLID, RayType_Infinite, TraceFilter_DontHitPlayersAndClips);

	TR_GetEndPosition(fEndOrigin);

	// Now try again with hull to avoid funny stuff.

	TR_TraceHullFilter(fOrigin, fEndOrigin, fMins, fMaxs, MASK_PLAYERSOLID, TraceFilter_DontHitPlayersAndClips);

	TR_GetEndPosition(fEndOrigin);

	float fPlaneNormal[3];
	// For bird charges to find if it's a slope.
	TR_GetPlaneNormal(INVALID_HANDLE, fPlaneNormal);

	if (fPlaneNormal[2] < 0.7 && fPlaneNormal[2] != 0.0)
	{
		apexHeight[client] -= 50.0 * CHARGE_CHECKING_INTERVAL;    // To reduce situations where the slope fakes a karma, usually slopes protect karma.

		float fVelocity[3], fModifiedVelocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);

		float fVector[3];

		fModifiedVelocity = fVelocity;

		if (GetVectorLength(fModifiedVelocity) < 1000.0)
		{
			NormalizeVector(fModifiedVelocity, fModifiedVelocity);
			ScaleVector(fModifiedVelocity, 1000.0);

			if (fModifiedVelocity[2] < -64.0)
				fModifiedVelocity[2] = -64.0;
		}

		fVector[0] = fOrigin[0] + fModifiedVelocity[0];
		fVector[1] = fOrigin[1] + fModifiedVelocity[1];
		fVector[2] = fOrigin[2];

		TR_TraceRayFilter(fVector, ANGLE_STRAIGHT_DOWN, MASK_PLAYERSOLID, RayType_Infinite, TraceFilter_DontHitPlayersAndClips);

		TR_GetEndPosition(fEndPredictedOrigin);

		TR_TraceHullFilter(fVector, fEndPredictedOrigin, fMins, fMaxs, MASK_PLAYERSOLID, TraceFilter_DontHitPlayersAndClips);

		TR_GetEndPosition(fEndPredictedOrigin);

		int ent = TR_GetEntityIndex();

		if (ent != -1)
		{
			char sClassname[64];
			GetEdictClassname(ent, sClassname, sizeof(sClassname));
		}

		// Now make a trace between fOrigin and fEndPredictedOrigin.
		TR_TraceHullFilter(fOrigin, fEndPredictedOrigin, fMins, fMaxs, MASK_PLAYERSOLID, TraceFilter_DontHitPlayersAndClips);

		TR_GetEndPosition(fEndPredictedOrigin);

		TR_EnumerateEntities(fOrigin, fEndPredictedOrigin, PARTITION_SOLID_EDICTS | PARTITION_TRIGGER_EDICTS | PARTITION_STATIC_PROPS, RayType_EndPoint, TraceEnum_TriggerHurt, aEntities);

		if (IsServerDebugMode())
		{
			TE_SetupBeamPoints(fOrigin, fEndPredictedOrigin, PrecacheModel("materials/vgui/white_additive.vmt"), 0, 0, 0, 10.0, 10.0, 10.0, 0, 10.0, { 255, 0, 0, 255 }, 50);
			TE_SendToAllInRange(fOrigin, RangeType_Audibility);
		}
	}

	// You must EXCEED 340.0 height fall damage to instantly die at 100 health.

	// 62 is player height

	if (!CanClientSurviveFall(client, apexHeight[client] - (fEndOrigin[2] + 62.0)))
	{
		if (secondsLeft <= 0.0)
		{
			AnnounceKarma(lastKarma, client, type, false, false, victimTimer[client].timer, hIgnoreTimer);
			victimTimer[client].timer = INVALID_HANDLE;
			victimTimer[client].dp    = null;
			return Plugin_Stop;
		}
		else
		{
			secondsLeft -= CHARGE_CHECKING_INTERVAL;

			victimTimer[client].dp.Reset();

			victimTimer[client].dp.WriteFloat(secondsLeft);
		}
	}
	// No height? Maybe we can find some useful trigger_hurt.
	else
	{
		TR_EnumerateEntities(fOrigin, fEndOrigin, PARTITION_SOLID_EDICTS | PARTITION_TRIGGER_EDICTS | PARTITION_STATIC_PROPS, RayType_EndPoint, TraceEnum_TriggerHurt, aEntities);

		int iSize = GetArraySize(aEntities);
		delete aEntities;

		if (iSize > 0)
		{
			if (secondsLeft <= 0.0)
			{
				AnnounceKarma(lastKarma, client, type, false, false, victimTimer[client].timer, hIgnoreTimer);
				victimTimer[client].timer = INVALID_HANDLE;
				victimTimer[client].dp    = null;
				return Plugin_Stop;
			}
			else
			{
				secondsLeft -= CHARGE_CHECKING_INTERVAL;

				victimTimer[client].dp.Reset();

				victimTimer[client].dp.WriteFloat(secondsLeft);
			}
		}
	}

	return Plugin_Continue;
}

public void L4D_TankClaw_OnPlayerHit_Post(int tank, int claw, int victim)
{
	if (victim < 1 || victim > MaxClients || tank < 1 || tank > MaxClients)
		return;

	else if (L4D_GetClientTeam(victim) != L4DTeam_Survivor || L4D_GetClientTeam(tank) != L4DTeam_Infected)
		return;

	else if (L4D_GetAttackerCarry(victim) != 0)
		return;

	AttachKarmaToVictim(victim, tank, KT_Punch);

	if (PunchRegisterTimer[victim] != INVALID_HANDLE)
	{
		CloseHandle(PunchRegisterTimer[victim]);
		PunchRegisterTimer[victim] = INVALID_HANDLE;
	}

	PunchRegisterTimer[victim] = CreateTimer(0.25, RegisterPunchDelay, victim);

	if (victimTimer[victim].timer != INVALID_HANDLE)
	{
		CloseHandle(victimTimer[victim].timer);
		victimTimer[victim].timer = INVALID_HANDLE;
		victimTimer[victim].dp    = null;
	}

	victimTimer[victim].timer = CreateDataTimer(CHARGE_CHECKING_INTERVAL, Timer_CheckVictim, victimTimer[victim].dp, TIMER_REPEAT);

	victimTimer[victim].dp.WriteFloat(PUNCH_SECONDS_NEEDED_AGAINST_LEDGE_HANG);
	victimTimer[victim].dp.WriteCell(victim);
	victimTimer[victim].dp.WriteCell(INVALID_HANDLE);
}

public Action RegisterAllKarmaDelay(Handle timer, any victim)
{
	AllKarmaRegisterTimer[victim] = INVALID_HANDLE;

	return Plugin_Continue;
}

public Action RegisterSlapDelay(Handle timer, any victim)
{
	SlapRegisterTimer[victim] = INVALID_HANDLE;

	return Plugin_Continue;
}

public Action RegisterPunchDelay(Handle timer, any victim)
{
	PunchRegisterTimer[victim] = INVALID_HANDLE;

	return Plugin_Continue;
}

public Action RegisterCaptorDelay(Handle timer, any victim)
{
	BlockRegisterTimer[victim] = INVALID_HANDLE;

	return Plugin_Continue;
}

public Action RegisterJumpDelay(Handle timer, any victim)
{
	JumpRegisterTimer[victim] = INVALID_HANDLE;

	return Plugin_Continue;
}

public void Event_PlayerLedgeGrab(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));

	if (!victim || !IsClientInGame(victim))
		return;

	int type;
	int lastKarma = GetAnyLastKarma(victim, type);

	if (lastKarma == 0)
		return;

	if(!g_bEnabled) return;

	CreateTimer(0.1, Timer_CheckLedgeChange, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
}

public Action Timer_CheckLedgeChange(Handle hTimer, int userId)
{
	int victim = GetClientOfUserId(userId);

	if (victim == 0)
		return Plugin_Stop;

	else if (!IsPlayerAlive(victim))
		return Plugin_Stop;

	else if (L4D_GetClientTeam(victim) != L4DTeam_Survivor)
		return Plugin_Stop;

	if (GetEntProp(victim, Prop_Send, "m_isFallingFromLedge"))
	{
		int type;
		int lastKarma = GetAnyLastKarma(victim, type);

		if (lastKarma == 0 || g_bkarmaOnlyConfirmed || type == KT_Jump)
			return Plugin_Stop;

		AnnounceKarma(lastKarma, victim, type, false, false, INVALID_HANDLE);
		return Plugin_Stop;
	}
	else if (GetEntProp(victim, Prop_Send, "m_isHangingFromLedge"))
		return Plugin_Continue;

	else
		return Plugin_Stop;
}

public void event_playerDeathPre(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));

	if (!g_bEnabled || !victim || !IsClientInGame(victim))
		return;

	if (L4D_GetClientTeam(victim) != L4DTeam_Survivor)    // L4D_GetClientTeam(victim) == 2 -> Victim is a survivor
		return;

	FixChargeTimeleftBug();

	// New by Eyal282 because any fall or drown damage trigger this block.

	if (AllKarmaRegisterTimer[victim] == INVALID_HANDLE)
		return;

	for (int i = 0; i < KarmaType_MAX; i++)
	{
		if (LastKarma[victim][i].artist != 0)
		{
			if (i == KT_Charge && LastKarma[victim][i].artist > 0 && IsPlayerAlive(LastKarma[victim][i].artist))
			{
				SetEntPropEnt(LastKarma[victim][i].artist, Prop_Send, "m_carryVictim", -1);
				SetEntPropEnt(LastKarma[victim][i].artist, Prop_Send, "m_pummelVictim", -1);

				CreateTimer(0.1, Timer_ResetAbility, GetClientUserId(LastKarma[victim][i].artist), TIMER_FLAG_NO_MAPCHANGE);
			}

			int memoryLastKarma = LastKarma[victim][i].artist;

			AnnounceKarma(LastKarma[victim][i].artist, victim, i, false, true);

			if (memoryLastKarma > 0 && GetConVarBool(karmaAwardConfirmed))
			{
				int damageReward = g_ikarmaAwardConfirmed;

				if (damageReward > 0)
				{
					SetEntProp(memoryLastKarma, Prop_Send, "m_missionSurvivorDamage", GetEntProp(memoryLastKarma, Prop_Send, "m_missionSurvivorDamage") + damageReward);
					SetEntProp(memoryLastKarma, Prop_Send, "m_checkpointSurvivorDamage", GetEntProp(memoryLastKarma, Prop_Send, "m_checkpointSurvivorDamage") + damageReward);
					L4D2Direct_SetTankTickets(memoryLastKarma, L4D2Direct_GetTankTickets(memoryLastKarma) + damageReward);
				}

				SetEventInt(event, "attacker", GetClientUserId(memoryLastKarma));
				SetEventInt(event, "attackerentid", memoryLastKarma);
				SetEventInt(event, "headshot", 2);
				return;
			}
		}
	}

	return;
}

public void event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	// SlowTime creates an entity, and round_start can be called before a map starts ( and before entities can be created )

	if (g_bMapStarted)
		SlowTime("0.0", "0.0", "0.0", 0.0, 1.0);
}

public void event_RoundStartPostNav(Event event, const char[] name, bool dontBroadcast)
{
	// SlowTime creates an entity, and round_start can be called before a map starts ( and before entities can be created )

	g_bRoundStarted = true;

	if (g_bMapStarted)
		SlowTime("0.0", "0.0", "0.0", 0.0, 1.0);
}

public void event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_bRoundStarted = false;

	// Because round_start has bugs when calling on first chapters.
	SlowTime("0.0", "0.0", "0.0", 0.0, 1.0);
}

public void FixChargeTimeleftBug()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;

		else if (!IsPlayerAlive(i))
			continue;

		else if (L4D_GetClientTeam(i) != L4DTeam_Infected)
			continue;

		else if (L4D2_GetPlayerZombieClass(i) != L4D2ZombieClass_Charger)
			continue;

		int iCustomAbility = L4D_GetPlayerCustomAbility(i);

		// I have no clue why it's exactly 3600.0 when it bugs, but whatever.
		if (GetEntPropFloat(iCustomAbility, Prop_Send, "m_duration") == 3600.0)
		{
			SetEntPropFloat(iCustomAbility, Prop_Send, "m_timestamp", GetGameTime());
			SetEntPropFloat(iCustomAbility, Prop_Send, "m_duration", 0.0);
		}
	}
}

public Action Timer_ResetAbility(Handle hTimer, int userID)
{
	int client = GetClientOfUserId(userID);

	if (client == 0)
		return Plugin_Continue;

	else if (!IsPlayerAlive(client))
		return Plugin_Continue;

	else if (L4D_GetClientTeam(client) != L4DTeam_Infected)
		return Plugin_Continue;

	int iEntity = GetEntPropEnt(client, Prop_Send, "m_customAbility");

	if (iEntity != -1)
	{
		SetEntPropFloat(iEntity, Prop_Send, "m_timestamp", GetGameTime());
		SetEntPropFloat(iEntity, Prop_Send, "m_duration", 0.0);
	}

	return Plugin_Continue;
}
/*
public Action Command_XYZ(int client, int args)
{
	float Origin[3], Velocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", Origin);
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", Velocity);

	PrintToChat(client, "Origin: %.4f, %.4f, %.4f | Velocity: %.2f, %.2f, %.2f | FV: %.2f", Origin[0], Origin[1], Origin[2], Velocity[0], Velocity[1], Velocity[2], GetEntPropFloat(client, Prop_Send, "m_flFallVelocity"));

	return Plugin_Handled;
}

public Action Command_UltimateKarma(int client, int args)
{
	if (!IsServerDebugMode())
	{
		PrintToChat(client, "This command can only be executed in a server with debug mode enabled");
		return Plugin_Handled;
	}

	char sMapName[64];

	GetCurrentMap(sMapName, sizeof(sMapName));

	if (!StrEqual(sMapName, "c8m5_rooftop"))
	{
		PrintToChat(client, "This command can only be executed in No Mercy Finale.\x04 sm_map c8m5_rooftop");
		return Plugin_Handled;
	}

	else if (L4D_GetClientTeam(client) != L4DTeam_Survivor)
	{
		PrintToChat(client, "This command can only be executed by survivors");
		return Plugin_Handled;
	}

	if (fLogHeight[client] == -1.0)
	{
		fLogHeight[client] = 160.0;

		PrintToChat(client, "Height debug enabled.");

		float fDebugOrigin[3];

		fDebugOrigin = NO_MERCY_DEBUG_ORIGIN;

		fDebugOrigin[2] += fLogHeight[client];

		TeleportEntity(client, fDebugOrigin, NULL_VECTOR, NULL_VECTOR);
	}
	else
	{
		fLogHeight[client] = -1.0;

		PrintToChat(client, "Height debug disabled.");

		ForcePlayerSuicide(client);
	}

	return Plugin_Handled;
}
*/
public void OnGameFrame()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			float fOrigin[3];
			float fVelocity[3];

			GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", fOrigin);
			GetEntPropVector(i, Prop_Data, "m_vecVelocity", fVelocity);

			if (GetEntityFlags(i) & FL_ONGROUND)
			{
				// Being on the ground reduces bird charge for slopes.
				catchHeight[i] = fOrigin[2];

				apexHeight[i]    = -65535.0;
				preJumpHeight[i] = fOrigin[2];

				if (GetCarryVictim(i) == -1)
					catchHeight[i] = -65535.0;

				if (fLogHeight[i] != -1.0)
				{
					if (GetVectorLength(fVelocity) == 0.0)
					{
						float fDebugOrigin[3];

						fDebugOrigin = NO_MERCY_DEBUG_ORIGIN;

						fDebugOrigin[2] += fLogHeight[i];

						TeleportEntity(i, fDebugOrigin, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
			else
			{
				if (fOrigin[2] > apexHeight[i])
				{
					apexHeight[i] = fOrigin[2];
				}
			}

			if (AllKarmaRegisterTimer[i] != INVALID_HANDLE)
				continue;

			else if (!GetAnyLastKarma(i))
				continue;

			else if (!IsClientInGame(i))
				continue;

			else if (!IsPlayerAlive(i))
				continue;

			else if (!(GetEntityFlags(i) & FL_ONGROUND))
				continue;

			if (GetEntProp(i, Prop_Send, "m_isHangingFromLedge") || GetEntProp(i, Prop_Send, "m_isFallingFromLedge"))
				continue;

			apexHeight[i] = -65535.0;

			if (IsClientAffectedByFling(i))
				continue;

			else if (L4D_IsPlayerStaggering(i))
				continue;

			if (LastKarma[i][KT_Charge].artist != 0 && !IsPinnedByCharger(i))
				DettachKarmaFromVictim(i, KT_Charge);

			else if (LastKarma[i][KT_Jockey].artist != 0 && JockRegisterTimer[i] == INVALID_HANDLE)
				DettachKarmaFromVictim(i, KT_Jockey);

			else if (LastKarma[i][KT_Slap].artist != 0 && SlapRegisterTimer[i] == INVALID_HANDLE)
				DettachKarmaFromVictim(i, KT_Slap);

			else if (LastKarma[i][KT_Punch].artist != 0 && PunchRegisterTimer[i] == INVALID_HANDLE)
				DettachKarmaFromVictim(i, KT_Punch);

			else if (LastKarma[i][KT_Impact].artist != 0)
				DettachKarmaFromVictim(i, KT_Impact);

			else if (LastKarma[i][KT_Smoke].artist != 0 && SmokeRegisterTimer[i] == INVALID_HANDLE)
				DettachKarmaFromVictim(i, KT_Smoke);

			// Staggers despite keeping the player on the ground will have L4D_IsPlayerStaggering that appears above.
			else if (LastKarma[i][KT_Stagger].artist != 0)
				DettachKarmaFromVictim(i, KT_Stagger);

			// If you hold jump, you can make yourself fall from ledges, so don't detach if you're holding jump button.
			else if (LastKarma[i][KT_Jump].artist != 0 && JumpRegisterTimer[i] == INVALID_HANDLE && !(GetClientButtons(i) & IN_JUMP))
				DettachKarmaFromVictim(i, KT_Jump);

			// No blocks, remove victim timer.
			if (!FindAnyRegisterBlocks(i))
			{
				if (victimTimer[i].timer != INVALID_HANDLE)
				{
					CloseHandle(victimTimer[i].timer);
					victimTimer[i].timer = INVALID_HANDLE;
					victimTimer[i].dp    = null;
				}

				BlockAnnounce[i] = false;
			}
		}
	}
}

public void event_BotReplacesAPlayer(Event event, const char[] name, bool dontBroadcast)
{
	int oldPlayer = GetClientOfUserId(event.GetInt("player"));
	int newPlayer = GetClientOfUserId(event.GetInt("bot"));

	if(!oldPlayer || !IsClientInGame(oldPlayer)) return;
	if(!newPlayer || !IsClientInGame(newPlayer)) return;

	if(!g_bEnabled) return;

	OnPlayersSwapped(oldPlayer, newPlayer);
}

public void event_PlayerReplacesABot(Event event, const char[] name, bool dontBroadcast)
{
	int oldPlayer = GetClientOfUserId(event.GetInt("bot"));
	int newPlayer = GetClientOfUserId(event.GetInt("player"));

	if(!oldPlayer || !IsClientInGame(oldPlayer)) return;
	if(!newPlayer || !IsClientInGame(newPlayer)) return;

	if(!g_bEnabled) return;

	OnPlayersSwapped(oldPlayer, newPlayer);
}

// Called before the takeover events. This allows you to clear variables.
public void event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!g_bEnabled || !client || !IsClientInGame(client))
		return;

	BlockAnnounce[client] = false;

	DettachKarmaFromVictim(client, KarmaType_MAX);

	preJumpHeight[client] = 0.0;
	apexHeight[client]    = -65535.0;
	catchHeight[client]   = -65535.0;

	if (chargerTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(chargerTimer[client]);
		chargerTimer[client] = INVALID_HANDLE;
	}
	if (victimTimer[client].timer != INVALID_HANDLE)
	{
		CloseHandle(victimTimer[client].timer);
		victimTimer[client].timer = INVALID_HANDLE;
		victimTimer[client].dp    = null;
	}
	if (ledgeTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(ledgeTimer[client]);
		ledgeTimer[client] = INVALID_HANDLE;
	}
	if (AllKarmaRegisterTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(AllKarmaRegisterTimer[client]);
		AllKarmaRegisterTimer[client] = INVALID_HANDLE;
	}

	if (BlockRegisterTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(BlockRegisterTimer[client]);
		BlockRegisterTimer[client] = INVALID_HANDLE;
	}

	if (JockRegisterTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(JockRegisterTimer[client]);
		JockRegisterTimer[client] = INVALID_HANDLE;
	}
	if (SlapRegisterTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(SlapRegisterTimer[client]);
		SlapRegisterTimer[client] = INVALID_HANDLE;
	}
	if (PunchRegisterTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(PunchRegisterTimer[client]);
		PunchRegisterTimer[client] = INVALID_HANDLE;
	}
	if (JumpRegisterTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(JumpRegisterTimer[client]);
		JumpRegisterTimer[client] = INVALID_HANDLE;
	}
	if (SmokeRegisterTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(SmokeRegisterTimer[client]);
		SmokeRegisterTimer[client] = INVALID_HANDLE;
	}
}

// Called after player_spawn, so you're allowed to clear variables in player_spawn
// Note to self consider adding here: CreateTimer(0.1, Timer_CheckLedgeChange, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
public void OnPlayersSwapped(int oldPlayer, int newPlayer)
{
	// FL_ONGROUND is bugged for an instant on takeovers, maybe other flags are too?
	if (!(GetEntityFlags(oldPlayer) & FL_ONGROUND))
		SetEntityFlags(newPlayer, GetEntityFlags(newPlayer) & ~FL_ONGROUND);

	if (GetEntProp(oldPlayer, Prop_Send, "m_isHangingFromLedge"))
	{
		CreateTimer(0.1, Timer_CheckLedgeChange, GetClientUserId(newPlayer), TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	}

	BlockAnnounce[newPlayer] = BlockAnnounce[oldPlayer];

	TransferKarmaToVictim(newPlayer, oldPlayer);

	preJumpHeight[newPlayer] = preJumpHeight[oldPlayer];
	apexHeight[newPlayer]    = apexHeight[oldPlayer];
	catchHeight[newPlayer]   = catchHeight[oldPlayer];

	BlockAnnounce[oldPlayer] = false;

	preJumpHeight[oldPlayer] = 0.0;
	apexHeight[oldPlayer]    = 0.0;
	catchHeight[oldPlayer]   = 0.0;

	if (chargerTimer[oldPlayer] != INVALID_HANDLE)
	{
		CloseHandle(chargerTimer[oldPlayer]);
		chargerTimer[oldPlayer] = INVALID_HANDLE;

		if (chargerTimer[newPlayer] != INVALID_HANDLE)
		{
			CloseHandle(chargerTimer[newPlayer]);
			chargerTimer[newPlayer] = INVALID_HANDLE;
		}

		chargerTimer[newPlayer] = CreateTimer(CHARGE_CHECKING_INTERVAL, Timer_CheckCharge, newPlayer, TIMER_REPEAT);
	}
	if (victimTimer[oldPlayer].timer != INVALID_HANDLE)
	{
		victimTimer[oldPlayer].dp.Reset();

		float secondsLeft = victimTimer[oldPlayer].dp.ReadFloat();

		CloseHandle(victimTimer[oldPlayer].timer);
		victimTimer[oldPlayer].timer = INVALID_HANDLE;
		victimTimer[oldPlayer].dp    = null;

		if (victimTimer[newPlayer].timer != INVALID_HANDLE)
		{
			CloseHandle(victimTimer[newPlayer].timer);
			victimTimer[newPlayer].timer = INVALID_HANDLE;
			victimTimer[newPlayer].dp    = null;
		}

		victimTimer[newPlayer].timer = CreateDataTimer(CHARGE_CHECKING_INTERVAL, Timer_CheckVictim, victimTimer[newPlayer].dp, TIMER_REPEAT);

		victimTimer[newPlayer].dp.WriteFloat(secondsLeft);
		victimTimer[newPlayer].dp.WriteCell(newPlayer);
		victimTimer[newPlayer].dp.WriteCell(INVALID_HANDLE);
	}
	if (ledgeTimer[oldPlayer] != INVALID_HANDLE)
	{
		CloseHandle(ledgeTimer[oldPlayer]);
		ledgeTimer[oldPlayer] = INVALID_HANDLE;

		if (ledgeTimer[newPlayer] != INVALID_HANDLE)
		{
			CloseHandle(ledgeTimer[newPlayer]);
			ledgeTimer[newPlayer] = INVALID_HANDLE;
		}

		ledgeTimer[newPlayer] = CreateTimer(CHARGE_CHECKING_INTERVAL, Timer_CheckJockeyRideLedge, newPlayer, TIMER_REPEAT);
	}
	if (AllKarmaRegisterTimer[oldPlayer] != INVALID_HANDLE)
	{
		CloseHandle(AllKarmaRegisterTimer[oldPlayer]);
		AllKarmaRegisterTimer[oldPlayer] = INVALID_HANDLE;

		if (AllKarmaRegisterTimer[newPlayer] != INVALID_HANDLE)
		{
			CloseHandle(AllKarmaRegisterTimer[newPlayer]);
			AllKarmaRegisterTimer[newPlayer] = INVALID_HANDLE;
		}

		AllKarmaRegisterTimer[newPlayer] = CreateTimer(3.0, RegisterAllKarmaDelay, newPlayer);
	}

	if (BlockRegisterTimer[oldPlayer] != INVALID_HANDLE)
	{
		CloseHandle(BlockRegisterTimer[oldPlayer]);
		BlockRegisterTimer[oldPlayer] = INVALID_HANDLE;

		if (BlockRegisterTimer[newPlayer] != INVALID_HANDLE)
		{
			CloseHandle(BlockRegisterTimer[newPlayer]);
			BlockRegisterTimer[newPlayer] = INVALID_HANDLE;
		}

		BlockRegisterTimer[newPlayer] = CreateTimer(15.0, RegisterCaptorDelay, newPlayer);
	}

	if (JockRegisterTimer[oldPlayer] != INVALID_HANDLE)
	{
		CloseHandle(JockRegisterTimer[oldPlayer]);
		JockRegisterTimer[oldPlayer] = INVALID_HANDLE;

		if (JockRegisterTimer[newPlayer] != INVALID_HANDLE)
		{
			CloseHandle(JockRegisterTimer[newPlayer]);
			JockRegisterTimer[newPlayer] = INVALID_HANDLE;
		}

		JockRegisterTimer[newPlayer] = CreateTimer(0.7, EndLastJockey, newPlayer);
	}

	if (SlapRegisterTimer[oldPlayer] != INVALID_HANDLE)
	{
		CloseHandle(SlapRegisterTimer[oldPlayer]);
		SlapRegisterTimer[oldPlayer] = INVALID_HANDLE;

		if (SlapRegisterTimer[newPlayer] != INVALID_HANDLE)
		{
			CloseHandle(SlapRegisterTimer[newPlayer]);
			SlapRegisterTimer[newPlayer] = INVALID_HANDLE;
		}

		SlapRegisterTimer[newPlayer] = CreateTimer(0.25, RegisterSlapDelay, newPlayer);
	}

	if (PunchRegisterTimer[oldPlayer] != INVALID_HANDLE)
	{
		CloseHandle(PunchRegisterTimer[oldPlayer]);
		PunchRegisterTimer[oldPlayer] = INVALID_HANDLE;

		if (PunchRegisterTimer[newPlayer] != INVALID_HANDLE)
		{
			CloseHandle(PunchRegisterTimer[newPlayer]);
			PunchRegisterTimer[newPlayer] = INVALID_HANDLE;
		}

		PunchRegisterTimer[newPlayer] = CreateTimer(0.25, RegisterPunchDelay, newPlayer);
	}

	if (JumpRegisterTimer[oldPlayer] != INVALID_HANDLE)
	{
		CloseHandle(JumpRegisterTimer[oldPlayer]);
		JumpRegisterTimer[oldPlayer] = INVALID_HANDLE;

		if (JumpRegisterTimer[newPlayer] != INVALID_HANDLE)
		{
			CloseHandle(JumpRegisterTimer[newPlayer]);
			JumpRegisterTimer[newPlayer] = INVALID_HANDLE;
		}

		JumpRegisterTimer[newPlayer] = CreateTimer(0.25, RegisterJumpDelay, newPlayer);
	}

	if (SmokeRegisterTimer[oldPlayer] != INVALID_HANDLE)
	{
		CloseHandle(SmokeRegisterTimer[oldPlayer]);
		SmokeRegisterTimer[oldPlayer] = INVALID_HANDLE;

		if (SmokeRegisterTimer[newPlayer] != INVALID_HANDLE)
		{
			CloseHandle(SmokeRegisterTimer[newPlayer]);
			SmokeRegisterTimer[newPlayer] = INVALID_HANDLE;
		}

		SmokeRegisterTimer[newPlayer] = CreateTimer(0.7, EndLastSmoker, newPlayer);
	}
}

public void event_PlayerJump(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bkarmaJump)
		return;

	int victim = GetClientOfUserId(event.GetInt("userid"));

	if (!g_bEnabled || !victim || !IsClientInGame(victim) || L4D_GetClientTeam(victim) != L4DTeam_Survivor)
		return;

	AttachKarmaToVictim(victim, victim, KT_Jump, true);

	if (JumpRegisterTimer[victim] != INVALID_HANDLE)
	{
		CloseHandle(JumpRegisterTimer[victim]);
		JumpRegisterTimer[victim] = INVALID_HANDLE;
	}

	JumpRegisterTimer[victim] = CreateTimer(0.25, RegisterJumpDelay, victim);
}

public void event_ChargerKill(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!g_bEnabled || client == 0 || !IsClientInGame(client))
	{
		return;
	}

	if (g_ikarmaAwardConfirmed < 0)
		return;

	int maxDamage = GetConVarInt(FindConVar("z_max_survivor_damage"));

	// Valve limits.
	if (maxDamage > 300)
		maxDamage = 300;

	SetEntProp(client, Prop_Send, "m_missionSurvivorDamage", GetEntProp(client, Prop_Send, "m_missionSurvivorDamage") - maxDamage);
	SetEntProp(client, Prop_Send, "m_checkpointSurvivorDamage", GetEntProp(client, Prop_Send, "m_checkpointSurvivorDamage") - maxDamage);
	L4D2Direct_SetTankTickets(client, L4D2Direct_GetTankTickets(client) - maxDamage);
}

public void event_ChargerGrab(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!g_bEnabled || client == 0 || !IsClientInGame(client))
	{
		return;
	}

	int victim = GetClientOfUserId(event.GetInt("victim"));

	AttachKarmaToVictim(victim, client, KT_Charge);

	DebugPrintToAll("Charger Carry event caught, initializing timer");

	if (chargerTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(chargerTimer[client]);
		chargerTimer[client] = INVALID_HANDLE;
	}

	float fOrigin[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", fOrigin);
	catchHeight[client] = fOrigin[2];

	chargerTimer[client] = CreateTimer(CHARGE_CHECKING_INTERVAL, Timer_CheckCharge, client, TIMER_REPEAT);
	TriggerTimer(chargerTimer[client], true);
}

public void event_GrabEnded(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client == 0 || !IsClientInGame(client))
	{
		return;
	}

	if (chargerTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(chargerTimer[client]);
		chargerTimer[client] = INVALID_HANDLE;
	}

	return;
}

public void event_ChargerImpact(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int victim = GetClientOfUserId(event.GetInt("victim"));

	if (!g_bEnabled || !client || !IsClientInGame(client)
		|| !victim || !IsClientInGame(victim))
	{
		return;
	}

	if (GetEntPropEnt(victim, Prop_Send, "m_carryAttacker") == -1)
	{
		AttachKarmaToVictim(victim, client, KT_Impact);

		if (victimTimer[victim].timer != INVALID_HANDLE)
		{
			CloseHandle(victimTimer[victim].timer);
			victimTimer[victim].timer = INVALID_HANDLE;
			victimTimer[victim].dp    = null;
		}

		victimTimer[victim].timer = CreateDataTimer(CHARGE_CHECKING_INTERVAL, Timer_CheckVictim, victimTimer[victim].dp, TIMER_REPEAT);

		victimTimer[victim].dp.WriteFloat(IMPACT_SECONDS_NEEDED_AGAINST_LEDGE_HANG);
		victimTimer[victim].dp.WriteCell(victim);
		victimTimer[victim].dp.WriteCell(INVALID_HANDLE);
	}
}

public void event_jockeyRideStart(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("victim"));

	if (!victim || !IsClientInGame(victim))
		return;

	if (ledgeTimer[victim] != INVALID_HANDLE)
	{
		CloseHandle(ledgeTimer[victim]);
		ledgeTimer[victim] = INVALID_HANDLE;
	}

	if(!g_bEnabled) return;

	ledgeTimer[victim] = CreateTimer(0.1, Timer_CheckJockeyRideLedge, victim, TIMER_REPEAT);
}

public void event_jockeyRideEndPre(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int victim = GetClientOfUserId(event.GetInt("victim"));

	if (!g_bEnabled || !client || !IsClientInGame(client)
					|| !victim || !IsClientInGame(victim)) return;

	// This is disabled by the new jockey mechanism except for ledges
	if (L4D_IsPlayerHangingFromLedge(victim))
	{
		AttachKarmaToVictim(victim, client, KT_Jockey);

		CreateTimer(0.7, EndLastJockey, victim, TIMER_FLAG_NO_MAPCHANGE);
	}

	else if (!IsPlayerAlive(client) && ledgeTimer[victim] == INVALID_HANDLE)
	{
		TriggerTimer(CreateTimer(0.1, Timer_CheckJockeyRideLedge, victim, TIMER_FLAG_NO_MAPCHANGE));
	}
}

// For when a survivor cannot hang. Either shallow water like the passing and memorial bridge, or last survivor.
public Action Timer_CheckJockeyRideLedge(Handle timer, any client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client) || L4D_GetClientTeam(client) != L4DTeam_Survivor)
	{
		ledgeTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	else if (L4D_GetAttackerJockey(client) == 0)
	{
		ledgeTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}

	else if (GetEntProp(client, Prop_Send, "m_isHangingFromLedge"))
	{
		ledgeTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}

	else if (GetEntityFlags(client) & FL_ONGROUND)
		return Plugin_Continue;

	// Something else is calculating karma so who cares?
	else if (GetAnyLastKarma(client) != 0)
		return Plugin_Continue;

	float fOrigin[3], fEndOrigin[3], fMins[3], fMaxs[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", fOrigin);

	GetClientMins(client, fMins);
	GetClientMaxs(client, fMaxs);

	TR_TraceRayFilter(fOrigin, ANGLE_STRAIGHT_DOWN, MASK_PLAYERSOLID, RayType_Infinite, TraceFilter_DontHitPlayersAndClips);

	TR_GetEndPosition(fEndOrigin);

	// Now try again with hull to avoid funny stuff.

	TR_TraceHullFilter(fOrigin, fEndOrigin, fMins, fMaxs, MASK_PLAYERSOLID, TraceFilter_DontHitPlayersAndClips);

	TR_GetEndPosition(fEndOrigin);

	// 285 is 265.0 but accounting for delay in getting there by 0.1 seconds.
	if (L4D_CanPlayerLedgeHang(client) && GetVectorDistance(fOrigin, fEndOrigin) > 285.0 && !IsLastStandingSurvivor(client))
		return Plugin_Continue;

	AttachKarmaToVictim(client, L4D_GetAttackerJockey(client), KT_Jockey);

	if (victimTimer[client].timer != INVALID_HANDLE)
	{
		CloseHandle(victimTimer[client].timer);
		victimTimer[client].timer = INVALID_HANDLE;
		victimTimer[client].dp    = null;
	}

	victimTimer[client].timer = CreateDataTimer(1.0, Timer_CheckVictim, victimTimer[client].dp, TIMER_REPEAT);

	victimTimer[client].dp.WriteFloat(0.0);
	victimTimer[client].dp.WriteCell(client);
	victimTimer[client].dp.WriteCell(ledgeTimer[client]);

	// AnnounceKarma deletes this timer to avoid infinite karma spam.
	TriggerTimer(victimTimer[client].timer);

	return Plugin_Continue;
}

public Action EndLastJockey(Handle timer, any victim)
{
	JockRegisterTimer[victim] = INVALID_HANDLE;

	return Plugin_Continue;
}

public void event_tongueGrabOrRelease(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int victim = GetClientOfUserId(event.GetInt("victim"));

	if (!g_bEnabled || !client || !IsClientInGame(client)
		|| !victim || !IsClientInGame(victim)) return;

	AttachKarmaToVictim(victim, client, KT_Smoke);

	float fOrigin[3];
	GetEntPropVector(victim, Prop_Data, "m_vecAbsOrigin", fOrigin);

	apexHeight[victim]         = -65535.0;
	preJumpHeight[victim]      = fOrigin[2];
	SmokeRegisterTimer[victim] = CreateTimer(0.7, EndLastSmoker, victim);

	if (victimTimer[victim].timer != INVALID_HANDLE)
	{
		CloseHandle(victimTimer[victim].timer);
		victimTimer[victim].timer = INVALID_HANDLE;
		victimTimer[victim].dp    = null;
	}

	if(!g_bEnabled) return;

	victimTimer[victim].timer = CreateDataTimer(CHARGE_CHECKING_INTERVAL, Timer_CheckVictim, victimTimer[victim].dp, TIMER_REPEAT);

	victimTimer[victim].dp.WriteFloat(SMOKE_SECONDS_NEEDED_AGAINST_LEDGE_HANG);
	victimTimer[victim].dp.WriteCell(victim);
	victimTimer[victim].dp.WriteCell(INVALID_HANDLE);
}

public Action EndLastSmoker(Handle timer, any victim)
{
	SmokeRegisterTimer[victim] = INVALID_HANDLE;

	return Plugin_Continue;
}

public Action Timer_CheckCharge(Handle timer, any client)
{
	if (!client || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		chargerTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}

	int victim = GetCarryVictim(client);

	if (victim == -1)
		return Plugin_Continue;

	else if (IsDoubleCharged(victim))
		return Plugin_Continue;

	else if (GetEntityFlags(client) & FL_ONGROUND) return Plugin_Continue;

	float fOrigin[3], fEndOrigin[3], fEndPredictedOrigin[3], fMins[3], fMaxs[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", fOrigin);

	ArrayList aEntities = new ArrayList(1);

	GetClientMins(client, fMins);
	GetClientMaxs(client, fMaxs);

	TR_TraceRayFilter(fOrigin, ANGLE_STRAIGHT_DOWN, MASK_PLAYERSOLID, RayType_Infinite, TraceFilter_DontHitPlayersAndClips);

	TR_GetEndPosition(fEndOrigin);

	// Now try again with hull to avoid funny stuff.

	TR_TraceHullFilter(fOrigin, fEndOrigin, fMins, fMaxs, MASK_PLAYERSOLID, TraceFilter_DontHitPlayersAndClips);

	TR_GetEndPosition(fEndOrigin);

	float fPlaneNormal[3];
	// For bird charges to find if it's a slope.
	TR_GetPlaneNormal(INVALID_HANDLE, fPlaneNormal);

	// 0.0 is also flat apparently.
	if (fPlaneNormal[2] < 0.7 && fPlaneNormal[2] != 0.0)
	{
		float fVelocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);

		float fVector[3];

		fVector[0] = fOrigin[0] + fVelocity[0];
		fVector[1] = fOrigin[1] + fVelocity[1];
		fVector[2] = fOrigin[2];

		TR_TraceRayFilter(fVector, ANGLE_STRAIGHT_DOWN, MASK_PLAYERSOLID, RayType_Infinite, TraceFilter_DontHitPlayersAndClips);

		TR_GetEndPosition(fEndPredictedOrigin);

		TR_TraceHullFilter(fVector, fEndPredictedOrigin, fMins, fMaxs, MASK_PLAYERSOLID, TraceFilter_DontHitPlayersAndClips);

		TR_GetEndPosition(fEndPredictedOrigin);

		int ent = TR_GetEntityIndex();

		if (ent != -1)
		{
			char sClassname[64];
			GetEdictClassname(ent, sClassname, sizeof(sClassname));
		}

		// Now make a trace between fOrigin and fEndPredictedOrigin.
		TR_TraceHullFilter(fOrigin, fEndPredictedOrigin, fMins, fMaxs, MASK_PLAYERSOLID, TraceFilter_DontHitPlayersAndClips);

		TR_GetEndPosition(fEndPredictedOrigin);

		TR_EnumerateEntities(fOrigin, fEndPredictedOrigin, PARTITION_SOLID_EDICTS | PARTITION_TRIGGER_EDICTS | PARTITION_STATIC_PROPS, RayType_EndPoint, TraceEnum_TriggerHurt, aEntities);

		if (IsServerDebugMode())
		{
			TE_SetupBeamPoints(fOrigin, fEndPredictedOrigin, PrecacheModel("materials/vgui/white_additive.vmt"), 0, 0, 0, 10.0, 10.0, 10.0, 0, 10.0, { 255, 0, 0, 255 }, 50);
			TE_SendToAllInRange(fOrigin, RangeType_Audibility);
		}
	}

	TR_EnumerateEntities(fOrigin, fEndOrigin, PARTITION_SOLID_EDICTS | PARTITION_TRIGGER_EDICTS | PARTITION_STATIC_PROPS, RayType_EndPoint, TraceEnum_TriggerHurt, aEntities);

	int iSize = GetArraySize(aEntities);
	delete aEntities;

	if (iSize > 0)
	{
		AnnounceKarma(client, victim, KT_Charge, false, false, chargerTimer[client]);
		chargerTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}

	else if (g_bkarmaBirdCharge)
	{
		// 0.0 is also flat apparently.
		if ((fPlaneNormal[2] >= 0.7 || fPlaneNormal[2] == 0.0) && !CanClientSurviveFall(victim, catchHeight[client] - fEndOrigin[2]))
		{
			AnnounceKarma(client, victim, KT_Charge, true, false, chargerTimer[client]);
			chargerTimer[client] = INVALID_HANDLE;
			return Plugin_Stop;
		}
	}

	return Plugin_Continue;
}

public bool TraceFilter_DontHitPlayersAndClips(int entity, int contentsMask)
{
	if (IsEntityPlayer(entity))
		return false;

	char sClassname[64];
	GetEdictClassname(entity, sClassname, sizeof(sClassname));

	if (StrContains(sClassname, "_clip", false) != -1)
		return false;

	else if (strncmp(sClassname, "weapon_", 7) == 0)
		return false;

	return true;
}

public bool TraceEnum_TriggerHurt(int entity, ArrayList aEntities)
{
	// If we hit the world, stop enumerating.
	if (!entity)
		return false;

	else if (!IsValidEdict(entity))
		return false;

	char sClassname[24];
	GetEdictClassname(entity, sClassname, sizeof(sClassname));

	// Also works for trigger_hurt_ghost because some maps wager on the fact trigger_hurt_ghost kills the charger and the survivors dies from the fall itself.

	if (strncmp(sClassname, "trigger_hurt", 12) == 0)
	{
		TR_ClipCurrentRayToEntity(MASK_ALL, entity);

		if (TR_GetEntityIndex() != entity)
			return true;

		float fDamage = GetEntPropFloat(entity, Prop_Data, "m_flDamage");

		// Does it do incap damage?
		if (fDamage < 100)
			return true;

		int iDamagetype = GetEntProp(entity, Prop_Data, "m_bitsDamageInflict");

		// Does it simulate a fall or water?
		if (iDamagetype != DMG_FALL && iDamagetype != DMG_DROWN)
			return true;

		aEntities.Push(entity);

		return true;
	}
	else if (StrEqual(sClassname, "trigger_multiple"))
	{
		TR_ClipCurrentRayToEntity(MASK_ALL, entity);

		if (TR_GetEntityIndex() != entity)
			return true;

		char sTargetname[64];
		GetEntPropString(entity, Prop_Data, "m_iName", sTargetname, sizeof(sTargetname));

		if (StrContains(sTargetname, "KarmaKill", false) != -1)
		{
			aEntities.Push(entity);

			return true;
		}
		return true;
	}

	return true;
}

// Client will be negative if the karma is done by a bot and the bot left the server.
// In that case, client = -1 * zombieclass
void AnnounceKarma(int client, int victim, int type, bool bBird, bool bKillConfirmed, Handle hDontKillHandle = INVALID_HANDLE, Handle hDontKillHandle2 = INVALID_HANDLE)
{
	char KarmaName[64];
	FormatEx(KarmaName, sizeof(KarmaName), karmaNames[type]);

	if (victimTimer[victim].timer != INVALID_HANDLE && hDontKillHandle != victimTimer[victim].timer && hDontKillHandle2 != victimTimer[victim].timer)
	{
		CloseHandle(victimTimer[victim].timer);
		victimTimer[victim].timer = INVALID_HANDLE;
		victimTimer[victim].dp    = null;
	}

	if (ledgeTimer[victim] != INVALID_HANDLE && hDontKillHandle != ledgeTimer[victim] && hDontKillHandle2 != ledgeTimer[victim])
	{
		CloseHandle(ledgeTimer[victim]);
		ledgeTimer[victim] = INVALID_HANDLE;
	}

	if (client > 0 && chargerTimer[client] != INVALID_HANDLE && hDontKillHandle != chargerTimer[client] && hDontKillHandle2 != chargerTimer[client])
	{
		CloseHandle(chargerTimer[client]);
		chargerTimer[client] = INVALID_HANDLE;
	}

	if (BlockRegisterTimer[victim] != INVALID_HANDLE)
	{
		CloseHandle(BlockRegisterTimer[victim]);
		BlockRegisterTimer[victim] = INVALID_HANDLE;
	}

	// Enforces a one karma per 15 seconds per victim, exlcuding height checkers.
	BlockRegisterTimer[victim] = CreateTimer(15.0, RegisterCaptorDelay, victim);

	bool bWasBlocked = BlockAnnounce[victim] && (!g_bkarmaOnlyConfirmed || bKillConfirmed);

	if (!BlockAnnounce[victim] && (!g_bkarmaOnlyConfirmed || bKillConfirmed))
	{
		BlockAnnounce[victim] = true;

		EmitSoundToAll(SOUND_EFFECT);

		if (g_bModeSwitch || cooldownTimer != INVALID_HANDLE)
			SlowKarmaCouple(victim, client, KarmaName);

		else
		{
			SlowTime();
		}
/*
		if (type == KT_Jump)
		{
			CPrintToChatAll("[{olive}%s{default}] {green}%s{olive} [%s] {default} %s %s {olive}%N{default}, for great justice!!", g_sPrefix, LastKarma[victim][type].artistName, LastKarma[victim][type].artistSteamId, bBird ? "Bird" : "Karma", KarmaName, victim);
		}
		else
		{
			CPrintToChatAll("[{olive}%s{default}] {green}%s{default} %s %s {olive}%N{default}, for great justice!!", g_sPrefix, LastKarma[victim][type].artistName, bBird ? "Bird" : "Karma", KarmaName, victim);
		}
*/
	}

	if (type != KT_Jump)
	{
		// Kill confirmed without an announce block? Means we failed to register it. Send the kill unconfirmed again
		if (!bWasBlocked && bKillConfirmed)
		{
			Call_StartForward(fw_OnKarmaEventPost);

			Call_PushCell(victim);
			Call_PushCell(client);
			Call_PushString(KarmaName);
			Call_PushCell(bBird);
			Call_PushCell(false);
			Call_PushCell(g_bkarmaOnlyConfirmed);

			Call_Finish();
		}

		DebugPrintToAll("Karma event by %s %i", LastKarma[victim][type].artistName, bKillConfirmed);

		Call_StartForward(fw_OnKarmaEventPost);

		Call_PushCell(victim);
		Call_PushCell(client);
		Call_PushString(KarmaName);
		Call_PushCell(bBird);
		Call_PushCell(bKillConfirmed);
		Call_PushCell(g_bkarmaOnlyConfirmed);

		Call_Finish();
	}
	else
	{
		if (!StrEqual(LastKarma[victim][type].artistSteamId, "BOT"))
		{
			Call_StartForward(fw_OnKarmaJumpPost);

			Call_PushCell(victim);

			Call_PushArray(LastKarma[victim][type].lastPos, 3);
			Call_PushArray(LastKarma[victim][type].artistWeapons, 64);
			Call_PushArray(LastKarma[victim][type].artistHealth, 2);
			Call_PushCell(LastKarma[victim][type].artistTimestamp);
			Call_PushString(LastKarma[victim][type].artistSteamId);
			Call_PushString(LastKarma[victim][type].artistName);

			Call_Finish();
		}
	}

	// Major changes might make this unnecessary anymore.

	if (!bKillConfirmed)
	{
		// Ensuring the bKillConfirmed karma event will fire by removing unrelated karma artists.
		for (int i = 0; i < KarmaType_MAX; i++)
		{
			if (type != i && LastKarma[victim][i].artist != client)
				DettachKarmaFromVictim(victim, i);
		}
	}
	else
	{
		// Kill confirmed, remove every single karma artist.
		DettachKarmaFromVictim(victim, KarmaType_MAX);
	}
}

// This does nothing except avoid double freezing of time.
public Action RestoreSlowmo(Handle Timer)
{
	cooldownTimer = INVALID_HANDLE;

	return Plugin_Continue;
}

void SlowKarmaCouple(int victim, int attacker, char[] sKarmaName)
{
	// Karma can register a lot of time after the register because of ledge hang, so no random slowdowns...
	if (StrEqual(sKarmaName, "Charge") && attacker > 0 && IsPlayerAlive(attacker))
		SetEntPropFloat(attacker, Prop_Send, "m_flLaggedMovementValue", g_fkarmaSlow);

	SetEntPropFloat(victim, Prop_Send, "m_flLaggedMovementValue", g_fkarmaSlow);

	Handle data = CreateDataPack();
	WritePackCell(data, GetClientUserId(victim));

	if (StrEqual(sKarmaName, "Charge") && attacker > 0 && IsPlayerAlive(attacker))
		WritePackCell(data, GetClientUserId(attacker));

	else
		WritePackCell(data, 0);

	CreateTimer(g_fkarmaSlowTimeOnCouple, _revertCoupleTimeSlow, data, TIMER_FLAG_NO_MAPCHANGE);
}

public Action _revertCoupleTimeSlow(Handle timer, Handle data)
{
	ResetPack(data);
	int victim   = GetClientOfUserId(ReadPackCell(data));
	int attacker = GetClientOfUserId(ReadPackCell(data));
	CloseHandle(data);

	if (victim != 0)
	{
		SetEntPropFloat(victim, Prop_Send, "m_flLaggedMovementValue", 1.0);
	}

	if (attacker != 0)
	{
		SetEntPropFloat(attacker, Prop_Send, "m_flLaggedMovementValue", 1.0);
	}

	return Plugin_Continue;
}

bool IsPinnedByCharger(int client)
{
	return GetEntPropEnt(client, Prop_Send, "m_carryAttacker") != -1 || GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") != -1;
}

int GetCarryVictim(int client)
{
	int victim = GetEntPropEnt(client, Prop_Send, "m_carryVictim");
	if (victim < 1
	    || victim > MaxClients
	    || !IsClientInGame(victim))
	{
		return -1;
	}

	return victim;
}

void SlowTime(const char[] re_Acceleration = "2.0", const char[] minBlendRate = "1.0", const char[] blendDeltaMultiplier = "2.0", float fTime = -1.0, float fSlowPower = -65535.0)
{
	char desiredTimeScale[16];
	char sAddOutput[64];

	if (fSlowPower == -65535.0)
	{
		fSlowPower = g_fkarmaSlow;

		if (fSlowPower < 0.03)
			fSlowPower = 0.03;
	}

	FloatToString(fSlowPower, desiredTimeScale, sizeof(desiredTimeScale));

	int ent = CreateEntityByName("func_timescale");

	DispatchKeyValue(ent, "desiredTimescale", desiredTimeScale);
	DispatchKeyValue(ent, "acceleration", re_Acceleration);
	DispatchKeyValue(ent, "minBlendRate", minBlendRate);
	DispatchKeyValue(ent, "blendDeltaMultiplier", blendDeltaMultiplier);
	DispatchKeyValue(ent, "targetname", "THE WORLD");

	DispatchSpawn(ent);

	if (fSlowPower == 1.0 || !g_bRoundStarted)
	{
		int theWorldEnt = -1;

		while ((theWorldEnt = FindEntityByTargetname(theWorldEnt, "THE WORLD", true, false)) != -1)
		{
			AcceptEntityInput(theWorldEnt, "Stop");
			AcceptEntityInput(theWorldEnt, "Reset");

			// Must compensate for the timescale making every single timer slower, both CreateTimer type timers and OnUser1 type timers
			FormatEx(sAddOutput, sizeof(sAddOutput), "OnUser2 !self:Kill::3.0:1");
			SetVariantString(sAddOutput);
			AcceptEntityInput(theWorldEnt, "AddOutput");
			AcceptEntityInput(theWorldEnt, "FireUser2");
		}
	}
	else
	{
		AcceptEntityInput(ent, "Start");

		if (fTime == -1.0)
			fTime = g_fkarmaSlowTimeOnServer;

		// Must compensate for the timescale making every single timer slower, both CreateTimer type timers and OnUser1 type timers
		FormatEx(sAddOutput, sizeof(sAddOutput), "OnUser1 !self:Stop::%.2f:1", fTime * fSlowPower);
		SetVariantString(sAddOutput);
		AcceptEntityInput(ent, "AddOutput");
		AcceptEntityInput(ent, "FireUser1");

		FormatEx(sAddOutput, sizeof(sAddOutput), "OnUser2 !self:Kill::%.2f:1", (fTime * fSlowPower) + 5.0);
		SetVariantString(sAddOutput);
		AcceptEntityInput(ent, "AddOutput");
		AcceptEntityInput(ent, "FireUser2");

		// Start counting the cvarCooldown from after the freeze ends, also this timer needs to account for the timescale.
		cooldownTimer = CreateTimer((fTime * fSlowPower) + g_fCooldown, RestoreSlowmo);
	}
}

void DebugPrintToAll(const char[] format, any...)
{
	if (IsServerDebugMode())
	{
		char buffer[256];

		VFormat(buffer, sizeof(buffer), format, 2);

		LogMessage("%s", buffer);
		PrintToChatAll("[KARMA] %s", buffer);
		PrintToConsole(0, "[KARMA] %s", buffer);
	}
}

void DebugLogToFile(const char[] fileName, const char[] format, any...)
{
	if (IsServerDebugMode())
	{
		char buffer[512];

		VFormat(buffer, sizeof(buffer), format, 3);

		char sPath[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, sPath, sizeof(sPath), "logs/%s", fileName);

		LogToFile(sPath, buffer);
	}
}

bool IsClientAffectedByFling(int client)
{
	char model[PLATFORM_MAX_PATH];
	GetEntPropString(client, Prop_Data, "m_ModelName", model, PLATFORM_MAX_PATH);
	switch (model[29])
	{
		case 'b':    // nick
		{
			switch (GetEntProp(client, Prop_Send, "m_nSequence"))
			{
				case 661, 667, 669, 671, 672, 627, 628, 629, 630, 620:
					return true;
			}
		}
		case 'd':    // rochelle
		{
			switch (GetEntProp(client, Prop_Send, "m_nSequence"))
			{
				case 668, 674, 676, 678, 679, 635, 636, 637, 638, 629:
					return true;
			}
		}
		case 'c':    // coach
		{
			switch (GetEntProp(client, Prop_Send, "m_nSequence"))
			{
				case 650, 656, 658, 660, 661, 627, 628, 629, 630, 621:
					return true;
			}
		}
		case 'h':    // ellis
		{
			switch (GetEntProp(client, Prop_Send, "m_nSequence"))
			{
				case 665, 671, 673, 675, 676, 632, 633, 634, 635, 625:
					return true;
			}
		}
		case 'v':    // bill
		{
			switch (GetEntProp(client, Prop_Send, "m_nSequence"))
			{
				case 753, 759, 761, 763, 764, 535, 536, 537, 538, 528:
					return true;
			}
		}
		case 'n':    // zoey
		{
			switch (GetEntProp(client, Prop_Send, "m_nSequence"))
			{
				case 813, 819, 821, 823, 824, 544, 545, 546, 547, 537:
					return true;
			}
		}
		case 'e':    // francis
		{
			switch (GetEntProp(client, Prop_Send, "m_nSequence"))
			{
				case 756, 762, 764, 766, 767, 538, 539, 540, 541, 531:
					return true;
			}
		}
		case 'a':    // louis
		{
			switch (GetEntProp(client, Prop_Send, "m_nSequence"))
			{
				case 753, 759, 761, 763, 764, 535, 536, 537, 538, 528:
					return true;
			}
		}
	}
	return false;
}

void RegisterCaptor(int victim)
{
	if (BlockRegisterTimer[victim] != INVALID_HANDLE)
		return;

	int charger = L4D_GetAttackerCharger(victim);

	if (charger == 0)
		charger = L4D_GetAttackerCarry(victim);

	int jockey = L4D_GetAttackerJockey(victim);
	int smoker = L4D_GetAttackerSmoker(victim);

	if (charger != 0)
		AttachKarmaToVictim(victim, charger, KT_Charge);

	if (jockey != 0)
		AttachKarmaToVictim(victim, jockey, KT_Jockey);

	if (smoker != 0)
		AttachKarmaToVictim(victim, smoker, KT_Smoke);
}

bool IsEntityPlayer(int entity)
{
	if (entity <= 0)
		return false;

	else if (entity > MaxClients)
		return false;

	return true;
}

int GetAnyLastKarma(int victim, int& type = 0)
{
	for (int i = 0; i < KarmaType_MAX; i++)
	{
		if (LastKarma[victim][i].artist != 0)
		{
			type = i;

			return LastKarma[victim][i].artist;
		}
	}

	return 0;
}

bool FindAnyRegisterBlocks(int victim)
{
	return BlockRegisterTimer[victim] != INVALID_HANDLE || AllKarmaRegisterTimer[victim] != INVALID_HANDLE || SlapRegisterTimer[victim] != INVALID_HANDLE || JockRegisterTimer[victim] != INVALID_HANDLE || PunchRegisterTimer[victim] != INVALID_HANDLE || SmokeRegisterTimer[victim] != INVALID_HANDLE || JumpRegisterTimer[victim] != INVALID_HANDLE;
}

bool CanClientSurviveFall(int client, float fTotalDistance)
{
	float fFatalFallDaamage = g_fFatalFallDamage;

	// 137.5 is the lowest height of fall damage, making you take 0.000000 damage.
	float fDistancesVsDamages[][] = {

		{157.5,   2.777781    },
		{ 177.5,  11.111101   },
		{ 197.5,  24.999961   },
		{ 220.0,  44.444358   },
		{ 242.5,  69.44429    },
		{ 265.0,  99.999771   },
		{ 290.0,  136.110794  },
		{ 315.0,  177.777343  },
		{ 340.0,  224.99942   },
		{ 367.5,  277.777038  },
		{ 397.5,  336.110198  },
		{ 425.0,  399.998962  },
		{ 455.0,  469.443115  },
		{ 485.0,  544.442932  },
		{ 517.5,  624.998352  },
		{ 550.0,  711.10913   },
		{ 582.5,  802.775573  },
		{ 617.5,  899.99768   },
		{ 652.5,  1002.775695 },
		{ 687.5,  1111.109375 },
		{ 725.0,  1224.998413 },
		{ 762.5,  1344.443115 },
		{ 802.5,  1469.443481 },
		{ 840.0,  1599.999389 },
		{ 882.5,  1736.111083 },
		{ 922.5,  1877.777832 },
		{ 965.0,  2025.000976 },
		{ 1007.5, 2177.779052 },
		{ 1052.5, 2336.112548 },
		{ 1097.5, 2500.002441 },
		{ 1142.5, 2669.447265 },
		{ 1190.0, 2844.447998 },
		{ 1237.5, 3025.00415  },
		{ 1285.0, 3211.115722 },
		{ 1335.0, 3402.783691 },
		{ 1385.0, 3600.006591 },
		{ 1437.5, 3802.785156 },
		{ 1487.5, 4011.11914  },
		{ 1540.0, 4225.008789 },
		{ 1595.0, 4444.454589 },
		{ 1650.0, 4669.455078 },
		{ 1705.0, 4900.012207 },
		{ 1762.5, 5136.124023 },
		{ 1820.0, 5377.791015 },
		{ 1877.5, 5625.014648 },
		{ 1937.5, 5877.793457 },
		{ 1997.5, 6136.128417 },
		{ 2057.5, 6400.018554 },
		{ 2120.0, 6669.463378 },
		{ 2182.5, 6944.464843 },
		{ 2245.0, 7225.022949 },
		{ 2310.0, 7511.135253 },
		{ 2375.0, 7802.802246 },
		{ 2440.0, 8100.025878 },
		{ 2507.5, 8402.804687 },
		{ 2577.5, 8711.138671 },
		{ 2645.0, 9025.02539  },
		{ 2715.0, 9344.46875  },
		{ 2785.0, 9669.467773 },
		{ 2857.5, 10000.021484},
		{ 2930.0, 10336.130859},
		{ 3002.5, 10677.794921},
		{ 3077.5, 11025.015625},
		{ 3152.5, 11377.791992},
		{ 3227.5, 11736.123046},
		{ 3305.0, 12100.010742},
		{ 3382.5, 12469.452148},
		{ 3462.5, 12844.450195},
		{ 3540.0, 13225.004882},
		{ 3622.5, 13611.111328},
		{ 3702.5, 14002.777343},
		{ 3785.0, 14399.995117},
		{ 3867.5, 14802.771484},
		{ 3952.5, 15211.103515},
		{ 4037.5, 15624.988281},
		{ 4122.5, 16044.430664},
		{ 4210.0, 16469.425781},
		{ 4297.5, 16899.980468},
		{ 4385.0, 17336.089843},
		{ 4475.0, 17777.751953},
		{ 4565.0, 18224.970703},
		{ 4657.5, 18677.74414 },
		{ 4747.5, 19136.076171},
		{ 4840.0, 19599.96289 },
		{ 4935.0, 20069.402343},
		{ 5030.0, 20544.40039 },
		{ 5125.0, 21024.949218},
		{ 5222.5, 21511.058593},
		{ 5320.0, 22002.724609},
		{ 5417.5, 22499.941406},
		{ 5517.5, 23002.714843},
		{ 5617.5, 23511.042968},
		{ 5717.5, 24024.929687},
		{ 5820.0, 24544.371093},
		{ 5922.5, 25069.365234},
		{ 6025.0, 25599.917968},
		{ 6130.0, 26136.023437},
		{ 6235.0, 26677.685546},
		{ 6340.0, 27224.90625 },
		{ 6447.5, 27777.679687},
		{ 6557.5, 28336.003906},
		{ 6665.0, 28899.890625},
		{ 6775.0, 29469.330078},
		{ 6885.0, 30044.326171},
		{ 6997.5, 30624.880859},
		{ 7110.0, 31210.980468},
		{ 7222.5, 31802.642578},
		{ 7337.5, 32399.863281},
		{ 7452.5, 33002.636718},
		{ 7567.5, 33610.96875 },
		{ 7685.0, 33764.0625  }
	};

	for (int i = sizeof(fDistancesVsDamages) - 1; i >= 0; i--)
	{
		if (fTotalDistance >= fDistancesVsDamages[i][0])
		{
			// Can survive the fall if either:
			// 1. Player has more total health to survive the damage it deals.
			// 2. The damage dealt is lower than the fatal fall damage.
			return GetEntProp(client, Prop_Send, "m_iHealth") + L4D_GetPlayerTempHealth(client) > RoundToFloor(fDistancesVsDamages[i][1]) || fDistancesVsDamages[i][1] < fFatalFallDaamage;
		}
	}

	return true;
}

bool IsDoubleCharged(int victim)
{
	int count;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;

		else if (GetClientTeam(i) != view_as<int>(L4DTeam_Infected))
			continue;

		else if (L4D2_GetPlayerZombieClass(i) != L4D2ZombieClass_Charger)
			continue;

		if (L4D_GetVictimCarry(i) == victim || L4D_GetVictimCharger(i) == victim)
			count++;
	}

	return count >= 2;
}

// Todo: check if clearing with netprops causes the jockey teleport to shadow realm bug.
// WARNING!!! This will permanently freeze the victim, but I'm killing him so IDGAF.
void ClearAllPinners(int victim)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;

		else if (GetClientTeam(i) != view_as<int>(L4DTeam_Infected))
			continue;

		if (GetEntPropEnt(i, Prop_Send, "m_pounceVictim") == victim)
			SetEntPropEnt(i, Prop_Send, "m_pounceVictim", -1);

		if (GetEntPropEnt(i, Prop_Send, "m_tongueVictim") == victim)
			SetEntPropEnt(i, Prop_Send, "m_tongueVictim", -1);

		if (GetEntPropEnt(i, Prop_Send, "m_pummelVictim") == victim)
			SetEntPropEnt(i, Prop_Send, "m_pummelVictim", -1);

		if (GetEntPropEnt(i, Prop_Send, "m_carryVictim") == victim)
			SetEntPropEnt(i, Prop_Send, "m_carryVictim", -1);
	}

	SetEntPropEnt(victim, Prop_Send, "m_pounceAttacker", -1);
	SetEntPropEnt(victim, Prop_Send, "m_tongueOwner", -1);
	SetEntPropEnt(victim, Prop_Send, "m_pummelAttacker", -1);
	SetEntPropEnt(victim, Prop_Send, "m_carryAttacker", -1);

	if (GetEntPropEnt(victim, Prop_Send, "m_jockeyAttacker") != -1)
	{
		L4D2_Jockey_EndRide(victim, GetEntPropEnt(victim, Prop_Send, "m_jockeyAttacker"));
	}

	// Detach from chargers.
	AcceptEntityInput(victim, "ClearParent");
}

bool IsServerDebugMode()
{
	return TEST_DEBUG;
}

bool IsLastStandingSurvivor(int client)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (client == i)
			continue;

		else if (!IsClientInGame(i))
			continue;

		else if (!IsPlayerAlive(i))
			continue;

		else if (GetClientTeam(i) != view_as<int>(L4DTeam_Survivor))
			continue;

		else if (L4D_IsPlayerIncapacitated(i))
			continue;

		return false;
	}

	return true;
}

int FindEntityByTargetname(int startEnt, const char[] TargetName, bool caseSensitive, bool bContains)    // Same as FindEntityByClassname with sensitivity and contain features
{
	int entCount = GetEntityCount();

	char EntTargetName[300];

	for (int i = startEnt + 1; i < entCount; i++)
	{
		if (!IsValidEntity(i))
			continue;

		else if (!IsValidEdict(i))
			continue;

		GetEntPropString(i, Prop_Data, "m_iName", EntTargetName, sizeof(EntTargetName));

		if ((StrEqual(EntTargetName, TargetName, caseSensitive) && !bContains) || (StrContains(EntTargetName, TargetName, caseSensitive) != -1 && bContains))
			return i;
	}

	return -1;
}

void AttachKarmaToVictim(int victim, int attacker, int type, bool bLastPos = false)
{
	LastKarma[victim][type].artist = attacker;
	GetClientName(attacker, LastKarma[victim][type].artistName, sizeof(enLastKarma::artistName));
	GetClientAuthId(attacker, AuthId_Steam2, LastKarma[victim][type].artistSteamId, sizeof(enLastKarma::artistSteamId));

	if (bLastPos)
	{
		GetClientAbsOrigin(victim, LastKarma[victim][type].lastPos);
		LastKarma[victim][type].artistTimestamp = GetGameTime();
		LastKarma[victim][type].artistHealth[0] = GetEntityHealth(victim);
		LastKarma[victim][type].artistHealth[1] = L4D_GetPlayerTempHealth(victim);

		int num = 0;

		for (int i = 0; i < sizeof(enLastKarma::artistWeapons); i++)
		{
			LastKarma[victim][type].artistWeapons[i] = -1;
		}

		for (int i = 0; i < GetEntPropArraySize(victim, Prop_Send, "m_hMyWeapons"); i++)
		{
			int weapon = GetEntPropEnt(victim, Prop_Send, "m_hMyWeapons", i);

			if (weapon != -1)
			{
				LastKarma[victim][type].artistWeapons[num++] = EntIndexToEntRef(weapon);
			}
		}
	}
}

int GetEntityHealth(int client)
{
	return GetEntProp(client, Prop_Send, "m_iHealth");
}
void StripKarmaArtistFromVictim(int victim, int type)
{
	if (type == KarmaType_MAX)
	{
		for (int i = 0; i < KarmaType_MAX; i++)
		{
			LastKarma[victim][i].artist = -1;
		}
	}
	else
	{
		LastKarma[victim][type].artist = -1;
	}
}

void StripKarmaVictimsFromArtist(int artist, int type)
{
	if (type == KarmaType_MAX)
	{
		for (int i = 0; i < KarmaType_MAX; i++)
		{
			for (int client = 1; client <= MaxClients; client++)
			{
				if (!IsClientInGame(client))
					continue;

				else if (LastKarma[client][i].artist == artist)
				{
					StripKarmaArtistFromVictim(client, i);
				}
			}
		}
	}
	else
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (!IsClientInGame(client))
				continue;

			else if (LastKarma[client][type].artist == artist)
			{
				StripKarmaArtistFromVictim(client, type);
			}
		}
	}
}

void DettachKarmaFromVictim(int victim, int type)
{
	if (type == KarmaType_MAX)
	{
		for (int i = 0; i < KarmaType_MAX; i++)
		{
			LastKarma[victim][i].artist           = 0;
			LastKarma[victim][i].artistName[0]    = EOS;
			LastKarma[victim][i].artistSteamId[0] = EOS;
		}
	}
	else
	{
		LastKarma[victim][type].artist           = 0;
		LastKarma[victim][type].artistName[0]    = EOS;
		LastKarma[victim][type].artistSteamId[0] = EOS;
	}
}

void TransferKarmaToVictim(int toVictim, int fromVictim)
{
	for (int i = 0; i < KarmaType_MAX; i++)
	{
		if (LastKarma[fromVictim][i].artist != 0)
		{
			// .artist is swapped because someone needs to be credited in rewards..
			LastKarma[toVictim][i].artist          = toVictim;
			LastKarma[toVictim][i].artistName      = LastKarma[fromVictim][i].artistName;
			LastKarma[toVictim][i].artistSteamId   = LastKarma[fromVictim][i].artistSteamId;
			LastKarma[toVictim][i].lastPos         = LastKarma[fromVictim][i].lastPos;
			LastKarma[toVictim][i].artistTimestamp = LastKarma[fromVictim][i].artistTimestamp;
			LastKarma[toVictim][i].artistHealth[0] = LastKarma[fromVictim][i].artistHealth[0];
			LastKarma[toVictim][i].artistHealth[1] = LastKarma[fromVictim][i].artistHealth[1];

			for (int a = 0; a < 64; a++)
			{
				LastKarma[toVictim][i].artistWeapons[a] = LastKarma[fromVictim][i].artistWeapons[a];
			}
		}
	}

	DettachKarmaFromVictim(fromVictim, KarmaType_MAX);
}