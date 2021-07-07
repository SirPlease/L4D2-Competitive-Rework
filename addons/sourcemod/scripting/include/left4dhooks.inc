/**
 * vim  set ts=4
 * =============================================================================
 *
 * Left 4 Downtown 2 SourceMod Extension
 * Copyright (C) 2010 Michael "ProdigySim" Busby
 *
 * Left 4 Downtown SourceMod Extension
 * Copyright (C) 2009 Igor "Downtown1" Smirnov.
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
 * Left 4 DHooks SourceMod plugin
 * Copyright (C) 2020 "SilverShot" / "Silvers"
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

	MarkNativeAsOptional("L4D_Deafen");
	MarkNativeAsOptional("L4D_Dissolve");
	MarkNativeAsOptional("L4D_OnITExpired");
	MarkNativeAsOptional("L4D_AngularVelocity");
	MarkNativeAsOptional("L4D_GetRandomPZSpawnPosition");
	MarkNativeAsOptional("L4D_GetNearestNavArea");
	MarkNativeAsOptional("L4D_GetLastKnownArea");
	MarkNativeAsOptional("L4D2_GetFurthestSurvivorFlow");
	MarkNativeAsOptional("L4D_FindRandomSpot");
	MarkNativeAsOptional("L4D_HasAnySurvivorLeftSafeArea");
	MarkNativeAsOptional("L4D_IsAnySurvivorInStartArea");
	MarkNativeAsOptional("L4D_IsAnySurvivorInCheckpoint");
	MarkNativeAsOptional("L4D_IsInFirstCheckpoint");
	MarkNativeAsOptional("L4D_IsInLastCheckpoint");
	MarkNativeAsOptional("L4D2_IsReachable");
	MarkNativeAsOptional("L4D_HasPlayerControlledZombies");
	MarkNativeAsOptional("L4D_PipeBombPrj");

	MarkNativeAsOptional("L4D2_GetVScriptOutput");
	MarkNativeAsOptional("L4D2_SpitterPrj");
	MarkNativeAsOptional("L4D2_UseAdrenaline");
	MarkNativeAsOptional("L4D_RespawnPlayer");
	MarkNativeAsOptional("L4D_SetHumanSpec");
	MarkNativeAsOptional("L4D_TakeOverBot");
	MarkNativeAsOptional("L4D_CanBecomeGhost");
	MarkNativeAsOptional("L4D2_AreWanderersAllowed");
	MarkNativeAsOptional("L4D2_GetCurrentFinaleStage");
	MarkNativeAsOptional("L4D2_ForceNextStage");
	MarkNativeAsOptional("L4D2_IsTankInPlay");
	MarkNativeAsOptional("L4D2_GetScriptValueInt");
	MarkNativeAsOptional("L4D2_NavAreaTravelDistance");

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

	MarkNativeAsOptional("L4D_ScavengeBeginRoundSetupTime");
	MarkNativeAsOptional("L4D_ResetMobTimer");
	MarkNativeAsOptional("L4D_GetPlayerSpawnTime");
	MarkNativeAsOptional("L4D_GetVersusMaxCompletionScore");
	MarkNativeAsOptional("L4D_SetVersusMaxCompletionScore");
	MarkNativeAsOptional("L4D_GetTeamScore");
	MarkNativeAsOptional("L4D_GetMobSpawnTimerRemaining");
	MarkNativeAsOptional("L4D_GetMobSpawnTimerDuration");
	MarkNativeAsOptional("L4D2_ChangeFinaleStage");
	MarkNativeAsOptional("L4D2_SpawnWitchBride");

	// l4d2weapons.inc
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
	MarkNativeAsOptional("L4D_CancelStagger");
	MarkNativeAsOptional("L4D_CreateRescuableSurvivors");
	MarkNativeAsOptional("L4D_ReviveSurvivor");
	MarkNativeAsOptional("L4D_GetHighestFlowSurvivor");
	MarkNativeAsOptional("L4D_GetInfectedFlowDistance");
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
	MarkNativeAsOptional("L4D2_StartRematchVote");
	MarkNativeAsOptional("L4D2_FullRestart");
	MarkNativeAsOptional("L4D2_HideVersusScoreboard");
	MarkNativeAsOptional("L4D2_HideScavengeScoreboard");
	MarkNativeAsOptional("L4D2_HideScoreboard");
}
#endif





// ====================================================================================================
// ANIMATION HOOK
// ====================================================================================================
typeset AnimHookCallback
{
	/**
	 * @brief Callback called whenever animation is invoked.
	 *
	 * @param client		Client triggering.
	 * @param sequence		The animation "activity" (pre-hook) or "m_nSequence" (post-hook) sequence number being used.
	 *
	 * @return				Plugin_Changed to change animation, Plugin_Continue otherwise.
	 */
	function Action(int client, int &sequence);
}

/**
 * @brief Add a client animation hook.
 * @remarks All hooks are removed on map change.
 *
 * @param client			The client to hook
 * @param callback			Callback function for your pre-hook (uses "ACT_*" activity numbers) or INVALID_FUNCTION to not use.
 * @param callbackPost		Callback function for your post-hook (uses "m_nSequence" animation numbers) or INVALID_FUNCTION to not use.
 *
 * @return					True on success, false if client invalid.
 */
native bool AnimHookEnable(int client, AnimHookCallback callback, AnimHookCallback callbackPost = INVALID_FUNCTION);

/**
 * @brief Remove a client animation hook.
 * @remarks All hooks are removed on map change.
 *
 * @param client			The client to hook
 * @param callback			Callback function for your pre-hook (uses "ACT_*" activity numbers) or INVALID_FUNCTION if not used.
 * @param callbackPost		Callback function for your post-hook (uses "m_nSequence" animation numbers) or INVALID_FUNCTION if not used.
 *
 * @return					True on success, false if client invalid.
 */
native bool AnimHookDisable(int client, AnimHookCallback callback, AnimHookCallback callbackPost = INVALID_FUNCTION);

/**
 * @brief Retrieves the activity string from it's relative activity number.
 * @remarks activity numbers are different from a models "m_nSequence" animation numbers.
 * @remarks The ACT_* list and values are for Survivors and differ from other models. Use the "m_nSequence" value in a post hook for Special Infected.
 * @remarks The "m_nSequence" values for each model can be found using Left4Dead Authoring Tools > Model Viewer.
 *
 * @param sequence			Activity number to retrieve from
 * @param activity			Destination string to store the activity
 * @param maxlength			Size of destination string
 *
 * @return					True on success, false on failure to find.
 */
native bool AnimGetActivity(int sequence, char[] activity, int maxlength);

/**
 * @brief Retrieves the animation activity number from an activity string.
 *
 * @param activity			The activity string to retrieve from.
 *
 * @return					Activity number or -1 on failure.
 */
native int AnimGetFromActivity(char[] activity);





// ====================================================================================================
// FORWARDS - left4downtown.inc
// ====================================================================================================
/**
 * @brief Called whenever ZombieManager::SpawnSpecial(ZombieClassType,Vector&,QAngle&) is invoked
 * @remarks Only used for bot special spawns (not players)
 * @remarks zombieClass: 1=Smoker, 2=Boomer, 3=Hunter, 4=Spitter, 5=Jockey, 6=Charger
 *
 * @param zombieClass	Zombie class that will be spawned.
 * @param vecPos		Vector coordinate where special will be spawned
 * @param vecAng		QAngle where spcial will be facing
 *
 * @return				Plugin_Handled to block special from spawning,
 * 						Plugin_Changed to change the zombie class type to spawn, Plugin_Continue otherwise.
 */
forward Action L4D_OnSpawnSpecial(int &zombieClass, const float vecPos[3], const float vecAng[3]);

/**
 * @brief Called whenever ZombieManager::SpawnTank(Vector&,QAngle&) is invoked
 * @remarks Not invoked if z_spawn tank is used and it gives a ghosted/dead player tank
 *
 * @param vecPos		Vector coordinate where tank is spawned
 * @param vecAng		QAngle where tank will be facing
 *
 * @return				Plugin_Handled to block tank from spawning, Plugin_Continue otherwise.
 */
forward Action L4D_OnSpawnTank(const float vecPos[3], const float vecAng[3]);

/**
 * @brief Called whenever ZombieManager::SpawnWitch(Vector&,QAngle&) is invoked
 * @brief Called when a Witch spawns
 *
 * @param vecPos		Vector coordinate where witch is spawned
 * @param vecAng		QAngle where witch will be facing
 *
 * @return 				Plugin_Handled to block witch from spawning, Plugin_Continue otherwise.
 */
forward Action L4D_OnSpawnWitch(const float vecPos[3], const float vecAng[3]);

/**
 * @brief Called whenever ZombieManager::SpawnWitchBride(Vector&,QAngle&) is invoked
 * @brief Called when a Witch Bride spawns
 *
 * @param vecPos		Vector coordinate where witch is spawned
 * @param vecAng		QAngle where witch will be facing
 *
 * @return 				Plugin_Handled to block witch from spawning, Plugin_Continue otherwise.
 */
// L4D2 only.
forward Action L4D2_OnSpawnWitchBride(const float vecPos[3], const float vecAng[3]);

/**
 * @brief Called whenever CDirector::OnMobRushStart(void) is invoked
 * @remarks called on random hordes, mini and finale hordes, and boomer hordes, causes Zombies to attack
 *			Not called on "z_spawn mob", hook the console command and check arguments to catch plugin mobs
 *			This function is used to reset the Director's natural horde timer.
 *
 * @return				Plugin_Handled to block, Plugin_Continue otherwise
 */
