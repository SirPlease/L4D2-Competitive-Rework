/**
 * vim: set ts=4 :
 * =============================================================================
 * Left 4 Downtown SourceMod Extension
 * Copyright (C) 2009-2011 Downtown1, ProdigySim; 2012-2015 Visor
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
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */
#if defined _l4do_included
 #endinput
#endif
#define _l4do_included

#include <l4d2timers>
#include <l4d2weapons>
#include <l4d2director>

/**
 * @brief Called whenever ZombieManager::SpawnTank(Vector&,QAngle&) is invoked
 * @remarks Not invoked if z_spawn tank is used and it gives a ghosted/dead player tank
 *
 * @param vector	Vector coordinate where tank is spawned
 * @param qangle	QAngle where tank will be facing
 * @return 		Pl_Handled to block tank from spawning, Pl_Continue otherwise.
 */
forward Action L4D_OnSpawnTank(const float vecOrigin[3], const float vecAngles[3]);

/**
 * @brief Called whenever ZombieManager::SpawnWitch(Vector&,QAngle&) is invoked
 *
 * @param vector	Vector coordinate where witch is spawned
 * @param qangle	QAngle where witch will be facing
 * @return 		Pl_Handled to block witch from spawning, Pl_Continue otherwise.
 */
forward Action L4D_OnSpawnWitch(const float vecOrigin[3], const float vecAngles[3]);

/**
 * @brief Called whenever ZombieManager::SpawnWitchBride(Vector&,QAngle&) is invoked
 *
 * @param vector	Vector coordinate where witch is spawned
 * @param qangle	QAngle where witch will be facing
 * @return 		Pl_Handled to block witch from spawning, Pl_Continue otherwise.
 */
forward Action L4D_OnSpawnWitchBride(const float vecOrigin[3], const float vecAngles[3]);

/**
 * @brief Called whenever ZombieManager::SpawnSpecial(ZombieClassType,Vector&,QAngle&) is invoked
 * @remarks Only used for bot special spawns (not players)
 *
 * @param zombieClass	Zombie class that will be spawned.
 * @param vector		Vector coordinate where special will be spawned
 * @param qangle		QAngle where spcial will be facing
 * @return 				Pl_Handled to block special from spawning, 
 * 				Pl_Changed to change the zombie class type to spawn, Pl_Continue otherwise.
 */
forward Action L4D_OnSpawnSpecial(int &zombieClass, const float vecOrigin[3], const float vecAngles[3]);

/**
 * @brief Called whenever CTerrorGameRules::ClearTeamScores(bool) is invoked
 * @remarks 	This resets the map score at the beginning of a map, and by checking 
 *                the campaign scores on a small timer you can see if they were reset as well.
 * 
 * @param newCampaign  if true then this is a new campaign, if false a new chapter
 * @return 		Pl_Handled to block scores from being cleared, Pl_Continue otherwise.
 */
forward Action L4D_OnClearTeamScores(bool newCampaign);

/**
 * @brief Called whenever CTerrorGameRules::SetCampaignScores(int,int) is invoked
 * @remarks The campaign scores are updated after the 2nd round is completed
 * 
 * @param scoreA  score of logical team A
 * @param scoreB  score of logical team B
 * @return 		Pl_Handled to block campaign scores from being set, Pl_Continue otherwise.
 */
forward Action L4D_OnSetCampaignScores(int &scoreA, int &scoreB);

/**
 * @brief Called whenever CDirector::OnFirstSurvivorLeftSafeArea is invoked
 * @remarks A versus round is started when survivors leave the safe room, or force started
 *           after 90 seconds regardless.
 * 
 * @param client  the survivor that left the safe area first
 * 
 * @return 		Pl_Handled to block round from being started, Pl_Continue otherwise.
 */
forward Action L4D_OnFirstSurvivorLeftSafeArea(int client);

