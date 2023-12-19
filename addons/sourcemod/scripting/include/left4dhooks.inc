/**
 * vim  set ts=4
 * =============================================================================
 *
 * Left 4 Downtown 2 SourceMod Extension
 * Copyright (C) 2010 Michael "ProdigySim" Busby
 *
 * Left 4 Downtown SourceMod Extension
 * Copyright (C) 2009 Igor "Downtown1" Smirnov
 *
 * Left 4 Downtown 2 Extension updates
 * Copyright (C) 2012-2015 "Visor"
 *
 * Left 4 Downtown 2 Extension updates
 * Copyright (C) 2015 "Attano"
 *
 * Left 4 Downtown 2 Extension updates
 * Copyright (C) 2017 "Accelerator74"
 *
 * Left 4 DHooks Direct SourceMod plugin
 * Copyright (C) 2023 "SilverShot" / "Silvers"
 *
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http //www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http //www.sourcemod.net/license.php>.
 *
 * Version  $Id$
 */

#if defined _l4dh_included
 #endinput
#endif
#define _l4dh_included

#pragma newdecls required

#include <left4dhooks_anim>
#include <left4dhooks_silver>
#include <left4dhooks_lux_library>
#include <left4dhooks_stocks>



// Natives: 272 (including 3 for L4D1 only)
// L4D1 = 31 [left4downtown] + 47 [l4d_direct] + 16 [l4d2addresses] + 70 [silvers - mine!] + 4 [anim] = 169
// L4D2 = 61 [left4downtown] + 59 [l4d_direct] + 31 [l4d2addresses] + 114 [silvers - mine!] + 4 [anim] = 269

// Forwards: 207 (including 5 for L4D1 only)
// L4D1 = 142
// L4D2 = 202

// Stocks: 169 (L4D1 = 114, L4D2 = 167)
// left4dhooks_silver			46 stocks	(L4D1 = 39,		L4D2 = 53)
// left4dhooks_stocks			84 stocks	(L4D1 = 45,		L4D2 = 80)
// left4dhooks_lux_library		34 stocks	(L4D1 = 30,		L4D2 = 34)