forward Action L4D_OnMobRushStart();

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
 * @brief Called whenever ZombieManager::SpawnMob(int) is invoked
 * @remarks called on natural hordes & z_spawn mob, increases Zombie Spawn
 *			Queue, triggers player OnMobSpawned (vocalizations), sets horde
 *			direction, and plays horde music.
 *
 * @param amount		Amount of Zombies to add to Queue
 *
 * @return				Plugin_Handled to block, Plugin_Changed to use overwritten values from plugin, Plugin_Continue otherwise
 */
forward Action L4D_OnSpawnMob(int &amount);

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
 *
 * @param client		the client that has entered ghost mode
 */
forward void L4D_OnEnterGhostState(int client);

/**
 * @brief Called whenever IsTeamFull is invoked.
 * @remarks called when bots or players are joining a team
 *
 * @param team			Which team is being checked. 2=Survivors. 3=Special Infected.
 *
 * @return				Plugin_Handled to block changing team, Plugin_Continue otherwise.
 */
forward Action L4D_OnIsTeamFull(int team, bool &full);

/**
 * @brief Called whenever CTerrorGameRules::ClearTeamScores(bool) is invoked
 * @remarks 	This resets the map score at the beginning of a map, and by checking
 *			the campaign scores on a small timer you can see if they were reset as well.
 *
 * @param newCampaign	if true then this is a new campaign, if false a new chapter. Not used for L4D1.
 *
 * @return				Plugin_Handled to block scores from being cleared, Plugin_Continue otherwise. Does not block reset in L4D1.
 */
forward Action L4D_OnClearTeamScores(bool newCampaign);

/**
 * @brief Called whenever CTerrorGameRules::SetCampaignScores(int,int) is invoked
 * @remarks The campaign scores are updated after the 2nd round is completed
 *
 * @param scoreA		score of logical team A
 * @param scoreB		score of logical team B
 *
 * @return				Plugin_Handled to block campaign scores from being set, Plugin_Continue otherwise.
 */
forward Action L4D_OnSetCampaignScores(int &scoreA, int &scoreB);

/**
 * @brief Called whenever CDirector::OnFirstSurvivorLeftSafeArea is invoked
 * @remarks A versus round is started when survivors leave the safe room, or force started
 *			after 90 seconds regardless.
 *
 * @param client		the survivor that left the safe area first
 *
 * @return				Plugin_Handled to block round from being started, Plugin_Continue otherwise.
 */
forward Action L4D_OnFirstSurvivorLeftSafeArea(int client);

/**
 * @brief Called whenever CTerrorPlayer::GetCrouchTopSpeed() is invoked
 * @remarks Constantly called to get players max Crouch speed
 *
 * @param target		the client that its being called on (not changible)
 * @param retVal		what to override the return value with
 *
 * @return				Plugin_Handled to override return value, Plugin_Continue otherwise.
 */
forward Action L4D_OnGetCrouchTopSpeed(int target, float &retVal);

/**
 * @brief Called whenever CTerrorPlayer::GetRunTopSpeed() is invoked
 * @remarks Constantly called to get players max Run speed
 *
 * @param target		the client that its being called on (not changible)
 * @param retVal		what to override the return value with
 *
 * @return				Plugin_Handled to override return value, Plugin_Continue otherwise.
 */
forward Action L4D_OnGetRunTopSpeed(int target, float &retVal);

/**
 * @brief Called whenever CTerrorPlayer::GetWalkTopSpeed() is invoked
 * @remarks Constantly called to get players max Walk speed
 *
 * @param target		the client that its being called on (not changible)
 * @param retVal		what to override the return value with
 *
 * @return				Plugin_Handled to override return value, Plugin_Continue otherwise.
 */
forward Action L4D_OnGetWalkTopSpeed(int target, float &retVal);

/**
 * @brief Called whenever CDirector::GetScriptValue(const char*, int) is invoked
 * @remarks A script value is map specific
 *
 * @param key			the script's key name
 * @param retVal		what to override the return value with
 *
 * @return				Plugin_Handled to override return value, Plugin_Continue otherwise.
 */
// L4D2 only.
forward Action L4D_OnGetScriptValueInt(const char[] key, int &retVal);

/**
 * @brief Called whenever CDirector::GetScriptValue(const char*, float) is invoked
 * @remarks A script value is map specific
 *
 * @param key			the script's key name
 * @param retVal		what to override the return value with
 *
 * @return				Plugin_Handled to override return value, Plugin_Continue otherwise.
 */
// L4D2 only.
forward Action L4D_OnGetScriptValueFloat(const char[] key, float &retVal);

/**
 * @brief Called whenever CDirector::GetScriptValue(const char*, const char*, char*, int) is invoked
 * @remarks A script value is map specific
 *
 * @param key			the script's key name
 * @param defaultVal	default key return, usually empty
 * @param retVal		returned string
 *
 * @return				Plugin_Handled to override return value, Plugin_Continue otherwise.
 */
// L4D2 only.
forward Action L4D_OnGetScriptValueString(const char[] key, const char[] defaultVal, char retVal[128]);

/**
 * @brief Called whenever CTerrorGameRules::HasConfigurableDifficultySetting() is invoked
 * @remarks used to deny/allow difficulty changes in different game modes
 *
 * @param retVal		what to override the return value with. 1 to allow difficulty configuration, 0 to deny.
 *
 * @return				Plugin_Handled to override return value, Plugin_Continue otherwise.
 */
// L4D2 only.
forward Action L4D_OnHasConfigurableDifficulty(int &retVal);

/**
 * @brief Called whenever CTerrorGameRules::GetSurvivorSet(void) is invoked
 * @remarks Constantly called to get the survivor character set
 *
 * @param retVal		what to override the return value with
 *
 * @return				Plugin_Handled to override return value, Plugin_Continue otherwise.
 */
// L4D2 only.
forward Action L4D_OnGetSurvivorSet(int &retVal);

/**
 * @brief Called whenever CTerrorGameRules::FastGetSurvivorSet(void) is invoked
 * @remarks Constantly called to get the survivor character set
 *
 * @param retVal	what to override the return value with
 *
 * @return			Plugin_Handled to override return value, Plugin_Continue otherwise.
 */
// L4D2 only.
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
 * @return			Plugin_Handled to block reading map data, Plugin_Changed to use overwritten values from plugin, Plugin_Continue to continue to read from mission data.
 */
forward Action L4D_OnGetMissionVSBossSpawning(float &spawn_pos_min, float &spawn_pos_max, float &tank_chance, float &witch_chance);

/**
 * @brief Called whenever ZombieManager::ReplaceTank(CTerrorPlayer *,CTerrorPlayer *) is invoked
 * @remarks Not invoked if tank is bot
 *
 * @param tank			the player who was a tank
 * @param newtank		a player who has become a new tank
 */
forward void L4D_OnReplaceTank(int tank, int newtank);

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
 * @brief Called whenever CThrow::ActivateAbility(void) is invoked
 * @remarks Called when a tank throws a rock. Blocking this call will keep the tank from throwing a rock
 *
 * @param ability	ability_throw entity index
 *
 * @return			Plugin_Handled to block, Plugin_Continue otherwise
 */
forward Action L4D_OnCThrowActivate(int ability);

/**
 * @brief Called when CBaseAnimating::SelectWeightedSequence(int Activity) is invoked with tank attack activity
 * @remarks Called whenever a tank uses his primary (punch) or secondary (throw) attack (uses ACT_* activity numbers)
 *
 * This detour uses activity sequence numbers.
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
 * @return			Plugin_Handled to override return value, Plugin_Continue otherwise.
 */
forward Action L4D2_OnSelectTankAttackPre(int client, int &sequence);

/**
 * @brief Called when CBaseAnimating::SelectWeightedSequence(int Activity) is invoked with tank attack activity
 * @remarks Called whenever a tank uses his primary (punch) or secondary (throw) attack (uses m_nSequence animation numbers)
 *
 * This detour uses models m_nSequence numbers.
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
 * @return			Plugin_Handled to override return value, Plugin_Continue otherwise.
 */
forward Action L4D2_OnSelectTankAttack(int client, int &sequence);

/**
 * @brief Called whenever CTerrorMeleeWeapon::StartMeleeSwing(CTerrorPlayer *, bool) is invoked
 * @remarks Called when a player uses his melee weapons primary attack. This is before the game
 *			reads the melee weapon data (model etc) and decides if he CAN attack at all.
 *
 * @return			Plugin_Handled to block, Plugin_Continue otherwise
 */
// L4D2 only.
forward Action L4D_OnStartMeleeSwing(int client, bool boolean);

/**
 * @brief Called whenever CDirectorScriptedEventManager::SendInRescueVehicle(void) is invoked
 * @remarks Called when the last Finale stage is reached and the Rescue means becomes 'available'.
 *			Take note this forward WILL fire upon using the native of the same function.
 *
 * @return			Plugin_Handled to block, Plugin_Continue otherwise
 */
// 2020 Left4DHooks update: Blocked on L4D1/L4D2 Linux to prevent crashes. Waiting for DHooks update to support object returns.
forward Action L4D2_OnSendInRescueVehicle();

