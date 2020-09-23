#pragma semicolon 1

new Float:fSavedTime;
new Handle:hCvarCommonLimit;
new Handle:hCvarSurvivorLimit;
new iCommonLimit;
new iSurvivorLimit;

#include <sourcemod>
#include <left4dhooks>
#include <l4d2lib>
#include <sdkhooks>
#include <sdktools>

new Address:pZombieManager = Address_Null;

public Plugin:myinfo = 
{
	name = "L4D2 Horde",
	author = "Visor, Sir",
	description = "Modifies Event Horde sizes and stops it completely during Tank",
	version = "1.1",
	url = "Nowhere."
};

public OnPluginStart()
{
	new Handle:gamedata = LoadGameConfigFile("left4dhooks.l4d2");
	if (!gamedata)
	{
		SetFailState("Left4DHooks Direct gamedata missing or corrupt");
	}

	pZombieManager = GameConfGetAddress(gamedata, "ZombieManager");
	if (!pZombieManager)
	{
		SetFailState("Couldn't find the 'ZombieManager' address");
	}

	hCvarCommonLimit = FindConVar("z_common_limit");
	hCvarSurvivorLimit = FindConVar("survivor_limit");
	HookEvent("round_start", RoundStart);
}

public OnConfigsExecuted()
{
	iCommonLimit = GetConVarInt(hCvarCommonLimit);
	iSurvivorLimit = GetConVarInt(hCvarSurvivorLimit);
}

public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual(classname, "infected", false) && IsInfiniteHordeActive() && !IsTankUp() && !ArePlayersBiled() && iSurvivorLimit > 1)
	{
		CreateTimer(0.1, CommonSlayer, entity);
	}
}

public Action:CommonSlayer(Handle:timer, any:entity)
{
	if (IsValidEntity(entity) && GetAllCommon() > (iCommonLimit - 8))
	{
		AcceptEntityInput(entity, "Kill");
	}
}

public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast ) { fSavedTime = 0.0; }

public Action:L4D_OnSpawnMob(&amount)
{
	/////////////////////////////////////
	// - Called on Event Hordes.
	// - Called on Panic Event Hordes.
	// - Called on Natural Hordes.
	// - Called on Onslaught (Mini-finale or finale Scripts)

	// - Not Called on Boomer Hordes.
	// - Not Called on z_spawn mob.
	////////////////////////////////////
	
	new Float:fTime = GetGameTime();
	new Float:fHordeTimer;

	// "Pause" the infinite horde during the Tank fight
	if (IsInfiniteHordeActive())
	{
		if (IsTankUp())
		{
			SetPendingMobCount(0);
			amount = 0;
			return Plugin_Handled;
		}
		else
		{
			// Horde Timer
			if (fTime - fSavedTime > 10.0) fHordeTimer = 0.0;
			else
			{
				// Scale Horde depending on how often the timer triggers.
				fHordeTimer = fTime - fSavedTime;
				amount = RoundToCeil(fHordeTimer) * 2;
			}
		}

		fSavedTime = fTime;
	}
	return Plugin_Continue;
}

bool:IsInfiniteHordeActive()
{
	new countdown = GetHordeCountdown();
	return (/*GetPendingMobCount() > 0 &&*/ countdown > -1 && countdown <= 10);
}

/*GetPendingMobCount()
{
	return LoadFromAddress(pZombieManager + Address:528, NumberType_Int32);
}*/

SetPendingMobCount(count)
{
	StoreToAddress(pZombieManager + Address:528, count, NumberType_Int32);
}

GetHordeCountdown()
{
	return CTimer_HasStarted(L4D2Direct_GetMobSpawnTimer()) ? RoundFloat(CTimer_GetRemainingTime(L4D2Direct_GetMobSpawnTimer())) : -1;
}

GetAllCommon()
{
	new count;
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "infected")) != INVALID_ENT_REFERENCE)
	{
		if (GetEntProp(entity, Prop_Send, "m_mobRush") > 0) count++;
	}
	return count;
}

bool:ArePlayersBiled()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			new Float:fVomitFade = GetEntPropFloat(i, Prop_Send, "m_vomitFadeStart");
			if (fVomitFade != 0.0 && fVomitFade + 8.0 > GetGameTime()) return true;
		}
	}
	return false;
}

bool:IsTankUp()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 3 && !IsFakeClient(i) && GetEntProp(i, Prop_Send, "m_zombieClass") == 8 && IsPlayerAlive(i))
		{
			return true;
		}
	}
	return false;
}