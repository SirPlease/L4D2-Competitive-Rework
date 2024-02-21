/**
 * vim: set ts=4 :
 * =============================================================================
 * L4D2_Direct
 * Copyright (C) 2012 Michael "ProdigySim" Busby
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
#if defined _l4d2_direct_included
 #endinput
#endif
#define _l4d2_direct_included

#include <sourcemod>
#include <l4d2d_internals>
#include <l4d2d_timers>


/* CDirector Variable access */

/**
 * Get the current Tank count stored by the director.
 * 
 * @note This should work on any gamemode, and is a good check to see if there is a tank in play
 *
 *
 * @return			The current number of tanks in play.
 * @error			Director address not found.
 */
stock L4D2Direct_GetTankCount()
{
	return LoadFromAddress( L4D2Direct_GetTankCountAddr() , NumberType_Int32 );
}

/**
 * Get a reference to the CDirector natural mob spawn CountdownTimer
 *
 * @note This timer is used to control the spawning of natural hordes.
 * @note This timer gets reset during unnatural hordes as well (boomer/car alarm hordes)
 * @note Some scripted events will effectively "take over", by reducing the mob spawn time.
 *
 * @return				CountdownTimer reference to the timer, or CTimer_Null on lookup failure.
 */
stock CountdownTimer:L4D2Direct_GetMobSpawnTimer()
{
	static Address:pMobSpawnTimer = Address_Null;
	if(pMobSpawnTimer == Address_Null)
	{
		new offs = GameConfGetOffset(L4D2Direct_GetGameConf(), "CDirector::MobSpawnTimer");
		if(offs == -1) return CTimer_Null;
		pMobSpawnTimer = L4D2Direct_GetCDirector() + Address:offs;
	}
	return CountdownTimer:pMobSpawnTimer;
}

/**
 * Get a reference to a IntervalTimer that counts up from the last death of a given SI class
 *
 * @note The main place I've seen these timers used is in the SI spawning algorithms (CDirector::UpdateSpecialSpawns)
 * @note This timer gets checked against SI respawn interval for different gamemodes, some of which are cvar controlled (e.g. versus_special_respawn_interval)
 *
 * @param class		SI Class to retrieve timer for
 * @return			IntervalTimer reference to the timer, or ITimer_Null on lookup failure or bad class.
 */
stock IntervalTimer:L4D2Direct_GetSIClassDeathTimer(class)
{
	// Should be between smoker and charger
	if(class < 1 || class > 6) return ITimer_Null;
	
	static Address:pSIDeathTimers = Address_Null;
	if(pSIDeathTimers == Address_Null)
	{
		new offs = GameConfGetOffset(L4D2Direct_GetGameConf(), "CDirector::ClassDeathTimers");
		if(offs == -1) return ITimer_Null;
		pSIDeathTimers = L4D2Direct_GetCDirector() + Address:offs;
	}
	return IntervalTimer:(_:pSIDeathTimers + ((class - 1) * SIZEOF_ITIMER));
}

/**
 * Get a reference to a CountdownTimer that counts down from the last attempted director-controlled spawn of an SI
 *
 * @note The main place I've seen these timers used is in the SI spawning algorithms (CDirector::UpdateSpecialSpawns)
 * @note This timer is hard-coded to use a duration of 20.0s.
 *
 * @param class		SI Class to retrieve timer for
 * @return			CountdownTimer reference to the timer, or CTimer_Null on lookup failure or bad class.
 */
stock CountdownTimer:L4D2Direct_GetSIClassSpawnTimer(class)
{
	// Should be between smoker and charger
	if(class < 1 || class > 6) return CTimer_Null;
	
	static Address:pSISpawnTimers = Address_Null;
	if(pSISpawnTimers == Address_Null)
	{
		new offs = GameConfGetOffset(L4D2Direct_GetGameConf(), "CDirector::ClassSpawnTimers");
		if(offs == -1) return CTimer_Null;
		pSISpawnTimers = L4D2Direct_GetCDirector() + Address:offs;
	}
	return CountdownTimer:(_:pSISpawnTimers + ((class - 1) * SIZEOF_CTIMER));
}

/* CDirectorVersusMode Variable access */

/**
 * Reads the director's stored campaign score for a given team.
 * 
 * @note You can use the gamerules m_bAreTeamsFlipped property to figure out team numbers
 * @note The campaign scores value is also stored in gamerules, however this is the "master" version.
 * @note Campaign scores are only updated on round end, so this will not reflect current survivor distance score
 *
 *
 * @param teamNumber	Team number to read campaign score of, 0 or 1.
 * @return				Campaign score for the given team.
 * @error				Director or Versus Director address not found.
 */
stock L4D2Direct_GetVSCampaignScore( teamNumber )
{
	if(teamNumber < 0 || teamNumber > 1) return -1;

	return LoadFromAddress( L4D2Direct_GetVSCampaignScoresAddr() + Address:(teamNumber * 4), NumberType_Int32 );
}

