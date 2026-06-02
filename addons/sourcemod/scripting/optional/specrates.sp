#pragma semicolon 1 
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#undef REQUIRE_PLUGIN
#include <caster_system>
#include <l4dstats>
#define REQUIRE_PLUGIN

enum L4DTeam
{
	L4DTeam_Unassigned = 0,
	L4DTeam_Spectator  = 1,
	L4DTeam_Survivor   = 2,
	L4DTeam_Infected   = 3
};

enum StatusRates
{
	RatesLimit = 0,
	RatesFree  = 1,
};

enum struct Player
{
	float       LastAdjusted;
	StatusRates Status;
}

bool
	g_bCasterSystem,
	g_bL4DStatsAvail,
	g_bLateload;

ConVar
	sv_mincmdrate,
	sv_maxcmdrate,
	sv_minupdaterate,
	sv_maxupdaterate,
	sv_minrate,
	sv_maxrate,
	sv_client_min_interp_ratio,
	sv_client_max_interp_ratio,
	cv_fullSpecNum,        // specrates_fulltickspecnum
	cv_forceSpec;          // specrates_force_spec （新增：强制旁观限速开关）

char g_sNetVars[8][8];

Player g_Players[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name        = "Lightweight Spectating (merged+128+force-spec)",
	author      = "Visor, lechuga, 东(merge) + Simth req",
	description = "Spectate/Play rate policies with admin 128-tick in play, plus force spec limiter",
	version     = "1.6-merged-128",
	url         = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("SetStatusRates", Native_SetStatusRates);
	CreateNative("GetStatusRates", Native_GetStatusRates);

	g_bLateload = late;
	RegPluginLibrary("specrates");
	return APLRes_Success;
}

public void OnAllPluginsLoaded()
{
	g_bCasterSystem   = LibraryExists("caster_system");
	g_bL4DStatsAvail  = LibraryExists("l4d_stats");
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "caster_system", true))
		g_bCasterSystem = false;
	else if (StrEqual(name, "l4d_stats", true))
		g_bL4DStatsAvail = false;
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "caster_system", true))
		g_bCasterSystem = true;
	else if (StrEqual(name, "l4d_stats", true))
		g_bL4DStatsAvail = true;
}

public void OnPluginStart()
{
	sv_mincmdrate               = FindConVar("sv_mincmdrate");
	sv_maxcmdrate               = FindConVar("sv_maxcmdrate");
	sv_minupdaterate            = FindConVar("sv_minupdaterate");
	sv_maxupdaterate            = FindConVar("sv_maxupdaterate");
	sv_minrate                  = FindConVar("sv_minrate");
	sv_maxrate                  = FindConVar("sv_maxrate");
	sv_client_min_interp_ratio  = FindConVar("sv_client_min_interp_ratio");
	sv_client_max_interp_ratio  = FindConVar("sv_client_max_interp_ratio");

	// 旁观超额阈值：超过后（除管理员/解说）一律 30 tick
	cv_fullSpecNum = CreateConVar("specrates_fulltickspecnum", "4", "旁观超过这个数量后（除管理员与解说），其余人全部30tick，无视积分");
	cv_fullSpecNum.AddChangeHook(OnFullSpecChanged);

	// ★ 新增：全局强制旁观限速开关
	cv_forceSpec = CreateConVar(
		"specrates_force_spec",
		"0",
		"开启后：旁观均30tick；管理员/解说旁观为60tick；对局内不受影响",
		FCVAR_NOTIFY, true, 0.0, true, 1.0
	);
	cv_forceSpec.AddChangeHook(OnForceSpecChanged);

	// 指令：玩家（≥30W分）设置 60tick 旁观；管理员智能：对局128 / 旁观100
	RegConsoleCmd("sm_specrates", Cmd_SetRates60, "当你分数>=30W时手动设置旁观60tick");
	RegAdminCmd("sm_adminrates", Cmd_AdminRates, ADMFLAG_GENERIC, "管理员手动提升：对局128tick/旁观100tick");

	HookEvent("player_team", OnTeamChange);

	if (!g_bLateload)
		return;

	g_bCasterSystem  = LibraryExists("caster_system");
	g_bL4DStatsAvail = LibraryExists("l4d_stats");
}

