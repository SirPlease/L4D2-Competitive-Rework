#if defined _l4d_stats_plugin_start_included
	#endinput
#endif
#define _l4d_stats_plugin_start_included

// 插件启动、ConVar 创建、事件注册和配置加载入口。

// Here we go!
public OnPluginStart()
{
	CommandsRegistered = false;
	// Require Left 4 Dead (2)
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));

	if (!StrEqual(game_name, "left4dead", false) &&
			!StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("Plugin supports Left 4 Dead and Left 4 Dead 2 only.");
		return;
	}
	
	EngineVersion1 = GetEngineVersion();

	if (EngineVersion1 == Engine_Left4Dead)
	{
		strcopy(StatsSound_MapTime_Start, sizeof(StatsSound_MapTime_Start), SOUND_MAPTIME_START_L4D1);
		strcopy(StatsSound_MapTime_Improve, sizeof(StatsSound_MapTime_Improve), SOUND_MAPTIME_IMPROVE_L4D1);
		strcopy(StatsSound_Rankmenu_Show, sizeof(StatsSound_Rankmenu_Show), SOUND_RANKMENU_SHOW_L4D1);
		strcopy(StatsSound_Boomer_Vomit, sizeof(StatsSound_Boomer_Vomit), SOUND_BOOMER_VOMIT_L4D1);
		strcopy(StatsSound_Hunter_Perfect, sizeof(StatsSound_Hunter_Perfect), SOUND_HUNTER_PERFECT_L4D1);
		strcopy(StatsSound_Tank_Bulldozer, sizeof(StatsSound_Tank_Bulldozer), SOUND_TANK_BULLDOZER_L4D1);
	}
	else
	{
		strcopy(StatsSound_MapTime_Start, sizeof(StatsSound_MapTime_Start), SOUND_MAPTIME_START_L4D2);
		strcopy(StatsSound_MapTime_Improve, sizeof(StatsSound_MapTime_Improve), SOUND_MAPTIME_IMPROVE_L4D2);
		strcopy(StatsSound_Rankmenu_Show, sizeof(StatsSound_Rankmenu_Show), SOUND_RANKMENU_SHOW_L4D2);
		strcopy(StatsSound_Boomer_Vomit, sizeof(StatsSound_Boomer_Vomit), SOUND_BOOMER_VOMIT_L4D2);
		strcopy(StatsSound_Hunter_Perfect, sizeof(StatsSound_Hunter_Perfect), SOUND_HUNTER_PERFECT_L4D2);
		strcopy(StatsSound_Tank_Bulldozer, sizeof(StatsSound_Tank_Bulldozer), SOUND_TANK_BULLDOZER_L4D2);
	}

	// Plugin version public Cvar
	CreateConVar("l4d_stats_version", PLUGIN_VERSION, "Custom Player Stats Version", 0|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	// Disable setting Cvars
	cvar_Difficulty = FindConVar("z_difficulty");
	cvar_Gamemode = FindConVar("mp_gamemode");
	cvar_Cheats = FindConVar("sv_cheats");
	if(FindConVar("l4d_ready_cfg_name"))
		cvar_mode = FindConVar("l4d_ready_cfg_name");
	cvar_Lan = FindConVar("sv_lan");
	if (GetConVarInt(cvar_Lan))
		LogMessage("ATTENTION! %s in LAN environment is based on IP address rather than Steam ID. The statistics are not reliable when they are base on IP!", PLUGIN_NAME);

	HookConVarChange(cvar_Lan, action_LanChanged);

	cvar_SurvivorLimit = FindConVar("survivor_limit");
	cvar_InfectedLimit = FindConVar("z_max_player_zombies");

	// Administrative Cvars
	cvar_AdminPlayerCleanLastOnTime = CreateConVar("l4d_stats_adm_cleanoldplayers", "0", "How many months old players (last online time) will be cleaned. 0 = Disabled", 0, true, 0.0);
	cvar_AdminPlayerCleanPlatime = CreateConVar("l4d_stats_adm_cleanplaytime", "10", "How many minutes of playtime to not get cleaned from stats. 0 = Disabled", 0, true, 0.0);

	// Config/control Cvars
	cvar_EnableRankVote = CreateConVar("l4d_stats_enablerankvote", "1", "Enable voting of team shuffle by player PPM (Points Per Minute)", 0, true, 0.0, true, 1.0);
	cvar_HumansNeeded = CreateConVar("l4d_stats_minhumans", "1", "Minimum Human players before stats will be enabled", 0, true, 1.0, true, 4.0);
	cvar_UpdateRate = CreateConVar("l4d_stats_updaterate", "90", "Number of seconds between Common Infected point earn announcement/update", 0, true, 30.0);
	//cvar_AnnounceRankMinChange = CreateConVar("l4d_stats_announcerankminpoint", "500", "Minimum change to points before rank change announcement", 0, true, 0.0);
	cvar_AnnounceRankChange = CreateConVar("l4d_stats_announcerank", "1", "Chat announcment for rank change", 0, true, 0.0, true, 1.0);
	cvar_AnnounceRankChangeIVal = CreateConVar("l4d_stats_announcerankinterval", "60", "Rank change check interval", 0, true, 10.0);
	cvar_AnnouncePlayerJoined = CreateConVar("l4d_stats_announceplayerjoined", "1", "Chat announcment for player joined.", 0, true, 0.0, true, 1.0);
	cvar_AnnounceMotd = CreateConVar("l4d_stats_announcemotd", "1", "Chat announcment for the message of the day.", 0, true, 0.0, true, 1.0);
	cvar_AnnounceMode = CreateConVar("l4d_stats_announcemode", "1", "Chat announcment mode. 0 = Off, 1 = Player Only, 2 = Player Only w/ Public Headshots, 3 = All Public", 0, true, 0.0, true, 3.0);
	cvar_AnnounceToTeam = CreateConVar("l4d_stats_announceteam", "2", "Chat announcment team messages to the team only mode. 0 = Print messages to all teams, 1 = Print messages to own team only, 2 = Print messages to own team and spectators only", 0, true, 0.0, true, 2.0);
	//cvar_AnnounceSpecial = CreateConVar("l4d_stats_announcespecial", "1", "Chat announcment mode for special events. 0 = Off, 1 = Player Only, 2 = Print messages to all teams, 3 = Print messages to own team only, 4 = Print messages to own team and spectators only", 0, true, 0.0, true, 4.0);
	cvar_MedkitMode = CreateConVar("l4d_stats_medkitmode", "0", "Medkit point award mode. 0 = Based on amount healed, 1 = Static amount", 0, true, 0.0, true, 1.0);
	cvar_SiteURL = CreateConVar("l4d_stats_siteurl", "https://sb.trygek.com/l4d_stats/", "Community site URL, for rank panel display", 0);
	cvar_RankOnJoin = CreateConVar("l4d_stats_rankonjoin", "0", "Display player's rank when they connect. 0 = Disable, 1 = Enable", 0, true, 0.0, true, 1.0);
	cvar_SilenceChat = CreateConVar("l4d_stats_silencechat", "0", "Silence chat triggers. 0 = Show chat triggers, 1 = Silence chat triggers", 0, true, 0.0, true, 1.0);
	cvar_DisabledMessages = CreateConVar("l4d_stats_disabledmessages", "1", "Show 'Stats Disabled' messages, allow chat commands to work when stats disabled. 0 = Hide messages/disable chat, 1 = Show messages/allow chat", 0, true, 0.0, true, 1.0);
	//cvar_MaxPoints = CreateConVar("l4d_stats_maxpoints", "500", "Maximum number of points that can be earned in a single map. Normal = x1, Adv = x2, Expert = x3", 0, true, 500.0);
	cvar_DbPrefix = CreateConVar("l4d_stats_dbprefix", "", "Prefix for your stats tables", 0);
	//cvar_LeaderboardTime = CreateConVar("l4d_stats_leaderboardtime", "14", "Time in days to show Survival Leaderboard times", 0, true, 1.0);
	cvar_EnableNegativeScore = CreateConVar("l4d_stats_enablenegativescore", "1", "Enable point losses (negative score)", 0, true, 0.0, true, 1.0);
	cvar_FriendlyFireMode = CreateConVar("l4d_stats_ffire_mode", "2", "Friendly fire mode. 0 = Normal, 1 = Cooldown, 2 = Damage based", 0, true, 0.0, true, 2.0);
	cvar_FriendlyFireMultiplier = CreateConVar("l4d_stats_ffire_multiplier", "1.5", "Friendly fire damage multiplier (Formula: Score = Damage * Multiplier)", 0, true, 0.0);
	cvar_FriendlyFireCooldown = CreateConVar("l4d_stats_ffire_cooldown", "10.0", "Time in seconds for friendly fire cooldown", 0, true, 1.0);
	cvar_FriendlyFireCooldownMode = CreateConVar("l4d_stats_ffire_cooldownmode", "1", "Friendly fire cooldown mode. 0 = Disable, 1 = Player specific, 2 = General", 0, true, 0.0, true, 2.0);

	// Game mode Cvars
	cvar_Enable = CreateConVar("l4d_stats_enable", "1", "Enable/Disable all stat tracking", 0, true, 0.0, true, 1.0);
	cvar_EnableCoop = CreateConVar("l4d_stats_enablecoop", "1", "Enable/Disable coop stat tracking", 0, true, 0.0, true, 1.0);
	cvar_EnableSv = CreateConVar("l4d_stats_enablesv", "1", "Enable/Disable survival stat tracking", 0, true, 0.0, true, 1.0);
	cvar_EnableVersus = CreateConVar("l4d_stats_enableversus", "1", "Enable/Disable versus stat tracking", 0, true, 0.0, true, 1.0);
	cvar_EnableTeamVersus = CreateConVar("l4d_stats_enableteamversus", "1", "[L4D2] Enable/Disable team versus stat tracking", 0, true, 0.0, true, 1.0);
	cvar_EnableRealism = CreateConVar("l4d_stats_enablerealism", "1", "[L4D2] Enable/Disable realism stat tracking", 0, true, 0.0, true, 1.0);
	cvar_EnableScavenge = CreateConVar("l4d_stats_enablescavenge", "1", "[L4D2] Enable/Disable scavenge stat tracking", 0, true, 0.0, true, 1.0);
	cvar_EnableTeamScavenge = CreateConVar("l4d_stats_enableteamscavenge", "1", "[L4D2] Enable/Disable team scavenge stat tracking", 0, true, 0.0, true, 1.0);
	cvar_EnableRealismVersus = CreateConVar("l4d_stats_enablerealismvs", "1", "[L4D2] Enable/Disable realism versus stat tracking", 0, true, 0.0, true, 1.0);
	cvar_EnableTeamRealismVersus = CreateConVar("l4d_stats_enableteamrealismvs", "1", "[L4D2] Enable/Disable team realism versus stat tracking", 0, true, 0.0, true, 1.0);
	cvar_EnableMutations = CreateConVar("l4d_stats_enablemutations", "1", "[L4D2] Enable/Disable mutations stat tracking", 0, true, 0.0, true, 1.0);

	// Game mode depended Cvars
	cvar_RealismMultiplier = CreateConVar("l4d_stats_realismmultiplier", "1", "[L4D2] Realism score multiplier for coop score", 0, true, 1.0);
	cvar_RealismVersusSurMultiplier = CreateConVar("l4d_stats_realismvsmultiplier_s", "1", "[L4D2] Realism score multiplier for survivors versus score", 0, true, 1.0);
	cvar_RealismVersusInfMultiplier = CreateConVar("l4d_stats_realismvsmultiplier_i", "1", "[L4D2] Realism score multiplier for infected versus score", 0, true, 0.0, true, 1.0);
	cvar_EnableSvMedicPoints = CreateConVar("l4d_stats_medicpointssv", "1", "Survival medic points enabled", 0, true, 0.0, true, 1.0);

	// Infected point Cvars
	cvar_Infected = CreateConVar("l4d_stats_infected", "1", "Base score for killing a Common Infected", 0, true, 1.0);
	cvar_Hunter = CreateConVar("l4d_stats_hunter", "3", "Base score for killing a Hunter", 0, true, 1.0);
	cvar_Smoker = CreateConVar("l4d_stats_smoker", "3", "Base score for killing a Smoker", 0, true, 1.0);
	cvar_Boomer = CreateConVar("l4d_stats_boomer", "2", "Base score for killing a Boomer", 0, true, 1.0);
	cvar_Spitter = CreateConVar("l4d_stats_spitter", "3", "[L4D2] Base score for killing a Spitter", 0, true, 1.0);
	cvar_Jockey = CreateConVar("l4d_stats_jockey", "4", "[L4D2] Base score for killing a Jockey", 0, true, 1.0);
	cvar_Charger = CreateConVar("l4d_stats_charger", "5", "[L4D2] Base score for killing a Charger", 0, true, 1.0);
	cvar_InfectedDamage = CreateConVar("l4d_stats_infected_damage", "1", "The amount of damage inflicted to Survivors to earn 1 point", 0, true, 1.0);

	// Misc personal gain Cvars
	cvar_Pills = CreateConVar("l4d_stats_pills", "15", "Base score for giving Pills to a friendly", 0, true, 1.0);
	cvar_Adrenaline = CreateConVar("l4d_stats_adrenaline", "15", "[L4D2] Base score for giving Adrenaline to a friendly", 0, true, 1.0);
	cvar_Medkit = CreateConVar("l4d_stats_medkit", "20", "Base score for using a Medkit on a friendly", 0, true, 1.0);
	cvar_Defib = CreateConVar("l4d_stats_defib", "20", "[L4D2] Base score for using a Defibrillator on a friendly", 0, true, 1.0);
	cvar_SmokerDrag = CreateConVar("l4d_stats_smokerdrag", "2", "Base score for saving a friendly from a Smoker Tongue Drag", 0, true, 1.0);
	cvar_JockeyRide = CreateConVar("l4d_stats_jockeyride", "2", "[L4D2] Base score for saving a friendly from a Jockey Ride", 0, true, 1.0);
	cvar_ChargerPlummel = CreateConVar("l4d_stats_chargerplummel", "5", "[L4D2] Base score for saving a friendly from a Charger Plummel", 0, true, 1.0);
	cvar_ChargerCarry = CreateConVar("l4d_stats_chargercarry", "15", "[L4D2] Base score for saving a friendly from a Charger Carry", 0, true, 1.0);
	cvar_ChokePounce = CreateConVar("l4d_stats_chokepounce", "2", "Base score for saving a friendly from a Hunter Pounce / Smoker Choke", 0, true, 1.0);
	cvar_Revive = CreateConVar("l4d_stats_revive", "10", "Base score for Revive a friendly from Incapacitated state", 0, true, 1.0);
	cvar_Rescue = CreateConVar("l4d_stats_rescue", "10", "Base score for Rescue a friendly from a closet", 0, true, 1.0);
	cvar_Protect = CreateConVar("l4d_stats_protect", "2", "Base score for Protect a friendly in combat", 0, true, 1.0);
	cvar_PlayerLedgeSuccess = CreateConVar("l4d_stats_ledgegrap", "20", "Base score for causing a survivor to grap a ledge", 0, true, 1.0);
	cvar_Matador = CreateConVar("l4d_stats_matador", "20", "[L4D2] Base score for killing a charging Charger with a melee weapon", 0, true, 1.0);
	cvar_WitchCrowned = CreateConVar("l4d_stats_witchcrowned", "30", "Base score for Crowning a Witch", 0, true, 1.0);

	// Team gain Cvars
	cvar_Tank = CreateConVar("l4d_stats_tank", "40", "Base team score for killing a Tank", 0, true, 1.0);
	cvar_Panic = CreateConVar("l4d_stats_panic", "5", "Base team score for surviving a Panic Event with no Incapacitations", 0, true, 1.0);
	cvar_BoomerMob = CreateConVar("l4d_stats_boomermob", "3", "Base team score for surviving a Boomer Mob with no Incapacitations", 0, true, 1.0);
	cvar_SafeHouse = CreateConVar("l4d_stats_safehouse", "50", "Base score for reaching a Safe House", 0, true, 1.0);
	cvar_Witch = CreateConVar("l4d_stats_witch", "5", "Base score for Not Disturbing a Witch", 0, true, 1.0);
	cvar_VictorySurvivors = CreateConVar("l4d_stats_campaign", "45", "Base score for Completing a Campaign", 0, true, 1.0);
	cvar_VictoryInfected = CreateConVar("l4d_stats_infected_win", "35", "Base victory score for Infected Team", 0, true, 1.0);

	// Point loss Cvars
	cvar_FFire = CreateConVar("l4d_stats_ffire", "25", "Base score for Friendly Fire", 0, true, 1.0);
	cvar_FIncap = CreateConVar("l4d_stats_fincap", "75", "Base score for a Friendly Incap", 0, true, 1.0);
	cvar_FKill = CreateConVar("l4d_stats_fkill", "250", "Base score for a Friendly Kill", 0, true, 1.0);
	cvar_InSafeRoom = CreateConVar("l4d_stats_insaferoom", "5", "Base score for letting Infected in the Safe Room", 0, true, 1.0);
	cvar_Restart = CreateConVar("l4d_stats_restart", "200", "Base score for a Round Restart", 0, true, 1.0);
	cvar_MedkitUsedPointPenalty = CreateConVar("l4d_stats_medkitpenalty", "0.1", "Score reduction for all Survivor earned points for each used Medkit (Formula: Score = NormalPoints * (1 - MedkitsUsed * MedkitPenalty))", 0, true, 0.0, true, 0.5);
	cvar_MedkitUsedPointPenaltyMax = CreateConVar("l4d_stats_medkitpenaltymax", "0.6", "Maximum score reduction (the score reduction will not go over this value when a Medkit is used)", 0, true, 0.0, true, 1.0);
	cvar_MedkitUsedFree = CreateConVar("l4d_stats_medkitpenaltyfree", "0", "Team Survivors can use this many Medkits for free without any reduction to the score", 0, true, 0.0);
	cvar_MedkitUsedRealismFree = CreateConVar("l4d_stats_medkitpenaltyfree_r", "4", "Team Survivors can use this many Medkits for free without any reduction to the score when playing in Realism gamemodes (-1 = use the value in l4d_stats_medkitpenaltyfree)", 0, true, -1.0);
	cvar_MedkitBotMode = CreateConVar("l4d_stats_medkitbotmode", "1", "Add score reduction when bot uses a medkit. 0 = No, 1 = Bot uses a Medkit to a human player, 2 = Bot uses a Medkit to other than itself, 3 = Yes", 0, true, 0.0, true, 2.0);
	cvar_CarAlarm = CreateConVar("l4d_stats_caralarm", "50", "[L4D2] Base score for a Triggering Car Alarm", 0, true, 1.0);
	cvar_BotScoreMultiplier = CreateConVar("l4d_stats_botscoremultiplier", "1.0", "Multiplier to use when receiving bot related score penalty. 0 = Disable", 0, true, 0.0);

	// Survivor point Cvars
	cvar_SurvivorDeath = CreateConVar("l4d_stats_survivor_death", "50", "Base score for killing a Survivor", 0, true, 1.0);
	cvar_SurvivorIncap = CreateConVar("l4d_stats_survivor_incap", "25", "Base score for incapacitating a Survivor", 0, true, 1.0);

	// Hunter point Cvars
	cvar_HunterPerfectPounceDamage = CreateConVar("l4d_stats_perfectpouncedamage", "25", "The amount of damage from a pounce to earn Perfect Pounce (Death From Above) success points", 0, true, 1.0);
	cvar_HunterPerfectPounceSuccess = CreateConVar("l4d_stats_perfectpouncesuccess", "25", "Base score for a successful Perfect Pounce", 0, true, 1.0);
	cvar_HunterNicePounceDamage = CreateConVar("l4d_stats_nicepouncedamage", "15", "The amount of damage from a pounce to earn Nice Pounce (Pain From Above) success points", 0, true, 1.0);
	cvar_HunterNicePounceSuccess = CreateConVar("l4d_stats_nicepouncesuccess", "10", "Base score for a successful Nice Pounce", 0, true, 1.0);
	cvar_HunterDamageCap = CreateConVar("l4d_stats_hunterdamagecap", "25", "Hunter stored damage cap", 0, true, 25.0);

	if (EngineVersion1 == Engine_Left4Dead)
	{
		MaxPounceDistance = GetConVarInt(FindConVar("z_pounce_damage_range_max"));
		MinPounceDistance = GetConVarInt(FindConVar("z_pounce_damage_range_min"));
	}
	else
	{
		MaxPounceDistance = 1024;
		MinPounceDistance = 300;
	}
	MaxPounceDamage = GetConVarInt(FindConVar("z_hunter_max_pounce_bonus_damage"));

	// Boomer point Cvars
	cvar_BoomerSuccess = CreateConVar("l4d_stats_boomersuccess", "5", "Base score for a successfully vomiting on survivor", 0, true, 1.0);
	cvar_BoomerPerfectHits = CreateConVar("l4d_stats_boomerperfecthits", "4", "The number of survivors that needs to get blinded to earn Boomer Perfect Vomit Award and success points", 0, true, 4.0);
	cvar_BoomerPerfectSuccess = CreateConVar("l4d_stats_boomerperfectsuccess", "30", "Base score for a successful Boomer Perfect Vomit", 0, true, 1.0);

	// Tank point Cvars
	cvar_TankDamageCap = CreateConVar("l4d_stats_tankdmgcap", "800", "Maximum inflicted damage done by Tank to earn Infected damagepoints", 0, true, 150.0);
	cvar_TankDamageTotal = CreateConVar("l4d_stats_bulldozer", "500", "Damage inflicted by Tank to earn Bulldozer Award and success points", 0, true, 200.0);
	cvar_TankDamageTotalSuccess = CreateConVar("l4d_stats_bulldozersuccess", "50", "Base score for Bulldozer Award", 0, true, 1.0);
	cvar_TankThrowRockSuccess = CreateConVar("l4d_stats_tankthrowrocksuccess", "5", "Base score for a Tank thrown rock hit", 0, true, 0.0);

	// Charger point Cvars
	cvar_ChargerRamSuccess = CreateConVar("l4d_stats_chargerramsuccess", "40", "Base score for a successful Charger Scattering Ram", 0, true, 1.0);
	cvar_ChargerRamHits = CreateConVar("l4d_stats_chargerramhits", "4", "The number of impacts on survivors to earn Scattering Ram Award and success points", 0, true, 2.0);

	// Misc L4D2 Cvars
	cvar_AmmoUpgradeAdded = CreateConVar("l4d_stats_deployammoupgrade", "10", "[L4D2] Base score for deploying ammo upgrade pack", 0, true, 0.0);
	cvar_GascanPoured = CreateConVar("l4d_stats_gascanpoured", "5", "[L4D2] Base score for successfully pouring a gascan", 0, true, 0.0);

	// Other Cvars
	cvar_Top10PPMMin = CreateConVar("l4d_stats_top10ppmplaytime", "30", "Minimum playtime (minutes) to show in top10 ppm list", 0, true, 1.0);
	cvar_RankVoteTime = CreateConVar("l4d_stats_rankvotetime", "20", "Time to wait people to vote", 0, true, 10.0);

	cvar_SoundsEnabled = CreateConVar("l4d_stats_soundsenabled", "1", "Play sounds on certain events", 0, true, 0.0, true, 1.0);
	NewPlayerBonus_CreateCvars();
	NoBuyBonus_CreateCvars();
	ScoreLog_CreateCvars();
	QuarterRank_CreateCvars();

	// Make that config!
	//AutoExecConfig(true, "l4d_stats");

	// Personal Gain Events
	HookEvent("round_end",	Event_RoundEnd);
	HookEvent("player_death", event_PlayerDeath);
	HookEvent("infected_death", event_InfectedDeath);
	HookEvent("tank_killed", event_TankKilled);
	if (EngineVersion1 == Engine_Left4Dead)
	{
		HookEvent("weapon_given", event_GivePills);
	}
	else
	{
		HookEvent("defibrillator_used", event_DefibPlayer);
	}
	HookEvent("item_pickup", event_ItemPickup);
	HookEvent("heal_begin", event_HealBegin);
	HookEvent("heal_success", event_HealPlayer);
	HookEvent("revive_success", event_RevivePlayer);
	HookEvent("tongue_pull_stopped", event_TongueSave);
	HookEvent("choke_stopped", event_ChokeSave);
	HookEvent("pounce_stopped", event_PounceSave);
	HookEvent("lunge_pounce", event_PlayerPounced);
	HookEvent("player_ledge_grab", event_PlayerLedge);
	HookEvent("player_falldamage", event_PlayerFallDamage);
	HookEvent("melee_kill", event_MeleeKill);

	// Personal Loss Events
	HookEvent("friendly_fire", event_FriendlyFire);
	HookEvent("player_incapacitated", event_PlayerIncap);

	// Team Gain Events
	HookEvent("finale_vehicle_leaving", event_CampaignWin);
	HookEvent("map_transition", event_MapTransitionPre, EventHookMode_Pre);
	HookEvent("map_transition", event_MapTransition);
	//HookEvent("create_panic_event", event_PanicEvent);
	HookEvent("player_now_it", event_PlayerBlind);
	//HookEvent("player_no_longer_it", event_PlayerBlindEnd);
	HookEvent("award_earned", event_Award_L4D2);
	HookEvent("witch_spawn", event_WitchSpawn);
	HookEvent("witch_killed", event_WitchCrowned);
	HookEvent("witch_harasser_set", event_WitchDisturb);
	HookEvent("round_start", event_RoundStart);
	// Record player positions when an ability is used
	HookEvent("ability_use", event_AbilityUse);
	// Set player specific counters (BoomerHitCounter etc)
	HookEvent("player_spawn", event_PlayerSpawn);

	// Set player specific counters (BoomerHitCounter etc)
	HookEvent("player_hurt", event_PlayerHurt);

	// Smoker stats
	HookEvent("tongue_grab", event_SmokerGrap);
	HookEvent("tongue_release", event_SmokerRelease);
	if (EngineVersion1 == Engine_Left4Dead)
	{
		HookEvent("tongue_broke_victim_died", event_SmokerRelease);
	}
	HookEvent("choke_end", event_SmokerRelease);
	HookEvent("tongue_broke_bent", event_SmokerRelease);
	// Hooked previously ^
	//HookEvent("choke_stopped", event_SmokerRelease);
	//HookEvent("tongue_pull_stopped", event_SmokerRelease);

	// Hunter stats
	HookEvent("pounce_end", event_HunterRelease);

	if (EngineVersion1 != Engine_Left4Dead)
	{
		// Spitter stats
		//HookEvent("spitter_killed", event_SpitterKilled);

		// Jockey stats
		HookEvent("jockey_ride", event_JockeyStart);
		HookEvent("jockey_ride_end", event_JockeyRelease);
		HookEvent("jockey_killed", event_JockeyKilled);

		// Charger stats
		HookEvent("charger_impact", event_ChargerImpact);
		HookEvent("charger_killed", event_ChargerKilled);
		HookEvent("charger_carry_start", event_ChargerCarryStart);
		HookEvent("charger_carry_end", event_ChargerCarryRelease);
		HookEvent("charger_pummel_start", event_ChargerPummelStart);
		HookEvent("charger_pummel_end", event_ChargerPummelRelease);

		// Misc L4D2 events
		HookEvent("upgrade_pack_used", event_UpgradePackAdded);
		HookEvent("gascan_pour_completed", event_GascanPoured);
		HookEvent("triggered_car_alarm", event_CarAlarm);
		HookEvent("survival_round_start", event_SurvivalStart); // Timed Maps event
		HookEvent("scavenge_round_halftime", event_ScavengeHalftime);
		HookEvent("scavenge_round_start", event_ScavengeRoundStart);
	}

	// Achievements
	HookEvent("achievement_earned", event_Achievement);

	// Timed Maps events
	HookEvent("door_open", event_DoorOpen, EventHookMode_Post); // When the saferoom door opens...
	HookEvent("player_left_start_area", event_StartAreaPre, EventHookMode_Pre);
	HookEvent("player_left_start_area", event_StartArea, EventHookMode_Post); // When a survivor leaves the start area...
	HookEvent("player_team", event_PlayerTeam, EventHookMode_Post); // When a survivor changes team...

	// Startup the plugin's timers
	//CreateTimer(1.0, InitPlayers); // Called in OnMapStart
	CreateTimer(60.0, timer_UpdatePlayers, INVALID_HANDLE, TIMER_REPEAT);
	UpdateTimer = CreateTimer(GetConVarFloat(cvar_UpdateRate), timer_ShowTimerScore, INVALID_HANDLE, TIMER_REPEAT);
	AddCommandListener(Command_BlockSupportGiveSource, "give");
	HookConVarChange(cvar_UpdateRate, action_TimerChanged);
	HookConVarChange(cvar_DbPrefix, action_DbPrefixChanged);

	// Gamemode
	GetConVarString(cvar_Gamemode, CurrentGamemode, sizeof(CurrentGamemode));
	CurrentGamemodeID = GetCurrentGamemodeID();
	SetCurrentGamemodeName();
	HookConVarChange(cvar_Gamemode, action_GamemodeChanged);
	HookConVarChange(cvar_Difficulty, action_DifficultyChanged);

	//RegConsoleCmd("l4d_stats_test", cmd_StatsTest);

	MapTimingSurvivors = CreateTrie();
	MapTimingInfected = CreateTrie();
	FriendlyFireDamageTrie = CreateTrie();
	PlayerRankVoteTrie = CreateTrie();

	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
		OnAdminMenuReady(topmenu);

	if (FileExists("addons/sourcemod/gamedata/l4d_stats.txt"))
	{
		// SDK handles for team shuffle
		L4DStatsConf = LoadGameConfigFile("l4d_stats");
		if (L4DStatsConf == INVALID_HANDLE)
		{
			LogError("Could not load gamedata/l4d_stats.txt");
		}
		else
		{
			StartPrepSDKCall(SDKCall_Player);
			PrepSDKCall_SetFromConf(L4DStatsConf, SDKConf_Signature, "SetHumanSpec");
			PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
			L4DStatsSHS = EndPrepSDKCall();

			StartPrepSDKCall(SDKCall_Player);
			PrepSDKCall_SetFromConf(L4DStatsConf, SDKConf_Signature, "TakeOverBot");
			PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
			L4DStatsTOB = EndPrepSDKCall();
		}
	}
	else
	{
		LogMessage("Rank Vote is disabled because could not load gamedata/l4d_stats.txt");
	}

	// Sounds
	if (EnableSounds_Rankvote)
	{
		EnableSounds_Rankvote = PrecacheSound(SOUND_RANKVOTE); // Sound from rankvote team switch
	}
	else
	{
		EnableSounds_Rankvote = true;
	}

	if (EnableSounds_Maptime_Start)
	{
		EnableSounds_Maptime_Start = PrecacheSound(StatsSound_MapTime_Start); // Sound map timer start
	}
	else
	{
		EnableSounds_Maptime_Start = true;
	}

	if (EnableSounds_Maptime_Improve)
	{
		EnableSounds_Maptime_Improve = PrecacheSound(StatsSound_MapTime_Improve); // Sound from improving personal map timing
	}
	else
	{
		EnableSounds_Maptime_Improve = true;
	}

	if (EnableSounds_Rankmenu_Show)
	{
		EnableSounds_Rankmenu_Show = PrecacheSound(StatsSound_Rankmenu_Show); // Sound from showing the rankmenu
	}
	else
	{
		EnableSounds_Rankmenu_Show = true;
	}

	if (EnableSounds_Boomer_Vomit)
	{
		EnableSounds_Boomer_Vomit = PrecacheSound(StatsSound_Boomer_Vomit); // Sound from a successful boomer vomit (Perfect Blindness)
	}
	else
	{
		EnableSounds_Boomer_Vomit = true;
	}

	if (EnableSounds_Hunter_Perfect)
	{
		EnableSounds_Hunter_Perfect = PrecacheSound(StatsSound_Hunter_Perfect); // Sound from a hunter perfect pounce (Death From Above)
	}
	else
	{
		EnableSounds_Hunter_Perfect = true;
	}

	if (EnableSounds_Tank_Bulldozer)
	{
		EnableSounds_Tank_Bulldozer = PrecacheSound(StatsSound_Tank_Bulldozer); // Sound from a tank bulldozer
	}
	else
	{
		EnableSounds_Tank_Bulldozer = true;
	}

	if (EngineVersion1 != Engine_Left4Dead)
	{
		if (EnableSounds_Charger_Ram)
		{
			EnableSounds_Charger_Ram = PrecacheSound(SOUND_CHARGER_RAM); // Sound from a charger scattering ram
		}
		else
		{
			EnableSounds_Charger_Ram = true;
		}
	}
	else
	{
		EnableSounds_Charger_Ram = false;
	}
	delete L4DStatsConf;
}


