#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <left4dhooks> //#include <left4downtown>

#define DEBUG						0

#define TEAM_INFECTED				3
#define TANK_ZOMBIE_CLASS			8

#define INT_WEAPON_MAX_ATTRS		sizeof(iIntWeaponAttributes)
#define FLOAT_WEAPON_MAX_ATTRS		sizeof(iFloatWeaponAttributes)

#define PLUGIN_WEAPON_MAX_ATTRS		(GAME_WEAPON_MAX_ATTRS + 1) // Including: tankdamagemult(Tank damage multiplier), the plugin is responsible for this attribute
#define GAME_WEAPON_MAX_ATTRS		(INT_WEAPON_MAX_ATTRS + FLOAT_WEAPON_MAX_ATTRS)

#define MAX_ATTRS_NAME_LENGTH		32
#define MAX_WEAPON_NAME_LENGTH		64
#define MAX_ATTRS_VALUE_LENGTH		32

enum
{
	eDisableCommand = 0,
	eShowToOnlyAdmin,
	eShowToEveryone
};

enum MessageTypeFlag
{
	eServerPrint =	(1 << 0),
	ePrintChatAll =	(1 << 1),
	eLogError =		(1 << 2)
};

static const L4D2IntWeaponAttributes iIntWeaponAttributes[] =
{
	L4D2IWA_Damage,
	L4D2IWA_Bullets,
	L4D2IWA_ClipSize,
	L4D2IWA_Bucket,
	L4D2IWA_Tier // L4D2 only
};

static const L4D2FloatWeaponAttributes iFloatWeaponAttributes[] =
{
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
	L4D2FWA_VerticalPunch,
	L4D2FWA_HorizontalPunch, // Requires "z_gun_horiz_punch" cvar changed to "1".
	L4D2FWA_GainRange,
	L4D2FWA_ReloadDuration
};

static const char sWeaponAttrNames[PLUGIN_WEAPON_MAX_ATTRS][MAX_ATTRS_NAME_LENGTH] = 
{
	"Damage",
	"Bullets",
	"Clip Size",
	"Bucket",
	"Tier",
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
	"Vertical punch",
	"Horizontal punch",
	"Gain range",
	"Reload duration",
	"Tank damage multiplier"
};

static const char sWeaponAttrShortName[PLUGIN_WEAPON_MAX_ATTRS][MAX_ATTRS_NAME_LENGTH] =
{
	"damage",
	"bullets",
	"clipsize",
	"bucket",
	"tier",
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
	"verticalpunch",
	"horizpunch",
	"gainrange",
	"reloadduration",
	"tankdamagemult"
};

ConVar
	hHideWeaponAttributes = null;

bool
	bTankDamageEnableAttri = false;

StringMap
	hTankDamageAttri = null,
	hDefaultWeaponAttributes[GAME_WEAPON_MAX_ATTRS] = {null, ...};

public Plugin myinfo =
{
	name = "L4D2 Weapon Attributes",
	author = "Jahze, A1m`, Forgetest",
	version = "2.6",
	description = "Allowing tweaking of the attributes of all weapons"
};

public void OnPluginStart()
{
	hHideWeaponAttributes = CreateConVar( \
		"sm_weapon_hide_attributes", \
		"2", \
		"Allows to customize the command 'sm_weapon_attributes'. \
		0 - disable command, 1 - show weapons attribute to admin only. 2 - show weapon attributes to everyone.", \
		_, true, 0.0, true, 2.0 \
	);
	
	hTankDamageAttri = new StringMap();
	
	for (int iAtrriIndex = 0; iAtrriIndex < GAME_WEAPON_MAX_ATTRS; iAtrriIndex++) {
		hDefaultWeaponAttributes[iAtrriIndex] = new StringMap();
	}

	RegServerCmd("sm_weapon", Cmd_Weapon);
	RegServerCmd("sm_weapon_attributes_reset", Cmd_WeaponAttributesReset);
	
	RegConsoleCmd("sm_weapon_attributes", Cmd_WeaponAttributes);
}

public void OnPluginEnd()
{
	ResetWeaponAttributes(true);
}

public void OnClientPutInServer(int client)
{
	if (bTankDamageEnableAttri)
		SDKHook(client, SDKHook_OnTakeDamage, DamageBuffVsTank);
}

void OnTankDamageEnableAttriChanged(bool newValue)
{
	if (!bTankDamageEnableAttri && newValue)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
				SDKHook(i, SDKHook_OnTakeDamage, DamageBuffVsTank);
		}
	}
	else if (bTankDamageEnableAttri && !newValue)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
				SDKUnhook(i, SDKHook_OnTakeDamage, DamageBuffVsTank);
		}
	}
	
	bTankDamageEnableAttri = newValue;
}

