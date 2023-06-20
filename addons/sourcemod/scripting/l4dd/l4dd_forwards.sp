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



// FORWARDS
GlobalForward g_hFWD_GameModeChange;
GlobalForward g_hFWD_ZombieManager_SpawnSpecial;
GlobalForward g_hFWD_ZombieManager_SpawnSpecial_Post;
GlobalForward g_hFWD_ZombieManager_SpawnSpecial_PostHandled;
GlobalForward g_hFWD_ZombieManager_SpawnTank;
GlobalForward g_hFWD_ZombieManager_SpawnTank_Post;
GlobalForward g_hFWD_ZombieManager_SpawnTank_PostHandled;
GlobalForward g_hFWD_ZombieManager_SpawnWitch;
GlobalForward g_hFWD_ZombieManager_SpawnWitch_Post;
GlobalForward g_hFWD_ZombieManager_SpawnWitch_PostHandled;
GlobalForward g_hFWD_ZombieManager_SpawnWitchBride;
GlobalForward g_hFWD_ZombieManager_SpawnWitchBride_Post;
GlobalForward g_hFWD_ZombieManager_SpawnWitchBride_PostHandled;
GlobalForward g_hFWD_CTerrorGameRules_ClearTeamScores;
GlobalForward g_hFWD_CTerrorGameRules_SetCampaignScores;
GlobalForward g_hFWD_CTerrorGameRules_SetCampaignScores_Post;
GlobalForward g_hFWD_CTerrorPlayer_RecalculateVersusScore;
GlobalForward g_hFWD_CTerrorPlayer_RecalculateVersusScore_Post;
GlobalForward g_hFWD_CDirector_OnFirstSurvivorLeftSafeArea;
GlobalForward g_hFWD_CDirector_OnFirstSurvivorLeftSafeArea_Post;
GlobalForward g_hFWD_CDirector_OnFirstSurvivorLeftSafeArea_PostHandled;
GlobalForward g_hFWD_CDirector_OnForceSurvivorPositions_Pre;
GlobalForward g_hFWD_CDirector_OnForceSurvivorPositions;
GlobalForward g_hFWD_CDirector_OnReleaseSurvivorPositions;
GlobalForward g_hFWD_SpeakResponseConceptFromEntityIO_Pre;
GlobalForward g_hFWD_SpeakResponseConceptFromEntityIO_Post;
GlobalForward g_hFWD_CDirector_GetScriptValueInt;
GlobalForward g_hFWD_CDirector_GetScriptValueFloat;
// GlobalForward g_hFWD_CDirector_GetScriptValueVector;
GlobalForward g_hFWD_CDirector_GetScriptValueString;
GlobalForward g_hFWD_CSquirrelVM_GetValue_Void;
GlobalForward g_hFWD_CSquirrelVM_GetValue_Int;
GlobalForward g_hFWD_CSquirrelVM_GetValue_Float;
GlobalForward g_hFWD_CSquirrelVM_GetValue_Vector;
GlobalForward g_hFWD_CDirector_IsTeamFull;
GlobalForward g_hFWD_CTerrorPlayer_EnterGhostState_Pre;
GlobalForward g_hFWD_CTerrorPlayer_EnterGhostState_Post;
GlobalForward g_hFWD_CTerrorPlayer_EnterGhostState_PostHandled;
GlobalForward g_hFWD_CTerrorPlayer_TakeOverBot_Pre;
GlobalForward g_hFWD_CTerrorPlayer_TakeOverBot_Post;
GlobalForward g_hFWD_CTerrorPlayer_TakeOverBot_PostHandled;
GlobalForward g_hFWD_CTankClaw_DoSwing_Pre;
GlobalForward g_hFWD_CTankClaw_DoSwing_Post;
GlobalForward g_hFWD_CTankClaw_GroundPound_Pre;
GlobalForward g_hFWD_CTankClaw_GroundPound_Post;
GlobalForward g_hFWD_CTankClaw_OnPlayerHit_Pre;
GlobalForward g_hFWD_CTankClaw_OnPlayerHit_Post;
GlobalForward g_hFWD_CTankClaw_OnPlayerHit_PostHandled;
GlobalForward g_hFWD_CTankRock_Detonate;
GlobalForward g_hFWD_CTankRock_OnRelease;
GlobalForward g_hFWD_CTankRock_OnRelease_Post;
GlobalForward g_hFWD_CDirector_TryOfferingTankBot;
GlobalForward g_hFWD_CDirector_TryOfferingTankBot_Post;
GlobalForward g_hFWD_CDirector_TryOfferingTankBot_PostHandled;
GlobalForward g_hFWD_CDirector_MobRushStart;
GlobalForward g_hFWD_CDirector_MobRushStart_Post;
GlobalForward g_hFWD_CDirector_MobRushStart_PostHandled;
GlobalForward g_hFWD_ZombieManager_SpawnITMob;
GlobalForward g_hFWD_ZombieManager_SpawnITMob_Post;
GlobalForward g_hFWD_ZombieManager_SpawnITMob_PostHandled;
GlobalForward g_hFWD_ZombieManager_SpawnMob;
GlobalForward g_hFWD_ZombieManager_SpawnMob_Post;
GlobalForward g_hFWD_ZombieManager_SpawnMob_PostHandled;
GlobalForward g_hFWD_CTerrorWeapon_OnSwingStart;
GlobalForward g_hFWD_CTerrorPlayer_OnShovedBySurvivor;
GlobalForward g_hFWD_CTerrorPlayer_OnShovedBySurvivor_Post;
GlobalForward g_hFWD_CTerrorPlayer_OnShovedBySurvivor_PostHandled;
GlobalForward g_hFWD_CTerrorPlayer_GetCrouchTopSpeed;
GlobalForward g_hFWD_CTerrorPlayer_GetRunTopSpeed;
GlobalForward g_hFWD_CTerrorPlayer_GetWalkTopSpeed;
GlobalForward g_hFWD_CTerrorGameRules_HasConfigurableDifficultySetting;
GlobalForward g_hFWD_CTerrorGameRules_HasConfigurableDifficultySetting_Post;
GlobalForward g_hFWD_CTerrorGameRules_GetSurvivorSet;
GlobalForward g_hFWD_CTerrorGameRules_FastGetSurvivorSet;
GlobalForward g_hFWD_GetMissionVSBossSpawning;
GlobalForward g_hFWD_GetMissionVSBossSpawning_Post;
GlobalForward g_hFWD_GetMissionVSBossSpawning_PostHandled;
GlobalForward g_hFWD_CThrow_ActivateAbililty;
GlobalForward g_hFWD_CThrow_ActivateAbililty_Post;
GlobalForward g_hFWD_CThrow_ActivateAbililty_PostHandled;
GlobalForward g_hFWD_StartMeleeSwing;
GlobalForward g_hFWD_StartMeleeSwing_Post;
GlobalForward g_hFWD_StartMeleeSwing_PostHandled;
GlobalForward g_hFWD_GetDamageForVictim;
GlobalForward g_hFWD_CDirectorScriptedEventManager_SendInRescueVehicle;
GlobalForward g_hFWD_CDirectorScriptedEventManager_ChangeFinaleStage;
GlobalForward g_hFWD_CDirectorScriptedEventManager_ChangeFinaleStage_Post;
GlobalForward g_hFWD_CDirectorScriptedEventManager_ChangeFinaleStage_PostPost;
GlobalForward g_hFWD_CDirectorVersusMode_EndVersusModeRound_Pre;
GlobalForward g_hFWD_CDirectorVersusMode_EndVersusModeRound_Post;
GlobalForward g_hFWD_CDirectorVersusMode_EndVersusModeRound_PostHandled;
GlobalForward g_hFWD_CBaseAnimating_SelectWeightedSequence_Pre;
GlobalForward g_hFWD_CBaseAnimating_SelectWeightedSequence_Post;
GlobalForward g_hFWD_CTerrorPlayer_DoAnimationEvent;
GlobalForward g_hFWD_CTerrorPlayer_DoAnimationEvent_Post;
GlobalForward g_hFWD_CTerrorPlayer_DoAnimationEvent_PostHandled;
GlobalForward g_hFWD_CTerrorPlayer_OnLedgeGrabbed;
GlobalForward g_hFWD_CTerrorPlayer_OnLedgeGrabbed_Post;
GlobalForward g_hFWD_CTerrorPlayer_OnLedgeGrabbed_PostHandled;
GlobalForward g_hFWD_CTerrorPlayer_OnRevived_Post;
GlobalForward g_hFWD_ZombieManager_ReplaceTank;
GlobalForward g_hFWD_SurvivorBot_UseHealingItems;
GlobalForward g_hFWD_SurvivorBot_FindScavengeItem_Post;
GlobalForward g_hFWD_BossZombiePlayerBot_ChooseVictim_Post;
GlobalForward g_hFWD_CTerrorPlayer_MaterializeFromGhost_Pre;
GlobalForward g_hFWD_CTerrorPlayer_MaterializeFromGhost_Post;
GlobalForward g_hFWD_CTerrorPlayer_MaterializeFromGhost_PostHandled;
GlobalForward g_hFWD_CTerrorPlayer_OnVomitedUpon;
GlobalForward g_hFWD_CTerrorPlayer_OnVomitedUpon_Post;
GlobalForward g_hFWD_CTerrorPlayer_OnVomitedUpon_PostHandled;
GlobalForward g_hFWD_CTerrorPlayer_OnHitByVomitJar;
GlobalForward g_hFWD_CTerrorPlayer_OnHitByVomitJar_Post;
GlobalForward g_hFWD_CTerrorPlayer_OnHitByVomitJar_PostHandled;
GlobalForward g_hFWD_CBreakableProp_Break_Post;
GlobalForward g_hFWD_CGasCanEvent_Killed;
GlobalForward g_hFWD_CGasCanEvent_Killed_Post;
GlobalForward g_hFWD_CGasCanEvent_Killed_PostHandled;
GlobalForward g_hFWD_CGasCan_ShouldStartAction;
GlobalForward g_hFWD_CGasCan_ShouldStartAction_Post;
GlobalForward g_hFWD_CGasCan_ShouldStartAction_PostHandled;
GlobalForward g_hFWD_CBaseBackpackItem_StartAction;
GlobalForward g_hFWD_CBaseBackpackItem_StartAction_Post;
GlobalForward g_hFWD_CBaseBackpackItem_StartAction_PostHandled;
GlobalForward g_hFWD_CFirstAidKit_StartHealing;
GlobalForward g_hFWD_CFirstAidKit_StartHealing_Post;
GlobalForward g_hFWD_CFirstAidKit_StartHealing_PostHandled;
GlobalForward g_hFWD_CGasCan_OnActionComplete;
GlobalForward g_hFWD_CGasCan_OnActionComplete_Post;
GlobalForward g_hFWD_CGasCan_OnActionComplete_PostHandled;
GlobalForward g_hFWD_CServerGameDLL_ServerHibernationUpdate;
GlobalForward g_hFWD_CTerrorPlayer_OnPouncedOnSurvivor;
GlobalForward g_hFWD_CTerrorPlayer_OnPouncedOnSurvivor_Post;
GlobalForward g_hFWD_CTerrorPlayer_OnPouncedOnSurvivor_PostHandled;
GlobalForward g_hFWD_CTerrorPlayer_GrabVictimWithTongue;
GlobalForward g_hFWD_CTerrorPlayer_GrabVictimWithTongue_Post;
GlobalForward g_hFWD_CTerrorPlayer_GrabVictimWithTongue_PostHandled;
GlobalForward g_hFWD_CTerrorPlayer_OnLeptOnSurvivor;
GlobalForward g_hFWD_CTerrorPlayer_OnLeptOnSurvivor_Post;
GlobalForward g_hFWD_CTerrorPlayer_OnLeptOnSurvivor_PostHandled;
GlobalForward g_hFWD_CTerrorPlayer_OnStartCarryingVictim;
GlobalForward g_hFWD_CTerrorPlayer_OnStartCarryingVictim_Post;
GlobalForward g_hFWD_CTerrorPlayer_OnStartCarryingVictim_PostHandled;
GlobalForward g_hFWD_CCharge_ImpactStagger;
GlobalForward g_hFWD_CInsectSwarm_CanHarm;
GlobalForward g_hFWD_CInsectSwarm_CanHarm_Post;
GlobalForward g_hFWD_CInsectSwarm_CanHarm_PostHandled;
GlobalForward g_hFWD_CPipeBombProjectile_Create_Pre;
GlobalForward g_hFWD_CPipeBombProjectile_Create_Post;
GlobalForward g_hFWD_CPipeBombProjectile_Create_PostHandled;
GlobalForward g_hFWD_CMolotovProjectile_Detonate;
GlobalForward g_hFWD_CMolotovProjectile_Detonate_Post;
GlobalForward g_hFWD_CMolotovProjectile_Detonate_PostHandled;
GlobalForward g_hFWD_CPipeBombProjectile_Detonate;
GlobalForward g_hFWD_CPipeBombProjectile_Detonate_Post;
GlobalForward g_hFWD_CPipeBombProjectile_Detonate_PostHandled;
GlobalForward g_hFWD_CVomitJarProjectile_Detonate;
GlobalForward g_hFWD_CVomitJarProjectile_Detonate_Post;
GlobalForward g_hFWD_CVomitJarProjectile_Detonate_PostHandled;
GlobalForward g_hFWD_CTerrorPlayer_Extinguish;
GlobalForward g_hFWD_CInferno_Spread;
GlobalForward g_hFWD_CTerrorWeapon_OnHit;
GlobalForward g_hFWD_CTerrorWeapon_OnHit_Post;
GlobalForward g_hFWD_CTerrorWeapon_OnHit_PostHandled;
GlobalForward g_hFWD_CTerrorPlayer_OnStaggered;
GlobalForward g_hFWD_CTerrorPlayer_OnStaggered_Post;
GlobalForward g_hFWD_CTerrorPlayer_OnStaggered_PostHandled;
GlobalForward g_hFWD_CTerrorPlayer_OnShovedByPounceLanding;
GlobalForward g_hFWD_CTerrorPlayer_OnShovedByPounceLanding_Post;
GlobalForward g_hFWD_CTerrorPlayer_OnShovedByPounceLanding_PostHandled;
GlobalForward g_hFWD_CTerrorPlayer_OnKnockedDown;
GlobalForward g_hFWD_CTerrorPlayer_OnKnockedDown_Post;
GlobalForward g_hFWD_CTerrorPlayer_OnKnockedDown_PostHandled;
GlobalForward g_hFWD_CTerrorPlayer_OnSlammedSurvivor;
GlobalForward g_hFWD_CTerrorPlayer_OnSlammedSurvivor_Post;
GlobalForward g_hFWD_CTerrorPlayer_OnSlammedSurvivor_PostHandled;
GlobalForward g_hFWD_CTerrorPlayer_QueuePummelVictim;
GlobalForward g_hFWD_CTerrorPlayer_QueuePummelVictim_Post;
GlobalForward g_hFWD_CTerrorPlayer_QueuePummelVictim_PostHandled;
GlobalForward g_hFWD_ThrowImpactedSurvivor;
GlobalForward g_hFWD_ThrowImpactedSurvivor_Post;
GlobalForward g_hFWD_ThrowImpactedSurvivor_PostHandled;
GlobalForward g_hFWD_CTerrorPlayer_CancelStagger;
GlobalForward g_hFWD_CTerrorPlayer_CancelStagger_Post;
GlobalForward g_hFWD_CTerrorPlayer_CancelStagger_PostHandled;
GlobalForward g_hFWD_CTerrorPlayer_Fling;
GlobalForward g_hFWD_CTerrorPlayer_Fling_Post;
GlobalForward g_hFWD_CTerrorPlayer_Fling_PostHandled;
GlobalForward g_hFWD_CTerrorPlayer_IsMotionControlledXY;
GlobalForward g_hFWD_CDeathFallCamera_Enable;
GlobalForward g_hFWD_CTerrorPlayer_OnFalling_Post;
GlobalForward g_hFWD_CTerrorPlayer_Cough;
GlobalForward g_hFWD_CTerrorPlayer_Cough_Post;
GlobalForward g_hFWD_CTerrorPlayer_Cough_PostHandled;
GlobalForward g_hFWD_Witch_SetHarasser;
GlobalForward g_hFWD_Tank_EnterStasis_Post;
GlobalForward g_hFWD_Tank_LeaveStasis_Post;
GlobalForward g_hFWD_AddonsDisabler;
// GlobalForward g_hFWD_GetRandomPZSpawnPos;
// GlobalForward g_hFWD_InfectedShoved;
// GlobalForward g_hFWD_OnWaterMove;





