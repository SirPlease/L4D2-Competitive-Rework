#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>
#include <clientprefs>

// ★ 可选依赖 RPG（有就用，没有继续走 Cookie）
#undef REQUIRE_PLUGIN
#include <rpg>

#define PLUGIN_VERSION 		"1.4.1"
#define GAMEDATA_FILE  		"punch_angle"
#define COOKIE_NAME	   		"punch_angle_cookie"
#define TRANSLATION_FILE 	"punch_angle.phrases"

// Cvars
ConVar g_cvZGunVerticalPu;
ConVar g_cvToggle;

// Cookie（作为无 RPG 时的持久化）
Cookie g_hCookie = null;

// 开关：true=不抖动（去抖），false=抖动（原版）
bool g_bAntiShake[MAXPLAYERS + 1] = { false, ... };
bool g_bEnable = true;
bool g_bRPG = false;

public Plugin myinfo =
{
	name = "[L4D2] Punch Angle (RPG-aware, recoil command)",
	author = "sorallll, blueblur, + morzlee/ChatGPT",
	description = "Remove recoil when shooting and getting hit. Uses RPG if present. Adds !recoil command.",
	version	= PLUGIN_VERSION,
	url	= "https://github.com/blueblur0730/modified-plugins"
};

// ===== RPG 库检测 =====
public void OnAllPluginsLoaded()                     { g_bRPG = LibraryExists("rpg"); }
public void OnLibraryAdded(const char[] name)        { if (StrEqual(name, "rpg")) g_bRPG = true; }
public void OnLibraryRemoved(const char[] name)      { if (StrEqual(name, "rpg")) g_bRPG = false; }

// ===== 启动 =====
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion version = GetEngineVersion();
	if (version != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead 2\" game");
		return APLRes_SilentFailure;
	}
	RegPluginLibrary("punch_angle");
	return APLRes_Success;
}

public void OnPluginStart()
{
	IniGameData();
	LoadTranslation(TRANSLATION_FILE);

	CreateConVar("punch_angle_version", PLUGIN_VERSION, "Version of the Punch Angle plugin.",
		FCVAR_NOTIFY | FCVAR_DEVELOPMENTONLY | FCVAR_DONTRECORD);

	g_hCookie = new Cookie(COOKIE_NAME, "Toggles recoil on or off.", CookieAccess_Protected);
	g_hCookie.SetPrefabMenu(CookieMenu_OnOff, "Punch Angle Toggle", CookieSelected, g_hCookie);

	// 该 cvar 控制射击的垂直 punch；去抖时置 0，原版置 1
	g_cvZGunVerticalPu = FindConVar("z_gun_vertical_punch");
	if (g_cvZGunVerticalPu != null) g_cvZGunVerticalPu.IntValue = 1;

	g_cvToggle = CreateConVar("punch_angle_toggle", "1", "Toggles recoil on or off.",
		_, true, 0.0, true, 1.0);
	g_cvToggle.AddChangeHook(OnToggle);
	g_bEnable = g_cvToggle.BoolValue;

	// ★ 命令：!recoil / !punch
	RegConsoleCmd("sm_recoil", Cmd_Recoil);
	RegConsoleCmd("sm_punch",  Cmd_Recoil);
}

public void OnPluginEnd()
{
	if (g_cvZGunVerticalPu != null)
	{
		// prevent this from replicating to clients.
		g_cvZGunVerticalPu.RestoreDefault(true, false);
	}
}

// ===== 玩家上线：同步状态 =====
public void OnClientPutInServer(int client)
{
	if (IsFakeClient(client)) return;

	// 优先 RPG 值：RPG 约定 1=不抖动；0=抖动
	if (g_bRPG)
	{
		int v = L4D_RPG_GetValue(client, INDEX_RECOIL);
		if (v != -1)
		{
			bool anti = (v != 0); // v=1 → 不抖动
			ApplyRecoilSetting(client, anti, true, true);
			return;
		}
	}
	// RPG 不可用/失败 → Cookie 流程由 OnClientCookiesCached 覆盖
}

public void OnClientCookiesCached(int client)
{
	if (IsFakeClient(client)) return;

	// 再尝试 RPG（若库刚加载/延迟）
	if (g_bRPG)
	{
		int v = L4D_RPG_GetValue(client, INDEX_RECOIL);
		if (v != -1)
		{
			bool anti = (v != 0);
			ApplyRecoilSetting(client, anti, true, true);
			return;
		}
	}

	// Cookie 回退："On" 表示不抖动（去抖）
	char value[4];
	g_hCookie.Get(client, value, sizeof(value));
	bool anti = (value[0] == '\0' || StrEqual(value, "On"));
	ApplyRecoilSetting(client, anti, false, true);
}

