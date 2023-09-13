#include <sourcemod>
#include <sdkhooks>
#include <sdktools_functions>

#define REQUIRE_EXTENSIONS
#include <dhooks>

// Fixed issues:
// - It's possible to get a second melee from same spawner with empty counter before it is removed from the game (same should work with other spawners)

#define GAMEDATA_FILE "weapon_spawn_duplicate_fix"

Handle g_hCWeaponSpawn_GiveItem = null;
ArrayStack g_hItems = null;

public MRESReturn Handler_CWeaponSpawn_GiveItem(int spawner, Handle hReturn)
{
	if (GetEntProp(spawner, Prop_Data, "m_itemCount") == 0) {
		DHookSetReturn(hReturn, false);
        
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

void CheckClassAndHook(int entity)
{
	char className[64];
	if (!GetEntityNetClass(entity, className, sizeof(className))) {
		return;
	}
    
	if (strcmp(className, "CWeaponSpawn") != 0) {
		return;
	}

	// Remember to unhook later
	g_hItems.Push(DHookEntity(g_hCWeaponSpawn_GiveItem, false, entity));
}

public void OnEntityCreated(int entity, const char[] className)
{
	if (strncmp(className, "weapon_", 7, false) != 0) {
		return;
	}

	CheckClassAndHook(entity);
}

public void OnMapEnd()
{
	// Unhook entities
	while (!g_hItems.Empty) {
		DHookRemoveHookID(g_hItems.Pop());
	}
}

void LoadGameConfigOrFail()
{
	Handle gc = LoadGameConfigFile(GAMEDATA_FILE);
	if (gc == null) {
		SetFailState("Failed to load gamedata file \"" ... GAMEDATA_FILE ... "\"");
	}

	int offset = GameConfGetOffset(gc, "CWeaponSpawn::GiveItem");

	delete gc;

	if (offset == -1) {
		SetFailState("Unable to get offset for \"CWeaponSpawn::GiveItem\" from game config (file: \"" ... GAMEDATA_FILE ... ".txt\")");
	}

	g_hCWeaponSpawn_GiveItem = DHookCreate(offset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, Handler_CWeaponSpawn_GiveItem);
	if (g_hCWeaponSpawn_GiveItem == null) {
		SetFailState("Unable to hook \"CWeaponSpawn::GiveItem\" (given offset: %d)", offset);
	}

	DHookAddParam(g_hCWeaponSpawn_GiveItem, HookParamType_CBaseEntity);
	DHookAddParam(g_hCWeaponSpawn_GiveItem, HookParamType_Int);
}

public void OnPluginStart()
{
	LoadGameConfigOrFail();

	g_hItems = new ArrayStack();

	int entity = INVALID_ENT_REFERENCE;
	while ((entity = FindEntityByClassname(entity, "weapon_*")) != INVALID_ENT_REFERENCE) {
		CheckClassAndHook(entity);
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() == Engine_Left4Dead2) {
		return APLRes_Success;
	}
    
	strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");

	return APLRes_SilentFailure;
}

public Plugin myinfo =
{
	name = "[L4D2] Weapon Duplicate Fix",
	author = "shqke",
	description = "Prevents a weapon to be taken from weapon spawn if its item counter has hit a zero",
	version = "1.1",
	url = "https://github.com/shqke/sp_public"
};