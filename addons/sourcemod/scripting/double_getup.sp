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

#include <sourcemod>
#include <sdkhooks>
#define L4D2UTIL_STOCKS_ONLY
#include <l4d2util> // Needed for IdentifySurvivor calls. I use survivor indices rather than client indices in case someone leaves while incapped (with a pending getup).
#undef L4D2UTIL_STOCKS_ONLY
#include <left4dhooks> // Needed for forcing players to have a getup animation.

public Plugin:myinfo =
{
    name = "L4D2 Get-Up Fix",
    author = "Darkid, Jacob",
    description = "Fixes the problem when, after completing a getup animation, you have another one.",
    version = "3.7",
    url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
}

new bool:lateLoad;
new Handle:rockPunchFix;
new Handle:longerTankPunchGetup;
new const bool:DEBUG = false;

enum PlayerState {
    UPRIGHT = 0,
    INCAPPED,
    SMOKED,
    JOCKEYED,
    HUNTER_GETUP,
    INSTACHARGED, // 5
    CHARGED,
    CHARGER_GETUP,
    MULTI_CHARGED,
    TANK_ROCK_GETUP,
    TANK_PUNCH_FLY, // 10
    TANK_PUNCH_GETUP,
    TANK_PUNCH_FIX,
    TANK_PUNCH_JOCKEY_FIX,
}

new pendingGetups[8] = 0; // This is used to track the number of pending getups. The collective opinion is that you should have at most 1.
new interrupt[8] = false; // If the player was getting up, and that getup is interrupted. This alows us to break out of the GetupTimer loop.
new currentSequence[8] = 0; // Kept to track when a player changes sequences, i.e. changes animations.
new PlayerState:playerState[8] = PlayerState:UPRIGHT; // Since there are multiple sequences for each animation, this acts as a simpler way to track a player's state.

// Coach, Nick, Rochelle, Ellis, Louis, Zoey, Bill, Francis
new tankFlyAnim[8] = {628, 628, 636, 633, 536, 545, 536, 539};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    lateLoad=late;
    return APLRes_Success;
}

public OnPluginStart() {
    rockPunchFix = CreateConVar("rock_punch_fix", "1", "When a tank punches someone who is getting up from a rock, cause them to have an extra getup.", FCVAR_NONE);
    longerTankPunchGetup = CreateConVar("longer_tank_punch_getup", "0", "When a tank punches someone give them a slightly longer getup.", FCVAR_NONE, false, 0.0, false, 0.0);

    HookEvent("round_start", round_start);
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
    InitSurvivorModelTrie(); // Not necessary, but speeds up IdentifySurvivor() calls.

    if(lateLoad) {
        for (new client=1; client <= MaxClients; client++) {
            if(!IsClientInGame(client)) continue;
            OnClientPostAdminCheck(client);
        }
    }
}

