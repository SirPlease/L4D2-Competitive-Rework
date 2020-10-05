#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <l4d2_weapon_stocks>

new const snipers[2] =
{
	35,		// SNIPER_AWP
	36		// SNIPER_SCOUT
};

public Plugin:myinfo =
{
	name        = "L4D2 Sniper Precache",
	author      = "Visor",
	version     = "2.0",
	description = "Unlocks German sniper weapons",
	url 		= "https://github.com/Attano/Equilibrium"
};

public OnMapStart() 
{
	new WeaponId:wepid;
	decl String:buffer[64];
	
	for (new i = 0; i < sizeof(snipers); i++)
	{
		wepid = WeaponId:snipers[i];
		PrecacheModel(WeaponModels[_:wepid]);
		
		GetWeaponName(wepid, buffer, sizeof(buffer));
		new index = CreateEntityByName(buffer);
		DispatchSpawn(index);
		RemoveEdict(index);
	}
}