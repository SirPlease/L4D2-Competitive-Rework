#define PLUGIN_VERSION "1.2"

#pragma semicolon 1
#include <sourcemod>
#define debug 0

#define CHECK_TIME				5.0
#define PRE_MAPCHANGE_COUNT	3

public Plugin:myinfo =
{
	name = "[L4D & L4D2] Simple AFK Manager VS",
	author = "raziEiL [disawar1]",
	description = "Players constantly take slot on your server? Plugin take care of them",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/raziEiL"
}

native L4DReady_IsReadyMode();
native IsInReady();
native fnemotes_IsClientEmoting(int client);

static	Float:g_fCvarKickT, g_iCvarAdmFlag, bool:g_bCvarImBack, g_iCvarSpecT, bool:g_bCvarTank, Handle:g_hTimer[MAXPLAYERS+1], Handle:g_hfwdOnClientAwake, Handle:g_hfwdOnClientAFK,
		Float:g_fButtonTime[MAXPLAYERS+1], bool:g_bTempBlock[MAXPLAYERS+1], bool:g_bLeft4Dead2, bool:g_bLoadLate, bool:g_bCvarKickF, g_iRoundEnd;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	// supports competitive mods
	MarkNativeAsOptional("L4DReady_IsReadyMode");
	MarkNativeAsOptional("IsInReady");
	MarkNativeAsOptional("fnemotes_IsClientEmoting");
	g_bLoadLate = late;

	return APLRes_Success;
}

