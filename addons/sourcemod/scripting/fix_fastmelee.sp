#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PL_VERSION "2.1"

GlobalForward hWeaponSwitchFwd;

float fLastMeleeSwing[MAXPLAYERS + 1];
bool bLate;

public Plugin myinfo =
{
	name = "Fast melee fix",
	author = "sheo",
	description = "Fixes the bug with too fast melee attacks",
	version = PL_VERSION,
	url = "http://steamcommunity.com/groups/b1com"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion iEngine = GetEngineVersion();
	if (iEngine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}

	bLate = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d2_fast_melee_fix_version", PL_VERSION, "Fast melee fix version", FCVAR_NOTIFY | FCVAR_DONTRECORD | FCVAR_SPONLY);

	HookEvent("weapon_fire", Event_WeaponFire, EventHookMode_Post);

	if (bLate)
		LateLoadHook();

	hWeaponSwitchFwd = new GlobalForward("OnClientMeleeSwitch", ET_Ignore, Param_Cell, Param_Cell);
}

void LateLoadHook()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			SDKHook(i, SDKHook_WeaponSwitchPost, OnWeaponSwitched);
		}
	}
}

public void OnClientPutInServer(int client)
{
	if (!IsFakeClient(client))
	{
		SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitched);
	}
	fLastMeleeSwing[client] = 0.0;
}

public Action Event_WeaponFire(Event event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client > 0 && !IsFakeClient(client))
	{
		char sBuffer[64];
		event.GetString("weapon", sBuffer, sizeof(sBuffer));
		if (StrEqual(sBuffer, "melee"))
		{
			fLastMeleeSwing[client] = GetGameTime();
		}
	}

	return Plugin_Continue;
}

public void OnWeaponSwitched(int client, int weapon)
{
	if (!IsFakeClient(client) && IsValidEntity(weapon))
	{
		char sBuffer[32];
		GetEntityClassname(weapon, sBuffer, sizeof(sBuffer));
		if (StrEqual(sBuffer, "weapon_melee"))
		{
			float fShouldbeNextAttack = fLastMeleeSwing[client] + 0.92;
			float fByServerNextAttack = GetGameTime() + 0.5;
			SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", (fShouldbeNextAttack > fByServerNextAttack) ? fShouldbeNextAttack : fByServerNextAttack);

			Call_StartForward(hWeaponSwitchFwd);
			Call_PushCell(client);
			Call_PushCell(weapon);
			Call_Finish();
		}
	}
}