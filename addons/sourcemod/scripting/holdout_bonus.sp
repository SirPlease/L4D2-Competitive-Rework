#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>
#include <l4d2_penalty_bonus>
#undef REQUIRE_PLUGIN
#include <readyup>
#define REQUIRE_PLUGIN

#define IS_VALID_CLIENT(%1)     (%1 > 0 && %1 <= MaxClients)
#define IS_SURVIVOR(%1)         (GetClientTeam(%1) == 2)
#define IS_INFECTED(%1)         (GetClientTeam(%1) == 3)
#define IS_VALID_INGAME(%1)     (IS_VALID_CLIENT(%1) && IsClientInGame(%1))
#define IS_VALID_SURVIVOR(%1)   (IS_VALID_INGAME(%1) && IS_SURVIVOR(%1))
#define IS_VALID_INFECTED(%1)   (IS_VALID_INGAME(%1) && IS_INFECTED(%1))
#define IS_SURVIVOR_ALIVE(%1)   (IS_VALID_SURVIVOR(%1) && IsPlayerAlive(%1))
#define IS_INFECTED_ALIVE(%1)   (IS_VALID_INFECTED(%1) && IsPlayerAlive(%1))

#define TEAM_SPECTATOR          1
#define TEAM_SURVIVOR           2
#define TEAM_INFECTED           3

#define TEAM_SIZE               4

#define MAXCHARACTERS           4
#define MAXGAME                 24
#define MAXSTR                  32

#define PMODE_OFF               0
#define PMODE_NODIST            1
#define PMODE_DIST              2

#define REPORT_ONLYEVENT        4


new     Handle: g_hForwardSet           = INVALID_HANDLE;
new     Handle: g_hForwardStart         = INVALID_HANDLE;
new     Handle: g_hForwardEnd           = INVALID_HANDLE;

new     bool:   g_bReadyUpAvailable     = false;

new     bool:   g_bInRound              = false;
new     bool:   g_bPlayersLeftStart     = false;
new     bool:   g_bSecondHalf           = false;                                        // second roundhalf in a versus round

new     bool:   g_bPaused               = false;                                        // whether paused with pause.smx

new     Handle: g_hCvarPointsMode       = INVALID_HANDLE;
new     Handle: g_hCvarKeyValuesPath    = INVALID_HANDLE;
new     Handle: g_hCvarReportMode       = INVALID_HANDLE;

new     Handle: g_kHIData               = INVALID_HANDLE;

new     bool:   g_bHoldoutActive        = false;                                        // whether an event is ongoing
new             g_iProgress             = 0;                                            // progress through event
new             g_iCharProgress [MAXCHARACTERS];                                        // per survivor character: the progress they made in an event (in seconds) -- used if they died earlier (-1 = never present)

new     bool:   g_bHoldoutThisRound     = false;                                        // whether this map has a holdout event
new     Float:  g_fHoldoutPointFactor   = 0.0;
new             g_iHoldoutPointAbsolute = 0;                                            // either this or factor is used, not both
new             g_iHoldoutTime          = 0;

new             g_iHoldoutStartTime     = 0;                                            // absolute time it started
new             g_iMapDistance          = 0;                                            // current map distance (without deducted points for holdout pointsmode 2)
new             g_iPointsBonus          = 0;                                            // how many points the holdout bonus is worth
new             g_iActualBonus          = 0;                                            // what the players for this round actually get

new     String: g_sHoldoutStart         [MAXSTR];                                       // 'ferry_button' (etc)
new             g_iHoldoutStartHamId    = 0;                                            // hammerid for start button
new     String: g_sHoldoutStartClass    [MAXSTR];                                       // 'logic_relay' (etc)
new     String: g_sHoldoutStartHook     [MAXSTR];                                       // 'OnTrigger' (etc)

new     String: g_sHoldoutEnd           [MAXSTR];                                       // only included in case the timing varies or may be off...
new             g_iHoldoutEndHamId      = 0;
new     String: g_sHoldoutEndClass      [MAXSTR];
new     String: g_sHoldoutEndHook       [MAXSTR];

/*
    Idea:
    -----
    Pure camping bonus, when survivors have no choice.
    Example: Swamp Fever 1 ferry:
        Survivors press button, the clock starts. It ends when the ferry
        actually arrives (not when they press the ferry button!).
        If they lived long enough for the ferry to arrive, they get
        the full holdout bonus.
        
*/

