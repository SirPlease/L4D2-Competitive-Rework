printl("\n[NavFixes] x1m3_city_navfixes initialized\n")

//Fix 1: Fix god spot room behind previously unbreakable door in holdout area//
//Issue: Nav area has no connections to the main room, making it impossible for common to path
function x1m3_city_navfixes_fix1()
{
	//Get nav areas:
	//Problematic nav areas
	local fix1_jesusNav_a = NavMesh.GetNavAreaByID(1607)
	//Create two way connection on railing so commons have an alternative way to path
	local fix1_jesusNav_b = NavMesh.GetNavAreaByID(10647)
	//Nav areas to connect
	local fix1_nav_a = NavMesh.GetNavAreaByID(12)
	local fix1_nav_b = NavMesh.GetNavAreaByID(8961)
	
	//Create two-way connection between nav areas
	fix1_nav_a.ConnectTo(fix1_jesusNav_a,-1)
	fix1_jesusNav_a.ConnectTo(fix1_nav_a,-1)
	fix1_nav_b.ConnectTo(fix1_jesusNav_b,-1)
	
	printl("\n[NavFixes] Fix 1 applied\n")
}


x1m3_city_navfixes_fix1()