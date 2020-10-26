#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <l4d2util>

#define DEBUG_MODE false

/*

    Changelog
    =========
        0.1.1
            - added PBONUS_RequestFinalUpdate() forward.
            - replaced netprop round tracking with bool. (odd behaviour fix?)
            
        0.0.1 - 0.0.9
            - added library registration ('penaltybonus')
            - simplified round-end: L4D2_OnEndVersusRound instead of a bunch of hooked events.
            - added native to change defib penalty (since it can vary in Random!)
            - where possible, neatly divides total bonus through bonuses/penalties,
              to improve end-of-round overview. Only works for single-value bonus/penalty
              setups.
            - fixed double minus signs appearing on reports for negative changes.
            - fixed incorrect reporting on round end (twice the 2nd team's score).
            - added enable cvar.
            - avoided messing with bonus unless it's really necessary.
            - fixed for config-set custom defib penalty values.
            - optional report of changes to bonus as they happen.
            - removed sm_bonus command effects when display mode is off.
            - fixed report error.
            - added sm_bonus command to display bonus.
            - optional simple tank/witch kill bonus (off by default).
            - optional bonus reporting on round end.
            - allows setting bonus through natives.
            - bonus calculation, taking defib use into account.
*/


public Plugin:myinfo = 
{
    name = "Penalty bonus system",
    author = "Tabun",
    description = "Allows other plugins to set bonuses for a round that will be given even if the saferoom is not reached.",
    version = "0.1.1",
    url = ""
}


new     Handle:         g_hForwardRequestUpdate                             = INVALID_HANDLE;       // request final update before round ends

new     Handle:         g_hCvarEnabled                                      = INVALID_HANDLE;
new     Handle:         g_hCvarDoDisplay                                    = INVALID_HANDLE;
new     Handle:         g_hCvarReportChange                                 = INVALID_HANDLE;
new     Handle:         g_hCvarBonusTank                                    = INVALID_HANDLE;
new     Handle:         g_hCvarBonusWitch                                   = INVALID_HANDLE;

new     bool:           g_bSecondHalf                                       = false;
new     bool:           g_bFirstMapStartDone                                = false;                // so we can set the config-set defib penalty

new     Handle:         g_hCvarDefibPenalty                                 = INVALID_HANDLE;
new                     g_iOriginalPenalty                                  = 25;                   // original defib penalty
new     bool:           g_bSetSameChange                                    = true;                 // whether we've already determined that there is a same-change or not (true = it's still 'the same' if not 0)
new                     g_iSameChange                                       = 0;                    // if all changes to the bonus are by the same amount, this is it (-1 = not set)

new     bool:           g_bRoundOver[2]                                     = {false,...};          // tank/witch deaths don't count after this true
new                     g_iDefibsUsed[2]                                    = {0,...};              // defibs used this round
new                     g_iBonus[2]                                         = {0,...};              // bonus to be added when this round ends




// Natives
// -------
 
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    // this forward requests all plugins to return their final modifications
    //  the cell parameter will be updated for each plugin responding to this forward
    //  so the last return value is the total of the final update modifications
    g_hForwardRequestUpdate = CreateGlobalForward("PBONUS_RequestFinalUpdate", ET_Single, Param_CellByRef );
    
    CreateNative("PBONUS_GetRoundBonus", Native_GetRoundBonus);
    CreateNative("PBONUS_ResetRoundBonus", Native_ResetRoundBonus);
    CreateNative("PBONUS_SetRoundBonus", Native_SetRoundBonus);
    CreateNative("PBONUS_AddRoundBonus", Native_AddRoundBonus);
    CreateNative("PBONUS_GetDefibsUsed", Native_GetDefibsUsed);
    CreateNative("PBONUS_SetDefibPenalty", Native_SetDefibPenalty);
    
    RegPluginLibrary("penaltybonus");
    
    return APLRes_Success;
}

public Native_GetRoundBonus(Handle:plugin, numParams)
{
    return _: g_iBonus[RoundNum()];
}

