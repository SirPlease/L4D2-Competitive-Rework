/*
*	Left 4 DHooks Direct - TESTER
*	Copyright (C) 2023 Silvers
*
*	This program is free software: you can redistribute it and/or modify
*	it under the terms of the GNU General Public License as published by
*	the Free Software Foundation, either version 3 of the License, or
*	(at your option) any later version.
*
*	This program is distributed in the hope that it will be useful,
*	but WITHOUT ANY WARRANTY; without even the implied warranty of
*	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*	GNU General Public License for more details.
*
*	You should have received a copy of the GNU General Public License
*	along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/



#define PLUGIN_VERSION		"1.133"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Left 4 DHooks Direct - TESTER
*	Author	:	SilverShot
*	Descrp	:	Left 4 DHooks Direct - Demo and Test plugin.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=321696
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

	- See forum thread: https://forums.alliedmods.net/showthread.php?t=321696
	- OR: See the "scripting/l4dd/left4dhooks_changelog.txt" file.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <left4dhooks>
#define REQUIRE_PLUGIN

#define MAX_CALLS			1		// How many times to print each forward
#define DEMO_ANIM			0		// Demonstrate "Incapped Crawling" animation hooks

bool g_bLeft4Dead2;
bool g_bLibraryActive;
bool g_bTestForwards =		true;	// To enable forwards testing
int g_iForwardsMax;					// Total forwards we expect to see
int g_iForwards;



// ====================================================================================================
//					PLUGIN INFO / START
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Left 4 DHooks Direct - TESTER",
	author = "SilverShot",
	description = "Left 4 DHooks Direct - Demo and Test plugin.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=321696"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test == Engine_Left4Dead ) g_bLeft4Dead2 = false;
	else if( test == Engine_Left4Dead2 ) g_bLeft4Dead2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}

	if( g_bLeft4Dead2 )
		g_iForwardsMax = 178;
	else
		g_iForwardsMax = 126;

	return APLRes_Success;
}

public void OnLibraryAdded(const char[] name)
{
	if( strcmp(name, "left4dhooks") == 0 )
		g_bLibraryActive = true;
}

public void OnLibraryRemoved(const char[] name)
{
	if( strcmp(name, "left4dhooks") == 0 )
		g_bLibraryActive = false;
}

public void OnAllPluginsLoaded()
{
	if( g_bLibraryActive == false )
		LogError("Required plugin left4dhooks is missing.");
}

public void OnPluginStart()
{
	RegAdminCmd("sm_l4df", sm_l4df, ADMFLAG_ROOT);
	RegAdminCmd("sm_l4dd", sm_l4dd, ADMFLAG_ROOT);

	#if DEMO_ANIM
	HookEvent("player_incapacitated",	player_incapacitated);
	HookEvent("revive_success",			revive_success);
	HookEvent("player_death",			player_death);
	HookEvent("round_end",				round_end);
	HookEvent("player_spawn",			player_spawn);
	#endif
}





// ====================================================================================================
// PIPEBOMB PROJECTILE - Fuse and Light particles
// ====================================================================================================
#define PARTICLE_FUSE						"weapon_pipebomb_fuse"
#define PARTICLE_LIGHT						"weapon_pipebomb_blinking_light"

public void OnMapStart()
{
	// PipeBomb projectile
	PrecacheParticle(PARTICLE_FUSE);
	PrecacheParticle(PARTICLE_LIGHT);
}

stock void CreateParticle(int target, int type)
{
	int entity = CreateEntityByName("info_particle_system");
	if( type == 0 )	DispatchKeyValue(entity, "effect_name", PARTICLE_FUSE);
	else			DispatchKeyValue(entity, "effect_name", PARTICLE_LIGHT);

	DispatchSpawn(entity);
	ActivateEntity(entity);
	AcceptEntityInput(entity, "Start");

	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", target);

	if( type == 0 )	SetVariantString("fuse");
	else			SetVariantString("pipebomb_light");
	AcceptEntityInput(entity, "SetParentAttachment", target);
}

stock void PrecacheParticle(const char[] sEffectName)
{
	static int table = INVALID_STRING_TABLE;
	if( table == INVALID_STRING_TABLE )
	{
		table = FindStringTable("ParticleEffectNames");
	}

	if( FindStringIndex(table, sEffectName) == INVALID_STRING_INDEX )
	{
		bool save = LockStringTables(false);
		AddToStringTable(table, sEffectName);
		LockStringTables(save);
	}
}





// ====================================================================================================
// CRAWLING TEST - Remove "INCAPPED CRAWLING WITH ANIMATION" plugin to test
// ====================================================================================================
#if DEMO_ANIM
bool g_bCrawling;

void player_spawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client && IsClientInGame(client) )
		AnimHookEnable(client, OnAnimPre, OnAnimPost);
}

void player_incapacitated(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( GetClientTeam(client) == 2 )
		AnimHookEnable(client, OnAnimPre, OnAnimPost);
}

void revive_success(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	AnimHookDisable(client, OnAnimPre, OnAnimPost);
}

void player_death(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	AnimHookDisable(client, OnAnimPre, OnAnimPost);
}

void round_end(Event event, const char[] name, bool dontBroadcast)
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		AnimHookDisable(i, OnAnimPre, OnAnimPost);
	}
}

// Uses "Activity" numbers, which means 1 animation number is the same for all Survivors.
Action OnAnimPre(int client, int &anim)
{
	// /*
	if( g_bCrawling )
	{
		// anim = g_bLeft4Dead2 ? 696 : 1197;
		anim = g_bLeft4Dead2 ? L4D2_ACT_TERROR_INCAP_CRAWL : L4D1_ACT_TERROR_INCAP_CRAWL; // Include file now has *_ACT_* constants from version 1.52
		return Plugin_Changed;
	}
	// */

	return Plugin_Continue;
}

// Uses "m_nSequence" animation numbers, which are different for each character model.
Action OnAnimPost(int client, int &anim)
{
	/*
	if( g_bCrawling )
	{
		static char model[40];
		GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));

		switch( model[29] )
		{
			// case 'c': { Format(model, sizeof(model), "coach");		anim = -1; }
			case 'b': { anim = 631; }	// gambler
			case 'h': { anim = 636; }	// mechanic
			case 'd': { anim = 639; }	// producer
			case 'v': { anim = 539; }	// NamVet
			case 'e': { anim = 542; }	// Biker
			case 'a': { anim = 539; }	// Manager
			case 'n': { anim = 529; }	// TeenGirl
		}

		return Plugin_Changed;
	}
	// */

	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	// Incapped
	g_bCrawling = false;

	if(
		buttons & IN_FORWARD &&
		GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) &&
		GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1) == 0
	)
	{
		if(
			GetClientTeam(client) == 2 &&
			IsFakeClient(client) == false &&
			IsPlayerAlive(client) == true &&
			GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") <= 0 &&
			GetEntPropEnt(client, Prop_Send, "m_tongueOwner") <= 0 &&
			GetEntPropEnt(client, Prop_Send, "m_reviveOwner") <= 0 &&
			(!g_bLeft4Dead2 || GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") <= 0)
		)
		{
			g_bCrawling = true;
		}
	}

	return Plugin_Continue;
}
#endif
// ====================================================================================================





// ====================================================================================================
// COMMAND TEST
// ====================================================================================================
Action sm_l4df(int client, int args)
{
	ReplyToCommand(client, "[Left4DHooks] Forwards triggered %d/%d", g_iForwards, g_iForwardsMax);
	return Plugin_Handled;
}

stock Action TimerCancelStagger(Handle timer, int client)
{
	client = GetClientOfUserId(client);
	if( client )
	{
		L4D_CancelStagger(client);
	}

	return Plugin_Continue;
}

