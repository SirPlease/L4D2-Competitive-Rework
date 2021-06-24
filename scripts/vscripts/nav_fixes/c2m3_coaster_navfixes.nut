printl("\n[NavFixes] c2m3_coaster_navfixes initialized\n")

//Fix 1: Fix jesus spot on coaster fence by the first ramp//
//Issue: Nav area has one way connections, making it impossible for common to path

//Get nav areas:
//Problematic nav area (on the fence)
local fix1_jesusNav = NavMesh.GetNavAreaByID(414389)
//Nav areas to connect
local fix1_nav_a1 = NavMesh.GetNavAreaByID(420193) //Large nav on opposite side of fence
local fix1_nav_a2 = NavMesh.GetNavAreaByID(315284) //Small nav on opposite side of fence
local fix1_nav_b1 = NavMesh.GetNavAreaByID(183482) //Large nav on coaster ramp
local fix1_nav_b2 = NavMesh.GetNavAreaByID(183490) //Small nav on coaster ramp

//Create two-way connection between nav areas
fix1_nav_a1.ConnectTo(fix1_jesusNav,3)
fix1_nav_a2.ConnectTo(fix1_jesusNav,3)
fix1_nav_b1.ConnectTo(fix1_jesusNav,1)
fix1_nav_b2.ConnectTo(fix1_jesusNav,1)

printl("\n[NavFixes] Fix 1 applied\n")