/**
 * @brief Called whenever CDirector::GetScriptValue(const char*, int) is invoked
 * @remarks A script value is map specific
 * 
 * @param key     the script's key name
 * @param retVal  what to override the return value with
 * 
 * @return 		Pl_Handled to override return value, Pl_Continue otherwise.
 */
forward Action L4D_OnGetScriptValueInt(const char[] key, int &retVal);

/**
 * @brief Called whenever CDirector::GetScriptValue(const char*, float) is invoked
 * @remarks A script value is map specific
 * 
 * @param key     the script's key name
 * @param retVal  what to override the return value with
 * 
 * @return 		Pl_Handled to override return value, Pl_Continue otherwise.
 */
forward Action L4D_OnGetScriptValueFloat(const char[] key, float &retVal);

/**
 * @brief Called whenever CDirector::GetScriptValue(const char*, const char*, char*, int) is invoked
 * @remarks A script value is map specific
 * 
 * @param key     	  the script's key name
 * @param defaultVal  default key return, usually empty
 * @param retVal	  returned String
 * 
 * @return 		Pl_Handled to override return value, Pl_Continue otherwise.
 */
forward Action L4D_OnGetScriptValueString(const char[] key, const char[] defaultVal, char retVal[128]);

/**
 * @brief Called whenever CTerrorPlayer::OnEnterGhostState(CTerrorPlayer*) is invoked
 * @remarks This happens when a player enters ghost mode (or in finales auto-materialized)
 * 
 * @param client  the client that has entered ghost mode
 */
forward void L4D_OnEnterGhostState(int client);

/**
 * @brief Called whenever ZombieManager::ReplaceTank(CTerrorPlayer *,CTerrorPlayer *) is invoked
 * @remarks Not invoked if tank is bot
 *
 * @param CTerrorPlayer	tank the player who was a tank
 * @param CTerrorPlayer	newtank a player who has become a new tank
 */
forward void L4D_OnReplaceTank(int tank, int newtank);

/**
 * @brief Called whenever CDirector::TryOfferingTankBot is invoked
 * @remarks Is used for displaying the "X gets Tank" window and transferring Tank control
 * 
 * @return 		Pl_Handled to block window from showing and to keep Tank Bot, Pl_Continue otherwise
 */
forward Action L4D_OnTryOfferingTankBot(int tank_index, bool &enterStasis);

/**
 * @brief Called whenever CDirector::OnMobRushStart(void) is invoked
 * @remarks called on random hordes, mini- and finale hordes, and boomer hordes, causes Zombies to attack
 *           Not called on "z_spawn mob", hook the console command and check arguments to catch plugin mobs
 *           This function is used to reset the Director's natural horde timer
 * 
 * @return 		Pl_Handled to block, Pl_Continue otherwise
 */
forward Action L4D_OnMobRushStart();

/**
 * @brief Called whenever ZombieManager::SpawnITMob(int) is invoked
 * @remarks called on boomer hordes, increases Zombie Spawn Queue
 * 
 * @param amount	Amount of Zombies to add to Queue
 * 
 * @return 		Pl_Handled to block, Pl_Continue otherwise
 */
forward Action L4D_OnSpawnITMob(int &amount);

/**
 * @brief Called whenever ZombieManager::SpawnMob(int) is invoked
 * @remarks called on natural hordes & z_spawn mob, increases Zombie Spawn 
 *           Queue, triggers player OnMobSpawned (vocalizations), sets horde
 *           direction, and plays horde music.
 * 
 * @param amount	Amount of Zombies to add to Queue
 * 
 * @return 		Pl_Handled to block, Pl_Continue otherwise
 */
forward Action L4D_OnSpawnMob(int &amount);

/**
 * @brief Called whenever CTerrorPlayer::OnShovedBySurvivor(CTerrorPlayer, Vector&) is invoked
 * @remarks L4D2 only uses this on Special Infected
 *
 * @param client	the client that did the shoving
 * @param victim	the client that was shoved (CAUTION: retrieved from function pointer, dont meddle with it)
 * @param vector	Vector Angle of Shoveforce
 *
 * @return 		Pl_Handled to block melee effect (staggering), Pl_Continue otherwise.
 */
