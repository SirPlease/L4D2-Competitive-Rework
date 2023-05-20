/*
*	Left 4 DHooks Direct
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



// Prevent compiling if not compiled from "left4dhooks.sp"
#if !defined COMPILE_FROM_MAIN
 #error This file must be inside "scripting/l4dd/" while compiling "left4dhooks.sp" to include its content.
#endif



#pragma semicolon 1
#pragma newdecls required



// NATIVES - SDKCall
// Silvers Natives
Handle g_hSDK_CTerrorGameRules_HasConfigurableDifficultySetting;
Handle g_hSDK_CTerrorGameRules_IsGenericCooperativeMode;
Handle g_hSDK_CTerrorGameRules_IsRealismMode;
Handle g_hSDK_NavAreaTravelDistance;
Handle g_hSDK_CTerrorPlayer_GetLastKnownArea;
Handle g_hSDK_Music_Play;
Handle g_hSDK_Music_StopPlaying;
Handle g_hSDK_CTerrorPlayer_Deafen;
Handle g_hSDK_CEntityDissolve_Create;
Handle g_hSDK_CTerrorPlayer_OnITExpired;
Handle g_hSDK_CTerrorPlayer_EstimateFallingDamage;
Handle g_hSDK_CBaseEntity_WorldSpaceCenter;
Handle g_hSDK_CBaseEntity_ApplyLocalAngularVelocityImpulse;
Handle g_hSDK_SurvivorBot_IsReachable;
Handle g_hSDK_CTerrorGameRules_HasPlayerControlledZombies;
Handle g_hSDK_CTerrorGameRules_GetSurvivorSet;
Handle g_hSDK_CBaseGrenade_Detonate;
// Handle g_hSDK_CInferno_StartBurning;
Handle g_hSDK_CPipeBombProjectile_Create;
Handle g_hSDK_CMolotovProjectile_Create;
Handle g_hSDK_CVomitJarProjectile_Create;
Handle g_hSDK_CGrenadeLauncher_Projectile_Create;
Handle g_hSDK_CSpitterProjectile_Create;
Handle g_hSDK_CTerrorPlayer_OnAdrenalineUsed;
Handle g_hSDK_CTerrorPlayer_RoundRespawn;
Handle g_hSDK_SurvivorBot_SetHumanSpectator;
Handle g_hSDK_CTerrorPlayer_TakeOverBot;
Handle g_hSDK_CTerrorPlayer_CanBecomeGhost;
Handle g_hSDK_CTerrorPlayer_SetBecomeGhostAt;
Handle g_hSDK_CTerrorPlayer_GoAwayFromKeyboard;
Handle g_hSDK_CDirector_AreWanderersAllowed;
Handle g_hSDK_CDirector_IsFinaleEscapeInProgress;
Handle g_hSDK_CDirector_ForceNextStage;
Handle g_hSDK_ForceVersusStart;
Handle g_hSDK_ForceSurvivalStart;
Handle g_hSDK_ForceScavengeStart;
Handle g_hSDK_CDirector_IsTankInPlay;
Handle g_hSDK_CDirector_GetFurthestSurvivorFlow;
Handle g_hSDK_CDirector_GetScriptValueInt;
Handle g_hSDK_CDirector_GetScriptValueFloat;
// Handle g_hSDK_CDirector_GetScriptValueString;
Handle g_hSDK_ZombieManager_GetRandomPZSpawnPosition;
Handle g_hSDK_NavAreaBuildPath_ShortestPathCost;
Handle g_hSDK_CNavMesh_GetNearestNavArea;
Handle g_hSDK_TerrorNavArea_FindRandomSpot;
Handle g_hSDK_CTerrorPlayer_WarpToValidPositionIfStuck;
Handle g_hSDK_IsVisibleToPlayer;
Handle g_hSDK_CDirector_HasAnySurvivorLeftSafeArea;
// Handle g_hSDK_CDirector_IsAnySurvivorInExitCheckpoint;
Handle g_hSDK_CDirector_AreAllSurvivorsInFinaleArea;
Handle g_hSDK_TerrorNavMesh_GetInitialCheckpoint;
Handle g_hSDK_TerrorNavMesh_GetLastCheckpoint;
Handle g_hSDK_TerrorNavMesh_IsInInitialCheckpoint_NoLandmark;
Handle g_hSDK_TerrorNavMesh_IsInExitCheckpoint_NoLandmark;
Handle g_hSDK_Checkpoint_ContainsArea;
// Handle g_hSDK_CDirector_IsAnySurvivorInStartArea;
Handle g_hSDK_CTerrorGameRules_GetNumChaptersForMissionAndMode;
Handle g_hSDK_CDirector_GetGameModeBase;
Handle g_hSDK_KeyValues_GetString;

// left4downtown.inc
Handle g_hSDK_CTerrorGameRules_GetTeamScore;
Handle g_hSDK_CDirector_RestartScenarioFromVote;
Handle g_hSDK_CDirector_IsFirstMapInScenario;
Handle g_hSDK_CTerrorGameRules_IsMissionFinalMap;
Handle g_hSDK_CDirector_ResetMobTimer;
Handle g_hSDK_CGameRulesProxy_NotifyNetworkStateChanged;
Handle g_hSDK_CTerrorPlayer_OnStaggered;
Handle g_hSDK_ZombieManager_ReplaceTank;
Handle g_hSDK_CDirectorScriptedEventManager_SendInRescueVehicle;
Handle g_hSDK_CDirectorScriptedEventManager_ChangeFinaleStage;
Handle g_hSDK_ZombieManager_SpawnSpecial;
Handle g_hSDK_ZombieManager_SpawnHunter;
Handle g_hSDK_ZombieManager_SpawnBoomer;
Handle g_hSDK_ZombieManager_SpawnSmoker;
Handle g_hSDK_ZombieManager_SpawnTank;
Handle g_hSDK_ZombieManager_SpawnWitch;
Handle g_hSDK_ZombieManager_SpawnWitchBride;
Handle g_hSDK_GetWeaponInfo;
Handle g_hSDK_CMeleeWeaponInfoStore_GetMeleeWeaponInfo;
Handle g_hSDK_CTerrorGameRules_GetMissionInfo;
Handle g_hSDK_CDirector_TryOfferingTankBot;
Handle g_hSDK_CNavMesh_GetNavArea;
Handle g_hSDK_CTerrorPlayer_GetFlowDistance;
Handle g_hSDK_CTerrorPlayer_SetShovePenalty;
// Handle g_hSDK_CTerrorPlayer_SetNextShoveTime;
Handle g_hSDK_CTerrorPlayer_DoAnimationEvent;
Handle g_hSDK_CTerrorGameRules_RecomputeTeamScores;
Handle g_hSDK_CBaseServer_SetReservationCookie;
// Handle g_hSDK_GetCampaignScores;
// Handle g_hSDK_LobbyIsReserved;

// l4d2addresses.txt
Handle g_hSDK_CTerrorPlayer_OnVomitedUpon;
Handle g_hSDK_CTerrorPlayer_OnHitByVomitJar;
Handle g_hSDK_Infected_OnHitByVomitJar;
Handle g_hSDK_CTerrorPlayer_Fling;
Handle g_hSDK_CTerrorPlayer_CancelStagger;
Handle g_hSDK_ThrowImpactedSurvivor;
Handle g_hSDK_CTerrorPlayer_OnStartCarryingVictim;
Handle g_hSDK_CTerrorPlayer_QueuePummelVictim;
Handle g_hSDK_CTerrorPlayer_OnPummelEnded;
Handle g_hSDK_CTerrorPlayer_OnRideEnded;
Handle g_hSDK_CDirector_CreateRescuableSurvivors;
Handle g_hSDK_CTerrorPlayer_OnRevived;
Handle g_hSDK_CTerrorGameRules_GetVersusCompletion;
Handle g_hSDK_CDirectorTacticalServices_GetHighestFlowSurvivor;
Handle g_hSDK_Infected_GetFlowDistance;
Handle g_hSDK_CTerrorPlayer_TakeOverZombieBot;
Handle g_hSDK_CTerrorPlayer_ReplaceWithBot;
Handle g_hSDK_CTerrorPlayer_CullZombie;
Handle g_hSDK_CTerrorPlayer_CleanupPlayerState;
Handle g_hSDK_CTerrorPlayer_SetClass;
Handle g_hSDK_CBaseAbility_CreateForPlayer;
Handle g_hSDK_CTerrorPlayer_MaterializeFromGhost;
Handle g_hSDK_CTerrorPlayer_BecomeGhost;
Handle g_hSDK_CCSPlayer_State_Transition;
Handle g_hSDK_CDirector_SwapTeams;
// Handle g_hSDK_CDirector_AreTeamsFlipped;
Handle g_hSDK_CDirector_StartRematchVote;
Handle g_hSDK_CDirector_FullRestart;
Handle g_hSDK_CDirectorVersusMode_HideScoreboardNonVirtual;
Handle g_hSDK_CDirectorScavengeMode_HideScoreboardNonVirtual;
Handle g_hSDK_CDirector_HideScoreboard;
Handle g_hSDK_CDirector_RegisterForbiddenTarget;
Handle g_hSDK_CDirector_UnregisterForbiddenTarget;





// ====================================================================================================
//										NATIVES
// ====================================================================================================
void ValidateAddress(any addr, const char[] name, bool check = false)
{
	if( addr == Address_Null )
	{
		if( check )		LogError("Failed to find \"%s\" address (%s).", name, g_sSystem);
		else			ThrowNativeError(SP_ERROR_INVALID_ADDRESS, "%s not available (%s).", name, g_sSystem);
	}
}

void ValidateNatives(Handle test, const char[] name)
{
	if( test == null )
	{
		ThrowNativeError(SP_ERROR_INVALID_ADDRESS, "%s not available (%s).", name, g_sSystem);
	}
}

void ValidateOffset(int test, const char[] name, bool check = true)
{
	if( test == -1 )
	{
		if( check )		LogError("Failed to find \"%s\" offset (%s).", name, g_sSystem);
		else			ThrowNativeError(SP_ERROR_INVALID_ADDRESS, "%s not available (%s).", name, g_sSystem);
	}
}



// ====================================================================================================
//										SILVERS NATIVES
// ====================================================================================================
any Native_GetPointer(Handle plugin, int numParams) // Native "L4D_GetPointer"
{
	PointerType ptr_type = GetNativeCell(1);

	switch( ptr_type )
	{
		case POINTER_DIRECTOR:			return g_pDirector;
		case POINTER_SERVER:			return g_pServer;
		case POINTER_GAMERULES:			return g_pGameRules;
		case POINTER_NAVMESH:			return g_pNavMesh;
		case POINTER_ZOMBIEMANAGER:		return g_pZombieManager;
		case POINTER_WEAPONINFO:		return g_pWeaponInfoDatabase;
		case POINTER_MELEEINFO:			return g_pMeleeWeaponInfoStore;
		case POINTER_EVENTMANAGER:		return g_pScriptedEventManager;
		case POINTER_SCAVENGEMODE:		return g_pScavengeMode;
		case POINTER_VERSUSMODE:		return g_pVersusMode;
		case POINTER_SCRIPTVM:			return g_pScriptVM;
		case POINTER_THENAVAREAS:		return g_pTheNavAreas;
	}

	return 0;
}

int Native_GetClientFromAddress(Handle plugin, int numParams) // Native "L4D_GetClientFromAddress"
{
	return GetClientFromAddress(GetNativeCell(1));
}

int Native_GetEntityFromAddress(Handle plugin, int numParams) // Native "L4D_GetEntityFromAddress"
{
	return GetEntityFromAddress(GetNativeCell(1));
}

int Native_ReadMemoryString(Handle plugin, int numParams) // Native "L4D_ReadMemoryString"
{
	int addy = GetNativeCell(1);
	int maxlength = GetNativeCell(3);
	char[] buffer = new char[maxlength];

	ReadMemoryString(view_as<Address>(addy), buffer, maxlength);

	SetNativeString(2, buffer, maxlength);

	return 0;
}

int Native_GetServerOS(Handle plugin, int numParams) // Native "L4D_GetServerOS"
{
	return g_bLinuxOS;
}

int Native_Left4DHooks_Version(Handle plugin, int numParams) // Native "Left4DHooks_Version"
{
	return PLUGIN_VERLONG;
}



// ==================================================
// MEMORY HELPERS
// ==================================================
int GetEntityFromAddress(int addr)
{
	int max = GetEntityCount();
	for( int i = 0; i <= max; i++ )
		if( IsValidEdict(i) )
			if( GetEntityAddress(i) == view_as<Address>(addr) )
				return i;
	return -1;
}

int GetClientFromAddress(int addr)
{
	for(int i = 1; i <= MaxClients; i++ )
		if( IsClientInGame(i) )
			if( GetEntityAddress(i) == view_as<Address>(addr) )
				return i;
	return 0;
}

void ReadMemoryString(Address addr, char[] buffer, int size)
{
	int max = size - 1;

	int i = 0;
	for( ; i < max; i++ )
		if( (buffer[i] = view_as<char>(LoadFromAddress(addr + view_as<Address>(i), NumberType_Int8))) == '\0' )
			return;

	buffer[i] = '\0';
}

void ReverseAddress(const char[] sBytes, char sReturn[32])
{
	sReturn[0] = 0;
	char sByte[3];
	for( int i = strlen(sBytes) - 2; i >= -1 ; i -= 2 )
	{
		strcopy(sByte, i >= 1 ? 3 : i + 3, sBytes[i >= 0 ? i : 0]);

		StrCat(sReturn, sizeof(sReturn), "\\x");
		if( strlen(sByte) == 1 )
			StrCat(sReturn, sizeof(sReturn), "0");
		StrCat(sReturn, sizeof(sReturn), sByte);
	}
}



// ==================================================
// VSCRIPT WRAPPERS
// ==================================================
int Native_VS_GetMapNumber(Handle plugin, int numParams) // Native "L4D2_VScriptWrapper_GetMapNumber"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	// Vars
	char code[256];
	char buffer[8];

	// Code
	FormatEx(code, sizeof(code), "ret <- Director.GetMapNumber(); <RETURN>ret</RETURN>");

	// Exec
	if( GetVScriptOutput(code, buffer, sizeof(buffer)) )
		return StringToInt(buffer);
	else
		return 0;
}

int Native_VS_HasEverBeenInjured(Handle plugin, int numParams) // Native "L4D2_VScriptWrapper_HasEverBeenInjured"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	// Vars
	char code[256];
	char buffer[8];

	int client = GetNativeCell(1);
	client = GetClientUserId(client);
	int team = GetNativeCell(2);

	// Code
	FormatEx(code, sizeof(code), "ret <- GetPlayerFromUserID(%d).HasEverBeenInjured(%d); <RETURN>ret</RETURN>", client, team);

	// Exec
	if( GetVScriptOutput(code, buffer, sizeof(buffer)) )
		return view_as<bool>(StringToInt(buffer));
	else
		return false;
}

any Native_VS_GetAliveDuration(Handle plugin, int numParams) // Native "L4D2_VScriptWrapper_GetAliveDuration"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	// Vars
	char code[256];
	char buffer[8];

	int client = GetNativeCell(1);
	client = GetClientUserId(client);

	// Code
	FormatEx(code, sizeof(code), "ret <- GetPlayerFromUserID(%d).GetAliveDuration(); <RETURN>ret</RETURN>", client);

	// Exec
	if( GetVScriptOutput(code, buffer, sizeof(buffer)) )
		return StringToFloat(buffer);
	else
		return 0.0;
}

int Native_VS_IsDead(Handle plugin, int numParams) // Native "L4D2_VScriptWrapper_IsDead"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	// Vars
	char code[256];
	char buffer[8];

	int client = GetNativeCell(1);
	client = GetClientUserId(client);

	// Code
	FormatEx(code, sizeof(code), "ret <- GetPlayerFromUserID(%d).IsDead(); <RETURN>ret</RETURN>", client);

	// Exec
	if( GetVScriptOutput(code, buffer, sizeof(buffer)) )
		return view_as<bool>(StringToInt(buffer));
	else
		return false;
}

int Native_VS_IsDying(Handle plugin, int numParams) // Native "L4D2_VScriptWrapper_IsDying"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	// Vars
	char code[256];
	char buffer[8];

	int client = GetNativeCell(1);
	client = GetClientUserId(client);

	// Code
	FormatEx(code, sizeof(code), "ret <- GetPlayerFromUserID(%d).IsDying(); <RETURN>ret</RETURN>", client);

	// Exec
	if( GetVScriptOutput(code, buffer, sizeof(buffer)) )
		return view_as<bool>(StringToInt(buffer));
	else
		return false;
}

int Native_VS_UseAdrenaline(Handle plugin, int numParams) // Native "L4D2_VScriptWrapper_UseAdrenaline"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	// Vars
	char code[256];

	int client = GetNativeCell(1);
	client = GetClientUserId(client);
	float fTime = GetNativeCell(2);

	// Code
	FormatEx(code, sizeof(code), "GetPlayerFromUserID(%d).UseAdrenaline(%f);", client, fTime);

	// Exec
	return ExecVScriptCode(code);
}

int Native_VS_ReviveByDefib(Handle plugin, int numParams) // Native "L4D2_VScriptWrapper_ReviveByDefib"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	// Vars
	char code[256];

	int client = GetNativeCell(1);
	client = GetClientUserId(client);

	// Code
	FormatEx(code, sizeof(code), "GetPlayerFromUserID(%d).ReviveByDefib();", client);

	// Exec
	return ExecVScriptCode(code);
}

int Native_VS_ReviveFromIncap(Handle plugin, int numParams) // Native "L4D2_VScriptWrapper_ReviveFromIncap"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	// Vars
	char code[256];

	int client = GetNativeCell(1);
	client = GetClientUserId(client);

	// Code
	FormatEx(code, sizeof(code), "GetPlayerFromUserID(%d).ReviveFromIncap();", client);

	// Exec
	return ExecVScriptCode(code);
}

int Native_VS_GetSenseFlags(Handle plugin, int numParams) // Native "L4D2_VScriptWrapper_GetSenseFlags"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	// Vars
	char code[256];
	char buffer[8];

	int client = GetNativeCell(1);
	client = GetClientUserId(client);

	// Code
	FormatEx(code, sizeof(code), "ret <- GetPlayerFromUserID(%d).GetSenseFlags(); <RETURN>ret</RETURN>", client);

	// Exec
	if( GetVScriptOutput(code, buffer, sizeof(buffer)) )
		return StringToInt(buffer);
	else
		return 0;
}

int Native_VS_NavAreaBuildPath(Handle plugin, int numParams) // Native "L4D2_VScriptWrapper_NavAreaBuildPath"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	// Vars
	char code[512];
	char buffer[8];
	float vPos[3];
	float vEnd[3];

	// Params
	GetNativeArray(1, vPos, sizeof(vPos));
	GetNativeArray(2, vEnd, sizeof(vEnd));
	float flMaxPathLength = GetNativeCell(3);
	bool checkLOS = GetNativeCell(4);
	bool checkGround = GetNativeCell(5);
	int teamID = GetNativeCell(6);
	bool ignoreNavBlockers = GetNativeCell(7);

	// Code
	FormatEx(code, sizeof(code), "\
	a1 <- NavMesh.GetNearestNavArea(Vector(%f, %f, %f), %f, %s, %s);\
	a2 <- NavMesh.GetNearestNavArea(Vector(%f, %f, %f), %f, %s, %s);\
	a3 <- NavMesh.NavAreaBuildPath(a1, a2, Vector(%f, %f, %f), %f, %d, %s);\
	<RETURN>a3</RETURN>",
	vPos[0], vPos[1], vPos[2], flMaxPathLength, checkLOS ? "true" : "false", checkGround ? "true" : "false",
	vEnd[0], vEnd[1], vEnd[2], flMaxPathLength, checkLOS ? "true" : "false", checkGround ? "true" : "false",
	vEnd[0], vEnd[1], vEnd[2], flMaxPathLength, teamID, ignoreNavBlockers ? "true" : "false"
	);

	// Exec
	if( GetVScriptOutput(code, buffer, sizeof(buffer)) )
		return view_as<bool>(StringToInt(buffer));
	else
		return false;
}

any Native_VS_NavAreaTravelDistance(Handle plugin, int numParams) // Native "L4D2_VScriptWrapper_NavAreaTravelDistance"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	// Vars
	char code[512];
	char buffer[8];
	float vPos[3];
	float vEnd[3];

	// Params
	GetNativeArray(1, vPos, sizeof(vPos));
	GetNativeArray(2, vEnd, sizeof(vEnd));
	float flMaxPathLength = GetNativeCell(3);
	bool checkLOS = GetNativeCell(4);
	bool checkGround = GetNativeCell(5);

	// Code
	FormatEx(code, sizeof(code), "\
	a1 <- NavMesh.GetNearestNavArea(Vector(%f, %f, %f), %f, %s, %s);\
	a2 <- NavMesh.GetNearestNavArea(Vector(%f, %f, %f), %f, %s, %s);\
	a3 <- NavMesh.NavAreaTravelDistance(a1, a2, %f);\
	<RETURN>a3</RETURN>",
	vPos[0], vPos[1], vPos[2], flMaxPathLength, checkLOS ? "true" : "false", checkGround ? "true" : "false",
	vEnd[0], vEnd[1], vEnd[2], flMaxPathLength, checkLOS ? "true" : "false", checkGround ? "true" : "false",
	vEnd[0], vEnd[1], vEnd[2], flMaxPathLength
	);

	// Exec
	if( GetVScriptOutput(code, buffer, sizeof(buffer)) )
		return StringToFloat(buffer);
	else
		return -1.0;
}



// ==================================================
// VSCRIPT NATIVES
// ==================================================
int g_iLogicScript;

int Native_GetScriptScope(Handle plugin, int numParams) // Native "L4D2_GetScriptScope"
{
	int entity = GetNativeCell(1);

	Address pEntity = GetEntityAddress(entity);
	int m_iszScriptId = LoadFromAddress(pEntity + g_pScriptId, NumberType_Int32);
	if( m_iszScriptId == -1 ) m_iszScriptId = 0;

	return m_iszScriptId;
}

int Native_GetVScriptEntity(Handle plugin, int numParams) // Native "L4D2_GetVScriptEntity"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	bool success = GetVScriptEntity();
	if( !success ) return 0;

	return EntRefToEntIndex(g_iLogicScript);
}

int Native_ExecVScriptCode(Handle plugin, int numParams) // Native "L4D2_ExecVScriptCode"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	int maxlength;
	GetNativeStringLength(1, maxlength);
	maxlength += 1;
	char[] code = new char[maxlength];
	GetNativeString(1, code, maxlength);

	bool success = ExecVScriptCode(code);

	return success;
}

int Native_GetVScriptOutput(Handle plugin, int numParams) // Native "L4D2_GetVScriptOutput"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	int maxlength;
	GetNativeStringLength(1, maxlength);
	maxlength += 1;
	char[] code = new char[maxlength];
	GetNativeString(1, code, maxlength);

	maxlength = GetNativeCell(3);
	char[] buffer = new char[maxlength];

	bool success = GetVScriptOutput(code, buffer, maxlength);
	if( success ) SetNativeString(2, buffer, maxlength);

	return success;
}



// ==================================================
// VSCRIPT - ENTITY / EXEC / OUTPUT
// ==================================================
bool GetVScriptEntity()
{
	if( !g_bMapStarted ) return false;

	if( !g_iLogicScript || EntRefToEntIndex(g_iLogicScript) == INVALID_ENT_REFERENCE )
	{
		g_iLogicScript = CreateEntityByName("logic_script");

		if( g_iLogicScript == INVALID_ENT_REFERENCE || !IsValidEntity(g_iLogicScript) )
		{
			LogError("Could not create 'logic_script'");
			return false;
		}

		DispatchSpawn(g_iLogicScript);

		g_iLogicScript = EntIndexToEntRef(g_iLogicScript);
	}

	return true;
}

bool ExecVScriptCode(char[] code)
{
	if( !GetVScriptEntity() ) return false;

	// Run code
	SetVariantString(code);
	AcceptEntityInput(g_iLogicScript, "RunScriptCode");

	#if defined KILL_VSCRIPT
	#if KILL_VSCRIPT
	RemoveEntity(g_iLogicScript);
	#endif
	#endif

	return true;
}

bool GetVScriptOutput(char[] code, char[] ret, int maxlength)
{
	if( !GetVScriptEntity() ) return false;

	// Return values between <RETURN> </RETURN>
	int length = strlen(code) + 256;
	char[] buffer = new char[length];

	int pos = StrContains(code, "<RETURN>");
	if( pos != -1 )
	{
		strcopy(buffer, length, code);
		ReplaceString(buffer, length, "</RETURN>", ");");
		ReplaceString(buffer, length, "<RETURN>", "Convars.SetValue(\"l4d2_vscript_return\", ");
	}
	else
	{
		FormatEx(buffer, length, "Convars.SetValue(\"l4d2_vscript_return\", \"\" + %s + \"\");", code);
	}

	// Run code
	SetVariantString(buffer);
	AcceptEntityInput(g_iLogicScript, "RunScriptCode");

	#if defined KILL_VSCRIPT
	#if KILL_VSCRIPT
	RemoveEntity(g_iLogicScript);
	#endif
	#endif

	// Retrieve value and return to buffer
	g_hCvar_VScriptBuffer.GetString(ret, maxlength);
	g_hCvar_VScriptBuffer.SetString("");

	if( ret[0] == '\x0')
		return false;
	return true;
}



// ==================================================
// VARIOUS NATIVES
// ==================================================
int Native_CTerrorGameRules_HasConfigurableDifficultySetting(Handle plugin, int numParams) // Native "L4D2_HasConfigurableDifficultySetting"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateNatives(g_hSDK_CTerrorGameRules_HasConfigurableDifficultySetting, "CTerrorGameRules::HasConfigurableDifficultySetting");

	//PrintToServer("#### CALL g_hSDK_CTerrorGameRules_HasConfigurableDifficultySetting");
	return SDKCall(g_hSDK_CTerrorGameRules_HasConfigurableDifficultySetting, g_pGameRules);
}

int Native_CTerrorGameRules_GetSurvivorSetMap(Handle plugin, int numParams) // Native "L4D2_GetSurvivorSetMap"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateNatives(g_hSDK_KeyValues_GetString, "KeyValues::GetString");
	ValidateNatives(g_hSDK_CTerrorGameRules_GetMissionInfo, "CTerrorGameRules::GetMissionInfo");

	char sTemp[8];
	//PrintToServer("#### CALL g_hSDK_CTerrorGameRules_GetMissionInfo");
	int infoPointer = SDKCall(g_hSDK_CTerrorGameRules_GetMissionInfo);
	ValidateAddress(infoPointer, "CTerrorGameRules::GetMissionInfo");

	//PrintToServer("#### CALL g_hSDK_KeyValues_GetString");
	SDKCall(g_hSDK_KeyValues_GetString, infoPointer, sTemp, sizeof(sTemp), "survivor_set", "2"); // Default set = 2

	return StringToInt(sTemp);
}

int Native_CTerrorGameRules_GetSurvivorSetMod(Handle plugin, int numParams) // Native "L4D2_GetSurvivorSetMod"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	//PrintToServer("#### CALL g_hSDK_CTerrorGameRules_GetSurvivorSet");
	return SDKCall(g_hSDK_CTerrorGameRules_GetSurvivorSet);
}

any Native_Internal_GetTempHealth(Handle plugin, int numParams) // Native "L4D_GetTempHealth"
{
	int client = GetNativeCell(1);
	return GetTempHealth(client);
}

int Native_Internal_SetTempHealth(Handle plugin, int numParams) // Native "L4D_SetTempHealth"
{
	int client = GetNativeCell(1);
	float health = GetNativeCell(2);
	SetTempHealth(client, health);

	return 0;
}

any Native_Internal_GetReserveAmmo(Handle plugin, int numParams) // Native "L4D_GetReserveAmmo"
{
	int client = GetNativeCell(1);
	int weapon = GetNativeCell(2);
	return GetReserveAmmo(client, weapon);
}

int Native_Internal_SetReserveAmmo(Handle plugin, int numParams) // Native "L4D_SetReserveAmmo"
{
	int client = GetNativeCell(1);
	int weapon = GetNativeCell(2);
	int ammo = GetNativeCell(3);
	SetReserveAmmo(client, weapon, ammo);

	return 0;
}

int Native_PlayMusic(Handle plugin, int numParams) // Native "L4D_PlayMusic"
{
	int client = GetNativeCell(1);
	int source_ent = GetNativeCell(3);
	float one_float = GetNativeCell(4);
	bool one_bool = GetNativeCell(5);
	bool two_bool = GetNativeCell(6);

	Address music_address = GetEntityAddress(client) + view_as<Address>(GetEntSendPropOffs(client, "m_music"));

	int maxlength;
	GetNativeStringLength(2, maxlength);
	maxlength += 1;
	char[] music_str = new char[maxlength];
	GetNativeString(2, music_str, maxlength);

	//PrintToServer("#### CALL g_hSDK_Music_Play");
	SDKCall(g_hSDK_Music_Play, music_address, music_str, source_ent, one_float, one_bool, two_bool);

	return 0;
}

int Native_StopMusic(Handle plugin, int numParams) // Native "L4D_StopMusic"
{
	int client = GetNativeCell(1);
	float one_float = GetNativeCell(3);
	bool one_bool = GetNativeCell(4);

	Address music_address = GetEntityAddress(client) + view_as<Address>(GetEntSendPropOffs(client, "m_music"));

	int maxlength;
	GetNativeStringLength(2, maxlength);
	maxlength += 1;
	char[] music_str = new char[maxlength];
	GetNativeString(2, music_str, maxlength);

	//PrintToServer("#### CALL g_hSDK_Music_StopPlaying");
	SDKCall(g_hSDK_Music_StopPlaying, music_address, music_str, one_float, one_bool);

	return 0;
}

int Native_CTerrorPlayer_Deafen(Handle plugin, int numParams) // Native "L4D_Deafen"
{
	ValidateNatives(g_hSDK_CTerrorPlayer_Deafen, "CTerrorPlayer::Deafen");

	int client = GetNativeCell(1);

	//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_Deafen");
	SDKCall(g_hSDK_CTerrorPlayer_Deafen, client, 1.0, 0.0, 0.01 );

	return 0;
}

int Native_CEntityDissolve_Create(Handle plugin, int numParams) // Native "L4D_Dissolve"
{
	ValidateNatives(g_hSDK_CEntityDissolve_Create, "CEntityDissolve::Create");

	int entity = GetNativeCell(1);
	if( entity > MaxClients )
	{
		// Prevent common infected from crashing the server when taking damage from the dissolver.
		SDKHook(entity, SDKHook_OnTakeDamage, OnCommonDamage);
	}

	//PrintToServer("#### CALL g_hSDK_CEntityDissolve_Create");
	int dissolver = SDKCall(g_hSDK_CEntityDissolve_Create, entity, "", GetGameTime() + 0.8, 2, false);
	SetEntPropFloat(dissolver, Prop_Send, "m_flFadeOutStart", 0.0); // Fixes broken particles
	return dissolver;
}

Action OnCommonDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	// Block dissolver damage to common, otherwise server will crash.
	if( damage == 10000 && damagetype == (g_bLeft4Dead2 ? 5982249 : 33540137) )
	{
		damage = 0.0;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

int Native_CTerrorPlayer_OnITExpired(Handle plugin, int numParams) // Native "L4D_OnITExpired"
{
	ValidateNatives(g_hSDK_CTerrorPlayer_OnITExpired, "CTerrorPlayer::OnITExpired");

	int client = GetNativeCell(1);

	//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_OnITExpired");
	SDKCall(g_hSDK_CTerrorPlayer_OnITExpired, client);

	return 0;
}

any Native_CTerrorPlayer_EstimateFallingDamage(Handle plugin, int numParams) // Native "L4D_EstimateFallingDamage"
{
	ValidateNatives(g_hSDK_CTerrorPlayer_EstimateFallingDamage, "CTerrorPlayer::EstimateFallingDamage");

	int client = GetNativeCell(1);

	//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_EstimateFallingDamage");
	return SDKCall(g_hSDK_CTerrorPlayer_EstimateFallingDamage, client);
}

int Native_CBaseEntity_WorldSpaceCenter(Handle plugin, int numParams) // Native "L4D_GetEntityWorldSpaceCenter"
{
	ValidateNatives(g_hSDK_CBaseEntity_WorldSpaceCenter, "CBaseEntity::WorldSpaceCenter");

	int entity = GetNativeCell(1);
	float vPos[3];

	//PrintToServer("#### CALL g_hSDK_CBaseEntity_WorldSpaceCenter");
	SDKCall(g_hSDK_CBaseEntity_WorldSpaceCenter, entity, vPos);

	/* Without SDKCall, only properly on clients:
	float vPos[3], vMin[3], vMax[3], vResult[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPos);
	GetEntPropVector(entity, Prop_Data, "m_vecMins", vMin);
	GetEntPropVector(entity, Prop_Data, "m_vecMaxs", vMax);

	AddVectors(vMin, vMax, vResult);
	ScaleVector(vResult, 0.5);
	AddVectors(vPos, vResult, vResult);

	SetNativeArray(2, vResult, sizeof(vResult));
	// */

	SetNativeArray(2, vPos, sizeof(vPos));
	return 0;
}

