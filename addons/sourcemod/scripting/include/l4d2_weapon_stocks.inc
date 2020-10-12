#if defined l4d2_weapons_inc_
    #endinput
#endif
#define l4d2_weapons_inc_

#define GETWEAPONNAME(%0) (IsValidWeaponId(WeaponId:(%0)) ? (WeaponNames[_:(%0)]) : "")
#define GETLONGWEAPONNAME(%0) (IsValidWeaponId(WeaponId:(%0)) ? (LongWeaponNames[_:(%0)]) : "")
#define GETMELEEWEAPONNAME(%0) (IsValidWeaponId(MeleeWeaponId:(%0)) ? (MeleeWeaponNames[_:(%0)]) : "")
#define GETLONGMELEEWEAPONNAME(%0) (IsValidWeaponId(MeleeWeaponId:(%0)) ? (LongMeleeWeaponNames[_:(%0)]) : "")
#define GETWEAPONMODEL(%0) (HasValidWeaponModel(WeaponId:(%0)) ? (WeaponModels[_:(%0)]) : "")
#define GETMELEEWEAPONMODEL(%0) (HasValidWeaponModel(MeleeWeaponId:(%0)) ? (MeleeWeaponModels[_:(%0)]) : "")

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
new const String:WeaponNames[WeaponId][] =
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
new const String:LongWeaponNames[WeaponId][] = 
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
new const String:MeleeWeaponNames[MeleeWeaponId][] =
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

// Long melee weapon names
new const String:LongMeleeWeaponNames[MeleeWeaponId][] =
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
    "Tonfa"
};

// World weapon models for each of the weapons. Useful for making new weapon spawns.
// Some models are left blank because no single model can be given, the model is known or none exist.
new const String:WeaponModels[WeaponId][] =
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

new const String:MeleeWeaponModels[MeleeWeaponId][] =
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

new const WeaponSlots[_:WeaponId] =
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

enum L4D2WeaponSlot
{
    L4D2WeaponSlot_Primary,
    L4D2WeaponSlot_Secondary,
    L4D2WeaponSlot_Throwable,
    L4D2WeaponSlot_HeavyHealthItem,
    L4D2WeaponSlot_LightHealthItem
};

static Handle:hWeaponNamesTrie = INVALID_HANDLE;
static Handle:hMeleeWeaponNamesTrie = INVALID_HANDLE;
static Handle:hMeleeWeaponModelsTrie = INVALID_HANDLE;

stock InitWeaponNamesTrie()
{
    hWeaponNamesTrie = CreateTrie();
    for(new i = 0; i < _:WeaponId; i++)
    {
        SetTrieValue(hWeaponNamesTrie, WeaponNames[WeaponId:i], i);
    }

    hMeleeWeaponNamesTrie = CreateTrie();
    hMeleeWeaponModelsTrie = CreateTrie();
    for (new i = 0; i < _:MeleeWeaponId; ++i)
    {
        SetTrieValue(hMeleeWeaponNamesTrie, MeleeWeaponNames[MeleeWeaponId:i], i);
        SetTrieString(hMeleeWeaponModelsTrie, MeleeWeaponModels[MeleeWeaponId:i], MeleeWeaponNames[MeleeWeaponId:i]);
    }
}

/**
 * Performs bounds checking to determine if a WeaponId is valid
 * @remark Simple check to see if wepid has a garbage value
 *
 * @param wepid        WeaponId to check for validity
 * @return True if wepid is valid, false otherwise.
 */
stock bool:IsValidWeaponId(WeaponId:wepid)
{
    return wepid >= WEPID_NONE && wepid < WeaponId;
}

/**
 * Get the player weapon slot used by the given WeaponId.
 * 
 * @param wepid     WeaponId to get the slot for.
 * @return Slot number (0-4) or -1 for invalid WeaponId or no slot
 */
