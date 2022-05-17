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
 *      2) Bowling get-up keeps playing during ride.					(Event_JockeyRide)
 *    
 *    Hunter:
 *      1) Double get-up when pounce on charger victims.				(Event_ChargerKilled)
 *    
 *    Charger:
 *      1) Prevent get-up for self-clears.								(Event_ChargerKilled)
 *      2) Fix no godframe for long get-up.								(Event_ChargerKilled)
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
#include <godframecontrol>

#define PLUGIN_VERSION "4.4"

public Plugin myinfo = 
{
	name = "[L4D2] Merged Get-Up Fixes",
	author = "Forgetest",
	description = "Fixes all double/missing get-up cases.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
};

#define GAMEDATA_FILE "l4d2_getup_fixes"
#define KEY_ANIMSTATE "CTerrorPlayer::m_hAnimState"
#define KEY_FLAG_CHARGED "CTerrorPlayerAnimState::m_bCharged"
#define KEY_RESETMAINACTIVITY "CTerrorPlayerAnimState::ResetMainActivity"

Handle
	g_hSDKCall_ResetMainActivity;

int
	m_hAnimState,
	m_bCharged;

methodmap AnimState
{
	public AnimState(int player) {
		int ptr = GetEntData(player, m_hAnimState, 4);
		if (ptr == 0)
			ThrowError("Invalid pointer to \"CTerrorPlayer::CTerrorPlayerAnimState\".");
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

enum AnimStateFlag // start from m_bCharged
{
	ASF_Charged			= 0,
	ASF_Pummeled		= 1,
	ASF_WallSlammed		= 2,
	ASF_GroundSlammed	= 3,
	ASF_Pounded			= 5,
	ASF_TankPunched		= 7,
	ASF_Pounced			= 9,
	ASF_RiddenByJockey	= 14
}

bool
	g_bLateLoad;

int
	g_iChargeVictim[MAXPLAYERS+1] = {-1, ...},
	g_iChargeAttacker[MAXPLAYERS+1] = {-1, ...};

ConVar 
	g_hChargeDuration,
	g_hLongChargeDuration,
	longerTankPunchGetup,
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
	
	m_hAnimState = GameConfGetOffset(conf, KEY_ANIMSTATE);
	if (m_hAnimState == -1)
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
	
	g_hChargeDuration = FindConVar("gfc_charger_duration");
	g_hLongChargeDuration = CreateConVar("gfc_long_charger_duration", "2.2", "God frame duration for long charger getup animations");
	
	longerTankPunchGetup = CreateConVar("longer_tank_punch_getup", "0", "When a tank punches someone give them a slightly longer getup.", _, true, 0.0, true, 1.0);
	
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
	HookEvent("charger_pummel_start", Event_ChargerPummelStart);
	HookEvent("charger_killed", Event_ChargerKilled);
	
	if (g_bLateLoad)
	{
		for (int i = 1; i <= MaxClients; ++i)
		{
			if (IsClientInGame(i)) OnClientPutInServer(i);
		}
	}
}

public void OnClientPutInServer(int client)
{
	g_iChargeVictim[client] = -1;
	g_iChargeAttacker[client] = -1;
		
	SDKHook(client, SDKHook_OnTakeDamage, SDK_OnTakeDamage);
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; ++i)
	{
		g_iChargeVictim[i] = -1;
		g_iChargeAttacker[i] = -1;
	}
}

void Event_PlayerBotReplace(Event event, const char[] name, bool dontBroadcast)
{
	int replacer = GetClientOfUserId(event.GetInt("bot"));
	int replacee = GetClientOfUserId(event.GetInt("userid"));
	if (replacer && replacee)
		HandlePlayerReplace(replacer, replacee);
}

void Event_BotPlayerReplace(Event event, const char[] name, bool dontBroadcast)
{
	int replacer = GetClientOfUserId(event.GetInt("userid"));
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
		AnimState hAnim = AnimState(client);
		hAnim.SetFlag(ASF_GroundSlammed, false);
		hAnim.SetFlag(ASF_WallSlammed, false);
		hAnim.SetFlag(ASF_Pounded, false);
		hAnim.SetFlag(ASF_Pounced, false);
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
		AnimState hAnim = AnimState(client);
		
		// Fix double get-up
		hAnim.SetFlag(ASF_Pounced, false);
		
		// Commented to keep consistency with game
		//hAnim.SetFlag(ASF_GroundSlammed, false);
		//hAnim.SetFlag(ASF_WallSlammed, false);
		//hAnim.SetFlag(ASF_TankPunched, false);
		//hAnim.SetFlag(ASF_Pounded, false);
		//hAnim.SetFlag(ASF_Charged, false);
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
		AnimState hAnim = AnimState(client);
		
		// Fix get-up keeps playing
		hAnim.SetFlag(ASF_TankPunched, false);
		hAnim.SetFlag(ASF_Pounded, false);
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
		AnimState(client).SetFlag(ASF_Charged, false);
	}
}

