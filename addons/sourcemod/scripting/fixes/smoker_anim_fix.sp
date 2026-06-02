#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>
#include <sdktools>

// ====================================================================================================
// >> DEFINES & PLUGIN INFO
// ====================================================================================================

#define GAMEDATA "l4d2_smoker_anim"

public Plugin myinfo = 
{
    name        = "Smoker Animation Fix (windowed & safe reset, end-on-grab option)",
    author      = "HoongDou, edited by ChatGPT for morzlee",
    description = "Fix AI Smoker tongue animation to match human players (with window, robust resets, and end-on-grab option)",
    version     = "1.3",
    url         = "https://github.com/HoongDou/L4D2-HoongDou-Project"
};

// ====================================================================================================
// >> Globals
// ====================================================================================================

// Handles
Handle  hConf         = null;      // Gamedata
Handle  sdkDoAnim     = null;      // SDKCall: CTerrorPlayer::DoAnimationEvent
Handle  hSequenceSet  = null;      // Detour:   CTerrorPlayer::SelectWeightedSequence

// ConVars
ConVar g_cvEnabled;                // 是否启用
ConVar g_cvHoldWindow;             // 起手强制动画的持续窗口（秒）
ConVar g_cvSafetyTimer;            // 起手兜底复位时间（秒）
ConVar g_cvEndOnGrab;              // 抓住瞬间是否立即结束覆盖窗口（更贴近原生）

// State Tracking
static bool  g_bTongueAttacking[MAXPLAYERS + 1] = {false, ...};  // 当前是否处于“吐舌动画强制期”
static float g_fTongueWindow[MAXPLAYERS + 1]    = {0.0,   ...};  // 强制期截止时间（EngineTime）
static bool  g_bDidAnimKick[MAXPLAYERS + 1]     = {false, ...};  // 是否已在起手踢过一次 DoAnimationEvent

// Animation cache: key = "<model_path>::<activity_name>" -> sequence id
StringMap g_hAnimCache = null;

// ====================================================================================================
// >> SIGNATURES
// ====================================================================================================

// SelectWeightedSequence
#define NAME_SelectWeightedSequence "CTerrorPlayer::SelectWeightedSequence"
#define SIG_SelectWeightedSequence_LINUX "@_ZN13CTerrorPlayer22SelectWeightedSequenceE8Activity"
#define SIG_SelectWeightedSequence_WINDOWS "\\x55\\x8B\\x2A\\x56\\x57\\x8B\\x2A\\x2A\\x8B\\x2A\\x81\\x2A\\x2A\\x2A\\x2A\\x2A\\x75\\x2A"

// DoAnimationEvent
#define NAME_DoAnimationEvent "CTerrorPlayer::DoAnimationEvent"
#define SIG_DoAnimationEvent_LINUX "@_ZN13CTerrorPlayer16DoAnimationEventE17PlayerAnimEvent_ti"
#define SIG_DoAnimationEvent_WINDOWS "\\x55\\x8B\\x2A\\x56\\x8B\\x2A\\x2A\\x57\\x8B\\x2A\\x83\\x2A\\x2A\\x74\\x2A\\x8B\\x2A\\x2A\\x2A\\x2A\\x2A\\x8B\\x2A"

// ====================================================================================================
// >> PLUGIN CORE
// ====================================================================================================

public void OnPluginStart()
{
    // 事件：技能/抓住/释放（核心三件套）
    HookEvent("ability_use",    Event_AbilityUse);
    HookEvent("tongue_grab",    Event_TongueGrab);
    HookEvent("tongue_release", Event_TongueRelease);

    // 事件：复位相关（尽量覆盖所有边界）
    HookEvent("player_death",       Event_PlayerDeath);
    HookEvent("player_spawn",       Event_PlayerSpawn);
    HookEvent("player_team",        Event_PlayerTeam);
    HookEvent("bot_player_replace", Event_PlayerSwap);   // 人/机互换
    HookEvent("player_bot_replace", Event_PlayerSwap);

    HookEvent("round_end",       Event_RoundEnd);
    HookEvent("map_transition",  Event_MapTransition);
    HookEvent("mission_lost",    Event_MissionLost);

    // ConVars
    g_cvEnabled     = CreateConVar("smoker_anim_fix_enabled", "1",
                                   "Enable smoker animation fix", FCVAR_NONE, true, 0.0, true, 1.0);

    g_cvHoldWindow  = CreateConVar("smoker_anim_fix_hold_window", "0.6",
                                   "Seconds we force tongue animation after ability start.", FCVAR_NONE, true, 0.0, true, 2.0);

    g_cvSafetyTimer = CreateConVar("smoker_anim_fix_safety_timer", "2.0",
                                   "Safety timer to reset tongue flag after ability start.", FCVAR_NONE, true, 0.5, true, 5.0);

    g_cvEndOnGrab   = CreateConVar("smoker_anim_fix_end_on_grab", "1",
                                   "End the hold window immediately when tongue grabs a target.", FCVAR_NONE, true, 0.0, true, 1.0);

    // Gamedata / SDK / Detour
    GetGamedata();
    PrepSDKCall();
    LoadOffset();

    // 动画缓存
    if (g_hAnimCache == null)
        g_hAnimCache = new StringMap();

    AutoExecConfig(true, "l4d2_smoker_anim_fix");
}

