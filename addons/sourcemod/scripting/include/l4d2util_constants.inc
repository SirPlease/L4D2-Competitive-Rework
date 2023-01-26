#if defined l4d2util_constants_inc_
	#endinput
#endif
#define l4d2util_constants_inc_

#define ENTITY_MAX_NAME_LENGTH		64
#define MAX_MAP_NAME				64
#define MAX_NETWORKID_LENGTH		64 // num chars for a network (i.e steam) ID

// How many bits to use to encode an edict.
#define MAX_EDICT_BITS				11 // # of bits needed to represent max edicts
// Max # of edicts in a level
#define MAX_EDICTS					(1 << MAX_EDICT_BITS)

// m_lifeState values
#define LIFE_ALIVE					0 // alive
#define LIFE_DYING					1 // playing death animation or still falling off of a ledge waiting to hit ground
#define LIFE_DEAD					2 // dead. lying still.
#define LIFE_RESPAWNABLE			3
#define LIFE_DISCARDBODY			4

#define SPAWNFLAG_READY				0
#define SPAWNFLAG_CANSPAWN			(0 << 0)
#define SPAWNFLAG_DISABLED			(1 << 0)
#define SPAWNFLAG_WAITFORSURVIVORS	(1 << 1)
#define SPAWNFLAG_WAITFORFINALE		(1 << 2)
#define SPAWNFLAG_WAITFORTANKTODIE	(1 << 3)
#define SPAWNFLAG_SURVIVORESCAPED	(1 << 4)
#define SPAWNFLAG_DIRECTORTIMEOUT	(1 << 5)
#define SPAWNFLAG_WAITFORNEXTWAVE	(1 << 6)
#define SPAWNFLAG_CANBESEEN			(1 << 7)
#define SPAWNFLAG_TOOCLOSE			(1 << 8)
#define SPAWNFLAG_RESTRICTEDAREA	(1 << 9)
#define SPAWNFLAG_BLOCKED			(1 << 10)

#define HITGROUP_GENERIC	0
#define HITGROUP_HEAD		1
#define HITGROUP_CHEST		2
#define HITGROUP_STOMACH	3
#define HITGROUP_LEFTARM	4
#define HITGROUP_RIGHTARM	5
#define HITGROUP_LEFTLEG	6
#define HITGROUP_RIGHTLEG	7
#define HITGROUP_GEAR		10 // alerts NPC, but doesn't do damage or bleed (1/100th damage)

// Constants that exist in the game (except for constant MAX_NUMBER_TEAMS)
#define TEAM_ANY				-1
#define TEAM_INVALID			-1
#define TEAM_UNASSIGNED			0 // not assigned to a team
#define TEAM_SPECTATOR			1 // spectator team
#define TEAM_SURVIVOR			2
#define TEAM_ZOMBIE				3
#define TEAM_L4D1_SURVIVOR		4 // Used for maps where there are survivors from the first chapter and from the second, for example c7m3_port

#define MAX_NUMBER_TEAMS		5

// Constants are used in the game code, there is definitely no such enum
enum /*L4D2_Team*/
{
	L4D2Team_None = 0,
	L4D2Team_Spectator,
	L4D2Team_Survivor,
	L4D2Team_Infected,
	L4D2Team_L4D1_Survivor, // Used for maps where there are survivors from the first chapter and from the second, for example c7m3_port

	L4D2Team_Size // 5 size
};

//The official order of characters in the game
enum /*L4D2_Infected*/
{
	L4D2Infected_Common = 0,
	L4D2Infected_Smoker = 1,
	L4D2Infected_Boomer,
	L4D2Infected_Hunter,
	L4D2Infected_Spitter,
	L4D2Infected_Jockey,
	L4D2Infected_Charger,
	L4D2Infected_Witch,
	L4D2Infected_Tank,
	L4D2Infected_Survivor,

	L4D2Infected_Size //10 size
};

