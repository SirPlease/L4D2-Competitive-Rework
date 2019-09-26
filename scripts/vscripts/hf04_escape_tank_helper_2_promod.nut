// Once the tank dies on Haunted Forest finale,
// the onslaught script is run again to verify common limit doesn't increase

tanks <-{
	tank1 = "models/infected/hulk.mdl",
    tank2 = "models/infected/hulk_dlc3.mdl"
}

function TankIsAlive()
{
	foreach (t, m in tanks)
	{
		tank <- Entities.FindByModel(null, m);
		if (tank)
		{
			return true;
		}
	}
	return false;
}

if (!TankIsAlive())
{
	// Kill the timer that keeps running this script
	EntFire( "tank_spawned_timer_2", "Disable", 0 );
	
	// Reset Common Limit
	EntFire( "director", "BeginScript", "hf04_escape_onslaught_promod");
}