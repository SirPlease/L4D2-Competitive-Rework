#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define DEBUG 0

#define MAX_ENTITY_NAME_SIZE 64

#define GAMEDATA_FILE "l4d2_bw_rock_hit"
#define SIGNATURE_NAME "CTankRock::Detonate"

#define Z_TANK 8

#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

float
	g_fPainPillsDecayRate = 0.0;

int
	g_iSurvivorMaxIncapCount = 0,
	g_iVsTankDamage = 0;

ConVar
	g_hSurvivorMaxIncapCount = null,
	g_hVsTankDamage = null,
	g_hPainPillsDecayRate = null;

bool
	g_bLateLoad = false;

Handle
	g_hTankRockDetonateCall = null;

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrMax)
{
	g_bLateLoad = bLate;
	return APLRes_Success;
}

public Plugin myinfo =
{
	name = "L4D2 Black&White Rock Hit",
	author = "Visor, A1m`",
	description = "Stops rocks from passing through soon-to-be-dead Survivors",
	version = "1.3",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	InitGameData();

	g_hSurvivorMaxIncapCount = FindConVar("survivor_max_incapacitated_count");
	g_hVsTankDamage = FindConVar("vs_tank_damage");
	g_hPainPillsDecayRate = FindConVar("pain_pills_decay_rate");
	
	CvarsToType();

	g_hSurvivorMaxIncapCount.AddChangeHook(CvarsChanged);

#if DEBUG
	RegConsoleCmd("sm_detonate_rock", Cmd_DetonateRock);
#endif

	if (g_bLateLoad) {
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i)) {
				OnClientPutInServer(i);
			}
		}
	}
}

void InitGameData()
{
	Handle hGameData = LoadGameConfigFile(GAMEDATA_FILE);
	if (!hGameData) {
		SetFailState("Could not load gamedata/%s.txt", GAMEDATA_FILE);
	}

	StartPrepSDKCall(SDKCall_Entity);
	
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, SIGNATURE_NAME)) {
		SetFailState("Function '%s' not found", SIGNATURE_NAME);
	}
	
	g_hTankRockDetonateCall = EndPrepSDKCall();
	
	if (g_hTankRockDetonateCall == null) {
		SetFailState("Function '%s' found, but something went wrong", SIGNATURE_NAME);
	}

	delete hGameData;
}

public void CvarsChanged(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	CvarsToType();
}

void CvarsToType()
{
	g_iSurvivorMaxIncapCount = g_hSurvivorMaxIncapCount.IntValue;
	g_iVsTankDamage = g_hVsTankDamage.IntValue;
	g_fPainPillsDecayRate = g_hPainPillsDecayRate.FloatValue;
}

public void OnClientPutInServer(int iClient)
{
	SDKHook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnClientDisconnect(int iClient)
{
	SDKUnhook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int iVictim, int &iAttacker, int &iInflictor, float &fDamage, int &iDamagetype, 
								int &iWeapon, float fDamageForce[3], float fDamagePosition[3])
{
	if (iDamagetype != DMG_CLUB || !IsTankRock(iInflictor)) {
		return Plugin_Continue;
	}
	
	if (!IsSurvivor(iVictim)/* || !IsTank(iAttacker)*/) {
		return Plugin_Continue;
	}
	
#if DEBUG
	char sClassName[MAX_ENTITY_NAME_SIZE];
	GetEdictClassname(iInflictor, sClassName, sizeof(sClassName));
	PrintToChatAll("Victim %d attacker %d inflictor %d damageType %d weapon %d", 
								iVictim, iAttacker, iInflictor, iDamagetype, iWeapon);
			
	PrintToChatAll("Victim %N(%i/%i) attacker %N classname %s", 
								iVictim, GetSurvivorPermanentHealth(iVictim), GetSurvivorTemporaryHealth(iVictim), iAttacker, sClassName);
#endif

	// Not b&w
	if (!IsOnCriticalStrike(iVictim)) {
		return Plugin_Continue;
	}
	
	// Gotcha
	if (GetSurvivorTemporaryHealth(iVictim) <= g_iVsTankDamage) {
		CTankRock__Detonate(iInflictor);
	}

	return Plugin_Continue;
}

int GetSurvivorTemporaryHealth(int iClient)
{
	int temphp = RoundToCeil(GetEntPropFloat(iClient, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(iClient, Prop_Send, "m_healthBufferTime")) * g_fPainPillsDecayRate)) - 1;
	return (temphp > 0 ? temphp : 0);
}

bool IsOnCriticalStrike(int iClient)
{
	return (g_iSurvivorMaxIncapCount == GetEntProp(iClient, Prop_Send, "m_currentReviveCount"));
}

bool IsSurvivor(int iClient)
{
	return (iClient > 0
		&& iClient <= MaxClients
		&& IsClientInGame(iClient)
		&& GetClientTeam(iClient) == TEAM_SURVIVOR);
}

/*bool IsTank(int iClient)
{
	return (iClient > 0
		&& iClient <= MaxClients
		&& IsClientInGame(iClient)
		&& GetClientTeam(iClient) == TEAM_INFECTED 
		&& GetEntProp(iClient, Prop_Send, "m_zombieClass") == Z_TANK
		&& IsPlayerAlive(iClient));
}*/

bool IsTankRock(int iEntity)
{
	if (iEntity > 0 && IsValidEntity(iEntity)) {
		char sClassName[MAX_ENTITY_NAME_SIZE];
		GetEdictClassname(iEntity, sClassName, sizeof(sClassName));
		return (strcmp(sClassName, "tank_rock") == 0);
	}

	return false;
}

void CTankRock__Detonate(int iTankRock)
{
#if DEBUG
	PrintToChatAll("CTankRock__Detonate: %d", iTankRock);
#endif

	SDKCall(g_hTankRockDetonateCall, iTankRock);
}

#if DEBUG
public Action Cmd_DetonateRock(int iClient, int iArgs)
{
	int iEntity = -1;
	while ((iEntity = FindEntityByClassname(iEntity, "tank_rock")) != -1) {
		int iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");

		CTankRock__Detonate(iEntity);
		
		if (iOwner > 0 && IsClientInGame(iOwner)) {
			PrintToChatAll("Owner: %N (%d). Tank rock %d detonate)", iOwner, iOwner, iEntity);
		} else {
			PrintToChatAll("Unknown owner: %d. Tank rock %d detonate)", iOwner, iEntity);
		}
	}

	return Plugin_Handled;
}

int GetSurvivorPermanentHealth(int iClient)
{
	if (GetEntProp(iClient, Prop_Send, "m_currentReviveCount") > 0) {
		return 0;
	}
	
	int iHealth = GetEntProp(iClient, Prop_Send, "m_iHealth");
	return (iHealth > 0) ? iHealth : 0;
}
#endif
