printl("\n[NavFixes] cwm1_intro_navfixes initialized\n")

//Fix 1: Fix jesus spot on top of bus outside saferoom//
//Issue: Nav area has one way connections, making it impossible for common to path
function cwm1_intro_navfixes_fix1()
{
	//Get nav areas:
	//Problematic nav areas (on top of bus)
	local fix1_jesusNav_a = NavMesh.GetNavAreaByID(20667)
	local fix1_jesusNav_b = NavMesh.GetNavAreaByID(22510)
	local fix1_jesusNav_c = NavMesh.GetNavAreaByID(29368)
	local fix1_jesusNav_d = NavMesh.GetNavAreaByID(29526)
	local fix1_jesusNav_e = NavMesh.GetNavAreaByID(20664)
	//Nav areas to connect
	local fix1_nav_ad1 = NavMesh.GetNavAreaByID(29514)
	local fix1_nav_a2 = NavMesh.GetNavAreaByID(21456)
	local fix1_nav_b1 = NavMesh.GetNavAreaByID(22512)
	local fix1_nav_b2 = NavMesh.GetNavAreaByID(22740)
	local fix1_nav_c = NavMesh.GetNavAreaByID(19033)
	local fix1_nav_e1 = NavMesh.GetNavAreaByID(20307)
	local fix1_nav_e2 = NavMesh.GetNavAreaByID(29429)
	local fix1_nav_e3 = NavMesh.GetNavAreaByID(29369)
	
	//Create one-way connection between nav areas
	fix1_nav_ad1.ConnectTo(fix1_jesusNav_a,-1)
	fix1_nav_a2.ConnectTo(fix1_jesusNav_a,-1)
	fix1_nav_b1.ConnectTo(fix1_jesusNav_b,-1)
	fix1_nav_b2.ConnectTo(fix1_jesusNav_b,-1)
	fix1_nav_c.ConnectTo(fix1_jesusNav_c,-1)
	fix1_nav_ad1.ConnectTo(fix1_jesusNav_d,-1)
	fix1_nav_e1.ConnectTo(fix1_jesusNav_e,-1)
	fix1_nav_e2.ConnectTo(fix1_jesusNav_e,-1)
	fix1_nav_e3.ConnectTo(fix1_jesusNav_e,-1)
	
	printl("\n[NavFixes] Fix 1 applied\n")
}

//Fix 2: Fix jesus spot on truck and buses after warehouse//
//Issue: Nav area has one way connections, making it impossible for common to path
function cwm1_intro_navfixes_fix2()
{
	//Get nav areas:
	//Problematic nav areas
	// Truck
	local fix1_jesusNav_a = NavMesh.GetNavAreaByID(48708)
	local fix1_jesusNav_b = NavMesh.GetNavAreaByID(48614)
	local fix1_jesusNav_c = NavMesh.GetNavAreaByID(48607)
	local fix1_jesusNav_d = NavMesh.GetNavAreaByID(48762)
	// Bus 1
	local fix1_jesusNav_e = NavMesh.GetNavAreaByID(48634)
	local fix1_jesusNav_f = NavMesh.GetNavAreaByID(48705)
	local fix1_jesusNav_g = NavMesh.GetNavAreaByID(48704)
	// Bus 2
	local fix1_jesusNav_h = NavMesh.GetNavAreaByID(48771)
	local fix1_jesusNav_i = NavMesh.GetNavAreaByID(48824)
	local fix1_jesusNav_j = NavMesh.GetNavAreaByID(48683)
	//Nav areas to connect
	local fix1_nav_a = NavMesh.GetNavAreaByID(48884)
	local fix1_nav_b = NavMesh.GetNavAreaByID(48578)
	local fix1_nav_c1 = NavMesh.GetNavAreaByID(48764)
	local fix1_nav_c2 = NavMesh.GetNavAreaByID(48605)
	local fix1_nav_d1 = NavMesh.GetNavAreaByID(48633)
	local fix1_nav_d2 = NavMesh.GetNavAreaByID(49984)
	local fix1_nav_e = NavMesh.GetNavAreaByID(50019)
	local fix1_nav_f = NavMesh.GetNavAreaByID(50011)
	local fix1_nav_g = NavMesh.GetNavAreaByID(48747)
	local fix1_nav_h = NavMesh.GetNavAreaByID(48555)
	local fix1_nav_i = NavMesh.GetNavAreaByID(48598)
	local fix1_nav_j1 = NavMesh.GetNavAreaByID(48837)
	local fix1_nav_j2 = NavMesh.GetNavAreaByID(48737)
	
	//Create one-way connection between nav areas
	fix1_nav_a.ConnectTo(fix1_jesusNav_a,-1)
	fix1_nav_b.ConnectTo(fix1_jesusNav_b,-1)
	fix1_nav_c1.ConnectTo(fix1_jesusNav_c,-1)
	fix1_nav_c2.ConnectTo(fix1_jesusNav_c,-1)
	fix1_nav_d1.ConnectTo(fix1_jesusNav_d,-1)
	fix1_nav_d2.ConnectTo(fix1_jesusNav_d,-1)
	fix1_nav_e.ConnectTo(fix1_jesusNav_e,-1)
	fix1_nav_f.ConnectTo(fix1_jesusNav_f,-1)
	fix1_nav_g.ConnectTo(fix1_jesusNav_g,-1)
	fix1_nav_h.ConnectTo(fix1_jesusNav_h,-1)
	fix1_nav_i.ConnectTo(fix1_jesusNav_i,-1)
	fix1_nav_j1.ConnectTo(fix1_jesusNav_j,-1)
	fix1_nav_j2.ConnectTo(fix1_jesusNav_j,-1)
	
	printl("\n[NavFixes] Fix 2 applied\n")
}


cwm1_intro_navfixes_fix1()
cwm1_intro_navfixes_fix2()