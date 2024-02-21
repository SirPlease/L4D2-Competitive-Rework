#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>
#include <sdktools>

public Plugin myinfo =
{
	name = "L4D2 Fix Death Spit",
	author = "Jahze",
	description = "Removes invisible death spit",
	version = "1.1",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
}

public void OnPluginStart()
{
	HookEvent("spitter_killed", SpitterKilledEvent, EventHookMode_PostNoCopy);
}

public void SpitterKilledEvent(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	CreateTimer(1.0, FindDeathSpit, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action FindDeathSpit(Handle hTimer)
{
	int iEntity = -1, iMaxFlames = 0, iCurrentFlames = 0;

	while ((iEntity = FindEntityByClassname(iEntity, "insect_swarm")) != -1) {
		iMaxFlames = L4D2Direct_GetInfernoMaxFlames(iEntity);
		iCurrentFlames = GetEntProp(iEntity, Prop_Send, "m_fireCount");

		if (iMaxFlames == 2 && iCurrentFlames == 2) {
			SetEntProp(iEntity, Prop_Send, "m_fireCount", 1);
			L4D2Direct_SetInfernoMaxFlames(iEntity, 1);
		}
	}

	return Plugin_Stop;
}
