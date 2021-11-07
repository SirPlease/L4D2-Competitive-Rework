/*
    SourceMod Anti-Cheat
    Copyright (C) 2011-2016 SMAC Development Team
    Copyright (C) 2007-2011 CodingDirect LLC
	
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#if defined _smac_stocks_included
  #endinput
#endif
#define _smac_stocks_included

/**
 * Preprocessor directives
 */
#define MAX_EDICTS      2048
#define MAX_ENTITIES    4096

#define MAX_MAPNAME_LENGTH  32
#define MAX_AUTHID_LENGTH   64

// Hud Element hiding flags
#define HIDEHUD_WEAPONSELECTION     (1 << 0)	// Hide ammo count & weapon selection
#define HIDEHUD_FLASHLIGHT          (1 << 1)
#define HIDEHUD_ALL                 (1 << 2)
#define HIDEHUD_HEALTH              (1 << 3)	// Hide health & armor / suit battery
#define HIDEHUD_PLAYERDEAD          (1 << 4)	// Hide when local player's dead
#define HIDEHUD_NEEDSUIT            (1 << 5)	// Hide when the local player doesn't have the HEV suit
#define HIDEHUD_MISCSTATUS          (1 << 6)	// Hide miscellaneous status elements (trains, pickup history, death notices, etc)
#define HIDEHUD_CHAT                (1 << 7)	// Hide all communication elements (saytext, voice icon, etc)
#define HIDEHUD_CROSSHAIR           (1 << 8)	// Hide crosshairs
#define HIDEHUD_VEHICLE_CROSSHAIR   (1 << 9)	// Hide vehicle crosshair
#define HIDEHUD_INVEHICLE           (1 << 10)
#define HIDEHUD_BONUS_PROGRESS      (1 << 11)	// Hide bonus progress display (for bonus map challenges)
#define HIDEHUD_BITCOUNT            12

// Fade UserMessage bits
#define FFADE_IN        0x0001	// Just here so we don't pass 0 into the function
#define FFADE_OUT       0x0002	// Fade out (not in)
#define FFADE_MODULATE  0x0004	// Modulate (don't blend)
#define FFADE_STAYOUT   0x0008	// ignores the duration, stays faded out until new ScreenFade message received
#define FFADE_PURGE     0x0010	// Purges all other fades, replacing them with this one

// Macros
#define IS_CLIENT(%1)       (1 <= %1 <= MaxClients)
#define TIME_TO_TICK(%1)    (RoundToNearest((%1) / GetTickInterval()))
#define TICK_TO_TIME(%1)    ((%1) * GetTickInterval())

// Spectator movement modes
enum {
    OBS_MODE_NONE = 0,  // not in spectator mode
    OBS_MODE_DEATHCAM,  // special mode for death cam animation
    OBS_MODE_FREEZECAM, // zooms to a target, and freeze-frames on them
    OBS_MODE_FIXED,     // view from a fixed camera position
    OBS_MODE_IN_EYE,    // follow a player in first person view
    OBS_MODE_CHASE,     // follow a player in third person view
    OBS_MODE_ROAMING,   // free roaming
};

/**
 * General
 */
stock void GetPluginBasename(Handle plugin, char[] buffer,int maxlength)
{
    GetPluginFilename(plugin, buffer, maxlength);

    int check = -1;
    if ((check = FindCharInString(buffer, '/', true)) != -1 ||
        (check = FindCharInString(buffer, '\\', true)) != -1)
    {
        Format(buffer, maxlength, "%s", buffer[check+1]);
    }
}

stock bool IsConVarDefault(ConVar convar)
{
    char sDefaultVal[16], sCurrentVal[16];
    GetConVarDefault(convar, sDefaultVal, sizeof(sDefaultVal));
    GetConVarString(convar, sCurrentVal, sizeof(sCurrentVal));

    return StrEqual(sDefaultVal, sCurrentVal);
}

