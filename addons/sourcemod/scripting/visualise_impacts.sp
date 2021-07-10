#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define DECAL_NAME "materials/decals/metal/metal01b.vtf"

int g_precachedIndex;

public void OnPluginStart()
{
	g_precachedIndex = PrecacheDecal(DECAL_NAME, true);
	
	HookEvent("bullet_impact", BulletImpactEvent);
}

public void OnMapStart()
{
	if (!IsDecalPrecached(DECAL_NAME)) {
		g_precachedIndex = PrecacheDecal(DECAL_NAME, true); //true or false?
	}
}

public void BulletImpactEvent(Event hEvent, const char[] name, bool dontBroadcast)
{
	float pos[3];

	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	
	pos[0] = hEvent.GetFloat("x");
	pos[1] = hEvent.GetFloat("y");
	pos[2] = hEvent.GetFloat("z");

	TE_Start("BSP Decal");
	TE_WriteVector("m_vecOrigin", pos);
	TE_WriteNum("m_nEntity", 0);
	TE_WriteNum("m_nIndex", g_precachedIndex);
	TE_SendToClient(client);
}
