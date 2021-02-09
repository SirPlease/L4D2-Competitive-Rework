#include <l4d2util_infected>
#pragma newdecls required
#include <sourcemod>

ConVar convarTongueDelay;
float fTongueDelay;

public Plugin myinfo = 
{
	name = "Tongue Timer",
	author = "Sir",
	description = "Modify the Smoker's tongue ability timer if it's a quick repull.",
	version = "1.0",
	url = "Nope"
}

public void OnPluginStart()
{
	convarTongueDelay = CreateConVar("l4d2_tongue_delay", "4.0", "How long of a cooldown does the Smoker get on a quick clear? (Vanilla = ~0.5s)");
	fTongueDelay = convarTongueDelay.FloatValue;
	convarTongueDelay.AddChangeHook(ConvarChanged);

	HookEvent("tongue_release", Event_TongueRelease);
}

public Action Event_TongueRelease(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidAliveSmoker(attacker)) 
	{
		float time = GetGameTime();
		float timestamp;
		float duration;
		if (!GetInfectedAbilityTimer(attacker, timestamp, duration)) return;

		// Duration will be used as the new "m_timestamp"
		// If the smoker's pull delay is already longer than what we want it to be, don't bother.
		duration = time + fTongueDelay;
		if (duration > timestamp) 
		{
			SetInfectedAbilityTimer(attacker, duration, fTongueDelay);
			// PrintToChatAll("[%s] - Ability Delay: \x03%.1f", name, fTongueDelay);
		}
	}
}

void ConvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	fTongueDelay = convarTongueDelay.FloatValue;
}

bool IsValidAliveSmoker(int client) 
{ 
	if (client <= 0 
	|| client > MaxClients 
	|| !IsClientInGame(client) 
	|| !IsPlayerAlive(client) 
	|| GetClientTeam(client) != 3) return false; 
	return GetEntProp(client, Prop_Send, "m_zombieClass") == 1; 
} 
