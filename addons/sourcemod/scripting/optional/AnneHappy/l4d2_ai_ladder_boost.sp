#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0.1"

// ConVars
ConVar g_cvEnabled;
ConVar g_cvSpeedMultiplier;
ConVar g_cvDetectionMethod;
ConVar g_cvCooldownTime;
ConVar g_cvUseSDKHook;
ConVar g_cvDebugMode;

// 存储玩家状态
bool g_bIsOnLadder[MAXPLAYERS + 1] = {false, ...};
bool g_bSpeedBoosted[MAXPLAYERS + 1] = {false, ...};
float g_fOriginalSpeed[MAXPLAYERS + 1] = {0.0, ...};

// 冷却系统
float g_fCooldownEndTime[MAXPLAYERS + 1] = {0.0, ...}; // 冷却结束时间

// Timer句柄 (仅在非SDKHook模式使用)
Handle g_hCheckTimer = null;

public Plugin myinfo = 
{
    name = "[L4D2] Infected Ladder Speed Boost",
    author = "YourName",
    description = "特感在无生还者观察时爬梯子速度增强",
    version = PLUGIN_VERSION,
    url = ""
};

public void OnPluginStart()
{
    // 创建ConVars
    g_cvEnabled = CreateConVar("l4d2_ladder_boost_enabled", "1", "启用特感爬梯速度增强 (0=禁用, 1=启用)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvSpeedMultiplier = CreateConVar("l4d2_ladder_boost_multiplier", "10.0", "爬梯速度倍数", FCVAR_NOTIFY, true, 1.0, true, 20.0);
    g_cvDetectionMethod = CreateConVar("l4d2_ladder_boost_detection", "0", "检测方法 (0=新射线检测, 1=传统方法)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvCooldownTime = CreateConVar("l4d2_ladder_boost_cooldown", "3.0", "被发现后的冷却时间(秒)", FCVAR_NOTIFY, true, 1.0, true, 10.0);
    g_cvUseSDKHook = CreateConVar("l4d2_ladder_boost_use_sdkhook", "1", "使用SDKHook监听 (0=使用Timer, 1=使用SDKHook, 推荐)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvDebugMode = CreateConVar("l4d2_ladder_boost_debug", "0", "调试模式 (0=关闭, 1=基本调试, 2=详细调试)", FCVAR_NOTIFY, true, 0.0, true, 2.0);
    
    // 自动生成配置文件
    AutoExecConfig(true, "l4d2_infected_ladder_speed");
    
    // 注册管理员命令
    RegAdminCmd("sm_ladder_debug", Command_LadderDebug, ADMFLAG_GENERIC, "显示插件调试信息");
    RegAdminCmd("sm_ladder_status", Command_LadderStatus, ADMFLAG_GENERIC, "显示所有玩家状态");
    
    // Hook事件
    HookEvent("round_start", Event_RoundStart);
    HookEvent("round_end", Event_RoundEnd);
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("player_disconnect", Event_PlayerDisconnect);
    
    // ConVar变化监听
    g_cvEnabled.AddChangeHook(OnConVarChanged);
    g_cvUseSDKHook.AddChangeHook(OnConVarChanged);
}

public void OnPluginEnd()
{
    // 恢复所有玩家的原始速度
    for (int i = 1; i <= MaxClients; i++)
    {
        if (g_bSpeedBoosted[i])
        {
            RestorePlayerSpeed(i);
        }
    }
    
    if (g_hCheckTimer != null)
    {
        KillTimer(g_hCheckTimer);
        g_hCheckTimer = null;
    }
}

public void OnMapStart()
{
    // 对于AI特感，Timer模式更稳定，所以总是启动Timer
    if (g_cvEnabled.BoolValue)
    {
        StartCheckTimer();
    }
}

public void OnMapEnd()
{
    StopCheckTimer();
}

public void OnClientPostAdminCheck(int client)
{
    if (g_cvEnabled.BoolValue && g_cvUseSDKHook.BoolValue)
    {
        SetupClientHooks(client);
    }
}

public void OnClientDisconnect(int client)
{
    ResetClientData(client);
}

void SetupClientHooks(int client)
{
    if (!IsValidClient(client)) return;
    
    // AI特感不需要SDKHook，使用Timer模式更稳定
    if (IsFakeClient(client)) return;
    
    // Hook m_hasVisibleThreats 属性变化
    SDKHook(client, SDKHook_PostThinkPost, Hook_PostThinkPost);
    
    // Hook 移动类型变化 (检测爬梯子)
    SDKHook(client, SDKHook_PreThink, Hook_PreThink);
}

void RemoveClientHooks(int client)
{
    SDKUnhook(client, SDKHook_PostThinkPost, Hook_PostThinkPost);
    SDKUnhook(client, SDKHook_PreThink, Hook_PreThink);
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (convar == g_cvEnabled || convar == g_cvUseSDKHook)
    {
        // 重新设置所有客户端的Hook状态
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsValidClient(i))
            {
                RemoveClientHooks(i);
                if (g_cvEnabled.BoolValue)
                {
                    if (g_cvUseSDKHook.BoolValue)
                    {
                        SetupClientHooks(i);
                    }
                    else
                    {
                        StartCheckTimer();
                    }
                }
            }
            
            // 恢复增强的速度
            if (g_bSpeedBoosted[i])
            {
                RestorePlayerSpeed(i);
            }
        }
        
        // 处理Timer - 总是启动Timer以支持AI特感
        if (g_cvEnabled.BoolValue)
        {
            StartCheckTimer();
        }
        else
        {
            StopCheckTimer();
        }
    }
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    // 重置所有玩家数据
    for (int i = 1; i <= MaxClients; i++)
    {
        ResetClientData(i);
    }
    
    if (g_cvEnabled.BoolValue)
    {
        // 总是启动Timer以支持AI特感
        StartCheckTimer();
        
        if (g_cvUseSDKHook.BoolValue)
        {
            // 额外为真人玩家设置SDKHook
            for (int i = 1; i <= MaxClients; i++)
            {
                if (IsValidClient(i))
                {
                    SetupClientHooks(i);
                }
            }
        }
    }
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    StopCheckTimer();
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0 && IsValidClient(client))
    {
        ResetClientData(client);
        
        if (g_cvEnabled.BoolValue && g_cvUseSDKHook.BoolValue)
        {
            SetupClientHooks(client);
        }
    }
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0 && IsValidClient(client))
    {
        if (g_bSpeedBoosted[client])
        {
            RestorePlayerSpeed(client);
        }
        ResetClientData(client);
    }
}

