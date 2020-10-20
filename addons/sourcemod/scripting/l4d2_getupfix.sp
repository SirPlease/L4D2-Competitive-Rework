#pragma semicolon 1

#define L4D2UTIL_STOCKS_ONLY 1

#include <sourcemod>
#include <sdktools>
#include <l4d2util>
#include <l4d2_direct>

public Plugin:myinfo = 
{
    name = "L4D2 Get-Up Fix",
    author = "Blade, ProdigySim, DieTeetasse, Stabby, Jahze",
    description = "Double/no/self-clear get-up fix.",
    version = "1.7.2",
    url = "http://bitbucket.org/ProdigySim/misc-sourcemod-plugins/"
}

// frames: 64, fps: 30, length: 2.133
#define ANIM_HUNTER_LENGTH 2.2
// frames: 85, fps 30, length: 2.833
#define ANIM_CHARGER_STANDARD_LENGTH 2.9
// frames 116 fps 30 = 3.867
#define ANIM_CHARGER_SLAMMED_WALL_LENGTH 3.9
// frames 119 fps 30 = 3.967
#define ANIM_CHARGER_SLAMMED_GROUND_LENGTH 4.0

#define ANIM_EVENT_CHARGER_GETUP 78

#define GETUP_TIMER_INTERVAL 0.5

#define INDEX_HUNTER            0    //index for getup anim on hunter clears
#define INDEX_CHARGER            1    //index for getup anim on post-slam clears
#define INDEX_CHARGER_WALL        2    //index for getup anim on mid-slam clears against walls
#define INDEX_CHARGER_GROUND    3    //index for getup anim on mid-slam clears against ground (after long charges)

new const getUpAnimations[SurvivorCharacter][4] = {    
    // 0: Coach, 1: Nick, 2: Rochelle, 3: Ellis
    {621, 656, 660, 661}, {620, 667, 671, 672}, {629, 674, 678, 679}, {625, 671, 675, 676},
    // 4: Louis, 5: Zoey, 6: Bill, 7: Francis
    {528, 759, 763, 764}, {537, 819, 823, 824}, {528, 759, 763, 764}, {531, 762, 766, 767}
};

//incapped animations: 0 = single-pistol, 1 = dual pistols
new const incapAnimations[SurvivorCharacter][2] = {
    // 0: Coach, 1: Nick, 2: Rochelle, 3: Ellis
    {613, 614}, {612, 613}, {621, 622}, {617, 618},
    // 4: Louis, 5: Zoey, 6: Bill, 7: Francis
    {520, 521}, {525, 526}, {520, 521}, {523, 524}
};

new PropOff_nSequence;

public OnPluginStart() {
    HookEvent("pounce_end", Event_PounceOrPummel);
    HookEvent("charger_pummel_end", Event_PounceOrPummel);
    HookEvent("charger_killed", ChargerKilled);
    
    PropOff_nSequence = FindSendPropInfo("CTerrorPlayer", "m_nSequence");
}

public Event_PounceOrPummel(Handle:event, const String:name[], bool:dontBroadcast) {
    new client = GetClientOfUserId(GetEventInt(event, "victim"));
    if (client == 0) return;
    if (!IsClientInGame(client)) return;
    
    CreateTimer(0.1, Timer_ProcessClient, client);
}

public Action:Timer_ProcessClient(Handle:timer, any:client) {
    ProcessClient(client);
}

ProcessClient(client) {
    new SurvivorCharacter:charIndex = IdentifySurvivor(client);    
    if (charIndex == SC_NONE) return;
    
    new sequence = GetEntData(client, PropOff_nSequence);
    
    // charger or hunter get up animation?
    if (sequence != getUpAnimations[charIndex][INDEX_HUNTER] && sequence != getUpAnimations[charIndex][INDEX_CHARGER]
    &&  sequence != getUpAnimations[charIndex][INDEX_CHARGER_GROUND] && sequence != getUpAnimations[charIndex][INDEX_CHARGER_WALL])
    {
        if (sequence != incapAnimations[charIndex][0] && sequence != incapAnimations[charIndex][1])
        {
            L4D2Direct_DoAnimationEvent(client, ANIM_EVENT_CHARGER_GETUP);
        }
        return;
    }
    
    // create stack with client and sequence
    new Handle:tempStack = CreateStack(3);
    PushStackCell(tempStack, client);
    PushStackCell(tempStack, sequence);
    
    if (sequence == getUpAnimations[charIndex][INDEX_HUNTER]) {
        CreateTimer(ANIM_HUNTER_LENGTH, Timer_CheckClient, tempStack);
    }
    else if (sequence == getUpAnimations[charIndex][INDEX_CHARGER]) {
        CreateTimer(ANIM_CHARGER_STANDARD_LENGTH, Timer_CheckClient, tempStack);
    }
    else if (sequence == getUpAnimations[charIndex][INDEX_CHARGER_WALL]) {
        CreateTimer(ANIM_CHARGER_SLAMMED_WALL_LENGTH - 2.5*GetEntPropFloat(client, Prop_Send, "m_flCycle"), Timer_CheckClient, tempStack);
    }
    else {
        CreateTimer(ANIM_CHARGER_SLAMMED_GROUND_LENGTH - 2.5*GetEntPropFloat(client, Prop_Send, "m_flCycle"), Timer_CheckClient, tempStack);
    }
}