stock const char L4D2_InfectedNames[L4D2Infected_Size][] =
{
	"Normal",
	"Smoker",
	"Boomer",
	"Hunter",
	"Spitter",
	"Jockey",
	"Charger",
	"Witch",
	"Tank",
	"Survivor"
};

stock const char L4D2_TeamName[L4D2Team_Size][] =
{
	"Unassigned",
	"Spectator",
	"Survivors",
	"Infected",
	"L4D1_Survivor"
};

enum /*L4D2_Gender*/
{
	L4D2Gender_Neutral			= 0,
	L4D2Gender_Male				= 1,
	L4D2Gender_Female			= 2,
	L4D2Gender_Nanvet			= 3, //Bill
	L4D2Gender_TeenGirl			= 4, //Zoey
	L4D2Gender_Biker			= 5, //Francis
	L4D2Gender_Manager			= 6, //Louis
	L4D2Gender_Gambler			= 7, //Nick
	L4D2Gender_Producer			= 8, //Rochelle
	L4D2Gender_Coach			= 9, //Coach
	L4D2Gender_Mechanic			= 10, //Ellis
	L4D2Gender_Ceda				= 11,
	L4D2Gender_Crawler			= 12, //Mudman
	L4D2Gender_Undistractable	= 13, //Workman (class not reacting to the pipe bomb)
	L4D2Gender_Fallen			= 14,
	L4D2Gender_Riot_Control		= 15, //RiotCop
	L4D2Gender_Clown			= 16,
	L4D2Gender_Jimmy			= 17, //JimmyGibbs
	L4D2Gender_Hospital_Patient	= 18,
	L4D2Gender_Witch_Bride		= 19,
	L4D2Gender_Police			= 20, //l4d1 RiotCop (was removed from the game)
	L4D2Gender_Male_L4D1		= 21,
	L4D2Gender_Female_L4D1		= 22,

	L4D2Gender_MaxSize //23 size
};

enum /*L4D2WeaponSlot*/
{
	L4D2WeaponSlot_Primary,
	L4D2WeaponSlot_Secondary,
	L4D2WeaponSlot_Throwable,
	L4D2WeaponSlot_HeavyHealthItem,
	L4D2WeaponSlot_LightHealthItem,

	L4D2WeaponSlot_Size //5 size
};

// Weapon ID enumerations.
// These values are *NOT* arbitrary! 
// They are used in game as the weaponid for weapon_spawn entities
enum /*WeaponId*/
{
	WEPID_NONE,             // 0
	WEPID_PISTOL,           // 1
	WEPID_SMG,              // 2
	WEPID_PUMPSHOTGUN,      // 3
	WEPID_AUTOSHOTGUN,      // 4
	WEPID_RIFLE,            // 5
	WEPID_HUNTING_RIFLE,    // 6
	WEPID_SMG_SILENCED,     // 7
	WEPID_SHOTGUN_CHROME,   // 8
	WEPID_RIFLE_DESERT,     // 9
	WEPID_SNIPER_MILITARY,  // 10
	WEPID_SHOTGUN_SPAS,     // 11
	WEPID_FIRST_AID_KIT,    // 12
	WEPID_MOLOTOV,          // 13
	WEPID_PIPE_BOMB,        // 14
	WEPID_PAIN_PILLS,       // 15
	WEPID_GASCAN,           // 16
	WEPID_PROPANE_TANK,     // 17
	WEPID_OXYGEN_TANK,      // 18
	WEPID_MELEE,            // 19
	WEPID_CHAINSAW,         // 20
	WEPID_GRENADE_LAUNCHER, // 21
	WEPID_AMMO_PACK,        // 22
	WEPID_ADRENALINE,       // 23
	WEPID_DEFIBRILLATOR,    // 24
	WEPID_VOMITJAR,         // 25
	WEPID_RIFLE_AK47,       // 26
	WEPID_GNOME_CHOMPSKI,   // 27
	WEPID_COLA_BOTTLES,     // 28
	WEPID_FIREWORKS_BOX,    // 29
	WEPID_INCENDIARY_AMMO,  // 30
	WEPID_FRAG_AMMO,        // 31
	WEPID_PISTOL_MAGNUM,    // 32
	WEPID_SMG_MP5,          // 33
	WEPID_RIFLE_SG552,      // 34
	WEPID_SNIPER_AWP,       // 35
	WEPID_SNIPER_SCOUT,     // 36
	WEPID_RIFLE_M60,        // 37
	WEPID_TANK_CLAW,        // 38
	WEPID_HUNTER_CLAW,      // 39
	WEPID_CHARGER_CLAW,     // 40
	WEPID_BOOMER_CLAW,      // 41
	WEPID_SMOKER_CLAW,      // 42
	WEPID_SPITTER_CLAW,     // 43
	WEPID_JOCKEY_CLAW,      // 44
	WEPID_MACHINEGUN,       // 45
	WEPID_VOMIT,            // 46
	WEPID_SPLAT,            // 47
	WEPID_POUNCE,           // 48
	WEPID_LOUNGE,           // 49
	WEPID_PULL,             // 50
	WEPID_CHOKE,            // 51
	WEPID_ROCK,             // 52
	WEPID_PHYSICS,          // 53
	WEPID_AMMO,             // 54
	WEPID_UPGRADE_ITEM,     // 55