/**
 * Set the director's stored campaign score for a given team.
 * 
 * @note You can use the gamerules m_bAreTeamsFlipped property to figure out team numbers
 * @note The campaign scores value is also stored in gamerules, however this is the "master" version.
 * @note Keep in mind the current survivor team's distance/bonus score will be added at the end of a round
 *
 *
 * @param teamNumber	Team number to set campaign score of, 0 or 1.
 * @param score			Score to set for the team
 * @error				Director or Versus Director address not found.
 * @noreturn
 */
stock L4D2Direct_SetVSCampaignScore( teamNumber , score )
{
	if(teamNumber < 0 || teamNumber > 1) return;

	StoreToAddress( L4D2Direct_GetVSCampaignScoresAddr() + Address:(teamNumber * 4), score, NumberType_Int32 );
}

/**
 * Reads the tank flow percent for a given round for versus mode
 * 
 * @note You should check GetVSTankToSpawnThisRound to find out if a tank is going to be spawned for this round.
 * @note When the survivors reach this flow percent minus versus_boss_buffer converted to flow percent, a tank will spawn.
 *
 *
 * @param roundNumber	Round number to read tank spawn flow percent of
 * @return				Tank spawn flow percent for the given round
 * @error				Director or Versus Director address not found.
 */
stock Float:L4D2Direct_GetVSTankFlowPercent( roundNumber )
{
	if(roundNumber < 0 || roundNumber > 1) return -1.0;
	
	return Float:LoadFromAddress( L4D2Direct_GetVSTankFlowAddr() + Address:(roundNumber * 4) , NumberType_Int32 );
}

/**
 * Sets the tank flow percent for a given round for versus mode
 * 
 * @note You should check GetVSTankToSpawnThisRound to find out if there is still a tank to spawn this round.
 * @note When the survivors reach this flow percent minus versus_boss_buffer converted to flow percent, a tank will spawn.
 *
 *
 * @param roundNumber	Round number to set tank spawn flow percent of
 * @param flow			Floating point percent of flow distance.
 * @noreturn
 * @error				Director or Versus Director address not found.
 */
stock L4D2Direct_SetVSTankFlowPercent( roundNumber , Float:flow )
{
	if(roundNumber < 0 || roundNumber > 1) return;
	
	StoreToAddress( L4D2Direct_GetVSTankFlowAddr() + Address:(roundNumber * 4) , _:flow , NumberType_Int32 );
}

/**
 * Is there going to be a tank spawned during the given round
 *
 * @param roundNumber	Round number to check for tank spawn on
 * @return				True if there is still a tank to spawn for the given round, false if it has already been spawned or will not spawn.
 * @error				Director or Versus Director address not found.
 */
stock bool:L4D2Direct_GetVSTankToSpawnThisRound( roundNumber )
{
	if(roundNumber < 0 || roundNumber > 1) return false;
	
	return bool:LoadFromAddress( L4D2Direct_GeVSTankToSpawnAddr() + Address:roundNumber , NumberType_Int8 );
}

/**
 * Tell the director whether or not to spawn a(nother) flow distance-based tank for this round.
 *
 * @note If you set this to true after a flow-distance-based tank has been spawned, this can trigger another tank to be spawned based on flow distance
 *
 * @param roundNumber	Round number to set a tank spawn on
 * @param spawn			Whether or not to spawn a flow-distance-based tank for this round.
 * @noreturn
 * @error				Director or Versus Director address not found.
 */
stock L4D2Direct_SetVSTankToSpawnThisRound( roundNumber , bool:spawn )
{
	if(roundNumber < 0 || roundNumber > 1) return;
	
	StoreToAddress( L4D2Direct_GeVSTankToSpawnAddr() + Address:roundNumber , _:spawn, NumberType_Int8 );
}

/**
 * Reads the witch flow percent for a given round for versus mode
 * 
 * @note You should check GetVSWitchToSpawnThisRound to find out if a witch is going to be spawned for this round.
 * @note When the survivors reach this flow percent minus versus_boss_buffer converted to flow percent, a witch will spawn.
 *
 *
 * @param roundNumber	Round number to read witch spawn flow percent of
 * @return				Witch spawn flow percent for the given round
 * @error				Director or Versus Director address not found.
 */
stock Float:L4D2Direct_GetVSWitchFlowPercent( roundNumber )
{
	if(roundNumber < 0 || roundNumber > 1) return -1.0;

	return Float:LoadFromAddress( L4D2Direct_GetVSWitchFlowAddr() + Address:(roundNumber * 4) , NumberType_Int32 );
}

/**
 * Sets the witch flow percent for a given round for versus mode
 * 
 * @note You should check GetVSWitchToSpawnThisRound to find out if there is still a witch to spawn this round.
 * @note When the survivors reach this flow percent minus versus_boss_buffer converted to flow percent, a witch will spawn.
 *
 *
 * @param roundNumber	Round number to set witch spawn flow percent of
 * @param flow			Floating point percent of flow distance.
 * @noreturn
 * @error				Director or Versus Director address not found.
 */
