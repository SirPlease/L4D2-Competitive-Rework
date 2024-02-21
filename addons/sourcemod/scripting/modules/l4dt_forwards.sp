#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

public Action:L4D_OnSpawnTank(const Float:vector[3], const Float:qangle[3])
{
	if(GT_OnTankSpawn_Forward() == Plugin_Handled)
		return Plugin_Handled;
	BS_OnTankSpawn_Forward();
	return Plugin_Continue;
}

public Action:L4D_OnSpawnMob(&amount)
{
	if(GT_OnSpawnMob_Forward(amount) == Plugin_Handled)
		return Plugin_Handled;
	
	return Plugin_Continue;
}

public Action:L4D_OnTryOfferingTankBot(tank_index, &bool:enterStasis)
{
	if(GT_OnTryOfferingTankBot(enterStasis) == Plugin_Handled)
		return Plugin_Handled;
	return Plugin_Continue;
}

public Action:L4D_OnGetMissionVSBossSpawning(&Float:spawn_pos_min, &Float:spawn_pos_max, &Float:tank_chance, &Float:witch_chance)
{
	if (UB_OnGetMissionVSBossSpawning() == Plugin_Handled)
		return Plugin_Handled;
	return Plugin_Continue;
}

public Action:L4D_OnGetScriptValueInt(const String:key[], &retVal)
{
	if (UB_OnGetScriptValueInt(key, retVal) == Plugin_Handled)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:OFSLA_ForceMobSpawnTimer(Handle:timer)
{
	// Workaround to make tank horde blocking always work
	// Makes the first horde always start 100s after survivors leave saferoom
	static Handle:MobSpawnTimeMin, Handle:MobSpawnTimeMax;
	if(MobSpawnTimeMin == INVALID_HANDLE)
	{
		MobSpawnTimeMin = FindConVar("z_mob_spawn_min_interval_normal");
		MobSpawnTimeMax = FindConVar("z_mob_spawn_max_interval_normal");
	}
	L4D2_CTimerStart(L4D2CT_MobSpawnTimer, GetRandomFloat(GetConVarFloat(MobSpawnTimeMin), GetConVarFloat(MobSpawnTimeMax)));
}
public Action:L4D_OnFirstSurvivorLeftSafeArea(client)
{
	if(IsPluginEnabled())
	{
		CreateTimer(0.1, OFSLA_ForceMobSpawnTimer);
	}
	return Plugin_Continue;
}