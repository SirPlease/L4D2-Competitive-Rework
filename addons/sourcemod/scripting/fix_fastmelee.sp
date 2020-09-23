#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PL_VERSION "2.1"

new Handle:hWeaponSwitchFwd;

new Float:fLastMeleeSwing[MAXPLAYERS + 1];
new bool:bLate;

public Plugin myinfo =
{
	name = "Fast melee fix",
	author = "sheo",
	description = "Fixes the bug with too fast melee attacks",
	version = PL_VERSION,
	url = "http://steamcommunity.com/groups/b1com"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	bLate = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	decl String:gfstring[128];
	GetGameFolderName(gfstring, sizeof(gfstring));
	if (!StrEqual(gfstring, "left4dead2", false))
	{
		SetFailState("Plugin supports Left 4 dead 2 only!");
	}
	HookEvent("weapon_fire", Event_WeaponFire);
	CreateConVar("l4d2_fast_melee_fix_version", PL_VERSION, "Fast melee fix version");
	if (bLate)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				SDKHook(i, SDKHook_WeaponSwitchPost, OnWeaponSwitched);
			}
		}
	}

	hWeaponSwitchFwd = CreateGlobalForward("OnClientMeleeSwitch", ET_Ignore, Param_Cell, Param_Cell);
}

public OnClientPutInServer(client)
{
	if (!IsFakeClient(client))
	{
		SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitched);
	}
	fLastMeleeSwing[client] = 0.0;
}

public Action:Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0 && !IsFakeClient(client))
	{
		decl String:sBuffer[64];
		GetEventString(event, "weapon", sBuffer, sizeof(sBuffer));
		if (StrEqual(sBuffer, "melee"))
		{
			fLastMeleeSwing[client] = GetGameTime();
		}
	}
}

public OnWeaponSwitched(client, weapon)
{
	if (!IsFakeClient(client) && IsValidEntity(weapon))
	{
		decl String:sBuffer[32];
		GetEntityClassname(weapon, sBuffer, sizeof(sBuffer));
		if (StrEqual(sBuffer, "weapon_melee"))
		{
			new Float:fShouldbeNextAttack = fLastMeleeSwing[client] + 0.92;
			new Float:fByServerNextAttack = GetGameTime() + 0.5;
			SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", (fShouldbeNextAttack > fByServerNextAttack) ? fShouldbeNextAttack : fByServerNextAttack);

			Call_StartForward(hWeaponSwitchFwd);

			Call_PushCell(client);

			Call_PushCell(weapon);

			Call_Finish();
		}
	}
}