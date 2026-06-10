#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

#define PLUGIN_VERSION "1.1.0"

#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3
#define ZC_SMOKER 1
#define ZC_BOOMER 2
#define ZC_HUNTER 3
#define ZC_SPITTER 4
#define ZC_JOCKEY 5
#define ZC_CHARGER 6
#define ZC_TANK 8

#define NORMAL_SPEED 1.0
#define SPEED_EPSILON 0.01
#define CHECK_INTERVAL 0.5

ConVar g_cvEnabled;
ConVar g_cvSpeedMultiplier;
ConVar g_cvDetectionMethod;
ConVar g_cvCooldownTime;
ConVar g_cvUseSDKHook;
ConVar g_cvDebugMode;

// Compatibility cvars from l4d2_si_ladder_booster.sp.
ConVar g_cvAiLadderBoost;
ConVar g_cvPzLadderBoost;
ConVar g_cvLegacyBoostMultiplier;
ConVar g_cvTankLadderBoost;
ConVar g_cvClimbAnimBoost;
ConVar g_cvSiClimbAnimRate;
ConVar g_cvTankClimbAnimRate;
ConVar g_cvTankLowClimbAnimRate;
ConVar g_cvTankLadderAnimRate;
ConVar g_cvClampExitSpeed;

bool g_bIsOnLadder[MAXPLAYERS + 1] = {false, ...};
bool g_bSpeedBoosted[MAXPLAYERS + 1] = {false, ...};
bool g_bWasOnLadder[MAXPLAYERS + 1] = {false, ...};
bool g_bClimbAnimBoosted[MAXPLAYERS + 1] = {false, ...};
bool g_bAnimHooked[MAXPLAYERS + 1] = {false, ...};
float g_fOriginalSpeed[MAXPLAYERS + 1] = {0.0, ...};
float g_fActiveMultiplier[MAXPLAYERS + 1] = {0.0, ...};
float g_fCooldownEndTime[MAXPLAYERS + 1] = {0.0, ...};

Handle g_hCheckTimer = null;
StringMap g_hTankClimbAnimMap;
StringMap g_hTankLowClimbAnimMap;

enum ClimbSequenceType
{
    ClimbSequence_High,
    ClimbSequence_Low
}

public Plugin myinfo =
{
    name = "[L4D2] Infected Ladder Speed Boost",
    author = "YourName, AiMee, AnneHappy",
    description = "Merged infected ladder booster with visibility-gated boost and climb animation controls",
    version = PLUGIN_VERSION,
    url = ""
};

