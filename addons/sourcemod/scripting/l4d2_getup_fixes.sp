/**
 * Documentation
 *
 * =========================================================================================================
 * 
 * Methods of `CTerrorPlayerAnimState` (peeks into `CTerrorPlayer`):
 *    [1]. `ResetMainActivity()`: Invoke recalculation of animation to be played.
 *
 * Flags of `CTerrorPlayerAnimState`:
 *    See `AnimStateFlag` for an incomplete list.
 * 
 * =========================================================================================================
 * 
 * Fixes for cappers respectively:
 *
 *    Smoker:
 *      1) [DISABLED] Charged get-ups keep playing during pull.			(Event_TongueGrab)
 *      2) [DISABLED] Punch/Rock get-up keeps playing during pull.		(Event_TongueGrab)
 *      3) Hunter get-up replayed when pull released.					(Event_TongueGrab)
 *
 *    Jockey:
 *      1) No get-up if forced off by any other capper.					(Event_JockeyRideEnd)
 *      2) Bowling/Wallslam get-up keeps playing during ride.			(Event_JockeyRide)
 *    
 *    Hunter:
 *      1) Double get-up when pounce on charger victims.				(Event_ChargerPummelStart Event_ChargerKilled)
 *      2) Bowling/Pummel/Slammed get-up keeps playing when pounced.	(Event_LungePounce)
 *      3) Punch/Rock get-up keeps playing when pounced.				(Event_LungePounce)
 *    
 *    Charger:
 *      1) Prevent get-up for self-clears.								(Event_ChargerKilled)
 *      2) Fix no godframe for long get-up.								(Event_ChargerKilled)
 *      3) Punch/Charger get-up keeps playing during carry.				(Event_ChargerCarryStart)
 *      4) Fix possible slammed get-up not playing on instant slam.		(SDK_OnTakeDamage)
 *    
 *    Tank:
 *      1) Double get-up if punch/rock on chargers with victims to die.	(OnPlayerHit_Post OnKnockedDown_Post)
 *         Do not play punch/rock get-up to keep consistency.
 *      2) No get-up if do rock-punch combo.							(OnPlayerHit_Post OnKnockedDown_Post)
 *      3) Double get-up if punch/rock on survivors in bowling.			(OnPlayerHit_Post OnKnockedDown_Post)
 */


#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>
#include <l4d2util_constants>
#undef REQUIRE_PLUGIN
#include <godframecontrol>

#define PLUGIN_VERSION "4.12.1"

public Plugin myinfo = 
{
	name = "[L4D2] Merged Get-Up Fixes",
	author = "Forgetest",
	description = "Fixes all double/missing get-up cases.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
};

#define GAMEDATA_FILE "l4d2_getup_fixes"
#define KEY_ANIMSTATE "CTerrorPlayer::m_PlayerAnimState"
#define KEY_FLAG_CHARGED "CTerrorPlayerAnimState::m_bCharged"
#define KEY_RESETMAINACTIVITY "CTerrorPlayerAnimState::ResetMainActivity"

Handle
	g_hSDKCall_ResetMainActivity;

int
	m_PlayerAnimState,
	m_bCharged;

enum AnimStateFlag // mid-way start from m_bCharged
{
	AnimState_Charged			= 0, // aka multi-charged
	AnimState_WallSlammed		= 2,
	AnimState_GroundSlammed		= 3,
	AnimState_Pounded			= 5, // Pummel get-up
	AnimState_TankPunched		= 7, // Rock get-up shares this
	AnimState_Pounced			= 9,
	AnimState_RiddenByJockey	= 14
}

methodmap AnimState
{
	public AnimState(int client) {
		int ptr = GetEntData(client, m_PlayerAnimState, 4);
		if (ptr == 0)
			ThrowError("Invalid pointer to \"CTerrorPlayer::CTerrorPlayerAnimState\" (client %d).", client);
		return view_as<AnimState>(ptr);
	}
	public void ResetMainActivity() { SDKCall(g_hSDKCall_ResetMainActivity, this); }
	public bool GetFlag(AnimStateFlag flag) {
		return view_as<bool>(LoadFromAddress(view_as<Address>(this) + view_as<Address>(m_bCharged) + view_as<Address>(flag), NumberType_Int8));
	}
	public void SetFlag(AnimStateFlag flag, bool val) {
		StoreToAddress(view_as<Address>(this) + view_as<Address>(m_bCharged) + view_as<Address>(flag), view_as<int>(val), NumberType_Int8);
	}
}

bool
	g_bLateLoad,
	g_bGodframeControl;

