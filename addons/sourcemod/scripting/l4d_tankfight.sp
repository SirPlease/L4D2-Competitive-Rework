#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#undef REQUIRE_PLUGIN
#include <l4d_boss_vote>
#include <readyup>
#include <l4d2util>
#define REQUIRE_PLUGIN
#include <colors>
#include <witch_and_tankifier>
#include <l4d2_hybrid_scoremod>
#define PLUGIN_VERSION "1.0.0"

// 基于Target5150/MoYu_Server_Stupid_Plugins的tank发光插件Predict Tank Glow重新修改。
public Plugin myinfo = 
{
    name = "[L4D & 2] TankFight",
    author = "Forgetest, sp",
    description = "Predicts flow tank positions and fakes models with glow (mimic \"Dark Carnival: Remix\").",
    version = PLUGIN_VERSION,
    url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
};

//=========================================================================================================

#define GAMEDATA_FILE "l4d_predict_tank_glow"
#include "tankglow/tankglow_defines.inc"

bool g_bLeft4Dead2;
CZombieManager ZombieManager;

// order is foreign referred in `PickTankVariant()`
#define TANK_VARIANT_SLOT (sizeof(g_sTankModels)-1)
#define TANK_MODEL_STRLEN 128

#define IS_INFECTED(%1)         (GetClientTeam(%1) == 3)
#define IS_VALID_CLIENT(%1)     (%1 > 0 && %1 <= MaxClients)
#define IS_VALID_INFECTED(%1)   (IS_VALID_INGAME(%1) && IS_INFECTED(%1))
#define IS_VALID_INGAME(%1)     (IS_VALID_CLIENT(%1) && IsClientInGame(%1))
#define ZC_TANK    8


int g_iMapTFType = 0;

enum /*strMapType*/
{
    MP_FINALE
};

enum
{
    TYPE_NORMAL = 10,
    TYPE_FINISH = 11,
    TYPE_STATIC = 12
};
static const char g_sTankModels[][TANK_MODEL_STRLEN] = {
    "models/infected/hulk.mdl",
    "models/infected/hulk_dlc3.mdl",
    "models/infected/hulk_l4d1.mdl",
    "N/A" // TankVariant slot
};

// 是懒狗，所以
static const char g_sSurvivorModels_Plugin[][TANK_MODEL_STRLEN] = {
    "models/survivors/survivor_producer.mdl",//2代
    "models/survivors/survivor_manager.mdl",//1代
    "models/survivors/survivor_manager.mdl",//1代
    "N/A" // TankVariant slot
};

int g_iPredictModel = INVALID_ENT_REFERENCE;
int g_iPredictSurModel = INVALID_ENT_REFERENCE;
int g_iRound = 0;
float g_vModelPos[3], g_vModelAng[3];
float g_vSmodelPos[3], g_vSmodelAng[3];
ConVar g_cvTeleport;

//=========================================================================================================

// !!! remove this line if you want to include info_editor
native void InfoEditor_GetString(int pThis, const char[] keyname, char[] dest, int destLen);

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    switch (GetEngineVersion())
    {
        case Engine_Left4Dead: g_bLeft4Dead2 = false;
        case Engine_Left4Dead2: g_bLeft4Dead2 = true;
        default:
        {
            strcopy(error, err_max, "Plugin supports Left 4 Dead & 2 only.");
            return APLRes_SilentFailure;
        }
    }
    
    MarkNativeAsOptional("InfoEditor_GetString");
    return APLRes_Success;
}

public void OnPluginStart()
{
    LoadSDK();
    
    g_cvTeleport = CreateConVar("l4d_predict_glow_tp",
                                "0",
                                "Teleports tank to glow position for consistency.\n"
                            ...	"0 = Disable, 1 = Enable",
                                FCVAR_SPONLY,
                                true, 0.0, true, 1.0);
    
    HookEvent("round_start", Event_RoundStart);
    HookEvent("tank_spawn", Event_TankSpawn);
    HookEvent("round_end", RoundEnd_Event);
}