Action sm_l4dd(int client, int args)
{
	/*
		NOTE:
		Uncomment the things you want to test. All disabled by default.
		Must test individual sections on their own otherwise you'll receive errors about symbols already defined..
	*/



	/*
	int victim, attacker;
	victim = GetRandomSurvivor(1, -1);
	attacker = GetRandomInfected(1, -1);

	if( L4D2_GetPlayerZombieClass(attacker) == L4D2ZombieClass_Hunter )
	{
		L4D_ForceHunterVictim(victim, attacker);
		PrintToChatAll("Forced Hunter %N on %N", attacker, victim);

		L4D_Hunter_ReleaseVictim(victim, attacker);
	}

	if( L4D2_GetPlayerZombieClass(attacker) == L4D2ZombieClass_Smoker )
	{
		L4D_ForceSmokerVictim(victim, attacker);
		PrintToChatAll("Forced Smoker %N on %N", attacker, victim);

		L4D_Smoker_ReleaseVictim(victim, attacker);
	}

	if( L4D2_GetPlayerZombieClass(attacker) == L4D2ZombieClass_Jockey )
	{
		L4D2_ForceJockeyVictim(victim, attacker);
		PrintToChatAll("Forced Jockey %N on %N", attacker, victim);
	}

	if( L4D2_GetPlayerZombieClass(attacker) == L4D2ZombieClass_Charger )
	{
		victim = L4D_GetVictimCarry(attacker);
		L4D2_Charger_EndCarry(victim, attacker);
		PrintToChatAll("Forced Charger drop %N on %N", attacker, victim);
	}
	// */



	// int entity = GetClientAimTarget(client, false);
	// PrintToChatAll("L4D_IsTankProp %d", L4D_IsTankProp(entity));



	// PrintToChatAll("Old spawn time: %f", L4D_GetPlayerSpawnTime(client));
	// L4D_SetPlayerSpawnTime(client, 25.0, false);
	// PrintToChatAll("New spawn time: %f", L4D_GetPlayerSpawnTime(client));
	// PrintToChatAll("Direct_GetSpawnTimer %f", CTimer_GetElapsedTime(L4D2Direct_GetSpawnTimer(client)));



	/*
	// Get TheNavAreas - check for connected areas
	ArrayList aList = new ArrayList();
	L4D_GetAllNavAreas(aList);

	int size = aList.Length;

	// Get random area
	Address targ;
	Address area = aList.Get(GetRandomInt(0, size - 1));
	int id = L4D_GetNavAreaID(area);
	float vPos[3], vEnd[3];

	PrintToServer("Testing ID: %d Nav: (%d) area for connections in %d areas", id, area, size);

	// VScript test:
	// -----
	char code[256];
	char buffer[256];
	L4D_GetNavAreaPos(area, vPos);
	// -----

	// Check against all addresses:
	for( int i = 0; i < size; i++ )
	{
		targ = aList.Get(i);

		// VScript test
		// -----
		L4D_GetNavAreaPos(targ, vEnd);
		Format(code, sizeof(code), "ret <- NavMesh.GetNavArea(Vector(%f, %f, %f), 500.000000); tst <- NavMesh.GetNavArea(Vector(%f, %f, %f), 50.000000); if (ret && tst) <RETURN>ret.IsConnected(tst, 4)</RETURN>;", vEnd[0], vEnd[1], vEnd[2], vPos[0], vPos[1], vPos[2]);
		buffer[0] = 0;
		L4D2_GetVScriptOutput(code, buffer, sizeof(buffer));
		if( buffer[0] )
			PrintToServer("VS: [%s] - %d", buffer, targ);
		// -----

		// Native test
		if( L4D_NavArea_IsConnected(area, targ, 4) )
		{
			L4D_GetNavAreaPos(targ, vEnd);

			PrintToServer("Area %d (%d) is connected (dist: %f)", L4D_GetNavAreaID(targ), targ, GetVectorDistance(vPos, vEnd));
		}

		// For some reason the VScript and Native versions sometimes return true for areas that the other does not return true for.
	}

	delete aList;
	// */




	// L4D_WarpToValidPositionIfStuck(client);



	// PrintToServer("L4D2_GetFirstSpawnClass %d", L4D2_GetFirstSpawnClass());
	// PrintToServer("L4D2_SetFirstSpawnClass set to 1", L4D2_SetFirstSpawnClass(1));



	/*
	// Get TheNavAreas
	ArrayList aList = new ArrayList();
	L4D_GetAllNavAreas(aList);

	int size = aList.Length;

	// Print all addresses:
	// for( int i = 0; i < size; i++ )
	// {
		// PrintToServer("%4d. %d (ID=%d)", i, aList.Get(i), L4D_GetNavAreaID(aList.Get(i)));
	// }

	// Get random area
	Address area = aList.Get(GetRandomInt(0, size - 1));
	int id = L4D_GetNavAreaID(area);
	PrintToServer("AREA %d (ID=%d) out of %d", area, id, size);
	PrintToServer("ID test %d == %d", id, L4D_GetNavAreaByID(id));

	// Get origin
	float vPos[3];
	L4D_GetNavAreaPos(area, vPos);
	PrintToServer("POS %f %f %f", vPos[0], vPos[1], vPos[2]);

	// Get size
	float vSize[3];
	L4D_GetNavAreaSize(area, vSize);
	PrintToServer("SIZE %f %f %f", vSize[0], vSize[1], vSize[2]);

	// Get center
	float vMid[3];
	L4D_GetNavAreaCenter(area, vMid);
	PrintToServer("CENTER %f %f %f", vMid[0], vMid[1], vMid[2]);

	delete aList;
	// */



	// PrintToChatAll("ANY_CHECK %d ANY_START %d FIRST %d LAST %d", L4D_IsAnySurvivorInCheckpoint(), L4D_IsAnySurvivorInStartArea(), L4D_IsInFirstCheckpoint(client), L4D_IsInLastCheckpoint(client));



	/*
	float vPos[3];
	GetClientAbsOrigin(client, vPos);

	PrintToServer("L4D_IsPositionInFirstCheckpoint %N == %d", client, L4D_IsPositionInFirstCheckpoint(vPos));
	PrintToServer("L4D_IsPositionInLastCheckpoint %N == %d", client, L4D_IsPositionInLastCheckpoint(vPos));
	*/



	/*
	float vPos[3];

	GetClientEyePosition(client, vPos);
	PrintToChatAll("Eye %f %f %f", vPos[0], vPos[1], vPos[2]);

	GetClientAbsOrigin(client, vPos);
	PrintToChatAll("Abs %f %f %f", vPos[0], vPos[1], vPos[2]);

	L4D_GetEntityWorldSpaceCenter(client, vPos);
	PrintToChatAll("Cen %f %f %f", vPos[0], vPos[1], vPos[2]);
	*/



	// float vPos[3];
	// GetClientAbsOrigin(client, vPos);
	// PrintToChatAll("FIRST %d", L4D_IsPositionInFirstCheckpoint(vPos));
	// PrintToChatAll("LAST %d", L4D_IsPositionInLastCheckpoint(vPos));



	// Test for "L4D_OnCancelStagger" and "L4D_OnMotionControlledXY" forwards
	// L4D_StaggerPlayer(client, client, NULL_VECTOR);
	// CreateTimer(1.0, TimerCancelStagger, GetClientUserId(client));



	// L4D_SetBecomeGhostAt(client, GetGameTime() + 15.0); // Working



	/*
	if( GetFeatureStatus(FeatureType_Native, "Left4DHooks_Version") == FeatureStatus_Available )
		PrintToServer("Left4DHooks_Version = %d", Left4DHooks_Version());
	else
		PrintToServer("Left4DHooks_Version = Unable to determine, could break down version cvar instead.", Left4DHooks_Version());
	*/



	/*
	if( g_bLeft4Dead2 )
	{
		int charger;

		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) && GetClientTeam(i) == 3 && L4D2_GetPlayerZombieClass(i) == L4D2_ZOMBIE_CLASS_CHARGER )
			{
				charger = i;
				break;
			}
		}

		if( charger )
		{
			PrintToServer("L4D2_GetQueuedPummelStartTime %d", L4D2_GetQueuedPummelStartTime(charger));
			PrintToServer("L4D2_IsInQueuedPummel %d", L4D2_IsInQueuedPummel(charger));
			PrintToServer("L4D2_GetQueuedPummelAttacker %d", L4D2_GetQueuedPummelAttacker(charger));
			PrintToServer("L4D2_GetQueuedPummelVictim %d", L4D2_GetQueuedPummelVictim(charger));
		}
	}
	// */



	// PrintToServer("L4D_AreAllSurvivorsInFinaleArea %d", L4D_AreAllSurvivorsInFinaleArea()); // WORKS



	/*
	if( g_bLeft4Dead2 )
	{
		int target = GetRandomInfected(1, 1);
		if( target )
		{
			float vPos[3];
			GetClientEyePosition(target, vPos);
			PrintToChatAll("L4D2_IsVisibleToPlayer %d", L4D2_IsVisibleToPlayer(client, 2, 3, 0, vPos)); // WORKS
		}
	}
	// */



	/*
	if( g_bLeft4Dead2 )
	{
		int bot = GetRandomSurvivor(1, 1);
		int target = GetRandomInfected(1, 1);

		L4D2_CommandABot(bot, 0, BOT_CMD_MOVE, view_as<float>({-3612.902832, 2533.870605, 316.031250})); // WORKS

		L4D2_CommandABot(bot, 0, BOT_CMD_RESET); // WORKS
		L4D2_CommandABot(bot, target, BOT_CMD_ATTACK); // WORKS

		// Retreat from Tank
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i) && L4D2_GetPlayerZombieClass(i) == L4D2_ZOMBIE_CLASS_TANK )
			{
				L4D2_CommandABot(bot, target, BOT_CMD_RETREAT); // WORKS
				break;
			}
		}



		// PrintToServer("L4D_CleanupPlayerState", L4D_CleanupPlayerState(client)); // WORKS



		// WORKS
		// PrintToServer("L4D2_GetDirectorScriptScope 0 = %d",L4D2_GetDirectorScriptScope(0));
		// PrintToServer("L4D2_GetDirectorScriptScope 1 = %d",L4D2_GetDirectorScriptScope(1));
		// PrintToServer("L4D2_GetDirectorScriptScope 2 = %d",L4D2_GetDirectorScriptScope(2));
		// PrintToServer("L4D2_GetDirectorScriptScope 3 = %d",L4D2_GetDirectorScriptScope(3));
		// PrintToServer("L4D2_GetDirectorScriptScope 4 = %d",L4D2_GetDirectorScriptScope(4));
	}
	// */



	/*
	float vPos[3];
	GetClientAbsOrigin(client, vPos);
	Address navarea = L4D_GetNearestNavArea(vPos, 100.0);
	PrintToServer("L4D_GetNavArea_AttributeFlags %d", L4D_GetNavArea_AttributeFlags(navarea));
	PrintToServer("L4D_GetNavArea_SpawnAttributes %d", L4D_GetNavArea_SpawnAttributes(navarea));
	*/



	/*
	char retValue[64];
	L4D2_GetScriptValueString("OnChangeFinaleMusic", "", retValue, sizeof(retValue));
	PrintToServer("L4D2_GetScriptValueString \"OnChangeFinaleMusic\" == \"%s\"", retValue);

	// Map "c10m5_houseboat" test:
	// L4D2_GetScriptValueString("A_CustomFinale1", "N/A", retValue, sizeof(retValue));
	// PrintToServer("L4D2_GetScriptValueString \"A_CustomFinale1\" == \"%s\"", retValue);
	// L4D2_GetScriptValueString("A_CustomFinaleValue1", "N/A", retValue, sizeof(retValue));
	// PrintToServer("L4D2_GetScriptValueString \"A_CustomFinaleValue1\" == \"%s\"", retValue);
	// L4D2_GetScriptValueString("A_CustomFinaleValue5", "N/A", retValue, sizeof(retValue));
	// PrintToServer("L4D2_GetScriptValueString \"A_CustomFinaleValue5\" == \"%s\"", retValue);
	// L4D2_GetScriptValueString("A_CustomFinaleMusic5", "N/A", retValue, sizeof(retValue));
	// PrintToServer("L4D2_GetScriptValueString \"A_CustomFinaleMusic5\" == \"%s\"", retValue);
	*/



	/*
	// Testing SDKCall replacement of native VScript wrapper.
	// Tested on c1m2_streets
	float vPos[3];
	float vEnd[3];
	vPos = view_as<float>({ 2449.840576, 5027.909179, 448.031250 });	// Saferoom start
	vEnd = view_as<float>({ -7481.826660, -4701.759277, 384.281250 });	// Saferoom end
	vEnd = view_as<float>({ 2860.525634, 4751.391113, 448.031250 });	// Out-of-bounds left of first saferoom exit on c1m2_streets

	// VScript shows true, sdkcall shows false which is correct and SDKCall returning the expected result
	// VScript uses "99999.999" as nearest nav area, so it finds a valid one where SDKCall requires you to find nav area
	// vEnd = view_as<float>({ -17481.826660, -4701.759277, 384.281250 });	// Saferoom end but with -17 instead of -7

	// vEnd = view_as<float>({ 2048.739013, 2895.070556, 718.817260 });	// Invalid position on top of bus
	// vEnd = view_as<float>({ 1743.588867, 2676.366455, 744.114746 });	// Invalid position on top of tent

	PrintToServer("L4D2_VScriptWrapper_NavAreaBuildPath %b", L4D2_VScriptWrapper_NavAreaBuildPath(vPos, vEnd, 99999.999, false, true, 2, false));

	Address nav1 = L4D_GetNearestNavArea(vPos, 100.0);
	Address nav2 = L4D_GetNearestNavArea(vEnd, 100.0);

	PrintToServer("L4D2_NavAreaBuildPath %d", L4D2_NavAreaBuildPath(nav1, nav2, 99999.999, 2, false));
	PrintToServer("L4D2_NavAreaBuildPath2 %d", L4D2_NavAreaBuildPath2(nav1, nav2, 99999.999, 2, false));
	// */



	/*
	// Method to detonate VomitJar. Must impact the ground, "L4D_DetonateProjectile" will make it detonate but no particles or smoke will appear. Only the affect within the area.
	float vAng[3], vPos[3];
	GetClientEyePosition(client, vPos);
	vPos[2] += 50.0; // Move projectile above player to avoid collision
	vAng = view_as<float>({ 0.0, 0.0, 500.0 }); // Shoot upwards

	int projectile = L4D2_VomitJarPrj(client, vPos, vAng);
	CreateTimer(1.0, TimerDetonateVomitjar, EntIndexToEntRef(projectile));
	// */

	/*
	float vPos[3], vAng[3];

	GetClientEyeAngles(client, vAng);
	GetClientEyePosition(client, vPos);

	Handle trace = TR_TraceRayFilterEx(vPos, vAng, MASK_SHOT, RayType_Infinite, TraceFilter, client);

	if( TR_DidHit(trace) )
	{
		TR_GetEndPosition(vPos, trace);
		TR_GetPlaneNormal(trace, vAng);
		delete trace;
// "inferno", "insect_swarm", "fire_cracker_blast"
		int entity = CreateEntityByName("insect_swarm");
		if( entity != -1 )
		{
			PrintToChatAll("Insect_swarm %d", entity);
			L4D_StartBurning(entity, vPos, vAng, view_as<float>({ 0.0, 0.0, 0.0 }));
		}
	}
	// */



	// =========================
	// STOCKS - left4dhooks_silver
	// =========================
	/*
	StopUsingMinigun(client);

	// Jockey tests
	int survivor = GetRandomSurvivor(1, 0);
	if( survivor )
	{
		int jockey;

		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) && GetClientTeam(i) == 3 && L4D2_GetPlayerZombieClass(i) == L4D2_ZOMBIE_CLASS_JOCKEY )
			{
				jockey = i;
				break;
			}
		}

		if( jockey )
		{
			L4D2_Jockey_EndRide(survivor, jockey);
		}
	}
	// */

	/*
	// Charger tests
	int survivor = GetRandomSurvivor(1, 0);
	if( survivor )
	{
		int charger;

		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) && GetClientTeam(i) == 3 && L4D2_GetPlayerZombieClass(i) == L4D2_ZOMBIE_CLASS_CHARGER )
			{
				charger = i;
				break;
			}
		}

		if( charger )
		{
			L4D2_Charger_StartCarryingVictim(survivor, charger);
			L4D2_Charger_PummelVictim(survivor, charger);
			L4D2_Charger_EndPummel(survivor, charger);
			L4D2_Charger_ThrowImpactedSurvivor(survivor, charger);
		}
	}

	PrintToServer("L4D_GetCheckpointFirst = %d", L4D_GetCheckpointFirst());
	PrintToServer("L4D_GetCheckpointLast = %d", L4D_GetCheckpointLast());

	PrintToServer("GetAnyRandomClient = %d", GetAnyRandomClient());
	PrintToServer("GetRandomSurvivor = %d", GetRandomSurvivor());
	PrintToServer("GetRandomInfected = %d", GetRandomInfected());

	int entity = FindEntityByClassname(-1, "prop_door*");
	if( entity != INVALID_ENT_REFERENCE )
	{
		PrintToServer("L4D_EntityParent %d",				L4D_EntityParent(entity));
		PrintToServer("L4D_GetDoorState %d",				L4D_GetDoorState(entity));
		PrintToServer("L4D_GetDoorFlag %d",					L4D_GetDoorFlag(entity));
	}

	PrintToServer("L4D_IsEngineLeft4Dead %d",				L4D_IsEngineLeft4Dead());
	PrintToServer("L4D_IsEngineLeft4Dead1 %d",				L4D_IsEngineLeft4Dead1());
	PrintToServer("L4D_IsEngineLeft4Dead2 %d",				L4D_IsEngineLeft4Dead2());
	PrintToServer("L4D_GetCommonsCount %d",					L4D_GetCommonsCount());
	PrintToServer("L4D_GetPlayerCurrentWeapon %d",			L4D_GetPlayerCurrentWeapon(client));
	PrintToServer("L4D_GetPlayerCustomAbility %d",			L4D_GetPlayerCustomAbility(client));
	PrintToServer("L4D_GetPlayerUseTarget %d",				L4D_GetPlayerUseTarget(client));
	PrintToServer("L4D_GetVictimHunter %d",					L4D_GetVictimHunter(client));
	PrintToServer("L4D_GetVictimSmoker %d",					L4D_GetVictimSmoker(client));
	PrintToServer("L4D_GetVictimCharger %d",				L4D_GetVictimCharger(client));
	PrintToServer("L4D_GetVictimCarry %d",					L4D_GetVictimCarry(client));
	PrintToServer("L4D_GetVictimJockey %d",					L4D_GetVictimJockey(client));
	PrintToServer("L4D_GetAttackerHunter %d",				L4D_GetAttackerHunter(client));
	PrintToServer("L4D_GetAttackerSmoker %d",				L4D_GetAttackerSmoker(client));
	PrintToServer("L4D_GetAttackerCharger %d",				L4D_GetAttackerCharger(client));
	PrintToServer("L4D_GetAttackerCarry %d",				L4D_GetAttackerCarry(client));
	PrintToServer("L4D_GetAttackerJockey %d",				L4D_GetAttackerJockey(client));
	PrintToServer("L4D_GetPinnedInfected %d",				L4D_GetPinnedInfected(client));
	PrintToServer("L4D_HasReachedSmoker %d",				L4D_HasReachedSmoker(client));
	PrintToServer("L4D_IsPlayerPinned %d",					L4D_IsPlayerPinned(client));
	PrintToServer("L4D_IsPlayerHangingFromLedge %d",		L4D_IsPlayerHangingFromLedge(client));
	PrintToServer("L4D_CanPlayerLedgeHang %d"		,		L4D_CanPlayerLedgeHang(client));
	PrintToServer("L4D_GetPlayerReviveTarget %d",			L4D_GetPlayerReviveTarget(client));
	PrintToServer("L4D_GetPlayerReviveOwner %d",			L4D_GetPlayerReviveOwner(client));
	// PrintToServer("L4D_IsPlayerIncapped %d",				L4D_IsPlayerIncapped(client)); // DEPRECATED

	L4D_LedgeHangDisable(client);
	L4D_LedgeHangEnable(client);
	L4D_StopReviveAction(client);
	L4D_SetPlayerIncappedDamage(client);
	L4D_SetPlayerIncapped(client, false);
	L4D_ForcePanicEvent();

	float vPos[3];
	GetClientAbsOrigin(client, vPos);
	vPos[1] += 50.0;
	L4D_SpawnCommonInfected(vPos);
	// */





	// =========================
	// STOCKS - lux_library
	// =========================
	/*
	float vPos[3];
	float vAng[3];
	GetClientAbsOrigin(client, vPos);

	GetAbsOrigin(client, vPos);
	PrintToServer("GetAbsOrigin (%0.1f %0.1f %0.1f)", vPos[0], vPos[1], vPos[2]);
	vPos[2] += 10.0;
	PrintToServer("SetAbsOrigin %d", SetAbsOrigin(client, vPos));
	PrintToServer("SetAbsVelocity %d", SetAbsVelocity(client, view_as<float>({0.0, 0.0, 255.0})));
	PrintToServer("SetAbsAngles %d", SetAbsAngles(client, view_as<float>({0.0, 0.0, 0.0})));
	PrintToServer("GetAttachmentVectors %d", GetAttachmentVectors(client, "mouth", vPos, vAng));
	PrintToServer("GetAttachmentVectors Pos:(%0.1f %0.1f %0.1f) Ang:(%0.1f %0.1f %0.1f)", vPos[0], vPos[1], vPos[2], vAng[0], vAng[1], vAng[2]);

	PrintToServer("LookupAttachment %d", LookupAttachment(client, "mouth"));
	PrintToServer("GetAttachment %d", GetAttachment(client, LookupAttachment(client, "mouth"), vPos, vAng));
	PrintToServer("GetAttachment Pos:(%0.1f %0.1f %0.1f) Ang:(%0.1f %0.1f %0.1f)", vPos[0], vPos[1], vPos[2], vAng[0], vAng[1], vAng[2]);

	GetClientAbsOrigin(client, vPos);
	PrintToServer("IsPositionInWater %d", IsPositionInWater(vPos));

	Terror_SetPendingDspEffect(client, 0.0, 11);

	Terror_SetAdrenalineTime(client, 25.0);
	PrintToServer("Terror_GetAdrenalineTime %f", Terror_GetAdrenalineTime(client));
	PhysicsExplode(vPos, 64, 500.0, false);
	TE_SetupExplodeForce(vPos, 500.0, 64.0);
	TE_SendToAll();

	TE_SetupPhysicsProp(vPos, PrecacheModel("models/props_junk/propanecanister001a.mdl"));
	TE_SendToAll();

	PrintToServer("TE_SetupDynamicLight %d", TE_SetupDynamicLight(vPos, {255, 0, 0}, 512.0, 10.0, 0.0, 5));
	TE_SendToAll();

	TE_SetupParticleAttachment(GetParticleIndex("weapon_pipebomb_fuse"), LookupAttachment(client, "mouth"), client, true);
	TE_SendToAll();

	vPos[2] += 20.0;
	TE_SetupParticle(GetParticleIndex("weapon_pipebomb_fuse"), vPos);
	TE_SendToAll();

	TE_SetupParticleFollowEntity(GetParticleIndex("weapon_pipebomb_fuse"), client);
	TE_SendToAll();

	TE_SetupParticleFollowEntity_MaintainOffset(GetParticleIndex("weapon_pipebomb_fuse"), client, view_as<float>({0.0, 0.0, 0.0}));
	TE_SendToAll();

	TE_SetupParticle_ControlPoints(GetParticleIndex("smoker_tongue"), client, vPos);
	TE_SendToAll();

	PrintToServer("TE_SetupParticleFollowEntity_Name %d", TE_SetupParticleFollowEntity_Name("weapon_pipebomb_blinking_light", client));
	TE_SendToAll();

	PrintToServer("TE_SetupParticleFollowEntity_MaintainOffset_Name %d", TE_SetupParticleFollowEntity_MaintainOffset_Name("weapon_pipebomb_blinking_light", client, vPos));
	TE_SendToAll();

	PrintToServer("TE_SetupParticle_Name %d", TE_SetupParticle_Name("weapon_pipebomb_blinking_light", vPos));
	TE_SendToAll();

	PrintToServer("TE_SetupParticleAttachment_Names %d", TE_SetupParticleAttachment_Names("weapon_pipebomb_fuse", "mouth", client));
	TE_SendToAll();

	TE_SetupStopAllParticles(client);
	TE_SendToAll();

	float vEnd[3];
	vEnd = vPos;
	vEnd[1] += 50.0;
	TE_SetupTracerSound(vPos, vEnd);
	TE_SendToAll();

	int decal = PrecacheDecal("decals/checkpoint01_black.vmt");
	TE_SetupEntityDecal(vPos, vPos, GetClientAimTarget(client, false), 0, decal);
	TE_SendToAll();

	decal = PrecacheDecal("decals/helipad.vmt");
	TE_SetupWorldDecal(vPos, decal);
	TE_SendToAll();

	GetClientEyePosition(client, vPos);
	GetClientEyeAngles(client, vAng);
	Handle trace = TR_TraceRayFilterEx(vPos, vAng, MASK_SHOT, RayType_Infinite, _TraceFilter);
	PrintToServer("TE_SetupDecal_FromTrace %d", TE_SetupDecal_FromTrace(trace, "decals/checkpoint01_black.vmt"));
	TE_SendToAll();

	PrintToServer("GetDecalIndex %d", GetDecalIndex("decals/checkpoint01_black.vmt"));
	PrintToServer("GetParticleIndex %d", GetParticleIndex("weapon_pipebomb_fuse"));
	// PrintToServer("__FindStringIndex2 %d", __FindStringIndex2(int tableidx, const char[] str));
	// PrintToServer("__PrecacheParticleSystem %d", __PrecacheParticleSystem(const char[] particleSystem));
	// PrintToServer("Precache_Particle_System %d", Precache_Particle_System(const char[] particleSystem));

	OS_Type OS = GetOSType();
	PrintToServer("GetOSType = %s", OS == OS_windows ? "Windows" : OS == OS_linux ? "Linux" : "Other");
	// */





	// =========================
	// STOCKS - left4dhooks_stocks
	// =========================
	/*
	int entity = FindEntityByClassname(-1, "prop_dynamic");
	// int weapon = FindEntityByClassname(-1, "weapon_pistol*");
	int weapon = GetPlayerWeaponSlot(client, L4D_WEAPON_SLOT_PRIMARY);
	int bot = GetRandomSurvivor(1, 1);



	PrintToServer("L4D1_GetPlayerZombieClass %d", L4D1_GetPlayerZombieClass(client));
	L4D1_SetPlayerZombieClass(client, L4D1ZombieClass_Smoker);
	PrintToServer("L4D2_GetPlayerZombieClass %d", L4D2_GetPlayerZombieClass(client));
	L4D2_SetPlayerZombieClass(client, L4D2ZombieClass_Smoker);
	PrintToServer("L4D_IsPlayerGhost %d", L4D_IsPlayerGhost(client));
	L4D_SetPlayerGhostState(client, true);
	PrintToServer("L4D_GetPlayerGhostSpawnState %d", L4D_GetPlayerGhostSpawnState(client));
	L4D_SetPlayerGhostSpawnState(client, 1);
	PrintToServer("L4D_IsPlayerCulling %d", L4D_IsPlayerCulling(client));
	L4D_SetPlayerCullingState(client, true);
	PrintToServer("L4D_IsPlayerIncapacitated %d", L4D_IsPlayerIncapacitated(client));
	L4D_SetPlayerIncapacitatedState(client, true);
	PrintToServer("L4D_GetPlayerShovePenalty %d", L4D_GetPlayerShovePenalty(client));
	L4D_SetPlayerShovePenalty(client, 1);
	PrintToServer("L4D_GetTankFrustration %d", L4D_GetTankFrustration(client));
	L4D_SetTankFrustration(client, 1);
	PrintToServer("L4D_IsPlayerIdle %d", L4D_IsPlayerIdle(client));
	PrintToServer("L4D_GetBotOfIdlePlayer %d", L4D_GetBotOfIdlePlayer(client));
	PrintToServer("L4D_GetIdlePlayerOfBot %d", L4D_GetIdlePlayerOfBot(bot));
	PrintToServer("L4D_GetPlayerResourceData %d", L4D_GetPlayerResourceData(client, L4DResource_MaxHealth));
	L4D_SetPlayerResourceData(client, L4DResource_MaxHealth, 150);
	L4D_RemoveWeaponSlot(client, L4DWeaponSlot_Secondary);
	L4D_RemoveAllWeapons(client);
	PrintToServer("L4D_IsFinaleActive %d", L4D_IsFinaleActive());
	PrintToServer("L4D_HasAnySurvivorLeftSafeArea %d", L4D_HasAnySurvivorLeftSafeArea());
	PrintToServer("L4D_GetPendingTankPlayer %d", L4D_GetPendingTankPlayer());
	L4D2_SetEntityGlow(entity, L4D2Glow_Constant, 1000, 1, {255, 0, 0}, true);
	L4D2_SetEntityGlow_Type(entity, L4D2Glow_Constant);
	L4D2_SetEntityGlow_Range(entity, 1000);
	L4D2_SetEntityGlow_MinRange(entity,1);
	L4D2_SetEntityGlow_Color(entity, {255, 0, 0});
	L4D2_SetEntityGlow_Flashing(entity, true);
	PrintToServer("L4D2_GetEntityGlow_Type %d", L4D2_GetEntityGlow_Type(entity));
	PrintToServer("L4D2_GetEntityGlow_Range %d", L4D2_GetEntityGlow_Range(entity));
	PrintToServer("L4D2_GetEntityGlow_MinRange %d", L4D2_GetEntityGlow_MinRange(entity));
	PrintToServer("L4D2_GetEntityGlow_Flashing %d", L4D2_GetEntityGlow_Flashing(entity));
	L4D2_RemoveEntityGlow(entity);
	L4D2_RemoveEntityGlow_Color(entity);
	PrintToServer("L4D2_IsPlayerSurvivorGlowEnable %d", L4D2_IsPlayerSurvivorGlowEnable(client));
	L4D2_SetPlayerSurvivorGlowState(client, true);
	PrintToServer("L4D_GetPlayerReviveCount %d", L4D_GetPlayerReviveCount(client));
	L4D_SetPlayerReviveCount(client, 1);
	PrintToServer("L4D_GetPlayerIntensity %d", L4D_GetPlayerIntensity(client));
	PrintToServer("L4D_GetAvgSurvivorIntensity %d", L4D_GetAvgSurvivorIntensity());
	L4D_SetPlayerIntensity(client, 0.0);
	PrintToServer("L4D_IsPlayerCalm %d", L4D_IsPlayerCalm(client));
	L4D_SetPlayerCalmState(client, true);
	PrintToServer("L4D_HasVisibleThreats %d", L4D_HasVisibleThreats(client));
	PrintToServer("L4D_IsPlayerOnThirdStrike %d", L4D_IsPlayerOnThirdStrike(client));
	L4D_SetPlayerThirdStrikeState(client, true);
	PrintToServer("L4D_IsPlayerGoingToDie %d", L4D_IsPlayerGoingToDie(client));
	L4D_SetPlayerIsGoingToDie(client, true);
	PrintToServer("L4D2_IsWeaponUpgradeCompatible %d", L4D2_IsWeaponUpgradeCompatible(weapon));
	PrintToServer("L4D2_GetWeaponUpgradeAmmoCount %d", L4D2_GetWeaponUpgradeAmmoCount(weapon));
	L4D2_SetWeaponUpgradeAmmoCount(weapon, 123);
	PrintToServer("L4D2_GetWeaponUpgrades %d", L4D2_GetWeaponUpgrades(weapon));
	L4D2_SetWeaponUpgrades(weapon, 2);
	PrintToServer("L4D2_GetInfectedAttacker %d", L4D2_GetInfectedAttacker(client));
	PrintToServer("L4D2_GetSurvivorVictim %d", L4D2_GetSurvivorVictim(client));
	PrintToServer("L4D2_WasPresentAtSurvivalStart %d", L4D2_WasPresentAtSurvivalStart(client));
	L4D2_SetPresentAtSurvivalStart(client, true);
	PrintToServer("L4D_IsPlayerUsingMountedWeapon %d", L4D_IsPlayerUsingMountedWeapon(client));
	PrintToServer("L4D_GetPlayerTempHealth %d", L4D_GetPlayerTempHealth(client));
	L4D_SetPlayerTempHealth(client, 50);
	PrintToServer("L4D2_GetPlayerUseAction %d", L4D2_GetPlayerUseAction(client));
	PrintToServer("L4D2_GetPlayerUseActionTarget %d", L4D2_GetPlayerUseActionTarget(client));
	PrintToServer("L4D2_GetPlayerUseActionOwner %d", L4D2_GetPlayerUseActionOwner(client));

	L4D2_CreateInstructorHint("Test_Hint",
		client,
		"Test hint string",
		{255, 0, 0},
		"icon_alert_red",
		"icon_alert_red",
		"",
		0.0,
		0.0,
		2,
		true,
		false,
		false,
		L4D2_IHFLAG_ALPHA_URGENT);

	L4D2_StopInstructorHint("Test_Hint");

	PrintToServer("L4D1_GetShotgunNeedPump %d", L4D1_GetShotgunNeedPump(weapon));
	L4D1_SetShotgunNeedPump(weapon, true);
	L4D2_SetCustomAbilityCooldown(client, 0.0);


	char dest[64];

	// =========================
	// WEAPON STOCKS: l4d_weapon_stocks.inc
	// =========================
	PrintToServer("L4D2_IsValidWeaponId %d", L4D2_IsValidWeaponId(L4D2WeaponId_Pistol));
	PrintToServer("L4D2_IsValidWeaponName %d", L4D2_IsValidWeaponName("weapon_pistol"));
	PrintToServer("L4D2_HasValidWeaponWorldModel %d", L4D2_HasValidWeaponWorldModel(L4D2WeaponId_Pistol));
	L4D2_GetWeaponModelByWeaponId(L4D2WeaponId_Pistol, dest, sizeof(dest));
	PrintToServer("L4D2_GetWeaponModelByWeaponId %s", dest);
	PrintToServer("L4D2_GetWeaponIdByWeaponModel %d", L4D2_GetWeaponIdByWeaponModel("/w_models/weapons/w_pistol_b.mdl"));
	PrintToServer("L4D2_GetWeaponIdByWeaponName %d", L4D2_GetWeaponIdByWeaponName("weapon_pistol"));
	L4D2_GetWeaponNameByWeaponId(L4D2WeaponId_Pistol, dest, sizeof(dest));
	PrintToServer("L4D2_GetWeaponNameByWeaponId %s", dest);
	PrintToServer("L4D2_GetWeaponId %d", L4D2_GetWeaponId(weapon));
	L4D2_InitWeaponNameTrie();
	// */



	/*
	if( g_bLeft4Dead2 )
	{
		// Method to detonate VomitJar. Must impact the ground, "L4D_DetonateProjectile" will make it detonate but no particles or smoke will appear. Only the affect within the area.
		float vAng[3], vPos[3];
		GetClientEyePosition(client, vPos);
		vPos[2] += 50.0; // Move projectile above player to avoid collision
		vAng = view_as<float>({ 0.0, 0.0, 500.0 }); // Shoot upwards

		int projectile = L4D2_VomitJarPrj(client, vPos, vAng);
		CreateTimer(1.0, TimerDetonateVomitjar, EntIndexToEntRef(projectile));
	}
	*/





	// =========================
	// NATIVES - Mine
	// =========================
	// Version 1.72 tests
	/*
	// TEST: L4D_GetPointer
	PrintToServer("POINTER_DIRECTOR = %d",			L4D_GetPointer(POINTER_DIRECTOR));
	PrintToServer("POINTER_SERVER = %d",			L4D_GetPointer(POINTER_SERVER));
	PrintToServer("POINTER_GAMERULES = %d",			L4D_GetPointer(POINTER_GAMERULES));
	PrintToServer("POINTER_NAVMESH = %d",			L4D_GetPointer(POINTER_NAVMESH));
	PrintToServer("POINTER_ZOMBIEMANAGER = %d",		L4D_GetPointer(POINTER_ZOMBIEMANAGER));
	PrintToServer("POINTER_WEAPONINFO = %d",		L4D_GetPointer(POINTER_WEAPONINFO));
	PrintToServer("POINTER_MELEEINFO = %d",			L4D_GetPointer(POINTER_MELEEINFO));
	PrintToServer("POINTER_EVENTMANAGER = %d",		L4D_GetPointer(POINTER_EVENTMANAGER));
	PrintToServer("POINTER_SCAVENGEMODE = %d",		L4D_GetPointer(POINTER_SCAVENGEMODE));
	PrintToServer("POINTER_VERSUSMODE = %d",		L4D_GetPointer(POINTER_VERSUSMODE));

	// TEST: L4D_GetClientFromAddress + L4D_GetEntityFromAddress
	int target = GetAnyRandomClient();
	if( target )
	{
		PrintToServer("L4D_GetClientFromAddress %d (%d) == %d", target, GetEntityAddress(target), L4D_GetClientFromAddress(GetEntityAddress(target)));
	}

	int entity = FindEntityByClassname(-1, "prop_dynamic");
	if( entity != INVALID_ENT_REFERENCE )
	{
		PrintToServer("L4D_GetEntityFromAddress %d (%d) == %d", entity, GetEntityAddress(entity), L4D_GetEntityFromAddress(GetEntityAddress(entity)));
	}

	// TEST: L4D_ReadMemoryString
	if( target )
	{
		// OFFSET: (Hardcoded for demonstration)
		// Search: "#Cstrike_Name_Change"
		// Look for "CBasePlayer::SetPlayerName" near bottom of function. Offset inside.

		char temp[32];
		Address addy;
		Address offs;
		int os = L4D_GetServerOS();

		if( g_bLeft4Dead2 && os == SERVER_OS_LINUX )			offs = 8361;
		else if( g_bLeft4Dead2 && os == SERVER_OS_WINDOWS )		offs = 8365;
		else if( !g_bLeft4Dead2 && os == SERVER_OS_LINUX )		offs = 3845;
		else if( !g_bLeft4Dead2 && os == SERVER_OS_WINDOWS )	offs = 3825;

		// Returns the players name, read from a memory address
		addy = GetEntityAddress(target);
		L4D_ReadMemoryString(addy + offs, temp, sizeof(temp));

		PrintToServer("L4D_ReadMemoryString %N == [%s]", target, temp);
	}
	// */



	/*
	// WORKS
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	PrintToServer("L4D_GetReserveAmmoA %d",					L4D_GetReserveAmmo(client, weapon));
	L4D_SetReserveAmmo(client, weapon, L4D_GetReserveAmmo(client, weapon) + 20);
	PrintToServer("L4D_GetReserveAmmoB %d",					L4D_GetReserveAmmo(client, weapon));

	PrintToServer("Fall dmg: %f", L4D_EstimateFallingDamage(client));

	if( g_bLeft4Dead2 )
	{
		PrintToServer("L4D2_GetSurvivorSetMap: %d",					L4D2_GetSurvivorSetMap());
		PrintToServer("L4D2_GetSurvivorSetMod: %d",					L4D2_GetSurvivorSetMod());
		PrintToServer("L4D2_HasConfigurableDifficultySetting %d",	L4D2_HasConfigurableDifficultySetting());
		PrintToServer("L4D2_AreWanderersAllowed %d",				L4D2_AreWanderersAllowed()); // WORKS?
		PrintToServer("L4D2_IsGenericCooperativeMode %d",			L4D2_IsGenericCooperativeMode());
		PrintToServer("L4D2_IsRealismMode %d",						L4D2_IsRealismMode());
		PrintToServer("L4D2_IsScavengeMode %d",						L4D2_IsScavengeMode());
	}

	PrintToServer("L4D_IsCoopMode %d",								L4D_IsCoopMode());
	PrintToServer("L4D_IsSurvivalMode %d",							L4D_IsSurvivalMode());
	PrintToServer("L4D_IsVersusMode %d",							L4D_IsVersusMode());

	// WORKS
	// int iCurrentMode = L4D_GetGameModeType();
	// PrintToServer("GameMode %d", iCurrentMode);

	// WORKS
	// When a Survivor is taking over another Survivor, should change team to 0 otherwise the players old character will disappear.
	ChangeClientTeam(client, 0);

	int bot = GetRandomSurvivor(1, 1);
	PrintToServer("L4D_SetHumanSpec %d (%d - %N)",					L4D_SetHumanSpec(bot, client), bot, bot);
	PrintToServer("L4D_TakeOverBot %d (%d - %N)",					L4D_TakeOverBot(client), bot, bot);

	// WORKS
	PrintToServer("L4D_GoAwayFromKeyboard %d",						L4D_GoAwayFromKeyboard(client));

	// WORKS
	L4D_RespawnPlayer(client);
	PrintToServer("L4D_RespawnPlayer %N", client);

	// WORKS
	PrintToServer("L4D_GetLastKnownArea %d",						L4D_GetLastKnownArea(client));

	// WORKS
	PrintToServer("L4D_CanBecomeGhost %d",							L4D_CanBecomeGhost(client));

	// WORKS
	PrintToServer("L4D_IsFinaleEscapeInProgress %d",				L4D_IsFinaleEscapeInProgress());
	// */



	/*
	// VSCRIPT WRAPPER TESTS
	if( g_bLeft4Dead2 )
	{
		float vPos[3];
		float vEnd[3];

		// GetClientAbsOrigin(client, vPos);
		// PrintToChatAll("Nav area %d (%f, %f, %f)", L4D2Direct_GetTerrorNavArea(vPos),vPos[0], vPos[1], vPos[2]);

		// Tested on c1m2_streets
		// vPos = view_as<float>({ 2655.420410, 4722.138183, 448.031250 });	// Saferoom start - out of bounds
		vPos = view_as<float>({ 2449.840576, 5027.909179, 448.031250 });	// Saferoom start
		vEnd = view_as<float>({ -7481.826660, -4701.759277, 384.281250 });	// Saferoom end

		PrintToServer("L4D2_NavAreaTravelDistance %f / %f", L4D2_NavAreaTravelDistance(vPos, vEnd, false), GetVectorDistance(vPos, vEnd));

		PrintToServer("L4D2_VScriptWrapper_NavAreaBuildPath %b", L4D2_VScriptWrapper_NavAreaBuildPath(vPos, vEnd, 99999.999, true, true, 2, true));

		PrintToServer("L4D2_VScriptWrapper_NavAreaTravelDistance %f", L4D2_VScriptWrapper_NavAreaTravelDistance(vPos, vEnd, 99999.999, true, true));

		PrintToServer("L4D2_VScriptWrapper_GetMapNumber %d", L4D2_VScriptWrapper_GetMapNumber());

		if( client )
		{
			PrintToServer("L4D2_VScriptWrapper_HasEverBeenInjured %d", L4D2_VScriptWrapper_HasEverBeenInjured(client, 3));
			PrintToServer("L4D2_VScriptWrapper_GetAliveDuration %f", L4D2_VScriptWrapper_GetAliveDuration(client));
			PrintToServer("L4D2_VScriptWrapper_IsDead %d", L4D2_VScriptWrapper_IsDead(client));
			PrintToServer("L4D2_VScriptWrapper_IsDying %d", L4D2_VScriptWrapper_IsDying(client));
			PrintToServer("L4D2_VScriptWrapper_UseAdrenaline %d", L4D2_VScriptWrapper_UseAdrenaline(client, 20.0));
			PrintToServer("L4D2_VScriptWrapper_ReviveByDefib %d", L4D2_VScriptWrapper_ReviveByDefib(client));
			PrintToServer("L4D2_VScriptWrapper_ReviveFromIncap %d", L4D2_VScriptWrapper_ReviveFromIncap(client));

			char code[256];
			FormatEx(code, sizeof(code), "GetPlayerFromUserID(%d).ReviveByDefib();", GetClientUserId(client));
			L4D2_ExecVScriptCode(code);

			FormatEx(code, sizeof(code), "GetPlayerFromUserID(%d).UseAdrenaline(%f);", GetClientUserId(client), 20.0);
			L4D2_ExecVScriptCode(code);
		}

		int bot;

		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 2 )
			{
				bot = i;
				break;
			}
		}

		if( bot )
		{
			PrintToServer("L4D2_VScriptWrapper_GetSenseFlags %d (%d %N)", L4D2_VScriptWrapper_GetSenseFlags(bot), bot, bot);
		} else {
			PrintToServer("L4D2_VScriptWrapper_GetSenseFlags: ERROR: No bot to test");
		}
	}
	// */



	/*
	if( g_bLeft4Dead2 )
	{
		// VSCRIPT RETURN TESTING
		char buffer[128];

		if( client )
		{
			// Seems to always return 0. VScript problems.
			Format(buffer, sizeof(buffer), "GetCurrentFlowPercentForPlayer(%d)", client);
			if( L4D2_GetVScriptOutput(buffer, buffer, sizeof(buffer)) )
				PrintToServer("VScript: GetCurrentFlowPercentForPlayer(%d) = %s", client, buffer);

			// Seems to always return 0. VScript problems.
			Format(buffer, sizeof(buffer), "GetCurrentFlowDistanceForPlayer(%d)", client);
			if( L4D2_GetVScriptOutput(buffer, buffer, sizeof(buffer)) )
				PrintToServer("VScript: GetCurrentFlowDistanceForPlayer(%d) = %s", client, buffer);
		}

		// WORKS
		if( L4D2_GetVScriptOutput("Director.GetGameMode()", buffer, sizeof(buffer)) )
			PrintToServer("VScript: Director.GetGameMode() = %s", buffer);

		// WORKS
		if( L4D2_GetVScriptOutput("GetMaxFlowDistance()", buffer, sizeof(buffer)) )
			PrintToServer("VScript: GetMaxFlowDistance() = %s", buffer);

		// WORKS
		if( L4D2_GetVScriptOutput("Director.GetFurthestSurvivorFlow()", buffer, sizeof(buffer)) )
			PrintToServer("VScript: Director.GetFurthestSurvivorFlow() = %s", buffer);

		// WORKS
		int a = 14, b = 300;
		Format(buffer, sizeof(buffer), "test_a <- %d; test_b <- %d; <RETURN>test_a + test_b</RETURN>", a, b);
		if( L4D2_GetVScriptOutput(buffer, buffer, sizeof(buffer)) )
			PrintToServer("VScript: Math test_A = %s", buffer);

		// WORKS
		// Example of multi-line code strings. The string must end with a backslash "\" to work.
		float A = 107.0;
		float G = 0.8682;
		Format(buffer, sizeof(buffer), "test_a <- %f;\
			test_b <- %f;\
			<RETURN>test_a + test_b</RETURN>", A, G);
		if( L4D2_GetVScriptOutput(buffer, buffer, sizeof(buffer)) )
			PrintToServer("VScript: Math test_B = %s", buffer);

		if( client )
		{
			float vPos[3];
			GetClientAbsOrigin(client, vPos);
			int bot;

			for( int i = 1; i <= MaxClients; i++ )
			{
				if( IsClientInGame(i) && IsFakeClient(i) == true && GetClientTeam(i) == 2 )
				{
					bot = i;
					break;
				}
			}

			if( bot )
			{
				PrintToServer("L4D2_IsReachable %d", L4D2_IsReachable(bot, vPos));
			}
		}
	}
	// */



	// OTHER NATIVES
	/*
	// These list may be incomplete and the values not 100% accurate, some functions return a different value but this gives an overview of the keys and their related values or cvars.

	// Default value depends on difficulty:
	// "director_intensity_relax_allow_wanderers_threshold" = "0.3"
	// "director_intensity_relax_allow_wanderers_threshold_hard" = "0.5"
	// "director_intensity_relax_allow_wanderers_threshold_expert" = "0.8"
	PrintToServer("%s = %f", "IntensityRelaxAllowWanderersThreshold", L4D2_GetScriptValueFloat("IntensityRelaxAllowWanderersThreshold", 0.3));

	// Default value depends on difficulty:
	// "z_mob_spawn_max_interval_easy" = "240"
	// "z_mob_spawn_max_interval_normal" = "180"
	// "z_mob_spawn_max_interval_hard" = "180"
	// "z_mob_spawn_max_interval_expert" = "180"
	PrintToServer("%s = %f", "MobSpawnMaxTime", L4D2_GetScriptValueFloat("MobSpawnMaxTime", 180.0));

	// Default value depends on difficulty:
	// "z_mob_spawn_min_interval_easy" = "120"
	// "z_mob_spawn_min_interval_normal" = "90"
	// "z_mob_spawn_min_interval_hard" = "90"
	// "z_mob_spawn_min_interval_expert" = "90"
	PrintToServer("%s = %f", "MobSpawnMinTime", L4D2_GetScriptValueFloat("MobSpawnMinTime", 90.0));

	PrintToServer("%s = %f", "AddToSpawnTimer", L4D2_GetScriptValueFloat("AddToSpawnTimer", 0.0)); // 0.0
	PrintToServer("%s = %f", "FarAcquireRange", L4D2_GetScriptValueFloat("FarAcquireRange", 2500.0)); // "z_acquire_far_range" = "2500"
	PrintToServer("%s = %f", "NearAcquireRange", L4D2_GetScriptValueFloat("NearAcquireRange", 200.0)); // "z_acquire_near_range" = "200"
	PrintToServer("%s = %f", "FarAcquireTime", L4D2_GetScriptValueFloat("FarAcquireTime", 5.0)); // "z_acquire_far_time" = "5.0"
	PrintToServer("%s = %f", "NearAcquireTime", L4D2_GetScriptValueFloat("NearAcquireTime", 0.5)); // "z_acquire_near_time" = "0.5"
	PrintToServer("%s = %f", "GetSpecialSlotCountdownTime", L4D2_GetScriptValueFloat("GetSpecialSlotCountdownTime", 45.0)); // "director_special_respawn_interval" = "45"
	PrintToServer("%s = %f", "IntensityRelaxThreshold", L4D2_GetScriptValueFloat("IntensityRelaxThreshold", 0.9)); // "director_intensity_relax_threshold" = "0.9"
	PrintToServer("%s = %f", "MobRechargeRate", L4D2_GetScriptValueFloat("MobRechargeRate", 0.0025)); // "z_mob_recharge_rate" = "0.0025"
	PrintToServer("%s = %f", "PreferredMobPositionRange", L4D2_GetScriptValueFloat("PreferredMobPositionRange", 0.0)); // 0.0? CDirector + 137 (reads the CDirecors variable stored here)
	PrintToServer("%s = %f", "RelaxMaxFlowTravel", L4D2_GetScriptValueFloat("RelaxMaxFlowTravel", 3000.0)); // "director_relax_max_flow_travel" = "3000"
	PrintToServer("%s = %f", "RelaxMaxInterval", L4D2_GetScriptValueFloat("RelaxMaxInterval", 45.0)); // "director_relax_max_interval" = "45"
	PrintToServer("%s = %f", "RelaxMinInterval", L4D2_GetScriptValueFloat("RelaxMinInterval", 30.0)); // "director_relax_min_interval" = "30"
	PrintToServer("%s = %f", "SpawnBehindSurvivorsDistance", L4D2_GetScriptValueFloat("SpawnBehindSurvivorsDistance", 0.0)); // "spawn_behind_survivors_distance" = "0"
	PrintToServer("%s = %f", "SpecialInitialSpawnDelayMax", L4D2_GetScriptValueFloat("SpecialInitialSpawnDelayMax", 60.0)); // "director_special_initial_spawn_delay_max" = "60"
	PrintToServer("%s = %f", "SpecialInitialSpawnDelayMin", L4D2_GetScriptValueFloat("SpecialInitialSpawnDelayMin", 30.0)); // "director_special_initial_spawn_delay_min" = "30"
	PrintToServer("%s = %f", "SpecialRespawnInterval", L4D2_GetScriptValueFloat("SpecialRespawnInterval", 45.0)); // "director_special_respawn_interval" = "45"
	PrintToServer("%s = %f", "SustainPeakMaxTime", L4D2_GetScriptValueFloat("SustainPeakMaxTime", 5.0)); // "director_sustain_peak_max_time" = "5"
	PrintToServer("%s = %f", "SustainPeakMinTime", L4D2_GetScriptValueFloat("SustainPeakMinTime", 3.0)); // "director_sustain_peak_min_time" = "3"
	PrintToServer("%s = %f", "TankHitDamageModifierCoop", L4D2_GetScriptValueFloat("TankHitDamageModifierCoop", 1.0)); // 1.0
	PrintToServer("%s = %f", "TankRunSpawnDelay", L4D2_GetScriptValueFloat("TankRunSpawnDelay", 15.0)); // "tank_run_spawn_delay" = "15"
	PrintToServer("%s = %f", "TempHealthDecayRate", L4D2_GetScriptValueFloat("TempHealthDecayRate", 0.27)); // "pain_pills_decay_rate" = "0.27"
	PrintToServer("%s = %f", "WanderingZombieDensityModifier", L4D2_GetScriptValueFloat("WanderingZombieDensityModifier", 0.03)); // "z_wandering_density" = "0.03"
	PrintToServer("%s = %f", "ZombieSpawnRange", L4D2_GetScriptValueFloat("ZombieSpawnRange", 1500.0)); // "z_spawn_range" = "1500"
	PrintToServer("%s = %f", "ZombieTankHealth", L4D2_GetScriptValueFloat("ZombieTankHealth", 1.0)); // 1.0

	PrintToServer("%s = %d", "AllowCrescendoEvents", L4D2_GetScriptValueInt("AllowCrescendoEvents", 1)); // 1
	PrintToServer("%s = %d", "AllowWitchesInCheckpoints", L4D2_GetScriptValueInt("AllowWitchesInCheckpoints", 0)); // 0
	PrintToServer("%s = %d", "AlwaysAllowWanderers", L4D2_GetScriptValueInt("AlwaysAllowWanderers", 0)); // "director_always_allow_wanderers" = "0"
	PrintToServer("%s = %d", "BuildUpMinInterval", L4D2_GetScriptValueInt("BuildUpMinInterval", 15)); // "director_build_up_min_interval" = "15"
	PrintToServer("%s = %d", "ClearedWandererRespawnChance", L4D2_GetScriptValueInt("ClearedWandererRespawnChance", 0)); // "cleared_wanderer_respawn_chance" = "0"
	PrintToServer("%s = %d", "DisallowThreatType", L4D2_GetScriptValueInt("DisallowThreatType", 0)); // 0
	PrintToServer("%s = %d", "GasCansOnBacks", L4D2_GetScriptValueInt("GasCansOnBacks", 0)); // 0
	PrintToServer("%s = %d", "IgnoreNavThreatAreas", L4D2_GetScriptValueInt("IgnoreNavThreatAreas", 0)); // 0
	PrintToServer("%s = %d", "InfectedFlags", L4D2_GetScriptValueInt("InfectedFlags", 0)); // 0
	PrintToServer("%s = %d", "LockTempo", L4D2_GetScriptValueInt("LockTempo", 0)); // 0? CDirectorVersusMode + 351
	PrintToServer("%s = %d", "MusicDynamicMobScanStopSize", L4D2_GetScriptValueInt("MusicDynamicMobScanStopSize", 3)); // "director_music_dynamic_scanmobstop_size" = "3"
	PrintToServer("%s = %d", "MusicDynamicMobSpawnSize", L4D2_GetScriptValueInt("MusicDynamicMobSpawnSize", 25)); // "director_music_dynamic_mob_size" = "25"
	PrintToServer("%s = %d", "MusicDynamicMobStopSize", L4D2_GetScriptValueInt("MusicDynamicMobStopSize", 8)); // "director_music_dynamic_mobstop_size" = "8"
	PrintToServer("%s = %d", "NumReservedWanderers", L4D2_GetScriptValueInt("NumReservedWanderers", 0)); // "director_num_reserved_wanderers" = "0"
	PrintToServer("%s = %d", "NoMobSpawns", L4D2_GetScriptValueInt("NoMobSpawns", 0)); // 0
	PrintToServer("%s = %d", "PanicForever", L4D2_GetScriptValueInt("PanicForever", 0)); // "director_panic_forever" = "0"
	PrintToServer("%s = %d", "PausePanicWhenRelaxing", L4D2_GetScriptValueInt("PausePanicWhenRelaxing", 0)); // 0
	PrintToServer("%s = %d", "PreferredMobDirection", L4D2_GetScriptValueInt("PreferredMobDirection", -1)); // -1
	PrintToServer("%s = %d", "PreferredSpecialDirection", L4D2_GetScriptValueInt("PreferredSpecialDirection", -1)); // -1
	PrintToServer("%s = %d", "ProhibitBosses", L4D2_GetScriptValueInt("ProhibitBosses", 0)); // "director_no_bosses" = "0"
	PrintToServer("%s = %d", "ShouldAllowMobsWithTank", L4D2_GetScriptValueInt("ShouldAllowMobsWithTank", 0)); // 0
	PrintToServer("%s = %d", "ShouldAllowSpecialsWithTank", L4D2_GetScriptValueInt("ShouldAllowSpecialsWithTank", 0)); // 0
	PrintToServer("%s = %d", "ShouldConstrainLargeVolumeSpawn", L4D2_GetScriptValueInt("ShouldConstrainLargeVolumeSpawn", 1)); // 1
	PrintToServer("%s = %d", "ShouldIgnoreClearStateForSpawn", L4D2_GetScriptValueInt("ShouldIgnoreClearStateForSpawn", 0)); // 0
	PrintToServer("%s = %d", "SpecialInfectedAssault", L4D2_GetScriptValueInt("SpecialInfectedAssault", 0)); // 0
	PrintToServer("%s = %d", "SurvivorMaxIncapacitatedCount", L4D2_GetScriptValueInt("SurvivorMaxIncapacitatedCount", 2)); // "survivor_max_incapacitated_count" = "2"
	PrintToServer("%s = %d", "WaterSlowsMovement", L4D2_GetScriptValueInt("WaterSlowsMovement", 1)); // 1
	PrintToServer("%s = %d", "ZombieDiscardRange", L4D2_GetScriptValueInt("ZombieDiscardRange", 2500)); // "z_discard_range" = "2500"
	PrintToServer("%s = %d", "ZombieDontClear", L4D2_GetScriptValueInt("ZombieDontClear", 0)); // "z_dont_clear" = "0"
	PrintToServer("%s = %d", "ZombieSpawnInFog", L4D2_GetScriptValueInt("ZombieSpawnInFog", 0)); // "z_fog_spawn" = "0"



	// WORKS
	int target = GetClientAimTarget(client, false);
	if( target != -1 )
	{
		PrintToServer("L4D_Dissolve %d",					L4D_Dissolve(target));
	}

	PrintToServer("L4D_Deafen %d",							L4D_Deafen(client)); // WORKS

	// WORKS
	float health = L4D_GetTempHealth(client);
	PrintToServer("L4D_GetTempHealth %N %f", client, health);
	health += 10.0;
	L4D_SetTempHealth(client, health);



	// WORKS
	// Starts and stops incapacitated music
	// L4D_PlayMusic(client, "Event.Down", 0, 0.0, false, false);
	// L4D_StopMusic(client, "Event.Down");

	// Starts and stops the Portal Jukebox song
	// L4D_PlayMusic(client, "Jukebox.still_alive", 0, 0.0, false, false);
	// L4D_StopMusic(client, "Jukebox.still_alive");



	PrintToServer("L4D_OnITExpired %d",						L4D_OnITExpired(client)); // WORKS



	float vPos[3];
	float vAng[3];

	GetClientEyeAngles(client, vAng);
	GetClientEyePosition(client, vPos);



	// WORKS
	static int zombieClass = 1;
	zombieClass++;
	if( zombieClass > (g_bLeft4Dead2 ? 6 : 3) ) zombieClass = 1;
	float vecPos[3];
	PrintToServer("L4D_GetRandomPZSpawnPosition %d",					L4D_GetRandomPZSpawnPosition(client, zombieClass, 20, vecPos));
	PrintToServer("L4D_GetRandomPZSpawnPosition (%f %f %f)",			vecPos[0], vecPos[1], vecPos[2]);



	int area = L4D_GetNearestNavArea(vPos);
	PrintToServer("L4D_GetNearestNavArea %d",							area);

	L4D_FindRandomSpot(area, vecPos);
	PrintToServer("L4D_FindRandomSpot (%f %f %f)",						vecPos[0], vecPos[1], vecPos[2]);
	// Above spawns next to player.



	PrintToServer("L4D_HasAnySurvivorLeftSafeArea %d",					L4D_HasAnySurvivorLeftSafeArea()); // WORKS

	PrintToServer("L4D_IsAnySurvivorInCheckpoint %d",					L4D_IsAnySurvivorInCheckpoint()); // WORKS

	PrintToServer("L4D_IsAnySurvivorInStartArea %d",					L4D_IsAnySurvivorInStartArea()); // WORKS

	PrintToServer("L4D_IsInFirstCheckpoint %d",							L4D_IsInFirstCheckpoint(client)); // WORKS

	PrintToServer("L4D_IsInLastCheckpoint %d",							L4D_IsInLastCheckpoint(client)); // WORKS

	PrintToServer("L4D_HasPlayerControlledZombies %d",					L4D_HasPlayerControlledZombies()); // WORKS


	// WORKS
	// L4D2_UseAdrenaline(client, 15.0, false);
	L4D2_UseAdrenaline(client);
	PrintToServer("L4D2_UseAdrenaline %N", client);



	// WORKS
	// The "Fuse" + "Light" particles must be manually added in your plugin.
	// I intentionally did not include this in left4dhooks in case you wanted to create an activated PipeBomb projectile without the particles.
	int projectile = L4D_PipeBombPrj(client, vPos, vAng);

	// Create particles
	CreateParticle(projectile, 0);
	CreateParticle(projectile, 1);

	// Might work, from "PipeBomb Shove" plugin
	SetEntPropFloat(projectile, Prop_Data, "m_DmgRadius", 400.0);
	SetEntPropFloat(projectile, Prop_Data, "m_flDamage", 25.0);

	PrintToServer("L4D2_PipeBombPrj %d", projectile);



	// WORKS
	projectile = L4D_MolotovPrj(client, vPos, vAng);
	PrintToServer("L4D_MolotovPrj %d", projectile);



	// WORKS
	if( g_bLeft4Dead2 )
	{
		projectile = L4D2_VomitJarPrj(client, vPos, vAng);
		PrintToServer("L4D2_VomitJarPrj %d", projectile);

		projectile = L4D2_GrenadeLauncherPrj(client, vPos, vAng);
		SetEntProp(projectile, Prop_Data, "m_iHammerID", 2467737); // Avoid conflict with "Flare Gun" plugin.
		PrintToServer("L4D2_GrenadeLauncherPrj %d", projectile);
	}



	vAng = view_as<float>({ 0.0, 0.0, 500.0 }); // Shoot upwards
	vPos[2] += 100.0; // Move projectile above player to avoid collision
	projectile = L4D_TankRockPrj(client, vPos, vAng);
	PrintToChatAll("L4D_TankRockPrj == %d", projectile);

	// projectile = L4D_MolotovPrj(client, vPos, vAng);
	if( g_bLeft4Dead2 )
	{
		// projectile = L4D2_VomitJarPrj(client, vPos, vAng);
		// projectile = L4D2_SpitterPrj(client, vPos, vAng);
		// projectile = L4D2_GrenadeLauncherPrj(client, vPos, vAng);
	}
	CreateTimer(1.0, TimerDetonate, EntIndexToEntRef(projectile));



	// WORKS
	float vDir[3];
	// vDir = view_as<float>({ 0.0, 1.0, 0.0}); // Spin top over
	vDir = view_as<float>({ -1.0, 0.0, 0.0}); // Spin sideways
	NormalizeVector(vDir, vDir);
	ScaleVector(vDir, 10000.0);
	PrintToServer("L4D_AngularVelocity %d",								L4D_AngularVelocity(projectile, vDir));



	// WORKS
	if( g_bLeft4Dead2 )
	{
		GetAngleVectors(vAng, vAng, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(vAng, vAng);
		ScaleVector(vAng, 500.0);
		PrintToServer("L4D2_SpitterPrj %d",								L4D2_SpitterPrj(client, vPos, vAng));

		PrintToServer("L4D2_GetCurrentFinaleStage %d",					L4D2_GetCurrentFinaleStage()); // WORKS

		PrintToServer("L4D2_ForceNextStage %d",							L4D2_ForceNextStage()); // WORKS

		PrintToServer("L4D2_IsTankInPlay %d",							L4D2_IsTankInPlay()); // WORKS

		PrintToServer("L4D2_GetFurthestSurvivorFlow %f",				L4D2_GetFurthestSurvivorFlow()); // WORKS
	}
	// =========================
	// */





	// =========================
	// NATIVES - Animation
	// =========================
	/*
	float vPos[3];
	float vAng[3];

	if( client == 0 ) client = GetRandomSurvivor();
	PrintToServer("TESTING NATIVES. Using client: %d (%N)", client, client);
	GetClientAbsOrigin(client, vPos);
	GetClientAbsAngles(client, vAng);



	// Animation Hook test
	char temp[64];
	AnimGetActivity(1813, temp, sizeof(temp));
	int seq = AnimGetFromActivity("ACT_MP_GESTURE_VC_NODNO_PDA");
	PrintToServer("Animation Activity: SEQ: [%d]. ACT: [%s]", seq, temp);
	PrintToServer("");
	PrintToServer("");
	// */





	// =========================
	// NATIVES - l4d_direct.inc
	// =========================
	/*
	PrintToServer("L4D2_GetTankCount %d",					L4D2_GetTankCount()); //WORKING
	PrintToServer("L4D2_GetWitchCount %d",					L4D2_GetWitchCount()); //WORKING
	PrintToServer("");
	PrintToServer("");

	PrintToServer("L4D_IsMissionFinalMap %d",				L4D_IsMissionFinalMap()); //WORKING
	PrintToServer("L4D_IsFirstMapInScenario %d",			L4D_IsFirstMapInScenario()); //WORKING



	if( g_bLeft4Dead2 )
	{
		PrintToServer("");
		PrintToServer("");

		// l4d2weapons.inc
		PrintToServer("L4D2_GetMeleeWeaponIndex: knife %d",										L4D2_GetMeleeWeaponIndex("knife"));
		PrintToServer("L4D2_GetMeleeWeaponIndex: machete %d",									L4D2_GetMeleeWeaponIndex("machete"));
		PrintToServer("L4D2_GetIntMeleeAttribute:dmg0= %d",										L4D2_GetIntMeleeAttribute(0, L4D2IMWA_DamageFlags));
		PrintToServer("L4D2_GetIntMeleeAttribute:dmg1= %d",										L4D2_GetIntMeleeAttribute(1, L4D2IMWA_DamageFlags));
		PrintToServer("L4D2_GetIntMeleeAttribute:dmg2= %d",										L4D2_GetIntMeleeAttribute(2, L4D2IMWA_DamageFlags));
		PrintToServer("L4D2_GetIntMeleeAttribute:dmg3= %d",										L4D2_GetIntMeleeAttribute(3, L4D2IMWA_DamageFlags));
		PrintToServer("L4D2_GetIntMeleeAttribute:dmg4= %d",										L4D2_GetIntMeleeAttribute(4, L4D2IMWA_DamageFlags));
		PrintToServer("L4D2_GetIntMeleeAttribute:dmg5= %d",										L4D2_GetIntMeleeAttribute(5, L4D2IMWA_DamageFlags));
		PrintToServer("L4D2_GetIntMeleeAttribute:dmg6= %d",										L4D2_GetIntMeleeAttribute(6, L4D2IMWA_DamageFlags));
		PrintToServer("L4D2_GetIntMeleeAttribute:dmg7= %d",										L4D2_GetIntMeleeAttribute(7, L4D2IMWA_DamageFlags));
		PrintToServer("L4D2_GetIntMeleeAttribute:dmg8= %d",										L4D2_GetIntMeleeAttribute(8, L4D2IMWA_DamageFlags));
		PrintToServer("L4D2_GetIntMeleeAttribute:dmg9= %d",										L4D2_GetIntMeleeAttribute(9, L4D2IMWA_DamageFlags));
		PrintToServer("L4D2_GetIntMeleeAttribute:dmg10= %d",									L4D2_GetIntMeleeAttribute(10, L4D2IMWA_DamageFlags));
		PrintToServer("");
		PrintToServer("");

		PrintToServer("L4D2_GetIntMeleeAttribute (RumbleEffect): 1= %d",						L4D2_GetIntMeleeAttribute(1, L4D2IMWA_RumbleEffect));
		PrintToServer("L4D2_GetIntMeleeAttribute (RumbleEffect): 2= %d",						L4D2_GetIntMeleeAttribute(3, L4D2IMWA_RumbleEffect));
		PrintToServer("");
		PrintToServer("");

		int meleeID = L4D2_GetMeleeWeaponIndex("knife");

		PrintToServer("L4D2_GetFloatMeleeAttribute knife (Damage): %f",							L4D2_GetFloatMeleeAttribute(meleeID, L4D2FMWA_Damage));
		L4D2_SetFloatMeleeAttribute(meleeID, L4D2FMWA_Damage, 100.0);
		PrintToServer("L4D2_SetFloatMeleeAttribute knife (Damage): %f",							L4D2_GetFloatMeleeAttribute(meleeID, L4D2FMWA_Damage));

		PrintToServer("L4D2_GetBoolMeleeAttribute knife (Decapitates): %d",						L4D2_GetBoolMeleeAttribute(meleeID, L4D2BMWA_Decapitates));
		L4D2_SetBoolMeleeAttribute(meleeID, L4D2BMWA_Decapitates, true);
		PrintToServer("L4D2_SetBoolMeleeAttribute knife (Decapitates): %d",						L4D2_GetBoolMeleeAttribute(meleeID, L4D2BMWA_Decapitates));

		PrintToServer("L4D2_GetIntMeleeAttribute knife (DamageFlags): %d",						L4D2_GetIntMeleeAttribute(meleeID, L4D2IMWA_DamageFlags));
		L4D2_SetIntMeleeAttribute(meleeID, L4D2IMWA_DamageFlags, 8);
		PrintToServer("L4D2_SetIntMeleeAttribute knife (DamageFlags): %d",						L4D2_GetIntMeleeAttribute(meleeID, L4D2IMWA_DamageFlags));
		PrintToServer("");
		PrintToServer("");
	}

	PrintToServer("L4D2_IsValidWeapon weapon_rifle: %d",									L4D2_IsValidWeapon("weapon_rifle"));
	PrintToServer("L4D2_IsValidWeapon weapon_autoshotgun: %d",								L4D2_IsValidWeapon("weapon_autoshotgun"));
	PrintToServer("L4D2_IsValidWeapon weapon_smg: %d",										L4D2_IsValidWeapon("weapon_smg"));
	PrintToServer("L4D2_IsValidWeapon smg: %d",												L4D2_IsValidWeapon("smg")); // Changed to support this without "weapon_" required
	PrintToServer("");
	PrintToServer("");

	PrintToServer("L4D_GetWeaponID weapon_rifle: %d",										L4D_GetWeaponID("weapon_rifle"));
	PrintToServer("L4D_GetWeaponID weapon_tank_claw: %d",									L4D_GetWeaponID("weapon_tank_claw"));
	PrintToServer("L4D_GetWeaponID weapon_smg: %d",											L4D_GetWeaponID("weapon_smg"));
	PrintToServer("L4D_GetWeaponID smg: %d",												L4D_GetWeaponID("smg"));
	PrintToServer("");
	PrintToServer("");

	PrintToServer("L4D2_GetFloatWeaponAttribute_A weapon_rifle (MaxPlayerSpeed): %f",		L4D2_GetFloatWeaponAttribute("weapon_rifle", L4D2FWA_ReloadDuration));
	L4D2_SetFloatWeaponAttribute("weapon_rifle",											L4D2FWA_ReloadDuration, 0.5);
	PrintToServer("L4D2_SetFloatWeaponAttribute_A weapon_rifle (MaxPlayerSpeed): %f",		L4D2_GetFloatWeaponAttribute("weapon_rifle", L4D2FWA_ReloadDuration));

	PrintToServer("L4D2_GetFloatWeaponAttribute_A weapon_rifle (MaxPlayerSpeed): %f",		L4D2_GetFloatWeaponAttribute("weapon_rifle", L4D2FWA_MaxPlayerSpeed));
	L4D2_SetFloatWeaponAttribute("weapon_rifle",											L4D2FWA_MaxPlayerSpeed, 300.0);
	PrintToServer("L4D2_SetFloatWeaponAttribute_A weapon_rifle (MaxPlayerSpeed): %f",		L4D2_GetFloatWeaponAttribute("weapon_rifle", L4D2FWA_MaxPlayerSpeed));

	PrintToServer("L4D2_GetFloatWeaponAttribute_B weapon_rifle (Range): %f",				L4D2_GetFloatWeaponAttribute("weapon_rifle", L4D2FWA_Range));
	PrintToServer("L4D2_GetFloatWeaponAttribute_C weapon_rifle (MinInAirSpread): %f",		L4D2_GetFloatWeaponAttribute("weapon_rifle", L4D2FWA_MinInAirSpread));
	PrintToServer("L4D2_GetFloatWeaponAttribute_D weapon_rifle (MaxMovementSpread): %f",	L4D2_GetFloatWeaponAttribute("weapon_rifle", L4D2FWA_MaxMovementSpread));
	PrintToServer("");
	PrintToServer("");

	PrintToServer("L4D2_GetIntWeaponAttribute weapon_rifle (Bullets): %d",					L4D2_GetIntWeaponAttribute("weapon_rifle", L4D2IWA_Bullets));
	PrintToServer("L4D2_GetIntWeaponAttribute weapon_rifle (ClipSize): %d",					L4D2_GetIntWeaponAttribute("weapon_rifle", L4D2IWA_ClipSize));
	PrintToServer("L4D2_GetIntWeaponAttribute weapon_rifle (Default ClipSize): %d",			L4D2_GetIntWeaponAttribute("weapon_rifle", L4D2IWA_DefaultSize));
	PrintToServer("L4D2_GetIntWeaponAttribute weapon_rifle (Bucket): %d",					L4D2_GetIntWeaponAttribute("weapon_rifle", L4D2IWA_Bucket));
	if( g_bLeft4Dead2 )
		PrintToServer("L4D2_GetIntWeaponAttribute weapon_rifle (Tier): %d",					L4D2_GetIntWeaponAttribute("weapon_rifle", L4D2IWA_Tier));
	PrintToServer("L4D2_GetIntWeaponAttribute weapon_rifle (Damage): %d",					L4D2_GetIntWeaponAttribute("weapon_rifle", L4D2IWA_Damage));
	L4D2_SetIntWeaponAttribute("weapon_rifle",												L4D2IWA_ClipSize, 100);
	PrintToServer("");
	PrintToServer("");
	L4D2_SetIntWeaponAttribute("weapon_rifle",												L4D2IWA_Damage, 100);
	PrintToServer("L4D2_SetIntWeaponAttribute weapon_rifle (Damage): %d",					L4D2_GetIntWeaponAttribute("weapon_rifle", L4D2IWA_Damage));
	PrintToServer("");
	PrintToServer("");

	PrintToServer("L4D2_GetFloatWeaponAttribute_CA weapon_smg (MaxPlayerSpeed): %f",		L4D2_GetFloatWeaponAttribute("weapon_smg", L4D2FWA_MaxPlayerSpeed));
	PrintToServer("L4D2_GetFloatWeaponAttribute_CB weapon_smg (Range): %f",					L4D2_GetFloatWeaponAttribute("weapon_smg", L4D2FWA_Range));
	PrintToServer("L4D2_GetFloatWeaponAttribute_CC weapon_smg (MinInAirSpread): %f",		L4D2_GetFloatWeaponAttribute("weapon_smg", L4D2FWA_MinInAirSpread));
	PrintToServer("L4D2_GetFloatWeaponAttribute_CD weapon_smg (MaxMovementSpread): %f",		L4D2_GetFloatWeaponAttribute("weapon_smg", L4D2FWA_MaxMovementSpread));
	PrintToServer("");
	PrintToServer("");

	if( g_bLeft4Dead2 )
	{
		// Test attribute tag mis-match
		// PrintToServer("L4D2_GetIntWeaponAttribute_DD: %d",		L4D2_GetIntWeaponAttribute("weapon_smg", L4D2FWA_MaxPlayerSpeed));

		int scores[2];
		L4D2_GetVersusCampaignScores(scores);
		PrintToServer("L4D2_GetVersusCampaignScores A: %d / %d", scores[0], scores[1]);
		scores[0] = 123;
		scores[1] = 314;
		L4D2_SetVersusCampaignScores(scores);
		PrintToServer("L4D2_SetVersusCampaignScores B: %d / %d", scores[0], scores[1]);

		float tankFlows[2];
		L4D2_GetVersusTankFlowPercent(tankFlows);
		PrintToServer("L4D2_GetVersusTankFlowPercent A: %f / %f", tankFlows[0], tankFlows[1]);
		tankFlows[0] = 10.0;
		tankFlows[1] = 15.0;
		L4D2_SetVersusTankFlowPercent(tankFlows);
		PrintToServer("L4D2_SetVersusTankFlowPercent B: %f / %f", tankFlows[0], tankFlows[1]);

		float witchFlows[2];
		L4D2_GetVersusWitchFlowPercent(witchFlows);
		PrintToServer("L4D2_GetVersusWitchFlowPercent A: %f / %f", witchFlows[0], witchFlows[1]);
		witchFlows[0] = 20.0;
		witchFlows[1] = 25.0;
		L4D2_SetVersusWitchFlowPercent(witchFlows);
		PrintToServer("L4D2_SetVersusWitchFlowPercent B: %f / %f", witchFlows[0], witchFlows[1]);
		PrintToServer("");
		PrintToServer("");

		PrintToServer("L4D2_CTimerHasStarted A: %d",				L4D2_CTimerHasStarted(L4D2CT_MobSpawnTimer));
		PrintToServer("L4D2_CTimerReset: %d",						L4D2_CTimerReset(L4D2CT_MobSpawnTimer));
		PrintToServer("L4D2_CTimerHasStarted B: %d",				L4D2_CTimerHasStarted(L4D2CT_MobSpawnTimer));
		PrintToServer("L4D2_CTimerStart: %d",						L4D2_CTimerStart(L4D2CT_MobSpawnTimer, 10.0));
		PrintToServer("L4D2_CTimerHasStarted C: %d",				L4D2_CTimerHasStarted(L4D2CT_MobSpawnTimer));
		PrintToServer("L4D2_CTimerInvalidate: %d",					L4D2_CTimerInvalidate(L4D2CT_MobSpawnTimer));
		PrintToServer("L4D2_CTimerHasStarted D: %d",				L4D2_CTimerHasStarted(L4D2CT_MobSpawnTimer));

		PrintToServer("L4D2_CTimerIsElapsed: %d",					L4D2_CTimerIsElapsed(L4D2CT_MobSpawnTimer));
		PrintToServer("L4D2_CTimerGetElapsedTime: %f",				L4D2_CTimerGetElapsedTime(L4D2CT_MobSpawnTimer));
		PrintToServer("L4D2_CTimerGetRemainingTime: %f",			L4D2_CTimerGetRemainingTime(L4D2CT_MobSpawnTimer));
		PrintToServer("L4D2_CTimerGetCountdownDuration: %f",		L4D2_CTimerGetCountdownDuration(L4D2CT_MobSpawnTimer));
		PrintToServer("");
		PrintToServer("");

		PrintToServer("Testing Boomer timers:");
		PrintToServer("L4D2_ITimerHasStarted A: %d",				L4D2_ITimerHasStarted(L4D2IT_BoomerDeathTimer));
		PrintToServer("L4D2_ITimerGetElapsedTime: %f",				L4D2_ITimerGetElapsedTime(L4D2IT_BoomerDeathTimer));
		PrintToServer("L4D2_ITimerStart: %f",						L4D2_ITimerStart(L4D2IT_BoomerDeathTimer));
		PrintToServer("L4D2_ITimerHasStarted B: %d",				L4D2_ITimerHasStarted(L4D2IT_BoomerDeathTimer));
		PrintToServer("L4D2_ITimerInvalidate: %f",					L4D2_ITimerInvalidate(L4D2IT_BoomerDeathTimer));
		PrintToServer("L4D2_ITimerHasStarted C: %d",				L4D2_ITimerHasStarted(L4D2IT_BoomerDeathTimer));
		PrintToServer("");
		PrintToServer("");

		PrintToServer("L4D_ResetMobTimer %d",						L4D_ResetMobTimer()); //SEEMS WORKING

		// 1 - Finale Started; 6 - Rescue Vehicle Ready; 7 - Zombie Hordes; 8 - Tank; 10 - Combat Respite (nothing spawns)
		PrintToServer("L4D2_ChangeFinaleStage %d",					L4D2_ChangeFinaleStage(10, "test")); // WORKS
		PrintToServer("L4D2_ChangeFinaleStage %d",					L4D2_ChangeFinaleStage(8, "")); // WORKS
		PrintToServer("");
		PrintToServer("");
	}





	// =========================
	// NATIVES - left4downtown.inc
	// =========================
	if( g_bLeft4Dead2 )
	{
		PrintToServer("L4D_GetTeamScore A Map: %d",					L4D_GetTeamScore(1, false)); //WORKING
		PrintToServer("L4D_GetTeamScore B Map: %d",					L4D_GetTeamScore(2, false)); //WORKING
		PrintToServer("L4D_GetTeamScore A Camp: %d",				L4D_GetTeamScore(1, true)); //WORKING
		PrintToServer("L4D_GetTeamScore B Camp: %d",				L4D_GetTeamScore(2, true)); //WORKING

		PrintToServer("");
		PrintToServer("");
		PrintToServer("L4D_ScavengeBeginRoundSetupTime %f",			L4D_ScavengeBeginRoundSetupTime());
		PrintToServer("L4D_GetMobSpawnTimerRemaining %f",			L4D_GetMobSpawnTimerRemaining()); //SEEMS WORKING
		PrintToServer("L4D_GetMobSpawnTimerDuration %f",			L4D_GetMobSpawnTimerDuration()); //SEEMS WORKING
		PrintToServer("");
		PrintToServer("");
	}

	PrintToServer("L4D_GetVersusMaxCompletionScore %d",			L4D_GetVersusMaxCompletionScore()); //WORKING
	L4D_SetVersusMaxCompletionScore(314); //WORKING

	PrintToServer("L4D_GetMaxChapters %d", L4D_GetMaxChapters()); //WORKING
	PrintToServer("L4D_GetCurrentChapter %d", L4D_GetCurrentChapter()); //WORKING

	PrintToServer("L4D_NotifyNetworkStateChanged %d",				L4D_NotifyNetworkStateChanged()); //SEEMS WORKING, UNKNOWN

	PrintToServer("");
	PrintToServer("");
	// */



	// WORKS
	/*
	char sTemp[20];
	L4D_GetLobbyReservation(sTemp, sizeof(sTemp));
	PrintToServer("L4D_GetLobbyReservation_A %s", sTemp);

	sTemp = "1BADFAD1337D34D";
	L4D_SetLobbyReservation(sTemp);
	PrintToServer("L4D_SetLobbyReservation %s", sTemp);

	L4D_GetLobbyReservation(sTemp, sizeof(sTemp));
	PrintToServer("L4D_GetLobbyReservation_B %s", sTemp);
	PrintToServer("L4D_LobbyIsReserved == %d", L4D_LobbyIsReserved());

	ServerCommand("status");
	ServerExecute();

	// PrintToServer("L4D_LobbyUnreserve_A %d", L4D_LobbyUnreserve()); // Comment this to see "status" output otherwise this triggers before it can execute.

	L4D_GetLobbyReservation(sTemp, sizeof(sTemp));
	PrintToServer("L4D_GetLobbyReservation_C %s", sTemp);
	PrintToServer("L4D_LobbyIsReserved_B == %d", L4D_LobbyIsReserved());
	*/





	// =========================
	// NATIVES - L4D_Direct
	// =========================
	// Most seem to work, not all tested
	/*
	float vPos[3];

	if( g_bLeft4Dead2 )
	{
		PrintToServer("L4D_DIRECT TEST:");
		PrintToServer("Direct_GetTankCount %d",								L4D2Direct_GetTankCount()); // WORKS
		PrintToServer("Direct_GetMobSpawnTimer address %d",					L4D2Direct_GetMobSpawnTimer());
		PrintToServer("Direct_GetSIClassDeathTimer address %d",				L4D2Direct_GetSIClassDeathTimer(1));
		PrintToServer("Direct_GetSIClassSpawnTimer address %d",				L4D2Direct_GetSIClassSpawnTimer(1));
		PrintToServer("Direct_GetVSStartTimer address %d",					L4D2Direct_GetVSStartTimer());
		PrintToServer("Direct_GetScavengeRoundSetupTimer address %d",		L4D2Direct_GetScavengeRoundSetupTimer());
		PrintToServer("Direct_GetScavengeOvertimeGraceTimer address %d",	L4D2Direct_GetScavengeOvertimeGraceTimer());
		PrintToServer("Direct_GetSpawnTimer address %d",					L4D2Direct_GetSpawnTimer(client));
		PrintToServer("Direct_GetShovePenalty %d",							L4D2Direct_GetShovePenalty(client)); // Seems working
		L4D2Direct_SetShovePenalty(client, 50);
		PrintToServer("Direct_SetShovePenalty %d",							L4D2Direct_GetShovePenalty(client));
		PrintToServer("Direct_GetNextShoveTime %f",							L4D2Direct_GetNextShoveTime(client)); // WORKS
		L4D2Direct_SetNextShoveTime(client, GetGameTime() + 5.0); // WORKS
		PrintToServer("Direct_SetNextShoveTime %f",							L4D2Direct_GetNextShoveTime(client)); // WORKS
		PrintToServer("Direct_GetPreIncapHealth %d",						L4D2Direct_GetPreIncapHealth(client)); // Seems working
		L4D2Direct_SetPreIncapHealth(client, 95); // Seems working
		PrintToServer("Direct_SetPreIncapHealth %d",						L4D2Direct_GetPreIncapHealth(client)); // Seems working
		PrintToServer("Direct_GetPreIncapHealthBuffer %d",					L4D2Direct_GetPreIncapHealthBuffer(client)); // Seems working
		L4D2Direct_SetPreIncapHealthBuffer(client, 90); // Seems working
		PrintToServer("Direct_SetPreIncapHealthBuffer %d",					L4D2Direct_GetPreIncapHealthBuffer(client)); // Seems working

		// Maybe needs to be set on spawn to work:
		int entity = FindEntityByClassname(-1, "inferno");
		if( entity != INVALID_ENT_REFERENCE )
		{
			PrintToServer("Direct_GetInfernoMaxFlames %d",					L4D2Direct_GetInfernoMaxFlames(entity));
			L4D2Direct_SetInfernoMaxFlames(entity, 1);
			PrintToServer("Direct_SetInfernoMaxFlames %d",					L4D2Direct_GetInfernoMaxFlames(entity));
		}

		PrintToServer("Direct_GetScriptedEventManager %d",					L4D2Direct_GetScriptedEventManager());
	}

	PrintToServer("Direct_GetTankPassedCount %d",							L4D2Direct_GetTankPassedCount());
	L4D2Direct_SetTankPassedCount(2);
	PrintToServer("Direct_SetTankPassedCount %d",							L4D2Direct_GetTankPassedCount());
	PrintToServer("Direct_GetVSCampaignScore %d",							L4D2Direct_GetVSCampaignScore(0));
	L4D2Direct_SetVSCampaignScore(0, 314);
	PrintToServer("Direct_SetVSCampaignScore %d",							L4D2Direct_GetVSCampaignScore(0));
	PrintToServer("Direct_GetVSTankFlowPercent %f",							L4D2Direct_GetVSTankFlowPercent(1)); // Seems working
	L4D2Direct_SetVSTankFlowPercent(1, 0.2); // Seems working
	PrintToServer("Direct_SetVSTankFlowPercent %f",							L4D2Direct_GetVSTankFlowPercent(1)); // Seems working
	PrintToServer("Direct_GetVSTankToSpawnThisRound %d",					L4D2Direct_GetVSTankToSpawnThisRound(1)); // Seems working
	L4D2Direct_SetVSTankToSpawnThisRound(1, true); // Seems working
	PrintToServer("Direct_SetVSTankToSpawnThisRound %d",					L4D2Direct_GetVSTankToSpawnThisRound(1)); // Seems working
	PrintToServer("Direct_GetVSWitchFlowPercent %f",						L4D2Direct_GetVSWitchFlowPercent(1)); // Seems working
	L4D2Direct_SetVSWitchFlowPercent(1, 25.0); // Seems working
	PrintToServer("Direct_SetVSWitchFlowPercent %f",						L4D2Direct_GetVSWitchFlowPercent(1)); // Seems working
	PrintToServer("Direct_GetVSWitchToSpawnThisRound %d",					L4D2Direct_GetVSWitchToSpawnThisRound(1)); // Seems working
	L4D2Direct_SetVSWitchToSpawnThisRound(1, true); // Seems working
	PrintToServer("Direct_SetVSWitchToSpawnThisRound %d",					L4D2Direct_GetVSWitchToSpawnThisRound(1)); // Seems working
	PrintToServer("Direct_GetMapMaxFlowDistance %f",						L4D2Direct_GetMapMaxFlowDistance()); // WORKS
	PrintToServer("Direct_GetInvulnerabilityTimer address %d",				L4D2Direct_GetInvulnerabilityTimer(client));
	PrintToServer("Direct_GetTankTickets %d",								L4D2Direct_GetTankTickets(client));
	L4D2Direct_SetTankTickets(client, 100);
	PrintToServer("Direct_SetTankTickets %d",								L4D2Direct_GetTankTickets(client));

	PrintToServer("Direct_GetTerrorNavArea %d",								L4D2Direct_GetTerrorNavArea(vPos)); // WORKS
	PrintToServer("Direct_GetTerrorNavAreaFlow %f",							L4D2Direct_GetTerrorNavAreaFlow(L4D2Direct_GetTerrorNavArea(vPos))); // WORKS
	PrintToServer("Direct_GetFlowDistance %f",								L4D2Direct_GetFlowDistance(client)); // WORKS
	PrintToServer("Direct_DoAnimationEvent",								L4D2Direct_DoAnimationEvent(client, 4)); // 4-6 = Reload. 8=Jump? 10=Death anim (loops).

	// PrintToServer("Direct_TryOfferingTankBot %d",						L4D2Direct_TryOfferingTankBot(client, false)); // WORKS



	if( g_bLeft4Dead2 )
	{
		// To verify the correct address, lets use VScript to get value.
		char buffer[4];
		if( L4D2_GetVScriptOutput("Director.GetPendingMobCount()", buffer, sizeof(buffer)) )
			PrintToServer("VScript: GetPendingMobCount() = %s", buffer);
	}

	// Test read
	PrintToServer("L4D2Direct_GetPendingMobCount %d",					L4D2Direct_GetPendingMobCount()); //WORKING

	// Test write
	L4D2Direct_SetPendingMobCount(5); //WORKING
	PrintToServer("L4D2Direct_SetPendingMobCount %d",					L4D2Direct_GetPendingMobCount()); //WORKING

	if( g_bLeft4Dead2 )
	{
		char buffer[4];
		if( L4D2_GetVScriptOutput("Director.GetPendingMobCount()", buffer, sizeof(buffer)) )
			PrintToServer("GetPendingMobCount: GetPendingMobCount() = %s", buffer);
	}
	// */



	// TIMER TESTS
	/*
	// pPanicCountdown
	CountdownTimer ptr = view_as<CountdownTimer>(L4D2Direct_GetScriptedEventManager() + 300);

	PrintToServer("Timer Initial: = %f / %f",			CTimer_GetTimestamp(ptr), CTimer_GetTimestamp(ptr));

	CTimer_Reset(ptr);
	PrintToServer("CTimer_Reset = %f / %f",				CTimer_GetTimestamp(ptr), CTimer_GetTimestamp(ptr));

	CTimer_Start(ptr, 1.0);
	PrintToServer("CTimer_Start = %f / %f",				CTimer_GetTimestamp(ptr), CTimer_GetTimestamp(ptr));

	CTimer_Invalidate(ptr);
	PrintToServer("CTimer_Invalidate = %f / %f",		CTimer_GetTimestamp(ptr), CTimer_GetTimestamp(ptr));

	PrintToServer("CTimer_HasStarted = %d",				CTimer_HasStarted(ptr));
	PrintToServer("CTimer_IsElapsed = %d",				CTimer_IsElapsed(ptr));
	PrintToServer("CTimer_GetElapsedTime = %f",			CTimer_GetElapsedTime(ptr));
	PrintToServer("CTimer_GetRemainingTime = %f",		CTimer_GetRemainingTime(ptr));
	PrintToServer("CTimer_GetCountdownDuration = %f",	CTimer_GetCountdownDuration(ptr));
	PrintToServer("CTimer_GetDuration = %f",			CTimer_GetDuration(ptr));

	CTimer_SetDuration(ptr, 2.0);
	PrintToServer("CTimer_SetDuration = %f / %f",		CTimer_GetTimestamp(ptr), CTimer_GetTimestamp(ptr));

	PrintToServer("CTimer_GetTimestamp = %f",			CTimer_GetTimestamp(ptr));

	CTimer_SetTimestamp(ptr, GetGameTime() + 1.0);
	PrintToServer("CTimer_SetTimestamp = %f / %f",		CTimer_GetTimestamp(ptr), CTimer_GetTimestamp(ptr));



	IntervalTimer itPTR = view_as<IntervalTimer>(L4D2Direct_GetScriptedEventManager() + 300);
	ITimer_Reset(itPTR);
	PrintToServer("ITimer_Reset = %f / %f",				CTimer_GetTimestamp(ptr), CTimer_GetTimestamp(ptr));

	ITimer_Start(itPTR);
	PrintToServer("ITimer_Start = %f / %f",				CTimer_GetTimestamp(ptr), CTimer_GetTimestamp(ptr));

	ITimer_Invalidate(itPTR);
	PrintToServer("ITimer_Invalidate = %f / %f",		CTimer_GetTimestamp(ptr), CTimer_GetTimestamp(ptr));

	PrintToServer("ITimer_HasStarted = %d",				ITimer_HasStarted(itPTR));
	PrintToServer("ITimer_GetElapsedTime = %f",			ITimer_GetElapsedTime(itPTR));
	PrintToServer("ITimer_GetTimestamp = %f",			ITimer_GetTimestamp(itPTR));
	ITimer_SetTimestamp(itPTR, GetGameTime() + 2.0);



	if( !g_bLeft4Dead2 )
	{
		// UNTESTED:
		L4DDirect_GetSurvivorHealthBonus(client);
		L4DDirect_SetSurvivorHealthBonus(client, 2);
		L4DDirect_RecomputeTeamScores();
	}



	PrintToServer("");
	PrintToServer("");
	// */





	// =========================
	// Client specific, spawning and stuff that changes the mission.
	// =========================
	/*
	float vPos[3];
	float vAng[3];

	if( g_bLeft4Dead2 )
	{
		PrintToServer("L4D_GetPlayerSpawnTime %f",							L4D_GetPlayerSpawnTime(client));// WORKS
		PrintToServer("");
		PrintToServer("");
	}



	vPos[0] = GetRandomFloat(50.0, 250.0);
	vPos[1] = GetRandomFloat(50.0, 250.0);
	vPos[2] = GetRandomFloat(50.0, 250.0);



	PrintToServer("L4D_StaggerPlayer %N", client);
	PrintToServer("");
	PrintToServer("");
	L4D_StaggerPlayer(client, client, vPos); //WORKING



	GetClientAbsOrigin(client, vPos);
	GetClientAbsAngles(client, vAng);



	// PrintToServer("L4D_ReplaceTank %d",									L4D_ReplaceTank(tank, newtank)); // WORKS



	// Spawn
	vPos[1] += 30.0;
	PrintToServer("L4D2_SpawnSpecial %d",									L4D2_SpawnSpecial(3, vPos, vAng)); // WORKS

	vPos[0] += 30.0;
	PrintToServer("L4D2_SpawnTank %d",										L4D2_SpawnTank(vPos, vAng)); //WORKING

	vPos[1] += 30.0;
	PrintToServer("L4D2_SpawnWitch %d",										L4D2_SpawnWitch(vPos, vAng)); //WORKING

	if( g_bLeft4Dead2 )
	{
		vPos[0] += 30.0;
		PrintToServer("L4D2_SpawnWitchBride %d",							L4D2_SpawnWitchBride(vPos, vAng)); //WORKING
	}

	PrintToServer("");
	PrintToServer("");



	// char sMap[64];
	// GetCurrentMap(sMap, sizeof(sMap));
	// PrintToServer("L4D_RestartScenarioFromVote %d",						L4D_RestartScenarioFromVote(sMap)); //WORKING

	PrintToServer("L4D2_SendInRescueVehicle %d",							L4D2_SendInRescueVehicle()); // WORKS
	// */





	// =========================
	// NATIVES - l4d2addresses.txt
	// =========================
	/*
	int targ = GetClientAimTarget(client, false);
	if( targ > 0 && targ <= MaxClients )
	{
		PrintToServer("L4D_CTerrorPlayer_OnVomitedUpon",						L4D_CTerrorPlayer_OnVomitedUpon(targ, client)); // WORKS
		PrintToServer("L4D_CTerrorPlayer_OnVomitedUpon",						L4D_CTerrorPlayer_OnVomitedUpon(client, client)); // WORKS
	}

	PrintToServer("L4D_CancelStagger",										L4D_CancelStagger(client)); // WORKS

	PrintToServer("L4D_CreateRescuableSurvivors",							L4D_CreateRescuableSurvivors()); // WORKS

	PrintToServer("L4D_ReviveSurvivor",										L4D_ReviveSurvivor(client)); // WORKS

	PrintToServer("L4D_GetHighestFlowSurvivor %d",							L4D_GetHighestFlowSurvivor()); // WORKS

	int infected = GetClientAimTarget(client, false);
	if( infected != -1 )
	{
		PrintToServer("L4D_GetInfectedFlowDistance %f",						L4D_GetInfectedFlowDistance(infected)); // WORKS
	}

	int bot = GetClientAimTarget(client, false);
	if( bot != -1 )
	PrintToServer("L4D_TakeOverZombieBot",									L4D_TakeOverZombieBot(client, bot)); // WORKS

	PrintToServer("L4D_ReplaceWithBot",										L4D_ReplaceWithBot(client)); // WORKS

	PrintToServer("L4D_CullZombie",											L4D_CullZombie(client)); // WORKS

	static int class = 1;
	class++;
	if( class > (g_bLeft4Dead2 ? 6 : 3) ) class = 1;
	PrintToServer("L4D_SetClass",											L4D_SetClass(client, class)); // WORKS

	PrintToServer("L4D_MaterializeFromGhost %d",							L4D_MaterializeFromGhost(client)); // WORKS

	PrintToServer("L4D_BecomeGhost %d",										L4D_BecomeGhost(client)); // WORKS

	PrintToServer("L4D_State_Transition",									L4D_State_Transition(client, 6)); // WORKS

	// Has no affect
	int car = GetClientAimTarget(client, false);
	PrintToServer("L4D_RegisterForbiddenTarget %d",							L4D_RegisterForbiddenTarget(car));
	PrintToServer("L4D_UnRegisterForbiddenTarget",							L4D_UnRegisterForbiddenTarget(car));



	if( g_bLeft4Dead2 )
	{
		if( targ > 0 && targ <= MaxClients )
		{
			PrintToServer("L4D2_CTerrorPlayer_OnHitByVomitJar",					L4D2_CTerrorPlayer_OnHitByVomitJar(targ, client)); // WORKS
		}

		if( targ > MaxClients )
		{
			PrintToServer("L4D2_Infected_OnHitByVomitJar",						L4D2_Infected_OnHitByVomitJar(targ, client)); // WORKS
		}

		PrintToServer("L4D2_CTerrorPlayer_Fling",							L4D2_CTerrorPlayer_Fling(client, client, view_as<float>({ 1.0, 0.0, 0.0 }))); // WORKS

		PrintToServer("L4D2_GetVersusCompletionPlayer %d",					L4D2_GetVersusCompletionPlayer(client)); // WORKS

		PrintToServer("L4D2_SwapTeams",										L4D2_SwapTeams()); // WORKS, some survivors may spawn dead.

		PrintToServer("L4D2_AreTeamsFlipped %d",							L4D2_AreTeamsFlipped()); // WORKS

		PrintToServer("L4D2_StartRematchVote",								L4D2_StartRematchVote()); // WORKS

		PrintToServer("L4D2_FullRestart",									L4D2_FullRestart()); // WORKS

		PrintToServer("L4D2_HideVersusScoreboard",							L4D2_HideVersusScoreboard()); // WORKS

		PrintToServer("L4D2_HideScavengeScoreboard",						L4D2_HideScavengeScoreboard()); // WORKS

		PrintToServer("L4D2_HideScoreboard",								L4D2_HideScoreboard()); // WORKS
	}
	// */

	return Plugin_Handled;
}