forward Action L4D_OnShovedBySurvivor(int client, int victim, const float vecDirection[3]);

/**
 * @brief Called whenever CTerrorPlayer::GetCrouchTopSpeed() is invoked
 *
 * @param target	the client that its being called on (not changible)
 * @param retVal  what to override the return value with
 * 
 * @return 		Pl_Handled to override return value, Pl_Continue otherwise.
 */
forward Action L4D_OnGetCrouchTopSpeed(int target, float &retVal);

/**
 * @brief Called whenever CTerrorPlayer::GetRunTopSpeed() is invoked
 *
 * @param target	the client that its being called on (not changible)
 * @param retVal  what to override the return value with
 * 
 * @return 		Pl_Handled to override return value, Pl_Continue otherwise.
 */
forward Action L4D_OnGetRunTopSpeed(int target, float &retVal);

/**
 * @brief Called whenever CTerrorPlayer::GetWalkTopSpeed() is invoked
 *
 * @param target	the client that its being called on (not changible)
 * @param retVal  what to override the return value with
 * 
 * @return 		Pl_Handled to override return value, Pl_Continue otherwise.
 */
forward Action L4D_OnGetWalkTopSpeed(int target, float &retVal);

/**
 * @brief Called whenever CTerrorGameRules::HasConfigurableDifficultySetting() is invoked
 * @remarks used to deny/allow difficulty changes in different game modes
 *
 * @param retVal  what to override the return value with. 1 to allow difficulty configuration, 0 to deny.
 * 
 * @return 		Pl_Handled to override return value, Pl_Continue otherwise.
 */
forward Action L4D_OnHasConfigurableDifficulty(int &retVal);

/**
 * @brief Called whenever CTerrorGameRules::GetSurvivorSet(void) is invoked
 *
 * @param retVal  what to override the return value with
 * 
 * @return 		Pl_Handled to override return value, Pl_Continue otherwise.
 */
forward Action L4D_OnGetSurvivorSet(int &retVal);

/**
 * @brief Called whenever CTerrorGameRules::FastGetSurvivorSet(void) is invoked
 *
 * @param retVal  what to override the return value with
 * 
 * @return 		Pl_Handled to override return value, Pl_Continue otherwise.
 */
forward Action L4D_OnFastGetSurvivorSet(int &retVal);

/**
 * @brief Called whenever CDirectorVersusMode::GetMissionVersusBossSpawning() is invoked
 * @remarks Passed values are from the map's Mission Keyvalues. If those keyvalues don't exist, they are from cvar and other globals
 *
 * @param spawn_pos_min		Minimum spawn position (percent of flow distance) for bosses
 * @param spawn_pos_max		Maximum spawn position (perfect of flow distance) for bosses
 * @param tank_chance		Chance for a tank to spawn on this map
 * @param witch_chance		Chance for a witch to spawn on this map
 * 
 * @return 		Pl_Handled to block reading map data, Pl_Changed to use overwritten values from plugin, Pl_Continue to continue to read from mission data.
 */
forward Action L4D_OnGetMissionVSBossSpawning(float &spawn_pos_min, float &spawn_pos_max, float &tank_chance, float &witch_chance);

/**
 * @brief Called whenever CThrow::ActivateAbility(void) is invoked
 * @remarks Called when a tank throws a rock. Blocking this call will
 *			keep the tank from throwing a rock.
 *
 * @param ability	ability_throw entity index
 * 
 * @return 		Pl_Handled to block, Pl_Continue otherwise
 */
forward Action L4D_OnCThrowActivate(int ability);