	WEPID_SIZE //56 size
};

// These values are arbitrary
enum /*MeleeWeaponId*/
{
	WEPID_MELEE_NONE,
	WEPID_KNIFE,
	WEPID_BASEBALL_BAT,
	WEPID_MELEE_CHAINSAW,
	WEPID_CRICKET_BAT,
	WEPID_CROWBAR,
	WEPID_DIDGERIDOO,
	WEPID_ELECTRIC_GUITAR,
	WEPID_FIREAXE,
	WEPID_FRYING_PAN,
	WEPID_GOLF_CLUB,
	WEPID_KATANA,
	WEPID_MACHETE,
	WEPID_RIOT_SHIELD,
	WEPID_TONFA,
	WEPID_SHOVEL,
	WEPID_PITCHFORK,
	
	WEPID_MELEES_SIZE //15 size
};

// Weapon names for each of the weapons, used in identification.
stock const char WeaponNames[WEPID_SIZE][] =
{
	"weapon_none", "weapon_pistol", "weapon_smg",                                            // 0
	"weapon_pumpshotgun", "weapon_autoshotgun", "weapon_rifle",                              // 3
	"weapon_hunting_rifle", "weapon_smg_silenced", "weapon_shotgun_chrome",                  // 6
	"weapon_rifle_desert", "weapon_sniper_military", "weapon_shotgun_spas",                  // 9
	"weapon_first_aid_kit", "weapon_molotov", "weapon_pipe_bomb",                            // 12
	"weapon_pain_pills", "weapon_gascan", "weapon_propanetank",                              // 15
	"weapon_oxygentank", "weapon_melee", "weapon_chainsaw",                                  // 18
	"weapon_grenade_launcher", "weapon_ammo_pack", "weapon_adrenaline",                      // 21
	"weapon_defibrillator", "weapon_vomitjar", "weapon_rifle_ak47",                          // 24
	"weapon_gnome", "weapon_cola_bottles", "weapon_fireworkcrate",                           // 27
	"weapon_upgradepack_incendiary", "weapon_upgradepack_explosive", "weapon_pistol_magnum", // 30
	"weapon_smg_mp5", "weapon_rifle_sg552", "weapon_sniper_awp",                             // 33
	"weapon_sniper_scout", "weapon_rifle_m60", "weapon_tank_claw",                           // 36
	"weapon_hunter_claw", "weapon_charger_claw", "weapon_boomer_claw",                       // 39
	"weapon_smoker_claw", "weapon_spitter_claw", "weapon_jockey_claw",                       // 42
	"weapon_machinegun", "vomit", "splat",                                                   // 45
	"pounce", "lounge", "pull",                                                              // 48
	"choke", "rock", "physics",                                                              // 51
	"ammo", "upgrade_item"                                                                   // 54
};

