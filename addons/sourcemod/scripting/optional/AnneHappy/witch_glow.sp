#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define VERSION "0.2"

ConVar CvarGlowMinRange, CvarGlowMaxRange;
int g_iGlowMinRange, g_iGlowMaxRange;

public Plugin myinfo =
{
	name = "L4D2 Witch glow",
	author = "fdxx",
	description = "",
	version = VERSION,
	url = ""
}

public void OnPluginStart()
{
	CreateConVar("l4d2_witch_glow_version", VERSION, "插件版本", FCVAR_NONE | FCVAR_DONTRECORD);

	CvarGlowMinRange = CreateConVar("l4d2_witch_glow_min_range", "500", "发光最小距离", FCVAR_NONE);
	CvarGlowMaxRange = CreateConVar("l4d2_witch_glow_max_range", "2000", "发光最大距离", FCVAR_NONE);

	g_iGlowMinRange = CvarGlowMinRange.IntValue;
	g_iGlowMaxRange = CvarGlowMaxRange.IntValue;

	CvarGlowMinRange.AddChangeHook(ConVarChanged);
	CvarGlowMaxRange.AddChangeHook(ConVarChanged);

	HookEvent("witch_spawn", Event_WitchSpawn);
	HookEvent("witch_harasser_set", Event_WitchHarasserSet);
	HookEvent("witch_killed", Event_Witchkilled, EventHookMode_Pre);

}

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iGlowMinRange = CvarGlowMinRange.IntValue;
	g_iGlowMaxRange = CvarGlowMaxRange.IntValue;
}

public void Event_WitchSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int iWitch = event.GetInt("witchid");
	SetGlow(iWitch);
}

public void Event_WitchHarasserSet(Event event, const char[] name, bool dontBroadcast)
{
	int iWitch = event.GetInt("witchid");
	RestGlow(iWitch);
}

public Action Event_Witchkilled(Event event, const char[] name, bool dontBroadcast)
{
	int iWitch = event.GetInt("witchid");
	RestGlow(iWitch);
	return Plugin_Continue;
}

void SetGlow(int iWitch)
{
	SetEntProp(iWitch, Prop_Send, "m_iGlowType", 3);
	SetEntProp(iWitch, Prop_Send, "m_glowColorOverride", 16777215);
	SetEntProp(iWitch, Prop_Send, "m_nGlowRangeMin", g_iGlowMinRange);
	SetEntProp(iWitch, Prop_Send, "m_nGlowRange", g_iGlowMaxRange);
}

void RestGlow(int iWitch)
{
	SetEntProp(iWitch, Prop_Send, "m_iGlowType", 0);
	SetEntProp(iWitch, Prop_Send, "m_glowColorOverride", 0);
	SetEntProp(iWitch, Prop_Send, "m_nGlowRangeMin", 0);
	SetEntProp(iWitch, Prop_Send, "m_nGlowRange", 0);
}