stock void StringToLower(char[] input)
{
    int length = strlen(input);

    for (int i = 0; i < length; i++)
    {
        input[i] = CharToLower(input[i]);
    }
}

/**
 * Clients
 */
stock bool IsClientNew(int client)
{
    // Client must be ingame.
    return IsFakeClient(client) || GetGameTime() > GetClientTime(client);
}

stock bool GetClientAbsVelocity(int client, float velocity[3])
{
    static int offset = -1;

    if (offset == -1 && (offset = FindDataMapInfo(client, "m_vecAbsVelocity")) == -1) // FindDataMapOffs(client, "m_vecAbsVelocity")) == -1)
    {
        ZeroVector(velocity);
        return false;
    }

    GetEntDataVector(client, offset, velocity);
    return true;
}

stock int GetClientHudFlags(int client)
{
    return GetEntProp(client, Prop_Send, "m_iHideHUD");
}

stock int GetClientObserverMode(int client)
{
    static int offset = -1;

    if (offset == -1 && (offset = FindSendPropInfo("CBasePlayer", "m_iObserverMode")) == -1) //FindSendPropOffs("CBasePlayer", "m_iObserverMode")) == -1)
    {
        return OBS_MODE_NONE;
    }

    return GetEntData(client, offset);
}

stock int GetClientObserverTarget(int client)
{
    static int offset = -1;

    if (offset == -1 && (offset = FindSendPropInfo("CBasePlayer", "m_hObserverTarget")) == -1)
    {
        return -1;
    }

    return GetEntDataEnt2(client, offset);
}

/**
 * Game Specific
 */
stock bool DODS_IsPlayerProne(int client)
{
    return view_as<bool>(GetEntProp(client, Prop_Send, "m_bProne") || 
        GetEntPropFloat(client, Prop_Send, "m_flGoProneTime") > 0.0 || 
        GetEntPropFloat(client, Prop_Send, "m_flUnProneTime") > 0.0);
}

stock bool L4D_IsPlayerGhost(int client)
{
    return view_as<bool>(GetEntProp(client, Prop_Send, "m_isGhost", 1));
}

// "Busy" implies that the client is not in their typical first-person state.
stock bool L4D_IsSurvivorBusy(int client)
{
    return GetEntityFlags(client) & FL_FROZEN || 
        GetClientHudFlags(client) & ~HIDEHUD_BONUS_PROGRESS || 
        GetEntProp(client, Prop_Send, "m_isIncapacitated") > 0 || 
        GetEntProp(client, Prop_Send, "m_knockdownReason") > 0 || 
        GetEntPropFloat(client, Prop_Send, "m_staggerDist") > 0.0 || 
        GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0 || 
        GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0;
}

stock bool L4D_IsInfectedBusy(int client)
{
    return GetEntPropFloat(client, Prop_Send, "m_vomitFadeStart") > GetGameTime() || 
        GetEntPropEnt(client, Prop_Send, "m_pounceVictim") > 0 || 
        GetEntPropEnt(client, Prop_Send, "m_tongueVictim") > 0;
}

stock bool L4D2_IsSurvivorBusy(int client)
{
    return GetEntityFlags(client) & FL_FROZEN || 
        GetClientHudFlags(client) & ~HIDEHUD_BONUS_PROGRESS || 
        GetEntProp(client, Prop_Send, "m_isIncapacitated") > 0 || 
        GetEntProp(client, Prop_Send, "m_knockdownReason") > 0 || 
        GetEntPropFloat(client, Prop_Send, "m_staggerDist") > 0.0 || 
        GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") > 0 || 
        GetEntPropEnt(client, Prop_Send, "m_carryAttacker") > 0 || 
        GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0 || 
        GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0 || 
        GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0;
}

