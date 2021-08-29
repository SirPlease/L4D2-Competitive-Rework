#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>

#define DEBUG 0
#define PLUGIN_VERSION "1.2b"

public Plugin myinfo =
{
	name = "[L4D & 2] Backjump Fix",
	author = "Forgetest",
	description = "Fix hunter being unable to pounce off non-static props",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
};

#define GAMEDATA_FILE "l4d2_si_ability"
#define KEY_ONTOUCH "CBaseAbility::OnTouch"
#define KEY_BLOCKMIDPOUNCE "CLunge->m_blockMidPounce"

Handle hCLunge_OnTouch;
int iCLunge_BlockMidPounce;

public void OnPluginStart()
{
	Handle conf = LoadGameConfigFile(GAMEDATA_FILE);
	if (conf == null)
		SetFailState("Missing gamedata \"" ... GAMEDATA_FILE ... "\"");
	
	int iCLungeOnTouch = GameConfGetOffset(conf, KEY_ONTOUCH);
	if (iCLungeOnTouch == -1)
		SetFailState("Failed to get offset \"" ... KEY_ONTOUCH ... "\"");
	
	hCLunge_OnTouch = DHookCreate(iCLungeOnTouch, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, CLunge_OnTouch);
	DHookAddParam(hCLunge_OnTouch, HookParamType_CBaseEntity);
	
	iCLunge_BlockMidPounce = GameConfGetOffset(conf, KEY_BLOCKMIDPOUNCE);
	if (iCLunge_BlockMidPounce == -1)
		SetFailState("Failed to get offset \"" ... KEY_BLOCKMIDPOUNCE ... "\"");
	
	delete conf;
	
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || GetClientTeam(client) != 3 || GetEntProp(client, Prop_Send, "m_zombieClass") != 3)
		return;
		
	int ability = GetEntPropEnt(client, Prop_Send, "m_customAbility");
	if (ability != -1)
	{
		DHookEntity(hCLunge_OnTouch, false, ability);
	}
}

public MRESReturn CLunge_OnTouch(int pThis, Handle hParams)
{
	int other = DHookGetParam(hParams, 1);
	if (other <= 0) return MRES_Ignored;
	
	int hunter = GetEntPropEnt(pThis, Prop_Send, "m_owner");
	if (hunter == -1) return MRES_Ignored;
	
#if DEBUG
	static int iLast = -1;
	if (other != iLast)
	{
		static char cls[64];
		GetEntityClassname(other, cls, 64);
		PrintToChat(hunter, "other: %s (%i), solid: %i", cls, other, Entity_IsSolid(other));
		iLast = other;
	}
#endif
	
	// NOTE:
	//
	// Weapons (guns, melees, etc) are solid as well, so they'd be blocked.
	//
	// Should've performed stricter check here, by comparing the classname,
	// instead of just checking for property "m_weaponID", because
	// weapons that are not spawners don't have such property.
	//
	// For the sake that this function is pretty of high density, and there
	// can be incredibly limited chance that a hunter pounces right off
	// a dropped weapon, as well as my belief in that single `HasEntProp`
	// has better efficiency,
	// I decided to make a spawner-only check here.
	
	//static char clsname[64];
	//if (!GetEdictClassname(other, clsname, sizeof clsname)) return MRES_Ignored;
	
	if (/*strncmp(clsname, "weapon", 6) == 0*/
		HasEntProp(other, Prop_Send, "m_weaponID") || GetEntPropEnt(hunter, Prop_Send, "m_hGroundEntity") != -1
	) {
		if (other <= MaxClients)
		{
			SetEntData(pThis, iCLunge_BlockMidPounce, 1, 1);
		}
	}
	else if (!GetEntData(pThis, iCLunge_BlockMidPounce, 1))
	{
		if (Entity_IsSolid(other))
		{
			float now = GetGameTime();
			
			float duration = GetEntPropFloat(pThis, Prop_Send, "m_lungeAgainTimer", 0);
			float timestamp = GetEntPropFloat(pThis, Prop_Send, "m_lungeAgainTimer", 1);
			
			if (duration != 0.5)
			{
				// Supposed to be a CountdownTimer::NetworkStateChanged(void *)
				// Empty function, so just skip it.
				SetEntPropFloat(pThis, Prop_Send, "m_lungeAgainTimer", 0.5, 0);
			}
			if (timestamp != now + 0.5)
			{
				// Supposed to be a CountdownTimer::NetworkStateChanged(void *)
				// Empty function, so just skip it.
				SetEntPropFloat(pThis, Prop_Send, "m_lungeAgainTimer", now + 0.5, 1);
			}
		}
	}
	return MRES_Supercede;
}

// https://forums.alliedmods.net/showthread.php?t=147732
#define SOLID_NONE 0
#define FSOLID_NOT_SOLID 0x0004
/**
 * Checks whether the entity is solid or not.
 *
 * @param entity            Entity index.
 * @return                    True if the entity is solid, false otherwise.
 */
stock bool Entity_IsSolid(int entity)
{
    return (GetEntProp(entity, Prop_Send, "m_nSolidType", 1) != SOLID_NONE &&
            !(GetEntProp(entity, Prop_Send, "m_usSolidFlags", 2) & FSOLID_NOT_SOLID));
}