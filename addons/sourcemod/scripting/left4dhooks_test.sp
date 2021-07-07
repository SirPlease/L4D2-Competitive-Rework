/*
*	Left 4 DHooks Direct - TESTER
*	Copyright (C) 2021 Silvers
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



#define PLUGIN_VERSION		"1.43"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Left 4 DHooks Direct - TESTER
*	Author	:	SilverShot
*	Descrp	:	Left 4 DHooks Direct - Demo and Test plugin.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=321696
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.43 (01-Jul-2021)
	- L4D1 & L4D2 update:
	- Added forward "L4D_OnMaterializeFromGhostPre" and "L4D_OnMaterializeFromGhost" when a client spawns out of ghost mode. Thanks to "ProjectSky" and "sorallll" and for suggesting.

	- Added native "L4D_RespawnPlayer" to respawn a dead player.
	- Added native "L4D_SetHumanSpec" to takeover a bot.
	- Added native "L4D_TakeOverBot" to takeover a bot.
	- Added native "L4D_CanBecomeGhost" to determine when someone is about to enter ghost mode.
	- Added native "L4D2_AreWanderersAllowed" to determine if Witches can wander.
	- Added native "L4D_IsFinaleEscapeInProgress" to determine if Witches can wander around.
	- Added native "L4D_GetLastKnownArea" to retrieve a clients last known nav area.

	- Added missing "ACT_ITEM2_VM_LOWERED_TO_IDLE" to the "data/left4dhooks.l4d2.cfg" config.

	- Updated: Plugin, Test plugin, Include file, GameData files and "data/left4dhooks.l4d2.cfg" config.

1.42 (23-Jun-2021)
	- L4D1 & L4D2 update:
	- Added forward "L4D_OnVomitedUpon" when client is covered in vomit.
	- Added forward "L4D_OnEnterGhostStatePre" with the ability to block entering ghost state.
	- Changed 2 signatures to be compatible with detouring: "CTerrorPlayer::OnStaggered" and "CTerrorPlayer::OnVomitedUpon".

	- L4D2 update only:

	- Added forward "L4D2_OnHitByVomitJar" when a Bilejar explodes on clients.
	- Added native "L4D2_NavAreaTravelDistance" to return the nav flow distance between two areas.
	- Added native "L4D2_UseAdrenaline" to give a player the Adrenaline effect and health benefits.

	- Added various natives as wrappers executing VScript code:
		- These are slower than native SDKCalls, please report popular ones to convert to fast SDKCalls.
		"L4D2_VScriptWrapper_GetMapNumber"
		"L4D2_VScriptWrapper_HasEverBeenInjured"
		"L4D2_VScriptWrapper_GetAliveDuration"
		"L4D2_VScriptWrapper_IsDead"
		"L4D2_VScriptWrapper_IsDying"
		"L4D2_VScriptWrapper_UseAdrenaline"
		"L4D2_VScriptWrapper_ReviveByDefib"
		"L4D2_VScriptWrapper_ReviveFromIncap"
		"L4D2_VScriptWrapper_GetSenseFlags"
		"L4D2_VScriptWrapper_NavAreaBuildPath"
		"L4D2_VScriptWrapper_NavAreaTravelDistance" // Added as a demonstration and test, SDKCall is available, use "L4D2_NavAreaTravelDistance" instead.

	- Updated: Plugin, Test plugin, GameData and Include file. Both L4D1 and L4D2.
	- Thanks to "Eärendil" for showing me how to call some VScript functions.

1.36 (20-Apr-2021)
	- Restricted native "L4D2_IsReachable" client index to Survivor bots only. Attempts to find a valid bot otherwise it will throw an error. Thanks to "Forgetest" for reporting.

1.20 (23-Mar-2021)
	- Added native "L4D_HasPlayerControlledZombies".

1.19 (27-Aug-2020)
	- Marked "Direct_TryOfferingTankBot" as tested and working.

1.18 (20-Aug-2020)
	- Minor change to reflect "L4D2_IsValidWeapon" changes.

1.17 (20-Jul-2020)
	- Added native (L4D2 only): "L4D2_IsReachable" to check if a position is accessible to a Survivor Bot.
	- Added some extra checks to prevent errors being thrown when testing.

1.16a (16-Jun-2020)
	- Added "GetAnyRandomClient" stock. For demonstration.

1.16 (05-Jun-2020)
	- Now supports "L4D_LobbyUnreserve" native.

1.14 (10-May-2020)
	- New natives added.

1.13 (05-May-2020)
	- Made all natives optional from the include file. Thanks to "Crasher_3637" for requesting.

1.10 (14-Mar-2020)
	- New natives added.

1.9 (10-Mar-2020)
	- New natives added.
	- Test examples for L4D2: "L4D2_GetVScriptOutput" native.

1.8 (08-Mar-2020)
	- Removed "L4D2_OnClientDisableAddons" setting addons allowed.

1.7 (04-Mar-2020)
	- New natives added.

1.6 (02-Mar-2020)
	- No changes.

1.5 (28-Feb-2020)
	- Removed some forward debug printing that wasn't being limited by MAX_CALLS.
	- Removed "L4D_OnGetRandomPZSpawnPosition" forward due to bugs.

1.4 (28-Feb-2020)
	- Minor changes. Not important.

1.3 (27-Feb-2020)
	- Major changes.

1.2 (27-Feb-2020)
	- No changes.

1.1 (27-Feb-2020)
	- Major changes.

1.0 (24-Feb-2020)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <left4dhooks>
#define REQUIRE_PLUGIN

#define MAX_CALLS			1		// How many times to print each forward

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

	// (+2 for "L4D2_OnEndVersusModeRound_Post" and "L4D2_OnSelectTankAttackPre")
	if( g_bLeft4Dead2 )
		g_iForwardsMax = 48;
	else
		g_iForwardsMax = 37;

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

	HookEvent("player_incapacitated",	player_incapacitated);
	HookEvent("revive_success",			revive_success);
	HookEvent("player_death",			player_death);
	HookEvent("round_end",				round_end);
	HookEvent("player_spawn",			player_spawn);
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
// CRAWLING TEST - Remove "INCAPPED CRAWLING WITH ANIMATION" plugin to test.
// ====================================================================================================
bool g_bCrawling;

public void player_spawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client && IsClientInGame(client) )
		AnimHookEnable(client, OnAnim, OnAnimPost);
}

public void player_incapacitated(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( GetClientTeam(client) == 2 )
		AnimHookEnable(client, OnAnim, OnAnimPost);
}

public void revive_success(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	AnimHookDisable(client, OnAnim, OnAnimPost);
}

public void player_death(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	AnimHookDisable(client, OnAnim, OnAnimPost);
}

public void round_end(Event event, const char[] name, bool dontBroadcast)
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		AnimHookDisable(i, OnAnim, OnAnimPost);
	}
}

// Uses "Activity" numbers, which means 1 animation number is the same for all Survivors.
Action OnAnim(int client, int &anim)
{
	// /*
	if( g_bCrawling )
	{
		anim = g_bLeft4Dead2 ? 696 : 1197;
		return Plugin_Changed;
	}
	// */

	return Plugin_Continue;
}

