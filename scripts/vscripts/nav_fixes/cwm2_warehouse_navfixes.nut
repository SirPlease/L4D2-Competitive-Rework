printl("\n[NavFixes] cwm2_warehouse_navfixes initialized\n")

//Fix 1: Fix jesus spot on top of truck after the alarmed doors//
//Issue: Nav area has one way connections, making it impossible for common to path
function cwm2_warehouse_navfixes_fix1()
{
	//Get nav areas:
	//Problematic nav areas (on top of truck)
	local fix1_jesusNav_a = NavMesh.GetNavAreaByID(19271)
	local fix1_jesusNav_b = NavMesh.GetNavAreaByID(19258)
	local fix1_jesusNav_c = NavMesh.GetNavAreaByID(19256)
	local fix1_jesusNav_d = NavMesh.GetNavAreaByID(19247)
	//Nav areas to connect
	local fix1_nav_a = NavMesh.GetNavAreaByID(19632)
	local fix1_nav_b1 = NavMesh.GetNavAreaByID(19249)
	local fix1_nav_b2 = NavMesh.GetNavAreaByID(19269)
	local fix1_nav_c1 = NavMesh.GetNavAreaByID(19266)
	local fix1_nav_c2 = NavMesh.GetNavAreaByID(19248)
	local fix1_nav_d1 = NavMesh.GetNavAreaByID(19312)
	local fix1_nav_d2 = NavMesh.GetNavAreaByID(19234)
	
	//Create one-way connection between nav areas
	fix1_nav_a.ConnectTo(fix1_jesusNav_a,-1)
	fix1_nav_b1.ConnectTo(fix1_jesusNav_b,-1)
	fix1_nav_b2.ConnectTo(fix1_jesusNav_b,-1)
	fix1_nav_c1.ConnectTo(fix1_jesusNav_c,-1)
	fix1_nav_c2.ConnectTo(fix1_jesusNav_c,-1)
	fix1_nav_d1.ConnectTo(fix1_jesusNav_d,-1)
	fix1_nav_d2.ConnectTo(fix1_jesusNav_d,-1)
	
	printl("\n[NavFixes] Fix 1 applied\n")
}

//Fix 2: Fix jesus spot on top of van after the alarmed doors//
//Issue: Nav area has one way connections, making it impossible for common to path
function cwm2_warehouse_navfixes_fix2()
{
	//Get nav areas:
	//Problematic nav areas (on top of van)
	local fix1_jesusNav_a = NavMesh.GetNavAreaByID(18085)
	local fix1_jesusNav_b = NavMesh.GetNavAreaByID(18070)
	local fix1_jesusNav_c = NavMesh.GetNavAreaByID(16583)
	//Nav areas to connect
	local fix1_nav_a = NavMesh.GetNavAreaByID(16377)
	local fix1_nav_b1 = NavMesh.GetNavAreaByID(18064)
	local fix1_nav_b2 = NavMesh.GetNavAreaByID(16117)
	local fix1_nav_c1 = NavMesh.GetNavAreaByID(19200)
	local fix1_nav_c2 = NavMesh.GetNavAreaByID(16043)
	
	//Create one-way connection between nav areas
	fix1_nav_a.ConnectTo(fix1_jesusNav_a,-1)
	fix1_nav_b1.ConnectTo(fix1_jesusNav_b,-1)
	fix1_nav_b2.ConnectTo(fix1_jesusNav_b,-1)
	fix1_nav_c1.ConnectTo(fix1_jesusNav_c,-1)
	fix1_nav_c2.ConnectTo(fix1_jesusNav_c,-1)
	
	printl("\n[NavFixes] Fix 2 applied\n")
}


cwm2_warehouse_navfixes_fix1()
cwm2_warehouse_navfixes_fix2()