void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0)
    {
        ResetClientData(client);
    }
}

void StartCheckTimer()
{
    if (!g_cvEnabled.BoolValue) return;
    
    StopCheckTimer();
    g_hCheckTimer = CreateTimer(0.5, Timer_CheckPlayers, _, TIMER_REPEAT); // 固定0.5秒间隔
}

void StopCheckTimer()
{
    if (g_hCheckTimer != null)
    {
        KillTimer(g_hCheckTimer);
        g_hCheckTimer = null;
    }
}

// SDKHook回调函数
public void Hook_PreThink(int client)
{
    if (!g_cvEnabled.BoolValue || !IsValidInfected(client)) return;
    
    bool isOnLadder = IsPlayerOnLadder(client);
    bool wasOnLadder = g_bIsOnLadder[client];
    
    g_bIsOnLadder[client] = isOnLadder;
    
    // 调试输出
    if (g_cvDebugMode.IntValue >= 2 && isOnLadder != wasOnLadder)
    {
        char name[64];
        GetClientName(client, name, sizeof(name));
        LogMessage("[调试] 玩家 %s (%d) 梯子状态变化: %s -> %s", 
            name, client, wasOnLadder ? "在梯子上" : "不在梯子上", isOnLadder ? "在梯子上" : "不在梯子上");
    }
    
    // 如果刚开始爬梯子或者刚离开梯子，触发检查
    if (isOnLadder != wasOnLadder)
    {
        if (isOnLadder)
        {
            // 开始爬梯子，检查是否需要加速
            if (g_cvDebugMode.IntValue >= 1)
            {
                char name[64];
                GetClientName(client, name, sizeof(name));
                PrintToServer("[调试] %s 开始爬梯子，检查加速条件", name);
            }
            CheckAndUpdatePlayerSpeed(client);
        }
        else if (wasOnLadder && g_bSpeedBoosted[client])
        {
            // 离开梯子，恢复速度
            if (g_cvDebugMode.IntValue >= 1)
            {
                char name[64];
                GetClientName(client, name, sizeof(name));
                PrintToServer("[调试] %s 离开梯子，恢复原始速度", name);
            }
            RestorePlayerSpeed(client);
        }
    }
}