public void OnRoundIsLive()
{
    CPrintToChatAll("[{green}!{default}] {olive}Tank fight 简要说明");
    CPrintToChatAll("只有克局，克死亡后进入加时阶段。如果所有人都被扶起来回合结束！");
    CPrintToChatAll("游戏开始后，生还者会被传送到地图上发光的生还者模型");
}

public Action IsTankFightEnd(Handle timer)
{  
    if (IsTankInGame()) return Plugin_Continue;
    if (!IsCanEndRound()) return Plugin_Continue;
    // 防止影响下一队
    if (IsInReady()) return Plugin_Stop;
    EndTankFightRound();
    
    return Plugin_Stop;
}

bool IsTankInGame()
{
    for (int client = 1; client <= MaxClients; client++) {
        if (IS_VALID_INFECTED(client) && IsPlayerAlive(client) && GetEntProp(client, Prop_Send, "m_zombieClass") == ZC_TANK) {
            return true;
        }
    }
    return false;
}

bool IsCanEndRound(){
    for (int i = 1; i <= MaxClients; i++){
        if (!IsClientInGame(i)) continue;
        if (!IsPlayerAlive(i)) continue;
        if (IsSurvivor(i)){
            if (IsIncapacitated(i) || IsHangingFromLedge(i)) return false;
        }
    }
    return true;
}

bool AllSurInjured(){
    for (int i = 1; i <= MaxClients; i++){
        if (!IsClientInGame(i)) continue;
        if (!IsPlayerAlive(i)) continue;
        if (IsSurvivor(i)){
            if (!(IsIncapacitated(i) || IsHangingFromLedge(i))) return false;
        }
    }
    return true;
}
int healthbonus, damageBonus, pillsBonus;
// 传送生还者到安全屋并结束本回合
void EndTankFightRound(){
    // 如果是团灭则不做处理
    if (!AllSurInjured()) return;
    
    if (g_iMapTFType == TYPE_FINISH){
        healthbonus = SMPlus_GetHealthBonus();
        damageBonus	= SMPlus_GetDamageBonus();
        pillsBonus	= SMPlus_GetPillsBonus();
        bool bFlipped = !!GameRules_GetProp("m_bAreTeamsFlipped");
        int SurvivorTeamIndex = bFlipped ? 1 : 0;
        int survScore = L4D2Direct_GetVSCampaignScore(SurvivorTeamIndex);
        L4D2Direct_SetVSCampaignScore(SurvivorTeamIndex, survScore + healthbonus + damageBonus + pillsBonus);
        CreateTimer(3.5, AnnounceResult);
        CheatCommand("scenario_end", "");   
    }else{
        CheatCommand("sm_warpend", "");
    }
}


Action AnnounceResult(Handle timer)
{
    CPrintToChatAll("[{green}!{default}] 生还者本关得分：{olive}+%i", healthbonus + damageBonus + pillsBonus);
    return Plugin_Stop;
}

//=========================================================================================================

/**
 * @brief Called when the boss percents are updated.
 * @remarks Triggered via boss votes, force tanks, force witches.
 * @remarks Special value: -1 indicates ignored in change, 0 disabled (no spawn).
 */
public void OnUpdateBosses(int iTankFlow, int iWitchFlow)
{
    if (iTankFlow > 0)
    {
        Event_RoundStart(null, "", false);
    }
}

//=========================================================================================================

void RoundEnd_Event(Event event, const char[] name, bool dontBroadcast)
{
    //if (t_IsTankAlive != INVALID_HANDLE) KillTimer(t_IsTankAlive);
    //t_IsTankAlive = INVALID_HANDLE;
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    if (!L4D_IsVersusMode()) return;
    
    if (!GameRules_GetProp("m_bInSecondHalfOfRound", 1))
    {
        g_vModelPos = NULL_VECTOR;
        g_vModelAng = NULL_VECTOR;
        g_vSmodelAng = NULL_VECTOR;
        g_vSmodelPos = NULL_VECTOR;
    }
    
    // Need to delay a bit, seems crashing otherwise.
    CreateTimer(1.0, Timer_DelayProcess, .flags = TIMER_FLAG_NO_MAPCHANGE);
    
    // TODO: Is there a hook?
    CreateTimer(5.0, Timer_AccessTankWarp, false, TIMER_FLAG_NO_MAPCHANGE);
}