void Event_JockeyRideEnd(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if (client)
	{
		// Fix no get-up
		AnimState(client).SetFlag(ASF_RiddenByJockey, false);
	}
}


/**
 * Charger
 */
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

void Event_ChargerKilled(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	if (client)
	{
		int victim = g_iChargeVictim[client];
		if (victim != -1)
		{
			AnimState hAnim = AnimState(victim);
			
			// Chances that hunter pounces right on survivor queued for pummel
			if (GetEntPropEnt(victim, Prop_Send, "m_pounceAttacker") == -1)
			{
				int attacker = GetClientOfUserId(event.GetInt("attacker"));
				if (attacker && victim == attacker)
				{
					if (!L4D_IsPlayerIncapacitated(victim))
					{
						// No self-clear get-up
						hAnim.SetFlag(ASF_GroundSlammed, false);
						hAnim.SetFlag(ASF_WallSlammed, false);
					}
				}
				else
				{
					// Fix double get-up
					hAnim.SetFlag(ASF_TankPunched, false);
					hAnim.SetFlag(ASF_Pounced, false);
					
					// long charged get-up
					if ((hAnim.GetFlag(ASF_GroundSlammed) && cvar_keepLongChargeLongGetUp.BoolValue)
						|| (hAnim.GetFlag(ASF_WallSlammed) && cvar_keepWallSlamLongGetUp.BoolValue))
					{
						GiveClientGodFrames(victim, g_hLongChargeDuration.FloatValue, 6);
					}
					else
					{
						if (hAnim.GetFlag(ASF_GroundSlammed) || hAnim.GetFlag(ASF_WallSlammed))
						{
							GiveClientGodFrames(victim, g_hChargeDuration.FloatValue, 6);
						}
						L4D2Direct_DoAnimationEvent(victim, 78);
					}
				}
			}
			else
			{
				// Fix double get-up
				hAnim.SetFlag(ASF_GroundSlammed, false);
				hAnim.SetFlag(ASF_WallSlammed, false);
			}
			
			// We're creating timers only for later punch/rock hits
			// because somehow "m_flCycle" doesn't serve reliably.
			CreateTimer(0.1, Timer_ClearChargeInfo, userid, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

Action Timer_ClearChargeInfo(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (client 
		&& g_iChargeVictim[client] != -1) // In case team swaps
	{
		g_iChargeAttacker[g_iChargeVictim[client]] = -1;
		g_iChargeVictim[client] = -1;
	}
	
	return Plugin_Stop;
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
			}
		}
	}
	
	return Plugin_Continue;
}

/**
 * Tank
 */
public void L4D_TankClaw_OnPlayerHit_Post(int tank, int claw, int player)
{
	if (GetClientTeam(player) == 2)
	{
		if (GetEntPropEnt(player, Prop_Send, "m_pummelAttacker") != -1)
		{
			return;
		}
		
		AnimState hAnim = AnimState(player);
		
		// Fix double get-up
		hAnim.SetFlag(ASF_Charged, false);
		
		// Fix double get-up when punching charger with victim to die
		// Keep in mind that do not mess up with later attacks to the survivor
		if (g_iChargeAttacker[player] != -1)
		{
			hAnim.SetFlag(ASF_TankPunched, false);
		}
		else
		{
			// Remove charger get-up that doesn't pass the check above
			hAnim.SetFlag(ASF_GroundSlammed, false);
			hAnim.SetFlag(ASF_WallSlammed, false);
			hAnim.SetFlag(ASF_Pounded, false);
			
			if (longerTankPunchGetup.BoolValue)
			{
				// TODO: Does not extend the get-up.
				// Fixable, though I'd wonder if it's actually needed.
				//L4D2Direct_DoAnimationEvent(player, 57); // ANIM_SHOVED_BY_TEAMMATE
			}
			hAnim.ResetMainActivity();
		}
	}
}

public void L4D_OnKnockedDown_Post(int client, int reason)
{
	if (reason == KNOCKDOWN_TANK && GetClientTeam(client) == 2)
	{
		if (GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") != -1)
		{
			return;
		}
		
		AnimState hAnim = AnimState(client);
		
		// Fix double get-up
		hAnim.SetFlag(ASF_Charged, false);
		
		// Fix double get-up when punching charger with victim to die
		// Keep in mind that do not mess up with later attacks to the survivor
		if (g_iChargeAttacker[client] != -1)
		{
			hAnim.SetFlag(ASF_TankPunched, false);
		}
		else
		{
			// Remove charger get-up that doesn't pass the check above
			hAnim.SetFlag(ASF_GroundSlammed, false);
			hAnim.SetFlag(ASF_WallSlammed, false);
			hAnim.SetFlag(ASF_Pounded, false);
			
			hAnim.ResetMainActivity();
		}
	}
}