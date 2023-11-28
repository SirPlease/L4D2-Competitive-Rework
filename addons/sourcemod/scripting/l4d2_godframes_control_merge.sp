#pragma semicolon 1
#pragma newdecls required

/*
 * To-do:
 * Add flag cvar to control damage from different SI separately.
 * Add cvar to control whether tanks should reset frustration with hittable hits. Maybe.
 */
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks> //#include <l4d2_direct>
#define L4D2UTIL_STOCKS_ONLY 1
#include <l4d2util>

#define CLASSNAME_LENGTH 64

// Macros for easily referencing the Undo Damage array
#define UNDO_PERM 0
#define UNDO_TEMP 1
#define UNDO_SIZE 16

// Macros for stack argument array
#define STACK_VICTIM 0
#define STACK_DAMAGE 1
#define STACK_DISTANCE 2
#define STACK_TYPE 3
#define STACK_SIZE 4

// Announcement flags
#define ANNOUNCE_NONE 0
#define ANNOUNCE_CONSOLE 1
#define ANNOUNCE_CHAT 2

// Flags for different types of Friendly Fire
#define FFTYPE_NOTUNDONE 0
#define FFTYPE_TOOCLOSE 1
#define FFTYPE_CHARGERCARRY 2
#define FFTYPE_STUPIDBOTS 4
#define FFTYPE_MELEEFLAG 0x8000

//cvars
ConVar
	g_hRageRock = null,
	g_hRageHittables = null,
	g_hHittable = null,
	g_hWitch = null,
	g_hFF = null,
	g_hSpit = null,
	g_hCommon = null,
	g_hHunter = null,
	g_hSmoker = null,
	g_hJockey = null,
	g_hCharger = null,
	g_hChargerStagger = null,
	g_hChargerFlags = null,
	g_hSpitFlags = null,
	g_hCommonFlags = null,
	g_hGodframeGlows = null,
	g_hRock = null;

//shotgun ff stuff
ConVar
	g_hCvarEnableShotFF = null,
	g_hCvarModifier = null,
	g_hCvarMinFF = null,
	g_hCvarMaxFF = null;

bool
	g_bBuckshot[MAXPLAYERS + 1] = {false, ...};

//undo ff
ConVar
	g_hCvarEnable = null,
	g_hCvarBlockZeroDmg = null,
	g_hCvarPermDamageFraction = null;

int
	g_iEnabledFlags = 0,
	g_iBlockZeroDmg = 0,
	g_iLastHealth[MAXPLAYERS + 1][UNDO_SIZE][2],				// The Undo Damage array, with correlated arrays for holding the last revive count and current undo index
	g_iLastReviveCount[MAXPLAYERS + 1] = {0, ... },
	g_iCurrentUndo[MAXPLAYERS + 1] = {0, ... },
	g_iTargetTempHealth[MAXPLAYERS + 1] = {0, ... },			// Healing is weird, so this keeps track of our target OR the target's temp health
	g_iLastPerm[MAXPLAYERS + 1] = {100, ... },				// The permanent damage fraction requires some coordination between OnTakeDamage and player_hurt
	g_iLastTemp[MAXPLAYERS + 1] = {0, ... };

float
	g_fPermFrac = 0.0;

bool
	g_bChargerCarryNoFF[MAXPLAYERS + 1] = {false, ...},		// Flags for knowing when to undo friendly fire
	g_bStupidGuiltyBots[MAXPLAYERS + 1] = {false, ...};

//fake godframes
float
	g_fFakeGodframeEnd[MAXPLAYERS + 1] = {0.0, ...},
	g_fFakeChargeGodframeEnd[MAXPLAYERS + 1] = {0.0, ...};

Handle
	g_hTimer[MAXPLAYERS + 1] = {null, ...};

int
	g_iLastSI[MAXPLAYERS + 1] = {0, ...},
	g_iPelletsShot[MAXPLAYERS + 1][MAXPLAYERS + 1],			//shotgun ff
	g_iFrustrationOffset[MAXPLAYERS + 1] = {0, ...};			//frustration

bool
	g_bLateLoad = false; //late load

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrMax)
{
	CreateNative("GiveClientGodFrames", Native_GiveClientGodFrames);
	
	RegPluginLibrary("l4d2_godframes_control_merge");
	
	g_bLateLoad = bLate;
	return APLRes_Success;
}

public Plugin myinfo =
{
	name = "L4D2 Godframes Control combined with FF Plugins",
	author = "Stabby, CircleSquared, Tabun, Visor, dcx, Sir, Spoon, A1m`, Sir",
	version = "0.6.10",
	description = "Allows for control of what gets godframed and what doesnt along with integrated FF Support from l4d2_survivor_ff (by dcx and Visor) and l4d2_shotgun_ff (by Visor)"
};