/**
 * @brief Called whenever CDirectorScriptedEventManager::ChangeFinaleStage is invoked
 *
 * @param FinaleStageType	integer value
 * @remarks Called when the director stage changes
 * @remarks some values for FinaleStageType: 1 - Finale Started; 6 - Rescue Vehicle Ready; 7 - Zombie Hordes; 8 - Tank; 10 - Combat Respite (nothing spawns)
 * @remarks SendInRescueVehicle does not depend on Finale Stage being 6, that only signals endless Hordes/Tanks
 *
 * @return			Plugin_Handled to block, Plugin_Changed to change finaleType, Plugin_Continue otherwise
 */
// L4D2 only.
forward Action L4D2_OnChangeFinaleStage(int &finaleType, const char[] arg);

/**
 * @brief Called whenever CDirectorVersusMode::EndVersusModeRound(bool) is invoked
 * @remarks Called before score calculations and the scoreboard display
 *
 * @param countSurvivors	True if the survival multiplier count needs to be nonzero. I guess.
 * @remarks Not sure what bool does exactly yet. Just monitor it. If true, survivors will be counted for multiplier. If false, survival multiplier will be set to 0.
 * @remarks A lot of Score calculations happen on this function, and the round-end scoreboard comes up doing this. Don't block unless you're sure you can reproduce this logic.
 *
 * @return			Plugin_Handled to block, Plugin_Continue otherwise
 */
forward Action L4D2_OnEndVersusModeRound(bool countSurvivors);

/**
 * @brief Called after CDirectorVersusMode::EndVersusModeRound(bool)
 * @remarks Called after all score calculations are complete and the scoreboard shows
 * @remarks Called after all score calculations inside CDirectorVersusMode::EndVersusModeRound(bool). This good forward to replace standard "round_end" hook.
 *
 * @return			noreturn
 */
forward void L4D2_OnEndVersusModeRound_Post();

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
 * @brief Called when CTerrorPlayer::OnRevived(void) is invoked
 * @remarks Called post-revive so all data values are post-revive status.
 *
 * @param client	the client that has been revived
 *
 * @noreturn
 */
forward void L4D2_OnRevived(int client);

/**
 * @brief Called whenever CTerrorPlayer::OnStaggered(CBaseEntity *, Vector const *) is invoked
 * @remarks Source is always null for Charger impacts (Valve)
 *
 * @param target	the client that is about to get staggered
 * @param source	the client that is about to stagger the target
 *
 * @return			Plugin_Handled to block, Plugin_Continue otherwise
 */
forward Action L4D2_OnStagger(int target, int source);

/**
 * @brief Called whenever CTerrorPlayer::OnShovedBySurvivor(CTerrorPlayer, Vector&) is invoked
 * @remarks L4D2 only uses this on Special Infected
 * @remarks Blocks hunter dead stop
 *
 * @param client	the client that did the shoving
 * @param victim	the client that was shoved (CAUTION retrieved from function pointer, don't meddle with it)
 * @param vecDir	Vector Angle of Shoveforce
 *
 * @return			Plugin_Handled to block melee effect (staggering), Plugin_Continue otherwise.
 */
forward Action L4D_OnShovedBySurvivor(int client, int victim, const float vecDir[3]);

/**
 * @brief Called whenever CTerrorWeapon::OnHit(CGameTrace &, Vector const&, bool) is invoked
 * @remarks Called for every single shovable and even some of the unshovable entities in the game
 *
 * @param client	survivor who did the shoving
 * @param entity	entity that is about to get shoved
 * @param weapon	weapon that has been held while shoving
 * @param vecDir	stagger direction
 * @param bIsHighPounce		a boolean to determine if it was a pounce from a height or not; reliable to a certain degree and should only be considered for hunters
 * @param bIsHighPounce		sometimes reset to 0 when punched before the detour retrieves the information.
 *
 * @return			Plugin_Handled to block, Plugin_Continue otherwise
 */
forward Action L4D2_OnEntityShoved(int client, int entity, int weapon, float vecDir[3], bool bIsHighPounce);

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
// 2020 Left4DHooks update: Works for Molotovs and Spitters.
// return Plugin_Handled to make small fire or goo puddle.
// x,y,z has no affect, is 0,0,0 for spitter, molotovs is area size or something.
forward Action L4D2_OnSpitSpread(int spitter, int projectile, float &x, float &y, float &z);

/**
 * @brief Called when SurvivorBot::UseHealingItems(Action<SurvivorBot> *) is invoked
 * @remarks Causes bots to use or give healing items (except in safe room on non-expert)
 *
 * @param client	the client that will decide whether to use healing items
 *
 * @return			Plugin_Handled to block, Plugin_Continue otherwise.
 */
// 2020 Left4DHooks update: Blocked on L4D1/L4D2 Linux to prevent crashes. Waiting for DHooks update to support object returns.
forward Action L4D2_OnUseHealingItems(int client);

/**
 * @brief Called after SurvivorBot::FindScavengeItem(Action<SurvivorBot> *) is invoked
 * @remarks Indicates which item the Survivor Bot will attempt to pick up
 *
 * @param client	the client that will try to pick something up
 * @param item		the item the client will try to pick up (null means no item)
 *
 * @return			Plugin_Handled to block, Plugin_Changed to overwrite item, Plugin_Continue otherwise.
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
 * @brief Called whenever CTerrorPlayer::MaterializeFromGhost is invoked
 * @remarks Called when a Special Infected spawns out of ghost mode.
 *
 * @param victim			the client who spawned
 *
 * @return					Plugin_Handled to block, Plugin_Continue otherwise
 */
forward Action L4D_OnMaterializeFromGhostPre(int client);

/**
 * @brief Called whenever CTerrorPlayer::MaterializeFromGhost is invoked
 * @remarks Called when a Special Infected spawns out of ghost mode.
 *
 * @param victim			the client who spawned
 *
 * @noreturn
 */
forward Action L4D_OnMaterializeFromGhost(int client);

/**
 * @brief Called whenever CTerrorPlayer::OnVomitedUpon is invoked
 * @remarks Called when a Survivor player is covered in Boomer bile, or when using "Bile the World" plugin by "AtomicStryker"
 *
 * @param victim			the client who's now it
 * @param attacker			the attacker who caused the vomit
 *
 * @return					Plugin_Handled to block, Plugin_Changed to use overwritten values from plugin, Plugin_Continue otherwise
 */
forward Action L4D_OnVomitedUpon(int victim, int &attacker, bool &boomerExplosion);

/**
 * @brief Called whenever CTerrorPlayer::OnHitByVomitJar is invoked
 * @remarks Called a Special Infected is hit from a Bilejar explosion
 *
 * @param victim			the client who's now it
 * @param attacker			the attacker who caused the vomit
 * @param boomerExplosion	true if triggered by a boommer explosion
 *
 * @return					Plugin_Handled to block, Plugin_Changed to use overwritten values from plugin, Plugin_Continue otherwise
 */
forward Action L4D2_OnHitByVomitJar(int victim, int &attacker);

/**
 * @brief Called when the client's material system is expecting instructions from the server in regards to addons
 * @remarks Doesn't fire if l4d2_addons_eclipse is -1 or 0
 *
 * @param SteamID	SteamID of the client expecting a matsys reply
 *
 * @return			Plugin_Handled to let the client through with addons, Plugin_Continue otherwise.
 */
 // L4D2 only.
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
#pragma deprecated Does not return water state. Use FL_INWATER instead. See Swimming plugin for L4D/2.
forward void L4D2_OnWaterMove(int client);





// ====================================================================================================
// FORWARDS - Silvers
// ====================================================================================================
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
#pragma deprecated Removed because it spawns specials at 0,0,0 when modifying any value.
forward Action L4D_OnGetRandomPZSpawnPosition(int &client, int &zombieClass, int &attempts, float vecPos[3]);





// ====================================================================================================
// NATIVES - Silvers
// ====================================================================================================
/**
* @brief Runs a specified VScript code and returns values from it.
* @remarks Can execute several code blocks on a single line separating them with ; as standard coding practice.
* @remarks Can also execute several lines of code from SourcePawn, you must end the line with a backslash.
* @remarks Can return specific data by wrapping what you want to return within "<RETURN>" and "</RETURN>".
* @remarks See the test plugin for examples to all the above.
*
* @param	code			The VScript code to execute. Maximum length seems to be 1006 characters.
* @param	buffer			Buffer to copy return data to. You can use StringToInt or StringToFloat if required.
* @param	maxlength		Maximum size of the buffer.
*
* @return	True on success, false otherwise.
* @error	Invalid code or failed to create logic_script or possibly an empty string.
*/
// L4D2 only.
native bool L4D2_GetVScriptOutput(char[] code, char[] buffer, int maxlength);

/**
 * @brief Deafens a player with a high pitch ringing sound for a few seconds.
 * @remarks Used in the "Prototype Grenades" plugin by Silvers
 *
 * @param client	Client id of the player to deafen
 *
 * @noreturn
 */
native int L4D_Deafen(int client);

/**
 * @brief Creates the dissolve effect on common infected, players or objects.
 * @remarks You must handle the fading or killing of an entity as required
 * @remarks Used in the "Dissolve Infected" plugin by Silvers
 *
 * @param entity	The entity to dissolve.
 *
 * @return			Entity index of the dissolver, which should automatically delete itself when the effect is done
 */
native int L4D_Dissolve(int entity);

/**
 * @brief Removes the boomer vomit effect from a player.
 *
 * @param client	Client id of the player to remove the effect from
 * @param vecAng	Angular velocity vector, director to spin the projectile
 *
 * @noreturn
 */
native void L4D_OnITExpired(int client);

