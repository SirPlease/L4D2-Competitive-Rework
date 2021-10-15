#if defined _l4d2lib_rounds_included
	#endinput
#endif
#define _l4d2lib_rounds_included

/* Global Vars */
Handle
	g_hFwdRoundStart = null,
	g_hFwdRoundEnd = null;

static int
	g_iRoundNumber = 0;

static bool
	g_bInRound = false;

void Rounds_OnRoundStart_Update()
{
	if (!g_bInRound) {
		g_bInRound = true;
		g_iRoundNumber++;

		Call_StartForward(g_hFwdRoundStart);
		Call_PushCell(g_iRoundNumber);
		Call_Finish();
	}
}

void Rounds_OnRoundEnd_Update()
{
	if (g_bInRound) {
		g_bInRound = false;
		Call_StartForward(g_hFwdRoundEnd);
		Call_PushCell(g_iRoundNumber);
		Call_Finish();
	}
}

void Rounds_OnMapEnd_Update()
{
	g_iRoundNumber = 0;
	g_bInRound = false;
}

int GetCurrentRound()
{
	return g_iRoundNumber;
}

bool CurrentlyInRound()
{
	return g_bInRound;
}
