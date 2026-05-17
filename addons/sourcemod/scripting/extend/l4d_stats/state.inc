#if defined _l4d_stats_state_included
	#endinput
#endif
#define _l4d_stats_state_included

// 插件运行时全局状态、ConVar 句柄和缓存数组。

new String:TM_MENU_CURRENT[4] = " <<";

new String:DB_PLAYERS_TOTALPOINTS[1024] = "totalpoints";
new String:DB_PLAYERS_TOTALPLAYTIME[1024] = "totalplaytime";

new String:RANKVOTE_QUESTION[128] = "Do you want to shuffle teams by player PPM?";

// Message of the day
new String:MOTD_TITLE[32] = "今日消息";
new String:MessageOfTheDay[1024];

// Set to false when stats seem to work properly
new bool:DEBUG = true;

new bool:CommandsRegistered = false;
// Sounds
new bool:EnableSounds_Rankvote = true;
new bool:EnableSounds_Maptime_Start = true;
new bool:EnableSounds_Maptime_Improve = true;
new bool:EnableSounds_Rankmenu_Show = true;
new bool:EnableSounds_Boomer_Vomit = true;
new bool:EnableSounds_Hunter_Perfect = true;
new bool:EnableSounds_Tank_Bulldozer = true;
new bool:EnableSounds_Charger_Ram = true;
new String:StatsSound_MapTime_Start[32];
new String:StatsSound_MapTime_Improve[32];
new String:StatsSound_Rankmenu_Show[32];
new String:StatsSound_Boomer_Vomit[32];
new String:StatsSound_Hunter_Perfect[32];
new String:StatsSound_Tank_Bulldozer[32];
new bool:Isstart = false;
new bool:g_broundend = false;
// Server version
EngineVersion EngineVersion1 =  Engine_Left4Dead;

// Database handle
new Handle:db = INVALID_HANDLE;
new String:DbPrefix[MAX_LINE_WIDTH] = "";

// Update Timer handle
new Handle:UpdateTimer = INVALID_HANDLE;

// Gamemode
new String:CurrentGamemode[MAX_LINE_WIDTH];
new String:CurrentGamemodeLabel[MAX_LINE_WIDTH];
new CurrentGamemodeID = GAMEMODE_UNKNOWN;
new String:CurrentMutation[MAX_LINE_WIDTH];
ConVar cvar_mode;

// Disable check Cvar handles
new Handle:cvar_Difficulty = INVALID_HANDLE;
new Handle:cvar_Gamemode = INVALID_HANDLE;
new Handle:cvar_Cheats = INVALID_HANDLE;

new Handle:cvar_SurvivorLimit = INVALID_HANDLE;
new Handle:cvar_InfectedLimit = INVALID_HANDLE;

// Game event booleans
new bool:PlayerVomited = false;
new bool:PlayerVomitedIncap = false;
new bool:PanicEvent = false;
new bool:PanicEventIncap = false;
new bool:CampaignOver = false;
new bool:WitchExists = false;
new bool:WitchDisturb = false;

// Anti-Stat Whoring vars
new CurrentPoints[MAXPLAYERS + 1];
new TankCount = 0;

new bool:ClientRankMute[MAXPLAYERS + 1];

// Cvar handles
new Handle:cvar_EnableRankVote = INVALID_HANDLE;
new Handle:cvar_HumansNeeded = INVALID_HANDLE;
new Handle:cvar_UpdateRate = INVALID_HANDLE;
//new Handle:cvar_AnnounceRankMinChange = INVALID_HANDLE;
new Handle:cvar_AnnounceRankChange = INVALID_HANDLE;
new Handle:cvar_AnnouncePlayerJoined = INVALID_HANDLE;
new Handle:cvar_AnnounceMotd = INVALID_HANDLE;
new Handle:cvar_AnnounceMode = INVALID_HANDLE;
new Handle:cvar_AnnounceRankChangeIVal = INVALID_HANDLE;
new Handle:cvar_AnnounceToTeam = INVALID_HANDLE;
//new Handle:cvar_AnnounceSpecial = INVALID_HANDLE;
new Handle:cvar_MedkitMode = INVALID_HANDLE;
new Handle:cvar_SiteURL = INVALID_HANDLE;
new Handle:cvar_RankOnJoin = INVALID_HANDLE;
new Handle:cvar_SilenceChat = INVALID_HANDLE;
new Handle:cvar_DisabledMessages = INVALID_HANDLE;
//new Handle:cvar_MaxPoints = INVALID_HANDLE;
new Handle:cvar_DbPrefix = INVALID_HANDLE;
//new Handle:cvar_LeaderboardTime = INVALID_HANDLE;
new Handle:cvar_EnableNegativeScore = INVALID_HANDLE;
new Handle:cvar_FriendlyFireMode = INVALID_HANDLE;
new Handle:cvar_FriendlyFireMultiplier = INVALID_HANDLE;
new Handle:cvar_FriendlyFireCooldown = INVALID_HANDLE;
new Handle:cvar_FriendlyFireCooldownMode = INVALID_HANDLE;
new Handle:FriendlyFireTimer[MAXPLAYERS + 1][MAXPLAYERS + 1];
new bool:FriendlyFireCooldown[MAXPLAYERS + 1][MAXPLAYERS + 1];
new FriendlyFirePrm[MAXPLAYERS][2];
new Handle:FriendlyFireDamageTrie = INVALID_HANDLE;
new FriendlyFirePrmCounter = 0;

