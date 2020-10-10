#include <sourcemod>
#include <left4dhooks>
#include <colors>

//throw sequences:
//48 - (not used unless tank_rock_overhead_percent is changed)

//49 - 1handed overhand (+attack2),
//50 - underhand (+use),
//51 - 2handed overhand (+reload)

new g_iQueuedThrow[MAXPLAYERS + 1];
new Handle:g_hBlockPunchRock = INVALID_HANDLE;
new Handle:g_hBlockJumpRock = INVALID_HANDLE;
new Handle:hOverhandOnly;

new Float:throwQueuedAt[MAXPLAYERS + 1];

public Plugin:myinfo = 
{
	name = "Tank Attack Control", 
	author = "vintik, CanadaRox, Jacob, Visor",
	description = "",
	version = "0.7.1",
	url = "https://github.com/Attano/L4D2-Competitive-Framework"
}

public OnPluginStart()
{
	decl String:sGame[256];
	GetGameFolderName(sGame, sizeof(sGame));
	if (!StrEqual(sGame, "left4dead2", false))
	{
		SetFailState("Plugin supports Left 4 dead 2 only!");
	}
	
	//future-proof remake of the confogl feature (could be used with lgofnoc)
	g_hBlockPunchRock = CreateConVar("l4d2_block_punch_rock", "1", "Block tanks from punching and throwing a rock at the same time");
	g_hBlockJumpRock = CreateConVar("l4d2_block_jump_rock", "0", "Block tanks from jumping and throwing a rock at the same time");
	hOverhandOnly = CreateConVar("tank_overhand_only", "0", "Force tank to only throw overhand rocks.");

	HookEvent("round_start", EventHook:RoundStartEvent, EventHookMode_PostNoCopy);
	HookEvent("tank_spawn", TankSpawn_Event);
}

public RoundStartEvent()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		throwQueuedAt[i] = 0.0;
	}
}

public TankSpawn_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new tank = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsFakeClient(tank)) return;

	new bool:hidemessage = false;
	decl String:buffer[3];
	if (GetClientInfo(tank, "rs_hidemessage", buffer, sizeof(buffer)))
	{
		hidemessage = bool:StringToInt(buffer);
	}
	if (!hidemessage && (GetConVarBool(hOverhandOnly) == false))
	{
        CPrintToChat(tank, "{blue}[{default}Tank Rock Selector{blue}]");
        CPrintToChat(tank, "{olive}Reload {default}= {blue}2 Handed Overhand");
        CPrintToChat(tank, "{olive}Use {default}= {blue}Underhand");
        CPrintToChat(tank, "{olive}M2 {default}= {blue}1 Handed Overhand");
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (!IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) != 3
		|| GetEntProp(client, Prop_Send, "m_zombieClass") != 8)
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

public Action:L4D_OnCThrowActivate(ability)
{
	if (!IsValidEntity(ability))
	{
		LogMessage("Invalid 'ability_throw' index: %d. Continuing throwing.", ability);
		return Plugin_Continue;
	}
	new client = GetEntPropEnt(ability, Prop_Data, "m_hOwnerEntity");
	
	if (GetClientButtons(client) & IN_ATTACK)
	{
		if (GetConVarBool(g_hBlockPunchRock))
			return Plugin_Handled;
	}
	
	throwQueuedAt[client] = GetGameTime();
	return Plugin_Continue;
}

public Action:L4D2_OnSelectTankAttack(client, &sequence)
{
	if (sequence > 48 && g_iQueuedThrow[client])
	{
		//rock throw
		sequence = g_iQueuedThrow[client] + 48;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

bool:ShouldCancelJump(client)
{
	if (!GetConVarBool(g_hBlockJumpRock))
	{
		return false;
	}
	return (1.5 > GetGameTime() - throwQueuedAt[client]);
}