#if defined l4d2util_weapons_inc_
	#endinput
#endif
#define l4d2util_weapons_inc_

#include <sdktools>
#include <l4d2util_constants>

#define GETWEAPONNAME(%0) (IsValidWeaponId(%0) ? (WeaponNames[%0]) : "")
#define GETLONGWEAPONNAME(%0) (IsValidWeaponId(%0) ? (LongWeaponNames[%0]) : "")
#define GETMELEEWEAPONNAME(%0) (IsValidMeleeWeaponId(%0) ? (MeleeWeaponNames[%0]) : "")
#define GETLONGMELEEWEAPONNAME(%0) (IsValidMeleeWeaponId(%0) ? (LongMeleeWeaponNames[%0]) : "")
#define GETWEAPONMODEL(%0) (HasValidWeaponModel(%0) ? (WeaponModels[%0]) : "")
#define GETMELEEWEAPONMODEL(%0) (HasValidMeleeWeaponModel(%0) ? (MeleeWeaponModels[%0]) : "")

stock static StringMap hWeaponNamesTrie = null;
stock static StringMap hMeleeWeaponNamesTrie = null;
stock static StringMap hMeleeWeaponModelsTrie = null;

stock void InitWeaponNamesTrie()
{
	hWeaponNamesTrie = new StringMap();

	for (int i = 0; i < WEPID_SIZE; i++) {
		hWeaponNamesTrie.SetValue(WeaponNames[i], i);
	}

	hMeleeWeaponNamesTrie = new StringMap();
	hMeleeWeaponModelsTrie = new StringMap();

	for (int i = 0; i < WEPID_MELEES_SIZE; i++) {
		hMeleeWeaponNamesTrie.SetValue(MeleeWeaponNames[i], i);
		hMeleeWeaponModelsTrie.SetString(MeleeWeaponModels[i], MeleeWeaponNames[i]);
	}
}

/**
 * Initializes internal structure necessary for weapons.inc functions
 * @remark It is recommended that you run this function on plugin start, but not necessary
 *
 * @noreturn
 */
stock void L4D2Weapons_Init()
{
	if (hWeaponNamesTrie == null) {
		InitWeaponNamesTrie();
	}
}

/**
 * Performs bounds checking to determine if a WeaponId is valid
 * @remark Simple check to see if wepid has a garbage value
 *
 * @param wepid        WeaponId to check for validity
 * @return True if wepid is valid, false otherwise.
 */
stock bool IsValidWeaponId(int wepid)
{
	return (wepid >= WEPID_NONE && wepid < WEPID_SIZE);
}

/**
 * Performs bounds checking to determine if a MeleeWeaponId is valid
 * @remark Simple check to see if wepid has a garbage value
 *
 * @param wepid        MeleeWeaponId to check for validity
 * @return True if wepid is valid, false otherwise.
 */
stock bool IsValidMeleeWeaponId(int wepid)
{
	return (wepid >= WEPID_MELEE_NONE && wepid < WEPID_MELEES_SIZE);
}

/**
 * Checks to see if a given meleeweaponid has a known WeaponModel in this file's model array
 *
 * @param wepid        MeleeWeaponId to check for a known weapon model for.
 * @return True if a valid weapon model exists for wepid, false otherwise.
 */
stock bool HasValidMeleeWeaponModel(int wepid)
{
	return (IsValidMeleeWeaponId(wepid) && MeleeWeaponModels[wepid][0] != '\0');
}

/**
 * Get the player weapon slot used by the given WeaponId.
 * 
 * @param wepid     WeaponId to get the slot for.
 * @return Slot number (0-4) or -1 for invalid WeaponId or no slot
 */
stock int GetSlotFromWeaponId(int wepid)
{
	return (IsValidWeaponId(wepid)) ? WeaponSlots[wepid] : -1;
}