int
	g_iChargeVictim[MAXPLAYERS+1] = {-1, ...},
	g_iChargeAttacker[MAXPLAYERS+1] = {-1, ...};

float 
	g_fLastChargedEndTime[MAXPLAYERS+1];

ConVar 
	g_hChargeDuration,
	g_hLongChargeDuration,
	cvar_keepWallSlamLongGetUp,
	cvar_keepLongChargeLongGetUp;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

void LoadSDK()
{
	Handle conf = LoadGameConfigFile(GAMEDATA_FILE);
	if (!conf)
		SetFailState("Missing gamedata \""...GAMEDATA_FILE..."\"");
	
	m_PlayerAnimState = GameConfGetOffset(conf, KEY_ANIMSTATE);
	if (m_PlayerAnimState == -1)
		SetFailState("Missing offset \""...KEY_ANIMSTATE..."\"");
	
	m_bCharged = GameConfGetOffset(conf, KEY_FLAG_CHARGED);
	if (m_bCharged == -1)
		SetFailState("Missing offset \""...KEY_FLAG_CHARGED..."\"");
	
	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(conf, SDKConf_Virtual, KEY_RESETMAINACTIVITY))
		SetFailState("Missing offset \""...KEY_RESETMAINACTIVITY..."\"");
	g_hSDKCall_ResetMainActivity = EndPrepSDKCall();
	if (!g_hSDKCall_ResetMainActivity)
		SetFailState("Failed to prepare SDKCall \""...KEY_RESETMAINACTIVITY..."\"");
	
	delete conf;
}

public void OnPluginStart()
{
	LoadSDK();
	
	g_hLongChargeDuration = CreateConVar("gfc_long_charger_duration", "2.2", "God frame duration for long charger getup animations");
	
	cvar_keepWallSlamLongGetUp = CreateConVar("charger_keep_wall_charge_animation", "1", "Enable the long wall slam animation (with god frames)");
	cvar_keepLongChargeLongGetUp = CreateConVar("charger_keep_far_charge_animation", "0", "Enable the long 'far' slam animation (with god frames)");
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_bot_replace", Event_PlayerBotReplace);
	HookEvent("bot_player_replace", Event_BotPlayerReplace);
	HookEvent("revive_success", Event_ReviveSuccess);
	HookEvent("tongue_grab", Event_TongueGrab);
	HookEvent("lunge_pounce", Event_LungePounce);
	HookEvent("jockey_ride", Event_JockeyRide);
	HookEvent("jockey_ride_end", Event_JockeyRideEnd);
	HookEvent("charger_carry_start", Event_ChargerCarryStart);
	HookEvent("charger_pummel_start", Event_ChargerPummelStart);
	HookEvent("charger_pummel_end", Event_ChargerPummelEnd);
	HookEvent("charger_killed", Event_ChargerKilled);
	
	if (g_bLateLoad)
	{
		for (int i = 1; i <= MaxClients; ++i)
		{
			if (IsClientInGame(i)) OnClientPutInServer(i);
		}
	}
}

public void OnAllPluginsLoaded()
{
	g_bGodframeControl = LibraryExists("l4d2_godframes_control_merge");
}

public void OnLibraryAdded(const char[] name)
{
	if (strcmp(name, "l4d2_godframes_control_merge") == 0)
		g_bGodframeControl = true;
}

public void OnLibraryRemoved(const char[] name)
{
	if (strcmp(name, "l4d2_godframes_control_merge") == 0)
		g_bGodframeControl = false;
}

public void OnConfigsExecuted()
{
	if (g_bGodframeControl)
	{
		g_hChargeDuration = FindConVar("gfc_charger_duration");
	}
}

public void OnClientPutInServer(int client)
{
	g_iChargeVictim[client] = -1;
	g_iChargeAttacker[client] = -1;
	g_fLastChargedEndTime[client] = 0.0;
		
	SDKHook(client, SDKHook_OnTakeDamage, SDK_OnTakeDamage);
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; ++i)
	{
		g_iChargeVictim[i] = -1;
		g_iChargeAttacker[i] = -1;
		g_fLastChargedEndTime[i] = 0.0;
	}
}

void Event_PlayerBotReplace(Event event, const char[] name, bool dontBroadcast)
{
	int replacer = GetClientOfUserId(event.GetInt("bot"));
	int replacee = GetClientOfUserId(event.GetInt("player"));
	if (replacer && replacee)
		HandlePlayerReplace(replacer, replacee);
}

void Event_BotPlayerReplace(Event event, const char[] name, bool dontBroadcast)
{
	int replacer = GetClientOfUserId(event.GetInt("player"));
	int replacee = GetClientOfUserId(event.GetInt("bot"));
	if (replacer && replacee)
		HandlePlayerReplace(replacer, replacee);
}