public void OnPluginEnd()
{
    if (hSequenceSet != null)
    {
        DHookDisableDetour(hSequenceSet, false, OnSequenceSet_Pre);
        DHookDisableDetour(hSequenceSet, true,  OnSequenceSet_Post);
    }
}

public void OnMapStart()
{
    // 地图开始清缓存和状态
    if (g_hAnimCache != null)
        g_hAnimCache.Clear();

    for (int i = 1; i <= MaxClients; i++)
        ResetSmokerFlag(i);
}

public void OnClientDisconnect(int client)
{
    ResetSmokerFlag(client);
}

public void OnClientPutInServer(int client)
{
    ResetSmokerFlag(client);
}

// ====================================================================================================
// >> EVENT HANDLERS
// ====================================================================================================

public Action Event_AbilityUse(Event event, const char[] name, bool dontBroadcast)
{
    if (!GetConVarBool(g_cvEnabled))
        return Plugin_Continue;

    int userid = event.GetInt("userid");
    int client = GetClientOfUserId(userid);

    if (!IsValidSmoker(client))
        return Plugin_Continue;

    char ability[64];
    event.GetString("ability", ability, sizeof(ability));
    int context = event.GetInt("context");

    // context==1: start
    if (StrEqual(ability, "ability_tongue") && context == 1)
    {
        g_bTongueAttacking[client] = true;
        g_fTongueWindow[client]    = GetEngineTime() + g_cvHoldWindow.FloatValue;
        g_bDidAnimKick[client]     = false;

        // 只在起手踢一次动画
        if (sdkDoAnim != null && !g_bDidAnimKick[client])
        {
            SDKCall(sdkDoAnim, client, 4, 1); // 4 = PLAYERANIMEVENT_ATTACK_PRIMARY
            g_bDidAnimKick[client] = true;
        }

        // 起手兜底（可配）
        CreateTimer(g_cvSafetyTimer.FloatValue, Timer_ResetTongueFlag, client);
    }

    return Plugin_Continue;
}

public Action Event_TongueGrab(Event event, const char[] name, bool dontBroadcast)
{
    if (!GetConVarBool(g_cvEnabled))
        return Plugin_Continue;

    int userid = event.GetInt("userid");
    int client = GetClientOfUserId(userid);
    if (!IsValidSmoker(client))
        return Plugin_Continue;

    if (GetConVarBool(g_cvEndOnGrab))
    {
        // 抓住就结束覆盖：马上允许引擎选“拉人/拖拽”等序列
        ResetSmokerFlag(client);
    }
    else
    {
        // 维持短窗口（极端条件下的兜底），防止某些边界态视觉抖动
        g_bTongueAttacking[client] = true;
        if (g_fTongueWindow[client] <= 0.0)
            g_fTongueWindow[client] = GetEngineTime() + 0.3;
    }

    return Plugin_Continue;
}

public Action Event_TongueRelease(Event event, const char[] name, bool dontBroadcast)
{
    if (!GetConVarBool(g_cvEnabled))
        return Plugin_Continue;

    int userid = event.GetInt("userid");
    int client = GetClientOfUserId(userid);

    ResetSmokerFlag(client);
    return Plugin_Continue;
}