public Action L4D_OnFirstSurvivorLeftSafeArea(int x){
    if (g_iMapTFType == TYPE_STATIC) return Plugin_Continue;
    if (!IsInReady()){
        for (int i = 1; i <= MaxClients; i++){
            if (IsSurvivor(i)){
                TeleportEntity(i, g_vSmodelPos, g_vSmodelAng, NULL_VECTOR);
            }
        }
    }else{
        return Plugin_Continue;
    }

    if (IsValidEdict(g_iPredictSurModel)){
        RemoveEntity(g_iPredictSurModel);
        g_iPredictSurModel = INVALID_ENT_REFERENCE;
    }

    // 暂时禁止特感复活
    ConVar spawn = FindConVar("director_no_specials");
    spawn.IntValue = 1;
    PrintToChatAll("特感将在12S以后允许复活！");
    CreateTimer(12.0, Timer_DelaySpawn, false, TIMER_FLAG_NO_MAPCHANGE);
    return Plugin_Continue;
}	

public void OnMapStart()
{
    for (int i = 0; i < sizeof(g_sTankModels); ++i){
        PrecacheModel(g_sTankModels[i]);
        PrecacheModel(g_sSurvivorModels_Plugin[i]);
    }
    if (IsStaticTankMap()){
        g_iMapTFType = TYPE_STATIC;
    }else if (IsMissionFinalMap()){
        g_iMapTFType = TYPE_FINISH;
    }else{
        g_iMapTFType = TYPE_NORMAL;
    }
    if (g_iMapTFType == TYPE_STATIC)
    {
        CreateTimer(20.0, Timer_AnounceChangeMap);
    }
}
public void OnMapEnd()
{
    strcopy(g_sTankModels[TANK_VARIANT_SLOT], TANK_MODEL_STRLEN, "N/A");
    strcopy(g_sSurvivorModels_Plugin[TANK_VARIANT_SLOT], TANK_MODEL_STRLEN, "N/A");
    g_iRound++;
}

Action Timer_AnounceChangeMap(Handle Timer)
{
    CPrintToChatAll("[{green}!{default}] Tank Fight模式不支持当前地图，在20秒后将自动换图！");
    CreateTimer(20.0, ChangtToNewMap, _,TIMER_FLAG_NO_MAPCHANGE);
    return Plugin_Stop;
}

Action Timer_DelaySpawn(Handle timer)
{
    ConVar spawn = FindConVar("director_no_specials");
    spawn.IntValue = 0;
    return Plugin_Stop;
}