void HandlePlayerReplace(int replacer, int replacee)
{
	if (GetClientTeam(replacer) == 3)
	{
		if (g_iChargeVictim[replacee] != -1)
		{
			g_iChargeVictim[replacer] = g_iChargeVictim[replacee];
			g_iChargeAttacker[g_iChargeVictim[replacee]] = replacer;
			g_iChargeVictim[replacee] = -1;
		}
	}
	else
	{
		if (g_iChargeAttacker[replacee] != -1)
		{
			g_iChargeAttacker[replacer] = g_iChargeAttacker[replacee];
			g_iChargeVictim[g_iChargeAttacker[replacee]] = replacer;
			g_iChargeAttacker[replacee] = -1;
		}
	}
}


/**
 * Survivor Incap
 */
void Event_ReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	if (client)
	{
		// Clear all get-up flags
		AnimState pAnim = AnimState(client);
		pAnim.SetFlag(AnimState_GroundSlammed, false);
		pAnim.SetFlag(AnimState_WallSlammed, false);
		pAnim.SetFlag(AnimState_Pounded, false); // probably no need
		pAnim.SetFlag(AnimState_Pounced, false); // probably no need
	}
}


/**
 * Smoker
 */
void Event_TongueGrab(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if (client)
	{
		AnimState pAnim = AnimState(client);
		
		// Fix double get-up
		pAnim.SetFlag(AnimState_Pounced, false);
		
		// Commented to prevent unexpected buff
		
		// Fix get-up keeps playing
		//pAnim.SetFlag(AnimState_GroundSlammed, false);
		//pAnim.SetFlag(AnimState_WallSlammed, false);
		//pAnim.SetFlag(AnimState_TankPunched, false);
		//pAnim.SetFlag(AnimState_Pounded, false);
		//pAnim.SetFlag(AnimState_Charged, false);
	}
}


/**
 * Hunter
 */
void Event_LungePounce(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if (client)
	{
		AnimState pAnim = AnimState(client);
		
		// Fix get-up keeps playing
		pAnim.SetFlag(AnimState_TankPunched, false);
		pAnim.SetFlag(AnimState_Charged, false);
		pAnim.SetFlag(AnimState_Pounded, false);
		pAnim.SetFlag(AnimState_WallSlammed, false);
	}
}


/**
 * Jockey
 */
void Event_JockeyRide(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if (client)
	{
		// Fix get-up keeps playing
		AnimState pAnim = AnimState(client);
		pAnim.SetFlag(AnimState_Charged, false);
		pAnim.SetFlag(AnimState_WallSlammed, false);
	}
}

void Event_JockeyRideEnd(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if (client)
	{
		// Fix no get-up
		AnimState(client).SetFlag(AnimState_RiddenByJockey, false);
	}
}


/**
 * Charger
 */
void Event_ChargerCarryStart(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("victim"));
	if (victim)
	{
		AnimState pAnim = AnimState(victim);
		
		// Fix get-up keeps playing
		pAnim.SetFlag(AnimState_TankPunched, false);
		
		/**
		 * FIXME:
		 * Tiny workaround for multiple chargers, but still glitchy.
		 * I would think charging victims away from other chargers
		 * is really an undefined behavior, better block it.
		 */
		pAnim.SetFlag(AnimState_Charged, false);
		pAnim.SetFlag(AnimState_Pounded, false);
		pAnim.SetFlag(AnimState_GroundSlammed, false);
		pAnim.SetFlag(AnimState_WallSlammed, false);
	}
}

// Take care of pummel transition and self-clears
void Event_ChargerKilled(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client))
		return;
	
	int victim = g_iChargeVictim[client];
	if (victim == -1 || !IsClientInGame(victim))
		return;
	
	AnimState pAnim = AnimState(victim);
	
	// Chances that hunter pounces right on survivor queued for pummel
	if (GetEntPropEnt(victim, Prop_Send, "m_pounceAttacker") != -1)
	{
		// Fix double get-up
		pAnim.SetFlag(AnimState_GroundSlammed, false);
		pAnim.SetFlag(AnimState_WallSlammed, false);
	}
	else
	{
		int attacker = GetClientOfUserId(event.GetInt("attacker"));
		if (attacker && victim == attacker)
		{
			if (!L4D_IsPlayerIncapacitated(victim))
			{
				// No self-clear get-up
				pAnim.SetFlag(AnimState_GroundSlammed, false);
				pAnim.SetFlag(AnimState_WallSlammed, false);
			}
		}
		else
		{
			// long charged get-up
			if ((pAnim.GetFlag(AnimState_GroundSlammed) && cvar_keepLongChargeLongGetUp.BoolValue)
				|| (pAnim.GetFlag(AnimState_WallSlammed) && cvar_keepWallSlamLongGetUp.BoolValue))
			{
				SetInvulnerableForSlammed(victim, g_hLongChargeDuration.FloatValue);
			}
			else
			{
				if (pAnim.GetFlag(AnimState_GroundSlammed) || pAnim.GetFlag(AnimState_WallSlammed))
				{
					float duration = 2.0;
					if (g_hChargeDuration != null)
					{
						duration = g_hChargeDuration.FloatValue;
					}
					SetInvulnerableForSlammed(victim, duration);
				}
				L4D2Direct_DoAnimationEvent(victim, ANIM_CHARGER_GETUP);
			}
		}
	}
	
	g_iChargeVictim[client] = -1;
	g_iChargeAttacker[victim] = -1;
	g_fLastChargedEndTime[victim] = GetGameTime();
}

