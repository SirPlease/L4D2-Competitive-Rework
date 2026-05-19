#pragma newdecls required
/**/
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colors>
#include <rpg>
#include <admin>
#undef REQUIRE_PLUGIN
#include <l4dstats>
#include <hextags>
#include <l4d_hats>
#include <godframecontrol>
#include <readyup>
#define PLUGIN_VERSION "2.0"
#define MAX_LINE_WIDTH 64
#define DB_CONF_NAME  "rpg"
#define RPG_DB_RECONNECT_DELAY 10.0
#define RPG_DB_KEEPALIVE_INTERVAL 45.0
#define RPG_DB_LOAD_RETRY_DELAY 2.0

// 进行 MySQL 连接相关变量
Handle db = INVALID_HANDLE;
Handle g_hDbReconnectTimer = null;
Handle g_hDbKeepAliveTimer = null;
int g_iDbLoadRetryCount[MAXPLAYERS + 1];
enum struct PlayerStruct{
	int ClientPoints;
	int ClientBlood;
	int ClientMelee;
	int ClientHat;
	int ClientRecoil;
	int GlowType;
	int SkinType;
	bool ClientFirstBuy;
	bool Check;
	bool CanBuy;
	CustomTags tags;
}
PlayerStruct player[MAXPLAYERS + 1];
bool valid = true, UseBuy = false;
bool IsStart=false;
bool IsAllowBigGun = false;
bool g_bEnableGlow = true;
bool  g_bAllowUseB = true;
ConVar g_hAllowUseB = null;
ConVar GaoJiRenJi, AllowBigGun, g_cShopEnable, g_hEnableGlow, g_hInfectedLimit = null;
// === Admin Anti-Kick ===
ConVar g_hAntiKickEnable;
ConVar g_hAntiKickBlockVote;
ConVar g_hAntiKickBlockCmdKick;
ConVar g_hAntiKickMinImmunity;   // 0=只要有任意管理员标识就保护；>0=要求免疫等级>=此值才保护
ConVar g_hAntiKickEqualBlock;    // 同级免疫是否禁止互踢（默认禁用互踢）
bool g_bHitSoundAvailable = false,g_bGodFrameSystemAvailable = false, g_bHatSystemAvailable = false, g_bHextagsSystemAvailable = false, g_bl4dstatsSystemAvailable = false, g_bMysqlSystemAvailable = false, g_bReadyUpSystemAvailable = false, g_bInfectedControlAvailable = false, g_bpunchangelSystemAvailable= false, g_bDamageShowHudAvailable = false;
//new lastpoints[MAXPLAYERS + 1];

//枚举变量,修改武器消耗积分在此。
enum costweapon
{
	CostAmmo			=0,
	//手枪
	CostP220		    = 50,
	CostMagnum		    = 50,
	//冲锋枪
	CostUzi 		    = 50,
	CostSilenced 	    = 50,
	CostMP5 		    = 100,
	//步枪
	CostM16 		    = 200,
	CostAK47   		    = 200,
	CostSCAR 		    = 200,
	CostSG552 		    = 200,
	//连狙
	CostHunting 	    = 200,
	CostMilitary        = 200,
	//栓狙
	CostAWP 		    = 500,
	CostScout 		    = 300,
	//连喷
	CostAuto 		    = 200,
	CostSPAS 		    = 200,
	//单喷
	CostChromeShotgun   = 50,
	CostPumpShotgun     = 50,
	//特殊武器
	CostGrenadeLuanch   = 500,
	CostM60 			= 500,
	//医疗物品
	CostFirstAidKit		= 500,
	//药品
	CostAdren 			= 300,
	CostPills 			= 400,
	//升级附件
	CostGascan			= 200,
	CostGnome			= 500,
}
enum TEAM
{
    Team_Spectator = 1,
    Team_Survivor = 2,
    Team_Infected = 3
};
ConVar ReturnBlood;
//插件开始
public Plugin myinfo =
{
	name = "商店插件",
	author = "东",
	description = "购买游戏道具,幸存者轮廓，帽子保存,生还者皮肤颜色",
	version = PLUGIN_VERSION,
	url = "http://sb.trygek.com"
}

Handle IsValid, IsUseBuy;
//Startup
// rpg.sp —— 在 AskPluginLoad2 里注册 Native（和你现有的三个一起）
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    RegPluginLibrary("rpg");
    IsValid = CreateGlobalForward("OnValidValveChange", ET_Ignore, Param_Cell);
    IsUseBuy = CreateGlobalForward("OnBuyValveChange", ET_Ignore, Param_Cell);

    CreateNative("L4D_RPG_GetValue",        Native_GetValue);
    CreateNative("L4D_RPG_GetGlobalValue",  Native_GetGlobalValue);
    CreateNative("L4D_RPG_SetGlobalValue",  Native_SetGlobalValue);
    CreateNative("L4D_RPG_SetValue",        Native_SetValue); // ★ 新增
    return APLRes_Success;
}



// rpg.sp —— 在合适位置加上实现（紧跟你已有的 Native_* 后面即可）
public any Native_SetValue(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    int option = GetNativeCell(2);
    int value  = GetNativeCell(3);

    if (client < 1 || client > MaxClients)
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
    if (!IsClientConnected(client))
        return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);

    switch (view_as<TARGET_VALUE_INDEX>(option))
    {
        case INDEX_RECOIL:
        {
            player[client].ClientRecoil = value ? 1 : 0;
            ClientSaveToFileSave(client);   // 你已有的落库函数：UPDATE RPG ... RECOIL=...
            return 1;
        }
    }
    return -1;
}

public any Native_GetValue(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int option = GetNativeCell(2);
	if (client < 1 || client > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	if (!IsClientConnected(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
	}
	//Debug_Print("GetClientTargetNum Native called");
	switch( view_as<TARGET_VALUE_INDEX>(option) )
	{
		case INDEX_POINTS:			return player[client].ClientPoints;
		case INDEX_BLOOD:			return player[client].ClientBlood;
		case INDEX_MELEE:			return player[client].ClientMelee;
		case INDEX_HAT:				return player[client].ClientHat;
		case INDEX_GLOW:			return player[client].GlowType;
		case INDEX_SKIN:			return player[client].SkinType;
		case INDEX_FIRSTBUY:		return player[client].ClientFirstBuy;
		case INDEX_RECOIL:			return player[client].ClientRecoil;
	}
	return -1;
}

public any Native_GetGlobalValue(Handle plugin, int numParams)
{
	int option = GetNativeCell(1);
	//Debug_Print("GetClientTargetNum Native called");
	switch( view_as<TARGET_VALUE_INDEX>(option) )
	{
		case INDEX_VALID:			return valid;
		case INDEX_USEBUY:			return UseBuy;
	}
	return -1;
}

public any Native_SetGlobalValue(Handle plugin, int numParams)
{
	int option = GetNativeCell(1);
	int value  = GetNativeCell(2);
	//Debug_Print("GetClientTargetNum Native called");
	switch( view_as<TARGET_VALUE_INDEX>(option) )
	{
		case INDEX_VALID:			valid  = view_as<bool>(value);
		case INDEX_USEBUY:			UseBuy = view_as<bool>(value);
	}
	return -1;
}


static int GetClientImmunityLevel(int client)
{
    AdminId adm = GetUserAdmin(client);
    if (adm == INVALID_ADMIN_ID) return 0;
    return GetAdminImmunityLevel(adm);
}

static bool HasAnyAdminFlag(int client)
{
    return (GetUserAdmin(client) != INVALID_ADMIN_ID) || (GetUserFlagBits(client) != 0);
}


// 目标是否受“防踢”保护
static bool IsAdminProtected(int target)
{
    if (!IsClientInGame(target)) return false;
    if (!HasAnyAdminFlag(target)) return false;

    int minImm = g_hAntiKickMinImmunity != null ? g_hAntiKickMinImmunity.IntValue : 0;
    if (minImm <= 0) return true;                       // 0：只要有任意管理员身份就保护
    return GetClientImmunityLevel(target) >= minImm;    // 否则：需达到阈值
}

static bool HasRootGlowAccess(int client)
{
	return GetClientImmunityLevel(client) >= 100 || CheckCommandAccess(client, "", ADMFLAG_PASSWORD);
}

static bool HasBasicGlowAccess(int client)
{
	if (!g_bl4dstatsSystemAvailable)
		return true;

	return l4dstats_IsTopPlayer(client, 20)
		|| (l4dstats_IsQuarterTopPlayer(client, 5) && l4dstats_GetClientQuarterScore(client) > 100000)
		|| CheckCommandAccess(client, "", ADMFLAG_SLAY);
}

static bool IsCustomGlowOwner(int client, int glowType)
{
	char steamid[32];
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));

	switch (glowType)
	{
		case 17:
			return StrContains(steamid, "632322128", false) != -1 || StrContains(steamid, "121430603", false) != -1;
		case 18:
			return StrContains(steamid, "511614235", false) != -1 || StrContains(steamid, "121430603", false) != -1;
		case 19:
			return StrContains(steamid, "888190443", false) != -1 || StrContains(steamid, "121430603", false) != -1;
	}

	return false;
}

static bool CanClientUseGlow(int client, int glowType)
{
	if (glowType == 0)
		return true;
	if (!IsValidClient(client) || glowType < 0 || glowType > 19)
		return false;
	if (!g_bl4dstatsSystemAvailable)
		return glowType < 17 || IsCustomGlowOwner(client, glowType);

	if (glowType >= 17)
		return HasBasicGlowAccess(client) && IsCustomGlowOwner(client, glowType);
	if (glowType < 15)
		return HasBasicGlowAccess(client);
	if (glowType == 15)
		return l4dstats_IsTopPlayer(client, 3) || HasRootGlowAccess(client);
	if (glowType == 16)
		return l4dstats_IsTopPlayer(client, 1) || HasRootGlowAccess(client);

	return false;
}

static void ClearClientGlow(int client, bool persist, bool notify = false)
{
	if (!IsValidClient(client))
		return;

	player[client].GlowType = 0;
	DisableGlow(client);

	if (persist)
		ClientSaveToFileSave(client);

	if (notify)
		CPrintToChat(client, "\x01[\x04RPG\x01] \x05你的轮廓权限已失效，已自动关闭。");
}

static bool ValidateClientGlow(int client, bool persist, bool notify = false)
{
	if (player[client].GlowType == 0 || CanClientUseGlow(client, player[client].GlowType))
		return true;

	ClearClientGlow(client, persist, notify);
	return false;
}

// 解析 callvote/ sm_kick 里的目标参数，支持 "#userid" 或 精确姓名；
// 如果精确不唯一，则返回 0（避免误判）
static int ResolveSingleTarget(const char[] arg)
{
    if (arg[0] == '#' && strlen(arg) >= 2)
    {
        int uid = StringToInt(arg[1]);
        int cl = GetClientOfUserId(uid);
        return (cl > 0 && IsClientInGame(cl)) ? cl : 0;
    }

    // 先尝试精确匹配
    for (int i=1; i<=MaxClients; i++)
    {
        if (!IsClientInGame(i)) continue;
        char name[64];
        GetClientName(i, name, sizeof(name));
        if (StrEqual(name, arg, false))
            return i;
    }

    // 再尝试“唯一”子串匹配（仅当唯一命中才返回）
    int hit = 0, cnt = 0;
    for (int i=1; i<=MaxClients; i++)
    {
        if (!IsClientInGame(i)) continue;
        char name[64];
        GetClientName(i, name, sizeof(name));
        if (StrContains(name, arg, false) != -1)
        {
            hit = i; cnt++;
            if (cnt > 1) break;
        }
    }
    return (cnt == 1) ? hit : 0;
}


public bool IsSurvivor(int client)
{
    return (IsValidClient(client) && GetClientTeam(client) == view_as<int>(Team_Survivor));
}
public bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client));
}

public void OnAllPluginsLoaded()
{
    g_bGodFrameSystemAvailable   = LibraryExists("l4d2_godframes_control_merge");
    g_bHatSystemAvailable        = LibraryExists("l4d_hats");
    g_bl4dstatsSystemAvailable   = LibraryExists("l4d_stats");
    g_bHextagsSystemAvailable    = LibraryExists("hextags");
    g_bReadyUpSystemAvailable    = LibraryExists("readyup");
	g_bpunchangelSystemAvailable = LibraryExists("punch_angle");
	g_bHitSoundAvailable = LibraryExists("l4d2_hitsound");

    // 只在 infected_control 库存在时再去找 l4d_infected_limit
    g_bInfectedControlAvailable  = LibraryExists("infected_control");
    if (g_bInfectedControlAvailable)
    {
        g_hInfectedLimit = FindConVar("l4d_infected_limit");
        if (g_hInfectedLimit != null)
        {
            g_hInfectedLimit.AddChangeHook(ConVarChanged_Cvars);
        }
    }
	g_bDamageShowHudAvailable = LibraryExists("damage_show");
}

public void OnLibraryAdded(const char[] name)
{
    if (StrEqual(name, "l4d2_godframes_control_merge")) { g_bGodFrameSystemAvailable = true; }
    else if (StrEqual(name, "l4d_hats")) { g_bHatSystemAvailable = true; }
    else if (StrEqual(name, "l4d_stats")) { g_bl4dstatsSystemAvailable = true; }
    else if (StrEqual(name, "hextags")) { g_bHextagsSystemAvailable = true; }
    else if (StrEqual(name, "readyup")) { g_bReadyUpSystemAvailable = true; }
    else if (StrEqual(name, "infected_control"))
    {
        g_bInfectedControlAvailable = true;
        g_hInfectedLimit = FindConVar("l4d_infected_limit");
        if (g_hInfectedLimit != null)
        {
            g_hInfectedLimit.AddChangeHook(ConVarChanged_Cvars);
        }
    }
	else if (StrEqual(name, "punch_angle")) { g_bpunchangelSystemAvailable = true; }
	else if (StrEqual(name, "damage_show")) { g_bDamageShowHudAvailable = true; }
	else if (StrEqual(name, "l4d2_hitsound")) { g_bHitSoundAvailable = true; }
}

