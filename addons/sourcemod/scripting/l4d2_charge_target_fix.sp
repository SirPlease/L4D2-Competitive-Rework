#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>
#include <left4dhooks>

#define PLUGIN_VERSION "1.8"

public Plugin myinfo = 
{
	name = "[L4D2] Charger Target Fix",
	author = "Forgetest",
	description = "Fix multiple issues with charger targets.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
};

#define GAMEDATA_FILE "l4d2_charge_target_fix"
#define FUNCTION_NAME "CCharge::HandleCustomCollision"

#define KEY_ANIMSTATE "CTerrorPlayer::m_PlayerAnimState"
#define KEY_FLAG_CHARGED "CTerrorPlayerAnimState::m_bCharged"

int
	m_PlayerAnimState,
	m_bCharged;

enum AnimStateFlag // mid-way start from m_bCharged
{
	AnimState_WallSlammed		= 2,
	AnimState_GroundSlammed		= 3,
}

methodmap AnimState
{
	public AnimState(int client) {
		int ptr = GetEntData(client, m_PlayerAnimState, 4);
		if (ptr == 0)
			ThrowError("Invalid pointer to \"CTerrorPlayer::CTerrorPlayerAnimState\" (client %d).", client);
		return view_as<AnimState>(ptr);
	}
	public bool GetFlag(AnimStateFlag flag) {
		return view_as<bool>(LoadFromAddress(view_as<Address>(this) + view_as<Address>(m_bCharged) + view_as<Address>(flag), NumberType_Int8));
	}
}

#define FSOLID_NOT_SOLID 0x0004 // Are we currently not solid?
#define KNOCKDOWN_DURATION_CHARGER 2.5

int 
	g_iChargeVictim[MAXPLAYERS+1] = {-1, ...},
	g_iChargeAttacker[MAXPLAYERS+1] = {-1, ...};

bool g_bNotSolid[MAXPLAYERS+1];

enum
{
	CHARGER_COLLISION_PUMMEL = 1,
	CHARGER_COLLISION_GETUP = (1 << 1)
};
int g_iChargerCollision;
float g_flKnockdownWindow;

public void OnPluginStart()
{
	GameData gd = new GameData(GAMEDATA_FILE);
	if (!gd)
		SetFailState("Missing gamedata \""...GAMEDATA_FILE..."\"");
	
	m_PlayerAnimState = GameConfGetOffset(gd, KEY_ANIMSTATE);
	if (m_PlayerAnimState == -1)
		SetFailState("Missing offset \""...KEY_ANIMSTATE..."\"");
	
	m_bCharged = GameConfGetOffset(gd, KEY_FLAG_CHARGED);
	if (m_bCharged == -1)
		SetFailState("Missing offset \""...KEY_FLAG_CHARGED..."\"");
	
	DynamicDetour hDetour = DynamicDetour.FromConf(gd, FUNCTION_NAME);
	if (!hDetour)
		SetFailState("Missing detour setup \""...FUNCTION_NAME..."\"");
	if (!hDetour.Enable(Hook_Pre, DTR_CCharge__HandleCustomCollision))
		SetFailState("Failed to detour \""...FUNCTION_NAME..."\"");
	
	delete hDetour;
	delete gd;
	
	CreateConVarHook("z_charge_pinned_collision",
				"3",
				"Enable collision to Infected Team on Survivors pinned by charger.\n"
			...	"1 = Enable collision during pummel, 2 = Enable collision during get-up, 3 = Both, 0 = No collision at all.",
				FCVAR_SPONLY,
				true, 0.0, true, 3.0,
				CvarChg_ChargerCollision);
	
	CreateConVarHook("charger_knockdown_getup_window",
				"0.1",
				"Duration between knockdown timer ends and get-up finishes.\n"
			...	"The higher value is set, the earlier Survivors become collideable when getting up from charger.",
				FCVAR_SPONLY,
				true, 0.0, true, 4.0,
				CvarChg_KnockdownWindow);
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_incapacitated", Event_PlayerIncap);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("charger_pummel_end", Event_ChargerPummelEnd);
	HookEvent("charger_killed", Event_ChargerKilled);
	HookEvent("player_bot_replace", Event_PlayerBotReplace);
	HookEvent("bot_player_replace", Event_BotPlayerReplace);
}

