#include <sourcemod>

#if defined __rounds__
#endinput
#endif
#define __rounds__

/* Global Vars */
new Handle:hFwdRoundStart;
new Handle:hFwdRoundEnd;


static iRoundNumber=0;
static bool:bInRound;

Rounds_OnRoundStart_Update()
{
        if(!bInRound)
        {
                bInRound=true;
                iRoundNumber++;
                Call_StartForward(hFwdRoundStart);
                Call_PushCell(iRoundNumber);
                Call_Finish();
                
        }
}

Rounds_OnRoundEnd_Update()
{
        if(bInRound)
        {
                bInRound=false;
                Call_StartForward(hFwdRoundEnd);
                Call_PushCell(iRoundNumber);
                Call_Finish();
        }
}


Rounds_OnMapEnd_Update()
{
        iRoundNumber=0;
        bInRound=false;
}

GetCurrentRound()
{
        return iRoundNumber;
}

bool:CurrentlyInRound()
{
        return bInRound;
}
