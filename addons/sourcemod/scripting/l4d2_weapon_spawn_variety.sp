#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#define L4D2UTIL_STOCKS_ONLY 1
#include <l4d2util>

#define MAX_SEL_LEN 32

bool g_bManaged[2049];
StringMap g_hSpawnResults;

public Plugin myinfo =
{
	name = "[L4D/2] T1 Weapon Spawn Variety",
	author = "Sir",
	description = "SMG/T1 shotgun spawners roll their tier pool (any_smg / tier1_shotgun), while keeping random weapon spawns identical between versus halves. (Does not overwrite enforced spawns)",
	version = "1.2"
};

public void OnPluginStart()
{
	g_hSpawnResults = new StringMap();
}

public void OnMapStart()
{
	g_hSpawnResults.Clear();
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (IsWeaponSpawnerClass(classname))
	{
		g_bManaged[entity] = false;
		SDKHook(entity, SDKHook_Spawn, OnSpawnerSpawn);
		SDKHook(entity, SDKHook_SpawnPost, OnSpawnerSpawnPost);
	}
}

/*
	Capture whether this spawner has a random selection, before the engine
	resolves and clears it (spawn_without_director spawns resolve inside Spawn()).
*/
Action OnSpawnerSpawn(int entity)
{
	g_bManaged[entity] = false;

	if (HasEntProp(entity, Prop_Data, "m_iszWeaponToSpawn"))
	{
		char sel[MAX_SEL_LEN];
		GetEntPropString(entity, Prop_Data, "m_iszWeaponToSpawn", sel, sizeof(sel));
		g_bManaged[entity] = IsManagedSelection(sel);
	}

	return Plugin_Continue;
}

void OnSpawnerSpawnPost(int entity)
{
	// Gamerules and entity creation not available yet at this stage, wait.
	RequestFrame(OnSpawnerSpawnPostFrame, EntIndexToEntRef(entity));
}

void OnSpawnerSpawnPostFrame(int ref)
{
	int entity = EntRefToEntIndex(ref);
	if (entity == INVALID_ENT_REFERENCE)
		return;

	/*
		Fixed T1 spawners become their tier pool so they roll the full set.
		Predefined (Stripper:Source) weapon_* placements and tier spots are not modified.
	*/
	char classname[64];
	GetEntityClassname(entity, classname, sizeof(classname));

	char pool[MAX_SEL_LEN];
	if (GetNativePoolSelection(classname, pool, sizeof(pool)))
	{
		ConvertToSelection(entity, pool);
		return;
	}

	if (!g_bManaged[entity])
		return;

	g_bManaged[entity] = false;

	float origin[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);

	char key[48];
	FormatEx(key, sizeof(key), "%.0f_%.0f_%.0f", origin[0], origin[1], origin[2]);

	int resolved = GetEntProp(entity, Prop_Send, "m_weaponID");
	int stored;

	if (InSecondHalfOfRound() && g_hSpawnResults.GetValue(key, stored))
	{
		if (stored != resolved)
			ConvertWeaponSpawn(entity, stored);
	}
	else
	{
		g_hSpawnResults.SetValue(key, resolved, true);
	}
}

// Random selections we keep consistent between halves: "any_*" and "tier*".
bool IsManagedSelection(const char[] sel)
{
	return (strncmp(sel, "any", 3) == 0 || strncmp(sel, "tier", 4) == 0);
}

bool GetNativePoolSelection(const char[] classname, char[] sel, int maxlen)
{
	if (StrEqual(classname, "weapon_smg_spawn") || StrEqual(classname, "weapon_smg_silenced_spawn"))
	{
		strcopy(sel, maxlen, "any_smg");
		return true;
	}

	if (StrEqual(classname, "weapon_pumpshotgun_spawn") || StrEqual(classname, "weapon_shotgun_chrome_spawn"))
	{
		strcopy(sel, maxlen, "tier1_shotgun");
		return true;
	}

	return false;
}

/*
	Replaces a spawner with a weapon_spawn using an engine selection.
	`spawn_without_director` makes the engine roll it inside DispatchSpawn, and the new entity re-enters our hooks.
*/
void ConvertToSelection(int entity, const char[] selection)
{
	float origin[3], angles[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
	GetEntPropVector(entity, Prop_Send, "m_angRotation", angles);

	int newent = CreateEntityByName("weapon_spawn");
	if (newent == -1)
		return;

	AcceptEntityInput(entity, "kill");

	DispatchKeyValue(newent, "weapon_selection", selection);
	DispatchKeyValue(newent, "spawn_without_director", "1");
	DispatchKeyValue(newent, "count", "5");
	TeleportEntity(newent, origin, angles, NULL_VECTOR);
	DispatchSpawn(newent);
}

bool IsWeaponSpawnerClass(const char[] classname)
{
	if (strncmp(classname, "weapon_", 7) != 0)
		return false;

	int len = strlen(classname);
	return len >= 12 && StrEqual(classname[len - 6], "_spawn");
}