/**
 * @brief Called whenever InfectedShoved::OnShoved(Infected *, CBaseEntity *) is invoked
 * @remarks Called when common Infected are about to get shoved
 * 
 * @return 		Pl_Handled to block, Pl_Continue otherwise
 */
forward Action L4D_OnInfectedShoved(int infected, int entity);

/**
 * @brief Called whenever CTerrorMeleeWeapon::StartMeleeSwing(CTerrorPlayer *, bool) is invoked
 * @remarks Called when a player uses his melee Weapons primary attack. This is before the game
 *			reads the melee weapon data (model etc) and decides if he CAN attack at all.
 * 
 * @return 		Pl_Handled to block, Pl_Continue otherwise
 */
forward Action L4D_OnStartMeleeSwing(int client, bool boolean);

/**
 * @brief Called whenever CDirectorScriptedEventManager::SendInRescueVehicle(void) is invoked
 * @remarks Called when the last Finale stage is reached and the Rescue Means becomes 'available'.
 *			Take note this forward WILL fire upon using the native of the same function.
 * 
 * @return 		Pl_Handled to block, Pl_Continue otherwise
 */
forward Action L4D2_OnSendInRescueVehicle();

/**
 * @brief Called whenever CDirectorScriptedEventManager::ChangeFinaleStage is invoked
 *
 * @param FinaleStageType	integer value
 * @remarks some values for FinaleStageType: 1 - Finale Started; 6 - Rescue Vehicle Ready; 7 - Zombie Hordes; 8 - Tank; 10 - Combat Respite (nothing spawns)
 * @remarks SendInRescueVehicle does not depend on Finale Stage being 6, that only signals endless Hordes/Tanks
 * 
 * @return 		Pl_Handled to block, Pl_Continue otherwise
 */
forward Action L4D2_OnChangeFinaleStage(int &finaleType, const char[] arg);

/**
 * @brief Called whenever CDirectorVersusMode::EndVersusModeRound(bool) is invoked
 *
 * @param countSurvivors	True if the survival multiplier count needs to be nonzero. I guess.
 * @remarks Not sure what bool does exactly yet. Just monitor it. If true, survivors will be counted for multiplier. If false, survival multiplier will be set to 0.
 * @remarks A lot of Score calculations happen on this function, and the round-end scoreboard comes up doing this. Don't block unless you're sure you can reproduce this logic.
 * 
 * @return 		Pl_Handled to block, Pl_Continue otherwise
 */
forward Action L4D2_OnEndVersusModeRound(bool countSurvivors);

/**
 * @brief Called after CDirectorVersusMode::EndVersusModeRound(bool)
 * @remarks Called after all score calculations inside CDirectorVersusMode::EndVersusModeRound(bool). This good forward to replace standard "round_end" hook.
 * 
 * @return 		noreturn
 */
forward void L4D2_OnEndVersusModeRound_Post();

/**
 * @brief Called when CBaseAnimating::SelectWeightedSequence(int Activity) is invoked with tank attack activity
 * @remarks Called whenever a tank uses his primary (punch) or secondary (throw) attack
 *
 * @param client   the client that is playing as tank
 * @param sequence  current selected sequence for attack, option to override the return value with it
 * @remarks	sequences(punches): 40(uppercut), 43(right hook), 45(left hook), 46 and 47 (pounding the ground)
 * @remarks	sequences(throws): 48(undercut), 49(1handed overhand), 50(throw from the hip), 51(2handed overhand)
 * 
 * @return 		Pl_Handled to override return value, Pl_Continue otherwise.
 */
forward Action L4D2_OnSelectTankAttack(int client, int &sequence);

/**
 * @brief Called when CTerrorPlayer::OnRevived(void) is invoked
 * @remarks Called post-revive so all data values are post-revive status.
 *
 * @param client   the client that has been revived
 *
 * @noreturn Pl_Handled to override return value, Pl_Continue otherwise.
 */
forward Action L4D2_OnRevived(int client);

