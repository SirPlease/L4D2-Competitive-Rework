#if defined _l4d2lib_survivors_included
	#endinput
#endif
#define _l4d2lib_survivors_included

/* Global Vars */
static int
	g_iSurvivorIndex[MAXPLAYERS + 1] = {0, ...},
	g_iSurvivorCount = 0;

void Survivors_AskPluginLoad2()
{
	CreateNative("L4D2_GetSurvivorCount", _native_GetSurvivorCount); //never used
	CreateNative("L4D2_GetSurvivorOfIndex", _native_GetSurvivorOfIndex); //never used
}

void Survivors_RebuildArray_Delay()
{
	CreateTimer(0.3, BuildArray_Timer);
}

public Action BuildArray_Timer(Handle hTimer)
{
	Survivors_RebuildArray();
}

void Survivors_RebuildArray()
{
	if (!IsServerProcessing()) {
		return;
	}

	g_iSurvivorCount = 0;

	for (int i = 1; i <= MaxClients; i++) {
		g_iSurvivorIndex[i] = 0;

		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i)) {
			g_iSurvivorIndex[g_iSurvivorCount] = i;
			g_iSurvivorCount++;
		}
	}
}

public int _native_GetSurvivorCount(Handle hPlugin, int iNumParams)
{
	return g_iSurvivorCount;
}

public int _native_GetSurvivorOfIndex(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);

	return g_iSurvivorIndex[iClient];
}
