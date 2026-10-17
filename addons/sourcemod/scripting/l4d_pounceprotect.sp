#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>

int
	iPounceBudgetOffset,
	iLungeDamagedOffset;

public Plugin myinfo =
{
	name		= "L4D2 Pounce Protect",
	author		= "ProdigySim, Sir",
	description	= "Prevent damage from blocking a hunter's ability to pounce",
	version		= "2.0",
	url			= "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	// Pounce damage interrupt budget
	iPounceBudgetOffset = FindSendPropInfo("CTerrorPlayer", "m_isAttemptingToPounce") + 4;

	// Set when hit mid-lunge, blocks lunging again off walls
	iLungeDamagedOffset = FindSendPropInfo("CLunge", "m_isLunging") + 1;

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			OnClientPutInServer(i);
		}
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
}

Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	/*
		Damage still counts towards z_pounce_damage_interrupt for ~0.1s after a pounce ends (and hasn't been skeeted)
		If the pounce damage + the buffer reaches z_pounce_damage_interrupt, the hunter is stunned for ~0.5s.
		The budget is reset at the start of every pounce, so setting it to a high value doesn't affect skeets.
	*/
	if (IsClientInGame(victim) && IsHunter(victim) && !GetEntProp(victim, Prop_Send, "m_isAttemptingToPounce") && GetEntPropEnt(victim, Prop_Send, "m_pounceVictim") == -1) {
		SetEntData(victim, iPounceBudgetOffset, 999999);
	}

	return Plugin_Continue;
}

void OnTakeDamagePost(int victim, int attacker, int inflictor, float damage, int damagetype)
{
	// The damage flag only gets read when lunging again, so clearing it after the damage is enough (no need for gamedata)
	if (IsClientInGame(victim) && IsHunter(victim)) {
		int ability = GetEntPropEnt(victim, Prop_Send, "m_customAbility");
		if (ability != -1) {
			SetEntData(ability, iLungeDamagedOffset, 0, 1);
		}
	}
}

bool IsHunter(int client)
{
	return GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 3;
}