/**
 * @brief Called when SurvivorBot::UseHealingItems(Action<SurvivorBot> *) is invoked
 * @remarks Causes bots to use or give healing items (except in safe room on non-expert)
 *
 * @param client	the client that will decide whether to use healing items
 *
 * @noreturn Pl_Handled to block, Pl_Continue otherwise.
 */
forward Action L4D2_OnUseHealingItems(int client);

/**
 * @brief Called after SurvivorBot::FindScavengeItem(Action<SurvivorBot> *) is invoked
 * @remarks Indicates which item the Survivor Bot will attempt to pick up
 *
 * @param client	the client that will try to pick something up
 * @param item		the item the client will try to pick up (null means no item)
 *
 * @noreturn Pl_Handled to block, Pl_Continue otherwise.
 */
forward Action L4D2_OnFindScavengeItem(int client, int item);

/**
 * @brief Called whenever CBasePlayer::WaterMove() is invoked
 * @remarks Couple it with a FL_INWATER check to be sure
 *
 * @param client	the client that is moving in the water
 *
 * @noreturn
 */
forward void L4D2_OnWaterMove(int client);

/**
 * @brief Called whenever CTerrorPlayer::OnStaggered(CBaseEntity *, Vector const *) is invoked
 * @remarks Source is always null for Charger impacts(Valve)
 *
 * @param target	the client that is about to get staggered
 * @param source	the client that is about to stagger the target
 *
 * @return 		Pl_Handled to block, Pl_Continue otherwise
 */
forward Action L4D2_OnStagger(int target, int source);

/**
 * @brief Called whenever CTerrorWeapon::OnHit(CGameTrace &, Vector  const&, bool) is invoked
 * @remarks Called for every single shovable and even some of the unshovable entities in the game
 *
 * @param client	survivor who did the shoving
 * @param entity	entity that is about to get shoved
 * @param weapon	weapon that has been held while shoving
 * @param vector	not sure what are these coordinates, probably some kind of shove distance
 * @param bIsHunterDeadstop	    a boolean to determine if it was a pounce from a height or not; reliable to a certain degree and should only be considered for hunters
 *
 * @return 		Pl_Handled to block, Pl_Continue otherwise
 */
forward Action L4D2_OnEntityShoved(int client, int entity, int weapon, float vector[3], bool bIsHighPounce);

/**
 * @brief Called when the client's material system is expecting instructions from the server in regards to addons
 * @remarks Doesn't fire if l4d2_addons_eclipse is -1 or 0
 *
 * @param SteamID   SteamID of the client expecting a matsys reply
 *
 * @return      Pl_Handled to let the client through with addons, Pl_Continue otherwise.
 */
forward Action L4D2_OnClientDisableAddons(const char[] SteamID);

/**
 * @brief Called whenever CTerrorPlayer::OnShovedByPounceLanding(CTerrorPlayer*) is invoked
 *
 * @param victim	the survivor that is about to get stumbled as a result of "attacker" capping someone in close proximity
 * @param attacker	the SI that is about to cause a stumble as a result of capping someone in close proximity to a survivor
 *
 * @return 		Pl_Handled to block, Pl_Continue otherwise
 */
forward Action L4D2_OnPounceOrLeapStumble(int victim, int attacker);

/**
 * @brief Called whenever BossZombiePlayer(CTerrorPlayer *, int, CBaseEntity *) is invoked
 *
 * @param specialInfected	the SI entity index
 * @param curTarget			the survivor player index who is chosen victim
 *
 * @return 		Pl_Handled to block, Pl_Changed to use overwritten values from plugin, Pl_Continue otherwise
 */
forward Action L4D2_OnChooseVictim(int specialInfected, int &curTarget);

/**
 * @brief Get the current campaign scores stored in the Director
 * @remarks The campaign scores are updated after L4D_OnSetCampaignScores
 * 
 * @deprecated This will set the scores to -1 for both sides on L4D2,
 *               this function is no longer supported.
 * 
 * @param scoreA  score of logical team A
 * @param scoreB  score of logical team B
 * @return 		1 always
 */
