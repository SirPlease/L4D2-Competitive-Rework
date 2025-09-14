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

bool g_bQueuedCommandThrow[MAXPLAYERS+1];
int g_iQueuedThrow[MAXPLAYERS + 1];
ConVar g_hBlockPunchRock;
ConVar g_hBlockJumpRock;
ConVar hOverhandOnly;
bool g_bBlockJumpRock;
bool g_bOverhandOnly;

public Plugin myinfo = 
{
	name = "Tank Attack Control", 
	author = "vintik, CanadaRox, Jacob, Visor, Forgetest",
	description = "",
	version = "0.8",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin supports Left 4 dead 2 only!");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("l4d2_tank_attack_control.phrases");

	//future-proof remake of the confogl feature (could be used with lgofnoc)
	g_hBlockPunchRock = CreateConVar("l4d2_block_punch_rock", "1", "Block tanks from punching and throwing a rock at the same time");
	g_hBlockJumpRock = CreateConVar("l4d2_block_jump_rock", "0", "Block tanks from jumping and throwing a rock at the same time");
	hOverhandOnly = CreateConVar("tank_overhand_only", "0", "Force tank to only throw overhand rocks.");

	g_hBlockJumpRock.AddChangeHook(OnConVarChanged);
	hOverhandOnly.AddChangeHook(OnConVarChanged);
	GetCvars();

	HookEvent("tank_spawn", TankSpawn_Event);

	RegConsoleCmd("sm_underhand", Cmd_sm_underhand);
	RegConsoleCmd("sm_overhand", Cmd_sm_overhand);
	RegConsoleCmd("sm_overonehand", Cmd_sm_overonehand);
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bBlockJumpRock = g_hBlockJumpRock.BoolValue;
	g_bOverhandOnly = hOverhandOnly.BoolValue;
}

public void OnClientConnected(int client)
{
	g_bQueuedCommandThrow[client] = false;
}

Action Cmd_sm_underhand(int client, int args)
{
	if (!client || !IsClientInGame(client) || !IsTank(client))
		return Plugin_Continue;

	g_bQueuedCommandThrow[client] = true;
	g_iQueuedThrow[client] = 2; //underhand
	return Plugin_Handled;
}

Action Cmd_sm_overhand(int client, int args)
{
	if (!client || !IsClientInGame(client) || !IsTank(client))
		return Plugin_Continue;
	
	g_bQueuedCommandThrow[client] = true;
	g_iQueuedThrow[client] = 3; //two hand overhand
	return Plugin_Handled;
}

Action Cmd_sm_overonehand(int client, int args)
{
	if (!client || !IsClientInGame(client) || !IsTank(client))
		return Plugin_Continue;
	
	g_bQueuedCommandThrow[client] = true;
	g_iQueuedThrow[client] = 1; //one hand overhand
	return Plugin_Handled;
}

void TankSpawn_Event(Event event, const char[] name, bool dontBroadcast)
{
	int tank = GetClientOfUserId(event.GetInt("userid"));
	if (!tank || !IsClientInGame(tank) || IsFakeClient(tank)) return;

	if (g_bOverhandOnly == false)
	{
		CPrintToChat(tank, "%t", "Title");
		CPrintToChat(tank, "%t", "Reload");
		CPrintToChat(tank, "%t", "Use");
		CPrintToChat(tank, "%t", "M2");
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	bool bCommandThrow = g_bQueuedCommandThrow[client];
	g_bQueuedCommandThrow[client] = false;

	if (!IsClientInGame(client) || IsFakeClient(client) || !IsTank(client))
		return Plugin_Continue;
	
	//if tank
	if ((buttons & IN_JUMP) && ShouldCancelJump(client))
	{
		buttons &= ~IN_JUMP;
	}
	
	if (bCommandThrow)
	{
		buttons |= IN_ATTACK2;
	}
	else
	{
		if (g_bOverhandOnly == false)
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
		if (g_hBlockPunchRock.BoolValue)
			return Plugin_Handled;
	}
	
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
	if (!g_bBlockJumpRock)
	{
		return false;
	}
	return IsTankThrowingRock(client);
}

bool IsTankThrowingRock(int client)
{
	int ability = GetEntPropEnt(client, Prop_Send, "m_customAbility");
	if (ability == -1)
		return false;
	
	return CThrow__IsActive(ability) || CThrow__SelectingTankAttack(ability);
}

bool IsTank(int client)
{
	return GetClientTeam(client) == L4D2Team_Infected && GetEntProp(client, Prop_Send, "m_zombieClass") == L4D2Infected_Tank;
}

CountdownTimer CThrow__GetThrowTimer(int ability)
{
	static int s_iOffs_m_throwTimer = -1;
	if (s_iOffs_m_throwTimer == -1)
		s_iOffs_m_throwTimer = FindSendPropInfo("CThrow", "m_hasBeenUsed") + 4;
	
	return view_as<CountdownTimer>(
		GetEntityAddress(ability) + view_as<Address>(s_iOffs_m_throwTimer)
	);
}

bool CThrow__IsActive(int ability)
{
	CountdownTimer ct = CThrow__GetThrowTimer(ability);
	if (!CTimer_HasStarted(ct))
		return false;
	
	return !CTimer_IsElapsed(ct);
}

bool CThrow__SelectingTankAttack(int ability)
{
	static int s_iOffs_m_bSelectingAttack = -1;
	if (s_iOffs_m_bSelectingAttack == -1)
		s_iOffs_m_bSelectingAttack = FindSendPropInfo("CThrow", "m_hasBeenUsed") + 28;
	
	return GetEntData(ability, s_iOffs_m_bSelectingAttack, 1) > 0;
}