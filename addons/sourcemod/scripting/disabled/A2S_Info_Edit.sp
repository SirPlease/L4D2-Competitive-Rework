#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>				// https://forums.alliedmods.net/showthread.php?t=321696
#include <sourcescramble>			// https://github.com/nosoop/SMExt-SourceScramble
#include <localizer> 				// https://github.com/dragokas/SM-Localizer
#include <l4d2_source_keyvalues>	// https://github.com/fdxx/l4d2_source_keyvalues

/*
	部分代码来源:
	fdxx => l4d2_source_keyvalues
	umlka => map_changer
	dragokas => SM-Localizer
*/

#define GAMEDATA				"A2S_Info_Edit"

#define PLUGIN_NAME				"A2S_INFO Edit | A2S_INFO 信息修改"
#define PLUGIN_AUTHOR			"yuzumi"
#define PLUGIN_VERSION			"1.1.3"
#define PLUGIN_DESCRIPTION		"DIY Server A2S_INFO Information | 定义自己服务器的A2S_INFO信息"
#define PLUGIN_URL				"https://github.com/joyrhyme/L4D2-Plugins/tree/main/A2S_Info_Edit"
#define CVAR_FLAGS				FCVAR_NOTIFY

#define DEBUG					0
#define BENCHMARK				0
#if BENCHMARK
	#include <profiler>
	Profiler g_profiler;
#endif

#define TRANSLATION_MISSIONS	"a2s_missions.phrases.txt"
#define TRANSLATION_CHAPTERS	"a2s_chapters.phrases.txt"
#define A2S_SETTING				"a2s_info_edit.cfg"

// 游戏本地化文本
Localizer
	loc;

// 记录内存修补数据
MemoryPatch
	g_mMapNamePatch;

// SDKCall地址
Address
	g_pSteam3Server,
	g_pDirector,
	g_pMatchExtL4D;

// SDKCall句柄
Handle
	g_hSDK_GetSteam3Server,
	g_hSDK_SendServerInfo,
	g_hSDK_GetAllMissions;

// 各初始化状态
bool
	g_bLocInit,
	g_bIsFinalMap,
	g_bMissionCached,
	g_bFinaleStarted,
	g_bisAllBotGame;

// ConVars
ConVar
	g_hMPGameMode,
	g_hMapNameLang,
	g_hMapNameType,
	g_hAllBotGame;

// 存放修改后地图名称/游戏描述/模式名的变量
char
	g_cMap[128],
	g_cMode[64],
	g_cLanguage[5],
	g_cInFinale[32],
	g_cNotInFinale[32],
	g_cMapName[64],
	g_cCampaignName[64],
	g_cChapterName[64];

// 存放数值的变量
int
	g_iMapNameOS,
	g_iChapterNum,
	g_iChapterMaxNum,
	g_iMapNameType;

StringMap
	g_smExclude,
	g_smMissionMap;

enum struct esPhrase {
	char key[64];
	char val[64];
	int official;
}

