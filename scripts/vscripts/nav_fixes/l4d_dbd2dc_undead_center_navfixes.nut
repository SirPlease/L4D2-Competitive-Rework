printl("\n[NavFixes] l4d_dbd2dc_undead_center_navfixes initialized\n")

//Fix 1: Fix jesus spots on kiosks at the start of the map on the 1st floor//
//Issue: Nav area has one way connections, making it impossible for common to path
function l4d_dbd2dc_clean_up_navfixes_fix1()
{
	//Get nav areas:
	//Problematic nav areas
	local fix1_kisok1_a = NavMesh.GetNavAreaByID(4528)
	local fix1_kisok1_b = NavMesh.GetNavAreaByID(4527)
	local fix1_kisok1_c = NavMesh.GetNavAreaByID(4529)
	local fix1_kisok1_d = NavMesh.GetNavAreaByID(1491)
	local fix1_kisok1_e = NavMesh.GetNavAreaByID(4517)
	local fix1_kisok1_f = NavMesh.GetNavAreaByID(4520)
	
	local fix1_kisok2_a = NavMesh.GetNavAreaByID(4506)
	local fix1_kisok2_b = NavMesh.GetNavAreaByID(4508)
	
	local fix1_kisok_connect_a = NavMesh.GetNavAreaByID(4516)
	//Nav areas to connect
	local fix1_nav_kisok1_ab = NavMesh.GetNavAreaByID(592)
	local fix1_nav_kisok1_bf = NavMesh.GetNavAreaByID(4523)
	local fix1_nav_kisok1_cde = NavMesh.GetNavAreaByID(188)
	local fix1_nav_kisok1_f = NavMesh.GetNavAreaByID(4513)
	
	local fix1_nav_kisok2_a = NavMesh.GetNavAreaByID(72)
	local fix1_nav_kisok2_ab = NavMesh.GetNavAreaByID(477)
	local fix1_nav_kisok2_b = NavMesh.GetNavAreaByID(188)
	
	//Create one-way connection between nav areas
	fix1_nav_kisok1_ab.ConnectTo(fix1_kisok1_a,3)
	fix1_nav_kisok1_ab.ConnectTo(fix1_kisok1_b,3)
	fix1_nav_kisok1_cde.ConnectTo(fix1_kisok1_c,2)
	fix1_nav_kisok1_cde.ConnectTo(fix1_kisok1_d,2)
	fix1_nav_kisok1_cde.ConnectTo(fix1_kisok1_e,2)
	fix1_nav_kisok1_bf.ConnectTo(fix1_kisok1_b,0)
	fix1_nav_kisok1_bf.ConnectTo(fix1_kisok1_f,0)
	fix1_nav_kisok1_f.ConnectTo(fix1_kisok1_f,0)
	
	fix1_nav_kisok2_a.ConnectTo(fix1_kisok2_a,0)
	fix1_nav_kisok2_ab.ConnectTo(fix1_kisok2_a,1)
	fix1_nav_kisok2_ab.ConnectTo(fix1_kisok2_b,1)
	fix1_nav_kisok2_b.ConnectTo(fix1_kisok2_b,2)
	
	fix1_kisok2_a.ConnectTo(fix1_kisok_connect_a,1)
	fix1_kisok_connect_a.ConnectTo(fix1_kisok2_a,3)
	
	printl("\n[NavFixes] Fix 1 applied\n")
}