/**
 * @brief Sets a physics entity angular velocity vector.
 * @remarks Spins an entity, for example used in "Throwable Melee Weapons" plugin by Silvers
 * @remarks See the "left4dhooks_test" plugin for an example on spinning the entity top over or sideways
 *
 * @param entity	The entity to spin.
 * @param vecAng	Angular velocity vector, director to spin the projectile
 *
 * @noreturn
 */
native int L4D_AngularVelocity(int entity, const float vecAng[3]);

/**
 * @brief Attempts to find a random valid position to spawn a Special Infected.
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
 * @brief Given a vector position, returns the relative NavArea.
 * @remarks This is more reliable than L4D2Direct_GetTerrorNavArea.
 *
 * @param vecPos			The vector array to use to retrieve the NavArea
 *
 * @return					The NavArea value, or 0 on failure probably
 */
native int L4D_GetNearestNavArea(const float vecPos[3]);

/**
 * @brief Returns the nav address of the last known area.
 *
 * @param client			The client to check
 *
 * @return					The nav area adress or 0 on fail
 */
native int L4D_GetLastKnownArea(int client);

/**
 * @brief Gets the maximum flow distance any survivor has achieved.
 *
 * @return			Returns the maximum flow distance any survivor has achieved.
 */
// L4D2 only.
native float L4D2_GetFurthestSurvivorFlow();

/**
 * @brief Given a nav area value, returns a randomly selected position for spawning.
 * @remarks This is what Witches use to spawn.
 *
 * @param NavArea			The NavArea to search for a valid location
 * @param vecPos			The vector array to store the valid location on success
 *
 * @noreturn
 */
native void L4D_FindRandomSpot(int NavArea, float vecPos[3]);

/**
 * @brief Returns true when any survivor has left the starting area and true in Versus when the saferoom door automatically opens.
 *
 * @return			True if a survivor has left the starting area. False otherwise.
 */
native bool L4D_HasAnySurvivorLeftSafeArea();

/**
 * @brief Returns true when any survivor is in the starting checkpoint area.
 *
 * @return			True if any survivor is in the starting checkpoint area. False otherwise.
 */
native bool L4D_IsAnySurvivorInStartArea();

/**
 * @brief Returns true when any survivor is in the starting or ending checkpoint area.
 *
 * @return			True if a survivor is in the starting or ending checkpoint area. False otherwise.
 */
native bool L4D_IsAnySurvivorInCheckpoint();

/**
 * @brief Returns true when the specified Survivor or Special Infected is in the starting checkpoint area.
 *
 * @param client	Client id to check their checkpoint.
 *
 * @return			True if a survivor is in the starting checkpoint area. False otherwise.
 */
native bool L4D_IsInFirstCheckpoint(int client);

/**
 * @brief Returns true when the specified Survivor or Special Infected is in the ending checkpoint area.
 *
 * @param client	Client id to check their checkpoint.
 *
 * @return			True if a survivor is in the ending checkpoint area. False otherwise.
 */
native bool L4D_IsInLastCheckpoint(int client);

/**
 * @brief Checks if a world position is accessible to a Survivor bot.
 * @remarks You must pass a survivor bots client index into this, otherwise the plugin will attempt to find a bot or throw an error otherwise.
 * @remarks It appears the server will sometimes crash when passing a real players client index.
 * @remarks If the clients flow distance is too far away from the position to test it will return false.
 *
 * @param client	Client id to use for testing
 * @param vecPos	Vector coordinate to test
 *
 * @return			True if accessible, false otherwise
 */
// L4D2 only.
native bool L4D2_IsReachable(int client, const float vecPos[3]);

/**
 * @brief Returns if players can control infected.
 *
 * @return			True if players can control infected, false otherwise
 */
native bool L4D_HasPlayerControlledZombies();

/**
 * @brief Creates an activated PipeBomb projectile.
 * @remarks Does not attach the "Fuse" or "Light" particles, see the "left4dhooks_test" plugin for example on attaching these
 * @remarks Also used in the "PipeBomb Shove" plugin by Silvers
 *
 * @param client	Client id to attribute the projectile to for damage credit
 * @param vecPos	Vector coordinate of the projectile on creation
 * @param vecAng	Vector velocity and direction of the projectile
 *
 * @return			Entity index of the projectile
 */
native int L4D_PipeBombPrj(int client, const float vecPos[3], const float vecAng[3]);

/**
 * @brief Creates a Spitter goo projectile.
 *
 * @param client	Client id to attribute the projectile to for damage credit
 * @param vecPos	Vector coordinate of the projectile on creation
 * @param vecAng	Vector velocity and direction of the projectile
 *
 * @return			Entity index of the projectile
 */
// L4D2 only.
native int L4D2_SpitterPrj(int client, const float vecPos[3], const float vecAng[3]);

/**
 * @brief Gives the player adrenaline effect and health benefits.
 *
 * @param client	Client id to affect
 * @param fTime		Duration of screen effects (game default: 15.0 - Cvar: "adrenaline_duration")
 * @param heal		True = give health benefits and fire "adrenaline_used" event. False = only screen effects.
 *
 * @return			True on success, false otherwise
 */
// L4D2 only.
native void L4D2_UseAdrenaline(int client, float fTime = 15.0, bool heal = true);

/**
 * @brief Respawns a player from dead state.
 * @remarks Resets players stats for kills etc.
 * @remarks To preserve stats please view the code in "[L4D1 & L4D2] SM Respawn Improved" plugin by "Dragokas": https://forums.alliedmods.net/showthread.php?t=323220
 *
 * @param client			Client ID of the person to affect
 *
 * @noreturn
 */
native void L4D_RespawnPlayer(int client);

/**
 * @brief To takeover a Survivor bot. First use "ChangeClientTeam" and change them to 0. Then call "L4D_SetHumanSpec" then call "L4D_TakeOverBot".
 *
 * @return			True or false
 */
native int L4D_SetHumanSpec(int bot, int client);

/**
 * @brief To takeover a Survivor bot. First use "ChangeClientTeam" and change them to 0. Then call "L4D_SetHumanSpec" then call "L4D_TakeOverBot".
 *
 * @return			True or false
 */
native int L4D_TakeOverBot(int client);

/**
 * @brief Returns true when the "You will enter Spawn Mode in X seconds" text appears on the screen.
 *
 * @return			True or false
 */
native bool L4D_CanBecomeGhost(int client);

/**
 * @brief Returns if Wandering Witches are allowed.
 *
 * @return			True or false
 */
 // L4D2 only.
native bool L4D2_AreWanderersAllowed();

/**
 * @brief Returns true when the rescue vehicle is leaving until the screen fades and credits start.
 *
 * @return			True or false
 */
native bool L4D_IsFinaleEscapeInProgress();

/**
 * @brief Returns the current Finale stage type.
 * @remarks some values for FinaleStageType: 1 - Finale Started; 6 - Rescue Vehicle Ready; 7 - Zombie Hordes; 8 - Tank; 10 - Combat Respite (nothing spawns)
 * @remarks Seems to return 18 for non-finale maps
 *
 * @return			finaleType stage value
 */
// L4D2 only.
native int L4D2_GetCurrentFinaleStage();

/**
 * @brief Forces the ScriptedMode stage to advance to the next stage.
 *
 * @noreturn
 */
// L4D2 only.
native void L4D2_ForceNextStage();

/**
 * @brief Returns true when any tanks are on the map
 *
 * @return			True when any tanks are on the map. False when no tanks.
 */
// L4D2 only.
native bool L4D2_IsTankInPlay();

/**
 * @brief Returns the value of the specified Director Variable key.
 *
 * @param key		Director variable key name to search for
 * @param value		Default value to use when the variable is not found
 *
 * @return			Value of the variable, or provided default value on failure
 */
// L4D2 only.
native int L4D2_GetScriptValueInt(const char[] key, int value);

/**
 * @brief Returns the nav distance between two areas. Does not account for out-of-bounds areas.
 *
 * @param startArea				NavArea address
 * @param endArea				NavArea address
 * @param ignoreNavBlockers		Bool to ignore blocked areas while checking (does not seem to work as expected)
 *
 * @return						Distance between the areas, 0.0 if the same area or -1.0 on failure.
 */
// L4D2 only.
native float L4D2_NavAreaTravelDistance(float startPos[3], float endPos[3], bool ignoreNavBlockers);



// // Only returns default value provided.
// native float L4D2_GetScriptValueFloat(const char[] key, float value);

// Not implemented, request if really required.
// native void L4D2_GetScriptValueString(const char[] key, const char[] value, char[] retValue, int maxlength);




// ====================================================================================================
// NATIVES - Silvers - VSCRIPT WRAPPERS
// ====================================================================================================
// These natives are using VScripts to call functions - this is much slower than native SDKCalls.
// Popular VScript functions will be converted to standard native SDKCalls. Please tell me.
// Recommend not using these too often, instead request proper native SDKCalls.

/**
 * @brief Returns the number of maps played since a new campaign (not the current chapter).
 *
 * @return		Number of maps played
 */
// L4D2 only.
native int L4D2_VScriptWrapper_GetMapNumber();

/**
 * @brief Returns true if the character has ever been injured by a member of the given team.
 * @remarks Team 3 returns true when hurt by Common Infected.
 *
 * @param client		Client to test
 *
 * @return				Number of maps played
 */
// L4D2 only.
native bool L4D2_VScriptWrapper_HasEverBeenInjured(int client, int team);

/**
 * @brief Returns the time the character has been alive (only valid when alive).
 *
 * @return				Client to test
 */
// L4D2 only.
native float L4D2_VScriptWrapper_GetAliveDuration(int client);

