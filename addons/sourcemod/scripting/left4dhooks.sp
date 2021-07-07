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



#define PLUGIN_VERSION		"1.45"

#define DEBUG				0
// #define DEBUG			1	// Prints addresses + detour info (only use for debugging, slows server down)

#define DETOUR_ALL			0	// Only enable required detours, for public release.
// #define DETOUR_ALL		1	// Enable all detours, for testing.

#define KILL_VSCRIPT		0	// 0=Keep VScript entity after using for "GetVScriptOutput". 1=Kill the entity after use.



/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Left 4 DHooks Direct
*	Author	:	SilverShot
*	Descrp	:	Left 4 Downtown and L4D Direct conversion and merger.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=321696
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.45 (04-Jul-2021)
	- Fixed bad description for "L4D_SetHumanSpec" and "L4D_TakeOverBot" in the Include file.
	- L4D1: Fixed forward "L4D_OnVomitedUpon" crashing. GameData file updated. Thanks to "Crasher_3637" for reporting.

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
	- L4D2: Fixed signatures breaking from "2.2.1.3" game update. Thanks to "Crasher_3637" for fixing.
	- L4D2: Fixed "VanillaModeOffset" in Linux breaking from "2.2.1.3" game update. Thanks to "Accelerator74" for fixing.
	- GameData .txt file updated.

1.38 (28-Apr-2021)
	- Changed native "L4D2_IsReachable" to allow using team 2 and team 4.

1.37 (20-Apr-2021)
	- Removed "RoundRespawn" being used, was for private testing, maybe a future native. Thanks to "Ja-Forces" for reporting.

1.36 (20-Apr-2021)
	- Added optional forward "AP_OnPluginUpdate" from "Autoreload Plugins" by Dragokas, to rescan required detours when loaded plugins change.
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
	- Thanks to "Crasher_3637" for the L4D1 signature.
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
	- Fixed native "L4D_OnFirstSurvivorLeftSafeArea" throwing errors about null pointer.

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
	- Made all natives optional from the include file. Thanks to "Crasher_3637" for requesting.
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
#define MAX_FWD_LEN							32		// Maximum string length of forward names, used for ArrayList.

// ToDo: When using extra-api.ext (or hopefully one day native SM forwards), g_aDetoursHooked will store the number of plugins using each forward
// so we can disable when the value is 0 and not have to check all plugins just to determine if still required.
ArrayList g_aDetoursHooked;					// Identifies if the detour hook is enabled or disabled
ArrayList g_aDetourHandles;					// Stores detour handles to enable/disable as required
ArrayList g_aForwardNames;					// Stores Forward names
ArrayList g_aForwardIndex;					// Stores Detour indexes
ArrayList g_aForceDetours;					// Determines if a detour should be forced on without any forward using it
int g_iCurrentIndex;						// Index for each detour while created
bool g_bCreatedDetours;						// To determine first time creation of detours, or if enabling or disabling
Handle g_hThisPlugin;						// Ignore checking this plugin



// Animation Hook
int g_iAnimationDetourIndex;
ArrayList g_iHookedClients;
ArrayList g_hActivityList;
PrivateForward g_hAnimationCallbackPre;
PrivateForward g_hAnimationCallback;



// Weapons
StringMap g_aWeaponPtrs;					// Stores weapon pointers to retrieve CCSWeaponInfo and CTerrorWeaponInfo data
StringMap g_aWeaponIDs;						// Store weapon IDs to get above pointers
StringMap g_aMeleeIDs;						// Store melee IDs
ArrayList g_aMeleePtrs;						// Stores melee pointers



// FORWARDS
GlobalForward g_hForward_SpawnSpecial;
GlobalForward g_hForward_SpawnTank;
GlobalForward g_hForward_SpawnWitch;
GlobalForward g_hForward_SpawnWitchBride;
GlobalForward g_hForward_ClearTeamScores;
GlobalForward g_hForward_SetCampaignScores;
GlobalForward g_hForward_OnFirstSurvivorLeftSafeArea;
GlobalForward g_hForward_GetScriptValueInt;
GlobalForward g_hForward_GetScriptValueFloat;
GlobalForward g_hForward_GetScriptValueString;
GlobalForward g_hForward_IsTeamFull;
GlobalForward g_hForward_EnterGhostState;
GlobalForward g_hForward_EnterGhostStatePre;
GlobalForward g_hForward_TryOfferingTankBot;
GlobalForward g_hForward_MobRushStart;
GlobalForward g_hForward_SpawnITMob;
GlobalForward g_hForward_SpawnMob;
GlobalForward g_hForward_ShovedBySurvivor;
GlobalForward g_hForward_GetCrouchTopSpeed;
GlobalForward g_hForward_GetRunTopSpeed;
GlobalForward g_hForward_GetWalkTopSpeed;
GlobalForward g_hForward_HasConfigurableDifficulty;
GlobalForward g_hForward_GetSurvivorSet;
GlobalForward g_hForward_FastGetSurvivorSet;
GlobalForward g_hForward_GetMissionVSBossSpawning;
GlobalForward g_hForward_CThrowActivate;
GlobalForward g_hForward_StartMeleeSwing;
GlobalForward g_hForward_SendInRescueVehicle;
GlobalForward g_hForward_ChangeFinaleStage;
GlobalForward g_hForward_EndVersusModeRound;
GlobalForward g_hForward_EndVersusModeRoundPost;
GlobalForward g_hForward_SelectTankAttackPre;
GlobalForward g_hForward_SelectTankAttack;
GlobalForward g_hForward_LedgeGrabbed;
GlobalForward g_hForward_OnRevived;
GlobalForward g_hForward_OnReplaceTank;
GlobalForward g_hForward_OnUseHealingItems;
GlobalForward g_hForward_OnFindScavengeItem;
GlobalForward g_hForward_OnChooseVictim;
GlobalForward g_hForward_OnMaterializeFromGhostPre;
GlobalForward g_hForward_OnMaterializeFromGhost;
GlobalForward g_hForward_OnVomitedUpon;
GlobalForward g_hForward_OnHitByVomitJar;
GlobalForward g_hForward_InfernoSpread;
GlobalForward g_hForward_CTerrorWeapon_OnHit;
GlobalForward g_hForward_OnPlayerStagger;
GlobalForward g_hForward_OnShovedByPounceLanding;
GlobalForward g_hForward_AddonsDisabler;
// GlobalForward g_hForward_GetRandomPZSpawnPos;
// GlobalForward g_hForward_InfectedShoved;
// GlobalForward g_hForward_OnWaterMove;



// NATIVES - SDKCall
// Silvers Natives
Handle g_hSDK_Call_NavAreaTravelDistance;
Handle g_hSDK_Call_GetLastKnownArea;
Handle g_hSDK_Call_Deafen;
Handle g_hSDK_Call_Dissolve;
Handle g_hSDK_Call_OnITExpired;
Handle g_hSDK_Call_AngularVelocity;
Handle g_hSDK_Call_IsReachable;
Handle g_hSDK_Call_HasPlayerControlledZombies;
Handle g_hSDK_Call_PipeBombPrj;
Handle g_hSDK_Call_SpitterPrj;
Handle g_hSDK_Call_OnAdrenalineUsed;
Handle g_hSDK_Call_RoundRespawn;
Handle g_hSDK_Call_SetHumanSpec;
Handle g_hSDK_Call_TakeOverBot;
Handle g_hSDK_Call_CanBecomeGhost;
Handle g_hSDK_Call_AreWanderersAllowed;
Handle g_hSDK_Call_IsFinaleEscapeInProgress;
Handle g_hSDK_Call_ForceNextStage;
Handle g_hSDK_Call_IsTankInPlay;
Handle g_hSDK_Call_GetFurthestSurvivorFlow;
Handle g_hSDK_Call_GetScriptValueInt;
// Handle g_hSDK_Call_GetScriptValueFloat;
// Handle g_hSDK_Call_GetScriptValueString;
Handle g_hSDK_Call_GetRandomPZSpawnPosition;
Handle g_hSDK_Call_GetNearestNavArea;
Handle g_hSDK_Call_FindRandomSpot;
Handle g_hSDK_Call_HasAnySurvivorLeftSafeArea;
Handle g_hSDK_Call_IsAnySurvivorInCheckpoint;
Handle g_hSDK_Call_IsAnySurvivorInStartArea;
Handle SDK_KV_GetString;

// left4downtown.inc
Handle g_hSDK_Call_GetTeamScore;
Handle g_hSDK_Call_RestartScenarioFromVote;
Handle g_hSDK_Call_IsFirstMapInScenario;
Handle g_hSDK_Call_IsMissionFinalMap;
Handle g_hSDK_Call_ResetMobTimer;
Handle g_hSDK_Call_NotifyNetworkStateChanged;
Handle g_hSDK_Call_StaggerPlayer;
Handle g_hSDK_Call_ReplaceTank;
Handle g_hSDK_Call_SendInRescueVehicle;
Handle g_hSDK_Call_ChangeFinaleStage;
Handle g_hSDK_Call_SpawnSpecial;
Handle g_hSDK_Call_SpawnHunter;
Handle g_hSDK_Call_SpawnBoomer;
Handle g_hSDK_Call_SpawnSmoker;
Handle g_hSDK_Call_SpawnTank;
Handle g_hSDK_Call_SpawnWitch;
Handle g_hSDK_Call_SpawnWitchBride;
Handle g_hSDK_Call_GetWeaponInfo;
Handle g_hSDK_Call_GetMeleeInfo;
Handle g_hSDK_Call_TryOfferingTankBot;
Handle g_hSDK_Call_GetNavArea;
Handle g_hSDK_Call_GetFlowDistance;
Handle g_hSDK_Call_DoAnimationEvent;
Handle g_hSDK_Call_LobbyUnreserve;
// Handle g_hSDK_Call_GetCampaignScores;
// Handle g_hSDK_Call_LobbyIsReserved;

// l4d2addresses.txt
Handle g_hSDK_Call_CTerrorPlayer_OnVomitedUpon;
Handle g_hSDK_Call_CTerrorPlayer_OnHitByVomitJar;
Handle g_hSDK_Call_Infected_OnHitByVomitJar;
Handle g_hSDK_Call_Fling;
Handle g_hSDK_Call_CancelStagger;
Handle g_hSDK_Call_CreateRescuableSurvivors;
Handle g_hSDK_Call_OnRevived;
Handle g_hSDK_Call_GetVersusCompletionPlayer;
Handle g_hSDK_Call_GetHighestFlowSurvivor;
Handle g_hSDK_Call_GetInfectedFlowDistance;
Handle g_hSDK_Call_TakeOverZombieBot;
Handle g_hSDK_Call_ReplaceWithBot;
Handle g_hSDK_Call_CullZombie;
Handle g_hSDK_Call_SetClass;
Handle g_hSDK_Call_CreateAbility;
Handle g_hSDK_Call_MaterializeFromGhost;
Handle g_hSDK_Call_BecomeGhost;
Handle g_hSDK_Call_State_Transition;
Handle g_hSDK_Call_SwapTeams;
Handle g_hSDK_Call_AreTeamsFlipped;
Handle g_hSDK_Call_StartRematchVote;
Handle g_hSDK_Call_FullRestart;
Handle g_hSDK_Call_HideVersusScoreboard;
Handle g_hSDK_Call_HideScavengeScoreboard;
Handle g_hSDK_Call_HideScoreboard;
Handle g_hSDK_Call_RegisterForbiddenTarget;
Handle g_hSDK_Call_UnRegisterForbiddenTarget;



// Offsets
// int ClearTeamScore_A;
// int ClearTeamScore_B;
int g_iAddonEclipse1;
int g_iAddonEclipse2;

int VersusStartTimer;
int m_rescueCheckTimer;
int SpawnTimer;
int MobSpawnTimer;
int VersusMaxCompletionScore;
int OnBeginRoundSetupTime;
int ScriptedEventManagerPtr;
int VersusModePtr;
int ScavengeModePtr;
int VanillaModeOffset;
Address VanillaModeAddress;
// Address TeamScoresAddress;

// Various offsets
int m_iTankCount;
int m_iWitchCount;
int m_iCampaignScores;
int m_fTankSpawnFlowPercent;
int m_fWitchSpawnFlowPercent;
int m_iTankPassedCount;
int m_bTankThisRound;
int m_bWitchThisRound;
int OvertimeGraceTimer;
int InvulnerabilityTimer;
int m_iTankTickets;
int m_iShovePenalty;
int m_fNextShoveTime;
int m_preIncapacitatedHealth;
int m_preIncapacitatedHealthBuffer;
int m_maxFlames;
int m_flow;
int m_PendingMobCount;
int m_fMapMaxFlowDistance;
// int m_iClrRender; // NULL PTR - METHOD (kept for demonstration)

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
Address g_pServer;
Address g_pDirector;
Address g_pGameRules;
Address g_pNavMesh;
Address g_pZombieManager;
Address g_pMeleeWeaponInfoStore;
Address g_pWeaponInfoDatabase;