void CookieSelected(int client, CookieMenuAction action, Cookie info, char[] buffer, int maxlen)
{
	if (action == CookieMenuAction_DisplayOption)
	{
		PrintToChat(client, "%t", "Select");
	}
	else
	{
		char value[4];
		info.Get(client, value, sizeof(value));
		PrintToChat(client, "%t", "CookieSlected", value); // Punch Angle Toggle: %s
	}
}

// ======== 新增命令：!recoil / !punch ========
// 用法：!recoil            → 切换
//      !recoil 0          → 开启抖动（原版）
//      !recoil 1          → 不抖动（去抖）
public Action Cmd_Recoil(int client, int args)
{
	if (client <= 0 || !IsClientInGame(client)) return Plugin_Handled;

	bool anti = g_bAntiShake[client]; // 当前是否不抖动
	if (args >= 1)
	{
		char sArg[8];
		GetCmdArg(1, sArg, sizeof(sArg));
		int iv = StringToInt(sArg);
		if (iv != 0 && iv != 1)
		{
			PrintToChat(client, "%t", "PunchAngle_RecoilUsageRecoil01");
			return Plugin_Handled;
		}
		// 1 = 不抖动（去抖） → anti=true；0 = 抖动 → anti=false
		anti = (iv == 1);
	}
	else
	{
		// 无参 → 反转
		anti = !anti;
	}

	// 应用 + 持久化（RPG/或Cookie）
	ApplyRecoilSetting(client, anti, true, false);

	// 反馈
	if (anti)
		PrintToChat(client, "%t", "PunchAngle_JitterTurnedOffDebounceNo");
	else
		PrintToChat(client, "%t", "PunchAngle_JitterOriginalEffect");

	return Plugin_Handled;
}

// ======== 统一应用函数 ========
// anti=true  → 不抖动（去抖）
// persist=true 时，写 RPG（若可用）或 Cookie
// silent=true 时不打印聊天提示（用于上线同步）
static void ApplyRecoilSetting(int client, bool anti, bool persist, bool silent)
{
	g_bAntiShake[client] = anti;

	// 同步 cvar 到该客户端（去抖→0，原版→1）
	if (g_cvZGunVerticalPu != null)
		g_cvZGunVerticalPu.ReplicateToClient(client, anti ? "0" : "1");

	if (persist)
	{
		if (g_bRPG)
		{
			// RPG 语义：1=不抖动；0=抖动 不用改，插件自己维护
			//int rpgValue = anti ? 1 : 0;
			//L4D_RPG_SetValue(client, INDEX_RECOIL, rpgValue);
		}
		else
		{
			// 没有 RPG 就用 Cookie：On=不抖动；Off=抖动
			g_hCookie.Set(client, anti ? "On" : "Off");
		}
	}

	if (!silent)
	{
		// 已在命令里提示，这里不重复
	}
}

// ===== 被击中抖动：去抖时屏蔽 Punch =====
MRESReturn DD_CBasePlayer_SetPunchAngle_Pre(int pThis, DHookReturn hReturn)
{
	if (GetClientTeam(pThis) != 2 || !IsPlayerAlive(pThis))
		return MRES_Ignored;

	// g_bEnable 总开关 + 不抖动时屏蔽 punch
	if (g_bEnable && g_bAntiShake[pThis])
	{
		hReturn.Value = 0;
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

void OnToggle(ConVar convar, char[] old_value, char[] new_value)
{
	g_bEnable = convar.BoolValue;
}

// ===== Gamedata & Detour =====
void IniGameData()
{
	char buffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, buffer, sizeof buffer, "gamedata/%s.txt", GAMEDATA_FILE);
	if (!FileExists(buffer))
		SetFailState("\n==========\nMissing required file: \"%s\".\n==========", buffer);

	GameData hGameData = new GameData(GAMEDATA_FILE);
	if (!hGameData)
		SetFailState("Failed to load gamedata file \"" ... GAMEDATA_FILE... "\".");

	DynamicDetour hDetour = DynamicDetour.FromConf(hGameData, "DD::CBasePlayer::SetPunchAngle");
	if (!hDetour)
		SetFailState("Failed to create DynamicDetour: \"DD::CBasePlayer::SetPunchAngle\"");

	if (!hDetour.Enable(Hook_Pre, DD_CBasePlayer_SetPunchAngle_Pre))
		SetFailState("Failed to detour pre: \"DD::CBasePlayer::SetPunchAngle\"");

	delete hDetour;
	delete hGameData;
}

stock void LoadTranslation(const char[] translation)
{
	char sPath[PLATFORM_MAX_PATH], sName[64];

	Format(sName, sizeof(sName), "translations/%s.txt", translation);
	BuildPath(Path_SM, sPath, sizeof(sPath), sName);
	if (!FileExists(sPath))
		SetFailState("Missing translation file %s.txt", translation);

	LoadTranslations(translation);
}
