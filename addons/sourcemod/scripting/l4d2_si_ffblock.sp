#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <l4d2util_constants>

#define DEBUG 0
#define MAX_ENTITY_NAME_SIZE 64

bool
	g_bLateLoad = false,
	g_bFFBlock = false,
	g_bAllowTankFF = false,
	g_bBlockWitchFF = false;

ConVar
	g_hCvarFFBlock = null,
	g_hCvarAllowTankFF = null,
	g_hCvarBlockWitchFF = null;

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrMax)
{
	g_bLateLoad = bLate;

	return APLRes_Success;
}

public Plugin myinfo =
{
	name = "L4D2 Infected Friendly Fire Disable",
	author = "ProdigySim, Don, Visor, A1m`",
	description = "Disables friendly fire between infected players.",
	version = "2.1"
};

public void OnPluginStart()
{
	g_hCvarFFBlock = CreateConVar("l4d2_block_infected_ff", "1", "Disable SI->SI friendly fire", _, true, 0.0, true, 1.0);
	g_hCvarAllowTankFF = CreateConVar("l4d2_infected_ff_allow_tank", "1", "Do not disable friendly fire for tanks on other SI", _, true, 0.0, true, 1.0);
	g_hCvarBlockWitchFF = CreateConVar("l4d2_infected_ff_block_witch", "0", "Disable FF towards witches", _, true, 0.0, true, 1.0);
	
	CvarsToType();
	
	g_hCvarFFBlock.AddChangeHook(Cvars_Changed);
	g_hCvarAllowTankFF.AddChangeHook(Cvars_Changed);
	g_hCvarBlockWitchFF.AddChangeHook(Cvars_Changed);

	HookEvent("witch_spawn", Event_WitchSpawn, EventHookMode_Post);

	if (g_bLateLoad) {
		int iEntityMaxCount = GetEntityCount();

		for (int iEntity = 1; iEntity <= iEntityMaxCount; iEntity++) {
			if (iEntity <= MaxClients) {
				if (IsClientInGame(iEntity)) {
					SDKHook(iEntity, SDKHook_OnTakeDamage, Hook_PlayerOnTakeDamage);
				}
			} else {
				if (IsWitch(iEntity)) {
					SDKHook(iEntity, SDKHook_OnTakeDamage, Hook_WitchOnTakeDamage);
				}
			}
		}
	}
}

public void Cvars_Changed(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	CvarsToType();
}

void CvarsToType()
{
	g_bFFBlock = g_hCvarFFBlock.BoolValue;
	g_bAllowTankFF = g_hCvarAllowTankFF.BoolValue;
	g_bBlockWitchFF = g_hCvarBlockWitchFF.BoolValue;
}

public void Event_WitchSpawn(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int iWitch = hEvent.GetInt("witchid");

	SDKHook(iWitch, SDKHook_OnTakeDamage, Hook_WitchOnTakeDamage);
}

public Action Hook_WitchOnTakeDamage(int iVictim, int &iAttacker, int &iInflictor, float &fDamage, int &iDamagetype)
{
	if (!(iDamagetype & DMG_CLUB) || !g_bBlockWitchFF) {
		return Plugin_Continue;
	}
	
	if (!IsWitch(iVictim) || !IsInfected(iAttacker)) {
		return Plugin_Continue;
	}

	int iZClass = GetEntProp(iAttacker, Prop_Send, "m_zombieClass");

#if DEBUG
	char sClassName[MAX_ENTITY_NAME_SIZE];
	GetEdictClassname(iVictim, sClassName, sizeof(sClassName));
	PrintToChatAll("Hook_WitchOnTakeDamage. iVictim: %s (%d), iAttacker: %N (%d), ZClass: %s (%d), iInflictor: %d, fDamage: %f, iDamagetype: %d", \
							sClassName, iVictim, iAttacker, iAttacker, L4D2_InfectedNames[iZClass], iZClass, iInflictor, fDamage, iDamagetype);
#endif

	return (iZClass == L4D2Infected_Tank) ? Plugin_Continue : Plugin_Handled;
}

public void OnClientPutInServer(int iClient)
{
	SDKHook(iClient, SDKHook_OnTakeDamage, Hook_PlayerOnTakeDamage);
}

public Action Hook_PlayerOnTakeDamage(int iVictim, int &iAttacker, int &iInflictor, float &fDamage, int &iDamagetype)
{
	if (!(iDamagetype & DMG_CLUB) || !g_bFFBlock) {
		return Plugin_Continue;
	}
	
	if (!IsInfected(iAttacker) || !IsInfected(iVictim)) {
		return Plugin_Continue;
	}
	
	int iZClass = GetEntProp(iAttacker, Prop_Send, "m_zombieClass");

#if DEBUG
	PrintToChatAll("Hook_PlayerOnTakeDamage. iVictim: %N (%d), iAttacker: %N (%d), ZClass: %s (%d), iInflictor: %d, fDamage: %f, iDamagetype: %d", \
							iVictim, iVictim, iAttacker, iAttacker, L4D2_InfectedNames[iZClass], iZClass, iInflictor, fDamage, iDamagetype);
#endif

	return (iZClass == L4D2Infected_Tank && g_bAllowTankFF) ? Plugin_Continue : Plugin_Handled;
}

bool IsInfected(int iClient)
{
	return (iClient > 0
		&& iClient <= MaxClients
		&& IsClientInGame(iClient)
		&& GetClientTeam(iClient) == L4D2Team_Infected);
}

bool IsWitch(int iEntity)
{
	if (iEntity <= MaxClients || !IsValidEdict(iEntity)) {
		return false;
	}
	
	char sClassName[MAX_ENTITY_NAME_SIZE];
	GetEdictClassname(iEntity, sClassName, sizeof(sClassName));
	return (strncmp(sClassName, "witch", 5) == 0); //witch and witch_bride
}
