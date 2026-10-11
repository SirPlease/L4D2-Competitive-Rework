printl("\n[NavFixes] cdta_03warehouse initialized\n")

//Fix 1: Fix AI having issues pathing over the balcony under the fire escape//
//Issue: Nav area on balcony has is only connected by the ladder which AI doesn't see as a valid path from above, and nav under the fire escape is connected to the fire escape which causes AI to attempt to path through it
function cdta_03warehouse_navfixes_fix1()
{
	//Get nav areas:
	//Problematic nav areas
	local fix1_balconyNav_a = NavMesh.GetNavAreaByID(162748)
	local fix1_underLadderNav_b = NavMesh.GetNavAreaByID(162745)
	//Nav areas to connect
	local fix1_nav_a = NavMesh.GetNavAreaByID(162689)
	local fix1_nav_b = NavMesh.GetNavAreaByID(136940)
	
	//Create one-way connection between nav areas
	fix1_balconyNav_a.ConnectTo(fix1_nav_a,-1)
	//Disconnect invalid navs on fire escape
	fix1_underLadderNav_b.Disconnect(fix1_nav_b)
	fix1_nav_b.Disconnect(fix1_underLadderNav_b)
	
	printl("\n[NavFixes] Fix 1 applied\n")
}


cdta_03warehouse_navfixes_fix1()