new Handle:cvar_Enable = INVALID_HANDLE;
new Handle:cvar_EnableCoop = INVALID_HANDLE;
new Handle:cvar_EnableSv = INVALID_HANDLE;
new Handle:cvar_EnableVersus = INVALID_HANDLE;
new Handle:cvar_EnableTeamVersus = INVALID_HANDLE;
new Handle:cvar_EnableRealism = INVALID_HANDLE;
new Handle:cvar_EnableScavenge = INVALID_HANDLE;
new Handle:cvar_EnableTeamScavenge = INVALID_HANDLE;
new Handle:cvar_EnableRealismVersus = INVALID_HANDLE;
new Handle:cvar_EnableTeamRealismVersus = INVALID_HANDLE;
new Handle:cvar_EnableMutations = INVALID_HANDLE;

new Handle:cvar_RealismMultiplier = INVALID_HANDLE;
new Handle:cvar_RealismVersusSurMultiplier = INVALID_HANDLE;
new Handle:cvar_RealismVersusInfMultiplier = INVALID_HANDLE;
new Handle:cvar_EnableSvMedicPoints = INVALID_HANDLE;

new Handle:cvar_Infected = INVALID_HANDLE;
new Handle:cvar_Hunter = INVALID_HANDLE;
new Handle:cvar_Smoker = INVALID_HANDLE;
new Handle:cvar_Boomer = INVALID_HANDLE;
new Handle:cvar_Spitter = INVALID_HANDLE;
new Handle:cvar_Jockey = INVALID_HANDLE;
new Handle:cvar_Charger = INVALID_HANDLE;

new Handle:cvar_Pills = INVALID_HANDLE;
new Handle:cvar_Adrenaline = INVALID_HANDLE;
new Handle:cvar_Medkit = INVALID_HANDLE;
new Handle:cvar_Defib = INVALID_HANDLE;
new Handle:cvar_SmokerDrag = INVALID_HANDLE;
new Handle:cvar_ChokePounce = INVALID_HANDLE;
new Handle:cvar_JockeyRide = INVALID_HANDLE;
new Handle:cvar_ChargerPlummel = INVALID_HANDLE;
new Handle:cvar_ChargerCarry = INVALID_HANDLE;
new Handle:cvar_Revive = INVALID_HANDLE;
new Handle:cvar_Rescue = INVALID_HANDLE;
new Handle:cvar_Protect = INVALID_HANDLE;

new Handle:cvar_Tank = INVALID_HANDLE;
new Handle:cvar_Panic = INVALID_HANDLE;
new Handle:cvar_BoomerMob = INVALID_HANDLE;
new Handle:cvar_SafeHouse = INVALID_HANDLE;
new Handle:cvar_Witch = INVALID_HANDLE;
new Handle:cvar_WitchCrowned = INVALID_HANDLE;
new Handle:cvar_VictorySurvivors = INVALID_HANDLE;
new Handle:cvar_VictoryInfected = INVALID_HANDLE;

new Handle:cvar_FFire = INVALID_HANDLE;
new Handle:cvar_FIncap = INVALID_HANDLE;
new Handle:cvar_FKill = INVALID_HANDLE;
new Handle:cvar_InSafeRoom = INVALID_HANDLE;
new Handle:cvar_Restart = INVALID_HANDLE;
new Handle:cvar_CarAlarm = INVALID_HANDLE;
new Handle:cvar_BotScoreMultiplier = INVALID_HANDLE;

new Handle:cvar_SurvivorDeath = INVALID_HANDLE;
new Handle:cvar_SurvivorIncap = INVALID_HANDLE;

// L4D2 misc
new Handle:cvar_AmmoUpgradeAdded = INVALID_HANDLE;
new Handle:cvar_GascanPoured = INVALID_HANDLE;

