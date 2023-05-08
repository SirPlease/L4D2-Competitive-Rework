#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <left4dhooks> //#include <left4downtown>
#include <dhooks>
#include <colors>

#define DEBUG						0

#define GAMEDATA_FILE				"l4d2_weapon_attributes"

#define TEAM_INFECTED				3
#define TANK_ZOMBIE_CLASS			8

#define INT_WEAPON_MAX_ATTRS		sizeof(iIntWeaponAttributes)
#define FLOAT_WEAPON_MAX_ATTRS		sizeof(iFloatWeaponAttributes)

#define GAME_WEAPON_MAX_ATTRS		(INT_WEAPON_MAX_ATTRS + FLOAT_WEAPON_MAX_ATTRS)
#define PLUGIN_WEAPON_MAX_ATTRS		(GAME_WEAPON_MAX_ATTRS + 2) // Including: tankdamagemult(Tank damage multiplier), reloaddurationmult(Reload duration multiplier), the plugin is responsible for these attributes

#define INT_MELEE_MAX_ATTRS			sizeof(iIntMeleeAttributes)
#define BOOL_MELEE_MAX_ATTRS		sizeof(iBoolMeleeAttributes)
#define FLOAT_MELEE_MAX_ATTRS		sizeof(iFloatMeleeAttributes)

#define GAME_MELEE_MAX_ATTRS		(INT_MELEE_MAX_ATTRS + BOOL_MELEE_MAX_ATTRS + FLOAT_MELEE_MAX_ATTRS)
#define PLUGIN_MELEE_MAX_ATTRS		(GAME_MELEE_MAX_ATTRS + 1) // Including: tankdamagemult(Tank damage multiplier), the plugin is responsible for this attribute

#define MAX_ATTRS_NAME_LENGTH		32
#define MAX_WEAPON_NAME_LENGTH		64
#define MAX_ATTRS_VALUE_LENGTH		32

enum
{
	eDisableCommand = 0,
	eShowToOnlyAdmin,
	eShowToEveryone,
};

enum MessageTypeFlag
{
	eServerPrint =	(1 << 0),
	ePrintChatAll =	(1 << 1),
	eLogError =		(1 << 2)
};

enum struct Resetable
{
	any defVal;
	any curVal;
}

static const L4D2IntWeaponAttributes iIntWeaponAttributes[] =
{
	L4D2IWA_Damage,
	L4D2IWA_Bullets,
	L4D2IWA_ClipSize,
	L4D2IWA_Bucket,
	L4D2IWA_Tier, // L4D2 only
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
	L4D2FWA_ReloadDuration,
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
	
	"Tank damage multiplier", // the plugin is responsible for this attribute
	"Reload duration multiplier", // the plugin is responsible for this attribute
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
	
	"tankdamagemult", // the plugin is responsible for this attribute
	"reloaddurationmult", // the plugin is responsible for this attribute
};

static const L4D2IntMeleeWeaponAttributes iIntMeleeAttributes[] = 
{
	L4D2IMWA_DamageFlags,
	L4D2IMWA_RumbleEffect,
};

static const L4D2BoolMeleeWeaponAttributes iBoolMeleeAttributes[] = 
{
	L4D2BMWA_Decapitates,
};

static const L4D2FloatMeleeWeaponAttributes iFloatMeleeAttributes[] = 
{
	L4D2FMWA_Damage,
	L4D2FMWA_RefireDelay,
	L4D2FMWA_WeaponIdleTime,
};

static const char sMeleeAttrNames[PLUGIN_MELEE_MAX_ATTRS][MAX_ATTRS_NAME_LENGTH] = 
{
	"Damage flags",
	"Rumble effect",
	"Decapitates",
	"Damage",
	"Refire delay",
	"Weapon idle time",
	
	"Tank damage multiplier", // the plugin is responsible for this attribute
};

static const char sMeleeAttrShortName[PLUGIN_MELEE_MAX_ATTRS][MAX_ATTRS_NAME_LENGTH] =
{
	"damageflags",
	"rumbleeffect",
	"decapitates",
	"damage",
	"refiredelay",
	"weaponidletime",
	
	"tankdamagemult", // the plugin is responsible for this attribute
};


ConVar
	hHideWeaponAttributes = null;

bool
	bTankDamageEnableAttri = false,
	bReloadDurationEnableAttri = false;

StringMap
	hTankDamageAttri = null,
	hReloadDurationAttri = null,
	hDefaultWeaponAttributes[GAME_WEAPON_MAX_ATTRS] = {null, ...},
	hDefaultMeleeAttributes[GAME_MELEE_MAX_ATTRS] = {null, ...};

DynamicDetour
	hReloadDurationDetour;