public void OnLibraryRemoved(const char[] name)
{
    if (StrEqual(name, "l4d2_godframes_control_merge")) { g_bGodFrameSystemAvailable = false; }
    else if (StrEqual(name, "l4d_hats")) { g_bHatSystemAvailable = false; }
    else if (StrEqual(name, "l4d_stats")) { g_bl4dstatsSystemAvailable = false; }
    else if (StrEqual(name, "hextags")) { g_bHextagsSystemAvailable = false; }
    else if (StrEqual(name, "readyup")) { g_bReadyUpSystemAvailable = false; }
    else if (StrEqual(name, "infected_control"))
    {
        g_bInfectedControlAvailable = false;
        if (g_hInfectedLimit != null)
        {
            g_hInfectedLimit.RemoveChangeHook(ConVarChanged_Cvars);
            g_hInfectedLimit = null;
        }
    }
	else if (StrEqual(name, "punch_angle")) { g_bpunchangelSystemAvailable = false; }
	else if (StrEqual(name, "damage_show")) { g_bDamageShowHudAvailable = false; }
	else if (StrEqual(name, "l4d2_hitsound")) { g_bHitSoundAvailable = false; }
}


//god frame send forward implement
public void L4D2_GodFrameRenderChange(int client){
	if(g_bGodFrameSystemAvailable && player[client].SkinType){
		GetSkin(client, player[client].SkinType, false);
	}
}


public void L4D_OnHatLoadSave(int client, int index)
{
	//PrintToConsoleAll("index:%d load:%d",index,load);
	//LogError("index:%d load:%d",index,load);
	if(index >= 0 && IsValidClient(client) && !IsFakeClient(client)){
		player[client].ClientHat = index;
		ClientSaveToFileSave(client);
	}
}

//载入事件
public void OnMapStart()
{
	for(int i=1;i<MaxClients;i++){
		if(IsSurvivor(i))
			{
				player[i].ClientFirstBuy=true;
				player[i].CanBuy=true;
				player[i].ClientPoints=500;
			}
		else
			player[i].ClientPoints=0;
		IsStart=false;
		valid=true;
		UseBuy = false;
	}
}

