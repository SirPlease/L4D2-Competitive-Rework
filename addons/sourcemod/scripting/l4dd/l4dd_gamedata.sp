/*
*	Left 4 DHooks Direct
*	Copyright (C) 2026 Silvers
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

		g_iOff_NavAreaID = 140; // Hard-coding offset here, unlikely to ever change
		g_iOff_NavAreaLadderBase = 0x60; // Offset found in "TerrorNavArea::ScriptGetLadders" function
		g_iOff_NavAreaLadderEntity = 0x38; // Offset found by searching memory from base ptr for valid entity
	}
	else
	{
		g_iOff_NavAreaID = 136; // Hard-coding offset here, unlikely to ever change
		g_iOff_NavAreaLadderBase = 0x60; // Offset found in "TerrorNavArea::ScriptGetLadders" function
		g_iOff_NavAreaLadderEntity = 0x34; // Offset found by searching memory from base ptr for valid entity
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

	GameData hGameData = g_hGameData;
	if( hGameData == null ) SetFailState("Failed to retrieve \"%s.txt\" gamedata.", g_bLeft4Dead2 ? GAMEDATA_2 : GAMEDATA_1);

	#if defined DEBUG
	#if DEBUG
	PrintToServer("");
	PrintToServer("Left4DHooks loading gamedata: %s", g_bLeft4Dead2 ? GAMEDATA_2 : GAMEDATA_1);
	PrintToServer("");
	#endif
	#endif



	// ====================================================================================================
	//									SDK CALLS
	// ====================================================================================================
	// INTERNAL
	StartPrepSDKCall(SDKCall_Static);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "GetWeaponInfo") == false )
	{
		ThrowErrorSignature("GetWeaponInfo");
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_GetWeaponInfo = EndPrepSDKCall();
		if( g_hSDK_GetWeaponInfo == null )
			ThrowErrorCreate("GetWeaponInfo");
	}

	StartPrepSDKCall(SDKCall_Static);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorGameRules::GetMissionInfo") == false )
	{
		ThrowErrorSignature("CTerrorGameRules::GetMissionInfo");
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CTerrorGameRules_GetMissionInfo = EndPrepSDKCall();
		if( g_hSDK_CTerrorGameRules_GetMissionInfo == null )
			ThrowErrorCreate("CTerrorGameRules::GetMissionInfo");
	}



	// =========================
	// ANIMATION NATIVES
	// =========================
	if( g_bLeft4Dead2 )
	{
		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CMultiPlayerAnimState::ResetMainActivity") == false )
		{
			ThrowErrorSignature("CMultiPlayerAnimState::ResetMainActivity");
		} else {
			g_hSDK_CMultiPlayerAnimState_ResetMainActivity = EndPrepSDKCall();
			if( g_hSDK_CMultiPlayerAnimState_ResetMainActivity == null )
				ThrowErrorCreate("CMultiPlayerAnimState::ResetMainActivity");
		}
	}



	// =========================
	// SILVERS NATIVES
	// =========================
	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CTerrorPlayer::GetLastKnownArea") == false )
	{
		ThrowErrorSignature("CTerrorPlayer::GetLastKnownArea");
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CTerrorPlayer_GetLastKnownArea = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_GetLastKnownArea == null )
			ThrowErrorCreate("CTerrorPlayer::GetLastKnownArea");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CTerrorPlayer::Deafen") == false )
	{
		ThrowErrorSignature("CTerrorPlayer::Deafen");
	} else {
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		g_hSDK_CTerrorPlayer_Deafen = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_Deafen == null )
			ThrowErrorCreate("CTerrorPlayer::Deafen");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "Music::Play") == false )
	{
		ThrowErrorSignature("Music::Play");
	} else {
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		g_hSDK_Music_Play = EndPrepSDKCall();
		if( g_hSDK_Music_Play == null )
			ThrowErrorCreate("Music::Play");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "Music::StopPlaying") == false )
	{
		ThrowErrorSignature("Music::StopPlaying");
	} else {
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		g_hSDK_Music_StopPlaying = EndPrepSDKCall();
		if( g_hSDK_Music_StopPlaying == null )
			ThrowErrorCreate("Music::StopPlaying");
	}

	StartPrepSDKCall(SDKCall_Static);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CEntityDissolve::Create") == false )
	{
		ThrowErrorSignature("CEntityDissolve::Create");
	} else {
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDK_CEntityDissolve_Create = EndPrepSDKCall();
		if( g_hSDK_CEntityDissolve_Create == null )
			ThrowErrorCreate("CEntityDissolve::Create");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::OnITExpired") == false )
	{
		ThrowErrorSignature("CTerrorPlayer::OnITExpired");
	} else {
		g_hSDK_CTerrorPlayer_OnITExpired = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_OnITExpired == null )
			ThrowErrorCreate("CTerrorPlayer::OnITExpired");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::EstimateFallingDamage") == false )
	{
		ThrowErrorSignature("CTerrorPlayer::EstimateFallingDamage");
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_Plain);
		g_hSDK_CTerrorPlayer_EstimateFallingDamage = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_EstimateFallingDamage == null )
			ThrowErrorCreate("CTerrorPlayer::EstimateFallingDamage");
	}

	StartPrepSDKCall(SDKCall_Entity);
	if( PrepSDKCall_SetFromConf(hGameData, (g_bLeft4Dead2 || g_bLinuxOS) ? SDKConf_Signature : SDKConf_Virtual, "CBaseEntity::WorldSpaceCenter") == false )
	{
		ThrowErrorSignature("CBaseEntity::WorldSpaceCenter");
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Vector, SDKPass_ByRef);
		g_hSDK_CBaseEntity_WorldSpaceCenter = EndPrepSDKCall();
		if( g_hSDK_CBaseEntity_WorldSpaceCenter == null )
			ThrowErrorCreate("CBaseEntity::WorldSpaceCenter");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "IPhysicsObject::GetMass") == false )
	{
		ThrowErrorSignature("IPhysicsObject::GetMass");
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_Plain);
		g_hSDK_IPhysicsObject_GetMass = EndPrepSDKCall();
		if( g_hSDK_IPhysicsObject_GetMass == null )
			ThrowErrorCreate("IPhysicsObject::GetMass");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "IPhysicsObject::SetMass") == false )
	{
		ThrowErrorSignature("IPhysicsObject::SetMass");
	} else {
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_Plain);
		g_hSDK_IPhysicsObject_SetMass = EndPrepSDKCall();
		if( g_hSDK_IPhysicsObject_SetMass == null )
			ThrowErrorCreate("IPhysicsObject::SetMass");
	}

	StartPrepSDKCall(SDKCall_Entity);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CBaseEntity::ApplyLocalAngularVelocityImpulse") == false )
	{
		ThrowErrorSignature("CBaseEntity::ApplyLocalAngularVelocityImpulse");
	} else {
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		g_hSDK_CBaseEntity_ApplyLocalAngularVelocityImpulse = EndPrepSDKCall();
		if( g_hSDK_CBaseEntity_ApplyLocalAngularVelocityImpulse == null )
			ThrowErrorCreate("CBaseEntity::ApplyLocalAngularVelocityImpulse");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "ZombieManager::GetRandomPZSpawnPosition") == false )
	{
		ThrowErrorSignature("ZombieManager::GetRandomPZSpawnPosition");
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWWORLD);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK);
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_ZombieManager_GetRandomPZSpawnPosition = EndPrepSDKCall();
		if( g_hSDK_ZombieManager_GetRandomPZSpawnPosition == null )
			ThrowErrorCreate("ZombieManager::GetRandomPZSpawnPosition");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CNavMesh::GetNearestNavArea") == false )
	{
		ThrowErrorSignature("CNavMesh::GetNearestNavArea");
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
			ThrowErrorCreate("CNavMesh::GetNearestNavArea");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "TerrorNavArea::FindRandomSpot") == false )
	{
		ThrowErrorSignature("TerrorNavArea::FindRandomSpot");
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Vector, SDKPass_ByValue);
		g_hSDK_TerrorNavArea_FindRandomSpot = EndPrepSDKCall();
		if( g_hSDK_TerrorNavArea_FindRandomSpot == null )
			ThrowErrorCreate("TerrorNavArea::FindRandomSpot");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::WarpToValidPositionIfStuck") == false )
	{
		ThrowErrorSignature("CTerrorPlayer::WarpToValidPositionIfStuck");
	} else {
		g_hSDK_CTerrorPlayer_WarpToValidPositionIfStuck = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_WarpToValidPositionIfStuck == null )
			ThrowErrorCreate("CTerrorPlayer::WarpToValidPositionIfStuck");
	}

	if( g_bLeft4Dead2 )
	{
		StartPrepSDKCall(SDKCall_Player);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::GetSpecialInfectedDominatingMe") == false )
		{
			ThrowErrorSignature("CTerrorPlayer::GetSpecialInfectedDominatingMe");
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
			g_hSDK_CTerrorPlayer_GetSpecialInfectedDominatingMe = EndPrepSDKCall();
			if( g_hSDK_CTerrorPlayer_GetSpecialInfectedDominatingMe == null )
				ThrowErrorCreate("CTerrorPlayer::GetSpecialInfectedDominatingMe");
		}

		StartPrepSDKCall(SDKCall_Static);
		if( !PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "IsVisibleToPlayer") )
		{
			ThrowErrorSignature("IsVisibleToPlayer");
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
					ThrowErrorCreate("IsVisibleToPlayer");
		}
	}

	if( g_bLeft4Dead2 || g_bLinuxOS )
	{
		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "TerrorNavArea::IsPotentiallyVisibleToTeam") == false )
		{
			ThrowErrorSignature("TerrorNavArea::IsPotentiallyVisibleToTeam");
		} else {
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
			g_hSDK_TerrorNavArea_IsPotentiallyVisibleToTeam = EndPrepSDKCall();
			if( g_hSDK_TerrorNavArea_IsPotentiallyVisibleToTeam == null )
				ThrowErrorCreate("TerrorNavArea::IsPotentiallyVisibleToTeam");
		}
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "TerrorNavArea::IsPotentiallyVisible") == false )
	{
		ThrowErrorSignature("TerrorNavArea::IsPotentiallyVisible");
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_TerrorNavArea_IsPotentiallyVisible = EndPrepSDKCall();
		if( g_hSDK_TerrorNavArea_IsPotentiallyVisible == null )
			ThrowErrorCreate("TerrorNavArea::IsPotentiallyVisible");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "TerrorNavArea::IsCompletelyVisibleToTeam") == false )
	{
		ThrowErrorSignature("TerrorNavArea::IsCompletelyVisibleToTeam");
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_TerrorNavArea_IsCompletelyVisibleToTeam = EndPrepSDKCall();
		if( g_hSDK_TerrorNavArea_IsCompletelyVisibleToTeam == null )
			ThrowErrorCreate("TerrorNavArea::IsCompletelyVisibleToTeam");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "TerrorNavArea::IsCompletelyVisible") == false )
	{
		ThrowErrorSignature("TerrorNavArea::IsCompletelyVisible");
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_TerrorNavArea_IsCompletelyVisible = EndPrepSDKCall();
		if( g_hSDK_TerrorNavArea_IsCompletelyVisible == null )
			ThrowErrorCreate("TerrorNavArea::IsCompletelyVisible");
	}

	int offset;

	offset = GameConfGetOffset(hGameData, "IVEngineServer::GetClusterForOrigin");
	if( offset == -1 )
	{
		ThrowErrorSignature("IVEngineServer::GetClusterForOrigin");
	} else {
		StartPrepSDKCall(SDKCall_Raw);
		PrepSDKCall_SetVirtual(offset);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_IVEngineServer_GetClusterForOrigin = EndPrepSDKCall();
		if( g_hSDK_IVEngineServer_GetClusterForOrigin == null )
			ThrowErrorCreate("IVEngineServer::GetClusterForOrigin");
	}

	offset = GameConfGetOffset(hGameData, "IVEngineServer::GetPVSForCluster");
	if( offset == -1 )
	{
		ThrowErrorSignature("IVEngineServer::GetPVSForCluster");
	} else {
		StartPrepSDKCall(SDKCall_Raw);
		PrepSDKCall_SetVirtual(offset);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_IVEngineServer_GetPVSForCluster = EndPrepSDKCall();
		if( g_hSDK_IVEngineServer_GetPVSForCluster == null )
			ThrowErrorCreate("IVEngineServer::GetPVSForCluster");
	}

	offset = GameConfGetOffset(hGameData, "IVEngineServer::CheckOriginInPVS");
	if( offset == -1 )
	{
		ThrowErrorSignature("IVEngineServer::CheckOriginInPVS");
	} else {
		StartPrepSDKCall(SDKCall_Raw);
		PrepSDKCall_SetVirtual(offset);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_IVEngineServer_CheckOriginInPVS = EndPrepSDKCall();
		if( g_hSDK_IVEngineServer_CheckOriginInPVS == null )
			ThrowErrorCreate("IVEngineServer::CheckOriginInPVS");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::HasAnySurvivorLeftSafeArea") == false )
	{
		ThrowErrorSignature("CDirector::HasAnySurvivorLeftSafeArea");
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_CDirector_HasAnySurvivorLeftSafeArea = EndPrepSDKCall();
		if( g_hSDK_CDirector_HasAnySurvivorLeftSafeArea == null )
			ThrowErrorCreate("CDirector::HasAnySurvivorLeftSafeArea");
	}

	StartPrepSDKCall(SDKCall_Entity);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CBaseTrigger::IsTouching") == false )
	{
		ThrowErrorSignature("CBaseTrigger::IsTouching");
	} else {
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_CBaseTrigger_IsTouching = EndPrepSDKCall();
		if( g_hSDK_CBaseTrigger_IsTouching == null )
			ThrowErrorCreate("CBaseTrigger::IsTouching");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CGlobalEntityList::FindEntityByClassnameNearest") == false )
	{
		ThrowErrorSignature("CGlobalEntityList::FindEntityByClassnameNearest");
	} else {
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDK_CGlobalEntityList_FindEntityByClassnameNearest = EndPrepSDKCall();
		if( g_hSDK_CGlobalEntityList_FindEntityByClassnameNearest == null )
			ThrowErrorCreate("CBaseTrigger::IsTouching");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CGlobalEntityList::FindEntityByClassnameWithin") == false )
	{
		ThrowErrorSignature("CGlobalEntityList::FindEntityByClassnameWithin");
	} else {
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWWORLD|VDECODE_FLAG_ALLOWNULL);
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDK_CGlobalEntityList_FindEntityByClassnameWithin = EndPrepSDKCall();
		if( g_hSDK_CGlobalEntityList_FindEntityByClassnameWithin == null )
			ThrowErrorCreate("CBaseTrigger::IsTouching");
	}

	/*
	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::IsAnySurvivorInStartArea") == false )
	{
		ThrowErrorSignature("CDirector::IsAnySurvivorInStartArea");
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_CDirector_IsAnySurvivorInStartArea = EndPrepSDKCall();
		if( g_hSDK_CDirector_IsAnySurvivorInStartArea == null )
			ThrowErrorCreate("CDirector::IsAnySurvivorInStartArea");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::IsAnySurvivorInExitCheckpoint") == false )
	{
		ThrowErrorSignature("CDirector::IsAnySurvivorInExitCheckpoint");
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_CDirector_IsAnySurvivorInExitCheckpoint = EndPrepSDKCall();
		if( g_hSDK_CDirector_IsAnySurvivorInExitCheckpoint == null )
			ThrowErrorCreate("CDirector::IsAnySurvivorInExitCheckpoint");
	}
	*/

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, g_bLeft4Dead2 ? SDKConf_Signature : SDKConf_Address, "CDirector::AreAllSurvivorsInFinaleArea") == false )
	{
		ThrowErrorSignature("CDirector::AreAllSurvivorsInFinaleArea");
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_CDirector_AreAllSurvivorsInFinaleArea = EndPrepSDKCall();
		if( g_hSDK_CDirector_AreAllSurvivorsInFinaleArea == null )
			ThrowErrorCreate("CDirector::AreAllSurvivorsInFinaleArea");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "TerrorNavMesh::GetInitialCheckpoint") == false )
	{
		ThrowErrorSignature("TerrorNavMesh::GetInitialCheckpoint");
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_TerrorNavMesh_GetInitialCheckpoint = EndPrepSDKCall();
		if( g_hSDK_TerrorNavMesh_GetInitialCheckpoint == null )
			ThrowErrorCreate("TerrorNavMesh::GetInitialCheckpoint");
	}

	/*
	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "TerrorNavMesh::GetLastCheckpoint") == false )
	{
		ThrowErrorSignature("TerrorNavMesh::GetLastCheckpoint");
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_TerrorNavMesh_GetLastCheckpoint = EndPrepSDKCall();
		if( g_hSDK_TerrorNavMesh_GetLastCheckpoint == null )
			ThrowErrorCreate("TerrorNavMesh::GetLastCheckpoint");
	}
	// */

	if( g_bLeft4Dead2 )
	{
		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "TerrorNavMesh::IsInInitialCheckpoint_NoLandmark") == false )
		{
			ThrowErrorSignature("TerrorNavMesh::IsInInitialCheckpoint_NoLandmark");
		} else {
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
			g_hSDK_TerrorNavMesh_IsInInitialCheckpoint_NoLandmark = EndPrepSDKCall();
			if( g_hSDK_TerrorNavMesh_IsInInitialCheckpoint_NoLandmark == null )
				ThrowErrorCreate("TerrorNavMesh::IsInInitialCheckpoint_NoLandmark");
		}

		/*
		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "TerrorNavMesh::IsInExitCheckpoint_NoLandmark") == false )
		{
			ThrowErrorSignature("TerrorNavMesh::IsInExitCheckpoint_NoLandmark");
		} else {
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
			g_hSDK_TerrorNavMesh_IsInExitCheckpoint_NoLandmark = EndPrepSDKCall();
			if( g_hSDK_TerrorNavMesh_IsInExitCheckpoint_NoLandmark == null )
				ThrowErrorCreate("TerrorNavMesh::IsInExitCheckpoint_NoLandmark");
		}
		// */
	}

	StartPrepSDKCall(SDKCall_Static);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "Checkpoint::ContainsArea") == false )
	{
		ThrowErrorSignature("Checkpoint::ContainsArea");
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_Checkpoint_ContainsArea = EndPrepSDKCall();
		if( g_hSDK_Checkpoint_ContainsArea == null )
			ThrowErrorCreate("Checkpoint::ContainsArea");
	}

	StartPrepSDKCall(SDKCall_Static);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorGameRules::HasPlayerControlledZombies") == false )
	{
		ThrowErrorSignature("CTerrorGameRules::HasPlayerControlledZombies");
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_CTerrorGameRules_HasPlayerControlledZombies = EndPrepSDKCall();
		if( g_hSDK_CTerrorGameRules_HasPlayerControlledZombies == null )
			ThrowErrorCreate("CTerrorGameRules::HasPlayerControlledZombies");
	}

	if( g_bLeft4Dead2 )
	{
		StartPrepSDKCall(SDKCall_GameRules);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorGameRules::GetSurvivorSet") == false )
		{
			ThrowErrorSignature("CTerrorGameRules::GetSurvivorSet");
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_CTerrorGameRules_GetSurvivorSet = EndPrepSDKCall();
			if( g_hSDK_CTerrorGameRules_GetSurvivorSet == null )
				ThrowErrorCreate("CTerrorGameRules::GetSurvivorSet");
		}
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "Script_ForceVersusStart") == false )
	{
		ThrowErrorSignature("Script_ForceVersusStart");
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
			ThrowErrorCreate("Script_ForceVersusStart");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "Script_ForceSurvivalStart") == false )
	{
		ThrowErrorSignature("Script_ForceSurvivalStart");
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_ForceSurvivalStart = EndPrepSDKCall();
		if( g_hSDK_ForceSurvivalStart == null )
			ThrowErrorCreate("Script_ForceSurvivalStart");
	}

	StartPrepSDKCall(SDKCall_Entity);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CBaseGrenade::Detonate") == false )
	{
		ThrowErrorSignature("CBaseGrenade::Detonate");
	} else {
		g_hSDK_CBaseGrenade_Detonate = EndPrepSDKCall();
		if( g_hSDK_CBaseGrenade_Detonate == null )
			ThrowErrorCreate("CBaseGrenade::Detonate");
	}

	/*
	StartPrepSDKCall(SDKCall_Static);
	// StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CInferno::StartBurning") == false )
	{
		ThrowErrorSignature("CInferno::StartBurning");
	} else {
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CInferno_StartBurning = EndPrepSDKCall();
		if( g_hSDK_CInferno_StartBurning == null )
			ThrowErrorCreate("CInferno::StartBurning");
	}
	// */

	StartPrepSDKCall(SDKCall_Static);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CPipeBombProjectile::Create") == false )
	{
		ThrowErrorSignature("CPipeBombProjectile::Create");
	} else {
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWWORLD|VDECODE_FLAG_ALLOWNULL);
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDK_CPipeBombProjectile_Create = EndPrepSDKCall();
		if( g_hSDK_CPipeBombProjectile_Create == null )
			ThrowErrorCreate("CPipeBombProjectile::Create");
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
		if( hFile == null )
		{
			SetFailState("Failed to create file: \"%s\". Check your folder permissions allow writing.", sPath);
		}

		char sAddress[512];
		char sHexAddr[32];

		// Dynamically generated projectile Create detours:
		hFile.WriteLine("\"Games\"");
		hFile.WriteLine("{");
		hFile.WriteLine("	\"#default\"");
		hFile.WriteLine("	{");
		hFile.WriteLine("		\"Functions\"");
		hFile.WriteLine("		{");
		hFile.WriteLine("			\"L4DD::CMolotovProjectile::Create\"");
		hFile.WriteLine("			{");
		hFile.WriteLine("				\"signature\"		\"FindAddress_0\"");
		hFile.WriteLine("				\"callconv\"		\"cdecl\"");
		hFile.WriteLine("				\"return\"		\"cbaseentity\"");
		hFile.WriteLine("				\"arguments\"");
		hFile.WriteLine("				{");
		hFile.WriteLine("					\"origin\"");
		hFile.WriteLine("					{");
		hFile.WriteLine("						\"type\"		\"vectorptr\"");
		hFile.WriteLine("					}");
		hFile.WriteLine("					\"angles\"");
		hFile.WriteLine("					{");
		hFile.WriteLine("						\"type\"		\"vectorptr\"");
		hFile.WriteLine("					}");
		hFile.WriteLine("					\"velocity\"");
		hFile.WriteLine("					{");
		hFile.WriteLine("						\"type\"		\"vectorptr\"");
		hFile.WriteLine("					}");
		hFile.WriteLine("					\"rotation\"");
		hFile.WriteLine("					{");
		hFile.WriteLine("						\"type\"		\"vectorptr\"");
		hFile.WriteLine("					}");
		hFile.WriteLine("					\"owner\"");
		hFile.WriteLine("					{");
		hFile.WriteLine("						\"type\"		\"cbaseentity\"");
		hFile.WriteLine("					}");
		hFile.WriteLine("					\"duration\"");
		hFile.WriteLine("					{");
		hFile.WriteLine("						\"type\"		\"float\"");
		hFile.WriteLine("					}");
		hFile.WriteLine("				}");
		hFile.WriteLine("			}");
		if( g_bLeft4Dead2 )
		{
		hFile.WriteLine("			\"L4DD::CVomitJarProjectile::Create\"");
		hFile.WriteLine("			{");
		hFile.WriteLine("				\"signature\"		\"FindAddress_1\"");
		hFile.WriteLine("				\"callconv\"		\"cdecl\"");
		hFile.WriteLine("				\"return\"		\"cbaseentity\"");
		hFile.WriteLine("				\"arguments\"");
		hFile.WriteLine("				{");
		hFile.WriteLine("					\"origin\"");
		hFile.WriteLine("					{");
		hFile.WriteLine("						\"type\"		\"vectorptr\"");
		hFile.WriteLine("					}");
		hFile.WriteLine("					\"angles\"");
		hFile.WriteLine("					{");
		hFile.WriteLine("						\"type\"		\"vectorptr\"");
		hFile.WriteLine("					}");
		hFile.WriteLine("					\"velocity\"");
		hFile.WriteLine("					{");
		hFile.WriteLine("						\"type\"		\"vectorptr\"");
		hFile.WriteLine("					}");
		hFile.WriteLine("					\"rotation\"");
		hFile.WriteLine("					{");
		hFile.WriteLine("						\"type\"		\"vectorptr\"");
		hFile.WriteLine("					}");
		hFile.WriteLine("					\"owner\"");
		hFile.WriteLine("					{");
		hFile.WriteLine("						\"type\"		\"cbaseentity\"");
		hFile.WriteLine("					}");
		hFile.WriteLine("					\"duration\"");
		hFile.WriteLine("					{");
		hFile.WriteLine("						\"type\"		\"float\"");
		hFile.WriteLine("					}");
		hFile.WriteLine("				}");
		hFile.WriteLine("			}");
		hFile.WriteLine("			\"L4DD::CGrenadeLauncher_Projectile::Create\"");
		hFile.WriteLine("			{");
		hFile.WriteLine("				\"signature\"		\"FindAddress_2\"");
		hFile.WriteLine("				\"callconv\"		\"cdecl\"");
		hFile.WriteLine("				\"return\"		\"cbaseentity\"");
		hFile.WriteLine("				\"arguments\"");
		hFile.WriteLine("				{");
		hFile.WriteLine("					\"origin\"");
		hFile.WriteLine("					{");
		hFile.WriteLine("						\"type\"		\"vectorptr\"");
		hFile.WriteLine("					}");
		hFile.WriteLine("					\"angles\"");
		hFile.WriteLine("					{");
		hFile.WriteLine("						\"type\"		\"vectorptr\"");
		hFile.WriteLine("					}");
		hFile.WriteLine("					\"velocity\"");
		hFile.WriteLine("					{");
		hFile.WriteLine("						\"type\"		\"vectorptr\"");
		hFile.WriteLine("					}");
		hFile.WriteLine("					\"rotation\"");
		hFile.WriteLine("					{");
		hFile.WriteLine("						\"type\"		\"vectorptr\"");
		hFile.WriteLine("					}");
		hFile.WriteLine("					\"owner\"");
		hFile.WriteLine("					{");
		hFile.WriteLine("						\"type\"		\"cbaseentity\"");
		hFile.WriteLine("					}");
		hFile.WriteLine("					\"bIncendiary\"");
		hFile.WriteLine("					{");
		hFile.WriteLine("						\"type\"		\"int\"");
		hFile.WriteLine("					}");
		hFile.WriteLine("				}");
		hFile.WriteLine("			}");
		}
		hFile.WriteLine("		}");

		// Dynamically generated addresses
		hFile.WriteLine("");
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

		// Dynamically generated signatures
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
				hFile.WriteLine("				\"library\"	\"server\""); // Server is default.
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
		ThrowErrorSignature("CMolotovProjectile::Create");
	} else {
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWWORLD|VDECODE_FLAG_ALLOWNULL);
		if( !g_bLeft4Dead2 )
			PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDK_CMolotovProjectile_Create = EndPrepSDKCall();
		if( g_hSDK_CMolotovProjectile_Create == null )
			ThrowErrorCreate("CMolotovProjectile::Create");
	}

	if( g_bLeft4Dead2 )
	{
		StartPrepSDKCall(SDKCall_Static);
		if( PrepSDKCall_SetFromConf(g_bLinuxOS ? hGameData : hTempGameData, SDKConf_Signature, g_bLinuxOS ? "CVomitJarProjectile::Create" : "FindAddress_1") == false )
		{
			ThrowErrorSignature("CVomitJarProjectile::Create");
		} else {
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWWORLD|VDECODE_FLAG_ALLOWNULL);
			PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
			g_hSDK_CVomitJarProjectile_Create = EndPrepSDKCall();
			if( g_hSDK_CVomitJarProjectile_Create == null )
				ThrowErrorCreate("CVomitJarProjectile::Create");
		}

		StartPrepSDKCall(SDKCall_Static);
		if( PrepSDKCall_SetFromConf(g_bLinuxOS ? hGameData : hTempGameData, SDKConf_Signature, g_bLinuxOS ? "CGrenadeLauncher_Projectile::Create" : "FindAddress_2") == false )
		{
			ThrowErrorSignature("CGrenadeLauncher_Projectile::Create");
		} else {
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWWORLD|VDECODE_FLAG_ALLOWNULL);
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
			g_hSDK_CGrenadeLauncher_Projectile_Create = EndPrepSDKCall();
			if( g_hSDK_CGrenadeLauncher_Projectile_Create == null )
				ThrowErrorCreate("CGrenadeLauncher_Projectile::Create");
		}

		StartPrepSDKCall(SDKCall_GameRules);
		if( PrepSDKCall_SetFromConf(g_bLinuxOS ? hGameData : hTempGameData, SDKConf_Signature, g_bLinuxOS ? "CTerrorGameRules::IsRealismMode" : "FindAddress_3") == false )
		{
			ThrowErrorSignature("CTerrorGameRules::IsRealismMode");
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
			g_hSDK_CTerrorGameRules_IsRealismMode = EndPrepSDKCall();
			if( g_hSDK_CTerrorGameRules_IsRealismMode == null )
				ThrowErrorCreate("CTerrorGameRules::IsRealismMode");
		}

		// Normal GameData SDKCalls
		StartPrepSDKCall(SDKCall_Static);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CSpitterProjectile::Create") == false )
		{
			ThrowErrorSignature("CSpitterProjectile::Create");
		} else {
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWWORLD);
			PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
			g_hSDK_CSpitterProjectile_Create = EndPrepSDKCall();
			if( g_hSDK_CSpitterProjectile_Create == null )
				ThrowErrorCreate("CSpitterProjectile::Create");
		}

		StartPrepSDKCall(SDKCall_GameRules);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorGameRules::HasConfigurableDifficultySetting") == false )
		{
			ThrowErrorSignature("CTerrorGameRules::HasConfigurableDifficultySetting");
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_CTerrorGameRules_HasConfigurableDifficultySetting = EndPrepSDKCall();
			if( g_hSDK_CTerrorGameRules_HasConfigurableDifficultySetting == null )
				ThrowErrorCreate("CTerrorGameRules::HasConfigurableDifficultySetting");
		}

		StartPrepSDKCall(SDKCall_Static);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "NavAreaBuildPath_ShortestPathCost") == false )
		{
			ThrowErrorSignature("NavAreaBuildPath_ShortestPathCost");
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
				ThrowErrorCreate("NavAreaBuildPath_ShortestPathCost");
		}

		StartPrepSDKCall(SDKCall_Player);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::OnAdrenalineUsed") == false )
		{
			ThrowErrorSignature("CTerrorPlayer::OnAdrenalineUsed");
		} else {
			PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
			g_hSDK_CTerrorPlayer_OnAdrenalineUsed = EndPrepSDKCall();
			if( g_hSDK_CTerrorPlayer_OnAdrenalineUsed == null )
				ThrowErrorCreate("CTerrorPlayer::OnAdrenalineUsed");
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
			ThrowErrorSignature("CDirector::ForceNextStage::Address");
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_CDirector_ForceNextStage = EndPrepSDKCall();
			if( g_hSDK_CDirector_ForceNextStage == null )
				ThrowErrorCreate("CDirector::ForceNextStage::Address");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "Script_ForceScavengeStart") == false )
		{
			ThrowErrorSignature("Script_ForceScavengeStart");
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
			g_hSDK_ForceScavengeStart = EndPrepSDKCall();
			if( g_hSDK_ForceScavengeStart == null )
				ThrowErrorCreate("Script_ForceScavengeStart");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::IsTankInPlay") == false )
		{
			ThrowErrorSignature("CDirector::IsTankInPlay");
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
			g_hSDK_CDirector_IsTankInPlay = EndPrepSDKCall();
			if( g_hSDK_CDirector_IsTankInPlay == null )
				ThrowErrorCreate("CDirector::IsTankInPlay");
		}

		StartPrepSDKCall(SDKCall_Player);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::OnRevivedByDefibrillator") == false )
		{
			ThrowErrorSignature("CTerrorPlayer::OnRevivedByDefibrillator");
		}
		else
		{
			PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
			PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
			g_hSDK_CTDefibPlayer = EndPrepSDKCall();
		}

		if( g_hSDK_CTDefibPlayer == null )
		{
			ThrowErrorCreate("CTerrorPlayer::OnRevivedByDefibrillator");
		}

		StartPrepSDKCall(SDKCall_Player);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "SurvivorBot::IsReachable") == false )
		{
			ThrowErrorSignature("SurvivorBot::IsReachable");
		} else {
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
			g_hSDK_SurvivorBot_IsReachable = EndPrepSDKCall();
			if( g_hSDK_SurvivorBot_IsReachable == null )
				ThrowErrorCreate("SurvivorBot::IsReachable");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::GetFurthestSurvivorFlow") == false )
		{
			ThrowErrorSignature("CDirector::GetFurthestSurvivorFlow");
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_Plain);
			g_hSDK_CDirector_GetFurthestSurvivorFlow = EndPrepSDKCall();
			if( g_hSDK_CDirector_GetFurthestSurvivorFlow == null )
				ThrowErrorCreate("CDirector::GetFurthestSurvivorFlow");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::GetScriptValueInt") == false )
		{
			ThrowErrorSignature("CDirector::GetScriptValueInt");
		} else {
			PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_CDirector_GetScriptValueInt = EndPrepSDKCall();
			if( g_hSDK_CDirector_GetScriptValueInt == null )
					ThrowErrorCreate("CDirector::GetScriptValueInt");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::GetScriptValueFloat") == false )
		{
			ThrowErrorSignature("CDirector::GetScriptValueFloat");
		} else {
			PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
			PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
			PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_Plain);
			g_hSDK_CDirector_GetScriptValueFloat = EndPrepSDKCall();
			if( g_hSDK_CDirector_GetScriptValueFloat == null )
					ThrowErrorCreate("CDirector::GetScriptValueFloat");
		}

		// Crashes when the key has not been set
		/*
		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::GetScriptValueString") == false )
		{
			ThrowErrorSignature("CDirector::GetScriptValueString");
		} else {
			PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
			PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
			PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_SetReturnInfo(SDKType_String, SDKPass_Pointer);
			// PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_CDirector_GetScriptValueString = EndPrepSDKCall();
			if( g_hSDK_CDirector_GetScriptValueString == null )
					ThrowErrorCreate("CDirector::GetScriptValueString");
		}
		*/
	}

	StartPrepSDKCall(SDKCall_Static);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "NavAreaTravelDistance") == false )
	{
		ThrowErrorSignature("NavAreaTravelDistance");
	} else {
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		if( g_bLeft4Dead2 )
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_Plain);
		g_hSDK_NavAreaTravelDistance = EndPrepSDKCall();
		if( g_hSDK_NavAreaTravelDistance == null )
			ThrowErrorCreate("NavAreaTravelDistance");
	}



	// =========================
	// MAIN - left4downtown.inc
	// =========================
	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::RestartScenarioFromVote") == false )
	{
		ThrowErrorSignature("CDirector::RestartScenarioFromVote");
	} else {
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CDirector_RestartScenarioFromVote = EndPrepSDKCall();
		if( g_hSDK_CDirector_RestartScenarioFromVote == null )
			ThrowErrorCreate("CDirector::RestartScenarioFromVote");
	}

	StartPrepSDKCall(SDKCall_GameRules);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorGameRules::SetCampaignScores") == false )
	{
		ThrowErrorSignature("CTerrorGameRules::SetCampaignScores");
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CTerrorGameRules_SetCampaignScores = EndPrepSDKCall();
		if( g_hSDK_CTerrorGameRules_SetCampaignScores == null )
			ThrowErrorCreate("CTerrorGameRules::SetCampaignScores");
	}

	StartPrepSDKCall(SDKCall_GameRules);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorGameRules::GetTeamScore") == false )
	{
		ThrowErrorSignature("CTerrorGameRules::GetTeamScore");
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CTerrorGameRules_GetTeamScore = EndPrepSDKCall();
		if( g_hSDK_CTerrorGameRules_GetTeamScore == null )
			ThrowErrorCreate("CTerrorGameRules::GetTeamScore");
	}

	if( g_bLeft4Dead2 )
	{
		StartPrepSDKCall(SDKCall_Raw);
	} else {
		StartPrepSDKCall(SDKCall_Static);
	}
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::IsFirstMapInScenario") == false )
	{
		ThrowErrorSignature("CDirector::IsFirstMapInScenario");
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
			ThrowErrorCreate("IsFirstMapInScenario");
	}

	StartPrepSDKCall(SDKCall_GameRules);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorGameRules::IsMissionFinalMap") == false )
	{
		ThrowErrorSignature("CTerrorGameRules::IsMissionFinalMap");
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_CTerrorGameRules_IsMissionFinalMap = EndPrepSDKCall();
		if( g_hSDK_CTerrorGameRules_IsMissionFinalMap == null )
			ThrowErrorCreate("CTerrorGameRules::IsMissionFinalMap");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "KeyValues::GetString") == false )
	{
		ThrowErrorSignature("KeyValues::GetString");
	} else {
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		PrepSDKCall_SetReturnInfo(SDKType_String, SDKPass_Pointer);
		g_hSDK_KeyValues_GetString = EndPrepSDKCall();
		if( g_hSDK_KeyValues_GetString == null )
			ThrowErrorCreate("KeyValues::GetString");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CAmmoDef::MaxCarry") == false )
	{
		ThrowErrorSignature("CAmmoDef::MaxCarry");
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_AmmoDef_MaxCarry = EndPrepSDKCall();
		if( g_hSDK_AmmoDef_MaxCarry == null )
			ThrowErrorCreate("CAmmoDef::MaxCarry");
	}

	if( g_bLeft4Dead2 )
	{
		StartPrepSDKCall(SDKCall_GameRules);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorGameRules::GetNumChaptersForMissionAndMode") == false )
		{
			ThrowErrorSignature("CTerrorGameRules::GetNumChaptersForMissionAndMode");
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_CTerrorGameRules_GetNumChaptersForMissionAndMode = EndPrepSDKCall();
			if( g_hSDK_CTerrorGameRules_GetNumChaptersForMissionAndMode == null )
				ThrowErrorCreate("CTerrorGameRules::GetNumChaptersForMissionAndMode");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::GetGameModeBase") == false )
		{
			ThrowErrorSignature("CDirector::GetGameModeBase");
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_String, SDKPass_Pointer);
			g_hSDK_CDirector_GetGameModeBase = EndPrepSDKCall();
			if( g_hSDK_CDirector_GetGameModeBase == null )
				ThrowErrorCreate("CDirector::GetGameModeBase");
		}

		StartPrepSDKCall(SDKCall_GameRules);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorGameRules::IsGenericCooperativeMode") == false )
		{
			ThrowErrorSignature("CTerrorGameRules::IsGenericCooperativeMode");
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_CTerrorGameRules_IsGenericCooperativeMode = EndPrepSDKCall();
			if( g_hSDK_CTerrorGameRules_IsGenericCooperativeMode == null )
				ThrowErrorCreate("CTerrorGameRules::IsGenericCooperativeMode");
		}
	}

	StartPrepSDKCall(SDKCall_GameRules);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CGameRulesProxy::NotifyNetworkStateChanged") == false )
	{
		ThrowErrorSignature("CGameRulesProxy::NotifyNetworkStateChanged");
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CGameRulesProxy_NotifyNetworkStateChanged = EndPrepSDKCall();
		if( g_hSDK_CGameRulesProxy_NotifyNetworkStateChanged == null )
			ThrowErrorCreate("CGameRulesProxy::NotifyNetworkStateChanged");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::OnStaggered") == false )
	{
		ThrowErrorSignature("CTerrorPlayer::StaggerPlayer");
	} else {
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CTerrorPlayer_OnStaggered = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_OnStaggered == null )
			ThrowErrorCreate("CTerrorPlayer::OnStaggered");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirectorScriptedEventManager::SendInRescueVehicle") == false )
	{
		ThrowErrorSignature("CDirectorScriptedEventManager::SendInRescueVehicle");
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_CDirectorScriptedEventManager_SendInRescueVehicle = EndPrepSDKCall();
		if( g_hSDK_CDirectorScriptedEventManager_SendInRescueVehicle == null )
			ThrowErrorCreate("CDirectorScriptedEventManager::SendInRescueVehicle");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "ZombieManager::ReplaceTank") == false )
	{
		ThrowErrorSignature("ZombieManager::ReplaceTank");
	} else {
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_ZombieManager_ReplaceTank = EndPrepSDKCall();
		if( g_hSDK_ZombieManager_ReplaceTank == null )
			ThrowErrorCreate("ZombieManager::ReplaceTank");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "ZombieManager::SpawnTank") == false )
	{
		ThrowErrorSignature("ZombieManager::SpawnTank");
	} else {
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
		PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDK_ZombieManager_SpawnTank = EndPrepSDKCall();
		if( g_hSDK_ZombieManager_SpawnTank == null )
			ThrowErrorCreate("ZombieManager::SpawnTank");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "ZombieManager::SpawnWitch") == false )
	{
		ThrowErrorSignature("ZombieManager::SpawnWitch");
	} else {
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
		PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDK_ZombieManager_SpawnWitch = EndPrepSDKCall();
		if( g_hSDK_ZombieManager_SpawnWitch == null )
			ThrowErrorCreate("ZombieManager::SpawnWitch");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::IsFinaleEscapeInProgress") == false )
	{
		ThrowErrorSignature("CDirector::IsFinaleEscapeInProgress");
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_CDirector_IsFinaleEscapeInProgress = EndPrepSDKCall();
		if( g_hSDK_CDirector_IsFinaleEscapeInProgress == null )
			ThrowErrorCreate("CDirector::IsFinaleEscapeInProgress");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "SurvivorBot::SetHumanSpectator") == false )
	{
		ThrowErrorSignature("SurvivorBot::SetHumanSpectator");
	} else {
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_SurvivorBot_SetHumanSpectator = EndPrepSDKCall();
		if( g_hSDK_SurvivorBot_SetHumanSpectator == null )
			ThrowErrorCreate("SurvivorBot::SetHumanSpectator");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::TakeOverBot") == false )
	{
		ThrowErrorSignature("CTerrorPlayer::TakeOverBot");
	} else {
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_CTerrorPlayer_TakeOverBot = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_TakeOverBot == null )
			ThrowErrorCreate("CTerrorPlayer::TakeOverBot");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::CanBecomeGhost") == false )
	{
		ThrowErrorSignature("CTerrorPlayer::CanBecomeGhost");
	} else {
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_CTerrorPlayer_CanBecomeGhost = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_CanBecomeGhost == null )
			ThrowErrorCreate("CTerrorPlayer::CanBecomeGhost");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::SetBecomeGhostAt") == false )
	{
		ThrowErrorSignature("CTerrorPlayer::SetBecomeGhostAt");
	} else {
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CTerrorPlayer_SetBecomeGhostAt = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_SetBecomeGhostAt == null )
			ThrowErrorCreate("CTerrorPlayer::SetBecomeGhostAt");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::GoAwayFromKeyboard") == false )
	{
		ThrowErrorSignature("CTerrorPlayer::GoAwayFromKeyboard");
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_CTerrorPlayer_GoAwayFromKeyboard = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_GoAwayFromKeyboard == null )
			ThrowErrorCreate("CTerrorPlayer::GoAwayFromKeyboard");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::TryOfferingTankBot") == false )
	{
		ThrowErrorSignature("CDirector::TryOfferingTankBot");
	} else {
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CDirector_TryOfferingTankBot = EndPrepSDKCall();
		if( g_hSDK_CDirector_TryOfferingTankBot == null )
			ThrowErrorCreate("CDirector::TryOfferingTankBot");
	}

	if( g_bLeft4Dead2 )
	{
		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::AddSurvivorBot") == false )
		{
			ThrowErrorSignature("CDirector::AddSurvivorBot");
		} else {
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_CDirector_AddSurvivorBot = EndPrepSDKCall();
			if( g_hSDK_CDirector_AddSurvivorBot == null )
				ThrowErrorCreate("CDirector::AddSurvivorBot");
		}
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CNavMesh::GetNavArea") == false )
	{
		ThrowErrorSignature("CNavMesh::GetNavArea");
	} else {
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CNavMesh_GetNavArea = EndPrepSDKCall();
		if( g_hSDK_CNavMesh_GetNavArea == null )
			ThrowErrorCreate("CNavMesh::GetNavArea");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CNavArea::ConnectTo") == false )
	{
		ThrowErrorSignature("CNavArea::ConnectTo");
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_CNavArea_ConnectTo = EndPrepSDKCall();
		if( g_hSDK_CNavArea_ConnectTo == null )
			ThrowErrorCreate("CNavArea::ConnectTo");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CNavArea::IsConnected") == false )
	{
		ThrowErrorSignature("CNavArea::IsConnected");
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_CNavArea_IsConnected = EndPrepSDKCall();
		if( g_hSDK_CNavArea_IsConnected == null )
			ThrowErrorCreate("CNavArea::IsConnected");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CNavArea::IsBlocked") == false )
	{
		ThrowErrorSignature("CNavArea::IsBlocked");
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_CNavArea_IsBlocked = EndPrepSDKCall();
		if( g_hSDK_CNavArea_IsBlocked == null )
			ThrowErrorCreate("CNavArea::IsBlocked");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CNavArea::GetZ") == false )
	{
		ThrowErrorSignature("CNavArea::GetZ");
	} else {
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_Plain);
		g_hSDK_CNavArea_GetZ = EndPrepSDKCall();
		if( g_hSDK_CNavArea_GetZ == null )
			ThrowErrorCreate("CNavArea::GetZ");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::GetFlowDistance") == false )
	{
		ThrowErrorSignature("CTerrorPlayer::GetFlowDistance");
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_Plain);
		g_hSDK_CTerrorPlayer_GetFlowDistance = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_GetFlowDistance == null )
			ThrowErrorCreate("CTerrorPlayer::GetFlowDistance");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "Intensity::Reset") == false )
	{
		ThrowErrorSignature("Intensity::Reset");
	} else {
		g_hSDK_Intensity_Reset = EndPrepSDKCall();
		if( g_hSDK_Intensity_Reset == null )
			ThrowErrorCreate("Intensity::Reset");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::SetShovePenalty") == false )
	{
		ThrowErrorSignature("CTerrorPlayer::SetShovePenalty");
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CTerrorPlayer_SetShovePenalty = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_SetShovePenalty == null )
			ThrowErrorCreate("CTerrorPlayer::SetShovePenalty");
	}

	/*
	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::SetNextShoveTime") == false )
	{
		ThrowErrorSignature("CTerrorPlayer::SetNextShoveTime");
	} else {
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CTerrorPlayer_SetNextShoveTime = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_SetNextShoveTime == null )
			ThrowErrorCreate("CTerrorPlayer::SetNextShoveTime");
	}
	*/

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::DoAnimationEvent") == false )
	{
		ThrowErrorSignature("CTerrorPlayer::DoAnimationEvent");
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CTerrorPlayer_DoAnimationEvent = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_DoAnimationEvent == null )
			ThrowErrorCreate("CTerrorPlayer::DoAnimationEvent");
	}

	StartPrepSDKCall(SDKCall_GameRules);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorGameRules::RecomputeTeamScores") == false )
	{
		ThrowErrorSignature("CTerrorGameRules::RecomputeTeamScores");
	} else {
		if( g_bLeft4Dead2 )
		{
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		}

		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CTerrorGameRules_RecomputeTeamScores = EndPrepSDKCall();
		if( g_hSDK_CTerrorGameRules_RecomputeTeamScores == null )
			ThrowErrorCreate("CTerrorGameRules::RecomputeTeamScores");
	}



	if( g_bLeft4Dead2 )
	{
		StartPrepSDKCall(SDKCall_Static);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "TheNextBots") == false )
		{
			ThrowErrorSignature("TheNextBots");
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_TheNextBots = EndPrepSDKCall();
			if( g_hSDK_TheNextBots == null )
				ThrowErrorCreate("TheNextBots");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "NextBotManager::RushVictim") == false )
		{
			ThrowErrorSignature("NextBotManager::RushVictim");
		} else {
			PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
			PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
			g_hSDK_RushVictim = EndPrepSDKCall();
			if( g_hSDK_RushVictim == null )
				ThrowErrorCreate("NextBotManager::RushVictim");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "NextBotManager::StartAssault") == false )
		{
			ThrowErrorSignature("NextBotManager::StartAssault");
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_StartAssault = EndPrepSDKCall();
			if( g_hSDK_StartAssault == null )
				ThrowErrorCreate("NextBotManager::StartAssault");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CMeleeWeaponInfoStore::GetMeleeWeaponInfo") == false )
		{
			ThrowErrorSignature("CMeleeWeaponInfoStore::GetMeleeWeaponInfo");
		} else {
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_CMeleeWeaponInfoStore_GetMeleeWeaponInfo = EndPrepSDKCall();
			if( g_hSDK_CMeleeWeaponInfoStore_GetMeleeWeaponInfo == null )
				ThrowErrorCreate("CMeleeWeaponInfoStore::GetMeleeWeaponInfo");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::ResetMobTimer") == false )
		{
			ThrowErrorSignature("CDirector::ResetMobTimer");
		} else {
			g_hSDK_CDirector_ResetMobTimer = EndPrepSDKCall();
			if( g_hSDK_CDirector_ResetMobTimer == null )
				ThrowErrorCreate("CDirector::ResetMobTimer");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::SpawnAllScavengeItems") == false )
		{
			ThrowErrorSignature("CDirector::SpawnAllScavengeItems");
		} else {
			g_hSDK_CDirector_SpawnAllScavengeItems = EndPrepSDKCall();
			if( g_hSDK_CDirector_SpawnAllScavengeItems == null )
				ThrowErrorCreate("CDirector::SpawnAllScavengeItems");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirectorScriptedEventManager::ChangeFinaleStage") == false )
		{
			ThrowErrorSignature("CDirectorScriptedEventManager::ChangeFinaleStage");
		} else {
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_CDirectorScriptedEventManager_ChangeFinaleStage = EndPrepSDKCall();
			if( g_hSDK_CDirectorScriptedEventManager_ChangeFinaleStage == null )
				ThrowErrorCreate("CDirectorScriptedEventManager::ChangeFinaleStage");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "ZombieManager::SpawnSpecial") == false )
		{
			ThrowErrorSignature("ZombieManager::SpawnSpecial");
		} else {
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
			PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
			g_hSDK_ZombieManager_SpawnSpecial = EndPrepSDKCall();
			if( g_hSDK_ZombieManager_SpawnSpecial == null )
				ThrowErrorCreate("ZombieManager::SpawnSpecial");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "ZombieManager::SpawnWitchBride") == false )
		{
			ThrowErrorSignature("ZombieManager::SpawnWitchBride");
		} else {
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
			PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
			g_hSDK_ZombieManager_SpawnWitchBride = EndPrepSDKCall();
			if( g_hSDK_ZombieManager_SpawnWitchBride == null )
				ThrowErrorCreate("ZombieManager::SpawnWitchBride");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::AreWanderersAllowed") == false )
		{
			ThrowErrorSignature("CDirector::AreWanderersAllowed");
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
			g_hSDK_CDirector_AreWanderersAllowed = EndPrepSDKCall();
			if( g_hSDK_CDirector_AreWanderersAllowed == null )
				ThrowErrorCreate("CDirector::AreWanderersAllowed");
		}
	} else {
	// L4D1 only:
		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "ZombieManager::SpawnHunter") == false )
		{
			ThrowErrorSignature("ZombieManager::SpawnHunter");
		} else {
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
			PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
			g_hSDK_ZombieManager_SpawnHunter = EndPrepSDKCall();
			if( g_hSDK_ZombieManager_SpawnHunter == null )
				ThrowErrorCreate("ZombieManager::SpawnHunter");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "ZombieManager::SpawnBoomer") == false )
		{
			ThrowErrorSignature("ZombieManager::SpawnBoomer");
		} else {
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
			PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
			g_hSDK_ZombieManager_SpawnBoomer = EndPrepSDKCall();
			if( g_hSDK_ZombieManager_SpawnBoomer == null )
				ThrowErrorCreate("ZombieManager::SpawnBoomer");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "ZombieManager::SpawnSmoker") == false )
		{
			ThrowErrorSignature("ZombieManager::SpawnSmoker");
		} else {
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
			PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
			g_hSDK_ZombieManager_SpawnSmoker = EndPrepSDKCall();
			if( g_hSDK_ZombieManager_SpawnSmoker == null )
				ThrowErrorCreate("ZombieManager::SpawnSmoker");
		}
	}



	// =========================
	// l4d2addresses.txt
	// =========================
	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::OnVomitedUpon") == false )
	{
		ThrowErrorSignature("CTerrorPlayer::OnVomitedUpon");
	} else {
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		g_hSDK_CTerrorPlayer_OnVomitedUpon = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_OnVomitedUpon == null )
			ThrowErrorCreate("CTerrorPlayer::OnVomitedUpon");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::CancelStagger") == false )
	{
		ThrowErrorSignature("CTerrorPlayer::CancelStagger");
	} else {
		g_hSDK_CTerrorPlayer_CancelStagger = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_CancelStagger == null )
			ThrowErrorCreate("CTerrorPlayer::CancelStagger");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::FindUseEntity") == false )
	{
		ThrowErrorSignature("CTerrorPlayer::FindUseEntity");
	} else {
		PrepSDKCall_AddParameter(SDKType_Float,SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Float,SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Float,SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData,SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Bool,SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDK_CTerrorPlayer_FindUseEntity = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_FindUseEntity == null )
			ThrowErrorCreate("CTerrorPlayer::FindUseEntity");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::OnPouncedOnSurvivor") == false )
	{
		ThrowErrorSignature("CTerrorPlayer::OnPouncedOnSurvivor");
	}
	else
	{
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDK_CTerrorPlayer_OnPouncedOnSurvivor = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_OnPouncedOnSurvivor == null )
			ThrowErrorCreate("CTerrorPlayer::OnPouncedOnSurvivor");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::GrabVictimWithTongue") == false )
	{
		ThrowErrorSignature("CTerrorPlayer::GrabVictimWithTongue");
	}
	else
	{
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDK_CTerrorPlayer_GrabVictimWithTongue = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_GrabVictimWithTongue == null )
			ThrowErrorCreate("CTerrorPlayer::GrabVictimWithTongue");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::ReleaseTongueVictim") == false )
	{
		ThrowErrorSignature("CTerrorPlayer::ReleaseTongueVictim");
	}
	else
	{
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDK_CTerrorPlayer_ReleaseTongueVictim = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_ReleaseTongueVictim == null )
			ThrowErrorCreate("CTerrorPlayer::ReleaseTongueVictim");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::OnPounceEnded") == false )
	{
		ThrowErrorSignature("CTerrorPlayer::OnPounceEnded");
	}
	else
	{
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDK_CTerrorPlayer_OnPounceEnded = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_OnPounceEnded == null )
			ThrowErrorCreate("CTerrorPlayer::OnPounceEnded");
	}

	if( g_bLeft4Dead2 )
	{
		StartPrepSDKCall(SDKCall_Player);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::OnLeptOnSurvivor") == false )
		{
			ThrowErrorSignature("CTerrorPlayer::OnLeptOnSurvivor");
		}
		else
		{
			PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
			g_hSDK_CTerrorPlayer_OnLeptOnSurvivor = EndPrepSDKCall();
			if( g_hSDK_CTerrorPlayer_OnLeptOnSurvivor == null )
				ThrowErrorCreate("CTerrorPlayer::OnLeptOnSurvivor");
		}

		StartPrepSDKCall(SDKCall_Static);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "ThrowImpactedSurvivor") == false )
		{
			ThrowErrorSignature("ThrowImpactedSurvivor");
		}
		else
		{
			PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
			PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
			PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
			g_hSDK_ThrowImpactedSurvivor = EndPrepSDKCall();
			if( g_hSDK_ThrowImpactedSurvivor == null )
				ThrowErrorCreate("ThrowImpactedSurvivor");
		}

		StartPrepSDKCall(SDKCall_Player);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::OnStartCarryingVictim") == false )
		{
			ThrowErrorSignature("CTerrorPlayer::OnStartCarryingVictim");
		}
		else
		{
			PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
			g_hSDK_CTerrorPlayer_OnStartCarryingVictim = EndPrepSDKCall();
			if( g_hSDK_CTerrorPlayer_OnStartCarryingVictim == null )
				ThrowErrorCreate("CTerrorPlayer::OnStartCarryingVictim");
		}

		StartPrepSDKCall(SDKCall_Player);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::QueuePummelVictim") == false )
		{
			ThrowErrorSignature("CTerrorPlayer::QueuePummelVictim");
		}
		else
		{
			PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
			PrepSDKCall_AddParameter(SDKType_Float, SDKPass_ByValue);
			g_hSDK_CTerrorPlayer_QueuePummelVictim = EndPrepSDKCall();
			if( g_hSDK_CTerrorPlayer_QueuePummelVictim == null )
				ThrowErrorCreate("CTerrorPlayer::QueuePummelVictim");
		}

		StartPrepSDKCall(SDKCall_Player);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::OnPummelEnded") == false )
		{
			ThrowErrorSignature("CTerrorPlayer::OnPummelEnded");
		}
		else
		{
			PrepSDKCall_AddParameter(SDKType_String, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
			g_hSDK_CTerrorPlayer_OnPummelEnded = EndPrepSDKCall();
			if( g_hSDK_CTerrorPlayer_OnPummelEnded == null )
				ThrowErrorCreate("CTerrorPlayer::OnPummelEnded");
		}

		StartPrepSDKCall(SDKCall_Player);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::OnCarryEnded") == false )
		{
			ThrowErrorSignature("CTerrorPlayer::OnCarryEnded");
		}
		else
		{
			PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
			g_hSDK_CTerrorPlayer_OnCarryEnded = EndPrepSDKCall();
			if( g_hSDK_CTerrorPlayer_OnCarryEnded == null )
				ThrowErrorCreate("CTerrorPlayer::OnCarryEnded");
		}

		StartPrepSDKCall(SDKCall_Player);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::OnRideEnded") == false )
		{
			ThrowErrorSignature("CTerrorPlayer::OnRideEnded");
		}
		else
		{
			PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
			g_hSDK_CTerrorPlayer_OnRideEnded = EndPrepSDKCall();
			if( g_hSDK_CTerrorPlayer_OnRideEnded == null )
				ThrowErrorCreate("CTerrorPlayer::OnRideEnded");
		}
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::RoundRespawn") == false )
	{
		ThrowErrorSignature("CTerrorPlayer::RoundRespawn");
	} else {
		g_hSDK_CTerrorPlayer_RoundRespawn = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_RoundRespawn == null )
			ThrowErrorCreate("CTerrorPlayer::RoundRespawn");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::CreateRescuableSurvivors") == false )
	{
		ThrowErrorSignature("CDirector::CreateRescuableSurvivors");
	} else {
		g_hSDK_CDirector_CreateRescuableSurvivors = EndPrepSDKCall();
		if( g_hSDK_CDirector_CreateRescuableSurvivors == null )
			ThrowErrorCreate("CDirector::CreateRescuableSurvivors");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::StopBeingRevived") == false )
	{
		ThrowErrorSignature("CTerrorPlayer::StopBeingRevived");
	} else {
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		g_hSDK_CTerrorPlayer_StopBeingRevived = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_StopBeingRevived == null )
			ThrowErrorCreate("CTerrorPlayer::StopBeingRevived");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::OnRevived") == false )
	{
		ThrowErrorSignature("CTerrorPlayer::OnRevived");
	} else {
		g_hSDK_CTerrorPlayer_OnRevived = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_OnRevived == null )
			ThrowErrorCreate("CTerrorPlayer::OnRevived");
	}

	StartPrepSDKCall(SDKCall_Static);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirectorTacticalServices::GetHighestFlowSurvivor") == false )
	{
		ThrowErrorSignature("CDirectorTacticalServices::GetHighestFlowSurvivor");
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDK_CDirectorTacticalServices_GetHighestFlowSurvivor = EndPrepSDKCall();
		if( g_hSDK_CDirectorTacticalServices_GetHighestFlowSurvivor == null )
			ThrowErrorCreate("CDirectorTacticalServices::GetHighestFlowSurvivor");
	}

	StartPrepSDKCall(SDKCall_Entity);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "Infected::GetFlowDistance") == false )
	{
		ThrowErrorSignature("Infected::GetFlowDistance");
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_Plain);
		g_hSDK_Infected_GetFlowDistance = EndPrepSDKCall();
		if( g_hSDK_Infected_GetFlowDistance == null )
			ThrowErrorCreate("Infected::GetFlowDistance");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::TakeOverZombieBot") == false )
	{
		ThrowErrorSignature("CTerrorPlayer::TakeOverZombieBot");
	} else {
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		g_hSDK_CTerrorPlayer_TakeOverZombieBot = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_TakeOverZombieBot == null )
			ThrowErrorCreate("CTerrorPlayer::TakeOverZombieBot");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::ReplaceWithBot") == false )
	{
		ThrowErrorSignature("CTerrorPlayer::ReplaceWithBot");
	} else {
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		g_hSDK_CTerrorPlayer_ReplaceWithBot = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_ReplaceWithBot == null )
			ThrowErrorCreate("CTerrorPlayer::ReplaceWithBot");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::CullZombie") == false )
	{
		ThrowErrorSignature("CTerrorPlayer::CullZombie");
	} else {
		g_hSDK_CTerrorPlayer_CullZombie = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_CullZombie == null )
			ThrowErrorCreate("CTerrorPlayer::CullZombie");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::CleanupPlayerState") == false )
	{
		ThrowErrorSignature("CTerrorPlayer::CleanupPlayerState");
	} else {
		g_hSDK_CTerrorPlayer_CleanupPlayerState = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_CleanupPlayerState == null )
			ThrowErrorCreate("CTerrorPlayer::CleanupPlayerState");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::SetClass") == false )
	{
		ThrowErrorSignature("CTerrorPlayer::SetClass");
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CTerrorPlayer_SetClass = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_SetClass == null )
			ThrowErrorCreate("CTerrorPlayer::SetClass");
	}

	StartPrepSDKCall(SDKCall_Static);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CBaseAbility::CreateForPlayer") == false )
	{
		ThrowErrorSignature("CBaseAbility::CreateForPlayer");
	} else {
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDK_CBaseAbility_CreateForPlayer = EndPrepSDKCall();
		if( g_hSDK_CBaseAbility_CreateForPlayer == null )
			ThrowErrorCreate("CBaseAbility::CreateForPlayer");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::MaterializeFromGhost") == false )
	{
		ThrowErrorSignature("CTerrorPlayer::MaterializeFromGhost");
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CTerrorPlayer_MaterializeFromGhost = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_MaterializeFromGhost == null )
			ThrowErrorCreate("CTerrorPlayer::MaterializeFromGhost");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::BecomeGhost") == false )
	{
		ThrowErrorSignature("CTerrorPlayer::BecomeGhost");
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
			ThrowErrorCreate("CTerrorPlayer::BecomeGhost");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CCSPlayer::State_Transition") == false )
	{
		ThrowErrorSignature("CCSPlayer::State_Transition");
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CCSPlayer_State_Transition = EndPrepSDKCall();
		if( g_hSDK_CCSPlayer_State_Transition == null )
			ThrowErrorCreate("CCSPlayer::State_Transition");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::RegisterForbiddenTarget") == false )
	{
		ThrowErrorSignature("CDirector::RegisterForbiddenTarget");
	} else {
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CDirector_RegisterForbiddenTarget = EndPrepSDKCall();
		if( g_hSDK_CDirector_RegisterForbiddenTarget == null )
			ThrowErrorCreate("CDirector::RegisterForbiddenTarget");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::UnregisterForbiddenTarget") == false )
	{
		ThrowErrorSignature("CDirector::UnregisterForbiddenTarget");
	} else {
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDK_CDirector_UnregisterForbiddenTarget = EndPrepSDKCall();
		if( g_hSDK_CDirector_UnregisterForbiddenTarget == null )
			ThrowErrorCreate("CDirector::UnregisterForbiddenTarget");
	}

	StartPrepSDKCall(SDKCall_Entity);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "InfoChangelevel::IsEntitySaveable") == false )
	{
		ThrowErrorSignature("InfoChangelevel::IsEntitySaveable");
	} else {
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_InfoChangeLevel_IsEntitySaveable = EndPrepSDKCall();
		if( g_hSDK_InfoChangeLevel_IsEntitySaveable == null )
			ThrowErrorCreate("InfoChangeLevel::IsEntitySaveable");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirectorVersusMode::EndVersusModeRound") == false )
	{
	ThrowErrorSignature("CDirectorVersusMode::EndVersusModeRound");
	} else {
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CDirectorVersusMode_EndVersusModeRound = EndPrepSDKCall();
		if( g_hSDK_CDirectorVersusMode_EndVersusModeRound == null )
			ThrowErrorCreate("CDirectorVersusMode::EndVersusModeRound");
	}



	if( g_bLeft4Dead2 )
	{
		StartPrepSDKCall(SDKCall_Player);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::OnHitByVomitJar") == false )
		{
			ThrowErrorSignature("CTerrorPlayer::OnHitByVomitJar");
		} else {
			PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
			g_hSDK_CTerrorPlayer_OnHitByVomitJar = EndPrepSDKCall();
			if( g_hSDK_CTerrorPlayer_OnHitByVomitJar == null )
				ThrowErrorCreate("CTerrorPlayer::OnHitByVomitJar");
		}

		StartPrepSDKCall(SDKCall_Entity);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "Infected::OnHitByVomitJar") == false )
		{
			ThrowErrorSignature("Infected::OnHitByVomitJar");
		} else {
			PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
			g_hSDK_Infected_OnHitByVomitJar = EndPrepSDKCall();
			if( g_hSDK_Infected_OnHitByVomitJar == null )
				ThrowErrorCreate("Infected::OnHitByVomitJar");
		}

		StartPrepSDKCall(SDKCall_Player);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::Fling") == false )
		{
			ThrowErrorSignature("CTerrorPlayer::Fling");
		} else {
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
			PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
			g_hSDK_CTerrorPlayer_Fling = EndPrepSDKCall();
			if( g_hSDK_CTerrorPlayer_Fling == null )
				ThrowErrorCreate("CTerrorPlayer::Fling");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorGameRules::GetVersusCompletion") == false )
		{
			ThrowErrorSignature("CTerrorGameRules::GetVersusCompletion");
		} else {
			PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_CTerrorGameRules_GetVersusCompletion = EndPrepSDKCall();
			if( g_hSDK_CTerrorGameRules_GetVersusCompletion == null )
				ThrowErrorCreate("CTerrorGameRules::GetVersusCompletion");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::SwapTeams") == false )
		{
			ThrowErrorSignature("CDirector::SwapTeams");
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_CDirector_SwapTeams = EndPrepSDKCall();
			if( g_hSDK_CDirector_SwapTeams == null )
				ThrowErrorCreate("CDirector::SwapTeams");
		}

		/*
		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::AreTeamsFlipped") == false )
		{
			ThrowErrorSignature("CDirector::AreTeamsFlipped");
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_CDirector_AreTeamsFlipped = EndPrepSDKCall();
			if( g_hSDK_CDirector_AreTeamsFlipped == null )
				ThrowErrorCreate("CDirector::AreTeamsFlipped");
		}
		*/

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::Rematch") == false )
		{
			ThrowErrorSignature("CDirector::Rematch");
		} else {
			g_hSDK_CDirector_Rematch = EndPrepSDKCall();
			if( g_hSDK_CDirector_Rematch == null )
				ThrowErrorCreate("CDirector::Rematch");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::StartRematchVote") == false )
		{
			ThrowErrorSignature("CDirector::StartRematchVote");
		} else {
			g_hSDK_CDirector_StartRematchVote = EndPrepSDKCall();
			if( g_hSDK_CDirector_StartRematchVote == null )
				ThrowErrorCreate("CDirector::StartRematchVote");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::FullRestart") == false )
		{
			ThrowErrorSignature("CDirector::FullRestart");
		} else {
			g_hSDK_CDirector_FullRestart = EndPrepSDKCall();
			if( g_hSDK_CDirector_FullRestart == null )
				ThrowErrorCreate("CDirector::FullRestart");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirectorVersusMode::HideScoreboardNonVirtual") == false )
		{
			ThrowErrorSignature("CDirectorVersusMode::HideScoreboardNonVirtual");
		} else {
			g_hSDK_CDirectorVersusMode_HideScoreboardNonVirtual = EndPrepSDKCall();
			if( g_hSDK_CDirectorVersusMode_HideScoreboardNonVirtual == null )
				ThrowErrorCreate("CDirectorVersusMode::HideScoreboardNonVirtual");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirectorScavengeMode::HideScoreboardNonVirtual") == false )
		{
			ThrowErrorSignature("CDirectorScavengeMode::HideScoreboardNonVirtual");
		} else {
			g_hSDK_CDirectorScavengeMode_HideScoreboardNonVirtual = EndPrepSDKCall();
			if( g_hSDK_CDirectorScavengeMode_HideScoreboardNonVirtual == null )
				ThrowErrorCreate("CDirectorScavengeMode::HideScoreboardNonVirtual");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::HideScoreboard") == false )
		{
			ThrowErrorSignature("CDirector::CDirectorHideScoreboard");
		} else {
			g_hSDK_CDirector_HideScoreboard = EndPrepSDKCall();
			if( g_hSDK_CDirector_HideScoreboard == null )
				ThrowErrorCreate("CDirector::HideScoreboard");
		}
	}

	StartPrepSDKCall(SDKCall_Static); // Since SM 1.11 can use "SDKCall_Server" (but that crashes the server)
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CBaseServer::SetReservationCookie") == false )
	{
		ThrowErrorSignature("CBaseServer::SetReservationCookie");
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		g_hSDK_CBaseServer_SetReservationCookie = EndPrepSDKCall();
		if( g_hSDK_CBaseServer_SetReservationCookie == null )
			ThrowErrorCreate("CBaseServer::SetReservationCookie");
	}



	// UNUSED / BROKEN
	/* DEPRECATED
	StartPrepSDKCall(SDKCall_Static);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "GetCampaignScores") == false )
	{
		ThrowErrorSignature("GetCampaignScores");
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_GetCampaignScores = EndPrepSDKCall();
		if( g_hSDK_GetCampaignScores == null )
			ThrowErrorCreate("GetCampaignScores");
	}
	// */

	/* DEPRECATED on L4D2 and L4D1 Linux
	StartPrepSDKCall(SDKCall_Static);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "LobbyIsReserved") == false )
	{
		ThrowErrorSignature("LobbyIsReserved");
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_LobbyIsReserved = EndPrepSDKCall();
		if( g_hSDK_LobbyIsReserved == null )
			ThrowErrorCreate("LobbyIsReserved");
	}
	// */



	// ====================================================================================================
	//									VALIDATE SDKCALLS
	// ====================================================================================================
	#if VERIFY_SDKCALL
	ValidateSDKCall(g_hSDK_GetWeaponInfo, "g_hSDK_GetWeaponInfo");
	ValidateSDKCall(g_hSDK_CTerrorGameRules_GetMissionInfo, "g_hSDK_CTerrorGameRules_GetMissionInfo");
	ValidateSDKCall(g_hSDK_CTerrorPlayer_GetLastKnownArea, "g_hSDK_CTerrorPlayer_GetLastKnownArea");
	ValidateSDKCall(g_hSDK_CTerrorPlayer_Deafen, "g_hSDK_CTerrorPlayer_Deafen");
	ValidateSDKCall(g_hSDK_Music_Play, "g_hSDK_Music_Play");
	ValidateSDKCall(g_hSDK_Music_StopPlaying, "g_hSDK_Music_StopPlaying");
	ValidateSDKCall(g_hSDK_CEntityDissolve_Create, "g_hSDK_CEntityDissolve_Create");
	ValidateSDKCall(g_hSDK_CTerrorPlayer_OnITExpired, "g_hSDK_CTerrorPlayer_OnITExpired");
	ValidateSDKCall(g_hSDK_CTerrorPlayer_EstimateFallingDamage, "g_hSDK_CTerrorPlayer_EstimateFallingDamage");
	ValidateSDKCall(g_hSDK_CBaseEntity_WorldSpaceCenter, "g_hSDK_CBaseEntity_WorldSpaceCenter");
	ValidateSDKCall(g_hSDK_IPhysicsObject_GetMass, "g_hSDK_IPhysicsObject_GetMass");
	ValidateSDKCall(g_hSDK_IPhysicsObject_SetMass, "g_hSDK_IPhysicsObject_SetMass");
	ValidateSDKCall(g_hSDK_CBaseEntity_ApplyLocalAngularVelocityImpulse, "g_hSDK_CBaseEntity_ApplyLocalAngularVelocityImpulse");
	ValidateSDKCall(g_hSDK_ZombieManager_GetRandomPZSpawnPosition, "g_hSDK_ZombieManager_GetRandomPZSpawnPosition");
	ValidateSDKCall(g_hSDK_CNavMesh_GetNearestNavArea, "g_hSDK_CNavMesh_GetNearestNavArea");
	ValidateSDKCall(g_hSDK_TerrorNavArea_FindRandomSpot, "g_hSDK_TerrorNavArea_FindRandomSpot");
	ValidateSDKCall(g_hSDK_CTerrorPlayer_WarpToValidPositionIfStuck, "g_hSDK_CTerrorPlayer_WarpToValidPositionIfStuck");
	ValidateSDKCall(g_hSDK_CDirector_HasAnySurvivorLeftSafeArea, "g_hSDK_CDirector_HasAnySurvivorLeftSafeArea");
	ValidateSDKCall(g_hSDK_CBaseTrigger_IsTouching, "g_hSDK_CBaseTrigger_IsTouching");
	ValidateSDKCall(g_hSDK_CGlobalEntityList_FindEntityByClassnameNearest, "g_hSDK_CGlobalEntityList_FindEntityByClassnameNearest");
	ValidateSDKCall(g_hSDK_CGlobalEntityList_FindEntityByClassnameWithin, "g_hSDK_CGlobalEntityList_FindEntityByClassnameWithin");
	ValidateSDKCall(g_hSDK_CDirector_AreAllSurvivorsInFinaleArea, "g_hSDK_CDirector_AreAllSurvivorsInFinaleArea");
	ValidateSDKCall(g_hSDK_TerrorNavMesh_GetInitialCheckpoint, "g_hSDK_TerrorNavMesh_GetInitialCheckpoint");
	ValidateSDKCall(g_hSDK_Checkpoint_ContainsArea, "g_hSDK_Checkpoint_ContainsArea");
	ValidateSDKCall(g_hSDK_CTerrorGameRules_HasPlayerControlledZombies, "g_hSDK_CTerrorGameRules_HasPlayerControlledZombies");
	ValidateSDKCall(g_hSDK_ForceVersusStart, "g_hSDK_ForceVersusStart");
	ValidateSDKCall(g_hSDK_ForceSurvivalStart, "g_hSDK_ForceSurvivalStart");
	ValidateSDKCall(g_hSDK_CBaseGrenade_Detonate, "g_hSDK_CBaseGrenade_Detonate");
	ValidateSDKCall(g_hSDK_CPipeBombProjectile_Create, "g_hSDK_CPipeBombProjectile_Create");
	ValidateSDKCall(g_hSDK_CMolotovProjectile_Create, "g_hSDK_CMolotovProjectile_Create");
	ValidateSDKCall(g_hSDK_NavAreaTravelDistance, "g_hSDK_NavAreaTravelDistance");
	ValidateSDKCall(g_hSDK_CDirector_RestartScenarioFromVote, "g_hSDK_CDirector_RestartScenarioFromVote");
	ValidateSDKCall(g_hSDK_CTerrorGameRules_SetCampaignScores, "g_hSDK_CTerrorGameRules_SetCampaignScores");
	ValidateSDKCall(g_hSDK_CTerrorGameRules_GetTeamScore, "g_hSDK_CTerrorGameRules_GetTeamScore");
	ValidateSDKCall(g_hSDK_CDirector_IsFirstMapInScenario, "g_hSDK_CDirector_IsFirstMapInScenario");
	ValidateSDKCall(g_hSDK_CTerrorGameRules_IsMissionFinalMap, "g_hSDK_CTerrorGameRules_IsMissionFinalMap");
	ValidateSDKCall(g_hSDK_KeyValues_GetString, "g_hSDK_KeyValues_GetString");
	ValidateSDKCall(g_hSDK_AmmoDef_MaxCarry, "g_hSDK_AmmoDef_MaxCarry");
	ValidateSDKCall(g_hSDK_CGameRulesProxy_NotifyNetworkStateChanged, "g_hSDK_CGameRulesProxy_NotifyNetworkStateChanged");
	ValidateSDKCall(g_hSDK_CTerrorPlayer_OnStaggered, "g_hSDK_CTerrorPlayer_OnStaggered");
	ValidateSDKCall(g_hSDK_CDirectorScriptedEventManager_SendInRescueVehicle, "g_hSDK_CDirectorScriptedEventManager_SendInRescueVehicle");
	ValidateSDKCall(g_hSDK_ZombieManager_ReplaceTank, "g_hSDK_ZombieManager_ReplaceTank");
	ValidateSDKCall(g_hSDK_ZombieManager_SpawnTank, "g_hSDK_ZombieManager_SpawnTank");
	ValidateSDKCall(g_hSDK_ZombieManager_SpawnWitch, "g_hSDK_ZombieManager_SpawnWitch");
	ValidateSDKCall(g_hSDK_CDirector_IsFinaleEscapeInProgress, "g_hSDK_CDirector_IsFinaleEscapeInProgress");
	ValidateSDKCall(g_hSDK_SurvivorBot_SetHumanSpectator, "g_hSDK_SurvivorBot_SetHumanSpectator");
	ValidateSDKCall(g_hSDK_CTerrorPlayer_TakeOverBot, "g_hSDK_CTerrorPlayer_TakeOverBot");
	ValidateSDKCall(g_hSDK_CTerrorPlayer_CanBecomeGhost, "g_hSDK_CTerrorPlayer_CanBecomeGhost");
	ValidateSDKCall(g_hSDK_CTerrorPlayer_SetBecomeGhostAt, "g_hSDK_CTerrorPlayer_SetBecomeGhostAt");
	ValidateSDKCall(g_hSDK_CTerrorPlayer_GoAwayFromKeyboard, "g_hSDK_CTerrorPlayer_GoAwayFromKeyboard");
	ValidateSDKCall(g_hSDK_CDirector_TryOfferingTankBot, "g_hSDK_CDirector_TryOfferingTankBot");
	ValidateSDKCall(g_hSDK_CNavMesh_GetNavArea, "g_hSDK_CNavMesh_GetNavArea");
	ValidateSDKCall(g_hSDK_CNavArea_IsConnected, "g_hSDK_CNavArea_IsConnected");
	ValidateSDKCall(g_hSDK_CNavArea_ConnectTo, "g_hSDK_CNavArea_ConnectTo");
	ValidateSDKCall(g_hSDK_CNavArea_IsBlocked, "g_hSDK_CNavArea_IsBlocked");
	ValidateSDKCall(g_hSDK_CNavArea_GetZ, "g_hSDK_CNavArea_GetZ");
	ValidateSDKCall(g_hSDK_CTerrorPlayer_GetFlowDistance, "g_hSDK_CTerrorPlayer_GetFlowDistance");
	ValidateSDKCall(g_hSDK_Intensity_Reset, "g_hSDK_Intensity_Reset");
	ValidateSDKCall(g_hSDK_CTerrorPlayer_SetShovePenalty, "g_hSDK_CTerrorPlayer_SetShovePenalty");
	ValidateSDKCall(g_hSDK_CTerrorPlayer_DoAnimationEvent, "g_hSDK_CTerrorPlayer_DoAnimationEvent");
	ValidateSDKCall(g_hSDK_CTerrorGameRules_RecomputeTeamScores, "g_hSDK_CTerrorGameRules_RecomputeTeamScores");
	ValidateSDKCall(g_hSDK_CTerrorPlayer_OnVomitedUpon, "g_hSDK_CTerrorPlayer_OnVomitedUpon");
	ValidateSDKCall(g_hSDK_CTerrorPlayer_CancelStagger, "g_hSDK_CTerrorPlayer_CancelStagger");
	ValidateSDKCall(g_hSDK_CTerrorPlayer_FindUseEntity, "g_hSDK_CTerrorPlayer_FindUseEntity");
	ValidateSDKCall(g_hSDK_CTerrorPlayer_OnPouncedOnSurvivor, "g_hSDK_CTerrorPlayer_OnPouncedOnSurvivor");
	ValidateSDKCall(g_hSDK_CTerrorPlayer_GrabVictimWithTongue, "g_hSDK_CTerrorPlayer_GrabVictimWithTongue");
	ValidateSDKCall(g_hSDK_CTerrorPlayer_ReleaseTongueVictim, "g_hSDK_CTerrorPlayer_ReleaseTongueVictim");
	ValidateSDKCall(g_hSDK_CTerrorPlayer_OnPounceEnded, "g_hSDK_CTerrorPlayer_OnPounceEnded");
	ValidateSDKCall(g_hSDK_CTerrorPlayer_RoundRespawn, "g_hSDK_CTerrorPlayer_RoundRespawn");
	ValidateSDKCall(g_hSDK_CDirector_CreateRescuableSurvivors, "g_hSDK_CDirector_CreateRescuableSurvivors");
	ValidateSDKCall(g_hSDK_CTerrorPlayer_StopBeingRevived, "g_hSDK_CTerrorPlayer_StopBeingRevived");
	ValidateSDKCall(g_hSDK_CTerrorPlayer_OnRevived, "g_hSDK_CTerrorPlayer_OnRevived");
	ValidateSDKCall(g_hSDK_CDirectorTacticalServices_GetHighestFlowSurvivor, "g_hSDK_CDirectorTacticalServices_GetHighestFlowSurvivor");
	ValidateSDKCall(g_hSDK_Infected_GetFlowDistance, "g_hSDK_Infected_GetFlowDistance");
	ValidateSDKCall(g_hSDK_CTerrorPlayer_TakeOverZombieBot, "g_hSDK_CTerrorPlayer_TakeOverZombieBot");
	ValidateSDKCall(g_hSDK_CTerrorPlayer_ReplaceWithBot, "g_hSDK_CTerrorPlayer_ReplaceWithBot");
	ValidateSDKCall(g_hSDK_CTerrorPlayer_CullZombie, "g_hSDK_CTerrorPlayer_CullZombie");
	ValidateSDKCall(g_hSDK_CTerrorPlayer_CleanupPlayerState, "g_hSDK_CTerrorPlayer_CleanupPlayerState");
	ValidateSDKCall(g_hSDK_CTerrorPlayer_SetClass, "g_hSDK_CTerrorPlayer_SetClass");
	ValidateSDKCall(g_hSDK_CBaseAbility_CreateForPlayer, "g_hSDK_CBaseAbility_CreateForPlayer");
	ValidateSDKCall(g_hSDK_CTerrorPlayer_MaterializeFromGhost, "g_hSDK_CTerrorPlayer_MaterializeFromGhost");
	ValidateSDKCall(g_hSDK_CTerrorPlayer_BecomeGhost, "g_hSDK_CTerrorPlayer_BecomeGhost");
	ValidateSDKCall(g_hSDK_CCSPlayer_State_Transition, "g_hSDK_CCSPlayer_State_Transition");
	ValidateSDKCall(g_hSDK_CDirector_RegisterForbiddenTarget, "g_hSDK_CDirector_RegisterForbiddenTarget");
	ValidateSDKCall(g_hSDK_CDirector_UnregisterForbiddenTarget, "g_hSDK_CDirector_UnregisterForbiddenTarget");
	ValidateSDKCall(g_hSDK_InfoChangeLevel_IsEntitySaveable, "g_hSDK_InfoChangeLevel_IsEntitySaveable");
	ValidateSDKCall(g_hSDK_CDirectorVersusMode_EndVersusModeRound, "g_hSDK_CDirectorVersusMode_EndVersusModeRound");
	ValidateSDKCall(g_hSDK_CBaseServer_SetReservationCookie, "g_hSDK_CBaseServer_SetReservationCookie");

	if( g_bLeft4Dead2 || g_bLinuxOS )
		ValidateSDKCall(g_hSDK_TerrorNavArea_IsPotentiallyVisibleToTeam, "g_hSDK_TerrorNavArea_IsPotentiallyVisibleToTeam");
	ValidateSDKCall(g_hSDK_TerrorNavArea_IsPotentiallyVisible, "g_hSDK_TerrorNavArea_IsPotentiallyVisible");
	ValidateSDKCall(g_hSDK_TerrorNavArea_IsCompletelyVisibleToTeam, "g_hSDK_TerrorNavArea_IsCompletelyVisibleToTeam");
	ValidateSDKCall(g_hSDK_TerrorNavArea_IsCompletelyVisible, "g_hSDK_TerrorNavArea_IsCompletelyVisible");
	ValidateSDKCall(g_hSDK_IVEngineServer_GetPVSForCluster, "g_hSDK_IVEngineServer_GetPVSForCluster");
	ValidateSDKCall(g_hSDK_IVEngineServer_GetClusterForOrigin, "g_hSDK_IVEngineServer_GetClusterForOrigin");
	ValidateSDKCall(g_hSDK_IVEngineServer_CheckOriginInPVS, "g_hSDK_IVEngineServer_CheckOriginInPVS");

	if( g_bLeft4Dead2 )
	{
		ValidateSDKCall(g_hSDK_CMultiPlayerAnimState_ResetMainActivity, "g_hSDK_CMultiPlayerAnimState_ResetMainActivity");
		ValidateSDKCall(g_hSDK_CTerrorPlayer_GetSpecialInfectedDominatingMe, "g_hSDK_CTerrorPlayer_GetSpecialInfectedDominatingMe");
		ValidateSDKCall(g_hSDK_IsVisibleToPlayer, "g_hSDK_IsVisibleToPlayer");
		ValidateSDKCall(g_hSDK_TerrorNavMesh_IsInInitialCheckpoint_NoLandmark, "g_hSDK_TerrorNavMesh_IsInInitialCheckpoint_NoLandmark");
		ValidateSDKCall(g_hSDK_CTerrorGameRules_GetSurvivorSet, "g_hSDK_CTerrorGameRules_GetSurvivorSet");
		ValidateSDKCall(g_hSDK_CVomitJarProjectile_Create, "g_hSDK_CVomitJarProjectile_Create");
		ValidateSDKCall(g_hSDK_CGrenadeLauncher_Projectile_Create, "g_hSDK_CGrenadeLauncher_Projectile_Create");
		ValidateSDKCall(g_hSDK_CTerrorGameRules_IsRealismMode, "g_hSDK_CTerrorGameRules_IsRealismMode");
		ValidateSDKCall(g_hSDK_CSpitterProjectile_Create, "g_hSDK_CSpitterProjectile_Create");
		ValidateSDKCall(g_hSDK_CTerrorGameRules_HasConfigurableDifficultySetting, "g_hSDK_CTerrorGameRules_HasConfigurableDifficultySetting");
		ValidateSDKCall(g_hSDK_NavAreaBuildPath_ShortestPathCost, "g_hSDK_NavAreaBuildPath_ShortestPathCost");
		ValidateSDKCall(g_hSDK_CTerrorPlayer_OnAdrenalineUsed, "g_hSDK_CTerrorPlayer_OnAdrenalineUsed");
		ValidateSDKCall(g_hSDK_CDirector_ForceNextStage, "g_hSDK_CDirector_ForceNextStage");
		ValidateSDKCall(g_hSDK_ForceScavengeStart, "g_hSDK_ForceScavengeStart");
		ValidateSDKCall(g_hSDK_CDirector_IsTankInPlay, "g_hSDK_CDirector_IsTankInPlay");
		ValidateSDKCall(g_hSDK_CTDefibPlayer, "g_hSDK_CTDefibPlayer");
		ValidateSDKCall(g_hSDK_SurvivorBot_IsReachable, "g_hSDK_SurvivorBot_IsReachable");
		ValidateSDKCall(g_hSDK_CDirector_GetFurthestSurvivorFlow, "g_hSDK_CDirector_GetFurthestSurvivorFlow");
		ValidateSDKCall(g_hSDK_CDirector_GetScriptValueInt, "g_hSDK_CDirector_GetScriptValueInt");
		ValidateSDKCall(g_hSDK_CDirector_GetScriptValueFloat, "g_hSDK_CDirector_GetScriptValueFloat");
		ValidateSDKCall(g_hSDK_CTerrorGameRules_GetNumChaptersForMissionAndMode, "g_hSDK_CTerrorGameRules_GetNumChaptersForMissionAndMode");
		ValidateSDKCall(g_hSDK_CDirector_GetGameModeBase, "g_hSDK_CDirector_GetGameModeBase");
		ValidateSDKCall(g_hSDK_CTerrorGameRules_IsGenericCooperativeMode, "g_hSDK_CTerrorGameRules_IsGenericCooperativeMode");
		ValidateSDKCall(g_hSDK_CDirector_AddSurvivorBot, "g_hSDK_CDirector_AddSurvivorBot");
		ValidateSDKCall(g_hSDK_TheNextBots, "g_hSDK_TheNextBots");
		ValidateSDKCall(g_hSDK_RushVictim, "g_hSDK_RushVictim");
		ValidateSDKCall(g_hSDK_StartAssault, "g_hSDK_StartAssault");
		ValidateSDKCall(g_hSDK_CMeleeWeaponInfoStore_GetMeleeWeaponInfo, "g_hSDK_CMeleeWeaponInfoStore_GetMeleeWeaponInfo");
		ValidateSDKCall(g_hSDK_CDirector_ResetMobTimer, "g_hSDK_CDirector_ResetMobTimer");
		ValidateSDKCall(g_hSDK_CDirector_SpawnAllScavengeItems, "g_hSDK_CDirector_SpawnAllScavengeItems");
		ValidateSDKCall(g_hSDK_CDirectorScriptedEventManager_ChangeFinaleStage, "g_hSDK_CDirectorScriptedEventManager_ChangeFinaleStage");
		ValidateSDKCall(g_hSDK_ZombieManager_SpawnSpecial, "g_hSDK_ZombieManager_SpawnSpecial");
		ValidateSDKCall(g_hSDK_ZombieManager_SpawnWitchBride, "g_hSDK_ZombieManager_SpawnWitchBride");
		ValidateSDKCall(g_hSDK_CDirector_AreWanderersAllowed, "g_hSDK_CDirector_AreWanderersAllowed");
		ValidateSDKCall(g_hSDK_CTerrorPlayer_OnLeptOnSurvivor, "g_hSDK_CTerrorPlayer_OnLeptOnSurvivor");
		ValidateSDKCall(g_hSDK_ThrowImpactedSurvivor, "g_hSDK_ThrowImpactedSurvivor");
		ValidateSDKCall(g_hSDK_CTerrorPlayer_OnStartCarryingVictim, "g_hSDK_CTerrorPlayer_OnStartCarryingVictim");
		ValidateSDKCall(g_hSDK_CTerrorPlayer_QueuePummelVictim, "g_hSDK_CTerrorPlayer_QueuePummelVictim");
		ValidateSDKCall(g_hSDK_CTerrorPlayer_OnPummelEnded, "g_hSDK_CTerrorPlayer_OnPummelEnded");
		ValidateSDKCall(g_hSDK_CTerrorPlayer_OnCarryEnded, "g_hSDK_CTerrorPlayer_OnCarryEnded");
		ValidateSDKCall(g_hSDK_CTerrorPlayer_OnRideEnded, "g_hSDK_CTerrorPlayer_OnRideEnded");
		ValidateSDKCall(g_hSDK_CTerrorPlayer_OnHitByVomitJar, "g_hSDK_CTerrorPlayer_OnHitByVomitJar");
		ValidateSDKCall(g_hSDK_Infected_OnHitByVomitJar, "g_hSDK_Infected_OnHitByVomitJar");
		ValidateSDKCall(g_hSDK_CTerrorPlayer_Fling, "g_hSDK_CTerrorPlayer_Fling");
		ValidateSDKCall(g_hSDK_CTerrorGameRules_GetVersusCompletion, "g_hSDK_CTerrorGameRules_GetVersusCompletion");
		ValidateSDKCall(g_hSDK_CDirector_SwapTeams, "g_hSDK_CDirector_SwapTeams");
		ValidateSDKCall(g_hSDK_CDirector_Rematch, "g_hSDK_CDirector_Rematch");
		ValidateSDKCall(g_hSDK_CDirector_StartRematchVote, "g_hSDK_CDirector_StartRematchVote");
		ValidateSDKCall(g_hSDK_CDirector_FullRestart, "g_hSDK_CDirector_FullRestart");
		ValidateSDKCall(g_hSDK_CDirectorVersusMode_HideScoreboardNonVirtual, "g_hSDK_CDirectorVersusMode_HideScoreboardNonVirtual");
		ValidateSDKCall(g_hSDK_CDirectorScavengeMode_HideScoreboardNonVirtual, "g_hSDK_CDirectorScavengeMode_HideScoreboardNonVirtual");
		ValidateSDKCall(g_hSDK_CDirector_HideScoreboard, "g_hSDK_CDirector_HideScoreboard");
	}

	if( !g_bLeft4Dead2 )
	{
		ValidateSDKCall(g_hSDK_ZombieManager_SpawnHunter, "g_hSDK_ZombieManager_SpawnHunter");
		ValidateSDKCall(g_hSDK_ZombieManager_SpawnBoomer, "g_hSDK_ZombieManager_SpawnBoomer");
		ValidateSDKCall(g_hSDK_ZombieManager_SpawnSmoker, "g_hSDK_ZombieManager_SpawnSmoker");
	}
	#endif



	// ====================================================================================================
	//									POINTER OFFSETS
	// ====================================================================================================
	if( g_bLeft4Dead2 )
	{
		g_pScavengeMode = hGameData.GetOffset("ScavengeModePtr");
		ValidateOffset(g_pScavengeMode, "ScavengeModePtr");

		g_pVersusMode = hGameData.GetOffset("VersusModePtr");
		ValidateOffset(g_pVersusMode, "VersusModePtr");

		g_pSurvivalMode = hGameData.GetOffset("SurvivalModePtr");
		ValidateOffset(g_pSurvivalMode, "SurvivalModePtr");

		g_pScriptedEventManager = hGameData.GetOffset("ScriptedEventManagerPtr");
		ValidateOffset(g_pScriptedEventManager, "ScriptedEventManagerPtr");

		g_pItemManager = hGameData.GetOffset("ItemManagerPtr");
		ValidateOffset(g_pItemManager, "ItemManagerPtr");

		g_pMusicBanks = hGameData.GetOffset("MusicBanksPtr");
		ValidateOffset(g_pMusicBanks, "MusicBanksPtr");

		g_pSessionManager = hGameData.GetOffset("SessionManagerPtr");
		ValidateOffset(g_pSessionManager, "SessionManagerPtr");

		g_pChallengeMode = hGameData.GetOffset("ChallengeModePtr");
		ValidateOffset(g_pChallengeMode, "ChallengeModePtr");

		g_pTheNextBots = SDKCall(g_hSDK_TheNextBots);



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
	// g_iOff_EHandle = hGameData.GetOffset("EHandleOffset");
	// ValidateOffset(g_iOff_EHandle, "EHandleOffset");

	g_iOff_LobbyReservation = hGameData.GetOffset("LobbyReservationOffset");
	ValidateOffset(g_iOff_LobbyReservation, "LobbyReservationOffset");

	g_iOff_AcceptInput = hGameData.GetOffset("CBaseEntity::AcceptInput");
	ValidateOffset(g_iOff_AcceptInput, "CBaseEntity::AcceptInput");

	g_pAmmoDef = hGameData.GetAddress("ammoDef");
	ValidateAddress(g_pAmmoDef, "AmmoDef", true);

	g_pDirector = hGameData.GetAddress("CDirector");
	ValidateAddress(g_pDirector, "CDirector", true);

	g_pZombieManager = hGameData.GetAddress("ZombieManager");
	ValidateAddress(g_pZombieManager, "g_pZombieManager", true);

	g_pNavMesh = hGameData.GetAddress("TerrorNavMesh");
	ValidateAddress(g_pNavMesh, "TheNavMesh", true);

	g_pEntList = hGameData.GetAddress("gEntList");
	ValidateAddress(g_pEntList, "gEntList", true);

	g_pServer = hGameData.GetAddress("ServerAddr");
	ValidateAddress(g_pServer, "g_pServer", true);

	g_pEngine = hGameData.GetAddress("EngineAddr");
	ValidateAddress(g_pEngine, "g_pEngine", true);

	g_pWeaponInfoDatabase = hGameData.GetAddress("WeaponInfoDatabase");
	ValidateAddress(g_pWeaponInfoDatabase, "g_pWeaponInfoDatabase", true);

	if( g_bLeft4Dead2 )
	{
		g_hScriptHook = DynamicHook.FromConf(hGameData, "CSquirrelVM::GetValue");

		g_pMeleeWeaponInfoStore = hGameData.GetAddress("MeleeWeaponInfoStore");
		ValidateAddress(g_pMeleeWeaponInfoStore, "g_pMeleeWeaponInfoStore", true);

		g_pScriptedEventManager = LoadFromAddress(g_pDirector + view_as<Address>(g_pScriptedEventManager), NumberType_Int32);
		ValidateAddress(g_pScriptedEventManager, "ScriptedEventManagerPtr", true);

		g_pVersusMode = LoadFromAddress(g_pDirector + view_as<Address>(g_pVersusMode), NumberType_Int32);
		ValidateAddress(g_pVersusMode, "VersusModePtr", true);

		g_pScavengeMode = LoadFromAddress(g_pDirector + view_as<Address>(g_pScavengeMode), NumberType_Int32);
		ValidateAddress(g_pScavengeMode, "ScavengeModePtr", true);

		g_pSurvivalMode = LoadFromAddress(g_pDirector + view_as<Address>(g_pSurvivalMode), NumberType_Int32);
		ValidateAddress(g_pSurvivalMode, "g_pSurvivalMode", true);

		g_pItemManager = LoadFromAddress(g_pDirector + view_as<Address>(g_pItemManager), NumberType_Int32);
		ValidateAddress(g_pItemManager, "ItemManagerPtr", true);

		g_pMusicBanks = LoadFromAddress(g_pDirector + view_as<Address>(g_pMusicBanks), NumberType_Int32);
		ValidateAddress(g_pMusicBanks, "MusicBanksPtr", true);

		g_pSessionManager = LoadFromAddress(g_pDirector + view_as<Address>(g_pSessionManager), NumberType_Int32);
		ValidateAddress(g_pSessionManager, "SessionManagerPtr", true);

		g_pChallengeMode = LoadFromAddress(g_pDirector + view_as<Address>(g_pChallengeMode), NumberType_Int32);
		ValidateAddress(g_pChallengeMode, "ChallengeModePtr", true);
	} else {
		// L4D1: g_pDirector is also g_pVersusMode.
		g_pVersusMode = view_as<int>(g_pDirector);

		g_pSurvivalMode = view_as<int>(g_pDirector);
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
	PrintToServer("%12d == g_pEntList", g_pEntList);
	PrintToServer("%12d == g_pServer", g_pServer);
	PrintToServer("%12d == g_pEngine", g_pEngine);
	PrintToServer("%12d == g_pWeaponInfoDatabase", g_pWeaponInfoDatabase);
	PrintToServer("%12d == g_pVersusModePtr", g_pVersusMode);
	PrintToServer("%12d == g_pSurvivalModePtr", g_pSurvivalMode);

	if( g_bLeft4Dead2 )
	{
		PrintToServer("%12d == g_pMeleeWeaponInfoStore", g_pMeleeWeaponInfoStore);
		PrintToServer("%12d == g_pScriptedEventManagerPtr", g_pScriptedEventManager);
		PrintToServer("%12d == g_pScavengeMode", g_pScavengeMode);
		PrintToServer("%12d == g_pItemManagerPtr", g_pItemManager);
		PrintToServer("%12d == g_pMusicBanksPtr", g_pMusicBanks);
		PrintToServer("%12d == g_pSessionManagerPtr", g_pSessionManager);
		PrintToServer("%12d == g_pChallengeModePtr", g_pChallengeMode);
		PrintToServer("%12d == g_pTheNextBots", g_pTheNextBots);
	}
	PrintToServer("");
	#endif
	#endif



	// ====================================================================================================
	//									OFFSETS
	// ====================================================================================================
	#if defined DEBUG
	#if DEBUG
	PrintToServer("Various Offsets:");
	#endif
	#endif

	// Animation offsets
	if( g_bLeft4Dead2 )
	{
		g_iOff_m_PlayerAnimState = hGameData.GetOffset("CTerrorPlayer::m_PlayerAnimState");
		ValidateOffset(g_iOff_m_PlayerAnimState, "CTerrorPlayer::m_PlayerAnimState");

		g_iOff_m_eCurrentMainSequenceActivity = hGameData.GetOffset("CMultiPlayerAnimState::m_eCurrentMainSequenceActivity");
		ValidateOffset(g_iOff_m_eCurrentMainSequenceActivity, "CMultiPlayerAnimState::m_eCurrentMainSequenceActivity");

		g_iOff_m_bIsCustomSequence = hGameData.GetOffset("CTerrorPlayerAnimState::m_bIsCustomSequence");
		ValidateOffset(g_iOff_m_bIsCustomSequence, "CTerrorPlayerAnimState::m_bIsCustomSequence");
	}



	// Various offsets
	g_iOff_m_iCampaignScores = hGameData.GetOffset("m_iCampaignScores");
	ValidateOffset(g_iOff_m_iCampaignScores, "m_iCampaignScores");

	g_iOff_m_iCampaignScores2 = hGameData.GetOffset("m_iCampaignScores2");
	ValidateOffset(g_iOff_m_iCampaignScores2, "m_iCampaignScores2");

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

		g_iOff_m_bInIntro = hGameData.GetOffset("m_bInIntro");
		ValidateOffset(g_iOff_m_bInIntro, "m_bInIntro");
	}
	else
	{
		g_iOff_m_nFirstClassIndex = hGameData.GetOffset("CDirector::m_nFirstClassIndex");
		ValidateOffset(g_iOff_m_nFirstClassIndex, "CDirector::m_nFirstClassIndex");

		g_iOff_m_iSetupNotifyTime = hGameData.GetOffset("CDirectorSurvivalMode::m_iSetupNotifyTime");
		ValidateOffset(g_iOff_m_iSetupNotifyTime, "CDirectorSurvivalMode::m_iSetupNotifyTime");
	}

	g_iOff_Intensity = hGameData.GetOffset("m_intensity");
	ValidateOffset(g_iOff_Intensity, "m_intensity");

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
		LogError("CTerrorPlayer::CanBecomeGhost patch: byte mismatch. %X (%s)", LoadFromAddress(g_pCTerrorPlayer_CanBecomeGhost + view_as<Address>(g_iCanBecomeGhostOffset), NumberType_Int8), g_sSystem);
	}
	// ====================



	// ====================
	// Patch to allow "L4D_RespawnPlayer" to not reset stats
	// ====================
	// Address to function
	g_pCTerrorPlayer_RoundRespawn = hGameData.GetAddress("CTerrorPlayer::RoundRespawn::Address");
	ValidateAddress(g_pCTerrorPlayer_RoundRespawn, "CTerrorPlayer::RoundRespawn::Address", true);

	// Offset to patch
	g_iOff_RespawnPlayer = hGameData.GetOffset("CTerrorPlayer::RoundRespawn::Offset");
	ValidateOffset(g_iOff_RespawnPlayer, "CTerrorPlayer::RoundRespawn::Offset");

	// Patch count and byte match
	g_iByte_RespawnPlayer = hGameData.GetOffset("CTerrorPlayer::RoundRespawn::Bytes");
	g_iSize_RespawnPlayer = hGameData.GetOffset("CTerrorPlayer::RoundRespawn::Count");
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
		L4D2CountdownTimer_Offsets[9] = hGameData.GetOffset("L4D2CountdownTimer_SurvivalSetupTimer") + g_pSurvivalMode;
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
	L4D2IntWeapon_Offsets[6] = hGameData.GetOffset("L4D2IntWeapon_Type");
	L4D2IntWeapon_Offsets[7] = hGameData.GetOffset("L4D2IntWeapon_AmmoType");
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
	PrintToServer("m_iCampaignScores2 = %d", g_iOff_m_iCampaignScores2);
	PrintToServer("m_fTankSpawnFlowPercent = %d", g_iOff_m_fTankSpawnFlowPercent);
	PrintToServer("m_fWitchSpawnFlowPercent = %d", g_iOff_m_fWitchSpawnFlowPercent);
	PrintToServer("m_iTankPassedCount = %d", g_iOff_m_iTankPassedCount);
	PrintToServer("m_bTankThisRound = %d", g_iOff_m_bTankThisRound);
	PrintToServer("m_bWitchThisRound = %d", g_iOff_m_bWitchThisRound);
	PrintToServer("InvulnerabilityTimer = %d", g_iOff_InvulnerabilityTimer);
	PrintToServer("m_iTankTickets = %d", g_iOff_m_iTankTickets);
	PrintToServer("m_intensity = %d", g_iOff_Intensity);
	PrintToServer("m_flow = %d", g_iOff_m_flow);
	PrintToServer("m_chapter = %d", g_iOff_m_chapter);
	PrintToServer("m_PendingMobCount = %d", g_iOff_m_PendingMobCount);
	PrintToServer("m_fMapMaxFlowDistance = %d", g_iOff_m_fMapMaxFlowDistance);
	PrintToServer("m_rescueCheckTimer = %d", g_iOff_m_rescueCheckTimer);
	PrintToServer("VersusMaxCompletionScore = %d", g_iOff_VersusMaxCompletionScore);
	PrintToServer("m_iTankCount = %d", g_iOff_m_iTankCount);
	PrintToServer("MobSpawnTimer = %d", g_iOff_MobSpawnTimer);
	PrintToServer("SetupNotifyTime = %d", g_iOff_m_iSetupNotifyTime);

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
		PrintToServer("g_iOff_m_PlayerAnimState = %d", g_iOff_m_PlayerAnimState);
		PrintToServer("g_iOff_m_eCurrentMainSequenceActivity = %d", g_iOff_m_eCurrentMainSequenceActivity);
		PrintToServer("g_iOff_m_bIsCustomSequence = %d", g_iOff_m_bIsCustomSequence);
		PrintToServer("");
	}
	else
	{
		PrintToServer("m_bInIntro = %d", g_iOff_m_bInIntro);
	}
	#endif
	#endif



	// ====================================================================================================
	//									END
	// ====================================================================================================
	g_hGameData = hGameData;
	g_hTempGameData = hTempGameData;
}