new MaxPounceDistance;
new MinPounceDistance;
new MaxPounceDamage;
new Handle:cvar_HunterDamageCap = INVALID_HANDLE;
new Float:HunterPosition[MAXPLAYERS + 1][3];
new Handle:cvar_HunterPerfectPounceDamage = INVALID_HANDLE;
new Handle:cvar_HunterPerfectPounceSuccess = INVALID_HANDLE;
new Handle:cvar_HunterNicePounceDamage = INVALID_HANDLE;
new Handle:cvar_HunterNicePounceSuccess = INVALID_HANDLE;

new BoomerHitCounter[MAXPLAYERS + 1];
new bool:BoomerVomitUpdated[MAXPLAYERS + 1];
new Handle:cvar_BoomerSuccess = INVALID_HANDLE;
new Handle:cvar_BoomerPerfectHits = INVALID_HANDLE;
new Handle:cvar_BoomerPerfectSuccess = INVALID_HANDLE;
new Handle:TimerBoomerPerfectCheck[MAXPLAYERS + 1];

new InfectedDamageCounter[MAXPLAYERS + 1];
new Handle:cvar_InfectedDamage = INVALID_HANDLE;
new Handle:TimerInfectedDamageCheck[MAXPLAYERS + 1];

new Handle:cvar_TankDamageCap = INVALID_HANDLE;
new Handle:cvar_TankDamageTotal = INVALID_HANDLE;
new Handle:cvar_TankDamageTotalSuccess = INVALID_HANDLE;

new ChargerCarryVictim[MAXPLAYERS + 1];
new ChargerPlummelVictim[MAXPLAYERS + 1];
new JockeyVictim[MAXPLAYERS + 1];
new JockeyRideStartTime[MAXPLAYERS + 1];

new SmokerDamageCounter[MAXPLAYERS + 1];
new SpitterDamageCounter[MAXPLAYERS + 1];
new JockeyDamageCounter[MAXPLAYERS + 1];
new ChargerDamageCounter[MAXPLAYERS + 1];
new ChargerImpactCounter[MAXPLAYERS + 1];
new Handle:ChargerImpactCounterTimer[MAXPLAYERS + 1];
new Handle:cvar_ChargerRamHits = INVALID_HANDLE;
new Handle:cvar_ChargerRamSuccess = INVALID_HANDLE;
new TankDamageCounter[MAXPLAYERS + 1];
new TankDamageTotalCounter[MAXPLAYERS + 1];
new TankPointsCounter[MAXPLAYERS + 1];
new TankSurvivorKillCounter[MAXPLAYERS + 1];
new Handle:cvar_TankThrowRockSuccess = INVALID_HANDLE;

new Handle:cvar_PlayerLedgeSuccess = INVALID_HANDLE;
new Handle:cvar_Matador = INVALID_HANDLE;

new ClientInfectedType[MAXPLAYERS + 1];

new PlayerBlinded[MAXPLAYERS + 1][2];
new PlayerParalyzed[MAXPLAYERS + 1][2];
new PlayerLunged[MAXPLAYERS + 1][2];
new PlayerPlummeled[MAXPLAYERS + 1][2];
new PlayerCarried[MAXPLAYERS + 1][2];
new PlayerJockied[MAXPLAYERS + 1][2];

// Rank panel vars
new RankTotal = 0;
new ClientRank[MAXPLAYERS + 1];
new ClientNextRank[MAXPLAYERS + 1];
new ClientPoints[MAXPLAYERS + 1];
new GameModeRankTotal = 0;
new ClientGameModeRank[MAXPLAYERS + 1];
new ClientGameModePoints[MAXPLAYERS + 1][GAMEMODES];

// Misc arrays
new TimerPoints[MAXPLAYERS + 1];
new TimerKills[MAXPLAYERS + 1];
new TimerHeadshots[MAXPLAYERS + 1];
new Pills[4096];
new Adrenaline[4096];
new PillsFirstHolder[4096];
new AdrenalineFirstHolder[4096];
new FirstAidFirstHolder[4096];
new bool:SupportItemWorldSpawned[4096];
new bool:SupportStartGrantRecorded = false;
new HealingFirstAid[MAXPLAYERS + 1];
new Float:SupportReloadTime[MAXPLAYERS + 1];
new SupportReloadType[MAXPLAYERS + 1];
new Float:SupportReloadOrigin[MAXPLAYERS + 1][3];
new Float:SupportGiveCommandUntil[MAXPLAYERS + 1];
new Float:InitialSupportScanUntil = 0.0;

new String:QueryBuffer[MAX_QUERY_COUNTER][MAX_QUERY_COUNTER];
new QueryCounter = 0;