//Fix 2: Fix jesus spots on kiosks at the start of the map on the 2nd floor//
//Issue: Nav area has one way connections, making it impossible for common to path
function l4d_dbd2dc_clean_up_navfixes_fix2()
{
	//Get nav areas:
	//Problematic nav areas
	local fix2_kisok1_a = NavMesh.GetNavAreaByID(3755)
	local fix2_kisok1_b = NavMesh.GetNavAreaByID(3748)
	
	local fix2_kisok2_a = NavMesh.GetNavAreaByID(3739)
	local fix2_kisok2_b = NavMesh.GetNavAreaByID(3738)
	
	local fix1_kisok_connect_a = NavMesh.GetNavAreaByID(3744)
	local fix1_kisok_connect_b = NavMesh.GetNavAreaByID(3740)
	//Nav areas to connect
	local fix2_nav_kisok1_a = NavMesh.GetNavAreaByID(297)
	local fix2_nav_kisok1_b = NavMesh.GetNavAreaByID(131)
	local fix2_nav_kisok1_b2 = NavMesh.GetNavAreaByID(245)
	
	local fix2_nav_kisok2_ab = NavMesh.GetNavAreaByID(718)
	
	//Create one-way connection between nav areas
	fix2_nav_kisok1_a.ConnectTo(fix2_kisok1_a,3)
	fix2_nav_kisok1_b.ConnectTo(fix2_kisok1_b,0)
	fix2_nav_kisok1_b2.ConnectTo(fix2_kisok1_b,0)
	
	fix2_nav_kisok2_ab.ConnectTo(fix2_kisok2_a,1)
	fix2_nav_kisok2_ab.ConnectTo(fix2_kisok2_b,1)
	
	fix1_kisok_connect_b.ConnectTo(fix1_kisok_connect_a,1)
	fix1_kisok_connect_a.ConnectTo(fix1_kisok_connect_b,3)
	
	printl("\n[NavFixes] Fix 2 applied\n")
}

//Fix 3: Fix jesus spots on kiosks by the forklift event//
//Issue: Nav area has one way connections, making it impossible for common to path
function l4d_dbd2dc_clean_up_navfixes_fix3()
{
	//Get nav areas:
	//Problematic nav areas
	local fix3_kisok1_a = NavMesh.GetNavAreaByID(1660)
	local fix3_kisok1_b = NavMesh.GetNavAreaByID(5428)
	local fix3_kisok1_c = NavMesh.GetNavAreaByID(1091)
	
	local fix3_kisok2_a = NavMesh.GetNavAreaByID(5443)
	local fix3_kisok2_b = NavMesh.GetNavAreaByID(805)
	
	local fix3_kisok3_a = NavMesh.GetNavAreaByID(5489)
	local fix3_kisok3_b = NavMesh.GetNavAreaByID(5490)
	
	local fix3_kisok4_a = NavMesh.GetNavAreaByID(5383)
	local fix3_kisok4_b = NavMesh.GetNavAreaByID(5373)
	//Nav areas to connect
	local fix3_nav_kisok1_a_kiosk2_a = NavMesh.GetNavAreaByID(160)
	local fix3_nav_kisok1_b = NavMesh.GetNavAreaByID(1658)
	local fix3_nav_kisok1_c = NavMesh.GetNavAreaByID(139)
	
	local fix3_nav_kisok2_a2 = NavMesh.GetNavAreaByID(5451)
	local fix3_nav_kisok2_a3 = NavMesh.GetNavAreaByID(5310)
	local fix3_nav_kisok2_b = NavMesh.GetNavAreaByID(496)
	local fix3_nav_kisok2_b2 = NavMesh.GetNavAreaByID(624)
	local fix3_nav_kisok2_b3 = NavMesh.GetNavAreaByID(139)
	
	local fix3_nav_kisok3_ab = NavMesh.GetNavAreaByID(50)
	local fix3_nav_kisok3_a2 = NavMesh.GetNavAreaByID(322)
	local fix3_nav_kisok3_a3 = NavMesh.GetNavAreaByID(101)
	local fix3_nav_kisok3_b = NavMesh.GetNavAreaByID(229)
	
	local fix3_nav_kisok4_a = NavMesh.GetNavAreaByID(320)
	local fix3_nav_kisok4_a2 = NavMesh.GetNavAreaByID(118)
	local fix3_nav_kisok4_a3 = NavMesh.GetNavAreaByID(803)
	local fix3_nav_kisok4_b = NavMesh.GetNavAreaByID(42)
	
	//Create one-way connection between nav areas
	fix3_nav_kisok1_a_kiosk2_a.ConnectTo(fix3_kisok1_a,3)
	fix3_nav_kisok1_b.ConnectTo(fix3_kisok1_b,0)
	fix3_nav_kisok1_c.ConnectTo(fix3_kisok1_c,1)
	
	fix3_nav_kisok1_a_kiosk2_a.ConnectTo(fix3_kisok2_a,3)
	fix3_nav_kisok2_a2.ConnectTo(fix3_kisok2_a,3)
	fix3_nav_kisok2_a3.ConnectTo(fix3_kisok2_a,2)
	fix3_nav_kisok2_b.ConnectTo(fix3_kisok2_b,2)
	fix3_nav_kisok2_b2.ConnectTo(fix3_kisok2_b,1)
	fix3_nav_kisok2_b3.ConnectTo(fix3_kisok2_b,1)
	
	fix3_nav_kisok3_ab.ConnectTo(fix3_kisok3_a,0)
	fix3_nav_kisok3_a2.ConnectTo(fix3_kisok3_a,3)
	fix3_nav_kisok3_a3.ConnectTo(fix3_kisok3_a,2)
	fix3_nav_kisok3_ab.ConnectTo(fix3_kisok3_b,0)
	fix3_nav_kisok3_b.ConnectTo(fix3_kisok3_b,1)
	
	fix3_nav_kisok4_a.ConnectTo(fix3_kisok4_a,3)
	fix3_nav_kisok4_a2.ConnectTo(fix3_kisok4_a,2)
	fix3_nav_kisok4_a3.ConnectTo(fix3_kisok4_a,2)
	fix3_nav_kisok4_b.ConnectTo(fix3_kisok4_b,0)
	
	printl("\n[NavFixes] Fix 3 applied\n")
}