int Native_CBaseEntity_ApplyLocalAngularVelocityImpulse(Handle plugin, int numParams) // Native "L4D_AngularVelocity"
{
	ValidateNatives(g_hSDK_CBaseEntity_ApplyLocalAngularVelocityImpulse, "CBaseEntity::ApplyLocalAngularVelocityImpulse");

	float vAng[3];
	int entity = GetNativeCell(1);
	GetNativeArray(2, vAng, sizeof(vAng));

	//PrintToServer("#### CALL g_hSDK_CBaseEntity_ApplyLocalAngularVelocityImpulse");
	SDKCall(g_hSDK_CBaseEntity_ApplyLocalAngularVelocityImpulse, entity, vAng);

	return 0;
}

int Native_ZombieManager_GetRandomPZSpawnPosition(Handle plugin, int numParams) // Native "L4D_GetRandomPZSpawnPosition"
{
	ValidateAddress(g_pZombieManager, "g_pZombieManager");
	ValidateNatives(g_hSDK_ZombieManager_GetRandomPZSpawnPosition, "ZombieManager::GetRandomPZSpawnPosition");

	float vPos[3];
	int client = GetNativeCell(1);
	int zombieClass = GetNativeCell(2);
	int attempts = GetNativeCell(3);

	//PrintToServer("#### CALL g_hSDK_ZombieManager_GetRandomPZSpawnPosition");
	int result = SDKCall(g_hSDK_ZombieManager_GetRandomPZSpawnPosition, g_pZombieManager, zombieClass, attempts, client, vPos);
	SetNativeArray(4, vPos, 3);

	return result;
}

int Native_CNavMesh_GetNearestNavArea(Handle plugin, int numParams) // Native "L4D_GetNearestNavArea"
{
	ValidateAddress(g_pNavMesh, "g_pNavMesh");
	ValidateNatives(g_hSDK_CNavMesh_GetNearestNavArea, "CNavMesh::GetNearestNavArea");

	float vPos[3];
	GetNativeArray(1, vPos, sizeof(vPos));

	float flMaxPathLength = 300.0;
	bool anyZ = false;
	bool checkLOS = false;
	bool checkGround = false;
	int teamID = 2;

	if( numParams == 6 )
	{
		flMaxPathLength = GetNativeCell(2);
		anyZ = GetNativeCell(3);
		checkLOS = GetNativeCell(4);
		checkGround = GetNativeCell(5);
		teamID = GetNativeCell(6);
	}

	//PrintToServer("#### CALL Native_CNavMesh_GetNearestNavArea");
	int result = SDKCall(g_hSDK_CNavMesh_GetNearestNavArea, g_pNavMesh, vPos, anyZ, flMaxPathLength, checkLOS, checkGround, teamID);
	return result;
}

int Native_CTerrorPlayer_GetLastKnownArea(Handle plugin, int numParams) // Native "L4D_GetLastKnownArea"
{
	ValidateNatives(g_hSDK_CTerrorPlayer_GetLastKnownArea, "CTerrorPlayer::GetLastKnownArea");

	int client = GetNativeCell(1);

	//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_GetLastKnownArea");
	return SDKCall(g_hSDK_CTerrorPlayer_GetLastKnownArea, client);
}

int Native_TerrorNavArea_FindRandomSpot(Handle plugin, int numParams) // Native "L4D_FindRandomSpot"
{
	ValidateNatives(g_hSDK_TerrorNavArea_FindRandomSpot, "TerrorNavArea::FindRandomSpot");

	float vPos[3];
	int area = GetNativeCell(1);

	//PrintToServer("#### CALL g_hSDK_TerrorNavArea_FindRandomSpot");
	SDKCall(g_hSDK_TerrorNavArea_FindRandomSpot, area, vPos, sizeof(vPos));
	SetNativeArray(2, vPos, sizeof(vPos));

	return 0;
}

int Native_CTerrorPlayer_WarpToValidPositionIfStuck(Handle plugin, int numParams) // Native "L4D_FindRandomSpot"
{
	ValidateNatives(g_hSDK_CTerrorPlayer_WarpToValidPositionIfStuck, "CTerrorPlayer::WarpToValidPositionIfStuck");

	int client = GetNativeCell(1);

	//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_WarpToValidPositionIfStuck");
	SDKCall(g_hSDK_CTerrorPlayer_WarpToValidPositionIfStuck, client);

	return 0;
}

int Native_IsVisibleToPlayer(Handle plugin, int numParams) // Native "L4D2_IsVisibleToPlayer"
{
	ValidateNatives(g_hSDK_IsVisibleToPlayer, "IsVisibleToPlayer");

	float vPos[3];
	int client = GetNativeCell(1);
	int team = GetNativeCell(2);
	int team_target = GetNativeCell(3);
	int area = GetNativeCell(4);
	GetNativeArray(5, vPos, sizeof(vPos));

	//PrintToServer("#### CALL g_hSDK_IsVisibleToPlayer");
	if( SDKCall(g_hSDK_IsVisibleToPlayer, vPos, client, team, team_target, 0.0, 0, area, true) )
		return true;

	return false;
}

int Native_CDirector_HasAnySurvivorLeftSafeArea(Handle plugin, int numParams) // Native "L4D_HasAnySurvivorLeftSafeArea"
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_CDirector_HasAnySurvivorLeftSafeArea, "CDirector::HasAnySurvivorLeftSafeArea");

	//PrintToServer("#### CALL g_hSDK_CDirector_HasAnySurvivorLeftSafeArea");
	return SDKCall(g_hSDK_CDirector_HasAnySurvivorLeftSafeArea, g_pDirector);
}

int Native_CDirector_IsAnySurvivorInStartArea(Handle plugin, int numParams) // Native "L4D_IsAnySurvivorInStartArea"
{
	if( g_bLeft4Dead2 )
	{
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && IsInFirstCheckpoint(i) )
			{
				return true;
			}
		}
	}
	else
	{
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( g_bCheckpointFirst[i] && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) )
			{
				return true;
			}
		}
	}

	return false;

	/*
	// Removed this due to not always reporting true
	if( g_bLeft4Dead2 )
	{
		ValidateAddress(g_pDirector, "g_pDirector");
		ValidateNatives(g_hSDK_CDirector_IsAnySurvivorInStartArea, "CDirector::IsAnySurvivorInStartArea");

		//PrintToServer("#### CALL g_hSDK_CDirector_IsAnySurvivorInStartArea");
		return SDKCall(g_hSDK_CDirector_IsAnySurvivorInStartArea, g_pDirector);
	} else {
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && GetEntProp(i, Prop_Send, "m_isInMissionStartArea") )
			{
				return true;
			}
		}

		return false;
	}
	*/
}

int Native_CDirector_IsAnySurvivorInCheckpoint(Handle plugin, int numParams) // Native "L4D_IsAnySurvivorInCheckpoint"
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && (IsInFirstCheckpoint(i) || IsInLastCheckpoint(i)) )
		{
			return true;
		}
	}

	return false;
}

/*
int Native_CDirector_IsAnySurvivorInExitCheckpoint(Handle plugin, int numParams) // Native "L4D_IsAnySurvivorInExitCheckpoint"
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_CDirector_IsAnySurvivorInExitCheckpoint, "CDirector::IsAnySurvivorInExitCheckpoint");

	//PrintToServer("#### CALL g_hSDK_CDirector_IsAnySurvivorInExitCheckpoint");
	return SDKCall(g_hSDK_CDirector_IsAnySurvivorInExitCheckpoint, g_pDirector);
}
// */

int Native_CDirector_AreAllSurvivorsInFinaleArea(Handle plugin, int numParams) // Native "L4D_AreAllSurvivorsInFinaleArea"
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_CDirector_AreAllSurvivorsInFinaleArea, "CDirector::AreAllSurvivorsInFinaleArea");

	//PrintToServer("#### CALL g_hSDK_CDirector_AreAllSurvivorsInFinaleArea");
	return SDKCall(g_hSDK_CDirector_AreAllSurvivorsInFinaleArea, g_pDirector);
}

int Native_IsInFirstCheckpoint(Handle plugin, int numParams) // Native "L4D_IsInFirstCheckpoint"
{
	int client = GetNativeCell(1);
	return IsInFirstCheckpoint(client);
}

#define FIRST_RANGE_TOLLERANCE 2500.0 // Guess max distance to first saferoom

bool IsInFirstCheckpoint(int client)
{
	if( g_bLeft4Dead2 )
	{
		//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_GetLastKnownArea");
		Address nav = SDKCall(g_hSDK_CTerrorPlayer_GetLastKnownArea, client);
		if( nav == Address_Null ) return false;

		if( GetTerrorNavAreaFlow(nav) < FIRST_RANGE_TOLLERANCE )
		{
			//PrintToServer("#### CALL g_hSDK_TerrorNavMesh_GetInitialCheckpoint");
			int nav1 = SDKCall(g_hSDK_TerrorNavMesh_GetInitialCheckpoint, g_pNavMesh);
			if( nav1 )
			{
				//PrintToServer("#### CALL g_hSDK_Checkpoint_ContainsArea");
				if( SDKCall(g_hSDK_Checkpoint_ContainsArea, nav1, nav) )
					return true;
			}

			//PrintToServer("#### g_hSDK_TerrorNavMesh_IsInInitialCheckpoint_NoLandmark");
			if( SDKCall(g_hSDK_TerrorNavMesh_IsInInitialCheckpoint_NoLandmark, g_pNavMesh, nav) )
			{
				return true;
			}
		}
	}
	else
	{
		return g_bCheckpointFirst[client];
	}

	return false;
}

int Native_IsInLastCheckpoint(Handle plugin, int numParams) // Native "L4D_IsInLastCheckpoint"
{
	int client = GetNativeCell(1);
	return IsInLastCheckpoint(client);
}

bool IsInLastCheckpoint(int client)
{
	ValidateNatives(g_hSDK_CTerrorGameRules_IsMissionFinalMap, "CTerrorGameRules::IsMissionFinalMap");

	//PrintToServer("#### g_hSDK_CTerrorGameRules_IsMissionFinalMap");
	if( SDKCall(g_hSDK_CTerrorGameRules_IsMissionFinalMap) ) return false;

	if( g_bLeft4Dead2 )
	{
		ValidateNatives(g_hSDK_CTerrorPlayer_GetLastKnownArea, "CTerrorPlayer::GetLastKnownArea");
		ValidateNatives(g_hSDK_TerrorNavMesh_GetLastCheckpoint, "TerrorNavMesh::GetLastCheckpoint");
		ValidateNatives(g_hSDK_TerrorNavMesh_IsInExitCheckpoint_NoLandmark, "TerrorNavMesh::IsInExitCheckpoint_NoLandmark");

		//PrintToServer("#### g_hSDK_CTerrorPlayer_GetLastKnownArea");
		int area = SDKCall(g_hSDK_CTerrorPlayer_GetLastKnownArea, client);
		if( area == 0 ) return false;

		//PrintToServer("#### g_hSDK_TerrorNavMesh_GetLastCheckpoint");
		int nav1 = SDKCall(g_hSDK_TerrorNavMesh_GetLastCheckpoint, g_pNavMesh);
		if( nav1 )
		{
			//PrintToServer("#### g_hSDK_Checkpoint_ContainsArea");
			if( SDKCall(g_hSDK_Checkpoint_ContainsArea, nav1, area) )
				return true;
		}

		//PrintToServer("#### g_hSDK_TerrorNavMesh_IsInExitCheckpoint_NoLandmark");
		if( SDKCall(g_hSDK_TerrorNavMesh_IsInExitCheckpoint_NoLandmark, g_pNavMesh, area) )
			return true;
	}
	else
	{
		return g_bCheckpointLast[client];
	}

	return false;
}

int Native_IsPositionInFirstCheckpoint(Handle plugin, int numParams) // Native "L4D_IsPositionInFirstCheckpoint"
{
	float vPos[3];
	GetNativeArray(1, vPos, sizeof(vPos));

	return IsPositionInSaferoom(vPos, true);
}

int Native_IsPositionInLastCheckpoint(Handle plugin, int numParams) // Native "L4D_IsPositionInLastCheckpoint"
{
	float vPos[3];
	GetNativeArray(1, vPos, sizeof(vPos));

	return IsPositionInSaferoom(vPos, false);
}

bool IsPositionInSaferoom(float vecPos[3], bool bStartSaferoom)
{
	Address nav = L4D_GetNearestNavArea(vecPos, 1000.0, _, _, true);
	if( nav != Address_Null )
	{
		int spawnAttributes = GetTerrorNavArea_Attributes(nav);
		if( spawnAttributes & NAV_SPAWN_CHECKPOINT && !(spawnAttributes & NAV_SPAWN_FINALE) )
		{
			float range = GetTerrorNavAreaFlow(nav);
			if( (bStartSaferoom && range < FIRST_RANGE_TOLLERANCE) || (!bStartSaferoom && range > FIRST_RANGE_TOLLERANCE) )
			{
				return bStartSaferoom != GetTerrorNavAreaFlow(nav) > FIRST_RANGE_TOLLERANCE;
			}
		}
	}

	return false;
}

#define DOOR_RANGE_TOLLERANCE 2000.0 // Guess distance from start of map to first saferoom door