bool IsMissionFinalMap()
{
    
    char g_sMapName[48][32];
    GetCurrentMap(g_sMapName[g_iRound], 32);
    Handle g_hTrieMaps;
    // finales
    g_hTrieMaps = CreateTrie();
    SetTrieValue(g_hTrieMaps, "c1m4_atrium",					MP_FINALE);
    SetTrieValue(g_hTrieMaps, "c2m5_concert",				   MP_FINALE);
    SetTrieValue(g_hTrieMaps, "c3m4_plantation",				MP_FINALE);
    SetTrieValue(g_hTrieMaps, "c4m5_milltown_escape",		   MP_FINALE);
    SetTrieValue(g_hTrieMaps, "c5m5_bridge",					MP_FINALE);
    SetTrieValue(g_hTrieMaps, "c6m3_port",					  MP_FINALE);
    SetTrieValue(g_hTrieMaps, "c7m3_port",					  MP_FINALE);
    SetTrieValue(g_hTrieMaps, "c8m5_rooftop",				   MP_FINALE);
    SetTrieValue(g_hTrieMaps, "c9m2_lots",					  MP_FINALE);
    SetTrieValue(g_hTrieMaps, "c10m5_houseboat",				MP_FINALE);
    SetTrieValue(g_hTrieMaps, "c11m5_runway",				   MP_FINALE);
    SetTrieValue(g_hTrieMaps, "c12m5_cornfield",				MP_FINALE);
    SetTrieValue(g_hTrieMaps, "c13m4_cutthroatcreek",		   MP_FINALE);
    SetTrieValue(g_hTrieMaps, "c14m2_lighthouse",		   MP_FINALE);
    SetTrieValue(g_hTrieMaps, "c7m1_docks",		   MP_FINALE);

    // since L4D_IsMissionFinalMap() is bollocksed, simple map string check
    int mapType;
    if (!GetTrieValue(g_hTrieMaps, g_sMapName[g_iRound], mapType)) {
        return false;
    }

    return (mapType == MP_FINALE);
}

Action ChangtToNewMap(Handle Timer)
{
    char newmap[32];
    ArrayList offmaps = new ArrayList(32);
    offmaps.PushString("c1m1_hotel");
    offmaps.PushString("c2m1_highway");
    offmaps.PushString("c3m1_plankcountry");
    offmaps.PushString("c4m1_milltown_a");
    offmaps.PushString("c5m1_waterfront");
    offmaps.PushString("c6m1_riverbank");
    offmaps.PushString("c8m1_apartment");
    offmaps.PushString("c10m1_caves");
    offmaps.PushString("c11m1_greenhouse");
    offmaps.PushString("c12m1_hilltop");
    //offmaps.PushString("c13m1_alpinecreek");
    int i = GetRandomInt(0, offmaps.Length - 1);
    offmaps.GetString(i, newmap, sizeof(newmap));
    
    
    ForceChangeLevel(newmap, "No Support Fin map");
    return Plugin_Stop;
}

Action Timer_DelayProcess(Handle timer)
{
    if (!L4D_IsVersusMode()) return Plugin_Stop;
    
    if (IsValidEdict(g_iPredictModel))
    {
        RemoveEntity(g_iPredictModel);
        g_iPredictModel = INVALID_ENT_REFERENCE;
    }
    if (IsValidEdict(g_iPredictSurModel))
    {
        RemoveEntity(g_iPredictSurModel);
        g_iPredictSurModel = INVALID_ENT_REFERENCE;
    }
    
    g_iPredictModel = ProcessPredictModel(g_vModelPos, g_vModelAng);
    g_iPredictSurModel = ProcessSurPredictModel(g_vSmodelPos, g_vSmodelAng);
    if (g_iPredictModel != INVALID_ENT_REFERENCE)
        g_iPredictModel = EntIndexToEntRef(g_iPredictModel);
    if (g_iPredictSurModel != INVALID_ENT_REFERENCE)
        g_iPredictSurModel = EntIndexToEntRef(g_iPredictSurModel);
    
    FreezePoints();

    return Plugin_Stop;
}