stock GetSlotFromWeaponId(WeaponId:wepid)
{
    return IsValidWeaponId(wepid) ? WeaponSlots[wepid] : -1;
}

/**
 * Checks to see if a given weaponid has a known WeaponModel in this file's model array
 * @remark Some weapons (like weapon_melee) have multiple valid models, and this will report false for them.
 *
 * @param wepid        WeaponId to check for a known weapon model for.
 * @return True if a valid weapon model exists for wepid, false otherwise.
 */
stock bool:HasValidWeaponModel(WeaponId:wepid)
{
    return IsValidWeaponId(wepid) && WeaponModels[wepid][0] != '\0';
}

/**
 * Tries to look up a WeaponId for a given Weapon Name.
 *
 * @param weaponName    Weapon name string to look up Id from
 * @return                The corresponding WeaponId if found, else WEPID_NONE
 */
stock WeaponId:WeaponNameToId(const String:weaponName[])
{
    new WeaponID:id;
    if(hWeaponNamesTrie == INVALID_HANDLE)
    {
        InitWeaponNamesTrie();
    }
    if(GetTrieValue(hWeaponNamesTrie, weaponName, id))
    {
        return WeaponId:id;
    }
    return WEPID_NONE;
}

/**
 * Tries to look up L4D2's internal weapon name for a given WeaponId.
 *
 * @param wepid            WeaponId To get name of.
 * @param nameBuffer    String buffer to write the weapon name to.
 * @param length        Max length which can be written to the buffer.
 * @return                Number of bytes written to buffer, or 0 for invalid weaponId.
 */
stock GetWeaponName(WeaponId:wepid, String:nameBuffer[], length)
{
    strcopy(nameBuffer, length, GETWEAPONNAME(wepid));
}

/**
 * Tries to look up L4D2's internal weapon name for a given WeaponId.
 *
 * @param wepid            WeaponId To get name of.
 * @param nameBuffer    String buffer to write the weapon name to.
 * @param length        Max length which can be written to the buffer.
 * @return                Number of bytes written to buffer, or 0 for invalid weaponId.
 */
stock GetLongWeaponName(WeaponId:wepid, String:nameBuffer[], length)
{
    strcopy(nameBuffer, length, GETLONGWEAPONNAME(wepid));
}
    
/**
 * Tries to look up the weapon model for a given WeaponId.
 * @remarks You should use HasValidWeaponModel to make sure the WeaponId you're looking up has a valid model associated with it.
 *
 * @param wepid            WeaponId To get name of.
 * @param nameBuffer    String buffer to write the weapon name to.
 * @param length        Max length which can be written to the buffer.
 * @return                Number of bytes written to buffer, or 0 for invalid weaponid or no weapon model available.
 */
stock GetWeaponModel(WeaponId:wepid, String:modelBuffer[], length)
{
    strcopy(modelBuffer, length, GETWEAPONMODEL(wepid));
}

/**
 * Identifies a weapon spawn or weapon entity as a WeaponID
 * @remark Should work on most weapon ents--even spawns, singles, held, etc.
 *
 * @param entity        Index of entity to identify
 * @return WeaponID for the entity if it is a weapon, WEPID_NONE otherwise
 */
stock WeaponId:IdentifyWeapon(entity)
{
    if(!entity || !IsValidEntity(entity) || !IsValidEdict(entity))
    {
        return WEPID_NONE;
    }
    decl String:class[64];
    if(!GetEdictClassname(entity, class, sizeof(class)))
    {
        return WEPID_NONE;
    }

    if(StrEqual(class, "weapon_spawn"))
    {
        return WeaponId:GetEntProp(entity,Prop_Send,"m_weaponID");
    }

    new len = strlen(class);
    if(len-6 > 0 && StrEqual(class[len-6], "_spawn"))
    {
        class[len-6]='\0';
        return WeaponNameToId(class);
    }
    
    return WeaponNameToId(class);
}