// 复位相关事件
public Action Event_PlayerDeath(Event e, const char[] n, bool db)
{
    ResetSmokerFlag(GetClientOfUserId(e.GetInt("userid")));
    return Plugin_Continue;
}
public Action Event_PlayerSpawn(Event e, const char[] n, bool db)
{
    ResetSmokerFlag(GetClientOfUserId(e.GetInt("userid")));
    return Plugin_Continue;
}
public Action Event_PlayerTeam(Event e, const char[] n, bool db)
{
    ResetSmokerFlag(GetClientOfUserId(e.GetInt("userid")));
    return Plugin_Continue;
}
public Action Event_PlayerSwap(Event e, const char[] n, bool db)
{
    // bot_player_replace / player_bot_replace 都清一次
    ResetSmokerFlag(GetClientOfUserId(e.GetInt("userid")));
    ResetSmokerFlag(GetClientOfUserId(e.GetInt("bot")));
    return Plugin_Continue;
}
public Action Event_RoundEnd(Event e, const char[] n, bool db)
{
    for (int i = 1; i <= MaxClients; i++) ResetSmokerFlag(i);
    return Plugin_Continue;
}
public Action Event_MapTransition(Event e, const char[] n, bool db)
{
    for (int i = 1; i <= MaxClients; i++) ResetSmokerFlag(i);
    return Plugin_Continue;
}
public Action Event_MissionLost(Event e, const char[] n, bool db)
{
    for (int i = 1; i <= MaxClients; i++) ResetSmokerFlag(i);
    return Plugin_Continue;
}

// ====================================================================================================
// >> TIMERS
// ====================================================================================================

public Action Timer_ResetTongueFlag(Handle timer, int client)
{
    // 兜底：到时清理强制标志（若仍在窗口内，窗口检查也会结束）
    ResetSmokerFlag(client);
    return Plugin_Stop;
}

// ====================================================================================================
// >> DHOOK CALLBACKS
// ====================================================================================================

public MRESReturn OnSequenceSet_Pre(int client, Handle hReturn, Handle hParams)
{
    return MRES_Ignored;
}

public MRESReturn OnSequenceSet_Post(int client, Handle hReturn, Handle hParams)
{
    if (!GetConVarBool(g_cvEnabled))
        return MRES_Ignored;

    if (!IsValidSmoker(client))
        return MRES_Ignored;

    // 若未处于强制期，或强制期超时，则不覆盖
    if (!g_bTongueAttacking[client])
        return MRES_Ignored;

    float now = GetEngineTime();
    if (now > g_fTongueWindow[client])
    {
        // 超时自动清空，避免“长时间吐舌动画”
        ResetSmokerFlag(client);
        return MRES_Ignored;
    }

    int sequence = DHookGetReturn(hReturn);

    // 获取吐舌动画的序列 id（带缓存）
    int tongueSequence = GetAnimationCached(client, "ACT_TERROR_SMOKER_SENDING_OUT_TONGUE");
    if (tongueSequence > -1 && sequence != tongueSequence)
    {
        DHookSetReturn(hReturn, tongueSequence);
        return MRES_Override;
    }

    return MRES_Ignored;
}

// ====================================================================================================
// >> HELPER FUNCTIONS
// ====================================================================================================

bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

bool IsValidSmoker(int client)
{
    if (!IsValidClient(client) || !IsPlayerAlive(client))
        return false;
    if (!IsFakeClient(client))          // 只针对 AI
        return false;
    if (GetClientTeam(client) != 3)     // Infected
        return false;
    if (GetEntProp(client, Prop_Send, "m_zombieClass") != 1) // 1 = Smoker
        return false;
    return true;
}

void ResetSmokerFlag(int client)
{
    if (client <= 0 || client > MaxClients)
        return;
    g_bTongueAttacking[client] = false;
    g_bDidAnimKick[client]     = false;
    g_fTongueWindow[client]    = 0.0;
}

/**
 * 获取动画序列（带缓存）：key = "<model>::<activity>"
 */
int GetAnimationCached(int entity, const char[] activity)
{
    if (!IsValidEntity(entity))
        return -1;

    char model[PLATFORM_MAX_PATH];
    GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));

    char key[PLATFORM_MAX_PATH + 96];
    Format(key, sizeof(key), "%s::%s", model, activity);

    int seq = -1;
    if (g_hAnimCache != null && g_hAnimCache.GetValue(key, seq))
        return seq;

    // 未命中缓存：创建临时 prop_dynamic 读取序列
    int tempEnt = CreateEntityByName("prop_dynamic");
    if (tempEnt == -1 || !IsValidEntity(tempEnt))
        return -1;

    SetEntityModel(tempEnt, model);
    DispatchSpawn(tempEnt);

    SetVariantString(activity);
    AcceptEntityInput(tempEnt, "SetAnimation");
    seq = GetEntProp(tempEnt, Prop_Send, "m_nSequence");

    RemoveEntity(tempEnt);

    if (g_hAnimCache != null && seq > -1)
        g_hAnimCache.SetValue(key, seq, true);

    return seq;
}