public void OnPluginStart()
{
    LoadTranslations("l4d2_ai_ladder_boost.phrases");

    g_cvEnabled = CreateConVar("l4d2_ladder_boost_enabled", "1", "启用未被生还者看见时的特感爬梯加速 (0=禁用, 1=启用)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvSpeedMultiplier = CreateConVar("l4d2_ladder_boost_multiplier", "10.0", "未被看见时的爬梯速度倍数", FCVAR_NOTIFY, true, 1.0, true, 20.0);
    g_cvDetectionMethod = CreateConVar("l4d2_ladder_boost_detection", "0", "检测方法 (0=威胁感知+射线, 1=传统FOV+射线)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvCooldownTime = CreateConVar("l4d2_ladder_boost_cooldown", "3.0", "被看见后禁用未视野加速的冷却时间(秒)", FCVAR_NOTIFY, true, 1.0, true, 10.0);
    g_cvUseSDKHook = CreateConVar("l4d2_ladder_boost_use_sdkhook", "1", "真人特感使用SDKHook即时检测 (0=只使用Timer, 1=使用SDKHook)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvDebugMode = CreateConVar("l4d2_ladder_boost_debug", "0", "调试模式 (0=关闭, 1=基本调试, 2=详细调试)", FCVAR_NOTIFY, true, 0.0, true, 2.0);

    g_cvAiLadderBoost = CreateConVar("l4d2_ai_ladder_boost", "1", "兼容旧l4d2_si_ladder_booster：AI特感在梯子上固定加速", FCVAR_SPONLY, true, 0.0, true, 1.0);
    g_cvPzLadderBoost = CreateConVar("l4d2_pz_ladder_boost", "0", "兼容旧l4d2_si_ladder_booster：真人特感在梯子上固定加速", FCVAR_SPONLY, true, 0.0, true, 1.0);
    g_cvLegacyBoostMultiplier = CreateConVar("l4d2_boost_multiplier", "3.2", "兼容旧l4d2_si_ladder_booster：固定爬梯加速倍数", FCVAR_SPONLY, true, 1.0, true, 10.0);
    g_cvTankLadderBoost = CreateConVar("l4d2_ladder_boost_tank", "1", "是否允许该通用插件加速Tank爬梯", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvClimbAnimBoost = CreateConVar("l4d2_climb_anim_boost", "1", "是否由该插件处理特感翻越/爬小障碍动画加速", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvSiClimbAnimRate = CreateConVar("l4d2_si_climb_anim_rate", "3.2", "非Tank特感翻越/爬小障碍动画播放倍速（1.0=原速）", FCVAR_NOTIFY, true, 0.0);
    g_cvTankClimbAnimRate = CreateConVar("l4d2_tank_climb_anim_rate", "3.5", "Tank 高翻越动画播放倍速（1.0=原速）", FCVAR_NOTIFY, true, 0.0);
    g_cvTankLowClimbAnimRate = CreateConVar("l4d2_tank_low_climb_anim_rate", "2.5", "Tank 低翻越动画播放倍速（1.0=原速）", FCVAR_NOTIFY, true, 0.0);
    g_cvTankLadderAnimRate = CreateConVar("l4d2_tank_ladder_anim_rate", "1.0", "Tank 梯子动画播放倍速；真实爬梯速度由 m_flLaggedMovementValue 控制", FCVAR_NOTIFY, true, 0.0);
    g_cvClampExitSpeed = CreateConVar("l4d2_ladder_boost_clamp_exit_speed", "1", "特感离开梯子时将水平速度限制到当前走路速度，防止10倍速度带出", FCVAR_NOTIFY, true, 0.0, true, 1.0);

    AutoExecConfig(true, "l4d2_infected_ladder_speed");

    InitClimbAnimMaps();

    RegAdminCmd("sm_ladder_debug", Command_LadderDebug, ADMFLAG_GENERIC, "显示插件调试信息");
    RegAdminCmd("sm_ladder_status", Command_LadderStatus, ADMFLAG_GENERIC, "显示所有玩家状态");

    HookEvent("round_start", Event_RoundStart);
    HookEvent("round_end", Event_RoundEnd);
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("player_disconnect", Event_PlayerDisconnect);

    HookBoostCvars();
}

void HookBoostCvars()
{
    g_cvEnabled.AddChangeHook(OnConVarChanged);
    g_cvSpeedMultiplier.AddChangeHook(OnConVarChanged);
    g_cvUseSDKHook.AddChangeHook(OnConVarChanged);
    g_cvAiLadderBoost.AddChangeHook(OnConVarChanged);
    g_cvPzLadderBoost.AddChangeHook(OnConVarChanged);
    g_cvLegacyBoostMultiplier.AddChangeHook(OnConVarChanged);
    g_cvTankLadderBoost.AddChangeHook(OnConVarChanged);
    g_cvClimbAnimBoost.AddChangeHook(OnConVarChanged);
    g_cvSiClimbAnimRate.AddChangeHook(OnConVarChanged);
    g_cvTankClimbAnimRate.AddChangeHook(OnConVarChanged);
    g_cvTankLowClimbAnimRate.AddChangeHook(OnConVarChanged);
    g_cvTankLadderAnimRate.AddChangeHook(OnConVarChanged);
    g_cvClampExitSpeed.AddChangeHook(OnConVarChanged);
}

public void OnPluginEnd()
{
    StopCheckTimer();

    for (int i = 1; i <= MaxClients; i++)
    {
        if (g_bSpeedBoosted[i])
        {
            RestorePlayerSpeed(i);
        }
        RestorePlaybackRate(i);
        RemoveAnimationHook(i);
        RemoveClientHooks(i);
    }

    delete g_hTankClimbAnimMap;
    delete g_hTankLowClimbAnimMap;
}

public void OnMapStart()
{
    RefreshRuntimeHooks();
}

public void OnMapEnd()
{
    StopCheckTimer();

    for (int i = 1; i <= MaxClients; i++)
    {
        g_bAnimHooked[i] = false;
        g_bClimbAnimBoosted[i] = false;
    }
}

public void OnClientPostAdminCheck(int client)
{
    if (ShouldRunBoostChecks() && g_cvUseSDKHook.BoolValue)
    {
        SetupClientHooks(client);
    }

    SetupAnimationHook(client);
}

public void OnClientDisconnect(int client)
{
    RemoveClientHooks(client);
    RemoveAnimationHook(client);
    ResetClientData(client);
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    RefreshRuntimeHooks();

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsValidClient(i))
        {
            continue;
        }

        CheckAndUpdatePlayerSpeed(i);
    }
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (g_bSpeedBoosted[i])
        {
            RestorePlayerSpeed(i);
        }
        RestorePlaybackRate(i);

        ResetClientData(i);
    }

    RefreshRuntimeHooks();
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    StopCheckTimer();
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client <= 0 || !IsValidClient(client))
    {
        return;
    }

    if (g_bSpeedBoosted[client])
    {
        RestorePlayerSpeed(client);
    }
    RestorePlaybackRate(client);

    ResetClientData(client);

    if (ShouldRunBoostChecks() && g_cvUseSDKHook.BoolValue)
    {
        SetupClientHooks(client);
    }

    SetupAnimationHook(client);
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client <= 0)
    {
        return;
    }

    if (g_bSpeedBoosted[client])
    {
        RestorePlayerSpeed(client);
    }
    RestorePlaybackRate(client);

    ResetClientData(client);
}