public Plugin myinfo =
{
	name = "L4D2 Weapon Attributes",
	author = "Jahze, A1m`, Forgetest",
	version = "3.0.1",
	description = "Allowing tweaking of the attributes of all weapons"
};

public void OnPluginStart()
{
	GameData gd = new GameData(GAMEDATA_FILE);
	if (!gd)
		SetFailState("Missing gamedata \""...GAMEDATA_FILE..."\"");
	
	hReloadDurationDetour = DynamicDetour.FromConf(gd, "CBaseShotgun::GetReloadDurationModifier");
	if (!hReloadDurationDetour)
		SetFailState("Missing detour setup \"CBaseShotgun::GetReloadDurationModifier\"");
	
	delete gd;
	
	hHideWeaponAttributes = CreateConVar( \
		"sm_weapon_hide_attributes", \
		"2", \
		"Allows to customize the command 'sm_weapon_attributes'. \
		0 - disable command, 1 - show weapons attribute to admin only. 2 - show weapon attributes to everyone.", \
		_, true, 0.0, true, 2.0 \
	);
	
	hTankDamageAttri = new StringMap();
	hReloadDurationAttri = new StringMap();
	
	for (int iAtrriIndex = 0; iAtrriIndex < GAME_WEAPON_MAX_ATTRS; iAtrriIndex++) {
		hDefaultWeaponAttributes[iAtrriIndex] = new StringMap();
	}
	for (int iAtrriIndex = 0; iAtrriIndex < GAME_MELEE_MAX_ATTRS; iAtrriIndex++) {
		hDefaultMeleeAttributes[iAtrriIndex] = new StringMap();
	}

	RegServerCmd("sm_weapon", Cmd_Weapon);
	RegServerCmd("sm_weapon_attributes_reset", Cmd_WeaponAttributesReset);
	
	RegConsoleCmd("sm_weaponstats", Cmd_WeaponAttributes);
	RegConsoleCmd("sm_weapon_attributes", Cmd_WeaponAttributes);
}

public void OnPluginEnd()
{
	ResetWeaponAttributes(true);
	ResetMeleeAttributes(true);
}

public void OnClientPutInServer(int client)
{
	if (bTankDamageEnableAttri)
		SDKHook(client, SDKHook_OnTakeDamage, DamageBuffVsTank);
}

public void OnConfigsExecuted()
{
	// Weapon info may get reloaded, and supported melees
	// are different between campaigns.
	// Here we are reloading all the attributes set by our own.
	
	ResetWeaponAttributes(false);
	ResetMeleeAttributes(false);
}

void OnTankDamageEnableAttriChanged(bool newValue)
{
	if (bTankDamageEnableAttri != newValue) {
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i)) {
				newValue ? SDKHook(i, SDKHook_OnTakeDamage, DamageBuffVsTank) : SDKUnhook(i, SDKHook_OnTakeDamage, DamageBuffVsTank);
			}
		}
		
		bTankDamageEnableAttri = newValue;
	}
}

void OnReloadDurationEnableAttriChanged(bool newValue)
{
	if (bReloadDurationEnableAttri != newValue) {
		if (!(newValue
				 ?
				hReloadDurationDetour.Enable(Hook_Pre, DTR_CBaseShotgun__GetReloadDurationModifier)
				: hReloadDurationDetour.Disable(Hook_Pre, DTR_CBaseShotgun__GetReloadDurationModifier)))
			SetFailState("Failed to detour \"CBaseShotgun::GetReloadDurationModifier__skip_constant\"");
		
		bReloadDurationEnableAttri = newValue;
	}
}

