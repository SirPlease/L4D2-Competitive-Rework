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
			pos <- tank.GetOrigin();

			// -1436.083740 153.653137 -1151.968750;
			pos.x = -1436.083740;
			pos.y = 153.653137;
			pos.z = -1175.968750;
			tank.SetOrigin(pos);

			// Kill the timer that keeps running this script
			EntFire( "tank_early_timer", "Disable", 0 );
		}
	}
}

TeleTank();
