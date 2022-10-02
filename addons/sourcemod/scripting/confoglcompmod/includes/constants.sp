#if defined __confogl_constants_included
	#endinput
#endif
#define __confogl_constants_included

#define MAX_ENTITY_NAME_LENGTH		64

#define NUM_OF_SURVIVORS			4

#define START_SAFEROOM				(1 << 0)
#define END_SAFEROOM				(1 << 1)

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

enum
{
	L4D2Team_None = 0,
	L4D2Team_Spectator,
	L4D2Team_Survivor,
	L4D2Team_Infected,
	
	L4D2Team_Size //4 size
};

enum
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

enum
{
	L4D2WeaponSlot_Primary = 0,
	L4D2WeaponSlot_Secondary,
	L4D2WeaponSlot_Throwable,
	L4D2WeaponSlot_HeavyHealthItem,
	L4D2WeaponSlot_LightHealthItem,
	
	L4D2WeaponSlot_Size //5 size
};

enum /*WeaponIDs*/
{
	WEPID_PISTOL			 = 1,
	WEPID_SMG,				// 2
	WEPID_PUMPSHOTGUN,		// 3
	WEPID_AUTOSHOTGUN,		// 4
	WEPID_RIFLE,			// 5
	WEPID_HUNTING_RIFLE,	// 6
	WEPID_SMG_SILENCED,		// 7
	WEPID_SHOTGUN_CHROME,	// 8
	WEPID_RIFLE_DESERT,		// 9
	WEPID_SNIPER_MILITARY,	// 10
	WEPID_SHOTGUN_SPAS,		// 11
	WEPID_FIRST_AID_KIT,	// 12
	WEPID_MOLOTOV,			// 13
	WEPID_PIPE_BOMB,		// 14
	WEPID_PAIN_PILLS,		// 15
	WEPID_GASCAN,			// 16
	WEPID_PROPANE_TANK,		// 17
	WEPID_AIR_CANISTER,		// 18
	WEPID_CHAINSAW			 = 20,
	WEPID_GRENADE_LAUNCHER,	// 21
	WEPID_ADRENALINE 		 = 23,
	WEPID_DEFIBRILLATOR,	// 24
	WEPID_VOMITJAR,			// 25
	WEPID_RIFLE_AK47,		// 26
	WEPID_GNOME_CHOMPSKI,	// 27
	WEPID_COLA_BOTTLES,		// 28
	WEPID_FIREWORKS_BOX,	// 29
	WEPID_INCENDIARY_AMMO,	// 30
	WEPID_FRAG_AMMO,		// 31
	WEPID_PISTOL_MAGNUM,	// 32
	WEPID_SMG_MP5,			// 33
	WEPID_RIFLE_SG552,		// 34
	WEPID_SNIPER_AWP,		// 35
	WEPID_SNIPER_SCOUT,		// 36
	WEPID_RIFLE_M60,		// 37

	WEPID_SIZE
};

/*stock const char g_sTeamName[8][] =
{
	"Spectator",
	"" ,
	"Survivor",
	"Infected",
	"",
	"Infected",
	"Survivors",
	"Infected"
};*/
