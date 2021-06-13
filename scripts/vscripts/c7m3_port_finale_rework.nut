//-----------------------------------------------------
// This script handles the logic for the Port / Bridge
// finale in the River Campaign. 
//
//-----------------------------------------------------
Msg("Initiating c7m3_port_finale rework script\n");

//-----------------------------------------------------
ERROR		<- -1
PANIC 		<- 0
TANK 		<- 1
DELAY 		<- 2

//-----------------------------------------------------

// This keeps track of the number of times the generator button has been pressed. 
// Init to 1, since one button press has been used to start the finale and run 
// this script. 
ButtonPressCount <- 1

// This stores the stage number that we last
// played the "Press the Button!" VO
LastVOButtonStageNumber <- 0

// We use this to keep from running a bunch of queued advances really quickly. 
// Init to true because we are starting a finale from a button press in the pre-finale script 
// see GeneratorButtonPressed in c7m3_port.nut
PendingWaitAdvance <- true	

// We use three generator button presses to push through
// 8 stages. We have to queue up state advances
// depending on the state of the finale when buttons are pressed
QueuedDelayAdvances <- 0


// Tracking current finale states
CurrentFinaleStageNumber <- ERROR
CurrentFinaleStageType <- ERROR

// The finale is 3 phases. 
// We randomize the event types in the first two
local RandomFinaleStage1 = 0
local RandomFinaleStage2 = 0
local RandomFinaleStage4 = 0
local RandomFinaleStage5 = 0

// PHASE 1 EVENTS
// Rework - remove the RNG from the event, make horde always spawn before a tank
RandomFinaleStage1 = PANIC
RandomFinaleStage2 = TANK
RandomFinaleStage4 = PANIC
RandomFinaleStage5 = TANK


// We want to give the survivors a little of extra time to 
// get on their feet before the escape, since you have to fight through 
// the sacrifice.

PreEscapeDelay <- 0
if ( Director.GetGameModeBase() == "coop" || Director.GetGameModeBase() == "realism" )
{
	PreEscapeDelay <- 5
}
else if ( Director.GetGameModeBase() == "versus" )
{
	PreEscapeDelay <- 15
}

DirectorOptions <-
{	
	 
	A_CustomFinale_StageCount = 8
	 
	// PHASE 1
	A_CustomFinale1 = RandomFinaleStage1
	A_CustomFinaleValue1 = 1
	A_CustomFinale2 = RandomFinaleStage2
	A_CustomFinaleValue2 = 1
	A_CustomFinale3 = DELAY
	A_CustomFinaleValue3 = 9999
	
	
	// PHASE 2
	A_CustomFinale4 = RandomFinaleStage4
	A_CustomFinaleValue4 = 1
	A_CustomFinale5 = RandomFinaleStage5
	A_CustomFinaleValue5 = 1	
	A_CustomFinale6 = DELAY
	A_CustomFinaleValue6 = 9999 	 
	
	
	// PHASE 3
	A_CustomFinale7 = TANK
	A_CustomFinaleValue7 = 1	 	 		 
	A_CustomFinale8 = DELAY
	A_CustomFinaleValue8 = PreEscapeDelay
	 
	 
	 
	TankLimit = 4
	WitchLimit = 0
	CommonLimit = 20	
	HordeEscapeCommonLimit = 15	
	EscapeSpawnTanks = false
	//SpecialRespawnInterval = 80

}


function OnBeginCustomFinaleStage( num, type )
{
	printl( "*!* Beginning custom finale stage " + num + " of type " + type );
	printl( "*!* PendingWaitAdvance " + PendingWaitAdvance + ", QueuedDelayAdvances " + QueuedDelayAdvances );
	
	// Store off the state... 
	CurrentFinaleStageNumber = num
	CurrentFinaleStageType = type
	
	// Acknowledge the state advance
	PendingWaitAdvance = false
}