stock bool L4D2_IsInfectedBusy(int client)
{
    return GetEntProp(client, Prop_Send, "m_iGlowType") == 3 || 
        GetEntPropFloat(client, Prop_Send, "m_vomitFadeStart") > GetGameTime() || 
        GetEntPropEnt(client, Prop_Send, "m_pummelVictim") > 0 || 
        GetEntPropEnt(client, Prop_Send, "m_carryVictim") > 0 || 
        GetEntPropEnt(client, Prop_Send, "m_pounceVictim") > 0 || 
        GetEntPropEnt(client, Prop_Send, "m_jockeyVictim") > 0 || 
        GetEntPropEnt(client, Prop_Send, "m_tongueVictim") > 0;
}

stock bool ND_IsPlayerCommander(int client)
{
    return GameRules_GetPropEnt("m_hCommanders", 0) == client || GameRules_GetPropEnt("m_hCommanders", 1) == client;
}

/**
 * Math
 */
stock void ZeroVector(float vec[3])
{
    vec[0] = vec[1] = vec[2] = 0.0;
}

stock bool IsVectorZero(const float vec[3])
{
    return vec[0] == 0.0 && vec[1] == 0.0 && vec[2] == 0.0;
}

stock bool IsVectorAlmostZero(const float vec[3], const float tolerance=0.1)
{
    return view_as<bool>(FloatAbs(vec[0]) <= tolerance && 
        FloatAbs(vec[1]) <= tolerance && 
        FloatAbs(vec[2]) <= tolerance);
}

stock bool AreVectorsEqual(const float vec1[3], const float vec2[3])
{
    return vec1[0] == vec2[0] && vec1[1] == vec2[1] && vec1[2] == vec2[2];
}

stock bool AreVectorsAlmostEqual(const float vec1[3], const float vec2[3], const float tolerance=0.1)
{
    return view_as<bool>(FloatAbs(vec1[0] - vec2[0]) <= tolerance && 
        FloatAbs(vec1[1] - vec2[1]) <= tolerance && 
        FloatAbs(vec1[2] - vec2[2]) <= tolerance);
}

stock int AbsValue(int value)
{
    return (value >= 0) ? value : -value;
}

stock any MinValue(any value, any min)
{
    return (value < min) ? min : value;
}

stock any MaxValue(any value, any max)
{
    return (value > max) ? max : value;
}

stock any ClampValue(any value, any min, any max)
{
    value = MinValue(value, min);
    value = MaxValue(value, max);

    return value;
}

stock int IPToLong(const char[] ip)
{
    char pieces[4][4];

    if (ExplodeString(ip, ".", pieces, sizeof(pieces), sizeof(pieces[])) != 4)
    {
        return 0;
    }

    return StringToInt(pieces[0]) << 24 | 
        StringToInt(pieces[1]) << 16 | 
        StringToInt(pieces[2]) << 8 | 
        StringToInt(pieces[3]);
}

stock void LongToIP(int ip, char[] buffer,int size)
{
    FormatEx(buffer, size, "%d.%d.%d.%d", (ip >> 24) & 0xFF, (ip >> 16) & 0xFF, (ip >> 8) & 0xFF, ip & 0xFF);
}

stock int MT_GetRandomInt(int min,int max)
{
    return RoundToNearest(GetURandomFloat() * float(max - min) + float(min));
}

stock float MT_GetRandomFloat(float min, float max)
{
    return GetURandomFloat() * (max - min) + min;
}

stock void BfWriteSBitLong(Handle bf,int data,int numBits)
{
    for (int i = 0; i < numBits; i++)
    {
        BfWriteBool(bf, !!(data & (1 << i)));
    }
}

stock int BfReadSBitLong(Handle bf,int numBits)
{
    int[] bits = new int[numBits];
    int ret, i;

    for (i = 0; i < numBits; i++)
    {
        bits[i] = BfReadBool(bf);
    }

    ret = bits[numBits-1] ? -1 : 0;

    for (i = numBits-1; i >= 0; i--)
    {
        ret <<= 1;
        ret |= bits[i];
    }

    return ret;
}
