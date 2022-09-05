Msg("Initiating c14m2_lighthouse_finale rework script\n");

StageDelay <- 10
PreEscapeDelay <- 10

//-----------------------------------------------------
PANIC <- 0
TANK <- 1
DELAY <- 2
ONSLAUGHT <- 3
//-----------------------------------------------------

DirectorOptions <-
{
	A_CustomFinale_StageCount = 8
	
	A_CustomFinale1 		= PANIC
	A_CustomFinaleValue1 	= 1
	A_CustomFinale2 		= DELAY
	A_CustomFinaleValue2 	= StageDelay
	A_CustomFinale3 		= TANK
	A_CustomFinaleValue3 	= 1
	A_CustomFinale4 		= DELAY
	A_CustomFinaleValue4 	= StageDelay
	A_CustomFinale5			= ONSLAUGHT
	A_CustomFinaleValue5 	= "c14m2_gauntlet"
	A_CustomFinale6 		= DELAY
	A_CustomFinaleValue6 	= StageDelay
	A_CustomFinale7			= TANK
	A_CustomFinaleValue7	= 2
	A_CustomFinaleMusic7	= "Event.TankMidpoint_Metal"
	A_CustomFinale8 		= DELAY
	A_CustomFinaleValue8 	= PreEscapeDelay
	//-----------------------------------------------------

	ProhibitBosses = true
	HordeEscapeCommonLimit = 20
	EscapeSpawnTanks = false
}

local difficulty = GetDifficulty();

if ( Director.GetGameModeBase() == "versus" )
{
	DirectorOptions.rawdelete("A_CustomFinaleMusic7");
	DirectorOptions.A_CustomFinale_StageCount = 11;
	DirectorOptions.A_CustomFinale5	= ONSLAUGHT; //Rework
	DirectorOptions.A_CustomFinaleValue5 = "c14m2_gauntlet_vs"; //Rework
	DirectorOptions.A_CustomFinale6 = ONSLAUGHT;
	DirectorOptions.A_CustomFinaleValue6 = "c14m2_gauntlet_vs";
	DirectorOptions.A_CustomFinale7 = ONSLAUGHT;
	DirectorOptions.A_CustomFinaleValue7 = "c14m2_gauntlet_vs";
	DirectorOptions.A_CustomFinale8 = ONSLAUGHT;
	DirectorOptions.A_CustomFinaleValue8 = "c14m2_gauntlet_vs";
	DirectorOptions.A_CustomFinale9 <- DELAY;
	DirectorOptions.A_CustomFinaleValue9 <- StageDelay;
	DirectorOptions.A_CustomFinale10 <- TANK;
	DirectorOptions.A_CustomFinaleValue10 <- 1;
	DirectorOptions.A_CustomFinaleMusic10 <- "Event.TankMidpoint_Metal";
	DirectorOptions.A_CustomFinale11 <- DELAY;
	DirectorOptions.A_CustomFinaleValue11 <- PreEscapeDelay;
	difficulty = 1;
}
else
{
	if ( difficulty == 2 || difficulty == 3 )
	{
		DirectorOptions.rawdelete("A_CustomFinaleMusic7");
		DirectorOptions.A_CustomFinale_StageCount = 12;
		DirectorOptions.A_CustomFinaleValue7 = 1;
		DirectorOptions.A_CustomFinaleValue8 = StageDelay;
		DirectorOptions.A_CustomFinale9 <- PANIC;
		DirectorOptions.A_CustomFinaleValue9 <- 2;
		DirectorOptions.A_CustomFinale10 <- DELAY;
		DirectorOptions.A_CustomFinaleValue10 <- StageDelay;
		DirectorOptions.A_CustomFinale11 <- TANK;
		DirectorOptions.A_CustomFinaleValue11 <- 2;
		DirectorOptions.A_CustomFinaleMusic11 <- "Event.TankMidpoint_Metal"
		DirectorOptions.A_CustomFinale12 <- DELAY;
		DirectorOptions.A_CustomFinaleValue12 <- PreEscapeDelay;
	}
}

//-----------------------------------------------------