void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0)
    {
        RemoveClientHooks(client);
        RemoveAnimationHook(client);
        ResetClientData(client);
    }
}

void RefreshRuntimeHooks()
{
    bool shouldRun = ShouldRunBoostChecks();
    if (shouldRun)
    {
        StartCheckTimer();
    }
    else
    {
        StopCheckTimer();
    }

    for (int i = 1; i <= MaxClients; i++)
    {
        RemoveClientHooks(i);

        if (shouldRun && g_cvUseSDKHook.BoolValue && IsValidClient(i))
        {
            SetupClientHooks(i);
        }

        if (IsValidClient(i))
        {
            SetupAnimationHook(i);
        }
    }
}

bool ShouldRunBoostChecks()
{
    return g_cvEnabled.BoolValue || g_cvAiLadderBoost.BoolValue || g_cvPzLadderBoost.BoolValue || g_cvTankLadderBoost.BoolValue;
}

void StartCheckTimer()
{
    if (!ShouldRunBoostChecks())
    {
        return;
    }

    StopCheckTimer();
    g_hCheckTimer = CreateTimer(CHECK_INTERVAL, Timer_CheckPlayers, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

void StopCheckTimer()
{
    if (g_hCheckTimer == null)
    {
        return;
    }

    KillTimer(g_hCheckTimer);
    g_hCheckTimer = null;
}

void SetupClientHooks(int client)
{
    if (!IsValidClient(client) || IsFakeClient(client))
    {
        return;
    }

    SDKHook(client, SDKHook_PreThink, Hook_PreThink);
    SDKHook(client, SDKHook_PostThinkPost, Hook_PostThinkPost);
}

void RemoveClientHooks(int client)
{
    if (client < 1 || client > MaxClients)
    {
        return;
    }

    SDKUnhook(client, SDKHook_PreThink, Hook_PreThink);
    SDKUnhook(client, SDKHook_PostThinkPost, Hook_PostThinkPost);
}

void SetupAnimationHook(int client)
{
    if (!IsValidClient(client) || GetClientTeam(client) != TEAM_INFECTED || g_bAnimHooked[client])
    {
        return;
    }

    AnimHookEnable(client, INVALID_FUNCTION, Hook_AnimationPost);
    SDKHook(client, SDKHook_PostThinkPost, Hook_ClimbAnimThink);
    g_bAnimHooked[client] = true;
}

void RemoveAnimationHook(int client)
{
    if (client < 1 || client > MaxClients || !g_bAnimHooked[client])
    {
        return;
    }

    if (!IsValidClient(client))
    {
        g_bAnimHooked[client] = false;
        return;
    }

    AnimHookDisable(client, INVALID_FUNCTION, Hook_AnimationPost);
    SDKUnhook(client, SDKHook_PostThinkPost, Hook_ClimbAnimThink);
    g_bAnimHooked[client] = false;
}

Action Hook_AnimationPost(int client, int &sequence)
{
    if (!g_cvClimbAnimBoost.BoolValue || !IsValidInfected(client))
    {
        return Plugin_Continue;
    }

    float rate = GetClimbPlaybackRate(client, sequence);
    if (rate <= NORMAL_SPEED + SPEED_EPSILON)
    {
        return Plugin_Continue;
    }

    SetClientPlaybackRate(client, rate);
    g_bClimbAnimBoosted[client] = true;
    return Plugin_Continue;
}

public void Hook_ClimbAnimThink(int client)
{
    if (!g_cvClimbAnimBoost.BoolValue || !IsValidInfected(client))
    {
        RestorePlaybackRate(client);
        return;
    }

    if (IsTank(client) && IsPlayerOnLadder(client))
    {
        float ladderRate = g_cvTankLadderAnimRate.FloatValue;
        if (ladderRate > NORMAL_SPEED + SPEED_EPSILON)
        {
            SetClientPlaybackRate(client, ladderRate);
            g_bClimbAnimBoosted[client] = true;
            return;
        }
    }

    int sequence = GetEntProp(client, Prop_Data, "m_nSequence");
    float rate = GetClimbPlaybackRate(client, sequence);
    if (rate > NORMAL_SPEED + SPEED_EPSILON)
    {
        SetClientPlaybackRate(client, rate);
        g_bClimbAnimBoosted[client] = true;
        return;
    }

    RestorePlaybackRate(client);
}

public void Hook_PreThink(int client)
{
    if (!ShouldRunBoostChecks() || !IsValidInfected(client))
    {
        return;
    }

    bool isOnLadder = IsPlayerOnLadder(client);
    bool wasOnLadder = g_bIsOnLadder[client];
    g_bIsOnLadder[client] = isOnLadder;

    if (g_cvDebugMode.IntValue >= 2 && isOnLadder != wasOnLadder)
    {
        char name[64];
        GetClientName(client, name, sizeof(name));
        LogMessage("[LadderBoost] %s(%d) ladder state: %s -> %s",
            name, client, wasOnLadder ? "on" : "off", isOnLadder ? "on" : "off");
    }

    if (isOnLadder != wasOnLadder)
    {
        CheckAndUpdatePlayerSpeed(client);
    }
}

public void Hook_PostThinkPost(int client)
{
    if (!ShouldRunBoostChecks() || !g_bIsOnLadder[client] || !IsValidInfected(client))
    {
        return;
    }

    CheckAndUpdatePlayerSpeed(client);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3])
{
    if (!g_bSpeedBoosted[client] && !g_bWasOnLadder[client])
    {
        return Plugin_Continue;
    }

    if (!IsValidInfected(client))
    {
        RestorePlayerSpeed(client);
        g_bIsOnLadder[client] = false;
        g_bWasOnLadder[client] = false;
        return Plugin_Continue;
    }

    bool isOnLadder = IsPlayerOnLadder(client);
    if (!isOnLadder || !IsClassAllowedForBoost(client))
    {
        if (g_bWasOnLadder[client])
        {
            ClampClientExitVelocity(client);
        }
        RestorePlayerSpeed(client);
        g_bIsOnLadder[client] = false;
        g_bWasOnLadder[client] = false;
        return Plugin_Continue;
    }

    g_bWasOnLadder[client] = true;
    CheckAndUpdatePlayerSpeed(client);

    return Plugin_Continue;
}

public Action Timer_CheckPlayers(Handle timer)
{
    if (!ShouldRunBoostChecks())
    {
        g_hCheckTimer = null;
        return Plugin_Stop;
    }

    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsValidClient(client))
        {
            continue;
        }

        CheckAndUpdatePlayerSpeed(client);
    }

    return Plugin_Continue;
}