// ====================================================================================================
// >> SETUP & INITIALIZATION
// ====================================================================================================

void PrepSDKCall()
{
    if (hConf == null)
        SetFailState("Error: Gamedata not loaded!");

    StartPrepSDKCall(SDKCall_Player);
    if (!PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, NAME_DoAnimationEvent))
        SetFailState("Can't find %s signature in gamedata", NAME_DoAnimationEvent);

    // CTerrorPlayer::DoAnimationEvent(PlayerAnimEvent_t, int)
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // PlayerAnimEvent_t
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // int
    sdkDoAnim = EndPrepSDKCall();

    if (sdkDoAnim == null)
        SetFailState("Can't initialize %s SDKCall", NAME_DoAnimationEvent);
}

void LoadOffset()
{
    if (hConf == null)
        SetFailState("Error: Gamedata not found");

    hSequenceSet = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Int, ThisPointer_CBaseEntity);
    DHookSetFromConf(hSequenceSet, hConf, SDKConf_Signature, NAME_SelectWeightedSequence);
    DHookAddParam(hSequenceSet, HookParamType_Int); // Activity
    DHookEnableDetour(hSequenceSet, false, OnSequenceSet_Pre);
    DHookEnableDetour(hSequenceSet, true,  OnSequenceSet_Post);
}

void GetGamedata()
{
    char filePath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, filePath, sizeof(filePath), "gamedata/%s.txt", GAMEDATA);

    if (FileExists(filePath))
    {
        hConf = LoadGameConfigFile(GAMEDATA);
        if (hConf == null)
            SetFailState("[SM] Failed to load gamedata file!");
        return;
    }

    PrintToServer("[SM] %s gamedata file not found. Generating...", "Smoker Animation Fix");

    Handle fileHandle = OpenFile(filePath, "a+");
    if (fileHandle == null)
        SetFailState("[SM] Couldn't generate gamedata file!");

    WriteFileLine(fileHandle, "\"Games\"");
    WriteFileLine(fileHandle, "{");
    WriteFileLine(fileHandle, "    \"left4dead2\"");
    WriteFileLine(fileHandle, "    {");
    WriteFileLine(fileHandle, "        \"Signatures\"");
    WriteFileLine(fileHandle, "        {");
    // SelectWeightedSequence
    WriteFileLine(fileHandle, "            \"%s\"", NAME_SelectWeightedSequence);
    WriteFileLine(fileHandle, "            {");
    WriteFileLine(fileHandle, "                \"library\"    \"server\"");
    WriteFileLine(fileHandle, "                \"linux\"      \"%s\"", SIG_SelectWeightedSequence_LINUX);
    WriteFileLine(fileHandle, "                \"windows\"    \"%s\"", SIG_SelectWeightedSequence_WINDOWS);
    WriteFileLine(fileHandle, "                \"mac\"        \"%s\"", SIG_SelectWeightedSequence_LINUX);
    WriteFileLine(fileHandle, "            }");
    // DoAnimationEvent
    WriteFileLine(fileHandle, "            \"%s\"", NAME_DoAnimationEvent);
    WriteFileLine(fileHandle, "            {");
    WriteFileLine(fileHandle, "                \"library\"    \"server\"");
    WriteFileLine(fileHandle, "                \"linux\"      \"%s\"", SIG_DoAnimationEvent_LINUX);
    WriteFileLine(fileHandle, "                \"windows\"    \"%s\"", SIG_DoAnimationEvent_WINDOWS);
    WriteFileLine(fileHandle, "                \"mac\"        \"%s\"", SIG_DoAnimationEvent_LINUX);
    WriteFileLine(fileHandle, "            }");
    WriteFileLine(fileHandle, "        }");
    WriteFileLine(fileHandle, "    }");
    WriteFileLine(fileHandle, "}");

    CloseHandle(fileHandle);

    hConf = LoadGameConfigFile(GAMEDATA);
    if (hConf == null)
        SetFailState("[SM] Failed to load auto-generated gamedata file!");

    PrintToServer("[SM] %s successfully generated gamedata file!", "Smoker Animation Fix");
}
