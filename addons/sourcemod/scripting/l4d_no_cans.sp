#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

new bool:bNoCans = true;
new bool:bNoPropane = true;
new bool:bNoOxygen = true;
new bool:bNoFireworks = true;

new Handle:cvar_noCans;
new Handle:cvar_noPropane;
new Handle:cvar_noOxygen;
new Handle:cvar_noFireworks;

static const String:CAN_GASCAN[]   = "models/props_junk/gascan001a.mdl";
static const String:CAN_PROPANE[]   = "models/props_junk/propanecanister001a.mdl";
static const String:CAN_OXYGEN[]   = "models/props_equipment/oxygentank01.mdl";
static const String:CAN_FIREWORKS[]   = "models/props_junk/explosive_box001.mdl";

public Plugin:myinfo =
{
    name        = "L4D2 Remove Cans",
    author      = "Jahze, Sir",
    version     = "0.3",
    description = "Provides the ability to remove Gascans, Propane, Oxygen Tanks and Fireworks"
}

public OnPluginStart() {
    cvar_noCans = CreateConVar("l4d_no_cans", "1", "Remove Gascans?", FCVAR_NONE);
    cvar_noPropane = CreateConVar("l4d_no_propane", "1", "Remove Propane Tanks?", FCVAR_NONE);
    cvar_noOxygen = CreateConVar("l4d_no_oxygen", "1", "Remove Oxygen Tanks?", FCVAR_NONE);
    cvar_noFireworks = CreateConVar("l4d_no_fireworks", "1", "Remove Fireworks?", FCVAR_NONE);
    HookConVarChange(cvar_noCans, NoCansChange);
    HookConVarChange(cvar_noPropane, NoPropaneChange);
    HookConVarChange(cvar_noOxygen, NoOxygenChange);
    HookConVarChange(cvar_noFireworks, NoFireworksChange);
    HookEvent("round_start", RoundStartHook, EventHookMode_Post);
}

IsCan(iEntity) 
{
    decl String:sModelName[128];
    GetEntPropString(iEntity, Prop_Data, "m_ModelName", sModelName, sizeof(sModelName));
    
    if (bool:GetEntProp(iEntity, Prop_Send, "m_isCarryable", 1))
    {
        if (StrEqual(sModelName, CAN_GASCAN, false) && bNoCans) return true;
        if (StrEqual(sModelName, CAN_PROPANE, false) && bNoPropane) return true;
        if (StrEqual(sModelName, CAN_OXYGEN, false) && bNoOxygen) return true;
        if (StrEqual(sModelName, CAN_FIREWORKS, false) && bNoFireworks) return true;
    }
    return false;
}

public Action:RoundStartHook( Handle:event, const String:name[], bool:dontBroadcast ) 
{
    CreateTimer(1.0, RoundStartNoCans);
}

public NoCansChange( Handle:cvar, const String:oldValue[], const String:newValue[] ) {
    if (StringToInt(newValue) == 0) bNoCans = false;
    else bNoCans = true;
}

public NoPropaneChange( Handle:cvar, const String:oldValue[], const String:newValue[] ) {
    if (StringToInt(newValue) == 0) bNoPropane = false;
    else bNoPropane = true;
}

public NoOxygenChange( Handle:cvar, const String:oldValue[], const String:newValue[] ) {
    if (StringToInt(newValue) == 0) bNoOxygen = false;
    else bNoOxygen = true;
}

public NoFireworksChange( Handle:cvar, const String:oldValue[], const String:newValue[] ) {
    if (StringToInt(newValue) == 0) bNoFireworks = false;
    else bNoFireworks = true;
}

public Action:RoundStartNoCans( Handle:timer ) 
{
    new iEntity;
    
    while ( (iEntity = FindEntityByClassname(iEntity, "prop_physics")) != -1 ) {
        if ( !IsValidEdict(iEntity) || !IsValidEntity(iEntity) ) {
            continue;
        }
        
        // Let's see what we got here!
        if (IsCan(iEntity)) 
        {
            AcceptEntityInput(iEntity, "Kill");
        }
    }
}