public OnMapEnd()
{
	// 连接和 KeepAlive 都保持跨地图运行，不停不断。
	// OnConfigsExecuted 的 ConnectDB 会检测并处理连接状态。
}

public OnConfigsExecuted()
{
	GetConVarString(cvar_DbPrefix, DbPrefix, sizeof(DbPrefix));

	// Init MySQL connections
	new bool:DatabaseReady = ConnectDB();
	if (!DatabaseReady && !IsDBReconnectPending())
	{
		SetFailState("Connecting to database failed. Read error log for further details.");
		return;
	}

	if (CommandsRegistered)
		return;

	CommandsRegistered = true;

	// Register chat commands for rank panels
	RegConsoleCmd("say", cmd_Say);
	RegConsoleCmd("say_team", cmd_Say);

	// Register console commands for rank panels
	RegConsoleCmd("sm_rank", cmd_ShowRank);
	RegConsoleCmd("sm_top10", cmd_ShowTop10);
	RegConsoleCmd("sm_top10ppm", cmd_ShowTop10PPM);
	RegConsoleCmd("sm_top10q", cmd_ShowQuarterTop10);
	RegConsoleCmd("sm_qtop10", cmd_ShowQuarterTop10);
	RegConsoleCmd("sm_quartertop10", cmd_ShowQuarterTop10);
	RegConsoleCmd("sm_nextrank", cmd_ShowNextRank);
	RegConsoleCmd("sm_showtimer", cmd_ShowTimedMapsTimer);
	RegConsoleCmd("sm_showrank", cmd_ShowRanks);
	RegConsoleCmd("sm_showppm", cmd_ShowPPMs);
	RegConsoleCmd("sm_rankvote", cmd_RankVote);
	RegConsoleCmd("sm_timedmaps", cmd_TimedMaps);
	RegConsoleCmd("sm_maptimes", cmd_MapTimes);
	RegConsoleCmd("sm_showmaptimes", cmd_ShowMapTimes);
	RegConsoleCmd("sm_rankmenu", cmd_ShowRankMenu);
	RegConsoleCmd("sm_rankmutetoggle", cmd_ToggleClientRankMute);
	RegConsoleCmd("sm_rankmute", cmd_ClientRankMute);
	AddCommandListener(Command_ReloadSupportItem, "+reload");
	RegConsoleCmd("sm_showmotd", cmd_ShowMotd);
	RegConsoleCmd("sm_resetscore", cmd_ResetScore);

	// Register administrator command for clearing all stats (BE CAREFUL)
	//RegAdminCmd("sm_rank_admin", cmd_RankAdmin, ADMFLAG_ROOT, "Display admin panel for Rank");
	//RegAdminCmd("sm_rank_clear", cmd_ClearRank, ADMFLAG_ROOT, "Clear all stats from database (asks a confirmation before clearing the database)");
	//RegAdminCmd("sm_rank_shuffle", cmd_ShuffleTeams, ADMFLAG_KICK, "Shuffle teams by player PPM (Points Per Minute)");
	RegAdminCmd("sm_rank_motd", cmd_SetMotd, ADMFLAG_GENERIC, "Set Message Of The Day");
	
	// Read the settings etc from the database.
	if (DatabaseReady && db != INVALID_HANDLE)
	{
		ReadDb();
		GetTop100PlayerScore();
		QuarterRank_QueryTop100Scores();
	}
}
