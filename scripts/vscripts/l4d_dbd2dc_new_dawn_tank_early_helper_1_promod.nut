// Used to prevent early tanks on Dead Before Dawn:DC finale
// from getting stuck behind the finale start gate

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
			// Kill the second timer that is responsible for teleporting the early tank
			// because the tank spawned early enough that we don't need to worry about him getting stuck
			EntFire( "tank_early_timer_2", "Kill", 0 );

			// Kill the timer that keeps running this script
			EntFire( "tank_early_timer_1", "Disable", 0 );
		}
	}
}

TeleTank();