new AnnounceCounter[MAXPLAYERS + 1];
new PostAdminCheckRetryCounter[MAXPLAYERS + 1];

// For every medkit used the points earned by the Survivor team is calculated with this formula:
// NormalPointsEarned * (1 - MedkitsUsedCounter * cvar_MedkitUsedPointPenalty)
// Minimum formula result = 0 (Cannot be negative)
new MedkitsUsedCounter = 0;
new Handle:cvar_MedkitUsedPointPenalty = INVALID_HANDLE;
new Handle:cvar_MedkitUsedPointPenaltyMax = INVALID_HANDLE;
new Handle:cvar_MedkitUsedFree = INVALID_HANDLE;
new Handle:cvar_MedkitUsedRealismFree = INVALID_HANDLE;
new Handle:cvar_MedkitBotMode = INVALID_HANDLE;

new ProtectedFriendlyCounter[MAXPLAYERS + 1];
new Handle:TimerProtectedFriendly[MAXPLAYERS + 1];
new ProtectedFriendlyRoundToken = 1;

// Announce rank
new Handle:TimerRankChangeCheck[MAXPLAYERS + 1];
new RankChangeLastRank[MAXPLAYERS + 1];
new bool:RankChangeFirstCheck[MAXPLAYERS + 1];
new QuarterRankChangeLastRank[MAXPLAYERS + 1];
new bool:QuarterRankChangeFirstCheck[MAXPLAYERS + 1];

// MapTiming
new Float:MapTimingStartTime = -1.0;
new bool:MapTimingBlocked = false;
new Handle:MapTimingSurvivors = INVALID_HANDLE; // Survivors at the beginning of the map
new Handle:MapTimingInfected = INVALID_HANDLE; // Survivors at the beginning of the map
new String:MapTimingMenuInfo[MAXPLAYERS + 1][MAX_LINE_WIDTH];
float FastestTime = -1.0;

// When an admin calls for clear database, the client id is stored here for a period of time.
// The admin must then call the clear command again to confirm the call. After the second call
// the database is cleared. The confirm must be done in the time set by CLEAR_DATABASE_CONFIRMTIME.
new ClearDatabaseCaller = -1;
new Handle:ClearDatabaseTimer = INVALID_HANDLE;
//new Handle:ClearPlayerMenu = INVALID_HANDLE;

// Create handle for the admin menu
new Handle:RankAdminMenu = INVALID_HANDLE;
new TopMenuObject:MenuClear = INVALID_TOPMENUOBJECT;
new TopMenuObject:MenuClearPlayers = INVALID_TOPMENUOBJECT;
new TopMenuObject:MenuClearMaps = INVALID_TOPMENUOBJECT;
new TopMenuObject:MenuClearAll = INVALID_TOPMENUOBJECT;
new TopMenuObject:MenuRemoveCustomMaps = INVALID_TOPMENUOBJECT;
new TopMenuObject:MenuCleanPlayers = INVALID_TOPMENUOBJECT;
new TopMenuObject:MenuClearTimedMaps = INVALID_TOPMENUOBJECT;

bool g_brpgAvailable = false;

// Administrative Cvars
new Handle:cvar_AdminPlayerCleanLastOnTime = INVALID_HANDLE;
new Handle:cvar_AdminPlayerCleanPlatime = INVALID_HANDLE;

// Players can request a vote for team shuffle based on the player ranks ONCE PER MAP
new PlayerRankVote[MAXPLAYERS + 1];
new Handle:RankVoteTimer = INVALID_HANDLE;
new Handle:PlayerRankVoteTrie = INVALID_HANDLE; // Survivors at the beginning of the map
new Handle:cvar_RankVoteTime = INVALID_HANDLE;

new Handle:cvar_Top10PPMMin = INVALID_HANDLE;

new bool:SurvivalStarted = false;

new Handle:L4DStatsConf = INVALID_HANDLE;
new Handle:L4DStatsSHS = INVALID_HANDLE;
new Handle:L4DStatsTOB = INVALID_HANDLE;

new Float:ClientMapTime[MAXPLAYERS + 1];

new Handle:cvar_Lan = INVALID_HANDLE;
new Handle:cvar_SoundsEnabled = INVALID_HANDLE;

new Handle:MeleeKillTimer[MAXPLAYERS + 1];
new MeleeKillCounter[MAXPLAYERS + 1];
new ClientPlayTime[MAXPLAYERS + 1];
new bool:ClientEnabled[MAXPLAYERS + 1];
new CheckPlayerPoint[100];
Handle AnnounceGameTime, SuccessGetPlayerTime;