stock Action TimerDetonate(Handle timer, int entity)
{
	entity = EntRefToEntIndex(entity);
	if( entity != INVALID_ENT_REFERENCE )
	{
		L4D_DetonateProjectile(entity);
	}

	return Plugin_Continue;
}

stock Action TimerDetonateVomitjar(Handle timer, int entity)
{
	entity = EntRefToEntIndex(entity);
	if( entity != INVALID_ENT_REFERENCE )
	{
		float vPos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);
		PrintToChatAll("DETON A (%0.0f %0.0f %0.0f)", vPos[0], vPos[1], vPos[2]);
		GetGroundAngles(vPos);
		PrintToChatAll("DETON B (%0.0f %0.0f %0.0f)", vPos[0], vPos[1], vPos[2]);
		vPos[2] += 1.0;
		TeleportEntity(entity, vPos, NULL_VECTOR, view_as<float>({ 0.0, 0.0, -1.0}));
	}

	return Plugin_Continue;
}

void GetGroundAngles(float vOrigin[3])
{
	float vAng[3], vLookAt[3], vTargetOrigin[3];

	vTargetOrigin = vOrigin;
	vTargetOrigin[2] -= 20.0; // Point to the floor
	vOrigin[2] -= 5.0;
	MakeVectorFromPoints(vOrigin, vTargetOrigin, vLookAt);
	GetVectorAngles(vLookAt, vAng); // get angles from vector for trace

	// Execute Trace
	Handle trace = TR_TraceRayFilterEx(vOrigin, vAng, MASK_ALL, RayType_Infinite, _TraceFilter);

	if( TR_DidHit(trace) )
	{
		TR_GetEndPosition(vOrigin, trace); // retrieve our trace endpoint
		PrintToChatAll("Trace (%0.0f %0.0f %0.0f)", vOrigin[0], vOrigin[1], vOrigin[2]);
	}

	delete trace;
}

