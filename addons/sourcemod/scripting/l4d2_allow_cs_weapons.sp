#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>

#define GAMEDATA "l4d2_allow_cs_weapons"

public Plugin myinfo =
{
	name = "[L4D2] Allow CS weapons on every map.",
	author = "Sir",
	description = "Force weapon spawners to ignore the 'no_cs_weapons' KeyValue, allowing for CS weapons on every map.",
	version = "1.0"
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

MRESReturn DirectorItemManager_AreCSWeaponsAllowed(DHookReturn hReturn)
{
	hReturn.Value = true;
	return MRES_Supercede;
}
