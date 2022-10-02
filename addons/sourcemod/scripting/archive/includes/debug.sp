
#if DEBUG_ALL
#define DEBUG_DEFAULT "1"
#else
#define DEBUG_DEFAULT "0"
#endif

new bool:debug_confogl;

public Debug_OnModuleStart()
{
	new Handle:hDebugConVar = CreateConVarEx("debug", DEBUG_DEFAULT, "Turn on Debug Logging in all Confogl Modules");
	HookConVarChange(hDebugConVar, Debug_ConVarChange);
	debug_confogl = GetConVarBool(hDebugConVar);
}

public Debug_ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	debug_confogl = bool:StringToInt(newValue);
}

stock bool:IsDebugEnabled()
{
	return debug_confogl || DEBUG_ALL;
}