/**
 * @brief Returns true when a player is dead and can spectate others.
 *
 * @return				True if dead, false if not or script error.
 */
// L4D2 only.
native bool L4D2_VScriptWrapper_IsDead(int client);

/**
 * @brief Returns true when a player is dead, but cannot spectate others yet.
 *
 * @param client		Client to test
 *
 * @return				True if dying, false if not or script error.
 */
// L4D2 only.
native bool L4D2_VScriptWrapper_IsDying(int client);

/**
 * @brief Causes Adrenaline's speed and visual effect, no change to health.
 *
 * @param client		Client to affect
 *
 * @return				True on success (does not guarantee effect turned on), false on script error.
 */
// L4D2 only.
native bool L4D2_VScriptWrapper_UseAdrenaline(int client, float time);

/**
 * @brief Revive a dead player by defib.
 *
 * @param client		Client to revive
 *
 * @return				True on success (does not guarantee they were revived), false on script error.
 */
// L4D2 only.
native bool L4D2_VScriptWrapper_ReviveByDefib(int client);

/**
 * @brief Revive an incapacitated player.
 *
 * @param client		Client to revive
 *
 * @return				True on success (does not guarantee they were revived), false on script error.
 */
// L4D2 only.
native bool L4D2_VScriptWrapper_ReviveFromIncap(int client);

/**
 * @brief Get the current bits for the bot sense flags: BOT_CANT_SEE, BOT_CANT_HEAR, BOT_CANT_FEEL.
 *
 * @param client		Bot to check
 *
 * @return				Current sense flags
 */
// L4D2 only.
native int L4D2_VScriptWrapper_GetSenseFlags(int client);

/**
 * @brief Test two vector positions if they can be reached (only returns false if a location has no valid NavArea, out-of-bounds can be valid).
 *
 * @return		Returns true if a path exists, false if not or on script error.
 */
// L4D2 only.
native bool L4D2_VScriptWrapper_NavAreaBuildPath(float startPos[3], float endPos[3], float flMaxPathLength, bool checkLOS, bool checkGround, int teamID, bool ignoreNavBlockers);

/**
 * @brief Compute distance between two areas.
 *
 * @return		-1 if can't reach 'endArea' from 'startArea'. 
 */
// L4D2 only.
// Added as a demonstration and test, SDKCall is available, use "L4D2_NavAreaTravelDistance" instead.
native float L4D2_VScriptWrapper_NavAreaTravelDistance(float startPos[3], float endPos[3], float flMaxPathLength, bool checkLOS, bool checkGround);





// ====================================================================================================
// NATIVES - left4downtown.inc
// ====================================================================================================
/**
 * @brief Restarts the setup timer (when in scavenge mode)
 * @remarks If game has already started, the setup timer will show,
 *			but it still won't go back into setup.
 */
// L4D2 only.
native int L4D_ScavengeBeginRoundSetupTime();

/**
 * @brief Resets the natural mob (horde) timer
 * @remarks	Requires the Director to be available--map must be started
 *
 * @noreturn
 */
// L4D2 only.
native void L4D_ResetMobTimer();

/**
 * @brief Get the remaining spawn time for an SI
 * @remarks This is meant for Special infected in ghost mode in versus.
 *
 * @return			Time (seconds) until the SI will spawn.
 */
// L4D2 only.
native float L4D_GetPlayerSpawnTime(int player);

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
 * @remarks Requires GameRules to be initialized--map must be loaded
 *			Seems to be updated before OnMapStart
 *
 * @return			The map's max completion distance (map distance score)
 */
// L4D2 only.
native int L4D_GetVersusMaxCompletionScore();

/**
 * @brief Sets the max versus completion score for the map
 * @remarks Requires GameRules to be initialized--map must be loaded
 *			Seems to be updated before OnMapStart and checked on round_start
 *
 * @param score		The versus max completion score to set for the round
 */
// L4D2 only.
native int L4D_SetVersusMaxCompletionScore(int score);

/**
 * @brief Get the team scores for the current map
 * @remarks The campaign scores are not set until the end of round 2,
 *			use L4D_GetCampaignScores to get them earlier.
 *
 * @deprecated This function can be called through SDKTools using CTerrorGameRules,
 *			and so you should switch off to using SDKTools instead of this native.
 *
 * @param logical_team		1 for A, 2 for B
 * @param campaign_score	true to get campaign score instead of map score
 *
 * @return			the logical team's map score
 *					or -1 if the team hasn't played the round yet,
 *					or the team's campaign score if campaign_score = true
 */
// L4D2 only.
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
 * @return			true if the map is the last map of the campaign (finale)
 */
native bool L4D_IsMissionFinalMap();

/**
 * @brief Notifies the CGameRulesProxy that the game state has been changed
 * @remarks Use this function before changing networked members of GameRules,
 *			like with L4D_SetVersusMaxCompletionScore()
 *
 * @noreturn
 */
native void L4D_NotifyNetworkStateChanged();

/**
 * @brief Trigger's a target player's stagger behavior
 * @remarks Works on any CTerrorPlayer--survivor or infected.
 *
 * @param target 		Player to stagger
 * @param source_ent	Source of the stagger (another player, etc)
 * @param vecSource		Source location of the stagger. If NULL_VECTOR, origins of source_ent is used.
 * @noreturn
 */
native void L4D_StaggerPlayer(int target, int source_ent, float vecSource[3]);

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
 *
 * @param FinaleStageType	integer value
 *
 * @noreturn
 */
// L4D2 only.
native void L4D2_ChangeFinaleStage(int finaleType, const char[] arg);

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
// L4D2 only.
native int L4D2_SpawnWitchBride(const float vecPos[3], const float vecAng[3]);

/**
 * @brief Removes lobby reservation from a server
 * @remarks Sets the reservation cookie to 0,
 *			it is safe to call this even if it's unreserved.
 */
native void L4D_LobbyUnreserve();

/**
 * @brief Get the current campaign scores stored in the Director
 * @remarks The campaign scores are updated after L4D_OnSetCampaignScores
 *
 * @deprecated This will set the scores to -1 for both sides on L4D2,
 *				this function is no longer supported.
 *
 * @param scoreA	score of logical team A
 * @param scoreB	score of logical team B
 *
 * @return			1 always
 */
#pragma deprecated Use GetTeamScore and OnClearTeamScores instead
native int L4D_GetCampaignScores(int &scoreA, int &scoreB);

/**
 * @brief Checks if the server is currently reserved for a lobby
 * @remarks Server is automatically unreserved if it hibernates or
 *			if all players leave.
 *
 * @deprecated This will always return false on L4D2 or on Linux.
 *
 * @return			true if reserved, false if not reserved
 */
#pragma deprecated This will always return false on L4D2 or on Linux.
native bool L4D_LobbyIsReserved();
/**
 * @brief Get the time remaining before the next director horde.
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
 * @return			Total time from last horde to next horde.
 */
#pragma deprecated Use L4D2_CTimerGetCountdownDuration(L4D2CT_MobSpawnTimer)
native float L4D_GetMobSpawnTimerDuration();





// ====================================================================================================
// NATIVES - l4d2director.inc
// ====================================================================================================
/**
 * @brief Gets the number of tanks currently in play.
 * @remarks This value is tracked by the director, and should be a good
 *		indicator that a tank is in play
 *
 * @return			Current Tank count
 */
native int L4D2_GetTankCount();

/**
 * @brief Gets the number of witches currently in play.
 * @remarks This value is tracked by the director, and should be a good
 *		indicator that a witch is in play
 *
 * @return			Current Witch count
 */
native int L4D2_GetWitchCount();

/**
 * @brief Gets the campaign scores stored in the Versus Director
 * @remarks These are the actual values used for campaign scores--not proxies
 *
 * @param scores 	Array to store the campaign scores in
 * @noreturn
 */
// L4D2 only.
native void L4D2_GetVersusCampaignScores(int scores[2]);

/**
 * @brief Sets the campaign scores stored in the Versus Director
 * @remarks These are the actual values used for campaign scores--not proxies
 *
 * @param scores 	Array of campaign scores to set the director's values to.
 * @noreturn
 */
// L4D2 only.
native void L4D2_SetVersusCampaignScores(const int scores[2]);

/**
 * @brief Gets the flow percent for tank spawns for both versus rounds.
 * @remarks These values are checked against as the survivors move through the
 *		map. Once they are passed, the tank spawns. Note that this is flow
 *		as a percent of the map's flow, not flow distance.
 *
 * @param tankFlows		Array to store the Tank Spawn Flow percents in director
 * @noreturn
 */
// L4D2 only.
native void L4D2_GetVersusTankFlowPercent(float tankFlows[2]);

/**
 * @brief Sets the flow percent for tank spawns for both versus rounds.
 * @remarks These values are checked against as the survivors move through the
 *		map. Once they are passed, the tank spawns. Note that this is flow
 *		as a percent of the map's flow, not flow distance.
 *
 * @param tankFlows		Array of Tank Spawn Flow percents to store in director
 * @noreturn
 */
// L4D2 only.
native void L4D2_SetVersusTankFlowPercent(const float tankFlows[2]);

/**
 * @brief Gets the flow percent for witch spawns for both versus rounds.
 * @remarks These values are checked against as the survivors move through the
 *		map. Once they are passed, the witch spawns. Note that this is flow
 *		as a percent of the map's flow, not flow distance.
 *
 * @param witchFlows	Array to store the Witch Spawn Flow percents in director
 * @noreturn
 */