public Plugin myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	EngineVersion iEngineVersion = GetEngineVersion();
	if(iEngineVersion != Engine_Left4Dead2 && !IsDedicatedServer())
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2 Dedicated Server!");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart() {
	g_smMissionMap = new StringMap();

	// 初始化GameData和Kv文件
	InitKvFile();
	InitGameData();

	// 创建Cvars
	g_hMapNameType = CreateConVar("a2s_info_mapname_type", "5", "A2S_INFO MapName DisplayType. 1.Mission, 2.Mission&Chapter, 3.Mission&FinaleType, 4.Mission&Chapter&FinaleType, 5.Mission&[ChapterNum|MaxChapter]", CVAR_FLAGS, true, 1.0, true, 5.0);
	g_hMapNameLang = CreateConVar("a2s_info_mapname_language", "chi", "What language is used in the generated PhraseFile to replace the TranslatedText of en? (Please Delete All A2S_Edit PhraseFile After Change This Cvar to Regenerate)", CVAR_FLAGS);
	
	g_hMPGameMode = FindConVar("mp_gamemode");
	g_hAllBotGame = FindConVar("sb_all_bot_game");
	if (g_hAllBotGame.IntValue == 1)
		g_bisAllBotGame = true;
	else
		g_hAllBotGame.IntValue = 1;

	// 初始化Cvars
	GetCvars_Mode();
	GetCvars_Lang();
	GetCvars();
	
	g_hMapNameLang.AddChangeHook(ConVarChanged_Lang);
	g_hMPGameMode.AddChangeHook(ConVarChanged_Mode);
	g_hMapNameType.AddChangeHook(ConVarChanged_Cvars);

	AutoExecConfig(true, "A2S_Edit");

	/*	事件相关
		地图名字只需要在地图有变更时进行变更,所以暂时绑MapStart和MapEnd
		终局相关事件
		finale_start // 少部分不触发(跑图类就不触发).
		finale_radio_start // 绝大部分都触发(按照目前测试没遇到过不触发的).
		gauntlet_finale_start // 从头跑到尾的貌似触发这个(像教区/三方图的冰点,闪电突袭2),都带提示向XXXXX前进.
		explain_stage_finale_start // 未知作用.
	*/
	HookEvent("round_end",	Event_RoundEnd,	EventHookMode_PostNoCopy);
	HookEvent("finale_start", Event_FinaleStart, EventHookMode_PostNoCopy);
	#if DEBUG
		HookEvent("finale_radio_start", Event_finale_radio, EventHookMode_PostNoCopy);
		HookEvent("gauntlet_finale_start", Event_gauntlet_finale, EventHookMode_PostNoCopy);
		HookEvent("explain_stage_finale_start", Event_explain_stage_finale, EventHookMode_PostNoCopy);
	#else
		HookEvent("finale_radio_start", Event_FinaleStart, EventHookMode_PostNoCopy);
		HookEvent("gauntlet_finale_start", Event_FinaleStart, EventHookMode_PostNoCopy);
	#endif

	// 注册命令
	RegAdminCmd("sm_a2s_edit_reload", cmdReload, ADMFLAG_ROOT, "Reload A2S_EDIT Setting");

	// 初始化游戏本地化文本
	loc = new Localizer();
	loc.Delegate_InitCompleted(OnPhrasesReady);
}

void ConVarChanged_Mode(ConVar convar, const char[] oldValue, const char[] newValue) {
	GetCvars_Mode();
}

void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue) {
	GetCvars();
}

void ConVarChanged_Lang(ConVar convar, const char[] oldValue, const char[] newValue) {
	GetCvars_Lang();
}

void GetCvars_Mode() {
	g_hMPGameMode.GetString(g_cMode, sizeof(g_cMode));
}

void GetCvars_Lang() {
	g_hMapNameLang.GetString(g_cLanguage, sizeof(g_cLanguage));
	if (GetLanguageByCode(g_cLanguage) == -1) {
		LogError("SourceMod unsupport this language: %s , Please chcek language setting. A2S_Edit change to use chi generate phrases files!", g_cLanguage);
		Format(g_cLanguage, sizeof(g_cLanguage), "chi");
	}
}

void GetCvars() {
	g_iMapNameType = g_hMapNameType.IntValue;
	if (g_bLocInit && g_bMissionCached) {
		ChangeMapName();
	}

}

public void OnConfigsExecuted() {
	GetCvars();
	GetCvars_Mode();

	if(!g_bMissionCached)
		CacheMissionInfo();
}

// 重载插件所用的文本配置
Action cmdReload(int client, int args) {
	if (!InitKvFile()) {
		PrintToServer("[A2S_Edit] Reload a2s_edit.cfg failed!");
		return Plugin_Handled;
	}
	
	PrintToServer("[A2S_Edit] a2s_edit.cfg is reloaded");
	return Plugin_Handled;
}

// 地图开始
public void OnMapStart() {
	// 兼容新版的L4DHOOKS的检测
	if (GetFeatureStatus(FeatureType_Native, "Left4DHooks_Version") != FeatureStatus_Available || Left4DHooks_Version() < 1135 || !L4D_HasMapStarted()) {
		RequestFrame(OnMapStartedPost);
	} else {
		OnMapStartedPost();
	}
}

// 地图结束
public void OnMapEnd() {
	// 重置终局救援流程标记
	g_bFinaleStarted = false;
}

// DEBUG用
#if DEBUG
void Event_finale_radio(Event hEvent, const char[] name, bool dontBroadcast) {
	PrintToServer("[A2S_Edit] Start finale_radio Process!");
	if (!g_bFinaleStarted) {
		g_bFinaleStarted = true;
		ChangeMapName();
	}
}
#endif