int Native_GetCheckpointFirst(Handle plugin, int numParams) // Native "L4D_GetCheckpointFirst"
{
	return GetCheckpointFirst();
}

int GetCheckpointFirst()
{
	// Cache
	static int door;

	if( door && EntRefToEntIndex(door) != INVALID_ENT_REFERENCE )
	{
		return EntRefToEntIndex(door);
	}

	// Find
	ValidateAddress(g_pNavMesh, "g_pNavMesh");
	ValidateAddress(g_iOff_m_flow, "m_flow");

	float vPos[3], val, pos = 999999.9;
	int flags, target, entity = -1;

	while( (entity = FindEntityByClassname(entity, "prop_door_rotating_checkpoint")) != -1 )
	{
		flags = GetEntProp(entity, Prop_Send, "m_spawnflags");
		if( !(flags & DOOR_FLAG_IGNORE_USE) )
		{
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);

			//PrintToServer("#### g_hSDK_CNavMesh_GetNearestNavArea");
			Address area = view_as<Address>(SDKCall(g_hSDK_CNavMesh_GetNearestNavArea, g_pNavMesh, vPos, 0, 1000.0, 0, 0, 0));
			if( area )
			{
				val = view_as<float>(LoadFromAddress(area + view_as<Address>(g_iOff_m_flow), NumberType_Int32));
				if( val < DOOR_RANGE_TOLLERANCE && val < pos )
				{
					pos = val;
					target = entity;
				}
			}
		}
	}

	if( target )
	{
		door = EntIndexToEntRef(target);
		return target;
	}

	return -1;
}

int Native_GetCheckpointLast(Handle plugin, int numParams) // Native "L4D_GetCheckpointLast"
{
	return GetCheckpointLast();
}

int GetCheckpointLast()
{
	// Cache
	static int door;

	if( door && EntRefToEntIndex(door) != INVALID_ENT_REFERENCE )
	{
		return EntRefToEntIndex(door);
	}

	// Find
	ValidateAddress(g_pNavMesh, "g_pNavMesh");
	ValidateAddress(g_iOff_m_flow, "m_flow");
	ValidateAddress(g_iOff_m_fMapMaxFlowDistance, "m_fMapMaxFlowDistance");

	float vPos[3], val, pos, max;
	int flags, target, entity = -1;

	max = view_as<float>(LoadFromAddress(g_pNavMesh + view_as<Address>(g_iOff_m_fMapMaxFlowDistance), NumberType_Int32));

	while( (entity = FindEntityByClassname(entity, "prop_door_rotating_checkpoint")) != -1 )
	{
		flags = GetEntProp(entity, Prop_Send, "m_spawnflags");
		if( !(flags & DOOR_FLAG_IGNORE_USE) )
		{
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);

			//PrintToServer("#### g_hSDK_CNavMesh_GetNearestNavArea");
			Address area = view_as<Address>(SDKCall(g_hSDK_CNavMesh_GetNearestNavArea, g_pNavMesh, vPos, 0, 1000.0, 0, 0, 0));
			if( area )
			{
				val = view_as<float>(LoadFromAddress(area + view_as<Address>(g_iOff_m_flow), NumberType_Int32));
				if( val > max - DOOR_RANGE_TOLLERANCE && val > pos ) // DOOR_RANGE_TOLLERANCE, guess distance from maps max distance to last saferoom door
				{
					pos = val;
					target = entity;
				}
			}
		}
	}

	if( target )
	{
		door = EntIndexToEntRef(target);
		return target;
	}

	return -1;
}

/*
// These do not work as expected
int Native_GetCheckpointFirst(Handle plugin, int numParams)
{
	// Cache
	static int door;

	if( door && EntRefToEntIndex(door) != INVALID_ENT_REFERENCE )
	{
		return EntRefToEntIndex(door);
	}

	// Find
	ValidateAddress(g_pDirector, "g_pNavMesh");
	ValidateNatives(g_hSDK_TerrorNavMesh_IsInInitialCheckpoint_NoLandmark, "TerrorNavMesh::IsInInitialCheckpoint_NoLandmark");

	Address safe = SDKCall(g_hSDK_TerrorNavMesh_IsInInitialCheckpoint_NoLandmark, g_pNavMesh);
	Address area;
	float vPos[3];
	int entity = -1;

	while( (entity = FindEntityByClassname(entity, "prop_door_rotating_checkpoint")) != -1 )
	{
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);
		area = view_as<Address>(L4D_GetNearestNavArea(vPos));

		if( SDKCall(g_hSDK_Checkpoint_ContainsArea, safe, area) )
			return entity;
	}

	return -1;
}

int Native_GetCheckpointLast(Handle plugin, int numParams)
{
	// Cache
	static int door;

	if( door && EntRefToEntIndex(door) != INVALID_ENT_REFERENCE )
	{
		return EntRefToEntIndex(door);
	}

	// Find
	ValidateAddress(g_pDirector, "g_pNavMesh");
	ValidateNatives(g_hSDK_TerrorNavMesh_IsInExitCheckpoint_NoLandmark, "TerrorNavMesh::IsInExitCheckpoint_NoLandmark");

	Address safe = SDKCall(g_hSDK_TerrorNavMesh_GetLastCheckpoint, g_pNavMesh);
	Address area;
	float vPos[3];
	int entity = -1;


	while( (entity = FindEntityByClassname(entity, "prop_door_rotating_checkpoint")) != -1 )
	{
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);
		area = view_as<Address>(L4D_GetNearestNavArea(vPos));

		if( SDKCall(g_hSDK_Checkpoint_ContainsArea, safe, area) )
			return entity;
	}

	return -1;
}
// */

int Native_CTerrorGameRules_HasPlayerControlledZombies(Handle plugin, int numParams) // Native "L4D_HasPlayerControlledZombies"
{
	ValidateNatives(g_hSDK_CTerrorGameRules_HasPlayerControlledZombies, "CTerrorGameRules::HasPlayerControlledZombies");

	//PrintToServer("#### CALL g_hSDK_CTerrorGameRules_HasPlayerControlledZombies");
	return SDKCall(g_hSDK_CTerrorGameRules_HasPlayerControlledZombies);
}

int Native_CBaseGrenade_Detonate(Handle plugin, int numParams) // Native "L4D_DetonateProjectile"
{
	ValidateNatives(g_hSDK_CBaseGrenade_Detonate, "CBaseGrenade::Detonate");

	int entity = GetNativeCell(1);

	//PrintToServer("#### CALL g_hSDK_CBaseGrenade_Detonate 1");
	// if( GetEntPropFloat(entity, Prop_Data, "m_flCreateTime") == GetGameTime() )
		// RequestFrame(OnFrameDetonate, EntIndexToEntRef(entity));
	// else
	SDKCall(g_hSDK_CBaseGrenade_Detonate, entity);

	return 0;
}

/*
void OnFrameDetonate(int entity)
{
	entity = EntRefToEntIndex(entity);
	if( entity != -1 )
	{
		//PrintToServer("#### CALL g_hSDK_CBaseGrenade_Detonate 2");
		SDKCall(g_hSDK_CBaseGrenade_Detonate, entity);
	}
}
// */

/*
int Native_CInferno_StartBurning(Handle plugin, int numParams) // Native "L4D_StartBurning"
{
	ValidateNatives(g_hSDK_CInferno_StartBurning, "CInferno::StartBurning");

	float vPos[3], vVel[3], vNorm[3];
	int entity = GetNativeCell(1);
	GetNativeArray(2, vPos, sizeof(vPos));
	GetNativeArray(3, vNorm, sizeof(vNorm));
	GetNativeArray(4, vVel, sizeof(vVel));

	PrintToChatAll("#### CALL g_hSDK_CInferno_StartBurning [%d] %f", entity, vPos[1]);
	SDKCall(g_hSDK_CInferno_StartBurning, entity, vPos, vNorm, vVel, 1);
	return 0;
}
// */

// ==================================================
// TANK ROCK NATIVE
// ==================================================
// SDKCall method did not work as expected:
// 1. The rock is attached to the client throwing.
// 2. The Velocity is not applied.
// 3. The rock does not detonate on impact.
// So using this method to create, get entity index and apply owner.
int g_iTankRockOwner;
int g_iTankRockEntity;

int Native_CTankRock_Create(Handle plugin, int numParams) // Native "L4D_TankRockPrj"
{
	// Get client index and origin/angle to throw
	float vPos[3], vAng[3];
	int client = GetNativeCell(1);
	GetNativeArray(2, vPos, sizeof(vPos));
	GetNativeArray(3, vAng, sizeof(vAng));

	// Create rock
	int entity = CreateEntityByName("env_rock_launcher");
	TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
	DispatchSpawn(entity);

	// Watch for "tank_rock" entity index and to set owner
	g_iTankRockEntity = 0;
	g_iTankRockOwner = client > 0 && client <= MaxClients ? client : -1;
	AcceptEntityInput(entity, "LaunchRock");
	g_iTankRockOwner = 0;

	// Delete and return rock index
	RemoveEntity(entity);

	entity = g_iTankRockEntity;
	g_iTankRockEntity = 0;

	return entity;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	// Watch for this plugins native creating the "tank_rock" to return it's entity index and set owner if applicable
	if( g_iTankRockOwner && strcmp(classname, "tank_rock") == 0 )
	{
		g_iTankRockEntity = entity;

		// Must set owner on next frame after it's spawned
		if( g_iTankRockOwner != -1 )
		{
			DataPack dPack = new DataPack();
			dPack.WriteCell(EntIndexToEntRef(entity));
			dPack.WriteCell(GetClientUserId(g_iTankRockOwner));
			RequestFrame(OnFrameTankRock, dPack);
		}

		// Make the tank rock fully visible, otherwise it's semi-transparent (during pickup animation of Tank Rock).
		SetEntityRenderColor(entity, 255, 255, 255, 255);
	}
}

void OnFrameTankRock(DataPack dPack)
{
	dPack.Reset();

	int entity = dPack.ReadCell();
	int client = dPack.ReadCell();
	client = GetClientOfUserId(client);

	delete dPack;

	if( client && IsClientInGame(client) && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
	{
		SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
		SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", client);
		SetEntPropEnt(entity, Prop_Send, "m_hThrower", client);
		SetEntPropEnt(entity, Prop_Data, "m_hThrower", client);
	}
}
// ==================================================

int Native_CPipeBombProjectile_Create(Handle plugin, int numParams) // Native "L4D_PipeBombPrj"
{
	ValidateNatives(g_hSDK_CPipeBombProjectile_Create, "CPipeBombProjectile::Create");

	float vPos[3], vAng[3];
	int client = GetNativeCell(1);
	GetNativeArray(2, vPos, sizeof(vPos));
	GetNativeArray(3, vAng, sizeof(vAng));

	//PrintToServer("#### CALL g_hSDK_CPipeBombProjectile_Create");
	return SDKCall(g_hSDK_CPipeBombProjectile_Create, vPos, vAng, vAng, vAng, client, 2.0);

	// int entity = SDKCall(g_hSDK_CPipeBombProjectile_Create, vPos, vAng, vAng, vAng, client, 2.0);
	// SetEntPropFloat(entity, Prop_Data, "m_flCreateTime", GetGameTime());
	// return entity;
}

int Native_CMolotovProjectile_Create(Handle plugin, int numParams) // Native "L4D_MolotovPrj"
{
	ValidateNatives(g_hSDK_CMolotovProjectile_Create, "CMolotovProjectile::Create");

	float vPos[3], vAng[3];
	int client = GetNativeCell(1);
	GetNativeArray(2, vPos, sizeof(vPos));
	GetNativeArray(3, vAng, sizeof(vAng));

	//PrintToServer("#### CALL g_hSDK_CMolotovProjectile_Create");
	return SDKCall(g_hSDK_CMolotovProjectile_Create, vPos, vAng, vAng, vAng, client, 2.0);

	// int entity = SDKCall(g_hSDK_CMolotovProjectile_Create, vPos, vAng, vAng, vAng, client, 2.0);
	// SetEntPropFloat(entity, Prop_Data, "m_flCreateTime", GetGameTime());
	// return entity;
}

int Native_CVomitJarProjectile_Create(Handle plugin, int numParams) // Native "L4D2_VomitJarPrj"
{
	ValidateNatives(g_hSDK_CVomitJarProjectile_Create, "CVomitJarProjectile::Create");

	float vPos[3], vAng[3];
	int client = GetNativeCell(1);
	GetNativeArray(2, vPos, sizeof(vPos));
	GetNativeArray(3, vAng, sizeof(vAng));

	//PrintToServer("#### CALL g_hSDK_CVomitJarProjectile_Create");
	return SDKCall(g_hSDK_CVomitJarProjectile_Create, vPos, vAng, vAng, vAng, client, 2.0);

	// int entity = SDKCall(g_hSDK_CVomitJarProjectile_Create, vPos, vAng, vAng, vAng, client, 2.0);
	// SetEntPropFloat(entity, Prop_Data, "m_flCreateTime", GetGameTime());
	// return entity;
}

int Native_CGrenadeLauncher_Projectile_Create(Handle plugin, int numParams) // Native "L4D2_GrenadeLauncherPrj"
{
	ValidateNatives(g_hSDK_CGrenadeLauncher_Projectile_Create, "CGrenadeLauncher_Projectile::Create");

	float vPos[3], vAng[3];
	int client = GetNativeCell(1);
	GetNativeArray(2, vPos, sizeof(vPos));
	GetNativeArray(3, vAng, sizeof(vAng));

	//PrintToServer("#### CALL g_hSDK_CGrenadeLauncher_Projectile_Create");
	return SDKCall(g_hSDK_CGrenadeLauncher_Projectile_Create, vPos, vAng, vAng, vAng, client, 2.0);

	// int entity = SDKCall(g_hSDK_CGrenadeLauncher_Projectile_Create, vPos, vAng, vAng, vAng, client, 2.0);
	// SetEntPropFloat(entity, Prop_Data, "m_flCreateTime", GetGameTime());
	// return entity;
}

int Native_CSpitterProjectile_Create(Handle plugin, int numParams) // Native "L4D2_SpitterPrj"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateNatives(g_hSDK_CSpitterProjectile_Create, "CSpitterProjectile::Create");

	float vPos[3], vAng[3];
	int client = GetNativeCell(1);
	GetNativeArray(2, vPos, sizeof(vPos));
	GetNativeArray(3, vAng, sizeof(vAng));

	//PrintToServer("#### CALL g_hSDK_CSpitterProjectile_Create");
	int entity = SDKCall(g_hSDK_CSpitterProjectile_Create, vPos, vAng, vAng, vAng, client);
	// SetEntPropFloat(entity, Prop_Data, "m_flCreateTime", GetGameTime());

	// Not watching for acid damage
	if( !g_bAcidWatch )
	{
		// Verify client is not team 3, which causes sound bug
		if( !client || GetClientTeam(client) != 3 )
		{
			g_bAcidWatch = true;
			g_iAcidEntity[entity] = EntIndexToEntRef(entity);

			// Hook clients damage
			for( int i = 1; i <= MaxClients; i++ )
			{
				if( IsClientInGame(i) )
				{
					SDKHook(i, SDKHook_OnTakeDamageAlivePost, OnAcidDamage);
				}
			}
		}
	}

	return entity;
}

void OnAcidDamage(int victim, int attacker, int inflictor, float damage, int damagetype)
{
	// Emit sound when taking acid damage
	if( damage > 0 )
	{
		if( ((damagetype == (DMG_ENERGYBEAM|DMG_RADIATION) && attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker) && GetClientTeam(attacker) != 3)) || (damagetype == (DMG_ENERGYBEAM|DMG_RADIATION|DMG_PREVENT_PHYSICS_FORCE) && attacker > MaxClients) )
		{
			float vPos[3];
			GetClientAbsOrigin(victim, vPos);
			EmitSoundToAll(g_sAcidSounds[GetRandomInt(0, sizeof(g_sAcidSounds) - 1)], _, SNDCHAN_AUTO, 85, _, 0.55, GetRandomInt(95, 105), _, vPos);
		}
	}
}

// When acid entity is destroyed, and no more active, unhook
public void OnEntityDestroyed(int entity)
{
	// Acid damage watched and destroyed entity was acid damage
	if( g_bAcidWatch && entity > 0 && EntIndexToEntRef(entity) == g_iAcidEntity[entity] )
	{
		g_iAcidEntity[entity] = 0;

		bool reset = true;

		// Check no more acid entities are alive
		for( int i = MaxClients + 1; i < 2048; i++ )
		{
			if( EntRefToEntIndex(g_iAcidEntity[i]) != INVALID_ENT_REFERENCE )
			{
				reset = false;
				break;
			}
		}

		// If no acid entities are alive, unhook damage on clients
		if( reset )
		{
			for( int i = 1; i <= MaxClients; i++ )
			{
				if( IsClientInGame(i) )
				{
					SDKUnhook(i, SDKHook_OnTakeDamageAlivePost, OnAcidDamage);
				}
			}
		}
	}
}

int Native_CTerrorPlayer_OnAdrenalineUsed(Handle plugin, int numParams) // Native "L4D2_UseAdrenaline"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateNatives(g_hSDK_CTerrorPlayer_OnAdrenalineUsed, "CTerrorPlayer::OnAdrenalineUsed");

	int client = GetNativeCell(1);
	float fTime = GetNativeCell(2);
	bool heal = GetNativeCell(3);

	// Heal
	if( heal )
	{
		float fHealth = GetTempHealth(client);
		int iHealth = GetClientHealth(client);
		float fClientHealth = iHealth + fHealth;
		if( fClientHealth < 100.0 ) // Some plugin allows survivor HP > 100
		{
			fClientHealth = fClientHealth + g_fCvar_Adrenaline;
			if( fClientHealth > 100.0 )
			{
				SetTempHealth(client, 100.0 - iHealth);
			}
			else
			{
				SetTempHealth(client, fClientHealth - iHealth);
			}
		}
	}

	// Event
	Event hEvent = CreateEvent("adrenaline_used");
	if( hEvent != null )
	{
		hEvent.SetInt("userid", GetClientUserId(client));
		hEvent.Fire();
	}

	//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_OnAdrenalineUsed");
	SDKCall(g_hSDK_CTerrorPlayer_OnAdrenalineUsed, client, fTime);

	return 0;
}

int Native_GetCurrentFinaleStage(Handle plugin, int numParams) // Native "L4D2_GetCurrentFinaleStage"
{
	ValidateAddress(g_pScriptedEventManager, "g_pScriptedEventManager");

	return LoadFromAddress(view_as<Address>(g_pScriptedEventManager + 0x04), NumberType_Int32);
}

int Native_CDirector_ForceNextStage(Handle plugin, int numParams) // Native "L4D2_ForceNextStage"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_CDirector_ForceNextStage, "CDirector::ForceNextStage");

	//PrintToServer("#### CALL g_hSDK_CDirector_ForceNextStage");
	SDKCall(g_hSDK_CDirector_ForceNextStage, g_pDirector);

	return 0;
}

int Native_ForceVersusStart(Handle plugin, int numParams) // Native "L4D_ForceVersusStart"
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_ForceVersusStart, "Script_ForceVersusStart");

	//PrintToServer("#### CALL g_hSDK_ForceVersusStart");
	if( g_bLeft4Dead2 )
		SDKCall(g_hSDK_ForceVersusStart, g_pDirector);
	else
	{
		SDKCall(g_hSDK_ForceVersusStart, g_pDirector, -1.0);
	}

	return 0;
}

int Native_ForceSurvivalStart(Handle plugin, int numParams) // Native "L4D_ForceSurvivalStart"
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_ForceSurvivalStart, "ForceSurvivalStart");

	//PrintToServer("#### CALL g_hSDK_ForceSurvivalStart");
	SDKCall(g_hSDK_ForceSurvivalStart, g_pDirector);

	return 0;
}

int Native_ForceScavengeStart(Handle plugin, int numParams) // Native "L4D2_ForceScavengeStart"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_ForceScavengeStart, "ForceScavengeStart");

	//PrintToServer("#### CALL g_hSDK_ForceScavengeStart");
	SDKCall(g_hSDK_ForceScavengeStart, g_pDirector);

	return 0;
}

int Native_CDirector_IsTankInPlay(Handle plugin, int numParams) // Native "L4D2_IsTankInPlay"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_CDirector_IsTankInPlay, "CDirector_IsTankInPlay");

	//PrintToServer("#### CALL g_hSDK_CDirector_IsTankInPlay");
	return SDKCall(g_hSDK_CDirector_IsTankInPlay, g_pDirector);
}

int Native_SurvivorBot_IsReachable(Handle plugin, int numParams) // Native "L4D2_IsReachable"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateNatives(g_hSDK_SurvivorBot_IsReachable, "SurvivorBot::IsReachable");

	int client = GetNativeCell(1);

	if( IsFakeClient(client) == false || (GetClientTeam(client) != 2 && GetClientTeam(client) != 4) )
	{
		client = 0;

		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) && IsFakeClient(i) && IsPlayerAlive(i) )
			{
				int team = GetClientTeam(i);
				if( team == 2 || team == 4 )
				{
					client = i;
					break;
				}
			}
		}

		if( !client )
		{
			ThrowNativeError(SP_ERROR_PARAM, "L4D2_IsReachable Error: invalid client. This native only works for Survivor Bots.");
		}
	}

	float vPos[3];
	GetNativeArray(2, vPos, sizeof(vPos));

	//PrintToServer("#### CALL g_hSDK_SurvivorBot_IsReachable");
	return SDKCall(g_hSDK_SurvivorBot_IsReachable, client, vPos);
}

any Native_CDirector_GetFurthestSurvivorFlow(Handle plugin, int numParams) // Native "L4D2_GetFurthestSurvivorFlow"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_CDirector_GetFurthestSurvivorFlow, "CDirector::GetFurthestSurvivorFlow");

	//PrintToServer("#### CALL g_hSDK_CDirector_GetFurthestSurvivorFlow");
	return SDKCall(g_hSDK_CDirector_GetFurthestSurvivorFlow, g_pDirector);
}

int Native_GetFirstSpawnClass(Handle plugin, int numParams) // Native "L4D2_GetFirstSpawnClass"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateAddress(g_iOff_m_nFirstClassIndex, "m_nFirstClassIndex");

	return LoadFromAddress(g_pDirector + view_as<Address>(g_iOff_m_nFirstClassIndex), NumberType_Int32);
}

int Native_SetFirstSpawnClass(Handle plugin, int numParams) // Native "L4D2_SetFirstSpawnClass"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateAddress(g_iOff_m_nFirstClassIndex, "m_nFirstClassIndex");

	int index = GetNativeCell(1);
	if( index < 1 || index > 6 ) ThrowError("Invalid index %d, must be 1-6.", index);

	StoreToAddress(g_pDirector + view_as<Address>(g_iOff_m_nFirstClassIndex), index, NumberType_Int32);

	return 0;
}

int Native_NavAreaTravelDistance(Handle plugin, int numParams) // Native "L4D2_NavAreaTravelDistance"
{
	ValidateNatives(g_hSDK_NavAreaTravelDistance, "NavAreaTravelDistance");

	float vPos[3], vEnd[3];

	GetNativeArray(1, vPos, sizeof(vPos));
	GetNativeArray(2, vEnd, sizeof(vEnd));
	int a3 = GetNativeCell(3);

	//PrintToServer("#### CALL g_hSDK_NavAreaTravelDistance");
	if( g_bLeft4Dead2 )
		return SDKCall(g_hSDK_NavAreaTravelDistance, vPos, vEnd, a3);

	return SDKCall(g_hSDK_NavAreaTravelDistance, vPos, vEnd);
}

