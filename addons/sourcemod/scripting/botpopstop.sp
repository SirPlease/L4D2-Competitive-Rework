#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define WP_PAIN_PILLS 15
#define WP_ADRENALINE 23
#define PILL_INDEX 0
#define ADREN_INDEX 1

new iBotUsedCount[2][MAXPLAYERS + 1];

public Plugin:myinfo = 
{
	name = "Simplified Bot Pop Stop",
	author = "Stabby & CanadaRox",
	description = "Removes pills from bots if they try to use them and restores them when a human takes over.",
	version = "1.3",
	url = "no url"
}

public OnPluginStart()
{
	HookEvent("weapon_fire",Event_WeaponFire);
	HookEvent("bot_player_replace",Event_PlayerJoined);
	HookEvent("round_start",Event_RoundStart,EventHookMode_PostNoCopy);
}

// Take pills from the bot before they get used
public Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client   = GetClientOfUserId(GetEventInt(event,"userid"));
	new weaponid = GetEventInt(event,"weaponid");

	if (IsFakeClient(client))
	{
		if (weaponid == WP_PAIN_PILLS)
		{
			iBotUsedCount[PILL_INDEX][client]++;
			RemovePlayerItem(client, GetPlayerWeaponSlot(client,4));
		}
		else if (weaponid == WP_ADRENALINE)
		{
			iBotUsedCount[ADREN_INDEX][client]++;
			RemovePlayerItem(client, GetPlayerWeaponSlot(client,4));
		}
	}
}

// Give the human player the pills back when they join
public Event_PlayerJoined(Handle:event, const String:name[], bool:dontBroadcast)
{
	new leavingBot = GetClientOfUserId(GetEventInt(event,"bot"));

	if (iBotUsedCount[PILL_INDEX][leavingBot] > 0 || iBotUsedCount[ADREN_INDEX][leavingBot] > 0)
	{
		RestoreItems(GetClientOfUserId(GetEventInt(event, "player")), leavingBot);
		iBotUsedCount[PILL_INDEX][leavingBot] = 0;
		iBotUsedCount[ADREN_INDEX][leavingBot] = 0;
	}
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 0; i < 2; i++)
	{
		for (new j = 0; j < MAXPLAYERS + 1; j++)
		{
			iBotUsedCount[i][j] = 0;
		}
	}
}

RestoreItems(client, leavingBot)
{
	// manually create entity and the equip it since GivePlayerItem() doesn't work in L4D2
	decl entity;
	decl Float:clientOrigin[3];
	new currentWeapon = GetPlayerWeaponSlot(client, 4);
	for (new i = 0; i < 2; i++)
	{
		for (new j = iBotUsedCount[i][leavingBot]; j > 0; j--)
		{
			entity = CreateEntityByName(i == PILL_INDEX ? "weapon_pain_pills" : "weapon_adrenaline");
			GetClientAbsOrigin(client, clientOrigin);
			clientOrigin[2] += 10.0;
			TeleportEntity(entity, clientOrigin, NULL_VECTOR, NULL_VECTOR);
			DispatchSpawn(entity);
			if (currentWeapon == -1)
			{
				EquipPlayerWeapon(client, entity);
				currentWeapon = entity;
			}
		}
	}
}