public Plugin: myinfo =
{
    name = "Holdout Bonus",
    author = "Tabun",
    description = "Gives bonus for (partially) surviving holdout/camping events. (Requires penalty_bonus.)",
    version = "0.0.9",
    url = "https://github.com/Tabbernaut/L4D2-Plugins"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    RegPluginLibrary("holdout_bonus");
    
    g_hForwardSet =     CreateGlobalForward("OnHoldOutBonusSet", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell );
    g_hForwardStart =   CreateGlobalForward("OnHoldOutBonusStart", ET_Ignore, Param_Cell );
    g_hForwardEnd =     CreateGlobalForward("OnHoldOutBonusEnd", ET_Ignore, Param_Cell, Param_Cell );
    
    return APLRes_Success;
}

// crox readyup usage
public OnAllPluginsLoaded()
{
    g_bReadyUpAvailable = LibraryExists("readyup");
}

public OnLibraryRemoved(const String:name[])
{
    if ( StrEqual(name, "readyup") ) { g_bReadyUpAvailable = false; }
}

public OnLibraryAdded(const String:name[])
{
    if ( StrEqual(name, "readyup") ) { g_bReadyUpAvailable = true; }
}


public OnPluginStart()
{
    // events    
    HookEvent("round_start",                Event_RoundStart,               EventHookMode_PostNoCopy);
    HookEvent("player_death",               Event_PlayerDeath,              EventHookMode_Post);
    HookEvent("defibrillator_used",         Event_DefibUsed,                EventHookMode_Post);    
    
    // cvars
    g_hCvarReportMode = CreateConVar(
            "sm_hbonus_report",
            "2",                                        // 0: disable; 1: leave distance unchanged; 2: substract points from distance
            "The way the bonus is reported. 0: no report; 1: report only on round end; 2: also report after event; 3: also report when event starts; 4: only report on event end",
            FCVAR_NONE, true, 0.0, false
        );
    
    g_hCvarPointsMode = CreateConVar(
            "sm_hbonus_pointsmode",
            "2",                                        // 0: disable; 1: leave distance unchanged; 2: substract points from distance
            "The way the holdout bonus is awarded. 0: disable; 1: leave distance unchanged; 2: substract points from distance.",
            FCVAR_NONE, true, 0.0, false
        );
    
    g_hCvarKeyValuesPath = CreateConVar(
            "sm_hbonus_configpath",
            "configs/holdoutmapinfo.txt",
            "The path to the holdoutmapinfo.txt with keyvalues for per-map holdout bonus settings.",
            FCVAR_NONE
        );
    
    HookConVarChange(g_hCvarKeyValuesPath, ConvarChange_KeyValuesPath);
    
    // commands:
    RegConsoleCmd( "sm_hbonus", Cmd_DisplayBonus, "Shows current holdout bonus" );
    
}

public OnPluginEnd()
{
    KV_Close();
}

public OnConfigsExecuted()
{
    KV_Load();
}

public ConvarChange_KeyValuesPath(Handle:convar, const String:oldValue[], const String:newValue[])
{
    // reload the keyvalues file
    if (g_kHIData != INVALID_HANDLE) {
        KV_Close();
    }

    KV_Load();
    KV_UpdateHoldoutMapInfo();
}

public OnMapStart()
{
    g_bSecondHalf = false;
    
    // check for holdout event
    KV_UpdateHoldoutMapInfo();
}

public OnMapEnd()
{
    g_bInRound = false;
    
    if ( g_kHIData != INVALID_HANDLE )
    {
        KvRewind(g_kHIData);
    }
}

