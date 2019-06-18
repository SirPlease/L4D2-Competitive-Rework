/**
 * vim: set ts=4 :
 * =============================================================================
 * L4D2_Direct Timer functions
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
#if defined _l4d2_direct_timers_included
 #endinput
#endif
#define _l4d2_direct_timers_included

#include <sourcemod>
#include <l4d2d_internals>

#define CTIMER_DURATION_OFFSET (Address:4)
#define CTIMER_TIMESTAMP_OFFSET (Address:8)
#define ITIMER_TIMESTAMP_OFFSET (Address:4)
#define SIZEOF_ITIMER 8
#define SIZEOF_CTIMER 12

enum CountdownTimer
{
	CTimer_Null = 0 /**< Invalid Timer when lookup fails */
};

enum IntervalTimer
{
	ITimer_Null = 0 /**< Invalid Timer when lookup fails */
};

/* CountdownTimer funcs */

/**
 * Reset a CountdownTimer to begin counting down again from now to its original duration
 *
 * @param timer		CountdownTimer to reset
 * @noreturn
 * @error 			Invalid timer address
 */
stock CTimer_Reset( CountdownTimer:timer )
{
	CTimer_SetTimestamp( timer , GetGameTime() + CTimer_GetDuration( timer ) );
}

/**
 * Start a CountdownTimer from now for a given duration
 *
 * @param timer		CountdownTimer to reset
 * @param duration	Duration for this CountdownTimer to use, in seconds
 * @noreturn
 * @error 			Invalid timer address
 */
stock CTimer_Start( CountdownTimer:timer , Float:duration )
{
	CTimer_SetTimestamp( timer , GetGameTime() + duration );
	CTimer_SetDuration( timer , duration );
}

/**
 * Invalidate a CountdownTimer, so it is considered not running
 *
 * @param timer		CountdownTimer to Invalidate
 * @noreturn
 * @error 			Invalid timer address
 */
stock CTimer_Invalidate( CountdownTimer:timer )
{
	CTimer_SetTimestamp( timer , -1.0 );
}

/**
 * Determine if a CountdownTimer has started counting down.
 *
 * @param timer		CountdownTimer to check
 * @return			True if it has started running, False if it is not (Invalidated)
 * @error 			Invalid timer address
 */
stock bool:CTimer_HasStarted( CountdownTimer:timer )
{
	return CTimer_GetTimestamp( timer ) >= 0.0;
}

/**
 * Determine if a CountdownTimer is elapsed.
 *
 * @param timer		CountdownTimer to check
 * @return			True if the timer's duration has passed since it started, false otherwise.
 * @error 			Invalid timer address
 */
stock bool:CTimer_IsElapsed( CountdownTimer:timer )
{
	return GetGameTime() >= CTimer_GetTimestamp( timer );
}

/**
 * Check how long a CountdownTimer has been running
 *
 * @param timer		CountdownTimer to check
 * @return			Time since the CountdownTimer was last Started or Reset, in seconds.
 * @error 			Invalid timer address
 */
stock Float:CTimer_GetElapsedTime( CountdownTimer:timer )
{
	return ( GetGameTime() - CTimer_GetTimestamp( timer ) ) + CTimer_GetDuration( timer );
}

/**
 * Check how much time remains before a CountdownTimer is elapsed.
 *
 * @param timer		CountdownTimer to check
 * @return			Time until the CountdownTimer is elapsed, in seconds.
 * @error 			Invalid timer address
 */
stock Float:CTimer_GetRemainingTime( CountdownTimer:timer )
{
	return CTimer_GetTimestamp( timer ) - GetGameTime();
}

/**
 * Get the countdown duration used for a CountdownTimer
 *
 * @param timer		CountdownTimer to check
 * @return			Countdown duration in seconds if timer is running, or 0.0 if timer is invalidated (not running)
 * @error 			Invalid timer address
 */
stock Float:CTimer_GetCountdownDuration( CountdownTimer:timer )
{
	return ( CTimer_GetTimestamp( timer ) > 0.0 ) ? CTimer_GetDuration( timer ) : 0.0;
}

/* IntervalTimer funcs */

/**
 * Reset an IntervalTimer to begin counting up again from now
 *
 * @param timer		IntervalTimer to reset
 * @noreturn
 * @error 			Invalid timer address
 */
stock ITimer_Reset( IntervalTimer:timer )
{
	ITimer_SetTimestamp( timer , GetGameTime() );
}

/**
 * Start an IntervalTimer to begin counting up from now
 *
 * @note This is the same as reset for IntervalTimers...
 *
 * @param timer		IntervalTimer to start
 * @noreturn
 * @error 			Invalid timer address
 */
stock ITimer_Start( IntervalTimer:timer )
{
	ITimer_SetTimestamp( timer , GetGameTime() );
}

/**
 * Invalidate an IntervalTimer, so it is considered not running
 *
 * @param timer		IntervalTimer to Invalidate
 * @noreturn
 * @error 			Invalid timer address
 */
stock ITimer_Invalidate( IntervalTimer:timer )
{
	ITimer_SetTimestamp( timer , -1.0 );
}

/**
 * Check if an IntervalTimer has started
 *
 * @param timer		IntervalTimer to check
 * @return			True if the IntervalTimer is running, false if it is Invalidated
 * @error 			Invalid timer address
 */
stock bool:ITimer_HasStarted( IntervalTimer:timer )
{
	return ( ITimer_GetTimestamp( timer ) > 0.0 );
}

/**
 * Get the elapsed time of an IntervalTimer
 *
 * @param timer		IntervalTimer to check
 * @return			Elapsed time of the IntervalTimer in seconds if it has started, or 99999.9 ("infinite") if it is Invalidated
 * @error 			Invalid timer address
 */
stock Float:ITimer_GetElapsedTime( IntervalTimer:timer )
{
	return ITimer_HasStarted( timer ) ? GetGameTime() - ITimer_GetTimestamp(timer) : 99999.9;
}

/* Timer Internals */

// Read duration variable in CTimer
static stock Float:CTimer_GetDuration( CountdownTimer:timer )
{
	return Float:LoadFromAddress( Address:timer + CTIMER_DURATION_OFFSET , NumberType_Int32 );
}

// Set duration variable in CTimer
static stock CTimer_SetDuration( CountdownTimer:timer , Float:duration )
{
	StoreToAddress( Address:timer + CTIMER_DURATION_OFFSET , _:duration , NumberType_Int32 );
}

// Read timestamp variable in CTimer
static stock Float:CTimer_GetTimestamp( CountdownTimer:timer )
{
	return Float:LoadFromAddress( Address:timer + CTIMER_TIMESTAMP_OFFSET , NumberType_Int32 );
}

// Set timestamp variable in CTimer
static stock CTimer_SetTimestamp( CountdownTimer:timer , Float:timestamp )
{
	StoreToAddress( Address:timer + CTIMER_TIMESTAMP_OFFSET , _:timestamp , NumberType_Int32 );
}

// Read timestamp variable in ITimer
static stock Float:ITimer_GetTimestamp( IntervalTimer:timer )
{
	return Float:LoadFromAddress( Address:timer + ITIMER_TIMESTAMP_OFFSET , NumberType_Int32 );
}

// Set timestamp variable in ITimer
static stock ITimer_SetTimestamp( IntervalTimer:timer , Float:timestamp )
{
	StoreToAddress( Address:timer + ITIMER_TIMESTAMP_OFFSET , _:timestamp , NumberType_Int32 );
}