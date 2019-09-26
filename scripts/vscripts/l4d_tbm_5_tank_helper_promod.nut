// Used to teleport The Bloody Moors Finale early flow tank to a safe location.
// Refer to the corresponding stripper file.

tanks <-{
	tank1 = "models/infected/hulk.mdl",
    tank2 = "models/infected/hulk_dlc3.mdl",
	tank3 = "models/bunny/infected/b_weretank.mdl"
}

function ReduceCommon() {
	DirectorOptions <-
	{
		MobSpawnSize = 17
		CommonLimit = 17
		MobMaxPending = 17
		MobMinSize = 17
		MobMaxSize = 17
	}
}

function TeleTank()
{
	foreach (t, m in tanks)
	{
		tank <- Entities.FindByModel(null, m);
		if (tank)
		{
			pos <- tank.GetOrigin();
			
			// Coordinates to where we want to teleport the tank
			// "1993.809448 1718.826538 860.031250"
			pos.x = 1993.809448;
			pos.y = 1718.826538;
			pos.z = 860.031250;
			tank.SetOrigin(pos);
			
			// Kill the timer that keeps running this script
			EntFire( "tank_spawned_timer", "Disable", 0 );
			
			// Also set common limit here for rest of map because the Gauntlet is crazy horde
			ReduceCommon();
		}
	}
}

TeleTank();