void CheckAndUpdatePlayerSpeed(int client)
{
    if (!IsValidClient(client))
    {
        return;
    }

    if (!IsValidInfected(client))
    {
        if (g_bSpeedBoosted[client])
        {
            RestorePlayerSpeed(client);
        }
        g_bIsOnLadder[client] = false;
        return;
    }

    bool isOnLadder = IsPlayerOnLadder(client);
    g_bIsOnLadder[client] = isOnLadder;

    if (!isOnLadder || !IsClassAllowedForBoost(client))
    {
        if (g_bSpeedBoosted[client])
        {
            if (g_bWasOnLadder[client])
            {
                ClampClientExitVelocity(client);
            }
            RestorePlayerSpeed(client);
        }
        if (!isOnLadder)
        {
            g_bWasOnLadder[client] = false;
        }
        return;
    }

    g_bWasOnLadder[client] = true;
    float multiplier = GetDesiredBoostMultiplier(client);
    if (multiplier <= NORMAL_SPEED + SPEED_EPSILON)
    {
        if (g_bSpeedBoosted[client])
        {
            RestorePlayerSpeed(client);
        }
        return;
    }

    ApplyPlayerSpeed(client, multiplier);
}

float GetDesiredBoostMultiplier(int client)
{
    float multiplier = NORMAL_SPEED;
    bool fakeClient = IsFakeClient(client);
    bool tank = IsTank(client);

    if (tank && g_cvTankLadderBoost.BoolValue)
    {
        multiplier = MaxFloat(multiplier, g_cvLegacyBoostMultiplier.FloatValue);
    }

    if (!tank && fakeClient && g_cvAiLadderBoost.BoolValue)
    {
        multiplier = MaxFloat(multiplier, g_cvLegacyBoostMultiplier.FloatValue);
    }

    if (!tank && !fakeClient && g_cvPzLadderBoost.BoolValue && !IsInfectedGhost(client))
    {
        multiplier = MaxFloat(multiplier, g_cvLegacyBoostMultiplier.FloatValue);
    }

    if (!tank && g_cvEnabled.BoolValue && IsSightBoostAllowed(client))
    {
        multiplier = MaxFloat(multiplier, g_cvSpeedMultiplier.FloatValue);
    }

    return multiplier;
}

