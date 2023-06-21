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



// ====================================================================================================
//										LOAD GAMEDATA - (create natives, load offsets etc)
// ====================================================================================================
void LoadGameDataRules(GameData hGameData)
{
	// Map changes can modify the address
	g_pGameRules = hGameData.GetAddress("GameRules");
	ValidateAddress(g_pGameRules, "g_pGameRules", true);

	g_pTheNavAreas = hGameData.GetAddress("TheNavAreas");
	ValidateAddress(g_pTheNavAreas, "TheNavAreas", true);

	g_pTheNavAreas_Size = g_pTheNavAreas + view_as<Address>(12);
	g_pTheNavAreas_List = LoadFromAddress(g_pTheNavAreas, NumberType_Int32);

	if( g_bLeft4Dead2 )
	{
		if( g_iScriptVMDetourIndex )
			g_aDetoursHooked.Set(g_iScriptVMDetourIndex, 0);

		g_pScriptVM = hGameData.GetAddress("L4DD::ScriptVM");

		ValidateAddress(g_pScriptVM, "g_pScriptVM", true);

		g_iOff_NavAreaID = 140; // Hard-coding offset here, unlikely to ever change.
	}
	else
	{
		g_iOff_NavAreaID = 136; // Hard-coding offset here, unlikely to ever change.
	}

	#if defined DEBUG
	#if DEBUG
	PrintToServer("%12d == g_pGameRules", g_pGameRules);
	PrintToServer("%12d == g_pTheNavAreas", g_pTheNavAreas);
	PrintToServer("%12d == g_pTheNavAreas_List", g_pTheNavAreas_List);

	if( g_bLeft4Dead2 )
	{
		PrintToServer("%12d == g_pScriptVM", g_pScriptVM);
	}
	#endif
	#endif
}