public void OnPluginStart()
{
	g_hGodframeGlows = CreateConVar("gfc_godframe_glows", "1", "Changes the rendering of survivors while godframed (red/transparent).", _, true, 0.0, true, 1.0);
	g_hRageHittables = CreateConVar("gfc_hittable_rage_override", "1", "Allow tank to gain rage from hittable hits. 0 blocks rage gain.", _, true, 0.0, true, 1.0);
	g_hRageRock = CreateConVar("gfc_rock_rage_override", "1", "Allow tank to gain rage from godframed hits. 0 blocks rage gain.", _, true, 0.0, true, 1.0);
	g_hHittable = CreateConVar("gfc_hittable_override", "1", "Allow hittables to always ignore godframes.", _, true, 0.0, true, 1.0);
	g_hRock = CreateConVar("gfc_rock_override", "0", "Allow hittables to always ignore godframes.", _, true, 0.0, true, 1.0);
	g_hWitch = CreateConVar("gfc_witch_override", "1", "Allow witches to always ignore godframes.", _, true, 0.0, true, 1.0);
	g_hFF = CreateConVar("gfc_ff_min_time", "0.3", "Minimum time before FF damage is allowed.", _, true, 0.0, true, 3.0);
	g_hSpit = CreateConVar("gfc_spit_extra_time", "0.7", "Additional godframe time before spit damage is allowed.", 0, true, 0.0, true, 3.0);
	g_hCommon = CreateConVar("gfc_common_extra_time", "0.0", "Additional godframe time before common damage is allowed.", 0, true, 0.0, true, 3.0);
	g_hHunter = CreateConVar("gfc_hunter_duration", "2.1", "How long should godframes after a pounce last?", _, true, 0.0, true, 3.0);
	g_hJockey = CreateConVar("gfc_jockey_duration", "0.0", "How long should godframes after a ride last?", _, true, 0.0, true, 3.0);
	g_hSmoker = CreateConVar("gfc_smoker_duration", "0.0", "How long should godframes after a pull or choke last?", _, true, 0.0, true, 3.0);
	g_hCharger = CreateConVar("gfc_charger_duration", "2.1", "How long should godframes after a pummel last?", _, true, 0.0, true, 3.0);
	g_hChargerStagger = CreateConVar("gfc_charger_stagger_extra_time", "0.0", "Additional godframe time before damage from ChargerFlags is allowed.", _, true, 0.0, true, 3.0);
	g_hChargerFlags = CreateConVar("gfc_charger_stagger_flags", "0", "What will be affected by extra charger stagger protection time. 1 - Common. 2 - Spit.", _, true, 0.0, true, 3.0);
	g_hSpitFlags = CreateConVar("gfc_spit_zc_flags", "6", "Which classes will be affected by extra spit protection time. 1 - Hunter. 2 - Smoker. 4 - Jockey. 8 - Charger.", _, true, 0.0, true, 15.0);
	g_hCommonFlags= CreateConVar("gfc_common_zc_flags", "0", "Which classes will be affected by extra common protection time. 1 - Hunter. 2 - Smoker. 4 - Jockey. 8 - Charger.", _, true, 0.0, true, 15.0);

	g_hCvarEnable = CreateConVar("l4d2_undoff_enable", "7", "Bit flag: Enables plugin features (add together): 1=too close, 2=Charger carry, 4=guilty bots, 7=all, 0=off", FCVAR_NOTIFY);
	g_hCvarBlockZeroDmg = CreateConVar("l4d2_undoff_blockzerodmg","7", "Bit flag: Block 0 damage friendly fire effects like recoil and vocalizations/stats (add together): 4=bot hits human block recoil, 2=block vocals/stats on ALL difficulties, 1=block vocals/stats on everything EXCEPT Easy (flag 2 has precedence), 0=off", FCVAR_NOTIFY);
	g_hCvarPermDamageFraction = CreateConVar("l4d2_undoff_permdmgfrac", "1.0", "Minimum fraction of damage applied to permanent health", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	g_hCvarEnableShotFF = CreateConVar("l4d2_shotgun_ff_enable", "1", "Enable Shotgun FF Module?", _, true, 0.0, true, 5.0);
	g_hCvarModifier = CreateConVar("l4d2_shotgun_ff_multi", "0.5", "Shotgun FF damage modifier value", _, true, 0.0, true, 5.0);
	g_hCvarMinFF = CreateConVar("l4d2_shotgun_ff_min", "1.0", "Minimum allowed shotgun FF damage; 0 for no limit", _, true, 0.0);
	g_hCvarMaxFF = CreateConVar("l4d2_shotgun_ff_max", "6.0", "Maximum allowed shotgun FF damage; 0 for no limit", _, true, 0.0);

	g_hCvarEnable.AddChangeHook(OnUndoFFEnableChanged);
	g_hCvarBlockZeroDmg.AddChangeHook(OnUndoFFBlockZeroDmgChanged);
	g_hCvarPermDamageFraction.AddChangeHook(OnPermFracChanged);

	g_iEnabledFlags = g_hCvarEnable.IntValue;
	g_iBlockZeroDmg = g_hCvarBlockZeroDmg.IntValue;
	g_fPermFrac = g_hCvarPermDamageFraction.FloatValue;

	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
	HookEvent("friendly_fire", Event_FriendlyFire, EventHookMode_Pre);
	HookEvent("charger_carry_start", Event_ChargerCarryStart, EventHookMode_Post);
	HookEvent("charger_carry_end", Event_ChargerCarryEnd, EventHookMode_Post);
	HookEvent("heal_begin", Event_HealBegin, EventHookMode_Pre);
	HookEvent("heal_end", Event_HealEnd, EventHookMode_Pre);
	HookEvent("heal_success", Event_HealSuccess, EventHookMode_Pre);
	HookEvent("player_incapacitated_start", Event_PlayerIncapStart, EventHookMode_Pre);

	//Fake godframes
	HookEvent("tongue_release", PostSurvivorRelease);
	HookEvent("pounce_end", PostSurvivorRelease);
	HookEvent("jockey_ride_end", PostSurvivorRelease);
	HookEvent("charger_pummel_end", PostSurvivorRelease);

	//Pass over stuff on passover to and from bots
	HookEvent("bot_player_replace", Event_Replaced);
	HookEvent("player_bot_replace", Event_Replaced);
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	
	if (g_bLateLoad) {
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i)) {
				SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
				SDKHook(i, SDKHook_TraceAttack, TraceAttackUndoFF);
				
				g_bBuckshot[i] = false;
			}
			
			for (int j = 0; j < UNDO_SIZE; j++) {
				g_iLastHealth[i][j][UNDO_PERM] = 0;
				g_iLastHealth[i][j][UNDO_TEMP] = 0;
			}
		}
	}
}

