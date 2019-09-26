// Used to control the spawn of I Hate Mountains 2 (map 2) tank.
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
			// -1304.231079 -702.810608 967.286316;
			pos.x = -1304.231079;
			pos.y = -702.810608;
			pos.z = 967.286316;
			tank.SetOrigin(pos);
			
			// Kill the timer that keeps running this script
			EntFire( "tank_spawned_timer", "Disable", 0 );
		}
	}
}

TeleTank();