public void OnPluginEnd()
{
	// 还原服务器全局最小设置
	sv_minupdaterate.SetString(g_sNetVars[2]);
	sv_mincmdrate.SetString(g_sNetVars[0]);
}

public void OnConfigsExecuted()
{
	// 备份原值
	sv_mincmdrate.GetString(g_sNetVars[0], 8);
	sv_maxcmdrate.GetString(g_sNetVars[1], 8);
	sv_minupdaterate.GetString(g_sNetVars[2], 8);
	sv_maxupdaterate.GetString(g_sNetVars[3], 8);
	sv_minrate.GetString(g_sNetVars[4], 8);
	sv_maxrate.GetString(g_sNetVars[5], 8);
	sv_client_min_interp_ratio.GetString(g_sNetVars[6], 8);
	sv_client_max_interp_ratio.GetString(g_sNetVars[7], 8);

	// 服务器底限统一设为 30，具体按客户端所属状态 per-client 下发
	sv_minupdaterate.SetInt(30);
	sv_mincmdrate.SetInt(30);
}

public void OnClientPutInServer(int client)
{
	g_Players[client].LastAdjusted = 0.0;
	g_Players[client].Status       = RatesLimit;

	// ★ 如果开启了强制旁观限速，立即应用并返回
	if (cv_forceSpec != null && cv_forceSpec.BoolValue)
	{
		ApplyForceSpecEnforcement();
		return;
	}

	// 如果此刻旁观超额，立即把非管理员/解说的旁观都压到 30
	if (GetSpecCount() > cv_fullSpecNum.IntValue)
		ApplyFullSpecEnforcement();
}

/* -------------------------- 事件与指令 -------------------------- */

void OnTeamChange(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	CreateTimer(10.0, TimerAdjustRates, client, TIMER_FLAG_NO_MAPCHANGE);
}

Action TimerAdjustRates(Handle timer, any client)
{
	AdjustRates(client);
	return Plugin_Handled;
}

public void OnClientSettingsChanged(int client)
{
	AdjustRates(client);
}

public Action Cmd_SetRates60(int client, int args)
{
	if (!IsValidClient(client))
		return Plugin_Continue;

	if (!g_bL4DStatsAvail || l4dstats_GetClientScore(client) < 300000)
	{
		PrintToChat(client, "\x04[SpecRates]\x01 你的分数小于 30W，无法设置旁观速率。");
		return Plugin_Handled;
	}
	if (GetSpecCount() > cv_fullSpecNum.IntValue)
	{
		PrintToChat(client, "\x04[SpecRates]\x01 旁观人数超过 %d，人满仅允许 30tick。", cv_fullSpecNum.IntValue);
		return Plugin_Handled;
	}

	// 强制 60tick 旁观
	SetSpectator60(client);
	PrintToChat(client, "\x04[SpecRates]\x01 已设置为 \x0360tick\x01 旁观。");
	return Plugin_Handled;
}

public Action Cmd_AdminRates(int client, int args)
{
	if (!IsValidClient(client))
		return Plugin_Continue;

	L4DTeam team = L4D_GetClientTeam(client);
	if (team == L4DTeam_Survivor || team == L4DTeam_Infected)
	{
		SetFull128(client);
		PrintToChat(client, "\x04[SpecRates]\x01 管理员（对局）已设置为 \x03128tick\x01。");
	}
	else
	{
		ResetToServerDefaults(client); // 旁观：默认=100tick（或服配置）
		PrintToChat(client, "\x04[SpecRates]\x01 管理员（旁观）已设置为 \x03100tick\x01。");
	}
	return Plugin_Handled;
}

/* -------------------------- 逻辑核心 -------------------------- */

