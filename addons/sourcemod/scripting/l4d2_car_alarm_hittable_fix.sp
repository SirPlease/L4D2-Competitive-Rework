#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define GAMEDATA			"l4d2_car_alarm_bots"
#define MAX_BYTES			33
int g_ByteCount, g_ByteMatch;
int g_ByteSaved[MAX_BYTES];
Address g_Address;

ConVar 
	g_hCarAlarmSettings,
	g_hCarTouchCapped,
	g_hCarAI;

int FLAGS[3] = {
	1 << 0, // Trigger Car Alarm on Survivor Touch
	1 << 1, // Trigger Car Alarm disabled when hit by another Hittable.
};

int iFlags;
bool bCarTouchCapped;
bool bAI;


// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo = 
{
	name = "L4D2 Car Alarm Fixes",
	author = "Sir & Silvers (Gamedata and general idea from l4d2_car_alarm_bots)",
	description = "Disables the Car Alarm when a Tank hittable hits the alarmed car and makes sure the Car Alarm triggers whenever a Survivor touches it",
	version = "1.2",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	// ====================================================================================================
	// GAMEDATA
	// ====================================================================================================
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if( FileExists(sPath) == false ) SetFailState("\n==========\nMissing required file: \"%s\".\nRead installation instructions again.\n==========", sPath);

	Handle hGameData = LoadGameConfigFile(GAMEDATA);
	if( hGameData == null ) SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	g_Address = GameConfGetAddress(hGameData, "CCarProp::InputSurvivorStandingOnCar");
	if( !g_Address ) SetFailState("Failed to load \"CCarProp::InputSurvivorStandingOnCar\" address.");

	int offset = GameConfGetOffset(hGameData, "InputSurvivorStandingOnCar_Offset");
	if( offset == -1 ) SetFailState("Failed to load \"InputSurvivorStandingOnCar_Offset\" offset.");

	g_ByteMatch = GameConfGetOffset(hGameData, "InputSurvivorStandingOnCar_Byte");
	if( g_ByteMatch == -1 ) SetFailState("Failed to load \"InputSurvivorStandingOnCar_Byte\" byte.");

	g_ByteCount = GameConfGetOffset(hGameData, "InputSurvivorStandingOnCar_Count");
	if( g_ByteCount == -1 ) SetFailState("Failed to load \"InputSurvivorStandingOnCar_Count\" count.");
	if( g_ByteCount > MAX_BYTES ) SetFailState("Error: byte count exceeds scripts defined value (%d/%d).", g_ByteCount, MAX_BYTES);

	g_Address += view_as<Address>(offset);

	for( int i = 0; i < g_ByteCount; i++ )
	{
		g_ByteSaved[i] = LoadFromAddress(g_Address + view_as<Address>(i), NumberType_Int8);
	}
	if( g_ByteSaved[0] != g_ByteMatch ) SetFailState("Failed to load, byte mis-match. %d (0x%02X != 0x%02X)", offset, g_ByteSaved[0], g_ByteMatch);

	delete hGameData;

	// =================================================================================================
	// CONVARS
	// =================================================================================================

	g_hCarAlarmSettings = CreateConVar("l4d2_car_alarm_settings", "3", "Bitmask: 1-Trigger Alarm on Survivor Touch/ 2-Disable Alarm when a Hittable hits the Alarm Car", FCVAR_NOTIFY);
	g_hCarTouchCapped   = CreateConVar("l4d2_car_alarm_touch_capped", "1", "Only add the additional car alarm trigger when the Survivor is capped by an Infected when touching the car? (Requires bitmask settings)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hCarAI            = CreateConVar("l4d2_car_alarm_touch_ai", "0", "Care about AI Survivors touching the car? (Default vanilla = 0) Requires bitmask settings", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	iFlags          = g_hCarAlarmSettings.IntValue;
	bCarTouchCapped = g_hCarTouchCapped.BoolValue;
	bAI             = g_hCarAI.BoolValue;
	g_hCarAlarmSettings.AddChangeHook(ChangedConVars);
	g_hCarTouchCapped.AddChangeHook(ChangedConVars);
	g_hCarAI.AddChangeHook(ChangedConVars);
}

public void OnPluginEnd()
{
	PatchAddress(false);
}

// ====================================================================================================
//					PATCH / HOOK
// ====================================================================================================
void PatchAddress(int patch)
{
	static bool patched;

	if( !patched && patch )
	{
		patched = true;
		for( int i = 0; i < g_ByteCount; i++ )
			StoreToAddress(g_Address + view_as<Address>(i), g_ByteMatch == 0x0F ? 0x90 : 0xEB, NumberType_Int8);
	}
	else if( patched && !patch )
	{
		patched = false;
		for( int i = 0; i < g_ByteCount; i++ )
			StoreToAddress(g_Address + view_as<Address>(i), g_ByteSaved[i], NumberType_Int8);
	}
}

// ====================================================================================================
//					EVENTS
// ====================================================================================================
public void OnEntityCreated(int entity, const char[] classname)
{
	if(strcmp(classname, "prop_car_alarm") == 0)
	  SDKHook(entity, SDKHook_Touch, OnTouch);
}

public void OnTouch(int car, int other)
{
	// Is the other entity a Survivor?
	if ((iFlags & FLAGS[0]) && other >= 1 && other <= MaxClients && GetClientTeam(other) == 2)
	{
		// We don't want the AI to trigger the car alarm.
		if (!bAI && IsFakeClient(other))
		  return;

		// We only care about capped players touching the car.
		if (bCarTouchCapped && !IsPlayerCapped(other))
		  return;

		PatchAddress(true);
		AcceptEntityInput(car, "SurvivorStandingOnCar", other, other);
		PatchAddress(false);

		// Unhook car, we don't need it anymore.
		SDKUnhook(car, SDKHook_Touch, OnTouch);
	}
	
	// Is the other entity a Hittable car?
	else if ((iFlags & FLAGS[1]) && IsTankHittable(other))
	{
		// This returns 1 on every hittable at all times.
		if (GetEntProp(other, Prop_Send, "m_hasTankGlow") > 0)
		{
			// Disable the Car Alarm
			AcceptEntityInput(car, "Disable");

			// Fake damage to Car to stop the glass from still blinking, delay it to prevent issues.
			CreateTimer(0.3, DisableAlarm, car);

			// Unhook car, we don't need it anymore.
			SDKUnhook(car, SDKHook_Touch, OnTouch);
		}
	}
}

public Action DisableAlarm(Handle timer, any car)
{
	int Tank = -1;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidTank(i))
		{
			Tank = i;
			break;
		}
	}

	if (Tank != -1) 
	  SDKHooks_TakeDamage(car, Tank, Tank, 0.0);

	return Plugin_Stop;
}


// ====================================================================================================
//					STOCKS
// ====================================================================================================
stock bool IsValidTank(int client) 
{ 
	if (client <= 0 || client > MaxClients || !IsClientConnected(client)) return false;
	return (IsClientInGame(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 8); 
}

stock bool IsTankHittable(int iEntity)
{
	if (!IsValidEntity(iEntity)) 
	  return false;
	
	char className[64];
	
	GetEdictClassname(iEntity, className, sizeof(className));

	if (StrEqual(className, "prop_physics")) 
	{
		if (GetEntProp(iEntity, Prop_Send, "m_hasTankGlow", 1)) 
		  return true;
	}
	else if (StrEqual(className, "prop_car_alarm")) 
	  return true;
	
	return false;
}

stock bool IsPlayerCapped(int client)
{
	if (GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0 || 
	GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0 ||
	GetEntPropEnt(client, Prop_Send, "m_carryAttacker") > 0)
	  return true;

	return false;
}

void ChangedConVars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	iFlags          = g_hCarAlarmSettings.IntValue;
	bCarTouchCapped = g_hCarTouchCapped.BoolValue;
	bAI             = g_hCarAI.BoolValue;
}