Action Timer_AccessTankWarp(Handle timer, bool isRetry)
{
    if (!L4D_IsVersusMode()) return Plugin_Stop;
    
    if (g_bLeft4Dead2 && IsValidEdict(g_iPredictModel))
    {
        char buffer[256];
        
        L4D2_GetVScriptOutput("ret <- ( \"anv_tankwarps\" in getroottable() );<RETURN>ret</RETURN>", buffer, sizeof(buffer));
        if (strcmp(buffer, "1") != 0)
        {
            // retry or seeu
            if (!isRetry) CreateTimer(15.0, Timer_AccessTankWarp, true, TIMER_FLAG_NO_MAPCHANGE);
            return Plugin_Stop;
        }
        
        /**
         *	if ( "anv_tankwarps" in getroottable() )
         *	{
         *		::anv_tankwarps.OnGameEvent_tank_spawn(
         *		{
         *			userid = 0,
         *			tankid = %d
         *		} );
         *		::anv_tankwarps.iTankCount--;
         *	}
         */
        FormatEx(buffer, sizeof(buffer),
            "::anv_tankwarps.OnGameEvent_tank_spawn(\
            {\
                userid = 0,\
                tankid = %d\
            } );\
            ::anv_tankwarps.iTankCount--;",
            EntRefToEntIndex(g_iPredictModel)
        );
        
        /**
         *	Code for re-organized community update. Commented for afterward use.
         *
         *	---------------------------------------------
         *
         *	if ( "CommunityUpdate" in getroottable() )
         *	{
         *		CommunityUpdate().OnGameEvent_tank_spawn(
         *		{
         *			userid = 0,
         *			tankid = %d
         *		} );
         *		CommunityUpdate().m_iTankCount--;
         *	}
         */
    }
    
    return Plugin_Stop;
}

void FreezePoints()
{
    CPrintToChatAll("[{green}!{default}] Tank Fight 模式下没有路程分！");
    L4D_SetVersusMaxCompletionScore(0);
}

void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
    if (!L4D_IsVersusMode()) return;
    
    if (!IsValidEdict(g_iPredictModel))
        return;
    
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!client)
        return;
    
    if (IsFakeClient(client))
    {
        if (g_cvTeleport.BoolValue)
            TeleportEntity(client, g_vModelPos, g_vModelAng, NULL_VECTOR);
    }
    
    RemoveEntity(g_iPredictModel);
    g_iPredictModel = INVALID_ENT_REFERENCE;
    
    CreateTimer(0.3, IsTankFightEnd, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}

//=========================================================================================================

int ProcessPredictModel(float vPos[3], float vAng[3])
{
    if (GetVectorLength(vPos) == 0.0)
    {
        if (L4D2Direct_GetVSTankToSpawnThisRound(0))
        {
            for (float p = L4D2Direct_GetVSTankFlowPercent(0); p < 1.0; p += 0.01)
            {
                TerrorNavArea nav = GetBossSpawnAreaForFlow(p);
                if (nav.Valid())
                {
                    L4D_FindRandomSpot(view_as<int>(nav), vPos);
                    vPos[2] -= 8.0; // less floating off ground
                    
                    vAng[0] = 0.0;
                    vAng[1] = GetRandomFloat(0.0, 360.0);
                    vAng[2] = 0.0;
                    
                    break;
                }
            }
        }
    }
    
    if (GetVectorLength(vPos) == 0.0)
        return -1;
    
    return CreateTankGlowModel(vPos, vAng);
}

/**
 * 获取生还者模型的刷新位置
 */
int ProcessSurPredictModel(float vPos[3], float vAng[3])
{
    if (GetVectorLength(vPos) == 0.0)
    {
        if (L4D2Direct_GetVSTankToSpawnThisRound(0))
        {
            // 从 -12% 反方向获取位置
            for (float p = L4D2Direct_GetVSTankFlowPercent(0) -0.12; p > 0.0; p -= 0.01)
            {
                TerrorNavArea nav = GetBossSpawnAreaForFlow(p);
                if (nav.Valid())
                {
                    L4D_FindRandomSpot(view_as<int>(nav), vPos);
                    vPos[2] -= 8.0; // less floating off ground
                    
                    vAng[0] = 0.0;
                    vAng[1] = GetRandomFloat(0.0, 360.0);
                    vAng[2] = 0.0;
                    
                    break;
                }
            }
        }
    }
    
    if (GetVectorLength(vPos) == 0.0)
        return -1;
    
    return CreateSurvivorGlowModel(vPos, vAng);
}