void AdjustRates(int client)
{
	if (!IsValidClient(client))
		return;

	if (g_Players[client].LastAdjusted > 0.0 && GetEngineTime() - g_Players[client].LastAdjusted < 1.0)
		return;

	g_Players[client].LastAdjusted = GetEngineTime();

	L4DTeam team     = L4D_GetClientTeam(client);
	bool   isAdmin   = HasAdminRateAccess(client);
	bool   isCaster  = (g_bCasterSystem && IsClientCaster(client));
	int    score     = (g_bL4DStatsAvail ? l4dstats_GetClientScore(client) : 0);
	int    specCount = GetSpecCount();

	// 对局中：非管理员 → 强制 100；管理员 → 128
	if (team == L4DTeam_Survivor || team == L4DTeam_Infected)
	{
		if (isAdmin)
			SetFull128(client);
		else
			SetFull100(client);
		return;
	}

	// 旁观：
	if (team == L4DTeam_Spectator)
	{
		// ★ 强制模式优先：管理员/解说 = 60；其他 = 30
		if (cv_forceSpec != null && cv_forceSpec.BoolValue)
		{
			if (isAdmin || isCaster)
				SetSpectator60(client);
			else
				SetSpectator30(client);
			return;
		}

		// 超额时：除管理员/解说外，一律 30
		if (specCount > cv_fullSpecNum.IntValue && !isAdmin && !isCaster)
		{
			SetSpectator30(client);
			return;
		}

		// 管理员/解说：给服务器默认（通常=100）
		if (isAdmin || isCaster)
		{
			ResetToServerDefaults(client);
			return;
		}

		// 非管理员：≥30W → 60tick；否则 30tick
		if (score >= 300000)
			SetSpectator60(client);
		else
			SetSpectator30(client);
	}
}

/* -------------------------- 速率模板 -------------------------- */

// 旁观 30tick
void SetSpectator30(int client)
{
	sv_mincmdrate.ReplicateToClient(client, "30");
	sv_maxcmdrate.ReplicateToClient(client, "30");
	sv_minupdaterate.ReplicateToClient(client, "30");
	sv_maxupdaterate.ReplicateToClient(client, "30");
	sv_minrate.ReplicateToClient(client, "10000");
	sv_maxrate.ReplicateToClient(client, "10000");

	SetClientInfo(client, "cl_updaterate", "30");
	SetClientInfo(client, "cl_cmdrate", "30");
	
	// 强制客户端立即应用这些设置
	SendConVarValue(client, sv_mincmdrate, "30");
	SendConVarValue(client, sv_maxcmdrate, "30");
	SendConVarValue(client, sv_minupdaterate, "30");
	SendConVarValue(client, sv_maxupdaterate, "30");
}

// 旁观 60tick
void SetSpectator60(int client)
{
	sv_mincmdrate.ReplicateToClient(client, "60");
	sv_maxcmdrate.ReplicateToClient(client, "60");
	sv_minupdaterate.ReplicateToClient(client, "60");
	sv_maxupdaterate.ReplicateToClient(client, "60");
	sv_minrate.ReplicateToClient(client, "20000");
	sv_maxrate.ReplicateToClient(client, "20000");

	SetClientInfo(client, "cl_updaterate", "60");
	SetClientInfo(client, "cl_cmdrate", "60");
	
	// 强制刷新
	SendConVarValue(client, sv_mincmdrate, "60");
	SendConVarValue(client, sv_maxcmdrate, "60");
	SendConVarValue(client, sv_minupdaterate, "60");
	SendConVarValue(client, sv_maxupdaterate, "60");
}

// 对局 100tick
void SetFull100(int client)
{
	sv_mincmdrate.ReplicateToClient(client, "100");
	sv_maxcmdrate.ReplicateToClient(client, "100");
	sv_minupdaterate.ReplicateToClient(client, "100");
	sv_maxupdaterate.ReplicateToClient(client, "100");
	sv_minrate.ReplicateToClient(client, g_sNetVars[4]);
	sv_maxrate.ReplicateToClient(client, g_sNetVars[5]);

	SetClientInfo(client, "cl_updaterate", "100");
	SetClientInfo(client, "cl_cmdrate", "100");
	
	// 强制刷新
	SendConVarValue(client, sv_mincmdrate, "100");
	SendConVarValue(client, sv_maxcmdrate, "100");
	SendConVarValue(client, sv_minupdaterate, "100");
	SendConVarValue(client, sv_maxupdaterate, "100");
}