// Long weapon names
stock const char LongWeaponNames[WEPID_SIZE][] = 
{
	"None", "Pistol", "Uzi", // 0
	"Pump", "Autoshotgun", "M-16", // 3
	"Hunting Rifle", "Mac", "Chrome", // 6
	"Desert Rifle", "Military Sniper", "SPAS Shotgun", // 9
	"First Aid Kit", "Molotov", "Pipe Bomb", // 12
	"Pills", "Gascan", "Propane Tank", // 15
	"Oxygen Tank", "Melee", "Chainsaw", // 18
	"Grenade Launcher", "Ammo Pack", "Adrenaline", // 21
	"Defibrillator", "Bile Bomb", "AK-47", // 24
	"Gnome", "Cola Bottles", "Fireworks", // 27
	"Incendiary Ammo Pack", "Explosive Ammo Pack", "Deagle", // 30
	"MP5", "SG552", "AWP", // 33
	"Scout", "M60", "Tank Claw", // 36
	"Hunter Claw", "Charger Claw", "Boomer Claw", // 39
	"Smoker Claw", "Spitter Claw", "Jockey Claw", // 42
	"Turret", "vomit", "splat", // 45
	"pounce", "lounge", "pull", // 48
	"choke", "rock", "physics", // 51
	"ammo", "upgrade_item" // 54
};

// Internal names for melee weapons
stock const char MeleeWeaponNames[WEPID_MELEES_SIZE][] =
{
	"",
	"knife",
	"baseball_bat",
	"chainsaw",
	"cricket_bat",
	"crowbar",
	"didgeridoo",
	"electric_guitar",
	"fireaxe",
	"frying_pan",
	"golfclub",
	"katana",
	"machete",
	"riotshield",
	"tonfa",
	"shovel",
	"pitchfork"
};

stock const char LongMeleeWeaponNames[WEPID_MELEES_SIZE][] =
{
	"None",
	"Knife",
	"Baseball Bat",
	"Chainsaw",
	"Cricket Bat",
	"Crowbar",
	"didgeridoo", // derp
	"Guitar",
	"Axe",
	"Frying Pan",
	"Golf Club",
	"Katana",
	"Machete",
	"Riot Shield",
	"Tonfa",
	"Shovel",
	"Pitchfork"
};