function SpawnScavengeCans( difficulty )
{
	local function SpawnCan( gascan )
	{
		local can_origin = gascan.GetOrigin();
		local can_angles = gascan.GetAngles();
		gascan.Kill();
		
		local kvs =
		{
			angles = can_angles.ToKVString()
			body = 0
			disableshadows = 1
			glowstate = 3
			model = "models/props_junk/gascan001a.mdl"
			skin = 2
			weaponskin = 2
			solid = 0
			spawnflags = 2
			targetname = "scavenge_gascans"
			origin = can_origin.ToKVString()
			connections =
			{
				OnItemPickedUp =
				{
					cmd1 = "directorRunScriptCodeDirectorScript.MapScript.LocalScript.GasCanTouched()0-1"
				}
			}
		}
		local can_spawner = SpawnEntityFromTable( "weapon_scavenge_item_spawn", kvs );
		if ( can_spawner )
			DoEntFire( "!self", "SpawnItem", "", 0, null, can_spawner );
	}
	
	switch( difficulty )
	{
		case 3:
		{
			local gascan = null;
			while ( gascan = Entities.FindByName( gascan, "gascans_finale_expert" ) )
			{
				if ( gascan.IsValid() )
					SpawnCan( gascan );
			}
		}
		case 2:
		{
			local gascan = null;
			while ( gascan = Entities.FindByName( gascan, "gascans_finale_advanced" ) )
			{
				if ( gascan.IsValid() )
					SpawnCan( gascan );
			}
		}
		case 1:
		{
			local gascan = null;
			while ( gascan = Entities.FindByName( gascan, "gascans_finale_normal" ) )
			{
				if ( gascan.IsValid() )
					SpawnCan( gascan );
			}
		}
		case 0:
		{
			local gascan = null;
			while ( gascan = Entities.FindByName( gascan, "gascans_finale_easy" ) )
			{
				if ( gascan.IsValid() )
					SpawnCan( gascan );
			}
			break;
		}
		default:
			break;
	}
	
	EntFire( "gascans_finale_*", "Kill" );
}

// number of cans needed to escape.
NumCansNeeded <- 8

switch( difficulty )
{
	case 0:
	{
		NumCansNeeded = 6;
		EntFire( "relay_outro_easy", "Enable" );
		break;
	}
	case 1:
	{
		//Rework
		if ( Director.GetGameModeBase() == "versus" )
		{
			NumCansNeeded = 6;
		}
		else
		{
				NumCansNeeded = 8;
		}
		EntFire( "relay_outro_normal", "Enable" );
		break;
	}
	case 2:
	{
		NumCansNeeded = 10;
		EntFire( "relay_outro_advanced", "Enable" );
		break;
	}
	case 3:
	{
		NumCansNeeded = 12;
		EntFire( "relay_outro_expert", "Enable" );
		break;
	}
	default:
		break;
}

EntFire( "progress_display", "SetTotalItems", NumCansNeeded );
EntFire( "radio", "AddOutput", "FinaleEscapeStarted director:RunScriptCode:DirectorScript.MapScript.LocalScript.DirectorOptions.TankLimit <- 3:0:-1" );

local c14m2_tankspawntime = 0.0;
local c14m2_tankspawner = null;
while ( c14m2_tankspawner = Entities.FindByClassname( c14m2_tankspawner, "commentary_zombie_spawner" ) )
{
	if ( c14m2_tankspawner.IsValid() )
	{
		c14m2_tankspawner.ValidateScriptScope();
		local spawnerScope = c14m2_tankspawner.GetScriptScope();
		spawnerScope.SpawnedTankTime <- 0.0;
		spawnerScope.InputSpawnZombie <- function()
		{
			if ( (caller) && (caller.GetName() == "escapetanktrigger") )
			{
				if ( !c14m2_tankspawntime )
					c14m2_tankspawntime = Time();
			}
			if ( SpawnedTankTime )
			{
				if ( Time() - c14m2_tankspawntime < 1 )
					return false;
				else
				{
					delete this.SpawnedTankTime;
					delete this.InputSpawnZombie;
					return true;
				}
			}
			
			SpawnedTankTime = Time();
			return true;
		}
	}
}