// L4D2 only.
native void L4D2_GetVersusWitchFlowPercent(float witchFlows[2]);

/**
 * @brief Sets the flow percent for witch spawns for both versus rounds.
 * @remarks These values are checked against as the survivors move through the
 *		map. Once they are passed, the witch spawns. Note that this is flow
 *		as a percent of the map's flow, not flow distance.
 *
 * @param witchFlows	Array of Witch Spawn Flow percents to store in director
 * @noreturn
 */
// L4D2 only.
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
	L4D2CT_UpdateMarkersTimer
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
// L4D2 only.
native void L4D2_CTimerReset(L4D2CountdownTimer timer);

/**
 * @brief Starts a given CountdownTimer with a given duration
 * @remarks This sets a new duration and sets up the end timestamp
 *
 * @param timer 		CountdownTimer to start
 * @param duration		Duration for the timer to use
 * @noreturn
 */
// L4D2 only.
native void L4D2_CTimerStart(L4D2CountdownTimer timer, float duration);

/**
 * @brief Invalidates a given CountdownTimer (Timer essentially does not run)
 * @remarks Sets the timestamp to -1.0f
 *
 * @param timer 		CountdownTimer to Invalidate
 * @noreturn
 */
// L4D2 only.
native void L4D2_CTimerInvalidate(L4D2CountdownTimer timer);

/**
 * @brief Tells if a given CountdownTimer has started
 * @remarks Checks to see if the end timestamp is greater than 0.0f
 *
 * @param timer 		CountdownTimer to check
 *
 * @return				true if timer has started, false if timer is not started/invalid.
 */
// L4D2 only.
native bool L4D2_CTimerHasStarted(L4D2CountdownTimer timer);

/**
 * @brief Tells if a given CountdownTimer is elapsed
 * @remarks If a timer is "up," e.g duration has passed since start, this returns true;
 *
 * @param timer 		CountdownTimer to check
 *
 * @return				true if timer has elapsed or timer invalid/not started, false otherwise
 */
// L4D2 only.
native bool L4D2_CTimerIsElapsed(L4D2CountdownTimer timer);

/**
 * @brief Gets elapsed time of a given CountdownTimer, from the timed it was started
 * @remarks Value is (Now() - timestamp) + duration
 *
 * @param timer 		CountdownTimer to get elapsed time of
 *
 * @return				float amount of time since timer started
 */
// L4D2 only.
native float L4D2_CTimerGetElapsedTime(L4D2CountdownTimer timer);

/**
 * @brief Gets remaining time on a given CountdownTimer
 * @remarks Value is (timestamp - Now())
 *
 * @param timer 		CountdownTimer to get remaining time of
 *
 * @return				float amount of time remaining on the timer
 */
// L4D2 only.
native float L4D2_CTimerGetRemainingTime(L4D2CountdownTimer timer);

/**
 * @brief Gets the duration of a given CountdownTimer
 * @remarks Value is (timestamp > 0.0f ? duration 0.0f)
 *
 * @param timer 		CountdownTimer to get duration of
 *
 * @return				0.0 for invalid/not started timers, timer duration otherwise.
 */
// L4D2 only.
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
// L4D2 only.
native void L4D2_ITimerStart(L4D2IntervalTimer timer);

/**
 * @brief Invalidates a given IntervalTimer
 * @remarks Just sets timestamp = -1.0f
 *
 * @param timer 		IntervalTimer to Invalidate
 * @noreturn
 */
// L4D2 only.
native void L4D2_ITimerInvalidate(L4D2IntervalTimer timer);

/**
 * @brief Tells whether a given IntervalTimer has started
 * @remarks Checks to see if timestamp > 0.0f
 *
 * @param timer 		IntervalTimer to check
 *
 * @return				true if timer is started, false if it is invalid/not started
 */
// L4D2 only.
native bool L4D2_ITimerHasStarted(L4D2IntervalTimer timer);

/**
 * @brief Gets the elapsed time of a given IntervalTimer
 * @remarks Value is Now() - Timestamp
 *
 * @param timer 		IntervalTimer to get elapsed time of
 *
 * @return				Elapsed time if timer started and valid, 99999.9f otherwise
 */
// L4D2 only.
native float L4D2_ITimerGetElapsedTime(L4D2IntervalTimer timer);





// ====================================================================================================
// NATIVES - l4d2weapons.inc
// ====================================================================================================
/*
 * 2020 Update1: Use the "Info Editor" plugin by Silvers to edit the weapon scripts and increase clip size.
 * 2020 Update2: Now works in Left4DHooks. Glitchy animation bug when reloading an already full weapon.
 * Fix plugin coming soon. Maybe full plugin to modify maximum clip size with all fixes handled.

A note regarding Clipsize: Any nonstandard value will NOT be in effect at weapon pickup, which means the client
has to reload once to achieve the modified value. To fix this, add a weapon pickup hook in your plugin (eg "player_use")
and use something like this with a small timer delay of 0.1 seconds or more (dont you love this engine).

	new weapon = GetPlayerWeaponSlot(client, 0);
	if (weapon == INVALID_ENT_REFERENCE) return;
	char class[56];
	GetEdictClassname(weapon, class, sizeof(class));
	SetEntProp(weapon, Prop_Send, "m_iClip1", L4D2_GetIntWeaponAttribute(class, L4D2IWA_ClipSize));
*/
enum L4D2IntWeaponAttributes
{
	L4D2IWA_Damage,
	L4D2IWA_Bullets,
	L4D2IWA_ClipSize,
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
	MAX_SIZE_L4D2FloatWeaponAttributes
};

enum L4D2BoolMeleeWeaponAttributes
{
	L4D2BMWA_Decapitates,
	MAX_SIZE_L4D2BoolMeleeWeaponAttributes
};

enum L4D2IntMeleeWeaponAttributes
{
	L4D2IMWA_DamageFlags,
	L4D2IMWA_RumbleEffect,
	MAX_SIZE_L4D2IntMeleeWeaponAttributes
};

enum L4D2FloatMeleeWeaponAttributes
{
	L4D2FMWA_Damage,
	L4D2FMWA_RefireDelay,
	L4D2FMWA_WeaponIdleTime,
	MAX_SIZE_L4D2FloatMeleeWeaponAttributes
};



/**
 * @brief Checks for a given weapon string to exist in the WeaponInformationDatabase
 * @remarks Throws an error if Database is unavailable
 *
 * @param weaponName 	Weapon to check up on
 *
 * @return				True if weapon is found, false if not
 */
// L4D2 only.
native bool L4D2_IsValidWeapon(const char[] weaponName);

/**
 * @brief Read an int-typed attribute for a given weapon from the WeaponInformationDatabase
 * @remarks Throws an error if the weapon is not found or the attribute is incorrect
 *
 * @param weaponName 	Weapon to lookup attribute for
 * @param attr			Attribute to read from the weapon's info struct
 *
 * @return				The value read.
 */
// L4D2 only.
native int L4D2_GetIntWeaponAttribute(const char[] weaponName, L4D2IntWeaponAttributes attr);

/**
 * @brief Read a float-typed attribute for a given weapon from the WeaponInformationDatabase
 * @remarks Throws an error if the weapon is not found or the attribute is incorrect
 *
 * @param weaponName 	Weapon to lookup attribute for
 * @param attr			Attribute to read from the weapon's info struct
 *
 * @return				The value read.
 */
// L4D2 only.
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
// L4D2 only.
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
// L4D2 only.
native void L4D2_SetFloatWeaponAttribute(const char[] weaponName, L4D2FloatWeaponAttributes attr, float value);



/**
 * @brief Retrieve the index for a given melee weapon from the Melee Weapon Database.
 * @remarks Index updated on OnMapStart - suggest using RequestFrame to find index.
 * @remarks Index can change depending on available melee weapons each map.
 *
 * @param weaponName 	Weapon to lookup index id for
 *
 * @return				The index id. Returns -1 if no match is found or melee unavailable.
 */
// L4D2 only.
native int L4D2_GetMeleeWeaponIndex(const char[] weaponName);

/**
 * @brief Read an int-typed attribute for a given id from the Melee Weapon Database
 * @remarks Throws an error if the id is not found or the attribute is incorrect
 *
 * @param id 			Melee id to lookup attribute for
 * @param attr			Attribute to read from the weapon's info struct
 *
 * @return				The value read.
 */
// L4D2 only.
native int L4D2_GetIntMeleeAttribute(int id, L4D2IntMeleeWeaponAttributes attr);

/**
 * @brief Read a float-typed attribute for a given id from the Melee Weapon Database
 * @remarks Throws an error if the id is not found or the attribute is incorrect
 *
 * @param id 			Melee id to lookup attribute for
 * @param attr			Attribute to read from the weapon's info struct
 *
 * @return				The value read.
 */
// L4D2 only.
native float L4D2_GetFloatMeleeAttribute(int id, L4D2FloatMeleeWeaponAttributes attr);

/**
 * @brief Read a bool-typed attribute for a given id from the Melee Weapon Database
 * @remarks Throws an error if the id is not found or the attribute is incorrect
 *
 * @param id 			Melee id to lookup attribute for
 * @param attr			Attribute to read from the weapon's info struct
 *
 * @return				The value read.
 */
// L4D2 only.
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
// L4D2 only.
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
// L4D2 only.
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
// L4D2 only.
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
 * Get the current Tank count stored by the director.
 *
 * @note This should work on any gamemode, and is a good check to see if there is a tank in play
 *
 * @return			The current number of tanks in play.
 * @error			Director address not found.
 */