public SharedPlugin __pl_l4dh =
{
	name = "left4dhooks",
	file = "left4dhooks.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_l4dh_SetNTVOptional()
{
	// =========================
	// Silvers Natives
	// =========================
	MarkNativeAsOptional("AnimHookEnable");
	MarkNativeAsOptional("AnimHookDisable");
	MarkNativeAsOptional("AnimGetActivity");
	MarkNativeAsOptional("AnimGetFromActivity");
	MarkNativeAsOptional("L4D_GetGameModeType");
	MarkNativeAsOptional("L4D_Deafen");
	MarkNativeAsOptional("L4D_GetTempHealth");
	MarkNativeAsOptional("L4D_SetTempHealth");
	MarkNativeAsOptional("L4D_GetReserveAmmo");
	MarkNativeAsOptional("L4D_SetReserveAmmo");
	MarkNativeAsOptional("L4D_PlayMusic");
	MarkNativeAsOptional("L4D_StopMusic");
	MarkNativeAsOptional("L4D_Dissolve");
	MarkNativeAsOptional("L4D_OnITExpired");
	MarkNativeAsOptional("L4D_EstimateFallingDamage");
	MarkNativeAsOptional("L4D_GetEntityWorldSpaceCenter");
	MarkNativeAsOptional("L4D_AngularVelocity");
	MarkNativeAsOptional("L4D_GetRandomPZSpawnPosition");
	MarkNativeAsOptional("L4D_GetNearestNavArea");
	MarkNativeAsOptional("L4D_GetLastKnownArea");
	MarkNativeAsOptional("L4D2_GetFurthestSurvivorFlow");
	MarkNativeAsOptional("L4D2_GetFirstSpawnClass");
	MarkNativeAsOptional("L4D2_SetFirstSpawnClass");
	MarkNativeAsOptional("L4D_FindRandomSpot");
	MarkNativeAsOptional("L4D2_IsVisibleToPlayer");
	MarkNativeAsOptional("L4D_HasAnySurvivorLeftSafeArea");
	MarkNativeAsOptional("L4D_IsAnySurvivorInStartArea");
	MarkNativeAsOptional("L4D_IsAnySurvivorInCheckpoint");
	MarkNativeAsOptional("L4D_AreAllSurvivorsInFinaleArea");
	MarkNativeAsOptional("L4D_IsInFirstCheckpoint");
	MarkNativeAsOptional("L4D_IsInLastCheckpoint");
	MarkNativeAsOptional("L4D_IsPositionInFirstCheckpoint");
	MarkNativeAsOptional("L4D_IsPositionInLastCheckpoint");
	MarkNativeAsOptional("L4D_GetCheckpointFirst");
	MarkNativeAsOptional("L4D_GetCheckpointLast");
	MarkNativeAsOptional("L4D2_IsReachable");
	MarkNativeAsOptional("L4D_HasPlayerControlledZombies");
	MarkNativeAsOptional("L4D_DetonateProjectile");
	MarkNativeAsOptional("L4D_TankRockPrj");
	MarkNativeAsOptional("L4D_PipeBombPrj");
	MarkNativeAsOptional("L4D_MolotovPrj");
	MarkNativeAsOptional("L4D2_VomitJarPrj");
	MarkNativeAsOptional("L4D2_GrenadeLauncherPrj");
	MarkNativeAsOptional("L4D_PrecacheParticle");
	MarkNativeAsOptional("L4D_RemoveEntityDelay");
	MarkNativeAsOptional("L4D_GetPointer");
	MarkNativeAsOptional("L4D_GetClientFromAddress");
	MarkNativeAsOptional("L4D_GetEntityFromAddress");
	MarkNativeAsOptional("L4D_ReadMemoryString");
	MarkNativeAsOptional("L4D_WriteMemoryString");
	MarkNativeAsOptional("L4D_GetServerOS");
	MarkNativeAsOptional("Left4DHooks_Version");
	MarkNativeAsOptional("L4D_HasMapStarted");
	MarkNativeAsOptional("L4D2_GetScriptScope");
	MarkNativeAsOptional("L4D2_GetVScriptEntity");
	MarkNativeAsOptional("L4D2_ExecVScriptCode");
	MarkNativeAsOptional("L4D2_GetVScriptOutput");
	MarkNativeAsOptional("L4D2_SpitterPrj");
	MarkNativeAsOptional("L4D2_UseAdrenaline");
	MarkNativeAsOptional("L4D_RespawnPlayer");
	MarkNativeAsOptional("L4D_SetHumanSpec");
	MarkNativeAsOptional("L4D_TakeOverBot");
	MarkNativeAsOptional("L4D_CanBecomeGhost");
	MarkNativeAsOptional("L4D_SetBecomeGhostAt");
	MarkNativeAsOptional("L4D2_AreWanderersAllowed");
	MarkNativeAsOptional("L4D2_GetCurrentFinaleStage");
	MarkNativeAsOptional("L4D2_ForceNextStage");
	MarkNativeAsOptional("L4D2_GetSurvivalStartTime");
	MarkNativeAsOptional("L4D2_SetSurvivalStartTime");
	MarkNativeAsOptional("L4D_ForceVersusStart");
	MarkNativeAsOptional("L4D_ForceSurvivalStart");
	MarkNativeAsOptional("L4D2_ForceScavengeStart");
	MarkNativeAsOptional("L4D2_IsTankInPlay");
	MarkNativeAsOptional("L4D2_GetDirectorScriptScope");
	MarkNativeAsOptional("L4D2_GetScriptValueInt");
	MarkNativeAsOptional("L4D2_GetScriptValueFloat");
	// MarkNativeAsOptional("L4D2_GetScriptValueString");
	MarkNativeAsOptional("L4D2_NavAreaTravelDistance");
	MarkNativeAsOptional("L4D2_NavAreaBuildPath");
	MarkNativeAsOptional("L4D2_CommandABot");
	MarkNativeAsOptional("L4D2_GetSurvivorSetMod");
	MarkNativeAsOptional("L4D2_GetSurvivorSetMap");
	MarkNativeAsOptional("L4D2_HasConfigurableDifficultySetting");
	MarkNativeAsOptional("L4D2_IsGenericCooperativeMode");
	MarkNativeAsOptional("L4D_IsFinaleEscapeInProgress");
	MarkNativeAsOptional("L4D_IsCoopMode");
	MarkNativeAsOptional("L4D2_IsRealismMode");
	MarkNativeAsOptional("L4D_IsSurvivalMode");
	MarkNativeAsOptional("L4D2_IsScavengeMode");
	MarkNativeAsOptional("L4D_IsVersusMode");
	MarkNativeAsOptional("L4D2_VScriptWrapper_GetMapNumber");
	MarkNativeAsOptional("L4D2_VScriptWrapper_HasEverBeenInjured");
	MarkNativeAsOptional("L4D2_VScriptWrapper_GetAliveDuration");
	MarkNativeAsOptional("L4D2_VScriptWrapper_IsDead");
	MarkNativeAsOptional("L4D2_VScriptWrapper_IsDying");
	MarkNativeAsOptional("L4D2_VScriptWrapper_UseAdrenaline");
	MarkNativeAsOptional("L4D2_VScriptWrapper_ReviveByDefib");
	MarkNativeAsOptional("L4D2_VScriptWrapper_ReviveFromIncap");
	MarkNativeAsOptional("L4D2_VScriptWrapper_GetSenseFlags");
	MarkNativeAsOptional("L4D2_VScriptWrapper_NavAreaBuildPath");
	MarkNativeAsOptional("L4D2_VScriptWrapper_NavAreaTravelDistance");



	// =========================
	// left4downtown.inc
	// =========================
	MarkNativeAsOptional("L4D_RestartScenarioFromVote");
	MarkNativeAsOptional("L4D_IsFirstMapInScenario");
	MarkNativeAsOptional("L4D_IsMissionFinalMap");
	MarkNativeAsOptional("L4D_NotifyNetworkStateChanged");
	MarkNativeAsOptional("L4D_StaggerPlayer");
	MarkNativeAsOptional("L4D2_SendInRescueVehicle");
	MarkNativeAsOptional("L4D_ReplaceTank");
	MarkNativeAsOptional("L4D2_SpawnTank");
	MarkNativeAsOptional("L4D2_SpawnSpecial");
	MarkNativeAsOptional("L4D2_SpawnWitch");
	MarkNativeAsOptional("L4D2_GetTankCount");
	MarkNativeAsOptional("L4D2_GetWitchCount");
	MarkNativeAsOptional("L4D_GetCurrentChapter");
	MarkNativeAsOptional("L4D_GetMaxChapters");
	MarkNativeAsOptional("L4D_GetAllNavAreas");
	MarkNativeAsOptional("L4D_GetNavAreaID");
	MarkNativeAsOptional("L4D_GetNavAreaByID");
	MarkNativeAsOptional("L4D_GetNavAreaPos");
	MarkNativeAsOptional("L4D_GetNavAreaCenter");
	MarkNativeAsOptional("L4D_GetNavAreaSize");
	MarkNativeAsOptional("L4D_NavArea_IsConnected");
	MarkNativeAsOptional("L4D_GetNavArea_SpawnAttributes");
	MarkNativeAsOptional("L4D_SetNavArea_SpawnAttributes");
	MarkNativeAsOptional("L4D_GetNavArea_AttributeFlags");
	MarkNativeAsOptional("L4D_SetNavArea_AttributeFlags");
	MarkNativeAsOptional("L4D_ScavengeBeginRoundSetupTime");
	MarkNativeAsOptional("L4D2_SpawnAllScavengeItems");
	MarkNativeAsOptional("L4D_ResetMobTimer");
	MarkNativeAsOptional("L4D_GetPlayerSpawnTime");
	MarkNativeAsOptional("L4D_SetPlayerSpawnTime");
	MarkNativeAsOptional("L4D_GetVersusMaxCompletionScore");
	MarkNativeAsOptional("L4D_SetVersusMaxCompletionScore");
	MarkNativeAsOptional("L4D_GetTeamScore");
	MarkNativeAsOptional("L4D_GetMobSpawnTimerRemaining");
	MarkNativeAsOptional("L4D_GetMobSpawnTimerDuration");
	MarkNativeAsOptional("L4D2_ChangeFinaleStage");
	MarkNativeAsOptional("L4D2_SpawnWitchBride");
	MarkNativeAsOptional("L4D_LobbyUnreserve");
	MarkNativeAsOptional("L4D_LobbyIsReserved");
	MarkNativeAsOptional("L4D_GetLobbyReservation");
	MarkNativeAsOptional("L4D_SetLobbyReservation");

	// l4d2weapons.inc
	MarkNativeAsOptional("L4D_GetWeaponID");
	MarkNativeAsOptional("L4D2_IsValidWeapon");
	MarkNativeAsOptional("L4D2_GetIntWeaponAttribute");
	MarkNativeAsOptional("L4D2_GetFloatWeaponAttribute");
	MarkNativeAsOptional("L4D2_SetIntWeaponAttribute");
	MarkNativeAsOptional("L4D2_SetFloatWeaponAttribute");
	MarkNativeAsOptional("L4D2_GetMeleeWeaponIndex");
	MarkNativeAsOptional("L4D2_GetIntMeleeAttribute");
	MarkNativeAsOptional("L4D2_GetFloatMeleeAttribute");
	MarkNativeAsOptional("L4D2_GetBoolMeleeAttribute");
	MarkNativeAsOptional("L4D2_SetIntMeleeAttribute");
	MarkNativeAsOptional("L4D2_SetFloatMeleeAttribute");
	MarkNativeAsOptional("L4D2_SetBoolMeleeAttribute");

	// l4d2timers.inc
	MarkNativeAsOptional("L4D2_CTimerReset");
	MarkNativeAsOptional("L4D2_CTimerStart");
	MarkNativeAsOptional("L4D2_CTimerInvalidate");
	MarkNativeAsOptional("L4D2_CTimerHasStarted");
	MarkNativeAsOptional("L4D2_CTimerIsElapsed");
	MarkNativeAsOptional("L4D2_CTimerGetElapsedTime");
	MarkNativeAsOptional("L4D2_CTimerGetRemainingTime");
	MarkNativeAsOptional("L4D2_CTimerGetCountdownDuration");
	MarkNativeAsOptional("L4D2_ITimerStart");
	MarkNativeAsOptional("L4D2_ITimerInvalidate");
	MarkNativeAsOptional("L4D2_ITimerHasStarted");
	MarkNativeAsOptional("L4D2_ITimerGetElapsedTime");

	// l4d2director.inc
	MarkNativeAsOptional("L4D2_GetVersusCampaignScores");
	MarkNativeAsOptional("L4D2_SetVersusCampaignScores");
	MarkNativeAsOptional("L4D2_GetVersusTankFlowPercent");
	MarkNativeAsOptional("L4D2_SetVersusTankFlowPercent");
	MarkNativeAsOptional("L4D2_GetVersusWitchFlowPercent");
	MarkNativeAsOptional("L4D2_SetVersusWitchFlowPercent");



	// =========================
	// l4d2_direct.inc
	// =========================
	MarkNativeAsOptional("L4D2Direct_GetPendingMobCount");
	MarkNativeAsOptional("L4D2Direct_SetPendingMobCount");
	MarkNativeAsOptional("L4D2Direct_GetTankPassedCount");
	MarkNativeAsOptional("L4D2Direct_SetTankPassedCount");
	MarkNativeAsOptional("L4D2Direct_GetVSCampaignScore");
	MarkNativeAsOptional("L4D2Direct_SetVSCampaignScore");
	MarkNativeAsOptional("L4D2Direct_GetVSTankFlowPercent");
	MarkNativeAsOptional("L4D2Direct_SetVSTankFlowPercent");
	MarkNativeAsOptional("L4D2Direct_GetVSTankToSpawnThisRound");
	MarkNativeAsOptional("L4D2Direct_SetVSTankToSpawnThisRound");
	MarkNativeAsOptional("L4D2Direct_GetVSWitchFlowPercent");
	MarkNativeAsOptional("L4D2Direct_SetVSWitchFlowPercent");
	MarkNativeAsOptional("L4D2Direct_GetVSWitchToSpawnThisRound");
	MarkNativeAsOptional("L4D2Direct_SetVSWitchToSpawnThisRound");
	MarkNativeAsOptional("L4D2Direct_GetMapMaxFlowDistance");
	MarkNativeAsOptional("L4D2Direct_GetInvulnerabilityTimer");
	MarkNativeAsOptional("L4D2Direct_GetTankTickets");
	MarkNativeAsOptional("L4D2Direct_SetTankTickets");
	MarkNativeAsOptional("L4D2Direct_GetTerrorNavArea");
	MarkNativeAsOptional("L4D2Direct_GetTerrorNavAreaFlow");
	MarkNativeAsOptional("L4D2Direct_TryOfferingTankBot");
	MarkNativeAsOptional("L4D2Direct_GetFlowDistance");
	MarkNativeAsOptional("L4D2Direct_DoAnimationEvent");
	MarkNativeAsOptional("L4DDirect_GetSurvivorHealthBonus");
	MarkNativeAsOptional("L4DDirect_SetSurvivorHealthBonus");
	MarkNativeAsOptional("L4DDirect_RecomputeTeamScores");
	MarkNativeAsOptional("L4D2Direct_GetTankCount");
	MarkNativeAsOptional("L4D2Direct_GetMobSpawnTimer");
	MarkNativeAsOptional("L4D2Direct_GetSIClassDeathTimer");
	MarkNativeAsOptional("L4D2Direct_GetSIClassSpawnTimer");
	MarkNativeAsOptional("L4D2Direct_GetVSStartTimer");
	MarkNativeAsOptional("L4D2Direct_GetScavengeRoundSetupTimer");
	MarkNativeAsOptional("L4D2Direct_GetScavengeOvertimeGraceTimer");
	MarkNativeAsOptional("L4D2Direct_GetSpawnTimer");
	MarkNativeAsOptional("L4D2Direct_GetShovePenalty");
	MarkNativeAsOptional("L4D2Direct_SetShovePenalty");
	MarkNativeAsOptional("L4D2Direct_GetNextShoveTime");
	MarkNativeAsOptional("L4D2Direct_SetNextShoveTime");
	MarkNativeAsOptional("L4D2Direct_GetPreIncapHealth");
	MarkNativeAsOptional("L4D2Direct_SetPreIncapHealth");
	MarkNativeAsOptional("L4D2Direct_GetPreIncapHealthBuffer");
	MarkNativeAsOptional("L4D2Direct_SetPreIncapHealthBuffer");
	MarkNativeAsOptional("L4D2Direct_GetInfernoMaxFlames");
	MarkNativeAsOptional("L4D2Direct_SetInfernoMaxFlames");
	MarkNativeAsOptional("L4D2Direct_GetScriptedEventManager");

	// l4d2d_timers.inc
	MarkNativeAsOptional("CTimer_Reset");
	MarkNativeAsOptional("CTimer_Start");
	MarkNativeAsOptional("CTimer_Invalidate");
	MarkNativeAsOptional("CTimer_HasStarted");
	MarkNativeAsOptional("CTimer_IsElapsed");
	MarkNativeAsOptional("CTimer_GetElapsedTime");
	MarkNativeAsOptional("CTimer_GetRemainingTime");
	MarkNativeAsOptional("CTimer_GetCountdownDuration");
	MarkNativeAsOptional("ITimer_Reset");
	MarkNativeAsOptional("ITimer_Start");
	MarkNativeAsOptional("ITimer_Invalidate");
	MarkNativeAsOptional("ITimer_HasStarted");
	MarkNativeAsOptional("ITimer_GetElapsedTime");
	MarkNativeAsOptional("CTimer_GetDuration");
	MarkNativeAsOptional("CTimer_SetDuration");
	MarkNativeAsOptional("CTimer_GetTimestamp");
	MarkNativeAsOptional("CTimer_SetTimestamp");
	MarkNativeAsOptional("ITimer_GetTimestamp");
	MarkNativeAsOptional("ITimer_SetTimestamp");



	// =========================
	// l4d2addresses.txt
	// =========================
	MarkNativeAsOptional("L4D_CTerrorPlayer_OnVomitedUpon");
	MarkNativeAsOptional("L4D2_Charger_ThrowImpactedSurvivor");
	MarkNativeAsOptional("L4D2_Charger_StartCarryingVictim");
	MarkNativeAsOptional("L4D2_Charger_PummelVictim");
	MarkNativeAsOptional("L4D2_Charger_EndPummel");
	MarkNativeAsOptional("L4D2_Charger_EndCarry");
	MarkNativeAsOptional("L4D2_Jockey_EndRide");
	MarkNativeAsOptional("L4D_Hunter_ReleaseVictim");
	MarkNativeAsOptional("L4D_Smoker_ReleaseVictim");
	MarkNativeAsOptional("L4D_CancelStagger");
	MarkNativeAsOptional("L4D_FindUseEntity");
	MarkNativeAsOptional("L4D_ForceHunterVictim");
	MarkNativeAsOptional("L4D_ForceSmokerVictim");
	MarkNativeAsOptional("L4D2_ForceJockeyVictim");
	MarkNativeAsOptional("L4D_CreateRescuableSurvivors");
	MarkNativeAsOptional("L4D_ReviveSurvivor");
	MarkNativeAsOptional("L4D_GetHighestFlowSurvivor");
	MarkNativeAsOptional("L4D_GetInfectedFlowDistance");
	MarkNativeAsOptional("L4D_CleanupPlayerState");
	MarkNativeAsOptional("L4D_TakeOverZombieBot");
	MarkNativeAsOptional("L4D_ReplaceWithBot");
	MarkNativeAsOptional("L4D_CullZombie");
	MarkNativeAsOptional("L4D_SetClass");
	MarkNativeAsOptional("L4D_MaterializeFromGhost");
	MarkNativeAsOptional("L4D_BecomeGhost");
	MarkNativeAsOptional("L4D_State_Transition");
	MarkNativeAsOptional("L4D_RegisterForbiddenTarget");
	MarkNativeAsOptional("L4D_UnRegisterForbiddenTarget");
	MarkNativeAsOptional("L4D2_CTerrorPlayer_OnHitByVomitJar");
	MarkNativeAsOptional("L4D2_Infected_OnHitByVomitJar");
	MarkNativeAsOptional("L4D2_CTerrorPlayer_Fling");
	MarkNativeAsOptional("L4D2_GetVersusCompletionPlayer");
	MarkNativeAsOptional("L4D2_SwapTeams");
	MarkNativeAsOptional("L4D2_AreTeamsFlipped");
	MarkNativeAsOptional("L4D_EndVersusModeRound");
	MarkNativeAsOptional("L4D2_StartRematchVote");
	MarkNativeAsOptional("L4D2_Rematch");
	MarkNativeAsOptional("L4D2_FullRestart");
	MarkNativeAsOptional("L4D2_HideVersusScoreboard");
	MarkNativeAsOptional("L4D2_HideScavengeScoreboard");
	MarkNativeAsOptional("L4D2_HideScoreboard");

	PlayerAnimState_MarkNativeAsOptional();
}

// ANIMATION NATIVES
void PlayerAnimState_MarkNativeAsOptional()
{
	MarkNativeAsOptional("PlayerAnimState.FromPlayer");
	MarkNativeAsOptional("PlayerAnimState.GetMainActivity");
	MarkNativeAsOptional("PlayerAnimState.ResetMainActivity");
	MarkNativeAsOptional("PlayerAnimState.m_bIsCustomSequence.get");
	MarkNativeAsOptional("PlayerAnimState.m_bIsCustomSequence.set");
	MarkNativeAsOptional("PlayerAnimState.m_bIsDead.get");
	MarkNativeAsOptional("PlayerAnimState.m_bIsDead.set");
	MarkNativeAsOptional("PlayerAnimState.m_bIsHealing.get");
	MarkNativeAsOptional("PlayerAnimState.m_bIsHealing.set");
	MarkNativeAsOptional("PlayerAnimState.m_bIsResurrection.get");
	MarkNativeAsOptional("PlayerAnimState.m_bIsResurrection.set");
	MarkNativeAsOptional("PlayerAnimState.m_bIsHitByCharger.get");
	MarkNativeAsOptional("PlayerAnimState.m_bIsHitByCharger.set");
	MarkNativeAsOptional("PlayerAnimState.m_bIsPummeled.get");
	MarkNativeAsOptional("PlayerAnimState.m_bIsPummeled.set");
	MarkNativeAsOptional("PlayerAnimState.m_bIsSlammedIntoWall.get");
	MarkNativeAsOptional("PlayerAnimState.m_bIsSlammedIntoWall.set");
	MarkNativeAsOptional("PlayerAnimState.m_bIsSlammedIntoGround.get");
	MarkNativeAsOptional("PlayerAnimState.m_bIsSlammedIntoGround.set");
	MarkNativeAsOptional("PlayerAnimState.m_bIsStartPummel.get");
	MarkNativeAsOptional("PlayerAnimState.m_bIsStartPummel.set");
	MarkNativeAsOptional("PlayerAnimState.m_bIsPounded.get");
	MarkNativeAsOptional("PlayerAnimState.m_bIsPounded.set");
	MarkNativeAsOptional("PlayerAnimState.m_bIsCarriedByCharger.get");
	MarkNativeAsOptional("PlayerAnimState.m_bIsCarriedByCharger.set");
	MarkNativeAsOptional("PlayerAnimState.m_bIsPunchedByTank.get");
	MarkNativeAsOptional("PlayerAnimState.m_bIsPunchedByTank.set");
	MarkNativeAsOptional("PlayerAnimState.m_bIsSpitting.get");
	MarkNativeAsOptional("PlayerAnimState.m_bIsSpitting.set");
	MarkNativeAsOptional("PlayerAnimState.m_bIsPouncedOn.get");
	MarkNativeAsOptional("PlayerAnimState.m_bIsPouncedOn.set");
	MarkNativeAsOptional("PlayerAnimState.m_bIsTongueAttacked.get");
	MarkNativeAsOptional("PlayerAnimState.m_bIsTongueAttacked.set");
	MarkNativeAsOptional("PlayerAnimState.m_bIsStartChainsaw.get");
	MarkNativeAsOptional("PlayerAnimState.m_bIsStartChainsaw.set");
	MarkNativeAsOptional("PlayerAnimState.m_bIsIsPouncing.get");
	MarkNativeAsOptional("PlayerAnimState.m_bIsIsPouncing.set");
	MarkNativeAsOptional("PlayerAnimState.m_bIsRiding.get");
	MarkNativeAsOptional("PlayerAnimState.m_bIsRiding.set");
	MarkNativeAsOptional("PlayerAnimState.m_bIsJockeyRidden.get");
	MarkNativeAsOptional("PlayerAnimState.m_bIsJockeyRidden.set");
	MarkNativeAsOptional("PlayerAnimState.m_bIsTonguing.get");
	MarkNativeAsOptional("PlayerAnimState.m_bIsTonguing.set");
	MarkNativeAsOptional("PlayerAnimState.m_bIsCharging.get");
	MarkNativeAsOptional("PlayerAnimState.m_bIsCharging.set");
	MarkNativeAsOptional("PlayerAnimState.m_bIsPummeling.get");
	MarkNativeAsOptional("PlayerAnimState.m_bIsPummeling.set");
	MarkNativeAsOptional("PlayerAnimState.m_bIsPounding.get");
	MarkNativeAsOptional("PlayerAnimState.m_bIsPounding.set");
	MarkNativeAsOptional("PlayerAnimState.m_bIsTongueReelingIn.get");
	MarkNativeAsOptional("PlayerAnimState.m_bIsTongueReelingIn.set");
	MarkNativeAsOptional("PlayerAnimState.m_bIsTongueAttacking.get");
	MarkNativeAsOptional("PlayerAnimState.m_bIsTongueAttacking.set");
}
#endif





// ====================================================================================================
// ANIMATION NATIVES
// ====================================================================================================
methodmap PlayerAnimState {
	// Get the PlayerAnimState instance of a player.
	public static native PlayerAnimState FromPlayer(int client);
	
	// Main activity of player's animation, matching enums in "left4dhooks_anim.inc".
	public native int GetMainActivity();
	
	// Restart and recalculate the main activity.
	public native void ResetMainActivity();
	
	// All booleans (or flags) that used for animation events.
	property bool m_bIsCustomSequence { // True only after "CTerrorPlayerAnimState::SetCustomSequence".
		public native get();
		public native set(bool value);
	}
	property bool m_bIsDead {
		public native get();
		public native set(bool value);
	}
	property bool m_bIsHealing {
		public native get();
		public native set(bool value);
	}
	property bool m_bIsResurrection {
		public native get();
		public native set(bool value);
	}
	property bool m_bIsHitByCharger { // aka multi-charged, bowling.
		public native get();
		public native set(bool value);
	}
	property bool m_bIsPummeled {
		public native get();
		public native set(bool value);
	}
	property bool m_bIsSlammedIntoWall {
		public native get();
		public native set(bool value);
	}
	property bool m_bIsSlammedIntoGround {
		public native get();
		public native set(bool value);
	}
	property bool m_bIsStartPummel { // Something to do with charger pummel animation, not sure about the name.
		public native get();
		public native set(bool value);
	}
	property bool m_bIsPounded { // Pummel get-up
		public native get();
		public native set(bool value);
	}
	property bool m_bIsCarriedByCharger {
		public native get();
		public native set(bool value);
	}
	property bool m_bIsPunchedByTank { // Rock get-up shares this
		public native get();
		public native set(bool value);
	}
	property bool m_bIsSpitting {
		public native get();
		public native set(bool value);
	}
	property bool m_bIsPouncedOn {
		public native get();
		public native set(bool value);
	}
	property bool m_bIsTongueAttacked {
		public native get();
		public native set(bool value);
	}
	property bool m_bIsStartChainsaw {
		public native get();
		public native set(bool value);
	}
	property bool m_bIsIsPouncing {
		public native get();
		public native set(bool value);
	}
	property bool m_bIsRiding {
		public native get();
		public native set(bool value);
	}
	property bool m_bIsJockeyRidden {
		public native get();
		public native set(bool value);
	}
	property bool m_bIsTonguing {
		public native get();
		public native set(bool value);
	}
	property bool m_bIsCharging {
		public native get();
		public native set(bool value);
	}
	property bool m_bIsPummeling {
		public native get();
		public native set(bool value);
	}
	property bool m_bIsPounding {
		public native get();
		public native set(bool value);
	}
	property bool m_bIsTongueReelingIn {
		public native get();
		public native set(bool value);
	}
	property bool m_bIsTongueAttacking {
		public native get();
		public native set(bool value);
	}
}





// ====================================================================================================
// VARIOUS ENUMS
// ====================================================================================================
// For the game mode native and forward
enum
{
	GAMEMODE_UNKNOWN	= 0,
	GAMEMODE_COOP		= 1,
	GAMEMODE_VERSUS		= 2,
	GAMEMODE_SURVIVAL	= 4,
	GAMEMODE_SCAVENGE	= 8
};

// For the "L4D_GetPointer" native
// Some of these will only be valid after OnMapStart() because they change on each new map. For example: POINTER_GAMERULES, POINTER_THENAVAREAS, POINTER_MISSIONINFO and possibly others
enum PointerType
{
	POINTER_DIRECTOR		= 1,	// @TheDirector
	POINTER_SERVER			= 2,	// @sv
	POINTER_GAMERULES		= 3,	// @g_pGameRules
	POINTER_NAVMESH			= 4,	// @TheNavMesh
	POINTER_ZOMBIEMANAGER	= 5,	// @TheZombieManager
	POINTER_WEAPONINFO		= 6,	// @_ZL20m_WeaponInfoDatabase
	POINTER_MELEEINFO		= 7,	// @g_MeleeWeaponInfoStore (L4D2 Only)
	POINTER_EVENTMANAGER	= 8,	// pScriptedEventManager (L4D2 Only)
	POINTER_SCAVENGEMODE	= 9,	// pScavengeMode (L4D2 Only)
	POINTER_VERSUSMODE		= 10,	// pVersusMode
	POINTER_SCRIPTVM		= 11,	// @g_pScriptVM (L4D2 Only)
	POINTER_THENAVAREAS		= 12,	// @TheNavAreas
	POINTER_MISSIONINFO		= 13,	// MissionInfo pointer
	POINTER_SURVIVALMODE	= 14	// pSurvivalMode pointer (assuming this is the same as pVersusMode in L4D1 and also TheDirector)
};

// Provided by "BHaType":
// For the "L4D_State_Transition" native
// X -> Y (means X state will become Y state on next frame or some seconds later)
enum
{
	STATE_ACTIVE = 0,
	STATE_WELCOME,				// -> STATE_PICKING_TEAM
	STATE_PICKING_TEAM,
	STATE_PICKINGCLASS,			// -> STATE_ACTIVE
	STATE_DEATH_ANIM,			// -> STATE_DEATH_WAIT_FOR_KEY
	STATE_DEATH_WAIT_FOR_KEY,	// -> STATE_OBSERVER_MODE
	STATE_OBSERVER_MODE,
	STATE_WAITING_FOR_RESCUE,
	STATE_GHOST,
	STATE_INTRO_CAMERA
};

// From: https://developer.valvesoftware.com/wiki/L4D2_Director_Scripts
// For the "L4D2_ChangeFinaleStage" and "L4D2_GetCurrentFinaleStage" natives and "L4D2_OnChangeFinaleStage" forward
enum
{
	FINALE_GAUNTLET_1 = 0,
	FINALE_HORDE_ATTACK_1 = 1,
	FINALE_HALFTIME_BOSS = 2,
	FINALE_GAUNTLET_2 = 3,
	FINALE_HORDE_ATTACK_2 = 4,
	FINALE_FINAL_BOSS = 5,
	FINALE_HORDE_ESCAPE = 6,
	FINALE_CUSTOM_PANIC = 7,
	FINALE_CUSTOM_TANK = 8,
	FINALE_CUSTOM_SCRIPTED = 9,
	FINALE_CUSTOM_DELAY = 10,
	FINALE_CUSTOM_CLEAROUT = 11,
	FINALE_GAUNTLET_START = 12,
	FINALE_GAUNTLET_HORDE = 13,
	FINALE_GAUNTLET_HORDE_BONUSTIME = 14,
	FINALE_GAUNTLET_BOSS_INCOMING = 15,
	FINALE_GAUNTLET_BOSS = 16,
	FINALE_GAUNTLET_ESCAPE = 17,
	FINALE_NONE = 18
};

// Used as the "reason" by the "L4D_OnKnockedDown*" forwards
enum
{
	KNOCKDOWN_HUNTER = 1,
	KNOCKDOWN_TANK = 2,
	KNOCKDOWN_CHARGER = 3
};

// From: https://developer.valvesoftware.com/wiki/List_of_L4D_Series_Nav_Mesh_Attributes
// Use by "L4D_GetNavArea_AttributeFlags" and "L4D_SetNavArea_AttributeFlags" natives
// NavArea Base Attributes:
enum
{
	NAV_BASE_CROUCH = 1,							// (1<<0)
	NAV_BASE_JUMP = 2,								// (1<<1)
	NAV_BASE_PRECISE = 4,							// (1<<2)
	NAV_BASE_NO_JUMP = 8,							// (1<<3)
	NAV_BASE_STOP = 16,								// (1<<4)
	NAV_BASE_RUN = 32,								// (1<<5)
	NAV_BASE_WALK = 64,								// (1<<6)
	NAV_BASE_AVOID = 128,							// (1<<7)
	NAV_BASE_TRANSIENT = 256,						// (1<<8)
	NAV_BASE_DONT_HIDE = 512,						// (1<<9)
	NAV_BASE_STAND = 1024,							// (1<<10)
	NAV_BASE_NO_HOSTAGES = 2048,					// (1<<11)
	NAV_BASE_STAIRS = 4096,							// (1<<12)
	NAV_BASE_NO_MERGE = 8192,						// (1<<13)
	NAV_BASE_OBSTACLE_TOP = 16384,					// (1<<14)
	NAV_BASE_CLIFF = 32768,							// (1<<15)
	NAV_BASE_TANK_ONLY = 65536,						// (1<<16)
	NAV_BASE_MOB_ONLY = 131072,						// (1<<17)
	NAV_BASE_PLAYERCLIP = 262144,					// (1<<18)
	NAV_BASE_BREAKABLEWALL = 524288,				// (1<<19)
	NAV_BASE_FLOW_BLOCKED = 134217728,				// (1<<27)
	NAV_BASE_OUTSIDE_WORLD = 268435456,				// (1<<28)
	NAV_BASE_MOSTLY_FLAT = 536870912,				// (1<<29)
	NAV_BASE_HAS_ELEVATOR = 1073741824,				// (1<<30)
	NAV_BASE_NAV_BLOCKER = -2147483648				// (1<<31)
};

// Use by "L4D_GetNavArea_SpawnAttributes" and "L4D_SetNavArea_SpawnAttributes" natives
// NavArea Spawn Attributes:
enum
{
	NAV_SPAWN_EMPTY = 2,							// (1<<0)
	NAV_SPAWN_STOP_SCAN = 4,						// (1<<1)
	NAV_SPAWN_BATTLESTATION = 32,					// (1<<5)
	NAV_SPAWN_FINALE = 64,							// (1<<6)
	NAV_SPAWN_PLAYER_START = 128,					// (1<<7)
	NAV_SPAWN_BATTLEFIELD = 256,					// (1<<8)
	NAV_SPAWN_IGNORE_VISIBILITY = 512,				// (1<<9)
	NAV_SPAWN_NOT_CLEARABLE = 1024,					// (1<<10)
	NAV_SPAWN_CHECKPOINT = 2048,					// (1<<11)
	NAV_SPAWN_OBSCURED = 4096,						// (1<<12)
	NAV_SPAWN_NO_MOBS = 8192,						// (1<<13)
	NAV_SPAWN_THREAT = 16384,						// (1<<14)
	NAV_SPAWN_RESCUE_VEHICLE = 32768,				// (1<<15)
	NAV_SPAWN_RESCUE_CLOSET = 65536,				// (1<<16)
	NAV_SPAWN_ESCAPE_ROUTE = 131072,				// (1<<17)
	NAV_SPAWN_DESTROYED_DOOR = 262144,				// (1<<18)
	NAV_SPAWN_NOTHREAT = 524288,					// (1<<19)
	NAV_SPAWN_LYINGDOWN = 1048576,					// (1<<20)
	NAV_SPAWN_COMPASS_NORTH = 16777216,				// (1<<24)
	NAV_SPAWN_COMPASS_NORTHEAST = 33554432,			// (1<<25)
	NAV_SPAWN_COMPASS_EAST = 67108864,				// (1<<26)
	NAV_SPAWN_COMPASS_EASTSOUTH = 134217728,		// (1<<27)
	NAV_SPAWN_COMPASS_SOUTH = 268435456,			// (1<<28)
	NAV_SPAWN_COMPASS_SOUTHWEST = 536870912,		// (1<<29)
	NAV_SPAWN_COMPASS_WEST = 1073741824,			// (1<<30)
	NAV_SPAWN_COMPASS_WESTNORTH = -2147483648		// (1<<31)
};

// From: https://developer.valvesoftware.com/wiki/L4D2_Director_Scripts
// Used by "L4D_NavArea_IsConnected" native
// NavArea Spawn Attributes:
enum
{
	NAV_NORTH = 0,
	NAV_EAST = 1,
	NAV_SOUTH = 2,
	NAV_WEST = 3,
	NAV_ALL = 4
};

// List provided by "A1m`" taken from: https://github.com/A1mDev/l4d2_structs/blob/master/terror_player_animstate.h
// There are constants that are not used, these constants were already inside the engine, the developers added their own over the existing code
// Some constants from 'l4d2util_contants.inc'
// These are used by the "L4D2Direct_DoAnimationEvent" native and "L4D_OnDoAnimationEvent*" forwards
// L4D1 seems to only have 35 animation events, the names may not be relative to those listed here
// For L4D1: See below the enum.
enum PlayerAnimEvent_t
{
	// Made by A1m`

	PLAYERANIMEVENT_ATTACK_PRIMARY = 1, // CMultiPlayerAnimState::DoAnimationEvent
	PLAYERANIMEVENT_ATTACK_SECONDARY = 2, // CMultiPlayerAnimState::DoAnimationEvent
	PLAYERANIMEVENT_ATTACK_GRENADE = 3, // CMultiPlayerAnimState::DoAnimationEvent
	PLAYERANIMEVENT_RELOAD = 4, // CMultiPlayerAnimState::DoAnimationEvent, CTerrorGun::SendWeaponAnim
	PLAYERANIMEVENT_RELOAD_LOOP = 5, // CMultiPlayerAnimState::DoAnimationEvent, CBaseShotgun::CheckReload->PlayReloadAnim
	PLAYERANIMEVENT_RELOAD_END = 6, //CMultiPlayerAnimState::DoAnimationEvent, CBaseShotgun::CheckReload->PlayReloadAnim, CTerrorGun::AbortReload
	PLAYERANIMEVENT_JUMP = 7, // CMultiPlayerAnimState::DoAnimationEvent, CTerrorGameMovement::DoJump, CCSGameMovement::CheckJumpButton
	PLAYERANIMEVENT_LAND = 8, // CTerrorGameMovement::PlayerRoughLandingEffects
	PLAYERANIMEVENT_SWIM = 9, // Not sure, not used in the game anyway
	PLAYERANIMEVENT_DIE = 10, // CMultiPlayerAnimState::DoAnimationEvent, CTerrorPlayer::StartSurvivorDeathAnim, CTerrorPlayer::OnIncapacitatedAsTank
	PLAYERANIMEVENT_FLINCH_CHEST = 11, // CMultiPlayerAnimState::DoAnimationEvent
	PLAYERANIMEVENT_FLINCH_HEAD = 12, // CMultiPlayerAnimState::DoAnimationEvent
	PLAYERANIMEVENT_FLINCH_LEFTARM = 13, // CMultiPlayerAnimState::DoAnimationEvent
	PLAYERANIMEVENT_FLINCH_RIGHTARM = 14, // CMultiPlayerAnimState::DoAnimationEvent
	PLAYERANIMEVENT_FLINCH_LEFTLEG = 15, // CMultiPlayerAnimState::DoAnimationEvent
	PLAYERANIMEVENT_FLINCH_RIGHTLEG = 16, // CMultiPlayerAnimState::DoAnimationEvent
	PLAYERANIMEVENT_DOUBLEJUMP = 17, // Not sure, not used in the game anyway
	PLAYERANIMEVENT_CANCEL_GESTURE_ATTACK_AND_RELOAD = 18, // CTerrorPlayer::OnShovedByPounceLanding, CTerrorPlayer::OnShovedBySurvivor, CTerrorPlayer::OnRideEnded, CTerrorPlayer::OnPounceEnded
	PLAYERANIMEVENT_CANCEL = 19, // Not sure, not used in the game anyway
	PLAYERANIMEVENT_SPAWN = 20, // CMultiPlayerAnimState::DoAnimationEvent
	PLAYERANIMEVENT_SNAP_YAW = 21, // CMultiPlayerAnimState::DoAnimationEvent
	PLAYERANIMEVENT_CUSTOM = 22, // CMultiPlayerAnimState::DoAnimationEvent
	PLAYERANIMEVENT_CUSTOM_GESTURE = 23, // CMultiPlayerAnimState::DoAnimationEvent
	PLAYERANIMEVENT_CUSTOM_SEQUENCE = 24, // CMultiPlayerAnimState::DoAnimationEvent
	PLAYERANIMEVENT_CUSTOM_GESTURE_SEQUENCE = 25, // Not sure, not used in the game anyway

	// TF Specific. Here until there's a derived game solution to this
	PLAYERANIMEVENT_ATTACK_PRE = 26, // Not sure, not used in the game anyway
	PLAYERANIMEVENT_ATTACK_POST = 27, // Not sure, not used in the game anyway
	PLAYERANIMEVENT_GRENADE1_DRAW = 28, // Not sure, not used in the game anyway
	PLAYERANIMEVENT_GRENADE2_DRAW = 29, // Not sure, not used in the game anyway
	PLAYERANIMEVENT_GRENADE1_THROW = 30, // Not sure, not used in the game anyway
	PLAYERANIMEVENT_GRENADE2_THROW = 31, // Not sure, not used in the game anyway
	PLAYERANIMEVENT_VOICE_COMMAND_GESTURE = 32, // Not sure, not used in the game?. CTerrorPlayerAnimState::DoAnimationEvent
	PLAYERANIMEVENT_HAND_ATTACK = 33, // CClaw::OnSwingStart, CTerrorPlayer::UpdateTankEffects, CTankClaw::OnSwingStart
	PLAYERANIMEVENT_HAND_LOW_ATTACK = 34, // CTankClaw::OnSwingStart, CTerrorWeapon::OnSwingStart
	PLAYERANIMEVENT_SHOVE_COMMON = 35, // CTerrorWeapon::OnSwingStart
	PLAYERANIMEVENT_SHOVE = 36, // CTerrorWeapon::OnSwingStart
	PLAYERANIMEVENT_SHOVE_ZOMBIE_STOMP = 37, //CTerrorWeapon::OnSwingStart
	PLAYERANIMEVENT_START_RELOADING_SHOTGUN = 38, // CBaseShotgun::Reload->PlayReloadAnim
	PLAYERANIMEVENT_START_CHAINSAW = 39, // CChainsaw::Deploy
	PLAYERANIMEVENT_PRIMARY_ATTACK = 40, // CTerrorMeleeWeapon::StartMeleeSwing, CBaseBeltItem::PrimaryAttack, FireTerrorBullets, CGrenadeLauncher::PrimaryAttack
	PLAYERANIMEVENT_SECONDARY_ATTACK = 41, // CTerrorMeleeWeapon::StartMeleeSwing, CVomit::ActivateAbility, FireTerrorBullets
	PLAYERANIMEVENT_HEAL_SELF = 42,
	PLAYERANIMEVENT_HEAL_OTHER = 43,
	PLAYERANIMEVENT_CROUCH_HEAL_INCAP = 44, // CTerrorPlayer::StartReviving
	PLAYERANIMEVENT_CROUCH_HEAL_INCAPACITATED_ABOVE = 45, // CTerrorPlayer::StartReviving
	PLAYERANIMEVENT_STOP_USE_ACTION = 46, // CTerrorPlayer::StopRevivingSomeone, CTerrorPlayer::StopBeingRevived, CFirstAidKit::OnStopAction, CItemAmmoPack::OnStopAction, CItemBaseUpgradePack::OnStopAction, CItemDefibrillator::OnStopAction
	PLAYERANIMEVENT_PICKUP_START_SUBJECT = 47, // CTerrorPlayer::StartReviving
	PLAYERANIMEVENT_PICKUP_STOP_SUBJECT = 48, // CTerrorPlayer::CleanupPlayerState, CTerrorPlayer::StopBeingRevived, CTerrorPlayer::StopRevivingSomeone
	PLAYERANIMEVENT_PICKUP_SUCCESS_SUBJECT = 49, // CTerrorPlayer::OnRevived
	PLAYERANIMEVENT_DEFIB_START = 50,
	PLAYERANIMEVENT_DEFIB_END = 51,
	PLAYERANIMEVENT_DEPLOY_AMMO = 52,
	PLAYERANIMEVENT_USE_GASCAN_START = 53,
	PLAYERANIMEVENT_USE_GASCAN_END = 54, // CGasCan::OnStopAction
	PLAYERANIMEVENT_USE_COLA_START = 55,
	PLAYERANIMEVENT_USE_COLA_END = 56, // CColaBottles::OnStopAction
	PLAYERANIMEVENT_FLINCH_EVENT_SHOVED_BY_TEAMMATE = 57, // CTerrorPlayer::OnTakeDamageInternal->GetFlinchEvent, CTerrorPlayer::OnTakeDamage_Alive->GetFlinchEvent, CTerrorWeapon::OnHit->GetFlinchEvent
	PLAYERANIMEVENT_FLINCH_EVENT_TAKE_DAMAGE = 58, // CTerrorPlayer::GetFlinchEvent
	PLAYERANIMEVENT_THROW_ITEM_START = 59, // CBaseCSGrenade::PrimaryAttack
	PLAYERANIMEVENT_ROLL_GRENADE = 60, // Not sure, not used in the game anyway
	PLAYERANIMEVENT_THROW_ITEM_FINISH = 61, // CBaseCSGrenade::ItemPostFrame
	PLAYERANIMEVENT_THROW_GRENADE = 62, // CCSPlayer::DoAnimationEvent
	PLAYERANIMEVENT_THROW_ITEM_HOLSTER = 63, // CBaseCSGrenade::Holster
	PLAYERANIMEVENT_PLAYER_USE = 64, // CTerrorPlayer::OnUseEntity
	PLAYERANIMEVENT_CHANGE_SLOT = 65, // CWeaponCSBase::DefaultDeploy
	PLAYERANIMEVENT_UNKNOWN_START_GESTURE = 66, // Don't know. Not used in the game? Something like option 32? CTerrorPlayerAnimState::DoAnimationEvent
	PLAYERANIMEVENT_TUG_HANGING_PLAYER = 67, // CTerrorPlayer::StartTug
	PLAYERANIMEVENT_STUMBLE = 68, // CTerrorPlayer::UpdateStagger, CTerrorPlayer::OnShovedByPounceLanding, CTerrorPlayer::OnStaggered, CTerrorPlayer::UpdateStagger, CTerrorPlayer::OnShovedBySurvivor
	PLAYERANIMEVENT_POUNCE_VICTIM_END = 69,
	PLAYERANIMEVENT_SPIT_SPITTING = 70, // CSpitAbility::ActivateAbility
	PLAYERANIMEVENT_CHARGER_START_CHARGE = 71, // CCharge::BeginCharge
	PLAYERANIMEVENT_CHARGER_END_CHARGE = 72, // CCharge::EndCharge
	PLAYERANIMEVENT_CHARGER_PUMMELING_START = 73,
	PLAYERANIMEVENT_CHARGER_PUMMELING_END = 74, // ZombieReplacement::Restore, CTerrorPlayer::UpdatePound, ZombieReplacement::Restore
	PLAYERANIMEVENT_CHARGER_SLAM_INTO_GROUND = 75, // CTerrorPlayer::OnSlammedSurvivor
	PLAYERANIMEVENT_IMPACT_BY_CHARGER = 76,
	PLAYERANIMEVENT_CHARGER_PUMMELED = 77, // ThrowImpactedSurvivor->CTerrorPlayer::Fling; CTerrorPlayerAnimState::HandleActivity_Pummeling
	PLAYERANIMEVENT_POUNDED_BY_CHARGER = 78, // ZombieReplacement::Restore, CTerrorPlayer::UpdatePound, CTerrorPlayerAnimState::HandleActivity_Pummeling
	PLAYERANIMEVENT_CARRIED_BY_CHARGER = 79, // ZombieReplacement::Restore, CTerrorPlayer::OnStartBeingCarried
	PLAYERANIMEVENT_STAGGERING = 80, // CTerrorPlayer::OnSlammedSurvivor
	PLAYERANIMEVENT_VICTIM_SLAMMED_INTO_GROUND = 81, // CTerrorPlayer::OnSlammedSurvivor
	PLAYERANIMEVENT_HUNTER_POUNCING = 82, // ZombieReplacement::Restore, CTerrorPlayer::OnPouncedUpon, ZombieReplacement::Restore
	PLAYERANIMEVENT_HUNTER_POUNCE_ON_VICTIM = 83, // CTerrorPlayer::OnPouncedOnSurvivor
	PLAYERANIMEVENT_JOCKEY_RIDING = 84,
	PLAYERANIMEVENT_JOCKEY_RIDDEN = 85, // ZombieReplacement::Restore
	PLAYERANIMEVENT_HUNTER_GETUP = 86, // CTerrorPlayer::OnPouncedUpon, ZombieReplacement::Restore
	PLAYERANIMEVENT_TONGUE_LAUNCH_START = 87, // SmokerTongueVictim::OnStart
	PLAYERANIMEVENT_TONGUE_LAUNCH_END = 88, // CTongue::OnEnterExtendingState
	PLAYERANIMEVENT_TONGUE_REELING_IN = 89, // CTongue::OnEnterAttachedToTargetState
	PLAYERANIMEVENT_TONGUE_ATTACKING_START = 90, // CTongue::OnTouch
	PLAYERANIMEVENT_TONGUE_ATTACKING_END = 91, // CTerrorPlayer::OnReleasingWithTongue
	PLAYERANIMEVENT_VICTIM_PULLED = 92, // ZombieReplacement::Restore, CTerrorPlayer::OnGrabbedByTongue
	PLAYERANIMEVENT_ROCK_THROW = 93, // CThrow::ActivateAbility
	PLAYERANIMEVENT_TANK_CLIMB = 94, // TankLocomotion::ClimbUpToLedge
	PLAYERANIMEVENT_TANK_RAGE = 95, // CTerrorPlayer::OnAttackSuccess, CTerrorPlayer::OnMissionLost, CTerrorPlayer::ClientCommand (dance)
	PLAYERANIMEVENT_PLAYERHIT_BY_TANK = 96, // CTankClaw::OnPlayerHit, CTerrorPlayer::OnTakeDamage->Fling, CTerrorPlayer::OnKnockedDown
	PLAYERANIMEVENT_PUSH_ENTITY = 97, // CTerrorPlayer::PlayerUse
	PLAYERANIMEVENT_FIDGET = 98, // CTerrorPlayerAnimState::UpdateFidgeting

	PLAYERANIMEVENT_COUNT // Total size 99. Function 'CTerrorPlayer::DoAnimationEvent'
};

// L4D1 anim values appear to be related to these below. Thanks to "Dragokas" for gathering a list of them:
/*
1 - Primary Attack
2 - Unused
3 - Aiming
4 - Reload Reserved Ammo
5 - Chambering Of A Cartridge (No Sound)
6 - Chambering Of A Cartridge (With Sound)
7 - Shotgun Reload (With Sound)
8 - Shotgun Reload (No Sound)
9 - Shove (Side)
10 - Shove (Forward)
11 - Shove (Right Arm)
12 - Stomp
13 - Heal Myself
14 - Heal Teammate1
15 - Pick Up Incapped Player
16 - Heal Teammate2
21 - Headbutt
22 - Headbutt2
23 - Pick Up Item From Ground
24 - Take Item From Teammate
25 - Change Weapon
26 - Weapon Reload Fast
27 - Weapon Recoil + Reload
28 - Weapon Recoil + Reload (same)
29... - Seems unused (Same for 2, 17-20).
*/

enum WeaponType
{
	WEAPONTYPE_PISTOL,
	WEAPONTYPE_SMG,
	WEAPONTYPE_RIFLE,
	WEAPONTYPE_SHOTGUN,
	WEAPONTYPE_SNIPERRIFLE,
	WEAPONTYPE_MACHINEGUN,

	WEAPONTYPE_GRENADE = 7,
	WEAPONTYPE_HEALING,
	WEAPONTYPE_REVIVING,
	WEAPONTYPE_MELEE,
	WEAPONTYPE_CHAINSAW,
	WEAPONTYPE_GRENADELAUNCHER,
	WEAPONTYPE_CARRIEDPROP,
	WEAPONTYPE_CLAW,
	WEAPONTYPE_UPGRADEPACK,

	WEAPONTYPE_UNKNOWN
};

stock const char g_sWeaponTypes[WeaponType][] =
{
	"pistol",
	"smg",
	"rifle",
	"shotgun",
	"sniperrifle",
	"machinegun",
	"",
	"grenade",
	"healing",
	"reviving",
	"melee",
	"chainsaw",
	"grenadelauncher",
	"carriedprop",
	"claw",
	"upgradepack",
	""
};





// ====================================================================================================
// ANIMATION HOOK
// ====================================================================================================
/* The PRE hook can utilize the "ACT_*" enum defines from the "include/left4dhooks_anim.inc" include file. */
typeset AnimHookCallback
{
	/**
	 * @brief Callback called whenever animation is invoked
	 *
	 * @param client		Client triggering
	 * @param sequence		The animation "activity" (pre-hook) or "m_nSequence" (post-hook) sequence number being used
	 *
	 * @return				Plugin_Changed to change the animation sequence, Plugin_Continue otherwise
	 */
	function Action(int client, int &sequence);
}

/**
 * @brief Add a client animation hook
 * @remarks All hooks are removed on map change
 *
 * @param client			The client to hook
 * @param callback			Callback function for your pre-hook (uses "ACT_*" activity numbers) or INVALID_FUNCTION to not use
 * @param callbackPost		Callback function for your post-hook (uses "m_nSequence" sequence numbers) or INVALID_FUNCTION to not use
 *
 * @return					True on success, false if client invalid
 */
native bool AnimHookEnable(int client, AnimHookCallback callback, AnimHookCallback callbackPost = INVALID_FUNCTION);

/**
 * @brief Remove a client animation hook
 * @remarks All hooks are removed on map change
 *
 * @param client			The client to hook
 * @param callback			Callback function for your pre-hook (uses "ACT_*" activity numbers) or INVALID_FUNCTION if not used
 * @param callbackPost		Callback function for your post-hook (uses "m_nSequence" sequence numbers) or INVALID_FUNCTION if not used
 *
 * @return					True on success, false if client not hooked
 */
native bool AnimHookDisable(int client, AnimHookCallback callback, AnimHookCallback callbackPost = INVALID_FUNCTION);

/**
 * @brief Retrieves the activity string from it's relative activity number
 * @remarks activity numbers are different from a models "m_nSequence" sequence numbers
 * @remarks The ACT_* list and values are for Survivor models and differ from other models. Use the "m_nSequence" sequence value in a post hook for Special Infected
 * @remarks The "m_nSequence" sequence values for each model can be found using Left4Dead Authoring Tools > Model Viewer
 * @remarks The PRE hook can utilize the "ACT_*" enum defines from the "include/left4dhooks_anim.inc" include file instead of using this method of converting them
 *
 * @param sequence			Activity number to retrieve from
 * @param activity			Destination string to store the activity
 * @param maxlength			Size of destination string
 *
 * @return					True on success, false on failure to find
 */
native bool AnimGetActivity(int sequence, char[] activity, int maxlength);

/**
 * @brief Retrieves the animation activity number from an activity string
 *
 * @param activity			The activity string to retrieve from
 *
 * @return					Activity number or -1 on failure
 */
native int AnimGetFromActivity(char[] activity);





// ====================================================================================================
// FORWARDS - left4downtown.inc (and new ones by Silvers)
// ====================================================================================================
/**
 * @brief Called whenever ZombieManager::SpawnSpecial(ZombieClassType,Vector&,QAngle&) is invoked
 * @remarks Only used for bot special spawns (not players)
 * @remarks zombieClass: 1=Smoker, 2=Boomer, 3=Hunter, 4=Spitter, 5=Jockey, 6=Charger
 *
 * @param zombieClass	Zombie class that will be spawned
 * @param vecPos		Vector coordinate where special will be spawned
 * @param vecAng		QAngle where special will be facing
 *
 * @return				Plugin_Handled to block special from spawning,
 * 						Plugin_Changed to change the zombie class type to spawn, Plugin_Continue otherwise
 */
forward Action L4D_OnSpawnSpecial(int &zombieClass, const float vecPos[3], const float vecAng[3]);

/**
 * @brief Called whenever ZombieManager::SpawnSpecial(ZombieClassType,Vector&,QAngle&) is invoked
 * @remarks Only used for bot special spawns (not players)
 * @remarks zombieClass: 1=Smoker, 2=Boomer, 3=Hunter, 4=Spitter, 5=Jockey, 6=Charger
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param client		The client index who spawned. Can be 0 if spawning failed
 * @param zombieClass	Zombie class that will be spawned
 * @param vecPos		Vector coordinate where special will be spawned
 * @param vecAng		QAngle where special will be facing
 *
 * @noreturn
 */
forward void L4D_OnSpawnSpecial_Post(int client, int zombieClass, const float vecPos[3], const float vecAng[3]);

/**
 * @brief Called whenever ZombieManager::SpawnSpecial(ZombieClassType,Vector&,QAngle&) is invoked
 * @remarks Only used for bot special spawns (not players)
 * @remarks zombieClass: 1=Smoker, 2=Boomer, 3=Hunter, 4=Spitter, 5=Jockey, 6=Charger
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param client		The client index who spawned. Can be 0 if spawning failed or -1 if blocked
 * @param zombieClass	Zombie class that will be spawned
 * @param vecPos		Vector coordinate where special will be spawned
 * @param vecAng		QAngle where special will be facing
 *
 * @noreturn
 */
forward void L4D_OnSpawnSpecial_PostHandled(int client, int zombieClass, const float vecPos[3], const float vecAng[3]);

/**
 * @brief Called whenever ZombieManager::SpawnTank(Vector&,QAngle&) is invoked
 * @remarks Not invoked if z_spawn tank is used and it gives a ghosted/dead player tank
 *
 * @param vecPos		Vector coordinate where tank is spawned
 * @param vecAng		QAngle where tank will be facing
 *
 * @return				Plugin_Handled to block tank from spawning, Plugin_Continue otherwise
 */
forward Action L4D_OnSpawnTank(const float vecPos[3], const float vecAng[3]);

/**
 * @brief Called whenever ZombieManager::SpawnTank(Vector&,QAngle&) is invoked
 * @remarks Not invoked if z_spawn tank is used and it gives a ghosted/dead player tank
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param client		The client index who spawned
 * @param vecPos		Vector coordinate where tank is spawned
 * @param vecAng		QAngle where tank will be facing
 *
 * @noreturn
 */
forward void L4D_OnSpawnTank_Post(int client, const float vecPos[3], const float vecAng[3]);

/**
 * @brief Called whenever ZombieManager::SpawnTank(Vector&,QAngle&) is invoked
 * @remarks Not invoked if z_spawn tank is used and it gives a ghosted/dead player tank
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param client		The client index who spawned (can be -1 if blocked in pre hook)
 * @param vecPos		Vector coordinate where tank is spawned
 * @param vecAng		QAngle where tank will be facing
 *
 * @noreturn
 */
forward void L4D_OnSpawnTank_PostHandled(int client, const float vecPos[3], const float vecAng[3]);

/**
 * @brief Called whenever ZombieManager::SpawnWitch(Vector&,QAngle&) is invoked
 * @brief Called when a Witch spawns
 *
 * @param vecPos		Vector coordinate where witch is spawned
 * @param vecAng		QAngle where witch will be facing
 *
 * @return 				Plugin_Handled to block witch from spawning, Plugin_Continue otherwise
 */
forward Action L4D_OnSpawnWitch(const float vecPos[3], const float vecAng[3]);

/**
 * @brief Called whenever ZombieManager::SpawnWitch(Vector&,QAngle&) is invoked
 * @brief Called when a Witch spawns
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param entity		Entity index that spawned
 * @param vecPos		Vector coordinate where witch is spawned
 * @param vecAng		QAngle where witch will be facing
 *
 * @noreturn
 */
forward void L4D_OnSpawnWitch_Post(int entity, const float vecPos[3], const float vecAng[3]);

/**
 * @brief Called whenever ZombieManager::SpawnWitch(Vector&,QAngle&) is invoked
 * @brief Called when a Witch spawns
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param entity		Entity index that spawned (can be -1 if blocked)
 * @param vecPos		Vector coordinate where witch is spawned
 * @param vecAng		QAngle where witch will be facing
 *
 * @noreturn
 */
forward void L4D_OnSpawnWitch_PostHandled(int entity, const float vecPos[3], const float vecAng[3]);

/**
 * @brief Called whenever ZombieManager::SpawnWitchBride(Vector&,QAngle&) is invoked
 * @brief Called when a Witch Bride spawns
 *
 * @param vecPos		Vector coordinate where witch is spawned
 * @param vecAng		QAngle where witch will be facing
 *
 * @return 				Plugin_Handled to block witch from spawning, Plugin_Continue otherwise
 */
// L4D2 only
forward Action L4D2_OnSpawnWitchBride(const float vecPos[3], const float vecAng[3]);

/**
 * @brief Called whenever ZombieManager::SpawnWitchBride(Vector&,QAngle&) is invoked
 * @brief Called when a Witch Bride spawns
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param entity		Entity index that spawned
 * @param vecPos		Vector coordinate where witch is spawned
 * @param vecAng		QAngle where witch will be facing
 *
 * @noreturn
 */
// L4D2 only
forward void L4D2_OnSpawnWitchBride_Post(int entity, const float vecPos[3], const float vecAng[3]);

/**
 * @brief Called whenever ZombieManager::SpawnWitchBride(Vector&,QAngle&) is invoked
 * @brief Called when a Witch Bride spawns
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param entity		Entity index that spawned (can be -1 if blocked)
 * @param vecPos		Vector coordinate where witch is spawned
 * @param vecAng		QAngle where witch will be facing
 *
 * @noreturn
 */
// L4D2 only
forward void L4D2_OnSpawnWitchBride_PostHandled(int entity, const float vecPos[3], const float vecAng[3]);

/**
 * @brief Called whenever CDirector::OnMobRushStart(void) is invoked
 * @remarks called on random hordes, mini and finale hordes, and boomer hordes, causes Zombies to attack
 *			Not called on "z_spawn mob", hook the console command and check arguments to catch plugin mobs
 *			This function is used to reset the Director's natural horde timer
 *
 * @return				Plugin_Handled to block, Plugin_Continue otherwise
 */
forward Action L4D_OnMobRushStart();

/**
 * @brief Called whenever CDirector::OnMobRushStart(void) is invoked
 * @remarks called on random hordes, mini and finale hordes, and boomer hordes, causes Zombies to attack
 *			Not called on "z_spawn mob", hook the console command and check arguments to catch plugin mobs
 *			This function is used to reset the Director's natural horde timer
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @noreturn
 */
forward void L4D_OnMobRushStart_Post();

/**
 * @brief Called whenever CDirector::OnMobRushStart(void) is invoked
 * @remarks called on random hordes, mini and finale hordes, and boomer hordes, causes Zombies to attack
 *			Not called on "z_spawn mob", hook the console command and check arguments to catch plugin mobs
 *			This function is used to reset the Director's natural horde timer
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @noreturn
 */
forward void L4D_OnMobRushStart_PostHandled();

/**
 * @brief Called whenever ZombieManager::SpawnITMob(int) is invoked
 * @remarks called on boomer hordes, increases Zombie Spawn Queue
 *
 * @param amount		Amount of Zombies to add to Queue
 *
 * @return				Plugin_Handled to block, Plugin_Changed to use overwritten values from plugin, Plugin_Continue otherwise
 */
forward Action L4D_OnSpawnITMob(int &amount);

/**
 * @brief Called whenever ZombieManager::SpawnITMob(int) is invoked
 * @remarks called on boomer hordes, increases Zombie Spawn Queue
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param amount		Amount of Zombies to add to Queue
 *
 * @noreturn
 */
forward void L4D_OnSpawnITMob_Post(int amount);

/**
 * @brief Called whenever ZombieManager::SpawnITMob(int) is invoked
 * @remarks called on boomer hordes, increases Zombie Spawn Queue
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param amount		Amount of Zombies to add to Queue
 *
 * @noreturn
 */
forward void L4D_OnSpawnITMob_PostHandled(int amount);

/**
 * @brief Called whenever ZombieManager::SpawnMob(int) is invoked
 * @remarks called on natural hordes & z_spawn mob, increases Zombie Spawn
 *			Queue, triggers player OnMobSpawned (vocalizations), sets horde
 *			direction, and plays horde music
 *
 * @param amount		Amount of Zombies to add to Queue
 *
 * @return				Plugin_Handled to block, Plugin_Changed to use overwritten values from plugin, Plugin_Continue otherwise
 */
forward Action L4D_OnSpawnMob(int &amount);

/**
 * @brief Called whenever ZombieManager::SpawnMob(int) is invoked
 * @remarks called on natural hordes & z_spawn mob, increases Zombie Spawn
 *			Queue, triggers player OnMobSpawned (vocalizations), sets horde
 *			direction, and plays horde music
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param amount		Amount of Zombies to add to Queue
 *
 * @noreturn
 */
forward void L4D_OnSpawnMob_Post(int amount);

/**
 * @brief Called whenever ZombieManager::SpawnMob(int) is invoked
 * @remarks called on natural hordes & z_spawn mob, increases Zombie Spawn
 *			Queue, triggers player OnMobSpawned (vocalizations), sets horde
 *			direction, and plays horde music
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param amount		Amount of Zombies to add to Queue
 *
 * @noreturn
 */
forward void L4D_OnSpawnMob_PostHandled(int amount);

/**
 * @brief Called when a witch has been startled by someone
 *
 * @param witch			The witch entity index
 * @param victim		Client who harassed the Witch, will be 0 on spawn
 *
 * @noreturn
 **/
forward void L4D_OnWitchSetHarasser(int witch, int victim);

/**
 * @brief Called when Tank::EnterStasis() is invoked
 * @remarks Called when a Tank enters stasis mode in Versus mode
 *
 * @param tank			Client index of the Tank
 *
 * @noreturn
 **/
forward void L4D_OnEnterStasis(int tank);

/**
 * @brief Called when Tank::LeaveStasis() is invoked
 * @remarks Called when a Tank leaves stasis mode in Versus mode
 *
 * @param tank				Client index of the Tank
 *
 * @noreturn
 **/
forward void L4D_OnLeaveStasis(int tank);

/**
 * @brief Called whenever CTerrorPlayer::OnEnterGhostState(CTerrorPlayer*) is invoked
 * @remarks This happens when a player enters ghost mode (or in finales auto-materialized)
 * @remarks This forward triggers before the player enters ghost state allowing it to be blocked
 *
 * @param client		the client that has entered ghost mode
 *
 * @return				Plugin_Handled to block, Plugin_Continue otherwise
 */
forward Action L4D_OnEnterGhostStatePre(int client);

/**
 * @brief Called whenever CTerrorPlayer::OnEnterGhostState(CTerrorPlayer*) is invoked
 * @remarks This happens when a player enters ghost mode (or in finales auto-materialized)
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param client		the client that has entered ghost mode
 *
 * @noreturn
 */
forward void L4D_OnEnterGhostState(int client);

/**
 * @brief Called whenever CTerrorPlayer::OnEnterGhostState(CTerrorPlayer*) is invoked
 * @remarks This happens when a player enters ghost mode (or in finales auto-materialized)
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param client		the client that has entered ghost mode
 *
 * @noreturn
 */
forward void L4D_OnEnterGhostState_PostHandled(int client);

/**
 * @brief Called whenever CTerrorPlayer::TakeOverBot(CTerrorPlayer*) is invoked
 * @remarks This happens when player is looking to take over a bot
 *
 * @param client			the client that is looking to take over a bot
 *
 * @return					Plugin_Handled to block, Plugin_Continue otherwise
 */
forward Action L4D_OnTakeOverBot(int client);

/**
 * @brief Called whenever CTerrorPlayer::TakeOverBot(CTerrorPlayer*) is invoked
 * @remarks This happens when player is looking to take over a bot
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param client			the client that is looking to take over a bot
 * @param success			true if the takeover was successful, false otherwise
 *
 * @noreturn
 */
forward void L4D_OnTakeOverBot_Post(int client, bool success);

/**
 * @brief Called whenever CTerrorPlayer::TakeOverBot(CTerrorPlayer*) is invoked
 * @remarks This happens when player is looking to take over a bot
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param client			the client that is looking to take over a bot
 * @param success			true if the takeover was successful, false otherwise
 *
 * @noreturn
 */
forward void L4D_OnTakeOverBot_PostHandled(int client, bool success);

/**
 * @brief Called whenever CTerrorPlayer::MaterializeFromGhost is invoked
 * @remarks Called when a Special Infected spawns out of ghost mode
 *
 * @param victim			the client who spawned
 *
 * @return					Plugin_Handled to block, Plugin_Continue otherwise
 */
forward Action L4D_OnMaterializeFromGhostPre(int client);

/**
 * @brief Called whenever CTerrorPlayer::MaterializeFromGhost is invoked
 * @remarks Called when a Special Infected spawns out of ghost mode
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param victim			the client who spawned
 *
 * @noreturn
 */
forward void L4D_OnMaterializeFromGhost(int client);

/**
 * @brief Called whenever CTerrorPlayer::MaterializeFromGhost is invoked
 * @remarks Called when a Special Infected spawns out of ghost mode
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param victim			the client who spawned
 *
 * @noreturn
 */
forward void L4D_OnMaterializeFromGhost_PostHandled(int client);

/**
 * @brief Called whenever IsTeamFull is invoked
 * @remarks called when bots or players are joining a team
 *
 * @param team			Which team is being checked. 2=Survivors. 3=Special Infected
 *
 * @return				Plugin_Handled to block changing team, Plugin_Continue otherwise
 */
forward Action L4D_OnIsTeamFull(int team, bool &full);

/**
 * @brief Called whenever CTerrorGameRules::ClearTeamScores(bool) is invoked
 * @remarks 	This resets the map score at the beginning of a map, and by checking
 *			the campaign scores on a small timer you can see if they were reset as well
 *
 * @param newCampaign	if true then this is a new campaign, if false a new chapter. Not used for L4D1
 *
 * @return				Plugin_Handled to block scores from being cleared, Plugin_Continue otherwise. Does not block reset in L4D1
 */
forward Action L4D_OnClearTeamScores(bool newCampaign);

/**
 * @brief Called whenever CTerrorGameRules::SetCampaignScores(int,int) is invoked
 * @remarks The campaign scores are updated after the 2nd round is completed
 *
 * @param scoreA		score of logical team A
 * @param scoreB		score of logical team B
 *
 * @return				Plugin_Handled to block campaign scores from being set, Plugin_Continue otherwise
 */
forward Action L4D_OnSetCampaignScores(int &scoreA, int &scoreB);

/**
 * @brief Called whenever CTerrorGameRules::SetCampaignScores(int,int) is invoked
 * @remarks The campaign scores are updated after the 2nd round is completed
 *
 * @param scoreA		score of logical team A
 * @param scoreB		score of logical team B
 *
 * @noreturn
 */
forward void L4D_OnSetCampaignScores_Post(int scoreA, int scoreB);

/**
 * @brief Called whenever CTerrorPlayer:RecalculateVersusScore(void) is invoked
 * @remarks Calculates an individual survivors health bonus from their current health and status
 *
 * @return		Plugin_Handled to block health bonus from being calculated
*/
// L4D1 only
forward Action L4D_OnRecalculateVersusScore(int client);

/**
 * @brief Called whenever CTerrorPlayer:RecalculateVersusScore(void) is invoked
 * @remarks Calculates an individual survivors health bonus from their current health and status
 *
 * @noreturn
*/
// L4D1 only
forward void L4D_OnRecalculateVersusScore_Post(int client);

/**
 * @brief Called whenever CDirector::OnFirstSurvivorLeftSafeArea is invoked
 * @remarks A versus round is started when survivors leave the safe room, or force started
 *			after 90 seconds regardless
 *
 * @param client		the survivor that left the safe area first
 *
 * @return				Plugin_Handled to block round from being started, Plugin_Continue otherwise
 */
forward Action L4D_OnFirstSurvivorLeftSafeArea(int client);

/**
 * @brief Called whenever CDirector::OnFirstSurvivorLeftSafeArea is invoked
 * @remarks A versus round is started when survivors leave the safe room, or force started
 *			after 90 seconds regardless
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param client		the survivor that left the safe area first
 *
 * @noreturn
 */
forward void L4D_OnFirstSurvivorLeftSafeArea_Post(int client);

/**
 * @brief Called whenever CDirector::OnFirstSurvivorLeftSafeArea is invoked
 * @remarks A versus round is started when survivors leave the safe room, or force started
 *			after 90 seconds regardless
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param client		the survivor that left the safe area first
 *
 * @noreturn
 */
forward void L4D_OnFirstSurvivorLeftSafeArea_PostHandled(int client);

/**
 * @brief Called whenever CDirector::OnForceSurvivorPositions is invoked
 * @remarks Triggers after round start when Survivors are forced into starting positions, usually first map and finale escape start, does not trigger on all maps
 *
 * @noreturn
 */
forward void L4D_OnForceSurvivorPositions_Pre();

/**
 * @brief Called whenever CDirector::OnForceSurvivorPositions is invoked
 * @remarks Triggers after round start when Survivors are forced into starting positions, usually first map and finale escape start, does not trigger on all maps
 *
 * @noreturn
 */
forward void L4D_OnForceSurvivorPositions();

/**
 * @brief Called whenever CDirector::OnReleaseSurvivorPositions is invoked
 * @remarks Triggers after round start when Survivors are released from the starting positions, usually first map and finale escape start, does not trigger on all maps
 *
 * @noreturn
 */
forward void L4D_OnReleaseSurvivorPositions();

/**
 * @brief Called whenever "SpeakResponseConceptFromEntityIO" is invoked
 * @remarks Triggers on concept talking
 *
 * @param entity		Entity doing the talking (not always client indexes, might be a func_orator)
 *
 * @noreturn
 */
forward void L4D_OnSpeakResponseConcept_Pre(int entity);

/**
 * @brief Called whenever "SpeakResponseConceptFromEntityIO" is invoked
 * @remarks Triggers on concept talking
 *
 * @param entity		Entity doing the talking (not always client indexes, might be a func_orator)
 *
 * @noreturn
 */
forward void L4D_OnSpeakResponseConcept_Post(int entity);

/**
 * @brief Called whenever CTerrorPlayer::GetCrouchTopSpeed() is invoked
 * @remarks Constantly called to get players max Crouch speed
 *
 * @param target		the client that its being called on (not changeable)
 * @param retVal		what to override the return value with
 *
 * @return				Plugin_Handled to override return value, Plugin_Continue otherwise
 */
forward Action L4D_OnGetCrouchTopSpeed(int target, float &retVal);

/**
 * @brief Called whenever CTerrorPlayer::GetRunTopSpeed() is invoked
 * @remarks Constantly called to get players max Run speed
 *
 * @param target		the client that its being called on (not changeable)
 * @param retVal		what to override the return value with
 *
 * @return				Plugin_Handled to override return value, Plugin_Continue otherwise
 */
forward Action L4D_OnGetRunTopSpeed(int target, float &retVal);

/**
 * @brief Called whenever CTerrorPlayer::GetWalkTopSpeed() is invoked
 * @remarks Constantly called to get players max Walk speed
 *
 * @param target		the client that its being called on (not changeable)
 * @param retVal		what to override the return value with
 *
 * @return				Plugin_Handled to override return value, Plugin_Continue otherwise
 */
forward Action L4D_OnGetWalkTopSpeed(int target, float &retVal);

/**
 * @brief Called whenever CDirector::GetScriptValue(const char*, int) is invoked
 * @remarks A script value is map specific
 * @warning This forward may not fire on some keys due to C inline feature. Use L4D2_OnGetScriptValueInt instead to avoid the issue
 *
 * @param key			the script's key name
 * @param retVal		what to override the return value with
 *
 * @return				Plugin_Handled to override return value, Plugin_Continue otherwise
 */
// L4D2 only
forward Action L4D_OnGetScriptValueInt(const char[] key, int &retVal);

/**
 * @brief Called whenever CDirector::GetScriptValue(const char*, float) is invoked
 * @remarks A script value is map specific
 * @warning This forward may not fire on some keys due to C inline feature. Use L4D2_OnGetScriptValueFloat instead to avoid the issue
 *
 * @param key			the script's key name
 * @param retVal		what to override the return value with
 *
 * @return				Plugin_Handled to override return value, Plugin_Continue otherwise
 */
// L4D2 only
forward Action L4D_OnGetScriptValueFloat(const char[] key, float &retVal);

/**
 * @brief Called whenever CDirector::GetScriptValue(const char*, Vector) is invoked
 * @remarks A script value is map specific
 * @warning This forward may not fire on some keys due to C inline feature. Use L4D2_OnGetScriptValueVector instead to avoid the issue
 *
 * @param key			the script's key name
 * @param retVal		what to override the return value with
 *
 * @return				Plugin_Handled to override return value, Plugin_Continue otherwise
 */
// L4D2 only
// Unused, unable to determine if the return value is modified, and potentially different detour setup for linux
// forward Action L4D_OnGetScriptValueVector(const char[] key, float retVal[3]);

/**
 * @brief Called whenever CDirector::GetScriptValue(const char*, const char*, char*, int) is invoked
 * @remarks A script value is map specific
 * @warning This forward may not fire on some keys due to C inline feature. Use L4D2_OnGetScriptValueString instead to avoid the issue
 *
 * @param key			the script's key name
 * @param defaultVal	default key return, usually empty
 * @param retVal		returned string
 *
 * @return				Plugin_Handled to override return value, Plugin_Continue otherwise
 */
// L4D2 only
forward Action L4D_OnGetScriptValueString(const char[] key, const char[] defaultVal, char retVal[128]);

// These are used for the "L4D2_OnGetScriptValueVoid" forward, and interally for the other "L4D2_OnGetScriptValue*" forwards:
enum fieldtype_t
{
	FIELD_VOID = 0,				// No type or value
	FIELD_FLOAT = 1,			// Any floating point value
	FIELD_VECTOR = 3,			// Any vector, QAngle, or AngularImpulse
	FIELD_INTEGER = 5,			// Any integer or enum
	FIELD_BOOLEAN = 6,			// boolean, implemented as an int, I may use this as a hint for compression
	FIELD_CHARACTER = 8,		// a byte
	FIELD_CSTRING = 31,
	FIELD_UNSIGNED = 38,
	FIELD_QANGLE = 40
};

enum struct VariantBuffer
{
	int m_int;
	float m_float;
	char m_string[256];
	float m_vector[3];
}

/**
 * @brief Called whenever CSquirrelVM::GetValue() is invoked
 * @remarks A script value is map specific
 * @remarks This is called when the searching key is not present in the Script VM
 * @remarks "retVal" accepts only 2 formats --- int:12345 or float:123.4
 *
 * @param key				the script's key name
 * @param type				the data type being set in retVal
 * @param retVal			what to override the return value with
 * @param hScope			The script scope (table) this was called from
 *							Use L4D2_GetDirectorScriptScope() if you want to make sure this was called by CDirector
 *
 * @return					Plugin_Handled to override return value, Plugin_Continue otherwise
 */
// L4D2 only
forward Action L4D2_OnGetScriptValueVoid(const char[] key, fieldtype_t &type, VariantBuffer retVal, int hScope);

/**
 * @brief Called whenever CSquirrelVM::GetValue() is invoked
 * @remarks A script value is map specific
 *
 * @param key				the script's key name
 * @param retVal			what to override the return value with
 * @param hScope			The script scope (table) this was called from
 *							Use L4D2_GetDirectorScriptScope() if you want to make sure this was called by CDirector
 *
 * @return					Plugin_Handled to override return value, Plugin_Continue otherwise
 */
// L4D2 only
forward Action L4D2_OnGetScriptValueInt(const char[] key, int &retVal, int hScope);

/**
 * @brief Called whenever CSquirrelVM::GetValue() is invoked
 * @remarks A script value is map specific
 *
 * @param key				the script's key name
 * @param retVal			what to override the return value with
 * @param hScope			The script scope (table) this was called from
 *							Use L4D2_GetDirectorScriptScope() if you want to make sure this was called by CDirector
 *
 * @return					Plugin_Handled to override return value, Plugin_Continue otherwise
 */
// L4D2 only
forward Action L4D2_OnGetScriptValueFloat(const char[] key, float &retVal, int hScope);

/**
 * @brief Called whenever CSquirrelVM::GetValue() is invoked
 * @remarks A script value is map specific
 *
 * @param key				the script's key name
 * @param retVal			what to override the return value with
 * @param hScope			The script scope (table) this was called from
 *							Use L4D2_GetDirectorScriptScope() if you want to make sure this was called by CDirector
 *
 * @return					Plugin_Handled to override return value, Plugin_Continue otherwise
 */
// L4D2 only
forward Action L4D2_OnGetScriptValueVector(const char[] key, float retVal[3], int hScope);

/**
 * @brief Called whenever CTerrorGameRules::HasConfigurableDifficultySetting() is invoked
 * @remarks used to deny/allow difficulty changes in different game modes
 *
 * @param retVal		what to override the return value with. 1 to allow difficulty configuration, 0 to deny
 *
 * @return				Plugin_Handled to override return value, Plugin_Continue otherwise
 */
// L4D2 only
forward Action L4D_OnHasConfigurableDifficulty(int &retVal);

/**
 * @brief Called whenever CTerrorGameRules::HasConfigurableDifficultySetting() is invoked
 * @remarks used to deny/allow difficulty changes in different game modes
 *
 * @param retVal		what to override the return value with. 1 to allow difficulty configuration, 0 to deny
 *
 * @noreturn
 */
// L4D2 only
forward void L4D_OnHasConfigurableDifficulty_Post(int retVal);

/**
 * @brief Called whenever CTerrorGameRules::GetSurvivorSet(void) is invoked
 * @remarks Constantly called to get the survivor character set
 *
 * @param retVal		what to override the return value with
 *
 * @return				Plugin_Handled to override return value, Plugin_Continue otherwise
 */
// L4D2 only
forward Action L4D_OnGetSurvivorSet(int &retVal);

/**
 * @brief Called whenever CTerrorGameRules::FastGetSurvivorSet(void) is invoked
 * @remarks Constantly called to get the survivor character set
 *
 * @param retVal	what to override the return value with
 *
 * @return			Plugin_Handled to override return value, Plugin_Continue otherwise
 */
// L4D2 only
forward Action L4D_OnFastGetSurvivorSet(int &retVal);

/**
 * @brief Called whenever CDirectorVersusMode::GetMissionVersusBossSpawning() is invoked
 * @remarks Passed values are from the map's Mission Keyvalues. If those keyvalues don't exist, they are from cvar and other globals
 *
 * @param spawn_pos_min		Minimum spawn position (percent of flow distance) for bosses
 * @param spawn_pos_max		Maximum spawn position (percent of flow distance) for bosses
 * @param tank_chance		Chance for a tank to spawn on this map
 * @param witch_chance		Chance for a witch to spawn on this map
 *
 * @return			Plugin_Handled to block reading map data, Plugin_Changed to use overwritten values from plugin, Plugin_Continue to continue to read from mission data
 */
forward Action L4D_OnGetMissionVSBossSpawning(float &spawn_pos_min, float &spawn_pos_max, float &tank_chance, float &witch_chance);

/**
 * @brief Called whenever CDirectorVersusMode::GetMissionVersusBossSpawning() is invoked
 * @remarks Passed values are from the map's Mission Keyvalues. If those keyvalues don't exist, they are from cvar and other globals
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param spawn_pos_min		Minimum spawn position (percent of flow distance) for bosses
 * @param spawn_pos_max		Maximum spawn position (percent of flow distance) for bosses
 * @param tank_chance		Chance for a tank to spawn on this map
 * @param witch_chance		Chance for a witch to spawn on this map
 *
 * @noreturn
 */
forward void L4D_OnGetMissionVSBossSpawning_Post(float spawn_pos_min, float spawn_pos_max, float tank_chance, float witch_chance);

/**
 * @brief Called whenever CDirectorVersusMode::GetMissionVersusBossSpawning() is invoked
 * @remarks Passed values are from the map's Mission Keyvalues. If those keyvalues don't exist, they are from cvar and other globals
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param spawn_pos_min		Minimum spawn position (percent of flow distance) for bosses
 * @param spawn_pos_max		Maximum spawn position (percent of flow distance) for bosses
 * @param tank_chance		Chance for a tank to spawn on this map
 * @param witch_chance		Chance for a witch to spawn on this map
 *
 * @noreturn
 */
forward void L4D_OnGetMissionVSBossSpawning_PostHandled(float spawn_pos_min, float spawn_pos_max, float tank_chance, float witch_chance);

/**
 * @brief Called whenever ZombieManager::ReplaceTank(CTerrorPlayer *,CTerrorPlayer *) is invoked
 * @remarks When a player loses tank control and is replaced by another player. Not invoked if tank is bot
 *
 * @param tank			the player who was a tank
 * @param newtank		a player who has become a new tank
 *
 * @noreturn
 */
forward void L4D_OnReplaceTank(int tank, int newtank);

/**
 * @brief Called whenever CTankClaw::DoSwing(CTankClaw *this) is invoked
 * @remarks When a tank is swinging to punch
 *
 * @param tank			tank client index
 * @param claw			the claw entity index
 *
 * @noreturn
 */
forward void L4D_TankClaw_DoSwing_Pre(int tank, int claw);

/**
 * @brief Called whenever CTankClaw::DoSwing(CTankClaw *this) is invoked
 * @remarks When a tank is swinging to punch
 *
 * @param tank			tank client index
 * @param claw			the claw entity index
 *
 * @noreturn
 */
forward void L4D_TankClaw_DoSwing_Post(int tank, int claw);

/**
 * @brief Called whenever CTankClaw::GroundPound() is invoked
 * @remarks When hitting the ground (maybe only when hitting an incapped player)
 * @remarks The forwards "L4D_TankClaw_OnPlayerHit_Pre" and "L4D_TankClaw_OnPlayerHit_Post" trigger after this, allowing identification of victim
 * @remarks The forwards "L4D_TankClaw_DoSwing_Pre" and "L4D_TankClaw_DoSwing_Post" can trigger after this
 *
 * @param tank			tank client index
 * @param claw			the claw entity index
 *
 * @noreturn
 */
forward void L4D_TankClaw_GroundPound_Pre(int tank, int claw);

/**
 * @brief Called whenever CTankClaw::GroundPound() is invoked
 * @remarks When hitting the ground (maybe only when hitting an incapped player)
 * @remarks The forwards "L4D_TankClaw_OnPlayerHit_Pre" and "L4D_TankClaw_OnPlayerHit_Post" trigger before this
 * @remarks The forwards "L4D_TankClaw_DoSwing_Pre" and "L4D_TankClaw_DoSwing_Post" can trigger after this
 *
 * @param tank			tank client index
 * @param claw			the claw entity index
 *
 * @noreturn
 */
forward void L4D_TankClaw_GroundPound_Post(int tank, int claw);

/**
 * @brief Called whenever CTankClaw::OnPlayerHit(CTerrorPlayer*, bool) is invoked
 * @remarks When a tank swings and punches a player
 *
 * @param tank			tank client index
 * @param claw			the claw entity index
 * @param player		the player being hit
 *
 * @return				Plugin_Handled to block the target player from being stumbled, Plugin_Continue otherwise
 */
forward Action L4D_TankClaw_OnPlayerHit_Pre(int tank, int claw, int player);

/**
 * @brief Called whenever CTankClaw::OnPlayerHit(CTerrorPlayer*, bool) is invoked
 * @remarks When a tank swings and punches a player
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param tank			tank client index
 * @param claw			the claw entity index
 * @param player		the player being hit
 *
 * @noreturn
 */
forward void L4D_TankClaw_OnPlayerHit_Post(int tank, int claw, int player);

/**
 * @brief Called whenever CTankClaw::OnPlayerHit(CTerrorPlayer*, bool) is invoked
 * @remarks When a tank swings and punches a player
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param tank			tank client index
 * @param rock			the claw entity index
 * @param player		the player being hit
 *
 * @noreturn
 */
forward void L4D_TankClaw_OnPlayerHit_PostHandled(int tank, int claw, int player);

/**
 * @brief Called whenever CTankRock::Detonate() is invoked
 * @remarks When a tank rock hits something and explodes
 *
 * @param tank			tank client index
 * @param rock			the rock entity index
 *
 * @noreturn
 */
forward void L4D_TankRock_OnDetonate(int tank, int rock);

/**
 * @brief Called whenever CTankRock::OnRelease(Vector const&, QAngle const&, Vector const&, Vector const&) is invoked
 * @remarks When a tank rock is thrown
 *
 * @param tank			tank client index (can be -1 if the rock was created by the native "L4D_TankRockPrj" or the "env_rock_launcher" entity)
 * @param rock			the rock entity index
 * @param vecPos		the position vector of the rock
 * @param vecAng		the angle vector of the rock
 * @param vecVel		the velocity vector of the rock
 * @param vecRot		the rotation vector of the rock
 *
 * @return				Plugin_Changed to modify the vector values, Plugin_Continue otherwise
 */
forward Action L4D_TankRock_OnRelease(int tank, int rock, float vecPos[3], float vecAng[3], float vecVel[3], float vecRot[3]);

/**
 * @brief Called whenever CTankRock::OnRelease(Vector const&, QAngle const&, Vector const&, Vector const&) is invoked
 * @remarks When a tank rock is thrown
 * @remarks Forward shows the final values that may have been changed from the relative pre-hook
 *
 * @param tank			tank client index (can be -1 if the rock was created by the native "L4D_TankRockPrj" or the "env_rock_launcher" entity)
 * @param rock			the rock entity index
 * @param vecPos		the position vector of the rock
 * @param vecAng		the angle vector of the rock
 * @param vecVel		the velocity vector of the rock
 * @param vecRot		the rotation vector of the rock
 *
 * @noreturn
 */
forward void L4D_TankRock_OnRelease_Post(int tank, int rock, const float vecPos[3], const float vecAng[3], const float vecVel[3], const float vecRot[3]);

/**
 * @brief Called whenever CTankRock::BounceTouch is invoked
 * @remarks When a tank rock touches an entity to bounce
 *
 * @param tank			tank client index (can be -1 if the rock was created by the native "L4D_TankRockPrj" or the "env_rock_launcher" entity)
 * @param rock			the rock entity index
 * @param entity		the entity index it touched (can be 0 for world)
 *
 * @return				Plugin_Handled to prevent exploding/hitting(?) - this will cause the rock to float in position and call L4D_TankRock_BounceTouch over and over, manually teleport to bounce off an object, Plugin_Continue otherwise
 */
forward Action L4D_TankRock_BounceTouch(int tank, int rock, int entity);

/**
 * @brief Called whenever CTankRock::BounceTouch is invoked
 * @remarks When a tank rock touches an entity to bounce
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param tank			tank client index (can be -1 if the rock was created by the native "L4D_TankRockPrj" or the "env_rock_launcher" entity)
 * @param rock			the rock entity index
 * @param entity		the entity index it touched (can be 0 for world)
 *
 * @noreturn
 */
forward void L4D_TankRock_BounceTouch_Post(int tank, int rock, int entity);

/**
 * @brief Called whenever CTankRock::BounceTouch is invoked
 * @remarks When a tank rock touches an entity to bounce
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param tank			tank client index (can be -1 if the rock was created by the native "L4D_TankRockPrj" or the "env_rock_launcher" entity)
 * @param rock			the rock entity index
 * @param entity		the entity index it touched (can be 0 for world)
 *
 * @noreturn
 */
forward void L4D_TankRock_BounceTouch_PostHandled(int tank, int rock, int entity);

/**
 * @brief Called whenever CDirector::TryOfferingTankBot is invoked
 * @remarks Is used for displaying the "X gets Tank" window and transferring Tank control
 *
 * @param tank_index		Client index of the tank
 * @param enterStasis		Is the tank in stasis
 *
 * @return				Plugin_Handled to block window from showing and to keep Tank Bot, Plugin_Changed to use overwritten values from plugin, Plugin_Continue otherwise
 */
forward Action L4D_OnTryOfferingTankBot(int tank_index, bool &enterStasis);

/**
 * @brief Called whenever CDirector::TryOfferingTankBot is invoked
 * @remarks Is used for displaying the "X gets Tank" window and transferring Tank control
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param tank_index		Client index of the tank
 * @param enterStasis		Is the tank in stasis
 *
 * @noreturn
 */
forward void L4D_OnTryOfferingTankBot_Post(int tank_index, bool enterStasis);

/**
 * @brief Called whenever CDirector::TryOfferingTankBot is invoked
 * @remarks Is used for displaying the "X gets Tank" window and transferring Tank control
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param tank_index		Client index of the tank (can be -1 when blocked)
 * @param enterStasis		Is the tank in stasis
 *
 * @noreturn
 */
forward void L4D_OnTryOfferingTankBot_PostHandled(int tank_index, bool enterStasis);

/**
 * @brief Called whenever CThrow::ActivateAbility(void) is invoked
 * @remarks Called when a tank throws a rock. Blocking this call will keep the tank from throwing a rock
 *
 * @param ability	ability_throw entity index
 *
 * @return			Plugin_Handled to block, Plugin_Continue otherwise
 */
forward Action L4D_OnCThrowActivate(int ability);

/**
 * @brief Called whenever CThrow::ActivateAbility(void) is invoked
 * @remarks Called when a tank throws a rock. Blocking this call will keep the tank from throwing a rock
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param ability	ability_throw entity index
 *
 * @noreturn
 */
forward void L4D_OnCThrowActivate_Post(int ability);

/**
 * @brief Called whenever CThrow::ActivateAbility(void) is invoked
 * @remarks Called when a tank throws a rock. Blocking this call will keep the tank from throwing a rock
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param ability	ability_throw entity index
 *
 * @noreturn
 */
forward void L4D_OnCThrowActivate_PostHandled(int ability);

/**
 * @brief Called when CBaseAnimating::SelectWeightedSequence(int Activity) is invoked with tank attack activity
 * @remarks Called whenever a tank uses his primary (punch) or secondary (throw) attack (uses ACT_* activity numbers)
 *
 * This detour uses activity sequence numbers
 *
 * @param client	the client that is playing as tank
 * @param sequence	current selected activity for attack, option to override the return value with it
 *
 * L4D2:
 * ACT_HULK_THROW				761
 * ACT_TANK_OVERHEAD_THROW		762
 * ACT_HULK_ATTACK_LOW			763
 * ACT_TERROR_ATTACK_MOVING		790
 *
 * L4D1:
 * ACT_HULK_THROW				1254
 * ACT_TANK_OVERHEAD_THROW		1255
 * ACT_HULK_ATTACK_LOW			1256
 * ACT_TERROR_ATTACK_MOVING		1282
 *
 * @return			Plugin_Handled to override return value, Plugin_Continue otherwise
 */
forward Action L4D2_OnSelectTankAttackPre(int client, int &sequence);

/**
 * @brief Called when CBaseAnimating::SelectWeightedSequence(int Activity) is invoked with tank attack activity
 * @remarks Called whenever a tank uses his primary (punch) or secondary (throw) attack (uses m_nSequence animation numbers)
 *
 * This detour uses models m_nSequence numbers
 *
 * @param client	the client that is playing as tank
 * @param sequence	current selected activity for attack, option to override the return value with it
 *
 * @remarks	sequences, for L4D1:
 * @remarks	sequences(punches)	38 (uppercut), 41 (right hook), 43 (left hook), 44 and 45 (pounding the ground)
 * @remarks	sequences(throws)	46 (undercut), 47 (1handed overhand), 48 (throw from the hip), 49 (2handed overhand)
 *
 * @remarks	sequences, for L4D2:
 * @remarks	sequences(punches)	40 uppercut), 43 (right hook), 45 (left hook), 46 and 47 (pounding the ground)
 * @remarks	sequences(throws)	48 undercut), 49 (1handed overhand), 50 (throw from the hip), 51 (2handed overhand)
 *
 * @return			Plugin_Handled to override return value, Plugin_Continue otherwise
 */
forward Action L4D2_OnSelectTankAttack(int client, int &sequence);

/**
 * @brief Called whenever CTerrorMeleeWeapon::StartMeleeSwing(CTerrorPlayer *, bool) is invoked
 * @remarks Called when a player uses his melee weapons primary attack. This is before the game
 *			reads the melee weapon data (model etc) and decides if he CAN attack at all
 *
 * @return			Plugin_Handled to block, Plugin_Continue otherwise
 */
// L4D2 only
forward Action L4D_OnStartMeleeSwing(int client, bool boolean);

/**
 * @brief Called whenever CTerrorMeleeWeapon::StartMeleeSwing(CTerrorPlayer *, bool) is invoked
 * @remarks Called when a player uses his melee weapons primary attack. This is before the game
 *			reads the melee weapon data (model etc) and decides if he CAN attack at all
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @noreturn
 */
// L4D2 only
forward void L4D_OnStartMeleeSwing_Post(int client, bool boolean);

/**
 * @brief Called whenever CTerrorMeleeWeapon::StartMeleeSwing(CTerrorPlayer *, bool) is invoked
 * @remarks Called when a player uses his melee weapons primary attack. This is before the game
 *			reads the melee weapon data (model etc) and decides if he CAN attack at all
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @noreturn
 */
// L4D2 only
forward void L4D_OnStartMeleeSwing_PostHandled(int client, bool boolean);

/**
 * @brief Called whenever CTerrorMeleeWeapon::GetDamageForVictim() is invoked
 * @remarks Called to calculate the damage when a melee weapon hits something
 * @remarks A headshot on Common Infected will still kill them
 * @remarks Could maybe set the weapon attribute "L4D2BoolMeleeWeapon_Decapitates" to avoid killing on headshot. Please report success if you try
 *
 * @param client	the client swinging the melee weapon
 * @param weapon	the weapon entity index
 * @param victim	the victim being hit by the melee weapon
 * @param damage	the amount of damage to inflict on the victim
 *
 * @return			Plugin_Handled to block, Plugin_Changed to change damage, Plugin_Continue otherwise
 */
// L4D2 only
forward Action L4D2_MeleeGetDamageForVictim(int client, int weapon, int victim, float &damage);

/**
 * @brief Called whenever CTerrorPlayer::DoAnimationEvent is invoked
 * @note The event argument is NOT the same as the sequence numbers found in the model viewer
 * @note You can get the number for your animation by looking at the disasm for virtual calls to DoAnimationEvent
 *
 * @return			Plugin_Handled to block, Plugin_Changed to modify value, Plugin_Continue otherwise
 */
forward Action L4D_OnDoAnimationEvent(int client, int &event, int &variant_param);

/**
 * @brief Called whenever CTerrorPlayer::DoAnimationEvent is invoked
 * @note The event argument is NOT the same as the sequence numbers found in the model viewer
 * @note You can get the number for your animation by looking at the disasm for virtual calls to DoAnimationEvent
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @noreturn
 */
forward void L4D_OnDoAnimationEvent_Post(int client, int event, int variant_param);

/**
 * @brief Called whenever CTerrorPlayer::DoAnimationEvent is invoked
 * @note The event argument is NOT the same as the sequence numbers found in the model viewer
 * @note You can get the number for your animation by looking at the disasm for virtual calls to DoAnimationEvent
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @noreturn
 */
forward void L4D_OnDoAnimationEvent_PostHandled(int client, int event, int variant_param);

/**
 * @brief Called whenever CDirectorScriptedEventManager::SendInRescueVehicle(void) is invoked
 * @remarks Called when the last Finale stage is reached and the Rescue means becomes 'available'
 *			Take note this forward WILL fire upon using the native of the same function
 *
 * @return			Plugin_Handled to block, Plugin_Continue otherwise
 */
// 2020 Left4DHooks update: Blocked on L4D1/L4D2 Linux to prevent crashes. Waiting for DHooks update to support object returns
forward Action L4D2_OnSendInRescueVehicle();

/**
 * @brief Called whenever CDirectorScriptedEventManager::ChangeFinaleStage is invoked
 * @remarks Called when the director stage changes
 * @remarks some values for FinaleStageType: 1 - Finale Started; 6 - Rescue Vehicle Ready; 7 - Zombie Hordes; 8 - Tank; 10 - Combat Respite (nothing spawns)
 * @remarks SendInRescueVehicle does not depend on Finale Stage being 6, that only signals endless Hordes/Tanks
 * @remarks Can use the "FINALE_*" enums (search for them above) for the finaleType value
 *
 * @param FinaleStageType	integer value
 *
 * @return			Plugin_Handled to block, Plugin_Changed to change finaleType, Plugin_Continue otherwise
 */
// L4D2 only
forward Action L4D2_OnChangeFinaleStage(int &finaleType, const char[] arg);

/**
 * @brief Called whenever CDirectorScriptedEventManager::ChangeFinaleStage is invoked
 * @remarks Called when the director stage changes
 * @remarks some values for FinaleStageType: 1 - Finale Started; 6 - Rescue Vehicle Ready; 7 - Zombie Hordes; 8 - Tank; 10 - Combat Respite (nothing spawns)
 * @remarks SendInRescueVehicle does not depend on Finale Stage being 6, that only signals endless Hordes/Tanks
 * @remarks Can use the "FINALE_*" enums (search for them above) for the finaleType value
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param FinaleStageType	integer value
 *
 * @noreturn
 */
// L4D2 only
forward void L4D2_OnChangeFinaleStage_Post(int finaleType, const char[] arg);

/**
 * @brief Called whenever CDirectorScriptedEventManager::ChangeFinaleStage is invoked
 * @remarks Called when the director stage changes
 * @remarks some values for FinaleStageType: 1 - Finale Started; 6 - Rescue Vehicle Ready; 7 - Zombie Hordes; 8 - Tank; 10 - Combat Respite (nothing spawns)
 * @remarks SendInRescueVehicle does not depend on Finale Stage being 6, that only signals endless Hordes/Tanks
 * @remarks Can use the "FINALE_*" enums (search for them above) for the finaleType value
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param FinaleStageType	integer value
 *
 * @noreturn
 */
// L4D2 only
forward void L4D2_OnChangeFinaleStage_PostHandled(int finaleType, const char[] arg);

/**
 * @brief Called whenever CDirectorVersusMode::EndVersusModeRound(bool) is invoked
 * @remarks Called before score calculations and the scoreboard display
 *
 * @param countSurvivors	True if the survival multiplier count needs to be nonzero. I guess
 * @remarks Not sure what bool does exactly yet. Just monitor it. If true, survivors will be counted for multiplier. If false, survival multiplier will be set to 0
 * @remarks A lot of Score calculations happen on this function, and the round-end scoreboard comes up doing this. Don't block unless you're sure you can reproduce this logic
 *
 * @param countSurvivors		False = Survivors didn't make it to saferoom. True = Survivors made to the saferoom
 *
 * @return			Plugin_Handled to block, Plugin_Continue otherwise
 */
forward Action L4D2_OnEndVersusModeRound(bool countSurvivors);

/**
 * @brief Called after CDirectorVersusMode::EndVersusModeRound(bool)
 * @remarks Called after all score calculations are complete and the scoreboard shows
 * @remarks Called after all score calculations inside CDirectorVersusMode::EndVersusModeRound(bool). This good forward to replace standard "round_end" hook
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @noreturn
 */
forward void L4D2_OnEndVersusModeRound_Post();

/**
 * @brief Called after CDirectorVersusMode::EndVersusModeRound(bool)
 * @remarks Called after all score calculations are complete and the scoreboard shows
 * @remarks Called after all score calculations inside CDirectorVersusMode::EndVersusModeRound(bool). This good forward to replace standard "round_end" hook
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @noreturn
 */
forward void L4D2_OnEndVersusModeRound_PostHandled();


/**
 * @brief Called whenever CTerrorPlayer::OnLedgeGrabbed(CTerrorPlayer *this, const Vector *) is invoked
 * @remarks Called when a player is about to grab a ledge
 *
 * @param client	client grabbing the ledge
 *
 * @return			Plugin_Handled to prevent grabbing, Plugin_Continue otherwise
 */
forward Action L4D_OnLedgeGrabbed(int client);

/**
 * @brief Called whenever CTerrorPlayer::OnLedgeGrabbed(CTerrorPlayer *this, const Vector *) is invoked
 * @remarks Called when a player is about to grab a ledge
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param client	client grabbing the ledge
 *
 * @noreturn
 */
forward void L4D_OnLedgeGrabbed_Post(int client);

/**
 * @brief Called whenever CTerrorPlayer::OnLedgeGrabbed(CTerrorPlayer *this, const Vector *) is invoked
 * @remarks Called when a player is about to grab a ledge
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param client	client grabbing the ledge
 *
 * @noreturn
 */
forward void L4D_OnLedgeGrabbed_PostHandled(int client);

/**
 * @brief Called when CTerrorPlayer::OnRevived(void) is invoked
 * @remarks Called post-revive so all data values are post-revive status
 *
 * @param client	the client that has been revived
 *
 * @noreturn
 */
forward void L4D2_OnRevived(int client);

/**
 * @brief Called whenever CTerrorWeapon::OnSwingStart(CTerrorWeapon *this) is invoked
 * @remarks Called when a Survivor shoves
 * @remarks Blocking has no effect so this function is void only
 *
 * @param client	the client that did the shoving
 * @param weapon	the weapon being held when shoving
 *
 * @noreturn
 */
forward void L4D_OnSwingStart(int client, int weapon);

/**
 * @brief Called whenever CTerrorPlayer::OnShovedBySurvivor(CTerrorPlayer, Vector&) is invoked
 * @remarks L4D2 only uses this on Special Infected
 * @remarks Blocks hunter dead stop
 *
 * @param client	the client that did the shoving
 * @param victim	the client that was shoved (CAUTION retrieved from function pointer, don't meddle with it)
 * @param vecDir	Vector Angle of Shoveforce
 *
 * @return			Plugin_Handled to block melee effect (staggering), Plugin_Continue otherwise
 */
forward Action L4D_OnShovedBySurvivor(int client, int victim, const float vecDir[3]);

/**
 * @brief Called whenever CTerrorPlayer::OnShovedBySurvivor(CTerrorPlayer, Vector&) is invoked
 * @remarks L4D2 only uses this on Special Infected
 * @remarks Blocks hunter dead stop
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param client	the client that did the shoving
 * @param victim	the client that was shoved (CAUTION retrieved from function pointer, don't meddle with it)
 * @param vecDir	Vector Angle of Shoveforce
 *
 * @noreturn
 */
forward void L4D_OnShovedBySurvivor_Post(int client, int victim, const float vecDir[3]);

/**
 * @brief Called whenever CTerrorPlayer::OnShovedBySurvivor(CTerrorPlayer, Vector&) is invoked
 * @remarks L4D2 only uses this on Special Infected
 * @remarks Blocks hunter dead stop
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param client	the client that did the shoving
 * @param victim	the client that was shoved (CAUTION retrieved from function pointer, don't meddle with it)
 * @param vecDir	Vector Angle of Shoveforce
 *
 * @noreturn
 */
forward void L4D_OnShovedBySurvivor_PostHandled(int client, int victim, const float vecDir[3]);

/**
 * @brief Called whenever CTerrorWeapon::OnHit(CGameTrace &, Vector const&, bool) is invoked
 * @remarks Called for every single shovable and even some of the unshovable entities in the game
 *
 * @param client	survivor who did the shoving
 * @param entity	entity that is about to get shoved
 * @param weapon	weapon that has been held while shoving
 * @param vecDir	stagger direction
 * @param bIsHighPounce		a boolean to determine if it was a pounce from a height or not; reliable to a certain degree and should only be considered for hunters
 * @param bIsHighPounce		sometimes reset to 0 when punched before the detour retrieves the information
 *
 * @return			Plugin_Handled to block, Plugin_Continue otherwise
 */
forward Action L4D2_OnEntityShoved(int client, int entity, int weapon, float vecDir[3], bool bIsHighPounce);

/**
 * @brief Called whenever CTerrorWeapon::OnHit(CGameTrace &, Vector const&, bool) is invoked
 * @remarks Called for every single shovable and even some of the unshovable entities in the game
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param client	survivor who did the shoving
 * @param entity	entity that is about to get shoved
 * @param weapon	weapon that has been held while shoving
 * @param vecDir	stagger direction
 * @param bIsHighPounce		a boolean to determine if it was a pounce from a height or not; reliable to a certain degree and should only be considered for hunters
 * @param bIsHighPounce		sometimes reset to 0 when punched before the detour retrieves the information
 *
 * @noreturn
 */
forward void L4D2_OnEntityShoved_Post(int client, int entity, int weapon, const float vecDir[3], bool bIsHighPounce);

/**
 * @brief Called whenever CTerrorWeapon::OnHit(CGameTrace &, Vector const&, bool) is invoked
 * @remarks Called for every single shovable and even some of the unshovable entities in the game
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param client	survivor who did the shoving
 * @param entity	entity that is about to get shoved
 * @param weapon	weapon that has been held while shoving
 * @param vecDir	stagger direction
 * @param bIsHighPounce		a boolean to determine if it was a pounce from a height or not; reliable to a certain degree and should only be considered for hunters
 * @param bIsHighPounce		sometimes reset to 0 when punched before the detour retrieves the information
 *
 * @noreturn
 */
forward void L4D2_OnEntityShoved_PostHandled(int client, int entity, int weapon, const float vecDir[3], bool bIsHighPounce);

/**
 * @brief Called whenever CTerrorPlayer::OnStaggered(CBaseEntity *, Vector const *) is invoked
 * @remarks Source is always null for Charger impacts (Valve)
 *
 * @param client	the client that is about to get staggered
 * @param source	the client that is about to stagger the client
 *
 * @return			Plugin_Handled to block, Plugin_Continue otherwise
 */
forward Action L4D2_OnStagger(int client, int source);

/**
 * @brief Called whenever CTerrorPlayer::OnStaggered(CBaseEntity *, Vector const *) is invoked
 * @remarks Source is always null for Charger impacts (Valve)
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param client	the client that is about to get staggered
 * @param source	the client that is about to stagger the client
 *
 * @noreturn
 */
forward void L4D2_OnStagger_Post(int client, int source);

/**
 * @brief Called whenever CTerrorPlayer::OnStaggered(CBaseEntity *, Vector const *) is invoked
 * @remarks Source is always null for Charger impacts (Valve)
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param client	the client that is about to get staggered
 * @param source	the client that is about to stagger the client
 *
 * @noreturn
 */
forward void L4D2_OnStagger_PostHandled(int client, int source);

/**
 * @brief Called when CTerrorPlayer::CancelStagger() is invoked
 * @remarks Called when a players staggering is about to be cancelled
 *
 * @param client		Client index of the player
 *
 * @return				Plugin_Handled to allow staggering to continue, Plugin_Continue to allow
 **/
forward Action L4D_OnCancelStagger(int client);

/**
 * @brief Called when CTerrorPlayer::CancelStagger() is invoked
 * @remarks Called when a players staggering is being cancelled
 * @remarks This will not trigger if the cancel is being blocked by other plugins
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param client		Client index of the player
 *
 * @return				Plugin_Handled to allow staggering to continue, Plugin_Continue to allow
 **/
forward void L4D_OnCancelStagger_Post(int client);

/**
 * @brief Called when CTerrorPlayer::CancelStagger() is invoked
 * @remarks Called when a players staggering has not been cancelled
 * @remarks This will trigger if the cancel is being blocked by other plugins
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param client		Client index of the player
 *
 * @return				Plugin_Handled to allow staggering to continue, Plugin_Continue to allow
 **/
forward void L4D_OnCancelStagger_PostHandled(int client);

/**
 * @brief Called when CTerrorPlayer::Fling(Vector const&, PlayerAnimEvent_t, CBaseCombatCharacter*, float) is invoked
 * @remarks Called when a player is flung to the ground
 *
 * @param client		Client index of the player
 * @param attacker		Client index of the attacker
 * @param vecDir		Vector direction of the fling
 *
 * @return				Plugin_Handled to block fling, Plugin_Continue to allow
 **/
// L4D2 only
forward Action L4D2_OnPlayerFling(int client, int attacker, float vecDir[3]);

/**
 * @brief Called when CTerrorPlayer::Fling(Vector const&, PlayerAnimEvent_t, CBaseCombatCharacter*, float) is invoked
 * @remarks Called when a player is flung to the ground
 * @remarks This will not trigger if the fling is being blocked by other plugins
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param client		Client index of the player
 * @param attacker		Client index of the attacker
 * @param vecDir		Vector direction of the fling
 *
 * @noreturn
 **/
// L4D2 only
forward void L4D2_OnPlayerFling_Post(int client, int attacker, const float vecDir[3]);

/**
 * @brief Called when CTerrorPlayer::Fling(Vector const&, PlayerAnimEvent_t, CBaseCombatCharacter*, float) is invoked
 * @remarks Called when a player is flung to the ground
 * @remarks This will trigger if the fling is being blocked by other plugins
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param client		Client index of the player
 * @param attacker		Client index of the attacker
 * @param vecDir		Vector direction of the fling
 *
 * @noreturn
 **/
// L4D2 only
forward void L4D2_OnPlayerFling_PostHandled(int client, int attacker, const float vecDir[3]);

/**
 * @brief Called when CTerrorPlayer::IsMotionControlledXY is invoked
 * @remarks Called when a player is staggering or a Hunter has been knocked off someone
 * @remarks Blocking this will allow the player to fall with gravity instead of floating in the air
 *
 * @param client		Client index of the player
 * @param activity		The activity sequence playing that has a fixed set of motions
 *
 * @return				Plugin_Handled to block, Plugin_Continue otherwise
 **/
forward Action L4D_OnMotionControlledXY(int client, int activity);

/**
 * @brief Called whenever CTerrorPlayer::OnShovedByPounceLanding(CTerrorPlayer*) is invoked
 *
 * @param victim	the survivor that is about to get stumbled as a result of "attacker" capping someone in close proximity
 * @param attacker	the SI that is about to cause a stumble as a result of capping someone in close proximity to a survivor
 *
 * @return			Plugin_Handled to block, Plugin_Continue otherwise
 */
forward Action L4D2_OnPounceOrLeapStumble(int victim, int attacker);

/**
 * @brief Called whenever CTerrorPlayer::OnShovedByPounceLanding(CTerrorPlayer*) is invoked
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param victim	the survivor that is about to get stumbled as a result of "attacker" capping someone in close proximity
 * @param attacker	the SI that is about to cause a stumble as a result of capping someone in close proximity to a survivor
 *
 * @noreturn
 */
forward void L4D2_OnPounceOrLeapStumble_Post(int victim, int attacker);

/**
 * @brief Called whenever CTerrorPlayer::OnShovedByPounceLanding(CTerrorPlayer*) is invoked
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param victim	the survivor that is about to get stumbled as a result of "attacker" capping someone in close proximity
 * @param attacker	the SI that is about to cause a stumble as a result of capping someone in close proximity to a survivor
 *
 * @noreturn
 */
forward void L4D2_OnPounceOrLeapStumble_PostHandled(int victim, int attacker);

/**
 * @brief Called when CTerrorPlayer::OnKnockedDown(CTerrorPlayer*) is invoked
 * @remarks Called when someone is about to be hit by a Tank rock or lunged by a Hunter
 * @remarks You can use the "KNOCKDOWN_*" enum values for the reason
 * @remarks Called multiple times when someone is about to be pounced by a Hunter
 *
 * @param victim		Client index of the victim
 * @param reason		The Knockdown reason type. 1=Hunter lunge, 2=Tank rock, 3=Charger impact
 *
 * @return				Plugin_Handled to block fling, Plugin_Continue to allow
 **/
forward Action L4D_OnKnockedDown(int client, int reason);

/**
 * @brief Called when CTerrorPlayer::OnKnockedDown(CTerrorPlayer*) is invoked
 * @remarks Called when someone is about to be hit by a Tank rock or lunged by a Hunter
 * @remarks Called multiple times when someone is about to be pounced by a Hunter
 * @remarks You can use the "KNOCKDOWN_*" enum values for the reason
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param victim		Client index of the victim
 * @param reason		The Knockdown reason type. 1=Hunter lunge, 2=Tank rock, 3=Charger impact
 *
 * @noreturn
 **/
forward void L4D_OnKnockedDown_Post(int client, int reason);

/**
 * @brief Called when CTerrorPlayer::OnKnockedDown(CTerrorPlayer*) is invoked
 * @remarks Called when someone is about to be hit by a Tank rock or lunged by a Hunter
 * @remarks Called multiple times when someone is about to be pounced by a Hunter
 * @remarks You can use the "KNOCKDOWN_*" enum values for the reason
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param victim		Client index of the victim
 * @param reason		The Knockdown reason type. 1=Hunter lunge, 2=Tank rock, 3=Charger impact
 *
 * @noreturn
 **/
forward void L4D_OnKnockedDown_PostHandled(int client, int reason);

/**
 * @brief Called when ThrowImpactedSurvivor(CTerrorPlayer *, CTerrorPlayer *, float, bool) is invoked
 * @remarks Called when a player is about to be flung by a Charger impact
 *
 * @param attacker		Client index of the attacker
 * @param victim		Client index of the victim
 *
 * @return				Plugin_Handled to block fling, Plugin_Continue to allow
 **/
// L4D2 only
forward Action L4D2_OnThrowImpactedSurvivor(int attacker, int victim);

/**
 * @brief Called when ThrowImpactedSurvivor(CTerrorPlayer *, CTerrorPlayer *, float, bool) is invoked
 * @remarks Called when a player is flung by a Charger impact
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param attacker		Client index of the attacker
 * @param victim		Client index of the victim
 *
 * @noreturn
 **/
// L4D2 only
forward void L4D2_OnThrowImpactedSurvivor_Post(int attacker, int victim);

/**
 * @brief Called when ThrowImpactedSurvivor(CTerrorPlayer *, CTerrorPlayer *, float, bool) is invoked
 * @remarks Called when a player is flung by a Charger impact
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param attacker		Client index of the attacker
 * @param victim		Client index of the victim
 *
 * @noreturn
 **/
// L4D2 only
forward void L4D2_OnThrowImpactedSurvivor_PostHandled(int attacker, int victim);

/**
 * @brief Called when CDeathFallCamera::Enable(CBasePlayer*) is invoked
 * @remarks Called when a player is falling in a fatal zone
 * @remarks Does not trigger for all cases when someone is fatally falling
 * @remarks Use this forward to check if the current map has death fall cameras (fatal falls)
 *
 * @param client		Client index of the player. Can be 0
 * @param camera		Death fall camera index
 *
 * @return				Plugin_Handled to block the death fall camera, Plugin_Continue to allow
 **/
forward Action L4D_OnFatalFalling(int client, int camera);

/**
 * @brief Called when CTerrorPlayer::OnFalling() is invoked
 * @remarks Called when a player is falling
 *
 * @param client		Client index of the player
 **/
forward void L4D_OnFalling(int client);

/**
 * @brief Called when CTerrorPlayer::Cough() is invoked
 * @remarks Called when a player is coughing, most likely from Smoker Cloud, but possibly called by other plugins
 *
 * @param client		Client index of the player affected
 * @param attacker		Client index who caused the cough, can be 0 after a while when the AI special infected is kicked
 *
 * @return				return Plugin_Handled to block, Plugin_Continue otherwise
 **/
forward Action L4D_OnPlayerCough(int client, int attacker);

/**
 * @brief Called when CTerrorPlayer::Cough() is invoked
 * @remarks Called when a player is coughing, most likely from Smoker Cloud, but possibly called by other plugins
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param client		Client index of the player affected
 * @param attacker		Client index who caused the cough, can be 0 after a while when the AI special infected is kicked
 *
 * @noreturn
 **/
forward void L4D_OnPlayerCough_Post(int client, int attacker);

/**
 * @brief Called when CTerrorPlayer::Cough() is invoked
 * @remarks Called when a player is coughing, most likely from Smoker Cloud, but possibly called by other plugins
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param client		Client index of the player affected
 * @param attacker		Client index who caused the cough, can be 0 after a while when the AI special infected is kicked
 *
 * @noreturn
 **/
forward void L4D_OnPlayerCough_PostHandled(int client, int attacker);

/**
 * @brief Called when CTerrorPlayer::OnIncapacitatedAsSurvivor() is invoked
 * @remarks Called when a player is about to be incapacitated
 *
 * @param client		Client index of the player affected
 * @param inflictor		The inflictor entity index
 * @param attacker		The attacker entity index
 * @param damage		Amount of damage being caused
 * @param damagetype	Type of damage being caused
 *
 * @return				return Plugin_Handled to block, Plugin_Changed to modify values, Plugin_Continue otherwise
 **/
forward Action L4D_OnIncapacitated(int client, int &inflictor, int &attacker, float &damage, int &damagetype);

/**
 * @brief Called when CTerrorPlayer::OnIncapacitatedAsSurvivor() is invoked
 * @remarks Called when a player is about to be incapacitated
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param client		Client index of the player affected
 * @param inflictor		The inflictor entity index
 * @param attacker		The attacker entity index
 * @param damage		Amount of damage being caused
 * @param damagetype	Type of damage being caused
 *
 * @noreturn
 **/
forward void L4D_OnIncapacitated_Post(int client, int inflictor, int attacker, float damage, int damagetype);

/**
 * @brief Called when CTerrorPlayer::OnIncapacitatedAsSurvivor() is invoked
 * @remarks Called when a player is about to be incapacitated
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param client		Client index of the player affected
 * @param inflictor		The inflictor entity index
 * @param attacker		The attacker entity index
 * @param damage		Amount of damage being caused
 * @param damagetype	Type of damage being caused
 *
 * @noreturn
 **/
forward void L4D_OnIncapacitated_PostHandled(int client, int inflictor, int attacker, float damage, int damagetype);

/**
 * @brief Called when CTerrorPlayer::DropWeapons() is invoked
 * @remarks Called when a player dies, listing their currently held weapons and objects that are being dropped
 * @remarks Array index is as follows:
 * @remarks [0] = L4DWeaponSlot_Primary
 * @remarks [1] = L4DWeaponSlot_Secondary
 * @remarks [2] = L4DWeaponSlot_Grenade
 * @remarks [3] = L4DWeaponSlot_FirstAid
 * @remarks [4] = L4DWeaponSlot_Pills
 * @remarks [5] = Held item (e.g. weapon_gascan, weapon_gnome etc)
 *
 * @param client		Client index of the player who died
 * @param weapons		Array of weapons dropped, valid entity index or -1 if empty
 *
 * @noreturn
 **/
forward void L4D_OnDeathDroppedWeapons(int client, int weapons[6]);

/**
 * @brief Called whenever CInferno::Spread(Vector const&) is invoked (only for spitters -- ignores fire)
 *
 * @param spitter	 	spitter that spat (:D)
 * @param projectile	spitter's projectile entity
 * @param x				x coordinate of the new acid puddle (can be overridden)
 * @param y				y coordinate of the new acid puddle (can be overridden)
 * @param z				z coordinate of the new acid puddle (can be overridden)
 *
 * @return			Plugin_Handled to block, Plugin_Continue otherwise
 */
// 2020 Left4DHooks update: Works for Molotovs and Spitters
// return Plugin_Handled to make small fire or goo puddle
// x,y,z has no affect, is 0,0,0 for spitter, molotovs is area size or something
forward Action L4D2_OnSpitSpread(int spitter, int projectile, float &x, float &y, float &z);

/**
 * @brief Called whenever CTerrorPlayer::Extinguish() is invoked
 * @remarks Called when a player (Survivor or Special Infected) is about to be extinguished
 *
 * @param client			the client who is about to be extinguished
 *
 * @return					Plugin_Handled to block extinguishing, Plugin_Continue otherwise
 */
forward Action L4D_PlayerExtinguish(int client);

/**
 * @brief Called when SurvivorBot::UseHealingItems(Action<SurvivorBot> *) is invoked
 * @remarks Causes bots to use or give healing items (except in safe room on non-expert)
 *
 * @param client	the client that will decide whether to use healing items
 *
 * @return			Plugin_Handled to block, Plugin_Continue otherwise
 */
// 2020 Left4DHooks update: Blocked on L4D1/L4D2 Linux to prevent crashes. Waiting for DHooks update to support object returns
forward Action L4D2_OnUseHealingItems(int client);

/**
 * @brief Called after SurvivorBot::FindScavengeItem(Action<SurvivorBot> *) is invoked
 * @remarks Indicates which item the Survivor Bot will attempt to pick up
 *
 * @param client	the client that will try to pick something up
 * @param item		the item the client will try to pick up (null means no item)
 *
 * @return			Plugin_Handled to block, Plugin_Changed to overwrite item, Plugin_Continue otherwise
 */
forward Action L4D2_OnFindScavengeItem(int client, int &item);

/**
 * @brief Called whenever BossZombiePlayer(CTerrorPlayer *, int, CBaseEntity *) is invoked
 * @remarks Called when Special Infected are targeting a victim
 *
 * @param specialInfected	the SI entity index
 * @param curTarget			the survivor player index who is chosen victim
 *
 * @return					Plugin_Handled to block, Plugin_Changed to use overwritten values from plugin, Plugin_Continue otherwise
 */
forward Action L4D2_OnChooseVictim(int specialInfected, int &curTarget);

/**
 * @brief Called whenever CTerrorPlayer::OnPouncedOnSurvivor() is invoked
 * @remarks Called when a Survivor player is about to be pounced on by a Hunter
 *
 * @param victim			the client who's being pounced
 * @param attacker			the Hunter pouncing on someone
 *
 * @return					Plugin_Handled to block, Plugin_Continue otherwise
 */
forward Action L4D_OnPouncedOnSurvivor(int victim, int attacker);

/**
 * @brief Called whenever CTerrorPlayer::OnPouncedOnSurvivor() is invoked
 * @remarks Called when a Survivor player is about to be pounced on by a Hunter
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param victim			the client who's being pounced
 * @param attacker			the Hunter pouncing on someone
 *
 * @noreturn
 */
forward void L4D_OnPouncedOnSurvivor_Post(int victim, int attacker);

/**
 * @brief Called whenever CTerrorPlayer::OnPouncedOnSurvivor() is invoked
 * @remarks Called when a Survivor player is about to be pounced on by a Hunter
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param victim			the client who's being pounced
 * @param attacker			the Hunter pouncing on someone
 *
 * @noreturn
 */
forward void L4D_OnPouncedOnSurvivor_PostHandled(int victim, int attacker);

/**
 * @brief Called whenever CTerrorPlayer::GrabVictimWithTongue() is invoked
 * @remarks Called when a Survivor player is about to be grabbed by a Smoker
 *
 * @param victim			the client who's being grabbed
 * @param attacker			the Smoker grabbing someone
 *
 * @return					Plugin_Handled to block, Plugin_Continue otherwise
 */
forward Action L4D_OnGrabWithTongue(int victim, int attacker);

/**
 * @brief Called whenever CTerrorPlayer::GrabVictimWithTongue() is invoked
 * @remarks Called when a Survivor player is grabbed by a Smoker
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param victim			the client who's being grabbed
 * @param attacker			the Smoker grabbing someone
 *
 * @noreturn
 */
forward void L4D_OnGrabWithTongue_Post(int victim, int attacker);

/**
 * @brief Called whenever CTerrorPlayer::GrabVictimWithTongue() is invoked
 * @remarks Called when a Survivor player is grabbed by a Smoker
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param victim			the client who's being grabbed
 * @param attacker			the Smoker grabbing someone
 *
 * @noreturn
 */
forward void L4D_OnGrabWithTongue_PostHandled(int victim, int attacker);

/**
 * @brief Called whenever CTerrorPlayer::OnLeptOnSurvivor() is invoked
 * @remarks Called when a Survivor player is about to be ridden by a Jockey
 *
 * @param victim			the client who's being grabbed
 * @param attacker			the Jockey grabbing someone
 *
 * @return					Plugin_Handled to block, Plugin_Continue otherwise
 */
// L4D2 only
forward Action L4D2_OnJockeyRide(int victim, int attacker);

/**
 * @brief Called whenever CTerrorPlayer::OnLeptOnSurvivor() is invoked
 * @remarks Called when a Survivor player is starting to be ridden by a Jockey
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param victim			the client who's being grabbed
 * @param attacker			the Jockey grabbing someone
 *
 * @noreturn
 */
// L4D2 only
forward void L4D2_OnJockeyRide_Post(int victim, int attacker);

/**
 * @brief Called whenever CTerrorPlayer::OnLeptOnSurvivor() is invoked
 * @remarks Called when a Survivor player is starting to be ridden by a Jockey
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param victim			the client who's being grabbed
 * @param attacker			the Jockey grabbing someone
 *
 * @noreturn
 */
// L4D2 only
forward void L4D2_OnJockeyRide_PostHandled(int victim, int attacker);

/**
 * @brief Called whenever CTerrorPlayer::OnSlammedSurvivor() is invoked
 * @remarks Called when a Survivor is slammed into a wall by a Charger, or on the first pummel if bWallSlam is 0
 * @remarks bDeadlyCharge seems to always return 1 on Windows
 *
 * @param victim			the client who's being slammed
 * @param attacker			the Charger slamming someone
 * @param bWallSlam			when slammed into a wall. Changing this can play a different animation
 * @param bDeadlyCharge		indicates the carry ends at a height down 360.0 units from the carry start, and adds DMG_PARALYZE to the damage flags to incap the victim. Changing this can incap the victim
 *
 * @return					Plugin_Handled to block, Plugin_Changed to use overwritten values from plugin, Plugin_Continue otherwise
 */
// L4D2 only
forward Action L4D2_OnSlammedSurvivor(int victim, int attacker, bool &bWallSlam, bool &bDeadlyCharge);

/**
 * @brief Called whenever CTerrorPlayer::OnSlammedSurvivor() is invoked
 * @remarks Called when a Survivor is slammed into a wall by a Charger, or on the first pummel if bWallSlam is 0
 * @bDeadlyCharge seems to always return 1 on Windows
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param victim			the client who's being slammed
 * @param attacker			the Charger slamming someone
 * @param bWallSlam			when slammed into a wall. Changing this can play a different animation
 * @param bDeadlyCharge		indicates the carry ends at a height down 360.0 units from the carry start, and adds DMG_PARALYZE to the damage flags to incap the victim. Changing this can incap the victim
 *
 * @noreturn
 */
// L4D2 only
forward void L4D2_OnSlammedSurvivor_Post(int victim, int attacker, bool bWallSlam, bool bDeadlyCharge);

/**
 * @brief Called whenever CTerrorPlayer::OnSlammedSurvivor() is invoked
 * @remarks Called when a Survivor is slammed into a wall by a Charger, or on the first pummel if bWallSlam is 0
 * @bDeadlyCharge seems to always return 1 on Windows
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param victim			the client who's being slammed
 * @param attacker			the Charger slamming someone
 * @param bWallSlam			when slammed into a wall. Changing this can play a different animation
 * @param bDeadlyCharge		indicates the carry ends at a height down 360.0 units from the carry start, and adds DMG_PARALYZE to the damage flags to incap the victim. Changing this can incap the victim
 *
 * @noreturn
 */
// L4D2 only
forward void L4D2_OnSlammedSurvivor_PostHandled(int victim, int attacker, bool bWallSlam, bool bDeadlyCharge);

/**
 * @brief Called whenever CTerrorPlayer::OnStartCarryingVictim() is invoked
 * @remarks Called when a Survivor player is about to be carried by a Charger
 *
 * @param victim			the client who's being grabbed
 * @param attacker			the Charger picking up someone
 *
 * @return					Plugin_Handled to block, Plugin_Continue otherwise
 */
// L4D2 only
forward Action L4D2_OnStartCarryingVictim(int victim, int attacker);

/**
 * @brief Called whenever CTerrorPlayer::OnStartCarryingVictim() is invoked
 * @remarks Called when a Survivor player is about to be carried by a Charger
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param victim			the client who's being grabbed
 * @param attacker			the Charger picking up someone
 *
 * @noreturn
 */
// L4D2 only
forward void L4D2_OnStartCarryingVictim_Post(int victim, int attacker);

/**
 * @brief Called whenever CTerrorPlayer::OnStartCarryingVictim() is invoked
 * @remarks Called when a Survivor player is about to be carried by a Charger
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param victim			the client who's being grabbed
 * @param attacker			the Charger picking up someone
 *
 * @noreturn
 */
// L4D2 only
forward void L4D2_OnStartCarryingVictim_PostHandled(int victim, int attacker);

/**
 * @brief Called when CCharge::ImpactStagger is invoked
 * @remarks Called when a Charger impacts a wall or object after charging, but not when carrying a Survivor
 * @remarks Can be used to determine if someone is being staggered from this impact, L4D2_OnStagger should trigger in the same frame
 *
 * @param client		Client index
 *
 * @noreturn
 **/
// L4D2 only
forward void L4D2_OnChargerImpact(int client);

/**
 * @brief Called when CTerrorPlayer::QueuePummelVictim is invoked
 * @remarks Called when a player is about to be pummelled by a Charger
 * @remarks To block the stumble animation and getting stuck inside a Charger see the "L4D2_OnPummelVictim" section for a demonstration in "left4dhooks_test.sp"
 * @remarks Note: when blocking pummel the Survivor will be stuck inside the Charger (eventually teleporting them) and AI chargers cannot move. See the above demo for a solution
 *
 * @param attacker		Client index of the attacker
 * @param victim		Client index of the victim
 *
 * @return				Plugin_Handled to block pummel, Plugin_Continue to allow
 **/
// L4D2 only
forward Action L4D2_OnPummelVictim(int attacker, int victim);

/**
 * @brief Called when CTerrorPlayer::QueuePummelVictim is invoked
 * @remarks Called when a player is about to be pummelled by a Charger
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param attacker		Client index of the attacker
 * @param victim		Client index of the victim
 *
 * @noreturn
 **/
// L4D2 only
forward void L4D2_OnPummelVictim_Post(int attacker, int victim);

/**
 * @brief Called when CTerrorPlayer::QueuePummelVictim is invoked
 * @remarks Called when a player is about to be pummelled by a Charger
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param attacker		Client index of the attacker
 * @param victim		Client index of the victim
 *
 * @noreturn
 **/
// L4D2 only
forward void L4D2_OnPummelVictim_PostHandled(int attacker, int victim);

/**
 * @brief Called whenever CTerrorPlayer::OnVomitedUpon is invoked
 * @remarks Called when a Survivor player is covered in Boomer bile, or when using "Bile the World" plugin by "AtomicStryker"
 *
 * @param victim			the client who's now it
 * @param attacker			the attacker who caused the vomit (can be 0)
 * @param boomerExplosion	true if triggered by a boommer explosion
 *
 * @return					Plugin_Handled to block, Plugin_Changed to use overwritten values from plugin, Plugin_Continue otherwise
 */
forward Action L4D_OnVomitedUpon(int victim, int &attacker, bool &boomerExplosion);

/**
 * @brief Called whenever CTerrorPlayer::OnVomitedUpon is invoked
 * @remarks Called when a Survivor player is covered in Boomer bile, or when using "Bile the World" plugin by "AtomicStryker"
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param victim			the client who's now it
 * @param attacker			the attacker who caused the vomit (can be 0)
 * @param boomerExplosion	true if triggered by a boommer explosion
 *
 * @noreturn
 */
forward void L4D_OnVomitedUpon_Post(int victim, int attacker, bool boomerExplosion);

/**
 * @brief Called whenever CTerrorPlayer::OnVomitedUpon is invoked
 * @remarks Called when a Survivor player is covered in Boomer bile, or when using "Bile the World" plugin by "AtomicStryker"
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param victim			the client who's now it
 * @param attacker			the attacker who caused the vomit (can be 0)
 * @param boomerExplosion	true if triggered by a boommer explosion
 *
 * @noreturn
 */
forward void L4D_OnVomitedUpon_PostHandled(int victim, int attacker, bool boomerExplosion);

/**
 * @brief Called whenever CTerrorPlayer::OnHitByVomitJar is invoked
 * @remarks Called when a Special Infected is about to be hit from a Bilejar explosion
 *
 * @param victim			the client who's now it
 * @param attacker			the attacker who caused the vomit (can be 0)
 *
 * @return					Plugin_Handled to block, Plugin_Changed to use overwritten values from plugin, Plugin_Continue otherwise
 */
forward Action L4D2_OnHitByVomitJar(int victim, int &attacker);

/**
 * @brief Called whenever CTerrorPlayer::OnHitByVomitJar is invoked
 * @remarks Called when a Special Infected is hit from a Bilejar explosion
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param victim			the client who's now it
 * @param attacker			the attacker who caused the vomit (can be 0)
 *
 * @noreturn
 */
forward void L4D2_OnHitByVomitJar_Post(int victim, int attacker);

/**
 * @brief Called whenever CTerrorPlayer::OnHitByVomitJar is invoked
 * @remarks Called when a Special Infected is hit from a Bilejar explosion
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param victim			the client who's now it
 * @param attacker			the attacker who caused the vomit (can be 0)
 *
 * @noreturn
 */
forward void L4D2_OnHitByVomitJar_PostHandled(int victim, int attacker);

/**
 * @brief Called whenever Infected::OnHitByVomitJar is invoked
 * @remarks Called when a common infected or Witch is about to be hit from a Bilejar explosion and possibly boomer explosion
 *
 * @param victim			the common who's now it
 * @param attacker			the attacker who caused the vomit (can be 0)
 *
 * @return					Plugin_Handled to block, Plugin_Changed to use overwritten values from plugin, Plugin_Continue otherwise
 */
forward Action L4D2_Infected_HitByVomitJar(int victim, int &attacker);

/**
 * @brief Called whenever Infected::OnHitByVomitJar is invoked
 * @remarks Called when a common infected or Witch is hit from a Bilejar explosion and possibly boomer explosion
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param victim			the common who's now it
 * @param attacker			the attacker who caused the vomit (can be 0)
 *
 * @noreturn
 */
forward void L4D2_Infected_HitByVomitJar_Post(int victim, int attacker);

/**
 * @brief Called whenever Infected::OnHitByVomitJar is invoked
 * @remarks Called when a common infected or Witch is hit from a Bilejar explosion and possibly boomer explosion
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param victim			the common who's now it
 * @param attacker			the attacker who caused the vomit (can be 0)
 *
 * @noreturn
 */
forward void L4D2_Infected_HitByVomitJar_PostHandled(int victim, int attacker);

/**
 * @brief Called whenever CPipeBombProjectile::Create is invoked
 * @remarks Called when a PipeBomb projectile is being created
 *
 * @param client			the client who is throwing the grenade (can be 0)
 * @param vecPos			the position vector of the projectile
 * @param vecAng			the angle vector of the projectile
 * @param vecVel			the velocity vector of the projectile
 * @param vecRot			the rotation vector of the projectile
 *
 * @return					Plugin_Handled to block the grenade creation, Plugin_Changed to modify the vector values, Plugin_Continue otherwise
 */
forward Action L4D_PipeBombProjectile_Pre(int client, float vecPos[3], float vecAng[3], float vecVel[3], float vecRot[3]);

/**
 * @brief Called whenever CPipeBombProjectile::Create is invoked
 * @remarks Called when a PipeBomb projectile has been created
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param client			the client who is throwing the grenade
 * @param projectile		the projectile entity index (can be 0 if blocked in the pre hook)
 * @param vecPos			the position vector of the projectile
 * @param vecAng			the angle vector of the projectile
 * @param vecVel			the velocity vector of the projectile
 * @param vecRot			the rotation vector of the projectile
 *
 * @noreturn
 */
forward void L4D_PipeBombProjectile_Post(int client, int projectile, const float vecPos[3], const float vecAng[3], const float vecVel[3], const float vecRot[3]);

/**
 * @brief Called whenever CPipeBombProjectile::Create is invoked
 * @remarks Called when a PipeBomb projectile has been created
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param client			the client who is throwing the grenade (can be -1 if blocked)
 * @param projectile		the projectile entity index (can be 0 if blocked in the pre hook)
 * @param vecPos			the position vector of the projectile
 * @param vecAng			the angle vector of the projectile
 * @param vecVel			the velocity vector of the projectile
 * @param vecRot			the rotation vector of the projectile
 *
 * @noreturn
 */
forward void L4D_PipeBombProjectile_PostHandled(int client, int projectile, const float vecPos[3], const float vecAng[3], const float vecVel[3], const float vecRot[3]);

/**
 * @brief Called whenever CMolotovProjectile::Detonate is invoked
 * @remarks Called when a Molotov projectile is about to explode
 *
 * @param entity			the entity that exploded
 * @param client			the client who threw the grenade, can be -1
 *
 * @return					Plugin_Handled to block explosion which will cause the Molotov projectile to bounce remain active, Plugin_Continue otherwise
 */
forward Action L4D_Molotov_Detonate(int entity, int client);

/**
 * @brief Called whenever CMolotovProjectile::Detonate is invoked
 * @remarks Called when a Molotov projectile is about to explode
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param entity			the entity that exploded
 * @param client			the client who threw the grenade, can be -1
 *
 * @noreturn
 */
forward void L4D_Molotov_Detonate_Post(int entity, int client);

/**
 * @brief Called whenever CMolotovProjectile::Detonate is invoked
 * @remarks Called when a Molotov projectile is about to explode
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param entity			the entity that exploded
 * @param client			the client who threw the grenade, can be -1
 *
 * @noreturn
 */
forward void L4D_Molotov_Detonate_PostHandled(int entity, int client);

/**
 * @brief Called whenever CPipeBombProjectile::Detonate is invoked
 * @remarks Called when a PipeBomb projectile is about to explode
 *
 * @param entity			the entity that exploded
 * @param client			the client who threw the grenade, can be -1
 *
 * @return					Plugin_Handled to block explosion which will cause the PipeBomb projectile to continue flashing and remain active, Plugin_Continue otherwise
 */
forward Action L4D_PipeBomb_Detonate(int entity, int client);

/**
 * @brief Called whenever CPipeBombProjectile::Detonate is invoked
 * @remarks Called when a PipeBomb projectile is about to explode
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param entity			the entity that exploded
 * @param client			the client who threw the grenade, can be -1
 *
 * @noreturn
 */
forward void L4D_PipeBomb_Detonate_Post(int entity, int client);

/**
 * @brief Called whenever CPipeBombProjectile::Detonate is invoked
 * @remarks Called when a PipeBomb projectile is about to explode
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param entity			the entity that exploded
 * @param client			the client who threw the grenade, can be -1
 *
 * @noreturn
 */
forward void L4D_PipeBomb_Detonate_PostHandled(int entity, int client);

/**
 * @brief Called whenever CVomitJarProjectile::Detonate is invoked
 * @remarks Called when a VomitJar projectile is about to explode
 *
 * @param entity			the entity that exploded
 * @param client			the client who threw the grenade, can be -1
 *
 * @return					Plugin_Handled to block explosion which will cause the Vomitjar projectile to bounce and remain active, Plugin_Continue otherwise
 */
// L4D2 only
forward Action L4D2_VomitJar_Detonate(int entity, int client);

/**
 * @brief Called whenever CVomitJarProjectile::Detonate is invoked
 * @remarks Called when a VomitJar projectile is about to explode
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param entity			the entity that exploded
 * @param client			the client who threw the grenade, can be -1
 *
 * @noreturn
 */
// L4D2 only
forward void L4D2_VomitJar_Detonate_Post(int entity, int client);

/**
 * @brief Called whenever CVomitJarProjectile::Detonate is invoked
 * @remarks Called when a VomitJar projectile is about to explode
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param entity			the entity that exploded
 * @param client			the client who threw the grenade, can be -1
 *
 * @noreturn
 */
// L4D2 only
forward void L4D2_VomitJar_Detonate_PostHandled(int entity, int client);

/**
 * @brief Called whenever CGrenadeLauncher_Projectile::Explode is invoked
 * @remarks Called when a Grenade Launcher projectile is about to explode
 *
 * @param entity			the entity that exploded
 * @param client			the client who shot the grenade, can be -1
 *
 * @return					Plugin_Handled to block explosion which will cause the Grenade Launcher projectile to bounce and remain active, Plugin_Continue otherwise
 */
// L4D2 only
forward Action L4D2_GrenadeLauncher_Detonate(int entity, int client);

/**
 * @brief Called whenever CGrenadeLauncher_Projectile::Explode is invoked
 * @remarks Called when a Grenade Launcher projectile is about to explode
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param entity			the entity that exploded
 * @param client			the client who shot the grenade, can be -1
 *
 * @noreturn
 */
// L4D2 only
forward void L4D2_GrenadeLauncher_Detonate_Post(int entity, int client);

/**
 * @brief Called whenever CGrenadeLauncher_Projectile::Explode is invoked
 * @remarks Called when a Grenade Launcher projectile is about to explode
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param entity			the entity that exploded
 * @param client			the client who shot the grenade, can be -1
 *
 * @noreturn
 */
// L4D2 only
forward void L4D2_GrenadeLauncher_Detonate_PostHandled(int entity, int client);

/**
 * @brief Called whenever CInsectSwarm::CanHarm() is invoked
 * @remarks Called when Spitter Acid is determining if a client or entity can be damaged
 *
 * @param acid				the acid entity index causing the damage
 * @param spitter			the Spitter or client who created the acid (can be 0 or -1)
 * @param entity			the client or entity index being checked if it can be damaged
 *
 * @return					Plugin_Handled to block allowing damage to an entity, Plugin_Continue otherwise
 */
// L4D2 only
forward Action L4D2_CInsectSwarm_CanHarm(int acid, int spitter, int entity);

/**
 * @brief Called whenever CInsectSwarm::CanHarm() is invoked
 * @remarks Called when Spitter Acid has determining if a client or entity can be damaged, or not called when block in the pre forward
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param acid				the acid entity index causing the damage
 * @param spitter			the Spitter or client who created the acid (can be 0 or -1)
 * @param entity			the client or entity index being checked if it can be damaged
 *
 * @noreturn
 */
// L4D2 only
forward void L4D2_CInsectSwarm_CanHarm_Post(int acid, int spitter, int entity);

/**
 * @brief Called whenever CInsectSwarm::CanHarm() is invoked
 * @remarks Called when Spitter Acid has determining if a client or entity can be damaged
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param acid				the acid entity index causing the damage
 * @param spitter			the Spitter or client who created the acid (can be 0 or -1)
 * @param entity			the client or entity index being checked if it can be damaged
 *
 * @noreturn
 */
// L4D2 only
forward void L4D2_CInsectSwarm_CanHarm_PostHandled(int acid, int spitter, int entity);

/**
 * @brief Called whenever CBreakableProp::Break() is invoked
 * @remarks Called when a physics prop is broken
 * @note When a propanetank explodes, it will create and explode another prop_physics and the attacker entity will be 0. Maybe only L4D2 has this issue
 *
 * @param prop				the physics entity index which broke
 * @param entity			the client or entity who caused the prop to break (could be 0)
 *
 * @noreturn
 */
forward void L4D_CBreakableProp_Break(int prop, int entity);

/**
 * @brief Called whenever CFirstAidKit::StartHealing() is invoked
 * @remarks Called when a player is using a first aid kit to heal
 * @note: Detouring as a pre-hook for changing "first_aid_heal_percent" per player before healing finishes
 * @note: Detouring as a post-hook for changing "first_aid_heal_percent" back to default value after healing finishes
 * @note: This does not change the animation speed
 * @note: To find the use entity that is being targeted, use the native: "L4D_FindUseEntity"
 *
 * @param client			the client performing the action
 * @param entity			the medkit entity they are using
 *
 * @return					Plugin_Handled to block healing, Plugin_Continue otherwise
 */
// L4D1 only
forward Action L4D1_FirstAidKit_StartHealing(int client, int entity);

/**
 * @brief Called whenever CFirstAidKit::StartHealing() is invoked
 * @remarks Called when a player is using a first aid kit to heal
 * @note: Detouring as a pre-hook for changing "first_aid_heal_percent" per player before healing finishes
 * @note: Detouring as a post-hook for changing "first_aid_heal_percent" back to default value after healing finishes
 * @note: This does not change the animation speed
 * @note: To find the use entity that is being targeted, use the native: "L4D_FindUseEntity"
 *
 * @param client			the client performing the action
 * @param entity			the medkit entity they are using
 *
 * @noreturn
 */
// L4D1 only
forward void L4D1_FirstAidKit_StartHealing_Post(int client, int entity);

/**
 * @brief Called whenever CFirstAidKit::StartHealing() is invoked
 * @remarks Called when a player is using a first aid kit to heal
 * @note: Detouring as a pre-hook for changing "first_aid_heal_percent" per player before healing finishes
 * @note: Detouring as a post-hook for changing "first_aid_heal_percent" back to default value after healing finishes
 * @note: This does not change the animation speed
 * @note: To find the use entity that is being targeted, use the native: "L4D_FindUseEntity"
 *
 * @param client			the client performing the action
 * @param entity			the medkit entity they are using
 *
 * @noreturn
 */
// L4D1 only
forward void L4D1_FirstAidKit_StartHealing_PostHandled(int client, int entity);

/**
 * @brief Called whenever CBaseBackpackItem::StartAction() is invoked
 * @remarks Called when a player is holding an item and about to use it
 * @note: This does not change the animation speed
 * @note: Detouring as a pre-hook for changing the following per player before starting any actions:
 * - "first_aid_kit_use_duration"
 * - "ammo_pack_use_duration"
 * - "cola_bottles_use_duration"
 * - "defibrillator_use_duration"
 * - "gas_can_use_duration"
 * - "upgrade_pack_use_duration"
 * @note: Detouring as a post-hook for changing the above back to default values after starting any actions
 * @note: To find the use entity that is being targeted, use the native: "L4D_FindUseEntity"
 *
 * @param client			the client performing the action
 * @param entity			the medkit entity they are using
 * @param type				the weapon type ID. Can be found as L4D2WeaponId in the left4dhooks_stocks include file
 *
 * @return					Plugin_Handled to block healing, Plugin_Continue otherwise
 */
// L4D2 only
forward Action L4D2_BackpackItem_StartAction(int client, int entity, any type);

/**
 * @brief Called whenever CBaseBackpackItem::StartAction() is invoked
 * @remarks Called when a player is holding an item and about to use it
 * @note: This does not change the animation speed
 * @note: Detouring as a pre-hook for changing the following per player before starting any actions:
 * - "first_aid_kit_use_duration"
 * - "ammo_pack_use_duration"
 * - "cola_bottles_use_duration"
 * - "defibrillator_use_duration"
 * - "gas_can_use_duration"
 * - "upgrade_pack_use_duration"
 * @note: Detouring as a post-hook for changing the above back to default values after starting any actions
 * @note: To find the use entity that is being targeted, use the native: "L4D_FindUseEntity"
 *
 * @param client			the client performing the action
 * @param entity			the medkit entity they are using
 * @param type				the weapon type ID. Can be found as L4D2WeaponId in the left4dhooks_stocks include file
 *
 * @noreturn
 */
// L4D2 only
forward void L4D2_BackpackItem_StartAction_Post(int client, int entity, any type);

/**
 * @brief Called whenever CBaseBackpackItem::StartAction() is invoked
 * @remarks Called when a player is holding an item and about to use it
 * @note: This does not change the animation speed
 * @note: Detouring as a pre-hook for changing the following per player before starting any actions:
 * - "first_aid_kit_use_duration"
 * - "ammo_pack_use_duration"
 * - "cola_bottles_use_duration"
 * - "defibrillator_use_duration"
 * - "gas_can_use_duration"
 * - "upgrade_pack_use_duration"
 * @note: Detouring as a post-hook for changing the above back to default values after starting any actions
 * @note: To find the use entity that is being targeted, use the native: "L4D_FindUseEntity"
 *
 * @param client			the client performing the action
 * @param entity			the medkit entity they are using
 * @param type				the weapon type ID. Can be found as L4D2WeaponId in the left4dhooks_stocks include file
 *
 * @noreturn
 */
// L4D2 only
forward void L4D2_BackpackItem_StartAction_PostHandled(int client, int entity, any type);

/**
 * @brief Called whenever CGasCan::Event_Killed() is invoked
 * @remarks Called when a gascan is broken
 *
 * @param gascan			the gascan entity index
 * @param inflictor			the inflictor entity index
 * @param attacker			the attacker entity index
 *
 * @return					Plugin_Handled to block detonating, Plugin_Changed to change any values, Plugin_Continue otherwise
 */
// L4D2 only
forward Action L4D2_CGasCan_EventKilled(int gascan, int &inflictor, int &attacker);

/**
 * @brief Called whenever CGasCan::Event_Killed() is invoked
 * @remarks Called when a gascan is broken
 *
 * @param gascan			the gascan entity index
 * @param inflictor			the inflictor entity index
 * @param attacker			the attacker entity index
 *
 * @noreturn
 */
// L4D2 only
forward void L4D2_CGasCan_EventKilled_Post(int gascan, int inflictor, int attacker);

/**
 * @brief Called whenever CGasCan::Event_Killed() is invoked
 * @remarks Called when a gascan is broken
 *
 * @param gascan			the gascan entity index
 * @param inflictor			the inflictor entity index
 * @param attacker			the attacker entity index
 *
 * @noreturn
 */
// L4D2 only
forward void L4D2_CGasCan_EventKilled_PostHandled(int gascan, int inflictor, int attacker);

/**
 * @brief Called whenever CGasCan::ShouldStartAction() is invoked
 * @remarks Called when someone is about to pour a gascan into a nozzle
 *
 * @param client			the client pouring
 * @param gascan			the gascan entity index that is being consumed
 * @param nozzle			the nozzle being poured into
 *
 * @return					Plugin_Handled to block adding to Scavenge score (see "Scavenge Score Fix" plugin for more details), Plugin_Continue otherwise
 */
// L4D2 only
forward Action L4D2_CGasCan_ShouldStartAction(int client, int gascan, int nozzle);

/**
 * @brief Called whenever CGasCan::ShouldStartAction() is invoked
 * @remarks Called when someone has started to pour a gascan into a nozzle
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param client			the client pouring
 * @param gascan			the gascan entity index that is being consumed
 * @param nozzle			the nozzle being poured into
 *
 * @noreturn
 */
// L4D2 only
forward void L4D2_CGasCan_ShouldStartAction_Post(int client, int gascan, int nozzle);

/**
 * @brief Called whenever CGasCan::ShouldStartAction() is invoked
 * @remarks Called when someone has started to pour a gascan into a nozzle
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param client			the client pouring
 * @param gascan			the gascan entity index that is being consumed
 * @param nozzle			the nozzle being poured into
 *
 * @noreturn
 */
// L4D2 only
forward void L4D2_CGasCan_ShouldStartAction_PostHandled(int client, int gascan, int nozzle);

/**
 * @brief Called whenever CGasCan::OnActionComplete() is invoked
 * @remarks Called when someone is about to complete pouring a gascan into a nozzle
 *
 * @param client			the client pouring
 * @param gascan			the gascan entity index that is being consumed
 * @param nozzle			the nozzle being poured into
 *
 * @return					Plugin_Handled to block adding to Scavenge score (see "Scavenge Score Fix" plugin for more details), Plugin_Continue otherwise
 */
// L4D2 only
forward Action L4D2_CGasCan_ActionComplete(int client, int gascan, int nozzle);

/**
 * @brief Called whenever CGasCan::OnActionComplete() is invoked
 * @remarks Called when someone completes pouring a gascan into a nozzle
 * @remarks This forward will not trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param client			the client pouring
 * @param gascan			the gascan entity index that is being consumed
 * @param nozzle			the nozzle being poured into
 *
 * @noreturn
 */
// L4D2 only
forward void L4D2_CGasCan_ActionComplete_Post(int client, int gascan, int nozzle);

/**
 * @brief Called whenever CGasCan::OnActionComplete() is invoked
 * @remarks Called when someone completes pouring a gascan into a nozzle
 * @remarks This forward will ONLY trigger if the relative pre-hook forward has been blocked with Plugin_Handled
 *
 * @param client			the client pouring
 * @param gascan			the gascan entity index that is being consumed
 * @param nozzle			the nozzle being poured into
 *
 * @noreturn
 */
// L4D2 only
forward void L4D2_CGasCan_ActionComplete_PostHandled(int client, int gascan, int nozzle);

/**
 * @brief Returns the current game mode type when it changes. 0=Unknown or error. 1=Coop. 2=Versus. 4=Survival. 8=Scavenge (L4D2)
 * @remarks You can use the "GAMEMODE_*" enums provided above to match the mode
 * @remarks Only triggers when the server starts and after when the game mode changes
 *
 * @param gamemode		Current game mode
 *
 * @noreturn
 */
forward void L4D_OnGameModeChange(int gamemode);

/**
 * @brief Called when the server changes hibernation status
 *
 * @param hibernating		true when hibernating, false when waking up
 *
 * @noreturn
 */
forward void L4D_OnServerHibernationUpdate(bool hibernating);

/**
 * @brief Called when the client's material system is expecting instructions from the server in regards to addons
 * @remarks Doesn't fire if l4d2_addons_eclipse is -1 or 0
 *
 * @param SteamID	SteamID of the client expecting a matsys reply
 *
 * @return			Plugin_Handled to let the client through with addons, Plugin_Continue otherwise
 */
// L4D2 only
forward Action L4D2_OnClientDisableAddons(const char[] SteamID);

/**
 * @brief Called whenever InfectedShoved::OnShoved(Infected *, CBaseEntity *) is invoked
 * @remarks Called when common Infected are about to get shoved
 *
 * @return			Plugin_Handled to block, Plugin_Continue otherwise
 */
#pragma deprecated This was never enabled
forward Action L4D_OnInfectedShoved(int infected, int entity);

/**
 * @brief Called whenever CBasePlayer::WaterMove() is invoked
 * @remarks Couple it with a FL_INWATER check to be sure
 *
 * @param client	the client that is moving in the water
 *
 * @noreturn
 */
#pragma deprecated Does not return water state. Use FL_INWATER instead. See Swimming plugin for L4D/2
forward void L4D2_OnWaterMove(int client);

/**
 * @brief Called whenever ZombieManager::GetRandomPZSpawnPosition is invoked
 * @remarks Attempts to find a valid position to spawn Special Infected
 *
 * @param client			Client id to find an area near this player
 * @param zombieClass		Special Infected class to search for a spawn position for
 * @param attempts			How many tries to find a valid location
 * @param vecPos			The vector location. Sometimes is 0,0,0. Use post hook for real selected position
 *
 * @return					Plugin_Changed to change any values, Plugin_Continue otherwise
 */
#pragma deprecated Removed because it spawns specials at 0,0,0 when modifying any value
forward Action L4D_OnGetRandomPZSpawnPosition(int &client, int &zombieClass, int &attempts, float vecPos[3]);





// ====================================================================================================
// NATIVES - Silvers
// ====================================================================================================
/**
 * @brief Precaches a particle effect
 *
 * @param	sEffectName		String of the particle name e.g. "fuse" or "fire_small_02" etc
 *
 * @noreturn
 */
native void L4D_PrecacheParticle(const char[] sEffectName);

/**
 * @brief Kills an entity of X seconds using the FireUser input/output
 * @remarks This triggers OnUser1 and FireUser1 etc using the AcceptEntityInput method to "Kill" an entity
 *
 * @param	entity		The entity to kill
 * @param	time		After how long to kill the entity
 * @param	user		Which user input/output to use. Valid values 1-4 only.
 *
 * @noreturn
 */
native void L4D_RemoveEntityDelay(int entity, float time, int user = 4);

/**
 * @brief Returns the address pointer to various internal game objects
 *
 * @param	ptr_type		Using the PointerType enum to select which pointer to return
 *
 * @return	Address pointer or 0 on failure
 */
native Address L4D_GetPointer(PointerType ptr_type);

/**
 * @brief Returns a client index from a memory address
 *
 * @param	addy		Address to check
 *
 * @return	Client index or 0 on failure
 */
native int L4D_GetClientFromAddress(Address addy);

/**
 * @brief Returns an entity index from a memory address
 *
 * @param	addy		Address to check
 *
 * @return	Entity index or -1 on failure
 */
native int L4D_GetEntityFromAddress(Address addy);

/**
 * @brief Returns a string read from a memory address
 *
 * @param	addy		Address to read from
 *
 * @return	Entity index or -1 on failure
 */
native int L4D_ReadMemoryString(Address addy, char[] buffer, int maxlength);

/**
 * @brief Writes a string to a memory address
 *
 * @param	addy		Address to write to
 * @param	buffer		String to write
 *
 * @noreturn
 */
native void L4D_WriteMemoryString(Address addy, const char[] buffer);

/**
 * @brief Returns the servers operating system
 *
 * @return	0=Windows. 1=Linux
 */
native int L4D_GetServerOS();

/**
 * @brief Returns the Left4DHooks version number. For example version "1.122" is 1122
 * @note This will only work from Left4DHooks version 1.122 or newer
 *
 * @remarks Use to verify a newer version is running from a certain version number, where for example a new native or forward was added
 * @remarks Each version number will be greater than the previous
 * @remarks Example code:
 * @remarks Put: MarkNativeAsOptional("Left4DHooks_Version") in your plugins "AskPluginLoad2" section
 * @remarks Then run this code to determine the version:
 * @remarks if( GetFeatureStatus(FeatureType_Native, "Left4DHooks_Version") == FeatureStatus_Available && Left4DHooks_Version() >= 1122 )
 *
 * @remarks Alternatively, to support all versions, it would be better to use the "left4dhooks_version" convar, retrieve as a float and check
 * @remarks For example: FindConVar("left4dhooks_version").FloatValue >= 1.122
 *
 * @return	Version number
 */
native int Left4DHooks_Version();

/**
 * @brief Checks if the map and addresses are loaded that some natives rely on
 *
 * @return	True if the map has started and addresses are loaded, false otherwise
 */
native bool L4D_HasMapStarted();

/**
* @brief Returns an entities script scope (HSCRIPT)
*
* @param	entity		The entity to retrieve it's script scope
*
* @return	Script scope or 0 if none
*/
// L4D2 only
native int L4D2_GetScriptScope(int entity);

/**
* @brief Creates or uses an existing "logic_script" entity that is created by Left4DHooks
* @remarks Do NOT use entity outputs as this entity is shared by other plugins
*
* @return	VScript "logic_script" entity index
* @error	0 on error
*/
// L4D2 only
native int L4D2_GetVScriptEntity();

/**
* @brief Runs a specified VScript code
* @remarks Saves having to create an entity. The entity can remain alive and used again
* @remarks unless the core plugins define KILL_VSCRIPT is changed and the plugin recompiled
*
* @param	code			The VScript code to execute. Maximum length seems to be 1006 characters
*
* @return	True on success, false otherwise
* @error	Invalid code or failed to create logic_script
*/
// L4D2 only
native bool L4D2_ExecVScriptCode(char[] code);

/**
* @brief Runs a specified VScript code and returns values from it
* @remarks Can execute several code blocks on a single line separating them with ; as standard coding practice
* @remarks Can also execute several lines of code from SourcePawn, you must end the line with a backslash
* @remarks Can return specific data by wrapping what you want to return within "<RETURN>" and "</RETURN>"
* @remarks See the test plugin for examples to all the above
*
* @param	code			The VScript code to execute. Maximum length seems to be 1006 characters
* @param	buffer			Buffer to copy return data to. You can use StringToInt or StringToFloat if required
* @param	maxlength		Maximum size of the buffer
*
* @return	True on success, false otherwise
* @error	Invalid code or failed to create logic_script or possibly an empty string
*/
// L4D2 only
native bool L4D2_GetVScriptOutput(char[] code, char[] buffer, int maxlength);

/**
 * @brief Returns the current game mode type. 0=Unknown or error. 1=Coop. 2=Versus. 4=Survival. 8=Scavenge (L4D2)
 * @remarks You can use the "GAMEMODE_*" enums provided above to match the mode
 *
 * @return	Current game mode
 */
native int L4D_GetGameModeType();

/**
 * @brief Deafens a player with a high pitch ringing sound for a few seconds
 * @remarks Used in the "Prototype Grenades" plugin by Silvers
 *
 * @param client	Client id of the player to deafen
 *
 * @noreturn
 */
native void L4D_Deafen(int client);

/**
 * @brief Returns a Survivors current temporary health buffer HP
 *
 * @param client	Client id of the Survivor player
 *
 * @return			Temp health value
 */
native float L4D_GetTempHealth(int client);

/**
 * @brief Sets a Survivors temporary health buffer HP
 *
 * @param client	Client id of the Survivor player
 * @param health	Health value to set
 *
 * @noreturn
 */
native void L4D_SetTempHealth(int client, float health);

/**
 * @brief Returns the reserve ammo for a specific players weapon
 *
 * @param client	Client id of the Survivor player
 * @param weapon	Weapon entity index to affect
 *
 * @return			Reserve ammo count
 */
native int L4D_GetReserveAmmo(int client, int weapon);

/**
 * @brief Sets the reserve ammo for a specific players weapon
 *
 * @param client	Client id of the Survivor player
 * @param weapon	Weapon entity index to affect
 * @param ammo		Reserve ammo count to set
 *
 * @noreturn
 */
native void L4D_SetReserveAmmo(int client, int weapon, int ammo);

/**
 * @brief Plays specified music string name on the music channel to a client
 * @remarks Music strings such as "Event.BleedingOut"
 * @remarks List of strings can be found inside the games VPK files here: scripts\game_sounds_music.txt
 *
 * @param client		Client id of the Survivor player
 * @param music_str		Music string name to play
 * @param source_ent	Source entity to play from (can be 0)
 * @param one_float		Unknown, maybe duration? Please report what this is when using
 * @param one_bool		Unknown. Please report what this is when using
 * @param two_bool		Unknown. Please report what this is when using
 *
 * @noreturn
 */
native void L4D_PlayMusic(int client, const char[] music_str, int source_ent = 0, float one_float, bool one_bool, bool two_bool);

/**
 * @brief Stops playing the specified music_str to the client
 * @remarks Music strings such as "Event.BleedingOut"
 * @remarks List of strings can be found inside the games VPK files here: scripts\game_sounds_music.txt
 *
 * @param client		Client id of the Survivor player
 * @param music_str		Music string name to stop playing
 * @param one_float		Unknown, maybe duration? Please report what this is when using
 * @param one_bool		Unknown. Please report what this is when using
 *
 * @noreturn
 */
native void L4D_StopMusic(int client, const char[] music_str, float one_float = 0.0, bool one_bool = false);

/**
 * @brief Creates the dissolve effect on common infected, players or objects
 * @remarks You must handle the fading or killing of an entity as required
 * @remarks Used in the "Dissolve Infected" plugin by Silvers
 *
 * @param entity	The entity to dissolve
 *
 * @return			Entity index of the dissolver, which should automatically delete itself when the effect is done
 */
native int L4D_Dissolve(int entity);

/**
 * @brief Removes the boomer vomit effect from a player
 *
 * @param client	Client id of the player to remove the effect from
 *
 * @noreturn
 */
native void L4D_OnITExpired(int client);

/**
 * @brief Returns the estimated fall damage of a player
 * @remarks This only gives an estimate and not the actual damage the player is likely to receive
 * @remarks The value maxes out at 400.0. Use SourceScamble to modify "FallingDamageForSpeed(float)" and change the minimum and maximum values
 *
 * @param client	Client id of the player
 *
 * @return			Estimated falling damage value
 */
native float L4D_EstimateFallingDamage(int client);

/**
 * @brief Returns the worldspace center of an entity
 *
 * @param entity	The entity to use
 * @param vecPos	The entities worldspace center returned vector
 *
 * @noreturn
 */
native void L4D_GetEntityWorldSpaceCenter(int entity, float vecPos[3]);

/**
 * @brief Sets a physics entity angular velocity vector
 * @remarks Spins an entity, for example used in "Throwable Melee Weapons" plugin by Silvers
 * @remarks See the "left4dhooks_test" plugin for an example on spinning the entity top over or sideways
 *
 * @param entity	The entity to spin
 * @param vecAng	Angular velocity vector, director to spin the projectile
 *
 * @noreturn
 */
native void L4D_AngularVelocity(int entity, const float vecAng[3]);

/**
 * @brief Attempts to find a random valid position to spawn a Special Infected
 * @remarks The zombieClass does not matter but different values yield different results:
 * @remarks Using the Tank zombieClass probably searches for a larger area that's clear of objects
 *
 * @param client			Client id to find an area near this player. Accepts 0 to find a random area instead
 * @param zombieClass		Special Infected class to search for a spawn position for
 * @param attempts			How many tries to find a valid location
 * @param vecPos			The vector array to store the valid location on success
 *
 * @return					True on success, false on failure to find valid location
 */
native bool L4D_GetRandomPZSpawnPosition(int client, int zombieClass, int attempts, float vecPos[3]);

/**
 * @brief Given a vector position, returns the relative NavArea
 * @remarks This is more reliable than L4D2Direct_GetTerrorNavArea
 *
 * @param vecPos			The vector array to use to retrieve the NavArea
 * @param maxDist			Furthest distance to the nearest nav area
 * @param anyZ				Any ground position?
 * @param checkLOS			Check line of sight
 * @param checkGround		Check if on ground?
 * @param teamID			Team ID to check for
 *
 * @return					The NavArea value, or 0 on failure probably
 */
native any L4D_GetNearestNavArea(const float vecPos[3], float maxDist = 300.0, bool anyZ = false, bool checkLOS = false, bool checkGround = false, int teamID = 2);

/**
 * @brief Returns the nav address of the last known area
 *
 * @param client			The client to check
 *
 * @return					The nav area address or 0 on fail
 */
native any L4D_GetLastKnownArea(int client);

/**
 * @brief Gets the first Special Infected type the Director will spawn. Value set on map start
 * @remarks zombieClass: 1=Smoker, 2=Boomer, 3=Hunter, 4=Spitter, 5=Jockey, 6=Charger
 *
 * @return			zombieClass of the Special Infected first spawning
 */
// L4D2 only
native int L4D2_GetFirstSpawnClass();

/**
 * @brief Sets the first Special Infected type the Director will spawn
 * @remarks zombieClass: 1=Smoker, 2=Boomer, 3=Hunter, 4=Spitter, 5=Jockey, 6=Charger
 *
 * @noreturn
 */
// L4D2 only
native void L4D2_SetFirstSpawnClass(int zombieClass);

/**
 * @brief Gets the maximum flow distance any survivor has achieved
 *
 * @return			Returns the maximum flow distance any survivor has achieved
 */
// L4D2 only
native float L4D2_GetFurthestSurvivorFlow();

/**
 * @brief Given a nav area value, returns a randomly selected position for spawning
 * @remarks This is what Witches use to spawn
 *
 * @param NavArea			The NavArea to search for a valid location
 * @param vecPos			The vector array to store the valid location on success
 *
 * @noreturn
 */
native void L4D_FindRandomSpot(int NavArea, float vecPos[3]);

/**
 * @brief Checks if a player is visible to a specified position. Should be slightly faster than using TR_TraceRayFilterEx
 *
 * @param client			Client to check visibility from
 * @param vecPos			The vector position of the target location
 * @param team				The team of the client, can possibly pass 0 to 3
 * @param team_target		Target point team, if it is 0, the client's angle will be considered
 * @param NavArea			NavArea of ​​the target, or 0 to automatically get with GetNearestNavArea
 *
 * @return					True if visible, false otherwise
 */
native bool L4D2_IsVisibleToPlayer(int client, int team, int team_target, int NavArea, float vecPos[3]);

/**
 * @brief Teleports a player to a valid position if they are stuck
 *
 * @param client			Client to perform the action
 *
 * @noreturn
 */
native void L4D_WarpToValidPositionIfStuck(int client);

/**
 * @brief Returns true when any survivor has left the starting area and true in Versus when the saferoom door automatically opens
 *
 * @return			True if a survivor has left the starting area. False otherwise
 */
native bool L4D_HasAnySurvivorLeftSafeArea();

/**
 * @brief Returns true when any survivor is in the starting checkpoint area
 *
 * @return			True if any survivor is in the starting checkpoint area. False otherwise
 */
native bool L4D_IsAnySurvivorInStartArea();

/**
 * @brief Returns true when any survivor is in the starting or ending checkpoint area
 *
 * @return			True if a survivor is in the starting or ending checkpoint area. False otherwise
 */
native bool L4D_IsAnySurvivorInCheckpoint();

/**
 * @brief Returns true when all survivors are in the finale area
 *
 * @return			True when in all Survivors are in the area. False otherwise
 */
native bool L4D_AreAllSurvivorsInFinaleArea();

/**
 * @brief Returns true when the specified Survivor or Special Infected is in the starting checkpoint area
 * @remarks This might return true on certain maps, maybe in Survival/Scavenge start areas if they are close enough to the saferoom
 * @remarks You could use the "L4D_IsPositionInFirstCheckpoint" native instead to accurately determine if someone is in the starting area
 * @remarks This will always returns false when the "Unlock Finales" plugin by "Marttt" is installed: https://forums.alliedmods.net/showthread.php?t=333274
 *
 * @param client	Client id to check their checkpoint
 *
 * @return			True if a survivor is in the starting checkpoint area. False otherwise
 */
native bool L4D_IsInFirstCheckpoint(int client);

/**
 * @brief Returns true when the specified Survivor or Special Infected is in the ending checkpoint area
 *
 * @param client	Client id to check their checkpoint
 *
 * @return			True if a survivor is in the ending checkpoint area. False otherwise
 */
native bool L4D_IsInLastCheckpoint(int client);

/**
 * @brief Returns true when a given vector is within the starting checkpoint area
 *
 * @param vecPos	Vector position to check
 *
 * @return			True if the position is within the starting checkpoint area. False otherwise
 */
native bool L4D_IsPositionInFirstCheckpoint(float vecPos[3]);

/**
 * @brief Returns true when a given vector is within the ending checkpoint area
 *
 * @param vecPos	Vector position to check
 *
 * @return			True if the position is within the ending checkpoint area. False otherwise
 */
native bool L4D_IsPositionInLastCheckpoint(float vecPos[3]);

/**
 * @brief Returns the entity index of the first saferoom door, if available
 * @remarks This works by checking the saferoom door position against the maps flow distance selecting the door with 2000.0 (DOOR_RANGE_TOLLERANCE define) from map start
 * @remarks Does not include doors with the DOOR_FLAG_IGNORE_USE flag. This flag is set by the "Safe Door Spam" plugin by Silvers for 0.1 seconds when someone attempts to open the saferoom door
 *
 * @return			-1 if none exists or entity index of saferoom door
 */
native int L4D_GetCheckpointFirst();

/**
 * @brief Returns the entity index of the last saferoom door, if available
 * @remarks This works by checking the saferoom door position against the maps flow distance selecting the door with 2000.0 (DOOR_RANGE_TOLLERANCE define) from map end
 * @remarks Does not include doors with the DOOR_FLAG_IGNORE_USE flag. This flag is set by the "Safe Door Spam" plugin by Silvers for 0.1 seconds when someone attempts to open the saferoom door
 *
 * @return			-1 if none exists or entity index of saferoom door
 */
native int L4D_GetCheckpointLast();

/**
 * @brief Checks if a world position is accessible to a Survivor bot
 * @remarks You must pass a survivor bots client index into this, otherwise the plugin will attempt to find a bot or throw an error otherwise
 * @remarks It appears the server will sometimes crash when passing a real players client index
 * @remarks If the clients flow distance is too far away from the position to test it will return false
 *
 * @param client	Client id to use for testing
 * @param vecPos	Vector coordinate to test
 *
 * @return			True if accessible, false otherwise
 */
// L4D2 only
native bool L4D2_IsReachable(int client, const float vecPos[3]);

/**
 * @brief Returns the nav distance between two areas. Does not account for out-of-bounds areas
 *
 * @param startArea				NavArea address
 * @param endArea				NavArea address
 * @param ignoreNavBlockers		Bool to ignore blocked areas while checking (does not seem to work as expected) (ignored in L4D1)
 *
 * @return						Distance between the areas, 0.0 if the same area or -1.0 on failure
 */
native float L4D2_NavAreaTravelDistance(float startPos[3], float endPos[3], bool ignoreNavBlockers);

/**
 * @brief Test two vector positions if they can be reached (only returns false if a location has no valid NavArea, out-of-bounds can be valid)
 * @remarks Uses the "ShortestPathCost" system
 *
 * @param		nav_startPos		The NavArea address start position (can use L4D_GetNearestNavArea)
 * @param		nav_endPos			The NavArea address end position from (can use L4D_GetNearestNavArea)
 * @param		flMaxPathLength		Maximum distance allowed between the two points
 * @param		teamID				Which team to validate the path for
 * @param		ignoreNavBlockers	Should nav blockers be ignored or not
 *
 * @return		Returns true if a path exists, false if not or on script error
 */
// L4D2 only
native bool L4D2_NavAreaBuildPath(Address nav_startPos, Address nav_endPos, float flMaxPathLength, int teamID, bool ignoreNavBlockers);

// Used by "L4D2_CommandABot" native:
enum BOT_CMD
{
	BOT_CMD_ATTACK = 0,		// Force the bot to attack a specific target, even bypassing CTerrorPlayer::SetSenseFlags (DirectorScript.BOT_CANT_SEE)
	BOT_CMD_MOVE = 1,		// Force the bot to move to a specific location, which then they will do it unconditionally without performing any other AI behaviours controlled by themselves
							// This means that Survivor Bots and most player-controllable Special Infected won't attack anything when commanded, but Common Infected still automatically attack enemies if they close in enough
	BOT_CMD_RETREAT = 2,	// Force the bot to retreat from a target entity. Only works when used on Survivor Bots, and if target is a Tank
	BOT_CMD_RESET = 3		// Removes the active bot command and lets the AI resume controlling the bot
};

/**
 * @brief Uses the VScript "CommandABot" function to command a bot to attack, move, retreat or reset previous command
 *
 * @param		entity			The bot or infected to command
 * @param		target			The Special Infected to target (used for types "BOT_CMD_ATTACK" and "BOT_CMD_RETREAT")
 * @param		type			Type of command (see the "BOT_CMD" enum)
 * @param		vecPos			Move to this location (Used for type "BOT_CMD_MOVE")
 *
 * @return		Returns false when unable to perform, true otherwise
 */
// L4D2 only
native bool L4D2_CommandABot(int entity, int target, BOT_CMD type, float vecPos[3] = NULL_VECTOR);

/**
 * @brief Returns if players can control infected
 *
 * @return			True if players can control infected, false otherwise
 */
native bool L4D_HasPlayerControlledZombies();

/**
 * @brief Detonates an active grenade projectile
 * @remarks Can detonate in L4D1 & L4D2: "molotov_projectile", "pipebomb_projectile", "tank_rock"
 * @remarks Can detonate in L4D2: "vomitjar_projectile", "grenadelauncher_projectile", "spitter_projectile"
 *
 * @param entity	The projectile entity to detonate
 *
 * @noreturn
 */
native void L4D_DetonateProjectile(int entity);

/**
 * @brief Detonates an active grenade projectile
 * @remarks Can detonate in L4D1 & L4D2: "molotov_projectile", "pipebomb_projectile", "tank_rock"
 * @remarks Can detonate in L4D2: "vomitjar_projectile", "grenadelauncher_projectile", "spitter_projectile"
 *
 * @param entity	The projectile entity to detonate
 *
 * @noreturn
 */
// NOT IMPLEMENTED
// native int L4D_StartBurning(int entity, float vecPos[3], float vecNorm[3], float vecVel[3]);

/**
 * @brief Creates an activated Tank Rock projectile
 * @remarks It seems when using a Survivor for the client index and hitting another Survivor, the victim will take 1.0 damage (maybe due to friendly fire settings)
 * @remarks Suggest using an OnTakeDamage hook if you want to apply more damage
 *
 * @param client	Client id to attribute the projectile to for damage credit. Passing 0 (world) is allowed
 * @param vecPos	Vector coordinate of the projectile on creation
 * @param vecAng	Vector direction of the projectile
 *
 * @return			Entity index of the projectile
 */
native int L4D_TankRockPrj(int client, const float vecPos[3], const float vecAng[3]);

/**
 * @brief Creates an activated PipeBomb projectile
 * @remarks Example use in the "PipeBomb Shove" plugin by Silvers
 *
 * @param client	Client id to attribute the projectile to for damage credit. Passing 0 (world) is allowed
 * @param vecPos	Vector coordinate of the projectile on creation
 * @param vecAng	Vector velocity and direction of the projectile
 * @param effects	True = create fuse/light particles. False = don't create (default before 1.139 update)
 *
 * @return			Entity index of the projectile
 */
native int L4D_PipeBombPrj(int client, const float vecPos[3], const float vecAng[3], bool effects = false);

/**
 * @brief Creates an activated Molotov projectile
 *
 * @param client	Client id to attribute the projectile to for damage credit Passing 0 (world) is allowed
 * @param vecPos	Vector coordinate of the projectile on creation
 * @param vecAng	Vector velocity and direction of the projectile
 *
 * @return			Entity index of the projectile
 */
native int L4D_MolotovPrj(int client, const float vecPos[3], const float vecAng[3]);

/**
 * @brief Creates an activated VomitJar projectile
 *
 * @param client	Client id to attribute the projectile to for damage credit Passing 0 (world) is allowed
 * @param vecPos	Vector coordinate of the projectile on creation
 * @param vecAng	Vector velocity and direction of the projectile
 *
 * @return			Entity index of the projectile
 */
// L4D2 Only
native int L4D2_VomitJarPrj(int client, const float vecPos[3], const float vecAng[3]);

/**
 * @brief Creates an activated Grenade Launcher projectile
 *
 * @param client	Client id to attribute the projectile to for damage credit Passing 0 (world) is allowed
 * @param vecPos	Vector coordinate of the projectile on creation
 * @param vecAng	Vector velocity and direction of the projectile
 *
 * @return			Entity index of the projectile
 */
// L4D2 Only
native int L4D2_GrenadeLauncherPrj(int client, const float vecPos[3], const float vecAng[3]);

/**
 * @brief Creates a Spitter goo projectile
 *
 * @param client	Client id to attribute the projectile to for damage credit Passing 0 (world) is allowed
 * @param vecPos	Vector coordinate of the projectile on creation
 * @param vecAng	Vector velocity and direction of the projectile
 *
 * @return			Entity index of the projectile
 */
// L4D2 only
native int L4D2_SpitterPrj(int client, const float vecPos[3], const float vecAng[3]);

/**
 * @brief Gives the player adrenaline effect and health benefits
 *
 * @param client	Client id to affect
 * @param fTime		Duration of screen effects (game default: 15.0 - Cvar: "adrenaline_duration")
 * @param heal		True = give health benefits. False = only screen effects
 * @param event		True = fire the "adrenaline_used" event. False = no event triggered
 *
 * @return			True on success, false otherwise
 */
// L4D2 only
native void L4D2_UseAdrenaline(int client, float fTime = 15.0, bool heal = true, bool event = true);

/**
 * @brief Respawns a player from dead state
 * @remarks Resets players stats for kills etc
 * @remarks To preserve stats please view the code in "[L4D1 & L4D2] SM Respawn Improved" plugin by "Dragokas": https://forums.alliedmods.net/showthread.php?t=323220
 *
 * @param client	Client ID of the person to respawn
 *
 * @noreturn
 */
native void L4D_RespawnPlayer(int client);

/**
 * @brief To takeover a Survivor bot. First use "ChangeClientTeam" and change them to 0. Then call "L4D_SetHumanSpec" then call "L4D_TakeOverBot"
 *
 * @param bot		Bot ID of the person to set spectator
 * @param client	Client ID of the spectator
 *
 * @return			True or false
 */
native bool L4D_SetHumanSpec(int bot, int client);

/**
 * @brief To takeover a Survivor bot. First use "ChangeClientTeam" and change them to 0. Then call "L4D_SetHumanSpec" then call "L4D_TakeOverBot"
 *
 * @param client	Client ID of who should takeover
 *
 * @return			True or false
 */
native bool L4D_TakeOverBot(int client);

/**
 * @brief Returns true when the "You will enter Spawn Mode in X seconds" text appears on the screen
 *
 * @param client	Client ID to check
 *
 * @return			True or false
 */
native bool L4D_CanBecomeGhost(int client);

/**
 * @brief Set a dead Special Infected players time until they transition into ghost state. Can be used when the "ghost_spawn_time" event triggers
 *
 * @param client	Client ID to check
 *
 * @return			True or false
 */
native void L4D_SetBecomeGhostAt(int client, float time);

/**
 * @brief Sets a client as idle, afk - away from keyboard
 *
 * @param client	Client ID to check
 *
 * @return			True or false
 */
native bool L4D_GoAwayFromKeyboard(int client);

/**
 * @brief Returns if Wandering Witches are allowed
 *
 * @return			True or false
 */
// L4D2 only
native bool L4D2_AreWanderersAllowed();

/**
 * @brief Returns true when the rescue vehicle is leaving until the screen fades and credits start
 *
 * @return			True or false
 */
native bool L4D_IsFinaleEscapeInProgress();

/**
 * @brief Returns the current Finale stage type
 * @remarks some values for FinaleStageType: 1 - Finale Started; 6 - Rescue Vehicle Ready; 7 - Zombie Hordes; 8 - Tank; 10 - Combat Respite (nothing spawns)
 * @remarks Seems to return 18 for non-finale maps
 * @remarks Can use the "FINALE_*" enums (search for them above) for the finaleType value
 *
 * @return			finaleType stage value
 */
// L4D2 only
native any L4D2_GetCurrentFinaleStage();

/**
 * @brief Forces the ScriptedMode stage to advance to the next stage
 *
 * @noreturn
 */
// L4D2 only
native void L4D2_ForceNextStage();

/**
 * @brief Returns the Survival setup countdown time before start (director_survival_setup_time must be non-0)
 * @remarks Shows the time as 140/130/120 seconds, which is related to the chat messages shown as "SPAWNING STARTS IN 130 SECONDS"
 *
 * @return			Seconds until start, or 0 if director_survival_setup_time is 0
 */
// L4D2 only
native int L4D2_GetSurvivalStartTime();

/**
 * @brief Sets the Survival countdown time before start
 *
 * @noreturn
 */
// L4D2 only
native void L4D2_SetSurvivalStartTime(int time);

/**
 * @brief Forces the game to start in Versus
 *
 * @noreturn
 */
native void L4D_ForceVersusStart();

/**
 * @brief Forces the game to start in Survival
 *
 * @noreturn
 */
native void L4D_ForceSurvivalStart();

/**
 * @brief Forces the game to start in Scavenge
 *
 * @noreturn
 */
// L4D2 only
native void L4D2_ForceScavengeStart();

/**
 * @brief Returns true when any tanks are on the map
 *
 * @return			True when any tanks are on the map. False when no tanks
 */
// L4D2 only
native bool L4D2_IsTankInPlay();

/**
 * @brief Returns the directors script scope handle
 * @remarks	Scope level
 * 0 = DirectorScript
 * 1 = MapScript
 * 2 = LocalScript
 * 3 = ChallengeScript
 * 4 = DirectorOptionsScope
 *
 * @Param level		The scope level
 *
 * @return			Value of directors script scope
 */
// L4D2 only
native int L4D2_GetDirectorScriptScope(int level);

/**
 * @brief Returns the value of the specified Director Variable key
 * @remarks You should provide a valid default value to use as the native is likely to return that unless the key value has been modified by a mutation or director script
 * @remarks See the "left4dhooks_test.sp" plugin and search for "L4D2_GetScriptValueInt" to see a list of keys and their default values and related cvars
 *
 * @param key		Director variable key name to search for
 * @param value		Default value to use when the variable is not found
 *
 * @return			Value of the variable, or provided default value on failure
 */
// L4D2 only
native int L4D2_GetScriptValueInt(const char[] key, int value);

/**
 * @brief Returns the value of the specified Director Variable key
 * @remarks You should provide a valid default value to use as the native is likely to return that unless the key value has been modified by a mutation or director script
 * @remarks See the "left4dhooks_test.sp" plugin and search for "L4D2_GetScriptValueFloat" to see a list of keys and their default values and related cvars
 *
 * @param key		Director variable key name to search for
 * @param value		Default value to use when the variable is not found
 *
 * @return			Value of the variable, or provided default value on failure
 */
// L4D2 only
native float L4D2_GetScriptValueFloat(const char[] key, float value);

// Crashes when the key has not been set
// native void L4D2_GetScriptValueString(const char[] key, const char[] value, char[] retValue, int maxlength);

/**
 * @brief Returns if there is a configurable difficulty setting
 * @brief Returns true for Coop/Realism modes
 * @remarks Can only be called 1 frame after OnMapStart at the earliest otherwise the addresses are invalid - Since version 1.133 Left4DHooks will block these calls and log an error
 *
 * @return				True if there is a configurable difficulty setting, false otherwise
 **/
// L4D2 only
native bool L4D2_HasConfigurableDifficultySetting();

/**
 * @brief Returns the maps default Survivor set
 * @brief Does not return the overridden value when changed from the "L4D_OnGetSurvivorSet" or "L4D_OnFastGetSurvivorSet" forwards
 * @remarks Can only be called 1 frame after OnMapStart at the earliest otherwise the addresses are invalid - Since version 1.133 Left4DHooks will block these calls and log an error
 *
 * @return				Maps default survivor set
 **/
// L4D2 only
native int L4D2_GetSurvivorSetMap();

/**
 * @brief Returns the current Survivor set
 * @brief Return the current set which may have been overridden if changed in the "L4D_OnGetSurvivorSet" or "L4D_OnFastGetSurvivorSet" forwards
 *
 * @return				Maps default survivor set
 **/
// L4D2 only
native int L4D2_GetSurvivorSetMod();

/**
 * @brief Returns if the current game mode is Coop/Realism mode
 * @remarks Can only be called 1 frame after OnMapStart at the earliest otherwise the addresses are invalid - Since version 1.133 Left4DHooks will block these calls and log an error
 *
 * @return				True if the current game mode is Coop/Realism mode, false otherwise
 **/
// L4D2 only
native bool L4D2_IsGenericCooperativeMode();

/**
 * @brief Returns if the current game mode is Coop mode
 *
 * @return				True if the current game mode is Coop mode, false otherwise
 **/
native bool L4D_IsCoopMode();

/**
 * @brief Returns if the current game mode is Realism mode
 * @remarks Can only be called 1 frame after OnMapStart at the earliest otherwise the addresses are invalid - Since version 1.133 Left4DHooks will block these calls and log an error
 *
 * @return				True if the current game mode is Realism mode, false otherwise
// L4D2 only
 **/
native bool L4D2_IsRealismMode();

/**
 * @brief Returns if the current game mode is Survival mode
 *
 * @return				True if the current game mode is Survival mode, false otherwise
 **/
native bool L4D_IsSurvivalMode();

/**
 * @brief Returns if the current game mode is Scavenge mode
 *
 * @return				True if the current game mode is Scavenge mode, false otherwise
 **/
// L4D2 only
native bool L4D2_IsScavengeMode();

/**
 * @brief Returns if the current game mode is Versus mode
 *
 * @return				True if the current game mode is Versus mode, false otherwise
 **/
native bool L4D_IsVersusMode();





// ====================================================================================================
// NATIVES - Silvers - VSCRIPT WRAPPERS
// ====================================================================================================
// These natives are using VScripts to call functions - this is much slower than native SDKCalls
// Popular VScript functions will be converted to standard native SDKCalls. Please tell me
// Recommend not using these too often, instead request proper native SDKCalls

/**
 * @brief Returns the number of maps played since a new campaign (not the current chapter)
 *
 * @return		Number of maps played
 */
// L4D2 only
native int L4D2_VScriptWrapper_GetMapNumber();

/**
 * @brief Returns true if the character has ever been injured by a member of the given team
 * @remarks Team 3 returns true when hurt by Common Infected
 *
 * @param client		Client to test
 * @param team			Team to test
 *
 * @return				Number of maps played
 */
// L4D2 only
native bool L4D2_VScriptWrapper_HasEverBeenInjured(int client, int team);

/**
 * @brief Returns the time the character has been alive (only valid when alive)
 *
 * @return				Client to test
 */
// L4D2 only
native float L4D2_VScriptWrapper_GetAliveDuration(int client);

/**
 * @brief Returns true when a player is dead and can spectate others
 *
 * @param client		Client to test
 *
 * @return				True if dead, false if not or script error
 */
// L4D2 only
native bool L4D2_VScriptWrapper_IsDead(int client);

/**
 * @brief Returns true when a player is dead, but cannot spectate others yet
 *
 * @param client		Client to test
 *
 * @return				True if dying, false if not or script error
 */
// L4D2 only
native bool L4D2_VScriptWrapper_IsDying(int client);

/**
 * @brief Causes Adrenaline's speed and visual effect, no change to health
 *
 * @param client		Client to affect
 *
 * @return				True on success (does not guarantee effect turned on), false on script error
 */
// L4D2 only
#pragma deprecated Use L4D2_UseAdrenaline native instead (kept here for speed comparison)
native bool L4D2_VScriptWrapper_UseAdrenaline(int client, float time);

/**
 * @brief Revive a dead player by defib
 *
 * @param client		Client to revive
 *
 * @return				True on success (does not guarantee they were revived), false on script error
 */
// L4D2 only
native bool L4D2_VScriptWrapper_ReviveByDefib(int client);

/**
 * @brief Revive an incapacitated player
 *
 * @param client		Client to revive
 *
 * @return				True on success (does not guarantee they were revived), false on script error
 */
// L4D2 only
native bool L4D2_VScriptWrapper_ReviveFromIncap(int client);

/**
 * @brief Get the current bits for the bot sense flags: BOT_CANT_SEE, BOT_CANT_HEAR, BOT_CANT_FEEL
 *
 * @param bot			Bot to check
 *
 * @return				Current sense flags
 */
// L4D2 only
native any L4D2_VScriptWrapper_GetSenseFlags(int bot);

/**
 * @brief Test two vector positions if they can be reached (only returns false if a location has no valid NavArea, out-of-bounds can be valid)
 *
 * @return		Returns true if a path exists, false if not or on script error
 */
// L4D2 only
#pragma deprecated Use L4D2_NavAreaBuildPath native instead (kept here for speed comparison)
native bool L4D2_VScriptWrapper_NavAreaBuildPath(const float startPos[3], const float endPos[3], float flMaxPathLength, bool checkLOS, bool checkGround, int teamID, bool ignoreNavBlockers);

/**
 * @brief Compute distance between two areas
 *
 * @return		-1 if can't reach 'endArea' from 'startArea'
 */
// L4D2 only
// Added as a demonstration and test, SDKCall is available, use "L4D2_NavAreaTravelDistance" instead
native float L4D2_VScriptWrapper_NavAreaTravelDistance(const float startPos[3], const float endPos[3], float flMaxPathLength, bool checkLOS, bool checkGround);





// ====================================================================================================
// NATIVES - left4downtown.inc (and new ones by Silvers)
// ====================================================================================================
/**
 * @brief Restarts the setup timer (when in scavenge mode)
 * @remarks If game has already started, the setup timer will show,
 *			but it still won't go back into setup
 */
// L4D2 only
native int L4D_ScavengeBeginRoundSetupTime();

/**
 * @brief Spawns all Scavenge gascans in the map
 * @remarks	Requires the Director to be available--map must be started
 * @remarks Enables to fix https://github.com/ValveSoftware/Source-1-Games/issues/1616
 * @remarks Spawns them even if they exist already
 *
 * @noreturn
 */
// L4D2 only
native void L4D2_SpawnAllScavengeItems();


/**
 * @brief Resets the natural mob (horde) timer
 * @remarks	Requires the Director to be available--map must be started
 *
 * @noreturn
 */
// L4D2 only
native void L4D_ResetMobTimer();

/**
 * @brief Get the remaining spawn time for a SI
 * @remarks This is meant for Special infected in ghost mode in versus
 *
 * @param player	Player ID to get time
 *
 * @return			Time (seconds) until the SI will spawn
 */
// L4D2 only
native float L4D_GetPlayerSpawnTime(int player);

/**
 * @brief Set the remaining spawn time for a SI
 * @remarks This is meant for Special infected in ghost mode in versus
 *
 * @param player				Player ID to set time
 * @param time					Number of seconds until the SI will spawn
 * @param bReportToPlayer		If the change should be sent to clients, updating timer in HUD
 *
 * @noreturn
 */
// L4D2 only
native void L4D_SetPlayerSpawnTime(int player, float time, bool bReportToPlayer = true);

/**
 * @brief Restarts the round, switching the map if necessary
 * @remarks Set the map to the current map to restart the round
 *
 * @param map		the mapname it should go to after the round restarts
 *
 * @return			1 always
 */
native int L4D_RestartScenarioFromVote(const char[] map);

/**
 * @brief Gets the max versus completion score for the map
 * @remarks Can only be called 1 frame after OnMapStart at the earliest otherwise the addresses are invalid - Since version 1.133 Left4DHooks will block these calls and log an error
 *
 * @return			The map's max completion distance (map distance score)
 */
native int L4D_GetVersusMaxCompletionScore();

/**
 * @brief Sets the max versus completion score for the map
 * @remarks Can only be called 1 frame after OnMapStart at the earliest otherwise the addresses are invalid - Since version 1.133 Left4DHooks will block these calls and log an error
 *
 * @param score		The versus max completion score to set for the round
 */
native int L4D_SetVersusMaxCompletionScore(int score);

/**
 * @brief Get the team scores for the current map
 * @remarks The campaign scores are not set until the end of round 2,
 *			use L4D_GetCampaignScores to get them earlier
 *
 * @deprecated This function can be called through SDKTools using CTerrorGameRules,
 *			and so you should switch off to using SDKTools instead of this native
 *
 * @param logical_team		L4D1: 1 for A, 2 for B. L4D1: 1-6 (Maybe something like: 1: Your team 1. 2: Enemy team. 3: Survivor completion percentage. 4: Health bonus. 5: Completion percentage. 6: Total score at round end.)
 * @param campaign_score	true to get campaign score instead of map score
 *
 * @return			the logical team's map score
 *					or -1 if the team hasn't played the round yet,
 *					or the team's campaign score if campaign_score = true
 */
native int L4D_GetTeamScore(int logical_team, bool campaign_score=false);

/**
 * @brief Tells if the Mission (map) is the first map of the campaign
 *
 * @return			true if the map is the first map of the campaign
 */
native bool L4D_IsFirstMapInScenario();

/**
 * @brief Tells if the Mission (map) is the final map of the campaign
 *
 * @param anyMap	True to return true if any map is a finale, not just the last map of a campaign (useful for campaigns that have multiple finale maps)
 *
 * @return			true if the map is the last map of the campaign (finale)
 */
native bool L4D_IsMissionFinalMap(bool anyMap = false);

/**
 * @brief Notifies the CGameRulesProxy that the game state has been changed
 * @remarks Use this function before changing networked members of GameRules,
 *			like with L4D_SetVersusMaxCompletionScore()
 *
 * @noreturn
 */
native void L4D_NotifyNetworkStateChanged();

/**
 * @brief Trigger's a target player's stagger behaviour
 * @remarks Works on any CTerrorPlayer--survivor or infected
 *
 * @param target 		Player to stagger
 * @param source_ent	Source of the stagger (another player, etc)
 * @param vecSource		Source location of the stagger. If NULL_VECTOR, origins of source_ent is used
 *
 * @noreturn
 */
native void L4D_StaggerPlayer(int target, int source_ent, const float vecSource[3]);

/**
 * @brief Calls CDirectorScriptedEventManager::SendInRescueVehicle(void)
 * @remarks Calls in the rescue vehicle
 * @remarks will fire the forward of the same function
 *
 * @noreturn
 */
native void L4D2_SendInRescueVehicle();

/**
 * @brief Calls CDirectorScriptedEventManager::ChangeFinaleStage(CDirectorScriptedEventManager FinaleStageType,char const*)
 * @remarks Changes the Finale stage
 * @remarks some values for FinaleStageType: 1 - Finale Started; 6 - Rescue Vehicle Ready; 7 - Zombie Hordes; 8 - Tank; 10 - Combat Respite (nothing spawns)
 * @remarks will fire the forward of the same function
 * @remarks Can use the "FINALE_*" enums (search for them above) for the finaleType value
 *
 * @param FinaleStageType	integer value
 *
 * @noreturn
 */
// L4D2 only
native void L4D2_ChangeFinaleStage(any finaleType, const char[] arg);

/**
 * @brief Calls ZombieManager::ReplaceTank(CTerrorPlayer *,CTerrorPlayer *)
 * @remarks Replaces a players tank control with another player
 *
 * @param tank		the player who was a tank
 * @param newtank	a player who will become a new tank
 */
native void L4D_ReplaceTank(int tank, int newtank);

/**
 * @brief Calls ZombieManager::SpawnTank(Vector&,QAngle&)
 *
 * @param vecPos	Vector coordinate where the tank will be spawned
 * @param vecAng	QAngle where the tank will be facing
 *
 * @return			Entity index of the spawned tank
 */
native int L4D2_SpawnTank(const float vecPos[3], const float vecAng[3]);

/**
 * @brief Calls ZombieManager::SpawnSpecial(ZombieClassType,Vector&,QAngle&)
 * @remarks Only used for bot special spawns (not players)
 *
 * @param vecPos	Vector coordinate where the SI will be spawned
 * @param vecAng	QAngle where the SI will be facing
 *
 * @return			Entity index of the spawned SI
 */
native int L4D2_SpawnSpecial(int zombieClass, const float vecPos[3], const float vecAng[3]);

/**
 * @brief Calls ZombieManager::SpawnWitch(Vector&,QAngle&)
 *
 * @param vecPos	Vector coordinate where the witch will be spawned
 * @param vecAng	QAngle where the witch will be facing
 *
 * @return			Entity index of the spawned witch
 */
native int L4D2_SpawnWitch(const float vecPos[3], const float vecAng[3]);

/**
 * @brief Calls ZombieManager::SpawnWitchBride(Vector&,QAngle&)
 *
 * @param vecPos	Vector coordinate where the witch bride will be spawned
 * @param vecAng	QAngle where the witch bride will be facing
 *
 * @return			Entity index of the spawned witch bride
 */
// L4D2 only
native int L4D2_SpawnWitchBride(const float vecPos[3], const float vecAng[3]);

/**
 * @brief Removes lobby reservation from a server
 * @remarks Sets the reservation cookie to 0, it is safe to call this even if it's unreserved
 *
 * @noreturn
 */
native void L4D_LobbyUnreserve();

/**
 * @brief Checks if the server is currently reserved for a lobby
 * @remarks Server is automatically unreserved if it hibernates or if all players leave
 *
 * @return			true if reserved, false if not reserved
 */
native bool L4D_LobbyIsReserved();

/**
 * @brief Returns the lobby reservation ID
 *
 * @param reservation	String to store the reservation ID to
 * @param maxlength		Maximum length of the string to store to
 *
 * @noreturn
 */
native void L4D_GetLobbyReservation(char [] reservation, int maxlength);

/**
 * @brief Sets the lobby reservation ID
 *
 * @param reservation	The reservation ID to set
 *
 * @noreturn
 */
native void L4D_SetLobbyReservation(char reservation[20]);

/**
 * @brief Get the current campaign scores stored in the Director
 * @remarks The campaign scores are updated after L4D_OnSetCampaignScores
 *
 * @deprecated This will set the scores to -1 for both sides on L4D2,
 *				this function is no longer supported
 *
 * @param scoreA	score of logical team A
 * @param scoreB	score of logical team B
 *
 * @return			1 always
 */
#pragma deprecated Use GetTeamScore and OnClearTeamScores instead
native int L4D_GetCampaignScores(int &scoreA, int &scoreB);

/**
 * @brief Get the time remaining before the next director horde
 * @remarks This timer is used for scripted event hordes and natural timed hordes
 *
 * @return			Time remaining before next director horde
 */
#pragma deprecated Use L4D2_CTimerGetRemainingTime(L4D2CT_MobSpawnTimer)
native float L4D_GetMobSpawnTimerRemaining();

/**
 * @brief Get the duration the horde timer was set to after the last horde
 * @remarks This timer is used for scripted event hordes and natural timed hordes
 *
 * @return			Total time from last horde to next horde
 */
#pragma deprecated Use L4D2_CTimerGetCountdownDuration(L4D2CT_MobSpawnTimer)
native float L4D_GetMobSpawnTimerDuration();





// ====================================================================================================
// NATIVES - l4d2director.inc (and new ones by Silvers)
// ====================================================================================================
/**
 * @brief Gets the number of tanks currently in play
 * @remarks This value is tracked by the director, and should be a good
 *		indicator that a tank is in play
 *
 * @return			Current Tank count
 */
native int L4D2_GetTankCount();

/**
 * @brief Gets the number of witches currently in play
 * @remarks This value is tracked by the director, and should be a good
 *		indicator that a witch is in play
 *
 * @return			Current Witch count
 */
native int L4D2_GetWitchCount();

/**
 * @brief Returns the current map chapter number of the campaign
 *
 * @return			Map chapter
 */
native int L4D_GetCurrentChapter();

/**
 * @brief Returns the maximum number of chapters for the current game mode
 * @remarks Can only be called 1 frame after OnMapStart at the earliest otherwise the addresses are invalid - Since version 1.133 Left4DHooks will block these calls and log an error
 *
 * @return			Max chapters
 */
native int L4D_GetMaxChapters();

/**
 * @brief Returns all TheNavAreas addresses
 * @remarks Can only be called 1 frame after OnMapStart at the earliest otherwise the addresses are invalid - Since version 1.133 Left4DHooks will block these calls and log an error
 *
 *param aList		The ArrayList to store all nav area addresses
 *
 * @noreturn
 */
native void L4D_GetAllNavAreas(ArrayList aList);

/**
 * @brief Returns a given NavArea's ID from it's address
 * @remarks Can only be called 1 frame after OnMapStart at the earliest otherwise the addresses are invalid - Since version 1.133 Left4DHooks will block these calls and log an error
 *
 *param area		The NavArea address
 *
 * @return			NavArea ID
 */
native int L4D_GetNavAreaID(Address area);

/**
 * @brief Returns a given NavArea address from it's ID
 * @remarks Can only be called 1 frame after OnMapStart at the earliest otherwise the addresses are invalid - Since version 1.133 Left4DHooks will block these calls and log an error
 *
 *param id			The NavArea ID
 *
 * @return			NavArea address or Address_Null if invalid ID
 */
native Address L4D_GetNavAreaByID(int id);

/**
 * @brief Returns origin of a given NavArea
 *
 *param area		The address of the NavArea to read
 *param vecPos		The vector to store the position read
 *
 * @noreturn
 */
native void L4D_GetNavAreaPos(Address area, float vecPos[3]);

/**
 * @brief Returns center of a given NavArea
 *
 *param area		The address of the NavArea to read
 *param vecPos		The vector to store the center position
 *
 * @noreturn
 */
native void L4D_GetNavAreaCenter(Address area, float vecPos[3]);

/**
 * @brief Returns size of a given NavArea
 *
 *param area		The address of the NavArea to read
 *param vecPos		The vector to store the size read
 *
 * @noreturn
 */
native void L4D_GetNavAreaSize(Address area, float vecSize[3]);

/**
 * @brief  	Returns true if this area is connected to other area in given direction. (If you set direction to -1 or 4, it will automatically check all directions for a connection)
 *
 *param area1		The address of the first NavArea
 *param are2a		The address of the second NavArea
 *param direction	The direction to check in (NAV_NORTH, NAV_EAST, NAV_SOUTH, NAV_WEST, NAV_ALL) - provide value 1 to 4 only
 *
 * @noreturn
 */
native bool L4D_NavArea_IsConnected(Address area1, Address area2, int direction);

/**
 * @brief Returns the nav area attribute flags
 * @remarks See the "NAV_BASE_*" near the top of the include file
 *
 *param pTerrorNavArea		Pointer to a NavArea
 *
 * @return			Attribute flags
 */
native int L4D_GetNavArea_AttributeFlags(Address pTerrorNavArea);

/**
 * @brief Sets the nav area attribute flags
 * @remarks See the "NAV_BASE_*" near the top of the include file
 *
 *param pTerrorNavArea		Pointer to a NavArea
 *param flags				Attribute flags to set
 *
 * @return			Attribute flags
 */
native void L4D_SetNavArea_AttributeFlags(Address pTerrorNavArea, int flags);

/**
 * @brief Returns the terror nav area attribute flags
 * @remarks See the "NAV_SPAWN_*" near the top of the include file
 *
 *param pTerrorNavArea		Pointer to a TerrorNavArea
 *
 * @return			Attribute flags
 */
native int L4D_GetNavArea_SpawnAttributes(Address pTerrorNavArea);

/**
 * @brief Sets the terror nav area attribute flags
 * @remarks See the "NAV_SPAWN_*" near the top of the include file
 *
 *param pTerrorNavArea		Pointer to a TerrorNavArea
 *param flags				Attribute flags to set
 *
 * @noreturn
 */
native void L4D_SetNavArea_SpawnAttributes(Address pTerrorNavArea, int flags);

/**
 * @brief Gets the campaign scores stored in the Versus Director
 * @remarks These are the actual values used for campaign scores--not proxies
 *
 * @param scores 	Array to store the campaign scores in
 * @noreturn
 */
// L4D2 only
native void L4D2_GetVersusCampaignScores(int scores[2]);

/**
 * @brief Sets the campaign scores stored in the Versus Director
 * @remarks These are the actual values used for campaign scores--not proxies
 *
 * @param scores 	Array of campaign scores to set the director's values to
 * @noreturn
 */
// L4D2 only
native void L4D2_SetVersusCampaignScores(const int scores[2]);

/**
 * @brief Gets the flow percent for tank spawns for both versus rounds
 * @remarks These values are checked against as the survivors move through the
 *		map. Once they are passed, the tank spawns. Note that this is flow
 *		as a percent of the map's flow, not flow distance
 *
 * @param tankFlows		Array to store the Tank Spawn Flow percents in director
 * @noreturn
 */
// L4D2 only
native void L4D2_GetVersusTankFlowPercent(float tankFlows[2]);

/**
 * @brief Sets the flow percent for tank spawns for both versus rounds
 * @remarks These values are checked against as the survivors move through the
 *		map. Once they are passed, the tank spawns. Note that this is flow
 *		as a percent of the map's flow, not flow distance
 *
 * @param tankFlows		Array of Tank Spawn Flow percents to store in director
 * @noreturn
 */
// L4D2 only
native void L4D2_SetVersusTankFlowPercent(const float tankFlows[2]);

/**
 * @brief Gets the flow percent for witch spawns for both versus rounds
 * @remarks These values are checked against as the survivors move through the
 *		map. Once they are passed, the witch spawns. Note that this is flow
 *		as a percent of the map's flow, not flow distance
 *
 * @param witchFlows	Array to store the Witch Spawn Flow percents in director
 * @noreturn
 */
// L4D2 only
native void L4D2_GetVersusWitchFlowPercent(float witchFlows[2]);

/**
 * @brief Sets the flow percent for witch spawns for both versus rounds
 * @remarks These values are checked against as the survivors move through the
 *		map. Once they are passed, the witch spawns. Note that this is flow
 *		as a percent of the map's flow, not flow distance
 *
 * @param witchFlows	Array of Witch Spawn Flow percents to store in director
 * @noreturn
 */
// L4D2 only
native void L4D2_SetVersusWitchFlowPercent(const float witchFlows[2]);





// ====================================================================================================
// NATIVES - l4d2timers.inc
// ====================================================================================================
enum L4D2CountdownTimer
{
	L4D2CT_MobSpawnTimer,
	L4D2CT_SmokerSpawnTimer,
	L4D2CT_BoomerSpawnTimer,
	L4D2CT_HunterSpawnTimer,
	L4D2CT_SpitterSpawnTimer,
	L4D2CT_JockeySpawnTimer,
	L4D2CT_ChargerSpawnTimer,
	L4D2CT_VersusStartTimer,
	L4D2CT_UpdateMarkersTimer,
	L4D2CT_SurvivalSetupTimer
};

enum L4D2IntervalTimer
{
	L4D2IT_SmokerDeathTimer,
	L4D2IT_BoomerDeathTimer,
	L4D2IT_HunterDeathTimer,
	L4D2IT_SpitterDeathTimer,
	L4D2IT_JockeyDeathTimer,
	L4D2IT_ChargerDeathTimer
};



/*************************************
	CountdownTimer Natives
***********************************/
/**
 * @brief Resets a given CountdownTimer (start again with same duration)
 * @remarks Equivalent to Start(timer, GetCountdownDuration(timer))
 *
 * @param timer 		CountdownTimer to reset
 * @noreturn
 */
// L4D2 only
native void L4D2_CTimerReset(L4D2CountdownTimer timer);

/**
 * @brief Starts a given CountdownTimer with a given duration
 * @remarks This sets a new duration and sets up the end timestamp
 *
 * @param timer 		CountdownTimer to start
 * @param duration		Duration for the timer to use
 * @noreturn
 */
// L4D2 only
native void L4D2_CTimerStart(L4D2CountdownTimer timer, float duration);

/**
 * @brief Invalidates a given CountdownTimer (Timer essentially does not run)
 * @remarks Sets the timestamp to -1.0f
 *
 * @param timer 		CountdownTimer to Invalidate
 * @noreturn
 */
// L4D2 only
native void L4D2_CTimerInvalidate(L4D2CountdownTimer timer);

/**
 * @brief Tells if a given CountdownTimer has started
 * @remarks Checks to see if the end timestamp is greater than 0.0f
 *
 * @param timer 		CountdownTimer to check
 *
 * @return				true if timer has started, false if timer is not started/invalid
 */
// L4D2 only
native bool L4D2_CTimerHasStarted(L4D2CountdownTimer timer);

/**
 * @brief Tells if a given CountdownTimer is elapsed
 * @remarks If a timer is "up," e.g duration has passed since start, this returns true;
 *
 * @param timer 		CountdownTimer to check
 *
 * @return				true if timer has elapsed or timer invalid/not started, false otherwise
 */
// L4D2 only
native bool L4D2_CTimerIsElapsed(L4D2CountdownTimer timer);

/**
 * @brief Gets elapsed time of a given CountdownTimer, from the timed it was started
 * @remarks Value is (Now() - timestamp) + duration
 *
 * @param timer 		CountdownTimer to get elapsed time of
 *
 * @return				float amount of time since timer started
 */
// L4D2 only
native float L4D2_CTimerGetElapsedTime(L4D2CountdownTimer timer);

/**
 * @brief Gets remaining time on a given CountdownTimer
 * @remarks Value is (timestamp - Now())
 *
 * @param timer 		CountdownTimer to get remaining time of
 *
 * @return				float amount of time remaining on the timer
 */
// L4D2 only
native float L4D2_CTimerGetRemainingTime(L4D2CountdownTimer timer);

/**
 * @brief Gets the duration of a given CountdownTimer
 * @remarks Value is (timestamp > 0.0f ? duration 0.0f)
 *
 * @param timer 		CountdownTimer to get duration of
 *
 * @return				0.0 for invalid/not started timers, timer duration otherwise
 */
// L4D2 only
native float L4D2_CTimerGetCountdownDuration(L4D2CountdownTimer timer);



/*************************************
	IntervalTimer Natives
***********************************/

/**
 * @brief Starts a given IntervalTimer
 * @remarks Just sets timestamp = Now(), so counting starts from now
 *
 * @param timer 		IntervalTimer to start
 *
 * @noreturn
 */
// L4D2 only
native void L4D2_ITimerStart(L4D2IntervalTimer timer);

/**
 * @brief Invalidates a given IntervalTimer
 * @remarks Just sets timestamp = -1.0f
 *
 * @param timer 		IntervalTimer to Invalidate
 * @noreturn
 */
// L4D2 only
native void L4D2_ITimerInvalidate(L4D2IntervalTimer timer);

/**
 * @brief Tells whether a given IntervalTimer has started
 * @remarks Checks to see if timestamp > 0.0f
 *
 * @param timer 		IntervalTimer to check
 *
 * @return				true if timer is started, false if it is invalid/not started
 */
// L4D2 only
native bool L4D2_ITimerHasStarted(L4D2IntervalTimer timer);

/**
 * @brief Gets the elapsed time of a given IntervalTimer
 * @remarks Value is Now() - Timestamp
 *
 * @param timer 		IntervalTimer to get elapsed time of
 *
 * @return				Elapsed time if timer started and valid, 99999.9f otherwise
 */
// L4D2 only
native float L4D2_ITimerGetElapsedTime(L4D2IntervalTimer timer);





// ====================================================================================================
// NATIVES - l4d2weapons.inc
// ====================================================================================================
/*
 * 2020 Update1: Use the "Info Editor" plugin by Silvers to edit the weapon scripts and increase clip size
 * 2020 Update2: Now works in Left4DHooks. Glitchy animation bug when reloading an already full weapon
 * 2021 Update3: Fix plugin for modified ammo clips found here: https://forums.alliedmods.net/showthread.php?t=327105

	A note regarding Clipsize: Any non-standard value will NOT be in effect at weapon pickup, which means the client
	has to reload once to achieve the modified value. To fix this, add a weapon pickup hook in your plugin (eg "player_use")
	and use something like this with a small timer delay of 0.1 seconds or more (dont you love this engine)

	int weapon = GetPlayerWeaponSlot(client, 0);
	if( weapon == INVALID_ENT_REFERENCE ) return;
	char class[56];
	GetEdictClassname(weapon, class, sizeof(class));
	SetEntProp(weapon, Prop_Send, "m_iClip1", L4D2_GetIntWeaponAttribute(class, L4D2IWA_ClipSize));
*/
enum L4D2IntWeaponAttributes
{
	L4D2IWA_Damage,
	L4D2IWA_Bullets,
	L4D2IWA_ClipSize,
	L4D2IWA_Bucket,
	L4D2IWA_Tier, // L4D2 only
	L4D2IWA_DefaultSize, // Default weapon clip size
	L4D2IWA_WeaponType, // Can use with the "WeaponType" enum
	MAX_SIZE_L4D2IntWeaponAttributes
};

enum L4D2FloatWeaponAttributes
{
	L4D2FWA_MaxPlayerSpeed,
	L4D2FWA_SpreadPerShot,
	L4D2FWA_MaxSpread,
	L4D2FWA_SpreadDecay,
	L4D2FWA_MinDuckingSpread,
	L4D2FWA_MinStandingSpread,
	L4D2FWA_MinInAirSpread,
	L4D2FWA_MaxMovementSpread,
	L4D2FWA_PenetrationNumLayers,
	L4D2FWA_PenetrationPower,
	L4D2FWA_PenetrationMaxDist,
	L4D2FWA_CharPenetrationMaxDist,
	L4D2FWA_Range,
	L4D2FWA_RangeModifier,
	L4D2FWA_CycleTime,
	L4D2FWA_PelletScatterPitch,
	L4D2FWA_PelletScatterYaw,
	L4D2FWA_VerticalPunch,
	L4D2FWA_HorizontalPunch, // Requires "z_gun_horiz_punch" cvar changed to "1"
	L4D2FWA_GainRange,
	L4D2FWA_ReloadDuration,
	MAX_SIZE_L4D2FloatWeaponAttributes
};

// L4D2 only
enum L4D2BoolMeleeWeaponAttributes
{
	L4D2BMWA_Decapitates,
	MAX_SIZE_L4D2BoolMeleeWeaponAttributes
};

// L4D2 only
enum L4D2IntMeleeWeaponAttributes
{
	L4D2IMWA_DamageFlags,
	L4D2IMWA_RumbleEffect,
	MAX_SIZE_L4D2IntMeleeWeaponAttributes
};

// L4D2 only
enum L4D2FloatMeleeWeaponAttributes
{
	L4D2FMWA_Damage,
	L4D2FMWA_RefireDelay,
	L4D2FMWA_WeaponIdleTime,
	MAX_SIZE_L4D2FloatMeleeWeaponAttributes
};



/**
 * @brief Returns the weapon ID for a specific classname
 * @remarks Can specify either "rifle" or "weapon_rifle" for example
 *
 * @param weaponName 	Weapon classname to check up on
 *
 * @return				-1 if not found, otherwise returns weaponID
 */
native int L4D_GetWeaponID(const char[] weaponName);

/**
 * @brief Checks for a given weapon string to exist in the WeaponInformationDatabase
 * @remarks Throws an error if Database is unavailable
 *
 * @param weaponName 	Weapon to check up on
 *
 * @return				True if weapon is found, false if not
 */
native bool L4D2_IsValidWeapon(const char[] weaponName);

/**
 * @brief Read an int-typed attribute for a given weapon from the WeaponInformationDatabase
 * @remarks Throws an error if the weapon is not found or the attribute is incorrect
 *
 * @param weaponName 	Weapon to lookup attribute for
 * @param attr			Attribute to read from the weapon's info struct
 *
 * @return				The value read
 */
native any L4D2_GetIntWeaponAttribute(const char[] weaponName, L4D2IntWeaponAttributes attr);

/**
 * @brief Read a float-typed attribute for a given weapon from the WeaponInformationDatabase
 * @remarks Throws an error if the weapon is not found or the attribute is incorrect
 *
 * @param weaponName 	Weapon to lookup attribute for
 * @param attr			Attribute to read from the weapon's info struct
 *
 * @return				The value read
 */
native float L4D2_GetFloatWeaponAttribute(const char[] weaponName, L4D2FloatWeaponAttributes attr);

/**
 * @brief Set an int-typed attribute for a given weapon from the WeaponInformationDatabase to a given value
 * @remarks Throws an error if the weapon is not found or the attribute is incorrect
 *
 * @param weaponName 	Weapon to lookup attribute for
 * @param attr			Attribute to alter in the weapon's info struct
 * @param value			Value to set the attribute to
 *
 * @noreturn
 */
native void L4D2_SetIntWeaponAttribute(const char[] weaponName, L4D2IntWeaponAttributes attr, int value);

/**
 * @brief Set a float-typed attribute for a given weapon from the WeaponInformationDatabase to a given value
 * @remarks Throws an error if the weapon is not found or the attribute is incorrect
 *
 * @param weaponName 	Weapon to lookup attribute for
 * @param attr			Attribute to alter in the weapon's info struct
 * @param value			Value to set the attribute to
 *
 * @noreturn
 */
native void L4D2_SetFloatWeaponAttribute(const char[] weaponName, L4D2FloatWeaponAttributes attr, float value);



/**
 * @brief Retrieve the index for a given melee weapon from the Melee Weapon Database
 * @remarks Can only be called 1 frame after OnMapStart at the earliest otherwise the addresses are invalid - Since version 1.133 Left4DHooks will block these calls and log an error
 * @remarks Index can change depending on available melee weapons each map
 *
 * @param weaponName 	Weapon to lookup index id for
 *
 * @return				The index id. Returns -1 if no match is found or melee unavailable
 */
// L4D2 only
native int L4D2_GetMeleeWeaponIndex(const char[] weaponName);

/**
 * @brief Read an int-typed attribute for a given id from the Melee Weapon Database
 * @remarks Throws an error if the id is not found or the attribute is incorrect
 *
 * @param id 			Melee id to lookup attribute for
 * @param attr			Attribute to read from the weapon's info struct
 *
 * @return				The value read
 */
// L4D2 only
native int L4D2_GetIntMeleeAttribute(int id, L4D2IntMeleeWeaponAttributes attr);

/**
 * @brief Read a float-typed attribute for a given id from the Melee Weapon Database
 * @remarks Throws an error if the id is not found or the attribute is incorrect
 *
 * @param id 			Melee id to lookup attribute for
 * @param attr			Attribute to read from the weapon's info struct
 *
 * @return				The value read
 */
// L4D2 only
native float L4D2_GetFloatMeleeAttribute(int id, L4D2FloatMeleeWeaponAttributes attr);

/**
 * @brief Read a bool-typed attribute for a given id from the Melee Weapon Database
 * @remarks Throws an error if the id is not found or the attribute is incorrect
 *
 * @param id 			Melee id to lookup attribute for
 * @param attr			Attribute to read from the weapon's info struct
 *
 * @return				The value read
 */
// L4D2 only
native bool L4D2_GetBoolMeleeAttribute(int id, L4D2BoolMeleeWeaponAttributes attr);

/**
 * @brief Set an int-typed attribute for a given id from the Melee Weapon Database to a given value
 * @remarks Throws an error if the id is not found or the attribute is incorrect
 *
 * @param id 			Melee id to lookup attribute for
 * @param attr			Attribute to alter in the weapon's info struct
 * @param value			Value to set the attribute to
 *
 * @noreturn
 */
// L4D2 only
native void L4D2_SetIntMeleeAttribute(int id, L4D2IntMeleeWeaponAttributes attr, int value);

/**
 * @brief Set a float-typed attribute for a given id from the Melee Weapon Database to a given value
 * @remarks Throws an error if the id is not found or the attribute is incorrect
 *
 * @param id 			Melee id to lookup attribute for
 * @param attr			Attribute to alter in the weapon's info struct
 * @param value			Value to set the attribute to
 *
 * @noreturn
 */
// L4D2 only
native void L4D2_SetFloatMeleeAttribute(int id, L4D2FloatMeleeWeaponAttributes attr, float value);

/**
 * @brief Set a bool-typed attribute for a given id from the Melee Weapon Database to a given value
 * @remarks Throws an error if the id is not found or the attribute is incorrect
 *
 * @param id 			Melee id to lookup attribute for
 * @param attr			Attribute to alter in the weapon's info struct
 * @param value			Value to set the attribute to
 *
 * @noreturn
 */
// L4D2 only
native void L4D2_SetBoolMeleeAttribute(int id, L4D2BoolMeleeWeaponAttributes attr, bool value);





// ====================================================================================================
// NATIVES - l4d2_direct.inc
// ====================================================================================================
enum CountdownTimer
{
	CTimer_Null = 0 /**< Invalid Timer when lookup fails */
};

enum IntervalTimer
{
	ITimer_Null = 0 /**< Invalid Timer when lookup fails */
};



/* CDirector Variable access */

/**
 * Get the current Tank count stored by the director
 *
 * @note This should work on any gamemode, and is a good check to see if there is a tank in play
 *
 * @return			The current number of tanks in play
 * @error			Director address not found
 */
native int L4D2Direct_GetTankCount();

/**
 * Returns the number of infected waiting to spawn
 *
 * @return					Mob size
 */
native int L4D2Direct_GetPendingMobCount();

/**
 * Sets the number of infected waiting to spawn
 *
 * @param count				Mob size
 *
 * @noreturn
 */
native void L4D2Direct_SetPendingMobCount(int count);

/**
 * Get a reference to the CDirector natural mob spawn CountdownTimer
 * @note This timer is used to control the spawning of natural hordes
 * @note This timer gets reset during unnatural hordes as well (boomer/car alarm hordes)
 * @note Some scripted events will effectively "take over", by reducing the mob spawn time
 *
 * @return				CountdownTimer reference to the timer, or CTimer_Null on lookup failure
 */
native CountdownTimer L4D2Direct_GetMobSpawnTimer();

/**
 * Get a reference to a IntervalTimer that counts up from the last death of a given SI class
 * @note The main place I've seen these timers used is in the SI spawning algorithms (CDirector::UpdateSpecialSpawns)
 * @note This timer gets checked against SI respawn interval for different gamemodes, some of which are cvar controlled (e.g. versus_special_respawn_interval)
 *
 * @param class		SI Class to retrieve timer for
 *
 * @return			IntervalTimer reference to the timer, or ITimer_Null on lookup failure or bad class
 */
// L4D2 only
native IntervalTimer L4D2Direct_GetSIClassDeathTimer(int class);

/**
 * Get a reference to a CountdownTimer that counts down from the last attempted director-controlled spawn of an SI
 * @note The main place I've seen these timers used is in the SI spawning algorithms (CDirector::UpdateSpecialSpawns)
 * @note This timer is hard-coded to use a duration of 20.0s
 *
 * @param class		SI Class to retrieve timer for
 *
 * @return			CountdownTimer reference to the timer, or CTimer_Null on lookup failure or bad class
 */
// L4D2 only
native CountdownTimer L4D2Direct_GetSIClassSpawnTimer(int class);

/**
 * Gets the number of times the tank has passed to a player
 * @note When this variable is >1 the tank will be replaced with a bot when the his frustration reaches 0
 * @note The initial pass from AI to a player counts as a pass
 * @note As this is global on the director weird things could potentially happen if more than one tank is alive at a time with z_frustration 1
 *
 * @return			The number of passes
 */
native int L4D2Direct_GetTankPassedCount();

/**
 * Sets the number of times the tank has passed to a player
 * @note When this variable is >1 the tank will be replaced with a bot when the his frustration reaches 0
 * @note The initial pass from AI to a player counts as a pass
 * @note As this is global on the director weird things could potentially happen if more than one tank is alive at a time with z_frustration 1
 *
 * @param passes		New number of passes value
 *
 * @noreturn
 */
native void L4D2Direct_SetTankPassedCount(int passes);



/* CDirectorVersusMode Variable access */

/**
 * Reads the director's stored campaign score for a given team
 *
 * @note You can use the gamerules m_bAreTeamsFlipped property to figure out team numbers
 * @note The campaign scores value is also stored in gamerules, however this is the "master" version
 * @note Campaign scores are only updated on round end, so this will not reflect current survivor distance score
 *
 * @param teamNumber	Team number to read campaign score of, 0 or 1
 *
 * @return				Campaign score for the given team
 * @error				Director or Versus Director address not found
 */
native int L4D2Direct_GetVSCampaignScore(int teamNumber);

/**
 * Set the director's stored campaign score for a given team
 *
 * @note You can use the gamerules m_bAreTeamsFlipped property to figure out team numbers
 * @note The campaign scores value is also stored in gamerules, however this is the "master" version
 * @note Keep in mind the current survivor team's distance/bonus score will be added at the end of a round
 *
 * @param teamNumber	Team number to set campaign score of, 0 or 1
 * @param score			Score to set for the team
 *
 * @noreturn
 * @error				Director or Versus Director address not found
 */
native void L4D2Direct_SetVSCampaignScore(int teamNumber, int score);

/**
 * Reads the tank flow percent for a given round for versus mode
 *
 * @note You should check GetVSTankToSpawnThisRound to find out if a tank is going to be spawned for this round
 * @note When the survivors reach this flow percent minus versus_boss_buffer converted to flow percent, a tank will spawn
 *
 * @param roundNumber	Round number to read tank spawn flow percent of
 *
 * @return				Tank spawn flow percent for the given round
 * @error				Director or Versus Director address not found
 */
native float L4D2Direct_GetVSTankFlowPercent(int roundNumber);

/**
 * Sets the tank flow percent for a given round for versus mode
 *
 * @note You should check GetVSTankToSpawnThisRound to find out if there is still a tank to spawn this round
 * @note When the survivors reach this flow percent minus versus_boss_buffer converted to flow percent, a tank will spawn
 *
 * @param roundNumber	Round number to set tank spawn flow percent of
 * @param flow			Floating point percent of flow distance
 *
 * @noreturn
 * @error				Director or Versus Director address not found
 */
native void L4D2Direct_SetVSTankFlowPercent(int roundNumber, float flow);

/**
 * Is there going to be a tank spawned during the given round
 *
 * @param roundNumber	Round number to check for tank spawn on
 *
 * @return				True if there is still a tank to spawn for the given round, false if it has already been spawned or will not spawn
 * @error				Director or Versus Director address not found
 */
native bool L4D2Direct_GetVSTankToSpawnThisRound(int roundNumber);

/**
 * Tell the director whether or not to spawn a(nother) flow distance-based tank for this round
 * @note If you set this to true after a flow-distance-based tank has been spawned, this can trigger another tank to be spawned based on flow distance
 *
 * @param roundNumber	Round number to set a tank spawn on
 * @param spawn			Whether or not to spawn a flow-distance-based tank for this round
 *
 * @noreturn
 * @error				Director or Versus Director address not found
 */
native void L4D2Direct_SetVSTankToSpawnThisRound(int roundNumber, bool spawn);

/**
 * Reads the witch flow percent for a given round for versus mode
 *
 * @note You should check GetVSWitchToSpawnThisRound to find out if a witch is going to be spawned for this round
 * @note When the survivors reach this flow percent minus versus_boss_buffer converted to flow percent, a witch will spawn
 *
 * @param roundNumber	Round number to read witch spawn flow percent of
 *
 * @return				Witch spawn flow percent for the given round
 * @error				Director or Versus Director address not found
 */
native float L4D2Direct_GetVSWitchFlowPercent(int roundNumber);

/**
 * Sets the witch flow percent for a given round for versus mode
 *
 * @note You should check GetVSWitchToSpawnThisRound to find out if there is still a witch to spawn this round
 * @note When the survivors reach this flow percent minus versus_boss_buffer converted to flow percent, a witch will spawn
 *
 * @param roundNumber	Round number to set witch spawn flow percent of
 * @param flow			Floating point percent of flow distance
 *
 * @noreturn
 * @error				Director or Versus Director address not found
 */
native void L4D2Direct_SetVSWitchFlowPercent(int roundNumber, float flow);

/**
 * Is there going to be a witch spawned during the given round
 *
 * @param roundNumber	Round number to check for witch spawn on
 *
 * @return				True if there is still a witch to spawn for the given round, false if it has already been spawned or will not spawn
 * @error				Director or Versus Director address not found
 */
native bool L4D2Direct_GetVSWitchToSpawnThisRound(int roundNumber);

/**
 * Tell the director whether or not to spawn a(nother) flow distance-based witch for this round
 * @note If you set this to true after a flow-distance-based witch has been spawned, this can trigger another witch to be spawned based on flow distance
 *
 * @param roundNumber	Round number to set a witch spawn on
 * @param spawn			Whether or not to spawn a flow-distance-based witch for this round
 *
 * @noreturn
 * @error				Director or Versus Director address not found
 */
native void L4D2Direct_SetVSWitchToSpawnThisRound(int roundNumber, bool spawn);

/**
 * Get a reference to the VersusStart CountdownTimer
 * @note This timer controls when the saferoom door will open and PZ spawning is enabled
 * @note The default duration for this timer is controlled by cvar: versus_force_start_time
 *
 * @return				CountdownTimer reference to the timer, or CTimer_Null on lookup failure
 * @error				Director address not found
 */
// L4D2 only
native CountdownTimer L4D2Direct_GetVSStartTimer();



/* CDirectorScavengeMode Variable access */

/**
 * Get a reference to the Scavenge Round Setup CountdownTimer
 * @note This timer controls when the scavenge "warmup" time ends and PZ/game timers start
 * @note The default duration for this timer is controlled by cvar: scavenge_round_setup_time
 *
 * @return				CountdownTimer reference to the timer, or CTimer_Null on lookup failure
 * @error				Director address not found
 */
// L4D2 only
native CountdownTimer L4D2Direct_GetScavengeRoundSetupTimer();

/**
 * Get a reference to the Scavenge Overtime Grace CountdownTimer
 * @note This timer keeps track of how long survivors have gone without holding a can during overtime
 * @note The default duration for this timer is controlled by cvar: scavenge_overtime_grace_time
 *
 * @return				CountdownTimer reference to the timer, or CTimer_Null on lookup failure
 * @error				Director address not found
 */
// L4D2 only
native CountdownTimer L4D2Direct_GetScavengeOvertimeGraceTimer();



/* TerrorNavMesh Variable access */

/**
 * Get the max flow distance (in flow units) for the current map
 * @note The flow distance for each map is generated as it is loaded, and it can change slightly (a few hundred units) with each load
 * @note You can use this value to convert a flow distance to a flow percent, and vice versa
 *
 * @return				Max flow distance for the current loaded map
 * @error				TerrorNavMesh address not found
 */
native float L4D2Direct_GetMapMaxFlowDistance();



/* CTerrorPlayer Variable access */

/**
 * Get a reference to a CountdownTimer that tracks when an SI player can next spawn
 * @note The duration of this timer is controlled by the cvars z_ghost_delay_min and z_ghost_delay_max
 * @remarks It is advised to use the "L4D_GetPlayerSpawnTime" native instead of this
 *
 * @param client		Client id to get the spawn timer for
 *
 * @return				CountdownTimer reference to the timer, or CTimer_Null on lookup failure
 * @error				Invalid client
 */
// L4D2 only
native CountdownTimer L4D2Direct_GetSpawnTimer(int client);

/**
 * Get a reference to a CountdownTimer that tracks when an survivor player is invulnerable due to "godframes"
 *
 * @param client		Client id to get the godframes timer for
 *
 * @return				CountdownTimer reference to the timer, or CTimer_Null on lookup failure
 * @error				Invalid client
 */
native CountdownTimer L4D2Direct_GetInvulnerabilityTimer(int client);

/**
 * Looks up the number of tickets a client has for entry into the tank lottery
 * @note The number of tickets you have is equal to your damage done as an SI and will still increase as you do damage with the Tank
 * @note When the tank is passed away from you your tickets are set back to zero
 *
 * @param client		Client id to get the tickets for
 *
 * @return				Number of tickets
 * @error				Invalid client
 */
native int L4D2Direct_GetTankTickets(int client);

/**
 * Sets the number of tickets a player has for entry into the tank lottery
 *
 * @param client		Client id to set the tickets for
 * @param tickets		New value for the client's tank lottery tickets
 *
 * @noreturn
 * @error				Invalid client
 */
native void L4D2Direct_SetTankTickets(int client, int tickets);

/**
 * Gets a client's shove penalty
 * @note The returned value will be between 0 and z_gun_swing_{vs,coop}_max_penalty
 *
 * @param client		Client id
 *
 * @return				Shove penalty or -1 on error
 */
// L4D2 only
#pragma deprecated Use this instead: GetEntProp(client, Prop_Send, "m_iShovePenalty");
native int L4D2Direct_GetShovePenalty(int client);

/**
 * Sets a client's shove penalty
 * @note The penalty should be set between 0 and z_gun_swing_{vs,coop}_max_penalty
 *
 * @param client		Client id
 * @param penalty		Shove penalty
 *
 * @noreturn
 */
// L4D2 only
#pragma deprecated Use this instead: SetEntProp(client, Prop_Send, "m_iShovePenalty", penalty);
native void L4D2Direct_SetShovePenalty(int client, int penalty);

/**
 * Gets the time at which a survivor can perform his next +attack2
 *
 * @param client		Client id
 *
 * @return				Time or 0.0 on error
 */
// L4D2 only
native float L4D2Direct_GetNextShoveTime(int client);

/**
 * Sets the time at which a survivor can perform his next +attack2
 *
 * @param client		Client id
 * @param time			Game time
 *
 * @noreturn
 */
// L4D2 only
native void L4D2Direct_SetNextShoveTime(int client, float time);

/**
 * Gets the health of the survivor from before they were incapacitated
 * @note This may only apply to hanging players
 *
 * @param client		Client id
 *
 * @return				Real health before incapacitation
 */
// L4D2 only
native int L4D2Direct_GetPreIncapHealth(int client);

/**
 * Sets the health of the survivor from before they were incapacitated
 * @note This may only apply to hanging players
 *
 * @param client		Client id
 * @param health		New pre-incap health
 *
 * @noreturn
 */
// L4D2 only
native void L4D2Direct_SetPreIncapHealth(int client, int health);

/**
 * Gets the temporary health of the survivor from before they were incapacitated
 * @note This may only apply to hanging players
 *
 * @param client		Client id
 * @return				Temporary health before incapacitation
 */
// L4D2 only
native int L4D2Direct_GetPreIncapHealthBuffer(int client);

/**
 * Sets the health of the survivor from before they were incapacitated
 * @note This may only apply to hanging players
 *
 * @param client		Client id
 * @param health		New pre-incap temporary health
 *
 * @noreturn
 */
// L4D2 only
native void L4D2Direct_SetPreIncapHealthBuffer(int client, int health);

/**
 * Gets the maximum number of flames a CInferno is allowed to spawn
 *
 * @param entity		Entity id
 *
 * @return				Number of flames or -1 on error
 */
// L4D2 only
native int L4D2Direct_GetInfernoMaxFlames(int entity);

/**
 * Sets the maximum number of flames a CInferno is allowed to spawn
 *
 * @param entity		Entity id
 * @param flames		Number of flames
 *
 * @noreturn
 */
// L4D2 only
native void L4D2Direct_SetInfernoMaxFlames(int entity, int flames);

/**
 * Returns the CDirectorScriptedEventManager address
 * This native replicates "L4D2_GetCDirectorScriptedEventManager" used by other plugins
 *
 * @return				Address pointer
 */
// L4D2 only
native any L4D2Direct_GetScriptedEventManager();

/**
 * Get the TerrorNavArea which holds a specific position
 * @note Some positions will not return a nav area (Address_Null). Notable examples are saferooms and small ledges like the guard rail at the start of c2m1_highway
 * @remarks This is less reliable than L4D_GetNearestNavArea
 *
 * @param pos			The position to find the containing nav area of
 * @param beneathLimit
 *
 * @return				Address to a TerrorNavArea or Address_Null
 * @error				Unable to prepare SDK call
 */
native Address L4D2Direct_GetTerrorNavArea(float pos[3], float beneathLimit = 120.0);

/**
 * Find the distance through the map (in flow units) that a TerrorNavArea is located
 *
 * @param pTerrorNavArea	Pointer to a TerrorNavArea
 *
 * @return					The flow units through the map that the TerrorNavArea is located at
 * @error					When passed an Address_Null
 */
native float L4D2Direct_GetTerrorNavAreaFlow(Address pTerrorNavArea);

/**
 * Force the director to pass the tank
 *
 * @param client			Client index of the tank
 * @param bEnterStasis		Should the tank be put in stasis
 *
 * @return					False on error otherwise true
 */
native bool L4D2Direct_TryOfferingTankBot(int client, int bEnterStasis);

/**
 * Gets a player's distance in flow units
 *
 * @param client			Client ID
 *
 * @return					0.0 on error otherwise flow distance
 */
native float L4D2Direct_GetFlowDistance(int client);

/**
 * Plays the specified animation for a player
 * @note The event argument is NOT the same as the sequence numbers found in the model viewer
 * @note You can get the number for your animation by looking at the disasm for virtual calls to DoAnimationEvent
 *
 * @param client		Client ID to do animation
 * @param event			Animation index (PlayerAnimEvent_t)
 *
 * @noreturn
 */
native void L4D2Direct_DoAnimationEvent(int client, any event, int variant_param = 0);

/**
 * Get the clients health bonus
 *
 * @note Survivors health bonuses are 0 until CTerrorPlayer:RecalculateVersusScore(void) calculates it
 *
 * @param client		Client id whose health bonus is to be returned
 *
 * @return				Int value of the survivors health bonus
*/
// L4D1 only
native int L4DDirect_GetSurvivorHealthBonus(int client);

/**
 * Sets the clients health bonus
 *
 * @note Keep in mind the individual survivors health bonus will be recalculate again when CTerrorPlayer:RecalculateVersusScore(void) is invoked
 * @note L4D_OnRecalculateVersusScore(client) forward (left4downtown exts) can block health bonus from being calculated to store your own value with this function
 *
 * @param client		Client id to set the health bonus for
 * @param health		Number of health bonus
 * @param recompute		If true, L4DDirect_RecomputeTeamScores() is called after the health bonus has been set
 * @noreturn
 * @error				Invalid client
*/
// L4D1 only
native void L4DDirect_SetSurvivorHealthBonus(int client, int health, bool recompute = true);

/**
 * Compute the scores on the scoreboard
 *
 * @noparam
 * @return					False on error otherwise true
 * @error					SDK call preparation failed
 */
// L4D1 only
native void L4DDirect_RecomputeTeamScores();



/* CountdownTimer funcs */

/**
 * Reset a CountdownTimer to begin counting down again from now to its original duration
 *
 * @param timer				CountdownTimer to reset
 *
 * @noreturn
 */
native void CTimer_Reset(CountdownTimer timer);

/**
 * Start a CountdownTimer from now for a given duration
 *
 * @param timer				CountdownTimer to reset
 * @param duration			Duration for this CountdownTimer to use, in seconds
 *
 * @noreturn
 */
native void CTimer_Start(CountdownTimer timer, float duration);

/**
 * Invalidate a CountdownTimer, so it is considered not running
 *
 * @param timer				CountdownTimer to Invalidate
 *
 * @noreturn
 */

native void CTimer_Invalidate(CountdownTimer timer);

/**
 * Determine if a CountdownTimer has started counting down
 *
 * @param timer				CountdownTimer to check
 *
 * @return					True if it has started running, False if it is not (Invalidated)
 */
native bool CTimer_HasStarted(CountdownTimer timer);

/**
 * Determine if a CountdownTimer is elapsed
 *
 * @param timer				CountdownTimer to check
 *
 * @return					True if the timer's duration has passed since it started, false otherwise
 */
native bool CTimer_IsElapsed(CountdownTimer timer);

/**
 * Check how long a CountdownTimer has been running
 *
 * @param timer				CountdownTimer to check
 *
 * @return					Time since the CountdownTimer was last Started or Reset, in seconds
 */
native float CTimer_GetElapsedTime(CountdownTimer timer);

/**
 * Check how much time remains before a CountdownTimer is elapsed
 *
 * @param timer				CountdownTimer to check
 *
 * @return					Time until the CountdownTimer is elapsed, in seconds
 */
native float CTimer_GetRemainingTime(CountdownTimer timer);

/**
 * Get the countdown duration used for a CountdownTimer
 *
 * @param timer				CountdownTimer to check
 *
 * @return					Countdown duration in seconds if timer is running, or 0.0 if timer is invalidated (not running)
 */
native float CTimer_GetCountdownDuration(CountdownTimer timer);

/* IntervalTimer funcs */

/**
 * Reset an IntervalTimer to begin counting up again from now
 *
 * @param timer				IntervalTimer to reset
 *
 * @noreturn
 */
native void ITimer_Reset(IntervalTimer timer);

/**
 * Start an IntervalTimer to begin counting up from now
 *
 * @note This is the same as reset for IntervalTimers
 *
 * @param timer				IntervalTimer to start
 *
 * @noreturn
 */
native void ITimer_Start(IntervalTimer timer);

/**
 * Invalidate an IntervalTimer, so it is considered not running
 *
 * @param timer				IntervalTimer to Invalidate
 *
 * @noreturn
 */
native void ITimer_Invalidate(IntervalTimer timer);

/**
 * Check if an IntervalTimer has started
 *
 * @param timer				IntervalTimer to check
 *
 * @return					True if the IntervalTimer is running, false if it is Invalidated
 */
native bool ITimer_HasStarted(IntervalTimer timer);

/**
 * Get the elapsed time of an IntervalTimer
 *
 * @param timer				IntervalTimer to check
 *
 * @return					Elapsed time of the IntervalTimer in seconds if it has started, or 99999.9 ("infinite") if it is Invalidated
 */
native float ITimer_GetElapsedTime(IntervalTimer timer);



/* Timer Internals */

/**
 * Read duration variable in CTimer
 *
 * @param timer				CountdownTimer to check
 *
 * @return					CountdownTimer duration value
 */
native float CTimer_GetDuration(CountdownTimer timer);

/**
 * Set duration variable in CTimer
 *
 * @param timer				CountdownTimer to check
 * @param duration			Duration to set
 *
 * @noreturn
 */
native void CTimer_SetDuration(CountdownTimer timer, float duration);

/**
 * Read timestamp variable in CTimer
 *
 * @param timer				CountdownTimer to check
 *
 * @return					CountdownTimer duration value
 */
native float CTimer_GetTimestamp(CountdownTimer timer);

/**
 * Set timestamp variable in CTimer
 *
 * @param timer				CountdownTimer to check
 * @param timestamp			Timestamp to set
 *
 * @noreturn
 */
native void CTimer_SetTimestamp(CountdownTimer timer, float timestamp);

/**
 * Read timestamp variable in ITimer
 *
 * @param timer				IntervalTimer to check
 *
 * @return					IntervalTimer duration value
 */
native float ITimer_GetTimestamp(IntervalTimer timer);

/**
 * Set timestamp variable in ITimer
 *
 * @param timer				IntervalTimer to check
 * @param timestamp			Timestamp to set
 *
 * @noreturn
 */
native void ITimer_SetTimestamp(IntervalTimer timer, float timestamp);





// ====================================================================================================
// NATIVES - l4d2addresses.txt
// ====================================================================================================
/**
 * @brief Creates the boomer vomit effect on Survivors or Special infected
 *
 * @param client			Client ID of the person to affect
 * @param attacker			Client ID who caused the blindness, can be the same as client
 *
 * @noreturn
 */
native void L4D_CTerrorPlayer_OnVomitedUpon(int client, int attacker);

/**
 * @brief Creates the boomer vomit effect on Survivors or Special infected
 *
 * @param client			Client ID of the person to affect
 * @param attacker			Client ID who caused the blindness, can be the same as client
 *
 * @noreturn
 */
// L4D2 only
native void L4D2_CTerrorPlayer_OnHitByVomitJar(int client, int attacker);

/**
 * @brief Creates the boomer vomit effect on Common infected
 *
 * @param entity			Entity ID of the common to affect
 * @param attacker			Client ID who caused the blindness, can be the same as client
 *
 * @noreturn
 */
// L4D2 only
native void L4D2_Infected_OnHitByVomitJar(int entity, int attacker);

/**
 * @brief Flings a player to the ground, like they were hit by a Charger
 *
 * @param client			Client ID of the person to affect
 * @param attacker			Client ID who caused the attack, can be the same as client
 * @param vecDir			Vector direction to throw the player
 *
 * @noreturn
 */
// L4D2 only
native void L4D2_CTerrorPlayer_Fling(int client, int attacker, const float vecDir[3]);

/**
 * @brief Cancels a player staggering
 *
 * @param client			Client ID of the person to affect
 *
 * @noreturn
 */
native void L4D_CancelStagger(int client);

/**
 * @brief Finds the Use client/entity if available
 * @remarks See the "L4D1_FirstAidKit_StartHealing" and "L4D2_BackpackItem_StartAction" pre hook forwards for examples of usage and games range values
 *
 * @param client			Client ID of the person to check
 * @param players			True = only search for players, false = search for any use entity
 * @param range				Maximum distance to search for a usable entity
 *
 * @return					Entity index or maybe 0 or -1 if none (not validated). May return an attached entity on the client (for example prop_dynamic) or other nearby entities
 */
native int L4D_FindUseEntity(int client, bool players = false, float range = 96.0);

/**
 * @brief Forces a Hunter to pin a victim
 *
 * @param victim			Client index of the Survivor affect
 * @param attacker			Client index of the client attacking the Survivor
 *
 * @noreturn
 */
native void L4D_ForceHunterVictim(int victim, int attacker);

/**
 * @brief Forces a Smoker to grab a victim with their tongue
 *
 * @param victim			Client index of the Survivor affect
 * @param attacker			Client index of the client attacking the Survivor
 *
 * @noreturn
 */
native void L4D_ForceSmokerVictim(int victim, int attacker);

/**
 * @brief Forces a Jockey to pin a victim
 *
 * @param victim			Client index of the Survivor affect
 * @param attacker			Client index of the client attacking the Survivor
 *
 * @noreturn
 */
native void L4D2_ForceJockeyVictim(int victim, int attacker);

/**
 * @brief Flings a Survivor like when they're flung by a nearby Charger impact
 * @remarks	attacker can be the same client index as victim
 *
 * @param victim			Client index of the Survivor affect
 * @param attacker			Client index of the client attacking the Survivor
 *
 * @noreturn
 */
// L4D2 only
native void L4D2_Charger_ThrowImpactedSurvivor(int victim, int attacker);

/**
 * @brief Makes a Charger carry a Survivor
 * @remarks The Survivor is teleported after 0.3 seconds to position in the Chargers arms, the position is not perfect and could do with tweaking
 * @remarks It seems like the Survivor is colliding with the Charger. If anyone fixes this please report the changes required
 *
 * @param victim			Client index of the Survivor to affect
 * @param attacker			Client index of the Charger attacking the Survivor
 *
 * @noreturn
 */
// L4D2 only
native void L4D2_Charger_StartCarryingVictim(int victim, int attacker);

/**
 * @brief Makes a Charger pummel a Survivor
 *
 * @param victim			Client index of the Survivor to affect
 * @param attacker			Client index of the Charger attacking the Survivor
 *
 * @noreturn
 */
// L4D2 only
native void L4D2_Charger_PummelVictim(int victim, int attacker);

/**
 * @brief Makes a Charger stop pummelling a Survivor
 *
 * @param victim			Client index of the Survivor to affect
 * @param attacker			Client index of the Charger attacking the Survivor
 *
 * @noreturn
 */
// L4D2 only
native void L4D2_Charger_EndPummel(int victim, int attacker);

/**
 * @brief Makes a Charger stop carrying a Survivor
 *
 * @param victim			Client index of the Survivor to affect
 * @param attacker			Client index of the Charger
 *
 * @noreturn
 */
// L4D2 only
native void L4D2_Charger_EndCarry(int victim, int attacker);

/**
 * @brief Makes a Jockey stop riding a Survivor
 *
 * @param victim			Client index of the Survivor to affect
 * @param attacker			Client index of the Jockey
 *
 * @noreturn
 */
// L4D2 only
native void L4D2_Jockey_EndRide(int victim, int attacker);

/**
 * @brief Makes a Hunter end pounce on a Survivor
 *
 * @param victim			Client index of the Survivor to affect
 * @param attacker			Client index of the Hunter
 *
 * @noreturn
 */
native void L4D_Hunter_ReleaseVictim(int victim, int attacker);

/**
 * @brief Makes a Smoker stop hanging a Survivor from it's tongue
 *
 * @param victim			Client index of the Survivor to affect
 * @param attacker			Client index of the Smoker
 *
 * @noreturn
 */
native void L4D_Smoker_ReleaseVictim(int victim, int attacker);

/**
 * @brief Spawns all dead survivors in rescuable rooms
 * @remarks L4D1: Any survivor must not be in the starting area for it to work
 * @remarks L4D2: Any survivor must have left the starting area for it to work, they can return and all be in the starting area
 * @remarks By default the game would spawn one per frame, but I've added a RequestFrame loop to spawn all dead. Request if you want a singular spawn native
 *
 * @noreturn
 */
native void L4D_CreateRescuableSurvivors();

/**
 * @brief Revives an incapacitated survivor, also from ledge hanging
 *
 * @param client			Client ID of the person to affect
 *
 * @noreturn
 */
native void L4D_ReviveSurvivor(int client);

/**
 * @brief Retrieve a clients map flow progress percentage. Doesn't have to be Versus mode
 * @remarks Can only be called 1 frame after OnMapStart at the earliest otherwise the addresses are invalid - Since version 1.133 Left4DHooks will block these calls and log an error
 *
 * @param client			Client ID of the person to affect
 *
 * @return					Returns value from 0-100
 */
// L4D2 only
native int L4D2_GetVersusCompletionPlayer(int client);

/**
 * @brief Returns client who is furthest in flow
 *
 * @return					Client ID of the player furthest ahead
 */
native int L4D_GetHighestFlowSurvivor();

/**
 * @brief Retrieve the specified common infected map flow distance
 *
 * @param entity			Common infected ID
 *
 * @return					flow distance
 */
native float L4D_GetInfectedFlowDistance(int entity);

/**
 * @brief Takeover another special infected
 * @remarks L4D1: Due to some bug and a workaround, when spawning you'll hear another special infected sound other than your own type
 *
 * @param client			Client ID of the special infected taking over
 * @param target			Client ID of the special infected losing control
 *
 * @noreturn
 */
native void L4D_TakeOverZombieBot(int client, int target);

/**
 * @brief Replaces the player with a bot
 * @remarks Survivors: makes the player go into spectator mode and a bot takeover, like going idle
 * @remarks Infected: basically spawns an identical bot in your position. The client is forced into ghost mode
 *
 * @param client			Client ID of the player losing control
 *
 * @noreturn
 */
native void L4D_ReplaceWithBot(int client);

/**
 * @brief Kills the player. Teleports their view to a random survivor
 *
 * @param client			Client ID of the player to kill. Not common infected
 *
 * @noreturn
 */
native void L4D_CullZombie(int client);

/**
 * @brief Resets a players state equivalent to when they die
 * @remarks does stuff like removing any pounces, stops reviving, stops healing, resets hang lighting, resets heartbeat and other sounds
 *
 * @param client			Client ID to affect
 *
 * @noreturn
 */
native void L4D_CleanupPlayerState(int client);

/**
 * @brief Sets a players zombie class, special infected can be alive and change!
 * @remarks Valid values L4D1: 1-3. L4D2: 1-6
 * @remarks zombieClass: 1=Smoker, 2=Boomer, 3=Hunter, 4=Spitter, 5=Jockey, 6=Charger
 *
 * @param client			Client ID of the player to kill. Not common infected
 * @param zombieClass		Zombie class number to change to
 *
 * @noreturn
 */
native void L4D_SetClass(int client, int zombieClass);

/**
 * @brief Spawns a special infected from ghost state. Returns the clients "m_customAbility" weapon, or -1 on error (possibly not a ghost)
 *
 * @param client			Client ID of the player to materialize
 *
 * @return					Clients "m_customAbility" weapon entity ID or -1 on error
 */
native int L4D_MaterializeFromGhost(int client);

/**
 * @brief Turns an alive player into the ghost state
 *
 * @param client			Client ID of the player to affect
 *
 * @return					True on success, false on error or if already ghost state
 */
native bool L4D_BecomeGhost(int client);

/**
 * @brief Enter ghost/dead mode. Some state values may have different results. Unknown
 * @remarks 6 and 8 are commonly used by the game
 * @remarks Can use the "STATE_*" enums (search for them above)
 *
 * @param client			Client ID of the player to affect
 *
 * @noreturn
 */
native void L4D_State_Transition(int client, any state);

/**
 * @brief Swaps the teams in Versus
 * @remarks Some survivors may spawn dead on swapping, seems to be random
 *
 * @noreturn
 */
// L4D2 only
native void L4D2_SwapTeams();

/**
 * @brief Returns if Versus team are flipped
 *
 * @return					0=Not flipped. 1=Flipped
 */
#pragma deprecated Use this instead: GameRules_GetProp("m_bAreTeamsFlipped");
native bool L4D2_AreTeamsFlipped();

/**
 * @brief Ends a Versus round
 * @remarks This will only end the first round, calculating scores and swapping players to the other team
 *
 * @param countSurvivors		False = Survivors didn't make it to saferoom. True = Survivors made to the saferoom
 *
 * @noreturn
 */
native void L4D_EndVersusModeRound(bool countSurvivors);

/**
 * @brief Starts a Versus rematch vote like end of game before credits roll
 * @remarks Failing a successful vote players are kicked back to lobby
 *
 * @noreturn
 */
// L4D2 only
native void L4D2_StartRematchVote();

/**
 * @brief Passes a Versus rematch vote like end of game before credits roll
 * @remarks A failed vote would have kicked players back to lobby
 * @remarks Do not use this in conjunction with "L4D2_StartRematchVote"
 *
 * @noreturn
 */
// L4D2 only
native void L4D2_Rematch();

/**
 * @brief Seems to restart the chapter like "mp_restartgame". In Versus the teams flip
 *
 * @noreturn
 */
// L4D2 only
native void L4D2_FullRestart();

/**
 * @brief Hides end of round scoreboard
 *
 * @noreturn
 */
// L4D2 only
native void L4D2_HideVersusScoreboard();

/**
 * @brief Hides end of round scoreboard
 *
 * @noreturn
 */
// L4D2 only
native void L4D2_HideScavengeScoreboard();

/**
 * @brief Hides end of round scoreboard
 *
 * @noreturn
 */
// L4D2 only
native void L4D2_HideScoreboard();

/**
 * @brief NOT WORKING? Setup car alarm for object. Seems to have no affect. Only works on prop_breakable or prop_car_alarm?
 *
 * @return				Some memory address (large value) or possibly ID if already registered (low value from 1+)
 */
native int L4D_RegisterForbiddenTarget(int entity);

/**
 * @brief NOT WORKING? Remove car alarm for object. Seems to have no affect. Only works on prop_breakable or prop_car_alarm?
 *
 * @return				Some memory address (large value) or possibly ID if already registered (low value from 1+)
 */
native void L4D_UnRegisterForbiddenTarget(int entity);