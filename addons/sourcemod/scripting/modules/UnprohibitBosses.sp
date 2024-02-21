#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

new Handle:UB_hEnable;
new bool:UB_bEnabled = true;

UB_OnModuleStart()
{
	UB_hEnable = CreateConVarEx("boss_unprohibit", "1", "Enable bosses spawning on all maps, even through they normally aren't allowed");
	
	HookConVarChange(UB_hEnable,UB_ConVarChange);
	
	UB_bEnabled = GetConVarBool(UB_hEnable);
}

public UB_ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	UB_bEnabled = GetConVarBool(UB_hEnable);
}

Action:UB_OnGetScriptValueInt(const String:key[], &retVal)
{
	if(IsPluginEnabled() && UB_bEnabled)
	{
		if(StrEqual(key, "DisallowThreatType"))
		{
			retVal = 0;
			return Plugin_Handled;
		}
		
		if(StrEqual(key, "ProhibitBosses"))
		{
			retVal = 0;
			return Plugin_Handled;		
		}
	}
	return Plugin_Continue;
}

Action:UB_OnGetMissionVSBossSpawning()
{
	if(UB_bEnabled)
	{
		decl String:mapbuf[32];
		GetCurrentMap(mapbuf, sizeof(mapbuf));
		if(StrEqual(mapbuf, "c7m1_docks") || StrEqual(mapbuf, "c13m2_southpinestream"))
		{
			return Plugin_Continue;
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
