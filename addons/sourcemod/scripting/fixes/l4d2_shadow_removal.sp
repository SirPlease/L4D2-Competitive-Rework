#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name = "L4D2 Shadow Removal",
	author = "Sir",
	description = "A plugin that removes Shadows so that Survivors can't see Infected Players their shadows through walls and the like.",
	version = "1.1",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnMapStart()
{
	CreateEntityByName("shadow_control");

	int iEnt = -1;
	while((iEnt = FindEntityByClassname(iEnt, "shadow_control")) != -1) {
		SetVariantInt(1);
		AcceptEntityInput(iEnt, "SetShadowsDisabled");
	}
}