// Pounces on survivors being carried will invoke this instantly.
void Event_ChargerPummelStart(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int victim = GetClientOfUserId(event.GetInt("victim"));
	if (client && victim)
	{
		g_iChargeVictim[client] = victim;
		g_iChargeAttacker[victim] = client;
	}
}

void Event_ChargerPummelEnd(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int victim = GetClientOfUserId(event.GetInt("victim"));
	if (client && victim)
	{
		AnimState pAnim = AnimState(victim);
		
		// Fix double get-up
		pAnim.SetFlag(AnimState_TankPunched, false);
		pAnim.SetFlag(AnimState_Pounced, false);
		
		// Normal processes don't need special care
		g_iChargeVictim[client] = -1;
		g_iChargeAttacker[victim] = -1;
		g_fLastChargedEndTime[victim] = GetGameTime();
	}
}

Action SDK_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if (!attacker || attacker > MaxClients)
		return Plugin_Continue;
	
	if (GetClientTeam(victim) != 2 || GetClientTeam(attacker) != 3)
		return Plugin_Continue;
	
	switch (GetEntProp(attacker, Prop_Send, "m_zombieClass"))
	{
		case 6:
		{
			if (RoundToFloor(damage) == 10 && GetVectorLength(damageForce) == 0.0)
			{
				g_iChargeVictim[attacker] = victim;
				g_iChargeAttacker[victim] = attacker;
				
				AnimState pAnim = AnimState(victim);
				pAnim.SetFlag(AnimState_Pounded, false);
				pAnim.SetFlag(AnimState_Charged, false);
				pAnim.SetFlag(AnimState_TankPunched, false);
				pAnim.SetFlag(AnimState_Pounced, false);
				pAnim.ResetMainActivity();
			}
		}
	}
	
	return Plugin_Continue;
}

void SetInvulnerableForSlammed(int client, float duration)
{
	if (g_bGodframeControl)
	{
		GiveClientGodFrames(client, duration, 6);
	}
	else
	{
		CountdownTimer timer = L4D2Direct_GetInvulnerabilityTimer(client);
		if (timer != CTimer_Null)
		{
			CTimer_Start(timer, duration);
		}
	}
}

/**
 * Tank
 */
void ProcessAttackedByTank(int victim)
{
	if (GetEntPropEnt(victim, Prop_Send, "m_pummelAttacker") != -1)
	{
		return;
	}
	
	AnimState pAnim = AnimState(victim);
	
	// Fix double get-up
	pAnim.SetFlag(AnimState_Charged, false);
	
	// Fix double get-up when punching charger with victim to die
	// Keep in mind that do not mess up with later attacks to the survivor
	if (GetGameTime() - g_fLastChargedEndTime[victim] <= 0.1)
	{
		pAnim.SetFlag(AnimState_TankPunched, false);
	}
	else
	{
		// Remove charger get-up that doesn't pass the check above
		pAnim.SetFlag(AnimState_GroundSlammed, false);
		pAnim.SetFlag(AnimState_WallSlammed, false);
		pAnim.SetFlag(AnimState_Pounded, false);
		
		// Restart the get-up sequence if already playing
		pAnim.ResetMainActivity();
	}
}

public void L4D_TankClaw_OnPlayerHit_Post(int tank, int claw, int player)
{
	if (GetClientTeam(player) == 2 && !L4D_IsPlayerIncapacitated(player))
	{
		ProcessAttackedByTank(player);
	}
}

public void L4D_OnKnockedDown_Post(int client, int reason)
{
	if (reason == KNOCKDOWN_TANK && GetClientTeam(client) == 2)
	{
		ProcessAttackedByTank(client);
	}
}