// ====================================================================================================
//										DETOURS - SETUP
// ====================================================================================================
// Features: handles multiple detours for 1 forward, and multiple forwards for 1 detour. Also force enabling a detour without any forward using it.
void SetupDetours(GameData hGameData = null)
{
	if( g_bCreatedDetours == false )
	{
		g_aDetoursHooked = new ArrayList();
		g_aDetourHandles = new ArrayList();
		g_aUseLastIndex = new ArrayList();
		g_aForwardIndex = new ArrayList();
		g_aForceDetours = new ArrayList();
		g_aDetourHookIDsPre = new ArrayList();
		g_aDetourHookIDsPost = new ArrayList();
		g_aGameDataSigs = new ArrayList(ByteCountToCells(MAX_FWD_LEN));
		g_aForwardNames = new ArrayList(ByteCountToCells(MAX_FWD_LEN));
	}

	g_iSmallIndex = 0;
	g_iLargeIndex = 0;



	// Forwards listed here must match forward list in plugin start.
	//			 GameData			DHookCallback PRE											DHookCallback POST											Signature Name														Forward Name									useLast index		DynamicHook			Hook Address		forceOn detour
	CreateDetour(hGameData,			DTR_ZombieManager_SpawnTank,								DTR_ZombieManager_SpawnTank_Post,							"L4DD::ZombieManager::SpawnTank",									"L4D_OnSpawnTank");
	CreateDetour(hGameData,			DTR_ZombieManager_SpawnTank,								DTR_ZombieManager_SpawnTank_Post,							"L4DD::ZombieManager::SpawnTank",									"L4D_OnSpawnTank_Post",							true); // Different forwards, same detour as above - same index.
	CreateDetour(hGameData,			DTR_ZombieManager_SpawnTank,								DTR_ZombieManager_SpawnTank_Post,							"L4DD::ZombieManager::SpawnTank",									"L4D_OnSpawnTank_PostHandled",					true);

	if( !g_bLeft4Dead2 && g_bLinuxOS )
	{
		CreateDetour(hGameData,		DTR_ZombieManager_SpawnWitch_Area,							DTR_ZombieManager_SpawnWitch_Area_Post,						"L4DD::ZombieManager::SpawnWitch_Area",								"L4D_OnSpawnWitch");
		CreateDetour(hGameData,		DTR_ZombieManager_SpawnWitch_Area,							DTR_ZombieManager_SpawnWitch_Area_Post,						"L4DD::ZombieManager::SpawnWitch_Area",								"L4D_OnSpawnWitch_Post",						true);
		CreateDetour(hGameData,		DTR_ZombieManager_SpawnWitch_Area,							DTR_ZombieManager_SpawnWitch_Area_Post,						"L4DD::ZombieManager::SpawnWitch_Area",								"L4D_OnSpawnWitch_PostHandled",					true);
	}

	CreateDetour(hGameData,			DTR_ZombieManager_SpawnWitch,								DTR_ZombieManager_SpawnWitch_Post,							"L4DD::ZombieManager::SpawnWitch",									"L4D_OnSpawnWitch");
	CreateDetour(hGameData,			DTR_ZombieManager_SpawnWitch,								DTR_ZombieManager_SpawnWitch_Post,							"L4DD::ZombieManager::SpawnWitch",									"L4D_OnSpawnWitch_Post",						true);
	CreateDetour(hGameData,			DTR_ZombieManager_SpawnWitch,								DTR_ZombieManager_SpawnWitch_Post,							"L4DD::ZombieManager::SpawnWitch",									"L4D_OnSpawnWitch_PostHandled",					true);
	CreateDetour(hGameData,			DTR_CDirector_MobRushStart,									DTR_CDirector_MobRushStart_Post,							"L4DD::CDirector::OnMobRushStart",									"L4D_OnMobRushStart");
	CreateDetour(hGameData,			DTR_CDirector_MobRushStart,									DTR_CDirector_MobRushStart_Post,							"L4DD::CDirector::OnMobRushStart",									"L4D_OnMobRushStart_Post",						true);
	CreateDetour(hGameData,			DTR_CDirector_MobRushStart,									DTR_CDirector_MobRushStart_Post,							"L4DD::CDirector::OnMobRushStart",									"L4D_OnMobRushStart_PostHandled",				true);
	CreateDetour(hGameData,			DTR_ZombieManager_SpawnITMob,								DTR_ZombieManager_SpawnITMob_Post,							"L4DD::ZombieManager::SpawnITMob",									"L4D_OnSpawnITMob");
	CreateDetour(hGameData,			DTR_ZombieManager_SpawnITMob,								DTR_ZombieManager_SpawnITMob_Post,							"L4DD::ZombieManager::SpawnITMob",									"L4D_OnSpawnITMob_Post",						true);
	CreateDetour(hGameData,			DTR_ZombieManager_SpawnITMob,								DTR_ZombieManager_SpawnITMob_Post,							"L4DD::ZombieManager::SpawnITMob",									"L4D_OnSpawnITMob_PostHandled",					true);
	CreateDetour(hGameData,			DTR_ZombieManager_SpawnMob,									DTR_ZombieManager_SpawnMob_Post,							"L4DD::ZombieManager::SpawnMob",									"L4D_OnSpawnMob");
	CreateDetour(hGameData,			DTR_ZombieManager_SpawnMob,									DTR_ZombieManager_SpawnMob_Post,							"L4DD::ZombieManager::SpawnMob",									"L4D_OnSpawnMob_Post",							true);
	CreateDetour(hGameData,			DTR_ZombieManager_SpawnMob,									DTR_ZombieManager_SpawnMob_Post,							"L4DD::ZombieManager::SpawnMob",									"L4D_OnSpawnMob_PostHandled",					true);
	CreateDetour(hGameData,			DTR_CTerrorPlayer_EnterGhostState_Pre,						DTR_CTerrorPlayer_EnterGhostState_Post,						"L4DD::CTerrorPlayer::OnEnterGhostState",							"L4D_OnEnterGhostStatePre");
	CreateDetour(hGameData,			DTR_CTerrorPlayer_EnterGhostState_Pre,						DTR_CTerrorPlayer_EnterGhostState_Post,						"L4DD::CTerrorPlayer::OnEnterGhostState",							"L4D_OnEnterGhostState",						true);
	CreateDetour(hGameData,			DTR_CTerrorPlayer_EnterGhostState_Pre,						DTR_CTerrorPlayer_EnterGhostState_Post,						"L4DD::CTerrorPlayer::OnEnterGhostState",							"L4D_OnEnterGhostState_PostHandled",			true);
	CreateDetour(hGameData,			DTR_CTerrorPlayer_TakeOverBot_Pre,							DTR_CTerrorPlayer_TakeOverBot_Post,							"L4DD::CTerrorPlayer::TakeOverBot",									"L4D_OnTakeOverBot");
	CreateDetour(hGameData,			DTR_CTerrorPlayer_TakeOverBot_Pre,							DTR_CTerrorPlayer_TakeOverBot_Post,							"L4DD::CTerrorPlayer::TakeOverBot",									"L4D_OnTakeOverBot_Post",						true);
	CreateDetour(hGameData,			DTR_CTerrorPlayer_TakeOverBot_Pre,							DTR_CTerrorPlayer_TakeOverBot_Post,							"L4DD::CTerrorPlayer::TakeOverBot",									"L4D_OnTakeOverBot_PostHandled",				true);
	CreateDetour(hGameData,			DTR_CDirector_IsTeamFull,									INVALID_FUNCTION,											"L4DD::CDirector::IsTeamFull",										"L4D_OnIsTeamFull");
	CreateDetour(hGameData,			DTR_CTerrorGameRules_ClearTeamScores,						INVALID_FUNCTION,											"L4DD::CTerrorGameRules::ClearTeamScores",							"L4D_OnClearTeamScores");
	CreateDetour(hGameData,			DTR_CTerrorGameRules_SetCampaignScores,						DTR_CTerrorGameRules_SetCampaignScores_Post,				"L4DD::CTerrorGameRules::SetCampaignScores",						"L4D_OnSetCampaignScores");
	CreateDetour(hGameData,			DTR_CTerrorGameRules_SetCampaignScores,						DTR_CTerrorGameRules_SetCampaignScores_Post,				"L4DD::CTerrorGameRules::SetCampaignScores",						"L4D_OnSetCampaignScores_Post",					true);

	if( !g_bLeft4Dead2 )
	{
		CreateDetour(hGameData,		DTR_CTerrorPlayer_RecalculateVersusScore,					DTR_CTerrorPlayer_RecalculateVersusScore_Post,				"L4DD::CTerrorPlayer::RecalculateVersusScore",						"L4D_OnRecalculateVersusScore");
		CreateDetour(hGameData,		DTR_CTerrorPlayer_RecalculateVersusScore,					DTR_CTerrorPlayer_RecalculateVersusScore_Post,				"L4DD::CTerrorPlayer::RecalculateVersusScore",						"L4D_OnRecalculateVersusScore_Post",			true);
	}

	CreateDetour(hGameData,			DTR_CDirector_OnFirstSurvivorLeftSafeArea,					DTR_CDirector_OnFirstSurvivorLeftSafeArea_Post,				"L4DD::CDirector::OnFirstSurvivorLeftSafeArea",						"L4D_OnFirstSurvivorLeftSafeArea");
	CreateDetour(hGameData,			DTR_CDirector_OnFirstSurvivorLeftSafeArea,					DTR_CDirector_OnFirstSurvivorLeftSafeArea_Post,				"L4DD::CDirector::OnFirstSurvivorLeftSafeArea",						"L4D_OnFirstSurvivorLeftSafeArea_Post",			true);
	CreateDetour(hGameData,			DTR_CDirector_OnFirstSurvivorLeftSafeArea,					DTR_CDirector_OnFirstSurvivorLeftSafeArea_Post,				"L4DD::CDirector::OnFirstSurvivorLeftSafeArea",						"L4D_OnFirstSurvivorLeftSafeArea_PostHandled",	true);
	CreateDetour(hGameData,			DTR_CDirector_OnForceSurvivorPositions_Pre,					DTR_CDirector_OnForceSurvivorPositions_Post,				"L4DD::CDirector::OnForceSurvivorPositions",						"L4D_OnForceSurvivorPositions_Pre");
	CreateDetour(hGameData,			DTR_CDirector_OnForceSurvivorPositions_Pre,					DTR_CDirector_OnForceSurvivorPositions_Post,				"L4DD::CDirector::OnForceSurvivorPositions",						"L4D_OnForceSurvivorPositions",					true);
	CreateDetour(hGameData,			DTR_CDirector_OnReleaseSurvivorPositions_Pre,				DTR_CDirector_OnReleaseSurvivorPositions,					"L4DD::CDirector::OnReleaseSurvivorPositions",						"L4D_OnReleaseSurvivorPositions");
	CreateDetour(hGameData,			DTR_SpeakResponseConceptFromEntityIO_Pre,					DTR_SpeakResponseConceptFromEntityIO_Post,					"L4DD::SpeakResponseConceptFromEntityIO",							"L4D_OnSpeakResponseConcept_Pre");
	CreateDetour(hGameData,			DTR_SpeakResponseConceptFromEntityIO_Pre,					DTR_SpeakResponseConceptFromEntityIO_Post,					"L4DD::SpeakResponseConceptFromEntityIO",							"L4D_OnSpeakResponseConcept_Post",				true);
	CreateDetour(hGameData,			DTR_CTerrorPlayer_GetCrouchTopSpeed_Pre,					DTR_CTerrorPlayer_GetCrouchTopSpeed_Post,					"L4DD::CTerrorPlayer::GetCrouchTopSpeed",							"L4D_OnGetCrouchTopSpeed");
	CreateDetour(hGameData,			DTR_CTerrorPlayer_GetRunTopSpeed_Pre,						DTR_CTerrorPlayer_GetRunTopSpeed_Post,						"L4DD::CTerrorPlayer::GetRunTopSpeed",								"L4D_OnGetRunTopSpeed");
	CreateDetour(hGameData,			DTR_CTerrorPlayer_GetWalkTopSpeed_Pre,						DTR_CTerrorPlayer_GetWalkTopSpeed_Post,						"L4DD::CTerrorPlayer::GetWalkTopSpeed",								"L4D_OnGetWalkTopSpeed");
	CreateDetour(hGameData,			DTR_CDirectorVersusMode_GetMissionVersusBossSpawning,		DTR_CDirectorVersusMode_GetMissionVersusBossSpawning_Post,	"L4DD::CDirectorVersusMode::GetMissionVersusBossSpawning",			"L4D_OnGetMissionVSBossSpawning");
	CreateDetour(hGameData,			DTR_CDirectorVersusMode_GetMissionVersusBossSpawning,		DTR_CDirectorVersusMode_GetMissionVersusBossSpawning_Post,	"L4DD::CDirectorVersusMode::GetMissionVersusBossSpawning",			"L4D_OnGetMissionVSBossSpawning_Post",			true);
	CreateDetour(hGameData,			DTR_CDirectorVersusMode_GetMissionVersusBossSpawning,		DTR_CDirectorVersusMode_GetMissionVersusBossSpawning_Post,	"L4DD::CDirectorVersusMode::GetMissionVersusBossSpawning",			"L4D_OnGetMissionVSBossSpawning_PostHandled",	true);
	CreateDetour(hGameData,			DTR_ZombieManager_ReplaceTank,								INVALID_FUNCTION,											"L4DD::ZombieManager::ReplaceTank",									"L4D_OnReplaceTank");
	CreateDetour(hGameData,			DTR_CTankClaw_DoSwing_Pre,									DTR_CTankClaw_DoSwing_Post,									"L4DD::CTankClaw::DoSwing",											"L4D_TankClaw_DoSwing_Pre");
	CreateDetour(hGameData,			DTR_CTankClaw_DoSwing_Pre,									DTR_CTankClaw_DoSwing_Post,									"L4DD::CTankClaw::DoSwing",											"L4D_TankClaw_DoSwing_Post3",					true);
	CreateDetour(hGameData,			DTR_CTankClaw_GroundPound_Pre,								DTR_CTankClaw_GroundPound_Post,								"L4DD::CTankClaw::GroundPound",										"L4D_TankClaw_GroundPound_Pre");
	CreateDetour(hGameData,			DTR_CTankClaw_GroundPound_Pre,								DTR_CTankClaw_GroundPound_Post,								"L4DD::CTankClaw::GroundPound",										"L4D_TankClaw_GroundPound_Post",				true);
	CreateDetour(hGameData,			DTR_CTankClaw_OnPlayerHit_Pre,								DTR_CTankClaw_OnPlayerHit_Post,								"L4DD::CTankClaw::OnPlayerHit",										"L4D_TankClaw_OnPlayerHit_Pre");
	CreateDetour(hGameData,			DTR_CTankClaw_OnPlayerHit_Pre,								DTR_CTankClaw_OnPlayerHit_Post,								"L4DD::CTankClaw::OnPlayerHit",										"L4D_TankClaw_OnPlayerHit_Post",				true);
	CreateDetour(hGameData,			DTR_CTankClaw_OnPlayerHit_Pre,								DTR_CTankClaw_OnPlayerHit_Post,								"L4DD::CTankClaw::OnPlayerHit",										"L4D_TankClaw_OnPlayerHit_PostHandled",			true);
	CreateDetour(hGameData,			DTR_CTankRock_Detonate,										INVALID_FUNCTION,											"L4DD::CTankRock::Detonate",										"L4D_TankRock_OnDetonate");
	CreateDetour(hGameData,			DTR_CTankRock_OnRelease,									DTR_CTankRock_OnRelease_Post,								"L4DD::CTankRock::OnRelease",										"L4D_TankRock_OnRelease");
	CreateDetour(hGameData,			DTR_CTankRock_OnRelease,									DTR_CTankRock_OnRelease_Post,								"L4DD::CTankRock::OnRelease",										"L4D_TankRock_OnRelease_Post",					true);
	CreateDetour(hGameData,			DTR_CThrow_ActivateAbililty,								DTR_CThrow_ActivateAbililty_Post,							"L4DD::CThrow::ActivateAbililty",									"L4D_OnCThrowActivate");
	CreateDetour(hGameData,			DTR_CThrow_ActivateAbililty,								DTR_CThrow_ActivateAbililty_Post,							"L4DD::CThrow::ActivateAbililty",									"L4D_OnCThrowActivate_Post",					true);
	CreateDetour(hGameData,			DTR_CThrow_ActivateAbililty,								DTR_CThrow_ActivateAbililty_Post,							"L4DD::CThrow::ActivateAbililty",									"L4D_OnCThrowActivate_PostHandled",				true);
	g_iAnimationDetourIndex = g_iLargeIndex; // Animation Hook - detour index to enable when required.
	CreateDetour(hGameData,			DTR_CBaseAnimating_SelectWeightedSequence_Pre,				DTR_CBaseAnimating_SelectWeightedSequence_Post,				"L4DD::CBaseAnimating::SelectWeightedSequence",						"L4D2_OnSelectTankAttackPre");							// Animation Hook
	CreateDetour(hGameData,			DTR_CBaseAnimating_SelectWeightedSequence_Pre,				DTR_CBaseAnimating_SelectWeightedSequence_Post,				"L4DD::CBaseAnimating::SelectWeightedSequence",						"L4D2_OnSelectTankAttack",						true);	// Animation Hook
	CreateDetour(hGameData,			DTR_CTerrorPlayer_DoAnimationEvent_Pre,						DTR_CTerrorPlayer_DoAnimationEvent,							"L4DD::CTerrorPlayer::DoAnimationEvent",							"L4D_OnDoAnimationEvent");
	CreateDetour(hGameData,			DTR_CTerrorPlayer_DoAnimationEvent_Pre,						DTR_CTerrorPlayer_DoAnimationEvent,							"L4DD::CTerrorPlayer::DoAnimationEvent",							"L4D_OnDoAnimationEvent_Post",					true);
	CreateDetour(hGameData,			DTR_CTerrorPlayer_DoAnimationEvent_Pre,						DTR_CTerrorPlayer_DoAnimationEvent,							"L4DD::CTerrorPlayer::DoAnimationEvent",							"L4D_OnDoAnimationEvent_PostHandled",			true);
	CreateDetour(hGameData,			DTR_CDirectorVersusMode_EndVersusModeRound_Pre,				DTR_CDirectorVersusMode_EndVersusModeRound_Post,			"L4DD::CDirectorVersusMode::EndVersusModeRound",					"L4D2_OnEndVersusModeRound");
	CreateDetour(hGameData,			DTR_CDirectorVersusMode_EndVersusModeRound_Pre,				DTR_CDirectorVersusMode_EndVersusModeRound_Post,			"L4DD::CDirectorVersusMode::EndVersusModeRound",					"L4D2_OnEndVersusModeRound_Post",				true);
	CreateDetour(hGameData,			DTR_CDirectorVersusMode_EndVersusModeRound_Pre,				DTR_CDirectorVersusMode_EndVersusModeRound_Post,			"L4DD::CDirectorVersusMode::EndVersusModeRound",					"L4D2_OnEndVersusModeRound_PostHandled",		true);
	CreateDetour(hGameData,			DTR_CTerrorPlayer_OnLedgeGrabbed,							DTR_CTerrorPlayer_OnLedgeGrabbed_Post,						"L4DD::CTerrorPlayer::OnLedgeGrabbed",								"L4D_OnLedgeGrabbed");
	CreateDetour(hGameData,			DTR_CTerrorPlayer_OnLedgeGrabbed,							DTR_CTerrorPlayer_OnLedgeGrabbed_Post,						"L4DD::CTerrorPlayer::OnLedgeGrabbed",								"L4D_OnLedgeGrabbed_Post",						true);
	CreateDetour(hGameData,			DTR_CTerrorPlayer_OnLedgeGrabbed,							DTR_CTerrorPlayer_OnLedgeGrabbed_Post,						"L4DD::CTerrorPlayer::OnLedgeGrabbed",								"L4D_OnLedgeGrabbed_PostHandled",				true);
	CreateDetour(hGameData,			DTR_CTerrorPlayer_OnRevived_Pre,							DTR_CTerrorPlayer_OnRevived_Post,							"L4DD::CTerrorPlayer::OnRevived",									"L4D2_OnRevived");

	if( !g_bLinuxOS ) // Blocked on Linux in L4D1/L4D2 to prevent crashes. Waiting for DHooks update to support object returns.
	{
		CreateDetour(hGameData,		DTR_SurvivorBot_UseHealingItems,							INVALID_FUNCTION,											"L4DD::SurvivorBot::UseHealingItems",								"L4D2_OnUseHealingItems");
		CreateDetour(hGameData,		DTR_CDirectorScriptedEventManager_SendInRescueVehicle,		INVALID_FUNCTION,											"L4DD::CDirectorScriptedEventManager::SendInRescueVehicle",			"L4D2_OnSendInRescueVehicle");
	}

	CreateDetour(hGameData,			DTR_CDirector_TryOfferingTankBot,							DTR_CDirector_TryOfferingTankBot_Post,						"L4DD::CDirector::TryOfferingTankBot",								"L4D_OnTryOfferingTankBot");
	CreateDetour(hGameData,			DTR_CDirector_TryOfferingTankBot,							DTR_CDirector_TryOfferingTankBot_Post,						"L4DD::CDirector::TryOfferingTankBot",								"L4D_OnTryOfferingTankBot_Post",				true);
	CreateDetour(hGameData,			DTR_CDirector_TryOfferingTankBot,							DTR_CDirector_TryOfferingTankBot_Post,						"L4DD::CDirector::TryOfferingTankBot",								"L4D_OnTryOfferingTankBot_PostHandled",			true);
	CreateDetour(hGameData,			DTR_CTerrorWeapon_OnSwingStart,								INVALID_FUNCTION,											"L4DD::CTerrorWeapon::OnSwingStart",								"L4D_OnSwingStart");
	CreateDetour(hGameData,			DTR_CTerrorPlayer_OnShovedBySurvivor,						DTR_CTerrorPlayer_OnShovedBySurvivor_Post,					"L4DD::CTerrorPlayer::OnShovedBySurvivor",							"L4D_OnShovedBySurvivor");
	CreateDetour(hGameData,			DTR_CTerrorPlayer_OnShovedBySurvivor,						DTR_CTerrorPlayer_OnShovedBySurvivor_Post,					"L4DD::CTerrorPlayer::OnShovedBySurvivor",							"L4D_OnShovedBySurvivor_Post",					true);
	CreateDetour(hGameData,			DTR_CTerrorPlayer_OnShovedBySurvivor,						DTR_CTerrorPlayer_OnShovedBySurvivor_Post,					"L4DD::CTerrorPlayer::OnShovedBySurvivor",							"L4D_OnShovedBySurvivor_PostHandled",			true);
	CreateDetour(hGameData,			DTR_CTerrorPlayer_OnShovedBySurvivor,						DTR_CTerrorPlayer_OnShovedBySurvivor_Post,					"L4DD::CTerrorPlayer::OnShovedBySurvivor",							"L4D_OnShovedBySurvivor_PostHandled",			true);
	CreateDetour(hGameData,			DTR_CTerrorPlayer_OnStaggered,								DTR_CTerrorPlayer_OnStaggered_Post,							"L4DD::CTerrorPlayer::OnStaggered",									"L4D2_OnStagger");
	CreateDetour(hGameData,			DTR_CTerrorPlayer_OnStaggered,								DTR_CTerrorPlayer_OnStaggered_Post,							"L4DD::CTerrorPlayer::OnStaggered",									"L4D2_OnStagger_Post",							true);
	CreateDetour(hGameData,			DTR_CTerrorPlayer_OnStaggered,								DTR_CTerrorPlayer_OnStaggered_Post,							"L4DD::CTerrorPlayer::OnStaggered",									"L4D2_OnStagger_PostHandled",					true);

	if( !g_bLeft4Dead2 && g_bLinuxOS )
	{
		CreateDetour(hGameData,		DTR_CDirector_TryOfferingTankBot_Clone,						DTR_CDirector_TryOfferingTankBot_Clone_Post,				"L4DD::CDirector::TryOfferingTankBot_Clone",						"L4D_OnTryOfferingTankBot");
		CreateDetour(hGameData,		DTR_CDirector_TryOfferingTankBot_Clone,						DTR_CDirector_TryOfferingTankBot_Clone_Post,				"L4DD::CDirector::TryOfferingTankBot_Clone",						"L4D_OnTryOfferingTankBot_Post",				true);
		CreateDetour(hGameData,		DTR_CDirector_TryOfferingTankBot_Clone,						DTR_CDirector_TryOfferingTankBot_Clone_Post,				"L4DD::CDirector::TryOfferingTankBot_Clone",						"L4D_OnTryOfferingTankBot_PostHandled",			true);
		CreateDetour(hGameData,		DTR_CTerrorPlayer_OnShovedBySurvivor_Clone,					DTR_CTerrorPlayer_OnShovedBySurvivor_Clone_Post,			"L4DD::CTerrorPlayer::OnShovedBySurvivor_Clone",					"L4D_OnShovedBySurvivor");
		CreateDetour(hGameData,		DTR_CTerrorPlayer_OnShovedBySurvivor_Clone,					DTR_CTerrorPlayer_OnShovedBySurvivor_Clone_Post,			"L4DD::CTerrorPlayer::OnShovedBySurvivor_Clone",					"L4D_OnShovedBySurvivor_Post",					true);
		CreateDetour(hGameData,		DTR_CTerrorPlayer_OnShovedBySurvivor_Clone,					DTR_CTerrorPlayer_OnShovedBySurvivor_Clone_Post,			"L4DD::CTerrorPlayer::OnShovedBySurvivor_Clone",					"L4D_OnShovedBySurvivor_PostHandled",			true);
		CreateDetour(hGameData,		DTR_CTerrorPlayer_OnStaggered_Clone,						DTR_CTerrorPlayer_OnStaggered_Clone_Post,					"L4DD::CTerrorPlayer::OnStaggered_Clone",							"L4D2_OnStagger");
		CreateDetour(hGameData,		DTR_CTerrorPlayer_OnStaggered_Clone,						DTR_CTerrorPlayer_OnStaggered_Clone_Post,					"L4DD::CTerrorPlayer::OnStaggered_Clone",							"L4D2_OnStagger_Post",							true);
		CreateDetour(hGameData,		DTR_CTerrorPlayer_OnStaggered_Clone,						DTR_CTerrorPlayer_OnStaggered_Clone_Post,					"L4DD::CTerrorPlayer::OnStaggered_Clone",							"L4D2_OnStagger_PostHandled",					true);
	}

	CreateDetour(hGameData,			DTR_CTerrorWeapon_OnHit,									DTR_CTerrorWeapon_OnHit_Post,								"L4DD::CTerrorWeapon::OnHit",										"L4D2_OnEntityShoved");
	CreateDetour(hGameData,			DTR_CTerrorWeapon_OnHit,									DTR_CTerrorWeapon_OnHit_Post,								"L4DD::CTerrorWeapon::OnHit",										"L4D2_OnEntityShoved_Post",						true);
	CreateDetour(hGameData,			DTR_CTerrorWeapon_OnHit,									DTR_CTerrorWeapon_OnHit_Post,								"L4DD::CTerrorWeapon::OnHit",										"L4D2_OnEntityShoved_PostHandled",				true);
	CreateDetour(hGameData,			DTR_CTerrorPlayer_OnShovedByPounceLanding,					DTR_CTerrorPlayer_OnShovedByPounceLanding_Post,				"L4DD::CTerrorPlayer::OnShovedByPounceLanding",						"L4D2_OnPounceOrLeapStumble");
	CreateDetour(hGameData,			DTR_CTerrorPlayer_OnShovedByPounceLanding,					DTR_CTerrorPlayer_OnShovedByPounceLanding_Post,				"L4DD::CTerrorPlayer::OnShovedByPounceLanding",						"L4D2_OnPounceOrLeapStumble_Post",				true);
	CreateDetour(hGameData,			DTR_CTerrorPlayer_OnShovedByPounceLanding,					DTR_CTerrorPlayer_OnShovedByPounceLanding_Post,				"L4DD::CTerrorPlayer::OnShovedByPounceLanding",						"L4D2_OnPounceOrLeapStumble_PostHandled",		true);
	CreateDetour(hGameData,			DTR_CDeathFallCamera_Enable,								INVALID_FUNCTION,											"L4DD::CDeathFallCamera::Enable",									"L4D_OnFatalFalling");
	CreateDetour(hGameData,			DTR_CTerrorPlayer_OnFalling_Pre,							DTR_CTerrorPlayer_OnFalling_Post,							"L4DD::CTerrorPlayer::OnFalling",									"L4D_OnFalling");
	CreateDetour(hGameData,			DTR_CTerrorPlayer_Cough,									DTR_CTerrorPlayer_Cough_Post,								"L4DD::CTerrorPlayer::Cough",										"L4D_OnPlayerCough");
	CreateDetour(hGameData,			DTR_CTerrorPlayer_Cough,									DTR_CTerrorPlayer_Cough_Post,								"L4DD::CTerrorPlayer::Cough",										"L4D_OnPlayerCough_Post",						true);
	CreateDetour(hGameData,			DTR_CTerrorPlayer_Cough,									DTR_CTerrorPlayer_Cough_Post,								"L4DD::CTerrorPlayer::Cough",										"L4D_OnPlayerCough_PostHandled",				true);
	CreateDetour(hGameData,			DTR_Witch_SetHarasser,										INVALID_FUNCTION,											"L4DD::Witch::SetHarasser",											"L4D_OnWitchSetHarasser");
	CreateDetour(hGameData,			DTR_Tank_EnterStasis_Pre,									DTR_Tank_EnterStasis_Post,									"L4DD::Tank::EnterStasis",											"L4D_OnEnterStasis");
	CreateDetour(hGameData,			DTR_Tank_LeaveStasis_Pre,									DTR_Tank_LeaveStasis_Post,									"L4DD::Tank::LeaveStasis",											"L4D_OnLeaveStasis");
	CreateDetour(hGameData,			DTR_CInferno_Spread,										INVALID_FUNCTION,											"L4DD::CInferno::Spread",											"L4D2_OnSpitSpread");
	CreateDetour(hGameData,			DTR_SurvivorBot_FindScavengeItem_Pre,						DTR_SurvivorBot_FindScavengeItem_Post,						"L4DD::SurvivorBot::FindScavengeItem",								"L4D2_OnFindScavengeItem");
	CreateDetour(hGameData,			DTR_BossZombiePlayerBot_ChooseVictim_Pre,					DTR_BossZombiePlayerBot_ChooseVictim_Post,					"L4DD::BossZombiePlayerBot::ChooseVictim",							"L4D2_OnChooseVictim");
	CreateDetour(hGameData,			DTR_CTerrorPlayer_MaterializeFromGhost_Pre,					DTR_CTerrorPlayer_MaterializeFromGhost_Post,				"L4DD::CTerrorPlayer::MaterializeFromGhost",						"L4D_OnMaterializeFromGhostPre");
	CreateDetour(hGameData,			DTR_CTerrorPlayer_MaterializeFromGhost_Pre,					DTR_CTerrorPlayer_MaterializeFromGhost_Post,				"L4DD::CTerrorPlayer::MaterializeFromGhost",						"L4D_OnMaterializeFromGhost",					true);
	CreateDetour(hGameData,			DTR_CPipeBombProjectile_Create_Pre,							DTR_CPipeBombProjectile_Create_Post,						"L4DD::CPipeBombProjectile::Create",								"L4D_PipeBombProjectile_Pre");
	CreateDetour(hGameData,			DTR_CPipeBombProjectile_Create_Pre,							DTR_CPipeBombProjectile_Create_Post,						"L4DD::CPipeBombProjectile::Create",								"L4D_PipeBombProjectile_Post",					true);
	CreateDetour(hGameData,			DTR_CPipeBombProjectile_Create_Pre,							DTR_CPipeBombProjectile_Create_Post,						"L4DD::CPipeBombProjectile::Create",								"L4D_PipeBombProjectile_PostHandled",			true);
	CreateDetour(hGameData,			DTR_CMolotovProjectile_Detonate_Pre,						DTR_CMolotovProjectile_Detonate,							"L4DD::CMolotovProjectile::Detonate",								"L4D_Molotov_Detonate");
	CreateDetour(hGameData,			DTR_CMolotovProjectile_Detonate_Pre,						DTR_CMolotovProjectile_Detonate,							"L4DD::CMolotovProjectile::Detonate",								"L4D_Molotov_Detonate_Post",					true);
	CreateDetour(hGameData,			DTR_CMolotovProjectile_Detonate_Pre,						DTR_CMolotovProjectile_Detonate,							"L4DD::CMolotovProjectile::Detonate",								"L4D_Molotov_Detonate_PostHandled",				true);
	CreateDetour(hGameData,			DTR_CPipeBombProjectile_Detonate_Pre,						DTR_CPipeBombProjectile_Detonate,							"L4DD::CPipeBombProjectile::Detonate",								"L4D_PipeBomb_Detonate");
	CreateDetour(hGameData,			DTR_CPipeBombProjectile_Detonate_Pre,						DTR_CPipeBombProjectile_Detonate,							"L4DD::CPipeBombProjectile::Detonate",								"L4D_PipeBomb_Detonate_Post",					true);
	CreateDetour(hGameData,			DTR_CPipeBombProjectile_Detonate_Pre,						DTR_CPipeBombProjectile_Detonate,							"L4DD::CPipeBombProjectile::Detonate",								"L4D_PipeBomb_Detonate_PostHandled",			true);
	CreateDetour(hGameData,			DTR_CTerrorPlayer_Extinguish,								INVALID_FUNCTION,											"L4DD::CTerrorPlayer::Extinguish",									"L4D_PlayerExtinguish");
	CreateDetour(hGameData,			DTR_CBreakableProp_Break_Pre,								DTR_CBreakableProp_Break_Post,								"L4DD::CBreakableProp::Break",										"L4D_CBreakableProp_Break");
	CreateDetour(hGameData,			DTR_CTerrorPlayer_OnVomitedUpon,							DTR_CTerrorPlayer_OnVomitedUpon_Post,						"L4DD::CTerrorPlayer::OnVomitedUpon",								"L4D_OnVomitedUpon");
	CreateDetour(hGameData,			DTR_CTerrorPlayer_OnVomitedUpon,							DTR_CTerrorPlayer_OnVomitedUpon_Post,						"L4DD::CTerrorPlayer::OnVomitedUpon",								"L4D_OnVomitedUpon_Post",						true);
	CreateDetour(hGameData,			DTR_CTerrorPlayer_OnVomitedUpon,							DTR_CTerrorPlayer_OnVomitedUpon_Post,						"L4DD::CTerrorPlayer::OnVomitedUpon",								"L4D_OnVomitedUpon_PostHandled",				true);
	CreateDetour(hGameData,			DTR_CTerrorPlayer_OnPouncedOnSurvivor,						DTR_CTerrorPlayer_OnPouncedOnSurvivor_Post,					"L4DD::CTerrorPlayer::OnPouncedOnSurvivor",							"L4D_OnPouncedOnSurvivor");
	CreateDetour(hGameData,			DTR_CTerrorPlayer_OnPouncedOnSurvivor,						DTR_CTerrorPlayer_OnPouncedOnSurvivor_Post,					"L4DD::CTerrorPlayer::OnPouncedOnSurvivor",							"L4D_OnPouncedOnSurvivor_Post",					true);
	CreateDetour(hGameData,			DTR_CTerrorPlayer_OnPouncedOnSurvivor,						DTR_CTerrorPlayer_OnPouncedOnSurvivor_Post,					"L4DD::CTerrorPlayer::OnPouncedOnSurvivor",							"L4D_OnPouncedOnSurvivor_PostHandled",			true);
	CreateDetour(hGameData,			DTR_CTerrorPlayer_OnKnockedDown,							DTR_CTerrorPlayer_OnKnockedDown_Post,						"L4DD::CTerrorPlayer::OnKnockedDown",								"L4D_OnKnockedDown");
	CreateDetour(hGameData,			DTR_CTerrorPlayer_OnKnockedDown,							DTR_CTerrorPlayer_OnKnockedDown_Post,						"L4DD::CTerrorPlayer::OnKnockedDown",								"L4D_OnKnockedDown_Post",						true);
	CreateDetour(hGameData,			DTR_CTerrorPlayer_OnKnockedDown,							DTR_CTerrorPlayer_OnKnockedDown_Post,						"L4DD::CTerrorPlayer::OnKnockedDown",								"L4D_OnKnockedDown_PostHandled",				true);
	CreateDetour(hGameData,			DTR_CTerrorPlayer_GrabVictimWithTongue,						DTR_CTerrorPlayer_GrabVictimWithTongue_Post,				"L4DD::CTerrorPlayer::GrabVictimWithTongue",						"L4D_OnGrabWithTongue");
	CreateDetour(hGameData,			DTR_CTerrorPlayer_GrabVictimWithTongue,						DTR_CTerrorPlayer_GrabVictimWithTongue_Post,				"L4DD::CTerrorPlayer::GrabVictimWithTongue",						"L4D_OnGrabWithTongue_Post",					true);
	CreateDetour(hGameData,			DTR_CTerrorPlayer_GrabVictimWithTongue,						DTR_CTerrorPlayer_GrabVictimWithTongue_Post,				"L4DD::CTerrorPlayer::GrabVictimWithTongue",						"L4D_OnGrabWithTongue_PostHandled",				true);
	CreateDetour(hGameData,			DTR_CServerGameDLL_ServerHibernationUpdate,					INVALID_FUNCTION,											"L4DD::CServerGameDLL::ServerHibernationUpdate",					"L4D_OnServerHibernationUpdate");
	CreateDetour(hGameData,			DTR_CTerrorPlayer_IsMotionControlledXY,						INVALID_FUNCTION,											"L4DD::CTerrorPlayer::IsMotionControlledXY",						"L4D_OnMotionControlledXY");
	CreateDetour(hGameData,			DTR_CTerrorPlayer_CancelStagger,							DTR_CTerrorPlayer_CancelStagger_Post,						"L4DD::CTerrorPlayer::CancelStagger",								"L4D_OnCancelStagger");
	CreateDetour(hGameData,			DTR_CTerrorPlayer_CancelStagger,							DTR_CTerrorPlayer_CancelStagger_Post,						"L4DD::CTerrorPlayer::CancelStagger",								"L4D_OnCancelStagger_Post",						true);
	CreateDetour(hGameData,			DTR_CTerrorPlayer_CancelStagger,							DTR_CTerrorPlayer_CancelStagger_Post,						"L4DD::CTerrorPlayer::CancelStagger",								"L4D_OnCancelStagger_PostHandled",				true);

	if( !g_bLeft4Dead2 )
	{
		// Different detours, same forward (L4D_OnSpawnSpecial).
		CreateDetour(hGameData,		DTR_ZombieManager_SpawnHunter,								DTR_ZombieManager_SpawnHunter_Post,							"L4DD::ZombieManager::SpawnHunter",									"L4D_OnSpawnSpecial");
		CreateDetour(hGameData,		DTR_ZombieManager_SpawnHunter,								DTR_ZombieManager_SpawnHunter_Post,							"L4DD::ZombieManager::SpawnHunter",									"L4D_OnSpawnSpecial_Post",						true);
		CreateDetour(hGameData,		DTR_ZombieManager_SpawnHunter,								DTR_ZombieManager_SpawnHunter_Post,							"L4DD::ZombieManager::SpawnHunter",									"L4D_OnSpawnSpecial_PostHandled",				true);
		CreateDetour(hGameData,		DTR_ZombieManager_SpawnBoomer,								DTR_ZombieManager_SpawnBoomer_Post,							"L4DD::ZombieManager::SpawnBoomer",									"L4D_OnSpawnSpecial");
		CreateDetour(hGameData,		DTR_ZombieManager_SpawnBoomer,								DTR_ZombieManager_SpawnBoomer_Post,							"L4DD::ZombieManager::SpawnBoomer",									"L4D_OnSpawnSpecial_Post",						true);
		CreateDetour(hGameData,		DTR_ZombieManager_SpawnBoomer,								DTR_ZombieManager_SpawnBoomer_Post,							"L4DD::ZombieManager::SpawnBoomer",									"L4D_OnSpawnSpecial_PostHandled",				true);
		CreateDetour(hGameData,		DTR_ZombieManager_SpawnSmoker,								DTR_ZombieManager_SpawnSmoker_Post,							"L4DD::ZombieManager::SpawnSmoker",									"L4D_OnSpawnSpecial");
		CreateDetour(hGameData,		DTR_ZombieManager_SpawnSmoker,								DTR_ZombieManager_SpawnSmoker_Post,							"L4DD::ZombieManager::SpawnSmoker",									"L4D_OnSpawnSpecial_Post",						true);
		CreateDetour(hGameData,		DTR_ZombieManager_SpawnSmoker,								DTR_ZombieManager_SpawnSmoker_Post,							"L4DD::ZombieManager::SpawnSmoker",									"L4D_OnSpawnSpecial_PostHandled",				true);
		if( !g_bLinuxOS )
		{
			CreateDetour(hGameData,	DTR_CFirstAidKit_StartHealing_WIN,							DTR_CFirstAidKit_StartHealing_Post_WIN,						"L4DD::CFirstAidKit::StartHealing",									"L4D1_FirstAidKit_StartHealing");
			CreateDetour(hGameData,	DTR_CFirstAidKit_StartHealing_WIN,							DTR_CFirstAidKit_StartHealing_Post_WIN,						"L4DD::CFirstAidKit::StartHealing",									"L4D1_FirstAidKit_StartHealing_Post",			true);
			CreateDetour(hGameData,	DTR_CFirstAidKit_StartHealing_WIN,							DTR_CFirstAidKit_StartHealing_Post_WIN,						"L4DD::CFirstAidKit::StartHealing",									"L4D1_FirstAidKit_StartHealing_PostHandled",	true);
		}
		else
		{
			CreateDetour(hGameData,	DTR_CFirstAidKit_StartHealing_NIX,							DTR_CFirstAidKit_StartHealing_Post_NIX,						"L4DD::CFirstAidKit::StartHealing",									"L4D1_FirstAidKit_StartHealing");
			CreateDetour(hGameData,	DTR_CFirstAidKit_StartHealing_NIX,							DTR_CFirstAidKit_StartHealing_Post_NIX,						"L4DD::CFirstAidKit::StartHealing",									"L4D1_FirstAidKit_StartHealing_Post",			true);
			CreateDetour(hGameData,	DTR_CFirstAidKit_StartHealing_NIX,							DTR_CFirstAidKit_StartHealing_Post_NIX,						"L4DD::CFirstAidKit::StartHealing",									"L4D1_FirstAidKit_StartHealing_PostHandled",	true);
		}
	}
	else
	{
		CreateDetour(hGameData,		DTR_ZombieManager_SpawnSpecial,								DTR_ZombieManager_SpawnSpecial_Post,						"L4DD::ZombieManager::SpawnSpecial",								"L4D_OnSpawnSpecial");
		CreateDetour(hGameData,		DTR_ZombieManager_SpawnSpecial,								DTR_ZombieManager_SpawnSpecial_Post,						"L4DD::ZombieManager::SpawnSpecial",								"L4D_OnSpawnSpecial_Post",						true);
		CreateDetour(hGameData,		DTR_ZombieManager_SpawnSpecial,								DTR_ZombieManager_SpawnSpecial_Post,						"L4DD::ZombieManager::SpawnSpecial",								"L4D_OnSpawnSpecial_PostHandled",				true);
		// CreateDetour(hGameData,		DTR_ZombieManager_SpawnSpecial_Clone,						DTR_ZombieManager_SpawnSpecial_Post_Clone,					"L4DD::ZombieManager::SpawnSpecial_Clone",							"L4D_OnSpawnSpecial");
		// CreateDetour(hGameData,		DTR_ZombieManager_SpawnSpecial_Clone,						DTR_ZombieManager_SpawnSpecial_Post_Clone,					"L4DD::ZombieManager::SpawnSpecial_Clone",							"L4D_OnSpawnSpecial_Post",						true);
		// CreateDetour(hGameData,		DTR_ZombieManager_SpawnSpecial_Clone,						DTR_ZombieManager_SpawnSpecial_Post_Clone,					"L4DD::ZombieManager::SpawnSpecial_Clone",							"L4D_OnSpawnSpecial_PostHandled",				true);

		CreateDetour(hGameData,		DTR_CTerrorPlayer_OnLeptOnSurvivor,							DTR_CTerrorPlayer_OnLeptOnSurvivor_Post,					"L4DD::CTerrorPlayer::OnLeptOnSurvivor",							"L4D2_OnJockeyRide");
		CreateDetour(hGameData,		DTR_CTerrorPlayer_OnLeptOnSurvivor,							DTR_CTerrorPlayer_OnLeptOnSurvivor_Post,					"L4DD::CTerrorPlayer::OnLeptOnSurvivor",							"L4D2_OnJockeyRide_Post",						true);
		CreateDetour(hGameData,		DTR_CTerrorPlayer_OnLeptOnSurvivor,							DTR_CTerrorPlayer_OnLeptOnSurvivor_Post,					"L4DD::CTerrorPlayer::OnLeptOnSurvivor",							"L4D2_OnJockeyRide_PostHandled",				true);
		CreateDetour(hGameData,		DTR_CTerrorPlayer_OnStartCarryingVictim,					DTR_CTerrorPlayer_OnStartCarryingVictim_Post,				"L4DD::CTerrorPlayer::OnStartCarryingVictim",						"L4D2_OnStartCarryingVictim");
		CreateDetour(hGameData,		DTR_CTerrorPlayer_OnStartCarryingVictim,					DTR_CTerrorPlayer_OnStartCarryingVictim_Post,				"L4DD::CTerrorPlayer::OnStartCarryingVictim",						"L4D2_OnStartCarryingVictim_Post",				true);
		CreateDetour(hGameData,		DTR_CTerrorPlayer_OnStartCarryingVictim,					DTR_CTerrorPlayer_OnStartCarryingVictim_Post,				"L4DD::CTerrorPlayer::OnStartCarryingVictim",						"L4D2_OnStartCarryingVictim_PostHandled",		true);
		CreateDetour(hGameData,		DTR_CCharge_ImpactStagger,									INVALID_FUNCTION,											"L4DD::CCharge::ImpactStagger",										"L4D2_OnChargerImpact");
		CreateDetour(hGameData,		DTR_CGasCanEvent_Killed,									DTR_CGasCanEvent_Killed_Post,								"L4DD::CGasCan::Event_Killed",										"L4D2_CGasCan_EventKilled");
		CreateDetour(hGameData,		DTR_CGasCanEvent_Killed,									DTR_CGasCanEvent_Killed_Post,								"L4DD::CGasCan::Event_Killed",										"L4D2_CGasCan_EventKilled_Post",				true);
		CreateDetour(hGameData,		DTR_CGasCanEvent_Killed,									DTR_CGasCanEvent_Killed_Post,								"L4DD::CGasCan::Event_Killed",										"L4D2_CGasCan_EventKilled_PostHandled",			true);
		CreateDetour(hGameData,		DTR_CGasCan_ShouldStartAction,								DTR_CGasCan_ShouldStartAction_Post,							"L4DD::CGasCan::ShouldStartAction",									"L4D2_CGasCan_ShouldStartAction");
		CreateDetour(hGameData,		DTR_CGasCan_ShouldStartAction,								DTR_CGasCan_ShouldStartAction_Post,							"L4DD::CGasCan::ShouldStartAction",									"L4D2_CGasCan_ShouldStartAction_Post",			true);
		CreateDetour(hGameData,		DTR_CGasCan_ShouldStartAction,								DTR_CGasCan_ShouldStartAction_Post,							"L4DD::CGasCan::ShouldStartAction",									"L4D2_CGasCan_ShouldStartAction_PostHandled",	true);
		CreateDetour(hGameData,		DTR_CGasCan_OnActionComplete,								DTR_CGasCan_OnActionComplete_Post,							"L4DD::CGasCan::OnActionComplete",									"L4D2_CGasCan_ActionComplete");
		CreateDetour(hGameData,		DTR_CGasCan_OnActionComplete,								DTR_CGasCan_OnActionComplete_Post,							"L4DD::CGasCan::OnActionComplete",									"L4D2_CGasCan_ActionComplete_Post",				true);
		CreateDetour(hGameData,		DTR_CGasCan_OnActionComplete,								DTR_CGasCan_OnActionComplete_Post,							"L4DD::CGasCan::OnActionComplete",									"L4D2_CGasCan_ActionComplete_PostHandled",		true);
		CreateDetour(hGameData,		DTR_CBaseBackpackItem_StartAction,							DTR_CBaseBackpackItem_StartAction_Post,						"L4DD::CBaseBackpackItem::StartAction",								"L4D2_BackpackItem_StartAction");
		CreateDetour(hGameData,		DTR_CBaseBackpackItem_StartAction,							DTR_CBaseBackpackItem_StartAction_Post,						"L4DD::CBaseBackpackItem::StartAction",								"L4D2_BackpackItem_StartAction_Post",			true);
		CreateDetour(hGameData,		DTR_CBaseBackpackItem_StartAction,							DTR_CBaseBackpackItem_StartAction_Post,						"L4DD::CBaseBackpackItem::StartAction",								"L4D2_BackpackItem_StartAction_PostHandled",	true);
		CreateDetour(hGameData,		DTR_CVomitJarProjectile_Detonate_Pre,						DTR_CVomitJarProjectile_Detonate,							"L4DD::CVomitJarProjectile::Detonate",								"L4D2_VomitJar_Detonate");
		CreateDetour(hGameData,		DTR_CVomitJarProjectile_Detonate_Pre,						DTR_CVomitJarProjectile_Detonate,							"L4DD::CVomitJarProjectile::Detonate",								"L4D2_VomitJar_Detonate_Post",					true);
		CreateDetour(hGameData,		DTR_CVomitJarProjectile_Detonate_Pre,						DTR_CVomitJarProjectile_Detonate,							"L4DD::CVomitJarProjectile::Detonate",								"L4D2_VomitJar_Detonate_PostHandled",			true);
		CreateDetour(hGameData,		DTR_CInsectSwarm_CanHarm,									DTR_CInsectSwarm_CanHarm_Post,								"L4DD::CInsectSwarm::CanHarm",										"L4D2_CInsectSwarm_CanHarm");
		CreateDetour(hGameData,		DTR_CInsectSwarm_CanHarm,									DTR_CInsectSwarm_CanHarm_Post,								"L4DD::CInsectSwarm::CanHarm",										"L4D2_CInsectSwarm_CanHarm_Post",				true);
		CreateDetour(hGameData,		DTR_CInsectSwarm_CanHarm,									DTR_CInsectSwarm_CanHarm_Post,								"L4DD::CInsectSwarm::CanHarm",										"L4D2_CInsectSwarm_CanHarm_PostHandled",		true);
		CreateDetour(hGameData,		DTR_CTerrorPlayer_Fling,									DTR_CTerrorPlayer_Fling_Post,								"L4DD::CTerrorPlayer::Fling",										"L4D2_OnPlayerFling");
		CreateDetour(hGameData,		DTR_CTerrorPlayer_Fling,									DTR_CTerrorPlayer_Fling_Post,								"L4DD::CTerrorPlayer::Fling",										"L4D2_OnPlayerFling_Post",						true);
		CreateDetour(hGameData,		DTR_CTerrorPlayer_Fling,									DTR_CTerrorPlayer_Fling_Post,								"L4DD::CTerrorPlayer::Fling",										"L4D2_OnPlayerFling_PostHandled",				true);
		CreateDetour(hGameData,		DTR_CTerrorPlayer_OnSlammedSurvivor,						DTR_CTerrorPlayer_OnSlammedSurvivor_Post,					"L4DD::CTerrorPlayer::OnSlammedSurvivor",							"L4D2_OnSlammedSurvivor");
		CreateDetour(hGameData,		DTR_CTerrorPlayer_OnSlammedSurvivor,						DTR_CTerrorPlayer_OnSlammedSurvivor_Post,					"L4DD::CTerrorPlayer::OnSlammedSurvivor",							"L4D2_OnSlammedSurvivor_Post",					true);
		CreateDetour(hGameData,		DTR_CTerrorPlayer_OnSlammedSurvivor,						DTR_CTerrorPlayer_OnSlammedSurvivor_Post,					"L4DD::CTerrorPlayer::OnSlammedSurvivor",							"L4D2_OnSlammedSurvivor_PostHandled",			true);
		CreateDetour(hGameData,		DTR_CTerrorPlayer_QueuePummelVictim,						DTR_CTerrorPlayer_QueuePummelVictim_Post,					"L4DD::CTerrorPlayer::QueuePummelVictim",							"L4D2_OnPummelVictim");
		CreateDetour(hGameData,		DTR_CTerrorPlayer_QueuePummelVictim,						DTR_CTerrorPlayer_QueuePummelVictim_Post,					"L4DD::CTerrorPlayer::QueuePummelVictim",							"L4D2_OnPummelVictim_Post",						true);
		CreateDetour(hGameData,		DTR_CTerrorPlayer_QueuePummelVictim,						DTR_CTerrorPlayer_QueuePummelVictim_Post,					"L4DD::CTerrorPlayer::QueuePummelVictim",							"L4D2_OnPummelVictim_PostHandled",				true);
		CreateDetour(hGameData,		DTR_ThrowImpactedSurvivor,									DTR_ThrowImpactedSurvivor_Post,								"L4DD::ThrowImpactedSurvivor",										"L4D2_OnThrowImpactedSurvivor");
		CreateDetour(hGameData,		DTR_ThrowImpactedSurvivor,									DTR_ThrowImpactedSurvivor_Post,								"L4DD::ThrowImpactedSurvivor",										"L4D2_OnThrowImpactedSurvivor_Post",			true);
		CreateDetour(hGameData,		DTR_ThrowImpactedSurvivor,									DTR_ThrowImpactedSurvivor_Post,								"L4DD::ThrowImpactedSurvivor",										"L4D2_OnThrowImpactedSurvivor_PostHandled",		true);
		CreateDetour(hGameData,		DTR_CTerrorPlayer_OnHitByVomitJar,							DTR_CTerrorPlayer_OnHitByVomitJar_Post,						"L4DD::CTerrorPlayer::OnHitByVomitJar",								"L4D2_OnHitByVomitJar");
		CreateDetour(hGameData,		DTR_CTerrorPlayer_OnHitByVomitJar,							DTR_CTerrorPlayer_OnHitByVomitJar_Post,						"L4DD::CTerrorPlayer::OnHitByVomitJar",								"L4D2_OnHitByVomitJar_Post",					true);
		CreateDetour(hGameData,		DTR_CTerrorPlayer_OnHitByVomitJar,							DTR_CTerrorPlayer_OnHitByVomitJar_Post,						"L4DD::CTerrorPlayer::OnHitByVomitJar",								"L4D2_OnHitByVomitJar_PostHandled",				true);
		CreateDetour(hGameData,		DTR_ZombieManager_SpawnWitchBride,							DTR_ZombieManager_SpawnWitchBride_Post,						"L4DD::ZombieManager::SpawnWitchBride",								"L4D2_OnSpawnWitchBride");
		CreateDetour(hGameData,		DTR_ZombieManager_SpawnWitchBride,							DTR_ZombieManager_SpawnWitchBride_Post,						"L4DD::ZombieManager::SpawnWitchBride",								"L4D2_OnSpawnWitchBride_Post",					true);
		CreateDetour(hGameData,		DTR_ZombieManager_SpawnWitchBride,							DTR_ZombieManager_SpawnWitchBride_Post,						"L4DD::ZombieManager::SpawnWitchBride",								"L4D2_OnSpawnWitchBride_PostHandled",			true);
		CreateDetour(hGameData,		DTR_CDirector_GetScriptValueInt_Pre,						DTR_CDirector_GetScriptValueInt,							"L4DD::CDirector::GetScriptValueInt",								"L4D_OnGetScriptValueInt");
		CreateDetour(hGameData,		DTR_CDirector_GetScriptValueFloat_Pre,						DTR_CDirector_GetScriptValueFloat,							"L4DD::CDirector::GetScriptValueFloat",								"L4D_OnGetScriptValueFloat");
		// CreateDetour(hGameData,		DTR_CDirector_GetScriptValueVector_Pre,						DTR_CDirector_GetScriptValueVector,							"L4DD::CDirector::GetScriptValueVector",							"L4D_OnGetScriptValueVector");
		CreateDetour(hGameData,		DTR_CDirector_GetScriptValueString_Pre,						DTR_CDirector_GetScriptValueString,							"L4DD::CDirector::GetScriptValueString",							"L4D_OnGetScriptValueString");

		g_iScriptVMDetourIndex = g_iSmallIndex;
		CreateDetour(hGameData,		INVALID_FUNCTION,											DTR_CSquirrelVM_GetValue,									"L4DD::ScriptVM",													"L4D2_OnGetScriptValueInt",						false,				g_hScriptHook,		g_pScriptVM);
		CreateDetour(hGameData,		INVALID_FUNCTION,											DTR_CSquirrelVM_GetValue,									"L4DD::ScriptVM",													"L4D2_OnGetScriptValueFloat",					true,				g_hScriptHook,		g_pScriptVM);
		CreateDetour(hGameData,		INVALID_FUNCTION,											DTR_CSquirrelVM_GetValue,									"L4DD::ScriptVM",													"L4D2_OnGetScriptValueVector",					true,				g_hScriptHook,		g_pScriptVM);
		CreateDetour(hGameData,		INVALID_FUNCTION,											DTR_CSquirrelVM_GetValue,									"L4DD::ScriptVM",													"L4D2_OnGetScriptValueVoid",					true,				g_hScriptHook,		g_pScriptVM);

		CreateDetour(hGameData,		DTR_CTerrorGameRules_HasConfigurableDifficultySetting,		DTR_CTerrorGameRules_HasConfigurableDifficultySetting_Post,	"L4DD::CTerrorGameRules::HasConfigurableDifficultySetting",			"L4D_OnHasConfigurableDifficulty");
		CreateDetour(hGameData,		DTR_CTerrorGameRules_HasConfigurableDifficultySetting,		DTR_CTerrorGameRules_HasConfigurableDifficultySetting_Post,	"L4DD::CTerrorGameRules::HasConfigurableDifficultySetting",			"L4D_OnHasConfigurableDifficulty_Post",			true);
		CreateDetour(hGameData,		DTR_CTerrorGameRules_GetSurvivorSet_Pre,					DTR_CTerrorGameRules_GetSurvivorSet,						"L4DD::CTerrorGameRules::GetSurvivorSet",							"L4D_OnGetSurvivorSet");
		CreateDetour(hGameData,		DTR_CTerrorGameRules_FastGetSurvivorSet_Pre,				DTR_CTerrorGameRules_FastGetSurvivorSet,					"L4DD::CTerrorGameRules::FastGetSurvivorSet",						"L4D_OnFastGetSurvivorSet");
		CreateDetour(hGameData,		DTR_CTerrorMeleeWeapon_StartMeleeSwing,						DTR_CTerrorMeleeWeapon_StartMeleeSwing_Post,				"L4DD::CTerrorMeleeWeapon::StartMeleeSwing",						"L4D_OnStartMeleeSwing");
		CreateDetour(hGameData,		DTR_CTerrorMeleeWeapon_StartMeleeSwing,						DTR_CTerrorMeleeWeapon_StartMeleeSwing_Post,				"L4DD::CTerrorMeleeWeapon::StartMeleeSwing",						"L4D_OnStartMeleeSwing_Post",					true);
		CreateDetour(hGameData,		DTR_CTerrorMeleeWeapon_StartMeleeSwing,						DTR_CTerrorMeleeWeapon_StartMeleeSwing_Post,				"L4DD::CTerrorMeleeWeapon::StartMeleeSwing",						"L4D_OnStartMeleeSwing_PostHandled",			true);
		CreateDetour(hGameData,		DTR_CTerrorMeleeWeapon_GetDamageForVictim_Pre,				DTR_CTerrorMeleeWeapon_GetDamageForVictim_Post,				"L4DD::CTerrorMeleeWeapon::GetDamageForVictim",						"L4D2_MeleeGetDamageForVictim");
		CreateDetour(hGameData,		DTR_CDirectorScriptedEventManager_ChangeFinaleStage,		DTR_CDirectorScriptedEventManager_ChangeFinaleStage_Post,	"L4DD::CDirectorScriptedEventManager::ChangeFinaleStage",			"L4D2_OnChangeFinaleStage");
		CreateDetour(hGameData,		DTR_CDirectorScriptedEventManager_ChangeFinaleStage,		DTR_CDirectorScriptedEventManager_ChangeFinaleStage_Post,	"L4DD::CDirectorScriptedEventManager::ChangeFinaleStage",			"L4D2_OnChangeFinaleStage_Post",				true);
		CreateDetour(hGameData,		DTR_CDirectorScriptedEventManager_ChangeFinaleStage,		DTR_CDirectorScriptedEventManager_ChangeFinaleStage_Post,	"L4DD::CDirectorScriptedEventManager::ChangeFinaleStage",			"L4D2_OnChangeFinaleStage_PostHandled",			true);
		CreateDetour(hGameData,		DTR_AddonsDisabler,											INVALID_FUNCTION,											"L4DD::CBaseServer::FillServerInfo",								"L4D2_OnClientDisableAddons",					false,				null,				Address_Null,		true); // Force detour to enable.
	}

	// Deprecated, unused or broken.
	// CreateDetour(hGameData,			DTR_ZombieManager_GetRandomPZSpawnPosition,					INVALID_FUNCTION,											"L4DD::ZombieManager::GetRandomPZSpawnPosition",					"L4D_OnGetRandomPZSpawnPosition");
	// CreateDetour(hGameData,			DTR_InfectedShoved_OnShoved,								INVALID_FUNCTION,											"L4DD::InfectedShoved::OnShoved",									"L4D_OnInfectedShoved"); // Missing signature
	// CreateDetour(hGameData,			DTR_CBasePlayer_WaterMove_Pre,								DTR_CBasePlayer_WaterMove_Post,								"L4DD::CBasePlayer::WaterMove",										"L4D2_OnWaterMove"); // Does not return water state. Use FL_INWATER instead.

	g_bCreatedDetours = true;
}

