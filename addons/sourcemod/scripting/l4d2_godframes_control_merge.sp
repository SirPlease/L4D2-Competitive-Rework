#pragma semicolon 1

/*
 * To-do:
 * Add flag cvar to control damage from different SI separately.
 * Add cvar to control whether tanks should reset frustration with hittable hits. Maybe.
 */

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>
#include <l4d2util>

#define CLASSNAME_LENGTH 64
#define MIN(%0,%1) (((%0) < (%1)) ? (%0) : (%1))
#define MAX(%0,%1) (((%0) > (%1)) ? (%0) : (%1))

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

// Macros for determining client validity
#define IS_VALID_CLIENT(%1) (%1 > 0 && %1 <= MaxClients)
#define IS_SURVIVOR(%1) (GetClientTeam(%1) == 2)
#define IS_INFECTED(%1) (GetClientTeam(%1) == 3)
#define IS_VALID_INGAME(%1) (IS_VALID_CLIENT(%1) && IsClientInGame(%1))
#define IS_VALID_SURVIVOR(%1) (IS_VALID_INGAME(%1) && IS_SURVIVOR(%1))
#define IS_VALID_INFECTED(%1) (IS_VALID_INGAME(%1) && IS_INFECTED(%1))
#define IS_SURVIVOR_ALIVE(%1) (IS_VALID_SURVIVOR(%1) && IsPlayerAlive(%1))
#define IS_INFECTED_ALIVE(%1) (IS_VALID_INFECTED(%1) && IsPlayerAlive(%1))

//cvars
new Handle: hRageRock = INVALID_HANDLE;
new Handle: hRageHittables = INVALID_HANDLE;
new Handle: hHittable = INVALID_HANDLE;
new Handle: hWitch = INVALID_HANDLE;
new Handle: hFF = INVALID_HANDLE;
new Handle: hSpit = INVALID_HANDLE;
new Handle: hCommon = INVALID_HANDLE;
new Handle: hHunter = INVALID_HANDLE;
new Handle: hSmoker = INVALID_HANDLE;
new Handle: hJockey = INVALID_HANDLE;
new Handle: hCharger = INVALID_HANDLE;
new Handle: hSpitFlags = INVALID_HANDLE;
new Handle: hCommonFlags = INVALID_HANDLE;
new Handle: hGodframeGlows = INVALID_HANDLE;
new Handle: hRock = INVALID_HANDLE;

//shotgun ff stuff
new Handle:hCvarEnableShotFF;
new Handle:hCvarModifier;
new Handle:hCvarMinFF;
new Handle:hCvarMaxFF;
new bool:bBuckshot[MAXPLAYERS + 1];

//undo ff
new Handle:g_cvarEnable = INVALID_HANDLE;
new Handle:g_cvarBlockZeroDmg = INVALID_HANDLE;
new Handle:g_cvarPermDamageFraction = INVALID_HANDLE;

new g_EnabledFlags;
new g_BlockZeroDmg;
new g_lastHealth[MAXPLAYERS+1][UNDO_SIZE][2];					// The Undo Damage array, with correlated arrays for holding the last revive count and current undo index
new g_lastReviveCount[MAXPLAYERS+1] = { 0, ... };
new g_currentUndo[MAXPLAYERS+1] = { 0, ... };
new g_targetTempHealth[MAXPLAYERS+1] = { 0, ... };				// Healing is weird, so this keeps track of our target OR the target's temp health
new g_lastPerm[MAXPLAYERS+1] = { 100, ... };					// The permanent damage fraction requires some coordination between OnTakeDamage and player_hurt
new g_lastTemp[MAXPLAYERS+1] = { 0, ... };

new Float:g_flPermFrac;

new bool:g_chargerCarryNoFF[MAXPLAYERS+1] = { false, ... };		// Flags for knowing when to undo friendly fire
new bool:g_stupidGuiltyBots[MAXPLAYERS+1] = { false, ... };

//fake godframes
new Float: fFakeGodframeEnd[MAXPLAYERS + 1];
new iLastSI[MAXPLAYERS + 1];

//shotgun ff
new pelletsShot[MAXPLAYERS + 1][MAXPLAYERS + 1];

//frustration
new frustrationOffset[MAXPLAYERS + 1];

//late load
new bool:bLateLoad;

public APLRes:AskPluginLoad2( Handle:plugin, bool:late, String:error[], errMax )
{
	bLateLoad = late;
	CreateNative("GiveClientGodFrames", Native_GiveClientGodFrames);
	RegPluginLibrary("l4d2_godframes_control_merge");
	return APLRes_Success;
}