// Other
int g_iClassTank;
bool g_bCheckpoint[MAXPLAYERS+1];
bool g_bRoundEnded;
bool g_bMapStarted;
bool g_bLeft4Dead2;
bool g_bLinuxOS;
ConVar g_hCvarVScriptBuffer;
ConVar g_hCvarAddonsEclipse;
ConVar g_hCvarRescueDeadTime;
ConVar g_hDecayDecay;
ConVar g_hPillsHealth;

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
		strcopy(error, err_max, "This plugin replaces Left4Downtown. Delete the extension to run.");
		return APLRes_SilentFailure;
	}



	// ====================================================================================================
	//									FORWARDS
	// ====================================================================================================
	// FORWARDS
	// List should match the CreateDetour list of forwards.
	g_hForward_SpawnSpecial						= new GlobalForward("L4D_OnSpawnSpecial",						ET_Event, Param_CellByRef, Param_Array, Param_Array);
	g_hForward_SpawnTank						= new GlobalForward("L4D_OnSpawnTank",							ET_Event, Param_Array, Param_Array);
	g_hForward_SpawnWitch						= new GlobalForward("L4D_OnSpawnWitch",							ET_Event, Param_Array, Param_Array);
	g_hForward_MobRushStart						= new GlobalForward("L4D_OnMobRushStart",						ET_Event);
	g_hForward_SpawnITMob						= new GlobalForward("L4D_OnSpawnITMob",							ET_Event, Param_CellByRef);
	g_hForward_SpawnMob							= new GlobalForward("L4D_OnSpawnMob",							ET_Event, Param_CellByRef);
	g_hForward_EnterGhostState					= new GlobalForward("L4D_OnEnterGhostState",					ET_Event, Param_Cell);
	g_hForward_EnterGhostStatePre				= new GlobalForward("L4D_OnEnterGhostStatePre",					ET_Event, Param_Cell);
	g_hForward_IsTeamFull						= new GlobalForward("L4D_OnIsTeamFull",							ET_Event, Param_Cell, Param_CellByRef);
	g_hForward_ClearTeamScores					= new GlobalForward("L4D_OnClearTeamScores",					ET_Event, Param_Cell);
	g_hForward_SetCampaignScores				= new GlobalForward("L4D_OnSetCampaignScores",					ET_Event, Param_CellByRef, Param_CellByRef);
	g_hForward_OnFirstSurvivorLeftSafeArea		= new GlobalForward("L4D_OnFirstSurvivorLeftSafeArea",			ET_Event, Param_Cell);
	g_hForward_GetCrouchTopSpeed				= new GlobalForward("L4D_OnGetCrouchTopSpeed",					ET_Event, Param_Cell, Param_FloatByRef);
	g_hForward_GetRunTopSpeed					= new GlobalForward("L4D_OnGetRunTopSpeed",						ET_Event, Param_Cell, Param_FloatByRef);
	g_hForward_GetWalkTopSpeed					= new GlobalForward("L4D_OnGetWalkTopSpeed",					ET_Event, Param_Cell, Param_FloatByRef);
	g_hForward_GetMissionVSBossSpawning			= new GlobalForward("L4D_OnGetMissionVSBossSpawning",			ET_Event, Param_FloatByRef, Param_FloatByRef, Param_FloatByRef, Param_FloatByRef);
	g_hForward_OnReplaceTank					= new GlobalForward("L4D_OnReplaceTank",						ET_Event, Param_Cell, Param_Cell);
	g_hForward_TryOfferingTankBot				= new GlobalForward("L4D_OnTryOfferingTankBot",					ET_Event, Param_Cell, Param_CellByRef);
	g_hForward_CThrowActivate					= new GlobalForward("L4D_OnCThrowActivate",						ET_Event, Param_Cell);
	g_hForward_SelectTankAttackPre				= new GlobalForward("L4D2_OnSelectTankAttackPre",				ET_Event, Param_Cell, Param_CellByRef);
	g_hForward_SelectTankAttack					= new GlobalForward("L4D2_OnSelectTankAttack",					ET_Event, Param_Cell, Param_CellByRef);
	g_hForward_SendInRescueVehicle				= new GlobalForward("L4D2_OnSendInRescueVehicle",				ET_Event);
	g_hForward_EndVersusModeRound				= new GlobalForward("L4D2_OnEndVersusModeRound",				ET_Event, Param_Cell);
	g_hForward_EndVersusModeRoundPost			= new GlobalForward("L4D2_OnEndVersusModeRound_Post",			ET_Event);
	g_hForward_LedgeGrabbed						= new GlobalForward("L4D_OnLedgeGrabbed",						ET_Event, Param_Cell);
	g_hForward_OnRevived						= new GlobalForward("L4D2_OnRevived",							ET_Event, Param_Cell);
	g_hForward_OnPlayerStagger					= new GlobalForward("L4D2_OnStagger",							ET_Event, Param_Cell, Param_Cell);
	g_hForward_ShovedBySurvivor					= new GlobalForward("L4D_OnShovedBySurvivor",					ET_Event, Param_Cell, Param_Cell, Param_Array);
	g_hForward_CTerrorWeapon_OnHit				= new GlobalForward("L4D2_OnEntityShoved",						ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_Array, Param_Cell);
	g_hForward_OnShovedByPounceLanding			= new GlobalForward("L4D2_OnPounceOrLeapStumble",				ET_Event, Param_Cell, Param_Cell);
	g_hForward_InfernoSpread					= new GlobalForward("L4D2_OnSpitSpread",						ET_Event, Param_Cell, Param_Cell, Param_FloatByRef, Param_FloatByRef, Param_FloatByRef);
	g_hForward_OnUseHealingItems				= new GlobalForward("L4D2_OnUseHealingItems",					ET_Event, Param_Cell);
	g_hForward_OnFindScavengeItem				= new GlobalForward("L4D2_OnFindScavengeItem",					ET_Event, Param_Cell, Param_CellByRef);
	g_hForward_OnChooseVictim					= new GlobalForward("L4D2_OnChooseVictim",						ET_Event, Param_Cell, Param_CellByRef);
	g_hForward_OnMaterializeFromGhostPre		= new GlobalForward("L4D_OnMaterializeFromGhostPre",			ET_Event, Param_Cell);
	g_hForward_OnMaterializeFromGhost			= new GlobalForward("L4D_OnMaterializeFromGhost",				ET_Event, Param_Cell);
	g_hForward_OnVomitedUpon					= new GlobalForward("L4D_OnVomitedUpon",						ET_Event, Param_Cell, Param_CellByRef, Param_CellByRef);
	// g_hForward_InfectedShoved					= new GlobalForward("L4D_OnInfectedShoved",						ET_Event, Param_Cell, Param_Cell);
	// g_hForward_OnWaterMove						= new GlobalForward("L4D2_OnWaterMove",							ET_Event, Param_Cell);
	// g_hForward_GetRandomPZSpawnPos				= new GlobalForward("L4D_OnGetRandomPZSpawnPosition",			ET_Event, Param_CellByRef, Param_CellByRef, Param_CellByRef, Param_Array);

	if( g_bLeft4Dead2 )
	{
		g_hForward_OnHitByVomitJar				= new GlobalForward("L4D2_OnHitByVomitJar",						ET_Event, Param_Cell, Param_CellByRef);
		g_hForward_SpawnWitchBride				= new GlobalForward("L4D2_OnSpawnWitchBride",					ET_Event, Param_Array, Param_Array);
		g_hForward_GetScriptValueInt			= new GlobalForward("L4D_OnGetScriptValueInt",					ET_Event, Param_String, Param_CellByRef);
		g_hForward_GetScriptValueFloat			= new GlobalForward("L4D_OnGetScriptValueFloat",				ET_Event, Param_String, Param_FloatByRef);
		g_hForward_GetScriptValueString			= new GlobalForward("L4D_OnGetScriptValueString",				ET_Event, Param_String, Param_String, Param_String);
		g_hForward_HasConfigurableDifficulty	= new GlobalForward("L4D_OnHasConfigurableDifficulty",			ET_Event, Param_CellByRef);
		g_hForward_GetSurvivorSet				= new GlobalForward("L4D_OnGetSurvivorSet",						ET_Event, Param_CellByRef);
		g_hForward_FastGetSurvivorSet			= new GlobalForward("L4D_OnFastGetSurvivorSet",					ET_Event, Param_CellByRef);
		g_hForward_StartMeleeSwing				= new GlobalForward("L4D_OnStartMeleeSwing",					ET_Event, Param_Cell, Param_Cell);
		g_hForward_ChangeFinaleStage			= new GlobalForward("L4D2_OnChangeFinaleStage",					ET_Event, Param_CellByRef, Param_String);
		g_hForward_AddonsDisabler				= new GlobalForward("L4D2_OnClientDisableAddons",				ET_Event, Param_String);
	}



	// ====================================================================================================
	//									NATIVES
	// L4D1 = 12 [left4downtown] + 43 - 0 (deprecated) [l4d_direct] + 15 [l4d2addresses] + 15 [silvers - mine!] + 4 [anim] = 94
	// L4D2 = 52 [left4downtown] + 62 - 1 (deprecated) [l4d_direct] + 26 [l4d2addresses] + 36 [silvers - mine!] + 4 [anim] = 184
	// ====================================================================================================
	// ANIMATION HOOK
	CreateNative("AnimHookEnable",		 							Native_AnimHookEnable);
	CreateNative("AnimHookDisable",		 							Native_AnimHookDisable);
	CreateNative("AnimGetActivity",		 							Native_AnimGetActivity);
	CreateNative("AnimGetFromActivity",		 						Native_AnimGetFromActivity);



	// =========================
	// Silvers Natives
	// =========================
	CreateNative("L4D_Deafen",		 								Native_Deafen);
	CreateNative("L4D_Dissolve",		 							Native_Dissolve);
	CreateNative("L4D_OnITExpired",		 							Native_OnITExpired);
	CreateNative("L4D_AngularVelocity",		 						Native_AngularVelocity);
	CreateNative("L4D_GetRandomPZSpawnPosition",		 			Native_GetRandomPZSpawnPosition);
	CreateNative("L4D_FindRandomSpot",		 						Native_FindRandomSpot);
	CreateNative("L4D_GetNearestNavArea",		 					Native_GetNearestNavArea);
	CreateNative("L4D_GetLastKnownArea",		 					Native_GetLastKnownarea);
	CreateNative("L4D_HasAnySurvivorLeftSafeArea",		 			Native_HasAnySurvivorLeftSafeArea);
	CreateNative("L4D_IsAnySurvivorInStartArea",		 			Native_IsAnySurvivorInStartArea);
	CreateNative("L4D_IsAnySurvivorInCheckpoint",		 			Native_IsAnySurvivorInCheckpoint);
	CreateNative("L4D_IsInFirstCheckpoint",		 					Native_IsInFirstCheckpoint);
	CreateNative("L4D_IsInLastCheckpoint",		 					Native_IsInLastCheckpoint);
	CreateNative("L4D_HasPlayerControlledZombies",		 			Native_HasPlayerControlledZombies);
	CreateNative("L4D_PipeBombPrj",		 							Native_PipeBombPrj);

	CreateNative("L4D_SetHumanSpec",								Native_SetHumanSpec);
	CreateNative("L4D_TakeOverBot",									Native_TakeOverBot);
	CreateNative("L4D_CanBecomeGhost",								Native_CanBecomeGhost);
	CreateNative("L4D_IsFinaleEscapeInProgress",					Native_IsFinaleEscapeInProgress);

	if( g_bLeft4Dead2 )
	{
		CreateNative("L4D2_AreWanderersAllowed",					Native_AreWanderersAllowed);
		CreateNative("L4D2_GetVScriptOutput",						Native_GetVScriptOutput);
		CreateNative("L4D2_SpitterPrj",		 						Native_SpitterPrj);
		CreateNative("L4D2_UseAdrenaline",		 					Native_OnAdrenalineUsed);
		CreateNative("L4D2_GetCurrentFinaleStage",		 			Native_GetCurrentFinaleStage);
		CreateNative("L4D2_ForceNextStage",		 					Native_ForceNextStage);
		CreateNative("L4D2_IsTankInPlay",		 					Native_IsTankInPlay);
		CreateNative("L4D2_IsReachable",		 					Native_IsReachable);
		CreateNative("L4D2_GetFurthestSurvivorFlow",		 		Native_GetFurthestSurvivorFlow);
		CreateNative("L4D2_GetScriptValueInt",						Native_GetScriptValueInt);
		CreateNative("L4D2_NavAreaTravelDistance",		 			Native_NavAreaTravelDistance);

		CreateNative("L4D2_VScriptWrapper_GetMapNumber",			Native_VS_GetMapNumber);
		CreateNative("L4D2_VScriptWrapper_HasEverBeenInjured",		Native_VS_HasEverBeenInjured);
		CreateNative("L4D2_VScriptWrapper_GetAliveDuration",		Native_VS_GetAliveDuration);
		CreateNative("L4D2_VScriptWrapper_IsDead",					Native_VS_IsDead);
		CreateNative("L4D2_VScriptWrapper_IsDying",					Native_VS_IsDying);
		CreateNative("L4D2_VScriptWrapper_UseAdrenaline",			Native_VS_UseAdrenaline);
		CreateNative("L4D2_VScriptWrapper_ReviveByDefib",			Native_VS_ReviveByDefib);
		CreateNative("L4D2_VScriptWrapper_ReviveFromIncap",			Native_VS_ReviveFromIncap);
		CreateNative("L4D2_VScriptWrapper_GetSenseFlags",			Native_VS_GetSenseFlags);
		CreateNative("L4D2_VScriptWrapper_NavAreaBuildPath",		Native_VS_NavAreaBuildPath);
		CreateNative("L4D2_VScriptWrapper_NavAreaTravelDistance",	Native_VS_NavAreaTravelDistance);
		// CreateNative("L4D2_GetScriptValueFloat",					Native_GetScriptValueFloat); // Only returns default value provided.
		// CreateNative("L4D2_GetScriptValueString",				Native_GetScriptValueString); // Not implemented, probably broken too, request if really required.
	}



	// =========================
	// left4downtown.inc
	// =========================
	// CreateNative("L4D_GetCampaignScores",						Native_GetCampaignScores);
	// CreateNative("L4D_LobbyIsReserved",							Native_LobbyIsReserved);
	CreateNative("L4D_LobbyUnreserve",				 				Native_LobbyUnreserve);
	CreateNative("L4D_RestartScenarioFromVote",		 				Native_RestartScenarioFromVote);
	CreateNative("L4D_IsFirstMapInScenario",						Native_IsFirstMapInScenario);
	CreateNative("L4D_IsMissionFinalMap",							Native_IsMissionFinalMap);
	CreateNative("L4D_NotifyNetworkStateChanged",					Native_NotifyNetworkStateChanged);
	CreateNative("L4D_StaggerPlayer",								Native_StaggerPlayer);
	CreateNative("L4D2_SendInRescueVehicle",						Native_SendInRescueVehicle);
	CreateNative("L4D_ReplaceTank",									Native_ReplaceTank);
	CreateNative("L4D2_SpawnTank",									Native_SpawnTank);
	CreateNative("L4D2_SpawnSpecial",								Native_SpawnSpecial);
	CreateNative("L4D2_SpawnWitch",									Native_SpawnWitch);
	CreateNative("L4D2_GetTankCount",								Native_GetTankCount);
	CreateNative("L4D2_GetWitchCount",								Native_GetWitchCount);

	if( g_bLeft4Dead2 )
	{
		CreateNative("L4D_ScavengeBeginRoundSetupTime", 			Native_ScavengeBeginRoundSetupTime);
		CreateNative("L4D_ResetMobTimer",							Native_ResetMobTimer);
		CreateNative("L4D_GetPlayerSpawnTime",						Native_GetPlayerSpawnTime);
		CreateNative("L4D_GetVersusMaxCompletionScore",				Native_GetVersusMaxCompletionScore);
		CreateNative("L4D_SetVersusMaxCompletionScore",				Native_SetVersusMaxCompletionScore);
		CreateNative("L4D_GetTeamScore",							Native_GetTeamScore);
		CreateNative("L4D_GetMobSpawnTimerRemaining",				Native_GetMobSpawnTimerRemaining);
		CreateNative("L4D_GetMobSpawnTimerDuration",				Native_GetMobSpawnTimerDuration);
		CreateNative("L4D2_ChangeFinaleStage",						Native_ChangeFinaleStage);
		CreateNative("L4D2_SpawnWitchBride",						Native_SpawnWitchBride);

		// l4d2weapons.inc
		CreateNative("L4D2_IsValidWeapon",							Native_IsValidWeapon);
		CreateNative("L4D2_GetIntWeaponAttribute",					Native_GetIntWeaponAttribute);
		CreateNative("L4D2_GetFloatWeaponAttribute",				Native_GetFloatWeaponAttribute);
		CreateNative("L4D2_SetIntWeaponAttribute",					Native_SetIntWeaponAttribute);
		CreateNative("L4D2_SetFloatWeaponAttribute",				Native_SetFloatWeaponAttribute);
		CreateNative("L4D2_GetMeleeWeaponIndex",					Native_GetMeleeWeaponIndex);
		CreateNative("L4D2_GetIntMeleeAttribute",					Native_GetIntMeleeAttribute);
		CreateNative("L4D2_GetFloatMeleeAttribute",					Native_GetFloatMeleeAttribute);
		CreateNative("L4D2_GetBoolMeleeAttribute",					Native_GetBoolMeleeAttribute);
		CreateNative("L4D2_SetIntMeleeAttribute",					Native_SetIntMeleeAttribute);
		CreateNative("L4D2_SetFloatMeleeAttribute",					Native_SetFloatMeleeAttribute);
		CreateNative("L4D2_SetBoolMeleeAttribute",					Native_SetBoolMeleeAttribute);

		// l4d2timers.inc
		CreateNative("L4D2_CTimerReset",							Native_CTimerReset);
		CreateNative("L4D2_CTimerStart",							Native_CTimerStart);
		CreateNative("L4D2_CTimerInvalidate",						Native_CTimerInvalidate);
		CreateNative("L4D2_CTimerHasStarted",						Native_CTimerHasStarted);
		CreateNative("L4D2_CTimerIsElapsed",						Native_CTimerIsElapsed);
		CreateNative("L4D2_CTimerGetElapsedTime",					Native_CTimerGetElapsedTime);
		CreateNative("L4D2_CTimerGetRemainingTime",					Native_CTimerGetRemainingTime);
		CreateNative("L4D2_CTimerGetCountdownDuration",				Native_CTimerGetCountdownDuration);
		CreateNative("L4D2_ITimerStart",							Native_ITimerStart);
		CreateNative("L4D2_ITimerInvalidate",						Native_ITimerInvalidate);
		CreateNative("L4D2_ITimerHasStarted",						Native_ITimerHasStarted);
		CreateNative("L4D2_ITimerGetElapsedTime",					Native_ITimerGetElapsedTime);

		// l4d2director.inc
		CreateNative("L4D2_GetVersusCampaignScores",				Native_GetVersusCampaignScores);
		CreateNative("L4D2_SetVersusCampaignScores",				Native_SetVersusCampaignScores);
		CreateNative("L4D2_GetVersusTankFlowPercent",				Native_GetVersusTankFlowPercent);
		CreateNative("L4D2_SetVersusTankFlowPercent",				Native_SetVersusTankFlowPercent);
		CreateNative("L4D2_GetVersusWitchFlowPercent",				Native_GetVersusWitchFlowPercent);
		CreateNative("L4D2_SetVersusWitchFlowPercent",				Native_SetVersusWitchFlowPercent);
	}



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

	if( g_bLeft4Dead2 )
	{
		CreateNative("L4D2Direct_GetTankCount",						Direct_GetTankCount);
		CreateNative("L4D2Direct_GetMobSpawnTimer",					Direct_GetMobSpawnTimer);
		CreateNative("L4D2Direct_GetSIClassDeathTimer",				Direct_GetSIClassDeathTimer);
		CreateNative("L4D2Direct_GetSIClassSpawnTimer",				Direct_GetSIClassSpawnTimer);
		CreateNative("L4D2Direct_GetVSStartTimer",					Direct_GetVSStartTimer);
		CreateNative("L4D2Direct_GetScavengeRoundSetupTimer",		Direct_GetScavengeRoundSetupTimer);
		CreateNative("L4D2Direct_GetScavengeOvertimeGraceTimer",	Direct_GetScavengeOvertimeGraceTimer);
		CreateNative("L4D2Direct_GetSpawnTimer",					Direct_GetSpawnTimer);
		CreateNative("L4D2Direct_GetShovePenalty",					Direct_GetShovePenalty);
		CreateNative("L4D2Direct_SetShovePenalty",					Direct_SetShovePenalty);
		CreateNative("L4D2Direct_GetNextShoveTime",					Direct_GetNextShoveTime);
		CreateNative("L4D2Direct_SetNextShoveTime",					Direct_SetNextShoveTime);
		CreateNative("L4D2Direct_GetPreIncapHealth",				Direct_GetPreIncapHealth);
		CreateNative("L4D2Direct_SetPreIncapHealth",				Direct_SetPreIncapHealth);
		CreateNative("L4D2Direct_GetPreIncapHealthBuffer",			Direct_GetPreIncapHealthBuffer);
		CreateNative("L4D2Direct_SetPreIncapHealthBuffer",			Direct_SetPreIncapHealthBuffer);
		CreateNative("L4D2Direct_GetInfernoMaxFlames",				Direct_GetInfernoMaxFlames);
		CreateNative("L4D2Direct_SetInfernoMaxFlames",				Direct_SetInfernoMaxFlames);
		CreateNative("L4D2Direct_GetScriptedEventManager",			Direct_GetScriptedEventManager);
	}



	// =========================
	// l4d2addresses.txt
	// =========================
	CreateNative("L4D_CTerrorPlayer_OnVomitedUpon",					Native_CTerrorPlayer_OnVomitedUpon);
	CreateNative("L4D_CancelStagger",								Native_CancelStagger);
	CreateNative("L4D_RespawnPlayer",								Native_RespawnPlayer);
	CreateNative("L4D_CreateRescuableSurvivors",					Native_CreateRescuableSurvivors);
	CreateNative("L4D_ReviveSurvivor",								Native_OnRevived);
	CreateNative("L4D_GetHighestFlowSurvivor",						Native_GetHighestFlowSurvivor);
	CreateNative("L4D_GetInfectedFlowDistance",						Native_GetInfectedFlowDistance);
	CreateNative("L4D_TakeOverZombieBot",							Native_TakeOverZombieBot);
	CreateNative("L4D_ReplaceWithBot",								Native_ReplaceWithBot);
	CreateNative("L4D_CullZombie",									Native_CullZombie);
	CreateNative("L4D_SetClass",									Native_SetClass);
	CreateNative("L4D_MaterializeFromGhost",						Native_MaterializeFromGhost);
	CreateNative("L4D_BecomeGhost",									Native_BecomeGhost);
	CreateNative("L4D_State_Transition",							Native_State_Transition);
	CreateNative("L4D_RegisterForbiddenTarget",						Native_RegisterForbiddenTarget);
	CreateNative("L4D_UnRegisterForbiddenTarget",					Native_UnRegisterForbiddenTarget);

	if( g_bLeft4Dead2 )
	{
		CreateNative("L4D2_CTerrorPlayer_OnHitByVomitJar",			Native_CTerrorPlayer_OnHitByVomitJar);
		CreateNative("L4D2_Infected_OnHitByVomitJar",				Native_Infected_OnHitByVomitJar);
		CreateNative("L4D2_CTerrorPlayer_Fling",					Native_CTerrorPlayer_Fling);
		CreateNative("L4D2_GetVersusCompletionPlayer",				Native_GetVersusCompletionPlayer);
		CreateNative("L4D2_SwapTeams",								Native_SwapTeams);
		CreateNative("L4D2_AreTeamsFlipped",						Native_AreTeamsFlipped);
		CreateNative("L4D2_StartRematchVote",						Native_StartRematchVote);
		CreateNative("L4D2_FullRestart",							Native_FullRestart);
		CreateNative("L4D2_HideVersusScoreboard",					Native_HideVersusScoreboard);
		CreateNative("L4D2_HideScavengeScoreboard",					Native_HideScavengeScoreboard);
		CreateNative("L4D2_HideScoreboard",							Native_HideScoreboard);
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	// ====================================================================================================
	//									SETUP
	// ====================================================================================================
	g_iClassTank = g_bLeft4Dead2 ? 8 : 5;



	// Animation Hook
	g_hActivityList = new ArrayList(ByteCountToCells(64));
	ParseActivityConfig();

	g_iHookedClients = new ArrayList();
	g_hAnimationCallbackPre = new PrivateForward(ET_Event, Param_Cell, Param_CellByRef);
	g_hAnimationCallback = new PrivateForward(ET_Event, Param_Cell, Param_CellByRef);


	// NULL PTR - METHOD (kept for demonstration)
	// Null pointer - by Dragokas
	/*
	m_iClrRender = FindSendPropInfo("CBaseEntity", "m_clrRender");
	if( m_iClrRender == -1 )
	{
		SetFailState("Error: m_clrRender not found.");
	}
	*/



	// Weapon IDs
	g_aWeaponPtrs = new StringMap();
	g_aWeaponIDs = new StringMap();

	if( !g_bLeft4Dead2 )
	{
		// UNUSED, UNKNOWN OFFSETS FOR WEAPON DATA
		// g_aWeaponIDs.SetValue("weapon_none",						0);
		// g_aWeaponIDs.SetValue("weapon_pistol",						1);
		// g_aWeaponIDs.SetValue("weapon_smg",							2);
		// g_aWeaponIDs.SetValue("weapon_pumpshotgun",					3);
		// g_aWeaponIDs.SetValue("weapon_autoshotgun",					4);
		// g_aWeaponIDs.SetValue("weapon_rifle",						5);
		// g_aWeaponIDs.SetValue("weapon_hunting_rifle",				6);
		// g_aWeaponIDs.SetValue("weapon_first_aid_kit",				8);
		// g_aWeaponIDs.SetValue("weapon_molotov",						9);
		// g_aWeaponIDs.SetValue("weapon_pipe_bomb",					10);
		// g_aWeaponIDs.SetValue("weapon_pain_pills",					12);
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
	AddMultiTargetFilter("@incappedsurvivorbot",		FilterRandomE,	"Random Incapped Survivor Bot", false);
	AddMultiTargetFilter("@isb",						FilterRandomE,	"Random Incapped Survivor Bot", false);
	AddMultiTargetFilter("@survivorbot",				FilterRandomF,	"Random Survivor Bot", false);
	AddMultiTargetFilter("@sb",							FilterRandomF,	"Random Survivor Bot", false);
	AddMultiTargetFilter("@infectedbot",				FilterRandomG,	"Random Infected Bot", false);
	AddMultiTargetFilter("@ib",							FilterRandomG,	"Random Infected Bot", false);
	AddMultiTargetFilter("@tankbot",					FilterRandomH,	"Random Tank Bot", false);
	AddMultiTargetFilter("@tb",							FilterRandomH,	"Random Tank Bot", false);

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
		g_hCvarVScriptBuffer = CreateConVar("l4d2_vscript_return", "", "Buffer used to return VScript values. Do not use.", FCVAR_DONTRECORD);
		g_hCvarAddonsEclipse = CreateConVar("l4d2_addons_eclipse", "-1", "Addons Manager (-1: use addonconfig; 0: disable addons; 1: enable addons.)", FCVAR_NOTIFY);
		g_hCvarAddonsEclipse.AddChangeHook(ConVarChanged_Cvars);

		g_hDecayDecay = FindConVar("pain_pills_decay_rate");
		g_hPillsHealth = FindConVar("pain_pills_health_value");
	}

	g_hCvarRescueDeadTime = FindConVar("rescue_min_dead_time");



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
	g_bMapStarted = false;

	// Reset hooks
	g_iHookedClients.Clear();

	// Remove all hooked functions from private forward
	Handle hIter = GetPluginIterator();
	Handle hPlug;

	// Iterate plugins
	while( MorePlugins(hIter) )
	{
		hPlug = ReadPlugin(hIter);
		g_hAnimationCallbackPre.RemoveAllFunctions(hPlug);
		g_hAnimationCallback.RemoveAllFunctions(hPlug);
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
		DHookEnableDetour(hDetour, false, SelectTankAttackPre);
		DHookEnableDetour(hDetour, true, SelectTankAttack);
	}

	// Add callback
	if( GetNativeFunction(2) != INVALID_FUNCTION ) g_hAnimationCallbackPre.AddFunction(plugin, GetNativeFunction(2));
	if( GetNativeFunction(3) != INVALID_FUNCTION ) g_hAnimationCallback.AddFunction(plugin, GetNativeFunction(3));
	g_iHookedClients.Push(GetClientUserId(client));
	return true;
}

public int Native_AnimHookDisable(Handle plugin, int numParams)
{
	// Remove callback
	if( GetNativeFunction(2) != INVALID_FUNCTION ) g_hAnimationCallbackPre.RemoveFunction(plugin, GetNativeFunction(2));
	if( GetNativeFunction(3) != INVALID_FUNCTION ) g_hAnimationCallback.RemoveFunction(plugin, GetNativeFunction(3));

	// Validate client
	int client = GetNativeCell(1);
	if( !client || !IsClientInGame(client) ) return true; // Disconnected
	client = GetClientUserId(client);

	// Remove client from checking array
	int index = g_iHookedClients.FindValue(client);
	if( index != -1 )
	{
		g_iHookedClients.Erase(index);
		return true;
	}
	return false;
}

public int Native_AnimGetActivity(Handle plugin, int numParams)
{
	int sequence = GetNativeCell(1);
	int maxlength = GetNativeCell(3);
	char[] activity = new char[maxlength];

	if( g_hActivityList.GetString(sequence, activity, maxlength) )
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

	int sequence = g_hActivityList.FindString(activity);
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
	g_hActivityList.PushString(key);
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

// Specific survivors
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

// Filter all Infected
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


// Filter - Random Incapped Survivors
public bool FilterRandomA(const char[] pattern, Handle clients)
{
	ArrayList aList = new ArrayList();

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && GetEntProp(i, Prop_Send, "m_isIncapacitated", 1) )
		{
			aList.Push(i);
		}
	}

	PushArrayCell(clients, aList.Get(GetRandomInt(0, aList.Length - 1)));

	delete aList;

	return true;
}

// Filter - Random Survivors
public bool FilterRandomB(const char[] pattern, Handle clients)
{
	ArrayList aList = new ArrayList();

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 2 )
		{
			aList.Push(i);
		}
	}

	PushArrayCell(clients, aList.Get(GetRandomInt(0, aList.Length - 1)));

	delete aList;

	return true;
}

// Filter - Random Infected
public bool FilterRandomC(const char[] pattern, Handle clients)
{
	ArrayList aList = new ArrayList();

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 3 )
		{
			aList.Push(i);
		}
	}

	PushArrayCell(clients, aList.Get(GetRandomInt(0, aList.Length - 1)));

	delete aList;

	return true;
}

// Filter - Random Tank
public bool FilterRandomD(const char[] pattern, Handle clients)
{
	ArrayList aList = new ArrayList();

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i) && GetEntProp(i, Prop_Send, "m_zombieClass") == g_iClassTank )
		{
			aList.Push(i);
		}
	}

	PushArrayCell(clients, aList.Get(GetRandomInt(0, aList.Length - 1)));

	delete aList;

	return true;
}

// Filter - Random Incapped Survivor Bot
public bool FilterRandomE(const char[] pattern, Handle clients)
{
	ArrayList aList = new ArrayList();

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && IsFakeClient(i) && GetEntProp(i, Prop_Send, "m_isIncapacitated", 1) )
		{
			aList.Push(i);
		}
	}

	PushArrayCell(clients, aList.Get(GetRandomInt(0, aList.Length - 1)));

	delete aList;

	return true;
}

// Filter - Random Survivor Bot
public bool FilterRandomF(const char[] pattern, Handle clients)
{
	ArrayList aList = new ArrayList();

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && IsFakeClient(i) )
		{
			aList.Push(i);
		}
	}

	PushArrayCell(clients, aList.Get(GetRandomInt(0, aList.Length - 1)));

	delete aList;

	return true;
}

// Filter - Random Infected Bot
public bool FilterRandomG(const char[] pattern, Handle clients)
{
	ArrayList aList = new ArrayList();

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i) && IsFakeClient(i) )
		{
			aList.Push(i);
		}
	}

	PushArrayCell(clients, aList.Get(GetRandomInt(0, aList.Length - 1)));

	delete aList;

	return true;
}

// Filter - Random Tank Bot
public bool FilterRandomH(const char[] pattern, Handle clients)
{
	ArrayList aList = new ArrayList();

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i) && IsFakeClient(i) && GetEntProp(i, Prop_Send, "m_zombieClass") == g_iClassTank )
		{
			aList.Push(i);
		}
	}

	PushArrayCell(clients, aList.Get(GetRandomInt(0, aList.Length - 1)));

	delete aList;

	return true;
}

// Specific Infected
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



// ====================================================================================================
//										DISABLE ADDONS
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
	RemoveMultiTargetFilter("@incappedsurvivorbot",		FilterRandomE);
	RemoveMultiTargetFilter("@isb",						FilterRandomE);
	RemoveMultiTargetFilter("@survivorbot",				FilterRandomF);
	RemoveMultiTargetFilter("@sb",						FilterRandomF);
	RemoveMultiTargetFilter("@infectedbot",				FilterRandomG);
	RemoveMultiTargetFilter("@ib",						FilterRandomG);
	RemoveMultiTargetFilter("@tankbot",					FilterRandomH);
	RemoveMultiTargetFilter("@tb",						FilterRandomH);

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

public void OnConfigsExecuted()
{
	if( g_bLeft4Dead2 )
		ConVarChanged_Cvars(null, "", "");
}

bool g_bAddonsPatched;

public void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	if( g_hCvarAddonsEclipse.IntValue > -1 )
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
		AddonsDisabler_Restore[0] = LoadFromAddress(VanillaModeAddress + view_as<Address>(VanillaModeOffset), NumberType_Int8);
		AddonsDisabler_Restore[1] = LoadFromAddress(VanillaModeAddress + view_as<Address>(VanillaModeOffset + 1), NumberType_Int8);
		AddonsDisabler_Restore[2] = LoadFromAddress(VanillaModeAddress + view_as<Address>(VanillaModeOffset + 2), NumberType_Int8);
	}

	//PrintToServer("Addons restore: %02x%02x%02x", AddonsDisabler_Restore[0], AddonsDisabler_Restore[1], AddonsDisabler_Restore[2]);
	StoreToAddress(VanillaModeAddress + view_as<Address>(VanillaModeOffset), 0x0F, NumberType_Int8);
	StoreToAddress(VanillaModeAddress + view_as<Address>(VanillaModeOffset + 1), 0x1F, NumberType_Int8);
	StoreToAddress(VanillaModeAddress + view_as<Address>(VanillaModeOffset + 2), 0x00, NumberType_Int8);
}

void AddonsDisabler_Unpatch()
{
	if( g_bAddonsPatched )
	{
		g_bAddonsPatched = false;
		StoreToAddress(VanillaModeAddress + view_as<Address>(VanillaModeOffset), AddonsDisabler_Restore[0], NumberType_Int8);
		StoreToAddress(VanillaModeAddress + view_as<Address>(VanillaModeOffset + 1), AddonsDisabler_Restore[1], NumberType_Int8);
		StoreToAddress(VanillaModeAddress + view_as<Address>(VanillaModeOffset + 2), AddonsDisabler_Restore[2], NumberType_Int8);
	}
}



