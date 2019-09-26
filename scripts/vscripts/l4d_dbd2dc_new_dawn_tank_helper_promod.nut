// Used to convert Dead Before Dawn: DC's finale to a gauntlet.
// Refer to the corresponding stripper file.

tanks <-{
	tank1 = "models/infected/hulk.mdl",
    tank2 = "models/infected/hulk_dlc3.mdl"
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
			// "-1014.411316 2127.294922 -416.949554"
			pos.x = -1014.411316;
			pos.y = 2127.294922;
			pos.z = -416.949554;
			tank.SetOrigin(pos);
			
			// Kill the timer that keeps running this script
			EntFire( "tank_spawned_timer", "Disable", 0 );
			
			// Start the timer that monitors the tank music
			EntFire( "tank_music_timer", "Enable", 0 );
		}
	}
}

TeleTank();