public Plugin:myinfo =
{
	name = "L4D2 Godframes Control combined with FF Plugins",
	author = "Stabby, CircleSquared, Tabun, Visor, dcx, Sir, Spoon",
	version = "0.6.2",
	description = "Allows for control of what gets godframed and what doesnt along with integrated FF Support from l4d2_survivor_ff (by dcx and Visor) and l4d2_shotgun_ff (by Visor)"
};

public OnPluginStart()
{
	hGodframeGlows = CreateConVar("gfc_godframe_glows", "1",
									"Changes the rendering of survivors while godframed (red/transparent).",
									0, true, 0.0, true, 1.0 );
	hRageHittables = CreateConVar("gfc_hittable_rage_override", "1",
									"Allow tank to gain rage from hittable hits. 0 blocks rage gain.",
									0, true, 0.0, true, 1.0 );
	hRageRock = CreateConVar(	"gfc_rock_rage_override", "1",
									"Allow tank to gain rage from godframed hits. 0 blocks rage gain.",
									0, true, 0.0, true, 1.0 );
	hHittable = CreateConVar(	"gfc_hittable_override", "1",
									"Allow hittables to always ignore godframes.",
									0, true, 0.0, true, 1.0 );
	hRock = CreateConVar(	"gfc_rock_override", "0",
									"Allow hittables to always ignore godframes.",
									0, true, 0.0, true, 1.0 );
	hWitch = CreateConVar( 		"gfc_witch_override", "1",
									"Allow witches to always ignore godframes.",
									0, true, 0.0, true, 1.0 );
	hFF = CreateConVar( 		"gfc_ff_min_time", "0.3",
									"Minimum time before FF damage is allowed.",
									0, true, 0.0, true, 3.0 );
	hSpit = CreateConVar( 		"gfc_spit_extra_time", "0.7",
									"Additional godframe time before spit damage is allowed.",
									0, true, 0.0, true, 3.0 );
	hCommon = CreateConVar( 	"gfc_common_extra_time", "0.0",
									"Additional godframe time before common damage is allowed.",
									0, true, 0.0, true, 3.0 );
	hHunter = CreateConVar( 	"gfc_hunter_duration", "2.1",
									"How long should godframes after a pounce last?",
									0, true, 0.0, true, 3.0 );
	hJockey = CreateConVar( 	"gfc_jockey_duration", "0.0",
									"How long should godframes after a ride last?",
									0, true, 0.0, true, 3.0 );
	hSmoker = CreateConVar( 	"gfc_smoker_duration", "0.0",
									"How long should godframes after a pull or choke last?",
									0, true, 0.0, true, 3.0 );
	hCharger = CreateConVar( 	"gfc_charger_duration", "2.1",
									"How long should godframes after a pummel last?",
									0, true, 0.0, true, 3.0 );
	hSpitFlags = CreateConVar( 	"gfc_spit_zc_flags", "6",
									"Which classes will be affected by extra spit protection time. 1 - Hunter. 2 - Smoker. 4 - Jockey. 8 - Charger.",
									0, true, 0.0, true, 15.0 );
	hCommonFlags= CreateConVar( "gfc_common_zc_flags", "0",
									"Which classes will be affected by extra common protection time. 1 - Hunter. 2 - Smoker. 4 - Jockey. 8 - Charger.",
									0, true, 0.0, true, 15.0 );

	g_cvarEnable = 				CreateConVar("l4d2_undoff_enable", 		"7", 	"Bit flag: Enables plugin features (add together): 1=too close, 2=Charger carry, 4=guilty bots, 7=all, 0=off", FCVAR_NOTIFY);
	g_cvarBlockZeroDmg =		CreateConVar("l4d2_undoff_blockzerodmg","7", 	"Bit flag: Block 0 damage friendly fire effects like recoil and vocalizations/stats (add together): 4=bot hits human block recoil, 2=block vocals/stats on ALL difficulties, 1=block vocals/stats on everything EXCEPT Easy (flag 2 has precedence), 0=off", FCVAR_NOTIFY);
	g_cvarPermDamageFraction = 	CreateConVar("l4d2_undoff_permdmgfrac", "1.0", 	"Minimum fraction of damage applied to permanent health", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	hCvarEnableShotFF = CreateConVar("l4d2_shotgun_ff_enable", "1", "Enable Shotgun FF Module?");
	hCvarModifier = CreateConVar("l4d2_shotgun_ff_multi", "0.5", "Shotgun FF damage modifier value", 0, true, 0.0, true, 5.0);
	hCvarMinFF = CreateConVar("l4d2_shotgun_ff_min", "1.0", "Minimum allowed shotgun FF damage; 0 for no limit", 0, true, 0.0);
	hCvarMaxFF = CreateConVar("l4d2_shotgun_ff_max", "6.0", "Maximum allowed shotgun FF damage; 0 for no limit", 0, true, 0.0);

	HookConVarChange(g_cvarEnable, 				OnUndoFFEnableChanged);
	HookConVarChange(g_cvarBlockZeroDmg, 		OnUndoFFBlockZeroDmgChanged);
	HookConVarChange(g_cvarPermDamageFraction, 	OnPermFracChanged);

	g_EnabledFlags = GetConVarInt(g_cvarEnable);
	g_BlockZeroDmg = GetConVarInt(g_cvarBlockZeroDmg);
	g_flPermFrac = GetConVarFloat(g_cvarPermDamageFraction);

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

	if (bLateLoad) InitializeHooks();
}

public OnRoundStart()
{
	for (new i = 1; i <= MaxClients; i++) //clear both fake and real just because
	{
		fFakeGodframeEnd[i] = 0.0;
		bBuckshot[i] = false;
	}
}

public Native_GiveClientGodFrames(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new Float:godFrameTime = GetNativeCell(2);
	new attackerClass = GetNativeCell(3);
	
	if (!IsClientAndInGame(client)) { return; } //just in case
	
	fFakeGodframeEnd[client] = GetGameTime() + godFrameTime;
	iLastSI[client] = attackerClass;
	
	SetGodframedGlow(client);
	CreateTimer(fFakeGodframeEnd[client] - GetGameTime(), Timed_ResetGlow, client);
}

public PostSurvivorRelease(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event,"victim"));

	if (!IsClientAndInGame(victim)) { return; } //just in case

	//sets fake godframe time based on cvars for each ZC
	if (StrContains(name, "tongue") != -1)
	{
		fFakeGodframeEnd[victim] = GetGameTime() + GetConVarFloat(hSmoker);
		iLastSI[victim] = 2;
	} else
	if (StrContains(name, "pounce") != -1)
	{
		fFakeGodframeEnd[victim] = GetGameTime() + GetConVarFloat(hHunter);
		iLastSI[victim] = 1;
	} else
	if (StrContains(name, "jockey") != -1)
	{
		fFakeGodframeEnd[victim] = GetGameTime() + GetConVarFloat(hJockey);
		iLastSI[victim] = 4;
	} else
	if (StrContains(name, "charger") != -1)
	{
		fFakeGodframeEnd[victim] = GetGameTime() + GetConVarFloat(hCharger);
		iLastSI[victim] = 8;
	}
	
	if (fFakeGodframeEnd[victim] > GetGameTime() && GetConVarBool(hGodframeGlows)) {
		SetGodframedGlow(victim);
		CreateTimer(fFakeGodframeEnd[victim] - GetGameTime(), Timed_ResetGlow, victim);
	}

	return;
}