public Action Cmd_Weapon(int args)
{
	if (args < 3) {
		PrintDebug(eLogError|eServerPrint, "Syntax: sm_weapon <weapon> <attr> <value>.");
		return Plugin_Handled;
	}

	char sWeaponName[MAX_WEAPON_NAME_LENGTH];
	GetCmdArg(1, sWeaponName, sizeof(sWeaponName));
	
	if (strncmp(sWeaponName, "weapon_", 7)) {
		Format(sWeaponName, sizeof(sWeaponName), "weapon_%s", sWeaponName);
	}
	
	if (!L4D2_IsValidWeapon(sWeaponName)) {
		PrintDebug(eLogError|eServerPrint, "Bad weapon name: %s.", sWeaponName);
		return Plugin_Handled;
	}
	
	char sAttrName[MAX_ATTRS_NAME_LENGTH];
	GetCmdArg(2, sAttrName, sizeof(sAttrName));
	
	int iAttrIdx = GetWeaponAttributeIndex(sAttrName);

	if (iAttrIdx == -1) {
		PrintDebug(eLogError|eServerPrint, "Bad attribute name: %s.", sAttrName);
		return Plugin_Handled;
	}
	
	char sAttrValue[MAX_ATTRS_VALUE_LENGTH];
	GetCmdArg(3, sAttrValue, sizeof(sAttrValue));
	
	if (iAttrIdx < INT_WEAPON_MAX_ATTRS) {
		int iValue = StringToInt(sAttrValue);
		SetWeaponAttributeInt(sWeaponName, iAttrIdx, iValue);
		PrintToServer("%s for %s set to %d.", sWeaponAttrNames[iAttrIdx], sWeaponName, iValue);
	} else {
		float fValue = StringToFloat(sAttrValue);
		if (iAttrIdx < GAME_WEAPON_MAX_ATTRS) {
			SetWeaponAttributeFloat(sWeaponName, iAttrIdx, fValue);
			PrintToServer("%s for %s set to %.2f.", sWeaponAttrNames[iAttrIdx], sWeaponName, fValue);
		} else {
			if (fValue <= 0.0) {
				if (!hTankDamageAttri.Remove(sWeaponName)) {
					PrintDebug(eLogError|eServerPrint, "Сheck weapon attribute '%s' value, cannot be set below zero or zero. Set the value: %f!", sAttrName, fValue);
					return Plugin_Handled;
				}
				
				PrintToServer("Tank Damage Multiplier (tankdamagemult) attribute reset for %s weapon!", sWeaponName);
				OnTankDamageEnableAttriChanged(hTankDamageAttri.Size != 0);
				return Plugin_Handled;
			}
			
			OnTankDamageEnableAttriChanged(true);
			hTankDamageAttri.SetValue(sWeaponName, fValue);
			PrintToServer("%s for %s set to %.2f", sWeaponAttrNames[iAttrIdx], sWeaponName, fValue);
		}
	}

	return Plugin_Handled;
}

public Action Cmd_WeaponAttributes(int client, int args)
{
	int iCvarValue = hHideWeaponAttributes.IntValue;

	if (iCvarValue == eDisableCommand || 
		(iCvarValue == eShowToOnlyAdmin && client != 0 && GetUserAdmin(client) == INVALID_ADMIN_ID)
	) {
		ReplyToCommand(client, "This command is not available to you!");
		return Plugin_Handled;
	}
	
	if (args < 1) {
		ReplyToCommand(client, "Syntax: sm_weapon_attributes <weapon>.");
		return Plugin_Handled;
	}
	
	char sWeaponName[MAX_WEAPON_NAME_LENGTH];
	GetCmdArg(1, sWeaponName, sizeof(sWeaponName));
	
	if (strncmp(sWeaponName, "weapon_", 7)) {
		Format(sWeaponName, sizeof(sWeaponName), "weapon_%s", sWeaponName);
	}
	
	if (!L4D2_IsValidWeapon(sWeaponName)) {
		ReplyToCommand(client, "Bad weapon name: %s.", sWeaponName);
		return Plugin_Handled;
	}

	ReplyToCommand(client, "Weapon stats for %s:", sWeaponName);

	for (int iAtrriIndex = 0; iAtrriIndex < GAME_WEAPON_MAX_ATTRS; iAtrriIndex++) {
		if (iAtrriIndex < INT_WEAPON_MAX_ATTRS) {
			int iValue = GetWeaponAttributeInt(sWeaponName, iAtrriIndex);
			ReplyToCommand(client, "%s: %d.", sWeaponAttrNames[iAtrriIndex], iValue);
		} else {
			float fValue = GetWeaponAttributeFloat(sWeaponName, iAtrriIndex);
			ReplyToCommand(client, "%s: %.2f.", sWeaponAttrNames[iAtrriIndex], fValue);
		}
	}
	
	float fBuff = 0.0;
	if (hTankDamageAttri.GetValue(sWeaponName, fBuff)) {
		ReplyToCommand(client, "%s: %.2f.", sWeaponAttrNames[GAME_WEAPON_MAX_ATTRS], fBuff);
	}
	
	return Plugin_Handled;
}