public Event_RoundStart (Handle:hEvent, const String:name[], bool:dontBroadcast)
{
    if ( g_bInRound ) { return; }
    
    g_bInRound = true;
    g_bPaused = false;
    
    // reset progress
    ResetTracking();

    if (!g_bSecondHalf) {
        CreateTimer(1.0, Timer_SetDisplayPoints, _, TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action: Timer_SetDisplayPoints(Handle:timer)
{
    // store holdout bonus points (will get set again if round goes live for real)
    // this is just for display purposes
    
    if (g_iHoldoutPointAbsolute) {
        g_iPointsBonus = g_iHoldoutPointAbsolute;
    } else {
        g_iPointsBonus = RoundFloat(float(L4D_GetVersusMaxCompletionScore()) * g_fHoldoutPointFactor);
    }

    return Plugin_Continue;
}

public OnRoundIsLive()
{
    RoundReallyStarting();
}

public Action: L4D_OnFirstSurvivorLeftSafeArea( client )
{
	if ( !g_bReadyUpAvailable )
	{
		RoundReallyStarting();
	}

	return Plugin_Continue;
}

// penalty_bonus: requesting final update before setting score, pass it the holdout bonus
public PBONUS_RequestFinalUpdate( &update )
{
    if ( g_bHoldoutActive )
    {
        // hold out ends, but note it's by request
        HoldOutEnds( true );
        update += g_iActualBonus;
    }
    
    return update;
}

// this is not called before penalty_bonus, so useless
public Action:L4D2_OnEndVersusModeRound(bool:countSurvivors)
{
	if ( g_bHoldoutThisRound )
	{
		if ( g_bHoldoutActive )
		{
			// game ended while holdout was active! wipe before they made it - apply partial bonus
			HoldOutEnds();
		}
		
		// display the puny bonus (if enabled)
		new iReport = GetConVarInt(g_hCvarReportMode);
		if (iReport && iReport != REPORT_ONLYEVENT && GetConVarBool(g_hCvarPointsMode) )
		{
			DisplayBonusToAll();
		}
	}

	g_bInRound = false;
	g_bSecondHalf = true;
	g_bPlayersLeftStart = false;

	return Plugin_Continue;
}

stock RoundReallyStarting()
{
    g_bPlayersLeftStart = true;
    
    if ( g_bHoldoutThisRound )
    {
        // get map distance and bonus points value
        if ( g_bSecondHalf )
        {
            // if second half, check if distance is different than we expected
            if ( GetConVarInt(g_hCvarPointsMode) == PMODE_DIST && L4D_GetVersusMaxCompletionScore() != (g_iMapDistance - g_iPointsBonus) )
            {
                g_iMapDistance = L4D_GetVersusMaxCompletionScore();
                if (g_iHoldoutPointAbsolute) {
                    g_iPointsBonus = g_iHoldoutPointAbsolute;
                } else {
                    g_iPointsBonus = RoundFloat( float(g_iMapDistance) * g_fHoldoutPointFactor );
                }
                
                // change distance
                if ( GetConVarInt(g_hCvarPointsMode) == PMODE_DIST )
                {
                    L4D_SetVersusMaxCompletionScore( g_iMapDistance - g_iPointsBonus );
                }
            }
        }
        else {
            g_iMapDistance = L4D_GetVersusMaxCompletionScore();
            if (g_iHoldoutPointAbsolute) {
                g_iPointsBonus = g_iHoldoutPointAbsolute;
            } else {
                g_iPointsBonus = RoundFloat( float(g_iMapDistance) * g_fHoldoutPointFactor );
            }
            
            // change distance
            if ( GetConVarInt(g_hCvarPointsMode) == PMODE_DIST )
            {
                L4D_SetVersusMaxCompletionScore( g_iMapDistance - g_iPointsBonus );
            }
        }
        
        Call_StartForward(g_hForwardSet);
        Call_PushCell(g_iPointsBonus);
        Call_PushCell(g_iMapDistance);
        Call_PushCell(g_iHoldoutTime);
        Call_PushCell( (GetConVarInt(g_hCvarPointsMode) == PMODE_DIST) ? 1 : 0);
        Call_Finish();
        
        // hook any triggers / buttons that may be required
        HookHoldOut();
    }
    
    /*
        remember distance, if we're changing it
        second half: check if distance is different from what we expect it to be
            if so: recalculate (so it's compatible with randumb :))
    
        only change if   g_hCvarPointsMode == PMODE_DIST
    */
}


// pause tracking
public OnPause()
{
    if ( g_bPaused ) { return; }
    g_bPaused = true;
}

public OnUnpause()
{
    g_bPaused = false;
}

// event tracking
public HoldOutStarts ( const String:output[], caller, activator, Float:delay )
{
    if ( g_bHoldoutActive ) { return; }
    
    PrintDebug( "Holdout Starts (hooked)." );
    
    g_bHoldoutActive = true;
    g_iHoldoutStartTime = GetTime();
    
    // check every second
    CreateTimer( 1.0, Timer_HoldOutCheck, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
    
    ResetTracking();
    
    // take into account current survivor status
    new chr;
    for ( new client = 1; client <= MaxClients; client++ )
    {
        if ( IS_VALID_SURVIVOR(client) && !IsPlayerAlive(client) )
        {
            chr = GetPlayerCharacter(client);
            g_iCharProgress[chr] = -1;
        }
    }
    
    // report
    new iReport = GetConVarInt(g_hCvarReportMode);
    if ( iReport > 2 && iReport != REPORT_ONLYEVENT )
    {
        PrintToChatAll( "\x01Holdout event starts... (\x04%i\x01 bonus over \x05%i\x01 seconds)", g_iPointsBonus, g_iHoldoutTime );
    }
    
    Call_StartForward(g_hForwardStart);
    Call_PushCell(g_iHoldoutTime);
    Call_Finish();
}

public HoldOutEnds_Hook ( const String:output[], caller, activator, Float:delay )
{
    // hooked on map logic
    // only use as safeguard / check for time
    
    PrintDebug( "Holdout Ends (hooked): abs: %i / prg %i / defined %i.", GetTime() - g_iHoldoutStartTime, g_iProgress, g_iHoldoutTime );
    
    if ( g_bHoldoutActive )
    {
        // safeguard: make sure the whole time is awarded
        g_iProgress = g_iHoldoutTime;
        HoldOutEnds();
    }
}



stock HoldOutEnds( bool:bByRequest = false )
{
    g_bHoldoutActive = false;
    
    PrintDebug( "Holdout over, awarding bonus: prg %i / defined %i.", g_iProgress, g_iHoldoutTime );
    
    g_iActualBonus = CalculateHoldOutBonus();
    
    // only give bonus if enabled
    if ( GetConVarBool(g_hCvarPointsMode) )
    {
        if ( !bByRequest )
        {
            PBONUS_AddRoundBonus( g_iActualBonus );
        }
        
        // only show bonus on event over if report 2+ (REPORT_ONLYEVENT is fine for this too)
        if ( GetConVarInt(g_hCvarReportMode) > 1 )
        {
            DisplayBonusToAll();
        }
    }
    
    Call_StartForward(g_hForwardEnd);
    Call_PushCell(g_iActualBonus);
    Call_PushCell(g_iProgress);
    Call_Finish();
}

// timer: every second while event is active
public Action: Timer_HoldOutCheck ( Handle: timer )
{
    // stop if hook trigger already caught
    if ( !g_bHoldoutActive ) { return Plugin_Stop; }
    
    // ignore while paused
    if ( g_bPaused ) { return Plugin_Continue; }
    
    g_iProgress++;
    
    // if set time entirely passed, stop the clock
    if ( g_iProgress == g_iHoldoutTime )
    {
        HoldOutEnds();
        return Plugin_Stop;
    }
    
    return Plugin_Continue;
}

// hook map logic to start the holdout tracking
stock HookHoldOut()
{
    new iEntity = -1;
    decl String:sTargetName[128];
    
    // find and hook start entity
    if ( strlen(g_sHoldoutStart) || g_iHoldoutStartHamId )
    {
        while ( (iEntity = FindEntityByClassname(iEntity, g_sHoldoutStartClass)) != -1 )
        {
            if ( strlen(g_sHoldoutStart) ) 
            {
                GetEntityName( iEntity, sTargetName, sizeof(sTargetName) );
                if ( StrEqual( sTargetName, g_sHoldoutStart, false ) )
                {
                    HookSingleEntityOutput(iEntity, g_sHoldoutStartHook, HoldOutStarts);
                    break;
                }
            }
            else if ( g_iHoldoutStartHamId && GetEntProp(iEntity, Prop_Data, "m_iHammerID") == g_iHoldoutStartHamId )
            {
                HookSingleEntityOutput(iEntity, g_sHoldoutStartHook, HoldOutStarts);
                break;
            }
        }
    }
    
    // end
    if ( strlen(g_sHoldoutEnd) || g_iHoldoutEndHamId)
    {
        while ( (iEntity = FindEntityByClassname(iEntity, g_sHoldoutEndClass)) != -1 )
        {
            if ( strlen(g_sHoldoutEnd) ) 
            {
                GetEntityName( iEntity, sTargetName, sizeof(sTargetName) );
                if ( StrEqual( sTargetName, g_sHoldoutEnd, false ) )
                {
                    HookSingleEntityOutput(iEntity, g_sHoldoutEndHook, HoldOutEnds_Hook);
                    break;
                }
            }
            else if ( g_iHoldoutEndHamId && GetEntProp(iEntity, Prop_Data, "m_iHammerID") == g_iHoldoutEndHamId )
            {
                HookSingleEntityOutput(iEntity, g_sHoldoutEndHook, HoldOutEnds_Hook);
                break;
            }
        }
    }
}

stock CalculateHoldOutBonus()
{
    // check status (of all survivors)
    // calculate bonus
    
    new Float: fBonusPart = float(g_iPointsBonus) / float(TEAM_SIZE);
    new tmpProg = 0;
    new Float: fBonus = 0.0;
    
    for ( new chr = 0; chr < MAXCHARACTERS; chr++ )
    {
        // skip ones dead from the start
        if ( g_iCharProgress[chr] == -1 ) { continue; }
        
        // 0 means they made it until 'now'
        tmpProg = ( g_iCharProgress[chr] == 0 ) ? g_iProgress : g_iCharProgress[chr];
        
        // add bonus for char
        if ( g_iHoldoutTime != tmpProg ) {
            fBonus += fBonusPart / float(g_iHoldoutTime) * float(tmpProg);
        } else {
            fBonus += fBonusPart;
        }
    }
    
    return RoundFloat( fBonus );
}

// death / revival tracking
public Action: Event_PlayerDeath ( Handle:event, const String:name[], bool:dontBroadcast )
{
    if ( !g_bPlayersLeftStart || !g_bHoldoutActive ) { return; }
    
    new client = GetClientOfUserId( GetEventInt(event, "userid") );
    if ( !IS_VALID_SURVIVOR(client) ) { return; }
    
    // stop progress for this character
    new chr = GetPlayerCharacter(client);
    g_iCharProgress[chr] = g_iProgress;
}

public Action: Event_DefibUsed (Handle:event, const String:name[], bool:dontBroadcast)
{
    if ( !g_bPlayersLeftStart || !g_bHoldoutActive ) { return; }
    
    new client = GetClientOfUserId( GetEventInt(event, "subject") );
    if ( !IS_VALID_SURVIVOR(client) ) { return; }
    
    // reset progress so it will be matched to g_iProgress
    new chr = GetPlayerCharacter(client);
    g_iCharProgress[chr] = 0;
}


/*  Command
    ------- */
public Action: Cmd_DisplayBonus (client, args)
{
    new String: sMsg[128];
    
    // build message: current / round's bonus
    if ( !g_bHoldoutThisRound )
    {
        Format( sMsg, sizeof(sMsg), "no holdout event this round." );
    }
    else
    {
        if ( g_bHoldoutActive )
        {
            Format( sMsg, sizeof(sMsg), "\x04%i\x01 out of \x05%i\x01 [\x04%i\x01/\x05%i\x01 sec].", CalculateHoldOutBonus(), g_iPointsBonus, g_iProgress, g_iHoldoutTime );
        }
        else if ( g_iActualBonus )
        {
            Format( sMsg, sizeof(sMsg), "\x04%i\x01 out of \x05%i\x01 [event over].", g_iActualBonus, g_iPointsBonus );
        }
        else
        {
            Format( sMsg, sizeof(sMsg), "\x04%i\x01 out of \x05%i\x01 [not started yet].", g_iActualBonus, g_iPointsBonus );
        }
    }
    
    // display message
    if ( IS_VALID_INGAME(client) )
    {
        PrintToChat( client, "\x01Holdout Bonus: %s", sMsg );
    }
    else
    {
        PrintToServer( "\x01Holdout Bonus: %s", sMsg );
    }
}

stock DisplayBonusToAll()
{
    if ( g_iActualBonus )
    {
        PrintToChatAll( "\x01Holdout Bonus: \x04%i\x01 out of \x05%i\x01.", g_iActualBonus, g_iPointsBonus );
    }
}

/*  Keyvalues
    --------- */
KV_Close()
{
    if ( g_kHIData == INVALID_HANDLE ) { return; }
    CloseHandle(g_kHIData);
    g_kHIData = INVALID_HANDLE;
}

KV_Load()
{
    decl String:sNameBuff[PLATFORM_MAX_PATH];
    GetConVarString( g_hCvarKeyValuesPath, sNameBuff, sizeof(sNameBuff) );
    BuildPath(Path_SM, sNameBuff, sizeof(sNameBuff), sNameBuff);
    
    g_kHIData = CreateKeyValues("HoldoutEvents");
    
    if ( !FileToKeyValues(g_kHIData, sNameBuff) )
    {
        LogError("Couldn't load HoldOutMapInfo data! (file: %s)", sNameBuff);
        KV_Close();
        return;
    }

    PrintDebug( "Holdout data loaded from file: %s.", sNameBuff );
}

bool: KV_UpdateHoldoutMapInfo()
{
    g_bHoldoutThisRound = false;    // whether the map has a holdout event
    g_fHoldoutPointFactor = 0.0;    // how much the event is worth as a fraction of map distance
    g_iHoldoutPointAbsolute = 0;
    g_iHoldoutTime = 0;             // how long the event lasts
    
    if ( g_kHIData == INVALID_HANDLE ) { return false; }

    /*
        To Do:
        figure out a way to get information about how the event is started
        so we can do tracking.. targetname listening, I assume..
    */
    
    new String: mapname[64];
    GetCurrentMap(mapname, sizeof(mapname));
    
    // get keyvalues
    if ( KvJumpToKey(g_kHIData, mapname) )
    {
        g_bHoldoutThisRound = bool: (KvGetNum(g_kHIData, "holdout", 0));
        g_fHoldoutPointFactor = KvGetFloat(g_kHIData, "pointfactor", 0.0);
        g_iHoldoutPointAbsolute = KvGetNum(g_kHIData, "pointabsolute", 0);
        g_iHoldoutTime = KvGetNum(g_kHIData, "time", 0);
        
        if ( g_bHoldoutThisRound )
        {
            KvGetString( g_kHIData, "t_start", g_sHoldoutStart, MAXSTR, "" );
            g_iHoldoutStartHamId = KvGetNum( g_kHIData, "t_s_hamid", 0 );
            KvGetString( g_kHIData, "t_s_class", g_sHoldoutStartClass, MAXSTR, "" );
            KvGetString( g_kHIData, "t_s_hook", g_sHoldoutStartHook, MAXSTR, "" );
            
            KvGetString( g_kHIData, "t_end", g_sHoldoutEnd, MAXSTR, "" );
            g_iHoldoutEndHamId = KvGetNum( g_kHIData, "t_e_hamid", 0 );
            KvGetString( g_kHIData, "t_e_class", g_sHoldoutEndClass, MAXSTR, "" );
            KvGetString( g_kHIData, "t_e_hook", g_sHoldoutEndHook, MAXSTR, "" );
        }
        
        PrintDebug( "Read holdout mapinfo for '%s': %i / (factor: %.2f; abs: %i).",
            mapname, g_bHoldoutThisRound,
            g_fHoldoutPointFactor, g_iHoldoutPointAbsolute
        );
        
        return true;
    }
    
    return false;
}

/*  Support
    ------- */

stock ResetTracking()
{
    g_iProgress = 0;
    g_iActualBonus = 0;
    
    for ( new i = 0; i < MAXCHARACTERS; i++ )
    {
        g_iCharProgress[i] = 0;
    }
}

GetEntityName( iEntity, String:sTargetName[], iSize )
{
    GetEntPropString(iEntity, Prop_Data, "m_iName", sTargetName, iSize);
}

stock GetPlayerCharacter ( client )
{
    new tmpChr = GetEntProp(client, Prop_Send, "m_survivorCharacter");
    
    // use models when incorrect character returned
    if ( tmpChr < 0 || tmpChr >= MAXCHARACTERS )
    {
        decl String:model[PLATFORM_MAX_PATH];
        GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
        
        if (StrContains(model, "gambler") != -1) {          tmpChr = 0; }
        else if (StrContains(model, "coach") != -1) {       tmpChr = 2; }
        else if (StrContains(model, "mechanic") != -1) {    tmpChr = 3; }
        else if (StrContains(model, "producer") != -1) {    tmpChr = 1; }
        else if (StrContains(model, "namvet") != -1) {      tmpChr = 0; }
        else if (StrContains(model, "teengirl") != -1) {    tmpChr = 1; }
        else if (StrContains(model, "biker") != -1) {       tmpChr = 3; }
        else if (StrContains(model, "manager") != -1) {     tmpChr = 2; }
        else {                                              tmpChr = 0; }
    }
    
    return tmpChr;
}

stock PrintDebug( const String:Message[], any:... )
{
	decl String:DebugBuff[256];
	VFormat(DebugBuff, sizeof(DebugBuff), Message, 3);
	LogMessage(DebugBuff);
	//PrintToServer(DebugBuff);
}