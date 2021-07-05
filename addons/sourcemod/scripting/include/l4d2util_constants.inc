#if defined l4d2util_constants_inc_
	#endinput
#endif
#define l4d2util_constants_inc_

#define IS_VALID_CLIENT(%1)     (%1 > 0 && %1 <= MaxClients)

enum L4D2_Team
{
	L4D2Team_Spectator = 1,
	L4D2Team_Survivor,
	L4D2Team_Infected
};

enum L4D2_Infected
{
	L4D2Infected_Smoker = 1,
	L4D2Infected_Boomer,
	L4D2Infected_Hunter,
	L4D2Infected_Spitter,
	L4D2Infected_Jockey,
	L4D2Infected_Charger,
	L4D2Infected_Witch,
	L4D2Infected_Tank
};

stock const char L4D2_InfectedNames[8][] =
{
	"Smoker",
	"Boomer",
	"Hunter",
	"Spitter",
	"Jockey",
	"Charger",
	"Witch",
	"Tank"
};

enum L4D2_Gender
{
	L4D2Gender_Neutral,
	L4D2Gender_Male,
	L4D2Gender_Female,
	L4D2Gender_Bill,
	L4D2Gender_Zoey,
	L4D2Gender_Francis,
	L4D2Gender_Louis,
	L4D2Gender_Nick,
	L4D2Gender_Rochelle,
	L4D2Gender_Coach,
	L4D2Gender_Ellis,
	L4D2Gender_CEDA,
	L4D2Gender_Mudman,
	L4D2Gender_Workman,
	L4D2Gender_Fallen,
	L4D2Gender_RiotCop,
	L4D2Gender_Clown,
	L4D2Gender_JimmyGibbs,
	L4D2Gender_HospitalPatient
};

// Weapon ID enumerations.
// These values are *NOT* arbitrary! 
// They are used in game as the weaponid for weapon_spawn entities
enum WeaponId
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
	WEPID_UPGRADE_ITEM      // 55
};

// These values are arbitrary
enum MeleeWeaponId
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
	WEPID_TONFA
};

// Weapon names for each of the weapons, used in identification.
stock const char WeaponNames[WeaponId][] =
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

// Internal names for melee weapons
stock const char MeleeWeaponNames[MeleeWeaponId][] =
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
	"tonfa"
};

// World weapon models for each of the weapons. Useful for making new weapon spawns.
// Some models are left blank because no single model can be given, the model is known or none exist.
stock const char WeaponModels[WeaponId][] =
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
	"",
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

stock const char MeleeWeaponModels[MeleeWeaponId][] =
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
	"/weapons/melee/w_tonfa.mdl"
};

stock const int WeaponSlots[view_as<int>(WeaponId)] =
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

// Indexes are arbitrary at this point.
enum SurvivorCharacter
{
	SC_NONE=-1,
	SC_COACH=0,
	SC_NICK,
	SC_ROCHELLE,
	SC_ELLIS,
	SC_LOUIS,
	SC_ZOEY,
	SC_BILL,
	SC_FRANCIS
};

// Names of the survivors
// TODO: languages?
stock const char SurvivorNames[SurvivorCharacter][] =
{
	"Coach",
	"Nick",
	"Rochelle",
	"Ellis",
	"Louis",
	"Zoey",
	"Bill",
	"Francis"
};

// Models for each of the characters
stock const char SurvivorModels[SurvivorCharacter][] =
{
	"models/survivors/survivor_coach.mdl",
	"models/survivors/survivor_gambler.mdl",
	"models/survivors/survivor_producer.mdl",
	"models/survivors/survivor_mechanic.mdl",
	"models/survivors/survivor_manager.mdl",
	"models/survivors/survivor_teenangst.mdl",
	"models/survivors/survivor_namvet.mdl",
	"models/survivors/survivor_biker.mdl"
};

// Animation IDs used by CTerrorPlayer::DoAnimationEvent
// Gaps do not mean the animation doesn't exist, just that I don't know what it maps to.
enum Animation
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
}
