#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>
#include <colors>

#define L4D2Team_Infected 3
#define L4D2Infected_Tank 8

//throw sequences:
//48 - (not used unless tank_rock_overhead_percent is changed)

//49 - 1handed overhand (+attack2),
//50 - underhand (+use),
//51 - 2handed overhand (+reload)

int g_iQueuedThrow[MAXPLAYERS + 1];
ConVar g_hBlockPunchRock;
ConVar g_hBlockJumpRock;
ConVar hOverhandOnly;

float throwQueuedAt[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "Tank Attack Control", 
	author = "vintik, CanadaRox, Jacob, Visor",
	description = "",
	version = "0.7.2",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
}

public void OnPluginStart()
{
	LoadTranslations("l4d2_tank_attack_control.phrases");
	char sGame[256];
	GetGameFolderName(sGame, sizeof(sGame));
	if (!StrEqual(sGame, "left4dead2", false))
	{
		SetFailState("Plugin supports Left 4 dead 2 only!");
	}
	
	//future-proof remake of the confogl feature (could be used with lgofnoc)
	g_hBlockPunchRock = CreateConVar("l4d2_block_punch_rock", "1", "Block tanks from punching and throwing a rock at the same time");
	g_hBlockJumpRock = CreateConVar("l4d2_block_jump_rock", "0", "Block tanks from jumping and throwing a rock at the same time");
	hOverhandOnly = CreateConVar("tank_overhand_only", "0", "Force tank to only throw overhand rocks.");

	HookEvent("round_start", RoundStartEvent, EventHookMode_PostNoCopy);
	HookEvent("tank_spawn", TankSpawn_Event);
}

public void RoundStartEvent(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++) {
		throwQueuedAt[i] = 0.0;
	}
}

public void TankSpawn_Event(Event event, const char[] name, bool dontBroadcast)
{
	int tank = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsFakeClient(tank)) return;

	if (GetConVarBool(hOverhandOnly) == false)
	{
		CPrintToChat(tank, "%t", "Title");
		CPrintToChat(tank, "%t", "Reload");
		CPrintToChat(tank, "%t", "Use");
		CPrintToChat(tank, "%t", "M2");
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (!IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) != L4D2Team_Infected
		|| GetEntProp(client, Prop_Send, "m_zombieClass") != L4D2Infected_Tank)
			return Plugin_Continue;
	
	//if tank
	if ((buttons & IN_JUMP) && ShouldCancelJump(client))
	{
		buttons &= ~IN_JUMP;
	}
	
	if (GetConVarBool(hOverhandOnly) == false)
	{
		if (buttons & IN_RELOAD)
		{
			g_iQueuedThrow[client] = 3; //two hand overhand
			buttons |= IN_ATTACK2;
		}
		else if (buttons & IN_USE)
		{
			g_iQueuedThrow[client] = 2; //underhand
			buttons |= IN_ATTACK2;
		}
		else
		{
			g_iQueuedThrow[client] = 1; //one hand overhand
		}
	}
	else
	{
		g_iQueuedThrow[client] = 3; // two hand overhand
	}
	
	return Plugin_Continue;
}

public Action L4D_OnCThrowActivate(int ability)
{
	if (!IsValidEntity(ability))
	{
		LogMessage("Invalid 'ability_throw' index: %d. Continuing throwing.", ability);
		return Plugin_Continue;
	}
	int client = GetEntPropEnt(ability, Prop_Data, "m_hOwnerEntity");
	
	if (GetClientButtons(client) & IN_ATTACK)
	{
		if (GetConVarBool(g_hBlockPunchRock))
			return Plugin_Handled;
	}
	
	throwQueuedAt[client] = GetGameTime();
	return Plugin_Continue;
}

public Action L4D2_OnSelectTankAttack(int client, int &sequence)
{
	if (sequence > 48 && g_iQueuedThrow[client])
	{
		//rock throw
		sequence = g_iQueuedThrow[client] + 48;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

bool ShouldCancelJump(int client)
{
	if (!GetConVarBool(g_hBlockJumpRock))
	{
		return false;
	}
	return (1.5 > GetGameTime() - throwQueuedAt[client]);
}