// Uses "m_nSequence" animation numbers, which are different for each model.
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
		GetEntProp(client, Prop_Send, "m_isHangingFromLedge") == 0
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
}
// ====================================================================================================





// ====================================================================================================
// COMMAND TEST
// ====================================================================================================
public Action sm_l4df(int client, int args)
{
	ReplyToCommand(client, "[Left4DHooks] Forwards triggered %d/%d", g_iForwards, g_iForwardsMax);
	return Plugin_Handled;
}

public Action sm_l4dd(int client, int args)
{
	PrintToServer("Uncomment the things you want to test. All disabled by default now.");
	PrintToServer("Must test individual sections on their own otherwise you'll receive errors about symbols already defined..");



	// =========================
	// NATIVES - Mine
	// =========================

	/*
	// WORKS
	// When a Survivor is taking over another Survivor, should change team to 0 otherwise the players old character will disappear.
	ChangeClientTeam(client, 0);

	int bot = GetAnyRandomBot();
	PrintToServer("L4D_SetHumanSpec %d (%d - %N)",					L4D_SetHumanSpec(bot, client), bot, bot);
	PrintToServer("L4D_TakeOverBot %d (%d - %N)",					L4D_TakeOverBot(client), bot, bot);

	// WORKS
	L4D_RespawnPlayer(client);
	PrintToServer("L4D_RespawnPlayer %N", client);

	// WORKS
	PrintToServer("L4D_GetLastKnownArea %d",						L4D_GetLastKnownArea(client));

	// WORKS
	PrintToServer("L4D_CanBecomeGhost %d",							L4D_CanBecomeGhost(client));

	// WORKS
	PrintToServer("L4D_IsFinaleEscapeInProgress %d",				L4D_IsFinaleEscapeInProgress());
	PrintToChatAll("L4D_IsFinaleEscapeInProgress %d",				L4D_IsFinaleEscapeInProgress());

	// WORKS?
	if( g_bLeft4Dead2 )
		PrintToServer("L4D2_AreWanderersAllowed %d",				L4D2_AreWanderersAllowed());
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

		// WORKING
		if( L4D2_GetVScriptOutput("Director.GetGameMode()", buffer, sizeof(buffer)) )
			PrintToServer("VScript: Director.GetGameMode() = %s", buffer);

		// WORKING
		if( L4D2_GetVScriptOutput("GetMaxFlowDistance()", buffer, sizeof(buffer)) )
			PrintToServer("VScript: GetMaxFlowDistance() = %s", buffer);

		// WORKING
		if( L4D2_GetVScriptOutput("Director.GetFurthestSurvivorFlow()", buffer, sizeof(buffer)) )
			PrintToServer("VScript: Director.GetFurthestSurvivorFlow() = %s", buffer);

		// WORKING
		int a = 14, b = 300;
		Format(buffer, sizeof(buffer), "test_a <- %d; test_b <- %d; <RETURN>test_a + test_b</RETURN>", a, b);
		if( L4D2_GetVScriptOutput(buffer, buffer, sizeof(buffer)) )
			PrintToServer("VScript: Math test_A = %s", buffer);

		// WORKING
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
	PrintToServer("L4D2_GetScriptValueInt %d",					L4D2_GetScriptValueInt("MaxSpecials", 314)); //WORKING
	// PrintToServer("L4D2_GetScriptValueFloat %f",				L4D2_GetScriptValueFloat("TempHealthDecayRate", 0.314)); // Only returns default value provided.



	// WORKING
	int target = GetClientAimTarget(client, false);
	if( target != -1 )
	{
		PrintToServer("L4D_Dissolve %d",					L4D_Dissolve(target));
	}

	PrintToServer("L4D_Deafen %d",							L4D_Deafen(client)); // WORKING

	PrintToServer("L4D_OnITExpired %d",						L4D_OnITExpired(client)); // WORKING



	float vPos[3];
	float vAng[3];

	GetClientEyeAngles(client, vAng);
	GetClientEyePosition(client, vPos);



	// WORKING
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



	PrintToServer("L4D_HasAnySurvivorLeftSafeArea %d",					L4D_HasAnySurvivorLeftSafeArea()); // WORKING

	PrintToServer("L4D_IsAnySurvivorInCheckpoint %d",					L4D_IsAnySurvivorInCheckpoint()); // WORKING

	PrintToServer("L4D_IsAnySurvivorInStartArea %d",					L4D_IsAnySurvivorInStartArea()); // WORKING

	PrintToServer("L4D_IsInFirstCheckpoint %d",							L4D_IsInFirstCheckpoint(client)); // WORKING

	PrintToServer("L4D_IsInLastCheckpoint %d",							L4D_IsInLastCheckpoint(client)); // WORKING

	PrintToServer("L4D_HasPlayerControlledZombies %d",					L4D_HasPlayerControlledZombies()); // WORKING


	// WORKING
	// L4D2_UseAdrenaline(client, 15.0, false);
	L4D2_UseAdrenaline(client);
	PrintToServer("L4D2_UseAdrenaline %N", client);



	// WORKING
	// The "Fuse" + "Light" particles must be manually added in your plugin.
	// I intentionally did not include this in left4dhooks in case you wanted to create an activated PipeBomb projectile without the particles.
	int pipe = L4D_PipeBombPrj(client, vPos, vAng);

	// Create particles
	CreateParticle(pipe, 0);
	CreateParticle(pipe, 1);

	// Might work, from "PipeBomb Shove" plugin
	SetEntPropFloat(pipe, Prop_Data, "m_DmgRadius", 400.0);
	SetEntPropFloat(pipe, Prop_Data, "m_flDamage", 25.0);

	PrintToServer("L4D2_PipeBombPrj %d", pipe);



	// WORKING
	float vDir[3];
	// vDir = view_as<float>({ 0.0, 1.0, 0.0}); // Spin top over
	vDir = view_as<float>({ -1.0, 0.0, 0.0}); // Spin sideways
	NormalizeVector(vDir, vDir);
	ScaleVector(vDir, 10000.0);
	PrintToServer("L4D_AngularVelocity %d",								L4D_AngularVelocity(pipe, vDir));



	// WORKING
	if( g_bLeft4Dead2 )
	{
		GetAngleVectors(vAng, vAng, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(vAng, vAng);
		ScaleVector(vAng, 500.0);
		PrintToServer("L4D2_SpitterPrj %d",								L4D2_SpitterPrj(client, vPos, vAng));

		PrintToServer("L4D2_GetCurrentFinaleStage %d",					L4D2_GetCurrentFinaleStage()); // WORKING

		PrintToServer("L4D2_ForceNextStage %d",							L4D2_ForceNextStage()); // WORKING

		PrintToServer("L4D2_IsTankInPlay %d",							L4D2_IsTankInPlay()); // WORKING

		PrintToServer("L4D2_GetFurthestSurvivorFlow %f",				L4D2_GetFurthestSurvivorFlow()); // WORKING
	}
	// =========================
	// */





	// =========================
	// NATIVES - Animation
	// =========================
	/*
	float vPos[3];
	float vAng[3];

	if( client == 0 ) client = GetRandomClient();
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

		PrintToServer("L4D2_IsValidWeapon weapon_rifle: %d",									L4D2_IsValidWeapon("weapon_rifle"));
		PrintToServer("L4D2_IsValidWeapon weapon_autoshotgun: %d",								L4D2_IsValidWeapon("weapon_autoshotgun"));
		PrintToServer("L4D2_IsValidWeapon weapon_smg: %d",										L4D2_IsValidWeapon("weapon_smg"));
		PrintToServer("L4D2_IsValidWeaponF: %d",												L4D2_IsValidWeapon("smg")); // Changed to support this without "weapon_" required
		PrintToServer("");
		PrintToServer("");

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
		PrintToServer("L4D2_ChangeFinaleStage %d",					L4D2_ChangeFinaleStage(10, "test")); // WORKING
		PrintToServer("L4D2_ChangeFinaleStage %d",					L4D2_ChangeFinaleStage(8, "")); // WORKING
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

		PrintToServer("L4D_GetVersusMaxCompletionScore %d",			L4D_GetVersusMaxCompletionScore()); //WORKING
		L4D_SetVersusMaxCompletionScore(314); //WORKING
		PrintToServer("L4D_SetVersusMaxCompletionScore %d",			L4D_GetVersusMaxCompletionScore()); //WORKING
		PrintToServer("");
		PrintToServer("");
		PrintToServer("L4D_ScavengeBeginRoundSetupTime %f",			L4D_ScavengeBeginRoundSetupTime());
		PrintToServer("L4D_GetMobSpawnTimerRemaining %f",			L4D_GetMobSpawnTimerRemaining()); //SEEMS WORKING
		PrintToServer("L4D_GetMobSpawnTimerDuration %f",			L4D_GetMobSpawnTimerDuration()); //SEEMS WORKING
		PrintToServer("");
		PrintToServer("");
	}

	PrintToServer("L4D_NotifyNetworkStateChanged %d",				L4D_NotifyNetworkStateChanged()); //SEEMS WORKING, UNKNOWN

	PrintToServer("");
	PrintToServer("");
	// */

	//DEPRECIATED
	// L4D_GetCampaignScores
	// PrintToServer("L4D_LobbyUnreserve %d",					L4D_LobbyUnreserve()); // WORKING





	// =========================
	// NATIVES - L4D_Direct
	// =========================
	// Most seem to work, not all tested
	/*
	float vPos[3];

	if( g_bLeft4Dead2 )
	{
		PrintToServer("L4D_DIRECT TEST:");
		PrintToServer("Direct_GetTankCount %d",								L4D2Direct_GetTankCount()); // WORKING
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
		PrintToServer("Direct_GetNextShoveTime %f",							L4D2Direct_GetNextShoveTime(client)); // WORKING
		L4D2Direct_SetNextShoveTime(client, GetGameTime() + 5.0); // WORKING
		PrintToServer("Direct_SetNextShoveTime %f",							L4D2Direct_GetNextShoveTime(client)); // WORKING
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
	PrintToServer("Direct_GetMapMaxFlowDistance %f",						L4D2Direct_GetMapMaxFlowDistance()); // WORKING
	PrintToServer("Direct_GetInvulnerabilityTimer address %d",				L4D2Direct_GetInvulnerabilityTimer(client));
	PrintToServer("Direct_GetTankTickets %d",								L4D2Direct_GetTankTickets(client));
	L4D2Direct_SetTankTickets(client, 100);
	PrintToServer("Direct_SetTankTickets %d",								L4D2Direct_GetTankTickets(client));

	PrintToServer("Direct_GetTerrorNavArea %d",								L4D2Direct_GetTerrorNavArea(vPos)); // WORKING
	PrintToServer("Direct_GetTerrorNavAreaFlow %f",							L4D2Direct_GetTerrorNavAreaFlow(L4D2Direct_GetTerrorNavArea(vPos))); // WORKING
	PrintToServer("Direct_GetFlowDistance %f",								L4D2Direct_GetFlowDistance(client)); // WORKING
	PrintToServer("Direct_DoAnimationEvent",								L4D2Direct_DoAnimationEvent(client, 4)); // 4-6 = Reload. 8=Jump? 10=Death anim (loops).

	// PrintToServer("Direct_TryOfferingTankBot %d",						L4D2Direct_TryOfferingTankBot(client, false)); // WORKING



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
		PrintToServer("L4D_GetPlayerSpawnTime %f",							L4D_GetPlayerSpawnTime(client));// WORKING
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



	// PrintToServer("L4D_ReplaceTank %d",									L4D_ReplaceTank(tank, newtank)); // WORKING



	// Spawn
	vPos[1] += 30.0;
	PrintToServer("L4D2_SpawnSpecial %d",									L4D2_SpawnSpecial(3, vPos, vAng)); // WORKING

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

	PrintToServer("L4D2_SendInRescueVehicle %d",							L4D2_SendInRescueVehicle()); // WORKING
	// */





	// =========================
	// NATIVES - l4d2addresses.txt
	// =========================
	/*
	int targ = GetClientAimTarget(client, false);
	if( targ > 0 && targ <= MaxClients )
	{
		PrintToServer("L4D_CTerrorPlayer_OnVomitedUpon",						L4D_CTerrorPlayer_OnVomitedUpon(targ, client)); // WORKING
		PrintToServer("L4D_CTerrorPlayer_OnVomitedUpon",						L4D_CTerrorPlayer_OnVomitedUpon(client, client)); // WORKING
	}

	PrintToServer("L4D_CancelStagger",										L4D_CancelStagger(client)); // WORKING

	PrintToServer("L4D_CreateRescuableSurvivors",							L4D_CreateRescuableSurvivors()); // WORKING

	PrintToServer("L4D_ReviveSurvivor",										L4D_ReviveSurvivor(client)); // WORKING

	PrintToServer("L4D_GetHighestFlowSurvivor %d",							L4D_GetHighestFlowSurvivor()); // WORKING

	int infected = GetClientAimTarget(client, false);
	if( infected != -1 )
	{
		PrintToServer("L4D_GetInfectedFlowDistance %f",						L4D_GetInfectedFlowDistance(infected)); // WORKING
	}

	int bot = GetClientAimTarget(client, false);
	if( bot != -1 )
	PrintToServer("L4D_TakeOverZombieBot",									L4D_TakeOverZombieBot(client, bot)); // WORKING

	PrintToServer("L4D_ReplaceWithBot",										L4D_ReplaceWithBot(client)); // WORKING

	PrintToServer("L4D_CullZombie",											L4D_CullZombie(client)); // WORKING

	static int class = 1;
	class++;
	if( class > (g_bLeft4Dead2 ? 6 : 3) ) class = 1;
	PrintToServer("L4D_SetClass",											L4D_SetClass(client, class)); // WORKING

	PrintToServer("L4D_MaterializeFromGhost %d",							L4D_MaterializeFromGhost(client)); // WORKING

	PrintToServer("L4D_BecomeGhost %d",										L4D_BecomeGhost(client)); // WORKING

	PrintToServer("L4D_State_Transition",									L4D_State_Transition(client, 6)); // WORKING

	// Has no affect
	int car = GetClientAimTarget(client, false);
	PrintToServer("L4D_RegisterForbiddenTarget %d",							L4D_RegisterForbiddenTarget(car));
	PrintToServer("L4D_UnRegisterForbiddenTarget",							L4D_UnRegisterForbiddenTarget(car));



	if( g_bLeft4Dead2 )
	{
		if( targ > 0 && targ <= MaxClients )
		{
			PrintToServer("L4D2_CTerrorPlayer_OnHitByVomitJar",					L4D2_CTerrorPlayer_OnHitByVomitJar(targ, client)); // WORKING
		}

		if( targ > MaxClients )
		{
			PrintToServer("L4D2_Infected_OnHitByVomitJar",						L4D2_Infected_OnHitByVomitJar(targ, client)); // WORKING
		}

		PrintToServer("L4D2_CTerrorPlayer_Fling",							L4D2_CTerrorPlayer_Fling(client, client, view_as<float>({ 1.0, 0.0, 0.0 }))); // WORKING

		PrintToServer("L4D2_GetVersusCompletionPlayer %d",					L4D2_GetVersusCompletionPlayer(client)); // WORKING

		PrintToServer("L4D2_SwapTeams",										L4D2_SwapTeams()); // WORKING, some survivors may spawn dead.

		PrintToServer("L4D2_AreTeamsFlipped %d",							L4D2_AreTeamsFlipped()); // WORKING

		PrintToServer("L4D2_StartRematchVote",								L4D2_StartRematchVote()); // WORKING

		PrintToServer("L4D2_FullRestart",									L4D2_FullRestart()); // WORKING

		PrintToServer("L4D2_HideVersusScoreboard",							L4D2_HideVersusScoreboard()); // WORKING

		PrintToServer("L4D2_HideScavengeScoreboard",						L4D2_HideScavengeScoreboard()); // WORKING

		PrintToServer("L4D2_HideScoreboard",								L4D2_HideScoreboard()); // WORKING
	}
	// */

	return Plugin_Handled;
}



