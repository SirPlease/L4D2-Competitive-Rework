#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>

#define PLUGIN_VERSION "2.0.1"

public Plugin myinfo =
{
	name = "[L4D & 2] Fix Saferoom Ghost Spawn",
	author = "Forgetest",
	description = "Fix a glitch that ghost can spawn in saferoom while it shouldn't.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
};

int g_iOffs_LastSurvivorLeftStartArea;
Address gpTheDirector;

public void OnPluginStart()
{
	GameData gd = new GameData("l4d_fix_saferoom_ghostspawn");
	if (!gd)
		SetFailState("Missing gamedata \"l4d_fix_saferoom_ghostspawn\"");
	
	g_iOffs_LastSurvivorLeftStartArea = gd.GetOffset("CDirector::m_bLastSurvivorLeftStartArea");
	if (g_iOffs_LastSurvivorLeftStartArea == -1)
		SetFailState("Missing offset \"CDirector::m_bLastSurvivorLeftStartArea\"");
	
	delete gd;
	
	LateLoad();
}

void LateLoad()
{
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 3 && L4D_IsPlayerGhost(i))
			L4D_OnEnterGhostState(i);
	}
}

public void OnAllPluginsLoaded()
{
	gpTheDirector = L4D_GetPointer(POINTER_DIRECTOR);
}

public void L4D_OnEnterGhostState(int client)
{
	if (!IsClientInGame(client) || IsFakeClient(client))
		return;
	
	SDKHook(client, SDKHook_PreThinkPost, SDK_OnPreThink_Post);
}

void SDK_OnPreThink_Post(int client)
{
	if (!IsClientInGame(client))
		return;
	
	if (!L4D_IsPlayerGhost(client))
	{
		SDKUnhook(client, SDKHook_PreThinkPost, SDK_OnPreThink_Post);
	}
	else
	{
		int spawnstate = L4D_GetPlayerGhostSpawnState(client);
		if (spawnstate & L4D_SPAWNFLAG_RESTRICTEDAREA)
			return;
		
		Address area = L4D_GetLastKnownArea(client);
		if (area == Address_Null)
			return;
		
		if (HasLastSurvivorLeftStartArea()) // therefore free spawn in saferoom
			return;
		
		// Some stupid maps like Blood Harvest finale and The Passing finale have CHECKPOINT inside a FINALE marked area.
		int spawnattr = L4D_GetNavArea_SpawnAttributes(area);
		if (~spawnattr & NAV_SPAWN_CHECKPOINT || spawnattr & NAV_SPAWN_FINALE)
			return;
		
		/**
		 * Game code looks like this:
		 *
		 * ```cpp
		 * 	CNavArea* area = GetLastKnownArea();
		 * 	if ( area && !area->IsOverlapping(GetAbsOrigin(), 100.0) )
		 *  	area = NULL;
		 * ```
		 *
		 * "area" will then be checked for in restricted area, except when it's NULL.
		 */
		
		float origin[3];
		GetClientAbsOrigin(client, origin);
		if (NavArea_IsOverlapping(area, origin)) // make sure it's the exact case
			return;
		
		static const float kflExtendedRange = 300.0; // adjustable, 300 units should be fair enough
		if ((area = L4D_GetNearestNavArea(origin, kflExtendedRange, false, true, true, 2)) != Address_Null)
		{
			spawnattr = L4D_GetNavArea_SpawnAttributes(area);
			if (spawnattr & NAV_SPAWN_CHECKPOINT && ~spawnattr & NAV_SPAWN_FINALE)
				L4D_SetPlayerGhostSpawnState(client, spawnstate | L4D_SPAWNFLAG_RESTRICTEDAREA);
		}
	}
}

bool HasLastSurvivorLeftStartArea()
{
	return LoadFromAddress(gpTheDirector + view_as<Address>(g_iOffs_LastSurvivorLeftStartArea), NumberType_Int8);
}

bool NavArea_IsOverlapping(Address area, const float pos[3], float tolerance = 100.0)
{
	float center[3], size[3];
	L4D_GetNavAreaCenter(area, center);
	L4D_GetNavAreaSize(area, size);
	
	return ( pos[0] + tolerance >= center[0] - size[0] * 0.5 && pos[0] - tolerance <= center[0] + size[0] * 0.5
		&& pos[1] + tolerance >= center[1] - size[1] * 0.5 && pos[1] - tolerance <= center[1] + size[1] * 0.5 );
}