int Native_NavAreaBuildPath(Handle plugin, int numParams) // Native "L4D2_NavAreaBuildPath"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	// Params
	int nav1 = GetNativeCell(1);
	int nav2 = GetNativeCell(2);

	if( nav1 && nav2 )
	{
		float flMaxPathLength = GetNativeCell(3);
		int teamID = GetNativeCell(4);
		bool ignoreNavBlockers = GetNativeCell(5);

		return SDKCall(g_hSDK_NavAreaBuildPath_ShortestPathCost, nav1, nav2, 0, 0, 0, 0, flMaxPathLength, teamID, ignoreNavBlockers);
	}

	return false;
}

int Native_CommandABot(Handle plugin, int numParams) // Native "L4D2_CommandABot"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	// Params
	int entity = GetNativeCell(1);
	int target = GetNativeCell(2);
	int type = GetNativeCell(3);

	// Set target
	static char sTemp[128];
	static char sTarget[32];
	sTarget[0] = 0;

	if( target > MaxClients )
		FormatEx(sTarget, sizeof(sTarget), "EntIndexToHScript(%d)", target);
	else if( target > 0 )
		FormatEx(sTarget, sizeof(sTarget), "GetPlayerFromUserID(%d)", GetClientUserId(target));

	// Command
	switch( type )
	{
		case 0:	FormatEx(sTemp, sizeof(sTemp), "CommandABot({cmd=0, bot=self, target=%s})", sTarget);
		case 1:
		{
			float vPos[3];
			GetNativeArray(4, vPos, sizeof(vPos));
			FormatEx(sTemp, sizeof(sTemp), "CommandABot({cmd=1, bot=self, pos=Vector(%f,%f,%f)})", vPos[0], vPos[1], vPos[2]);
		}
		case 2:	FormatEx(sTemp, sizeof(sTemp), "CommandABot({cmd=2, bot=self, target=%s})", sTarget);
		case 3:	sTemp = "CommandABot({cmd=3, bot=self})";
		default: return false;
	}

	// Execute
	SetVariantString(sTemp);
	AcceptEntityInput(entity, "RunScriptCode");

	return 0;
}

int Native_GetDirectorScriptScope(Handle plugin, int numParams) // Native "L4D2_GetDirectorScriptScope"
{
	ValidateAddress(g_pDirector, "g_pDirector");

	int a1 = GetNativeCell(1);

	return LoadFromAddress(g_pDirector + view_as<Address>(12 * a1) + view_as<Address>(g_iOff_m_iszScriptId), NumberType_Int32);
}

int Native_CDirector_GetScriptValueInt(Handle plugin, int numParams) // Native "L4D2_GetScriptValueInt"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_CDirector_GetScriptValueInt, "CDirector::GetScriptValueInt");

	int maxlength;
	GetNativeStringLength(1, maxlength);
	maxlength += 1;
	char[] key = new char[maxlength];
	GetNativeString(1, key, maxlength);

	int value = GetNativeCell(2);

	//PrintToServer("#### CALL g_hSDK_CDirector_GetScriptValueInt");
	return SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, key, value);
}

any Native_CDirector_GetScriptValueFloat(Handle plugin, int numParams) // Native "L4D2_GetScriptValueFloat"
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_CDirector_GetScriptValueFloat, "CDirector::GetScriptValueFloat");

	int maxlength;
	GetNativeStringLength(1, maxlength);
	maxlength += 1;
	char[] key = new char[maxlength];
	GetNativeString(1, key, maxlength);

	float value = GetNativeCell(2);

	//PrintToServer("#### CALL g_hSDK_CDirector_GetScriptValueFloat");
	return SDKCall(g_hSDK_CDirector_GetScriptValueFloat, g_pDirector, key, value);
}

/*
// Crashes when the key has not been set
int Native_CDirector_GetScriptValueString(Handle plugin, int numParams) // Native "L4D2_GetScriptValueString"
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_CDirector_GetScriptValueString, "CDirector::GetScriptValueString");

	// Key
	int maxlength;
	GetNativeStringLength(1, maxlength);
	maxlength += 1;
	char[] key = new char[maxlength];
	GetNativeString(1, key, maxlength);

	// Value
	GetNativeStringLength(2, maxlength);
	maxlength += 1;
	char[] value = new char[maxlength];
	GetNativeString(2, value, maxlength);

	// Return val
	maxlength = GetNativeCell(4);
	char[] retValue = new char[maxlength];
	char[] fakeRet = new char[maxlength];

	SDKCall(g_hSDK_CDirector_GetScriptValueString, g_pDirector, retValue, maxlength, key, value, fakeRet, sizeof(fakeRet));

	SetNativeString(3, fakeRet, maxlength);

	return 0;
}
// */





// ==================================================
// left4downtown.inc
// ==================================================
int Native_ScavengeBeginRoundSetupTime(Handle plugin, int numParams) // Native "L4D_ScavengeBeginRoundSetupTime"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pScavengeMode, "ScavengeModePtr");
	ValidateAddress(g_iOff_OnBeginRoundSetupTime, "OnBeginRoundSetupTime");

	return LoadFromAddress(view_as<Address>(g_pScavengeMode + g_iOff_OnBeginRoundSetupTime + 4), NumberType_Int32);
}

int Native_CDirector_ResetMobTimer(Handle plugin, int numParams) // Native "L4D_ResetMobTimer"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_CDirector_ResetMobTimer, "CDirector::ResetMobTimer");

	//PrintToServer("#### CALL g_hSDK_CDirector_ResetMobTimer");
	SDKCall(g_hSDK_CDirector_ResetMobTimer, g_pDirector);
	return 0;
}

any Native_GetPlayerSpawnTime(Handle plugin, int numParams) // Native "L4D_GetPlayerSpawnTime"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_iOff_SpawnTimer, "SpawnTimer");

	int client = GetNativeCell(1);
	return (view_as<float>(LoadFromAddress(GetEntityAddress(client) + view_as<Address>(g_iOff_SpawnTimer + 8), NumberType_Int32)) - GetGameTime());
}

int Native_CDirector_RestartScenarioFromVote(Handle plugin, int numParams) // Native "L4D_RestartScenarioFromVote"
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_CDirector_RestartScenarioFromVote, "CDirector::RestartScenarioFromVote");

	char map[64];
	GetNativeString(1, map, sizeof(map));

	//PrintToServer("#### CALL g_hSDK_CDirector_RestartScenarioFromVote");
	return SDKCall(g_hSDK_CDirector_RestartScenarioFromVote, g_pDirector, map);
}

int Native_GetVersusMaxCompletionScore(Handle plugin, int numParams) // Native "L4D_GetVersusMaxCompletionScore"
{
	ValidateAddress(g_pGameRules, "g_pGameRules");
	ValidateAddress(g_iOff_VersusMaxCompletionScore, "VersusMaxCompletionScore");

	if( g_bLeft4Dead2 )
	{
		return LoadFromAddress(g_pGameRules + view_as<Address>(g_iOff_VersusMaxCompletionScore), NumberType_Int32);
	}
	else
	{
		ValidateAddress(g_iOff_m_chapter, "m_chapter");

		int chapter = LoadFromAddress(g_pDirector + view_as<Address>(g_iOff_m_chapter), NumberType_Int32);
		return LoadFromAddress(g_pGameRules + view_as<Address>(chapter * 4 + g_iOff_VersusMaxCompletionScore), NumberType_Int32);
	}
}

int Native_SetVersusMaxCompletionScore(Handle plugin, int numParams) // Native "L4D_SetVersusMaxCompletionScore"
{
	ValidateAddress(g_pGameRules, "g_pGameRules");
	ValidateAddress(g_iOff_VersusMaxCompletionScore, "VersusMaxCompletionScore");

	int value = GetNativeCell(1);

	if( g_bLeft4Dead2 )
	{
		StoreToAddress(g_pGameRules + view_as<Address>(g_iOff_VersusMaxCompletionScore), value, NumberType_Int32, false);
	}
	else
	{
		ValidateAddress(g_iOff_m_chapter, "m_chapter");

		int chapter = LoadFromAddress(g_pDirector + view_as<Address>(g_iOff_m_chapter), NumberType_Int32);
		StoreToAddress(g_pGameRules + view_as<Address>(chapter * 4 + g_iOff_VersusMaxCompletionScore), value, NumberType_Int32, false);
	}

	return 0;
}

int Native_CTerrorGameRules_GetTeamScore(Handle plugin, int numParams) // Native "L4D_GetTeamScore"
{
	// #define SCORE_TEAM_A 1
	// #define SCORE_TEAM_B 2
	#define SCORE_TYPE_ROUND 0
	#define SCORE_TYPE_CAMPAIGN 1

	ValidateNatives(g_hSDK_CTerrorGameRules_GetTeamScore, "CTerrorGameRules::GetTeamScore");

	//sanity check that the team index is valid
	int team = GetNativeCell(1);
	if( team < 1 || team > (g_bLeft4Dead2 ? 2 : 6) )
	{
		ThrowNativeError(SP_ERROR_PARAM, "Logical team %d is invalid. Accepted values: 1 %s %d.", team, g_bLeft4Dead2 ? "or" : "to", g_bLeft4Dead2 ? 2 : 6);
	}

	//campaign_score is a boolean so should be 0 (use round score) or 1 only
	int score = GetNativeCell(2);
	if( score != SCORE_TYPE_ROUND && score != SCORE_TYPE_CAMPAIGN )
	{
		ThrowNativeError(SP_ERROR_PARAM, "campaign_score %d is invalid. Accepted values: 0 or 1", score);
	}

	//PrintToServer("#### CALL g_hSDK_CTerrorGameRules_GetTeamScore");
	return SDKCall(g_hSDK_CTerrorGameRules_GetTeamScore, team, score);
}

int Native_CDirector_IsFirstMapInScenario(Handle plugin, int numParams) // Native "L4D_IsFirstMapInScenario"
{
	ValidateNatives(g_hSDK_CDirector_IsFirstMapInScenario, "CDirector::IsFirstMapInScenario");

	if( !g_bLeft4Dead2 )
	{
		ValidateNatives(g_hSDK_KeyValues_GetString, "KV_GetString");
		static char sMap[64], check[64];

		/*
		// NULL PTR - METHOD (kept for demonstration)
		// "malloc" replacement hack (method by @Rostu)
		Address pNull = GetEntityAddress(0) + view_as<Address>(g_iOff_m_iClrRender);

		// Save old value
		int iRestore = LoadFromAddress(pNull, NumberType_Int32);

		// Some test to ensure that our temporary buffer is not corrupted with SDK Call
		// Test first 1024 bytes
		// int data[256];
		// for( int i = 0; i < sizeof(data); i++ )
		// {
		// 	data[i] = LoadFromAddress(pNull + view_as<Address>(i*4), NumberType_Int32);
		// }

		// Should be 0 to match the original call arguments
		StoreToAddress(pNull, 0, NumberType_Int32);

		//PrintToServer("#### CALL g_hSDK_CDirector_IsFirstMapInScenario");
		int keyvalue = SDKCall(g_hSDK_CDirector_IsFirstMapInScenario, pNull); // NULL PTR - METHOD (kept for demonstration)
		// */

		//PrintToServer("#### CALL g_hSDK_CDirector_IsFirstMapInScenario");
		int keyvalue = SDKCall(g_hSDK_CDirector_IsFirstMapInScenario, 0);

		// Restore the old value
		// StoreToAddress(pNull, iRestore, NumberType_Int32); // NULL PTR - METHOD (kept for demonstration)

		// NULL PTR - METHOD (kept for demonstration)
		// Verification
		/*
		PrintToServer("Checking for temp. buffer modifications ...");
		int new_byte;
		for( int i = 0; i < sizeof(data); i++ )
		{
			new_byte = LoadFromAddress(pNull + view_as<Address>(i*4), NumberType_Int32);
			if( data[i] != new_byte )
			{
				PrintToServer("m_iClrRender struct corrupted @%i: byte %X != %X", i*4, new_byte, data[i]);
			}
		}
		*/

		if( keyvalue )
		{
			//PrintToServer("#### CALL g_hSDK_KeyValues_GetString");
			SDKCall(g_hSDK_KeyValues_GetString, keyvalue, check, sizeof(check), "map", "N/A");

			GetCurrentMap(sMap, sizeof(sMap));
			return strcmp(sMap, check) == 0;
		}

		return 0;
	}

	//PrintToServer("#### CALL g_hSDK_CDirector_IsFirstMapInScenario");
	return SDKCall(g_hSDK_CDirector_IsFirstMapInScenario, g_pDirector);
}

int Native_CTerrorGameRules_IsMissionFinalMap(Handle plugin, int numParams) // Native "L4D_IsMissionFinalMap"
{
	ValidateNatives(g_hSDK_CTerrorGameRules_IsMissionFinalMap, "CTerrorGameRules::IsMissionFinalMap");

	//PrintToServer("#### CALL g_hSDK_CTerrorGameRules_IsMissionFinalMap");
	return SDKCall(g_hSDK_CTerrorGameRules_IsMissionFinalMap);
}

int Native_CGameRulesProxy_NotifyNetworkStateChanged(Handle plugin, int numParams) // Native "L4D_NotifyNetworkStateChanged"
{
	ValidateNatives(g_hSDK_CGameRulesProxy_NotifyNetworkStateChanged, "CGameRulesProxy::NotifyNetworkStateChanged");

	//PrintToServer("#### CALL g_hSDK_CGameRulesProxy_NotifyNetworkStateChanged");
	SDKCall(g_hSDK_CGameRulesProxy_NotifyNetworkStateChanged);
	return 0;
}

int Native_CTerrorPlayer_OnStaggered(Handle plugin, int numParams) // Native "L4D_StaggerPlayer"
{
	ValidateNatives(g_hSDK_CTerrorPlayer_OnStaggered, "CTerrorPlayer::OnStaggered");

	int a1 = GetNativeCell(1);
	int a2 = GetNativeCell(2);
	float vDir[3];
	GetNativeArray(3, vDir, sizeof(vDir));

	if( IsNativeParamNullVector(3) )
	{
		GetEntPropVector(a2, Prop_Send, "m_vecOrigin", vDir);
	}

	//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_OnStaggered");
	SDKCall(g_hSDK_CTerrorPlayer_OnStaggered, a1, a2, vDir);
	return 0;
}

int Native_ZombieManager_ReplaceTank(Handle plugin, int numParams) // Native "L4D_ReplaceTank"
{
	ValidateNatives(g_hSDK_ZombieManager_ReplaceTank, "ZombieManager::ReplaceTank");

	int oldtank = GetNativeCell(1);
	int newtank = GetNativeCell(2);

	if( oldtank <= 0 || oldtank > MaxClients || !IsClientInGame(oldtank) )
		ThrowNativeError(SP_ERROR_PARAM, "Invalid oldtank client %d.", oldtank);

	if( newtank <= 0 || newtank > MaxClients || !IsClientInGame(newtank) )
		ThrowNativeError(SP_ERROR_PARAM, "Invalid newtank client %d.", newtank);

	// float vAng[3], vOld[3], vNew[3];
	// GetClientEyeAngles(oldtank, vAng);
	// GetClientEyePosition(oldtank, vOld);
	// GetClientAbsOrigin(newtank, vNew);

	//PrintToServer("#### CALL g_hSDK_ZombieManager_ReplaceTank");
	SDKCall(g_hSDK_ZombieManager_ReplaceTank, g_pZombieManager, oldtank, newtank);

	// TeleportEntity(oldtank, vOld, vAng, NULL_VECTOR);
	// TeleportEntity(newtank, vNew, NULL_VECTOR, NULL_VECTOR);
	return 0;
}

int Native_CDirectorScriptedEventManager_SendInRescueVehicle(Handle plugin, int numParams) // Native "L4D2_SendInRescueVehicle"
{
	ValidateNatives(g_hSDK_CDirectorScriptedEventManager_SendInRescueVehicle, "CDirectorScriptedEventManager::SendInRescueVehicle");
	if( g_bLeft4Dead2 )		ValidateAddress(g_pScriptedEventManager, "ScriptedEventManagerPtr");
	else					ValidateAddress(g_pDirector, "g_pDirector");

	//PrintToServer("#### CALL g_hSDK_CDirectorScriptedEventManager_SendInRescueVehicle");
	SDKCall(g_hSDK_CDirectorScriptedEventManager_SendInRescueVehicle, g_bLeft4Dead2 ? g_pScriptedEventManager : view_as<int>(g_pDirector));
	return 0;
}

int Native_CDirectorScriptedEventManager_ChangeFinaleStage(Handle plugin, int numParams) // Native "L4D2_ChangeFinaleStage"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pScriptedEventManager, "ScriptedEventManagerPtr");
	ValidateNatives(g_hSDK_CDirectorScriptedEventManager_ChangeFinaleStage, "CDirectorScriptedEventManager::ChangeFinaleStage");

	static char arg[64];
	int finaleType = GetNativeCell(1);
	GetNativeString(2, arg, sizeof(arg));

	//PrintToServer("#### CALL g_hSDK_CDirectorScriptedEventManager_ChangeFinaleStage");
	SDKCall(g_hSDK_CDirectorScriptedEventManager_ChangeFinaleStage, g_pScriptedEventManager, finaleType, arg);
	return 0;
}

int Native_ZombieManager_SpawnTank(Handle plugin, int numParams) // Native "L4D2_SpawnTank"
{
	ValidateAddress(g_pZombieManager, "g_pZombieManager");
	ValidateNatives(g_hSDK_ZombieManager_SpawnTank, "ZombieManager::SpawnTank");

	float vPos[3], vAng[3];
	GetNativeArray(1, vPos, sizeof(vPos));
	GetNativeArray(2, vAng, sizeof(vAng));

	//PrintToServer("#### CALL g_hSDK_ZombieManager_SpawnTank");
	return SDKCall(g_hSDK_ZombieManager_SpawnTank, g_pZombieManager, vPos, vAng);
}

int Native_ZombieManager_SpawnSpecial(Handle plugin, int numParams) // Native "L4D2_SpawnSpecial"
{
	ValidateAddress(g_pZombieManager, "g_pZombieManager");

	float vPos[3], vAng[3];
	int zombieClass = GetNativeCell(1);
	GetNativeArray(2, vPos, sizeof(vPos));
	GetNativeArray(3, vAng, sizeof(vAng));

	if( g_bLeft4Dead2 )
	{
		ValidateNatives(g_hSDK_ZombieManager_SpawnSpecial, "ZombieManager::SpawnSpecial");

		//PrintToServer("#### CALL g_hSDK_ZombieManager_SpawnSpecial");
		return SDKCall(g_hSDK_ZombieManager_SpawnSpecial, g_pZombieManager, zombieClass, vPos, vAng);
	}
	else
	{
		switch( zombieClass )
		{
			case 1:
			{
				ValidateNatives(g_hSDK_ZombieManager_SpawnSmoker, "ZombieManager::SpawnSmoker");

				//PrintToServer("#### CALL g_hSDK_ZombieManager_SpawnSmoker");
				return SDKCall(g_hSDK_ZombieManager_SpawnSmoker, g_pZombieManager, vPos, vAng);
			}
			case 2:
			{
				ValidateNatives(g_hSDK_ZombieManager_SpawnBoomer, "ZombieManager::SpawnBoomer");

				//PrintToServer("#### CALL g_hSDK_ZombieManager_SpawnBoomer");
				return SDKCall(g_hSDK_ZombieManager_SpawnBoomer, g_pZombieManager, vPos, vAng);
			}
			case 3:
			{
				ValidateNatives(g_hSDK_ZombieManager_SpawnHunter, "ZombieManager::SpawnHunter");

				//PrintToServer("#### CALL g_hSDK_ZombieManager_SpawnHunter");
				return SDKCall(g_hSDK_ZombieManager_SpawnHunter, g_pZombieManager, vPos, vAng);
			}
		}
	}

	return 0;
}

int Native_ZombieManager_SpawnWitch(Handle plugin, int numParams) // Native "L4D2_SpawnWitch"
{
	ValidateAddress(g_pZombieManager, "g_pZombieManager");
	ValidateNatives(g_hSDK_ZombieManager_SpawnWitch, "ZombieManager::SpawnWitch");

	float vPos[3], vAng[3];
	GetNativeArray(1, vPos, sizeof(vPos));
	GetNativeArray(2, vAng, sizeof(vAng));

	//PrintToServer("#### CALL g_hSDK_ZombieManager_SpawnWitch");
	return SDKCall(g_hSDK_ZombieManager_SpawnWitch, g_pZombieManager, vPos, vAng);
}

int Native_ZombieManager_SpawnWitchBride(Handle plugin, int numParams) // Native "L4D2_SpawnWitchBride"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pZombieManager, "g_pZombieManager");
	ValidateNatives(g_hSDK_ZombieManager_SpawnWitchBride, "ZombieManager::SpawnWitchBride");

	float vPos[3], vAng[3];
	GetNativeArray(1, vPos, sizeof(vPos));
	GetNativeArray(2, vAng, sizeof(vAng));

	//PrintToServer("#### CALL g_hSDK_ZombieManager_SpawnWitchBride");
	return SDKCall(g_hSDK_ZombieManager_SpawnWitchBride, g_pZombieManager, vPos, vAng);
}

any Native_GetMobSpawnTimerRemaining(Handle plugin, int numParams) // Native "L4D_GetMobSpawnTimerRemaining"
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateAddress(g_iOff_MobSpawnTimer, "MobSpawnTimer");

	float timestamp = view_as<float>(LoadFromAddress(g_pDirector + view_as<Address>(g_iOff_MobSpawnTimer + 8), NumberType_Int32));
	return timestamp - GetGameTime();
}

any Native_GetMobSpawnTimerDuration(Handle plugin, int numParams) // Native "L4D_GetMobSpawnTimerDuration"
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateAddress(g_iOff_MobSpawnTimer, "MobSpawnTimer");

	float duration = view_as<float>(LoadFromAddress(g_pDirector + view_as<Address>(g_iOff_MobSpawnTimer + 4), NumberType_Int32));
	return duration > 0.0 ? duration : 0.0;
}

Action CmdLobby(int client, int args)
{
	Native_CBaseServer_SetReservationCookie(null, 0);
	return Plugin_Handled;
}

int Native_CBaseServer_SetReservationCookie(Handle plugin, int numParams) // Native "L4D_LobbyUnreserve"
{
	ValidateAddress(g_pServer, "g_pServer");
	ValidateNatives(g_hSDK_CBaseServer_SetReservationCookie, "CBaseServer::SetReservationCookie");

	//PrintToServer("#### CALL g_hSDK_CBaseServer_SetReservationCookie");
	SDKCall(g_hSDK_CBaseServer_SetReservationCookie, g_pServer, 0, 0, "Unreserved by Left 4 DHooks");

	return 0;
}