bool IsSightBoostAllowed(int client)
{
    float currentTime = GetGameTime();
    if (currentTime < g_fCooldownEndTime[client])
    {
        if (g_cvDebugMode.IntValue >= 1)
        {
            char name[64];
            GetClientName(client, name, sizeof(name));
            PrintToServer("[LadderBoost] %s sight boost cooldown %.1fs", name, g_fCooldownEndTime[client] - currentTime);
        }
        return false;
    }

    bool visible = IsInfectedVisibleToSurvivors(client);

    if (g_cvDebugMode.IntValue >= 1)
    {
        char name[64];
        GetClientName(client, name, sizeof(name));
        PrintToServer("[LadderBoost] %s visible=%s boosted=%s",
            name, visible ? "yes" : "no", g_bSpeedBoosted[client] ? "yes" : "no");
    }

    if (visible)
    {
        g_fCooldownEndTime[client] = currentTime + g_cvCooldownTime.FloatValue;
        return false;
    }

    return true;
}

void ApplyPlayerSpeed(int client, float multiplier)
{
    if (!g_bSpeedBoosted[client])
    {
        g_fOriginalSpeed[client] = GetClientSpeed(client);
        if (g_fOriginalSpeed[client] <= 0.0)
        {
            g_fOriginalSpeed[client] = NORMAL_SPEED;
        }
        g_bSpeedBoosted[client] = true;
    }

    float desiredSpeed = multiplier;
    float currentSpeed = GetClientSpeed(client);
    if (FloatAbs(currentSpeed - desiredSpeed) > SPEED_EPSILON)
    {
        SetClientSpeed(client, desiredSpeed);
    }

    if (FloatAbs(g_fActiveMultiplier[client] - multiplier) > SPEED_EPSILON && g_cvDebugMode.IntValue >= 1)
    {
        char name[64];
        GetClientName(client, name, sizeof(name));
        PrintToServer("[LadderBoost] %s ladder speed %.1fx", name, multiplier);
        PrintToChatAll("%t", "L4D2AILadderBoost_LadderAccelerationGetLadderAcceleration", name);
    }

    g_fActiveMultiplier[client] = multiplier;
}

void RestorePlayerSpeed(int client, bool clampVelocity = false)
{
    if (!IsValidClient(client) || !g_bSpeedBoosted[client])
    {
        return;
    }

    if (clampVelocity)
    {
        ClampClientExitVelocity(client);
    }

    float restoreSpeed = (g_fOriginalSpeed[client] > 0.0) ? g_fOriginalSpeed[client] : NORMAL_SPEED;
    SetClientSpeed(client, restoreSpeed);

    if (g_cvDebugMode.IntValue >= 1)
    {
        char name[64];
        GetClientName(client, name, sizeof(name));
        PrintToServer("[LadderBoost] %s restore ladder speed", name);
        PrintToChatAll("%t", "L4D2AILadderBoost_LadderAccelerationRestoreOriginalSpeed", name);
    }

    g_bSpeedBoosted[client] = false;
    g_fOriginalSpeed[client] = 0.0;
    g_fActiveMultiplier[client] = 0.0;
}

void ResetClientData(int client)
{
    if (client < 1 || client > MaxClients)
    {
        return;
    }

    g_bIsOnLadder[client] = false;
    g_bSpeedBoosted[client] = false;
    g_bWasOnLadder[client] = false;
    g_bClimbAnimBoosted[client] = false;
    g_fOriginalSpeed[client] = 0.0;
    g_fActiveMultiplier[client] = 0.0;
    g_fCooldownEndTime[client] = 0.0;
}

