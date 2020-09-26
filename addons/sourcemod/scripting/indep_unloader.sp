/*========================================================================================

------------ Change Log:

===> V1.0
- Loads into Plugins and when OnPluginEnd is called, deal with the functions that aren't being reset.

===> V1.1
- Do everything on OnPluginStart so that we don't need to have it loaded all the time.
- The Plugin will not make sure the Server's "vanilla" when the plugins get loaded (which is when matchmodes unload and when the server boots, or map changes if the plugin is unloaded before the map change)

========================================================================================*/

#pragma newdecls required
#include <sourcemod>
#include <sdktools>

ConVar director_no_specials, god, sb_stop, sv_infinite_primary_ammo, z_common_limit;

public Plugin myinfo =
{
	name = "Independent Unloader",
	author = "Sir",
	description = "Used for Competitive stuff that needs to be undone on config unload, but can't be called on OnPluginEnd due to dependencies.",
	version = "1.1",
	url = ""
};

public void OnPluginStart()
{
	director_no_specials = FindConVar("director_no_specials");
	god = FindConVar("god");
	sb_stop = FindConVar("sb_stop");
	z_common_limit = FindConVar("z_common_limit");
	sv_infinite_primary_ammo = FindConVar("sv_infinite_primary_ammo");

	/////////////////////////////////////////////////////////
	// 
	// - For Ready-up unloading~
	//

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i)) 
			SetClientUnfrozen(i);
	}

	EnableEntities();

	// Back to Vanilla ConVars. (Quietly)
	director_no_specials.Flags = director_no_specials.Flags & ~FCVAR_NOTIFY;
	god.Flags = god.Flags & ~FCVAR_NOTIFY;
	sb_stop.Flags = sb_stop.Flags & ~FCVAR_NOTIFY;
	sv_infinite_primary_ammo.Flags = sv_infinite_primary_ammo.Flags & ~FCVAR_NOTIFY;
	z_common_limit.Flags = z_common_limit.Flags & ~FCVAR_NOTIFY;

	director_no_specials.BoolValue = false
	god.BoolValue = false;
	sb_stop.BoolValue = false;
	sv_infinite_primary_ammo.BoolValue = false;
	z_common_limit.IntValue = 30;

	director_no_specials.Flags = director_no_specials.Flags | FCVAR_NOTIFY;
	god.Flags = god.Flags | FCVAR_NOTIFY;
	sb_stop.Flags = sb_stop.Flags | FCVAR_NOTIFY;
	sv_infinite_primary_ammo.Flags = sv_infinite_primary_ammo.Flags | FCVAR_NOTIFY;
	z_common_limit.Flags = z_common_limit.Flags | FCVAR_NOTIFY;
}

void EnableEntities() 
{	
	ActivateEntities("prop_door_rotating", "SetBreakable");
	MakePropsBreakable();
}

void SetClientUnfrozen(int client)
{
	SetEntityMoveType(client, MOVETYPE_WALK);
}

void ActivateEntities(char[] className, char[] inputName) 
{ 
	int iEntity;
	
	while ((iEntity = FindEntityByClassname(iEntity, className)) != -1 ) 
	{
		if (!IsValidEdict(iEntity) || !IsValidEntity(iEntity)) 
			continue;
			
		if (GetEntProp(iEntity, Prop_Data, "m_spawnflags") & (1 << 19)) 
			continue;
	
		AcceptEntityInput(iEntity, inputName);
	}
}

void MakePropsBreakable() 
{
	int iEntity;
	
	while ((iEntity = FindEntityByClassname(iEntity, "prop_physics")) != -1 ) {
	if ( !IsValidEdict(iEntity) ||  !IsValidEntity(iEntity) ) {
		continue;
	}
	DispatchKeyValueFloat(iEntity, "minhealthdmg", 5.0);
	}
}