// ====================================================================================================
//										ADDONS DISABLER DETOUR
// ====================================================================================================
public MRESReturn AddonsDisabler(int pThis, Handle hReturn, Handle hParams)
{
	// Details on finding offsets can be found here: https://github.com/ProdigySim/left4dhooks/pull/1
	// Big thanks to "ProdigySim" for updating for The Last Stand update.

	#if DEBUG
	PrintToServer("##### DTR AddonsDisabler");
	#endif

	int cvar = g_hCvarAddonsEclipse.IntValue;
	if( cvar != -1 )
	{
		int ptr = DHookGetParam(hParams, 1);

		// This is `m_nPlayerSlot` on the `SVC_ServerInfo`.
		// It represents the client index of the connecting user.
		int playerSlot = LoadFromAddress(view_as<Address>(ptr + g_iAddonEclipse1), NumberType_Int8);
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
			Call_StartForward(g_hForward_AddonsDisabler);
			Call_PushString(netID);
			Call_Finish(aResult);

			// 1 to tell the client it should use "vanilla mode"--no addons. 0 to enable addons.
			int bVanillaMode =  aResult == Plugin_Handled ? 0 : view_as<int>(!cvar);
			StoreToAddress(view_as<Address>(ptr + g_iAddonEclipse2), bVanillaMode, NumberType_Int8);
			
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
// Forward from "[DEV] Autoreload Plugins" by "Dragokas"
public void AP_OnPluginUpdate(int pre) 
{
	if( pre == 0 )
	{
		CheckRequiredDetours();
	}
}

public Action CmdLobby(int client, int args)
{
	Native_LobbyUnreserve(null, 0);
}

public Action CmdDetours(int client, int args)
{
	CheckRequiredDetours(client + 1);
	return Plugin_Handled;
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
		g_aForwardIndex = new ArrayList();
		g_aForceDetours = new ArrayList();
		g_aForwardNames = new ArrayList(ByteCountToCells(MAX_FWD_LEN));
	}

	g_iCurrentIndex = 0;



	// Forwards listed here must match forward list in plugin start.
	//			 GameData	DHookCallback PRE					DHookCallback POST		Signature Name							Forward Name				useLast index		forceOn detour
	CreateDetour(hGameData, SpawnTank,							INVALID_FUNCTION,		"SpawnTank",							"L4D_OnSpawnTank");
	CreateDetour(hGameData, SpawnWitch,							INVALID_FUNCTION,		"SpawnWitch",							"L4D_OnSpawnWitch");
	CreateDetour(hGameData, MobRushStart,						INVALID_FUNCTION,		"OnMobRushStart",						"L4D_OnMobRushStart");
	CreateDetour(hGameData, SpawnITMob,							INVALID_FUNCTION,		"SpawnITMob",							"L4D_OnSpawnITMob");
	CreateDetour(hGameData, SpawnMob,							INVALID_FUNCTION,		"SpawnMob",								"L4D_OnSpawnMob");
	CreateDetour(hGameData, EnterGhostStatePre,					EnterGhostState,		"OnEnterGhostState",					"L4D_OnEnterGhostState");
	CreateDetour(hGameData, EnterGhostStatePre,					EnterGhostState,		"OnEnterGhostState",					"L4D_OnEnterGhostStatePre", true); // Different forwards, same detour as above - same index.
	CreateDetour(hGameData, IsTeamFullPre,						INVALID_FUNCTION,		"IsTeamFull",							"L4D_OnIsTeamFull");
	CreateDetour(hGameData, ClearTeamScores,					INVALID_FUNCTION,		"ClearTeamScores",						"L4D_OnClearTeamScores");
	CreateDetour(hGameData, SetCampaignScores,					INVALID_FUNCTION,		"SetCampaignScores",					"L4D_OnSetCampaignScores");
	CreateDetour(hGameData, OnFirstSurvivorLeftSafeArea,		INVALID_FUNCTION,		"OnFirstSurvivorLeftSafeArea",			"L4D_OnFirstSurvivorLeftSafeArea");
	CreateDetour(hGameData, GetCrouchTopSpeedPre,				GetCrouchTopSpeed,		"GetCrouchTopSpeed",					"L4D_OnGetCrouchTopSpeed");
	CreateDetour(hGameData, GetRunTopSpeedPre,					GetRunTopSpeed,			"GetRunTopSpeed",						"L4D_OnGetRunTopSpeed");
	CreateDetour(hGameData, GetWalkTopSpeedPre,					GetWalkTopSpeed,		"GetWalkTopSpeed",						"L4D_OnGetWalkTopSpeed");
	CreateDetour(hGameData, GetMissionVSBoss,					INVALID_FUNCTION,		"GetMissionVersusBossSpawning",			"L4D_OnGetMissionVSBossSpawning");
	CreateDetour(hGameData, OnReplaceTank,						INVALID_FUNCTION,		"ReplaceTank",							"L4D_OnReplaceTank");
	CreateDetour(hGameData, TryOfferingTankBot,					INVALID_FUNCTION,		"TryOfferingTankBot",					"L4D_OnTryOfferingTankBot");
	CreateDetour(hGameData, CThrowActivate,						INVALID_FUNCTION,		"CThrowActivate",						"L4D_OnCThrowActivate");
	g_iAnimationDetourIndex = g_iCurrentIndex; // Animation Hook - detour index to enable when required.
	CreateDetour(hGameData, SelectTankAttackPre,				SelectTankAttack,		"SelectTankAttack",						"L4D2_OnSelectTankAttack"); // Animation Hook
	CreateDetour(hGameData, SelectTankAttackPre,				SelectTankAttack,		"SelectTankAttack",						"L4D2_OnSelectTankAttackPre", true); // Animation Hook
	if( !g_bLinuxOS ) // Blocked on Linux in L4D1/L4D2 to prevent crashes. Waiting for DHooks update to support object returns.
	CreateDetour(hGameData, SendInRescueVehicle,				INVALID_FUNCTION,		"SendInRescueVehicle",					"L4D2_OnSendInRescueVehicle");
	CreateDetour(hGameData, EndVersusModeRoundPre,				EndVersusModeRound,		"EndVersusModeRound",					"L4D2_OnEndVersusModeRound");
	CreateDetour(hGameData,	EndVersusModeRoundPre,				EndVersusModeRound,		"EndVersusModeRound",					"L4D2_OnEndVersusModeRound_Post", true); // Different forwards, same detour as above - same index.
	CreateDetour(hGameData, LedgeGrabbed,						INVALID_FUNCTION,		"OnLedgeGrabbed",						"L4D_OnLedgeGrabbed");
	CreateDetour(hGameData, OnRevivedPre,						OnRevived,				"OnRevived",							"L4D2_OnRevived");
	CreateDetour(hGameData, OnPlayerStagger,					INVALID_FUNCTION,		"OnStaggered",							"L4D2_OnStagger");
	CreateDetour(hGameData, ShovedBySurvivor,					INVALID_FUNCTION,		"OnShovedBySurvivor",					"L4D_OnShovedBySurvivor");
	CreateDetour(hGameData, CTerrorWeapon_OnHit,				INVALID_FUNCTION,		"OnHit",								"L4D2_OnEntityShoved");
	CreateDetour(hGameData, OnShovedByPounceLanding,			INVALID_FUNCTION,		"OnShovedByPounceLanding",				"L4D2_OnPounceOrLeapStumble");
	CreateDetour(hGameData, InfernoSpread,						INVALID_FUNCTION,		"Spread",								"L4D2_OnSpitSpread");
	if( !g_bLinuxOS ) // Blocked on Linux in L4D1/L4D2 to prevent crashes. Waiting for DHooks update to support object returns.
	CreateDetour(hGameData, OnUseHealingItems,					INVALID_FUNCTION,		"UseHealingItems",						"L4D2_OnUseHealingItems");
	CreateDetour(hGameData, OnFindScavengeItemPre,				OnFindScavengeItem,		"FindScavengeItem",						"L4D2_OnFindScavengeItem");
	CreateDetour(hGameData, OnChooseVictimPre,					OnChooseVictim,			"ChooseVictim",							"L4D2_OnChooseVictim");
	CreateDetour(hGameData, OnMaterializeFromGhostPre,			OnMaterialize,			"OnMaterializeFromGhost",				"L4D_OnMaterializeFromGhostPre");
	CreateDetour(hGameData, OnMaterializeFromGhostPre,			OnMaterialize,			"OnMaterializeFromGhost",				"L4D_OnMaterializeFromGhost", true);
	CreateDetour(hGameData, OnVomitedUpon,						INVALID_FUNCTION,		"OnVomitedUpon",						"L4D_OnVomitedUpon");

	if( !g_bLeft4Dead2 )
	{
		// Different detours, same forward (SpawnSpecial).
		CreateDetour(hGameData, SpawnHunter,					INVALID_FUNCTION,		"SpawnHunter",							"L4D_OnSpawnSpecial");
		CreateDetour(hGameData, SpawnBoomer,					INVALID_FUNCTION,		"SpawnBoomer",							"L4D_OnSpawnSpecial");
		CreateDetour(hGameData, SpawnSmoker,					INVALID_FUNCTION,		"SpawnSmoker",							"L4D_OnSpawnSpecial");
	}
	else
	{
		CreateDetour(hGameData, OnHitByVomitJar,				INVALID_FUNCTION,		"OnHitByVomitJar",						"L4D2_OnHitByVomitJar");
		CreateDetour(hGameData, SpawnSpecial,					INVALID_FUNCTION,		"SpawnSpecial",							"L4D_OnSpawnSpecial");
		CreateDetour(hGameData, SpawnWitchBride,				INVALID_FUNCTION,		"SpawnWitchBride",						"L4D_OnSpawnWitchBride");
		CreateDetour(hGameData, GetScriptValueInt,				INVALID_FUNCTION,		"GetScriptValueInt",					"L4D_OnGetScriptValueInt");
		CreateDetour(hGameData, GetScriptValueFloat,			INVALID_FUNCTION,		"GetScriptValueFloat",					"L4D_OnGetScriptValueFloat");
		CreateDetour(hGameData, GetScriptValueString,			INVALID_FUNCTION,		"GetScriptValueString",					"L4D_OnGetScriptValueString");
		CreateDetour(hGameData, HasConfigurableDifficulty,		INVALID_FUNCTION,		"HasConfigurableDifficulty",			"L4D_OnHasConfigurableDifficulty");
		CreateDetour(hGameData, GetSurvivorSet,					INVALID_FUNCTION,		"GetSurvivorSet",						"L4D_OnGetSurvivorSet");
		CreateDetour(hGameData, FastGetSurvivorSet,				INVALID_FUNCTION,		"FastGetSurvivorSet",					"L4D_OnFastGetSurvivorSet");
		CreateDetour(hGameData, StartMeleeSwing,				INVALID_FUNCTION,		"StartMeleeSwing",						"L4D_OnStartMeleeSwing");
		CreateDetour(hGameData, ChangeFinaleStage,				INVALID_FUNCTION,		"ChangeFinaleStage",					"L4D2_OnChangeFinaleStage");
		CreateDetour(hGameData, AddonsDisabler,					INVALID_FUNCTION,		"FillServerInfo",						"L4D2_OnClientDisableAddons", false, true); // Force detour to enable.
	}

	// Deprecated, unused or broken.
	// CreateDetour(hGameData, InfectedShoved,					INVALID_FUNCTION,		"InfectedShoved",						"L4D_OnInfectedShoved"); // Missing signature
	// CreateDetour(hGameData, OnWaterMovePre,					OnWaterMove,			"WaterMove",							"L4D2_OnWaterMove"); // Does not return water state. Use FL_INWATER instead.
	// CreateDetour(hGameData, GetRandomPZSpawnPos,				INVALID_FUNCTION,		"GetRandomPZSpawnPosition",				"L4D_OnGetRandomPZSpawnPosition");

	g_bCreatedDetours = true;
}

void CreateDetour(GameData hGameData, DHookCallback fCallback, DHookCallback fPostCallback, const char[] sName, const char[] sForward, bool useLast = false, bool forceOn = false)
{
	if( g_bCreatedDetours == false )
	{
		// Set forward names and indexes
		static int index;
		if( useLast ) index -= 1;

		g_aForwardNames.PushString(sForward);
		g_aForwardIndex.Push(index++);
		g_aForceDetours.Push(forceOn);

		// Setup detours
		if( !useLast )
		{
			Handle hDetour = DHookCreateFromConf(hGameData, sName);
			if( !hDetour ) LogError("Failed to load \"%s\" signature.", sName);

			g_aDetoursHooked.Push(0);			// Default disabled
			g_aDetourHandles.Push(hDetour);		// Store handle
		}
	}
	else
	{
		// Enable detours
		if( !useLast )
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

						if( fCallback != INVALID_FUNCTION && !DHookEnableDetour(hDetour, false, fCallback) ) LogError("Failed to detour \"%s\".", sName);
						if( fPostCallback != INVALID_FUNCTION && !DHookEnableDetour(hDetour, true, fPostCallback) ) LogError("Failed to detour post \"%s\".", sName);
					} else {
						g_aDetoursHooked.Set(index, 0);
						#if DEBUG
						PrintToServer("Disabling detour %d %s", index, sName);
						#endif

						if( fCallback != INVALID_FUNCTION && !DHookDisableDetour(hDetour, false, fCallback) ) LogError("Failed to disable detour \"%s\".", sName);
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
	char filename[PLATFORM_MAX_PATH];
	char forwards[MAX_FWD_LEN];
	ArrayList aHand = new ArrayList();
	Handle hIter = GetPluginIterator();
	Handle hPlug;
	int index;

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

			// Get forward name
			g_aForwardNames.GetString(i, forwards, sizeof(forwards));

			// Prevent checking forwards already known in use
			// ToDo: When using extra-api.ext, we will check all plugins to gather total number using each forward and store in g_aDetoursHooked
			if( aHand.FindValue(index) == -1 )
			{
				// Only if not enabling all detours
				#if !DETOUR_ALL

				// Force detour on?
				if( g_aForceDetours.Get(i) )
				{
					aHand.Push(index);

					#if DEBUG
					if( client == 0 )
					{
						StopProfiling(g_vProf);
						g_fProf += GetProfilerTime(g_vProf);
						PrintToServer("%40s> %s", "FORCED DETOUR", forwards);
						StartProfiling(g_vProf);
					}
					#endif

					if( client > 0 )
					{
						ReplyToCommand(client - 1, "%40s> %s", "FORCED DETOUR", forwards);
					}
				}
				// Check if used
				else if( GetFunctionByName(hPlug, forwards) != INVALID_FUNCTION )
				#endif
				{
					aHand.Push(index);

					#if DEBUG
					if( client == 0 )
					{
						#if DETOUR_ALL
						filename = "THIS_PLUGIN_TEST";
						#else
						GetPluginFilename(hPlug, filename, sizeof(filename));
						#endif

						StopProfiling(g_vProf);
						g_fProf += GetProfilerTime(g_vProf);
						PrintToServer("%40s> %s", filename, forwards);
						StartProfiling(g_vProf);
					}
					#endif

					if( client > 0 )
					{
						#if DETOUR_ALL
						ReplyToCommand(client - 1, "%40s %s", "FORCED DETOUR", forwards);
						#else
						GetPluginFilename(hPlug, filename, sizeof(filename));
						ReplyToCommand(client - 1, "%40s> %s", filename, forwards);
						#endif
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
//										LOAD GAMEDATA
// ====================================================================================================
public void OnMapStart()
{
	g_bRoundEnded = false;



	// Putting this here so g_pGameRules is valid.
	LoadGameDataRules();



	// Enable or Disable detours as required.
	#if DEBUG
	g_vProf = CreateProfiler();
	g_fProf = 0.0;
	StartProfiling(g_vProf);
	#endif

	CheckRequiredDetours();

	#if DEBUG
	StopProfiling(g_vProf);
	PrintToServer("");
	PrintToServer("Dynamic Detours finished in %f seconds.", g_fProf);
	PrintToServer("");
	delete g_vProf;
	#endif



	// Because reload cmd calls this function.
	if( !g_bMapStarted )
	{
		g_bMapStarted = true;

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
			SDKCall(g_hSDK_Call_GetScriptValueInt, g_pDirector, "MaxSpecials",			1); // This doesn't appear to work in the finale. At least for some maps.

			// These only appear to work in the Finale, or maybe some specific maps. Unknown.
			SDKCall(g_hSDK_Call_GetScriptValueInt, g_pDirector, "SmokerLimit",			1);
			SDKCall(g_hSDK_Call_GetScriptValueInt, g_pDirector, "BoomerLimit",			1);
			SDKCall(g_hSDK_Call_GetScriptValueInt, g_pDirector, "HunterLimit",			1);
			SDKCall(g_hSDK_Call_GetScriptValueInt, g_pDirector, "SpitterLimit",			1);
			SDKCall(g_hSDK_Call_GetScriptValueInt, g_pDirector, "JockeyLimit",			1);
			SDKCall(g_hSDK_Call_GetScriptValueInt, g_pDirector, "ChargerLimit",			1);
			SDKCall(g_hSDK_Call_GetScriptValueInt, g_pDirector, "TankLimit",			1);
			SDKCall(g_hSDK_Call_GetScriptValueInt, g_pDirector, "DominatorLimit",		1);
			SDKCall(g_hSDK_Call_GetScriptValueInt, g_pDirector, "WitchLimit",			1);
			SDKCall(g_hSDK_Call_GetScriptValueInt, g_pDirector, "CommonLimit",			1);

			// Challenge mode required?
			SDKCall(g_hSDK_Call_GetScriptValueInt, g_pDirector, "cm_MaxSpecials",		1);
			SDKCall(g_hSDK_Call_GetScriptValueInt, g_pDirector, "cm_BaseSpecialLimit",	1);
			SDKCall(g_hSDK_Call_GetScriptValueInt, g_pDirector, "cm_SmokerLimit",		1);
			SDKCall(g_hSDK_Call_GetScriptValueInt, g_pDirector, "cm_BoomerLimit",		1);
			SDKCall(g_hSDK_Call_GetScriptValueInt, g_pDirector, "cm_HunterLimit",		1);
			SDKCall(g_hSDK_Call_GetScriptValueInt, g_pDirector, "cm_SpitterLimit",		1);
			SDKCall(g_hSDK_Call_GetScriptValueInt, g_pDirector, "cm_JockeyLimit",		1);
			SDKCall(g_hSDK_Call_GetScriptValueInt, g_pDirector, "cm_ChargerLimit",		1);
			SDKCall(g_hSDK_Call_GetScriptValueInt, g_pDirector, "cm_TankLimit",			1);
			SDKCall(g_hSDK_Call_GetScriptValueInt, g_pDirector, "cm_DominatorLimit",	1);
			SDKCall(g_hSDK_Call_GetScriptValueInt, g_pDirector, "cm_WitchLimit",		1);
			SDKCall(g_hSDK_Call_GetScriptValueInt, g_pDirector, "cm_CommonLimit",		1);

			// These also exist, required?
			// SDKCall(g_hSDK_Call_GetScriptValueInt, g_pDirector, "TotalSmokers",			1);
			// SDKCall(g_hSDK_Call_GetScriptValueInt, g_pDirector, "TotalBoomers",			1);
			// SDKCall(g_hSDK_Call_GetScriptValueInt, g_pDirector, "TotalHunters",			1);
			// SDKCall(g_hSDK_Call_GetScriptValueInt, g_pDirector, "TotalSpitter",			1);
			// SDKCall(g_hSDK_Call_GetScriptValueInt, g_pDirector, "TotalJockey",			1);
			// SDKCall(g_hSDK_Call_GetScriptValueInt, g_pDirector, "TotalCharger",			1);
		}

		// Melee weapon IDs - They can change when switching map depending on what melee weapons are enabled
		if( g_bLeft4Dead2 )
		{
			delete g_aMeleePtrs;
			delete g_aMeleeIDs;

			g_aMeleePtrs = new ArrayList(2);
			g_aMeleeIDs = new StringMap();

			int iTable = FindStringTable("meleeweapons");
			if( iTable == INVALID_STRING_TABLE )
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

void LoadGameDataRules()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", g_bLeft4Dead2 ? GAMEDATA_2 : GAMEDATA_1);
	if( FileExists(sPath) == false ) SetFailState("\n==========\nMissing required file: \"%s\".\nRead installation instructions again.\n==========", sPath);

	GameData hGameData = new GameData(g_bLeft4Dead2 ? GAMEDATA_2 : GAMEDATA_1);
	if( hGameData == null ) SetFailState("Failed to load \"%s.txt\" gamedata.", g_bLeft4Dead2 ? GAMEDATA_2 : GAMEDATA_1);

	// Map changes can modify the address
	g_pGameRules = hGameData.GetAddress("GameRules");
	ValidateAddress(g_pGameRules, "g_pGameRules", true);

	delete hGameData;
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



	// ====================================================================================================
	//									SDK CALLS
	// ====================================================================================================
	// INTERNAL
	if( g_bLeft4Dead2 )
	{
		StartPrepSDKCall(SDKCall_Static);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "GetWeaponInfo") == false )
		{
			LogError("Failed to find signature: GetWeaponInfo");
		} else {
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_Call_GetWeaponInfo = EndPrepSDKCall();
			if( g_hSDK_Call_GetWeaponInfo == null )
				LogError("Failed to create SDKCall: GetWeaponInfo");
		}
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
		g_hSDK_Call_GetLastKnownArea = EndPrepSDKCall();
		if( g_hSDK_Call_GetLastKnownArea == null )
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
		g_hSDK_Call_Deafen = EndPrepSDKCall();
		if( g_hSDK_Call_Deafen == null )
			LogError("Failed to create SDKCall: CTerrorPlayer::Deafen");
	}

	StartPrepSDKCall(SDKCall_Static);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CEntityDissolve_Create") == false )
	{
		LogError("Failed to find signature: CEntityDissolve_Create");
	} else {
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDK_Call_Dissolve = EndPrepSDKCall();
		if( g_hSDK_Call_Dissolve == null )
			LogError("Failed to create SDKCall: CEntityDissolve_Create");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::OnITExpired") == false )
	{
		LogError("Failed to find signature: CTerrorPlayer::OnITExpired");
	} else {
		g_hSDK_Call_OnITExpired = EndPrepSDKCall();
		if( g_hSDK_Call_OnITExpired == null )
			LogError("Failed to create SDKCall: CTerrorPlayer::OnITExpired");
	}

	StartPrepSDKCall(SDKCall_Entity);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CBaseEntity::ApplyLocalAngularVelocityImpulse") == false )
	{
		LogError("Failed to find signature: CBaseEntity::ApplyLocalAngularVelocityImpulse");
	} else {
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		g_hSDK_Call_AngularVelocity = EndPrepSDKCall();
		if( g_hSDK_Call_AngularVelocity == null )
			LogError("Failed to create SDKCall: CBaseEntity::ApplyLocalAngularVelocityImpulse");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "GetRandomPZSpawnPosition") == false )
	{
		LogError("Failed to find signature: GetRandomPZSpawnPosition");
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // zombieClass
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // Attempts
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWWORLD); // Client
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK); // Vector return
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_Call_GetRandomPZSpawnPosition = EndPrepSDKCall();
		if( g_hSDK_Call_GetRandomPZSpawnPosition == null )
			LogError("Failed to create SDKCall: GetRandomPZSpawnPosition");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "GetNearestNavArea") == false )
	{
		LogError("Failed to find signature: GetNearestNavArea");
	} else {
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_Call_GetNearestNavArea = EndPrepSDKCall();
		if( g_hSDK_Call_GetNearestNavArea == null )
			LogError("Failed to create SDKCall: GetNearestNavArea");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "FindRandomSpot") == false )
	{
		LogError("Failed to find signature: FindRandomSpot");
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Vector, SDKPass_ByValue);
		g_hSDK_Call_FindRandomSpot = EndPrepSDKCall();
		if( g_hSDK_Call_FindRandomSpot == null )
			LogError("Failed to create SDKCall: FindRandomSpot");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "HasAnySurvivorLeftSafeArea") == false )
	{
		LogError("Failed to find signature: HasAnySurvivorLeftSafeArea");
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_Call_HasAnySurvivorLeftSafeArea = EndPrepSDKCall();
		if( g_hSDK_Call_HasAnySurvivorLeftSafeArea == null )
			LogError("Failed to create SDKCall: HasAnySurvivorLeftSafeArea");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "IsAnySurvivorInStartArea") == false )
	{
		LogError("Failed to find signature: IsAnySurvivorInStartArea");
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_Call_IsAnySurvivorInStartArea = EndPrepSDKCall();
		if( g_hSDK_Call_IsAnySurvivorInStartArea == null )
			LogError("Failed to create SDKCall: IsAnySurvivorInStartArea");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "IsAnySurvivorInExitCheckpoint") == false )
	{
		LogError("Failed to find signature: IsAnySurvivorInExitCheckpoint");
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_Call_IsAnySurvivorInCheckpoint = EndPrepSDKCall();
		if( g_hSDK_Call_IsAnySurvivorInCheckpoint == null )
			LogError("Failed to create SDKCall: IsAnySurvivorInExitCheckpoint");
	}

	StartPrepSDKCall(SDKCall_Static);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "HasPlayerControlledZombies") == false )
	{
		LogError("Failed to find signature: HasPlayerControlledZombies");
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_Call_HasPlayerControlledZombies = EndPrepSDKCall();
		if( g_hSDK_Call_HasPlayerControlledZombies == null )
			LogError("Failed to create SDKCall: HasPlayerControlledZombies");
	}

	StartPrepSDKCall(SDKCall_Static);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CPipeBombProjectile_Create") == false )
	{
		LogError("Failed to find signature: CPipeBombProjectile_Create");
	} else {
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDK_Call_PipeBombPrj = EndPrepSDKCall();
		if( g_hSDK_Call_PipeBombPrj == null )
			LogError("Failed to create SDKCall: CPipeBombProjectile_Create");
	}

	if( g_bLeft4Dead2 )
	{
		StartPrepSDKCall(SDKCall_Static);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "NavAreaTravelDistance") == false )
		{
			LogError("Failed to find signature: NavAreaTravelDistance");
		} else {
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_Plain);
			g_hSDK_Call_NavAreaTravelDistance = EndPrepSDKCall();
			if( g_hSDK_Call_NavAreaTravelDistance == null )
				LogError("Failed to create SDKCall: NavAreaTravelDistance");
		}

		StartPrepSDKCall(SDKCall_Static);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CSpitterProjectile_Create") == false )
		{
			LogError("Failed to find signature: CSpitterProjectile_Create");
		} else {
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
			PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
			g_hSDK_Call_SpitterPrj = EndPrepSDKCall();
			if( g_hSDK_Call_SpitterPrj == null )
				LogError("Failed to create SDKCall: CSpitterProjectile_Create");
		}

		StartPrepSDKCall(SDKCall_Player);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "OnAdrenalineUsed") == false )
		{
			LogError("Failed to find signature: OnAdrenalineUsed");
		} else {
			PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
			g_hSDK_Call_OnAdrenalineUsed = EndPrepSDKCall();
			if( g_hSDK_Call_OnAdrenalineUsed == null )
				LogError("Failed to create SDKCall: OnAdrenalineUsed");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "ForceNextStage") == false )
		{
			LogError("Failed to find signature: ForceNextStage");
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_Call_ForceNextStage = EndPrepSDKCall();
			if( g_hSDK_Call_ForceNextStage == null )
				LogError("Failed to create SDKCall: ForceNextStage");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "IsTankInPlay") == false )
		{
			LogError("Failed to find signature: IsTankInPlay");
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
			g_hSDK_Call_IsTankInPlay = EndPrepSDKCall();
			if( g_hSDK_Call_IsTankInPlay == null )
				LogError("Failed to create SDKCall: IsTankInPlay");
		}

		StartPrepSDKCall(SDKCall_Player);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "SurvivorBot::IsReachable") == false )
		{
			LogError("Failed to find signature: SurvivorBot::IsReachable");
		} else {
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
			g_hSDK_Call_IsReachable = EndPrepSDKCall();
			if( g_hSDK_Call_IsReachable == null )
				LogError("Failed to create SDKCall: SurvivorBot::IsReachable");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "GetFurthestSurvivorFlow") == false )
		{
			LogError("Failed to find signature: GetFurthestSurvivorFlow");
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_Plain);
			g_hSDK_Call_GetFurthestSurvivorFlow = EndPrepSDKCall();
			if( g_hSDK_Call_GetFurthestSurvivorFlow == null )
				LogError("Failed to create SDKCall: GetFurthestSurvivorFlow");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "GetScriptValueInt") == false )
		{
			LogError("Failed to find signature: GetScriptValueInt");
		} else {
			PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_Call_GetScriptValueInt = EndPrepSDKCall();
			if( g_hSDK_Call_GetScriptValueInt == null )
					LogError("Failed to create SDKCall: GetScriptValueInt");
		}

		/*
		// Only returns default value provided.
		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "GetScriptValueFloat") == false )
		{
			LogError("Failed to find signature: GetScriptValueFloat");
		} else {
			PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
			PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
			PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_Plain);
			g_hSDK_Call_GetScriptValueFloat = EndPrepSDKCall();
			if( g_hSDK_Call_GetScriptValueFloat == null )
					LogError("Failed to create SDKCall: GetScriptValueFloat");
		}

		// Not implemented, request if really required.
		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "GetScriptValueString") == false )
		{
			LogError("Failed to find signature: GetScriptValueString");
		} else {
			PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
			PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
			PrepSDKCall_SetReturnInfo(SDKType_String, SDKPass_Pointer);
			g_hSDK_Call_GetScriptValueString = EndPrepSDKCall();
			if( g_hSDK_Call_GetScriptValueString == null )
					LogError("Failed to create SDKCall: GetScriptValueString");
		}
		*/
	}



	// =========================
	// MAIN - left4downtown.inc
	// =========================
	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "RestartScenarioFromVote") == false )
	{
		LogError("Failed to find signature: RestartScenarioFromVote");
	} else {
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_Call_RestartScenarioFromVote = EndPrepSDKCall();
		if( g_hSDK_Call_RestartScenarioFromVote == null )
			LogError("Failed to create SDKCall: RestartScenarioFromVote");
	}

	StartPrepSDKCall(SDKCall_GameRules);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "GetTeamScore") == false )
	{
		LogError("Failed to find signature: GetTeamScore");
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_Call_GetTeamScore = EndPrepSDKCall();
		if( g_hSDK_Call_GetTeamScore == null )
			LogError("Failed to create SDKCall: GetTeamScore");
	}

	if( g_bLeft4Dead2 )
	{
		StartPrepSDKCall(SDKCall_Raw);
	} else {
		StartPrepSDKCall(SDKCall_Static);
	}
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "IsFirstMapInScenario") == false )
	{
		LogError("Failed to find signature: IsFirstMapInScenario");
	} else {
		if( !g_bLeft4Dead2 )
		{
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain, VDECODE_FLAG_ALLOWWORLD);
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		}
		g_hSDK_Call_IsFirstMapInScenario = EndPrepSDKCall();
		if( g_hSDK_Call_IsFirstMapInScenario == null )
			LogError("Failed to create SDKCall: IsFirstMapInScenario");
	}

	StartPrepSDKCall(SDKCall_GameRules);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "IsMissionFinalMap") == false )
	{
		LogError("Failed to find signature: IsMissionFinalMap");
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_Call_IsMissionFinalMap = EndPrepSDKCall();
		if( g_hSDK_Call_IsMissionFinalMap == null )
			LogError("Failed to create SDKCall: IsMissionFinalMap");
	}

	if( !g_bLeft4Dead2 )
	{
		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "KeyValues::GetString") == false )
			SetFailState("Could not load the \"KeyValues::GetString\" gamedata signature.");
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		PrepSDKCall_SetReturnInfo(SDKType_String, SDKPass_Pointer);
		SDK_KV_GetString = EndPrepSDKCall();
		if( SDK_KV_GetString == null )
			SetFailState("Could not prep the \"KeyValues::GetString\" function.");
	}

	StartPrepSDKCall(SDKCall_GameRules);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "NotifyNetworkStateChanged") == false )
	{
		LogError("Failed to find signature: NotifyNetworkStateChanged");
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_Call_NotifyNetworkStateChanged = EndPrepSDKCall();
		if( g_hSDK_Call_NotifyNetworkStateChanged == null )
			LogError("Failed to create SDKCall: NotifyNetworkStateChanged");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "OnStaggered") == false )
	{
		LogError("Failed to find signature: StaggerPlayer");
	} else {
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_Call_StaggerPlayer = EndPrepSDKCall();
		if( g_hSDK_Call_StaggerPlayer == null )
			LogError("Failed to create SDKCall: OnStaggered");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "SendInRescueVehicle") == false )
	{
		LogError("Failed to find signature: SendInRescueVehicle");
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_Call_SendInRescueVehicle = EndPrepSDKCall();
		if( g_hSDK_Call_SendInRescueVehicle == null )
			LogError("Failed to create SDKCall: SendInRescueVehicle");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "ReplaceTank") == false )
	{
		LogError("Failed to find signature: ReplaceTank");
	} else {
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_Call_ReplaceTank = EndPrepSDKCall();
		if( g_hSDK_Call_ReplaceTank == null )
			LogError("Failed to create SDKCall: ReplaceTank");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "SpawnTank") == false )
	{
		LogError("Failed to find signature: SpawnTank");
	} else {
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
		PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDK_Call_SpawnTank = EndPrepSDKCall();
		if( g_hSDK_Call_SpawnTank == null )
			LogError("Failed to create SDKCall: SpawnTank");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "SpawnWitch") == false )
	{
		LogError("Failed to find signature: SpawnWitch");
	} else {
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
		PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDK_Call_SpawnWitch = EndPrepSDKCall();
		if( g_hSDK_Call_SpawnWitch == null )
			LogError("Failed to create SDKCall: SpawnWitch");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "IsFinaleEscapeInProgress") == false )
	{
		LogError("Failed to find signature: IsFinaleEscapeInProgress");
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_Call_IsFinaleEscapeInProgress = EndPrepSDKCall();
		if( g_hSDK_Call_IsFinaleEscapeInProgress == null )
			LogError("Failed to create SDKCall: IsFinaleEscapeInProgress");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "SetHumanSpec") == false )
	{
		LogError("Failed to find signature: SetHumanSpec");
	} else {
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_Call_SetHumanSpec = EndPrepSDKCall();
		if( g_hSDK_Call_SetHumanSpec == null )
			LogError("Failed to create SDKCall: SetHumanSpec");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "TakeOverBot") == false )
	{
		LogError("Failed to find signature: TakeOverBot");
	} else {
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_Call_TakeOverBot = EndPrepSDKCall();
		if( g_hSDK_Call_TakeOverBot == null )
			LogError("Failed to create SDKCall: TakeOverBot");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CanBecomeGhost") == false )
	{
		LogError("Failed to find signature: CanBecomeGhost");
	} else {
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		g_hSDK_Call_CanBecomeGhost = EndPrepSDKCall();
		if( g_hSDK_Call_CanBecomeGhost == null )
			LogError("Failed to create SDKCall: CanBecomeGhost");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "TryOfferingTankBot") == false )
	{
		LogError("Failed to find signature: TryOfferingTankBot");
	} else {
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_Call_TryOfferingTankBot = EndPrepSDKCall();
		if( g_hSDK_Call_TryOfferingTankBot == null )
			LogError("Failed to create SDKCall: TryOfferingTankBot");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "GetNavArea") == false )
	{
		LogError("Failed to find signature: GetNavArea");
	} else {
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_Call_GetNavArea = EndPrepSDKCall();
		if( g_hSDK_Call_GetNavArea == null )
			SetFailState("Failed to create SDKCall: GetNavArea");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "GetFlowDistance") == false )
	{
		LogError("Failed to find signature: GetFlowDistance");
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_Plain);
		g_hSDK_Call_GetFlowDistance = EndPrepSDKCall();
		if( g_hSDK_Call_GetFlowDistance == null )
			SetFailState("Failed to create SDKCall: GetFlowDistance");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "DoAnimationEvent") == false )
	{
		LogError("Failed to find signature: DoAnimationEvent");
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_Call_DoAnimationEvent = EndPrepSDKCall();
		if( g_hSDK_Call_DoAnimationEvent == null )
			SetFailState("Failed to create SDKCall: DoAnimationEvent");
	}



	if( g_bLeft4Dead2 )
	{
		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "GetMeleeWeaponInfo") == false )
		{
			LogError("Failed to find signature: GetMeleeWeaponInfo");
		} else {
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_Call_GetMeleeInfo = EndPrepSDKCall();
			if( g_hSDK_Call_GetMeleeInfo == null )
				LogError("Failed to create SDKCall: GetMeleeWeaponInfo");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "ResetMobTimer") == false )
		{
			LogError("Failed to find signature: ResetMobTimer");
		} else {
			g_hSDK_Call_ResetMobTimer = EndPrepSDKCall();
			if( g_hSDK_Call_ResetMobTimer == null )
				LogError("Failed to create SDKCall: ResetMobTimer");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "ChangeFinaleStage") == false )
		{
			LogError("Failed to find signature: ChangeFinaleStage");
		} else {
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_Call_ChangeFinaleStage = EndPrepSDKCall();
			if( g_hSDK_Call_ChangeFinaleStage == null )
				LogError("Failed to create SDKCall: ChangeFinaleStage");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "SpawnSpecial") == false )
		{
			LogError("Failed to find signature: SpawnSpecial");
		} else {
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
			PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
			g_hSDK_Call_SpawnSpecial = EndPrepSDKCall();
			if( g_hSDK_Call_SpawnSpecial == null )
				LogError("Failed to create SDKCall: SpawnSpecial");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "SpawnWitchBride") == false )
		{
			LogError("Failed to find signature: SpawnWitchBride");
		} else {
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
			PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
			g_hSDK_Call_SpawnWitchBride = EndPrepSDKCall();
			if( g_hSDK_Call_SpawnWitchBride == null )
				LogError("Failed to create SDKCall: SpawnWitchBride");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "AreWanderersAllowed") == false )
		{
			LogError("Failed to find signature: AreWanderersAllowed");
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
			g_hSDK_Call_AreWanderersAllowed = EndPrepSDKCall();
			if( g_hSDK_Call_AreWanderersAllowed == null )
				LogError("Failed to create SDKCall: AreWanderersAllowed");
		}
	} else {
	// L4D1 only:
		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "SpawnHunter") == false )
		{
			LogError("Failed to find signature: SpawnHunter");
		} else {
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
			PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
			g_hSDK_Call_SpawnHunter = EndPrepSDKCall();
			if( g_hSDK_Call_SpawnHunter == null )
				LogError("Failed to create SDKCall: SpawnHunter");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "SpawnBoomer") == false )
		{
			LogError("Failed to find signature: SpawnBoomer");
		} else {
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
			PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
			g_hSDK_Call_SpawnBoomer = EndPrepSDKCall();
			if( g_hSDK_Call_SpawnBoomer == null )
				LogError("Failed to create SDKCall: SpawnBoomer");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "SpawnSmoker") == false )
		{
			LogError("Failed to find signature: SpawnSmoker");
		} else {
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
			PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
			g_hSDK_Call_SpawnSmoker = EndPrepSDKCall();
			if( g_hSDK_Call_SpawnSmoker == null )
				LogError("Failed to create SDKCall: SpawnSmoker");
		}
	}



	// =========================
	// l4d2addresses.txt
	// =========================
	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer_OnVomitedUpon") == false )
	{
		LogError("Failed to find signature: CTerrorPlayer_OnVomitedUpon");
	} else {
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		g_hSDK_Call_CTerrorPlayer_OnVomitedUpon = EndPrepSDKCall();
		if( g_hSDK_Call_CTerrorPlayer_OnVomitedUpon == null )
			LogError("Failed to create SDKCall: CTerrorPlayer_OnVomitedUpon");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CancelStagger") == false )
	{
		LogError("Failed to find signature: CancelStagger");
	} else {
		g_hSDK_Call_CancelStagger = EndPrepSDKCall();
		if( g_hSDK_Call_CancelStagger == null )
			LogError("Failed to create SDKCall: CancelStagger");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "RoundRespawn") == false )
	{
		LogError("Failed to find signature: RoundRespawn");
	} else {
		g_hSDK_Call_RoundRespawn = EndPrepSDKCall();
		if( g_hSDK_Call_RoundRespawn == null )
			LogError("Failed to create SDKCall: RoundRespawn");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CreateRescuableSurvivors") == false )
	{
		LogError("Failed to find signature: CreateRescuableSurvivors");
	} else {
		g_hSDK_Call_CreateRescuableSurvivors = EndPrepSDKCall();
		if( g_hSDK_Call_CreateRescuableSurvivors == null )
			LogError("Failed to create SDKCall: CreateRescuableSurvivors");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "OnRevived") == false )
	{
		LogError("Failed to find signature: OnRevived");
	} else {
		g_hSDK_Call_OnRevived = EndPrepSDKCall();
		if( g_hSDK_Call_OnRevived == null )
			LogError("Failed to create SDKCall: OnRevived");
	}

	StartPrepSDKCall(SDKCall_Static);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "GetHighestFlowSurvivor") == false )
	{
		LogError("Failed to find signature: GetHighestFlowSurvivor");
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDK_Call_GetHighestFlowSurvivor = EndPrepSDKCall();
		if( g_hSDK_Call_GetHighestFlowSurvivor == null )
			LogError("Failed to create SDKCall: GetHighestFlowSurvivor");
	}

	StartPrepSDKCall(SDKCall_Entity);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "GetInfectedFlowDistance") == false )
	{
		LogError("Failed to find signature: GetInfectedFlowDistance");
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_Plain);
		g_hSDK_Call_GetInfectedFlowDistance = EndPrepSDKCall();
		if( g_hSDK_Call_GetInfectedFlowDistance == null )
			LogError("Failed to create SDKCall: GetInfectedFlowDistance");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "TakeOverZombieBot") == false )
	{
		LogError("Failed to find signature: TakeOverZombieBot");
	} else {
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		g_hSDK_Call_TakeOverZombieBot = EndPrepSDKCall();
		if( g_hSDK_Call_TakeOverZombieBot == null )
			LogError("Failed to create SDKCall: TakeOverZombieBot");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "ReplaceWithBot") == false )
	{
		LogError("Failed to find signature: ReplaceWithBot");
	} else {
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		g_hSDK_Call_ReplaceWithBot = EndPrepSDKCall();
		if( g_hSDK_Call_ReplaceWithBot == null )
			LogError("Failed to create SDKCall: ReplaceWithBot");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CullZombie") == false )
	{
		LogError("Failed to find signature: CullZombie");
	} else {
		g_hSDK_Call_CullZombie = EndPrepSDKCall();
		if( g_hSDK_Call_CullZombie == null )
			LogError("Failed to create SDKCall: CullZombie");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "SetClass") == false )
	{
		LogError("Failed to find signature: SetClass");
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_Call_SetClass = EndPrepSDKCall();
		if( g_hSDK_Call_SetClass == null )
			LogError("Failed to create SDKCall: SetClass");
	}

	StartPrepSDKCall(SDKCall_Static);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CreateAbility") == false )
	{
		LogError("Failed to find signature: CreateAbility");
	} else {
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDK_Call_CreateAbility = EndPrepSDKCall();
		if( g_hSDK_Call_CreateAbility == null )
			LogError("Failed to create SDKCall: CreateAbility");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "MaterializeFromGhost") == false )
	{
		LogError("Failed to find signature: MaterializeFromGhost");
	} else {
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_Call_MaterializeFromGhost = EndPrepSDKCall();
		if( g_hSDK_Call_MaterializeFromGhost == null )
			LogError("Failed to create SDKCall: MaterializeFromGhost");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "BecomeGhost") == false )
	{
		LogError("Failed to find signature: BecomeGhost");
	} else {
		if( g_bLeft4Dead2 )
			PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		else
		{
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		}
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_Call_BecomeGhost = EndPrepSDKCall();
		if( g_hSDK_Call_BecomeGhost == null )
			LogError("Failed to create SDKCall: BecomeGhost");
	}

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "State_Transition") == false )
	{
		LogError("Failed to find signature: State_Transition");
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_Call_State_Transition = EndPrepSDKCall();
		if( g_hSDK_Call_State_Transition == null )
			LogError("Failed to create SDKCall: State_Transition");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "RegisterForbiddenTarget") == false )
	{
		LogError("Failed to find signature: RegisterForbiddenTarget");
	} else {
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hSDK_Call_RegisterForbiddenTarget = EndPrepSDKCall();
		if( g_hSDK_Call_RegisterForbiddenTarget == null )
			LogError("Failed to create SDKCall: RegisterForbiddenTarget");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "UnRegisterForbiddenTarget") == false )
	{
		LogError("Failed to find signature: UnRegisterForbiddenTarget");
	} else {
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hSDK_Call_UnRegisterForbiddenTarget = EndPrepSDKCall();
		if( g_hSDK_Call_UnRegisterForbiddenTarget == null )
			LogError("Failed to create SDKCall: UnRegisterForbiddenTarget");
	}



	if( g_bLeft4Dead2 )
	{
		StartPrepSDKCall(SDKCall_Player);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer_OnHitByVomitJar") == false )
		{
			LogError("Failed to find signature: CTerrorPlayer_OnHitByVomitJar");
		} else {
			PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
			g_hSDK_Call_CTerrorPlayer_OnHitByVomitJar = EndPrepSDKCall();
			if( g_hSDK_Call_CTerrorPlayer_OnHitByVomitJar == null )
				LogError("Failed to create SDKCall: CTerrorPlayer_OnHitByVomitJar");
		}

		StartPrepSDKCall(SDKCall_Entity);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "Infected_OnHitByVomitJar") == false )
		{
			LogError("Failed to find signature: Infected_OnHitByVomitJar");
		} else {
			PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
			g_hSDK_Call_Infected_OnHitByVomitJar = EndPrepSDKCall();
			if( g_hSDK_Call_Infected_OnHitByVomitJar == null )
				LogError("Failed to create SDKCall: Infected_OnHitByVomitJar");
		}

		StartPrepSDKCall(SDKCall_Player);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer_Fling") == false )
		{
			LogError("Failed to find signature: CTerrorPlayer_Fling");
		} else {
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
			PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
			g_hSDK_Call_Fling = EndPrepSDKCall();
			if( g_hSDK_Call_Fling == null )
				LogError("Failed to create SDKCall: CTerrorPlayer_Fling");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "GetVersusCompletionPlayer") == false )
		{
			LogError("Failed to find signature: GetVersusCompletionPlayer");
		} else {
			PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_Call_GetVersusCompletionPlayer = EndPrepSDKCall();
			if( g_hSDK_Call_GetVersusCompletionPlayer == null )
				LogError("Failed to create SDKCall: GetVersusCompletionPlayer");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "SwapTeams") == false )
		{
			LogError("Failed to find signature: SwapTeams");
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_Call_SwapTeams = EndPrepSDKCall();
			if( g_hSDK_Call_SwapTeams == null )
				LogError("Failed to create SDKCall: SwapTeams");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "AreTeamsFlipped") == false )
		{
			LogError("Failed to find signature: AreTeamsFlipped");
		} else {
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			g_hSDK_Call_AreTeamsFlipped = EndPrepSDKCall();
			if( g_hSDK_Call_AreTeamsFlipped == null )
				LogError("Failed to create SDKCall: AreTeamsFlipped");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "StartRematchVote") == false )
		{
			LogError("Failed to find signature: StartRematchVote");
		} else {
			g_hSDK_Call_StartRematchVote = EndPrepSDKCall();
			if( g_hSDK_Call_StartRematchVote == null )
				LogError("Failed to create SDKCall: StartRematchVote");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "FullRestart") == false )
		{
			LogError("Failed to find signature: FullRestart");
		} else {
			g_hSDK_Call_FullRestart = EndPrepSDKCall();
			if( g_hSDK_Call_FullRestart == null )
				LogError("Failed to create SDKCall: FullRestart");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "HideVersusScoreboard") == false )
		{
			LogError("Failed to find signature: HideVersusScoreboard");
		} else {
			g_hSDK_Call_HideVersusScoreboard = EndPrepSDKCall();
			if( g_hSDK_Call_HideVersusScoreboard == null )
				LogError("Failed to create SDKCall: HideVersusScoreboard");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "HideScavengeScoreboard") == false )
		{
			LogError("Failed to find signature: HideScavengeScoreboard");
		} else {
			g_hSDK_Call_HideScavengeScoreboard = EndPrepSDKCall();
			if( g_hSDK_Call_HideScavengeScoreboard == null )
				LogError("Failed to create SDKCall: HideScavengeScoreboard");
		}

		StartPrepSDKCall(SDKCall_Raw);
		if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "HideScoreboard") == false )
		{
			LogError("Failed to find signature: HideScoreboard");
		} else {
			g_hSDK_Call_HideScoreboard = EndPrepSDKCall();
			if( g_hSDK_Call_HideScoreboard == null )
				LogError("Failed to create SDKCall: HideScoreboard");
		}
	}

	StartPrepSDKCall(SDKCall_Static);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "SetReservationCookie") == false )
	{
		LogError("Failed to find signature: SetReservationCookie");
	} else {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		g_hSDK_Call_LobbyUnreserve = EndPrepSDKCall();
		if( g_hSDK_Call_LobbyUnreserve == null )
			LogError("Failed to create SDKCall: SetReservationCookie");
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
		g_hSDK_Call_GetCampaignScores = EndPrepSDKCall();
		if( g_hSDK_Call_GetCampaignScores == null )
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
		g_hSDK_Call_LobbyIsReserved = EndPrepSDKCall();
		if( g_hSDK_Call_LobbyIsReserved == null )
			LogError("Failed to create SDKCall: LobbyIsReserved");
	}
	// */



	// =========================
	// Pointer Offsets
	// =========================
	if( g_bLeft4Dead2 )
	{
		ScavengeModePtr = hGameData.GetOffset("ScavengeModePtr");
		ValidateOffset(ScavengeModePtr, "ScavengeModePtr");

		VersusModePtr = hGameData.GetOffset("VersusModePtr");
		ValidateOffset(VersusModePtr, "VersusModePtr");

		ScriptedEventManagerPtr = hGameData.GetOffset("ScriptedEventManagerPtr");
		ValidateOffset(ScriptedEventManagerPtr, "ScriptedEventManagerPtr");


		// DisableAddons
		VanillaModeAddress = hGameData.GetAddress("VanillaModeAddress");
		ValidateAddress(VanillaModeAddress, "VanillaModeAddress", true);

		VanillaModeOffset = hGameData.GetOffset("VanillaModeOffset");
		ValidateOffset(VanillaModeOffset, "VanillaModeOffset");
	// } else {
		// TeamScoresAddress = hGameData.GetAddress("ClearTeamScores");
		// if( TeamScoresAddress == Address_Null ) LogError("Failed to find \"ClearTeamScores\" address.");

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
		PrintToServer("%12d == VersusModePtr", VersusModePtr);
		PrintToServer("%12d == ScavengeModePtr", ScavengeModePtr);
		PrintToServer("%12d == ScriptedEventManagerPtr", ScriptedEventManagerPtr);
		PrintToServer("%12d == VanillaModeAddress", VanillaModeAddress);
		PrintToServer("%12d == VanillaModeOffset (Win=0, Nix=4)", VanillaModeOffset);
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

	if( g_bLeft4Dead2 )
	{
		g_pWeaponInfoDatabase = hGameData.GetAddress("WeaponInfoDatabase");
		ValidateAddress(g_pWeaponInfoDatabase, "g_pWeaponInfoDatabase", true);

		g_pMeleeWeaponInfoStore = hGameData.GetAddress("MeleeWeaponInfoStore");
		ValidateAddress(g_pMeleeWeaponInfoStore, "g_pMeleeWeaponInfoStore", true);

		ScriptedEventManagerPtr =			LoadFromAddress(g_pDirector + view_as<Address>(ScriptedEventManagerPtr), NumberType_Int32);
		ValidateAddress(ScriptedEventManagerPtr, "ScriptedEventManagerPtr", true);

		VersusModePtr =						LoadFromAddress(g_pDirector + view_as<Address>(VersusModePtr), NumberType_Int32);
		ValidateAddress(VersusModePtr, "VersusModePtr", true);

		ScavengeModePtr =					LoadFromAddress(g_pDirector + view_as<Address>(ScavengeModePtr), NumberType_Int32);
		ValidateAddress(ScavengeModePtr, "ScavengeModePtr", true);
	} else {
		// L4D1: g_pDirector is also VersusModePtr.
		VersusModePtr = view_as<int>(g_pDirector);
	}

	#if DEBUG
	if( g_bLateLoad )
	{
		LoadGameDataRules();
	}

	PrintToServer("Pointers:");
	PrintToServer("%12d == g_pDirector", g_pDirector);
	PrintToServer("%12d == g_pZombieManager", g_pZombieManager);
	PrintToServer("%12d == g_pGameRules", g_pGameRules);
	PrintToServer("%12d == g_pNavMesh", g_pNavMesh);
	PrintToServer("%12d == g_pServer", g_pServer);
	if( g_bLeft4Dead2 )
	{
		PrintToServer("%12d == g_pWeaponInfoDatabase", g_pWeaponInfoDatabase);
		PrintToServer("%12d == g_pMeleeWeaponInfoStore", g_pMeleeWeaponInfoStore);
		PrintToServer("%12d == ScriptedEventManagerPtr", ScriptedEventManagerPtr);
		PrintToServer("%12d == VersusModePtr", VersusModePtr);
		PrintToServer("%12d == ScavengeModePtr", ScavengeModePtr);
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

	g_bLinuxOS = hGameData.GetOffset("OS") == 1;

	m_iCampaignScores = hGameData.GetOffset("m_iCampaignScores");
	ValidateOffset(m_iCampaignScores, "m_iCampaignScores");

	m_fTankSpawnFlowPercent = hGameData.GetOffset("m_fTankSpawnFlowPercent");
	ValidateOffset(m_fTankSpawnFlowPercent, "m_fTankSpawnFlowPercent");

	m_fWitchSpawnFlowPercent = hGameData.GetOffset("m_fWitchSpawnFlowPercent");
	ValidateOffset(m_fWitchSpawnFlowPercent, "m_fWitchSpawnFlowPercent");

	m_iTankPassedCount = hGameData.GetOffset("m_iTankPassedCount");
	ValidateOffset(m_iTankPassedCount, "m_iTankPassedCount");

	m_bTankThisRound = hGameData.GetOffset("m_bTankThisRound");
	ValidateOffset(m_bTankThisRound, "m_bTankThisRound");

	m_bWitchThisRound = hGameData.GetOffset("m_bWitchThisRound");
	ValidateOffset(m_bWitchThisRound, "m_bWitchThisRound");

	InvulnerabilityTimer = hGameData.GetOffset("InvulnerabilityTimer");
	ValidateOffset(InvulnerabilityTimer, "InvulnerabilityTimer");

	m_iTankTickets = hGameData.GetOffset("m_iTankTickets");
	ValidateOffset(m_iTankTickets, "m_iTankTickets");

	m_flow = hGameData.GetOffset("m_flow");
	ValidateOffset(m_flow, "m_flow");

	m_PendingMobCount = hGameData.GetOffset("m_PendingMobCount");
	ValidateOffset(m_PendingMobCount, "m_PendingMobCount");

	m_fMapMaxFlowDistance = hGameData.GetOffset("m_fMapMaxFlowDistance");
	ValidateOffset(m_fMapMaxFlowDistance, "m_fMapMaxFlowDistance");

	m_rescueCheckTimer = hGameData.GetOffset("m_rescueCheckTimer");
	ValidateOffset(m_rescueCheckTimer, "m_rescueCheckTimer");



	if( g_bLeft4Dead2 )
	{
		g_iAddonEclipse1 = hGameData.GetOffset("AddonEclipse1");
		ValidateOffset(g_iAddonEclipse1, "AddonEclipse1");
		g_iAddonEclipse2 = hGameData.GetOffset("AddonEclipse2");
		ValidateOffset(g_iAddonEclipse2, "AddonEclipse2");

		SpawnTimer = hGameData.GetOffset("SpawnTimer");
		ValidateOffset(SpawnTimer, "SpawnTimer");

		MobSpawnTimer = hGameData.GetOffset("MobSpawnTimer");
		ValidateOffset(MobSpawnTimer, "MobSpawnTimer");

		OnBeginRoundSetupTime = hGameData.GetOffset("OnBeginRoundSetupTime");
		ValidateOffset(OnBeginRoundSetupTime, "OnBeginRoundSetupTime");

		VersusMaxCompletionScore = hGameData.GetOffset("VersusMaxCompletionScore");
		ValidateOffset(VersusMaxCompletionScore, "VersusMaxCompletionScore");

		m_iTankCount = hGameData.GetOffset("m_iTankCount");
		ValidateOffset(SpawnTimer, "SpawnTimer");

		m_iWitchCount = hGameData.GetOffset("m_iWitchCount");
		ValidateOffset(m_iWitchCount, "m_iWitchCount");

		OvertimeGraceTimer = hGameData.GetOffset("OvertimeGraceTimer");
		ValidateOffset(OvertimeGraceTimer, "OvertimeGraceTimer");

		m_iShovePenalty = hGameData.GetOffset("m_iShovePenalty");
		ValidateOffset(m_iShovePenalty, "m_iShovePenalty");

		m_fNextShoveTime = hGameData.GetOffset("m_fNextShoveTime");
		ValidateOffset(m_fNextShoveTime, "m_fNextShoveTime");

		m_preIncapacitatedHealth = hGameData.GetOffset("m_preIncapacitatedHealth");
		ValidateOffset(m_preIncapacitatedHealth, "m_preIncapacitatedHealth");

		m_preIncapacitatedHealthBuffer = hGameData.GetOffset("m_preIncapacitatedHealthBuffer");
		ValidateOffset(m_preIncapacitatedHealthBuffer, "m_preIncapacitatedHealthBuffer");

		m_maxFlames = hGameData.GetOffset("m_maxFlames");
		ValidateOffset(m_maxFlames, "m_maxFlames");

		// l4d2timers.inc offsets
		L4D2CountdownTimer_Offsets[0] = hGameData.GetOffset("L4D2CountdownTimer_MobSpawnTimer") + view_as<int>(g_pDirector);
		L4D2CountdownTimer_Offsets[1] = hGameData.GetOffset("L4D2CountdownTimer_SmokerSpawnTimer") + view_as<int>(g_pDirector);
		L4D2CountdownTimer_Offsets[2] = hGameData.GetOffset("L4D2CountdownTimer_BoomerSpawnTimer") + view_as<int>(g_pDirector);
		L4D2CountdownTimer_Offsets[3] = hGameData.GetOffset("L4D2CountdownTimer_HunterSpawnTimer") + view_as<int>(g_pDirector);
		L4D2CountdownTimer_Offsets[4] = hGameData.GetOffset("L4D2CountdownTimer_SpitterSpawnTimer") + view_as<int>(g_pDirector);
		L4D2CountdownTimer_Offsets[5] = hGameData.GetOffset("L4D2CountdownTimer_JockeySpawnTimer") + view_as<int>(g_pDirector);
		L4D2CountdownTimer_Offsets[6] = hGameData.GetOffset("L4D2CountdownTimer_ChargerSpawnTimer") + view_as<int>(g_pDirector);
		L4D2CountdownTimer_Offsets[7] = hGameData.GetOffset("L4D2CountdownTimer_VersusStartTimer") + VersusModePtr;
		L4D2CountdownTimer_Offsets[8] = hGameData.GetOffset("L4D2CountdownTimer_UpdateMarkersTimer") + view_as<int>(g_pDirector);
		L4D2IntervalTimer_Offsets[0] = hGameData.GetOffset("L4D2IntervalTimer_SmokerDeathTimer") + view_as<int>(g_pDirector);
		L4D2IntervalTimer_Offsets[1] = hGameData.GetOffset("L4D2IntervalTimer_BoomerDeathTimer") + view_as<int>(g_pDirector);
		L4D2IntervalTimer_Offsets[2] = hGameData.GetOffset("L4D2IntervalTimer_HunterDeathTimer") + view_as<int>(g_pDirector);
		L4D2IntervalTimer_Offsets[3] = hGameData.GetOffset("L4D2IntervalTimer_SpitterDeathTimer") + view_as<int>(g_pDirector);
		L4D2IntervalTimer_Offsets[4] = hGameData.GetOffset("L4D2IntervalTimer_JockeyDeathTimer") + view_as<int>(g_pDirector);
		L4D2IntervalTimer_Offsets[5] = hGameData.GetOffset("L4D2IntervalTimer_ChargerDeathTimer") + view_as<int>(g_pDirector);

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
		L4D2BoolMeleeWeapon_Offsets[0] = hGameData.GetOffset("L4D2BoolMeleeWeapon_Decapitates");
		L4D2IntMeleeWeapon_Offsets[0] = hGameData.GetOffset("L4D2IntMeleeWeapon_DamageFlags");
		L4D2IntMeleeWeapon_Offsets[1] = hGameData.GetOffset("L4D2IntMeleeWeapon_RumbleEffect");
		L4D2FloatMeleeWeapon_Offsets[0] = hGameData.GetOffset("L4D2FloatMeleeWeapon_Damage");
		L4D2FloatMeleeWeapon_Offsets[1] = hGameData.GetOffset("L4D2FloatMeleeWeapon_RefireDelay");
		L4D2FloatMeleeWeapon_Offsets[2] = hGameData.GetOffset("L4D2FloatMeleeWeapon_WeaponIdleTime");
	} else {
		VersusStartTimer = hGameData.GetOffset("VersusStartTimer");
		ValidateOffset(VersusStartTimer, "VersusStartTimer");

		#if DEBUG
		PrintToServer("VersusStartTimer = %d", VersusStartTimer);
		#endif
	}



	#if DEBUG
	PrintToServer("m_iCampaignScores = %d", m_iCampaignScores);
	PrintToServer("m_fTankSpawnFlowPercent = %d", m_fTankSpawnFlowPercent);
	PrintToServer("m_fWitchSpawnFlowPercent = %d", m_fWitchSpawnFlowPercent);
	PrintToServer("m_iTankPassedCount = %d", m_iTankPassedCount);
	PrintToServer("m_bTankThisRound = %d", m_bTankThisRound);
	PrintToServer("m_bWitchThisRound = %d", m_bWitchThisRound);
	PrintToServer("InvulnerabilityTimer = %d", InvulnerabilityTimer);
	PrintToServer("m_iTankTickets = %d", m_iTankTickets);
	PrintToServer("m_flow = %d", m_flow);
	PrintToServer("m_PendingMobCount = %d", m_PendingMobCount);
	PrintToServer("m_fMapMaxFlowDistance = %d", m_fMapMaxFlowDistance);
	PrintToServer("m_rescueCheckTimer = %d", m_rescueCheckTimer);

	if( g_bLeft4Dead2 )
	{
		PrintToServer("g_iAddonEclipse1 = %d", g_iAddonEclipse1);
		PrintToServer("g_iAddonEclipse2 = %d", g_iAddonEclipse2);
		PrintToServer("SpawnTimer = %d", SpawnTimer);
		PrintToServer("MobSpawnTimer = %d", MobSpawnTimer);
		PrintToServer("OnBeginRoundSetupTime = %d", OnBeginRoundSetupTime);
		PrintToServer("VersusMaxCompletionScore = %d", VersusMaxCompletionScore);
		PrintToServer("m_iTankCount = %d", m_iTankCount);
		PrintToServer("m_iWitchCount = %d", m_iWitchCount);
		PrintToServer("OvertimeGraceTimer = %d", OvertimeGraceTimer);
		PrintToServer("m_iShovePenalty = %d", m_iShovePenalty);
		PrintToServer("m_fNextShoveTime = %d", m_fNextShoveTime);
		PrintToServer("m_preIncapacitatedHealth = %d", m_preIncapacitatedHealth);
		PrintToServer("m_preIncapacitatedHealthBuffer = %d", m_preIncapacitatedHealthBuffer);
		PrintToServer("m_maxFlames = %d", m_maxFlames);
		PrintToServer("");

		for( int i = 0; i < sizeof(L4D2CountdownTimer_Offsets); i++ )		PrintToServer("L4D2CountdownTimer_Offsets[%d] == %d", i, L4D2CountdownTimer_Offsets[i]);
		for( int i = 0; i < sizeof(L4D2IntervalTimer_Offsets); i++ )		PrintToServer("L4D2IntervalTimer_Offsets[%d] == %d", i, L4D2IntervalTimer_Offsets[i]);
		for( int i = 0; i < sizeof(L4D2IntWeapon_Offsets); i++ )			PrintToServer("L4D2IntWeapon_Offsets[%d] == %d", i, L4D2IntWeapon_Offsets[i]);
		for( int i = 0; i < sizeof(L4D2FloatWeapon_Offsets); i++ )			PrintToServer("L4D2FloatWeapon_Offsets[%d] == %d", i, L4D2FloatWeapon_Offsets[i]);
		for( int i = 0; i < sizeof(L4D2BoolMeleeWeapon_Offsets); i++ )		PrintToServer("L4D2BoolMeleeWeapon_Offsets[%d] == %d", i, L4D2BoolMeleeWeapon_Offsets[i]);
		for( int i = 0; i < sizeof(L4D2IntMeleeWeapon_Offsets); i++ )		PrintToServer("L4D2IntMeleeWeapon_Offsets[%d] == %d", i, L4D2IntMeleeWeapon_Offsets[i]);
		for( int i = 0; i < sizeof(L4D2FloatMeleeWeapon_Offsets); i++ )		PrintToServer("L4D2FloatMeleeWeapon_Offsets[%d] == %d", i, L4D2FloatMeleeWeapon_Offsets[i]);
	}
	#endif



	// ====================================================================================================
	//									DETOURS
	// ====================================================================================================
	SetupDetours(hGameData);



	// ====================================================================================================
	//									END
	// ====================================================================================================
	delete hGameData;
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
public int Native_GetVScriptOutput(Handle plugin, int numParams)
{
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

public int Native_Deafen(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_Call_Deafen, "Deafen");

	int client = GetNativeCell(1);

	//PrintToServer("#### CALL g_hSDK_Call_Deafen");
	SDKCall(g_hSDK_Call_Deafen, client, 1.0, 0.0, 0.01 );
}

public int Native_Dissolve(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_Call_Dissolve, "Dissolve");

	int entity = GetNativeCell(1);
	if( entity > MaxClients )
	{
		// Prevent common infected from crashing the server when taking damage from the dissolver.
		SDKHook(entity, SDKHook_OnTakeDamage, OnCommonDamage);
	}

	//PrintToServer("#### CALL g_hSDK_Call_Dissolve");
	int dissolver = SDKCall(g_hSDK_Call_Dissolve, entity, "", GetGameTime() + 0.8, 2, false);
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

public int Native_OnITExpired(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_Call_OnITExpired, "OnITExpired");

	int client = GetNativeCell(1);

	//PrintToServer("#### CALL g_hSDK_Call_OnITExpired");
	SDKCall(g_hSDK_Call_OnITExpired, client);
}

public int Native_AngularVelocity(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_Call_AngularVelocity, "AngularVelocity");

	float vAng[3];
	int entity = GetNativeCell(1);
	GetNativeArray(2, vAng, 3);

	//PrintToServer("#### CALL g_hSDK_Call_AngularVelocity");
	SDKCall(g_hSDK_Call_AngularVelocity, entity, vAng);
}

