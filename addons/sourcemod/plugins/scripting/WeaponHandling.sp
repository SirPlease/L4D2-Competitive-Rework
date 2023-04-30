/*  
*    Copyright (C) 2019  LuxLuma		acceliacat@gmail.com
*
*    This program is free software: you can redistribute it and/or modify
*    it under the terms of the GNU General Public License as published by
*    the Free Software Foundation, either version 3 of the License, or
*    (at your option) any later version.
*
*    This program is distributed in the hope that it will be useful,
*    but WITHOUT ANY WARRANTY; without even the implied warranty of
*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*    GNU General Public License for more details.
*
*    You should have received a copy of the GNU General Public License
*    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/



//dual pistol shots have been lowered from 13.3~ shots per sec to 11.5~ shots per sec inline with double shoot speed of single pistol
//These forwards are likely not safe to do much to clients in like change their weapons ect.

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <dhooks>

#pragma semicolon 1

#pragma newdecls required


#define GAMEDATA "WeaponHandling"

#define PLUGIN_VERSION "1.0.6"

#define USING_PILLS_ACT 187

#define DESERT_BURST_INTERVAL 0.35
#define DESERT_BURST_OFFSET_2 0
#define DESERT_BURST_OFFSET_3 4
#define DESERT_BURST_OFFSET_END 8
static int g_DesertBurstOffset = -1;
static float g_fBurstEndTime[MAXPLAYERS+1];
static float g_fBurstModifier;

enum L4D2WeaponType 
{
	L4D2WeaponType_Unknown = 0,
	L4D2WeaponType_Pistol,
	L4D2WeaponType_Magnum,
	L4D2WeaponType_Rifle,
	L4D2WeaponType_RifleAk47,
	L4D2WeaponType_RifleDesert,
	L4D2WeaponType_RifleM60,
	L4D2WeaponType_RifleSg552,
	L4D2WeaponType_HuntingRifle,
	L4D2WeaponType_SniperAwp,
	L4D2WeaponType_SniperMilitary,
	L4D2WeaponType_SniperScout,
	L4D2WeaponType_SMG,
	L4D2WeaponType_SMGSilenced,
	L4D2WeaponType_SMGMp5,
	L4D2WeaponType_Autoshotgun,
	L4D2WeaponType_AutoshotgunSpas,
	L4D2WeaponType_Pumpshotgun,
	L4D2WeaponType_PumpshotgunChrome,
	L4D2WeaponType_Molotov,
	L4D2WeaponType_Pipebomb,
	L4D2WeaponType_FirstAid,
	L4D2WeaponType_Pills,
	L4D2WeaponType_Gascan,
	L4D2WeaponType_Oxygentank,
	L4D2WeaponType_Propanetank,
	L4D2WeaponType_Vomitjar,
	L4D2WeaponType_Adrenaline,
	L4D2WeaponType_Chainsaw,
	L4D2WeaponType_Defibrilator,
	L4D2WeaponType_GrenadeLauncher,
	L4D2WeaponType_Melee,
	L4D2WeaponType_UpgradeFire,
	L4D2WeaponType_UpgradeExplosive,
	L4D2WeaponType_BoomerClaw,
	L4D2WeaponType_ChargerClaw,
	L4D2WeaponType_HunterClaw,
	L4D2WeaponType_JockeyClaw,
	L4D2WeaponType_SmokerClaw,
	L4D2WeaponType_SpitterClaw,
	L4D2WeaponType_TankClaw,
	L4D2WeaponType_Gnome
}

static L4D2WeaponType g_iWeaponType[2048+1];
static Handle hReloadModifier;
static Handle hRateOfFire;
static Handle hItemUseDuration;
static Handle hOnPillsUse_L4D1;
static Handle hDeployModifier;
static Handle hDeployGun;
static Handle hGrenadePrimaryAttack;
static Handle hStartThrow;
static Handle hDesertBurstFire;

static Address CTerrorGun__GetRateOfFire_byte_address;
static Address CPistol__GetRateOfFire_byte_address;

static int g_iTempRef;
static float g_fTempSpeed;

Handle g_hOnMeleeSwing;
Handle g_hOnStartThrow;
Handle g_hOnReadyingThrow;
Handle g_hOnReloadModifier;
Handle g_hOnGetRateOfFire;
Handle g_hOnDeployModifier;

static ConVar hCvar_DoublePistolCycle;
static ConVar hCvar_UseIncapCycle;
static ConVar hCvar_DeploySetting;

static bool g_bDoublePistolCycle;
static bool g_bUseIncapCycle;
static int g_iDeploySetting;

static ConVar hCvar_IncapCycle;
static float g_fIncapCycle = 0.3;

static bool g_bL4D1IsUsingPills;
static int g_iPillsUseTimerOffset;

enum MeleeSwingInfo
{
	MeleeSwingInfo_Entity = 0,
	MeleeSwingInfo_Client,
	MeleeSwingInfo_SwingType
} 

static int g_iMeleeTempVals[3];

bool g_bIsL4D2;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion iEngineVersion = GetEngineVersion();
	if(iEngineVersion == Engine_Left4Dead2)
	{
		g_bIsL4D2 = true;
	}
	else if(iEngineVersion == Engine_Left4Dead)
	{
		g_bIsL4D2 = false;
	}
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1/2");
		return APLRes_SilentFailure;
	}
	
	RegPluginLibrary("WeaponHandling");
	g_hOnMeleeSwing = CreateGlobalForward("WH_OnMeleeSwing", ET_Event, Param_Cell, Param_Cell, Param_FloatByRef);
	g_hOnStartThrow = CreateGlobalForward("WH_OnStartThrow", ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_FloatByRef);
	g_hOnReadyingThrow = CreateGlobalForward("WH_OnReadyingThrow", ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_FloatByRef);
	g_hOnReloadModifier = CreateGlobalForward("WH_OnReloadModifier", ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_FloatByRef);
	g_hOnGetRateOfFire = CreateGlobalForward("WH_OnGetRateOfFire", ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_FloatByRef);
	g_hOnDeployModifier = CreateGlobalForward("WH_OnDeployModifier", ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_FloatByRef);
	
	return APLRes_Success;
}

public Plugin myinfo =
{
	name = "WeaponHandling",
	author = "Lux",
	description = "Weapon Handling API for guns and melee weapons in left 4 dead",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2674761"
};


public void OnPluginStart()
{
	LoadHooksAndPatches();
	
	CreateConVar("weaponhandling_version", PLUGIN_VERSION, "", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	
	hCvar_DoublePistolCycle = CreateConVar("wh_double_pistol_cycle_rate", "0", "1 = (double pistol shoot at double speed of a single pistol 2~ shots persec slower than vanilla) 0 = (keeps vanilla cycle rate of 0.075) before being modified", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	hCvar_UseIncapCycle = CreateConVar("wh_use_incap_cycle_cvar", "1", "1 = (use \"survivor_incapacitated_cycle_time\" for incap shooting cycle rate) 0 = (ignores the cvar and uses weapon_*.txt cycle rates) before being modified", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	hCvar_DeploySetting = CreateConVar("wh_deploy_animation_speed", "-1", "1 = (match deploy animation speed to the \"DeployDuration\" keyvalue in weapon_*.txt) 0 = (ignore \"DeployDuration\" keyvalue in weapon_*.txt and matches deploy speed to animation speed) before being modified -1(do nothing)", FCVAR_NOTIFY, true, -1.0, true, 1.0);
	
	hCvar_IncapCycle = FindConVar("survivor_incapacitated_cycle_time");
	if(hCvar_IncapCycle == null)
	{
		LogError("Unable to find \"survivor_incapacitated_cycle_time\" cvar, assuming \"wh_use_incap_cycle_cvar\" is false");
	}
	else
	{
		hCvar_IncapCycle.AddChangeHook(eConvarChanged);
	}
	
	hCvar_DoublePistolCycle.AddChangeHook(eConvarChanged);
	hCvar_UseIncapCycle.AddChangeHook(eConvarChanged);
	hCvar_DeploySetting.AddChangeHook(eConvarChanged);
	
	CvarsChanged();
	AutoExecConfig(true, "WeaponHandling");
}

public void eConvarChanged(Handle hCvar, const char[] sOldVal, const char[] sNewVal)
{
	CvarsChanged();
}

void CvarsChanged()
{
	g_bDoublePistolCycle = hCvar_DoublePistolCycle.IntValue > 0;
	g_bUseIncapCycle = hCvar_UseIncapCycle.IntValue > 0;
	g_iDeploySetting = hCvar_DeploySetting.IntValue;
	
	if(hCvar_IncapCycle != null)
	{
		g_fIncapCycle = hCvar_IncapCycle.FloatValue;
	}
	else
	{
		g_bUseIncapCycle = false;
	}
}

public MRESReturn OnMeleeSwingPre(int pThis, Handle hReturn, Handle hParams)
{
	g_iMeleeTempVals[MeleeSwingInfo_Entity] = pThis;
	g_iMeleeTempVals[MeleeSwingInfo_Client] = DHookGetParam(hParams, 1);
	g_iMeleeTempVals[MeleeSwingInfo_SwingType] = DHookGetParam(hParams, 2);
	
	return MRES_Ignored;
}

public MRESReturn OnMeleeSwingpPost()
{
	if(!g_iMeleeTempVals[MeleeSwingInfo_SwingType]) // this is here incase someone does something with secondary melee attacks, they are not accessible without plugin. 
		return MRES_Ignored;
	
	int iWeapon = g_iMeleeTempVals[MeleeSwingInfo_Entity];
	float fSpeed = 1.0;
	
	Call_StartForward(g_hOnMeleeSwing);
	Call_PushCell(g_iMeleeTempVals[MeleeSwingInfo_Client]);
	Call_PushCell(iWeapon);
	Call_PushFloatRef(fSpeed);
	Call_Finish();
	
	fSpeed = ClampFloatAboveZero(fSpeed);
	
	float flGameTime;
	float flNextTimeCalc;
	flGameTime = GetGameTime();
	flNextTimeCalc = (((GetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack") - flGameTime) / fSpeed) + flGameTime);
	
	SetEntPropFloat(iWeapon, Prop_Send, "m_flPlaybackRate", fSpeed);
	SetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack", flNextTimeCalc);
	
	return MRES_Ignored;
}

public void PostThinkOnce(int iClient)
{
	SDKUnhook(iClient, SDKHook_PostThink, PostThinkOnce);
	
	int iWeapon = GetEntPropEnt(iClient, Prop_Data, "m_hActiveWeapon");
	if(!IsValidEntRef(g_iTempRef) || iWeapon != EntRefToEntIndex(g_iTempRef))
		return;
	
	SetEntPropFloat(iWeapon, Prop_Send, "m_flPlaybackRate", g_fTempSpeed);
}

public MRESReturn OnStartThrow(int pThis, Handle hReturn)
{
	int iClient = GetEntPropEnt(pThis, Prop_Send, "m_hOwnerEntity");
	if(iClient < 1)
		return MRES_Ignored;
	
	float fSpeed = 1.0;
	
	Call_StartForward(g_hOnStartThrow);
	Call_PushCell(iClient);
	Call_PushCell(pThis);
	Call_PushCell(g_iWeaponType[pThis]);
	Call_PushFloatRef(fSpeed);
	Call_Finish();
	
	fSpeed = ClampFloatAboveZero(fSpeed);
	
	float flGameTime;
	float flNextTimeCalc;
	flGameTime = GetGameTime();
	flNextTimeCalc = (((GetEntPropFloat(pThis, Prop_Send, "m_fThrowTime") - flGameTime) / fSpeed) + flGameTime);
	SetEntPropFloat(pThis, Prop_Send, "m_fThrowTime", flNextTimeCalc);
	
	
	g_iTempRef = EntIndexToEntRef(pThis);
	g_fTempSpeed = fSpeed;
	
	SDKHook(iClient, SDKHook_PostThink, PostThinkOnce);
	return MRES_Ignored;
}

//can get very spammy when holding a throw.
public MRESReturn OnReadyingThrow(int pThis)
{
	static int iClient;
	iClient = GetEntPropEnt(pThis, Prop_Send, "m_hOwnerEntity");
	if(iClient < 1)
		return MRES_Ignored;
	
	static float fSpeed;
	fSpeed = 1.0;
	
	Call_StartForward(g_hOnReadyingThrow);
	Call_PushCell(iClient);
	Call_PushCell(pThis);
	Call_PushCell(g_iWeaponType[pThis]);
	Call_PushFloatRef(fSpeed);
	Call_Finish();
	
	fSpeed = ClampFloatAboveZero(fSpeed);
	
	//credit timocop
	static float flGameTime;
	static float flNextTimeCalc;
	flGameTime = GetGameTime();
	flNextTimeCalc = (((GetEntPropFloat(pThis, Prop_Send, "m_flNextPrimaryAttack") - flGameTime) / fSpeed) + flGameTime);
	
	SetEntPropFloat(pThis, Prop_Send, "m_flPlaybackRate", fSpeed);
	SetEntPropFloat(pThis, Prop_Send, "m_flNextPrimaryAttack", flNextTimeCalc);
	SetEntPropFloat(iClient, Prop_Send, "m_flNextAttack", flNextTimeCalc);
	
	return MRES_Ignored;
}

public MRESReturn OnReloadModifier(int pThis, Handle hReturn)
{
	int iClient = GetEntPropEnt(pThis, Prop_Send, "m_hOwnerEntity");
	if(iClient < 1)
		return MRES_Ignored;
	
	float fSpeed = 1.0;
	
	Call_StartForward(g_hOnReloadModifier);
	Call_PushCell(iClient);
	Call_PushCell(pThis);
	Call_PushCell(g_iWeaponType[pThis]);
	Call_PushFloatRef(fSpeed);
	Call_Finish();
	
	float fReloadSpeed = DHookGetReturn(hReturn);
	fReloadSpeed = ClampFloatAboveZero(fReloadSpeed / fSpeed);
	
	DHookSetReturn(hReturn, fReloadSpeed);
	return MRES_Override;
}

public MRESReturn OnGetRateOfFire(int pThis, Handle hReturn)
{
	static float fRateOfFire;
	static float fRateOfFireModifier;
	
	static int iClient;
	iClient = GetEntPropEnt(pThis, Prop_Send, "m_hOwnerEntity");
	if(iClient < 1)
		return MRES_Ignored;
		
	fRateOfFireModifier = 1.0;
	fRateOfFire = DHookGetReturn(hReturn);
	
	Call_StartForward(g_hOnGetRateOfFire);
	Call_PushCell(iClient);
	Call_PushCell(pThis);
	Call_PushCell(g_iWeaponType[pThis]);
	Call_PushFloatRef(fRateOfFireModifier);
	Call_Finish();
	
	if(g_iWeaponType[pThis] == L4D2WeaponType_Pistol && GetEntProp(pThis, Prop_Send, "m_isDualWielding", 1))
	{
		if(g_bDoublePistolCycle)
		{
			fRateOfFire = fRateOfFire * 0.5;//double pistol shoots at 2x speed of single instead of valve's 0.075 static rate weapon_pistol.txt firerate changes will scale better.
		}
		else
		{
			fRateOfFire = 0.075000003;
		}
	}
	
	if(g_bUseIncapCycle && GetEntProp(iClient, Prop_Send, "m_isIncapacitated", 1))
	{
		fRateOfFire = g_fIncapCycle;
	}
	
	fRateOfFire = ClampFloatAboveZero(fRateOfFire / fRateOfFireModifier);
	
	if(g_iWeaponType[pThis] == L4D2WeaponType_RifleDesert)
	{
		g_fBurstModifier = fRateOfFireModifier;
	}
	
	DHookSetReturn(hReturn, fRateOfFire);
	SetEntPropFloat(pThis, Prop_Send, "m_flPlaybackRate", fRateOfFireModifier);
	
	return MRES_Override;
}

//call order hack
public MRESReturn OnGetRateOfFireBurst(int pThis, Handle hReturn)
{
	//return MRES_Ignored;
	static int iClient;
	iClient = GetEntPropEnt(pThis, Prop_Send, "m_hOwnerEntity");
	if(iClient < 1)
		return MRES_Ignored;
	
	float flValveBurstData = GetEntDataFloat(pThis, g_DesertBurstOffset + DESERT_BURST_OFFSET_END);
	if(flValveBurstData == g_fBurstEndTime[iClient])// store the modified value to not scale it again
	{
		return MRES_Ignored;
	}
	
	float fTime = GetGameTime();
	flValveBurstData = flValveBurstData - fTime;
	flValveBurstData = ClampFloatAboveZero(flValveBurstData / g_fBurstModifier);
	g_fBurstEndTime[iClient] = flValveBurstData + fTime;
	
	SetEntDataFloat(pThis, g_DesertBurstOffset + DESERT_BURST_OFFSET_END, g_fBurstEndTime[iClient]);
	return MRES_Ignored;
}

public MRESReturn OnGetRateOfFireL4D1Pills(int pThis)
{
	int iClient = GetEntPropEnt(pThis, Prop_Send, "m_hOwnerEntity");
	if(iClient < 1 || !g_bL4D1IsUsingPills)
	{
		g_bL4D1IsUsingPills = false;
		return MRES_Ignored;
	}
	g_bL4D1IsUsingPills = false;
	
	float fRateOfFireModifier = 1.0;
	
	Call_StartForward(g_hOnGetRateOfFire);
	Call_PushCell(iClient);
	Call_PushCell(pThis);
	Call_PushCell(g_iWeaponType[pThis]);
	Call_PushFloatRef(fRateOfFireModifier);
	Call_Finish();
	
	//g_iPillsUseTimerOffset + 4 = Duration
	//g_iPillsUseTimerOffset + 8 = TimeStamp
	Address PillsUseTimerDuration = GetEntityAddress(pThis) + view_as<Address>(g_iPillsUseTimerOffset + 4);
	Address PillsUseTimerTimeStamp = PillsUseTimerDuration + view_as<Address>(4);
	
	float fRateOfFire = view_as<float>(LoadFromAddress(PillsUseTimerDuration, NumberType_Int32));
	fRateOfFire = ClampFloatAboveZero(fRateOfFire / fRateOfFireModifier);
	
	StoreToAddress(PillsUseTimerTimeStamp, view_as<int>(fRateOfFire + GetGameTime()), NumberType_Int32);
	StoreToAddress(PillsUseTimerDuration, view_as<int>(fRateOfFire), NumberType_Int32);
	
	SetEntPropFloat(pThis, Prop_Send, "m_flPlaybackRate", fRateOfFireModifier);
	return MRES_Ignored;
}
// Using CPainPills::SendWeaponAnim way less spammy than CBaseAnimating::SequenceDuration, since other stuff call that altho it would of been simpler to use.
public MRESReturn OnIsUsingPills(int pThis, Handle hReturn, Handle hParams)
{
	int iClient = GetEntPropEnt(pThis, Prop_Send, "m_hOwnerEntity");
	if(iClient < 1)
		return MRES_Ignored;
	
	int iCurrentAct = DHookGetParam(hParams, 1);
	if(iCurrentAct != USING_PILLS_ACT || !DHookGetReturn(hReturn))
		return MRES_Ignored;
	
	g_bL4D1IsUsingPills = true;
	
	return MRES_Ignored;
}

public MRESReturn OnDeployModifier(int pThis, Handle hReturn)
{
	g_fTempSpeed = 1.0;
	
	int iClient = GetEntPropEnt(pThis, Prop_Send, "m_hOwnerEntity");
	if(iClient < 1)
		return MRES_Ignored;
	
	float fCurrentSpeed = DHookGetReturn(hReturn);
	float fSpeed = 1.0;
	
	switch(g_iDeploySetting)
	{
		case 0:
		{
			fCurrentSpeed = 1.0;
		}
		case 1:
		{
			g_fTempSpeed = 1.0 / fCurrentSpeed;
		}
	}
	
	Call_StartForward(g_hOnDeployModifier);
	Call_PushCell(iClient);
	Call_PushCell(pThis);
	Call_PushCell(g_iWeaponType[pThis]);
	Call_PushFloatRef(fSpeed);
	Call_Finish();
	
	fSpeed = ClampFloatAboveZero(fSpeed);
	g_fTempSpeed = g_fTempSpeed * fSpeed;
	DHookSetReturn(hReturn, ClampFloatAboveZero(fCurrentSpeed / fSpeed));
	return MRES_Override;
}

public MRESReturn OnDeployGun(int pThis)
{
	SetEntPropFloat(pThis, Prop_Send, "m_flPlaybackRate", g_fTempSpeed);
	return MRES_Ignored;
}

public void OnEntityCreated(int iEntity, const char[] sClassname)
{
	if(iEntity < 1 || sClassname[0] != 'w')
		return;

	g_iWeaponType[iEntity] = GetWeaponTypeFromClassname(sClassname);
	
	switch(g_iWeaponType[iEntity])
	{
		case L4D2WeaponType_AutoshotgunSpas, L4D2WeaponType_PumpshotgunChrome, 
			L4D2WeaponType_Autoshotgun, L4D2WeaponType_Pumpshotgun, L4D2WeaponType_GrenadeLauncher, 
			L4D2WeaponType_HuntingRifle, L4D2WeaponType_Magnum, L4D2WeaponType_Rifle, 
			L4D2WeaponType_SMG, L4D2WeaponType_RifleSg552,
			L4D2WeaponType_Pistol, L4D2WeaponType_RifleAk47, L4D2WeaponType_SMGMp5, 
			L4D2WeaponType_SMGSilenced, L4D2WeaponType_SniperAwp, L4D2WeaponType_SniperMilitary, 
			L4D2WeaponType_SniperScout, L4D2WeaponType_RifleM60:
		{
			DHookEntity(hReloadModifier, true, iEntity);
			DHookEntity(hRateOfFire, true, iEntity);
			DHookEntity(hDeployModifier, true, iEntity);
			DHookEntity(hDeployGun, true, iEntity);
		}
		case L4D2WeaponType_RifleDesert:
		{
			DHookEntity(hReloadModifier, true, iEntity);
			DHookEntity(hRateOfFire, true, iEntity);
			DHookEntity(hDeployModifier, true, iEntity);
			DHookEntity(hDeployGun, true, iEntity);
			DHookEntity(hDesertBurstFire, true, iEntity);
		}
		case L4D2WeaponType_Pills, L4D2WeaponType_Adrenaline:
		{
			if(!g_bIsL4D2)
			{
				DHookEntity(hOnPillsUse_L4D1, true, iEntity);
			}
			DHookEntity(hItemUseDuration, true, iEntity);
			DHookEntity(hDeployModifier, true, iEntity);
			DHookEntity(hDeployGun, true, iEntity);
		}
		case L4D2WeaponType_Melee, L4D2WeaponType_Defibrilator, L4D2WeaponType_FirstAid, L4D2WeaponType_UpgradeFire, L4D2WeaponType_UpgradeExplosive:
		{
			DHookEntity(hDeployModifier, true, iEntity);
			DHookEntity(hDeployGun, true, iEntity);
		}
		case L4D2WeaponType_Molotov, L4D2WeaponType_Pipebomb, L4D2WeaponType_Vomitjar:
		{
			DHookEntity(hGrenadePrimaryAttack, true, iEntity);
			DHookEntity(hStartThrow, true, iEntity);
			DHookEntity(hDeployModifier, true, iEntity);
			DHookEntity(hDeployGun, true, iEntity);
		}
	}
}

StringMap CreateWeaponClassnameHashMap(StringMap hWeaponClassnameHashMap)
{
	hWeaponClassnameHashMap = CreateTrie();
	hWeaponClassnameHashMap.SetValue("weapon_pistol", L4D2WeaponType_Pistol);
	hWeaponClassnameHashMap.SetValue("weapon_pistol_magnum", L4D2WeaponType_Magnum);
	hWeaponClassnameHashMap.SetValue("weapon_rifle", L4D2WeaponType_Rifle);
	hWeaponClassnameHashMap.SetValue("weapon_rifle_ak47", L4D2WeaponType_RifleAk47);
	hWeaponClassnameHashMap.SetValue("weapon_rifle_desert", L4D2WeaponType_RifleDesert);
	hWeaponClassnameHashMap.SetValue("weapon_rifle_m60", L4D2WeaponType_RifleM60);
	hWeaponClassnameHashMap.SetValue("weapon_rifle_sg552", L4D2WeaponType_RifleSg552);
	hWeaponClassnameHashMap.SetValue("weapon_hunting_rifle", L4D2WeaponType_HuntingRifle);
	hWeaponClassnameHashMap.SetValue("weapon_sniper_awp", L4D2WeaponType_SniperAwp);
	hWeaponClassnameHashMap.SetValue("weapon_sniper_military", L4D2WeaponType_SniperMilitary);
	hWeaponClassnameHashMap.SetValue("weapon_sniper_scout", L4D2WeaponType_SniperScout);
	hWeaponClassnameHashMap.SetValue("weapon_smg", L4D2WeaponType_SMG);
	hWeaponClassnameHashMap.SetValue("weapon_smg_silenced", L4D2WeaponType_SMGSilenced);
	hWeaponClassnameHashMap.SetValue("weapon_smg_mp5", L4D2WeaponType_SMGMp5);
	hWeaponClassnameHashMap.SetValue("weapon_autoshotgun", L4D2WeaponType_Autoshotgun);
	hWeaponClassnameHashMap.SetValue("weapon_shotgun_spas", L4D2WeaponType_AutoshotgunSpas);
	hWeaponClassnameHashMap.SetValue("weapon_pumpshotgun", L4D2WeaponType_Pumpshotgun);
	hWeaponClassnameHashMap.SetValue("weapon_shotgun_chrome", L4D2WeaponType_PumpshotgunChrome);
	hWeaponClassnameHashMap.SetValue("weapon_molotov", L4D2WeaponType_Molotov);
	hWeaponClassnameHashMap.SetValue("weapon_pipe_bomb", L4D2WeaponType_Pipebomb);
	hWeaponClassnameHashMap.SetValue("weapon_first_aid_kit", L4D2WeaponType_FirstAid);
	hWeaponClassnameHashMap.SetValue("weapon_pain_pills", L4D2WeaponType_Pills);
	hWeaponClassnameHashMap.SetValue("weapon_gascan", L4D2WeaponType_Gascan);
	hWeaponClassnameHashMap.SetValue("weapon_oxygentank", L4D2WeaponType_Oxygentank);
	hWeaponClassnameHashMap.SetValue("weapon_propanetank", L4D2WeaponType_Propanetank);
	hWeaponClassnameHashMap.SetValue("weapon_vomitjar", L4D2WeaponType_Vomitjar);
	hWeaponClassnameHashMap.SetValue("weapon_adrenaline", L4D2WeaponType_Adrenaline);
	hWeaponClassnameHashMap.SetValue("weapon_chainsaw", L4D2WeaponType_Chainsaw);
	hWeaponClassnameHashMap.SetValue("weapon_defibrillator", L4D2WeaponType_Defibrilator);
	hWeaponClassnameHashMap.SetValue("weapon_grenade_launcher", L4D2WeaponType_GrenadeLauncher);
	hWeaponClassnameHashMap.SetValue("weapon_melee", L4D2WeaponType_Melee);
	hWeaponClassnameHashMap.SetValue("weapon_upgradepack_incendiary", L4D2WeaponType_UpgradeFire);
	hWeaponClassnameHashMap.SetValue("weapon_upgradepack_explosive", L4D2WeaponType_UpgradeExplosive);
	hWeaponClassnameHashMap.SetValue("weapon_boomer_claw", L4D2WeaponType_BoomerClaw);
	hWeaponClassnameHashMap.SetValue("weapon_charger_claw", L4D2WeaponType_ChargerClaw);
	hWeaponClassnameHashMap.SetValue("weapon_hunter_claw", L4D2WeaponType_HunterClaw);
	hWeaponClassnameHashMap.SetValue("weapon_jockey_claw", L4D2WeaponType_JockeyClaw);
	hWeaponClassnameHashMap.SetValue("weapon_smoker_claw", L4D2WeaponType_SmokerClaw);
	hWeaponClassnameHashMap.SetValue("weapon_spitter_claw", L4D2WeaponType_SpitterClaw);
	hWeaponClassnameHashMap.SetValue("weapon_tank_claw", L4D2WeaponType_TankClaw);
	hWeaponClassnameHashMap.SetValue("weapon_gnome", L4D2WeaponType_Gnome);
	return hWeaponClassnameHashMap;
}

L4D2WeaponType GetWeaponTypeFromClassname(const char[] sClassname)
{
	static StringMap hWeaponClassnameHashMap;
	
	if(hWeaponClassnameHashMap == INVALID_HANDLE)
		hWeaponClassnameHashMap = CreateWeaponClassnameHashMap(hWeaponClassnameHashMap);
	
	static L4D2WeaponType WeaponType;
	if(!hWeaponClassnameHashMap.GetValue(sClassname, WeaponType))
		return L4D2WeaponType_Unknown;
	
	return WeaponType;
}

void LoadHooksAndPatches()
{
	Handle hGamedata = LoadGameConfigFile(GAMEDATA);
	if(hGamedata == null) 
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);
	
	
	int iOffset;
	iOffset = GameConfGetOffset(hGamedata, "CTerrorWeapon::GetReloadDurationModifier");
	if(iOffset == -1)
		SetFailState("Unable to get offset for 'CTerrorPlayer::GetReloadDurationModifier'");
	
	hReloadModifier = DHookCreate(iOffset, HookType_Entity, ReturnType_Float, ThisPointer_CBaseEntity, OnReloadModifier);
	
	iOffset = GameConfGetOffset(hGamedata, "CTerrorGun::GetRateOfFire");
	if(iOffset == -1)
		SetFailState("Unable to get offset for 'CTerrorGun::GetRateOfFire'");
	
	hRateOfFire = DHookCreate(iOffset, HookType_Entity, ReturnType_Float, ThisPointer_CBaseEntity, OnGetRateOfFire);
	
	
	if(g_bIsL4D2)
	{
		iOffset = GameConfGetOffset(hGamedata, "CBaseBeltItem::GetUseTimerDuration");
		if(iOffset == -1)
			SetFailState("Unable to get offset for 'CBaseBeltItem::GetUseTimerDuration'");
		
		hItemUseDuration = DHookCreate(iOffset, HookType_Entity, ReturnType_Float, ThisPointer_CBaseEntity, OnGetRateOfFire);
		
		iOffset = GameConfGetOffset(hGamedata, "CRifle_Desert::PrimaryAttack");
		if(iOffset == -1)
			SetFailState("Unable to get offset for 'CRifle_Desert::PrimaryAttack'");
		
		hDesertBurstFire = DHookCreate(iOffset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, OnGetRateOfFireBurst);
		
		g_DesertBurstOffset = GameConfGetOffset(hGamedata, "CRifle_Desert::BurstTimes_StartOffset");
		if(iOffset == -1)
			SetFailState("Unable to get offset for 'CRifle_Desert::BurstTimes_StartOffset'");
	}
	else
	{
		iOffset = GameConfGetOffset(hGamedata, "CPainPills::SendWeaponAnim");
		if(iOffset == -1)
			SetFailState("Unable to get offset for 'CPainPills::SendWeaponAnim'");
		
		hOnPillsUse_L4D1 = DHookCreate(iOffset, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, OnIsUsingPills);
		DHookAddParam(hOnPillsUse_L4D1, HookParamType_Int);
		
		iOffset = GameConfGetOffset(hGamedata, "CPainPills::PrimaryAttack");
		if(iOffset == -1)
			SetFailState("Unable to get offset for 'CPainPills::PrimaryAttack'");
		
		hItemUseDuration = DHookCreate(iOffset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, OnGetRateOfFireL4D1Pills);
		
		g_iPillsUseTimerOffset = GameConfGetOffset(hGamedata, "CPainPills::GetUseTimer");
		if(iOffset == -1)
			SetFailState("Unable to get offset for 'CPainPills::GetUseTime'");
	}
	
	iOffset = GameConfGetOffset(hGamedata, "CTerrorWeapon::GetDeployDurationModifier");
	if(iOffset == -1)
		SetFailState("Unable to get offset for 'CTerrorWeapon::GetDeployDurationModifier'");
	
	hDeployModifier = DHookCreate(iOffset, HookType_Entity, ReturnType_Float, ThisPointer_CBaseEntity, OnDeployModifier);
	
	iOffset = GameConfGetOffset(hGamedata, "CTerrorWeapon::Deploy");
	if(iOffset == -1)
		SetFailState("Unable to get offset for 'CTerrorWeapon::Deploy'");
	
	hDeployGun = DHookCreate(iOffset, HookType_Entity, ReturnType_Unknown, ThisPointer_CBaseEntity, OnDeployGun);
	
	iOffset = GameConfGetOffset(hGamedata, "CBaseCSGrenade::PrimaryAttack");
	if(iOffset == -1)
		SetFailState("Unable to get offset for 'CBaseCSGrenade::PrimaryAttack'");
	
	hGrenadePrimaryAttack = DHookCreate(iOffset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, OnReadyingThrow);
	
	iOffset = GameConfGetOffset(hGamedata, "CBaseCSGrenade::StartGrenadeThrow");
	if(iOffset == -1)
		SetFailState("Unable to get offset for 'CBaseCSGrenade::StartGrenadeThrow'");
	
	hStartThrow = DHookCreate(iOffset, HookType_Entity, ReturnType_Edict, ThisPointer_CBaseEntity, OnStartThrow);
	
	if(g_bIsL4D2)
	{
		Handle hDetour;
		hDetour = DHookCreateFromConf(hGamedata, "CTerrorMeleeWeapon::StartMeleeSwing");
		if(!hDetour)
			SetFailState("Failed to find 'CTerrorMeleeWeapon::StartMeleeSwing' signature");
		
		if(!DHookEnableDetour(hDetour, false, OnMeleeSwingPre))
			SetFailState("Failed to detour 'CTerrorMeleeWeapon::StartMeleeSwing'");
		
		if(!DHookEnableDetour(hDetour, true, OnMeleeSwingpPost))
			SetFailState("Failed to detour 'CTerrorMeleeWeapon::StartMeleeSwing'");
	}
	
	
	Address patch = GameConfGetAddress(hGamedata, "CTerrorGun::GetRateOfFire");
	if(patch)
	{
		int offset = GameConfGetOffset(hGamedata, "CTerrorGun::GetRateOfFire_patch");
		if(offset != -1) 
		{
			if(LoadFromAddress(patch + view_as<Address>(offset), NumberType_Int8) == 0x74)
			{
				CTerrorGun__GetRateOfFire_byte_address = patch + view_as<Address>(offset);
				StoreToAddress(CTerrorGun__GetRateOfFire_byte_address, 0xEB, NumberType_Int8);
				PrintToServer("WeaponHandling CTerrorGun::GetRateOfFire Incap cycle rate patched");
			}
			else
			{
				LogError("Incorrect offset for 'CTerrorGun::GetRateOfFire_patch'.");
			}
		}
		else
		{
			LogError("Invalid offset for 'CTerrorGun::GetRateOfFire_patch'.");
		}
	}
	else
	{
		LogError("Error finding the 'CTerrorGun::GetRateOfFire' signature.'");
	}
	
	patch = GameConfGetAddress(hGamedata, "CPistol::GetRateOfFire");
	if(patch)
	{
		int offset = GameConfGetOffset(hGamedata, "CPistol::GetRateOfFire_patch");
		if(offset != -1) 
		{
			if(LoadFromAddress(patch + view_as<Address>(offset), NumberType_Int8) == 0x74)
			{
				CPistol__GetRateOfFire_byte_address = patch + view_as<Address>(offset);
				StoreToAddress(CPistol__GetRateOfFire_byte_address, 0xEB, NumberType_Int8);
				PrintToServer("WeaponHandling CPistol::GetRateOfFire Incap cycle rate patched");
			}
			else
			{
				LogError("Incorrect offset for 'CPistol::GetRateOfFire_patch'.");
			}
		}
		else
		{
			LogError("Invalid offset for 'CPistol::GetRateOfFire_patch'.");
		}
	}
	else
	{
		LogError("Error finding the 'CPistol::GetRateOfFire' signature.'");
	}
	
	delete hGamedata;
}

public void OnPluginEnd()
{
	int byte;
	
	if(CPistol__GetRateOfFire_byte_address != Address_Null)
	{
		byte = LoadFromAddress(CPistol__GetRateOfFire_byte_address, NumberType_Int8);
		if(byte == 0xEB)
		{
			StoreToAddress(CPistol__GetRateOfFire_byte_address, 0x74, NumberType_Int8);
			PrintToServer("WeaponHandling restored 'CPistol::GetRateOfFire'");
		}
	}	
	
	if(CTerrorGun__GetRateOfFire_byte_address != Address_Null)
	{
		byte = LoadFromAddress(CTerrorGun__GetRateOfFire_byte_address, NumberType_Int8);
		if(byte == 0xEB)
		{
			StoreToAddress(CTerrorGun__GetRateOfFire_byte_address, 0x74, NumberType_Int8);
			PrintToServer("WeaponHandling restored 'CTerrorGun::GetRateOfFire'");
		}
	}
}

static float ClampFloatAboveZero(float fSpeed)
{
	if(fSpeed <= 0.0)
		return 0.00001;
	return fSpeed;
}

static bool IsValidEntRef(int iEntRef)
{
	return (iEntRef != 0 && EntRefToEntIndex(iEntRef) != INVALID_ENT_REFERENCE);
}