void InitClimbAnimMaps()
{
    if (!g_hTankClimbAnimMap)
    {
        g_hTankClimbAnimMap = new StringMap();
    }
    if (!g_hTankLowClimbAnimMap)
    {
        g_hTankLowClimbAnimMap = new StringMap();
    }

    g_hTankClimbAnimMap.SetValue("ACT_DIESIMPLE", true);
    g_hTankClimbAnimMap.SetValue("ACT_DIEBACKWARD", true);
    g_hTankClimbAnimMap.SetValue("ACT_DIEFORWARD", true);
    g_hTankClimbAnimMap.SetValue("ACT_DIEVIOLENT", true);

    g_hTankLowClimbAnimMap.SetValue("ACT_RANGE_ATTACK1", true);
    g_hTankLowClimbAnimMap.SetValue("ACT_RANGE_ATTACK2", true);
    g_hTankLowClimbAnimMap.SetValue("ACT_RANGE_ATTACK1_LOW", true);
    g_hTankLowClimbAnimMap.SetValue("ACT_RANGE_ATTACK2_LOW", true);
}

float GetClimbPlaybackRate(int client, int sequence)
{
    if (!IsValidInfected(client))
    {
        return NORMAL_SPEED;
    }

    if (IsTank(client))
    {
        ClimbSequenceType type;
        if (!GetTankClimbSequenceType(sequence, type))
        {
            return NORMAL_SPEED;
        }

        return type == ClimbSequence_Low ? g_cvTankLowClimbAnimRate.FloatValue : g_cvTankClimbAnimRate.FloatValue;
    }

    int zombieClass = GetZombieClass(client);
    if (zombieClass < ZC_SMOKER || zombieClass > ZC_CHARGER)
    {
        return NORMAL_SPEED;
    }

    if (!IsPlayerOnLadder(client) && IsGenericClimbSequence(sequence))
    {
        return g_cvSiClimbAnimRate.FloatValue;
    }

    return NORMAL_SPEED;
}

bool GetTankClimbSequenceType(int sequence, ClimbSequenceType &type)
{
    if (sequence < 0)
    {
        return false;
    }

    char seqName[64];
    if (!AnimGetActivity(sequence, seqName, sizeof(seqName)))
    {
        return false;
    }

    if (g_hTankLowClimbAnimMap && g_hTankLowClimbAnimMap.ContainsKey(seqName))
    {
        type = ClimbSequence_Low;
        return true;
    }

    if (g_hTankClimbAnimMap && g_hTankClimbAnimMap.ContainsKey(seqName))
    {
        type = ClimbSequence_High;
        return true;
    }

    return false;
}

bool IsGenericClimbSequence(int sequence)
{
    if (sequence < 0)
    {
        return false;
    }

    char seqName[64];
    if (!AnimGetActivity(sequence, seqName, sizeof(seqName)))
    {
        return false;
    }

    if (StrContains(seqName, "LADDER", false) != -1)
    {
        return false;
    }

    return StrContains(seqName, "CLIMB", false) != -1;
}

void RestorePlaybackRate(int client)
{
    if (client < 1 || client > MaxClients || !g_bClimbAnimBoosted[client])
    {
        return;
    }

    if (IsValidClient(client))
    {
        SetClientPlaybackRate(client, NORMAL_SPEED);
    }

    g_bClimbAnimBoosted[client] = false;
}

void SetClientPlaybackRate(int client, float value)
{
    if (!IsValidClient(client))
    {
        return;
    }

    float current = GetEntPropFloat(client, Prop_Send, "m_flPlaybackRate");
    if (FloatAbs(current - value) > SPEED_EPSILON)
    {
        SetEntPropFloat(client, Prop_Send, "m_flPlaybackRate", value);
    }
}

void ClampClientExitVelocity(int client)
{
    if (!g_cvClampExitSpeed.BoolValue || !IsValidClient(client))
    {
        return;
    }

    float maxSpeed = GetClientWalkSpeed(client);
    if (maxSpeed <= 0.0)
    {
        return;
    }

    float velocity[3];
    GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", velocity);
    float horizontal = SquareRoot(velocity[0] * velocity[0] + velocity[1] * velocity[1]);
    if (horizontal <= maxSpeed || horizontal <= 0.0)
    {
        return;
    }

    float scale = maxSpeed / horizontal;
    velocity[0] *= scale;
    velocity[1] *= scale;
    TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
}

float GetClientWalkSpeed(int client)
{
    if (HasEntProp(client, Prop_Send, "m_flMaxspeed"))
    {
        float speed = GetEntPropFloat(client, Prop_Send, "m_flMaxspeed");
        if (speed > 0.0)
        {
            return speed;
        }
    }

    switch (GetZombieClass(client))
    {
        case ZC_SMOKER: return 210.0;
        case ZC_BOOMER: return 175.0;
        case ZC_HUNTER: return 300.0;
        case ZC_SPITTER: return 210.0;
        case ZC_JOCKEY: return 250.0;
        case ZC_CHARGER: return 250.0;
        case ZC_TANK: return 210.0;
    }

    return 250.0;
}

