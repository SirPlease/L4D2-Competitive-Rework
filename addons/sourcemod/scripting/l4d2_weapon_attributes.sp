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
#include <sdkhooks>
#include <left4dhooks>

#define MAX_ATTRS           21
#define TANK_ZOMBIE_CLASS   8

public Plugin:myinfo =
{
    name        = "L4D2 Weapon Attributes",
    author      = "Jahze, Stabby",
    version     = "1.2a",
    description = "Allowing tweaking of the attributes of all weapons"
};

new L4D2IntWeaponAttributes:iIntWeaponAttributes[3] = {
    L4D2IWA_Damage,
    L4D2IWA_Bullets,
    L4D2IWA_ClipSize,
};

new L4D2FloatWeaponAttributes:iFloatWeaponAttributes[17] = {
    L4D2FWA_MaxPlayerSpeed,
    L4D2FWA_SpreadPerShot,
    L4D2FWA_MaxSpread,
    L4D2FWA_SpreadDecay,
    L4D2FWA_MinDuckingSpread,
    L4D2FWA_MinStandingSpread,
    L4D2FWA_MinInAirSpread,
    L4D2FWA_MaxMovementSpread,
    L4D2FWA_PenetrationNumLayers,
    L4D2FWA_PenetrationPower,
    L4D2FWA_PenetrationMaxDist,
    L4D2FWA_CharPenetrationMaxDist,
    L4D2FWA_Range,
    L4D2FWA_RangeModifier,
    L4D2FWA_CycleTime,
    L4D2FWA_PelletScatterPitch,	 	
    L4D2FWA_PelletScatterYaw,
};

new String:sWeaponAttrNames[MAX_ATTRS][32] = {
    "Damage",
    "Bullets",
    "Clip Size",
    "Max player speed",
    "Spread per shot",
    "Max spread",
    "Spread decay",
    "Min ducking spread",
    "Min standing spread",
    "Min in air spread",
    "Max movement spread",
    "Penetration num layers",
    "Penetration power",
    "Penetration max dist",
    "Char penetration max dist",
    "Range",
    "Range modifier",
    "Cycle time",
    "Pellet scatter pitch",
    "Pellet scatter yaw",
    "Tank damage multiplier"
};

new String:sWeaponAttrShortName[MAX_ATTRS][32] = {
    "damage",
    "bullets",
    "clipsize",
    "speed",
    "spreadpershot",
    "maxspread",
    "spreaddecay",
    "minduckspread",
    "minstandspread",
    "minairspread",
    "maxmovespread",
    "penlayers",
    "penpower",
    "penmaxdist",
    "charpenmaxdist",
    "range",
    "rangemod",
    "cycletime",
    "scatterpitch",
    "scatteryaw",
    "tankdamagemult"
};

new bool:bLateLoad;

new Handle:hTankDamageKVs;
new Handle:hWeaponDefaultAttsTrie[MAX_ATTRS];
new Handle:hWeaponNamesInTrie[MAX_ATTRS];

public APLRes:AskPluginLoad2( Handle:plugin, bool:late, String:error[], errMax ) {
    bLateLoad = late;
    return APLRes_Success;
}

public OnPluginStart() {
    RegServerCmd("sm_weapon", Weapon);
    RegConsoleCmd("sm_weapon_attributes", WeaponAttributes);

    hTankDamageKVs = CreateKeyValues("DamageVsTank");

    for ( new i = 0; i < MAX_ATTRS; i++ ) {
        hWeaponDefaultAttsTrie[i] = INVALID_HANDLE;
        hWeaponNamesInTrie[i] = INVALID_HANDLE;
    }

    if ( bLateLoad ) {
        for ( new i = 1; i <= MaxClients; i++ ) {
            if ( IsClientInGame(i) ) {
                SDKHook(i, SDKHook_OnTakeDamage, DamageBuffVsTank);
            }
        }
    }
}

public OnClientPutInServer( client ) {
    SDKHook(client, SDKHook_OnTakeDamage, DamageBuffVsTank);
}