int Native_LobbyIsReserved(Handle plugin, int numParams) // Native "L4D_LobbyIsReserved"
{
	int val1 = LoadFromAddress(g_pServer + view_as<Address>(g_iOff_LobbyReservation + 4), NumberType_Int32);
	int val2 = LoadFromAddress(g_pServer + view_as<Address>(g_iOff_LobbyReservation), NumberType_Int32);
	if( val1 == 0 && val2 == 0 )
		return false;
	return true;
}

int Native_GetLobbyReservation(Handle plugin, int numParams) // Native "L4D_GetLobbyReservation"
{
	int val1 = LoadFromAddress(g_pServer + view_as<Address>(g_iOff_LobbyReservation + 4), NumberType_Int32);
	int val2 = LoadFromAddress(g_pServer + view_as<Address>(g_iOff_LobbyReservation), NumberType_Int32);

	char sTemp[20];

	if( val1 )
		Format(sTemp, sizeof(sTemp), "%X%08X", val1, val2);
	else
		Format(sTemp, sizeof(sTemp), "%X", val2);

	int maxlength = GetNativeCell(2);
	SetNativeString(1, sTemp, maxlength);

	return 0;
}

int Native_SetLobbyReservation(Handle plugin, int numParams) // Native "L4D_SetLobbyReservation"
{
	char sTemp[20];
	GetNativeString(1, sTemp, sizeof(sTemp));

	int val1;
	int val2;

	int length = strlen(sTemp);
	if( length > 8 )
	{
		val2 = HexStrToInt(sTemp[length - 8]);
	}

	sTemp[length - 8] = 0;
	val1 = HexStrToInt(sTemp);

	StoreToAddress(g_pServer + view_as<Address>(g_iOff_LobbyReservation + 4), val1, NumberType_Int32, false);
	StoreToAddress(g_pServer + view_as<Address>(g_iOff_LobbyReservation), val2, NumberType_Int32, false);

	return 0;
}

int HexStrToInt(const char[] sTemp)
{
	int i;
	int res;
	char c[2];
	char v[2];

	for( ;; )
	{
		strcopy(c, sizeof(c), sTemp[i++]);
		if( !c[0] ) break;

		v[0] = (c[0] & 0xF) + (c[0] >> 6) | ((c[0] >> 3) & 0x8);
		res = (res << 4) | v[0];
	}

	return res;
}

//DEPRECATED
// int Native_GetCampaignScores(Handle plugin, int numParams) // Native "L4D_GetCampaignScores"
// {}



// ==================================================
// l4d2weapons.inc
// ==================================================
// Pointers
// ==================================================
int GetWeaponPointer()
{
	ValidateAddress(g_pWeaponInfoDatabase, "g_pWeaponInfoDatabase");
	ValidateNatives(g_hSDK_GetWeaponInfo, "GetWeaponInfo");

	static char weaponName[32];
	GetNativeString(1, weaponName, sizeof(weaponName));

	// Add "weapon_" if missing, required for usage with stored StringMap.
	if( strncmp(weaponName, "weapon_", 7) )
	{
		Format(weaponName, sizeof(weaponName), "weapon_%s", weaponName);
	}

	int ptr;
	if( g_aWeaponPtrs.GetValue(weaponName, ptr) == false )
	{
		if( g_aWeaponIDs.GetValue(weaponName, ptr) == false )
		{
			LogError("Invalid weapon name (%s) or weapon unavailable (%d)", weaponName, ptr);
			return -1;
		}

		//PrintToServer("#### CALL g_hSDK_GetWeaponInfo");
		if( ptr ) ptr = SDKCall(g_hSDK_GetWeaponInfo, ptr);
		if( ptr ) g_aWeaponPtrs.SetValue(weaponName, ptr);
	}

	if( ptr ) return ptr;
	return -1;
}

int GetMeleePointer(int id)
{
	ValidateAddress(g_pMeleeWeaponInfoStore, "g_pMeleeWeaponInfoStore");
	ValidateNatives(g_hSDK_CMeleeWeaponInfoStore_GetMeleeWeaponInfo, "CMeleeWeaponInfoStore::GetMeleeWeaponInfo");

	int ptr = g_aMeleePtrs.FindValue(id, 0);
	if( ptr == -1 )
	{
		//PrintToServer("#### CALL g_hSDK_CMeleeWeaponInfoStore_GetMeleeWeaponInfo");
		ptr = SDKCall(g_hSDK_CMeleeWeaponInfoStore_GetMeleeWeaponInfo, g_pMeleeWeaponInfoStore, id);

		if( ptr )
		{
			int vars[2];
			vars[0] = id;
			vars[1] = ptr;
			g_aMeleePtrs.PushArray(vars, 2);
		}
	} else {
		ptr = g_aMeleePtrs.Get(ptr, 1);
	}

	if( ptr == 0 )
	{
		LogStackTrace("Invalid melee ID (%d) or melee unavailable.", id);
		return -1;
	}

	return ptr;
}



// ==================================================
// Natives
// ==================================================
int Native_GetWeaponID(Handle plugin, int numParams) // Native "L4D_GetWeaponID"
{
	static char weaponName[32];
	GetNativeString(1, weaponName, sizeof(weaponName));

	// Add "weapon_" if missing, required for usage with stored StringMap.
	if( strncmp(weaponName, "weapon_", 7) )
	{
		Format(weaponName, sizeof(weaponName), "weapon_%s", weaponName);
	}

	int wepID;

	if( g_aWeaponIDs.GetValue(weaponName, wepID) == false )
	{
		return -1;
	}

	return wepID;
}

int Native_Internal_IsValidWeapon(Handle plugin, int numParams) // Native "L4D2_IsValidWeapon"
{
	return GetWeaponPointer() != -1;
}

int Native_GetIntWeaponAttribute(Handle plugin, int numParams) // Native "L4D2_GetIntWeaponAttribute"
{
	int attr = GetNativeCell(2);
	if( attr >= view_as<int>(MAX_SIZE_L4D2IntWeaponAttributes) ) // view_as to avoid tag mismatch from enum "type"
		ThrowNativeError(SP_ERROR_PARAM, "Invalid attribute id");

	if( !g_bLeft4Dead2 && attr == view_as<int>(L4D2IWA_Tier) )
		ThrowNativeError(SP_ERROR_PARAM, "Attribute \"L4D2IWA_Tier\" only exists in L4D2.");

	int ptr = GetWeaponPointer();
	if( ptr != -1 )
	{
		attr = L4D2IntWeapon_Offsets[attr]; // Offset
		ptr = LoadFromAddress(view_as<Address>(ptr + attr), NumberType_Int32);
	}

	return ptr;
}

any Native_GetFloatWeaponAttribute(Handle plugin, int numParams) // Native "L4D2_GetFloatWeaponAttribute"
{
	int attr = GetNativeCell(2);
	if( attr >= view_as<int>(MAX_SIZE_L4D2FloatWeaponAttributes) ) // view_as to avoid tag mismatch from enum "type"
		ThrowNativeError(SP_ERROR_PARAM, "Invalid attribute id");

	int ptr = GetWeaponPointer();
	if( ptr != -1 )
	{
		attr = L4D2FloatWeapon_Offsets[attr]; // Offset
		ptr = LoadFromAddress(view_as<Address>(ptr + attr), NumberType_Int32);
	}

	return view_as<float>(ptr);
}

int Native_SetIntWeaponAttribute(Handle plugin, int numParams) // Native "L4D2_SetIntWeaponAttribute"
{
	int attr = GetNativeCell(2);
	if( attr >= view_as<int>(MAX_SIZE_L4D2IntWeaponAttributes) ) // view_as to avoid tag mismatch from enum "type"
		ThrowNativeError(SP_ERROR_PARAM, "Invalid attribute id");

	if( !g_bLeft4Dead2 && attr == view_as<int>(L4D2IWA_Tier) )
		ThrowNativeError(SP_ERROR_PARAM, "Attribute \"L4D2IWA_Tier\" only exists in L4D2.");

	int ptr = GetWeaponPointer();
	if( ptr != -1 )
	{
		if( !g_bLeft4Dead2 && attr == view_as<int>(L4D2FWA_PenetrationNumLayers) )
		{
			attr = L4D2IntWeapon_Offsets[attr]; // Offset
			StoreToAddress(view_as<Address>(ptr + attr), RoundToCeil(GetNativeCell(3)), NumberType_Int32, false);
		}
		else
		{
			attr = L4D2IntWeapon_Offsets[attr]; // Offset
			StoreToAddress(view_as<Address>(ptr + attr), GetNativeCell(3), NumberType_Int32, false);
		}
	}

	return ptr;
}

int Native_SetFloatWeaponAttribute(Handle plugin, int numParams) // Native "L4D2_SetFloatWeaponAttribute"
{
	int attr = GetNativeCell(2);
	if( attr >= view_as<int>(MAX_SIZE_L4D2FloatWeaponAttributes) ) // view_as to avoid tag mismatch from enum "type"
		ThrowNativeError(SP_ERROR_PARAM, "Invalid attribute id");

	int ptr = GetWeaponPointer();
	if( ptr != -1 )
	{
		attr = L4D2FloatWeapon_Offsets[attr]; // Offset
		StoreToAddress(view_as<Address>(ptr + attr), GetNativeCell(3), NumberType_Int32, false);
	}

	return ptr;
}

int Native_GetMeleeWeaponIndex(Handle plugin, int numParams) // Native "L4D2_GetMeleeWeaponIndex"
{
	static char weaponName[32];
	GetNativeString(1, weaponName, sizeof(weaponName));

	int ptr;
	if( g_aMeleeIDs.GetValue(weaponName, ptr) == false )
	{
		ptr = -1;
	}

	return ptr;
}

int Native_GetIntMeleeAttribute(Handle plugin, int numParams) // Native "L4D2_GetIntMeleeAttribute"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	int attr = GetNativeCell(2);
	if( attr >= view_as<int>(MAX_SIZE_L4D2IntMeleeWeaponAttributes) ) // view_as to avoid tag mismatch from enum "type"
		ThrowNativeError(SP_ERROR_PARAM, "Invalid attribute id");

	int ptr = GetMeleePointer(GetNativeCell(1));
	if( ptr != -1 )
	{
		attr = L4D2IntMeleeWeapon_Offsets[attr]; // Offset
		ptr = LoadFromAddress(view_as<Address>(ptr + attr), NumberType_Int16);
	}

	return ptr;
}

any Native_GetFloatMeleeAttribute(Handle plugin, int numParams) // Native "L4D2_GetFloatMeleeAttribute"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	int attr = GetNativeCell(2);
	if( attr >= view_as<int>(MAX_SIZE_L4D2FloatMeleeWeaponAttributes) ) // view_as to avoid tag mismatch from enum "type"
		ThrowNativeError(SP_ERROR_PARAM, "Invalid attribute id");

	int ptr = GetMeleePointer(GetNativeCell(1));
	if( ptr != -1 )
	{
		attr = L4D2FloatMeleeWeapon_Offsets[attr]; // Offset
		ptr = LoadFromAddress(view_as<Address>(ptr + attr), NumberType_Int32);
	}

	return view_as<float>(ptr);
}

int Native_GetBoolMeleeAttribute(Handle plugin, int numParams) // Native "L4D2_GetBoolMeleeAttribute"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	int attr = GetNativeCell(2);
	if( attr >= view_as<int>(MAX_SIZE_L4D2BoolMeleeWeaponAttributes) ) // view_as to avoid tag mismatch from enum "type"
		ThrowNativeError(SP_ERROR_PARAM, "Invalid attribute id");

	int ptr = GetMeleePointer(GetNativeCell(1));
	if( ptr != -1 )
	{
		attr = L4D2BoolMeleeWeapon_Offsets[attr]; // Offset
		ptr = LoadFromAddress(view_as<Address>(ptr + attr), NumberType_Int8);
	}

	return ptr;
}

int Native_SetIntMeleeAttribute(Handle plugin, int numParams) // Native "L4D2_SetIntMeleeAttribute"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	int attr = GetNativeCell(2);
	if( attr >= view_as<int>(MAX_SIZE_L4D2IntMeleeWeaponAttributes) ) // view_as to avoid tag mismatch from enum "type"
		ThrowNativeError(SP_ERROR_PARAM, "Invalid attribute id");

	int ptr = GetMeleePointer(GetNativeCell(1));
	if( ptr != -1 )
	{
		int value = GetNativeCell(3);
		attr = L4D2IntMeleeWeapon_Offsets[attr]; // Offset
		StoreToAddress(view_as<Address>(ptr + attr), value, NumberType_Int16, false);
	}

	return 0;
}

int Native_SetFloatMeleeAttribute(Handle plugin, int numParams) // Native "L4D2_SetFloatMeleeAttribute"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	int attr = GetNativeCell(2);
	if( attr >= view_as<int>(MAX_SIZE_L4D2FloatMeleeWeaponAttributes) ) // view_as to avoid tag mismatch from enum "type"
		ThrowNativeError(SP_ERROR_PARAM, "Invalid attribute id");

	int ptr = GetMeleePointer(GetNativeCell(1));
	if( ptr != -1 )
	{
		float value = GetNativeCell(3);
		attr = L4D2FloatMeleeWeapon_Offsets[attr]; // Offset
		StoreToAddress(view_as<Address>(ptr + attr), view_as<int>(value), NumberType_Int32, false);
	}

	return 0;
}

int Native_SetBoolMeleeAttribute(Handle plugin, int numParams) // Native "L4D2_SetBoolMeleeAttribute"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	int attr = GetNativeCell(2);
	if( attr >= view_as<int>(MAX_SIZE_L4D2BoolMeleeWeaponAttributes) ) // view_as to avoid tag mismatch from enum "type"
		ThrowNativeError(SP_ERROR_PARAM, "Invalid attribute id");

	int ptr = GetMeleePointer(GetNativeCell(1));
	if( ptr != -1 )
	{
		bool value = GetNativeCell(3);
		attr = L4D2BoolMeleeWeapon_Offsets[attr]; // Offset
		StoreToAddress(view_as<Address>(ptr + attr), value, NumberType_Int32, false);
	}

	return 0;
}



// ==================================================
// l4d2timers.inc
// ==================================================
// CountdownTimers
// ==================================================
int Native_CTimerReset(Handle plugin, int numParams) // Native "L4D2_CTimerReset"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pDirector, "g_pDirector");

	int id = GetNativeCell(1);
	int off = L4D2CountdownTimer_Offsets[id];
	float timestamp = GetGameTime();

	StoreToAddress(view_as<Address>(off + 8), view_as<int>(timestamp), NumberType_Int32, false);

	return 0;
}

int Native_CTimerStart(Handle plugin, int numParams) // Native "L4D2_CTimerStart"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pDirector, "g_pDirector");

	int id = GetNativeCell(1);
	int off = L4D2CountdownTimer_Offsets[id];
	float duration = GetNativeCell(2);
	float timestamp = GetGameTime() + duration;

	StoreToAddress(view_as<Address>(off + 4), view_as<int>(duration), NumberType_Int32, false);
	StoreToAddress(view_as<Address>(off + 8), view_as<int>(timestamp), NumberType_Int32, false);

	return 0;
}

int Native_CTimerInvalidate(Handle plugin, int numParams) // Native "L4D2_CTimerInvalidate"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pDirector, "g_pDirector");

	int id = GetNativeCell(1);
	int off = L4D2CountdownTimer_Offsets[id];
	float timestamp = -1.0;

	StoreToAddress(view_as<Address>(off + 8), view_as<int>(timestamp), NumberType_Int32, false);

	return 0;
}

int Native_CTimerHasStarted(Handle plugin, int numParams) // Native "L4D2_CTimerHasStarted"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pDirector, "g_pDirector");

	int id = GetNativeCell(1);
	int off = L4D2CountdownTimer_Offsets[id];
	float timestamp = view_as<float>(LoadFromAddress(view_as<Address>(off + 8), NumberType_Int32));

	return (timestamp >= 0.0);
}

int Native_CTimerIsElapsed(Handle plugin, int numParams) // Native "L4D2_CTimerIsElapsed"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pDirector, "g_pDirector");

	int id = GetNativeCell(1);
	int off = L4D2CountdownTimer_Offsets[id];
	float timestamp = view_as<float>(LoadFromAddress(view_as<Address>(off + 8), NumberType_Int32));

	return (GetGameTime() >= timestamp);
}

any Native_CTimerGetElapsedTime(Handle plugin, int numParams) // Native "L4D2_CTimerGetElapsedTime"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pDirector, "g_pDirector");

	int id = GetNativeCell(1);
	int off = L4D2CountdownTimer_Offsets[id];
	float duration = view_as<float>(LoadFromAddress(view_as<Address>(off + 4), NumberType_Int32));
	float timestamp = view_as<float>(LoadFromAddress(view_as<Address>(off + 8), NumberType_Int32));

	return GetGameTime() - timestamp + duration;
}

any Native_CTimerGetRemainingTime(Handle plugin, int numParams) // Native "L4D2_CTimerGetRemainingTime"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pDirector, "g_pDirector");

	int id = GetNativeCell(1);
	int off = L4D2CountdownTimer_Offsets[id];
	float timestamp = view_as<float>(LoadFromAddress(view_as<Address>(off + 8), NumberType_Int32));

	return (timestamp - GetGameTime());
}

any Native_CTimerGetCountdownDuration(Handle plugin, int numParams) // Native "L4D2_CTimerGetCountdownDuration"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pDirector, "g_pDirector");

	int id = GetNativeCell(1);
	int off = L4D2CountdownTimer_Offsets[id];
	float duration = view_as<float>(LoadFromAddress(view_as<Address>(off + 4), NumberType_Int32));
	float timestamp = view_as<float>(LoadFromAddress(view_as<Address>(off + 8), NumberType_Int32));

	return (timestamp > 0.0) ? duration : 0.0;
}

// ==================================================
// IntervalTimers
// ==================================================
int Native_ITimerStart(Handle plugin, int numParams) // Native "L4D2_ITimerStart"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pDirector, "g_pDirector");

	int id = GetNativeCell(1);
	int off = L4D2IntervalTimer_Offsets[id];
	float timestamp = GetGameTime();

	StoreToAddress(view_as<Address>(off + 4), view_as<int>(timestamp), NumberType_Int32, false);

	return 0;
}

int Native_ITimerInvalidate(Handle plugin, int numParams) // Native "L4D2_ITimerInvalidate"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pDirector, "g_pDirector");

	int id = GetNativeCell(1);
	int off = L4D2IntervalTimer_Offsets[id];
	float timestamp = -1.0;

	StoreToAddress(view_as<Address>(off + 4), view_as<int>(timestamp), NumberType_Int32, false);

	return 0;
}

int Native_ITimerHasStarted(Handle plugin, int numParams) // Native "L4D2_ITimerHasStarted"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pDirector, "g_pDirector");

	int id = GetNativeCell(1);
	int off = L4D2IntervalTimer_Offsets[id];
	float timestamp = view_as<float>(LoadFromAddress(view_as<Address>(off + 4), NumberType_Int32));

	return (timestamp > 0.0);
}

any Native_ITimerGetElapsedTime(Handle plugin, int numParams) // Native "L4D2_ITimerGetElapsedTime"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pDirector, "g_pDirector");

	int id = GetNativeCell(1);
	int off = L4D2IntervalTimer_Offsets[id];
	float timestamp = view_as<float>(LoadFromAddress(view_as<Address>(off + 4), NumberType_Int32));

	return (timestamp > 0.0 ? (GetGameTime() - timestamp) : 99999.9);
}



// ==================================================
// l4d2director.inc
// ==================================================
int Native_GetTankCount(Handle plugin, int numParams) // Native "L4D2_GetTankCount"
{
	int val;

	if( g_bLeft4Dead2 )
	{
		ValidateAddress(g_pDirector, "g_pDirector");
		val = LoadFromAddress(g_pDirector + view_as<Address>(g_iOff_m_iTankCount), NumberType_Int32);
	} else {
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i) && GetEntProp(i, Prop_Send, "m_zombieClass") == g_iClassTank )
			{
				val++;
			}
		}
	}

	return val;
}

int Native_GetWitchCount(Handle plugin, int numParams) // Native "L4D2_GetWitchCount"
{
	int val;

	if( g_bLeft4Dead2 )
	{
		ValidateAddress(g_pDirector, "g_pDirector");

		val = LoadFromAddress(g_pDirector + view_as<Address>(g_iOff_m_iWitchCount), NumberType_Int32);
	} else {
		int entity = -1;
		while( (entity = FindEntityByClassname(entity, "witch")) != INVALID_ENT_REFERENCE )
		{
			val++;
		}
	}

	return val;
}

int Native_GetCurrentChapter(Handle plugin, int numParams) // Native "L4D_GetCurrentChapter"
{
	ValidateAddress(g_iOff_m_chapter, "m_chapter");

	return LoadFromAddress(g_pDirector + view_as<Address>(g_iOff_m_chapter), NumberType_Int32) + 1;
}

int Native_GetAllNavAreas(Handle plugin, int numParams) // Native "L4D_GetAllNavAreas"
{
	ValidateAddress(g_pTheNavAreas_List, "g_pTheNavAreas_List");
	ValidateAddress(g_pTheNavAreas_Size, "g_pTheNavAreas_Size");

	ArrayList aList = GetNativeCell(1);

	int size = LoadFromAddress(g_pTheNavAreas_Size, NumberType_Int32);

	if( aList )
	{
		for( int i = 0; i < size; i++ )
		{
			aList.Push(LoadFromAddress(g_pTheNavAreas_List + view_as<Address>(i * 4), NumberType_Int32));
		}
	}

	return 0;
}

int Native_GetNavAreaID(Handle plugin, int numParams) // Native "L4D_GetNavAreaID"
{
	Address area = GetNativeCell(1);

	return LoadFromAddress(area + view_as<Address>(g_iOff_NavAreaID), NumberType_Int32);
}

any Native_GetNavAreaByID(Handle plugin, int numParams) // Native "L4D_GetNavAreaByID"
{
	ValidateAddress(g_pTheNavAreas_List, "g_pTheNavAreas_List");
	ValidateAddress(g_pTheNavAreas_Size, "g_pTheNavAreas_Size");

	int area = GetNativeCell(1);

	Address test;

	int size = LoadFromAddress(g_pTheNavAreas_Size, NumberType_Int32);

	for( int i = 0; i < size; i++ )
	{
		test = LoadFromAddress(g_pTheNavAreas_List + view_as<Address>(i * 4), NumberType_Int32);
		if( LoadFromAddress(test + view_as<Address>(g_iOff_NavAreaID), NumberType_Int32) == area )
		{
			return test;
		}
	}

	return Address_Null;
}

int Native_GetNavAreaPos(Handle plugin, int numParams) // Native "L4D_GetNavAreaPos"
{
	Address area = GetNativeCell(1);

	float vPos[3];

	vPos[0] = view_as<float>(LoadFromAddress(area + view_as<Address>(4), NumberType_Int32));
	vPos[1] = view_as<float>(LoadFromAddress(area + view_as<Address>(8), NumberType_Int32));
	vPos[2] = view_as<float>(LoadFromAddress(area + view_as<Address>(12), NumberType_Int32));

	SetNativeArray(2, vPos, sizeof(vPos));

	return 0;
}