public OnPluginStart()
{
	decl String:sGameFolder[32];
	GetGameFolderName(sGameFolder, 32);
	g_bLeft4Dead2 = StrEqual(sGameFolder, "left4dead2");

	g_hfwdOnClientAwake = CreateGlobalForward("SAM_OnClientAwake", ET_Ignore, Param_Cell);
	g_hfwdOnClientAFK = CreateGlobalForward("SAM_OnClientAFK", ET_Event, Param_Cell);

	CreateConVar("sam_vs_version", PLUGIN_VERSION, "Simple AFK Manager Versus plugin version", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	new Handle:hSpecT		= CreateConVar("sam_vs_spec_time",		"35", "Time before idle player will be moved to spectator in seconds", FCVAR_NOTIFY, true, 10.0);
	new Handle:hKickT		= CreateConVar("sam_vs_kick_time",		"120", "Time before idle spectator player will be kicked in seconds. 0 = never kick", FCVAR_NOTIFY, true, 0.0);
	new Handle:hImBack	= CreateConVar("sam_vs_respect_spec",	"1", "Don't kick spectators players if they is no longer AFK", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	new Handle:hTank		= CreateConVar("sam_vs_respect_tank",	"1", "Don't move AFK players to spectator if they playing as Tank", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	new Handle:hAdmin		= CreateConVar("sam_vs_respect_admins",	"k", "Admins have immunity againts AFK manager. Flag value or empty \"\" to don't protect admins", FCVAR_NOTIFY);
	new Handle:hKickF		= CreateConVar("sam_vs_force_kick",		"0", "Kicks all idle spectator players when map changes. (Requires for plugins compatibility that puts spec to spec after map change)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	AutoExecConfig(true, "SimpleAFKManagerVs");

	decl String:sFlags[2];
	GetConVarString(hAdmin, sFlags, 2);

	g_iCvarAdmFlag	= ReadFlagString(sFlags);
	g_iCvarSpecT		= GetConVarInt(hSpecT);
	g_fCvarKickT		= GetConVarFloat(hKickT);
	g_bCvarImBack	= GetConVarBool(hImBack);
	g_bCvarTank		= GetConVarBool(hTank);
	g_bCvarKickF		= GetConVarBool(hKickF);

	HookConVarChange(hSpecT,	OnCvarChange_SpecT);
	HookConVarChange(hKickT,	OnCvarChange_KickT);
	HookConVarChange(hImBack,	OnCvarChange_ImBack);
	HookConVarChange(hTank,	OnCvarChange_Tank);
	HookConVarChange(hKickF,	OnCvarChange_KickF);
	HookConVarChange(hAdmin,	OnCvarChange_Admin);

	HookEvent("player_team",	SAM_ev_PlayerTeam);
	HookEvent("player_say",	SAM_ev_PlayerSay);
	HookEvent("round_end",	SAM_ev_RoundEnd, EventHookMode_PostNoCopy);

	CreateTimer(CHECK_TIME, SAM_t_CheckIdles, _, TIMER_REPEAT);

	if (g_bLoadLate)
		for (new i = 1; i <= MaxClients; i++)
			if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) != 1)
				SetEngineTime(i);
}

public OnMapStart()
{
	g_iRoundEnd = 0;
}

public SAM_ev_RoundEnd(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if (g_bCvarKickF && ++g_iRoundEnd == PRE_MAPCHANGE_COUNT){

		for (new i = 1; i <= MaxClients; i++)
			if (g_hTimer[i] != INVALID_HANDLE)
				SAM_t_ActionKick(INVALID_HANDLE, i);
	}
}

public SAM_ev_PlayerSay(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client) return;

	if (GetClientTeam(client) != 1){

		#if debug
			PrintToChatAll("[debug] %N chatting", client);
		#endif

		SetEngineTime(client);
	}
	else
		RespectSpecCheck(client);
}

public Action:OnPlayerRunCmd(client, &buttons)
{
	if (buttons && !g_bTempBlock[client] && !IsFakeClient(client)){

		switch (GetClientTeam(client)){

			case 1:
				RespectSpecCheck(client);
			case 2:
				if (IsPlayerAlive(client))
					SAM_PluseTime(client);
			case 3:
				SAM_PluseTime(client);
		}
	}
}

SAM_PluseTime(client)
{
	#if debug
		PrintToChatAll("[debug] %N pressed a button (%d)", client, GetClientButtons(client));
	#endif

	SetEngineTime(client);

	g_bTempBlock[client] = true;
	CreateTimer(CHECK_TIME, SAM_t_Unlock, client);
}

public Action:SAM_t_Unlock(Handle:timer, any:client)
{
	g_bTempBlock[client] = false;
}

public Action:SAM_t_CheckIdles(Handle:timer)
{
	static Float:fTheTime, bool:bRUP, iTeam, Action:iResult;
	fTheTime = GetEngineTime(), bRUP = IsReadyUpActive();

	#if debug
		PrintToChatAll("[debug] SAM_t_CheckIdles()-> fired, RUP = %b!", bRUP);
	#endif

	for (new i = 1; i <= MaxClients; i++){

		if (bRUP && IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) != 1){

			g_fButtonTime[i] = fTheTime;
			continue;
		}

		if (g_fButtonTime[i] && (fTheTime - g_fButtonTime[i]) > g_iCvarSpecT){

			if (IsClientInGame(i) && (iTeam = GetClientTeam(i)) != 1){

				if (IsPlayerBussy(i, iTeam) || g_bCvarTank && iTeam == 3 && IsPlayerTank(i)){

					#if debug
						PrintToChatAll("[debug] SAM_t_CheckIdles()-> %N are bussy/tank. We skip him...", i);
					#endif

					g_fButtonTime[i] = fTheTime;
					continue;
				}

				if (fnemotes_IsClientEmoting(i))
				{
					#if debug
						PrintToChatAll("[debug] SAM_t_CheckIdles()-> %N are dancing, skip he...", i);
					#endif
					g_fButtonTime[i] = fTheTime;
					continue;
                }

				Call_StartForward(g_hfwdOnClientAFK);
				Call_PushCell(i);
				Call_Finish(iResult);

				if (iResult == Plugin_Handled){

					g_fButtonTime[i] = fTheTime;
					continue;
				}

				ChangeClientTeam(i, 1);

				#if debug
					PrintToChatAll("[debug] SAM_t_CheckIdles()-> %N moved to spec (Was AFK for %.1fsec)", i, fTheTime - g_fButtonTime[i]);
				#endif

				if (bWhoAmI(i) || !g_fCvarKickT) continue;

				g_hTimer[i] = CreateTimer(g_fCvarKickT, SAM_t_ActionKick, i, TIMER_FLAG_NO_MAPCHANGE);

				#if debug
					PrintToChatAll("[debug] SAM_t_CheckIdles()-> %N AFK, timer %x hndl", i, g_hTimer[i]);
				#endif
			}
			else
				g_fButtonTime[i] = 0.0;
		}
	}
}

public OnClientDisconnect(client)
{
	if (client){

		SAM_TimeToKill(client);
		g_fButtonTime[client] = 0.0;
	}
}

public SAM_ev_PlayerTeam(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if (GetEventBool(event, "disconnect")) return;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (client && !IsFakeClient(client) && GetEventInt(event, "team") != 1){

		SAM_TimeToKill(client);
		SetEngineTime(client);
	}
}

