/*
*	Left 4 DHooks Direct
*	Copyright (C) 2024 Silvers
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



void SetupForwardsNatives()
{
	// ====================================================================================================
	//									FORWARDS
	// ====================================================================================================
	// FORWARDS
	// List should match the CreateDetour list of forwards.
	g_hFWD_GameModeChange													= new GlobalForward("L4D_OnGameModeChange",								ET_Event, Param_Cell);
	g_hFWD_ZombieManager_SpawnSpecial										= new GlobalForward("L4D_OnSpawnSpecial",								ET_Event, Param_CellByRef, Param_Array, Param_Array);
	g_hFWD_ZombieManager_SpawnSpecial_Post									= new GlobalForward("L4D_OnSpawnSpecial_Post",							ET_Event, Param_Cell, Param_Cell, Param_Array, Param_Array);
	g_hFWD_ZombieManager_SpawnSpecial_PostHandled							= new GlobalForward("L4D_OnSpawnSpecial_PostHandled",					ET_Event, Param_Cell, Param_Cell, Param_Array, Param_Array);
	g_hFWD_ZombieManager_SpawnTank											= new GlobalForward("L4D_OnSpawnTank",									ET_Event, Param_Array, Param_Array);
	g_hFWD_ZombieManager_SpawnTank_Post										= new GlobalForward("L4D_OnSpawnTank_Post",								ET_Event, Param_Cell, Param_Array, Param_Array);
	g_hFWD_ZombieManager_SpawnTank_PostHandled								= new GlobalForward("L4D_OnSpawnTank_PostHandled",						ET_Event, Param_Cell, Param_Array, Param_Array);
	g_hFWD_ZombieManager_SpawnWitch											= new GlobalForward("L4D_OnSpawnWitch",									ET_Event, Param_Array, Param_Array);
	g_hFWD_ZombieManager_SpawnWitch_Post									= new GlobalForward("L4D_OnSpawnWitch_Post",							ET_Event, Param_Cell, Param_Array, Param_Array);
	g_hFWD_ZombieManager_SpawnWitch_PostHandled								= new GlobalForward("L4D_OnSpawnWitch_PostHandled",						ET_Event, Param_Cell, Param_Array, Param_Array);
	g_hFWD_CDirector_MobRushStart											= new GlobalForward("L4D_OnMobRushStart",								ET_Event);
	g_hFWD_CDirector_MobRushStart_Post										= new GlobalForward("L4D_OnMobRushStart_Post",							ET_Event);
	g_hFWD_CDirector_MobRushStart_PostHandled								= new GlobalForward("L4D_OnMobRushStart_PostHandled",					ET_Event);
	g_hFWD_ZombieManager_SpawnITMob											= new GlobalForward("L4D_OnSpawnITMob",									ET_Event, Param_CellByRef);
	g_hFWD_ZombieManager_SpawnITMob_Post									= new GlobalForward("L4D_OnSpawnITMob_Post",							ET_Event, Param_Cell);
	g_hFWD_ZombieManager_SpawnITMob_PostHandled								= new GlobalForward("L4D_OnSpawnITMob_PostHandled",						ET_Event, Param_Cell);
	g_hFWD_ZombieManager_SpawnMob											= new GlobalForward("L4D_OnSpawnMob",									ET_Event, Param_CellByRef);
	g_hFWD_ZombieManager_SpawnMob_Post										= new GlobalForward("L4D_OnSpawnMob_Post",								ET_Event, Param_Cell);
	g_hFWD_ZombieManager_SpawnMob_PostHandled								= new GlobalForward("L4D_OnSpawnMob_PostHandled",						ET_Event, Param_Cell);
	g_hFWD_CTerrorPlayer_EnterGhostState_Pre								= new GlobalForward("L4D_OnEnterGhostStatePre",							ET_Event, Param_Cell);
	g_hFWD_CTerrorPlayer_EnterGhostState_Post								= new GlobalForward("L4D_OnEnterGhostState",							ET_Event, Param_Cell);
	g_hFWD_CTerrorPlayer_EnterGhostState_PostHandled						= new GlobalForward("L4D_OnEnterGhostState_PostHandled",				ET_Event, Param_Cell);
	g_hFWD_CTerrorPlayer_TakeOverBot_Pre									= new GlobalForward("L4D_OnTakeOverBot",								ET_Event, Param_Cell);
	g_hFWD_CTerrorPlayer_TakeOverBot_Post									= new GlobalForward("L4D_OnTakeOverBot_Post",							ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CTerrorPlayer_TakeOverBot_PostHandled							= new GlobalForward("L4D_OnTakeOverBot_PostHandled",					ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CDirector_IsTeamFull												= new GlobalForward("L4D_OnIsTeamFull",									ET_Event, Param_Cell, Param_CellByRef);
	g_hFWD_CTerrorGameRules_ClearTeamScores									= new GlobalForward("L4D_OnClearTeamScores",							ET_Event, Param_Cell);
	g_hFWD_CTerrorGameRules_SetCampaignScores								= new GlobalForward("L4D_OnSetCampaignScores",							ET_Event, Param_CellByRef, Param_CellByRef);
	g_hFWD_CTerrorGameRules_SetCampaignScores_Post							= new GlobalForward("L4D_OnSetCampaignScores_Post",						ET_Event, Param_Cell, Param_Cell);
	if( !g_bLeft4Dead2 )
	{
		g_hFWD_CTerrorPlayer_RecalculateVersusScore							= new GlobalForward("L4D_OnRecalculateVersusScore",						ET_Event, Param_Cell);
		g_hFWD_CTerrorPlayer_RecalculateVersusScore_Post					= new GlobalForward("L4D_OnRecalculateVersusScore_Post",				ET_Event, Param_Cell);
	}
	g_hFWD_CDirector_OnFirstSurvivorLeftSafeArea							= new GlobalForward("L4D_OnFirstSurvivorLeftSafeArea",					ET_Event, Param_Cell);
	g_hFWD_CDirector_OnFirstSurvivorLeftSafeArea_Post						= new GlobalForward("L4D_OnFirstSurvivorLeftSafeArea_Post",				ET_Event, Param_Cell);
	g_hFWD_CDirector_OnFirstSurvivorLeftSafeArea_PostHandled				= new GlobalForward("L4D_OnFirstSurvivorLeftSafeArea_PostHandled",		ET_Event, Param_Cell);
	g_hFWD_CDirector_OnForceSurvivorPositions_Pre							= new GlobalForward("L4D_OnForceSurvivorPositions_Pre",					ET_Event);
	g_hFWD_CDirector_OnForceSurvivorPositions								= new GlobalForward("L4D_OnForceSurvivorPositions",						ET_Event);
	g_hFWD_CDirector_OnReleaseSurvivorPositions								= new GlobalForward("L4D_OnReleaseSurvivorPositions",					ET_Event);
	g_hFWD_SpeakResponseConceptFromEntityIO_Pre								= new GlobalForward("L4D_OnSpeakResponseConcept_Pre",					ET_Event, Param_Cell);
	g_hFWD_SpeakResponseConceptFromEntityIO_Post							= new GlobalForward("L4D_OnSpeakResponseConcept_Post",					ET_Event, Param_Cell);
	g_hFWD_CTerrorPlayer_GetCrouchTopSpeed									= new GlobalForward("L4D_OnGetCrouchTopSpeed",							ET_Event, Param_Cell, Param_FloatByRef);
	g_hFWD_CTerrorPlayer_GetRunTopSpeed										= new GlobalForward("L4D_OnGetRunTopSpeed",								ET_Event, Param_Cell, Param_FloatByRef);
	g_hFWD_CTerrorPlayer_GetWalkTopSpeed									= new GlobalForward("L4D_OnGetWalkTopSpeed",							ET_Event, Param_Cell, Param_FloatByRef);
	g_hFWD_GetMissionVSBossSpawning											= new GlobalForward("L4D_OnGetMissionVSBossSpawning",					ET_Event, Param_FloatByRef, Param_FloatByRef, Param_FloatByRef, Param_FloatByRef);
	g_hFWD_GetMissionVSBossSpawning_Post									= new GlobalForward("L4D_OnGetMissionVSBossSpawning_Post",				ET_Event, Param_Float, Param_Float, Param_Float, Param_Float);
	g_hFWD_GetMissionVSBossSpawning_PostHandled								= new GlobalForward("L4D_OnGetMissionVSBossSpawning_PostHandled",		ET_Event, Param_Float, Param_Float, Param_Float, Param_Float);
	g_hFWD_ZombieManager_ReplaceTank										= new GlobalForward("L4D_OnReplaceTank",								ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CTankClaw_DoSwing_Pre											= new GlobalForward("L4D_TankClaw_DoSwing_Pre",							ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CTankClaw_DoSwing_Post											= new GlobalForward("L4D_TankClaw_DoSwing_Post",						ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CTankClaw_GroundPound_Pre										= new GlobalForward("L4D_TankClaw_GroundPound_Pre",						ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CTankClaw_GroundPound_Post										= new GlobalForward("L4D_TankClaw_GroundPound_Post",					ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CTankClaw_OnPlayerHit_Pre										= new GlobalForward("L4D_TankClaw_OnPlayerHit_Pre",						ET_Event, Param_Cell, Param_Cell, Param_Cell);
	g_hFWD_CTankClaw_OnPlayerHit_Post										= new GlobalForward("L4D_TankClaw_OnPlayerHit_Post",					ET_Event, Param_Cell, Param_Cell, Param_Cell);
	g_hFWD_CTankClaw_OnPlayerHit_PostHandled								= new GlobalForward("L4D_TankClaw_OnPlayerHit_PostHandled",				ET_Event, Param_Cell, Param_Cell, Param_Cell);
	g_hFWD_CTankRock_Detonate												= new GlobalForward("L4D_TankRock_OnDetonate",							ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CTankRock_OnRelease												= new GlobalForward("L4D_TankRock_OnRelease",							ET_Event, Param_Cell, Param_Cell, Param_Array, Param_Array, Param_Array, Param_Array);
	g_hFWD_CTankRock_OnRelease_Post											= new GlobalForward("L4D_TankRock_OnRelease_Post",						ET_Event, Param_Cell, Param_Cell, Param_Array, Param_Array, Param_Array, Param_Array);
	g_hFWD_CTankRock_BounceTouch											= new GlobalForward("L4D_TankRock_BounceTouch",							ET_Event, Param_Cell, Param_Cell, Param_Cell);
	g_hFWD_CTankRock_BounceTouch_Post										= new GlobalForward("L4D_TankRock_BounceTouch_Post",					ET_Event, Param_Cell, Param_Cell, Param_Cell);
	g_hFWD_CTankRock_BounceTouch_PostHandled								= new GlobalForward("L4D_TankRock_BounceTouch_PostHandled",				ET_Event, Param_Cell, Param_Cell, Param_Cell);
	g_hFWD_CDirector_TryOfferingTankBot										= new GlobalForward("L4D_OnTryOfferingTankBot",							ET_Event, Param_Cell, Param_CellByRef);
	g_hFWD_CDirector_TryOfferingTankBot_Post								= new GlobalForward("L4D_OnTryOfferingTankBot_Post",					ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CDirector_TryOfferingTankBot_PostHandled							= new GlobalForward("L4D_OnTryOfferingTankBot_PostHandled",				ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CThrow_ActivateAbililty											= new GlobalForward("L4D_OnCThrowActivate",								ET_Event, Param_Cell);
	g_hFWD_CThrow_ActivateAbililty_Post										= new GlobalForward("L4D_OnCThrowActivate_Post",						ET_Event, Param_Cell);
	g_hFWD_CThrow_ActivateAbililty_PostHandled								= new GlobalForward("L4D_OnCThrowActivate_PostHandled",					ET_Event, Param_Cell);
	g_hFWD_CBaseAnimating_SelectWeightedSequence_Pre						= new GlobalForward("L4D2_OnSelectTankAttackPre",						ET_Event, Param_Cell, Param_CellByRef);
	g_hFWD_CBaseAnimating_SelectWeightedSequence_Post						= new GlobalForward("L4D2_OnSelectTankAttack",							ET_Event, Param_Cell, Param_CellByRef);
	g_hFWD_CTerrorPlayer_DoAnimationEvent									= new GlobalForward("L4D_OnDoAnimationEvent",							ET_Event, Param_Cell, Param_CellByRef, Param_CellByRef);
	g_hFWD_CTerrorPlayer_DoAnimationEvent_Post								= new GlobalForward("L4D_OnDoAnimationEvent_Post",						ET_Event, Param_Cell, Param_Cell, Param_Cell);
	g_hFWD_CTerrorPlayer_DoAnimationEvent_PostHandled						= new GlobalForward("L4D_OnDoAnimationEvent_PostHandled",				ET_Event, Param_Cell, Param_Cell, Param_Cell);
	g_hFWD_CDirectorScriptedEventManager_SendInRescueVehicle				= new GlobalForward("L4D2_OnSendInRescueVehicle",						ET_Event);
	g_hFWD_CDirectorVersusMode_EndVersusModeRound_Pre						= new GlobalForward("L4D2_OnEndVersusModeRound",						ET_Event, Param_Cell);
	g_hFWD_CDirectorVersusMode_EndVersusModeRound_Post						= new GlobalForward("L4D2_OnEndVersusModeRound_Post",					ET_Event);
	g_hFWD_CDirectorVersusMode_EndVersusModeRound_PostHandled				= new GlobalForward("L4D2_OnEndVersusModeRound_PostHandled",			ET_Event);
	g_hFWD_CServerGameDLL_ServerHibernationUpdate							= new GlobalForward("L4D_OnServerHibernationUpdate",					ET_Event, Param_Cell);
	g_hFWD_CTerrorPlayer_OnLedgeGrabbed										= new GlobalForward("L4D_OnLedgeGrabbed",								ET_Event, Param_Cell);
	g_hFWD_CTerrorPlayer_OnLedgeGrabbed_Post								= new GlobalForward("L4D_OnLedgeGrabbed_Post",							ET_Event, Param_Cell);
	g_hFWD_CTerrorPlayer_OnLedgeGrabbed_PostHandled							= new GlobalForward("L4D_OnLedgeGrabbed_PostHandled",					ET_Event, Param_Cell);
	g_hFWD_CTerrorPlayer_OnRevived_Post										= new GlobalForward("L4D2_OnRevived",									ET_Event, Param_Cell);
	g_hFWD_CTerrorPlayer_OnStaggered										= new GlobalForward("L4D2_OnStagger",									ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CTerrorPlayer_OnStaggered_Post									= new GlobalForward("L4D2_OnStagger_Post",								ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CTerrorPlayer_OnStaggered_PostHandled							= new GlobalForward("L4D2_OnStagger_PostHandled",						ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CTerrorWeapon_OnSwingStart										= new GlobalForward("L4D_OnSwingStart",									ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CTerrorPlayer_OnShovedBySurvivor									= new GlobalForward("L4D_OnShovedBySurvivor",							ET_Event, Param_Cell, Param_Cell, Param_Array);
	g_hFWD_CTerrorPlayer_OnShovedBySurvivor_Post							= new GlobalForward("L4D_OnShovedBySurvivor_Post",						ET_Event, Param_Cell, Param_Cell, Param_Array);
	g_hFWD_CTerrorPlayer_OnShovedBySurvivor_PostHandled						= new GlobalForward("L4D_OnShovedBySurvivor_PostHandled",				ET_Event, Param_Cell, Param_Cell, Param_Array);
	g_hFWD_CTerrorWeapon_OnHit												= new GlobalForward("L4D2_OnEntityShoved",								ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_Array, Param_Cell);
	g_hFWD_CTerrorWeapon_OnHit_Post											= new GlobalForward("L4D2_OnEntityShoved_Post",							ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_Array, Param_Cell);
	g_hFWD_CTerrorWeapon_OnHit_PostHandled									= new GlobalForward("L4D2_OnEntityShoved_PostHandled",					ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_Array, Param_Cell);
	g_hFWD_CTerrorPlayer_OnShovedByPounceLanding							= new GlobalForward("L4D2_OnPounceOrLeapStumble",						ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CTerrorPlayer_OnShovedByPounceLanding_Post						= new GlobalForward("L4D2_OnPounceOrLeapStumble_Post",					ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CTerrorPlayer_OnShovedByPounceLanding_PostHandled				= new GlobalForward("L4D2_OnPounceOrLeapStumble_PostHandled",			ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CTerrorPlayer_OnKnockedDown										= new GlobalForward("L4D_OnKnockedDown",								ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CTerrorPlayer_OnKnockedDown_Post									= new GlobalForward("L4D_OnKnockedDown_Post",							ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CTerrorPlayer_OnKnockedDown_PostHandled							= new GlobalForward("L4D_OnKnockedDown_PostHandled",					ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CTerrorPlayer_OnSlammedSurvivor									= new GlobalForward("L4D2_OnSlammedSurvivor",							ET_Event, Param_Cell, Param_Cell, Param_CellByRef, Param_CellByRef);
	g_hFWD_CTerrorPlayer_OnSlammedSurvivor_Post								= new GlobalForward("L4D2_OnSlammedSurvivor_Post",						ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	g_hFWD_CTerrorPlayer_OnSlammedSurvivor_PostHandled						= new GlobalForward("L4D2_OnSlammedSurvivor_PostHandled",				ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	g_hFWD_CTerrorPlayer_QueuePummelVictim									= new GlobalForward("L4D2_OnPummelVictim",								ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CTerrorPlayer_QueuePummelVictim_Post								= new GlobalForward("L4D2_OnPummelVictim_Post",							ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CTerrorPlayer_QueuePummelVictim_PostHandled						= new GlobalForward("L4D2_OnPummelVictim_PostHandled",					ET_Event, Param_Cell, Param_Cell);
	g_hFWD_ThrowImpactedSurvivor											= new GlobalForward("L4D2_OnThrowImpactedSurvivor",						ET_Event, Param_Cell, Param_Cell);
	g_hFWD_ThrowImpactedSurvivor_Post										= new GlobalForward("L4D2_OnThrowImpactedSurvivor_Post",				ET_Event, Param_Cell, Param_Cell);
	g_hFWD_ThrowImpactedSurvivor_PostHandled								= new GlobalForward("L4D2_OnThrowImpactedSurvivor_PostHandled",			ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CTerrorPlayer_CancelStagger										= new GlobalForward("L4D_OnCancelStagger",								ET_Event, Param_Cell);
	g_hFWD_CTerrorPlayer_CancelStagger_Post									= new GlobalForward("L4D_OnCancelStagger_Post",							ET_Event, Param_Cell);
	g_hFWD_CTerrorPlayer_CancelStagger_PostHandled							= new GlobalForward("L4D_OnCancelStagger_PostHandled",					ET_Event, Param_Cell);
	g_hFWD_CTerrorPlayer_Fling												= new GlobalForward("L4D2_OnPlayerFling",								ET_Event, Param_Cell, Param_Cell, Param_Array);
	g_hFWD_CTerrorPlayer_Fling_Post											= new GlobalForward("L4D2_OnPlayerFling_Post",							ET_Event, Param_Cell, Param_Cell, Param_Array);
	g_hFWD_CTerrorPlayer_Fling_PostHandled									= new GlobalForward("L4D2_OnPlayerFling_PostHandled",					ET_Event, Param_Cell, Param_Cell, Param_Array);
	g_hFWD_CTerrorPlayer_IsMotionControlledXY								= new GlobalForward("L4D_OnMotionControlledXY",							ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CDeathFallCamera_Enable											= new GlobalForward("L4D_OnFatalFalling",								ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CTerrorPlayer_OnFalling_Post										= new GlobalForward("L4D_OnFalling",									ET_Event, Param_Cell);
	g_hFWD_CTerrorPlayer_Cough												= new GlobalForward("L4D_OnPlayerCough",								ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CTerrorPlayer_Cough_Post											= new GlobalForward("L4D_OnPlayerCough_Post",							ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CTerrorPlayer_Cough_PostHandled									= new GlobalForward("L4D_OnPlayerCough_PostHandled",					ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CTerrorPlayer_OnIncapacitatedAsSurvivor							= new GlobalForward("L4D_OnIncapacitated",								ET_Event, Param_Cell, Param_CellByRef, Param_CellByRef, Param_FloatByRef, Param_CellByRef);
	g_hFWD_CTerrorPlayer_OnIncapacitatedAsSurvivor_Post						= new GlobalForward("L4D_OnIncapacitated_Post",							ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_Float, Param_Cell);
	g_hFWD_CTerrorPlayer_OnIncapacitatedAsSurvivor_PostHandled				= new GlobalForward("L4D_OnIncapacitated_PostHandled",					ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_Float, Param_Cell);
	g_hFWD_Witch_SetHarasser												= new GlobalForward("L4D_OnWitchSetHarasser",							ET_Event, Param_Cell, Param_Cell);
	g_hFWD_Tank_EnterStasis_Post											= new GlobalForward("L4D_OnEnterStasis",								ET_Event, Param_Cell);
	g_hFWD_Tank_LeaveStasis_Post											= new GlobalForward("L4D_OnLeaveStasis",								ET_Event, Param_Cell);
	g_hFWD_CTerrorPlayer_DropWeapons										= new GlobalForward("L4D_OnDeathDroppedWeapons",						ET_Event, Param_Cell, Param_Array);
	g_hFWD_CInferno_Spread													= new GlobalForward("L4D2_OnSpitSpread",								ET_Event, Param_Cell, Param_Cell, Param_FloatByRef, Param_FloatByRef, Param_FloatByRef);
	g_hFWD_SurvivorBot_UseHealingItems										= new GlobalForward("L4D2_OnUseHealingItems",							ET_Event, Param_Cell);
	g_hFWD_SurvivorBot_FindScavengeItem_Post								= new GlobalForward("L4D2_OnFindScavengeItem",							ET_Event, Param_Cell, Param_CellByRef);
	// g_hFWD_BossZombiePlayerBot_ChooseVictim_Pre								= new GlobalForward("L4D2_OnChooseVictim_Pre",							ET_Event, Param_Cell, Param_CellByRef, Param_CellByRef, Param_CellByRef, Param_CellByRef); // For a future update
	g_hFWD_BossZombiePlayerBot_ChooseVictim_Pre								= new GlobalForward("L4D2_OnChooseVictim_Pre",							ET_Event, Param_Cell, Param_CellByRef);
	g_hFWD_BossZombiePlayerBot_ChooseVictim_Post							= new GlobalForward("L4D2_OnChooseVictim",								ET_Event, Param_Cell, Param_CellByRef);
	g_hFWD_CTerrorPlayer_MaterializeFromGhost_Pre							= new GlobalForward("L4D_OnMaterializeFromGhostPre",					ET_Event, Param_Cell);
	g_hFWD_CTerrorPlayer_MaterializeFromGhost_Post							= new GlobalForward("L4D_OnMaterializeFromGhost",						ET_Event, Param_Cell);
	g_hFWD_CTerrorPlayer_MaterializeFromGhost_PostHandled					= new GlobalForward("L4D_OnMaterializeFromGhost_PostHandled",			ET_Event, Param_Cell);
	g_hFWD_CTerrorPlayer_OnVomitedUpon										= new GlobalForward("L4D_OnVomitedUpon",								ET_Event, Param_Cell, Param_CellByRef, Param_CellByRef);
	g_hFWD_CTerrorPlayer_OnVomitedUpon_Post									= new GlobalForward("L4D_OnVomitedUpon_Post",							ET_Event, Param_Cell, Param_Cell, Param_Cell);
	g_hFWD_CTerrorPlayer_OnVomitedUpon_PostHandled							= new GlobalForward("L4D_OnVomitedUpon_PostHandled",					ET_Event, Param_Cell, Param_Cell, Param_Cell);
	g_hFWD_CMolotovProjectile_Create_Pre									= new GlobalForward("L4D_MolotovProjectile_Pre",						ET_Event, Param_Cell, Param_Array, Param_Array, Param_Array, Param_Array);
	g_hFWD_CMolotovProjectile_Create_Post									= new GlobalForward("L4D_MolotovProjectile_Post",						ET_Event, Param_Cell, Param_Cell, Param_Array, Param_Array, Param_Array, Param_Array);
	g_hFWD_CMolotovProjectile_Create_PostHandled							= new GlobalForward("L4D_MolotovProjectile_PostHandled",				ET_Event, Param_Cell, Param_Cell, Param_Array, Param_Array, Param_Array, Param_Array);
	g_hFWD_CMolotovProjectile_Detonate										= new GlobalForward("L4D_Molotov_Detonate",								ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CMolotovProjectile_Detonate_Post									= new GlobalForward("L4D_Molotov_Detonate_Post",						ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CMolotovProjectile_Detonate_PostHandled							= new GlobalForward("L4D_Molotov_Detonate_PostHandled",					ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CPipeBombProjectile_Create_Pre									= new GlobalForward("L4D_PipeBombProjectile_Pre",						ET_Event, Param_Cell, Param_Array, Param_Array, Param_Array, Param_Array);
	g_hFWD_CPipeBombProjectile_Create_Post									= new GlobalForward("L4D_PipeBombProjectile_Post",						ET_Event, Param_Cell, Param_Cell, Param_Array, Param_Array, Param_Array, Param_Array);
	g_hFWD_CPipeBombProjectile_Create_PostHandled							= new GlobalForward("L4D_PipeBombProjectile_PostHandled",				ET_Event, Param_Cell, Param_Cell, Param_Array, Param_Array, Param_Array, Param_Array);
	g_hFWD_CPipeBombProjectile_Detonate										= new GlobalForward("L4D_PipeBomb_Detonate",							ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CPipeBombProjectile_Detonate_Post								= new GlobalForward("L4D_PipeBomb_Detonate_Post",						ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CPipeBombProjectile_Detonate_PostHandled							= new GlobalForward("L4D_PipeBomb_Detonate_PostHandled",				ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CTerrorPlayer_Extinguish											= new GlobalForward("L4D_PlayerExtinguish",								ET_Event, Param_Cell);
	g_hFWD_CTerrorPlayer_OnPouncedOnSurvivor								= new GlobalForward("L4D_OnPouncedOnSurvivor",							ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CTerrorPlayer_OnPouncedOnSurvivor_Post							= new GlobalForward("L4D_OnPouncedOnSurvivor_Post",						ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CTerrorPlayer_OnPouncedOnSurvivor_PostHandled					= new GlobalForward("L4D_OnPouncedOnSurvivor_PostHandled",				ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CTerrorPlayer_GrabVictimWithTongue								= new GlobalForward("L4D_OnGrabWithTongue",								ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CTerrorPlayer_GrabVictimWithTongue_Post							= new GlobalForward("L4D_OnGrabWithTongue_Post",						ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CTerrorPlayer_GrabVictimWithTongue_PostHandled					= new GlobalForward("L4D_OnGrabWithTongue_PostHandled",					ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CBreakableProp_Break_Post										= new GlobalForward("L4D_CBreakableProp_Break",							ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CFirstAidKit_StartHealing										= new GlobalForward("L4D1_FirstAidKit_StartHealing",					ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CFirstAidKit_StartHealing_Post									= new GlobalForward("L4D1_FirstAidKit_StartHealing_Post",				ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CFirstAidKit_StartHealing_PostHandled							= new GlobalForward("L4D1_FirstAidKit_StartHealing_PostHandled",		ET_Event, Param_Cell, Param_Cell);
	// g_hFWD_GetRandomPZSpawnPos												= new GlobalForward("L4D_OnGetRandomPZSpawnPosition",					ET_Event, Param_CellByRef, Param_CellByRef, Param_CellByRef, Param_Array);
	// g_hFWD_InfectedShoved													= new GlobalForward("L4D_OnInfectedShoved",								ET_Event, Param_Cell, Param_Cell);
	// g_hFWD_OnWaterMove														= new GlobalForward("L4D2_OnWaterMove",									ET_Event, Param_Cell);

	if( g_bLeft4Dead2 )
	{
		g_hFWD_CVomitJarProjectile_Create_Pre								= new GlobalForward("L4D2_VomitJarProjectile_Pre",						ET_Event, Param_Cell, Param_Array, Param_Array, Param_Array, Param_Array);
		g_hFWD_CVomitJarProjectile_Create_Post								= new GlobalForward("L4D2_VomitJarProjectile_Post",						ET_Event, Param_Cell, Param_Cell, Param_Array, Param_Array, Param_Array, Param_Array);
		g_hFWD_CVomitJarProjectile_Create_PostHandled						= new GlobalForward("L4D2_VomitJarProjectile_PostHandled",				ET_Event, Param_Cell, Param_Cell, Param_Array, Param_Array, Param_Array, Param_Array);
		g_hFWD_CGrenadeLauncherProjectile_Create_Pre						= new GlobalForward("L4D2_GrenadeLauncherProjectile_Pre",				ET_Event, Param_Cell, Param_Array, Param_Array, Param_Array, Param_Array, Param_CellByRef);
		g_hFWD_CGrenadeLauncherProjectile_Create_Post						= new GlobalForward("L4D2_GrenadeLauncherProjectile_Post",				ET_Event, Param_Cell, Param_Cell, Param_Array, Param_Array, Param_Array, Param_Array, Param_Cell);
		g_hFWD_CGrenadeLauncherProjectile_Create_PostHandled				= new GlobalForward("L4D2_GrenadeLauncherProjectile_PostHandled",		ET_Event, Param_Cell, Param_Cell, Param_Array, Param_Array, Param_Array, Param_Array, Param_Cell);
		g_hFWD_CVomitJarProjectile_Detonate									= new GlobalForward("L4D2_VomitJar_Detonate",							ET_Event, Param_Cell, Param_Cell);
		g_hFWD_CVomitJarProjectile_Detonate_Post							= new GlobalForward("L4D2_VomitJar_Detonate_Post",						ET_Event, Param_Cell, Param_Cell);
		g_hFWD_CVomitJarProjectile_Detonate_PostHandled						= new GlobalForward("L4D2_VomitJar_Detonate_PostHandled",				ET_Event, Param_Cell, Param_Cell);
		g_hFWD_CGrenadeLauncher_Projectile_Explode							= new GlobalForward("L4D2_GrenadeLauncher_Detonate",					ET_Event, Param_Cell, Param_Cell, Param_CellByRef);
		g_hFWD_CGrenadeLauncher_Projectile_Explode_Post						= new GlobalForward("L4D2_GrenadeLauncher_Detonate_Post",				ET_Event, Param_Cell, Param_Cell, Param_Cell);
		g_hFWD_CGrenadeLauncher_Projectile_Explode_PostHandled				= new GlobalForward("L4D2_GrenadeLauncher_Detonate_PostHandled",		ET_Event, Param_Cell, Param_Cell, Param_Cell);
		g_hFWD_ZombieManager_SpawnWitchBride								= new GlobalForward("L4D2_OnSpawnWitchBride",							ET_Event, Param_Array, Param_Array);
		g_hFWD_ZombieManager_SpawnWitchBride_Post							= new GlobalForward("L4D2_OnSpawnWitchBride_Post",						ET_Event, Param_Cell, Param_Array, Param_Array);
		g_hFWD_ZombieManager_SpawnWitchBride_PostHandled					= new GlobalForward("L4D2_OnSpawnWitchBride_PostHandled",				ET_Event, Param_Cell, Param_Array, Param_Array);
		g_hFWD_CTerrorPlayer_OnLeptOnSurvivor								= new GlobalForward("L4D2_OnJockeyRide",								ET_Event, Param_Cell, Param_Cell);
		g_hFWD_CTerrorPlayer_OnLeptOnSurvivor_Post							= new GlobalForward("L4D2_OnJockeyRide_Post",							ET_Event, Param_Cell, Param_Cell);
		g_hFWD_CTerrorPlayer_OnLeptOnSurvivor_PostHandled					= new GlobalForward("L4D2_OnJockeyRide_PostHandled",					ET_Event, Param_Cell, Param_Cell);
		g_hFWD_CTerrorPlayer_OnStartCarryingVictim							= new GlobalForward("L4D2_OnStartCarryingVictim",						ET_Event, Param_Cell, Param_Cell);
		g_hFWD_CTerrorPlayer_OnStartCarryingVictim_Post						= new GlobalForward("L4D2_OnStartCarryingVictim_Post",					ET_Event, Param_Cell, Param_Cell);
		g_hFWD_CTerrorPlayer_OnStartCarryingVictim_PostHandled				= new GlobalForward("L4D2_OnStartCarryingVictim_PostHandled",			ET_Event, Param_Cell, Param_Cell);
		g_hFWD_CCharge_ImpactStagger										= new GlobalForward("L4D2_OnChargerImpact",								ET_Event, Param_Cell);
		g_hFWD_CGasCanEvent_Killed											= new GlobalForward("L4D2_CGasCan_EventKilled",							ET_Event, Param_Cell, Param_CellByRef, Param_CellByRef);
		g_hFWD_CGasCanEvent_Killed_Post										= new GlobalForward("L4D2_CGasCan_EventKilled_Post",					ET_Event, Param_Cell, Param_Cell, Param_Cell);
		g_hFWD_CGasCanEvent_Killed_PostHandled								= new GlobalForward("L4D2_CGasCan_EventKilled_PostHandled",				ET_Event, Param_Cell, Param_Cell, Param_Cell);
		g_hFWD_CGasCan_ShouldStartAction									= new GlobalForward("L4D2_CGasCan_ShouldStartAction",					ET_Event, Param_Cell, Param_Cell, Param_Cell);
		g_hFWD_CGasCan_ShouldStartAction_Post								= new GlobalForward("L4D2_CGasCan_ShouldStartAction_Post",				ET_Event, Param_Cell, Param_Cell, Param_Cell);
		g_hFWD_CGasCan_ShouldStartAction_PostHandled						= new GlobalForward("L4D2_CGasCan_ShouldStartAction_PostHandled",		ET_Event, Param_Cell, Param_Cell, Param_Cell);
		g_hFWD_CTerrorPlayer_StartUseAction									= new GlobalForward("L4D2_OnStartUseAction",							ET_Event, Param_Cell, Param_Cell, Param_Cell);
		g_hFWD_CTerrorPlayer_StartUseAction_Post							= new GlobalForward("L4D2_OnStartUseAction_Post",						ET_Event, Param_Cell, Param_Cell, Param_Cell);
		g_hFWD_CTerrorPlayer_StartUseAction_PostHandled						= new GlobalForward("L4D2_OnStartUseAction_PostHandled",				ET_Event, Param_Cell, Param_Cell, Param_Cell);
		g_hFWD_CBaseBackpackItem_StartAction								= new GlobalForward("L4D2_BackpackItem_StartAction",					ET_Event, Param_Cell, Param_Cell, Param_Cell);
		g_hFWD_CBaseBackpackItem_StartAction_Post							= new GlobalForward("L4D2_BackpackItem_StartAction_Post",				ET_Event, Param_Cell, Param_Cell, Param_Cell);
		g_hFWD_CBaseBackpackItem_StartAction_PostHandled					= new GlobalForward("L4D2_BackpackItem_StartAction_PostHandled",		ET_Event, Param_Cell, Param_Cell, Param_Cell);
		g_hFWD_CGasCan_OnActionComplete										= new GlobalForward("L4D2_CGasCan_ActionComplete",						ET_Event, Param_Cell, Param_Cell, Param_Cell);
		g_hFWD_CGasCan_OnActionComplete_Post								= new GlobalForward("L4D2_CGasCan_ActionComplete_Post",					ET_Event, Param_Cell, Param_Cell, Param_Cell);
		g_hFWD_CGasCan_OnActionComplete_PostHandled							= new GlobalForward("L4D2_CGasCan_ActionComplete_PostHandled",			ET_Event, Param_Cell, Param_Cell, Param_Cell);
		g_hFWD_CInsectSwarm_CanHarm											= new GlobalForward("L4D2_CInsectSwarm_CanHarm",						ET_Event, Param_Cell, Param_Cell, Param_Cell);
		g_hFWD_CInsectSwarm_CanHarm_Post									= new GlobalForward("L4D2_CInsectSwarm_CanHarm_Post",					ET_Event, Param_Cell, Param_Cell, Param_Cell);
		g_hFWD_CInsectSwarm_CanHarm_PostHandled								= new GlobalForward("L4D2_CInsectSwarm_CanHarm_PostHandled",			ET_Event, Param_Cell, Param_Cell, Param_Cell);
		g_hFWD_CTerrorPlayer_OnHitByVomitJar								= new GlobalForward("L4D2_OnHitByVomitJar",								ET_Event, Param_Cell, Param_CellByRef);
		g_hFWD_CTerrorPlayer_OnHitByVomitJar_Post							= new GlobalForward("L4D2_OnHitByVomitJar_Post",						ET_Event, Param_Cell, Param_Cell);
		g_hFWD_CTerrorPlayer_OnHitByVomitJar_PostHandled					= new GlobalForward("L4D2_OnHitByVomitJar_PostHandled",					ET_Event, Param_Cell, Param_Cell);
		g_hFWD_Infected_OnHitByVomitJar										= new GlobalForward("L4D2_Infected_HitByVomitJar",						ET_Event, Param_Cell, Param_CellByRef);
		g_hFWD_Infected_OnHitByVomitJar_Post								= new GlobalForward("L4D2_Infected_HitByVomitJar_Post",					ET_Event, Param_Cell, Param_Cell);
		g_hFWD_Infected_OnHitByVomitJar_PostHandled							= new GlobalForward("L4D2_Infected_HitByVomitJar_PostHandled",			ET_Event, Param_Cell, Param_Cell);
		g_hFWD_CDirector_GetScriptValueInt									= new GlobalForward("L4D_OnGetScriptValueInt",							ET_Event, Param_String, Param_CellByRef);
		g_hFWD_CDirector_GetScriptValueFloat								= new GlobalForward("L4D_OnGetScriptValueFloat",						ET_Event, Param_String, Param_FloatByRef);
		// g_hFWD_CDirector_GetScriptValueVector								= new GlobalForward("L4D_OnGetScriptValueVector",						ET_Event, Param_String, Param_Array);
		g_hFWD_CDirector_GetScriptValueString								= new GlobalForward("L4D_OnGetScriptValueString",						ET_Event, Param_String, Param_String, Param_String);
		g_hFWD_CSquirrelVM_GetValue_Void									= new GlobalForward("L4D2_OnGetScriptValueVoid",						ET_Event, Param_String, Param_CellByRef, Param_Array, Param_Cell);
		g_hFWD_CSquirrelVM_GetValue_Int										= new GlobalForward("L4D2_OnGetScriptValueInt",							ET_Event, Param_String, Param_CellByRef, Param_Cell);
		g_hFWD_CSquirrelVM_GetValue_Float									= new GlobalForward("L4D2_OnGetScriptValueFloat",						ET_Event, Param_String, Param_FloatByRef, Param_Cell);
		g_hFWD_CSquirrelVM_GetValue_Vector									= new GlobalForward("L4D2_OnGetScriptValueVector",						ET_Event, Param_String, Param_Array, Param_Cell);
		g_hFWD_CTerrorGameRules_HasConfigurableDifficultySetting			= new GlobalForward("L4D_OnHasConfigurableDifficulty",					ET_Event, Param_CellByRef);
		g_hFWD_CTerrorGameRules_HasConfigurableDifficultySetting_Post		= new GlobalForward("L4D_OnHasConfigurableDifficulty_Post",				ET_Event, Param_Cell);
		g_hFWD_CTerrorGameRules_GetSurvivorSet								= new GlobalForward("L4D_OnGetSurvivorSet",								ET_Event, Param_CellByRef);
		g_hFWD_CTerrorGameRules_FastGetSurvivorSet							= new GlobalForward("L4D_OnFastGetSurvivorSet",							ET_Event, Param_CellByRef);
		g_hFWD_StartMeleeSwing												= new GlobalForward("L4D_OnStartMeleeSwing",							ET_Event, Param_Cell, Param_Cell);
		g_hFWD_StartMeleeSwing_Post											= new GlobalForward("L4D_OnStartMeleeSwing_Post",						ET_Event, Param_Cell, Param_Cell);
		g_hFWD_StartMeleeSwing_PostHandled									= new GlobalForward("L4D_OnStartMeleeSwing_PostHandled",				ET_Event, Param_Cell, Param_Cell);
		g_hFWD_GetDamageForVictim											= new GlobalForward("L4D2_MeleeGetDamageForVictim",						ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_FloatByRef);
		g_hFWD_CDirectorScriptedEventManager_ChangeFinaleStage				= new GlobalForward("L4D2_OnChangeFinaleStage",							ET_Event, Param_CellByRef, Param_String);
		g_hFWD_CDirectorScriptedEventManager_ChangeFinaleStage_Post			= new GlobalForward("L4D2_OnChangeFinaleStage_Post",					ET_Event, Param_Cell, Param_String);
		g_hFWD_CDirectorScriptedEventManager_ChangeFinaleStage_PostPost		= new GlobalForward("L4D2_OnChangeFinaleStage_PostHandled",				ET_Event, Param_Cell, Param_String);
		g_hFWD_AddonsDisabler												= new GlobalForward("L4D2_OnClientDisableAddons",						ET_Event, Param_String);
	}



	// ====================================================================================================
	//									NATIVES
	// ====================================================================================================
	PlayerAnimState_CreateNatives();
	AmmoDef_CreateNatives();
	Ammo_t_CreateNatives();



	// ANIMATION HOOK
	CreateNative("AnimHookEnable",		 							Native_AnimHookEnable);
	CreateNative("AnimHookDisable",		 							Native_AnimHookDisable);
	CreateNative("AnimGetActivity",		 							Native_AnimGetActivity);
	CreateNative("AnimGetFromActivity",		 						Native_AnimGetFromActivity);



	// =========================
	// Silvers Natives
	// =========================
	CreateNative("L4D_PrecacheParticle",							Native_PrecacheParticle);
	CreateNative("L4D_RemoveEntityDelay",							Native_RemoveEntityDelay);
	CreateNative("L4D_GetPointer",		 							Native_GetPointer);
	CreateNative("L4D_GetClientFromAddress",		 				Native_GetClientFromAddress);
	CreateNative("L4D_GetEntityFromAddress",		 				Native_GetEntityFromAddress);
	CreateNative("L4D_ReadMemoryString",		 					Native_ReadMemoryString);
	CreateNative("L4D_WriteMemoryString",		 					Native_WriteMemoryString);
	CreateNative("L4D_GetServerOS",		 							Native_GetServerOS);
	CreateNative("Left4DHooks_Version",		 						Native_Left4DHooks_Version);
	CreateNative("L4D_HasMapStarted",		 						Native_HasMapStarted);
	CreateNative("L4D_GetGameModeType",		 						Native_Internal_GetGameMode);
	CreateNative("L4D2_IsGenericCooperativeMode",		 			Native_CTerrorGameRules_IsGenericCooperativeMode);
	CreateNative("L4D_IsCoopMode",		 							Native_Internal_IsCoopMode);
	CreateNative("L4D2_IsRealismMode",		 						Native_Internal_IsRealismMode);
	CreateNative("L4D_IsSurvivalMode",		 						Native_Internal_IsSurvivalMode);
	CreateNative("L4D2_IsScavengeMode",		 						Native_Internal_IsScavengeMode);
	CreateNative("L4D_IsVersusMode",		 						Native_Internal_IsVersusMode);
	CreateNative("L4D2_HasConfigurableDifficultySetting",			Native_CTerrorGameRules_HasConfigurableDifficultySetting);
	CreateNative("L4D2_GetSurvivorSetMap",							Native_CTerrorGameRules_GetSurvivorSetMap);
	CreateNative("L4D2_GetSurvivorSetMod",							Native_CTerrorGameRules_GetSurvivorSetMod);
	CreateNative("L4D_GetTempHealth",								Native_Internal_GetTempHealth);
	CreateNative("L4D_SetTempHealth",								Native_Internal_SetTempHealth);
	CreateNative("L4D_GetReserveAmmo",								Native_Internal_GetReserveAmmo);
	CreateNative("L4D_SetReserveAmmo",								Native_Internal_SetReserveAmmo);
	CreateNative("L4D_PlayMusic",		 							Native_PlayMusic);
	CreateNative("L4D_StopMusic",		 							Native_StopMusic);
	CreateNative("L4D_Deafen",		 								Native_CTerrorPlayer_Deafen);
	CreateNative("L4D_Dissolve",		 							Native_CEntityDissolve_Create);
	CreateNative("L4D_OnITExpired",		 							Native_CTerrorPlayer_OnITExpired);
	CreateNative("L4D_EstimateFallingDamage",		 				Native_CTerrorPlayer_EstimateFallingDamage);
	CreateNative("L4D_GetEntityWorldSpaceCenter",		 			Native_CBaseEntity_WorldSpaceCenter);
	CreateNative("L4D_AngularVelocity",		 						Native_CBaseEntity_ApplyLocalAngularVelocityImpulse);
	CreateNative("L4D_GetRandomPZSpawnPosition",		 			Native_ZombieManager_GetRandomPZSpawnPosition);
	CreateNative("L4D_FindRandomSpot",		 						Native_TerrorNavArea_FindRandomSpot);
	CreateNative("L4D_WarpToValidPositionIfStuck",		 			Native_CTerrorPlayer_WarpToValidPositionIfStuck);
	CreateNative("L4D2_IsVisibleToPlayer",		 					Native_IsVisibleToPlayer);
	CreateNative("L4D_GetNearestNavArea",		 					Native_CNavMesh_GetNearestNavArea);
	CreateNative("L4D_GetLastKnownArea",		 					Native_CTerrorPlayer_GetLastKnownArea);
	CreateNative("L4D_IsTouchingTrigger",		 					Native_CBaseTrigger_IsTouching);
	CreateNative("L4D_HasAnySurvivorLeftSafeArea",		 			Native_CDirector_HasAnySurvivorLeftSafeArea);
	CreateNative("L4D_IsAnySurvivorInStartArea",		 			Native_CDirector_IsAnySurvivorInStartArea);
	CreateNative("L4D_IsAnySurvivorInCheckpoint",		 			Native_CDirector_IsAnySurvivorInCheckpoint);
	// CreateNative("L4D_IsAnySurvivorInExitCheckpoint",		 		Native_CDirector_IsAnySurvivorInCheckpoint);
	CreateNative("L4D_AreAllSurvivorsInFinaleArea",		 			Native_CDirector_AreAllSurvivorsInFinaleArea);
	CreateNative("L4D_IsInFirstCheckpoint",		 					Native_IsInFirstCheckpoint);
	CreateNative("L4D_IsInLastCheckpoint",		 					Native_IsInLastCheckpoint);
	CreateNative("L4D_IsPositionInFirstCheckpoint",		 			Native_IsPositionInFirstCheckpoint);
	CreateNative("L4D_IsPositionInLastCheckpoint",		 			Native_IsPositionInLastCheckpoint);
	CreateNative("L4D_GetCheckpointFirst",		 					Native_GetCheckpointFirst);
	CreateNative("L4D_GetCheckpointLast",		 					Native_GetCheckpointLast);
	CreateNative("L4D_HasPlayerControlledZombies",		 			Native_CTerrorGameRules_HasPlayerControlledZombies);
	CreateNative("L4D_DetonateProjectile",		 					Native_CBaseGrenade_Detonate);
	// CreateNative("L4D_StartBurning",		 						Native_CInferno_StartBurning);
	CreateNative("L4D_TankRockPrj",		 							Native_CTankRock_Create);
	CreateNative("L4D_PipeBombPrj",		 							Native_CPipeBombProjectile_Create);
	CreateNative("L4D_MolotovPrj",		 							Native_CMolotovProjectile_Create);
	CreateNative("L4D2_VomitJarPrj",		 						Native_CVomitJarProjectile_Create);
	CreateNative("L4D2_GrenadeLauncherPrj",		 					Native_CGrenadeLauncher_Projectile_Create);
	CreateNative("L4D_SetHumanSpec",								Native_SurvivorBot_SetHumanSpectator);
	CreateNative("L4D_TakeOverBot",									Native_CTerrorPlayer_TakeOverBot);
	CreateNative("L4D_CanBecomeGhost",								Native_CTerrorPlayer_CanBecomeGhost);
	CreateNative("L4D_SetBecomeGhostAt",							Native_CTerrorPlayer_SetBecomeGhostAt);
	CreateNative("L4D_IsFinaleEscapeInProgress",					Native_CDirector_IsFinaleEscapeInProgress);

	// L4D2 only:
	CreateNative("L4D2_AreWanderersAllowed",						Native_CDirector_AreWanderersAllowed);
	CreateNative("L4D2_GetScriptScope",								Native_GetScriptScope);
	CreateNative("L4D2_GetVScriptEntity",							Native_GetVScriptEntity);
	CreateNative("L4D2_ExecVScriptCode",							Native_ExecVScriptCode);
	CreateNative("L4D2_GetVScriptOutput",							Native_GetVScriptOutput);
	CreateNative("L4D2_SpitterPrj",		 							Native_CSpitterProjectile_Create);
	CreateNative("L4D2_UseAdrenaline",		 						Native_CTerrorPlayer_OnAdrenalineUsed);
	CreateNative("L4D2_GetCurrentFinaleStage",		 				Native_GetCurrentFinaleStage);
	CreateNative("L4D2_ForceNextStage",		 						Native_CDirector_ForceNextStage);
	CreateNative("L4D_GetSurvivalStartTime",		 				Native_GetSurvivalStartTime);
	CreateNative("L4D_SetSurvivalStartTime",		 				Native_SetSurvivalStartTime);
	CreateNative("L4D_ForceVersusStart",		 					Native_ForceVersusStart);
	CreateNative("L4D_ForceSurvivalStart",		 					Native_ForceSurvivalStart);
	CreateNative("L4D2_ForceScavengeStart",		 					Native_ForceScavengeStart);
	CreateNative("L4D2_IsTankInPlay",		 						Native_CDirector_IsTankInPlay);
	CreateNative("L4D2_IsReachable",		 						Native_SurvivorBot_IsReachable);
	CreateNative("L4D2_GetFirstSpawnClass",		 					Native_GetFirstSpawnClass);
	CreateNative("L4D2_SetFirstSpawnClass",		 					Native_SetFirstSpawnClass);
	CreateNative("L4D2_GetFurthestSurvivorFlow",		 			Native_CDirector_GetFurthestSurvivorFlow);
	CreateNative("L4D2_GetDirectorScriptScope",						Native_GetDirectorScriptScope);
	CreateNative("L4D2_GetScriptValueInt",							Native_CDirector_GetScriptValueInt);
	CreateNative("L4D2_GetScriptValueFloat",						Native_CDirector_GetScriptValueFloat);
	// CreateNative("L4D2_GetScriptValueString",						Native_CDirector_GetScriptValueString); // Crashes when the key has not been set
	CreateNative("L4D2_NavAreaTravelDistance",		 				Native_NavAreaTravelDistance);
	CreateNative("L4D2_NavAreaBuildPath",							Native_NavAreaBuildPath);
	CreateNative("L4D2_CommandABot",								Native_CommandABot);

	CreateNative("L4D2_VScriptWrapper_GetMapNumber",				Native_VS_GetMapNumber);
	CreateNative("L4D2_VScriptWrapper_HasEverBeenInjured",			Native_VS_HasEverBeenInjured);
	CreateNative("L4D2_VScriptWrapper_GetAliveDuration",			Native_VS_GetAliveDuration);
	CreateNative("L4D2_VScriptWrapper_IsDead",						Native_VS_IsDead);
	CreateNative("L4D2_VScriptWrapper_IsDying",						Native_VS_IsDying);
	CreateNative("L4D2_VScriptWrapper_UseAdrenaline",				Native_VS_UseAdrenaline);
	CreateNative("L4D2_VScriptWrapper_ReviveByDefib",				Native_VS_ReviveByDefib);
	CreateNative("L4D2_VScriptWrapper_ReviveFromIncap",				Native_VS_ReviveFromIncap);
	CreateNative("L4D2_VScriptWrapper_GetSenseFlags",				Native_VS_GetSenseFlags);
	CreateNative("L4D2_VScriptWrapper_NavAreaBuildPath",			Native_VS_NavAreaBuildPath);
	CreateNative("L4D2_VScriptWrapper_NavAreaTravelDistance",		Native_VS_NavAreaTravelDistance);



	// =========================
	// left4downtown.inc
	// =========================
	// CreateNative("L4D_GetCampaignScores",						Native_GetCampaignScores);
	CreateNative("L4D_LobbyUnreserve",				 				Native_CBaseServer_SetReservationCookie);
	CreateNative("L4D_LobbyIsReserved",								Native_LobbyIsReserved);
	CreateNative("L4D_GetLobbyReservation",							Native_GetLobbyReservation);
	CreateNative("L4D_SetLobbyReservation",							Native_SetLobbyReservation);
	CreateNative("L4D_RestartScenarioFromVote",		 				Native_CDirector_RestartScenarioFromVote);
	CreateNative("L4D_IsFirstMapInScenario",						Native_CDirector_IsFirstMapInScenario);
	CreateNative("L4D_IsMissionFinalMap",							Native_CTerrorGameRules_IsMissionFinalMap);
	CreateNative("L4D_NotifyNetworkStateChanged",					Native_CGameRulesProxy_NotifyNetworkStateChanged);
	CreateNative("L4D_StaggerPlayer",								Native_CTerrorPlayer_OnStaggered);
	CreateNative("L4D2_SendInRescueVehicle",						Native_CDirectorScriptedEventManager_SendInRescueVehicle);
	CreateNative("L4D_ReplaceTank",									Native_ZombieManager_ReplaceTank);
	CreateNative("L4D2_SpawnTank",									Native_ZombieManager_SpawnTank);
	CreateNative("L4D2_SpawnSpecial",								Native_ZombieManager_SpawnSpecial);
	CreateNative("L4D2_SpawnWitch",									Native_ZombieManager_SpawnWitch);
	CreateNative("L4D2_GetTankCount",								Native_GetTankCount);
	CreateNative("L4D2_GetWitchCount",								Native_GetWitchCount);
	CreateNative("L4D_GetCurrentChapter",							Native_GetCurrentChapter);
	CreateNative("L4D_GetAllNavAreas",								Native_GetAllNavAreas);
	CreateNative("L4D_GetNavAreaID",								Native_GetNavAreaID);
	CreateNative("L4D_GetNavAreaByID",								Native_GetNavAreaByID);
	CreateNative("L4D_GetNavAreaPos",								Native_GetNavAreaPos);
	CreateNative("L4D_GetNavAreaCenter",							Native_GetNavAreaCenter);
	CreateNative("L4D_GetNavAreaSize",								Native_GetNavAreaSize);
	CreateNative("L4D_NavArea_IsConnected",							Native_CNavArea_IsConnected);
	CreateNative("L4D_GetNavArea_SpawnAttributes",					Native_GetTerrorNavArea_Attributes);
	CreateNative("L4D_SetNavArea_SpawnAttributes",					Native_SetTerrorNavArea_Attributes);
	CreateNative("L4D_GetNavArea_AttributeFlags",					Native_GetCNavArea_AttributeFlags);
	CreateNative("L4D_SetNavArea_AttributeFlags",					Native_SetCNavArea_AttributeFlags);
	CreateNative("L4D_GetMaxChapters",								Native_CTerrorGameRules_GetNumChaptersForMissionAndMode);
	CreateNative("L4D_GetVersusMaxCompletionScore",					Native_GetVersusMaxCompletionScore);
	CreateNative("L4D_SetVersusMaxCompletionScore",					Native_SetVersusMaxCompletionScore);

	// L4D2 only:
	CreateNative("L4D_ScavengeBeginRoundSetupTime", 				Native_ScavengeBeginRoundSetupTime);
	CreateNative("L4D2_SpawnAllScavengeItems",						Native_CDirector_SpawnAllScavengeItems);
	CreateNative("L4D_ResetMobTimer",								Native_CDirector_ResetMobTimer);
	CreateNative("L4D_GetPlayerSpawnTime",							Native_GetPlayerSpawnTime);
	CreateNative("L4D_SetPlayerSpawnTime",							Native_SetPlayerSpawnTime);
	CreateNative("L4D_GetTeamScore",								Native_CTerrorGameRules_GetTeamScore);
	CreateNative("L4D_GetMobSpawnTimerRemaining",					Native_GetMobSpawnTimerRemaining);
	CreateNative("L4D_GetMobSpawnTimerDuration",					Native_GetMobSpawnTimerDuration);
	CreateNative("L4D2_ChangeFinaleStage",							Native_CDirectorScriptedEventManager_ChangeFinaleStage);
	CreateNative("L4D2_SpawnWitchBride",							Native_ZombieManager_SpawnWitchBride);

	// l4d2weapons.inc
	CreateNative("L4D_GetWeaponID",									Native_GetWeaponID);
	CreateNative("L4D2_IsValidWeapon",								Native_Internal_IsValidWeapon);
	CreateNative("L4D2_GetIntWeaponAttribute",						Native_GetIntWeaponAttribute);
	CreateNative("L4D2_GetFloatWeaponAttribute",					Native_GetFloatWeaponAttribute);
	CreateNative("L4D2_SetIntWeaponAttribute",						Native_SetIntWeaponAttribute);
	CreateNative("L4D2_SetFloatWeaponAttribute",					Native_SetFloatWeaponAttribute);
	CreateNative("L4D2_GetMeleeWeaponIndex",						Native_GetMeleeWeaponIndex);
	CreateNative("L4D2_GetIntMeleeAttribute",						Native_GetIntMeleeAttribute);
	CreateNative("L4D2_GetFloatMeleeAttribute",						Native_GetFloatMeleeAttribute);
	CreateNative("L4D2_GetBoolMeleeAttribute",						Native_GetBoolMeleeAttribute);
	CreateNative("L4D2_SetIntMeleeAttribute",						Native_SetIntMeleeAttribute);
	CreateNative("L4D2_SetFloatMeleeAttribute",						Native_SetFloatMeleeAttribute);
	CreateNative("L4D2_SetBoolMeleeAttribute",						Native_SetBoolMeleeAttribute);

	// l4d2timers.inc
	CreateNative("L4D2_CTimerReset",								Native_CTimerReset);
	CreateNative("L4D2_CTimerStart",								Native_CTimerStart);
	CreateNative("L4D2_CTimerInvalidate",							Native_CTimerInvalidate);
	CreateNative("L4D2_CTimerHasStarted",							Native_CTimerHasStarted);
	CreateNative("L4D2_CTimerIsElapsed",							Native_CTimerIsElapsed);
	CreateNative("L4D2_CTimerGetElapsedTime",						Native_CTimerGetElapsedTime);
	CreateNative("L4D2_CTimerGetRemainingTime",						Native_CTimerGetRemainingTime);
	CreateNative("L4D2_CTimerGetCountdownDuration",					Native_CTimerGetCountdownDuration);
	CreateNative("L4D2_ITimerStart",								Native_ITimerStart);
	CreateNative("L4D2_ITimerInvalidate",							Native_ITimerInvalidate);
	CreateNative("L4D2_ITimerHasStarted",							Native_ITimerHasStarted);
	CreateNative("L4D2_ITimerGetElapsedTime",						Native_ITimerGetElapsedTime);

	// l4d2director.inc
	CreateNative("L4D2_GetVersusCampaignScores",					Native_GetVersusCampaignScores);
	CreateNative("L4D2_SetVersusCampaignScores",					Native_SetVersusCampaignScores);
	CreateNative("L4D2_GetVersusTankFlowPercent",					Native_GetVersusTankFlowPercent);
	CreateNative("L4D2_SetVersusTankFlowPercent",					Native_SetVersusTankFlowPercent);
	CreateNative("L4D2_GetVersusWitchFlowPercent",					Native_GetVersusWitchFlowPercent);
	CreateNative("L4D2_SetVersusWitchFlowPercent",					Native_SetVersusWitchFlowPercent);



	// =========================
	// l4d2_direct.inc
	// =========================
	CreateNative("L4D2Direct_GetPendingMobCount",					Direct_GetPendingMobCount);
	CreateNative("L4D2Direct_SetPendingMobCount",					Direct_SetPendingMobCount);
	CreateNative("L4D2Direct_GetTankPassedCount",					Direct_GetTankPassedCount);
	CreateNative("L4D2Direct_SetTankPassedCount",					Direct_SetTankPassedCount);
	CreateNative("L4D2Direct_GetVSCampaignScore",					Direct_GetVSCampaignScore);
	CreateNative("L4D2Direct_SetVSCampaignScore",					Direct_SetVSCampaignScore);
	CreateNative("L4D2Direct_GetVSTankFlowPercent",					Direct_GetVSTankFlowPercent);
	CreateNative("L4D2Direct_SetVSTankFlowPercent",					Direct_SetVSTankFlowPercent);
	CreateNative("L4D2Direct_GetVSTankToSpawnThisRound",			Direct_GetVSTankToSpawnThisRound);
	CreateNative("L4D2Direct_SetVSTankToSpawnThisRound",			Direct_SetVSTankToSpawnThisRound);
	CreateNative("L4D2Direct_GetVSWitchFlowPercent",				Direct_GetVSWitchFlowPercent);
	CreateNative("L4D2Direct_SetVSWitchFlowPercent",				Direct_SetVSWitchFlowPercent);
	CreateNative("L4D2Direct_GetVSWitchToSpawnThisRound",			Direct_GetVSWitchToSpawnThisRound);
	CreateNative("L4D2Direct_SetVSWitchToSpawnThisRound",			Direct_SetVSWitchToSpawnThisRound);
	CreateNative("L4D2Direct_GetMapMaxFlowDistance",				Direct_GetMapMaxFlowDistance);
	CreateNative("L4D2Direct_GetInvulnerabilityTimer",				Direct_GetInvulnerabilityTimer);
	CreateNative("L4D2Direct_GetTankTickets",						Direct_GetTankTickets);
	CreateNative("L4D2Direct_SetTankTickets",						Direct_SetTankTickets);
	CreateNative("L4D2Direct_GetTerrorNavArea",						Direct_GetTerrorNavArea);
	CreateNative("L4D2Direct_GetTerrorNavAreaFlow",					Direct_GetTerrorNavAreaFlow);
	CreateNative("L4D2Direct_TryOfferingTankBot",					Direct_TryOfferingTankBot);
	CreateNative("L4D2Direct_GetFlowDistance",						Direct_GetFlowDistance);
	CreateNative("L4D2Direct_DoAnimationEvent",						Direct_DoAnimationEvent);
	CreateNative("L4DDirect_GetSurvivorHealthBonus",				Direct_GetSurvivorHealthBonus);
	CreateNative("L4DDirect_SetSurvivorHealthBonus",				Direct_SetSurvivorHealthBonus);
	CreateNative("L4DDirect_RecomputeTeamScores",					Direct_RecomputeTeamScores);
	CreateNative("L4D2Direct_GetMobSpawnTimer",						Direct_GetMobSpawnTimer);
	CreateNative("L4D2Direct_GetTankCount",							Direct_GetTankCount);

	CreateNative("CTimer_Reset",									Direct_CTimer_Reset);
	CreateNative("CTimer_Start",									Direct_CTimer_Start);
	CreateNative("CTimer_Invalidate",								Direct_CTimer_Invalidate);
	CreateNative("CTimer_HasStarted",								Direct_CTimer_HasStarted);
	CreateNative("CTimer_IsElapsed",								Direct_CTimer_IsElapsed);
	CreateNative("CTimer_GetElapsedTime",							Direct_CTimer_GetElapsedTime);
	CreateNative("CTimer_GetRemainingTime",							Direct_CTimer_GetRemainingTime);
	CreateNative("CTimer_GetCountdownDuration",						Direct_CTimer_GetCountdownDuration);
	CreateNative("ITimer_Reset",									Direct_ITimer_Reset);
	CreateNative("ITimer_Start",									Direct_ITimer_Start);
	CreateNative("ITimer_Invalidate",								Direct_ITimer_Invalidate);
	CreateNative("ITimer_HasStarted",								Direct_ITimer_HasStarted);
	CreateNative("ITimer_GetElapsedTime",							Direct_ITimer_GetElapsedTime);

	// l4d2d_timers.inc
	CreateNative("CTimer_GetDuration",								Direct_CTimer_GetDuration);
	CreateNative("CTimer_SetDuration",								Direct_CTimer_SetDuration);
	CreateNative("CTimer_GetTimestamp",								Direct_CTimer_GetTimestamp);
	CreateNative("CTimer_SetTimestamp",								Direct_CTimer_SetTimestamp);
	CreateNative("ITimer_GetTimestamp",								Direct_ITimer_GetTimestamp);
	CreateNative("ITimer_SetTimestamp",								Direct_ITimer_SetTimestamp);

	// L4D2 only:
	CreateNative("L4D2Direct_GetSIClassDeathTimer",					Direct_GetSIClassDeathTimer);
	CreateNative("L4D2Direct_GetSIClassSpawnTimer",					Direct_GetSIClassSpawnTimer);
	CreateNative("L4D2Direct_GetVSStartTimer",						Direct_GetVSStartTimer);
	CreateNative("L4D2Direct_GetScavengeRoundSetupTimer",			Direct_GetScavengeRoundSetupTimer);
	CreateNative("L4D2Direct_GetScavengeOvertimeGraceTimer",		Direct_GetScavengeOvertimeGraceTimer);
	CreateNative("L4D2Direct_GetSpawnTimer",						Direct_GetSpawnTimer);
	CreateNative("L4D2Direct_GetShovePenalty",						Direct_GetShovePenalty);
	CreateNative("L4D2Direct_SetShovePenalty",						Direct_SetShovePenalty);
	CreateNative("L4D2Direct_GetNextShoveTime",						Direct_GetNextShoveTime);
	CreateNative("L4D2Direct_SetNextShoveTime",						Direct_SetNextShoveTime);
	CreateNative("L4D2Direct_GetPreIncapHealth",					Direct_GetPreIncapHealth);
	CreateNative("L4D2Direct_SetPreIncapHealth",					Direct_SetPreIncapHealth);
	CreateNative("L4D2Direct_GetPreIncapHealthBuffer",				Direct_GetPreIncapHealthBuffer);
	CreateNative("L4D2Direct_SetPreIncapHealthBuffer",				Direct_SetPreIncapHealthBuffer);
	CreateNative("L4D2Direct_GetInfernoMaxFlames",					Direct_GetInfernoMaxFlames);
	CreateNative("L4D2Direct_SetInfernoMaxFlames",					Direct_SetInfernoMaxFlames);
	CreateNative("L4D2Direct_GetScriptedEventManager",				Direct_GetScriptedEventManager);



	// =========================
	// l4d2addresses.txt
	// =========================
	CreateNative("L4D_CTerrorPlayer_OnVomitedUpon",					Native_CTerrorPlayer_OnVomitedUpon);
	CreateNative("L4D_CancelStagger",								Native_CTerrorPlayer_CancelStagger);
	CreateNative("L4D_FindUseEntity",								Native_CTerrorPlayer_FindUseEntity);
	CreateNative("L4D_ForceHunterVictim",							Native_CTerrorPlayer_OnPouncedOnSurvivor);
	CreateNative("L4D_ForceSmokerVictim",							Native_CTerrorPlayer_GrabVictimWithTongue);
	CreateNative("L4D2_ForceJockeyVictim",							Native_CTerrorPlayer_OnLeptOnSurvivor);
	CreateNative("L4D2_Charger_ThrowImpactedSurvivor",				Native_ThrowImpactedSurvivor);
	CreateNative("L4D2_Charger_StartCarryingVictim",				Native_CTerrorPlayer_OnStartCarryingVictim);
	CreateNative("L4D2_Charger_PummelVictim",						Native_CTerrorPlayer_QueuePummelVictim);
	CreateNative("L4D2_Charger_EndPummel",							Native_CTerrorPlayer_OnPummelEnded);
	CreateNative("L4D2_Charger_EndCarry",							Native_CTerrorPlayer_OnCarryEnded);
	CreateNative("L4D2_Jockey_EndRide",								Native_CTerrorPlayer_OnRideEnded);
	CreateNative("L4D_Hunter_ReleaseVictim",						Native_CTerrorPlayer_OnPounceEnded);
	CreateNative("L4D_Smoker_ReleaseVictim",						Native_CTerrorPlayer_ReleaseTongueVictim);
	CreateNative("L4D_RespawnPlayer",								Native_CTerrorPlayer_RespawnPlayer);
	CreateNative("L4D_CreateRescuableSurvivors",					Native_CDirector_CreateRescuableSurvivors);
	CreateNative("L4D_StopBeingRevived",							Native_CTerrorPlayer_StopBeingRevived);
	CreateNative("L4D_ReviveSurvivor",								Native_CTerrorPlayer_OnRevived);
	CreateNative("L4D_GetHighestFlowSurvivor",						Native_CDirectorTacticalServices_GetHighestFlowSurvivor);
	CreateNative("L4D_GetInfectedFlowDistance",						Native_Infected_GetInfectedFlowDistance);
	CreateNative("L4D_TakeOverZombieBot",							Native_CTerrorPlayer_TakeOverZombieBot);
	CreateNative("L4D_ReplaceWithBot",								Native_CTerrorPlayer_ReplaceWithBot);
	CreateNative("L4D_CullZombie",									Native_CTerrorPlayer_CullZombie);
	CreateNative("L4D_SetClass",									Native_CTerrorPlayer_SetClass);
	CreateNative("L4D_CleanupPlayerState",							Native_CTerrorPlayer_CleanupPlayerState);
	CreateNative("L4D_MaterializeFromGhost",						Native_CTerrorPlayer_MaterializeFromGhost);
	CreateNative("L4D_BecomeGhost",									Native_CTerrorPlayer_BecomeGhost);
	CreateNative("L4D_GoAwayFromKeyboard",							Native_CTerrorPlayer_GoAwayFromKeyboard);
	CreateNative("L4D_State_Transition",							Native_CCSPlayer_State_Transition);
	CreateNative("L4D_RegisterForbiddenTarget",						Native_CDirector_RegisterForbiddenTarget);
	CreateNative("L4D_UnRegisterForbiddenTarget",					Native_CDirector_UnregisterForbiddenTarget);

	// L4D2 only:
	CreateNative("L4D2_CTerrorPlayer_OnHitByVomitJar",				Native_CTerrorPlayer_OnHitByVomitJar);
	CreateNative("L4D2_Infected_OnHitByVomitJar",					Native_Infected_OnHitByVomitJar);
	CreateNative("L4D2_CTerrorPlayer_Fling",						Native_CTerrorPlayer_Fling);
	CreateNative("L4D2_GetVersusCompletionPlayer",					Native_CTerrorGameRules_GetVersusCompletion);
	CreateNative("L4D2_SwapTeams",									Native_CDirector_SwapTeams);
	CreateNative("L4D2_AreTeamsFlipped",							Native_CDirector_AreTeamsFlipped);
	CreateNative("L4D2_Rematch",									Native_CDirector_Rematch);
	CreateNative("L4D2_StartRematchVote",							Native_CDirector_StartRematchVote);
	CreateNative("L4D_EndVersusModeRound",							Native_CDirectorVersusMode_EndVersusModeRound);
	CreateNative("L4D2_FullRestart",								Native_CDirector_FullRestart);
	CreateNative("L4D2_HideVersusScoreboard",						Native_CDirectorVersusMode_HideScoreboardNonVirtual);
	CreateNative("L4D2_HideScavengeScoreboard",						Native_CDirectorScavengeMode_HideScoreboardNonVirtual);
	CreateNative("L4D2_HideScoreboard",								Native_CDirector_HideScoreboard);
}