// Fix charger grabbing victims of other chargers
MRESReturn DTR_CCharge__HandleCustomCollision(int ability, DHookReturn hReturn, DHookParam hParams)
{
	if (!GetEntProp(ability, Prop_Send, "m_hasBeenUsed"))
		return MRES_Ignored;
	
	int charger = GetEntPropEnt(ability, Prop_Send, "m_owner");
	if (charger == -1)
		return MRES_Ignored;
	
	int touch = hParams.Get(1);
	if (!touch || touch > MaxClients)
		return MRES_Ignored;
	
	if (g_iChargeAttacker[touch] == -1) // free for attacks
		return MRES_Ignored;
	
	if (g_iChargeAttacker[touch] == charger) // about to slam my victim
		return MRES_Ignored;
	
	// basically invalid calls at here, block
	hReturn.Value = 0;
	return MRES_Supercede;
}

void CvarChg_ChargerCollision(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iChargerCollision = convar.IntValue;
}

void CvarChg_KnockdownWindow(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flKnockdownWindow = convar.FloatValue;
}

// Fix anomaly pummel that usually happens when a Charger is carrying someone and round restarts
void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; ++i)
	{
		// clear our stuff
		g_bNotSolid[i] = false;
		g_iChargeVictim[i] = -1;
		g_iChargeAttacker[i] = -1;
		
		if (IsClientInGame(i))
		{
			// ~ CDirector::RestartScenario()
			// ~ CDirector::Restart()
			// ~ ForEachTerrorPlayer<RestartCleanup>()
			// ~ CTerrorPlayer::CleanupPlayerState()
			// ~ CTerrorPlayer::OnCarryEnded( (bClearBoth = true), (bSkipPummel = false), (bIsAttacker = true) )
			// ~ CTerrorPlayer::QueuePummelVictim( m_carryVictim.Get(), -1.0 )
			// CTerrorPlayer::UpdatePound()
			SetEntPropEnt(i, Prop_Send, "m_pummelVictim", -1);
			SetEntPropEnt(i, Prop_Send, "m_pummelAttacker", -1);
			
			// perhaps unnecessary
			L4D2_SetQueuedPummelStartTime(i, -1.0);
			L4D2_SetQueuedPummelVictim(i, -1);
			L4D2_SetQueuedPummelAttacker(i, -1);
		}
	}
}

// Remove collision on Survivor going incapped because `CTerrorPlayer::IsGettingUp` returns false in this case
// Thanks to @Alan on discord for reporting.
void Event_PlayerIncap(Event event, const char[] name, bool dontBroadcast)
{
	if (g_iChargerCollision & CHARGER_COLLISION_PUMMEL)
		return;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client))
		return;
	
	if (GetClientTeam(client) != 2)
		return;
	
	int queuedPummelAttacker = L4D2_GetQueuedPummelAttacker(client);
	if (queuedPummelAttacker == -1 || !L4D2_IsInQueuedPummel(queuedPummelAttacker))
	{
		if (GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") == -1)
			return;
	}
	
	SetPlayerSolid(client, false);
	g_bNotSolid[client] = true;
}

// Clear arrays if the victim dies to slams
void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client))
		return;
	
	int attacker = g_iChargeAttacker[client];
	if (attacker == -1)
		return;
	
	if (L4D2_IsInQueuedPummel(attacker) && L4D2_GetQueuedPummelVictim(attacker) == client)
	{
		int ability = GetEntPropEnt(attacker, Prop_Send, "m_customAbility");
		SetEntPropFloat(ability, Prop_Send, "m_nextActivationTimer", 0.2, 0);
		SetEntPropFloat(ability, Prop_Send, "m_nextActivationTimer", L4D2_GetQueuedPummelStartTime(attacker) + 0.2, 1);
	}
	
	if (g_bNotSolid[client])
	{
		SetPlayerSolid(client, true);
		g_bNotSolid[client] = false;
	}
	
	g_iChargeVictim[attacker] = -1;
	g_iChargeAttacker[client] = -1;
}

