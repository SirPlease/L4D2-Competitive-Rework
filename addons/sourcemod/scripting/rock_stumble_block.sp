#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>

public Plugin myinfo =
{
	name = "Tank Rock Stumble Block",
	author = "Jacob, Forgetest",
	description = "Fixes rocks disappearing if tank gets stumbled while throwing.",
	version = "2.0",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

#define TEAM_INFECTED 3
#define Z_TANK 8

bool g_keepThrowing;
bool g_isLeft4Dead2;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	switch (GetEngineVersion())
	{
	case Engine_Left4Dead: g_isLeft4Dead2 = false;
	case Engine_Left4Dead2: g_isLeft4Dead2 = true;
	default:
		{
			strcopy(error, err_max, "Plugin supports L4D & 2 only");
			return APLRes_SilentFailure;
		}
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVarHook("rock_stumble_throwing",
				"1",
				"Whether to keep throwing rock even when stumbled.\n"
			...	"NOTE: if disabled, Tank will get huge movement penalty after stumbled for a few time.",
				FCVAR_SPONLY,
				true, 0.0, true, 1.0,
				CvarChg_KeepThrowing);
}

void CvarChg_KeepThrowing(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_keepThrowing = convar.BoolValue;
}

public Action L4D2_OnStagger(int client, int source)
{
	if (!g_keepThrowing)
		return Plugin_Continue;
	
	if (!IsClientInGame(client))
		return Plugin_Continue;
	
	if (!IsTank(client))
		return Plugin_Continue;
	
	int ability = GetEntPropEnt(client, Prop_Send, "m_customAbility");
	if (ability == -1)
		return Plugin_Continue;
	
	if (!CThrow__IsActive(ability) && !CThrow__SelectingTankAttack(ability))
		return Plugin_Continue;
	
	return Plugin_Handled;
}

public void L4D2_OnStagger_Post(int client, int source)
{
	if (g_keepThrowing)
		return;
	
	if (!IsClientInGame(client))
		return;
	
	if (!IsTank(client))
		return;
	
	int ability = GetEntPropEnt(client, Prop_Send, "m_customAbility");
	if (ability == -1)
		return;
	
	if (!CThrow__IsActive(ability) && !CThrow__SelectingTankAttack(ability))
		return;
	
	SetEntPropFloat(client, Prop_Send, "m_flCycle", 1.0);
}

bool CThrow__SelectingTankAttack(int ability)
{
	if (!g_isLeft4Dead2)
		return false;
	
	static int s_iOffs_m_bSelectingAttack = -1;
	if (s_iOffs_m_bSelectingAttack == -1)
		s_iOffs_m_bSelectingAttack = FindSendPropInfo("CThrow", "m_hasBeenUsed") + 28;
	
	return GetEntData(ability, s_iOffs_m_bSelectingAttack, 1) > 0;
}

bool CThrow__IsActive(int ability)
{
	CountdownTimer ct = CThrow__GetThrowTimer(ability);
	if (!CTimer_HasStarted(ct))
		return false;
	
	return CTimer_IsElapsed(ct) ? false : true;
}

CountdownTimer CThrow__GetThrowTimer(int ability)
{
	static int s_iOffs_m_throwTimer = -1;
	if (s_iOffs_m_throwTimer == -1)
		s_iOffs_m_throwTimer = FindSendPropInfo("CThrow", "m_hasBeenUsed") + 4;
	
	return view_as<CountdownTimer>(
		GetEntityAddress(ability) + view_as<Address>(s_iOffs_m_throwTimer)
	);
}

bool IsTank(int iClient)
{
	return (GetClientTeam(iClient) == TEAM_INFECTED && GetEntProp(iClient, Prop_Send, "m_zombieClass") == Z_TANK);
}

ConVar CreateConVarHook(const char[] name,
	const char[] defaultValue,
	const char[] description="",
	int flags=0,
	bool hasMin=false, float min=0.0,
	bool hasMax=false, float max=0.0,
	ConVarChanged callback)
{
	ConVar cv = CreateConVar(name, defaultValue, description, flags, hasMin, min, hasMax, max);
	
	Call_StartFunction(INVALID_HANDLE, callback);
	Call_PushCell(cv);
	Call_PushNullString();
	Call_PushNullString();
	Call_Finish();
	
	cv.AddChangeHook(callback);
	
	return cv;
}
