#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <dhooks>

#define GAMEDATA "l4d2_allow_cs_weapons"

public Plugin myinfo =
{
	name = "[L4D2] Allow CS weapons on every map.",
	author = "Sir",
	description = "Force weapon spawners to ignore the 'no_cs_weapons' KeyValue, allowing for CS weapons on every map.",
	version = "1.1"
};

public void OnPluginStart()
{
	GameData hGameData = new GameData(GAMEDATA);
	if (hGameData == null)
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	DynamicDetour hDetour = DynamicDetour.FromConf(hGameData, "CDirectorItemManager::AreCSWeaponsAllowed");
	if (!hDetour)
		SetFailState("Missing signature \"CDirectorItemManager::AreCSWeaponsAllowed\"");
	if (!hDetour.Enable(Hook_Pre, DirectorItemManager_AreCSWeaponsAllowed))
		SetFailState("Failed to detour \"CDirectorItemManager::AreCSWeaponsAllowed\"");

	delete hDetour;
	delete hGameData;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (IsWeaponSpawnerClass(classname))
		SDKHook(entity, SDKHook_Spawn, WeaponSpawner_OnSpawn);
}

/*
	Must run before Spawn: spawners with "spawn_without_director" "1" pick their weapon
	inside Spawn() itself, and the entity-level KeyValue is checked before the detoured
	CDirectorItemManager::AreCSWeaponsAllowed ever runs, so it has to be cleared here.
*/
Action WeaponSpawner_OnSpawn(int entity)
{
	if (HasEntProp(entity, Prop_Data, "m_bNoCSWeapons"))
		SetEntProp(entity, Prop_Data, "m_bNoCSWeapons", 0);

	return Plugin_Continue;
}

// Matches "weapon_spawn" and every "weapon_<name>_spawn" spawner classname.
bool IsWeaponSpawnerClass(const char[] classname)
{
	if (strncmp(classname, "weapon_", 7) != 0)
		return false;

	int len = strlen(classname);
	return len >= 12 && StrEqual(classname[len - 6], "_spawn");
}

MRESReturn DirectorItemManager_AreCSWeaponsAllowed(DHookReturn hReturn)
{
	hReturn.Value = true;
	return MRES_Supercede;
}