public int Native_GetRandomPZSpawnPosition(Handle plugin, int numParams)
{
	ValidateAddress(g_pZombieManager, "g_pZombieManager");
	ValidateNatives(g_hSDK_Call_GetRandomPZSpawnPosition, "GetRandomPZSpawnPosition");

	float vPos[3];
	int client = GetNativeCell(1);
	int zombieClass = GetNativeCell(2);
	int attempts = GetNativeCell(3);

	int result = SDKCall(g_hSDK_Call_GetRandomPZSpawnPosition, g_pZombieManager, zombieClass, attempts, client, vPos);
	SetNativeArray(4, vPos, 3);

	return result;
}

public int Native_GetNearestNavArea(Handle plugin, int numParams)
{
	ValidateAddress(g_pNavMesh, "g_pNavMesh");
	ValidateNatives(g_hSDK_Call_GetNearestNavArea, "GetNearestNavArea");

	float vPos[3];
	GetNativeArray(1, vPos, 3);

	//PrintToServer("#### CALL Native_GetNearestNavArea");
	int result = SDKCall(g_hSDK_Call_GetNearestNavArea, g_pNavMesh, vPos, 0, 10000.0, 0, 1, 0);
	return result;
}

public int Native_GetLastKnownarea(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_Call_GetLastKnownArea, "GetLastKnownArea");

	int client = GetNativeCell(1);

	//PrintToServer("#### CALL g_hSDK_Call_GetLastKnownArea");
	return SDKCall(g_hSDK_Call_GetLastKnownArea, client);
}