public Native_ResetRoundBonus(Handle:plugin, numParams)
{
    g_iBonus[RoundNum()] = 0;
    
    g_iSameChange = 0;
    g_bSetSameChange = true;
    
}

public Native_SetRoundBonus(Handle:plugin, numParams)
{
    new bonus = GetNativeCell(1);
    
    if (g_bSetSameChange) {
        g_iSameChange = g_iBonus[RoundNum()] - bonus;
    } else if (g_iSameChange != g_iBonus[RoundNum()] - bonus) {
        g_iSameChange = 0;
        g_bSetSameChange = false;
    }
    
    g_iBonus[RoundNum()] = bonus;
    
    if (GetConVarBool(g_hCvarReportChange)) { ReportChange(0, -1, true); }
}

public Native_AddRoundBonus(Handle:plugin, numParams)
{
    new bool: bNoReport = false;
    new bonus = GetNativeCell(1);
    g_iBonus[RoundNum()] += bonus;
    
    if (g_bSetSameChange) {
        g_iSameChange = bonus;
    } else if (g_iSameChange != bonus) {
        g_iSameChange = 0;
        g_bSetSameChange = false;
    }
    
    if ( numParams > 1 )
    {
        bNoReport = bool: GetNativeCell(2);
    }
    
    if ( !bNoReport )
    {
        if (GetConVarBool(g_hCvarReportChange)) { ReportChange(bonus); }
    }
}

public Native_GetDefibsUsed(Handle:plugin, numParams)
{
    return _: g_iDefibsUsed[RoundNum()];
}

public Native_SetDefibPenalty(Handle:plugin, numParams)
{
    new penalty = GetNativeCell(1);
    
    g_iOriginalPenalty = penalty;
}


// Init and round handling
// -----------------------

public OnPluginStart()
{
    // store original penalty
    g_hCvarDefibPenalty = FindConVar("vs_defib_penalty");

    // cvars
    g_hCvarEnabled = CreateConVar(      "sm_pbonus_enable",         "1",    "Whether the penalty-bonus system is enabled.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvarDoDisplay = CreateConVar(    "sm_pbonus_display",        "1",    "Whether to display bonus at round-end and with !bonus.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvarReportChange = CreateConVar( "sm_pbonus_reportchanges",  "1",    "Whether to report changes when they are made to the current bonus.", FCVAR_NONE, true, 0.0, true, 1.0);
    g_hCvarBonusTank = CreateConVar(    "sm_pbonus_tank",           "0",    "Give this much bonus when a tank is killed (0 to disable entirely).", FCVAR_NONE, true, 0.0);
    g_hCvarBonusWitch = CreateConVar(   "sm_pbonus_witch",          "0",    "Give this much bonus when a witch is killed (0 to disable entirely).", FCVAR_NONE, true, 0.0);
    
    // hook events
    HookEvent("defibrillator_used",     Event_DefibUsed,            EventHookMode_PostNoCopy);
    HookEvent("witch_killed",           Event_WitchKilled,          EventHookMode_PostNoCopy);
    HookEvent("player_death",           Event_PlayerDeath,          EventHookMode_Post);
 
    // Chat cleaning
    AddCommandListener(Command_Say, "say");
    AddCommandListener(Command_Say, "say_team");

    RegConsoleCmd("sm_bonus", Cmd_Bonus, "Prints the current extra bonus(es) for this round.");
}

public OnPluginEnd()
{
    SetConVarInt(g_hCvarDefibPenalty, g_iOriginalPenalty);
}

public OnMapStart()
{
    // save original defib penalty setting
    if ( !g_bFirstMapStartDone )
    {
        g_iOriginalPenalty = GetConVarInt(g_hCvarDefibPenalty);
        g_bFirstMapStartDone = true;
    }
    
    SetConVarInt(g_hCvarDefibPenalty, g_iOriginalPenalty);
    
    g_bSecondHalf = false;
    g_bRoundOver[0] = false;
    g_bRoundOver[1] = false;
    g_iDefibsUsed[0] = 0;
    g_iDefibsUsed[1] = 0;
}

public OnMapEnd()
{
    g_bSecondHalf = false;
}

public OnRoundStart()
{
    // reset
    SetConVarInt(g_hCvarDefibPenalty, g_iOriginalPenalty);
    
    g_iBonus[RoundNum()] = 0;
    g_iSameChange = -1;
}

public OnRoundEnd()
{
    g_bRoundOver[RoundNum()] = true;
    g_bSecondHalf = true;
    
    if (GetConVarBool(g_hCvarEnabled) && GetConVarBool(g_hCvarDoDisplay))
    {
        DisplayBonus();
    }
}

public Action: Cmd_Bonus(client, args)
{
    if (!GetConVarBool(g_hCvarEnabled) || !GetConVarBool(g_hCvarDoDisplay)) { return Plugin_Continue; }
    
    DisplayBonus(client);
    return Plugin_Handled;
}

public Action:Command_Say(client, const String:command[], args)
{
    if (!GetConVarBool(g_hCvarEnabled) || !GetConVarBool(g_hCvarDoDisplay)) { return Plugin_Continue; }
    
    if (IsChatTrigger())
    {
        decl String:sMessage[MAX_NAME_LENGTH];
        GetCmdArg(1, sMessage, sizeof(sMessage));

        if (StrEqual(sMessage, "!bonus")) return Plugin_Handled;
        else if (StrEqual (sMessage, "!sm_bonus")) return Plugin_Handled;
    }

    return Plugin_Continue;
}


// Tank and Witch tracking
// -----------------------

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (!GetConVarBool(g_hCvarEnabled)) { return; }
    
    new client = GetClientOfUserId(GetEventInt(event, "userid"));

    if (client && IsTank(client))
    {
        TankKilled();
    }
}