SAM_TimeToKill(client)
{
	if (g_hTimer[client] != INVALID_HANDLE){

		#if debug
			PrintToChatAll("[debug] SAM_TimeToKill(%N)-> Kill %x timer hndl", client, g_hTimer[client]);
		#endif

		KillTimer(g_hTimer[client]);
		g_hTimer[client] = INVALID_HANDLE;
	}
}

public Action:SAM_t_ActionKick(Handle:timer, any:client)
{
	#if debug
		PrintToChatAll("[debug] SAM_t_ActionKick(%N) Kick player", client);
	#endif

	if (IsClientInGame(client) && !bWhoAmI(client))
		KickClient(client, "你发呆太久了，下次记得闲置！");

	g_hTimer[client] = INVALID_HANDLE;
}

SetEngineTime(client)
{
	g_fButtonTime[client] = GetEngineTime();
}

RespectSpecCheck(client)
{
	if (g_bCvarImBack && g_hTimer[client] != INVALID_HANDLE){

		SAM_TimeToKill(client);

		Call_StartForward(g_hfwdOnClientAwake);
		Call_PushCell(client);
		Call_Finish();
	}
}

bool:IsReadyUpActive()
{
	return !IsServerProcessing() || (GetFeatureStatus(FeatureType_Native, "L4DReady_IsReadyMode") == FeatureStatus_Available && L4DReady_IsReadyMode() || GetFeatureStatus(FeatureType_Native, "IsInReady") == FeatureStatus_Available && IsInReady());
}

bool:IsPlayerTank(client)
{
	return GetEntProp(client, Prop_Send, "m_zombieClass") == (g_bLeft4Dead2 ? 8 : 5);
}

bool:IsPlayerBussy(client, team)
{
	return team == 2 && (!IsPlayerAlive(client) || IsSurvivorBussy(client) || GetEntProp(client, Prop_Send, "m_isIncapacitated") || GetEntProp(client, Prop_Send, "m_isHangingFromLedge")) ||
		(GetEntProp(client, Prop_Send, "m_iHealth") == 1 || IsInfectedBussy(client));
}

bool:IsSurvivorBussy(client)
{
	return GetEntProp(client, Prop_Send, "m_tongueOwner") > 0 || GetEntProp(client, Prop_Send, "m_pounceAttacker") > 0 || g_bLeft4Dead2 && (GetEntProp(client, Prop_Send, "m_pummelAttacker") > 0 || GetEntProp(client, Prop_Send, "m_jockeyAttacker") > 0);
}

bool:IsInfectedBussy(client)
{
	return GetEntProp(client, Prop_Send, "m_tongueVictim") > 0 || GetEntProp(client, Prop_Send, "m_pounceVictim") > 0 || g_bLeft4Dead2 && (GetEntProp(client, Prop_Send, "m_pummelVictim") > 0 || GetEntProp(client, Prop_Send, "m_jockeyVictim") > 0);
}

bool:bWhoAmI(client)
{
	return g_iCvarAdmFlag && GetUserFlagBits(client) && CheckCommandAccess(client, "", g_iCvarAdmFlag);
}

public OnCvarChange_SpecT(Handle:hConVar, const String:sOldVal[], const String:sNewVal[])
{
	if (!StrEqual(sOldVal, sNewVal))
		g_iCvarSpecT = GetConVarInt(hConVar);
}

public OnCvarChange_KickT(Handle:hConVar, const String:sOldVal[], const String:sNewVal[])
{
	if (!StrEqual(sOldVal, sNewVal))
		g_fCvarKickT = GetConVarFloat(hConVar);
}

public OnCvarChange_ImBack(Handle:hConVar, const String:sOldVal[], const String:sNewVal[])
{
	if (!StrEqual(sOldVal, sNewVal))
		g_bCvarImBack = GetConVarBool(hConVar);
}

public OnCvarChange_Tank(Handle:hConVar, const String:sOldVal[], const String:sNewVal[])
{
	if (!StrEqual(sOldVal, sNewVal))
		g_bCvarTank = GetConVarBool(hConVar);
}

public OnCvarChange_KickF(Handle:hConVar, const String:sOldVal[], const String:sNewVal[])
{
	if (!StrEqual(sOldVal, sNewVal))
		g_bCvarKickF = GetConVarBool(hConVar);
}

public OnCvarChange_Admin(Handle:hConVar, const String:sOldVal[], const String:sNewVal[])
{
	if (!StrEqual(sOldVal, sNewVal)){

		decl String:sFlags[2];
		GetConVarString(hConVar, sFlags, 2);
		g_iCvarAdmFlag = ReadFlagString(sFlags);
	}
}