#pragma semicolon 1

#include <sdktools>

new g_precachedIndex;

public OnPluginStart()
{
	g_precachedIndex = PrecacheDecal("materials/decals/metal/metal01b.vtf", true);
	HookEvent("bullet_impact", BulletImpactEvent);
}

public Action:BulletImpactEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl Float:pos[3];

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	pos[0] = GetEventFloat(event, "x");
	pos[1] = GetEventFloat(event, "y");
	pos[2] = GetEventFloat(event, "z");

	TE_Start("BSP Decal");
	TE_WriteVector("m_vecOrigin", pos);
	TE_WriteNum("m_nEntity", 0);
	TE_WriteNum("m_nIndex", g_precachedIndex);
	TE_SendToClient(client);
}