public Action Cmd_Weapon(int args)
{
	if (args < 3) {
		PrintDebug(eLogError|eServerPrint, "Syntax: sm_weapon <weapon> <attr> <value>.");
		return Plugin_Handled;
	}

	char sWeaponName[MAX_WEAPON_NAME_LENGTH];
	GetCmdArg(1, sWeaponName, sizeof(sWeaponName));
	
	if (strncmp(sWeaponName, "weapon_", 7) == 0) {
		strcopy(sWeaponName, sizeof(sWeaponName), sWeaponName[7]);
	}
	
	char sAttrName[MAX_ATTRS_NAME_LENGTH];
	GetCmdArg(2, sAttrName, sizeof(sAttrName));
	
	char sAttrValue[MAX_ATTRS_VALUE_LENGTH];
	GetCmdArg(3, sAttrValue, sizeof(sAttrValue));
	
	if (IsSupportedMelee(sWeaponName)) {
		int iAttrIdx = GetMeleeAttributeIndex(sAttrName);
	
		if (iAttrIdx == -1) {
			PrintDebug(eLogError|eServerPrint, "Bad attribute name: %s.", sAttrName);
			return Plugin_Handled;
		}
		
		if (iAttrIdx < INT_MELEE_MAX_ATTRS) {
			int iValue = StringToInt(sAttrValue);
			SetMeleeAttributeInt(sWeaponName, iAttrIdx, iValue);
			PrintToServer("%s for %s set to %d.", sMeleeAttrNames[iAttrIdx], sWeaponName, iValue);
		} else if (iAttrIdx < INT_MELEE_MAX_ATTRS + BOOL_MELEE_MAX_ATTRS) {
			bool bValue = StringToBool(sAttrValue);
			SetMeleeAttributeBool(sWeaponName, iAttrIdx, bValue);
			PrintToServer("%s for %s set to %s.", sMeleeAttrNames[iAttrIdx], sWeaponName, bValue ? "true" : "false");
		} else {
			float fValue = StringToFloat(sAttrValue);
			if (iAttrIdx < GAME_MELEE_MAX_ATTRS) {
				SetMeleeAttributeFloat(sWeaponName, iAttrIdx, fValue);
				PrintToServer("%s for %s set to %.2f.", sMeleeAttrNames[iAttrIdx], sWeaponName, fValue);
			} else {
				if (fValue <= 0.0) {
					if (!hTankDamageAttri.Remove(sWeaponName)) {
						PrintDebug(eLogError|eServerPrint, "Сheck melee attribute '%s' value, cannot be set below zero or zero. Set the value: %f!", sAttrName, fValue);
						return Plugin_Handled;
					}
					
					PrintToServer("Tank Damage Multiplier (tankdamagemult) attribute reset for %s melee!", sWeaponName);
					OnTankDamageEnableAttriChanged(hTankDamageAttri.Size != 0);
					return Plugin_Handled;
				}
				
				OnTankDamageEnableAttriChanged(true);
				hTankDamageAttri.SetValue(sWeaponName, fValue);
				PrintToServer("%s for %s set to %.2f", sMeleeAttrNames[iAttrIdx], sWeaponName, fValue);
			}
		}
	} else if (L4D2_IsValidWeapon(sWeaponName)) {
		int iAttrIdx = GetWeaponAttributeIndex(sAttrName);
	
		if (iAttrIdx == -1) {
			PrintDebug(eLogError|eServerPrint, "Bad attribute name: %s.", sAttrName);
			return Plugin_Handled;
		}
		
		if (iAttrIdx < INT_WEAPON_MAX_ATTRS) {
			int iValue = StringToInt(sAttrValue);
			SetWeaponAttributeInt(sWeaponName, iAttrIdx, iValue);
			PrintToServer("%s for %s set to %d.", sWeaponAttrNames[iAttrIdx], sWeaponName, iValue);
		} else {
			float fValue = StringToFloat(sAttrValue);
			if (iAttrIdx < GAME_WEAPON_MAX_ATTRS) {
				SetWeaponAttributeFloat(sWeaponName, iAttrIdx, fValue);
				PrintToServer("%s for %s set to %.2f.", sWeaponAttrNames[iAttrIdx], sWeaponName, fValue);
			} else if (iAttrIdx < PLUGIN_WEAPON_MAX_ATTRS - 1) {
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
			} else {
				if (StrContains(sWeaponName, "shotgun", false) == -1) {
					PrintDebug(eLogError|eServerPrint, "Non-shotgun weapon '%s' encountered when setting Reload Duration Multiplier (reloaddurationmult).", sWeaponName);
					return Plugin_Handled;
				}
				
				if (fValue <= 0.0) {
					if (!hReloadDurationAttri.Remove(sWeaponName)) {
						PrintDebug(eLogError|eServerPrint, "Сheck weapon attribute '%s' value, cannot be set below zero or zero. Set the value: %f!", sAttrName, fValue);
						return Plugin_Handled;
					}
					
					PrintToServer("Reload Duration Multiplier (reloaddurationmult) attribute reset for %s weapon!", sWeaponName);
					OnReloadDurationEnableAttriChanged(hReloadDurationAttri.Size != 0);
					return Plugin_Handled;
				}
				
				OnReloadDurationEnableAttriChanged(true);
				hReloadDurationAttri.SetValue(sWeaponName, fValue);
				PrintToServer("%s for %s set to %.2f", sWeaponAttrNames[iAttrIdx], sWeaponName, fValue);
			}
		}
	} else {
		PrintDebug(eLogError|eServerPrint, "Bad weapon name: %s.", sWeaponName);
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
	
	if (args > 1) {
		ReplyToCommand(client, "Syntax: sm_weapon_attributes [weapon].");
		return Plugin_Handled;
	}
	
	char sWeaponName[MAX_WEAPON_NAME_LENGTH];
	if (args == 1) {
		GetCmdArg(1, sWeaponName, sizeof(sWeaponName));
	} else if (client > 0) {
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (weapon != -1) {
			GetEdictClassname(weapon, sWeaponName, sizeof(sWeaponName));
			if (strcmp(sWeaponName, "weapon_melee") == 0) {
				GetEntPropString(weapon, Prop_Data, "m_strMapSetScriptName", sWeaponName, sizeof(sWeaponName));
			}
		}
	}
	
	if (strncmp(sWeaponName, "weapon_", 7) == 0) {
		strcopy(sWeaponName, sizeof(sWeaponName), sWeaponName[7]);
	}
	
	if (IsSupportedMelee(sWeaponName)) {
		CReplyToCommand(client, "{blue}[{default}Melee stats for {green}%s{blue}]", sWeaponName);
	
		for (int iAtrriIndex = 0; iAtrriIndex < GAME_MELEE_MAX_ATTRS; iAtrriIndex++) {
			if (iAtrriIndex < INT_MELEE_MAX_ATTRS) {
				int iValue = GetMeleeAttributeInt(sWeaponName, iAtrriIndex);
				CReplyToCommand(client, "- {lightgreen}%s{default}: {olive}%d", sMeleeAttrNames[iAtrriIndex], iValue);
			} else if (iAtrriIndex < INT_MELEE_MAX_ATTRS + BOOL_MELEE_MAX_ATTRS) {
				bool bValue = GetMeleeAttributeBool(sWeaponName, iAtrriIndex);
				CReplyToCommand(client, "- {lightgreen}%s{default}: {olive}%s", sMeleeAttrNames[iAtrriIndex], bValue ? "true" : "false");
			} else {
				float fValue = GetMeleeAttributeFloat(sWeaponName, iAtrriIndex);
				CReplyToCommand(client, "- {lightgreen}%s{default}: {olive}%.2f", sMeleeAttrNames[iAtrriIndex], fValue);
			}
		}
		
		float fBuff = 0.0;
		if (hTankDamageAttri.GetValue(sWeaponName, fBuff)) {
			CReplyToCommand(client, "- {lightgreen}%s{default}: {olive}%.2f", sMeleeAttrNames[GAME_MELEE_MAX_ATTRS], fBuff);
		}
	} else if (L4D2_IsValidWeapon(sWeaponName)) {
		CReplyToCommand(client, "{blue}[{default}Weapon stats for {green}%s{blue}]", sWeaponName);
	
		for (int iAtrriIndex = 0; iAtrriIndex < GAME_WEAPON_MAX_ATTRS; iAtrriIndex++) {
			if (iAtrriIndex < INT_WEAPON_MAX_ATTRS) {
				int iValue = GetWeaponAttributeInt(sWeaponName, iAtrriIndex);
				CReplyToCommand(client, "- {lightgreen}%s{default}: {olive}%d", sWeaponAttrNames[iAtrriIndex], iValue);
			} else {
				float fValue = GetWeaponAttributeFloat(sWeaponName, iAtrriIndex);
				CReplyToCommand(client, "- {lightgreen}%s{default}: {olive}%.2f", sWeaponAttrNames[iAtrriIndex], fValue);
			}
		}
		
		float fBuff = 0.0;
		if (hTankDamageAttri.GetValue(sWeaponName, fBuff)) {
			CReplyToCommand(client, "- {lightgreen}%s{default}: {olive}%.2f", sWeaponAttrNames[GAME_WEAPON_MAX_ATTRS], fBuff);
		}
		
		fBuff = 0.0;
		if (hReloadDurationAttri.GetValue(sWeaponName, fBuff)) {
			CReplyToCommand(client, "- {lightgreen}%s{default}: {olive}%.2f", sWeaponAttrNames[GAME_WEAPON_MAX_ATTRS+1], fBuff);
		}
	} else {
		ReplyToCommand(client, "Bad weapon name: %s.", sWeaponName);
		return Plugin_Handled;
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
	
	IsReset = (hReloadDurationAttri.Size > 0);
	hReloadDurationAttri.Clear();
	
	if (IsReset) {
		PrintToServer("Reload Duration Multiplier (reloaddurationmult) attribute reset for all shotguns!");
	}
	
	int iWeaponAttrCount = ResetWeaponAttributes(true);
	if (iWeaponAttrCount == 0) {
		PrintToServer("Weapon attributes were not reset, because no weapon attributes were saved!");
	}
	
	int iMeleeAttrCount = ResetMeleeAttributes(true);
	if (iMeleeAttrCount == 0) {
		PrintToServer("Melee attributes were not reset, because no melee attributes were saved!");
	}
	
	if (iWeaponAttrCount || iMeleeAttrCount) {
		PrintToServer("The weapon attributes for all saved weapons have been reset successfully. Number of reset weapon attributes: %d!", iWeaponAttrCount + iMeleeAttrCount);
	}
	
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
	if (!(damagetype & DMG_BULLET) && !(damagetype & DMG_CLUB)) {
		return Plugin_Continue;
	}
	
	/*if (!L4D2_IsTankInPlay()) { //left4dhooks & left4donwtown
		return Plugin_Continue;
	}*/

	if (!IsValidClient(attacker) || !IsTank(victim)) {
		return Plugin_Continue;
	}

	char sWeaponName[MAX_WEAPON_NAME_LENGTH];
	GetEdictClassname(inflictor, sWeaponName, sizeof(sWeaponName));
	
	if (strncmp(sWeaponName, "weapon_", 7) == 0) {
		if (strcmp(sWeaponName[7], "melee") == 0) {
			GetEntPropString(inflictor, Prop_Data, "m_strMapSetScriptName", sWeaponName, sizeof(sWeaponName));
		} else {
			strcopy(sWeaponName, sizeof(sWeaponName), sWeaponName[7]);
		}
	}
	
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

MRESReturn DTR_CBaseShotgun__GetReloadDurationModifier(int weapon, DHookReturn hReturn)
{
	char sWeaponName[MAX_WEAPON_NAME_LENGTH];
	GetEdictClassname(weapon, sWeaponName, sizeof(sWeaponName));
	
	if (strncmp(sWeaponName, "weapon_", 7) == 0) {
		strcopy(sWeaponName, sizeof(sWeaponName), sWeaponName[7]);
	}
	
	float fBuff = 0.0;
	if (!hReloadDurationAttri.GetValue(sWeaponName, fBuff)) {
		return MRES_Ignored;
	}
	
	hReturn.Value = fBuff;
	
	#if DEBUG
		PrintDebug(eLogError|eServerPrint|ePrintChatAll, "Reload duration multiplier to weapon '%s' is set %f.", sWeaponName, fBuff);
	#endif
	
// 1.12.0.7000
// https://github.com/alliedmodders/sourcemod/commit/8e0039aaec2bd449bc4f73d82307bde
#if SOURCEMOD_V_MAJOR > 1
  || (SOURCEMOD_V_MAJOR == 1 && SOURCEMOD_V_MINOR >= 12 && SOURCEMOD_V_REV >= 7000)
	return MRES_Supercede;
#else
	return MRES_Override;
#endif
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

int GetMeleeAttributeIndex(const char[] sAttrName)
{
	for (int i = 0; i < PLUGIN_MELEE_MAX_ATTRS; i++) {
		if (strcmp(sAttrName, sMeleeAttrShortName[i]) == 0) {
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
	Resetable value;
	if (!hDefaultWeaponAttributes[iAtrriIndex].GetArray(sWeaponName, value, sizeof(value))) {
		if (bIsSaveDefValue) {
			value.defVal = GetWeaponAttributeInt(sWeaponName, iAtrriIndex);
		
			#if DEBUG
				PrintDebug(eLogError|eServerPrint|ePrintChatAll, "The default int value '%d' of the attribute for the weapon '%s' is saved! Attributes index: %d.", value.defVal, sWeaponName, iAtrriIndex);
			#endif
		}
	}
	
	L4D2_SetIntWeaponAttribute(sWeaponName, iIntWeaponAttributes[iAtrriIndex], iSetValue);
	
	value.curVal = iSetValue;
	hDefaultWeaponAttributes[iAtrriIndex].SetArray(sWeaponName, value, sizeof(value), true);

#if DEBUG
	PrintDebug(eLogError|eServerPrint|ePrintChatAll, "Weapon attribute int set. %s - Trying to set: %d, was set: %d.", sWeaponName, iSetValue, GetWeaponAttributeInt(sWeaponName, iAtrriIndex));
#endif
}

void SetWeaponAttributeFloat(const char[] sWeaponName, int iAtrriIndex, float fSetValue, bool bIsSaveDefValue = true)
{
	Resetable value;
	if (!hDefaultWeaponAttributes[iAtrriIndex].GetArray(sWeaponName, value, sizeof(value))) {
		if (bIsSaveDefValue) {
			value.defVal = GetWeaponAttributeFloat(sWeaponName, iAtrriIndex);
			
			#if DEBUG
				PrintDebug(eLogError|eServerPrint|ePrintChatAll, "The default float value '%f' of the attribute for the weapon '%s' is saved! Attributes index: %d.", value.defVal, sWeaponName, iAtrriIndex);
			#endif
		}
	}

	L4D2_SetFloatWeaponAttribute(sWeaponName, iFloatWeaponAttributes[iAtrriIndex - INT_WEAPON_MAX_ATTRS], fSetValue);

	value.curVal = fSetValue;
	hDefaultWeaponAttributes[iAtrriIndex].SetArray(sWeaponName, value, sizeof(value), true);
	
#if DEBUG
	PrintDebug(eLogError|eServerPrint|ePrintChatAll, "Weapon attribute float set. %s - Trying to set: %f, was set: %f.", sWeaponName, fSetValue, GetWeaponAttributeFloat(sWeaponName, iAtrriIndex));
#endif
}

int GetMeleeAttributeInt(const char[] sMeleeName, int iAtrriIndex)
{
	int idx = L4D2_GetMeleeWeaponIndex(sMeleeName);
	if (idx != -1) {
		return L4D2_GetIntMeleeAttribute(idx, iIntMeleeAttributes[iAtrriIndex]);
	}
	
	Resetable value;
	if (hDefaultMeleeAttributes[iAtrriIndex].GetArray(sMeleeName, value, sizeof(value))) {
		// do something ...
	}
	return value.curVal;
}

bool GetMeleeAttributeBool(const char[] sMeleeName, int iAtrriIndex)
{
	int idx = L4D2_GetMeleeWeaponIndex(sMeleeName);
	if (idx != -1) {
		return L4D2_GetBoolMeleeAttribute(idx, iBoolMeleeAttributes[iAtrriIndex - INT_MELEE_MAX_ATTRS]);
	}
	
	Resetable value;
	if (hDefaultMeleeAttributes[iAtrriIndex].GetArray(sMeleeName, value, sizeof(value))) {
		// do something ...
	}
	
	return value.curVal;
}

float GetMeleeAttributeFloat(const char[] sMeleeName, int iAtrriIndex)
{
	int idx = L4D2_GetMeleeWeaponIndex(sMeleeName);
	if (idx != -1) {
		return L4D2_GetFloatMeleeAttribute(idx, iFloatMeleeAttributes[iAtrriIndex - BOOL_MELEE_MAX_ATTRS - INT_MELEE_MAX_ATTRS]);
	}
	
	Resetable value;
	if (hDefaultMeleeAttributes[iAtrriIndex].GetArray(sMeleeName, value, sizeof(value))) {
		// do something ...
	}
	
	return value.curVal;
}

void SetMeleeAttributeInt(const char[] sMeleeName, int iAtrriIndex, int iSetValue, bool bIsSaveDefValue = true)
{
	Resetable value;
	if (!hDefaultMeleeAttributes[iAtrriIndex].GetArray(sMeleeName, value, sizeof(value))) {
		if (bIsSaveDefValue) {
			value.defVal = GetMeleeAttributeInt(sMeleeName, iAtrriIndex);
		
			#if DEBUG
				PrintDebug(eLogError|eServerPrint|ePrintChatAll, "The default int value '%d' of the attribute for the melee '%s' is saved! Attributes index: %d.", value.defVal, sMeleeName, iAtrriIndex);
			#endif
		}
	}
	
	int idx = L4D2_GetMeleeWeaponIndex(sMeleeName);
	if (idx != -1) {
		L4D2_SetIntMeleeAttribute(idx, iIntMeleeAttributes[iAtrriIndex], iSetValue);
	}
	
	value.curVal = iSetValue;
	hDefaultMeleeAttributes[iAtrriIndex].SetArray(sMeleeName, value, sizeof(value), true);

#if DEBUG
	PrintDebug(eLogError|eServerPrint|ePrintChatAll, "Melee attribute int set. %s - Trying to set: %d, was set: %d.", sMeleeName, iSetValue, GetMeleeAttributeInt(sMeleeName, iAtrriIndex));
#endif
}

void SetMeleeAttributeBool(const char[] sMeleeName, int iAtrriIndex, bool bSetValue, bool bIsSaveDefValue = true)
{
	Resetable value;
	if (!hDefaultMeleeAttributes[iAtrriIndex].GetArray(sMeleeName, value, sizeof(value))) {
		if (bIsSaveDefValue) {
			value.defVal = GetMeleeAttributeBool(sMeleeName, iAtrriIndex);
		
			#if DEBUG
				PrintDebug(eLogError|eServerPrint|ePrintChatAll, "The default int value '%d' of the attribute for the melee '%s' is saved! Attributes index: %d.", value.defVal, sMeleeName, iAtrriIndex);
			#endif
		}
	}
	
	int idx = L4D2_GetMeleeWeaponIndex(sMeleeName);
	if (idx != -1) {
		L4D2_SetBoolMeleeAttribute(idx, iBoolMeleeAttributes[iAtrriIndex - INT_MELEE_MAX_ATTRS], bSetValue);
	}
	
	value.curVal = bSetValue;
	hDefaultMeleeAttributes[iAtrriIndex].SetArray(sMeleeName, value, sizeof(value), true);

#if DEBUG
	PrintDebug(eLogError|eServerPrint|ePrintChatAll, "Melee attribute int set. %s - Trying to set: %d, was set: %d.", sMeleeName, bSetValue, GetMeleeAttributeBool(sMeleeName, iAtrriIndex));
#endif
}

void SetMeleeAttributeFloat(const char[] sMeleeName, int iAtrriIndex, float fSetValue, bool bIsSaveDefValue = true)
{
	Resetable value;
	if (!hDefaultMeleeAttributes[iAtrriIndex].GetArray(sMeleeName, value, sizeof(value))) {
		if (bIsSaveDefValue) {
			value.defVal = GetMeleeAttributeFloat(sMeleeName, iAtrriIndex);
		
			#if DEBUG
				PrintDebug(eLogError|eServerPrint|ePrintChatAll, "The default int value '%f' of the attribute for the melee '%s' is saved! Attributes index: %d.", value.defVal, sMeleeName, iAtrriIndex);
			#endif
		}
	}
	
	int idx = L4D2_GetMeleeWeaponIndex(sMeleeName);
	if (idx != -1) {
		L4D2_SetFloatMeleeAttribute(idx, iFloatMeleeAttributes[iAtrriIndex - BOOL_MELEE_MAX_ATTRS - INT_MELEE_MAX_ATTRS], fSetValue);
	}
	
	value.curVal = fSetValue;
	hDefaultMeleeAttributes[iAtrriIndex].SetArray(sMeleeName, value, sizeof(value), true);

#if DEBUG
	PrintDebug(eLogError|eServerPrint|ePrintChatAll, "Melee attribute int set. %s - Trying to set: %f, was set: %f.", sMeleeName, fSetValue, GetMeleeAttributeFloat(sMeleeName, iAtrriIndex));
#endif
}

int ResetWeaponAttributes(bool bResetDefault = false)
{
	float fDefValue = 0.0, fCurValue = 0.0;
	int iDefValue = 0, iCurValue = 0;
	Resetable value;

	char sWeaponName[MAX_WEAPON_NAME_LENGTH];
	StringMapSnapshot hTrieSnapshot = null;
	int iCount = 0, iSize = 0;
	
	for (int iAtrriIndex = 0; iAtrriIndex < GAME_WEAPON_MAX_ATTRS; iAtrriIndex++) {
		hTrieSnapshot = hDefaultWeaponAttributes[iAtrriIndex].Snapshot();
		iSize = hTrieSnapshot.Length;
		
		for (int i = 0; i < iSize; i++) {
			hTrieSnapshot.GetKey(i, sWeaponName, sizeof(sWeaponName));
			if (iAtrriIndex < INT_WEAPON_MAX_ATTRS) {
				hDefaultWeaponAttributes[iAtrriIndex].GetArray(sWeaponName, value, sizeof(value));
				
				iCurValue = GetWeaponAttributeInt(sWeaponName, iAtrriIndex);
				iDefValue = bResetDefault ? value.defVal : value.curVal;
				if (iCurValue != iDefValue) {
					SetWeaponAttributeInt(sWeaponName, iAtrriIndex, iDefValue, false);
					iCount++;
				}
				
				#if DEBUG
					PrintDebug(eLogError|eServerPrint|ePrintChatAll, "Reset Attributes: %s - '%s' set default to %d. Current value: %d.", sWeaponName, sWeaponAttrShortName[iAtrriIndex], iDefValue, iCurValue);
				#endif
			} else {
				hDefaultWeaponAttributes[iAtrriIndex].GetArray(sWeaponName, value, sizeof(value));
				
				fCurValue = GetWeaponAttributeFloat(sWeaponName, iAtrriIndex);
				fDefValue = bResetDefault ? value.defVal : value.curVal;
				if (fCurValue != fDefValue) {
					SetWeaponAttributeFloat(sWeaponName, iAtrriIndex, fDefValue, false);
					iCount++;
				}
				
				#if DEBUG
					PrintDebug(eLogError|eServerPrint|ePrintChatAll, "Reset Attributes: %s - '%s' set default to %f. Current value: %f.", sWeaponName, sWeaponAttrShortName[iAtrriIndex], fDefValue, fCurValue);
				#endif
			}
		}
		
		delete hTrieSnapshot;
		hTrieSnapshot = null;
	}

#if DEBUG
	PrintDebug(eLogError|eServerPrint|ePrintChatAll, "Reset all weapon attributes. Count: %d.", iCount);
#endif

	return iCount;
}

int ResetMeleeAttributes(bool bResetDefault = false)
{
	float fDefValue = 0.0, fCurValue = 0.0;
	bool bDefValue = false, bCurValue = false;
	int iDefValue = 0, iCurValue = 0;
	Resetable value;

	char sMeleeName[MAX_WEAPON_NAME_LENGTH];
	StringMapSnapshot hTrieSnapshot = null;
	int iCount = 0, iSize = 0;
	
	for (int iAtrriIndex = 0; iAtrriIndex < GAME_MELEE_MAX_ATTRS; iAtrriIndex++) {
		hTrieSnapshot = hDefaultMeleeAttributes[iAtrriIndex].Snapshot();
		iSize = hTrieSnapshot.Length;
		
		for (int i = 0; i < iSize; i++) {
			hTrieSnapshot.GetKey(i, sMeleeName, sizeof(sMeleeName));
			if (iAtrriIndex < INT_MELEE_MAX_ATTRS) {
				hDefaultMeleeAttributes[iAtrriIndex].GetArray(sMeleeName, value, sizeof(value));
				
				iCurValue = GetMeleeAttributeInt(sMeleeName, iAtrriIndex);
				iDefValue = bResetDefault ? value.defVal : value.curVal;
				if (iCurValue != iDefValue) {
					SetMeleeAttributeInt(sMeleeName, iAtrriIndex, iDefValue, false);
					iCount++;
				}
				
				#if DEBUG
					PrintDebug(eLogError|eServerPrint|ePrintChatAll, "Reset Attributes: %s - '%s' set default to %d. Current value: %d.", sMeleeName, sMeleeAttrShortName[iAtrriIndex], iDefValue, iCurValue);
				#endif
			} else if (iAtrriIndex < INT_MELEE_MAX_ATTRS + BOOL_MELEE_MAX_ATTRS) {
				hDefaultMeleeAttributes[iAtrriIndex].GetArray(sMeleeName, value, sizeof(value));
				
				bCurValue = GetMeleeAttributeBool(sMeleeName, iAtrriIndex);
				bDefValue = bResetDefault ? value.defVal : value.curVal;
				if (bCurValue != bDefValue) {
					SetMeleeAttributeBool(sMeleeName, iAtrriIndex, bDefValue, false);
					iCount++;
				}
				
				#if DEBUG
					PrintDebug(eLogError|eServerPrint|ePrintChatAll, "Reset Attributes: %s - '%s' set default to %d. Current value: %d.", sMeleeName, sMeleeAttrShortName[iAtrriIndex], bDefValue, bCurValue);
				#endif
			} else {
				hDefaultMeleeAttributes[iAtrriIndex].GetArray(sMeleeName, value, sizeof(value));
				
				fCurValue = GetMeleeAttributeFloat(sMeleeName, iAtrriIndex);
				fDefValue = bResetDefault ? value.defVal : value.curVal;
				if (fCurValue != fDefValue) {
					SetMeleeAttributeFloat(sMeleeName, iAtrriIndex, fDefValue, false);
					iCount++;
				}
				
				#if DEBUG
					PrintDebug(eLogError|eServerPrint|ePrintChatAll, "Reset Attributes: %s - '%s' set default to %f. Current value: %f.", sMeleeName, sMeleeAttrShortName[iAtrriIndex], fDefValue, fCurValue);
				#endif
			}
		}
		
		delete hTrieSnapshot;
		hTrieSnapshot = null;
	}

#if DEBUG
	PrintDebug(eLogError|eServerPrint|ePrintChatAll, "Reset all melee attributes. Count: %d.", iCount);
#endif

	return iCount;
}

bool IsSupportedMelee(const char[] sMeleeName)
{
	static const char s_sOfficialMeleeWeaponNames[][] =
	{
		"knife",
		"baseball_bat",
		"chainsaw",
		"cricket_bat",
		"crowbar",
		"didgeridoo",
		"electric_guitar",
		"fireaxe",
		"frying_pan",
		"golfclub",
		"katana",
		"machete",
		"riotshield",
		"tonfa",
		"shovel",
		"pitchfork"
	};
	
	for (int i = 0; i < sizeof(s_sOfficialMeleeWeaponNames); i++) {
		if (strcmp(sMeleeName, s_sOfficialMeleeWeaponNames[i]) == 0) {
			return true;
		}
	}

	return false;
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

stock bool StringToBool(const char[] str)
{
	int num;
	if (StringToIntEx(str, num)) {
		return num != 0;
	} else if (strcmp(str, "true", false) == 0) {
		return true;
	}
	
	return false;
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