function GeneratorButtonPressed()
{
    printl( "*!* GeneratorButtonPressed finale stage " + CurrentFinaleStageNumber + " of type " +CurrentFinaleStageType );
	printl( "*!* PendingWaitAdvance " + PendingWaitAdvance + ", QueuedDelayAdvances " + QueuedDelayAdvances );
	
	
	ButtonPressCount++
	
	
	local ImmediateAdvances = 0
	
	
	if ( CurrentFinaleStageNumber == 1 || CurrentFinaleStageNumber == 4 )
	{		
		// First stage of a phase, so next stage is an "action" stage too.
		// Advance to next action stage, and then queue an advance to the 
		// next delay.
		QueuedDelayAdvances++
		ImmediateAdvances = 1
	}
	else if ( CurrentFinaleStageNumber == 2 || CurrentFinaleStageNumber == 5 )
	{
		// Second stage of a phase, so next stage is a "delay" stage.
		// We need to immediately advance past the delay and into an action state. 
		
		//QueuedDelayAdvances++	// NOPE!
		ImmediateAdvances = 2
	}
	else if ( CurrentFinaleStageNumber == 3 || CurrentFinaleStageNumber == 6 )
	{
		// Wait states... (very long delay)
		// Advance immediately into an action state
		
		//QueuedDelayAdvances++
		ImmediateAdvances = 1
	}
	else if ( CurrentFinaleStageNumber == -1 || 
              CurrentFinaleStageNumber == 0 )
	{
		// the finale is *just* about to start... 
		// we can get this if all the buttons are hit at once at the beginning
		// Just queue a wait advance
		QueuedDelayAdvances++
		ImmediateAdvances = 0
	}
	else
	{
		printl( "*!* Unhandled generator button press! " );
	}

	if ( ImmediateAdvances > 0 )
	{	
		EntFire( "generator_start_model", "Enable" )
		
		
		if ( ImmediateAdvances == 1 )
		{
			printl( "*!* GeneratorButtonPressed Advancing State ONCE");
			EntFire( "generator_start_model", "AdvanceFinaleState" )
		}
		else if ( ImmediateAdvances == 2 )
		{
			printl( "*!* GeneratorButtonPressed Advancing State TWICE");
			EntFire( "generator_start_model", "AdvanceFinaleState" )
			EntFire( "generator_start_model", "AdvanceFinaleState" )
		}
		
		EntFire( "generator_start_model", "Disable" )
		
		PendingWaitAdvance = true
	}
	
}

function Update()
{
	// Should we advance the finale state?
	// 1. If we're in a DELAY state
	// 2. And we have queued advances.... 
	// 3. And we haven't just tried to advance the advance the state.... 
	if ( CurrentFinaleStageType == DELAY && QueuedDelayAdvances > 0 && !PendingWaitAdvance )
	{
		// If things are calm (relatively), jump to the next state
		if ( !Director.IsTankInPlay() && !Director.IsAnySurvivorInCombat() )
		{
			if ( Director.GetPendingMobCount() < 1 && Director.GetCommonInfectedCount() < 5 )
			{
				printl( "*!* Update Advancing State finale stage " + CurrentFinaleStageNumber + " of type " +CurrentFinaleStageType );
				printl( "*!* PendingWaitAdvance " + PendingWaitAdvance + ", QueuedDelayAdvances " + QueuedDelayAdvances );
		
				QueuedDelayAdvances--
				EntFire( "generator_start_model", "Enable" )
				EntFire( "generator_start_model", "AdvanceFinaleState" )
				EntFire( "generator_start_model", "Disable" )
				PendingWaitAdvance = true
			}
		}
	}
	
	// Should we fire the director event to play the "Press the button!" Nag VO?	
	// If we're on an infinite delay stage...
	if ( CurrentFinaleStageType == DELAY && CurrentFinaleStageNumber > 1 && CurrentFinaleStageNumber < 7 )	
	{		
		// 1. We haven't nagged for this stage yet
		// 2. There are button presses remaining
		if ( CurrentFinaleStageNumber != LastVOButtonStageNumber && ButtonPressCount < 3 )
		{
			// We're not about to process a wait advance..
			if ( QueuedDelayAdvances == 0 && !PendingWaitAdvance )
			{
				// If things are pretty calm, run the event
				if ( Director.GetPendingMobCount() < 1 && Director.GetCommonInfectedCount() < 1 )
				{
					if ( !Director.IsTankInPlay() && !Director.IsAnySurvivorInCombat() )
					{
						printl( "*!* Update firing event 1 (VO Prompt)" )
						LastVOButtonStageNumber = CurrentFinaleStageNumber
						Director.UserDefinedEvent1()
					}
				}
			}
		}
	}
	
}


function EnableEscapeTanks()
{
	printl( "*!* EnableEscapeTanks finale stage " + CurrentFinaleStageNumber + " of type " +CurrentFinaleStageType );
	
	//Msg( "\n*****\nMapScript.DirectorOptions:\n" );
	//foreach( key, value in MapScript.DirectorOptions )
	//{
	//	Msg( "    " + key + " = " + value + "\n" );
	//}

	MapScript.DirectorOptions.EscapeSpawnTanks <- true
}