public OnPluginEnd() {
    if ( hTankDamageKVs != INVALID_HANDLE ) {
        CloseHandle(hTankDamageKVs);
        hTankDamageKVs = INVALID_HANDLE;
    }

    decl i, j, String:sWeaponName[32], buf, Float:fub;
    for ( i = 0; i < 3; i++ ) {
        if (hWeaponDefaultAttsTrie[i] != INVALID_HANDLE) {
            for ( j = 0; j < GetArraySize(hWeaponNamesInTrie[i]); j++ ) {
                GetArrayString(hWeaponNamesInTrie[i], j, sWeaponName, 32);
                GetTrieValue(hWeaponDefaultAttsTrie[i], sWeaponName, buf);
                SetWeaponAttributeInt(sWeaponName, i, buf);
            }
        }
    }
    for ( i = 0; i < MAX_ATTRS - 1; i++ ) {
        if (hWeaponDefaultAttsTrie[i] != INVALID_HANDLE) {
            for ( j = 0; j < GetArraySize(hWeaponNamesInTrie[i]); j++ ) {
                GetArrayString(hWeaponNamesInTrie[i], j, sWeaponName, 32);
                GetTrieValue(hWeaponDefaultAttsTrie[i], sWeaponName, fub);
                SetWeaponAttributeFloat(sWeaponName, i, fub);
            }
        }
    }
}

GetWeaponAttributeIndex( String:sAttrName[128] ) {
    for ( new i = 0; i < MAX_ATTRS; i++ ) {
        if ( StrEqual(sAttrName, sWeaponAttrShortName[i]) ) {
            return i;
        }
    }

    return -1;
}

GetWeaponAttributeInt( const String:sWeaponName[], idx ) {
    return L4D2_GetIntWeaponAttribute(sWeaponName, iIntWeaponAttributes[idx]);
}

Float:GetWeaponAttributeFloat( const String:sWeaponName[], idx ) {
    return L4D2_GetFloatWeaponAttribute(sWeaponName, iFloatWeaponAttributes[idx]);
}

SetWeaponAttributeInt( const String:sWeaponName[], idx, value ) {
    L4D2_SetIntWeaponAttribute(sWeaponName, iIntWeaponAttributes[idx], value);
}

SetWeaponAttributeFloat( const String:sWeaponName[], idx, Float:value ) {
    L4D2_SetFloatWeaponAttribute(sWeaponName, iFloatWeaponAttributes[idx], value);
}

public Action:Weapon( args ) {
    new iValue;
    new Float:fValue;
    new iAttrIdx;
    decl String:sWeaponName[128];
    decl String:sWeaponNameFull[128];
    decl String:sAttrName[128];
    decl String:sAttrValue[128];

    if ( GetCmdArgs() < 3 ) {
        PrintToServer("Syntax: sm_weapon <weapon> <attr> <value>");
        return;
    }

    GetCmdArg(1, sWeaponName, sizeof(sWeaponName));
    GetCmdArg(2, sAttrName, sizeof(sAttrName));
    GetCmdArg(3, sAttrValue, sizeof(sAttrValue));

    if ( L4D2_IsValidWeapon(sWeaponName) ) {
        PrintToServer("Bad weapon name: %s", sWeaponName);
        return;
    }

    iAttrIdx = GetWeaponAttributeIndex(sAttrName);

    if ( iAttrIdx == -1 ) {
        PrintToServer("Bad attribute name: %s", sAttrName);
        return;
    }

    sWeaponNameFull[0] = 0;
    StrCat(sWeaponNameFull, sizeof(sWeaponNameFull), "weapon_");
    StrCat(sWeaponNameFull, sizeof(sWeaponNameFull), sWeaponName);

    if (hWeaponDefaultAttsTrie[iAttrIdx] == INVALID_HANDLE) {
        hWeaponDefaultAttsTrie[iAttrIdx] = CreateTrie();
        hWeaponNamesInTrie[iAttrIdx] = CreateArray(32);
    }
    PushArrayString(hWeaponNamesInTrie[iAttrIdx], sWeaponNameFull);

    iValue = StringToInt(sAttrValue);
    fValue = StringToFloat(sAttrValue);

    if ( iAttrIdx < 3 ) {
        SetTrieValue(hWeaponDefaultAttsTrie[iAttrIdx], sWeaponNameFull, GetWeaponAttributeInt(sWeaponNameFull, iAttrIdx), false);
        SetWeaponAttributeInt(sWeaponNameFull, iAttrIdx, iValue);
        PrintToServer("%s for %s set to %d", sWeaponAttrNames[iAttrIdx], sWeaponName, iValue);
    }
    else if ( (iAttrIdx -= 3) < MAX_ATTRS - 1 ) {
        SetTrieValue(hWeaponDefaultAttsTrie[iAttrIdx], sWeaponNameFull, GetWeaponAttributeFloat(sWeaponNameFull, iAttrIdx), false);
        SetWeaponAttributeFloat(sWeaponNameFull, iAttrIdx, fValue);
        PrintToServer("%s for %s set to %.2f", sWeaponAttrNames[iAttrIdx], sWeaponName, fValue);
    }
    else {
        KvSetFloat(hTankDamageKVs, sWeaponNameFull, fValue);
        PrintToServer("%s for %s set to %.2f", sWeaponAttrNames[iAttrIdx], sWeaponName, fValue);
    }
}