// ====================================================================================================
//										FORWAWRDS
// ====================================================================================================
public Action L4D_OnSpawnSpecial(int &zombieClass, const float vector[3], const float qangle[3])
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D_OnSpawnSpecial\" %d. (%f %f %f). (%f %f %f)", zombieClass, vector[0], vector[1], vector[2], qangle[0], qangle[1], qangle[2]);
	}

	// zombieClass = 1;
	// return Plugin_Changed; // WORKS

	// return Plugin_Handled; // WORKS
}

public Action L4D_OnSpawnTank(const float vector[3], const float qangle[3])
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D_OnSpawnTank\" (%f %f %f). (%f %f %f)", vector[0], vector[1], vector[2], qangle[0], qangle[1], qangle[2]);
	}
	// return Plugin_Handled; // WORKS
}

public Action L4D_OnSpawnWitch(const float vector[3], const float qangle[3])
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D_OnSpawnWitch\" (%f %f %f). (%f %f %f)", vector[0], vector[1], vector[2], qangle[0], qangle[1], qangle[2]);
	}
	// return Plugin_Handled; // WORKS
}

public Action L4D2_OnSpawnWitchBride(const float vector[3], const float qangle[3])
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D2_OnSpawnWitchBride\" (%f %f %f). (%f %f %f)", vector[0], vector[1], vector[2], qangle[0], qangle[1], qangle[2]);
	}
	// return Plugin_Handled; // WORKS
}

