/*
*	Left 4 DHooks Direct
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



#define PLUGIN_VERSION		"1.71"

#define DEBUG				0
// #define DEBUG			1	// Prints addresses + detour info (only use for debugging, slows server down)

#define DETOUR_ALL			0	// Only enable required detours, for public release.
// #define DETOUR_ALL		1	// Enable all detours, for testing.

#define KILL_VSCRIPT		0	// 0=Keep VScript entity after using for "GetVScriptOutput". 1=Kill the entity after use (more resourceful to keep recreating, use if you're maxing out entities and reaching the limit regularly).



/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Left 4 DHooks Direct
*	Author	:	SilverShot
*	Descrp	:	Left 4 Downtown and L4D Direct conversion and merger.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=321696
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.71 (07-Nov-2021)
	- Fixed native "L4D2_GetSurvivorSetMod" not being restricted to L4D2. Thanks to "HarryPotter" for reporting.
	- Plugin now loads about 1 second faster and no longer creates about 1 second delay on map changes.
	- Changes to the "sm_l4dd_detours" and "sm_l4dhooks_detours" commands to prevent errors when using the DEBUG or DETOUR defines.

1.70 (07-Nov-2021)
	- Added native "L4D_TankRockPrj" to create a Tank Rock projectile.
	- Added native "L4D_DetonateProjectile" to detonate grenade projectiles.
	- Added natives to L4D2: "L4D2_GetSurvivorSetMap" and "L4D2_GetSurvivorSetMod" to return the maps and modified Survivor set.
	- Changed forwards "L4D_OnGetSurvivorSet" and "L4D_OnFastGetSurvivorSet" to post hooks to retrieve the correct value. Thanks to "Gabe Iggy" for reporting.
	- Fixed detours "OnShovedBySurvivor_Clone" and "OnStaggered_Clone" being broken on L4D1 linux. Thanks to "HarryPotter" for reporting.

	- GameData files, include file and plugins updated.

1.69a (04-Nov-2021)
	- Added missing forwards "L4D_OnPouncedOnSurvivor" and "L4D2_OnStartCarryingVictim" to the include file. Thanks to "ProjectSky" for reporting.

1.69 (03-Nov-2021)
	- Added forward "L4D_OnPouncedOnSurvivor" to notify when a Survivor is being pounced on by a Hunter.
	- Added forward "L4D2_OnStartCarryingVictim" to L4D2 to notify when a Survivor is being grabbed by a Charger.
	- Fixed some natives disabling the plugin if their signatures broke. Only their functionality will break.

	- GameData files, include file and plugins updated.

1.68 (02-Nov-2021)
	- Added forward "L4D_OnGrabWithTongue" to L4D2 to notify when someone is about to be grabbed by a Smoker Tongue. Requested by "Alexmy".
	- Added forward "L4D2_OnJockeyRide" to notify when someone is about to be ridden by a Jockey. Requested by "Alexmy".
	- Cleaned and consolidated the code: standardized gamedata names, function names and variable names.
	- Compatibility support for SourceMod 1.11. Fixed various warnings.

	- GameData files, include file and plugins updated.

1.67 (25-Oct-2021)
	- Fixed the create projectile natives from failing still when passing 0 entity index. Thanks to "BHaType" for reporting.
	- Fixed L4D1 Linux forward "TryOfferingTankBot" sometimes throwing errors. Thanks to "HarryPotter" for reporting.
	- Fixed L4D1 setting "L4D2FWA_PenetrationNumLayers" - float values will be rounded to ceiling. Thanks to "epzminion" for finding and "Psyk0tik" for reporting.
	- Fixed target filters "@isb" and "@isp" being flipped.

1.66 (21-Oct-2021)
	- Fixed L4D1 Linux not finding the "g_pWeaponInfoDatabase" signature. Thanks to "Ja-Forces" for reporting.
	- L4D1 GameData updated.

1.65 (20-Oct-2021)
	- Changed forward "L4D2_CGasCan_EventKilled" params to show the inflictor and attacker.
	- Thanks to "ProjectSky" for reminding me.

	- Plugins and include file updated.

1.64 (20-Oct-2021)
	- Added 1 new forward to L4D1 and L4D2:
		- "L4D_CBreakableProp_Break" - When a physics prop is broken.

	- Added 3 new forwards to L4D2:
		- "L4D2_CGasCan_EventKilled" - When a GasCan is destroyed.
		- "L4D2_CGasCan_ActionComplete" - When a Survivor has finished pouring gas.
		- "L4D2_CInsectSwarm_CanHarm" - When Spitter Acid is checking if a player or entity can be damaged.

	- Added 1 new native to L4D1 and L4D2:
		- "L4D_GetWeaponID" - to get the Weapon ID by classname

	- Added and unlocked all the weapon attribute modification natives to L4D1:
	- Thanks to "Psyk0tik" for the suggestion and information about offsets.
		- "L4D2_IsValidWeapon"
		- "L4D2_GetFloatWeaponAttribute" and "L4D2_SetFloatWeaponAttribute"
		- "L4D2_GetIntWeaponAttribute" and "L4D2_SetIntWeaponAttribute"
		- "L4D2IntWeaponAttributes" enums - ("L4D2IWA_Bullets", "L4D2IWA_Damage", "L4D2IWA_ClipSize")
		- "L4D2FloatWeaponAttributes" enums - ("L4D2FWA_MaxPlayerSpeed", "L4D2FWA_SpreadPerShot", "L4D2FWA_MaxSpread", "L4D2FWA_Range", etc)

	- Added new target filters:
		"@deads" - Dead Survivors (all, bots)
		"@deadsi" - Dead Special Infected (all, bots)
		"@deadsp" - Dead Survivors players (no bots)
		"@deadsip" - Dead Special Infected players (no bots)
		"@deadsb" - Dead Survivors bots (no players)
		"@deadsib" - Dead Special Infected bots (no players)
		"@sp" - Survivors players (no bots)
		"@sip" - Special Infected players (no bots)
		"@isb" - Incapped Survivor Only Bots
		"@isp" - Incapped Survivor Only Players

	- Changed target filter names:
		"@incappedsurvivorbot" to "@rincappedsurvivorbot"
		"@isb" to "@risb"
		"@survivorbot" to "@rsurvivorbot"
		"@sb" to "@rsb"
		"@infectedbot" to "@rinfectedbot"
		"@ib" to "@rib"
		"@tankbot" to "@rtankbot"
		"@tb" to "@rtb"

	- Added "FINALE_*" enums to the include file for use with the "L4D2_ChangeFinaleStage" and "L4D2_GetCurrentFinaleStage" natives and "L4D2_OnChangeFinaleStage" forward.
	- Thanks to "Dragokas" for suggesting.

	- GameData files, include file and plugins updated.

1.63 (15-Oct-2021)
	- Changed all projectile natives to allow passing 0 (world) instead of a client index. Thanks to "BHaType" for reporting.
	- Changed forward "L4D_OnGameModeChange" from "Action" type to "Void". Thanks to "Psyk0tik" for reporting.
	- Fixed commands "sm_l4dd_detours" and "sm_l4dhooks_detours" not showing all forwards when they have pre and post hooks.

	- Added 11 new forwards to L4D1 and L4D2. Thanks to "Psyk0tik" for the suggestions, signatures and detour functions.
		- "L4D_TankClaw_DoSwing_Pre" - When a tank is swinging to punch.
		- "L4D_TankClaw_DoSwing_Post" - When a tank is swinging to punch.
		- "L4D_TankClaw_GroundPound_Pre" - When an tank punches the ground.
		- "L4D_TankClaw_GroundPound_Post" - When an tank punches the ground.
		- "L4D_TankClaw_OnPlayerHit_Pre" - When a tank swings and punches a player.
		- "L4D_TankClaw_OnPlayerHit_Post" - When a tank swings and punches a player.
		- "L4D_TankRock_OnDetonate" - When a tank rock hits something.
		- "L4D_TankRock_OnRelease" - When a tank rock is thrown.
		- "L4D_PlayerExtinguish" - When a player is about to be extinguished.
		- "L4D_PipeBombProjectile_Pre" - When a PipeBomb projectile is being created.
		- "L4D_PipeBombProjectile_Post" - After a PipeBomb projectile is created.

	- Added 1 new forward to L4D2. Thanks to "Lux" for the suggestion, signature and detour functions.
		- "L4D2_MeleeGetDamageForVictim" - When calculating melee damage to inflict on something.

	- GameData files, include file and plugins updated.

1.62 (08-Oct-2021)
	- L4D1 Linux: Update thanks to "Forgetest" for writing.
	- L4D1 Linux: Fixed issues with the forwards "L4D_OnShovedBySurvivor" and "L4D2_OnStagger". Thanks "HarryPotter" for reporting.

	- L4D1 GameData file and plugin updated.

1.61 (05-Oct-2021)
	- Added natives "L4D_GetTempHealth" and "L4D_SetTempHealth" to handle Survivors temporary health buffer.
	- Added natives "L4D_PlayMusic" to play a specified music string to a client. Thanks to "DeathChaos25" and "Shadowysn" for "Dynamic Soundtrack Sets" plugin.
	- Added natives "L4D_StopMusic" to stop playing a specified music string to a client. Thanks to "DeathChaos25" and "Shadowysn" for "Dynamic Soundtrack Sets" plugin.
	- Moved the animation ACT_* enums from "include/left4dhooks.inc" to "include/left4dhooks_anim.inc". Suggested by "Accelerator". No plugin changes required.

	- Thanks to "Psyk0tik" for requesting the following forwards and natives and their signatures found here: https://github.com/Psykotikism/L4D1-2_Signatures

	- Added natives:
		- "L4D2_HasConfigurableDifficultySetting" - Returns if there is a configurable difficulty setting.
		- "L4D2_IsGenericCooperativeMode" - Returns if the current game mode is Coop/Realism mode.
		- "L4D_IsCoopMode" - Returns if the current game mode is Coop mode.
		- "L4D2_IsRealismMode" - Returns if the current game mode is Realism mode.
		- "L4D2_IsScavengeMode" - Returns if the current game mode is Scavenge mode.
		- "L4D_IsSurvivalMode" - Returns if the current game mode is Survival mode.
		- "L4D_IsVersusMode" - Returns if the current game mode is Versus mode.

	- Added forwards:
		- "L4D_OnFalling" - Called when a player is falling.
		- "L4D_OnFatalFalling" - Called when a player is falling in a fatal zone.
		- "L4D2_OnPlayerFling" - Called when a player is flung to the ground.
		- "L4D_OnEnterStasis" - Called when a Tank enters stasis mode in Versus mode.
		- "L4D_OnLeaveStasis" - Called when a Tank leaves stasis mode in Versus mode.

	- GameData files, include file and plugins updated.

1.60 (29-Sep-2021)
	- Added native "L4D2_GrenadeLauncherPrj" to create an activated Grenade Launcher projectile which detonates on impact. L4D2 only.
	- Fixed L4D1 Linux "CMolotovProjectile::Create" signature. Thanks to "Ja-Forces" for reporting.

1.59 (29-Sep-2021)
	- HotFix: Fix Linux not loading the last 2 natives.

1.58 (29-Sep-2021)
	- Added native "L4D_MolotovPrj" to create an activated Molotov projectile which detonates on impact.
	- Added native "L4D2_VomitJarPrj" to create an activated VomitJar projectile which detonates on impact. L4D2 only.
	- Added "STATE_*" enums to the include file for use with the "L4D_State_Transition" native. Thanks to "BHaType" for providing.
	- Fixed some incorrect information in the include file. Thanks to "jackz" for reporting.

	- GameData files, include file and plugins updated.

1.57 (18-Sep-2021)
	- Changed the method for getting the current GameMode. Should have no more issues. Thanks to "ddd123" for reporting.
	- L4D2: Wildcarded the "CTerrorPlayer::Fling" signature for compatibility with being detoured. Thanks to "ddd123" for reporting.

	- L4D2 GameData file and plugin updated.

1.56 (15-Sep-2021)
	- Fixed spawning an entity directly OnMapStart (can cause crashes), delayed by a frame to fix errors. Thanks to "fdxx" for reporting.

1.55 (12-Sep-2021)
	- Fixed native "L4D2Direct_TryOfferingTankBot" not working for L4D1 Linux due to the last update. Thanks to "Forgetest" for reporting.
	- L4D1 gamedata file updated only.

1.54 (12-Sep-2021)
	- Big thanks to "Forgetest" and "HarryPotter" for helping fix and test this release.

	- Added forward "L4D_OnGameModeChange" to notify plugins when the mode has changed to Coop, Versus, Survival and Scavenge (L4D2).
	- Added native "L4D_GetGameModeType" to return if the current game mode is Coop, Versus, Survival or Scavenge (L4D2).

	- Update for L4D1:

	- Fixed on Linux forward "L4D_OnSpawnWitch" from not triggering for some Witch spawns. Thanks to "Forgetest" for fixing.
	- Fixed on Linux forward "L4D_OnTryOfferingTankBot" from not triggering on the first tank. Thanks to "Forgetest" for fixing.
	- Unlocked native "L4D2Direct_GetMobSpawnTimer" for usage in L4D1. Thanks to "HarryPotter" for reporting functionality.
	- Unlocked native "L4D2Direct_GetTankCount" for usage in L4D1. Missed this from the last update.

	- L4D1 GameData file, include file and plugins updated.

1.53 (09-Sep-2021)
	- Update for L4D1:

	- Added forward "L4D_OnRecalculateVersusScore" from "raziEiL"'s port of "L4D Direct".
	- Added natives "L4DDirect_GetSurvivorHealthBonus", "L4DDirect_SetSurvivorHealthBonus" and "L4DDirect_RecomputeTeamScores" from "raziEiL"'s port of "L4D Direct".
	- Changed native "L4D2_GetTankCount" to use the directors variable instead of counting entities. Thanks to "Forgetest" for the offsets.
	- Unblocked native "L4D_GetTeamScore" for usage in L4D1. Accepts logical_team params 1-6.
	- Fixed forward "L4D_OnFirstSurvivorLeftSafeArea" not blocking correctly. Thanks to "Forgetest" for the solution.
	- Various fixes and additions thanks to "HarryPotter" for requesting and testing.

	- L4D1 GameData file, include file and plugins updated.

1.52 (31-Aug-2021)
	- Added L4D1 and L4D2 specific "ACT_*" animation activity constants to the include file for usage in animation pre-hooks. See the include file for details.
	- Wildcarded "RestartScenarioFromVote" detour to be compatible with the "[L4D2] Restart Without Changelevel" plugin by "iaNanaNana".
	- Various minor changes to the code legibility.

1.51 (10-Aug-2021)
	- Added natives "L4D_GetCurrentChapter" and "L4D_GetMaxChapters" to get the current and max chapters count. Thanks to "Psyk0tik" for help.
	- L4D1: Added natives "L4D_GetVersusMaxCompletionScore" and "L4D_SetVersusMaxCompletionScore" to get/set Versus max score. Thanks to "BHaType" for offsets.
	- L4D1: Fixed broken "CThrowActivate" signature due to the 1.0.4.0 update. Thank to "matrixmark" for reporting.

	- GameData files, include file and plugins updated.

1.50 (22-Jul-2021)
	- Fixed "Native was not found" errors in L4D1. Thanks to "xerox8521" for reporting.
	- Test plugin: Fixed "L4D_OnMaterializeFromGhostPre" and "L4D_OnMaterializeFromGhost" throwing "String formatted incorrectly" errors.

1.49 (13-Jul-2021)
	- L4D2: Fixed the "SpawnTimer" offset being wrong. Thanks to "Forgetest" for reporting.
	- L4D2: GameData file updated.

1.48 (13-Jul-2021)
	- Fixed "Param is not a pointer" in the "L4D_OnVomitedUpon" forward. Thanks to "ddd123" for reporting.
	- L4D2: Changed the way "ForceNextStage" address is read on Windows, hopefully future proof.

1.47 (10-Jul-2021)
	- Fixed "Trying to get value for null pointer" in the "L4D_OnVomitedUpon" forward. Thanks to "Shadowart" for reporting.

1.46 (09-Jul-2021)
	- L4D2: Added native "L4D2_ExecVScriptCode" to exec VScript code instead of having to create an entity to fire code.
	- L4D2: Fixed GameData file from the "2.2.2.0" game update.

1.45 (04-Jul-2021)
	- Fixed bad description for "L4D_SetHumanSpec" and "L4D_TakeOverBot" in the Include file.
	- L4D1: Fixed forward "L4D_OnVomitedUpon" crashing. GameData file updated. Thanks to "Psyk0tik" for reporting.

1.44 (01-Jul-2021)
	- Fixed forward "L4D_OnMaterializeFromGhost" not firing. Thanks to "ProjectSky" for reporting.
	- Fixed changelog description. Thanks to "Spirit_12" for reporting.

1.43 (01-Jul-2021)
	- L4D1 & L4D2 update:
	- Added forward "L4D_OnMaterializeFromGhostPre" and "L4D_OnMaterializeFromGhost" when a client spawns out of ghost mode. Thanks to "ProjectSky" and "sorallll" and for suggesting.

	- Added native "L4D_RespawnPlayer" to respawn a dead player.
	- Added native "L4D_SetHumanSpec" to takeover a bot.
	- Added native "L4D_TakeOverBot" to takeover a bot.
	- Added native "L4D_CanBecomeGhost" to determine when someone is about to enter ghost mode.
	- Added native "L4D2_AreWanderersAllowed" to determine if Witches can wander.
	- Added native "L4D_IsFinaleEscapeInProgress" to determine when the rescue vehicle is leaving until.
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

1.41 (18-Jun-2021)
	- L4D2: Fixed "InvulnerabilityTimer" offset. Thanks to "Nuki" for helping.
	- GameData .txt file updated.

1.40 (16-Jun-2021)
	- L4D2: Fixed various offsets breaking from "2.2.1.3" game update. Thanks to "Nuki" for reporting and helping.
	- GameData .txt file updated.

1.39 (16-Jun-2021)
	- Changed command "sm_l4dd_detours" results displayed to be read easier.
	- L4D2: Fixed signatures breaking from "2.2.1.3" game update. Thanks to "Psyk0tik" for fixing.
	- L4D2: Fixed "VanillaModeOffset" in Linux breaking from "2.2.1.3" game update. Thanks to "Accelerator74" for fixing.
	- GameData .txt file updated.

1.38 (28-Apr-2021)
	- Changed native "L4D2_IsReachable" to allow using team 2 and team 4.

1.37 (20-Apr-2021)
	- Removed "RoundRespawn" being used, was for private testing, maybe a future native. Thanks to "Ja-Forces" for reporting.

1.36 (20-Apr-2021)
	- Added optional forward "AP_OnPluginUpdate" from "Autoreload Plugins" by "Dragokas", to rescan required detours when loaded plugins change.
	- Fixed native "L4D2Direct_GetFlowDistance" sometimes returning -9999.0 when invalid, now returns 0.0;
	- Fixed native "L4D_FindRandomSpot" from crashing Linux servers. Thanks to "Gold Fish" for reporting and fixing and "Marttt" for testing.
	- Restricted native "L4D2_IsReachable" client index to Survivor bots only. Attempts to find a valid bot otherwise it will throw an error. Thanks to "Forgetest" for reporting.
	- Signatures compatibility with plugins detouring them. L4D1: "OnLedgeGrabbed", "OnRevived" and L4D2: "OnLedgeGrabbed". Thanks to "Dragokas" for providing.

	- Updated: L4D1 GameData file.
	- Updated: L4D2 GameData file.
	- Updated: Plugin and Include file.
	- Updated: Test plugin to reflect above changes.

1.35 (10-Apr-2021)
	- Fixed native "L4D_GetTeamScore" error message when using the wrong team values. Thanks to "BHaType" for reporting.
	- Restricted native "L4D2_IsReachable" client index to bots only. Attempts to find a valid bot otherwise it will throw an error. Thanks to "Forgetest" for reporting.

1.34 (23-Mar-2021)
	- Added native "L4D_HasPlayerControlledZombies" to return if players can control infected. Thanks to "Spirit_12" for requesting.
	- Thanks to "Psyk0tik" for the L4D1 signature.
	- Fixed Linux detection accidentally being broken from version 1.17 update.

	- Updated: L4D1 GameData file.
	- Updated: L4D2 GameData file.
	- Updated: Plugin and Include file.
	- Updated: Test plugin to reflect above changes.

1.33a (04-Mar-2021)
	- L4D1 GameData updated. Changes fixing "L4D2_OnEntityShoved" were missing from the previous update.

1.33 (02-Mar-2021)
	- Changed forward "L4D2_OnEntityShoved" to trigger for all entities being shoved not just clients.
	- Fixed forward "L4D2_OnEntityShoved" not working in L4D1. GameData file updated for L4D1.
	- Fixed native "L4D_IsFirstMapInScenario" crashing in L4D1 from changes in version 1.30 update.

1.32 (23-Feb-2021)
	- Changed native "L4D_GetRandomPZSpawnPosition" to accept client index of 0. Thanks to "Accelerator74" for reporting.
	- Fixed target filters misspelling "incapped". Thanks to "Forgetest" for reporting.

1.31 (23-Feb-2021)
	- Added Target Filters to target randomly. Requested by "Tonblader":
		"@incappedsurvivors", "@is"
		"@randomincappedsurvivor", "@ris"
		"@randomsurvivor", "@rs"
		"@randominfected", "@ri"
		"@randomtank", "@rt"
		"@incappedsurvivorbot", "@isb"
		"@survivorbot", "@sb"
		"@infectedbot", "@ib"
		"@tankbot", "@tb"

	- Fixed "L4D_GetPlayerSpawnTime" from returning the wrong value again. Thanks to "Forgetest" for reporting.

1.30 (15-Feb-2021)
	- Fixed natives "L4D2_SetIntMeleeAttribute" and "L4D2_SetFloatMeleeAttribute" functions. Thanks to "bw4re" for reporting.
	- Fixed native "L4D_GetPlayerSpawnTime" giving the wrong time. Thanks to "Forgetest" for reporting.

	- Fixes by "Dragokas"
	- Fixed native "L4D_IsFirstMapInScenario" call with SDKCall_Raw returned error in SM 1.11, L4D1. Thanks to "Crasher" for reporting, and "Rostu" for help.
	- Fixed "ForceNextStage" signature (WIN).

	- Updated: L4D2 GameData file.
	- Updated: Plugin.

1.29 (10-Oct-2020)
	- Fixed "L4D_StaggerPlayer" not working with NULL_VECTOR. Thanks to "Zippeli" for reporting.

1.28 (09-Oct-2020)
	- Added command "sm_l4dd_unreserve" to remove lobby reservation. Added for testing purposes but is functional.
	- Fixed L4D1 GameData failing to find "g_pServer" address. Thanks to "Ja-Forces" for reporting.
	- Fixed forward "L4D_OnFirstSurvivorLeftSafeArea" throwing errors about null pointer.

1.27 (05-Oct-2020)
	- Fixed not loading in L4D1 due to recent changes. Thanks to "TiTz" for reporting.

1.26 (01-Oct-2020)
	- L4D2: Fixed the new target filters not working correctly, now matches by modelname for Survivors instead of character netprop.

1.25 (01-Oct-2020)
	- Added survivor specific target filters:	@nick, @rochelle, @coach, @ellis, @bill, @zoey, @francis, @louis
	- Added special infected target filters:	@smokers, @boomers, @hunters, @spitters, @jockeys, @chargers
	- Changed native "L4D2_GetMeleeWeaponIndex" to return -1 instead of throwing an error, due to melee being unavailable.
	- Fixed melee weapon IDs being incorrect depending on which are enabled. Thanks to "iaNanaNana" for reporting.
	- Updated the "data/left4dhooks.l4d2.cfg" config with latest "ACT_*" animation numbers.

1.24 (27-Sep-2020)
	- Reverted change: native "L4D_GetTeamScore" now accepts values 1 and 2 again.
	- Changed natives:
		"L4D2Direct_GetVSTankFlowPercent", "L4D2Direct_SetVSTankFlowPercent", "L4D2Direct_GetVSTankToSpawnThisRound",
		"L4D2Direct_SetVSTankToSpawnThisRound", "L4D2Direct_GetVSWitchFlowPercent", "L4D2Direct_SetVSWitchFlowPercent",
		"L4D2Direct_GetVSWitchToSpawnThisRound" and "L4D2Direct_SetVSWitchToSpawnThisRound".
	- Corrected natives "roundNumber" to consider "m_bAreTeamsFlipped" and "m_bInSecondHalfOfRound".
	- Thanks to "devilesk" for native value clarification.

1.23 (27-Sep-2020)
	- Update by "ProdigySim" to fix Addons Eclipse. Thank you!
	- Updated: L4D2 GameData file.

1.22 (24-Sep-2020)
	- Compatibility update for L4D2's "The Last Stand" update.
	- Big thanks to "ProdigySim" for help updating various gamedata offsets and signatures.
	- Added support for the 2 new melee weapons.
	- Changed native "L4D_GetTeamScore" to accept values 0 and 1 which seems is the standard.
	- Late loading with debug enabled now shows the g_pGameRules pointer.
	- Moved hard coded Addon Eclipse offsets to gamedata.

1.21 (01-Sep-2020)
	- Removed teleporting the old and new tank players when using "L4D_ReplaceTank" native.

1.20 (28-Aug-2020)
	- Changed forward "L4D_OnEnterGhostState" hook from pre to post hook. Thanks to "Forgetest" for reporting.
	- Fixed forward "L4D_OnShovedBySurvivor" client and target order being wrong. Thanks to "Forgetest" for reporting.

1.19 (27-Aug-2020)
	- Fixed native "L4D2Direct_TryOfferingTankBot" from crashing the server. Thanks to "disawar1" for reporting.

1.18 (20-Aug-2020)
	- Thanks to "Forgetest" for reporting the following issues and testing multiple fixes.
	- Fixed natives using "L4D2CT_VersusStartTimer" from reading the incorrect address.
	- Fixed native "L4D2_IsValidWeapon" returning false when the classname is missing "weapon_".
	- Fixed address "g_pGameRules" being incorrect after certain map or mode changes, this broke the following natives:
		"L4D2_GetVersusCompletionPlayer", "L4D_GetVersusMaxCompletionScore" and "L4D_SetVersusMaxCompletionScore".

	- Note: native "L4D2_IsValidWeapon" and various "*WeaponAttribute" natives still returns invalid for CSS weapons.
		This only happens on the servers first load until map is changed and the CSS weapons are precached using whichever method
		your server uses to enable CSS weapons. Plugins using or modifying CSS weapons might need to be updated with this in mind.

1.17 (20-Jul-2020)
	- Added native (L4D2 only): "L4D2_IsReachable" to check if a position is accessible to a Survivor Bot.
	- Fixed include native "L4D2_AreTeamsFlipped" returning an int instead of bool. Thanks to "BloodyBlade" for reporting.
	- Fixed native "L4D_GetHighestFlowSurvivor" throwing errors in 1.11. Thanks to "yuzumi" for reporting.
	- Removed some useless "view_as" code. Might remove more in the future.

	- Updated: L4D2 GameData file.
	- Updated: Plugin and Include file.
	- Updated: Test plugin to reflect above changes.

1.16a (16-Jun-2020)
	- Fixed using the wrong offset for "m_PendingMobCount". Thanks to "fbef0102" for reporting.
	- Updated: GameData file for L4D2 Linux only.

1.16 (05-Jun-2020)
	- Added native "L4D_LobbyUnreserve" finally, to support "Remove Lobby Reservation (When Full)" plugin.
	- Huge thanks to "GAMMACASE" and "Deathreus" for helping figure why the native was crashing.

	- Updated: L4D1 GameData file.
	- Updated: Plugin and Include file.

1.15 (15-May-2020)
	- Added a valid entity check for "L4D2_OnFindScavengeItem" due to so many plugins passing bad entities and throwing errors.
	- Fixed "L4D_Dissolve" native description in the include file. Thanks to "Psyk0tik" for reporting.

1.14 (10-May-2020)
	- Added native (L4D2 only): "L4D2Direct_GetScriptedEventManager" to return the scripted event manager pointer.
	- This native replicates "L4D2_GetCDirectorScriptedEventManager" used by other plugins.

	- Added 19 missing natives from L4D2Direct (L4D1 and L4D2):
	- "CTimer_Reset", "CTimer_Start", "CTimer_Invalidate", "CTimer_HasStarted", "CTimer_IsElapsed", "CTimer_GetElapsedTime", "CTimer_GetRemainingTime",
	- "CTimer_GetCountdownDuration", "ITimer_Reset", "ITimer_Start", "ITimer_Invalidate", "ITimer_HasStarted", "ITimer_GetElapsedTime",
	- "CTimer_GetDuration", "CTimer_SetDuration", "CTimer_GetTimestamp", "CTimer_SetTimestamp", "ITimer_GetTimestamp", "ITimer_SetTimestamp"

	- Fixed "L4D_OnTryOfferingTankBot" not returning a valid client index.
	- Thanks to "Mis" for requesting changes and reporting bugs.

	- Updated: Plugin and Include file.
	- Updated: Test plugin to reflect above changes.

1.13 (05-May-2020)
	- Added better error log message when gamedata file is missing.
	- Fixed "L4D2_OnEntityShoved" not detecting the last client. Thanks to "Addie" for reporting.
	- Made all natives optional from the include file. Thanks to "Psyk0tik" for requesting.
	- Optional natives can be set by plugins with "#undef REQUIRE_PLUGIN" before "#include <left4dhooks>" and "#define REQUIRE_PLUGIN" after.

	- Updated: Plugin and Include file.
	- Updated: Test plugin to reflect above changes.

1.12 (09-Apr-2020)
	- Added commands "sm_l4dd_detours" and "sm_l4dd_reload" as wrappers to "sm_l4dhooks_detours" and "sm_l4dhooks_reload".
	- Fixed command "sm_l4dhooks_detours" displaying the wrong forward, now also displays the plugin name using that forward.

1.11 (18-Mar-2020)
	- Added command "sm_l4dhooks_detours" to display which forwards are enabled.
	- Added missing natives: "L4D2Direct_GetPendingMobCount" and "L4D2Direct_SetPendingMobCount" from "raziEiL"'s port.
	- Fixed native "L4D2_GetVScriptOutput" using the provided buffer to execute code. Buffer now can be small to get small return values.
	- Optimized native "L4D2_GetVScriptOutput" to reuse the same entity for multiple calls in the same frame.
	- Maximum native "L4D2_GetVScriptOutput" code allowed seems to be 1006 characters.

	- Updated: Plugin, Include and GameData files.
	- Updated: Test plugin to reflect above changes.

1.10 (14-Mar-2020)
	- Added natives (L4D1 & L4D2): "L4D_IsAnySurvivorInStartArea", "L4D_IsInFirstCheckpoint" and "L4D_IsInLastCheckpoint".
	- Added native (L4D2 only): "L4D2_GetCurrentFinaleStage".
	- Thanks to "Nuki" for requesting.

	- Fixed missing "L4D2IWA_ClipSize" offset. Now this works: L4D2_SetIntWeaponAttribute("weapon_rifle", L4D2IWA_ClipSize, 100);
	- See include for details.

	- Updated: Plugin, Include and GameData files.
	- Updated: Test plugin to reflect above changes.

1.9 (10-Mar-2020)
	- Added native (L4D2 only): "L4D2_GetVScriptOutput" to execute VScript code and get return data.
	- This is modified from an example script I published on 29-Jun-2019: https://forums.alliedmods.net/showthread.php?t=317145

	- Added new natives (L4D2 only): "L4D2_ForceNextStage", "L4D2_IsTankInPlay" and "L4D2_GetFurthestSurvivorFlow"
	- Added new natives (L4D1 & L4D2): "L4D_HasAnySurvivorLeftSafeArea" and "L4D_IsAnySurvivorInCheckpoint".
	- See the "NATIVES - Silvers" section inside the include file for details.
	- Thanks to "Nuki" for requesting.

	- Updated: Plugin, Include and GameData files.
	- Updated: Test plugin to reflect above changes.

1.8 (08-Mar-2020)
	- Added AutoExecConfig to generate a cvars config saved to "cfgs/sourcemod/left4dhooks.cfg".
	- Loads signatures in "OnPluginStart" except "g_pGameRules" which can only load in "OnMapStart".
	- Thanks to "Accelerator74" for requesting and testing.
	- Fixed some wrong return types in the include file.

	- Updated: Plugin and Include file.

1.7 (04-Mar-2020)
	- Added natives "L4D_GetNearestNavArea" and "L4D_FindRandomSpot" to get a random spawn position.
	- Fixed native "L4D2Direct_GetFlowDistance" sometimes causing server crashes.
	- Fixed natives "L4D_IsFirstMapInScenario" and "L4D_IsMissionFinalMap" sometimes returning incorrect values. Thanks to "Accelerator74".

	- Updated: Plugin, Include and GameData files.
	- Updated: Test plugin to reflect above changes.

1.6 (02-Mar-2020)
	- Fixed the animation hook throwing an "Exception reported: Client is not connected" error.

	Thanks to "Accelerator74" for reporting:
	- Fixed Addons Disabler "l4d2_addons_eclipse" not working without any plugins using the forward to detour.
	- Fixed "L4D2Direct_GetVSWitchFlowPercent" and "L4D2Direct_SetVSWitchFlowPercent" natives.

1.5 (29-Feb-2020)
	- Added Director Variables to be rechecked:
	- Some of these only work in the Finale, some may only work outside of the Finale. L4D2 is weird.
		"SmokerLimit", "BoomerLimit", "HunterLimit", "SpitterLimit", "JockeyLimit", "ChargerLimit", "TankLimit",
		"DominatorLimit", "WitchLimit" and "CommonLimit".

		Challenge Mode variables, if required:
		"cm_MaxSpecials", "cm_BaseSpecialLimit", "cm_SmokerLimit", "cm_BoomerLimit", "cm_HunterLimit", "cm_SpitterLimit",
		"cm_JockeyLimit", "cm_ChargerLimit", "cm_TankLimit", "cm_DominatorLimit", "cm_WitchLimit" and "cm_CommonLimit".

	- Added Target Filters (thanks to "hoanganh810972" for reporting as missing):
		Survivors: "@s", "@surv", "@survivors"
		Specials:  "@i", "@infe", "@infected"
		Tanks:     "@t", "@tank", "@tanks"

	- Fixed native "L4D_CreateRescuableSurvivors" from not working. Now spawns all dead survivors into rescuable rooms.
	- Removed "L4D_OnGetRandomPZSpawnPosition" forward due to spawning specials at 0,0,0 when modifying any value.

	- Updated: Plugin, Include and GameData files.
	- Updated: Test plugin to reflect above changes.

1.4 (28-Feb-2020)
	- AnimHooks no longer affect the same client index if the previous user disconnected and someone else connected.
	- Clarified AnimHooks details in the include file. All AnimHooks are removed on map change.
	- Fixed L4D1: "Invalid Handle" errors caused by Director Variables fix. Thanks to "TiTz" for reporting.

1.3 (27-Feb-2020)
	- Added forward "L4D_OnGetRandomPZSpawnPosition" to display when the game selects a position.
	- Added native "L4D_GetRandomPZSpawnPosition" to select a random position.
	- Thanks to "Accelerator74" for requesting.

	- Added forward "L4D2_OnSelectTankAttackPre" to handle "ACT_*" activity numbers.
	- Changed "L4D2_OnSelectTankAttack" to use "m_nSequence" numbers instead, just like the extension did.
	- Changed the "AnimHook" functions to use "ACT_*" activity numbers (pre-hook) and "m_nSequence" animation number (post-hook).
	- Existing plugins using "L4D2_OnSelectTankAttack" no longer need to change anything.
	- Existing plugins with the new "AnimHook" hook can now use normal model "m_nSequence" sequence numbers in the post hook.
	- Thanks to "Accelerator74" for reporting the fix.

	- Updated: Plugin, Include and GameData files.
	- Updated: Test plugin to demonstrate each change.

1.2 (27-Feb-2020)
	- Wildcarded the following signatures to be compatible with 3rd party plugin detours:
	- L4D2: "ChooseVictim", "GetSurvivorSet" and "ChangeFinaleStage".
	- Thanks to "xZk" for reporting.

1.1 (27-Feb-2020)
	- Added 26 new natives to L4D2 and 15 to L4D1 from "l4d2addresses.txt". Thanks to "Nuki" for suggesting.
	- See the "NATIVES - l4d2addresses.txt" section inside the include file for details.

	- Added 7 new natives to L4D2 and 5 to L4D1 from my plugins.
	- See the "NATIVES - Silvers" section inside the include file for details.

	- Fixed "L4D2_OnEndVersusModeRound" forwards triggering more than once per round. Thanks to "spumer" for reporting.
	- Fixed creating forwards and natives in the wrong place. Thanks to "Accelerator74" for reporting.
	- Fixed some signatures failing when other plugins detour them. Thanks to "hoanganh810972" for reporting.
	- Fixed cvar "l4d2_addons_eclipse" - values 0 and 1 now disable/enable addons unless otherwise handled.
	- Fixed not forwarding some Director Variables that were initialized too early. Thanks to "hoanganh81097" for reporting.
	- Thanks to "Spirit_12" for ideas with the Director Variables fix.
	- Removed unused actions from some forwards.

	- Updated: Plugin, Include and GameData files.

1.0 (24-Feb-2020)
	- Initial release.

========================================================================================
	To Do:

		Re-write dynamic detour enabler?
			- All working but looks ugly. Could be cleaner?
			- Optional extra-api.ext support

========================================================================================
	Thanks:

	This plugin was made using source code from the following plugins.
	If I have used your code and not credited you, please let me know.

*	Original Left4Downtown extension:		https://forums.alliedmods.net/showthread.php?t=91132
		"Downtown1" and "XBetaAlpha" - authors of the original Left4Downtown.
		"pRED*" for his TF2 tools code, I looked at it a lot . and for answering questions on IRC
		"Fyren" for being so awesome and inspiring me from his sdktools patch to do custom |this| calls.
		"ivailosp" for providing the Windows addresses that needed to be patched to get player slot unlocking to work.
		"dvander" for making sourcemod and teaching me about the mod r/m bytes.
		"DDRKhat" for letting me use his Linux server to test this
		"Frustian" for being a champ and poking around random Linux sigs so I could the one native I actually needed.
		"XBetaAlpha" for making this a team effort rather than one guy writing all the code.

*	Original Left4Downtown2 extension:		https://forums.alliedmods.net/showthread.php?t=134032
		"Downtown1" and "XBetaAlpha" - authors of the original Left4Downtown.
		"ProdigySim" - Confogl developer interested in expanding and updating Left4Downtown.
		"AtomicStryker" - Sourcemod plugin developer, and part of the original Left4Downtown team.
		"psychonic" - Resident Sourcemod insider, started Left4Downtown2.
		"asherkin" - Hosting the autobuild server.
		"CanadaRox", "vintik", "rochellecrab", and anyone else who has submitted code in any way.

*	Left 4 Downtown 2 Extension updates:	https://forums.alliedmods.net/showpost.php?p=1970730&postcount=397?p=1970730&postcount=397
		"Visor" for "l4d2_addons_eclipse" cvar and new forwards.

*	Left 4 Downtown 2 Extension updates
		"Attano" for various github commits.

*	Left 4 Downtown 2 Extension updates
		"Accelerator74" for various github commits.

*	"ProdigySim" and the "ConfoglTeam" for "L4D2Direct" plugin:
		https://forums.alliedmods.net/showthread.php?t=180028

*	"raziEiL" for "L4D_Direct Port" offsets and addresses:
		https://github.com/raziEiL/l4d_direct-port

*	"AtomicStryker" and whoever else contributed to "l4d2addresses.txt" gamedata file.

*	"Dragokas" for "String Tables Dumper" some code used to get melee weapon IDs.
		https://forums.alliedmods.net/showthread.php?t=322674

===================================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <dhooks>
#include <left4dhooks>

#if DEBUG
#include <profiler>
Handle g_vProf;
float g_fProf;
#endif



// Plugin
#define GAMEDATA_1							"left4dhooks.l4d1"
#define GAMEDATA_2							"left4dhooks.l4d2"
#define GAMEDATA_TEMP						"left4dhooks.temp"
#define NATIVE_UNSUPPORTED1					"\n==========\nThis Native is only supported in L4D1.\nPlease fix the code to avoid calling this native from L4D2.\n=========="
#define NATIVE_UNSUPPORTED2					"\n==========\nThis Native is only supported in L4D2.\nPlease fix the code to avoid calling this native from L4D1.\n=========="



// Tank animations
#define L4D2_ACT_HULK_THROW					761
#define L4D2_ACT_TANK_OVERHEAD_THROW		762
#define L4D2_ACT_HULK_ATTACK_LOW			763
#define L4D2_ACT_TERROR_ATTACK_MOVING		790
#define L4D2_SEQ_PUNCH_UPPERCUT				40
#define L4D2_SEQ_PUNCH_RIGHT_HOOK			43
#define L4D2_SEQ_PUNCH_LEFT_HOOK			45
#define L4D2_SEQ_PUNCH_POUND_GROUND1		46
#define L4D2_SEQ_PUNCH_POUND_GROUND2		47
#define L4D2_SEQ_THROW_UNDERCUT				48
#define L4D2_SEQ_THROW_1HAND_OVER			49
#define L4D2_SEQ_THROW_FROM_HIP				50
#define L4D2_SEQ_THROW_2HAND_OVER			51

#define L4D1_ACT_HULK_THROW					1254
#define L4D1_ACT_TANK_OVERHEAD_THROW		1255
#define L4D1_ACT_HULK_ATTACK_LOW			1256
#define L4D1_ACT_TERROR_ATTACK_MOVING		1282
#define L4D1_SEQ_PUNCH_UPPERCUT				38
#define L4D1_SEQ_PUNCH_RIGHT_HOOK			41
#define L4D1_SEQ_PUNCH_LEFT_HOOK			43
#define L4D1_SEQ_PUNCH_POUND_GROUND1		44
#define L4D1_SEQ_PUNCH_POUND_GROUND2		45
#define L4D1_SEQ_THROW_UNDERCUT				46
#define L4D1_SEQ_THROW_1HAND_OVER			47
#define L4D1_SEQ_THROW_FROM_HIP				48
#define L4D1_SEQ_THROW_2HAND_OVER			49



// Dissolver
#define SPRITE_GLOW							"sprites/blueglow1.vmt"



// Precache models for spawning
static const char g_sModels1[][] =
{
	"models/infected/witch.mdl",
	"models/infected/hulk.mdl",
	"models/infected/smoker.mdl",
	"models/infected/boomer.mdl",
	"models/infected/hunter.mdl"
};

static const char g_sModels2[][] =
{
	"models/infected/witch_bride.mdl",
	"models/infected/spitter.mdl",
	"models/infected/jockey.mdl",
	"models/infected/charger.mdl"
};



// Dynamic Detours:
#define MAX_FWD_LEN							64		// Maximum string length of forward and signature names, used for ArrayList.

// ToDo: When using extra-api.ext (or hopefully one day native SM forwards), g_aDetoursHooked will store the number of plugins using each forward
// so we can disable when the value is 0 and not have to check all plugins just to determine if still required.
ArrayList g_aDetoursHooked;					// Identifies if the detour hook is enabled or disabled
ArrayList g_aDetourHandles;					// Stores detour handles to enable/disable as required
ArrayList g_aGameDataSigs;					// Stores Signature names
ArrayList g_aForwardNames;					// Stores Forward names
ArrayList g_aUseLastIndex;					// Use last index
ArrayList g_aForwardIndex;					// Stores Detour indexes
ArrayList g_aForceDetours;					// Determines if a detour should be forced on without any forward using it
int g_iCurrentIndex;						// Index for each detour while created
bool g_bCreatedDetours;						// To determine first time creation of detours, or if enabling or disabling
float g_fLoadTime;							// When the plugin was loaded, to ignore when "AP_OnPluginUpdate" fires
Handle g_hThisPlugin;						// Ignore checking this plugin
GameData g_hGameData;						// GameData file - to speed up loading



// Animation Hook
int g_iAnimationDetourIndex;
ArrayList g_iAnimationHookedClients;
ArrayList g_hAnimationActivityList;
PrivateForward g_hAnimationCallbackPre;
PrivateForward g_hAnimationCallbackPost;



// Weapons
StringMap g_aWeaponPtrs;					// Stores weapon pointers to retrieve CCSWeaponInfo and CTerrorWeaponInfo data
StringMap g_aWeaponIDs;						// Store weapon IDs to get above pointers
StringMap g_aMeleeIDs;						// Store melee IDs
ArrayList g_aMeleePtrs;						// Stores melee pointers



// FORWARDS
GlobalForward g_hFWD_GameModeChange;
GlobalForward g_hFWD_ZombieManager_SpawnSpecial;
GlobalForward g_hFWD_ZombieManager_SpawnTank;
GlobalForward g_hFWD_ZombieManager_SpawnWitch;
GlobalForward g_hFWD_ZombieManager_SpawnWitchBride;
GlobalForward g_hFWD_CTerrorGameRules_ClearTeamScores;
GlobalForward g_hFWD_CTerrorGameRules_SetCampaignScores;
GlobalForward g_hFWD_CTerrorPlayer_RecalculateVersusScore;
GlobalForward g_hFWD_CDirector_OnFirstSurvivorLeftSafeArea;
GlobalForward g_hFWD_CDirector_GetScriptValueInt;
GlobalForward g_hFWD_CDirector_GetScriptValueFloat;
GlobalForward g_hFWD_CDirector_GetScriptValueString;
GlobalForward g_hFWD_CDirector_IsTeamFull;
GlobalForward g_hFWD_CTerrorPlayer_EnterGhostState;
GlobalForward g_hFWD_CTerrorPlayer_EnterGhostStatePre;
GlobalForward g_hFWD_CTankClaw_DoSwing_Pre;
GlobalForward g_hFWD_CTankClaw_DoSwing_Post;
GlobalForward g_hFWD_CTankClaw_GroundPound_Pre;
GlobalForward g_hFWD_CTankClaw_GroundPound_Post;
GlobalForward g_hFWD_CTankClaw_OnPlayerHit_Pre;
GlobalForward g_hFWD_CTankClaw_OnPlayerHit_Post;
GlobalForward g_hFWD_CTankRock_Detonate;
GlobalForward g_hFWD_CTankRock_OnRelease;
GlobalForward g_hFWD_CDirector_TryOfferingTankBot;
GlobalForward g_hFWD_CDirector_MobRushStart;
GlobalForward g_hFWD_ZombieManager_SpawnITMob;
GlobalForward g_hFWD_ZombieManager_SpawnMob;
GlobalForward g_hFWD_CTerrorPlayer_OnShovedBySurvivor;
GlobalForward g_hFWD_CTerrorPlayer_GetCrouchTopSpeed;
GlobalForward g_hFWD_CTerrorPlayer_GetRunTopSpeed;
GlobalForward g_hFWD_CTerrorPlayer_GetWalkTopSpeed;
GlobalForward g_hFWD_CTerrorGameRules_HasConfigurableDifficultySetting;
GlobalForward g_hFWD_CTerrorGameRules_GetSurvivorSet;
GlobalForward g_hFWD_CTerrorGameRules_FastGetSurvivorSet;
GlobalForward g_hFWD_GetMissionVSBossSpawning;
GlobalForward g_hFWD_CThrow_ActivateAbililty;
GlobalForward g_hFWD_StartMeleeSwing;
GlobalForward g_hFWD_GetDamageForVictim;
GlobalForward g_hFWD_CDirectorScriptedEventManager_SendInRescueVehicle;
GlobalForward g_hFWD_CDirectorScriptedEventManager_ChangeFinaleStage;
GlobalForward g_hFWD_CDirectorVersusMode_EndVersusModeRound_Pre;
GlobalForward g_hFWD_CDirectorVersusMode_EndVersusModeRound_Post;
GlobalForward g_hFWD_CBaseAnimating_SelectWeightedSequence_Pre;
GlobalForward g_hFWD_CBaseAnimating_SelectWeightedSequence_Post;
GlobalForward g_hFWD_CTerrorPlayer_OnLedgeGrabbed;
GlobalForward g_hFWD_CTerrorPlayer_OnRevived_Post;
GlobalForward g_hFWD_ZombieManager_ReplaceTank;
GlobalForward g_hFWD_SurvivorBot_UseHealingItems;
GlobalForward g_hFWD_SurvivorBot_FindScavengeItem_Post;
GlobalForward g_hFWD_BossZombiePlayerBot_ChooseVictim_Post;
GlobalForward g_hFWD_CTerrorPlayer_MaterializeFromGhost_Pre;
GlobalForward g_hFWD_CTerrorPlayer_MaterializeFromGhost_Post;
GlobalForward g_hFWD_CTerrorPlayer_OnVomitedUpon;
GlobalForward g_hFWD_CTerrorPlayer_OnHitByVomitJar;
GlobalForward g_hFWD_CBreakableProp_Break_Post;
GlobalForward g_hFWD_CGasCanEvent_Killed;	
GlobalForward g_hFWD_CGasCan_OnActionComplete;
GlobalForward g_hFWD_CTerrorPlayer_OnPouncedOnSurvivor;
GlobalForward g_hFWD_CTerrorPlayer_GrabVictimWithTongue;
GlobalForward g_hFWD_CTerrorPlayer_OnLeptOnSurvivor;
GlobalForward g_hFWD_CTerrorPlayer_OnStartCarryingVictim;
GlobalForward g_hFWD_CInsectSwarm_CanHarm;
GlobalForward g_hFWD_CPipeBombProjectile_Create_Pre;
GlobalForward g_hFWD_CPipeBombProjectile_Create_Post;
GlobalForward g_hFWD_CTerrorPlayer_Extinguish;
GlobalForward g_hFWD_CInferno_Spread;
GlobalForward g_hFWD_CTerrorWeapon_OnHit;
GlobalForward g_hFWD_CTerrorPlayer_OnStaggered;
GlobalForward g_hFWD_CTerrorPlayer_OnShovedByPounceLanding;
GlobalForward g_hFWD_CTerrorPlayer_Fling;
GlobalForward g_hFWD_CDeathFallCamera_Enable;
GlobalForward g_hFWD_CTerrorPlayer_OnFalling_Post;
GlobalForward g_hFWD_Tank_EnterStasis_Post;
GlobalForward g_hFWD_Tank_LeaveStasis_Post;
GlobalForward g_hFWD_AddonsDisabler;
// GlobalForward g_hFWD_GetRandomPZSpawnPos;
// GlobalForward g_hFWD_InfectedShoved;
// GlobalForward g_hFWD_OnWaterMove;



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
Handle g_hSDK_CBaseEntity_ApplyLocalAngularVelocityImpulse;
Handle g_hSDK_SurvivorBot_IsReachable;
Handle g_hSDK_CTerrorGameRules_HasPlayerControlledZombies;
Handle g_hSDK_CTerrorGameRules_GetSurvivorSet;
Handle g_hSDK_CPipeBombProjectile_Create;
Handle g_hSDK_CMolotovProjectile_Create;
Handle g_hSDK_VomitJarProjectile_Create;
Handle g_hSDK_CGrenadeLauncher_Projectile_Create;
Handle g_hSDK_CSpitterProjectile_Create;
Handle g_hSDK_CTerrorPlayer_OnAdrenalineUsed;
Handle g_hSDK_CTerrorPlayer_RoundRespawn;
Handle g_hSDK_SurvivorBot_SetHumanSpectator;
Handle g_hSDK_CTerrorPlayer_TakeOverBot;
Handle g_hSDK_CTerrorPlayer_CanBecomeGhost;
Handle g_hSDK_CDirector_AreWanderersAllowed;
Handle g_hSDK_CDirector_IsFinaleEscapeInProgress;
Handle g_hSDK_CDirector_ForceNextStage;
Handle g_hSDK_CDirector_IsTankInPlay;
Handle g_hSDK_CDirector_GetFurthestSurvivorFlow;
Handle g_hSDK_CDirector_GetScriptValueInt;
// Handle g_hSDK_CDirector_GetScriptValueFloat;
// Handle g_hSDK_CDirector_GetScriptValueString;
Handle g_hSDK_ZombieManager_GetRandomPZSpawnPosition;
Handle g_hSDK_CNavMesh_GetNearestNavArea;
Handle g_hSDK_TerrorNavArea_FindRandomSpot;
Handle g_hSDK_CDirector_HasAnySurvivorLeftSafeArea;
Handle g_hSDK_CDirector_IsAnySurvivorInExitCheckpoint;
Handle g_hSDK_CDirector_IsAnySurvivorInStartArea;
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
Handle g_hSDK_CBaseGrenade_Detonate;
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
Handle g_hSDK_CDirector_CreateRescuableSurvivors;
Handle g_hSDK_CTerrorPlayer_OnRevived;
Handle g_hSDK_CTerrorGameRules_GetVersusCompletion;
Handle g_hSDK_CDirectorTacticalServices_GetHighestFlowSurvivor;
Handle g_hSDK_Infected_GetFlowDistance;
Handle g_hSDK_CTerrorPlayer_TakeOverZombieBot;
Handle g_hSDK_CTerrorPlayer_ReplaceWithBot;
Handle g_hSDK_CTerrorPlayer_CullZombie;
Handle g_hSDK_CTerrorPlayer_SetClass;
Handle g_hSDK_CBaseAbility_CreateForPlayer;
Handle g_hSDK_CTerrorPlayer_MaterializeFromGhost;
Handle g_hSDK_CTerrorPlayer_BecomeGhost;
Handle g_hSDK_CCSPlayer_State_Transition;
Handle g_hSDK_CDirector_SwapTeams;
Handle g_hSDK_CDirector_AreTeamsFlipped;
Handle g_hSDK_CDirector_StartRematchVote;
Handle g_hSDK_CDirector_FullRestart;
Handle g_hSDK_CDirectorVersusMode_HideScoreboardNonVirtual;
Handle g_hSDK_CDirectorScavengeMode_HideScoreboardNonVirtual;
Handle g_hSDK_CDirector_HideScoreboard;
Handle g_hSDK_CDirector_RegisterForbiddenTarget;
Handle g_hSDK_CDirector_UnregisterForbiddenTarget;



// Offsets - Addons Eclipse
int g_iOff_AddonEclipse1;
int g_iOff_AddonEclipse2;
int g_iOff_VanillaModeOffset;
Address g_pVanillaModeAddress;

// Various offsets
int g_iOff_VersusStartTimer;
int g_iOff_m_rescueCheckTimer;
int g_iOff_SpawnTimer;
int g_iOff_MobSpawnTimer;
int g_iOff_VersusMaxCompletionScore;
int g_iOff_OnBeginRoundSetupTime;
int g_iOff_m_iTankCount;
int g_iOff_m_iWitchCount;
int g_iOff_m_iCampaignScores;
int g_iOff_m_fTankSpawnFlowPercent;
int g_iOff_m_fWitchSpawnFlowPercent;
int g_iOff_m_iTankPassedCount;
int g_iOff_m_bTankThisRound;
int g_iOff_m_bWitchThisRound;
int g_iOff_OvertimeGraceTimer;
int g_iOff_InvulnerabilityTimer;
int g_iOff_m_iTankTickets;
int g_iOff_m_iSurvivorHealthBonus;
int g_iOff_m_bFirstSurvivorLeftStartArea;
int g_iOff_m_iShovePenalty;
int g_iOff_m_fNextShoveTime;
int g_iOff_m_preIncapacitatedHealth;
int g_iOff_m_preIncapacitatedHealthBuffer;
int g_iOff_m_maxFlames;
int g_iOff_m_flow;
int g_iOff_m_PendingMobCount;
int g_iOff_m_fMapMaxFlowDistance;
int g_iOff_m_chapter;
// int g_iOff_m_iClrRender; // NULL PTR - METHOD (kept for demonstration)
// int ClearTeamScore_A;
// int ClearTeamScore_B;
// Address TeamScoresAddress;

// l4d2timers.inc
int L4D2CountdownTimer_Offsets[9];
int L4D2IntervalTimer_Offsets[6];

// l4d2weapons.inc
int L4D2IntWeapon_Offsets[3];
int L4D2FloatWeapon_Offsets[17];
int L4D2BoolMeleeWeapon_Offsets[1];
int L4D2IntMeleeWeapon_Offsets[2];
int L4D2FloatMeleeWeapon_Offsets[3];



// Pointers
int g_pScriptedEventManager;
int g_pVersusMode;
int g_pScavengeMode;
Address g_pServer;
Address g_pDirector;
Address g_pGameRules;
Address g_pNavMesh;
Address g_pZombieManager;
Address g_pMeleeWeaponInfoStore;
Address g_pWeaponInfoDatabase;



// Other
int g_iCurrentMode;
int g_iMaxChapters;
int g_iClassTank;
bool g_bLinuxOS;
bool g_bLeft4Dead2;
bool g_bMapStarted;
bool g_bRoundEnded;
bool g_bCheckpoint[MAXPLAYERS+1];
ConVar g_hCvar_VScriptBuffer;
ConVar g_hCvar_AddonsEclipse;
ConVar g_hCvar_RescueDeadTime;
ConVar g_hCvar_PillsDecay;
ConVar g_hCvar_PillsHealth;
ConVar g_hCvar_MPGameMode;

#if DEBUG
bool g_bLateLoad;
#endif



// ====================================================================================================
//										PLUGIN INFO / START
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Left 4 DHooks Direct",
	author = "SilverShot",
	description = "Left 4 Downtown and L4D Direct conversion and merger.",
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

	#if DEBUG
	g_bLateLoad = late;
	#endif

	g_hThisPlugin = myself;
	RegPluginLibrary("left4dhooks");



	// ====================================================================================================
	//									EXTENSION BLOCK
	// ====================================================================================================
	if( GetFeatureStatus(FeatureType_Native, "L4D_RestartScenarioFromVote") != FeatureStatus_Unknown )
	{
		strcopy(error, err_max, "\n==========\nThis plugin replaces Left4Downtown. Delete the extension to run.\n==========");
		return APLRes_SilentFailure;
	}



	// ====================================================================================================
	//									FORWARDS
	// ====================================================================================================
	// FORWARDS
	// List should match the CreateDetour list of forwards.
	g_hFWD_GameModeChange											= new GlobalForward("L4D_OnGameModeChange",						ET_Event, Param_Cell);
	g_hFWD_ZombieManager_SpawnSpecial								= new GlobalForward("L4D_OnSpawnSpecial",						ET_Event, Param_CellByRef, Param_Array, Param_Array);
	g_hFWD_ZombieManager_SpawnTank									= new GlobalForward("L4D_OnSpawnTank",							ET_Event, Param_Array, Param_Array);
	g_hFWD_ZombieManager_SpawnWitch									= new GlobalForward("L4D_OnSpawnWitch",							ET_Event, Param_Array, Param_Array);
	g_hFWD_CDirector_MobRushStart									= new GlobalForward("L4D_OnMobRushStart",						ET_Event);
	g_hFWD_ZombieManager_SpawnITMob									= new GlobalForward("L4D_OnSpawnITMob",							ET_Event, Param_CellByRef);
	g_hFWD_ZombieManager_SpawnMob									= new GlobalForward("L4D_OnSpawnMob",							ET_Event, Param_CellByRef);
	g_hFWD_CTerrorPlayer_EnterGhostState							= new GlobalForward("L4D_OnEnterGhostState",					ET_Event, Param_Cell);
	g_hFWD_CTerrorPlayer_EnterGhostStatePre							= new GlobalForward("L4D_OnEnterGhostStatePre",					ET_Event, Param_Cell);
	g_hFWD_CDirector_IsTeamFull										= new GlobalForward("L4D_OnIsTeamFull",							ET_Event, Param_Cell, Param_CellByRef);
	g_hFWD_CTerrorGameRules_ClearTeamScores							= new GlobalForward("L4D_OnClearTeamScores",					ET_Event, Param_Cell);
	g_hFWD_CTerrorGameRules_SetCampaignScores						= new GlobalForward("L4D_OnSetCampaignScores",					ET_Event, Param_CellByRef, Param_CellByRef);
	if( !g_bLeft4Dead2 )
		g_hFWD_CTerrorPlayer_RecalculateVersusScore					= new GlobalForward("L4D_OnRecalculateVersusScore",				ET_Event, Param_Cell);
	g_hFWD_CDirector_OnFirstSurvivorLeftSafeArea					= new GlobalForward("L4D_OnFirstSurvivorLeftSafeArea",			ET_Event, Param_Cell);
	g_hFWD_CTerrorPlayer_GetCrouchTopSpeed							= new GlobalForward("L4D_OnGetCrouchTopSpeed",					ET_Event, Param_Cell, Param_FloatByRef);
	g_hFWD_CTerrorPlayer_GetRunTopSpeed								= new GlobalForward("L4D_OnGetRunTopSpeed",						ET_Event, Param_Cell, Param_FloatByRef);
	g_hFWD_CTerrorPlayer_GetWalkTopSpeed							= new GlobalForward("L4D_OnGetWalkTopSpeed",					ET_Event, Param_Cell, Param_FloatByRef);
	g_hFWD_GetMissionVSBossSpawning									= new GlobalForward("L4D_OnGetMissionVSBossSpawning",			ET_Event, Param_FloatByRef, Param_FloatByRef, Param_FloatByRef, Param_FloatByRef);
	g_hFWD_ZombieManager_ReplaceTank								= new GlobalForward("L4D_OnReplaceTank",						ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CTankClaw_DoSwing_Pre									= new GlobalForward("L4D_TankClaw_DoSwing_Pre",					ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CTankClaw_DoSwing_Post									= new GlobalForward("L4D_TankClaw_DoSwing_Post",				ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CTankClaw_GroundPound_Pre								= new GlobalForward("L4D_TankClaw_GroundPound_Pre",				ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CTankClaw_GroundPound_Post								= new GlobalForward("L4D_TankClaw_GroundPound_Post",			ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CTankClaw_OnPlayerHit_Pre								= new GlobalForward("L4D_TankClaw_OnPlayerHit_Pre",				ET_Event, Param_Cell, Param_Cell, Param_Cell);
	g_hFWD_CTankClaw_OnPlayerHit_Post								= new GlobalForward("L4D_TankClaw_OnPlayerHit_Post",			ET_Event, Param_Cell, Param_Cell, Param_Cell);
	g_hFWD_CTankRock_Detonate										= new GlobalForward("L4D_TankRock_OnDetonate",					ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CTankRock_OnRelease										= new GlobalForward("L4D_TankRock_OnRelease",					ET_Event, Param_Cell, Param_Cell, Param_Array, Param_Array, Param_Array, Param_Array);
	g_hFWD_CDirector_TryOfferingTankBot								= new GlobalForward("L4D_OnTryOfferingTankBot",					ET_Event, Param_Cell, Param_CellByRef);
	g_hFWD_CThrow_ActivateAbililty									= new GlobalForward("L4D_OnCThrowActivate",						ET_Event, Param_Cell);
	g_hFWD_CBaseAnimating_SelectWeightedSequence_Pre				= new GlobalForward("L4D2_OnSelectTankAttackPre",				ET_Event, Param_Cell, Param_CellByRef);
	g_hFWD_CBaseAnimating_SelectWeightedSequence_Post				= new GlobalForward("L4D2_OnSelectTankAttack",					ET_Event, Param_Cell, Param_CellByRef);
	g_hFWD_CDirectorScriptedEventManager_SendInRescueVehicle		= new GlobalForward("L4D2_OnSendInRescueVehicle",				ET_Event);
	g_hFWD_CDirectorVersusMode_EndVersusModeRound_Pre				= new GlobalForward("L4D2_OnEndVersusModeRound",				ET_Event, Param_Cell);
	g_hFWD_CDirectorVersusMode_EndVersusModeRound_Post				= new GlobalForward("L4D2_OnEndVersusModeRound_Post",			ET_Event);
	g_hFWD_CTerrorPlayer_OnLedgeGrabbed								= new GlobalForward("L4D_OnLedgeGrabbed",						ET_Event, Param_Cell);
	g_hFWD_CTerrorPlayer_OnRevived_Post								= new GlobalForward("L4D2_OnRevived",							ET_Event, Param_Cell);
	g_hFWD_CTerrorPlayer_OnStaggered								= new GlobalForward("L4D2_OnStagger",							ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CTerrorPlayer_OnShovedBySurvivor							= new GlobalForward("L4D_OnShovedBySurvivor",					ET_Event, Param_Cell, Param_Cell, Param_Array);
	g_hFWD_CTerrorWeapon_OnHit										= new GlobalForward("L4D2_OnEntityShoved",						ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_Array, Param_Cell);
	g_hFWD_CTerrorPlayer_OnShovedByPounceLanding					= new GlobalForward("L4D2_OnPounceOrLeapStumble",				ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CTerrorPlayer_Fling										= new GlobalForward("L4D2_OnPlayerFling",						ET_Event, Param_Cell, Param_Cell, Param_Array);
	g_hFWD_CDeathFallCamera_Enable									= new GlobalForward("L4D_OnFatalFalling",						ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CTerrorPlayer_OnFalling_Post								= new GlobalForward("L4D_OnFalling",							ET_Event, Param_Cell);
	g_hFWD_Tank_EnterStasis_Post									= new GlobalForward("L4D_OnEnterStasis",						ET_Event, Param_Cell);
	g_hFWD_Tank_LeaveStasis_Post									= new GlobalForward("L4D_OnLeaveStasis",						ET_Event, Param_Cell);
	g_hFWD_CInferno_Spread											= new GlobalForward("L4D2_OnSpitSpread",						ET_Event, Param_Cell, Param_Cell, Param_FloatByRef, Param_FloatByRef, Param_FloatByRef);
	g_hFWD_SurvivorBot_UseHealingItems								= new GlobalForward("L4D2_OnUseHealingItems",					ET_Event, Param_Cell);
	g_hFWD_SurvivorBot_FindScavengeItem_Post						= new GlobalForward("L4D2_OnFindScavengeItem",					ET_Event, Param_Cell, Param_CellByRef);
	g_hFWD_BossZombiePlayerBot_ChooseVictim_Post					= new GlobalForward("L4D2_OnChooseVictim",						ET_Event, Param_Cell, Param_CellByRef);
	g_hFWD_CTerrorPlayer_MaterializeFromGhost_Pre					= new GlobalForward("L4D_OnMaterializeFromGhostPre",			ET_Event, Param_Cell);
	g_hFWD_CTerrorPlayer_MaterializeFromGhost_Post					= new GlobalForward("L4D_OnMaterializeFromGhost",				ET_Event, Param_Cell);
	g_hFWD_CTerrorPlayer_OnVomitedUpon								= new GlobalForward("L4D_OnVomitedUpon",						ET_Event, Param_Cell, Param_CellByRef, Param_CellByRef);
	g_hFWD_CPipeBombProjectile_Create_Pre							= new GlobalForward("L4D_PipeBombProjectile_Pre",				ET_Event, Param_Cell, Param_Array, Param_Array, Param_Array, Param_Array);
	g_hFWD_CPipeBombProjectile_Create_Post							= new GlobalForward("L4D_PipeBombProjectile_Post",				ET_Event, Param_Cell, Param_Cell, Param_Array, Param_Array, Param_Array, Param_Array);
	g_hFWD_CTerrorPlayer_Extinguish									= new GlobalForward("L4D_PlayerExtinguish",						ET_Event, Param_Cell);
	g_hFWD_CTerrorPlayer_OnPouncedOnSurvivor						= new GlobalForward("L4D_OnPouncedOnSurvivor",					ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CTerrorPlayer_GrabVictimWithTongue						= new GlobalForward("L4D_OnGrabWithTongue",						ET_Event, Param_Cell, Param_Cell);
	g_hFWD_CBreakableProp_Break_Post								= new GlobalForward("L4D_CBreakableProp_Break",					ET_Event, Param_Cell, Param_Cell);
	// g_hFWD_GetRandomPZSpawnPos										= new GlobalForward("L4D_OnGetRandomPZSpawnPosition",			ET_Event, Param_CellByRef, Param_CellByRef, Param_CellByRef, Param_Array);
	// g_hFWD_InfectedShoved											= new GlobalForward("L4D_OnInfectedShoved",						ET_Event, Param_Cell, Param_Cell);
	// g_hFWD_OnWaterMove												= new GlobalForward("L4D2_OnWaterMove",							ET_Event, Param_Cell);

	if( g_bLeft4Dead2 )
	{
		g_hFWD_CTerrorPlayer_OnLeptOnSurvivor						= new GlobalForward("L4D2_OnJockeyRide",						ET_Event, Param_Cell, Param_Cell);
		g_hFWD_CTerrorPlayer_OnStartCarryingVictim					= new GlobalForward("L4D2_OnStartCarryingVictim",				ET_Event, Param_Cell, Param_Cell);
		g_hFWD_CGasCanEvent_Killed									= new GlobalForward("L4D2_CGasCan_EventKilled",					ET_Event, Param_Cell, Param_Cell, Param_Cell);
		g_hFWD_CGasCan_OnActionComplete								= new GlobalForward("L4D2_CGasCan_ActionComplete",				ET_Event, Param_Cell, Param_Cell, Param_Cell);
		g_hFWD_CInsectSwarm_CanHarm									= new GlobalForward("L4D2_CInsectSwarm_CanHarm",				ET_Event, Param_Cell, Param_Cell, Param_Cell);
		g_hFWD_CTerrorPlayer_OnHitByVomitJar						= new GlobalForward("L4D2_OnHitByVomitJar",						ET_Event, Param_Cell, Param_CellByRef);
		g_hFWD_ZombieManager_SpawnWitchBride						= new GlobalForward("L4D2_OnSpawnWitchBride",					ET_Event, Param_Array, Param_Array);
		g_hFWD_CDirector_GetScriptValueInt							= new GlobalForward("L4D_OnGetScriptValueInt",					ET_Event, Param_String, Param_CellByRef);
		g_hFWD_CDirector_GetScriptValueFloat						= new GlobalForward("L4D_OnGetScriptValueFloat",				ET_Event, Param_String, Param_FloatByRef);
		g_hFWD_CDirector_GetScriptValueString						= new GlobalForward("L4D_OnGetScriptValueString",				ET_Event, Param_String, Param_String, Param_String);
		g_hFWD_CTerrorGameRules_HasConfigurableDifficultySetting	= new GlobalForward("L4D_OnHasConfigurableDifficulty",			ET_Event, Param_CellByRef);
		g_hFWD_CTerrorGameRules_GetSurvivorSet						= new GlobalForward("L4D_OnGetSurvivorSet",						ET_Event, Param_CellByRef);
		g_hFWD_CTerrorGameRules_FastGetSurvivorSet					= new GlobalForward("L4D_OnFastGetSurvivorSet",					ET_Event, Param_CellByRef);
		g_hFWD_StartMeleeSwing										= new GlobalForward("L4D_OnStartMeleeSwing",					ET_Event, Param_Cell, Param_Cell);
		g_hFWD_GetDamageForVictim									= new GlobalForward("L4D2_MeleeGetDamageForVictim",				ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_FloatByRef);
		g_hFWD_CDirectorScriptedEventManager_ChangeFinaleStage		= new GlobalForward("L4D2_OnChangeFinaleStage",					ET_Event, Param_CellByRef, Param_String);
		g_hFWD_AddonsDisabler										= new GlobalForward("L4D2_OnClientDisableAddons",				ET_Event, Param_String);
	}



	// ====================================================================================================
	//									NATIVES
	// L4D1 = 24 [left4downtown] + 47 [l4d_direct] + 15 [l4d2addresses] + 39 [silvers - mine!] + 4 [anim] = 121
	// L4D2 = 53 [left4downtown] + 61 [l4d_direct] + 26 [l4d2addresses] + 74 [silvers - mine!] + 4 [anim] = 207
	// ====================================================================================================
	// ANIMATION HOOK
	CreateNative("AnimHookEnable",		 							Native_AnimHookEnable);
	CreateNative("AnimHookDisable",		 							Native_AnimHookDisable);
	CreateNative("AnimGetActivity",		 							Native_AnimGetActivity);
	CreateNative("AnimGetFromActivity",		 						Native_AnimGetFromActivity);



	// =========================
	// Silvers Natives
	// =========================
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
	CreateNative("L4D_PlayMusic",		 							Native_PlayMusic);
	CreateNative("L4D_StopMusic",		 							Native_StopMusic);
	CreateNative("L4D_Deafen",		 								Native_CTerrorPlayer_Deafen);
	CreateNative("L4D_Dissolve",		 							Native_CEntityDissolve_Create);
	CreateNative("L4D_OnITExpired",		 							Native_CTerrorPlayer_OnITExpired);
	CreateNative("L4D_AngularVelocity",		 						Native_CBaseEntity_ApplyLocalAngularVelocityImpulse);
	CreateNative("L4D_GetRandomPZSpawnPosition",		 			Native_ZombieManager_GetRandomPZSpawnPosition);
	CreateNative("L4D_FindRandomSpot",		 						Native_TerrorNavArea_FindRandomSpot);
	CreateNative("L4D_GetNearestNavArea",		 					Native_CNavMesh_GetNearestNavArea);
	CreateNative("L4D_GetLastKnownArea",		 					Native_CTerrorPlayer_GetLastKnownArea);
	CreateNative("L4D_HasAnySurvivorLeftSafeArea",		 			Native_CDirector_HasAnySurvivorLeftSafeArea);
	CreateNative("L4D_IsAnySurvivorInStartArea",		 			Native_CDirector_IsAnySurvivorInStartArea);
	CreateNative("L4D_IsAnySurvivorInCheckpoint",		 			Native_CDirector_IsAnySurvivorInExitCheckpoint);
	CreateNative("L4D_IsInFirstCheckpoint",		 					Native_IsInFirstCheckpoint);
	CreateNative("L4D_IsInLastCheckpoint",		 					Native_IsInLastCheckpoint);
	CreateNative("L4D_HasPlayerControlledZombies",		 			Native_CTerrorGameRules_HasPlayerControlledZombies);
	CreateNative("L4D_DetonateProjectile",		 					Native_CBaseGrenade_Detonate);
	CreateNative("L4D_TankRockPrj",		 							Native_CTankRock_Create);
	CreateNative("L4D_PipeBombPrj",		 							Native_CPipeBombProjectile_Create);
	CreateNative("L4D_MolotovPrj",		 							Native_CMolotovProjectile_Create);
	CreateNative("L4D2_VomitJarPrj",		 						Native_VomitJarProjectile_Create);
	CreateNative("L4D2_GrenadeLauncherPrj",		 					Native_CGrenadeLauncher_Projectile_Create);
	CreateNative("L4D_SetHumanSpec",								Native_SurvivorBot_SetHumanSpectator);
	CreateNative("L4D_TakeOverBot",									Native_CTerrorPlayer_TakeOverBot);
	CreateNative("L4D_CanBecomeGhost",								Native_CTerrorPlayer_CanBecomeGhost);
	CreateNative("L4D_IsFinaleEscapeInProgress",					Native_CDirector_IsFinaleEscapeInProgress);

	// L4D2 only:
	CreateNative("L4D2_AreWanderersAllowed",						Native_CDirector_AreWanderersAllowed);
	CreateNative("L4D2_ExecVScriptCode",							Native_ExecVScriptCode);
	CreateNative("L4D2_GetVScriptOutput",							Native_GetVScriptOutput);
	CreateNative("L4D2_SpitterPrj",		 							Native_CSpitterProjectile_Create);
	CreateNative("L4D2_UseAdrenaline",		 						Native_CTerrorPlayer_OnAdrenalineUsed);
	CreateNative("L4D2_GetCurrentFinaleStage",		 				Native_GetCurrentFinaleStage);
	CreateNative("L4D2_ForceNextStage",		 						Native_CDirector_ForceNextStage);
	CreateNative("L4D2_IsTankInPlay",		 						Native_CDirector_IsTankInPlay);
	CreateNative("L4D2_IsReachable",		 						Native_SurvivorBot_IsReachable);
	CreateNative("L4D2_GetFurthestSurvivorFlow",		 			Native_CDirector_GetFurthestSurvivorFlow);
	CreateNative("L4D2_GetScriptValueInt",							Native_CDirector_GetScriptValueInt);
	CreateNative("L4D2_NavAreaTravelDistance",		 				Native_NavAreaTravelDistance);

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
	// CreateNative("L4D2_GetScriptValueFloat",						Native_CDirector_GetScriptValueFloat); // Only returns default value provided.
	// CreateNative("L4D2_GetScriptValueString",					Native_CDirector_GetScriptValueString); // Not implemented, probably broken too, request if really required.



	// =========================
	// left4downtown.inc
	// =========================
	// CreateNative("L4D_GetCampaignScores",						Native_GetCampaignScores);
	// CreateNative("L4D_LobbyIsReserved",							Native_LobbyIsReserved);
	CreateNative("L4D_LobbyUnreserve",				 				Native_CBaseServer_SetReservationCookie);
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
	CreateNative("L4D_GetMaxChapters",								Native_CTerrorGameRules_GetNumChaptersForMissionAndMode);
	CreateNative("L4D_GetVersusMaxCompletionScore",					Native_GetVersusMaxCompletionScore);
	CreateNative("L4D_SetVersusMaxCompletionScore",					Native_SetVersusMaxCompletionScore);

	// L4D2 only:
	CreateNative("L4D_ScavengeBeginRoundSetupTime", 				Native_ScavengeBeginRoundSetupTime);
	CreateNative("L4D_ResetMobTimer",								Native_CDirector_ResetMobTimer);
	CreateNative("L4D_GetPlayerSpawnTime",							Native_GetPlayerSpawnTime);
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
	CreateNative("L4D_RespawnPlayer",								Native_CTerrorPlayer_RespawnPlayer);
	CreateNative("L4D_CreateRescuableSurvivors",					Native_CDirector_CreateRescuableSurvivors);
	CreateNative("L4D_ReviveSurvivor",								Native_CTerrorPlayer_OnRevived);
	CreateNative("L4D_GetHighestFlowSurvivor",						Native_CDirectorTacticalServices_GetHighestFlowSurvivor);
	CreateNative("L4D_GetInfectedFlowDistance",						Native_Infected_GetInfectedFlowDistance);
	CreateNative("L4D_TakeOverZombieBot",							Native_CTerrorPlayer_TakeOverZombieBot);
	CreateNative("L4D_ReplaceWithBot",								Native_CTerrorPlayer_ReplaceWithBot);
	CreateNative("L4D_CullZombie",									Native_CTerrorPlayer_CullZombie);
	CreateNative("L4D_SetClass",									Native_CTerrorPlayer_SetClass);
	CreateNative("L4D_MaterializeFromGhost",						Native_CTerrorPlayer_MaterializeFromGhost);
	CreateNative("L4D_BecomeGhost",									Native_CTerrorPlayer_BecomeGhost);
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
	CreateNative("L4D2_StartRematchVote",							Native_CDirector_StartRematchVote);
	CreateNative("L4D2_FullRestart",								Native_CDirector_FullRestart);
	CreateNative("L4D2_HideVersusScoreboard",						Native_CDirectorVersusMode_HideScoreboardNonVirtual);
	CreateNative("L4D2_HideScavengeScoreboard",						Native_CDirectorScavengeMode_HideScoreboardNonVirtual);
	CreateNative("L4D2_HideScoreboard",								Native_CDirector_HideScoreboard);

	return APLRes_Success;
}

public void OnPluginStart()
{
	// ====================================================================================================
	//									SETUP
	// ====================================================================================================
	g_iClassTank = g_bLeft4Dead2 ? 8 : 5;
	g_fLoadTime = GetEngineTime();



	// Animation Hook
	g_hAnimationActivityList = new ArrayList(ByteCountToCells(64));
	ParseActivityConfig();

	g_iAnimationHookedClients = new ArrayList();
	g_hAnimationCallbackPre = new PrivateForward(ET_Event, Param_Cell, Param_CellByRef);
	g_hAnimationCallbackPost = new PrivateForward(ET_Event, Param_Cell, Param_CellByRef);


	// NULL PTR - METHOD (kept for demonstration)
	// Null pointer - by Dragokas
	/*
	g_iOff_m_iClrRender = FindSendPropInfo("CBaseEntity", "m_clrRender");
	if( g_iOff_m_iClrRender == -1 )
	{
		SetFailState("Error: m_clrRender not found.");
	}
	*/



	// Weapon IDs
	g_aWeaponPtrs = new StringMap();
	g_aWeaponIDs = new StringMap();

	if( !g_bLeft4Dead2 )
	{
		g_aWeaponIDs.SetValue("weapon_none",						0);
		g_aWeaponIDs.SetValue("weapon_pistol",						1);
		g_aWeaponIDs.SetValue("weapon_smg",							2);
		g_aWeaponIDs.SetValue("weapon_pumpshotgun",					3);
		g_aWeaponIDs.SetValue("weapon_autoshotgun",					4);
		g_aWeaponIDs.SetValue("weapon_rifle",						5);
		g_aWeaponIDs.SetValue("weapon_hunting_rifle",				6);
		g_aWeaponIDs.SetValue("weapon_first_aid_kit",				8);
		g_aWeaponIDs.SetValue("weapon_molotov",						9);
		g_aWeaponIDs.SetValue("weapon_pipe_bomb",					10);
		g_aWeaponIDs.SetValue("weapon_pain_pills",					12);
		g_aWeaponIDs.SetValue("weapon_gascan",						14);
		g_aWeaponIDs.SetValue("weapon_propanetank",					15);
		g_aWeaponIDs.SetValue("weapon_oxygentank",					16);
		g_aWeaponIDs.SetValue("weapon_tank_claw",					17);
		g_aWeaponIDs.SetValue("weapon_hunter_claw",					18);
		g_aWeaponIDs.SetValue("weapon_boomer_claw",					19);
		g_aWeaponIDs.SetValue("weapon_smoker_claw",					20);
		g_aWeaponIDs.SetValue("weapon_ammo_spawn",					29);
	} else {
		g_aWeaponIDs.SetValue("weapon_none",						0);
		g_aWeaponIDs.SetValue("weapon_pistol",						1);
		g_aWeaponIDs.SetValue("weapon_smg",							2);
		g_aWeaponIDs.SetValue("weapon_pumpshotgun",					3);
		g_aWeaponIDs.SetValue("weapon_autoshotgun",					4);
		g_aWeaponIDs.SetValue("weapon_rifle",						5);
		g_aWeaponIDs.SetValue("weapon_hunting_rifle",				6);
		g_aWeaponIDs.SetValue("weapon_smg_silenced",				7);
		g_aWeaponIDs.SetValue("weapon_shotgun_chrome",				8);
		g_aWeaponIDs.SetValue("weapon_rifle_desert",				9);
		g_aWeaponIDs.SetValue("weapon_sniper_military",				10);
		g_aWeaponIDs.SetValue("weapon_shotgun_spas",				11);
		g_aWeaponIDs.SetValue("weapon_first_aid_kit",				12);
		g_aWeaponIDs.SetValue("weapon_molotov",						13);
		g_aWeaponIDs.SetValue("weapon_pipe_bomb",					14);
		g_aWeaponIDs.SetValue("weapon_pain_pills",					15);
		g_aWeaponIDs.SetValue("weapon_gascan",						16);
		g_aWeaponIDs.SetValue("weapon_propanetank",					17);
		g_aWeaponIDs.SetValue("weapon_oxygentank",					18);
		g_aWeaponIDs.SetValue("weapon_melee",						19);
		g_aWeaponIDs.SetValue("weapon_chainsaw",					20);
		g_aWeaponIDs.SetValue("weapon_grenade_launcher",			21);
		// g_aWeaponIDs.SetValue("weapon_ammo_pack",				22); // Unavailable
		g_aWeaponIDs.SetValue("weapon_adrenaline",					23);
		g_aWeaponIDs.SetValue("weapon_defibrillator",				24);
		g_aWeaponIDs.SetValue("weapon_vomitjar",					25);
		g_aWeaponIDs.SetValue("weapon_rifle_ak47",					26);
		g_aWeaponIDs.SetValue("weapon_gnome",						27);
		g_aWeaponIDs.SetValue("weapon_cola_bottles",				28);
		g_aWeaponIDs.SetValue("weapon_fireworkcrate",				29);
		g_aWeaponIDs.SetValue("weapon_upgradepack_incendiary",		30);
		g_aWeaponIDs.SetValue("weapon_upgradepack_explosive",		31);
		g_aWeaponIDs.SetValue("weapon_pistol_magnum",				32);
		g_aWeaponIDs.SetValue("weapon_smg_mp5",						33);
		g_aWeaponIDs.SetValue("weapon_rifle_sg552",					34);
		g_aWeaponIDs.SetValue("weapon_sniper_awp",					35);
		g_aWeaponIDs.SetValue("weapon_sniper_scout",				36);
		g_aWeaponIDs.SetValue("weapon_rifle_m60",					37);
		g_aWeaponIDs.SetValue("weapon_tank_claw",					38);
		g_aWeaponIDs.SetValue("weapon_hunter_claw",					39);
		g_aWeaponIDs.SetValue("weapon_charger_claw",				40);
		g_aWeaponIDs.SetValue("weapon_boomer_claw",					41);
		g_aWeaponIDs.SetValue("weapon_smoker_claw",					42);
		g_aWeaponIDs.SetValue("weapon_spitter_claw",				43);
		g_aWeaponIDs.SetValue("weapon_jockey_claw",					44);
		g_aWeaponIDs.SetValue("weapon_ammo_spawn",					54);

		g_aMeleePtrs = new ArrayList(2);
		g_aMeleeIDs = new StringMap();
		g_aMeleeIDs.SetValue("fireaxe",								0);
		g_aMeleeIDs.SetValue("frying_pan",							1);
		g_aMeleeIDs.SetValue("machete",								2);
		g_aMeleeIDs.SetValue("baseball_bat",						3);
		g_aMeleeIDs.SetValue("crowbar",								4);
		g_aMeleeIDs.SetValue("cricket_bat",							5);
		g_aMeleeIDs.SetValue("tonfa",								6);
		g_aMeleeIDs.SetValue("katana",								7);
		g_aMeleeIDs.SetValue("electric_guitar",						8);
		g_aMeleeIDs.SetValue("knife",								9);
		g_aMeleeIDs.SetValue("golfclub",							10);
		g_aMeleeIDs.SetValue("pitchfork",							11);
		g_aMeleeIDs.SetValue("shovel",								12);
	}



	LoadGameData();



	// ====================================================================================================
	//									TARGET FILTERS
	// ====================================================================================================
	AddMultiTargetFilter("@s",							FilterSurvivor,	"Survivors", false);
	AddMultiTargetFilter("@surv",						FilterSurvivor,	"Survivors", false);
	AddMultiTargetFilter("@survivors",					FilterSurvivor,	"Survivors", false);
	AddMultiTargetFilter("@incappedsurvivors",			FilterIncapped,	"Incapped Survivors", false);
	AddMultiTargetFilter("@is",							FilterIncapped,	"Incapped Survivors", false);
	AddMultiTargetFilter("@infe",						FilterInfected,	"Infected", false);
	AddMultiTargetFilter("@infected",					FilterInfected,	"Infected", false);
	AddMultiTargetFilter("@i",							FilterInfected,	"Infected", false);

	AddMultiTargetFilter("@randomincappedsurvivor",		FilterRandomA,	"Random Incapped Survivors", false);
	AddMultiTargetFilter("@ris",						FilterRandomA,	"Random Incapped Survivors", false);
	AddMultiTargetFilter("@randomsurvivor",				FilterRandomB,	"Random Survivors", false);
	AddMultiTargetFilter("@rs",							FilterRandomB,	"Random Survivors", false);
	AddMultiTargetFilter("@randominfected",				FilterRandomC,	"Random Infected", false);
	AddMultiTargetFilter("@ri",							FilterRandomC,	"Random Infected", false);
	AddMultiTargetFilter("@randomtank",					FilterRandomD,	"Random Tank", false);
	AddMultiTargetFilter("@rt",							FilterRandomD,	"Random Tank", false);
	AddMultiTargetFilter("@rincappedsurvivorbot",		FilterRandomE,	"Random Incapped Survivor Bot", false);
	AddMultiTargetFilter("@risb",						FilterRandomE,	"Random Incapped Survivor Bot", false);
	AddMultiTargetFilter("@rsurvivorbot",				FilterRandomF,	"Random Survivor Bot", false);
	AddMultiTargetFilter("@rsb",						FilterRandomF,	"Random Survivor Bot", false);
	AddMultiTargetFilter("@rinfectedbot",				FilterRandomG,	"Random Infected Bot", false);
	AddMultiTargetFilter("@rib",						FilterRandomG,	"Random Infected Bot", false);
	AddMultiTargetFilter("@rtankbot",					FilterRandomH,	"Random Tank Bot", false);
	AddMultiTargetFilter("@rtb",						FilterRandomH,	"Random Tank Bot", false);

	AddMultiTargetFilter("@deads",						FilterDeadA,	"Dead Survivors (all, bots)", false);
	AddMultiTargetFilter("@deadsi",						FilterDeadB,	"Dead Special Infected (all, bots)", false);
	AddMultiTargetFilter("@deadsp",						FilterDeadC,	"Dead Survivors players (no bots)", false);
	AddMultiTargetFilter("@deadsip",					FilterDeadD,	"Dead Special Infected players (no bots)", false);
	AddMultiTargetFilter("@deadsb",						FilterDeadE,	"Dead Survivors bots (no players)", false);
	AddMultiTargetFilter("@deadsib",					FilterDeadF,	"Dead Special Infected bots (no players)", false);
	AddMultiTargetFilter("@sp",							FilterPlayA,	"Survivors players (no bots)", false);
	AddMultiTargetFilter("@sip",						FilterPlayB,	"Special Infected players (no bots)", false);
	AddMultiTargetFilter("@isb",						FilterIncapA,	"Incapped Survivor Only Bots", false);
	AddMultiTargetFilter("@isp",						FilterIncapB,	"Incapped Survivor Only Players", false);

	AddMultiTargetFilter("@nick",						FilterNick,		"Nick", false);
	AddMultiTargetFilter("@rochelle",					FilterRochelle,	"Rochelle", false);
	AddMultiTargetFilter("@coach",						FilterCoach,	"Coach", false);
	AddMultiTargetFilter("@ellis",						FilterEllis,	"Ellis", false);
	AddMultiTargetFilter("@bill",						FilterBill,		"Bill", false);
	AddMultiTargetFilter("@zoey",						FilterZoey,		"Zoey", false);
	AddMultiTargetFilter("@francis",					FilterFrancis,	"Francis", false);
	AddMultiTargetFilter("@louis",						FilterLouis,	"Louis", false);

	AddMultiTargetFilter("@smokers",					FilterSmoker,	"Smokers", false);
	AddMultiTargetFilter("@boomers",					FilterBoomer,	"Boomers", false);
	AddMultiTargetFilter("@hunters",					FilterHunter,	"Hunters", false);
	AddMultiTargetFilter("@spitters",					FilterSpitter,	"Spitters", false);
	AddMultiTargetFilter("@jockeys",					FilterJockey,	"Jockeys", false);
	AddMultiTargetFilter("@chargers",					FilterCharger,	"Chargers", false);

	AddMultiTargetFilter("@tank",						FilterTanks,	"Tanks", false);
	AddMultiTargetFilter("@tanks",						FilterTanks,	"Tanks", false);
	AddMultiTargetFilter("@t",							FilterTanks,	"Tanks", false);



	// ====================================================================================================
	//									COMMANDS
	// ====================================================================================================
	// When adding or removing plugins that use any detours during gameplay. To optimize forwards by disabling unused or enabling required functions that were previously unused. TODO: Not needed when using extra-api.ext.
	RegAdminCmd("sm_l4dd_unreserve",	CmdLobby,	ADMFLAG_ROOT, "Removes lobby reservation.");
	RegAdminCmd("sm_l4dd_reload",		CmdReload,	ADMFLAG_ROOT, "Reloads the detour hooks, enabling or disabling depending if they're required by other plugins.");
	RegAdminCmd("sm_l4dd_detours",		CmdDetours,	ADMFLAG_ROOT, "Lists the currently active forwards and the plugins using them.");
	RegAdminCmd("sm_l4dhooks_reload",	CmdReload,	ADMFLAG_ROOT, "Reloads the detour hooks, enabling or disabling depending if they're required by other plugins.");
	RegAdminCmd("sm_l4dhooks_detours",	CmdDetours,	ADMFLAG_ROOT, "Lists the currently active forwards and the plugins using them.");



	// ====================================================================================================
	//									CVARS
	// ====================================================================================================
	CreateConVar("left4dhooks_version", PLUGIN_VERSION,	"Left 4 DHooks Direct plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	if( g_bLeft4Dead2 )
	{
		g_hCvar_VScriptBuffer = CreateConVar("l4d2_vscript_return", "", "Buffer used to return VScript values. Do not use.", FCVAR_DONTRECORD);
		g_hCvar_AddonsEclipse = CreateConVar("l4d2_addons_eclipse", "-1", "Addons Manager (-1: use addonconfig; 0: disable addons; 1: enable addons.)", FCVAR_NOTIFY);
		//AutoExecConfig(true, "left4dhooks");
		g_hCvar_AddonsEclipse.AddChangeHook(ConVarChanged_Cvars);

		g_hCvar_PillsHealth = FindConVar("pain_pills_health_value");
	}

	g_hCvar_PillsDecay = FindConVar("pain_pills_decay_rate");
	g_hCvar_RescueDeadTime = FindConVar("rescue_min_dead_time");
	g_hCvar_MPGameMode = FindConVar("mp_gamemode");
	g_hCvar_MPGameMode.AddChangeHook(ConVarChanged_Mode);



	// ====================================================================================================
	//									EVENTS
	// ====================================================================================================
	HookEvent("round_start",					Event_RoundStart);
	HookEvent("player_left_checkpoint",			Event_LeftCheckpoint);
	HookEvent("player_entered_checkpoint",		Event_EnteredCheckpoint);
	if( !g_bLeft4Dead2 )
		HookEvent("player_entered_start_area",	Event_EnteredCheckpoint);
}

public void Event_EnteredCheckpoint(Event event, const char[] name, bool dontBroadcast)
{
	g_bCheckpoint[GetClientOfUserId(event.GetInt("userid"))] = true;
}

public void Event_LeftCheckpoint(Event event, const char[] name, bool dontBroadcast)
{
	g_bCheckpoint[GetClientOfUserId(event.GetInt("userid"))] = false;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bRoundEnded = false;

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 2 )
			g_bCheckpoint[i] = true;
		else
			g_bCheckpoint[i] = false;
	}
}



// ====================================================================================================
//										ANIMATION HOOK
// ====================================================================================================
public void OnMapEnd()
{
	// Reset vars
	g_bMapStarted = false;
	g_iMaxChapters = 0;

	// Reset hooks
	g_iAnimationHookedClients.Clear();

	// Remove all hooked functions from private forward
	Handle hIter = GetPluginIterator();
	Handle hPlug;

	// Iterate plugins - remove animation hooks
	while( MorePlugins(hIter) )
	{
		hPlug = ReadPlugin(hIter);
		g_hAnimationCallbackPre.RemoveAllFunctions(hPlug);
		g_hAnimationCallbackPost.RemoveAllFunctions(hPlug);
	}

	delete hIter;
}



// =========================
// ANIMATION NATIVES
// =========================
public int Native_AnimHookEnable(Handle plugin, int numParams)
{
	// Validate client
	int client = GetNativeCell(1);
	if( client < 1 || client > MaxClients || !IsClientInGame(client) ) return false;

	// Check if detour enabled, otherwise enable.
	if( g_aDetoursHooked.Get(g_iAnimationDetourIndex) == 0 )
	{
		Handle hDetour = g_aDetourHandles.Get(g_iAnimationDetourIndex);
		DHookEnableDetour(hDetour, false, DTR_CBaseAnimating_SelectWeightedSequence_Pre);
		DHookEnableDetour(hDetour, true, DTR_CBaseAnimating_SelectWeightedSequence_Post);
	}

	// Add callback
	if( GetNativeFunction(2) != INVALID_FUNCTION ) g_hAnimationCallbackPre.AddFunction(plugin, GetNativeFunction(2));
	if( GetNativeFunction(3) != INVALID_FUNCTION ) g_hAnimationCallbackPost.AddFunction(plugin, GetNativeFunction(3));
	g_iAnimationHookedClients.Push(GetClientUserId(client));

	return true;
}

public int Native_AnimHookDisable(Handle plugin, int numParams)
{
	// Remove callback
	if( GetNativeFunction(2) != INVALID_FUNCTION ) g_hAnimationCallbackPre.RemoveFunction(plugin, GetNativeFunction(2));
	if( GetNativeFunction(3) != INVALID_FUNCTION ) g_hAnimationCallbackPost.RemoveFunction(plugin, GetNativeFunction(3));

	// Validate client
	int client = GetNativeCell(1);
	if( !client || !IsClientInGame(client) ) return true; // Disconnected
	client = GetClientUserId(client);

	// Remove client from checking array
	int index = g_iAnimationHookedClients.FindValue(client);
	if( index != -1 )
	{
		g_iAnimationHookedClients.Erase(index);
		return true;
	}

	return false;
}

public int Native_AnimGetActivity(Handle plugin, int numParams)
{
	int sequence = GetNativeCell(1);
	int maxlength = GetNativeCell(3);
	char[] activity = new char[maxlength];

	if( g_hAnimationActivityList.GetString(sequence, activity, maxlength) )
	{
		SetNativeString(2, activity, maxlength);
		return true;
	}

	return false;
}

public int Native_AnimGetFromActivity(Handle plugin, int numParams)
{
	int maxlength;
	GetNativeStringLength(1, maxlength);
	maxlength += 1;
	char[] activity = new char[maxlength];
	GetNativeString(1, activity, maxlength);

	int sequence = g_hAnimationActivityList.FindString(activity);
	return sequence;
}



// =========================
// ACTIVITY CONFIG
// =========================
bool ParseActivityConfig()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "data/%s.cfg", g_bLeft4Dead2 ? GAMEDATA_2 : GAMEDATA_1);
	if( FileExists(sPath) == false ) SetFailState("\n==========\nMissing required file: \"%s\".\nRead installation instructions again.\n==========", sPath);

	SMCParser parser = new SMCParser();
	SMC_SetReaders(parser, ColorConfig_NewSection, ColorConfig_KeyValue, ColorConfig_EndSection);
	parser.OnEnd = ColorConfig_End;

	char error[128];
	int line = 0, col = 0;
	SMCError result = parser.ParseFile(sPath, line, col);

	if( result != SMCError_Okay )
	{
		parser.GetErrorString(result, error, sizeof(error));
		SetFailState("%s on line %d, col %d of %s [%d]", error, line, col, sPath, result);
	}

	delete parser;
	return (result == SMCError_Okay);
}

public SMCResult ColorConfig_NewSection(Handle parser, const char[] section, bool quotes)
{
	return SMCParse_Continue;
}

public SMCResult ColorConfig_KeyValue(Handle parser, const char[] key, const char[] value, bool key_quotes, bool value_quotes)
{
	g_hAnimationActivityList.PushString(key);
	return SMCParse_Continue;
}

public SMCResult ColorConfig_EndSection(Handle parser)
{
	return SMCParse_Continue;
}

public void ColorConfig_End(Handle parser, bool halted, bool failed)
{
	if( failed )
		SetFailState("Error: Cannot load the Activity config.");
}



// ====================================================================================================
//										GAME MODE
// ====================================================================================================
public void ConVarChanged_Mode(Handle convar, const char[] oldValue, const char[] newValue)
{
	// Want to rescan max chapters on mode change
	g_iMaxChapters = 0;

	// For game mode native/forward
	GetGameMode();
}

void GetGameMode()
{
	g_iCurrentMode = 0;

	static char sMode[12];

	if( g_bLeft4Dead2 )
	{
		ValidateAddress(g_pDirector, "g_pDirector");
		ValidateNatives(g_hSDK_CDirector_GetGameModeBase, "CDirector::GetGameModeBase");

		//PrintToServer("#### CALL g_hSDK_CDirector_GetGameModeBase");
		SDKCall(g_hSDK_CDirector_GetGameModeBase, g_pDirector, sMode, sizeof(sMode));

		if( strcmp(sMode,			"coop") == 0 )		g_iCurrentMode = GAMEMODE_COOP;
		else if( strcmp(sMode,		"survival") == 0 )	g_iCurrentMode = GAMEMODE_SURVIVAL;
		else if( strcmp(sMode,		"versus") == 0 )	g_iCurrentMode = GAMEMODE_VERSUS;
		else if( strcmp(sMode,		"scavenge") == 0 )	g_iCurrentMode = GAMEMODE_SCAVENGE;
	} else {
		g_hCvar_MPGameMode.GetString(sMode, sizeof(sMode));

		if( strcmp(sMode,			"coop") == 0 )		g_iCurrentMode = GAMEMODE_COOP;
		else if( strcmp(sMode,		"survival") == 0 )	g_iCurrentMode = GAMEMODE_SURVIVAL;
		else if( strcmp(sMode,		"versus") == 0 )	g_iCurrentMode = GAMEMODE_VERSUS;
	}

	// Forward
	static int mode;

	if( mode != g_iCurrentMode )
	{
		mode = g_iCurrentMode;

		Call_StartForward(g_hFWD_GameModeChange);
		Call_PushCell(mode);
		Call_Finish();
	}
}

public int Native_Internal_GetGameMode(Handle plugin, int numParams)
{
	return g_iCurrentMode;
}

public int Native_CTerrorGameRules_IsGenericCooperativeMode(Handle plugin, int numParams)
{
	ValidateAddress(g_pGameRules, "g_pGameRules");
	ValidateNatives(g_hSDK_CTerrorGameRules_IsGenericCooperativeMode, "CTerrorGameRules::IsGenericCooperativeMode");

	//PrintToServer("#### CALL g_hSDK_CTerrorGameRules_IsGenericCooperativeMode");
	return SDKCall(g_hSDK_CTerrorGameRules_IsGenericCooperativeMode, g_pGameRules);
}

public int Native_Internal_IsCoopMode(Handle plugin, int numParams)
{
	return g_iCurrentMode == GAMEMODE_COOP;
}

public int Native_Internal_IsRealismMode(Handle plugin, int numParams)
{
	ValidateAddress(g_pGameRules, "g_pGameRules");
	ValidateNatives(g_hSDK_CTerrorGameRules_IsRealismMode, "CTerrorGameRules::IsRealismMode");

	//PrintToServer("#### CALL g_hSDK_CTerrorGameRules_IsRealismMode");
	return SDKCall(g_hSDK_CTerrorGameRules_IsRealismMode, g_pGameRules);
}

public int Native_Internal_IsSurvivalMode(Handle plugin, int numParams)
{
	return g_iCurrentMode == GAMEMODE_SURVIVAL;
}

public int Native_Internal_IsScavengeMode(Handle plugin, int numParams)
{
	return g_iCurrentMode == GAMEMODE_SCAVENGE;
}

public int Native_Internal_IsVersusMode(Handle plugin, int numParams)
{
	return g_iCurrentMode == GAMEMODE_VERSUS;
}



// ====================================================================================================
//										TARGET FILTERS
// ====================================================================================================
public bool FilterSurvivor(const char[] pattern, Handle clients)
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 2 )
		{
			PushArrayCell(clients, i);
		}
	}

	return true;
}

public bool FilterIncapped(const char[] pattern, Handle clients)
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && GetEntProp(i, Prop_Send, "m_isIncapacitated", 1) )
		{
			PushArrayCell(clients, i);
		}
	}

	return true;
}



// =========================
// Specific survivors
// =========================
void MatchSurvivor(Handle clients, int survivorCharacter)
{
	int type;
	bool matched;

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 2 )
		{
			matched = false;

			if( g_bLeft4Dead2 )
			{
				static char modelname[32];
				GetClientModel(i, modelname, sizeof(modelname));

				switch( modelname[29] )
				{
					case 'b':		type = 0; // Nick
					case 'd', 'w':	type = 1; // Rochelle, Adawong
					case 'c':		type = 2; // Coach
					case 'h':		type = 3; // Ellis
					case 'v':		type = 4; // Bill
					case 'n':		type = 5; // Zoey
					case 'e':		type = 6; // Francis
					case 'a':		type = 7; // Louis
					default:		type = 0;
				}

				if( type == survivorCharacter )
					matched = true;
			} else {
				survivorCharacter -= 4;

				if( GetEntProp(i, Prop_Send, "m_survivorCharacter") == survivorCharacter )
					matched = true;
			}

			if( matched )
			{
				PushArrayCell(clients, i);
			}
		}
	}
}

public bool FilterNick(const char[] pattern, Handle clients)
{
	if( g_bLeft4Dead2 )
		MatchSurvivor(clients, 0);
	return true;
}

public bool FilterRochelle(const char[] pattern, Handle clients)
{
	if( g_bLeft4Dead2 )
		MatchSurvivor(clients, 1);
	return true;
}

public bool FilterCoach(const char[] pattern, Handle clients)
{
	if( g_bLeft4Dead2 )
		MatchSurvivor(clients, 2);
	return true;
}

public bool FilterEllis(const char[] pattern, Handle clients)
{
	if( g_bLeft4Dead2 )
		MatchSurvivor(clients, 3);
	return true;
}

public bool FilterBill(const char[] pattern, Handle clients)
{
	MatchSurvivor(clients, 4);
	return true;
}

public bool FilterZoey(const char[] pattern, Handle clients)
{
	MatchSurvivor(clients, 5);
	return true;
}

public bool FilterFrancis(const char[] pattern, Handle clients)
{
	MatchSurvivor(clients, 6);
	return true;
}

public bool FilterLouis(const char[] pattern, Handle clients)
{
	MatchSurvivor(clients, 7);
	return true;
}



// =========================
// Filter all Infected
// =========================
public bool FilterInfected(const char[] pattern, Handle clients)
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		// Exclude tanks
		// if( IsClientInGame(i) && GetClientTeam(i) == 3 && !GetEntProp(i, Prop_Send, "m_isGhost") && GetEntProp(i, Prop_Send, "m_zombieClass") != g_iClassTank )

		// Include all specials
		if( IsClientInGame(i) && GetClientTeam(i) == 3 && !GetEntProp(i, Prop_Send, "m_isGhost") )
		{
			PushArrayCell(clients, i);
		}
	}

	return true;
}



// =========================
// Filter - Random Clients
// =========================
void MatchRandomClient(Handle clients, int index)
{
	ArrayList aList = new ArrayList();

	for( int i = 1; i <= MaxClients; i++ )
	{
		switch( index )
		{
			case 1:			if( IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && GetEntProp(i, Prop_Send, "m_isIncapacitated", 1) )									aList.Push(i);	// Random Incapped Survivors
			case 2:			if( IsClientInGame(i) && GetClientTeam(i) == 2 )																											aList.Push(i);	// Random Survivors
			case 3:			if( IsClientInGame(i) && GetClientTeam(i) == 3 )																											aList.Push(i);	// Random Infected
			case 4:			if( IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i) && GetEntProp(i, Prop_Send, "m_zombieClass") == g_iClassTank )							aList.Push(i);	// Random Tank
			case 5:			if( IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && IsFakeClient(i) && GetEntProp(i, Prop_Send, "m_isIncapacitated", 1) )					aList.Push(i);	// Random Incapped Survivor Bot
			case 6:			if( IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && IsFakeClient(i) )																		aList.Push(i);	// Random Survivor Bot
			case 7:			if( IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i) && IsFakeClient(i) )																		aList.Push(i);	// Random Infected Bot
			case 8:			if( IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i) && IsFakeClient(i) && GetEntProp(i, Prop_Send, "m_zombieClass") == g_iClassTank )		aList.Push(i);	// Random Tank Bot
		}
	}

	PushArrayCell(clients, aList.Get(GetRandomInt(0, aList.Length - 1)));

	delete aList;
}

public bool FilterRandomA(const char[] pattern, Handle clients)
{
	MatchRandomClient(clients, 1);
	return true;
}

public bool FilterRandomB(const char[] pattern, Handle clients)
{
	MatchRandomClient(clients, 2);
	return true;
}

public bool FilterRandomC(const char[] pattern, Handle clients)
{
	MatchRandomClient(clients, 3);
	return true;
}

public bool FilterRandomD(const char[] pattern, Handle clients)
{
	MatchRandomClient(clients, 4);
	return true;
}

public bool FilterRandomE(const char[] pattern, Handle clients)
{
	MatchRandomClient(clients, 5);
	return true;
}

public bool FilterRandomF(const char[] pattern, Handle clients)
{
	MatchRandomClient(clients, 6);
	return true;
}

public bool FilterRandomG(const char[] pattern, Handle clients)
{
	MatchRandomClient(clients, 7);
	return true;
}

public bool FilterRandomH(const char[] pattern, Handle clients)
{
	MatchRandomClient(clients, 8);
	return true;
}



// =========================
// Various matches
// =========================
void MatchVariousClients(Handle clients, int index)
{
	ArrayList aList = new ArrayList();

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) )
		{
			switch( index )
			{
				case 1:			if( !IsPlayerAlive(i) && GetClientTeam(i) == 2 )															aList.Push(i);	// "Dead Survivors (all, bots)"
				case 2:			if( !IsPlayerAlive(i) && GetClientTeam(i) == 3 )															aList.Push(i);	// "Dead Special Infected (all, bots)"
				case 3:			if( !IsPlayerAlive(i) && GetClientTeam(i) == 2 && !IsFakeClient(i) )										aList.Push(i);	// "Dead Survivors players (no bots)"
				case 4:			if( !IsPlayerAlive(i) && GetClientTeam(i) == 3 && !IsFakeClient(i) )										aList.Push(i);	// "Dead Special Infected players (no bots)"
				case 5:			if( !IsPlayerAlive(i) && GetClientTeam(i) == 2 && IsFakeClient(i) )											aList.Push(i);	// "Dead Survivors bots (no players)"
				case 6:			if( !IsPlayerAlive(i) && GetClientTeam(i) == 3 && IsFakeClient(i) )											aList.Push(i);	// "Dead Special Infected bots (no players)"
				case 7:			if( GetClientTeam(i) == 2 && !IsFakeClient(i) )																aList.Push(i);	// "Survivors players (no bots)"
				case 8:			if( GetClientTeam(i) == 3 && !IsFakeClient(i) )																aList.Push(i);	// "Special Infected players (no bots)"
				case 9:			if( GetClientTeam(i) == 2 && IsFakeClient(i) && GetEntProp(i, Prop_Send, "m_isIncapacitated", 1) )			aList.Push(i);	// "Incapped Survivor Only Bots"
				case 10:		if( GetClientTeam(i) == 2 && !IsFakeClient(i) && GetEntProp(i, Prop_Send, "m_isIncapacitated", 1) )			aList.Push(i);	// "Incapped Survivor Only Players"
			}
		}
	}

	PushArrayCell(clients, aList.Get(GetRandomInt(0, aList.Length - 1)));

	delete aList;
}

public bool FilterDeadA(const char[] pattern, Handle clients)
{
	MatchVariousClients(clients, 1);
	return true;
}

public bool FilterDeadB(const char[] pattern, Handle clients)
{
	MatchVariousClients(clients, 2);
	return true;
}

public bool FilterDeadC(const char[] pattern, Handle clients)
{
	MatchVariousClients(clients, 3);
	return true;
}

public bool FilterDeadD(const char[] pattern, Handle clients)
{
	MatchVariousClients(clients, 4);
	return true;
}

public bool FilterDeadE(const char[] pattern, Handle clients)
{
	MatchVariousClients(clients, 5);
	return true;
}

public bool FilterDeadF(const char[] pattern, Handle clients)
{
	MatchVariousClients(clients, 6);
	return true;
}

public bool FilterPlayA(const char[] pattern, Handle clients)
{
	MatchVariousClients(clients, 7);
	return true;
}

public bool FilterPlayB(const char[] pattern, Handle clients)
{
	MatchVariousClients(clients, 8);
	return true;
}

public bool FilterIncapA(const char[] pattern, Handle clients)
{
	MatchVariousClients(clients, 9);
	return true;
}

public bool FilterIncapB(const char[] pattern, Handle clients)
{
	MatchVariousClients(clients, 10);
	return true;
}



// =========================
// Specific Infected
// =========================
void MatchZombie(Handle clients, int zombieClass)
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 3 && GetEntProp(i, Prop_Send, "m_zombieClass") == zombieClass )
		{
			PushArrayCell(clients, i);
		}
	}
}

public bool FilterSmoker(const char[] pattern, Handle clients)
{
	MatchZombie(clients, 1);
	return true;
}

public bool FilterBoomer(const char[] pattern, Handle clients)
{
	MatchZombie(clients, 2);
	return true;
}

public bool FilterHunter(const char[] pattern, Handle clients)
{
	MatchZombie(clients, 3);
	return true;
}

public bool FilterSpitter(const char[] pattern, Handle clients)
{
	MatchZombie(clients, 4);
	return true;
}

public bool FilterJockey(const char[] pattern, Handle clients)
{
	MatchZombie(clients, 5);
	return true;
}

public bool FilterCharger(const char[] pattern, Handle clients)
{
	MatchZombie(clients, 6);
	return true;
}

public bool FilterTanks(const char[] pattern, Handle clients)
{
	MatchZombie(clients, g_iClassTank);
	return true;
}



// ====================================================================================================
//										CLEAN UP
// ====================================================================================================
public void OnPluginEnd()
{
	if( g_bLeft4Dead2 )
		AddonsDisabler_Unpatch();

	// Target Filters
	RemoveMultiTargetFilter("@s",						FilterSurvivor);
	RemoveMultiTargetFilter("@surv",					FilterSurvivor);
	RemoveMultiTargetFilter("@survivors",				FilterSurvivor);
	RemoveMultiTargetFilter("@incappedsurvivors",		FilterIncapped);
	RemoveMultiTargetFilter("@is",						FilterIncapped);
	RemoveMultiTargetFilter("@infe",					FilterInfected);
	RemoveMultiTargetFilter("@infected",				FilterInfected);
	RemoveMultiTargetFilter("@i",						FilterInfected);

	RemoveMultiTargetFilter("@randomincappedsurvivor",	FilterRandomA);
	RemoveMultiTargetFilter("@ris",						FilterRandomA);
	RemoveMultiTargetFilter("@randomsurvivor",			FilterRandomB);
	RemoveMultiTargetFilter("@rs",						FilterRandomB);
	RemoveMultiTargetFilter("@randominfected",			FilterRandomC);
	RemoveMultiTargetFilter("@ri",						FilterRandomC);
	RemoveMultiTargetFilter("@randomtank",				FilterRandomD);
	RemoveMultiTargetFilter("@rt",						FilterRandomD);
	RemoveMultiTargetFilter("@rincappedsurvivorbot",	FilterRandomE);
	RemoveMultiTargetFilter("@risb",					FilterRandomE);
	RemoveMultiTargetFilter("@rsurvivorbot",			FilterRandomF);
	RemoveMultiTargetFilter("@rsb",						FilterRandomF);
	RemoveMultiTargetFilter("@rinfectedbot",			FilterRandomG);
	RemoveMultiTargetFilter("@rib",						FilterRandomG);
	RemoveMultiTargetFilter("@rtankbot",				FilterRandomH);
	RemoveMultiTargetFilter("@rtb",						FilterRandomH);

	RemoveMultiTargetFilter("@deads",					FilterDeadA);
	RemoveMultiTargetFilter("@deadsi",					FilterDeadB);
	RemoveMultiTargetFilter("@deadsp",					FilterDeadC);
	RemoveMultiTargetFilter("@deadsip",					FilterDeadD);
	RemoveMultiTargetFilter("@deadsb",					FilterDeadE);
	RemoveMultiTargetFilter("@deadsib",					FilterDeadF);
	RemoveMultiTargetFilter("@sp",						FilterPlayA);
	RemoveMultiTargetFilter("@sip",						FilterPlayB);
	RemoveMultiTargetFilter("@isb",						FilterIncapA);
	RemoveMultiTargetFilter("@isp",						FilterIncapB);

	RemoveMultiTargetFilter("@nick",					FilterNick);
	RemoveMultiTargetFilter("@rochelle",				FilterRochelle);
	RemoveMultiTargetFilter("@coach",					FilterCoach);
	RemoveMultiTargetFilter("@ellis",					FilterEllis);
	RemoveMultiTargetFilter("@bill",					FilterBill);
	RemoveMultiTargetFilter("@zoey",					FilterZoey);
	RemoveMultiTargetFilter("@francis",					FilterFrancis);
	RemoveMultiTargetFilter("@louis",					FilterLouis);

	RemoveMultiTargetFilter("@smokers",					FilterSmoker);
	RemoveMultiTargetFilter("@boomers",					FilterBoomer);
	RemoveMultiTargetFilter("@hunters",					FilterHunter);
	RemoveMultiTargetFilter("@spitters",				FilterSpitter);
	RemoveMultiTargetFilter("@jockeys",					FilterJockey);
	RemoveMultiTargetFilter("@chargers",				FilterCharger);

	RemoveMultiTargetFilter("@tank",					FilterTanks);
	RemoveMultiTargetFilter("@tanks",					FilterTanks);
	RemoveMultiTargetFilter("@t",						FilterTanks);
}



// ====================================================================================================
//										DISABLE ADDONS
// ====================================================================================================
public void OnConfigsExecuted()
{
	if( g_bLeft4Dead2 )
		ConVarChanged_Cvars(null, "", "");
}

bool g_bAddonsPatched;

public void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	if( g_hCvar_AddonsEclipse.IntValue > -1 )
		AddonsDisabler_Patch();
	else
		AddonsDisabler_Unpatch();
}

int AddonsDisabler_Restore[3];
void AddonsDisabler_Patch()
{
	if( !g_bAddonsPatched )
	{
		g_bAddonsPatched = true;
		AddonsDisabler_Restore[0] = LoadFromAddress(g_pVanillaModeAddress + view_as<Address>(g_iOff_VanillaModeOffset), NumberType_Int8);
		AddonsDisabler_Restore[1] = LoadFromAddress(g_pVanillaModeAddress + view_as<Address>(g_iOff_VanillaModeOffset + 1), NumberType_Int8);
		AddonsDisabler_Restore[2] = LoadFromAddress(g_pVanillaModeAddress + view_as<Address>(g_iOff_VanillaModeOffset + 2), NumberType_Int8);
	}

	//PrintToServer("Addons restore: %02x%02x%02x", AddonsDisabler_Restore[0], AddonsDisabler_Restore[1], AddonsDisabler_Restore[2]);
	StoreToAddress(g_pVanillaModeAddress + view_as<Address>(g_iOff_VanillaModeOffset), 0x0F, NumberType_Int8);
	StoreToAddress(g_pVanillaModeAddress + view_as<Address>(g_iOff_VanillaModeOffset + 1), 0x1F, NumberType_Int8);
	StoreToAddress(g_pVanillaModeAddress + view_as<Address>(g_iOff_VanillaModeOffset + 2), 0x00, NumberType_Int8);
}

void AddonsDisabler_Unpatch()
{
	if( g_bAddonsPatched )
	{
		g_bAddonsPatched = false;
		StoreToAddress(g_pVanillaModeAddress + view_as<Address>(g_iOff_VanillaModeOffset), AddonsDisabler_Restore[0], NumberType_Int8);
		StoreToAddress(g_pVanillaModeAddress + view_as<Address>(g_iOff_VanillaModeOffset + 1), AddonsDisabler_Restore[1], NumberType_Int8);
		StoreToAddress(g_pVanillaModeAddress + view_as<Address>(g_iOff_VanillaModeOffset + 2), AddonsDisabler_Restore[2], NumberType_Int8);
	}
}



// ====================================================================================================
//										ADDONS DISABLER DETOUR
// ====================================================================================================
public MRESReturn DTR_AddonsDisabler(int pThis, Handle hReturn, Handle hParams)
{
	// Details on finding offsets can be found here: https://github.com/ProdigySim/left4dhooks/pull/1
	// Big thanks to "ProdigySim" for updating for The Last Stand update.

	#if DEBUG
	PrintToServer("##### DTR_AddonsDisabler");
	#endif

	int cvar = g_hCvar_AddonsEclipse.IntValue;
	if( cvar != -1 )
	{
		int ptr = DHookGetParam(hParams, 1);

		// This is `m_nPlayerSlot` on the `SVC_ServerInfo`.
		// It represents the client index of the connecting user.
		int playerSlot = LoadFromAddress(view_as<Address>(ptr + g_iOff_AddonEclipse1), NumberType_Int8);
		// The playerslot is an index into `CBaseServer::m_Clients`, and SourceMod's client entity indexes are just `m_Clients` index plus 1.
		int client = playerSlot + 1;

		#if DEBUG
		PrintToServer("#### AddonCheck for %d", client);
		#endif

		if( client > 0 && client <= MaxClients && IsClientConnected(client) )
		{
			// Yes False, because we need SteamID soon as connected, this is how downtown worked.
			static char netID[32];
			GetClientAuthId(client, AuthId_Steam2, netID, sizeof(netID), false);

			#if DEBUG
			PrintToServer("#### AddonCheck for %d [%s] (%N)", client, netID, client);
			#endif

			Action aResult = Plugin_Continue;
			Call_StartForward(g_hFWD_AddonsDisabler);
			Call_PushString(netID);
			Call_Finish(aResult);

			// 1 to tell the client it should use "vanilla mode"--no addons. 0 to enable addons.
			int bVanillaMode = aResult == Plugin_Handled ? 0 : view_as<int>(!cvar);
			StoreToAddress(view_as<Address>(ptr + g_iOff_AddonEclipse2), bVanillaMode, NumberType_Int8);
			
			#if DEBUG
			PrintToServer("#### AddonCheck vanillaMode for %d [%s] (%N): %d", client, netID, client, bVanillaMode);
			#endif
		}
	}

	return MRES_Ignored;
}



// ====================================================================================================
//										DYNAMIC DETOURS SETUP
// ====================================================================================================
public void AP_OnPluginUpdate(int pre) 
{
	if( pre == 0 && GetEngineTime() - g_fLoadTime > 5.0 )
	{
		CallCheckRequiredDetours();
	}
}

public Action CmdLobby(int client, int args)
{
	Native_CBaseServer_SetReservationCookie(null, 0);
	return Plugin_Handled;
}

public Action CmdDetours(int client, int args)
{
	CallCheckRequiredDetours(client + 1);
	return Plugin_Handled;
}

void CallCheckRequiredDetours(int client = 0)
{
	#if DEBUG
	g_vProf = CreateProfiler();
	g_fProf = 0.0;
	StartProfiling(g_vProf);
	#endif

	CheckRequiredDetours(client);

	#if DEBUG
	StopProfiling(g_vProf);
	g_fProf += GetProfilerTime(g_vProf);
	PrintToServer("");
	PrintToServer("Dynamic Detours finished in %f seconds.", g_fProf);
	PrintToServer("");
	delete g_vProf;
	#endif

}

public Action CmdReload(int client, int args)
{
	float timing = GetEngineTime();
	OnMapStart();
	ReplyToCommand(client, "[Left4DHooks: Detours reloaded in %f seconds.", GetEngineTime() - timing);
	return Plugin_Handled;
}

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
		g_aGameDataSigs = new ArrayList(ByteCountToCells(MAX_FWD_LEN));
		g_aForwardNames = new ArrayList(ByteCountToCells(MAX_FWD_LEN));
	}

	g_iCurrentIndex = 0;



	// Forwards listed here must match forward list in plugin start.
	//			 GameData	DHookCallback PRE											DHookCallback POST									Signature Name														Forward Name							useLast index		forceOn detour
	CreateDetour(hGameData, DTR_ZombieManager_SpawnTank,								INVALID_FUNCTION,									"ZombieManager::SpawnTank",									"L4D_OnSpawnTank");

	if( !g_bLeft4Dead2 && g_bLinuxOS )
		CreateDetour(hGameData, DTR_ZombieManager_SpawnWitch_Area,						INVALID_FUNCTION,									"ZombieManager::SpawnWitch_Area",								"L4D_OnSpawnWitch");
		// CreateDetour(hGameData, DTR_ZombieManager_SpawnWitch_AreaPre,					DTR_ZombieManager_SpawnWitch_Area,					"ZombieManager::SpawnWitch_Area",											"L4D_OnSpawnWitch");

	CreateDetour(hGameData, DTR_ZombieManager_SpawnWitch,								INVALID_FUNCTION,									"ZombieManager::SpawnWitch",									"L4D_OnSpawnWitch");
	CreateDetour(hGameData, DTR_CDirector_MobRushStart,									INVALID_FUNCTION,									"CDirector::OnMobRushStart",									"L4D_OnMobRushStart");
	CreateDetour(hGameData, DTR_ZombieManager_SpawnITMob,								INVALID_FUNCTION,									"ZombieManager::SpawnITMob",									"L4D_OnSpawnITMob");
	CreateDetour(hGameData, DTR_ZombieManager_SpawnMob,									INVALID_FUNCTION,									"ZombieManager::SpawnMob",									"L4D_OnSpawnMob");
	CreateDetour(hGameData, DTR_CTerrorPlayer_EnterGhostState_Pre,						DTR_CTerrorPlayer_EnterGhostState_Post,				"CTerrorPlayer::OnEnterGhostState",							"L4D_OnEnterGhostState");
	CreateDetour(hGameData, DTR_CTerrorPlayer_EnterGhostState_Pre,						DTR_CTerrorPlayer_EnterGhostState_Post,				"CTerrorPlayer::OnEnterGhostState",							"L4D_OnEnterGhostStatePre",				true); // Different forwards, same detour as above - same index.
	CreateDetour(hGameData, DTR_CDirector_IsTeamFull,									INVALID_FUNCTION,									"CDirector::IsTeamFull",										"L4D_OnIsTeamFull");
	CreateDetour(hGameData, DTR_CTerrorGameRules_ClearTeamScores,						INVALID_FUNCTION,									"CTerrorGameRules::ClearTeamScores",							"L4D_OnClearTeamScores");
	CreateDetour(hGameData, DTR_CTerrorGameRules_SetCampaignScores,						INVALID_FUNCTION,									"CTerrorGameRules::SetCampaignScores",						"L4D_OnSetCampaignScores");

	if( !g_bLeft4Dead2 )
		CreateDetour(hGameData, DTR_CTerrorPlayer_RecalculateVersusScore,				INVALID_FUNCTION,									"CTerrorPlayer::RecalculateVersusScore",						"L4D_OnRecalculateVersusScore");

	CreateDetour(hGameData, DTR_CDirector_OnFirstSurvivorLeftSafeArea,					INVALID_FUNCTION,									"CDirector::OnFirstSurvivorLeftSafeArea",						"L4D_OnFirstSurvivorLeftSafeArea");
	CreateDetour(hGameData, DTR_CTerrorPlayer_GetCrouchTopSpeed_Pre,					DTR_CTerrorPlayer_GetCrouchTopSpeed_Post,			"CTerrorPlayer::GetCrouchTopSpeed",							"L4D_OnGetCrouchTopSpeed");
	CreateDetour(hGameData, DTR_CTerrorPlayer_GetRunTopSpeed_Pre,						DTR_CTerrorPlayer_GetRunTopSpeed_Post,				"CTerrorPlayer::GetRunTopSpeed",								"L4D_OnGetRunTopSpeed");
	CreateDetour(hGameData, DTR_CTerrorPlayer_GetWalkTopSpeed_Pre,						DTR_CTerrorPlayer_GetWalkTopSpeed_Post,				"CTerrorPlayer::GetWalkTopSpeed",								"L4D_OnGetWalkTopSpeed");
	CreateDetour(hGameData, DTR_CDirectorVersusMode_GetMissionVersusBossSpawning,		INVALID_FUNCTION,									"CDirectorVersusMode::GetMissionVersusBossSpawning",			"L4D_OnGetMissionVSBossSpawning");
	CreateDetour(hGameData, DTR_ZombieManager_ReplaceTank,								INVALID_FUNCTION,									"ZombieManager::ReplaceTank",									"L4D_OnReplaceTank");
	CreateDetour(hGameData, DTR_CTankClaw_DoSwing_Pre,									DTR_CTankClaw_DoSwing_Post,							"CTankClaw::DoSwing",											"L4D_TankClaw_DoSwing_Pre");
	CreateDetour(hGameData, DTR_CTankClaw_DoSwing_Pre,									DTR_CTankClaw_DoSwing_Post,							"CTankClaw::DoSwing",											"L4D_TankClaw_DoSwing_Post",			true); // Different forwards, same detour as above - same index.
	CreateDetour(hGameData, DTR_CTankClaw_GroundPound_Pre,								DTR_CTankClaw_GroundPound_Post,						"CTankClaw::GroundPound",										"L4D_TankClaw_GroundPound_Pre");
	CreateDetour(hGameData, DTR_CTankClaw_GroundPound_Pre,								DTR_CTankClaw_GroundPound_Post,						"CTankClaw::GroundPound",										"L4D_TankClaw_GroundPound_Post",		true); // Different forwards, same detour as above - same index.
	CreateDetour(hGameData, DTR_CTankClaw_OnPlayerHit_Pre,								DTR_CTankClaw_OnPlayerHit_Post,						"CTankClaw::OnPlayerHit",										"L4D_TankClaw_OnPlayerHit_Pre");
	CreateDetour(hGameData, DTR_CTankClaw_OnPlayerHit_Pre,								DTR_CTankClaw_OnPlayerHit_Post,						"CTankClaw::OnPlayerHit",										"L4D_TankClaw_OnPlayerHit_Post",		true); // Different forwards, same detour as above - same index.
	CreateDetour(hGameData, DTR_CTankRock_Detonate,										INVALID_FUNCTION,									"CTankRock::Detonate",										"L4D_TankRock_OnDetonate");
	CreateDetour(hGameData, DTR_CTankRock_OnRelease,									INVALID_FUNCTION,									"CTankRock::OnRelease",										"L4D_TankRock_OnRelease");
	CreateDetour(hGameData, DTR_CThrow_ActivateAbililty,								INVALID_FUNCTION,									"CThrow::ActivateAbililty",									"L4D_OnCThrowActivate");
	g_iAnimationDetourIndex = g_iCurrentIndex; // Animation Hook - detour index to enable when required.
	CreateDetour(hGameData, DTR_CBaseAnimating_SelectWeightedSequence_Pre,				DTR_CBaseAnimating_SelectWeightedSequence_Post,		"CBaseAnimating::SelectWeightedSequence",						"L4D2_OnSelectTankAttack"); // Animation Hook
	CreateDetour(hGameData, DTR_CBaseAnimating_SelectWeightedSequence_Pre,				DTR_CBaseAnimating_SelectWeightedSequence_Post,		"CBaseAnimating::SelectWeightedSequence",						"L4D2_OnSelectTankAttackPre",			true); // Animation Hook
	CreateDetour(hGameData, DTR_CDirectorVersusMode_EndVersusModeRound_Pre,				DTR_CDirectorVersusMode_EndVersusModeRound_Post,	"CDirectorVersusMode::EndVersusModeRound",					"L4D2_OnEndVersusModeRound");
	CreateDetour(hGameData,	DTR_CDirectorVersusMode_EndVersusModeRound_Pre,				DTR_CDirectorVersusMode_EndVersusModeRound_Post,	"CDirectorVersusMode::EndVersusModeRound",					"L4D2_OnEndVersusModeRound_Post",		true); // Different forwards, same detour as above - same index.
	CreateDetour(hGameData, DTR_CTerrorPlayer_OnLedgeGrabbed,							INVALID_FUNCTION,									"CTerrorPlayer::OnLedgeGrabbed",								"L4D_OnLedgeGrabbed");
	CreateDetour(hGameData, DTR_CTerrorPlayer_OnRevived_Pre,							DTR_CTerrorPlayer_OnRevived_Post,					"CTerrorPlayer::OnRevived",									"L4D2_OnRevived");

	if( !g_bLinuxOS ) // Blocked on Linux in L4D1/L4D2 to prevent crashes. Waiting for DHooks update to support object returns.
	{
		CreateDetour(hGameData, DTR_SurvivorBot_UseHealingItems,						INVALID_FUNCTION,									"SurvivorBot::UseHealingItems",								"L4D2_OnUseHealingItems");
		CreateDetour(hGameData, DTR_CDirectorScriptedEventManager_SendInRescueVehicle,	INVALID_FUNCTION,									"CDirectorScriptedEventManager::SendInRescueVehicle",			"L4D2_OnSendInRescueVehicle");
	}

	CreateDetour(hGameData, DTR_CDirector_TryOfferingTankBot,							INVALID_FUNCTION,									"CDirector::TryOfferingTankBot",								"L4D_OnTryOfferingTankBot");
	CreateDetour(hGameData, DTR_CTerrorPlayer_OnShovedBySurvivor,						INVALID_FUNCTION,									"CTerrorPlayer::OnShovedBySurvivor",							"L4D_OnShovedBySurvivor");
	CreateDetour(hGameData, DTR_CTerrorPlayer_OnStaggered,								INVALID_FUNCTION,									"CTerrorPlayer::OnStaggered",									"L4D2_OnStagger");

	if( !g_bLeft4Dead2 && g_bLinuxOS )
	{
		CreateDetour(hGameData, DTR_CDirector_TryOfferingTankBot_Clone,					INVALID_FUNCTION,									"CDirector::TryOfferingTankBot_Clone",						"L4D_OnTryOfferingTankBot");
		CreateDetour(hGameData, DTR_CTerrorPlayer_OnShovedBySurvivor_Clone,				INVALID_FUNCTION,									"CTerrorPlayer::OnShovedBySurvivor_Clone",					"L4D_OnShovedBySurvivor");
		CreateDetour(hGameData, DTR_CTerrorPlayer_OnStaggered_Clone,					INVALID_FUNCTION,									"CTerrorPlayer::OnStaggered_Clone",							"L4D2_OnStagger");
	}

	CreateDetour(hGameData, DTR_CTerrorWeapon_OnHit,									INVALID_FUNCTION,									"CTerrorWeapon::OnHit",										"L4D2_OnEntityShoved");
	CreateDetour(hGameData, DTR_CTerrorPlayer_OnShovedByPounceLanding,					INVALID_FUNCTION,									"CTerrorPlayer::OnShovedByPounceLanding",						"L4D2_OnPounceOrLeapStumble");
	CreateDetour(hGameData, DTR_CDeathFallCamera_Enable,								INVALID_FUNCTION,									"CDeathFallCamera::Enable",									"L4D_OnFatalFalling");
	CreateDetour(hGameData, DTR_CTerrorPlayer_OnFalling_Pre,							DTR_CTerrorPlayer_OnFalling_Post,					"CTerrorPlayer::OnFalling",									"L4D_OnFalling");
	CreateDetour(hGameData, DTR_Tank_EnterStasis_Pre,									DTR_Tank_EnterStasis_Post,							"Tank::EnterStasis",											"L4D_OnEnterStasis");
	CreateDetour(hGameData, DTR_Tank_LeaveStasis_Pre,									DTR_Tank_LeaveStasis_Post,							"Tank::LeaveStasis",											"L4D_OnLeaveStasis");
	CreateDetour(hGameData, DTR_CInferno_Spread,										INVALID_FUNCTION,									"CInferno::Spread",											"L4D2_OnSpitSpread");
	CreateDetour(hGameData, DTR_SurvivorBot_FindScavengeItem_Pre,						DTR_SurvivorBot_FindScavengeItem_Post,				"SurvivorBot::FindScavengeItem",								"L4D2_OnFindScavengeItem");
	CreateDetour(hGameData, DTR_BossZombiePlayerBot_ChooseVictim_Pre,					DTR_BossZombiePlayerBot_ChooseVictim_Post,			"BossZombiePlayerBot::ChooseVictim",							"L4D2_OnChooseVictim");
	CreateDetour(hGameData, DTR_CTerrorPlayer_MaterializeFromGhost_Pre,					DTR_CTerrorPlayer_MaterializeFromGhost_Post,		"CTerrorPlayer::MaterializeFromGhost",						"L4D_OnMaterializeFromGhostPre");
	CreateDetour(hGameData, DTR_CTerrorPlayer_MaterializeFromGhost_Pre,					DTR_CTerrorPlayer_MaterializeFromGhost_Post,		"CTerrorPlayer::MaterializeFromGhost",						"L4D_OnMaterializeFromGhost",			true); // Different forwards, same detour as above - same index.
	CreateDetour(hGameData, DTR_CPipeBombProjectile_Create_Pre,							DTR_CPipeBombProjectile_Create_Post,				"CPipeBombProjectile::Create",								"L4D_PipeBombProjectile_Pre");
	CreateDetour(hGameData, DTR_CPipeBombProjectile_Create_Pre,							DTR_CPipeBombProjectile_Create_Post,				"CPipeBombProjectile::Create",								"L4D_PipeBombProjectile_Post",			true); // Different forwards, same detour as above - same index.
	CreateDetour(hGameData, DTR_CTerrorPlayer_Extinguish,								INVALID_FUNCTION,									"CTerrorPlayer::Extinguish",									"L4D_PlayerExtinguish");
	CreateDetour(hGameData, DTR_CBreakableProp_Break_Pre,								DTR_CBreakableProp_Break_Post,						"CBreakableProp::Break",										"L4D_CBreakableProp_Break");
	CreateDetour(hGameData, DTR_CTerrorPlayer_OnVomitedUpon,							INVALID_FUNCTION,									"CTerrorPlayer::OnVomitedUpon",								"L4D_OnVomitedUpon");
	CreateDetour(hGameData, DTR_CTerrorPlayer_OnPouncedOnSurvivor,						INVALID_FUNCTION,									"CTerrorPlayer::OnPouncedOnSurvivor",							"L4D_OnPouncedOnSurvivor");
	CreateDetour(hGameData, DTR_CTerrorPlayer_GrabVictimWithTongue,						INVALID_FUNCTION,									"CTerrorPlayer::GrabVictimWithTongue",						"L4D_OnGrabWithTongue");

	if( !g_bLeft4Dead2 )
	{
		// Different detours, same forward (L4D_OnSpawnSpecial).
		CreateDetour(hGameData, DTR_ZombieManager_SpawnHunter,							INVALID_FUNCTION,									"ZombieManager::SpawnHunter",									"L4D_OnSpawnSpecial");
		CreateDetour(hGameData, DTR_ZombieManager_SpawnBoomer,							INVALID_FUNCTION,									"ZombieManager::SpawnBoomer",									"L4D_OnSpawnSpecial");
		CreateDetour(hGameData, DTR_ZombieManager_SpawnSmoker,							INVALID_FUNCTION,									"ZombieManager::SpawnSmoker",									"L4D_OnSpawnSpecial");
	}
	else
	{
		CreateDetour(hGameData, DTR_CTerrorPlayer_OnLeptOnSurvivor,						INVALID_FUNCTION,									"CTerrorPlayer::OnLeptOnSurvivor",							"L4D2_OnJockeyRide");
		CreateDetour(hGameData, DTR_CTerrorPlayer_OnStartCarryingVictim,				INVALID_FUNCTION,									"CTerrorPlayer::OnStartCarryingVictim",						"L4D2_OnStartCarryingVictim");
		CreateDetour(hGameData, DTR_CGasCanEvent_Killed,								INVALID_FUNCTION,									"CGasCan::Event_Killed",										"L4D2_CGasCan_EventKilled");
		CreateDetour(hGameData, DTR_CGasCan_OnActionComplete,							INVALID_FUNCTION,									"CGasCan::OnActionComplete",									"L4D2_CGasCan_ActionComplete");
		CreateDetour(hGameData, DTR_CInsectSwarm_CanHarm,								INVALID_FUNCTION,									"CInsectSwarm::CanHarm",										"L4D2_CInsectSwarm_CanHarm");
		CreateDetour(hGameData, DTR_CTerrorPlayer_Fling,								INVALID_FUNCTION,									"CTerrorPlayer::Fling",										"L4D2_OnPlayerFling");
		CreateDetour(hGameData, DTR_CTerrorPlayer_OnHitByVomitJar,						INVALID_FUNCTION,									"CTerrorPlayer::OnHitByVomitJar",								"L4D2_OnHitByVomitJar");
		CreateDetour(hGameData, DTR_ZombieManager_SpawnSpecial,							INVALID_FUNCTION,									"ZombieManager::SpawnSpecial",								"L4D_OnSpawnSpecial");
		CreateDetour(hGameData, DTR_ZombieManager_SpawnWitchBride,						INVALID_FUNCTION,									"ZombieManager::SpawnWitchBride",								"L4D2_OnSpawnWitchBride");
		CreateDetour(hGameData, DTR_CDirector_GetScriptValueInt,						INVALID_FUNCTION,									"CDirector::GetScriptValueInt",								"L4D_OnGetScriptValueInt");
		CreateDetour(hGameData, DTR_CDirector_GetScriptValueFloat,						INVALID_FUNCTION,									"CDirector::GetScriptValueFloat",								"L4D_OnGetScriptValueFloat");
		CreateDetour(hGameData, DTR_CDirector_GetScriptValueString,						INVALID_FUNCTION,									"CDirector::GetScriptValueString",							"L4D_OnGetScriptValueString");
		CreateDetour(hGameData, DTR_CTerrorGameRules_HasConfigurableDifficultySetting,	INVALID_FUNCTION,									"CTerrorGameRules::HasConfigurableDifficultySetting",			"L4D_OnHasConfigurableDifficulty");
		CreateDetour(hGameData, DTR_CTerrorGameRules_GetSurvivorSet_Pre,				DTR_CTerrorGameRules_GetSurvivorSet,				"CTerrorGameRules::GetSurvivorSet",							"L4D_OnGetSurvivorSet");
		CreateDetour(hGameData, DTR_CTerrorGameRules_FastGetSurvivorSet_Pre,			DTR_CTerrorGameRules_FastGetSurvivorSet,			"CTerrorGameRules::FastGetSurvivorSet",						"L4D_OnFastGetSurvivorSet");
		CreateDetour(hGameData, DTR_CTerrorMeleeWeapon_StartMeleeSwing,					INVALID_FUNCTION,									"CTerrorMeleeWeapon::StartMeleeSwing",						"L4D_OnStartMeleeSwing");
		CreateDetour(hGameData, DTR_CTerrorMeleeWeapon_GetDamageForVictim_Pre,			DTR_CTerrorMeleeWeapon_GetDamageForVictim_Post,		"CTerrorMeleeWeapon::GetDamageForVictim",						"L4D2_MeleeGetDamageForVictim");
		CreateDetour(hGameData, DTR_CDirectorScriptedEventManager_ChangeFinaleStage,	INVALID_FUNCTION,									"CDirectorScriptedEventManager::ChangeFinaleStage",			"L4D2_OnChangeFinaleStage");
		CreateDetour(hGameData, DTR_AddonsDisabler,										INVALID_FUNCTION,									"CBaseServer::FillServerInfo",								"L4D2_OnClientDisableAddons",			false,				true); // Force detour to enable.
	}

	// Deprecated, unused or broken.
	// CreateDetour(hGameData, DTR_ZombieManager_GetRandomPZSpawnPosition,					INVALID_FUNCTION,									"ZombieManager::GetRandomPZSpawnPosition",					"L4D_OnGetRandomPZSpawnPosition");
	// CreateDetour(hGameData, DTR_InfectedShoved_OnShoved,								INVALID_FUNCTION,									"InfectedShoved::OnShoved",									"L4D_OnInfectedShoved"); // Missing signature
	// CreateDetour(hGameData, DTR_CBasePlayer_WaterMove_Pre,								DTR_CBasePlayer_WaterMove_Post,						"CBasePlayer::WaterMove",										"L4D2_OnWaterMove"); // Does not return water state. Use FL_INWATER instead.

	g_bCreatedDetours = true;
}

void CreateDetour(GameData hGameData, DHookCallback fCallback, DHookCallback fPostCallback, const char[] sName, const char[] sForward, bool useLast = false, bool forceOn = false)
{
	if( g_bCreatedDetours == false )
	{
		// Set forward names and indexes
		static int index;
		if( useLast ) index -= 1;

		g_aGameDataSigs.PushString(sName);
		g_aForwardNames.PushString(sForward);
		g_aUseLastIndex.Push(useLast);
		g_aForwardIndex.Push(index++);
		g_aForceDetours.Push(forceOn);

		// Setup detours
		if( !useLast )
		{
			Handle hDetour = DHookCreateFromConf(hGameData, sName);
			if( !hDetour ) LogError("Failed to load detour \"%s\" signature.", sName);

			g_aDetoursHooked.Push(0);			// Default disabled
			g_aDetourHandles.Push(hDetour);		// Store handle
		}
	}
	else
	{
		// Enable detours
		if( !useLast ) // When using the last index, the pre and post detours are already hooked. Pre is always hooked even when only using post, to avoid crashes from dhooks.
		{
			int index = g_iCurrentIndex++;
			int current = g_aDetoursHooked.Get(index);
			if( current < 0 ) // if( current == -1 || current == -2 )
			{
				Handle hDetour = g_aDetourHandles.Get(index);
				if( hDetour != null )
				{
					if( current == -1 )
					{
						g_aDetoursHooked.Set(index, 1);
						#if DEBUG
						PrintToServer("Enabling detour %d %s", index, sName);
						#endif

						if( fCallback != INVALID_FUNCTION && !DHookEnableDetour(hDetour, false, fCallback) ) LogError("Failed to detour pre \"%s\".", sName);
						if( fPostCallback != INVALID_FUNCTION && !DHookEnableDetour(hDetour, true, fPostCallback) ) LogError("Failed to detour post \"%s\".", sName);
					} else {
						g_aDetoursHooked.Set(index, 0);
						#if DEBUG
						PrintToServer("Disabling detour %d %s", index, sName);
						#endif

						if( fCallback != INVALID_FUNCTION && !DHookDisableDetour(hDetour, false, fCallback) ) LogError("Failed to disable detour pre \"%s\".", sName);
						if( fPostCallback != INVALID_FUNCTION && !DHookDisableDetour(hDetour, true, fPostCallback) ) LogError("Failed to disable detour post \"%s\".", sName);
					}
				}
			}
		}
	}
}

// Loop through plugins, check which forwards are being used, then hook
void CheckRequiredDetours(int client = 0)
{
	#if DEBUG || !DETOUR_ALL
	char filename[PLATFORM_MAX_PATH];
	#endif

	bool useLast;
	char signatures[MAX_FWD_LEN];
	char forwards[MAX_FWD_LEN];
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
			// PrintToServer("i %d", i);
				// Only if not enabling all detours

				// Force detour on?
				if( g_aForceDetours.Get(i) )
				{
					// Get forward name
					g_aForwardNames.GetString(i, forwards, sizeof(forwards));
					g_aGameDataSigs.GetString(i, signatures, sizeof(signatures));

					count++;

					if( !useLast )
						aHand.Push(index);

					#if DEBUG
					if( client == 0 )
					{
						StopProfiling(g_vProf);
						g_fProf += GetProfilerTime(g_vProf);
						PrintToServer("%2d %36s> %32s (%s)", count, "FORCED DETOUR", forwards, signatures[6]);
						StartProfiling(g_vProf);
					}
					#endif

					if( client > 0 )
					{
						ReplyToCommand(client - 1, "%2d %36s> %32s (%s)", count, "FORCED DETOUR", forwards, signatures[6]);
					}
				}
				// Check if used
				else
				{
					// Get forward name
					g_aForwardNames.GetString(i, forwards, sizeof(forwards));

					#if !DETOUR_ALL
					if( GetFunctionByName(hPlug, forwards) != INVALID_FUNCTION )
					#else
					if( aHand.FindValue(index) == -1 )
					#endif
					{
						count++;

						if( !useLast )
							aHand.Push(index);

						#if DEBUG
						if( client == 0 )
						{
							#if DETOUR_ALL
							filename = "THIS_PLUGIN_TEST";
							#else
							GetPluginFilename(hPlug, filename, sizeof(filename));
							#endif

							g_aGameDataSigs.GetString(i, signatures, sizeof(signatures));

							StopProfiling(g_vProf);
							g_fProf += GetProfilerTime(g_vProf);
							PrintToServer("%2d %36s> %32s (%s)", count, filename, forwards, signatures[6]);
							StartProfiling(g_vProf);
						}
						#endif

						if( client > 0 )
						{
							g_aGameDataSigs.GetString(i, signatures, sizeof(signatures));

							#if DETOUR_ALL
							ReplyToCommand(client - 1, "%2d %36s> %32s (%s)", count, "THIS_PLUGIN_TEST", forwards, signatures[6]);
							#else
							GetPluginFilename(hPlug, filename, sizeof(filename));
							ReplyToCommand(client - 1, "%2d %36s> %32s (%s)", count, filename, forwards, signatures[6]);
							#endif
						}
					}
				}
			}
		}
	}

	// Iterate detours - enable and disable as required
	int len = g_aDetoursHooked.Length;
	for( int i = 0; i < len; i++ )
	{
		// ToDo: When using extra-api.ext - increment or decrement and only enable/disable when required
		int current = g_aDetoursHooked.Get(i);

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
//										MAP START - INITIALIZE - (LOAD GAMEDATA, DETOURS etc)
// ====================================================================================================
public void OnMapStart()
{
	g_bRoundEnded = false;



	// Putting this here so g_pGameRules is valid. Changes for each map.
	LoadGameDataRules(g_hGameData);



	// Benchmark
	#if DEBUG
	g_vProf = CreateProfiler();
	g_fProf = 0.0;
	StartProfiling(g_vProf);
	#endif

	// Enable or Disable detours as required.
	CheckRequiredDetours();

	#if DEBUG
	StopProfiling(g_vProf);
	g_fProf += GetProfilerTime(g_vProf);
	PrintToServer("");
	PrintToServer("Dynamic Detours finished in %f seconds.", g_fProf);
	PrintToServer("");
	delete g_vProf;
	#endif



	// Because reload command calls this function. We only want these loaded on actual map start.
	if( !g_bMapStarted )
	{
		g_bMapStarted = true;

		GetGameMode(); // Get current game mode

		// Precache Models, prevent crashing when spawning with SpawnSpecial()
		for( int i = 0; i < sizeof(g_sModels1); i++ )
			PrecacheModel(g_sModels1[i]);

		if( g_bLeft4Dead2 )
		{
			for( int i = 0; i < sizeof(g_sModels2); i++ )
				PrecacheModel(g_sModels2[i]);
		}

		PrecacheModel(SPRITE_GLOW, true); // Dissolver



		// Director Variables initialized before the plugin is able to hook.
		// Extension was able to process these and fire the forwards accordingly.
		// Some plugins want to overwrite these values from the forward. Please report which ones are required.
		static bool bDirectorVars;
		if( g_bLeft4Dead2 && bDirectorVars == false )
		{
			bDirectorVars = true;

			// Variable + default value you're passing, which may be used if the director var is not set. Probably uses cvar instead. Unknown.
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "MaxSpecials",			1); // This doesn't appear to work in the finale. At least for some maps.

			// These only appear to work in the Finale, or maybe some specific maps. Unknown.
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "SmokerLimit",			1);
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "BoomerLimit",			1);
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "HunterLimit",			1);
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "SpitterLimit",		1);
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "JockeyLimit",			1);
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "ChargerLimit",		1);
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "TankLimit",			1);
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "DominatorLimit",		1);
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "WitchLimit",			1);
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "CommonLimit",			1);

			// Challenge mode required?
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "cm_MaxSpecials",		1);
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "cm_BaseSpecialLimit",	1);
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "cm_SmokerLimit",		1);
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "cm_BoomerLimit",		1);
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "cm_HunterLimit",		1);
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "cm_SpitterLimit",		1);
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "cm_JockeyLimit",		1);
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "cm_ChargerLimit",		1);
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "cm_TankLimit",		1);
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "cm_DominatorLimit",	1);
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "cm_WitchLimit",		1);
			SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "cm_CommonLimit",		1);

			// These also exist, required?
			// SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "TotalSmokers",			1);
			// SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "TotalBoomers",			1);
			// SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "TotalHunters",			1);
			// SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "TotalSpitter",			1);
			// SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "TotalJockey",			1);
			// SDKCall(g_hSDK_CDirector_GetScriptValueInt, g_pDirector, "TotalCharger",			1);
		}

		// Melee weapon IDs - They can change when switching map depending on what melee weapons are enabled
		if( g_bLeft4Dead2 )
		{
			delete g_aMeleePtrs;
			delete g_aMeleeIDs;

			g_aMeleePtrs = new ArrayList(2);
			g_aMeleeIDs = new StringMap();

			int iTable = FindStringTable("meleeweapons");
			if( iTable == INVALID_STRING_TABLE ) // Default to known IDs
			{
				g_aMeleeIDs.SetValue("fireaxe",								0);
				g_aMeleeIDs.SetValue("frying_pan",							1);
				g_aMeleeIDs.SetValue("machete",								2);
				g_aMeleeIDs.SetValue("baseball_bat",						3);
				g_aMeleeIDs.SetValue("crowbar",								4);
				g_aMeleeIDs.SetValue("cricket_bat",							5);
				g_aMeleeIDs.SetValue("tonfa",								6);
				g_aMeleeIDs.SetValue("katana",								7);
				g_aMeleeIDs.SetValue("electric_guitar",						8);
				g_aMeleeIDs.SetValue("knife",								9);
				g_aMeleeIDs.SetValue("golfclub",							10);
				g_aMeleeIDs.SetValue("pitchfork",							11);
				g_aMeleeIDs.SetValue("shovel",								12);
			} else {
				// Get actual IDs
				int iNum = GetStringTableNumStrings(iTable);
				char sName[PLATFORM_MAX_PATH];

				for( int i = 0; i < iNum; i++ )
				{
					ReadStringTable(iTable, i, sName, sizeof(sName));
					g_aMeleeIDs.SetValue(sName, i);
				}
			}
		}
	}
}



// ====================================================================================================
//										LOAD GAMEDATA - (create natives, load offsets etc)
// ====================================================================================================
void LoadGameDataRules(GameData hGameData)
{
	// Map changes can modify the address
	g_pGameRules = hGameData.GetAddress("GameRules");
	ValidateAddress(g_pGameRules, "g_pGameRules", true);
}

void LoadGameData()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", g_bLeft4Dead2 ? GAMEDATA_2 : GAMEDATA_1);
	if( FileExists(sPath) == false ) SetFailState("\n==========\nMissing required file: \"%s\".\nRead installation instructions again.\n==========", sPath);

	GameData hGameData = new GameData(g_bLeft4Dead2 ? GAMEDATA_2 : GAMEDATA_1);
	if( hGameData == null ) SetFailState("Failed to load \"%s.txt\" gamedata.", g_bLeft4Dead2 ? GAMEDATA_2 : GAMEDATA_1);

	#if DEBUG
	PrintToServer("");
	PrintToServer("Left4DHooks loading gamedata: %s", g_bLeft4Dead2 ? GAMEDATA_2 : GAMEDATA_1);
	PrintToServer("");
	#endif

	g_bLinuxOS = hGameData.GetOffset("OS") == 1;



	// ====================================================================================================
	//									SDK CALLS
	// ====================================================================================================
	// INTERNAL
	StartPrepSDKCall(SDKCall_Static);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "GetWeaponInfo") == false )
	{
		LogError("Failed to find signature: GetWeaponInfo");
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_GetWeaponInfo = EndPrepSDKCall();
		if( g_hSDK_GetWeaponInfo == null )
			LogError("Failed to create SDKCall: GetWeaponInfo");
	}

	StartPrepSDKCall(SDKCall_Static);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorGameRules::GetMissionInfo") == false )
	{
		LogError("Failed to find signature: CTerrorGameRules::GetMissionInfo");
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CTerrorGameRules_GetMissionInfo = EndPrepSDKCall();
		if( g_hSDK_CTerrorGameRules_GetMissionInfo == null )
			LogError("Failed to create SDKCall: CTerrorGameRules::GetMissionInfo");
	}



	// =========================
	// SILVERS NATIVES
	// =========================
	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CTerrorPlayer::GetLastKnownArea") == false )
	{
		LogError("Failed to find signature: CTerrorPlayer::GetLastKnownArea");
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CTerrorPlayer_GetLastKnownArea = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_GetLastKnownArea == null )
			LogError("Failed to create SDKCall: CTerrorPlayer::GetLastKnownArea");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CTerrorPlayer::Deafen") == false )
	{
		LogError("Failed to find signature: CTerrorPlayer::Deafen");
	} else {
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		g_hSDK_CTerrorPlayer_Deafen = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_Deafen == null )
			LogError("Failed to create SDKCall: CTerrorPlayer::Deafen");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "Music::Play") == false )
	{
		LogError("Failed to find signature: Music::Play");
	} else {
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		g_hSDK_Music_Play = EndPrepSDKCall();
		if( g_hSDK_Music_Play == null )
			LogError("Failed to create SDKCall: Music::Play");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "Music::StopPlaying") == false )
	{
		LogError("Failed to find signature: Music::StopPlaying");
	} else {
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		g_hSDK_Music_StopPlaying = EndPrepSDKCall();
		if( g_hSDK_Music_StopPlaying == null )
			LogError("Failed to create SDKCall: Music::StopPlaying");
	}

	StartPrepSDKCall(SDKCall_Static);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CEntityDissolve::Create") == false )
	{
		LogError("Failed to find signature: CEntityDissolve::Create");
	} else {
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDK_CEntityDissolve_Create = EndPrepSDKCall();
		if( g_hSDK_CEntityDissolve_Create == null )
			LogError("Failed to create SDKCall: CEntityDissolve::Create");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::OnITExpired") == false )
	{
		LogError("Failed to find signature: CTerrorPlayer::OnITExpired");
	} else {
		g_hSDK_CTerrorPlayer_OnITExpired = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_OnITExpired == null )
			LogError("Failed to create SDKCall: CTerrorPlayer::OnITExpired");
	}

	StartPrepSDKCall(SDKCall_Entity);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CBaseEntity::ApplyLocalAngularVelocityImpulse") == false )
	{
		LogError("Failed to find signature: CBaseEntity::ApplyLocalAngularVelocityImpulse");
	} else {
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		g_hSDK_CBaseEntity_ApplyLocalAngularVelocityImpulse = EndPrepSDKCall();
		if( g_hSDK_CBaseEntity_ApplyLocalAngularVelocityImpulse == null )
			LogError("Failed to create SDKCall: CBaseEntity::ApplyLocalAngularVelocityImpulse");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "ZombieManager::GetRandomPZSpawnPosition") == false )
	{
		LogError("Failed to find signature: ZombieManager::GetRandomPZSpawnPosition");
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // zombieClass
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // Attempts
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWWORLD); // Client
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK); // Vector return
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_ZombieManager_GetRandomPZSpawnPosition = EndPrepSDKCall();
		if( g_hSDK_ZombieManager_GetRandomPZSpawnPosition == null )
			LogError("Failed to create SDKCall: ZombieManager::GetRandomPZSpawnPosition");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CNavMesh::GetNearestNavArea") == false )
	{
		LogError("Failed to find signature: CNavMesh::GetNearestNavArea");
	} else {
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CNavMesh_GetNearestNavArea = EndPrepSDKCall();
		if( g_hSDK_CNavMesh_GetNearestNavArea == null )
			LogError("Failed to create SDKCall: CNavMesh::GetNearestNavArea");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "TerrorNavArea::FindRandomSpot") == false )
	{
		LogError("Failed to find signature: TerrorNavArea::FindRandomSpot");
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Vector, SDKPass_ByValue);
		g_hSDK_TerrorNavArea_FindRandomSpot = EndPrepSDKCall();
		if( g_hSDK_TerrorNavArea_FindRandomSpot == null )
			LogError("Failed to create SDKCall: TerrorNavArea::FindRandomSpot");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::HasAnySurvivorLeftSafeArea") == false )
	{
		LogError("Failed to find signature: CDirector::HasAnySurvivorLeftSafeArea");
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_CDirector_HasAnySurvivorLeftSafeArea = EndPrepSDKCall();
		if( g_hSDK_CDirector_HasAnySurvivorLeftSafeArea == null )
			LogError("Failed to create SDKCall: CDirector::HasAnySurvivorLeftSafeArea");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::IsAnySurvivorInStartArea") == false )
	{
		LogError("Failed to find signature: CDirector::IsAnySurvivorInStartArea");
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_CDirector_IsAnySurvivorInStartArea = EndPrepSDKCall();
		if( g_hSDK_CDirector_IsAnySurvivorInStartArea == null )
			LogError("Failed to create SDKCall: CDirector::IsAnySurvivorInStartArea");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::IsAnySurvivorInExitCheckpoint") == false )
	{
		LogError("Failed to find signature: CDirector::IsAnySurvivorInExitCheckpoint");
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_CDirector_IsAnySurvivorInExitCheckpoint = EndPrepSDKCall();
		if( g_hSDK_CDirector_IsAnySurvivorInExitCheckpoint == null )
			LogError("Failed to create SDKCall: CDirector::IsAnySurvivorInExitCheckpoint");
	}

	StartPrepSDKCall(SDKCall_Static);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorGameRules::HasPlayerControlledZombies") == false )
	{
		LogError("Failed to find signature: CTerrorGameRules::HasPlayerControlledZombies");
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_CTerrorGameRules_HasPlayerControlledZombies = EndPrepSDKCall();
		if( g_hSDK_CTerrorGameRules_HasPlayerControlledZombies == null )
			LogError("Failed to create SDKCall: CTerrorGameRules::HasPlayerControlledZombies");
	}

	if( g_bLeft4Dead2 )
	{
		StartPrepSDKCall(SDKCall_GameRules);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorGameRules::GetSurvivorSet") == false )
		{
			LogError("Failed to find signature: CTerrorGameRules::GetSurvivorSet");
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_CTerrorGameRules_GetSurvivorSet = EndPrepSDKCall();
			if( g_hSDK_CTerrorGameRules_GetSurvivorSet == null )
				LogError("Failed to create SDKCall: CTerrorGameRules::GetSurvivorSet");
		}
	}

	StartPrepSDKCall(SDKCall_Static);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CPipeBombProjectile::Create") == false )
	{
		LogError("Failed to find signature: CPipeBombProjectile::Create");
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
			LogError("Failed to create SDKCall: CPipeBombProjectile::Create");
	}



	// =========================
	// DYNAMIC SIG SCANS
	// =========================

	// Automatically generate addresses from strings inside the custom temp gamedata used for some natives
	if( !g_bLinuxOS )
	{
		// Search game memory for specific strings
		#define MAX_HOOKS 3
		int iMaxHooks = g_bLeft4Dead2 ? 3 : 1;
		int offsetPush;

		Address patchAddr;
		Address patches[MAX_HOOKS];

		patches[0] = GameConfGetAddress(hGameData, "Molotov_StrFind");
		if( g_bLeft4Dead2 )
		{
			patches[1] = GameConfGetAddress(hGameData, "VomitJar_StrFind");
			patches[2] = GameConfGetAddress(hGameData, "GrenadeLauncher_StrFind");
		}



		// Write custom gamedata with found addresses
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

				// First byte of projectile functions is \x55 || \x8B
				if( g_bLeft4Dead2 )
					sAddress = "\\x55";
				else
					sAddress = "\\x8B";

				// Offset to the "push" call
				switch( i )
				{
					case 0: offsetPush = hGameData.GetOffset("Molotov_OffsetPush");
					case 1: offsetPush = hGameData.GetOffset("VomitJar_OffsetPush");
					case 2: offsetPush = hGameData.GetOffset("GrenadeLauncher_OffsetPush");
				}

				// Add * bytes
				for( int x = 0; x < offsetPush; x++ )
				{
					StrCat(sAddress, sizeof(sAddress), "\\x2A");
				}

				// Add call X address
				StrCat(sAddress, sizeof(sAddress), "\\x68"); // Add "push" byte (this is found in the "Molotov", "VomitJar" and "GrenadeLauncher" functions only) - added to match better although not required
				StrCat(sAddress, sizeof(sAddress), sHexAddr);


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

				// Write wildcard for IDA
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



	GameData hTempGameData;
	
	if( !g_bLinuxOS )
	{
		hTempGameData = LoadGameConfigFile(GAMEDATA_TEMP);
		if( hTempGameData == null ) LogError("Failed to load \"%s.txt\" gamedata.", GAMEDATA_TEMP);
	}



	StartPrepSDKCall(SDKCall_Static);
	if( PrepSDKCall_SetFromConf(g_bLinuxOS ? hGameData : hTempGameData, SDKConf_Signature, g_bLinuxOS ? "CMolotovProjectile::Create" : "FindAddress_0") == false )
	{
		LogError("Failed to find signature: CMolotovProjectile::Create");
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
			LogError("Failed to create SDKCall: CMolotovProjectile::Create");
	}

	if( g_bLeft4Dead2 )
	{
		StartPrepSDKCall(SDKCall_Static);
		if( PrepSDKCall_SetFromConf(g_bLinuxOS ? hGameData : hTempGameData, SDKConf_Signature, g_bLinuxOS ? "VomitJarProjectile::Create" : "FindAddress_1") == false )
		{
			LogError("Failed to find signature: VomitJarProjectile::Create");
		} else {
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWWORLD);
			PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
			PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
			g_hSDK_VomitJarProjectile_Create = EndPrepSDKCall();
			if( g_hSDK_VomitJarProjectile_Create == null )
				LogError("Failed to create SDKCall: VomitJarProjectile::Create");
		}

		StartPrepSDKCall(SDKCall_Static);
		if( PrepSDKCall_SetFromConf(g_bLinuxOS ? hGameData : hTempGameData, SDKConf_Signature, g_bLinuxOS ? "CGrenadeLauncher_Projectile::Create" : "FindAddress_2") == false )
		{
			LogError("Failed to find signature: CGrenadeLauncher_Projectile::Create");
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
				LogError("Failed to create SDKCall: CGrenadeLauncher_Projectile::Create");
		}

		StartPrepSDKCall(SDKCall_Static);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CSpitterProjectile::Create") == false )
		{
			LogError("Failed to find signature: CSpitterProjectile::Create");
		} else {
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWWORLD);
			PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
			g_hSDK_CSpitterProjectile_Create = EndPrepSDKCall();
			if( g_hSDK_CSpitterProjectile_Create == null )
				LogError("Failed to create SDKCall: CSpitterProjectile::Create");
		}

		StartPrepSDKCall(SDKCall_GameRules);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorGameRules::HasConfigurableDifficultySetting") == false )
		{
			LogError("Failed to find signature: CTerrorGameRules::HasConfigurableDifficultySetting");
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_CTerrorGameRules_HasConfigurableDifficultySetting = EndPrepSDKCall();
			if( g_hSDK_CTerrorGameRules_HasConfigurableDifficultySetting == null )
				LogError("Failed to create SDKCall: CTerrorGameRules::HasConfigurableDifficultySetting");
		}

		StartPrepSDKCall(SDKCall_Static);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "NavAreaTravelDistance") == false )
		{
			LogError("Failed to find signature: NavAreaTravelDistance");
		} else {
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_Plain);
			g_hSDK_NavAreaTravelDistance = EndPrepSDKCall();
			if( g_hSDK_NavAreaTravelDistance == null )
				LogError("Failed to create SDKCall: NavAreaTravelDistance");
		}

		StartPrepSDKCall(SDKCall_Player);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::OnAdrenalineUsed") == false )
		{
			LogError("Failed to find signature: CTerrorPlayer::OnAdrenalineUsed");
		} else {
			PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
			g_hSDK_CTerrorPlayer_OnAdrenalineUsed = EndPrepSDKCall();
			if( g_hSDK_CTerrorPlayer_OnAdrenalineUsed == null )
				LogError("Failed to create SDKCall: CTerrorPlayer::OnAdrenalineUsed");
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
			LogError("Failed to find signature: CDirector::ForceNextStage::Address");
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_CDirector_ForceNextStage = EndPrepSDKCall();
			if( g_hSDK_CDirector_ForceNextStage == null )
				LogError("Failed to create SDKCall: CDirector::ForceNextStage::Address");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::IsTankInPlay") == false )
		{
			LogError("Failed to find signature: CDirector::IsTankInPlay");
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
			g_hSDK_CDirector_IsTankInPlay = EndPrepSDKCall();
			if( g_hSDK_CDirector_IsTankInPlay == null )
				LogError("Failed to create SDKCall: CDirector::IsTankInPlay");
		}

		StartPrepSDKCall(SDKCall_Player);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "SurvivorBot::IsReachable") == false )
		{
			LogError("Failed to find signature: SurvivorBot::IsReachable");
		} else {
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
			g_hSDK_SurvivorBot_IsReachable = EndPrepSDKCall();
			if( g_hSDK_SurvivorBot_IsReachable == null )
				LogError("Failed to create SDKCall: SurvivorBot::IsReachable");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::GetFurthestSurvivorFlow") == false )
		{
			LogError("Failed to find signature: CDirector::GetFurthestSurvivorFlow");
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_Plain);
			g_hSDK_CDirector_GetFurthestSurvivorFlow = EndPrepSDKCall();
			if( g_hSDK_CDirector_GetFurthestSurvivorFlow == null )
				LogError("Failed to create SDKCall: CDirector::GetFurthestSurvivorFlow");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::GetScriptValueInt") == false )
		{
			LogError("Failed to find signature: CDirector::GetScriptValueInt");
		} else {
			PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_CDirector_GetScriptValueInt = EndPrepSDKCall();
			if( g_hSDK_CDirector_GetScriptValueInt == null )
					LogError("Failed to create SDKCall: CDirector::GetScriptValueInt");
		}

		/*
		// Only returns default value provided.
		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::GetScriptValueFloat") == false )
		{
			LogError("Failed to find signature: CDirector::GetScriptValueFloat");
		} else {
			PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
			PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
			PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_Plain);
			g_hSDK_CDirector_GetScriptValueFloat = EndPrepSDKCall();
			if( g_hSDK_CDirector_GetScriptValueFloat == null )
					LogError("Failed to create SDKCall: CDirector::GetScriptValueFloat");
		}

		// Not implemented, request if really required.
		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::GetScriptValueString") == false )
		{
			LogError("Failed to find signature: CDirector::GetScriptValueString");
		} else {
			PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
			PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
			PrepSDKCall_SetReturnInfo(SDKType_String, SDKPass_Pointer);
			g_hSDK_CDirector_GetScriptValueString = EndPrepSDKCall();
			if( g_hSDK_CDirector_GetScriptValueString == null )
					LogError("Failed to create SDKCall: CDirector::GetScriptValueString");
		}
		*/
	}



	// =========================
	// MAIN - left4downtown.inc
	// =========================
	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::RestartScenarioFromVote") == false )
	{
		LogError("Failed to find signature: CDirector::RestartScenarioFromVote");
	} else {
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CDirector_RestartScenarioFromVote = EndPrepSDKCall();
		if( g_hSDK_CDirector_RestartScenarioFromVote == null )
			LogError("Failed to create SDKCall: CDirector::RestartScenarioFromVote");
	}

	StartPrepSDKCall(SDKCall_GameRules);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorGameRules::GetTeamScore") == false )
	{
		LogError("Failed to find signature: CTerrorGameRules::GetTeamScore");
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CTerrorGameRules_GetTeamScore = EndPrepSDKCall();
		if( g_hSDK_CTerrorGameRules_GetTeamScore == null )
			LogError("Failed to create SDKCall: CTerrorGameRules::GetTeamScore");
	}

	if( g_bLeft4Dead2 )
	{
		StartPrepSDKCall(SDKCall_Raw);
	} else {
		StartPrepSDKCall(SDKCall_Static);
	}
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::IsFirstMapInScenario") == false )
	{
		LogError("Failed to find signature: CDirector::IsFirstMapInScenario");
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
			LogError("Failed to create SDKCall: IsFirstMapInScenario");
	}

	StartPrepSDKCall(SDKCall_GameRules);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorGameRules::IsMissionFinalMap") == false )
	{
		LogError("Failed to find signature: CTerrorGameRules::IsMissionFinalMap");
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_CTerrorGameRules_IsMissionFinalMap = EndPrepSDKCall();
		if( g_hSDK_CTerrorGameRules_IsMissionFinalMap == null )
			LogError("Failed to create SDKCall: CTerrorGameRules::IsMissionFinalMap");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "KeyValues::GetString") == false )
	{
		LogError("Could not load the \"KeyValues::GetString\" gamedata signature.");
	} else {
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		PrepSDKCall_SetReturnInfo(SDKType_String, SDKPass_Pointer);
		g_hSDK_KeyValues_GetString = EndPrepSDKCall();
		if( g_hSDK_KeyValues_GetString == null )
			LogError("Could not prep the \"KeyValues::GetString\" function.");
	}

	if( g_bLeft4Dead2 )
	{
		StartPrepSDKCall(SDKCall_GameRules);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorGameRules::GetNumChaptersForMissionAndMode") == false )
		{
			LogError("Could not load the \"CTerrorGameRules::GetNumChaptersForMissionAndMode\" gamedata signature.");
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_CTerrorGameRules_GetNumChaptersForMissionAndMode = EndPrepSDKCall();
			if( g_hSDK_CTerrorGameRules_GetNumChaptersForMissionAndMode == null )
				LogError("Could not prep the \"CTerrorGameRules::GetNumChaptersForMissionAndMode\" function.");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::GetGameModeBase") == false )
		{
			LogError("Could not load the \"CDirector::GetGameModeBase\" gamedata signature.");
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_String, SDKPass_Pointer);
			g_hSDK_CDirector_GetGameModeBase = EndPrepSDKCall();
			if( g_hSDK_CDirector_GetGameModeBase == null )
				LogError("Could not prep the \"CDirector::GetGameModeBase\" function.");
		}

		StartPrepSDKCall(SDKCall_GameRules);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorGameRules::IsRealismMode") == false )
		{
			LogError("Could not load the \"CTerrorGameRules::IsRealismMode\" gamedata signature.");
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_CTerrorGameRules_IsRealismMode = EndPrepSDKCall();
			if( g_hSDK_CTerrorGameRules_IsRealismMode == null )
				LogError("Could not prep the \"CTerrorGameRules::IsRealismMode\" function.");
		}

		StartPrepSDKCall(SDKCall_GameRules);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorGameRules::IsGenericCooperativeMode") == false )
		{
			LogError("Could not load the \"CTerrorGameRules::IsGenericCooperativeMode\" gamedata signature.");
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_CTerrorGameRules_IsGenericCooperativeMode = EndPrepSDKCall();
			if( g_hSDK_CTerrorGameRules_IsGenericCooperativeMode == null )
				LogError("Could not prep the \"CTerrorGameRules::IsGenericCooperativeMode\" function.");
		}
	}

	StartPrepSDKCall(SDKCall_GameRules);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CGameRulesProxy::NotifyNetworkStateChanged") == false )
	{
		LogError("Failed to find signature: CGameRulesProxy::NotifyNetworkStateChanged");
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CGameRulesProxy_NotifyNetworkStateChanged = EndPrepSDKCall();
		if( g_hSDK_CGameRulesProxy_NotifyNetworkStateChanged == null )
			LogError("Failed to create SDKCall: CGameRulesProxy::NotifyNetworkStateChanged");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::OnStaggered") == false )
	{
		LogError("Failed to find signature: StaggerPlayer");
	} else {
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CTerrorPlayer_OnStaggered = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_OnStaggered == null )
			LogError("Failed to create SDKCall: CTerrorPlayer::OnStaggered");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirectorScriptedEventManager::SendInRescueVehicle") == false )
	{
		LogError("Failed to find signature: CDirectorScriptedEventManager::SendInRescueVehicle");
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_CDirectorScriptedEventManager_SendInRescueVehicle = EndPrepSDKCall();
		if( g_hSDK_CDirectorScriptedEventManager_SendInRescueVehicle == null )
			LogError("Failed to create SDKCall: CDirectorScriptedEventManager::SendInRescueVehicle");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "ZombieManager::ReplaceTank") == false )
	{
		LogError("Failed to find signature: ZombieManager::ReplaceTank");
	} else {
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_ZombieManager_ReplaceTank = EndPrepSDKCall();
		if( g_hSDK_ZombieManager_ReplaceTank == null )
			LogError("Failed to create SDKCall: ZombieManager::ReplaceTank");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "ZombieManager::SpawnTank") == false )
	{
		LogError("Failed to find signature: ZombieManager::SpawnTank");
	} else {
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
		PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDK_ZombieManager_SpawnTank = EndPrepSDKCall();
		if( g_hSDK_ZombieManager_SpawnTank == null )
			LogError("Failed to create SDKCall: ZombieManager::SpawnTank");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "ZombieManager::SpawnWitch") == false )
	{
		LogError("Failed to find signature: ZombieManager::SpawnWitch");
	} else {
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
		PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDK_ZombieManager_SpawnWitch = EndPrepSDKCall();
		if( g_hSDK_ZombieManager_SpawnWitch == null )
			LogError("Failed to create SDKCall: ZombieManager::SpawnWitch");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::IsFinaleEscapeInProgress") == false )
	{
		LogError("Failed to find signature: CDirector::IsFinaleEscapeInProgress");
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_CDirector_IsFinaleEscapeInProgress = EndPrepSDKCall();
		if( g_hSDK_CDirector_IsFinaleEscapeInProgress == null )
			LogError("Failed to create SDKCall: CDirector::IsFinaleEscapeInProgress");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "SurvivorBot::SetHumanSpectator") == false )
	{
		LogError("Failed to find signature: SurvivorBot::SetHumanSpectator");
	} else {
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_SurvivorBot_SetHumanSpectator = EndPrepSDKCall();
		if( g_hSDK_SurvivorBot_SetHumanSpectator == null )
			LogError("Failed to create SDKCall: SurvivorBot::SetHumanSpectator");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::TakeOverBot") == false )
	{
		LogError("Failed to find signature: CTerrorPlayer::TakeOverBot");
	} else {
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_CTerrorPlayer_TakeOverBot = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_TakeOverBot == null )
			LogError("Failed to create SDKCall: CTerrorPlayer::TakeOverBot");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::CanBecomeGhost") == false )
	{
		LogError("Failed to find signature: CTerrorPlayer::CanBecomeGhost");
	} else {
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_CTerrorPlayer_CanBecomeGhost = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_CanBecomeGhost == null )
			LogError("Failed to create SDKCall: CTerrorPlayer::CanBecomeGhost");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::TryOfferingTankBot") == false )
	{
		LogError("Failed to find signature: CDirector::TryOfferingTankBot");
	} else {
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CDirector_TryOfferingTankBot = EndPrepSDKCall();
		if( g_hSDK_CDirector_TryOfferingTankBot == null )
			LogError("Failed to create SDKCall: CDirector::TryOfferingTankBot");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CNavMesh::GetNavArea") == false )
	{
		LogError("Failed to find signature: CNavMesh::GetNavArea");
	} else {
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CNavMesh_GetNavArea = EndPrepSDKCall();
		if( g_hSDK_CNavMesh_GetNavArea == null )
			LogError("Failed to create SDKCall: CNavMesh::GetNavArea");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::GetFlowDistance") == false )
	{
		LogError("Failed to find signature: CTerrorPlayer::GetFlowDistance");
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_Plain);
		g_hSDK_CTerrorPlayer_GetFlowDistance = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_GetFlowDistance == null )
			LogError("Failed to create SDKCall: CTerrorPlayer::GetFlowDistance");
	}

	StartPrepSDKCall(SDKCall_Entity);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CBaseGrenade::Detonate") == false )
	{
		LogError("Failed to find signature: CBaseGrenade::Detonate");
	} else {
		g_hSDK_CBaseGrenade_Detonate = EndPrepSDKCall();
		if( g_hSDK_CBaseGrenade_Detonate == null )
			LogError("Failed to create SDKCall: CBaseGrenade::Detonate");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CTerrorPlayer::DoAnimationEvent") == false )
	{
		LogError("Failed to find signature: CTerrorPlayer::DoAnimationEvent");
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CTerrorPlayer_DoAnimationEvent = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_DoAnimationEvent == null )
			LogError("Failed to create SDKCall: CTerrorPlayer::DoAnimationEvent");
	}

	if( !g_bLeft4Dead2 )
	{
		StartPrepSDKCall(SDKCall_GameRules);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorGameRules::RecomputeTeamScores") == false )
		{
			LogError("Failed to find signature: CTerrorGameRules::RecomputeTeamScores");
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_CTerrorGameRules_RecomputeTeamScores = EndPrepSDKCall();
			if( g_hSDK_CTerrorGameRules_RecomputeTeamScores == null )
				LogError("Failed to create SDKCall: CTerrorGameRules::RecomputeTeamScores");
		}
	}



	if( g_bLeft4Dead2 )
	{
		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CMeleeWeaponInfoStore::GetMeleeWeaponInfo") == false )
		{
			LogError("Failed to find signature: CMeleeWeaponInfoStore::GetMeleeWeaponInfo");
		} else {
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_CMeleeWeaponInfoStore_GetMeleeWeaponInfo = EndPrepSDKCall();
			if( g_hSDK_CMeleeWeaponInfoStore_GetMeleeWeaponInfo == null )
				LogError("Failed to create SDKCall: CMeleeWeaponInfoStore::GetMeleeWeaponInfo");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::ResetMobTimer") == false )
		{
			LogError("Failed to find signature: CDirector::ResetMobTimer");
		} else {
			g_hSDK_CDirector_ResetMobTimer = EndPrepSDKCall();
			if( g_hSDK_CDirector_ResetMobTimer == null )
				LogError("Failed to create SDKCall: CDirector::ResetMobTimer");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirectorScriptedEventManager::ChangeFinaleStage") == false )
		{
			LogError("Failed to find signature: CDirectorScriptedEventManager::ChangeFinaleStage");
		} else {
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_CDirectorScriptedEventManager_ChangeFinaleStage = EndPrepSDKCall();
			if( g_hSDK_CDirectorScriptedEventManager_ChangeFinaleStage == null )
				LogError("Failed to create SDKCall: CDirectorScriptedEventManager::ChangeFinaleStage");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "ZombieManager::SpawnSpecial") == false )
		{
			LogError("Failed to find signature: ZombieManager::SpawnSpecial");
		} else {
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
			PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
			g_hSDK_ZombieManager_SpawnSpecial = EndPrepSDKCall();
			if( g_hSDK_ZombieManager_SpawnSpecial == null )
				LogError("Failed to create SDKCall: ZombieManager::SpawnSpecial");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "ZombieManager::SpawnWitchBride") == false )
		{
			LogError("Failed to find signature: ZombieManager::SpawnWitchBride");
		} else {
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
			PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
			g_hSDK_ZombieManager_SpawnWitchBride = EndPrepSDKCall();
			if( g_hSDK_ZombieManager_SpawnWitchBride == null )
				LogError("Failed to create SDKCall: ZombieManager::SpawnWitchBride");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::AreWanderersAllowed") == false )
		{
			LogError("Failed to find signature: CDirector::AreWanderersAllowed");
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
			g_hSDK_CDirector_AreWanderersAllowed = EndPrepSDKCall();
			if( g_hSDK_CDirector_AreWanderersAllowed == null )
				LogError("Failed to create SDKCall: CDirector::AreWanderersAllowed");
		}
	} else {
	// L4D1 only:
		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "ZombieManager::SpawnHunter") == false )
		{
			LogError("Failed to find signature: ZombieManager::SpawnHunter");
		} else {
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
			PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
			g_hSDK_ZombieManager_SpawnHunter = EndPrepSDKCall();
			if( g_hSDK_ZombieManager_SpawnHunter == null )
				LogError("Failed to create SDKCall: ZombieManager::SpawnHunter");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "ZombieManager::SpawnBoomer") == false )
		{
			LogError("Failed to find signature: ZombieManager::SpawnBoomer");
		} else {
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
			PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
			g_hSDK_ZombieManager_SpawnBoomer = EndPrepSDKCall();
			if( g_hSDK_ZombieManager_SpawnBoomer == null )
				LogError("Failed to create SDKCall: ZombieManager::SpawnBoomer");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "ZombieManager::SpawnSmoker") == false )
		{
			LogError("Failed to find signature: ZombieManager::SpawnSmoker");
		} else {
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
			PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
			g_hSDK_ZombieManager_SpawnSmoker = EndPrepSDKCall();
			if( g_hSDK_ZombieManager_SpawnSmoker == null )
				LogError("Failed to create SDKCall: ZombieManager::SpawnSmoker");
		}
	}



	// =========================
	// l4d2addresses.txt
	// =========================
	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::OnVomitedUpon") == false )
	{
		LogError("Failed to find signature: CTerrorPlayer::OnVomitedUpon");
	} else {
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		g_hSDK_CTerrorPlayer_OnVomitedUpon = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_OnVomitedUpon == null )
			LogError("Failed to create SDKCall: CTerrorPlayer::OnVomitedUpon");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::CancelStagger") == false )
	{
		LogError("Failed to find signature: CTerrorPlayer::CancelStagger");
	} else {
		g_hSDK_CTerrorPlayer_CancelStagger = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_CancelStagger == null )
			LogError("Failed to create SDKCall: CTerrorPlayer::CancelStagger");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::RoundRespawn") == false )
	{
		LogError("Failed to find signature: CTerrorPlayer::RoundRespawn");
	} else {
		g_hSDK_CTerrorPlayer_RoundRespawn = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_RoundRespawn == null )
			LogError("Failed to create SDKCall: CTerrorPlayer::RoundRespawn");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::CreateRescuableSurvivors") == false )
	{
		LogError("Failed to find signature: CDirector::CreateRescuableSurvivors");
	} else {
		g_hSDK_CDirector_CreateRescuableSurvivors = EndPrepSDKCall();
		if( g_hSDK_CDirector_CreateRescuableSurvivors == null )
			LogError("Failed to create SDKCall: CDirector::CreateRescuableSurvivors");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::OnRevived") == false )
	{
		LogError("Failed to find signature: CTerrorPlayer::OnRevived");
	} else {
		g_hSDK_CTerrorPlayer_OnRevived = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_OnRevived == null )
			LogError("Failed to create SDKCall: CTerrorPlayer::OnRevived");
	}

	StartPrepSDKCall(SDKCall_Static);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirectorTacticalServices::GetHighestFlowSurvivor") == false )
	{
		LogError("Failed to find signature: CDirectorTacticalServices::GetHighestFlowSurvivor");
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDK_CDirectorTacticalServices_GetHighestFlowSurvivor = EndPrepSDKCall();
		if( g_hSDK_CDirectorTacticalServices_GetHighestFlowSurvivor == null )
			LogError("Failed to create SDKCall: CDirectorTacticalServices::GetHighestFlowSurvivor");
	}

	StartPrepSDKCall(SDKCall_Entity);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "Infected::GetFlowDistance") == false )
	{
		LogError("Failed to find signature: Infected::GetFlowDistance");
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_Plain);
		g_hSDK_Infected_GetFlowDistance = EndPrepSDKCall();
		if( g_hSDK_Infected_GetFlowDistance == null )
			LogError("Failed to create SDKCall: Infected::GetFlowDistance");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::TakeOverZombieBot") == false )
	{
		LogError("Failed to find signature: CTerrorPlayer::TakeOverZombieBot");
	} else {
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		g_hSDK_CTerrorPlayer_TakeOverZombieBot = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_TakeOverZombieBot == null )
			LogError("Failed to create SDKCall: CTerrorPlayer::TakeOverZombieBot");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::ReplaceWithBot") == false )
	{
		LogError("Failed to find signature: CTerrorPlayer::ReplaceWithBot");
	} else {
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		g_hSDK_CTerrorPlayer_ReplaceWithBot = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_ReplaceWithBot == null )
			LogError("Failed to create SDKCall: CTerrorPlayer::ReplaceWithBot");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::CullZombie") == false )
	{
		LogError("Failed to find signature: CTerrorPlayer::CullZombie");
	} else {
		g_hSDK_CTerrorPlayer_CullZombie = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_CullZombie == null )
			LogError("Failed to create SDKCall: CTerrorPlayer::CullZombie");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::SetClass") == false )
	{
		LogError("Failed to find signature: CTerrorPlayer::SetClass");
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CTerrorPlayer_SetClass = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_SetClass == null )
			LogError("Failed to create SDKCall: CTerrorPlayer::SetClass");
	}

	StartPrepSDKCall(SDKCall_Static);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CBaseAbility::CreateForPlayer") == false )
	{
		LogError("Failed to find signature: CBaseAbility::CreateForPlayer");
	} else {
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDK_CBaseAbility_CreateForPlayer = EndPrepSDKCall();
		if( g_hSDK_CBaseAbility_CreateForPlayer == null )
			LogError("Failed to create SDKCall: CBaseAbility::CreateForPlayer");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::MaterializeFromGhost") == false )
	{
		LogError("Failed to find signature: CTerrorPlayer::MaterializeFromGhost");
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CTerrorPlayer_MaterializeFromGhost = EndPrepSDKCall();
		if( g_hSDK_CTerrorPlayer_MaterializeFromGhost == null )
			LogError("Failed to create SDKCall: CTerrorPlayer::MaterializeFromGhost");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::BecomeGhost") == false )
	{
		LogError("Failed to find signature: CTerrorPlayer::BecomeGhost");
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
			LogError("Failed to create SDKCall: CTerrorPlayer::BecomeGhost");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CCSPlayer::State_Transition") == false )
	{
		LogError("Failed to find signature: CCSPlayer::State_Transition");
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CCSPlayer_State_Transition = EndPrepSDKCall();
		if( g_hSDK_CCSPlayer_State_Transition == null )
			LogError("Failed to create SDKCall: CCSPlayer::State_Transition");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::RegisterForbiddenTarget") == false )
	{
		LogError("Failed to find signature: CDirector::RegisterForbiddenTarget");
	} else {
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_CDirector_RegisterForbiddenTarget = EndPrepSDKCall();
		if( g_hSDK_CDirector_RegisterForbiddenTarget == null )
			LogError("Failed to create SDKCall: CDirector::RegisterForbiddenTarget");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::UnregisterForbiddenTarget") == false )
	{
		LogError("Failed to find signature: CDirector::UnregisterForbiddenTarget");
	} else {
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDK_CDirector_UnregisterForbiddenTarget = EndPrepSDKCall();
		if( g_hSDK_CDirector_UnregisterForbiddenTarget == null )
			LogError("Failed to create SDKCall: CDirector::UnregisterForbiddenTarget");
	}



	if( g_bLeft4Dead2 )
	{
		StartPrepSDKCall(SDKCall_Player);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::OnHitByVomitJar") == false )
		{
			LogError("Failed to find signature: CTerrorPlayer::OnHitByVomitJar");
		} else {
			PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
			g_hSDK_CTerrorPlayer_OnHitByVomitJar = EndPrepSDKCall();
			if( g_hSDK_CTerrorPlayer_OnHitByVomitJar == null )
				LogError("Failed to create SDKCall: CTerrorPlayer::OnHitByVomitJar");
		}

		StartPrepSDKCall(SDKCall_Entity);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "Infected::OnHitByVomitJar") == false )
		{
			LogError("Failed to find signature: Infected::OnHitByVomitJar");
		} else {
			PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
			g_hSDK_Infected_OnHitByVomitJar = EndPrepSDKCall();
			if( g_hSDK_Infected_OnHitByVomitJar == null )
				LogError("Failed to create SDKCall: Infected::OnHitByVomitJar");
		}

		StartPrepSDKCall(SDKCall_Player);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::Fling") == false )
		{
			LogError("Failed to find signature: CTerrorPlayer::Fling");
		} else {
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
			PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
			g_hSDK_CTerrorPlayer_Fling = EndPrepSDKCall();
			if( g_hSDK_CTerrorPlayer_Fling == null )
				LogError("Failed to create SDKCall: CTerrorPlayer::Fling");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorGameRules::GetVersusCompletion") == false )
		{
			LogError("Failed to find signature: CTerrorGameRules::GetVersusCompletion");
		} else {
			PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_CTerrorGameRules_GetVersusCompletion = EndPrepSDKCall();
			if( g_hSDK_CTerrorGameRules_GetVersusCompletion == null )
				LogError("Failed to create SDKCall: CTerrorGameRules::GetVersusCompletion");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::SwapTeams") == false )
		{
			LogError("Failed to find signature: CDirector::SwapTeams");
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_CDirector_SwapTeams = EndPrepSDKCall();
			if( g_hSDK_CDirector_SwapTeams == null )
				LogError("Failed to create SDKCall: CDirector::SwapTeams");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::AreTeamsFlipped") == false )
		{
			LogError("Failed to find signature: CDirector::AreTeamsFlipped");
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_CDirector_AreTeamsFlipped = EndPrepSDKCall();
			if( g_hSDK_CDirector_AreTeamsFlipped == null )
				LogError("Failed to create SDKCall: CDirector::AreTeamsFlipped");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::StartRematchVote") == false )
		{
			LogError("Failed to find signature: CDirector::StartRematchVote");
		} else {
			g_hSDK_CDirector_StartRematchVote = EndPrepSDKCall();
			if( g_hSDK_CDirector_StartRematchVote == null )
				LogError("Failed to create SDKCall: CDirector::StartRematchVote");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::FullRestart") == false )
		{
			LogError("Failed to find signature: CDirector::FullRestart");
		} else {
			g_hSDK_CDirector_FullRestart = EndPrepSDKCall();
			if( g_hSDK_CDirector_FullRestart == null )
				LogError("Failed to create SDKCall: CDirector::FullRestart");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirectorVersusMode::HideScoreboardNonVirtual") == false )
		{
			LogError("Failed to find signature: CDirectorVersusMode::HideScoreboardNonVirtual");
		} else {
			g_hSDK_CDirectorVersusMode_HideScoreboardNonVirtual = EndPrepSDKCall();
			if( g_hSDK_CDirectorVersusMode_HideScoreboardNonVirtual == null )
				LogError("Failed to create SDKCall: CDirectorVersusMode::HideScoreboardNonVirtual");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirectorScavengeMode::HideScoreboardNonVirtual") == false )
		{
			LogError("Failed to find signature: CDirectorScavengeMode::HideScoreboardNonVirtual");
		} else {
			g_hSDK_CDirectorScavengeMode_HideScoreboardNonVirtual = EndPrepSDKCall();
			if( g_hSDK_CDirectorScavengeMode_HideScoreboardNonVirtual == null )
				LogError("Failed to create SDKCall: CDirectorScavengeMode::HideScoreboardNonVirtual");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::HideScoreboard") == false )
		{
			LogError("Failed to find signature: CDirectorHideScoreboard");
		} else {
			g_hSDK_CDirector_HideScoreboard = EndPrepSDKCall();
			if( g_hSDK_CDirector_HideScoreboard == null )
				LogError("Failed to create SDKCall: CDirector::HideScoreboard");
		}
	}

	StartPrepSDKCall(SDKCall_Static);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CBaseServer::SetReservationCookie") == false )
	{
		LogError("Failed to find signature: CBaseServer::SetReservationCookie");
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		g_hSDK_CBaseServer_SetReservationCookie = EndPrepSDKCall();
		if( g_hSDK_CBaseServer_SetReservationCookie == null )
			LogError("Failed to create SDKCall: CBaseServer::SetReservationCookie");
	}



	// UNUSED / BROKEN
	/* DEPRECATED
	StartPrepSDKCall(SDKCall_Static);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "GetCampaignScores") == false )
	{
		LogError("Failed to find signature: GetCampaignScores");
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_GetCampaignScores = EndPrepSDKCall();
		if( g_hSDK_GetCampaignScores == null )
			LogError("Failed to create SDKCall: GetCampaignScores");
	}
	// */

	/* DEPRECATED on L4D2 and L4D1 Linux
	StartPrepSDKCall(SDKCall_Static);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "LobbyIsReserved") == false )
	{
		LogError("Failed to find signature: LobbyIsReserved");
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_LobbyIsReserved = EndPrepSDKCall();
		if( g_hSDK_LobbyIsReserved == null )
			LogError("Failed to create SDKCall: LobbyIsReserved");
	}
	// */



	// =========================
	// Pointer Offsets
	// =========================
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
		// if( TeamScoresAddress == Address_Null ) LogError("Failed to find \"CTerrorGameRules::ClearTeamScores\" address.");

		// ClearTeamScore_A = hGameData.GetOffset("ClearTeamScore_A");
		// if( ClearTeamScore_A == -1 ) LogError("Failed to find \"ClearTeamScore_A\" offset.");

		// ClearTeamScore_B = hGameData.GetOffset("ClearTeamScore_B");
		// if( ClearTeamScore_B == -1 ) LogError("Failed to find \"ClearTeamScore_B\" offset.");
	}

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



	// ====================================================================================================
	//									ADDRESSES
	// ====================================================================================================
	g_pDirector = hGameData.GetAddress("CDirector");
	ValidateAddress(g_pDirector, "CDirector", true);

	g_pZombieManager = hGameData.GetAddress("ZombieManager");
	ValidateAddress(g_pZombieManager, "g_pZombieManager", true);

	g_pNavMesh = GameConfGetAddress(hGameData, "TerrorNavMesh");
	ValidateAddress(g_pNavMesh, "TheNavMesh", true);

	g_pServer = hGameData.GetAddress("ServerAddr");
	ValidateAddress(g_pServer, "g_pServer", true);

	g_pWeaponInfoDatabase = hGameData.GetAddress("WeaponInfoDatabase");
	ValidateAddress(g_pWeaponInfoDatabase, "g_pWeaponInfoDatabase", true);

	if( g_bLeft4Dead2 )
	{
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



	// ====================================================================================================
	//									OFFSETS
	// ====================================================================================================
	// Various
	#if DEBUG
	PrintToServer("Various Offsets:");
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

	g_iOff_m_flow = hGameData.GetOffset("m_flow");
	ValidateOffset(g_iOff_m_flow, "m_flow");

	g_iOff_m_chapter = hGameData.GetOffset("m_chapter");
	ValidateOffset(g_iOff_m_chapter, "m_chapter");

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



	if( g_bLeft4Dead2 )
	{
		g_iOff_AddonEclipse1 = hGameData.GetOffset("AddonEclipse1");
		ValidateOffset(g_iOff_AddonEclipse1, "AddonEclipse1");
		g_iOff_AddonEclipse2 = hGameData.GetOffset("AddonEclipse2");
		ValidateOffset(g_iOff_AddonEclipse2, "AddonEclipse2");

		g_iOff_SpawnTimer = hGameData.GetOffset("SpawnTimer");
		ValidateOffset(g_iOff_SpawnTimer, "SpawnTimer");

		g_iOff_OnBeginRoundSetupTime = hGameData.GetOffset("OnBeginRoundSetupTime");
		ValidateOffset(g_iOff_OnBeginRoundSetupTime, "OnBeginRoundSetupTime");

		g_iOff_m_iWitchCount = hGameData.GetOffset("m_iWitchCount");
		ValidateOffset(g_iOff_m_iWitchCount, "m_iWitchCount");

		g_iOff_OvertimeGraceTimer = hGameData.GetOffset("OvertimeGraceTimer");
		ValidateOffset(g_iOff_OvertimeGraceTimer, "OvertimeGraceTimer");

		g_iOff_m_iShovePenalty = hGameData.GetOffset("m_iShovePenalty");
		ValidateOffset(g_iOff_m_iShovePenalty, "m_iShovePenalty");

		g_iOff_m_fNextShoveTime = hGameData.GetOffset("m_fNextShoveTime");
		ValidateOffset(g_iOff_m_fNextShoveTime, "m_fNextShoveTime");

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

		#if DEBUG
		PrintToServer("VersusStartTimer = %d", g_iOff_VersusStartTimer);
		#endif
	}

	// l4d2weapons.inc offsets
	L4D2IntWeapon_Offsets[0] = hGameData.GetOffset("L4D2IntWeapon_Damage");
	L4D2IntWeapon_Offsets[1] = hGameData.GetOffset("L4D2IntWeapon_Bullets");
	L4D2IntWeapon_Offsets[2] = hGameData.GetOffset("L4D2IntWeapon_ClipSize");
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
		PrintToServer("SpawnTimer = %d", g_iOff_SpawnTimer);
		PrintToServer("OnBeginRoundSetupTime = %d", g_iOff_OnBeginRoundSetupTime);
		PrintToServer("m_iWitchCount = %d", g_iOff_m_iWitchCount);
		PrintToServer("OvertimeGraceTimer = %d", g_iOff_OvertimeGraceTimer);
		PrintToServer("m_iShovePenalty = %d", g_iOff_m_iShovePenalty);
		PrintToServer("m_fNextShoveTime = %d", g_iOff_m_fNextShoveTime);
		PrintToServer("m_preIncapacitatedHealth = %d", g_iOff_m_preIncapacitatedHealth);
		PrintToServer("m_preIncapacitatedHealthBuffer = %d", g_iOff_m_preIncapacitatedHealthBuffer);
		PrintToServer("m_maxFlames = %d", g_iOff_m_maxFlames);
		PrintToServer("");
	}
	#endif



	// ====================================================================================================
	//									DETOURS
	// ====================================================================================================
	SetupDetours(hGameData);



	// ====================================================================================================
	//									END
	// ====================================================================================================	
	g_hGameData = hGameData;

	delete hTempGameData;
}



// ====================================================================================================
//										NATIVES
// ====================================================================================================
void ValidateAddress(any addr, const char[] name, bool check = false)
{
	if( addr == Address_Null )
	{
		if( check )		LogError("Failed to find \"%s\" address.", name);
		else			ThrowNativeError(SP_ERROR_INVALID_ADDRESS, "%s not available.", name);
	}
}

void ValidateNatives(Handle test, const char[] name)
{
	if( test == null )
	{
		ThrowNativeError(SP_ERROR_INVALID_ADDRESS, "%s not available.", name);
	}
}

void ValidateOffset(int test, const char[] name, bool check = true)
{
	if( test == -1 )
	{
		if( check )		LogError("Failed to find \"%s\" offset.", name);
		else			ThrowNativeError(SP_ERROR_INVALID_ADDRESS, "%s not available.", name);
	}
}



// ==================================================
// Silvers Natives
// ==================================================
public int Native_ExecVScriptCode(Handle plugin, int numParams)
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

public int Native_GetVScriptOutput(Handle plugin, int numParams)
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

public int Native_CTerrorGameRules_HasConfigurableDifficultySetting(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateNatives(g_hSDK_CTerrorGameRules_HasConfigurableDifficultySetting, "CTerrorGameRules::HasConfigurableDifficultySetting");

	//PrintToServer("#### CALL g_hSDK_CTerrorGameRules_HasConfigurableDifficultySetting");
	return SDKCall(g_hSDK_CTerrorGameRules_HasConfigurableDifficultySetting, g_pGameRules);
}

public int Native_CTerrorGameRules_GetSurvivorSetMap(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateNatives(g_hSDK_KeyValues_GetString, "KeyValues::GetString");
	ValidateNatives(g_hSDK_CTerrorGameRules_GetMissionInfo, "CTerrorGameRules::GetMissionInfo");

	char sTemp[8];
	//PrintToServer("#### CALL g_hSDK_CTerrorGameRules_GetMissionInfo");
	int infoPointer = SDKCall(g_hSDK_CTerrorGameRules_GetMissionInfo);

	//PrintToServer("#### CALL g_hSDK_KeyValues_GetString");
	SDKCall(g_hSDK_KeyValues_GetString, infoPointer, sTemp, sizeof(sTemp), "survivor_set", "2"); // Default set = 2

	return StringToInt(sTemp);
}

public int Native_CTerrorGameRules_GetSurvivorSetMod(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	//PrintToServer("#### CALL g_hSDK_CTerrorGameRules_GetSurvivorSet");
	return SDKCall(g_hSDK_CTerrorGameRules_GetSurvivorSet);
}

public any Native_Internal_GetTempHealth(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return GetTempHealth(client);
}

public int Native_Internal_SetTempHealth(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	float health = GetNativeCell(2);
	SetTempHealth(client, health);

	return 0;
}

public int Native_PlayMusic(Handle plugin, int numParams)
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

public int Native_StopMusic(Handle plugin, int numParams)
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

public int Native_CTerrorPlayer_Deafen(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_CTerrorPlayer_Deafen, "CTerrorPlayer::Deafen");

	int client = GetNativeCell(1);

	//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_Deafen");
	SDKCall(g_hSDK_CTerrorPlayer_Deafen, client, 1.0, 0.0, 0.01 );

	return 0;
}

public int Native_CEntityDissolve_Create(Handle plugin, int numParams)
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

public Action OnCommonDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	// Block dissolver damage to common, otherwise server will crash.
	if( damage == 10000 && damagetype == (g_bLeft4Dead2 ? 5982249 : 33540137) )
	{
		damage = 0.0;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public int Native_CTerrorPlayer_OnITExpired(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_CTerrorPlayer_OnITExpired, "CTerrorPlayer::OnITExpired");

	int client = GetNativeCell(1);

	//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_OnITExpired");
	SDKCall(g_hSDK_CTerrorPlayer_OnITExpired, client);

	return 0;
}

public int Native_CBaseEntity_ApplyLocalAngularVelocityImpulse(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_CBaseEntity_ApplyLocalAngularVelocityImpulse, "CBaseEntity::ApplyLocalAngularVelocityImpulse");

	float vAng[3];
	int entity = GetNativeCell(1);
	GetNativeArray(2, vAng, 3);

	//PrintToServer("#### CALL g_hSDK_CBaseEntity_ApplyLocalAngularVelocityImpulse");
	SDKCall(g_hSDK_CBaseEntity_ApplyLocalAngularVelocityImpulse, entity, vAng);

	return 0;
}

public int Native_ZombieManager_GetRandomPZSpawnPosition(Handle plugin, int numParams)
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

public int Native_CNavMesh_GetNearestNavArea(Handle plugin, int numParams)
{
	ValidateAddress(g_pNavMesh, "g_pNavMesh");
	ValidateNatives(g_hSDK_CNavMesh_GetNearestNavArea, "CNavMesh::GetNearestNavArea");

	float vPos[3];
	GetNativeArray(1, vPos, 3);

	//PrintToServer("#### CALL Native_CNavMesh_GetNearestNavArea");
	int result = SDKCall(g_hSDK_CNavMesh_GetNearestNavArea, g_pNavMesh, vPos, 0, 10000.0, 0, 1, 0);
	return result;
}

public int Native_CTerrorPlayer_GetLastKnownArea(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_CTerrorPlayer_GetLastKnownArea, "CTerrorPlayer::GetLastKnownArea");

	int client = GetNativeCell(1);

	//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_GetLastKnownArea");
	return SDKCall(g_hSDK_CTerrorPlayer_GetLastKnownArea, client);
}

public int Native_TerrorNavArea_FindRandomSpot(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_TerrorNavArea_FindRandomSpot, "TerrorNavArea::FindRandomSpot");

	float vPos[3];
	int area = GetNativeCell(1);

	//PrintToServer("#### CALL g_hSDK_TerrorNavArea_FindRandomSpot");
	SDKCall(g_hSDK_TerrorNavArea_FindRandomSpot, area, vPos, sizeof(vPos));
	SetNativeArray(2, vPos, sizeof(vPos));

	return 0;
}

public int Native_CDirector_HasAnySurvivorLeftSafeArea(Handle plugin, int numParams)
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_CDirector_HasAnySurvivorLeftSafeArea, "CDirector::HasAnySurvivorLeftSafeArea");

	//PrintToServer("#### CALL g_hSDK_CDirector_HasAnySurvivorLeftSafeArea");
	return SDKCall(g_hSDK_CDirector_HasAnySurvivorLeftSafeArea, g_pDirector);
}

public int Native_CDirector_IsAnySurvivorInStartArea(Handle plugin, int numParams)
{
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
}

public int Native_CDirector_IsAnySurvivorInExitCheckpoint(Handle plugin, int numParams)
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_CDirector_IsAnySurvivorInExitCheckpoint, "CDirector::IsAnySurvivorInExitCheckpoint");

	//PrintToServer("#### CALL g_hSDK_CDirector_IsAnySurvivorInExitCheckpoint");
	return SDKCall(g_hSDK_CDirector_IsAnySurvivorInExitCheckpoint, g_pDirector);
}

public int Native_IsInFirstCheckpoint(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return InCheckpoint(client, true);
}

public int Native_IsInLastCheckpoint(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return InCheckpoint(client, false);
}

bool InCheckpoint(int client, bool start)
{
	if( g_bCheckpoint[client] )
	{
		ValidateAddress(g_iOff_m_flow, "m_flow");
		ValidateNatives(g_hSDK_CTerrorPlayer_GetLastKnownArea, "CTerrorPlayer::GetLastKnownArea");

		//PrintToServer("#### CALL InCheckpoint %d g_hSDK_CTerrorPlayer_GetLastKnownArea", start);
		int area = SDKCall(g_hSDK_CTerrorPlayer_GetLastKnownArea, client);
		if( area == 0 ) return false;

		float flow = view_as<float>(LoadFromAddress(view_as<Address>(area + g_iOff_m_flow), NumberType_Int32));
		return (start ? flow < 3000.0 : flow > 3000.0);
	}

	return false;
}

public int Native_CTerrorGameRules_HasPlayerControlledZombies(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_CTerrorGameRules_HasPlayerControlledZombies, "CTerrorGameRules::HasPlayerControlledZombies");

	//PrintToServer("#### CALL g_hSDK_CTerrorGameRules_HasPlayerControlledZombies");
	return SDKCall(g_hSDK_CTerrorGameRules_HasPlayerControlledZombies);
}

public int Native_CBaseGrenade_Detonate(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_CBaseGrenade_Detonate, "CBaseGrenade::Detonate");

	int entity = GetNativeCell(1);

	//PrintToServer("#### CALL g_hSDK_CBaseGrenade_Detonate");
	SDKCall(g_hSDK_CBaseGrenade_Detonate, entity);

	return 0;
}

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

public int Native_CTankRock_Create(Handle plugin, int numParams)
{
	// Get client index and origin/angle to throw
	float vPos[3], vAng[3];
	int client = GetNativeCell(1);
	GetNativeArray(2, vPos, 3);
	GetNativeArray(3, vAng, 3);

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

public void OnFrameTankRock(DataPack dPack)
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

public int Native_CPipeBombProjectile_Create(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_CPipeBombProjectile_Create, "CPipeBombProjectile::Create");

	float vPos[3], vAng[3];
	int client = GetNativeCell(1);
	GetNativeArray(2, vPos, 3);
	GetNativeArray(3, vAng, 3);

	//PrintToServer("#### CALL g_hSDK_CPipeBombProjectile_Create");
	return SDKCall(g_hSDK_CPipeBombProjectile_Create, vPos, vAng, vAng, vAng, client, 2.0);
}

public int Native_CMolotovProjectile_Create(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_CMolotovProjectile_Create, "CMolotovProjectile::Create");

	float vPos[3], vAng[3];
	int client = GetNativeCell(1);
	GetNativeArray(2, vPos, 3);
	GetNativeArray(3, vAng, 3);

	//PrintToServer("#### CALL g_hSDK_CMolotovProjectile_Create");
	return SDKCall(g_hSDK_CMolotovProjectile_Create, vPos, vAng, vAng, vAng, client, 2.0);
}

public int Native_VomitJarProjectile_Create(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_VomitJarProjectile_Create, "VomitJarProjectile::Create");

	float vPos[3], vAng[3];
	int client = GetNativeCell(1);
	GetNativeArray(2, vPos, 3);
	GetNativeArray(3, vAng, 3);

	//PrintToServer("#### CALL g_hSDK_VomitJarProjectile_Create");
	return SDKCall(g_hSDK_VomitJarProjectile_Create, vPos, vAng, vAng, vAng, client, 2.0);
}

public int Native_CGrenadeLauncher_Projectile_Create(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_CGrenadeLauncher_Projectile_Create, "CGrenadeLauncher_Projectile::Create");

	float vPos[3], vAng[3];
	int client = GetNativeCell(1);
	GetNativeArray(2, vPos, 3);
	GetNativeArray(3, vAng, 3);

	//PrintToServer("#### CALL g_hSDK_CGrenadeLauncher_Projectile_Create");
	return SDKCall(g_hSDK_CGrenadeLauncher_Projectile_Create, vPos, vAng, vAng, vAng, client, 2.0);
}

public int Native_CSpitterProjectile_Create(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateNatives(g_hSDK_CSpitterProjectile_Create, "CSpitterProjectile::Create");

	float vPos[3], vAng[3];
	int client = GetNativeCell(1);
	GetNativeArray(2, vPos, 3);
	GetNativeArray(3, vAng, 3);

	//PrintToServer("#### CALL g_hSDK_CSpitterProjectile_Create");
	return SDKCall(g_hSDK_CSpitterProjectile_Create, vPos, vAng, vAng, vAng, client);
}

public int Native_CTerrorPlayer_OnAdrenalineUsed(Handle plugin, int numParams)
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
		fHealth += g_hCvar_PillsHealth.FloatValue;
		if( fHealth > 100.0 ) fHealth = 100.0;

		SetTempHealth(client, fHealth);

		// Event
		Event hEvent = CreateEvent("adrenaline_used");
		if( hEvent != null )
		{
			hEvent.SetInt("userid", GetClientUserId(client));
			hEvent.Fire();
		}
	}

	//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_OnAdrenalineUsed");
	SDKCall(g_hSDK_CTerrorPlayer_OnAdrenalineUsed, client, fTime);

	return 0;
}

public int Native_GetCurrentFinaleStage(Handle plugin, int numParams)
{
	ValidateAddress(g_pScriptedEventManager, "g_pScriptedEventManager");

	return LoadFromAddress(view_as<Address>(g_pScriptedEventManager + 0x04), NumberType_Int32);
}

public int Native_CDirector_ForceNextStage(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_CDirector_ForceNextStage, "CDirector::ForceNextStage");

	//PrintToServer("#### CALL g_hSDK_CDirector_ForceNextStage");
	SDKCall(g_hSDK_CDirector_ForceNextStage, g_pDirector);

	return 0;
}

public int Native_CDirector_IsTankInPlay(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_CDirector_IsTankInPlay, "CDirector_IsTankInPlay");

	//PrintToServer("#### CALL g_hSDK_CDirector_IsTankInPlay");
	return SDKCall(g_hSDK_CDirector_IsTankInPlay, g_pDirector);
}

public int Native_SurvivorBot_IsReachable(Handle plugin, int numParams)
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
	GetNativeArray(2, vPos, 3);

	//PrintToServer("#### CALL g_hSDK_SurvivorBot_IsReachable");
	return SDKCall(g_hSDK_SurvivorBot_IsReachable, client, vPos);
}

public any Native_CDirector_GetFurthestSurvivorFlow(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_CDirector_GetFurthestSurvivorFlow, "CDirector::GetFurthestSurvivorFlow");

	//PrintToServer("#### CALL g_hSDK_CDirector_GetFurthestSurvivorFlow");
	return SDKCall(g_hSDK_CDirector_GetFurthestSurvivorFlow, g_pDirector);
}

public int Native_NavAreaTravelDistance(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateNatives(g_hSDK_NavAreaTravelDistance, "NavAreaTravelDistance");

	float vPos[3], vEnd[3];

	GetNativeArray(1, vPos, sizeof(vPos));
	GetNativeArray(2, vEnd, sizeof(vEnd));
	int a3 = GetNativeCell(3);

	//PrintToServer("#### CALL g_hSDK_NavAreaTravelDistance");
	return SDKCall(g_hSDK_NavAreaTravelDistance, vPos, vEnd, a3);
}

public int Native_CDirector_GetScriptValueInt(Handle plugin, int numParams)
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

/* // Only returns default value provided.
public any Native_CDirector_GetScriptValueFloat(Handle plugin, int numParams)
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

// Not implemented, request if really required.
public int Native_CDirector_GetScriptValueString(Handle plugin, int numParams)
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

	//PrintToServer("#### CALL g_hSDK_CDirector_GetScriptValueString");
	SDKCall(g_hSDK_CDirector_GetScriptValueString, g_pDirector, key, value, retValue, maxlength);
	SetNativeString(3, retValue, maxlength);
}
*/





// ==================================================
// left4downtown.inc
// ==================================================
public int Native_ScavengeBeginRoundSetupTime(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pScavengeMode, "ScavengeModePtr");
	ValidateAddress(g_iOff_OnBeginRoundSetupTime, "OnBeginRoundSetupTime");

	return LoadFromAddress(view_as<Address>(g_pScavengeMode + g_iOff_OnBeginRoundSetupTime + 4), NumberType_Int32);
}

public int Native_CDirector_ResetMobTimer(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_CDirector_ResetMobTimer, "CDirector::ResetMobTimer");

	//PrintToServer("#### CALL g_hSDK_CDirector_ResetMobTimer");
	SDKCall(g_hSDK_CDirector_ResetMobTimer, g_pDirector);
	return 0;
}

public any Native_GetPlayerSpawnTime(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_iOff_SpawnTimer, "SpawnTimer");

	int client = GetNativeCell(1);
	return (view_as<float>(LoadFromAddress(GetEntityAddress(client) + view_as<Address>(g_iOff_SpawnTimer + 8), NumberType_Int32)) - GetGameTime());
}

public int Native_CDirector_RestartScenarioFromVote(Handle plugin, int numParams)
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_CDirector_RestartScenarioFromVote, "CDirector::RestartScenarioFromVote");

	char map[64];
	GetNativeString(1, map, sizeof(map));

	//PrintToServer("#### CALL g_hSDK_CDirector_RestartScenarioFromVote");
	return SDKCall(g_hSDK_CDirector_RestartScenarioFromVote, g_pDirector, map);
}

public int Native_GetVersusMaxCompletionScore(Handle plugin, int numParams)
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

public int Native_SetVersusMaxCompletionScore(Handle plugin, int numParams)
{
	ValidateAddress(g_pGameRules, "g_pGameRules");
	ValidateAddress(g_iOff_VersusMaxCompletionScore, "VersusMaxCompletionScore");

	int value = GetNativeCell(1);

	if( g_bLeft4Dead2 )
	{
		StoreToAddress(g_pGameRules + view_as<Address>(g_iOff_VersusMaxCompletionScore), value, NumberType_Int32);
	}
	else
	{
		ValidateAddress(g_iOff_m_chapter, "m_chapter");

		int chapter = LoadFromAddress(g_pDirector + view_as<Address>(g_iOff_m_chapter), NumberType_Int32);
		StoreToAddress(g_pGameRules + view_as<Address>(chapter * 4 + g_iOff_VersusMaxCompletionScore), value, NumberType_Int32);
	}

	return 0;
}

public int Native_CTerrorGameRules_GetTeamScore(Handle plugin, int numParams)
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

public int Native_CDirector_IsFirstMapInScenario(Handle plugin, int numParams)
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

public int Native_CTerrorGameRules_IsMissionFinalMap(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_CTerrorGameRules_IsMissionFinalMap, "CTerrorGameRules::IsMissionFinalMap");

	//PrintToServer("#### CALL g_hSDK_CTerrorGameRules_IsMissionFinalMap");
	return SDKCall(g_hSDK_CTerrorGameRules_IsMissionFinalMap);
}

public int Native_CGameRulesProxy_NotifyNetworkStateChanged(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_CGameRulesProxy_NotifyNetworkStateChanged, "CGameRulesProxy::NotifyNetworkStateChanged");

	//PrintToServer("#### CALL g_hSDK_CGameRulesProxy_NotifyNetworkStateChanged");
	SDKCall(g_hSDK_CGameRulesProxy_NotifyNetworkStateChanged);
	return 0;
}

public int Native_CTerrorPlayer_OnStaggered(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_CTerrorPlayer_OnStaggered, "CTerrorPlayer::OnStaggered");

	int a1 = GetNativeCell(1);
	int a2 = GetNativeCell(2);
	float vDir[3];
	GetNativeArray(3, vDir, 3);

	if( IsNativeParamNullVector(3) )
	{
		GetEntPropVector(a2, Prop_Send, "m_vecOrigin", vDir);
	}

	//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_OnStaggered");
	SDKCall(g_hSDK_CTerrorPlayer_OnStaggered, a1, a2, vDir);
	return 0;
}

public int Native_ZombieManager_ReplaceTank(Handle plugin, int numParams)
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

public int Native_CDirectorScriptedEventManager_SendInRescueVehicle(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_CDirectorScriptedEventManager_SendInRescueVehicle, "CDirectorScriptedEventManager::SendInRescueVehicle");
	if( g_bLeft4Dead2 )		ValidateAddress(g_pScriptedEventManager, "ScriptedEventManagerPtr");
	else					ValidateAddress(g_pDirector, "g_pDirector");

	//PrintToServer("#### CALL g_hSDK_CDirectorScriptedEventManager_SendInRescueVehicle");
	SDKCall(g_hSDK_CDirectorScriptedEventManager_SendInRescueVehicle, g_bLeft4Dead2 ? g_pScriptedEventManager : view_as<int>(g_pDirector));
	return 0;
}

public int Native_CDirectorScriptedEventManager_ChangeFinaleStage(Handle plugin, int numParams)
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

public int Native_ZombieManager_SpawnTank(Handle plugin, int numParams)
{
	ValidateAddress(g_pZombieManager, "g_pZombieManager");
	ValidateNatives(g_hSDK_ZombieManager_SpawnTank, "ZombieManager::SpawnTank");

	float vPos[3], vAng[3];
	GetNativeArray(1, vPos, 3);
	GetNativeArray(2, vAng, 3);

	//PrintToServer("#### CALL g_hSDK_ZombieManager_SpawnTank");
	return SDKCall(g_hSDK_ZombieManager_SpawnTank, g_pZombieManager, vPos, vAng);
}

public int Native_ZombieManager_SpawnSpecial(Handle plugin, int numParams)
{
	ValidateAddress(g_pZombieManager, "g_pZombieManager");

	float vPos[3], vAng[3];
	int zombieClass = GetNativeCell(1);
	GetNativeArray(2, vPos, 3);
	GetNativeArray(3, vAng, 3);

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

public int Native_ZombieManager_SpawnWitch(Handle plugin, int numParams)
{
	ValidateAddress(g_pZombieManager, "g_pZombieManager");
	ValidateNatives(g_hSDK_ZombieManager_SpawnWitch, "ZombieManager::SpawnWitch");

	float vPos[3], vAng[3];
	GetNativeArray(1, vPos, 3);
	GetNativeArray(2, vAng, 3);

	//PrintToServer("#### CALL g_hSDK_ZombieManager_SpawnWitch");
	return SDKCall(g_hSDK_ZombieManager_SpawnWitch, g_pZombieManager, vPos, vAng);
}

public int Native_ZombieManager_SpawnWitchBride(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pZombieManager, "g_pZombieManager");
	ValidateNatives(g_hSDK_ZombieManager_SpawnWitchBride, "ZombieManager::SpawnWitchBride");

	float vPos[3], vAng[3];
	GetNativeArray(1, vPos, 3);
	GetNativeArray(2, vAng, 3);

	//PrintToServer("#### CALL g_hSDK_ZombieManager_SpawnWitchBride");
	return SDKCall(g_hSDK_ZombieManager_SpawnWitchBride, g_pZombieManager, vPos, vAng);
}

public any Native_GetMobSpawnTimerRemaining(Handle plugin, int numParams)
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateAddress(g_iOff_MobSpawnTimer, "MobSpawnTimer");

	float timestamp = view_as<float>(LoadFromAddress(g_pDirector + view_as<Address>(g_iOff_MobSpawnTimer + 8), NumberType_Int32));
	return timestamp - GetGameTime();
}

public any Native_GetMobSpawnTimerDuration(Handle plugin, int numParams)
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateAddress(g_iOff_MobSpawnTimer, "MobSpawnTimer");

	float duration = view_as<float>(LoadFromAddress(g_pDirector + view_as<Address>(g_iOff_MobSpawnTimer + 4), NumberType_Int32));
	return duration > 0.0 ? duration : 0.0;
}

public int Native_CBaseServer_SetReservationCookie(Handle plugin, int numParams)
{
	ValidateAddress(g_pServer, "g_pServer");
	ValidateNatives(g_hSDK_CBaseServer_SetReservationCookie, "CBaseServer::SetReservationCookie");

	//PrintToServer("#### CALL g_hSDK_CBaseServer_SetReservationCookie");
	SDKCall(g_hSDK_CBaseServer_SetReservationCookie, g_pServer, 0, 0, "Unreserved by Left 4 DHooks");

	return 0;
}

//DEPRECATED
// public int Native_GetCampaignScores(Handle plugin, int numParams)
// {}

//DEPRECATED
// public int Native_LobbyIsReserved(Handle plugin, int numParams)
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
		LogError("Invalid melee ID (%d) or melee unavailable (%d)", id, ptr);
		return -1;
	}

	return ptr;
}

// ==================================================
// Natives
// ==================================================
public int Native_GetWeaponID(Handle plugin, int numParams)
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

public int Native_Internal_IsValidWeapon(Handle plugin, int numParams)
{
	return GetWeaponPointer() != -1;
}

public int Native_GetIntWeaponAttribute(Handle plugin, int numParams)
{
	int attr = GetNativeCell(2);
	if( attr >= view_as<int>(MAX_SIZE_L4D2IntWeaponAttributes) ) // view_as to avoid tag mismatch from enum "type"
		ThrowNativeError(SP_ERROR_PARAM, "Invalid attribute id");

	int ptr = GetWeaponPointer();
	if( ptr != -1 )
	{
		attr = L4D2IntWeapon_Offsets[attr]; // Offset
		ptr = LoadFromAddress(view_as<Address>(ptr + attr), NumberType_Int32);
	}

	return ptr;
}

public any Native_GetFloatWeaponAttribute(Handle plugin, int numParams)
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

public int Native_SetIntWeaponAttribute(Handle plugin, int numParams)
{
	int attr = GetNativeCell(2);
	if( attr >= view_as<int>(MAX_SIZE_L4D2IntWeaponAttributes) ) // view_as to avoid tag mismatch from enum "type"
		ThrowNativeError(SP_ERROR_PARAM, "Invalid attribute id");

	int ptr = GetWeaponPointer();
	if( ptr != -1 )
	{
		if( !g_bLeft4Dead2 && attr == view_as<int>(L4D2FWA_PenetrationNumLayers) )
		{
			attr = L4D2IntWeapon_Offsets[attr]; // Offset
			StoreToAddress(view_as<Address>(ptr + attr), RoundToCeil(GetNativeCell(3)), NumberType_Int32);
		}
		else
		{
			attr = L4D2IntWeapon_Offsets[attr]; // Offset
			StoreToAddress(view_as<Address>(ptr + attr), GetNativeCell(3), NumberType_Int32);
		}
	}

	return ptr;
}

public int Native_SetFloatWeaponAttribute(Handle plugin, int numParams)
{
	int attr = GetNativeCell(2);
	if( attr >= view_as<int>(MAX_SIZE_L4D2FloatWeaponAttributes) ) // view_as to avoid tag mismatch from enum "type"
		ThrowNativeError(SP_ERROR_PARAM, "Invalid attribute id");

	int ptr = GetWeaponPointer();
	if( ptr != -1 )
	{
		attr = L4D2FloatWeapon_Offsets[attr]; // Offset
		StoreToAddress(view_as<Address>(ptr + attr), GetNativeCell(3), NumberType_Int32);
	}

	return ptr;
}

public int Native_GetMeleeWeaponIndex(Handle plugin, int numParams)
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

public int Native_GetIntMeleeAttribute(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	int attr = GetNativeCell(2);
	if( attr >= view_as<int>(MAX_SIZE_L4D2IntMeleeWeaponAttributes) ) // view_as to avoid tag mismatch from enum "type"
		ThrowNativeError(SP_ERROR_PARAM, "Invalid attribute id");

	int ptr = GetMeleePointer(GetNativeCell(1));
	if( ptr != -1 )
	{
		attr = L4D2IntMeleeWeapon_Offsets[attr]; // Offset
		ptr = LoadFromAddress(view_as<Address>(ptr + attr), NumberType_Int32);
	}

	return ptr;
}

public any Native_GetFloatMeleeAttribute(Handle plugin, int numParams)
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

public int Native_GetBoolMeleeAttribute(Handle plugin, int numParams)
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

public int Native_SetIntMeleeAttribute(Handle plugin, int numParams)
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
		StoreToAddress(view_as<Address>(ptr + attr), value, NumberType_Int32);
	}

	return 0;
}

public int Native_SetFloatMeleeAttribute(Handle plugin, int numParams)
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
		StoreToAddress(view_as<Address>(ptr + attr), view_as<int>(value), NumberType_Int32);
	}

	return 0;
}

public int Native_SetBoolMeleeAttribute(Handle plugin, int numParams)
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
		StoreToAddress(view_as<Address>(ptr + attr), value, NumberType_Int32);
	}

	return 0;
}



// ==================================================
// l4d2timers.inc
// ==================================================
// CountdownTimers
// ==================================================
public int Native_CTimerReset(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pDirector, "g_pDirector");

	int id = GetNativeCell(1);
	int off = L4D2CountdownTimer_Offsets[id];
	float timestamp = GetGameTime();

	StoreToAddress(view_as<Address>(off + 8), view_as<int>(timestamp), NumberType_Int32);

	return 0;
}

public int Native_CTimerStart(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pDirector, "g_pDirector");

	int id = GetNativeCell(1);
	int off = L4D2CountdownTimer_Offsets[id];
	float duration = GetNativeCell(2);
	float timestamp = GetGameTime() + duration;

	StoreToAddress(view_as<Address>(off + 4), view_as<int>(duration), NumberType_Int32);
	StoreToAddress(view_as<Address>(off + 8), view_as<int>(timestamp), NumberType_Int32);

	return 0;
}

public int Native_CTimerInvalidate(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pDirector, "g_pDirector");

	int id = GetNativeCell(1);
	int off = L4D2CountdownTimer_Offsets[id];
	float timestamp = -1.0;

	StoreToAddress(view_as<Address>(off + 8), view_as<int>(timestamp), NumberType_Int32);

	return 0;
}

public int Native_CTimerHasStarted(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pDirector, "g_pDirector");

	int id = GetNativeCell(1);
	int off = L4D2CountdownTimer_Offsets[id];
	float timestamp = view_as<float>(LoadFromAddress(view_as<Address>(off + 8), NumberType_Int32));

	return (timestamp >= 0.0);
}

public int Native_CTimerIsElapsed(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pDirector, "g_pDirector");

	int id = GetNativeCell(1);
	int off = L4D2CountdownTimer_Offsets[id];
	float timestamp = view_as<float>(LoadFromAddress(view_as<Address>(off + 8), NumberType_Int32));

	return (GetGameTime() >= timestamp);
}

public any Native_CTimerGetElapsedTime(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pDirector, "g_pDirector");

	int id = GetNativeCell(1);
	int off = L4D2CountdownTimer_Offsets[id];
	float duration = view_as<float>(LoadFromAddress(view_as<Address>(off + 4), NumberType_Int32));
	float timestamp = view_as<float>(LoadFromAddress(view_as<Address>(off + 8), NumberType_Int32));

	return GetGameTime() - timestamp + duration;
}

public any Native_CTimerGetRemainingTime(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pDirector, "g_pDirector");

	int id = GetNativeCell(1);
	int off = L4D2CountdownTimer_Offsets[id];
	float timestamp = view_as<float>(LoadFromAddress(view_as<Address>(off + 8), NumberType_Int32));

	return (timestamp - GetGameTime());
}

public any Native_CTimerGetCountdownDuration(Handle plugin, int numParams)
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
public int Native_ITimerStart(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pDirector, "g_pDirector");

	int id = GetNativeCell(1);
	int off = L4D2IntervalTimer_Offsets[id];
	float timestamp = GetGameTime();

	StoreToAddress(view_as<Address>(off + 4), view_as<int>(timestamp), NumberType_Int32);

	return 0;
}

public int Native_ITimerInvalidate(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pDirector, "g_pDirector");

	int id = GetNativeCell(1);
	int off = L4D2IntervalTimer_Offsets[id];
	float timestamp = -1.0;

	StoreToAddress(view_as<Address>(off + 4), view_as<int>(timestamp), NumberType_Int32);

	return 0;
}

public int Native_ITimerHasStarted(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pDirector, "g_pDirector");

	int id = GetNativeCell(1);
	int off = L4D2IntervalTimer_Offsets[id];
	float timestamp = view_as<float>(LoadFromAddress(view_as<Address>(off + 4), NumberType_Int32));

	return (timestamp > 0.0);
}

public any Native_ITimerGetElapsedTime(Handle plugin, int numParams)
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
public int Native_GetTankCount(Handle plugin, int numParams)
{
	ValidateAddress(g_pDirector, "g_pDirector");

	int val = LoadFromAddress(g_pDirector + view_as<Address>(g_iOff_m_iTankCount), NumberType_Int32);

	return val;
}

public int Native_GetWitchCount(Handle plugin, int numParams)
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

public int Native_GetCurrentChapter(Handle plugin, int numParams)
{
	ValidateAddress(g_iOff_m_chapter, "m_chapter");

	return LoadFromAddress(g_pDirector + view_as<Address>(g_iOff_m_chapter), NumberType_Int32) + 1;
}

public int Native_CTerrorGameRules_GetNumChaptersForMissionAndMode(Handle plugin, int numParams)
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

			char sMode[64];
			char sTemp[64];
			char sRet[64];
			g_hCvar_MPGameMode.GetString(sMode, sizeof(sMode));

			int index = 1;
			while( index < 20 )
			{
				FormatEx(sTemp, sizeof(sTemp), "modes/%s/%d/Map", sMode, index);

				// PrintToServer("#### CALL g_hSDK_KeyValues_GetString");
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

public int Native_CDirector_IsFinaleEscapeInProgress(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_CDirector_IsFinaleEscapeInProgress, "CDirector::IsFinaleEscapeInProgress");
	ValidateAddress(g_pDirector, "g_pDirector");

	//PrintToServer("#### CALL g_hSDK_CDirector_IsFinaleEscapeInProgress");
	return SDKCall(g_hSDK_CDirector_IsFinaleEscapeInProgress, g_pDirector);
}

public int Native_SurvivorBot_SetHumanSpectator(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_SurvivorBot_SetHumanSpectator, "SurvivorBot::SetHumanSpectator");

	int bot = GetNativeCell(1);
	int client = GetNativeCell(2);

	//PrintToServer("#### CALL g_hSDK_SurvivorBot_SetHumanSpectator");
	return SDKCall(g_hSDK_SurvivorBot_SetHumanSpectator, bot, client);
}

public int Native_CTerrorPlayer_TakeOverBot(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_CTerrorPlayer_TakeOverBot, "CTerrorPlayer::TakeOverBot");

	int client = GetNativeCell(1);

	//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_TakeOverBot");
	return SDKCall(g_hSDK_CTerrorPlayer_TakeOverBot, client, true);
}

public int Native_CTerrorPlayer_CanBecomeGhost(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_CTerrorPlayer_CanBecomeGhost, "CTerrorPlayer::CanBecomeGhost");

	int client = GetNativeCell(1);

	//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_CanBecomeGhost");
	return SDKCall(g_hSDK_CTerrorPlayer_CanBecomeGhost, client, true);
}

public int Native_CDirector_AreWanderersAllowed(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateNatives(g_hSDK_CDirector_AreWanderersAllowed, "CDirector::AreWanderersAllowed");
	ValidateAddress(g_pDirector, "g_pDirector");

	//PrintToServer("#### CALL g_hSDK_CDirector_AreWanderersAllowed");
	return SDKCall(g_hSDK_CDirector_AreWanderersAllowed, g_pDirector);
}

public int Native_GetVersusCampaignScores(Handle plugin, int numParams)
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

public int Native_SetVersusCampaignScores(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pVersusMode, "VersusModePtr");
	ValidateAddress(g_pVersusMode, "m_iCampaignScores");

	int vals[2];
	GetNativeArray(1, vals, 2);
	StoreToAddress(view_as<Address>(g_pVersusMode + g_iOff_m_iCampaignScores), vals[0], NumberType_Int32);
	StoreToAddress(view_as<Address>(g_pVersusMode + g_iOff_m_iCampaignScores + 4), vals[1], NumberType_Int32);

	return 0;
}

public int Native_GetVersusTankFlowPercent(Handle plugin, int numParams)
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

public int Native_SetVersusTankFlowPercent(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pVersusMode, "VersusModePtr");
	ValidateAddress(g_pVersusMode, "m_fTankSpawnFlowPercent");

	float vals[2];
	GetNativeArray(1, vals, 2);
	StoreToAddress(view_as<Address>(g_pVersusMode + g_iOff_m_fTankSpawnFlowPercent), view_as<int>(vals[0]), NumberType_Int32);
	StoreToAddress(view_as<Address>(g_pVersusMode + g_iOff_m_fTankSpawnFlowPercent + 4), view_as<int>(vals[1]), NumberType_Int32);

	return 0;
}

public int Native_GetVersusWitchFlowPercent(Handle plugin, int numParams)
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

public int Native_SetVersusWitchFlowPercent(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pVersusMode, "VersusModePtr");
	ValidateAddress(g_pVersusMode, "m_fWitchSpawnFlowPercent");

	float vals[2];
	GetNativeArray(1, vals, 2);
	StoreToAddress(view_as<Address>(g_pVersusMode + g_iOff_m_fWitchSpawnFlowPercent), view_as<int>(vals[0]), NumberType_Int32);
	StoreToAddress(view_as<Address>(g_pVersusMode + g_iOff_m_fWitchSpawnFlowPercent + 4), view_as<int>(vals[1]), NumberType_Int32);

	return 0;
}





// ==================================================
// l4d_direct.inc
// ==================================================
public int Direct_GetTankCount(Handle plugin, int numParams)
{
	return Native_GetTankCount(plugin, numParams);
}

public int Direct_GetPendingMobCount(Handle plugin, int numParams)
{
	ValidateAddress(g_pZombieManager, "g_pZombieManager");
	ValidateAddress(g_iOff_m_PendingMobCount, "m_PendingMobCount");

	return LoadFromAddress(g_pZombieManager + view_as<Address>(g_iOff_m_PendingMobCount), NumberType_Int32);
}

public int Direct_SetPendingMobCount(Handle plugin, int numParams)
{
	ValidateAddress(g_pZombieManager, "g_pZombieManager");
	ValidateAddress(g_iOff_m_PendingMobCount, "m_PendingMobCount");

	int count = GetNativeCell(1);
	StoreToAddress(g_pZombieManager + view_as<Address>(g_iOff_m_PendingMobCount), count, NumberType_Int32);

	return 0;
}

public any Direct_GetMobSpawnTimer(Handle plugin, int numParams)
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateAddress(g_iOff_MobSpawnTimer, "MobSpawnTimer");

	return view_as<CountdownTimer>(g_pDirector + view_as<Address>(g_iOff_MobSpawnTimer));
}

public any Direct_GetSIClassDeathTimer(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pDirector, "g_pDirector");

	int class = GetNativeCell(1);
	if( class < 1 || class > 6 ) return CTimer_Null;

	int offset = L4D2IntervalTimer_Offsets[class];
	return view_as<IntervalTimer>(view_as<Address>(offset));
}

public any Direct_GetSIClassSpawnTimer(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pDirector, "g_pDirector");

	int class = GetNativeCell(1);
	if( class < 1 || class > 6 ) return CTimer_Null;

	int offset = L4D2CountdownTimer_Offsets[class];
	return view_as<CountdownTimer>(view_as<Address>(offset));
}

public int Direct_GetTankPassedCount(Handle plugin, int numParams)
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateAddress(g_pDirector, "m_iTankPassedCount");

	return LoadFromAddress(g_pDirector + view_as<Address>(g_iOff_m_iTankPassedCount), NumberType_Int32);
}

public int Direct_SetTankPassedCount(Handle plugin, int numParams)
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateAddress(g_pDirector, "m_iTankPassedCount");

	int passes = GetNativeCell(1);
	StoreToAddress(g_pDirector + view_as<Address>(g_iOff_m_iTankPassedCount), passes, NumberType_Int32);

	return 0;
}

public int Direct_GetVSCampaignScore(Handle plugin, int numParams)
{
	ValidateAddress(g_pVersusMode, "VersusModePtr");
	ValidateAddress(g_iOff_m_iCampaignScores, "m_iCampaignScores");

	int team = GetNativeCell(1);
	if( team < 0 || team > 1 ) return -1;

	return LoadFromAddress(view_as<Address>(g_pVersusMode + g_iOff_m_iCampaignScores + (team * 4)), NumberType_Int32);
}

public int Direct_SetVSCampaignScore(Handle plugin, int numParams)
{
	ValidateAddress(g_pVersusMode, "VersusModePtr");
	ValidateAddress(g_iOff_m_iCampaignScores, "m_iCampaignScores");

	int team = GetNativeCell(1);
	if( team < 0 || team > 1 ) return 0;

	int score = GetNativeCell(2);
	StoreToAddress(view_as<Address>(g_pVersusMode + g_iOff_m_iCampaignScores + (team * 4)), score, NumberType_Int32);

	return 0;
}

public any Direct_GetVSTankFlowPercent(Handle plugin, int numParams)
{
	ValidateAddress(g_pVersusMode, "VersusModePtr");
	ValidateAddress(g_iOff_m_fTankSpawnFlowPercent, "m_fTankSpawnFlowPercent");

	int round = GetNativeCell(1);
	if( round < 0 || round > 1 ) return -1.0;

	int team = round ^ GameRules_GetProp("m_bInSecondHalfOfRound") != GameRules_GetProp("m_bAreTeamsFlipped");

	return LoadFromAddress(view_as<Address>(g_pVersusMode + g_iOff_m_fTankSpawnFlowPercent + (team * 4)), NumberType_Int32);
}

public int Direct_SetVSTankFlowPercent(Handle plugin, int numParams)
{
	ValidateAddress(g_pVersusMode, "VersusModePtr");
	ValidateAddress(g_iOff_m_fTankSpawnFlowPercent, "m_fTankSpawnFlowPercent");

	int round = GetNativeCell(1);
	if( round < 0 || round > 1 ) return 0;

	int team = round ^ GameRules_GetProp("m_bInSecondHalfOfRound") != GameRules_GetProp("m_bAreTeamsFlipped");
	float flow = GetNativeCell(2);

	StoreToAddress(view_as<Address>(g_pVersusMode + g_iOff_m_fTankSpawnFlowPercent + (team * 4)), view_as<int>(flow), NumberType_Int32);

	return 0;
}

public int Direct_GetVSTankToSpawnThisRound(Handle plugin, int numParams)
{
	ValidateAddress(g_pVersusMode, "VersusModePtr");
	ValidateAddress(g_iOff_m_bTankThisRound, "m_bTankThisRound");

	int round = GetNativeCell(1);
	if( round < 0 || round > 1 ) return false;

	int team = round ^ GameRules_GetProp("m_bInSecondHalfOfRound") != GameRules_GetProp("m_bAreTeamsFlipped");

	return LoadFromAddress(view_as<Address>(g_pVersusMode + g_iOff_m_bTankThisRound + team), NumberType_Int8);
}

public int Direct_SetVSTankToSpawnThisRound(Handle plugin, int numParams)
{
	ValidateAddress(g_pVersusMode, "VersusModePtr");
	ValidateAddress(g_iOff_m_bTankThisRound, "m_bTankThisRound");

	int round = GetNativeCell(1);
	if( round < 0 || round > 1 ) return 0;

	int team = round ^ GameRules_GetProp("m_bInSecondHalfOfRound") != GameRules_GetProp("m_bAreTeamsFlipped");
	bool spawn = GetNativeCell(2);

	StoreToAddress(view_as<Address>(g_pVersusMode + g_iOff_m_bTankThisRound + team), spawn, NumberType_Int8);

	return 0;
}

public any Direct_GetVSWitchFlowPercent(Handle plugin, int numParams)
{
	ValidateAddress(g_pVersusMode, "VersusModePtr");
	ValidateAddress(g_iOff_m_fWitchSpawnFlowPercent, "m_fWitchSpawnFlowPercent");

	int round = GetNativeCell(1);
	if( round < 0 || round > 1 ) return false;

	int team = round ^ GameRules_GetProp("m_bInSecondHalfOfRound") != GameRules_GetProp("m_bAreTeamsFlipped");

	return LoadFromAddress(view_as<Address>(g_pVersusMode + g_iOff_m_fWitchSpawnFlowPercent + (team * 4)), NumberType_Int32);
}

public int Direct_SetVSWitchFlowPercent(Handle plugin, int numParams)
{
	ValidateAddress(g_pVersusMode, "VersusModePtr");
	ValidateAddress(g_iOff_m_fWitchSpawnFlowPercent, "m_fWitchSpawnFlowPercent");

	int round = GetNativeCell(1);
	if( round < 0 || round > 1 ) return 0;

	int team = round ^ GameRules_GetProp("m_bInSecondHalfOfRound") != GameRules_GetProp("m_bAreTeamsFlipped");
	float flow = GetNativeCell(2);

	StoreToAddress(view_as<Address>(g_pVersusMode + g_iOff_m_fWitchSpawnFlowPercent + (team * 4)), view_as<int>(flow), NumberType_Int32);

	return 0;
}

public int Direct_GetVSWitchToSpawnThisRound(Handle plugin, int numParams)
{
	ValidateAddress(g_pVersusMode, "VersusModePtr");
	ValidateAddress(g_iOff_m_bWitchThisRound, "m_bWitchThisRound");

	int round = GetNativeCell(1);
	if( round < 0 || round > 1 ) return false;

	int team = round ^ GameRules_GetProp("m_bInSecondHalfOfRound") != GameRules_GetProp("m_bAreTeamsFlipped");

	return LoadFromAddress(view_as<Address>(g_pVersusMode + g_iOff_m_bWitchThisRound + team), NumberType_Int8);
}

public int Direct_SetVSWitchToSpawnThisRound(Handle plugin, int numParams)
{
	ValidateAddress(g_pVersusMode, "VersusModePtr");
	ValidateAddress(g_iOff_m_bWitchThisRound, "m_bWitchThisRound");

	int round = GetNativeCell(1);
	if( round < 0 || round > 1 ) return 0;

	int team = round ^ GameRules_GetProp("m_bInSecondHalfOfRound") != GameRules_GetProp("m_bAreTeamsFlipped");
	bool spawn = GetNativeCell(2);

	StoreToAddress(view_as<Address>(g_pVersusMode + g_iOff_m_bWitchThisRound + team), spawn, NumberType_Int8);

	return 0;
}

public any Direct_GetVSStartTimer(Handle plugin, int numParams)
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

public any Direct_GetScavengeRoundSetupTimer(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pScavengeMode, "ScavengeModePtr");
	ValidateAddress(g_iOff_OnBeginRoundSetupTime, "OnBeginRoundSetupTime");

	return view_as<CountdownTimer>(view_as<Address>(g_pScavengeMode + g_iOff_OnBeginRoundSetupTime));
}

public any Direct_GetScavengeOvertimeGraceTimer(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pScavengeMode, "ScavengeModePtr");
	ValidateAddress(g_iOff_OvertimeGraceTimer, "OvertimeGraceTimer");

	return view_as<CountdownTimer>(view_as<Address>(g_pScavengeMode + g_iOff_OvertimeGraceTimer));
}

public any Direct_GetMapMaxFlowDistance(Handle plugin, int numParams)
{
	ValidateAddress(g_pNavMesh, "g_pNavMesh");
	ValidateAddress(g_iOff_m_fMapMaxFlowDistance, "m_fMapMaxFlowDistance");

	return LoadFromAddress(g_pNavMesh + view_as<Address>(g_iOff_m_fMapMaxFlowDistance), NumberType_Int32);
}

public any Direct_GetSpawnTimer(Handle plugin, int numParams)
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

public any Direct_GetInvulnerabilityTimer(Handle plugin, int numParams)
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

public int Direct_GetTankTickets(Handle plugin, int numParams)
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

public int Direct_SetTankTickets(Handle plugin, int numParams)
{
	ValidateAddress(g_iOff_m_iTankTickets, "m_iTankTickets");

	int client = GetNativeCell(1);
	if( client < 1 || client > MaxClients )
		return 0;

	Address pEntity = GetEntityAddress(client);
	if( pEntity == Address_Null )
		return 0;

	int tickets = GetNativeCell(2);
	StoreToAddress(pEntity + view_as<Address>(g_iOff_m_iTankTickets), tickets, NumberType_Int32);

	return 0;
}

public int Direct_GetShovePenalty(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_iOff_m_iShovePenalty, "m_iShovePenalty");

	int client = GetNativeCell(1);
	if( client < 1 || client > MaxClients )
		return -1;

	Address pEntity = GetEntityAddress(client);
	if( pEntity == Address_Null )
		return -1;

	return LoadFromAddress(pEntity + view_as<Address>(g_iOff_m_iShovePenalty), NumberType_Int32);
}

public int Direct_SetShovePenalty(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_iOff_m_iShovePenalty, "m_iShovePenalty");

	int client = GetNativeCell(1);
	if( client < 1 || client > MaxClients )
		return 0;

	Address pEntity = GetEntityAddress(client);
	if( pEntity == Address_Null )
		return 0;

	int penalty = GetNativeCell(2);
	StoreToAddress(pEntity + view_as<Address>(g_iOff_m_iShovePenalty), penalty, NumberType_Int32);

	return 0;
}

public any Direct_GetNextShoveTime(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_iOff_m_fNextShoveTime, "m_fNextShoveTime");

	int client = GetNativeCell(1);
	if( client < 1 || client > MaxClients )
		return 0.0;

	Address pEntity = GetEntityAddress(client);
	if( pEntity == Address_Null )
		return 0.0;

	return LoadFromAddress(pEntity + view_as<Address>(g_iOff_m_fNextShoveTime), NumberType_Int32);
}

public int Direct_SetNextShoveTime(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_iOff_m_fNextShoveTime, "m_fNextShoveTime");

	int client = GetNativeCell(1);
	if( client < 1 || client > MaxClients )
		return 0;

	Address pEntity = GetEntityAddress(client);
	if( pEntity == Address_Null )
		return 0;

	float time = GetNativeCell(2);
	StoreToAddress(pEntity + view_as<Address>(g_iOff_m_fNextShoveTime), view_as<int>(time), NumberType_Int32);

	return 0;
}

public int Direct_GetPreIncapHealth(Handle plugin, int numParams)
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

public int Direct_SetPreIncapHealth(Handle plugin, int numParams)
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
	StoreToAddress(pEntity + view_as<Address>(g_iOff_m_preIncapacitatedHealth), health, NumberType_Int32);

	return 0;
}

public int Direct_GetPreIncapHealthBuffer(Handle plugin, int numParams)
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

public int Direct_SetPreIncapHealthBuffer(Handle plugin, int numParams)
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
	StoreToAddress(pEntity + view_as<Address>(g_iOff_m_preIncapacitatedHealthBuffer), health, NumberType_Int32);

	return 0;
}

public int Direct_GetInfernoMaxFlames(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_iOff_m_maxFlames, "m_maxFlames");

	int client = GetNativeCell(1);

	Address pEntity = GetEntityAddress(client);
	if( pEntity == Address_Null )
		return -1;

	return LoadFromAddress(pEntity + view_as<Address>(g_iOff_m_maxFlames), NumberType_Int32);
}

public int Direct_SetInfernoMaxFlames(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_iOff_m_maxFlames, "m_maxFlames");

	int entity = GetNativeCell(1);

	Address pEntity = GetEntityAddress(entity);
	if( pEntity == Address_Null )
		return 0;

	int flames = GetNativeCell(2);
	StoreToAddress(pEntity + view_as<Address>(g_iOff_m_maxFlames), flames, NumberType_Int32);

	return 0;
}

public int Direct_GetScriptedEventManager(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pScriptedEventManager, "ScriptedEventManagerPtr");

	return g_pScriptedEventManager;
}

public any Direct_GetTerrorNavArea(Handle plugin, int numParams)
{
	ValidateAddress(g_pNavMesh, "g_pNavMesh");
	ValidateNatives(g_hSDK_CNavMesh_GetNavArea, "CNavMesh::GetNavArea");

	float vPos[3];
	GetNativeArray(1, vPos, 3);

	float beneathLimit = GetNativeCell(2);

	//PrintToServer("#### CALL g_hSDK_CNavMesh_GetNavArea");
	return SDKCall(g_hSDK_CNavMesh_GetNavArea, g_pNavMesh, vPos, beneathLimit);
}

public any Direct_GetTerrorNavAreaFlow(Handle plugin, int numParams)
{
	ValidateAddress(g_iOff_m_flow, "m_flow");

	Address pTerrorNavArea = GetNativeCell(1);
	if( pTerrorNavArea == Address_Null )
		return 0.0;

	return view_as<float>(LoadFromAddress(pTerrorNavArea + view_as<Address>(g_iOff_m_flow), NumberType_Int32));
}

public int Direct_TryOfferingTankBot(Handle plugin, int numParams)
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_CDirector_TryOfferingTankBot, "CDirector::TryOfferingTankBot");

	int entity = GetNativeCell(1);
	bool bEnterStasis = GetNativeCell(2);

	//PrintToServer("#### CALL g_hSDK_CDirector_TryOfferingTankBot");
	SDKCall(g_hSDK_CDirector_TryOfferingTankBot, g_pDirector, entity, bEnterStasis);

	return 0;
}

public any Direct_GetFlowDistance(Handle plugin, int numParams)
{
	ValidateAddress(g_iOff_m_flow, "m_flow");
	ValidateNatives(g_hSDK_CTerrorPlayer_GetLastKnownArea, "CTerrorPlayer::GetLastKnownArea");

	int client = GetNativeCell(1);

	//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_GetLastKnownArea");
	int area = SDKCall(g_hSDK_CTerrorPlayer_GetLastKnownArea, client);
	if( area == 0 ) return 0.0;

	float flow = view_as<float>(LoadFromAddress(view_as<Address>(area + g_iOff_m_flow), NumberType_Int32));
	if( flow == -9999.0 ) flow = 0.0;

	return flow;
}

public int Direct_DoAnimationEvent(Handle plugin, int numParams)
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

public int Direct_GetSurvivorHealthBonus(Handle plugin, int numParams)
{
	if( g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED1);

	int client = GetNativeCell(1);

	Address pEntity = GetEntityAddress(client);
	if( pEntity == Address_Null )
		return -1;

	return LoadFromAddress(pEntity + view_as<Address>(g_iOff_m_iSurvivorHealthBonus), NumberType_Int32);
}

public int Direct_SetSurvivorHealthBonus(Handle plugin, int numParams)
{
	if( g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED1);

	int client = GetNativeCell(1);

	Address pEntity = GetEntityAddress(client);
	if( pEntity == Address_Null )
		return 0;

	int health = GetNativeCell(2);
	bool recompute = GetNativeCell(3);

	StoreToAddress(pEntity + view_as<Address>(g_iOff_m_iSurvivorHealthBonus), health, NumberType_Int32);

	if( recompute )
	{
		ValidateNatives(g_hSDK_CTerrorGameRules_RecomputeTeamScores, "CTerrorGameRules::RecomputeTeamScores");

		//PrintToServer("#### CALL g_hSDK_CTerrorGameRules_RecomputeTeamScores");
		SDKCall(g_hSDK_CTerrorGameRules_RecomputeTeamScores);
	}

	return 0;
}

public int Direct_RecomputeTeamScores(Handle plugin, int numParams)
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
public int Direct_CTimer_Reset(Handle plugin, int numParams)
{
	CountdownTimer timer = GetNativeCell(1);
	Stock_CTimer_Reset(timer);
	return 0;
}

public int Direct_CTimer_Start(Handle plugin, int numParams)
{
	CountdownTimer timer = GetNativeCell(1);
	float duration = GetNativeCell(2);
	Stock_CTimer_Start(timer, duration);
	return 0;
}

public int Direct_CTimer_Invalidate(Handle plugin, int numParams)
{
	CountdownTimer timer = GetNativeCell(1);
	Stock_CTimer_Invalidate(timer);
	return 0;
}

public int Direct_CTimer_HasStarted(Handle plugin, int numParams)
{
	CountdownTimer timer = GetNativeCell(1);
	return Stock_CTimer_HasStarted(timer);
}

public int Direct_CTimer_IsElapsed(Handle plugin, int numParams)
{
	CountdownTimer timer = GetNativeCell(1);
	return Stock_CTimer_IsElapsed(timer);
}

public any Direct_CTimer_GetElapsedTime(Handle plugin, int numParams)
{
	CountdownTimer timer = GetNativeCell(1);
	return Stock_CTimer_GetElapsedTime(timer);
}

public any Direct_CTimer_GetRemainingTime(Handle plugin, int numParams)
{
	CountdownTimer timer = GetNativeCell(1);
	return Stock_CTimer_GetRemainingTime(timer);
}

public any Direct_CTimer_GetCountdownDuration(Handle plugin, int numParams)
{
	CountdownTimer timer = GetNativeCell(1);
	return Stock_CTimer_GetCountdownDuration(timer);
}

public int Direct_ITimer_Reset(Handle plugin, int numParams)
{
	IntervalTimer timer = GetNativeCell(1);
	Stock_ITimer_Reset(timer);
	return 0;
}

public int Direct_ITimer_Start(Handle plugin, int numParams)
{
	IntervalTimer timer = GetNativeCell(1);
	Stock_ITimer_Start(timer);
	return 0;
}

public int Direct_ITimer_Invalidate(Handle plugin, int numParams)
{
	IntervalTimer timer = GetNativeCell(1);
	Stock_ITimer_Invalidate(timer);
	return 0;
}

public int Direct_ITimer_HasStarted(Handle plugin, int numParams)
{
	IntervalTimer timer = GetNativeCell(1);
	return Stock_ITimer_HasStarted(timer);
}

public any Direct_ITimer_GetElapsedTime(Handle plugin, int numParams)
{
	IntervalTimer timer = GetNativeCell(1);
	return Stock_ITimer_GetElapsedTime(timer);
}

/* Timer Internals */
public any Direct_CTimer_GetDuration(Handle plugin, int numParams)
{
	CountdownTimer timer = GetNativeCell(1);
	return Stock_CTimer_GetDuration(timer);
}

public int Direct_CTimer_SetDuration(Handle plugin, int numParams)
{
	CountdownTimer timer = GetNativeCell(1);
	float duration = GetNativeCell(2);
	Stock_CTimer_SetDuration(timer, duration);
	return 0;
}

public any Direct_CTimer_GetTimestamp(Handle plugin, int numParams)
{
	CountdownTimer timer = GetNativeCell(1);
	return Stock_CTimer_GetTimestamp(timer);
}

public int Direct_CTimer_SetTimestamp(Handle plugin, int numParams)
{
	CountdownTimer timer = GetNativeCell(1);
	float timestamp = GetNativeCell(2);
	Stock_CTimer_SetTimestamp(timer, timestamp);
	return 0;
}

public any Direct_ITimer_GetTimestamp(Handle plugin, int numParams)
{
	CountdownTimer timer = GetNativeCell(1);
	return Stock_CTimer_GetTimestamp(timer);
}

public int Direct_ITimer_SetTimestamp(Handle plugin, int numParams)
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
	StoreToAddress(view_as<Address>(timer) + CTIMER_DURATION_OFFSET, view_as<int>(duration), NumberType_Int32);
}

float Stock_CTimer_GetTimestamp(CountdownTimer timer)
{
	return view_as<float>(LoadFromAddress(view_as<Address>(timer) + CTIMER_TIMESTAMP_OFFSET, NumberType_Int32));
}

void Stock_CTimer_SetTimestamp(CountdownTimer timer, float timestamp)
{
	StoreToAddress(view_as<Address>(timer) + CTIMER_TIMESTAMP_OFFSET, view_as<int>(timestamp), NumberType_Int32);
}

float Stock_ITimer_GetTimestamp(IntervalTimer timer)
{
	return view_as<float>(LoadFromAddress(view_as<Address>(timer) + ITIMER_TIMESTAMP_OFFSET, NumberType_Int32));
}

void Stock_ITimer_SetTimestamp(IntervalTimer timer, float timestamp)
{
	StoreToAddress(view_as<Address>(timer) + ITIMER_TIMESTAMP_OFFSET, view_as<int>(timestamp), NumberType_Int32);
}





// ==================================================
// l4d2addresses.txt
// ==================================================
public int Native_CTerrorPlayer_OnVomitedUpon(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_CTerrorPlayer_OnVomitedUpon, "CTerrorPlayer::OnVomitedUpon");

	int client = GetNativeCell(1);
	int attacker = GetNativeCell(2);

	//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_OnVomitedUpon");
	SDKCall(g_hSDK_CTerrorPlayer_OnVomitedUpon, client, attacker, false);

	return 0;
}

public int Native_CTerrorPlayer_OnHitByVomitJar(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateNatives(g_hSDK_CTerrorPlayer_OnHitByVomitJar, "CTerrorPlayer::OnHitByVomitJar");

	int client = GetNativeCell(1);
	int attacker = GetNativeCell(2);

	//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_OnHitByVomitJar");
	SDKCall(g_hSDK_CTerrorPlayer_OnHitByVomitJar, client, attacker, true);

	return 0;
}

public int Native_Infected_OnHitByVomitJar(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateNatives(g_hSDK_Infected_OnHitByVomitJar, "Infected::OnHitByVomitJar");

	int entity = GetNativeCell(1);
	int attacker = GetNativeCell(2);

	//PrintToServer("#### CALL g_hSDK_Infected_OnHitByVomitJar");
	SDKCall(g_hSDK_Infected_OnHitByVomitJar, entity, attacker, true);

	return 0;
}

public int Native_CTerrorPlayer_Fling(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateNatives(g_hSDK_CTerrorPlayer_Fling, "CTerrorPlayer::Fling");

	int client = GetNativeCell(1);
	int attacker = GetNativeCell(2);
	float vDir[3];
	GetNativeArray(3, vDir, 3);

	//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_Fling");
	SDKCall(g_hSDK_CTerrorPlayer_Fling, client, vDir, 76, attacker, 3.0); // 76 is the 'got bounced' animation in L4D2. 3.0 = incapTime, what's this mean?

	return 0;
}

public int Native_CTerrorPlayer_CancelStagger(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_CTerrorPlayer_CancelStagger, "CTerrorPlayer::CancelStagger");

	int client = GetNativeCell(1);

	//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_CancelStagger");
	SDKCall(g_hSDK_CTerrorPlayer_CancelStagger, client);

	return 0;
}

public int Native_CTerrorPlayer_RespawnPlayer(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_CTerrorPlayer_RoundRespawn, "CTerrorPlayer::RoundRespawn");

	int client = GetNativeCell(1);

	//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_RoundRespawn");
	SDKCall(g_hSDK_CTerrorPlayer_RoundRespawn, client);

	return 0;
}

public int Native_CDirector_CreateRescuableSurvivors(Handle plugin, int numParams)
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
	StoreToAddress(g_pDirector + view_as<Address>(g_iOff_m_rescueCheckTimer + 8), view_as<int>(0.0), NumberType_Int32);

	int time = g_hCvar_RescueDeadTime.IntValue;
	g_hCvar_RescueDeadTime.SetInt(0);
	//PrintToServer("#### CALL g_hSDK_CDirector_CreateRescuableSurvivors");
	SDKCall(g_hSDK_CDirector_CreateRescuableSurvivors, g_pDirector);
	g_hCvar_RescueDeadTime.SetInt(time);
}

public int Native_CTerrorPlayer_OnRevived(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_CTerrorPlayer_OnRevived, "CTerrorPlayer::OnRevived");

	int client = GetNativeCell(1);

	//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_OnRevived");
	SDKCall(g_hSDK_CTerrorPlayer_OnRevived, client);

	return 0;
}

public any Native_CTerrorGameRules_GetVersusCompletion(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pGameRules, "g_pGameRules");
	ValidateNatives(g_hSDK_CTerrorGameRules_GetVersusCompletion, "CTerrorGameRules::GetVersusCompletion");

	int client = GetNativeCell(1);

	//PrintToServer("#### CALL g_hSDK_CTerrorGameRules_GetVersusCompletion");
	return SDKCall(g_hSDK_CTerrorGameRules_GetVersusCompletion, g_pGameRules, client);
}

public int Native_CDirectorTacticalServices_GetHighestFlowSurvivor(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_CDirectorTacticalServices_GetHighestFlowSurvivor, "CDirectorTacticalServices::GetHighestFlowSurvivor");

	//PrintToServer("#### CALL g_hSDK_CDirectorTacticalServices_GetHighestFlowSurvivor");
	return SDKCall(g_hSDK_CDirectorTacticalServices_GetHighestFlowSurvivor, 0, 0);
}

public any Native_Infected_GetInfectedFlowDistance(Handle plugin, int numParams)
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

public int Native_CTerrorPlayer_TakeOverZombieBot(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_CTerrorPlayer_TakeOverZombieBot, "CTerrorPlayer::TakeOverZombieBot");

	int client = GetNativeCell(1);
	int target = GetNativeCell(2);

	if( client > 0 && client <= MaxClients && target > 0 && target <= MaxClients &&
		GetClientTeam(client) == 3 && GetClientTeam(target) == 3 &&
		IsFakeClient(client) == false && IsFakeClient(target) == true )
	{
		if( g_bLeft4Dead2 )
		{
			//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_TakeOverZombieBot");
			SDKCall(g_hSDK_CTerrorPlayer_TakeOverZombieBot, client, target);
		}
		else
		{
			// Workaround spawning wrong type, you'll hear another special infected type sound when spawning.
			int zombieClass = GetEntProp(target, Prop_Send, "m_zombieClass");

			//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_TakeOverZombieBot");
			SDKCall(g_hSDK_CTerrorPlayer_TakeOverZombieBot, client, target);
			SetClass(client, zombieClass);
		}
	}

	return 0;
}

public int Native_CTerrorPlayer_ReplaceWithBot(Handle plugin, int numParams)
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

public int Native_CTerrorPlayer_CullZombie(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_CTerrorPlayer_CullZombie, "CTerrorPlayer::CullZombie");

	int client = GetNativeCell(1);

	//PrintToServer("#### CALL g_hSDK_CTerrorPlayer_CullZombie");
	SDKCall(g_hSDK_CTerrorPlayer_CullZombie, client);

	return 0;
}

public int Native_CTerrorPlayer_SetClass(Handle plugin, int numParams)
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

public int Native_CTerrorPlayer_MaterializeFromGhost(Handle plugin, int numParams)
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

public int Native_CTerrorPlayer_BecomeGhost(Handle plugin, int numParams)
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

public int Native_CCSPlayer_State_Transition(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_CCSPlayer_State_Transition, "CCSPlayer::State_Transition");

	int client = GetNativeCell(1);
	int state = GetNativeCell(2);

	//PrintToServer("#### CALL g_hSDK_CCSPlayer_State_Transition");
	SDKCall(g_hSDK_CCSPlayer_State_Transition, client, state);

	return 0;
}

public int Native_CDirector_SwapTeams(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_CDirector_SwapTeams, "CDirector::SwapTeams");

	//PrintToServer("#### CALL g_hSDK_CDirector_SwapTeams");
	SDKCall(g_hSDK_CDirector_SwapTeams, g_pDirector);

	return 0;
}

public int Native_CDirector_AreTeamsFlipped(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_CDirector_AreTeamsFlipped, "CDirector::AreTeamsFlipped");

	//PrintToServer("#### CALL g_hSDK_CDirector_AreTeamsFlipped");
	return SDKCall(g_hSDK_CDirector_AreTeamsFlipped, g_pDirector);
}

public int Native_CDirector_StartRematchVote(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateNatives(g_hSDK_CDirector_StartRematchVote, "CDirector::StartRematchVote");

	//PrintToServer("#### CALL g_hSDK_CDirector_StartRematchVote");
	SDKCall(g_hSDK_CDirector_StartRematchVote, g_pDirector);

	return 0;
}


public int Native_CDirector_FullRestart(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_CDirector_FullRestart, "CDirector::FullRestart");

	//PrintToServer("#### CALL g_hSDK_CDirector_FullRestart");
	SDKCall(g_hSDK_CDirector_FullRestart, g_pDirector);

	return 0;
}

public int Native_CDirectorVersusMode_HideScoreboardNonVirtual(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pVersusMode, "VersusModePtr");
	ValidateNatives(g_hSDK_CDirectorVersusMode_HideScoreboardNonVirtual, "CDirectorVersusMode::HideScoreboardNonVirtual");

	//PrintToServer("#### CALL g_hSDK_CDirectorVersusMode_HideScoreboardNonVirtual");
	SDKCall(g_hSDK_CDirectorVersusMode_HideScoreboardNonVirtual, g_pVersusMode);

	return 0;
}

public int Native_CDirectorScavengeMode_HideScoreboardNonVirtual(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pScavengeMode, "ScavengeModePtr");
	ValidateNatives(g_hSDK_CDirectorScavengeMode_HideScoreboardNonVirtual, "CDirectorScavengeMode::HideScoreboardNonVirtual");

	//PrintToServer("#### CALL g_hSDK_CDirectorScavengeMode_HideScoreboardNonVirtual");
	SDKCall(g_hSDK_CDirectorScavengeMode_HideScoreboardNonVirtual, g_pScavengeMode);

	return 0;
}

public int Native_CDirector_HideScoreboard(Handle plugin, int numParams)
{
	if( !g_bLeft4Dead2 ) ThrowNativeError(SP_ERROR_NOT_RUNNABLE, NATIVE_UNSUPPORTED2);

	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_CDirector_HideScoreboard, "CDirector::HideScoreboard");

	//PrintToServer("#### CALL g_hSDK_CDirector_HideScoreboard");
	SDKCall(g_hSDK_CDirector_HideScoreboard, g_pDirector);

	return 0;
}

public int Native_CDirector_RegisterForbiddenTarget(Handle plugin, int numParams)
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_CDirector_RegisterForbiddenTarget, "CDirector::RegisterForbiddenTarget");

	int entity = GetNativeCell(1);

	//PrintToServer("#### CALL g_hSDK_CDirector_RegisterForbiddenTarget");
	return SDKCall(g_hSDK_CDirector_RegisterForbiddenTarget, g_pDirector, entity);
}

public int Native_CDirector_UnregisterForbiddenTarget(Handle plugin, int numParams)
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_CDirector_UnregisterForbiddenTarget, "CDirector::UnregisterForbiddenTarget");

	int entity = GetNativeCell(1);

	//PrintToServer("#### CALL g_hSDK_CDirector_UnregisterForbiddenTarget");
	SDKCall(g_hSDK_CDirector_UnregisterForbiddenTarget, g_pDirector, entity);

	return 0;
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

public MRESReturn DTR_ZombieManager_SpawnSpecial(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_ZombieManager_SpawnSpecial");
	float a1[3], a2[3];
	int class = DHookGetParam(hParams, 1);
	DHookGetParamVector(hParams, 2, a1);
	DHookGetParamVector(hParams, 3, a2);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_ZombieManager_SpawnSpecial);
	Call_PushCellRef(class);
	Call_PushArray(a1, sizeof(a1));
	Call_PushArray(a2, sizeof(a2));
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	if( aResult == Plugin_Changed )
	{
		DHookSetParam(hParams, 1, class);
		return MRES_ChangedHandled;
	}

	return MRES_Ignored;
}

public MRESReturn DTR_ZombieManager_SpawnBoomer(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_ZombieManager_SpawnBoomer");
	int class = 2;
	return Spawn_SmokerBoomerHunter(class, hReturn, hParams);
}

public MRESReturn DTR_ZombieManager_SpawnHunter(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_ZombieManager_SpawnHunter");
	int class = 3;
	return Spawn_SmokerBoomerHunter(class, hReturn, hParams);
}

public MRESReturn DTR_ZombieManager_SpawnSmoker(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_ZombieManager_SpawnSmoker");
	int class = 1;
	return Spawn_SmokerBoomerHunter(class, hReturn, hParams);
}

MRESReturn Spawn_SmokerBoomerHunter(int zombieClass, Handle hReturn, Handle hParams)
{
	int class = zombieClass;
	float a1[3], a2[3];
	DHookGetParamVector(hParams, 1, a1);
	DHookGetParamVector(hParams, 2, a2);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_ZombieManager_SpawnSpecial);
	Call_PushCellRef(class);
	Call_PushArray(a1, sizeof(a1));
	Call_PushArray(a2, sizeof(a2));
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

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

			DHookSetReturn(hReturn, 0);
			return MRES_Supercede;
		}

		DHookSetParam(hParams, 1, class);
		return MRES_ChangedHandled;
	}

	return MRES_Ignored;
}

public MRESReturn DTR_ZombieManager_SpawnTank(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_ZombieManager_SpawnTank");
	return Spawn_TankWitch(g_hFWD_ZombieManager_SpawnTank, hReturn, hParams);
}

public MRESReturn DTR_ZombieManager_SpawnWitch(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_ZombieManager_SpawnWitch");
	return Spawn_TankWitch(g_hFWD_ZombieManager_SpawnWitch, hReturn, hParams);
}

public MRESReturn DTR_ZombieManager_SpawnWitchBride(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_ZombieManager_SpawnWitchBride");
	return Spawn_TankWitch(g_hFWD_ZombieManager_SpawnWitchBride, hReturn, hParams);
}

MRESReturn Spawn_TankWitch(Handle hForward, Handle hReturn, Handle hParams)
{
	float a1[3], a2[3];
	DHookGetParamVector(hParams, 1, a1);
	DHookGetParamVector(hParams, 2, a2);

	Action aResult = Plugin_Continue;
	Call_StartForward(hForward);
	Call_PushArray(a1, sizeof(a1));
	Call_PushArray(a2, sizeof(a2));
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

// L4D1 Linux clone function detour
/*
public MRESReturn SpawnWitchAreaPre(Handle hReturn, Handle hParams)
{
	return MRES_Ignored;
}
*/

public MRESReturn DTR_ZombieManager_SpawnWitch_Area(Handle hReturn, Handle hParams)
{
	// PrintToServer("##### DTR_ZombieManager_SpawnWitch_Area");
	// From the post hook
	/*
	int entity = DHookGetReturn(hReturn);
	if( entity == 0 ) return MRES_Ignored;

	float a1[3], a2[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", a1);
	DHookGetParamVector(hParams, 2, a2);
	*/

	float a2[3];
	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_ZombieManager_SpawnWitch);
	Call_PushArray(NULL_VECTOR, sizeof(a2));
	Call_PushArray(a2, sizeof(a2));
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		// RemoveEntity(entity); // From the post hook
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public MRESReturn DTR_CTerrorGameRules_ClearTeamScores(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_CTerrorGameRules_ClearTeamScores");
	int value = g_bLeft4Dead2 ? DHookGetParam(hParams, 1) : 0;

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorGameRules_ClearTeamScores);
	Call_PushCell(value);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public MRESReturn DTR_CTerrorGameRules_SetCampaignScores(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_CTerrorGameRules_SetCampaignScores");
	int a1 = DHookGetParam(hParams, 1);
	int a2 = DHookGetParam(hParams, 2);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorGameRules_SetCampaignScores);
	Call_PushCellRef(a1);
	Call_PushCellRef(a2);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	if( aResult == Plugin_Changed )
	{
		DHookSetParam(hParams, 1, a1);
		DHookSetParam(hParams, 2, a2);
		DHookSetReturn(hReturn, 0);
		return MRES_ChangedOverride;
	}

	return MRES_Ignored;
}

public MRESReturn DTR_CTerrorPlayer_RecalculateVersusScore(int pThis, Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_CTerrorPlayer_RecalculateVersusScore");

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorPlayer_RecalculateVersusScore);
	Call_PushCell(pThis);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public MRESReturn DTR_CDirector_OnFirstSurvivorLeftSafeArea(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_CDirector_OnFirstSurvivorLeftSafeArea");
	if( DHookIsNullParam(hParams, 1) ) return MRES_Ignored;

	int value = DHookGetParam(hParams, 1);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CDirector_OnFirstSurvivorLeftSafeArea);
	Call_PushCell(value);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		if( !g_bLeft4Dead2 )
		{
			
			// Remove bool that says not to check if they have left
			ValidateAddress(g_pDirector, "g_pDirector");
			ValidateAddress(g_iOff_m_bFirstSurvivorLeftStartArea, "m_bFirstSurvivorLeftStartArea");
			StoreToAddress(g_pDirector + view_as<Address>(g_iOff_m_bFirstSurvivorLeftStartArea), 0, NumberType_Int8);
		}

		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public MRESReturn DTR_CDirector_MobRushStart(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_CDirector_MobRushStart");
	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CDirector_MobRushStart);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public MRESReturn DTR_ZombieManager_SpawnITMob(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_ZombieManager_SpawnITMob");
	int a1 = DHookGetParam(hParams, 1);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_ZombieManager_SpawnITMob);
	Call_PushCellRef(a1);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	if( aResult == Plugin_Changed )
	{
		DHookSetParam(hParams, 1, a1);
		DHookSetReturn(hReturn, a1);
		return MRES_ChangedHandled;
	}

	return MRES_Ignored;
}

public MRESReturn DTR_ZombieManager_SpawnMob(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_ZombieManager_SpawnMob");
	int a1 = DHookGetParam(hParams, 1);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_ZombieManager_SpawnMob);
	Call_PushCellRef(a1);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	if( aResult == Plugin_Changed )
	{
		DHookSetParam(hParams, 1, a1);
		DHookSetReturn(hReturn, a1);
		return MRES_ChangedHandled;
	}

	return MRES_Ignored;
}

public MRESReturn DTR_CTerrorPlayer_EnterGhostState_Pre(int pThis, Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_CTerrorPlayer_EnterGhostState_Pre");
	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorPlayer_EnterGhostStatePre);
	Call_PushCell(pThis);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public MRESReturn DTR_CTerrorPlayer_EnterGhostState_Post(int pThis, Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_CTerrorPlayer_EnterGhostState_Post");
	Call_StartForward(g_hFWD_CTerrorPlayer_EnterGhostState);
	Call_PushCell(pThis);
	Call_Finish();

	return MRES_Ignored;
}

public MRESReturn DTR_CDirector_IsTeamFull(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_CDirector_IsTeamFull");
	int a1 = DHookGetParam(hParams, 1);
	bool a2 = DHookGetReturn(hReturn);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CDirector_IsTeamFull);
	Call_PushCell(a1);
	Call_PushCellRef(a2);
	Call_Finish(aResult);

	if( aResult == Plugin_Changed )
	{
		DHookSetReturn(hReturn, a2);
		return MRES_ChangedOverride; // Maybe MRES_Supercede can be used
	}

	return MRES_Ignored;
}

public MRESReturn DTR_CTerrorPlayer_GetCrouchTopSpeed_Pre(int pThis, Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_CTerrorPlayer_GetCrouchTopSpeed_Pre");
	return MRES_Ignored;
}

public MRESReturn DTR_CTerrorPlayer_GetCrouchTopSpeed_Post(int pThis, Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_CTerrorPlayer_GetCrouchTopSpeed_Post");
	return GetSpeed(pThis, g_hFWD_CTerrorPlayer_GetCrouchTopSpeed, hReturn);
}

public MRESReturn DTR_CTerrorPlayer_GetRunTopSpeed_Pre(int pThis, Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_CTerrorPlayer_GetRunTopSpeed_Pre");
	return MRES_Ignored;
}

public MRESReturn DTR_CTerrorPlayer_GetRunTopSpeed_Post(int pThis, Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_CTerrorPlayer_GetRunTopSpeed_Post");
	return GetSpeed(pThis, g_hFWD_CTerrorPlayer_GetRunTopSpeed, hReturn);
}

public MRESReturn DTR_CTerrorPlayer_GetWalkTopSpeed_Pre(int pThis, Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_CTerrorPlayer_GetWalkTopSpeed_Pre");
	return MRES_Ignored;
}

public MRESReturn DTR_CTerrorPlayer_GetWalkTopSpeed_Post(int pThis, Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_CTerrorPlayer_GetWalkTopSpeed_Post");
	return GetSpeed(pThis, g_hFWD_CTerrorPlayer_GetWalkTopSpeed, hReturn);
}

MRESReturn GetSpeed(int pThis, Handle hForward, Handle hReturn)
{
	float a2 = DHookGetReturn(hReturn);

	Action aResult = Plugin_Continue;
	Call_StartForward(hForward);
	Call_PushCell(pThis);
	Call_PushFloatRef(a2);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		DHookSetReturn(hReturn, a2);
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public MRESReturn DTR_CDirector_GetScriptValueInt(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_CDirector_GetScriptValueInt");
	static char key[64];
	DHookGetParamString(hParams, 1, key, sizeof(key));
	int a2 = DHookGetParam(hParams, 2);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CDirector_GetScriptValueInt);
	Call_PushString(key);
	Call_PushCellRef(a2);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		DHookSetParam(hParams, 2, a2);
		DHookSetReturn(hReturn, a2);
		return MRES_ChangedOverride;
	}

	return MRES_Ignored;
}

public MRESReturn DTR_CDirector_GetScriptValueFloat(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_CDirector_GetScriptValueFloat");
	static char key[64];
	DHookGetParamString(hParams, 1, key, sizeof(key));
	float a2 = DHookGetParam(hParams, 2);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CDirector_GetScriptValueFloat);
	Call_PushString(key);
	Call_PushFloatRef(a2);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		DHookSetParam(hParams, 2, a2);
		DHookSetReturn(hReturn, a2);
		return MRES_ChangedOverride;
	}

	return MRES_Ignored;
}

public MRESReturn DTR_CDirector_GetScriptValueString(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_CDirector_GetScriptValueString");
	static char a1[128], a2[128], a3[128]; // Don't know how long they should be

	DHookGetParamString(hParams, 1, a1, sizeof(a1));

	if( !DHookIsNullParam(hParams, 2) )
		DHookGetParamString(hParams, 2, a2, sizeof(a2));

	if( !DHookIsNullParam(hParams, 3) )
		DHookGetParamString(hParams, 3, a3, sizeof(a3));

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CDirector_GetScriptValueString);
	Call_PushString(a1);
	Call_PushString(a2);
	Call_PushString(a3);
	Call_Finish(aResult);

	// UNKNOWN - UNABLE TO TRIGGER FOR TEST
	if( aResult == Plugin_Handled )
	{
		DHookSetParamString(hParams, 3, a3);
		DHookSetReturnString(hReturn, a3);
		return MRES_ChangedOverride;
	}

	return MRES_Ignored;
}

public MRESReturn DTR_CTerrorGameRules_HasConfigurableDifficultySetting(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_CTerrorGameRules_HasConfigurableDifficultySetting");
	int a1 = DHookGetReturn(hReturn);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorGameRules_HasConfigurableDifficultySetting);
	Call_PushCellRef(a1);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		DHookSetReturn(hReturn, a1);
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public MRESReturn DTR_CTerrorGameRules_GetSurvivorSet_Pre(Handle hReturn, Handle hParams)
{
	//PrintToServer(DTR_CTerrorGameRules_GetSurvivorSet_Pre);
	return MRES_Ignored;
}

public MRESReturn DTR_CTerrorGameRules_GetSurvivorSet(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_CTerrorGameRules_GetSurvivorSet");
	return SurvivorSet(g_hFWD_CTerrorGameRules_GetSurvivorSet, hReturn);
}

public MRESReturn DTR_CTerrorGameRules_FastGetSurvivorSet_Pre(Handle hReturn, Handle hParams)
{
	//PrintToServer(DTR_CTerrorGameRules_FastGetSurvivorSet_Pre);
	return MRES_Ignored;
}

public MRESReturn DTR_CTerrorGameRules_FastGetSurvivorSet(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_CTerrorGameRules_FastGetSurvivorSet");
	return SurvivorSet(g_hFWD_CTerrorGameRules_FastGetSurvivorSet, hReturn);
}

MRESReturn SurvivorSet(Handle hForward, Handle hReturn)
{
	int a1 = DHookGetReturn(hReturn);

	Action aResult = Plugin_Continue;
	Call_StartForward(hForward);
	Call_PushCellRef(a1);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		DHookSetReturn(hReturn, a1);
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public MRESReturn DTR_CDirectorVersusMode_GetMissionVersusBossSpawning(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_CDirectorVersusMode_GetMissionVersusBossSpawning");
	int plus = !g_bLeft4Dead2;

	float a1 = DHookGetParamObjectPtrVar(hParams, plus + 1, 0, ObjectValueType_Float);
	float a2 = DHookGetParamObjectPtrVar(hParams, plus + 2, 0, ObjectValueType_Float);
	float a3 = DHookGetParamObjectPtrVar(hParams, plus + 3, 0, ObjectValueType_Float);
	float a4 = DHookGetParamObjectPtrVar(hParams, plus + 4, 0, ObjectValueType_Float);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_GetMissionVSBossSpawning);
	Call_PushFloatRef(a1);
	Call_PushFloatRef(a2);
	Call_PushFloatRef(a3);
	Call_PushFloatRef(a4);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	if( aResult == Plugin_Changed )
	{
		DHookSetParamObjectPtrVar(hParams, plus + 1, 0, ObjectValueType_Float, a1);
		DHookSetParamObjectPtrVar(hParams, plus + 2, 0, ObjectValueType_Float, a2);
		DHookSetParamObjectPtrVar(hParams, plus + 3, 0, ObjectValueType_Float, a3);
		DHookSetParamObjectPtrVar(hParams, plus + 4, 0, ObjectValueType_Float, a4);

		if( !g_bLeft4Dead2 )
			DHookSetParamObjectPtrVar(hParams, 6, 0, ObjectValueType_Bool, true);

		DHookSetReturn(hReturn, 1);
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public MRESReturn DTR_ZombieManager_ReplaceTank(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_ZombieManager_ReplaceTank");
	int a1 = DHookGetParam(hParams, 1);
	int a2 = DHookGetParam(hParams, 2);

	Call_StartForward(g_hFWD_ZombieManager_ReplaceTank);
	Call_PushCell(a1);
	Call_PushCell(a2);
	Call_Finish();

	return MRES_Ignored;
}

public MRESReturn DTR_CTankClaw_DoSwing_Pre(int pThis)
{
	// PrintToServer("##### DTR_CTankClaw_DoSwing_Pre");
	int tank = GetEntPropEnt(pThis, Prop_Data, "m_hOwner");

	Call_StartForward(g_hFWD_CTankClaw_DoSwing_Pre);
	Call_PushCell(tank);
	Call_PushCell(pThis);
	Call_Finish();

	return MRES_Ignored;
}

public MRESReturn DTR_CTankClaw_DoSwing_Post(int pThis)
{
	// PrintToServer("##### DTR_CTankClaw_DoSwing_Post");
	int tank = GetEntPropEnt(pThis, Prop_Data, "m_hOwner");

	Call_StartForward(g_hFWD_CTankClaw_DoSwing_Post);
	Call_PushCell(tank);
	Call_PushCell(pThis);
	Call_Finish();

	return MRES_Ignored;
}

public MRESReturn DTR_CTankClaw_GroundPound_Pre(int pThis)
{
	// PrintToServer("##### DTR_CTankClaw_GroundPound_Pre");
	int tank = GetEntPropEnt(pThis, Prop_Data, "m_hOwner");

	Call_StartForward(g_hFWD_CTankClaw_GroundPound_Pre);
	Call_PushCell(tank);
	Call_PushCell(pThis);
	Call_Finish();

	return MRES_Ignored;
}

public MRESReturn DTR_CTankClaw_GroundPound_Post(int pThis)
{
	// PrintToServer("##### DTR_CTankClaw_GroundPound_Post");
	int tank = GetEntPropEnt(pThis, Prop_Data, "m_hOwner");

	Call_StartForward(g_hFWD_CTankClaw_GroundPound_Post);
	Call_PushCell(tank);
	Call_PushCell(pThis);
	Call_Finish();

	return MRES_Ignored;
}

public MRESReturn DTR_CTankClaw_OnPlayerHit_Pre(int pThis, Handle hParams)
{
	//PrintToServer("##### DTR_CTankClaw_OnPlayerHit_Pre");
	int tank = GetEntPropEnt(pThis, Prop_Data, "m_hOwner");
	int target = DHookGetParam(hParams, 1);
	// bool incap = DHookGetParam(hParams, 2); // Unknown usage, always returns "1"

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTankClaw_OnPlayerHit_Pre);
	Call_PushCell(tank);
	Call_PushCell(pThis);
	Call_PushCell(target);
	Call_Finish(aResult);

	// WORKS - Blocks target player being flung
	if( aResult == Plugin_Handled )
	{
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public MRESReturn DTR_CTankClaw_OnPlayerHit_Post(int pThis, Handle hParams)
{
	//PrintToServer("##### DTR_CTankClaw_OnPlayerHit_Post");
	int tank = GetEntPropEnt(pThis, Prop_Data, "m_hOwner");
	int target = DHookGetParam(hParams, 1);
	// bool incap = DHookGetParam(hParams, 2);

	Call_StartForward(g_hFWD_CTankClaw_OnPlayerHit_Post);
	Call_PushCell(tank);
	Call_PushCell(pThis);
	Call_PushCell(target);
	Call_Finish();

	return MRES_Ignored;
}

public MRESReturn DTR_CTankRock_Detonate(int pThis, Handle hParams)
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

public MRESReturn DTR_CTankRock_OnRelease(int pThis, Handle hParams)
{
	//PrintToServer("##### DTR_CTankRock_OnRelease");
	int tank = GetEntPropEnt(pThis, Prop_Data, "m_hThrower");

	float v1[3];
	float v2[3];
	float v3[3];
	float v4[3];

	DHookGetParamVector(hParams, 1, v1); // vPos
	DHookGetParamVector(hParams, 2, v2); // vAng
	DHookGetParamVector(hParams, 3, v3); // vVel
	DHookGetParamVector(hParams, 4, v4); // vRot

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
		DHookSetParamVector(hParams, 1, v1);
		DHookSetParamVector(hParams, 2, v2);
		DHookSetParamVector(hParams, 3, v3);
		DHookSetParamVector(hParams, 4, v4);
		return MRES_ChangedHandled;
	}

	return MRES_Ignored;
}

public MRESReturn DTR_CDirector_TryOfferingTankBot(Handle hReturn, Handle hParams)
{
	// PrintToServer("##### DTR_CDirector_TryOfferingTankBot");
	int a1 = -1, a2;

	if( !DHookIsNullParam(hParams, 1) )
		a1 = DHookGetParam(hParams, 1);

	a2 = DHookGetParam(hParams, 2);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CDirector_TryOfferingTankBot);
	Call_PushCell(a1);
	Call_PushCellRef(a2);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	// UNKNOWN - PROBABLY WORKING
	if( aResult == Plugin_Changed )
	{
		DHookSetParam(hParams, 2, a2);
		DHookSetReturn(hReturn, a2);

		return MRES_ChangedOverride;
	}

	return MRES_Ignored;
}

public MRESReturn DTR_CDirector_TryOfferingTankBot_Clone(Handle hReturn, Handle hParams)
{
	// PrintToServer("##### DTR_CDirector_TryOfferingTankBot_Clone");
	int a1 = -1, a2;

	if( !DHookIsNullParam(hParams, 2) )
		a1 = DHookGetParam(hParams, 2);

	a2 = DHookGetParam(hParams, 3);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CDirector_TryOfferingTankBot);
	Call_PushCell(a1);
	Call_PushCellRef(a2);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	// UNKNOWN - PROBABLY WORKING
	if( aResult == Plugin_Changed )
	{
		DHookSetParam(hParams, 3, a2);

		return MRES_ChangedOverride;
	}

	return MRES_Ignored;
}

public MRESReturn DTR_CThrow_ActivateAbililty(int pThis, Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_CThrow_ActivateAbililty");
	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CThrow_ActivateAbililty);
	Call_PushCell(pThis);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public MRESReturn DTR_CBaseAnimating_SelectWeightedSequence_Pre(int pThis, Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_CBaseAnimating_SelectWeightedSequence_Pre");
	if( pThis < 1 || pThis > MaxClients || !IsClientInGame(pThis) ) return MRES_Ignored; // Ignore weapons etc

	int a1 = DHookGetParam(hParams, 1);
	Action aResult = Plugin_Continue;



	// ANIMATION HOOK
	int index = g_iAnimationHookedClients.FindValue(GetClientUserId(pThis));
	if( index != -1 )
	{
		Call_StartForward(g_hAnimationCallbackPre);
		Call_PushCell(pThis);
		Call_PushCellRef(a1);
		Call_Finish(aResult);

		if( aResult == Plugin_Changed )
		{
			DHookSetParam(hParams, 1, a1);
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
		DHookSetParam(hParams, 1, a1);
		return MRES_ChangedHandled;
	}

	return MRES_Ignored;
}

public MRESReturn DTR_CBaseAnimating_SelectWeightedSequence_Post(int pThis, Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_CBaseAnimating_SelectWeightedSequence_Post");
	if( pThis < 1 || pThis > MaxClients || !IsClientInGame(pThis) ) return MRES_Ignored; // Ignore weapons etc

	int a1 = DHookGetReturn(hReturn);
	Action aResult = Plugin_Continue;



	// ANIMATION HOOK
	int index = g_iAnimationHookedClients.FindValue(GetClientUserId(pThis));
	if( index != -1 )
	{
		Call_StartForward(g_hAnimationCallbackPost);
		Call_PushCell(pThis);
		Call_PushCellRef(a1);
		Call_Finish(aResult);

		if( aResult == Plugin_Changed )
		{
			DHookSetReturn(hReturn, a1);
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
		DHookSetReturn(hReturn, a1);
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public MRESReturn DTR_CTerrorMeleeWeapon_StartMeleeSwing(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_CTerrorMeleeWeapon_StartMeleeSwing");
	int a1 = DHookGetParam(hParams, 1);
	int a2 = DHookGetParam(hParams, 2);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_StartMeleeSwing);
	Call_PushCell(a1);
	Call_PushCell(a2);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public MRESReturn DTR_CTerrorMeleeWeapon_GetDamageForVictim_Pre(int pThis, Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_CTerrorMeleeWeapon_GetDamageForVictim_Pre");
	return MRES_Ignored;
}

public MRESReturn DTR_CTerrorMeleeWeapon_GetDamageForVictim_Post(int pThis, Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_CTerrorMeleeWeapon_GetDamageForVictim_Post");
	int victim = DHookGetParam(hParams, 1);
	if(! IsValidEdict(victim) )
		return MRES_Ignored;

	int client = GetEntPropEnt(pThis, Prop_Send, "m_hOwnerEntity");
	float damage = DHookGetReturn(hReturn);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_GetDamageForVictim);
	Call_PushCell(client);
	Call_PushCell(pThis);
	Call_PushCell(victim);
	Call_PushFloatRef(damage);
	Call_Finish(aResult);

	if( aResult == Plugin_Changed )
	{
		DHookSetReturn(hReturn, damage);
		return MRES_Override;
	}

	if( aResult == Plugin_Handled )
	{
		DHookSetReturn(hReturn, 0.0);
		return MRES_Override;
	}

	return MRES_Ignored;
}

public MRESReturn DTR_CDirectorScriptedEventManager_SendInRescueVehicle(Handle hReturn)
// public MRESReturn DTR_CDirectorScriptedEventManager_SendInRescueVehicle(Handle hParams)
{
	//PrintToServer("##### DTR_CDirectorScriptedEventManager_SendInRescueVehicle");
	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CDirectorScriptedEventManager_SendInRescueVehicle);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		// DHookSetParamObjectPtrVar(hParams, 1, 0, ObjectValueType_Int, 0);
		// DHookSetParamObjectPtrVar(hParams, 1, 1, ObjectValueType_Int, 0);
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public MRESReturn DTR_CDirectorScriptedEventManager_ChangeFinaleStage(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_CDirectorScriptedEventManager_ChangeFinaleStage");
	int a1 = DHookGetParam(hParams, 1);

	static char a2[64];
	if( !DHookIsNullParam(hParams, 2) )
		DHookGetParamString(hParams, 2, a2, sizeof(a2));

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CDirectorScriptedEventManager_ChangeFinaleStage);
	Call_PushCellRef(a1);
	Call_PushString(a2);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	if( aResult == Plugin_Changed )
	{
		DHookSetParam(hParams, 1, a1);
		DHookSetReturn(hReturn, a1);
		return MRES_ChangedOverride;
	}

	return MRES_Ignored;
}

public MRESReturn DTR_CDirectorVersusMode_EndVersusModeRound_Pre(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_CDirectorVersusMode_EndVersusModeRound_Pre");
	if( g_bRoundEnded ) return MRES_Ignored;

	int a1 = DHookGetParam(hParams, 1);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CDirectorVersusMode_EndVersusModeRound_Pre);
	Call_PushCell(a1);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public MRESReturn DTR_CDirectorVersusMode_EndVersusModeRound_Post(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_CDirectorVersusMode_EndVersusModeRound_Post");
	if( g_bRoundEnded ) return MRES_Ignored;
	g_bRoundEnded = true;

	Call_StartForward(g_hFWD_CDirectorVersusMode_EndVersusModeRound_Post);
	Call_Finish();

	return MRES_Ignored;
}

public MRESReturn DTR_CTerrorPlayer_OnLedgeGrabbed(int pThis, Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_CTerrorPlayer_OnLedgeGrabbed");
	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorPlayer_OnLedgeGrabbed);
	Call_PushCell(pThis);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled ) return MRES_Supercede;
	return MRES_Ignored;
}

public MRESReturn DTR_CTerrorPlayer_OnRevived_Pre(int pThis, Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_CTerrorPlayer_OnRevived_Pre");
	return MRES_Ignored;
}

public MRESReturn DTR_CTerrorPlayer_OnRevived_Post(int pThis, Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_CTerrorPlayer_OnRevived_Post");
	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorPlayer_OnRevived_Post);
	Call_PushCell(pThis);
	Call_Finish(aResult);

	return MRES_Ignored;
}

public MRESReturn DTR_CTerrorPlayer_OnStaggered(int pThis, Handle hParams)
{
	//PrintToServer("##### DTR_CTerrorPlayer_OnStaggered");
	int source = -1;

	if( !DHookIsNullParam(hParams, 1) )
		source = DHookGetParam(hParams, 1);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorPlayer_OnStaggered);
	Call_PushCell(pThis);
	Call_PushCell(source);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled ) return MRES_Supercede;
	return MRES_Ignored;
}

public MRESReturn DTR_CTerrorPlayer_OnStaggered_Clone(Handle hParams)
{
	//PrintToServer("##### DTR_CTerrorPlayer_OnStaggered_Clone");
	int target = DHookGetParam(hParams, 1);

	int source = -1;

	if( !DHookIsNullParam(hParams, 2) )
		source = DHookGetParam(hParams, 2);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorPlayer_OnStaggered);
	Call_PushCell(target);
	Call_PushCell(source);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled ) return MRES_Supercede;
	return MRES_Ignored;
}

public MRESReturn DTR_CTerrorPlayer_OnShovedBySurvivor(int pThis, Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_CTerrorPlayer_OnShovedBySurvivor");
	float a2[3];
	int a1 = DHookGetParam(hParams, 1);
	DHookGetParamVector(hParams, 2, a2);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorPlayer_OnShovedBySurvivor);
	Call_PushCell(a1);
	Call_PushCell(pThis);
	Call_PushArray(a2, sizeof(a2));
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public MRESReturn DTR_CTerrorPlayer_OnShovedBySurvivor_Clone(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_CTerrorPlayer_OnShovedBySurvivor_Clone");
	float a3[3];
	int a1 = DHookGetParam(hParams, 1);
	int a2 = DHookGetParam(hParams, 2);
	DHookGetParamVector(hParams, 3, a3);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorPlayer_OnShovedBySurvivor);
	Call_PushCell(a2);
	Call_PushCell(a1);
	Call_PushArray(a3, sizeof(a3));
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public MRESReturn DTR_CTerrorWeapon_OnHit(int weapon, Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_CTerrorWeapon_OnHit");
	bool userCall = DHookGetParam(hParams, 3);
	if( userCall )
	{
		// CTerrorWeapon::OnHit(CGameTrace &, Vector const&, bool)
		// Get target from CGameTrace
		int trace = DHookGetParam(hParams, 1);
		int target = LoadFromAddress(view_as<Address>(trace + 76), NumberType_Int32);
		if( !target ) return MRES_Ignored;

		// Returns entity address, get entity or client index
		target = GetEntityFromAddress(target);
		if( !target ) target = GetClientFromAddress(target);
		if( !target ) return MRES_Ignored;

		// Verify client hitting
		int client = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
		if( client > 0 && client <= MaxClients )
		{
			// Dead stop option - not always correct but should show if hunter was pouncing while punched
			int deadStop;
			if( target > 0 && target <= MaxClients )
			{
				// deadStop = LoadFromAddress(view_as<Address>(target + 16024), NumberType_Int32) > 0;
				deadStop = GetEntProp(target, Prop_Send, "m_isAttemptingToPounce");
			}

			float vec[3];
			DHookGetParamVector(hParams, 2, vec);

			Action aResult = Plugin_Continue;
			Call_StartForward(g_hFWD_CTerrorWeapon_OnHit);
			Call_PushCell(client);
			Call_PushCell(target);
			Call_PushCell(weapon);
			Call_PushArray(vec, sizeof(vec));
			Call_PushCell(deadStop);
			Call_Finish(aResult);

			if( aResult == Plugin_Handled )
			{
				DHookSetReturn(hReturn, 0);
				return MRES_Supercede;
			}
		}
	}
	return MRES_Ignored;
}

public MRESReturn DTR_CTerrorPlayer_OnShovedByPounceLanding(int pThis, Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_CTerrorPlayer_OnShovedByPounceLanding");
	int a1 = DHookGetParam(hParams, 1);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorPlayer_OnShovedByPounceLanding);
	Call_PushCell(pThis);
	Call_PushCell(a1);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		DHookSetReturn(hReturn, 0.0);
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public MRESReturn DTR_CTerrorPlayer_Fling(int pThis, Handle hParams)
{
	//PrintToServer("##### DTR_CTerrorPlayer_Fling");
	float vPos[3];
	int attacker = DHookGetParam(hParams, 3);
	DHookGetParamVector(hParams, 1, vPos);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorPlayer_Fling);
	Call_PushCell(pThis);
	Call_PushCell(attacker);
	Call_PushArray(vPos, sizeof(vPos));
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public MRESReturn DTR_CDeathFallCamera_Enable(int pThis, Handle hParams)
{
	//PrintToServer("##### DTR_CDeathFallCamera_Enable");
	int client = DHookGetParam(hParams, 1);

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

public MRESReturn DTR_CTerrorPlayer_OnFalling_Pre(int pThis, Handle hReturn)
{
	//PrintToServer("##### DTR_CTerrorPlayer_OnFalling_Pre");
	return MRES_Ignored;
}

public MRESReturn DTR_CTerrorPlayer_OnFalling_Post(int pThis, Handle hReturn)
{
	//PrintToServer("##### DTR_CTerrorPlayer_OnFalling_Post");
	Call_StartForward(g_hFWD_CTerrorPlayer_OnFalling_Post);
	Call_PushCell(pThis);
	Call_Finish();

	return MRES_Ignored;
}

public MRESReturn DTR_Tank_EnterStasis_Pre(int pThis, Handle hReturn)
{
	//PrintToServer("##### DTR_Tank_EnterStasis_Pre");
	return MRES_Ignored;
}

public MRESReturn DTR_Tank_EnterStasis_Post(int pThis, Handle hReturn)
{
	//PrintToServer("##### DTR_Tank_EnterStasis_Post");
	Call_StartForward(g_hFWD_Tank_EnterStasis_Post);
	Call_PushCell(pThis);
	Call_Finish();

	return MRES_Ignored;
}

public MRESReturn DTR_Tank_LeaveStasis_Pre(int pThis, Handle hReturn)
{
	//PrintToServer("##### DTR_Tank_LeaveStasis_Pre");
	return MRES_Ignored;
}

public MRESReturn DTR_Tank_LeaveStasis_Post(int pThis, Handle hReturn)
{
	//PrintToServer("##### DTR_Tank_LeaveStasis_Post");
	Call_StartForward(g_hFWD_Tank_LeaveStasis_Post);
	Call_PushCell(pThis);
	Call_Finish();

	return MRES_Ignored;
}

public MRESReturn DTR_CInferno_Spread(int pThis, Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_CInferno_Spread");
	float vPos[3];
	DHookGetParamVector(hParams, 1, vPos);

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
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	if( aResult == Plugin_Changed )
	{
		DHookSetParamVector(hParams, 1, vPos);
		DHookSetReturn(hReturn, 1);
		return MRES_ChangedHandled;
	}

	return MRES_Ignored;
}

public MRESReturn DTR_SurvivorBot_UseHealingItems(int pThis, Handle hReturn, Handle hParams)
// public MRESReturn DTR_SurvivorBot_UseHealingItems(Handle hParams)
{
	//PrintToServer("##### DTR_SurvivorBot_UseHealingItems");
	// int pThis = DHookGetParam(hParams, 2);
	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_SurvivorBot_UseHealingItems);
	Call_PushCell(pThis);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		// DHookSetParamObjectPtrVar(hParams, 1, 0, ObjectValueType_Int, 0);
		// DHookGetParamObjectPtrString(hParams, 1, 1, ObjectValueType_Int, 0);
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public MRESReturn DTR_SurvivorBot_FindScavengeItem_Pre(int pThis, Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_SurvivorBot_FindScavengeItem_Pre");
	return MRES_Ignored;
}

public MRESReturn DTR_SurvivorBot_FindScavengeItem_Post(int pThis, Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_SurvivorBot_FindScavengeItem_Post");
	int a1 = DHookGetReturn(hReturn);
	if( a1 == -1 ) a1 = 0;

	// Scan distance or something? If you find out please let me know, I'm interested. Haven't bothered testing.
	// float a2 = DHookGetParam(hParams, 1);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_SurvivorBot_FindScavengeItem_Post);
	Call_PushCell(pThis);
	Call_PushCellRef(a1);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	if( aResult == Plugin_Changed )
	{
		if( IsValidEntity(a1) )
		{
			DHookSetReturn(hReturn, a1);
			return MRES_ChangedOverride;
		}
	}

	return MRES_Ignored;
}

public MRESReturn DTR_BossZombiePlayerBot_ChooseVictim_Pre(int client, Handle hReturn)
{
	//PrintToServer("##### DTR_BossZombiePlayerBot_ChooseVictim_Pre");
	return MRES_Ignored;
}

public MRESReturn DTR_BossZombiePlayerBot_ChooseVictim_Post(int client, Handle hReturn)
{
	//PrintToServer("##### DTR_BossZombiePlayerBot_ChooseVictim_Post");
	int a1 = DHookGetReturn(hReturn);
	if( a1 == -1 ) a1 = 0;

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_BossZombiePlayerBot_ChooseVictim_Post);
	Call_PushCell(client);
	Call_PushCellRef(a1);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		DHookSetReturn(hReturn, client);
		return MRES_Supercede;
	}

	if( aResult == Plugin_Changed )
	{
		DHookSetReturn(hReturn, a1);
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public MRESReturn DTR_CTerrorPlayer_MaterializeFromGhost_Pre(int client)
{
	//PrintToServer("##### DTR_CTerrorPlayer_MaterializeFromGhost_Pre");

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorPlayer_MaterializeFromGhost_Pre);
	Call_PushCell(client);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public MRESReturn DTR_CTerrorPlayer_MaterializeFromGhost_Post(int client)
{
	//PrintToServer("##### DTR_CTerrorPlayer_MaterializeFromGhost_Post");

	Call_StartForward(g_hFWD_CTerrorPlayer_MaterializeFromGhost_Post);
	Call_PushCell(client);
	Call_Finish();

	return MRES_Ignored;
}

public MRESReturn DTR_CPipeBombProjectile_Create_Pre(Handle hReturn, Handle hParams)
{
	// PrintToServer("##### DTR_CPipeBombProjectile_Create_Pre");

	int client;
	if( !DHookIsNullParam(hParams, 5) )
		client = DHookGetParam(hParams, 5);

	float v1[3];
	float v2[3];
	float v3[3];
	float v4[3];

	DHookGetParamVector(hParams, 1, v1); // vPos
	DHookGetParamVector(hParams, 2, v2); // vAng
	DHookGetParamVector(hParams, 3, v3); // vVel
	DHookGetParamVector(hParams, 4, v4); // vRot

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CPipeBombProjectile_Create_Pre);
	Call_PushCell(client);
	Call_PushArrayEx(v1, sizeof(v1), SM_PARAM_COPYBACK);
	Call_PushArrayEx(v2, sizeof(v2), SM_PARAM_COPYBACK);
	Call_PushArrayEx(v3, sizeof(v3), SM_PARAM_COPYBACK);
	Call_PushArrayEx(v4, sizeof(v4), SM_PARAM_COPYBACK);
	Call_Finish(aResult);

	if( aResult == Plugin_Changed )
	{
		DHookSetParamVector(hParams, 1, v1);
		DHookSetParamVector(hParams, 2, v2);
		DHookSetParamVector(hParams, 3, v3);
		DHookSetParamVector(hParams, 4, v4);
		return MRES_ChangedHandled;
	}

	if( aResult == Plugin_Handled )
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public MRESReturn DTR_CPipeBombProjectile_Create_Post(Handle hReturn, Handle hParams)
{
	// PrintToServer("##### DTR_CPipeBombProjectile_Create_Post");

	int client;
	if( !DHookIsNullParam(hParams, 5) )
		client = DHookGetParam(hParams, 5);

	int entity = DHookGetReturn(hReturn);

	float v1[3];
	float v2[3];
	float v3[3];
	float v4[3];

	DHookGetParamVector(hParams, 1, v1); // vPos
	DHookGetParamVector(hParams, 2, v2); // vAng
	DHookGetParamVector(hParams, 3, v3); // vVel
	DHookGetParamVector(hParams, 4, v4); // vRot

	Call_StartForward(g_hFWD_CPipeBombProjectile_Create_Post);
	Call_PushCell(client);
	Call_PushCell(entity);
	Call_PushArray(v1, sizeof(v1));
	Call_PushArray(v2, sizeof(v2));
	Call_PushArray(v3, sizeof(v3));
	Call_PushArray(v4, sizeof(v4));
	Call_Finish();

	return MRES_Ignored;
}

public MRESReturn DTR_CTerrorPlayer_Extinguish(int client)
{
	// PrintToServer("##### DTR_CTerrorPlayer_Extinguish");

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

public MRESReturn DTR_CBreakableProp_Break_Pre(int pThis, Handle hReturn, Handle hParams)
{
	// PrintToServer("##### DTR_CBreakableProp_Break_Pre");
	return MRES_Ignored;
}

public MRESReturn DTR_CBreakableProp_Break_Post(int pThis, Handle hReturn, Handle hParams)
{
	// PrintToServer("##### DTR_CBreakableProp_Break_Post");

	int entity;
	if( !DHookIsNullParam(hParams, 1) )
		entity = DHookGetParam(hParams, 1);

	Call_StartForward(g_hFWD_CBreakableProp_Break_Post);
	Call_PushCell(pThis);
	Call_PushCell(entity);
	Call_Finish();

	return MRES_Ignored;
}

public MRESReturn DTR_CGasCanEvent_Killed(int pThis, Handle hReturn, Handle hParams)
{
	// PrintToServer("##### DTR_CGasCanEvent_Killed");

	int a1 = DHookGetParamObjectPtrVar(hParams, 1, 48, ObjectValueType_EhandlePtr);
	int a2 = DHookGetParamObjectPtrVar(hParams, 1, 52, ObjectValueType_EhandlePtr);

	Call_StartForward(g_hFWD_CGasCanEvent_Killed);
	Call_PushCell(pThis);
	Call_PushCell(a1);
	Call_PushCell(a2);
	Call_Finish();

	return MRES_Ignored;
}

public MRESReturn DTR_CGasCan_OnActionComplete(int pThis, Handle hReturn, Handle hParams)
{
	// PrintToServer("##### DTR_CGasCan_OnActionComplete");

	int client;
	if( !DHookIsNullParam(hParams, 1) )
		client = DHookGetParam(hParams, 1);

	int nozzle = DHookGetParam(hParams, 2);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CGasCan_OnActionComplete);
	Call_PushCell(client);
	Call_PushCell(pThis);
	Call_PushCell(nozzle);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public MRESReturn DTR_CTerrorPlayer_OnPouncedOnSurvivor(int pThis, Handle hReturn, Handle hParams)
{
	// PrintToServer("##### DTR_CTerrorPlayer_OnPouncedOnSurvivor");

	int target;
	if( !DHookIsNullParam(hParams, 1) )
		target = DHookGetParam(hParams, 1);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorPlayer_OnPouncedOnSurvivor);
	Call_PushCell(target);
	Call_PushCell(pThis);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public MRESReturn DTR_CTerrorPlayer_GrabVictimWithTongue(int pThis, Handle hReturn, Handle hParams)
{
	// PrintToServer("##### DTR_CTerrorPlayer_GrabVictimWithTongue");

	int target;
	if( !DHookIsNullParam(hParams, 1) )
		target = DHookGetParam(hParams, 1);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorPlayer_GrabVictimWithTongue);
	Call_PushCell(target);
	Call_PushCell(pThis);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public MRESReturn DTR_CTerrorPlayer_OnLeptOnSurvivor(int pThis, Handle hReturn, Handle hParams)
{
	// PrintToServer("##### DTR_CTerrorPlayer_OnLeptOnSurvivor");

	int target;
	if( !DHookIsNullParam(hParams, 1) )
		target = DHookGetParam(hParams, 1);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorPlayer_OnLeptOnSurvivor);
	Call_PushCell(target);
	Call_PushCell(pThis);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public MRESReturn DTR_CTerrorPlayer_OnStartCarryingVictim(int pThis, Handle hReturn, Handle hParams)
{
	// PrintToServer("##### DTR_CTerrorPlayer_OnStartCarryingVictim");

	int target;
	if( !DHookIsNullParam(hParams, 1) )
		target = DHookGetParam(hParams, 1);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorPlayer_OnStartCarryingVictim);
	Call_PushCell(target);
	Call_PushCell(pThis);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public MRESReturn DTR_CInsectSwarm_CanHarm(int pThis, Handle hReturn, Handle hParams)
{
	// PrintToServer("##### DTR_CInsectSwarm_CanHarm");

	int spitter = GetEntPropEnt(pThis, Prop_Data, "m_hOwnerEntity");

	int entity;
	if( !DHookIsNullParam(hParams, 1) )
		entity = DHookGetParam(hParams, 1);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CInsectSwarm_CanHarm);
	Call_PushCell(pThis);
	Call_PushCell(spitter);
	Call_PushCell(entity);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public MRESReturn DTR_CTerrorPlayer_OnVomitedUpon(int client, Handle hReturn, Handle hParams)
{
	// PrintToServer("##### DTR_CTerrorPlayer_OnVomitedUpon");

	if( DHookIsNullParam(hParams, 1) ) return MRES_Ignored;

	int a1 = DHookGetParam(hParams, 1);
	int a2 = DHookGetParam(hParams, 2);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorPlayer_OnVomitedUpon);
	Call_PushCell(client);
	Call_PushCellRef(a1);
	Call_PushCellRef(a2);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	if( aResult == Plugin_Changed )
	{
		DHookSetParam(hParams, 1, a1);
		DHookSetParam(hParams, 2, a2);
		return MRES_ChangedHandled;
	}

	return MRES_Ignored;
}

public MRESReturn DTR_CTerrorPlayer_OnHitByVomitJar(int client, Handle hReturn, Handle hParams)
{
	// PrintToServer("##### DTR_CTerrorPlayer_OnHitByVomitJar");

	int a1 = DHookGetParam(hParams, 1);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_CTerrorPlayer_OnHitByVomitJar);
	Call_PushCell(client);
	Call_PushCellRef(a1);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	if( aResult == Plugin_Changed )
	{
		DHookSetParam(hParams, 1, a1);
		return MRES_ChangedHandled;
	}

	return MRES_Ignored;
}

/*
// Removed because it spawns specials at 0,0,0 when modifying any value.
public MRESReturn DTR_ZombieManager_GetRandomPZSpawnPosition(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR_ZombieManager_GetRandomPZSpawnPosition");
	int zombieClass = DHookGetParam(hParams, 1);
	int attempts = DHookGetParam(hParams, 2);

	int client;
	if( !DHookIsNullParam(hParams, 3) )
		client = DHookGetParam(hParams, 3);

	float vecPos[3];
	DHookGetParamVector(hParams, 4, vecPos);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hFWD_GetRandomPZSpawnPos);
	Call_PushCellRef(client);
	Call_PushCellRef(zombieClass);
	Call_PushCellRef(attempts);
	Call_PushArrayEx(vecPos, 3, SM_PARAM_COPYBACK);
	Call_Finish(aResult);

	if( aResult == Plugin_Changed )
	{
		DHookSetParam(hParams, 1, zombieClass);
		DHookSetParam(hParams, 2, attempts);
		if( !DHookIsNullParam(hParams, 3) )
			DHookSetParam(hParams, 3, client);

		// Nothing worked to fix the bug, even though this is a pre-hook it's using the modified value.;
		if( vecPos[0] != 0.0 )
		{
			// DHookSetParamVector(hParams, 4, vecPos);
			DHookSetParamVector(hParams, 4, view_as<float>({0.0, 0.0, 0.0}));
		} else {
			DHookSetParamVector(hParams, 4, view_as<float>({0.0, 0.0, 0.0}));
		}

		return MRES_ChangedHandled;
	}

	return MRES_Ignored;
}
// */

/*
public MRESReturn DTR_InfectedShoved_OnShoved(Handle hReturn, Handle hParams)
{
	int a1 = DHookGetParam(hParams, 1);
	int a2 = DHookGetParam(hParams, 2);

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
public MRESReturn DTR_CBasePlayer_WaterMove_Pre(int pThis, Handle hReturn, Handle hParams)
{
}

public MRESReturn DTR_CBasePlayer_WaterMove_Post(int pThis, Handle hReturn, Handle hParams)
{
	int a1 = DHookGetReturn(hReturn);
	if( a1 )
	{
		Action aResult = Plugin_Continue;
		Call_StartForward(g_hFWD_OnWaterMove);
		Call_PushCell(pThis);
		Call_Finish(aResult);

		if( aResult == Plugin_Handled ) return MRES_Supercede;
	}

	return MRES_Ignored;
}
// */



// ====================================================================================================
//										VSCRIPT WRAPPERS
// ====================================================================================================
public int Native_VS_GetMapNumber(Handle plugin, int numParams)
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

public int Native_VS_HasEverBeenInjured(Handle plugin, int numParams)
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

public any Native_VS_GetAliveDuration(Handle plugin, int numParams)
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

public int Native_VS_IsDead(Handle plugin, int numParams)
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

public int Native_VS_IsDying(Handle plugin, int numParams)
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

public int Native_VS_UseAdrenaline(Handle plugin, int numParams)
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

public int Native_VS_ReviveByDefib(Handle plugin, int numParams)
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

public int Native_VS_ReviveFromIncap(Handle plugin, int numParams)
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

public int Native_VS_GetSenseFlags(Handle plugin, int numParams)
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

public int Native_VS_NavAreaBuildPath(Handle plugin, int numParams)
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

public any Native_VS_NavAreaTravelDistance(Handle plugin, int numParams)
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



// ====================================================================================================
//										VSCRIPT STUFF
// ====================================================================================================
int g_iLogicScript;

bool GetVScriptEntity()
{
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

	#if KILL_VSCRIPT
	RemoveEntity(g_iLogicScript);
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

	#if KILL_VSCRIPT
	RemoveEntity(g_iLogicScript);
	#endif

	// Retrieve value and return to buffer
	g_hCvar_VScriptBuffer.GetString(ret, maxlength);
	g_hCvar_VScriptBuffer.SetString("");

	if( ret[0] == '\x0')
		return false;
	return true;
}



// ====================================================================================================
//										STOCKS - HEALTH
// ====================================================================================================
float GetTempHealth(int client)
{
	float fGameTime = GetGameTime();
	float fHealthTime = GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
	float fHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	fHealth -= (fGameTime - fHealthTime) * g_hCvar_PillsDecay.FloatValue;
	return fHealth < 0.0 ? 0.0 : fHealth;
}

void SetTempHealth(int client, float fHealth)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", fHealth < 0.0 ? 0.0 : fHealth);
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
}



// ====================================================================================================
//										MEMORY HELPERS
// ====================================================================================================
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

// Unused, but here for demonstration and if required
stock void ReadMemoryString(int addr, char[] temp, int size)
{
	bool read = true;
	char byte[1];
	int pos;
	temp[0] = 0;

	while( read )
	{
		byte[0] = LoadFromAddress(view_as<Address>(addr + pos), NumberType_Int8);
		pos++;

		if( pos < size && (IsCharAlpha(byte[0]) || IsCharNumeric(byte[0])) )
		{
			StrCat(temp, size, byte);
		} else {
			return;
		}
	}
}