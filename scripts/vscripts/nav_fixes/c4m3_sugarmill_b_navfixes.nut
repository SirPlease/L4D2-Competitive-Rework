printl("\n[NavFixes] c4m3_sugarmill_b_navfixes initialized\n")

//Fix 1: Fix a jesus spot on the wire spool by the 2 silos//
//Issue: Nav area has one way connections, making it impossible for common to path

//Get nav areas:
//Problematic nav area (on the spool)
local fix1_jesusNav = NavMesh.GetNavAreaByID(9323)
//Nav areas to connect
local fix1_nav_a1 = NavMesh.GetNavAreaByID(2445) //Small nav by spool
local fix1_nav_a2 = NavMesh.GetNavAreaByID(558) //Large nav by spool

//Create two-way connection between nav areas
fix1_nav_a1.ConnectTo(fix1_jesusNav,0)
fix1_nav_a2.ConnectTo(fix1_jesusNav,2)

//Remove commentary fixes blocking the spool
local fix1_spoolBlocker = null
if((fix1_spoolBlocker = Entities.FindByClassnameWithin(null, "env_player_blocker", Vector(502,-6628,200), 10)) != null)
{
	if (developer() > 0)
	{
		local fix1_blockerOrigin = NetProps.GetPropVector(fix1_spoolBlocker, "m_vecOrigin")
		printl("Blocker at: " + fix1_blockerOrigin + " removed")
	}
	fix1_spoolBlocker.Kill()
}

printl("\n[NavFixes] Fix 1 applied\n")