int Native_GetNavAreaSize(Handle plugin, int numParams) // Native "L4D_GetNavAreaSize"
{
	Address area = GetNativeCell(1);

	float vPos[3];

	vPos[0] = view_as<float>(LoadFromAddress(area + view_as<Address>(4), NumberType_Int32));
	vPos[1] = view_as<float>(LoadFromAddress(area + view_as<Address>(8), NumberType_Int32));
	vPos[2] = view_as<float>(LoadFromAddress(area + view_as<Address>(12), NumberType_Int32));

	float vSize[3];

	vSize[0] = view_as<float>(LoadFromAddress(area + view_as<Address>(16), NumberType_Int32)) - vPos[0];
	vSize[1] = view_as<float>(LoadFromAddress(area + view_as<Address>(20), NumberType_Int32)) - vPos[1];
	vSize[2] = view_as<float>(LoadFromAddress(area + view_as<Address>(24), NumberType_Int32)) - vPos[2];

	SetNativeArray(2, vSize, sizeof(vSize));

	return 0;
}

int Native_GetTerrorNavArea_Attributes(Handle plugin, int numParams) // Native "L4D_GetNavArea_SpawnAttributes"
{
	int area = GetNativeCell(1);
	return GetTerrorNavArea_Attributes(area);
}

int GetTerrorNavArea_Attributes(any area)
{
	ValidateAddress(g_iOff_m_spawnAttributes, "m_spawnAttributes");

	return LoadFromAddress(view_as<Address>(area + g_iOff_m_spawnAttributes), NumberType_Int32);
}

int Native_SetTerrorNavArea_Attributes(Handle plugin, int numParams) // Native "L4D_SetNavArea_SpawnAttributes"
{
	ValidateAddress(g_iOff_m_spawnAttributes, "m_spawnAttributes");

	int area = GetNativeCell(1);
	int flags = GetNativeCell(2);

	StoreToAddress(view_as<Address>(area + g_iOff_m_spawnAttributes), flags, NumberType_Int32);

	return 0;
}

int Native_GetCNavArea_AttributeFlags(Handle plugin, int numParams) // Native "L4D_GetNavArea_AttributeFlags"
{
	ValidateAddress(g_iOff_m_attributeFlags, "m_attributeFlags");

	int area = GetNativeCell(1);

	return LoadFromAddress(view_as<Address>(area + g_iOff_m_attributeFlags), NumberType_Int32);
}

int Native_SetCNavArea_AttributeFlags(Handle plugin, int numParams) // Native "L4D_SetNavArea_AttributeFlags"
{
	ValidateAddress(g_iOff_m_attributeFlags, "m_attributeFlags");

	int area = GetNativeCell(1);
	int flags = GetNativeCell(2);

	StoreToAddress(view_as<Address>(area + g_iOff_m_attributeFlags), flags, NumberType_Int32);

	return 0;
}

int Native_CTerrorGameRules_GetNumChaptersForMissionAndMode(Handle plugin, int numParams) // Native "L4D_GetMaxChapters"
{
	if( g_bLeft4Dead2 )
	{
		ValidateNatives(g_hSDK_CTerrorGameRules_GetNumChaptersForMissionAndMode, "CTerrorGameRules::GetNumChaptersForMissionAndMode");

		//PrintToServer("#### CALL g_hSDK_CTerrorGameRules_GetNumChaptersForMissionAndMode");
		return SDKCall(g_hSDK_CTerrorGameRules_GetNumChaptersForMissionAndMode);
	} else {
		if( g_iMaxChapters == 0 )
		{
			ValidateNatives(g_hSDK_KeyValues_GetString, "KeyValues::GetString");
			ValidateNatives(g_hSDK_CTerrorGameRules_GetMissionInfo, "CTerrorGameRules::GetMissionInfo");

			//PrintToServer("#### CALL g_hSDK_CTerrorGameRules_GetMissionInfo");
			int infoPointer = SDKCall(g_hSDK_CTerrorGameRules_GetMissionInfo);
			ValidateAddress(infoPointer, "CTerrorGameRules::GetMissionInfo");

			char sMode[64];
			char sTemp[64];
			char sRet[64];
			g_hCvar_MPGameMode.GetString(sMode, sizeof(sMode));

			int index = 1;
			while( index < 20 )
			{
				FormatEx(sTemp, sizeof(sTemp), "modes/%s/%d/Map", sMode, index);

				//PrintToServer("#### CALL g_hSDK_KeyValues_GetString");
				SDKCall(g_hSDK_KeyValues_GetString, infoPointer, sRet, sizeof(sRet), sTemp, "");

				if( strcmp(sRet, "") == 0 )
				{
					g_iMaxChapters = index - 1;
					return g_iMaxChapters;
				}

				index++;
			}
		} else {
			return g_iMaxChapters;
		}
	}

	return 0;
}

int Native_CDirector_IsFinaleEscapeInProgress(Handle plugin, int numParams) // Native "L4D_IsFinaleEscapeInProgress"
{
	ValidateNatives(g_hSDK_CDirector_IsFinaleEscapeInProgress, "CDirector::IsFinaleEscapeInProgress");
	ValidateAddress(g_pDirector, "g_pDirector");

	//PrintToServer("#### CALL g_hSDK_CDirector_IsFinaleEscapeInProgress");
	return SDKCall(g_hSDK_CDirector_IsFinaleEscapeInProgress, g_pDirector);
}

int Native_SurvivorBot_SetHumanSpectator(Handle plugin, int numParams) // Native "L4D_SetHumanSpec"
{
	ValidateNatives(g_hSDK_SurvivorBot_SetHumanSpectator, "SurvivorBot::SetHumanSpectator");

	int bot = GetNativeCell(1);
	int client = GetNativeCell(2);

	//PrintToServer("#### CALL g_hSDK_SurvivorBot_SetHumanSpectator");
	return SDKCall(g_hSDK_SurvivorBot_SetHumanSpectator, bot, client);
}

int Native_CTerrorPlayer_TakeOverBot(Handle plugin, int numParams) // Native "L4D_TakeOverBot"
{
	ValidateNatives(g_hSDK_CTerrorPlayer_TakeOverBot, "CTerrorPlayer::TakeOverBot");

	int client = GetNativeCell(1);

	//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_TakeOverBot");
	return SDKCall(g_hSDK_CTerrorPlayer_TakeOverBot, client, true);
}

int Native_CTerrorPlayer_CanBecomeGhost(Handle plugin, int numParams) // Native "L4D_CanBecomeGhost"
{
	ValidateNatives(g_hSDK_CTerrorPlayer_CanBecomeGhost, "CTerrorPlayer::CanBecomeGhost");

	int client = GetNativeCell(1);

	//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_CanBecomeGhost");
	return SDKCall(g_hSDK_CTerrorPlayer_CanBecomeGhost, client, true);
}

int Native_CTerrorPlayer_SetBecomeGhostAt(Handle plugin, int numParams) // Native "L4D_SetBecomeGhostAt"
{
	ValidateNatives(g_hSDK_CTerrorPlayer_SetBecomeGhostAt, "CTerrorPlayer::SetBecomeGhostAt");

	int client = GetNativeCell(1);
	float time = GetNativeCell(2);

	//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_SetBecomeGhostAt");
	SDKCall(g_hSDK_CTerrorPlayer_SetBecomeGhostAt, client, time);

	return 0;
}

int Native_CTerrorPlayer_GoAwayFromKeyboard(Handle plugin, int numParams) // Native "L4D_GoAwayFromKeyboard"
{
	ValidateNatives(g_hSDK_CTerrorPlayer_GoAwayFromKeyboard, "CTerrorPlayer::GoAwayFromKeyboard");

	int client = GetNativeCell(1);

	//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_GoAwayFromKeyboard");
	return SDKCall(g_hSDK_CTerrorPlayer_GoAwayFromKeyboard, client);
}

int Native_CDirector_AreWanderersAllowed(Handle plugin, int numParams) // Native "L4D2_AreWanderersAllowed"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateNatives(g_hSDK_CDirector_AreWanderersAllowed, "CDirector::AreWanderersAllowed");
	ValidateAddress(g_pDirector, "g_pDirector");

	//PrintToServer("#### CALL g_hSDK_CDirector_AreWanderersAllowed");
	return SDKCall(g_hSDK_CDirector_AreWanderersAllowed, g_pDirector);
}

int Native_GetVersusCampaignScores(Handle plugin, int numParams) // Native "L4D2_GetVersusCampaignScores"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pVersusMode, "VersusModePtr");
	ValidateAddress(g_pVersusMode, "m_iCampaignScores");

	int vals[2];
	vals[0] = LoadFromAddress(view_as<Address>(g_pVersusMode + g_iOff_m_iCampaignScores), NumberType_Int32);
	vals[1] = LoadFromAddress(view_as<Address>(g_pVersusMode + g_iOff_m_iCampaignScores + 4), NumberType_Int32);
	SetNativeArray(1, vals, 2);

	return 0;
}

int Native_SetVersusCampaignScores(Handle plugin, int numParams) // Native "L4D2_SetVersusCampaignScores"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pVersusMode, "VersusModePtr");
	ValidateAddress(g_pVersusMode, "m_iCampaignScores");

	int vals[2];
	GetNativeArray(1, vals, sizeof(vals));
	StoreToAddress(view_as<Address>(g_pVersusMode + g_iOff_m_iCampaignScores), vals[0], NumberType_Int32, false);
	StoreToAddress(view_as<Address>(g_pVersusMode + g_iOff_m_iCampaignScores + 4), vals[1], NumberType_Int32, false);

	return 0;
}

int Native_GetVersusTankFlowPercent(Handle plugin, int numParams) // Native "L4D2_GetVersusTankFlowPercent"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pVersusMode, "VersusModePtr");
	ValidateAddress(g_pVersusMode, "m_fTankSpawnFlowPercent");

	float vals[2];
	vals[0] = view_as<float>(LoadFromAddress(view_as<Address>(g_pVersusMode + g_iOff_m_fTankSpawnFlowPercent), NumberType_Int32));
	vals[1] = view_as<float>(LoadFromAddress(view_as<Address>(g_pVersusMode + g_iOff_m_fTankSpawnFlowPercent + 4), NumberType_Int32));
	SetNativeArray(1, vals, 2);

	return 0;
}

int Native_SetVersusTankFlowPercent(Handle plugin, int numParams) // Native "L4D2_SetVersusTankFlowPercent"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pVersusMode, "VersusModePtr");
	ValidateAddress(g_pVersusMode, "m_fTankSpawnFlowPercent");

	float vals[2];
	GetNativeArray(1, vals, sizeof(vals));
	StoreToAddress(view_as<Address>(g_pVersusMode + g_iOff_m_fTankSpawnFlowPercent), view_as<int>(vals[0]), NumberType_Int32, false);
	StoreToAddress(view_as<Address>(g_pVersusMode + g_iOff_m_fTankSpawnFlowPercent + 4), view_as<int>(vals[1]), NumberType_Int32, false);

	return 0;
}

int Native_GetVersusWitchFlowPercent(Handle plugin, int numParams) // Native "L4D2_GetVersusWitchFlowPercent"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pVersusMode, "VersusModePtr");
	ValidateAddress(g_pVersusMode, "m_fWitchSpawnFlowPercent");

	float vals[2];
	vals[0] = view_as<float>(LoadFromAddress(view_as<Address>(g_pVersusMode + g_iOff_m_fWitchSpawnFlowPercent), NumberType_Int32));
	vals[1] = view_as<float>(LoadFromAddress(view_as<Address>(g_pVersusMode + g_iOff_m_fWitchSpawnFlowPercent + 4), NumberType_Int32));
	SetNativeArray(1, vals, 2);

	return 0;
}

int Native_SetVersusWitchFlowPercent(Handle plugin, int numParams) // Native "L4D2_SetVersusWitchFlowPercent"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pVersusMode, "VersusModePtr");
	ValidateAddress(g_pVersusMode, "m_fWitchSpawnFlowPercent");

	float vals[2];
	GetNativeArray(1, vals, sizeof(vals));
	StoreToAddress(view_as<Address>(g_pVersusMode + g_iOff_m_fWitchSpawnFlowPercent), view_as<int>(vals[0]), NumberType_Int32, false);
	StoreToAddress(view_as<Address>(g_pVersusMode + g_iOff_m_fWitchSpawnFlowPercent + 4), view_as<int>(vals[1]), NumberType_Int32, false);

	return 0;
}





// ==================================================
// l4d_direct.inc
// ==================================================
int Direct_GetTankCount(Handle plugin, int numParams) // Native "L4D2Direct_GetTankCount"
{
	return Native_GetTankCount(plugin, numParams);
}

int Direct_GetPendingMobCount(Handle plugin, int numParams) // Native "L4D2Direct_GetPendingMobCount"
{
	ValidateAddress(g_pZombieManager, "g_pZombieManager");
	ValidateAddress(g_iOff_m_PendingMobCount, "m_PendingMobCount");

	return LoadFromAddress(g_pZombieManager + view_as<Address>(g_iOff_m_PendingMobCount), NumberType_Int32);
}

int Direct_SetPendingMobCount(Handle plugin, int numParams) // Native "L4D2Direct_SetPendingMobCount"
{
	ValidateAddress(g_pZombieManager, "g_pZombieManager");
	ValidateAddress(g_iOff_m_PendingMobCount, "m_PendingMobCount");

	int count = GetNativeCell(1);
	StoreToAddress(g_pZombieManager + view_as<Address>(g_iOff_m_PendingMobCount), count, NumberType_Int32, false);

	return 0;
}

any Direct_GetMobSpawnTimer(Handle plugin, int numParams) // Native "L4D2Direct_GetMobSpawnTimer"
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateAddress(g_iOff_MobSpawnTimer, "MobSpawnTimer");

	return view_as<CountdownTimer>(g_pDirector + view_as<Address>(g_iOff_MobSpawnTimer));
}

any Direct_GetSIClassDeathTimer(Handle plugin, int numParams) // Native "L4D2Direct_GetSIClassDeathTimer"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pDirector, "g_pDirector");

	int class = GetNativeCell(1);
	if( class < 1 || class > 6 ) return CTimer_Null;

	int offset = L4D2IntervalTimer_Offsets[class];
	return view_as<IntervalTimer>(view_as<Address>(offset));
}

any Direct_GetSIClassSpawnTimer(Handle plugin, int numParams) // Native "L4D2Direct_GetSIClassSpawnTimer"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pDirector, "g_pDirector");

	int class = GetNativeCell(1);
	if( class < 1 || class > 6 ) return CTimer_Null;

	int offset = L4D2CountdownTimer_Offsets[class];
	return view_as<CountdownTimer>(view_as<Address>(offset));
}

int Direct_GetTankPassedCount(Handle plugin, int numParams) // Native "L4D2Direct_GetTankPassedCount"
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateAddress(g_pDirector, "m_iTankPassedCount");

	return LoadFromAddress(g_pDirector + view_as<Address>(g_iOff_m_iTankPassedCount), NumberType_Int32);
}

int Direct_SetTankPassedCount(Handle plugin, int numParams) // Native "L4D2Direct_SetTankPassedCount"
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateAddress(g_pDirector, "m_iTankPassedCount");

	int passes = GetNativeCell(1);
	StoreToAddress(g_pDirector + view_as<Address>(g_iOff_m_iTankPassedCount), passes, NumberType_Int32, false);

	return 0;
}

int Direct_GetVSCampaignScore(Handle plugin, int numParams) // Native "L4D2Direct_GetVSCampaignScore"
{
	ValidateAddress(g_pVersusMode, "VersusModePtr");
	ValidateAddress(g_iOff_m_iCampaignScores, "m_iCampaignScores");

	int team = GetNativeCell(1);
	if( team < 0 || team > 1 ) return -1;

	return LoadFromAddress(view_as<Address>(g_pVersusMode + g_iOff_m_iCampaignScores + (team * 4)), NumberType_Int32);
}

int Direct_SetVSCampaignScore(Handle plugin, int numParams) // Native "L4D2Direct_SetVSCampaignScore"
{
	ValidateAddress(g_pVersusMode, "VersusModePtr");
	ValidateAddress(g_iOff_m_iCampaignScores, "m_iCampaignScores");

	int team = GetNativeCell(1);
	if( team < 0 || team > 1 ) return 0;

	int score = GetNativeCell(2);
	StoreToAddress(view_as<Address>(g_pVersusMode + g_iOff_m_iCampaignScores + (team * 4)), score, NumberType_Int32, false);

	return 0;
}

any Direct_GetVSTankFlowPercent(Handle plugin, int numParams) // Native "L4D2Direct_GetVSTankFlowPercent"
{
	ValidateAddress(g_pVersusMode, "VersusModePtr");
	ValidateAddress(g_iOff_m_fTankSpawnFlowPercent, "m_fTankSpawnFlowPercent");

	int round = GetNativeCell(1);
	if( round < 0 || round > 1 ) return -1.0;

	int team = round ^ GameRules_GetProp("m_bInSecondHalfOfRound") != GameRules_GetProp("m_bAreTeamsFlipped");

	return LoadFromAddress(view_as<Address>(g_pVersusMode + g_iOff_m_fTankSpawnFlowPercent + (team * 4)), NumberType_Int32);
}

int Direct_SetVSTankFlowPercent(Handle plugin, int numParams) // Native "L4D2Direct_SetVSTankFlowPercent"
{
	ValidateAddress(g_pVersusMode, "VersusModePtr");
	ValidateAddress(g_iOff_m_fTankSpawnFlowPercent, "m_fTankSpawnFlowPercent");

	int round = GetNativeCell(1);
	if( round < 0 || round > 1 ) return 0;

	int team = round ^ GameRules_GetProp("m_bInSecondHalfOfRound") != GameRules_GetProp("m_bAreTeamsFlipped");
	float flow = GetNativeCell(2);

	StoreToAddress(view_as<Address>(g_pVersusMode + g_iOff_m_fTankSpawnFlowPercent + (team * 4)), view_as<int>(flow), NumberType_Int32, false);

	return 0;
}

int Direct_GetVSTankToSpawnThisRound(Handle plugin, int numParams) // Native "L4D2Direct_GetVSTankToSpawnThisRound"
{
	ValidateAddress(g_pVersusMode, "VersusModePtr");
	ValidateAddress(g_iOff_m_bTankThisRound, "m_bTankThisRound");

	int round = GetNativeCell(1);
	if( round < 0 || round > 1 ) return false;

	int team = round ^ GameRules_GetProp("m_bInSecondHalfOfRound") != GameRules_GetProp("m_bAreTeamsFlipped");

	return LoadFromAddress(view_as<Address>(g_pVersusMode + g_iOff_m_bTankThisRound + team), NumberType_Int8);
}

int Direct_SetVSTankToSpawnThisRound(Handle plugin, int numParams) // Native "L4D2Direct_SetVSTankToSpawnThisRound"
{
	ValidateAddress(g_pVersusMode, "VersusModePtr");
	ValidateAddress(g_iOff_m_bTankThisRound, "m_bTankThisRound");

	int round = GetNativeCell(1);
	if( round < 0 || round > 1 ) return 0;

	int team = round ^ GameRules_GetProp("m_bInSecondHalfOfRound") != GameRules_GetProp("m_bAreTeamsFlipped");
	bool spawn = GetNativeCell(2);

	StoreToAddress(view_as<Address>(g_pVersusMode + g_iOff_m_bTankThisRound + team), spawn, NumberType_Int8, false);

	return 0;
}

any Direct_GetVSWitchFlowPercent(Handle plugin, int numParams) // Native "L4D2Direct_GetVSWitchFlowPercent"
{
	ValidateAddress(g_pVersusMode, "VersusModePtr");
	ValidateAddress(g_iOff_m_fWitchSpawnFlowPercent, "m_fWitchSpawnFlowPercent");

	int round = GetNativeCell(1);
	if( round < 0 || round > 1 ) return false;

	int team = round ^ GameRules_GetProp("m_bInSecondHalfOfRound") != GameRules_GetProp("m_bAreTeamsFlipped");

	return LoadFromAddress(view_as<Address>(g_pVersusMode + g_iOff_m_fWitchSpawnFlowPercent + (team * 4)), NumberType_Int32);
}

int Direct_SetVSWitchFlowPercent(Handle plugin, int numParams) // Native "L4D2Direct_SetVSWitchFlowPercent"
{
	ValidateAddress(g_pVersusMode, "VersusModePtr");
	ValidateAddress(g_iOff_m_fWitchSpawnFlowPercent, "m_fWitchSpawnFlowPercent");

	int round = GetNativeCell(1);
	if( round < 0 || round > 1 ) return 0;

	int team = round ^ GameRules_GetProp("m_bInSecondHalfOfRound") != GameRules_GetProp("m_bAreTeamsFlipped");
	float flow = GetNativeCell(2);

	StoreToAddress(view_as<Address>(g_pVersusMode + g_iOff_m_fWitchSpawnFlowPercent + (team * 4)), view_as<int>(flow), NumberType_Int32, false);

	return 0;
}

int Direct_GetVSWitchToSpawnThisRound(Handle plugin, int numParams) // Native "L4D2Direct_GetVSWitchToSpawnThisRound"
{
	ValidateAddress(g_pVersusMode, "VersusModePtr");
	ValidateAddress(g_iOff_m_bWitchThisRound, "m_bWitchThisRound");

	int round = GetNativeCell(1);
	if( round < 0 || round > 1 ) return false;

	int team = round ^ GameRules_GetProp("m_bInSecondHalfOfRound") != GameRules_GetProp("m_bAreTeamsFlipped");

	return LoadFromAddress(view_as<Address>(g_pVersusMode + g_iOff_m_bWitchThisRound + team), NumberType_Int8);
}

int Direct_SetVSWitchToSpawnThisRound(Handle plugin, int numParams) // Native "L4D2Direct_SetVSWitchToSpawnThisRound"
{
	ValidateAddress(g_pVersusMode, "VersusModePtr");
	ValidateAddress(g_iOff_m_bWitchThisRound, "m_bWitchThisRound");

	int round = GetNativeCell(1);
	if( round < 0 || round > 1 ) return 0;

	int team = round ^ GameRules_GetProp("m_bInSecondHalfOfRound") != GameRules_GetProp("m_bAreTeamsFlipped");
	bool spawn = GetNativeCell(2);

	StoreToAddress(view_as<Address>(g_pVersusMode + g_iOff_m_bWitchThisRound + team), spawn, NumberType_Int8, false);

	return 0;
}

any Direct_GetVSStartTimer(Handle plugin, int numParams) // Native "L4D2Direct_GetVSStartTimer"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pVersusMode, "VersusModePtr");

	int offset;

	if( g_bLeft4Dead2 )
		offset = L4D2CountdownTimer_Offsets[7]; // L4D2CountdownTimer_VersusStartTimer
	else
		offset = g_pVersusMode + g_iOff_VersusStartTimer;

	ValidateAddress(offset, "VersusStartTimer");
	return view_as<CountdownTimer>(view_as<Address>(offset));
}

any Direct_GetScavengeRoundSetupTimer(Handle plugin, int numParams) // Native "L4D2Direct_GetScavengeRoundSetupTimer"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pScavengeMode, "ScavengeModePtr");
	ValidateAddress(g_iOff_OnBeginRoundSetupTime, "OnBeginRoundSetupTime");

	return view_as<CountdownTimer>(view_as<Address>(g_pScavengeMode + g_iOff_OnBeginRoundSetupTime));
}

