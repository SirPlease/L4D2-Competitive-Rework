#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <colors>

#define STEAMID_SIZE 32

#define L4D_TEAM_SPECTATE 1
#define L4D_TEAM_SURVIVORS 2

StringMap
    ArrLerpsValue = null,
    ArrLerpsCountChanges = null;

ConVar
    cVarReadyUpLerpChanges = null,
    cVarAllowedLerpChanges = null,
    cVarLerpChangeSpec = null,
    cVarBadLerpAction = null,
    cVarMinLerp = null,
    cVarMaxLerp = null,
    cVarMinUpdateRate = null,
    cVarMaxUpdateRate = null,
    cVarMinInterpRatio = null,
    cVarMaxInterpRatio = null,
    cVarShowLerpTeamChange = null;

bool
    IsLateLoad = false,
    isFirstHalf = true,
    isMatchLife = true,
    isTransfer = false;

// 增加：用于记录玩家的5秒警告定时器
Handle g_hLerpWarningTimer[MAXPLAYERS + 1] = { null, ... };

public Plugin myinfo =
{
    name = "LerpMonitor++",
    author = "ProdigySim, Die Teetasse, vintik, A1m`, Modified by Gemini",
    description = "Keep track of players' lerp settings with 5s warning",
    version = "2.4.3",
    url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    IsLateLoad = late;

    CreateNative("LM_GetLerpTime", LM_GetLerpTime);
    CreateNative("LM_GetCurrentLerpTime", LM_GetCurrentLerpTime);
    CreateNative("LM_GetStoredLerpTime", LM_GetStoredLerpTime);

    RegPluginLibrary("lerpmonitor");
    return APLRes_Success;
}

public void OnPluginStart()
{
    cVarAllowedLerpChanges = CreateConVar("sm_allowed_lerp_changes", "1", "Allowed number of lerp changes for a half", _, true, 0.0, true, 20.0);
    cVarLerpChangeSpec = CreateConVar("sm_lerp_change_spec", "1", "Move to spectators on exceeding lerp changes count?", _, true, 0.0, true, 1.0);
    cVarBadLerpAction = CreateConVar("sm_bad_lerp_action", "1", "What to do with a player if he is out of allowed lerp range? 1 - move to spectators, 0 - kick from server", _, true, 0.0, true, 1.0);
    cVarReadyUpLerpChanges = CreateConVar("sm_readyup_lerp_changes", "1", "Allow lerp changes during ready-up", _, true, 0.0, true, 1.0);
    cVarShowLerpTeamChange = CreateConVar("sm_show_lerp_team_changes", "1", "show a message about the player's lerp if he changes the team", _, true, 0.0, true, 1.0);
    cVarMinLerp = CreateConVar("sm_min_lerp", "0.000", "Minimum allowed lerp value", _, true, 0.000, true, 0.500);
    cVarMaxLerp = CreateConVar("sm_max_lerp", "0.067", "Maximum allowed lerp value", _, true, 0.000, true, 0.500);

    RegConsoleCmd("sm_lerps", Lerps_Cmd, "List the Lerps of all players in game");

    cVarMinUpdateRate = FindConVar("sv_minupdaterate");
    cVarMaxUpdateRate = FindConVar("sv_maxupdaterate");
    cVarMinInterpRatio = FindConVar("sv_client_min_interp_ratio");
    cVarMaxInterpRatio = FindConVar("sv_client_max_interp_ratio");

    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
    HookEvent("player_team", OnTeamChange, EventHookMode_Post);
    HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Post);
    HookEvent("player_left_start_area", Event_RoundGoesLive, EventHookMode_PostNoCopy);

    ArrLerpsValue = new StringMap();
    ArrLerpsCountChanges = new StringMap();

    LateLoad();
}

void LateLoad()
{
    if (!IsLateLoad) {
        return;
    }

    for (int i = 1; i <= MaxClients; i++) {
        if (!IsClientInGame(i) || IsFakeClient(i)) {
            continue;
        }
        ProcessPlayerLerp(i, true);
    }
}