public Action:WeaponAttributes( client, args ) {
    decl String:sWeaponName[128];
    decl String:sWeaponNameFull[128];

    if ( GetCmdArgs() < 1 ) {
        ReplyToCommand(client, "Syntax: sm_weapon_attributes <weapon>");
        return;
    }

    GetCmdArg(1, sWeaponName, sizeof(sWeaponName));

    if ( L4D2_IsValidWeapon(sWeaponName) ) {
        ReplyToCommand(client, "Bad weapon name: %s", sWeaponName);
        return;
    }

    sWeaponNameFull[0] = 0;
    StrCat(sWeaponNameFull, sizeof(sWeaponNameFull), "weapon_");
    StrCat(sWeaponNameFull, sizeof(sWeaponNameFull), sWeaponName);

    ReplyToCommand(client, "Weapon stats for %s", sWeaponName);

    for ( new i = 0; i < 3; i++ ) {
        new iValue = GetWeaponAttributeInt(sWeaponNameFull, i);
        ReplyToCommand(client, "%s: %d", sWeaponAttrNames[i], iValue);
    }

    for ( new i = 3; i < MAX_ATTRS-1; i++ ) {
        new Float:fValue = GetWeaponAttributeFloat(sWeaponNameFull, i);
        ReplyToCommand(client, "%s: %.2f", sWeaponAttrNames[i], fValue);
    }

    new Float:fBuff = KvGetFloat(hTankDamageKVs, sWeaponNameFull, 0.0);

    if ( fBuff ) {
        ReplyToCommand(client, "%s: %.2f", sWeaponAttrNames[MAX_ATTRS-1], fBuff);
    }
}

public Action:DamageBuffVsTank( victim, &attacker, &inflictor, &Float:damage, &damageType, &weapon, Float:damageForce[3], Float:damagePosition[3] ) {
    if (attacker <= 0 || attacker > MaxClients+1) {
        return Plugin_Continue;
    }

    if ( !IsTank(victim) ) {
        return Plugin_Continue;
    }

    decl String:sWeaponName[128];
    GetClientWeapon(attacker, sWeaponName, sizeof(sWeaponName));
    new Float:fBuff = KvGetFloat(hTankDamageKVs, sWeaponName, 0.0);

    if ( !fBuff ) {
        return Plugin_Continue;
    }

    damage *= fBuff;

    return Plugin_Changed;
}

bool:IsTank( client ) {
    if ( client <= 0
    || client > MaxClients+1
    || !IsClientInGame(client)
    || GetClientTeam(client) != 3
    || !IsPlayerAlive(client) ) {
        return false;
    }

    new playerClass = GetEntProp(client, Prop_Send, "m_zombieClass");

    if ( playerClass == TANK_ZOMBIE_CLASS ) {
        return true;
    }

    return false;
}
