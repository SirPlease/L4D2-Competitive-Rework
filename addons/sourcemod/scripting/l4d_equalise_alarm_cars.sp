/*
	SourcePawn is Copyright (C) 2006-2008 AlliedModders LLC.  All rights reserved.
	SourceMod is Copyright (C) 2006-2008 AlliedModders LLC.  All rights reserved.
	Pawn and SMALL are Copyright (C) 1997-2008 ITB CompuPhase.
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
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
    name        = "L4D2 Equalise Alarm Cars",
    author      = "Jahze",
    version     = "1.2",
    description = "Make the alarmed car spawns the same for each team in versus"
};

new bool:bHooked = false;
new bool:bActivated = false;
new bool:bSecondRound = false;
new bool:bPatched = false;

new Handle:hFirstRoundCars;
new Handle:hSecondRoundCars;

new Handle:hCvarEqAlarmCars;

public OnPluginStart() {
    hCvarEqAlarmCars = CreateConVar("l4d_equalise_alarm_cars", "1", "Makes alarmed cars spawn in the same way for both teams", FCVAR_NONE);
    HookConVarChange(hCvarEqAlarmCars, EqAlarmCarsChange);
    
    hFirstRoundCars = CreateArray(128);
    hSecondRoundCars = CreateArray(128);
    
    HookEvents();
}

public OnPluginStop() {
    UnhookEvents();
}

public OnMapStart() {
    bActivated = false;
    bSecondRound = false;
    bPatched = false;
    
    ClearArray(hFirstRoundCars);
    ClearArray(hSecondRoundCars);
}

HookEvents() {
    if ( !bHooked ) {
        HookEvent("round_start", RoundStart);
        HookEvent("round_end", RoundEnd);
        bHooked = true;
    }
}

UnhookEvents() {
    if ( bHooked ) {
        UnhookEvent("round_start", RoundStart);
        UnhookEvent("round_end", RoundEnd);
        bHooked = false;
    }
}

public EqAlarmCarsChange( Handle:cvar, const String:oldValue[], const String:newValue[] ) {
    if ( StringToInt(newValue) == 1 ) {
        HookEvents();
    }
    else {
        UnhookEvents();
    }
}

public Action:RoundStart( Handle:event, const String:name[], bool:dontBroadcast ) {
    CreateTimer(0.1, RoundStartDelay);
}

public Action:RoundEnd( Handle:event, const String:name[], bool:dontBroadcast ) {
    if ( !bSecondRound ) {
        bSecondRound = true;
    }
}

public Action:RoundStartDelay( Handle:timer ) {
    new iEntity = -1;
    decl String:sTargetName[128];
    
    if ( bSecondRound && !bActivated ) {
        return;
    }
    
    while ( (iEntity = FindEntityByClassname(iEntity, "logic_relay")) != -1 ) {
        GetEntityName(iEntity, sTargetName, sizeof(sTargetName));
        
        if ( StrContains(sTargetName, "-relay_caralarm_off") == -1 ) {
            continue;
        }
        
        HookSingleEntityOutput(iEntity, "OnTrigger", CarAlarmLogicRelayTriggered);
    }
}

public CarAlarmLogicRelayTriggered( const String:output[], caller, activator, Float:delay ) {
    decl String:sTargetName[128];
    GetEntityName(caller, sTargetName, sizeof(sTargetName));
    
    if (IsValidEntity(activator)) {
        decl String:sClassName[128];
        GetEntityClassname(activator, sClassName, sizeof(sClassName));
        
        // If a car is turned off because of a tank punch or because it was
        // triggered the activator is the car itself. When the cars get
        // randomised the activator is the player who entered the trigger area.
        if ( StrEqual(sClassName, "prop_car_alarm") ) {
            return;
        }
    }
        
    if ( !bSecondRound ) {
        bActivated = true;
        PushArrayString(hFirstRoundCars, sTargetName);
    }
    else {
        PushArrayString(hSecondRoundCars, sTargetName);
        if ( !bPatched ) {
            CreateTimer(1.0, PatchAlarmedCars);
            bPatched = true;
        }
    }
}

public Action:PatchAlarmedCars( Handle:timer ) {
    decl String:sEntName[128];
    
    for ( new i = 0; i < GetArraySize(hFirstRoundCars); i++ ) {
        GetArrayString(hFirstRoundCars, i, sEntName, sizeof(sEntName));
        
        if ( FindStringInArray(hSecondRoundCars, sEntName) == -1 ) {
            DisableCar(sEntName);
        }
    }
    
    for ( new i = 0; i < GetArraySize(hSecondRoundCars); i++ ) {
        GetArrayString(hSecondRoundCars, i, sEntName, sizeof(sEntName));
        
        if ( FindStringInArray(hFirstRoundCars, sEntName) == -1 ) {
            EnableCar(sEntName);
        }
    }
}

bool:ExtractCarName( const String:sName[], String:sBuffer[], iSize ) {
    return (SplitString(sName, "-", sBuffer, iSize) != -1);
}

DisableCar( const String:sName[] ) {
    TriggerCarRelay(sName, false);
}

EnableCar( const String:sName[] ) {
    TriggerCarRelay(sName, true);
}

TriggerCarRelay( const String:sName[], bool:bOn ) {
    decl String:sCarName[128];
    new iEntity;
    
    if ( !ExtractCarName(sName, sCarName, sizeof(sCarName)) ) {
        return;
    }
    
    StrCat(sCarName, sizeof(sCarName), "-relay_caralarm_");
    
    if ( bOn ) {
        StrCat(sCarName, sizeof(sCarName), "on");
    }
    else {
        StrCat(sCarName, sizeof(sCarName), "off");
    }
    
    iEntity = FindEntityByName(sCarName, "logic_relay");
    
    if ( iEntity != -1 ) {
        AcceptEntityInput(iEntity, "Trigger");
    }
}

FindEntityByName( const String:sName[], const String:sClassName[] ) {
    new iEntity = -1;
    decl String:sEntName[128];
    
    while ( (iEntity = FindEntityByClassname(iEntity, sClassName)) != -1 ) {
        if ( !IsValidEntity(iEntity) ) {
            continue;
        }
        
        GetEntityName(iEntity, sEntName, sizeof(sEntName));
        
        if ( StrEqual(sEntName, sName) ) {
            return iEntity;
        }
    }
    
    return -1;
}

GetEntityName( iEntity, String:sTargetName[], iSize ) {
    GetEntPropString(iEntity, Prop_Data, "m_iName", sTargetName, iSize);
}