public Action Cmd_WeaponAttributesReset(int args)
{
	OnTankDamageEnableAttriChanged(false);
	
	bool IsReset = (hTankDamageAttri.Size > 0);
	hTankDamageAttri.Clear();
	
	if (IsReset) {
		PrintToServer("Tank Damage Multiplier (tankdamagemult) attribute reset for all weapons!");
	}
	
	int iCount = ResetWeaponAttributes();
	if (iCount == 0) {
		PrintToServer("Weapon attributes were not reset, because no weapon attributes were saved!");
		return Plugin_Handled;
	}
	
	PrintToServer("The weapon attributes for all saved weapons have been reset successfully. Number of reset weapon attributes: %d!", iCount);

	return Plugin_Handled;
}

/*
This just returns the director variable

bool __cdecl CDirector::IsTankInPlay(CDirector *this)
{
	return *((_DWORD *)this + 64) > 0;
}
*/
public Action DamageBuffVsTank(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!(damagetype & DMG_BULLET)) {
		return Plugin_Continue;
	}
	
	/*if (!L4D2_IsTankInPlay()) { //left4dhooks & left4donwtown
		return Plugin_Continue;
	}*/

	if (!IsValidClient(attacker) || !IsTank(victim)) {
		return Plugin_Continue;
	}

	char sWeaponName[MAX_WEAPON_NAME_LENGTH];
	GetClientWeapon(attacker, sWeaponName, sizeof(sWeaponName));
	
	float fBuff = 0.0;
	if (hTankDamageAttri.GetValue(sWeaponName, fBuff)) {
		damage *= fBuff;
		
		#if DEBUG
			PrintDebug(eLogError|eServerPrint|ePrintChatAll, "Damage to the tank %N(%d) is set %f. Attacker: %N(%d), weapon: %s.", victim, victim, damage, attacker, attacker, sWeaponName);
		#endif
		
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

int GetWeaponAttributeIndex(const char[] sAttrName)
{
	for (int i = 0; i < PLUGIN_WEAPON_MAX_ATTRS; i++) {
		if (strcmp(sAttrName, sWeaponAttrShortName[i]) == 0) {
			return i;
		}
	}

	return -1;
}

int GetWeaponAttributeInt(const char[] sWeaponName, int iAtrriIndex)
{
	return L4D2_GetIntWeaponAttribute(sWeaponName, iIntWeaponAttributes[iAtrriIndex]);
}

float GetWeaponAttributeFloat(const char[] sWeaponName, int iAtrriIndex)
{
	return L4D2_GetFloatWeaponAttribute(sWeaponName, iFloatWeaponAttributes[iAtrriIndex - INT_WEAPON_MAX_ATTRS]);
}

void SetWeaponAttributeInt(const char[] sWeaponName, int iAtrriIndex, int iSetValue, bool bIsSaveDefValue = true)
{
	if (bIsSaveDefValue) {
		int iDefValue = 0;
		if (!hDefaultWeaponAttributes[iAtrriIndex].GetValue(sWeaponName, iDefValue)) {
			iDefValue = GetWeaponAttributeInt(sWeaponName, iAtrriIndex);
			hDefaultWeaponAttributes[iAtrriIndex].SetValue(sWeaponName, iDefValue, true);
			
			#if DEBUG
				PrintDebug(eLogError|eServerPrint|ePrintChatAll, "The default int value '%d' of the attribute for the weapon '%s' is saved! Attributes index: %d.", iDefValue, sWeaponName, iAtrriIndex);
			#endif
		}
	}
	
	L4D2_SetIntWeaponAttribute(sWeaponName, iIntWeaponAttributes[iAtrriIndex], iSetValue);

#if DEBUG
	PrintDebug(eLogError|eServerPrint|ePrintChatAll, "Weapon attribute int set. %s - Trying to set: %d, was set: %d.", sWeaponName, iSetValue, GetWeaponAttributeInt(sWeaponName, iAtrriIndex));
#endif
}

void SetWeaponAttributeFloat(const char[] sWeaponName, int iAtrriIndex, float fSetValue, bool bIsSaveDefValue = true)
{
	if (bIsSaveDefValue) {
		float fDefValue = 0.0;
		if (!hDefaultWeaponAttributes[iAtrriIndex].GetValue(sWeaponName, fDefValue)) {
			fDefValue = GetWeaponAttributeFloat(sWeaponName, iAtrriIndex);
			hDefaultWeaponAttributes[iAtrriIndex].SetValue(sWeaponName, fDefValue, true);
			
			#if DEBUG
				PrintDebug(eLogError|eServerPrint|ePrintChatAll, "The default float value '%f' of the attribute for the weapon '%s' is saved! Attributes index: %d.", fDefValue, sWeaponName, iAtrriIndex);
			#endif
		}
	}

	L4D2_SetFloatWeaponAttribute(sWeaponName, iFloatWeaponAttributes[iAtrriIndex - INT_WEAPON_MAX_ATTRS], fSetValue);

#if DEBUG
	PrintDebug(eLogError|eServerPrint|ePrintChatAll, "Weapon attribute float set. %s - Trying to set: %f, was set: %f.", sWeaponName, fSetValue, GetWeaponAttributeFloat(sWeaponName, iAtrriIndex));
#endif
}

int ResetWeaponAttributes(bool bIsClearArray = false)
{
	float fDefValue = 0.0, fCurValue = 0.0;
	int iDefValue = 0, iCurValue = 0;

	char sWeaponName[MAX_WEAPON_NAME_LENGTH];
	StringMapSnapshot hTrieSnapshot = null;
	int iCount = 0, iSize = 0;
	
	for (int iAtrriIndex = 0; iAtrriIndex < GAME_WEAPON_MAX_ATTRS; iAtrriIndex++) {
		hTrieSnapshot = hDefaultWeaponAttributes[iAtrriIndex].Snapshot();
		iSize = hTrieSnapshot.Length;
		
		for (int i = 0; i < iSize; i++) {
			hTrieSnapshot.GetKey(i, sWeaponName, sizeof(sWeaponName));
			if (iAtrriIndex < INT_WEAPON_MAX_ATTRS) {
				hDefaultWeaponAttributes[iAtrriIndex].GetValue(sWeaponName, iDefValue);
				
				iCurValue = GetWeaponAttributeInt(sWeaponName, iAtrriIndex);
				if (iCurValue != iDefValue) {
					SetWeaponAttributeInt(sWeaponName, iAtrriIndex, iDefValue, false);
					iCount++;
				}
				
				#if DEBUG
					PrintDebug(eLogError|eServerPrint|ePrintChatAll, "Reset Attributes: %s - '%s' set default to %d. Current value: %d.", sWeaponName, sWeaponAttrShortName[iAtrriIndex], iDefValue, iCurValue);
				#endif
			} else {
				hDefaultWeaponAttributes[iAtrriIndex].GetValue(sWeaponName, fDefValue);
				
				fCurValue = GetWeaponAttributeFloat(sWeaponName, iAtrriIndex);
				if (fCurValue != fDefValue) {
					SetWeaponAttributeFloat(sWeaponName, iAtrriIndex, fDefValue, false);
					iCount++;
				}
				
				#if DEBUG
					PrintDebug(eLogError|eServerPrint|ePrintChatAll, "Reset Attributes: %s - '%s' set default to %f. Current value: %f.", sWeaponName, sWeaponAttrShortName[iAtrriIndex], fDefValue, fCurValue);
				#endif
			}
		}
		
		if (bIsClearArray) {
			hDefaultWeaponAttributes[iAtrriIndex].Clear();
		}
	
		delete hTrieSnapshot;
		hTrieSnapshot = null;
	}

#if DEBUG
	PrintDebug(eLogError|eServerPrint|ePrintChatAll, "Reset all attributes. Count: %d.", iCount);
#endif

	return iCount;
}

bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients);
}

bool IsTank(int client)
{
	return (IsValidClient(client)
		&& IsClientInGame(client)
		&& GetClientTeam(client) == TEAM_INFECTED
		&& GetEntProp(client, Prop_Send, "m_zombieClass") == TANK_ZOMBIE_CLASS
		&& IsPlayerAlive(client)
	);
}

void PrintDebug(MessageTypeFlag iType, const char[] Message, any ...)
{
	char DebugBuff[256];
	VFormat(DebugBuff, sizeof(DebugBuff), Message, 3);

	if (iType & eServerPrint) {
		PrintToServer(DebugBuff);
	}
	
	if (iType & ePrintChatAll) {
		PrintToChatAll(DebugBuff);
	}
	
	if (iType & eLogError) {
		LogError(DebugBuff);
	}
}