public Action L4D_OnMobRushStart()
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D_OnMobRushStart\"");
	}
	// return Plugin_Handled;
}

public Action L4D_OnSpawnITMob(int &amount)
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D_OnSpawnITMob\" %d", amount);
	}

	// WORKS
	// amount = 3;
	// return Plugin_Changed;

	// WORKS
	// return Plugin_Handled;
}

public Action L4D_OnSpawnMob(int &amount)
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D_OnSpawnMob\" %d", amount);
	}

	// WORKS
	// amount = 3;
	// return Plugin_Changed;

	// WORKS
	// return Plugin_Handled;
}

public Action L4D_OnEnterGhostStatePre(int client)
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D_OnEnterGhostStatePre\" %d", client);
	}

	// WORKS
	// return Plugin_Handled;
}

public void L4D_OnEnterGhostState(int client)
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D_OnEnterGhostState\" %d", client);
	}
}

public Action L4D_OnIsTeamFull(int team, bool &full)
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

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

	// return Plugin_Continue;
}

public Action L4D_OnClearTeamScores(bool newCampaign)
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D_OnClearTeamScores\" %d", newCampaign);
	}

	// WORKS
	// return Plugin_Handled;
}

public Action L4D_OnSetCampaignScores(int &scoreA, int &scoreB)
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D_OnSetCampaignScores\" %d. %d", scoreA, scoreB);
	}

	// WORKS
	// scoreA = 314;
	// scoreB = 123;
	// return Plugin_Changed;

	// WORKS
	// return Plugin_Handled;
}