stock bool _TraceFilter(int entity, int contentsMask)
{
	if( !entity || entity <= MaxClients || !IsValidEntity(entity) ) // dont let WORLD, or invalid entities be hit
		return false;
	return true;
}



// ====================================================================================================
//										FORWAWRDS
// ====================================================================================================
public Action L4D_OnSpawnSpecial(int &zombieClass, const float vecPos[3], const float vecAng[3])
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnSpawnSpecial\" %d. (%f %f %f). (%f %f %f)", zombieClass, vecPos[0], vecPos[1], vecPos[2], vecAng[0], vecAng[1], vecAng[2]);
	}

	// zombieClass = 1;
	// return Plugin_Changed; // WORKS

	// return Plugin_Handled; // WORKS

	return Plugin_Continue;
}

public void L4D_OnSpawnSpecial_Post(int client, int zombieClass, const float vecPos[3], const float vecAng[3])
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnSpawnSpecial_Post\" %d. %d (%N). (%f %f %f). (%f %f %f)", zombieClass, client > 0 && client <= MaxClients ? client : 0, client > 0 && client <= MaxClients ? client : 0, vecPos[0], vecPos[1], vecPos[2], vecAng[0], vecAng[1], vecAng[2]);
	}
}

public void L4D_OnSpawnSpecial_PostHandled(int client, int zombieClass, const float vecPos[3], const float vecAng[3])
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnSpawnSpecial_PostHandled\" %d. %d (%N). (%f %f %f). (%f %f %f)", zombieClass, client > 0 && client <= MaxClients ? client : 0, client > 0 && client <= MaxClients ? client : 0, vecPos[0], vecPos[1], vecPos[2], vecAng[0], vecAng[1], vecAng[2]);
	}
}