any Direct_GetScavengeOvertimeGraceTimer(Handle plugin, int numParams) // Native "L4D2Direct_GetScavengeOvertimeGraceTimer"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pScavengeMode, "ScavengeModePtr");
	ValidateAddress(g_iOff_OvertimeGraceTimer, "OvertimeGraceTimer");

	return view_as<CountdownTimer>(view_as<Address>(g_pScavengeMode + g_iOff_OvertimeGraceTimer));
}

any Direct_GetMapMaxFlowDistance(Handle plugin, int numParams) // Native "L4D2Direct_GetMapMaxFlowDistance"
{
	ValidateAddress(g_pNavMesh, "g_pNavMesh");
	ValidateAddress(g_iOff_m_fMapMaxFlowDistance, "m_fMapMaxFlowDistance");

	return LoadFromAddress(g_pNavMesh + view_as<Address>(g_iOff_m_fMapMaxFlowDistance), NumberType_Int32);
}

any Direct_GetSpawnTimer(Handle plugin, int numParams) // Native "L4D2Direct_GetSpawnTimer"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_iOff_SpawnTimer, "SpawnTimer");

	int client = GetNativeCell(1);
	if( client < 1 || client > MaxClients )
		return CTimer_Null;

	Address pEntity = GetEntityAddress(client);
	if( pEntity == Address_Null )
		return CTimer_Null;

	return view_as<CountdownTimer>(pEntity + view_as<Address>(g_iOff_SpawnTimer));
}

any Direct_GetInvulnerabilityTimer(Handle plugin, int numParams) // Native "L4D2Direct_GetInvulnerabilityTimer"
{
	ValidateAddress(g_iOff_InvulnerabilityTimer, "InvulnerabilityTimer");

	int client = GetNativeCell(1);
	if( client < 1 || client > MaxClients )
		return CTimer_Null;

	Address pEntity = GetEntityAddress(client);
	if( pEntity == Address_Null )
		return CTimer_Null;

	return view_as<CountdownTimer>(pEntity + view_as<Address>(g_iOff_InvulnerabilityTimer));
}

int Direct_GetTankTickets(Handle plugin, int numParams) // Native "L4D2Direct_GetTankTickets"
{
	ValidateAddress(g_iOff_m_iTankTickets, "m_iTankTickets");

	int client = GetNativeCell(1);
	if( client < 1 || client > MaxClients )
		return -1;

	Address pEntity = GetEntityAddress(client);
	if( pEntity == Address_Null )
		return -1;

	return LoadFromAddress(pEntity + view_as<Address>(g_iOff_m_iTankTickets), NumberType_Int32);
}

int Direct_SetTankTickets(Handle plugin, int numParams) // Native "L4D2Direct_SetTankTickets"
{
	ValidateAddress(g_iOff_m_iTankTickets, "m_iTankTickets");

	int client = GetNativeCell(1);
	if( client < 1 || client > MaxClients )
		return 0;

	Address pEntity = GetEntityAddress(client);
	if( pEntity == Address_Null )
		return 0;

	int tickets = GetNativeCell(2);
	StoreToAddress(pEntity + view_as<Address>(g_iOff_m_iTankTickets), tickets, NumberType_Int32, false);

	return 0;
}

int Direct_GetShovePenalty(Handle plugin, int numParams) // Native "L4D2Direct_GetShovePenalty"
{
	int client = GetNativeCell(1);
	if( client < 1 || client > MaxClients )
		return -1;

	return GetEntProp(client, Prop_Send, "m_iShovePenalty");

	/*
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_iOff_m_iShovePenalty, "m_iShovePenalty");

	Address pEntity = GetEntityAddress(client);
	if( pEntity == Address_Null )
		return -1;

	return LoadFromAddress(pEntity + view_as<Address>(g_iOff_m_iShovePenalty), NumberType_Int32);
	*/
}

int Direct_SetShovePenalty(Handle plugin, int numParams) // Native "L4D2Direct_SetShovePenalty"
{
	int client = GetNativeCell(1);
	if( client < 1 || client > MaxClients )
		return 0;

	int penalty = GetNativeCell(2);

	SetEntProp(client, Prop_Send, "m_iShovePenalty", penalty);

	/*
	ValidateNatives(g_hSDK_CTerrorPlayer_SetShovePenalty, "CTerrorPlayer::SetShovePenalty");

	//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_SetShovePenalty");
	SDKCall(g_hSDK_CTerrorPlayer_SetShovePenalty, client, penalty);
	*/

	/* Version before SDKCall method
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_iOff_m_iShovePenalty, "m_iShovePenalty");

	Address pEntity = GetEntityAddress(client);
	if( pEntity == Address_Null )
		return 0;

	int penalty = GetNativeCell(2);

	StoreToAddress(pEntity + view_as<Address>(g_iOff_m_iShovePenalty), penalty, NumberType_Int32, false);
	*/

	return 0;
}

any Direct_GetNextShoveTime(Handle plugin, int numParams) // Native "L4D2Direct_GetNextShoveTime"
{
	int client = GetNativeCell(1);
	if( client < 1 || client > MaxClients )
		return 0.0;

	return GetEntPropFloat(client, Prop_Send, "m_flNextShoveTime");

	/*
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_iOff_m_fNextShoveTime, "m_fNextShoveTime");

	Address pEntity = GetEntityAddress(client);
	if( pEntity == Address_Null )
		return 0.0;

	return LoadFromAddress(pEntity + view_as<Address>(g_iOff_m_fNextShoveTime), NumberType_Int32);
	*/
}

int Direct_SetNextShoveTime(Handle plugin, int numParams) // Native "L4D2Direct_SetNextShoveTime"
{
	// if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	int client = GetNativeCell(1);
	if( client < 1 || client > MaxClients )
		return 0;

	int weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	if( weapon != -1 )
	{
		float time = GetNativeCell(2);

		SetEntData(weapon, g_iAttackTimer + 4, 0.0);
		SetEntData(weapon, g_iAttackTimer + 8, time);

		SetEntPropFloat(client, Prop_Send, "m_flNextShoveTime", time);
		SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", time);

		// SDKCall(g_hSDK_CTerrorPlayer_SetNextShoveTime , client, time);
	}

	// SDKCall(g_hSDK_CTerrorPlayer_SetNextShoveTime , client, time);

	/* Version before SDKCall method
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_iOff_m_fNextShoveTime, "m_fNextShoveTime");
	*/

	/* Version before SDKCall method
	Address pEntity = GetEntityAddress(client);
	if( pEntity == Address_Null )
		return 0;

	float time = GetNativeCell(2);

	StoreToAddress(pEntity + view_as<Address>(g_iOff_m_fNextShoveTime), view_as<int>(time), NumberType_Int32, false);
	*/

	return 0;
}

int Direct_GetPreIncapHealth(Handle plugin, int numParams) // Native "L4D2Direct_GetPreIncapHealth"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_iOff_m_preIncapacitatedHealth, "m_preIncapacitatedHealth");

	int client = GetNativeCell(1);
	if( client < 1 || client > MaxClients )
		return -1;

	Address pEntity = GetEntityAddress(client);
	if( pEntity == Address_Null )
		return -1;

	return LoadFromAddress(pEntity + view_as<Address>(g_iOff_m_preIncapacitatedHealth), NumberType_Int32);
}

int Direct_SetPreIncapHealth(Handle plugin, int numParams) // Native "L4D2Direct_SetPreIncapHealth"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_iOff_m_preIncapacitatedHealth, "m_preIncapacitatedHealth");

	int client = GetNativeCell(1);
	if( client < 1 || client > MaxClients )
		return 0;

	Address pEntity = GetEntityAddress(client);
	if( pEntity == Address_Null )
		return 0;

	int health = GetNativeCell(2);
	StoreToAddress(pEntity + view_as<Address>(g_iOff_m_preIncapacitatedHealth), health, NumberType_Int32, false);

	return 0;
}

int Direct_GetPreIncapHealthBuffer(Handle plugin, int numParams) // Native "L4D2Direct_GetPreIncapHealthBuffer"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_iOff_m_preIncapacitatedHealthBuffer, "m_preIncapacitatedHealthBuffer");

	int client = GetNativeCell(1);
	if( client < 1 || client > MaxClients )
		return -1;

	Address pEntity = GetEntityAddress(client);
	if( pEntity == Address_Null )
		return -1;

	return LoadFromAddress(pEntity + view_as<Address>(g_iOff_m_preIncapacitatedHealthBuffer), NumberType_Int32);
}

int Direct_SetPreIncapHealthBuffer(Handle plugin, int numParams) // Native "L4D2Direct_SetPreIncapHealthBuffer"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_iOff_m_preIncapacitatedHealthBuffer, "m_preIncapacitatedHealthBuffer");

	int client = GetNativeCell(1);
	if( client < 1 || client > MaxClients )
		return 0;

	Address pEntity = GetEntityAddress(client);
	if( pEntity == Address_Null )
		return 0;

	int health = GetNativeCell(2);

	StoreToAddress(pEntity + view_as<Address>(g_iOff_m_preIncapacitatedHealthBuffer), health, NumberType_Int32, false);

	return 0;
}

int Direct_GetInfernoMaxFlames(Handle plugin, int numParams) // Native "L4D2Direct_GetInfernoMaxFlames"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_iOff_m_maxFlames, "m_maxFlames");

	int client = GetNativeCell(1);

	Address pEntity = GetEntityAddress(client);
	if( pEntity == Address_Null )
		return -1;

	return LoadFromAddress(pEntity + view_as<Address>(g_iOff_m_maxFlames), NumberType_Int32);
}

int Direct_SetInfernoMaxFlames(Handle plugin, int numParams) // Native "L4D2Direct_SetInfernoMaxFlames"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_iOff_m_maxFlames, "m_maxFlames");

	int entity = GetNativeCell(1);

	Address pEntity = GetEntityAddress(entity);
	if( pEntity == Address_Null )
		return 0;

	int flames = GetNativeCell(2);
	StoreToAddress(pEntity + view_as<Address>(g_iOff_m_maxFlames), flames, NumberType_Int32, false);

	return 0;
}

int Direct_GetScriptedEventManager(Handle plugin, int numParams) // Native "L4D2Direct_GetScriptedEventManager"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pScriptedEventManager, "ScriptedEventManagerPtr");

	return g_pScriptedEventManager;
}

any Direct_GetTerrorNavArea(Handle plugin, int numParams) // Native "L4D2Direct_GetTerrorNavArea"
{
	ValidateAddress(g_pNavMesh, "g_pNavMesh");
	ValidateNatives(g_hSDK_CNavMesh_GetNavArea, "CNavMesh::GetNavArea");

	float vPos[3];
	GetNativeArray(1, vPos, sizeof(vPos));

	float beneathLimit = GetNativeCell(2);

	//PrintToServer("#### CALL g_hSDK_CNavMesh_GetNavArea");
	return SDKCall(g_hSDK_CNavMesh_GetNavArea, g_pNavMesh, vPos, beneathLimit);
}

any Direct_GetTerrorNavAreaFlow(Handle plugin, int numParams) // Native "L4D2Direct_GetTerrorNavAreaFlow"
{
	Address pTerrorNavArea = GetNativeCell(1);
	return GetTerrorNavAreaFlow(pTerrorNavArea);
}

float GetTerrorNavAreaFlow(Address pTerrorNavArea)
{
	ValidateAddress(g_iOff_m_flow, "m_flow");

	if( pTerrorNavArea == Address_Null )
		return 0.0;

	return view_as<float>(LoadFromAddress(pTerrorNavArea + view_as<Address>(g_iOff_m_flow), NumberType_Int32));
}

int Direct_TryOfferingTankBot(Handle plugin, int numParams) // Native "L4D2Direct_TryOfferingTankBot"
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_CDirector_TryOfferingTankBot, "CDirector::TryOfferingTankBot");

	int entity = GetNativeCell(1);
	bool bEnterStasis = GetNativeCell(2);

	//PrintToServer("#### CALL g_hSDK_CDirector_TryOfferingTankBot");
	SDKCall(g_hSDK_CDirector_TryOfferingTankBot, g_pDirector, entity, bEnterStasis);

	return 0;
}

any Direct_GetFlowDistance(Handle plugin, int numParams) // Native "L4D2Direct_GetFlowDistance"
{
	ValidateAddress(g_iOff_m_flow, "m_flow");
	ValidateNatives(g_hSDK_CTerrorPlayer_GetLastKnownArea, "CTerrorPlayer::GetLastKnownArea");

	int client = GetNativeCell(1);

	//PrintToServer("#### CALL Direct_GetFlowDistance > g_hSDK_CTerrorPlayer_GetLastKnownArea");
	int area = SDKCall(g_hSDK_CTerrorPlayer_GetLastKnownArea, client);
	//PrintToServer("#### CALL Direct_GetFlowDistance > g_hSDK_CTerrorPlayer_GetLastKnownArea Area %d", area);
	if( area == 0 ) return 0.0;

	float flow = view_as<float>(LoadFromAddress(view_as<Address>(area + g_iOff_m_flow), NumberType_Int32));
	//PrintToServer("#### CALL Direct_GetFlowDistance > g_hSDK_CTerrorPlayer_GetLastKnownArea Flow %d", flow);
	if( flow == -9999.0 ) flow = 0.0;

	return flow;
}

int Direct_DoAnimationEvent(Handle plugin, int numParams) // Native "L4D2Direct_DoAnimationEvent"
{
	ValidateNatives(g_hSDK_CTerrorPlayer_DoAnimationEvent, "CTerrorPlayer::DoAnimationEvent");

	int client = GetNativeCell(1);
	if( client <= 0 || client > MaxClients )
		return 0;

	int event = GetNativeCell(2);

	//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_DoAnimationEvent");
	SDKCall(g_hSDK_CTerrorPlayer_DoAnimationEvent, client, event, 0);

	return 0;
}

int Direct_GetSurvivorHealthBonus(Handle plugin, int numParams) // Native "L4DDirect_GetSurvivorHealthBonus"
{
	if( g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED1);

	int client = GetNativeCell(1);

	Address pEntity = GetEntityAddress(client);
	if( pEntity == Address_Null )
		return -1;

	return LoadFromAddress(pEntity + view_as<Address>(g_iOff_m_iSurvivorHealthBonus), NumberType_Int32);
}

int Direct_SetSurvivorHealthBonus(Handle plugin, int numParams) // Native "L4DDirect_SetSurvivorHealthBonus"
{
	if( g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED1);

	int client = GetNativeCell(1);

	Address pEntity = GetEntityAddress(client);
	if( pEntity == Address_Null )
		return 0;

	int health = GetNativeCell(2);
	bool recompute = GetNativeCell(3);

	StoreToAddress(pEntity + view_as<Address>(g_iOff_m_iSurvivorHealthBonus), health, NumberType_Int32, false);

	if( recompute )
	{
		ValidateNatives(g_hSDK_CTerrorGameRules_RecomputeTeamScores, "CTerrorGameRules::RecomputeTeamScores");

		//PrintToServer("#### CALL g_hSDK_CTerrorGameRules_RecomputeTeamScores");
		SDKCall(g_hSDK_CTerrorGameRules_RecomputeTeamScores);
	}

	return 0;
}

int Direct_RecomputeTeamScores(Handle plugin, int numParams) // Native "L4DDirect_RecomputeTeamScores"
{
	if( g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED1);

	ValidateNatives(g_hSDK_CTerrorGameRules_RecomputeTeamScores, "CTerrorGameRules::RecomputeTeamScores");

	//PrintToServer("#### CALL g_hSDK_CTerrorGameRules_RecomputeTeamScores");
	SDKCall(g_hSDK_CTerrorGameRules_RecomputeTeamScores);
	return true;
}



// ==================================================
// NATIVES: l4d2d_timers.inc
// ==================================================
int Direct_CTimer_Reset(Handle plugin, int numParams) // Native "CTimer_Reset"
{
	CountdownTimer timer = GetNativeCell(1);
	Stock_CTimer_Reset(timer);
	return 0;
}

int Direct_CTimer_Start(Handle plugin, int numParams) // Native "CTimer_Start"
{
	CountdownTimer timer = GetNativeCell(1);
	float duration = GetNativeCell(2);
	Stock_CTimer_Start(timer, duration);
	return 0;
}

int Direct_CTimer_Invalidate(Handle plugin, int numParams) // Native "CTimer_Invalidate"
{
	CountdownTimer timer = GetNativeCell(1);
	Stock_CTimer_Invalidate(timer);
	return 0;
}

int Direct_CTimer_HasStarted(Handle plugin, int numParams) // Native "CTimer_HasStarted"
{
	CountdownTimer timer = GetNativeCell(1);
	return Stock_CTimer_HasStarted(timer);
}

int Direct_CTimer_IsElapsed(Handle plugin, int numParams) // Native "CTimer_IsElapsed"
{
	CountdownTimer timer = GetNativeCell(1);
	return Stock_CTimer_IsElapsed(timer);
}

any Direct_CTimer_GetElapsedTime(Handle plugin, int numParams) // Native "CTimer_GetElapsedTime"
{
	CountdownTimer timer = GetNativeCell(1);
	return Stock_CTimer_GetElapsedTime(timer);
}

any Direct_CTimer_GetRemainingTime(Handle plugin, int numParams) // Native "CTimer_GetRemainingTime"
{
	CountdownTimer timer = GetNativeCell(1);
	return Stock_CTimer_GetRemainingTime(timer);
}

any Direct_CTimer_GetCountdownDuration(Handle plugin, int numParams) // Native "CTimer_GetCountdownDuration"
{
	CountdownTimer timer = GetNativeCell(1);
	return Stock_CTimer_GetCountdownDuration(timer);
}

int Direct_ITimer_Reset(Handle plugin, int numParams) // Native "ITimer_Reset"
{
	IntervalTimer timer = GetNativeCell(1);
	Stock_ITimer_Reset(timer);
	return 0;
}

int Direct_ITimer_Start(Handle plugin, int numParams) // Native "ITimer_Start"
{
	IntervalTimer timer = GetNativeCell(1);
	Stock_ITimer_Start(timer);
	return 0;
}

int Direct_ITimer_Invalidate(Handle plugin, int numParams) // Native "ITimer_Invalidate"
{
	IntervalTimer timer = GetNativeCell(1);
	Stock_ITimer_Invalidate(timer);
	return 0;
}

int Direct_ITimer_HasStarted(Handle plugin, int numParams) // Native "ITimer_HasStarted"
{
	IntervalTimer timer = GetNativeCell(1);
	return Stock_ITimer_HasStarted(timer);
}

any Direct_ITimer_GetElapsedTime(Handle plugin, int numParams) // Native "ITimer_GetElapsedTime"
{
	IntervalTimer timer = GetNativeCell(1);
	return Stock_ITimer_GetElapsedTime(timer);
}



/* Timer Internals */
any Direct_CTimer_GetDuration(Handle plugin, int numParams) // Native "CTimer_GetDuration"
{
	CountdownTimer timer = GetNativeCell(1);
	return Stock_CTimer_GetDuration(timer);
}

int Direct_CTimer_SetDuration(Handle plugin, int numParams) // Native "CTimer_SetDuration"
{
	CountdownTimer timer = GetNativeCell(1);
	float duration = GetNativeCell(2);
	Stock_CTimer_SetDuration(timer, duration);
	return 0;
}

any Direct_CTimer_GetTimestamp(Handle plugin, int numParams) // Native "CTimer_GetTimestamp"
{
	CountdownTimer timer = GetNativeCell(1);
	return Stock_CTimer_GetTimestamp(timer);
}

int Direct_CTimer_SetTimestamp(Handle plugin, int numParams) // Native "CTimer_SetTimestamp"
{
	CountdownTimer timer = GetNativeCell(1);
	float timestamp = GetNativeCell(2);
	Stock_CTimer_SetTimestamp(timer, timestamp);
	return 0;
}

any Direct_ITimer_GetTimestamp(Handle plugin, int numParams) // Native "ITimer_GetTimestamp"
{
	IntervalTimer timer = GetNativeCell(1);
	return Stock_ITimer_GetTimestamp(timer);
}

int Direct_ITimer_SetTimestamp(Handle plugin, int numParams) // Native "ITimer_SetTimestamp"
{
	IntervalTimer timer = GetNativeCell(1);
	float timestamp = GetNativeCell(2);
	Stock_ITimer_SetTimestamp(timer, timestamp);
	return 0;
}



// ==================================================
// STOCKS: l4d2d_timers.inc
// ==================================================
#define CTIMER_DURATION_OFFSET	view_as<Address>(4)
#define CTIMER_TIMESTAMP_OFFSET view_as<Address>(8)
#define ITIMER_TIMESTAMP_OFFSET view_as<Address>(4)

void Stock_CTimer_Reset(CountdownTimer timer)
{
	Stock_CTimer_SetTimestamp(timer, GetGameTime() + Stock_CTimer_GetDuration(timer));
}

void Stock_CTimer_Start(CountdownTimer timer, float duration)
{
	Stock_CTimer_SetTimestamp(timer, GetGameTime() + duration);
	Stock_CTimer_SetDuration(timer, duration);
}

void Stock_CTimer_Invalidate(CountdownTimer timer)
{
	Stock_CTimer_SetTimestamp(timer, -1.0);
}

bool Stock_CTimer_HasStarted(CountdownTimer timer)
{
	return Stock_CTimer_GetTimestamp(timer) >= 0.0;
}

bool Stock_CTimer_IsElapsed(CountdownTimer timer)
{
	return GetGameTime() >= Stock_CTimer_GetTimestamp(timer);
}

float Stock_CTimer_GetElapsedTime(CountdownTimer timer)
{
	return (GetGameTime() - Stock_CTimer_GetTimestamp(timer)) + Stock_CTimer_GetDuration(timer);
}

float Stock_CTimer_GetRemainingTime(CountdownTimer timer)
{
	return Stock_CTimer_GetTimestamp(timer) - GetGameTime();
}

float Stock_CTimer_GetCountdownDuration(CountdownTimer timer)
{
	return (Stock_CTimer_GetTimestamp(timer) > 0.0) ? Stock_CTimer_GetDuration(timer) : 0.0;
}

void Stock_ITimer_Reset(IntervalTimer timer)
{
	Stock_ITimer_SetTimestamp(timer, GetGameTime());
}

void Stock_ITimer_Start(IntervalTimer timer)
{
	Stock_ITimer_SetTimestamp(timer, GetGameTime());
}

void Stock_ITimer_Invalidate(IntervalTimer timer)
{
	Stock_ITimer_SetTimestamp(timer, -1.0);
}

bool Stock_ITimer_HasStarted(IntervalTimer timer)
{
	return (Stock_ITimer_GetTimestamp(timer) > 0.0);
}

float Stock_ITimer_GetElapsedTime(IntervalTimer timer)
{
	return Stock_ITimer_HasStarted(timer) ? GetGameTime() - Stock_ITimer_GetTimestamp(timer) : 99999.9; // 99999.999999 Should be this?
}

/* Timer Internals */
float Stock_CTimer_GetDuration(CountdownTimer timer)
{
	return view_as<float>(LoadFromAddress(view_as<Address>(timer) + CTIMER_DURATION_OFFSET, NumberType_Int32));
}

void Stock_CTimer_SetDuration(CountdownTimer timer, float duration)
{
	StoreToAddress(view_as<Address>(timer) + CTIMER_DURATION_OFFSET, view_as<int>(duration), NumberType_Int32, false);
}