// L4D2 only.
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
 * @note This timer is used to control the spawning of natural hordes.
 * @note This timer gets reset during unnatural hordes as well (boomer/car alarm hordes)
 * @note Some scripted events will effectively "take over", by reducing the mob spawn time.
 *
 * @return				CountdownTimer reference to the timer, or CTimer_Null on lookup failure.
 */
// L4D2 only.
native CountdownTimer L4D2Direct_GetMobSpawnTimer();

/**
 * Get a reference to a IntervalTimer that counts up from the last death of a given SI class
 * @note The main place I've seen these timers used is in the SI spawning algorithms (CDirector::UpdateSpecialSpawns)
 * @note This timer gets checked against SI respawn interval for different gamemodes, some of which are cvar controlled (e.g. versus_special_respawn_interval)
 *
 * @param class		SI Class to retrieve timer for
 *
 * @return			IntervalTimer reference to the timer, or ITimer_Null on lookup failure or bad class.
 */
// L4D2 only.
native IntervalTimer L4D2Direct_GetSIClassDeathTimer(int class);

/**
 * Get a reference to a CountdownTimer that counts down from the last attempted director-controlled spawn of an SI
 * @note The main place I've seen these timers used is in the SI spawning algorithms (CDirector::UpdateSpecialSpawns)
 * @note This timer is hard-coded to use a duration of 20.0s.
 *
 * @param class		SI Class to retrieve timer for
 *
 * @return			CountdownTimer reference to the timer, or CTimer_Null on lookup failure or bad class.
 */
// L4D2 only.
native CountdownTimer L4D2Direct_GetSIClassSpawnTimer(int class);

/**
 * Gets the number of times the tank has passed to a player.
 * @note When this variable is >1 the tank will be replaced with a bot when the his frustration reaches 0.
 * @note The initial pass from AI to a player counts as a pass.
 * @note As this is global on the director weird things could potentially happen if more than one tank is alive at a time with z_frustration 1.
 *
 * @return          The number of passes.
 */
native int L4D2Direct_GetTankPassedCount();

/**
 * Sets the number of times the tank has passed to a player.
 * @note When this variable is >1 the tank will be replaced with a bot when the his frustration reaches 0.
 * @note The initial pass from AI to a player counts as a pass.
 * @note As this is global on the director weird things could potentially happen if more than one tank is alive at a time with z_frustration 1.
 *
 * @param           New number of passes value
 *
 * @noreturn
 */
native void L4D2Direct_SetTankPassedCount(int passes);



/* CDirectorVersusMode Variable access */

/**
 * Reads the director's stored campaign score for a given team.
 *
 * @note You can use the gamerules m_bAreTeamsFlipped property to figure out team numbers
 * @note The campaign scores value is also stored in gamerules, however this is the "master" version.
 * @note Campaign scores are only updated on round end, so this will not reflect current survivor distance score
 *
 * @param teamNumber	Team number to read campaign score of, 0 or 1.
 *
 * @return				Campaign score for the given team.
 * @error				Director or Versus Director address not found.
 */
native int L4D2Direct_GetVSCampaignScore(int teamNumber);

/**
 * Set the director's stored campaign score for a given team.
 *
 * @note You can use the gamerules m_bAreTeamsFlipped property to figure out team numbers
 * @note The campaign scores value is also stored in gamerules, however this is the "master" version.
 * @note Keep in mind the current survivor team's distance/bonus score will be added at the end of a round
 *
 * @param teamNumber	Team number to set campaign score of, 0 or 1.
 * @param score			Score to set for the team
 *
 * @noreturn
 * @error				Director or Versus Director address not found.
 */
native void L4D2Direct_SetVSCampaignScore(int teamNumber, int score);

/**
 * Reads the tank flow percent for a given round for versus mode
 *
 * @note You should check GetVSTankToSpawnThisRound to find out if a tank is going to be spawned for this round.
 * @note When the survivors reach this flow percent minus versus_boss_buffer converted to flow percent, a tank will spawn.
 *
 * @param roundNumber	Round number to read tank spawn flow percent of
 *
 * @return				Tank spawn flow percent for the given round
 * @error				Director or Versus Director address not found.
 */
native float L4D2Direct_GetVSTankFlowPercent(int roundNumber);

/**
 * Sets the tank flow percent for a given round for versus mode
 *
 * @note You should check GetVSTankToSpawnThisRound to find out if there is still a tank to spawn this round.
 * @note When the survivors reach this flow percent minus versus_boss_buffer converted to flow percent, a tank will spawn.
 *
 * @param roundNumber	Round number to set tank spawn flow percent of
 * @param flow			Floating point percent of flow distance.
 *
 * @noreturn
 * @error				Director or Versus Director address not found.
 */
native int L4D2Direct_SetVSTankFlowPercent(int roundNumber, float flow);

/**
 * Is there going to be a tank spawned during the given round
 *
 * @param roundNumber	Round number to check for tank spawn on
 *
 * @return				True if there is still a tank to spawn for the given round, false if it has already been spawned or will not spawn.
 * @error				Director or Versus Director address not found.
 */
native bool L4D2Direct_GetVSTankToSpawnThisRound(int roundNumber);

/**
 * Tell the director whether or not to spawn a(nother) flow distance-based tank for this round.
 * @note If you set this to true after a flow-distance-based tank has been spawned, this can trigger another tank to be spawned based on flow distance
 *
 * @param roundNumber	Round number to set a tank spawn on
 * @param spawn			Whether or not to spawn a flow-distance-based tank for this round.
 *
 * @noreturn
 * @error				Director or Versus Director address not found.
 */
native void L4D2Direct_SetVSTankToSpawnThisRound(int roundNumber, bool spawn);

/**
 * Reads the witch flow percent for a given round for versus mode
 *
 * @note You should check GetVSWitchToSpawnThisRound to find out if a witch is going to be spawned for this round.
 * @note When the survivors reach this flow percent minus versus_boss_buffer converted to flow percent, a witch will spawn.
 *
 * @param roundNumber	Round number to read witch spawn flow percent of
 *
 * @return				Witch spawn flow percent for the given round
 * @error				Director or Versus Director address not found.
 */
native float L4D2Direct_GetVSWitchFlowPercent(int roundNumber);

/**
 * Sets the witch flow percent for a given round for versus mode
 *
 * @note You should check GetVSWitchToSpawnThisRound to find out if there is still a witch to spawn this round.
 * @note When the survivors reach this flow percent minus versus_boss_buffer converted to flow percent, a witch will spawn.
 *
 * @param roundNumber	Round number to set witch spawn flow percent of
 * @param flow			Floating point percent of flow distance.
 *
 * @noreturn
 * @error				Director or Versus Director address not found.
 */
native int L4D2Direct_SetVSWitchFlowPercent(int roundNumber, float flow);

/**
 * Is there going to be a witch spawned during the given round
 *
 * @param roundNumber	Round number to check for witch spawn on
 *
 * @return				True if there is still a witch to spawn for the given round, false if it has already been spawned or will not spawn.
 * @error				Director or Versus Director address not found.
 */
native bool L4D2Direct_GetVSWitchToSpawnThisRound(int roundNumber);

/**
 * Tell the director whether or not to spawn a(nother) flow distance-based witch for this round.
 * @note If you set this to true after a flow-distance-based witch has been spawned, this can trigger another witch to be spawned based on flow distance
 *
 * @param roundNumber	Round number to set a witch spawn on
 * @param spawn			Whether or not to spawn a flow-distance-based witch for this round.
 *
 * @noreturn
 * @error				Director or Versus Director address not found.
 */
native int L4D2Direct_SetVSWitchToSpawnThisRound(int roundNumber, bool spawn);

/**
 * Get a reference to the VersusStart CountdownTimer
 * @note This timer controls when the saferoom door will open and PZ spawning is enabled
 * @note The default duration for this timer is controlled by cvar: versus_force_start_time
 *
 * @return				CountdownTimer reference to the timer, or CTimer_Null on lookup failure.
 * @error				Director address not found.
 */
// L4D2 only.
native CountdownTimer L4D2Direct_GetVSStartTimer();



/* CDirectorScavengeMode Variable access */

/**
 * Get a reference to the Scavenge Round Setup CountdownTimer
 * @note This timer controls when the scavenge "warmup" time ends and PZ/game timers start.
 * @note The default duration for this timer is controlled by cvar: scavenge_round_setup_time
 *
 * @return				CountdownTimer reference to the timer, or CTimer_Null on lookup failure.
 * @error				Director address not found.
 */
// L4D2 only.
native CountdownTimer L4D2Direct_GetScavengeRoundSetupTimer();

/**
 * Get a reference to the Scavenge Overtime Grace CountdownTimer
 * @note This timer keeps track of how long survivors have gone without holding a can during overtime.
 * @note The default duration for this timer is controlled by cvar: scavenge_overtime_grace_time
 *
 * @return				CountdownTimer reference to the timer, or CTimer_Null on lookup failure.
 * @error				Director address not found.
 */
// L4D2 only.
native CountdownTimer L4D2Direct_GetScavengeOvertimeGraceTimer();



/* TerrorNavMesh Variable access */

/**
 * Get the max flow distance (in flow units) for the current map.
 * @note The flow distance for each map is generated as it is loaded, and it can change slightly (a few hundred units) with each load.
 * @note You can use this value to convert a flow distance to a flow percent, and vice versa.
 *
 * @return				Max flow distance for the current loaded map.
 * @error				TerrorNavMesh address not found.
 */