public TankKilled()
{
    if ( GetConVarInt(g_hCvarBonusTank) == 0 || g_bRoundOver[RoundNum()] ) { return; }
    
    g_iBonus[RoundNum()] += GetConVarInt(g_hCvarBonusTank);
    
    if (g_bSetSameChange) {
        g_iSameChange = GetConVarInt(g_hCvarBonusTank);
    } else if (g_iSameChange != GetConVarInt(g_hCvarBonusTank)) {
        g_iSameChange = 0;
        g_bSetSameChange = false;
    }
    
    ReportChange( GetConVarInt(g_hCvarBonusTank) );
}

public Action: Event_WitchKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (!GetConVarBool(g_hCvarEnabled)) { return Plugin_Continue; }
    if ( GetConVarInt(g_hCvarBonusWitch) == 0 || g_bRoundOver[RoundNum()] ) { return Plugin_Continue; }
    
    g_iBonus[RoundNum()] += GetConVarInt(g_hCvarBonusWitch);
    
    if (g_bSetSameChange) {
        g_iSameChange = GetConVarInt(g_hCvarBonusWitch);
    } else if (g_iSameChange != GetConVarInt(g_hCvarBonusWitch)) {
        g_iSameChange = 0;
        g_bSetSameChange = false;
    }
    
    ReportChange( GetConVarInt(g_hCvarBonusWitch) );
    
    return Plugin_Continue;
}


// Special Check (test)
// --------------------

public Action:L4D2_OnEndVersusModeRound(bool:countSurvivors)
{
    new updateScore = 0, updateResult = 0;
    
    // get update before setting the bonus
    Call_StartForward(g_hForwardRequestUpdate);
    Call_PushCellRef( updateScore );
    Call_Finish(_:updateResult);
    
    // add the update to the round's bonus
    g_iBonus[RoundNum()] += updateResult;
    g_iSameChange = 0;
    g_bSetSameChange = false;
    
    SetBonus();
}


// Bonus
// -----