// Helper function used for getting an entity's internal melee name
stock bool:GetMeleeWeaponNameFromEntity(entity, String:buffer[], length) {
    decl String:classname[64];
    if (! GetEdictClassname(entity, classname, sizeof(classname)))
    {
        return false;
    }

    if (StrEqual(classname, "weapon_melee_spawn"))
    {
        if (hMeleeWeaponModelsTrie == INVALID_HANDLE)
        {
            InitWeaponNamesTrie();
        }

        decl String:sModelName[128];
        GetEntPropString(entity, Prop_Data, "m_ModelName", sModelName, sizeof(sModelName));

        // Strip models directory
        if (strncmp(sModelName, "models/", 7, false) == 0)
        {
            strcopy(sModelName, sizeof(sModelName), sModelName[6]);
        }

        if (GetTrieString(hMeleeWeaponModelsTrie, sModelName, buffer, length))
        {
            return true;
        }
        return false;
    }
    else if (StrEqual(classname, "weapon_melee"))
    {
        GetEntPropString(entity, Prop_Data, "m_strMapSetScriptName", buffer, length);
        return true;
    }

    return false;
}

/**
 * Identifies a melee weapon spawn or weapon entity as a MeleeWeaponId
 * @remark Should work on most weapon ents--even spawns, singles, held, etc.
 *
 * @param entity        Index of entity to identify
 * @return MeleeWeaponId for the entity if it is a weapon, WEPID_MELEE_NONE otherwise
 */
stock MeleeWeaponId:IdentifyMeleeWeapon(entity)
{
    if (IdentifyWeapon(entity) != WEPID_MELEE)
    {
        return WEPID_MELEE_NONE;
    }

    decl String:sName[128];
    if (! GetMeleeWeaponNameFromEntity(entity, sName, sizeof(sName)))
    {
        return WEPID_MELEE_NONE;
    }

    if (hMeleeWeaponNamesTrie == INVALID_HANDLE)
    {
        InitWeaponNamesTrie();
    }

    new id;
    if(GetTrieValue(hMeleeWeaponNamesTrie, sName, id))
    {
        return MeleeWeaponId:id;
    }
    return WEPID_MELEE_NONE;
}

/**
 * Attempts to convert a weapon spawn entity to a given weapon spawn
 * @remark Truthfully, this will work on any entity with origin/rotation.
 *        Also, requires the weapon to either have a Valid weapon model or have one provided
 *
 * @param entity        Index of entity to convert to weapon spawn
 * @param wepid            WeaponId of the weapon to have the spawner hold
 * @param count            Weapon count for the spawner (default 5)
 * @param model            World model to use for the weapon spawn
 * @return entity of the new weapon spawn, or -1 on errors.
 */
stock ConvertWeaponSpawn(entity, WeaponId:wepid, count=5, const String:model[] = "")
{
    if(!IsValidEntity(entity)) return -1;
    if(!IsValidWeaponId(wepid)) return -1;
    if(model[0] == '\0' && !HasValidWeaponModel(wepid)) return -1;
    
    
    new Float:origins[3], Float:angles[3];
    GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origins);
    GetEntPropVector(entity, Prop_Send, "m_angRotation", angles);
    
    AcceptEntityInput(entity, "kill");
    
    entity = CreateEntityByName("weapon_spawn");
    if(!IsValidEntity(entity)) return -1;
    
    SetEntProp(entity, Prop_Send, "m_weaponID", wepid);

    decl String:buf[64];
    if(model[0] == '\0')
    {
        SetEntityModel(entity, model);
    }
    else
    {
        GetWeaponModel(wepid, buf, sizeof(buf));
        SetEntityModel(entity, buf);
    }
    IntToString(count, buf, sizeof(buf));
    DispatchKeyValue(entity, "count", buf);
    
    TeleportEntity(entity, origins, angles, NULL_VECTOR);
    DispatchSpawn(entity);
    SetEntityMoveType(entity,MOVETYPE_NONE);
    return entity;
}