#pragma deprecated Use GetTeamScore and OnClearTeamScores instead
native int L4D_GetCampaignScores(int &scoreA, int &scoreB);

/**
 * @brief Get the team scores for the current map
 * @remarks The campaign scores are not set until the end of round 2,
 *           use L4D_GetCampaignScores to get them earlier.
 *
 * @deprecated This function can be called through SDKTools using CTerrorGameRules,
 *          and so you should switch off to using SDKTools instead of this native.
 * 
 * @param logical_team  0 for A, 1 for B
 * @param campaign_score  true to get campaign score instead of map score
 * @return 		the logical team's map score 
 *                      or -1 if the team hasn't played the round yet,
 *                or the team's campaign score if campaign_score = true
 */
native int L4D_GetTeamScore(int logical_team, bool campaign_score=false);

/**
 * @brief Restarts the setup timer (when in scavenge mode)
 * @remarks If game has already started, the setup timer will show,
 *           but it still won't go back into setup.
 */
native void L4D_ScavengeBeginRoundSetupTime();

/**
 * @brief Restarts the round, switching the map if necessary
 * @remarks Set the map to the current map to restart the round
 * 
 * @param map  the mapname it should go to after the round restarts
 * @return     1 always
 */
native void L4D_RestartScenarioFromVote(const char[] map);

/**
 * @brief Removes lobby reservation from a server
 * @remarks Sets the reservation cookie to 0,
 *           it is safe to call this even if it's unreserved.
 */
native void L4D_LobbyUnreserve();

/**
 * @brief Checks if the server is currently reserved for a lobby
 * @remarks Server is automatically unreserved if it hibernates or
 *          if all players leave.
 *
 * @deprecated This will always return false on L4D2 or on Linux.
 *
 * @return     true if reserved, false if not reserved
 */
#pragma deprecated This will always return false on L4D2 or on Linux.
native bool L4D_LobbyIsReserved();

/**
 * @brief Gets the max versus completion score for the map
 * @remarks Requires GameRules to be initialized--map must be loaded
 *           Seems to be updated before OnMapStart
 *
 *
 * @return     The map's max completion distance (map distance score)
 */
native int L4D_GetVersusMaxCompletionScore();

/**
 * @brief Sets the max versus completion score for the map
 * @remarks Requires GameRules to be initialized--map must be loaded
 *           Seems to be updated before OnMapStart and checked on round_start
 *
 * @param	score	The versus max completion score to set for the round
 */
native void L4D_SetVersusMaxCompletionScore(int score);

/**
 * @brief Tells if the Mission (map) is the first map of the campaign
 *
 * @return		true if the map is the first map of the campaign
 */
native bool L4D_IsFirstMapInScenario();

/**
 * @brief Tells if the Mission (map) is the final map of the campaign
 *
 * @return		true if the map is the last map of the campaign (finale)
 */
native bool L4D_IsMissionFinalMap();

/**
 * @brief Resets the natural mob (horde) timer
 * @remarks	Requires the Director to be available--map must be started
 *
 * @noreturn
 */
native void L4D_ResetMobTimer();

/**
 * @brief Notifies the CGameRulesProxy that the game state has been changed
 * @remarks Use this function before changing networked members of GameRules,
 *           like with L4D_SetVersusMaxCompletionScore()
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
 * @param vecSource 	Source location of the stagger. If NULL_VECTOR, origins of source_ent is used.
 * @noreturn 				
 */
native void L4D_StaggerPlayer(int target, int source_ent, float vecSource[3]);

/**
 * @brief Get the time remaining before the next director horde. 
 * @remarks This timer is used for scripted event hordes and natural timed hordes
 * 
 * @return 	Time remaining before next director horde
 */
