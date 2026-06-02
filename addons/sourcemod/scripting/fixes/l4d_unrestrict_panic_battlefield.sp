#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sourcescramble>

methodmap GameDataWrapper < GameData {
	public GameDataWrapper(const char[] file) {
		GameData gd = new GameData(file);
		if (!gd) SetFailState("Missing gamedata \"%s\"", file);
		return view_as<GameDataWrapper>(gd);
	}
	public MemoryPatch CreatePatchOrFail(const char[] name, bool enable = false) {
		MemoryPatch hPatch = MemoryPatch.CreateFromConf(this, name);
		if (!(enable ? hPatch.Enable() : hPatch.Validate()))
			SetFailState("Failed to patch \"%s\"", name);
		return hPatch;
	}
}

enum struct BattleFieldPatch
{
	// "SPAWN_SPECIALS_ANYWHERE" is preferred over "SPAWN_SPECIALS_IN_FRONT_OF_SURVIVORS"
	MemoryPatch GetRandomPZSpawnPosition;

	// Only collects spawn areas with "BATTLEFIELD" flag
	// Enabling this lets ZombieManager turn to "SurvivorActiveSet" for collecting spawn areas.
	MemoryPatch CollectSpawnAreas;

	// Never spawn Common Infected on spawning-disallowed areas
	// Enabling this may cause Common Infected spawning much closer.
	MemoryPatch AccumulateSpawnAreaCollection;

	void Enable()
	{
		this.GetRandomPZSpawnPosition.Enable();
		this.CollectSpawnAreas.Enable();
		this.AccumulateSpawnAreaCollection.Enable();
	}

	void Disable()
	{
		this.GetRandomPZSpawnPosition.Disable();
		this.CollectSpawnAreas.Disable();
		this.AccumulateSpawnAreaCollection.Disable();
	}
}
BattleFieldPatch g_BattleFieldPatch;

public void OnPluginStart()
{
	GameDataWrapper gd = new GameDataWrapper("l4d_unrestrict_panic_battlefield");

	g_BattleFieldPatch.GetRandomPZSpawnPosition = gd.CreatePatchOrFail("ZombieManager::GetRandomPZSpawnPosition__skip_PanicEventActive", false);
	g_BattleFieldPatch.CollectSpawnAreas = gd.CreatePatchOrFail("ZombieManager::CollectSpawnAreas__skip_PanicEventActive", false);
	g_BattleFieldPatch.AccumulateSpawnAreaCollection = gd.CreatePatchOrFail("ZombieManager::AccumulateSpawnAreaCollection__skip_PanicEventActive", false);

	delete gd;
}

stock void TogglePatch(bool toggle)
{
	toggle ? g_BattleFieldPatch.Enable() : g_BattleFieldPatch.Disable();
}
