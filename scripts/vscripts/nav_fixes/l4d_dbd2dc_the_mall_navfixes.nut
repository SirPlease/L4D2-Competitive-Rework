printl("\n[NavFixes] l4d_dbd2dc_the_mall_navfixes initialized\n")

//Fix 1: Fix jesus spot on the first large white dumpster//
//Issue: Nav area has one way connections, making it impossible for common to path
function l4d_dbd2dc_the_mall_navfixes_fix1()
{
	//Get nav areas:
	//Problematic nav areas (on the dumpster)
	local fix1_jesusNav_a = NavMesh.GetNavAreaByID(9919)
	local fix1_jesusNav_b = NavMesh.GetNavAreaByID(9910)
	local fix1_jesusNav_c = NavMesh.GetNavAreaByID(9909)
	//Nav areas to connect (commented ones return bad nav connection with all directions, not sure why)
	local fix1_nav_ab1 = NavMesh.GetNavAreaByID(9192)
	//local fix1_nav_a2 = NavMesh.GetNavAreaByID(9325)
	//local fix1_nav_b2 = NavMesh.GetNavAreaByID(9137)
	//local fix1_nav_c1 = NavMesh.GetNavAreaByID(9878)
	local fix1_nav_c2 = NavMesh.GetNavAreaByID(9152)
	
	//Create two-way connection between nav areas
	fix1_nav_ab1.ConnectTo(fix1_jesusNav_a,2)
	
	fix1_nav_ab1.ConnectTo(fix1_jesusNav_b,2)
	
	//fix1_nav_a2.ConnectTo(fix1_jesusNav_a,4)
	
	//fix1_nav_b2.ConnectTo(fix1_jesusNav_b,1)
	
	//fix1_nav_c1.ConnectTo(fix1_jesusNav_c,2)
	fix1_nav_c2.ConnectTo(fix1_jesusNav_c,1)
	
	printl("\n[NavFixes] Fix 1 applied\n")
}


//Fix 2: Fix jesus spot on van by the event//
//Issue: Nav area has one way connections / no connections, making it impossible for common to path

function l4d_dbd2dc_the_mall_navfixes_fix2()
{
	//Get nav areas:
	//Problematic nav areas (on the van)
	local fix2_jesusNav_a = NavMesh.GetNavAreaByID(15308)
	local fix2_jesusNav_b = NavMesh.GetNavAreaByID(15233)
	local fix2_jesusNav_c = NavMesh.GetNavAreaByID(15264)
	local fix2_jesusNav_d = NavMesh.GetNavAreaByID(15244)
	local fix2_jesusNav_e = NavMesh.GetNavAreaByID(15270)
	//Nav areas to connect
	local fix2_nav_a1 = NavMesh.GetNavAreaByID(15240)
	local fix2_nav_a2 = NavMesh.GetNavAreaByID(15231)
	local fix2_nav_b1 = NavMesh.GetNavAreaByID(15226)
	local fix2_nav_b2 = NavMesh.GetNavAreaByID(15228)
	local fix2_nav_c1 = NavMesh.GetNavAreaByID(15254)
	local fix2_nav_d1 = NavMesh.GetNavAreaByID(15227)
	local fix2_nav_e1 = NavMesh.GetNavAreaByID(15239)
	
	//Create two-way connection between nav areas
	fix2_nav_a1.ConnectTo(fix2_jesusNav_a,3)
	fix2_nav_b1.ConnectTo(fix2_jesusNav_b,3)
	
	//Create completely new connections to improve pathing
	fix2_nav_a2.ConnectTo(fix2_jesusNav_a,2)
	fix2_jesusNav_a.ConnectTo(fix2_nav_a2,0)
	
	fix2_nav_b2.ConnectTo(fix2_jesusNav_b,1)
	fix2_jesusNav_b.ConnectTo(fix2_nav_b2,3)
	
	fix2_nav_c1.ConnectTo(fix2_jesusNav_c,1)
	fix2_jesusNav_c.ConnectTo(fix2_nav_c1,3)
	
	fix2_nav_d1.ConnectTo(fix2_jesusNav_d,3)
	fix2_jesusNav_d.ConnectTo(fix2_nav_d1,1)
	
	fix2_nav_e1.ConnectTo(fix2_jesusNav_e,0)
	fix2_jesusNav_e.ConnectTo(fix2_nav_e1,2)
	
	printl("\n[NavFixes] Fix 2 applied\n")
}


//Fix 3: Fix jesus spot on truck by the event//
//Issue: Nav area has one way connections, making it impossible for common to path

function l4d_dbd2dc_the_mall_navfixes_fix3()
{
	//Get nav areas:
	//Problematic nav areas (on the truck)
	local fix3_jesusNav_a = NavMesh.GetNavAreaByID(3328)
	local fix3_jesusNav_b = NavMesh.GetNavAreaByID(3132)
	local fix3_jesusNav_c = NavMesh.GetNavAreaByID(3109)
	local fix3_jesusNav_x = NavMesh.GetNavAreaByID(3283)
	//Nav areas to connect
	local fix3_nav_a1 = NavMesh.GetNavAreaByID(3136)
	local fix3_nav_a2 = NavMesh.GetNavAreaByID(3043)
	local fix3_nav_a3 = NavMesh.GetNavAreaByID(3127)
	local fix3_nav_b1 = NavMesh.GetNavAreaByID(3748)
	local fix3_nav_c1 = NavMesh.GetNavAreaByID(3041)
	local fix3_nav_c2 = NavMesh.GetNavAreaByID(3055)
	local fix3_nav_c3 = NavMesh.GetNavAreaByID(3124)
	
	//Create two-way connection between nav areas
	fix3_nav_a1.ConnectTo(fix3_jesusNav_a,3)
	fix3_nav_a2.ConnectTo(fix3_jesusNav_a,2)
	fix3_nav_a3.ConnectTo(fix3_jesusNav_a,1)
	
	fix3_nav_b1.ConnectTo(fix3_jesusNav_b,2)
	
	fix3_nav_c1.ConnectTo(fix3_jesusNav_c,1)
	fix3_nav_c2.ConnectTo(fix3_jesusNav_c,1)
	
	//Create completely new connections to improve pathing
	fix3_jesusNav_a.ConnectTo(fix3_jesusNav_x,2)
	fix3_jesusNav_x.ConnectTo(fix3_jesusNav_a,0)
	
	fix3_nav_c3.ConnectTo(fix3_jesusNav_c,0)
	fix3_jesusNav_c.ConnectTo(fix3_nav_c3,2)
	
	printl("\n[NavFixes] Fix 3 applied\n")
}


l4d_dbd2dc_the_mall_navfixes_fix1()
l4d_dbd2dc_the_mall_navfixes_fix2()
l4d_dbd2dc_the_mall_navfixes_fix3()