//Fix 4: Fix jesus spots on warehouse shelves and table by the forklift event//
//Issue: Nav area has no / one way connections, making it impossible for common to path
function l4d_dbd2dc_clean_up_navfixes_fix4()
{
	//Get nav areas:
	//Problematic nav areas
	local fix4_jesusNav_a = NavMesh.GetNavAreaByID(5614)
	local fix4_jesusNav_b = NavMesh.GetNavAreaByID(5610)
	local fix4_jesusNav_b2 = NavMesh.GetNavAreaByID(5598)
	local fix4_jesusNav_b3 = NavMesh.GetNavAreaByID(5597)
	local fix4_jesusNav_c = NavMesh.GetNavAreaByID(5611)
	//Nav areas to connect
	local fix4_nav_ac = NavMesh.GetNavAreaByID(807)
	local fix4_nav_a = NavMesh.GetNavAreaByID(6005)
	local fix4_nav_b3 = NavMesh.GetNavAreaByID(141)
	
	//Create one-way connection between nav areas
	fix4_nav_a.ConnectTo(fix4_jesusNav_a,1)
	fix4_nav_ac.ConnectTo(fix4_jesusNav_a,0)
	fix4_jesusNav_a.ConnectTo(fix4_nav_ac,2)
	
	fix4_jesusNav_c.ConnectTo(fix4_jesusNav_b,2)
	fix4_jesusNav_b.ConnectTo(fix4_jesusNav_c,0)
	
	fix4_jesusNav_b2.ConnectTo(fix4_jesusNav_b,1)
	fix4_jesusNav_b.ConnectTo(fix4_jesusNav_b2,3)
	
	fix4_nav_b3.ConnectTo(fix4_jesusNav_b2,2)
	fix4_jesusNav_b2.ConnectTo(fix4_nav_b3,0)
	
	fix4_nav_b3.ConnectTo(fix4_jesusNav_b3,2)
	fix4_jesusNav_b3.ConnectTo(fix4_nav_b3,0)
	
	fix4_nav_ac.ConnectTo(fix4_jesusNav_c,2)
	fix4_jesusNav_c.ConnectTo(fix4_nav_ac,0)
	
	printl("\n[NavFixes] Fix 4 applied\n")
}