public Action L4D_OnSpawnTank(const float vecPos[3], const float vecAng[3])
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnSpawnTank\" (%f %f %f). (%f %f %f)", vecPos[0], vecPos[1], vecPos[2], vecAng[0], vecAng[1], vecAng[2]);
	}

	// return Plugin_Handled; // WORKS

	return Plugin_Continue;
}

public void L4D_OnSpawnTank_Post(int client, const float vecPos[3], const float vecAng[3])
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnSpawnTank_Post\" %d (%N). (%f %f %f). (%f %f %f)", client > 0 && client <= MaxClients ? client : 0, client > 0 && client <= MaxClients ? client : 0, vecPos[0], vecPos[1], vecPos[2], vecAng[0], vecAng[1], vecAng[2]);
	}
}

public void L4D_OnSpawnTank_PostHandled(int client, const float vecPos[3], const float vecAng[3])
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnSpawnTank_PostHandled\" %d (%N). (%f %f %f). (%f %f %f)", client > 0 && client <= MaxClients ? client : 0, client > 0 && client <= MaxClients ? client : 0, vecPos[0], vecPos[1], vecPos[2], vecAng[0], vecAng[1], vecAng[2]);
	}
}

public Action L4D_OnSpawnWitch(const float vecPos[3], const float vecAng[3])
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnSpawnWitch\" (%f %f %f). (%f %f %f)", vecPos[0], vecPos[1], vecPos[2], vecAng[0], vecAng[1], vecAng[2]);
	}

	// return Plugin_Handled; // WORKS

	return Plugin_Continue;
}