public void Hook_PostThinkPost(int client)
{
    if (!g_cvEnabled.BoolValue) return;
    
    // 如果在梯子上，每帧检查速度状态
    if (g_bIsOnLadder[client] && IsValidInfected(client))
    {
        CheckAndUpdatePlayerSpeed(client);
    }
}

void CheckAndUpdatePlayerSpeed(int client)
{
    if (!IsValidInfected(client) || !g_bIsOnLadder[client]) return;
    
    float currentTime = GetGameTime();
    
    // 检查是否在冷却期
    if (currentTime < g_fCooldownEndTime[client])
    {
        if (g_cvDebugMode.IntValue >= 1)
        {
            char name[64];
            GetClientName(client, name, sizeof(name));
            float remainingTime = g_fCooldownEndTime[client] - currentTime;
            PrintToServer("[调试] %s 在冷却期，剩余 %.1f 秒", name, remainingTime);
        }
        
        // 冷却期内，必须恢复速度
        if (g_bSpeedBoosted[client])
        {
            RestorePlayerSpeed(client);
        }
        return;
    }
    
    bool isVisible = IsInfectedVisibleToSurvivors(client);
    
    if (g_cvDebugMode.IntValue >= 1)
    {
        char name[64];
        GetClientName(client, name, sizeof(name));
        PrintToServer("[调试] %s 在梯子上，可见性: %s，当前加速: %s", 
            name, isVisible ? "被看见" : "未被看见", g_bSpeedBoosted[client] ? "是" : "否");
    }
    
    if (isVisible)
    {
        // 被看见了，进入冷却期并恢复速度
        g_fCooldownEndTime[client] = currentTime + g_cvCooldownTime.FloatValue;
        
        if (g_cvDebugMode.IntValue >= 1)
        {
            char name[64];
            GetClientName(client, name, sizeof(name));
            PrintToServer("[调试] 🚨 %s 被发现，进入 %.1f 秒冷却期", name, g_cvCooldownTime.FloatValue);
        }
        
        if (g_bSpeedBoosted[client])
        {
            RestorePlayerSpeed(client);
        }
    }
    else if (!g_bSpeedBoosted[client])
    {
        // 未被看见且未加速，可以加速
        BoostPlayerSpeed(client);
    }
}

public Action Timer_CheckPlayers(Handle timer)
{
    if (!g_cvEnabled.BoolValue) return Plugin_Continue;
    
    // 检查所有特感状态（包括AI和真人）
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsValidInfected(client)) continue;
        
        bool isOnLadder = IsPlayerOnLadder(client);
        bool wasOnLadder = g_bIsOnLadder[client];
        
        g_bIsOnLadder[client] = isOnLadder;
        
        if (isOnLadder)
        {
            CheckAndUpdatePlayerSpeed(client);
        }
        else if (wasOnLadder && g_bSpeedBoosted[client])
        {
            // 不在梯子上但之前在，恢复速度
            RestorePlayerSpeed(client);
        }
    }
    
    return Plugin_Continue;
}

bool IsValidInfected(int client)
{
    return IsValidClient(client) && GetClientTeam(client) == 3 && IsPlayerAlive(client);
}

bool IsValidClient(int client)
{
    return client > 0 && client <= MaxClients && IsClientInGame(client) && !IsClientInKickQueue(client);
}