stock L4D2Direct_SetVSWitchFlowPercent( roundNumber , Float:flow )
{
	if(roundNumber < 0 || roundNumber > 1) return;
	
	StoreToAddress( L4D2Direct_GetVSWitchFlowAddr() + Address:(roundNumber * 4) , _:flow , NumberType_Int32 );
}

/**
 * Is there going to be a witch spawned during the given round
 *
 * @param roundNumber	Round number to check for witch spawn on
 * @return				True if there is still a witch to spawn for the given round, false if it has already been spawned or will not spawn.
 * @error				Director or Versus Director address not found.
 */
stock bool:L4D2Direct_GetVSWitchToSpawnThisRound( roundNumber )
{
	if(roundNumber < 0 || roundNumber > 1) return false;
	
	return bool:LoadFromAddress( L4D2Direct_GetVSWitchToSpawnAddr() + Address:roundNumber , NumberType_Int8 );
}

/**
 * Tell the director whether or not to spawn a(nother) flow distance-based witch for this round.
 *
 * @note If you set this to true after a flow-distance-based witch has been spawned, this can trigger another witch to be spawned based on flow distance
 *
 * @param roundNumber	Round number to set a witch spawn on
 * @param spawn			Whether or not to spawn a flow-distance-based witch for this round.
 * @noreturn
 * @error				Director or Versus Director address not found.
 */
stock L4D2Direct_SetVSWitchToSpawnThisRound( roundNumber , bool:spawn )
{
	if(roundNumber < 0 || roundNumber > 1) return;
	
	StoreToAddress( L4D2Direct_GetVSWitchToSpawnAddr() + Address:roundNumber , _:spawn , NumberType_Int8 );
}

/**
 * Get a reference to the VersusStart CountdownTimer
 *
 * @note This timer controls when the saferoom door will open and PZ spawning is enabled
 * @note The default duration for this timer is controlled by cvar: versus_force_start_time
 *
 * @return				CountdownTimer reference to the timer, or CTimer_Null on lookup failure.
 * @error				Director address not found.
 */
stock CountdownTimer:L4D2Direct_GetVSStartTimer()
{
	static Address:pVSStartTimer = Address_Null;
	if(pVSStartTimer == Address_Null)
	{
		new offs = GameConfGetOffset(L4D2Direct_GetGameConf(), "CDirectorVersusMode::VersusStartTimer");
		if(offs == -1) return CTimer_Null;
		pVSStartTimer = L4D2Direct_GetCDirectorVersusMode() + Address:offs;
	}
	return CountdownTimer:pVSStartTimer;
}

/* CDirectorScavengeMode Variable access */

/**
 * Get a reference to the Scavenge Round Setup CountdownTimer
 *
 * @note This timer controls when the scavenge "warmup" time ends and PZ/game timers start.
 * @note The default duration for this timer is controlled by cvar: scavenge_round_setup_time
 *
 * @return				CountdownTimer reference to the timer, or CTimer_Null on lookup failure.
 * @error				Director address not found.
 */
stock CountdownTimer:L4D2Direct_GetScavengeRoundSetupTimer()
{
	static Address:pRoundSetupTimer = Address_Null;
	if(pRoundSetupTimer == Address_Null)
	{
		new offs = GameConfGetOffset(L4D2Direct_GetGameConf(), "CDirectorScavengeMode::RoundSetupTimer");
		if(offs == -1) return CTimer_Null;
		pRoundSetupTimer = L4D2Direct_GetCDirectorScavengeMode() + Address:offs;
	}
	return CountdownTimer:pRoundSetupTimer;
}

/**
 * Get a reference to the Scavenge Overtime Grace CountdownTimer
 *
 * @note This timer keeps track of how long survivors have gone without holding a can during overtime.
 * @note The default duration for this timer is controlled by cvar: scavenge_overtime_grace_time
 *
 * @return				CountdownTimer reference to the timer, or CTimer_Null on lookup failure.
 * @error				Director address not found.
 */
stock CountdownTimer:L4D2Direct_GetScavengeOvertimeGraceTimer()
{
	static Address:pOvertimeGraceTimer = Address_Null;
	if(pOvertimeGraceTimer == Address_Null)
	{
		new offs = GameConfGetOffset(L4D2Direct_GetGameConf(), "CDirectorScavengeMode::OvertimeGraceTimer");
		if(offs == -1) return CTimer_Null;
		pOvertimeGraceTimer = L4D2Direct_GetCDirectorScavengeMode() + Address:offs;
	}
	return CountdownTimer:pOvertimeGraceTimer;
}

/* TerrorNavMesh Variable access */

/**
 * Get the max flow distance (in flow units) for the current map.
 *
 * @note The flow distance for each map is generated as it is loaded, and it can change slightly (a few hundred units) with each load.
 * @note You can use this value to convert a flow distance to a flow percent, and vice versa.
 *
 * @return				Max flow distance for the current loaded map.
 * @error				TerrorNavMesh address not found.
 */
stock Float:L4D2Direct_GetMapMaxFlowDistance()
{
	return Float:LoadFromAddress( L4D2Direct_GetMapMaxFlowDistanceAddr() , NumberType_Int32 );
}