void LoadGameData()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", g_bLeft4Dead2 ? GAMEDATA_2 : GAMEDATA_1);
	if( FileExists(sPath) == false ) SetFailState("\n==========\nMissing required file: \"%s\".\nRead installation instructions again.\n==========", sPath);

	GameData hGameData = new GameData(g_bLeft4Dead2 ? GAMEDATA_2 : GAMEDATA_1);
	if( hGameData == null ) SetFailState("Failed to load \"%s.txt\" gamedata.", g_bLeft4Dead2 ? GAMEDATA_2 : GAMEDATA_1);

	#if defined DEBUG
	#if DEBUG
	PrintToServer("");
	PrintToServer("Left4DHooks loading gamedata: %s", g_bLeft4Dead2 ? GAMEDATA_2 : GAMEDATA_1);
	PrintToServer("");
	#endif
	#endif

	g_bLinuxOS = hGameData.GetOffset("OS") == 1;
	Format(g_sSystem, sizeof(g_sSystem), "%s/%d/%s", g_bLinuxOS ? "NIX" : "WIN", g_bLeft4Dead2 ? 2 : 1, PLUGIN_VERSION);



	// ====================================================================================================
	//									SDK CALLS
	// ====================================================================================================
	// INTERNAL
	StartPrepSDKCall(SDKCall_Static);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "GetWeaponInfo") == false )
	{
		LogError("Failed to find signature: \"GetWeaponInfo\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_GetWeaponInfo = EndPrepSDKCall();
		if( g_hSDK_GetWeaponInfo == null )
			LogError("Failed to create SDKCall: \"GetWeaponInfo\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Static);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorGameRules::GetMissionInfo") == false )
	{
		LogError("Failed to find signature: \"CTerrorGameRules::GetMissionInfo\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CTerrorGameRules_GetMissionInfo = EndPrepSDKCall();
		if( g_hSDK_CTerrorGameRules_GetMissionInfo == null )
			LogError("Failed to create SDKCall: \"CTerrorGameRules::GetMissionInfo\" (%s)", g_sSystem);
	}



	// =========================
	// SILVERS NATIVES
	// =========================
	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CTerrorPlayer::GetLastKnownArea") == false )
	{
		LogError("Failed to find signature: \"CTerrorPlayer::GetLastKnownArea\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CTerrorPlayer_GetLastKnownArea = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_GetLastKnownArea == null )
			LogError("Failed to create SDKCall: \"CTerrorPlayer::GetLastKnownArea\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CTerrorPlayer::Deafen") == false )
	{
		LogError("Failed to find signature: \"CTerrorPlayer::Deafen\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		g_hSDK_CTerrorPlayer_Deafen = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_Deafen == null )
			LogError("Failed to create SDKCall: \"CTerrorPlayer::Deafen\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "Music::Play") == false )
	{
		LogError("Failed to find signature: \"Music::Play\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		g_hSDK_Music_Play = EndPrepSDKCall();
		if( g_hSDK_Music_Play == null )
			LogError("Failed to create SDKCall: \"Music::Play\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "Music::StopPlaying") == false )
	{
		LogError("Failed to find signature: \"Music::StopPlaying\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		g_hSDK_Music_StopPlaying = EndPrepSDKCall();
		if( g_hSDK_Music_StopPlaying == null )
			LogError("Failed to create SDKCall: \"Music::StopPlaying\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Static);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CEntityDissolve::Create") == false )
	{
		LogError("Failed to find signature: \"CEntityDissolve::Create\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDK_CEntityDissolve_Create = EndPrepSDKCall();
		if( g_hSDK_CEntityDissolve_Create == null )
			LogError("Failed to create SDKCall: \"CEntityDissolve::Create\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::OnITExpired") == false )
	{
		LogError("Failed to find signature: \"CTerrorPlayer::OnITExpired\" (%s)", g_sSystem);
	} else {
		g_hSDK_CTerrorPlayer_OnITExpired = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_OnITExpired == null )
			LogError("Failed to create SDKCall: \"CTerrorPlayer::OnITExpired\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::EstimateFallingDamage") == false )
	{
		LogError("Failed to find signature: \"CTerrorPlayer::EstimateFallingDamage\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_Plain);
		g_hSDK_CTerrorPlayer_EstimateFallingDamage = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_EstimateFallingDamage == null )
			LogError("Failed to create SDKCall: \"CTerrorPlayer::EstimateFallingDamage\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Entity);
	if( PrepSDKCall_SetFromConf(hGameData, (g_bLeft4Dead2 || g_bLinuxOS) ? SDKConf_Signature : SDKConf_Virtual, "CBaseEntity::WorldSpaceCenter") == false )
	{
		LogError("Failed to find signature: \"CBaseEntity::WorldSpaceCenter\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Vector, SDKPass_ByRef);
		g_hSDK_CBaseEntity_WorldSpaceCenter = EndPrepSDKCall();
		if( g_hSDK_CBaseEntity_WorldSpaceCenter == null )
			LogError("Failed to create SDKCall: \"CBaseEntity::WorldSpaceCenter\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Entity);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CBaseEntity::ApplyLocalAngularVelocityImpulse") == false )
	{
		LogError("Failed to find signature: \"CBaseEntity::ApplyLocalAngularVelocityImpulse\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		g_hSDK_CBaseEntity_ApplyLocalAngularVelocityImpulse = EndPrepSDKCall();
		if( g_hSDK_CBaseEntity_ApplyLocalAngularVelocityImpulse == null )
			LogError("Failed to create SDKCall: \"CBaseEntity::ApplyLocalAngularVelocityImpulse\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "ZombieManager::GetRandomPZSpawnPosition") == false )
	{
		LogError("Failed to find signature: \"ZombieManager::GetRandomPZSpawnPosition\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWWORLD);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK);
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_ZombieManager_GetRandomPZSpawnPosition = EndPrepSDKCall();
		if( g_hSDK_ZombieManager_GetRandomPZSpawnPosition == null )
			LogError("Failed to create SDKCall: \"ZombieManager::GetRandomPZSpawnPosition\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CNavMesh::GetNearestNavArea") == false )
	{
		LogError("Failed to find signature: \"CNavMesh::GetNearestNavArea\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CNavMesh_GetNearestNavArea = EndPrepSDKCall();
		if( g_hSDK_CNavMesh_GetNearestNavArea == null )
			LogError("Failed to create SDKCall: \"CNavMesh::GetNearestNavArea\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "TerrorNavArea::FindRandomSpot") == false )
	{
		LogError("Failed to find signature: \"TerrorNavArea::FindRandomSpot\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Vector, SDKPass_ByValue);
		g_hSDK_TerrorNavArea_FindRandomSpot = EndPrepSDKCall();
		if( g_hSDK_TerrorNavArea_FindRandomSpot == null )
			LogError("Failed to create SDKCall: \"TerrorNavArea::FindRandomSpot\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::WarpToValidPositionIfStuck") == false )
	{
		LogError("Failed to find signature: \"CTerrorPlayer::WarpToValidPositionIfStuck\" (%s)", g_sSystem);
	} else {
		g_hSDK_CTerrorPlayer_WarpToValidPositionIfStuck = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_WarpToValidPositionIfStuck == null )
			LogError("Failed to create SDKCall: \"CTerrorPlayer::WarpToValidPositionIfStuck\" (%s)", g_sSystem);
	}

	if( g_bLeft4Dead2 )
	{
		StartPrepSDKCall(SDKCall_Static);
		if( !PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "IsVisibleToPlayer") )
		{
			LogError("Failed to find signature: \"IsVisibleToPlayer\" (%s)", g_sSystem);
		} else {
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Pointer);
			PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Pointer);
			PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
			g_hSDK_IsVisibleToPlayer = EndPrepSDKCall();
			if( g_hSDK_IsVisibleToPlayer == null)
					LogError("Failed to create SDKCall: \"IsVisibleToPlayer\" (%s)", g_sSystem);
		}
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::HasAnySurvivorLeftSafeArea") == false )
	{
		LogError("Failed to find signature: \"CDirector::HasAnySurvivorLeftSafeArea\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_CDirector_HasAnySurvivorLeftSafeArea = EndPrepSDKCall();
		if( g_hSDK_CDirector_HasAnySurvivorLeftSafeArea == null )
			LogError("Failed to create SDKCall: \"CDirector::HasAnySurvivorLeftSafeArea\" (%s)", g_sSystem);
	}

	/*
	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::IsAnySurvivorInStartArea") == false )
	{
		LogError("Failed to find signature: \"CDirector::IsAnySurvivorInStartArea\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_CDirector_IsAnySurvivorInStartArea = EndPrepSDKCall();
		if( g_hSDK_CDirector_IsAnySurvivorInStartArea == null )
			LogError("Failed to create SDKCall: \"CDirector::IsAnySurvivorInStartArea\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::IsAnySurvivorInExitCheckpoint") == false )
	{
		LogError("Failed to find signature: \"CDirector::IsAnySurvivorInExitCheckpoint\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_CDirector_IsAnySurvivorInExitCheckpoint = EndPrepSDKCall();
		if( g_hSDK_CDirector_IsAnySurvivorInExitCheckpoint == null )
			LogError("Failed to create SDKCall: \"CDirector::IsAnySurvivorInExitCheckpoint\" (%s)", g_sSystem);
	}
	*/

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, g_bLeft4Dead2 ? SDKConf_Signature : SDKConf_Address, "CDirector::AreAllSurvivorsInFinaleArea") == false )
	{
		LogError("Failed to find signature: \"CDirector::AreAllSurvivorsInFinaleArea\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_CDirector_AreAllSurvivorsInFinaleArea = EndPrepSDKCall();
		if( g_hSDK_CDirector_AreAllSurvivorsInFinaleArea == null )
			LogError("Failed to create SDKCall: \"CDirector::AreAllSurvivorsInFinaleArea\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "TerrorNavMesh::GetInitialCheckpoint") == false )
	{
		LogError("Failed to find signature: \"TerrorNavMesh::GetInitialCheckpoint\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_TerrorNavMesh_GetInitialCheckpoint = EndPrepSDKCall();
		if( g_hSDK_TerrorNavMesh_GetInitialCheckpoint == null )
			LogError("Failed to create SDKCall: \"TerrorNavMesh::GetInitialCheckpoint\" (%s)", g_sSystem);
	}

	/*
	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "TerrorNavMesh::GetLastCheckpoint") == false )
	{
		LogError("Failed to find signature: \"TerrorNavMesh::GetLastCheckpoint\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_TerrorNavMesh_GetLastCheckpoint = EndPrepSDKCall();
		if( g_hSDK_TerrorNavMesh_GetLastCheckpoint == null )
			LogError("Failed to create SDKCall: \"TerrorNavMesh::GetLastCheckpoint\" (%s)", g_sSystem);
	}
	*/

	if( g_bLeft4Dead2 )
	{
		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "TerrorNavMesh::IsInInitialCheckpoint_NoLandmark") == false )
		{
			LogError("Failed to find signature: \"TerrorNavMesh::IsInInitialCheckpoint_NoLandmark\" (%s)", g_sSystem);
		} else {
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
			g_hSDK_TerrorNavMesh_IsInInitialCheckpoint_NoLandmark = EndPrepSDKCall();
			if( g_hSDK_TerrorNavMesh_IsInInitialCheckpoint_NoLandmark == null )
				LogError("Failed to create SDKCall: \"TerrorNavMesh::IsInInitialCheckpoint_NoLandmark\" (%s)", g_sSystem);
		}

		/*
		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "TerrorNavMesh::IsInExitCheckpoint_NoLandmark") == false )
		{
			LogError("Failed to find signature: \"TerrorNavMesh::IsInExitCheckpoint_NoLandmark\" (%s)", g_sSystem);
		} else {
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
			g_hSDK_TerrorNavMesh_IsInExitCheckpoint_NoLandmark = EndPrepSDKCall();
			if( g_hSDK_TerrorNavMesh_IsInExitCheckpoint_NoLandmark == null )
				LogError("Failed to create SDKCall: \"TerrorNavMesh::IsInExitCheckpoint_NoLandmark\" (%s)", g_sSystem);
		}
		*/
	}

	StartPrepSDKCall(SDKCall_Static);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "Checkpoint::ContainsArea") == false )
	{
		LogError("Failed to find signature: \"Checkpoint::ContainsArea\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_Checkpoint_ContainsArea = EndPrepSDKCall();
		if( g_hSDK_Checkpoint_ContainsArea == null )
			LogError("Failed to create SDKCall: \"Checkpoint::ContainsArea\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Static);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorGameRules::HasPlayerControlledZombies") == false )
	{
		LogError("Failed to find signature: \"CTerrorGameRules::HasPlayerControlledZombies\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_CTerrorGameRules_HasPlayerControlledZombies = EndPrepSDKCall();
		if( g_hSDK_CTerrorGameRules_HasPlayerControlledZombies == null )
			LogError("Failed to create SDKCall: \"CTerrorGameRules::HasPlayerControlledZombies\" (%s)", g_sSystem);
	}

	if( g_bLeft4Dead2 )
	{
		StartPrepSDKCall(SDKCall_GameRules);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorGameRules::GetSurvivorSet") == false )
		{
			LogError("Failed to find signature: \"CTerrorGameRules::GetSurvivorSet\" (%s)", g_sSystem);
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_CTerrorGameRules_GetSurvivorSet = EndPrepSDKCall();
			if( g_hSDK_CTerrorGameRules_GetSurvivorSet == null )
				LogError("Failed to create SDKCall: \"CTerrorGameRules::GetSurvivorSet\" (%s)", g_sSystem);
		}
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "Script_ForceVersusStart") == false )
	{
		LogError("Failed to find signature: \"Script_ForceVersusStart\" (%s)", g_sSystem);
	} else {
		if( g_bLeft4Dead2 )
		{
			PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		}
		else
		{
			PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		}
		g_hSDK_ForceVersusStart = EndPrepSDKCall();
		if( g_hSDK_ForceVersusStart == null )
			LogError("Failed to create SDKCall: \"Script_ForceVersusStart\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "Script_ForceSurvivalStart") == false )
	{
		LogError("Failed to find signature: \"Script_ForceSurvivalStart\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_ForceSurvivalStart = EndPrepSDKCall();
		if( g_hSDK_ForceSurvivalStart == null )
			LogError("Failed to create SDKCall: \"Script_ForceSurvivalStart\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Entity);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CBaseGrenade::Detonate") == false )
	{
		LogError("Failed to find signature: \"CBaseGrenade::Detonate\" (%s)", g_sSystem);
	} else {
		g_hSDK_CBaseGrenade_Detonate = EndPrepSDKCall();
		if( g_hSDK_CBaseGrenade_Detonate == null )
			LogError("Failed to create SDKCall: \"CBaseGrenade::Detonate\" (%s)", g_sSystem);
	}

	/*
	StartPrepSDKCall(SDKCall_Static);
	// StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CInferno::StartBurning") == false )
	{
		LogError("Failed to find signature: \"CInferno::StartBurning\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CInferno_StartBurning = EndPrepSDKCall();
		if( g_hSDK_CInferno_StartBurning == null )
			LogError("Failed to create SDKCall: \"CInferno::StartBurning\" (%s)", g_sSystem);
	}
	// */

	StartPrepSDKCall(SDKCall_Static);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CPipeBombProjectile::Create") == false )
	{
		LogError("Failed to find signature: \"CPipeBombProjectile::Create\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWWORLD);
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDK_CPipeBombProjectile_Create = EndPrepSDKCall();
		if( g_hSDK_CPipeBombProjectile_Create == null )
			LogError("Failed to create SDKCall: \"CPipeBombProjectile::Create\" (%s)", g_sSystem);
	}



	// =========================
	// DYNAMIC SIG SCANS
	// =========================

	// Automatically generate addresses from strings inside the custom temp gamedata used for some natives

	// What this does:
	// Basically finding a strings memory address by searching for it's literal string.
	// Then we create a gamedata with the target functions first byte, and add lots of wildcard bytes up to
	// the strings address which we add in reverse order.
	// We reverse the string address because that's how computers use them and can be seen in compiled code or in memory.
	// We also add "0x68" PUSH byte found before the string (not all functions would have this, but that's what occurs with the current ones used here).
	if( !g_bLinuxOS )
	{
		// Search game memory for specific strings
		#define MAX_HOOKS 4
		int iMaxHooks = g_bLeft4Dead2 ? 4 : 1;
		int offsetPush;

		Address patchAddr;
		Address patches[MAX_HOOKS];

		// Get memory address where the literal strings are stored
		patches[0] = hGameData.GetAddress("Molotov_StrFind");
		if( g_bLeft4Dead2 )
		{
			patches[1] = hGameData.GetAddress("VomitJar_StrFind");
			patches[2] = hGameData.GetAddress("GrenadeLauncher_StrFind");
			patches[3] = hGameData.GetAddress("Realism_StrFind");
		}


		// Write custom gamedata with found addresses from literal strings
		BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA_TEMP);
		File hFile = OpenFile(sPath, "w", false);

		char sAddress[512];
		char sHexAddr[32];

		hFile.WriteLine("\"Games\"");
		hFile.WriteLine("{");
		hFile.WriteLine("	\"#default\"");
		hFile.WriteLine("	{");
		hFile.WriteLine("		\"Addresses\"");
		hFile.WriteLine("		{");

		for( int i = 0; i < iMaxHooks; i++ )
		{
			patchAddr = patches[i];

			if( patchAddr )
			{
				hFile.WriteLine("			\"FindAddress_%d\"", i);
				hFile.WriteLine("			{");
				if( g_bLinuxOS )
				{
					hFile.WriteLine("				\"linux\"");
					hFile.WriteLine("				{");
					hFile.WriteLine("					\"signature\"		\"FindAddress_%d\"", i);
					hFile.WriteLine("				}");
				} else {
					hFile.WriteLine("				\"windows\"");
					hFile.WriteLine("				{");
					hFile.WriteLine("					\"signature\"		\"FindAddress_%d\"", i);
					hFile.WriteLine("				}");
				}
				hFile.WriteLine("			}");
			}
		}

		hFile.WriteLine("		}");
		hFile.WriteLine("");
		hFile.WriteLine("		\"Signatures\"");
		hFile.WriteLine("		{");

		for( int i = 0; i < iMaxHooks; i++ )
		{
			patchAddr = patches[i];
			if( patchAddr )
			{
				FormatEx(sAddress, sizeof(sAddress), "%X", patchAddr);
				ReverseAddress(sAddress, sHexAddr);

				// First byte of projectile functions is 0x55 or 0x8B
				if( i == 3 ) // For "CTerrorGameRules::IsRealismMode" first byte of function is different
				{
					sAddress = "\\x8B";
				}
				// Others
				else
				{
					if( g_bLeft4Dead2 )
						sAddress = "\\x55";
					else
						sAddress = "\\x8B";
				}

				// Offset to the "push" string call (number of bytes to wildcard, minus the first byte already matched and not including 0x68 PUSH)
				switch( i )
				{
					case 0: offsetPush = hGameData.GetOffset("Molotov_OffsetPush");
					case 1: offsetPush = hGameData.GetOffset("VomitJar_OffsetPush");
					case 2: offsetPush = hGameData.GetOffset("GrenadeLauncher_OffsetPush");
					case 3: offsetPush = hGameData.GetOffset("Realism_OffsetPush");
				}

				// Add * bytes
				for( int x = 0; x < offsetPush; x++ )
				{
					StrCat(sAddress, sizeof(sAddress), "\\x2A");
				}

				// Add call X address
				StrCat(sAddress, sizeof(sAddress), "\\x68"); // Add "push" byte (this is found in the "Molotov", "VomitJar", "GrenadeLauncher" and "IsRealism" functions only) - added to match better although not required
				StrCat(sAddress, sizeof(sAddress), sHexAddr);
				if( i == 3 ) StrCat(sAddress, sizeof(sAddress), "\\x68"); // Match byte after for "CTerrorGameRules::IsRealismMode", otherwise its not unique signature


				// Write lines
				hFile.WriteLine("			\"FindAddress_%d\"", i);
				hFile.WriteLine("			{");
				// hFile.WriteLine("				\"library\"	\"server\""); // Server is default.
				if( g_bLinuxOS )
				{
					hFile.WriteLine("				\"linux\"	\"%s\"", sAddress);
				} else {
					hFile.WriteLine("				\"windows\"	\"%s\"", sAddress);
				}

				// Write wildcard for IDA - Doesn't actually find in IDA because the memory addresses in runtime differ from compiled.
				// ReplaceString(sAddress, sizeof(sAddress), "\\x", " ");
				// ReplaceString(sAddress, sizeof(sAddress), "2A", "?");
				// hFile.WriteLine("				/*%s */", sAddress);

				// Finish
				hFile.WriteLine("			}");
			}
		}

		hFile.WriteLine("		}");
		hFile.WriteLine("	}");
		hFile.WriteLine("}");

		FlushFile(hFile);
		delete hFile;

		// =========================
		// END DYNAMIC SIG SCANS
		// =========================
	}



	// Temp GameData SDKCalls
	GameData hTempGameData;

	if( !g_bLinuxOS )
	{
		hTempGameData = new GameData(GAMEDATA_TEMP);
		if( hTempGameData == null ) LogError("Failed to load \"%s.txt\" gamedata (%s).", GAMEDATA_TEMP, g_sSystem);
	}



	StartPrepSDKCall(SDKCall_Static);
	if( PrepSDKCall_SetFromConf(g_bLinuxOS ? hGameData : hTempGameData, SDKConf_Signature, g_bLinuxOS ? "CMolotovProjectile::Create" : "FindAddress_0") == false )
	{
		LogError("Failed to find signature: \"CMolotovProjectile::Create\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWWORLD);
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDK_CMolotovProjectile_Create = EndPrepSDKCall();
		if( g_hSDK_CMolotovProjectile_Create == null )
			LogError("Failed to create SDKCall: \"CMolotovProjectile::Create\" (%s)", g_sSystem);
	}

	if( g_bLeft4Dead2 )
	{
		StartPrepSDKCall(SDKCall_Static);
		if( PrepSDKCall_SetFromConf(g_bLinuxOS ? hGameData : hTempGameData, SDKConf_Signature, g_bLinuxOS ? "CVomitJarProjectile::Create" : "FindAddress_1") == false )
		{
			LogError("Failed to find signature: \"CVomitJarProjectile::Create\" (%s)", g_sSystem);
		} else {
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWWORLD);
			PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
			PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
			g_hSDK_CVomitJarProjectile_Create = EndPrepSDKCall();
			if( g_hSDK_CVomitJarProjectile_Create == null )
				LogError("Failed to create SDKCall: \"CVomitJarProjectile::Create\" (%s)", g_sSystem);
		}

		StartPrepSDKCall(SDKCall_Static);
		if( PrepSDKCall_SetFromConf(g_bLinuxOS ? hGameData : hTempGameData, SDKConf_Signature, g_bLinuxOS ? "CGrenadeLauncher_Projectile::Create" : "FindAddress_2") == false )
		{
			LogError("Failed to find signature: \"CGrenadeLauncher_Projectile::Create\" (%s)", g_sSystem);
		} else {
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWWORLD);
			PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
			PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
			g_hSDK_CGrenadeLauncher_Projectile_Create = EndPrepSDKCall();
			if( g_hSDK_CGrenadeLauncher_Projectile_Create == null )
				LogError("Failed to create SDKCall: \"CGrenadeLauncher_Projectile::Create\" (%s)", g_sSystem);
		}

		StartPrepSDKCall(SDKCall_GameRules);
		if( PrepSDKCall_SetFromConf(g_bLinuxOS ? hGameData : hTempGameData, SDKConf_Signature, g_bLinuxOS ? "CTerrorGameRules::IsRealismMode" : "FindAddress_3") == false )
		{
			LogError("Failed to find signature: \"CTerrorGameRules::IsRealismMode\" (%s)", g_sSystem);
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_CTerrorGameRules_IsRealismMode = EndPrepSDKCall();
			if( g_hSDK_CTerrorGameRules_IsRealismMode == null )
				LogError("Failed to create SDKCall: \"CTerrorGameRules::IsRealismMode\" (%s)", g_sSystem);
		}

		// Normal GameData SDKCalls
		StartPrepSDKCall(SDKCall_Static);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CSpitterProjectile::Create") == false )
		{
			LogError("Failed to find signature: \"CSpitterProjectile::Create\" (%s)", g_sSystem);
		} else {
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWWORLD);
			PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
			g_hSDK_CSpitterProjectile_Create = EndPrepSDKCall();
			if( g_hSDK_CSpitterProjectile_Create == null )
				LogError("Failed to create SDKCall: \"CSpitterProjectile::Create\" (%s)", g_sSystem);
		}

		StartPrepSDKCall(SDKCall_GameRules);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorGameRules::HasConfigurableDifficultySetting") == false )
		{
			LogError("Failed to find signature: \"CTerrorGameRules::HasConfigurableDifficultySetting\" (%s)", g_sSystem);
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_CTerrorGameRules_HasConfigurableDifficultySetting = EndPrepSDKCall();
			if( g_hSDK_CTerrorGameRules_HasConfigurableDifficultySetting == null )
				LogError("Failed to create SDKCall: \"CTerrorGameRules::HasConfigurableDifficultySetting\" (%s)", g_sSystem);
		}

		StartPrepSDKCall(SDKCall_Static);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "NavAreaBuildPath_ShortestPathCost") == false )
		{
			LogError("Failed to find signature: \"NavAreaBuildPath_ShortestPathCost\" (%s)", g_sSystem);
		} else {
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
			PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
			g_hSDK_NavAreaBuildPath_ShortestPathCost = EndPrepSDKCall();
			if( g_hSDK_NavAreaBuildPath_ShortestPathCost == null )
				LogError("Failed to create SDKCall: \"NavAreaBuildPath_ShortestPathCost\" (%s)", g_sSystem);
		}

		StartPrepSDKCall(SDKCall_Player);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::OnAdrenalineUsed") == false )
		{
			LogError("Failed to find signature: \"CTerrorPlayer::OnAdrenalineUsed\" (%s)", g_sSystem);
		} else {
			PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
			g_hSDK_CTerrorPlayer_OnAdrenalineUsed = EndPrepSDKCall();
			if( g_hSDK_CTerrorPlayer_OnAdrenalineUsed == null )
				LogError("Failed to create SDKCall: \"CTerrorPlayer::OnAdrenalineUsed\" (%s)", g_sSystem);
		}

		// "ForceNextStage" is now found by getting the call address from another function, instead of trying to match such a small signature, which requires using an offset byte that changes in game updates
		/* Verify ForceNextStage addresses are equal (B will break in future updates, where A should remain intact)
		Address aa = hGameData.GetAddress("CDirector::ForceNextStage::Address");
		Address bb = hGameData.GetAddress("CDirector::ForceNextStage");
		PrintToServer("ForceNextStage: A: %d B: %d", aa, bb);
		*/

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Address, "CDirector::ForceNextStage::Address") == false )
		{
			LogError("Failed to find signature: \"CDirector::ForceNextStage::Address\" (%s)", g_sSystem);
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_CDirector_ForceNextStage = EndPrepSDKCall();
			if( g_hSDK_CDirector_ForceNextStage == null )
				LogError("Failed to create SDKCall: \"CDirector::ForceNextStage::Address\" (%s)", g_sSystem);
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "Script_ForceScavengeStart") == false )
		{
			LogError("Failed to find signature: \"Script_ForceScavengeStart\" (%s)", g_sSystem);
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
			g_hSDK_ForceScavengeStart = EndPrepSDKCall();
			if( g_hSDK_ForceScavengeStart == null )
				LogError("Failed to create SDKCall: \"Script_ForceScavengeStart\" (%s)", g_sSystem);
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::IsTankInPlay") == false )
		{
			LogError("Failed to find signature: \"CDirector::IsTankInPlay\" (%s)", g_sSystem);
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
			g_hSDK_CDirector_IsTankInPlay = EndPrepSDKCall();
			if( g_hSDK_CDirector_IsTankInPlay == null )
				LogError("Failed to create SDKCall: \"CDirector::IsTankInPlay\" (%s)", g_sSystem);
		}

		StartPrepSDKCall(SDKCall_Player);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "SurvivorBot::IsReachable") == false )
		{
			LogError("Failed to find signature: \"SurvivorBot::IsReachable\" (%s)", g_sSystem);
		} else {
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
			g_hSDK_SurvivorBot_IsReachable = EndPrepSDKCall();
			if( g_hSDK_SurvivorBot_IsReachable == null )
				LogError("Failed to create SDKCall: \"SurvivorBot::IsReachable\" (%s)", g_sSystem);
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::GetFurthestSurvivorFlow") == false )
		{
			LogError("Failed to find signature: \"CDirector::GetFurthestSurvivorFlow\" (%s)", g_sSystem);
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_Plain);
			g_hSDK_CDirector_GetFurthestSurvivorFlow = EndPrepSDKCall();
			if( g_hSDK_CDirector_GetFurthestSurvivorFlow == null )
				LogError("Failed to create SDKCall: \"CDirector::GetFurthestSurvivorFlow\" (%s)", g_sSystem);
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::GetScriptValueInt") == false )
		{
			LogError("Failed to find signature: \"CDirector::GetScriptValueInt\" (%s)", g_sSystem);
		} else {
			PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_CDirector_GetScriptValueInt = EndPrepSDKCall();
			if( g_hSDK_CDirector_GetScriptValueInt == null )
					LogError("Failed to create SDKCall: \"CDirector::GetScriptValueInt\" (%s)", g_sSystem);
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::GetScriptValueFloat") == false )
		{
			LogError("Failed to find signature: \"CDirector::GetScriptValueFloat\" (%s)", g_sSystem);
		} else {
			PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
			PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
			PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_Plain);
			g_hSDK_CDirector_GetScriptValueFloat = EndPrepSDKCall();
			if( g_hSDK_CDirector_GetScriptValueFloat == null )
					LogError("Failed to create SDKCall: \"CDirector::GetScriptValueFloat\" (%s)", g_sSystem);
		}

		// Crashes when the key has not been set
		/*
		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::GetScriptValueString") == false )
		{
			LogError("Failed to find signature: \"CDirector::GetScriptValueString\" (%s)", g_sSystem);
		} else {
			PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
			PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
			PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_SetReturnInfo(SDKType_String, SDKPass_Pointer);
			// PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_CDirector_GetScriptValueString = EndPrepSDKCall();
			if( g_hSDK_CDirector_GetScriptValueString == null )
					LogError("Failed to create SDKCall: \"CDirector::GetScriptValueString\" (%s)", g_sSystem);
		}
		*/
	}

	StartPrepSDKCall(SDKCall_Static);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "NavAreaTravelDistance") == false )
	{
		LogError("Failed to find signature: \"NavAreaTravelDistance\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		if( g_bLeft4Dead2 )
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_Plain);
		g_hSDK_NavAreaTravelDistance = EndPrepSDKCall();
		if( g_hSDK_NavAreaTravelDistance == null )
			LogError("Failed to create SDKCall: \"NavAreaTravelDistance\" (%s)", g_sSystem);
	}



	// =========================
	// MAIN - left4downtown.inc
	// =========================
	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::RestartScenarioFromVote") == false )
	{
		LogError("Failed to find signature: \"CDirector::RestartScenarioFromVote\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CDirector_RestartScenarioFromVote = EndPrepSDKCall();
		if( g_hSDK_CDirector_RestartScenarioFromVote == null )
			LogError("Failed to create SDKCall: \"CDirector::RestartScenarioFromVote\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_GameRules);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorGameRules::GetTeamScore") == false )
	{
		LogError("Failed to find signature: \"CTerrorGameRules::GetTeamScore\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CTerrorGameRules_GetTeamScore = EndPrepSDKCall();
		if( g_hSDK_CTerrorGameRules_GetTeamScore == null )
			LogError("Failed to create SDKCall: \"CTerrorGameRules::GetTeamScore\" (%s)", g_sSystem);
	}

	if( g_bLeft4Dead2 )
	{
		StartPrepSDKCall(SDKCall_Raw);
	} else {
		StartPrepSDKCall(SDKCall_Static);
	}
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::IsFirstMapInScenario") == false )
	{
		LogError("Failed to find signature: \"CDirector::IsFirstMapInScenario\" (%s)", g_sSystem);
	} else {
		if( !g_bLeft4Dead2 )
		{
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain, VDECODE_FLAG_ALLOWWORLD);
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		}
		g_hSDK_CDirector_IsFirstMapInScenario = EndPrepSDKCall();
		if( g_hSDK_CDirector_IsFirstMapInScenario == null )
			LogError("Failed to create SDKCall: \"IsFirstMapInScenario\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_GameRules);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorGameRules::IsMissionFinalMap") == false )
	{
		LogError("Failed to find signature: \"CTerrorGameRules::IsMissionFinalMap\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_CTerrorGameRules_IsMissionFinalMap = EndPrepSDKCall();
		if( g_hSDK_CTerrorGameRules_IsMissionFinalMap == null )
			LogError("Failed to create SDKCall: \"CTerrorGameRules::IsMissionFinalMap\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "KeyValues::GetString") == false )
	{
		LogError("Failed to find signature: \"KeyValues::GetString\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		PrepSDKCall_SetReturnInfo(SDKType_String, SDKPass_Pointer);
		g_hSDK_KeyValues_GetString = EndPrepSDKCall();
		if( g_hSDK_KeyValues_GetString == null )
			LogError("Failed to create SDKCall: \"KeyValues::GetString\" (%s)", g_sSystem);
	}

	if( g_bLeft4Dead2 )
	{
		StartPrepSDKCall(SDKCall_GameRules);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorGameRules::GetNumChaptersForMissionAndMode") == false )
		{
			LogError("Failed to find signature: \"CTerrorGameRules::GetNumChaptersForMissionAndMode\" (%s)", g_sSystem);
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_CTerrorGameRules_GetNumChaptersForMissionAndMode = EndPrepSDKCall();
			if( g_hSDK_CTerrorGameRules_GetNumChaptersForMissionAndMode == null )
				LogError("Failed to create SDKCall: \"CTerrorGameRules::GetNumChaptersForMissionAndMode\" (%s)", g_sSystem);
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::GetGameModeBase") == false )
		{
			LogError("Failed to find signature: \"CDirector::GetGameModeBase\" (%s)", g_sSystem);
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_String, SDKPass_Pointer);
			g_hSDK_CDirector_GetGameModeBase = EndPrepSDKCall();
			if( g_hSDK_CDirector_GetGameModeBase == null )
				LogError("Failed to create SDKCall: \"CDirector::GetGameModeBase\" (%s)", g_sSystem);
		}

		StartPrepSDKCall(SDKCall_GameRules);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorGameRules::IsGenericCooperativeMode") == false )
		{
			LogError("Failed to find signature: \"CTerrorGameRules::IsGenericCooperativeMode\" (%s)", g_sSystem);
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_CTerrorGameRules_IsGenericCooperativeMode = EndPrepSDKCall();
			if( g_hSDK_CTerrorGameRules_IsGenericCooperativeMode == null )
				LogError("Failed to create SDKCall: \"CTerrorGameRules::IsGenericCooperativeMode\" (%s)", g_sSystem);
		}
	}

	StartPrepSDKCall(SDKCall_GameRules);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CGameRulesProxy::NotifyNetworkStateChanged") == false )
	{
		LogError("Failed to find signature: \"CGameRulesProxy::NotifyNetworkStateChanged\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CGameRulesProxy_NotifyNetworkStateChanged = EndPrepSDKCall();
		if( g_hSDK_CGameRulesProxy_NotifyNetworkStateChanged == null )
			LogError("Failed to create SDKCall: \"CGameRulesProxy::NotifyNetworkStateChanged\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::OnStaggered") == false )
	{
		LogError("Failed to find signature: \"CTerrorPlayer::StaggerPlayer\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CTerrorPlayer_OnStaggered = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_OnStaggered == null )
			LogError("Failed to create SDKCall: \"CTerrorPlayer::OnStaggered\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirectorScriptedEventManager::SendInRescueVehicle") == false )
	{
		LogError("Failed to find signature: \"CDirectorScriptedEventManager::SendInRescueVehicle\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_CDirectorScriptedEventManager_SendInRescueVehicle = EndPrepSDKCall();
		if( g_hSDK_CDirectorScriptedEventManager_SendInRescueVehicle == null )
			LogError("Failed to create SDKCall: \"CDirectorScriptedEventManager::SendInRescueVehicle\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "ZombieManager::ReplaceTank") == false )
	{
		LogError("Failed to find signature: \"ZombieManager::ReplaceTank\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_ZombieManager_ReplaceTank = EndPrepSDKCall();
		if( g_hSDK_ZombieManager_ReplaceTank == null )
			LogError("Failed to create SDKCall: \"ZombieManager::ReplaceTank\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "ZombieManager::SpawnTank") == false )
	{
		LogError("Failed to find signature: \"ZombieManager::SpawnTank\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
		PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDK_ZombieManager_SpawnTank = EndPrepSDKCall();
		if( g_hSDK_ZombieManager_SpawnTank == null )
			LogError("Failed to create SDKCall: \"ZombieManager::SpawnTank\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "ZombieManager::SpawnWitch") == false )
	{
		LogError("Failed to find signature: \"ZombieManager::SpawnWitch\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
		PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDK_ZombieManager_SpawnWitch = EndPrepSDKCall();
		if( g_hSDK_ZombieManager_SpawnWitch == null )
			LogError("Failed to create SDKCall: \"ZombieManager::SpawnWitch\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::IsFinaleEscapeInProgress") == false )
	{
		LogError("Failed to find signature: \"CDirector::IsFinaleEscapeInProgress\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_CDirector_IsFinaleEscapeInProgress = EndPrepSDKCall();
		if( g_hSDK_CDirector_IsFinaleEscapeInProgress == null )
			LogError("Failed to create SDKCall: \"CDirector::IsFinaleEscapeInProgress\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "SurvivorBot::SetHumanSpectator") == false )
	{
		LogError("Failed to find signature: \"SurvivorBot::SetHumanSpectator\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_SurvivorBot_SetHumanSpectator = EndPrepSDKCall();
		if( g_hSDK_SurvivorBot_SetHumanSpectator == null )
			LogError("Failed to create SDKCall: \"SurvivorBot::SetHumanSpectator\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::TakeOverBot") == false )
	{
		LogError("Failed to find signature: \"CTerrorPlayer::TakeOverBot\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_CTerrorPlayer_TakeOverBot = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_TakeOverBot == null )
			LogError("Failed to create SDKCall: \"CTerrorPlayer::TakeOverBot\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::CanBecomeGhost") == false )
	{
		LogError("Failed to find signature: \"CTerrorPlayer::CanBecomeGhost\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_CTerrorPlayer_CanBecomeGhost = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_CanBecomeGhost == null )
			LogError("Failed to create SDKCall: \"CTerrorPlayer::CanBecomeGhost\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::SetBecomeGhostAt") == false )
	{
		LogError("Failed to find signature: \"CTerrorPlayer::SetBecomeGhostAt\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CTerrorPlayer_SetBecomeGhostAt = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_SetBecomeGhostAt == null )
			LogError("Failed to create SDKCall: \"CTerrorPlayer::SetBecomeGhostAt\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::GoAwayFromKeyboard") == false )
	{
		LogError("Failed to find signature: \"CTerrorPlayer::GoAwayFromKeyboard\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_CTerrorPlayer_GoAwayFromKeyboard = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_GoAwayFromKeyboard == null )
			LogError("Failed to create SDKCall: \"CTerrorPlayer::GoAwayFromKeyboard\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::TryOfferingTankBot") == false )
	{
		LogError("Failed to find signature: \"CDirector::TryOfferingTankBot\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CDirector_TryOfferingTankBot = EndPrepSDKCall();
		if( g_hSDK_CDirector_TryOfferingTankBot == null )
			LogError("Failed to create SDKCall: \"CDirector::TryOfferingTankBot\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CNavMesh::GetNavArea") == false )
	{
		LogError("Failed to find signature: \"CNavMesh::GetNavArea\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CNavMesh_GetNavArea = EndPrepSDKCall();
		if( g_hSDK_CNavMesh_GetNavArea == null )
			LogError("Failed to create SDKCall: \"CNavMesh::GetNavArea\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CNavArea::IsConnected") == false )
	{
		LogError("Failed to find signature: \"CNavArea::IsConnected\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_CNavArea_IsConnected = EndPrepSDKCall();
		if( g_hSDK_CNavArea_IsConnected == null )
			LogError("Failed to create SDKCall: \"CNavArea::IsConnected\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::GetFlowDistance") == false )
	{
		LogError("Failed to find signature: \"CTerrorPlayer::GetFlowDistance\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_Plain);
		g_hSDK_CTerrorPlayer_GetFlowDistance = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_GetFlowDistance == null )
			LogError("Failed to create SDKCall: \"CTerrorPlayer::GetFlowDistance\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::SetShovePenalty") == false )
	{
		LogError("Failed to find signature: \"CTerrorPlayer::SetShovePenalty\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CTerrorPlayer_SetShovePenalty = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_SetShovePenalty == null )
			LogError("Failed to create SDKCall: \"CTerrorPlayer::SetShovePenalty\" (%s)", g_sSystem);
	}

	/*
	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::SetNextShoveTime") == false )
	{
		LogError("Failed to find signature: \"CTerrorPlayer::SetNextShoveTime\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CTerrorPlayer_SetNextShoveTime = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_SetNextShoveTime == null )
			LogError("Failed to create SDKCall: \"CTerrorPlayer::SetNextShoveTime\" (%s)", g_sSystem);
	}
	*/

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::DoAnimationEvent") == false )
	{
		LogError("Failed to find signature: \"CTerrorPlayer::DoAnimationEvent\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CTerrorPlayer_DoAnimationEvent = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_DoAnimationEvent == null )
			LogError("Failed to create SDKCall: \"CTerrorPlayer::DoAnimationEvent\" (%s)", g_sSystem);
	}

	if( !g_bLeft4Dead2 )
	{
		StartPrepSDKCall(SDKCall_GameRules);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorGameRules::RecomputeTeamScores") == false )
		{
			LogError("Failed to find signature: \"CTerrorGameRules::RecomputeTeamScores\" (%s)", g_sSystem);
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_CTerrorGameRules_RecomputeTeamScores = EndPrepSDKCall();
			if( g_hSDK_CTerrorGameRules_RecomputeTeamScores == null )
				LogError("Failed to create SDKCall: \"CTerrorGameRules::RecomputeTeamScores\" (%s)", g_sSystem);
		}
	}



	if( g_bLeft4Dead2 )
	{
		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CMeleeWeaponInfoStore::GetMeleeWeaponInfo") == false )
		{
			LogError("Failed to find signature: \"CMeleeWeaponInfoStore::GetMeleeWeaponInfo\" (%s)", g_sSystem);
		} else {
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_CMeleeWeaponInfoStore_GetMeleeWeaponInfo = EndPrepSDKCall();
			if( g_hSDK_CMeleeWeaponInfoStore_GetMeleeWeaponInfo == null )
				LogError("Failed to create SDKCall: \"CMeleeWeaponInfoStore::GetMeleeWeaponInfo\" (%s)", g_sSystem);
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::ResetMobTimer") == false )
		{
			LogError("Failed to find signature: \"CDirector::ResetMobTimer\" (%s)", g_sSystem);
		} else {
			g_hSDK_CDirector_ResetMobTimer = EndPrepSDKCall();
			if( g_hSDK_CDirector_ResetMobTimer == null )
				LogError("Failed to create SDKCall: \"CDirector::ResetMobTimer\" (%s)", g_sSystem);
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirectorScriptedEventManager::ChangeFinaleStage") == false )
		{
			LogError("Failed to find signature: \"CDirectorScriptedEventManager::ChangeFinaleStage\" (%s)", g_sSystem);
		} else {
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_CDirectorScriptedEventManager_ChangeFinaleStage = EndPrepSDKCall();
			if( g_hSDK_CDirectorScriptedEventManager_ChangeFinaleStage == null )
				LogError("Failed to create SDKCall: \"CDirectorScriptedEventManager::ChangeFinaleStage\" (%s)", g_sSystem);
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "ZombieManager::SpawnSpecial") == false )
		{
			LogError("Failed to find signature: \"ZombieManager::SpawnSpecial\" (%s)", g_sSystem);
		} else {
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
			PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
			g_hSDK_ZombieManager_SpawnSpecial = EndPrepSDKCall();
			if( g_hSDK_ZombieManager_SpawnSpecial == null )
				LogError("Failed to create SDKCall: \"ZombieManager::SpawnSpecial\" (%s)", g_sSystem);
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "ZombieManager::SpawnWitchBride") == false )
		{
			LogError("Failed to find signature: \"ZombieManager::SpawnWitchBride\" (%s)", g_sSystem);
		} else {
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
			PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
			g_hSDK_ZombieManager_SpawnWitchBride = EndPrepSDKCall();
			if( g_hSDK_ZombieManager_SpawnWitchBride == null )
				LogError("Failed to create SDKCall: \"ZombieManager::SpawnWitchBride\" (%s)", g_sSystem);
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::AreWanderersAllowed") == false )
		{
			LogError("Failed to find signature: \"CDirector::AreWanderersAllowed\" (%s)", g_sSystem);
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
			g_hSDK_CDirector_AreWanderersAllowed = EndPrepSDKCall();
			if( g_hSDK_CDirector_AreWanderersAllowed == null )
				LogError("Failed to create SDKCall: \"CDirector::AreWanderersAllowed\" (%s)", g_sSystem);
		}
	} else {
	// L4D1 only:
		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "ZombieManager::SpawnHunter") == false )
		{
			LogError("Failed to find signature: \"ZombieManager::SpawnHunter\" (%s)", g_sSystem);
		} else {
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
			PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
			g_hSDK_ZombieManager_SpawnHunter = EndPrepSDKCall();
			if( g_hSDK_ZombieManager_SpawnHunter == null )
				LogError("Failed to create SDKCall: \"ZombieManager::SpawnHunter\" (%s)", g_sSystem);
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "ZombieManager::SpawnBoomer") == false )
		{
			LogError("Failed to find signature: \"ZombieManager::SpawnBoomer\" (%s)", g_sSystem);
		} else {
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
			PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
			g_hSDK_ZombieManager_SpawnBoomer = EndPrepSDKCall();
			if( g_hSDK_ZombieManager_SpawnBoomer == null )
				LogError("Failed to create SDKCall: \"ZombieManager::SpawnBoomer\" (%s)", g_sSystem);
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "ZombieManager::SpawnSmoker") == false )
		{
			LogError("Failed to find signature: \"ZombieManager::SpawnSmoker\" (%s)", g_sSystem);
		} else {
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
			PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
			g_hSDK_ZombieManager_SpawnSmoker = EndPrepSDKCall();
			if( g_hSDK_ZombieManager_SpawnSmoker == null )
				LogError("Failed to create SDKCall: \"ZombieManager::SpawnSmoker\" (%s)", g_sSystem);
		}
	}



	// =========================
	// l4d2addresses.txt
	// =========================
	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::OnVomitedUpon") == false )
	{
		LogError("Failed to find signature: \"CTerrorPlayer::OnVomitedUpon\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		g_hSDK_CTerrorPlayer_OnVomitedUpon = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_OnVomitedUpon == null )
			LogError("Failed to create SDKCall: \"CTerrorPlayer::OnVomitedUpon\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::CancelStagger") == false )
	{
		LogError("Failed to find signature: \"CTerrorPlayer::CancelStagger\" (%s)", g_sSystem);
	} else {
		g_hSDK_CTerrorPlayer_CancelStagger = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_CancelStagger == null )
			LogError("Failed to create SDKCall: \"CTerrorPlayer::CancelStagger\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::FindUseEntity") == false )
	{
		LogError("Failed to find signature: \"CTerrorPlayer::FindUseEntity\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_AddParameter(SDKType_Float,SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Float,SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Float,SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData,SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Bool,SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDK_CTerrorPlayer_FindUseEntity = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_FindUseEntity == null )
			LogError("Failed to create SDKCall: \"CTerrorPlayer::FindUseEntity\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::OnPouncedOnSurvivor") == false )
		SetFailState("Failed to find signature: CTerrorPlayer::OnPouncedOnSurvivor");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hSDK_CTerrorPlayer_OnPouncedOnSurvivor = EndPrepSDKCall();
	if( g_hSDK_CTerrorPlayer_OnPouncedOnSurvivor == null )
		SetFailState("Failed to create SDKCall: CTerrorPlayer::OnPouncedOnSurvivor");

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::GrabVictimWithTongue") == false )
		SetFailState("Failed to find signature: CTerrorPlayer::GrabVictimWithTongue");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hSDK_CTerrorPlayer_GrabVictimWithTongue = EndPrepSDKCall();
	if( g_hSDK_CTerrorPlayer_GrabVictimWithTongue == null )
		SetFailState("Failed to create SDKCall: CTerrorPlayer::GrabVictimWithTongue");

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::ReleaseTongueVictim") == false )
		SetFailState("Failed to find signature: CTerrorPlayer::ReleaseTongueVictim");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hSDK_CTerrorPlayer_ReleaseTongueVictim = EndPrepSDKCall();
	if( g_hSDK_CTerrorPlayer_ReleaseTongueVictim == null )
		SetFailState("Failed to create SDKCall: CTerrorPlayer::ReleaseTongueVictim");

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::OnPounceEnded") == false )
		SetFailState("Failed to find signature: CTerrorPlayer::OnPounceEnded");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hSDK_CTerrorPlayer_OnPounceEnded = EndPrepSDKCall();
	if( g_hSDK_CTerrorPlayer_OnPounceEnded == null )
		SetFailState("Failed to create SDKCall: CTerrorPlayer::OnPounceEnded");

	if( g_bLeft4Dead2 )
	{
		StartPrepSDKCall(SDKCall_Player);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::OnLeptOnSurvivor") == false )
			SetFailState("Failed to find signature: CTerrorPlayer::OnLeptOnSurvivor");
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDK_CTerrorPlayer_OnLeptOnSurvivor = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_OnLeptOnSurvivor == null )
			SetFailState("Failed to create SDKCall: CTerrorPlayer::OnLeptOnSurvivor");

		StartPrepSDKCall(SDKCall_Static);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "ThrowImpactedSurvivor") == false )
			SetFailState("Failed to find signature: ThrowImpactedSurvivor");
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		g_hSDK_ThrowImpactedSurvivor = EndPrepSDKCall();
		if( g_hSDK_ThrowImpactedSurvivor == null )
			SetFailState("Failed to create SDKCall: ThrowImpactedSurvivor");

		StartPrepSDKCall(SDKCall_Player);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::OnStartCarryingVictim") == false )
			SetFailState("Failed to find signature: CTerrorPlayer::OnStartCarryingVictim");
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDK_CTerrorPlayer_OnStartCarryingVictim = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_OnStartCarryingVictim == null )
			SetFailState("Failed to create SDKCall: CTerrorPlayer::OnStartCarryingVictim");

		StartPrepSDKCall(SDKCall_Player);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::QueuePummelVictim") == false )
			SetFailState("Failed to find signature: CTerrorPlayer::QueuePummelVictim");
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_ByValue);
		g_hSDK_CTerrorPlayer_QueuePummelVictim = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_QueuePummelVictim == null )
			SetFailState("Failed to create SDKCall: CTerrorPlayer::QueuePummelVictim");

		StartPrepSDKCall(SDKCall_Player);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::OnPummelEnded") == false )
			SetFailState("Failed to find signature: CTerrorPlayer::OnPummelEnded");
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDK_CTerrorPlayer_OnPummelEnded = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_OnPummelEnded == null )
			SetFailState("Failed to create SDKCall: CTerrorPlayer::OnPummelEnded");

		StartPrepSDKCall(SDKCall_Player);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::OnCarryEnded") == false )
			SetFailState("Failed to find signature: CTerrorPlayer::OnCarryEnded");
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDK_CTerrorPlayer_OnCarryEnded = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_OnCarryEnded == null )
			SetFailState("Failed to create SDKCall: CTerrorPlayer::OnCarryEnded");

		StartPrepSDKCall(SDKCall_Player);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::OnRideEnded") == false )
			SetFailState("Failed to find signature: CTerrorPlayer::OnRideEnded");
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDK_CTerrorPlayer_OnRideEnded = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_OnRideEnded == null )
			SetFailState("Failed to create SDKCall: CTerrorPlayer::OnRideEnded");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::RoundRespawn") == false )
	{
		LogError("Failed to find signature: \"CTerrorPlayer::RoundRespawn\" (%s)", g_sSystem);
	} else {
		g_hSDK_CTerrorPlayer_RoundRespawn = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_RoundRespawn == null )
			LogError("Failed to create SDKCall: \"CTerrorPlayer::RoundRespawn\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::CreateRescuableSurvivors") == false )
	{
		LogError("Failed to find signature: \"CDirector::CreateRescuableSurvivors\" (%s)", g_sSystem);
	} else {
		g_hSDK_CDirector_CreateRescuableSurvivors = EndPrepSDKCall();
		if( g_hSDK_CDirector_CreateRescuableSurvivors == null )
			LogError("Failed to create SDKCall: \"CDirector::CreateRescuableSurvivors\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::OnRevived") == false )
	{
		LogError("Failed to find signature: \"CTerrorPlayer::OnRevived\" (%s)", g_sSystem);
	} else {
		g_hSDK_CTerrorPlayer_OnRevived = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_OnRevived == null )
			LogError("Failed to create SDKCall: \"CTerrorPlayer::OnRevived\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Static);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirectorTacticalServices::GetHighestFlowSurvivor") == false )
	{
		LogError("Failed to find signature: \"CDirectorTacticalServices::GetHighestFlowSurvivor\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDK_CDirectorTacticalServices_GetHighestFlowSurvivor = EndPrepSDKCall();
		if( g_hSDK_CDirectorTacticalServices_GetHighestFlowSurvivor == null )
			LogError("Failed to create SDKCall: \"CDirectorTacticalServices::GetHighestFlowSurvivor\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Entity);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "Infected::GetFlowDistance") == false )
	{
		LogError("Failed to find signature: \"Infected::GetFlowDistance\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_Plain);
		g_hSDK_Infected_GetFlowDistance = EndPrepSDKCall();
		if( g_hSDK_Infected_GetFlowDistance == null )
			LogError("Failed to create SDKCall: \"Infected::GetFlowDistance\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::TakeOverZombieBot") == false )
	{
		LogError("Failed to find signature: \"CTerrorPlayer::TakeOverZombieBot\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		g_hSDK_CTerrorPlayer_TakeOverZombieBot = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_TakeOverZombieBot == null )
			LogError("Failed to create SDKCall: \"CTerrorPlayer::TakeOverZombieBot\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::ReplaceWithBot") == false )
	{
		LogError("Failed to find signature: \"CTerrorPlayer::ReplaceWithBot\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		g_hSDK_CTerrorPlayer_ReplaceWithBot = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_ReplaceWithBot == null )
			LogError("Failed to create SDKCall: \"CTerrorPlayer::ReplaceWithBot\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::CullZombie") == false )
	{
		LogError("Failed to find signature: \"CTerrorPlayer::CullZombie\" (%s)", g_sSystem);
	} else {
		g_hSDK_CTerrorPlayer_CullZombie = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_CullZombie == null )
			LogError("Failed to create SDKCall: \"CTerrorPlayer::CullZombie\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::CleanupPlayerState") == false )
	{
		LogError("Failed to find signature: \"CTerrorPlayer::CleanupPlayerState\" (%s)", g_sSystem);
	} else {
		g_hSDK_CTerrorPlayer_CleanupPlayerState = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_CleanupPlayerState == null )
			LogError("Failed to create SDKCall: \"CTerrorPlayer::CleanupPlayerState\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::SetClass") == false )
	{
		LogError("Failed to find signature: \"CTerrorPlayer::SetClass\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CTerrorPlayer_SetClass = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_SetClass == null )
			LogError("Failed to create SDKCall: \"CTerrorPlayer::SetClass\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Static);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CBaseAbility::CreateForPlayer") == false )
	{
		LogError("Failed to find signature: \"CBaseAbility::CreateForPlayer\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDK_CBaseAbility_CreateForPlayer = EndPrepSDKCall();
		if( g_hSDK_CBaseAbility_CreateForPlayer == null )
			LogError("Failed to create SDKCall: \"CBaseAbility::CreateForPlayer\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::MaterializeFromGhost") == false )
	{
		LogError("Failed to find signature: \"CTerrorPlayer::MaterializeFromGhost\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CTerrorPlayer_MaterializeFromGhost = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_MaterializeFromGhost == null )
			LogError("Failed to create SDKCall: \"CTerrorPlayer::MaterializeFromGhost\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::BecomeGhost") == false )
	{
		LogError("Failed to find signature: \"CTerrorPlayer::BecomeGhost\" (%s)", g_sSystem);
	} else {
		if( g_bLeft4Dead2 )
			PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		else
		{
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		}
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CTerrorPlayer_BecomeGhost = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_BecomeGhost == null )
			LogError("Failed to create SDKCall: \"CTerrorPlayer::BecomeGhost\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CCSPlayer::State_Transition") == false )
	{
		LogError("Failed to find signature: \"CCSPlayer::State_Transition\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CCSPlayer_State_Transition = EndPrepSDKCall();
		if( g_hSDK_CCSPlayer_State_Transition == null )
			LogError("Failed to create SDKCall: \"CCSPlayer::State_Transition\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::RegisterForbiddenTarget") == false )
	{
		LogError("Failed to find signature: \"CDirector::RegisterForbiddenTarget\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CDirector_RegisterForbiddenTarget = EndPrepSDKCall();
		if( g_hSDK_CDirector_RegisterForbiddenTarget == null )
			LogError("Failed to create SDKCall: \"CDirector::RegisterForbiddenTarget\" (%s)", g_sSystem);
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::UnregisterForbiddenTarget") == false )
	{
		LogError("Failed to find signature: \"CDirector::UnregisterForbiddenTarget\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDK_CDirector_UnregisterForbiddenTarget = EndPrepSDKCall();
		if( g_hSDK_CDirector_UnregisterForbiddenTarget == null )
			LogError("Failed to create SDKCall: \"CDirector::UnregisterForbiddenTarget\" (%s)", g_sSystem);
	}



	if( g_bLeft4Dead2 )
	{
		StartPrepSDKCall(SDKCall_Player);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::OnHitByVomitJar") == false )
		{
			LogError("Failed to find signature: \"CTerrorPlayer::OnHitByVomitJar\" (%s)", g_sSystem);
		} else {
			PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
			g_hSDK_CTerrorPlayer_OnHitByVomitJar = EndPrepSDKCall();
			if( g_hSDK_CTerrorPlayer_OnHitByVomitJar == null )
				LogError("Failed to create SDKCall: \"CTerrorPlayer::OnHitByVomitJar\" (%s)", g_sSystem);
		}

		StartPrepSDKCall(SDKCall_Entity);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "Infected::OnHitByVomitJar") == false )
		{
			LogError("Failed to find signature: \"Infected::OnHitByVomitJar\" (%s)", g_sSystem);
		} else {
			PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
			g_hSDK_Infected_OnHitByVomitJar = EndPrepSDKCall();
			if( g_hSDK_Infected_OnHitByVomitJar == null )
				LogError("Failed to create SDKCall: \"Infected::OnHitByVomitJar\" (%s)", g_sSystem);
		}

		StartPrepSDKCall(SDKCall_Player);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::Fling") == false )
		{
			LogError("Failed to find signature: \"CTerrorPlayer::Fling\" (%s)", g_sSystem);
		} else {
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
			PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
			g_hSDK_CTerrorPlayer_Fling = EndPrepSDKCall();
			if( g_hSDK_CTerrorPlayer_Fling == null )
				LogError("Failed to create SDKCall: \"CTerrorPlayer::Fling\" (%s)", g_sSystem);
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorGameRules::GetVersusCompletion") == false )
		{
			LogError("Failed to find signature: \"CTerrorGameRules::GetVersusCompletion\" (%s)", g_sSystem);
		} else {
			PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_CTerrorGameRules_GetVersusCompletion = EndPrepSDKCall();
			if( g_hSDK_CTerrorGameRules_GetVersusCompletion == null )
				LogError("Failed to create SDKCall: \"CTerrorGameRules::GetVersusCompletion\" (%s)", g_sSystem);
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::SwapTeams") == false )
		{
			LogError("Failed to find signature: \"CDirector::SwapTeams\" (%s)", g_sSystem);
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_CDirector_SwapTeams = EndPrepSDKCall();
			if( g_hSDK_CDirector_SwapTeams == null )
				LogError("Failed to create SDKCall: \"CDirector::SwapTeams\" (%s)", g_sSystem);
		}

		/*
		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::AreTeamsFlipped") == false )
		{
			LogError("Failed to find signature: \"CDirector::AreTeamsFlipped\" (%s)", g_sSystem);
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_CDirector_AreTeamsFlipped = EndPrepSDKCall();
			if( g_hSDK_CDirector_AreTeamsFlipped == null )
				LogError("Failed to create SDKCall: \"CDirector::AreTeamsFlipped\" (%s)", g_sSystem);
		}
		*/

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::StartRematchVote") == false )
		{
			LogError("Failed to find signature: \"CDirector::StartRematchVote\" (%s)", g_sSystem);
		} else {
			g_hSDK_CDirector_StartRematchVote = EndPrepSDKCall();
			if( g_hSDK_CDirector_StartRematchVote == null )
				LogError("Failed to create SDKCall: \"CDirector::StartRematchVote\" (%s)", g_sSystem);
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::FullRestart") == false )
		{
			LogError("Failed to find signature: \"CDirector::FullRestart\" (%s)", g_sSystem);
		} else {
			g_hSDK_CDirector_FullRestart = EndPrepSDKCall();
			if( g_hSDK_CDirector_FullRestart == null )
				LogError("Failed to create SDKCall: \"CDirector::FullRestart\" (%s)", g_sSystem);
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirectorVersusMode::HideScoreboardNonVirtual") == false )
		{
			LogError("Failed to find signature: \"CDirectorVersusMode::HideScoreboardNonVirtual\" (%s)", g_sSystem);
		} else {
			g_hSDK_CDirectorVersusMode_HideScoreboardNonVirtual = EndPrepSDKCall();
			if( g_hSDK_CDirectorVersusMode_HideScoreboardNonVirtual == null )
				LogError("Failed to create SDKCall: \"CDirectorVersusMode::HideScoreboardNonVirtual\" (%s)", g_sSystem);
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirectorScavengeMode::HideScoreboardNonVirtual") == false )
		{
			LogError("Failed to find signature: \"CDirectorScavengeMode::HideScoreboardNonVirtual\" (%s)", g_sSystem);
		} else {
			g_hSDK_CDirectorScavengeMode_HideScoreboardNonVirtual = EndPrepSDKCall();
			if( g_hSDK_CDirectorScavengeMode_HideScoreboardNonVirtual == null )
				LogError("Failed to create SDKCall: \"CDirectorScavengeMode::HideScoreboardNonVirtual\" (%s)", g_sSystem);
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::HideScoreboard") == false )
		{
			LogError("Failed to find signature: \"CDirector::CDirectorHideScoreboard\" (%s)", g_sSystem);
		} else {
			g_hSDK_CDirector_HideScoreboard = EndPrepSDKCall();
			if( g_hSDK_CDirector_HideScoreboard == null )
				LogError("Failed to create SDKCall: \"CDirector::HideScoreboard\" (%s)", g_sSystem);
		}
	}

	StartPrepSDKCall(SDKCall_Static); // Since SM 1.11 can use "SDKCall_Server" (but that crashes the server)
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CBaseServer::SetReservationCookie") == false )
	{
		LogError("Failed to find signature: \"CBaseServer::SetReservationCookie\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		g_hSDK_CBaseServer_SetReservationCookie = EndPrepSDKCall();
		if( g_hSDK_CBaseServer_SetReservationCookie == null )
			LogError("Failed to create SDKCall: \"CBaseServer::SetReservationCookie\" (%s)", g_sSystem);
	}



	// UNUSED / BROKEN
	/* DEPRECATED
	StartPrepSDKCall(SDKCall_Static);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "GetCampaignScores") == false )
	{
		LogError("Failed to find signature: \"GetCampaignScores\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_GetCampaignScores = EndPrepSDKCall();
		if( g_hSDK_GetCampaignScores == null )
			LogError("Failed to create SDKCall: \"GetCampaignScores\" (%s)", g_sSystem);
	}
	// */

	/* DEPRECATED on L4D2 and L4D1 Linux
	StartPrepSDKCall(SDKCall_Static);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "LobbyIsReserved") == false )
	{
		LogError("Failed to find signature: \"LobbyIsReserved\" (%s)", g_sSystem);
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_LobbyIsReserved = EndPrepSDKCall();
		if( g_hSDK_LobbyIsReserved == null )
			LogError("Failed to create SDKCall: \"LobbyIsReserved\" (%s)", g_sSystem);
	}
	// */



	// ====================================================================================================
	//									POINTER OFFSETS
	// ====================================================================================================
	if( g_bLeft4Dead2 )
	{
		g_pScavengeMode = hGameData.GetOffset("ScavengeModePtr");
		ValidateOffset(g_pScavengeMode, "ScavengeModePtr");

		g_pVersusMode = hGameData.GetOffset("VersusModePtr");
		ValidateOffset(g_pVersusMode, "VersusModePtr");

		g_pScriptedEventManager = hGameData.GetOffset("ScriptedEventManagerPtr");
		ValidateOffset(g_pScriptedEventManager, "ScriptedEventManagerPtr");



		// DisableAddons
		g_pVanillaModeAddress = hGameData.GetAddress("VanillaModeAddress");
		ValidateAddress(g_pVanillaModeAddress, "VanillaModeAddress", true);

		g_iOff_VanillaModeOffset = hGameData.GetOffset("VanillaModeOffset");
		ValidateOffset(g_iOff_VanillaModeOffset, "VanillaModeOffset");
	// } else {
		// TeamScoresAddress = hGameData.GetAddress("CTerrorGameRules::ClearTeamScores");
		// if( TeamScoresAddress == Address_Null ) LogError("Failed to find address \"CTerrorGameRules::ClearTeamScores\" (%s)", g_sSystem);

		// ClearTeamScore_A = hGameData.GetOffset("ClearTeamScore_A");
		// if( ClearTeamScore_A == -1 ) LogError("Failed to find \"ClearTeamScore_A\" offset (%s)", g_sSystem);

		// ClearTeamScore_B = hGameData.GetOffset("ClearTeamScore_B");
		// if( ClearTeamScore_B == -1 ) LogError("Failed to find \"ClearTeamScore_B\" offset (%s)", g_sSystem);
	}

	#if defined DEBUG
	#if DEBUG
	if( g_bLeft4Dead2 )
	{
		PrintToServer("");
		PrintToServer("Ptr Offsets:");
		PrintToServer("%12d == VersusModePtr", g_pVersusMode);
		PrintToServer("%12d == ScavengeModePtr", g_pScavengeMode);
		PrintToServer("%12d == ScriptedEventManagerPtr", g_pScriptedEventManager);
		PrintToServer("%12d == VanillaModeAddress", g_pVanillaModeAddress);
		PrintToServer("%12d == VanillaModeOffset (Win=0, Nix=4)", g_iOff_VanillaModeOffset);
	// } else {
		// PrintToServer("%12d == TeamScoresAddress", TeamScoresAddress);
		// PrintToServer("%12d == ClearTeamScore_A", ClearTeamScore_A);
		// PrintToServer("%12d == ClearTeamScore_B", ClearTeamScore_B);
	}
	PrintToServer("");
	#endif
	#endif



	// ====================================================================================================
	//									ADDRESSES
	// ====================================================================================================
	g_iOff_LobbyReservation = hGameData.GetOffset("LobbyReservationOffset");
	ValidateOffset(g_iOff_LobbyReservation, "LobbyReservationOffset");

	g_pDirector = hGameData.GetAddress("CDirector");
	ValidateAddress(g_pDirector, "CDirector", true);

	g_pZombieManager = hGameData.GetAddress("ZombieManager");
	ValidateAddress(g_pZombieManager, "g_pZombieManager", true);

	g_pNavMesh = hGameData.GetAddress("TerrorNavMesh");
	ValidateAddress(g_pNavMesh, "TheNavMesh", true);

	g_pServer = hGameData.GetAddress("ServerAddr");
	ValidateAddress(g_pServer, "g_pServer", true);

	g_pWeaponInfoDatabase = hGameData.GetAddress("WeaponInfoDatabase");
	ValidateAddress(g_pWeaponInfoDatabase, "g_pWeaponInfoDatabase", true);

	if( g_bLeft4Dead2 )
	{
		g_hScriptHook = DynamicHook.FromConf(hGameData, "CSquirrelVM::GetValue");

		g_pMeleeWeaponInfoStore = hGameData.GetAddress("MeleeWeaponInfoStore");
		ValidateAddress(g_pMeleeWeaponInfoStore, "g_pMeleeWeaponInfoStore", true);

		g_pScriptedEventManager =			LoadFromAddress(g_pDirector + view_as<Address>(g_pScriptedEventManager), NumberType_Int32);
		ValidateAddress(g_pScriptedEventManager, "ScriptedEventManagerPtr", true);

		g_pVersusMode =						LoadFromAddress(g_pDirector + view_as<Address>(g_pVersusMode), NumberType_Int32);
		ValidateAddress(g_pVersusMode, "VersusModePtr", true);

		g_pScavengeMode =					LoadFromAddress(g_pDirector + view_as<Address>(g_pScavengeMode), NumberType_Int32);
		ValidateAddress(g_pScavengeMode, "ScavengeModePtr", true);
	} else {
		// L4D1: g_pDirector is also g_pVersusMode.
		g_pVersusMode = view_as<int>(g_pDirector);
	}

	#if defined DEBUG
	#if DEBUG
	if( g_bLateLoad )
	{
		LoadGameDataRules(hGameData);
	}

	PrintToServer("Pointers:");
	PrintToServer("%12d == g_pDirector", g_pDirector);
	PrintToServer("%12d == g_pZombieManager", g_pZombieManager);
	PrintToServer("%12d == g_pGameRules", g_pGameRules);
	PrintToServer("%12d == g_pNavMesh", g_pNavMesh);
	PrintToServer("%12d == g_pServer", g_pServer);
	PrintToServer("%12d == g_pWeaponInfoDatabase", g_pWeaponInfoDatabase);
	if( g_bLeft4Dead2 )
	{
		PrintToServer("%12d == g_pMeleeWeaponInfoStore", g_pMeleeWeaponInfoStore);
		PrintToServer("%12d == ScriptedEventManagerPtr", g_pScriptedEventManager);
		PrintToServer("%12d == VersusModePtr", g_pVersusMode);
		PrintToServer("%12d == g_pScavengeMode", g_pScavengeMode);
	}
	PrintToServer("");
	#endif
	#endif



	// ====================================================================================================
	//									OFFSETS
	// ====================================================================================================
	// Various
	#if defined DEBUG
	#if DEBUG
	PrintToServer("Various Offsets:");
	#endif
	#endif

	g_iOff_m_iCampaignScores = hGameData.GetOffset("m_iCampaignScores");
	ValidateOffset(g_iOff_m_iCampaignScores, "m_iCampaignScores");

	g_iOff_m_fTankSpawnFlowPercent = hGameData.GetOffset("m_fTankSpawnFlowPercent");
	ValidateOffset(g_iOff_m_fTankSpawnFlowPercent, "m_fTankSpawnFlowPercent");

	g_iOff_m_fWitchSpawnFlowPercent = hGameData.GetOffset("m_fWitchSpawnFlowPercent");
	ValidateOffset(g_iOff_m_fWitchSpawnFlowPercent, "m_fWitchSpawnFlowPercent");

	g_iOff_m_iTankPassedCount = hGameData.GetOffset("m_iTankPassedCount");
	ValidateOffset(g_iOff_m_iTankPassedCount, "m_iTankPassedCount");

	g_iOff_m_bTankThisRound = hGameData.GetOffset("m_bTankThisRound");
	ValidateOffset(g_iOff_m_bTankThisRound, "m_bTankThisRound");

	g_iOff_m_bWitchThisRound = hGameData.GetOffset("m_bWitchThisRound");
	ValidateOffset(g_iOff_m_bWitchThisRound, "m_bWitchThisRound");

	g_iOff_InvulnerabilityTimer = hGameData.GetOffset("InvulnerabilityTimer");
	ValidateOffset(g_iOff_InvulnerabilityTimer, "InvulnerabilityTimer");

	g_iOff_m_iTankTickets = hGameData.GetOffset("m_iTankTickets");
	ValidateOffset(g_iOff_m_iTankTickets, "m_iTankTickets");

	if( !g_bLeft4Dead2 )
	{
		g_iOff_m_iSurvivorHealthBonus = hGameData.GetOffset("m_iSurvivorHealthBonus");
		ValidateOffset(g_iOff_m_iSurvivorHealthBonus, "m_iSurvivorHealthBonus");

		g_iOff_m_bFirstSurvivorLeftStartArea = hGameData.GetOffset("m_bFirstSurvivorLeftStartArea");
		ValidateOffset(g_iOff_m_bFirstSurvivorLeftStartArea, "m_bFirstSurvivorLeftStartArea");
	}
	else
	{
		g_iOff_m_nFirstClassIndex = hGameData.GetOffset("CDirector::m_nFirstClassIndex");
		ValidateOffset(g_iOff_m_nFirstClassIndex, "CDirector::m_nFirstClassIndex");
	}

	g_iOff_m_flow = hGameData.GetOffset("m_flow");
	ValidateOffset(g_iOff_m_flow, "m_flow");

	g_iOff_m_chapter = hGameData.GetOffset("m_chapter");
	ValidateOffset(g_iOff_m_chapter, "m_chapter");

	g_iOff_m_attributeFlags = hGameData.GetOffset("m_attributeFlags");
	ValidateOffset(g_iOff_m_attributeFlags, "m_attributeFlags");

	g_iOff_m_spawnAttributes = hGameData.GetOffset("m_spawnAttributes");
	ValidateOffset(g_iOff_m_spawnAttributes, "m_spawnAttributes");

	g_iOff_m_PendingMobCount = hGameData.GetOffset("m_PendingMobCount");
	ValidateOffset(g_iOff_m_PendingMobCount, "m_PendingMobCount");

	g_iOff_m_fMapMaxFlowDistance = hGameData.GetOffset("m_fMapMaxFlowDistance");
	ValidateOffset(g_iOff_m_fMapMaxFlowDistance, "m_fMapMaxFlowDistance");

	g_iOff_m_rescueCheckTimer = hGameData.GetOffset("m_rescueCheckTimer");
	ValidateOffset(g_iOff_m_rescueCheckTimer, "m_rescueCheckTimer");

	g_iOff_VersusMaxCompletionScore = hGameData.GetOffset("VersusMaxCompletionScore");
	ValidateOffset(g_iOff_VersusMaxCompletionScore, "VersusMaxCompletionScore");

	g_iOff_m_iTankCount = hGameData.GetOffset("m_iTankCount");
	ValidateOffset(g_iOff_m_iTankCount, "m_iTankCount");

	g_iOff_MobSpawnTimer = hGameData.GetOffset("MobSpawnTimer");
	ValidateOffset(g_iOff_MobSpawnTimer, "MobSpawnTimer");



	// ====================
	// Patch to allow "L4D_SetBecomeGhostAt" to work. Thanks to "sorallll" for this method.
	// ====================
	// Address to function
	g_pCTerrorPlayer_CanBecomeGhost = hGameData.GetAddress("CTerrorPlayer::CanBecomeGhost::Address");
	ValidateAddress(g_pCTerrorPlayer_CanBecomeGhost, "CTerrorPlayer::CanBecomeGhost::Address", true);

	// Offset to patch
	g_iCanBecomeGhostOffset = hGameData.GetOffset("CTerrorPlayer::CanBecomeGhost::Offset");
	ValidateOffset(g_iCanBecomeGhostOffset, "CTerrorPlayer::CanBecomeGhost::Offset");

	// Patch count and byte match
	int bytes = hGameData.GetOffset("CTerrorPlayer::CanBecomeGhost::Bytes");
	int count = hGameData.GetOffset("CTerrorPlayer::CanBecomeGhost::Count");

	// Verify bytes and patch
	int byte = LoadFromAddress(g_pCTerrorPlayer_CanBecomeGhost + view_as<Address>(g_iCanBecomeGhostOffset), NumberType_Int8);
	if( byte == bytes )
	{
		for( int i = 0; i < count; i++ )
		{
			g_hCanBecomeGhost.Push(LoadFromAddress(g_pCTerrorPlayer_CanBecomeGhost + view_as<Address>(g_iCanBecomeGhostOffset), NumberType_Int8));
			StoreToAddress(g_pCTerrorPlayer_CanBecomeGhost + view_as<Address>(g_iCanBecomeGhostOffset + i), 0x90, NumberType_Int8, true);
		}
	}
	else if( byte != 0x90 )
	{
		LogError("CTerrorPlayer::CanBecomeGhost patch: byte mis-match. %X", LoadFromAddress(g_pCTerrorPlayer_CanBecomeGhost + view_as<Address>(g_iCanBecomeGhostOffset), NumberType_Int8));
	}
	// ====================



	if( g_bLeft4Dead2 )
	{
		g_iOff_AddonEclipse1 = hGameData.GetOffset("AddonEclipse1");
		ValidateOffset(g_iOff_AddonEclipse1, "AddonEclipse1");
		g_iOff_AddonEclipse2 = hGameData.GetOffset("AddonEclipse2");
		ValidateOffset(g_iOff_AddonEclipse2, "AddonEclipse2");

		g_iOff_m_iszScriptId = hGameData.GetOffset("m_iszScriptId");
		ValidateOffset(g_iOff_m_iszScriptId, "m_iszScriptId");

		g_iOff_m_flBecomeGhostAt = hGameData.GetOffset("CTerrorPlayer::m_flBecomeGhostAt");
		ValidateOffset(g_iOff_m_flBecomeGhostAt, "CTerrorPlayer::m_flBecomeGhostAt");

		g_iOff_OnBeginRoundSetupTime = hGameData.GetOffset("OnBeginRoundSetupTime");
		ValidateOffset(g_iOff_OnBeginRoundSetupTime, "OnBeginRoundSetupTime");

		g_iOff_m_iWitchCount = hGameData.GetOffset("m_iWitchCount");
		ValidateOffset(g_iOff_m_iWitchCount, "m_iWitchCount");

		g_iOff_OvertimeGraceTimer = hGameData.GetOffset("OvertimeGraceTimer");
		ValidateOffset(g_iOff_OvertimeGraceTimer, "OvertimeGraceTimer");

		// g_iOff_m_iShovePenalty = hGameData.GetOffset("m_iShovePenalty");
		// ValidateOffset(g_iOff_m_iShovePenalty, "m_iShovePenalty");

		// g_iOff_m_fNextShoveTime = hGameData.GetOffset("m_fNextShoveTime");
		// ValidateOffset(g_iOff_m_fNextShoveTime, "m_fNextShoveTime");

		g_iOff_m_preIncapacitatedHealth = hGameData.GetOffset("m_preIncapacitatedHealth");
		ValidateOffset(g_iOff_m_preIncapacitatedHealth, "m_preIncapacitatedHealth");

		g_iOff_m_preIncapacitatedHealthBuffer = hGameData.GetOffset("m_preIncapacitatedHealthBuffer");
		ValidateOffset(g_iOff_m_preIncapacitatedHealthBuffer, "m_preIncapacitatedHealthBuffer");

		g_iOff_m_maxFlames = hGameData.GetOffset("m_maxFlames");
		ValidateOffset(g_iOff_m_maxFlames, "m_maxFlames");

		// l4d2timers.inc offsets
		L4D2CountdownTimer_Offsets[0] = hGameData.GetOffset("L4D2CountdownTimer_MobSpawnTimer") + view_as<int>(g_pDirector);
		L4D2CountdownTimer_Offsets[1] = hGameData.GetOffset("L4D2CountdownTimer_SmokerSpawnTimer") + view_as<int>(g_pDirector);
		L4D2CountdownTimer_Offsets[2] = hGameData.GetOffset("L4D2CountdownTimer_BoomerSpawnTimer") + view_as<int>(g_pDirector);
		L4D2CountdownTimer_Offsets[3] = hGameData.GetOffset("L4D2CountdownTimer_HunterSpawnTimer") + view_as<int>(g_pDirector);
		L4D2CountdownTimer_Offsets[4] = hGameData.GetOffset("L4D2CountdownTimer_SpitterSpawnTimer") + view_as<int>(g_pDirector);
		L4D2CountdownTimer_Offsets[5] = hGameData.GetOffset("L4D2CountdownTimer_JockeySpawnTimer") + view_as<int>(g_pDirector);
		L4D2CountdownTimer_Offsets[6] = hGameData.GetOffset("L4D2CountdownTimer_ChargerSpawnTimer") + view_as<int>(g_pDirector);
		L4D2CountdownTimer_Offsets[7] = hGameData.GetOffset("L4D2CountdownTimer_VersusStartTimer") + g_pVersusMode;
		L4D2CountdownTimer_Offsets[8] = hGameData.GetOffset("L4D2CountdownTimer_UpdateMarkersTimer") + view_as<int>(g_pDirector);
		L4D2IntervalTimer_Offsets[0] = hGameData.GetOffset("L4D2IntervalTimer_SmokerDeathTimer") + view_as<int>(g_pDirector);
		L4D2IntervalTimer_Offsets[1] = hGameData.GetOffset("L4D2IntervalTimer_BoomerDeathTimer") + view_as<int>(g_pDirector);
		L4D2IntervalTimer_Offsets[2] = hGameData.GetOffset("L4D2IntervalTimer_HunterDeathTimer") + view_as<int>(g_pDirector);
		L4D2IntervalTimer_Offsets[3] = hGameData.GetOffset("L4D2IntervalTimer_SpitterDeathTimer") + view_as<int>(g_pDirector);
		L4D2IntervalTimer_Offsets[4] = hGameData.GetOffset("L4D2IntervalTimer_JockeyDeathTimer") + view_as<int>(g_pDirector);
		L4D2IntervalTimer_Offsets[5] = hGameData.GetOffset("L4D2IntervalTimer_ChargerDeathTimer") + view_as<int>(g_pDirector);

		// l4d2weapons.inc offsets
		L4D2BoolMeleeWeapon_Offsets[0] = hGameData.GetOffset("L4D2BoolMeleeWeapon_Decapitates");
		L4D2IntMeleeWeapon_Offsets[0] = hGameData.GetOffset("L4D2IntMeleeWeapon_DamageFlags");
		L4D2IntMeleeWeapon_Offsets[1] = hGameData.GetOffset("L4D2IntMeleeWeapon_RumbleEffect");
		L4D2FloatMeleeWeapon_Offsets[0] = hGameData.GetOffset("L4D2FloatMeleeWeapon_Damage");
		L4D2FloatMeleeWeapon_Offsets[1] = hGameData.GetOffset("L4D2FloatMeleeWeapon_RefireDelay");
		L4D2FloatMeleeWeapon_Offsets[2] = hGameData.GetOffset("L4D2FloatMeleeWeapon_WeaponIdleTime");
	} else {
		g_iOff_VersusStartTimer = hGameData.GetOffset("VersusStartTimer");
		ValidateOffset(g_iOff_VersusStartTimer, "VersusStartTimer");

		#if defined DEBUG
		#if DEBUG
		PrintToServer("VersusStartTimer = %d", g_iOff_VersusStartTimer);
		#endif
		#endif
	}

	// l4d2weapons.inc offsets
	L4D2IntWeapon_Offsets[0] = hGameData.GetOffset("L4D2IntWeapon_Damage");
	L4D2IntWeapon_Offsets[1] = hGameData.GetOffset("L4D2IntWeapon_Bullets");
	L4D2IntWeapon_Offsets[2] = hGameData.GetOffset("L4D2IntWeapon_ClipSize");
	L4D2IntWeapon_Offsets[3] = hGameData.GetOffset("L4D2IntWeapon_Bucket");
	L4D2IntWeapon_Offsets[4] = hGameData.GetOffset("L4D2IntWeapon_Tier");
	L4D2IntWeapon_Offsets[5] = hGameData.GetOffset("L4D2IntWeapon_DefaultSize");
	L4D2FloatWeapon_Offsets[0] = hGameData.GetOffset("L4D2FloatWeapon_MaxPlayerSpeed");
	L4D2FloatWeapon_Offsets[1] = hGameData.GetOffset("L4D2FloatWeapon_SpreadPerShot");
	L4D2FloatWeapon_Offsets[2] = hGameData.GetOffset("L4D2FloatWeapon_MaxSpread");
	L4D2FloatWeapon_Offsets[3] = hGameData.GetOffset("L4D2FloatWeapon_SpreadDecay");
	L4D2FloatWeapon_Offsets[4] = hGameData.GetOffset("L4D2FloatWeapon_MinDuckingSpread");
	L4D2FloatWeapon_Offsets[5] = hGameData.GetOffset("L4D2FloatWeapon_MinStandingSpread");
	L4D2FloatWeapon_Offsets[6] = hGameData.GetOffset("L4D2FloatWeapon_MinInAirSpread");
	L4D2FloatWeapon_Offsets[7] = hGameData.GetOffset("L4D2FloatWeapon_MaxMovementSpread");
	L4D2FloatWeapon_Offsets[8] = hGameData.GetOffset("L4D2FloatWeapon_PenetrationNumLayers");
	L4D2FloatWeapon_Offsets[9] = hGameData.GetOffset("L4D2FloatWeapon_PenetrationPower");
	L4D2FloatWeapon_Offsets[10] = hGameData.GetOffset("L4D2FloatWeapon_PenetrationMaxDist");
	L4D2FloatWeapon_Offsets[11] = hGameData.GetOffset("L4D2FloatWeapon_CharPenetrationMaxDist");
	L4D2FloatWeapon_Offsets[12] = hGameData.GetOffset("L4D2FloatWeapon_Range");
	L4D2FloatWeapon_Offsets[13] = hGameData.GetOffset("L4D2FloatWeapon_RangeModifier");
	L4D2FloatWeapon_Offsets[14] = hGameData.GetOffset("L4D2FloatWeapon_CycleTime");
	L4D2FloatWeapon_Offsets[15] = hGameData.GetOffset("L4D2FloatWeapon_ScatterPitch");
	L4D2FloatWeapon_Offsets[16] = hGameData.GetOffset("L4D2FloatWeapon_ScatterYaw");
	L4D2FloatWeapon_Offsets[17] = hGameData.GetOffset("L4D2FloatWeapon_VerticalPunch");
	L4D2FloatWeapon_Offsets[18] = hGameData.GetOffset("L4D2FloatWeapon_HorizontalPunch");
	L4D2FloatWeapon_Offsets[19] = hGameData.GetOffset("L4D2FloatWeapon_GainRange");
	L4D2FloatWeapon_Offsets[20] = hGameData.GetOffset("L4D2FloatWeapon_ReloadDuration");



	#if defined DEBUG
	#if DEBUG
	PrintToServer("m_iCampaignScores = %d", g_iOff_m_iCampaignScores);
	PrintToServer("m_fTankSpawnFlowPercent = %d", g_iOff_m_fTankSpawnFlowPercent);
	PrintToServer("m_fWitchSpawnFlowPercent = %d", g_iOff_m_fWitchSpawnFlowPercent);
	PrintToServer("m_iTankPassedCount = %d", g_iOff_m_iTankPassedCount);
	PrintToServer("m_bTankThisRound = %d", g_iOff_m_bTankThisRound);
	PrintToServer("m_bWitchThisRound = %d", g_iOff_m_bWitchThisRound);
	PrintToServer("InvulnerabilityTimer = %d", g_iOff_InvulnerabilityTimer);
	PrintToServer("m_iTankTickets = %d", g_iOff_m_iTankTickets);
	PrintToServer("m_flow = %d", g_iOff_m_flow);
	PrintToServer("m_chapter = %d", g_iOff_m_chapter);
	PrintToServer("m_PendingMobCount = %d", g_iOff_m_PendingMobCount);
	PrintToServer("m_fMapMaxFlowDistance = %d", g_iOff_m_fMapMaxFlowDistance);
	PrintToServer("m_rescueCheckTimer = %d", g_iOff_m_rescueCheckTimer);
	PrintToServer("VersusMaxCompletionScore = %d", g_iOff_VersusMaxCompletionScore);
	PrintToServer("m_iTankCount = %d", g_iOff_m_iTankCount);
	PrintToServer("MobSpawnTimer = %d", g_iOff_MobSpawnTimer);

	for( int i = 0; i < sizeof(L4D2CountdownTimer_Offsets); i++ )		PrintToServer("L4D2CountdownTimer_Offsets[%d] == %d", i, L4D2CountdownTimer_Offsets[i]);
	for( int i = 0; i < sizeof(L4D2IntervalTimer_Offsets); i++ )		PrintToServer("L4D2IntervalTimer_Offsets[%d] == %d", i, L4D2IntervalTimer_Offsets[i]);
	for( int i = 0; i < sizeof(L4D2IntWeapon_Offsets); i++ )			PrintToServer("L4D2IntWeapon_Offsets[%d] == %d", i, L4D2IntWeapon_Offsets[i]);
	for( int i = 0; i < sizeof(L4D2FloatWeapon_Offsets); i++ )			PrintToServer("L4D2FloatWeapon_Offsets[%d] == %d", i, L4D2FloatWeapon_Offsets[i]);

	if( g_bLeft4Dead2 )
	{
		for( int i = 0; i < sizeof(L4D2BoolMeleeWeapon_Offsets); i++ )		PrintToServer("L4D2BoolMeleeWeapon_Offsets[%d] == %d", i, L4D2BoolMeleeWeapon_Offsets[i]);
		for( int i = 0; i < sizeof(L4D2IntMeleeWeapon_Offsets); i++ )		PrintToServer("L4D2IntMeleeWeapon_Offsets[%d] == %d", i, L4D2IntMeleeWeapon_Offsets[i]);
		for( int i = 0; i < sizeof(L4D2FloatMeleeWeapon_Offsets); i++ )		PrintToServer("L4D2FloatMeleeWeapon_Offsets[%d] == %d", i, L4D2FloatMeleeWeapon_Offsets[i]);

		PrintToServer("AddonEclipse1 = %d", g_iOff_AddonEclipse1);
		PrintToServer("AddonEclipse2 = %d", g_iOff_AddonEclipse2);
		PrintToServer("m_flBecomeGhostAt = %d", g_iOff_m_flBecomeGhostAt);
		PrintToServer("iszScriptId = %d", g_iOff_m_iszScriptId);
		PrintToServer("OnBeginRoundSetupTime = %d", g_iOff_OnBeginRoundSetupTime);
		PrintToServer("m_iWitchCount = %d", g_iOff_m_iWitchCount);
		PrintToServer("OvertimeGraceTimer = %d", g_iOff_OvertimeGraceTimer);
		// PrintToServer("m_iShovePenalty = %d", g_iOff_m_iShovePenalty);
		// PrintToServer("m_fNextShoveTime = %d", g_iOff_m_fNextShoveTime);
		PrintToServer("m_preIncapacitatedHealth = %d", g_iOff_m_preIncapacitatedHealth);
		PrintToServer("m_preIncapacitatedHealthBuffer = %d", g_iOff_m_preIncapacitatedHealthBuffer);
		PrintToServer("m_maxFlames = %d", g_iOff_m_maxFlames);
		PrintToServer("");
	}
	#endif
	#endif



	// ====================================================================================================
	//									END
	// ====================================================================================================
	g_hGameData = hGameData;

	delete hTempGameData;
}