// Used to check for tank rocks and tank punches.
public OnClientPostAdminCheck(client) {
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

// If the player is in any of the getup states.
public bool:isGettingUp(any:survivor) {
    switch (playerState[survivor]) {
    case (PlayerState:HUNTER_GETUP):
        return true;
    case (PlayerState:CHARGER_GETUP):
        return true;
    case (PlayerState:MULTI_CHARGED):
        return true;
    case (PlayerState:TANK_PUNCH_GETUP):
        return true;
    case (PlayerState:TANK_ROCK_GETUP):
        return true;
    }
    return false;
}

public round_start(Handle:event, const String:name[], bool:dontBroadcast) {
    for (new survivor=0; survivor<8; survivor++) {
        playerState[survivor] = PlayerState:UPRIGHT;
    }
}

// If a player is smoked while getting up from a hunter, the getup is interrupted.
public smoker_land(Handle:event, const String:name[], bool:dontBroadcast) {
    new client = GetClientOfUserId(GetEventInt(event, "victim"));
    new SurvivorCharacter:survivor = IdentifySurvivor(client);
    if (survivor == SC_NONE) return;
    if (playerState[survivor] == PlayerState:HUNTER_GETUP) {
        interrupt[survivor] = true;
    }
}

public jockey_land(Handle:event, const String:name[], bool:dontBroadcast) {
    new client = GetClientOfUserId(GetEventInt(event, "victim"));
    new SurvivorCharacter:survivor = IdentifySurvivor(client);
    if (survivor == SC_NONE) return;
    playerState[survivor] = PlayerState:JOCKEYED;
}

public jockey_clear(Handle:event, const String:name[], bool:dontBroadcast) {
    new client = GetClientOfUserId(GetEventInt(event, "victim"));
    new SurvivorCharacter:survivor = IdentifySurvivor(client);
    if (survivor == SC_NONE) return;
    if (playerState[survivor] == PlayerState:JOCKEYED) {
        playerState[survivor] = PlayerState:UPRIGHT;
    }
}

// If a player is cleared from a smoker, they should not have a getup.
public smoker_clear(Handle:event, const String:name[], bool:dontBroadcast) {
    new client = GetClientOfUserId(GetEventInt(event, "victim"));
    new SurvivorCharacter:survivor = IdentifySurvivor(client);
    if (survivor == SC_NONE) return;
    if (playerState[survivor] == PlayerState:INCAPPED) return;
    playerState[survivor] = PlayerState:UPRIGHT;
    _CancelGetup(client);
}

// If a player is cleared from a hunter, they should have 1 getup.
public hunter_clear(Handle:event, const String:name[], bool:dontBroadcast) {
    new client = GetClientOfUserId(GetEventInt(event, "victim"));
    new SurvivorCharacter:survivor = IdentifySurvivor(client);
    if (survivor == SC_NONE) return;
    if (playerState[survivor] == PlayerState:INCAPPED) return;
    // If someone gets cleared WHILE they are otherwise getting up, they double-getup.
    if (isGettingUp(survivor)) {
        pendingGetups[survivor]++;
        return;
    }
    playerState[survivor] = PlayerState:HUNTER_GETUP;
    _GetupTimer(client);
}

// If a player is impacted during a charged, they should have 1 getup.
public multi_charge(Handle:event, const String:name[], bool:dontBroadcast) {
    new SurvivorCharacter:survivor = IdentifySurvivor(GetClientOfUserId(GetEventInt(event, "victim")));
    if (survivor == SC_NONE) return;
    if (playerState[survivor] == PlayerState:INCAPPED) return;
    playerState[survivor] = PlayerState:MULTI_CHARGED;
}

// If a player is cleared from a charger, they should have 1 getup.
public charger_land_instant(Handle:event, const String:name[], bool:dontBroadcast) {
    new SurvivorCharacter:survivor = IdentifySurvivor(GetClientOfUserId(GetEventInt(event, "victim")));
    if (survivor == SC_NONE) return;
    // If the player is incapped when the charger lands, they will getup after being revived.
    if (playerState[survivor] == PlayerState:INCAPPED) {
        pendingGetups[survivor]++;
    }
    playerState[survivor] = PlayerState:INSTACHARGED;
}

// This event defines when a player transitions from being insta-charged to being pummeled.
public charger_land(Handle:event, const String:name[], bool:dontBroadcast) {
    new SurvivorCharacter:survivor = IdentifySurvivor(GetClientOfUserId(GetEventInt(event, "victim")));
    if (survivor == SC_NONE) return;
    if (playerState[survivor] == PlayerState:INCAPPED) return;
    playerState[survivor] = PlayerState:CHARGED;
}

// If a player is cleared from a charger, they should have 1 getup.
public charger_clear(Handle:event, const String:name[], bool:dontBroadcast) {
    new client = GetClientOfUserId(GetEventInt(event, "victim"));
    new SurvivorCharacter:survivor = IdentifySurvivor(client);
    if (survivor == SC_NONE) return;
    if (playerState[survivor] == PlayerState:INCAPPED) return;
    playerState[survivor] = PlayerState:CHARGER_GETUP;
    _GetupTimer(client);
}

// If a player is incapped, mark that down. This will interrupt their animations, if they have any.
public player_incap(Handle:event, const String:name[], bool:dontBroadcast) {
    new SurvivorCharacter:survivor = IdentifySurvivor(GetClientOfUserId(GetEventInt(event, "userid")));
    if (survivor == SC_NONE) return;
    // If the player is incapped when the charger lands, they will getup after being revived.
    if (playerState[survivor] == PlayerState:INSTACHARGED) {
        pendingGetups[survivor]++;
    }
    playerState[survivor] = PlayerState:INCAPPED;
}

// When a player is picked up, they should have 0 getups.
public player_revive(Handle:event, const String:name[], bool:dontBroadcast) {
    new client = GetClientOfUserId(GetEventInt(event, "subject"));
    new SurvivorCharacter:survivor = IdentifySurvivor(client);
    if (survivor == SC_NONE) return;
    playerState[survivor] = PlayerState:UPRIGHT;
    _CancelGetup(client);
}

// A catch-all to handle damage that is not associated with an event. I use this instead of player_hurt because it ignores godframes.
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype) {
    new SurvivorCharacter:survivor = IdentifySurvivor(victim);
    if (survivor == SC_NONE) return;
    decl String:weapon[32];
    GetEdictClassname(inflictor, weapon, sizeof(weapon));
    if (strcmp(weapon, "weapon_tank_claw") == 0) {
        if (playerState[survivor] == PlayerState:CHARGER_GETUP) {
            interrupt[survivor] = true;
        } else if (playerState[survivor] == PlayerState:MULTI_CHARGED) {
            pendingGetups[survivor]++;
        }

        if (playerState[survivor] == PlayerState:TANK_ROCK_GETUP && GetConVarBool(rockPunchFix)) {
            playerState[survivor] = PlayerState:TANK_PUNCH_FIX;
        } else if (playerState[survivor] == PlayerState:JOCKEYED) {
            playerState[survivor] = PlayerState:TANK_PUNCH_JOCKEY_FIX;
            _TankLandTimer(victim);
        } else {
            playerState[survivor] = PlayerState:TANK_PUNCH_FLY;
            // Watches and waits for the survivor to enter their getup animation. It is possible to skip the fly animation, so this can't be tracked by state-based logic.
            _TankLandTimer(victim);
        }
    } else if (strcmp(weapon, "tank_rock") == 0) {
        if (playerState[survivor] == PlayerState:CHARGER_GETUP) {
            interrupt[survivor] = true;
        } else if (playerState[survivor] == PlayerState:MULTI_CHARGED) {
            pendingGetups[survivor]++;
        }
        playerState[survivor] = PlayerState:TANK_ROCK_GETUP;
        _GetupTimer(victim);
    }
    return;
}

