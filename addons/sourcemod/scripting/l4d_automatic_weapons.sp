#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

new Handle:hConVar_Enabled = INVALID_HANDLE;
new Handle:hConVar_Weapons = INVALID_HANDLE;

new bool:bEnabled = true;
new String:sAllowedWeapons[64][32];
new iAllowedWeaponsCount = 64;

//PERFORMANCE!
new iPerf_AllowedWeapon[MAXPLAYERS+1] = 0; //For very good Performance in a loop! [0 = Nothing | 1 = True | 2 = False]
new iPerf_ActiveWeapon[MAXPLAYERS+1] = -1; // For "iPerf_AllowedWeapon"

public Plugin:myinfo = 
{
	name = "Automatic Weapons",
	author = "Coder:Timocop",
	description = "Automatic Weapon (For any game? mmh)",
	version = "1.0",
	url = ""
}

public OnPluginStart()
{

	hConVar_Enabled = CreateConVar("l4d_autopistols_enabled", "1", "是否启用插件 1=启用 0=禁用", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	hConVar_Weapons = CreateConVar("l4d_autopistols_weapons", "weapon_pistol;weapon_pistol_magnum;weapon_sniper_scout;weapon_sniper_awp", "选择需要连击的武器 用;号隔开来 不要空格", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	
	HookConVarChange(hConVar_Enabled, ConVarChanged);
	HookConVarChange(hConVar_Weapons, ConVarChanged);
	
	AutoExecConfig(true, "l4d_automatic_weapons");
	
	WeaponStringCalculation();
}

public ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == hConVar_Enabled)
	{
		bEnabled = GetConVarBool(hConVar_Enabled);
	}
	else if(convar == hConVar_Weapons)
	{
		WeaponStringCalculation();
	}
}

WeaponStringCalculation()
{
	decl String:sConVarAllowedWeapons[256];
	GetConVarString(hConVar_Weapons, sConVarAllowedWeapons, sizeof(sConVarAllowedWeapons));
	
	new iWeaponNumbers = ReplaceString(sConVarAllowedWeapons, sizeof(sConVarAllowedWeapons), ";", ";", false);
	iAllowedWeaponsCount = iWeaponNumbers;

	ExplodeString(sConVarAllowedWeapons, ";", sAllowedWeapons, iWeaponNumbers + 1, 32);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{ 
	if(!bEnabled)
	return Plugin_Continue;

	if (buttons & IN_ATTACK)
	{
		if(!IsClientInGame(client)
			|| !IsPlayerAlive(client)
			|| GetClientTeam(client) != 2)
		return Plugin_Continue;

		new iActiveWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		new bWeaponChanged = ((iActiveWeapon != iPerf_ActiveWeapon[client]) || (iPerf_ActiveWeapon[client] == -1));
		iPerf_ActiveWeapon[client] = iActiveWeapon;
		
		if(bWeaponChanged)
		{
			iPerf_AllowedWeapon[client] = 0;
		}
		
		if(!IsAllowedWeapon(client))
		return Plugin_Continue;
		
		if(!IsValidEntity(iActiveWeapon)
				|| GetEntPropFloat(iActiveWeapon, Prop_Send, "m_flCycle") > 0
				|| GetEntProp(iActiveWeapon, Prop_Send, "m_bInReload") > 0)
		return Plugin_Continue;

		// SetEntProp(CurrentWeapon, Prop_Send, "m_isHoldingFireButton", 1); //Is holding the IN_ATTACK
		SetEntProp(iActiveWeapon, Prop_Send, "m_isHoldingFireButton", 0); //Is not holding the IN_ATTACK // LOOOOOOOOOOOOOOOL SEMS LEGIT
		ChangeEdictState(iActiveWeapon, FindDataMapOffs(iActiveWeapon, "m_isHoldingFireButton"));
			
		//EmitSoundToClient(client,"^weapons/pistol/gunfire/pistol_fire.wav"); // The "Normal" Fire sound is little buggy...
	}
	/* else
	{
		if(iPerf_AllowedWeapon[client])
		iPerf_AllowedWeapon[client] = 0;
	} */
	return Plugin_Continue;
}


stock bool:IsAllowedWeapon(client)
{
	if(iPerf_AllowedWeapon[client] == 1)
	return true;
	else if(iPerf_AllowedWeapon[client] == 2)
	return false;
	
	decl String:sCurrentWeaponName[32];
	GetClientWeapon(client, sCurrentWeaponName, sizeof(sCurrentWeaponName));
	
	for(new i = 0; i <= iAllowedWeaponsCount; i++)
	{
		if(StrEqual(sAllowedWeapons[i], sCurrentWeaponName, false))
		{
			iPerf_AllowedWeapon[client] = 1;
			return true;
		}
		
	}
	
	iPerf_AllowedWeapon[client] = 2;
	return false;
}
