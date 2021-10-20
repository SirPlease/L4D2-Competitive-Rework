printl("\n[NavFixes] l4d_dbd2dc_clean_up_navfixes initialized\n")

//Fix 1: Fix jesus spot behind the fountain//
//Issue: Nav area has one way connections, making it impossible for common to path
function l4d_dbd2dc_clean_up_navfixes_fix1()
{
	//Get nav areas:
	//Problematic nav areas (behind the fountain)
	local fix1_jesusNav_a = NavMesh.GetNavAreaByID(7760)
	local fix1_jesusNav_b = NavMesh.GetNavAreaByID(7761)
	local fix1_jesusNav_c = NavMesh.GetNavAreaByID(7759)
	//Nav areas to connect
	local fix1_nav_abc = NavMesh.GetNavAreaByID(8608)
	local fix1_nav_a = NavMesh.GetNavAreaByID(8401)
	local fix1_nav_c = NavMesh.GetNavAreaByID(8384)
	
	//Create one-way connection between nav areas
	fix1_nav_abc.ConnectTo(fix1_jesusNav_a,1)
	fix1_nav_abc.ConnectTo(fix1_jesusNav_b,1)
	fix1_nav_abc.ConnectTo(fix1_jesusNav_c,1)
	fix1_nav_a.ConnectTo(fix1_jesusNav_a,0)
	fix1_nav_c.ConnectTo(fix1_jesusNav_c,2)
	
	printl("\n[NavFixes] Fix 1 applied\n")
}

//Fix 2: Fix commons getting stuck at the top of the stairs by the millionth customer door//
//Issue: Bad nav connection where commons fail to climb so they get stuck
function l4d_dbd2dc_clean_up_navfixes_fix2()
{
	//Get nav areas:
	//Problematic nav areas (at the top left of the stairs)
	local fix2_badNav_a = NavMesh.GetNavAreaByID(1154)
	//Nav areas to disconnect
	local fix2_nav_a = NavMesh.GetNavAreaByID(2130)
	
	//Disconnect the navs in climb direction
	fix2_nav_a.Disconnect(fix2_badNav_a)
	
	printl("\n[NavFixes] Fix 2 applied\n")
}


l4d_dbd2dc_clean_up_navfixes_fix1()
l4d_dbd2dc_clean_up_navfixes_fix2()