// Detects when a player lands from a tank punch.
_TankLandTimer(client) {
    CreateTimer(0.04, TankLandTimer, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}
public Action:TankLandTimer(Handle:timer, any:client) {
    new SurvivorCharacter:survivor = IdentifySurvivor(client);
    if (survivor == SC_NONE) return Plugin_Stop;
    // I consider players to have "landed" only once they stop being in the fly anim or the landing anim (fly + 1).
    if (GetEntProp(client, Prop_Send, "m_nSequence") == tankFlyAnim[survivor] || GetEntProp(client, Prop_Send, "m_nSequence") == tankFlyAnim[survivor] + 1) {
        return Plugin_Continue;
    }
    if (playerState[survivor] == PlayerState:TANK_PUNCH_JOCKEY_FIX) {
        // When punched out of a jockey, the player goes into land (fly+1) for an arbitrary number of frames, then enters land (fly+2) for an arbitrary number of frames. Once they're done "landing" we give them the getup they deserve.
        if (GetEntProp(client, Prop_Send, "m_nSequence") == tankFlyAnim[survivor]+2) {
            return Plugin_Continue;
        }
        if (DEBUG) PrintToChatAll("[Getup] Giving %N an extra getup...", client);
        if (GetConVarBool(longerTankPunchGetup))
        {
            L4D2Direct_DoAnimationEvent(client, 57);
        }
        else
        {
            L4D2Direct_DoAnimationEvent(client, 96); // 96 is the tank punch getup.
        }
    }
    if (playerState[survivor] == PlayerState:TANK_PUNCH_FLY) {
        playerState[survivor] = PlayerState:TANK_PUNCH_GETUP;
    }
    if (GetConVarBool(longerTankPunchGetup))
    {
        L4D2Direct_DoAnimationEvent(client, 57);
    }
    else
    {
        L4D2Direct_DoAnimationEvent(client, 96); // 96 is the tank punch getup.
    }
    _GetupTimer(client);
    return Plugin_Stop;
}

// Detects when a player finishes getting up, i.e. their sequence changes.
_GetupTimer(client) {
    CreateTimer(0.04, GetupTimer, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}
public Action:GetupTimer(Handle:timer, any:client) {
    new SurvivorCharacter:survivor = IdentifySurvivor(client);
    if (survivor == SC_NONE) return Plugin_Stop;
    if (currentSequence[survivor] == 0) {
        if (DEBUG) PrintToChatAll("[Getup] %N is getting up...", client);
        currentSequence[survivor] = GetEntProp(client, Prop_Send, "m_nSequence");
        pendingGetups[survivor]++;
        return Plugin_Continue;
    } else if (interrupt[survivor]) {
        if (DEBUG) PrintToChatAll("[Getup] %N's getup was interrupted!", client);
        interrupt[survivor] = false;
        // currentSequence[survivor] = 0;
        return Plugin_Stop;
    }

    if (currentSequence[survivor] == GetEntProp(client, Prop_Send, "m_nSequence")) {
        return Plugin_Continue;
    } else if (playerState[survivor] == PlayerState:TANK_PUNCH_FIX) {
        if (DEBUG) PrintToChatAll("[Getup] Giving %N an extra getup...", client);
        if (GetConVarBool(longerTankPunchGetup))
        {
            L4D2Direct_DoAnimationEvent(client, 57);
            playerState[survivor] = PlayerState:CHARGER_GETUP;
        }
        else
        {
            L4D2Direct_DoAnimationEvent(client, 96); // 96 is the tank punch getup.
            playerState[survivor] = PlayerState:TANK_PUNCH_GETUP;
        }
        currentSequence[survivor] = 0;
        _TankLandTimer(client);
        return Plugin_Stop;
    } else {
        if (DEBUG) PrintToChatAll("[Getup] %N finished getting up.", client);
        playerState[survivor] = PlayerState:UPRIGHT;
        pendingGetups[survivor]--;
        // After a player finishes getting up, cancel any remaining getups.
        _CancelGetup(client);
        return Plugin_Stop;
    }
}

// Gets players out of pending animations, i.e. sets their current frame in the animation to 1000.
_CancelGetup(client) {
    CreateTimer(0.04, CancelGetup, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}
public Action:CancelGetup(Handle:timer, any:client) {
    new SurvivorCharacter:survivor = IdentifySurvivor(client);
    if (survivor == SC_NONE) return Plugin_Stop;
    if (pendingGetups[survivor] <= 0) {
        pendingGetups[survivor] = 0;
        currentSequence[survivor] = 0;
        return Plugin_Stop;
    }
    if (DEBUG) LogMessage("[Getup] Canceled extra getup for player %d.", survivor);
    pendingGetups[survivor]--;
    SetEntPropFloat(client, Prop_Send, "m_flCycle", 1000.0); // Jumps to frame 1000 in the animation, effectively skipping it.
    return Plugin_Continue;
}