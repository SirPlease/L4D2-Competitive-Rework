#if defined _l4d2lib_rounds_included
	#endinput
#endif
#define _l4d2lib_rounds_included

/* Global Vars */
static Handle
	g_hFwdRoundStart = null,
	g_hFwdRoundEnd = null;

static int
	g_iRoundNumber = 0;

static bool
	g_bInRound = false;

void Rounds_AskPluginLoad2()
{
	CreateNative("L4D2_GetCurrentRound", _native_GetCurrentRound); //never used
	CreateNative("L4D2_CurrentlyInRound", _native_CurrentlyInRound); //never used

	g_hFwdRoundStart = CreateGlobalForward("L4D2_OnRealRoundStart", ET_Ignore, Param_Cell); // Commented out in Confoglcompmod (ItemTracking);
	g_hFwdRoundEnd = CreateGlobalForward("L4D2_OnRealRoundEnd", ET_Ignore, Param_Cell); //never used
}

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

public int _native_GetCurrentRound(Handle hPlugin, int iNumParams)
{
	return g_iRoundNumber;
}

public int _native_CurrentlyInRound(Handle hPlugin, int iNumParams)
{
	return g_bInRound;
}