#pragma deprecated Use L4D2_CTimerGetRemainingTime(L4D2CT_MobSpawnTimer)
native float L4D_GetMobSpawnTimerRemaining();

/**
 * @brief Get the duration the horde timer was set to after the last horde
 * @remarks This timer is used for scripted event hordes and natural timed hordes
 * 
 * @return 	Total time from last horde to next horde.
 */
#pragma deprecated Use L4D2_CTimerGetCountdownDuration(L4D2CT_MobSpawnTimer)
native float L4D_GetMobSpawnTimerDuration();

/**
 * @brief Get the remaining spawn time for an SI
 * @remarks This is meant for Special infected in ghost mode in versus.
 * 
 * @return 	Time (seconds) until the SI will spawn.
 */
native float L4D_GetPlayerSpawnTime(int player);

/**
 * @brief Calls CDirectorScriptedEventManager::SendInRescueVehicle(void)
 *
 * @remarks will fire the forward of the same function
 * 
 * @noreturn
 */
native void L4D2_SendInRescueVehicle();

/**
 * @brief Calls ZombieManager::ReplaceTank(CTerrorPlayer *,CTerrorPlayer *)
 *
 * @param tank	the player who was a tank
 * @param newtank	a player who has become a new tank
 */
native void L4D_ReplaceTank(int tank, int newtank);

/**
 * @brief Calls CDirectorScriptedEventManager::ChangeFinaleStage(CDirectorScriptedEventManager::FinaleStageType,char  const*)
 *
 * @param FinaleStageType	integer value
 * @remarks some values for FinaleStageType: 1 - Finale Started; 6 - Rescue Vehicle Ready; 7 - Zombie Hordes; 8 - Tank; 10 - Combat Respite (nothing spawns)
 * @remarks
 * @remarks will fire the forward of the same function
 *
 * @noreturn
 */
native void L4D2_ChangeFinaleStage(int finaleType, const char[] arg);

/**
 * @brief Calls ZombieManager::SpawnTank(Vector&,QAngle&)
 *
 * @param vector	Vector coordinate where the tank will be spawned
 * @param qangle	QAngle where the tank will be facing
 * @return 			Entity index of the spawned tank
 */
native int L4D2_SpawnTank(const float vecOrigin[3], const float vecAngles[3]);

/**
 * @brief Calls ZombieManager::SpawnSpecial(ZombieClassType,Vector&,QAngle&)
 * @remarks Only used for bot special spawns (not players)
 *
 * @param vector	Vector coordinate where the SI will be spawned
 * @param qangle	QAngle where the SI will be facing
 * @return 			Entity index of the spawned SI
 */
native int L4D2_SpawnSpecial(int zombieClass, const float vecOrigin[3], const float vecAngles[3]);

/**
 * @brief Calls ZombieManager::SpawnWitch(Vector&,QAngle&)
 *
 * @param vector	Vector coordinate where the witch will be spawned
 * @param qangle	QAngle where the witch will be facing
 * @return 			Entity index of the spawned witch
 */
native int L4D2_SpawnWitch(const float vecOrigin[3], const float vecAngles[3]);

/**
 * @brief Calls ZombieManager::SpawnWitchBride(Vector&,QAngle&)
 *
 * @param vector	Vector coordinate where the witch bride will be spawned
 * @param qangle	QAngle where the witch bride will be facing
 * @return 			Entity index of the spawned witch bride
 */
native int L4D2_SpawnWitchBride(const float vecOrigin[3], const float vecAngles[3]);

/*
Makes the extension required by the plugins, undefine REQUIRE_EXTENSIONS
if you want to use it optionally before including this .inc file
*/
public Extension __ext_left4downtown = 
{
	name = "Left 4 Downtown",
	file = "left4downtown.ext",
#if defined AUTOLOAD_EXTENSIONS
	autoload = 1,
#else
	autoload = 0,
#endif
#if defined REQUIRE_EXTENSIONS
	required = 1,
#else
	required = 0,
#endif
};
