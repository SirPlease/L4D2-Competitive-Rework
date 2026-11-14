#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

#pragma newdecls required

StringMap g_hPropSpriteMap;

#define SPRITE_PATH "materials/vgui/hud/zombieteamimage_tank.vmt" 

public Plugin myinfo = 
{
	name = "[L4D2] Car Hittable Tank Sprite Indicator",
	author = "B[R]UTUS",
	description = "Places a Tank HUD icon above hittables",
	version = "1.0",
	url = "https://steamcommunity.com/id/8ru7u5/"
};

public void OnPluginStart()
{
	g_hPropSpriteMap = new StringMap();
	HookEvent("round_start", 	Event_RoundStart, 	EventHookMode_PostNoCopy);
	HookEvent("player_death",  	Event_TankDeath,	EventHookMode_PostNoCopy);
}

public void L4D_OnSpawnTank_Post(int client, const float vecPos[3], const float vecAng[3])
{
	AttachSprites();
}

public void OnMapStart()
{
	PrecacheGeneric(SPRITE_PATH, true);
}

void ClearSprites()
{
	if (g_hPropSpriteMap != null)
	{
		StringMapSnapshot snapshot = g_hPropSpriteMap.Snapshot();
		char key[16];
		int sprite;

		for (int i = 0; i < snapshot.Length; i++)
		{
			snapshot.GetKey(i, key, sizeof(key));
			if (g_hPropSpriteMap.GetValue(key, sprite))
			{
				if (IsValidEntity(sprite))
				{
					AcceptEntityInput(sprite, "Kill");
				}

				int parentEntity = StringToInt(key);
				if (IsValidEntity(parentEntity))
					SDKUnhook(parentEntity, SDKHook_OnTakeDamagePost, OnPropDamaged);
			}
		}
		delete snapshot;

		g_hPropSpriteMap.Clear();
	}
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	ClearSprites();
}

void AttachSprites()
{
	char modelName[256];
	int iEntCount = GetMaxEntities();

	for (int i = MaxClients; i < iEntCount; i++) 
	{
		if (!IsValidEntity(i)) continue;

		if (IsTankProp(i)) 
		{
			GetEntPropString(i, Prop_Data, "m_ModelName", modelName, sizeof(modelName));
			AttachSpriteToEntity(i);
		}	
	}
}

void AttachSpriteToEntity(int parentEntity)
{
	SDKHook(parentEntity, SDKHook_OnTakeDamagePost, OnPropDamaged);

	int sprite = CreateEntityByName("env_sprite");
	if (sprite == -1) return;

	float origin[3];
	GetEntPropVector(parentEntity, Prop_Send, "m_vecOrigin", origin);
	origin[2] += 85.0; // Height above the hittable

	DispatchKeyValue(sprite, "model", SPRITE_PATH);
	DispatchKeyValue(sprite, "rendercolor", "255 0 0"); 
	DispatchKeyValue(sprite, "renderamt", "255");
	DispatchKeyValue(sprite, "rendermode", "9");			
	DispatchKeyValue(sprite, "scale", "0.125");			  
	DispatchKeyValue(sprite, "spawnflags", "1");

	if (!DispatchSpawn(sprite)) return;

	TeleportEntity(sprite, origin, NULL_VECTOR, NULL_VECTOR);

	SetVariantString("!activator");
	AcceptEntityInput(sprite, "SetParent", parentEntity, sprite, 0);
		
	AcceptEntityInput(sprite, "ShowSprite");

	char key[16];
	IntToString(parentEntity, key, sizeof(key));
	g_hPropSpriteMap.SetValue(key, sprite);

	SDKHook(sprite, SDKHook_SetTransmit, OnSpriteTransmit);
}

public void OnPropDamaged(int victim, int attacker, int inflictor, float damage, int damagetype, int weapon, const float damageForce[3], const float damagePosition[3], int damagecustom)
{
	// Checks an attacker for a Tank class
	if (attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker))
	{
		if (!IsTank(attacker))
			return;
	}
	else return;

	// Delete a sprite from a hittable if it was hit by Tank
	char key[16];
	IntToString(victim, key, sizeof(key));
	int sprite;
	if (g_hPropSpriteMap.GetValue(key, sprite))
	{
		if (IsValidEntity(sprite))
			AcceptEntityInput(sprite, "Kill");

		g_hPropSpriteMap.Remove(key);
	}
}

public Action OnSpriteTransmit(int entity, int client)
{
	// We'll display our sprites only to the Survivors and Infected teams. I don't think the Spectators team needs to see them.
	if (IsClientInGame(client) && GetClientTeam(client) > 1)
		return Plugin_Continue;

	return Plugin_Handled;
}

public void Event_TankDeath(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	// Checks whether any Tanks are still alive after one of them is killed (need to support multi-tanks)
	CreateTimer(1.0, TankDeadCheck, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action TankDeadCheck(Handle hTimer)
{
	if (FindTank() == -1) 
		ClearSprites();

	return Plugin_Stop;
}

bool IsTankProp(int iEntity)
{
	return IsValidEdict(iEntity) && HasEntProp(iEntity, Prop_Send, "m_hasTankGlow") && GetEntProp(iEntity, Prop_Send, "m_hasTankGlow", 1); 
}

bool IsTank(int iClient)
{
	return (GetEntProp(iClient, Prop_Send, "m_zombieClass") == 8 && IsPlayerAlive(iClient));
}

bool IsAliveTank(int iClient)
{
	return (IsClientInGame(iClient) && GetClientTeam(iClient) == 3 && IsTank(iClient));
}

int FindTank()
{
	for (int i = 1; i <= MaxClients; i++) 
	{
		if (IsAliveTank(i)) 
			return i;
	}

	return -1;
}
