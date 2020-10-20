printl( "VSCRIPT: Running anv_versus.nut" );

/*****************************************************************************
**  This file is RunScriptFile'd on "worldspawn" by anv_mapfixes.nut and contains
**  all Versus-specific content which only spawns if HasPlayerControlledZombies()
**  is true. Includes new Infected ladders and any supporting props i.e. pipes.
*****************************************************************************/

// Only run if it's Versus and not Taaannnk!! Mutation. Instantly warps
// Tanks that spawn unreasonably far away from Survivors or exposed.
// Note this runs even for all "COMMUNITY" maps and other Mutations so
// requires unique scope to not overwrite their "tank_spawn" events.
// Needs to run for both rounds or else both teams won't get warped.

if ( g_BaseMode == "versus" && g_MutaMode != "mutation19" )
{
	EntFire( "worldspawn", "RunScriptFile", "anv_tankwarps" );
}

// Map fixes for Valve.
// Dev Thread: https://steamcommunity.com/app/550/discussions/1/1651043320659915818/

switch( g_MapName )
{
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*==============================
||                            ||
||        DEAD CENTER         ||
||                            ||
==============================*/

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c1m1_hotel":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

// Simulates getting squished. Requires 2 Ghost Infected constantly stuck-warping.

con_comment( "LOGIC:\tAnti-doorbreak trighurt will be deleted 4 seconds after elevator starts." );

make_trighurt( "_elevator_exploit_bean", "Ghost", "-55 -2 0", "55 2 111", "2169 5713 2352" );
EntFire( "elevator_button", "AddOutput", "OnPressed anv_mapfixes_elevator_exploit_bean:Kill::4:-1" );

con_comment( "QOL:\tThe 2nd fire door is open immediately for Versus-only QoL." );

DoEntFire( "!self", "Break", "", 0.0, null, Entities.FindByClassnameNearest( "prop_door_rotating", Vector( 1828, 6620, 2464 ), 1 ) );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c1m2_streets":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

kill_funcinfclip( 1112.27 );	// Delete clip that's long and covers most wrongway signs
kill_funcinfclip( 777.979 );	// Delete clip along same way but off to the right side
kill_funcinfclip( 545.427 );	// Delete clip of chokepoint building's front side
kill_funcinfclip( 538.073 );	// Delete clip of chokepoint building's right side
kill_funcinfclip( 502.461 );	// Delete clip of chokepoint building's back side
kill_funcinfclip( 579.319 );	// Delete clip directly above wrongway signs
kill_funcinfclip( 790.065 );	// Delete clip to the right that'd block new vine ladder up
make_atomizer( "_atomizer_bsp_dumpster", "-7475 -4582 384", "models/props_junk/dumpster_2.mdl", 60 );
make_brush( "_losfix_backstreet_van",	"-1 -64 -10",	"1 64 10",	"-2182 687 9" );
make_brush( "_losfix_endstreet_bus",	"-1 -28 -12",	"1 60 12",	"-8352 -2283 395" );
make_brush( "_losfix_endstreet_fence",	"-1 -616 -5",	"1 616 5",	"-7071 -3944 389" );
make_brush( "_losfix_endstreet_gen1",	"-1 -25 -9",	"1 25 9",	"-7143 -4150 393" );
make_brush( "_losfix_endstreet_gen2",	"-1 -26 -9",	"1 26 9",	"-8699 -4013 393" );
make_brush( "_losfix_endstreet_van",	"-90 -1 -10",	"90 1 10",	"-7893 -2305 394" );
make_brush( "_losfix_sidestreet_van1",	"-35 -2 -10",	"35 2 10",	"-1209 3992 131" );
make_brush( "_losfix_sidestreet_van2",	"-2 -62 -10",	"2 62 10",	"-1180 4061 132" );
make_brush( "_losfix_sidestreet_van3",	"-35 -2 -10",	"35 2 10",	"-1162 4126 138" );
make_brush( "_losfix_skybridge_bus",	"-45 -1 -13",	"61 1 13",	"-5310 -609 460" );
make_brush( "_losfix_stairs_gen1",	"-1 -20 -8",	"1 20 8",	"-4974 1669 392" );
make_brush( "_losfix_stairs_gen2",	"-18 -1 -8",	"19 1 8",	"-4994 1651 392" );
make_brush( "_losfix_starting_truck",	"-100 -1 0",	"190 1 30",	"1165 2493 571.5" );
make_brush( "_losfix_tanker1",		"-4 -72 -60",	"4 72 60",	"-6939 -1040 444" );
make_brush( "_losfix_tanker2",		"-48 -4 -20",	"48 4 60",	"-6894 -964 444" );
make_brush( "_losfix_tanker3",		"-4 -72 -20",	"4 72 60",	"-6844 -888 444" );
make_brush( "_losfix_tanker4",		"-43 -4 -20",	"43 4 60",	"-6797 -820 444" );
make_brush( "_losfix_tanker5",		"-4 -15 -20",	"4 15 60",	"-6753 -801 444" );
make_brush( "_losfix_tanker6",		"-4 -50 -60",	"4 80 60",	"-6753 -736 444" );
make_brush( "_losfix_tanker7",		"-48 -4 -60",	"48 4 60",	"-6675 -619 444" );
make_brush( "_losfix_tanker8",		"-4 -36 -60",	"4 36 60",	"-6631 -579 444" );
make_brush( "_losfix_tanker9",		"-4 -38 -40",	"4 38 40",	"-6623 -505 426" );
make_clip( "_clipgap_deadendfence", "SI Players", 1, "-129 -7 -32", "145 7 32", "-1168 5160 383" );
make_clip( "_ladder_copvines_clip", "SI Players", 1, "-16 -12 -2", "16 32 0", "-284 3211 719", "0 0 37" );
make_clip( "_ladder_endbillboard_clipB", "SI Players", 1, "-5 -16 -10", "5 16 21", "-7470 -150 696", "0 -18 0" );
make_clip( "_ladder_endbillboard_clipT", "SI Players", 1, "-5 -16 -10", "5 16 21", "-7471 -150 714", "0 -18 0" );
make_clip( "_ladder_saferoomperch_clip", "Everyone", 1, "-18 -7 0", "14 9 288", "-8190 -4353 384" );
make_clip( "_ladder_tankhedge_jumpclip", "SI Players", 1, "-404 1 0", "428 2 46", "2644 3327 640" );
make_clip( "_ladderqol_railingtop", "SI Players", 1, "-266 -1 -12", "758 4 18", "-2614 2318 348" );
make_clip( "_ladderqol_railleftbot", "SI Players", 1, "-125 -1 0", "134 0 48", "-1154 2322 320" );
make_clip( "_ladderqol_raillefttop", "SI Players", 1, "-125 -1 0", "134 0 30", "-1154 2321 368" );
make_clip( "_skybridgebus_clip", "SI Players", 1, "-30 -95 -20", "20 48 45", "-5164 -485 595" );
make_clip( "_sneaky_hunter", "SI Players", 1, "-25 -142 0", "55 114 448", "-9207 -4402 1024" );
make_clip( "_yeswaychoke_clip", "SI Players", 1, "-275 -12 0", "251 240 945", "-3636 1800 523" );
make_clip( "_yeswaycorner_clip", "SI Players", 1, "-8 -512 0", "8 256 1472", "3703 2048 704" );
make_clip( "_yeswayturnpike_clipa", "SI Players", 1, "-128 -512 0", "128 512 768", "-384 512 704" );
make_clip( "_yeswayturnpike_clipb", "SI Players", 1, "-620 -8 -64", "620 8 1016", "-876 48 456" );
make_ladder( "_ladder_acbuildfront_cloned_acbuildside", "-6524 510 576", "-5059 7184 0", "0 90 0", "1 0 0" );
make_ladder( "_ladder_copfenceright_cloned_copfenceleft", "-1002 2368 391.5", "8 450 0" );
make_ladder( "_ladder_copvines_cloned_startvines", "2136 4926 600", "-2420 -1725 -35" );
make_ladder( "_ladder_dumpsterfront_cloned_dumpsterback", "-4845 -1167 494", "-9818 -2332 0", "0 -180 0", "-1 0 0" );
make_ladder( "_ladder_dynamictanker_cloned_roundthehedge", "-7554 -1280 500", "-5913 -8705 0", "0 -90 0", "0 1 0" );
make_ladder( "_ladder_endbillboardB_cloned_save4lessleft", "-6704 -2754 536", "-729 2611 -89" );
make_ladder( "_ladder_endbillboardT_cloned_save4lessright", "-6864 -2238 536", "-6642.5 -6636.1 -2475.7", "24 -103 3", "1 -0.08 0" );
make_ladder( "_ladder_endfence_cloned_carthedge", "-6034 -2592 480", "-1040 -1456 -47" );
make_ladder( "_ladder_endfenceconcrete_cloned_endvanconcrete", "-7554 -2048 500", "-9200 4227 0", "0 90 0", "0 -1 0" );
make_ladder( "_ladder_fencedinplatform_cloned_longfencefarleft", "1728 2306 649", "-2305 3724 -18", "0 -90 0", "1 0 0" );
make_ladder( "_ladder_hedgesreturn_cloned_skystairsback", "-5488 -878 514", "-10775 -1021 0", "0 180 0", "0 -1 0" );
make_ladder( "_ladder_longfencefarright_cloned_longfencefarleft", "1728 2306 649", "-900 -5 -16" );
make_ladder( "_ladder_oneway_cloned_stairsbus", "-2800 1182 66", "-1680 1129 364" );
make_ladder( "_ladder_overpassleft_cloned_overpassright", "-1920 2322 333.5", "508 0 23" );
make_ladder( "_ladder_postdropcut_cloned_turnpikemid", "-1026 1280 256", "-5147 3002 0", "0 165 0", "0.96 -0.26 0" );
make_ladder( "_ladder_saferoomperch_cloned_save4less", "-6864 -2238 536", "-1328 -2107 -8" );
make_ladder( "_ladder_saferoomperchoob_cloned_save4less", "-6864 -2238 536", "-176 -2107 -8" );
make_ladder( "_ladder_skybridgebus_cloned_endbusright", "-8406 -2272 449", "1578 -5868 64", "0 -53 0", "-0.6 0.8 0" );
make_ladder( "_ladder_skybridgechance_cloned_yellowbrickcones", "-5526 -1200 521", "334 1154 217" );
make_ladder( "_ladder_skybridgedodge_cloned_yellowbrickcones", "-5526 -1200 521", "334 137 217" );
make_ladder( "_ladder_skybridgestains_cloned_endslopeleft", "-1002 2368 391.5", "-6972 -873 -83", "0 -76 0", "0.18 -0.98 0" );
make_ladder( "_ladder_skystairsfront_cloned_skystairsback", "-5488 -878 514", "-10875 -1773 0", "0 180 0", "0 -1 0" );
make_ladder( "_ladder_slopeleftvine_cloned_save4lessright", "-6864 -2238 536", "6808 4541 24" );
make_ladder( "_ladder_stairvines_cloned_dumpstervines", "-2064 2302 205.5", "-973 3 3" );
make_ladder( "_ladder_startareavines_cloned_dumpsterright", "-2064 2302 205.5", "3133 6469 453", "0 90 0", "1 0 0" );
make_ladder( "_ladder_startfencefar_cloned_startfenceback", "2446 4732 518", "119 -850 77" );
make_ladder( "_ladder_startfencefront_cloned_startfenceback", "2446 4732 518", "4873 9426 0", "0 180 0", "-1 0 0" );
make_ladder( "_ladder_starthedgesfront_cloned_starthedgesback", "738 3376 687", "1536 6993 0", "0 180 0", "1 0 0" );
make_ladder( "_ladder_tankerfrontleft_cloned_tankerfenceleft", "-5808 -126 510", "-12063 -269 -5", "0 180 0", "0 -1 0" );
make_ladder( "_ladder_tankerfrontmid_cloned_tankerfencemid", "-6032 -126 510", "-12063 -269 -5", "0 180 0", "0 -1 0" );
make_ladder( "_ladder_tankerfrontright_cloned_tankerfenceright", "-6288 -126 506", "-12063 -269 -5", "0 180 0", "0 -1 0" );
make_ladder( "_ladder_tankhedge_cloned_stairsbus", "-2800 1182 66", "5389 2072 572" );
make_ladder( "_ladder_tentbus_cloned_stairsbus", "-2800 1182 66", "1786 5841 570", "0 120 0", "0.87 0.5 0" );
make_ladder( "_ladder_truckandtent_cloned_carthedge", "-6034 -2592 480", "-1460 8465 153", "0 90 0", "0 -1 0" );
make_ladder( "_ladder_turnpikeleft_cloned_turnpikemid", "-1026 1280 256", "3 780 0" );
make_ladder( "_ladder_turnpikeright_cloned_turnpikemid", "-1026 1280 256", "-1052 -1275 -41", "0 -27.42 0", "-0.89 0.46 0" );
make_ladder( "_ladder_whitakerback_cloned_tinyendladder", "-7168 -2754 650", "2020 579 128" );
make_ladder( "_ladder_whitakergunshop_cloned_eventicemachine", "-5506 -2564 544", "-2400 -7165 172", "0 -90 0", "0 1 0" );
make_ladder( "_ladder_whitakerquick_cloned_hedgeparklot", "-6034 -2256 476", "723.9 196 233" );
make_ladder( "_ladder_yeswaychokefence_cloned_yellowbrickcones", "-5526 -1200 521", "2391 2893 -400" );
make_ladder( "_ladder_yeswaychokeroof_cloned_tankerfencemid", "-6032 -126 510", "2384 2428.1 -70" );
make_ladder( "_ladder_yeswaycornerinner_cloned_roundthehedge", "-7554 -1280 500", "9600 3329 136" );
make_ladder( "_ladder_yeswaycornerouter_cloned_save4lessright", "-6864 -2238 536", "9427 4543.1 72" );
make_ladder( "_ladder_yeswayturnpikesign_cloned_turnpikemid", "-1026 1280 256", "-1936 2051 396", "0 180 0", "1 0 0" );
make_prop( "dynamic",		"_propladder_blocka",		"models/props_fortifications/concrete_block001_128_reference.mdl",	"-2296 2341 288",		"0 270 0",		"shadow_no" );
make_prop( "dynamic",		"_propladder_blockb",		"models/props_fortifications/concrete_block001_128_reference.mdl",	"-2426 2341 287",		"0 270 0",		"shadow_no" );
make_prop( "dynamic",		"_propladder_blockc",		"models/props_fortifications/concrete_block001_128_reference.mdl",	"-2816 2340 288",		"0 270 0",		"shadow_no" );
make_prop( "dynamic",		"_propladder_blockd",		"models/props_fortifications/concrete_block001_128_reference.mdl",	"-2946 2339 289",		"0 270 -2.5",		"shadow_no" );
make_prop( "dynamic",		"_propladder_blocke",		"models/props_fortifications/concrete_block001_128_reference.mdl",	"-3076 2339 295",		"0 270 -3.5",		"shadow_no" );
make_prop( "dynamic",		"_propladder_blockf",		"models/props_fortifications/concrete_block001_128_reference.mdl",	"-3203 2339 302",		"0 270 -2",		"shadow_no" );
make_prop( "dynamic", "_endbillboard_crashedvan", "models/props_vehicles/van_interior.mdl", "-7350 0 400", "12 120 8" );
make_prop( "dynamic", "_endbillboard_streetlight", "models/props_urban/streetlight001.mdl", "-7434 -95 370", "-23 90 -8", "shadow_no" );
make_prop( "dynamic", "_endbillboard_wrongway", "models/props_misc/wrongway_sign01_optimized.mdl", "-7622 -143 824", "0 -90 0", "shadow_no", "solid_no", "255 255 255", 217, 17 );
make_prop( "dynamic", "_losblocker_skybridgebus", "models/props_vehicles/bus01_2.mdl", "-5180 -508 447", "0 37 0" );
make_prop( "dynamic", "_propladder_endplywood1", "models/props_highway/plywood_01.mdl", "-7018.5 -3914 471.5", "45 0 0", "shadow_no" );
make_prop( "dynamic", "_propladder_endplywood2", "models/props_highway/plywood_01.mdl", "-7069.5 -3818 522.5", "-45 180 0", "shadow_no" );
make_prop( "dynamic", "_propladder_endvan", "models/props_vehicles/van.mdl", "-7003 -3900 383", "0 182 0" );
make_prop( "dynamic", "_propladder_endvanglass", "models/props_vehicles/van_glass.mdl", "-7003 -3900 383", "0 182 0", "shadow_no" );
make_prop( "dynamic", "_propladder_whitakergunshop_plywood", "models/props_highway/plywood_03.mdl", "-4798 -1600 623", "-41 270 0", "shadow_no" );
make_prop( "dynamic", "_yesdraw_disproof_hunt1", "models/props_update/c8m1_rooftop_1.mdl", "-6032 1264 1344", "0 0 0", "shadow_no" );
make_prop( "dynamic", "_yesdraw_disproof_hunt2", "models/props_update/c8m1_rooftop_1.mdl", "-6032 1744 1344", "0 0 0", "shadow_no" );
make_prop( "dynamic", "_yesdraw_disproof_hunt3", "models/props_update/c8m1_rooftop_3.mdl", "-5280 1264 1344", "0 0 0", "shadow_no" );
make_prop( "dynamic", "_yesdraw_disproof_hunt4", "models/props_update/c8m1_rooftop_3.mdl", "-5280 1744 1344", "0 0 0", "shadow_no" );
make_prop( "dynamic", "_yesdraw_skybroof_hunt1", "models/props_update/c8m1_rooftop_1.mdl", "-4368 3312 1728", "0 0 0", "shadow_no" );
make_prop( "dynamic", "_yesdraw_skybroof_hunt2", "models/props_update/c8m1_rooftop_3.mdl", "-3616 3312 1728", "0 0 0", "shadow_no" );
make_prop( "dynamic", "_yeswaychoke_fence1", "models/props_urban/fence_cover001_128.mdl", "-3870 1887 512", "0 0 0", "shadow_no" );
make_prop( "dynamic", "_yeswaychoke_fence2", "models/props_urban/fence_cover001_64.mdl", "-3870 1983 512", "0 0 0", "shadow_no" );
make_prop( "dynamic", "_yeswaychoke_roof1", "models/props_update/c1m2_wrongway_rooftop1.mdl", "-3900 2044 532", "0 0 0", "shadow_no" );
make_prop( "dynamic", "_yeswaychoke_roof2", "models/props_update/c1m2_wrongway_rooftop2.mdl", "-3652 2052 532", "0 0 0", "shadow_no" );
make_prop( "dynamic", "_yeswaychoke_wrongwaya", "models/props_misc/wrongway_sign01_optimized.mdl", "-3538 2042 574", "0 90 0", "shadow_no", "solid_no", "255 255 255", 300, 17 );
make_prop( "dynamic", "_yeswaychoke_wrongwayb", "models/props_misc/wrongway_sign01_optimized.mdl", "-3648 2042 574", "0 90 0", "shadow_no", "solid_no", "255 255 255", 300, 17 );
make_prop( "dynamic", "_yeswaychoke_wrongwayc", "models/props_misc/wrongway_sign01_optimized.mdl", "-3758 2042 574", "0 90 0", "shadow_no", "solid_no", "255 255 255", 300, 17 );
make_prop( "dynamic", "_yeswaycorner_wall", "models/props_update/c1m2_wrongway_wall.mdl", "3072 2048 608", "0 270 0", "shadow_no" );
make_prop( "dynamic", "_yeswaycorner_wrongway", "models/props_misc/wrongway_sign01_optimized.mdl", "3703 2048 768", "0 180 0", "shadow_no", "solid_no", "255 255 255", 217, 17 );
make_prop( "dynamic", "_yeswayturnpike_hedgea", "models/props_foliage/urban_hedge_256_128_high.mdl", "-599 1037 502", "-22 0 0", "shadow_no" );
make_prop( "dynamic", "_yeswayturnpike_hedgeb", "models/props_foliage/urban_hedge_256_128_high.mdl", "-860 1037 426", "0 0 0", "shadow_no" );
make_prop( "dynamic", "_yeswayturnpike_wrongwaya", "models/props_misc/wrongway_sign01_optimized.mdl", "-816 32 496", "0 90 0", "shadow_no", "solid_no", "255 255 255", 217, 17 );
make_prop( "dynamic", "_yeswayturnpike_wrongwayb", "models/props_misc/wrongway_sign01_optimized.mdl", "-1200 32 496", "0 90 0", "shadow_no", "solid_no", "255 255 255", 217, 17 );
patch_ladder( "-5168 162.0004 448", "0 -4 0" );
patch_ladder( "-7200 -126 506", "0 0 -1000" );
patch_ladder( "-7440 -126 510", "0 0 -1000" );
patch_ladder( "-7968 -126 510", "0 0 -1000" );
patch_ladder( "-8224 -126 510", "0 0 -1000" );

con_comment( "LOGIC:\tLOS tanker fixes will be deleted upon its destruction." );

EntFire( "tanker_destruction_relay", "AddOutput", "OnTrigger anv_mapfixes_losfix_tanker*:Kill::0:-1" );

con_comment( "FIX/ANTI-GRIEF:\tRemoved trigger which disables common infected spawns in Save 4 Less area for Versus only." );
kill_entity( Entities.FindByClassnameNearest( "trigger_once", Vector( -5128, -992, 548 ), 1 ) );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c1m3_mall":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

kill_entity( Entities.FindByClassnameNearest( "func_breakable", Vector( -1016.5, -4510.5, 561 ), 1 ) );
kill_entity( Entities.FindByClassnameNearest( "func_breakable", Vector( -1155.47, -4510.5, 561 ), 1 ) );
kill_entity( Entities.FindByClassnameNearest( "func_breakable", Vector( -1400.5, -4510.5, 561 ), 1 ) );
kill_entity( Entities.FindByClassnameNearest( "func_breakable", Vector( 2558.5, -408.5, 561 ), 1 ) );
kill_entity( Entities.FindByClassnameNearest( "func_breakable", Vector( 3964.5, -2910.5, 561 ), 1 ) );
kill_entity( Entities.FindByClassnameNearest( "func_breakable", Vector( 4099.47, -2337.5, 561 ), 1 ) );
kill_entity( Entities.FindByClassnameNearest( "func_breakable", Vector( 4103.5, -2910.5, 561 ), 1 ) );
kill_entity( Entities.FindByClassnameNearest( "func_breakable", Vector( 4344.5, -2337.5, 561 ), 1 ) );
kill_entity( Entities.FindByClassnameNearest( "func_breakable", Vector( 4348.54, -2910.5, 561 ), 1 ) );
kill_entity( Entities.FindByClassnameNearest( "func_breakable", Vector( 4483.47, -2337.5, 561 ), 1 ) );
kill_entity( Entities.FindByClassnameNearest( "func_breakable", Vector( 4487.5, -2910.5, 561 ), 1 ) );
make_brush( "_losfix_end_gen",		"-28 -1 -8",	"28 1 8",	"-1940 -4434 544" );
make_clip( "_ladderqol_lastroom_left", "SI Players", 1, "-564 -3 -31", "564 3 31", "-1280 -4503 509" );
make_clip( "_ladderqol_lastroom_right", "SI Players", 1, "-564 -3 -31", "564 3 31", "-1280 -3945 509" );
make_clip( "_ladderqol_maproom_left", "SI Players", 1, "-564 -3 -31", "564 3 31", "4224 -2903 509" );
make_clip( "_ladderqol_maproom_right", "SI Players", 1, "-564 -3 -31", "564 3 31", "4224 -2345 509" );
make_clip( "_ladderqol_oneway_left", "SI Players", 1, "-3 -564 -31", "3 564 31", "1993 -672 509" );
make_clip( "_ladderqol_oneway_right", "SI Players", 1, "-3 -564 -31", "3 564 31", "2551 -672 509" );
make_clip( "_skylighta_blocker1", "SI Players", 1, "-278 -246 0", "-268 246 172", "6463 -2592 586" );
make_clip( "_skylighta_blocker2", "SI Players", 1, "262 -246 0", "272 246 172", "6463 -2592 586" );
make_clip( "_skylighta_blocker3", "SI Players", 1, "-278 -246 0", "272 -236 172", "6463 -2592 586" );
make_clip( "_skylighta_blocker4", "SI Players", 1, "-278 236 0", "272 246 172", "6463 -2592 586" );
make_ladder( "_ladder_kappels_cloned_headroomvent", "612 -947 308", "7484 -2035.7 -148", "0 -90 0", "1 0 0" );
make_ladder( "_ladder_lastroomSE_cloned_lastroomNE", "-1088 -4498.48 456", "-2176 -8448 0", "0 180 0", "0 -1 0" );
make_ladder( "_ladder_lastroomSW_cloned_lastroomNW", "-1472 -4498.48 456", "-2944 -8448 0", "0 180 0", "0 -1 0" );
make_ladder( "_ladder_maproomNE_cloned_onewayNW", "1997.48 -864 504", "3552 -4896 0", "0 90 0", "0 1 0" );
make_ladder( "_ladder_maproomNW_cloned_onewaySW", "1997.48 -480 504", "3552 -4896 0", "0 90 0", "0 1 0" );
make_ladder( "_ladder_maproomSE_cloned_onewayNE", "2546.48 -864 504", "3552 -4896 0", "0 90 0", "0 -1 0" );
make_ladder( "_ladder_maproomSW_cloned_onewaySE", "2546.48 -480 504", "3552 -4896 0", "0 90 0", "0 -1 0" );
make_ladder( "_ladder_scaffold_cloned_sodavent", "754 -1300 351", "-895 -3732 -25" );
make_ladder( "_ladder_toystoreceiling_cloned_ventexcessheight", "1726.36 -2531.13 299", "3799 -586 173", "0 -90 0", "-0.7 -0.7 0" );
make_prop( "dynamic", "_cosmetic_breakwall1", "models/props_interiors/breakwall_interior_noboards.mdl", "238.1 -2505.6 344", "0 -45 0", "shadow_no", "solid_no" );
make_prop( "dynamic", "_cosmetic_breakwall2", "models/props_interiors/breakwall_interior_noboards.mdl", "236.9 -2504.9 348", "0 -225 0", "shadow_no", "solid_no" );
make_prop( "dynamic", "_ladder_toyvent1", "models/props_exteriors/guardshack_break07.mdl", "1271 -2310 431", "0 315 -95", "shadow_no", "solid_no" );
make_prop( "dynamic", "_ladder_toyvent2", "models/props_exteriors/guardshack_break07.mdl", "1279 -2304 518", "0 300 85", "shadow_no", "solid_no" );
make_prop( "dynamic", "_ladder_toyvent3", "models/props_exteriors/guardshack_break02.mdl", "1158 -2421 554", "0 125 0", "shadow_no", "solid_no" );
make_prop( "dynamic", "_ladder_toyvent4", "models/props_vents/vent_cluster006.mdl", "1412 -2172 560.35", "0 315 0", "shadow_no" );
make_prop( "dynamic", "_ladder_toyvent5", "models/props_vents/vent_cluster006.mdl", "1043 -2538 561", "0 315 0", "shadow_no" );
make_trigmove( "_duckqol_justforkidz", "Duck", "-18 -18 0", "18 18 1", "1191.3 -2026 521" );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c1m4_atrium":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

make_ladder( "_ladder_plywoodback_cloned_plywoodfront", "-3311 -4299 588", "-6627 -8597 0", "0 180 0", "-1 0 0" );
make_ladder( "_ladder_columnfarcorner_cloned_columngibbs", "-5044 -3531 443.893", "-1008.53 0 0" );
make_ladder( "_ladder_columnbooth_cloned_columngibbs", "-5044 -3531 443.893", "-8255 1902 -220", "0 90 0", "1 0 0" );
make_ladder( "_ladder_columnplywood_cloned_columnbusystairs", "-4948 -4181 310.5", "-504 0 0" );
make_ladder( "_ladder_columnstairsright_cloned_columnbusystairs", "-4948 -4181 310.5", "1008 0 -216" );
make_ladder( "_ladder_columnstairsleft_cloned_columnbusystairs", "-4948 -4181 310.5", "1512 0 -216" );
make_ladder( "_ladder_columnfallbanner_cloned_columnbusystairs", "-4948 -4181 310.5", "2016 0 0" );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*==============================
||                            ||
||       DARK CARNIVAL        ||
||                            ||
==============================*/

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c2m1_highway":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

kill_entity( Entities.FindByClassnameNearest( "env_player_blocker", Vector( 1388, 5660, -649 ), 1 ) );
kill_entity( Entities.FindByClassnameNearest( "env_player_blocker", Vector( 2972, 3724, -649 ), 1 ) );
make_brush( "_losfix_bush",		"-10 -190 -60",	"10 200 35",	"8224 8378 -536" );
make_brush( "_losfix_end_fence",	"-254 -1 -5",	"254 0 5",	"-522 -2416 -1083" );
make_brush( "_losfix_highway_bus1",		"-40 -1 -10",	"100 1 14",	"7035 7874 -641" );
make_brush( "_losfix_highway_bus2",		"-1 -54 -8",	"1 54 8",	"6951 7806 -645" );
make_brush( "_losfix_motel_balcony1",	"-1 -282 -2",	"0 282 2",	"2959 3416 -806" );
make_brush( "_losfix_motel_balcony2",	"-81 0 -2",	"81 1 2",	"2865 3129 -806" );
make_brush( "_losfix_motel_fence",		"0 -128 -6",	"1 128 6",	"3058 4818 -972" );
make_brush( "_losfix_motel_van",	"-64 -1 -10",	"64 1 10",	"1545 4113 -966" );
make_brush( "_losfix_overpass_truck",	"-1 -32 -12",	"1 32 12",	"3571 7076 -693" );
make_brush( "_losfix_start_bus",		"-215 -1 -18",	"250 1 24",	"9213 7957 -514" );
make_brush( "_losfix_start_van",	"-100 -1 -15",	"100 1 15",	"7957 7769 -581" );
make_brush( "_losfix_underpass_truck",	"-1 -110 -15",	"1 20 15",	"3471 7845 -994" );
make_brush( "_losfix_van_jump",		"-1 -40 -12",	"1 44 20",	"6981.6 7662.8 -656.3" );
make_clip( "_ladder_motelfrontleft_clipleft", "Everyone", 1, "-8 -25 0", "0 0 308", "2766 3708 -968", "0 129 0" );
make_clip( "_ladder_motelfrontleft_clipright", "Everyone", 1, "0 0 0", "8 25 308", "2753 3724 -968", "0 -129 0" );
make_clip( "_ladder_motelfrontright_clipleft", "Everyone", 1, "-8 -25 0", "0 0 308", "1372 4691 -968", "0 39 0" );
make_clip( "_ladder_motelfrontright_clipright", "Everyone", 1, "0 0 0", "8 25 308", "1366 4690 -968", "0 -39 0" );
make_clip( "_saferoof_trollblock", "Survivors", 1, "-72 -282 0", "120 166 684", "-904 -2534 -940" );
make_clip( "_whispsign_infectedqol", "SI Players", 1, "-56 -3.5 -2", "64 3 2", "9526 8374 -169" );
make_ladder( "_ladder_barrelsemi_cloned_caralarmshort", "1378 4328 -888", "2761 11131 269", "0 -120.6 0", "-0.52 -0.85 0" );
make_ladder( "_ladder_endbusback_cloned_caralarmshort", "1378 4328 -888", "1026 1349 -147", "0 159 0", "-0.92 0.37 0" );
make_ladder( "_ladder_endbusfront_cloned_caralarmshort", "1378 4328 -888", "-4553 -5663 -147", "0 -21.65 0", "0.92 -0.37 0" );
make_ladder( "_ladder_endsafebackl_cloned_fixdontdelete", "-187 -1725 -1018.05", "-599 -949 5" );
make_ladder( "_ladder_endsafebackr_cloned_fixdontdelete", "-187 -1725 -1018.05", "-599 -917 5" );
make_ladder( "_ladder_endsaferoofa_cloned_fixdontdelete", "-187 -1725 -1018.05", "-599 -667 5" );
make_ladder( "_ladder_endsaferoofb_cloned_fixdontdelete", "-187 -1725 -1018.05", "875 -3001 5", "0 270 0", "0 -1 0" );
make_ladder( "_ladder_highwaysign_cloned_whispsign", "9531 8445.5 -414.5", "-811 -365 -10" );
make_ladder( "_ladder_hilltoptruck_cloned_fixdontdelete", "-187 -1725 -1018.05", "702 -1008 10", "0 270 0", "0 -1 0" );
make_ladder( "_ladder_motelfrontleftB_cloned_motelalarmright", "1379 5428 -868", "8197 2343 -8", "0 90 0", "0 1 0" );
make_ladder( "_ladder_motelfrontleftT_cloned_motelalarmright", "1379 5428 -868", "8197 2343 120", "0 90 0", "0 1 0" );
make_ladder( "_ladder_motelfrontrightB_cloned_motelalarmright", "1379 5428 -868", "7 -740 -8" );
make_ladder( "_ladder_motelfrontrightT_cloned_motelalarmright", "1379 5428 -868", "7 -740 120" );
make_ladder( "_ladder_motelroofleft_cloned_onewaycliff", "1126.1 2008.58 -1462", "-863 5299 570", "0 -105 0", "-1 0 0" );
make_ladder( "_ladder_motelroofright_cloned_onewaycliff", "1126.1 2008.58 -1462", "-863 6912 570", "0 -105 0", "-1 0 0" );
make_ladder( "_ladder_motelroofright_cloned_onewaycliff", "1126.1 2008.58 -1462", "-868 6907 570", "0 -104.8 0", "-1 0 0" );
make_ladder( "_ladder_motelroofright_cloned_onewaycliff", "1126.1 2008.58 -1462", "-868 6907 570", "0 -104.8 0", "-1 0 0" );
make_ladder( "_ladder_qolbus_cloned_caralarmshort", "1378 4328 -888", "2759 7157 306", "0 -62.95 0", "0.45 -0.89 0" );
make_ladder( "_ladder_sheriffbus_cloned_caralarmshort", "1378 4328 -888", "4814 11473 245", "0 -142 0", "-0.78 -0.62 0" );
make_ladder( "_ladder_shortcutsemiback_cloned_caralarmshort", "1378 4328 -888", "3604 2785 270" );
make_ladder( "_ladder_shortcutsemifront_cloned_caralarmshort", "1378 4328 -888", "5705 11403 234", "0 180 0", "-1 0 0" );
make_ladder( "_ladder_shrubberybus_cloned_caralarmshort", "1378 4328 -888", "9165 10696 188", "0 152.5 0", "-0.88 0.46 0" );
make_ladder( "_ladder_slopetruck_cloned_caralarmshort", "1378 4328 -888", "10246 5931 274", "0 76.27 0", "0.24 0.97 0" );
make_ladder( "_ladder_startbus_cloned_caralarmshort", "1378 4328 -888", "5004 9321 425", "0 -90 0", "0 -1 0" );
make_ladder( "_ladder_tankfence_cloned_caralarm", "1378 4328 -888", "1681 298 -31" );
make_ladder( "_ladder_tankfightsemi_cloned_caralarmshort", "1378 4328 -888", "6740 8684 -36", "0 150.47 0", "-0.87 0.5 0" );
make_ladder( "_ladder_whispsignextender_cloned_motelpoolfence", "2712 3850 -906", "6819 4600 639" );
make_prop( "dynamic",		"_losblocker_fence",		"models/props_urban/fence_cover001_256.mdl",	"3060 4819 -967",		"0 0 0",		"shadow_no" );
make_prop( "dynamic",		"_losblocker_fencea",		"models/props_urban/fence_cover001_256.mdl",	"-128 -1332 -1078.75",		"0 150.5 0",		"shadow_no" );
make_prop( "dynamic",		"_losblocker_fenceb",		"models/props_urban/fence_cover001_256.mdl",	"48 -1160 -1078.75",		"0 120.5 0",		"shadow_no" );
make_prop( "dynamic",		"_propladder_barrel",		"models/props_urban/highway_barrel001.mdl",	"3084 5126 -947.96",		"-1.4995 119.966 2.6",	"shadow_no" );
make_prop( "dynamic",		"_propladder_barrier",		"models/props_fortifications/concrete_barrier001_128_reference.mdl",	"3079 5152 -948.75",		"0 18.5 -90",		"shadow_no" );
make_prop( "dynamic", "_ladder_motelfrontleftB_pipe", "models/props_rooftop/Gutter_Pipe_256.mdl", "2769 3714 -788", "0 180 0", "shadow_no" );
make_prop( "dynamic", "_ladder_motelfrontleftT_pipe", "models/props_rooftop/Gutter_Pipe_128.mdl", "2769 3714 -660", "0 180 0", "shadow_no" );
make_prop( "dynamic", "_ladder_motelfrontrightB_pipe", "models/props_rooftop/Gutter_Pipe_256.mdl", "1378 4688 -788", "0 90 0", "shadow_no" );
make_prop( "dynamic", "_ladder_motelfrontrightT_pipe", "models/props_rooftop/Gutter_Pipe_128.mdl", "1378 4688 -660", "0 90 0", "shadow_no" );
make_prop( "dynamic", "_ladder_motelroofleft_pipe", "models/props_mill/PipeSet08d_512_001a.mdl", "792 3695 -904", "90 90 0", "shadow_no" );
make_prop( "dynamic", "_ladder_motelroofright_pipe", "models/props_mill/PipeSet08d_512_001a.mdl", "792 5308 -904", "90 90 0", "shadow_no" );
make_prop( "dynamic", "_ladder_motelroofright_pipe", "models/props_mill/PipeSet08d_512_001a.mdl", "792 5308 -904", "90 90 0", "shadow_no" );
make_prop( "dynamic", "_losblocker_motelleft", "models/props_rooftop/acvent01.mdl", "2706 3541 -665", "0 0 0", "shadow_no" );
make_prop( "dynamic", "_losblocker_motelright", "models/props_rooftop/acvent01.mdl", "1205 5394 -668", "0 90 0", "shadow_no" );
make_prop( "dynamic", "_motelskyboxroof_wrongwaya", "models/props_misc/wrongway_sign01_optimized.mdl", "918 3383 -565", "0 90 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_motelskyboxroof_wrongwayb", "models/props_misc/wrongway_sign01_optimized.mdl", "1318 3383 -555", "0 90 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_motelskyboxroof_wrongwayc", "models/props_misc/wrongway_sign01_optimized.mdl", "1718 3383 -555", "0 90 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_motelskyboxroof_wrongwayd", "models/props_misc/wrongway_sign01_optimized.mdl", "2118 3383 -555", "0 90 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_motelskyboxroof_wrongwaye", "models/props_misc/wrongway_sign01_optimized.mdl", "2518 3383 -555", "0 90 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_motelskyboxroof_wrongwayf", "models/props_misc/wrongway_sign01_optimized.mdl", "2850 3383 -565", "0 90 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
patch_ladder( "-196 -1725 -1018.049", "0 0 0", "-1 0 0" );
make_trigpush( "_trigpushl_whispsign", "Infected", 50, "0 0 0", "0 0 0", "1 1 1", "9536 8453 -193" );
make_trigpush( "_trigpushr_whispsign", "Infected", 50, "0 180 0", "0 0 0", "1 1 1", "9525 8453 -193" );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c2m2_fairgrounds":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

kill_funcinfclip( 369.072 );		// Directly above start safe room
kill_funcinfclip( 340.667 );		// Hedge next to start safe room
kill_funcinfclip( 361.324 );		// Fence next to that hedge
kill_funcinfclip( 340.839 );		// Fence next to that fence
kill_funcinfclip( 930.962 );		// Delete clip above end safe roof
kill_funcinfclip( 1865.19 );		// Delete clip on fairground's far back side (Tank fight area)
make_atomizer( "_atomizer_bsp_dumpster", "-3777 -1164 -118", "models/props_junk/dumpster_2.mdl", 60 );
make_atomizer( "_atomizer_anv_2009forklift", "-3777 -1164 -128", "models/props\\cs_assault\\forklift_brokenlift.mdl", 30 );
make_atomizer( "_atomizer_bsp_forklift", "2752 -1529 0", "models/props\\cs_assault\\forklift_brokenlift.mdl", 60 );
make_brush( "_losfix_end_gen",		"-28 -1 -8",	"28 1 8",	"-3546 -5845 -55" );
make_brush( "_losfix_slide_gen",	"-28 -1 -8",	"28 1 8",	"-2363 -3306 -121" );
make_brush( "_losfix_start_gen",	"-32 -1 -8",	"32 1 8",	"2812 946.508 7" );
make_brush( "_losfix_trailer",	"-1 -100 -8",	"1 100 8",	"-2717 -2863 -122" );
make_brush( "_losfix_warehouse_gen",	"-22 -1 -8",	"22 1 8",	"2859 -1715 8" );
make_brush( "_tolentrance_base_losblock", "-1 -155 0", "4 149 38", "-3924 -5493 144" );
make_brush( "_tolentrance_main_losblock", "-1 -139 0", "4 120 165", "-3924 -5493 144" );
make_clip( "_ladder_garagebench_clipl", "Everyone", 1, "-8 -16 0", "8 16 161", "4103 -2102 4", "0 -45 0" );
make_clip( "_ladder_garagebench_clipr", "Everyone", 1, "-8 -16 0", "8 16 161", "4103 -2142 4", "0 45 0" );
make_clip( "_ladder_startrestrooms_clip", "Everyone", 1, "-6 -21 0", "11 26 127", "3061 1279 0" );
make_clip( "_meticulous_funcinfclip01", "SI Players", 1, "-8 -886 0", "8 873 497", "-4349 -5498 272" );
make_clip( "_meticulous_funcinfclip02", "SI Players", 1, "-61 -9 0", "55 9 497", "-4296 -6392 272" );
make_clip( "_onewayfence_blocker", "Survivors", 1, "-192 -1 0", "192 1 197", "-2240 -3841 2" );
make_clip( "_propladder_acvent_qolclip", "SI Players", 1, "-36 -28 -4", "32 32 12", "-1155 -6870 80" );
make_clip( "_tolentrance_base_collision", "Everyone", 1, "-1 -155 0", "19 149 34", "-3924 -5493 144" );
make_clip( "_tolentrance_main_collision", "Everyone", 1, "-1 -155 0", "4 149 165", "-3924 -5493 144" );
make_clip( "_yeswayfairback_funcinfclip", "SI Players", 1, "-1824 -8 -384", "1824 17 384", "-2272 1824 384" );
make_ladder( "_ladder_appleshedge_cloned_endelecboxback", "-3689 -6048 1", "2926 1156 -64" );
make_ladder( "_ladder_brickbackend_cloned_whiteawnings", "-2736 -6652 16", "-10057 2274 158", "0 90 0", "-1 0 0" );
make_ladder( "_ladder_brickbannerB_cloned_icemachine", "3855 784 98.6349", "868 292 26", "0 180 0", "1 0 0" );
make_ladder( "_ladder_brickbannerT_cloned_icemachine", "3855 784 98.6349", "868 292 58", "0 180 0", "1 0 0" );
make_ladder( "_ladder_bricksmokerB_cloned_bilehopcorner", "-800 -5500 32", "-2355 5377 -146" );
make_ladder( "_ladder_bricksmokerT_cloned_bilehopcorner", "-800 -5500 32", "-2355 5377 174" );
make_ladder( "_ladder_carouselelecbox_cloned_tallsignfence", "-1536 -5253 -64", "1389 -2362 -4", "0 -30 0", "-0.5 -0.87 0" );
make_ladder( "_ladder_carouselpermstuck_cloned_trucknukenose", "-3664 -2409 -80", "1423 -2847 285" );
make_ladder( "_ladder_carouseltiptop_cloned_trucknuketop", "-3664 -2317 -2", "1423 -3219 283" );
make_ladder( "_ladder_endawningsT_cloned_endawningsB", "-2736 -6652 16", "105 -128 160" );
make_ladder( "_ladder_endbrickback_cloned_endbrickfront", "-800 -5500 32", "-1857 -11769 0", "0 180 0", "0 -1 0" );
make_ladder( "_ladder_endelecboxfront_cloned_endelecboxback", "-3689 -6048 1", "-7327 -11977 0", "0 180 0", "1 0 0" );
make_ladder( "_ladder_endhedgefront_cloned_endhedgeback", "-3488 -6361 2", "-6981 -12673 0", "0 180 0", "0 1 0" );
make_ladder( "_ladder_garagebench_cloned_icemachine", "3855 784 98.635", "233 -2906 -31" );
make_ladder( "_ladder_genconcreteback_cloned_genconcretefront", "895 -56 64", "1806.25 -124.604 0", "0 180 0", "1 0 0" );
make_ladder( "_ladder_generatorfence_cloned_galleryfence", "2451 -210 69", "2811 660 0", "0 -90 0", "0 1 0" );
make_ladder( "_ladder_hedgecamera_cloned_chompyskypipe", "3089 -552 136", "1311 192 -82" );
make_ladder( "_ladder_lilpeanutB_cloned_dumpsteralley", "-4015 -1756 32", "1215 -900 -32" );
make_ladder( "_ladder_lilpeanutT_cloned_dumpsteralley", "-4015 -1756 32", "1215 -900 160" );
make_ladder( "_ladder_midareafence_cloned_scavfencefront", "-1184 -1787 -62", "2848 2777 135" );
make_ladder( "_ladder_parkourtracks1B_cloned_icemachine", "3855 784 98.6349", "-1507 -3201 -172", "0 90 0", "0 -1 0" );
make_ladder( "_ladder_parkourtracks1T_cloned_trucknuketop", "-3664 -2317 -2", "205 -2872 107", "0 -90 0", "-1 0 0" );
make_ladder( "_ladder_parkourtracks2B_cloned_icemachine", "3855 784 98.6349", "2350.1 -2390 -128", "0 180 0", "1 0 0" );
make_ladder( "_ladder_parkourtracks2T_cloned_trucknuketop", "-3664 -2317 -2", "2718 -3998 106", "0 -45 0", "-0.7 -0.7 0" );
make_ladder( "_ladder_picketback_cloned_galleryfence", "2451 -210 69", "-3682 1315 -153", "0 -90 0", "0 1 0" );
make_ladder( "_ladder_picketfront_cloned_galleryfence", "2451 -210 69", "-4100.87 -3594.57 -152.873", "0 90 0", "0 -1 0" );
make_ladder( "_ladder_redchickentent_cloned_gonutsleft", "2305 192 52", "1599 -1505 1" );
make_ladder( "_ladder_ridesroof_cloned_bilejarcut", "-900 -640 0", "887 1085 89" );
make_ladder( "_ladder_ridesroofbanner_cloned_containerpile", "-3952 -2561 -48", "4310 2825 359" );
make_ladder( "_ladder_ridesroofright_cloned_telepoletrains", "-784 -9 34", "1643 273 64" );
make_ladder( "_ladder_signgonuts_cloned_hedgebins", "2305 832 52", "-1 -310 0" );
make_ladder( "_ladder_slidefencefront_cloned_slidefenceback", "-2917 -2752 -63", "-5827 -5634 0", "0 180 0", "1 0 0" );
make_ladder( "_ladder_snoconestent_cloned_carouseluproom", "-2049 -4345 -26", "1537 4877 -28" );
make_ladder( "_ladder_startfenceback_cloned_cargocontainerback", "351 -960 64", "1434 3072 1" );
make_ladder( "_ladder_startfencefront_cloned_cargocontainerfront", "485 -960 64", "1305 3136 1" );
make_ladder( "_ladder_starthedgeback_cloned_cargocontainerback", "351 -960 64", "1370 3432 1" );
make_ladder( "_ladder_startrestrooms_cloned_icemachine", "3855 784 98.635", "-799 459 -35" );
make_ladder( "_ladder_tankfallback_cloned_galleryfence", "2451 -210 69", "-267 -2451 -10", "0 90 0", "0 -1 0" );
make_ladder( "_ladder_tankhedge_cloned_endelecboxback", "-3689 -6048 1", "-7149 -10818 -64", "0 180 0", "1 0 0" );
make_ladder( "_ladder_tentcornerB_cloned_tentcornerback", "-3377 1344 -71.5", "-6604 2583 -8", "0 180 0", "1 0 0" );
make_ladder( "_ladder_tenthedgejump_cloned_tentcornerback", "-3377 1344 -71.5", "-2404.46 -6133.6 -8", "0 -90 0", "0 1 0" );
make_ladder( "_ladder_tolentrance_cloned_uppertrackway", "-900 -2432 0", "-6440 -4754 16", "0 90 0", "0 -1 0" );
make_ladder( "_ladder_tolentrancetop_cloned_carouselfence", "-1416 -5243 -62", "1148 -6925 270", "0 -90 0", "1 0 0" );
make_ladder( "_ladder_warehouseexitleft_cloned_scavfencefront", "-1184 -1787 -62", "1739 -6 128" );
make_ladder( "_ladder_yeswayfairleft_cloned_scavfenceback", "-1248 -1797 -62", "-894 3244 -1" );
make_ladder( "_ladder_yeswayfairright_cloned_scavfenceback", "-1248 -1797 -62", "48 3244 -1" );
make_prop( "dynamic",		"_losblocker_hedgea",		"models/props_foliage/urban_hedge_128_64_high.mdl",		"2046 977 78",			"0 180.228 0",		"shadow_no" );
make_prop( "dynamic",		"_losblocker_hedgeb",		"models/props_foliage/urban_hedge_128_64_high.mdl",		"2258 930 78",			"0 90.2275 0",		"shadow_no" );
make_prop( "dynamic",		"_losblocker_hedgec",		"models/props_foliage/urban_hedge_128_64_high.mdl",		"2258 731 78",			"0 90.2275 0",		"shadow_no" );
make_prop( "dynamic",		"_losblocker_hedged",		"models/props_foliage/urban_hedge_128_64_high.mdl",		"2258 638 78",			"0 90.2275 0",		"shadow_no" );
make_prop( "dynamic",		"_losblocker_hedgee",		"models/props_foliage/urban_hedge_128_64_high.mdl",		"2258 410 78",			"0 90.2275 0",		"shadow_no" );
make_prop( "dynamic",		"_losblocker_hedgef",		"models/props_foliage/urban_hedge_128_64_high.mdl",		"2258 295 78",			"0 90.2275 0",		"shadow_no" );
make_prop( "dynamic",		"_losblocker_hedgeg",		"models/props_foliage/urban_hedge_128_64_high.mdl",		"2258 92 78",			"0 90.2275 0",		"shadow_no" );
make_prop( "dynamic",		"_losblocker_hedgeh",		"models/props_foliage/urban_hedge_128_64_high.mdl",		"2046 47 78",			"0 180.228 0",		"shadow_no" );
make_prop( "dynamic",		"_losblocker_hedgei",		"models/props_foliage/urban_hedge_128_64_high.mdl",		"1844 92 78",			"0 90.2275 0",		"shadow_no" );
make_prop( "dynamic",		"_losblocker_hedgej",		"models/props_foliage/urban_hedge_128_64_high.mdl",		"1844 295 78",			"0 90.2275 0",		"shadow_no" );
make_prop( "dynamic",		"_losblocker_hedgek",		"models/props_foliage/urban_hedge_128_64_high.mdl",		"1844 410 78",			"0 90.2275 0",		"shadow_no" );
make_prop( "dynamic",		"_losblocker_hedgel",		"models/props_foliage/urban_hedge_128_64_high.mdl",		"1844 638 78",			"0 90.2275 0",		"shadow_no" );
make_prop( "dynamic",		"_losblocker_hedgem",		"models/props_foliage/urban_hedge_128_64_high.mdl",		"1844 731 78",			"0 90.2275 0",		"shadow_no" );
make_prop( "dynamic",		"_losblocker_hedgen",		"models/props_foliage/urban_hedge_128_64_high.mdl",		"1844 930 78",			"0 90.2275 0",		"shadow_no" );
make_prop( "dynamic",		"_propladder_acvent",		"models/props_rooftop/acvent02.mdl",		"-1156 -6874 32.92",		"0 0.5 0",		"shadow_no" );
make_prop( "dynamic", "_ladder_garagebench_pipe", "models/props_rooftop/Gutter_Pipe_128.mdl", "4096 -2122 159", "0 -90 0", "shadow_no" );
make_prop( "dynamic", "_ladder_hedgecamera_pipe", "models/props_rooftop/Gutter_Pipe_256.mdl", "4384 -360 196", "0 90 0", "shadow_no" );
make_prop( "dynamic", "_ladder_parkourtracks1B_pipe", "models/props_rooftop/Gutter_Pipe_128.mdl", "-2291 670 0", "0 0 0", "shadow_no" );
make_prop( "dynamic", "_ladder_ridesroof_pipe", "models/props_rooftop/Gutter_Pipe_256.mdl", "0 445 201", "0 -90 0", "shadow_no" );
make_prop( "dynamic", "_ladder_ridesroofright_pipe", "models/props_rooftop/Gutter_Pipe_256.mdl", "859 272 242", "0 0 0", "shadow_no" );
make_prop( "dynamic", "_ladder_tolentrance_pipe", "models/props_rooftop/Gutter_Pipe_256.mdl", "-4008 -5648 144", "0 0 0", "shadow_no" );
make_prop( "dynamic", "_losblocker_ridesroof", "models/props_rooftop/acvent03.mdl", "923 406 222", "0 0 0", "shadow_no" );
make_prop( "dynamic", "_losblocker_startfence", "models/props_urban/fence_cover001_256.mdl", "1788 2145 1", "0 0 0", "shadow_no" );
make_prop( "dynamic", "_propladder_ridesroof", "models/props_urban/chimney001.mdl", "288 300 315", "0 -90 0", "shadow_no" );
make_prop( "dynamic", "_startroof_wrongwaya", "models/props_misc/wrongway_sign01_optimized.mdl", "1539 2888 200", "0 0 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_startroof_wrongwayb", "models/props_misc/wrongway_sign01_optimized.mdl", "1539 2678 200", "0 0 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_startroof_wrongwayc", "models/props_misc/wrongway_sign01_optimized.mdl", "1539 2490 60", "0 0 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_startroof_wrongwayd", "models/props_misc/wrongway_sign01_optimized.mdl", "1539 2160 60", "0 0 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_yeswayfairback_wall", "models/props_update/c2m2_fairgroundwall.mdl", "-2304 1536 -32", "0 270 0", "shadow_no" );
make_prop( "physics", "_hittable_2009forklift", "models/props/cs_assault/forklift.mdl", "-3666 -1321 -111", "0 135 0" );
make_trigduck( "_duckqol_carouselroof", "-30 1 0", "30 3 1", "-2240 -5259 303" );
patch_nav_checkpoint( "1737 2712 4" );
patch_nav_checkpoint( "-4337 -5511 -64" );

// Manually fix the 2009 forklift since it is spawned after anv_mapfixes runs
NetProps.SetPropInt( Entities.FindByName( null, g_UpdateName + "_hittable_2009forklift" ), "m_iMinHealthDmg", 400 );
NetProps.SetPropInt( Entities.FindByName( null, g_UpdateName + "_hittable_2009forklift" ), "m_takedamage", 3 );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c2m3_coaster":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

EntFire( "wrongway_brushes", "Enable" );
make_brush( "_coastertower_chimney_losblock", "-11 -19 0", "11 19 77", "-2751 1031 620" );
make_brush( "_losfix_truck",		"-1 -26 -8",	"1 64 8",	"-1575 1984 8" );
make_clip( "_coastertower_chimney_collision", "Everyone", 1, "-11 -19 0", "11 19 77", "-2751 1031 620" );
make_clip( "_ladder_buttonlegT_clip", "SI Players", 1, "-2 -1 -24", "2 1 17", "-3548 1785 148", "45 0 0" );
make_clip( "_ladder_coastertower_clip", "Everyone", 1, "-64 -3 -20", "64 13 42", "-2784 1327 174" );
make_clip( "_ladder_swanroomcpanel_clipB", "SI Players", 1, "0 -10 0", "1 10 2", "479 4838 126" );
make_clip( "_ladder_swanroomcpanel_clipT", "SI Players", 1, "-4 -10 0", "4 10 20", "475 4838 126" );
make_clip( "_ladderqol_coasterinclinequad", "SI Players", 1, "-64 -75 10", "64 -1 22", "-2784 375 593", "0 0 -45" );
make_clip( "_onewaybreakwall_elecbox", "Everyone", 1, "-64 -4 0", "64 4 236", "-64 3524 100" );
make_clip( "_propladder_airconda_qol", "SI Players", 1, "-22 -20 12", "22 -1 32", "-1938 739 195" );
make_clip( "_startwindow_cheese", "Survivors", 1, "-47.6 0 0", "49.6 1 135", "2783 1920 105" );
make_clip( "_trailerfence_clip", "SI Players", 1, "-114 -39 3", "126 761 963", "-1150 2887 -3" );
make_ladder( "_ladder_buttonlegT_cloned_buttonlegB", "-3518 1780 102", "0 2.1 118" );
make_ladder( "_ladder_coastertowerB_cloned_finalleg", "-4164 2274 128", "-510 5513 168", "0 90 0", "0 1 0" );
make_ladder( "_ladder_coastertowerT_cloned_shrubberytilt", "-2976 886.5 258", "-5760 2209 264", "0 180 0", "0 1 0" );
make_ladder( "_ladder_deadendcontainer_cloned_trailerfenceback", "-1056 2586 66", "235 -1929 -4" );
make_ladder( "_ladder_elecboxbags_cloned_dumpsterduo", "-774 1344 160", "-2446 255 0", "0 -90 0", "0 1 0" );
make_ladder( "_ladder_fencedroproof_cloned_dumpsterduo", "-774 1344 160", "-320 3316 35", "0 90 0", "0 -1 0" );
make_ladder( "_ladder_gunstruck_cloned_signalvines", "-1798 2176 80", "665 3727 -3", "0 90 0", "0 -1 0" );
make_ladder( "_ladder_swanroomcpanel_cloned_unusedconcrete", "-1920 -2 80", "2421 4867 -8" );
make_ladder( "_ladder_swanroomelecbox_cloned_swanroomsource", "-118 4376 80.5", "126 -106 65" );
make_ladder( "_ladder_swanroomshelf_cloned_coasterfencetilt", "-2240 2564 63.3879", "2837 1571 -29" );
make_ladder( "_ladder_trailerfencefront_cloned_trailerfenceback", "-1056 2586 66", "-2193 5164 0", "0 -180 0", "0 -1 0" );
make_prop( "dynamic",		"_losblocker_fencea",		"models/props_urban/fence_cover001_128.mdl",	"-2698 2029 -0.675446",		"0.0 180.0 0.0",	"shadow_no" );
make_prop( "dynamic",		"_losblocker_fenceb",		"models/props_urban/fence_cover001_128.mdl",	"-2682 2155 -0.675446",		"0.0 165.0 0.0",	"shadow_no" );
make_prop( "dynamic", "_propladder_airconda", "models/props_rooftop/acvent04.mdl", "-1938 683 160", "0 180 0", "shadow_no" );
make_prop( "dynamic", "_propladder_aircondb", "models/props_rooftop/acunit01.mdl", "-1825 490 231", "0 180 0", "shadow_no" );
make_prop( "dynamic", "_trailerfence_wrongway", "models/props_misc/wrongway_sign01_optimized.mdl", "-1093 2848 100", "0 -90 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "physics", "_hittable_bumpera_m4translated", "models/props_fairgrounds/bumpercar.mdl", "-5048 1361 4", "0 338 0" );
make_prop( "physics", "_hittable_bumperb_m4translated", "models/props_fairgrounds/bumpercar.mdl", "-5123 1374 31", "-1 178 106" );
make_trigmove( "_duckqol_swanroomcpanel", "Duck", "-4 -4 0", "4 4 32", "483 4854 136" );
make_trigmove( "_duckqol_coastergate", "Duck", "-17 -8 0", "17 8 1", "-2756 1690 139" );
patch_ladder( "-1278 2672 160", "13 0 0" );
patch_ladder( "-3518 1780 102", "0 2.1 0" );
patch_ladder( "-4164 2274 128", "0 -2 0" );
patch_ladder( "-484 506 160", "0 -3 0" );
patch_nav_checkpoint( "3852 2037 -64" );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c2m4_barns":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

kill_funcinfclip( 736.871 );
make_atomizer( "_atomizer_anv_haybail", "-960 -404 -184", "models/props_unique/haybails_single.mdl", 60 );
make_brush( "_losfix_barn_gen",		"-1 -28 -8",	"1 28 8",	"-1742 346 -185" );
make_brush( "_losfix_drop_trailer",	"-48 -1 -8",	"48 1 8",	"-2423 4 -185" );
make_brush( "_losfix_start_trailer1a",	"-102 -1 -8",	"102 1 8",	"2347 3295 -185" );
make_brush( "_losfix_start_trailer1b",	"-1 -40 -8",	"1 40 8",	"2244 3333 -185" );
make_brush( "_losfix_start_trailer2",	"-102 -1 -8",	"102 1 8",	"2814 2614 -185" );
make_clip( "_eventfence_wrongway", "SI Players", 1, "-210 -20 -608", "200 20 672", "-200 2652 352" );
make_clip( "_eventrooftop_smoother1", "SI Players", 1, "-343 0 0", "249 140 8", "-3305 1312 195", "0 0 -44" );
make_clip( "_eventrooftop_smoother2", "SI Players", 1, "-249 140 0", "343 0 8", "-3305 1312 195", "0 180 -44" );
make_clip( "_ladder_askewhedgeshared_clip", "SI Players and AI", 1, "-3 -279 -7", "3 245 79", "593 1177 -63" );
make_clip( "_ladder_barnoverhang_clip", "Survivors", 1, "-24 -4 -10", "24 4 188", "-731 56 -86" );
make_clip( "_ladder_barnsarearight_clip", "Everyone", 1, "1 -232 0", "2 16 85", "263 2288 -192" );
make_clip( "_ladder_startroof_clip", "Everyone", 1, "-16 -17 -5", "16 20 175", "3362.5 3216 -187" );
make_ladder( "_ladder_askewhedgebotr1_cloned_askewhedgebotl", "610 1209.88 -123.984", "0 26 0" );
make_ladder( "_ladder_askewhedgebotr2_cloned_askewhedgebotl", "610 1209.88 -123.984", "0 52 0" );
make_ladder( "_ladder_askewhedgetopl1_cloned_askewhedgetopr", "594 1262 -24", "0 -26 0" );
make_ladder( "_ladder_askewhedgetopl2_cloned_askewhedgetopr", "594 1262 -24", "0 -52 0" );
make_ladder( "_ladder_barnsarearight_cloned_barnsarealeft", "112 1526 -149", "1789 2124 -1.46", "0 90 0", "1 0 0" );
make_ladder( "_ladder_barnoverhang_cloned_starttrailer", "3645 1907 -130.5", "-4376 -1852 97" );
make_ladder( "_ladder_bumperhedgeleft_cloned_meatburgerhedge", "252 944 -132", "304 393 0" );
make_ladder( "_ladder_bumperhedgeright_cloned_meatburgerhedge", "252 944 -132", "304 359 0" );
make_ladder( "_ladder_cornerfence_cloned_fencebackalley", "864 2441 -124", "1274 4780 0", "0 -180 0", "0 -1 0" );
make_ladder( "_ladder_eventcedabanner1_cloned_askewhedgetopr", "594 1262 -24", "-4035 -398 71" );
make_ladder( "_ladder_eventcedabanner2_cloned_askewhedgetopr", "594 1262 -24", "-4035 -366 71" );
make_ladder( "_ladder_eventcedabanner3_cloned_askewhedgetopr", "594 1262 -24", "-4035 -334 71" );
make_ladder( "_ladder_eventendfencefront_cloned_endfenceback", "-144 2458 -188", "-265 4900 0", "0 -180 0", "0 -1 0" );
make_ladder( "_ladder_eventwallfence_cloned_peachpitwall", "-3056 1726 -168", "-4165 -2040 -26", "0 -90 0", "-1 0 0" );
make_ladder( "_ladder_finalrun1_cloned_hotdogstand", "2396 636 -124", "-3242 1088 -63" );
make_ladder( "_ladder_finalrun2_cloned_bumpsidemid", "1462 2296 -124", "-1685.4 -518 -71" );
make_ladder( "_ladder_lightapplesfront_cloned_lightapplesback", "-208 856 -120", "-450 1712 0", "0 -180 0", "-1 0 0" );
make_ladder( "_ladder_lightticketsbackB_cloned_lightapplesback", "-208 856 -120", "-3019 681 0", "0 -90 0", "0 -1 0" );
make_ladder( "_ladder_lightticketsbackT_cloned_lightapplesback", "-208 856 -120", "-3019 681 128", "0 -90 0", "0 -1 0" );
make_ladder( "_ladder_lightticketsfrontB_cloned_lightapplesback", "-208 856 -120", "-1307 1127 0", "0 90 0", "0 1 0" );
make_ladder( "_ladder_lightticketsfrontT_cloned_lightapplesback", "-208 856 -120", "-1307 1127 128", "0 90 0", "0 1 0" );
make_ladder( "_ladder_redtentmid_cloned_redtentstart", "2848 2074 -140", "-3787.5 -1225.5 1" );
make_ladder( "_ladder_startfoodcart_cloned_colddrinkfence", "1710 2272 -124", "741 1088 -13" );
make_ladder( "_ladder_starthedge_cloned_startfence", "2384 2462 -124", "-295 84 -7" );
make_ladder( "_ladder_startroof_cloned_elecbox", "1907 894 -64", "1455.5 2307 -68" );
make_prop( "dynamic", "_barn_overhang_floor", "models/props_update/c2m4_barn_overhang.mdl", "-608 162 28", "0 90 0", "shadow_no" );
make_prop( "dynamic", "_barn_overhang_ladder", "models/props_c17/metalladder001.mdl", "-731 57 32", "0 270 180", "shadow_no" );
make_prop( "dynamic", "_barn_overhang_laddercover", "models/props_highway/plywood_01.mdl", "-707 53.9 -97", "90 90 0", "shadow_no" );
make_prop( "dynamic", "_barn_overhang_haybaila", "models/props_unique/haybails_single.mdl", "-499 111 31", "0 180 0", "shadow_no" );
make_prop( "dynamic", "_barn_overhang_haybailb", "models/props_unique/haybails_single.mdl", "-528 111 75", "0 180 0", "shadow_no" );
make_prop( "dynamic", "_barn_overhang_haybailc", "models/props_unique/haybails_single.mdl", "-556 111 31", "0 180 0", "shadow_no" );
make_prop( "dynamic", "_barn_overhang_haybaild", "models/props_unique/haybails_single.mdl", "-690 215 75", "0 180 0", "shadow_no" );
make_prop( "dynamic", "_barn_overhang_haybaile", "models/props_unique/haybails_single.mdl", "-661 215 31", "0 180 0", "shadow_no" );
make_prop( "dynamic", "_barn_overhang_haybailf", "models/props_unique/haybails_single.mdl", "-718 215 31", "0 180 0", "shadow_no" );
make_prop( "dynamic", "_cosmetic_barn_ladder", "models/props_c17/metalladder001.mdl", "-665 -55 -189.2", "-90 300 0", "shadow_no", "solid_no" );
make_prop( "dynamic", "_cosmetic_fencea", "models/props_urban/fence_cover001_256.mdl", "896 2824 -192", "0 90 0", "shadow_no" );
make_prop( "dynamic", "_cosmetic_fenceb", "models/props_urban/fence_cover001_256.mdl", "384 2818.3 -192", "0 90 0", "shadow_no" );
make_prop( "dynamic", "_endfence_wrongwaya", "models/props_misc/wrongway_sign01_optimized.mdl", "-276 2636 -195", "0 -90 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_endfence_wrongwayb", "models/props_misc/wrongway_sign01_optimized.mdl", "-132 2636 -195", "0 -90 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic",		"_propladder_garbagecan",	"models/props_urban/garbage_can002.mdl",	"-2284 1028 -191",		"0 89.5 0",		"shadow_no" );
make_prop( "dynamic", "_ladder_startroof_pipe", "models/props_rooftop/Gutter_Pipe_256.mdl", "3362 3216 -4.1", "0 0 0", "shadow_no" );
make_prop( "dynamic", "_ladderpatch_awningfence1", "models/props_fortifications/police_barrier001_128_reference.mdl", "-635 2035 -192", "0 -45 90", "shadow_no" );
make_prop( "dynamic", "_ladderpatch_awningfence2", "models/props_fortifications/police_barrier001_128_reference.mdl", "-728 1969 -244", "104 -52 0", "shadow_no", "solid_no" );
make_prop( "dynamic", "_startfoodcart_wrongwaya", "models/props_misc/wrongway_sign01_optimized.mdl", "2125 3970 -130", "0 -90 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_startfoodcart_wrongwayb", "models/props_misc/wrongway_sign01_optimized.mdl", "2325 3970 -130", "0 -90 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_startfoodcart_wrongwayc", "models/props_misc/wrongway_sign01_optimized.mdl", "1966 3938 -130", "0 0 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "physics",		"_barn_middleroom_hittable",	"models/props_unique/haybails_single.mdl",	"-1103 191 -147.42",		"0 0 -92", "shadow_no" );
patch_ladder( "-666 2044 -192", "11 -29 0" );
patch_ladder( "1907 894 -64", "-40 -5 0" );

EntFire( g_UpdateName + "_ladderpatch_awningfence*", "Skin", 1 );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c2m5_concert":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

kill_funcinfclip( 130.518 );		// Delete clip inside sodapop 1a
kill_funcinfclip( 151.678 );		// Delete clip inside sodapop 1b
kill_funcinfclip( 369.219 );		// Delete clip inside anvilcase a
kill_funcinfclip( 226.475 );		// Delete clip inside anvilcase b
kill_funcinfclip( 425.096 );		// Delete clip inside NODRAW triplewindow
EntFire( "worldspawn", "RunScriptCode", "kill_funcinfclip( 130.518 )", 1 );		// Delete clip inside sodapop 2a (same)
EntFire( "worldspawn", "RunScriptCode", "kill_funcinfclip( 151.678 )", 1 );		// Delete clip inside sodapop 2b (same)
make_atomizer( "_atomizer_bsp_forklift", "-3527 3008 -256", "models/props\\cs_assault\\forklift_brokenlift.mdl", 60 );
make_axiswarp( "_axiswarp_anvilcase", "y+", 64, "-64 0 -128", "64 1 0", "-2304 2455 -96" );
make_axiswarp( "_axiswarp_sodapop1", "x+", 34, "0 -56 -184", "1 56 0", "-1400 1920 288" );
make_axiswarp( "_axiswarp_sodapop2", "x-", 34, "0 -56 -184", "1 56 0", "-3209 1920 288" );
make_brush( "_losfix_lightpanel",	"-100 -15 -2",	"90 15 2",	"-2299 2124 130" );
make_brush( "_losfix_plywood1",		"-1 -52 -5",	"1 52 5",	"-2846 2934 -255" );
make_brush( "_losfix_plywood2",		"-1 -52 -3",	"1 52 3",	"-1303 3098 -253" );
make_brush( "_losfix_scaffolding1a",		"-1 -74 -30",	"1 36 30",	"-1988 2489 -83" );
make_brush( "_losfix_scaffolding1b",		"-1 -60 -30",	"1 36 30",	"-1804 2489 -83" );
make_brush( "_losfix_scaffolding1c",		"-84 -1 -30",	"98 1 0",	"-1903 2524 -83" );
make_brush( "_losfix_scaffolding2a",		"-1 -74 -30",	"1 36 30",	"-2668 2489 -83" );
make_brush( "_losfix_scaffolding2b",		"-1 -60 -30",	"1 36 30",	"-2852 2489 -83" );
make_brush( "_losfix_scaffolding2c",		"-84 -1 -30",	"98 1 0",	"-2767 2524 -83" );
make_brush( "_losfix_start_trailer1",	"-104 -1 -8",	"104 1 8",	"-3740 3292 -248" );
make_brush( "_losfix_start_trailer2",	"-104 -1 -8",	"104 1 8",	"-4097 3304 -248" );
make_clip( "_axiswarp_anvilcase_clip", "SI Players", 1, "-64 0 0", "64 1 128", "-2304 2456 -224" );
make_clip( "_axiswarp_sodapop1_clip", "SI Players", 1, "0 -56 0", "1 56 184", "-1399 1920 104" );
make_clip( "_axiswarp_sodapop2_clip", "SI Players", 1, "0 -56 0", "1 56 184", "-3210 1920 104" );
make_clip( "_missing_staircase_clip", "Everyone", 1, "-40 -40 -1", "40 40 40", "-922 1933 173", "0 315 0" );
make_clip( "_smoother_windows", "SI Players and AI", 1, "-250 -32 0", "298 32 8", "-609 2387 329", "0 45 30" );
make_ladder( "_ladder_fencedperch_cloned_scaffoldsingle", "-2976 3198 -152", "-910 259 304" );
make_ladder( "_ladder_fireworksL_cloned_scaffoldsinglefork", "-2980 3298 -152", "771 -834 4" );
make_ladder( "_ladder_fireworksR_cloned_scaffoldsinglefork", "-2980 3298 -152", "581 -834 4" );
make_ladder( "_ladder_leftchopperwindowl_cloned_leftchopperwindowr", "-763.5005 2285.4995 240", "263 263 0" );
make_ladder( "_ladder_startfenceback_cloned_fencecoverfront", "-3444 3528 -188", "3838 2073 5", "0 43.5 0", "0.7 0.7 0" );
make_ladder( "_ladder_startfencefront_cloned_fencecoverback", "-3468 3592 -188", "3857 2072 5", "0 43.5 0", "-0.7 -0.7 0" );
make_prop( "dynamic", "_missing_staircase", "models/props_interiors/stair_metal_02.mdl", "-840 1792 136", "0 315 0", "shadow_no" );
make_prop( "dynamic", "_yesdraw_infecteddoorway", "models/props_update/c2m5_infectedroom_doorway.mdl", "-3200 3972 0", "0 90 0", "shadow_yes" );
make_prop( "dynamic", "_yesdraw_infectedroom", "models/props_update/c2m5_infectedroom.mdl", "-3200 3727 0", "0 -90 0", "shadow_yes" );
make_prop( "physics", "_hittable_dumpleft", "models/props_junk/dumpster_2.mdl", "-1551 3682 -255", "0 270 0" );
make_prop( "physics", "_hittable_dumpright", "models/props_junk/dumpster_2.mdl", "-3296 3682 -255", "0 270 0" );

con_comment( "KILL:\tLeft and right defibrillators deleted for Versus. See: https://www.l4d.com/blog/post.php?id=3935" );

kill_entity( Entities.FindByClassnameNearest( "weapon_defibrillator_spawn", Vector( -2667.81, 2358.75, 80.28 ), 8 ) );
kill_entity( Entities.FindByClassnameNearest( "weapon_defibrillator_spawn", Vector( -1812.16, 2326.31, 80.28 ), 8 ) );

con_comment( "KILL:\tExtra pills which are meant to be killed OnVersus but still spawn on 2nd round deleted for Versus." );

kill_entity( Entities.FindByClassnameNearest( "weapon_pain_pills_spawn", Vector( -2534, 3449, -105 ), 6 ) );
kill_entity( Entities.FindByClassnameNearest( "weapon_pain_pills_spawn", Vector( -2526, 3449, -105 ), 6 ) );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*==============================
||                            ||
||        SWAMP FEVER         ||
||                            ||
==============================*/

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c3m1_plankcountry":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

kill_funcinfclip( 1167.82 );		// UNDESIRABLY delete (matching value) unrelated clip but re-make exactly
EntFire( "worldspawn", "RunScriptCode", "kill_funcinfclip( 1167.82 )", 1 );		// Delete clip to left above end trains
kill_funcinfclip( 405.151 );		// Delete clip above middle of end trains
kill_funcinfclip( 699.27 );		// Delete clip to right above end trains
make_axiswarp( "_axiswarp_startspawn", "x+", 64, "0 -2020 0", "1 2000 128", "-13026 9199 191" );
make_brush( "_losfix_start_fence1",	"-32 -1 -5",	"32 1 5",	"-10968 9586 164" );
make_brush( "_losfix_start_fence2",	"-128 -1 -5",	"128 1 5",	"-11264 9665 164" );
make_brush( "_losfix_start_gen1",	"-1 -28 -8",	"1 28 8",	"-11817 9724 175" );
make_brush( "_losfix_start_gen2",	"-15 -1 -8",	"14 1 8",	"-11801 9723 175" );
make_brush( "_losfix_start_semi",	"-1 -56 -20",	"1 40 23",	"-11314 9748 181" );
make_brush( "_losfix_start_train1",	"-230 -2 -12",	"272 2 12",	"-11574 11024 210" );
make_brush( "_losfix_start_train2a",	"-78 -2 -12",	"78 2 12",	"-12154 10858 210" );
make_brush( "_losfix_start_train2b",	"-2 -45 -12",	"2 45 12",	"-12075 10905 210" );
make_brush( "_losfix_start_train3a",	"-4 -30 -12",	"4 62 12",	"-12658 10287 210" );
make_brush( "_losfix_start_train3b",	"-45 -2 -12",	"45 2 12",	"-12609 10351 210" );
make_brush( "_losfix_start_train3c",	"-2 -79 -12",	"2 79 12",	"-12566 10432 210" );
make_brush( "_losfix_start_train3d",	"-2 -79 -12",	"2 79 12",	"-12476 10590 210" );
make_brush( "_losfix_start_train3e",	"-45 -2 -12",	"45 2 12",	"-12519 10509 210" );
make_brush( "_losfix_start_train4a",	"-4 -128 -12",	"4 95 12",	"-12725 10059 210" );
make_brush( "_losfix_start_train4b",	"-4 -95 -12",	"4 139 12",	"-12815 9792 210" );
make_brush( "_losfix_start_train4c",	"-45 -2 -12",	"45 2 12",	"-12766 9929 210" );
make_brush( "_losfix_start_train5a",	"-2 -139 -12",	"2 95 12",	"-12844 9464 210" );
make_brush( "_losfix_start_train5b",	"-45 -2 -12",	"45 2 12",	"-12795 9327 210" );
make_brush( "_losfix_start_train5c",	"-2 -128 -12",	"2 128 12",	"-12754 9197 210" );
make_clip( "_ladder_earlsgatorvillage_clip", "Everyone", 1, "-5 -2 0", "2 32 222", "-7462 7696 32" );
make_clip( "_meticulous_funcinfclip01", "SI Players", 1, "-1053 -17 -123", "1029 17 935", "-484 9840 90" );
make_clip( "_meticulous_funcinfclip02", "SI Players", 1, "-733 -8 0", "640 8 768", "-2668 416 256" );
make_clip( "_meticulous_funcinfclip03", "SI Players", 1, "-198 -16 0", "198 16 961", "-3516 543 61", "0 -50 0" );
make_clip( "_meticulous_funcinfclip04", "SI Players", 1, "-198 -16 0", "1375 16 961", "-1846 433 61", "0 10 0" );
make_clip( "_starttrains_badredclip", "SI Players", 1, "-64 -36 -24", "64 36 -17", "-12728 9028 216", "0 -48 0" );
make_ladder( "_ladder_bridgetunnelleft_cloned_shacklegback", "-427 7088 76", "-505 -2151 116" );
make_ladder( "_ladder_bridgetunnelright_cloned_shacklegfront", "-579 7088 76", "-537 -2151 116" );
make_ladder( "_ladder_earlsgatorvillage_cloned_goodbuyautoparts", "-11522 8784 286", "4059 -1114 -117" );
make_ladder( "_ladder_endtrainsB_cloned_boardwalkleg", "-824 6181 74", "-1651 -4774 -2541", "0 0 25" );
make_ladder( "_ladder_endtrainsT_cloned_boardwalkleg", "-824 6181 74", "-1635 -5533 266" );
make_ladder( "_ladder_endtrainsback_cloned_boardwalkleg", "-824 6181 74", "-3494 6691 267", "0 -180 0", "0 -1 0" );
make_ladder( "_ladder_gaschainlinkin_cloned_gaschainlinkout", "-10946 9152 228", "-577 480 0" );
make_ladder( "_ladder_jonescar_cloned_goodbuyautoparts", "-6496 6202 170", "-14704 13713 -6", "0 180 0", "0 1 0" );
make_ladder( "_ladder_jonesvines_cloned_railroadgate", "-11658 10272 255.354", "3079 -2960 -120" );
make_ladder( "_ladder_rightafterchains_cloned_railroadgate", "-11658 10272 255.354", "1539 -1572 -24" );
make_ladder( "_ladder_startsemirear_cloned_boardwalkhole", "-551 7596 74", "-9373 2500 172" );
make_ladder( "_ladder_startsemitire_cloned_boardwalkhole", "-551 7596 74", "-16047 4401 168", "0 -46 0", "0.69 -0.72 0" );
make_ladder( "_ladder_starttrainfront1_cloned_boardwalkhole", "-551 7596 74", "-15700 3747 209", "0 -30 0", "0.87 -0.5 0" );
make_ladder( "_ladder_starttrainfront2_cloned_boardwalkhole", "-551 7596 74", "-11159 2086 209", "0 8 0", "1 0.16 0" );
make_ladder( "_ladder_starttrainvalve_cloned_starttrainyellow", "-12837 9094 299.0643", "2575 13964 0", "0 49 0", "-0.5 -0.86 0" );
make_navblock( "_nav_startshrubwall1", "Everyone", "Apply", "-24 -24 -24", "24 24 24", "-12524 10074 161" );
make_navblock( "_nav_startshrubwall2", "Everyone", "Apply", "-48 -16 -32", "48 16 32", "-12588 9075 168" );
make_navblock( "_nav_oldtree1", "Everyone", "Apply", "-24 -16 -32", "24 16 32", "-3447 8260 0" );
make_navblock( "_nav_oldtree2", "Everyone", "Apply", "-24 -16 -32", "24 16 32", "-4225 8490 0" );
make_prop( "dynamic", "_cosmetic_shruba",	"models/props_foliage/swamp_shrubwall_512_deep.mdl", "-2695 280 250", "0 90 0", "shadow_no", "solid_no" );
make_prop( "dynamic", "_cosmetic_shrubb",	"models/props_foliage/swamp_shrubwall_512_deep.mdl", "-3153 295 250", "0 86 0", "shadow_no", "solid_no" );
make_prop( "dynamic", "_cosmetic_shrubc",	"models/props_foliage/swamp_shrubwall_512_deep.mdl", "-2242 295 250", "0 94 0", "shadow_no", "solid_no" );
make_prop( "dynamic",		"_propladder_plank",		"models/props_swamp/plank001b_192.mdl",		"-6791 7712 200",		"0 270 -25.5" );
make_prop( "dynamic", "_losblocker_oldtree1", "models/props_foliage/old_tree01.mdl", "-3447 8298 -12", "0 -2 0", "shadow_no" );
make_prop( "dynamic", "_losblocker_oldtree2", "models/props_foliage/old_tree01.mdl", "-4212 8550 -12", "0 -2 0", "shadow_no" );
make_prop( "dynamic", "_endsaferoom_wrongwaya", "models/props_misc/wrongway_sign01_optimized.mdl", "-3415 430 320", "0 0 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_endsaferoom_wrongwayb", "models/props_misc/wrongway_sign01_optimized.mdl", "-3510 535 485", "0 0 0", "shadow_no", "solid_no", "255 255 255", "17", "270" );
make_prop( "dynamic", "_solidify_startshrubwall1", "models/props_foliage/swamp_shrubwall_block_128_deep.mdl", "-12543.6 10072.5 181.932", "-5 180 3", "shadow_no" );
make_prop( "dynamic", "_solidify_startshrubwall2", "models/props_foliage/swamp_shrubwall_block_128_deep.mdl", "-12550.2 9119.21 148.872", "0 90 0", "shadow_no" );
make_prop( "dynamic", "_start_fencea",	"models/props_urban/fence_cover001_256.mdl", "-11265 9665 167.25", "0 270 0", "shadow_no" );
make_prop( "dynamic", "_start_fenceb",	"models/props_urban/fence_cover001_64.mdl", "-10968 9586.1 167.25", "0 270 0", "shadow_no" );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c3m2_swamp":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

make_brush( "_losfix_end_gen1",		"-20 -1 -8",	"20 1 8",	"8011 2779 128" );
make_brush( "_losfix_end_gen2",		"-1 -13 -8",	"1 12 8",	"8007 2793 128" );
make_clip( "_propladder_crate_qol", "SI Players", 1, "-36 -2 -8", "44 4 8", "8055 100 166", "0 27 0" );
make_ladder( "_ladder_brokenhomeleft_cloned_airplanewingmini", "-1690.5 2951.13 38.3488", "-2031 6319 98", "0 93.74 0", "1 0 0" );
make_ladder( "_ladder_brokenhomeright_cloned_airplanewingmini", "-1690.5 2951.13 38.3488", "-2030.5 6344 98", "0 93.74 0", "1 0 0" );
make_ladder( "_ladder_corrugatedhome_cloned_airplaneleft", "-2060 3278 96", "3919.22 26.78 66" );
make_ladder( "_ladder_crashedplanetail_cloned_crashedplaneright", "-2060.0002 2942.0005 102", "1558 994 -28", "0 33.5 0", "-0.83 -0.55 0" );
make_ladder( "_ladder_endbarricadeleft1_cloned_airplaneleft", "-2060 3278 96", "4940 -1169 88", "0 -100 0", "0.17 0.98 0" );
make_ladder( "_ladder_endbarricadeleft2_cloned_airplaneleft", "-2060 3278 96", "4962 -1169 88", "0 -100 0", "0.17 0.98 0" );
make_ladder( "_ladder_endbarricaderight1_cloned_airplaneleft", "-2060 3278 96", "4775 -1169 88", "0 -100 0", "0.17 0.98 0" );
make_ladder( "_ladder_endbarricaderight2_cloned_airplaneleft", "-2060 3278 96", "4753 -1169 88", "0 -100 0", "0.17 0.98 0" );
make_ladder( "_ladder_endfence_cloned_airplaneleft", "-2060 3278 96", "9772 -3705 32" );
make_ladder( "_ladder_finalhome_cloned_airplaneleft", "-2060 3278 96", "4611 4947 -37", "0 180 0", "1 0 0" );
make_prop( "dynamic",		"_propladder_endcratea",	"models/props_crates/static_crate_40.mdl",	"8045 79 118.63",		"0 221.5 0",		"shadow_no" );
make_prop( "dynamic",		"_propladder_endcrateb",	"models/props_crates/static_crate_40.mdl",	"8083 102 118.63",		"0 297 0",		"shadow_no" );
make_prop( "dynamic", "_ladder_corrugatedhome_panel", "models/props_highway/corrugated_panel_damaged_01.mdl", "1855 3334 82", "80 180 2", "shadow_no" );
make_prop( "physics",	"_hittable_fallentree",	"models/props_foliage/swamp_fallentree01_bare.mdl",	"3225 1879 1",		"0 -34 0" );
make_prop( "dynamic", "_propladder_endsaferoof1", "models/props_crates/static_crate_40.mdl", "7777 -603 126", "0 0 0", "shadow_no" );
make_prop( "dynamic", "_propladder_endsaferoof2", "models/props_crates/static_crate_40.mdl", "7775 -646 126", "0 -83 0", "shadow_no" );
make_prop( "dynamic", "_propladder_endsaferoof3", "models/props_crates/static_crate_40.mdl", "7775 -646 166", "0 -187 0", "shadow_no" );
make_prop( "dynamic", "_solidify_endtreegiant", "models/props_foliage/urban_tree_giant01.mdl", "7849 -791 126.481", "0 203.16 0", "shadow_no" );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c3m3_shantytown":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

kill_funcinfclip( 1392.94 );		// Delete clip behind saferoom stretching the orange fences introducing no exploits
make_brush( "_losfix_endhaybailsa",	"-8 -64 0",	"8 70 50",	"5125 -3966.5 350" );
make_brush( "_losfix_endhaybailsb",	"-8 -26 0",	"8 22 30",	"5125 -3966.5 402" );
make_brush( "_losfix_opening_gen",	"-20 -1 -10",	"20 1 10",	"-4385 -2721 131" );
make_brush( "_losfix_opening_trailer",	"-100 -1 -15",	"100 1 15",	"-3332 417 -1" );
make_brush( "_losfix_start_truck1",	"-45 -1 -12",	"45 1 12",	"-5171 1649 139" );
make_brush( "_losfix_start_truck2",	"-1 -45 -12",	"1 46 12",	"-5214 1602 139" );
make_clip(	"_endhaybails_collisiona",	"SI Players",	1,	"-42 -66 -24",		"42 66 24",		"5126 -3967 378" );
make_clip(	"_endhaybails_collisionb",	"SI Players",	1,	"-42 -25 -24",		"42 25 24",		"5126 -3967 426" );
make_clip( "_ladder_afterplankfront_clip", "SI Players", 1, "7 -154 16", "15 43 32", "381 -4026 79" );
make_clip( "_ladder_endsafehousetall_clip", "Everyone", 1, "-8 -16 0", "13 16 264", "4754 -3718 209" );
make_clip( "_ladder_longtiltedlog_clipbot", "SI Players", 1, "-19 -16 0", "19 10 17", "-4037 -867 -21", "0 64 -77" );
make_clip( "_ladder_longtiltedlog_cliptop", "SI Players", 1, "-19 -16 0", "19 10 17", "-4103 -835 268", "0 64 -60" );
make_clip( "_ladder_plankhomeroof_clipleft", "Everyone", 1, "-8 5 -124", "13 6 105", "59 -4103 109", "0 45 0" );
make_clip( "_ladder_plankhomeroof_clipright", "Everyone", 1, "-8 5 -1", "13 6 105", "33 -4099 109", "0 -45 0" );
make_clip( "_ladder_startsafehouse_solidify", "SI Players", 1, "-87 -50 0", "78 35 16", "-5948 1913 244" );
make_ladder( "_ladder_afterplankfront_cloned_afterplankback", "795 -4272 104", "1185 -8350 -10", "0 -180 0", "-1 0 0" );
make_ladder( "_ladder_boatpanel_cloned_metalfence", "-4411 1178 136", "64 -1898 -85" );
make_ladder( "_ladder_bridgehouseB_cloned_logfencefirst", "-4256 132 69", "-6200 -577.1 -58", "0 -180 0", "0 -1 0" );
make_ladder( "_ladder_bridgehouseT_cloned_firebarrelhouse", "-3290 -1704 51.5", "1241 1035 50" );
make_ladder( "_ladder_bugnethome_cloned_metalfence", "-4411 1178 136", "-10133 -677 7", "0 -180 0", "0 -1 0" );
make_ladder( "_ladder_endsafehousetall_cloned_buglampoon", "-3984 -2900 117", "1843 266 224", "0 90 0", "-1 0 0" );
make_ladder( "_ladder_eventstartlowground_cloned_startshantyshop", "-4900 1094 229", "5267 -5587 -230" );
make_ladder( "_ladder_eventmidlowground_cloned_gunshackback", "-3756 -3241 53", "4337 -1130 -18" );
make_ladder( "_ladder_eventendlowground_cloned_gunshackback", "-3756 -3241 53", "4995 -315 -44" );
make_ladder( "_ladder_gonefishing_cloned_tallstartarea", "-5539 306 229", "-5864, -6927, -52", "0 -90 0", "0 1 0" );
make_ladder( "_ladder_logfencenext_cloned_logfencefirst", "-4256 132 69", "-699 -2893 -40", "0 -40.35 0", "0.64 0.76 0" );
make_ladder( "_ladder_longtiltedlog_cloned_privateproperty", "-3984 -3272 117", "-5224 4145 -438", "0 64 -8", "0.9 -0.45 0" );
make_ladder( "_ladder_mehsurvival_cloned_startouthouse", "-5121 306 229", "-2386 -5650 -136", "0 -74.77 0", "0.26 -0.97 0" );
make_ladder( "_ladder_outhouseroof_cloned_metalfence", "-4411 1178 136", "-1263 -4067 42", "0 -0.14 0", "0 1 0" );
make_ladder( "_ladder_plankhomeroof_cloned_afterplankback", "795 -4272 104", "-4224 -4882 6", "0 90 0", "0 1 0" );
make_ladder( "_ladder_safehouselow_cloned_highgenerator", "-4504 -2644 41", "9230 -881 238" );
make_ladder( "_ladder_shortcuttrailerfront_cloned_shortcuttrailerback", "-3949 -2333 81.0389", "-7827 -4970 -8", "0 -174.6 0", "-1 0 0" );
make_ladder( "_ladder_smalltrailerlogs_cloned_startsmalltrailer", "-5813.92 1030.64 192", "-2866 5580 -132", "0 90 0", "-0.26 -0.96 0" );
make_ladder( "_ladder_startbehindrooftop_cloned_startshantyshop", "-4900 1510 229", "277 -1 0" );
make_ladder( "_ladder_startnodrawfence_cloned_shantyshop", "-4900 1510 229", "-487.218 532.125 0" );
make_ladder( "_ladder_startpicketqol_cloned_startpicketroof", "-4660 643 205.5", "-3999 4832 -43", "0 90 0", "-1 0 0" );
make_ladder( "_ladder_startsafehouse_cloned_highgenerator", "-4504 -2644 41", "-9209 5970 128", "0 97.7 0", "0.13 -1 0" );
make_ladder( "_ladder_tarptrailerwood_cloned_startouthouse", "-5121 306 229", "200 -1056 -175" );
make_prop( "dynamic", "_permstuck_cratebot", "models/props_crates/static_crate_40.mdl", "-3749.85 -183.67 -3.164", "0 0 0" );
make_prop( "dynamic", "_permstuck_cratetop", "models/props_crates/static_crate_40.mdl", "-3749.85 -182.67 36.837", "0 -30 0" );
make_prop( "dynamic", "_yesdraw_nodrawfence", "models/props_update/c3m3_nodrawfence.mdl", "-5212 1765 213.5", "0 -90 0", "shadow_no", "solid_no" );
make_prop( "dynamic_ovr", "_ladder_mehsurvival_boat", "models/props_canal/boat001a.mdl", "-3438 -612 42", "95 15 90", "shadow_no" );
make_prop( "physics",		"_hittable_fallentree",		"models/props_foliage/swamp_fallentree01_bare.mdl",	"-3935 -1120 -11",		"0 34 0" );
patch_ladder( "-4304 -194 88.5", "0 -3 0" );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c3m4_plantation":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

make_brush( "_brickhome_chimney1_losblock", "-11 -19 0", "11 19 77", "-1779 -3712 454" );
make_brush( "_brickhome_chimney2_losblock", "-11 -19 0", "11 19 77", "-1298 -3712 454" );
make_brush( "_losfix_start_truck1",	"-54 -1 -12",	"54 1 12",	"-1733 -2751 10" );
make_brush( "_losfix_start_truck2",	"-1 -55 -12",	"1 54 12",	"-1785 -2695 10" );
make_clip( "_brickhome_chimney1_collision", "Everyone", 1, "-11 -19 0", "11 19 77", "-1779 -3712 454" );
make_clip( "_brickhome_chimney2_collision", "Everyone", 1, "-11 -19 0", "11 19 77", "-1298 -3712 454" );
make_clip( "_ladder_houselow_clipl", "Everyone", 1, "-8 -2 0", "12 4 136", "-2054 -1026 1", "0 -45 0" );
make_clip( "_ladder_houselow_clipr", "Everyone", 1, "-3 -2 0", "16 4 136", "-2012 -1032 1", "0 45 0" );
make_ladder( "_ladder_backwhitefence_cloned_brickhomeB", "-1036 -3438 84", "565 368 -42" );
make_ladder( "_ladder_brickhomeT_cloned_brickhomeB", "-1036 -3438 84", "2166 -4668 255", "0 -90 0", "1 0 0" );
make_ladder( "_ladder_brickhomeside_cloned_brickhomeB", "-1036 -3438 84", "2501 -4927 -32", "0 -90 0", "1 0 0" );
make_ladder( "_ladder_campscaffold_cloned_brickhomeB", "-1036 -3438 84", "1752 3509 248" );
make_ladder( "_ladder_dumpsterscaffold_cloned_brickhomeB", "-1036 -3438 84", "1418 -4324 224", "0 -180 0", "0 -1 0" );
make_ladder( "_ladder_enclosedhedges_cloned_brickhomeB", "-1036 -3438 84", "775 -322 -32" );
make_ladder( "_ladder_escapepillar_cloned_escapeback", "1880 2058 192", "3688 4089.5 2", "0 -180 0", "0 -1 0" );
make_ladder( "_ladder_househigh_cloned_cornerwhite", "3082 1856 192", "-5251 -2782 90" );
make_ladder( "_ladder_houselow_cloned_treeright", "2368 1516 188", "-4398 -2547 -111" );
make_ladder( "_ladder_logpileup_cloned_brickhomeB", "-1036 -3438 84", "-1656 -6509 40", "0 -180 0", "0 -1 0" );
make_ladder( "_ladder_mansionchoose_cloned_brickhomeB", "-1036 -3438 84", "244 -4594 135", "0 -180 0", "0 -1 0" );
make_ladder( "_ladder_moundhole_cloned_minigunleft", "1948 466 296", "4194 443 64", "0 -180 0", "0 -1 0" );
make_ladder( "_ladder_parkourattic_cloned_shortesthedge", "1984 1618 160", "-277 -1860 424" );
make_ladder( "_ladder_shelfpileleft_cloned_minigunleft", "1948 466 296", "-721 -1018 48" );
make_ladder( "_ladder_shelfpileright_cloned_minigunright", "1376 466 296", "2598 515 48", "0 -180 0", "0 -1 0" );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*==============================
||                            ||
||         HARD RAIN          ||
||                            ||
==============================*/

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c4m1_milltown_a":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

make_brush( "_losfix_ambulance1",	"-90 -1 -8",	"91 1 8",	"711 4748 102" );
make_brush( "_losfix_ambulance2",	"-1 -56 -8",	"1 57 8",	"803 4690 102" );
make_brush( "_losfix_burger_gen",	"-24 -1 -8",	"24 1 8",	"-5448 6765 107" );
make_brush( "_losfix_dumpster",		"-185 -1 -8",	"185 1 8",	"3550 343 128" );
make_brush( "_losfix_gen1",		"-28 -1 -10",	"28 1 10",	"241 5987 107" );
make_brush( "_losfix_gen2",		"-22 -1 -8",	"22 1 8",	"3448 -1345 113" );
make_brush( "_losfix_semia",		"-40 -1 -15",	"40 1 15",	"-4771 7156 113" );
make_brush( "_losfix_semib",		"-1 -34 -15",	"1 40 15",	"-4790 7180 113" );
make_brush( "_losfix_trailer1",		"-1 -48 -10",	"1 48 10",	"-3370 7548 106" );
make_brush( "_losfix_trailer2",		"-56 -1 -10",	"57 1 10",	"-3428 7594 106" );
make_brush( "_losfix_trailer3",		"-86 -1 -10",	"86 1 10",	"-3510 7618 106" );
make_brush( "_losfix_truck",		"-62 -1 -10",	"62 1 10",	"3217 -1376 114" );
make_brush( "_losfix_truck_jump",	"-70 -1 -10",	"70 1 10",	"2949 2885 108" );
make_clip( "_ladder_dumpsterhouse_clip", "Everyone", 1, "-8 -16 0", "26 8 168", "1638 4032 217", "0 45 0" );
make_clip( "_ladder_safehousetall_clip", "SI Players", 1, "-20 -2 -2", "8 2 310", "3725 -1537 101", "0 45 0" );
make_clip( "_ladder_sweetrelief_clip", "Everyone", 1, "-8 -16 0", "8 9 212", "-5746 6595 96", "0 53 0" );
make_clip( "_ladder_yellowhousetree_topdenial", "SI Players", 1, "-8 -32 0", "8 32 62", "2244 3123 378", "-7 0 0" );
make_clip( "_playgroundhouse_clip", "Survivors", 1, "-54 -177 -35", "635 176 1176", "-2074 7312 360" );
make_clip( "_safehousehedge_blocker", "SI Players", 1, "-690 -122 -20", "139 93 2122", "4401 -2207 438" );
make_ladder( "_ladder_autosalvagefront_cloned_playgroundroof", "-2041.58 7141.5 215.154", "-4077 930 8" );
make_ladder( "_ladder_classyjimboblue_cloned_garagesalehouse", "2468 2634 184", "-6814 4053 0" );
make_ladder( "_ladder_cornerhomeplants_cloned_garagesalehome", "2468 2634 184", "3773 4652 128", "0 90 0", "-1 0 0" );
make_ladder( "_ladder_cornerhometankfight_cloned_treehousefence", "2058.5 2999.08 151.11", "1958 155 0" );
make_ladder( "_ladder_cullingsub_cloned_cullingbuddy", "-4083 7580 170", "-11738 3696 -9", "0 -90 0", "0 -1 0" );
make_ladder( "_ladder_dumpsterhouse_cloned_alarmtrailer", "677.5 2966 212.223", "-1309 4697 88", "0 270 0", "0 -1 0" );
make_ladder( "_ladder_finalhouse_cloned_yellowhouse", "3510.5 917 182.881", "2993 3583 -14", "0 -90 0", "0 1 0" );
make_ladder( "_ladder_gaselecbox_cloned_autosalvageback", "-5876.19 8673.97 236.888", "4059 13901 -58", "0 90 0", "-1 0 0" );
make_ladder( "_ladder_grocerypillar_cloned_garagesalehouse", "2468 2634 184", "-8299 8596 5", "0 -90 0", "1 0 0" );
make_ladder( "_ladder_mobilepickup_cloned_alarmtrailer", "677.5 2966 212.223", "1675 8269 -36", "0 -180 0", "-1 0 0" );
make_ladder( "_ladder_safehousefenceback_cloned_cullingbuddy", "-4083 7580 170", "7421 -9698 -9" );
make_ladder( "_ladder_safehousetall_cloned_tallbuildingleft", "-885 5961 269.556", "9680 -675 -26", "0 90 0", "-1 0 0" );
make_ladder( "_ladder_saferoofpipe_cloned_tallbuildingleft", "-885 5961 269.556", "9680 -880 -26", "0 90 0", "-1 0 0" );
make_ladder( "_ladder_sweetrelief_cloned_autosalvageback", "-5876.19 8673.97 236.888", "112 -2069 -56" );
make_ladder( "_ladder_tallbuildingright_cloned_tallbuildingleft", "-885 5961 269.557", "5057 6467 -2", "0 90 0", "-1 0 0" );
make_ladder( "_ladder_trailerqol_cloned_alarmtrailer", "677.5 2966 212.223", "2555 3388 -66", "0 66 0", "0.4 0.9 0" );
make_ladder( "_ladder_vinehouseqol_cloned_alarmtrailer", "677.5 2966 212.223", "-3107 6241 -32", "0 -90 0", "0 -1 0" );
make_ladder( "_ladder_woodhouseqol_cloned_alarmtrailer", "677.5 2966 212.223", "2908 4383 -40", "0 90 0", "0 1 0" );
make_ladder( "_ladder_yellowhousetree_cloned_playgroundgutter", "-2041.58 7141.5 215.154", "9311 5106 -851", "3 90 6", "1 0 0" );
make_prop( "dynamic", "_ladder_finalhouse_pipe", "models/props_downtown/gutter_downspout_straight_160_02.mdl", "3910 71 248", "0 90 0", "shadow_no" );
make_prop( "dynamic", "_ladder_grocerypillar_bust", "models/props_interiors/concretepillar01_dm_base.mdl", "-5680 6576 160.2", "0 0 0", "shadow_no" );
make_prop( "dynamic", "_ladder_grocerypillar_prop", "models/props_interiors/concretepillar01.mdl", "-5680 6128 163.8", "0 0 0", "shadow_no" );
make_prop( "dynamic", "_ladder_safehouse_pipe", "models/props_pipes/PipeSet02d_512_001a.mdl", "3726 -1560 160", "-90 90 0", "shadow_no", "solid_no" );
make_prop( "dynamic", "_ladder_saferoofpipe_pipe", "models/props_mill/PipeSet08d_512_001a.mdl", "3726 -1765 158", "90 90 0", "shadow_no" );

EntFire( g_UpdateName + "_ladder_grocerypillar_prop", "AddOutput", "OnBreak anv_mapfixes_ladder_grocerypillar_cloned_garagesalehouse:Kill::0:-1" );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c4m2_sugarmill_a":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

make_brush( "_losfix_gas_truck",	"-1 -75 -12",	"1 75 12",	"-572 -13262.9 133" );
make_brush( "_losfix_gen",		"-1 -20 -8",	"1 20 8",	"-1390 -13156 125" );
make_brush( "_losfix_trailer1",		"-1 -81 -20",	"1 80 15",	"1219 -4171 120" );
make_brush( "_losfix_trailer2",		"-72 -1 -20",	"72 1 18",	"1149 -4253 116" );
make_brush( "_losfix_trailer3",		"-72 -1 -20",	"72 1 20",	"1074 -4342 116" );
make_brush( "_losfix_truck",		"-1 -70 -12",	"1 70 12",	"4106 -2935 115" );
make_clip( "_ladder_parkourouthouse_clip", "SI Players", 1, "-31 -28 0", "29 29 10", "1017 -4471 200", "0 15 0" );
make_ladder( "_ladder_ducatelelecbox_cloned_ducateldumpsters", "-1586.2 -13843.5 218.25", "11911 -15404 0", "0 -90 0", "-1 0 0" );
make_ladder( "_ladder_ducatelroofl_cloned_brokenlocker", "2756 -3833.5 392.25", "-5049 -16360 0", "0 90 0", "-1 0 0" );
make_ladder( "_ladder_ducatelroofr_cloned_brokenlocker", "2756 -3833.5 392.25", "-5049 -16410 0", "0 90 0", "-1 0 0" );
make_ladder( "_ladder_grindergirder_cloned_bricksemitrailer", "4319.5 -3675.85 264.25", "-1856 -1939 -23" );
make_ladder( "_ladder_jaggedchainlinkback1_cloned_stacksfenceback", "258 -4883.67 156.145", "4269 -10900 -19", "0 180 0", "0 0 1" );
make_ladder( "_ladder_jaggedchainlinkback2_cloned_stacksfenceback", "258 -4883.67 156.145", "4269 -10550 -19", "0 180 0", "0 0 1" );
make_ladder( "_ladder_jaggedchainlinkfront_cloned_stacksfenceback", "258 -4883.67 156.145", "3750 -1083 -19" );
make_ladder( "_ladder_parkourouthouse_cloned_rubbleshortpipe", "1988.06 -4910.53 164.268", "-2152 -260 -33", "0 14.76 0", "0.26 -0.97 0" );
make_ladder( "_ladder_parkoursiloleft_cloned_marshtrailer", "-74.9665 -7000.47 202.25", "-728 -10692 139", "0 162.42 0", "-0.94 -0.34 0" );
make_ladder( "_ladder_parkoursiloright_cloned_marshtrailer", "-74.9665 -7000.47 202.25", "-717 -10720 139", "0 162.42 0", "-0.94 -0.34 0" );
make_ladder( "_ladder_pipeyardsemi_cloned_millgrinder", "2001.5 -5712 273.75", "9997 -1842 -98", "0 -90 0" "0 -1 0" );
make_ladder( "_ladder_saferoofpipe_cloned_bricksemitrailer", "4319.5 -3675.85 264.25", "7776 -5566 -8", "0 180 0", "-1 0 0" );
make_ladder( "_ladder_siloplatform_cloned_grinderwheel", "1080.5 -6085.5 237.133", "1839 -12326.5 -2", "0 180 0", "1 0 0" );
make_ladder( "_ladder_silosemirearleft_cloned_millgrinder", "2001.5 -5712 273.75", "-3643 -11764 -75", "0 128 0" "-0.6 0.8 0" );
make_ladder( "_ladder_silosemirearright_cloned_millgrinder", "2001.5 -5712 273.75", "-3946 -11936 -75", "0 128 0" "-0.6 0.8 0" );
make_ladder( "_ladder_stacksfencefront_cloned_stacksfenceback", "258 -4883.67 156.145", "524 -9863 0", "0 180 0" "0 0 1" );
make_ladder( "_ladder_talleventpillar1_cloned_talleventpipe", "-1497 -9117.13 400.25", "-10269 -7652 0", "0 90 0" "0 1 0" );
make_ladder( "_ladder_talleventpillar2_cloned_talleventpipe", "-1497 -9117.13 400.25", "7965 -10268 0", "0 -90 0" "0 -1 0" );
make_ladder( "_ladder_tallspoolsroofleft_cloned_bigwindowspipe", "2369.33 -4846.5 302.25", "-1722 -2626 -76" );
make_ladder( "_ladder_tallspoolsroofright_cloned_bigwindowspipe", "2369.33 -4846.5 302.25", "3017 -13262 -71", "0 -180  0", "0 -1 0" );
make_ladder( "_ladder_tallvinereturn_cloned_brokenlocker", "2756 -3833.5 392.25", "3907 -9165 19", "0 -180 0", "0 -1 0" );
make_ladder( "_ladder_tankescape_cloned_bricksemitrailer", "4319.5 -3675.85 264.25", "-3231 -9632 -64", "0 90 0", "0 1 0" );
make_ladder( "_ladder_tankreturn_cloned_bricksemitrailer", "4319.5 -3675.85 264.25", "4730 -9078 -23", "0 -180 0", "-1 0 0" );
make_ladder( "_ladder_thimblesemi_cloned_millgrinder", "2001.5 -5712 273.75", "5981 -6400 -98", "0 -91.48 0" "0 -1 0" );
make_ladder( "_ladder_truckfencereturn_cloned_stacksfenceback", "258 -4883.67 156.145", "4551 -7959 1", "0 180 0" "1 0 0" );
make_prop( "dynamic", "_ladder_saferoofpipe_pipe", "models/props_mill/PipeSet08d_512_001a.mdl", "3466 -1891 158", "90 90 0", "shadow_no" );
patch_ladder( "1143.5 -5515.5 226", "0 5 0" );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c4m3_sugarmill_b":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

make_brush( "_losfix_gas_truck",	"-1 -75 -12",	"1 75 12",	"-572 -13262.9 133" );
make_brush( "_losfix_gen",		"-1 -20 -8",	"1 20 8",	"-1390 -13156 125" );
make_brush( "_losfix_trailer1",		"-1 -81 -20",	"1 80 15",	"1219 -4171 120" );
make_brush( "_losfix_trailer2",		"-72 -1 -20",	"72 1 18",	"1149 -4253 116" );
make_brush( "_losfix_trailer3",		"-72 -1 -20",	"72 1 20",	"1074 -4342 116" );
make_brush( "_losfix_truck",		"-1 -70 -12",	"1 70 12",	"4106 -2935 115" );
make_ladder( "_ladder_ducatelelecbox_cloned_ducateldumpsters", "-1586.2 -13843.5 218.25", "11911 -15404 0", "0 -90 0", "-1 0 0" );
make_ladder( "_ladder_ducatelroofl_cloned_brokenlocker", "2756 -3833.5 392.25", "-5049 -16360 0", "0 90 0", "-1 0 0" );
make_ladder( "_ladder_ducatelroofr_cloned_brokenlocker", "2756 -3833.5 392.25", "-5049 -16410 0", "0 90 0", "-1 0 0" );
make_ladder( "_ladder_grindergirder_cloned_bricksemitrailer", "4319.5 -3675.85 264.25", "-1856 -1939 -23" );
make_ladder( "_ladder_jaggedchainlinkback1_cloned_stacksfenceback", "258 -4883.67 156.145", "4269 -10900 -19", "0 180 0", "0 0 1" );
make_ladder( "_ladder_jaggedchainlinkback2_cloned_stacksfenceback", "258 -4883.67 156.145", "4269 -10550 -19", "0 180 0", "0 0 1" );
make_ladder( "_ladder_jaggedchainlinkfront_cloned_stacksfenceback", "258 -4883.67 156.145", "3750 -1083 -19" );
make_ladder( "_ladder_parkourouthouse_cloned_rubbleshortpipe", "1988.06 -4910.53 164.268", "-2152 -260 -33", "0 14.76 0", "0.26 -0.97 0" );
make_ladder( "_ladder_parkoursiloleft_cloned_marshtrailer", "-74.9665 -7000.47 202.25", "-728 -10692 139", "0 162.42 0", "-0.94 -0.34 0" );
make_ladder( "_ladder_parkoursiloright_cloned_marshtrailer", "-74.9665 -7000.47 202.25", "-717 -10720 139", "0 162.42 0", "-0.94 -0.34 0" );
make_ladder( "_ladder_pipeyardsemi_cloned_millgrinder", "2001.5 -5712 273.75", "9997 -1842 -98", "0 -90 0" "0 -1 0" );
make_ladder( "_ladder_saferoofpipe_cloned_bricksemitrailer", "4319.5 -3675.85 264.25", "7776 -5566 -8", "0 180 0", "-1 0 0" );
make_ladder( "_ladder_siloplatform_cloned_grinderwheel", "1080.5 -6085.5 237.133", "1839 -12326.5 -2", "0 180 0", "1 0 0" );
make_ladder( "_ladder_silosemirearleft_cloned_millgrinder", "2001.5 -5712 273.75", "-3643 -11764 -75", "0 128 0" "-0.6 0.8 0" );
make_ladder( "_ladder_silosemirearright_cloned_millgrinder", "2001.5 -5712 273.75", "-3946 -11936 -75", "0 128 0" "-0.6 0.8 0" );
make_ladder( "_ladder_stacksfencefront_cloned_stacksfenceback", "258 -4883.67 156.145", "524 -9863 0", "0 180 0" "0 0 1" );
make_ladder( "_ladder_talleventpillar1_cloned_talleventpipe", "-1497 -9117.13 400.25", "-10269 -7652 0", "0 90 0" "0 1 0" );
make_ladder( "_ladder_talleventpillar2_cloned_talleventpipe", "-1497 -9117.13 400.25", "7965 -10268 0", "0 -90 0" "0 -1 0" );
make_ladder( "_ladder_tallspoolsroofleft_cloned_bigwindowspipe", "2369.33 -4846.5 302.25", "-1722 -2626 -76" );
make_ladder( "_ladder_tallspoolsroofright_cloned_bigwindowspipe", "2369.33 -4846.5 302.25", "3017 -13262 -71", "0 -180  0", "0 -1 0" );
make_ladder( "_ladder_tallvinereturn_cloned_brokenlocker", "2756 -3833.5 392.25", "3907 -9165 19", "0 -180 0", "0 -1 0" );
make_ladder( "_ladder_tankescape_cloned_bricksemitrailer", "4319.5 -3675.85 264.25", "-3231 -9632 -64", "0 90 0", "0 1 0" );
make_ladder( "_ladder_tankreturn_cloned_bricksemitrailer", "4319.5 -3675.85 264.25", "4730 -9078 -23", "0 -180 0", "-1 0 0" );
make_ladder( "_ladder_thimblesemi_cloned_millgrinder", "2001.5 -5712 273.75", "5981 -6400 -98", "0 -91.48 0" "0 -1 0" );
make_ladder( "_ladder_truckfencereturn_cloned_stacksfenceback", "258 -4883.67 156.145", "4551 -7959 1", "0 180 0" "1 0 0" );
make_prop( "dynamic", "_ladder_saferoofpipe_pipe", "models/props_mill/PipeSet08d_512_001a.mdl", "3466 -1891 158", "90 90 0", "shadow_no" );
patch_ladder( "1143.5 -5515.5 226", "0 5 0" );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c4m4_milltown_b":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

make_brush( "_losfix_ambulance1",	"-90 -1 -8",	"91 1 8",	"711 4748 102" );
make_brush( "_losfix_ambulance2",	"-1 -56 -8",	"1 57 8",	"803 4690 102" );
make_brush( "_losfix_dumpster",		"-185 -1 -8",	"185 1 8",	"3550 343 128" );
make_brush( "_losfix_gen1",		"-28 -1 -10",	"28 1 10",	"241 5987 107" );
make_brush( "_losfix_gen2",		"-22 -1 -8",	"22 1 8",	"3448 -1345 113" );
make_brush( "_losfix_truck",		"-62 -1 -10",	"62 1 10",	"3217 -1376 114" );
make_brush( "_losfix_truck_jump",	"-70 -1 -10",	"70 1 10",	"2949 2885 108" );
make_clip( "_ladder_dumpsterhouse_clip", "Everyone", 1, "-8 -16 0", "26 8 168", "1638 4032 217", "0 45 0" );
make_clip( "_ladder_yellowhousetree_topdenial", "SI Players", 1, "-8 -32 0", "8 32 62", "2244 3123 378", "-7 0 0" );
make_clip( "_ladder_safehousetall_clip", "SI Players", 1, "-20 -2 -2", "8 2 310", "3725 -1537 101", "0 45 0" );
make_clip( "_playgroundhouse_clip", "Survivors", 1, "-54 -177 -35", "635 176 1176", "-2074 7312 360" );
make_clip( "_safehousehedge_blocker", "SI Players", 1, "-690 -122 -20", "139 93 2122", "4401 -2207 438" );
make_ladder( "_ladder_cornerhomeplants_cloned_garagesalehome", "2468 2634 184", "3773 4652 128", "0 90 0", "-1 0 0" );
make_ladder( "_ladder_cornerhometankfight_cloned_treehousefence", "2058.5 2999.08 151.11", "1958 155 0" );
make_ladder( "_ladder_dumpsterhouse_cloned_alarmtrailer", "677.5 2966 212.223", "-1309 4697 88", "0 270 0", "0 -1 0" );
make_ladder( "_ladder_finalhouse_cloned_yellowhouse", "3510.5 917 182.881", "2993 3583 -14", "0 -90 0", "0 1 0" );
make_ladder( "_ladder_mobilepickup_cloned_alarmtrailer", "677.5 2966 212.223", "1675 8269 -36", "0 -180 0", "-1 0 0" );
make_ladder( "_ladder_safehousefenceback_cloned_cullingbuddy", "-4083 7580 170", "7421 -9698 -9" );
make_ladder( "_ladder_safehousetall_cloned_tallbuildingleft", "-885 5961 269.556", "9680 -675 -26", "0 90 0", "-1 0 0" );
make_ladder( "_ladder_saferoofpipe_cloned_tallbuildingleft", "-885 5961 269.556", "9680 -880 -26", "0 90 0", "-1 0 0" );
make_ladder( "_ladder_tallbuildingright_cloned_tallbuildingleft", "-885 5961 269.557", "5057 6467 -2", "0 90 0", "-1 0 0" );
make_ladder( "_ladder_trailerqol_cloned_alarmtrailer", "677.5 2966 212.223", "2555 3388 -66", "0 66 0", "0.4 0.9 0" );
make_ladder( "_ladder_vinehouseqol_cloned_alarmtrailer", "677.5 2966 212.223", "-3107 6241 -32", "0 -90 0", "0 -1 0" );
make_ladder( "_ladder_woodhouseqol_cloned_alarmtrailer", "677.5 2966 212.223", "2908 4383 -40", "0 90 0", "0 1 0" );
make_ladder( "_ladder_yellowhousetree_cloned_playgroundgutter", "-2041.58 7141.5 215.154", "9311 5106 -851", "3 90 6", "1 0 0" );
make_prop( "dynamic", "_ladder_finalhouse_pipe", "models/props_downtown/gutter_downspout_straight_160_02.mdl", "3910 71 248", "0 90 0", "shadow_no" );
make_prop( "dynamic", "_ladder_safehouse_pipe", "models/props_pipes/PipeSet02d_512_001a.mdl", "3726 -1560 160", "-90 90 0", "shadow_no", "solid_no" );
make_prop( "dynamic", "_ladder_saferoofpipe_pipe", "models/props_mill/PipeSet08d_512_001a.mdl", "3726 -1765 158", "90 90 0", "shadow_no" );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c4m5_milltown_escape":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

make_brush( "_losfix_burger_gen",	"-24 -1 -8",	"24 1 8",	"-5448 6765 107" );
make_brush( "_losfix_dock_truck",	"-2 -75 -10",	"2 80 16",	"-6538 7550 105" );
make_brush( "_losfix_semia",		"-40 -1 -15",	"40 1 15",	"-4771 7156 113" );
make_brush( "_losfix_semib",		"-1 -34 -15",	"1 40 15",	"-4790 7180 113" );
make_clip( "_burgertank_windowsmoother1", "Everyone", 1, "-5 -120 0", "6 120 4", "-5663 7268 135" );
make_clip( "_burgertank_windowsmoother2", "Everyone", 1, "-90 -5 0", "90 6 4", "-5798 7505 135" );
make_clip( "_burgertank_windowsmoother3", "Everyone", 1, "-90 -5 0", "90 6 4", "-6022 7777 135" );
make_clip( "_dockm5only_smoother", "Everyone", 1, "0 -376 0", "8 820 32", "-7039 7701 91", "-45 0 0" );
make_clip( "_ladder_sweetrelief_clip", "Everyone", 1, "-8 -16 0", "8 9 212", "-5746 6595 96", "0 53 0" );
make_ladder( "_ladder_autosalvagefront_cloned_playgroundroof", "-2041.58 7141.5 215.154", "-4077 930 8" );
make_ladder( "_ladder_classyjimboblue_cloned_garagesalehouse", "2468 2634 184", "-6814 4053 0" );
make_ladder( "_ladder_cullingsub_cloned_cullingbuddy", "-4083 7580 170", "-11738 3696 -9", "0 -90 0", "0 -1 0" );
make_ladder( "_ladder_gaselecbox_cloned_autosalvageback", "-5876.19 8673.97 236.888", "4059 13901 -58", "0 90 0", "-1 0 0" );
make_ladder( "_ladder_grocerypillar_cloned_garagesalehouse", "2468 2634 184", "-8299 8596 5", "0 -90 0", "1 0 0" );
make_ladder( "_ladder_sweetrelief_cloned_autosalvageback", "-5876.19 8673.97 236.888", "112 -2069 -56" );
make_prop( "dynamic", "_ladder_grocerypillar_bust", "models/props_interiors/concretepillar01_dm_base.mdl", "-5680 6576 160.2", "0 0 0", "shadow_no" );
make_prop( "dynamic", "_ladder_grocerypillar_prop", "models/props_interiors/concretepillar01.mdl", "-5680 6128 163.8", "0 0 0", "shadow_no" );

EntFire( g_UpdateName + "_ladder_grocerypillar_prop", "AddOutput", "OnBreak anv_mapfixes_ladder_grocerypillar_cloned_garagesalehouse:Kill::0:-1" );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*==============================
||                            ||
||         THE PARISH         ||
||                            ||
==============================*/

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c5m1_waterfront":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

make_brush( "_losfix_bus",		"-1 -96 -14",	"1 128 14",	"-868 -1515 -363" );
make_brush( "_losfix_van",		"-100 -1 -12",	"100 1 12",	"-918 -1852 -365" );
make_clip( "_ladder_endbluehouse_clipleft", "Everyone", 1, "3 -3 0", "8 16 336", "-3751 -4 -376", "0 55 0" );
make_clip( "_ladder_endbluehouse_clipwall", "Everyone", 1, "-1 -208 0", "7 304 331", "-3807 208 -376" );
make_clip( "_ladder_endgutterm2mirr_clip", "Everyone", 1, "-4.09 -13 0", "0 23 338", "-3196 -1079 -376" );
make_ladder( "_ladder_backpropladder_cloned_waterfrontfence", "-920 438 -304", "-367 -2821 -8" );
make_ladder( "_ladder_bienville_cloned_brickgutter", "-2086 -1984 -216", "1428 1278 -93" );
make_ladder( "_ladder_boothwindow_cloned_whitetablepath", "-2566 -1272 -284", "-572 -4931 0", "0 -90 0", "0 1 0" );
make_ladder( "_ladder_endbluehouse_cloned_waterfrontbrick", "-192 78.0956 -216", "-3580 -68 17" );
make_ladder( "_ladder_endgutterm2mirr_cloned_telephonegutter", "-1236 -1274 -213.5", "-4452 -2337 -24", "0 -180 0", "0 -1 0" );
make_ladder( "_ladder_kitchenelecbox_cloned_telephonegutter", "-1236 -1274 -213.5", "-3305 550 -109", "0 90 0", "-1 0 0" );
make_ladder( "_ladder_kitchenwindow_cloned_telephonegutter", "-1236 -1274 -213.5", "-1282 -1900 -135", "0 -90 0", "1 0 0" );
make_ladder( "_ladder_startroofqol_cloned_whitetablepath", "-2566 -1272 -284", "1853 -2855 -5", "0 -90 0", "0 1 0" );
make_ladder( "_ladder_startwtflongright_cloned_startwtflongleft", "118 912 -392", "3 -661 0" );
make_ladder( "_ladder_tankwaterfront_cloned_telephonegutter", "-1236 -1274 -213.5", "-1936 888 0", "0 90 0", "-1 0 0" );
make_ladder( "_ladder_yellowbarriersroof_cloned_alleygutter", "-2086 -1984 -216", "-2639 27 18", "0 90 0", "0 -1 0" );
make_prop( "dynamic",		"_losblocker_boxes",		"models/props/cs_militia/boxes_garage_lower.mdl",	"-26 -1108 -375.742",		"0 135.5 0",		"shadow_no" );
make_prop( "dynamic",		"_propladder_planka",		"models/props_highway/plywood_01.mdl",		"-167 -48 -195.766",		"-34 0.6025 -0.3587" );
make_prop( "dynamic",		"_propladder_plankb",		"models/props_swamp/plank001b_192.mdl",		"-2176 -2538 -320",		"0 0 35" );
make_prop( "dynamic", "_ladder_endgutterm2mirr_pipe", "models/props_downtown/gutter_downspout_straight01.mdl", "-3216 -1056 -89", "0 270 0", "shadow_no" );
make_prop( "dynamic", "_ladder_startroofqol_pipe", "models/props_downtown/gutter_downspout_straight01.mdl", "580 -308 -222", "0 90 0", "shadow_no" );
patch_ladder( "-2592 -1030 -208", "12 -3 0" );
patch_nav_checkpoint( "-3764 -1224 -344" );

con_comment( "PROP:\tTrashbin near \"_ladder_endbluehouse\" moved to improve accessibility." );

kill_entity( Entities.FindByClassnameNearest( "prop_physics", Vector( -3785, 22, -375.624 ), 8 ) );
make_prop( "physics", "_replacement_trashbin", "models/props_street/trashbin01.mdl", "-3781 118 -376", "0 17 0" );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c5m2_park":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

make_atomizer( "_atomizer_bsp_dumpster", "-9216 -3264 -248", "models/props_junk/dumpster_2.mdl", 60 );
make_brush( "_losfix_bus",		"-1 -60 -12",	"1 60 12",	"-7268 -7479 -244" );
make_brush( "_losfix_fence",	"0 -64 -4",	"1 64 5",	"-6583 -5678 -252" );
make_brush( "_losfix_gen",		"-1 -28 -8",	"1 28 8",	"-9918 -4878.21 -249" );
make_brush( "_losfix_van",		"-1 -108 -10",	"1 108 10",	"-3360 -1422 -371" );
make_clip( "_ladder_billboard_clip", "SI Players", 1, "-32 -6 -4", "30 4 4", "-9158 -6944 154" );
make_clip( "_ladder_deadendbalconies_clip", "SI Players", 1, "0 -1 0", "1 1 128", "-8576 -4001 -208" );
make_clip( "_ladder_endlightpole_clippole", "Everyone", 1, "-15 -9 0", "17 9 446", "-8812 -7872 -249" );
make_clip( "_ladder_endlightpole_cliptop", "SI Players", 1, "-69 -6 0", "18 3 1", "-8812 -7871 197" );
make_clip( "_ladder_startorangedrain_clip", "SI Players", 1, "-42 -37 0", "32 21 47", "-3189 -1433 -376", "0 -64 42" );
make_clip( "_ladderqol_endgutterm1mirr_clip", "Everyone", 1, "-4.09 -13 0", "0 23 338", "-3196 -1079 -376" );
make_ladder( "_ladder_archright_cloned_archleft", "-8110 -2848 -200", "-11 1310 0" );
make_ladder( "_ladder_billboardleft_cloned_watchtower", "-8000 -5874 -128", "-1172 -1855 -2782", "0 0 -30" );
make_ladder( "_ladder_billboardright_cloned_watchtower", "-8000 -5874 -128", "-1146 -1855 -2782", "0 0 -30" );
make_ladder( "_ladder_busroofright_cloned_busroofleft", "-7646 -7052 64", "-16317 -13972 0", "0 180 0", "-1 0 0" );
make_ladder( "_ladder_busrooftop_cloned_eventladderfence", "-6970 -5824 -188", "-999 -1726 336" );
make_ladder( "_ladder_deadendbalconies_cloned_busstationphones", "-7477.93 -7051.48 -120", "-1100 3036 40" );
make_ladder( "_ladder_endbarricadeback_cloned_cedafenceback", "-9543 -5488 -176", "3406 -1959 17" );
make_ladder( "_ladder_endbarricadefront_cloned_cedafencefront", "-9557 -5536 -176", "3374 -1959 17" );
make_ladder( "_ladder_endlightpoleB_cloned_startdrainladder", "-3216 -1062 -231", "-5595 -6818 77" );
make_ladder( "_ladder_endlightpoleT_cloned_startdrainladder", "-3216 -1062 -231", "-5595 -6818 269" );
make_ladder( "_ladder_endroofsignage_cloned_startgutter", "-3216 -1062 -231", "-6146 -6493 95" );
make_ladder( "_ladder_eventelecbox_cloned_startdrainladder", "-3216 -1062 -231", "-8095 -1859 136", "0 90 0", "1 0 0" );
make_ladder( "_ladder_farcorner_cloned_horsehedge", "-6400.001 -3068 -192", "695 -1186 -16" );
make_ladder( "_ladder_finalrunelecbox_cloned_eventgutter", "-8428 -5206 -76", "82 -3123 13" );
make_ladder( "_ladder_gazebo1_cloned_archleft", "-8110 -2848 -200", "310 -1010 0" );
make_ladder( "_ladder_gazebowall_cloned_archleft", "-8110 -2848 -200", "566 -1275 16" );
make_ladder( "_ladder_generatortent_cloned_archleft", "-8110 -2848 -200", "-16249 -6496 0", "0 -180 0", "-1 0 0" );
make_ladder( "_ladder_guardtowerhigh_cloned_cedatrailerfence", "-9557 -5536 -176", "-404 100 253" );
make_ladder( "_ladder_guardtowerlow_cloned_restrictedbarricade", "-9544 -5266 -128", "-580 -15 48" );
make_ladder( "_ladder_hmmwvawning_cloned_startcopcarfence", "-3128 -2204 -304", "-3197 -3550 112", "0 -7.5 0" );
make_ladder( "_ladder_longempty_cloned_archleft", "-8110 -2848 -200", "-11 2105 0" );
make_ladder( "_ladder_mehacvent_cloned_hedgemazecorner", "-7564 -352 -195.966", "141 -4810 208" );
make_ladder( "_ladder_overpasshigh_cloned_cedatrailerfence", "-9557 -5536 -176", "-437 2900 254" );
make_ladder( "_ladder_overpasslow_cloned_watchtowerbags", "-8000 -5874 -128", "-2095 2947 24" );
make_ladder( "_ladder_restroomsplatforml_cloned_startcopcarfence", "-3128 -2204 -304", "-7101 529 80", "0 90 0", "0 -1 0" );
make_ladder( "_ladder_restroomsplatformr_cloned_startleftfence", "-3460 -1310 -304", "-8356 -3127 80", "0 180 0", "0 1 0" );
make_ladder( "_ladder_startorangedrain_cloned_whitedumpster", "-9162 -4093 -68", "5959 2634 -103" );
make_ladder( "_ladder_startstuckspot_cloned_archleft", "-8110 -2848 -200", "3444.1 1312 64" );
make_ladder( "_ladder_telephonepoleB_cloned_restrictedbarricade", "-9544 -5266 -128", "-11800 3720 -16", "0 90 0", "-1 0 0" );
make_ladder( "_ladder_telephonepoleT_cloned_restrictedbarricade", "-9544 -5266 -128", "-11800 3720 176", "0 90 0", "-1 0 0" );
make_prop( "dynamic",		"_losblocker_fence",		"models/props_urban/fence_cover001_256.mdl",	"-6583 -5743 -247.75",		"0 180 0",		"shadow_no" );
make_prop( "dynamic",		"_propladder_planka",		"models/props_highway/plywood_02.mdl",		"-4216 -1082 -130",		"40 90 0" );
make_prop( "dynamic",		"_propladder_plankb",		"models/props_swamp/plank001b_192.mdl",		"-3105 -1504 -320",		"0 90 35" );
make_prop( "dynamic",		"_propladder_plankc",		"models/props_highway/plywood_01.mdl",		"-6731 -6212 -80",		"0 270 25",		"shadow_no" );
make_prop( "dynamic",		"_propladder_venta",		"models/props_rooftop/hotel_rooftop_equip002.mdl",	"-6724 -6753 7.918",		"0 90 0",		"shadow_no" );
make_prop( "dynamic",		"_propladder_ventb",		"models/props_rooftop/hotel_rooftop_equip002.mdl",	"-6370 -6752 80",		"0 90 0",		"shadow_no" );
make_prop( "dynamic",		"_solidify_awning",		"models/props_street/awning_department_store.mdl",	"-6403.3 -5024 -102.145",	"0 180 0",		"shadow_no" );
make_prop( "dynamic", "_guardtower_wrongway", "models/props_misc/wrongway_sign01_optimized.mdl", "-10091 -5792 110", "0 90 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_overpass_wrongwaya", "models/props_misc/wrongway_sign01_optimized.mdl", "-10162 -2304 80", "0 -90 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_overpass_wrongwayb", "models/props_misc/wrongway_sign01_optimized.mdl", "-9900 -2304 225", "0 -90 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_overpass_wrongwayc", "models/props_misc/wrongway_sign01_optimized.mdl", "-9700 -2304 225", "0 -90 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_solidify_flatawningend1", "models/props_street/awning_short.mdl", "-7785 -8320 -108.921", "0 0 0", "shadow_no" );
make_prop( "dynamic", "_solidify_flatawningend2", "models/props_street/awning_short.mdl", "-8537 -8320 -108.921", "0 0 0", "shadow_no" );
make_prop( "dynamic", "_solidify_flatawningmid", "models/props_street/awning_short.mdl", "-9216 -3712 -78.4492", "0 270 0", "shadow_no" );
make_prop( "dynamic", "_yesdraw_billboard_nodraw", "models/props_update/c5m2_billboard_nodraw.mdl", "-9152 -6938 92", "0 -90 0", "shadow_no", "solid_no" );
make_prop( "physics", "_hittable_dumpster",	"models/props_junk/dumpster_2.mdl",	"-8095 -600 -246", "0 0 0", "shadow_no" );
patch_ladder( "-9260 -5130 -152", "0 14 0" );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c5m3_cemetery":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

make_brush( "_losfix_bridgesemi",	"-30 -1 -12",	"30 1 12",	"6218 -2306 446" );
make_brush( "_losfix_busdrop",		"-64 -1 -15",	"64 1 15",	"4304 5208 11" );
make_brush( "_losfix_lot_truck1",	"-30 -1 -16",	"30 1 16",	"5755 -1088 16" );
make_brush( "_losfix_lot_truck2",	"-30 -1 -16",	"30 1 16",	"5647 -1434 16" );
make_brush( "_losfix_lot_van1",		"-64 -1 -10",	"64 1 10",	"6195 261 6" );
make_brush( "_losfix_lot_van2",		"-96 -1 -14",	"96 1 14",	"5692 484 17" );
make_brush( "_losfix_lot_van3",		"-90 -1 -10",	"90 1 10",	"6206 -831 7" );
make_brush( "_losfix_mainst_trailer",	"-1 -245 -10",	"1 258 10",	"4444 3019 10" );
make_brush( "_losfix_mainst_van",	"-1 -90 -10",	"1 90 10",	"4123 3902 6" );
make_brush( "_losfix_sewer_van",	"-1 -77 -10",	"1 77 10",	"3924 802 10" );
make_clip( "_barricade_stepcollision1", "SI Players", 1, "-360 -8 0", "360 32 69", "2656 835 50" );
make_clip( "_barricade_stepcollision2", "SI Players", 1, "-32 -8 0", "32 32 72", "2973 822 0" );
make_clip( "_burntbuild_collision01", "SI Players", 1, "-102 -98 -4", "102 98 4", "2208 642 242", "26 0 0" );
make_clip( "_burntbuild_collision02", "SI Players", 1, "-102 -128 -4", "102 98 4", "2026 642 242", "-26 0 0" );
make_clip( "_burntbuild_collision03", "SI Players", 1, "-102 -111 0", "102 98 4", "2210 1042 200", "23 -9 -19" );
make_clip( "_burntbuild_collision04", "SI Players", 1, "-205 -147 -4", "172 17 2", "2123 1046 170", "1 0 -8" );
make_clip( "_burntbuild_collision05", "SI Players", 1, "-120 -140 0", "102 110 4", "2028 1042 206", "-26 10 -17" );
make_clip( "_burntbuild_collision06", "SI Players", 1, "-102 -108 -4", "102 128 4", "2210 1258 205", "26 5 10" );
make_clip( "_burntbuild_collision07", "SI Players", 1, "-198 -32 -4", "177 128 4", "2116 1254 157", "-5.5 0 14" );
make_clip( "_burntbuild_collision08", "SI Players", 1, "-108 -101 -4", "96 42 4", "2028 1258 207", "-26 -5 10" );
make_clip( "_burntbuild_collision09", "SI Players", 1, "-188 -80 -4", "188 64 4", "2250 2021 163", "5 1 24" );
make_clip( "_burntbuild_collision10", "SI Players", 1, "-102 0 0", "102 91 4", "2337 2084 198", "19 0 0" );
make_clip( "_burntbuild_collision11", "SI Players", 1, "-188 -98 -4", "208 98 2", "2244 2083 141", "5 0 6" );
make_clip( "_burntbuild_collision12", "SI Players", 1, "-102 0 0", "95 78 4", "2155 2084 215", "-10 0 0" );
make_clip( "_burntbuild_collision13", "SI Players", 1, "-188 -82 -4", "188 82 4", "2243 2710 152", "-4 0 0" );
make_clip( "_burntbuild_collision14", "SI Players", 1, "-90 -132 0", "122 104 4", "2337 2799 259", "39 7 14" );
make_clip( "_burntbuild_collision15", "SI Players", 1, "-182 -80 -2", "182 80 2", "2243 2796 225", "14 0 13" );
make_clip( "_burntbuild_collision16", "SI Players", 1, "-100 -111 0", "115 17 4", "2155 2799 292", "-11 -6 10" );
make_clip( "_ladder_onewayshedback_clip", "Everyone", 1, "-17 -6 0", "8 0 141", "7000 -4026 117", "0 21 0" );
make_ladder( "_ladder_1stdumpster1_cloned_stuckfencefront", "3420 1168 56.5", "1330 3691 -20", "0 23 0", "0.39 -0.92 0" );
make_ladder( "_ladder_1stdumpster2_cloned_stuckfencefront", "3420 1168 56.5", "1071 3581 -20", "0 23 0", "0.39 -0.92 0" );
make_ladder( "_ladder_1stdumpster3_cloned_stuckfenceback", "3420 298 56.5", "677 4507 -20", "0 23 0", "-0.39 0.92 0" );
make_ladder( "_ladder_2nddumpster1_cloned_stuckfenceback", "3420 298 56.5", "-394 1654 -23" );
make_ladder( "_ladder_2nddumpster2_cloned_stuckfenceback", "3420 298 56.5", "-114 1654 -23" );
make_ladder( "_ladder_atticgutterB_cloned_largetrailer", "2782 960 80", "227 -656 -46" );
make_ladder( "_ladder_atticgutterT_cloned_largetrailer", "2782 960 80", "227 -656 114" );
make_ladder( "_ladder_burntbuildleft_cloned_blownwallleft", "3778 656 100", "-1475 32 -5" );
make_ladder( "_ladder_collosaldumpster_cloned_manholeblownwall", "3778 656 100", "2224 5859 0", "0 -90 0", "0 -1 0" );
make_ladder( "_ladder_concreteupper_cloned_startfence", "5940 8462 89.6381", "-1152 -1293 68" );
make_ladder( "_ladder_dumpsterfence_cloned_startfence", "5940 8462 89.6381", "-2549 -2219 -9" );
make_ladder( "_ladder_elecbox_cloned_largetrailer", "2782 960 80", "663 357 55" );
make_ladder( "_ladder_endfenceback_cloned_lastcrypt", "8376 -7562 235", "16249 -16025 -42", "0 -180 0", "0 -1 0" );
make_ladder( "_ladder_endfencefront_cloned_lastcrypt", "8376 -7562 235", "-505 -887 -42" );
make_ladder( "_ladder_fencecornerleft_cloned_fencebackeastr", "2172 46 55.5", "900 -162 0" );
make_ladder( "_ladder_fencecornerright_cloned_fencebacksouthl", "2500 -142 55.5", "-302 655 0" );
make_ladder( "_ladder_firebarrelroofB_cloned_vandropelecbox", "4462 4992 104", "-1329 609 -8" );
make_ladder( "_ladder_firebarrelroofT_cloned_vandropelecbox", "4462 4992 104", "-1063 609 123" );
make_ladder( "_ladder_firefence_cloned_mobilehome", "4510 3224 76", "-161 3462 -16" );
make_ladder( "_ladder_holefenceback_cloned_firstcrypt", "7022 -4849 197.016", "10303 7146 -124", "0 -105 0", "0.96 -0.26 0" );
make_ladder( "_ladder_holefencefront_cloned_firstcrypt", "7022 -4849 197.016", "-2697 -3866 -124", "0 75 0", "-0.96 0.26 0" );
make_ladder( "_ladder_manholechaintran_cloned_manholeblue", "4374 1576 76.1509", "-5 -1940 -9" );
make_ladder( "_ladder_onewayshedback_cloned_firstcrypt", "7022 -4849 197.016", "-2 825 -10" );
make_ladder( "_ladder_onewaybackfence_cloned_middlecrypt", "7604.02 -5653.63 184", "-1657.1 1144 -16" );
make_ladder( "_ladder_onewayleftfence_cloned_firstcrypt", "7022 -4849 197.016", "-560 985 -20" );
make_ladder( "_ladder_overpassfence_cloned_flamingofence", "4830 3840 57", "2793 2190 1399", "17 -90 0", "0 1 0" );
make_ladder( "_ladder_overpassjumpqol_cloned_startfence", "5940 8462 89.6381", "-2301 14862 210", "0 -90 0", "-1 0 0" );
make_ladder( "_ladder_pinkhouseB_cloned_manholeblownwall", "3778 656 100", "69 3452 -12" );
make_ladder( "_ladder_pinkhouseT_cloned_manholeblownwall", "3778 656 100", "69 3452 180" );
make_ladder( "_ladder_sewerhole1_cloned_flamingofence", "4830 3840 57", "9345 -3869 -274", "0 90 0", "0 -1 0" );
make_ladder( "_ladder_sewerhole2_cloned_flamingofence", "4830 3840 57", "10032 -3869 -274", "0 90 0", "0 -1 0" );
make_ladder( "_ladder_sewerhole3_cloned_flamingofence", "4830 3840 57", "1698 -3280 -274", "0 0 0", "-1 0 0" );
make_ladder( "_ladder_sewerhole4_cloned_flamingofence", "4830 3840 57", "1698 -3952 -274", "0 0 0", "-1 0 0" );
make_ladder( "_ladder_sewerhole5_cloned_flamingofence", "4830 3840 57", "2351 4381 -274", "0 -90 0", "0 1 0" );
make_ladder( "_ladder_sewerhole6_cloned_flamingofence", "4830 3840 57", "1903 4381 -274", "0 -90 0", "0 1 0" );
make_ladder( "_ladder_sewerhole7_cloned_flamingofence", "4830 3840 57", "10045 3728 -274", "0 180 0", "1 0 0" );
make_ladder( "_ladder_tankconcretewallB_cloned_semionewaytall", "2762 2700 109", "6216 2239 1", "0 90 0", "0 -1 0" );
make_ladder( "_ladder_tankconcretewallT_cloned_semionewaytall", "2762 2700 109", "6216 2239 161", "0 90 0", "0 -1 0" );
make_ladder( "_ladder_tankfenceback_cloned_firstcrypt", "7022 -4849 197.016", "11143 -477 -131", "0 -180 0", "0 -1 0" );
make_ladder( "_ladder_tankfencefront_cloned_firstcrypt", "7022 -4849 197.016", "-2862 9222 -131" );
make_ladder( "_ladder_thelastgutter_cloned_manholeblownwall", "3778 656 100", "0 303 0" );
make_prop( "dynamic",		"_losblocker_fencea",		"models/props_urban/fence_cover001_128.mdl",	"4349.7 7071 0",		"0 0 0",		"shadow_no" );
make_prop( "dynamic",		"_losblocker_fenceb",		"models/props_urban/fence_cover001_256.mdl",	"4349.7 6623 0",		"0 0 0",		"shadow_no" );
make_prop( "dynamic",		"_losblocker_fencec",		"models/props_urban/fence_cover001_128.mdl",	"4349.7 6306 0",		"0 0 0",		"shadow_no" );
make_prop( "dynamic",		"_losblocker_fenced",		"models/props_urban/fence_cover001_128.mdl",	"4285 6242.3 20",		"0 270 0",		"shadow_no" );
make_prop( "dynamic",		"_losblocker_fencee",		"models/props_urban/fence_cover001_256.mdl",	"3070 6242.3 20",		"0 270 0",		"shadow_no" );
make_prop( "dynamic",		"_losblocker_fencef",		"models/props_urban/fence_cover001_128.mdl",	"2900.26 1884.1 9.25",		"0 35.5 0",		"shadow_no" );
make_prop( "dynamic",		"_losblocker_fenceg",		"models/props_urban/fence_cover001_128.mdl",	"3502 1867 9.2501",		"0 155.5 0",		"shadow_no" );
make_prop( "dynamic",		"_losblocker_hedge",		"models/props_foliage/urban_hedge_256_128_high.mdl",		"3750 6532 -1.73642",		"0 0 0",		"shadow_no" );
make_prop( "dynamic",		"_propladder_fencea",		"models/props_fortifications/barricade_gate001_64_reference.mdl",	"4116 6347 26.916",		"-45 89.466 0.0493",	"shadow_no" );
make_prop( "dynamic",		"_propladder_fenceb",		"models/props_fortifications/barricade_gate001_64_reference.mdl",	"3121 6347 26.916",		"-45 89.466 0.0493",	"shadow_no" );
make_prop( "dynamic",		"_propladder_fencec",		"models/props_fortifications/barricade_gate001_64_reference.mdl",	"4026.17 -194.24 -0.284",	"-45 269.466 0.0493",	"shadow_no" );
make_prop( "dynamic",		"_propladder_fenced",		"models/props_fortifications/barricade_gate001_64_reference.mdl",	"4074.17 -194.24 -0.284",	"-45 269.466 0.0493",	"shadow_no" );
make_prop( "dynamic", "_collosaldumpster_wrongwaya", "models/props_misc/wrongway_sign01_optimized.mdl", "3471 2320 320", "0 180 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_collosaldumpster_wrongwayb", "models/props_misc/wrongway_sign01_optimized.mdl", "3471 2140 320", "0 180 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_solidify_tankconcretewall_chimney", "models/props_urban/chimney007.mdl", "3500.87 5616.91 353.166", "0 180 0", "shadow_no" );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c5m4_quarter":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

make_brush( "_losfix_bus1",		"-1 -75 -12",	"1 75 12",	"-87 2569 76" );
make_brush( "_losfix_bus2",		"-1 -76 -12",	"1 75 12",	"-228 2780 74" );
make_brush( "_losfix_bus3",		"-54 -1 -12",	"54 1 12",	"-176 2703 74" );
make_brush( "_losfix_memefence", "-80 0 0", "80 1 96", "-2512 2443 64" );
make_brush( "_losfix_van",		"-1 -85 -10",	"1 85 10",	"-2513 2807 72" );
make_clip( "_ladder_busjazzclub_balconystep", "SI Players", 1, "-316 2 0", "326 5 6", "-324 2590 218" );
make_clip( "_ladder_billiards_clip", "Survivors", 1, "-160 0 -252", "24 1 60", "-848 1999.1 316" );
make_clip( "_ladder_billiardsqol_clip", "Everyone", 1, "0 0 -154", "4 18 0", "-832 1999.1 218" );
make_clip( "_ladder_endtriplewindow_clip", "SI Players", 1, "-4 -96 0", "4 96 2", "-2 -2304 298" );
make_clip( "_ladder_fountainvinesB_clip", "Everyone", 1, "-8 -126 0", "0 130 179", "-3200 4158 64" );
make_clip( "_ladder_garagerooftops_clipbot", "SI Players", 1, "-23 -19 0", "19 2 16", "-1346 2958 64" );
make_clip( "_ladder_garagerooftops_cliptop", "SI Players", 1, "-47 -19 0", "66 2 44", "-1346 2974 64" );
make_ladder( "_ladder_balconygutter_cloned_eventacvent", "-1414 1288 592", "830 -984 -96" );
make_ladder( "_ladder_billiards_cloned_billiardsdrop", "-1392 2489 240", "545 -493.9 -120" );
make_ladder( "_ladder_busjazzclub_cloned_startwhitefence", "-3296 3698 134", "-1427 -2032 -3", "0 -54.6 0", "-0.82 -0.58 0" );
make_ladder( "_ladder_endsemifront_cloned_endsemiback", "1122.36 -2274.4004 146.7381", "2144 -4483 0", "0 180 0", "-0.96 0.28 0" );
make_ladder( "_ladder_endtriplewindow_cloned_firstgutterladder", "-3706 4400 170", "3706 -6704 22" );
make_ladder( "_ladder_floatfarcorner_cloned_floatreartall", "-1722 -288 248", "-62 1265 -16" );
make_ladder( "_ladder_floatfronttall_cloned_floatreartall", "-1722 -288 248", "0 400 0" );
make_ladder( "_ladder_fountainvinesB_cloned_firstgutterladder", "-3706 4400 170", "-6911 8598 -29", "0 -180 0", "-1 0 0" );
make_ladder( "_ladder_fountainvinesT_cloned_startrightpicket", "-3424 3458 126", "387 7583 224", "0 90 0", "-1 0 0" );
make_ladder( "_ladder_garagerooftops_cloned_startwhitefence", "-3296 3698 134", "1950 -707 16" );
make_ladder( "_ladder_laststreetextend_cloned_floatpointyfence", "-1600 -382 124", "212 -264 352" );
make_ladder( "_ladder_poolhallinleft_cloned_poolhalloutright", "-384 1598 144", "-769 3218 9", "0 180 0", "0 1 0" );
make_ladder( "_ladder_poolhallinright_cloned_poolhalloutleft", "-640 1598 144", "-1281 3218 9", "0 180 0", "0 1 0" );
make_ladder( "_ladder_postfloatlowroof_cloned_eventscaffoldright", "-1152 454 170", "-1472 569 244" );
make_ladder( "_ladder_prefloatalley_cloned_unusedwrongway", "-26 1728 234", "-1852 1566 -4", "0 -90 0", "0 -1 0" );
make_ladder( "_ladder_unusedareain_cloned_onewayvanfence", "-2512 2434 144", "270 765 0" );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c5m5_bridge":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

make_ladder( "_ladder_endcedatrailer_cloned_endchainlink", "9271.145 4057.18 273.355", "2144 -5516 8", "0 28.54 0", "-0.82 -0.56 0" );
make_ladder( "_ladder_endlosfence_cloned_backnodraw", "10073.0508 2663.2498 380.7315", "-1902 6582 -111", "0 -36.64 0", "0.9 -0.43 0" );
make_ladder( "_ladder_finalsidehouse_cloned_finalrungs", "9310.49 3329.52 330", "7708 -5521 87", "0 55.85 0", "-0.57 -0.82 0" );
make_ladder( "_ladder_forconsistencysake_cloned_firstscaffrightback", "1027 6081.5 640", "-3583 -6 0" );
make_ladder( "_ladder_slantedbridgeup_cloned_farendfence", "9514.01 6428.48 528", "-4906 152 200" );
make_prop( "dynamic", "_solidify_finalsidehouse_acunit", "models/props_rooftop/acunit01.mdl", "10092.1 4520.26 491", "0 150 0", "shadow_no" );
make_prop( "dynamic", "_solidify_finalsidehouse_acvent", "models/props_rooftop/acvent03.mdl", "10185.5 4360.08 594", "0 150 0", "shadow_no" );
patch_ladder( "9271.145 4057.18 273.355", "0 0 0", "-1 0 0" );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*==============================
||                            ||
||        THE PASSING         ||
||                            ||
==============================*/

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c6m1_riverbank":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

make_brush( "_losfix_bus",		"-1 -124 -9",	"1 124 9",	"-3624 101 713" );
make_brush( "_losfix_van",		"-1 -72 -10",	"1 72 10",	"3897 1356 148" );
make_clip( "_endsaferoof_wrongway_clip", "SI Players", 1, "-287 -174 -140", "220 130 1759", "-4128 350 1337" );
make_clip( "_semiperm_endsaferoof", "SI Players", 1, "-8 0 0", "104 270 144", "-4344 482 1192" );
make_clip( "_ladder_startalternativeB_clipleft", "Everyone", 1, "-8 -16 0", "8 16 249", "701 4025 96", "0 -45 0" );
make_clip( "_ladder_startalternativeB_clipright", "Everyone", 1, "-8 -16 0", "8 16 249", "701 4071 96", "0 45 0" );
make_clip( "_ladder_upperbalconynear_clip", "Everyone", 1, "-3 0 0", "3 16 372", "3968 1822 199", "0 11 0" );
make_clip( "_infected_mapescape", "SI Players", 1, "-40 -350 -20", "40 440 245", "-1997 1497 192" );
make_ladder( "_ladder_brideentryleft_cloned_brideentryright", "196 422 574", "1199 -13 -20" );
make_ladder( "_ladder_elecbox_cloned_bluebin", "2528 1030 342", "-2652 -253 42" );
make_ladder( "_ladder_elecboxsafehouse_cloned_bluebin", "2528 1030 342", "-6434 498 516" );
make_ladder( "_ladder_endfencefront_cloned_endfenceback", "-3879.68 1645.6 787", "-7751 3326 -2", "0 180 0", "1 0 0" );
make_ladder( "_ladder_endsafehouse_cloned_windowtallright", "1664 2662 228", "-6535 2676 610", "0 -90 0", "1 0 0" );
make_ladder( "_ladder_endshorthouse_cloned_windowshortleft", "1136 2662 212", "-6567 1760 608", "0 -90 0", "1 0 0" );
make_ladder( "_ladder_endtallbrickleft_cloned_bluebin", "2528 1030 342", "-4866 2127 480", "0 -90 0", "1 0 0" );
make_ladder( "_ladder_endtallbrickright_cloned_bluebin", "2528 1030 342", "-4866 2383 480", "0 -90 0", "1 0 0" );
make_ladder( "_ladder_endtransitfence_cloned_dispcrouchfence", "4673 994 239.551", "-6991 -432 470" );
make_ladder( "_ladder_startalternativeB_cloned_windowtallright", "1664 2662 228", "-1947 5712 -16", "0 -90 0", "1 0 0" );
make_ladder( "_ladder_startalternativeT_cloned_starttallangled", "684.191 3062 368", "1365 7121 0", "0 180 0", "0 1 0" );
make_ladder( "_ladder_startpermstuck_cloned_endleftfence", "-3575 -1142 777.5", "4159 3762 -608" );
make_ladder( "_ladder_tankfenceback_cloned_startfence", "527 2940 162.12", "-1927 -1661 107" );
make_ladder( "_ladder_tankfencefront_cloned_dispcrouchfence", "4673 994 239.551", "-6066 228 26" );
make_ladder( "_ladder_upperbalconynear_cloned_upperbalconyfar", "3078 1644 376", "890 161 10" );
make_ladder( "_ladder_witchentryfrontleft_cloned_witchentryback", "-1356.6 412.195 698.459", "-2713 805 0", "0 -180 0", "0 -1 0" );
make_ladder( "_ladder_witchentryfrontright_cloned_witchentryback", "-1356.6 412.195 698.459", "-2016 805 0", "0 -180 0", "0 -1 0" );
make_ladder( "_ladder_witchfarbackL_cloned_witchentryback", "-1356.6 412.195 698.459", "-3434 -730 65", "0 -180 0", "0 -1 0" );
make_ladder( "_ladder_witchfarbackM_cloned_witchentryback", "-1356.6 412.195 698.459", "-2669 -730 65", "0 -180 0", "0 -1 0" );
make_ladder( "_ladder_witchfarbackR_cloned_witchentryback", "-1356.6 412.195 698.459", "-1905 -730 65", "0 -180 0", "0 -1 0" );
make_ladder( "_ladder_witchtentsleft_cloned_witchhedgeleft", "-1594 -920 700", "-1462 536 0", "0 90 0", "0 1 0" );
make_ladder( "_ladder_witchtentsright_cloned_witchhedgeleft", "-1594 -920 700", "-2232 536 0", "0 90 0", "0 1 0" );
make_prop( "dynamic", "_solidify_endacvent", "models/props_rooftop/acvent04.mdl", "-3920 1027 1056.8", "0 180 0", "shadow_no" );
make_prop( "dynamic", "_solidify_endchimney", "models/props_urban/chimney007.mdl", "-4027.48 830.86 1056", "2 270 0", "shadow_no" );
make_prop( "dynamic", "_tankfence_wrongway", "models/props_misc/wrongway_sign01_optimized.mdl", "-2025 1527 259", "0 326.5 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c6m2_bedlam":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

make_brush( "_losfix_crates",	"-2 -30 -3",	"2 30 3",	"1820 4757 -115" );
make_brush( "_losfix_strangebalcony",	"-400 -2 -8",	"240 2 8",	"1552 1854 344" );
make_brush( "_losfix_van1",		"-72 -1 -8",	"72 1 8",	"535 4275 -153" );
make_brush( "_losfix_van2",		"-72 -1 -8",	"72 1 8",	"1592 4299 -153" );
make_ladder( "_ladder_barplankqolB_cloned_barelecbox", "421 1994 136", "2394 2455 -256", "0 90 0", "0 1 0" );
make_ladder( "_ladder_barplankqolT_cloned_barelecbox", "421 1994 136", "2394 2455 0", "0 90 0", "0 1 0" );
make_ladder( "_ladder_crawfishelecbox_cloned_sucktheheads", "2080 -836 168", "4138 -1342 0", "0 180 0", "0 1 0" );
make_ladder( "_ladder_forkliftvines_cloned_startfenceback", "2408 -1284 -64", "-1130 4196 -48" );
make_ladder( "_ladder_frontloaderright_cloned_frontloaderleft", "803 1554 -151.5", "1607 3220 0", "0 180 0", "0 1 0", 0 );
make_ladder( "_ladder_pipesfencefront_cloned_pipesfenceback", "2384 1566 1", "4757 3130 0", "0 180 0", "-1 0 0" );
make_ladder( "_ladder_poolhalldropleft_cloned_poolhalldropright", "1113 1308 -94.8019", "250 0 0" );
make_ladder( "_ladder_stanleydoor_cloned_sewerdropleft", "1627.5 5554 -1132", "12817 4901 46", "0 90 0", "0 -1 0" );
make_ladder( "_ladder_startfenceback_cloned_startfence", "2408 -1284 -64", "719 -3792 160", "0 90 0", "1 0 0" );
make_ladder( "_ladder_startfencefront_cloned_startfenceback", "2408 -1284 -64", "4820 -2566 0", "0 180 0", "0 1 0" );
make_prop( "dynamic", "_solidify_ventlarge", "models/props_rooftop/vent_large1.mdl", "1312.21 1963.61 334.677", "0 270 0", "shadow_no" );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c6m3_port":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

make_brush( "_losfix_gen1",		"-20 -1 -8",	"20 1 8",	"-476 -577 11" );
make_brush( "_losfix_gen2",		"-1 -20 -8",	"1 20 8",	"-1152 920 168" );
make_brush( "_losfix_van1",		"-72 -1 -9",	"72 1 9",	"-318 5 5" );
make_brush( "_losfix_van2",		"-64 -1 -9",	"64 1 9",	"379 703 168" );
make_clip( "_ladder_c7mirrconcretecar_clipleft", "Everyone", 1, "-2 -6 0", "2 6 138", "251 493 30", "2 -45 -2" );
make_clip( "_ladder_c7mirrconcretecar_clipright", "Everyone", 1, "-2 -6 0", "2 6 138", "252 452 30", "2 45 2" );
make_clip( "_ladder_c7mirrstonewallcar_clipleft", "Everyone", 1, "6 13 0", "8 16 152", "1214 -143 -105", "0 45 0" );
make_clip( "_ladder_c7mirrstonewallcar_clipright", "Everyone", 1, "6 13 0", "8 16 152", "1158 -133 -105", "0 -45 0" );
make_ladder( "_ladder_backleftc6only_cloned_generatorvines", "-686 -408 160", "-1860 237 -16" );
make_ladder( "_ladder_backmidc6only_cloned_generatorvines", "-686 -408 160", "-1867 1068 -16" );
make_ladder( "_ladder_backrightc6only_cloned_starttinyvan", "-1872 -658 54", "-1869 -710 156", "0 -90 0", "1 0 0" );
make_ladder( "_ladder_c7mirracventfront_cloned_acventback", "-960 -514 391", "-1914 -1013 0", "0 180 0", "0 1 0" );
make_ladder( "_ladder_c7mirrbarricaderoof_cloned_elevatorvines", "-686 -408 160", "470 1410 96" );
make_ladder( "_ladder_c7mirrbrickstep_cloned_startshortest", "-1872 -658 54", "-1311 2911 308", "0 90 0", "-1 0 0" );
make_ladder( "_ladder_c7mirrbridgeright_cloned_stonewallstairs", "1154 -304 80", "-451 919 0" );
make_ladder( "_ladder_c7mirrconcretecar_cloned_acventback", "-960 -514 391", "745 -487 -318", "0 -90 -3", "-1 0 0" );
make_ladder( "_ladder_c7mirrconcretestep_cloned_startshortest", "-1872 -658 54", "909 -2818 -106", "0 -90 0", "1 0 0" );
make_ladder( "_ladder_c7mirrelecboxfence_cloned_elevatorvines", "-686 -408 160", "437 -582 3" );
make_ladder( "_ladder_c7mirrfireescapeback_cloned_burgerbillboard", "-528 798 240", "992 -1574 -65" );
make_ladder( "_ladder_c7mirrpoolhalldoorway_cloned_picketbridgefar", "-1368 -254 115", "1193 -1662 158", "0 -90 0", "1 0 0" );
make_ladder( "_ladder_c7mirrprivateparking_cloned_stonewallstairs", "1154 -304 80", "2175 866 132", "0 -180 0", "-1 0 0" );
make_ladder( "_ladder_c7mirrstonewallcar_cloned_stonewallstairs", "1154 -304 80", "887 -1283 -114", "0 90 0", "0 1 0" );
make_ladder( "_ladder_c7mirrstonewalltree_cloned_softdrinks", "272 1746 283.95", "3435 -631 -79", "0 90 -4", "1 0 0" );
make_ladder( "_ladder_c7mirrtentlinkfar_cloned_acventback", "-960 -514 391", "18 -940 -162", "0 180 0", "0 1 0" );
make_ladder( "_ladder_c7mirrtentlinknear_cloned_acventback", "-960 -514 391", "555 261 -162", "0 90 0", "1 0 0" );
make_ladder( "_ladder_c7mirrvinestohedge_cloned_burgerbillboard", "-528 798 240", "227 -1467 -128", "0 -90 0", "-1 0 0" );
make_ladder( "_ladder_c7mirrwhitetable_cloned_picketbridge", "-992 -254 160", "711 -618 3" );
make_ladder( "_ladder_c7mirrwindowdoor_cloned_burgerbillboard", "-528 798 240", "126 549 -65", "0 180 0", "0 1 0" );
make_ladder( "_ladder_starthighc6only_cloned_generatorvines", "-686 -408 160", "-1528 93 0" );
make_ladder( "_ladder_startlowc6only_cloned_generatorvines", "-686 -408 160", "-1356 -299 -240" );
make_prop( "dynamic", "_ladder_c7mirrbarricaderoof", "models/props_downtown/gutter_downspout_straight02.mdl", "-224 1001 412", "0 0 0", "shadow_no", "solid_no" );
make_prop( "dynamic", "_ladder_c7mirrelecboxfence", "models/props_downtown/gutter_downspout_straight02.mdl", "-256 -998 304", "0 0 0", "shadow_no", "solid_no" );
make_prop( "dynamic", "_ladder_c7mirrfireescapeback", "models/props_downtown/gutter_downspout_straight02.mdl", "463 -768 347", "0 -90 0", "shadow_no", "solid_no" );
make_prop( "dynamic", "_ladder_c7mirrpoolhalldoorway", "models/props_downtown/gutter_downspout_straight02.mdl", "928 -294 370", "0 0 0", "shadow_no", "solid_no" );
make_prop( "dynamic", "_ladder_c7mirrwindowdoor", "models/props_downtown/gutter_downspout_straight02.mdl", "654 -256 347", "0 90 0", "shadow_no", "solid_no" );
patch_nav_checkpoint( "-2227 -362 -256" );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*==============================
||                            ||
||       THE SACRIFICE        ||
||                            ||
==============================*/

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c7m1_docks":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

make_clip( "_ladder_tankwinleft_clip", "SI Players", 1, "-26 0 0", "26 1 6", "7335 944 224" );
make_clip( "_ladder_tankwinright_clip", "SI Players", 1, "-26 0 0", "26 1 6", "7591 944 224" );
make_ladder( "_ladder_brickyardleft1_cloned_brickyard2nd", "4712 193 224", "-72 -639 1" );
make_ladder( "_ladder_brickyardleft2_cloned_brickyard3rd", "3713 352 192", "4576 -4096 1", "0 90 0", "0 1 0" );
make_ladder( "_ladder_brickyardleft3_cloned_brickyard1st", "5441 -418 224", "-1730 64 1" );
make_ladder( "_ladder_brickyardright1_cloned_brickyard3rd", "3713 352 192", "5569 -3458 1", "0 90 0", "0 1 0" );
make_ladder( "_ladder_brickyardright2_cloned_brickyard3rd", "3713 352 192", "4545 -3457 1", "0 90 0", "0 1 0" );
make_ladder( "_ladder_midfencefar_cloned_midstreetnear", "11391 2256 204.538", "-778 -311 0" );
make_ladder( "_ladder_midfencenear_cloned_midstreetfar", "10621 2064 204.5", "782 0 0" );
make_ladder( "_ladder_parkourvent_cloned_roofshortest", "5559 1168 352", "10439 2848 -48", "0 180 0", "1 0 0" );
make_ladder( "_ladder_tankwinleft_cloned_brickoffice", "5944 823 256", "1390 105 -136" );
make_ladder( "_ladder_tankwinright_cloned_brickoffice", "5944 823 256", "1646 105 -136" );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c7m2_barge":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

make_ladder( "_ladder_bluecontback_cloned_bluecontfront", "6787.2104 2431.76 196", "13183 4909 -6", "0 180 0", "-1 0 0" );
make_ladder( "_ladder_comicboatsleftL_cloned_toolhouse", "-633 2008 254.462", "2764 -592 -344", "6 64.4 0", "0.43 0.9 0" );
make_ladder( "_ladder_comicboatsleftR_cloned_toolhouse", "-633 2008 254.462", "2738 -580 -344", "6 64.4 0", "0.43 0.9 0" );
make_ladder( "_ladder_comicboatsright_cloned_toolhouse", "-633 2008 254.462", "1602 555 -222", "0 90 0", "0 1 0" );
make_ladder( "_ladder_comicpylonleft_cloned_toolhouse", "-633 2008 254.462", "1190 -2732 -8", "-2 -19 -5", "0.93 -0.35 0" );
make_ladder( "_ladder_comicpylonright_cloned_toolhouse", "-633 2008 254.462", "783 -2540 26", "-2 -19 -5", "0.93 -0.35 0" );
make_ladder( "_ladder_comicwitchboat_cloned_toolhouse", "-633 2008 254.462", "971 3616 -216", "-6 155.8 1", "-0.91 0.4 0" );
make_ladder( "_ladder_endbarricadeleft_cloned_vanishbarricade", "-8918.5 1728 198.5", "-1940 4860 -3", "0 30 0", "0.86 0.5 0" );
make_ladder( "_ladder_endbarricaderight_cloned_nomanssemi", "-6769.9307 249.9129 83.622", "-2373 430 103", "0 -12 0", "-0.87 -0.5 0" );
make_ladder( "_ladder_overpassgapleft_cloned_fourcontainers", "2024 2585 312", "1089 7 -48" );
make_ladder( "_ladder_overpassgapright_cloned_fourcontainers", "2024 2585 312", "1410 7 -48" );
make_ladder( "_ladder_permstuckend_cloned_toolhouse", "-633 2008 254.462", "-8964 3427 -54", "0 105 0", "-0.24 0.96 0" );
make_ladder( "_ladder_pondareafence_cloned_startflatnosefence", "9572 914 204", "-741 841 0" );
make_ladder( "_ladder_shedwindow_cloned_barrelshort", "3576 2015 165.579", "5985 4958 -100", "0 -90 0", "-1 0 0" );
make_ladder( "_ladder_silofenceclone1_cloned_silofencesource", "6816 321 248.1575", "-1250 127 0" );
make_ladder( "_ladder_spectroleumtanker_cloned_spectroleumfence", "6269 632 204.057", "-676 -1582 -6", "0 20.17 0", "-0.94 -0.33 0" );
make_ladder( "_ladder_startroombrick_cloned_startareasemi", "10355 1488 210.5", "-94 911 13" );
make_ladder( "_ladder_tankpolesfenceleft_cloned_tankpolesfenceright", "1617 544 332", "0 -515 0" );
make_ladder( "_ladder_tankpoleswallL_cloned_tankpolesfenceright", "1617 544 332", "1532 960 -152", "0 -102.11 0", "-0.2 -0.97 0" );
make_ladder( "_ladder_tankpoleswallR_cloned_tankpolesfenceright", "1617 544 332", "1560 954 -152", "0 -102.11 0", "-0.2 -0.97 0" );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c7m3_port":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

make_brush( "_losfix_dynamic_car",	"-80 -1 -10",	"80 1 10",	"89 -1532 176" );
make_brush( "_losfix_dynamic_van",	"-100 -1 -10",	"100 1 10",	"-86 -1551 176" );
make_brush( "_losfix_gen1",			"-20 -1 -8",	"20 1 8",	"-460 -572 11" );
make_brush( "_losfix_gen2",			"-1 -20 -8",	"1 20 8",	"-1151 921 168" );
make_ladder( "_ladder_fencec6mirr_cloned_concbarrfront", "-274 1408 228", "39 -2127 -163" );
make_ladder( "_ladder_pillarc6mirr_cloned_dumpsterhedge", "2047 256 0", "-3089 44 64" );

con_comment( "MOVER:\tLOS dynamic car and van parented to move with bridge." );

EntFire( g_UpdateName + "_losfix_dynamic_car", "SetParent", "bridge_elevator" );
EntFire( g_UpdateName + "_losfix_dynamic_van", "SetParent", "bridge_elevator" );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*==============================
||                            ||
||          NO MERCY          ||
||                            ||
==============================*/

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c8m1_apartment":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

kill_funcinfclip( 43.2982 );
kill_funcinfclip( 617.65 );
kill_funcinfclip( 611.263 );
kill_funcinfclip( 769.74 );
kill_funcinfclip( 836.992 );
kill_funcinfclip( 577.321 );
kill_funcinfclip( 873.029 );		// Delete clip on roof near car alarm, watertower/chimneys have collision
kill_funcinfclip( 969.151 );		// Delete clip on gray rooftop with the 3 small AC units
kill_funcinfclip( 712.934 );		// Delete clip in far corner near NODRAW wall
EntFire( "worldspawn", "RunScriptCode", "kill_funcinfclip( 43.2982 )", 1 );
make_brush( "_losfix_boxes",		"-2 -4 -16",	"2 4 16",	"2956 3995.77 -224" );
make_brush( "_losfix_car",		"-46 -1 -16",	"56 1 10",	"1163 2944 23" );
make_brush( "_losfix_debris1",	"-30 -1 -74",	"15 1 40",	"2404 706 90" );
make_brush( "_losfix_debris2",	"-30 -1 -74",	"15 1 40",	"2493 706 90" );
make_brush( "_losfix_debris3",	"-112 -20 -1",	"73 20 1",	"2487 727 130" );
make_brush( "_losfix_debris4",	"-112 -1 -10",	"73 1 10",	"2487 747 141" );
make_brush( "_losfix_truck",	"-1 -80 -5",	"1 80 15",	"2232 4268 12" );
make_brush( "_losfix_van1",		"-1 -50 -8",	"1 50 8",	"2588 3542 21" );
make_brush( "_losfix_van2",		"-40 -1 -8",	"41 1 8",	"2546 3494 21" );
make_clip( "_ladder_startroof_clip", "SI Players", 1, "4 -28 0", "8 28 3", "2292 1340 319" );
make_clip( "_ladder_subwaybricks_clip", "Everyone", 1, "-1 -8 0", "2 8 128", "2814 4104 16" );
make_clip( "_meticulous_funcinfclip01", "SI Players", 1, "-1 -28 0", "3 28 74", "2293 850 322" );
make_clip( "_meticulous_funcinfclip02", "SI Players", 1, "-8 -619 0", "185 629 1089", "3175 3371 832" );
make_clip( "_meticulous_funcinfclip03", "SI Players", 1, "-153 -812 0", "293 308 4132", "153 2988 352" );
make_clip( "_meticulous_funcinfclip04", "SI Players", 1, "0 -846 0", "389 794 687", "-5 4298 466" );
make_clip( "_meticulous_funcinfclip05", "SI Players", 1, "-153 -128 -336", "104 0 4132", "153 2176 352" );
make_clip( "_yesdraw_dairy_clipa", "SI Players", 1, "-330 -231 0", "311 249 3952", "1737 5767 528" );
make_clip( "_yesdraw_dairy_clipb", "SI Players", 1, "-17 -142 0", "17 142 3952", "2031 5390 528" );
make_clip( "_yesdraw_farcorner_clip", "SI Players", 1, "-216 -215 -256", "168 233 3952", "216 5303 528" );
make_clip( "_yesdraw_start_clipa", "SI Players", 1, "-300 -447 0", "0 449 1120", "3052 959 800" );
make_clip( "_yesdraw_start_clipb", "SI Players", 1, "-158 -10 -580", "42 312 549", "2710 508 1370" );
make_ladder( "_ladder_alleywindow_cloned_tankerwindow", "1720 3959.5 120", "820 -1590 0" );
make_ladder( "_ladder_commvignette_cloned_trashorange", "2428 3204.5 255.9905", "-1800 97 -144" );
make_ladder( "_ladder_crushedescape_cloned_tankerwindow", "1720 3959.5 120", "4198 4729 -51", "0 180 0", "0 1 0" );
make_ladder( "_ladder_dairybrickleft_cloned_thinwhiteledge", "3310 4020.5 151.9882", "-1659 1036 488" );
make_ladder( "_ladder_dairybrickright_cloned_thinwhiteledge", "3310 4020.5 151.9882", "-1685 1036 488" );
make_ladder( "_ladder_fencebayB_cloned_garagewindow", "2056.5 4608 120", "3539 6600 208", "0 180 0", "-1 0 0" );
make_ladder( "_ladder_fencebayT_cloned_garagewindow", "2056.5 4608 120", "3539 6600 368", "0 180 0", "-1 0 0" );
make_ladder( "_ladder_fencefrontL_cloned_fencebackL", "841 2039.5 76", "2294 4095 0", "0 180 0", "0 1 0" );
make_ladder( "_ladder_fencefrontM_cloned_fencebackM", "1173 2048.5 68", "2346 4105 0", "0 180 0", "0 1 0" );
make_ladder( "_ladder_fencefrontR_cloned_fencebackR", "1453 2044.5 75.717", "2294 4095 0", "0 180 0", "0 1 0" );
make_ladder( "_ladder_flatnose_cloned_chaintilt", "3268.5 4088 83.9941", "-1708 205 -20", "0 -7 0", "0.96 -0.26 0" );
make_ladder( "_ladder_ominouswin_cloned_helloworld", "2066 1783.5 328", "-242 3464 -112" );
make_ladder( "_ladder_parkourstartB_cloned_tallpipecopcar", "1531 2570 255.99", "1029.5 -1500 144" );
make_ladder( "_ladder_parkourstartT_cloned_thinwhiteledge", "3310 4020.5 151.9882", "5852 5120 523", "0 180 0", "0 -1 0" );
make_ladder( "_ladder_simondairy_cloned_helloworld", "2066 1783.5 328", "-937 3272 -112" );
make_ladder( "_ladder_startroof_cloned_trashblack", "2565 2560 255.9905", "-265 -1168 -12" );
make_ladder( "_ladder_subwaybricks_cloned_tankerwindow", "1720 3959.5 120", "1112 134 -68" );
make_ladder( "_ladder_subwayrubble_cloned_woodyjr", "3408 3973.5 74", "-64 140 -264" );
make_prop( "dynamic",		"_losblocker_fencea",		"models/props_urban/fence_cover001_256.mdl",	"896 3971 17",			"0 270 0",		"shadow_no" );
make_prop( "dynamic",		"_losblocker_fenceb",		"models/props_urban/fence_cover001_256.mdl",	"1408 3971 17",			"0 270 0",		"shadow_no" );
make_prop( "dynamic", "_commvignette_wrongwaya", "models/props_misc/wrongway_sign01_optimized.mdl", "445 2790 416", "0 0 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_commvignette_wrongwayb", "models/props_misc/wrongway_sign01_optimized.mdl", "445 3190 416", "0 0 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_ladder_commvignette_pipe", "models/props_rooftop/Gutter_Pipe_256.mdl", "628 3296 330", "0 180 0", "shadow_no" );
make_prop( "dynamic", "_ladder_ominouswin_pipeB", "models/props_rooftop/Gutter_Pipe_256.mdl", "1824 5248 272", "0 0 0", "shadow_no" );
make_prop( "dynamic", "_ladder_ominouswin_pipeT", "models/props_rooftop/Gutter_Pipe_256.mdl", "1824 5248 528", "0 0 0", "shadow_no" );
make_prop( "dynamic", "_ladder_simondairy_pipeB", "models/props_rooftop/Gutter_Pipe_256.mdl", "1129 5056 272", "0 0 0", "shadow_no" );
make_prop( "dynamic", "_ladder_simondairy_pipeT", "models/props_rooftop/Gutter_Pipe_256.mdl", "1129 5056 528", "0 0 0", "shadow_no" );
make_prop( "dynamic", "_losblocker_simondairy", "models/props_rooftop/rooftopcluser06a.mdl", "1392 5397 630", "0 0 0", "shadow_no" );
make_prop( "dynamic", "_solidify_dairyclust", "models/props_rooftop/rooftopcluser06a.mdl", "1632 4672 869.405", "0 88.5 0", "shadow_no" );
make_prop( "dynamic", "_solidify_dairyvent1", "models/props_rooftop/acvent01.mdl", "1633 4676 776.299", "0 180 0", "shadow_no" );
make_prop( "dynamic", "_solidify_dairyvent2", "models/props_rooftop/acvent01.mdl", "1633 4548 776.299", "0 180 0", "shadow_no" );
make_prop( "dynamic", "_solidify_dairyvent3", "models/props_rooftop/acvent01.mdl", "1904 4145 776.299", "0 270 0", "shadow_no" );
make_prop( "dynamic", "_solidify_dairyvent4", "models/props_rooftop/acvent02.mdl", "1665 4124 776", "0 270 0", "shadow_no" );
make_prop( "dynamic", "_window_ceda_body", "models/DeadBodies/CEDA/ceda_truck_a.mdl", "2382 1414 257", "2 -137 32", "shadow_no", "solid_no" );
make_prop( "dynamic", "_yesdraw_dairy_wrongwaya", "models/props_misc/wrongway_sign01_optimized.mdl", "1309 5535 585", "0 270 0", "shadow_no", "solid_no", "255 255 255", 217, 17 );
make_prop( "dynamic", "_yesdraw_dairy_wrongwayb", "models/props_misc/wrongway_sign01_optimized.mdl", "1709 5535 585", "0 270 0", "shadow_no", "solid_no", "255 255 255", 217, 17 );
make_prop( "dynamic", "_yesdraw_farcorner_wall", "models/props_update/c8m1_rooftop_4.mdl", "384 4272 529.3", "0 270 0", "shadow_no", "solid_no" );
make_prop( "dynamic", "_yesdraw_farcorner_wrongway", "models/props_misc/wrongway_sign01_optimized.mdl", "384 5303 320", "0 0 0", "shadow_no", "solid_no", "255 255 255", 217, 17 );
make_prop( "dynamic", "_yesdraw_fireroof_hunt1", "models/props_update/c8m1_rooftop_3.mdl", "544 1264 1232", "0 0 0", "shadow_no" );
make_prop( "dynamic", "_yesdraw_fireroof_hunt2", "models/props_update/c8m1_rooftop_3.mdl", "544 1536 1232.1", "0 0 0", "shadow_no" );
make_prop( "dynamic", "_yesdraw_fireroof_hunt3", "models/props_update/c8m1_rooftop_3.mdl", "544 1808 1232", "0 0 0", "shadow_no" );
make_prop( "dynamic", "_yesdraw_roof_starta", "models/props_update/c8m1_rooftop_3.mdl", "2792 1192 799.9999", "0 -90 0", "shadow_no", "solid_no" );
make_prop( "dynamic", "_yesdraw_roof_startb", "models/props_update/c8m1_rooftop_3.mdl", "2792 744 799.9999", "0 -90 0", "shadow_no", "solid_no" );
make_prop( "dynamic", "_yesdraw_roof_startc", "models/props_update/c8m1_rooftop_3.mdl", "3272 1192 799.9999", "0 -90 0", "shadow_no", "solid_no" );
make_prop( "dynamic", "_yesdraw_roof_startd", "models/props_update/c8m1_rooftop_3.mdl", "3272 744 799.9999", "0 -90 0", "shadow_no", "solid_no" );
make_prop( "dynamic", "_yesdraw_rooftop_1", "models/props_update/c8m1_rooftop_1.mdl", "1776 4528 776", "0 -90 0", "shadow_no", "solid_no" );
make_prop( "dynamic", "_yesdraw_rooftop_2", "models/props_update/c8m1_rooftop_2.mdl", "1536 5536 528", "0 -90 0", "shadow_no", "solid_no" );
make_prop( "dynamic", "_yesdraw_rooftop_3", "models/props_update/c8m1_rooftop_3.mdl", "496 2400 616", "0 -90 0", "shadow_no", "solid_no" );
make_prop( "dynamic", "_yesdraw_rooftop_3_wrongwaya", "models/props_misc/wrongway_sign01_optimized.mdl", "445 2495 678", "0 0 0", "shadow_no", "solid_no", "255 255 255", 217, 17 );
make_prop( "dynamic", "_yesdraw_rooftop_3_wrongwayb", "models/props_misc/wrongway_sign01_optimized.mdl", "445 2305 678", "0 0 0", "shadow_no", "solid_no", "255 255 255", 217, 17 );
make_prop( "dynamic", "_yesdraw_start_wrongwaya", "models/props_misc/wrongway_sign01_optimized.mdl", "2752 1232 854", "0 180 0", "shadow_no", "solid_no", "255 255 255", 217, 17 );
make_prop( "dynamic", "_yesdraw_start_wrongwayb", "models/props_misc/wrongway_sign01_optimized.mdl", "2752 982 854", "0 180 0", "shadow_no", "solid_no", "255 255 255", 217, 17 );

DoEntFire( "!self", "Break", "", 0.0, null, Entities.FindByClassnameNearest( "prop_physics", Vector( 2293, 1340, 359 ), 1 ) );
DoEntFire( "!self", "AddOutput", "angles 90 20 0", 0.0, null, Entities.FindByClassnameNearest( "func_illusionary", Vector( 2296, 1340, 349.91 ), 1 ) );
DoEntFire( "!self", "AddOutput", "origin 2391 1335 16", 0.0, null, Entities.FindByClassnameNearest( "func_illusionary", Vector( 2296, 1340, 349.91 ), 1 ) );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c8m2_subway":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

kill_funcinfclip( 648.595 );	// Delete clip above SKYBOX-cornered roof right of end PAWN shop
make_brush( "_losfix_copcar",		"-80 -1 -8",	"80 1 8",	"9996 5815 16" );
make_brush( "_losfix_semi1",		"-1 -40 -18",	"1 40 18",	"9043 4927 26" );
make_brush( "_losfix_semi2",		"-29 -1 -10",	"28 1 10",	"9073 4913 18" );
make_clip( "_generator_qolstep1", "SI Players", 1, "0 -96 0", "0.1 96 8", "8021 2880 16" );
make_clip( "_generator_qolstep2", "SI Players", 1, "0 -96 0", "0.1 96 8", "8021 3168 16" );
make_clip( "_ladder_deadendrubble_clip", "Everyone", 1, "-18 -39 -87", "13 107 -5", "2149 3922 -242", "0 14 0" );
make_clip( "_ladder_generatorwindow_clipa", "SI Players", 1, "-4 -40 -56", "4 128 231", "7944 2512 425" );
make_clip( "_ladder_generatorwindow_clipb", "SI Players", 1, "-4 -40 -56", "4 128 231", "7568 2512 425" );
make_clip( "_ladder_generatorwindow_clipc", "SI Players", 1, "-170 -10 -56", "214 10 231", "7734 2462 425" );
make_clip( "_ladder_tanksubqol_clip", "Everyone", 1, "-22 3 0", "9 7 152", "6290 3284 -336", "0 -20 0" );
make_clip( "_ladder_tanksubway_clip", "SI Players", 1, "-17 -43 0", "16 -2 8", "6999 2919 -188" );
make_clip( "_ladder_tanksubwreck_clip", "Everyone", 1, "-38 -6 0", "38 1 8", "4306 4053 -231", "0 -21 0" );
make_ladder( "_ladder_deadendrubble_cloned_endfenceshortest", "10195 5726.5 67.766", "-5520 12737 -375", "0 -78.24 0", "0.98 0.2 0" );
make_ladder( "_ladder_endpawnbrick_cloned_trashbagdrop", "8233 3844.5 278", "14396 -3589 -228", "0 90 0", "-1 0 0" );
make_ladder( "_ladder_endpolicefence_cloned_oneunitbroke", "8657 5483.5 92", "1625 240 -40" );
make_ladder( "_ladder_endquickroof_cloned_oneunitbroke", "8657 5483.5 92", "1458 13407 0", "0 -82 0", "-1 -0.14 0" );
make_ladder( "_ladder_eventminigunnew_cloned_eventminigun", "7568 3663.5 184", "188 0 0" );
make_ladder( "_ladder_eventwindowleftB_cloned_endfenceshortest", "10195 5726.5 67.766", "2272 13074 18", "0 -90 0", "1 0 0" );
make_ladder( "_ladder_eventwindowleftT_cloned_eventwindowright", "7568 2816.5 178", "376 0 0" );
make_ladder( "_ladder_genwinglassleft_cloned_firebarrelfence", "8988 5513.5 92", "-1140 -2857 219" );
make_ladder( "_ladder_genwinglassright_cloned_firebarrelfence", "8988 5513.5 92", "-1327 -2857 219" );
make_ladder( "_ladder_innertanker_cloned_nodrawfence", "8419.5 3882 91.5", "-2478 5297 -35", "0 -25 0", "0.91 -0.42 0" );
make_ladder( "_ladder_newrocketboom_cloned_trashbagdrop", "8233 3844.5 278", "5620 12649 132", "0 -90 0", "1 0 0" );
make_ladder( "_ladder_permstuckpawnfence_cloned_endfenceshortest", "10195 5726.5 67.766", "4946 15517 -9", "0 -90 0", "1 0 0" );
make_ladder( "_ladder_permstuckpawnrear_cloned_eventminigun", "7568 3663.5 184", "3568 1208 -40" );
make_ladder( "_ladder_postsubrubble_cloned_firebarrelfence", "8988 5513.5 92", "13166 -6148 -410", "0 90 0", "-1 0 0" );
make_ladder( "_ladder_quickstepqol_cloned_wrongwayfence", "10362.5 3936 91.5", "-891 704 -63" );
make_ladder( "_ladder_subwaynontrashside_cloned_endalleyfence", "8419.5 3882 91.5", "-856 12513 -352", "0 -90 0", "0 -1 0" );
make_ladder( "_ladder_tanksubqol_cloned_copcarsbrick", "9732.5 6199.5 104", "2905 -7753 -376", "0 40.35 0", "0.76 0.64 0" );
make_ladder( "_ladder_tanksubway_cloned_copcarsbrick", "9732.5 6199.5 104", "-2712 -3295 -372" );
make_ladder( "_ladder_tanksubwreck_cloned_endfenceshortest", "10195 5726.5 67.766", "15871 5658 244.4", "0 158.73 -6", "-0.37 -0.93 0" );
make_ladder( "_ladder_tankwarprubble_cloned_warehousewindow", "8472 3819.5 312", "-3042 5533 -610", "0 -30 0", "-0.5 -0.86 0" );
make_ladder( "_ladder_windowdropleft_cloned_trashbagdrop", "8233 3844.5 278", "4344 12888 -124", "0 -90 0", "1 0 0" );
make_ladder( "_ladder_windowdropright_cloned_trashbagdrop", "8233 3844.5 278", "11007 -3519 -124", "0 90 0", "-1 0 0" );
make_prop( "dynamic", "_yesdraw_generatorroom", "models/props_update/c8m2_generatorroom.mdl", "7748 2448.1 513", "0 -90 0", "shadow_no", "solid_no" );
make_prop( "dynamic", "_yesdraw_planka", "models/props_swamp/plank001b_192.mdl", "7283 2638 424", "110 0 90", "shadow_no", "solid_no" );
make_prop( "dynamic", "_yesdraw_plankb", "models/props_swamp/plank001b_192.mdl", "7477 2638 444", "80 0 90", "shadow_no", "solid_no" );
make_prop( "dynamic", "_yesdraw_plankc", "models/props_swamp/plank001b_192.mdl", "8040 2638 435", "93 0 90", "shadow_no", "solid_no" );
make_prop( "dynamic", "_yesdraw_tallroof_hunt1", "models/props_update/c8m1_rooftop_3.mdl", "8961 4364 1215.9", "0 0 0", "shadow_no" );
make_prop( "dynamic", "_yesdraw_tallroof_hunt2", "models/props_update/c8m1_rooftop_3.mdl", "8548 4364 1215.99", "0 0 0", "shadow_no" );
make_prop( "dynamic", "_yesdraw_wrongwaya", "models/props_misc/wrongway_sign01_optimized.mdl", "7540 2556 410", "0 0 0", "shadow_no", "solid_no", "255 255 255", 220, 0 );
make_prop( "dynamic", "_yesdraw_wrongwayb", "models/props_misc/wrongway_sign01_optimized.mdl", "7971 2556 410", "0 180 0", "shadow_no", "solid_no", "255 255 255", 220, 0 );
make_prop( "dynamic", "_yesdraw_wrongwayc", "models/props_misc/wrongway_sign01_optimized.mdl", "7756 2440 410", "0 90 0", "shadow_no", "solid_no", "255 255 255", 220, 0 );
patch_ladder( "8657 5483.5 92", "0 -1 0" );

con_comment( "FIX:\tGenerator Room has 13 hanging lights and 9 need to be made non-solid." );

unsolidify_model( "models/props/de_nuke/IndustrialLight01.mdl" );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c8m3_sewers":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

kill_entity( Entities.FindByClassnameNearest( "func_brush", Vector( 10528, 6170.91, 62.5938 ), 1 ) );
kill_entity( Entities.FindByClassnameNearest( "func_brush", Vector( 10528, 6558.31, 62.5938 ), 1 ) );
kill_entity( Entities.FindByClassnameNearest( "func_brush", Vector( 14794, 11567.2, 625.313 ), 1 ) );
kill_funcinfclip( 525.363 );		// Delete clip at end manhole blocking left rooftop
kill_funcinfclip( 546.035 );		// Delete clip at end manhole blocking right rooftop
kill_funcinfclip( 767.643 );		// Delete clip blocking Burger Tank fence and 3 unusable ladders
kill_funcinfclip( 851.288 );		// Delete clip blocking EASTERN WATERWORKS rooftop above Scissor Lift
make_atomizer( "_atomizer_bsp_forklift", "12695 8149 16", "models/props\\cs_assault\\forklift_brokenlift.mdl", 60 );
make_atomizer( "_atomizer_bsp_manholecars", "14272 11613 -20", "models/props_vehicles/cara_82hatchback.mdl", 60 );
make_atomizer( "_atomizer_bsp_manholedump", "14272 11613 -30", "models/props_junk/dumpster.mdl", 60 );
make_atomizer( "_atomizer_bsp_manholeflip", "14272 11613 -10", "models/props_vehicles/cara_95sedan_wrecked.mdl", 60 );
make_brush( "_losfix_copcar",		"-1 -70 -8",	"1 70 8",	"10222 5963 16" );
make_brush( "_losfix_gasstation_los", "-45 -185 0", "45 185 1", "12659 6089 312" );
make_brush( "_losfix_pipes",		"-56 -1 -8",	"68 1 20",	"13490 7744.5 -249" );
make_brush( "_losfix_semi",		"-1 -48 -15",	"1 48 15",	"11906 6664 30" );
make_brush( "_losfix_sewage_tank1a",	"-132 -1 -6",	"132 1 6",	"13472 8306 -251" );
make_brush( "_losfix_sewage_tank1b",	"-132 -1 -6",	"132 1 6",	"13472 7893 -251" );
make_brush( "_losfix_sewage_tank2a",	"-132 -1 -6",	"132 1 6",	"13042 7891 -251" );
make_brush( "_losfix_sewage_tank2b",	"-132 -1 -6",	"132 1 6",	"13042 8120 -251" );
make_brush( "_losfix_sewage_tank2c",	"-132 -1 -6",	"132 1 6",	"13040 8300 -251" );
make_clip( "_burgerfence_blocker1", "SI Players", 1, "-419 -675 0", "-409 615 1202", "10137 6395 8" );
make_clip( "_burgerfence_blocker2", "SI Players", 1, "-419 -675 0", "384 -665 1202", "10137 6395 8" );
make_clip( "_burgerfence_blocker3", "SI Players", 1, "-419 605 0", "384 615 1202", "10137 6395 8" );
make_clip( "_ladder_burgerfenceshared_clip", "SI Players", 1, "0 -434 0", "6 398 149", "10521 6386 8" );
make_clip( "_ladder_scissormini_clipleft", "Everyone", 1, "-18 -8 0", "18 8 106", "12044 7545 323", "0 -45 0" );
make_clip( "_ladder_scissormini_clipright", "Everyone", 1, "-18 -8 0", "18 8 106", "12094 7545 323", "0 45 0" );
make_clip( "_ladder_warehousealley_clip", "Everyone", 1, "-22 0 -32", "39 4 96", "12789 8317 48" );
make_clip( "_losfix_gasstation_coll", "SI Players", 1, "-45 -185 0", "45 185 3", "12659 6089 312" );
make_clip( "_meticulous_funcinfclip01", "SI Players", 1, "-8 -295 0", "8 319 601", "15184 11445 608" );
make_clip( "_meticulous_funcinfclip02", "SI Players", 1, "-156 -6 0", "228 6 473", "14964 11156 736" );
make_clip( "_meticulous_funcinfclip03", "SI Players", 1, "-207 -16 0", "175 61.5 463", "13584 10754 746" );
make_clip( "_waterworks_blocker", "SI Players", 1, "-8 -728 0", "8 358 412", "13008 7408 800" );
make_clip( "_waterworks_collision", "SI Players", 1, "-41 -245 0", "32 247 110", "12761 7407 857" );
make_ladder( "_ladder_brickapartment_cloned_unusedmercyback", "11899.5 12470 232", "-460 -6825 112" );
make_ladder( "_ladder_gasstationfence_cloned_warehousepipe", "11904 8299.5 161", "959 -2392 14" );
make_ladder( "_ladder_overturnedsemiB_cloned_nodrawfence", "12930.5 5831 90", "-2546 3593 511", "0 -14.27 -5", "0.96 -0.27 0" );
make_ladder( "_ladder_overturnedsemiT_cloned_sewerdropB", "14128 8198 -476", "-2795 -2229 688" );
make_ladder( "_ladder_sewerup1_cloned_uppershafts", "12735 10083 -348", "278 445 88" );
make_ladder( "_ladder_sewerup2_cloned_uppershafts", "12735 10083 -348", "278 933 88" );
make_ladder( "_ladder_startpawnrear_cloned_warehousepipe", "11904 8299.5 161", "-768 -3429 -26" );
make_ladder( "_ladder_warehousealley_cloned_endminialley", "13912 10818.5 90", "-1160 -2501 0" );
make_ladder( "_ladder_warehouseexittall_cloned_unusedmercyback", "11899.5 12470 232", "640 -4441 -177" );
make_ladder( "_ladder_warehousemiddleB_cloned_endminialley", "13912 10818.5 90", "-2392 -2811 -45" );
make_ladder( "_ladder_warehousemiddleT_cloned_burgerentrance", "11408 5435.55 110", "59 2641 67" );
make_ladder( "_ladder_warehouserightboxes_cloned_mercyside", "12708 11903.5 232", "-958 -4167 -177" );
make_ladder( "_ladder_warehousewindow_cloned_endminialley", "13912 10818.5 90", "-2857 -2629 -20" );
make_prop( "dynamic", "_burgerfence_wrongwaya", "models/props_misc/wrongway_sign01_optimized.mdl", "10357 7000 65", "0 -90 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_burgerfence_wrongwayb", "models/props_misc/wrongway_sign01_optimized.mdl", "10057 7000 65", "0 -90 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_burgerfence_wrongwayc", "models/props_misc/wrongway_sign01_optimized.mdl", "9757 7000 65", "0 -90 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_ladder_scissormini_pipeB", "models/props_mill/pipeset08d_64_001a.mdl", "12070 7541 351", "90 180 0", "shadow_no" );
make_prop( "dynamic", "_ladder_scissormini_pipeT", "models/props_mill/pipeset08d_64_001a.mdl", "12070 7541 405", "90 180 0", "shadow_no" );
make_prop( "dynamic", "_permstuck_dumpsterspool", "models/props_industrial/wire_spool_02.mdl", "10419 6513 45", "40 65 0", "shadow_no" );
make_prop( "dynamic", "_propladder_gasstation", "models/props_rooftop/acvent02.mdl", "12766 6626 320", "0 180 0" );
make_prop( "dynamic", "_waterworks_wrongwaya", "models/props_misc/wrongway_sign01_optimized.mdl", "13004 6822 855", "0 180 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_waterworks_wrongwayb", "models/props_misc/wrongway_sign01_optimized.mdl", "13004 7122 855", "0 180 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_waterworks_wrongwayc", "models/props_misc/wrongway_sign01_optimized.mdl", "13004 7422 855", "0 180 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_waterworks_wrongwayd", "models/props_misc/wrongway_sign01_optimized.mdl", "13004 7722 855", "0 180 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_waterworks_wrongwaye", "models/props_misc/wrongway_sign01_optimized.mdl", "12914 7765 855", "0 -90 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );

con_comment( "VIS:\tInfected ladder \"_scissormini\" parented to its pipe to force render." );

make_ladder( "_ladder_scissormini_cloned_sewerdropB", "14128 8198 -476", "26197 15730 852.2", "0 -180 0", "0 -1 0" );
EntFire( g_UpdateName + "_ladder_scissormini_cloned_sewerdropB", "SetParent", g_UpdateName + "_ladder_scissormini_pipeT" );

con_comment( "LOGIC:\tGas Station explosion will spawn a new Infected ladder." );

function c8m3_DynamicLadder()
{
	make_ladder( "_ladder_gasdynamictop_cloned_burgerbackm", "10516.5 6416 84.4385", "2187 197 159" );
	make_ladder( "_ladder_gasdynamicbot_cloned_burgerbackm", "10516.5 6416 84.4385", "2187 197 31" );
}

EntFire( "gas_explosion_sound_relay", "AddOutput", "OnTrigger worldspawn:CallScriptFunction:c8m3_DynamicLadder:2:-1" );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c8m4_interior":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

EntFire( g_UpdateName + "_yesdrawskylight_hanginglight*", "skin", "1" );
kill_entity( Entities.FindByName( null, "vent_ceiling_02" ) );
kill_entity( Entities.FindByName( null, "vent_ceiling_03" ) );
make_brush( "_losfix_icucurtain1_los", "-16 -3.6 0", "16 3.6 128", "11936 14463 424" );
make_brush( "_losfix_icucurtain2_los", "-16 -3.6 0", "16 3.6 128", "11936 14575 424" );
make_brush( "_losfix_icucurtain3_los", "-16 -3.6 0", "16 3.6 128", "11936 14687 424" );
make_brush( "_losfix_icucurtain4_los", "-16 -3.6 0", "16 3.6 128", "11936 14799 424" );
make_brush( "_losfix_icucurtain5_los", "-16 -3.6 0", "16 3.6 128", "11936 14911 424" );
make_clip( "_losfix_icucurtain1_coll", "Everyone", 1, "-16 -3.6 0", "16 3.6 128", "11936 14463 424" );
make_clip( "_losfix_icucurtain2_coll", "Everyone", 1, "-16 -3.6 0", "16 3.6 128", "11936 14575 424" );
make_clip( "_losfix_icucurtain3_coll", "Everyone", 1, "-16 -3.6 0", "16 3.6 128", "11936 14687 424" );
make_clip( "_losfix_icucurtain4_coll", "Everyone", 1, "-16 -3.6 0", "16 3.6 128", "11936 14799 424" );
make_clip( "_losfix_icucurtain5_coll", "Everyone", 1, "-16 -3.6 0", "16 3.6 128", "11936 14911 424" );
make_clip( "_yesdrawskylight_clipwaya", "SI Players", 1, "-8 -300 0", "0 300 376", "11912 12204 448" );
make_clip( "_yesdrawskylight_clipwayb", "SI Players", 1, "-512 0 0", "512 8 376", "12416 11904 448" );
make_clip( "_yesdrawskylight_clipwayc", "SI Players", 1, "0 -300 0", "8 300 376", "12920 12204 448" );
make_ladder( "_ladder_skylighthanglight_cloned_shortestvent", "12918.5 15104 551", "27454 -726 -108", "0 90 0", "0 -1 0" );
make_ladder( "_ladder_ventceiling02left_cloned_sinkvent", "12918.5 15104 551", "-1856 27209 -48", "0 -90 0", "0 1 0" );
make_ladder( "_ladder_ventceiling03right_cloned_sinkvent", "12918.5 15104 551", "169 -689 10" );
make_prop( "dynamic", "_ventceiling02_static", "models/props_vents/VentBreakable01_DM01_Frame.mdl", "13248 14320 554", "90 90 0", "shadow_no", "solid_no" );
make_prop( "dynamic", "_yesdrawskylight_acvent1", "models/props_rooftop/acvent03.mdl", "12343 12237 448", "0 0 0", "shadow_no" );
make_prop( "dynamic", "_yesdrawskylight_acvent2", "models/props_rooftop/acvent03.mdl", "12343 12365 448", "0 0 0", "shadow_no" );
make_prop( "dynamic", "_yesdrawskylight_hanginglight1", "models/props/cs_office/Light_shop.mdl", "12348.2 12200.3 373", "0 0 0", "shadow_no", "solid_no" );
make_prop( "dynamic", "_yesdrawskylight_hanginglight2", "models/props/cs_office/Light_shop.mdl", "12380 12758 373", "0 0 0", "shadow_no", "solid_no" );
make_prop( "dynamic", "_yesdrawskylight_hanginglight3", "models/props/cs_office/Light_shop.mdl", "12380 12911 373", "0 0 0", "shadow_no", "solid_no" );
make_prop( "dynamic", "_yesdrawskylight_roof", "models/props_update/c8m4_skylight_rooftop.mdl", "12416 12216 447", "0 270 0", "shadow_no" );
make_prop( "dynamic", "_yesdrawskylight_wrongway1", "models/props_misc/wrongway_sign01_optimized.mdl", "11903.5 12326.2 511.365", "0 0 0", "shadow_no", "solid_no", "255 255 255", 217, 17 );
make_prop( "dynamic", "_yesdrawskylight_wrongway2", "models/props_misc/wrongway_sign01_optimized.mdl", "11903.5 12070.2 511.365", "0 0 0", "shadow_no", "solid_no", "255 255 255", 217, 17 );
make_prop( "dynamic", "_yesdrawskylight_wrongway3", "models/props_misc/wrongway_sign01_optimized.mdl", "12117.5 11902.2 511.365", "0 90 0", "shadow_no", "solid_no", "255 255 255", 217, 17 );
make_prop( "dynamic", "_yesdrawskylight_wrongway4", "models/props_misc/wrongway_sign01_optimized.mdl", "12415.5 11902.2 511.365", "0 90 0", "shadow_no", "solid_no", "255 255 255", 217, 17 );
make_prop( "dynamic", "_yesdrawskylight_wrongway5", "models/props_misc/wrongway_sign01_optimized.mdl", "12713.5 11902.2 511.365", "0 90 0", "shadow_no", "solid_no", "255 255 255", 217, 17 );
make_prop( "dynamic", "_yesdrawskylight_wrongway6", "models/props_misc/wrongway_sign01_optimized.mdl", "12927.5 12070.2 511.365", "0 180 0", "shadow_no", "solid_no", "255 255 255", 217, 17 );
make_prop( "dynamic", "_yesdrawskylight_wrongway7", "models/props_misc/wrongway_sign01_optimized.mdl", "12927.5 12326.2 511.365", "0 180 0", "shadow_no", "solid_no", "255 255 255", 217, 17 );
make_prop( "dynamic_ovr", "_ventceiling03_static", "models/props_vents/VentBreakable01.mdl", "13090 14416 520", "0 180 0", "shadow_no" );

EntFire( g_UpdateName + "_ladder_skylighthanglight_cloned_shortestvent", "SetParent", g_UpdateName + "_yesdrawskylight_hanginglight1" );

EntFire( g_UpdateName + "_ladder_ventceiling02left_cloned_sinkvent", "SetParent", g_UpdateName + "_ventceiling02_static" );

con_comment( "QOL:\tThe breakable railings in the cafeteria have had their health reduced for Versus-only QoL." );
DoEntFire( "!self", "AddOutput", "health 18", 0.0, null, Entities.FindByClassnameNearest( "func_breakable", Vector( 12423, 12014, 244.5 ), 1 ) );
DoEntFire( "!self", "AddOutput", "health 18", 0.0, null, Entities.FindByClassnameNearest( "func_breakable", Vector( 12278, 12150.5, 308.5 ), 1 ) );
DoEntFire( "!self", "AddOutput", "health 18", 0.0, null, Entities.FindByClassnameNearest( "func_breakable", Vector( 12278, 12716, 308.5 ), 1 ) );
DoEntFire( "!self", "AddOutput", "health 18", 0.0, null, Entities.FindByClassnameNearest( "func_breakable", Vector( 12278, 12935.5, 308.5 ), 1 ) );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c8m5_rooftop":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

make_brush( "_losfix_pipes1",		"-4 -156 -1",	"4 156 1",	"5830 8147 6055.36" );
make_brush( "_losfix_pipes2",		"-4 -156 -1",	"4 156 1",	"5982 8852 6055.36" );
make_clip( "_ladder_helipadcosmetic_clip", "Everyone", 1, "-16 -8 0", "16 -3 3", "7288 8968 6206" );
make_clip( "_ladder_missingpiece_clipl", "Everyone", 1, "-3 -2 0", "16 4 180", "6460 7911 5772", "0 45 0" );
make_clip( "_ladder_missingpiece_clipr", "Everyone", 1, "-8 -2 0", "12 4 180", "6462 7951 5772", "0 -45 0" );
make_ladder( "_ladder_deathchargenew_cloned_deathcharge", "5878 7479.5 5797.9", "268 136 148" );
make_ladder( "_ladder_deathjockeynew_cloned_deathjockey", "6419 9528.5 5797.9", "-470 -104 148" );
make_ladder( "_ladder_helipadclimbable_cloned_satelliteyellow", "6712.5 8704 6112", "-1415.96 15683.6 29", "0.1 -90 0", "0 -1 0" );
make_ladder( "_ladder_helipadcosmetic_cloned_deathcharge", "5878 7479.5 5797.9", "1410 1746.313 -67", "0 0 2.5", "0 -1 0" );
make_ladder( "_ladder_missingpiece_cloned_northgutter", "5878 7479.5 5797.895", "13952 2055 0.25", "0 90 0", "1 0 0" );
make_ladder( "_ladder_saferoomlulz_cloned_rooftopmain", "5924 8561.1 6018", "13896 2362 -447", "0 90 0", "0 1 0", 0 );
make_ladder( "_ladder_startstairwell_cloned_deathjockey", "6419 9528.5 5797.9", "-998 -940.5 -108" );
make_ladder( "_ladder_transformer1_cloned_deathcharge", "5878 7479.5 5797.9", "14206 1770 -112.5", "0 90 0", "1 0 0" );
make_ladder( "_ladder_transformer2_cloned_deathcharge", "5878 7479.5 5797.9", "13174.9 2001.42 -16", "0 90 0", "1 0 0" );
make_ladder( "_ladder_transformer3_cloned_deathjockey", "6419 9528.5 5797.9", "15006 2704 -16", "0 90 0", "-1 0 0" );
make_ladder( "_ladder_transformer4_cloned_deathcharge", "5878 7479.5 5797.9", "1833.28 913.736 -16.5" );
make_ladder( "_ladder_transformer5_cloned_deathjockey", "6419 9528.5 5797.9", "-3190 15179 163.5", "0 -90 0", "1 0 0" );
make_ladder( "_ladder_uponewayside_cloned_longshaft", "7018 8992.5 4800", "-1437.5 16118 166", "0 -90 0", "1 0 0" );
make_prop( "dynamic", "_ladder_missingpiece_pipe", "models/props_rooftop/Gutter_Pipe_256.mdl", "6464 7933 5952", "0 90 0", "shadow_no" );
make_prop( "dynamic", "_ladder_startstairwell_pipe", "models/props_pipes/PipeSet02d_512_001a.mdl", "5421 8586 5587.8", "-90 0 0", "shadow_no" );
make_prop( "dynamic", "_ladder_transformer5_patch", "models/props_pipes/PipeSet32d_256_001a.mdl", "6340 8757 5784", "-90 -64 0", "shadow_no" );
make_prop( "dynamic", "_ladder_uponewayside_pipe", "models/props_pipes/pipeset02d_512_001a.mdl", "7553 9100 5950", "-90 -90 0", "shadow_no" );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*==============================
||                            ||
||        CRASH COURSE        ||
||                            ||
==============================*/

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c9m1_alleys":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

make_atomizer( "_atomizer_bsp_forklift", "-6392 -10719 64", "models/props\\cs_assault\\forklift_brokenlift.mdl", 60 );
make_atomizer( "_atomizer_l4d1_dumpster", "-10312 -9907 0", "models/props_junk/dumpster.mdl", 30 );
make_brush( "_losfix_ambulance",	"-1 -80 -11",	"1 60 11",	"-1431 -4449 71" );
make_brush( "_losfix_boxcar",		"-1 -32 -10",	"1 32 10",	"-7360 -10074 2" );
make_brush( "_losfix_shelf1",		"-1 -28 -5",	"1 28 5",	"-5331 -10944 69" );
make_brush( "_losfix_shelf2",		"-1 -30 -5",	"1 30 5",	"561 -2002 -171" );
make_clip( "_ladder_aftertanker_clipleft", "Everyone", 1, "-14 -4 0", "15 4 608", "-2248 -5372 -224", "0 -55 0" );
make_clip( "_ladder_aftertanker_clipright", "Everyone", 1, "-15 -4 0", "14 4 608", "-2292 -5372 -224", "0 55 0" );
make_clip( "_ladder_dualwindowshared_clip", "SI Players and AI", 1, "-8 -186 0", "32 186 16", "-7960 -10924 191", "42 0 0" );
make_clip( "_solidify_acunit", "Everyone", 1, "-4 -59 -7", "4 59 136", "-708 -1224 23" );
make_ladder( "_ladder_aftertankerB_cloned_flatnosetruck", "-6318 -10227 191.524", "4048 4867 -384" );
make_ladder( "_ladder_aftertankerT_cloned_flatnosetruck", "-6318 -10227 191.524", "4048 4867 0" );
make_ladder( "_ladder_armybarricadeleftfront_cloned_armybarricadeleftback", "-1601 -4847 126", "-3226 -9766 0", "0 -180 0", "0 -1 0" );
make_ladder( "_ladder_deliveryfence_cloned_extrabarricade", "-368 -7289 -159.75", "-6281 -3706 291" );
make_ladder( "_ladder_dualwindowleft_cloned_startacunit", "-8715 -9616 112", "727 -1160 -17" );
make_ladder( "_ladder_dualwindowright_cloned_startacunit", "-8715 -9616 112", "727 -1457 -17" );
make_ladder( "_ladder_eventsemitrailer_cloned_semitrailerleft", "-4464 -10412 83.5", "-10119 -946 -193", "0 90 0", "1 0 0" );
make_ladder( "_ladder_firebarrelleft_cloned_firebarrelright", "-4581 -9840 128", "-14660 -5157 -64", "0 90 0", "0 -1 0" );
make_ladder( "_ladder_gooddeliveryvan_cloned_fencedinstart", "-8308 -10255 140", "5414 -5752 -35", "0 -30 0", "-0.5 -0.86 0" );
make_ladder( "_ladder_parkourpipeB_cloned_stainedfence", "-2953 -10850 93.792", "8003 -12985 1246", "-21 -90 0", "-1 0 0" );
make_ladder( "_ladder_parkourpipeT_cloned_endbackfence", "-768 -865 -148", "-3712 -9404 553", "0 90 0", "-1 0 0" );
make_ladder( "_ladder_parkourtruck_cloned_truckpassage", "-2528 -9543 128", "6483 -12894 -94", "0 -90 0", "-1 0 0" );
make_ladder( "_ladder_semifenceleft_cloned_endbackfence", "-768 -865 -148", "-3298 -9394 224" );
make_ladder( "_ladder_semifenceright_cloned_endbackfence", "-768 -865 -148", "-3682 -9394 224" );
make_ladder( "_ladder_semitrailerright_cloned_semitrailerleft", "-4464 -10412 83.5", "310 7 0" );
make_ladder( "_ladder_shortvanqol_cloned_shortwarehouse", "-5615 -10230.5 32", "-1398 -9 4" );
make_ladder( "_ladder_wreckedboxcar_cloned_bridgesemitrailer", "-1486.02 -3948.02 143", "-1860 -2843 -88" );
make_ladder( "_ladder_yesdrawwindow_cloned_boxwreckback", "-3452 -8277 71.4813", "-1028 -2347 -8" );
make_prop( "dynamic", "_yesdrawwindow_surface", "models/props_update/c9m1_nodraw_window.mdl", "-4350.5 -10816 192", "0 270 0", "shadow_no" );
patch_ladder( "-5432 -11009 224", "-450 0 0" );		// Move ladder on long brick wall closer to fence
patch_ladder( "-7056 -11023 140", "360 0 0" );		// Move ladder behind fence closer to play
patch_nav_checkpoint( "337 -1550 -176" );

con_comment( "PROP:\tDumpster near \"_ladder_yesdrawwindow\" moved to improve accessibility." );

kill_entity( Entities.FindByClassnameNearest( "prop_physics", Vector( -4433.81, -10580.1, 1.9375 ), 8 ) );
make_prop( "physics", "_replacement_dumpster", "models/props_junk/dumpster.mdl", "-4392 -10597 5", "0 90 0", "shadow_no" );

con_comment( "LOGIC:\tLowered health of 4 breakwalls from 8.3 scratches to 5 scratches." );

DoEntFire( "!self", "AddOutput", "health 30", 0.0, null, Entities.FindByClassnameNearest( "func_breakable", Vector( -1672, -5952, 96 ), 1 ) );
DoEntFire( "!self", "AddOutput", "health 30", 0.0, null, Entities.FindByClassnameNearest( "func_breakable", Vector( -1672, -5696, 96 ), 1 ) );
EntFire( "zombie_breakwall01", "AddOutput", "health 30" );
EntFire( "zombie_breakwall09", "AddOutput", "health 30" );

con_comment( "KILL:\tDeleted 5 func_brush wooden planks and 5 func_brush entry blockers." );

EntFire( "versus_doorblockers", "Kill" );

kill_funcinfclip( 145.969 );		// Delete clip in 1st closet
kill_funcinfclip( 206.482 );		// Delete clip in 2nd closet
kill_funcinfclip( 159.308 );		// Delete clip in 3rd closet
kill_funcinfclip( 146.816 );		// Delete clip in 4th closet
kill_funcinfclip( 129.286 );		// Delete clip in 5th closet

// It's a secret to everybody. Except you.

local hndCrowbar = Entities.FindByClassnameNearest( "weapon_melee_spawn", Vector( 112, -2512, -175 ), 8 );

if ( SafelyExists( hndCrowbar ) && hndCrowbar.GetModelName() == "models/weapons/melee/w_crowbar.mdl" )
{
	make_prop( "dynamic", "_concerned_citizen", "models/editor/playerstart.mdl", "123 -2394 -191", "0 270 10", "shadow_no", "solid_yes", "50 50 50" );
	make_prop( "dynamic", "_concerned_ply1", "models/props_highway/plywood_01.mdl", "163 -2415 -166", "0 0 0", "shadow_no" );
	make_prop( "dynamic", "_concerned_ply2", "models/props_highway/plywood_01.mdl", "163 -2415 -170", "0 0 0", "shadow_no" );

	DoEntFire( "!self", "skin", "1", 0.0, null, hndCrowbar );
	DoEntFire( "!self", "AddOutput", "weaponskin 1", 0.0, null, hndCrowbar );
}

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c9m2_lots":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

make_brush( "_losfix_gen1a",		"-1 -24 -8",	"1 24 8",	"6853 5881 50" );
make_brush( "_losfix_gen1b",		"-14 -1 -8",	"15 1 8",	"6837 5885 50" );
make_brush( "_losfix_gen2a",		"-1 -28 -8",	"1 28 8",	"7498 6786 55" );
make_brush( "_losfix_gen2b",		"-12 -1 -8",	"13 1 8",	"7484 6779 55" );
make_brush( "_losfix_semi1a",		"-1 -32 -13",	"1 32 13",	"4519 -91 -206" );
make_brush( "_losfix_semi1b",		"-40 -1 -13",	"41 1 13",	"4477 -121 -206" );
make_brush( "_losfix_semi2",		"-1 -50 -15",	"1 50 15",	"3560 4539 10" );
make_ladder( "_ladder_armybusfront_cloned_finalebus", "6547.86 6579 107.421", "623 -9374 -262", "0 34.7 0", "-0.57 0.82 0" );
make_ladder( "_ladder_backfenceright_cloned_backfenceleft", "4631 4016 76", "18 579 0" );
make_ladder( "_ladder_bluecontainerplus_cloned_bluecontainer", "3952 2421 -55.5", "1464 6691 11", "0 -90 0", "-1 0 0" );
make_ladder( "_ladder_buggycullfix_cloned_bluecontainer", "3952 2421 -55.5", "1810 4245 -124", "0 -144.2 0", "-0.58 0.81 0" );
make_ladder( "_ladder_containeryardsemi_cloned_metalsupplysemi", "4388 2361 -33.3145", "5405 -1211 2", "0 90 0", "0 -1 0" );
make_ladder( "_ladder_crashedbus_cloned_finalebus", "6547.86 6579 107.421", "7859 -9216 -265", "0 61.75 0", "-0.9 0.44 0" );
make_ladder( "_ladder_finaleshelffront_cloned_finaleshelfback", "8724 6143 320", "2369 14507 0", "0 -90 0", "-1 0 0" );
make_ladder( "_ladder_permstuck_cloned_finalecornerfence", "5920 7375 124", "-130 752 1" );
make_ladder( "_ladder_startareasemi_cloned_metalsupplysemi", "4388 2361 -33.3145", "-1583 4005 -114", "0 -93.25 0", "0 1 0" );
make_ladder( "_ladder_startfenceright_cloned_startfenceleft", "1456 -1675 -148", "-370 0 0" );
make_ladder( "_ladder_startroofbrick_cloned_startroofpipe", "1788.5 -1545 -60", "-697 -3531 -24", "0 90 0", "1 0 0" );
make_ladder( "_ladder_warehousesemi_cloned_metalsupplysemi", "4388 2361 -33.3145", "-538 7796 115", "0 -70.42 0", "-0.34 0.94 0" );
make_ladder( "_ladder_whitecontainer_cloned_bluecontainer", "3952 2421 -55.5", "625 7652 24", "0 -96.9 0", "-1 0.1 0" );
make_prop( "dynamic", "_solidify_startacvent1", "models/props_rooftop/acvent01.mdl", "-99.0076 -574.692 310.902", "18.5 0 0", "shadow_no" );
make_prop( "dynamic", "_solidify_startacvent2", "models/props_rooftop/acvent01.mdl", "-99.2042 -750.692 310.934", "18.5 0 0", "shadow_no" );

con_comment( "KILL:\tDeleted 7 func_brush wooden planks and 7 func_brush entry blockers." );

EntFire( "versus_doorblockers", "Kill" );

kill_funcinfclip( 149.409 );		// Delete clip in 1st closet
kill_funcinfclip( 150.29 );		// Delete clip in 2nd closet
kill_funcinfclip( 142.109 );		// Delete clip in 3rd closet
kill_funcinfclip( 137.706 );		// Delete clip in 4th closet
kill_funcinfclip( 149.676 );		// Delete clip in 5th closet
kill_funcinfclip( 159.458 );		// Delete clip in 6th closet
EntFire( "worldspawn", "RunScriptCode", "kill_funcinfclip( 159.458 )", 1 );		// Delete clip in 7th closet (same)

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*==============================
||                            ||
||         DEATH TOLL         ||
||                            ||
==============================*/

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c10m1_caves":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

kill_funcinfclip( 698.195 );		// Delete clip directly above bridge tunnel entrance, then patch in exploits created
kill_funcinfclip( 1086.93 );		// Delete clip on tunnel entrance side of the hill
kill_funcinfclip( 1105.65 );		// Delete clip on overpass side of the hill
make_brush( "_losfix_semi",		"-50 -1 -15",	"50 1 15",	"-12260 -11102 -49" );
make_brush( "_losfix_van1",		"-48 -1 -8",	"48 1 8",	"-12318 -8360 -56" );
make_brush( "_losfix_van2",		"-1 -45 -8",	"1 45 8",	"-12990 -6644 -56" );
make_clip( "_ladder_bridgetunnel_backboard", "Everyone", 1, "-248 -10 -84", "308 6 48", "-12348 -9814 272" );
make_clip( "_ladder_bridgetunnel_clip", "Everyone", 1, "-8 -8 0", "22 3 74", "-12617 -9856 -50", "0 21 0" );
make_clip( "_meticulous_funcinfclip01", "SI Players", 1, "-415 -16 0", "401 45 782", "-12353 -9664 496" );
make_clip( "_meticulous_funcinfclip02", "SI Players", 1, "-8 -420 -128", "45 550 782", "-11980 -9735 496" );
make_clip( "_meticulous_funcinfclip03", "SI Players", 1, "-8 -89 0", "45 55 782", "-12031 -9735 496" );
make_clip( "_meticulous_funcinfclip04", "SI Players", 1, "-38 -16 -144", "218 16 782", "-12975 -9745 496", "0 23 0" );
make_clip( "_yesdrawcliff_clip1", "SI Players", 1, "-510 -17 -128", "464 17 782", "-11472 -10279 496", "0 -11 0" );
make_clip( "_yesdrawcliff_clip2", "SI Players", 1, "-510 -17 -128", "464 17 782", "-10881 -10752 496", "0 108 0" );
make_ladder( "_ladder_bridgetunnelB1_cloned_endfencedumpster", "-12168 -5667 -12", "-467 -4199 22" );
make_ladder( "_ladder_bridgetunnelB2_cloned_endfencesafehouse", "-10352 -4599 677.106", "-2912 -5267 -3532", "17 0 0" );
make_ladder( "_ladder_bridgetunnelT_cloned_firsttunnelhole", "-12352 -8413 56", "-115 -1411 320" );
make_ladder( "_ladder_trafficlightB_cloned_secondtunnelhole", "-13047.5 -6072 56", "-14008 4027 3239", "-16 72 -3", "0.32 0.95 0" );
make_ladder( "_ladder_trafficlightT_cloned_secondtunnelhole", "-13047.5 -6072 56", "-14053 3927 3628", "-16.8 72 -3", "0.32 0.95 0" );
make_prop( "dynamic", "_bridgetunnel_wrongway", "models/props_misc/wrongway_sign01_optimized.mdl", "-11988 -9752 544", "0 180 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_yesdrawcliff_rocks1", "models/props_wasteland/rock_cliff01.mdl", "-11723 -9966 520", "0 273 0", "shadow_no" );
make_prop( "dynamic", "_yesdrawcliff_rocks2", "models/props_wasteland/rock_cliff01.mdl", "-11429 -10350 520", "0 0 0", "shadow_no" );
make_trigmove( "_duckqol_trafficlight", "Duck", "-8 -8 -32", "8 16 32", "-12158 -9866 60" );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c10m2_drainage":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

make_brush( "_losfix_bridge_base1",	"-19 -1 -78",	"19 1 78",	"-8693 -8517 -498" );
make_brush( "_losfix_bridge_base2",	"-53 -1 -35",	"53 1 35",	"-8404 -8517 -541" );
make_brush( "_losfix_bridge_base3",	"-19 -1 -78",	"19 1 78",	"-8115 -8517 -498" );
make_brush( "_losfix_bridge_base4",		"-18 -40 -1",	"20 42 1",	"-8693 -8568 -400" );
make_brush( "_losfix_bridge_base5",		"-18 -40 -1",	"20 42 1",	"-8117 -8568 -400" );
make_brush( "_losfix_dynamic_bridge1",		"-107 -1 -84",	"107 1 84",	"-8566 -8525 -289" );
make_brush( "_losfix_dynamic_bridge2",		"-107 -1 -84",	"107 1 84",	"-8243 -8525 -289" );
make_brush( "_losfix_dynamic_bridge_floor1",	"-134 -43 -1",	"134 43 1",	"-8538 -8566 -196" );
make_brush( "_losfix_dynamic_bridge_floor2",	"-134 -43 -1",	"134 43 1",	"-8270 -8566 -196" );
make_brush( "_losfix_van",		"-1 -108 -14",	"1 108 14",	"-7071 -5218 -30" );
make_clip( "_ladder_quickstairwell_clip", "SI Players", 1, "-8 -1 0", "8 1 28", "-6394 -7264.7 89", "0 -20 0" );
make_clip( "_ladder_starttriplebig_clip", "Everyone", 1, "-48 -16 -22", "66 16 1", "-11632 -8168 -231" );
make_ladder( "_ladder_endtrainbox_cloned_endchainlink", "-6592 -5341 5.2833", "-1659 -382 -6" );
make_ladder( "_ladder_quickstairwell_cloned_wrongturn", "-6592 -5313 14.2833", "218 -1949 -2" );
make_ladder( "_ladder_starttriplebig_cloned_startcoolingtanks", "-11639 -8492 -350", "84 246 0" );
make_ladder( "_ladder_warewinright_cloned_wrongturn", "-6592 -5313 14.2833", "0 -687 0" );

con_comment( "MOVER:\tLOS dynamic fixes parented to move with bridge." );

EntFire( g_UpdateName + "_losfix_dynamic_bridge1", "SetParent", "platform_01" );
EntFire( g_UpdateName + "_losfix_dynamic_bridge2", "SetParent", "platform_02" );
EntFire( g_UpdateName + "_losfix_dynamic_bridge_floor1", "SetParent", "platform_01" );
EntFire( g_UpdateName + "_losfix_dynamic_bridge_floor2", "SetParent", "platform_02" );

con_comment( "PROP:\tBarrels at end of sewers moved to reduce stuck-warp obligation." );

Entities.FindByClassnameNearest( "prop_physics", Vector( -7055, -6681, -205 ), 8 ).SetOrigin( Vector( -7055, -6731, -208 ) );
Entities.FindByClassnameNearest( "prop_physics", Vector( -7016, -6697, -206 ), 8 ).SetOrigin( Vector( -7016, -6747, -209 ) );
Entities.FindByClassnameNearest( "prop_physics", Vector( -7000, -6674, -205 ), 8 ).SetOrigin( Vector( -7000, -6724, -208 ) );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c10m3_ranchhouse":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

kill_funcinfclip( 889.728 );		// Delete HERSCH SHIPPING clip
kill_funcinfclip( 421.059 );		// Delete clip above rooftop ramp
make_brush( "_losfix_ambulance1",	"-1 -100 -7",	"1 100 7",	"-5924 -1034 -39" );
make_brush( "_losfix_ambulance2",	"-1 -40 -8",	"1 40 8",	"-5965 -1134 -38" );
make_brush( "_losfix_bus1",		"-1 -100 -14",	"1 100 14",	"-9815 -3582 -43" );
make_brush( "_losfix_bus2",		"-1 -50 -14",	"1 50 14",	"-9782 -3864 -43" );
make_brush( "_losfix_bus3",		"-50 -1 -14",	"41 1 14",	"-9857 -3507 -43" );
make_brush( "_losfix_van",		"-60 -1 -9",	"100 1 9",	"-9414 -2952 -42" );
make_brush( "_losfix_watertank",	"-2 -132 -6",	"2 132 6",	"-10456 -6456 -58" );
make_clip(	"_solidify_permstuck01",	"SI Players",	1,	"-17 -17 0",		"17 17 512",		"-6606 -722 -58" );
make_clip(	"_solidify_permstuck02",	"SI Players",	1,	"-17 -17 0",		"17 17 512",		"-6243 -697 -48" );
make_clip(	"_solidify_permstuck03",	"SI Players",	1,	"-17 -17 0",		"17 17 512",		"-6067 -585 -31" );
make_clip(	"_solidify_permstuck04",	"SI Players",	1,	"-17 -17 0",		"17 17 512",		"-6001 -266 -30" );
make_clip(	"_solidify_permstuck05",	"SI Players",	1,	"-17 -17 0",		"17 17 512",		"-5620.3 -301.3 -50.5" );
make_clip(	"_solidify_permstuck06",	"SI Players",	1,	"-17 -17 0",		"17 17 512",		"-9674 -1131 -10" );
make_clip(	"_solidify_permstuck07",	"SI Players",	1,	"-17 -17 0",		"17 17 512",		"-8918 -860 -42" );
make_clip(	"_solidify_permstuck08",	"SI Players",	1,	"-17 -17 0",		"17 17 512",		"-8570 -994 -66" );
make_clip( "_meticulous_funcinfclip01", "SI Players", 1, "-508 -290 -72", "1134 46 402", "-9348 -7694 584" );
make_ladder( "_ladder_brokenwallL_cloned_graveshort", "-4808 706 6", "2295 383 193" );
make_ladder( "_ladder_brokenwallM_cloned_graveshort", "-4808 706 6", "2327 383 193" );
make_ladder( "_ladder_brokenwallR_cloned_graveshort", "-4808 706 6", "2359 383 193" );
make_ladder( "_ladder_churchcampperimeter_cloned_churchtallninety", "-4024 -520.5 53.5", "-321 2305 119", "0 30 0", "0.5 -0.86 0" );
make_ladder( "_ladder_churchfarperimeter_cloned_churchsandbags", "-2791.83 600.5 236.126", "-296 504 8" );
make_ladder( "_ladder_concretebags_cloned_acunitcorner", "-11120 -7697 0", "-1639 229 0" );
make_ladder( "_ladder_mountaincrawl_cloned_fatcliffladder", "-7808 -2686 110.235", "-14382.5 -10536.8 1636", "0 -131.9 34", "0.81 -0.58 0" );
make_ladder( "_ladder_ramptohersch_cloned_lightsignalfence", "-11841 -5314.5 13", "2967 -2079 670" );
make_ladder( "_ladder_shedelectricbox_cloned_hellcade", "-4543.5 -1344 -14", "-10635 1854 19", "0 90 0", "0 1 0" );
make_ladder( "_ladder_stationfencebackL_cloned_stationfencebackR", "-12819.5 -8032 12.5", "0 1328 0" );
make_ladder( "_ladder_stationfencebackM_cloned_stationfencebackR", "-12819.5 -8032 12.5", "0 629 0" );
make_ladder( "_ladder_stationfencefrontL_cloned_stationfencefrontR", "-12792.5 -6685.7598 11.5", "0 -618 0" );
make_ladder( "_ladder_trainsignalleftB_cloned_sandtowerbest", "-11178 -5312.5 54.5", "-351 -2020 -101" );
make_ladder( "_ladder_trainsignalleftT_cloned_sandtowerbest", "-11178 -5312.5 54.5", "-351 -2020 27" );
make_ladder( "_ladder_trainsignalrightB_cloned_sandtowerbest", "-11178 -5312.5 54.5", "-832 -2020 -101" );
make_ladder( "_ladder_trainsignalrightT_cloned_sandtowerbest", "-11178 -5312.5 54.5", "-832 -2020 27" );
make_prop( "dynamic",		"_losblocker_rock",		"models/props/cs_militia/militiarock03.mdl",	"-5921 -453 19",		"2 277 -120",			"shadow_no" );
make_prop( "dynamic",		"_solidify_tree01",		"models/props_foliage/trees_cluster01.mdl",	"-6608 -712 -84",		"-3.50638 167.38 -6.41996",	"shadow_no" );
make_prop( "dynamic",		"_solidify_tree02",		"models/props_foliage/trees_cluster01.mdl",	"-6240 -704 -36",		"0.0 332.0 0.0",		"shadow_no" );
make_prop( "dynamic",		"_solidify_tree03",		"models/props_foliage/trees_cluster01.mdl",	"-6064 -584 -84",		"-1.16862 16.961 3.82575",	"shadow_no" );
make_prop( "dynamic",		"_solidify_tree04",		"models/props_foliage/trees_cluster01.mdl",	"-6000 -272 -84",		"-1.16862 331.961 3.82575",	"shadow_no" );
make_prop( "dynamic",		"_solidify_tree05",		"models/props_foliage/trees_cluster01.mdl",	"-5622 -298 -84",		"-1.16862 106.961 3.82575",	"shadow_no" );
make_prop( "dynamic",		"_solidify_tree06",		"models/props_foliage/trees_cluster01.mdl",	"-9678.08 -1120 11.46",		"-15.8186 151.677 -1.38363",	"shadow_no" );
make_prop( "dynamic",		"_solidify_tree07",		"models/props_foliage/trees_cluster01.mdl",	"-8914.98 -852.481 -26.4875",		"0 317 0",	"shadow_no" );
make_prop( "dynamic",		"_solidify_tree08",		"models/props_foliage/trees_cluster01.mdl",	"-8568 -984 -52", "1.17358 181.777 -6.60183",	"shadow_no" );
make_prop( "dynamic",		"_solidify_tree09",		"models/props_foliage/trees_cluster02.mdl",	"-7168 -880 -91.8731", "-6.18811 26.8478 12.0217",	"shadow_no" );
make_prop( "dynamic",		"_solidify_tree10",		"models/props_foliage/trees_cluster02.mdl",	"-9664 -1400 -36.5395", "-15.8186 151.677 -1.38363",	"shadow_no" );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c10m4_mainstreet":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

kill_entity( Entities.FindByClassnameNearest( "func_breakable", Vector( -1335, -4910, 244 ), 1 ) );
kill_funcinfclip( 1062.11 );
kill_funcinfclip( 773.493 );
//kill_funcinfclip( 928.269 );		// Delete clip above bookstore mid-event
kill_funcinfclip( 1055.05 );		// Delete clip above start area's tall hilltop
kill_funcinfclip( 718.274 );		// Delete clip above small Hunter-only roof bit that's non-NODRAW/culling
kill_funcinfclip( 800.786 );		// 1st house: Sliver of frontal access for Hunter/Jockey
// kill_funcinfclip( 805.326 );		// 2nd house: SKYBOX'd and completely irredeemable
// kill_funcinfclip( 783.598 );		// 3rd house: SKYBOX'd on right side, far away from action, would only confuse
kill_funcinfclip( 801.26 );		// 4th house: Useful but niche Tank perch with rooftop to hide with
kill_funcinfclip( 775.207 );		// 5th house: In the action, maybe a useful Smoker
kill_funcinfclip( 781.82 );		// 6th house: In the action, same (most rooftop real estate for SI so far)
kill_funcinfclip( 773.906 );		// 7th house: Best new Tank rocking rooftop, definitely needs a ladder
kill_funcinfclip( 769.448 );		// 8th house: Also good, easy jump from 7 but every USEFUL house warrants a ladder
kill_funcinfclip( 773.906 );		// 9th house: Out of the action and useless, open by good gesture only
//kill_funcinfclip( 748.323 );		// Delete clip above neighboring rooftop to new stained wall ladder
kill_funcinfclip( 1156 );		// Delete clip over WELCOME TO HELL barricade
kill_funcinfclip( 808.497 );		// Delete clip above FINE ANTIQUES building next to THEATRE
make_atomizer( "_atomizer_bsp_carflorist", "-572 -2019 -48", "models/props_vehicles/cara_82hatchback.mdl", 60 );
make_brush( "_losfix_bus1",		"-1 -128 -10",	"1 156 10",	"-1264 -4031 -54" );
make_brush( "_losfix_bus2",		"-30 -1 -10",	"29 1 10",	"-1292 -3874 -54" );
make_brush( "_losfix_truck",		"-1 -40 -11",	"1 40 11",	"-3636 -1019 -53" );
make_brush( "_losfix_van1",		"-100 -1 -9",	"100 1 9",	"-3340 -1677 -47" );
make_brush( "_losfix_van2",		"-70 -1 -8",	"70 1 8",	"-762 -2268 -48" );
make_clip( "_fineantique_surf_collision", "SI Players", 1, "-320 -240 -56", "320 240 0", "1968 -4608 320" );
make_clip( "_hellcade_clipa", "SI Players", 1, "-240 -8 0", "240 17 1792", "-5360 -504 -64" );
make_clip( "_hellcade_clipb", "SI Players", 1, "-17 -830 0", "8 507 1792", "-5605 -1001 -64" );
make_clip( "_hellcade_clipc", "SI Players", 1, "-240 -8 0", "304 17 1792", "-5360 -1857 -64" );
make_clip( "_hellcade_permstuck", "SI Players", 1, "-8 -216 0", "8 216 17", "-5115 -1028 -49" );
make_clip( "_ladder_eventskybridge_clip", "SI Players", 1, "-11 -23 0", "2 46 8", "-1314 -4766 296" );
make_clip( "_ladder_starthilltop_clip", "SI Players", 1, "-16 -8 0", "16 8 2", "-4608 -1906 520", "0 -17.7 0" );
make_clip( "_losblocker_deliveryclip", "Survivors", 1, "-57 -113 0", "56 171 1781", "583 -2463 -52", "0 -20 0" );
make_clip( "_meticulous_funcinfclip01", "SI Players", 1, "-908 -17 -440", "114 17 1342", "-3906 -3153 384" );
make_clip( "_meticulous_funcinfclip02", "SI Players", 1, "-17 -595 -731", "17 737 1051", "-4935 -2560 675", "0 13 0" );
make_clip( "_meticulous_funcinfclip03", "SI Players", 1, "-679 -581 -81", "635 120 1169", "2038 -3044 560" );
make_clip( "_yesdrawhellcade_collision", "SI Players", 1, "-0.5 -49.5 -30.5", "0.5 49.5 30.5", "-5254.8 -691.5 17", "13.3 14.3 1.5" );
make_ladder( "_ladder_churchleftm3mirr_cloned_churchrearwrong", "-3286.5 58 236", "0 -65.2147 0" );
make_ladder( "_ladder_eventfinalalley_cloned_endgraffiti", "319 -5601 38", "-6037 -5519 -24", "0 90 0", "0 -1 0" );
make_ladder( "_ladder_eventpipewires_cloned_endchainlink", "287 -5293 21", "319 -10635 -6", "0 180 0", "1 0 0" );
make_ladder( "_ladder_eventskybridge_cloned_churchwalltallest", "-2736 -152 118.5", "-4058 -4917 -54", "0 -180 0", "-1 0 0" );
make_ladder( "_ladder_fineantiques_cloned_enddumpstertall", "-1190 -5451 100", "2797 1031 152" );
make_ladder( "_ladder_house5sideup_cloned_churchwallmedium", "-2733 -521 80", "-2229 -1199 0", "0 -180 0", "-1 0 0" );
make_ladder( "_ladder_house6semifront_cloned_house6semiback", "1429.1 -943.16 82.5", "2827 -1996 -2", "0 -180 0", "-0.26 -0.96 0" );
make_ladder( "_ladder_house6telepole_cloned_eventbarricadepipe", "884 -3621 168", "-505 2313 -1134", "1 11.8 -20", "0.2 -0.97 0" );
make_ladder( "_ladder_house7Bthin_cloned_balconytrimmed", "226 -2715.5 67", "2023 -3266 -6", "0 180 0", "0 -1 0" );
make_ladder( "_ladder_house7Mthick_cloned_quadwindows", "2663.5 -2426 280", "-628 -3115 -40", "0 90 0", "0 -1 0" );
make_ladder( "_ladder_house7Tthick_cloned_quadwindows", "2663.5 -2426 280", "-628 -3067 705", "13 90 0", "0 -1 0" );
make_ladder( "_ladder_house8Bthin_cloned_balconytrimmed", "226 -2715.5 67", "2422 -3486 25", "0 180 0", "0 -1 0" );
make_ladder( "_ladder_house8Tthick_cloned_policebarricade", "52.8641 -994.878 -4.11075", "3125 -636 278", "0 -90 0", "0 -1 0" );
make_ladder( "_ladder_naturalstains_cloned_awningpipe", "2720 -1734 231.5", "-460 -794 97" );
make_ladder( "_ladder_semitrucknose_cloned_startgenerator", "-2932 -770.5 1", "3781 -1933 -17", "0 -30 0", "-0.5 -0.87 0" );
make_ladder( "_ladder_stainedboard_cloned_surplusfluff", "99 -4310.5 224", "5683 -3552 24", "0 -90 0", "1 0 0" );
make_ladder( "_ladder_starthilltopB_cloned_awningpipe", "2720 -1734 231.5", "-6639.9 754.3 259", "4 -17.7 14", "0.32 0.95 0" );
make_ladder( "_ladder_starthilltopM_cloned_awningpipe", "2720 -1734 231.5", "-6642.8 682.2 538", "4 -17.7 14", "0.32 0.95 0" );
make_ladder( "_ladder_starthilltopT_cloned_awningpipe", "2720 -1734 231.5", "-6645 626 755", "4 -17.7 14", "0.32 0.95 0" );
make_ladder( "_ladder_theatreleft_cloned_theatreright", "1142 -4311.5 20", "474 -4 0" );
make_ladder( "_ladder_yesdrawhellbackL_cloned_copbarrfront", "44.5933 -994.7905 -4.1108", "-5164 328 -3" );
make_ladder( "_ladder_yesdrawhellbackR_cloned_copbarrfront", "44.5933 -994.7905 -4.1108", "-5164 -351 -3" );
make_ladder( "_ladder_yesdrawhellfrontL_cloned_copbarrback", "52.8641 -994.878 -4.1108", "-5110 -351 -3" );
make_ladder( "_ladder_yesdrawhellfrontR_cloned_copbarrback", "52.8641 -994.878 -4.1108", "-5110 328 -3" );
//make_ladder( "_ladder_yeswayendfront_cloned_yeswayendback", "3380.5 -3825 59.5", "6102 -8207 0", "0 171 0", "-0.99 0.16 0" );
make_navblock( "_losblocker_deliverynavblock", "Everyone", "Apply", "-32 -64 -32", "32 64 32", "562 -2425 -48" );
make_prop( "dynamic",		"_losblocker_deliveryvan",	"models/props_vehicles/deliveryvan.mdl",		"600 -2429 -47",		"-1 70 -3" );
make_prop( "dynamic",		"_losblocker_deliveryvanglass",	"models/props_vehicles/deliveryvan_glass.mdl",	"600 -2429 -47",		"-1 70 -3",		"shadow_no" );
make_prop( "dynamic",		"_losblocker_sheetrock",	"models/props_interiors/sheetrock_leaning.mdl",		"-368 -2142 -48",		"0 0 0",		"shadow_no" );
make_prop( "dynamic", "_fineantique_surf1", "models/props_update/c8m1_rooftop_3.mdl", "2064 -4608 320.3", "0 0 0", "shadow_no" );
make_prop( "dynamic", "_fineantique_surf2", "models/props_update/c8m1_rooftop_3.mdl", "1872 -4608 320.2", "0 0 0", "shadow_no" );
make_prop( "dynamic", "_hellcade_m3mirr01", "models/props_c17/concrete_barrier001a.mdl", "-5136 -1224.06 -77.94", "0 0 0", "shadow_no" );
make_prop( "dynamic", "_hellcade_m3mirr02", "models/props_c17/concrete_barrier001a.mdl", "-5136 -744.06 -74", "0 0 7.5", "shadow_no" );
make_prop( "dynamic", "_hellcade_m3mirr03", "models/props_foliage/cedar01.mdl", "-5247.66 -1365 -91.57", "0 245.5 0", "shadow_no", "solid_no" );
make_prop( "dynamic", "_hellcade_m3mirr04", "models/props_foliage/cedar01.mdl", "-5485.07 -1318.82 -96", "-1.17 226.96 3.83", "shadow_no", "solid_no" );
make_prop( "dynamic", "_hellcade_m3mirr05", "models/props_street/concertinawire128.mdl", "-5112 -901.06 -35.94", "-1 0 0", "shadow_no", "solid_no" );
make_prop( "dynamic", "_hellcade_m3mirr06", "models/props_street/concertinawire128.mdl", "-5114 -1026.06 -35.94", "-1 0 0", "shadow_no", "solid_no" );
make_prop( "dynamic", "_hellcade_m3mirr07", "models/props_street/concertinawire128.mdl", "-5115 -1157.66 7.55", "1 0 180", "shadow_no", "solid_no" );
make_prop( "dynamic", "_hellcade_m3mirr08", "models/props_street/concertinawire128.mdl", "-5116 -1158.06 -35.94", "-1 0 0", "shadow_no", "solid_no" );
make_prop( "dynamic", "_hellcade_m3mirr09", "models/props_street/concertinawire128.mdl", "-5117 -1032.66 7.55", "1 0 180", "shadow_no", "solid_no" );
make_prop( "dynamic", "_hellcade_m3mirr10", "models/props_street/concertinawire128.mdl", "-5119 -900.66 7.55", "1 0 180", "shadow_no", "solid_no" );
make_prop( "dynamic", "_hellcade_m3mirr11", "models/props_street/stopsign01.mdl", "-5108 -1080.06 -73", "-5.8 179.41 6.27", "shadow_no" );
make_prop( "dynamic", "_hellcade_m3mirr12", "models/props_street/stopsign01.mdl", "-5267.23 -719.82 -69.49", "-13.32 194.27 -1.49", "shadow_no" );
make_prop( "dynamic", "_hellcade_m3mirr13", "models/props_street/stopsign01.mdl", "-5280.22 -667.42 -68.13", "-13.32 194.27 -1.49", "shadow_no" );
make_prop( "dynamic", "_hellcade_wrongwaya", "models/props_misc/wrongway_sign01_optimized.mdl", "-5605 -1257 0", "0 0 0", "shadow_no", "solid_no", "255 255 255", 217, 17 );
make_prop( "dynamic", "_hellcade_wrongwayb", "models/props_misc/wrongway_sign01_optimized.mdl", "-5605 -1001 0", "0 0 0", "shadow_no", "solid_no", "255 255 255", 217, 17 );
make_prop( "dynamic", "_hellcade_wrongwayc", "models/props_misc/wrongway_sign01_optimized.mdl", "-5605 -745 0", "0 0 0", "shadow_no", "solid_no", "255 255 255", 217, 17 );
make_prop( "dynamic", "_ladder_churchleftm3mirr_pipe", "models/props_rooftop/Gutter_Pipe_256.mdl", "-3276 -7 321", "0 -90 0", "shadow_no" );
make_prop( "dynamic", "_solidify_stainedawning", "models/props_street/awning_department_store.mdl", "2036 -2528 385", "0 0 0", "shadow_no" );
make_prop( "dynamic", "_stainedroof_wrongway1", "models/props_misc/wrongway_sign01_optimized.mdl", "1728 -2920 541", "0 90 0", "shadow_no", "solid_no", "255 255 255", 500, 17 );
make_prop( "dynamic", "_stainedroof_wrongway2", "models/props_misc/wrongway_sign01_optimized.mdl", "2028 -2920 541", "0 90 0", "shadow_no", "solid_no", "255 255 255", 500, 17 );
make_prop( "dynamic", "_stainedroof_wrongway3", "models/props_misc/wrongway_sign01_optimized.mdl", "2328 -2920 541", "0 90 0", "shadow_no", "solid_no", "255 255 255", 500, 17 );
make_prop( "dynamic", "_yesdrawhellcade_surface", "models/props_update/c10m4_hellcade_nodraw.mdl", "-5093.8 -1038 0", "0 270 0", "shadow_no" );
patch_ladder( "1698.6658 -3959.1636 -13.5", "0 -3 0" );
patch_ladder( "1712.9192 -3843.1353 -12.5", "0 3 0" );

// Car needs parenting, Survivors hardly see it and it has random color on previous map.

make_prop( "physics", "_hittable_hellcar", "models/props_vehicles/cara_95sedan.mdl", "-5351 -993.06 -63.59", "0 354.5 0" );
make_prop( "dynamic", "_hittable_hellcarglass", "models/props_vehicles/cara_95sedan_glass.mdl", "-5351 -993.06 -63.59", "0 354.5 0", "shadow_no" );

EntFire( g_UpdateName + "_hittable_hellcarglass", "SetParent", g_UpdateName + "_hittable_hellcar" );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c10m5_houseboat":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

make_brush( "_losfix_van",		"-1 -70 -8",	"1 70 8",	"3736 753 -181" );
make_clip( "_ladder_middlehouse_clip", "Everyone", 1, "-10 -7 0", "10 -4 160", "3488 -3063 -84", "0 -34 0" );
make_clip( "_rock_infected_clipqol", "SI Players", 1, "-140 -135 -105", "140 135 105", "3340 -5010 -324" );
make_clip( "_rock_survivor_clipright", "Survivors", 1, "-195 -240 -216", "50 183 1700", "3255 -4984 -253" );
make_clip( "_rock_survivor_clipleft", "Survivors", 1, "0 -240 -216", "200 105 1700", "3255 -4984 -253" );
make_clip( "_rock_survivor_clipwedge", "Survivors", 1, "-255 -120 -216", "100 150 1700", "3255 -4984 -253" );
make_clip( "_solidify_permstuck1", "SI Players", 1, "-17 -17 -17", "17 17 17", "2100 253 -112" );
make_clip( "_solidify_permstuck2", "SI Players", 1, "-17 -17 -17", "17 17 17", "3141 387 -168" );
make_clip( "_solidify_permstuck3", "SI Players", 1, "-17 -17 -17", "17 17 17", "5463 220 222" );
make_clip( "_solidify_permstuck4", "SI Players", 1, "-17 -17 -17", "17 17 17", "6736 -2753 207" );
make_clip( "_solidify_permstuck5", "SI Players", 1, "-17 -17 -17", "17 17 17", "2914 -1462 213" );
make_clip( "_solidify_railposta", "Everyone", 1, "-6 -2 0", "6 2 33.8", "3924 -4516 -24" );
make_clip( "_solidify_railpostb", "Everyone", 1, "-6 -2 0", "6 2 33.8", "4020 -4516 -24" );
make_clip( "_solidify_railpostc", "Everyone", 1, "-2 -6 0", "2 6 33.8", "4116 -4228 -24" );
make_clip( "_solidify_railpostd", "Everyone", 1, "-2 -6 0", "2 6 33.8", "4116 -4132 -24" );
make_clip( "_solidify_railposte", "Everyone", 1, "-2 -6 0", "2 6 33.8", "4116 -4036 -24" );
make_clip( "_solidify_railpostf", "Everyone", 1, "-6 -2 0", "6 2 33.8", "4020 -3940 -24" );
make_ladder( "_ladder_firebarrelarea_cloned_eventperimloner", "6406.5 -2736 -31", "1374 -7828 1500", "13 90 0", "0 -1 0" );
make_ladder( "_ladder_middlehouse_cloned_docksinwater", "3518 -4704.5 -205.5", "-16 1630 201" );
make_ladder( "_ladder_tankfightcorner_cloned_eventperimloner", "6406.5 -2736 -31", "-1460 -7078 1500", "13 77 0", "-0.24 -0.97 0" );
make_navblock( "_rock_navblock_outabounds", "Everyone", "Apply", "-32 -32 -216", "700 0 216", "2951 -5211 -295" );
make_navblock( "_rock_navblock_underneath", "Everyone", "Apply", "-128 -128 -216", "0 0 216", "3198 -4848 -295" );
make_prop( "dynamic", "_losblocker_tallladder", "models/props/cs_militia/militiarock01.mdl", "5639 -419 292", "-35.6616 352.555 -19.0887", "shadow_no" );
make_prop( "dynamic", "_propladder_back", "models/props/cs_militia/militiarock02.mdl", "5205 -2 -118", "-3.36983 12.0544 17.6989", "shadow_no" );
make_prop( "dynamic", "_propladder_front", "models/props/cs_militia/militiarock03.mdl", "4521 370 -250", "29.7193 155.282 23.7211", "shadow_no" );
make_prop( "dynamic", "_rock_nav", "models/props_foliage/rock_coast02f.mdl", "3050 -5000 -438", "90 190 0", "191 191 191" );
make_prop( "dynamic", "_rock_rene", "models/props_foliage/rock_coast02f.mdl", "3250 -4977 -242", "-5 177 3", "191 191 191" );
make_prop( "dynamic", "_solidify_tree01", "models/props_foliage/trees_cluster02.mdl", "6115.44 -1254.23 254.159", "0.0 144.5 0.0", "shadow_no" );
make_prop( "dynamic", "_solidify_tree02", "models/props_foliage/trees_cluster01.mdl", "5840.49 -1231.82 262.096", "0.0 185.5 0.0", "shadow_no" );
make_prop( "dynamic", "_solidify_tree03", "models/props_foliage/trees_cluster02.mdl", "5674.99 -173.235 286.403", "5.75837 274.813 12.6214", "shadow_no" );
make_prop( "dynamic", "_solidify_tree04", "models/props_foliage/trees_cluster01.mdl", "5482.81 241.228 132.695", "-12.1912 25.172 7.18842", "shadow_no" );
make_prop( "dynamic", "_solidify_tree05", "models/props_foliage/trees_cluster02.mdl", "5140.97 482.588 161.3", "-5.34185 52.754 5.27212", "shadow_no" );
make_prop( "dynamic", "_solidify_tree06", "models/props_foliage/trees_cluster01.mdl", "4947.63 841.389 177.102", "-15.3542 25.5395 5.64541", "shadow_no" );
make_prop( "dynamic", "_solidify_tree07", "models/props_foliage/trees_cluster02.mdl", "4596 -847.291 46.5099", "-10.7147 193.235 -2.50372", "shadow_no" );
make_prop( "dynamic", "_solidify_tree08", "models/props_foliage/trees_cluster01.mdl", "4472.11 -1332.35 92.7903", "3.1137 10.7052 10.6639", "shadow_no" );
make_prop( "dynamic", "_solidify_tree09", "models/props_foliage/trees_cluster02.mdl", "3330.26 -1363.53 109.319", "0.0 173.5 0.0", "shadow_no" );
make_prop( "dynamic", "_solidify_tree10", "models/props_foliage/trees_cluster01.mdl", "2913.72 -1441.18 125.267", "-6.93085 51.3826 10.6265", "shadow_no" );
make_prop( "dynamic", "_solidify_tree11", "models/props_foliage/trees_cluster02.mdl", "2806.21 -1397.96 136.034", "-5.62152 106.407 -2.15325", "shadow_no" );
make_prop( "dynamic", "_solidify_tree12", "models/props_foliage/trees_cluster02.mdl", "6591.85 -1674.72 249.755", "5.97716 272.278 -1.19737", "shadow_no" );
make_prop( "dynamic", "_solidify_tree13", "models/props_foliage/trees_cluster01.mdl", "6860.31 -1957.59 260.658", "4.82922 217.555 1.29717", "shadow_no" );
make_prop( "dynamic", "_solidify_tree14", "models/props_foliage/trees_cluster02.mdl", "6936.06 -2695.45 140.336", "-9.40842 32.8524 -16.7709", "shadow_no" );
make_prop( "dynamic", "_solidify_tree15", "models/props_foliage/trees_cluster01.mdl", "6743.79 -2761.88 140.372", "-7.2427 336.942 -0.575684", "shadow_no" );
make_prop( "dynamic", "_solidify_tree16", "models/props_foliage/old_tree01.mdl", "6754.94 -3134.69 175.772", "3.99839 219.252 11.5523", "shadow_no" );
make_prop( "dynamic", "_solidify_tree17", "models/props_foliage/trees_cluster02.mdl", "6691.45 -3321.24 167.145", "-5.27616 263.338 11.0332", "shadow_no" );
make_prop( "dynamic", "_solidify_tree18", "models/props_foliage/old_tree01.mdl", "3392 -87.0611 -192", "0.295558 271.978 -8.4949", "shadow_no" );
make_prop( "dynamic", "_solidify_tree19", "models/props_foliage/trees_cluster02.mdl", "3343.3 304.445 -195.784", "-2.83356 324.754 -6.57611", "shadow_no" );
make_prop( "dynamic", "_solidify_tree20", "models/props_foliage/trees_cluster01.mdl", "3135.65 343.649 -172.46", "4.82922 270.055 1.29717", "shadow_no" );
make_prop( "dynamic", "_solidify_tree21", "models/props_foliage/trees_cluster02.mdl", "3004 -49.16 -159.143", "0.0 193.0 0.0", "shadow_no" );
make_prop( "dynamic", "_solidify_tree22", "models/props_foliage/old_tree01.mdl", "2800 176.84 -175", "0.0 152.0 0.0", "shadow_no" );
make_prop( "dynamic", "_solidify_tree23", "models/props_foliage/trees_cluster02.mdl", "2600 166.84 -176", "0.0 197.0 0.0", "shadow_no" );
make_prop( "dynamic", "_solidify_tree24", "models/props_foliage/trees_cluster02.mdl", "2472.84 354 -191", "0.0 342.0 0.0", "shadow_no" );
make_prop( "dynamic", "_solidify_tree25", "models/props_foliage/trees_cluster01.mdl", "2103.88 254.77 -193.143", "0.0 43.0 0.0", "shadow_no" );
make_prop( "dynamic", "_solidify_tree26", "models/props_foliage/trees_cluster02.mdl", "2236.99 768.711 -202.778", "-6.18811 116.848 12.0217", "shadow_no" );
make_prop( "dynamic", "_solidify_tree27", "models/props_foliage/old_tree01.mdl", "2157.68 1276.4 -199.196", "-2.87053 121.382 4.69345", "shadow_no" );
make_prop( "dynamic", "_solidify_tree28", "models/props_foliage/trees_cluster02.mdl", "5416.34 565.308 209.588", "0.0 268.0 0.0", "shadow_no" );
make_prop( "physics",		"_hittable_log",		"models/props_foliage/tree_trunk_fallen.mdl",		"5405 -2480 -103",		"0 0 2", "shadow_no" );
make_prop( "physics_ovr", "_hittable_rock", "models/props/cs_militia/militiarock01.mdl", "1721 -1971 -4", "10.6 49.1 10.9", "shadow_no" );
patch_nav_obscured( "5298 328 153" );
patch_nav_obscured( "5020 664 190" );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*==============================
||                            ||
||          DEAD AIR          ||
||                            ||
==============================*/

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c11m1_greenhouse":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

kill_funcinfclip( 625.928 );	// Delete clip shielding access away from greenhouse roof
kill_funcinfclip( 985.253 );	// Delete clip shielding in dropping through roof holes
kill_funcinfclip( 730.438 );	// Delete clip above Holly Street station building
kill_funcinfclip( 608.147 );	// Delete clip above roof near Crane, Hunter-only so don't add ladder, fix added exploit
kill_funcinfclip( 677.928 );	// Delete clip to right of end area, also Hunter-only so no ladder, fix added exploit
kill_funcinfclip( 827.238 );	// Delete clip above office entrance roof for a new attack spot (Tank buff)
kill_funcinfclip( 726.55 );	// Delete clip on tall rooftop across from greenhouse
kill_funcinfclip( 138.95 );	// Delete clip (that's oddly tapered) at end of electrical pole
kill_funcinfclip( 900.059 );	// Delete clip covering the entirety of adjacent long-jump rooftop
kill_funcinfclip( 883.739 );	// Delete clip along greenhouse roof's far right wedge
make_brush( "_losfix_semi1",		"-40 -1 -27",	"40 1 27",	"3456 2233 43" );
make_brush( "_losfix_semi2",		"-1 -50 -15",	"1 50 15",	"3999 2268 23" );
make_brush( "_losfix_semi3",		"-20 -1 -15",	"21 1 15",	"3977 2264 23" );
make_brush( "_losfix_van",		"-70 -1 -8",	"70 1 8",	"3729 2932 15" );
make_clip( "_bustedwatertower_clip", "SI Players", 1, "-440 -187 -448", "440 149 264", "3872 -909 1464" );
make_clip( "_greenhouse_gutterleft", "SI Players and AI", 1, "-479 -1 0", "581 0 17", "5707 -993 984" );
make_clip( "_greenhouse_gutterright", "SI Players and AI", 1, "-479 -1 0", "1301 0 17", "5707 -271 984" );
make_clip( "_greenhouse_randomgapa", "SI Players", 1, "-112 -2 -1", "20 2 1", "4874 -752 923" );
make_clip( "_greenhouse_randomgapb", "SI Players", 1, "-64 -2 -1", "0 2 1", "5823 -633 1088" );
make_clip( "_greenhouse_saferoof_survivor", "Survivors", 1, "-242 -350 0", "480 349 800", "6530 -541 1004" );
make_clip( "_greenhouse_saferoof_infected", "SI Players", 1, "-242 -350 0", "480 349 800", "6530 -541 1004" );
make_clip( "_greenhouse_saferoof_infecgap", "SI Players", 1, "-8 -16 0", "8 16 32", "6296 -208 943" );
make_clip( "_meticulous_funcinfclip01", "SI Players and AI", 1, "-530 -3 0", "530 3 888", "5758 -1069 848" );
make_clip( "_meticulous_funcinfclip02", "SI Players and AI", 1, "-368 -3 0", "350 3 888", "6658 -893 916" );
make_clip( "_meticulous_funcinfclip03", "SI Players and AI", 1, "-130 -3 0", "350 3 888", "6658 -199 916" );
make_clip( "_meticulous_funcinfclip04", "SI Players and AI", 1, "-3 -381 0", "3 307 888", "7011 -509 908" );
make_clip( "_meticulous_funcinfclip05", "SI Players and AI", 1, "-3 -94 0", "3 88 888", "6291 -978 848" );
make_clip( "_yesdraw_longjump_clip", "SI Players", 1, "-682 -500 -436", "322 380 436", "3010 3568 1292" );
make_clip( "_yesdraw_longjump_stuck", "SI Players", 1, "-24 -240 0", "8 208 128", "2584 2864 728" );
make_ladder( "_ladder_endcarpetwin_cloned_onewayupper", "2872 1156.5 559", "2237 5217 -535", "0 -90 0", "1 0 0" );
make_ladder( "_ladder_endupperwalkway_cloned_longnosegrille", "4060.65 2328.76 49.8259", "9369 1162 182", "0 135 0", "-1 0 0" );
make_ladder( "_ladder_greenhousebox_cloned_firstbuildfront", "4360.5 384 692.5", "4678 3728 2", "0 -90 0", "0 -1 0" );
make_ladder( "_ladder_greenhouseroof_cloned_betweenacunits", "3322.5 726 732.5", "1907 -1313 229" );
make_ladder( "_ladder_startplankdoor_cloned_endchainlink", "2632 2367 92.5", "7133 -2174 503", "0 90 0", "-1 0 0" );
make_prop( "dynamic", "_bustedwatertower_wrongwaya", "models/props_misc/wrongway_sign01_optimized.mdl", "4069 -758 1264", "0 90 0", "shadow_no", "solid_no", "255 255 255", 217, 17 );
make_prop( "dynamic", "_bustedwatertower_wrongwayb", "models/props_misc/wrongway_sign01_optimized.mdl", "3664 -758 1264", "0 90 0", "shadow_no", "solid_no", "255 255 255", 217, 17 );
make_prop( "dynamic", "_yesdraw_longjump_roofa", "models/props_update/c8m1_rooftop_1.mdl", "3088 3312 856", "0 90 0", "shadow_no", "solid_no" );
make_prop( "dynamic", "_yesdraw_longjump_roofb", "models/props_update/c8m1_rooftop_1.mdl", "2832 3312 855.9", "0 90 0", "shadow_no", "solid_no" );
make_prop( "dynamic", "_yesdraw_longjump_wrongwaya", "models/props_misc/wrongway_sign01_optimized.mdl", "3090 3065 918", "0 -90 0", "shadow_no", "solid_no", "255 255 255", 500, 17 );
make_prop( "dynamic", "_yesdraw_longjump_wrongwayb", "models/props_misc/wrongway_sign01_optimized.mdl", "2805 3065 918", "0 -90 0", "shadow_no", "solid_no", "255 255 255", 500, 17 );
make_prop( "dynamic", "_yesdrawgreenhouse_panels", "models/props_update/c11m1_greenhouse_nodraw.mdl", "6118.9 -632 943", "0 270 0", "shadow_no" );
make_prop( "dynamic", "_yesdrawgreenhouse_plywood", "models/props_update/c11m1_greenhouse_plywood.mdl", "5524 -717 968", "0 270 0", "shadow_no" );
make_prop( "dynamic", "_yesdrawgreenhouse_wrongwaya", "models/props_misc/wrongway_sign01_optimized.mdl", "6305 -633 1148", "0 180 0", "shadow_no", "solid_no", "255 255 255", 500, 17 );
make_prop( "dynamic", "_yesdrawgreenhouse_wrongwayb", "models/props_misc/wrongway_sign01_optimized.mdl", "6305 -395 1148", "0 180 0", "shadow_no", "solid_no", "255 255 255", 500, 17 );
local strEndUpperWalkway = clone_model( Entities.FindByClassnameNearest( "func_illusionary", Vector( 4063, 2331, 49.83 ), 1 ) );

if ( strEndUpperWalkway != null )
{
	SpawnEntityFromTable( "func_illusionary",
	{
		targetname	= g_UpdateName + "_endupperwalkway_illus",
		model		= strEndUpperWalkway,
		origin		= Vector( 4853, 2387, 232 ),
		angles		= Vector( 0, 135, 0 )
	} );
}

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c11m2_offices":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

kill_funcinfclip( 677.928 );	// Delete clip above roof on far-right corner of end area
kill_funcinfclip( 827.238 );
make_brush( "_losfix_copcar",		"-1 -70 -8",	"1 70 8",	"9613 4999 16" );
make_brush( "_losfix_crane1",		"-21 -102 -41",	"21 102 41",	"5692 3913 784" );
make_brush( "_losfix_crane2",		"-110 -87 -2",	"110 87 2",	"5823 3913 746" );
make_brush( "_losfix_crane3",		"-34 -87 -2",	"34 87 2",	"6032 3914 746" );
make_brush( "_losfix_crane4",		"-100 -2 -13",	"100 2 13",	"5886 3828 756" );
make_brush( "_losfix_crane5",		"-1 -20 -20",	"1 20 20",	"5810 3914 1213" );
make_brush( "_losfix_crane6",		"-12 -20 -1",	"12 20 1",	"5820 3914 1194" );
make_brush( "_losfix_semi",		"-52 -1 -18",	"52 1 18",	"7412 5366 27" );
make_brush( "_losfix_van",		"-1 -80 -8",	"1 80 8",	"8754 5174.01 16" );
make_clip( "_meticulous_funcinfclip01", "SI Players", 1, "-309 -64 0", "331 64 862", "6197 4672 1056" );
make_clip( "_meticulous_funcinfclip02", "SI Players", 1, "-8 -470 0", "8 470 668", "9668 6033 536", "0 8 0" );
make_clip( "_meticulous_funcinfclip03", "SI Players", 1, "-360 -360 0", "568 360 352", "8904 3512 1056" );
make_ladder( "_ladder_endchaingate_cloned_endtallstraight", "7156 4653 92", "16110 10158 0", "0 -180 0", "0 -1 0" );
make_ladder( "_ladder_endcornerleft_cloned_farendmiddle", "6641.3789 5199.9937 68", "2837 117 0" );
make_ladder( "_ladder_endcornerright_cloned_farendmiddle", "6641.3789 5199.9937 68", "2837 -222 0" );
make_ladder( "_ladder_endcornertop_cloned_undercranedump", "6580 3987.5 342", "3020 1568 -132" );
make_ladder( "_ladder_officefoyerB_cloned_firebarrelfence", "5199 3376 92", "3109.9 332 548.35" );
make_ladder( "_ladder_officefoyerT_cloned_undercranepipe", "6158 3857.01 268", "12159 -2450 1009", "0 90 -7", "-1 0 0" );
make_ladder( "_ladder_poleconnection_cloned_semiexploit", "6780 3067 268", "85 549 513" );
make_prop( "dynamic", "_officefoyer_wrongwaya", "models/props_misc/wrongway_sign01_optimized.mdl", "8544 3284 1122", "0 180 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_officefoyer_wrongwayb", "models/props_misc/wrongway_sign01_optimized.mdl", "8544 3761 1122", "0 180 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_solidify_officefoyer_pole", "models/props_trainstation/pole_384connection001a.mdl", "8511.9 3565.75 1248.34", "0 90 0", "shadow_no" );
patch_ladder( "8596 5497.5 92.3941", "0 4 0" );
patch_ladder( "8260 5497.5 92.3941", "0 4 0" );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c11m3_garage":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

kill_funcinfclip( 1067.45 );	// Delete thin clip blocking access to the new enclosed construction area, fix exploits
kill_funcinfclip( 1841.92 );	// Delete clip above/around about 5 distinct rooftops above starting area
kill_funcinfclip( 1000.96 );	// Delete clip on rooftop besides new enclosed construction site space
kill_funcinfclip( 1110.34 );	// Delete clip on rooftop with watertower near large pothole
kill_funcinfclip( 874.48 );	// Delete clip above rooftop near beginning (same as one deleted for end of map 2)
kill_funcinfclip( 2083.18 );	// Delete 3-solid clip over 2 long fences and a rooftop ledge
make_atomizer( "_atomizer_bsp_forkliftdoor", "-3451 2517 32", "models/props\\cs_assault\\forklift_brokenlift.mdl", 60 );
make_atomizer( "_atomizer_bsp_forkliftgate", "-3573 2854 32", "models/props\\cs_assault\\forklift_brokenlift.mdl", 60 );
make_brush( "_losfix_copcar",		"-1 -80 -8",	"1 80 8",	"-3430 875 15" );
make_brush( "_losfix_end_van",		"-1 -70 -8",	"1 70 8",	"-3221 4198 23" );
make_brush( "_losfix_van",			"-1 -60 -8",	"1 60 8",	"-4577 664 16" );
make_brush( "_losfix_watertank1",	"-132 -1 -6",	"132 1 6",	"-4854 3494 22" );
make_brush( "_losfix_watertank2",	"-132 -1 -6",	"132 1 6",	"-3733 2330 38" );
make_brush( "_losfix_watertank3",	"-132 -1 -6",	"132 1 6",	"-3947 2566 38" );
make_brush( "_losfix_watertank4",	"-22 -32 -12",	"22 32 12",	"-3994 2929 25" );
make_clip( "_constructsite_fireescape_booster", "Survivors", 1, "-45 -88 -133", "42 82 1062", "-5434 -1145 792" );
make_clip( "_constructsite_scaffold_clip", "SI Players", 1, "-48 -167 0", "49 161 108", "-7551 -1707 180" );
make_clip( "_constructsite_wwblocker", "SI Players", 1, "-397 -19 0", "403 355 1132", "-7203 -723 736" );
make_clip( "_ladder_constructionfireescapea_qolclip", "SI Players", 1, "0 -102 0", "8 81 24", "-5478 -1153 727", "0 0 -56" );
make_clip( "_ladder_fireescapehelper_qolclip", "SI Players", 1, "-64 -0.1 0", "64 0 88", "-5456 -1312 512" );
make_clip( "_ladderqol_lessworthlessthanbefore", "SI Players", 1, "-470 -1 -12", "421 0 32", "-2901 2420 168" );
make_clip( "_meticulous_funcinfclip01", "SI Players", 1, "-391 -838 0", "281 122 1842", "-7753 -2058 16" );
make_clip( "_meticulous_funcinfclip02", "SI Players", 1, "-273 0 0", "221 298 1538", "-7711 -1040 308" );
make_clip( "_meticulous_funcinfclip03", "SI Players", 1, "-168 -448 -128", "8 464 1666", "-7976 -1504 180" );
make_clip( "_meticulous_funcinfclip04", "SI Players", 1, "-901 -316 -48", "479 932 1272", "-6583 -3412 584" );
make_clip( "_meticulous_funcinfclip05", "SI Players", 1, "-454 -409 0", "426 407 882", "-5602 -2703 976" );
make_clip( "_meticulous_funcinfclip06", "SI Players", 1, "-519 -120 0", "465 30 1482", "-6217 1232 380" );
make_clip( "_meticulous_funcinfclip07", "SI Players", 1, "-120 -690 0", "0 0 1848", "-5655 1952 8" );
make_clip( "_meticulous_funcinfclip08", "SI Players", 1, "-64 -457 0", "64 503 1312", "-3664 -3207 548" );
make_clip( "_meticulous_funcinfclip09", "SI Players", 1, "-306 -37 0", "334 28 1312", "-3934 -3627 548" );
make_clip( "_yeswayfence1st_clip", "Everyone", 1, "-33 -1163 0", "1 1163 152", "-5135 3067 16" );
make_clip( "_yeswayfence2nd_clip", "Everyone", 1, "-719 -1 0", "719 33 152", "-4447 4199 16" );
make_clip( "_yeswayfence_funcinfclip1", "SI Players", 1, "-135 -1321 0", "8 1321 1848", "-5521 3273 8" );
make_clip( "_yeswayfence_funcinfclip2", "SI Players", 1, "-888 -8 0", "888 8 1848", "-4632 4593 8" );
make_clip( "_yeswayfence_funcinfclip3", "SI Players", 1, "-8 -477 0", "8 477 1848", "-3736 4867 8" );
make_ladder( "_ladder_airportleft_cloned_airportright", "-1539.5 1472 192.315", "-1 3072 0" );
make_ladder( "_ladder_airportmidB_cloned_airportright", "-1539.5 1472 192.315", "-1 1536 0" );
make_ladder( "_ladder_airportmidT_cloned_onewayfence", "-6028 -2232 92", "4485 5240 312" );
make_ladder( "_ladder_constructnewarea_cloned_alleyelecbox", "-4745.5 -1033.5 136", "-6443 -6469 52", "0 -90 0", "1 0 0" );
make_ladder( "_ladder_constructnewpipe_cloned_prevunused", "-7489 -1512 244", "-6802 6348 -17", "0 73 0", "-0.3 -0.95 0" );
make_ladder( "_ladder_constructpillarB_cloned_alleyfirstpipe", "-5175.5 -897 280", "-6491 -7244 -80", "0 -90 0", "0 -1 0" );
make_ladder( "_ladder_constructpillarT_cloned_whitepillar", "-6830 -2072.5 154", "-14217 -4215 248", "0 180 0", "0 1 0" );
make_ladder( "_ladder_constructionfireescapea_cloned_tricountytop", "-4716 1483 386", "-6958 -5925 346", "0 -90 0", "-1 0 0" );
make_ladder( "_ladder_constructionfireescapeb_cloned_skybridgetiny", "-1168 3254.5 416", "-4265 -4488.1 248" );
make_ladder( "_ladder_fireescapehelpera_cloned_skybridgetiny", "-1168 3254.5 416", "-4268 -4565.1 120" );
make_ladder( "_ladder_fireescapehelperb_cloned_skybridgetiny", "-1168 3254.5 416", "-4268 -4565.1 152" );
make_ladder( "_ladder_tallibeamright_cloned_tallibeamleft", "-5872 -1328.5 264", "-11744 -3488 0", "0 180 0", "0 1 0" );
make_ladder( "_ladder_yellowgirder_cloned_skybridgemini", "-1168 3254.5 416", "-1748 -1038 -76" );
make_ladder( "_ladder_yesdrawtripleL_cloned_skybridgetiny", "-1168 3449.5 416", "490 2688 -272", "0 90 0", "-1 0 0" );
make_ladder( "_ladder_yesdrawtripleR_cloned_firewindow", "-3092.5 3104 96.5", "136 -1839 -1" );
make_ladder( "_ladder_yeswayfenceback1_cloned_1stfenceback", "-5167 2160 92.5", "0 387 0" );
make_ladder( "_ladder_yeswayfenceback2_cloned_1stfenceback", "-5167 2160 92.5", "0 774 0" );
make_ladder( "_ladder_yeswayfenceback3_cloned_1stfenceback", "-5167 2160 92.5", "0 1935 0" );
make_ladder( "_ladder_yeswayfenceback4_cloned_2ndfenceback", "-4090 4231 92.5", "-900 0 0" );
make_ladder( "_ladder_yeswayfenceback5_cloned_2ndfenceback", "-4090 4231 92.5", "-600 0 0" );
make_ladder( "_ladder_yeswayfenceback6_cloned_2ndfenceback", "-4090 4231 92.5", "-300 0 0" );
make_ladder( "_ladder_yeswayfencefront1_cloned_1stfenceback", "-5167 2160 92.5", "-10302 4550 0", "0 180 0", "1 0 0" );
make_ladder( "_ladder_yeswayfencefront2_cloned_1stfenceback", "-5167 2160 92.5", "-10302 5000 0", "0 180 0", "1 0 0" );
make_ladder( "_ladder_yeswayfencefront3_cloned_1stfenceback", "-5167 2160 92.5", "-10302 5450 0", "0 180 0", "1 0 0" );
make_ladder( "_ladder_yeswayfencefront4_cloned_1stfenceback", "-5167 2160 92.5", "-10302 5900 0", "0 180 0", "1 0 0" );
make_ladder( "_ladder_yeswayfencefront5_cloned_2ndfenceback", "-4090 4231 92.5", "-8932 8430 0", "0 -180 0", "0 -1 0" );
make_ladder( "_ladder_yeswayfencefront6_cloned_2ndfenceback", "-4090 4231 92.5", "-8632 8430 0", "0 -180 0", "0 -1 0" );
make_ladder( "_ladder_yeswayfencefront7_cloned_2ndfenceback", "-4090 4231 92.5", "-8332 8430 0", "0 -180 0", "0 -1 0" );
make_ladder( "_ladder_yeswayfencefront8_cloned_2ndfenceback", "-4090 4231 92.5", "-8032 8430 0", "0 -180 0", "0 -1 0" );
make_prop( "dynamic", "_constructsite_fireescapetop", "models/props_urban/fire_escape_upper.mdl", "-5392 -1067 792", "0 -90 0", "shadow_no" );
make_prop( "dynamic", "_constructsite_fireescapebot", "models/props_urban/fire_escape_lower.mdl", "-5392 -1067 664", "0 -90 0", "shadow_no" );
make_prop( "dynamic", "_constructsite_propladdera", "models/props_pipes/concrete_pipe001a.mdl", "-7629 -1214 222", "0 60 0", "shadow_no" );
make_prop( "dynamic", "_constructsite_propladderb", "models/props_pipes/concrete_pipe001a.mdl", "-7531 -1212 236", "90 90 0", "shadow_no" );
make_prop( "dynamic", "_constructsite_propladderc", "models/props_urban/metal_plate001.mdl", "-7573 -1199 291", "-24.2 10 0", "shadow_no" );
make_prop( "dynamic", "_constructsite_scaffold", "models/props_equipment/scaffolding.mdl", "-7551 -1710 80", "0 0 0", "shadow_no" );
make_prop( "dynamic", "_constructsite_wrongwaya", "models/props_misc/wrongway_sign01_optimized.mdl", "-7967 -1760 232", "0 0 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_constructsite_wrongwayb", "models/props_misc/wrongway_sign01_optimized.mdl", "-7967 -1505 232", "0 0 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_constructsite_wrongwayc", "models/props_misc/wrongway_sign01_optimized.mdl", "-7967 -1250 232", "0 0 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_constructsite_wrongwayd", "models/props_misc/wrongway_sign01_optimized.mdl", "-7051 -745 789", "0 -90 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_constructsite_wrongwaye", "models/props_misc/wrongway_sign01_optimized.mdl", "-7325 -745 789", "0 -90 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_constructsite_wrongwayf", "models/props_misc/wrongway_sign01_optimized.mdl", "-7490 -2346 590", "0 0 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_constructsite_wrongwayg", "models/props_misc/wrongway_sign01_optimized.mdl", "-7340 -2475 590", "0 90 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_fadedistfix_airport_acunitleft", "models/props_rooftop/acvent01.mdl", "-1344.2 4559.64 384.299", "0 270 0", "shadow_no", "solid_no" );
make_prop( "dynamic", "_fadedistfix_airport_acunitright", "models/props_rooftop/acvent01.mdl", "-1344.2 4015.64 384.299", "0 270 0", "shadow_no", "solid_no" );
make_prop( "dynamic", "_yesdrawtriple_surface", "models/props_update/c11m3_nodraw_cinderwall.mdl", "-2948 1392 224", "0 0 0", "shadow_no" );
make_prop( "dynamic", "_yeswayfence_curb", "models/props_update/c11m3_wrongway_curb.mdl", "-4512 3264 0", "0 270 0", "shadow_no" );
make_prop( "dynamic", "_yeswayfence_van", "models/props_vehicles/van.mdl", "-5221 3669 16", "0 178 0" );
make_prop( "dynamic", "_yeswayfence_vanglass", "models/props_vehicles/van_glass.mdl", "-5221 3669 16", "0 178 0", "shadow_no" );
make_prop( "dynamic", "_yeswayfence_wall", "models/props_update/c11m3_wrongway_fence.mdl", "-4448 3072 96", "0 270 0", "shadow_no" );
make_prop( "dynamic", "_yeswayfence_wrongway1", "models/props_misc/wrongway_sign01_optimized.mdl", "-5521 2393 72", "0 0 0", "shadow_no", "solid_no", "255 255 255", 217, 17 );
make_prop( "dynamic", "_yeswayfence_wrongway2", "models/props_misc/wrongway_sign01_optimized.mdl", "-5521 2833 72", "0 0 0", "shadow_no", "solid_no", "255 255 255", 217, 17 );
make_prop( "dynamic", "_yeswayfence_wrongway3", "models/props_misc/wrongway_sign01_optimized.mdl", "-5521 3273 72", "0 0 0", "shadow_no", "solid_no", "255 255 255", 217, 17 );
make_prop( "dynamic", "_yeswayfence_wrongway4", "models/props_misc/wrongway_sign01_optimized.mdl", "-5521 3713 72", "0 0 0", "shadow_no", "solid_no", "255 255 255", 217, 17 );
make_prop( "dynamic", "_yeswayfence_wrongway5", "models/props_misc/wrongway_sign01_optimized.mdl", "-5521 4153 72", "0 0 0", "shadow_no", "solid_no", "255 255 255", 217, 17 );
make_prop( "dynamic", "_yeswayfence_wrongway6", "models/props_misc/wrongway_sign01_optimized.mdl", "-5072 4593 72", "0 270 0", "shadow_no", "solid_no", "255 255 255", 217, 17 );
make_prop( "dynamic", "_yeswayfence_wrongway7", "models/props_misc/wrongway_sign01_optimized.mdl", "-4632 4593 72", "0 270 0", "shadow_no", "solid_no", "255 255 255", 217, 17 );
make_prop( "dynamic", "_yeswayfence_wrongway8", "models/props_misc/wrongway_sign01_optimized.mdl", "-4192 4593 72", "0 270 0", "shadow_no", "solid_no", "255 255 255", 217, 17 );
make_prop( "physics",		"_losblocker_closetcrate",	"models/props_junk/wood_crate002a.mdl",	"-559 3577 335",		"20 0 90" );
patch_ladder( "-1539.5 1472 192.315", "-1 0 0" );
patch_ladder( "-3352 2426 110", "0 -1 0" );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c11m4_terminal":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

make_brush( "_losfix_chairs1",		"-50 -1 -10",	"50 1 10",	"2976 2257 162" );
make_brush( "_losfix_chairs2",		"-50 -1 -9",	"50 1 9",	"3022 3230 161" );
make_brush( "_losfix_chairs3",		"-50 -1 -10",	"50 1 10",	"2967 3931 162" );
make_brush( "_losfix_chairs_long1",	"-102 -1 -10",	"102 1 10",	"2969 3383 162" );
make_brush( "_losfix_chairs_long2",	"-102 -1 -10",	"102 1 10",	"2968 3760 162" );
make_brush( "_losfix_chairs_long3",	"-102 -1 -10",	"102 1 10",	"2970 4924 162" );
make_brush( "_losfix_chairs_long4",	"-102 -1 -10",	"102 1 10",	"2971 5097 162" );
make_brush( "_losfix_chairs_long5",	"-102 -1 -10",	"102 1 10",	"2970 5457 162" );
make_clip( "_collision_terminaltruss1", "SI Players", 1, "-273 -16 0", "272 16 32", "-202 4742 670" );
make_clip( "_collision_terminaltruss2", "SI Players", 1, "-189 -16 0", "245 16 32", "128 4230 582", "-17 0 0" );
make_clip( "_collision_terminaltruss3", "SI Players", 1, "-78 -16 0", "161 16 32", "-400 4230 630", "4 0 0" );
make_clip( "_ladder_baggageclaim_rampclip", "SI Players", 1, "0 -31 0", "128 128 64", "640 4417 305", "40 90 0" );
make_clip( "_ladderqol_vaneventarea_left", "SI Players", 1, "-9 -66 -56", "41 66 32", "306 5104 264", "0 45 0" );
make_clip( "_ladderqol_vaneventarea_right", "SI Players", 1, "-13 -69 -56", "41 69 32", "306 3811 264", "0 -45 0" );
make_clip( "_losblocker_finalrun_clip", "Survivors", 1, "-102 -62 0", "52 61 76", "3032 3925 320" );
make_ladder( "_ladder_baggageclaim_cloned_farluggageback", "560 2727 353.403", "70 1684 -16" );
make_ladder( "_ladder_exploitventB_cloned_basheddoors", "397 1534 74", "322.495 -606.022 -4" );
make_ladder( "_ladder_exploitventT_cloned_givebloodrubble", "-24 1798 60", "-1159 905 232", "0 -90 0", "1 0 0" );
make_ladder( "_ladder_farluggagefront_cloned_farluggageback", "560 2727 353.403", "1115 5575 0", "0 180 0", "0 1 0" );
make_ladder( "_ladder_midluggagefront_cloned_midluggageback", "560 1519 353.403", "1101 3158 0", "0 180 0", "0 1 0" );
make_ladder( "_ladder_midventfront_cloned_midventback", "482 2082 329", "961 4155 0", "0 -180 0", "0 -1 0" );
make_navblock( "_losblocker_finalrun_navblock", "Everyone", "Apply", "-18 -36 -32", "18 36 32", "3050 3925 153" );
make_prop( "dynamic",		"_losblocker_finalrun_screen",	"models/props_unique/airportdeparturescreen01.mdl",	"2983 3925 151.25",		"0 180 0",		"shadow_no" );
make_trigduck( "_duckqol_missingvent", "-5 -32 -32", "5 32 32", "716 928 160" );
make_trigmove( "_duckqol_vanfence", "Duck", "-11 -8 0", "11 8 17", "-285 3524 191" );
patch_nav_checkpoint( "3175 4562 152" );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c11m5_runway":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

EntFire( "worldspawn", "RunScriptFile", "c11m5_versus_planecrash" );

make_brush( "_losfix_lowthinwing",	"-8 -116 -30",	"8 111 32",	"-6057 9725 -12" );
make_brush( "_losfix_truck1",		"-56 -1 -12",	"71 1 28",	"-5039 8665 -180" );
make_brush( "_losfix_truck2",		"-1 -29 -12",	"1 60 14",	"-4968 8695 -181" );
make_brush( "_losfix_truck3",		"-1 -28 -12",	"1 29 28",	"-5093 8635 -180" );
make_clip( "_boardingramp_wallclip", "SI Players", 1, "-200 -4 -1", "333 3 1", "-5824 10391.5 220", "4 0 0" );
make_clip( "_collapsedbuilding_clip1", "SI Players", 1, "-330 -190 -125", "330 185 220", "-6506 7723 -123", "-1 8 60" );
make_clip( "_collapsedbuilding_clip2", "SI Players", 1, "-330 -240 -600", "325 200 1036", "-6495 7469 403" );
make_clip( "_lowthinwing_collision", "Everyone", 1, "-8 -116 -30", "8 111 32", "-6057 9725 -12" );
make_clip( "_planecrash_concreteramp", "SI Players", 1, "-290 -10 0", "345 10 185", "-4127 11223 -128", "0 -56 45" );
make_ladder( "_ladder_boardingtables_cloned_cargocontainerfront", "-6663 9840 -127.879", "-1707 -769 287", "0 -13 0", "0.97 -0.22 0" );
make_ladder( "_ladder_catertruckleft1_cloned_escapeplaneright", "-4166 9126 -96", "4184 4433 -19", "0 30.26 0", "0.86 0.5 0" );
make_ladder( "_ladder_catertruckleft2_cloned_escapeplaneright", "-4166 9126 -96", "-12338 15912 -19", "0 -149.58 0", "-0.86 -0.5 0" );
make_ladder( "_ladder_catertruckright1_cloned_escapeplaneright", "-4166 9126 -96", "-10848 335 -19", "0 -59.5 0", "0.5 -0.86 0" );
make_ladder( "_ladder_catertruckright2_cloned_escapeplaneright", "-4166 9126 -96", "1280 16353 -19", "0 115.47 0", "-0.5 0.86 0" );
make_ladder( "_ladder_collapsedbuilding_cloned_escapeplaneleft", "-4354 9230 -96", "-365 16080 -488", "6 117 0", "0.45 -0.89 0" );
make_ladder( "_ladder_collapsedbuildingdoor_cloned_cargocontainerfront", "-6663 9840 -127.879", "-141 -2059 208" );
make_ladder( "_ladder_skybridgeleft_cloned_skybridgemid", "-5626 10415 36", "5750 6079 0", "0 46 0", "-0.72 0.69 0" );
make_ladder( "_ladder_wreckedengine_cloned_escapeplaneleft", "-4354 9230 -96", "-3933 -1386 -2219", "15 -14.3 7", "-0.96 0.27 0" );
make_ladder( "_ladder_wreckedfuselage_cloned_cargoslanted", "-4332 8255.36 -114.329", "-5096 1415 56", "0 -21.65 0", "0.34 0.94 0" );
make_ladder( "_ladder_wreckedrear_cloned_escapeplaneleft", "-4354 9230 -96", "-2781 246 -12", "0 -5.65 0", "-1 0.1 0" );
make_prop( "dynamic",		"_losblocker_fireline_tractor",	"models/props_vehicles/airport_baggage_tractor.mdl",	"-2980.23 10393 -141",		"70 180 -10",		"shadow_no" );

DoEntFire( "!self", "AddOutput", "OnBreak anv_mapfixes_boardingramp_wallclip:Kill::0:-1", 0.0, null, Entities.FindByClassnameNearest( "func_breakable", Vector( -5913.99, 10371.6, 162.64 ), 1 ) );
DoEntFire( "!self", "AddOutput", "OnBreak anv_mapfixes_boardingramp_wallclip:Kill::0:-1", 0.0, null, Entities.FindByClassnameNearest( "func_breakable", Vector( -5727.82, 10368.7, 143.43 ), 1 ) );
DoEntFire( "!self", "AddOutput", "OnBreak anv_mapfixes_boardingramp_wallclip:Kill::0:-1", 0.0, null, Entities.FindByClassnameNearest( "func_breakable", Vector( -5611.89, 10356, 143.21 ), 1 ) );

con_comment( "PROP:\tBaggage cart under the plane wing moved closer to the ring of fire to give infected better spawn points" );

kill_entity( Entities.FindByClassnameNearest( "prop_physics", Vector( -3708, 8863, -165.5 ), 8 ) );
make_prop( "physics", "_replacement_baggagecart", "models/props_vehicles/airport_baggage_cart2.mdl", "-3791 9604 -191", "0 60 0", "shadow_no" );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*==============================
||                            ||
||       BLOOD HARVEST        ||
||                            ||
==============================*/

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c12m1_hilltop":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

kill_funcinfclip( 1014.64 );	// Deletes clip above end cliff on right side
kill_funcinfclip( 1039.64 );	// Deletes clip above end cliff on left side
kill_funcinfclip( 1364.13 );	// Desirably deletes clip over the 1st rockcliffs on far-right (same)
kill_funcinfclip( 1454.65 );	// Deletes mildly-ladder-blocking fallen-trees chasm-crossing clip
kill_funcinfclip( 848.51 );	// Deletes next one in flow order (after above)
kill_funcinfclip( 849.49 );	// Deletes far-right largest clip (speaking in order of flow)
kill_funcinfclip( 986.591 );	// Deletes finally the clip above Valve's broken cliff ladder
kill_funcinfclip( 770.171 );	// Delete clip above tall yellow building in end area
kill_funcinfclip( 739.388 );	// Delete clip directly above end safe room (for Hunter)
kill_funcinfclip( 1081.48 );	// Delete clip for fence right of end safe room (all SI)
kill_funcinfclip( 741.805 );	// Delete clip above RICHARDSON ATLANTIC building for Hunter-only
EntFire( "worldspawn", "RunScriptCode", "kill_funcinfclip( 1364.13 )", 1 );	// Undesirably deletes clip behind start area (_meticulous repair)
make_clip( "_ladder_rockcliffback_clip", "SI Players", 1, "-24 -15 0", "27 56 25", "-10172 -10751 813", "0 49 0" );
make_clip( "_ladderqol_rockcliff", "SI Players", 1, "-32 -77 0", "32 100 32", "-10235 -12716 528", "0 30 -30" );
make_clip( "_meticulous_funcinfclip00", "SI Players", 1, "-32 -217 -640", "32 177 1935", "-7624 -14554 257" );
make_clip( "_meticulous_funcinfclip01", "SI Players", 1, "-492 -6 -977", "553 6 657", "-7806 -7614 1536", "0 38 0" );
make_clip( "_meticulous_funcinfclip02", "SI Players", 1, "-420 -32 -640", "420 32 1935", "-9771 -13110 257", "0 -40 0" );
make_clip( "_meticulous_funcinfclip03", "SI Players", 1, "-32 -384 -777", "32 384 1935", "-9849 -12580 257", "0 -40 0" );
make_clip( "_meticulous_funcinfclip04", "SI Players", 1, "-280 0 -640", "550 32 1635", "-10788 -8902 557" );
make_clip( "_meticulous_funcinfclip05", "SI Players", 1, "-280 0 -640", "210 32 1635", "-11103 -9082 557", "0 70 0" );
make_clip( "_meticulous_funcinfclip06", "SI Players", 1, "-8 -320 0", "8 320 1454", "-9996 -8345 738", "0 -36 0" );
make_clip( "_meticulous_funcinfclip07", "SI Players", 1, "-8 -160 0", "8 160 1372", "-6728 -7101 820" );
make_clip( "_meticulous_funcinfclip08", "SI Players", 1, "-777 -8 0", "1000 8 1372", "-5988 -6941 820" );
make_clip( "_meticulous_funcinfclip09", "SI Players", 1, "-205 -8 0", "1000 8 885", "-5988 -6941 -65" );
make_clip( "_meticulous_stuckspot", "SI Players", 1, "-420 -128 -640", "640 32 600", "-9801 -13140 120", "-20 -40 0" );
make_clip( "_meticulous_slidespot", "SI Players", 1, "-108 -56 0", "643 16 88", "-10932 -8918 432" );
make_ladder( "_ladder_1stcliffback_cloned_startwide", "-8180.8638 -14508.2334 12.3855", "-12520 3632 3095", "0 37.14 10", "-0.61 0.79 0" );
make_ladder( "_ladder_1stclifffront_cloned_prebridgewide", "-11628.5 -12194.834 161", "1441 -1480 -1124", "0 0 -8" );
make_ladder( "_ladder_2ndcliffback_cloned_endfencewide", "-6124 -7222.7998 175.5", "-4620 -2295 2337", "0 0 15" );
make_ladder( "_ladder_2ndclifffront_cloned_postbridgewide", "-11328 -11030 -70", "4300 -10407 -2705", "0 -46.6 -17", "-0.73 -0.69 0" );
make_ladder( "_ladder_2ndclifftank_cloned_elecboxchairs", "-11227.5 -9748 517", "1026 750 40" );
make_ladder( "_ladder_endelecbox_cloned_elecboxchairs", "-11227.5 -9748 517", "4652 1595 -24" );
make_ladder( "_ladder_endfenceback_cloned_farunused", "-11520 -8870 168", "5386 1595 124" );
make_ladder( "_ladder_endfencefront_cloned_freighttripipe", "-7252 -8192.5 370", "1104 891 4" );
make_ladder( "_ladder_rockcliffback_cloned_unusedladder", "-10213 -12939 834.173", "6102 -7889 560", "-4 -41.58 0", "0.73 -0.69 0" );
make_ladder( "_ladder_skybridgeleftB_cloned_trackstoshed", "-7726 -8871.5 120", "78 -605 97", "0 0 -2" );
make_ladder( "_ladder_skybridgeleftT_cloned_trackstoshed", "-7726 -8871.5 120", "78 -597.45 321", "0 0 -2" );
make_ladder( "_ladder_skybridgerightB_cloned_trackstoshed", "-7726 -8871.5 120", "-242 -605 97", "0 0 -2" );
make_ladder( "_ladder_skybridgerightT_cloned_trackstoshed", "-7726 -8871.5 120", "-242 -597.45 321", "0 0 -2" );
patch_ladder( "-10213 -12939 834.173", "22 0 0" );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c12m2_traintunnel":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

kill_funcinfclip( 741.034 );	// Delete clip above RICHARDSON ATLANTIC building for Hunter-only
make_atomizer( "_atomizer_bsp_forkliftinnie", "-8604 -7271 -64", "models/props\\cs_assault\\forklift_brokenlift.mdl", 60 );
make_atomizer( "_atomizer_bsp_forkliftoutie", "-8604 -7531 -64", "models/props\\cs_assault\\forklift_brokenlift.mdl", 30 );
make_clip( "_charger_smoother_01", "Everyone", 1, "-4 -136 -17",	"4 718 1",	"-8733 -8038 176",	"46 -90 0" );
make_clip( "_charger_smoother_02", "Everyone", 1, "-4 -132 -17",	"4 700 1",	"-7500 -8038 176",	"46 -90 0" );
make_clip( "_ladder_indoorventduct_clip", "Everyone", 1, "-22 -32 0", "42 32 223", "-8170 -6300 -64" );
make_clip( "_ladder_parkourvent_clip", "SI Players", 1, "-1 -17 0", "0 17 64", "-8723 -7415 163" );
make_clip( "_meticulous_funcinfclip01", "SI Players", 1, "-492 -6 -977", "553 6 657", "-7806 -7614 1536", "0 38 0" );
make_ladder( "_ladder_boxcarbm1mirr_cloned_firstwindow", "-6728.5 -6458 72", "-2053 -15104 -120", "0 -90 0", "0 1 0" );
make_ladder( "_ladder_boxcarcm1mirr_cloned_firstwindow", "-6728.5 -6458 72", "-14627 -1792 -120", "0 90 0", "0 -1 0" );
make_ladder( "_ladder_eventdoorback_cloned_triplepipes", "-7252 -8080.5 370", "-15712 -333 -250", "0 90 0", "1 0 0" );
make_ladder( "_ladder_eventdoorfront_cloned_triplepipes", "-7252 -8080.5 370", "64 -14840 -250", "0 -90 0", "-1 0 0" );
make_ladder( "_ladder_indoorboxcar_cloned_warehousecorner", "-8767.5 -7152 113", "1199 622 -172" );
make_ladder( "_ladder_indoorventduct_cloned_unusedcliff", "-6124 -7222.8 175.5", "-906 -12423 -260", "0 -90 0", "1 0 0" );
make_ladder( "_ladder_parkourvent_cloned_insideboxcar", "-5991 -8719 32", "-2735 1304 72" );
make_ladder( "_ladder_skybridgeleftB_cloned_trackstoshed", "-7726 -8871.5 132", "78 -584 417", "0 0 0" );
make_ladder( "_ladder_skybridgeleftT_cloned_trackstoshed", "-7726 -8871.5 132", "78 -584 641", "0 0 0" );
make_ladder( "_ladder_skybridgem1mirr_cloned_restoredbluebox", "-5991 -8719 32", "911 -14630 722", "0 -90 0", "0 -1 0" );
make_ladder( "_ladder_skybridgerightB_cloned_trackstoshed", "-7726 -8871.5 132", "-242 -584 417", "0 0 0" );
make_ladder( "_ladder_skybridgerightT_cloned_trackstoshed", "-7726 -8871.5 132", "-242 -584 641", "0 0 0" );
make_ladder( "_ladder_starthugevent_cloned_traintracktall", "-7726 -8871.5 132", "-15592 751 -24", "0 90 0", "-1 0 0" );
make_ladder( "_ladder_tankbeamescape_cloned_insideboxcar", "-5991 -8719 32", "737 -14088 84", "0 -90 0", "0 -1 0" );
make_ladder( "_ladder_warehouseboxes_cloned_warehousecorner", "-8767.5 -7152 113", "1601 988 -115" );
patch_ladder( "-4322 -8715 32", "71 0 21" );
patch_ladder( "-5991 -8719 32", "247 0 21" );

make_prop( "dynamic", "_easter_dorykcir", "models/weapons/melee/w_crowbar.mdl", "-8690 -7340 201", "0 -45 90", "shadow_no" );
make_prop( "dynamic_ovr", "_easter_yofffej", "models/props_junk/gnome.mdl", "-8695 -7340 211", "0 45 0", "shadow_no" );
EntFire( g_UpdateName + "_easter_dorykcir", "skin", "1" );

con_comment( "QOL:\tDeleted blockers to allow ghost infected to pass through the event door for Versus-only QoL." );
kill_entity( Entities.FindByClassnameNearest( "func_brush", Vector( -8600, -7540, -8.13 ), 1 ) );
kill_entity( Entities.FindByClassnameNearest( "func_brush", Vector( -8600, -7524, -8.13 ), 1 ) );
EntFire( "emergency_door_sign", "DisableCollision", 1 );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c12m3_bridge":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

kill_funcinfclip( 2553.75 );		// Delete clips all around start area
kill_funcinfclip( 3752.27 );		// Delete clips all around end area
make_clip( "_ladder_generatorhouse_clip", "Everyone", 1, "-3 -37 0", "13 43 140", "6531 -13083 -58" );
make_clip( "_ladder_newtankperch_clip", "SI Players", 1, "-38 -16 0", "38 128 32", "3465 -10222 158", "0 3 30" );
make_clip( "_ladder_pinkstairwell_clip", "Survivors", 1, "-156 -3 0", "156 0 124", "1740 -12296 260" );
make_clip( "_ladder_rightquickcliff_clip", "SI Players", 1, "-32 -21 0", "32 21 17", "2032 -10510 232", "15 4 0" );
make_clip( "_ladder_rightquickcliff_rock", "SI Players", 1, "-20 -26 0", "56 26 8", "2101 -10514 17", "25 0 0" );
make_clip( "_ladder_startventshaft_clipleft", "Everyone", 1, "-10 -12 0", "0 0 233", "-1030 -10911 -32", "0 -47 0" );
make_clip( "_ladder_startventshaft_clipright", "Everyone", 1, "-10 -12 0", "0 0 233", "-1005 -10903 -32", "0 47 0" );
make_clip( "_meticulous_funcinfclip01", "SI Players", 1, "-17 -515 -216", "150 721 1408", "-688 -10708 321" );
make_clip( "_meticulous_funcinfclip02", "SI Players", 1, "-1000 -17 -170", "1150 17 1408", "262 -11524 321", "0 -21 0" );
make_clip( "_meticulous_funcinfclip03", "SI Players", 1, "-34 -238 0", "57 260 1408", "1323 -12178 321" );
make_clip( "_meticulous_funcinfclip04", "SI Players", 1, "-310 -17 159", "724 17 1408", "1616 -12255 321" );
make_clip( "_meticulous_funcinfclip05", "SI Players", 1, "-1000 -310 -170", "850 187 1408", "262 -11524 321" );
make_clip( "_meticulous_funcinfclip06", "SI Players", 1, "-235 -165 64", "525 260 1408", "2560 -12100 321" );
make_clip( "_meticulous_funcinfclip07", "SI Players", 1, "-48 -555 -216", "17 1414 1408", "3276 -11409 321", "0 -24 0" );
make_clip( "_meticulous_funcinfclip08", "SI Players", 1, "-34 -120 -216", "17 700 1408", "3821 -10047 321", "0 24 0" );
make_clip( "_meticulous_funcinfclip09", "SI Players", 1, "-1600 -30 -216", "1600 17 1408", "1980 -9420 321" );
make_clip( "_meticulous_funcinfclip10", "SI Players", 1, "-600 -70 -216", "600 17 1408", "-132 -9696 321", "0 27 0" );
make_clip( "_meticulous_funcinfclip11", "SI Players", 1, "-17 -555 -55", "17 1414 1408", "2361 -13935 321" );
make_clip( "_meticulous_funcinfclip12", "SI Players", 1, "-3000 -17 -216", "3000 17 1408", "5344 -14507 321" );
make_clip( "_meticulous_funcinfclip13", "SI Players", 1, "-800 -17 -216", "500 17 1408", "9070 -14172 321", "0 25 0" );
make_clip( "_meticulous_funcinfclip14", "SI Players", 1, "-17 -761 -420", "17 1248 1408", "9216 -13284 321", "0 25 0" );
make_clip( "_meticulous_funcinfclip15", "SI Players", 1, "-320 -17 -216", "216 17 1408", "8456 -12150 321" );
make_clip( "_meticulous_funcinfclip16", "SI Players", 1, "-17 -170 -216", "17 610 1408", "8153 -11970 321" );
make_clip( "_meticulous_funcinfclip17", "SI Players", 1, "-78 -17 -216", "216 17 1408", "7954 -11343 321" );
make_clip( "_meticulous_funcinfclip18", "SI Players", 1, "-128 -17 360", "216 17 1408", "7660 -11343 321" );
make_clip( "_meticulous_funcinfclip19", "SI Players", 1, "-300 -17 -216", "1173 17 1408", "6359 -11309 321" );
make_clip( "_meticulous_funcinfclip20", "SI Players", 1, "-300 -21 -216", "1173 17 1408", "4998 -11810 321", "0 25 0" );
make_clip( "_meticulous_funcinfclip21", "SI Players", 1, "-711 -17 -216", "1717 17 1408", "3060 -12382 321", "0 15 0" );
make_clip( "_tunneltophill_wrongway_clip", "SI Players", 1, "-2 -128 -110", "100 290 1070", "3320 -12528 658" );
make_ladder( "_ladder_backtrains_cloned_midmound", "2438 -9808 60", "15702 -5728 -39", "0 -58.35 0", "0.53 -0.85 0" );
make_ladder( "_ladder_barnhousefront_cloned_treetrunkcliff", "982 -10596 116", "11972 -7767 -89", "0 -59.54 0", "-0.5 0.87 0" );
make_ladder( "_ladder_generatorhouse_cloned_doublerbottom", "-179.799 -10591.8 4", "14106 -5707 -673", "3.5 -45 -3.5", "1 0 0" );
make_ladder( "_ladder_leftcliffmini_cloned_startcliff", "982 -10596 116", "1185 669 -45", "4 0 0" );
make_ladder( "_ladder_lobsterrock_cloned_startcliff", "982 -10596 116", "11923 -11336 785", "32 -95 0", "0.09 1 0" );
make_ladder( "_ladder_newtankperchB_cloned_midmound", "2438 -9808 60", "13151 -7359 -26", "0 -87.35 0", "0 -1 0" );
make_ladder( "_ladder_newtankperchT_cloned_midmound", "2438 -9808 60", "13151 -7359 70", "0 -87.35 0", "0 -1 0" );
make_ladder( "_ladder_peskyrooftopB_cloned_midmound", "2438 -9808 60", "-8232 -14251 232", "0 90 0", "0 1 0" );
make_ladder( "_ladder_peskyrooftopT_cloned_midmound", "2438 -9808 60", "-8232 -14359 360", "0 90 0", "0 1 0" );
make_ladder( "_ladder_rightquickcliff_cloned_trainshedpipe", "3630.5747 -14189.8496 37.2963", "-12203 -7403 -900", "0 63.31 -4", "1 0.06 0" );
make_ladder( "_ladder_startventshaft_cloned_treetrunkcliff", "982 -10596 116", "-11617 -11894 -32", "0 90 0", "0 -1 0" );
make_ladder( "_ladder_tunnelexittop1_cloned_midmound", "2438 -9808 60", "181 -3603 -64", "0 0 0", "1 0 0" );
make_ladder( "_ladder_tunnelexittop2_cloned_midmound", "2438 -9808 60", "181 -3603 32", "0 0 0", "1 0 0" );
make_ladder( "_ladder_tunnelexittop3_cloned_midmound", "2438 -9808 60", "181 -3603 128", "0 0 0", "1 0 0" );
make_ladder( "_ladder_tunnelexittop4_cloned_midmound", "2438 -9808 60", "181 -3603 224", "0 0 0", "1 0 0" );
make_ladder( "_ladder_tunnelexittop5_cloned_midmound", "2438 -9808 60", "181 -3603 320", "0 0 0", "1 0 0" );
make_prop( "dynamic", "_cosmetic_starthillside_treea", "models/props_foliage/cedar_large01.mdl", "3643 -9364 245", "0 265 0", "shadow_no", "solid_no" );
make_prop( "dynamic", "_cosmetic_starthillside_treeb", "models/props_foliage/cedar_large01.mdl", "1166 -12035 527", "0 58 0", "shadow_no", "solid_no" );
make_prop( "dynamic", "_cosmetic_starthillside_treec", "models/props_foliage/cedar_large01.mdl", "1048 -11800 504", "0 52 0", "shadow_no", "solid_no" );
make_prop( "dynamic", "_cosmetic_starthillside_rock", "models/props_wasteland/rock_moss04.mdl", "3760 -10536 264", "0 42 0", "shadow_no", "solid_no" );
make_prop( "dynamic", "_losblocker_finalfence", "models/props_wasteland/rock_moss04.mdl", "5510 -12032 444", "0 216 0", "shadow_no" );
make_prop( "dynamic", "_peskyrooftop_wrongwaya", "models/props_misc/wrongway_sign01_optimized.mdl", "1882 -12238 540", "0 90 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_peskyrooftop_wrongwayb", "models/props_misc/wrongway_sign01_optimized.mdl", "1648 -12238 540", "0 90 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_peskyrooftop_leftside_wrongway", "models/props_misc/wrongway_sign01_optimized.mdl", "2320 -11900 520", "0 180 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_peskyrooftop_rightside_wrongwaya", "models/props_misc/wrongway_sign01_optimized.mdl", "1116 -11423 565", "0 0 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_peskyrooftop_rightside_wrongwayb", "models/props_misc/wrongway_sign01_optimized.mdl", "1116 -11660 565", "0 0 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_redbrushclip_wrongwaya1", "models/props_misc/wrongway_sign01_optimized.mdl", "5412 -12008 545", "0 0 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_redbrushclip_wrongwaya2", "models/props_misc/wrongway_sign01_optimized.mdl", "5412 -12008 545", "0 180 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_redbrushclip_wrongwayb1", "models/props_misc/wrongway_sign01_optimized.mdl", "5412 -12295 455", "0 0 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_redbrushclip_wrongwayb2", "models/props_misc/wrongway_sign01_optimized.mdl", "5412 -12295 455", "0 180 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_tunneltopcliff_wrongwaya", "models/props_misc/wrongway_sign01_optimized.mdl", "3330 -12400 825", "0 180 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_tunneltopcliff_wrongwayb", "models/props_misc/wrongway_sign01_optimized.mdl", "3330 -12590 730", "0 180 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_tunneltopcliff_wrongwayc", "models/props_misc/wrongway_sign01_optimized.mdl", "3390 -12400 820", "0 0 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_tunneltopcliff_wrongwayd", "models/props_misc/wrongway_sign01_optimized.mdl", "3390 -12590 730", "0 0 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c12m4_barn":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

make_brush( "_losfix_semia",		"-1 -30 -15",	"1 30 15",	"11440 -7078 -56" );
make_brush( "_losfix_semib",		"-50 -1 -15",	"30 1 15",	"11440 -7048 -56" );
make_clip( "_ladder_barnhousedoor_clip", "Everyone", 1, "-2 -112 9", "2 112 21", "8994 -9312 471" );
make_clip( "_ladder_finalrooftop_permstuck", "Everyone", 1, "-53 -19 0", "21 31 100", "10827 -4563 -62" );
make_clip( "_ladder_siloleft_clip1", "SI Players", 1, "-50 -24 0", "50 24 1", "8556 -7849 1035", "0 -52 0" );
make_clip( "_ladder_siloleft_clip2", "SI Players", 1, "-50 -24 0", "50 24 1", "8541 -7849 1052", "0 -52 0" );
make_clip( "_ladder_siloright_clip1", "SI Players", 1, "-50 -24 0", "50 24 1", "8909 -7849 1035", "0 -52 0" );
make_clip( "_ladder_siloright_clip2", "SI Players", 1, "-50 -24 0", "50 24 1", "8894 -7849 1052", "0 -52 0" );
make_clip( "_ladder_siloshared_clip", "SI Players", 1, "-170 -136 -72", "183 76 64", "8608 -7937 1001" );
make_clip( "_ladder_upperplanks_clipleft", "Everyone", 1, "-16 -5 0", "1 4 179", "10743 -9075 -11", "0 -33 0" );
make_clip( "_ladder_upperplanks_clipright", "Everyone", 1, "-46 -5 0", "25 4 179", "10678 -9067 -11" );
make_ladder( "_ladder_atlanticdiesel_cloned_trussfenceback", "10528 -7510 10", "436 -211 250" );
make_ladder( "_ladder_atlanticroofback_cloned_atlanticpipe", "11150 -9016 104.5", "447 1011 -40" );
make_ladder( "_ladder_atlanticroofleftB_cloned_bridgetower", "10321 -1894 162.5", "304 -5778 -282" );
make_ladder( "_ladder_atlanticroofleftT_cloned_bridgetower", "10321 -1894 162.5", "304 -5778 -90" );
make_ladder( "_ladder_barnhousedoor_cloned_atlanticpipe", "11150 -9016 104.5", "-2157 -216 327" );
make_ladder( "_ladder_crashedback_cloned_trussfencefront", "10384 -7522 10", "-64 -2804 -52", "0 0.5 0" );
make_ladder( "_ladder_crashedfront_cloned_trussfenceback", "10528 -7510 10", "-226.425 -2677 -37" );
make_ladder( "_ladder_elevatedhome_cloned_trussfencefront", "10384 -7522 10", "-1016 -72 16", "0 9 0", "0.16 -0.98 0" );
make_ladder( "_ladder_finalrooftopB_cloned_bridgetower", "10321 -1894 162.5", "504 -2712 -251" );
make_ladder( "_ladder_finalrooftopT_cloned_bridgetower", "10321 -1894 162.5", "504 -2712 -59" );
make_ladder( "_ladder_rocklobboxcar_cloned_trussfencefront", "10384 -7522 10", "23 -1461 27" );
make_ladder( "_ladder_shortfenceL_cloned_trussfencefront", "10384 -7522 10", "-860 -555 240" );
make_ladder( "_ladder_shortfenceR_cloned_backbarnshortfence", "8042 -9584 338", "1104 -485 48" );
make_ladder( "_ladder_siloleft_cloned_atlanticpipe", "11150 -9016 104.5", "-5753 -7451 420", "0 37.5 0", "0.78 0.62 0" );
make_ladder( "_ladder_siloleft_cloned_atlanticpipe", "11150 -9016 104.5", "-5753 -7451 740", "0 37.5 0", "0.78 0.62 0" );
make_ladder( "_ladder_siloright_cloned_atlanticpipe", "11150 -9016 104.5", "-5401 -7452 420", "0 37.5 0", "0.78 0.62 0" );
make_ladder( "_ladder_siloright_cloned_atlanticpipe", "11150 -9016 104.5", "-5401 -7452 740", "0 37.5 0", "0.78 0.62 0" );
make_ladder( "_ladder_upperplanks_cloned_bridgetower", "10321 -1894 162.5", "12612 1256 -89", "0 -90 0", "0 1 0" );
make_ladder( "_ladder_wreckedboxcar_cloned_trussfencefront", "10384 -7522 10", "-1619 -10047 -14", "0 57.72 0", "0.85 -0.52 0" );
make_prop( "dynamic", "_ladder_atlanticroofback_pipe", "models/props_mill/PipeSet08d_256_001a.mdl", "11590 -8002 77", "-90 90 180", "shadow_no" );
make_prop( "dynamic", "_ladder_atlanticroofleft_pipe", "models/props_rooftop/Gutter_Pipe_256.mdl", "10632 -7672 168", "0 -90 0", "shadow_no" );
make_prop( "dynamic", "_ladder_finalrooftop_pipe", "models/props_mill/PipeSet08d_256_001a.mdl", "10842 -4603 84", "90 90 0", "shadow_no" );
make_prop( "dynamic", "_solidify_finalchimney1", "models/props/cs_militia/fireplacechimney01.mdl", "11020 -4586 329", "0 135 0", "shadow_no" );
make_prop( "dynamic", "_solidify_finalchimney2", "models/props/cs_militia/fireplacechimney01.mdl", "11020 -4073 329", "0 135 0", "shadow_no" );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c12m5_cornfield":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

kill_funcinfclip( 3833.37 );		// Delete clip blocking access to vast start perimeter and one-way drop
kill_funcinfclip( 4564.93 );		// Delete clip blocking access to vast end perimeter (including barricade)
make_brush( "_losfix_gen",		"-24 -1 -6",	"24 1 6",	"7027 793 207" );
make_brush( "_losfix_tractor",		"-56 -1 -15",	"56 1 15",	"8713 1804 212" );
make_clip(	"_fence_collision",				"SI Players",	1,	"-4 -128 -80",		"4 240 20",		"8520 3627 579", "0 -32 0" );
make_clip(	"_fence_stuckspot",				"SI Players",	1,	"-60 -80 -80",		"4 60 20",		"8624 3811 579", "0 -32 0" );
make_clip(	"_meticulous_funcinfclip01",	"SI Players",	1,	"-573 120 -295",	"219 282 1205",		"9765 3742 651" );
make_clip(	"_meticulous_funcinfclip02",	"SI Players",	1,	"400 -585 -459",	"447 972 1205",		"7745 4147 651" );
make_clip(	"_meticulous_funcinfclip03",	"SI Players",	1,	"-744 -54 -459",	"447 972 1205",		"7745 4147 651" );
make_clip(	"_meticulous_funcinfclip04",	"SI Players",	1,	"-2464 0 -459",		"447 1470 1205",	"6554 4147 651" );
make_clip(	"_meticulous_funcinfclip05",	"SI Players",	1,	"-2464 -5300 -459",	"-2042 1470 1205",	"6554 4147 651" );
make_clip(	"_meticulous_funcinfclip06",	"SI Players",	1,	"-2464 -5300 -459",	"-90 -5043 1205",	"6554 4147 651" );
make_clip(	"_meticulous_funcinfclip07",	"SI Players",	1,	"-573 130 -295",	"-50 152 -90",		"9329 4402 651" );
make_clip(	"_meticulous_funcinfclip08",	"SI Players",	1,	"-50 130 -295",		"219 152 -70",		"9329 4402 651" );
make_clip(	"_meticulous_funcinfclip09",	"SI Players",	1,	"-744 -659 -459",	"-482 972 1205",	"8936 4147 651" );
make_clip(	"_meticulous_funcinfclip10",	"SI Players",	1,	"-744 722 -459",	"2840 972 1205",	"8936 4147 651" );
make_clip(	"_meticulous_funcinfclip11",	"SI Players",	1,	"0 -2687 -882",		"1615 2592 782",	"11776 2527 1074" );
make_clip( "_ladder_barnhouseback_clipleft", "Everyone", 1, "-3 -16 0", "1 11 321", "6963 -574 200", "0 52 0" );
make_clip( "_ladder_barnhouseback_clipright", "Everyone", 1, "-3 -19 0", "1 8 355", "7024 -574 200", "0 -52 0" );
make_clip( "_ladder_onewaydrop_collision", "SI Players", 1, "-1 -142 0", "1 130 111", "9200 3714 393" );
make_clip( "_ladder_onewayfence_qolclip", "SI Players", 1, "-38 -24 -17", "48 42 36", "9018 4530 399", "3 0 42" );
make_clip( "_ladder_siloleft_clip1", "SI Players", 1, "-50 -24 0", "50 24 1", "7309 2735 970", "0 -52 0" );
make_clip( "_ladder_siloleft_clip2", "SI Players", 1, "-50 -24 0", "50 24 1", "7294 2735 984", "0 -52 0" );
make_clip( "_ladder_siloright_clip1", "SI Players", 1, "-50 -24 0", "50 24 1", "7662 2735 970", "0 -52 0" );
make_clip( "_ladder_siloright_clip2", "SI Players", 1, "-50 -24 0", "50 24 1", "7647 2735 984", "0 -52 0" );
make_clip( "_ladder_siloshared_clip", "SI Players", 1, "-170 -136 -72", "183 76 64", "7361 2647 933" );
make_clip( "_meticulous_permstuck", "SI Players", 1, "-16 -216 -237", "800 17 1193", "8470 4808 663", "0 9 0" );
make_clip( "_onewaydrophill_clip", "SI Players", 1, "-2 -255 -115", "370 175 1271", "9613 3664 584" );
make_clip( "_pouncersonly_clip", "SI Players", 1, "-229 -386 -170", "394 320 1586", "11382 4549 270" );
make_clip( "_wrongway_clipa", "Everyone", 1, "-1600 -61 0", "401 128 1640", "6044 3997 196" );
make_clip( "_wrongway_clipb", "Everyone", 1, "-288 -61 0", "600 128 1640", "6706 4072 196", "0 16 0" );
make_ladder( "_ladder_barnhouseback_cloned_haybalebarn", "8128 131.5 374.5", "-1137 -718 4" );
make_ladder( "_ladder_barnhouseicing_cloned_barnhousefront", "7100 266.5 301.922", "6937 -6981 65.6", "0 90 38", "-1 0 0" );
make_ladder( "_ladder_barricadeback_cloned_oneway", "9020 3500 272", "15070 7001 40", "0 180 0", "0 1 0" );
make_ladder( "_ladder_barricadefront_cloned_oneway", "9020 3500 272", "-2970 -3 41" );
make_ladder( "_ladder_boxcardeadend_cloned_housegenerator", "7119 887.5 296", "3539 2400 -226", "0 10.58 0", "0.18 -0.98 0" );
make_ladder( "_ladder_boxcarstartline_cloned_housegenerator", "7119 887.5 296", "3861 4914 -280", "0 -28.05 0", "-0.47 -0.88 0" );
make_ladder( "_ladder_onewaydrop_cloned_hayhaildiesel", "6693.5 204 253", "2504 3592 198" );
make_ladder( "_ladder_onewayfence_cloned_housegenerator", "7119 887.5 296", "1901 3644 186" );
make_ladder( "_ladder_permstuck_cloned_toolshed", "7101 2140.5 275", "3898 6909 -199", "0 -33.46 0", "0.56 0.83 0" );
make_ladder( "_ladder_siloleft_cloned_haybalebarn", "8128 131.5 374.5", "12550 -3471 420", "0 129 0", "0.78 0.62 0" );
make_ladder( "_ladder_siloleft_cloned_haybalebarn", "8128 131.5 374.5", "12550 -3471 68", "0 129 0", "0.78 0.62 0" );
make_ladder( "_ladder_siloright_cloned_haybalebarn", "8128 131.5 374.5", "12903 -3471 420", "0 129 0", "0.78 0.62 0" );
make_ladder( "_ladder_siloright_cloned_haybalebarn", "8128 131.5 374.5", "12903 -3471 68", "0 129 0", "0.78 0.62 0" );
make_ladder( "_ladder_tallchimneybot_cloned_haybalebarn", "8128 131.5 374.5", "-1304 732 -14" );
make_ladder( "_ladder_tallchimneytop_cloned_haybalebarn", "8128 131.5 374.5", "-1304 732 306" );
make_navblock( "_losblocker_rockleft_navblock", "Everyone", "Apply", "-18 -36 -32", "18 36 32", "10335 1520 -64" );
make_prop( "dynamic", "_cosmetic_barric_cliffside", "models/props_wasteland/rock_cliff01.mdl", "4646 4080 602", "0 260 0", "shadow_no" );
make_prop( "dynamic", "_cosmetic_hillside_rocka", "models/props_wasteland/rock_moss04.mdl", "8760 4766 571", "260 120 20", "shadow_no", "solid_no" );
make_prop( "dynamic", "_cosmetic_hillside_rockb", "models/props_wasteland/rock_moss04.mdl", "8878 4781 566", "60 -80 160", "shadow_no", "solid_no" );
make_prop( "dynamic", "_cosmetic_hillside_rockc", "models/props_wasteland/rock_moss04.mdl", "9000 4800 571", "-70 80 70", "shadow_no", "solid_no" );
make_prop( "dynamic", "_cosmetic_hillside_tree", "models/props_foliage/cedar_medium01.mdl", "9299 4928 536", "0 264 0", "shadow_no", "solid_no" );
make_prop( "dynamic", "_losblocker_barric_cliffside", "models/props_wasteland/rock_moss04.mdl", "4879 2680 460", "120 252 0", "shadow_no" );
make_prop( "dynamic", "_losblocker_hillside_rock", "models/props_wasteland/rock_moss04.mdl", "9200 4792 550", "50 30 -130", "shadow_no" );
make_prop( "dynamic",		"_losblocker_rockleft",		"models/props_wasteland/rock_moss04.mdl",		"10344 1529.7 -14",		"-12.56 346.66 22.6",	"shadow_no" );
make_prop( "dynamic", "_losblocker_freeatlasta", "models/props_wasteland/rock_moss04.mdl", "7026 3507 421", "130 287 -62", "shadow_no" );
make_prop( "dynamic", "_losblocker_freeatlastb", "models/props_wasteland/rock_moss04.mdl", "6900 3507 410", "170 107 -142", "shadow_no" );
make_prop( "dynamic", "_losblocker_hardlyimpossible", "models/props_wasteland/rock_moss04.mdl", "6344 3782 270", "130 107 -62", "shadow_no" );
make_prop( "dynamic", "_losblocker_treefloater", "models/props_wasteland/rock_moss04.mdl", "5732 3800 227", "90 -71 90", "shadow_no" );
make_prop( "dynamic", "_pouncersonly_wrongwaya", "models/props_misc/wrongway_sign01_optimized.mdl", "11153 4780 259", "0 180 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_pouncersonly_wrongwayb", "models/props_misc/wrongway_sign01_optimized.mdl", "11153 4630 259", "0 180 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_pouncersonly_wrongwayc", "models/props_misc/wrongway_sign01_optimized.mdl", "11361 4164 310", "0 -90 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_solidify_treesripbro", "models/props_foliage/trees_cluster02.mdl", "5777.93 3757.84 265.545", "0 84.5 0", "shadow_no" );
make_prop( "dynamic", "_wrongway_propa", "models/props_placeable/wrong_way.mdl", "4930 3935 540", "0 90 90", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_wrongway_propb", "models/props_placeable/wrong_way.mdl", "5980 3935 280", "0 90 90", "shadow_no", "solid_no", "255 255 255", "17", "217" );
make_prop( "dynamic", "_wrongway_propc", "models/props_placeable/wrong_way.mdl", "6750 4020 465", "0 106 90", "shadow_no", "solid_no", "255 255 255", "17", "217" );

con_comment( "KILL:\tReplaced \"fenceSmash_clip_brush\" with Survivor-only version." );

EntFire( "fenceSmash_clip_brush", "Kill" );

con_comment( "LOGIC:\tBarricade ladders will be deleted 17 seconds into \"relay_outro_start\"." );

EntFire( "relay_outro_start", "AddOutput", "OnTrigger anv_mapfixes_ladder_barricade*:Kill::17:-1" );

con_comment( "EASTER_EGG:\tChair deleted, replaced with bumper car, SetModel to chair, clipped, parented and OnHitByTank I/O'd." );

kill_entity( Entities.FindByClassnameNearest( "prop_physics", Vector( 6929.47, 1058.91, 238.375 ), 8 ) );
make_prop( "physics", "_replacement_chair", "models/props_fairgrounds/bumpercar.mdl", "6929.47 1058.91 238.375", "360 180 0", "shadow_yes", "solid_yes", "255 255 255", -1, 0, 1.3 );
Entities.FindByName( null, g_UpdateName + "_replacement_chair" ).SetModel( "models/props_interiors/sofa_chair02.mdl" );
make_clip( "_replacement_chair_clip", "Everyone", 1, "-16 -22 0", "30 22 40", "6922 1059 238" );
EntFire( g_UpdateName + "_replacement_chair_clip", "SetParent", g_UpdateName + "_replacement_chair" );
EntFire( g_UpdateName + "_replacement_chair", "AddOutput", "OnHitByTank anv_mapfixes_replacement_chair_clip:Kill:0:-1" );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*==============================
||                            ||
||        COLD STREAM         ||
||                            ||
==============================*/

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c13m1_alpinecreek":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

make_ladder( "_ladder_crossoverbackB_cloned_mrlogsuperwide", "954 1027.5 474.3475", "-2055 3751 -274", "0 -90 0", "1 0 0" );
make_ladder( "_ladder_crossoverbackT_cloned_mrlogsuperwide", "954 1027.5 474.3475", "-2165 3751 -100", "0 -90 0", "1 0 0" );
make_ladder( "_ladder_crossoverfrontB_cloned_mrlogsuperwide", "954 1027.5 474.3475", "-479 1690 -313", "0 90 0", "-1 0 0" );
make_ladder( "_ladder_crossoverfrontT_cloned_mrlogsuperwide", "954 1027.5 474.3475", "-330 1690 17", "0 90 -8", "-1 0 0" );
make_ladder( "_ladder_crossoverupway_cloned_bunkerdoor", "1064 223 652", "-2326 2962 -84" );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c13m2_southpinestream":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

make_brush( "_losfix_gastruck1",	"-45 -1 -18",	"45 1 18",	"4992 2301 617" );
make_brush( "_losfix_gastruck2",	"-1 -40 -18",	"1 40 18",	"4082 2256 524" );
make_ladder( "_ladder_eventphysfence_cloned_endfencefront", "-1401.11 5244.2798 344", "1045 469 9" );
make_ladder( "_ladder_posttanksecret_cloned_cliffstraightwide", "6914.6465 2713.7744 601", "14585 5833 1212", "10 -176.74 0", "-0.69 0.72 0" );
make_ladder( "_ladder_pretankleft_cloned_cliffstraightwide", "6914.6465 2713.7744 601", "15420 1150 17", "0 141.65 0", "0 1 0" );
make_ladder( "_ladder_pretankright_cloned_cliffstraightwide", "6914.6465 2713.7744 601", "5680 -3340 1200", "10 52.84 0", "1 0.1 0" );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c13m3_memorialbridge":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

make_brush( "_losfix_bus",		"-1 -204 -8",	"1 204 8",	"1782 -4004 1335" );
make_brush( "_losfix_gastruck",		"-36 -1 -12",	"36 1 12",	"-2933 -3970 1340" );
make_ladder( "_ladder_endbrick_cloned_shortbase", "830 -3760 192", "9493 -5323 188", "0 -90 0", "0 1 0" );
make_ladder( "_ladder_shrubwall1_cloned_shortbase", "830 -3760 192", "-5443 -1047 601" );
make_ladder( "_ladder_shrubwall2_cloned_shortbase", "830 -3760 192", "-5373 -542 614" );
make_ladder( "_ladder_sosemerge_cloned_shortbase", "830 -3760 192", "-4989 -1291 352" );
make_ladder( "_ladder_supertallstart_cloned_samespot", "-3391 -4804 975", "0 305 0" );
make_prop( "dynamic",		"_losblocker_acvent",		"models/props_rooftop/acvent04.mdl",		"6027 -6087 542",		"0 90 0",		"shadow_no" );
make_prop( "dynamic",		"_propladder_bricka",		"models/props_industrial/brickpallets.mdl",	"5797.57 -6183.4 412.857",	"0 0 0",		"shadow_no" );
make_prop( "dynamic",		"_propladder_brickb",		"models/props_industrial/brickpallets.mdl",	"5733 -6184 412.857",		"0 0 0",		"shadow_no" );
make_prop( "dynamic",		"_propladder_brickc",		"models/props_industrial/brickpallets.mdl",	"5797.48 -6183.82 476.857",	"0 180 0",		"shadow_no" );
make_prop( "dynamic",		"_propladder_brickd",		"models/props_industrial/brickpallets.mdl",	"5796.57 -6248.4 445.857",	"0 0 0",		"shadow_no" );
make_prop( "dynamic",		"_propladder_bricke",		"models/props_industrial/brickpallets.mdl",	"5797.48 -6248.82 412.857",	"0 180 0",		"shadow_no" );
make_prop( "dynamic",		"_propladder_brickf",		"models/props_industrial/brickpallets.mdl",	"5732.91 -6249.42 412.857",	"0 180 0",		"shadow_no" );
make_prop( "dynamic",		"_propladder_brickg",		"models/props_industrial/brickpallets.mdl",	"5754 -6439 396.857",		"0 180 0",		"shadow_no" );
patch_ladder( "-410.09 -4121.79 1386", "15 15 10" );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c13m4_cutthroatcreek":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

kill_entity( Entities.FindByClassnameNearest( "prop_physics", Vector( -521.5, -1260.25, -399.53125 ), 8 ) );
make_clip(	"_ladder_startstreamL_clip",	"SI Players",	1,	"0 -30 -8",	"120 60 8",	"-4028 -5137 345", "0 90 31" );
make_clip(	"_ladder_littlecliff_qola",	"SI Players",	1,	"-60 0 -8",	"40 50 8",	"-3685 -1397 312", "0 20 45" );
make_clip(	"_ladder_littlecliff_qolb",	"SI Players",	1,	"-60 -24 -8",	"44 20 12",	"-3706 -1352 366", "0 20 45" );
make_brush( "_losfix_gen1",		"-1 -24 -8",	"1 24 8",	"-821 5675.32 -110" );
make_brush( "_losfix_gen2",		"-24 -1 -8",	"24 1 8",	"-838 4598 -110" );
make_ladder( "_ladder_cornerlowroofl_cloned_endbackarea", "-1 5304 -43.124", "-1245 660 107" );
make_ladder( "_ladder_cornerlowroofr_cloned_endbackarea", "-1 5304 -43.124", "-1245 692 107" );
make_ladder( "_ladder_enddumpsterL_cloned_endstackback", "-38 5888 -55.124", "-6748 5750 -30", "0 -90 0", "0 -1 0" );
make_ladder( "_ladder_enddumpsterR_cloned_endstackback", "-38 5888 -55.124", "-6469 5752 -30", "0 -90 0", "0 -1 0" );
make_ladder( "_ladder_endstackfront_cloned_endstackback", "-38 5888 -55.124", "-1302 11213 -4", "0 -168 0", "-0.98 -0.2 0" );
make_ladder( "_ladder_endwarehouseR_cloned_endwarehouseL", "178 4845.5 -18.624", "0 -685 0" );
make_ladder( "_ladder_fourthstream_cloned_secondstream", "-4184 -3448.5 244", "-27 1450 -100" );
make_ladder( "_ladder_littlecliff_cloned_waterfall", "-2164 -1760 -112", "-573 -1861 460", "-6 -48.11 0", "0.67 -0.74 0" );
make_ladder( "_ladder_thirdstream_cloned_secondstream", "-4184 -3448.5 244", "-8270 -4977 -88", "0 168 0", "-0.98 0.2 0" );
make_ladder( "_ladder_stairsfence_cloned_backfence", "-898 1668.5 -49.1", "684 730 0" );
make_ladder( "_ladder_startstreamL_cloned_startstreamR", "-3559.5 -4536.5 185", "-7540 -9590 8", "0 180 0", "1 0 0" );
make_navblock( "_losblocker_startshrubnavblock", "Everyone", "Apply", "-64 -64 -64", "64 64 64", "-3400 -7300 360" );
make_prop( "dynamic",		"_losblocker_startshrubwall",	"models/props_foliage/swamp_shrubwall_block_256_deep.mdl",	"-3388 -7294 335",		"0 231 0",		"shadow_no" );
make_prop( "dynamic", "_solidify_startcluster1", "models/props_foliage/urban_trees_cluster01.mdl", "-3130 -6492 366.443", "0 0 0", "shadow_no" );
make_prop( "dynamic", "_solidify_startcluster2", "models/props_foliage/urban_trees_cluster01.mdl", "-3168 -5984 317.023", "0 0 0", "shadow_no" );
make_prop( "physics", "_hittable_replacement", "models/props_foliage/tree_trunk_fallen.mdl", "-714 -863 -385", "0 100 0", "shadow_yes", "solid_yes", "255 255 255", -1, 0, 1.5 );
patch_ladder( "-1 5304 -43.124", "50 0 0" );
patch_ladder( "-202.0005 -1483.2271 -224", "0 0 10" );
patch_ladder( "145 4845.5 202", "-15 0 0" );
patch_ladder( "159 4845.5 159", "-15 0 0" );
patch_ladder( "178 4845.5 109.5", "-17 0 0" );
patch_ladder( "195 4845.5 -18.624", "-17 0 0" );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*==============================
||                            ||
||         LAST STAND         ||
||                            ||
==============================*/

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c14m1_junkyard":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c14m2_lighthouse":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*==============================
||                            ||
||         DEVELOPER          ||
||                            ||
==============================*/

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "c5m1_waterfront_sndscape":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "credits":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "curling_stadium":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "tutorial_standards":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	case "tutorial_standards_vs":
	{
		// ENTITIES FOR HUMAN-CONTROLLED SI MODES ONLY

EntFire( "worldspawn", "RunScriptFile", "anv_standards" );

		break;
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*==============================
||                            ||
||         COMMUNITY          ||
||                            ||
==============================*/

	// Do nothing.

	default:
	{
		return;
	}
}