public OnClientPutInServer(client)
{
	InitializeHooks(client);
}

InitializeHooks(client = -1)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (client > -1) i = client;
		
		if (IsClientInGame(i)) 
		{
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			SDKHook(i, SDKHook_TraceAttack, TraceAttackUndoFF);
			bBuckshot[i] = false;
		}
		
		for (new j = 0; j < UNDO_SIZE; j++)
		{
			g_lastHealth[i][j][UNDO_PERM] = 0;
			g_lastHealth[i][j][UNDO_TEMP] = 0;
		}
		
		if (client > -1) break;
	}
}

/* //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//																												   //
//																												   //
//                             --------------    Godframe Control      --------------							   //
//																												   //
//																												   //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

public Action:Timed_SetFrustration(Handle:timer, any:client) {
	if (IsClientConnected(client) && IsPlayerAlive(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 8) {
		new frust = GetEntProp(client, Prop_Send, "m_frustration");
		frust += frustrationOffset[client];
		
		if (frust > 100) frust = 100;
		else if (frust < 0) frust = 0;
		
		SetEntProp(client, Prop_Send, "m_frustration", frust);
		frustrationOffset[client] = 0;
	}
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if (!IS_VALID_SURVIVOR(victim) || !IsValidEdict(attacker) || !IsValidEdict(inflictor)) { return Plugin_Continue; }

	new CountdownTimer:cTimerGod = L4D2Direct_GetInvulnerabilityTimer(victim);
	if (cTimerGod != CTimer_Null) { CTimer_Invalidate(cTimerGod); }

	decl String:sClassname[CLASSNAME_LENGTH];
	GetEntityClassname(inflictor, sClassname, CLASSNAME_LENGTH);

	new Float:fTimeLeft = fFakeGodframeEnd[victim] - GetGameTime();

	if (StrEqual(sClassname, "infected") && (iLastSI[victim] & GetConVarInt(hCommonFlags))) //commons
	{
		fTimeLeft += GetConVarFloat(hCommon);
	}
	if (StrEqual(sClassname, "insect_swarm") && (iLastSI[victim] & GetConVarInt(hSpitFlags))) //spit
	{
		fTimeLeft += GetConVarFloat(hSpit);
	}
	if (IS_VALID_SURVIVOR(attacker)) //friendly fire
	{	
		//Block FF While Capped
		if (IsSurvivorBusy(victim)) return Plugin_Handled;

		//Block AI FF
		if (IsFakeClient(victim) && IsFakeClient(attacker)) return Plugin_Handled;

		/**
		#define DMG_PLASMA	(1 << 24)	// < Shot by Cremator
					
		Special case -- let this function know that we've manually applied damage
		I am expecting some info about HL3 at GDC in March, so I felt like choosing this
		exotic damage flag that stands for a cut enemy from HL2
		**/

		if (damagetype == DMG_PLASMA) return Plugin_Continue;

		fTimeLeft += GetConVarFloat(hFF);

		if (g_EnabledFlags)
		{
			new bool:undone = false;
			new dmg = RoundToFloor(damage);	// Damage to survivors is rounded down
	
			// Only check damage to survivors
			// - if it is greater than 0, OR
			// - if a human survivor did 0 damage (so we know when the engine forgives our friendly fire for us)
			if (dmg > 0 && !IsFakeClient(attacker))
			{
				// Remember health for undo
				new victimPerm = GetClientHealth(victim);
				new victimTemp = L4D_GetPlayerTempHealth(victim);
				// if attacker is not ourself, check for undo damage
				if (attacker != victim)
				{
					decl String:weaponName[32];
					GetSafeEntityName(weapon, weaponName, sizeof(weaponName));
					new Float:Distance = GetClientsDistance(victim, attacker);
					new Float:FFDist = GetWeaponFFDist(weaponName);

					if ((g_EnabledFlags & FFTYPE_TOOCLOSE) && (Distance < FFDist))
					{
						undone = true;
					}
					else if ((g_EnabledFlags & FFTYPE_CHARGERCARRY) && (g_chargerCarryNoFF[victim]))
					{
						undone = true;
					}
					else if ((g_EnabledFlags & FFTYPE_STUPIDBOTS) && (g_stupidGuiltyBots[victim]))
					{
						undone = true;
					}
					else if (dmg == 0)
					{
						// In order to get here, you must be a human Survivor doing 0 damage to another Survivor
						undone = (g_BlockZeroDmg & 0x02) || ((g_BlockZeroDmg & 0x01));
					}
				}
		
				// TODO: move to player_hurt?  and check to make sure damage was consistent between the two?
				// We prefer to do this here so we know what the player's state looked like pre-damage
				// Specifically, what portion of the damage was applied to perm and temp health,
				// since we can't tell after-the-fact what the damage was applied to
				// Unfortunately, not all calls to OnTakeDamage result in the player being hurt (e.g. damage during god frames)
				// So we use player_hurt to know when OTD actually happened
				if (!undone && dmg > 0)
				{			
					new PermDmg = RoundToCeil(g_flPermFrac * dmg);
					if (PermDmg >= victimPerm)
					{
						// Perm damage won't reduce permanent health below 1 if there is sufficient temp health
						PermDmg = victimPerm - 1;
					}
					new TempDmg = dmg - PermDmg;
					if (TempDmg > victimTemp)
					{
						// If TempDmg exceeds current temp health, transfer the difference to perm damage
						PermDmg += (TempDmg - victimTemp);
						TempDmg = victimTemp;
					}
				
					// Don't add to undo list if player is incapped
					if (!L4D_IsPlayerIncapacitated(victim))
					{
						// point at next undo cell
						new nextUndo = (g_currentUndo[victim] + 1) % UNDO_SIZE;
							
						if (PermDmg < victimPerm)
						{
							// This will call player_hurt, so we should store the damage done so that it can be added back if it is undone
							g_lastHealth[victim][nextUndo][UNDO_PERM] = PermDmg;
							g_lastHealth[victim][nextUndo][UNDO_TEMP] = TempDmg;
							
							// We need some way to tell player_hurt how much perm/temp health we expected the player to have after this attack
							// This is used to implement the fractional damage to perm health
							// We can't just set their health here because this attack might not actually do damage
							g_lastPerm[victim] = victimPerm - PermDmg;
							g_lastTemp[victim] = victimTemp - TempDmg;
						}
						else
						{
							// This will call player_incap_start, so we should store their exact health and incap count at the time of attack
							// If the incap is undone, we will restore these settings instead of adding them
							g_lastHealth[victim][nextUndo][UNDO_PERM] = victimPerm;
							g_lastHealth[victim][nextUndo][UNDO_TEMP] = victimTemp;
							
							// This is used to tell player_incap_start the exact amount of damage that was done by the attack
							g_lastPerm[victim] = PermDmg;
							g_lastTemp[victim] = TempDmg;
							
							// TODO: can we move to incapstart?
							g_lastReviveCount[victim] = L4D_GetPlayerReviveCount(victim);
						}
					}
				}
			}
			
			if (undone) return Plugin_Handled;
		}

		if (GetConVarBool(hCvarEnableShotFF) && fTimeLeft <= 0.0 && IsT1Shotgun(weapon))
		{	
			pelletsShot[victim][attacker]++;

			if (!bBuckshot[attacker])
			{
				bBuckshot[attacker] = true;
				new Handle:stack = CreateStack(3);
				PushStackCell(stack, weapon);
				PushStackCell(stack, attacker);
				PushStackCell(stack, victim);
				RequestFrame(ProcessShot, stack);
			}
			return Plugin_Handled;
		}
	}

	if (IsClientAndInGame(attacker) && GetClientTeam(attacker) == 3 && GetEntProp(attacker, Prop_Send, "m_zombieClass") == 8) {
		if (StrEqual(sClassname, "prop_physics") || StrEqual(sClassname, "prop_car_alarm")) {
			if (GetConVarBool(hRageHittables)) {
				frustrationOffset[attacker] = -100;
			} else {
				frustrationOffset[attacker] = 0;
			}
			CreateTimer(0.1, Timed_SetFrustration, attacker);
		} else
		if (weapon == 52) {	//tank rock
			if (GetConVarBool(hRageRock)) {
				frustrationOffset[attacker] = -100;
			} else {
				frustrationOffset[attacker] = 0;
			}
			CreateTimer(0.1, Timed_SetFrustration, attacker);
		} 
	}

	if (fTimeLeft > 0) //means fake god frames are in effect
	{
		if (StrEqual(sClassname, "prop_physics") || StrEqual(sClassname, "prop_car_alarm")) //hittables
		{
			if (GetConVarBool(hHittable)) { return Plugin_Continue; }
		}
		if (IsTankRock(inflictor)) //tank rock
		{
			if (GetConVarBool(hRock)) { return Plugin_Continue; }
		}
		if (StrEqual(sClassname, "witch")) //witches
		{
			if (GetConVarBool(hWitch)) { return Plugin_Continue; }
		}
		return Plugin_Handled;
	}
	else
	{
		iLastSI[victim] = 0;
	}
	return Plugin_Continue;
}