public void L4D_OnSpawnWitch_Post(int entity, const float vecPos[3], const float vecAng[3])
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnSpawnWitch_Post\" %d (%f %f %f). (%f %f %f)", entity, vecPos[0], vecPos[1], vecPos[2], vecAng[0], vecAng[1], vecAng[2]);
	}
}

public void L4D_OnSpawnWitch_PostHandled(int entity, const float vecPos[3], const float vecAng[3])
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnSpawnWitch_PostHandled\" %d (%f %f %f). (%f %f %f)", entity, vecPos[0], vecPos[1], vecPos[2], vecAng[0], vecAng[1], vecAng[2]);
	}
}

public Action L4D2_OnSpawnWitchBride(const float vecPos[3], const float vecAng[3])
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnSpawnWitchBride\" (%f %f %f). (%f %f %f)", vecPos[0], vecPos[1], vecPos[2], vecAng[0], vecAng[1], vecAng[2]);
	}

	// return Plugin_Handled; // WORKS

	return Plugin_Continue;
}

public void L4D2_OnSpawnWitchBride_Post(int entity, const float vecPos[3], const float vecAng[3])
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnSpawnWitchBride_Post\" %d (%f %f %f). (%f %f %f)", entity, vecPos[0], vecPos[1], vecPos[2], vecAng[0], vecAng[1], vecAng[2]);
	}
}

public void L4D2_OnSpawnWitchBride_PostHandled(int entity, const float vecPos[3], const float vecAng[3])
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnSpawnWitchBride_PostHandled\" %d (%f %f %f). (%f %f %f)", entity, vecPos[0], vecPos[1], vecPos[2], vecAng[0], vecAng[1], vecAng[2]);
	}
}

public Action L4D_OnMobRushStart()
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnMobRushStart\"");
	}
	// return Plugin_Handled;

	return Plugin_Continue;
}

public void L4D_OnMobRushStart_Post()
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnMobRushStart_Post\"");
	}
}

public void L4D_OnMobRushStart_PostHandled()
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnMobRushStart_PostHandled\"");
	}
}

public Action L4D_OnSpawnITMob(int &amount)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnSpawnITMob\" %d", amount);
	}

	// WORKS
	// amount = 3;
	// return Plugin_Changed;

	// WORKS
	// return Plugin_Handled;

	return Plugin_Continue;
}

public void L4D_OnSpawnITMob_Post(int amount)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnSpawnITMob_Post\" %d", amount);
	}
}

public void L4D_OnSpawnITMob_PostHandled(int amount)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnSpawnITMob_PostHandled\" %d", amount);
	}
}

public Action L4D_OnSpawnMob(int &amount)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnSpawnMob\" %d", amount);
	}

	// WORKS
	// amount = 3;
	// return Plugin_Changed;

	// WORKS
	// return Plugin_Handled;

	return Plugin_Continue;
}

public void L4D_OnSpawnMob_Post(int amount)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnSpawnMob_Post\" %d", amount);
	}
}

public void L4D_OnSpawnMob_PostHandled(int amount)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnSpawnMob_PostHandled\" %d", amount);
	}
}

public Action L4D_OnEnterGhostStatePre(int client)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnEnterGhostStatePre\" %d", client);
	}

	// WORKS
	// return Plugin_Handled;

	return Plugin_Continue;
}

public void L4D_OnEnterGhostState(int client)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnEnterGhostState\" %d", client);
	}
}

public void L4D_OnEnterGhostState_PostHandled(int client)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnEnterGhostState_PostHandled\" %d", client);
	}
}

public Action L4D_OnTakeOverBot(int client)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnTakeOverBot\" %d (%N)", client, client);
	}

	// Blocks
	// return Plugin_Handled;

	return Plugin_Continue;
}

public void L4D_OnTakeOverBot_Post(int client, bool success)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnTakeOverBot_Post\" %d (%N). Success: %d", client, client, success);
	}
}

public void L4D_OnTakeOverBot_PostHandled(int client, bool success)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnTakeOverBot_PostHandled\" %d (%N). Success: %d", client, client, success);
	}
}

public Action L4D_OnIsTeamFull(int team, bool &full)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_IsTeamFull\" %d %d", team, full);
	}

	// TEST
	// if( full )
	// {
		// full = false;
		// return Plugin_Changed;
	// }

	// Blocks
	// full = true;
	// return Plugin_Changed;

	return Plugin_Continue;
}

public Action L4D_OnClearTeamScores(bool newCampaign)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnClearTeamScores\" %d", newCampaign);
	}

	// WORKS
	// return Plugin_Handled;

	return Plugin_Continue;
}

public Action L4D_OnSetCampaignScores(int &scoreA, int &scoreB)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnSetCampaignScores\" %d. %d", scoreA, scoreB);
	}

	// WORKS
	// scoreA = 314;
	// scoreB = 123;
	// return Plugin_Changed;

	// WORKS
	// return Plugin_Handled;

	return Plugin_Continue;
}

public void L4D_OnSetCampaignScores_Post(int scoreA, int scoreB)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnSetCampaignScores_Post\" %d. %d", scoreA, scoreB);
	}
}

public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnFirstSurvivorLeftSafeArea\" %d", client);
	}

	// WORKS
	// return Plugin_Handled;

	return Plugin_Continue;
}

public void L4D_OnFirstSurvivorLeftSafeArea_Post(int client)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnFirstSurvivorLeftSafeArea_Post\" %d", client);
	}
}

public void L4D_OnFirstSurvivorLeftSafeArea_PostHandled(int client)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnFirstSurvivorLeftSafeArea_PostHandled\" %d", client);
	}
}

public void L4D_OnForceSurvivorPositions_Pre()
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnForceSurvivorPositions_Pre\"");
	}
}

public void L4D_OnForceSurvivorPositions()
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnForceSurvivorPositions\"");
	}
}

public void L4D_OnReleaseSurvivorPositions()
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnReleaseSurvivorPositions\"");
	}
}

public void L4D_OnSpeakResponseConcept_Pre(int entity)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnSpeakResponseConcept_Pre\" %d", entity);
	}
}

public void L4D_OnSpeakResponseConcept_Post(int entity)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnSpeakResponseConcept_Post\" %d", entity);
	}
}

public Action L4D_OnGetCrouchTopSpeed(int target, float &retVal)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnGetCrouchTopSpeed\" %d. %f", target, retVal);
	}

	// WORKS
	// retVal = 500.0;
	// return Plugin_Handled;

	return Plugin_Continue;
}

public Action L4D_OnGetRunTopSpeed(int target, float &retVal)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnGetRunTopSpeed\" %d. %f", target, retVal);
	}

	// WORKS
	// retVal = 500.0;
	// return Plugin_Handled;

	return Plugin_Continue;
}

public Action L4D_OnGetWalkTopSpeed(int target, float &retVal)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnGetWalkTopSpeed\" %d. %f", target, retVal);
	}

	// WORKS
	// retVal = 500.0;
	// return Plugin_Handled;

	return Plugin_Continue;
}

public Action L4D_OnGetMissionVSBossSpawning(float &spawn_pos_min, float &spawn_pos_max, float &tank_chance, float &witch_chance)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnGetMissionVSBossSpawning\" %f. %f. %f. %f", spawn_pos_min, spawn_pos_max, tank_chance, witch_chance);
	}

	// WORKS
	// spawn_pos_min = 0.01;
	// spawn_pos_max = 0.05;
	// tank_chance = 1.0;
	// witch_chance = 1.0;
	// return Plugin_Changed;

	return Plugin_Continue;
}

public void L4D_OnGetMissionVSBossSpawning_Post(float spawn_pos_min, float spawn_pos_max, float tank_chance, float witch_chance)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnGetMissionVSBossSpawning_Post\" %f. %f. %f. %f", spawn_pos_min, spawn_pos_max, tank_chance, witch_chance);
	}
}

public void L4D_OnGetMissionVSBossSpawning_PostHandled(float spawn_pos_min, float spawn_pos_max, float tank_chance, float witch_chance)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnGetMissionVSBossSpawning_PostHandled\" %f. %f. %f. %f", spawn_pos_min, spawn_pos_max, tank_chance, witch_chance);
	}
}

public void L4D_OnReplaceTank(int tank, int newtank)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnReplaceTank\" %d %d", tank, newtank);
	}
}

public void L4D_TankClaw_DoSwing_Pre(int tank, int claw)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_TankClaw_DoSwing_Pre\" %d (Claw = %d)", tank, claw);
	}
}

public void L4D_TankClaw_DoSwing_Post(int tank, int claw)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_TankClaw_DoSwing_Post\" %d (Claw = %d)", tank, claw);
	}
}

public void L4D_TankClaw_GroundPound_Pre(int tank, int claw)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_TankClaw_GroundPound_Pre\" %d (Claw = %d)", tank, claw);
	}
}

public void L4D_TankClaw_GroundPound_Post(int tank, int claw)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_TankClaw_GroundPound_Post\" %d (Claw = %d)", tank, claw);
	}
}

public Action L4D_TankClaw_OnPlayerHit_Pre(int tank, int claw, int player)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_TankClaw_OnPlayerHit_Pre\" %d (Claw = %d) (Target = %d)", tank, claw, player);
	}

	// WORKS - Blocks target player being flung
	// return Plugin_Handled;

	return Plugin_Continue;
}

public void L4D_TankClaw_OnPlayerHit_Post(int tank, int claw, int player)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_TankClaw_OnPlayerHit_Post\" %d (Claw = %d) (Target = %d)", tank, claw, player);
	}
}

public void L4D_TankClaw_OnPlayerHit_PostHandled(int tank, int claw, int player)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_TankClaw_OnPlayerHit_PostHandled\" %d (Claw = %d) (Target = %d)", tank, claw, player);
	}
}

public void L4D_TankRock_OnDetonate(int tank, int rock)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_TankRock_OnDetonate\" %d (Rock = %d)", tank, rock);
	}
}

public Action L4D_TankRock_OnRelease(int tank, int rock, float vecPos[3], float vecAng[3], float vecVel[3], float vecRot[3])
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_TankRock_OnRelease\" %d (Rock = %d) pos(%0.1f %0.1f %0.1f) ang(%0.1f %0.1f %0.1f) vel(%0.1f %0.1f %0.1f) rot(%0.1f %0.1f %0.1f)", tank, rock, vecPos[0], vecPos[1], vecPos[2], vecAng[0], vecAng[1], vecAng[2], vecVel[0], vecVel[1], vecVel[2], vecRot[0], vecRot[1], vecRot[2]);
	}

	// WORKS

	// Change position of rock
	// vecPos[0] += 50.0;
	// vecPos[1] += 50.0;
	// vecPos[2] += 50.0;

	// Change angle of rock
	// vecAng[0] += 90.0;
	// vecAng[1] += 90.0;
	// vecAng[2] += 90.0;

	// Increase velocity of rock
	// vecVel[0] *= 5.0;
	// vecVel[1] *= 5.0;
	// vecVel[2] *= 5.0;

	// Increase rotation of rock
	// vecRot[0] *= 5.0;
	// vecRot[1] *= 5.0;
	// vecRot[2] *= 5.0;

	// return Plugin_Changed;

	return Plugin_Continue;
}

public void L4D_TankRock_OnRelease_Post(int tank, int rock, const float vecPos[3], const float vecAng[3], const float vecVel[3], const float vecRot[3])
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_TankRock_OnRelease_Post\" %d (Rock = %d) pos(%0.1f %0.1f %0.1f) ang(%0.1f %0.1f %0.1f) vel(%0.1f %0.1f %0.1f) rot(%0.1f %0.1f %0.1f)", tank, rock, vecPos[0], vecPos[1], vecPos[2], vecAng[0], vecAng[1], vecAng[2], vecVel[0], vecVel[1], vecVel[2], vecRot[0], vecRot[1], vecRot[2]);
	}
}

public Action L4D_OnTryOfferingTankBot(int tank_index, bool &enterStasis)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnTryOfferingTankBot\" %d. %d", tank_index, enterStasis);
	}

	// WORKS
	// return Plugin_Handled;

	return Plugin_Continue;
}

public void L4D_OnTryOfferingTankBot_Post(int tank_index, bool enterStasis)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnTryOfferingTankBot_Post\" %d. %d", tank_index, enterStasis);
	}
}

public void L4D_OnTryOfferingTankBot_PostHandled(int tank_index, bool enterStasis)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnTryOfferingTankBot_PostHandled\" %d. %d", tank_index, enterStasis);
	}
}

public Action L4D_OnCThrowActivate(int ability)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnCThrowActivate\" %d", ability);
	}

	// WORKS
	// return Plugin_Handled;

	return Plugin_Continue;
}

public void L4D_OnCThrowActivate_Post(int ability)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnCThrowActivate_Post\" %d", ability);
	}
}

public void L4D_OnCThrowActivate_PostHandled(int ability)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnCThrowActivate_PostHandled\" %d", ability);
	}
}

public Action L4D2_OnSelectTankAttackPre(int client, int &sequence)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnSelectTankAttack\" %d. %d", client, sequence);
	}

	// WORKS
	// sequence = 761;
	// return Plugin_Handled;

	return Plugin_Continue;
}

public Action L4D2_OnSelectTankAttack(int client, int &sequence)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnSelectTankAttack\" %d. %d", client, sequence);
	}

	// WORKS
	// sequence = 48;
	// return Plugin_Handled;

	return Plugin_Continue;
}

public Action L4D_OnDoAnimationEvent(int client, int &event, int &variant_param)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnDoAnimationEvent\" %d (%N) - (%d - %d)", client, client > 0 && client <= MaxClients ? client : 0, event, variant_param);
	}

	// WORKS
	/*
	if( event == 4 )
	{
		event = 98;
		return Plugin_Changed;
	}
	// */

	// WORKS
	/*
	if( event == 4 )
	{
		return Plugin_Handled;
	}
	// */

	return Plugin_Continue;
}

public void L4D_OnDoAnimationEvent_Post(int client, int event, int variant_param)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnDoAnimationEvent_Post\" %d (%N) - (%d - %d)", client, client > 0 && client <= MaxClients ? client : 0, event, variant_param);
	}
}

public void L4D_OnDoAnimationEvent_PostHandled(int client, int event, int variant_param)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnDoAnimationEvent_PostHandled\" %d (%N) - (%d - %d)", client, client > 0 && client <= MaxClients ? client : 0, event, variant_param);
	}
}

public Action L4D2_OnSendInRescueVehicle()
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnSendInRescueVehicle\"");
	}

	// WORKS
	// return Plugin_Handled;

	return Plugin_Continue;
}

public Action L4D2_OnEndVersusModeRound(bool countSurvivors)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnEndVersusModeRound\" %d", countSurvivors);
	}

	// WORKS
	// return Plugin_Handled;

	return Plugin_Continue;
}

public void L4D2_OnEndVersusModeRound_Post()
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnEndVersusModeRound_Post\"");
	}
}

public void L4D2_OnEndVersusModeRound_PostHandled()
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnEndVersusModeRound_PostHandled\"");
	}
}

public Action L4D_OnRecalculateVersusScore(int client)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnRecalculateVersusScore\"");
	}

	// UNTESTED
	// return Plugin_Handled;

	return Plugin_Continue;
}

public void L4D_OnRecalculateVersusScore_Post(int client)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnRecalculateVersusScore_Post\"");
	}
}

public Action L4D_OnLedgeGrabbed(int client)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnLedgeGrabbed\" %d", client);
	}

	// WORKS
	// return Plugin_Handled;

	return Plugin_Continue;
}

public void L4D_OnLedgeGrabbed_Post(int client)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnLedgeGrabbed_Post\" %d", client);
	}
}

public void L4D_OnLedgeGrabbed_PostHandled(int client)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnLedgeGrabbed_PostHandled\" %d", client);
	}
}

public void L4D2_OnRevived(int client)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnRevived\" %d", client);
	}
}

public Action L4D2_OnStagger(int target, int source)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnStagger\" %d %d", target, source);
	}

	// WORKS
	// return Plugin_Handled;

	return Plugin_Continue;
}