// 由于SourcePawn不支持try-catch，我们使用另一种方法
bool IsPlayerOnLadder(int client)
{
    // 进行更严格的有效性检查
    if (!IsValidClient(client))
        return false;
    
    if (!IsPlayerAlive(client))
        return false;
    
    if (!IsClientConnected(client))
        return false;
    
    // 检查实体是否有效
    if (!IsValidEntity(client))
        return false;
    
    if (!HasEntProp(client, Prop_Data, "m_MoveType"))
    {
        if (g_cvDebugMode.IntValue >= 2)
        {
            LogMessage("[警告] 玩家 %d 缺少 m_MoveType 属性", client);
        }
        return false;
    }

    return GetEntProp(client, Prop_Data, "m_MoveType") == view_as<int>(MOVETYPE_LADDER);
}

// 使用安全版本替换原函数
#define IsPlayerOnLadder IsPlayerOnLadderSafe

bool IsInfectedVisibleToSurvivors(int infected)
{
    if (g_cvDetectionMethod.IntValue == 0)
    {
        // 新方法: 检查有威胁感知的生还者
        return UseNewRaycastDetection(infected);
    }
    else
    {
        // 传统方法: 对所有生还者进行完整检测
        return UseTraditionalDetection(infected);
    }
}

// 新检测方法：基于威胁感知的射线检测
bool UseNewRaycastDetection(int infected)
{
    if (!IsValidInfected(infected)) return false;
    
    float infectedPos[3];
    GetClientEyePosition(infected, infectedPos);
    
    for (int survivor = 1; survivor <= MaxClients; survivor++)
    {
        if (!IsValidClient(survivor) || GetClientTeam(survivor) != 2 || !IsPlayerAlive(survivor))
            continue;
        
        // 正确逻辑：只检查有威胁感知的生还者
        // 如果生还者m_hasVisibleThreats=1，说明他看到了威胁，需要进一步确认是否看到我们这个特感
        bool hasThreats = false;
        
        // 安全地检查威胁感知属性
        if (HasEntProp(survivor, Prop_Send, "m_hasVisibleThreats"))
        {
            hasThreats = GetEntProp(survivor, Prop_Send, "m_hasVisibleThreats") > 0;
        }
        
        if (!hasThreats)
        {
            if (g_cvDebugMode.IntValue >= 2)
            {
                char survivorName[64];
                GetClientName(survivor, survivorName, sizeof(survivorName));
                PrintToServer("[调试] 跳过 %s (无威胁感知)", survivorName);
            }
            continue; // 跳过没有威胁感知的生还者
        }
        
        float survivorPos[3];
        GetClientEyePosition(survivor, survivorPos);
        float distance = GetVectorDistance(survivorPos, infectedPos);
        
        // 距离检查
        if (distance > 1500.0)
        {
            if (g_cvDebugMode.IntValue >= 2)
            {
                char survivorName[64], infectedName[64];
                GetClientName(survivor, survivorName, sizeof(survivorName));
                GetClientName(infected, infectedName, sizeof(infectedName));
                PrintToServer("[调试] %s 与 %s 距离过远 (%.1f)", survivorName, infectedName, distance);
            }
            continue;
        }
        
        // FOV检查
        if (!IsInSurvivorFOV(survivor, infected, infectedPos, survivorPos))
        {
            if (g_cvDebugMode.IntValue >= 2)
            {
                char survivorName[64], infectedName[64];
                GetClientName(survivor, survivorName, sizeof(survivorName));
                GetClientName(infected, infectedName, sizeof(infectedName));
                PrintToServer("[调试] %s 的视野中没有 %s", survivorName, infectedName);
            }
            continue;
        }
        
        // 射线检测
        Handle trace = TR_TraceRayFilterEx(survivorPos, infectedPos, MASK_VISIBLE, RayType_EndPoint, TraceFilter_IgnorePlayers);
        bool isVisible = !TR_DidHit(trace);
        CloseHandle(trace);
        
        if (g_cvDebugMode.IntValue >= 2)
        {
            char survivorName[64], infectedName[64];
            GetClientName(survivor, survivorName, sizeof(survivorName));
            GetClientName(infected, infectedName, sizeof(infectedName));
            PrintToServer("[调试] %s 射线检测 %s: %s", survivorName, infectedName, isVisible ? "✅ 可见" : "❌ 遮挡");
        }
        
        if (isVisible)
        {
            if (g_cvDebugMode.IntValue >= 1)
            {
                char survivorName[64], infectedName[64];
                GetClientName(survivor, survivorName, sizeof(survivorName));
                GetClientName(infected, infectedName, sizeof(infectedName));
                PrintToServer("[调试] 🎯 %s 被有威胁感知的 %s 确认看到", infectedName, survivorName);
            }
            return true;
        }
    }
    
    return false;
}

