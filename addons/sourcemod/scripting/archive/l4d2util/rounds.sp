#if defined _l4d2util_rounds_included_
	#endinput
#endif
#define _l4d2util_rounds_included_

static bool
	bInRound = false;

static Handle
	hFwdOnRoundStart = null,
	hFwdOnRoundEnd = null;

void L4D2Util_Rounds_CreateForwards()
{
	hFwdOnRoundStart = CreateGlobalForward("OnRoundStart", ET_Ignore);
	hFwdOnRoundEnd = CreateGlobalForward("OnRoundEnd", ET_Ignore);
}

void L4D2Util_Rounds_OnMapEnd()
{
	bInRound = false;
}

void L4D2Util_Rounds_OnRoundStart()
{
	if (!bInRound) {
		bInRound = true;
		Call_StartForward(hFwdOnRoundStart);
		Call_Finish();
	}
}

void L4D2Util_Rounds_OnRoundEnd()
{
	if (bInRound) {
		bInRound = false;
		Call_StartForward(hFwdOnRoundEnd);
		Call_Finish();
	}
}