void CreateDetour(GameData hGameData, DHookCallback fCallback, DHookCallback fPostCallback, const char[] sName, const char[] sForward, bool useLast = false, DynamicHook hHook = null, Address hAddress = Address_Null, bool forceOn = false)
{
	if( g_bCreatedDetours == false )
	{
		// Set forward names and indexes
		static int index;
		if( useLast ) index -= 1;

		g_aGameDataSigs.PushString(sName);
		g_aForwardNames.PushString(sForward);
		g_aUseLastIndex.Push(useLast);
		g_aForwardIndex.Push(index);
		g_aForceDetours.Push(forceOn);

		index++;

		// Setup detours
		if( !useLast )
		{
			// DynamicHook
			if( hHook )
			{
				g_aDetourHookIDsPre.Push(INVALID_HOOK_ID);
				g_aDetourHookIDsPost.Push(INVALID_HOOK_ID);
				g_aDetoursHooked.Push(0);
				g_aDetourHandles.Push(0);
			}
			// DynamicDetour
			else
			{
				DynamicDetour hDetour = DynamicDetour.FromConf(hGameData, sName);
				if( !hDetour ) LogError("Failed to load detour \"%s\" signature (%s).", sName, g_sSystem);

				g_aDetoursHooked.Push(0);			// Default disabled
				g_aDetourHandles.Push(hDetour);		// Store handle

				g_aDetourHookIDsPre.Push(INVALID_HOOK_ID);
				g_aDetourHookIDsPost.Push(INVALID_HOOK_ID);
			}
		}
	}
	else
	{
		// Enable detours
		if( !useLast ) // When using the last index, the pre and post detours are already hooked. Pre is always hooked even when only using post, to avoid crashes from dhooks.
		{
			int current = g_aDetoursHooked.Get(g_iSmallIndex);
			if( current < 0 )
			{
				DynamicDetour hDetour = g_aDetourHandles.Get(g_iSmallIndex);
				if( hDetour != null )
				{
					if( current == -1 )
					{
						g_aDetoursHooked.Set(g_iSmallIndex, 1);
						#if defined DEBUG
						#if DEBUG
						PrintToServer("Enabling detour %d %s", g_iSmallIndex, sName);
						#endif
						#endif

						if( fCallback != INVALID_FUNCTION && !hDetour.Enable(Hook_Pre, fCallback) ) LogError("Failed to detour pre \"%s\" (%s).", sName, g_sSystem);
						if( fPostCallback != INVALID_FUNCTION && !hDetour.Enable(Hook_Post, fPostCallback) ) LogError("Failed to detour post \"%s\" (%s).", sName, g_sSystem);
					} else {
						g_aDetoursHooked.Set(g_iSmallIndex, 0);
						#if defined DEBUG
						#if DEBUG
						PrintToServer("Disabling detour %d %s", g_iSmallIndex, sName);
						#endif
						#endif

						if( fCallback != INVALID_FUNCTION && !hDetour.Disable(Hook_Pre, fCallback) ) LogError("Failed to disable detour pre \"%s\" (%s).", sName, g_sSystem);
						if( fPostCallback != INVALID_FUNCTION && !hDetour.Disable(Hook_Post, fPostCallback) ) LogError("Failed to disable detour post \"%s\" (%s).", sName, g_sSystem);
					}
				}
				else
				{
					if( current == -1 )
					{
						g_aDetoursHooked.Set(g_iSmallIndex, 1);
						#if defined DEBUG
						#if DEBUG
						PrintToServer("Enabling detour hook %d %s", g_iSmallIndex, sName);
						#endif
						#endif

						// Pre-hook
						int hookID = INVALID_HOOK_ID;

						if( fCallback != INVALID_FUNCTION )
						{
							hookID = hHook.HookRaw(Hook_Pre, hAddress, fPostCallback);
						}

						g_aDetourHookIDsPre.Set(g_iSmallIndex, hookID);		// Store handle

						// Post-hook
						hookID = INVALID_HOOK_ID;

						if( fPostCallback != INVALID_FUNCTION )
						{
							hookID = hHook.HookRaw(Hook_Post, hAddress, fPostCallback);
						}

						g_aDetourHookIDsPost.Set(g_iSmallIndex, hookID);		// Store handle
					} else {
						g_aDetoursHooked.Set(g_iSmallIndex, 0);
						#if defined DEBUG
						#if DEBUG
						PrintToServer("Disabling detour hook %d %s", g_iSmallIndex, sName);
						#endif
						#endif

						int hookID = g_aDetourHookIDsPre.Get(g_iSmallIndex);
						if( hookID != INVALID_HOOK_ID )
						{
							DynamicHook.RemoveHook(hookID);
						}

						hookID = g_aDetourHookIDsPost.Get(g_iSmallIndex);
						if( hookID != INVALID_HOOK_ID )
						{
							DynamicHook.RemoveHook(hookID);
						}

						g_aDetourHookIDsPre.Set(g_iSmallIndex, INVALID_HOOK_ID);
						g_aDetourHookIDsPost.Set(g_iSmallIndex, INVALID_HOOK_ID);
					}
				}
			}

			g_iSmallIndex++;
		}

		g_iLargeIndex++;
	}
}

// Loop through plugins, check which forwards are being used, then hook
void CheckRequiredDetours(int client = 0)
{
	#if defined DEBUG
	#if DEBUG || !DETOUR_ALL
	char filename[PLATFORM_MAX_PATH];
	#endif
	#endif

	bool useLast;
	char sName[MAX_FWD_LEN];
	char sForward[MAX_FWD_LEN];
	ArrayList aHand = new ArrayList();
	Handle hIter = GetPluginIterator();
	Handle hPlug;
	int index;
	int count;

	// Iterate plugins
	while( MorePlugins(hIter) )
	{
		hPlug = ReadPlugin(hIter);
		if( g_hThisPlugin == hPlug ) continue; // Ignore self

		// Iterate forwards
		int len = g_aForwardIndex.Length;
		for( int i = 0; i < len; i++ )
		{
			// Get detour index from forward list
			index = g_aForwardIndex.Get(i);
			useLast = g_aUseLastIndex.Get(i);

			// Prevent checking forwards already known in use
			// ToDo: When using extra-api.ext, we will check all plugins to gather total number using each forward and store in g_aDetoursHooked
			if( aHand.FindValue(index) == -1 || useLast )
			{
				// Only if not enabling all detours

				// Force detour on?
				if( g_aForceDetours.Get(i) )
				{
					// Get forward name
					g_aForwardNames.GetString(i, sForward, sizeof(sForward));
					g_aGameDataSigs.GetString(i, sName, sizeof(sName));

					count++;

					if( !useLast )
						aHand.Push(index);

					#if defined DEBUG
					#if DEBUG
					if( client == 0 )
					{
						g_vProf.Stop();
						g_fProf += g_vProf.Time;

						PrintToServer("%3d %36s> %43s (%s)", count, (i == g_iAnimationDetourIndex && g_aForceDetours.Get(g_iAnimationDetourIndex)) ? "FORCED ANIM" : "FORCED DETOUR", sForward, sName[6]);
						g_vProf.Start();
					}
					#endif
					#endif

					if( client > 0 )
					{
						ReplyToCommand(client - 1, "%3d %36s> %43s (%s)", count, (i == g_iAnimationDetourIndex && g_aForceDetours.Get(g_iAnimationDetourIndex)) ? "FORCED ANIM" : "FORCED DETOUR", sForward, sName[6]);
					}
				}
				// Check if used
				else
				{
					// Get forward name
					g_aForwardNames.GetString(i, sForward, sizeof(sForward));

					#if defined DETOUR_ALL
					#if !DETOUR_ALL
					if( GetFunctionByName(hPlug, sForward) != INVALID_FUNCTION )
					#else
					if( aHand.FindValue(index) == -1 )
					#endif
					#endif
					{
						count++;

						aHand.Push(index);

						#if defined DEBUG
						#if DEBUG
						if( client == 0 )
						{
							#if DETOUR_ALL
							filename = "THIS_PLUGIN_TEST";
							#else
							GetPluginFilename(hPlug, filename, sizeof(filename));
							#endif

							g_aGameDataSigs.GetString(i, sName, sizeof(sName));

							g_vProf.Stop();
							g_fProf += g_vProf.Time;
							PrintToServer("%3d %36s> %43s (%s)", count, filename, sForward, sName[6]);
							g_vProf.Start();
						}
						#endif
						#endif

						if( client > 0 )
						{
							g_aGameDataSigs.GetString(i, sName, sizeof(sName));

							#if defined DETOUR_ALL
							#if DETOUR_ALL
							ReplyToCommand(client - 1, "%3d %36s> %43s (%s)", count, "THIS_PLUGIN_TEST", sForward, sName[6]);
							#else
							GetPluginFilename(hPlug, filename, sizeof(filename));
							ReplyToCommand(client - 1, "%3d %36s> %43s (%s)", count, filename, sForward, sName[6]);
							#endif
							#endif
						}
					}
				}
			}
		}
	}

	// Iterate detours - enable and disable as required
	int current;
	int len = g_aDetoursHooked.Length;
	for( int i = 0; i < len; i++ )
	{
		// ToDo: When using extra-api.ext - increment or decrement and only enable/disable when required
		current = g_aDetoursHooked.Get(i);

		// Detour not required
		if( aHand.FindValue(i) == -1 )
		{
			if( current )
				g_aDetoursHooked.Set(i, -2); // -2 to disable
		}
		// Detour required
		else
		{
			if( current == 0 )
				g_aDetoursHooked.Set(i, -1); // -1 to enable
		}
	}

	delete aHand;
	delete hIter;

	// Now hook required
	SetupDetours();
}