public void L4D2_OnStagger_Post(int target, int source)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnStagger_Post\" %d %d", target, source);
	}
}

public void L4D2_OnStagger_PostHandled(int target, int source)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnStagger_PostHandled\" %d %d", target, source);
	}
}

public void L4D_OnSwingStart(int client, int weapon)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnSwingStart\" %N %d", client, weapon);
	}
}

public Action L4D_OnShovedBySurvivor(int client, int victim, const float vecDir[3])
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnShovedBySurvivor\" %d %d. (%f %f %f)", client, victim, vecDir[0], vecDir[1], vecDir[2]);
	}

	// WORKS
	// return Plugin_Handled;

	return Plugin_Continue;
}

public void L4D_OnShovedBySurvivor_Post(int client, int victim, const float vecDir[3])
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnShovedBySurvivor_Post\" %d %d. (%f %f %f)", client, victim, vecDir[0], vecDir[1], vecDir[2]);
	}
}

public void L4D_OnShovedBySurvivor_PostHandled(int client, int victim, const float vecDir[3])
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnShovedBySurvivor_PostHandled\" %d %d. (%f %f %f)", client, victim, vecDir[0], vecDir[1], vecDir[2]);
	}
}

public Action L4D2_OnEntityShoved(int client, int entity, int weapon, float vecDir[3], bool bIsHighPounce)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnEntityShoved\" %d %d %d (%f %f %f) IsHighPounce=%d", client, entity, weapon, vecDir[0], vecDir[1], vecDir[2], bIsHighPounce);
	}

	// WORKS
	// return Plugin_Handled;

	return Plugin_Continue;
}

public void L4D2_OnEntityShoved_Post(int client, int entity, int weapon, const float vecDir[3], bool bIsHighPounce)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnEntityShoved_Post\" %d %d %d (%f %f %f) IsHighPounce=%d", client, entity, weapon, vecDir[0], vecDir[1], vecDir[2], bIsHighPounce);
	}
}

public void L4D2_OnEntityShoved_PostHandled(int client, int entity, int weapon, const float vecDir[3], bool bIsHighPounce)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnEntityShoved_PostHandled\" %d %d %d (%f %f %f) IsHighPounce=%d", client, entity, weapon, vecDir[0], vecDir[1], vecDir[2], bIsHighPounce);
	}
}

public Action L4D2_OnPounceOrLeapStumble(int victim, int attacker)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnPounceOrLeapStumble\" %d (%N) %d", victim, victim, attacker);
	}

	// WORKS
	// return Plugin_Handled;

	return Plugin_Continue;
}

public void L4D2_OnPounceOrLeapStumble_Post(int victim, int attacker)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnPounceOrLeapStumble_Post\" %d (%N) %d", victim, victim, attacker);
	}
}

public void L4D2_OnPounceOrLeapStumble_PostHandled(int victim, int attacker)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnPounceOrLeapStumble_PostHandled\" %d (%N) %d", victim, victim, attacker);
	}
}

public Action L4D2_OnSpitSpread(int spitter, int projectile, float &x, float &y, float &z)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnSpitSpread\" %d %d (%f %f %f)", spitter, projectile, x, y, z);
	}

	// Doesn't work
	// x /= 4.0;
	// y /= 4.0;
	// z /= 4.0;
	// return Plugin_Changed;

	// WORKS
	// return Plugin_Handled;

	return Plugin_Continue;
}

public Action L4D2_OnUseHealingItems(int client)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnUseHealingItems\" %d", client);
	}

	// WORKS
	// return Plugin_Handled;

	return Plugin_Continue;
}

public Action L4D2_OnFindScavengeItem(int client, int &item)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnFindScavengeItem\" %d %d", client, item);
	}

	// WORKS
	// if( item == -1 )
	// {
		// item = 440; // 440 being an entity index (must set a valid "weapon_*" entity)
		// return Plugin_Changed;
	// }

	// WORKS
	// return Plugin_Handled;

	return Plugin_Continue;
}

public Action L4D_OnPouncedOnSurvivor(int victim, int attacker)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnPouncedOnSurvivor\" %d (%N) pouncing %d (%N)", attacker, attacker, victim, victim);
	}

	// WORKS
	// return Plugin_Handled;

	return Plugin_Continue;
}

public void L4D_OnPouncedOnSurvivor_Post(int victim, int attacker)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnPouncedOnSurvivor_Post\" %d (%N) pouncing %d (%N)", attacker, attacker, victim, victim);
	}
}

public void L4D_OnPouncedOnSurvivor_PostHandled(int victim, int attacker)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnPouncedOnSurvivor_PostHandled\" %d (%N) pouncing %d (%N)", attacker, attacker, victim, victim);
	}
}

public Action L4D_OnGrabWithTongue(int victim, int attacker)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnGrabWithTongue\" %d (%N) grabbing %d (%N)", attacker, attacker, victim, victim);
	}

	/* WORKS
	// Remove and re-create the custom ability.
	// This allows the player to keep moving and not frozen in place for a few seconds.
	// Tried setting "m_flMaxspeed", movement type and remove FL_FROZEN "m_fFlags" but only this method worked.
	int ability = GetEntPropEnt(attacker, Prop_Send, "m_customAbility");
	RemoveEntity(ability);

	// Create ability again
	L4D_SetClass(attacker, 1);

	// Set next attack time. Otherwise they can shoot again instantly. Remove if that's what you want. Doesn't show cooldown circle for next attack time.
	ability = GetEntPropEnt(attacker, Prop_Send, "m_customAbility");
	if( ability > 0 ) SetEntPropFloat(ability, Prop_Send, "m_nextActivationTimer", GetGameTime() + 2.0, 1);

	return Plugin_Handled;
	// */

	return Plugin_Continue;
}

public void L4D_OnGrabWithTongue_Post(int victim, int attacker)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnGrabWithTongue_Post\" %d (%N) grabbing %d (%N)", attacker, attacker, victim, victim);
	}
}

public void L4D_OnGrabWithTongue_PostHandled(int victim, int attacker)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnGrabWithTongue_PostHandled\" %d (%N) grabbing %d (%N)", attacker, attacker, victim, victim);
	}
}

public Action L4D2_OnJockeyRide(int victim, int attacker)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnJockeyRide\" %d (%N) grabbing %d (%N)", attacker, attacker, victim, victim);
	}

	// WORKS
	// return Plugin_Handled;

	return Plugin_Continue;
}

public void L4D2_OnJockeyRide_Post(int victim, int attacker)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnJockeyRide_Post\" %d (%N) grabbing %d (%N)", attacker, attacker, victim, victim);
	}
}

public void L4D2_OnJockeyRide_PostHandled(int victim, int attacker)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnJockeyRide_PostHandled\" %d (%N) grabbing %d (%N)", attacker, attacker, victim, victim);
	}
}

public Action L4D2_OnStartCarryingVictim(int victim, int attacker)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnStartCarryingVictim\" %d (%N) grabbing %d (%N)", attacker, attacker, victim, victim);
	}

	// WORKS
	// return Plugin_Handled;

	return Plugin_Continue;
}

public void L4D2_OnStartCarryingVictim_Post(int victim, int attacker)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnStartCarryingVictim_Post\" %d (%N) grabbing %d (%N)", attacker, attacker, victim, victim);
	}
}

public void L4D2_OnStartCarryingVictim_PostHandled(int victim, int attacker)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnStartCarryingVictim_PostHandled\" %d (%N) grabbing %d (%N)", attacker, attacker, victim, victim);
	}
}

public void L4D2_OnChargerImpact(int client)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnChargerImpact\" %d (%N)", client, client);
	}
}

public Action L4D_OnVomitedUpon(int victim, int &attacker, bool &boomerExplosion)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnVomitedUpon\" %d > %d (%d)", victim, attacker, boomerExplosion);
	}

	// attacker = victim;
	// return Plugin_Changed;

	// return Plugin_Handled;

	return Plugin_Continue;
}

public void L4D_OnVomitedUpon_Post(int victim, int attacker, bool boomerExplosion)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnVomitedUpon_Post\" %d > %d (%d)", victim, attacker, boomerExplosion);
	}
}

public void L4D_OnVomitedUpon_PostHandled(int victim, int attacker, bool boomerExplosion)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnVomitedUpon_PostHandled\" %d > %d (%d)", victim, attacker, boomerExplosion);
	}
}

public Action L4D2_OnHitByVomitJar(int victim, int &attacker)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnHitByVomitJar\" %d > %d)", victim, attacker);
	}

	// attacker = victim;
	// return Plugin_Changed;

	// WORKS
	// return Plugin_Handled;

	return Plugin_Continue;
}

public void L4D2_OnHitByVomitJar_Post(int victim, int attacker)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnHitByVomitJar_Post\" %d > %d)", victim, attacker);
	}
}

public void L4D2_OnHitByVomitJar_PostHandled(int victim, int attacker)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnHitByVomitJar_PostHandled\" %d > %d)", victim, attacker);
	}
}

public Action L4D_OnMaterializeFromGhostPre(int client)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnMaterializeFromGhostPre\" %d (%N)", client, client);
	}

	// WORKS
	// return Plugin_Handled;

	return Plugin_Continue;
}

public void L4D_OnMaterializeFromGhost(int client)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnMaterializeFromGhost\" %d (%N)", client, client);
	}
}

public void L4D_OnMaterializeFromGhost_PostHandled(int client)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnMaterializeFromGhost_PostHandled\" %d (%N)", client, client);
	}
}

public Action L4D_PipeBombProjectile_Pre(int client, float vecPos[3], float vecAng[3], float vecVel[3], float vecRot[3])
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_PipeBombProjectile_Pre\" %d", client);
	}



	// WORKS

	// Change position of grenade
	// vecPos[0] += 30.0;
	// vecPos[1] += 30.0;
	// vecPos[2] += 30.0;

	// Change angle of grenade
	// vecAng[0] += 90.0;
	// vecAng[1] += 90.0;
	// vecAng[2] += 90.0;

	// Increase velocity of grenade
	// vecVel[0] *= 2.0;
	// vecVel[1] *= 2.0;
	// vecVel[2] *= 2.0;

	// Increase rotation of grenade
	// vecRot[0] *= 5.0;
	// vecRot[1] *= 5.0;
	// vecRot[2] *= 5.0;

	// return Plugin_Changed;



	// WORKS - Blocks grenade creation
	// return Plugin_Handled;

	return Plugin_Continue;
}

public void L4D_PipeBombProjectile_Post(int client, int projectile, const float vecPos[3], const float vecAng[3], const float vecVel[3], const float vecRot[3])
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_PipeBombProjectile_Post\" %d (Grenade = %d) pos(%0.1f %0.1f %0.1f) ang(%0.1f %0.1f %0.1f) vel(%0.1f %0.1f %0.1f) rot(%0.1f %0.1f %0.1f)", client, projectile, vecPos[0], vecPos[1], vecPos[2], vecAng[0], vecAng[1], vecAng[2], vecVel[0], vecVel[1], vecVel[2], vecRot[0], vecRot[1], vecRot[2]);
	}
}

public void L4D_PipeBombProjectile_PostHandled(int client, int projectile, const float vecPos[3], const float vecAng[3], const float vecVel[3], const float vecRot[3])
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_PipeBombProjectile_PostHandled\" %d (Grenade = %d) pos(%0.1f %0.1f %0.1f) ang(%0.1f %0.1f %0.1f) vel(%0.1f %0.1f %0.1f) rot(%0.1f %0.1f %0.1f)", client, projectile, vecPos[0], vecPos[1], vecPos[2], vecAng[0], vecAng[1], vecAng[2], vecVel[0], vecVel[1], vecVel[2], vecRot[0], vecRot[1], vecRot[2]);
	}
}

public Action L4D_Molotov_Detonate(int entity, int client)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_Molotov_Detonate\" %d (%N) (Grenade = %d)", client, client > 0 && client <= MaxClients ? client : 0, entity);
	}

	// WORKS - block grenade detonating
	// return Plugin_Handled;

	return Plugin_Continue;
}

public void L4D_Molotov_Detonate_Post(int entity, int client)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_Molotov_Detonate_Post\" %d (%N) (Grenade = %d)", client, client > 0 && client <= MaxClients ? client : 0, entity);
	}
}

public void L4D_Molotov_Detonate_PostHandled(int entity, int client)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_Molotov_Detonate_PostHandled\" %d (%N) (Grenade = %d)", client, client > 0 && client <= MaxClients ? client : 0, entity);
	}
}

public Action L4D_PipeBomb_Detonate(int entity, int client)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_PipeBomb_Detonate\" %d (%N) (Grenade = %d)", client, client > 0 && client <= MaxClients ? client : 0, entity);
	}

	// WORKS - block grenade detonating
	// return Plugin_Handled;

	return Plugin_Continue;
}

public void L4D_PipeBomb_Detonate_Post(int entity, int client)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_PipeBomb_Detonate_Post\" %d (%N) (Grenade = %d)", client, client > 0 && client <= MaxClients ? client : 0, entity);
	}
}

public void L4D_PipeBomb_Detonate_PostHandled(int entity, int client)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_PipeBomb_Detonate_PostHandled\" %d (%N) (Grenade = %d)", client, client > 0 && client <= MaxClients ? client : 0, entity);
	}
}

public Action L4D2_VomitJar_Detonate(int entity, int client)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_VomitJar_Detonate\" %d (%N) (Grenade = %d)", client, client > 0 && client <= MaxClients ? client : 0, entity);
	}

	// WORKS - block grenade detonating
	// return Plugin_Handled;

	return Plugin_Continue;
}

public void L4D2_VomitJar_Detonate_Post(int entity, int client)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_VomitJar_Detonate_Post\" %d (%N) (Grenade = %d)", client, client > 0 && client <= MaxClients ? client : 0, entity);
	}
}

public void L4D2_VomitJar_Detonate_PostHandled(int entity, int client)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_VomitJar_Detonate_PostHandled\" %d (%N) (Grenade = %d)", client, client > 0 && client <= MaxClients ? client : 0, entity);
	}
}

public Action L4D_PlayerExtinguish(int client)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_PlayerExtinguish\" %d (%N)", client, client);
	}

	// WORKS - Block extinguish
	// return Plugin_Handled;

	return Plugin_Continue;
}

public void L4D_CBreakableProp_Break(int prop, int entity)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_CBreakableProp_Break\" %d (%d)", prop, entity);
	}
}

public Action L4D1_FirstAidKit_StartHealing(int client, int entity)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		// Better to use FindConVar in plugin start, hook the convar for change and store the value in a variable, this is just an example:
		float range = FindConVar("player_use_radius").FloatValue;

		int target = L4D_FindUseEntity(client, true, range); // "m_healTarget" is not set at this point, must call this native if you wish to identify the target before healing
		if( target < 0 || target > MaxClients ) target = 0;

		ForwardCalled("\"L4D1_FirstAidKit_StartHealing\" %d (%N) - MedKit = %d. Healing: %d (%N)", client, client, entity, target, target);
	}

	// WORKS - Block using
	// return Plugin_Handled;

	// Modify healing duration:
	// Better to use FindConVar in plugin start, hook the convar for change and store the value in a variable, this is just an example:
	// FindConVar("first_aid_kit_use_duration").FloatValue = 1.0;

	return Plugin_Continue;
}

public void L4D1_FirstAidKit_StartHealing_Post(int client, int entity)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		int target = GetEntPropEnt(client, Prop_Send, "m_healTarget"); // Target is only valid in post hook
		if( target == -1 ) target = 0;

		ForwardCalled("\"L4D2_BackpackItem_StartAction_Post\" %d (%N) - MedKit = %d. Healing: %d (%N)", client, client, entity, target, target);
	}

	// Reset healing duration:
	// Better to use FindConVar in plugin start, hook the convar for change and store the value in a variable, this is just an example:
	// FindConVar("first_aid_kit_use_duration").FloatValue = 5.0; // Game default is "5"
}

public void L4D1_FirstAidKit_StartHealing_PostHandled(int client, int entity)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D1_FirstAidKit_StartHealing_PostHandled\" %d (%N) - MedKit = %d", client, client, entity);
	}
}

public Action L4D2_BackpackItem_StartAction(int client, int entity, any type)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		// Range of FindUseEntity
		// Better to use FindConVar in plugin start, hook the convar for change and store the value in a variable, this is just an example:
		bool players;
		float range;

		switch( type )
		{
			case L4D2WeaponId_ColaBottles:
			{
				range = FindConVar("cola_bottles_use_range").FloatValue;
			}
			case L4D2WeaponId_Gascan:
			{
				range = FindConVar("gascan_use_range").FloatValue;
			}
			default:
			{
				range = FindConVar("player_use_radius").FloatValue;
				players = true;
			}
		}

		// Validate target
		int target = L4D_FindUseEntity(client, players, range); // "m_healTarget" is not set at this point, must call this native if you wish to identify the target before healing

		if( type == L4D2WeaponId_FirstAidKit || type == L4D2WeaponId_Defibrillator )
		{
			if( target < 0 || target > MaxClients ) target = 0;
		}
		else
		{
			if( target < 0 ) target = 0;
		}

		// Print
		switch( type )
		{
			case L4D2WeaponId_FirstAidKit:
			{
				ForwardCalled("\"L4D2_BackpackItem_StartAction\" %d (%N) - MedKit = %d. Healing: %d (%N)", client, client, entity, target, target);
			}
			case L4D2WeaponId_Defibrillator:
			{
				ForwardCalled("\"L4D2_BackpackItem_StartAction\" %d (%N) - Defib = %d. Reviving: %d (%N)", client, client, entity, target, target);
			}
			case L4D2WeaponId_ColaBottles, L4D2WeaponId_Gascan:
			{
				ForwardCalled("\"L4D2_BackpackItem_StartAction\" %d (%N) - GasCan = %d. Target: %d", client, client, entity, target);
			}
			default:
			{
				ForwardCalled("\"L4D2_BackpackItem_StartAction\" %d (%N) - Item = %d", client, client, entity);
			}
		}
	}

	// WORKS - Block using
	// return Plugin_Handled;

	// Modify use duration:
	// Better to use FindConVar in plugin start, hook the convar for change and store the value in a variable, this is just an example:
	/*
	switch( type )
	{
		case L4D2WeaponId_FirstAidKit:			FindConVar("first_aid_kit_use_duration").FloatValue = 1.0;
		case L4D2WeaponId_Defibrillator:		FindConVar("defibrillator_use_duration").FloatValue = 5.0;
		case L4D2WeaponId_FragAmmo:				FindConVar("upgrade_pack_use_duration").FloatValue = 5.0;
		case L4D2WeaponId_IncendiaryAmmo:		FindConVar("upgrade_pack_use_duration").FloatValue = 5.0;
		case L4D2WeaponId_ColaBottles:			FindConVar("cola_bottles_use_duration").FloatValue = 5.0;
		case L4D2WeaponId_Gascan:				FindConVar("gas_can_use_duration").FloatValue = 5.0;
	}					
	// */

	return Plugin_Continue;
}

public void L4D2_BackpackItem_StartAction_Post(int client, int entity, any type)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		int target = GetEntPropEnt(client, Prop_Send, "m_useActionTarget"); // Target is only valid in post hook
		if( target == -1 ) target = 0;

		switch( type )
		{
			case L4D2WeaponId_FirstAidKit:
			{
				ForwardCalled("\"L4D2_BackpackItem_StartAction_Post\" %d (%N) - MedKit = %d. Healing: %d (%N)", client, client, entity, target, target);
			}
			case L4D2WeaponId_Defibrillator:
			{
				ForwardCalled("\"L4D2_BackpackItem_StartAction_Post\" %d (%N) - Defib = %d. Reviving: %d (%N)", client, client, entity, target, target);
			}
			case L4D2WeaponId_ColaBottles, L4D2WeaponId_Gascan:
			{
				ForwardCalled("\"L4D2_BackpackItem_StartAction_Post\" %d (%N) - GasCan = %d. Target: %d", client, client, entity, target);
			}
			default:
			{
				ForwardCalled("\"L4D2_BackpackItem_StartAction_Post\" %d (%N) - Item = %d", client, client, entity);
			}
		}
	}

	// Reset use duration:
	// Better to use FindConVar in plugin start, hook the convar for change and store the value in a variable, this is just an example:
	/*
	switch( type )
	{
		case L4D2WeaponId_FirstAidKit:			FindConVar("first_aid_kit_use_duration").FloatValue = 5.0;
		case L4D2WeaponId_Defibrillator:		FindConVar("defibrillator_use_duration").FloatValue = 3.0;
		case L4D2WeaponId_FragAmmo:				FindConVar("upgrade_pack_use_duration").FloatValue = 1.9;
		case L4D2WeaponId_IncendiaryAmmo:		FindConVar("upgrade_pack_use_duration").FloatValue = 1.9;
		case L4D2WeaponId_ColaBottles:			FindConVar("cola_bottles_use_duration").FloatValue = 1.95;
		case L4D2WeaponId_Gascan:				FindConVar("gas_can_use_duration").FloatValue = 2.0;
	}
	// */
}

public void L4D2_BackpackItem_StartAction_PostHandled(int client, int entity, any type)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_BackpackItem_StartAction_PostHandled\" %d (%N) - Item = %d", client, client, entity);
	}
}

public Action L4D2_CGasCan_EventKilled(int gascan, int &inflictor, int &attacker)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_CGasCan_EventKilled\" %d (Inf=%d) (Att=%d)", gascan, inflictor, attacker);
	}

	// WORKS - Block detonating
	// return Plugin_Handled;

	// WORKS - Change attacker
	/*
	int bot = GetRandomSurvivor(1, 1);
	inflictor = bot;
	attacker = bot;
	return Plugin_Changed;
	// */

	return Plugin_Continue;
}

