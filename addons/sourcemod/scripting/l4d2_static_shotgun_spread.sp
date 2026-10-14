#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include "include/l4d_pellet_spread_customizer"

// You can use the visualise_impacts.smx plugin to test the resulting spread.
// It will render small purple boxes where the server-side pellets land.

ConVar g_hCvarRing1Bullets = null;
ConVar g_hCvarRing1Factor = null;
ConVar g_hCvarCenterPellet = null;

public Plugin myinfo =
{
	name = "L4D2 Static Shotgun Spread",
	author = "Jahze, Visor, A1m`, Rena, Forgetest",
	version = "2.0",
	description = "Apply circular pattern to shotgun spreads",
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
};

public void OnPluginStart()
{
	g_hCvarRing1Bullets = CreateConVar("sgspread_ring1_bullets", "3", "Number of bullets for the first ring, the remaining bullets will be in the second ring.");
	g_hCvarRing1Factor = CreateConVar("sgspread_ring1_factor", "2", "Determines how far or closer the bullets will be from the center for the first ring.");
	g_hCvarCenterPellet = CreateConVar("sgspread_center_pellet", "1", "Center pellet: 0 - off, 1 - on.", _, true, 0.0, true, 1.0);
}

public Action L4D_OnPelletFirstBullet(int weapon)
{
	return g_hCvarCenterPellet.BoolValue ? Plugin_Continue : Plugin_Handled;
}

public Action L4D_OnPelletSpread(int weapon, float &spread, int nPellet, int nMaxPellets)
{
	// For bullets on the first ring, divides the spread value by the factor.
	if (nPellet <= g_hCvarRing1Bullets.IntValue)
	{
		spread /= g_hCvarRing1Factor.FloatValue;
	}

	// For bullets on the second ring, sticks to the max spread value.

	return Plugin_Changed;
}

public Action L4D_OnPelletSpreadDir(int weapon, float &angle, int nPellet, int nMaxPellets)
{
	int numSlices = 0;
	if (nPellet <= g_hCvarRing1Bullets.IntValue)
	{
		numSlices = g_hCvarRing1Bullets.IntValue;
	}
	else
	{
		numSlices = nMaxPellets - g_hCvarRing1Bullets.IntValue;
	}
	
	// @Forgetest:
	// Not sure where the first pellet of ring should be. Actually no full understanding of the original ASM codes.
	// Keep it simple here, starting at 0.
	angle = 180.0 / numSlices * ((nPellet - 1) % numSlices); // "% numSlices" should be unnecessary, whatever.
	return Plugin_Changed;
}
