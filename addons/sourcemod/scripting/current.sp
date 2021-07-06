#pragma semicolon 1

#include <sourcemod>
#include <left4dhooks>

#define MAX(%0,%1) (((%0) > (%1)) ? (%0) : (%1))

new Handle:g_hVsBossBuffer;

public Plugin:myinfo =
{
	name = "L4D2 Survivor Progress",
	author = "CanadaRox, Visor",
	description = "Print survivor progress in flow percents ",
	version = "2.0.1",
	url = "https://github.com/Attano/ProMod"
};

public OnPluginStart()
{
	g_hVsBossBuffer = FindConVar("versus_boss_buffer");

	RegConsoleCmd("sm_cur", CurrentCmd);
	RegConsoleCmd("sm_current", CurrentCmd);
}

public Action:CurrentCmd(client, args)
{
	new boss_proximity = RoundToNearest(GetBossProximity() * 100.0);
	PrintToChat(client, "\x01Current: \x04%d%%", boss_proximity);
	return Plugin_Handled;
}

Float:GetBossProximity()
{
	new Float:proximity = GetMaxSurvivorCompletion() + GetConVarFloat(g_hVsBossBuffer) / L4D2Direct_GetMapMaxFlowDistance();
	new Float:var1;
	if (proximity > 1.0)
	{
		var1 = 1.0;
	}
	else
	{
		var1 = proximity;
	}
	return var1;
}

Float:GetMaxSurvivorCompletion()
{
	new Float:flow = 0.0;
	decl Float:tmp_flow;
	decl Float:origin[3];
	decl Address:pNavArea;
	new client = 1;
	while (client <= MaxClients)
	{
		if (IsClientInGame(client) && GetClientTeam(client) == 2)
		{
			GetClientAbsOrigin(client, origin);
			pNavArea = L4D2Direct_GetTerrorNavArea(origin, 120.0);
			if (pNavArea)
			{
				tmp_flow = L4D2Direct_GetTerrorNavAreaFlow(pNavArea);
				new Float:var2;
				if (flow > tmp_flow)
				{
					var2 = flow;
				}
				else
				{
					var2 = tmp_flow;
				}
				flow = var2;
			}
		}
		client++;
	}
	return flow / L4D2Direct_GetMapMaxFlowDistance();
}