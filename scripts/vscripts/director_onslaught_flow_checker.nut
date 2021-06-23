Msg("Initiating Onslaught Flow Checker\n");

g_TankSpawned <- false
g_StartingFlow <- 0
g_MaxTravelDistance <- Convars.GetFloat("director_tank_bypass_max_flow_travel")
g_WarnedOnce <- false

// Precache warning sound
PrecacheSound("Hint.Critical")

function OnslaughtGetStartingFlow()
{
	g_TankSpawned = true
	g_StartingFlow = Director.GetFurthestSurvivorFlow()
	
	if (developer() > 0)
	{
		printl("Starting Flow: " + g_StartingFlow.tostring() + "\n")
	}
}

function OnslaughtCheckFlow()
{
	if (g_TankSpawned == true)
	{
		local CurrentMaxFlow = Director.GetFurthestSurvivorFlow()
		
		// Check furthest survivor flow
		if (CurrentMaxFlow > g_StartingFlow + (g_MaxTravelDistance * 0.7))
		{
			// Survivors have travelled past the relax threshold, horde will now spawn regardless of tank state, inform players
			if (CurrentMaxFlow > g_StartingFlow + g_MaxTravelDistance)
			{
				ClientPrint(null, 3, "\x05Horde has resumed due to progression!")
				EntFire("OnslaughtFlowChecker", "Disable")
				
				// Play sound cue to warn players
				local players = null;
				while (players = Entities.FindByClassname(players, "player"))
				{
					EmitSoundOnClient("Hint.Critical", players)
				}
			}
			else
			{
				// Warn survivors getting close to the bypass point
				if (g_WarnedOnce == false)
				{
					ClientPrint(null, 3, "\x05Survivors are nearing the allowed travel distance...")
					g_WarnedOnce = true
				}
			}
		}
		
		if (developer() > 0)
		{
			printl("Current Flow: " + CurrentMaxFlow.tostring() + "\n")
		}
	}
}