stock IsClientAndInGame(client)
{
	if (0 < client && client <= MaxClients)
	{	
		return IsClientInGame(client);
	}
	return false;
}

stock IsSurvivorBusy(client)
{
	return (GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") > 0 || 
	GetEntPropEnt(client, Prop_Send, "m_carryAttacker") > 0 || 
	GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0 || 
	GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0 || 
	GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0);
}
public Action:Timed_ResetGlow(Handle:timer, any:client) {
	ResetGlow(client);
}

ResetGlow(client) {
	if (IsClientAndInGame(client)) {
		// remove transparency/color
		SetEntityRenderMode(client, RenderMode:0);
		SetEntityRenderColor(client, 255,255,255,255);
	}
}

SetGodframedGlow(client) {	//there might be issues with realism
	if (IsClientAndInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2) {
		// make player transparent/red while godframed
		SetEntityRenderMode( client, RenderMode:3 );
		SetEntityRenderColor (client, 255,0,0,200 );
	}
}

public OnMapStart() {
	for (new i = 0; i <= MaxClients; i++) {
		ResetGlow(i);
	}
}

/* //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//																												   //
//																												   //
//                             --------------    JUST UNDO FF STUFF      --------------							   //
//																												   //
//																												   //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

// The sole purpose of this hook is to prevent survivor bots from causing the vision of human survivors to recoil
public Action:TraceAttackUndoFF(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	// If none of the flags are enabled, don't do anything
	if (!g_EnabledFlags) return Plugin_Continue;
	
	// Only interested in Survivor victims
	if (!IS_VALID_SURVIVOR(victim)) return Plugin_Continue;
	
	// If a valid survivor bot shoots a valid survivor human, block it to prevent survivor vision from getting experiencing recoil (it would have done 0 damage anyway)
	if ((g_BlockZeroDmg & 0x04) && IS_VALID_SURVIVOR(attacker) && IsFakeClient(attacker) && IS_VALID_SURVIVOR(victim) && !IsFakeClient(victim))
	{
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

// Apply fractional permanent damage here
// Also announce damage, and undo guilty bot damage
public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_EnabledFlags) return Plugin_Continue;

	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IS_VALID_SURVIVOR(victim)) return Plugin_Continue;
	
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new dmg = GetEventInt(event, "dmg_health");
	new currentPerm = GetEventInt(event, "health");
	
	decl String:weaponName[32];
	GetEventString(event, "weapon", weaponName, sizeof(weaponName));
	
	// When incapped you continuously get hurt by the world, so we just ignore incaps altogether
	if (dmg > 0 && !L4D_IsPlayerIncapacitated(victim))
	{
		// Cycle the undo pointer when we have confirmed that the damage was actually taken
		g_currentUndo[victim] = (g_currentUndo[victim] + 1) % UNDO_SIZE;
		
		// victim values are what OnTakeDamage expected us to have, current values are what the game gave us
		new victimPerm = g_lastPerm[victim];
		new victimTemp = g_lastTemp[victim];
		new currentTemp = L4D_GetPlayerTempHealth(victim);

		// If this feature is enabled, some portion of damage will be applied to the temp health
		if (g_flPermFrac < 1.0 && victimPerm != currentPerm)
		{
			// make sure we don't give extra health
			new totalHealthOld = currentPerm + currentTemp, totalHealthNew = victimPerm + victimTemp;
			if (totalHealthOld == totalHealthNew)
			{
				SetEntityHealth(victim, victimPerm);
				L4D_SetPlayerTempHealth(victim, victimTemp);
			}
		}
	}
	
	// Announce damage, and check for guilty bots that slipped through OnTakeDamage
	if (IS_VALID_SURVIVOR(attacker))
	{
		// Unfortunately, the friendly fire event only fires *after* OnTakeDamage has been called so it can't be blocked in time
		// So we must check here to see if the bots are guilty and undo the damage after-the-fact
		if ((g_EnabledFlags & FFTYPE_STUPIDBOTS) && (g_stupidGuiltyBots[victim]))
		{
			UndoDamage(victim);
		}
	}

	return Plugin_Continue;
}

// When a Survivor is incapped by damage, player_hurt will not fire
// So you may notice that the code here has some similarities to the code for player_hurt
public Action:Event_PlayerIncapStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Cycle the incap pointer, now that the damage has been confirmed
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// Cycle the undo pointer when we have confirmed that the damage was actually taken
	g_currentUndo[victim] = (g_currentUndo[victim] + 1) % UNDO_SIZE;
	
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
 
	// Announce damage, and check for guilty bots that slipped through OnTakeDamage
	if (IS_VALID_SURVIVOR(attacker))
	{
		// Unfortunately, the friendly fire event only fires *after* OnTakeDamage has been called so it can't be blocked in time
		// So we must check here to see if the bots are guilty and undo the damage after-the-fact
		if ((g_EnabledFlags & FFTYPE_STUPIDBOTS) && (g_stupidGuiltyBots[victim]))
		{
			UndoDamage(victim);
		}
	}
}

// If a bot is guilty of creating a friendly fire event, undo it
// Also give the human some reaction time to realize the bot ran in front of them
public Action:Event_FriendlyFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!(g_EnabledFlags & FFTYPE_STUPIDBOTS)) return Plugin_Continue;

	new client = GetClientOfUserId(GetEventInt(event, "guilty"));
	if (IsFakeClient(client))
	{
		g_stupidGuiltyBots[client] = true;
		CreateTimer(0.4, StupidGuiltyBotDelay, client);
	}
	return Plugin_Continue;
}

public Action:StupidGuiltyBotDelay(Handle:timer, any:client)
{
	g_stupidGuiltyBots[client] = false;
}

// While a Charger is carrying a Survivor, undo any friendly fire done to them
// since they are effectively pinned and pinned survivors are normally immune to FF
public Action:Event_ChargerCarryStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!(g_EnabledFlags & FFTYPE_CHARGERCARRY)) return Plugin_Continue;
	
	new client = GetClientOfUserId(GetEventInt(event, "victim"));

	g_chargerCarryNoFF[client] = true;
	return Plugin_Continue;
}

// End immunity about one second after the carry ends
// (there is some time between carryend and pummelbegin,
// but pummelbegin does not always get called if the charger died first, so it is unreliable
// and besides the survivor has natural FF immunity when pinned)
public Action:Event_ChargerCarryEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "victim"));
	CreateTimer(1.0, ChargerCarryFFDelay, client);	
	return Plugin_Continue;
}

public Action:ChargerCarryFFDelay(Handle:timer, any:client)
{
	g_chargerCarryNoFF[client] = false;
}

// For health kit undo, we must remember the target in HealBegin
public Action:Event_HealBegin(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_EnabledFlags) 			return Plugin_Continue;	// Not enabled?  Done

	new subject = GetClientOfUserId(GetEventInt(event, "subject"));
	new userid = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!IS_SURVIVOR_ALIVE(subject) || !IS_SURVIVOR_ALIVE(userid)) return Plugin_Continue;
	
	// Remember the target for HealEnd, since that parameter is a lie for that event
	g_targetTempHealth[userid] = subject;

	return Plugin_Continue;
}

// When healing ends, remember how much temp health the target had
// This way it can be restored in UndoDamage
public Action:Event_HealEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_EnabledFlags) 			return Plugin_Continue;	// Not enabled?  Done

	new userid = GetClientOfUserId(GetEventInt(event, "userid"));
	new subject = g_targetTempHealth[userid];	// this is used first to carry the subject...
	new tempHealth;
	
	if (!IS_SURVIVOR_ALIVE(subject))
	{
		PrintToServer("Who did you heal? (%d)", subject);	
		return Plugin_Continue;
	}
	
	tempHealth =  L4D_GetPlayerTempHealth(subject);
	if (tempHealth < 0) tempHealth = 0;
	
	// ...and second it is used to store the subject's temp health (since success knows the subject)
	g_targetTempHealth[userid] = tempHealth;
	
	return Plugin_Continue;
}

// Save the amount of health restored as negative so it can be undone
public Action:Event_HealSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_EnabledFlags) return Plugin_Continue;	// Not enabled?  Done
	
	new subject = GetClientOfUserId(GetEventInt(event, "subject"));
	new userid = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!IS_SURVIVOR_ALIVE(subject)) return Plugin_Continue;

	new nextUndo = (g_currentUndo[subject] + 1) % UNDO_SIZE;
	g_lastHealth[subject][nextUndo][UNDO_PERM] = -GetEventInt(event, "health_restored");
	g_lastHealth[subject][nextUndo][UNDO_TEMP] = g_targetTempHealth[userid];
	g_currentUndo[subject] = nextUndo;

	return Plugin_Continue;
}

// The magic behind Undo Damage
// Cycles through the array, can also undo incapacitations
UndoDamage(client)
{
	if (IS_VALID_SURVIVOR(client))
	{
		new thisUndo = g_currentUndo[client];
		new undoPerm = g_lastHealth[client][thisUndo][UNDO_PERM];
		new undoTemp = g_lastHealth[client][thisUndo][UNDO_TEMP];

		new newHealth, newTemp;
		if (L4D_IsPlayerIncapacitated(client))
		{
			// If player is incapped, restore their previous health and incap count
			newHealth = undoPerm;
			newTemp = undoTemp;
			
			CheatCommand(client, "give", "health");
			L4D_SetPlayerReviveCount(client, g_lastReviveCount[client]);
		}
		else
		{
			// add perm and temp health back to their existing health
			newHealth = GetClientHealth(client) + undoPerm;
			newTemp = undoTemp;
			if (undoPerm >= 0)
			{
				// undoing damage, so add current temp health do undoTemp
				newTemp += L4D_GetPlayerTempHealth(client);
			}
			else
			{
				// undoPerm is negative when undoing healing, so don't add current temp health
				// instead, give the health kit that was undone
				CheatCommand(client, "give", "weapon_first_aid_kit");
			}
		}
		if (newHealth > 100) newHealth = 100;						// prevent going over 100 health
		if (newHealth + newTemp > 100) newTemp = 100 - newHealth;
		SetEntityHealth(client, newHealth);
		L4D_SetPlayerTempHealth(client, newTemp);

		// clear out the undo so it can't happen again
		g_lastHealth[client][thisUndo][UNDO_PERM] = 0;
		g_lastHealth[client][thisUndo][UNDO_TEMP] = 0;
		
		// point to the previous undo
		if (thisUndo <= 0) thisUndo = UNDO_SIZE;
		thisUndo = thisUndo - 1;
		g_currentUndo[client] = thisUndo;
	}
}

// Gets the distance between two survivors
// Accounting for any difference in height
stock Float:GetClientsDistance(victim, attacker)
{
	decl Float:attackerPos[3], Float:victimPos[3];
	decl Float:mins[3], Float:maxs[3], Float:halfHeight;
	GetClientMins(victim, mins);
	GetClientMaxs(victim, maxs);
	
	halfHeight = maxs[2] - mins[2] + 10;
	
	GetClientAbsOrigin(victim,victimPos);
	GetClientAbsOrigin(attacker,attackerPos);
	
	new Float:posHeightDiff = attackerPos[2] - victimPos[2];
	
	if (posHeightDiff > halfHeight)
	{
		attackerPos[2] -= halfHeight;
	}
	else if (posHeightDiff < (-1.0 * halfHeight))
	{
		victimPos[2] -= halfHeight;
	}
	else
	{
		attackerPos[2] = victimPos[2];
	}
	
	return GetVectorDistance(victimPos ,attackerPos, false);
}

// Gets per-weapon friendly fire undo distances
public Float:GetWeaponFFDist(String:weaponName[])
{
	if (StrEqual(weaponName, "weapon_melee") 
		|| StrEqual(weaponName, "weapon_pistol"))
	{
		return 25.0;
	}
	else if (StrEqual(weaponName, "weapon_smg") 
			|| StrEqual(weaponName, "weapon_smg_silenced") 
			|| StrEqual(weaponName, "weapon_smg_mp5") 
			|| StrEqual(weaponName, "weapon_pistol_magnum"))
	{
		return 30.0;
	}
	else if	(StrEqual(weaponName, "weapon_pumpshotgun")
			|| StrEqual(weaponName, "weapon_shotgun_chrome") 
			|| StrEqual(weaponName, "weapon_hunting_rifle") 
			|| StrEqual(weaponName, "weapon_sniper_scout") 
			|| StrEqual(weaponName, "weapon_sniper_awp"))
	{
		return 37.0;
	}

	return 0.0;
}

stock GetSafeEntityName(entity, String:TheName[], TheNameSize)
{
	if (entity > 0 && IsValidEntity(entity))
	{
		GetEntityClassname(entity, TheName, TheNameSize);
	}
	else
	{
		strcopy(TheName, TheNameSize, "Invalid");
	}
}

// I believe this is from Mr. Zero's stocks?
stock L4D_GetPlayerTempHealth(client)
{
	if (!IS_VALID_SURVIVOR(client)) return 0;
	
	static Handle:painPillsDecayCvar = INVALID_HANDLE;
	if (painPillsDecayCvar == INVALID_HANDLE)
	{
		painPillsDecayCvar = FindConVar("pain_pills_decay_rate");
		if (painPillsDecayCvar == INVALID_HANDLE)
		{
			return -1;
		}
	}

	new tempHealth = RoundToCeil(GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * GetConVarFloat(painPillsDecayCvar))) - 1;
	return tempHealth < 0 ? 0 : tempHealth;
}

stock L4D_SetPlayerTempHealth(client, tempHealth)
{
    SetEntPropFloat(client, Prop_Send, "m_healthBuffer", float(tempHealth));
    SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
}

stock L4D_GetPlayerReviveCount(client)
{
	return GetEntProp(client, Prop_Send, "m_currentReviveCount");
}

stock L4D_SetPlayerReviveCount(client, any:count)
{
	SetEntProp(client, Prop_Send, "m_currentReviveCount", count);
}

stock bool:L4D_IsPlayerIncapacitated(client)
{
	return bool:GetEntProp(client, Prop_Send, "m_isIncapacitated", 1);
}

stock CheatCommand(client, const String:command[], const String:arguments[])
{
    new flags = GetCommandFlags(command);
    SetCommandFlags(command, flags & ~FCVAR_CHEAT);
    FakeClientCommand(client, "%s %s", command, arguments);
    SetCommandFlags(command, flags);
}

public OnUndoFFEnableChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
	g_EnabledFlags = StringToInt(newVal);

public OnUndoFFBlockZeroDmgChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
	g_BlockZeroDmg = StringToInt(newVal);

public OnPermFracChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
	g_flPermFrac = StringToFloat(newVal);

/* //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//																												   //
//																												   //
//                             --------------    L4D2 Shotgun FF      --------------							   //
//																												   //
//																												   //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////// */