//Fix 5: Fix jesus spots in kiddyland - almost every prop is a jesus spot//
//Issue: Nav area has no / one way connections, making it impossible for common to path
function l4d_dbd2dc_clean_up_navfixes_fix5()
{
	//Get nav areas:
	//Problematic nav areas
	local fix5_jesusNav_a = NavMesh.GetNavAreaByID(2323)
	local fix5_jesusNav_b = NavMesh.GetNavAreaByID(2249)
	local fix5_jesusNav_c = NavMesh.GetNavAreaByID(2302)
	local fix5_jesusNav_c2 = NavMesh.GetNavAreaByID(2297)
	local fix5_jesusNav_c3 = NavMesh.GetNavAreaByID(2295)
	local fix5_jesusNav_c4 = NavMesh.GetNavAreaByID(2312)
	local fix5_jesusNav_d = NavMesh.GetNavAreaByID(2230)
	local fix5_jesusNav_e = NavMesh.GetNavAreaByID(2184)
	local fix5_jesusNav_f = NavMesh.GetNavAreaByID(1152)
	local fix5_jesusNav_f2 = NavMesh.GetNavAreaByID(2030)
	local fix5_jesusNav_g = NavMesh.GetNavAreaByID(1167)
	local fix5_jesusNav_h = NavMesh.GetNavAreaByID(2024)
	local fix5_jesusNav_h2 = NavMesh.GetNavAreaByID(2010)
	local fix5_jesusNav_h3 = NavMesh.GetNavAreaByID(2021)
	local fix5_jesusNav_h4 = NavMesh.GetNavAreaByID(2064)
	local fix5_jesusNav_i = NavMesh.GetNavAreaByID(1990)
	local fix5_jesusNav_j = NavMesh.GetNavAreaByID(2172)
	local fix5_jesusNav_j2 = NavMesh.GetNavAreaByID(6031)
	local fix5_jesusNav_j3 = NavMesh.GetNavAreaByID(6030)
	local fix5_jesusNav_j4 = NavMesh.GetNavAreaByID(5758)
	local fix5_jesusNav_k = NavMesh.GetNavAreaByID(2090)
	local fix5_jesusNav_l = NavMesh.GetNavAreaByID(1880)
	local fix5_jesusNav_l2 = NavMesh.GetNavAreaByID(1840)
	local fix5_jesusNav_m = NavMesh.GetNavAreaByID(1785)
	local fix5_jesusNav_m2 = NavMesh.GetNavAreaByID(1772)
	local fix5_jesusNav_n = NavMesh.GetNavAreaByID(1743)
	local fix5_jesusNav_o = NavMesh.GetNavAreaByID(2018)
	local fix5_jesusNav_o2 = NavMesh.GetNavAreaByID(2059)
	local fix5_jesusNav_p = NavMesh.GetNavAreaByID(1933)
	local fix5_jesusNav_q = NavMesh.GetNavAreaByID(1969)
	local fix5_jesusNav_r = NavMesh.GetNavAreaByID(5745)
	local fix5_jesusNav_r2 = NavMesh.GetNavAreaByID(5744)
	local fix5_jesusNav_r3 = NavMesh.GetNavAreaByID(5742)
	local fix5_jesusNav_r4 = NavMesh.GetNavAreaByID(2027)
	local fix5_jesusNav_s = NavMesh.GetNavAreaByID(5721)
	local fix5_jesusNav_s2 = NavMesh.GetNavAreaByID(5720)
	local fix5_jesusNav_s3 = NavMesh.GetNavAreaByID(5719)
	local fix5_jesusNav_s4 = NavMesh.GetNavAreaByID(5718)
	local fix5_jesusNav_t = NavMesh.GetNavAreaByID(5727)
	local fix5_jesusNav_t2 = NavMesh.GetNavAreaByID(5726)
	local fix5_jesusNav_t3 = NavMesh.GetNavAreaByID(5724)
	local fix5_jesusNav_u = NavMesh.GetNavAreaByID(5735)
	local fix5_jesusNav_u2 = NavMesh.GetNavAreaByID(5734)
	local fix5_jesusNav_u3 = NavMesh.GetNavAreaByID(5733)
	local fix5_jesusNav_u4 = NavMesh.GetNavAreaByID(5732)
	local fix5_jesusNav_v = NavMesh.GetNavAreaByID(643)
	local fix5_jesusNav_v2 = NavMesh.GetNavAreaByID(817)
	local fix5_jesusNav_w = NavMesh.GetNavAreaByID(5738)
	local fix5_jesusNav_w2 = NavMesh.GetNavAreaByID(5739)
	local fix5_jesusNav_w3 = NavMesh.GetNavAreaByID(5736)
	local fix5_jesusNav_w4 = NavMesh.GetNavAreaByID(5737)
	local fix5_jesusNav_x = NavMesh.GetNavAreaByID(1981)
	local fix5_jesusNav_x2 = NavMesh.GetNavAreaByID(1939)
	local fix5_jesusNav_x3 = NavMesh.GetNavAreaByID(1977)
	local fix5_jesusNav_x4 = NavMesh.GetNavAreaByID(1910)
	local fix5_jesusNav_x5 = NavMesh.GetNavAreaByID(1914)
	//Nav areas to connect
	local fix5_nav_a = NavMesh.GetNavAreaByID(272)
	local fix5_nav_b = NavMesh.GetNavAreaByID(231)
	local fix5_nav_c = NavMesh.GetNavAreaByID(332)
	local fix5_nav_c2 = NavMesh.GetNavAreaByID(52)
	local fix5_nav_c3 = NavMesh.GetNavAreaByID(60)
	local fix5_nav_c4 = NavMesh.GetNavAreaByID(1189)
	local fix5_nav_d = NavMesh.GetNavAreaByID(2233)
	local fix5_nav_d2 = NavMesh.GetNavAreaByID(508)
	local fix5_nav_d3 = NavMesh.GetNavAreaByID(2223)
	local fix5_nav_e = NavMesh.GetNavAreaByID(507)
	local fix5_nav_f = NavMesh.GetNavAreaByID(166)
	local fix5_nav_f2 = NavMesh.GetNavAreaByID(6034)
	local fix5_nav_f3 = NavMesh.GetNavAreaByID(267)
	local fix5_nav_f4 = NavMesh.GetNavAreaByID(74)
	local fix5_nav_g = NavMesh.GetNavAreaByID(143)
	local fix5_nav_g2 = NavMesh.GetNavAreaByID(328)
	local fix5_nav_g3 = NavMesh.GetNavAreaByID(120)
	local fix5_nav_h = NavMesh.GetNavAreaByID(823)
	local fix5_nav_h2 = NavMesh.GetNavAreaByID(631)
	local fix5_nav_h3 = NavMesh.GetNavAreaByID(826)
	local fix5_nav_h4 = NavMesh.GetNavAreaByID(650)
	local fix5_nav_i = NavMesh.GetNavAreaByID(1900)
	local fix5_nav_i2 = NavMesh.GetNavAreaByID(1988)
	local fix5_nav_j = NavMesh.GetNavAreaByID(75)
	local fix5_nav_j23 = NavMesh.GetNavAreaByID(421)
	local fix5_nav_j4 = NavMesh.GetNavAreaByID(653)
	local fix5_nav_k = NavMesh.GetNavAreaByID(830)
	local fix5_nav_l = NavMesh.GetNavAreaByID(821)
	local fix5_nav_l2 = NavMesh.GetNavAreaByID(6021)
	local fix5_nav_m = NavMesh.GetNavAreaByID(4)
	local fix5_nav_m2 = NavMesh.GetNavAreaByID(1768)
	local fix5_nav_n = NavMesh.GetNavAreaByID(164)
	local fix5_nav_o = NavMesh.GetNavAreaByID(6028)
	local fix5_nav_o2 = NavMesh.GetNavAreaByID(6029)
	local fix5_nav_o3 = NavMesh.GetNavAreaByID(75)
	local fix5_nav_p = NavMesh.GetNavAreaByID(165)
	local fix5_nav_pq = NavMesh.GetNavAreaByID(420)
	local fix5_nav_r = NavMesh.GetNavAreaByID(5749)
	local fix5_nav_r2 = NavMesh.GetNavAreaByID(5748)
	local fix5_nav_r3 = NavMesh.GetNavAreaByID(2128)
	local fix5_nav_r4 = NavMesh.GetNavAreaByID(269)
	local fix5_nav_s = NavMesh.GetNavAreaByID(636)
	local fix5_nav_s2 = NavMesh.GetNavAreaByID(636)
	local fix5_nav_t = NavMesh.GetNavAreaByID(413)
	local fix5_nav_t2 = NavMesh.GetNavAreaByID(1753)
	local fix5_nav_t3 = NavMesh.GetNavAreaByID(638)
	local fix5_nav_u = NavMesh.GetNavAreaByID(15)
	local fix5_nav_u2 = NavMesh.GetNavAreaByID(6010)
	local fix5_nav_v = NavMesh.GetNavAreaByID(1758)
	local fix5_nav_v2 = NavMesh.GetNavAreaByID(5620)
	local fix5_nav_v3 = NavMesh.GetNavAreaByID(103)
	local fix5_nav_v4 = NavMesh.GetNavAreaByID(500)
	local fix5_nav_w = NavMesh.GetNavAreaByID(419)
	local fix5_nav_w2 = NavMesh.GetNavAreaByID(1902)
	local fix5_nav_w3 = NavMesh.GetNavAreaByID(418)
	local fix5_nav_x = NavMesh.GetNavAreaByID(1971)
	local fix5_nav_x2 = NavMesh.GetNavAreaByID(1979)
	
	//Create one-way connection between nav areas
	fix5_nav_a.ConnectTo(fix5_jesusNav_a,2)
	fix5_jesusNav_a.ConnectTo(fix5_nav_a,0)
	
	fix5_nav_b.ConnectTo(fix5_jesusNav_b,2)
	fix5_jesusNav_b.ConnectTo(fix5_nav_b,0)
	
	fix5_nav_c.ConnectTo(fix5_jesusNav_c,2)
	fix5_jesusNav_c.ConnectTo(fix5_nav_c,0)
	fix5_nav_c2.ConnectTo(fix5_jesusNav_c2,1)
	fix5_jesusNav_c2.ConnectTo(fix5_nav_c2,3)
	fix5_nav_c3.ConnectTo(fix5_jesusNav_c3,0)
	fix5_jesusNav_c3.ConnectTo(fix5_nav_c3,2)
	fix5_nav_c4.ConnectTo(fix5_jesusNav_c4,3)
	fix5_jesusNav_c4.ConnectTo(fix5_nav_c4,1)
	
	fix5_nav_d.ConnectTo(fix5_jesusNav_d,2)
	fix5_jesusNav_d.ConnectTo(fix5_nav_d,0)
	fix5_nav_d2.ConnectTo(fix5_jesusNav_d,1)
	fix5_jesusNav_d.ConnectTo(fix5_nav_d2,3)
	fix5_nav_d3.ConnectTo(fix5_jesusNav_d,0)
	fix5_jesusNav_d.ConnectTo(fix5_nav_d3,2)
	
	fix5_nav_e.ConnectTo(fix5_jesusNav_e,0)
	fix5_jesusNav_e.ConnectTo(fix5_nav_e,2)
	
	fix5_nav_f.ConnectTo(fix5_jesusNav_f,3)
	fix5_jesusNav_f.ConnectTo(fix5_nav_f,1)
	fix5_nav_f2.ConnectTo(fix5_jesusNav_f,3)
	fix5_jesusNav_f.ConnectTo(fix5_nav_f2,1)
	fix5_nav_f2.ConnectTo(fix5_jesusNav_f,3)
	fix5_jesusNav_f.ConnectTo(fix5_nav_f2,1)
	fix5_nav_f3.ConnectTo(fix5_jesusNav_f,1)
	fix5_jesusNav_f.ConnectTo(fix5_nav_f3,3)
	fix5_nav_f.ConnectTo(fix5_jesusNav_f2,3)
	fix5_nav_f4.ConnectTo(fix5_jesusNav_f2,0)
	
	fix5_nav_g.ConnectTo(fix5_jesusNav_g,2)
	fix5_jesusNav_g.ConnectTo(fix5_nav_g,0)
	fix5_nav_g2.ConnectTo(fix5_jesusNav_g,3)
	fix5_jesusNav_g.ConnectTo(fix5_nav_g2,1)
	fix5_nav_g3.ConnectTo(fix5_jesusNav_g,0)
	fix5_jesusNav_g.ConnectTo(fix5_nav_g3,2)
	
	fix5_nav_h.ConnectTo(fix5_jesusNav_h,2)
	fix5_jesusNav_h.ConnectTo(fix5_nav_h,0)
	fix5_nav_h2.ConnectTo(fix5_jesusNav_h2,1)
	fix5_jesusNav_h2.ConnectTo(fix5_nav_h2,3)
	fix5_nav_h3.ConnectTo(fix5_jesusNav_h3,0)
	fix5_jesusNav_h3.ConnectTo(fix5_nav_h3,2)
	fix5_nav_h4.ConnectTo(fix5_jesusNav_h4,3)
	fix5_jesusNav_h4.ConnectTo(fix5_nav_h4,1)
	
	fix5_nav_i.ConnectTo(fix5_jesusNav_i,1)
	fix5_jesusNav_i.ConnectTo(fix5_nav_i,3)
	fix5_nav_i2.ConnectTo(fix5_jesusNav_i,2)
	fix5_jesusNav_i.ConnectTo(fix5_nav_i2,0)
	
	fix5_nav_j.ConnectTo(fix5_jesusNav_j,0)
	fix5_nav_j23.ConnectTo(fix5_jesusNav_j2,0)
	fix5_nav_j23.ConnectTo(fix5_jesusNav_j3,0)
	fix5_nav_j4.ConnectTo(fix5_jesusNav_j4,2)
	fix5_jesusNav_j4.ConnectTo(fix5_nav_j4,0)
	
	fix5_nav_k.ConnectTo(fix5_jesusNav_k,0)
	fix5_jesusNav_k.ConnectTo(fix5_nav_k,2)
	
	fix5_nav_l.ConnectTo(fix5_jesusNav_l,3)
	fix5_jesusNav_l.ConnectTo(fix5_nav_l,1)
	fix5_nav_l2.ConnectTo(fix5_jesusNav_l2,0)
	fix5_jesusNav_l2.ConnectTo(fix5_nav_l2,2)
	
	fix5_nav_m.ConnectTo(fix5_jesusNav_m,2)
	fix5_jesusNav_m.ConnectTo(fix5_nav_m,0)
	fix5_nav_m2.ConnectTo(fix5_jesusNav_m2,0)
	fix5_jesusNav_m2.ConnectTo(fix5_nav_m2,2)
	
	fix5_nav_n.ConnectTo(fix5_jesusNav_n,3)
	fix5_jesusNav_n.ConnectTo(fix5_nav_n,1)
	
	fix5_nav_h3.ConnectTo(fix5_jesusNav_o,2)
	fix5_nav_o.ConnectTo(fix5_jesusNav_o,0)
	fix5_nav_o2.ConnectTo(fix5_jesusNav_o,0)
	fix5_nav_h3.ConnectTo(fix5_jesusNav_o2,2)
	fix5_nav_o2.ConnectTo(fix5_jesusNav_o2,0)
	fix5_nav_o3.ConnectTo(fix5_jesusNav_o2,3)
	
	fix5_nav_p.ConnectTo(fix5_jesusNav_p,1)
	fix5_jesusNav_p.ConnectTo(fix5_nav_p,3)
	fix5_nav_pq.ConnectTo(fix5_jesusNav_p,2)
	fix5_jesusNav_p.ConnectTo(fix5_nav_pq,0)
	
	fix5_nav_pq.ConnectTo(fix5_jesusNav_q,1)
	fix5_jesusNav_q.ConnectTo(fix5_nav_pq,3)
	
	fix5_nav_h.ConnectTo(fix5_jesusNav_r,0)
	fix5_nav_r.ConnectTo(fix5_jesusNav_r,3)
	fix5_nav_r2.ConnectTo(fix5_jesusNav_r2,3)
	fix5_nav_r3.ConnectTo(fix5_jesusNav_r3,3)
	fix5_nav_r4.ConnectTo(fix5_jesusNav_r3,3)
	fix5_nav_r4.ConnectTo(fix5_jesusNav_r4,3)
	
	fix5_nav_s.ConnectTo(fix5_jesusNav_s,0)
	fix5_nav_m.ConnectTo(fix5_jesusNav_s,3)
	fix5_nav_m.ConnectTo(fix5_jesusNav_s2,3)
	fix5_nav_m.ConnectTo(fix5_jesusNav_s3,3)
	fix5_nav_m.ConnectTo(fix5_jesusNav_s4,3)
	
	fix5_nav_t.ConnectTo(fix5_jesusNav_t,3)
	fix5_nav_t.ConnectTo(fix5_jesusNav_t2,3)
	fix5_nav_t2.ConnectTo(fix5_jesusNav_t2,3)
	fix5_nav_t3.ConnectTo(fix5_jesusNav_t3,2)
	
	fix5_nav_t3.ConnectTo(fix5_jesusNav_u,0)
	fix5_nav_u.ConnectTo(fix5_jesusNav_u,3)
	fix5_nav_u.ConnectTo(fix5_jesusNav_u2,3)
	fix5_nav_u.ConnectTo(fix5_jesusNav_u3,3)
	fix5_nav_u.ConnectTo(fix5_jesusNav_u4,3)
	fix5_nav_u2.ConnectTo(fix5_jesusNav_u4,3)
	
	fix5_nav_n.ConnectTo(fix5_jesusNav_v,0)
	fix5_nav_t.ConnectTo(fix5_jesusNav_v,1)
	fix5_nav_v.ConnectTo(fix5_jesusNav_v,1)
	fix5_nav_v2.ConnectTo(fix5_jesusNav_v,1)
	fix5_nav_v3.ConnectTo(fix5_jesusNav_v,3)
	fix5_nav_v3.ConnectTo(fix5_jesusNav_v2,3)
	fix5_nav_v4.ConnectTo(fix5_jesusNav_v2,2)
	
	fix5_nav_p.ConnectTo(fix5_jesusNav_w,1)
	fix5_nav_w.ConnectTo(fix5_jesusNav_w,3)
	fix5_nav_p.ConnectTo(fix5_jesusNav_w2,1)
	fix5_nav_w.ConnectTo(fix5_jesusNav_w2,3)
	
	fix5_nav_m.ConnectTo(fix5_jesusNav_w3,1)
	fix5_nav_m.ConnectTo(fix5_jesusNav_w4,1)
	fix5_nav_w2.ConnectTo(fix5_jesusNav_w3,3)
	fix5_nav_w3.ConnectTo(fix5_jesusNav_w3,3)
	fix5_nav_w3.ConnectTo(fix5_jesusNav_w4,3)
	
	fix5_nav_x.ConnectTo(fix5_jesusNav_x,3)
	fix5_nav_x2.ConnectTo(fix5_jesusNav_x2,3)
	fix5_nav_x2.ConnectTo(fix5_jesusNav_x3,0)
	fix5_nav_v3.ConnectTo(fix5_jesusNav_x4,0)
	fix5_jesusNav_x4.ConnectTo(fix5_nav_v3,2)
	fix5_nav_u.ConnectTo(fix5_jesusNav_x5,1)
	fix5_jesusNav_x5.ConnectTo(fix5_nav_u,3)
	
	printl("\n[NavFixes] Fix 5 applied\n")
}