public void L4D2_CGasCan_EventKilled_Post(int gascan, int inflictor, int attacker)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_CGasCan_EventKilled_Post\" %d (Inf=%d) (Att=%d)", gascan, inflictor, attacker);
	}
}

public void L4D2_CGasCan_EventKilled_PostHandled(int gascan, int inflictor, int attacker)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_CGasCan_EventKilled_PostHandled\" %d (Inf=%d) (Att=%d)", gascan, inflictor, attacker);
	}
}

public Action L4D2_CGasCan_ActionComplete(int client, int gascan, int nozzle)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_CGasCan_ActionComplete\" %d (%N) - GasCan: %d > Nozzle: %d", client, client, gascan, nozzle);
	}

	// WORKS

	/*
	// Probably want to fire the event and output for other plugins, whilst blocking the call itself to prevent adding to the Scavenge Score pour gas count.
	// See the "Scavenge Score Fix - Gascan Pouring" plugin for more details.

	// Fire event
	Event hEvent = CreateEvent("gascan_pour_completed", true);
	if( hEvent != null )
	{
		hEvent.SetInt("userid", GetClientUserId(client));
		hEvent.Fire();
	}

	// Fire output
	FireEntityOutput(entity, "OnUseFinished", client);

	// Block call
	return Plugin_Handled;
	// */

	return Plugin_Continue;
}

public void L4D2_CGasCan_ActionComplete_Post(int client, int gascan, int nozzle)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_CGasCan_ActionComplete_Post\" %d (%N) - GasCan: %d > Nozzle: %d", client, client, gascan, nozzle);
	}
}

public void L4D2_CGasCan_ActionComplete_PostHandled(int client, int gascan, int nozzle)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_CGasCan_ActionComplete_PostHandled\" %d (%N) - GasCan: %d > Nozzle: %d", client, client, gascan, nozzle);
	}
}

public Action L4D2_CGasCan_ShouldStartAction(int client, int gascan, int nozzle)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_CGasCan_ShouldStartAction\" %d (%N) - GasCan: %d > Nozzle: %d", client, client, gascan, nozzle);
	}

	// WORKS
	// return Plugin_Handled;

	return Plugin_Continue;
}

public void L4D2_CGasCan_ShouldStartAction_Post(int client, int gascan, int nozzle)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_CGasCan_ShouldStartAction_Post\" %d (%N) - GasCan: %d > Nozzle: %d", client, client, gascan, nozzle);
	}
}

public void L4D2_CGasCan_ShouldStartAction_PostHandled(int client, int gascan, int nozzle)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_CGasCan_ShouldStartAction_PostHandled\" %d (%N) - GasCan: %d > Nozzle: %d", client, client, gascan, nozzle);
	}
}

public Action L4D2_CInsectSwarm_CanHarm(int acid, int spitter, int entity)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_CInsectSwarm_CanHarm\" %d %N > Acid: %d > Ent: %d", spitter, spitter < 1 ? 0 : spitter, acid, entity);
	}

	// WORKS
	// return Plugin_Handled;

	return Plugin_Continue;
}

public void L4D2_CInsectSwarm_CanHarm_Post(int acid, int spitter, int entity)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_CInsectSwarm_CanHarm_Post\" %d %N > Acid: %d > Ent: %d", spitter, spitter < 1 ? 0 : spitter, acid, entity);
	}
}

public Action L4D2_OnChooseVictim(int specialInfected, int &curTarget)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnChooseVictim\" %d > %d", specialInfected, curTarget);
	}

	// WORKS
	// curTarget = 2; // Must be valid client index, 0 = crash.
	// return Plugin_Changed;

	// ATTACK THEMSELVES (no target) - the special will stand still.
	// return Plugin_Handled;

	return Plugin_Continue;
}

public Action L4D_OnGetScriptValueInt(const char[] key, int &retVal)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnGetScriptValueInt\" \"%s\" %d", key, retVal);
	}

	// WORKS - green gascans on back from map c4m*
	/*
	if( strcmp(key, "GasCansOnBacks") == 0 )
	{
		retVal = 1;
		return Plugin_Handled;
	}
	// */

	/*
	// Setting this to test the "L4D_OnGetScriptValueVector" forward and "PreferredMobPosition" key
	if( strcmp(key, "PreferredMobDirection") == 0 )
	{
		retVal = 10;
		return Plugin_Handled;
	}
	// */

	return Plugin_Continue;
}

public Action L4D_OnGetScriptValueFloat(const char[] key, float &retVal)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnGetScriptValueFloat\" \"%s\" %f", key, retVal);
	}

	// WORKS
	/*
	if( strcmp(key, "TempHealthDecayRate") == 0 )
	{
		retVal = 1.0;
		return Plugin_Handled;
	}
	// */

	return Plugin_Continue;
}

// Unused, unable to determine if the return value is modified, and potentially different detour setup for linux
/*
public Action L4D_OnGetScriptValueVector(const char[] key, float retVal[3])
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnGetScriptValueVector\" %s. %f %f %f", key, retVal[0], retVal[1], retVal[2]);
	}

	// UNKNOWN - Unable to determine if the return value is modified, and potentially different detour setup for linux
	// Set "PreferredMobDirection" above to override the value, then "z_spawn mob auto" in console to test the function below
	// To test, enter this into server console: sm_cvar mp_gamemode dash; changelevel c5m2_park
	// if( strcmp(key, "PreferredMobPosition") == 0 || strcmp(key, "SpawnSetPosition") == 0 )
	// {
		// retVal = view_as<float>({ 0.0, 0.0, 0.0 });
		// retVal = view_as<float>({ -6717.444335, 8427.956054, 94.587501 });
		// retVal = view_as<float>({ -4368.217773, -2205.327636, -255.968750 }); // By first pole // c5m2_park
		// retVal = view_as<float>({ -7085.283203, -1518.681152, -255.968750 }); // Ahead // c5m2_park
		// retVal = view_as<float>({ -3945.166503, -1268.468750, -343.968750 }); // Start saferoom // c5m2_park
		// return Plugin_Handled;
	// }

	return Plugin_Continue;
}
*/

public Action L4D_OnGetScriptValueString(const char[] key, const char[] defaultVal, char retVal[128])
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		// Some of the returned data:
		// [A_CustomFinaleMusic5]. []. [Event.FinaleWave4]
		// [OnChangeFinaleMusic]. []. [FINALE_CUSTOM_DELAY]
		// [OnChangeFinaleMusic]. []. [Event.TankMidpoint]

		// ForwardCalled("\"L4D_OnGetScriptValueString\" [%s]. [%s]. [%s].", key, defaultVal, retVal); // Because printing random chars can break console printing text or possibly cause a crash?
		ForwardCalled("\"L4D_OnGetScriptValueString\"");
	}

	// Don't know if override works
	// UNKNOWN - MUSIC STRINGS ARE ALWAYS RANDOM CHARS, THIS SEEMS TO BE NORMAL, LOOK AT USERMSG HOOKS ETC.
	// if( strcmp(key, "OnChangeFinaleMusic") == 0 )
	// {
		// retVal = "Event.Tank";
		// return Plugin_Handled;
	// }

	return Plugin_Continue;
}

public Action L4D2_OnGetScriptValueVoid(const char[] key, fieldtype_t &type, VariantBuffer retVal, int hScope)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnGetScriptValueVoid\" \"%s\" hScope = %d", key, hScope);
	}

	// WORKS - example setting temporary health decay rate:
	/*
	if( strcmp(key, "TempHealthDecayRate") == 0 )
	{
		static float ress = -1.0;
		if( retVal.m_float != ress )
		{
			ress = retVal.m_float;
		}

		// Must specify the type of value being set, see left4dhooks include file for the "fieldtype_t" and "VariantBuffer" lists.
		type = FIELD_FLOAT;
		retVal.m_float = 2.0;
		return Plugin_Handled;
	}
	// */

	// WORKS - green gascans on back from map c4m*
	/*
	if( strcmp(key, "GasCansOnBacks") == 0 )
	{
		type = FIELD_INTEGER;
		retVal.m_int = 1;
		return Plugin_Handled;
	}
	// */

	return Plugin_Continue;
}

public Action L4D2_OnGetScriptValueInt(const char[] key, int &retVal, int hScope)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnGetScriptValueInt\" \"%s\" {%d}. hScope = %d", key, retVal, hScope);
	}

	return Plugin_Continue;
}

public Action L4D2_OnGetScriptValueFloat(const char[] key, float &retVal, int hScope)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnGetScriptValueFloat\" \"%s\" {%f}. hScope = %d", key, retVal, hScope);
	}

	return Plugin_Continue;
}

public Action L4D2_OnGetScriptValueVector(const char[] key, float retVal[3], int hScope)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnGetScriptValueVector\" \"%s\" {%f %f %f}. hScope = %d", key, retVal[0], retVal[1], retVal[2], hScope);
	}

	return Plugin_Continue;
}

public Action L4D_OnHasConfigurableDifficulty(int &retVal)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnHasConfigurableDifficulty\" %d", retVal);
	}

	// WORKS
	// retVal = 0;
	// return Plugin_Handled;

	return Plugin_Continue;
}

public void L4D_OnHasConfigurableDifficulty_Post(int retVal)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnHasConfigurableDifficulty_Post\" %d", retVal);
	}
}

public Action L4D_OnGetSurvivorSet(int &retVal)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnGetSurvivorSet\" %d", retVal);
	}

	// WORKS
	// retVal = 1;
	// return Plugin_Handled;

	return Plugin_Continue;
}

public Action L4D_OnFastGetSurvivorSet(int &retVal)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnFastGetSurvivorSet\" %d", retVal);
	}

	// WORKS
	// retVal = 1;
	// return Plugin_Handled;

	return Plugin_Continue;
}

public Action L4D_OnStartMeleeSwing(int client, bool boolean)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnStartMeleeSwing\" %d. %d", client, boolean);
	}

	// WORKS - PREDICTION ISSUES - Hear and partially see swing in first person
	// return Plugin_Handled;

	return Plugin_Continue;
}

public void L4D_OnStartMeleeSwing_Post(int client, bool boolean)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnStartMeleeSwing_Post\" %d. %d", client, boolean);
	}
}

public void L4D_OnStartMeleeSwing_PostHandled(int client, bool boolean)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnStartMeleeSwing_PostHandled\" %d. %d", client, boolean);
	}
}

public Action L4D2_MeleeGetDamageForVictim(int client, int weapon, int victim, float &damage)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_MeleeGetDamageForVictim\" %d %d > %d (%f)", client, weapon, victim, damage);
	}

	// WORKS
	// damage = 10.0;
	// return Plugin_Changed;

	// WORKS
	// return Plugin_Handled;

	return Plugin_Continue;
}

public Action L4D2_OnChangeFinaleStage(int &finaleType, const char[] arg)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnChangeFinaleStage\" %d. %s", finaleType, arg);
	}

	// WORKS
	// finaleType = 8;
	// return Plugin_Changed;

	// WORKS
	// return Plugin_Handled;

	return Plugin_Continue;
}

public void L4D2_OnChangeFinaleStage_Post(int finaleType, const char[] arg)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnChangeFinaleStage_Post\" %d. %s", finaleType, arg);
	}
}

public void L4D2_OnChangeFinaleStage_PostHandled(int finaleType, const char[] arg)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnChangeFinaleStage_PostHandled\" %d. %s", finaleType, arg);
	}
}

public void L4D_OnServerHibernationUpdate(bool hibernating)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnServerHibernationUpdate\" %d", hibernating);
	}
}

public Action L4D2_OnClientDisableAddons(const char[] SteamID)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnClientDisableAddons\" %s", SteamID);
	}

	// Requires l4d2_addons_eclipse 1 to be used.
	// return Plugin_Continue; // Block addons.
	return Plugin_Handled; // Allow addons.
}

public void L4D_OnGameModeChange(int gamemode)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnGameModeChange\" %d", gamemode);
	}
}

public Action L4D_OnKnockedDown(int client, int reason)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnKnockedDown\" %d (%N) reason %d", client, client, reason);
	}

	// To stop player velocity use RequestFrame and set their velocity to 0,0,0 or restore to previous maybe?
	// RequestFrame(OnFrameResetMove, GetClientUserId(client));

	// WORKS - Block the flung animation, player velocity will still change (L4D2 only?)
	// return Plugin_Handled;

	return Plugin_Continue;
}

stock void OnFrameResetMove(int client)
{
	client = GetClientOfUserId(client);
	if( client && IsClientInGame(client) )
	{
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, view_as<float>({ 0.0, 0.0, 0.0 }));
	}
}

public void L4D_OnKnockedDown_Post(int client, int reason)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnKnockedDown_Post\" %d (%N) reason %d", client, client, reason);
	}
}

public void L4D_OnKnockedDown_PostHandled(int client, int reason)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnKnockedDown_PostHandled\" %d (%N) reason %d", client, client, reason);
	}
}

public Action L4D2_OnSlammedSurvivor(int victim, int attacker, bool &bWallSlam, bool &bDeadlyCharge)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnSlammedSurvivor\" %d (%N) slammed %d (%N). Wall %d. Deadly %d", attacker, attacker, victim, victim, bWallSlam, bDeadlyCharge);
	}

	return Plugin_Continue;
}

public void L4D2_OnSlammedSurvivor_Post(int victim, int attacker, bool bWallSlam, bool bDeadlyCharge)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnSlammedSurvivor_Post\" %d (%N) slammed %d (%N). Wall %d. Deadly %d", attacker, attacker, victim, victim, bWallSlam, bDeadlyCharge);
	}
}

public void L4D2_OnSlammedSurvivor_PostHandled(int victim, int attacker, bool bWallSlam, bool bDeadlyCharge)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnSlammedSurvivor_PostHandled\" %d (%N) slammed %d (%N). Wall %d. Deadly %d", attacker, attacker, victim, victim, bWallSlam, bDeadlyCharge);
	}
}

public Action L4D2_OnPummelVictim(int attacker, int victim)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnPummelVictim\" %d (%N) pummelled %d (%N)", attacker, attacker, victim, victim);
	}

	// WORKS - Block being pummelled

	// Note: when blocking pummel the Survivor will be stuck inside the Charger (eventually teleporting them) and AI chargers cannot move. To fix this uncomment and use the following 4 lines:
	// DataPack dPack = new DataPack();
	// dPack.WriteCell(GetClientUserId(attacker));
	// dPack.WriteCell(GetClientUserId(victim));
	// RequestFrame(OnPummelTeleport, dPack);

	// To block the stumble animation, uncomment and use the following 2 lines:
	// AnimHookEnable(victim, OnPummelOnAnimPre, INVALID_FUNCTION);
	// CreateTimer(0.3, TimerOnPummelResetAnim, victim);

	// return Plugin_Handled;

	return Plugin_Continue;
}

// To fix getting stuck use this:
stock void OnPummelTeleport(DataPack dPack)
{
	dPack.Reset();
	int attacker = dPack.ReadCell();
	int victim = dPack.ReadCell();
	delete dPack;

	attacker = GetClientOfUserId(attacker);
	if( !attacker || !IsClientInGame(attacker) ) return;

	victim = GetClientOfUserId(victim);
	if( !victim || !IsClientInGame(victim) ) return;

	SetVariantString("!activator");
	AcceptEntityInput(victim, "SetParent", attacker);
	TeleportEntity(victim, view_as<float>({ 50.0, 0.0, 0.0 }), NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(victim, "ClearParent");
}

// To block the stumble animation use the next two functions:
stock Action OnPummelOnAnimPre(int client, int &anim)
{
	if( anim == L4D2_ACT_TERROR_SLAMMED_WALL || anim == L4D2_ACT_TERROR_SLAMMED_GROUND )
	{
		anim = L4D2_ACT_STAND;

		return Plugin_Changed;
	}

	return Plugin_Continue;
}

stock Action TimerOnPummelResetAnim(Handle timer, int victim) // Don't need client userID since it's not going to be validated just removed
{
	AnimHookDisable(victim, OnPummelOnAnimPre);

	return Plugin_Continue;
}

public void L4D2_OnPummelVictim_Post(int attacker, int victim)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnPummelVictim_Post\" %d (%N) pummelled %d (%N)", attacker, attacker, victim, victim);
	}
}

public void L4D2_OnPummelVictim_PostHandled(int attacker, int victim)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnPummelVictim_PostHandled\" %d (%N) pummelled %d (%N)", attacker, attacker, victim, victim);
	}
}

public Action L4D2_OnThrowImpactedSurvivor(int attacker, int victim)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnThrowImpactedSurvivor\" %d (%N) flung %d (%N)", attacker, attacker, victim, victim);
	}

	// WORKS - Block being flung
	// return Plugin_Handled;

	return Plugin_Continue;
}

public void L4D2_OnThrowImpactedSurvivor_Post(int attacker, int victim)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnThrowImpactedSurvivor_Post\" %d (%N) flung %d (%N)", attacker, attacker, victim, victim);
	}
}

public void L4D2_OnThrowImpactedSurvivor_PostHandled(int attacker, int victim)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnThrowImpactedSurvivor_PostHandled\" %d (%N) flung %d (%N)", attacker, attacker, victim, victim);
	}
}

public Action L4D_OnCancelStagger(int client)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnCancelStagger\" %d (%N)", client, client);
	}

	// WORKS
	// return Plugin_Handled;

	return Plugin_Continue;
}

public void L4D_OnCancelStagger_Post(int client)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnCancelStagger_Post\" %d (%N)", client, client);
	}
}

public void L4D_OnCancelStagger_PostHandled(int client)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnCancelStagger_PostHandled\" %d (%N)", client, client);
	}
}

public Action L4D2_OnPlayerFling(int client, int attacker, float vecDir[3])
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnPlayerFling\" %d (%N) flung %d (%N). vecDir: (%0.1f %0.1f %0.1f)", attacker, attacker, client, client, vecDir[0], vecDir[1], vecDir[2]);
	}

	// WORKS - Block being flung
	// return Plugin_Handled;

	return Plugin_Continue;
}

public void L4D2_OnPlayerFling_Post(int client, int attacker, const float vecDir[3])
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnPlayerFling_Post\" %d (%N) flung %d (%N). vecDir: (%0.1f %0.1f %0.1f)", attacker, attacker, client, client, vecDir[0], vecDir[1], vecDir[2]);
	}
}

public void L4D2_OnPlayerFling_PostHandled(int client, int attacker, const float vecDir[3])
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnPlayerFling_PostHandled\" %d (%N) flung %d (%N). vecDir: (%0.1f %0.1f %0.1f)", attacker, attacker, client, client, vecDir[0], vecDir[1], vecDir[2]);
	}
}

/*
public Action L4D_OnMotionControlledXY(int client, int activity)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_IsMotionControlledXY\" %d %N - %d", client, client, activity);
	}

	// WORKING
	// return Plugin_Handled;

	return Plugin_Continue;
}
*/

public Action L4D_OnFatalFalling(int client, int camera)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnFatalFalling\" %d %N (cam: %d)", client, client, camera);
	}

	// WORKS - Block death fall camera
	// return Plugin_Handled;

	return Plugin_Continue;
}

public void L4D_OnFalling(int client)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnFalling\" %d %N", client, client);
	}
}

public Action L4D_OnPlayerCough(int client, int attacker)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnPlayerCough\" %d %N (caused by %d %N)", client, client, attacker, attacker);
	}

	// WORKS - Block cough
	// return Plugin_Handled;

	return Plugin_Continue;
}

public void L4D_OnPlayerCough_Post(int client, int attacker)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnPlayerCough_Post\" %d %N (caused by %d %N)", client, client, attacker, attacker);
	}
}

public void L4D_OnPlayerCough_PostHandled(int client, int attacker)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnPlayerCough_PostHandled\" %d %N (caused by %d %N)", client, client, attacker, attacker);
	}
}

public void L4D_OnWitchSetHarasser(int witch, int victim)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnWitchSetHarasser\" %d > %d %N", witch, victim, victim);
	}
}

public void L4D_OnEnterStasis(int tank)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnEnterStasis\" %d %N", tank, tank);
	}
}

public void L4D_OnLeaveStasis(int tank)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnLeaveStasis\" %d %N", tank, tank);
	}
}



/*
// Can trigger with: "z_spawn_old hunter auto" in console.
// BROKEN, SPAWNS SPECIALS AT 0,0,0 WHEN MODIFYING VALUES
public Action L4D_OnGetRandomPZSpawnPosition(int &client, int &zombieClass, int &attempts, float vecPos[3])
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnGetRandomPZSpawnPosition\" Client(%d). Class(%d). Attempts(%d). (%f %f %f)", client, zombieClass, attempts, vecPos[0], vecPos[1], vecPos[2]);
	}

	// zombieClass = 1; // Smoker
	attempts = 20;
	return Plugin_Changed; // WORKS
}
// */

/* Not available
public Action L4D_OnInfectedShoved(int infected, int entity)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D_OnInfectedShoved\" %d. %d", infected, entity);
	}
}

public void L4D2_OnWaterMove(int client)
{
	static int called;
	if( called < MAX_CALLS )
	{
		if( called == 0 ) g_iForwards++;
		called++;

		ForwardCalled("\"L4D2_OnWaterMove\" %d", client);
	}
}
// */





// ====================================================================================================
// HELPERS
// ====================================================================================================
void ForwardCalled(const char[] format, any ...)
{
	if( g_bTestForwards == false ) return;

	static char buffer[512];
	VFormat(buffer, sizeof(buffer), format, 2);

	// LogAction(0, -1, "Forward %d/%d called %s", g_iForwards, g_iForwardsMax, buffer);

	// PrintToServer("----------");
	PrintToServer("L4DD: %s", buffer);
	// PrintToServer("----------");
}

stock bool TraceFilter(int entity, int contentsMask, int client)
{
	if( entity == client )
		return false;
	return true;
}