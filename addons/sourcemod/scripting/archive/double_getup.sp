/*
	SourcePawn is Copyright (C) 2006-2015 AlliedModders LLC.  All rights reserved.
	SourceMod is Copyright (C) 2006-2015 AlliedModders LLC.  All rights reserved.
	Pawn and SMALL are Copyright (C) 1997-2015 ITB CompuPhase.
	Source is Copyright (C) Valve Corporation.
	All trademarks are property of their respective owners.

	This program is free software: you can redistribute it and/or modify it
	under the terms of the GNU General Public License as published by the
	Free Software Foundation, either version 3 of the License, or (at your
	option) any later version.

	This program is distributed in the hope that it will be useful, but
	WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
	General Public License for more details.

	You should have received a copy of the GNU General Public License along
	with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
// Possible getups:
// Charger clear which still incaps
// Smoker pull on a Hunter getup
// Insta-clear hunter during any getup
// Tank rock on a charger getup
// Tank punch on a charger getup
// Tank rock on a multi-charger getup
// Tank punch on a multi-charge getup

// Missing getups:
// Tank punch on rock getup
// Tank punch on jockeyed player

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#define L4D2UTIL_STOCKS_ONLY 1
#include <l4d2util> // Needed for IdentifySurvivor calls. I use survivor indices rather than client indices in case someone leaves while incapped (with a pending getup).
#include <left4dhooks> // Needed for forcing players to have a getup animation.

#define DEBUG 0

enum ePlayerState
{
	eUPRIGHT = 0,
	eINCAPPED,
	eSMOKED,
	eJOCKEYED,
	eHUNTER_GETUP,
	eINSTACHARGED, // 5
	eCHARGED,
	eCHARGER_GETUP,
	eMULTI_CHARGED,
	eTANK_ROCK_GETUP,
	eTANK_PUNCH_FLY, // 10
	eTANK_PUNCH_GETUP,
	eTANK_PUNCH_FIX,
	eTANK_PUNCH_JOCKEY_FIX
}

stock const int tankFlyAnim[SurvivorCharacter_Size - 1] =
{
	628, // Nick
	636, // Rochelle
	628, // Coach
	633, // Ellis
	536, // Bill
	545, // Zoey
	539, // Francis
	536, // Louis
	539 // Francis
};

ConVar
	rockPunchFix,
	longerTankPunchGetup;

bool
	lateLoad;

int
	pendingGetups[SurvivorCharacter_Size - 1] = {0, ...}, // This is used to track the number of pending getups. The collective opinion is that you should have at most 1.
	interrupt[SurvivorCharacter_Size - 1] = {false, ...}, // If the player was getting up, and that getup is interrupted. This alows us to break out of the GetupTimer loop.
	currentSequence[SurvivorCharacter_Size - 1] = {0, ...}; // Kept to track when a player changes sequences, i.e. changes animations.

ePlayerState
	playerState[SurvivorCharacter_Size] = {eUPRIGHT, ...}; // Since there are multiple sequences for each animation, this acts as a simpler way to track a player's state.

public Plugin myinfo =
{
	name = "L4D2 Get-Up Fix",
	author = "Darkid, Jacob",
	description = "Fixes the problem when, after completing a getup animation, you have another one.",
	version = "3.8.1",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	lateLoad = late;

	return APLRes_Success;
}

public void OnPluginStart()
{
	rockPunchFix = CreateConVar("rock_punch_fix", "1", "When a tank punches someone who is getting up from a rock, cause them to have an extra getup.", _, true, 0.0, true, 1.0);
	longerTankPunchGetup = CreateConVar("longer_tank_punch_getup", "0", "When a tank punches someone give them a slightly longer getup.", _, true, 0.0, true, 1.0);

	HookEvent("round_start", round_start, EventHookMode_PostNoCopy);
	HookEvent("tongue_grab", smoker_land);
	HookEvent("jockey_ride", jockey_land);
	HookEvent("jockey_ride_end", jockey_clear);
	HookEvent("tongue_release", smoker_clear);
	HookEvent("pounce_stopped", hunter_clear);
	HookEvent("charger_impact", multi_charge);
	HookEvent("charger_carry_end", charger_land_instant);
	HookEvent("charger_pummel_start", charger_land);
	HookEvent("charger_pummel_end", charger_clear);
	HookEvent("player_incapacitated", player_incap);
	HookEvent("revive_success", player_revive);

	if (lateLoad) {
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i)) {
				OnClientPutInServer(i);
			}
		}
	}
}

// Used to check for tank rocks and tank punches.
public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void round_start(Event hEvent, const char[] name, bool dontBroadcast)
{
	for (int survivor = 0; survivor < SurvivorCharacter_Size; survivor++) {
		playerState[survivor] = eUPRIGHT;
	}
}

// If a player is smoked while getting up from a hunter, the getup is interrupted.
public void smoker_land(Event hEvent, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("victim"));
	int survivor = IdentifySurvivor(client);
	if (survivor == SurvivorCharacter_Invalid) {
		return;
	}
	
	if (playerState[survivor] == eHUNTER_GETUP) {
		interrupt[survivor] = true;
	}
}

public void jockey_land(Event hEvent, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("victim"));
	int survivor = IdentifySurvivor(client);
	if (survivor == SurvivorCharacter_Invalid) {
		return;
	}

	playerState[survivor] = eJOCKEYED;
}

public void jockey_clear(Event hEvent, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("victim"));
	int survivor = IdentifySurvivor(client);
	if (survivor == SurvivorCharacter_Invalid) {
		return;
	}
	
	if (playerState[survivor] == eJOCKEYED) {
		playerState[survivor] = eUPRIGHT;
	}
}

// If a player is cleared from a smoker, they should not have a getup.
public void smoker_clear(Event hEvent, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("victim"));
	int survivor = IdentifySurvivor(client);
	if (survivor == SurvivorCharacter_Invalid) {
		return;
	}
	
	if (playerState[survivor] == eINCAPPED) {
		return;
	}
	
	playerState[survivor] = eUPRIGHT;
	_CancelGetup(client);
}

// If a player is cleared from a hunter, they should have 1 getup.
public void hunter_clear(Event hEvent, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("victim"));
	int survivor = IdentifySurvivor(client);
	if (survivor == SurvivorCharacter_Invalid) {
		return;
	}
	
	if (playerState[survivor] == eINCAPPED) {
		return;
	}
	
	// If someone gets cleared WHILE they are otherwise getting up, they double-getup.
	if (isGettingUp(survivor)) {
		pendingGetups[survivor]++;
		return;
	}
	
	playerState[survivor] = eHUNTER_GETUP;
	_GetupTimer(client);
}

// If a player is impacted during a charged, they should have 1 getup.
public void multi_charge(Event hEvent, const char[] name, bool dontBroadcast)
{
	int survivor = IdentifySurvivor(GetClientOfUserId(hEvent.GetInt("victim")));
	if (survivor == SurvivorCharacter_Invalid) {
		return;
	}
	
	if (playerState[survivor] == eINCAPPED) {
		return;
	}
	
	playerState[survivor] = eMULTI_CHARGED;
}

// If a player is cleared from a charger, they should have 1 getup.
public void charger_land_instant(Event hEvent, const char[] name, bool dontBroadcast)
{
	int survivor = IdentifySurvivor(GetClientOfUserId(hEvent.GetInt("victim")));
	if (survivor == SurvivorCharacter_Invalid) {
		return;
	}
	
	// If the player is incapped when the charger lands, they will getup after being revived.
	if (playerState[survivor] == eINCAPPED) {
		pendingGetups[survivor]++;
	}

	playerState[survivor] = eINSTACHARGED;
}

// This event defines when a player transitions from being insta-charged to being pummeled.
public void charger_land(Event hEvent, const char[] name, bool dontBroadcast)
{
	int survivor = IdentifySurvivor(GetClientOfUserId(hEvent.GetInt("victim")));
	if (survivor == SurvivorCharacter_Invalid) {
		return;
	}

	if (playerState[survivor] == eINCAPPED) {
		return;
	}

	playerState[survivor] = eCHARGED;
}

// If a player is cleared from a charger, they should have 1 getup.
public void charger_clear(Event hEvent, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("victim"));
	int survivor = IdentifySurvivor(client);
	if (survivor == SurvivorCharacter_Invalid) {
		return;
	}
	
	if (playerState[survivor] == eINCAPPED) {
		return;
	}
	
	playerState[survivor] = eCHARGER_GETUP;
	_GetupTimer(client);
}

// If a player is incapped, mark that down. This will interrupt their animations, if they have any.
public void player_incap(Event hEvent, const char[] name, bool dontBroadcast)
{
	int survivor = IdentifySurvivor(GetClientOfUserId(hEvent.GetInt("userid")));
	if (survivor == SurvivorCharacter_Invalid) {
		return;
	}
	
	// If the player is incapped when the charger lands, they will getup after being revived.
	if (playerState[survivor] == eINSTACHARGED) {
		pendingGetups[survivor]++;
	}
	
	playerState[survivor] = eINCAPPED;
}

// When a player is picked up, they should have 0 getups.
public void player_revive(Event hEvent, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("subject"));
	int survivor = IdentifySurvivor(client);
	if (survivor == SurvivorCharacter_Invalid) {
		return;
	}
	
	playerState[survivor] = eUPRIGHT;
	_CancelGetup(client);
}

// A catch-all to handle damage that is not associated with an event. I use this instead of player_hurt because it ignores godframes.
public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	int survivor = IdentifySurvivor(victim);
	if (survivor == SurvivorCharacter_Invalid) {
		return Plugin_Continue;
	}
	
	char weapon[32];
	GetEdictClassname(inflictor, weapon, sizeof(weapon));
	if (strcmp(weapon, "weapon_tank_claw") == 0) {
		if (playerState[survivor] == eCHARGER_GETUP) {
			interrupt[survivor] = true;
		} else if (playerState[survivor] == eMULTI_CHARGED) {
			pendingGetups[survivor]++;
		}

		if (playerState[survivor] == eTANK_ROCK_GETUP && rockPunchFix.BoolValue) {
			playerState[survivor] = eTANK_PUNCH_FIX;
		} else if (playerState[survivor] == eJOCKEYED) {
			playerState[survivor] = eTANK_PUNCH_JOCKEY_FIX;
			_TankLandTimer(victim);
		} else {
			playerState[survivor] = eTANK_PUNCH_FLY;
			// Watches and waits for the survivor to enter their getup animation. It is possible to skip the fly animation, so this can't be tracked by state-based logic.
			_TankLandTimer(victim);
		}
	} else if (strcmp(weapon, "tank_rock") == 0) {
		if (playerState[survivor] == eCHARGER_GETUP) {
			interrupt[survivor] = true;
		} else if (playerState[survivor] == eMULTI_CHARGED) {
			pendingGetups[survivor]++;
		}
		
		playerState[survivor] = eTANK_ROCK_GETUP;
		
		_GetupTimer(victim);
	}
	
	return Plugin_Continue;
}

// Detects when a player lands from a tank punch.
void _TankLandTimer(int client)
{
	CreateTimer(0.04, TankLandTimer, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action TankLandTimer(Handle hTimer, any client)
{
	int survivor = IdentifySurvivor(client);
	if (survivor == SurvivorCharacter_Invalid) {
		return Plugin_Stop;
	}
	
	// I consider players to have "landed" only once they stop being in the fly anim or the landing anim (fly + 1).
	if (GetEntProp(client, Prop_Send, "m_nSequence") == tankFlyAnim[survivor] 
		|| GetEntProp(client, Prop_Send, "m_nSequence") == (tankFlyAnim[survivor] + 1)
	) {
		return Plugin_Continue;
	}
	
	int iAnimation = (longerTankPunchGetup.BoolValue) ? ANIM_SHOVED_BY_TEAMMATE : ANIM_TANK_PUNCH_GETUP; // 96 is the tank punch getup.
	
	if (playerState[survivor] == eTANK_PUNCH_JOCKEY_FIX) {
		// When punched out of a jockey, the player goes into land (fly+1) for an arbitrary number of frames, then enters land (fly+2) for an arbitrary number of frames. Once they're done "landing" we give them the getup they deserve.
		if (GetEntProp(client, Prop_Send, "m_nSequence") == (tankFlyAnim[survivor] + 2)) {
			return Plugin_Continue;
		}
		
		#if DEBUG
		PrintToChatAll("[Getup] Giving %N an extra getup...", client);
		#endif
		
		L4D2Direct_DoAnimationEvent(client, iAnimation);
	}
	
	if (playerState[survivor] == eTANK_PUNCH_FLY) {
		playerState[survivor] = eTANK_PUNCH_GETUP;
	}
	
	L4D2Direct_DoAnimationEvent(client, iAnimation);
	
	_GetupTimer(client);
	return Plugin_Stop;
}

// Detects when a player finishes getting up, i.e. their sequence changes.
void _GetupTimer(int client)
{
	CreateTimer(0.04, GetupTimer, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action GetupTimer(Handle hTimer, any client)
{
	int survivor = IdentifySurvivor(client);
	if (survivor == SurvivorCharacter_Invalid) {
		return Plugin_Stop;
	}
	
	if (currentSequence[survivor] == 0) {
		#if DEBUG
		PrintToChatAll("[Getup] %N is getting up...", client);
		#endif
		
		currentSequence[survivor] = GetEntProp(client, Prop_Send, "m_nSequence");
		pendingGetups[survivor]++;
		return Plugin_Continue;
	} else if (interrupt[survivor]) {
		#if DEBUG
		PrintToChatAll("[Getup] %N's getup was interrupted!", client);
		#endif
		
		interrupt[survivor] = false;
		// currentSequence[survivor] = 0;
		return Plugin_Stop;
	}

	if (currentSequence[survivor] == GetEntProp(client, Prop_Send, "m_nSequence")) {
		return Plugin_Continue;
	} else if (playerState[survivor] == eTANK_PUNCH_FIX) {
		#if DEBUG
		PrintToChatAll("[Getup] Giving %N an extra getup...", client);
		#endif
		
		if (longerTankPunchGetup.BoolValue) {
			L4D2Direct_DoAnimationEvent(client, ANIM_SHOVED_BY_TEAMMATE);
			playerState[survivor] = eCHARGER_GETUP;
		} else {
			L4D2Direct_DoAnimationEvent(client, ANIM_TANK_PUNCH_GETUP); // 96 is the tank punch getup.
			playerState[survivor] = eTANK_PUNCH_GETUP;
		}
		
		currentSequence[survivor] = 0;
		_TankLandTimer(client);
		return Plugin_Stop;
	} else {
		#if DEBUG
		PrintToChatAll("[Getup] %N finished getting up.", client);
		#endif
		
		playerState[survivor] = eUPRIGHT;
		pendingGetups[survivor]--;
		// After a player finishes getting up, cancel any remaining getups.
		_CancelGetup(client);
		return Plugin_Stop;
	}
}

// Gets players out of pending animations, i.e. sets their current frame in the animation to 1000.
void _CancelGetup(int client)
{
	CreateTimer(0.04, CancelGetup, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action CancelGetup(Handle hTimer, any client)
{
	int survivor = IdentifySurvivor(client);
	if (survivor == SurvivorCharacter_Invalid) {
		return Plugin_Stop;
	}
	
	if (pendingGetups[survivor] <= 0) {
		pendingGetups[survivor] = 0;
		currentSequence[survivor] = 0;
		return Plugin_Stop;
	}
	
	#if DEBUG
	LogMessage("[Getup] Canceled extra getup for player %d.", survivor);
	#endif
	
	pendingGetups[survivor]--;
	SetEntPropFloat(client, Prop_Send, "m_flCycle", 1000.0); // Jumps to frame 1000 in the animation, effectively skipping it.
	return Plugin_Continue;
}

// If the player is in any of the getup states.
bool isGettingUp(int survivor)
{
	switch (playerState[survivor]) {
		case (eHUNTER_GETUP): {
			return true;
		}
		case (eCHARGER_GETUP): {
			return true;
		}
		case (eMULTI_CHARGED): {
			return true;
		}
		case (eTANK_PUNCH_GETUP): {
			return true;
		}
		case (eTANK_ROCK_GETUP): {
			return true;
		}
	}
	return false;
}