public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D_OnFirstSurvivorLeftSafeArea\" %d", client);
	}

	// WORKS
	// return Plugin_Handled;
}

public Action L4D_OnGetCrouchTopSpeed(int target, float &retVal)
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D_OnGetCrouchTopSpeed\" %d. %f", target, retVal);
	}

	// WORKS
	// retVal = 500.0;
	// return Plugin_Handled;
}

public Action L4D_OnGetRunTopSpeed(int target, float &retVal)
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D_OnGetRunTopSpeed\" %d. %f", target, retVal);
	}

	// WORKS
	// retVal = 500.0;
	// return Plugin_Handled;
}

public Action L4D_OnGetWalkTopSpeed(int target, float &retVal)
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D_OnGetWalkTopSpeed\" %d. %f", target, retVal);
	}

	// WORKS
	// retVal = 500.0;
	// return Plugin_Handled;
}

public Action L4D_OnGetMissionVSBossSpawning(float &spawn_pos_min, float &spawn_pos_max, float &tank_chance, float &witch_chance)
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D_OnGetMissionVSBossSpawning\" %f. %f. %f. %f", spawn_pos_min, spawn_pos_max, tank_chance, witch_chance);
	}

	// WORKS
	// spawn_pos_min = 0.01;
	// spawn_pos_max = 0.05;
	// tank_chance = 1.0;
	// witch_chance = 1.0;
	// return Plugin_Changed;
}

