#pragma semicolon 1

#include <sourcemod>
//#include <left4downtown.inc>

new Handle: hCommonLimit = INVALID_HANDLE;
new iCommonLimit;                                               // stored for efficiency


/*
    -----------------------------------------------------------------------------------------------------------------------------------------------------

    Changelog
    ---------


    -----------------------------------------------------------------------------------------------------------------------------------------------------
 */

public Plugin:myinfo = 
{
    name = "Director-scripted common limit blocker",
    author = "Tabun",
    description = "Prevents director scripted overrides of z_common_limit. Only affects scripted common limits higher than the cvar.",
    version = "0.1a",
    url = "nope"
}

/* -------------------------------
 *      Init
 * ------------------------------- */

public OnPluginStart()
{
    // cvars
    hCommonLimit = FindConVar("z_common_limit");
    iCommonLimit = GetConVarInt(hCommonLimit);
    HookConVarChange(hCommonLimit, Cvar_CommonLimitChange);
}


public Cvar_CommonLimitChange( Handle:cvar, const String:oldValue[], const String:newValue[] ) { iCommonLimit = StringToInt(newValue); }
    

/* -------------------------------
 *      General hooks / events
 * ------------------------------- */

public OnMapStart()
{
    // do something?
}

public Action:L4D_OnGetScriptValueInt(const String:key[], &retVal)
{
    if (StrEqual(key,"CommonLimit"))
    {
        if (retVal > iCommonLimit)
        {
            retVal = iCommonLimit;
            return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}