public int Native_FindRandomSpot(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_Call_FindRandomSpot, "FindRandomSpot");

	float vPos[3];
	int area = GetNativeCell(1);

	//PrintToServer("#### CALL g_hSDK_Call_FindRandomSpot");
	SDKCall(g_hSDK_Call_FindRandomSpot, area, vPos, sizeof(vPos));
	SetNativeArray(2, vPos, sizeof(vPos));
}

public int Native_HasAnySurvivorLeftSafeArea(Handle plugin, int numParams)
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_Call_HasAnySurvivorLeftSafeArea, "HasAnySurvivorLeftSafeArea");

	//PrintToServer("#### CALL g_hSDK_Call_HasAnySurvivorLeftSafeArea");
	return SDKCall(g_hSDK_Call_HasAnySurvivorLeftSafeArea, g_pDirector);
}

public int Native_IsAnySurvivorInStartArea(Handle plugin, int numParams)
{
	if( g_bLeft4Dead2 )
	{
		ValidateAddress(g_pDirector, "g_pDirector");
		ValidateNatives(g_hSDK_Call_IsAnySurvivorInStartArea, "IsAnySurvivorInStartArea");

		//PrintToServer("#### CALL g_hSDK_Call_IsAnySurvivorInStartArea");
		return SDKCall(g_hSDK_Call_IsAnySurvivorInStartArea, g_pDirector);
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

public int Native_IsAnySurvivorInCheckpoint(Handle plugin, int numParams)
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_Call_IsAnySurvivorInCheckpoint, "IsAnySurvivorInCheckpoint");

	//PrintToServer("#### CALL g_hSDK_Call_IsAnySurvivorInCheckpoint");
	return SDKCall(g_hSDK_Call_IsAnySurvivorInCheckpoint, g_pDirector);
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
		ValidateAddress(m_flow, "m_flow");
		ValidateNatives(g_hSDK_Call_GetLastKnownArea, "GetLastKnownArea");

		//PrintToServer("#### CALL InCheckpoint %d g_hSDK_Call_GetLastKnownArea", start);
		int area = SDKCall(g_hSDK_Call_GetLastKnownArea, client);
		if( area == 0 ) return false;

		float flow = view_as<float>(LoadFromAddress(view_as<Address>(area + m_flow), NumberType_Int32));
		return (start ? flow < 3000.0 : flow > 3000.0);
	}

	return false;
}

public int Native_HasPlayerControlledZombies(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_Call_HasPlayerControlledZombies, "HasPlayerControlledZombies");

	return SDKCall(g_hSDK_Call_HasPlayerControlledZombies);
}

public int Native_PipeBombPrj(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_Call_PipeBombPrj, "PipeBombPrj");

	float vPos[3], vAng[3];
	int client = GetNativeCell(1);
	GetNativeArray(2, vPos, 3);
	GetNativeArray(3, vAng, 3);

	//PrintToServer("#### CALL g_hSDK_Call_PipeBombPrj");
	return SDKCall(g_hSDK_Call_PipeBombPrj, vPos, vAng, vAng, vAng, client, 2.0);
}

public int Native_SpitterPrj(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_Call_SpitterPrj, "SpitterPrj");

	float vPos[3], vAng[3];
	int client = GetNativeCell(1);
	GetNativeArray(2, vPos, 3);
	GetNativeArray(3, vAng, 3);

	//PrintToServer("#### CALL g_hSDK_Call_SpitterPrj");
	return SDKCall(g_hSDK_Call_SpitterPrj, vPos, vAng, vAng, vAng, client);
}

public int Native_OnAdrenalineUsed(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_Call_OnAdrenalineUsed, "OnAdrenalineUsed");

	int client = GetNativeCell(1);
	float fTime = GetNativeCell(2);
	bool heal = GetNativeCell(3);

	// Heal
	if( heal )
	{
		float fHealth = GetTempHealth(client);
		fHealth += g_hPillsHealth.FloatValue;
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

	//PrintToServer("#### CALL g_hSDK_Call_OnAdrenalineUsed");
	SDKCall(g_hSDK_Call_OnAdrenalineUsed, client, fTime);
}

public int Native_GetCurrentFinaleStage(Handle plugin, int numParams)
{
	ValidateAddress(ScriptedEventManagerPtr, "ScriptedEventManagerPtr");

	return LoadFromAddress(view_as<Address>(ScriptedEventManagerPtr + 0x04), NumberType_Int32);
}

public int Native_ForceNextStage(Handle plugin, int numParams)
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_Call_ForceNextStage, "ForceNextStage");

	//PrintToServer("#### CALL g_hSDK_Call_ForceNextStage");
	SDKCall(g_hSDK_Call_ForceNextStage, g_pDirector);
}

public int Native_IsTankInPlay(Handle plugin, int numParams)
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_Call_IsTankInPlay, "IsTankInPlay");

	//PrintToServer("#### CALL g_hSDK_Call_IsTankInPlay");
	return SDKCall(g_hSDK_Call_IsTankInPlay, g_pDirector);
}

public int Native_IsReachable(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_Call_IsReachable, "IsReachable");

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
	return SDKCall(g_hSDK_Call_IsReachable, client, vPos);
}

public any Native_GetFurthestSurvivorFlow(Handle plugin, int numParams)
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_Call_GetFurthestSurvivorFlow, "GetFurthestSurvivorFlow");

	//PrintToServer("#### CALL g_hSDK_Call_GetFurthestSurvivorFlow");
	return SDKCall(g_hSDK_Call_GetFurthestSurvivorFlow, g_pDirector);
}

public int Native_NavAreaTravelDistance(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_Call_NavAreaTravelDistance, "NavAreaTravelDistance");

	float vPos[3], vEnd[3];

	GetNativeArray(1, vPos, sizeof(vPos));
	GetNativeArray(2, vEnd, sizeof(vEnd));
	int a3 = GetNativeCell(3);

	//PrintToServer("#### CALL g_hSDK_Call_NavAreaTravelDistance");
	return SDKCall(g_hSDK_Call_NavAreaTravelDistance, vPos, vEnd, a3);
}

public int Native_GetScriptValueInt(Handle plugin, int numParams)
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_Call_GetScriptValueInt, "GetScriptValueInt");

	int maxlength;
	GetNativeStringLength(1, maxlength);
	maxlength += 1;
	char[] key = new char[maxlength];
	GetNativeString(1, key, maxlength);

	int value = GetNativeCell(2);
	return SDKCall(g_hSDK_Call_GetScriptValueInt, g_pDirector, key, value);
}

/* // Only returns default value provided.
public any Native_GetScriptValueFloat(Handle plugin, int numParams)
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_Call_GetScriptValueFloat, "GetScriptValueFloat");

	int maxlength;
	GetNativeStringLength(1, maxlength);
	maxlength += 1;
	char[] key = new char[maxlength];
	GetNativeString(1, key, maxlength);

	float value = GetNativeCell(2);
	return SDKCall(g_hSDK_Call_GetScriptValueFloat, g_pDirector, key, value);
}

// Not implemented, request if really required.
public int Native_GetScriptValueString(Handle plugin, int numParams)
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_Call_GetScriptValueString, "GetScriptValueString");

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

	//PrintToServer("#### CALL g_hSDK_Call_GetScriptValueString");
	SDKCall(g_hSDK_Call_GetScriptValueString, g_pDirector, key, value, retValue, maxlength);
	SetNativeString(3, retValue, maxlength);
}
*/





// ==================================================
// left4downtown.inc
// ==================================================
public int Native_ScavengeBeginRoundSetupTime(Handle plugin, int numParams)
{
	ValidateAddress(ScavengeModePtr, "ScavengeModePtr");
	ValidateAddress(OnBeginRoundSetupTime, "OnBeginRoundSetupTime");

	return LoadFromAddress(view_as<Address>(ScavengeModePtr + OnBeginRoundSetupTime + 4), NumberType_Int32);
}