// Calls if charger has started pummelling.
void Event_ChargerPummelEnd(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client)
		return;
	
	int victimId = event.GetInt("victim");
	int victim = GetClientOfUserId(victimId);
	if (!victim || !IsClientInGame(victim))
		return;
	
	if (~g_iChargerCollision & CHARGER_COLLISION_GETUP)
	{
		KnockdownPlayer(victim, KNOCKDOWN_CHARGER);
		ExtendKnockdown(victim, false);
	}
	
	if (g_bNotSolid[victim])
	{
		SetPlayerSolid(victim, true);
		g_bNotSolid[victim] = false;
	}
	
	// Normal processes don't need special care
	g_iChargeVictim[client] = -1;
	g_iChargeAttacker[victim] = -1;
}

// Calls if charger has slammed and before pummel, or simply is cleared before slam. 
void Event_ChargerKilled(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client))
		return;
	
	int victim = g_iChargeVictim[client];
	if (victim == -1)
		return;
	
	if (~g_iChargerCollision & CHARGER_COLLISION_GETUP)
	{
		KnockdownPlayer(victim, KNOCKDOWN_CHARGER);
		
		// a small delay to be compatible with `l4d2_getup_fixes`
		RequestFrame(OnNextFrame_LongChargeKnockdown, GetClientUserId(victim));
	}
	
	if (g_bNotSolid[victim])
	{
		SetPlayerSolid(victim, true);
		g_bNotSolid[victim] = false;
	}
	
	g_iChargeVictim[client] = -1;
	g_iChargeAttacker[victim] = -1;
}

void OnNextFrame_LongChargeKnockdown(int userid)
{
	int client = GetClientOfUserId(userid);
	if (!client || !IsClientInGame(client))
		return;
	
	ExtendKnockdown(client, true);
}