public void L4D_OnReplaceTank(int tank, int newtank)
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D_OnReplaceTank\" %d %d", tank, newtank);
	}
}

public Action L4D_OnTryOfferingTankBot(int tank_index, bool &enterStasis)
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D_OnTryOfferingTankBot\" %d. %d", tank_index, enterStasis);
	}

	// WORKING
	// return Plugin_Handled;
}

public Action L4D_OnCThrowActivate(int ability)
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D_OnCThrowActivate\" %d", ability);
	}

	// WORKS
	// return Plugin_Handled;
}

public Action L4D2_OnSelectTankAttackPre(int client, int &sequence)
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D2_OnSelectTankAttack\" %d. %d", client, sequence);
	}

	// WORKS
	// sequence = 761;
	// return Plugin_Handled;
}

public Action L4D2_OnSelectTankAttack(int client, int &sequence)
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D2_OnSelectTankAttack\" %d. %d", client, sequence);
	}

	// WORKS
	// sequence = 48;
	// return Plugin_Handled;
}

public Action L4D2_OnSendInRescueVehicle()
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D2_OnSendInRescueVehicle\"");
	}

	// WORKS
	// return Plugin_Handled;
}

public Action L4D2_OnEndVersusModeRound(bool countSurvivors)
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D2_OnEndVersusModeRound\" %d", countSurvivors);
	}

	// WORKS
	// return Plugin_Handled;
}