public SetBonus()
{
    // only change anything if there's a bonus to set at all
    if (g_iBonus[RoundNum()] == 0) {
        SetConVarInt( g_hCvarDefibPenalty, g_iOriginalPenalty );
        return;
    }
    
    // set the bonus as though only 1 defib was used: so 1 * CalculateBonus
    new bonus = CalculateBonus();
    
    // set the bonus to a neatly divisible value if possible
    new fakeDefibs = 1;
    if ( g_bSetSameChange && g_iSameChange != 0 && !g_iDefibsUsed[RoundNum()] )
    {
        fakeDefibs = g_iBonus[RoundNum()] / g_iSameChange;
        bonus = 0 - g_iSameChange;  // flip sign, so bonus = - penalty
        
        // only do it this way if fakedefibs stays small enough:
        if (fakeDefibs > 15)
        {
            fakeDefibs = 1;
            bonus = 0 - g_iBonus[RoundNum()];
        }
    }
    
    // set bonus(penalty) cvar
    SetConVarInt( g_hCvarDefibPenalty, bonus );
    
    // only set the amount of defibs used to 1 if there is a bonus to set
    GameRules_SetProp("m_iVersusDefibsUsed", (bonus != 0) ? fakeDefibs : 0, 4, GameRules_GetProp("m_bAreTeamsFlipped", 4, 0) );
}

public CalculateBonus()
{
    // negative = actual bonus, otherwise it is a penalty
    return ( g_iOriginalPenalty * g_iDefibsUsed[RoundNum()] ) - g_iBonus[RoundNum()];
}

stock DisplayBonus(client=-1)
{
    new String:msgPartHdr[48];
    new String:msgPartBon[48];
    
    for (new round = 0; round <= RoundNum(); round++)
    {
        if (g_bRoundOver[round]) {
            Format(msgPartHdr, sizeof(msgPartHdr), "Round \x05%i\x01 extra bonus", round+1);
        } else {
            Format(msgPartHdr, sizeof(msgPartHdr), "Current extra bonus");
        }
        
        Format(msgPartBon, sizeof(msgPartBon), "\x04%4d\x01", g_iBonus[round]);

        if (g_iDefibsUsed[round]) {
            Format(msgPartBon, sizeof(msgPartBon), "%s (- \x04%d\x01 defib penalty)", msgPartBon, g_iOriginalPenalty * g_iDefibsUsed[round] );
        }
        
        if (client == -1) {
            PrintToChatAll("\x01%s: %s", msgPartHdr, msgPartBon);
        } else if (client) {
            PrintToChat(client, "\x01%s: %s", msgPartHdr, msgPartBon);
        }
    }
}

stock ReportChange(bonusChange, client=-1, absoluteSet=false)
{
    if (bonusChange == 0 && !absoluteSet) { return; }
    
    // report bonus to all
    new String:msgPartBon[48];
    
    if (absoluteSet) {  // set to a specific value
        Format(msgPartBon, sizeof(msgPartBon), "Extra bonus set to: \x04%i\x01", g_iBonus[RoundNum()]);
    } else {
        Format(msgPartBon, sizeof(msgPartBon), "Extra bonus change: %s\x04%i\x01",
                (bonusChange > 0) ? "\x04+\x01" : "\x03-\x01",
                RoundFloat( FloatAbs( float(bonusChange) ) )
            );
    }
    
    if (client == -1) {
        PrintToChatAll("\x01%s", msgPartBon);
    } else if (client) {
        PrintToChat(client, "\x01%s", msgPartBon);
    }
}


// Defib tracking
// --------------

public Event_DefibUsed(Handle:event, const String:name[], bool:dontBroadcast)
{
    g_iDefibsUsed[RoundNum()]++;
}


// Support functions
// -----------------

RoundNum()
{
    return ( g_bSecondHalf ) ? 1 : 0;
    //return GameRules_GetProp("m_bInSecondHalfOfRound");
}

/*
public PrintDebug(const String:Message[], any:...)
{
    #if DEBUG_MODE
        decl String:DebugBuff[256];
        VFormat(DebugBuff, sizeof(DebugBuff), Message, 2);
        LogMessage(DebugBuff);
        //PrintToServer(DebugBuff);
        //PrintToChatAll(DebugBuff);
    #endif
}
*/