bool UseTraditionalDetection(int infected)
{
    if (!IsValidInfected(infected)) return false;
    
    float infectedPos[3];
    GetClientEyePosition(infected, infectedPos);
    
    for (int survivor = 1; survivor <= MaxClients; survivor++)
    {
        if (!IsValidClient(survivor) || GetClientTeam(survivor) != 2 || !IsPlayerAlive(survivor))
            continue;
        
        // 检查距离（优化性能）
        float survivorPos[3];
        GetClientEyePosition(survivor, survivorPos);
        float distance = GetVectorDistance(infectedPos, survivorPos);
        
        // 如果距离超过1500单位，跳过详细检查
        if (distance > 1500.0) continue;
        
        // 检查视线
        if (IsInSurvivorFOV(survivor, infected, infectedPos, survivorPos))
        {
            // 检查是否有障碍物遮挡
            Handle trace = TR_TraceRayFilterEx(survivorPos, infectedPos, MASK_VISIBLE, RayType_EndPoint, TraceFilter_IgnorePlayers);
            bool isVisible = !TR_DidHit(trace);
            CloseHandle(trace);
            
            if (isVisible)
            {
                return true;
            }
        }
    }
    
    return false;
}

bool IsInSurvivorFOV(int survivor, int infected, const float infectedPos[3], const float survivorPos[3])
{
    if (!IsValidClient(survivor) || !IsValidClient(infected)) return false;
    
    float survivorAngles[3];
    GetClientEyeAngles(survivor, survivorAngles);
    
    float toInfected[3];
    SubtractVectors(infectedPos, survivorPos, toInfected);
    NormalizeVector(toInfected, toInfected);
    
    float survivorForward[3];
    GetAngleVectors(survivorAngles, survivorForward, NULL_VECTOR, NULL_VECTOR);
    
    float dot = GetVectorDotProduct(survivorForward, toInfected);
    
    // FOV约90度（cos(45°) ≈ 0.707）
    return dot > 0.707;
}

public bool TraceFilter_IgnorePlayers(int entity, int contentsMask, int client)
{
    return entity > MaxClients;
}

void BoostPlayerSpeed(int client)
{
    if (!IsValidInfected(client) || g_bSpeedBoosted[client]) return;
    
    // 保存原始速度
    g_fOriginalSpeed[client] = GetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue");
    
    // 应用速度倍数
    float newSpeed = g_fOriginalSpeed[client] * g_cvSpeedMultiplier.FloatValue;
    SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", newSpeed);
    
    g_bSpeedBoosted[client] = true;
    
    // 调试输出
    if (g_cvDebugMode.IntValue >= 1)
    {
        char name[64];
        GetClientName(client, name, sizeof(name));
        PrintToServer("[调试] ✅ %s 获得爬梯加速 (%.1fx)", name, g_cvSpeedMultiplier.FloatValue);
        PrintToChatAll("[梯子加速] %s 获得爬梯加速", name);
    }
}

void RestorePlayerSpeed(int client)
{
    if (!IsValidClient(client) || !g_bSpeedBoosted[client]) return;
    
    // 恢复原始速度
    if (g_fOriginalSpeed[client] > 0.0)
    {
        SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", g_fOriginalSpeed[client]);
    }
    else
    {
        SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
    }
    
    // 调试输出
    if (g_cvDebugMode.IntValue >= 1)
    {
        char name[64];
        GetClientName(client, name, sizeof(name));
        PrintToServer("[调试] ⭕ %s 恢复原始爬梯速度", name);
        PrintToChatAll("[梯子加速] %s 恢复原始速度", name);
    }
    
    g_bSpeedBoosted[client] = false;
    g_fOriginalSpeed[client] = 0.0;
}