// World weapon models for each of the weapons. Useful for making new weapon spawns.
// Some models are left blank because no single model can be given, the model is known or none exist.
stock const char WeaponModels[WEPID_SIZE][] =
{
	"",
	"/w_models/weapons/w_pistol_B.mdl",
	"/w_models/weapons/w_smg_uzi.mdl",
	"/w_models/weapons/w_shotgun.mdl",
	"/w_models/weapons/w_autoshot_m4super.mdl",
	"/w_models/weapons/w_rifle_m16a2.mdl",
	"/w_models/weapons/w_sniper_mini14.mdl",
	"/w_models/weapons/w_smg_a.mdl",
	"/w_models/weapons/w_pumpshotgun_a.mdl",
	"/w_models/weapons/w_desert_rifle.mdl",           // "/w_models/weapons/w_rifle_b.mdl"
	"/w_models/weapons/w_sniper_military.mdl",
	"/w_models/weapons/w_shotgun_spas.mdl",
	"/w_models/weapons/w_eq_medkit.mdl",
	"/w_models/weapons/w_eq_molotov.mdl",
	"/w_models/weapons/w_eq_pipebomb.mdl",
	"/w_models/weapons/w_eq_painpills.mdl",
	"/props_junk/gascan001a.mdl",
	"/props_junk/propanecanister001.mdl",
	"/props_equipment/oxygentank01.mdl",
	"",                                               // "/weapons/w_knife_t.mdl",
	                                                  // "/weapons/melee/w_bat.mdl",
	                                                  // "/weapons/melee/w_chainsaw.mdl
	                                                  // "/weapons/melee/w_cricket_bat.mdl",
	                                                  // "/weapons/melee/w_crowbar.mdl",
	                                                  // "/weapons/melee/w_didgeridoo.mdl",
	                                                  // "/weapons/melee/w_electric_guitar.mdl",
	                                                  // "/weapons/melee/w_fireaxe.mdl",
	                                                  // "/weapons/melee/w_frying_pan.mdl",
	                                                  // "/weapons/melee/w_golfclub.mdl",
	                                                  // "/weapons/melee/w_katana.mdl",
	                                                  // "/weapons/melee/w_machete.mdl",
	                                                  // "/weapons/melee/w_riotshield.mdl",
	                                                  // "/weapons/melee/w_tonfa.mdl"
	"/weapons/melee/w_chainsaw.mdl",
	"/w_models/weapons/w_grenade_launcher.mdl",
	"",
	"/w_models/weapons/w_eq_adrenaline.mdl",
	"/w_models/weapons/w_eq_defibrillator.mdl",
	"/w_models/weapons/w_eq_bile_flask.mdl",
	"/w_models/weapons/w_rifle_ak47.mdl",
	"/props_junk/gnome.mdl",
	"/w_models/weapons/w_cola.mdl",
	"/props_junk/explosive_box001.mdl",
	"/w_models/weapons/w_eq_incendiary_ammopack.mdl",
	"/w_models/weapons/w_eq_explosive_ammopack.mdl",
	"/w_models/weapons/w_desert_eagle.mdl",
	"/w_models/weapons/w_smg_mp5.mdl",
	"/w_models/weapons/w_rifle_sg552.mdl",
	"/w_models/weapons/w_sniper_awp.mdl",
	"/w_models/weapons/w_sniper_scout.mdl",
	"/w_models/weapons/w_m60.mdl",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	""
};

stock const char MeleeWeaponModels[WEPID_MELEES_SIZE][] =
{
	"",
	"/w_models/weapons/w_knife_t.mdl",
	"/weapons/melee/w_bat.mdl",
	"/weapons/melee/w_chainsaw.mdl",
	"/weapons/melee/w_cricket_bat.mdl",
	"/weapons/melee/w_crowbar.mdl",
	"/weapons/melee/w_didgeridoo.mdl",
	"/weapons/melee/w_electric_guitar.mdl",
	"/weapons/melee/w_fireaxe.mdl",
	"/weapons/melee/w_frying_pan.mdl",
	"/weapons/melee/w_golfclub.mdl",
	"/weapons/melee/w_katana.mdl",
	"/weapons/melee/w_machete.mdl",
	"/weapons/melee/w_riotshield.mdl",
	"/weapons/melee/w_tonfa.mdl",
	"/weapons/melee/w_shovel.mdl",
	"/weapons/melee/w_pitchfork.mdl"
};