#if DEBUG
void Event_gauntlet_finale(Event hEvent, const char[] name, bool dontBroadcast) {
	PrintToServer("[A2S_Edit] Start gauntlet_finale Process!");
	if (!g_bFinaleStarted) {
		g_bFinaleStarted = true;
		ChangeMapName();
	}
}
#endif

#if DEBUG
void Event_explain_stage_finale(Event hEvent, const char[] name, bool dontBroadcast) {
	PrintToServer("[A2S_Edit] Start explain_stage_finale Process!");
	if (!g_bFinaleStarted) {
		g_bFinaleStarted = true;
		ChangeMapName();
	}
}
#endif

// 救援流程开始
void Event_FinaleStart(Event hEvent, const char[] name, bool dontBroadcast) {
	#if DEBUG
		PrintToServer("[A2S_Edit] Start Finale Process!");
	#endif

	/* 
		判断救援流程标记变量为false时
		(因为此函数绑定多个救援事件(防止部分三方图的奇怪终局),防止重复触发)
	*/
	if (!g_bFinaleStarted) {
		g_bFinaleStarted = true;
		ChangeMapName();
	}
}

// 关卡结束
void Event_RoundEnd(Event hEvent, const char[] name, bool dontBroadcast) {
	OnMapEnd();
	// 更改地图名称(针对在终局进行救援阶段时团灭后重置显示救援状态)
	ChangeMapName();
}