TerrorNavArea GetBossSpawnAreaForFlow(float flow)
{
    float vPos[3];
    TheEscapeRoute().GetPositionOnPath(flow, vPos);
    
    TerrorNavArea nav = TerrorNavArea(vPos);
    if (!nav.Valid())
        return NULL_NAV_AREA;
    
    ArrayList aList = new ArrayList();
    while( !nav.IsValidForWanderingPopulation()
        || nav.m_isUnderwater
        || (nav.GetCenter(vPos), vPos[2] += 10.0, !ZombieManager.IsSpaceForZombieHere(vPos))
        || nav.m_activeSurvivors )
    {
        if (aList.FindValue(nav) != -1)
        {
            delete aList;
            return NULL_NAV_AREA;
        }
        
        if (nav.Valid())
            aList.Push(nav);
        
        nav = nav.GetNextEscapeStep();
    }
    
    delete aList;
    return nav;
}

//=========================================================================================================

int CreateSurvivorGlowModel(const float vPos[3], const float vAng[3])
{
    int entity = CreateEntityByName("prop_dynamic");
    if (entity == -1)
        return -1;
    
    SetEntityModel(entity, g_sSurvivorModels_Plugin[PickTankVariant()]);
    DispatchKeyValue(entity, "disableshadows", "1");
    DispatchKeyValue(entity, "DefaultAnim", "Idle_Calm_Pistol");
    DispatchSpawn(entity);
    
    SetEntProp(entity, Prop_Send, "m_CollisionGroup", 0);
    SetEntProp(entity, Prop_Send, "m_nSolidType", 0);
    L4D2_SetEntityGlow(entity, L4D2Glow_Constant, 0, 0, {77, 102, 255}, false);
    TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
    
    return entity;
}

int CreateTankGlowModel(const float vPos[3], const float vAng[3])
{
    int entity = CreateEntityByName("prop_dynamic");
    if (entity == -1)
        return -1;
    
    SetEntityModel(entity, g_sTankModels[PickTankVariant()]);
    DispatchKeyValue(entity, "disableshadows", "1");
    DispatchKeyValue(entity, "DefaultAnim", "idle");
    DispatchSpawn(entity);
    
    SetEntProp(entity, Prop_Send, "m_CollisionGroup", 0);
    SetEntProp(entity, Prop_Send, "m_nSolidType", 0);
    L4D2_SetEntityGlow(entity, L4D2Glow_Constant, 0, 0, {77, 102, 255}, false);
    TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
    
    return entity;
}

//=========================================================================================================

public void OnGetMissionInfo(int pThis)
{
    if (strcmp(g_sTankModels[TANK_VARIANT_SLOT], "N/A") == 0)
    {
        static char buffer[64];
        FormatEx(buffer, sizeof(buffer), "modes/versus/%i/TankVariant", L4D_GetCurrentChapter());
        InfoEditor_GetString(pThis, buffer, g_sTankModels[TANK_VARIANT_SLOT], TANK_MODEL_STRLEN);
    }
}

int PickTankVariant()
{
    if (strcmp(g_sTankModels[TANK_VARIANT_SLOT], "N/A") != 0)
        return TANK_VARIANT_SLOT;
    
    if (!g_bLeft4Dead2 || L4D2_GetSurvivorSetMod() == 2)
        return 0;
    
    // in case some characteristic configs enables flow tank
    char sCurrentMap[64];
    GetCurrentMap(sCurrentMap, 6);
    if (strcmp(sCurrentMap, "c7m1_docks") == 0)
        return 1;
    
    return 2;
}

void CheatCommand(const char[] sCmd, const char[] sArgs = "")
{
    for (int i = 1; i< MaxClients + 1; i++){
        if (IsClientInGame(i) && !IsFakeClient(i)){
            int admindata = GetUserFlagBits(i);
            SetUserFlagBits(i, ADMFLAG_ROOT);
            int iFlags = GetCommandFlags(sCmd);
            SetCommandFlags(sCmd, iFlags & ~FCVAR_CHEAT);
            FakeClientCommand(i, "%s %s", sCmd, sArgs);
            SetCommandFlags(sCmd, iFlags);
            SetUserFlagBits(i, admindata);
            break;
        }
    }
}