// 对局 128tick
void SetFull128(int client)
{
	sv_mincmdrate.ReplicateToClient(client, "128");
	sv_maxcmdrate.ReplicateToClient(client, "128");
	sv_minupdaterate.ReplicateToClient(client, "128");
	sv_maxupdaterate.ReplicateToClient(client, "128");
	sv_minrate.ReplicateToClient(client, g_sNetVars[4]);
	sv_maxrate.ReplicateToClient(client, g_sNetVars[5]);

	SetClientInfo(client, "cl_updaterate", "128");
	SetClientInfo(client, "cl_cmdrate", "128");
	
	// 强制刷新
	SendConVarValue(client, sv_mincmdrate, "128");
	SendConVarValue(client, sv_maxcmdrate, "128");
	SendConVarValue(client, sv_minupdaterate, "128");
	SendConVarValue(client, sv_maxupdaterate, "128");
}

// 恢复到服务器默认（通常=100/100）
void ResetToServerDefaults(int client)
{
	sv_mincmdrate.ReplicateToClient(client, g_sNetVars[0]);
	sv_maxcmdrate.ReplicateToClient(client, g_sNetVars[1]);
	sv_minupdaterate.ReplicateToClient(client, g_sNetVars[2]);
	sv_maxupdaterate.ReplicateToClient(client, g_sNetVars[3]);
	sv_minrate.ReplicateToClient(client, g_sNetVars[4]);
	sv_maxrate.ReplicateToClient(client, g_sNetVars[5]);

	SetClientInfo(client, "cl_updaterate", g_sNetVars[3]);
	SetClientInfo(client, "cl_cmdrate", g_sNetVars[1]);
}

/* -------------------------- 工具函数 -------------------------- */

void OnFullSpecChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	ApplyFullSpecEnforcement();
}

void OnForceSpecChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (cv_forceSpec.BoolValue)
	{
		// 开启：立刻按强制规则重置所有旁观
		ApplyForceSpecEnforcement();
	}
	else
	{
		// 关闭：全员按当前策略重算
		RecalcAllClientRates();
	}
}

void ApplyFullSpecEnforcement()
{
	if (GetSpecCount() <= cv_fullSpecNum.IntValue)
		return;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i) || !IsClientInGame(i))
			continue;

		if (L4D_GetClientTeam(i) != L4DTeam_Spectator)
			continue;

		if (HasAdminRateAccess(i) || (g_bCasterSystem && IsClientCaster(i)))
			continue;

		SetSpectator30(i);
	}
}

void ApplyForceSpecEnforcement()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i) || !IsClientInGame(i))
			continue;

		if (L4D_GetClientTeam(i) != L4DTeam_Spectator)
			continue;

		if (HasAdminRateAccess(i) || (g_bCasterSystem && IsClientCaster(i)))
			SetSpectator60(i);
		else
			SetSpectator30(i);
	}
}

void RecalcAllClientRates()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
			AdjustRates(i);
	}
}

int GetSpecCount()
{
	int count = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsClientInGame(i) && L4D_GetClientTeam(i) == L4DTeam_Spectator)
			count++;
	}
	return count;
}

bool HasAdminRateAccess(int client)
{
	return CheckCommandAccess(client, "sm_adminrates", ADMFLAG_GENERIC);
}

// Natives
int Native_SetStatusRates(Handle plugin, int numParams)
{
	int         client = GetNativeCell(1);
	StatusRates status = view_as<StatusRates>(GetNativeCell(2));

	g_Players[client].Status = status;
	AdjustRates(client);
	return 0;
}

any Native_GetStatusRates(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return g_Players[client].Status;
}

bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client);
}

stock L4DTeam L4D_GetClientTeam(int client)
{
	return view_as<L4DTeam>(GetClientTeam(client));
}
