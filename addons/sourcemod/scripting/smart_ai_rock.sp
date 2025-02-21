#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>

public Plugin myinfo =
{
	name = "Smart AI Rock",
	author = "CanadaRox",
	description = "Prevents AI tanks from throwing underhand rocks since he can't aim them correctly",
	version = "1.1",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public Action L4D2_OnSelectTankAttack(int iClient, int &iSequence)
{
	if (IsFakeClient(iClient) && iSequence == 50) {
		iSequence = (GetRandomInt(0, 1)) ? 49 : 51;
		return Plugin_Handled;
	}

	return Plugin_Continue;
}