bool:IsT1Shotgun(weapon)
{
	if (!IsValidEdict(weapon)) return false;
	decl String:classname[64];
	GetEdictClassname(weapon, classname, sizeof(classname));
	return (StrEqual(classname, "weapon_pumpshotgun") || StrEqual(classname, "weapon_shotgun_chrome"));
}

void ProcessShot(ArrayStack stack)
{
	static victim, attacker, weapon;
	if (!IsStackEmpty(stack))
	{
		PopStackCell(stack, victim);
		PopStackCell(stack, attacker);
		PopStackCell(stack, weapon);
	}
	
	if (IS_VALID_INGAME(victim) && IS_VALID_INGAME(attacker))
	{
		// Replicate natural behaviour
		new Float:minFF = GetConVarFloat(hCvarMinFF);
		new Float:maxFF = GetConVarFloat(hCvarMaxFF) <= 0.0 ? 99999.0 : GetConVarFloat(hCvarMaxFF);
		new Float:damage = MAX(minFF, MIN((pelletsShot[victim][attacker] * GetConVarFloat(hCvarModifier)), maxFF));
		new newPelletCount = RoundFloat(damage);
		pelletsShot[victim][attacker] = 0;
		for (new i = 0; i < newPelletCount; i++)
		{
			SDKHooks_TakeDamage(victim, attacker, attacker, 1.0, DMG_PLASMA, weapon, NULL_VECTOR, NULL_VECTOR);
		}
	}
	
	bBuckshot[attacker] = false;

	CloseHandle(stack);
}

bool:IsTankRock(entity)
{
    if (entity > 0 && IsValidEntity(entity) && IsValidEdict(entity))
    {
        decl String:classname[64];
        GetEdictClassname(entity, classname, sizeof(classname));
        return StrEqual(classname, "tank_rock");
    }
    return false;
}