//public void OnRoundStart() //l4d2util forward
public void Event_RoundStart(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++) { //clear both fake and real just because
		g_fFakeGodframeEnd[i] = 0.0;
		g_fFakeChargeGodframeEnd[i] = 0.0;
		g_bBuckshot[i] = false;
		if (g_hTimer[i] != null) delete g_hTimer[i];
	}
}

public void PostSurvivorRelease(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int iVictim = GetClientOfUserId(hEvent.GetInt("victim"));

	if (iVictim < 1 || !IsClientInGame(iVictim) || !IsPlayerAlive(iVictim)) {
		return; //just in case
	}

	float fNow = GetGameTime();
	
	//sets fake godframe time based on cvars for each ZC
	if (StrContains(sEventName, "tongue") != -1) {
		g_fFakeGodframeEnd[iVictim] = fNow + g_hSmoker.FloatValue;
		g_iLastSI[iVictim] = 2;
	} else if (StrContains(sEventName, "pounce") != -1) {
		g_fFakeGodframeEnd[iVictim] = fNow + g_hHunter.FloatValue;
		g_iLastSI[iVictim] = 1;
	} else if (StrContains(sEventName, "jockey") != -1) {
		g_fFakeGodframeEnd[iVictim] = fNow + g_hJockey.FloatValue;
		g_iLastSI[iVictim] = 4;
	} else if (StrContains(sEventName, "charger") != -1) {
		g_fFakeGodframeEnd[iVictim] = fNow + g_hCharger.FloatValue;
		g_iLastSI[iVictim] = 8;
	}
	
	SetGodFrameGlows(iVictim);
}

public void L4D2_OnStagger_Post(int client, int source)
{
	// Charger Impact handling, source is always null.
	if (IsValidSurvivor(client) && source == -1 && g_hChargerStagger.FloatValue > 0.0)
	{	
		float fNow = GetGameTime();

		// In case of multi-charger configs/modes.
		if (g_fFakeChargeGodframeEnd[client] > fNow)
			fNow = g_fFakeChargeGodframeEnd[client];

		g_fFakeChargeGodframeEnd[client] = fNow + g_hChargerStagger.FloatValue;
	}
}

public void Event_Replaced(Event hEvent, char[] name, bool dontBroadcast) 
{
	bool bBotReplaced = (!strncmp(name, "b", 1));
	int replaced = bBotReplaced ? GetClientOfUserId(hEvent.GetInt("bot")) : GetClientOfUserId(hEvent.GetInt("player"));
	int replacer = bBotReplaced ? GetClientOfUserId(hEvent.GetInt("player")) : GetClientOfUserId(hEvent.GetInt("bot"));

	g_fFakeGodframeEnd[replacer] = g_fFakeGodframeEnd[replaced];
	g_fFakeChargeGodframeEnd[replacer] = g_fFakeChargeGodframeEnd[replaced];
	g_iLastSI[replacer] = g_iLastSI[replaced];

	// Use 500 IQ to re-create 'accurate' timer on the replacer.
	if (g_hTimer[replaced] != null) delete g_hTimer[replaced];
	float fRemainingFakeGodFrames = g_fFakeGodframeEnd[replacer] - GetGameTime();
	if (fRemainingFakeGodFrames > 0.0)
		SetGodFrameGlows(replacer);
}

public void OnClientPutInServer(int iClient)
{
	SDKHook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(iClient, SDKHook_TraceAttack, TraceAttackUndoFF);
	
	g_bBuckshot[iClient] = false;
	
	for (int j = 0; j < UNDO_SIZE; j++) {
		g_iLastHealth[iClient][j][UNDO_PERM] = 0;
		g_iLastHealth[iClient][j][UNDO_TEMP] = 0;
	}
}