public void  OnPluginStart()
{
//	LoadTranslations("menu_shop.phrases.txt");
	HookEvent("round_start", 	EventRoundStart, 				EventHookMode_Pre);
	HookEvent("player_death", 	EventReturnBlood, 				EventHookMode_Pre);
	HookEvent("player_spawn", 	Event_Player_Spawn, 			EventHookMode_Pre);
	HookEvent("mission_lost", 	EventMissionLost , 				EventHookMode_Post);
	HookEvent("player_afk", 	Event_PlayerAFK, 				EventHookMode_Pre);
	HookEvent("player_team", 	Event_PlayerDisconnectOrAFK, 	EventHookMode_Post);
	//HookEvent("player_team", 	Event_PlayerTeam, EventHookMode_Pre);
	g_cShopEnable =  CreateConVar("shop_enable", "0", "是否打开商店购买", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	AllowBigGun = CreateConVar("rpg_allow_biggun", "0", "商店是否允许购买大枪", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hEnableGlow = CreateConVar("rpg_allow_glow", "1", "商店是否打开轮廓", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	// --- Admin Anti-Kick: ConVars ---
	g_hAntiKickEnable       = CreateConVar("rpg_antikick_enable", "1", "是否启用管理员防踢（投票/命令）", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hAntiKickBlockVote    = CreateConVar("rpg_antikick_block_votekick", "1", "禁止对受保护管理员发起投票踢", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hAntiKickBlockCmdKick = CreateConVar("rpg_antikick_block_cmdkick", "1", "低级/同级管理员是否禁止用 sm_kick 踢受保护管理员", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hAntiKickMinImmunity  = CreateConVar("rpg_antikick_min_immunity", "0", "受保护阈值：管理员免疫等级>=此值即保护；0=任意管理员都保护", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	g_hAntiKickEqualBlock   = CreateConVar("rpg_antikick_equal_block", "1", "同级免疫是否禁止互踢（仅对 sm_kick 生效）", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hAllowUseB = CreateConVar(
    "rpg_allow_UseB", "1",
    "是否允许消费B数（>0 价格的商品）。1=允许；0=禁止（仅允许 0B 商品）",
    FCVAR_NOTIFY, true, 0.0, true, 1.0
	);
	g_bAllowUseB = g_hAllowUseB.BoolValue;
	g_hAllowUseB.AddChangeHook(ConVarChanged_Cvars);

	// --- Admin Anti-Kick: 监听命令 ---
	AddCommandListener(OnCallVote, "callvote");   // 阻止对管理员的投票踢
	AddCommandListener(OnSmKick,  "sm_kick");     // 限制同级/低级管理员踢更高级（或同级）
	if(FindConVar("sb_fix_enabled"))
		GaoJiRenJi=FindConVar("sb_fix_enabled");
	if (LibraryExists("infected_control"))
	{
		g_bInfectedControlAvailable = true;
		g_hInfectedLimit = FindConVar("l4d_infected_limit");
		if (g_hInfectedLimit != null)
		{
			g_hInfectedLimit.AddChangeHook(ConVarChanged_Cvars);
		}
	}
	AllowBigGun.AddChangeHook(ConVarChanged_Cvars);
	g_hEnableGlow.AddChangeHook(ConVarChanged_Cvars);
	if(GaoJiRenJi != null)
		GaoJiRenJi.AddChangeHook(ConVarChanged_Cvars);
	ReturnBlood = CreateConVar("ReturnBlood", "0", "回血模式");
	RegConsoleCmd("sm_buy", BuyMenu, "打开购买菜单(只能在游戏中)");
	RegConsoleCmd("sm_ammo", BuyAmmo, "快速买子弹");
	RegConsoleCmd("sm_pen", BuyPen, "快速随机买一把单喷");
	RegConsoleCmd("sm_chr", BuyChr, "快速买一把二代单喷");
	RegConsoleCmd("sm_pum", BuyPum, "快速买一把一代单喷");
	RegConsoleCmd("sm_smg", BuySmg, "快速买smg");
	RegConsoleCmd("sm_uzi", BuyUzi, "快速买uzi");
	RegConsoleCmd("sm_pill", BuyPill, "快速买药");
	RegConsoleCmd("sm_setch", SetCH, "设置自定义称号");
	RegConsoleCmd("sm_unsetch", UnSetCH, "设置自定义称号");
	RegConsoleCmd("sm_applytags", ApplyTags, "佩戴自定义称号");
	RegConsoleCmd("sm_rpg", BuyMenu, "打开购买菜单(只能在游戏中)");
	RegAdminCmd("sm_rpginfo", RpgInfo, ADMFLAG_ROOT ,"输出rpg人物信息");
	//RegAdminCmd("sm_skintest", Tryskin, ADMFLAG_ROOT ,"测试皮肤rgb值");
	//RegAdminCmd("sm_aruatest", Tryskin, ADMFLAG_ROOT ,"测试轮廓rgb值");
	for(int i=1;i<MaxClients;i++){
			player[i].ClientPoints=500;
			player[i].ClientFirstBuy=false;
			player[i].CanBuy=true;
	}
}

public void OnMapEnd()
{
	// flow offloading 已修复，不再需要换图时主动断连。
	// KeepAlive 使用了 TIMER_FLAG_NO_MAPCHANGE 会自动停止。
	StopDbReconnectTimer();
	StopDbKeepAliveTimer();
	// 不调用 CloseDbConnection()，连接保持跨地图复用
}

public void OnPluginEnd()
{
	StopDbReconnectTimer();
	CloseDbConnection();
}

public void OnConfigsExecuted()
{
	// Init MySQL connections
	if (!ConnectDB())
	{
		g_bMysqlSystemAvailable = false;
		//SetFailState("Connecting to database failed. Read error log for further details.");
		return;
	}else
	{
		g_bMysqlSystemAvailable = true;
	}
}

// *********************
//		获取Cvar值
// *********************
void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	// 先单独处理 rpg_allow_UseB（不依赖 infected_control）
    if (convar == g_hAllowUseB)
    {
        g_bAllowUseB = g_hAllowUseB.BoolValue;
        PrintToChatAll("\x01[\x04RPG\x01] %s",
            g_bAllowUseB ? "允许使用B数购买商品" : "已禁止使用B数购买（仅允许 0B 商品）");
        return;
    }
    if (!g_bInfectedControlAvailable || g_hInfectedLimit == null)
    {
        // 没有 infected_control，就当这局不计有效（保持你原始语义）
        valid = false;
        return;
    }

    if (IsStart)
    {
        if(valid)PrintToChatAll("\x01[\x04RANK\x01]\x04判断额外积分所需变量发生变化，此局无法获得额外积分, 过关也不奖励额外分数");
        valid = false;
        Call_StartForward(IsValid);
        Call_PushCell(false);
        Call_Finish();
    }

    IsAllowBigGun = GetConVarBool(AllowBigGun);
    g_bEnableGlow = GetConVarBool(g_hEnableGlow);
}

public void Event_PlayerDisconnectOrAFK( Event hEvent, const char[] sName, bool bDontBroadcast )
{
	int client = GetClientOfUserId( hEvent.GetInt( "userid" ));
	int team = hEvent.GetInt( "team" );
	bool disconnect = hEvent.GetBool( "disconnect" );
	if(IsValidClient(client) && (team == 3 || disconnect)){
		DisableGlow(client);
	}
	if(IsValidClient(client) && disconnect){
		player[client].ClientMelee = 0;
		player[client].ClientBlood = 0;
		player[client].ClientHat = 0;
		player[client].GlowType = 0;
		player[client].SkinType = 0;
		player[client].ClientFirstBuy = false;
		player[client].ClientRecoil = 1;
		player[client].CanBuy=true;
		player[client].ClientPoints = 500;
		player[client].Check = false;
		player[client].tags.ChatTag = NULL_STRING;
	}

}

public void Event_PlayerAFK( Event hEvent, const char[] sName, bool bDontBroadcast )
{
	DisableGlow( GetClientOfUserId( hEvent.GetInt("userid")) );
}

public void Event_Player_Spawn(Event hEvent, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId( hEvent.GetInt( "userid" ));
	if( client && IsClientInGame( client ) && !player[client].Check){
		player[client].Check = true;
		CreateTimer( 0.3, PlayerSpawnTimer, GetClientUserId( client ), TIMER_FLAG_NO_MAPCHANGE );
	}
		
}

stock bool IsPlayerGhost( int client )
{
	if( GetEntProp( client, Prop_Send, "m_isGhost", 1 ) ) 
		return true;
	
	return false;
} 

public Action PlayerSpawnTimer( Handle hTimer, any UserID )
{
	int client = GetClientOfUserId( UserID );
	if( client <= 0 || IsClientConnected( client ) != true )
		return Plugin_Handled;
	
	if( GetClientTeam( client ) == 2 && IsPlayerGhost( client ) != true )
	{
		if(player[client].GlowType && g_bEnableGlow)
		{
			if (ValidateClientGlow(client, true, true))
				GetAura(client,player[client].GlowType);
		}
		if(player[client].ClientHat)
			ServerCommand("sm_hatclient #%d %d", GetClientUserId(client), player[client].ClientHat);
		if(player[client].SkinType)
			GetSkin(client, player[client].SkinType);
	}
	else if( GetClientTeam( client ) == 3 )
	{
		DisableGlow( client );
		DisableSkin( client );
	}
	player[client].Check = false;
	return Plugin_Continue;
}

public void Event_PlayerTeam(Event hEvent, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId (hEvent.GetInt("userid"));
	int iTeam = hEvent.GetInt("team");
	if( iTeam == 2 )
	{
		if(player[client].GlowType && g_bEnableGlow)
		{
			if (ValidateClientGlow(client, true, true))
				GetAura(client,player[client].GlowType);
		}
		if(player[client].ClientHat)
			ServerCommand("sm_hatclient #%d %d", GetClientUserId(client), player[client].ClientHat);
		if(player[client].SkinType)
			GetSkin(client, player[client].SkinType);
		//PrintToConsole(client,"sm_hatclient #%d %d", GetClientUserId(client), player[client].ClientHat-1);
	}
	if( iTeam == 3 ) {
		DisableGlow( client );
		DisableSkin( client );
	}
		
}


public int GetSurvivorPermHealth(int client)
{
	return GetEntProp(client, Prop_Send, "m_iHealth", 4, 0);
}

public int SetSurvivorPermHealth(int client, int health)
{
	SetEntProp(client, Prop_Send, "m_iHealth", health, 4, 0);
	return 0;
}

public int IsPlayerIncap(int client)
{
	return GetEntProp(client, Prop_Send, "m_isIncapacitated", 4, 0);
}

public Action EventMissionLost(Handle event, const char []name, bool dontBroadcast){
	for(int i=1;i<MaxClients;i++){
		player[i].ClientPoints=500;
		player[i].ClientFirstBuy=true;
		player[i].CanBuy=true;
	}
	IsStart=false;
	valid=true;
	UseBuy = false;
	return Plugin_Continue;
}



public void EventReturnBlood(Handle event, const char []name, bool dontBroadcast){
	int victim = GetClientOfUserId(GetEventInt(event, "userid", 0));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker", 0));
	int var2 = victim;
	if(IsValidClient(victim)){
		DisableGlow( victim );
		DisableSkin( victim );
	}
	if (MaxClients >= var2 && 1 <= var2)
	{
		if (GetClientTeam(victim) == 3)
		{
			if (IsSurvivor(attacker))
			{
					if (GetConVarBool(ReturnBlood))
					{
						int maxhp = GetEntProp(attacker, Prop_Data, "m_iMaxHealth", 4, 0);
						int targetHealth = GetSurvivorPermHealth(attacker);
						if(player[attacker].ClientBlood>0)
							targetHealth += 2;
						if (targetHealth > maxhp)
						{
							targetHealth = maxhp;
						}
						if (!IsPlayerIncap(attacker))
						{
							SetSurvivorPermHealth(attacker, targetHealth);
						}
					}
			}
		}
	}
}

public bool ConnectDB()
{
	if (db != INVALID_HANDLE)
	{
		StartDbKeepAliveTimer();
		g_bMysqlSystemAvailable = true;
		return true;
	}

	if (SQL_CheckConfig(DB_CONF_NAME))
	{
		char Error[256];
		db = SQL_Connect(DB_CONF_NAME, false, Error, sizeof(Error));
		if (db == INVALID_HANDLE)
		{
			LogError("Failed to connect to database: %s", Error);
			g_bMysqlSystemAvailable = false;
			return false;
		}
		else if (!SQL_SetCharset(db,"utf8mb4"))
		{
			if (SQL_GetError(db, Error, sizeof(Error)))
				LogError("Failed to update encoding to utf8mb4: %s", Error);
			else
				LogError("Failed to update encoding to utf8mb4: unknown");
			CloseDbConnection();
			g_bMysqlSystemAvailable = false;
			return false;
		}

	}
	else
	{
		LogError("Databases.cfg missing '%s' entry!", DB_CONF_NAME);
		g_bMysqlSystemAvailable = false;
		return false;
	}

	SQL_FastQuery(db, "SET NAMES 'utf8mb4'");
	StartDbKeepAliveTimer();
	g_bMysqlSystemAvailable = true;
	return true;
}

bool IsDbConnectionLostError(const char[] error)
{
	return StrContains(error, "Lost connection", false) != -1
		|| StrContains(error, "server has gone away", false) != -1;
}

void StartDbKeepAliveTimer()
{
	if (g_hDbKeepAliveTimer != null)
		return;

	g_hDbKeepAliveTimer = CreateTimer(RPG_DB_KEEPALIVE_INTERVAL, Timer_DbKeepAlive, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

void StopDbKeepAliveTimer()
{
	if (g_hDbKeepAliveTimer == null)
		return;

	KillTimer(g_hDbKeepAliveTimer);
	g_hDbKeepAliveTimer = null;
}

void StopDbReconnectTimer()
{
	if (g_hDbReconnectTimer == null)
		return;

	KillTimer(g_hDbReconnectTimer);
	g_hDbReconnectTimer = null;
}

void CloseDbConnection()
{
	StopDbKeepAliveTimer();

	if (db != INVALID_HANDLE)
	{
		CloseHandle(db);
		db = INVALID_HANDLE;
	}
}

void ScheduleDbReconnect(const char[] error = "")
{
	if (error[0] != '\0' && !IsDbConnectionLostError(error))
		return;

	g_bMysqlSystemAvailable = false;
	CloseDbConnection();

	if (g_hDbReconnectTimer == null)
		g_hDbReconnectTimer = CreateTimer(RPG_DB_RECONNECT_DELAY, Timer_ReconnectDb, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_ReconnectDb(Handle timer, any data)
{
	g_hDbReconnectTimer = null;

	if (!ConnectDB())
	{
		ScheduleDbReconnect();
		return Plugin_Stop;
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && !IsFakeClient(i))
			ClientSaveToFileLoad(i);
	}

	return Plugin_Stop;
}

public Action Timer_DbKeepAlive(Handle timer, any data)
{
	if (db == INVALID_HANDLE)
		return Plugin_Continue;

	SQL_TQuery(db, SQL_DbKeepAliveCallback, "SELECT 1");
	return Plugin_Continue;
}

public void SQL_DbKeepAliveCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == INVALID_HANDLE || error[0] != '\0')
	{
		LogError("[RPG] database keepalive failed: %s", error);
		ScheduleDbReconnect(error);
	}
}

public void SendSQLUpdate(char []query)
{
    if (db == INVALID_HANDLE && !ConnectDB())
	{
		ScheduleDbReconnect();
        return;
	}

    SQL_TQuery(db, SQLErrorCheckCallback, query);
}
public void SQLErrorCheckCallback(Handle owner, Handle hndl, const char []error, any data)
{
    if(!StrEqual("", error))
	{
        LogError("SQL Error: %s", error);
		ScheduleDbReconnect(error);
	}
}


public void OnClientPostAdminCheck(int client)
{
	if(!IsValidClient(client) || IsFakeClient(client))
		return;
	if(IsStart)
		player[client].ClientFirstBuy = false;
	else
		player[client].ClientFirstBuy = true;
	player[client].ClientRecoil = 1;
	player[client].CanBuy=true;
	player[client].ClientPoints = 500;
	player[client].Check = false;
	g_iDbLoadRetryCount[client] = 0;
	if(g_bMysqlSystemAvailable)
	{
		player[client].ClientMelee = 0;
		player[client].ClientBlood = 0;
		player[client].ClientHat = 0;
		player[client].GlowType = 0;
		player[client].SkinType = 0;
		player[client].tags.ChatTag = NULL_STRING;
		ClientSaveToFileLoad(client);
	}
	CreateTimer(3.0, CheckPlayer, client);
	CreateTimer(10.0, SetClientTag, client);
}

public void OnClientDisconnect(int client)
{
	g_iDbLoadRetryCount[client] = 0;
}

public Action SetClientTag(Handle timer, int client)
{
    if (!IsValidClient(client) || IsFakeClient(client))
        return Plugin_Handled;

    if (player[client].tags.ChatTag[0] != '\0' && g_bHextagsSystemAvailable)
    {
        SetTags(client, player[client].tags.ChatTag);
    }
    return Plugin_Continue;
}


public Action CheckPlayer(Handle timer, int client)
{
	if(!IsValidClient(client))
		return Plugin_Handled;
	if(player[client].GlowType || player[client].ClientHat || player[client].SkinType)
		SetPlayer(client);
	return Plugin_Continue;
}

public void SetPlayer(int client)
{
	if(IsValidClient(client) && GetClientTeam( client ) == 2 )
	{
		
		if(player[client].GlowType && g_bEnableGlow)
		{
			if (ValidateClientGlow(client, true, true))
				GetAura(client,player[client].GlowType);
		}

		if(player[client].ClientHat)
		{

			if(l4dstats_IsTopPlayer(client, 100) || (CheckCommandAccess(client, "", ADMFLAG_SLAY)))
			{
				ServerCommand("sm_hatclient #%d %d", GetClientUserId(client), player[client].ClientHat);
			}else
			{
				player[client].ClientHat = 0;
				//ClientSaveToFileSave(client);
			}			
		}

		if(player[client].SkinType)
		{
			if(player[client].SkinType < 15 || player[client].SkinType >= 17)
			{
				if(l4dstats_IsTopPlayer(client, 50) || (CheckCommandAccess(client, "", ADMFLAG_SLAY)))
				{
					GetSkin(client,player[client].SkinType);
				}else
				{
					player[client].SkinType = 0;
					//ClientSaveToFileSave(client);
				}
			}			
			else if(l4dstats_IsTopPlayer(client, 5) || GetUserAdmin(client).ImmunityLevel == 100 || (CheckCommandAccess(client, "", ADMFLAG_PASSWORD)))
			{
				GetSkin(client,player[client].SkinType);
			}	
			else
			{
				player[client].SkinType = 0;
				ClientSaveToFileSave(client);
			}
		}

		if(g_bl4dstatsSystemAvailable && l4dstats_GetClientScore(client) < 500000 && !(CheckCommandAccess(client, "", ADMFLAG_SLAY)))
		{
			player[client].tags.ChatTag = NULL_STRING;
		}
			
		//PrintToConsole(client,"sm_hatclient #%d %d", GetClientUserId(client), player[client].ClientHat);
		
	}
}

public void BypassAndExecuteCommand(int client, char []strCommand, char []strParam1)
{
	int flags = GetCommandFlags(strCommand);
	SetCommandFlags(strCommand, flags & ~ FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", strCommand, strParam1);
	SetCommandFlags(strCommand, flags);
}

public Action Timer_AutoGive(Handle timer, any client)
{
	int temp = player[client].ClientMelee;
	if(temp == 14) temp = GetRandomInt(1,13);
	if (temp == 1)
	{
		BypassAndExecuteCommand(client, "give", "machete");
	}
	if (temp == 2)
	{
		BypassAndExecuteCommand(client, "give", "fireaxe");
	}
	if (temp == 3)
	{
		BypassAndExecuteCommand(client, "give", "knife");
	}
	if (temp == 4)
	{
		BypassAndExecuteCommand(client, "give", "katana");
	}
	if (temp == 5)
	{
		BypassAndExecuteCommand(client, "give", "pistol_magnum");
	}
	if (temp == 6)
	{
		BypassAndExecuteCommand(client, "give", "electric_guitar");
	}
	if (temp == 7)
	{
		BypassAndExecuteCommand(client, "give", "tonfa");
	}
	if (temp == 8)
	{
		BypassAndExecuteCommand(client, "give", "pitchfork");
	}
	if (temp == 9)
	{
		BypassAndExecuteCommand(client, "give", "shovel");
	}
	if (temp == 10)
	{
		BypassAndExecuteCommand(client, "give", "pistol");
	}
	if (temp == 11)
	{
		BypassAndExecuteCommand(client, "give", "frying_pan");
	}
	if (temp == 12)
	{
		BypassAndExecuteCommand(client, "give", "crowbar");
	}	
	if (temp == 13)
	{
		BypassAndExecuteCommand(client, "give", "cricket_bat");
	}	
	return Plugin_Continue;
}

public void ClientSaveToFileLoad(int Client)
{
	if(!IsValidClient(Client) || IsFakeClient(Client) || !g_bMysqlSystemAvailable)
		return;
	if (db == INVALID_HANDLE && !ConnectDB())
	{
		ScheduleDbReconnect();
		return;
	}
	char query[255];
	char SteamID[64];
	GetClientAuthId(Client, AuthId_Steam2,SteamID, sizeof(SteamID));
	if(StrEqual(SteamID,"BOT"))return;
	Format(query, sizeof(query), "SELECT MELEE_DATA,BLOOD_DATA,HAT,GLOW,SKIN,RECOIL,CHATTAG FROM RPG WHERE steamid = '%s'", SteamID);	
	SQL_TQuery(db, ShowMelee, query, GetClientUserId(Client));
	return;
}

public void ClientSaveToFileCreate(int Client)
{
	if(!IsValidClient(Client) || IsFakeClient(Client) || !g_bMysqlSystemAvailable)
	return;
	char query[255];
	char SteamID[64];
	GetClientAuthId(Client, AuthId_Steam2,SteamID, sizeof(SteamID));
	if(StrEqual(SteamID,"BOT"))return;
	Format(query, sizeof(query), "INSERT INTO RPG (steamid,MELEE_DATA,BLOOD_DATA,HAT,GLOW,SKIN,RECOIL)  VALUES ('%s',%d,%d,%d,%d,%d,%d)", SteamID, 0, 0, 0, 0, 0, 1);	
	SendSQLUpdate(query);
	return;
}

public void ClientTagsSaveToFileSave(int Client)
{
    if (!IsValidClient(Client) || IsFakeClient(Client) || !g_bMysqlSystemAvailable)
        return;

    char SteamID[64];
    GetClientAuthId(Client, AuthId_Steam2, SteamID, sizeof(SteamID));
    if (StrEqual(SteamID, "BOT")) return;

    // 转义 ChatTag
    char escTag[64];
    escTag[0] = '\0';
    if (player[Client].tags.ChatTag[0] != '\0' && db != INVALID_HANDLE)
    {
        SQL_EscapeString(db, player[Client].tags.ChatTag, escTag, sizeof(escTag));
    }

    if (player[Client].tags.ChatTag[0] == '\0')
        CPrintToChat(Client, "\x04你的称号取消设置");
    else
        CPrintToChat(Client, "\x04你的称号更新成功，新称号为：\x03%s", player[Client].tags.ChatTag);

    char query[255];
    Format(query, sizeof(query), "UPDATE RPG SET CHATTAG='%s' WHERE steamid = '%s'", escTag, SteamID);
    SendSQLUpdate(query);
}

public void ClientSaveToFileSave(int Client)
{
	if(!IsValidClient(Client) || IsFakeClient(Client) || !g_bMysqlSystemAvailable)
		return;
	char query[255];
	char SteamID[64];
	GetClientAuthId(Client, AuthId_Steam2,SteamID, sizeof(SteamID));
	if(StrEqual(SteamID,"BOT"))return;
	Format(query, sizeof(query), "UPDATE RPG SET MELEE_DATA=%d,BLOOD_DATA=%d,HAT=%d,GLOW=%d,SKIN=%d,RECOIL=%d WHERE steamid = '%s'",player[Client].ClientMelee,player[Client].ClientBlood, player[Client].ClientHat, player[Client].GlowType, player[Client].SkinType, player[Client].ClientRecoil, SteamID);	
	SendSQLUpdate(query);
	return;
}

//开局发近战能力武器
public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{
	if(g_bReadyUpSystemAvailable && IsInReady())
	{
		return Plugin_Continue;
	}

	if(g_cShopEnable.BoolValue){
		for(int i=1;i<MaxClients;i++){
			if(IsSurvivor(i))
			{
				CreateTimer(0.5, Timer_AutoGive, i, TIMER_FLAG_NO_MAPCHANGE);
			}
			player[i].ClientFirstBuy = false;
		}
	}
	GaoJiRenJi = FindConVar("sb_fix_enabled");
	if(GaoJiRenJi != null && GaoJiRenJi.BoolValue){
		PrintToChatAll("\x01[\x04RANK\x01]\x04由于开启了高级人机，不能获得额外积分，也不会更新地图记录");
		valid = false;
	}
	IsStart=true;
	return Plugin_Continue;
}


public Action EventRoundStart(Handle event, const char []name, bool dontBroadcast)
{
	for(int i=1;i<MaxClients;i++){
		player[i].ClientPoints=500;
		player[i].ClientFirstBuy = true;
		player[i].CanBuy = true;
	}
	IsStart = false;
	valid = true;
	UseBuy = false;
	return Plugin_Continue;
}

//检查client合法
int IsVaildClient(int client)
{
	if( client > 0 ) return 1;
	if( client < 64 ) return 1;
	if( IsClientInGame(client) ) return 1;
	if( GetClientTeam(client) == 2 ) return 1;
	else
    {
        return 0;
    }
}

//输出rpg任务信息动作
public Action RpgInfo(int client,int args)
{
	if(IsVaildClient(client) && IsPlayerAlive(client)  )
	{
		PrintToConsole(client,"melee:%d blood:%d glow:%d hat:%d skin:%d recoil:%d", player[client].ClientMelee, player[client].ClientBlood, player[client].GlowType, player[client].ClientHat, player[client].SkinType, player[client].ClientRecoil);
		PrintToConsole(client,"valid:%d uesbuy:%d", valid, UseBuy);
	}
	return Plugin_Continue;
}

//购买菜单指令动作
public Action BuyMenu(int client,int args)
{
	if(IsVaildClient(client) && IsPlayerAlive(client)  )
	{
		FakeClientCommand(client, "sm_resetscore");
		BuildMenu(client);
	}
	return Plugin_Continue;
}
//快速买子弹指令
public Action BuyAmmo(int client,int args)
{
	if(IsVaildClient(client) && IsPlayerAlive(client) && g_cShopEnable.BoolValue)
	{
    	GiveItems(client,"ammo");
    	PrintToChatAll("\x04%N \x03 补充了子弹",client);
	}
	return Plugin_Continue;
}

//快速买喷子指令
public Action BuyPen(int client,int args)
{ 
	if(IsVaildClient(client) && IsPlayerAlive(client) && g_cShopEnable.BoolValue)
	{
		if(player[client].ClientFirstBuy){
			player[client].ClientFirstBuy=false;
			bool result = false;
			if(GetRandomInt(0,1))
				result = RemovePoints(client,0,"pumpshotgun");
			else
				result = RemovePoints(client,0,"shotgun_chrome");
			if(result)
			PrintToChatAll("\x04%N \x03第一次随机白嫖一把喷子",client);
		}else if(player[client].ClientPoints>49)
		{
			bool result = false;
			if(GetRandomInt(0,1))
				result = RemovePoints(client,50,"pumpshotgun");
			else
				result = RemovePoints(client,50,"shotgun_chrome");
			if(result)
			PrintToChatAll("\x04%N \x03快速花费50B数随机购买一把单喷",client);
		}else{
			PrintToChat(client,"\x03没钱你买个屁喷子，心里没点B数");
		}
	}
	return Plugin_Continue;
}

//快速买二代单喷指令
public Action BuyChr(int client,int args)
{ 
	if(IsVaildClient(client) && IsPlayerAlive(client) && g_cShopEnable.BoolValue)
	{
		if(player[client].ClientFirstBuy){
			player[client].ClientFirstBuy=false;
			if(RemovePoints(client,0,"shotgun_chrome"))
			PrintToChatAll("\x04%N \x03第一次白嫖一把二代单喷",client);
		}else if(player[client].ClientPoints>49)
		{
			if(RemovePoints(client,50,"shotgun_chrome"))
			PrintToChatAll("\x04%N \x03快速花费50B数购买一把二代单喷",client);
		}else{
			PrintToChat(client,"\x03没钱你买个屁喷子，心里没点B数");
		}
	}
	return Plugin_Continue;
}

//快速买pump指令
public Action BuyPum(int client,int args)
{ 
	if(IsVaildClient(client) && IsPlayerAlive(client) && g_cShopEnable.BoolValue)
	{
		if(player[client].ClientFirstBuy){
			player[client].ClientFirstBuy=false;
			if(RemovePoints(client,0,"pumpshotgun"))
			PrintToChatAll("\x04%N \x03第一次白嫖一把一代单喷",client);
		}else if(player[client].ClientPoints>49)
		{
			if(RemovePoints(client,50,"pumpshotgun"))
			PrintToChatAll("\x04%N \x03快速花费50B数随机购买一把一代单喷",client);
		}else{
			PrintToChat(client,"\x03没钱你买个屁喷子，心里没点B数");
		}
	}
	return Plugin_Continue;
}

//快速买机枪指令
public Action BuySmg(int client,int args)
{ 
	if(IsVaildClient(client) && IsPlayerAlive(client) && g_cShopEnable.BoolValue)
	{ 
		if(player[client].ClientFirstBuy){
			player[client].ClientFirstBuy=false;
			if(RemovePoints(client,0,"smg_silenced"))
			PrintToChatAll("\x04%N \x03第一次白嫖一把消音smg机枪",client);
		}else if(player[client].ClientPoints>49)
		{
			if(RemovePoints(client,50,"smg_silenced"))
			PrintToChatAll("\x04%N \x03快速花费50B数购买一把消音smg机枪",client);
		}else{
			PrintToChat(client,"\x03没钱你买个屁机枪，心里没点B数");
		}
	}
	return Plugin_Continue;
}

//快速买uzi指令
public Action BuyUzi(int client,int args)
{ 
	if(IsVaildClient(client) && IsPlayerAlive(client) && g_cShopEnable.BoolValue)
	{ 
		if(player[client].ClientFirstBuy){
			player[client].ClientFirstBuy=false;
			if(RemovePoints(client,0,"smg"))
			PrintToChatAll("\x04%N \x03第一次白嫖一把Uzi",client);
		}else if(player[client].ClientPoints>49)
		{
			if(RemovePoints(client,50,"smg"))
			PrintToChatAll("\x04%N \x03快速花费50B数随机购买一把Uzi机枪",client);
		}else{
			PrintToChat(client,"\x03没钱你买个屁机枪，心里没点B数");
		}
	}
	return Plugin_Continue;
}

//快速买药指令
public Action BuyPill(int client,int args)
{ 
	if(IsVaildClient(client) && IsPlayerAlive(client) && g_cShopEnable.BoolValue)
	{
		if(RemovePoints(client,400,"pain_pills"))
		PrintToChatAll("\x04%N \x03快速花费400B数买了瓶药",client);
	}
	return Plugin_Continue;
}

//佩戴自定义称号
public Action ApplyTags(int client,int args)
{
	if(player[client].tags.ChatTag[0] != '\0')
		SetTags(client,player[client].tags.ChatTag);
	else
		CPrintToChat(client,"\x04你必须先用\x03!setch \"你想要的称号名字\" \x04设置好你的自定义称号");
	return Plugin_Continue;
}

//设置称号指令
public Action SetCH(int client,int args)
{ 
	if(!IsVaildClient(client)){return Plugin_Handled;}
	if((g_bl4dstatsSystemAvailable && l4dstats_GetClientScore(client) < 500000 && !(CheckCommandAccess(client, "", ADMFLAG_SLAY))))
	{
		ReplyToCommand(client,"你得积分小于50w，不能自定义称号");
		return Plugin_Handled;
	}
	if(args!=1){
		ReplyToCommand(client,"\x03错误参数，使用方式为!setch \"你想要的称号名字\"");
		return Plugin_Handled;
	}
	if(!IsValidClient(client) || IsFakeClient(client))
	{
		ReplyToCommand(client,"\x03错误index");
		return Plugin_Handled;
	}
	GetCmdArg(1, player[client].tags.ChatTag, 24);
	if(IsNullString(player[client].tags.ChatTag) || strlen(player[client].tags.ChatTag) == 0 || player[client].tags.ChatTag[0] == '\0')
	{
		ReplyToCommand(client,"\x03错误名字长度");
 		return Plugin_Handled;
	}
	SetTags(client,player[client].tags.ChatTag);
    /*
    char temp[32];
    Format(temp,sizeof(temp),"<%s>",player[client].tags.ChatTag);
    HexTags_SetClientTag(client, ScoreTag, temp);
    Format(temp,sizeof(temp),"{green}<%s>",player[client].tags.ChatTag);
	HexTags_SetClientTag(client, ChatTag, temp);
    HexTags_SetClientTag(client, ChatColor, "{teamcolor}");
    HexTags_SetClientTag(client, NameColor, "{lightgreen}");
    */
	ClientTagsSaveToFileSave(client);
	return Plugin_Continue;
}

//取消已设置称号指令
public Action UnSetCH(int client,int args)
{ 
	if(!IsVaildClient(client)){return Plugin_Handled;}
	if((g_bl4dstatsSystemAvailable && l4dstats_GetClientScore(client) < 500000 && !(CheckCommandAccess(client, "", ADMFLAG_SLAY))))
	{
		ReplyToCommand(client,"你得积分小于50w，不能取消自定义称号");
		return Plugin_Handled;
	}
	if(!IsValidClient(client) || IsFakeClient(client))
	{
		ReplyToCommand(client,"\x03错误index");
		return Plugin_Handled;
	}
	player[client].tags.ChatTag = NULL_STRING;
	if(g_bHextagsSystemAvailable)HexTags_ResetClientTag(client);
	//SetTags(client,player[client].tags.ChatTag);
    /*
    char temp[32];
    Format(temp,sizeof(temp),"<%s>",player[client].tags.ChatTag);
    HexTags_SetClientTag(client, ScoreTag, temp);
    Format(temp,sizeof(temp),"{green}<%s>",player[client].tags.ChatTag);
	HexTags_SetClientTag(client, ChatTag, temp);
    HexTags_SetClientTag(client, ChatColor, "{teamcolor}");
    HexTags_SetClientTag(client, NameColor, "{lightgreen}");
    */
	ClientTagsSaveToFileSave(client);
	return Plugin_Continue;
}

public void SetTags(int client, char[] tagsname)
{
    if (!g_bHextagsSystemAvailable)
    {
        CPrintToChat(client, "\x04称号模块未启用，无法设置称号");
        return;
    }
    char temp[32];
    Format(temp, sizeof(temp), "<%s>", tagsname);
    HexTags_SetClientTag(client, ScoreTag, temp);

    Format(temp, sizeof(temp), "{green}<%s>", tagsname);
    HexTags_SetClientTag(client, ChatTag, temp);
    HexTags_SetClientTag(client, ChatColor, "{teamcolor}");
    HexTags_SetClientTag(client, NameColor, "{lightgreen}");
}


public Action ResetBuy(Handle timer, int client)
{
	player[client].CanBuy = true;
	return Plugin_Continue;
}

static bool CanSpendB(int client, int costpoints)
{
    // 0B 永远允许
    if (costpoints <= 0) return true;

    // >0B 时需开关允许
    if (g_bAllowUseB) return true;

    PrintToChat(client, "\x03当前已禁止使用B数购买商品（仅允许 0B 物品）。");
    return false;
}

//分数操作
public bool RemovePoints(int client, int costpoints,char bitem[64])
{
	if(!player[client].CanBuy)
	{
		PrintToChat(client,"\x03商店技能冷却中(冷却时间15s)");
		return false;
	}
	// 新增：消费开关判定（>0B 时禁止）
    if (!CanSpendB(client, costpoints))
    {
		PrintToChat(client, "服务器关闭了B币使用通道，如需使用请投票开启");
		return false;
	}
	int actuallypoints = player[client].ClientPoints - costpoints;
	if(!UseBuy && actuallypoints < 500)
	{
		Call_StartForward(IsUseBuy);//转发触发
		Call_PushCell(false);//按顺序将参数push进forward传参列表里
		Call_Finish();//转发结束
		UseBuy = true;
	}
	if(IsVaildClient(client) && actuallypoints >= 0)
	{	
		GiveItems(client,bitem);
		player[client].ClientPoints=player[client].ClientPoints - costpoints;
		player[client].CanBuy = false;
		CreateTimer(15.0, ResetBuy, client, TIMER_FLAG_NO_MAPCHANGE);
		return true;
	}
	else
	{
		PrintToChat(client,"\x03你自己心里没有点B数吗?");
		return false;
	}

}
//数据库操作返回数据
public void ShowMelee(Handle owner, Handle hndl, const char []error, any data)
{
    int client = GetClientOfUserId(data);

    if (!client || !IsClientInGame(client) || IsFakeClient(client))
        return;

    if (hndl == INVALID_HANDLE)
    {
        LogError("[RPG] ShowMelee query failed: %s", error);
		ScheduleDbReconnect(error);

		if (IsDbConnectionLostError(error) && g_iDbLoadRetryCount[client] < 1)
		{
			g_iDbLoadRetryCount[client]++;
			CreateTimer(RPG_DB_LOAD_RETRY_DELAY, Timer_RetryClientLoad, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
        return;
    }

	g_iDbLoadRetryCount[client] = 0;

    if (SQL_FetchRow(hndl))
	{
 		player[client].ClientMelee = SQL_FetchInt(hndl, 0);
 		player[client].ClientBlood = SQL_FetchInt(hndl, 1);
 		player[client].ClientHat = SQL_FetchInt(hndl, 2);
 		player[client].GlowType = SQL_FetchInt(hndl, 3);
 		player[client].SkinType = SQL_FetchInt(hndl, 4);
		player[client].ClientRecoil = SQL_FetchInt(hndl, 5);
		FakeClientCommand(client, "sm_recoil %d", player[client].ClientRecoil);
 		SQL_FetchString(hndl, 6, player[client].tags.ChatTag, 24);
		ValidateClientGlow(client, true, true);
	}
	else
	{
		PrintToChat(client,"\x04新用户，正在创建数据库");
		ClientSaveToFileCreate(client);
	}
}

public Action Timer_RetryClientLoad(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (!client || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Stop;

	if (db == INVALID_HANDLE && !ConnectDB())
	{
		ScheduleDbReconnect();
		return Plugin_Stop;
	}

	ClientSaveToFileLoad(client);
	return Plugin_Stop;
}
//实现给予物品
public void GiveItems(int client, char bitem[64])
{
	int flags = GetCommandFlags("give");	
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "give %s", bitem);
	SetCommandFlags("give", flags|FCVAR_CHEAT);
}

//创建购买菜单>>主菜单
/*public void BuildMenu定义的是这个菜单的具体内容，包括标题，选项。
以下都是各个菜单的东西，不用修改。
*/
public void BuildMenu(int client)
{
	if( IsVaildClient(client) )
	{
		char binfo[255];
		Menu menu = new Menu(TopMenu);

		FormatEx(binfo, sizeof(binfo), "☆☆购物商店☆☆\n—————————\n当前B数：%d\n—————————",player[client].ClientPoints, client);	//玩家积分：
		menu.SetTitle(binfo);

		//FormatEx(binfo, sizeof(binfo),  "购买枪械", client);	//武器
		if(g_cShopEnable.BoolValue){
			FormatEx(binfo, sizeof(binfo), "购买枪械", client);
			menu.AddItem("gun", binfo);

			FormatEx(binfo, sizeof(binfo),  "购买补给", client); //补给
			menu.AddItem("supply", binfo);

			FormatEx(binfo, sizeof(binfo),  "出门近战技能", client); //技能菜单
			menu.AddItem("ability", binfo);
		}	
		if (GetConVarBool(ReturnBlood)){
			FormatEx(binfo, sizeof(binfo),  "回血技能", client); //技能菜单
			menu.AddItem("Blood", binfo);
		}
		if (g_bpunchangelSystemAvailable){
			FormatEx(binfo, sizeof(binfo),  "枪械抖动设置", client); //技能菜单
			menu.AddItem("Recoil", binfo);
		}
		if(g_bHextagsSystemAvailable){
			FormatEx(binfo, sizeof(binfo),  "称号菜单", client); //称号菜单
			menu.AddItem("ChatTags", binfo);
		}
		
		if(g_bHatSystemAvailable){
			FormatEx(binfo, sizeof(binfo),  "帽子菜单", client); //帽子菜单
			menu.AddItem("Hat", binfo);
		}

		if(g_bDamageShowHudAvailable){
			FormatEx(binfo, sizeof(binfo),  "伤害显示菜单", client); //伤害显示菜单
			menu.AddItem("Damage", binfo);
		}

		if(g_bHitSoundAvailable){
			FormatEx(binfo, sizeof(binfo),  "命中反馈菜单", client); //伤害显示菜单
			menu.AddItem("HitSound", binfo);
		}

		if(g_bEnableGlow && (HasBasicGlowAccess(client) || player[client].GlowType > 0))
		{
			FormatEx(binfo, sizeof(binfo),  "生还者轮廓", client); //生还者轮廓菜单
			menu.AddItem("Survivor_glow", binfo);
		}

		if((g_bl4dstatsSystemAvailable && ( l4dstats_IsTopPlayer(client,50) || (l4dstats_IsQuarterTopPlayer(client, 10) && l4dstats_GetClientQuarterScore(client) > 100000 )|| ((CheckCommandAccess(client, "", ADMFLAG_SLAY))) || player[client].SkinType > 0 )) || !g_bl4dstatsSystemAvailable)
		{
			FormatEx(binfo, sizeof(binfo),  "生还者皮肤", client); //生还者轮廓菜单
			menu.AddItem("Survivor_skin", binfo);
		}
				
		menu.Display(client, 20);

	}
}
/*public int TopMenu定义的是选择了某个选项之后的动作*/
public int TopMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char bitem[64];
			menu.GetItem(param2, bitem, sizeof(bitem));
			if( StrEqual(bitem, "gun") )
				gun(param1);
			else if( StrEqual(bitem, "supply") )
				supply(param1);
			else if( StrEqual(bitem, "ability") )
				ability(param1);
			else if( StrEqual(bitem, "Blood") )
				Blood(param1);
			else if( StrEqual(bitem, "ChatTags") )
				ChatTags(param1);
			else if( StrEqual(bitem, "Hat") )
				Hat(param1);
			else if( StrEqual(bitem, "Survivor_glow") )
				Survivor_glow(param1);
			else if( StrEqual(bitem, "Survivor_skin") )
				Survivor_skin(param1);
			else if( StrEqual(bitem, "Recoil") )
				Recoil(param1);
			else if( StrEqual(bitem, "Damage"))
				Damage(param1);
			else if( StrEqual(bitem, "HitSound"))
				HitSound(param1);
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}
//thanks "[L4D2] Glow Survivor" author King_OXO  url = "https://forums.alliedmods.net/showthread.php?t=332956"
//创建购买菜单>>主菜单--生还者轮廓菜单
public void Survivor_glow(int client)
{
	if( IsVaildClient(client) )
	{
		ValidateClientGlow(client, true, true);
		Menu menu = new Menu(VIPAuraMenuHandler);
		menu.SetTitle("生还者轮廓\n——————————");
		menu.AddItem("option0", "关闭\n ", player[client].GlowType == 0 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		if(HasBasicGlowAccess(client))
		{
			menu.AddItem("option1", "绿色", player[client].GlowType == 1 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			menu.AddItem("option2", "蓝色", player[client].GlowType == 2 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			menu.AddItem("option3", "藍紫色", player[client].GlowType == 3 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			menu.AddItem("option4", "青色", player[client].GlowType == 4 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			menu.AddItem("option5", "橘黄色", player[client].GlowType == 5 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			menu.AddItem("option6", "红色", player[client].GlowType == 6 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			menu.AddItem("option7", "灰色", player[client].GlowType == 7 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			menu.AddItem("option8", "黄色", player[client].GlowType == 8 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			menu.AddItem("option9", "酸橙色", player[client].GlowType == 9 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			menu.AddItem("option10", "栗色", player[client].GlowType == 10 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			menu.AddItem("option11", "藍綠色", player[client].GlowType == 11 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			menu.AddItem("option12", "粉红色", player[client].GlowType == 12 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			menu.AddItem("option13", "紫色", player[client].GlowType == 13 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			menu.AddItem("option14", "白色", player[client].GlowType == 14 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			DumpAdminCache(AdminCache_Admins,true);
			DumpAdminCache(AdminCache_Groups,true);
			if(CanClientUseGlow(client, 15))
				menu.AddItem("option15", "金黄色", player[client].GlowType == 15 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			if(CanClientUseGlow(client, 16))
				menu.AddItem("option16", "彩虹色", player[client].GlowType == 16 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			//个人定制轮廓部分
			if(CanClientUseGlow(client, 17)){
				//760308896 定制
				menu.AddItem("option17", "定制轮廓1", player[client].GlowType == 17 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			}
			if(CanClientUseGlow(client, 18)){
				//8894224 定制
				menu.AddItem("option18", "定制轮廓2", player[client].GlowType == 18 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			}
			if(CanClientUseGlow(client, 19)){
				//1850229089 定制
				menu.AddItem("option19", "定制轮廓3", player[client].GlowType == 19 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			}
		}	
		menu.ExitButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
}

public int VIPAuraMenuHandler(Menu menu, MenuAction action, int param1, int param2) 
{
    switch (action) 
    {
        case MenuAction_End:
            delete menu;
        case MenuAction_Select: 
        {
            char option[64];
            menu.GetItem(param2, option, sizeof(option));
            //PrintToConsoleAll("%s", option);
	            char result[2][6];
	            ExplodeString(option, "option", result, 2, 6);
	            //PrintToConsoleAll("%s", result[1]);
	            int glowType = StringToInt(result[1], 10);
	            if (glowType != 0 && !CanClientUseGlow(param1, glowType))
	            {
	                ClearClientGlow(param1, true, true);
	                return 0;
	            }
	            GetAura(param1, glowType);
	            ClientSaveToFileSave(param1);
            //SetCookie(param1, cookie, param2);
			
            Survivor_glow( param1 );
        }
    }

    return 0;
}

void GetAura(int client, int id) 
{
	if (id != 0 && !CanClientUseGlow(client, id))
	{
		ClearClientGlow(client, true, true);
		return;
	}

    switch (id) 
    {
        case 0: 
        {    
            DisableGlow( client );
            player[client].GlowType = id;
//          PrintToChat(client, "\x05你 have turned off the Glow");
            return;
        }
        case 1: 
        {
            SetEntProp(client, Prop_Send, "m_glowColorOverride", 0 + (255 * 256) + (0 * 65536));
            CPrintToChat(client, "\x05你 \x04将轮廓颜色改为\x01: \x04绿色 \x01!");
        }
        case 2: 
        {
            SetEntProp(client, Prop_Send, "m_glowColorOverride", 7 + (19 * 256) + (250 * 65536));
            CPrintToChat(client, "\x05你 \x04将轮廓颜色改为\x01: \x04蓝色 \x01!");
        }
        case 3: 
        {
            SetEntProp(client, Prop_Send, "m_glowColorOverride", 249 + (19 * 256) + (250 * 65536));
            CPrintToChat(client, "\x05你 \x04将轮廓颜色改为\x01: \x04蓝紫色 \x01!");
        }
        case 4: 
        {
            SetEntProp(client, Prop_Send, "m_glowColorOverride", 66 + (250 * 256) + (250 * 65536));
            CPrintToChat(client, "\x05你 \x04将轮廓颜色改为\x01: \x04青色 \x01!");
        }
        case 5: 
        {
            SetEntProp(client, Prop_Send, "m_glowColorOverride", 249 + (155 * 256) + (84 * 65536));
            CPrintToChat(client, "\x05你 \x04将轮廓颜色改为\x01: \x04橘黄色 \x01!");
        }
        case 6: 
        {
            SetEntProp(client, Prop_Send, "m_glowColorOverride", 255 + (0 * 256) + (0 * 65536));
            CPrintToChat(client, "\x05你 \x04将轮廓颜色改为\x01: \x04红色 \x01!");
        }
        case 7: 
        {
            SetEntProp(client, Prop_Send, "m_glowColorOverride", 50 + (50 * 256) + (50 * 65536));
            CPrintToChat(client, "\x05你 \x04将轮廓颜色改为\x01: \x04灰色 \x01!");
        }
        case 8: 
        {
            SetEntProp(client, Prop_Send, "m_glowColorOverride", 255 + (255 * 256) + (0 * 65536));
            CPrintToChat(client, "\x05你 \x04将轮廓颜色改为\x01: \x04黄色 \x01!");
        }
        case 9: 
        {
            SetEntProp(client, Prop_Send, "m_glowColorOverride", 128 + (255 * 256) + (0 * 65536));
            CPrintToChat(client, "\x05你 \x04将轮廓颜色改为\x01: \x04酸橙色 \x01!");
        }
        case 10: 
        {
            SetEntProp(client, Prop_Send, "m_glowColorOverride", 128 + (0 * 256) + (0 * 65536));
            CPrintToChat(client, "\x05你 \x04将轮廓颜色改为\x01: \x04栗色 \x01!");
        }
        case 11: 
        {
            SetEntProp(client, Prop_Send, "m_glowColorOverride", 0 + (128 * 256) + (128 * 65536));
            CPrintToChat(client, "\x05你 \x04将轮廓颜色改为\x01: \x04藍綠色 \x01!");
        }
        case 12:
        {
            SetEntProp(client, Prop_Send, "m_glowColorOverride", 255 + (0 * 256) + (150 * 65536));
            CPrintToChat(client, "\x05你 \x04将轮廓颜色改为\x01: \x04粉红色 \x01!");
        }
        case 13:
        {        
            SetEntProp(client, Prop_Send, "m_glowColorOverride", 155 + (0 * 256) + (255 * 65536));
            CPrintToChat(client, "\x05你 \x04将轮廓颜色改为\x01: \x04紫色 \x01!");
        }
        case 14: 
        {
            SetEntProp(client, Prop_Send, "m_glowColorOverride", -1 + (-1 * 256) + (-1 * 65536));
            CPrintToChat(client, "\x05你 \x04将轮廓颜色改为\x01: \x04白色 \x01!");
        }
        case 15: 
        {
            SetEntProp(client, Prop_Send, "m_glowColorOverride", 255 + (155 * 256) + (0 * 65536));
            CPrintToChat(client, "\x05你 \x04将轮廓颜色改为\x01: \x04金黄色 \x01!");
        }
        case 16: 
        {
            SDKHook(client, SDKHook_PreThink, RainbowPlayer);
            CPrintToChat(client, "\x05你 \x04将轮廓颜色改为\x01: \x04彩虹色 \x01!");
        }
		case 17:
		{
            SetEntProp(client, Prop_Send, "m_glowColorOverride", 255 + (69 * 256) + (0 * 65536));
            CPrintToChat(client, "\x05你 \x04将轮廓颜色改为您的\x01: \x04定制颜色轮廓 \x01!");
		}
		case 18:
		{
            SetEntProp(client, Prop_Send, "m_glowColorOverride", 255 + (110 * 256) + (156 * 65536));
            CPrintToChat(client, "\x05你 \x04将轮廓颜色改为您的\x01: \x04定制颜色轮廓 \x01!");
		}
		case 19:
		{
            SetEntProp(client, Prop_Send, "m_glowColorOverride", 255 + (115 * 256) + (215 * 65536));
            CPrintToChat(client, "\x05你 \x04将轮廓颜色改为您的\x01: \x04定制颜色轮廓 \x01!");
		}
    }

	if ((id >= 0 && id <= 15) || id >= 17)    {
        SetEntProp(client, Prop_Send, "m_iGlowType", 3);
        SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
        SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
		
        SDKUnhook(client, SDKHook_PreThink, RainbowPlayer);
    }
    
    player[client].GlowType = id;
    
}

void DisableGlow( int client )
{
	if( IsValidClient( client ))
	{		
		SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
		SetEntProp(client, Prop_Send, "m_iGlowType", 0);
		SDKUnhook(client, SDKHook_PreThink, RainbowPlayer);
	}
}

public Action RainbowPlayer(int client)
{
	if( IsValidClient( client ) != true || IsPlayerAlive(client) != true || GetClientTeam( client ) == 3 )
	{
		SDKUnhook(client, SDKHook_PreThink, RainbowPlayer);
		
		if( GetClientTeam( client ) == 3 )
		{
			SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
			SetEntProp(client, Prop_Send, "m_iGlowType", 0);
		}
		
		return Plugin_Handled;
	}
    
	SetEntProp(client, Prop_Send, "m_glowColorOverride", RoundToNearest(Cosine((GetGameTime() * 8.0) + client + 1) * 127.5 + 127.5) + (RoundToNearest(Cosine((GetGameTime() * 8.0) + client + 3) * 127.5 + 127.5) * 256) + (RoundToNearest(Cosine((GetGameTime() * 8.0) + client + 5) * 127.5 + 127.5) * 65536));
	SetEntProp(client, Prop_Send, "m_iGlowType", 3);
	SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
	SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
	return Plugin_Continue;
}

//创建购买菜单>>主菜单--生还者皮肤菜单
public void Survivor_skin(int client)
{
	if( IsVaildClient(client) )
	{
		Menu menu = new Menu(VIPSkinMenuHandler);
		menu.SetTitle("生还者皮肤颜色\n——————————");

		menu.AddItem("option0", "关闭\n ", player[client].SkinType == 0 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		if((g_bl4dstatsSystemAvailable && (l4dstats_IsTopPlayer(client, 50) || (CheckCommandAccess(client, "", ADMFLAG_SLAY)))) || !g_bl4dstatsSystemAvailable)
		{
			menu.AddItem("option1", "绿色", player[client].SkinType == 1 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			menu.AddItem("option2", "蓝色", player[client].SkinType == 2 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			menu.AddItem("option3", "藍紫色", player[client].SkinType == 3 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			menu.AddItem("option4", "青色", player[client].SkinType == 4 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			menu.AddItem("option5", "橘黄色", player[client].SkinType == 5 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			menu.AddItem("option6", "红色", player[client].SkinType == 6 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			menu.AddItem("option7", "灰色", player[client].SkinType == 7 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			menu.AddItem("option8", "黄色", player[client].SkinType == 8 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			menu.AddItem("option9", "酸橙色", player[client].SkinType == 9 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			menu.AddItem("option10", "栗色", player[client].SkinType == 10 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			menu.AddItem("option11", "藍綠色", player[client].SkinType == 11 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			menu.AddItem("option12", "粉红色", player[client].SkinType == 12 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			menu.AddItem("option13", "紫色", player[client].SkinType == 13 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			DumpAdminCache(AdminCache_Admins,true);
			DumpAdminCache(AdminCache_Groups,true);
			if((g_bl4dstatsSystemAvailable && l4dstats_IsTopPlayer(client,20)) || GetUserAdmin(client).ImmunityLevel == 100 || !g_bl4dstatsSystemAvailable)
				menu.AddItem("option14", "黑色", player[client].SkinType == 14 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			if((g_bl4dstatsSystemAvailable && (l4dstats_IsTopPlayer(client,5) || GetUserAdmin(client).ImmunityLevel == 100)) || !g_bl4dstatsSystemAvailable)
				menu.AddItem("option15", "金黄色", player[client].SkinType == 15 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			if((g_bl4dstatsSystemAvailable && (l4dstats_IsTopPlayer(client,3)) || GetUserAdmin(client).ImmunityLevel == 100) || !g_bl4dstatsSystemAvailable)
				menu.AddItem("option16", "透明色", player[client].SkinType == 16 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			//个人定制皮肤部分
			char steamid[32];
			GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
			if(StrContains(steamid, "632322128", false) != -1 || StrContains(steamid, "121430603", false) != -1 ){
				//760308896 定制
				menu.AddItem("option17", "定制皮肤1", player[client].SkinType == 17 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			}
			if(StrContains(steamid, "888190443", false) != -1|| StrContains(steamid, "121430603", false) != -1 ){
				//8894224 定制
				menu.AddItem("option18", "定制皮肤2", player[client].SkinType == 18 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			}
			if(StrContains(steamid, "697994844", false) != -1|| StrContains(steamid, "121430603", false) != -1 ){
				//2530533727 定制
				menu.AddItem("option19", "定制皮肤3", player[client].SkinType == 19 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			}
			if(StrContains(steamid, "511614235", false) != -1|| StrContains(steamid, "121430603", false) != -1 ){
				//2530533727 定制
				menu.AddItem("option20", "定制皮肤4", player[client].SkinType == 20 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			}
		}
		menu.ExitButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
}

public int VIPSkinMenuHandler(Menu menu, MenuAction action, int param1, int param2) 
{
    switch (action) 
    {
        case MenuAction_End:
            delete menu;
        case MenuAction_Select: 
        {
            char option[64];
            menu.GetItem(param2, option, sizeof(option));
            //PrintToConsoleAll("%s", option);
            char result[2][6];
            ExplodeString(option, "option", result, 2, 6);
            //PrintToConsoleAll("%s", result[1]);
            GetSkin(param1, StringToInt(result[1], 10));
            ClientSaveToFileSave(param1);
            //SetCookie(param1, cookie, param2);
			
            Survivor_skin( param1 );
        }
    }

    return 0;
}

void GetSkin(int client, int id, bool broadcast = true) 
{
    switch (id) 
    {
        case 0: 
        {    
            DisableSkin( client );
            player[client].SkinType = id;
            if(broadcast)
            	PrintToChat(client, "\x05你关闭了生还者轮廓");
            return;
        }
        case 1: 
        {
            SetEntityRenderMode(client, RENDER_GLOW);
            SetEntityRenderColor(client, 0, 255, 0, 255);
            if(broadcast)
            	CPrintToChat(client, "\x05你 \x04将皮肤颜色改为\x01: \x04绿色 \x01!");
        }
        case 2: 
        {
            SetEntityRenderMode(client, RENDER_GLOW);
            SetEntityRenderColor(client, 7, 19, 250, 255);
            if(broadcast)
            	CPrintToChat(client, "\x05你 \x04将皮肤颜色改为\x01: \x04蓝色 \x01!");
        }
        case 3: 
        {
            SetEntityRenderMode(client, RENDER_GLOW);
            SetEntityRenderColor(client, 249, 19, 250, 255);
            if(broadcast)
            	CPrintToChat(client, "\x05你 \x04将皮肤颜色改为\x01: \x04蓝紫色 \x01!");
        }
        case 4: 
        {
            SetEntityRenderMode(client, RENDER_GLOW);
            SetEntityRenderColor(client, 66, 250, 250, 255);
            if(broadcast)
            	CPrintToChat(client, "\x05你 \x04将皮肤颜色改为\x01: \x04青色 \x01!");
        }
        case 5: 
        {
            SetEntityRenderMode(client, RENDER_GLOW);
            SetEntityRenderColor(client, 249, 155, 84, 255);
            if(broadcast)
            	CPrintToChat(client, "\x05你 \x04将皮肤颜色改为\x01: \x04橘黄色 \x01!");
        }
        case 6: 
        {
            SetEntityRenderMode(client, RENDER_GLOW);
            SetEntityRenderColor(client, 255, 0, 0, 255);
            if(broadcast)
            	CPrintToChat(client, "\x05你 \x04将皮肤颜色改为\x01: \x04红色 \x01!");
        }
        case 7: 
        {
            SetEntityRenderMode(client, RENDER_GLOW);
            SetEntityRenderColor(client, 50, 50, 50, 255);
            if(broadcast)
            	CPrintToChat(client, "\x05你 \x04将皮肤颜色改为\x01: \x04灰色 \x01!");
        }
        case 8: 
        {
            SetEntityRenderMode(client, RENDER_GLOW);
            SetEntityRenderColor(client, 255, 255, 0, 255);
            if(broadcast)
            	CPrintToChat(client, "\x05你 \x04将皮肤颜色改为\x01: \x04黄色 \x01!");
        }
        case 9: 
        {
            SetEntityRenderMode(client, RENDER_GLOW);
            SetEntityRenderColor(client, 128, 255, 0, 255);
            if(broadcast)
            	CPrintToChat(client, "\x05你 \x04将皮肤颜色改为\x01: \x04酸橙色 \x01!");
        }
        case 10: 
        {
            SetEntityRenderMode(client, RENDER_GLOW);
            SetEntityRenderColor(client, 128, 0, 0, 255);
            if(broadcast)
            	CPrintToChat(client, "\x05你 \x04将皮肤颜色改为\x01: \x04栗色 \x01!");
        }
        case 11: 
        {
            SetEntityRenderMode(client, RENDER_GLOW);
            SetEntityRenderColor(client, 0, 128, 128, 255);
            if(broadcast)
            	CPrintToChat(client, "\x05你 \x04将皮肤颜色改为\x01: \x04藍綠色 \x01!");
        }
        case 12:
        {
            SetEntityRenderMode(client, RENDER_GLOW);
            SetEntityRenderColor(client, 255, 0, 150, 255);
            if(broadcast)
            	CPrintToChat(client, "\x05你 \x04将皮肤颜色改为\x01: \x04粉红色 \x01!");
        }
        case 13:
        {        
            SetEntityRenderMode(client, RENDER_GLOW);
            SetEntityRenderColor(client, 155, 0, 255, 255);
            if(broadcast)
            	CPrintToChat(client, "\x05你 \x04将皮肤颜色改为\x01: \x04紫色 \x01!");
        }
        case 14: 
        {
            SetEntityRenderMode(client, RENDER_GLOW);
            SetEntityRenderColor(client, 0, 0, 0, 255);
            if(broadcast)
            	CPrintToChat(client, "\x05你 \x04将皮肤颜色改为\x01: \x04黑色 \x01!");
        }
        case 15: 
        {
            SetEntityRenderMode(client, RENDER_GLOW);
            SetEntityRenderColor(client, 255, 155, 0, 255);
            if(broadcast)
            	CPrintToChat(client, "\x05你 \x04将皮肤颜色改为\x01: \x04金黄色 \x01!");
        }
        case 16: 
        {
            SetEntityRenderMode(client, RENDER_GLOW);
            SetEntityRenderColor(client, 0, 0, 0, 30);
            if(broadcast)
            	CPrintToChat(client, "\x05你 \x04将皮肤颜色改为\x01: \x04透明色 \x01!");
        }
		case 17:
		{
            SetEntityRenderMode(client, RENDER_GLOW);
            SetEntityRenderColor(client, 139, 101, 8, 255);
            if(broadcast)
            	CPrintToChat(client, "\x05你 \x04将皮肤颜色改为\x01: \x04您的定制皮肤 \x01!");
		}
		case 18:
		{
            SetEntityRenderMode(client, RENDER_GLOW);
            SetEntityRenderColor(client, 0, 0, 0, 60);
            if(broadcast)
            	CPrintToChat(client, "\x05你 \x04将皮肤颜色改为\x01: \x04您的定制皮肤 \x01!");
		}
		case 19: 
        {
            SetEntityRenderMode(client, RENDER_GLOW);
            SetEntityRenderColor(client, 0, 0, 0, 60);
            if(broadcast)
            	CPrintToChat(client, "\x05你 \x04将皮肤颜色改为\x01: \x04您的定制皮肤 \x01!");
        }
		case 20: 
        {
            SetEntityRenderMode(client, RENDER_GLOW);
            SetEntityRenderColor(client, 0, 0, 0, 60);
            if(broadcast)
            	CPrintToChat(client, "\x05你 \x04将皮肤颜色改为\x01: \x04您的定制皮肤 \x01!");
        }
    }
    
    player[client].SkinType = id;
    
}

void DisableSkin( int client )
{
	if( IsValidClient( client ))
	{		
		SetEntityRenderMode(client, RENDER_NORMAL);
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
}

//创建购买菜单>>主菜单--称号菜单
public void ChatTags(int client)
{
	//ClientCommand(client,"Cmd_ReloadTags");
	//ApplyTags(client,0);
	ClientCommand(client,"sm_ch");	
}

//创建购买菜单>>主菜单--帽子菜单
public void Hat(int client)
{
	ClientCommand(client,"sm_hats");	
}

//创建购买菜单>>主菜单--伤害显示菜单
public void Damage(int client)
{
	ClientCommand(client,"sm_dmgmenu");	
}

//创建购买菜单>>主菜单--伤害显示菜单
public void HitSound(int client)
{
	ClientCommand(client,"sm_snd");	
}

//创建购买菜单>>主菜单--主武器类型
public void gun(int client)
{
	if( IsVaildClient(client) )
	{
		char binfo[64];
		Menu menu = new Menu(gun_back);
		menu.SetTitle("当前B数：%i \n——————————",player[client].ClientPoints);
		
		FormatEx(binfo, sizeof(binfo),  "子弹 %dB数",CostAmmo, client);
		menu.AddItem("ammo", binfo);
		
		if(player[client].ClientFirstBuy){
			FormatEx(binfo, sizeof(binfo), "马格南 %dB数",0, client);
			menu.AddItem("pistol_magnum", binfo);
			FormatEx(binfo, sizeof(binfo), "Uzi %dB数",0, client);
			menu.AddItem("smg", binfo);

			FormatEx(binfo, sizeof(binfo), "消音smg %dB数",0,client);
			menu.AddItem("smg_silenced", binfo);
		
			FormatEx(binfo, sizeof(binfo), "一代单发霰弹枪 %dB数",0, client);
			menu.AddItem("pumpshotgun", binfo);

			FormatEx(binfo, sizeof(binfo), "二代单发霰弹枪 %dB数",0, client);
			menu.AddItem("shotgun_chrome", binfo);
			
			FormatEx(binfo, sizeof(binfo), "普通小手枪 %dB数",0, client);
			menu.AddItem("pistol", binfo);
		}else{
			FormatEx(binfo, sizeof(binfo), "马格南 %dB数",CostMagnum, client);
			menu.AddItem("pistol_magnum", binfo);
			FormatEx(binfo, sizeof(binfo),  "Uzi %dB数",CostUzi, client);
			menu.AddItem("smg", binfo);

			FormatEx(binfo, sizeof(binfo), "消音smg %dB数",CostSilenced,client);
			menu.AddItem("smg_silenced", binfo);
		
			FormatEx(binfo, sizeof(binfo),  "一代单发霰弹枪 %dB数",CostPumpShotgun, client);
			menu.AddItem("pumpshotgun", binfo);

			FormatEx(binfo, sizeof(binfo),  "二代单发霰弹枪 %dB数",CostPumpShotgun, client);
			menu.AddItem("shotgun_chrome", binfo);
			
			FormatEx(binfo, sizeof(binfo),"普通小手枪 %dB数",CostP220, client);
			menu.AddItem("pistol", binfo);
		}
		
		FormatEx(binfo, sizeof(binfo),  "mp5机枪 %dB数",CostMP5, client);
		menu.AddItem("smg_mp5", binfo);
		
		if(!IsAllowBigGun)
		{
			menu.Display(client, 20);
			return;
		}
		
		FormatEx(binfo, sizeof(binfo),  "一代连发霰弹枪 %dB数",CostAuto, client);
		menu.AddItem("autoshotgun", binfo);

		FormatEx(binfo, sizeof(binfo),  "二代连发霰弹枪 %dB数",CostAuto, client);
		menu.AddItem("shotgun_spas", binfo);
		
		FormatEx(binfo, sizeof(binfo),  "m16步枪 %dB数",CostM16, client);
		menu.AddItem("rifle", binfo);

		FormatEx(binfo, sizeof(binfo),  "ak47步枪 %dB数",CostAK47, client);
		menu.AddItem("rifle_ak47", binfo);

		FormatEx(binfo, sizeof(binfo),  "sg552步枪 %dB数",CostSG552, client);
		menu.AddItem("rifle_sg552", binfo);

		FormatEx(binfo, sizeof(binfo),  "scar步枪 %dB数",CostSCAR, client);
		menu.AddItem("rifle_desert", binfo);
		
		FormatEx(binfo, sizeof(binfo),  "一代连狙 %dB数",CostHunting, client);
		menu.AddItem("hunting_rifle", binfo);

		FormatEx(binfo, sizeof(binfo),  "二代连狙 %dB数",CostMilitary, client);
		menu.AddItem("sniper_military", binfo);

		FormatEx(binfo, sizeof(binfo),  "鸟狙 %dB数",CostScout, client);
		menu.AddItem("sniper_scout", binfo);

		FormatEx(binfo, sizeof(binfo),  "AWP狙击枪 %dB数",CostAWP, client);
		menu.AddItem("sniper_awp", binfo);
		
		FormatEx(binfo, sizeof(binfo),  "m60 %dB数",CostM60, client);
		menu.AddItem("rifle_m60", binfo);

		FormatEx(binfo, sizeof(binfo),  "榴弹发射器 %dB数",CostGrenadeLuanch, client);
		menu.AddItem("grenade_launcher", binfo);
		
		menu.Display(client, 20);
	}
}



public int gun_back(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char bitem[64];
			menu.GetItem(param2, bitem, sizeof(bitem));
			if( StrEqual(bitem, "smg") )
			{
				int costpoints = CostUzi;
				if(player[param1].ClientFirstBuy){
					player[param1].ClientFirstBuy=false;
					RemovePoints(param1, 0, bitem);
					PrintToChatAll("\x04%N\x03第一次白嫖了一把%s，还剩%d的B数",param1,"Uzi",player[param1].ClientPoints);
				}
				else if(RemovePoints(param1, costpoints, bitem))
				PrintToChatAll("\x04%N\x03B数-%d,购买了%s，还剩%d的B数",param1,CostUzi,"Uzi",player[param1].ClientPoints);
			}
			else if( StrEqual(bitem, "smg_silenced") )
			{
				
				int costpoints = CostSilenced;
				if(player[param1].ClientFirstBuy){
					player[param1].ClientFirstBuy=false;
					RemovePoints(param1, 0, bitem);
					PrintToChatAll("\x04%N\x03第一次白嫖了一把%s，还剩%d的B数",param1,"消音smg",player[param1].ClientPoints);
				}
				else if(RemovePoints(param1, costpoints, bitem))
				PrintToChatAll("\x04%N\x03B数-%d,购买了%s，还剩%d的B数",param1,CostSilenced,"消音smg",player[param1].ClientPoints);
			}				
			else if( StrEqual(bitem, "smg_mp5") )
			{
				
				int costpoints = CostMP5;
				if(RemovePoints(param1, costpoints, bitem))
				PrintToChatAll("\x04%N\x03B数-%d,购买了%s，还剩%d的B数",param1,CostMP5,"mp5",player[param1].ClientPoints);
			}	
			else if( StrEqual(bitem, "rifle") ){
				//
				int costpoints = CostM16;
				if(RemovePoints(param1, costpoints, bitem))
				PrintToChatAll("\x04%N\x03B数-%d,购买了%s，还剩%d的B数",param1,CostM16,"m16步枪",player[param1].ClientPoints);
			}
			else if( StrEqual(bitem, "rifle_ak47") ){
				int costpoints = CostAK47;
				if(RemovePoints(param1, costpoints, bitem))
				PrintToChatAll("\x04%N\x03B数-%d,购买了%s，还剩%d的B数",param1,CostAK47,"ak47步枪",player[param1].ClientPoints);
			}
				
			else if( StrEqual(bitem, "rifle_sg552") ){
				int costpoints = CostSG552;
				if(RemovePoints(param1, costpoints, bitem))
				PrintToChatAll("\x04%N\x03B数-%d,购买了%s，还剩%d的B数",param1,CostSG552,"sg552步枪",player[param1].ClientPoints);
			}
				
			else if( StrEqual(bitem, "rifle_desert") ){
				int costpoints = CostSCAR;
				if(RemovePoints(param1, costpoints, bitem))
				PrintToChatAll("\x04%N\x03B数-%d,购买了%s，还剩%d的B数",param1,CostSCAR,"scar步枪",player[param1].ClientPoints);
			}
			else if( StrEqual(bitem, "pumpshotgun") ){
				int costpoints = CostPumpShotgun;
				
				if(player[param1].ClientFirstBuy){
					player[param1].ClientFirstBuy=false;
					RemovePoints(param1, 0, bitem);
					PrintToChatAll("\x04%N\x03第一次白嫖了一把%s，还剩%d的B数",param1,"一代单喷",player[param1].ClientPoints);
				}
				else if(RemovePoints(param1, costpoints, bitem))
				PrintToChatAll("\x04%N\x03B数-%d,购买了%s，还剩%d的B数",param1,CostPumpShotgun,"一代单喷",player[param1].ClientPoints);
			}
			else if( StrEqual(bitem, "shotgun_chrome") ){
				int costpoints = CostChromeShotgun;
				if(player[param1].ClientFirstBuy){
					player[param1].ClientFirstBuy=false;
					RemovePoints(param1, 0, bitem);
					PrintToChatAll("\x04%N\x03第一次白嫖了一把%s，还剩%d的B数",param1,"二代单喷",player[param1].ClientPoints);
				}
				else if(RemovePoints(param1, costpoints, bitem))
				PrintToChatAll("\x04%N\x03B数-%d,购买了%s，还剩%d的B数",param1,CostChromeShotgun,"二代单喷",player[param1].ClientPoints);
			}
			else if( StrEqual(bitem, "autoshotgun") ){
				int costpoints = CostAuto;
				if(RemovePoints(param1, costpoints, bitem))
				PrintToChatAll("\x04%N\x03B数-%d,购买了%s，还剩%d的B数",param1,CostAuto,"一代连喷",player[param1].ClientPoints);
			}
			else if( StrEqual(bitem, "shotgun_spas") ){
				int costpoints = CostSPAS;
				if(RemovePoints(param1, costpoints, bitem))
				PrintToChatAll("\x04%N\x03B数-%d,购买了%s，还剩%d的B数",param1,CostSPAS,"二代连喷",player[param1].ClientPoints);
			}
			else if( StrEqual(bitem, "hunting_rifle") ){
				int costpoints = CostHunting;
				if(RemovePoints(param1, costpoints, bitem))
				PrintToChatAll("\x04%N\x03B数-%d,购买了%s，还剩%d的B数",param1,CostHunting,"一代连狙",player[param1].ClientPoints);
			}
			else if( StrEqual(bitem, "sniper_military") ){
				int costpoints = CostMilitary;
				if(RemovePoints(param1, costpoints, bitem))
				PrintToChatAll("\x04%N\x03B数-%d,购买了%s，还剩%d的B数",param1,CostMilitary,"二代连狙",player[param1].ClientPoints);
			}
			else if( StrEqual(bitem, "sniper_scout") ){
				int costpoints = CostScout;
				if(RemovePoints(param1, costpoints, bitem))
				PrintToChatAll("\x04%N\x03B数-%d,购买了%s，还剩%d的B数",param1,CostScout,"鸟狙",player[param1].ClientPoints);
			}
			else if( StrEqual(bitem, "sniper_awp") ){
				int costpoints = CostAWP;
				if(RemovePoints(param1, costpoints, bitem))
				PrintToChatAll("\x04%N\x03B数-%d,购买了%s，还剩%d的B数",param1,CostAWP,"AWP狙击枪",player[param1].ClientPoints);
			}
			else if( StrEqual(bitem, "rifle_m60") ){
				int costpoints = CostM60;
				if(RemovePoints(param1, costpoints, bitem))
				PrintToChatAll("\x04%N\x03B数-%d,购买了%s，还剩%d的B数",param1,CostM60,"m60",player[param1].ClientPoints);
			}
			else if( StrEqual(bitem, "grenade_launcher") ){
				int costpoints = CostGrenadeLuanch;
				if(RemovePoints(param1, costpoints, bitem))
				PrintToChatAll("\x04%N\x03B数-%d,购买了%s，还剩%d的B数",param1,CostGrenadeLuanch,"榴弹发射器",player[param1].ClientPoints);
			}
			else if( StrEqual(bitem, "pistol") ){			
				int costpoints = CostP220;
				if(player[param1].ClientFirstBuy){
					player[param1].ClientFirstBuy=false;
					RemovePoints(param1, 0, bitem);
					PrintToChatAll("\x04%N\x03第一次白嫖了一把%s，还剩%d的B数",param1,"小手枪",player[param1].ClientPoints);
				}
				else if(RemovePoints(param1, costpoints, bitem))
				PrintToChatAll("\x04%N\x03B数-%d,购买了%s，还剩%d的B数",param1,CostP220,"小手枪",player[param1].ClientPoints);
			}
			else if( StrEqual(bitem, "pistol_magnum") ){
				
				int costpoints = CostMagnum;
				if(player[param1].ClientFirstBuy){
					player[param1].ClientFirstBuy=false;
					RemovePoints(param1, 0, bitem);
					PrintToChatAll("\x04%N\x03第一次白嫖了一把%s，还剩%d的B数",param1,"马格南",player[param1].ClientPoints);
				}
				else if(RemovePoints(param1, costpoints, bitem))
				PrintToChatAll("\x04%N\x03B数-%d,购买了%s，还剩%d的B数",param1,CostMagnum,"马格南",player[param1].ClientPoints);
			}
			else if( StrEqual(bitem, "ammo") ){
				ClientCommand(param1, "sm_ammo");
			}
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}


//创建购买菜单>>主菜单--医疗物品/药品
public void supply(int client)
{
	if( IsVaildClient(client) )
	{
		char binfo[64];
		Menu menu = new Menu(supply_back);
		menu.SetTitle("医疗物品\n——————————");

		FormatEx(binfo, sizeof(binfo),  "药丸 %dB数",CostPills, client);
		menu.AddItem("pain_pills", binfo);

		FormatEx(binfo, sizeof(binfo),  "肾上腺素 %dB数",CostAdren, client);
		menu.AddItem("adrenaline", binfo);
		
		FormatEx(binfo, sizeof(binfo),  "医疗包 %dB数",CostFirstAidKit,client);
		menu.AddItem("first_aid_kit", binfo);
		
		FormatEx(binfo, sizeof(binfo),  "油桶 %dB数",CostGascan, client);
		menu.AddItem("gascan", binfo);
		
		FormatEx(binfo, sizeof(binfo),  "治疗小侏儒 %dB数",CostGnome, client);
		menu.AddItem("weapon_gnome", binfo);

		menu.Display(client, 20);
	}
}
public int supply_back(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char bitem[64];
			menu.GetItem(param2, bitem, sizeof(bitem));
			if( StrEqual(bitem, "first_aid_kit") ){				
				int costpoints = CostFirstAidKit;
				if(RemovePoints(param1, costpoints, bitem))
				PrintToChatAll("\x04%N\x03B数-%d,购买了%s，还剩%d的B数",param1,CostFirstAidKit,"医疗包",player[param1].ClientPoints);
			}
			else if( StrEqual(bitem, "pain_pills") ){				
				int costpoints = CostPills;
				if(RemovePoints(param1, costpoints, bitem))
				PrintToChatAll("\x04%N\x03B数-%d,购买了%s，还剩%d的B数",param1,CostPills,"药丸",player[param1].ClientPoints);
			}
			else if( StrEqual(bitem, "adrenaline") ){				
				int costpoints = CostAdren;
				if(RemovePoints(param1, costpoints, bitem))
				PrintToChatAll("\x04%N\x03B数-%d,购买了%s，还剩%d的B数",param1,CostAdren,"肾上腺素",player[param1].ClientPoints);
			}
			else if( StrEqual(bitem, "gascan") ){
				
				int costpoints = CostGascan;
				if(RemovePoints(param1, costpoints, bitem))
				PrintToChatAll("\x04%N\x03B数-%d,购买了%s，还剩%d的B数",param1,CostGascan,"油桶",player[param1].ClientPoints);
			}
			else if( StrEqual(bitem, "weapon_gnome") ){
				
				int costpoints = CostGnome;
				if(RemovePoints(param1, costpoints, bitem))
				PrintToChatAll("\x04%N\x03B数-%d,购买了%s，还剩%d的B数",param1,CostGnome,"治疗小侏儒",player[param1].ClientPoints);
			}
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}
//创建购买菜单>>主菜单--技能界面
public void ability(int client)
{
	if( IsVaildClient(client) )
	{
		char binfo[64];
		Menu menu = new Menu(ability_back);
		menu.SetTitle("选择出门近战,当前为%d\n——————————",player[client].ClientMelee);
		
		FormatEx(binfo, sizeof(binfo),  "砍刀", client);
		menu.AddItem("machete", binfo);

		FormatEx(binfo, sizeof(binfo),  "消防斧", client);
		menu.AddItem("fireaxe", binfo);

		FormatEx(binfo, sizeof(binfo),  "小刀", client);
		menu.AddItem("knife", binfo);

		FormatEx(binfo, sizeof(binfo),  "武士刀", client);
		menu.AddItem("katana", binfo);

		FormatEx(binfo, sizeof(binfo),  "马格南", client);
		menu.AddItem("pistol_magnum", binfo);

		FormatEx(binfo, sizeof(binfo),  "电吉他", client);
		menu.AddItem("electric_guitar", binfo);

		FormatEx(binfo, sizeof(binfo),  "警棍", client);
		menu.AddItem("tonfa", binfo);

		FormatEx(binfo, sizeof(binfo),  "草叉", client);
		menu.AddItem("pitchfork", binfo);

		FormatEx(binfo, sizeof(binfo),  "铲子", client);
		menu.AddItem("shovel", binfo);
		
		FormatEx(binfo, sizeof(binfo),  "普通小手枪", client);
		menu.AddItem("pistol", binfo);
		
		FormatEx(binfo, sizeof(binfo),  "平底锅", client);
		menu.AddItem("frying_pan", binfo);
		
		FormatEx(binfo, sizeof(binfo),  "撬棍", client);
		menu.AddItem("crowbar", binfo);
		
		FormatEx(binfo, sizeof(binfo),  "板球拍", client);
		menu.AddItem("cricket_bat", binfo);

		FormatEx(binfo, sizeof(binfo),  "随机近战", client);
		menu.AddItem("random_secondweapon", binfo);

		FormatEx(binfo, sizeof(binfo),  "取消设置", client);
		menu.AddItem("none", binfo);

		menu.Display(client, 20);
	}
}
public int ability_back(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char bitem[64];
			menu.GetItem(param2, bitem, sizeof(bitem));
			if( StrEqual(bitem, "machete") ){		
				player[param1].ClientMelee=1;
				ClientSaveToFileSave(param1);
				PrintToChat(param1,"\x04您的出门近战武器设为砍刀");
			}
			else if( StrEqual(bitem, "fireaxe") ){
				player[param1].ClientMelee=2;
				ClientSaveToFileSave(param1);
				PrintToChat(param1,"\x04您的出门近战武器设为消防斧");
			}
			else if( StrEqual(bitem, "knife") ){
				player[param1].ClientMelee=3;
				ClientSaveToFileSave(param1);
				PrintToChat(param1,"\x04您的出门近战武器设为小刀");
			}
			else if( StrEqual(bitem, "katana") ){
				player[param1].ClientMelee=4;
				ClientSaveToFileSave(param1);
				PrintToChat(param1,"\x04您的出门近战武器设为武士刀");
			}
			else if( StrEqual(bitem, "pistol_magnum") ){
				player[param1].ClientMelee=5;
				ClientSaveToFileSave(param1);
				PrintToChat(param1,"\x04您的出门近战武器设为马格南");
			}
			else if( StrEqual(bitem, "electric_guitar") ){
				player[param1].ClientMelee=6;
				ClientSaveToFileSave(param1);
				PrintToChat(param1,"\x04您的出门近战武器设为电吉他");
			}
			else if( StrEqual(bitem, "tonfa") ){
				player[param1].ClientMelee=7;
				ClientSaveToFileSave(param1);
				PrintToChat(param1,"\x04您的出门近战武器设为警棍");
			}
			else if( StrEqual(bitem, "pitchfork") ){
				player[param1].ClientMelee=8;
				ClientSaveToFileSave(param1);
				PrintToChat(param1,"\x04您的出门近战武器设为草叉");
			}
			else if( StrEqual(bitem, "shovel") ){
				player[param1].ClientMelee=9;
				ClientSaveToFileSave(param1);
				PrintToChat(param1,"\x04您的出门近战武器设为铲子");
			}
			else if( StrEqual(bitem, "pistol") ){
				player[param1].ClientMelee=10;
				ClientSaveToFileSave(param1);
				PrintToChat(param1,"\x04您的出门近战武器设为小手枪");
			}else if( StrEqual(bitem, "frying_pan") ){
				player[param1].ClientMelee=11;
				ClientSaveToFileSave(param1);
				PrintToChat(param1,"\x04您的出门近战武器设为平底锅");
			}else if( StrEqual(bitem, "crowbar") ){
				player[param1].ClientMelee=12;
				ClientSaveToFileSave(param1);
				PrintToChat(param1,"\x04您的出门近战武器设为撬棍");
			}else if( StrEqual(bitem, "cricket_bat") ){
				player[param1].ClientMelee=13;
				ClientSaveToFileSave(param1);
				PrintToChat(param1,"\x04您的出门近战武器设为板球拍");
			}else if( StrEqual(bitem, "random_secondweapon") ){
				player[param1].ClientMelee=14;
				ClientSaveToFileSave(param1);
				PrintToChat(param1,"\x04您的出门近战武器设为板球拍");
			}else if( StrEqual(bitem, "none") ){
				player[param1].ClientMelee = 0;
				ClientSaveToFileSave(param1);
				PrintToChat(param1,"\x04您取消了出门近战武器");
			}else 
			{
				PrintToChat(param1,"\x03您的出门近战武器设置失败，超出限制");
			}
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}
//创建购买菜单>>主菜单--技能界面
public void Blood(int client)
{
	if( IsVaildClient(client) )
	{
		char binfo[64];
		Menu menu = new Menu(Blood_back);
		if(player[client].ClientBlood)
			menu.SetTitle("是否开启杀特回血,当前状态：是\n——————————");
		else
			menu.SetTitle("是否开启杀特回血,当前状态：否\n——————————");
		FormatEx(binfo, sizeof(binfo),  "是", client);
		menu.AddItem("Yes", binfo);

		FormatEx(binfo, sizeof(binfo),  "否", client);
		menu.AddItem("No", binfo);
		menu.Display(client, 20);
	}
}

public int Blood_back(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char bitem[64];
			menu.GetItem(param2, bitem, sizeof(bitem));
			if( StrEqual(bitem, "Yes") ){
				
				player[param1].ClientBlood=1;
				ClientSaveToFileSave(param1);
				PrintToChat(param1,"\x04你已经开启了杀特回血，杀一只特感回2滴血，不超过血量上限");
			}
			else {				
				player[param1].ClientBlood=0;
				ClientSaveToFileSave(param1);
				PrintToChat(param1,"\x04你已经关闭了杀特回血.");
			}
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}


//创建购买菜单>>主菜单--技能界面
public void Recoil(int client)
{
	if( IsVaildClient(client) )
	{
		char binfo[64];
		Menu menu = new Menu(Recoil_back);
		if (player[client].ClientRecoil)
		menu.SetTitle("是否开启防抖动（去除枪械抖动），当前状态：是\n——————————");
	else
		menu.SetTitle("是否开启防抖动（去除枪械抖动），当前状态：否\n——————————");

		FormatEx(binfo, sizeof(binfo),  "是", client);
		menu.AddItem("Yes", binfo);
		FormatEx(binfo, sizeof(binfo),  "否", client);
		menu.AddItem("No", binfo);
		menu.Display(client, 20);
	}
}

public int Recoil_back(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char bitem[64];
            menu.GetItem(param2, bitem, sizeof(bitem));

            // Yes = 不抖动(去抖) → sm_recoil 1
            // No  = 抖动(原版)   → sm_recoil 0
            int want = StrEqual(bitem, "Yes") ? 1 : 0;

            // 1) 立即更新本地值并写库，保证数据库与面板显示一致
            player[param1].ClientRecoil = want; 
            ClientSaveToFileSave(param1);

            // 3) **下一帧**再执行命令，避免在菜单回调里直接 FakeClientCommand 失效的情况
            DataPack pack = new DataPack();
            pack.WriteCell(GetClientUserId(param1)); // 保存 userid，避免玩家刚好重连导致 index 变动
            pack.WriteCell(want);
            RequestFrame(Exec_RecoilCmdNextFrame, pack);
        }

        case MenuAction_End:
            delete menu;
    }
    return 0;
}

// 在下一帧执行命令
public void Exec_RecoilCmdNextFrame(DataPack pack)
{
    pack.Reset();
    int userid = pack.ReadCell();
    int want   = pack.ReadCell();
    delete pack;

    int client = GetClientOfUserId(userid);
    if (client <= 0 || !IsClientInGame(client))
        return;

    // 4) 触发 punch 插件的命令：!recoil 1=不抖动，0=抖动
    //    建议用 FakeClientCommandEx 以便拿到返回值（若你的 SM 版本支持）
    FakeClientCommand(client, "sm_recoil %d", want);
}


stock bool IsAboveFourPeople()
{
	ConVar survivorManager = FindConVar("l4d_multislots_survivors_manager_enable");
	if( survivorManager == null)
	{
		return false;
	}
	else
	{
		if(survivorManager.BoolValue)
		{
			return true;
		}else
		{
			return false;
		}
	}
}
stock int getSurvivorNum()
{
	int count = 0;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			count ++;
		}
	}
	return count;
}
stock bool IsGaoJiRenJiEnabled()
{
	ConVar gjrj = FindConVar("sb_fix_enabled");
	if(gjrj == null)
	{
		return false;
	}
	else if(gjrj.BoolValue)
	{
		return true;
	}
	return false;
}
// 这回合是否有效
stock bool IsThisRoundValid()
{
	ConVar tank_bhop = FindConVar("ai_Tank_Bhop");
	if(AnneMultiPlayerMode())
	{
		return tank_bhop.BoolValue;
	}
	return true;
}

stock bool AnneMultiPlayerMode(){
	char plugin_name[MAX_LINE_WIDTH];
	ConVar cvar_mode;
	if(cvar_mode == null && FindConVar("l4d_ready_cfg_name"))
	{
		cvar_mode = FindConVar("l4d_ready_cfg_name");
	}
	if(cvar_mode == null) return false;
	GetConVarString(cvar_mode, plugin_name, sizeof(plugin_name));
	if(StrContains(plugin_name, "AllCharger", false) != -1 || StrContains(plugin_name, "AnneHappy", false) != -1 || StrContains(plugin_name, "WitchParty", false) != -1)
	{
		return true;
	}else
	{
		return false;
	}
}

public Action OnCallVote(int client, const char[] command, int argc)
{
    if (client <= 0 || !IsClientInGame(client)) return Plugin_Continue;
    if (!g_hAntiKickEnable.BoolValue || !g_hAntiKickBlockVote.BoolValue) return Plugin_Continue;

    // 语法: callvote Kick <#userid|name>  （其他议题不拦）
    char issue[32]; GetCmdArg(1, issue, sizeof(issue));
    if (!StrEqual(issue, "Kick", false)) return Plugin_Continue;

    char targetArg[64]; GetCmdArg(2, targetArg, sizeof(targetArg));
    if (targetArg[0] == '\0') return Plugin_Continue;

    int target = ResolveSingleTarget(targetArg);
    if (target <= 0) return Plugin_Continue;

    if (IsAdminProtected(target))
    {
        char tname[64], cname[64];
        GetClientName(target, tname, sizeof(tname));
        GetClientName(client, cname, sizeof(cname));

        CPrintToChat(client, "\x04[AntiKick]\x01 该玩家 \x05%N\x01 为管理员，已启用防踢，投票无效。", target);
        PrintToServer("[AntiKick] %s attempted votekick on admin %s, blocked.", cname, tname);
        return Plugin_Handled;   // 直接拦截投票
    }

    return Plugin_Continue;
}

public Action OnSmKick(int client, const char[] command, int argc)
{
    // 控制台/服务器执行不拦（通常用于管理）
    if (client == 0) return Plugin_Continue;
    if (!IsClientInGame(client)) return Plugin_Continue;
    if (!g_hAntiKickEnable.BoolValue || !g_hAntiKickBlockCmdKick.BoolValue) return Plugin_Continue;

    // 语法: sm_kick <#userid|name> [reason...]
    char targetArg[64]; GetCmdArg(1, targetArg, sizeof(targetArg));
    if (targetArg[0] == '\0') return Plugin_Continue;

    int target = ResolveSingleTarget(targetArg);
    if (target <= 0) return Plugin_Continue;

    if (!IsAdminProtected(target)) return Plugin_Continue;

    int callerImm = GetClientImmunityLevel(client);
    int targetImm = GetClientImmunityLevel(target);
    bool equalBlock = g_hAntiKickEqualBlock.BoolValue;

    // 规则：低级 < 高级 => 禁止；同级 && equalBlock => 禁止
    if (callerImm < targetImm || (callerImm == targetImm && equalBlock))
    {
        char tname[64];
        GetClientName(target, tname, sizeof(tname));
        CPrintToChat(client, "\x04[AntiKick]\x01 你无权踢出受保护管理员：\x05%N\x01。", target);
        return Plugin_Handled;
    }

    // 更高免疫管理员可以踢（尊重免疫层级）
    return Plugin_Continue;
}