//Fix 6: Fix jesus spots in warehouse room behind kiddyland//
//Issue: Nav area has no / one way connections, making it impossible for common to path
function l4d_dbd2dc_clean_up_navfixes_fix6()
{
	//Get nav areas:
	//Problematic nav areas
	local fix6_jesusNav_a = NavMesh.GetNavAreaByID(637)
	local fix6_jesusNav_b = NavMesh.GetNavAreaByID(813)
	local fix6_jesusNav_c = NavMesh.GetNavAreaByID(1724)
	local fix6_jesusNav_d = NavMesh.GetNavAreaByID(1119)
	//Nav areas to connect
	local fix6_nav_a = NavMesh.GetNavAreaByID(102)
	local fix6_nav_a2 = NavMesh.GetNavAreaByID(499)
	local fix6_nav_bc = NavMesh.GetNavAreaByID(163)
	local fix6_nav_d = NavMesh.GetNavAreaByID(264)
	
	//Create one-way connection between nav areas
	fix6_nav_a.ConnectTo(fix6_jesusNav_a,3)
	fix6_nav_a2.ConnectTo(fix6_jesusNav_a,0)
	
	fix6_nav_bc.ConnectTo(fix6_jesusNav_b,0)
	
	fix6_nav_bc.ConnectTo(fix6_jesusNav_c,2)
	fix6_jesusNav_c.ConnectTo(fix6_nav_bc,0)
	
	fix6_nav_d.ConnectTo(fix6_jesusNav_d,2)
	fix6_jesusNav_d.ConnectTo(fix6_nav_d,0)
	
	printl("\n[NavFixes] Fix 6 applied\n")
}


l4d_dbd2dc_clean_up_navfixes_fix1()
l4d_dbd2dc_clean_up_navfixes_fix2()
l4d_dbd2dc_clean_up_navfixes_fix3()
l4d_dbd2dc_clean_up_navfixes_fix4()
l4d_dbd2dc_clean_up_navfixes_fix5()
l4d_dbd2dc_clean_up_navfixes_fix6()