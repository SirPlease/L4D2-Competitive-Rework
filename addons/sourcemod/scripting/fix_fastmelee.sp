#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <l4d2util_constants>

#define DEBUG 0

//Handle g_hWeaponSwitchFwd;

float g_fLastMeleeSwing[MAXPLAYERS + 1];

bool g_bLateLoad = false;

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrMax)
{
	EngineVersion iEngine = GetEngineVersion();
	if (iEngine != Engine_Left4Dead2) {
		strcopy(sError, iErrMax, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}

	//g_hWeaponSwitchFwd = CreateGlobalForward("OnClientMeleeSwitch", ET_Ignore, Param_Cell, Param_Cell);
	g_bLateLoad = bLate;
	return APLRes_Success;
}

public Plugin myinfo =
{
	name = "Fast melee fix",
	author = "sheo",
	description = "Fixes the bug with too fast melee attacks",
	version = "2.3",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	HookEvent("round_start", Event_Reset, EventHookMode_PostNoCopy);
	//HookEvent("round_end", Event_Reset, EventHookMode_PostNoCopy);
	HookEvent("weapon_fire", Event_WeaponFire, EventHookMode_Post);

	if (g_bLateLoad) {
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i)) {
				OnClientPutInServer(i);
			}
		}
	}
}

public void OnClientPutInServer(int iClient)
{
	if (!IsFakeClient(iClient)) {
		SDKHook(iClient, SDKHook_WeaponSwitchPost, OnWeaponSwitched);
	}

	g_fLastMeleeSwing[iClient] = 0.0;
}

void Event_Reset(Event hEvent, const char[] sEntityName, bool bDontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++) {
		g_fLastMeleeSwing[i] = 0.0;
	}
}

void Event_WeaponFire(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int iWeaponId = hEvent.GetInt("weaponid");
	if (iWeaponId != WEPID_MELEE) {
		return;
	}

	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if (iClient < 1 || IsFakeClient(iClient)) {
		return;
	}

	g_fLastMeleeSwing[iClient] = GetGameTime();

#if DEBUG
	char sWeaponName[ENTITY_MAX_NAME_LENGTH];
	hEvent.GetString("weapon", sWeaponName, sizeof(sWeaponName));
	PrintToChatAll("Event_WeaponFire: %N, weapon: %s, time: %f, iWeaponId: %d", iClient, sWeaponName, g_fLastMeleeSwing[iClient], iWeaponId);
#endif
}

void OnWeaponSwitched(int iClient, int iWeapon)
{
	if (IsFakeClient(iClient) || !IsValidEdict(iWeapon)) {
		return;
	}

	char sWeaponName[ENTITY_MAX_NAME_LENGTH];
	GetEdictClassname(iWeapon, sWeaponName, sizeof(sWeaponName));
	if (strcmp(sWeaponName, "weapon_melee") != 0) {
		return;
	}

	float fShouldbeNextAttack = g_fLastMeleeSwing[iClient] + 0.92;
	float fByServerNextAttack = GetGameTime() + 0.5;
	float fNextAttack = (fShouldbeNextAttack > fByServerNextAttack) ? fShouldbeNextAttack : fByServerNextAttack;
	SetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack", fNextAttack);

	/*Call_StartForward(g_hWeaponSwitchFwd);
	Call_PushCell(iClient);
	Call_PushCell(iWeapon);
	Call_Finish();*/

#if DEBUG
	PrintToChatAll("OnWeaponSwitched: %N, weapon: %d (%s), fNextAttack: %f", iClient, iWeapon, sWeaponName, fNextAttack);
#endif
}