public void L4D2_OnEndVersusModeRound_Post()
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D2_OnEndVersusModeRound_Post\"");
	}
}

public Action L4D_OnLedgeGrabbed(int client)
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D_OnLedgeGrabbed\" %d", client);
	}

	// WORKS
	// return Plugin_Handled;
}

public void L4D2_OnRevived(int client)
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D2_OnRevived\" %d", client);
	}
}

public Action L4D2_OnStagger(int target, int source)
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D2_OnStagger\" %d %d", target, source);
	}

	// WORKS
	// return Plugin_Handled;
}

public Action L4D_OnShovedBySurvivor(int client, int victim, const float vector[3])
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D_OnShovedBySurvivor\" %d %d. (%f %f %f)", client, victim, vector[0], vector[1], vector[2]);
	}

	// WORKS
	// return Plugin_Handled;
}

public Action L4D2_OnEntityShoved(int client, int entity, int weapon, float vector[3], bool bIsHighPounce)
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D2_OnEntityShoved\" %d %d %d (%f %f %f) IsHighPounce=%d", client, entity, weapon, vector[0], vector[1], vector[2], bIsHighPounce);
	}

	// WORKS
	// return Plugin_Handled;
}

public Action L4D2_OnPounceOrLeapStumble(int victim, int attacker)
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D2_OnPounceOrLeapStumble\" %d %d", victim, attacker);
	}

	// WORKS
	// return Plugin_Handled;
}

public Action L4D2_OnSpitSpread(int spitter, int projectile, float &x, float &y, float &z)
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D2_OnSpitSpread\" %d %d (%f %f %f)", spitter, projectile, x, y, z);
	}

	// Doesn't work
	// x /= 4.0;
	// y /= 4.0;
	// z /= 4.0;
	// return Plugin_Changed;

	// WORKS
	// return Plugin_Handled;
}

public Action L4D2_OnUseHealingItems(int client)
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D2_OnUseHealingItems\" %d", client);
	}

	// WORKS
	// return Plugin_Handled;
}

public Action L4D2_OnFindScavengeItem(int client, int &item)
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D2_OnFindScavengeItem\" %d %d", client, item);
	}

	// WORKS
	// if( item == -1 )
	// {
		// item = 440;
		// return Plugin_Changed;
	// }

	// WORKS
	// return Plugin_Handled;
}

public Action L4D_OnVomitedUpon(int victim, int &attacker, bool &boomerExplosion)
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D_OnVomitedUpon\" %d > %d (%d)", victim, attacker, boomerExplosion);
	}

	// attacker = victim;
	// return Plugin_Changed;

	// return Plugin_Handled;
}

public Action L4D2_OnHitByVomitJar(int victim, int &attacker)
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D2_OnHitByVomitJar\" %d > %d)", victim, attacker);
	}

	// attacker = victim;
	// return Plugin_Changed;

	// WORKS
	// return Plugin_Handled;
}

public Action L4D_OnMaterializeFromGhostPre(int client)
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D_OnMaterializeFromGhostPre\" %d > %d)", client);
	}

	// WORKS
	// return Plugin_Handled;
}

public Action L4D_OnMaterializeFromGhost(int client)
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D_OnMaterializeFromGhost\" %d > %d)", client);
	}
}

public Action L4D2_OnChooseVictim(int specialInfected, int &curTarget)
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D2_OnChooseVictim\" %d > %d", specialInfected, curTarget);
	}

	// WORKS
	// curTarget = 2; // Must be valid client index, 0 = crash.
	// return Plugin_Changed;

	// ATTACK THEMSELVES (no target) - the special will stand still.
	// return Plugin_Handled;
}

public Action L4D_OnGetScriptValueInt(const char[] key, int &retVal)
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D_OnGetScriptValueInt\" %s. %d", key, retVal);
	}

	// WORKS - map: c4_m*
	// if( strcmp(key, "GasCansOnBacks") == 0 )
	// {
		// retVal = 1;
		// return Plugin_Handled;
	// }
	// return Plugin_Continue;
}

public Action L4D_OnGetScriptValueFloat(const char[] key, float &retVal)
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D_OnGetScriptValueFloat\" %s. %f", key, retVal);
	}

	// if( strcmp(key, "TempHealthDecayRate") == 0 )
		// PrintToServer("FWD L4D_OnGetScriptValueFloat %s. %f", key, retVal);

	// WORKS
	// if( strcmp(key, "TempHealthDecayRate") == 0 )
	// {
		// retVal = 2.0;
		// return Plugin_Handled;
	// }
	// return Plugin_Continue;
}