/**
 * Checks to see if a given weaponid has a known WeaponModel in this file's model array
 * @remark Some weapons (like weapon_melee) have multiple valid models, and this will report false for them.
 *
 * @param wepid        WeaponId to check for a known weapon model for.
 * @return True if a valid weapon model exists for wepid, false otherwise.
 */
stock bool HasValidWeaponModel(int wepid)
{
	return (IsValidWeaponId(wepid) && WeaponModels[wepid][0] != '\0');
}

/**
 * Tries to look up a WeaponId for a given Weapon Name.
 *
 * @param weaponName    Weapon name string to look up Id from
 * @return int          The corresponding WeaponId if found, else WEPID_NONE
 */
stock int WeaponNameToId(const char[] weaponName)
{
	if (hWeaponNamesTrie == null) {
		InitWeaponNamesTrie();
	}
	
	int id;
	if (hWeaponNamesTrie.GetValue(weaponName, id)) {
		return id;
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
stock void GetWeaponName(int wepid, char[] nameBuffer, const int length)
{
	strcopy(nameBuffer, length, GETWEAPONNAME(wepid));
}

/**
 * Tries to look up L4D2's internal weapon name for a given MeleeWeaponId.
 *
 * @param wepid            MeleeWeaponId To get name of.
 * @param nameBuffer    String buffer to write the weapon name to.
 * @param length        Max length which can be written to the buffer.
 * @return                Number of bytes written to buffer, or 0 for invalid weaponId.
 */
stock void GetMeleeWeaponName(int wepid, char[] nameBuffer, const int length)
{
	strcopy(nameBuffer, length, GETMELEEWEAPONNAME(wepid));
}

/**
 * Tries to look up L4D2's internal weapon name for a given WeaponId.
 *
 * @param wepid            WeaponId To get name of.
 * @param nameBuffer    String buffer to write the weapon name to.
 * @param length        Max length which can be written to the buffer.
 * @return                Number of bytes written to buffer, or 0 for invalid weaponId.
 */
stock void GetLongWeaponName(int wepid, char[] nameBuffer, const int length)
{
	strcopy(nameBuffer, length, GETLONGWEAPONNAME(wepid));
}

/**
 * Tries to look up L4D2's internal weapon name for a given MeleeWeaponId.
 *
 * @param wepid            MeleeWeaponId To get name of.
 * @param nameBuffer    String buffer to write the weapon name to.
 * @param length        Max length which can be written to the buffer.
 * @return                Number of bytes written to buffer, or 0 for invalid weaponId.
 */
stock void GetLongMeleeWeaponName(int wepid, char[] nameBuffer, const int length)
{
	strcopy(nameBuffer, length, GETLONGMELEEWEAPONNAME(wepid));
}

/**
 * Tries to look up the weapon model for a given MeleeWeaponId.
 * @remarks You should use HasValidWeaponModel to make sure the MeleeWeaponId you're looking up has a valid model associated with it.
 *
 * @param wepid            MeleeWeaponId To get name of.
 * @param nameBuffer    String buffer to write the weapon name to.
 * @param length        Max length which can be written to the buffer.
 * @return                Number of bytes written to buffer, or 0 for invalid weaponid or no weapon model available.
 */
stock void GetMeleeWeaponModel(int wepid, char[] modelBuffer, const int length)
{
	strcopy(modelBuffer, length, GETMELEEWEAPONMODEL(wepid));
}

// Helper function used for getting an entity's internal melee name
stock bool GetMeleeWeaponNameFromEntity(int entity, char[] buffer, const int length)
{
	char classname[64];
	if (!GetEdictClassname(entity, classname, sizeof(classname))) {
		return false;
	}

	if (StrEqual(classname, "weapon_melee_spawn")) {
		if (hMeleeWeaponModelsTrie == null) {
			InitWeaponNamesTrie();
		}

		char sModelName[PLATFORM_MAX_PATH];
		GetEntPropString(entity, Prop_Data, "m_ModelName", sModelName, sizeof(sModelName));

		// Strip models directory
		if (strncmp(sModelName, "models/", 7, false) == 0) {
			strcopy(sModelName, sizeof(sModelName), sModelName[6]);
		}

		if (hMeleeWeaponModelsTrie.GetString(sModelName, buffer, length)) {
			return true;
		}
		
		return false;
	} else if (StrEqual(classname, "weapon_melee")) {
		GetEntPropString(entity, Prop_Data, "m_strMapSetScriptName", buffer, length);
		return true;
	}

	return false;
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
stock void GetWeaponModel(int wepid, char[] modelBuffer, const int length)
{
	strcopy(modelBuffer, length, GETWEAPONMODEL(wepid));
}

/**
 * Identifies a weapon spawn or weapon entity as a WeaponID
 * @remark Should work on most weapon ents--even spawns, singles, held, etc.
 *
 * @param entity        Index of entity to identify
 * @return int for the entity if it is a weapon, WEPID_NONE otherwise
 */
stock int IdentifyWeapon(int entity)
{
	if (!entity || !IsValidEntity(entity) || !IsValidEdict(entity)) {
		return WEPID_NONE;
	}

	char class[64];
	if (!GetEdictClassname(entity, class, sizeof(class))) {
		return WEPID_NONE;
	}

	if (strcmp(class, "weapon_spawn") == 0) {
		return GetEntProp(entity, Prop_Send, "m_weaponID");
	}

	int len = strlen(class);
	int len2 = len - 6;
	if (len2 > 0 && strcmp(class[len2], "_spawn") == 0) {
		class[len2] = '\0';
		return WeaponNameToId(class);
	}

	return WeaponNameToId(class);
}

/**
 * Identifies a melee weapon spawn or weapon entity as a MeleeWeaponId
 * @remark Should work on most weapon ents--even spawns, singles, held, etc.
 *
 * @param entity		Index of entity to identify
 * @return int			for the entity if it is a weapon, WEPID_MELEE_NONE otherwise
 */
stock int IdentifyMeleeWeapon(int entity)
{
	if (IdentifyWeapon(entity) != WEPID_MELEE) {
		return WEPID_MELEE_NONE;
	}

	char sName[64];
	if (!GetMeleeWeaponNameFromEntity(entity, sName, sizeof(sName))) {
		return WEPID_MELEE_NONE;
	}

	if (hMeleeWeaponNamesTrie == null) {
		InitWeaponNamesTrie();
	}

	int id;
	if (hMeleeWeaponNamesTrie.GetValue(sName, id)) {
		return id;
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
stock int ConvertWeaponSpawn(int entity, int wepid, int count = 5, const char[] model = "")
{
	if (!IsValidEntity(entity)) {
		return -1;
	}
	
	if (!IsValidWeaponId(wepid)) {
		return -1;
	}
	
	if (model[0] == '\0' && !HasValidWeaponModel(wepid)) {
		return -1;
	}

	float origins[3], angles[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origins);
	GetEntPropVector(entity, Prop_Send, "m_angRotation", angles);

	AcceptEntityInput(entity, "kill");

	entity = CreateEntityByName("weapon_spawn");
	if (!IsValidEntity(entity)) {
		return -1;
	}
	
	SetEntProp(entity, Prop_Send, "m_weaponID", wepid);

	char buf[PLATFORM_MAX_PATH - 16], modelName[PLATFORM_MAX_PATH];
	if (model[0] != '\0') {
		SetEntityModel(entity, model);
	} else {
		GetWeaponModel(wepid, buf, sizeof(buf));
		Format(modelName, sizeof(modelName), "models%s", buf);
		SetEntityModel(entity, modelName);
	}
	
	IntToString(count, buf, sizeof(buf));
	DispatchKeyValue(entity, "count", buf);

	TeleportEntity(entity, origins, angles, NULL_VECTOR);
	DispatchSpawn(entity);
	SetEntityMoveType(entity, MOVETYPE_NONE);

	return entity;
}