native float L4D2Direct_GetMapMaxFlowDistance();



/* CTerrorPlayer Variable access */

/**
 * Get a reference to a CountdownTimer that tracks when an SI player can next spawn.
 * @note The duration of this timer is controlled by the cvars z_ghost_delay_min and z_ghost_delay_max.
 *
 * @param client		Client id to get the spawn timer for
 *
 * @return				CountdownTimer reference to the timer, or CTimer_Null on lookup failure.
 * @error				Invalid client.
 */
// L4D2 only.
native CountdownTimer L4D2Direct_GetSpawnTimer(int client);

/**
 * Get a reference to a CountdownTimer that tracks when an survivor player is invulnerable due to "godframes".
 *
 * @param client		Client id to get the godframes timer for
 *
 * @return				CountdownTimer reference to the timer, or CTimer_Null on lookup failure.
 * @error				Invalid client.
 */
native CountdownTimer L4D2Direct_GetInvulnerabilityTimer(int client);

/**
 * Looks up the number of tickets a client has for entry into the tank lottery.
 * @note The number of tickets you have is equal to your damage done as an SI and will still increase as you do damage with the Tank.
 * @note When the tank is passed away from you your tickets are set back to zero.
 *
 * @param client		Client id to get the tickets for
 *
 * @return				Number of tickets.
 * @error				Invalid client.
 */
native int L4D2Direct_GetTankTickets(int client);

/**
 * Sets the number of tickets a player has for entry into the tank lottery.
 *
 * @param client		Client id to set the tickets for
 * @param tickets		New value for the client's tank lottery tickets
 *
 * @noreturn
 * @error				Invalid client.
 */
native void L4D2Direct_SetTankTickets(int client, int tickets);

/**
 * Gets a client's shove penalty.
 * @note The returned value will be between 0 and z_gun_swing_{vs,coop}_max_penalty.
 *
 * @param client		Client id
 *
 * @return				Shove penalty or -1 on error
 */
// L4D2 only.
native int L4D2Direct_GetShovePenalty(int client);

/**
 * Sets a client's shove penalty.
 * @note The penalty should be set between 0 and z_gun_swing_{vs,coop}_max_penalty.
 *
 * @param client		Client id
 * @param penalty		Shove penalty
 *
 * @noreturn
 */
// L4D2 only.
native void L4D2Direct_SetShovePenalty(int client, int penalty);

/**
 * Gets the time at which a survivor can perform his next +attack2.
 *
 * @param client		Client id
 *
 * @return				Time or 0.0 on error
 */
// L4D2 only.
native float L4D2Direct_GetNextShoveTime(int client);

/**
 * Sets the time at which a survivor can perform his next +attack2.
 *
 * @param client		Client id
 * @param time			Game time
 *
 * @noreturn
 */
// L4D2 only.
native void L4D2Direct_SetNextShoveTime(int client, float time);

/**
 * Gets the health of the survivor from before they were incapacitated
 * @note This may only apply to hanging players
 *
 * @param client		Client id
 *
 * @return				Real health before incapacitation
 */
// L4D2 only.
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
// L4D2 only.
native void L4D2Direct_SetPreIncapHealth(int client, int health);

/**
 * Gets the temporary health of the survivor from before they were incapacitated
 * @note This may only apply to hanging players
 *
 * @param client		Client id
 * @return				Temporary health before incapacitation
 */
// L4D2 only.
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
// L4D2 only.
native void L4D2Direct_SetPreIncapHealthBuffer(int client, int health);

/**
 * Gets the maximum number of flames a CInferno is allowed to spawn.
 *
 * @param entity		Entity id
 *
 * @return				Number of flames or -1 on error
 */
// L4D2 only.
native int L4D2Direct_GetInfernoMaxFlames(int entity);

/**
 * Sets the maximum number of flames a CInferno is allowed to spawn.
 *
 * @param entity		Entity id
 * @param flames		Number of flames
 *
 * @noreturn
 */
// L4D2 only.
native void L4D2Direct_SetInfernoMaxFlames(int entity, int flames);

/**
 * Returns the CDirectorScriptedEventManager address.
 * This native replicates "L4D2_GetCDirectorScriptedEventManager" used by other plugins.
 *
 * @return				Address pointer
 */
// L4D2 only.
native int L4D2Direct_GetScriptedEventManager();

/**
 * Get the TerrorNavArea which holds a specific position.
 * @note Some positions will not return a nav area (Address_Null). Notable examples are saferooms and small ledges like the guard rail at the start of c2m1_highway.
 * @remarks This is less reliable than L4D_GetNearestNavArea.
 *
 * @param pos           The position to find the containing nav area of
 * @param beneathLimit
 *
 * @return              Address to a TerrorNavArea or Address_Null
 * @error               Unable to prepare SDK call
 */
native Address L4D2Direct_GetTerrorNavArea(float pos[3], float beneathLimit = 120.0);

/**
 * Find the distance through the map (in flow units) that a TerrorNavArea is located.
 *
 * @param  pTerrorNavArea   Pointer to a TerrorNavArea
 *
 * @return                  The flow units through the map that the TerrorNavArea is located at.
 * @error                   When passed an Address_Null
 */
native float L4D2Direct_GetTerrorNavAreaFlow(Address pTerrorNavArea);

/**
 * Force the director to pass the tank.
 *
 * @param client			Client index of the tank
 * @param bEnterStasis		Should the tank be put in stasis
 *
 * @return					False on error otherwise true
 */
native bool L4D2Direct_TryOfferingTankBot(int client, int bEnterStasis);

/**
 * Gets a player's distance in flow units.
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
 * @param client
 * @param event PlayerAnimEvent_t
 *
 * @noreturn
 */
native void L4D2Direct_DoAnimationEvent(int client, int event);



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
 * Determine if a CountdownTimer has started counting down.
 *
 * @param timer				CountdownTimer to check
 *
 * @return					True if it has started running, False if it is not (Invalidated)
 */
native bool CTimer_HasStarted(CountdownTimer timer);

/**
 * Determine if a CountdownTimer is elapsed.
 *
 * @param timer				CountdownTimer to check
 *
 * @return					True if the timer's duration has passed since it started, false otherwise.
 */
native bool CTimer_IsElapsed(CountdownTimer timer);

/**
 * Check how long a CountdownTimer has been running
 *
 * @param timer				CountdownTimer to check
 *
 * @return					Time since the CountdownTimer was last Started or Reset, in seconds.
 */
native float CTimer_GetElapsedTime(CountdownTimer timer);

/**
 * Check how much time remains before a CountdownTimer is elapsed.
 *
 * @param timer				CountdownTimer to check
 *
 * @return					Time until the CountdownTimer is elapsed, in seconds.
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
 * @note This is the same as reset for IntervalTimers...
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
// L4D2 only.
native void L4D2_CTerrorPlayer_OnHitByVomitJar(int client, int attacker);

/**
 * @brief Creates the boomer vomit effect on Common infected
 *
 * @param entity			Entity ID of the common to affect
 * @param attacker			Client ID who caused the blindness, can be the same as client
 *
 * @noreturn
 */
// L4D2 only.
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
// L4D2 only.
native void L4D2_CTerrorPlayer_Fling(int client, int attacker, float vecDir[3]);

/**
 * @brief Cancels a player staggering
 *
 * @param client			Client ID of the person to affect
 *
 * @noreturn
 */
native void L4D_CancelStagger(int client);

/**
 * @brief Spawns all dead survivors in rescuable rooms.
 * @remarks L4D1: Any survivor must not be in the starting area for it to work.
 * @remarks L4D2: Any survivor must have left the starting area for it to work, they can return and all be in the starting area.
 * @remarks By default the game would spawn one per frame, but I've added a RequestFrame loop to spawn all dead. Request if you want a singular spawn native.
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
 *
 * @param client			Client ID of the person to affect
 *
 * @return					Returns value from 0-100
 */
// L4D2 only.
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
 * @brief Takeover another special infected.
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
 * @return					Clients "m_customAbility" weapon entity ID or -1 on error.
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
 * @brief Enter ghost/dead mode. Some state values may have different results. Unknown.
 * @remarks 6 and 8 are commonly used by the game.
 *
 * @param client			Client ID of the player to affect
 *
 * @noreturn
 */
native void L4D_State_Transition(int client, int state);

/**
 * @brief Swaps the teams in Versus
 * @remarks Some survivors may spawn dead on swapping, seems to be random
 *
 * @noreturn
 */
// L4D2 only.
native void L4D2_SwapTeams();

/**
 * @brief Returns if Versus team are flipped
 *
 * @return					0=Not flipped. 1=Flipped
 */
// L4D2 only.
native bool L4D2_AreTeamsFlipped();

/**
 * @brief Starts a Versus rematch vote like end of game before credits roll
 * @remarks Failing a successful vote players are kicked back to lobby
 *
 * @noreturn
 */
// L4D2 only.
native void L4D2_StartRematchVote();

/**
 * @brief Seems to restart the chapter like "mp_restartgame". In Versus the teams flip.
 *
 * @noreturn
 */
// L4D2 only.
native void L4D2_FullRestart();

/**
 * @brief Hides end of round scoreboard.
 *
 * @noreturn
 */
// L4D2 only.
native void L4D2_HideVersusScoreboard();

/**
 * @brief Hides end of round scoreboard.
 *
 * @noreturn
 */
// L4D2 only.
native void L4D2_HideScavengeScoreboard();

/**
 * @brief Hides end of round scoreboard.
 *
 * @noreturn
 */
// L4D2 only.
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