// 服务端首次运行时更改地图名的计时器
Action tChangeMapName(Handle timer) {
	#if DEBUG
		PrintToServer("[A2S_Edit] ChangeMapName Timer Executed!");
	#endif

	// 本地化文本/Cvars/任务信息缓存都完成时
	if (g_bLocInit && g_bMissionCached) {
		ChangeMapName();
		if (!g_bisAllBotGame)
			g_hAllBotGame.IntValue = 0;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

// 更改流程
void OnMapStartedPost() {
	// 是否为终局
	g_bIsFinalMap = L4D_IsMissionFinalMap();
	// 当前任务章节总数
	g_iChapterMaxNum = L4D_GetMaxChapters();
	// 当前章节号
	g_iChapterNum = L4D_GetCurrentChapter();

	// 如果都没初始化完(主要针对开服时)
	if (!g_bLocInit || !g_bMissionCached) {
		CreateTimer(1.0, tChangeMapName, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	} else {
		ChangeMapName();
	}
}

// 更改地图名
void ChangeMapName() {
	// 获取地图文件名
	GetCurrentMap(g_cMap, sizeof(g_cMap));
	// 获取此地图文件名所在的任务名 (ex. c1m1_hotel => L4D2C1)
	g_smMissionMap.GetString(g_cMap, g_cCampaignName, sizeof(g_cCampaignName));
	// 当前地图所在的任务译名 (ex. L4D2C1 => 死亡中心)
	fmt_Translate(g_cCampaignName, g_cCampaignName, sizeof(g_cCampaignName), 0, g_cMap);
	// 当前地图的章节译名 (ex. c1m1_hotel => 1:酒店)
	fmt_Translate(g_cMap, g_cChapterName, sizeof(g_cChapterName), 0, "");

	// 获取要显示的的类型
	switch (g_iMapNameType) {
		case 1:
			FormatEx(g_cMapName, sizeof(g_cMapName), "%s[%d]", g_cCampaignName, g_iChapterNum); // ex. 死亡中心

		case 2:
			FormatEx(g_cMapName, sizeof(g_cMapName), "%s [%s]", g_cCampaignName, g_cChapterName); // ex. 死亡中心 [1: 酒店]

		case 3:
		{
			// 是否为终局地图
			if (g_bIsFinalMap) {
				// 是否已开始救援阶段
				if (g_bFinaleStarted)
					FormatEx(g_cMapName, sizeof(g_cMapName), "%s - %s", g_cCampaignName, g_cInFinale); // ex. 死亡中心 - 救援进行中
				else
					FormatEx(g_cMapName, sizeof(g_cMapName), "%s - %s", g_cCampaignName, g_cNotInFinale); // ex. 死亡中心 - 救援未进行
			} else
				FormatEx(g_cMapName, sizeof(g_cMapName), "%s", g_cCampaignName); // ex. 死亡中心
		}

		case 4:
		{
			// 是否为终局地图
			if (g_bIsFinalMap) {
				// 是否已开始救援阶段
				if (g_bFinaleStarted)
					FormatEx(g_cMapName, sizeof(g_cMapName), "%s [%s] - %s", g_cCampaignName, g_cChapterName, g_cInFinale); // ex. 死亡中心 [4: 中厅] - 救援进行中
				else
					FormatEx(g_cMapName, sizeof(g_cMapName), "%s [%s] - %s", g_cCampaignName, g_cChapterName, g_cNotInFinale); // ex. 死亡中心 [4: 中厅] - 救援进行中
			} else
				FormatEx(g_cMapName, sizeof(g_cMapName), "%s [%s]", g_cCampaignName, g_cChapterName); // ex. 死亡中心 [4: 中厅]
		}

		case 5:
			FormatEx(g_cMapName, sizeof(g_cMapName), "%s [%s/%d]", g_cCampaignName, g_cChapterName, g_iChapterMaxNum); // ex. 死亡中心 [4: 中厅/4]

		default:
			FormatEx(g_cMapName, sizeof(g_cMapName), "%s", g_cCampaignName); // ex. 死亡中心
	}

	g_pSteam3Server = SDKCall(g_hSDK_GetSteam3Server);
	// 执行变更设定
	if (g_pSteam3Server && LoadFromAddress(g_pSteam3Server + view_as<Address>(4), NumberType_Int32)) {
		SDKCall(g_hSDK_SendServerInfo, g_pSteam3Server);
	} else {
		LogError("[A2S_Edit] Failed to get Steam3Server, ChangeMapName Failed!");	
	}
	
	// 输出DEBUG内容
	#if DEBUG
		LogAction(0, -1, "======== [A2S_Edit DEBUG] ========");
		LogAction(0, -1, "地图文件名: %s", g_cMap);
		LogAction(0, -1, "地图名: %s", g_cCampaignName);
		LogAction(0, -1, "章节名: %s", g_cChapterName);
		LogAction(0, -1, "合成后的名字: %s", g_cMapName);
		LogAction(0, -1, "地图章节号: %d", g_iChapterNum);
		LogAction(0, -1, "是否为终局: %s", g_bIsFinalMap ? "是" : "否");
		if (g_bIsFinalMap)
			LogAction(0, -1, "是否已开始救援事件: %s", g_bFinaleStarted ? "是" : "否");
		LogAction(0, -1, "=========== [DEBUG END] ===========");
	#endif
}

// DEBUG用 输出Kv的全部内容
stock void PrintAllKeyValues(SourceKeyValues root) {
	char sName[128], sValue[256];
	int type;

	for (SourceKeyValues kv = root.GetFirstSubKey(); !kv.IsNull(); kv = kv.GetNextKey())
	{
		kv.GetName(sName, sizeof(sName));

		if (!kv.GetFirstSubKey().IsNull())
		{
			PrintToServer("------ sub %s ------", sName);
			PrintAllKeyValues(kv);
		}
		else
		{
			type = kv.GetDataType(NULL_STRING);
			switch (type)
			{
				case TYPE_INT:
					PrintToServer("%s = %i", sName, kv.GetInt(NULL_STRING));
				case TYPE_FLOAT:
					PrintToServer("%s = %f", sName, kv.GetFloat(NULL_STRING));
				case TYPE_PTR:
					PrintToServer("%s = 0x%x", sName, kv.GetPtr(NULL_STRING));
				case TYPE_STRING:
				{
					kv.GetString(NULL_STRING, sValue, sizeof(sValue), "N/A");
					PrintToServer("%s = %s", sName, sValue); 
				}
				default:
					PrintToServer("%s type = %i, skip getting value", sName, type); 
			}
		}
	}

	if (root.SaveToFile("MissionTest.txt"))
		PrintToServer("Save to file succeeded: MissionTest.txt");
}

// 缓存地图对应的任务文件信息
void CacheMissionInfo() {
	g_bMissionCached = false;
	PrintToServer("[A2S_Edit] MissionInfo Cacheing...");
	g_smMissionMap.Clear();
	char key[64], mission[64], map[128];
	int i = 1;
	bool have = true;

	SourceKeyValues kvMissions = SDKCall(g_hSDK_GetAllMissions, g_pMatchExtL4D);
	for (SourceKeyValues kvSub = kvMissions.GetFirstTrueSubKey(); !kvSub.IsNull(); kvSub = kvSub.GetNextTrueSubKey()) {
		i = 1;
		have = true;
		do {
			FormatEx(key, sizeof(key), "modes/%s/%d/Map", g_cMode, i);
			SourceKeyValues kvMap = kvSub.FindKey(key);
			if (kvMap.IsNull()) {
				have = false;
			} else {
				kvSub.GetName(mission, sizeof(mission)); // ex. L4D2C1
				kvMap.GetString(NULL_STRING, map, sizeof(map)); // ex. c1m1_hotel
				g_smMissionMap.SetString(map, mission); // ex. c1m1_hotel => L4D2C1
				#if DEBUG
					PrintToServer("[A2S_Edit] %s => %s", map, mission);
				#endif
				++i;
			}
		} while (have);
	}
	PrintToServer("[A2S_Edit] MissionInfo Cached...");
	g_bMissionCached = true;
}

// 初始化游戏签名/偏移/所需内容等
void InitGameData() {
	char sPath[PLATFORM_MAX_PATH];
	Format(g_cMapName, sizeof(g_cMapName), "服务器初始化中");

	// 检查签名文件
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if (!FileExists(sPath))
		SetFailState("[A2S_EDIT] Missing required file: \"%s\" .", sPath);
	GameData hGameData = new GameData(GAMEDATA);
	if (!hGameData)
		SetFailState("[A2S_EDIT] Failed to load \"%s.txt\" gamedata.", GAMEDATA);
	
	/* ----------------------------- SDKCall相关 ----------------------------- */
	g_pDirector = hGameData.GetAddress("CDirector");
	if (!g_pDirector)
		SetFailState("[A2S_EDIT] Failed to find address: \"CDirector\"");

	g_pMatchExtL4D = hGameData.GetAddress("g_pMatchExtL4D");
	if (!g_pMatchExtL4D)
		SetFailState("[A2S_EDIT] Failed to find address: \"g_pMatchExtL4D\"");

	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetVirtual(0);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	if (!(g_hSDK_GetAllMissions = EndPrepSDKCall()))
		SetFailState("[A2S_EDIT] Failed to create SDKCall: \"MatchExtL4D::GetAllMissions\"");

	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "GetSteam3Server");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	if (!(g_hSDK_GetSteam3Server = EndPrepSDKCall()))
		SetFailState("[A2S_EDIT] Failed to create SDKCall: \"GetSteamServer\"");

	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "SendUpdatedServerDetails");
	if (!(g_hSDK_SendServerInfo = EndPrepSDKCall()))
		SetFailState("[A2S_EDIT] Failed to create SDKCall: \"SendServerInfo\"");


	/* ----------------------------- 内存修补相关 ----------------------------- */
	// A2S_INFO 的地图名
	g_iMapNameOS = hGameData.GetOffset("OS") ? 4 : 1;
	g_mMapNamePatch = MemoryPatch.CreateFromConf(hGameData, "RebuildInfo_MapName");
	if (!g_mMapNamePatch.Validate())
		SetFailState("[A2S_EDIT] Failed to verify patch: \"RebuildInfo_MapName\"");
	else if (g_mMapNamePatch.Enable()) {
		StoreToAddress(g_mMapNamePatch.Address + view_as<Address>(g_iMapNameOS), view_as<int>(GetAddressOfString(g_cMapName)), NumberType_Int32);
		PrintToServer("[A2S_EDIT] Enabled patch: \"RebuildInfo_MapName\"");
		//g_bMapNamePatchEnable = true;
	}

	delete hGameData;
	/* ----------------------------- 不需要生成翻译的地图 ----------------------------- */
	g_smExclude = new StringMap();
	g_smExclude.SetValue("credits", 1);
	g_smExclude.SetValue("HoldoutChallenge", 1);
	g_smExclude.SetValue("HoldoutTraining", 1);
	g_smExclude.SetValue("parishdash", 1);
	g_smExclude.SetValue("shootzones", 1);
}

// 初始化插件的Kv文件
bool InitKvFile() {
	char kvPath[PLATFORM_MAX_PATH];
	KeyValues kv;
	File file;
	BuildPath(Path_SM, kvPath, sizeof(kvPath), "data/%s", A2S_SETTING);

	// 文件不存在则创建
	kv = new KeyValues("a2s_edit");
	if (!FileExists(kvPath)) {
		file = OpenFile(kvPath, "w");
		// 无法打开文件
		if (!file) {
			LogError("Cannot open file: \"%s\"", kvPath);
			return false;
		}
		// 无法写入行
		if (!file.WriteLine("")) {
			LogError("Cannot write file line: \"%s\"", kvPath);
			delete file;
			return false;
		}
		delete file;

		// 写出默认值内容
		kv.SetString("inFinale", "救援正进行");
		kv.SetString("notInFinale", "救援未进行");

		// 返回树顶部
		kv.Rewind();
		// 从当前树位置导出内容到文件
		kv.ExportToFile(kvPath);
	} else if (!kv.ImportFromFile(kvPath)) {
		return false;
	}

	// 获取Kv文本内信息写入变量中
	kv.GetString("inFinale", g_cInFinale, sizeof(g_cInFinale), "救援正进行");
	kv.GetString("notInFinale", g_cNotInFinale, sizeof(g_cNotInFinale), "救援未进行");

	delete kv;
	return true;
}

// 地图是否存在
stock bool IsMapValidEx(const char[] map) {
	if (!map[0])
		return false;

	char foundmap[1];
	return FindMap(map, foundmap, sizeof foundmap) == FindMap_Found;
}

// 获取本地化后文本
void fmt_Translate(const char[] phrase, char[] buffer, int maxlength, int client, const char[] defvalue="") {
	if (!TranslationPhraseExists(phrase))
		strcopy(buffer, maxlength, defvalue);
	else
		Format(buffer, maxlength, "%T", phrase, client);
}

// 进行地图信息本地化(官方图为多语言)
void OnPhrasesReady() {
	g_bLocInit = false;
	PrintToServer("[A2S_Edit] Localizer Init...");

	#if BENCHMARK
		g_profiler = new Profiler();
		g_profiler.Start();
	#endif

	esPhrase esp;
	ArrayList al_missions = new ArrayList(sizeof esPhrase);
	ArrayList al_chapters = new ArrayList(sizeof esPhrase);

	int value;
	char phrase[64];
	char translation[64];
	// 获取全部地图信息
	SourceKeyValues kvModes;
	SourceKeyValues kvChapters;
	SourceKeyValues kvMissions = SDKCall(g_hSDK_GetAllMissions, g_pMatchExtL4D);
	// 循环读取map信息
	for (kvMissions = kvMissions.GetFirstTrueSubKey(); !kvMissions.IsNull(); kvMissions = kvMissions.GetNextTrueSubKey()) {
		// 获取地图的任务名称
		kvMissions.GetName(phrase, sizeof(phrase));

		// 在不需要生成翻译的地图列表里的跳过
		if (g_smExclude.GetValue(phrase, value))
			continue;

		// 在当前模式下没地图的跳过
		kvModes = kvMissions.FindKey("modes");
		if (kvModes.IsNull())
			continue;

		// 如果为官方地图DLC地图? (C1-C6都不存在此key,DLC1后的地图皆有)
		value = kvMissions.GetInt("builtin");
		// 任务名数组里找不到的话,则获取名字和信息推入数组
		if (al_missions.FindString(phrase) == -1) {
			kvMissions.GetString("DisplayTitle", translation, sizeof(translation), "N/A");
			strcopy(esp.key, sizeof(esp.key), phrase);
			strcopy(esp.val, sizeof(esp.val), !strcmp(translation, "N/A") ? phrase : translation);
			esp.official = value;
			al_missions.PushArray(esp);
		}

		// 获取任务文件里的全部章节的地图信息(地图文件名/地图的名称)
		for (kvModes = kvModes.GetFirstTrueSubKey(); !kvModes.IsNull(); kvModes = kvModes.GetNextTrueSubKey()) {
			for (kvChapters = kvModes.GetFirstTrueSubKey(); !kvChapters.IsNull(); kvChapters = kvChapters.GetNextTrueSubKey()) {
				// 获取地图章节文件名
				kvChapters.GetString("Map", phrase, sizeof(phrase), "N/A");
				if (!strcmp(phrase, "N/A") || FindCharInString(phrase, '/') != -1)
					continue;
				// 获取地图章节描述
				if (al_chapters.FindString(phrase) == -1) {
					kvChapters.GetString("DisplayName", translation, sizeof(translation), "N/A");
					strcopy(esp.key, sizeof(esp.key), phrase);
					strcopy(esp.val, sizeof(esp.val), !strcmp(translation, "N/A") ? phrase : translation);
					esp.official = value;
					al_chapters.PushArray(esp);
				}
			}
		}
	}

	char FilePath[PLATFORM_MAX_PATH];
	// 写出任务信息到文件
	BuildPhrasePath(FilePath, sizeof(FilePath), TRANSLATION_MISSIONS, "en");
	BuildPhraseFile(FilePath, al_missions, esp);

	// 写出章节信息到文件
	BuildPhrasePath(FilePath, sizeof(FilePath), TRANSLATION_CHAPTERS, "en");
	BuildPhraseFile(FilePath, al_chapters, esp);

	loc.Close();
	delete al_missions;
	delete al_chapters;

	value = 0;
	// 把翻译内容写出文本(写入到en里,由于服务器自身使用文本为SM的Core.cfg里控制,默认这里使用上方Cvar里定义的翻译覆盖en)
	BuildPhrasePath(FilePath, sizeof(FilePath), TRANSLATION_MISSIONS, "en");
	if (FileExists(FilePath)) {
		value = 1;
		LoadTranslations("a2s_missions.phrases");
	}

	BuildPhrasePath(FilePath, sizeof(FilePath), TRANSLATION_CHAPTERS, "en");
	if (FileExists(FilePath)) {
		value = 1;
		LoadTranslations("a2s_chapters.phrases");
	}
	// 读取完毕后重载翻译数据
	if (value) {
		InsertServerCommand("sm_reload_translations");
		ServerExecute();
	}

	#if BENCHMARK
		g_profiler.Stop();
		LogError("Export Phrases Time: %f", g_profiler.Time);
	#endif

	g_bLocInit = true;
	PrintToServer("[A2S_Edit] Localizer Init Complete...");
}

// 根据地图信息生成翻译文件
void BuildPhraseFile(char[] FilePath, ArrayList array, esPhrase esp) {
	int x;
	File file;
	KeyValues kv;
	char buffer[64];
	int len = array.Length;

	// 生成kv文件且定义头
	kv = new KeyValues("Phrases");
	// 文件不存在
	if (!FileExists(FilePath)) {
		file = OpenFile(FilePath, "w");
		// 无法打开文件
		if (!file) {
			LogError("Cannot open file: \"%s\"", FilePath);
			return;
		}
		// 无法写入行
		if (!file.WriteLine("")) {
			LogError("Cannot write file line: \"%s\"", FilePath);
			delete file;
			return;
		}

		delete file;

		// 根据数组长度遍历
		for (x = 0; x < len; x++) {
			// 获取数组指定位置的内容
			array.GetArray(x, esp);
			// 移动到此名的节点上,不存在则新建
			if (kv.JumpToKey(esp.key, true)) {
				// 非官方图,直接写入文本
				if (!esp.official)
					kv.SetString("en", esp.val);
				else {
					// 获取本地化文本写入
					loc.PhraseTranslateToLang(esp.val, buffer, sizeof(buffer), _, _, g_cLanguage, esp.val);
					kv.SetString("en", buffer);
				}
				// 返回树顶部
				kv.Rewind();
				// 写入内容到文件
				kv.ExportToFile(FilePath);
			}
		}
	}
	// 文件存在则加载原有文件
	else if(kv.ImportFromFile(FilePath)) {
		for (x = 0; x < len; x++) {
			array.GetArray(x, esp);
			// 移动到此名的节点上,不存在则新建
			if (kv.JumpToKey(esp.key, true)) {
				// 此节点上的en不存在
				if (!kv.JumpToKey("en")) {
					// 非官方图,直接写入文本
					if (!esp.official)
						kv.SetString("en", esp.val);
					else {
						// 获取本地化文本写入
						loc.PhraseTranslateToLang(esp.val, buffer, sizeof(buffer), _, _, g_cLanguage, esp.val);
						kv.SetString("en", buffer);
					}
					// 返回树顶部
					kv.Rewind();
					// 写入内容到文件
					kv.ExportToFile(FilePath);
				}
			}
			// 返回树顶部
			kv.Rewind();
		}
	}
	delete kv;
}

// 根据语言代码获取对应保存的位置
void BuildPhrasePath(char[] buffer, int maxlength, const char[] fliename, const char[] lang_code) {
	strcopy(buffer, maxlength, "translations/");

	int len;
	if (strcmp(lang_code, "en")) {
		len = strlen(buffer);
		FormatEx(buffer[len], maxlength - len, "%s/", lang_code);
	}

	len = strlen(buffer);
	FormatEx(buffer[len], maxlength - len, "%s", fliename);
	BuildPath(Path_SM, buffer, maxlength, "%s", buffer);
}