public int Native_ResetMobTimer(Handle plugin, int numParams)
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_Call_ResetMobTimer, "ResetMobTimer");

	//PrintToServer("#### CALL g_hSDK_Call_ResetMobTimer");
	SDKCall(g_hSDK_Call_ResetMobTimer, g_pDirector);
	return 0;
}

public any Native_GetPlayerSpawnTime(Handle plugin, int numParams)
{
	ValidateAddress(SpawnTimer, "SpawnTimer");

	int client = GetNativeCell(1);
	return (view_as<float>(LoadFromAddress(GetEntityAddress(client) + view_as<Address>(SpawnTimer + 8), NumberType_Int32)) - GetGameTime());
}

public int Native_RestartScenarioFromVote(Handle plugin, int numParams)
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_Call_RestartScenarioFromVote, "RestartScenarioFromVote");

	char map[64];
	GetNativeString(1, map, sizeof(map));

	//PrintToServer("#### CALL g_hSDK_Call_RestartScenarioFromVote");
	return SDKCall(g_hSDK_Call_RestartScenarioFromVote, g_pDirector, map);
}

public int Native_GetVersusMaxCompletionScore(Handle plugin, int numParams)
{
	ValidateAddress(g_pGameRules, "g_pGameRules");
	ValidateAddress(VersusMaxCompletionScore, "VersusMaxCompletionScore");

	return LoadFromAddress(g_pGameRules + view_as<Address>(VersusMaxCompletionScore), NumberType_Int32);
}

public int Native_SetVersusMaxCompletionScore(Handle plugin, int numParams)
{
	ValidateAddress(g_pGameRules, "g_pGameRules");
	ValidateAddress(VersusMaxCompletionScore, "VersusMaxCompletionScore");

	int value = GetNativeCell(1);
	StoreToAddress(g_pGameRules + view_as<Address>(VersusMaxCompletionScore), value, NumberType_Int32);
	return 0;
}

public int Native_GetTeamScore(Handle plugin, int numParams)
{
	#define SCORE_TEAM_A 1
	#define SCORE_TEAM_B 2
	#define SCORE_TYPE_ROUND 0
	#define SCORE_TYPE_CAMPAIGN 1

	if( g_bLeft4Dead2 )
	{
		ValidateNatives(g_hSDK_Call_GetTeamScore, "GetTeamScore");

		//sanity check that the team index is valid
		int team = GetNativeCell(1);
		if( team != SCORE_TEAM_A && team != SCORE_TEAM_B )
		{
			ThrowNativeError(SP_ERROR_PARAM, "Logical team %d is invalid. Accepted values: 1 or 2.", team);
		}

		//campaign_score is a boolean so should be 0 (use round score) or 1 only
		int score = GetNativeCell(2);
		if( score != SCORE_TYPE_ROUND && score != SCORE_TYPE_CAMPAIGN )
		{
			ThrowNativeError(SP_ERROR_PARAM, "campaign_score %d is invalid. Accepted values: 0 or 1", score);
		}

		//PrintToServer("#### CALL g_hSDK_Call_GetTeamScore");
		return SDKCall(g_hSDK_Call_GetTeamScore, team, score);
	// } else {
		// ValidateAddress(TeamScoresAddress, "TeamScoresAddress");
		// ValidateAddress(ClearTeamScore_A, "ClearTeamScore_A");
		// ValidateAddress(ClearTeamScore_B, "ClearTeamScore_B");

		// int team = GetNativeCell(1);
		// if( team != SCORE_TEAM_A && team != SCORE_TEAM_B )
		// {
			// ThrowNativeError(SP_ERROR_PARAM, "Logical team %d is invalid. Accepted values: 1 or 2.", team);
		// }

		// return LoadFromAddress(TeamScoresAddress + view_as<Address>(team == SCORE_TEAM_A ? ClearTeamScore_A : ClearTeamScore_B), NumberType_Int32);
	}
	return -1;
}

public int Native_IsFirstMapInScenario(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_Call_IsFirstMapInScenario, "IsFirstMapInScenario");

	if( !g_bLeft4Dead2 )
	{
		ValidateNatives(SDK_KV_GetString, "SDK_KV_GetString");
		static char sMap[64], check[64];

		/*
		// NULL PTR - METHOD (kept for demonstration)
		// "malloc" replacement hack (method by @Rostu)
		Address pNull = GetEntityAddress(0) + view_as<Address>(m_iClrRender);

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

		int keyvalue = SDKCall(g_hSDK_Call_IsFirstMapInScenario, pNull); // NULL PTR - METHOD (kept for demonstration)
		// */

		//PrintToServer("#### CALL g_hSDK_Call_IsFirstMapInScenario");
		int keyvalue = SDKCall(g_hSDK_Call_IsFirstMapInScenario, 0);

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
			GetCurrentMap(sMap, sizeof(sMap));
			//PrintToServer("#### CALL SDK_KV_GetString");
			SDKCall(SDK_KV_GetString, keyvalue, check, sizeof(check), "map", "N/A");
			return strcmp(sMap, check) == 0;
		}

		return 0;
	}

	//PrintToServer("#### CALL g_hSDK_Call_IsFirstMapInScenario");
	return SDKCall(g_hSDK_Call_IsFirstMapInScenario, g_pDirector);
}

public int Native_IsMissionFinalMap(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_Call_IsMissionFinalMap, "IsMissionFinalMap");

	//PrintToServer("#### CALL g_hSDK_Call_IsMissionFinalMap");
	return SDKCall(g_hSDK_Call_IsMissionFinalMap);
}

public int Native_NotifyNetworkStateChanged(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_Call_NotifyNetworkStateChanged, "NotifyNetworkStateChanged");

	//PrintToServer("#### CALL g_hSDK_Call_NotifyNetworkStateChanged");
	SDKCall(g_hSDK_Call_NotifyNetworkStateChanged);
	return 0;
}

public int Native_StaggerPlayer(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_Call_StaggerPlayer, "StaggerPlayer");

	int a1 = GetNativeCell(1);
	int a2 = GetNativeCell(2);
	float vDir[3];
	GetNativeArray(3, vDir, 3);

	if( IsNativeParamNullVector(3) )
	{
		GetEntPropVector(a2, Prop_Send, "m_vecOrigin", vDir);
	}

	//PrintToServer("#### CALL g_hSDK_Call_StaggerPlayer");
	SDKCall(g_hSDK_Call_StaggerPlayer, a1, a2, vDir);
	return 0;
}

public int Native_ReplaceTank(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_Call_ReplaceTank, "ReplaceTank");

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

	//PrintToServer("#### CALL g_hSDK_Call_ReplaceTank");
	SDKCall(g_hSDK_Call_ReplaceTank, g_pZombieManager, oldtank, newtank);

	// TeleportEntity(oldtank, vOld, vAng, NULL_VECTOR);
	// TeleportEntity(newtank, vNew, NULL_VECTOR, NULL_VECTOR);
	return 0;
}

public int Native_SendInRescueVehicle(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_Call_SendInRescueVehicle, "SendInRescueVehicle");
	if( g_bLeft4Dead2 )		ValidateAddress(ScriptedEventManagerPtr, "ScriptedEventManagerPtr");
	else					ValidateAddress(g_pDirector, "g_pDirector");

	//PrintToServer("#### CALL g_hSDK_Call_SendInRescueVehicle");
	SDKCall(g_hSDK_Call_SendInRescueVehicle, g_bLeft4Dead2 ? ScriptedEventManagerPtr : view_as<int>(g_pDirector));
	return 0;
}

public int Native_ChangeFinaleStage(Handle plugin, int numParams)
{
	ValidateAddress(ScriptedEventManagerPtr, "ScriptedEventManagerPtr");
	ValidateNatives(g_hSDK_Call_ChangeFinaleStage, "ChangeFinaleStage");

	static char arg[64];
	int finaleType = GetNativeCell(1);
	GetNativeString(2, arg, sizeof(arg));

	//PrintToServer("#### CALL g_hSDK_Call_ChangeFinaleStage");
	SDKCall(g_hSDK_Call_ChangeFinaleStage, ScriptedEventManagerPtr, finaleType, arg);
	return 0;
}

public int Native_SpawnTank(Handle plugin, int numParams)
{
	ValidateAddress(g_pZombieManager, "g_pZombieManager");
	ValidateNatives(g_hSDK_Call_SpawnTank, "SpawnTank");

	float vPos[3], vAng[3];
	GetNativeArray(1, vPos, 3);
	GetNativeArray(2, vAng, 3);

	//PrintToServer("#### CALL g_hSDK_Call_SpawnTank");
	return SDKCall(g_hSDK_Call_SpawnTank, g_pZombieManager, vPos, vAng);
}

public int Native_SpawnSpecial(Handle plugin, int numParams)
{
	ValidateAddress(g_pZombieManager, "g_pZombieManager");

	float vPos[3], vAng[3];
	int zombieClass = GetNativeCell(1);
	GetNativeArray(2, vPos, 3);
	GetNativeArray(3, vAng, 3);

	if( g_bLeft4Dead2 )
	{
		ValidateNatives(g_hSDK_Call_SpawnSpecial, "SpawnSpecial");

		//PrintToServer("#### CALL g_hSDK_Call_SpawnSpecial");
		return SDKCall(g_hSDK_Call_SpawnSpecial, g_pZombieManager, zombieClass, vPos, vAng);
	}
	else
	{
		switch( zombieClass )
		{
			case 1:
			{
				ValidateNatives(g_hSDK_Call_SpawnSmoker, "SpawnSmoker");

				//PrintToServer("#### CALL g_hSDK_Call_SpawnSmoker");
				return SDKCall(g_hSDK_Call_SpawnSmoker, g_pZombieManager, vPos, vAng);
			}
			case 2:
			{
				ValidateNatives(g_hSDK_Call_SpawnBoomer, "SpawnBoomer");

				//PrintToServer("#### CALL g_hSDK_Call_SpawnBoomer");
				return SDKCall(g_hSDK_Call_SpawnBoomer, g_pZombieManager, vPos, vAng);
			}
			case 3:
			{
				ValidateNatives(g_hSDK_Call_SpawnHunter, "SpawnHunter");

				//PrintToServer("#### CALL g_hSDK_Call_SpawnHunter");
				return SDKCall(g_hSDK_Call_SpawnHunter, g_pZombieManager, vPos, vAng);
			}
		}
	}

	return 0;
}

public int Native_SpawnWitch(Handle plugin, int numParams)
{
	ValidateAddress(g_pZombieManager, "g_pZombieManager");
	ValidateNatives(g_hSDK_Call_SpawnWitch, "SpawnWitch");

	float vPos[3], vAng[3];
	GetNativeArray(1, vPos, 3);
	GetNativeArray(2, vAng, 3);

	//PrintToServer("#### CALL g_hSDK_Call_SpawnWitch");
	return SDKCall(g_hSDK_Call_SpawnWitch, g_pZombieManager, vPos, vAng);
}

public int Native_SpawnWitchBride(Handle plugin, int numParams)
{
	ValidateAddress(g_pZombieManager, "g_pZombieManager");
	ValidateNatives(g_hSDK_Call_SpawnWitchBride, "SpawnWitchBride");

	float vPos[3], vAng[3];
	GetNativeArray(1, vPos, 3);
	GetNativeArray(2, vAng, 3);

	//PrintToServer("#### CALL g_hSDK_Call_SpawnWitchBride");
	return SDKCall(g_hSDK_Call_SpawnWitchBride, g_pZombieManager, vPos, vAng);
}

public any Native_GetMobSpawnTimerRemaining(Handle plugin, int numParams)
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateAddress(MobSpawnTimer, "MobSpawnTimer");

	float timestamp = view_as<float>(LoadFromAddress(g_pDirector + view_as<Address>(MobSpawnTimer + 8), NumberType_Int32));
	return timestamp - GetGameTime();
}

public any Native_GetMobSpawnTimerDuration(Handle plugin, int numParams)
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateAddress(MobSpawnTimer, "MobSpawnTimer");

	float duration = view_as<float>(LoadFromAddress(g_pDirector + view_as<Address>(MobSpawnTimer + 4), NumberType_Int32));
	return duration > 0.0 ? duration : 0.0;
}

public int Native_LobbyUnreserve(Handle plugin, int numParams)
{
	ValidateAddress(g_pServer, "g_pServer");
	ValidateNatives(g_hSDK_Call_LobbyUnreserve, "LobbyUnreserve");

	SDKCall(g_hSDK_Call_LobbyUnreserve, g_pServer, 0, 0, "Unreserved by Left 4 DHooks");
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
	ValidateNatives(g_hSDK_Call_GetWeaponInfo, "GetWeaponInfo");

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

		//PrintToServer("#### CALL g_hSDK_Call_GetWeaponInfo");
		if( ptr ) ptr = SDKCall(g_hSDK_Call_GetWeaponInfo, ptr);
		if( ptr ) g_aWeaponPtrs.SetValue(weaponName, ptr);
	}

	if( ptr ) return ptr;
	return -1;
}

int GetMeleePointer(int id)
{
	ValidateAddress(g_pMeleeWeaponInfoStore, "g_pMeleeWeaponInfoStore");
	ValidateNatives(g_hSDK_Call_GetMeleeInfo, "GetMeleeInfo");

	int ptr = g_aMeleePtrs.FindValue(id, 0);
	if( ptr == -1 )
	{
		//PrintToServer("#### CALL g_hSDK_Call_GetMeleeInfo");
		ptr = SDKCall(g_hSDK_Call_GetMeleeInfo, g_pMeleeWeaponInfoStore, id);

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
public int Native_IsValidWeapon(Handle plugin, int numParams)
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
		attr = L4D2IntWeapon_Offsets[attr]; // Offset
		StoreToAddress(view_as<Address>(ptr + attr), GetNativeCell(3), NumberType_Int32);
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
}

public int Native_SetFloatMeleeAttribute(Handle plugin, int numParams)
{
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
}

public int Native_SetBoolMeleeAttribute(Handle plugin, int numParams)
{
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
}



// ==================================================
// l4d2timers.inc
// ==================================================
// CountdownTimers
// ==================================================
public int Native_CTimerReset(Handle plugin, int numParams)
{
	ValidateAddress(g_pDirector, "g_pDirector");

	int id = GetNativeCell(1);
	int off = L4D2CountdownTimer_Offsets[id];
	float timestamp = GetGameTime();

	StoreToAddress(view_as<Address>(off + 8), view_as<int>(timestamp), NumberType_Int32);
}

public int Native_CTimerStart(Handle plugin, int numParams)
{
	ValidateAddress(g_pDirector, "g_pDirector");

	int id = GetNativeCell(1);
	int off = L4D2CountdownTimer_Offsets[id];
	float duration = GetNativeCell(2);
	float timestamp = GetGameTime() + duration;

	StoreToAddress(view_as<Address>(off + 4), view_as<int>(duration), NumberType_Int32);
	StoreToAddress(view_as<Address>(off + 8), view_as<int>(timestamp), NumberType_Int32);
}

public int Native_CTimerInvalidate(Handle plugin, int numParams)
{
	ValidateAddress(g_pDirector, "g_pDirector");

	int id = GetNativeCell(1);
	int off = L4D2CountdownTimer_Offsets[id];
	float timestamp = -1.0;

	StoreToAddress(view_as<Address>(off + 8), view_as<int>(timestamp), NumberType_Int32);
}

public int Native_CTimerHasStarted(Handle plugin, int numParams)
{
	ValidateAddress(g_pDirector, "g_pDirector");

	int id = GetNativeCell(1);
	int off = L4D2CountdownTimer_Offsets[id];
	float timestamp = view_as<float>(LoadFromAddress(view_as<Address>(off + 8), NumberType_Int32));

	return (timestamp >= 0.0);
}

public int Native_CTimerIsElapsed(Handle plugin, int numParams)
{
	ValidateAddress(g_pDirector, "g_pDirector");

	int id = GetNativeCell(1);
	int off = L4D2CountdownTimer_Offsets[id];
	float timestamp = view_as<float>(LoadFromAddress(view_as<Address>(off + 8), NumberType_Int32));

	return (GetGameTime() >= timestamp);
}

public any Native_CTimerGetElapsedTime(Handle plugin, int numParams)
{
	ValidateAddress(g_pDirector, "g_pDirector");

	int id = GetNativeCell(1);
	int off = L4D2CountdownTimer_Offsets[id];
	float duration = view_as<float>(LoadFromAddress(view_as<Address>(off + 4), NumberType_Int32));
	float timestamp = view_as<float>(LoadFromAddress(view_as<Address>(off + 8), NumberType_Int32));

	return GetGameTime() - timestamp + duration;
}

public any Native_CTimerGetRemainingTime(Handle plugin, int numParams)
{
	ValidateAddress(g_pDirector, "g_pDirector");

	int id = GetNativeCell(1);
	int off = L4D2CountdownTimer_Offsets[id];
	float timestamp = view_as<float>(LoadFromAddress(view_as<Address>(off + 8), NumberType_Int32));

	return (timestamp - GetGameTime());
}

public any Native_CTimerGetCountdownDuration(Handle plugin, int numParams)
{
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
	ValidateAddress(g_pDirector, "g_pDirector");

	int id = GetNativeCell(1);
	int off = L4D2IntervalTimer_Offsets[id];
	float timestamp = GetGameTime();

	StoreToAddress(view_as<Address>(off + 4), view_as<int>(timestamp), NumberType_Int32);
}

public int Native_ITimerInvalidate(Handle plugin, int numParams)
{
	ValidateAddress(g_pDirector, "g_pDirector");

	int id = GetNativeCell(1);
	int off = L4D2IntervalTimer_Offsets[id];
	float timestamp = -1.0;

	StoreToAddress(view_as<Address>(off + 4), view_as<int>(timestamp), NumberType_Int32);
}

public int Native_ITimerHasStarted(Handle plugin, int numParams)
{
	ValidateAddress(g_pDirector, "g_pDirector");

	int id = GetNativeCell(1);
	int off = L4D2IntervalTimer_Offsets[id];
	float timestamp = view_as<float>(LoadFromAddress(view_as<Address>(off + 4), NumberType_Int32));

	return (timestamp > 0.0);
}

public any Native_ITimerGetElapsedTime(Handle plugin, int numParams)
{
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
	int val;

	if( g_bLeft4Dead2 )
	{
		ValidateAddress(g_pDirector, "g_pDirector");

		val = LoadFromAddress(g_pDirector + view_as<Address>(m_iTankCount), NumberType_Int32);
	} else {
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) && GetClientTeam(i) == 3 && GetEntProp(i, Prop_Send, "m_zombieClass") == g_iClassTank )
			{
				val++;
			}
		}
	}

	return val;
}

public int Native_GetWitchCount(Handle plugin, int numParams)
{
	int val;

	if( g_bLeft4Dead2 )
	{
		ValidateAddress(g_pDirector, "g_pDirector");

		val = LoadFromAddress(g_pDirector + view_as<Address>(m_iWitchCount), NumberType_Int32);
	} else {
		int entity = -1;
		while( (entity = FindEntityByClassname(entity, "witch")) != INVALID_ENT_REFERENCE )
		{
			val++;
		}
	}

	return val;
}

public int Native_IsFinaleEscapeInProgress(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_Call_IsFinaleEscapeInProgress, "g_hSDK_Call_IsFinaleEscapeInProgress");
	ValidateAddress(g_pDirector, "g_pDirector");

	return SDKCall(g_hSDK_Call_IsFinaleEscapeInProgress, g_pDirector);
}

public int Native_SetHumanSpec(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_Call_SetHumanSpec, "g_hSDK_Call_SetHumanSpec");

	int bot = GetNativeCell(1);
	int client = GetNativeCell(2);

	return SDKCall(g_hSDK_Call_SetHumanSpec, bot, client);
}

public int Native_TakeOverBot(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_Call_TakeOverBot, "g_hSDK_Call_TakeOverBot");

	int client = GetNativeCell(1);

	return SDKCall(g_hSDK_Call_TakeOverBot, client, true);
}

public int Native_CanBecomeGhost(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_Call_CanBecomeGhost, "g_hSDK_Call_CanBecomeGhost");

	int client = GetNativeCell(1);

	return SDKCall(g_hSDK_Call_CanBecomeGhost, client, true);
}

public int Native_AreWanderersAllowed(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_Call_AreWanderersAllowed, "g_hSDK_Call_AreWanderersAllowed");
	ValidateAddress(g_pDirector, "g_pDirector");

	return SDKCall(g_hSDK_Call_AreWanderersAllowed, g_pDirector);
}

public int Native_GetVersusCampaignScores(Handle plugin, int numParams)
{
	ValidateAddress(VersusModePtr, "VersusModePtr");
	ValidateAddress(VersusModePtr, "m_iCampaignScores");

	int vals[2];
	vals[0] = LoadFromAddress(view_as<Address>(VersusModePtr + m_iCampaignScores), NumberType_Int32);
	vals[1] = LoadFromAddress(view_as<Address>(VersusModePtr + m_iCampaignScores + 4), NumberType_Int32);
	SetNativeArray(1, vals, 2);

	return 0;
}

public int Native_SetVersusCampaignScores(Handle plugin, int numParams)
{
	ValidateAddress(VersusModePtr, "VersusModePtr");
	ValidateAddress(VersusModePtr, "m_iCampaignScores");

	int vals[2];
	GetNativeArray(1, vals, 2);
	StoreToAddress(view_as<Address>(VersusModePtr + m_iCampaignScores), vals[0], NumberType_Int32);
	StoreToAddress(view_as<Address>(VersusModePtr + m_iCampaignScores + 4), vals[1], NumberType_Int32);
}

public int Native_GetVersusTankFlowPercent(Handle plugin, int numParams)
{
	ValidateAddress(VersusModePtr, "VersusModePtr");
	ValidateAddress(VersusModePtr, "m_fTankSpawnFlowPercent");

	float vals[2];
	vals[0] = view_as<float>(LoadFromAddress(view_as<Address>(VersusModePtr + m_fTankSpawnFlowPercent), NumberType_Int32));
	vals[1] = view_as<float>(LoadFromAddress(view_as<Address>(VersusModePtr + m_fTankSpawnFlowPercent + 4), NumberType_Int32));
	SetNativeArray(1, vals, 2);

	return 0;
}

public int Native_SetVersusTankFlowPercent(Handle plugin, int numParams)
{
	ValidateAddress(VersusModePtr, "VersusModePtr");
	ValidateAddress(VersusModePtr, "m_fTankSpawnFlowPercent");

	float vals[2];
	GetNativeArray(1, vals, 2);
	StoreToAddress(view_as<Address>(VersusModePtr + m_fTankSpawnFlowPercent), view_as<int>(vals[0]), NumberType_Int32);
	StoreToAddress(view_as<Address>(VersusModePtr + m_fTankSpawnFlowPercent + 4), view_as<int>(vals[1]), NumberType_Int32);
}

public int Native_GetVersusWitchFlowPercent(Handle plugin, int numParams)
{
	ValidateAddress(VersusModePtr, "VersusModePtr");
	ValidateAddress(VersusModePtr, "m_fWitchSpawnFlowPercent");

	float vals[2];
	vals[0] = view_as<float>(LoadFromAddress(view_as<Address>(VersusModePtr + m_fWitchSpawnFlowPercent), NumberType_Int32));
	vals[1] = view_as<float>(LoadFromAddress(view_as<Address>(VersusModePtr + m_fWitchSpawnFlowPercent + 4), NumberType_Int32));
	SetNativeArray(1, vals, 2);

	return 0;
}

public int Native_SetVersusWitchFlowPercent(Handle plugin, int numParams)
{
	ValidateAddress(VersusModePtr, "VersusModePtr");
	ValidateAddress(VersusModePtr, "m_fWitchSpawnFlowPercent");

	float vals[2];
	GetNativeArray(1, vals, 2);
	StoreToAddress(view_as<Address>(VersusModePtr + m_fWitchSpawnFlowPercent), view_as<int>(vals[0]), NumberType_Int32);
	StoreToAddress(view_as<Address>(VersusModePtr + m_fWitchSpawnFlowPercent + 4), view_as<int>(vals[1]), NumberType_Int32);
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
	ValidateAddress(m_PendingMobCount, "m_PendingMobCount");

	return LoadFromAddress(g_pZombieManager + view_as<Address>(m_PendingMobCount), NumberType_Int32);
}

public int Direct_SetPendingMobCount(Handle plugin, int numParams)
{
	ValidateAddress(g_pZombieManager, "g_pZombieManager");
	ValidateAddress(m_PendingMobCount, "m_PendingMobCount");

	int count = GetNativeCell(1);
	StoreToAddress(g_pZombieManager + view_as<Address>(m_PendingMobCount), count, NumberType_Int32);
}

public any Direct_GetMobSpawnTimer(Handle plugin, int numParams)
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateAddress(MobSpawnTimer, "MobSpawnTimer");

	return view_as<CountdownTimer>(g_pDirector + view_as<Address>(MobSpawnTimer));
}

