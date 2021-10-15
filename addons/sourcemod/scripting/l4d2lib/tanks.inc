#if defined _l4d2lib_tanks_included
	#endinput
#endif
#define _l4d2lib_tanks_included

/* Global Vars */
Handle
	g_hFwdFirstTankSpawn = null,
	g_hFwdTankPassControl = null,
	g_hFwdTankDeath = null,
	g_hTankDeathTimer = null;

static bool
	g_bIsTankActive = false;

static int
	g_iTankClient = -1,
	g_iTankPassCount = 0;

void ResetStatus()
{
	g_bIsTankActive = false;
	g_iTankClient = -1;
	g_iTankPassCount = 0;

	if (g_hTankDeathTimer != null) {
		KillTimer(g_hTankDeathTimer);
		g_hTankDeathTimer = null;
	}
}

void Tanks_OnMapStart()
{
	ResetStatus();
}

void Tanks_RoundStart()
{
	ResetStatus();
}

void Tanks_TankSpawn(Event hEvent)
{
	if (g_bIsTankActive) {
		return;
	}

	g_bIsTankActive = true;

	g_iTankClient = GetClientOfUserId(hEvent.GetInt("userid"));

	Call_StartForward(g_hFwdFirstTankSpawn);
	Call_PushCell(g_iTankClient);
	Call_Finish();
}

void Tanks_ItemPickup(Event hEvent)
{
	if (!g_bIsTankActive) {
		return;
	}

	char sItem[64];
	hEvent.GetString("item", sItem, sizeof(sItem));

	if (strcmp(sItem, "tank_claw") == 0) {
		int iPrevTank = g_iTankClient;
		g_iTankClient = GetClientOfUserId(hEvent.GetInt("userid"));

		if (g_hTankDeathTimer != null) {
			KillTimer(g_hTankDeathTimer);
			g_hTankDeathTimer = null;
		}

		Call_StartForward(g_hFwdTankPassControl);
		Call_PushCell(iPrevTank);
		Call_PushCell(g_iTankClient);
		Call_PushCell(g_iTankPassCount);
		Call_Finish();

		g_iTankPassCount++;
	}
}

void Tanks_PlayerDeath(Event hEvent)
{
	if (!g_bIsTankActive) {
		return;
	}

	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if (iClient != g_iTankClient) {
		return;
	}

	g_hTankDeathTimer = CreateTimer(0.5, TankDeath_Timer);
}

public Action TankDeath_Timer(Handle hTimer)
{
	Call_StartForward(g_hFwdTankDeath);
	Call_PushCell(g_iTankClient);
	Call_Finish();

	ResetStatus();
}