// ====================================================================================================
//										DETOURS - FORWARDS
// ====================================================================================================
// MRES_ChangedHandled = -2,	// Use changed values and return MRES_Handled
// MRES_ChangedOverride,		// Use changed values and return MRES_Override
// MRES_Ignored,				// plugin didn't take any action
// MRES_Handled,				// plugin did something, but real function should still be called
// MRES_Override,				// call real function, but use my return value
// MRES_Supercede				// skip real function; use my return value

bool g_bBlock_ZombieManager_SpawnSpecial;
MRESReturn DTR_ZombieManager_SpawnSpecial(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnSpawnSpecial"
{
	//PrintToServer("##### DTR_ZombieManager_SpawnSpecial");
	float a1[3], a2[3];
	int class = hParams.Get(1);
	hParams.GetVector(2, a1);
	hParams.GetVector(3, a2);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_ZombieManager_SpawnSpecial);
	Call_PushCellRef(class);
	Call_PushArray(a1, sizeof(a1));
	Call_PushArray(a2, sizeof(a2));
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_ZombieManager_SpawnSpecial = true;

		hReturn.Value = -1;
		return MRES_Supercede;
	}

	g_bBlock_ZombieManager_SpawnSpecial = false;

	if( aResult == Plugin_Changed )
	{
		hParams.Set(1, class);
		return MRES_ChangedHandled;
	}

	return MRES_Ignored;
}

MRESReturn DTR_ZombieManager_SpawnSpecial_Post(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnSpawnSpecial_Post" and "L4D_OnSpawnSpecial_PostHandled"
{
	//PrintToServer("##### DTR_ZombieManager_SpawnSpecial_Post");
	int client = hReturn.Value;

	float a1[3], a2[3];
	int class = hParams.Get(1);
	hParams.GetVector(2, a1);
	hParams.GetVector(3, a2);

	Call_StartForward(g_bBlock_ZombieManager_SpawnSpecial ? g_hFWD_ZombieManager_SpawnSpecial_PostHandled : g_hFWD_ZombieManager_SpawnSpecial_Post);
	Call_PushCell(client);
	Call_PushCell(class);
	Call_PushArray(a1, sizeof(a1));
	Call_PushArray(a2, sizeof(a2));
	Call_Finish();

	return MRES_Ignored;
}

/*
// NOT USED
MRESReturn DTR_ZombieManager_SpawnSpecial_Clone(DHookReturn hReturn, DHookParam hParams)
{
	//PrintToServer("##### DTR_ZombieManager_SpawnSpecial_Clone");
	float a1[3], a2[3];
	int class = hParams.Get(1);
	hParams.GetVector(3, a2);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_ZombieManager_SpawnSpecial);
	Call_PushCellRef(class);
	Call_PushArray(a1, sizeof(a1));
	Call_PushArray(a2, sizeof(a2));
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_ZombieManager_SpawnSpecial = true;

		hReturn.Value = 0;
		return MRES_Supercede;
	}

	g_bBlock_ZombieManager_SpawnSpecial = false;

	if( aResult == Plugin_Changed )
	{
		hParams.Set(1, class);
		return MRES_ChangedHandled;
	}

	return MRES_Ignored;
}

MRESReturn DTR_ZombieManager_SpawnSpecial_Post_Clone(DHookReturn hReturn, DHookParam hParams)
{
	//PrintToServer("##### DTR_ZombieManager_SpawnSpecial_Post_Clone");
	int client = hReturn.Value;
	if( client == -1 ) return MRES_Ignored;

	float a1[3], a2[3];
	int class = hParams.Get(1);
	hParams.GetVector(3, a2);

	Call_StartForward(g_bBlock_ZombieManager_SpawnSpecial ? g_hFWD_ZombieManager_SpawnSpecial_PostHandled : g_hFWD_ZombieManager_SpawnSpecial_Post);
	Call_PushCell(client);
	Call_PushCell(class);
	Call_PushArray(a1, sizeof(a1));
	Call_PushArray(a2, sizeof(a2));
	Call_Finish();

	return MRES_Ignored;
}
// */

// Forward "L4D_OnSpawnSpecial", "L4D_OnSpawnSpecial_Post" and "L4D_OnSpawnSpecial_PostHandled"
MRESReturn DTR_ZombieManager_SpawnBoomer(DHookReturn hReturn, DHookParam hParams)
{
	//PrintToServer("##### DTR_ZombieManager_SpawnBoomer");
	int class = 2;
	return Spawn_SmokerBoomerHunter(class, hReturn, hParams);
}

MRESReturn DTR_ZombieManager_SpawnBoomer_Post(DHookReturn hReturn, DHookParam hParams)
{
	//PrintToServer("##### DTR_ZombieManager_SpawnBoomer_Post");
	int class = 2;
	return Spawn_SmokerBoomerHunter_Post(class, hReturn, hParams);
}

MRESReturn DTR_ZombieManager_SpawnHunter(DHookReturn hReturn, DHookParam hParams)
{
	//PrintToServer("##### DTR_ZombieManager_SpawnHunter");
	int class = 3;
	return Spawn_SmokerBoomerHunter(class, hReturn, hParams);
}

MRESReturn DTR_ZombieManager_SpawnHunter_Post(DHookReturn hReturn, DHookParam hParams)
{
	//PrintToServer("##### DTR_ZombieManager_SpawnHunter_Post");
	int class = 3;
	return Spawn_SmokerBoomerHunter_Post(class, hReturn, hParams);
}

MRESReturn DTR_ZombieManager_SpawnSmoker(DHookReturn hReturn, DHookParam hParams)
{
	//PrintToServer("##### DTR_ZombieManager_SpawnSmoker");
	int class = 1;
	return Spawn_SmokerBoomerHunter(class, hReturn, hParams);
}

MRESReturn DTR_ZombieManager_SpawnSmoker_Post(DHookReturn hReturn, DHookParam hParams)
{
	//PrintToServer("##### DTR_ZombieManager_SpawnSmoker_Post");
	int class = 1;
	return Spawn_SmokerBoomerHunter_Post(class, hReturn, hParams);
}

bool g_bBlock_Spawn_SmokerBoomerHunter;
MRESReturn Spawn_SmokerBoomerHunter(int zombieClass, DHookReturn hReturn, DHookParam hParams)
{
	int class = zombieClass;
	float a1[3], a2[3];
	hParams.GetVector(1, a1);
	hParams.GetVector(2, a2);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_ZombieManager_SpawnSpecial);
	Call_PushCellRef(class);
	Call_PushArray(a1, sizeof(a1));
	Call_PushArray(a2, sizeof(a2));
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_Spawn_SmokerBoomerHunter = true;

		hReturn.Value = -1;
		return MRES_Supercede;
	}

	g_bBlock_Spawn_SmokerBoomerHunter = false;

	if( aResult == Plugin_Changed )
	{
		if( !g_bLeft4Dead2 )
		{
			if( zombieClass == class ) return MRES_Supercede;

			// Because we have no "zombieClass" int to modify, hackish style:
			ValidateAddress(g_pZombieManager, "g_pZombieManager");

			switch( class )
			{
				case 1:
				{
					ValidateNatives(g_hSDK_ZombieManager_SpawnSmoker, "ZombieManager::SpawnSmoker");
					//PrintToServer("#### CALL g_hSDK_ZombieManager_SpawnSmoker");
					SDKCall(g_hSDK_ZombieManager_SpawnSmoker, g_pZombieManager, a1, a2);
				}
				case 2:
				{
					ValidateNatives(g_hSDK_ZombieManager_SpawnBoomer, "ZombieManager::SpawnBoomer");
					//PrintToServer("#### CALL g_hSDK_ZombieManager_SpawnBoomer");
					SDKCall(g_hSDK_ZombieManager_SpawnBoomer, g_pZombieManager, a1, a2);
				}
				case 3:
				{
					ValidateNatives(g_hSDK_ZombieManager_SpawnHunter, "ZombieManager::SpawnHunter");
					//PrintToServer("#### CALL g_hSDK_ZombieManager_SpawnHunter");
					SDKCall(g_hSDK_ZombieManager_SpawnHunter, g_pZombieManager, a1, a2);
				}
			}

			hReturn.Value = -1;
			return MRES_Supercede;
		}

		hParams.Set(1, class);
		return MRES_ChangedHandled;
	}

	return MRES_Ignored;
}