bool IsClassAllowedForBoost(int client)
{
    if (IsTank(client) && !g_cvTankLadderBoost.BoolValue)
    {
        return false;
    }

    return true;
}

bool IsValidInfected(int client)
{
    return IsValidClient(client) && GetClientTeam(client) == TEAM_INFECTED && IsPlayerAlive(client);
}

bool IsValidClient(int client)
{
    return client > 0 && client <= MaxClients && IsClientInGame(client) && !IsClientInKickQueue(client);
}

bool IsPlayerOnLadder(int client)
{
    if (!IsValidClient(client) || !IsPlayerAlive(client) || !IsValidEntity(client))
    {
        return false;
    }

    if (!HasEntProp(client, Prop_Data, "m_MoveType"))
    {
        if (g_cvDebugMode.IntValue >= 2)
        {
            LogMessage("[LadderBoost] client %d missing m_MoveType", client);
        }
        return false;
    }

    return GetEntityMoveType(client) == MOVETYPE_LADDER;
}

bool IsTank(int client)
{
    if (!IsValidInfected(client))
    {
        return false;
    }

    return GetZombieClass(client) == ZC_TANK;
}

int GetZombieClass(int client)
{
    if (!IsValidClient(client) || !HasEntProp(client, Prop_Send, "m_zombieClass"))
    {
        return 0;
    }

    return GetEntProp(client, Prop_Send, "m_zombieClass");
}

bool IsInfectedGhost(int client)
{
    return HasEntProp(client, Prop_Send, "m_isGhost") && view_as<bool>(GetEntProp(client, Prop_Send, "m_isGhost"));
}

void SetClientSpeed(int client, float value)
{
    SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", value);
}

float GetClientSpeed(int client)
{
    return GetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue");
}

float MaxFloat(float a, float b)
{
    return (a > b) ? a : b;
}

bool IsInfectedVisibleToSurvivors(int infected)
{
    if (g_cvDetectionMethod.IntValue == 0)
    {
        return UseNewRaycastDetection(infected);
    }

    return UseTraditionalDetection(infected);
}

bool UseNewRaycastDetection(int infected)
{
    if (!IsValidInfected(infected))
    {
        return false;
    }

    float infectedPos[3];
    GetClientEyePosition(infected, infectedPos);

    for (int survivor = 1; survivor <= MaxClients; survivor++)
    {
        if (!IsValidClient(survivor) || GetClientTeam(survivor) != TEAM_SURVIVOR || !IsPlayerAlive(survivor))
        {
            continue;
        }

        bool hasThreats = false;
        if (HasEntProp(survivor, Prop_Send, "m_hasVisibleThreats"))
        {
            hasThreats = GetEntProp(survivor, Prop_Send, "m_hasVisibleThreats") > 0;
        }

        if (!hasThreats)
        {
            continue;
        }

        float survivorPos[3];
        GetClientEyePosition(survivor, survivorPos);
        if (GetVectorDistance(survivorPos, infectedPos) > 1500.0)
        {
            continue;
        }

        if (!IsInSurvivorFOV(survivor, infected, infectedPos, survivorPos))
        {
            continue;
        }

        Handle trace = TR_TraceRayFilterEx(survivorPos, infectedPos, MASK_VISIBLE, RayType_EndPoint, TraceFilter_IgnorePlayers);
        bool visible = !TR_DidHit(trace);
        CloseHandle(trace);

        if (visible)
        {
            return true;
        }
    }

    return false;
}

bool UseTraditionalDetection(int infected)
{
    if (!IsValidInfected(infected))
    {
        return false;
    }

    float infectedPos[3];
    GetClientEyePosition(infected, infectedPos);

    for (int survivor = 1; survivor <= MaxClients; survivor++)
    {
        if (!IsValidClient(survivor) || GetClientTeam(survivor) != TEAM_SURVIVOR || !IsPlayerAlive(survivor))
        {
            continue;
        }

        float survivorPos[3];
        GetClientEyePosition(survivor, survivorPos);
        if (GetVectorDistance(infectedPos, survivorPos) > 1500.0)
        {
            continue;
        }

        if (!IsInSurvivorFOV(survivor, infected, infectedPos, survivorPos))
        {
            continue;
        }

        Handle trace = TR_TraceRayFilterEx(survivorPos, infectedPos, MASK_VISIBLE, RayType_EndPoint, TraceFilter_IgnorePlayers);
        bool visible = !TR_DidHit(trace);
        CloseHandle(trace);

        if (visible)
        {
            return true;
        }
    }

    return false;
}