public Action L4D_OnGetScriptValueString(const char[] key, const char[] defaultVal, char retVal[128])
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		// ForwardCalled("\"L4D_OnGetScriptValueString\" [%s]. [%s]. [%s].", key, defaultVal, retVal); // Because printing random chars can break console printing text or possibly cause a crash?
		ForwardCalled("\"L4D_OnGetScriptValueString\"");
	}

	// UNKNOWN - MUSIC STRINGS ARE ALWAYS RANDOM CHARS, THIS SEEMS TO BE NORMAL, LOOK AT USERMSG HOOKS ETC.
	// PrintToServer("\"L4D_OnGetScriptValueString\" [%s]. [%s]. [%s].", key, defaultVal, retVal);
	// if( strcmp(key, "OnChangeFinaleMusic") == 0 )
	// {
		// retVal = "";
		// return Plugin_Handled;
	// }
}

public Action L4D_OnHasConfigurableDifficulty(int &retVal)
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D_OnHasConfigurableDifficulty\" %d", retVal);
	}

	// WORKS
	// retVal = 0;
	// return Plugin_Handled;
}

public Action L4D_OnGetSurvivorSet(int &retVal)
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D_OnGetSurvivorSet\" %d", retVal);
	}

	// WORKS
	// retVal = 1;
	// return Plugin_Handled;
}

public Action L4D_OnFastGetSurvivorSet(int &retVal)
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D_OnFastGetSurvivorSet\" %d", retVal);
	}

	// WORKS
	// retVal = 1;
	// return Plugin_Handled;
}

public Action L4D_OnStartMeleeSwing(int client, bool boolean)
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D_OnStartMeleeSwing\" %d. %d", client, boolean);
	}

	// WORKS - PREDICTION ISSUES - Hear and partially see swing in first person
	// return Plugin_Handled;
}

public Action L4D2_OnChangeFinaleStage(int &finaleType, const char[] arg)
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D2_OnChangeFinaleStage\" %d. %s", finaleType, arg);
	}

	// WORKS
	// finaleType = 8;
	// return Plugin_Changed;

	// WORKS
	// return Plugin_Handled;
}

public Action L4D2_OnClientDisableAddons(const char[] SteamID)
{
	PrintToServer("#### FWD L4D2_OnClientDisableAddons %s", SteamID);

	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D2_OnClientDisableAddons\" %s", SteamID);
	}

	// Requires l4d2_addons_eclipse 1 to be used.
	// return Plugin_Continue; // Block addons.
	// return Plugin_Handled; // Allow addons.
}

/*
// Can trigger with: "z_spawn_old hunter auto" in console.
// BROKEN, SPAWNS SPECIALS AT 0,0,0 WHEN MODIFYING VALUES
public Action L4D_OnGetRandomPZSpawnPosition(int &client, int &zombieClass, int &attempts, float vecPos[3])
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

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
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D_OnInfectedShoved\" %d. %d", infected, entity);
	}
}

public void L4D2_OnWaterMove(int client)
{
	static int called;
	if( called < MAX_CALLS )
	{
		called++;
		g_iForwards++;

		ForwardCalled("\"L4D2_OnWaterMove\" %d", client);
	}
}
// */





void ForwardCalled(const char[] format, any ...)
{
	if( g_bTestForwards == false ) return;

	char buffer[512];
	VFormat(buffer, sizeof(buffer), format, 2);

	PrintToServer("----------");
	PrintToServer("Forward %d/%d called %s", g_iForwards, g_iForwardsMax, buffer);
	PrintToServer("----------");
}

stock int GetRandomClient()
{
	int client;
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 2 && IsFakeClient(i) == false )
		{
			client = i;
			break;
		}
	}

	if( !client )
	{
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) && GetClientTeam(i) == 2 )
			{
				client = i;
				break;
			}
		}
	}

	if( !client )
	{
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) )
			{
				client = i;
				break;
			}
		}
	}

	return client;
}

stock int GetAnyRandomClient()
{
	int client;
	ArrayList aClients = new ArrayList();

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) )
		{
			aClients.Push(i);
		}
	}

	if( aClients.Length > 0 )
		client = aClients.Get(GetRandomInt(0, aClients.Length - 1));

	delete aClients;

	return client;
}

stock int GetAnyRandomBot()
{
	int client;
	ArrayList aClients = new ArrayList();

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 2 )
		{
			aClients.Push(i);
		}
	}

	if( aClients.Length > 0 )
		client = aClients.Get(GetRandomInt(0, aClients.Length - 1));

	delete aClients;

	return client;
}