//-----------------------------------------------------
//      INIT
//-----------------------------------------------------

GasCansTouched          <- 0
GasCansPoured           <- 0
ScavengeCansPoured		<- 0
ScavengeCansNeeded		<- 2

local EscapeStage = DirectorOptions.A_CustomFinale_StageCount;

//-----------------------------------------------------

function GasCanTouched()
{
	GasCansTouched++;
	if ( developer() > 0 )
		Msg(" Touched: " + GasCansTouched + "\n");
}

function GasCanPoured()
{
	GasCansPoured++;
	ScavengeCansPoured++;
	if ( developer() > 0 )
		Msg(" Poured: " + GasCansPoured + "\n");

	if ( GasCansPoured == 1 )
		EntFire( "explain_fuel_generator", "Kill" );
	else if ( GasCansPoured == NumCansNeeded )
	{
		if ( developer() > 0 )
			Msg(" needed: " + NumCansNeeded + "\n");
		EntFire( "relay_generator_ready", "Trigger", "", 0.1 );
		EntFire( "weapon_scavenge_item_spawn", "TurnGlowsOff" );
		EntFire( "weapon_scavenge_item_spawn", "Kill" );
		EntFire( "director", "EndCustomScriptedStage", "", 5 );
	}
	
	if ( Director.GetGameModeBase() == "versus" && ScavengeCansPoured == 2 && GasCansPoured < NumCansNeeded )
	{
		ScavengeCansPoured = 0;
		EntFire( "radio", "AdvanceFinaleState" );
	}
	
	//Rework - Skip additional scavenge stage once we reach 6 cans
	if ( Director.GetGameModeBase() == "versus" && GasCansPoured == NumCansNeeded )
	{
		Msg( "Rework advance to scavenge end \n" );
		EntFire( "radio", "AdvanceFinaleState" );
	}
}
//-----------------------------------------------------

function OnBeginCustomFinaleStage( num, type )
{
	if ( developer() > 0 )
		printl( "Beginning custom finale stage " + num + " of type " + type );
	
	if ( num == 4 )
	{
		EntFire( "relay_boat_coming2", "Trigger" );
		// Delay lasts 10 seconds, next stage turns off lights immediately
		EntFire( "lighthouse_light", "SetPattern", "mmamammmmammamamaaamammma", 7.0 );
		EntFire( "lighthouse_light", "SetPattern", "", 9.5 );
		EntFire( "lighthouse_light", "TurnOff", "", 10 );
		EntFire( "spotlight_beams", "LightOff", "", 7.0 );
		EntFire( "spotlight_glow", "HideSprite", "", 7.0 );
		EntFire( "brush_light", "Enable", "", 7.0 );
		EntFire( "spotlight_beams", "LightOn", "", 7.5 );
		EntFire( "spotlight_glow", "ShowSprite", "", 7.5 );
		EntFire( "brush_light", "Disable", "", 7.5 );
		EntFire( "spotlight_beams", "LightOff", "", 8.0 );
		EntFire( "spotlight_glow", "HideSprite", "", 8.0 );
		EntFire( "brush_light", "Enable", "", 8.0 );
		EntFire( "spotlight_beams", "LightOn", "", 8.5 );
		EntFire( "spotlight_glow", "ShowSprite", "", 8.5 );
		EntFire( "brush_light", "Disable", "", 8.5 );
	}
	else if ( num == 5 )
	{
		EntFire( "relay_lighthouse_off", "Trigger" );
		SpawnScavengeCans( difficulty );
		Director.ResetMobTimer(); //Rework
	}
	else if ( num == EscapeStage )
		EntFire( "relay_start_boat", "Trigger" );
}

function GetCustomScriptedStageProgress( defvalue )
{
	local progress = ScavengeCansPoured.tofloat() / ScavengeCansNeeded.tofloat();
	if ( developer() > 0 )
		Msg( "Progress was " + defvalue + ", now: " + ScavengeCansPoured + " poured / " + ScavengeCansNeeded + " needed = " + progress + "\n" );
	return progress;
}