stock const int WeaponSlots[WEPID_SIZE] =
{
	-1, // WEPID_NONE
	1,  // WEPID_PISTOL
	0,  // WEPID_SMG
	0,  // WEPID_PUMPSHOTGUN
	0,  // WEPID_AUTOSHOTGUN
	0,  // WEPID_RIFLE
	0,  // WEPID_HUNTING_RIFLE
	0,  // WEPID_SMG_SILENCED
	0,  // WEPID_SHOTGUN_CHROME
	0,  // WEPID_RIFLE_DESERT
	0,  // WEPID_SNIPER_MILITARY
	0,  // WEPID_SHOTGUN_SPAS
	3,  // WEPID_FIRST_AID_KIT
	2,  // WEPID_MOLOTOV
	2,  // WEPID_PIPE_BOMB
	4,  // WEPID_PAIN_PILLS
	-1, // WEPID_GASCAN
	-1, // WEPID_PROPANE_TANK
	-1, // WEPID_OXYGEN_TANK
	1,  // WEPID_MELEE
	1,  // WEPID_CHAINSAW
	0,  // WEPID_GRENADE_LAUNCHER
	3,  // WEPID_AMMO_PACK
	4,  // WEPID_ADRENALINE
	3,  // WEPID_DEFIBRILLATOR
	2,  // WEPID_VOMITJAR
	0,  // WEPID_RIFLE_AK47
	-1, // WEPID_GNOME_CHOMPSKI
	-1, // WEPID_COLA_BOTTLES
	-1, // WEPID_FIREWORKS_BOX
	3,  // WEPID_INCENDIARY_AMMO
	3,  // WEPID_FRAG_AMMO
	1,  // WEPID_PISTOL_MAGNUM
	0,  // WEPID_SMG_MP5
	0,  // WEPID_RIFLE_SG552
	0,  // WEPID_SNIPER_AWP
	0,  // WEPID_SNIPER_SCOUT
	0,  // WEPID_RIFLE_M60
	-1, // WEPID_TANK_CLAW
	-1, // WEPID_HUNTER_CLAW
	-1, // WEPID_CHARGER_CLAW
	-1, // WEPID_BOOMER_CLAW
	-1, // WEPID_SMOKER_CLAW
	-1, // WEPID_SPITTER_CLAW
	-1, // WEPID_JOCKEY_CLAW
	-1, // WEPID_MACHINEGUN
	-1, // WEPID_FATAL_VOMIT
	-1, // WEPID_EXPLODING_SPLAT
	-1, // WEPID_LUNGE_POUNCE
	-1, // WEPID_LOUNGE
	-1, // WEPID_FULLPULL
	-1, // WEPID_CHOKE
	-1, // WEPID_THROWING_ROCK
	-1, // WEPID_TURBO_PHYSICS
	-1, // WEPID_AMMO
	-1  // WEPID_UPGRADE_ITEM
};

/* @A1m`:
 * Original order of survivors in the game code.
 *
 * ~~~To use this to get survivor names we need left4dhooks or left4downtown,
 * we need to know the 'survival_set' value from the mission info,
 * this can be found by calling 'CTerrorGameRules::FastGetSurvivorSet'
 * (this function stores the value from 'CTerrorGameRules: :GetSurvivorSet'', it used for optimization) 
 * or 'CTerrorGameRules: :GetSurvivorSet'.
 *
 * If the player is not a survivor, then m_survivorCharacter netprop is set to 8.
 *
 * This damn code l4d2 :D, the order of the survivors on the l4d1 maps is changing,
 * after Louis should be Francis.~~~
 *
 * Or is it easier to get the survivor character index using netprop 'm_Gender'.
*/
enum /*SurvivorCharacterType*/
{
	SurvivorCharacter_Nick = 0,
	SurvivorCharacter_Rochelle,
	SurvivorCharacter_Coach,
	SurvivorCharacter_Ellis,
	SurvivorCharacter_Bill,
	SurvivorCharacter_Zoey,
	SurvivorCharacter_Francis,
	SurvivorCharacter_Louis,
	SurvivorCharacter_Invalid, // 8

	SurvivorCharacter_Size // 9 size
};

stock const char g_sSurvivorDisplayName[SurvivorCharacter_Size][] =
{
	"Nick",
	"Rochelle",
	"Coach",
	"Ellis",
	"Bill",
	"Zoey",
	"Francis",
	"Louis",
	"Invalid"
};

stock const char g_sSurvivorName[SurvivorCharacter_Size][] =
{
	"Gambler",
	"Producer",
	"Coach",
	"Mechanic",
	"NamVet",
	"TeenGirl",
	"Biker",
	"Manager",
	"Invalid"
};

