#if defined _l4d2util_tanks_included_
	#endinput
#endif
#define _l4d2util_tanks_included_

static Handle
	hFwdOnTankPunchHittable = null,
	hFwdOnTankSpawn = null,
	hFwdOnTankPass = null,
	hFwdOnTankDeath = null;

static ArrayList
	hTankClients = null;

void L4D2Util_Tanks_CreateForwards()
{
	hFwdOnTankPunchHittable = CreateGlobalForward("OnTankPunchHittable", ET_Ignore, Param_Cell, Param_Cell);
	hFwdOnTankSpawn = CreateGlobalForward("OnTankSpawn", ET_Ignore, Param_Cell);
	hFwdOnTankPass = CreateGlobalForward("OnTankPass", ET_Ignore, Param_Cell, Param_Cell);
	hFwdOnTankDeath = CreateGlobalForward("OnTankDeath", ET_Ignore, Param_Cell);
}

static void RemoveTankFromArray(int iClient)
{
	for (int i = 0; i < hTankClients.Length; ++i) {
		if (hTankClients.Get(i) == iClient) {
			hTankClients.Erase(i); 
		}
	}
}

static bool FindTankInArray(int iClient)
{
	int iSize = hTankClients.Length;
	
	for (int i = 0; i < iSize; ++i) {
		if (hTankClients.Get(i) == iClient) {
			return true;
		}
	}

	return false;
}

void L4D2Util_Tanks_Init()
{
	hTankClients = new ArrayList();
}

void L4D2Util_Tanks_OnRoundStart()
{
	hTankClients.Clear();
	
	CreateTimer(0.1, Timer_HookProps, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_HookProps(Handle hTimer)
{
	int iEntity = -1;

	while ((iEntity = FindEntityByClassname(iEntity, "prop_physics")) != -1) {
		if (IsTankHittable(iEntity)) {
			HookSingleEntityOutput(iEntity, "OnHitByTank", TankHittablePunched);
		}
	}

	iEntity = -1;

	while ((iEntity = FindEntityByClassname(iEntity, "prop_alarm_car")) != -1) {
		HookSingleEntityOutput(iEntity, "OnHitByTank", TankHittablePunched);
	}
}

public void TankHittablePunched(const char[] output, int caller, int activator, float delay)
{
	Call_StartForward(hFwdOnTankPunchHittable);
	Call_PushCell(activator);
	Call_PushCell(caller);
	Call_Finish();
}

// The tank_spawn hook is called when the tanks spawns(!), but also when the
// tank passes from AI to a player or from a player to AI.
void L4D2Util_Tanks_TankSpawn(int iClient)
{
	int iNumTanks = NumTanksInPlay();

	if (hTankClients.Length < iNumTanks) {
		hTankClients.Push(iClient);
		
		Call_StartForward(hFwdOnTankSpawn);
		Call_PushCell(iClient);
		Call_Finish();
	}
}

void L4D2Util_Tanks_PlayerDeath(int iClient)
{
	if (iClient == 0) {
		return;
	}

	if (!IsTank(iClient)) {
		return;
	}

	CreateTimer(0.1, L4D2Util_Tanks_TankDeathDelay, iClient, TIMER_FLAG_NO_MAPCHANGE);
}

public Action L4D2Util_Tanks_TankDeathDelay(Handle hTimer, any iOldTankClient)
{
	int iTankClient = -1, iClient = -1;

	while ((iClient = FindTankClient(iClient)) != -1) {
		if (!FindTankInArray(iClient)) {
			iTankClient = iClient;
			break;
		}
	}

	RemoveTankFromArray(iOldTankClient);

	if (iTankClient != -1) {
		hTankClients.Push(iClient);
		
		Call_StartForward(hFwdOnTankPass);
		Call_PushCell(iTankClient);
		Call_PushCell(iOldTankClient);
		Call_Finish();
		return Plugin_Stop;
	}

	Call_StartForward(hFwdOnTankDeath);
	Call_PushCell(iOldTankClient);
	Call_Finish();
}