/* //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//																												   //
//																												   //
//								 --------------    Godframe Control      --------------							   //
//																												   //
//																												   //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

void Timed_SetFrustration(any iClient)
{
	if (IsTank(iClient) && IsPlayerAlive(iClient)) {
		int iFrust = GetEntProp(iClient, Prop_Send, "m_frustration");
		iFrust += g_iFrustrationOffset[iClient];
		
		if (iFrust > 100) {
			iFrust = 100;
		} else if (iFrust < 0) {
			iFrust = 0;
		}
		
		SetEntProp(iClient, Prop_Send, "m_frustration", iFrust);
		g_iFrustrationOffset[iClient] = 0;
	}
}

public Action OnTakeDamage(int iVictim, int &iAttacker, int &iInflictor, float &fDamage, \
								int &iDamagetype, int &iWeapon, float fDamageForce[3], float fDamagePosition[3])
{
	if (!IsValidSurvivor(iVictim) || !IsValidEdict(iAttacker) || !IsValidEdict(iInflictor)) { 
		return Plugin_Continue;
	}

	CountdownTimer cTimerGod = L4D2Direct_GetInvulnerabilityTimer(iVictim); // left4dhooks
	if (cTimerGod != CTimer_Null) {
		CTimer_Invalidate(cTimerGod); //set m_timestamp - 0.0
	}

	char sClassname[CLASSNAME_LENGTH];
	GetEntityClassname(iInflictor, sClassname, CLASSNAME_LENGTH);

	float fTimeLeft = g_fFakeGodframeEnd[iVictim] - GetGameTime();

	// Common
	if (StrEqual(sClassname, "infected")) {
		if (g_iLastSI[iVictim] & g_hCommonFlags.IntValue)
			fTimeLeft += g_hCommon.FloatValue;

		if (1 & g_hChargerFlags.IntValue && fTimeLeft <= 0.0) {
			float charginTime = g_fFakeChargeGodframeEnd[iVictim] - GetGameTime();
			fTimeLeft = charginTime > 0.0 ? charginTime : fTimeLeft;
		}
	}
	
	// Spit
	if (StrEqual(sClassname, "insect_swarm")) {
		if (g_iLastSI[iVictim] & g_hSpitFlags.IntValue)
			fTimeLeft += g_hSpit.FloatValue;

		if (2 & g_hChargerFlags.IntValue && fTimeLeft <= 0.0) {
			float charginTime = g_fFakeChargeGodframeEnd[iVictim] - GetGameTime();
			fTimeLeft = charginTime > 0.0 ? charginTime : fTimeLeft;
		}
	}
	
	if (IsValidSurvivor(iAttacker)) { //friendly fire
		//Block FF While Capped
		if (IsSurvivorAttacked(iVictim)) {
			return Plugin_Handled;
		}
		
		//Block AI FF
		if (IsFakeClient(iVictim) && IsFakeClient(iAttacker)) {
			return Plugin_Handled;
		}
		
		/**
		#define DMG_PLASMA	(1 << 24)	// < Shot by Cremator
					
		Special case -- let this function know that we've manually applied damage
		I am expecting some info about HL3 at GDC in March, so I felt like choosing this
		exotic damage flag that stands for a cut enemy from HL2
		**/

		//if (iDamagetype == DMG_PLASMA) {
		//	return Plugin_Continue;
		//}
		
		fTimeLeft += g_hFF.FloatValue;

		if (g_iEnabledFlags) {
			bool bUndone = false;
			int iDmg = RoundToFloor(fDamage); // Damage to survivors is rounded down
	
			// Only check damage to survivors
			// - if it is greater than 0, OR
			// - if a human survivor did 0 damage (so we know when the engine forgives our friendly fire for us)
			if (iDmg > 0 && !IsFakeClient(iAttacker)) {
				// Remember health for undo
				int iVictimPerm = GetClientHealth(iVictim);
				int iVictimTemp = GetSurvivorTemporaryHealth(iVictim);
				
				// if attacker is not ourself, check for undo damage
				if (iAttacker != iVictim) {
					char sWeaponName[CLASSNAME_LENGTH];
					GetSafeEntityName(iWeapon, sWeaponName, sizeof(sWeaponName));
					
					float fDistance = GetClientsDistance(iVictim, iAttacker);
					float FFDist = GetWeaponFFDist(sWeaponName);
					if ((g_iEnabledFlags & FFTYPE_TOOCLOSE) && (fDistance < FFDist)) {
						bUndone = true;
					} else if ((g_iEnabledFlags & FFTYPE_CHARGERCARRY) && (g_bChargerCarryNoFF[iVictim])) {
						bUndone = true;
					} else if ((g_iEnabledFlags & FFTYPE_STUPIDBOTS) && (g_bStupidGuiltyBots[iVictim])) {
						bUndone = true;
					} else if (iDmg == 0) {
						// In order to get here, you must be a human Survivor doing 0 damage to another Survivor
						bUndone = ((g_iBlockZeroDmg & 0x02) || ((g_iBlockZeroDmg & 0x01)));
					}
				}
		
				// TODO: move to player_hurt?  and check to make sure damage was consistent between the two?
				// We prefer to do this here so we know what the player's state looked like pre-damage
				// Specifically, what portion of the damage was applied to perm and temp health,
				// since we can't tell after-the-fact what the damage was applied to
				// Unfortunately, not all calls to OnTakeDamage result in the player being hurt (e.g. damage during god frames)
				// So we use player_hurt to know when OTD actually happened
				if (!bUndone && iDmg > 0) {
					int iPermDmg = RoundToCeil(g_fPermFrac * iDmg);
					if (iPermDmg >= iVictimPerm)
					{
						// Perm damage won't reduce permanent health below 1 if there is sufficient temp health
						iPermDmg = iVictimPerm - 1;
					}
					
					int iTempDmg = iDmg - iPermDmg;
					if (iTempDmg > iVictimTemp) {
						// If TempDmg exceeds current temp health, transfer the difference to perm damage
						iPermDmg += (iTempDmg - iVictimTemp);
						iTempDmg = iVictimTemp;
					}
				
					// Don't add to undo list if player is incapped
					if (!IsIncapacitated(iVictim)) {
						// point at next undo cell
						int iNextUndo = (g_iCurrentUndo[iVictim] + 1) % UNDO_SIZE;
						
						if (iPermDmg < iVictimPerm) {
							// This will call player_hurt, so we should store the damage done so that it can be added back if it is undone
							g_iLastHealth[iVictim][iNextUndo][UNDO_PERM] = iPermDmg;
							g_iLastHealth[iVictim][iNextUndo][UNDO_TEMP] = iTempDmg;
							
							// We need some way to tell player_hurt how much perm/temp health we expected the player to have after this attack
							// This is used to implement the fractional damage to perm health
							// We can't just set their health here because this attack might not actually do damage
							g_iLastPerm[iVictim] = iVictimPerm - iPermDmg;
							g_iLastTemp[iVictim] = iVictimTemp - iTempDmg;
						} else {
							// This will call player_incap_start, so we should store their exact health and incap count at the time of attack
							// If the incap is undone, we will restore these settings instead of adding them
							g_iLastHealth[iVictim][iNextUndo][UNDO_PERM] = iVictimPerm;
							g_iLastHealth[iVictim][iNextUndo][UNDO_TEMP] = iVictimTemp;
							
							// This is used to tell player_incap_start the exact amount of damage that was done by the attack
							g_iLastPerm[iVictim] = iPermDmg;
							g_iLastTemp[iVictim] = iTempDmg;
							
							// TODO: can we move to incapstart?
							g_iLastReviveCount[iVictim] = GetEntProp(iVictim, Prop_Send, "m_currentReviveCount");
						}
					}
				}
			}
			
			if (bUndone) {
				return Plugin_Handled;
			}
		}

		if (g_hCvarEnableShotFF.BoolValue && fTimeLeft <= 0.0 && IsT1Shotgun(iWeapon)) {
			g_iPelletsShot[iVictim][iAttacker]++;

			if (!g_bBuckshot[iAttacker]) {
				g_bBuckshot[iAttacker] = true;
				
				ArrayStack hStack = new ArrayStack(3);
				hStack.Push(iWeapon);
				hStack.Push(iAttacker);
				hStack.Push(iVictim);
				
				RequestFrame(ProcessShot, hStack);
			}
			
			return Plugin_Handled;
		}
	}
	
	if (IsValidClientIndex(iAttacker) && IsTank(iAttacker)) {
		if (strcmp(sClassname, "prop_physics") == 0|| strcmp(sClassname, "prop_car_alarm") == 0) {
			if (g_hRageHittables.BoolValue) {
				g_iFrustrationOffset[iAttacker] = -100;
			} else {
				g_iFrustrationOffset[iAttacker] = 0;
			}
			
			RequestFrame(Timed_SetFrustration, iAttacker);
		} else if (iWeapon == 52) { //tank rock
			if (g_hRageRock.BoolValue) {
				g_iFrustrationOffset[iAttacker] = -100;
			} else {
				g_iFrustrationOffset[iAttacker] = 0;
			}
			
			RequestFrame(Timed_SetFrustration, iAttacker);
		} 
	}

	if (fTimeLeft > 0) {//means fake god frames are in effect
		if (strcmp(sClassname, "prop_physics") == 0 || strcmp(sClassname, "prop_car_alarm") == 0) { //hittables
			if (g_hHittable.BoolValue) {
				return Plugin_Continue; 
			}
		}
		
		if (IsTankRock(iInflictor)) {//tank rock
			if (g_hRock.BoolValue) {
				return Plugin_Continue; 
			}
		}
		
		if (strcmp(sClassname, "witch") == 0) {//witches 
			if (g_hWitch.BoolValue) {
				return Plugin_Continue;
			}
		}
		
		return Plugin_Handled;
	} else {
		g_iLastSI[iVictim] = 0;
	}
	
	return Plugin_Continue;
}