public any Direct_GetSIClassDeathTimer(Handle plugin, int numParams)
{
	ValidateAddress(g_pDirector, "g_pDirector");

	int class = GetNativeCell(1);
	if( class < 1 || class > 6 ) return CTimer_Null;

	int offset = L4D2IntervalTimer_Offsets[class];
	return view_as<IntervalTimer>(view_as<Address>(offset));
}

public any Direct_GetSIClassSpawnTimer(Handle plugin, int numParams)
{
	ValidateAddress(g_pDirector, "g_pDirector");

	int class = GetNativeCell(1);
	if( class < 1 || class > 6 ) return CTimer_Null;

	int offset = L4D2CountdownTimer_Offsets[class];
	return view_as<CountdownTimer>(view_as<Address>(offset));
}

public int Direct_GetTankPassedCount(Handle plugin, int numParams)
{
	ValidateAddress(g_pDirector, "g_pDirector");

	return LoadFromAddress(g_pDirector + view_as<Address>(m_iTankPassedCount), NumberType_Int32);
}

public int Direct_SetTankPassedCount(Handle plugin, int numParams)
{
	ValidateAddress(g_pDirector, "g_pDirector");

	int passes = GetNativeCell(1);
	StoreToAddress(g_pDirector + view_as<Address>(m_iTankPassedCount), passes, NumberType_Int32);
}

public int Direct_GetVSCampaignScore(Handle plugin, int numParams)
{
	ValidateAddress(VersusModePtr, "VersusModePtr");
	ValidateAddress(m_iCampaignScores, "m_iCampaignScores");

	int team = GetNativeCell(1);
	if( team < 0 || team > 1 ) return -1;

	return LoadFromAddress(view_as<Address>(VersusModePtr + m_iCampaignScores + (team * 4)), NumberType_Int32);
}

public int Direct_SetVSCampaignScore(Handle plugin, int numParams)
{
	ValidateAddress(VersusModePtr, "VersusModePtr");
	ValidateAddress(m_iCampaignScores, "m_iCampaignScores");

	int team = GetNativeCell(1);
	if( team < 0 || team > 1 ) return;

	int score = GetNativeCell(2);
	StoreToAddress(view_as<Address>(VersusModePtr + m_iCampaignScores + (team * 4)), score, NumberType_Int32);
}

public any Direct_GetVSTankFlowPercent(Handle plugin, int numParams)
{
	ValidateAddress(VersusModePtr, "VersusModePtr");
	ValidateAddress(m_fTankSpawnFlowPercent, "m_fTankSpawnFlowPercent");

	int round = GetNativeCell(1);
	if( round < 0 || round > 1 ) return -1.0;

	int team = round ^ GameRules_GetProp("m_bInSecondHalfOfRound") != GameRules_GetProp("m_bAreTeamsFlipped");

	return LoadFromAddress(view_as<Address>(VersusModePtr + m_fTankSpawnFlowPercent + (team * 4)), NumberType_Int32);
}

public int Direct_SetVSTankFlowPercent(Handle plugin, int numParams)
{
	ValidateAddress(VersusModePtr, "VersusModePtr");
	ValidateAddress(m_fTankSpawnFlowPercent, "m_fTankSpawnFlowPercent");

	int round = GetNativeCell(1);
	if( round < 0 || round > 1 ) return;

	int team = round ^ GameRules_GetProp("m_bInSecondHalfOfRound") != GameRules_GetProp("m_bAreTeamsFlipped");
	float flow = GetNativeCell(2);

	StoreToAddress(view_as<Address>(VersusModePtr + m_fTankSpawnFlowPercent + (team * 4)), view_as<int>(flow), NumberType_Int32);
}

public int Direct_GetVSTankToSpawnThisRound(Handle plugin, int numParams)
{
	ValidateAddress(VersusModePtr, "VersusModePtr");
	ValidateAddress(m_bTankThisRound, "m_bTankThisRound");

	int round = GetNativeCell(1);
	if( round < 0 || round > 1 ) return false;

	int team = round ^ GameRules_GetProp("m_bInSecondHalfOfRound") != GameRules_GetProp("m_bAreTeamsFlipped");

	return LoadFromAddress(view_as<Address>(VersusModePtr + m_bTankThisRound + team), NumberType_Int8);
}

public int Direct_SetVSTankToSpawnThisRound(Handle plugin, int numParams)
{
	ValidateAddress(VersusModePtr, "VersusModePtr");
	ValidateAddress(m_bTankThisRound, "m_bTankThisRound");

	int round = GetNativeCell(1);
	if( round < 0 || round > 1 ) return;

	int team = round ^ GameRules_GetProp("m_bInSecondHalfOfRound") != GameRules_GetProp("m_bAreTeamsFlipped");
	bool spawn = GetNativeCell(2);

	StoreToAddress(view_as<Address>(VersusModePtr + m_bTankThisRound + team), spawn, NumberType_Int8);
}

public any Direct_GetVSWitchFlowPercent(Handle plugin, int numParams)
{
	ValidateAddress(VersusModePtr, "VersusModePtr");
	ValidateAddress(m_fWitchSpawnFlowPercent, "m_fWitchSpawnFlowPercent");

	int round = GetNativeCell(1);
	if( round < 0 || round > 1 ) return false;

	int team = round ^ GameRules_GetProp("m_bInSecondHalfOfRound") != GameRules_GetProp("m_bAreTeamsFlipped");

	return LoadFromAddress(view_as<Address>(VersusModePtr + m_fWitchSpawnFlowPercent + (team * 4)), NumberType_Int32);
}

public int Direct_SetVSWitchFlowPercent(Handle plugin, int numParams)
{
	ValidateAddress(VersusModePtr, "VersusModePtr");
	ValidateAddress(m_fWitchSpawnFlowPercent, "m_fWitchSpawnFlowPercent");

	int round = GetNativeCell(1);
	if( round < 0 || round > 1 ) return;

	int team = round ^ GameRules_GetProp("m_bInSecondHalfOfRound") != GameRules_GetProp("m_bAreTeamsFlipped");
	float flow = GetNativeCell(2);

	StoreToAddress(view_as<Address>(VersusModePtr + m_fWitchSpawnFlowPercent + (team * 4)), view_as<int>(flow), NumberType_Int32);
}

public int Direct_GetVSWitchToSpawnThisRound(Handle plugin, int numParams)
{
	ValidateAddress(VersusModePtr, "VersusModePtr");
	ValidateAddress(m_bWitchThisRound, "m_bWitchThisRound");

	int round = GetNativeCell(1);
	if( round < 0 || round > 1 ) return false;

	int team = round ^ GameRules_GetProp("m_bInSecondHalfOfRound") != GameRules_GetProp("m_bAreTeamsFlipped");

	return LoadFromAddress(view_as<Address>(VersusModePtr + m_bWitchThisRound + team), NumberType_Int8);
}

public int Direct_SetVSWitchToSpawnThisRound(Handle plugin, int numParams)
{
	ValidateAddress(VersusModePtr, "VersusModePtr");
	ValidateAddress(m_bWitchThisRound, "m_bWitchThisRound");

	int round = GetNativeCell(1);
	if( round < 0 || round > 1 ) return;

	int team = round ^ GameRules_GetProp("m_bInSecondHalfOfRound") != GameRules_GetProp("m_bAreTeamsFlipped");
	bool spawn = GetNativeCell(2);

	StoreToAddress(view_as<Address>(VersusModePtr + m_bWitchThisRound + team), spawn, NumberType_Int8);
}

public any Direct_GetVSStartTimer(Handle plugin, int numParams)
{
	ValidateAddress(VersusModePtr, "VersusModePtr");

	int offset;

	if( g_bLeft4Dead2 )
		offset = L4D2CountdownTimer_Offsets[7]; // L4D2CountdownTimer_VersusStartTimer
	else
		offset = VersusModePtr + VersusStartTimer;

	ValidateAddress(offset, "VersusStartTimer");
	return view_as<CountdownTimer>(view_as<Address>(offset));
}

public any Direct_GetScavengeRoundSetupTimer(Handle plugin, int numParams)
{
	ValidateAddress(ScavengeModePtr, "ScavengeModePtr");
	ValidateAddress(OnBeginRoundSetupTime, "OnBeginRoundSetupTime");

	return view_as<CountdownTimer>(view_as<Address>(ScavengeModePtr + OnBeginRoundSetupTime));
}

public any Direct_GetScavengeOvertimeGraceTimer(Handle plugin, int numParams)
{
	ValidateAddress(ScavengeModePtr, "ScavengeModePtr");
	ValidateAddress(OvertimeGraceTimer, "OvertimeGraceTimer");

	return view_as<CountdownTimer>(view_as<Address>(ScavengeModePtr + OvertimeGraceTimer));
}

public any Direct_GetMapMaxFlowDistance(Handle plugin, int numParams)
{
	ValidateAddress(g_pNavMesh, "g_pNavMesh");
	ValidateAddress(m_fMapMaxFlowDistance, "m_fMapMaxFlowDistance");

	return LoadFromAddress(g_pNavMesh + view_as<Address>(m_fMapMaxFlowDistance), NumberType_Int32);
}

public any Direct_GetSpawnTimer(Handle plugin, int numParams)
{
	ValidateAddress(SpawnTimer, "SpawnTimer");

	int client = GetNativeCell(1);
	if( client < 1 || client > MaxClients )
		return CTimer_Null;

	Address pEntity = GetEntityAddress(client);
	if( pEntity == Address_Null )
		return CTimer_Null;

	return view_as<CountdownTimer>(pEntity + view_as<Address>(SpawnTimer));
}

public any Direct_GetInvulnerabilityTimer(Handle plugin, int numParams)
{
	ValidateAddress(InvulnerabilityTimer, "InvulnerabilityTimer");

	int client = GetNativeCell(1);
	if( client < 1 || client > MaxClients )
		return CTimer_Null;

	Address pEntity = GetEntityAddress(client);
	if( pEntity == Address_Null )
		return CTimer_Null;

	return view_as<CountdownTimer>(pEntity + view_as<Address>(InvulnerabilityTimer));
}

public int Direct_GetTankTickets(Handle plugin, int numParams)
{
	ValidateAddress(m_iTankTickets, "m_iTankTickets");

	int client = GetNativeCell(1);
	if( client < 1 || client > MaxClients )
		return -1;

	Address pEntity = GetEntityAddress(client);
	if( pEntity == Address_Null )
		return -1;

	return LoadFromAddress(pEntity + view_as<Address>(m_iTankTickets), NumberType_Int32);
}

public int Direct_SetTankTickets(Handle plugin, int numParams)
{
	ValidateAddress(m_iTankTickets, "m_iTankTickets");

	int client = GetNativeCell(1);
	if( client < 1 || client > MaxClients )
		return;

	Address pEntity = GetEntityAddress(client);
	if( pEntity == Address_Null )
		return;

	int tickets = GetNativeCell(2);
	StoreToAddress(pEntity + view_as<Address>(m_iTankTickets), tickets, NumberType_Int32);
}

public int Direct_GetShovePenalty(Handle plugin, int numParams)
{
	ValidateAddress(m_iShovePenalty, "m_iShovePenalty");

	int client = GetNativeCell(1);
	if( client < 1 || client > MaxClients )
		return -1;

	Address pEntity = GetEntityAddress(client);
	if( pEntity == Address_Null )
		return -1;

	return LoadFromAddress(pEntity + view_as<Address>(m_iShovePenalty), NumberType_Int32);
}

public int Direct_SetShovePenalty(Handle plugin, int numParams)
{
	ValidateAddress(m_iShovePenalty, "m_iShovePenalty");

	int client = GetNativeCell(1);
	if( client < 1 || client > MaxClients )
		return;

	Address pEntity = GetEntityAddress(client);
	if( pEntity == Address_Null )
		return;

	int penalty = GetNativeCell(2);
	StoreToAddress(pEntity + view_as<Address>(m_iShovePenalty), penalty, NumberType_Int32);
}

public any Direct_GetNextShoveTime(Handle plugin, int numParams)
{
	ValidateAddress(m_fNextShoveTime, "m_fNextShoveTime");

	int client = GetNativeCell(1);
	if( client < 1 || client > MaxClients )
		return 0.0;

	Address pEntity = GetEntityAddress(client);
	if( pEntity == Address_Null )
		return 0.0;

	return LoadFromAddress(pEntity + view_as<Address>(m_fNextShoveTime), NumberType_Int32);
}

public int Direct_SetNextShoveTime(Handle plugin, int numParams)
{
	ValidateAddress(m_fNextShoveTime, "m_fNextShoveTime");

	int client = GetNativeCell(1);
	if( client < 1 || client > MaxClients )
		return;

	Address pEntity = GetEntityAddress(client);
	if( pEntity == Address_Null )
		return;

	float time = GetNativeCell(2);
	StoreToAddress(pEntity + view_as<Address>(m_fNextShoveTime), view_as<int>(time), NumberType_Int32);
}

public int Direct_GetPreIncapHealth(Handle plugin, int numParams)
{
	ValidateAddress(m_preIncapacitatedHealth, "m_preIncapacitatedHealth");

	int client = GetNativeCell(1);
	if( client < 1 || client > MaxClients )
		return -1;

	Address pEntity = GetEntityAddress(client);
	if( pEntity == Address_Null )
		return -1;

	return LoadFromAddress(pEntity + view_as<Address>(m_preIncapacitatedHealth), NumberType_Int32);
}

public int Direct_SetPreIncapHealth(Handle plugin, int numParams)
{
	ValidateAddress(m_preIncapacitatedHealth, "m_preIncapacitatedHealth");

	int client = GetNativeCell(1);
	if( client < 1 || client > MaxClients )
		return;

	Address pEntity = GetEntityAddress(client);
	if( pEntity == Address_Null )
		return;

	int health = GetNativeCell(2);
	StoreToAddress(pEntity + view_as<Address>(m_preIncapacitatedHealth), health, NumberType_Int32);
}

public int Direct_GetPreIncapHealthBuffer(Handle plugin, int numParams)
{
	ValidateAddress(m_preIncapacitatedHealthBuffer, "m_preIncapacitatedHealthBuffer");

	int client = GetNativeCell(1);
	if( client < 1 || client > MaxClients )
		return -1;

	Address pEntity = GetEntityAddress(client);
	if( pEntity == Address_Null )
		return -1;

	return LoadFromAddress(pEntity + view_as<Address>(m_preIncapacitatedHealthBuffer), NumberType_Int32);
}

public int Direct_SetPreIncapHealthBuffer(Handle plugin, int numParams)
{
	ValidateAddress(m_preIncapacitatedHealthBuffer, "m_preIncapacitatedHealthBuffer");

	int client = GetNativeCell(1);
	if( client < 1 || client > MaxClients )
		return;

	Address pEntity = GetEntityAddress(client);
	if( pEntity == Address_Null )
		return;

	int health = GetNativeCell(2);
	StoreToAddress(pEntity + view_as<Address>(m_preIncapacitatedHealthBuffer), health, NumberType_Int32);
}

public int Direct_GetInfernoMaxFlames(Handle plugin, int numParams)
{
	ValidateAddress(m_maxFlames, "m_maxFlames");

	int client = GetNativeCell(1);

	Address pEntity = GetEntityAddress(client);
	if( pEntity == Address_Null )
		return -1;

	return LoadFromAddress(pEntity + view_as<Address>(m_maxFlames), NumberType_Int32);
}

public int Direct_SetInfernoMaxFlames(Handle plugin, int numParams)
{
	ValidateAddress(m_maxFlames, "m_maxFlames");

	int entity = GetNativeCell(1);

	Address pEntity = GetEntityAddress(entity);
	if( pEntity == Address_Null )
		return;

	int flames = GetNativeCell(2);
	StoreToAddress(pEntity + view_as<Address>(m_maxFlames), flames, NumberType_Int32);
}

public int Direct_GetScriptedEventManager(Handle plugin, int numParams)
{
	ValidateAddress(ScriptedEventManagerPtr, "ScriptedEventManagerPtr");

	return ScriptedEventManagerPtr;
}

public any Direct_GetTerrorNavArea(Handle plugin, int numParams)
{
	ValidateAddress(g_pNavMesh, "g_pNavMesh");
	ValidateNatives(g_hSDK_Call_GetNavArea, "g_hSDK_Call_GetNavArea");

	float vPos[3];
	GetNativeArray(1, vPos, 3);

	float beneathLimit = GetNativeCell(2);

	//PrintToServer("#### CALL g_hSDK_Call_GetNavArea");
	return SDKCall(g_hSDK_Call_GetNavArea, g_pNavMesh, vPos, beneathLimit);
}

public any Direct_GetTerrorNavAreaFlow(Handle plugin, int numParams)
{
	ValidateAddress(m_flow, "m_flow");

	Address pTerrorNavArea = GetNativeCell(1);
	if( pTerrorNavArea == Address_Null )
		return 0.0;

	return view_as<float>(LoadFromAddress(pTerrorNavArea + view_as<Address>(m_flow), NumberType_Int32));
}

public int Direct_TryOfferingTankBot(Handle plugin, int numParams)
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_Call_TryOfferingTankBot, "TryOfferingTankBot");

	int entity = GetNativeCell(1);
	bool bEnterStasis = GetNativeCell(2);

	//PrintToServer("#### CALL g_hSDK_Call_TryOfferingTankBot");
	SDKCall(g_hSDK_Call_TryOfferingTankBot, g_pDirector, entity, bEnterStasis);
}

public any Direct_GetFlowDistance(Handle plugin, int numParams)
{
	ValidateAddress(m_flow, "m_flow");
	ValidateNatives(g_hSDK_Call_GetLastKnownArea, "GetLastKnownArea");

	int client = GetNativeCell(1);

	int area = SDKCall(g_hSDK_Call_GetLastKnownArea, client);
	if( area == 0 ) return 0.0;

	float flow = view_as<float>(LoadFromAddress(view_as<Address>(area + m_flow), NumberType_Int32));
	if( flow == -9999.0 ) flow = 0.0;

	return flow;
}

public int Direct_DoAnimationEvent(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_Call_DoAnimationEvent, "DoAnimationEvent");

	int client = GetNativeCell(1);
	if( client <= 0 || client > MaxClients )
		return;

	int event = GetNativeCell(2);
	//PrintToServer("#### CALL g_hSDK_Call_DoAnimationEvent");
	SDKCall(g_hSDK_Call_DoAnimationEvent, client, event, 0);
}



// ==================================================
// NATIVES: l4d2d_timers.inc
// ==================================================
public int Direct_CTimer_Reset(Handle plugin, int numParams)
{
	CountdownTimer timer = GetNativeCell(1);
	Stock_CTimer_Reset(timer);
}

public int Direct_CTimer_Start(Handle plugin, int numParams)
{
	CountdownTimer timer = GetNativeCell(1);
	float duration = GetNativeCell(2);
	Stock_CTimer_Start(timer, duration);
}

public int Direct_CTimer_Invalidate(Handle plugin, int numParams)
{
	CountdownTimer timer = GetNativeCell(1);
	Stock_CTimer_Invalidate(timer);
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
}

public int Direct_ITimer_Start(Handle plugin, int numParams)
{
	IntervalTimer timer = GetNativeCell(1);
	Stock_ITimer_Start(timer);
}

public int Direct_ITimer_Invalidate(Handle plugin, int numParams)
{
	IntervalTimer timer = GetNativeCell(1);
	Stock_ITimer_Invalidate(timer);
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
	ValidateNatives(g_hSDK_Call_CTerrorPlayer_OnVomitedUpon, "CTerrorPlayer_OnVomitedUpon");

	int client = GetNativeCell(1);
	int attacker = GetNativeCell(2);
	SDKCall(g_hSDK_Call_CTerrorPlayer_OnVomitedUpon, client, attacker, false);
}

public int Native_CTerrorPlayer_OnHitByVomitJar(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_Call_CTerrorPlayer_OnHitByVomitJar, "CTerrorPlayer_OnHitByVomitJar");

	int client = GetNativeCell(1);
	int attacker = GetNativeCell(2);
	SDKCall(g_hSDK_Call_CTerrorPlayer_OnHitByVomitJar, client, attacker, true);
}

public int Native_Infected_OnHitByVomitJar(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_Call_Infected_OnHitByVomitJar, "Infected_OnHitByVomitJar");

	int entity = GetNativeCell(1);
	int attacker = GetNativeCell(2);
	SDKCall(g_hSDK_Call_Infected_OnHitByVomitJar, entity, attacker, true);
}

public int Native_CTerrorPlayer_Fling(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_Call_Fling, "Fling");

	int client = GetNativeCell(1);
	int attacker = GetNativeCell(2);
	float vDir[3];
	GetNativeArray(3, vDir, 3);
	SDKCall(g_hSDK_Call_Fling, client, vDir, 76, attacker, 3.0); // 76 is the 'got bounced' animation in L4D2. 3.0 = incapTime, what's this mean?
}

public int Native_CancelStagger(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_Call_CancelStagger, "CancelStagger");

	int client = GetNativeCell(1);
	SDKCall(g_hSDK_Call_CancelStagger, client);
}

public int Native_RespawnPlayer(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_Call_RoundRespawn, "g_hSDK_Call_RoundRespawn");

	int client = GetNativeCell(1);
	SDKCall(g_hSDK_Call_RoundRespawn, client);
}

public int Native_CreateRescuableSurvivors(Handle plugin, int numParams)
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_Call_CreateRescuableSurvivors, "CreateRescuableSurvivors");

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
}

void OnFrameRescue(int count)
{
	count--;
	if( count > 0 ) RequestFrame(OnFrameRescue, count);
	RespawnRescue();
}

void RespawnRescue()
{
	StoreToAddress(g_pDirector + view_as<Address>(m_rescueCheckTimer + 8), view_as<int>(0.0), NumberType_Int32);

	int time = g_hCvarRescueDeadTime.IntValue;
	g_hCvarRescueDeadTime.SetInt(0);
	SDKCall(g_hSDK_Call_CreateRescuableSurvivors, g_pDirector);
	g_hCvarRescueDeadTime.SetInt(time);
}

public int Native_OnRevived(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_Call_OnRevived, "OnRevived");

	int client = GetNativeCell(1);
	SDKCall(g_hSDK_Call_OnRevived, client);
}

public any Native_GetVersusCompletionPlayer(Handle plugin, int numParams)
{
	ValidateAddress(g_pGameRules, "g_pGameRules");
	ValidateNatives(g_hSDK_Call_GetVersusCompletionPlayer, "GetVersusCompletionPlayer");

	int client = GetNativeCell(1);
	return SDKCall(g_hSDK_Call_GetVersusCompletionPlayer, g_pGameRules, client);
}

public int Native_GetHighestFlowSurvivor(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_Call_GetHighestFlowSurvivor, "GetHighestFlowSurvivor");
	return SDKCall(g_hSDK_Call_GetHighestFlowSurvivor, 0, 0);
}

public any Native_GetInfectedFlowDistance(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_Call_GetInfectedFlowDistance, "GetInfectedFlowDistance");

	int entity = GetNativeCell(1);
	if( entity > MaxClients )
	{
		return SDKCall(g_hSDK_Call_GetInfectedFlowDistance, entity);
	}

	return 0.0;
}

public int Native_TakeOverZombieBot(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_Call_TakeOverZombieBot, "TakeOverZombieBot");

	int client = GetNativeCell(1);
	int target = GetNativeCell(2);

	if( client > 0 && client <= MaxClients && target > 0 && target <= MaxClients &&
		GetClientTeam(client) == 3 && GetClientTeam(target) == 3 &&
		IsFakeClient(client) == false && IsFakeClient(target) == true )
	{
		if( g_bLeft4Dead2 )
			SDKCall(g_hSDK_Call_TakeOverZombieBot, client, target);
		else
		{
			// Workaround spawning wrong type, you'll hear another special infected type sound when spawning.
			int zombieClass = GetEntProp(target, Prop_Send, "m_zombieClass");
			SDKCall(g_hSDK_Call_TakeOverZombieBot, client, target);
			SetClass(client, zombieClass);
		}
	}
}

public int Native_ReplaceWithBot(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_Call_ReplaceWithBot, "ReplaceWithBot");

	int client = GetNativeCell(1);

	float vPos[3], vAng[3];
	GetClientAbsOrigin(client, vPos);
	GetClientEyeAngles(client, vAng);

	SDKCall(g_hSDK_Call_ReplaceWithBot, client, true);
	SDKCall(g_hSDK_Call_BecomeGhost, client, 0, 0); // Otherwise they duplicate bots and don't go into ghost mode
	TeleportEntity(client, vPos, vAng, NULL_VECTOR);
}

public int Native_CullZombie(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_Call_CullZombie, "CullZombie");

	int client = GetNativeCell(1);
	SDKCall(g_hSDK_Call_CullZombie, client);
}

public int Native_SetClass(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_Call_SetClass, "SetClass");
	ValidateNatives(g_hSDK_Call_CreateAbility, "CreateAbility");

	int client = GetNativeCell(1);
	int zombieClass = GetNativeCell(2);

	SetClass(client, zombieClass);
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

	SDKCall(g_hSDK_Call_SetClass, client, zombieClass);

	ability = SDKCall(g_hSDK_Call_CreateAbility, client);
	if( ability != -1 ) SetEntPropEnt(client, Prop_Send, "m_customAbility", ability);
}

