#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

ConVar
	si_restore_ratio = null;

public Plugin myinfo = 
{
	name = "Despawn Health",
	author = "Jacob",
	description = "Gives Special Infected health back when they despawn.",
	version = "1.3.2",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
}

public void OnPluginStart()
{
	si_restore_ratio = CreateConVar( \
		"si_restore_ratio", \
		"0.5", \
		"How much of the clients missing HP should be restored? Zero or negative value disables it, 1.0 = Full HP.", \
		_, false, 0.0, true, 1.0 \
	);
}

public void L4D_OnEnterGhostState(int client)
{
	float fCvarValue = si_restore_ratio.FloatValue;
	if (fCvarValue > 0.0) {
		int CurrentHealth = GetClientHealth(client);
		int MaxHealth = GetEntProp(client, Prop_Send, "m_iMaxHealth");

		if (CurrentHealth < MaxHealth) {
			int MissingHealth = MaxHealth - CurrentHealth;
			int NewHP = RoundFloat(MissingHealth * fCvarValue) + CurrentHealth;

			SetEntityHealth(client, NewHP);
		}
	}
}