MRESReturn Spawn_SmokerBoomerHunter_Post(int zombieClass, DHookReturn hReturn, DHookParam hParams)
{
	//PrintToServer("##### Spawn_SmokerBoomerHunter_Post");
	int client = hReturn.Value;

	int class = zombieClass;
	float a1[3], a2[3];
	hParams.GetVector(1, a1);
	hParams.GetVector(2, a2);

	Call_StartForward(g_bBlock_Spawn_SmokerBoomerHunter ? g_hFWD_ZombieManager_SpawnSpecial_PostHandled : g_hFWD_ZombieManager_SpawnSpecial_Post);
	Call_PushCell(client);
	Call_PushCell(class);
	Call_PushArray(a1, sizeof(a1));
	Call_PushArray(a2, sizeof(a2));
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn DTR_ZombieManager_SpawnWitch(DHookReturn hReturn, DHookParam hParams)
{
	//PrintToServer("##### DTR_ZombieManager_SpawnWitch");
	return Spawn_TankWitch(g_hFWD_ZombieManager_SpawnWitch, hReturn, hParams);
}

MRESReturn DTR_ZombieManager_SpawnWitch_Post(DHookReturn hReturn, DHookParam hParams)
{
	//PrintToServer("##### DTR_ZombieManager_SpawnWitch_Post");
	return Spawn_TankWitch_Post(g_hFWD_ZombieManager_SpawnWitch_Post, g_hFWD_ZombieManager_SpawnWitch_PostHandled, hReturn, hParams);
}

MRESReturn DTR_ZombieManager_SpawnWitchBride(DHookReturn hReturn, DHookParam hParams) // Forward "L4D2_OnSpawnWitchBride"
{
	//PrintToServer("##### DTR_ZombieManager_SpawnWitchBride");
	return Spawn_TankWitch(g_hFWD_ZombieManager_SpawnWitchBride, hReturn, hParams);
}

MRESReturn DTR_ZombieManager_SpawnWitchBride_Post(DHookReturn hReturn, DHookParam hParams) // Forward "L4D2_OnSpawnWitchBride_Post" and "L4D2_OnSpawnWitchBride_PostHandled"
{
	//PrintToServer("##### DTR_ZombieManager_SpawnWitchBride_Post");
	return Spawn_TankWitch_Post(g_hFWD_ZombieManager_SpawnWitchBride_Post, g_hFWD_ZombieManager_SpawnWitchBride_PostHandled, hReturn, hParams);
}

MRESReturn DTR_ZombieManager_SpawnTank(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnSpawnTank"
{
	//PrintToServer("##### DTR_ZombieManager_SpawnTank");
	return Spawn_TankWitch(g_hFWD_ZombieManager_SpawnTank, hReturn, hParams);
}

MRESReturn DTR_ZombieManager_SpawnTank_Post(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnSpawnTank_Post" and "L4D_OnSpawnTank_PostHandled"
{
	//PrintToServer("##### DTR_ZombieManager_SpawnTank_Post");
	return Spawn_TankWitch_Post(g_hFWD_ZombieManager_SpawnTank_Post, g_hFWD_ZombieManager_SpawnTank_PostHandled, hReturn, hParams);
}

bool g_bBlock_Spawn_TankWitch;
MRESReturn Spawn_TankWitch(Handle hForward, DHookReturn hReturn, DHookParam hParams)
{
	float a1[3], a2[3];
	hParams.GetVector(1, a1);
	hParams.GetVector(2, a2);

	Action aResult = Plugin_Continue;
	Call_StartForward(hForward);
	Call_PushArray(a1, sizeof(a1));
	Call_PushArray(a2, sizeof(a2));
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_Spawn_TankWitch = true; // Signal to block post hook

		hReturn.Value = -1;
		return MRES_Supercede;
	}

	g_bBlock_Spawn_TankWitch = false;

	return MRES_Ignored;
}

MRESReturn Spawn_TankWitch_Post(Handle hForward, Handle hForward2, DHookReturn hReturn, DHookParam hParams)
{
	int entity = hReturn.Value;

	float a1[3], a2[3];
	hParams.GetVector(1, a1);
	hParams.GetVector(2, a2);

	Call_StartForward(g_bBlock_Spawn_TankWitch ? hForward2 : hForward);
	Call_PushCell(entity);
	Call_PushArray(a1, sizeof(a1));
	Call_PushArray(a2, sizeof(a2));
	Call_Finish();

	return MRES_Ignored;
}

// L4D1 Linux clone function detour
/*
MRESReturn SpawnWitchAreaPre(DHookReturn hReturn, DHookParam hParams)
{
	return MRES_Ignored;
}
*/

bool g_bBlock_ZombieManager_SpawnWitch;
MRESReturn DTR_ZombieManager_SpawnWitch_Area(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnSpawnWitch"
{
	//PrintToServer("##### DTR_ZombieManager_SpawnWitch_Area");
	// From the post hook
	/*
	int entity = hReturn.Value;
	if( entity == 0 ) return MRES_Ignored;

	float a1[3], a2[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", a1);
	hParams.GetVector(2, a2);
	*/

	float a2[3];
	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_ZombieManager_SpawnWitch);
	Call_PushArray(NULL_VECTOR, sizeof(a2));
	Call_PushArray(a2, sizeof(a2));
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_ZombieManager_SpawnWitch = true;

		// RemoveEntity(entity); // From the post hook
		hReturn.Value = -1;
		return MRES_Supercede;
	}

	g_bBlock_ZombieManager_SpawnWitch = false;

	return MRES_Ignored;
}

MRESReturn DTR_ZombieManager_SpawnWitch_Area_Post(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnSpawnWitch_Post" and "L4D_OnSpawnWitch_PostHandled"
{
	float a2[3];

	int entity = hReturn.Value;

	Call_StartForward(g_bBlock_ZombieManager_SpawnWitch ? g_hFWD_ZombieManager_SpawnWitch_PostHandled : g_hFWD_ZombieManager_SpawnWitch_Post);
	Call_PushCell(entity);
	Call_PushArray(NULL_VECTOR, sizeof(a2));
	Call_PushArray(a2, sizeof(a2));
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn DTR_CTerrorGameRules_ClearTeamScores(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnClearTeamScores"
{
	//PrintToServer("##### DTR_CTerrorGameRules_ClearTeamScores");
	int value = g_bLeft4Dead2 ? hParams.Get(1) : 0;

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorGameRules_ClearTeamScores);
	Call_PushCell(value);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		hReturn.Value = 0;
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

MRESReturn DTR_CTerrorGameRules_SetCampaignScores(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnSetCampaignScores"
{
	//PrintToServer("##### DTR_CTerrorGameRules_SetCampaignScores");
	int a1 = hParams.Get(1);
	int a2 = hParams.Get(2);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorGameRules_SetCampaignScores);
	Call_PushCellRef(a1);
	Call_PushCellRef(a2);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		hReturn.Value = 0;
		return MRES_Supercede;
	}

	if( aResult == Plugin_Changed )
	{
		hParams.Set(1, a1);
		hParams.Set(2, a2);
		hReturn.Value = 0;
		return MRES_ChangedOverride;
	}

	return MRES_Ignored;
}

MRESReturn DTR_CTerrorGameRules_SetCampaignScores_Post(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnSetCampaignScores_Post"
{
	//PrintToServer("##### DTR_CTerrorGameRules_SetCampaignScores_Post");
	int a1 = hParams.Get(1);
	int a2 = hParams.Get(2);

	Call_StartForward(g_hFWD_CTerrorGameRules_SetCampaignScores_Post);
	Call_PushCell(a1);
	Call_PushCell(a2);
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn DTR_CTerrorPlayer_RecalculateVersusScore(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnRecalculateVersusScore"
{
	//PrintToServer("##### DTR_CTerrorPlayer_RecalculateVersusScore");

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorPlayer_RecalculateVersusScore);
	Call_PushCell(pThis);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		hReturn.Value = 0;
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

MRESReturn DTR_CTerrorPlayer_RecalculateVersusScore_Post(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnRecalculateVersusScore_Post"
{
	//PrintToServer("##### DTR_CTerrorPlayer_RecalculateVersusScore_Post");

	Call_StartForward(g_hFWD_CTerrorPlayer_RecalculateVersusScore_Post);
	Call_PushCell(pThis);
	Call_Finish();

	return MRES_Ignored;
}

bool g_bBlock_CDirector_OnFirstSurvivorLeftSafeArea;
MRESReturn DTR_CDirector_OnFirstSurvivorLeftSafeArea(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnFirstSurvivorLeftSafeArea"
{
	//PrintToServer("##### DTR_CDirector_OnFirstSurvivorLeftSafeArea");
	if( hParams.IsNull(1) ) return MRES_Ignored;

	int value = hParams.Get(1);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CDirector_OnFirstSurvivorLeftSafeArea);
	Call_PushCell(value);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_CDirector_OnFirstSurvivorLeftSafeArea = true;

		if( !g_bLeft4Dead2 )
		{
			// Remove bool that says not to check if they have left
			ValidateAddress(g_pDirector, "g_pDirector");
			ValidateAddress(g_iOff_m_bFirstSurvivorLeftStartArea, "m_bFirstSurvivorLeftStartArea");
			StoreToAddress(g_pDirector + view_as<Address>(g_iOff_m_bFirstSurvivorLeftStartArea), 0, NumberType_Int8, false);
		}

		hReturn.Value = 0;
		return MRES_Supercede;
	}

	g_bBlock_CDirector_OnFirstSurvivorLeftSafeArea = false;

	return MRES_Ignored;
}

MRESReturn DTR_CDirector_OnFirstSurvivorLeftSafeArea_Post(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnFirstSurvivorLeftSafeArea_Post" and "L4D_OnFirstSurvivorLeftSafeArea_PostHandled"
{
	//PrintToServer("##### DTR_CDirector_OnFirstSurvivorLeftSafeArea_Post");
	if( hParams.IsNull(1) ) return MRES_Ignored;

	int value = hParams.Get(1);

	Call_StartForward(g_bBlock_CDirector_OnFirstSurvivorLeftSafeArea ? g_hFWD_CDirector_OnFirstSurvivorLeftSafeArea_PostHandled : g_hFWD_CDirector_OnFirstSurvivorLeftSafeArea_Post);
	Call_PushCell(value);
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn DTR_CDirector_OnForceSurvivorPositions_Pre(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnForceSurvivorPositions_Pre"
{
	//PrintToServer("##### DTR_CDirector_OnForceSurvivorPositions_Pre");

	Call_StartForward(g_hFWD_CDirector_OnForceSurvivorPositions_Pre);
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn DTR_CDirector_OnForceSurvivorPositions_Post(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnForceSurvivorPositions"
{
	//PrintToServer("##### DTR_CDirector_OnForceSurvivorPositions_Post");

	Call_StartForward(g_hFWD_CDirector_OnForceSurvivorPositions);
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn DTR_CDirector_OnReleaseSurvivorPositions_Pre(DHookReturn hReturn, DHookParam hParams)
{
	return MRES_Ignored;
}

MRESReturn DTR_CDirector_OnReleaseSurvivorPositions(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnSpeakResponseConcept"
{
	//PrintToServer("##### g_hFWD_CDirector_OnReleaseSurvivorPositions");

	Call_StartForward(g_hFWD_CDirector_OnReleaseSurvivorPositions);
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn DTR_SpeakResponseConceptFromEntityIO_Pre(DHookReturn hReturn, DHookParam hParams)
{
	//PrintToServer("##### g_hFWD_SpeakResponseConceptFromEntityIO_Pre");

	int entity = hParams.Get(1);

	Call_StartForward(g_hFWD_SpeakResponseConceptFromEntityIO_Pre);
	Call_PushCell(entity);
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn DTR_SpeakResponseConceptFromEntityIO_Post(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnSpeakResponseConcept_Post"
{
	//PrintToServer("##### g_hFWD_SpeakResponseConceptFromEntityIO_Post");

	int entity = hParams.Get(1);

	Call_StartForward(g_hFWD_SpeakResponseConceptFromEntityIO_Post);
	Call_PushCell(entity);
	Call_Finish();

	return MRES_Ignored;
}

bool g_bBlock_CDirector_MobRushStart;
MRESReturn DTR_CDirector_MobRushStart(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnMobRushStart"
{
	//PrintToServer("##### DTR_CDirector_MobRushStart");
	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CDirector_MobRushStart);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_CDirector_MobRushStart = true;

		hReturn.Value = 0;
		return MRES_Supercede;
	}

	g_bBlock_CDirector_MobRushStart = false;

	return MRES_Ignored;
}

MRESReturn DTR_CDirector_MobRushStart_Post(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnMobRushStart_Post" and "L4D_OnMobRushStart_PostHandled"
{
	//PrintToServer("##### DTR_CDirector_MobRushStart_Post");
	Call_StartForward(g_bBlock_CDirector_MobRushStart ? g_hFWD_CDirector_MobRushStart_PostHandled : g_hFWD_CDirector_MobRushStart_Post);
	Call_Finish();

	return MRES_Ignored;
}

bool g_bBlock_ZombieManager_SpawnITMob;
MRESReturn DTR_ZombieManager_SpawnITMob(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnSpawnITMob"
{
	//PrintToServer("##### DTR_ZombieManager_SpawnITMob");
	int a1 = hParams.Get(1);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_ZombieManager_SpawnITMob);
	Call_PushCellRef(a1);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_ZombieManager_SpawnITMob = true;

		hReturn.Value = 0;
		return MRES_Supercede;
	}

	g_bBlock_ZombieManager_SpawnITMob = false;

	if( aResult == Plugin_Changed )
	{
		hParams.Set(1, a1);
		hReturn.Value = a1;
		return MRES_ChangedHandled;
	}

	return MRES_Ignored;
}

MRESReturn DTR_ZombieManager_SpawnITMob_Post(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnSpawnITMob_Post" and "L4D_OnSpawnITMob_PostHandled"
{
	//PrintToServer("##### DTR_ZombieManager_SpawnITMob_Post");
	int a1 = hParams.Get(1);

	Call_StartForward(g_bBlock_ZombieManager_SpawnITMob ? g_hFWD_ZombieManager_SpawnITMob_PostHandled : g_hFWD_ZombieManager_SpawnITMob_Post);
	Call_PushCell(a1);
	Call_Finish();

	return MRES_Ignored;
}

bool g_bBlock_ZombieManager_SpawnMob;
MRESReturn DTR_ZombieManager_SpawnMob(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnSpawnMob"
{
	//PrintToServer("##### DTR_ZombieManager_SpawnMob");
	int a1 = hParams.Get(1);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_ZombieManager_SpawnMob);
	Call_PushCellRef(a1);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_ZombieManager_SpawnMob = true;

		hReturn.Value = 0;
		return MRES_Supercede;
	}

	g_bBlock_ZombieManager_SpawnMob = false;

	if( aResult == Plugin_Changed )
	{
		hParams.Set(1, a1);
		hReturn.Value = a1;
		return MRES_ChangedHandled;
	}

	return MRES_Ignored;
}

MRESReturn DTR_ZombieManager_SpawnMob_Post(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnSpawnMob_Post" and "L4D_OnSpawnMob_PostHandled"
{
	//PrintToServer("##### DTR_ZombieManager_SpawnMob_Post");
	int a1 = hParams.Get(1);

	Call_StartForward(g_bBlock_ZombieManager_SpawnMob ? g_hFWD_ZombieManager_SpawnMob_PostHandled : g_hFWD_ZombieManager_SpawnMob_Post);
	Call_PushCell(a1);
	Call_Finish();

	return MRES_Ignored;
}

bool g_bBlock_CTerrorPlayer_EnterGhostState;
MRESReturn DTR_CTerrorPlayer_EnterGhostState_Pre(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnEnterGhostStatePre"
{
	//PrintToServer("##### DTR_CTerrorPlayer_EnterGhostState_Pre");
	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorPlayer_EnterGhostState_Pre);
	Call_PushCell(pThis);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_CTerrorPlayer_EnterGhostState = true;

		hReturn.Value = 0;
		return MRES_Supercede;
	}

	g_bBlock_CTerrorPlayer_EnterGhostState = false;

	return MRES_Ignored;
}

MRESReturn DTR_CTerrorPlayer_EnterGhostState_Post(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnEnterGhostState" and "L4D_OnEnterGhostState_PostHandled"
{
	//PrintToServer("##### DTR_CTerrorPlayer_EnterGhostState_Post");
	Call_StartForward(g_bBlock_CTerrorPlayer_EnterGhostState ? g_hFWD_CTerrorPlayer_EnterGhostState_PostHandled : g_hFWD_CTerrorPlayer_EnterGhostState_Post);
	Call_PushCell(pThis);
	Call_Finish();

	return MRES_Ignored;
}

bool g_bBlock_CTerrorPlayer_TakeOverBot;
MRESReturn DTR_CTerrorPlayer_TakeOverBot_Pre(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnTakeOverBot"
{
	//PrintToServer("##### DTR_CTerrorPlayer_TakeOverBot_Pre");
	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorPlayer_TakeOverBot_Pre);
	Call_PushCell(pThis);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_CTerrorPlayer_TakeOverBot = true;

		hReturn.Value = 0;
		return MRES_Supercede;
	}

	g_bBlock_CTerrorPlayer_TakeOverBot = false;

	return MRES_Ignored;
}

MRESReturn DTR_CTerrorPlayer_TakeOverBot_Post(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnTakeOverBot_Post" and "L4D_OnTakeOverBot_PostHandled"
{
	//PrintToServer("##### DTR_CTerrorPlayer_TakeOverBot_Post");
	Call_StartForward(g_bBlock_CTerrorPlayer_TakeOverBot ? g_hFWD_CTerrorPlayer_TakeOverBot_PostHandled : g_hFWD_CTerrorPlayer_TakeOverBot_Post);
	Call_PushCell(pThis);
	Call_PushCell(hReturn.Value);
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn DTR_CDirector_IsTeamFull(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnIsTeamFull"
{
	//PrintToServer("##### DTR_CDirector_IsTeamFull");
	int a1 = hParams.Get(1);
	bool a2 = hReturn.Value;

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CDirector_IsTeamFull);
	Call_PushCell(a1);
	Call_PushCellRef(a2);
	Call_Finish(aResult);

	if( aResult == Plugin_Changed )
	{
		hReturn.Value = a2;
		return MRES_ChangedOverride; // Maybe MRES_Supercede can be used
	}

	return MRES_Ignored;
}

MRESReturn DTR_CTerrorPlayer_GetCrouchTopSpeed_Pre(int pThis, DHookReturn hReturn, DHookParam hParams)
{
	//PrintToServer("##### DTR_CTerrorPlayer_GetCrouchTopSpeed_Pre");
	return MRES_Ignored;
}

MRESReturn DTR_CTerrorPlayer_GetCrouchTopSpeed_Post(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnGetCrouchTopSpeed"
{
	//PrintToServer("##### DTR_CTerrorPlayer_GetCrouchTopSpeed_Post");
	return GetSpeed(pThis, g_hFWD_CTerrorPlayer_GetCrouchTopSpeed, hReturn);
}

MRESReturn DTR_CTerrorPlayer_GetRunTopSpeed_Pre(int pThis, DHookReturn hReturn, DHookParam hParams)
{
	//PrintToServer("##### DTR_CTerrorPlayer_GetRunTopSpeed_Pre");
	return MRES_Ignored;
}

MRESReturn DTR_CTerrorPlayer_GetRunTopSpeed_Post(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnGetRunTopSpeed"
{
	//PrintToServer("##### DTR_CTerrorPlayer_GetRunTopSpeed_Post");
	return GetSpeed(pThis, g_hFWD_CTerrorPlayer_GetRunTopSpeed, hReturn);
}

MRESReturn DTR_CTerrorPlayer_GetWalkTopSpeed_Pre(int pThis, DHookReturn hReturn, DHookParam hParams)
{
	//PrintToServer("##### DTR_CTerrorPlayer_GetWalkTopSpeed_Pre");
	return MRES_Ignored;
}

MRESReturn DTR_CTerrorPlayer_GetWalkTopSpeed_Post(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnGetWalkTopSpeed"
{
	//PrintToServer("##### DTR_CTerrorPlayer_GetWalkTopSpeed_Post");
	return GetSpeed(pThis, g_hFWD_CTerrorPlayer_GetWalkTopSpeed, hReturn);
}

MRESReturn GetSpeed(int pThis, Handle hForward, DHookReturn hReturn)
{
	if( IsClientInGame(pThis) )
	{
		float a2 = hReturn.Value;

		Action aResult = Plugin_Continue;
		Call_StartForward(hForward);
		Call_PushCell(pThis);
		Call_PushFloatRef(a2);
		Call_Finish(aResult);

		if( aResult == Plugin_Handled )
		{
			hReturn.Value = a2;
			return MRES_Supercede;
		}
	}

	return MRES_Ignored;
}

MRESReturn DTR_CTerrorGameRules_HasConfigurableDifficultySetting(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnHasConfigurableDifficulty"
{
	//PrintToServer("##### DTR_CTerrorGameRules_HasConfigurableDifficultySetting");
	int a1 = hReturn.Value;

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorGameRules_HasConfigurableDifficultySetting);
	Call_PushCellRef(a1);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		hReturn.Value = a1;
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

MRESReturn DTR_CTerrorGameRules_HasConfigurableDifficultySetting_Post(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnHasConfigurableDifficulty_Post"
{
	//PrintToServer("##### DTR_CTerrorGameRules_HasConfigurableDifficultySetting_Post");
	int a1 = hReturn.Value;

	Call_StartForward(g_hFWD_CTerrorGameRules_HasConfigurableDifficultySetting_Post);
	Call_PushCell(a1);
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn DTR_CTerrorGameRules_GetSurvivorSet_Pre(DHookReturn hReturn, DHookParam hParams)
{
	//PrintToServer("DTR_CTerrorGameRules_GetSurvivorSet_Pre");
	return MRES_Ignored;
}

MRESReturn DTR_CTerrorGameRules_GetSurvivorSet(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnGetSurvivorSet"
{
	//PrintToServer("##### DTR_CTerrorGameRules_GetSurvivorSet");
	return SurvivorSet(g_hFWD_CTerrorGameRules_GetSurvivorSet, hReturn);
}

MRESReturn DTR_CTerrorGameRules_FastGetSurvivorSet_Pre(DHookReturn hReturn, DHookParam hParams)
{
	//PrintToServer("DTR_CTerrorGameRules_FastGetSurvivorSet_Pre");
	return MRES_Ignored;
}

MRESReturn DTR_CTerrorGameRules_FastGetSurvivorSet(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnFastGetSurvivorSet"
{
	//PrintToServer("##### DTR_CTerrorGameRules_FastGetSurvivorSet");
	return SurvivorSet(g_hFWD_CTerrorGameRules_FastGetSurvivorSet, hReturn);
}

MRESReturn SurvivorSet(Handle hForward, DHookReturn hReturn)
{
	int a1 = hReturn.Value;

	Action aResult = Plugin_Continue;
	Call_StartForward(hForward);
	Call_PushCellRef(a1);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		hReturn.Value = a1;
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

bool g_bBlock_CDirectorVersusMode_GetMissionVersusBossSpawning;
MRESReturn DTR_CDirectorVersusMode_GetMissionVersusBossSpawning(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnGetMissionVSBossSpawning"
{
	//PrintToServer("##### DTR_CDirectorVersusMode_GetMissionVersusBossSpawning");
	int plus = !g_bLeft4Dead2;

	float a1 = hParams.GetObjectVar(plus + 1, 0, ObjectValueType_Float);
	float a2 = hParams.GetObjectVar(plus + 2, 0, ObjectValueType_Float);
	float a3 = hParams.GetObjectVar(plus + 3, 0, ObjectValueType_Float);
	float a4 = hParams.GetObjectVar(plus + 4, 0, ObjectValueType_Float);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_GetMissionVSBossSpawning);
	Call_PushFloatRef(a1);
	Call_PushFloatRef(a2);
	Call_PushFloatRef(a3);
	Call_PushFloatRef(a4);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_CDirectorVersusMode_GetMissionVersusBossSpawning = true;

		hReturn.Value = 0;
		return MRES_Supercede;
	}

	g_bBlock_CDirectorVersusMode_GetMissionVersusBossSpawning = false;

	if( aResult == Plugin_Changed )
	{
		hParams.SetObjectVar(plus + 1, 0, ObjectValueType_Float, a1);
		hParams.SetObjectVar(plus + 2, 0, ObjectValueType_Float, a2);
		hParams.SetObjectVar(plus + 3, 0, ObjectValueType_Float, a3);
		hParams.SetObjectVar(plus + 4, 0, ObjectValueType_Float, a4);

		if( !g_bLeft4Dead2 )
			hParams.SetObjectVar(6, 0, ObjectValueType_Bool, true);

		hReturn.Value = 1;
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

MRESReturn DTR_CDirectorVersusMode_GetMissionVersusBossSpawning_Post(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnGetMissionVSBossSpawning_Post" and "L4D_OnGetMissionVSBossSpawning_PostHandled"
{
	//PrintToServer("##### DTR_CDirectorVersusMode_GetMissionVersusBossSpawning_Post");
	int plus = !g_bLeft4Dead2;

	float a1 = hParams.GetObjectVar(plus + 1, 0, ObjectValueType_Float);
	float a2 = hParams.GetObjectVar(plus + 2, 0, ObjectValueType_Float);
	float a3 = hParams.GetObjectVar(plus + 3, 0, ObjectValueType_Float);
	float a4 = hParams.GetObjectVar(plus + 4, 0, ObjectValueType_Float);

	Call_StartForward(g_bBlock_CDirectorVersusMode_GetMissionVersusBossSpawning ? g_hFWD_GetMissionVSBossSpawning_PostHandled : g_hFWD_GetMissionVSBossSpawning_Post);
	Call_PushFloat(a1);
	Call_PushFloat(a2);
	Call_PushFloat(a3);
	Call_PushFloat(a4);
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn DTR_ZombieManager_ReplaceTank(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnReplaceTank"
{
	//PrintToServer("##### DTR_ZombieManager_ReplaceTank");
	int a1 = hParams.Get(1);
	int a2 = hParams.Get(2);

	Call_StartForward(g_hFWD_ZombieManager_ReplaceTank);
	Call_PushCell(a1);
	Call_PushCell(a2);
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn DTR_CTankClaw_DoSwing_Pre(int pThis) // Forward "L4D_TankClaw_DoSwing_Pre"
{
	//PrintToServer("##### DTR_CTankClaw_DoSwing_Pre");
	int tank = GetEntPropEnt(pThis, Prop_Data, "m_hOwner");

	Call_StartForward(g_hFWD_CTankClaw_DoSwing_Pre);
	Call_PushCell(tank);
	Call_PushCell(pThis);
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn DTR_CTankClaw_DoSwing_Post(int pThis) // Forward "L4D_TankClaw_DoSwing_Post"
{
	//PrintToServer("##### DTR_CTankClaw_DoSwing_Post");
	int tank = GetEntPropEnt(pThis, Prop_Data, "m_hOwner");

	Call_StartForward(g_hFWD_CTankClaw_DoSwing_Post);
	Call_PushCell(tank);
	Call_PushCell(pThis);
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn DTR_CTankClaw_GroundPound_Pre(int pThis) // Forward "L4D_TankClaw_GroundPound_Pre"
{
	//PrintToServer("##### DTR_CTankClaw_GroundPound_Pre");
	int tank = GetEntPropEnt(pThis, Prop_Data, "m_hOwner");

	Call_StartForward(g_hFWD_CTankClaw_GroundPound_Pre);
	Call_PushCell(tank);
	Call_PushCell(pThis);
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn DTR_CTankClaw_GroundPound_Post(int pThis) // Forward "L4D_TankClaw_GroundPound_Post"
{
	//PrintToServer("##### DTR_CTankClaw_GroundPound_Post");
	int tank = GetEntPropEnt(pThis, Prop_Data, "m_hOwner");

	Call_StartForward(g_hFWD_CTankClaw_GroundPound_Post);
	Call_PushCell(tank);
	Call_PushCell(pThis);
	Call_Finish();

	return MRES_Ignored;
}

bool g_bBlock_CTankClaw_OnPlayerHit;
MRESReturn DTR_CTankClaw_OnPlayerHit_Pre(int pThis, DHookParam hParams) // Forward "L4D_TankClaw_OnPlayerHit_Pre"
{
	//PrintToServer("##### DTR_CTankClaw_OnPlayerHit_Pre");
	int tank = GetEntPropEnt(pThis, Prop_Data, "m_hOwner");
	int target = hParams.Get(1);
	// bool incap = hParams.Get(2); // Unknown usage, always returns "1"

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTankClaw_OnPlayerHit_Pre);
	Call_PushCell(tank);
	Call_PushCell(pThis);
	Call_PushCell(target);
	Call_Finish(aResult);

	// WORKS - Blocks target player being flung
	if( aResult == Plugin_Handled )
	{
		g_bBlock_CTankClaw_OnPlayerHit = true;

		return MRES_Supercede;
	}

	g_bBlock_CTankClaw_OnPlayerHit = false;

	return MRES_Ignored;
}

MRESReturn DTR_CTankClaw_OnPlayerHit_Post(int pThis, DHookParam hParams) // Forward "L4D_TankClaw_OnPlayerHit_Post" and "L4D_TankClaw_OnPlayerHit_PostHandled"
{
	//PrintToServer("##### DTR_CTankClaw_OnPlayerHit_Post");
	int tank = GetEntPropEnt(pThis, Prop_Data, "m_hOwner");
	int target = hParams.Get(1);
	// bool incap = hParams.Get(2);

	Call_StartForward(g_bBlock_CTankClaw_OnPlayerHit ? g_hFWD_CTankClaw_OnPlayerHit_PostHandled : g_hFWD_CTankClaw_OnPlayerHit_Post);
	Call_PushCell(tank);
	Call_PushCell(pThis);
	Call_PushCell(target);
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn DTR_CTankRock_Detonate(int pThis, DHookParam hParams) // Forward "L4D_TankRock_OnDetonate"
{
	//PrintToServer("##### DTR_CTankRock_Detonate");
	int tank = GetEntPropEnt(pThis, Prop_Data, "m_hThrower");

	Call_StartForward(g_hFWD_CTankRock_Detonate);
	Call_PushCell(tank);
	Call_PushCell(pThis);
	Call_Finish();

	// Freezes tank rock on hit, causes constant severe shake
	// return MRES_Supercede;

	return MRES_Ignored;
}

bool g_bCTankRock_OnRelease_Changed;
float g_fCTankRock_OnRelease_Angle[3];

MRESReturn DTR_CTankRock_OnRelease(DHookParam hParams) // Forward "L4D_TankRock_OnRelease"
{
	//PrintToServer("##### DTR_CTankRock_OnRelease");
	int pThis = hParams.Get(1);
	int tank = GetEntPropEnt(pThis, Prop_Data, "m_hThrower");

	float v1[3];
	float v2[3];
	float v3[3];
	float v4[3];

	if( g_bLeft4Dead2 || !g_bLinuxOS )
	{
		hParams.GetVector(2, v1); // vPos
		hParams.GetVector(3, v2); // vAng
		hParams.GetVector(4, v3); // vVel
		hParams.GetVector(5, v4); // vRot
	}
	else
	{
		float vPos[3];
		if( !GetAttachmentVectors(tank, "debris", vPos, v2) )
			v2 = view_as<float>({0.0, 0.0, 0.0});

		hParams.GetVector(2, v1); // vPos
		hParams.GetVector(3, v3); // vVel
		hParams.GetVector(4, v4); // vRot
	}

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTankRock_OnRelease);
	Call_PushCell(tank);
	Call_PushCell(pThis);
	Call_PushArrayEx(v1, sizeof(v1), SM_PARAM_COPYBACK);
	Call_PushArrayEx(v2, sizeof(v2), SM_PARAM_COPYBACK);
	Call_PushArrayEx(v3, sizeof(v3), SM_PARAM_COPYBACK);
	Call_PushArrayEx(v4, sizeof(v4), SM_PARAM_COPYBACK);
	Call_Finish(aResult);

	/*
	if( aResult == Plugin_Handled )
	{
		// Causes the rock to not be thrown, but stuck to the Tanks hand
		return MRES_Supercede;
	}
	// */

	if( aResult == Plugin_Changed )
	{
		if( g_bLeft4Dead2 || !g_bLinuxOS )
		{
			hParams.SetVector(2, v1);
			hParams.SetVector(3, v2);
			hParams.SetVector(4, v3);
			hParams.SetVector(5, v4);
		}
		else
		{
			g_bCTankRock_OnRelease_Changed = true;
			g_fCTankRock_OnRelease_Angle = v2;

			hParams.SetVector(2, v1);
			hParams.SetVector(3, v3);
			hParams.SetVector(4, v4);
		}
		return MRES_ChangedHandled;
	}

	return MRES_Ignored;
}

MRESReturn DTR_CTankRock_OnRelease_Post(DHookParam hParams) // Forward "L4D_TankRock_OnRelease_Post"
{
	//PrintToServer("##### DTR_CTankRock_OnRelease_Post");
	int pThis = hParams.Get(1);
	int tank = GetEntPropEnt(pThis, Prop_Data, "m_hThrower");

	float v1[3];
	float v2[3];
	float v3[3];
	float v4[3];

	if( g_bLeft4Dead2 || !g_bLinuxOS )
	{
		hParams.GetVector(2, v1); // vPos
		hParams.GetVector(3, v2); // vAng
		hParams.GetVector(4, v3); // vVel
		hParams.GetVector(5, v4); // vRot
	}
	else
	{
		// v2 = view_as<float>({0.0, 0.0, 0.0});
		// GetEntPropVector(pThis, Prop_Send, "m_angRotation", v2);
		if( g_bCTankRock_OnRelease_Changed )
		{
			g_bCTankRock_OnRelease_Changed = false;
			TeleportEntity(pThis, NULL_VECTOR, g_fCTankRock_OnRelease_Angle, NULL_VECTOR);
		}

		hParams.GetVector(2, v1); // vPos
		hParams.GetVector(3, v3); // vVel
		hParams.GetVector(4, v4); // vRot
	}

	Call_StartForward(g_hFWD_CTankRock_OnRelease_Post);
	Call_PushCell(tank);
	Call_PushCell(pThis);
	Call_PushArray(v1, sizeof(v1));
	Call_PushArray(v2, sizeof(v2));
	Call_PushArray(v3, sizeof(v3));
	Call_PushArray(v4, sizeof(v4));
	Call_Finish();

	return MRES_Ignored;
}

bool g_bBlock_CDirector_TryOfferingTankBot;
MRESReturn DTR_CDirector_TryOfferingTankBot(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnTryOfferingTankBot"
{
	//PrintToServer("##### DTR_CDirector_TryOfferingTankBot");
	int a1, a2;

	if( !hParams.IsNull(1) )
		a1 = hParams.Get(1);

	if( a1 == 0 ) return MRES_Ignored;

	a2 = hParams.Get(2);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CDirector_TryOfferingTankBot);
	Call_PushCell(a1);
	Call_PushCellRef(a2);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_CDirector_TryOfferingTankBot = true;

		hReturn.Value = -1;
		return MRES_Supercede;
	}

	g_bBlock_CDirector_TryOfferingTankBot = false;

	// UNKNOWN - PROBABLY WORKING
	if( aResult == Plugin_Changed )
	{
		hParams.Set(2, a2);
		hReturn.Value = hReturn.Value;

		return MRES_ChangedOverride;
	}

	return MRES_Ignored;
}

MRESReturn DTR_CDirector_TryOfferingTankBot_Post(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnTryOfferingTankBot_Post" and "L4D_OnTryOfferingTankBot_PostHandled"
{
	//PrintToServer("##### DTR_CDirector_TryOfferingTankBot_Post");
	int a1, a2;

	if( !hParams.IsNull(1) )
		a1 = hParams.Get(1);

	if( a1 == 0 ) return MRES_Ignored;

	a2 = hParams.Get(2);

	Call_StartForward(g_bBlock_CDirector_TryOfferingTankBot ? g_hFWD_CDirector_TryOfferingTankBot_PostHandled : g_hFWD_CDirector_TryOfferingTankBot_Post);
	Call_PushCell(a1);
	Call_PushCell(a2);
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn DTR_CDirector_TryOfferingTankBot_Clone(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnTryOfferingTankBot"
{
	//PrintToServer("##### DTR_CDirector_TryOfferingTankBot_Clone");
	int a1 = -1, a2;

	if( !hParams.IsNull(2) )
		a1 = hParams.Get(2);

	if( a1 == 0 ) return MRES_Ignored;

	a2 = hParams.Get(3);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CDirector_TryOfferingTankBot);
	Call_PushCell(a1);
	Call_PushCellRef(a2);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_CDirector_TryOfferingTankBot = true;

		hReturn.Value = -1;
		return MRES_Supercede;
	}

	g_bBlock_CDirector_TryOfferingTankBot = false;

	// UNKNOWN - PROBABLY WORKING
	if( aResult == Plugin_Changed )
	{
		hParams.Set(3, a2);

		return MRES_ChangedOverride;
	}

	return MRES_Ignored;
}

MRESReturn DTR_CDirector_TryOfferingTankBot_Clone_Post(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnTryOfferingTankBot_Post" and "L4D_OnTryOfferingTankBot_PostHandled"
{
	//PrintToServer("##### DTR_CDirector_TryOfferingTankBot_Clone_Post");
	int a1 = -1, a2;

	if( !hParams.IsNull(2) )
		a1 = hParams.Get(2);

	if( a1 == 0 ) return MRES_Ignored;

	a2 = hParams.Get(3);

	Call_StartForward(g_bBlock_CDirector_TryOfferingTankBot ? g_hFWD_CDirector_TryOfferingTankBot_PostHandled : g_hFWD_CDirector_TryOfferingTankBot_Post);
	Call_PushCell(a1);
	Call_PushCell(a2);
	Call_Finish();

	return MRES_Ignored;
}

bool g_bBlock_CThrow_ActivateAbililty;
MRESReturn DTR_CThrow_ActivateAbililty(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnCThrowActivate"
{
	//PrintToServer("##### DTR_CThrow_ActivateAbililty");
	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CThrow_ActivateAbililty);
	Call_PushCell(pThis);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_CThrow_ActivateAbililty = true;

		hReturn.Value = 0;
		return MRES_Supercede;
	}

	g_bBlock_CThrow_ActivateAbililty = false;

	return MRES_Ignored;
}

MRESReturn DTR_CThrow_ActivateAbililty_Post(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnCThrowActivate_Post" and "L4D_OnCThrowActivate_PostHandled"
{
	//PrintToServer("##### DTR_CThrow_ActivateAbililty_Post");
	Action aResult = Plugin_Continue;
	Call_StartForward(g_bBlock_CThrow_ActivateAbililty ? g_hFWD_CThrow_ActivateAbililty_PostHandled : g_hFWD_CThrow_ActivateAbililty_Post);
	Call_PushCell(pThis);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		hReturn.Value = 0;
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

MRESReturn DTR_CBaseAnimating_SelectWeightedSequence_Pre(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D2_OnSelectTankAttackPre"
{
	//PrintToServer("##### DTR_CBaseAnimating_SelectWeightedSequence_Pre");
	if( pThis < 1 || pThis > MaxClients || !IsClientInGame(pThis) ) return MRES_Ignored; // Ignore weapons etc

	int a1 = hParams.Get(1);
	Action aResult = Plugin_Continue;



	// ANIMATION HOOK
	int index = g_iAnimationHookedClients.FindValue(pThis);
	if( index != -1 )
	{
		Call_StartForward(g_hAnimationCallbackPre[pThis]);
		Call_PushCell(pThis);
		Call_PushCellRef(a1);
		Call_Finish(aResult);

		if( aResult == Plugin_Changed )
		{
			hParams.Set(1, a1);
			return MRES_ChangedHandled;
		}
	}



	// TANK ATTACK
	if( g_bLeft4Dead2 && a1 != L4D2_ACT_HULK_THROW && a1 != L4D2_ACT_TANK_OVERHEAD_THROW && a1 != L4D2_ACT_HULK_ATTACK_LOW && a1 != L4D2_ACT_TERROR_ATTACK_MOVING )
		return MRES_Ignored;

	if( !g_bLeft4Dead2 && a1 != L4D1_ACT_HULK_THROW && a1 != L4D1_ACT_TANK_OVERHEAD_THROW && a1 != L4D1_ACT_HULK_ATTACK_LOW && a1 != L4D1_ACT_TERROR_ATTACK_MOVING )
		return MRES_Ignored;

	if( GetClientTeam(pThis) != 3 || GetEntProp(pThis, Prop_Send, "m_zombieClass") != g_iClassTank )
		return MRES_Ignored;

	Call_StartForward(g_hFWD_CBaseAnimating_SelectWeightedSequence_Pre);
	Call_PushCell(pThis);
	Call_PushCellRef(a1);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		hParams.Set(1, a1);
		return MRES_ChangedHandled;
	}

	return MRES_Ignored;
}

MRESReturn DTR_CBaseAnimating_SelectWeightedSequence_Post(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D2_OnSelectTankAttack"
{
	//PrintToServer("##### DTR_CBaseAnimating_SelectWeightedSequence_Post");
	if( pThis < 1 || pThis > MaxClients || !IsClientInGame(pThis) ) return MRES_Ignored; // Ignore weapons etc

	int a1 = hReturn.Value;
	Action aResult = Plugin_Continue;



	// ANIMATION HOOK
	int index = g_iAnimationHookedClients.FindValue(pThis);
	if( index != -1 )
	{
		Call_StartForward(g_hAnimationCallbackPost[pThis]);
		Call_PushCell(pThis);
		Call_PushCellRef(a1);
		Call_Finish(aResult);

		if( aResult == Plugin_Changed )
		{
			hReturn.Value = a1;
			return MRES_Supercede;
		}
	}



	// TANK ATTACK
	if( g_bLeft4Dead2 && a1 != L4D2_SEQ_PUNCH_UPPERCUT && a1 != L4D2_SEQ_PUNCH_RIGHT_HOOK && a1 != L4D2_SEQ_PUNCH_LEFT_HOOK && a1 != L4D2_SEQ_PUNCH_POUND_GROUND1 &&
		a1 != L4D2_SEQ_PUNCH_POUND_GROUND2 && a1 != L4D2_SEQ_THROW_UNDERCUT && a1 != L4D2_SEQ_THROW_1HAND_OVER && a1 != L4D2_SEQ_THROW_FROM_HIP && a1 != L4D2_SEQ_THROW_2HAND_OVER )
		return MRES_Ignored;

	if( !g_bLeft4Dead2 && a1 != L4D1_SEQ_PUNCH_UPPERCUT && a1 != L4D1_SEQ_PUNCH_RIGHT_HOOK && a1 != L4D1_SEQ_PUNCH_LEFT_HOOK && a1 != L4D1_SEQ_PUNCH_POUND_GROUND1 &&
		a1 != L4D1_SEQ_PUNCH_POUND_GROUND2 && a1 != L4D1_SEQ_THROW_UNDERCUT && a1 != L4D1_SEQ_THROW_1HAND_OVER && a1 != L4D1_SEQ_THROW_FROM_HIP && a1 != L4D1_SEQ_THROW_2HAND_OVER )
		return MRES_Ignored;

	if( GetClientTeam(pThis) != 3 || GetEntProp(pThis, Prop_Send, "m_zombieClass") != g_iClassTank )
		return MRES_Ignored;

	Call_StartForward(g_hFWD_CBaseAnimating_SelectWeightedSequence_Post);
	Call_PushCell(pThis);
	Call_PushCellRef(a1);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		hReturn.Value = a1;
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

bool g_bBlock_CTerrorPlayer_DoAnimationEvent_Pre;
MRESReturn DTR_CTerrorPlayer_DoAnimationEvent_Pre(int pThis, DHookParam hParams) // Forward "L4D_OnDoAnimationEvent"
{
	//PrintToServer("##### DTR_CTerrorPlayer_DoAnimationEvent_Pre");
	int event = hParams.Get(1);
	int vari = hParams.Get(2);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorPlayer_DoAnimationEvent);
	Call_PushCell(pThis);
	Call_PushCellRef(event);
	Call_PushCellRef(vari);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_CTerrorPlayer_DoAnimationEvent_Pre = true;

		return MRES_Supercede;
	}

	g_bBlock_CTerrorPlayer_DoAnimationEvent_Pre = false;

	if( aResult == Plugin_Changed )
	{
		hParams.Set(1, event);
		hParams.Set(2, vari);
		return MRES_ChangedHandled;
	}

	return MRES_Ignored;
}

MRESReturn DTR_CTerrorPlayer_DoAnimationEvent(int pThis, DHookParam hParams) // Forward "L4D_OnDoAnimationEvent_Post" and "L4D_OnDoAnimationEvent_PostHandled"
{
	//PrintToServer("##### DTR_CTerrorPlayer_DoAnimationEvent");
	int event = hParams.Get(1);
	int vari = hParams.Get(2);

	Call_StartForward(g_bBlock_CTerrorPlayer_DoAnimationEvent_Pre ? g_hFWD_CTerrorPlayer_DoAnimationEvent_PostHandled : g_hFWD_CTerrorPlayer_DoAnimationEvent_Post);
	Call_PushCell(pThis);
	Call_PushCell(event);
	Call_PushCell(vari);
	Call_Finish();

	return MRES_Ignored;
}

bool g_bBlock_CTerrorMeleeWeapon_StartMeleeSwing_Post;
MRESReturn DTR_CTerrorMeleeWeapon_StartMeleeSwing(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnStartMeleeSwing"
{
	//PrintToServer("##### DTR_CTerrorMeleeWeapon_StartMeleeSwing");
	int a1 = hParams.Get(1);
	int a2 = hParams.Get(2);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_StartMeleeSwing);
	Call_PushCell(a1);
	Call_PushCell(a2);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_CTerrorMeleeWeapon_StartMeleeSwing_Post = true;

		hReturn.Value = 0;
		return MRES_Supercede;
	}

	g_bBlock_CTerrorMeleeWeapon_StartMeleeSwing_Post = false;

	return MRES_Ignored;
}

MRESReturn DTR_CTerrorMeleeWeapon_StartMeleeSwing_Post(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnStartMeleeSwing_Post" and "L4D_OnStartMeleeSwing_PostHandled"
{
	//PrintToServer("##### DTR_CTerrorMeleeWeapon_StartMeleeSwing_Post");
	int a1 = hParams.Get(1);
	int a2 = hParams.Get(2);

	Call_StartForward(g_bBlock_CTerrorMeleeWeapon_StartMeleeSwing_Post ? g_hFWD_StartMeleeSwing_PostHandled : g_hFWD_StartMeleeSwing_Post);
	Call_PushCell(a1);
	Call_PushCell(a2);
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn DTR_CTerrorMeleeWeapon_GetDamageForVictim_Pre(int pThis, DHookReturn hReturn, DHookParam hParams)
{
	//PrintToServer("##### DTR_CTerrorMeleeWeapon_GetDamageForVictim_Pre");
	return MRES_Ignored;
}

MRESReturn DTR_CTerrorMeleeWeapon_GetDamageForVictim_Post(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D2_MeleeGetDamageForVictim"
{
	//PrintToServer("##### DTR_CTerrorMeleeWeapon_GetDamageForVictim_Post");
	int victim = hParams.Get(1);
	if(! IsValidEdict(victim) )
		return MRES_Ignored;

	int client = GetEntPropEnt(pThis, Prop_Send, "m_hOwnerEntity");
	float damage = hReturn.Value;

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_GetDamageForVictim);
	Call_PushCell(client);
	Call_PushCell(pThis);
	Call_PushCell(victim);
	Call_PushFloatRef(damage);
	Call_Finish(aResult);

	if( aResult == Plugin_Changed )
	{
		hReturn.Value = damage;
		return MRES_Override;
	}

	if( aResult == Plugin_Handled )
	{
		hReturn.Value = 0.0;
		return MRES_Override;
	}

	return MRES_Ignored;
}

MRESReturn DTR_CDirectorScriptedEventManager_SendInRescueVehicle(DHookReturn hReturn) // Forward "L4D2_OnSendInRescueVehicle"
// MRESReturn DTR_CDirectorScriptedEventManager_SendInRescueVehicle(DHookParam hParams)
{
	//PrintToServer("##### DTR_CDirectorScriptedEventManager_SendInRescueVehicle");
	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CDirectorScriptedEventManager_SendInRescueVehicle);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		// hParams.SetObjectVar(1, 0, ObjectValueType_Int, 0);
		// hParams.SetObjectVar(1, 1, ObjectValueType_Int, 0);
		hReturn.Value = 0;
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

bool g_bBlock_CDirectorScriptedEventManager_ChangeFinaleStage;
MRESReturn DTR_CDirectorScriptedEventManager_ChangeFinaleStage(DHookReturn hReturn, DHookParam hParams) // Forward "L4D2_OnChangeFinaleStage"
{
	//PrintToServer("##### DTR_CDirectorScriptedEventManager_ChangeFinaleStage");
	int a1 = hParams.Get(1);

	static char a2[64];
	if( !hParams.IsNull(2) )
		hParams.GetString(2, a2, sizeof(a2));

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CDirectorScriptedEventManager_ChangeFinaleStage);
	Call_PushCellRef(a1);
	Call_PushString(a2);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_CDirectorScriptedEventManager_ChangeFinaleStage = true;

		hReturn.Value = 0;
		return MRES_Supercede;
	}

	g_bBlock_CDirectorScriptedEventManager_ChangeFinaleStage = false;

	if( aResult == Plugin_Changed )
	{
		hParams.Set(1, a1);
		hReturn.Value = a1;
		return MRES_ChangedOverride;
	}

	return MRES_Ignored;
}

MRESReturn DTR_CDirectorScriptedEventManager_ChangeFinaleStage_Post(DHookReturn hReturn, DHookParam hParams) // Forward "L4D2_OnChangeFinaleStage_Post" and "L4D2_OnChangeFinaleStage_PostHandled"
{
	//PrintToServer("##### DTR_CDirectorScriptedEventManager_ChangeFinaleStage_Post");
	int a1 = hParams.Get(1);

	static char a2[64];
	if( !hParams.IsNull(2) )
		hParams.GetString(2, a2, sizeof(a2));

	Call_StartForward(g_bBlock_CDirectorScriptedEventManager_ChangeFinaleStage ? g_hFWD_CDirectorScriptedEventManager_ChangeFinaleStage_PostPost : g_hFWD_CDirectorScriptedEventManager_ChangeFinaleStage_Post);
	Call_PushCell(a1);
	Call_PushString(a2);
	Call_Finish();

	return MRES_Ignored;
}

bool g_bBlock_CDirectorVersusMode_EndVersusModeRound;
MRESReturn DTR_CDirectorVersusMode_EndVersusModeRound_Pre(DHookReturn hReturn, DHookParam hParams) // Forward "L4D2_OnEndVersusModeRound"
{
	//PrintToServer("##### DTR_CDirectorVersusMode_EndVersusModeRound_Pre");
	if( g_bRoundEnded ) return MRES_Ignored;

	int a1 = hParams.Get(1);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CDirectorVersusMode_EndVersusModeRound_Pre);
	Call_PushCell(a1);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_CDirectorVersusMode_EndVersusModeRound = true;

		hReturn.Value = 0;
		return MRES_Supercede;
	}

	g_bBlock_CDirectorVersusMode_EndVersusModeRound = false;

	return MRES_Ignored;
}

MRESReturn DTR_CDirectorVersusMode_EndVersusModeRound_Post(DHookReturn hReturn, DHookParam hParams) // Forward "L4D2_OnEndVersusModeRound_Post" and "L4D2_OnEndVersusModeRound_PostHandled"
{
	//PrintToServer("##### DTR_CDirectorVersusMode_EndVersusModeRound_Post");
	if( g_bRoundEnded ) return MRES_Ignored;
	g_bRoundEnded = true;

	Call_StartForward(g_bBlock_CDirectorVersusMode_EndVersusModeRound ? g_hFWD_CDirectorVersusMode_EndVersusModeRound_PostHandled : g_hFWD_CDirectorVersusMode_EndVersusModeRound_Post);
	Call_Finish();

	return MRES_Ignored;
}

bool g_bBlock_CTerrorPlayer_OnLedgeGrabbed;
MRESReturn DTR_CTerrorPlayer_OnLedgeGrabbed(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnLedgeGrabbed"
{
	//PrintToServer("##### DTR_CTerrorPlayer_OnLedgeGrabbed");
	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorPlayer_OnLedgeGrabbed);
	Call_PushCell(pThis);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_CTerrorPlayer_OnLedgeGrabbed = true;

		return MRES_Supercede;
	}

	g_bBlock_CTerrorPlayer_OnLedgeGrabbed = false;

	return MRES_Ignored;
}

MRESReturn DTR_CTerrorPlayer_OnLedgeGrabbed_Post(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnLedgeGrabbed_Post" and "L4D_OnLedgeGrabbed_PostHandled"
{
	//PrintToServer("##### DTR_CTerrorPlayer_OnLedgeGrabbed_Post");
	Call_StartForward(g_bBlock_CTerrorPlayer_OnLedgeGrabbed ? g_hFWD_CTerrorPlayer_OnLedgeGrabbed_PostHandled : g_hFWD_CTerrorPlayer_OnLedgeGrabbed_Post);
	Call_PushCell(pThis);
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn DTR_CTerrorPlayer_OnRevived_Pre(int pThis, DHookReturn hReturn, DHookParam hParams)
{
	//PrintToServer("##### DTR_CTerrorPlayer_OnRevived_Pre");
	return MRES_Ignored;
}

MRESReturn DTR_CTerrorPlayer_OnRevived_Post(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D2_OnRevived"
{
	//PrintToServer("##### DTR_CTerrorPlayer_OnRevived_Post");
	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorPlayer_OnRevived_Post);
	Call_PushCell(pThis);
	Call_Finish(aResult);

	return MRES_Ignored;
}

bool g_bBlock_CTerrorPlayer_OnStaggered;
MRESReturn DTR_CTerrorPlayer_OnStaggered(int pThis, DHookParam hParams) // Forward "L4D2_OnStagger"
{
	//PrintToServer("##### DTR_CTerrorPlayer_OnStaggered");
	int source = -1;

	if( !hParams.IsNull(1) )
		source = hParams.Get(1);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorPlayer_OnStaggered);
	Call_PushCell(pThis);
	Call_PushCell(source);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_CTerrorPlayer_OnStaggered = true;

		return MRES_Supercede;
	}

	g_bBlock_CTerrorPlayer_OnStaggered = false;

	return MRES_Ignored;
}

MRESReturn DTR_CTerrorPlayer_OnStaggered_Post(int pThis, DHookParam hParams) // Forward "L4D2_OnStagger_Post" and "L4D2_OnStagger_PostHandled"
{
	//PrintToServer("##### DTR_CTerrorPlayer_OnStaggered_Post");
	int source = -1;

	if( !hParams.IsNull(1) )
		source = hParams.Get(1);

	Call_StartForward(g_bBlock_CTerrorPlayer_OnStaggered ? g_hFWD_CTerrorPlayer_OnStaggered_PostHandled : g_hFWD_CTerrorPlayer_OnStaggered_Post);
	Call_PushCell(pThis);
	Call_PushCell(source);
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn DTR_CTerrorPlayer_OnStaggered_Clone(DHookParam hParams) // Forward "L4D2_OnStagger"
{
	//PrintToServer("##### DTR_CTerrorPlayer_OnStaggered_Clone");
	int target = hParams.Get(1);

	int source = -1;

	if( !hParams.IsNull(2) )
		source = hParams.Get(2);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorPlayer_OnStaggered);
	Call_PushCell(target);
	Call_PushCell(source);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_CTerrorPlayer_OnStaggered = true;

		return MRES_Supercede;
	}

	g_bBlock_CTerrorPlayer_OnStaggered = false;

	return MRES_Ignored;
}

MRESReturn DTR_CTerrorPlayer_OnStaggered_Clone_Post(DHookParam hParams) // Forward "L4D2_OnStagger_Post" and "L4D2_OnStagger_PostHandled"
{
	//PrintToServer("##### DTR_CTerrorPlayer_OnStaggered_Clone_Post");
	int target = hParams.Get(1);

	int source = -1;

	if( !hParams.IsNull(2) )
		source = hParams.Get(2);

	Call_StartForward(g_bBlock_CTerrorPlayer_OnStaggered ? g_hFWD_CTerrorPlayer_OnStaggered_PostHandled : g_hFWD_CTerrorPlayer_OnStaggered_Post);
	Call_PushCell(target);
	Call_PushCell(source);
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn DTR_CTerrorWeapon_OnSwingStart(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnSwingStart"
{
	//PrintToServer("##### DTR_CTerrorWeapon_OnSwingStart");
	if( pThis == -1 ) return MRES_Ignored;
	int client = GetEntPropEnt(pThis, Prop_Send, "m_hOwnerEntity");

	Call_StartForward(g_hFWD_CTerrorWeapon_OnSwingStart);
	Call_PushCell(client);
	Call_PushCell(pThis);
	Call_Finish();

	return MRES_Ignored;
}

bool g_bBlock_CTerrorPlayer_OnShovedBySurvivor;
MRESReturn DTR_CTerrorPlayer_OnShovedBySurvivor(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnShovedBySurvivor"
{
	//PrintToServer("##### DTR_CTerrorPlayer_OnShovedBySurvivor");
	if( hParams.IsNull(1) ) return MRES_Ignored;

	float a2[3];
	int a1 = hParams.Get(1);
	hParams.GetVector(2, a2);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorPlayer_OnShovedBySurvivor);
	Call_PushCell(a1);
	Call_PushCell(pThis);
	Call_PushArray(a2, sizeof(a2));
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_CTerrorPlayer_OnShovedBySurvivor = true;

		hReturn.Value = 0;
		return MRES_Supercede;
	}

	g_bBlock_CTerrorPlayer_OnShovedBySurvivor = false;

	return MRES_Ignored;
}

MRESReturn DTR_CTerrorPlayer_OnShovedBySurvivor_Post(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnShovedBySurvivor_Post" and "L4D_OnShovedBySurvivor_PostHandled"
{
	//PrintToServer("##### DTR_CTerrorPlayer_OnShovedBySurvivor_Post");
	if( hParams.IsNull(1) ) return MRES_Ignored;

	float a2[3];
	int a1 = hParams.Get(1);
	hParams.GetVector(2, a2);

	Call_StartForward(g_bBlock_CTerrorPlayer_OnShovedBySurvivor ? g_hFWD_CTerrorPlayer_OnShovedBySurvivor_PostHandled : g_hFWD_CTerrorPlayer_OnShovedBySurvivor_Post);
	Call_PushCell(a1);
	Call_PushCell(pThis);
	Call_PushArray(a2, sizeof(a2));
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn DTR_CTerrorPlayer_OnShovedBySurvivor_Clone(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnShovedBySurvivor"
{
	//PrintToServer("##### DTR_CTerrorPlayer_OnShovedBySurvivor_Clone");
	if( hParams.IsNull(1) ) return MRES_Ignored;

	float a3[3];
	int a1 = hParams.Get(1);
	int a2 = hParams.Get(2);
	hParams.GetVector(3, a3);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorPlayer_OnShovedBySurvivor);
	Call_PushCell(a2);
	Call_PushCell(a1);
	Call_PushArray(a3, sizeof(a3));
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_CTerrorPlayer_OnShovedBySurvivor = true;

		hReturn.Value = 0;
		return MRES_Supercede;
	}

	g_bBlock_CTerrorPlayer_OnShovedBySurvivor = false;

	return MRES_Ignored;
}

MRESReturn DTR_CTerrorPlayer_OnShovedBySurvivor_Clone_Post(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnShovedBySurvivor_Post" and "L4D_OnShovedBySurvivor_PostHandled"
{
	//PrintToServer("##### DTR_CTerrorPlayer_OnShovedBySurvivor_Clone_Post");
	if( hParams.IsNull(1) ) return MRES_Ignored;

	float a3[3];
	int a1 = hParams.Get(1);
	int a2 = hParams.Get(2);
	hParams.GetVector(3, a3);

	Call_StartForward(g_bBlock_CTerrorPlayer_OnShovedBySurvivor ? g_hFWD_CTerrorPlayer_OnShovedBySurvivor_PostHandled : g_hFWD_CTerrorPlayer_OnShovedBySurvivor_Post);
	Call_PushCell(a2);
	Call_PushCell(a1);
	Call_PushArray(a3, sizeof(a3));
	Call_Finish();

	return MRES_Ignored;
}

bool g_bIsPouncing;
bool g_bBlock_CTerrorWeapon_OnHit;
MRESReturn DTR_CTerrorWeapon_OnHit(int weapon, DHookReturn hReturn, DHookParam hParams) // Forward "L4D2_OnEntityShoved"
{
	g_bIsPouncing = false;
	g_bBlock_CTerrorWeapon_OnHit = false;

	//PrintToServer("##### DTR_CTerrorWeapon_OnHit");
	bool userCall = hParams.Get(3);
	if( userCall )
	{
		// CTerrorWeapon::OnHit(CGameTrace &, Vector const&, bool)
		// Get target from CGameTrace
		/*
		int trace = hParams.Get(1);
		int target = LoadFromAddress(view_as<Address>(trace + 76), NumberType_Int32);
		if( !target ) return MRES_Ignored;

		// Returns entity address, get entity or client index
		target = GetEntityFromAddress(target);
		if( !target ) target = GetClientFromAddress(target);
		// */

		// Thanks to "A1m`" for this solution to getting an entity index instead of looping clients/entities:
		int target = hParams.GetObjectVar(1, 76, ObjectValueType_CBaseEntityPtr);
		if( !target ) return MRES_Ignored;

		// Verify client hitting
		int client = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
		if( client > 0 && client <= MaxClients )
		{
			// Dead stop option - not always correct but should show if hunter was pouncing while punched
			if( target > 0 && target <= MaxClients )
			{
				// deadStop = LoadFromAddress(view_as<Address>(target + 16024), NumberType_Int32) > 0;
				g_bIsPouncing = GetEntProp(target, Prop_Send, "m_isAttemptingToPounce") > 0;
			}

			float vec[3];
			hParams.GetVector(2, vec);

			Action aResult = Plugin_Continue;
			Call_StartForward(g_hFWD_CTerrorWeapon_OnHit);
			Call_PushCell(client);
			Call_PushCell(target);
			Call_PushCell(weapon);
			Call_PushArray(vec, sizeof(vec));
			Call_PushCell(g_bIsPouncing);
			Call_Finish(aResult);

			if( aResult == Plugin_Handled )
			{
				g_bBlock_CTerrorWeapon_OnHit = true;

				hReturn.Value = 0;
				return MRES_Supercede;
			}
		}
	}
	return MRES_Ignored;
}

MRESReturn DTR_CTerrorWeapon_OnHit_Post(int weapon, DHookReturn hReturn, DHookParam hParams) // Forward "L4D2_OnEntityShoved_Post" and "L4D2_OnEntityShoved_PostHandled"
{
	//PrintToServer("##### DTR_CTerrorWeapon_OnHit_Post");
	bool userCall = hParams.Get(3);
	if( userCall )
	{
		// CTerrorWeapon::OnHit(CGameTrace &, Vector const&, bool)
		// Get target from CGameTrace
		/*
		int trace = hParams.Get(1);
		int target = LoadFromAddress(view_as<Address>(trace + 76), NumberType_Int32);
		if( !target ) return MRES_Ignored;

		// Returns entity address, get entity or client index
		target = GetEntityFromAddress(target);
		if( !target ) target = GetClientFromAddress(target);
		// */

		// Thanks to "A1m`" for this solution to getting an entity index instead of looping clients/entities:
		int target = hParams.GetObjectVar(1, 76, ObjectValueType_CBaseEntityPtr);
		if( !target ) return MRES_Ignored;

		// Verify client hitting
		int client = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
		if( client > 0 && client <= MaxClients )
		{
			float vec[3];
			hParams.GetVector(2, vec);

			Call_StartForward(g_bBlock_CTerrorWeapon_OnHit ? g_hFWD_CTerrorWeapon_OnHit_PostHandled : g_hFWD_CTerrorWeapon_OnHit_Post);
			Call_PushCell(client);
			Call_PushCell(target);
			Call_PushCell(weapon);
			Call_PushArray(vec, sizeof(vec));
			Call_PushCell(g_bIsPouncing);
			Call_Finish();
		}
	}
	return MRES_Ignored;
}

bool g_bBlock_CTerrorPlayer_OnShovedByPounceLanding;
MRESReturn DTR_CTerrorPlayer_OnShovedByPounceLanding(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D2_OnPounceOrLeapStumble"
{
	//PrintToServer("##### DTR_CTerrorPlayer_OnShovedByPounceLanding");
	int a1 = hParams.Get(1);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorPlayer_OnShovedByPounceLanding);
	Call_PushCell(pThis);
	Call_PushCell(a1);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_CTerrorPlayer_OnShovedByPounceLanding = true;

		hReturn.Value = 0.0;
		return MRES_Supercede;
	}

	g_bBlock_CTerrorPlayer_OnShovedByPounceLanding = false;

	return MRES_Ignored;
}

MRESReturn DTR_CTerrorPlayer_OnShovedByPounceLanding_Post(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D2_OnPounceOrLeapStumble_Post" and "L4D2_OnPounceOrLeapStumble_PostHandled"
{
	//PrintToServer("##### DTR_CTerrorPlayer_OnShovedByPounceLanding_Post");
	int a1 = hParams.Get(1);

	Call_StartForward(g_bBlock_CTerrorPlayer_OnShovedByPounceLanding ? g_hFWD_CTerrorPlayer_OnShovedByPounceLanding_PostHandled : g_hFWD_CTerrorPlayer_OnShovedByPounceLanding_Post);
	Call_PushCell(pThis);
	Call_PushCell(a1);
	Call_Finish();

	return MRES_Ignored;
}

bool g_bBlock_CTerrorPlayer_OnKnockedDown;
MRESReturn DTR_CTerrorPlayer_OnKnockedDown(int pThis, DHookParam hParams) // Forward "L4D_OnKnockedDown"
{
	//PrintToServer("##### DTR_CTerrorPlayer_OnKnockedDown");
	int reason = hParams.Get(1);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorPlayer_OnKnockedDown);
	Call_PushCell(pThis);
	Call_PushCell(reason);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_CTerrorPlayer_OnKnockedDown = true;

		return MRES_Supercede;
	}

	g_bBlock_CTerrorPlayer_OnKnockedDown = false;

	return MRES_Ignored;
}

MRESReturn DTR_CTerrorPlayer_OnKnockedDown_Post(int pThis, DHookParam hParams) // Forward "L4D_OnKnockedDown_Post" and "L4D_OnKnockedDown_PostHandled"
{
	//PrintToServer("##### DTR_CTerrorPlayer_OnKnockedDown_Post");
	int reason = hParams.Get(1);

	Call_StartForward(g_bBlock_CTerrorPlayer_OnKnockedDown ? g_hFWD_CTerrorPlayer_OnKnockedDown_PostHandled : g_hFWD_CTerrorPlayer_OnKnockedDown_Post);
	Call_PushCell(pThis);
	Call_PushCell(reason);
	Call_Finish();

	return MRES_Ignored;
}

bool g_bBlock_CTerrorPlayer_OnSlammedSurvivor;
MRESReturn DTR_CTerrorPlayer_OnSlammedSurvivor(int pThis, DHookParam hParams) // Forward "L4D2_OnSlammedSurvivor"
{
	//PrintToServer("##### DTR_CTerrorPlayer_OnSlammedSurvivor");
	if( hParams.IsNull(1) ) return MRES_Ignored;

	int victim = hParams.Get(1);
	bool bWall = hParams.Get(2);
	bool bDeadly = hParams.Get(3);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorPlayer_OnSlammedSurvivor);
	Call_PushCell(victim);
	Call_PushCell(pThis);
	Call_PushCellRef(bWall);
	Call_PushCellRef(bDeadly);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_CTerrorPlayer_OnSlammedSurvivor = true;
		return MRES_Supercede;
	}

	g_bBlock_CTerrorPlayer_OnSlammedSurvivor = false;

	if( aResult == Plugin_Changed )
	{
		hParams.Set(2, bWall);
		hParams.Set(3, bDeadly);
		return MRES_ChangedHandled;
	}

	return MRES_Ignored;
}

MRESReturn DTR_CTerrorPlayer_OnSlammedSurvivor_Post(int pThis, DHookParam hParams) // Forward "L4D2_OnSlammedSurvivor_Post" and "L4D2_OnSlammedSurvivor_PostHandled"
{
	//PrintToServer("##### DTR_CTerrorPlayer_OnSlammedSurvivor_Post");
	int victim;
	if( !hParams.IsNull(1) )
		victim = hParams.Get(1);

	bool bWall = hParams.Get(2);
	bool bDeadly = hParams.Get(3);

	Call_StartForward(g_bBlock_CTerrorPlayer_OnSlammedSurvivor ? g_hFWD_CTerrorPlayer_OnSlammedSurvivor_PostHandled : g_hFWD_CTerrorPlayer_OnSlammedSurvivor_Post);
	Call_PushCell(victim);
	Call_PushCell(pThis);
	Call_PushCell(bWall);
	Call_PushCell(bDeadly);
	Call_Finish();

	return MRES_Ignored;
}

bool g_bBlock_CTerrorPlayer_QueuePummelVictim;
MRESReturn DTR_CTerrorPlayer_QueuePummelVictim(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D2_OnPummelVictim"
{
	//PrintToServer("##### DTR_CTerrorPlayer_QueuePummelVictim");
	if( hParams.IsNull(1) ) return MRES_Ignored;

	int victim = hParams.Get(1);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorPlayer_QueuePummelVictim);
	Call_PushCell(pThis);
	Call_PushCell(victim);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_CTerrorPlayer_QueuePummelVictim = true;

		SetEntityMoveType(victim, MOVETYPE_WALK); // Prevent frozen with constant walking on spot bug

		hReturn.Value = 0;
		return MRES_Supercede;
	}

	g_bBlock_CTerrorPlayer_QueuePummelVictim = false;

	return MRES_Ignored;
}

MRESReturn DTR_CTerrorPlayer_QueuePummelVictim_Post(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D2_OnPummelVictim_Post" and "L4D2_OnPummelVictim_PostHandled"
{
	//PrintToServer("##### DTR_CTerrorPlayer_QueuePummelVictim_Post");
	int victim;
	if( !hParams.IsNull(1) )
		victim = hParams.Get(1);

	Call_StartForward(g_bBlock_CTerrorPlayer_QueuePummelVictim ? g_hFWD_CTerrorPlayer_QueuePummelVictim_PostHandled : g_hFWD_CTerrorPlayer_QueuePummelVictim_Post);
	Call_PushCell(pThis);
	Call_PushCell(victim);
	Call_Finish();

	return MRES_Ignored;
}

bool g_bBlock_ThrowImpactedSurvivor;
MRESReturn DTR_ThrowImpactedSurvivor(DHookReturn hReturn, DHookParam hParams) // Forward "L4D2_OnThrowImpactedSurvivor"
{
	//PrintToServer("##### DTR_ThrowImpactedSurvivor");
	int attacker = hParams.Get(1);
	int victim = hParams.Get(2);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_ThrowImpactedSurvivor);
	Call_PushCell(attacker);
	Call_PushCell(victim);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_ThrowImpactedSurvivor = true;

		hReturn.Value = 0;
		return MRES_Supercede;
	}

	g_bBlock_ThrowImpactedSurvivor = false;

	return MRES_Ignored;
}

MRESReturn DTR_ThrowImpactedSurvivor_Post(DHookReturn hReturn, DHookParam hParams) // Forward "L4D2_OnThrowImpactedSurvivor_Post" and "L4D2_OnThrowImpactedSurvivor_PostHandled"
{
	//PrintToServer("##### DTR_ThrowImpactedSurvivor_Post");
	int attacker = hParams.Get(1);
	int victim = hParams.Get(2);

	Call_StartForward(g_bBlock_ThrowImpactedSurvivor ? g_hFWD_ThrowImpactedSurvivor_PostHandled : g_hFWD_ThrowImpactedSurvivor_Post);
	Call_PushCell(attacker);
	Call_PushCell(victim);
	Call_Finish();

	return MRES_Ignored;
}

bool g_bBlock_CTerrorPlayer_CancelStagger;
MRESReturn DTR_CTerrorPlayer_CancelStagger(int pThis, DHookParam hParams) // Forward "L4D_OnCancelStagger"
{
	//PrintToServer("##### DTR_CTerrorPlayer_CancelStagger");

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorPlayer_CancelStagger);
	Call_PushCell(pThis);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_CTerrorPlayer_CancelStagger = true;

		return MRES_Supercede;
	}

	g_bBlock_CTerrorPlayer_CancelStagger = false;

	return MRES_Ignored;
}

MRESReturn DTR_CTerrorPlayer_CancelStagger_Post(int pThis, DHookParam hParams) // Forward "L4D_OnCancelStagger_Post" and "L4D_OnCancelStagger_PostHandled"
{
	Call_StartForward(g_bBlock_CTerrorPlayer_CancelStagger ? g_hFWD_CTerrorPlayer_CancelStagger_PostHandled : g_hFWD_CTerrorPlayer_CancelStagger_Post);
	Call_PushCell(pThis);
	Call_Finish();

	return MRES_Ignored;
}

bool g_bBlock_CTerrorPlayer_Fling;
MRESReturn DTR_CTerrorPlayer_Fling(int pThis, DHookParam hParams) // Forward "L4D2_OnPlayerFling"
{
	//PrintToServer("##### DTR_CTerrorPlayer_Fling");
	float vPos[3];
	int attacker = hParams.Get(3);
	hParams.GetVector(1, vPos);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorPlayer_Fling);
	Call_PushCell(pThis);
	Call_PushCell(attacker);
	Call_PushArray(vPos, sizeof(vPos));
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_CTerrorPlayer_Fling = true;

		return MRES_Supercede;
	}

	g_bBlock_CTerrorPlayer_Fling = false;

	return MRES_Ignored;
}

MRESReturn DTR_CTerrorPlayer_Fling_Post(int pThis, DHookParam hParams) // Forward "L4D2_OnPlayerFling_Post" and "L4D2_OnPlayerFling_PostHandled"
{
	//PrintToServer("##### DTR_CTerrorPlayer_Fling_Post");
	float vPos[3];
	int attacker = hParams.Get(3);
	hParams.GetVector(1, vPos);

	Call_StartForward(g_bBlock_CTerrorPlayer_Fling ? g_hFWD_CTerrorPlayer_Fling_PostHandled : g_hFWD_CTerrorPlayer_Fling_Post);
	Call_PushCell(pThis);
	Call_PushCell(attacker);
	Call_PushArray(vPos, sizeof(vPos));
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn DTR_CTerrorPlayer_IsMotionControlledXY(int client, DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnMotionControlledXY"
{
	//PrintToServer("##### DTR_CTerrorPlayer_IsMotionControlledXY");
	int activity = hParams.Get(1);

	if( g_bLeft4Dead2 )
	{
		switch( activity )
		{
			case
				L4D2_ACT_TERROR_SHOVED_FORWARD,
				L4D2_ACT_TERROR_SHOVED_BACKWARD,
				L4D2_ACT_TERROR_SHOVED_LEFTWARD,
				L4D2_ACT_TERROR_SHOVED_RIGHTWARD,
				L4D2_ACT_TERROR_SHOVED_FORWARD_CHAINSAW,
				L4D2_ACT_TERROR_SHOVED_BACKWARD_CHAINSAW,
				L4D2_ACT_TERROR_SHOVED_LEFTWARD_CHAINSAW,
				L4D2_ACT_TERROR_SHOVED_RIGHTWARD_CHAINSAW,
				L4D2_ACT_TERROR_SHOVED_FORWARD_BAT,
				L4D2_ACT_TERROR_SHOVED_BACKWARD_BAT,
				L4D2_ACT_TERROR_SHOVED_LEFTWARD_BAT,
				L4D2_ACT_TERROR_SHOVED_RIGHTWARD_BAT,
				L4D2_ACT_TERROR_SHOVED_FORWARD_MELEE,
				L4D2_ACT_TERROR_SHOVED_BACKWARD_MELEE,
				L4D2_ACT_TERROR_SHOVED_LEFTWARD_MELEE,
				L4D2_ACT_TERROR_SHOVED_RIGHTWARD_MELEE,
				L4D2_ACT_TERROR_HUNTER_POUNCE_KNOCKOFF_L,
				L4D2_ACT_TERROR_HUNTER_POUNCE_KNOCKOFF_R,
				L4D2_ACT_TERROR_HUNTER_POUNCE_KNOCKOFF_BACKWARD,
				L4D2_ACT_TERROR_HUNTER_POUNCE_KNOCKOFF_FORWARD:
			{
			}
			default: return MRES_Ignored;
		}
	}
	else
	{
		switch( activity )
		{
			case
				L4D1_ACT_TERROR_SHOVED_FORWARD,
				L4D1_ACT_TERROR_SHOVED_BACKWARD,
				L4D1_ACT_TERROR_SHOVED_LEFTWARD,
				L4D1_ACT_TERROR_SHOVED_RIGHTWARD,
				L4D1_ACT_TERROR_HUNTER_POUNCE_KNOCKOFF_L,
				L4D1_ACT_TERROR_HUNTER_POUNCE_KNOCKOFF_R,
				L4D1_ACT_TERROR_HUNTER_POUNCE_KNOCKOFF_BACKWARD,
				L4D1_ACT_TERROR_HUNTER_POUNCE_KNOCKOFF_FORWARD:
			{
			}
			default: return MRES_Ignored;
		}
	}

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorPlayer_IsMotionControlledXY);
	Call_PushCell(client);
	Call_PushCell(activity);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		// Prevent jumping, since it's unblocked when this function returns false
		SetEntPropFloat(client, Prop_Send, "m_jumpSupressedUntil", GetGameTime() + 0.1);

		hReturn.Value = 0;
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

MRESReturn DTR_CDeathFallCamera_Enable(int pThis, DHookParam hParams) // Forward "L4D_OnFatalFalling"
{
	//PrintToServer("##### DTR_CDeathFallCamera_Enable");
	int client;

	if( !hParams.IsNull(1) )
		client = hParams.Get(1);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CDeathFallCamera_Enable);
	Call_PushCell(client);
	Call_PushCell(pThis);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

MRESReturn DTR_CTerrorPlayer_OnFalling_Pre(int pThis, DHookReturn hReturn)
{
	//PrintToServer("##### DTR_CTerrorPlayer_OnFalling_Pre");
	return MRES_Ignored;
}

MRESReturn DTR_CTerrorPlayer_OnFalling_Post(int pThis, DHookReturn hReturn) // Forward "L4D_OnFalling"
{
	//PrintToServer("##### DTR_CTerrorPlayer_OnFalling_Post");
	Call_StartForward(g_hFWD_CTerrorPlayer_OnFalling_Post);
	Call_PushCell(pThis);
	Call_Finish();

	return MRES_Ignored;
}

bool g_bBlock_CTerrorPlayer_Cough;
MRESReturn DTR_CTerrorPlayer_Cough(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnPlayerCough"
{
	//PrintToServer("##### DTR_CTerrorPlayer_Cough");

	int attacker;

	if( !hParams.IsNull(1) )
		attacker = hParams.Get(1);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorPlayer_Cough);
	Call_PushCell(pThis);
	Call_PushCell(attacker);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_CTerrorPlayer_Cough = true;

		hReturn.Value = 0;
		return MRES_Supercede;
	}

	g_bBlock_CTerrorPlayer_Cough = false;

	return MRES_Ignored;
}

MRESReturn DTR_CTerrorPlayer_Cough_Post(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnPlayerCough_Post" abd "L4D_OnPlayerCough_PostHandled"
{
	int attacker;

	if( !hParams.IsNull(1) )
		attacker = hParams.Get(1);

	Call_StartForward(g_bBlock_CTerrorPlayer_Cough ? g_hFWD_CTerrorPlayer_Cough_PostHandled : g_hFWD_CTerrorPlayer_Cough_Post);
	Call_PushCell(pThis);
	Call_PushCell(attacker);
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn DTR_Witch_SetHarasser(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnWitchSetHarasser"
{
	//PrintToServer("##### DTR_Witch_SetHarasser");
	int victim;
	if( !hParams.IsNull(1) )
		victim = hParams.Get(1);

	Call_StartForward(g_hFWD_Witch_SetHarasser);
	Call_PushCell(pThis);
	Call_PushCell(victim);
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn DTR_Tank_EnterStasis_Pre(int pThis, DHookReturn hReturn)
{
	//PrintToServer("##### DTR_Tank_EnterStasis_Pre");
	return MRES_Ignored;
}

MRESReturn DTR_Tank_EnterStasis_Post(int pThis, DHookReturn hReturn) // Forward "L4D_OnEnterStasis"
{
	//PrintToServer("##### DTR_Tank_EnterStasis_Post");
	Call_StartForward(g_hFWD_Tank_EnterStasis_Post);
	Call_PushCell(pThis);
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn DTR_Tank_LeaveStasis_Pre(int pThis, DHookReturn hReturn)
{
	//PrintToServer("##### DTR_Tank_LeaveStasis_Pre");
	return MRES_Ignored;
}

MRESReturn DTR_Tank_LeaveStasis_Post(int pThis, DHookReturn hReturn) // Forward "L4D_OnLeaveStasis"
{
	//PrintToServer("##### DTR_Tank_LeaveStasis_Post");
	Call_StartForward(g_hFWD_Tank_LeaveStasis_Post);
	Call_PushCell(pThis);
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn DTR_CInferno_Spread(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D2_OnSpitSpread"
{
	//PrintToServer("##### DTR_CInferno_Spread");
	float vPos[3];
	hParams.GetVector(1, vPos);

	int client = GetEntPropEnt(pThis, Prop_Send, "m_hOwnerEntity");

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CInferno_Spread);
	Call_PushCell(client);
	Call_PushCell(pThis);
	Call_PushFloatRef(vPos[0]);
	Call_PushFloatRef(vPos[1]);
	Call_PushFloatRef(vPos[2]);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		hReturn.Value = 0;
		return MRES_Supercede;
	}

	if( aResult == Plugin_Changed )
	{
		hParams.SetVector(1, vPos);
		hReturn.Value = 1;
		return MRES_ChangedHandled;
	}

	return MRES_Ignored;
}

MRESReturn DTR_CTerrorPlayer_Extinguish(int client) // Forward "L4D_PlayerExtinguish"
{
	//PrintToServer("##### DTR_CTerrorPlayer_Extinguish");

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorPlayer_Extinguish);
	Call_PushCell(client);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

MRESReturn DTR_SurvivorBot_UseHealingItems(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D2_OnUseHealingItems"
// MRESReturn DTR_SurvivorBot_UseHealingItems(DHookParam hParams)
{
	//PrintToServer("##### DTR_SurvivorBot_UseHealingItems");
	// int pThis = hParams.Get(2);
	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_SurvivorBot_UseHealingItems);
	Call_PushCell(pThis);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		// hParams.SetObjectVar(1, 0, ObjectValueType_Int, 0);
		// hParams.GetObjectVarString(1, 1, ObjectValueType_Int, 0);
		hReturn.Value = 0;
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

MRESReturn DTR_SurvivorBot_FindScavengeItem_Pre(int pThis, DHookReturn hReturn, DHookParam hParams)
{
	//PrintToServer("##### DTR_SurvivorBot_FindScavengeItem_Pre");
	return MRES_Ignored;
}

MRESReturn DTR_SurvivorBot_FindScavengeItem_Post(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D2_OnFindScavengeItem"
{
	//PrintToServer("##### DTR_SurvivorBot_FindScavengeItem_Post");
	int a1 = hReturn.Value;
	if( a1 == -1 ) a1 = 0;

	// Scan distance or something? If you find out please let me know, I'm interested. Haven't bothered testing.
	// float a2 = hParams.Get(1);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_SurvivorBot_FindScavengeItem_Post);
	Call_PushCell(pThis);
	Call_PushCellRef(a1);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		hReturn.Value = -1;
		return MRES_Supercede;
	}

	if( aResult == Plugin_Changed )
	{
		if( IsValidEntity(a1) )
		{
			hReturn.Value = a1;
			return MRES_ChangedOverride;
		}
	}

	return MRES_Ignored;
}

MRESReturn DTR_BossZombiePlayerBot_ChooseVictim_Pre(int client, DHookReturn hReturn)
{
	//PrintToServer("##### DTR_BossZombiePlayerBot_ChooseVictim_Pre");
	return MRES_Ignored;
}

MRESReturn DTR_BossZombiePlayerBot_ChooseVictim_Post(int client, DHookReturn hReturn) // Forward "L4D2_OnChooseVictim"
{
	//PrintToServer("##### DTR_BossZombiePlayerBot_ChooseVictim_Post");
	int a1 = hReturn.Value;
	if( a1 == -1 ) a1 = 0;

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_BossZombiePlayerBot_ChooseVictim_Post);
	Call_PushCell(client);
	Call_PushCellRef(a1);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		hReturn.Value = client;
		return MRES_Supercede;
	}

	if( aResult == Plugin_Changed )
	{
		hReturn.Value = a1;
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

bool g_bBlock_CTerrorPlayer_MaterializeFromGhost;
MRESReturn DTR_CTerrorPlayer_MaterializeFromGhost_Pre(int client) // Forward "L4D_OnMaterializeFromGhostPre"
{
	//PrintToServer("##### DTR_CTerrorPlayer_MaterializeFromGhost_Pre");

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorPlayer_MaterializeFromGhost_Pre);
	Call_PushCell(client);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_CTerrorPlayer_MaterializeFromGhost = true;

		return MRES_Supercede;
	}

	g_bBlock_CTerrorPlayer_MaterializeFromGhost = false;

	return MRES_Ignored;
}

MRESReturn DTR_CTerrorPlayer_MaterializeFromGhost_Post(int client) // Forward "L4D_OnMaterializeFromGhost" and "L4D_OnMaterializeFromGhost_PostHandled"
{
	//PrintToServer("##### DTR_CTerrorPlayer_MaterializeFromGhost_Post");

	Call_StartForward(g_bBlock_CTerrorPlayer_MaterializeFromGhost ? g_hFWD_CTerrorPlayer_MaterializeFromGhost_PostHandled : g_hFWD_CTerrorPlayer_MaterializeFromGhost_Post);
	Call_PushCell(client);
	Call_Finish();

	return MRES_Ignored;
}

bool g_bBlock_CPipeBombProjectile_Create;
MRESReturn DTR_CPipeBombProjectile_Create_Pre(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_PipeBombProjectile_Pre"
{
	//PrintToServer("##### DTR_CPipeBombProjectile_Create_Pre");

	int client;
	if( !hParams.IsNull(5) )
		client = hParams.Get(5);

	float v1[3];
	float v2[3];
	float v3[3];
	float v4[3];

	hParams.GetVector(1, v1); // vPos
	hParams.GetVector(2, v2); // vAng
	hParams.GetVector(3, v3); // vVel
	hParams.GetVector(4, v4); // vRot

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CPipeBombProjectile_Create_Pre);
	Call_PushCell(client);
	Call_PushArrayEx(v1, sizeof(v1), SM_PARAM_COPYBACK);
	Call_PushArrayEx(v2, sizeof(v2), SM_PARAM_COPYBACK);
	Call_PushArrayEx(v3, sizeof(v3), SM_PARAM_COPYBACK);
	Call_PushArrayEx(v4, sizeof(v4), SM_PARAM_COPYBACK);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_CPipeBombProjectile_Create = true;

		hReturn.Value = -1;
		return MRES_Supercede;
	}

	g_bBlock_CPipeBombProjectile_Create = false;

	if( aResult == Plugin_Changed )
	{
		hParams.SetVector(1, v1);
		hParams.SetVector(2, v2);
		hParams.SetVector(3, v3);
		hParams.SetVector(4, v4);
		return MRES_ChangedHandled;
	}

	return MRES_Ignored;
}

MRESReturn DTR_CPipeBombProjectile_Create_Post(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_PipeBombProjectile_Post" and "L4D_PipeBombProjectile_PostHandled"
{
	//PrintToServer("##### DTR_CPipeBombProjectile_Create_Post");

	int client;
	if( !hParams.IsNull(5) )
		client = hParams.Get(5);

	int entity = hReturn.Value;

	float v1[3];
	float v2[3];
	float v3[3];
	float v4[3];

	hParams.GetVector(1, v1); // vPos
	hParams.GetVector(2, v2); // vAng
	hParams.GetVector(3, v3); // vVel
	hParams.GetVector(4, v4); // vRot

	Call_StartForward(g_bBlock_CPipeBombProjectile_Create ? g_hFWD_CPipeBombProjectile_Create_PostHandled : g_hFWD_CPipeBombProjectile_Create_Post);
	Call_PushCell(client);
	Call_PushCell(entity);
	Call_PushArray(v1, sizeof(v1));
	Call_PushArray(v2, sizeof(v2));
	Call_PushArray(v3, sizeof(v3));
	Call_PushArray(v4, sizeof(v4));
	Call_Finish();

	return MRES_Ignored;
}

bool g_bBlock_CMolotovProjectile_Detonate;
MRESReturn DTR_CMolotovProjectile_Detonate_Pre(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D_Molotov_Detonate"
{
	//PrintToServer("##### DTR_CMolotovProjectile_Detonate_Pre");

	int client = GetEntPropEnt(pThis, Prop_Send, "m_hOwnerEntity");

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CMolotovProjectile_Detonate);
	Call_PushCell(pThis);
	Call_PushCell(client);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_CMolotovProjectile_Detonate = true;

		hReturn.Value = 0;
		return MRES_Supercede;
	}

	g_bBlock_CMolotovProjectile_Detonate = false;

	return MRES_Ignored;
}

MRESReturn DTR_CMolotovProjectile_Detonate(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D_Molotov_Detonate"
{
	//PrintToServer("##### DTR_CMolotovProjectile_Detonate");

	int client = GetEntPropEnt(pThis, Prop_Send, "m_hOwnerEntity");

	Call_StartForward(g_bBlock_CMolotovProjectile_Detonate ? g_hFWD_CMolotovProjectile_Detonate_PostHandled : g_hFWD_CMolotovProjectile_Detonate_Post);
	Call_PushCell(pThis);
	Call_PushCell(client);
	Call_Finish();

	return MRES_Ignored;
}

bool g_bBlock_CPipeBombProjectile_Detonate;
MRESReturn DTR_CPipeBombProjectile_Detonate_Pre(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D_PipeBomb_Detonate"
{
	//PrintToServer("##### DTR_CPipeBombProjectile_Detonate_Pre");

	int client = GetEntPropEnt(pThis, Prop_Send, "m_hOwnerEntity");

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CPipeBombProjectile_Detonate);
	Call_PushCell(pThis);
	Call_PushCell(client);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_CPipeBombProjectile_Detonate = true;

		hReturn.Value = 0;
		return MRES_Supercede;
	}

	g_bBlock_CPipeBombProjectile_Detonate = false;

	return MRES_Ignored;
}

MRESReturn DTR_CPipeBombProjectile_Detonate(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D_PipeBomb_Detonate"
{
	//PrintToServer("##### DTR_CPipeBombProjectile_Detonate");

	int client = GetEntPropEnt(pThis, Prop_Send, "m_hOwnerEntity");

	Call_StartForward(g_bBlock_CPipeBombProjectile_Detonate ? g_hFWD_CPipeBombProjectile_Detonate_PostHandled : g_hFWD_CPipeBombProjectile_Detonate_Post);
	Call_PushCell(pThis);
	Call_PushCell(client);
	Call_Finish();

	return MRES_Ignored;
}

bool g_bBlock_CVomitJarProjectile_Detonate;
MRESReturn DTR_CVomitJarProjectile_Detonate_Pre(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D2_VomitJar_Detonate"
{
	//PrintToServer("##### DTR_CVomitJarProjectile_Detonate_Pre");

	int client = GetEntPropEnt(pThis, Prop_Send, "m_hOwnerEntity");

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CVomitJarProjectile_Detonate);
	Call_PushCell(pThis);
	Call_PushCell(client);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_CVomitJarProjectile_Detonate = true;

		hReturn.Value = -1;
		return MRES_Supercede;
	}

	g_bBlock_CVomitJarProjectile_Detonate = false;

	return MRES_Ignored;
}

MRESReturn DTR_CVomitJarProjectile_Detonate(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D2_VomitJar_Detonate"
{
	//PrintToServer("##### DTR_CVomitJarProjectile_Detonate");

	int client = GetEntPropEnt(pThis, Prop_Send, "m_hOwnerEntity");

	Call_StartForward(g_bBlock_CVomitJarProjectile_Detonate ? g_hFWD_CVomitJarProjectile_Detonate_PostHandled : g_hFWD_CVomitJarProjectile_Detonate_Post);
	Call_PushCell(pThis);
	Call_PushCell(client);
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn DTR_CBreakableProp_Break_Pre(int pThis, DHookReturn hReturn, DHookParam hParams)
{
	//PrintToServer("##### DTR_CBreakableProp_Break_Pre");
	return MRES_Ignored;
}

MRESReturn DTR_CBreakableProp_Break_Post(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D_CBreakableProp_Break"
{
	//PrintToServer("##### DTR_CBreakableProp_Break_Post");

	int entity;
	if( !hParams.IsNull(1) )
		entity = hParams.Get(1);

	Call_StartForward(g_hFWD_CBreakableProp_Break_Post);
	Call_PushCell(pThis);
	Call_PushCell(entity);
	Call_Finish();

	return MRES_Ignored;
}

bool g_bBlock_CGasCanEvent_Killed;
MRESReturn DTR_CGasCanEvent_Killed(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D2_CGasCan_EventKilled"
{
	//PrintToServer("##### DTR_CGasCanEvent_Killed");

	int a1 = hParams.GetObjectVar(1, 48, ObjectValueType_EhandlePtr);
	int a2 = hParams.GetObjectVar(1, 52, ObjectValueType_EhandlePtr);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CGasCanEvent_Killed);
	Call_PushCell(pThis);
	Call_PushCellRef(a1);
	Call_PushCellRef(a2);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_CGasCanEvent_Killed = true;

		hReturn.Value = 0;
		return MRES_Supercede;
	}

	if( aResult == Plugin_Changed )
	{
		hParams.SetObjectVar(1, 48, ObjectValueType_EhandlePtr, a1);
		hParams.SetObjectVar(1, 52, ObjectValueType_EhandlePtr, a2);
		return MRES_ChangedHandled;
	}

	g_bBlock_CGasCanEvent_Killed = false;

	return MRES_Ignored;
}

MRESReturn DTR_CGasCanEvent_Killed_Post(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D2_CGasCan_EventKilled_Post" and "L4D2_CGasCan_EventKilled_PostHandled"
{
	//PrintToServer("##### DTR_CGasCanEvent_Killed");

	int a1 = hParams.GetObjectVar(1, 48, ObjectValueType_EhandlePtr);
	int a2 = hParams.GetObjectVar(1, 52, ObjectValueType_EhandlePtr);

	Call_StartForward(g_bBlock_CGasCanEvent_Killed ? g_hFWD_CGasCanEvent_Killed_PostHandled : g_hFWD_CGasCanEvent_Killed_Post);
	Call_PushCell(pThis);
	Call_PushCell(a1);
	Call_PushCell(a2);
	Call_Finish();

	return MRES_Ignored;
}

bool g_bBlock_CGasCan_ShouldStartAction;
MRESReturn DTR_CGasCan_ShouldStartAction(DHookReturn hReturn, DHookParam hParams) // Forward "L4D2_CGasCan_ShouldStartAction"
{
	//PrintToServer("##### DTR_CGasCan_ShouldStartAction");

	int client;
	if( !hParams.IsNull(2) )
		client = hParams.Get(2);

	int nozzle = hParams.Get(3);

	int entity;
	if( client )
	{
		entity = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	}

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CGasCan_ShouldStartAction);
	Call_PushCell(client);
	Call_PushCell(entity);
	Call_PushCell(nozzle);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_CGasCan_ShouldStartAction = true;

		hReturn.Value = 0;
		return MRES_Supercede;
	}

	g_bBlock_CGasCan_ShouldStartAction = false;

	return MRES_Ignored;
}

MRESReturn DTR_CGasCan_ShouldStartAction_Post(DHookReturn hReturn, DHookParam hParams) // Forward "L4D2_CGasCan_ShouldStartAction_Post" and "L4D2_CGasCan_ShouldStartAction_PostHandled"
{
	//PrintToServer("##### DTR_CGasCan_ShouldStartAction_Post");

	int client;
	if( !hParams.IsNull(2) )
		client = hParams.Get(2);

	int nozzle = hParams.Get(3);

	int entity;
	if( client )
	{
		entity = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	}

	Call_StartForward(g_bBlock_CGasCan_ShouldStartAction ? g_hFWD_CGasCan_ShouldStartAction_PostHandled : g_hFWD_CGasCan_ShouldStartAction_Post);
	Call_PushCell(client);
	Call_PushCell(entity);
	Call_PushCell(nozzle);
	Call_Finish();

	return MRES_Ignored;
}

bool g_bBlock_CGasCan_OnActionComplete;
MRESReturn DTR_CGasCan_OnActionComplete(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D2_CGasCan_ActionComplete"
{
	//PrintToServer("##### DTR_CGasCan_OnActionComplete");

	int client;
	if( !hParams.IsNull(1) )
		client = hParams.Get(1);

	int nozzle = hParams.Get(2);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CGasCan_OnActionComplete);
	Call_PushCell(client);
	Call_PushCell(pThis);
	Call_PushCell(nozzle);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_CGasCan_OnActionComplete = true;

		hReturn.Value = 0;
		return MRES_Supercede;
	}

	g_bBlock_CGasCan_OnActionComplete = false;

	return MRES_Ignored;
}

MRESReturn DTR_CGasCan_OnActionComplete_Post(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D2_CGasCan_ActionComplete_Post" and "L4D2_CGasCan_ActionComplete_PostHandled"
{
	//PrintToServer("##### DTR_CGasCan_OnActionComplete_Post");

	int client;
	if( !hParams.IsNull(1) )
		client = hParams.Get(1);

	int nozzle = hParams.Get(2);

	Call_StartForward(g_bBlock_CGasCan_OnActionComplete ? g_hFWD_CGasCan_OnActionComplete_PostHandled : g_hFWD_CGasCan_OnActionComplete_Post);
	Call_PushCell(client);
	Call_PushCell(pThis);
	Call_PushCell(nozzle);
	Call_Finish();

	return MRES_Ignored;
}

int g_iCBaseBackpackItem_StartAction;
bool g_bBlock_CBaseBackpackItem_StartAction;
MRESReturn DTR_CBaseBackpackItem_StartAction(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D2_BackpackItem_StartAction"
{
	//PrintToServer("##### DTR_CBaseBackpackItem_StartAction");

	g_iCBaseBackpackItem_StartAction = -1;

	if( !IsValidEntity(pThis) ) return MRES_Ignored;

	int client = GetEntPropEnt(pThis, Prop_Send, "m_hOwner");

	if( client > 0 && IsClientInGame(client) )
	{
		static char sTemp[32];
		GetEdictClassname(pThis, sTemp, sizeof(sTemp));
		g_aWeaponIDs.GetValue(sTemp, g_iCBaseBackpackItem_StartAction);

		Action aResult = Plugin_Continue;
		Call_StartForward(g_hFWD_CBaseBackpackItem_StartAction);
		Call_PushCell(client);
		Call_PushCell(pThis);
		Call_PushCell(g_iCBaseBackpackItem_StartAction);
		Call_Finish(aResult);

		if( aResult == Plugin_Handled )
		{
			g_bBlock_CBaseBackpackItem_StartAction = true;

			hReturn.Value = 0;
			return MRES_Supercede;
		}
	}

	g_bBlock_CBaseBackpackItem_StartAction = false;

	return MRES_Ignored;
}

MRESReturn DTR_CBaseBackpackItem_StartAction_Post(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D2_BackpackItem_StartAction_Post" and "L4D2_BackpackItem_StartAction_PostHandled"
{
	//PrintToServer("##### DTR_CBaseBackpackItem_StartAction_Post");

	if( !IsValidEntity(pThis) ) return MRES_Ignored;

	int client = GetEntPropEnt(pThis, Prop_Send, "m_hOwner");

	if( client > 0 && IsClientInGame(client) )
	{
		Call_StartForward(g_bBlock_CBaseBackpackItem_StartAction ? g_hFWD_CBaseBackpackItem_StartAction_PostHandled : g_hFWD_CBaseBackpackItem_StartAction_Post);
		Call_PushCell(client);
		Call_PushCell(pThis);
		Call_PushCell(g_iCBaseBackpackItem_StartAction);
		Call_Finish();
	}

	return MRES_Ignored;
}

bool g_bBlock_CFirstAidKit_StartHealing;
MRESReturn DTR_CFirstAidKit_StartHealing_NIX(DHookParam hParams) // Forward "L4D1_FirstAidKit_StartHealing"
{
	//PrintToServer("##### DTR_CFirstAidKit_StartHealing_NIX");

	int pThis = hParams.Get(1);
	if( !IsValidEntity(pThis) ) return MRES_Ignored;

	int client = GetEntPropEnt(pThis, Prop_Send, "m_hOwner");

	if( client > 0 && IsClientInGame(client) )
	{
		Action aResult = Plugin_Continue;
		Call_StartForward(g_hFWD_CFirstAidKit_StartHealing);
		Call_PushCell(client);
		Call_PushCell(pThis);
		Call_Finish(aResult);

		if( aResult == Plugin_Handled )
		{
			g_bBlock_CFirstAidKit_StartHealing = true;

			return MRES_Supercede;
		}
	}

	g_bBlock_CFirstAidKit_StartHealing = false;

	return MRES_Ignored;
}

MRESReturn DTR_CFirstAidKit_StartHealing_Post_NIX(DHookParam hParams) // Forward "L4D1_FirstAidKit_StartHealing_Post" and "L4D1_FirstAidKit_StartHealing_PostHandled"
{
	//PrintToServer("##### DTR_CFirstAidKit_StartHealing_Post_NIX");

	int pThis = hParams.Get(1);
	if( !IsValidEntity(pThis) ) return MRES_Ignored;

	int client = GetEntPropEnt(pThis, Prop_Send, "m_hOwner");

	if( client > 0 && IsClientInGame(client) )
	{
		Call_StartForward(g_bBlock_CFirstAidKit_StartHealing ? g_hFWD_CFirstAidKit_StartHealing_PostHandled : g_hFWD_CFirstAidKit_StartHealing_Post);
		Call_PushCell(client);
		Call_PushCell(pThis);
		Call_Finish();
	}

	return MRES_Ignored;
}

MRESReturn DTR_CFirstAidKit_StartHealing_WIN(int pThis, DHookParam hParams) // Forward "L4D1_FirstAidKit_StartHealing"
{
	//PrintToServer("##### DTR_CFirstAidKit_StartHealing_WIN");

	if( !IsValidEntity(pThis) ) return MRES_Ignored;

	int client = GetEntPropEnt(pThis, Prop_Send, "m_hOwner");

	if( client > 0 && IsClientInGame(client) )
	{
		Action aResult = Plugin_Continue;
		Call_StartForward(g_hFWD_CFirstAidKit_StartHealing);
		Call_PushCell(client);
		Call_PushCell(pThis);
		Call_Finish(aResult);

		if( aResult == Plugin_Handled )
		{
			g_bBlock_CFirstAidKit_StartHealing = true;

			return MRES_Supercede;
		}
	}

	g_bBlock_CFirstAidKit_StartHealing = false;

	return MRES_Ignored;
}

MRESReturn DTR_CFirstAidKit_StartHealing_Post_WIN(int pThis, DHookParam hParams) // Forward "L4D1_FirstAidKit_StartHealing_Post" and "L4D1_FirstAidKit_StartHealing_PostHandled"
{
	//PrintToServer("##### DTR_CFirstAidKit_StartHealing_Post_WIN");

	if( !IsValidEntity(pThis) ) return MRES_Ignored;

	int client = GetEntPropEnt(pThis, Prop_Send, "m_hOwner");

	if( client > 0 && IsClientInGame(client) )
	{
		Call_StartForward(g_bBlock_CFirstAidKit_StartHealing ? g_hFWD_CFirstAidKit_StartHealing_PostHandled : g_hFWD_CFirstAidKit_StartHealing_Post);
		Call_PushCell(client);
		Call_PushCell(pThis);
		Call_Finish();
	}

	return MRES_Ignored;
}

MRESReturn DTR_CServerGameDLL_ServerHibernationUpdate(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnServerHibernationUpdate"
{
	//PrintToServer("##### DTR_CServerGameDLL_ServerHibernationUpdate");

	bool status = hParams.Get(1);

	Call_StartForward(g_hFWD_CServerGameDLL_ServerHibernationUpdate);
	Call_PushCell(status);
	Call_Finish();

	return MRES_Ignored;
}

bool g_bBlock_CTerrorPlayer_OnPouncedOnSurvivor;
MRESReturn DTR_CTerrorPlayer_OnPouncedOnSurvivor(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnPouncedOnSurvivor"
{
	//PrintToServer("##### DTR_CTerrorPlayer_OnPouncedOnSurvivor");

	int target;
	if( !hParams.IsNull(1) )
		target = hParams.Get(1);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorPlayer_OnPouncedOnSurvivor);
	Call_PushCell(target);
	Call_PushCell(pThis);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_CTerrorPlayer_OnPouncedOnSurvivor = true;

		hReturn.Value = 0;
		return MRES_Supercede;
	}

	g_bBlock_CTerrorPlayer_OnPouncedOnSurvivor = false;

	return MRES_Ignored;
}

MRESReturn DTR_CTerrorPlayer_OnPouncedOnSurvivor_Post(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnPouncedOnSurvivor_Post" and "L4D_OnPouncedOnSurvivor_PostHandled"
{
	//PrintToServer("##### DTR_CTerrorPlayer_OnPouncedOnSurvivor_Post");

	int target;
	if( !hParams.IsNull(1) )
		target = hParams.Get(1);

	Call_StartForward(g_bBlock_CTerrorPlayer_OnPouncedOnSurvivor ? g_hFWD_CTerrorPlayer_OnPouncedOnSurvivor_PostHandled : g_hFWD_CTerrorPlayer_OnPouncedOnSurvivor_Post);
	Call_PushCell(target);
	Call_PushCell(pThis);
	Call_Finish();

	return MRES_Ignored;
}

bool g_bBlock_CTerrorPlayer_GrabVictimWithTongue;
MRESReturn DTR_CTerrorPlayer_GrabVictimWithTongue(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnGrabWithTongue"
{
	//PrintToServer("##### DTR_CTerrorPlayer_GrabVictimWithTongue");

	int target;
	if( !hParams.IsNull(1) )
		target = hParams.Get(1);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorPlayer_GrabVictimWithTongue);
	Call_PushCell(target);
	Call_PushCell(pThis);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_CTerrorPlayer_GrabVictimWithTongue = true;

		hReturn.Value = 0;
		return MRES_Supercede;
	}

	g_bBlock_CTerrorPlayer_GrabVictimWithTongue = false;

	return MRES_Ignored;
}

MRESReturn DTR_CTerrorPlayer_GrabVictimWithTongue_Post(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnGrabWithTongue_Post" and "L4D_OnGrabWithTongue_PostHandled"
{
	//PrintToServer("##### DTR_CTerrorPlayer_GrabVictimWithTongue_Post");

	int target;
	if( !hParams.IsNull(1) )
		target = hParams.Get(1);

	Call_StartForward(g_bBlock_CTerrorPlayer_GrabVictimWithTongue ? g_hFWD_CTerrorPlayer_GrabVictimWithTongue_PostHandled : g_hFWD_CTerrorPlayer_GrabVictimWithTongue_Post);
	Call_PushCell(target);
	Call_PushCell(pThis);
	Call_Finish();

	return MRES_Ignored;
}

bool g_bBlock_CTerrorPlayer_OnLeptOnSurvivor;
MRESReturn DTR_CTerrorPlayer_OnLeptOnSurvivor(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D2_OnJockeyRide"
{
	//PrintToServer("##### DTR_CTerrorPlayer_OnLeptOnSurvivor");

	int target;
	if( !hParams.IsNull(1) )
		target = hParams.Get(1);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorPlayer_OnLeptOnSurvivor);
	Call_PushCell(target);
	Call_PushCell(pThis);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_CTerrorPlayer_OnLeptOnSurvivor = true;

		hReturn.Value = 0;
		return MRES_Supercede;
	}

	g_bBlock_CTerrorPlayer_OnLeptOnSurvivor = false;

	return MRES_Ignored;
}

MRESReturn DTR_CTerrorPlayer_OnLeptOnSurvivor_Post(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D2_OnJockeyRide_Post" and "L4D2_OnJockeyRide_PostHandled"
{
	//PrintToServer("##### DTR_CTerrorPlayer_OnLeptOnSurvivor_Post");

	int target;
	if( !hParams.IsNull(1) )
		target = hParams.Get(1);

	Call_StartForward(g_bBlock_CTerrorPlayer_OnLeptOnSurvivor ? g_hFWD_CTerrorPlayer_OnLeptOnSurvivor_PostHandled : g_hFWD_CTerrorPlayer_OnLeptOnSurvivor_Post);
	Call_PushCell(target);
	Call_PushCell(pThis);
	Call_Finish();

	return MRES_Ignored;
}

bool g_bBlock_CTerrorPlayer_OnStartCarryingVictim;
MRESReturn DTR_CTerrorPlayer_OnStartCarryingVictim(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D2_OnStartCarryingVictim"
{
	//PrintToServer("##### DTR_CTerrorPlayer_OnStartCarryingVictim");

	int target;
	if( !hParams.IsNull(1) )
		target = hParams.Get(1);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorPlayer_OnStartCarryingVictim);
	Call_PushCell(target);
	Call_PushCell(pThis);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_CTerrorPlayer_OnStartCarryingVictim = true;

		hReturn.Value = 0;
		return MRES_Supercede;
	}

	g_bBlock_CTerrorPlayer_OnStartCarryingVictim = false;

	return MRES_Ignored;
}

MRESReturn DTR_CTerrorPlayer_OnStartCarryingVictim_Post(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D2_OnStartCarryingVictim_Post" and "L4D2_OnStartCarryingVictim_PostHandled"
{
	//PrintToServer("##### DTR_CTerrorPlayer_OnStartCarryingVictim_Post");

	int target;
	if( !hParams.IsNull(1) )
		target = hParams.Get(1);

	Call_StartForward(g_bBlock_CTerrorPlayer_OnStartCarryingVictim ? g_hFWD_CTerrorPlayer_OnStartCarryingVictim_PostHandled : g_hFWD_CTerrorPlayer_OnStartCarryingVictim_Post);
	Call_PushCell(target);
	Call_PushCell(pThis);
	Call_Finish();

	return MRES_Ignored;
}

MRESReturn DTR_CCharge_ImpactStagger(int pThis, DHookReturn hReturn) // Forward "L4D2_OnChargerImpact"
{
	//PrintToServer("##### DTR_CCharge_ImpactStagger");

	int client = GetEntPropEnt(pThis, Prop_Send, "m_owner");
	if( client > 0 )
	{
		Call_StartForward(g_hFWD_CCharge_ImpactStagger);
		Call_PushCell(client);
		Call_Finish();
	}

	return MRES_Ignored;
}

bool g_bBlock_CInsectSwarm_CanHarm;
MRESReturn DTR_CInsectSwarm_CanHarm(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D2_CInsectSwarm_CanHarm"
{
	//PrintToServer("##### DTR_CInsectSwarm_CanHarm");

	int spitter = GetEntPropEnt(pThis, Prop_Data, "m_hOwnerEntity");

	int entity;
	if( !hParams.IsNull(1) )
		entity = hParams.Get(1);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CInsectSwarm_CanHarm);
	Call_PushCell(pThis);
	Call_PushCell(spitter);
	Call_PushCell(entity);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_CInsectSwarm_CanHarm = true;

		hReturn.Value = 0;
		return MRES_Supercede;
	}

	g_bBlock_CInsectSwarm_CanHarm = false;

	return MRES_Ignored;
}

MRESReturn DTR_CInsectSwarm_CanHarm_Post(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D2_CInsectSwarm_CanHarm_Post" and "L4D2_CInsectSwarm_CanHarm_PostHandled"
{
	//PrintToServer("##### DTR_CInsectSwarm_CanHarm_Post");

	int spitter = GetEntPropEnt(pThis, Prop_Data, "m_hOwnerEntity");

	int entity;
	if( !hParams.IsNull(1) )
		entity = hParams.Get(1);

	Call_StartForward(g_bBlock_CInsectSwarm_CanHarm ? g_hFWD_CInsectSwarm_CanHarm_PostHandled : g_hFWD_CInsectSwarm_CanHarm_Post);
	Call_PushCell(pThis);
	Call_PushCell(spitter);
	Call_PushCell(entity);
	Call_Finish();

	return MRES_Ignored;
}

bool g_bBlock_CTerrorPlayer_OnVomitedUpon;
MRESReturn DTR_CTerrorPlayer_OnVomitedUpon(int client, DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnVomitedUpon"
{
	//PrintToServer("##### DTR_CTerrorPlayer_OnVomitedUpon");

	int a1;

	if( !hParams.IsNull(1) )
		a1 = hParams.Get(1);

	int a2 = hParams.Get(2);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorPlayer_OnVomitedUpon);
	Call_PushCell(client);
	Call_PushCellRef(a1);
	Call_PushCellRef(a2);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_CTerrorPlayer_OnVomitedUpon = true;

		hReturn.Value = 0;
		return MRES_Supercede;
	}

	g_bBlock_CTerrorPlayer_OnVomitedUpon = false;

	if( aResult == Plugin_Changed )
	{
		hParams.Set(1, a1);
		hParams.Set(2, a2);
		return MRES_ChangedHandled;
	}

	return MRES_Ignored;
}

MRESReturn DTR_CTerrorPlayer_OnVomitedUpon_Post(int client, DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnVomitedUpon_Post" and "L4D_OnVomitedUpon_PostHandled"
{
	//PrintToServer("##### DTR_CTerrorPlayer_OnVomitedUpon_Post");

	int a1;

	if( !hParams.IsNull(1) )
		a1 = hParams.Get(1);

	int a2 = hParams.Get(2);

	Call_StartForward(g_bBlock_CTerrorPlayer_OnVomitedUpon ? g_hFWD_CTerrorPlayer_OnVomitedUpon_PostHandled : g_hFWD_CTerrorPlayer_OnVomitedUpon_Post);
	Call_PushCell(client);
	Call_PushCell(a1);
	Call_PushCell(a2);
	Call_Finish();

	return MRES_Ignored;
}

bool g_bBlock_CTerrorPlayer_OnHitByVomitJar;
MRESReturn DTR_CTerrorPlayer_OnHitByVomitJar(int client, DHookReturn hReturn, DHookParam hParams) // Forward "L4D2_OnHitByVomitJar"
{
	//PrintToServer("##### DTR_CTerrorPlayer_OnHitByVomitJar");

	int a1;

	if( !hParams.IsNull(1) )
		a1 = hParams.Get(1);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorPlayer_OnHitByVomitJar);
	Call_PushCell(client);
	Call_PushCellRef(a1);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		g_bBlock_CTerrorPlayer_OnHitByVomitJar = true;

		hReturn.Value = 0;
		return MRES_Supercede;
	}

	g_bBlock_CTerrorPlayer_OnHitByVomitJar = false;

	if( aResult == Plugin_Changed )
	{
		hParams.Set(1, a1);
		return MRES_ChangedHandled;
	}

	return MRES_Ignored;
}

MRESReturn DTR_CTerrorPlayer_OnHitByVomitJar_Post(int client, DHookReturn hReturn, DHookParam hParams) // Forward "L4D2_OnHitByVomitJar_Post" and "L4D2_OnHitByVomitJar_PostHandled"
{
	//PrintToServer("##### DTR_CTerrorPlayer_OnHitByVomitJar_Post");

	int a1;

	if( !hParams.IsNull(1) )
		a1 = hParams.Get(1);

	Call_StartForward(g_bBlock_CTerrorPlayer_OnHitByVomitJar ? g_hFWD_CTerrorPlayer_OnHitByVomitJar_PostHandled : g_hFWD_CTerrorPlayer_OnHitByVomitJar_Post);
	Call_PushCell(client);
	Call_PushCell(a1);
	Call_Finish();

	return MRES_Ignored;
}



/*
// Removed because it spawns specials at 0,0,0 when modifying any value.
MRESReturn DTR_ZombieManager_GetRandomPZSpawnPosition(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnGetRandomPZSpawnPosition"
{
	//PrintToServer("##### DTR_ZombieManager_GetRandomPZSpawnPosition");
	int zombieClass = hParams.Get(1);
	int attempts = hParams.Get(2);

	int client;
	if( !hParams.IsNull(3) )
		client = hParams.Get(3);

	// New method works - Thanks to "Forgetest":
	float vecPos[3];
	Address ptr = hParams.Get(4);
	PrintToChatAll("ptrPRE %d", ptr);
	vecPos[0] = view_as<float>(LoadFromAddress(ptr, NumberType_Int32));
	vecPos[1] = view_as<float>(LoadFromAddress(ptr + view_as<Address>(4), NumberType_Int32));
	vecPos[2] = view_as<float>(LoadFromAddress(ptr + view_as<Address>(8), NumberType_Int32));

	// Old method:
	float vecPos[3];
	hParams.GetVector(4, vecPos);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_GetRandomPZSpawnPos);
	Call_PushCellRef(client);
	Call_PushCellRef(zombieClass);
	Call_PushCellRef(attempts);
	Call_PushArrayEx(vecPos, 3, SM_PARAM_COPYBACK);
	Call_Finish(aResult);

	if( aResult == Plugin_Changed )
	{
		hParams.Set(1, zombieClass);
		hParams.Set(2, attempts);
		if( !hParams.IsNull(3) )
			hParams.Set(3, client);

		// New method:
		StoreToAddress(ptr, view_as<int>(vecPos[0]), NumberType_Int32);
		StoreToAddress(ptr + view_as<Address>(4), view_as<int>(vecPos[1]), NumberType_Int32);
		StoreToAddress(ptr + view_as<Address>(8), view_as<int>(vecPos[2]), NumberType_Int32);

		// Old method:
		// Nothing worked to fix the bug, even though this is a pre-hook it's using the modified value.
		if( vecPos[0] != 0.0 )
		{
			hParams.SetVector(4, vecPos);
		}

		return MRES_ChangedHandled;
	}

	return MRES_Ignored;
}
// */

/*
MRESReturn DTR_InfectedShoved_OnShoved(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnInfectedShoved"
{
	int a1 = hParams.Get(1);
	int a2 = hParams.Get(2);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_InfectedShoved);
	Call_PushCell(a1);
	Call_PushCell(a2);
	Call_Finish(aResult);
	if( aResult == Plugin_Handled ) return MRES_Supercede;

	return MRES_Ignored;
}
// */

/*
MRESReturn DTR_CBasePlayer_WaterMove_Pre(int pThis, DHookReturn hReturn, DHookParam hParams)
{
}

MRESReturn DTR_CBasePlayer_WaterMove_Post(int pThis, DHookReturn hReturn, DHookParam hParams) // Forward "L4D2_OnWaterMove"
{
	int a1 = hReturn.Value;
	if( a1 )
	{
		Call_StartForward(g_hFWD_OnWaterMove);
		Call_PushCell(pThis);
		Call_Finish();
	}

	return MRES_Ignored;
}
// */




// ====================================================================================================
// VSCRIPT DIRECTOR - GetScriptValue*
// ====================================================================================================
MRESReturn DTR_CDirector_GetScriptValueInt_Pre(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnGetScriptValueInt"
{
	return MRES_Ignored;
}

MRESReturn DTR_CDirector_GetScriptValueInt(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnGetScriptValueInt"
{
	//PrintToServer("##### DTR_CDirector_GetScriptValueInt");
	static char key[64];
	hParams.GetString(1, key, sizeof(key));
	int a2 = hReturn.Value;

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CDirector_GetScriptValueInt);
	Call_PushString(key);
	Call_PushCellRef(a2);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		hReturn.Value = a2;
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

MRESReturn DTR_CDirector_GetScriptValueFloat_Pre(DHookReturn hReturn, DHookParam hParams)
{
	return MRES_Ignored;
}

MRESReturn DTR_CDirector_GetScriptValueFloat(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnGetScriptValueFloat"
{
	//PrintToServer("##### DTR_CDirector_GetScriptValueFloat");
	static char key[64];
	hParams.GetString(1, key, sizeof(key));
	float a2 = hReturn.Value;

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CDirector_GetScriptValueFloat);
	Call_PushString(key);
	Call_PushFloatRef(a2);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		hReturn.Value = a2;
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

/*
MRESReturn DTR_CDirector_GetScriptValueVector_Pre(DHookReturn hReturn, DHookParam hParams)
{
	return MRES_Ignored;
}

MRESReturn DTR_CDirector_GetScriptValueVector(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnGetScriptValueVector"
{
	//PrintToServer("##### DTR_CDirector_GetScriptValueVector");
	static char key[64];
	hParams.GetString(2, key, sizeof(key));

	float vVec[3];
	hReturn.GetVector(vVec);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CDirector_GetScriptValueVector);
	Call_PushString(key);
	Call_PushArrayEx(vVec, sizeof(vVec), SM_PARAM_COPYBACK);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		hParams.Set(3, vVec[0]);
		hParams.Set(4, vVec[1]);
		hParams.Set(5, vVec[2]);
		hReturn.SetVector(vVec);
		hParams.SetVector(1, vVec);
		return MRES_Supercede;
	}

	return MRES_Ignored;
}
*/

MRESReturn DTR_CDirector_GetScriptValueString_Pre(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnGetScriptValueString"
{
	return MRES_Ignored;
}

MRESReturn DTR_CDirector_GetScriptValueString(DHookReturn hReturn, DHookParam hParams) // Forward "L4D_OnGetScriptValueString"
{
	//PrintToServer("##### DTR_CDirector_GetScriptValueString");
	static char a1[128], a2[128], a3[128]; // Don't know how long they should be

	hParams.GetString(1, a1, sizeof(a1));

	if( !hParams.IsNull(2) )
		hParams.GetString(2, a2, sizeof(a2));

	if( !hParams.IsNull(3) )
		hParams.GetString(3, a3, sizeof(a3));

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CDirector_GetScriptValueString);
	Call_PushString(a1);
	Call_PushString(a2);
	Call_PushStringEx(a3, sizeof(a3), SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_Finish(aResult);

	// UNKNOWN
	if( aResult == Plugin_Handled )
	{
		hReturn.SetString(a3);
		return MRES_Supercede;
	}

	return MRES_Ignored;
}



// ====================================================================================================
// VSCRIPT DIRECTOR - CSquirrelVM_GetValue - Thanks to "Forgetest" for writing:
// ====================================================================================================
methodmap ScriptVariant
{
	public ScriptVariant(Address ptr)
	{
		return view_as<ScriptVariant>(ptr);
	}

	public bool AssignToInt( int& dest )
	{
		switch ( this.m_type )
		{
			case FIELD_VOID: { dest = 0; return false; }
			case FIELD_INTEGER, FIELD_UNSIGNED: { dest = this.m_int; return true; }
			case FIELD_FLOAT: { dest = RoundToFloor(this.m_float); return true; }
			case FIELD_BOOLEAN, FIELD_CHARACTER: { dest = this.m_bool; return true; }
			case FIELD_CSTRING: { char buffer[20]; this.GetString(buffer, sizeof(buffer)); dest = StringToInt(buffer); return true; }
		}

		return false;
	}

	public bool AssignToFloat( float& dest )
	{
		switch ( this.m_type )
		{
			case FIELD_VOID: { dest = 0.0; return false; }
			case FIELD_INTEGER, FIELD_UNSIGNED: { dest = float(this.m_int); return true; }
			case FIELD_FLOAT: { dest = this.m_float; return true; }
			case FIELD_BOOLEAN: { dest = float(this.m_bool); return true; }
			case FIELD_CSTRING: { char buffer[20]; this.GetString(buffer, sizeof(buffer)); dest = StringToFloat(buffer); return true; }
		}

		return false;
	}

	public bool AssignToVector( float dest[3] )
	{
		switch ( this.m_type )
		{
			case FIELD_VOID: { dest = NULL_VECTOR; return false; }
			case FIELD_VECTOR, FIELD_QANGLE: { this.GetVector(dest); return true; }
			case FIELD_CSTRING: { char buffer[64]; this.GetString(buffer, sizeof(buffer)); StringToVector(buffer, " ", dest); return true; }
		}

		return false;
	}

	public bool AssignToString( char[] dest, int maxlen )
	{
		switch ( this.m_type )
		{
			case FIELD_VOID: { dest[0] = '\0'; return false; }
			case FIELD_INTEGER, FIELD_UNSIGNED: { IntToString(this.m_int, dest, maxlen); return true; }
			case FIELD_FLOAT: { FormatEx(dest, maxlen, "%f", this.m_float); return true; }
			case FIELD_VECTOR, FIELD_QANGLE: { float vec[3]; this.GetVector(vec); FormatEx(dest, maxlen, "%f %f %f", vec[0], vec[1], vec[2]); return true; }
			case FIELD_CSTRING, FIELD_CHARACTER: { this.GetString(dest, maxlen); return true; }
		}

		return false;
	}

	property fieldtype_t m_type
	{
		public get() { return LoadFromAddress(this.m_pType, NumberType_Int16); }
		public set(fieldtype_t type) { StoreToAddress(this.m_pType, type, NumberType_Int16); }
	}

	property int m_int
	{
		public get() { return LoadFromAddress(this.m_pValue, NumberType_Int32); }
	}

	property float m_float
	{
		public get() { return LoadFromAddress(this.m_pValue, NumberType_Int32); }
	}

	public void GetString(char[] str, int maxlen)
	{
		ReadMemoryString(this.m_pValue, str, maxlen);
	}

	public void GetVector(float vec[3])
	{
		Address ptr = LoadFromAddress(this.m_pValue, NumberType_Int32);
		vec[0] = LoadFromAddress(ptr, NumberType_Int32);
		vec[1] = LoadFromAddress(ptr + view_as<Address>(4), NumberType_Int32);
		vec[2] = LoadFromAddress(ptr + view_as<Address>(8), NumberType_Int32);
	}

	property char m_char
	{
		public get() { return LoadFromAddress(this.m_pValue, NumberType_Int8); }
	}

	property bool m_bool
	{
		public get() { return LoadFromAddress(this.m_pValue, NumberType_Int8); }
	}

	property Address m_pValue
	{
		public get() { return view_as<Address>(this); }
	}

	property Address m_pType
	{
		public get() { return view_as<Address>(this) + view_as<Address>(8); }
	}
}

Action DispatchScriptGetValueForwards(const char[] key, fieldtype_t &type, ScriptVariant pVar, VariantBuffer varBuf, int m_iszScriptId)
{
	Action aResult = Plugin_Continue;

	switch ( type )
	{
		case FIELD_VOID:
		{
			Call_StartForward(g_hFWD_CSquirrelVM_GetValue_Void);
			Call_PushString(key);
			Call_PushCellRef(type);
			Call_PushArrayEx(varBuf, sizeof(varBuf), SM_PARAM_COPYBACK);
			Call_PushCell(m_iszScriptId);
			Call_Finish(aResult);
		}
		case FIELD_INTEGER, FIELD_UNSIGNED, FIELD_BOOLEAN:
		{
			if( pVar.AssignToInt(varBuf.m_int) )
			{
				//PrintToServer("%s : %d (type %i)", key, varBuf.m_int, type);
				Call_StartForward(g_hFWD_CSquirrelVM_GetValue_Int);
				Call_PushString(key);
				Call_PushCellRef(varBuf.m_int);
				Call_PushCell(m_iszScriptId);
				Call_Finish(aResult);
			}
		}
		case FIELD_FLOAT:
		{
			if( pVar.AssignToFloat(varBuf.m_float) )
			{
				//PrintToServer("%s : %f (type %i)", key, varBuf.m_float, type);
				Call_StartForward(g_hFWD_CSquirrelVM_GetValue_Float);
				Call_PushString(key);
				Call_PushFloatRef(varBuf.m_float);
				Call_PushCell(m_iszScriptId);
				Call_Finish(aResult);
			}
		}
		case FIELD_VECTOR, FIELD_QANGLE:
		{
			if( pVar.AssignToVector(varBuf.m_vector) )
			{
				//PrintToServer("%s : [%f %f %f] (type %i)", key, varBuf.m_vector[0], varBuf.m_vector[1], varBuf.m_vector[2], type);
				Call_StartForward(g_hFWD_CSquirrelVM_GetValue_Vector);
				Call_PushString(key);
				Call_PushArrayEx(varBuf.m_vector, sizeof(varBuf.m_vector), SM_PARAM_COPYBACK);
				Call_PushCell(m_iszScriptId);
				Call_Finish(aResult);
			}
		}
		/*case FIELD_CHARACTER, FIELD_CSTRING:
		{
			if( pVar.AssignToString(varBuf.m_string) )
			{
				//PrintToServer("%s : %s (type %i)", key, varBuf.m_string, type);
				Call_StartForward(g_hFWD_CDirector_GetScriptValueString);
				Call_PushString(key);
				Call_PushArrayEx(varBuf.m_string, sizeof(varBuf.m_string), SM_PARAM_COPYBACK);
				Call_Finish(aResult);
			}
		}*/
	}

	return aResult;
}

MRESReturn DTR_CSquirrelVM_GetValue(DHookReturn hReturn, DHookParam hParams) // Forward "L4D2_OnGetScriptValueInt", "L4D2_OnGetScriptValueFloat", "L4D2_OnGetScriptValueVector" and "L4D2_OnGetScriptValueVoid"
{
	//PrintToServer("##### DTR_CSquirrelVM_GetValue");

	// Get key
	static char key[64];
	hParams.GetString(2, key, sizeof(key));

	// Setup methodmap
	ScriptVariant pVar = ScriptVariant(hParams.GetAddress(3));
	fieldtype_t type = pVar.m_type;

	// Forwards
	static VariantBuffer varBuf;

	switch( type )
	{
		case FIELD_VOID:
		{
			varBuf.m_int = 0;
			varBuf.m_float = 0.0;
			varBuf.m_string[0] = '\x0';
			varBuf.m_vector = view_as<float>({0.0, 0.0, 0.0});
		}
		case FIELD_INTEGER, FIELD_UNSIGNED, FIELD_BOOLEAN:
		{
			varBuf.m_int = hParams.GetObjectVar(3, 0, ObjectValueType_Int);
		}
		case FIELD_FLOAT:
		{
			varBuf.m_float = hParams.GetObjectVar(3, 0, ObjectValueType_Float);
		}
		case FIELD_VECTOR, FIELD_QANGLE:
		{
			hParams.GetObjectVarVector(3, 0, ObjectValueType_VectorPtr, varBuf.m_vector);
		}
		/*case FIELD_CHARACTER, FIELD_CSTRING:
		{
			// TODO
		}*/
	}

	if( DispatchScriptGetValueForwards(key, type, pVar, varBuf, hParams.Get(1)) == Plugin_Handled )
	{
		switch( type )
		{
			case FIELD_INTEGER, FIELD_UNSIGNED, FIELD_BOOLEAN:
			{
				hParams.SetObjectVar(3, 0, ObjectValueType_Int, varBuf.m_int);
			}
			case FIELD_FLOAT:
			{
				hParams.SetObjectVar(3, 0, ObjectValueType_Float, varBuf.m_float);
			}
			case FIELD_VECTOR, FIELD_QANGLE:
			{
				if( pVar.m_type != FIELD_VECTOR && pVar.m_type != FIELD_QANGLE )
					return MRES_Ignored;

				hParams.SetObjectVarVector(3, 0, ObjectValueType_VectorPtr, varBuf.m_vector);
			}
			/*case FIELD_CHARACTER, FIELD_CSTRING:
			{
				// TODO
			}*/
		}

		pVar.m_type = type;

		hReturn.Value = 1;
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

bool StringToVector(const char[] str, const char[] spilt, float vec[3])
{
	char buffers[3][20];
	if( 3 > ExplodeString(str, spilt, buffers, sizeof(buffers[]), sizeof(buffers[][]), true) )
		return false;

	for( int i = 0; i < 3; ++i )
		vec[i] = StringToFloat(buffers[i]);

	return true;
}