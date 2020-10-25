#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <left4dhooks>

#define MAX_ATTRS           21
#define TANK_ZOMBIE_CLASS   8

 
public Plugin:myinfo =
{
    name        = "L4D2 Weapon Attributes",
    author      = "Jahze",
    version     = "1.4.2",
    description = "Allowing tweaking of the attributes of all weapons"
};

new L4D2IntWeaponAttributes:iIntWeaponAttributes[3] = {
    L4D2IWA_Damage,
    L4D2IWA_Bullets,
    L4D2IWA_ClipSize
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
    L4D2FWA_PelletScatterYaw
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

new Handle:hVanillaAttributesWeapon;
new Handle:hVanillaAttributesAttribute;
new Handle:hVanillaAttributesValue;
 
public APLRes:AskPluginLoad2( Handle:plugin, bool:late, String:error[], errMax ) {
    bLateLoad = late;
    return APLRes_Success;
}

 
public OnPluginStart() {
    RegServerCmd("sm_weapon", Weapon);
    RegConsoleCmd("sm_weapon_attributes", WeaponAttributes);

    hVanillaAttributesWeapon = CreateArray(32);
    hVanillaAttributesAttribute = CreateArray();
    hVanillaAttributesValue = CreateArray();
    hTankDamageKVs = CreateKeyValues("DamageVsTank");

 
    if ( bLateLoad ) {
        for ( new i = 1; i < MaxClients+1; i++ ) {
            if ( IsClientInGame(i) ) {
                SDKHook(i, SDKHook_OnTakeDamage, DamageBuffVsTank);
            }
        }
    }
}

 
public OnClientPutInServer( client ) {
    SDKHook(client, SDKHook_OnTakeDamage, DamageBuffVsTank);
}

 
public OnPluginEnd() 
{
    if ( hTankDamageKVs != INVALID_HANDLE ) {
        CloseHandle(hTankDamageKVs);
        hTankDamageKVs = INVALID_HANDLE;
    }
    new iSize = GetArraySize(hVanillaAttributesWeapon);
    new iAtIndex;
    decl String:sBuffer[32];
    for (new i = 0; i < iSize; i++)
    {
        GetArrayString(hVanillaAttributesWeapon, i, sBuffer, 32);
        iAtIndex = GetArrayCell(hVanillaAttributesAttribute, i);
        if (iAtIndex < 3)
        {
            L4D2_SetIntWeaponAttribute(sBuffer, iIntWeaponAttributes[iAtIndex], GetArrayCell(hVanillaAttributesValue, i));
            // DEBUG: PrintToChatAll("%s - '%s' set to %i", sBuffer, sWeaponAttrShortName[iAtIndex], GetArrayCell(hVanillaAttributesValue, i));
        }
        else if (iAtIndex < MAX_ATTRS - 1)
        {
            L4D2_SetFloatWeaponAttribute(sBuffer, iFloatWeaponAttributes[iAtIndex - 3], GetArrayCell(hVanillaAttributesValue, i));
            // DEBUG: PrintToChatAll("%s, '%s' set to %f", sBuffer, sWeaponAttrShortName[iAtIndex], GetArrayCell(hVanillaAttributesValue, i));
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

 
SetWeaponAttributeInt( const String:sWeaponName[], idx, value ) 
{
    new iSize = GetArraySize(hVanillaAttributesWeapon);
    decl String:sBuffer[32];
    for (new i = 0; i < iSize; i++)
    {
        GetArrayString(hVanillaAttributesWeapon, i, sBuffer, 32);
        if (StrEqual(sWeaponName, sBuffer) && idx == GetArrayCell(hVanillaAttributesAttribute, i))
        {
            L4D2_SetIntWeaponAttribute(sWeaponName, iIntWeaponAttributes[idx], value);
            return;
        }
    }
    PushArrayCell(hVanillaAttributesValue, L4D2_GetIntWeaponAttribute(sWeaponName, iIntWeaponAttributes[idx]));
    PushArrayString(hVanillaAttributesWeapon, sWeaponName);
    PushArrayCell(hVanillaAttributesAttribute, idx);
    L4D2_SetIntWeaponAttribute(sWeaponName, iIntWeaponAttributes[idx], value);
}

 
SetWeaponAttributeFloat( const String:sWeaponName[], idx, Float:value ) {
    new iSize = GetArraySize(hVanillaAttributesWeapon);
    decl String:sBuffer[32];
    for (new i = 0; i < iSize; i++)
    {
        GetArrayString(hVanillaAttributesWeapon, i, sBuffer, 32);
        if (StrEqual(sWeaponName, sBuffer) && idx == GetArrayCell(hVanillaAttributesAttribute, i))
        {
            L4D2_SetFloatWeaponAttribute(sWeaponName, iFloatWeaponAttributes[idx - 3], value);
            return;
        }
    }
    PushArrayCell(hVanillaAttributesValue, L4D2_GetFloatWeaponAttribute(sWeaponName, iFloatWeaponAttributes[idx - 3]));
    PushArrayString(hVanillaAttributesWeapon, sWeaponName);
    PushArrayCell(hVanillaAttributesAttribute, idx);
    L4D2_SetFloatWeaponAttribute(sWeaponName, iFloatWeaponAttributes[idx - 3], value);
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

 
    if (!L4D2_IsValidWeapon(sWeaponName) ) {
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

 
    iValue = StringToInt(sAttrValue);
    fValue = StringToFloat(sAttrValue);

 
    if ( iAttrIdx < 3 ) {
        SetWeaponAttributeInt(sWeaponNameFull, iAttrIdx, iValue);
        PrintToServer("%s for %s set to %d", sWeaponAttrNames[iAttrIdx], sWeaponName, iValue);
    }
    else if ( iAttrIdx < MAX_ATTRS - 1 ) 
    {
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
        return Plugin_Handled;
    }

 
    GetCmdArg(1, sWeaponName, sizeof(sWeaponName));

 
    if (!L4D2_IsValidWeapon(sWeaponName) ) {
        ReplyToCommand(client, "Bad weapon name: %s", sWeaponName);
        return Plugin_Handled;
    }

 
    sWeaponNameFull[0] = 0;
    StrCat(sWeaponNameFull, sizeof(sWeaponNameFull), "weapon_");
    StrCat(sWeaponNameFull, sizeof(sWeaponNameFull), sWeaponName);

 
    ReplyToCommand(client, "Weapon stats for %s", sWeaponName);

 
    for ( new i = 0; i < MAX_ATTRS - 1; i++ ) 
    {
        if ( i < 3)
        {
            new iValue = GetWeaponAttributeInt(sWeaponNameFull, i);
            ReplyToCommand(client, "%s: %d", sWeaponAttrNames[i], iValue);
        }
        else
        {
            new fI = i - 3;
            new Float:fValue = GetWeaponAttributeFloat(sWeaponNameFull, fI);
            ReplyToCommand(client, "%s: %.2f", sWeaponAttrNames[i], fValue);
        }
    }

 
    new Float:fBuff = KvGetFloat(hTankDamageKVs, sWeaponNameFull, 0.0);

 
    if ( fBuff ) {
        ReplyToCommand(client, "%s: %.2f", sWeaponAttrNames[MAX_ATTRS-1], fBuff);
    }
    return Plugin_Handled;
}

 
public Action:DamageBuffVsTank( victim, &attacker, &inflictor, &Float:damage, &damageType, &weapon, Float:damageForce[3], Float:damagePosition[3] ) {
    if (attacker <= 0 || attacker > MaxClients) {
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
    || client > MaxClients
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