#pragma semicolon 1
#pragma newdecls required

#include <dhooks>
#include <sourcemod>

#define PLUGIN_VERSION "0.1"

public Plugin myinfo =
{
	name        = "[L4D] Shared Random Overrides",
	author      = "ProdigySim",
	description = "Hook and override calls to Shared Random values",
	version     = PLUGIN_VERSION,
	url         = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
};

#define GAMEDATA_FILE "shared_random_funcs"

StringMap g_hOverrideValues;

/**
NAMES

CLIENT: SharedRandomFloat( CTerrorGun::FireBullet HorizSpread 40966199 0 )
CLIENT: SharedRandomFloat( CTerrorGun::FireBullet VertSpread -1207581035 0 )
CLIENT: SharedRandomFloat( CTerrorPlayer::FireBullet Spread -1772348738 2 )
CLIENT: SharedRandomFloat( CTerrorPlayer::FireBullet SpreadDir -1613363080 2 )
CLIENT: SharedRandomFloat( CTerrorPlayer::FireBullet Spread 53268011 3 )
CLIENT: SharedRandomFloat( CTerrorPlayer::FireBullet SpreadDir -782302255 3 )
CLIENT: SharedRandomFloat( CTerrorPlayer::FireBullet Spread 1604119874 4 )
CLIENT: SharedRandomFloat( CTerrorPlayer::FireBullet SpreadDir -477022257 4 )
CLIENT: SharedRandomFloat( CTerrorPlayer::FireBullet Spread -890488361 5 )
CLIENT: SharedRandomFloat( CTerrorPlayer::FireBullet SpreadDir -1390920602 5 )
CLIENT: SharedRandomFloat( CTerrorPlayer::FireBullet Spread -1374928343 6 )
CLIENT: SharedRandomFloat( CTerrorPlayer::FireBullet SpreadDir 2122522781 6 )
CLIENT: SharedRandomFloat( CTerrorPlayer::FireBullet Spread 998020796 7 )
CLIENT: SharedRandomFloat( CTerrorPlayer::FireBullet SpreadDir 805972788 7 )
CLIENT: SharedRandomFloat( CTerrorPlayer::FireBullet Spread 392955131 8 )
CLIENT: SharedRandomFloat( CTerrorPlayer::FireBullet SpreadDir 455035041 8 )
CLIENT: SharedRandomInt( HorizKickDir -783437243 0 )

 */
public void OnPluginStart()
{
	Handle conf = LoadGameConfigFile(GAMEDATA_FILE);
	if (!conf)
		SetFailState("Missing gamedata \"" ... GAMEDATA_FILE... "\"");

	Handle hDetour = DHookCreateFromConf(conf, "SharedRandomFloat");
	if (!hDetour)
		SetFailState("Missing detour setup \"SharedRandomFloat\"");

	if (!DHookEnableDetour(hDetour, false, SharedRandomFloat))
		SetFailState("Failed to enable detour \"SharedRandomFloat\"");

	if (!DHookEnableDetour(hDetour, true, SharedRandomFloatPost))
		SetFailState("Failed to detour post \"SharedRandomFloat\".");

	delete conf;

	g_hOverrideValues = CreateTrie();

	// Range: +/- CWeaponInfo data value
	g_hOverrideValues.SetValue("CTerrorGun::FireBullet HorizSpread", 0.5);

	// Range: +/- CWeaponInfo data value
	g_hOverrideValues.SetValue("CTerrorGun::FireBullet VertSpread", 0.5);

	// Range: +/- CWeaponInfo data value (probably spread/maxspread?)
	g_hOverrideValues.SetValue("CTerrorPlayer::FireBullet Spread", 0.5);
	// Range: 0.0 to 180.0
	g_hOverrideValues.SetValue("CTerrorPlayer::FireBullet SpreadDir", 0.5);
}

// https://github.com/ValveSoftware/source-sdk-2013/blob/master/mp/src/game/shared/util_shared.h#L57-L68
// This function is called when the server will consume a shared random value.
// We can override this value and not advance the RNG.
public MRESReturn SharedRandomFloat(Handle hReturn, Handle hParams)
{
	// Store the current random shared name
	static char sharedname[128];
	DHookGetParamString(hParams, 1, sharedname, sizeof(sharedname));

	float flMinVal       = DHookGetParam(hParams, 2);
	float flMaxVal       = DHookGetParam(hParams, 3);
	int   additionalSeed = DHookGetParam(hParams, 4);

	float overrideValue = 0.0;
	if (OverrideSharedRandom(sharedname, flMinVal, flMaxVal, additionalSeed, overrideValue))
	{
		return MRES_Override;
	}
	return MRES_Ignored;
}

public MRESReturn SharedRandomFloatPost(Handle hReturn, Handle hParams)
{
	// Store the current random shared name
	static char sharedname[128];
	DHookGetParamString(hParams, 1, sharedname, sizeof(sharedname));

	float flMinVal       = DHookGetParam(hParams, 2);
	float flMaxVal       = DHookGetParam(hParams, 3);
	int   additionalSeed = DHookGetParam(hParams, 4);

	float randomValue = DHookGetReturn(hReturn);
	LogMessage("SharedRandomfloat(%s, %f, %f, %d) = %f", sharedname, flMinVal, flMaxVal, additionalSeed, randomValue);
	return MRES_Ignored;
}

bool OverrideSharedRandom(const char[] sharedname, float flMinVal, float flMaxVal, int additionalSeed, float& overrideValue)
{
	LogMessage("SharedRandomfloat(%s, %f, %f, %d)", sharedname, flMinVal, flMaxVal, additionalSeed);

	if (g_hOverrideValues.ContainsKey(sharedname))
	{
		// Override this value based on override settings.
		// Uses a scalar "factor" to determine where in the requested range to return a value.
		// e.g.
		//   factor 0.0 -> Returns min value.
		//   factor 1.0 -> Returns max value.
		//   factor 0.5 -> Returns a value halfway between min and max
		float factor = 0.0;
		g_hOverrideValues.GetValue(sharedname, factor);
		overrideValue = flMinVal + ((flMaxVal - flMinVal) * factor);
		return true;
	}
	// Don't override this value.
	return false;
}