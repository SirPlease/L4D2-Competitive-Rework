#include <sourcemod>
#include <left4dhooks>
#include <colors>

public Plugin:myinfo =
{
	name = "[L4D2] Tank Attack Control / Jump Rock Cooldown Hybrid",
	author = "Spoon",
	description = "Remake of https://github.com/Stabbath/ProMod/blob/master/addons/sourcemod/scripting/l4d_tank_control.sp.",
	version = "0.8.1",
	url = "https://github.com/spoon-l4d2"
}

new Handle:g_hBlockPunchRock = INVALID_HANDLE;
new Handle:g_hBlockJumpRock = INVALID_HANDLE;
new Handle:g_hJumpRockCooldown = INVALID_HANDLE;
new Handle:hOverhandOnly;
new g_iQueuedThrow[MAXPLAYERS + 1];
new bool:JumpRockReady;
new bool:jumped;
new Float:g_fCooldownTime;
new Float:throwQueuedAt[MAXPLAYERS + 1];

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
	g_hJumpRockCooldown = CreateConVar("l4d2_jump_rock_cooldown", "20", "Sets cooldown for jump rock ability");
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
		CPrintToChat(tank, "{red}[{default}Tank Rock Selector{red}]");
		CPrintToChat(tank, "{red}Use {default}-> {olive}Underhand throw");
		CPrintToChat(tank, "{red}Melee {default}-> {olive}One hand overhand");
		CPrintToChat(tank, "{red}Reload {default}-> {olive}Two hand overhand");

		if (!GetConVarBool(g_hBlockJumpRock))
			CPrintToChat(tank, "{red}Jump Rocks {default}have a {olive}%i{default} second cooldown.", GetConVarInt(g_hJumpRockCooldown));
	}

	jumped = false;
	JumpRockReady = true;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (!IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) != 3 || GetEntProp(client, Prop_Send, "m_zombieClass") != 8)
		return Plugin_Continue;

	// Cancel jump rocks

	if ((buttons & IN_JUMP) && ShouldCancelJump(client))
	{
		buttons &= ~IN_JUMP;
		jumped = false;
	}
	else if ((buttons & IN_JUMP) && !(GetEntityFlags(client) & FL_ONGROUND)) // if the client ACTUALLY jumped
	{
		jumped = true;
	}
	else
	{
		jumped = false;
	}

	if ((buttons & IN_ZOOM) && (GetEntityFlags(client) & FL_ONGROUND))
	{
		if (!JumpRockReady) return Plugin_Stop;

		g_iQueuedThrow[client] = 3; //two hand overhand
		blah(client, buttons);
		buttons |= IN_ATTACK2;
		jumped = true;
		return Plugin_Stop;
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

	if ((GetClientButtons(client) & IN_ATTACK) && GetConVarBool(g_hBlockPunchRock))
		return Plugin_Handled;

	throwQueuedAt[client] = GetGameTime();
	return Plugin_Continue;
}

public Action:L4D2_OnSelectTankAttack(client, &sequence)
{
	if (sequence > 48 && g_iQueuedThrow[client])
	{
		if (jumped)
		{
			PutJumpRockOnCooldown(client);
		}

		sequence = g_iQueuedThrow[client] + 48;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

bool:ShouldCancelJump(client)
{
	if (GetConVarBool(g_hBlockJumpRock)) return true;

	if (JumpRockReady) return false;

	return (1.5 > GetGameTime() - throwQueuedAt[client]);
}

public PutJumpRockOnCooldown(client)
{
	if (GetConVarBool(g_hBlockJumpRock)) return;

	// Disable Jump Rocks and start countdown to re-enable them
	g_fCooldownTime = GetConVarFloat(g_hJumpRockCooldown);
	JumpRockReady = false;
	CreateTimer(GetConVarFloat(g_hJumpRockCooldown), ResetJumpRockCooldown, GetClientUserId(client));
	CreateTimer(1.0, Timer_Countdown, _, TIMER_REPEAT);
	// Announce Time Until Rock is ready
	CPrintToChat(client, "<{red}JumpRock{default}> Jump Rock will be ready in {olive}%i{default} seconds!", GetConVarInt(g_hJumpRockCooldown));
}

public blah(client, int buttons)
{
	buttons |= IN_ATTACK2;
	buttons |= IN_JUMP;

	SetClientButtons(client, buttons);
}

public SetClientButtons(client, button)
{
	if(IsClientInGame(client))
		SetEntProp(client, Prop_Data, "m_nButtons", button);
}

public Action:ResetJumpRockCooldown(Handle:timer, userid)
{
	new client = GetClientOfUserId(userid);

	if (client == 0)
		return;

	JumpRockReady = true;
	CPrintToChat(client, "<{red}JumpRock{default}> Jump Rock Is {olive}Ready!");
}

public Action Timer_Countdown(Handle timer)
{
	if (g_fCooldownTime <= 0.0)
		return Plugin_Stop;

	g_fCooldownTime--;

	return Plugin_Continue;
}