// Models for each of the characters
stock const char g_sSurvivorModels[SurvivorCharacter_Size - 1][] =
{
	"models/survivors/survivor_gambler.mdl",	// MODEL_NICK
	"models/survivors/survivor_producer.mdl",	// MODEL_ROCHELLE
	"models/survivors/survivor_coach.mdl",		// MODEL_COACH
	"models/survivors/survivor_mechanic.mdl",	// MODEL_ELLIS
	"models/survivors/survivor_namvet.mdl",		// MODEL_BILL
	"models/survivors/survivor_teenangst.mdl",	// MODEL_ZOEY
	"models/survivors/survivor_biker.mdl",		// MODEL_FRANCIS
	"models/survivors/survivor_manager.mdl",	// MODEL_LOUIS
};

// Animation IDs used by CTerrorPlayer::DoAnimationEvent
// Gaps do not mean the animation doesn't exist, just that I don't know what it maps to.
enum /*Animation*/
{
	ANIM_RELOAD_PISTOL_UZI_SNIPER = 4,
	ANIM_RELOAD_SHOTGUN = 5,
	ANIM_RELOAD_SHOTGUN_FINAL = 6,
	ANIM_JUMP = 7,
	ANIM_LAND = 8,
	ANIM_TANK_DEATH = 10,
	ANIM_HUNTER_CLEAR = 18,
	ANIM_BACK_TO_IDLE = 20,
	ANIM_TANK_PUNCH = 33,
	ANIM_SHOVE_COMMON = 34,
	ANIM_SHOVE = 35,
	ANIM_START_RELOADING_SHOTGUN = 38, // Secondary value: Number of shells to reload
	ANIM_ATTACKA = 40,
	ANIM_ATTACKB = 41,
	ANIM_HEAL_SELF = 42,
	ANIM_HEAL_OTHER = 43,
	ANIM_PICKUP_START_HELPER = 44,
	ANIM_PICKUP_DEFIB_DEPLOY_STOP = 46,
	ANIM_PICKUP_START_SUBJECT = 47,
	ANIM_PICKUP_STOP_SUBJECT = 48,
	ANIM_PICKUP_SUCCESS_SUBJECT = 49,
	ANIM_DEFIB_START = 50,
	ANIM_DEFIB_END = 51,
	ANIM_DEPLOY_AMMO = 52,
	ANIM_COLA_DELIVER = 55,
	ANIM_SHOVED_BY_TEAMMATE = 57,
	ANIM_TAKE_DAMAGE = 58,
	ANIM_THROW_ITEM_START = 59,
	ANIM_THROW_ITEM_FINISH = 61,
	ANIM_THROW_ITEM_CANCEL = 63,
	ANIM_USE = 64,
	ANIM_CHANGE_SLOT = 65,
	ANIM_STUMBLE = 68, // Secondary value: ??
	ANIM_SPITTER_SPIT = 70,
	ANIM_CHARGER_START_CHARGE = 71,
	ANIM_CHARGER_STUMBLE = 72, // Will also play STUMBLE (68)
	ANIM_CHARGER_GETUP = 78,
	ANIM_HUNTER_GETUP = 86,
	ANIM_SMOKER_TONGUE_FIREA = 87,
	ANIM_SMOKER_TONGUE_FIREB = 88,
	ANIM_SMOKER_CLAW_TARGET = 90,
	ANIM_SMOKER_TONGUE_BROKE = 91,
	ANIM_SURVIVOR_PULLED = 92,
	ANIM_ROCK = 93, // Secondary value: 1
	ANIM_TANK_CLIMB = 94, // Secondary value: Height (1-6)
	ANIM_TANK_PUNCH_GETUP = 96,
	ANIM_IDLE = 98,
	
	ANIMATION_SIZE //99 size
};