public void OnClientPutInServer(int client)
{
    if (!IsFakeClient(client)) {
        CreateTimer(1.0, Process, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
    }
}

// 增加：玩家断开连接时清理定时器，防止报错
public void OnClientDisconnect(int client)
{
    if (g_hLerpWarningTimer[client] != null) {
        KillTimer(g_hLerpWarningTimer[client]);
        g_hLerpWarningTimer[client] = null;
    }
}

Action Process(Handle hTimer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (client > 0) {
        ProcessPlayerLerp(client);
    }
    return Plugin_Stop;
}

public void OnMapStart()
{
    isMatchLife = false;
}

public void OnMapEnd()
{
    isFirstHalf = true;
    ArrLerpsValue.Clear();
    ArrLerpsCountChanges.Clear();
}

void Event_RoundGoesLive(Event hEvent, const char[] name, bool dontBroadcast)
{
    isMatchLife = true;
}

public void OnClientSettingsChanged(int client)
{
    if (IsValidEdict(client) && !IsFakeClient(client)) {
        ProcessPlayerLerp(client);
    }
}

void Event_PlayerDisconnect(Event hEvent, const char[] name, bool dontBroadcast)
{
    char SteamID[64];
    hEvent.GetString("networkid", SteamID, sizeof(SteamID));

    if (StrContains(SteamID, "STEAM") != 0) {
        return;
    }

    ArrLerpsValue.Remove(SteamID);
}

void OnTeamChange(Event hEvent, const char[] eName, bool dontBroadcast)
{
    if (hEvent.GetInt("team") > L4D_TEAM_SPECTATE) {
        int userid = hEvent.GetInt("userid");
        int client = GetClientOfUserId(userid);
        if (client > 0 && IsClientInGame(client) && !IsFakeClient(client)) {
            if (!isTransfer) {
                CreateTimer(0.1, OnTeamChangeDelay, userid, TIMER_FLAG_NO_MAPCHANGE);
            }
        }
    }
}

Action OnTeamChangeDelay(Handle hTimer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (client > 0) {
        ProcessPlayerLerp(client, false, true);
    }
    return Plugin_Stop;
}

void Event_RoundEnd(Event hEvent, const char[] name, bool dontBroadcast)
{
    CreateTimer(0.5, Timer_RoundEndDelay, _, TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_RoundEndDelay(Handle hTimer)
{
    isFirstHalf = false;
    isTransfer = true;
    isMatchLife = false;
    ArrLerpsCountChanges.Clear();
    return Plugin_Stop;
}

Action Lerps_Cmd(int client, int args)
{
    int iCount = 0;
    if (ArrLerpsValue.Size > 0) {
        ReplyToCommand(client, "[!] Lerp setting list:");

        float fLerpValue;
        char sSteamID[STEAMID_SIZE];
        for (int i = 1; i <= MaxClients; i++) {
            if (IsClientInGame(i) && !IsFakeClient(i)) {
                GetClientAuthId(i, AuthId_Steam2, sSteamID, sizeof(sSteamID));

                if (ArrLerpsValue.GetValue(sSteamID, fLerpValue)) {
                    ReplyToCommand(client, "%N [%s]: %.01f", i, sSteamID, fLerpValue * 1000);
                    iCount++;
                }
            }
        }
    }

    if (iCount == 0) {
        ReplyToCommand(client, "There is nothing here!");
    }

    return Plugin_Handled;
}

void Event_RoundStart(Event hEvent, const char[] name, bool dontBroadcast)
{
    if (!isFirstHalf) {
        ArrLerpsCountChanges.Clear();
    }
    CreateTimer(0.5, OnTransfer, _, TIMER_FLAG_NO_MAPCHANGE);
}

Action OnTransfer(Handle hTimer)
{
    isTransfer = false;
    return Plugin_Stop;
}

void ProcessPlayerLerp(int client, bool load = false, bool team = false)
{
    float newLerpTime = GetLerpTime(client);

    SetEntPropFloat(client, Prop_Data, "m_fLerpTime", newLerpTime);

    if (GetClientTeam(client) < L4D_TEAM_SURVIVORS) {
        return;
    }

    char steamID[STEAMID_SIZE];
    GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID));

    // 修改点：处理超出允许范围的Lerp，给予5秒修改时间
    if ((FloatCompare(newLerpTime, cVarMinLerp.FloatValue) == -1)  || (FloatCompare(newLerpTime, cVarMaxLerp.FloatValue) == 1)) {
        if (load) {
            return;
        }

        if (g_hLerpWarningTimer[client] == null) {
            CPrintToChatEx(client, client, "{default}<{olive}Lerp{default}> {teamcolor}警告:{default} 你的Lerp值非法 (最小: {teamcolor}%.01f{default}, 最大: {teamcolor}%.01f{default})! 请在 5 秒内改回来。", cVarMinLerp.FloatValue * 1000, cVarMaxLerp.FloatValue * 1000);
            g_hLerpWarningTimer[client] = CreateTimer(5.0, Timer_CheckBadLerpRange, GetClientUserId(client));
        }
        return;
    } 
    else {
        // 如果玩家在5秒内改回了合法的Lerp，取消定时器并通知
        if (g_hLerpWarningTimer[client] != null) {
            KillTimer(g_hLerpWarningTimer[client]);
            g_hLerpWarningTimer[client] = null;
            CPrintToChatEx(client, client, "{default}<{olive}Lerp{default}> 感谢配合, Lerp已恢复到合法范围。");
        }
    }

    float currentLerpTime = 0.0;
    if (!ArrLerpsValue.GetValue(steamID, currentLerpTime)) {
        if (team && cVarShowLerpTeamChange.BoolValue) {
            CPrintToChatAllEx(client, "{default}<{olive}Lerp{default}> {teamcolor}%N {default}@ {teamcolor}%.01f", client, newLerpTime * 1000);
        }
        ArrLerpsValue.SetValue(steamID, newLerpTime, true);
        return;
    }

    if (currentLerpTime == newLerpTime) { 
        if (team && cVarShowLerpTeamChange.BoolValue) {
            CPrintToChatAllEx(client, "{default}<{olive}Lerp{default}> {teamcolor}%N {default}@ {teamcolor}%.01f", client, newLerpTime * 1000);
        }
        return;
    }

    if (isMatchLife || !cVarReadyUpLerpChanges.BoolValue) { 
        int count = 0;
        ArrLerpsCountChanges.GetValue(steamID, count);
        count++;

        int max = cVarAllowedLerpChanges.IntValue;
        CPrintToChatAllEx(client, "{default}<{olive}Lerp{default}> {teamcolor}%N {default}@ {teamcolor}%.01f {default}<== {teamcolor}%.01f {default}[%s%d{default}/%d {olive}changes]", client, newLerpTime * 1000, currentLerpTime * 1000, ((count > max) ? "{teamcolor} ": ""), count, max);

        if (cVarLerpChangeSpec.BoolValue && (count > max)) {
            CPrintToChatAllEx(client, "{default}<{olive}Lerp{default}> {teamcolor}%N {default}被移动到旁观者 (不合法的lerp改变)!", client);
            ChangeClientTeam(client, L4D_TEAM_SPECTATE);
            CPrintToChatEx(client, client, "{default}<{olive}Lerp{default}> 游戏里不合法的更改lerp! 将lerp改回 {teamcolor}%.01f", currentLerpTime * 1000);
            return;
        }

        ArrLerpsCountChanges.SetValue(steamID, count); 
    } else {
        CPrintToChatAllEx(client, "{default}<{olive}Lerp{default}> {teamcolor}%N {default}@ {teamcolor}%.01f {default}<== {teamcolor}%.01f", client, newLerpTime * 1000, currentLerpTime * 1000);
    }

    ArrLerpsValue.SetValue(steamID, newLerpTime); 
}

// 增加：5秒后二次验证Lerp的回调函数
Action Timer_CheckBadLerpRange(Handle timer, int userid) {
    int client = GetClientOfUserId(userid);
    
    // 确保玩家还在服务器且在生还者阵营才执行惩罚
    if (client > 0 && IsClientInGame(client)) {
        g_hLerpWarningTimer[client] = null; // 清除Handle
        
        if (GetClientTeam(client) < L4D_TEAM_SURVIVORS) {
            return Plugin_Stop;
        }

        float newLerpTime = GetLerpTime(client);
        
        // 5秒后再次判断，如果还是非法值，则执行对应惩罚
        if ((FloatCompare(newLerpTime, cVarMinLerp.FloatValue) == -1)  || (FloatCompare(newLerpTime, cVarMaxLerp.FloatValue) == 1)) {
            if (cVarBadLerpAction.IntValue == 1) {
                CPrintToChatAllEx(client, "{default}<{olive}Lerp{default}> {teamcolor}%N {default}因未在5秒内调整Lerp至合法范围，被移至旁观者", client);
                ChangeClientTeam(client, L4D_TEAM_SPECTATE);
            } else {
                CPrintToChatAllEx(client, "{default}<{olive}Lerp{default}> {teamcolor}%N {default}因未在5秒内调整Lerp至合法范围，被踢出游戏", client);
                KickClient(client, "Illegal lerp value (min: %.01f, max: %.01f)", cVarMinLerp.FloatValue * 1000, cVarMaxLerp.FloatValue * 1000);
            }
        }
    }
    return Plugin_Stop;
}

float GetLerpTime(int client)
{
    char buffer[64];

    if (!GetClientInfo(client, "cl_updaterate", buffer, sizeof(buffer))) {
        buffer = "";
    }

    int updateRate = StringToInt(buffer);
    updateRate = RoundFloat(clamp(float(updateRate), cVarMinUpdateRate.FloatValue, cVarMaxUpdateRate.FloatValue));

    if (!GetClientInfo(client, "cl_interp_ratio", buffer, sizeof(buffer))) {
        buffer = "";
    }

    float flLerpRatio = StringToFloat(buffer);

    if (!GetClientInfo(client, "cl_interp", buffer, sizeof(buffer))) {
        buffer = "";
    }

    float flLerpAmount = StringToFloat(buffer);

    if (cVarMinInterpRatio != null && cVarMaxInterpRatio != null && cVarMinInterpRatio.FloatValue != -1.0) {
        flLerpRatio = clamp(flLerpRatio, cVarMinInterpRatio.FloatValue, cVarMaxInterpRatio.FloatValue);
    }

    return maximum(flLerpAmount, flLerpRatio / updateRate);
}

float maximum(float a, float b)
{
    return (a > b) ? a : b;
}

float clamp(float inc, float low, float high)
{
    return (inc > high) ? high : ((inc < low) ? low : inc);
}

int LM_GetLerpTime(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    char sSteamID[STEAMID_SIZE];
    GetClientAuthId(client, AuthId_Steam2, sSteamID, sizeof(sSteamID));

    float fLerpValue = -1.0;
    if (ArrLerpsValue.GetValue(sSteamID, fLerpValue)) {
        return view_as<int>(fLerpValue);
    }

    return view_as<int>(GetLerpTime(client));
}

int LM_GetCurrentLerpTime(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    return view_as<int>(GetLerpTime(client));
}

int LM_GetStoredLerpTime(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    char sSteamID[STEAMID_SIZE];
    GetClientAuthId(client, AuthId_Steam2, sSteamID, sizeof(sSteamID));

    float fLerpValue = -1.0;
    if (ArrLerpsValue.GetValue(sSteamID, fLerpValue)) {
        return view_as<int>(fLerpValue);
    }

    return view_as<int>(-1.0);
}
