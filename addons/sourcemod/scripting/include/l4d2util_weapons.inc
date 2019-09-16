#if defined l4d2_weapons_inc_
    #endinput
#endif
#define l4d2_weapons_inc_

#define GETWEAPONNAME(%0) (IsValidWeaponId(WeaponId:(%0)) ? (WeaponNames[_:(%0)]) : "")
#define GETWEAPONMODEL(%0) (HasValidWeaponModel(WeaponId:(%0)) ? (WeaponModels[_:(%0)]) : "")

static Handle:hWeaponNamesTrie = INVALID_HANDLE;
stock InitWeaponNamesTrie()
{
    hWeaponNamesTrie = CreateTrie();
    for(new i = 0; i < _:WeaponId; i++)
    {
        SetTrieValue(hWeaponNamesTrie, WeaponNames[WeaponId:i], i);
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
    if(model[0] != '\0')
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
