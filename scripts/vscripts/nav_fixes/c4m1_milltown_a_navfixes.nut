printl("\n[NavFixes] c4m1_milltown_a_navfixes initialized\n")

//Fix 1: Fix jesus spot on table in burger tank//
//Issue: Nav area has one way connections, making it impossible for common to path

//Get nav areas:
//Problematic nav area (on the table)
local fix1_jesusNav = NavMesh.GetNavAreaByID(290844)
//Nav areas to connect
local fix1_nav_a1 = NavMesh.GetNavAreaByID(290839) //Nav in front of table

//Create two-way connection between nav areas
fix1_nav_a1.ConnectTo(fix1_jesusNav,0)

//Remove commentary fixes blocking the table
local fix1_washerBox = null
if((fix1_washerBox = Entities.FindByClassnameWithin(null, "prop_dynamic", Vector(-5824,7166.52,160.131), 10)) != null)
{
	if (developer() > 0)
	{
		local fix1_washerOrigin = NetProps.GetPropVector(fix1_washerBox, "m_vecOrigin")
		printl("Prop at: " + fix1_washerOrigin + " removed")
	}
	fix1_washerBox.Kill()
}

local fix1_tableBlocker = null
if((fix1_tableBlocker = Entities.FindByClassnameWithin(null, "env_player_blocker", Vector(-5840,7132,136), 10)) != null)
{
	if (developer() > 0)
	{
		local fix1_blockerOrigin = NetProps.GetPropVector(fix1_tableBlocker, "m_vecOrigin")
		printl("Blocker at: " + fix1_blockerOrigin + " removed")
	}
	fix1_tableBlocker.Kill()
}

printl("\n[NavFixes] Fix 1 applied\n")