public Action Timed_ResetGlow(Handle hTimer, any iClient)
{
	if (IsClientAndInGame(iClient)) {
		// remove transparency/color
		SetEntityRenderMode(iClient, RENDER_NORMAL);
		SetEntityRenderColor(iClient, 255, 255, 255, 255);
	}
	g_hTimer[iClient] = null;
	return Plugin_Stop;
}

public void OnMapStart()
{
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			// remove transparency/color
			SetEntityRenderMode(i, RENDER_NORMAL);
			SetEntityRenderColor(i, 255, 255, 255, 255);
		}
	}
}

/* //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//																												   //
//																												   //
//							--------------    JUST UNDO FF STUFF      --------------							   //
//																												   //
//																												   //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

// The sole purpose of this hook is to prevent survivor bots from causing the vision of human survivors to recoil
public Action TraceAttackUndoFF(int iVictim, int &iAttacker, int &iInflictor, float &fDamage, int &iDamagetype, int &iAmmotype, int iHitbox, int iHitgroup)
{
	// If none of the flags are enabled, don't do anything
	if (!g_iEnabledFlags) {
		return Plugin_Continue;
	}
	
	// Only interested in Survivor victims
	if (!IsValidSurvivor(iVictim)) {
		return Plugin_Continue;
	}
	
	// If a valid survivor bot shoots a valid survivor human, block it to prevent survivor vision from getting experiencing recoil (it would have done 0 damage anyway)
	if ((g_iBlockZeroDmg & 0x04) && IsValidSurvivor(iAttacker) && IsFakeClient(iAttacker) && IsValidSurvivor(iVictim) && !IsFakeClient(iVictim)) {
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

// Apply fractional permanent damage here
// Also announce damage, and undo guilty bot damage
public Action Event_PlayerHurt(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	if (!g_iEnabledFlags) {
		return Plugin_Continue;
	}
	
	int iVictim = GetClientOfUserId(hEvent.GetInt("userid"));
	if (iVictim < 1 || !IsSurvivor(iVictim)) {
		return Plugin_Continue;
	}
	
	int iAttacker = GetClientOfUserId(hEvent.GetInt("attacker"));
	int iDmg = hEvent.GetInt("dmg_health");
	int iCurrentPerm = hEvent.GetInt("health");
	
	/*char sWeaponName[CLASSNAME_LENGTH];
	hEvent.GetString("weapon", sWeaponName, sizeof(sWeaponName));*/
	
	// When incapped you continuously get hurt by the world, so we just ignore incaps altogether
	if (iDmg > 0 && !IsIncapacitated(iVictim)) {
		// Cycle the undo pointer when we have confirmed that the damage was actually taken
		g_iCurrentUndo[iVictim] = (g_iCurrentUndo[iVictim] + 1) % UNDO_SIZE;
		
		// victim values are what OnTakeDamage expected us to have, current values are what the game gave us
		int iVictimPerm = g_iLastPerm[iVictim];
		int iVictimTemp = g_iLastTemp[iVictim];
		int iCurrentTemp = GetSurvivorTemporaryHealth(iVictim);

		// If this feature is enabled, some portion of damage will be applied to the temp health
		if (g_fPermFrac < 1.0 && iVictimPerm != iCurrentPerm) {
			// make sure we don't give extra health
			int iTotalHealthOld = iCurrentPerm + iCurrentTemp;
			int iTotalHealthNew = iVictimPerm + iVictimTemp;
			
			if (iTotalHealthOld == iTotalHealthNew) {
				SetEntityHealth(iVictim, iVictimPerm);

				SetEntPropFloat(iVictim, Prop_Send, "m_healthBuffer", float(iVictimTemp));
				SetEntPropFloat(iVictim, Prop_Send, "m_healthBufferTime", GetGameTime());
			}
		}
	}
	
	// Announce damage, and check for guilty bots that slipped through OnTakeDamage
	if (IsValidSurvivor(iAttacker)) {
		// Unfortunately, the friendly fire event only fires *after* OnTakeDamage has been called so it can't be blocked in time
		// So we must check here to see if the bots are guilty and undo the damage after-the-fact
		if ((g_iEnabledFlags & FFTYPE_STUPIDBOTS) && (g_bStupidGuiltyBots[iVictim])) {
			UndoDamage(iVictim);
		}
	}

	return Plugin_Continue;
}