public int Native_MaterializeFromGhost(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_Call_MaterializeFromGhost, "MaterializeFromGhost");

	int client = GetNativeCell(1);
	if( GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_isGhost") )
	{
		SDKCall(g_hSDK_Call_MaterializeFromGhost, client);
		return GetEntPropEnt(client, Prop_Send, "m_customAbility");
	}
	return -1;
}

public int Native_BecomeGhost(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_Call_BecomeGhost, "BecomeGhost");

	int client = GetNativeCell(1);
	if( GetEntProp(client, Prop_Send, "m_isGhost") == 0 )
	{
		if( g_bLeft4Dead2 )
			return !!SDKCall(g_hSDK_Call_BecomeGhost, client, true);
		else
			return !!SDKCall(g_hSDK_Call_BecomeGhost, client, 0, 0);
	}
	return 0;
}

public int Native_State_Transition(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_Call_State_Transition, "State_Transition");

	int client = GetNativeCell(1);
	int state = GetNativeCell(2);
	SDKCall(g_hSDK_Call_State_Transition, client, state);
}

public int Native_SwapTeams(Handle plugin, int numParams)
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_Call_SwapTeams, "SwapTeams");

	SDKCall(g_hSDK_Call_SwapTeams, g_pDirector);
}

public int Native_AreTeamsFlipped(Handle plugin, int numParams)
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_Call_AreTeamsFlipped, "AreTeamsFlipped");

	return SDKCall(g_hSDK_Call_AreTeamsFlipped, g_pDirector);
}

public int Native_StartRematchVote(Handle plugin, int numParams)
{
	ValidateNatives(g_hSDK_Call_StartRematchVote, "StartRematchVote");
	SDKCall(g_hSDK_Call_StartRematchVote, g_pDirector);
}


public int Native_FullRestart(Handle plugin, int numParams)
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_Call_FullRestart, "FullRestart");

	SDKCall(g_hSDK_Call_FullRestart, g_pDirector);
}

public int Native_HideVersusScoreboard(Handle plugin, int numParams)
{
	ValidateAddress(VersusModePtr, "VersusModePtr");
	ValidateNatives(g_hSDK_Call_HideVersusScoreboard, "VersusScoreboard");

	SDKCall(g_hSDK_Call_HideVersusScoreboard, VersusModePtr);
}

public int Native_HideScavengeScoreboard(Handle plugin, int numParams)
{
	ValidateAddress(ScavengeModePtr, "ScavengeModePtr");
	ValidateNatives(g_hSDK_Call_HideScavengeScoreboard, "HideScavengeScoreboard");

	SDKCall(g_hSDK_Call_HideScavengeScoreboard, ScavengeModePtr);
}

public int Native_HideScoreboard(Handle plugin, int numParams)
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_Call_HideScoreboard, "HideScoreboard");

	SDKCall(g_hSDK_Call_HideScoreboard, g_pDirector);
}

public int Native_RegisterForbiddenTarget(Handle plugin, int numParams)
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_Call_RegisterForbiddenTarget, "RegisterForbiddenTarget");

	int entity = GetNativeCell(1);
	return SDKCall(g_hSDK_Call_RegisterForbiddenTarget, g_pDirector, entity);
}

public int Native_UnRegisterForbiddenTarget(Handle plugin, int numParams)
{
	ValidateAddress(g_pDirector, "g_pDirector");
	ValidateNatives(g_hSDK_Call_UnRegisterForbiddenTarget, "UnRegisterForbiddenTarget");

	int entity = GetNativeCell(1);
	SDKCall(g_hSDK_Call_UnRegisterForbiddenTarget, g_pDirector, entity);
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

public MRESReturn SpawnSpecial(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR SpawnSpecial");
	float a1[3], a2[3];
	int class = DHookGetParam(hParams, 1);
	DHookGetParamVector(hParams, 2, a1);
	DHookGetParamVector(hParams, 3, a2);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hForward_SpawnSpecial);
	Call_PushCellRef(class);
	Call_PushArray(a1, 3);
	Call_PushArray(a2, 3);
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

public MRESReturn SpawnBoomer(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR SpawnBoomer");
	int class = 2;
	return Spawn_SmokerBoomerHunter(class, hReturn, hParams);
}

public MRESReturn SpawnHunter(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR SpawnHunter");
	int class = 3;
	return Spawn_SmokerBoomerHunter(class, hReturn, hParams);
}

public MRESReturn SpawnSmoker(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR SpawnSmoker");
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
	Call_StartForward(g_hForward_SpawnSpecial);
	Call_PushCellRef(class);
	Call_PushArray(a1, 3);
	Call_PushArray(a2, 3);
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
					ValidateNatives(g_hSDK_Call_SpawnSmoker, "SpawnSmoker");
					//PrintToServer("#### CALL g_hSDK_Call_SpawnSmoker");
					SDKCall(g_hSDK_Call_SpawnSmoker, g_pZombieManager, a1, a2);
				}
				case 2:
				{
					ValidateNatives(g_hSDK_Call_SpawnBoomer, "SpawnBoomer");
					//PrintToServer("#### CALL g_hSDK_Call_SpawnBoomer");
					SDKCall(g_hSDK_Call_SpawnBoomer, g_pZombieManager, a1, a2);
				}
				case 3:
				{
					ValidateNatives(g_hSDK_Call_SpawnHunter, "SpawnHunter");
					//PrintToServer("#### CALL g_hSDK_Call_SpawnHunter");
					SDKCall(g_hSDK_Call_SpawnHunter, g_pZombieManager, a1, a2);
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

public MRESReturn SpawnTank(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR SpawnTank");
	return Spawn_TankWitch(g_hForward_SpawnTank, hReturn, hParams);
}

public MRESReturn SpawnWitch(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR SpawnWitch");
	return Spawn_TankWitch(g_hForward_SpawnWitch, hReturn, hParams);
}

public MRESReturn SpawnWitchBride(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR SpawnWitchBride");
	return Spawn_TankWitch(g_hForward_SpawnWitchBride, hReturn, hParams);
}

MRESReturn Spawn_TankWitch(Handle hForward, Handle hReturn, Handle hParams)
{
	float a1[3], a2[3];
	DHookGetParamVector(hParams, 1, a1);
	DHookGetParamVector(hParams, 2, a2);

	Action aResult = Plugin_Continue;
	Call_StartForward(hForward);
	Call_PushArray(a1, 3);
	Call_PushArray(a2, 3);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public MRESReturn ClearTeamScores(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR ClearTeamScores");
	int value = g_bLeft4Dead2 ? DHookGetParam(hParams, 1) : 0;

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hForward_ClearTeamScores);
	Call_PushCell(value);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public MRESReturn SetCampaignScores(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR SetCampaignScores");
	int a1 = DHookGetParam(hParams, 1);
	int a2 = DHookGetParam(hParams, 2);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hForward_SetCampaignScores);
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

public MRESReturn OnFirstSurvivorLeftSafeArea(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR OnFirstSurvivorLeftSafeArea");
	if( DHookIsNullParam(hParams, 1) ) return MRES_Ignored;

	int value = DHookGetParam(hParams, 1);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hForward_OnFirstSurvivorLeftSafeArea);
	Call_PushCell(value);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public MRESReturn MobRushStart(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR MobRushStart");
	Action aResult = Plugin_Continue;
	Call_StartForward(g_hForward_MobRushStart);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public MRESReturn SpawnITMob(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR SpawnITMob");
	int a1 = DHookGetParam(hParams, 1);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hForward_SpawnITMob);
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

public MRESReturn SpawnMob(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR SpawnMob");
	int a1 = DHookGetParam(hParams, 1);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hForward_SpawnMob);
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

public MRESReturn EnterGhostStatePre(int pThis, Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR EnterGhostStatePre");
	Action aResult = Plugin_Continue;
	Call_StartForward(g_hForward_EnterGhostStatePre);
	Call_PushCell(pThis);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public MRESReturn EnterGhostState(int pThis, Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR EnterGhostState");
	Call_StartForward(g_hForward_EnterGhostState);
	Call_PushCell(pThis);
	Call_Finish();

	return MRES_Ignored;
}

public MRESReturn IsTeamFullPre(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR IsTeamFullPre");
	int a1 = DHookGetParam(hParams, 1);
	bool a2 = DHookGetReturn(hReturn);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hForward_IsTeamFull);
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

public MRESReturn GetCrouchTopSpeedPre(int pThis, Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR GetCrouchTopSpeedPre");
}

public MRESReturn GetCrouchTopSpeed(int pThis, Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR GetCrouchTopSpeed");
	return GetSpeed(pThis, g_hForward_GetCrouchTopSpeed, hReturn);
}

public MRESReturn GetRunTopSpeedPre(int pThis, Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR GetRunTopSpeedPre");
}

public MRESReturn GetRunTopSpeed(int pThis, Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR GetRunTopSpeed");
	return GetSpeed(pThis, g_hForward_GetRunTopSpeed, hReturn);
}

public MRESReturn GetWalkTopSpeedPre(int pThis, Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR GetWalkTopSpeedPre");
}

public MRESReturn GetWalkTopSpeed(int pThis, Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR GetWalkTopSpeed");
	return GetSpeed(pThis, g_hForward_GetWalkTopSpeed, hReturn);
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

public MRESReturn GetScriptValueInt(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR GetScriptValueInt");
	static char key[64];
	DHookGetParamString(hParams, 1, key, sizeof(key));
	int a2 = DHookGetParam(hParams, 2);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hForward_GetScriptValueInt);
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

public MRESReturn GetScriptValueFloat(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR GetScriptValueFloat");
	static char key[64];
	DHookGetParamString(hParams, 1, key, sizeof(key));
	float a2 = DHookGetParam(hParams, 2);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hForward_GetScriptValueFloat);
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

public MRESReturn GetScriptValueString(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR GetScriptValueString");
	static char a1[128], a2[128], a3[128]; // Don't know how long they should be

	DHookGetParamString(hParams, 1, a1, sizeof(a1));

	if( !DHookIsNullParam(hParams, 2) )
		DHookGetParamString(hParams, 2, a2, sizeof(a2));

	if( !DHookIsNullParam(hParams, 3) )
		DHookGetParamString(hParams, 3, a3, sizeof(a3));

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hForward_GetScriptValueString);
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

public MRESReturn HasConfigurableDifficulty(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR HasConfigurableDifficulty");
	int a1 = DHookGetReturn(hReturn);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hForward_HasConfigurableDifficulty);
	Call_PushCellRef(a1);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		DHookSetReturn(hReturn, a1);
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public MRESReturn GetSurvivorSet(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR GetSurvivorSet");
	return SurvivorSet(g_hForward_GetSurvivorSet, hReturn);
}

public MRESReturn FastGetSurvivorSet(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR FastGetSurvivorSet");
	return SurvivorSet(g_hForward_FastGetSurvivorSet, hReturn);
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

public MRESReturn GetMissionVSBoss(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR GetMissionVSBoss");
	int plus = !g_bLeft4Dead2;

	float a1 = DHookGetParamObjectPtrVar(hParams, plus + 1, 0, ObjectValueType_Float);
	float a2 = DHookGetParamObjectPtrVar(hParams, plus + 2, 0, ObjectValueType_Float);
	float a3 = DHookGetParamObjectPtrVar(hParams, plus + 3, 0, ObjectValueType_Float);
	float a4 = DHookGetParamObjectPtrVar(hParams, plus + 4, 0, ObjectValueType_Float);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hForward_GetMissionVSBossSpawning);
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

public MRESReturn OnReplaceTank(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR OnReplaceTank");
	int a1 = DHookGetParam(hParams, 1);
	int a2 = DHookGetParam(hParams, 2);

	Call_StartForward(g_hForward_OnReplaceTank);
	Call_PushCell(a1);
	Call_PushCell(a2);
	Call_Finish();
}

public MRESReturn TryOfferingTankBot(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR TryOfferingTankBot");
	int a1 = -1;
	if( !DHookIsNullParam(hParams, 1) )
		a1 = DHookGetParam(hParams, 1);

	int a2 = DHookGetParam(hParams, 2);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hForward_TryOfferingTankBot);
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

public MRESReturn CThrowActivate(int pThis, Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR CThrowActivate");
	Action aResult = Plugin_Continue;
	Call_StartForward(g_hForward_CThrowActivate);
	Call_PushCell(pThis);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public MRESReturn SelectTankAttackPre(int pThis, Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR SelectTankAttackPre");
	if( pThis < 1 || pThis > MaxClients || !IsClientInGame(pThis) ) return MRES_Ignored; // Ignore weapons etc

	int a1 = DHookGetParam(hParams, 1);
	Action aResult = Plugin_Continue;



	// ANIMATION HOOK
	int index = g_iHookedClients.FindValue(GetClientUserId(pThis));
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

	Call_StartForward(g_hForward_SelectTankAttackPre);
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

public MRESReturn SelectTankAttack(int pThis, Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR SelectTankAttack");
	if( pThis < 1 || pThis > MaxClients || !IsClientInGame(pThis) ) return MRES_Ignored; // Ignore weapons etc

	int a1 = DHookGetReturn(hReturn);
	Action aResult = Plugin_Continue;



	// ANIMATION HOOK
	int index = g_iHookedClients.FindValue(GetClientUserId(pThis));
	if( index != -1 )
	{
		Call_StartForward(g_hAnimationCallback);
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

	Call_StartForward(g_hForward_SelectTankAttack);
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

public MRESReturn StartMeleeSwing(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR StartMeleeSwing");
	int a1 = DHookGetParam(hParams, 1);
	int a2 = DHookGetParam(hParams, 2);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hForward_StartMeleeSwing);
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

public MRESReturn SendInRescueVehicle(Handle hReturn)
// public MRESReturn SendInRescueVehicle(Handle hParams)
{
	//PrintToServer("##### DTR SendInRescueVehicle");
	Action aResult = Plugin_Continue;
	Call_StartForward(g_hForward_SendInRescueVehicle);
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

public MRESReturn ChangeFinaleStage(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR ChangeFinaleStage");
	int a1 = DHookGetParam(hParams, 1);

	static char a2[64];
	if( !DHookIsNullParam(hParams, 2) )
		DHookGetParamString(hParams, 2, a2, sizeof(a2));

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hForward_ChangeFinaleStage);
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

public MRESReturn EndVersusModeRoundPre(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR EndVersusModeRoundPre");
	if( g_bRoundEnded ) return MRES_Ignored;

	int a1 = DHookGetParam(hParams, 1);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hForward_EndVersusModeRound);
	Call_PushCell(a1);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public MRESReturn EndVersusModeRound(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR EndVersusModeRound");
	if( g_bRoundEnded ) return MRES_Ignored;
	g_bRoundEnded = true;

	Call_StartForward(g_hForward_EndVersusModeRoundPost);
	Call_Finish();

	return MRES_Ignored;
}

public MRESReturn LedgeGrabbed(int pThis, Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR LedgeGrabbed");
	Action aResult = Plugin_Continue;
	Call_StartForward(g_hForward_LedgeGrabbed);
	Call_PushCell(pThis);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled ) return MRES_Supercede;
	return MRES_Ignored;
}

public MRESReturn OnRevivedPre(int pThis, Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR OnRevivedPre");
}

public MRESReturn OnRevived(int pThis, Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR OnRevived");
	Action aResult = Plugin_Continue;
	Call_StartForward(g_hForward_OnRevived);
	Call_PushCell(pThis);
	Call_Finish(aResult);
}

public MRESReturn OnPlayerStagger(int pThis, Handle hParams)
{
	//PrintToServer("##### DTR OnPlayerStagger");
	int source = -1;

	if( !DHookIsNullParam(hParams, 1) )
		source = DHookGetParam(hParams, 1);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hForward_OnPlayerStagger);
	Call_PushCell(pThis);
	Call_PushCell(source);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled ) return MRES_Supercede;
	return MRES_Ignored;
}

public MRESReturn ShovedBySurvivor(int pThis, Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR ShovedBySurvivor");
	float a2[3];
	int a1 = DHookGetParam(hParams, 1);
	DHookGetParamVector(hParams, 2, a2);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hForward_ShovedBySurvivor);
	Call_PushCell(a1);
	Call_PushCell(pThis);
	Call_PushArray(a2, 3);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public MRESReturn CTerrorWeapon_OnHit(int weapon, Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR CTerrorWeapon_OnHit");
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
			Call_StartForward(g_hForward_CTerrorWeapon_OnHit);
			Call_PushCell(client);
			Call_PushCell(target);
			Call_PushCell(weapon);
			Call_PushArray(vec, 3);
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

public MRESReturn OnShovedByPounceLanding(int pThis, Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR OnShovedByPounceLanding");
	int a1 = DHookGetParam(hParams, 1);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hForward_OnShovedByPounceLanding);
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

public MRESReturn InfernoSpread(int pThis, Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR InfernoSpread");
	float vPos[3];
	DHookGetParamVector(hParams, 1, vPos);

	int client = GetEntPropEnt(pThis, Prop_Send, "m_hOwnerEntity");

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hForward_InfernoSpread);
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

public MRESReturn OnUseHealingItems(int pThis, Handle hReturn, Handle hParams)
// public MRESReturn OnUseHealingItems(Handle hParams)
{
	//PrintToServer("##### DTR OnUseHealingItems");
	// int pThis = DHookGetParam(hParams, 2);
	Action aResult = Plugin_Continue;
	Call_StartForward(g_hForward_OnUseHealingItems);
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

public MRESReturn OnFindScavengeItemPre(int pThis, Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR OnFindScavengeItemPre");
}

public MRESReturn OnFindScavengeItem(int pThis, Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR OnFindScavengeItem");
	int a1 = DHookGetReturn(hReturn);
	if( a1 == -1 ) a1 = 0;

	// Scan distance or something? If you find out please let me know, I'm interested. Haven't bothered testing.
	// float a2 = DHookGetParam(hParams, 1);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hForward_OnFindScavengeItem);
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

public MRESReturn OnChooseVictimPre(int client, Handle hReturn)
{
	//PrintToServer("##### DTR OnChooseVictimPre");
}

public MRESReturn OnChooseVictim(int client, Handle hReturn)
{
	//PrintToServer("##### DTR OnChooseVictim");
	int a1 = DHookGetReturn(hReturn);
	if( a1 == -1 ) a1 = 0;

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hForward_OnChooseVictim);
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

public MRESReturn OnMaterializeFromGhostPre(int client)
{
	//PrintToServer("##### DTR OnMaterializeFromGhostPre");

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hForward_OnMaterializeFromGhostPre);
	Call_PushCell(client);
	Call_Finish(aResult);

	if( aResult == Plugin_Handled )
	{
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public MRESReturn OnMaterialize(int client)
{
	//PrintToServer("##### DTR OnMaterializeFromGhost");

	Call_StartForward(g_hForward_OnMaterializeFromGhost);
	Call_PushCell(client);
	Call_Finish();

	return MRES_Ignored;
}

public MRESReturn OnVomitedUpon(int client, Handle hReturn, Handle hParams)
{
	// PrintToServer("##### DTR OnVomitedUpon");

	int a1 = DHookGetParam(hParams, 1);
	int a2 = DHookGetParam(hParams, 2);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hForward_OnVomitedUpon);
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

public MRESReturn OnHitByVomitJar(int client, Handle hReturn, Handle hParams)
{
	// PrintToServer("##### DTR OnHitByVomitJar");

	int a1 = DHookGetParam(hParams, 1);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hForward_OnHitByVomitJar);
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
public MRESReturn GetRandomPZSpawnPos(Handle hReturn, Handle hParams)
{
	//PrintToServer("##### DTR GetRandomPZSpawnPos");
	int zombieClass = DHookGetParam(hParams, 1);
	int attempts = DHookGetParam(hParams, 2);

	int client;
	if( !DHookIsNullParam(hParams, 3) )
		client = DHookGetParam(hParams, 3);

	float vecPos[3];
	DHookGetParamVector(hParams, 4, vecPos);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hForward_GetRandomPZSpawnPos);
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
			DHookSetParamVector(hParams, 4, view_as<float>({ 0.0, 0.0, 0.0}));
		} else {
			DHookSetParamVector(hParams, 4, view_as<float>({ 0.0, 0.0, 0.0}));
		}

		return MRES_ChangedHandled;
	}

	return MRES_Ignored;
}
// */

/*
public MRESReturn InfectedShoved(Handle hReturn, Handle hParams)
{
	int a1 = DHookGetParam(hParams, 1);
	int a2 = DHookGetParam(hParams, 2);

	Action aResult = Plugin_Continue;
	Call_StartForward(g_hForward_InfectedShoved);
	Call_PushCell(a1);
	Call_PushCell(a2);
	Call_Finish(aResult);
	if( aResult == Plugin_Handled ) return MRES_Supercede;

	return MRES_Ignored;
}
// */

/*
public MRESReturn OnWaterMovePre(int pThis, Handle hReturn, Handle hParams)
{
}

public MRESReturn OnWaterMove(int pThis, Handle hReturn, Handle hParams)
{
	int a1 = DHookGetReturn(hReturn);
	if( a1 )
	{
		Action aResult = Plugin_Continue;
		Call_StartForward(g_hForward_OnWaterMove);
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
	// Vars
	char code[256];
	char buffer[8];

	// Code
	FormatEx(code, sizeof(code), "ret <- Director.GetMapNumber(); <RETURN>ret</RETURN>");

	// Exec
	if( GetVScriptOutput(code, buffer, sizeof(buffer)) )
		return StringToInt(buffer);
	else
		return false;
}

public int Native_VS_HasEverBeenInjured(Handle plugin, int numParams)
{
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
		return false;
}

public int Native_VS_IsDead(Handle plugin, int numParams)
{
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
	// Vars
	char code[256];
	char buffer[8];

	int client = GetNativeCell(1);
	client = GetClientUserId(client);
	float fTime = GetNativeCell(2);

	// Code
	FormatEx(code, sizeof(code), "GetPlayerFromUserID(%d).UseAdrenaline(%f); <RETURN>1</RETURN>", client, fTime);

	// Exec
	if( GetVScriptOutput(code, buffer, sizeof(buffer)) )
		return true;
	else
		return false;
}

public int Native_VS_ReviveByDefib(Handle plugin, int numParams)
{
	// Vars
	char code[256];
	char buffer[8];

	int client = GetNativeCell(1);
	client = GetClientUserId(client);

	// Code
	FormatEx(code, sizeof(code), "GetPlayerFromUserID(%d).ReviveByDefib(); <RETURN>1</RETURN>", client);

	// Exec
	if( GetVScriptOutput(code, buffer, sizeof(buffer)) )
		return true;
	else
		return false;
}

public int Native_VS_ReviveFromIncap(Handle plugin, int numParams)
{
	// Vars
	char code[256];
	char buffer[8];

	int client = GetNativeCell(1);
	client = GetClientUserId(client);

	// Code
	FormatEx(code, sizeof(code), "GetPlayerFromUserID(%d).ReviveFromIncap(); <RETURN>1</RETURN>", client);

	// Exec
	if( GetVScriptOutput(code, buffer, sizeof(buffer)) )
		return true;
	else
		return false;
}

public int Native_VS_GetSenseFlags(Handle plugin, int numParams)
{
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
		return false;
}

public int Native_VS_NavAreaBuildPath(Handle plugin, int numParams)
{
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
//										HELPERS
// ====================================================================================================
bool GetVScriptOutput(char[] code, char[] ret, int maxlength)
{
	static int logic;

	if( !logic || EntRefToEntIndex(logic) == INVALID_ENT_REFERENCE )
	{
		logic = CreateEntityByName("logic_script");

		if( logic == INVALID_ENT_REFERENCE || !IsValidEntity(logic) )
		{
			LogError("Could not create 'logic_script'");
			return false;
		}

		DispatchSpawn(logic);

		logic = EntIndexToEntRef(logic);
	}

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
		Format(buffer, length, "Convars.SetValue(\"l4d2_vscript_return\", \"\" + %s + \"\");", code);
	}

	// Run code
	SetVariantString(buffer);
	AcceptEntityInput(logic, "RunScriptCode");

	#if KILL_VSCRIPT
	AcceptEntityInput(logic, "Kill");
	#endif

	// Retrieve value and return to buffer
	g_hCvarVScriptBuffer.GetString(ret, maxlength);
	g_hCvarVScriptBuffer.SetString("");

	if( ret[0] == '\x0')
		return false;
	return true;
}

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



// ====================================================================================================
//                    STOCKS - HEALTH
// ====================================================================================================
float GetTempHealth(int client)
{
    float fGameTime = GetGameTime();
    float fHealthTime = GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
    float fHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
    fHealth -= (fGameTime - fHealthTime) * g_hDecayDecay.FloatValue;
    return fHealth < 0.0 ? 0.0 : fHealth;
}

void SetTempHealth(int client, float fHealth)
{
    SetEntPropFloat(client, Prop_Send, "m_healthBuffer", fHealth < 0.0 ? 0.0 : fHealth );
    SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
}