bool IsInSurvivorFOV(int survivor, int infected, const float infectedPos[3], const float survivorPos[3])
{
    if (!IsValidClient(survivor) || !IsValidClient(infected))
    {
        return false;
    }

    float survivorAngles[3];
    GetClientEyeAngles(survivor, survivorAngles);

    float toInfected[3];
    SubtractVectors(infectedPos, survivorPos, toInfected);
    NormalizeVector(toInfected, toInfected);

    float survivorForward[3];
    GetAngleVectors(survivorAngles, survivorForward, NULL_VECTOR, NULL_VECTOR);

    float dot = GetVectorDotProduct(survivorForward, toInfected);
    return dot > 0.707;
}

public bool TraceFilter_IgnorePlayers(int entity, int contentsMask, any data)
{
    return entity > MaxClients;
}

public Action Command_LadderDebug(int client, int args)
{
    PrintToConsole(client, "=== Ladder Boost Debug ===");
    PrintToConsole(client, "Sight boost: %s", g_cvEnabled.BoolValue ? "on" : "off");
    PrintToConsole(client, "Sight multiplier: %.1fx", g_cvSpeedMultiplier.FloatValue);
    PrintToConsole(client, "Legacy AI boost: %s", g_cvAiLadderBoost.BoolValue ? "on" : "off");
    PrintToConsole(client, "Legacy PZ boost: %s", g_cvPzLadderBoost.BoolValue ? "on" : "off");
    PrintToConsole(client, "Legacy multiplier: %.1fx", g_cvLegacyBoostMultiplier.FloatValue);
    PrintToConsole(client, "Tank boost: %s", g_cvTankLadderBoost.BoolValue ? "on" : "off");
    PrintToConsole(client, "Detection: %s", g_cvDetectionMethod.IntValue == 0 ? "threat+ray" : "fov+ray");
    PrintToConsole(client, "Cooldown: %.1fs", g_cvCooldownTime.FloatValue);
    PrintToConsole(client, "SDKHook: %s", g_cvUseSDKHook.BoolValue ? "on" : "off");
    PrintToConsole(client, "Debug mode: %d", g_cvDebugMode.IntValue);

    float currentTime = GetGameTime();
    PrintToConsole(client, "\n=== Player State ===");

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsValidClient(i) || !IsPlayerAlive(i))
        {
            continue;
        }

        char name[64];
        GetClientName(i, name, sizeof(name));

        if (GetClientTeam(i) == TEAM_INFECTED)
        {
            bool hasThreats = false;
            if (HasEntProp(i, Prop_Send, "m_hasVisibleThreats"))
            {
                hasThreats = GetEntProp(i, Prop_Send, "m_hasVisibleThreats") > 0;
            }

            float cooldownRemaining = g_fCooldownEndTime[i] - currentTime;
            if (cooldownRemaining < 0.0)
            {
                cooldownRemaining = 0.0;
            }

            PrintToConsole(client, "SI %s%s: ladder=%s, boosted=%s, speed=%.2f, mult=%.1f, threats=%s, cooldown=%.1fs%s",
                name,
                IsFakeClient(i) ? "[AI]" : "[PZ]",
                g_bIsOnLadder[i] ? "yes" : "no",
                g_bSpeedBoosted[i] ? "yes" : "no",
                GetClientSpeed(i),
                g_fActiveMultiplier[i],
                hasThreats ? "yes" : "no",
                cooldownRemaining,
                IsTank(i) ? ", tank" : "");
        }
        else if (GetClientTeam(i) == TEAM_SURVIVOR)
        {
            bool hasThreats = false;
            if (HasEntProp(i, Prop_Send, "m_hasVisibleThreats"))
            {
                hasThreats = GetEntProp(i, Prop_Send, "m_hasVisibleThreats") > 0;
            }

            PrintToConsole(client, "Survivor %s: threats=%s", name, hasThreats ? "yes" : "no");
        }
    }

    return Plugin_Handled;
}

public Action Command_LadderStatus(int client, int args)
{
    ReplyToCommand(client, "[梯子加速] 当前有 %d 个特感获得了爬梯加速", CountBoostedPlayers());

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsValidInfected(i) || !g_bSpeedBoosted[i])
        {
            continue;
        }

        char name[64];
        GetClientName(i, name, sizeof(name));
        ReplyToCommand(client, "  - %s (%.1fx速度)", name, g_fActiveMultiplier[i]);
    }

    int coolingDownCount = 0;
    float currentTime = GetGameTime();
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
        {
            count++;
        }
    }

    return count;
}
