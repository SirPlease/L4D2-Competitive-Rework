Msg("Initiating Onslaught Flow Checker\n");

g_TankSpanwed <- false;
g_StartingFlow <- 0;
g_MaxTravelDistance <- Convars.GetFloat("director_tank_bypass_max_flow_travel")

function OnslaughtGetStartingFlow()
{
	g_TankSpanwed = true
	g_StartingFlow = Director.GetFurthestSurvivorFlow();
	
	if (developer() > 0)
	{
		printl("Starting Flow: " + g_StartingFlow.tostring() + "\n")
	}
}

function OnslaughtCheckFlow()
{
	if (g_TankSpanwed == true)
	{
		local CurrentMaxFlow = Director.GetFurthestSurvivorFlow();
		
		// Survivors have travelled past the relax threshold, horde will now spawn regardless of tank state, inform players
		if (CurrentMaxFlow > g_StartingFlow + g_MaxTravelDistance)
		{
			ClientPrint(null, 3, "\x05Horde has resumed due to progression")
			EntFire("OnslaughtFlowChecker", "Kill")
		}
		
		if (developer() > 0)
		{
			printl("Current Flow: " + CurrentMaxFlow.tostring() + "\n")
		}
	}
}