public Action:Timer_CheckClient(Handle:timer, any:tempStack) {
    decl client, oldSequence, Float:duration;
    PopStackCell(tempStack, oldSequence);
    PopStackCell(tempStack, client);
    CloseHandle(tempStack);
    
    new SurvivorCharacter:charIndex = IdentifySurvivor(client);    
    if (charIndex == SC_NONE) return;
    
    new newSequence = GetEntData(client, PropOff_nSequence);
    
    // not the same animation?
    if (newSequence == oldSequence)
    {
        return;
    }
    
    // charger or hunter get up animation?
    if (newSequence == getUpAnimations[charIndex][INDEX_HUNTER]) {
        duration = ANIM_HUNTER_LENGTH;
	}
    else if (newSequence == getUpAnimations[charIndex][INDEX_CHARGER]) {
        duration = ANIM_CHARGER_STANDARD_LENGTH;
    }
    else if (newSequence == getUpAnimations[charIndex][INDEX_CHARGER_WALL]) {
        duration = ANIM_CHARGER_SLAMMED_WALL_LENGTH;
    }
    else if (newSequence == getUpAnimations[charIndex][INDEX_CHARGER_GROUND]) {
        duration = ANIM_CHARGER_SLAMMED_GROUND_LENGTH;
    }
    else {
        return;
    }
    
    // Apply!
    SetEntPropFloat(client, Prop_Send, "m_flCycle", duration);
}

public Action:ChargerKilled(Handle:event, const String:name[], bool:dontBroadcast) {
    new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    
    if (attacker <= 0 || attacker > MaxClients) {
        return;
    }
    
    CreateTimer(GETUP_TIMER_INTERVAL, GetupTimer, attacker);
}

new bArClientAlreadyChecked[MAXPLAYERS + 1];    //in the rare event of it being a game with multiple chargers and 2+ getting cleared on slam

public Action:ResetAlreadyCheckedBool(Handle:timer, any:client) {
    bArClientAlreadyChecked[client] = false;
}

public Action:GetupTimer(Handle:timer, any:attacker) {
    for (new n = 1; n <= MaxClients; n++) {
        if (IsClientInGame(n) && GetClientTeam(n) == 2 && !bArClientAlreadyChecked[n]) {
            new seq = GetEntProp(n, Prop_Send, "m_nSequence");
            new SurvivorCharacter:character = IdentifySurvivor(n);
            
            if (character == SC_NONE) {
                return;
            }
            
            if (seq == getUpAnimations[character][INDEX_CHARGER_WALL]) {
                if (n == attacker) {
                    SetEntPropFloat(attacker, Prop_Send, "m_flCycle", ANIM_CHARGER_SLAMMED_WALL_LENGTH);                    
                }
                else {
                    bArClientAlreadyChecked[n] = true;
                    CreateTimer(ANIM_CHARGER_SLAMMED_WALL_LENGTH, ResetAlreadyCheckedBool, n);
                    ProcessClient(n);
                }
                
                break;
            }
            else if (seq == getUpAnimations[character][INDEX_CHARGER_GROUND]) {
                if (n == attacker) {
                    SetEntPropFloat(attacker, Prop_Send, "m_flCycle", ANIM_CHARGER_SLAMMED_GROUND_LENGTH);
                }
                else {
                    bArClientAlreadyChecked[n] = true;
                    CreateTimer(ANIM_CHARGER_SLAMMED_GROUND_LENGTH, ResetAlreadyCheckedBool, n);
                    ProcessClient(n);
                }
                
                break;
            }            
        }
    }
}