float Stock_CTimer_GetTimestamp(CountdownTimer timer)
{
	return view_as<float>(LoadFromAddress(view_as<Address>(timer) + CTIMER_TIMESTAMP_OFFSET, NumberType_Int32));
}

void Stock_CTimer_SetTimestamp(CountdownTimer timer, float timestamp)
{
	StoreToAddress(view_as<Address>(timer) + CTIMER_TIMESTAMP_OFFSET, view_as<int>(timestamp), NumberType_Int32, false);
}

float Stock_ITimer_GetTimestamp(IntervalTimer timer)
{
	return view_as<float>(LoadFromAddress(view_as<Address>(timer) + ITIMER_TIMESTAMP_OFFSET, NumberType_Int32));
}

void Stock_ITimer_SetTimestamp(IntervalTimer timer, float timestamp)
{
	StoreToAddress(view_as<Address>(timer) + ITIMER_TIMESTAMP_OFFSET, view_as<int>(timestamp), NumberType_Int32, false);
}





// ==================================================
// l4d2addresses.txt
// ==================================================
int Native_CTerrorPlayer_OnVomitedUpon(Handle plugin, int numParams) // Native "L4D_CTerrorPlayer_OnVomitedUpon"
{
	ValidateNatives(g_hSDK_CTerrorPlayer_OnVomitedUpon, "CTerrorPlayer::OnVomitedUpon");

	int client = GetNativeCell(1);
	int attacker = GetNativeCell(2);

	//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_OnVomitedUpon");
	SDKCall(g_hSDK_CTerrorPlayer_OnVomitedUpon, client, attacker, false);

	return 0;
}

int Native_CTerrorPlayer_OnHitByVomitJar(Handle plugin, int numParams) // Native "L4D2_CTerrorPlayer_OnHitByVomitJar"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateNatives(g_hSDK_CTerrorPlayer_OnHitByVomitJar, "CTerrorPlayer::OnHitByVomitJar");

	int client = GetNativeCell(1);
	int attacker = GetNativeCell(2);

	//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_OnHitByVomitJar");
	SDKCall(g_hSDK_CTerrorPlayer_OnHitByVomitJar, client, attacker, true);

	return 0;
}

int Native_Infected_OnHitByVomitJar(Handle plugin, int numParams) // Native "L4D2_Infected_OnHitByVomitJar"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateNatives(g_hSDK_Infected_OnHitByVomitJar, "Infected::OnHitByVomitJar");

	int entity = GetNativeCell(1);
	int attacker = GetNativeCell(2);

	//PrintToServer("#### CALL g_hSDK_Infected_OnHitByVomitJar");
	SDKCall(g_hSDK_Infected_OnHitByVomitJar, entity, attacker, true);

	return 0;
}

int Native_CTerrorPlayer_CancelStagger(Handle plugin, int numParams) // Native "L4D_CancelStagger"
{
	ValidateNatives(g_hSDK_CTerrorPlayer_CancelStagger, "CTerrorPlayer::CancelStagger");

	int client = GetNativeCell(1);

	//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_CancelStagger");
	SDKCall(g_hSDK_CTerrorPlayer_CancelStagger, client);

	return 0;
}

int Native_CTerrorPlayer_Fling(Handle plugin, int numParams) // Native "L4D2_CTerrorPlayer_Fling"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateNatives(g_hSDK_CTerrorPlayer_Fling, "CTerrorPlayer::Fling");

	int client = GetNativeCell(1);
	int attacker = GetNativeCell(2);
	float vDir[3];
	GetNativeArray(3, vDir, sizeof(vDir));

	//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_Fling");
	SDKCall(g_hSDK_CTerrorPlayer_Fling, client, vDir, 76, attacker, 3.0); // 76 is the 'got bounced' animation in L4D2. 3.0 = incapTime, what's this mean?

	return 0;
}

int Native_ThrowImpactedSurvivor(Handle plugin, int numParams) // Native "L4D2_Charger_ThrowImpactedSurvivor"
{
	ValidateNatives(g_hSDK_ThrowImpactedSurvivor, "ThrowImpactedSurvivor");

	int target = GetNativeCell(1);
	int client = GetNativeCell(2);

	//PrintToServer("#### CALL g_hSDK_ThrowImpactedSurvivor");
	SDKCall(g_hSDK_ThrowImpactedSurvivor, client, target, 0.1, false);

	return 0;
}

int Native_CTerrorPlayer_OnStartCarryingVictim(Handle plugin, int numParams) // Native "L4D2_Charger_StartCarryingVictim"
{
	ValidateNatives(g_hSDK_CTerrorPlayer_OnStartCarryingVictim, "CTerrorPlayer::OnStartCarryingVictim");

	int target = GetNativeCell(1);
	int client = GetNativeCell(2);

	if( client == target ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, "Attacker must be a Charger, not the same client.");

	//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_OnStartCarryingVictim");
	SDKCall(g_hSDK_CTerrorPlayer_OnStartCarryingVictim, client, target);

	CreateTimer(0.4, TimerTeleportTarget, GetClientUserId(target));

	return 0;
}

Action TimerTeleportTarget(Handle timer, int client)
{
	client = GetClientOfUserId(client);
	if( client )
	{
		int target = GetEntPropEnt(client, Prop_Send, "m_carryAttacker");
		if( target != -1 && IsClientInGame(target) )
		{
			SetVariantString("!activator");
			AcceptEntityInput(client, "SetParent", target);
			SetVariantString("lhand");
			AcceptEntityInput(client, "SetParentAttachment");

			if( GetEntPropEnt(client, Prop_Send, "m_isIncapacitated") )
				TeleportEntity(client, view_as<float>({ -10.0, -10.0, 5.0 }), NULL_VECTOR, NULL_VECTOR);
			else
				TeleportEntity(client, view_as<float>({ 5.0, 5.0, 30.0 }), NULL_VECTOR, NULL_VECTOR);
		}
	}

	return Plugin_Continue;
}

int Native_CTerrorPlayer_QueuePummelVictim(Handle plugin, int numParams) // Native "L4D2_Charger_PummelVictim"
{
	ValidateNatives(g_hSDK_CTerrorPlayer_QueuePummelVictim, "CTerrorPlayer::QueuePummelVictim");

	int target = GetNativeCell(1);
	int client = GetNativeCell(2);

	//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_QueuePummelVictim");
	SDKCall(g_hSDK_CTerrorPlayer_QueuePummelVictim, client, target, -1.0);

	return 0;
}

int Native_CTerrorPlayer_OnPummelEnded(Handle plugin, int numParams) // Native "L4D2_Charger_EndPummel"
{
	ValidateNatives(g_hSDK_CTerrorPlayer_OnPummelEnded, "CTerrorPlayer::OnPummelEnded");

	int target = GetNativeCell(1);
	int client = GetNativeCell(2);

	//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_OnPummelEnded");
	SDKCall(g_hSDK_CTerrorPlayer_OnPummelEnded, client, "", target);

	SetWeaponAttack(client, true, 0.5);
	SetWeaponAttack(client, false, 0.6);

	SetEntPropEnt(client, Prop_Send, "m_carryVictim", -1);
	SetEntPropEnt(target, Prop_Send, "m_carryAttacker", -1);

	float vPos[3];
	vPos[0] = GetEntProp(target, Prop_Send, "m_isIncapacitated") == 1 ? 20.0 : 50.0;
	SetVariantString("!activator");
	AcceptEntityInput(target, "SetParent", client);
	TeleportEntity(target, vPos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(target, "ClearParent");

	// Fix stuck in flying animation bug, 0.3 seems enough to cover, any earlier may not always detect the falling anim
	CreateTimer(0.3, TimerFixAnim, GetClientUserId(target));

	return 0;
}

void SetWeaponAttack(int client, bool primary, float time)
{
	if( primary )
	{
		int ability = GetEntPropEnt(client, Prop_Send, "m_customAbility");
		if( GetEntPropFloat(ability, Prop_Send, "m_timestamp") < GetGameTime() + time )
			SetEntPropFloat(ability, Prop_Send, "m_timestamp", GetGameTime() + time);
	}

	int weapon = GetPlayerWeaponSlot(client, 0);
	if( weapon != -1 )
	{
		if( primary )	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + time);
		if( !primary )	SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", GetGameTime() + time);
	}
}

Action TimerFixAnim(Handle t, int target)
{
	target = GetClientOfUserId(target);
	if( target && IsPlayerAlive(target) )
	{
		int seq = GetEntProp(target, Prop_Send, "m_nSequence");
		if( seq == 650 || seq == 665 || seq == 661 || seq == 651 || seq == 554 || seq == 551 ) // Coach, Ellis, Nick, Rochelle, Francis/Zoey, Bill/Louis
		{
			#if defined DEBUG
			#if DEBUG
			PrintToServer("Charger: Fixing victim stuck falling: %N", target);
			#endif
			#endif

			float vPos[3];
			GetClientAbsOrigin(target, vPos);
			SetEntityMoveType(target, MOVETYPE_WALK);
			TeleportEntity(target, vPos, NULL_VECTOR, view_as<float>({0.0, 0.0, 0.0}));
		}
	}

	return Plugin_Continue;
}

int Native_CTerrorPlayer_OnRideEnded(Handle plugin, int numParams) // Native "L4D2_Jockey_EndRide"
{
	ValidateNatives(g_hSDK_CTerrorPlayer_OnRideEnded, "CTerrorPlayer::OnRideEnded");

	int target = GetNativeCell(1);
	int client = GetNativeCell(2);

	//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_OnRideEnded");
	SDKCall(g_hSDK_CTerrorPlayer_OnRideEnded, client, target);

	return 0;
}

int Native_CTerrorPlayer_RespawnPlayer(Handle plugin, int numParams) // Native "L4D_RespawnPlayer"
{
	ValidateNatives(g_hSDK_CTerrorPlayer_RoundRespawn, "CTerrorPlayer::RoundRespawn");

	int client = GetNativeCell(1);

	//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_RoundRespawn");
	SDKCall(g_hSDK_CTerrorPlayer_RoundRespawn, client);

	return 0;
}

int Native_CDirector_CreateRescuableSurvivors(Handle plugin, int numParams) // Native "L4D_CreateRescuableSurvivors"
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_CDirector_CreateRescuableSurvivors, "CDirector::CreateRescuableSurvivors");

	// Only spawns one per frame, so we'll call for as many dead survivors.
	int count;
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 2 && !IsPlayerAlive(i) )
		{
			count++;
		}
	}

	RequestFrame(OnFrameRescue, count);

	return 0;
}

void OnFrameRescue(int count)
{
	count--;
	if( count > 0 ) RequestFrame(OnFrameRescue, count);
	RespawnRescue();
}

void RespawnRescue()
{
	StoreToAddress(g_pDirector + view_as<Address>(g_iOff_m_rescueCheckTimer + 8), view_as<int>(0.0), NumberType_Int32, false);

	int time = g_iCvar_RescueDeadTime;
	g_hCvar_RescueDeadTime.SetInt(0);

	//PrintToServer("#### CALL g_hSDK_CDirector_CreateRescuableSurvivors");
	SDKCall(g_hSDK_CDirector_CreateRescuableSurvivors, g_pDirector);

	g_hCvar_RescueDeadTime.SetInt(time);
}

int Native_CTerrorPlayer_OnRevived(Handle plugin, int numParams) // Native "L4D_ReviveSurvivor"
{
	ValidateNatives(g_hSDK_CTerrorPlayer_OnRevived, "CTerrorPlayer::OnRevived");

	int client = GetNativeCell(1);

	//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_OnRevived");
	SDKCall(g_hSDK_CTerrorPlayer_OnRevived, client);

	return 0;
}

any Native_CTerrorGameRules_GetVersusCompletion(Handle plugin, int numParams) // Native "L4D2_GetVersusCompletionPlayer"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pGameRules, "g_pGameRules");
	ValidateNatives(g_hSDK_CTerrorGameRules_GetVersusCompletion, "CTerrorGameRules::GetVersusCompletion");

	int client = GetNativeCell(1);

	//PrintToServer("#### CALL g_hSDK_CTerrorGameRules_GetVersusCompletion");
	return SDKCall(g_hSDK_CTerrorGameRules_GetVersusCompletion, g_pGameRules, client);
}

int Native_CDirectorTacticalServices_GetHighestFlowSurvivor(Handle plugin, int numParams) // Native "L4D_GetHighestFlowSurvivor"
{
	ValidateNatives(g_hSDK_CDirectorTacticalServices_GetHighestFlowSurvivor, "CDirectorTacticalServices::GetHighestFlowSurvivor");

	//PrintToServer("#### CALL g_hSDK_CDirectorTacticalServices_GetHighestFlowSurvivor");
	return SDKCall(g_hSDK_CDirectorTacticalServices_GetHighestFlowSurvivor, 0, 0);
}

any Native_Infected_GetInfectedFlowDistance(Handle plugin, int numParams) // Native "L4D_GetInfectedFlowDistance"
{
	ValidateNatives(g_hSDK_Infected_GetFlowDistance, "Infected::GetFlowDistance");

	int entity = GetNativeCell(1);
	if( entity > MaxClients )
	{
		//PrintToServer("#### CALL g_hSDK_Infected_GetFlowDistance");
		return SDKCall(g_hSDK_Infected_GetFlowDistance, entity);
	}

	return 0.0;
}

int Native_CTerrorPlayer_TakeOverZombieBot(Handle plugin, int numParams) // Native "L4D_TakeOverZombieBot"
{
	ValidateNatives(g_hSDK_CTerrorPlayer_TakeOverZombieBot, "CTerrorPlayer::TakeOverZombieBot");

	int client = GetNativeCell(1);
	int target = GetNativeCell(2);

	if( client > 0 && client <= MaxClients && target > 0 && target <= MaxClients &&
		GetClientTeam(client) == 3 && GetClientTeam(target) == 3 &&
		IsFakeClient(client) == false && IsFakeClient(target) == true )
	{
		// Workaround spawning wrong type, you'll hear another special infected type sound when spawning.
		int zombieClass = GetEntProp(target, Prop_Send, "m_zombieClass");

		//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_TakeOverZombieBot");
		SDKCall(g_hSDK_CTerrorPlayer_TakeOverZombieBot, client, target);
		SetClass(client, zombieClass);
	}

	return 0;
}

int Native_CTerrorPlayer_ReplaceWithBot(Handle plugin, int numParams) // Native "L4D_ReplaceWithBot"
{
	ValidateNatives(g_hSDK_CTerrorPlayer_ReplaceWithBot, "CTerrorPlayer::ReplaceWithBot");

	int client = GetNativeCell(1);

	float vPos[3], vAng[3];
	GetClientAbsOrigin(client, vPos);
	GetClientEyeAngles(client, vAng);

	//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_ReplaceWithBot");
	SDKCall(g_hSDK_CTerrorPlayer_ReplaceWithBot, client, true);
	//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_BecomeGhost");
	SDKCall(g_hSDK_CTerrorPlayer_BecomeGhost, client, 0, 0); // Otherwise they duplicate bots and don't go into ghost mode

	TeleportEntity(client, vPos, vAng, NULL_VECTOR);

	return 0;
}

int Native_CTerrorPlayer_CullZombie(Handle plugin, int numParams) // Native "L4D_CullZombie"
{
	ValidateNatives(g_hSDK_CTerrorPlayer_CullZombie, "CTerrorPlayer::CullZombie");

	int client = GetNativeCell(1);

	//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_CullZombie");
	SDKCall(g_hSDK_CTerrorPlayer_CullZombie, client);

	return 0;
}

int Native_CTerrorPlayer_CleanupPlayerState(Handle plugin, int numParams) // Native "L4D_CleanupPlayerState"
{
	ValidateNatives(g_hSDK_CTerrorPlayer_CleanupPlayerState, "CTerrorPlayer::CleanupPlayerState");

	int client = GetNativeCell(1);

	//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_CleanupPlayerState");
	SDKCall(g_hSDK_CTerrorPlayer_CleanupPlayerState, client);

	return 0;
}

int Native_CTerrorPlayer_SetClass(Handle plugin, int numParams) // Native "L4D_SetClass"
{
	ValidateNatives(g_hSDK_CTerrorPlayer_SetClass, "CTerrorPlayer::SetClass");
	ValidateNatives(g_hSDK_CBaseAbility_CreateForPlayer, "CBaseAbility::CreateForPlayer");

	int client = GetNativeCell(1);
	int zombieClass = GetNativeCell(2);

	SetClass(client, zombieClass);

	return 0;
}

void SetClass(int client, int zombieClass)
{
	int weapon = GetPlayerWeaponSlot(client, 0);
	if( weapon != -1 )
	{
		RemovePlayerItem(client, weapon);
		RemoveEntity(weapon);
	}

	int ability = GetEntPropEnt(client, Prop_Send, "m_customAbility");
	if( ability != -1 ) RemoveEntity(ability);

	//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_SetClass");
	SDKCall(g_hSDK_CTerrorPlayer_SetClass, client, zombieClass);

	//PrintToServer("#### CALL g_hSDK_CBaseAbility_CreateForPlayer");
	ability = SDKCall(g_hSDK_CBaseAbility_CreateForPlayer, client);
	if( ability != -1 ) SetEntPropEnt(client, Prop_Send, "m_customAbility", ability);
}

int Native_CTerrorPlayer_MaterializeFromGhost(Handle plugin, int numParams) // Native "L4D_MaterializeFromGhost"
{
	ValidateNatives(g_hSDK_CTerrorPlayer_MaterializeFromGhost, "CTerrorPlayer::MaterializeFromGhost");

	int client = GetNativeCell(1);
	if( GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_isGhost") )
	{
		//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_MaterializeFromGhost");
		SDKCall(g_hSDK_CTerrorPlayer_MaterializeFromGhost, client);
		return GetEntPropEnt(client, Prop_Send, "m_customAbility");
	}
	return -1;
}

int Native_CTerrorPlayer_BecomeGhost(Handle plugin, int numParams) // Native "L4D_BecomeGhost"
{
	ValidateNatives(g_hSDK_CTerrorPlayer_BecomeGhost, "CTerrorPlayer::BecomeGhost");

	int client = GetNativeCell(1);
	if( GetEntProp(client, Prop_Send, "m_isGhost") == 0 )
	{
		if( g_bLeft4Dead2 )
		{
			//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_BecomeGhost");
			return !!SDKCall(g_hSDK_CTerrorPlayer_BecomeGhost, client, true);
		}
		else
		{
			//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_BecomeGhost");
			return !!SDKCall(g_hSDK_CTerrorPlayer_BecomeGhost, client, 0, 0);
		}
	}
	return 0;
}

int Native_CCSPlayer_State_Transition(Handle plugin, int numParams) // Native "L4D_State_Transition"
{
	ValidateNatives(g_hSDK_CCSPlayer_State_Transition, "CCSPlayer::State_Transition");

	int client = GetNativeCell(1);
	int state = GetNativeCell(2);

	//PrintToServer("#### CALL g_hSDK_CCSPlayer_State_Transition");
	SDKCall(g_hSDK_CCSPlayer_State_Transition, client, state);

	return 0;
}

int Native_CDirector_SwapTeams(Handle plugin, int numParams) // Native "L4D2_SwapTeams"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_CDirector_SwapTeams, "CDirector::SwapTeams");

	//PrintToServer("#### CALL g_hSDK_CDirector_SwapTeams");
	SDKCall(g_hSDK_CDirector_SwapTeams, g_pDirector);

	return 0;
}

int Native_CDirector_AreTeamsFlipped(Handle plugin, int numParams) // Native "L4D2_AreTeamsFlipped"
{
	return GameRules_GetProp("m_bAreTeamsFlipped");

	/*
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_CDirector_AreTeamsFlipped, "CDirector::AreTeamsFlipped");

	//PrintToServer("#### CALL g_hSDK_CDirector_AreTeamsFlipped");
	return SDKCall(g_hSDK_CDirector_AreTeamsFlipped, g_pDirector);
	*/
}

int Native_CDirector_StartRematchVote(Handle plugin, int numParams) // Native "L4D2_StartRematchVote"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateNatives(g_hSDK_CDirector_StartRematchVote, "CDirector::StartRematchVote");

	//PrintToServer("#### CALL g_hSDK_CDirector_StartRematchVote");
	SDKCall(g_hSDK_CDirector_StartRematchVote, g_pDirector);

	return 0;
}

int Native_CDirector_FullRestart(Handle plugin, int numParams) // Native "L4D2_FullRestart"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_CDirector_FullRestart, "CDirector::FullRestart");

	//PrintToServer("#### CALL g_hSDK_CDirector_FullRestart");
	SDKCall(g_hSDK_CDirector_FullRestart, g_pDirector);

	return 0;
}

int Native_CDirectorVersusMode_HideScoreboardNonVirtual(Handle plugin, int numParams) // Native "L4D2_HideVersusScoreboard"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pVersusMode, "VersusModePtr");
	ValidateNatives(g_hSDK_CDirectorVersusMode_HideScoreboardNonVirtual, "CDirectorVersusMode::HideScoreboardNonVirtual");

	//PrintToServer("#### CALL g_hSDK_CDirectorVersusMode_HideScoreboardNonVirtual");
	SDKCall(g_hSDK_CDirectorVersusMode_HideScoreboardNonVirtual, g_pVersusMode);

	return 0;
}

int Native_CDirectorScavengeMode_HideScoreboardNonVirtual(Handle plugin, int numParams) // Native "L4D2_HideScavengeScoreboard"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pScavengeMode, "ScavengeModePtr");
	ValidateNatives(g_hSDK_CDirectorScavengeMode_HideScoreboardNonVirtual, "CDirectorScavengeMode::HideScoreboardNonVirtual");

	//PrintToServer("#### CALL g_hSDK_CDirectorScavengeMode_HideScoreboardNonVirtual");
	SDKCall(g_hSDK_CDirectorScavengeMode_HideScoreboardNonVirtual, g_pScavengeMode);

	return 0;
}

int Native_CDirector_HideScoreboard(Handle plugin, int numParams) // Native "L4D2_HideScoreboard"
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_CDirector_HideScoreboard, "CDirector::HideScoreboard");

	//PrintToServer("#### CALL g_hSDK_CDirector_HideScoreboard");
	SDKCall(g_hSDK_CDirector_HideScoreboard, g_pDirector);

	return 0;
}

int Native_CDirector_RegisterForbiddenTarget(Handle plugin, int numParams) // Native "L4D_RegisterForbiddenTarget"
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_CDirector_RegisterForbiddenTarget, "CDirector::RegisterForbiddenTarget");

	int entity = GetNativeCell(1);

	//PrintToServer("#### CALL g_hSDK_CDirector_RegisterForbiddenTarget");
	return SDKCall(g_hSDK_CDirector_RegisterForbiddenTarget, g_pDirector, entity);
}

int Native_CDirector_UnregisterForbiddenTarget(Handle plugin, int numParams) // Native "L4D_UnRegisterForbiddenTarget"
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_CDirector_UnregisterForbiddenTarget, "CDirector::UnregisterForbiddenTarget");

	int entity = GetNativeCell(1);

	//PrintToServer("#### CALL g_hSDK_CDirector_UnregisterForbiddenTarget");
	SDKCall(g_hSDK_CDirector_UnregisterForbiddenTarget, g_pDirector, entity);

	return 0;
}