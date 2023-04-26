#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <readyup>
#include <pause>
#include <l4d2_boss_percents>

#define TEAM_SURVIVORS 2
#define ALERT_MIN_INTERVAL 15

ConVar g_hVsBossBuffer;

bool alertsOff;
bool mustAlert[ALERT_MIN_INTERVAL + 1];

public Plugin myinfo =
{
	name		= "L4D2 - Tank is comming",
	author		= "Altair Sossai",
	description = "Alerts all players that the tank is nearby",
	version		= "1.0.0",
	url			= "https://github.com/altair-sossai/l4d2-zone-server"
};

public void OnPluginStart()
{
	g_hVsBossBuffer = FindConVar("versus_boss_buffer");

	HookEvent("tank_spawn", TankSpawn, EventHookMode_PostNoCopy);

	ResetAlerts();

	CreateTimer(1.0, MapProgressTick, _, TIMER_REPEAT);
}

public void OnRoundIsLive()
{
	ResetAlerts();
}

public void TankSpawn(Event hEvent, const char[] eName, bool dontBroadcast)
{
	DisableAllAlerts();
}

public Action MapProgressTick(Handle timer)
{
	if (alertsOff || IsInReady() || IsInPause())
		return Plugin_Continue;

	int current = GetCurrentProgress();
	if(current <= 0)
		return Plugin_Continue;

	int tank = GetStoredTankPercent();
	if (tank <= 0 || current > tank)
		return Plugin_Continue;

	int remaining = tank - current + 1;
	
	if(remaining <= 0 || remaining > ALERT_MIN_INTERVAL || !mustAlert[remaining])
		return Plugin_Continue;

	PrintToChatAll("\x01Tank in: \x03%d%%", remaining);

	for (int i = ALERT_MIN_INTERVAL; i >= remaining; i--)
		mustAlert[i] = false;

	return Plugin_Continue;
}

public void ResetAlerts()
{
	alertsOff = false;
	
	for (int i = 0; i <= ALERT_MIN_INTERVAL; i++)
    	mustAlert[i] = i < 5 || i % 5 == 0;
}

public void DisableAllAlerts()
{
	alertsOff = true;

	for (int i = 0; i <= ALERT_MIN_INTERVAL; i++)
    	mustAlert[i] = false;
}

// *****************************************************
// Copied from current.sp, do not change
// *****************************************************

int GetCurrentProgress()
{
	return RoundToNearest(GetBossProximity() * 100.0);
}

float GetBossProximity()
{
	float proximity = GetMaxSurvivorCompletion() + g_hVsBossBuffer.FloatValue / L4D2Direct_GetMapMaxFlowDistance();

	return (proximity > 1.0) ? 1.0 : proximity;
}

float GetMaxSurvivorCompletion()
{
	float flow = 0.0, tmp_flow = 0.0, origin[3];
	Address pNavArea;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVORS) {
			GetClientAbsOrigin(i, origin);
			pNavArea = L4D2Direct_GetTerrorNavArea(origin);
			if (pNavArea != Address_Null) {
				tmp_flow = L4D2Direct_GetTerrorNavAreaFlow(pNavArea);
				flow = (flow > tmp_flow) ? flow : tmp_flow;
			}
		}
	}

	return (flow / L4D2Direct_GetMapMaxFlowDistance());
}

// *****************************************************
// END
// *****************************************************