void ExtendKnockdown(int client, bool isLongCharge)
{
	float flExtendTime = 0.0;
	
	if (!isLongCharge)
	{
		float flAnimTime = 85 / 30.0;
		flExtendTime = flAnimTime - KNOCKDOWN_DURATION_CHARGER - g_flKnockdownWindow;
	}
	else
	{
		AnimState pAnim = AnimState(client);
		
		float flAnimTime = 0.0;
		if (((flAnimTime = 116 / 30.0), !pAnim.GetFlag(AnimState_WallSlammed))
		  && ((flAnimTime = 119 / 30.0), !pAnim.GetFlag(AnimState_GroundSlammed)))
		{
			ExtendKnockdown(client, false);
			return;
		}
		
		float flElaspedAnimTime = flAnimTime * GetEntPropFloat(client, Prop_Send, "m_flCycle");
		flExtendTime = flAnimTime - flElaspedAnimTime - KNOCKDOWN_DURATION_CHARGER - g_flKnockdownWindow;
	}
	
	if (flExtendTime >= 0.1)
		CreateTimer(flExtendTime, Timer_ExtendKnockdown, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_ExtendKnockdown(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (!client || !IsClientInGame(client))
		return Plugin_Stop;
	
	KnockdownPlayer(client, KNOCKDOWN_CHARGER);
	
	return Plugin_Stop;
}

void Event_PlayerBotReplace(Event event, const char[] name, bool dontBroadcast)
{
	HandlePlayerReplace(GetClientOfUserId(event.GetInt("bot")), GetClientOfUserId(event.GetInt("player")));
}

void Event_BotPlayerReplace(Event event, const char[] name, bool dontBroadcast)
{
	HandlePlayerReplace(GetClientOfUserId(event.GetInt("player")), GetClientOfUserId(event.GetInt("bot")));
}

void HandlePlayerReplace(int replacer, int replacee)
{
	if (!replacer || !IsClientInGame(replacer))
		return;
	
	if (!replacee)
		replacee = -1;
	
	if (GetClientTeam(replacer) == 3)
	{
		if (g_iChargeVictim[replacee] != -1)
		{
			g_iChargeVictim[replacer] = g_iChargeVictim[replacee];
			g_iChargeAttacker[g_iChargeVictim[replacee]] = replacer;
			g_iChargeVictim[replacee] = -1;
		}
	}
	else
	{
		if (g_iChargeAttacker[replacee] != -1)
		{
			g_iChargeAttacker[replacer] = g_iChargeAttacker[replacee];
			g_iChargeVictim[g_iChargeAttacker[replacee]] = replacer;
			g_iChargeAttacker[replacee] = -1;
		}
		
		if (g_bNotSolid[replacee])
		{
			g_bNotSolid[replacer] = true;
			g_bNotSolid[replacee] = false;
		}
	}
}

public Action L4D_OnPouncedOnSurvivor(int victim, int attacker)
{
	if (g_iChargeAttacker[victim] == -1)
		return Plugin_Continue;
	
	return Plugin_Handled;
}

public Action L4D2_OnJockeyRide(int victim, int attacker)
{
	if (g_iChargeAttacker[victim] == -1)
		return Plugin_Continue;
	
	return Plugin_Handled;
}

public Action L4D_OnGrabWithTongue(int victim, int attacker)
{
	if (g_iChargeAttacker[victim] == -1)
		return Plugin_Continue;
	
	return Plugin_Handled;
}

public void L4D2_OnStartCarryingVictim_Post(int victim, int attacker)
{
	if (!victim || !IsClientInGame(victim))
		return;
	
	if (!IsPlayerAlive(victim))
		return;
	
	g_iChargeVictim[attacker] = victim;
	g_iChargeAttacker[victim] = attacker;
}

public void L4D2_OnSlammedSurvivor_Post(int victim, int attacker, bool bWallSlam, bool bDeadlyCharge)
{
	if (!victim || !IsClientInGame(victim))
		return;
	
	if (!IsPlayerAlive(victim))
		return;
	
	g_iChargeVictim[attacker] = victim;
	g_iChargeAttacker[victim] = attacker;
	
	if (~g_iChargerCollision & CHARGER_COLLISION_PUMMEL)
	{
		Handle timer = CreateTimer(1.0, Timer_KnockdownRepeat, GetClientUserId(victim), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		TriggerTimer(timer);
	}
	
	if (!IsPlayerAlive(attacker)) // compatibility with competitive 1v1
	{
		Event event = CreateEvent("charger_killed");
		event.SetInt("userid", GetClientUserId(attacker));
		
		Event_ChargerKilled(event, "charger_killed", false);
		
		event.Cancel();
	}
	
	int jockey = GetEntPropEnt(victim, Prop_Send, "m_jockeyAttacker");
	if (jockey != -1)
	{
		Dismount(jockey);
	}
	
	int smoker = GetEntPropEnt(victim, Prop_Send, "m_tongueOwner");
	if (smoker != -1)
	{
		L4D_Smoker_ReleaseVictim(victim, smoker);
	}
}

Action Timer_KnockdownRepeat(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (!client || !IsClientInGame(client))
		return Plugin_Stop;
	
	if (GetClientTeam(client) != 2)
		return Plugin_Stop;
	
	if (!IsPlayerAlive(client) || L4D_IsPlayerIncapacitated(client))
		return Plugin_Stop;
	
	int queuedPummelAttacker = L4D2_GetQueuedPummelAttacker(client);
	if (queuedPummelAttacker == -1 || !L4D2_IsInQueuedPummel(queuedPummelAttacker))
	{
		if (GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") == -1)
			return Plugin_Stop;
	}
	
	KnockdownPlayer(client, KNOCKDOWN_CHARGER);
	
	return Plugin_Continue;
}

void KnockdownPlayer(int client, int reason)
{
	SetEntProp(client, Prop_Send, "m_knockdownReason", reason);
	SetEntPropFloat(client, Prop_Send, "m_knockdownTimer", GetGameTime(), 0);
}

void SetPlayerSolid(int client, bool solid)
{
	int flags = GetEntProp(client, Prop_Data, "m_usSolidFlags");
	SetEntProp(client, Prop_Data, "m_usSolidFlags", solid ? (flags & ~FSOLID_NOT_SOLID) : (flags | FSOLID_NOT_SOLID));
}

void Dismount(int client)
{
	int flags = GetCommandFlags("dismount");
	SetCommandFlags("dismount", flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "dismount");
	SetCommandFlags("dismount", flags);
}

ConVar CreateConVarHook(const char[] name,
	const char[] defaultValue,
	const char[] description="",
	int flags=0,
	bool hasMin=false, float min=0.0,
	bool hasMax=false, float max=0.0,
	ConVarChanged callback)
{
	ConVar cv = CreateConVar(name, defaultValue, description, flags, hasMin, min, hasMax, max);
	
	Call_StartFunction(INVALID_HANDLE, callback);
	Call_PushCell(cv);
	Call_PushNullString();
	Call_PushNullString();
	Call_Finish();
	
	cv.AddChangeHook(callback);
	
	return cv;
}