// When a Survivor is incapped by damage, player_hurt will not fire
// So you may notice that the code here has some similarities to the code for player_hurt
public Action Event_PlayerIncapStart(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	// Cycle the incap pointer, now that the damage has been confirmed
	int iVictim = GetClientOfUserId(hEvent.GetInt("userid"));
	
	// Cycle the undo pointer when we have confirmed that the damage was actually taken
	g_iCurrentUndo[iVictim] = (g_iCurrentUndo[iVictim] + 1) % UNDO_SIZE;
	
	int iAttacker = GetClientOfUserId(hEvent.GetInt("attacker"));
 
	// Announce damage, and check for guilty bots that slipped through OnTakeDamage
	if (IsValidSurvivor(iAttacker)) {
		// Unfortunately, the friendly fire event only fires *after* OnTakeDamage has been called so it can't be blocked in time
		// So we must check here to see if the bots are guilty and undo the damage after-the-fact
		if ((g_iEnabledFlags & FFTYPE_STUPIDBOTS) && (g_bStupidGuiltyBots[iVictim])) {
			UndoDamage(iVictim);
		}
	}

	return Plugin_Continue;
}

// If a bot is guilty of creating a friendly fire event, undo it
// Also give the human some reaction time to realize the bot ran in front of them
public Action Event_FriendlyFire(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	if (!(g_iEnabledFlags & FFTYPE_STUPIDBOTS)) {
		return Plugin_Continue;
	}
	
	int iClient = GetClientOfUserId(hEvent.GetInt("guilty"));
	if (IsFakeClient(iClient)) {
		g_bStupidGuiltyBots[iClient] = true;
		CreateTimer(0.4, StupidGuiltyBotDelay, iClient, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return Plugin_Continue;
}

public Action StupidGuiltyBotDelay(Handle hTimer, any iClient)
{
	g_bStupidGuiltyBots[iClient] = false;

	return Plugin_Stop;
}

// While a Charger is carrying a Survivor, undo any friendly fire done to them
// since they are effectively pinned and pinned survivors are normally immune to FF
public Action Event_ChargerCarryStart(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	if (!(g_iEnabledFlags & FFTYPE_CHARGERCARRY)) {
		return Plugin_Continue;
	}
	
	int iClient = GetClientOfUserId(hEvent.GetInt("victim"));

	g_bChargerCarryNoFF[iClient] = true;

	return Plugin_Continue;
}

// End immunity about one second after the carry ends
// (there is some time between carryend and pummelbegin,
// but pummelbegin does not always get called if the charger died first, so it is unreliable
// and besides the survivor has natural FF immunity when pinned)
public Action Event_ChargerCarryEnd(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("victim"));
	CreateTimer(1.0, ChargerCarryFFDelay, iClient, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}

public Action ChargerCarryFFDelay(Handle hTimer, any iClient)
{
	g_bChargerCarryNoFF[iClient] = false;

	return Plugin_Stop;
}

// For health kit undo, we must remember the target in HealBegin
public Action Event_HealBegin(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	if (!g_iEnabledFlags) {
		return Plugin_Continue; // Not enabled?  Done
	}
	
	int iSubject = GetClientOfUserId(hEvent.GetInt("subject"));

	if (iSubject < 1 || !IsSurvivor(iSubject) || !IsPlayerAlive(iSubject)) {
		return Plugin_Continue;
	}
	
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if (iClient < 1 || !IsSurvivor(iClient) || !IsPlayerAlive(iClient)) {
		return Plugin_Continue;
	}
	
	// Remember the target for HealEnd, since that parameter is a lie for that event
	g_iTargetTempHealth[iClient] = iSubject;

	return Plugin_Continue;
}

// When healing ends, remember how much temp health the target had
// This way it can be restored in UndoDamage
public Action Event_HealEnd(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	if (!g_iEnabledFlags) {
		return Plugin_Continue; // Not enabled?  Done
	}
	
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	int iSubject = g_iTargetTempHealth[iClient]; // this is used first to carry the subject...
	
	if (iSubject < 1 || !IsSurvivor(iSubject) || !IsPlayerAlive(iSubject)) {
		PrintToServer("Who did you heal? (%d)", iSubject);
		return Plugin_Continue;
	}
	
	int iTempHealth =  GetSurvivorTemporaryHealth(iSubject);
	if (iTempHealth < 0) {
		iTempHealth = 0;
	}
	
	// ...and second it is used to store the subject's temp health (since success knows the subject)
	g_iTargetTempHealth[iClient] = iTempHealth;
	return Plugin_Continue;
}

// Save the amount of health restored as negative so it can be undone
public Action Event_HealSuccess(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	if (!g_iEnabledFlags) {
		return Plugin_Continue; // Not enabled?  Done
	}
	
	int iSubject = GetClientOfUserId(hEvent.GetInt("subject"));
	if (iSubject < 1 || !IsSurvivor(iSubject) || !IsPlayerAlive(iSubject)) {
		return Plugin_Continue;
	}
	
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	
	int iNextUndo = (g_iCurrentUndo[iSubject] + 1) % UNDO_SIZE;
	g_iLastHealth[iSubject][iNextUndo][UNDO_PERM] = -hEvent.GetInt("health_restored");
	g_iLastHealth[iSubject][iNextUndo][UNDO_TEMP] = g_iTargetTempHealth[iClient];
	g_iCurrentUndo[iSubject] = iNextUndo;

	return Plugin_Continue;
}

// The magic behind Undo Damage
// Cycles through the array, can also undo incapacitations
void UndoDamage(int iClient)
{
	if (IsValidSurvivor(iClient)) {
		int iThisUndo = g_iCurrentUndo[iClient];
		int iUndoPerm = g_iLastHealth[iClient][iThisUndo][UNDO_PERM];
		int iUndoTemp = g_iLastHealth[iClient][iThisUndo][UNDO_TEMP];

		int iNewHealth, iNewTemp;
		if (IsIncapacitated(iClient)) {
			// If player is incapped, restore their previous health and incap count
			iNewHealth = iUndoPerm;
			iNewTemp = iUndoTemp;
			
			CheatCommand(iClient, "give", "health");
			SetEntProp(iClient, Prop_Send, "m_currentReviveCount", g_iLastReviveCount[iClient]);
		} else {
			// add perm and temp health back to their existing health
			iNewHealth = GetClientHealth(iClient) + iUndoPerm;
			iNewTemp = iUndoTemp;
			if (iUndoPerm >= 0) {
				// undoing damage, so add current temp health do undoTemp
				iNewTemp += GetSurvivorTemporaryHealth(iClient);
			} else {
				// undoPerm is negative when undoing healing, so don't add current temp health
				// instead, give the health kit that was undone
				CheatCommand(iClient, "give", "weapon_first_aid_kit");
			}
		}
		
		if (iNewHealth > 100) {
			iNewHealth = 100; // prevent going over 100 health
		}
		
		if (iNewHealth + iNewTemp > 100) {
			iNewTemp = 100 - iNewHealth;
		}
		
		SetEntityHealth(iClient, iNewHealth);
		SetEntPropFloat(iClient, Prop_Send, "m_healthBuffer", float(iNewTemp));
		SetEntPropFloat(iClient, Prop_Send, "m_healthBufferTime", GetGameTime());
	
		// clear out the undo so it can't happen again
		g_iLastHealth[iClient][iThisUndo][UNDO_PERM] = 0;
		g_iLastHealth[iClient][iThisUndo][UNDO_TEMP] = 0;
		
		// point to the previous undo
		if (iThisUndo <= 0) {
			iThisUndo = UNDO_SIZE;
		}
		
		iThisUndo = iThisUndo - 1;
		g_iCurrentUndo[iClient] = iThisUndo;
	}
}

// Gets the distance between two survivors
// Accounting for any difference in height
float GetClientsDistance(int iVictim, int iAttacker)
{
	float fMins[3], fMaxs[3];
	GetClientMins(iVictim, fMins);
	GetClientMaxs(iVictim, fMaxs);
	
	float fHalfHeight = fMaxs[2] - fMins[2] + 10;
	
	float fAttackerPos[3], fVictimPos[3];
	GetClientAbsOrigin(iVictim, fVictimPos);
	GetClientAbsOrigin(iAttacker, fAttackerPos);
	
	float fPosHeightDiff = fAttackerPos[2] - fVictimPos[2];
	
	if (fPosHeightDiff > fHalfHeight) {
		fAttackerPos[2] -= fHalfHeight;
	} else if (fPosHeightDiff < (-1.0 * fHalfHeight)) {
		fVictimPos[2] -= fHalfHeight;
	} else {
		fAttackerPos[2] = fVictimPos[2];
	}
	
	return GetVectorDistance(fVictimPos, fAttackerPos, false);
}

// Gets per-weapon friendly fire undo distances
float GetWeaponFFDist(char[] sWeaponName)
{
	if (strcmp(sWeaponName, "weapon_melee") == 0
		|| strcmp(sWeaponName, "weapon_pistol") == 0
	) {
		return 25.0;
	} else if (strcmp(sWeaponName, "weapon_smg") == 0
		|| strcmp(sWeaponName, "weapon_smg_silenced") == 0
		|| strcmp(sWeaponName, "weapon_smg_mp5") == 0
		|| strcmp(sWeaponName, "weapon_pistol_magnum") == 0
	) {
		return 30.0;
	} else if (strcmp(sWeaponName, "weapon_pumpshotgun") == 0
		|| strcmp(sWeaponName, "weapon_shotgun_chrome") == 0
		|| strcmp(sWeaponName, "weapon_hunting_rifle") == 0
		|| strcmp(sWeaponName, "weapon_sniper_scout") == 0
		|| strcmp(sWeaponName, "weapon_sniper_awp") == 0
	) {
		return 37.0;
	}

	return 0.0;
}

void GetSafeEntityName(int iEntity, char[] sName, const int iNameSize)
{
	if (iEntity > 0 && IsValidEntity(iEntity)) {
		GetEntityClassname(iEntity, sName, iNameSize);
		return;
	}

	strcopy(sName, iNameSize, "Invalid");
}

void CheatCommand(int iClient, const char[] sCommand, const char[] sArguments)
{
	int flags = GetCommandFlags(sCommand);
	SetCommandFlags(sCommand, flags & ~FCVAR_CHEAT);
	FakeClientCommand(iClient, "%s %s", sCommand, sArguments);
	SetCommandFlags(sCommand, flags);
}

bool IsClientAndInGame(int iClient)
{
	return (iClient > 0 && iClient <= MaxClients && IsClientInGame(iClient));
}

// Cvars
public void OnUndoFFEnableChanged(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	g_iEnabledFlags = StringToInt(sNewValue);
}

public void OnUndoFFBlockZeroDmgChanged(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	g_iBlockZeroDmg = StringToInt(sNewValue);
}

public void OnPermFracChanged(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	g_fPermFrac = StringToFloat(sNewValue);
}

/* //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//																												   //
//																												   //
//								--------------    L4D2 Shotgun FF      --------------							   //
//																												   //
//																												   //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */
public void ProcessShot(ArrayStack hStack)
{
	int iVictim = 0, iAttacker = 0, iWeapon = 0;
	if (!hStack.Empty) {
		iVictim = hStack.Pop();
		iAttacker = hStack.Pop();
		iWeapon = hStack.Pop();
	}
	
	if (IsClientAndInGame(iVictim) && IsClientAndInGame(iAttacker)) {
		CountdownTimer cTimerGod = L4D2Direct_GetInvulnerabilityTimer(iVictim); // left4dhooks
		if (cTimerGod != CTimer_Null) {
			CTimer_Invalidate(cTimerGod); //set m_timestamp - 0.0
		}
		
		// Replicate natural behaviour
		float fMinFF = g_hCvarMinFF.FloatValue;
		float fMaxFFCvarValue = g_hCvarMaxFF.FloatValue;
		float fMaxFF = fMaxFFCvarValue <= 0.0 ? 99999.0 : fMaxFFCvarValue;
		float fDamage = L4D2Util_GetMaxFloat(fMinFF, L4D2Util_GetMinFloat((g_iPelletsShot[iVictim][iAttacker] * g_hCvarModifier.FloatValue), fMaxFF));
		g_iPelletsShot[iVictim][iAttacker] = 0;
		
		int iNewPelletCount = RoundFloat(fDamage);
		for (int i = 0; i < iNewPelletCount; i++) {
			SDKHooks_TakeDamage(iVictim, iAttacker, iAttacker, 1.0, DMG_BUCKSHOT, iWeapon, .bypassHooks = true);
		}
	}
	
	g_bBuckshot[iAttacker] = false;

	delete hStack;
}

bool IsT1Shotgun(int iEntity)
{
	if (iEntity <= MaxClients || !IsValidEdict(iEntity)) {
		return false;
	}
	
	char sClassname[CLASSNAME_LENGTH];
	GetEdictClassname(iEntity, sClassname, sizeof(sClassname));
	return (strcmp(sClassname, "weapon_pumpshotgun") == 0 || strcmp(sClassname, "weapon_shotgun_chrome") == 0);
}

bool IsTankRock(int iEntity)
{
	if (iEntity <= MaxClients || !IsValidEdict(iEntity)) {
		return false;
	}
	
	char sClassname[CLASSNAME_LENGTH];
	GetEdictClassname(iEntity, sClassname, sizeof(sClassname));
	return (strcmp(sClassname, "tank_rock") == 0);
}

// Natives
public int Native_GiveClientGodFrames(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	
	if (!IsClientAndInGame(iClient)) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index or client is not in game (index %d)!", iClient);
	}
	
	if (!IsPlayerAlive(iClient)) {
		return ThrowNativeError(SP_ERROR_NATIVE, "The client is not alive (index %d)!", iClient);
	}
	
	float fGodFrameTime = GetNativeCell(2);
	int iAttackerClass = GetNativeCell(3);
	
	float fNow = GetGameTime();
	
	g_fFakeGodframeEnd[iClient] = fNow + fGodFrameTime; //godFrameTime
	g_iLastSI[iClient] = iAttackerClass; //attackerClass
	
	SetGodFrameGlows(iClient);
	
	return 1;
}

void SetGodFrameGlows(int client)
{
	if (g_hTimer[client])
		delete g_hTimer[client];
	
	float fNow = GetGameTime();
	
	if (g_fFakeGodframeEnd[client] <= fNow)
	{
		Timed_ResetGlow(null, client);
		return;
	}
	
	if (g_hGodframeGlows.BoolValue)
	{
		// make player transparent/red while godframed
		SetEntityRenderMode(client, RENDER_GLOW);
		SetEntityRenderColor(client, 255, 0, 0, 200);
		
		g_hTimer[client] = CreateTimer(g_fFakeGodframeEnd[client] - fNow, Timed_ResetGlow, client);
	}
}