void ResetClientData(int client)
{
    if (client < 1 || client > MaxClients) return;
    
    g_bIsOnLadder[client] = false;
    g_bSpeedBoosted[client] = false;
    g_fOriginalSpeed[client] = 0.0;
    g_fCooldownEndTime[client] = 0.0;
}

// 管理员调试命令
public Action Command_LadderDebug(int client, int args)
{
    PrintToConsole(client, "=== 梯子加速插件调试信息 ===");
    PrintToConsole(client, "插件启用: %s", g_cvEnabled.BoolValue ? "是" : "否");
    PrintToConsole(client, "速度倍数: %.1fx", g_cvSpeedMultiplier.FloatValue);
    PrintToConsole(client, "检测方法: %s", g_cvDetectionMethod.IntValue == 0 ? "新射线检测" : "传统方法");
    PrintToConsole(client, "冷却时间: %.1f秒", g_cvCooldownTime.FloatValue);
    PrintToConsole(client, "使用SDKHook: %s", g_cvUseSDKHook.BoolValue ? "是" : "否");
    PrintToConsole(client, "调试模式: %d", g_cvDebugMode.IntValue);
    
    float currentTime = GetGameTime();
    
    PrintToConsole(client, "\n=== 玩家状态 ===");
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsValidClient(i) || !IsPlayerAlive(i)) continue;
        
        char name[64];
        GetClientName(i, name, sizeof(name));
        int team = GetClientTeam(i);
        
        if (team == 3) // 特感
        {
            bool hasThreats = false;
            if (HasEntProp(i, Prop_Send, "m_hasVisibleThreats"))
            {
                hasThreats = GetEntProp(i, Prop_Send, "m_hasVisibleThreats") > 0;
            }
            
            float cooldownRemaining = g_fCooldownEndTime[i] - currentTime;
            if (cooldownRemaining < 0) cooldownRemaining = 0.0;
            
            char botStatus[16];
            Format(botStatus, sizeof(botStatus), IsFakeClient(i) ? "[AI]" : "[真人]");
            
            PrintToConsole(client, "特感 %s%s: 梯子=%s, 加速=%s, 威胁感知=%s, 冷却=%.1fs", 
                name, botStatus,
                g_bIsOnLadder[i] ? "是" : "否",
                g_bSpeedBoosted[i] ? "是" : "否",
                hasThreats ? "是" : "否",
                cooldownRemaining);
        }
        else if (team == 2) // 生还者
        {
            bool hasThreats = false;
            if (HasEntProp(i, Prop_Send, "m_hasVisibleThreats"))
            {
                hasThreats = GetEntProp(i, Prop_Send, "m_hasVisibleThreats") > 0;
            }
            
            PrintToConsole(client, "生还者 %s: 威胁感知=%s", 
                name, 
                hasThreats ? "是" : "否");
        }
    }
    
    return Plugin_Handled;
}

public Action Command_LadderStatus(int client, int args)
{
    ReplyToCommand(client, "[梯子加速] 当前有 %d 个特感获得了爬梯加速", CountBoostedPlayers());
    
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidInfected(i) && g_bSpeedBoosted[i])
        {
            char name[64];
            GetClientName(i, name, sizeof(name));
            ReplyToCommand(client, "  - %s (%.1fx速度)", name, g_cvSpeedMultiplier.FloatValue);
        }
    }
    
    float currentTime = GetGameTime();
    int coolingDownCount = 0;
    
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidInfected(i) && currentTime < g_fCooldownEndTime[i])
        {
            coolingDownCount++;
        }
    }
    
    if (coolingDownCount > 0)
    {
        ReplyToCommand(client, "[梯子加速] 有 %d 个特感在冷却期", coolingDownCount);
    }
    
    return Plugin_Handled;
}

int CountBoostedPlayers()
{
    int count = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (g_bSpeedBoosted[i])
            count++;
    }
    return count;
}