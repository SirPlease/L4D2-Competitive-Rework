#pragma semicolon 1
//強制1.7以後的新語法
#pragma newdecls required
#include <sourcemod>
#include <dhooks>
#include <l4d2_ems_hud>

#define CVAR_FLAGS		FCVAR_NOTIFY
#define PLUGIN_VERSION	"2.4.4"

#define	SurvivorsState		(1 << 0)
#define SurvivorsKill		(1 << 1)
#define SurvivorsHead		(1 << 2)
#define SurvivorsHealth		(1 << 3)
#define SurvivorsDmgHp		(1 << 4)
#define SurvivorsName		(1 << 5)

//设置数组数量(最大值:9).
#define Array	9
//设置数组数量(最大值:5).
#define Amount	5

bool  g_bMapRunTime, g_bShowHUD, g_bDmgHealth;
float g_fMapRunTime;
float iCoord[] = {0.00, 0.055, 0.110, 0.160, 0.215, 0.265};

int    g_iDeathTime, g_iPlayerNum, g_iChapterTotal[2], g_iCumulativeTotal[2], g_iKillSpecial[MAXPLAYERS+1], g_iHeadSpecial[MAXPLAYERS+1], g_iDmgHealth[MAXPLAYERS+1];

int    g_iSurvivorHealth, g_iMaxReviveCount, g_iPlayersNumber, g_iShowServerName, g_iShowServerNumber, g_iShowRunningTime, g_iShowServerTime, g_iShowKillNumber, g_iFakeRanking, g_iHurtRanking, g_iDeathFake, g_iReportLine, g_iReportTime, g_iTypeRanking, g_iInfoRanking;
ConVar g_hSurvivorHealth, g_hMaxReviveCount, g_hPlayersNumber, g_hShowServerName, g_hShowServerNumber, g_hShowRunningTime, g_hShowServerTime, g_hShowKillNumber, g_hFakeRanking, g_hHurtRanking, g_hDeathFake, g_hReportLine, g_hReportTime, g_hTypeRanking, g_hInfoRanking, g_hHostName;

char g_sTemp[Amount - 1][128], g_sDeathKill[Amount][128], g_sDeathInfo[256];
char sDate[][] = {"天", "时", "分", "秒"};
char g_sTitle[][] = {"状态", "血量", "击杀", "爆头", "友伤", "名字"};//这里不要改变长度,否则自动对齐可能怪怪的.
char g_sWeekName[][] = {"一", "二", "三", "四", "五", "六", "日"};
char g_sZombieName[][] = {"舌头","胖子","猎人","口水","猴子","牛牛","女巫","坦克"};

Handle g_hTimerHUD, g_hTimerCSKill;

public Plugin myinfo = 
{
	name 			= "l4d2_emshud_info",
	author 			= "豆瓣酱な | HUD的include提供者:sorallll",
	description 	= "HUD显示各种信息.",
	version 		= PLUGIN_VERSION,
	url 			= "N/A"
}

public void OnPluginStart()
{
	LoadGameCFG();
	
	HookEvent("round_end",		Event_RoundEnd);	//回合结束.
	HookEvent("round_start",	Event_RoundStart);	//回合开始.
	HookEvent("player_hurt",	Event_PlayerHurt);	//玩家受伤.
	HookEvent("player_death",	Event_PlayerDeath);	//玩家死亡.
	
	g_hHostName			= FindConVar("hostname");
	g_hSurvivorHealth	= FindConVar("survivor_limp_health");
	g_hMaxReviveCount	= FindConVar("survivor_max_incapacitated_count");

	g_hPlayersNumber	= CreateConVar("l4d2_emshud_show_players_number", "1", "显示玩家数量信息. 0=禁用, 1=显示.", CVAR_FLAGS);
	g_hShowServerName	= CreateConVar("l4d2_emshud_show_server_name", "1", "显示服务器名称. 0=禁用, 1=显示.", CVAR_FLAGS);
	g_hShowServerNumber	= CreateConVar("l4d2_emshud_show_server_name", "1", "显示服务器人数. 0=禁用, 1=显示.", CVAR_FLAGS);
	g_hShowRunningTime	= CreateConVar("l4d2_emshud_show_running_time", "1", "显示运行的时间. 0=禁用, 1=显示.", CVAR_FLAGS);
	g_hShowServerTime	= CreateConVar("l4d2_emshud_show_server_time", "1", "显示服务器时间. 0=禁用, 1=显示.", CVAR_FLAGS);
	g_hShowKillNumber	= CreateConVar("l4d2_emshud_show_kill_number", "1", "显示击杀总数量. 0=禁用, 1=显示.", CVAR_FLAGS);
	g_hFakeRanking		= CreateConVar("l4d2_emshud_ranking_Fake", "0", "排行榜显示电脑幸存者? 0=显示, 1=忽略.", CVAR_FLAGS);
	g_hInfoRanking		= CreateConVar("l4d2_emshud_ranking_Info", "8", "排行榜总共显示多少行(最多8行). 0=禁用.", CVAR_FLAGS);
	g_hTypeRanking		= CreateConVar("l4d2_emshud_ranking_Type", "63", "排行榜显示那些内容? (把需要启用的功能数字相加) 0=禁用, 1=状态, 2=血量, 4=击杀, 8=爆头, 16=友伤, 32=名字.", CVAR_FLAGS);
	g_hHurtRanking		= CreateConVar("l4d2_emshud_ranking_hurt", "1", "排行榜显示友伤的方式? 1=自动, 2=显示.", CVAR_FLAGS);
	g_hDeathFake		= CreateConVar("l4d2_emshud_death_Fake", "0", "击杀播报显示电脑幸存者? 0=显示, 1=忽略.", CVAR_FLAGS);
	g_hReportLine		= CreateConVar("l4d2_emshud_death_report_line", "5", "设置仿CS的击杀播报显示多少行. 0=禁用(最多5行).", CVAR_FLAGS);
	g_hReportTime		= CreateConVar("l4d2_emshud_death_report_time", "10", "设置多少秒后删除击杀播报首行(最低5秒).", CVAR_FLAGS);
	
	g_hSurvivorHealth.AddChangeHook(ConVarChanged);
	g_hMaxReviveCount.AddChangeHook(ConVarChanged);
	g_hPlayersNumber.AddChangeHook(ConVarChanged);
	g_hShowServerName.AddChangeHook(ConVarChanged);
	g_hShowServerNumber.AddChangeHook(ConVarChanged);
	g_hShowRunningTime.AddChangeHook(ConVarChanged);
	g_hShowServerTime.AddChangeHook(ConVarChanged);
	g_hShowKillNumber.AddChangeHook(ConVarChanged);
	g_hFakeRanking.AddChangeHook(ConVarChanged);
	g_hInfoRanking.AddChangeHook(ConVarChanged);
	g_hTypeRanking.AddChangeHook(ConVarChanged);
	g_hHurtRanking.AddChangeHook(ConVarChanged);
	g_hDeathFake.AddChangeHook(ConVarChanged);
	g_hReportLine.AddChangeHook(ConVarChanged);
	g_hReportTime.AddChangeHook(ConVarChanged);
	
	AutoExecConfig(true, "l4d2_emshud_info");//生成指定文件名的CFG.
}

/* https://github.com/lakwsh */
void LoadGameCFG()
{
	GameData hGameData = new GameData("l4d2_emshud_info");
	if(!hGameData) 
		SetFailState("Failed to load 'l4d2_emshud_info.txt' gamedata.");
	DHookSetup hDetour = DHookCreateFromConf(hGameData, "HibernationUpdate");
	CloseHandle(hGameData);
	if(!hDetour || !DHookEnableDetour(hDetour, true, OnHibernationUpdate)) 
		SetFailState("Failed to hook HibernationUpdate");
}

//服务器里没人后触发一次.
public MRESReturn OnHibernationUpdate(DHookParam hParams)
{
	bool hibernating = DHookGetParam(hParams, 1);

	if(!hibernating) 
		return MRES_Ignored;
		
	g_bMapRunTime = false;
	return MRES_Handled;
}

public void OnConfigsExecuted()
{
	if (g_bMapRunTime == false)
	{
		g_bMapRunTime = true;
		g_fMapRunTime = GetEngineTime();
	}
}

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_iSurvivorHealth	= g_hSurvivorHealth.IntValue;
	g_iMaxReviveCount	= g_hMaxReviveCount.IntValue;
	g_iPlayersNumber	= g_hPlayersNumber.IntValue;
	g_iShowServerName	= g_hShowServerName.IntValue;
	g_iShowServerNumber	= g_hShowServerNumber.IntValue;
	g_iShowRunningTime	= g_hShowRunningTime.IntValue;
	g_iShowServerTime	= g_hShowServerTime.IntValue;
	g_iShowKillNumber	= g_hShowKillNumber.IntValue;
	g_iFakeRanking		= g_hFakeRanking.IntValue;
	g_iInfoRanking		= g_hInfoRanking.IntValue;
	g_iTypeRanking		= g_hTypeRanking.IntValue;
	g_iHurtRanking		= g_hHurtRanking.IntValue;
	g_iDeathFake		= g_hDeathFake.IntValue;
	g_iReportLine		= g_hReportLine.IntValue;
	g_iReportTime		= g_hReportTime.IntValue;
	
	if( g_iReportTime < 5)
		g_iReportTime = 5;
	if( g_iReportLine > Amount)
		g_iReportLine = Amount;
	if( g_iInfoRanking > Array - 1)
		g_iInfoRanking = Array - 1;
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int iDmg = event.GetInt("dmg_health");
	//int health = event.GetInt("health");
	
	if(IsValidClient(client) && GetClientTeam(client) == 2)
	{
		if(IsValidClient(attacker) && GetClientTeam(attacker) == 2)
		{
			int iBot = IsClientIdle(attacker);

			if(iBot != 0)
			{
				if(IsValidClient(iBot))
					g_iDmgHealth[iBot] += iDmg;
			}
			else
				g_iDmgHealth[attacker] += iDmg;
		}
	}
}

//玩家死亡.
public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int iHeadshot = GetEventInt(event, "headshot");

	if(IsValidClient(attacker))
	{
		switch (GetClientTeam(attacker))
		{
			case 2:
			{
				char classname[32];
				int entity = GetEventInt(event, "entityid");
				GetEdictClassname(entity, classname, sizeof(classname));
				if (IsValidEdict(entity) && strcmp(classname, "infected") == 0)
				{
					g_iChapterTotal[0] += 1;
					g_iCumulativeTotal[0] += 1;
				}
				if(IsValidClient(client) && GetClientTeam(client) == 3)
				{
					g_iChapterTotal[1] += 1;
					g_iCumulativeTotal[1] += 1;
					int iBot = IsClientIdle(attacker);
			
					if(iHeadshot)
						g_iHeadSpecial[iBot != 0 ? iBot : attacker] += 1;
					g_iKillSpecial[iBot != 0 ? iBot : attacker] += 1;
					
					if (g_iReportLine <= 0 || g_iDeathFake != 0 && IsFakeClient(iBot != 0 ? iBot : attacker))//这里判断玩家是否在游戏中或是否显示电脑幸存者.
						return;

					IsImitationCSKillTip(client, attacker, iHeadshot ? "★" : "☆");
				}
			}
			case 3:
			{
				if(IsValidClient(client) && GetClientTeam(client) == 2)
				{
					int iBot = IsClientIdle(attacker);
					
					if (g_iReportLine <= 0 || g_iDeathFake != 0 && IsFakeClient(iBot != 0 ? iBot : attacker))//这里判断玩家是否在游戏中或是否显示电脑幸存者.
						return;
					
					IsImitationCSKillTip(client, attacker, "☆");
				}
			}
		}
	}
}

void IsDisplayTimeOut()
{
	delete g_hTimerCSKill;
	g_hTimerCSKill = CreateTimer(1.0, IsTimerImitationCSKillTip, _, TIMER_REPEAT);
}

public Action IsTimerImitationCSKillTip(Handle timer)
{
	int g_iDeathKill = GetStringContent();

	if(g_iDeathKill > 0)
	{
		if(g_iDeathTime < g_iReportTime)
		{
			g_iDeathTime += 1;
			return Plugin_Continue;
		}
		IsReorderDeath(g_iDeathKill >= g_iReportLine ? g_iReportLine - 1 : g_iDeathKill);
		g_sDeathKill[g_iDeathKill - 1][0] = '\0';
		ImplodeStrings(g_sDeathKill, sizeof(g_sDeathKill), "\n", g_sDeathInfo, sizeof(g_sDeathInfo));//打包字符串.
	}
	g_iDeathTime = 0;
	return Plugin_Continue;
}

//仿CS击杀提示.
void IsImitationCSKillTip(int client, int victim, char[] type)
{
	int g_iDeathKill = GetStringContent();
	if(g_iDeathKill >= g_iReportLine)
		IsReorderDeath(g_iReportLine - 1);
	
	FormatEx(g_sDeathKill[g_iDeathKill >= g_iReportLine ? g_iReportLine - 1 : g_iDeathKill], sizeof(g_sDeathKill[]), "%s%s%s", GetPlayerName(victim), type, GetPlayerName(client));
	ImplodeStrings(g_sDeathKill, sizeof(g_sDeathKill), "\n", g_sDeathInfo, sizeof(g_sDeathInfo));//打包字符串.
}

void IsReorderDeath(int iCycle)
{
	for (int i = 0; i < iCycle; i++)
		strcopy(g_sTemp[i], sizeof(g_sTemp[]), g_sDeathKill[i + 1]);
	for (int i = 0; i < iCycle; i++)
		strcopy(g_sDeathKill[i], sizeof(g_sDeathKill[]), g_sTemp[i]);
}

int GetStringContent()
{
	for (int i = 0; i < g_iReportLine; i++)
		if(g_sDeathKill[i][0] == '\0')
			return i;//break;
		
	return g_iReportLine;
}

char[] GetPlayerName(int client)
{
	char g_sName[16];//因为字符限制,显示5行只能限制到16个字符.
	switch (GetClientTeam(client))
	{
		case 2:
		{
			int iBot = IsClientIdle(client);

			if(iBot != 0)
				FormatEx(g_sName, sizeof(g_sName), "%N", iBot);
			else
				GetClientName(client, g_sName, sizeof(g_sName));
		}
		case 3:
			strcopy(g_sName, sizeof(g_sName), g_sZombieName[GetEntProp(client, Prop_Send, "m_zombieClass") - 1]);
	}
	return g_sName;
}

//玩家连接
public void OnClientConnected(int client)
{   
	g_iKillSpecial[client] = 0;
	g_iHeadSpecial[client] = 0;

	if (!IsFakeClient(client))
		g_iPlayerNum += 1;
}

//玩家离开.
public void OnClientDisconnect(int client)
{   
	g_iKillSpecial[client] = 0;
	g_iHeadSpecial[client] = 0;

	if (!IsFakeClient(client))
		g_iPlayerNum -= 1;
}

//地图开始
public void OnMapStart()
{
	GetCvars();
	EnableHUD();
	g_iPlayerNum = 0;
}

//回合开始.
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bShowHUD = false;
	//重置字符串.
	IsResetString();
	//创建计时器.
	IsDisplayTimeOut();
	//创建计时器显示HUD.
	IsCreateTimerShowHUD();
	//重置章节击杀特感和丧尸数量.
	for (int i = 0; i < sizeof(g_iChapterTotal); i++)
		g_iChapterTotal[i] = 0;//重置章节击杀特感和丧尸数量.
	
	//重置玩家友伤,击杀特感和丧尸数量.
	for (int i = 1; i <= MaxClients; i++)
	{
		g_iDmgHealth[i] = 0;
		g_iKillSpecial[i] = 0;
		g_iHeadSpecial[i] = 0;
	}
}

//回合结束.
public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_bShowHUD = true;
	//重置字符串.
	IsResetString();
	//清除击杀HUD.
	IsRemoveHUD();
	delete g_hTimerCSKill;
}

//重置字符串.
void IsResetString()
{
	for (int i = 0; i < sizeof(g_sDeathKill); i++)
		g_sDeathKill[i][0] = '\0';
	g_sDeathInfo[0] = '\0';
}

//创建计时器.
void IsCreateTimerShowHUD()
{
	if(g_hTimerHUD == null)//不存在计时器才创建.
		g_hTimerHUD = CreateTimer(1.0, DisplayInfo, _, TIMER_REPEAT);
}

public Action DisplayInfo(Handle timer)
{
	//清除击杀HUD.
	IsRemoveHUD();
	//显示所有HUD.
	IsShowAllHUD();
	return Plugin_Continue;
}

//清除指定HUD.
void IsRemoveHUD()
{
	//删除仿CS击杀提示HUD.
	if(g_iReportLine <= 0)
		if(HUDSlotIsUsed(HUD_FAR_LEFT))
			RemoveHUD(HUD_FAR_LEFT);
	
	//删除人数运行HUD.
	if(g_iShowServerNumber <= 0)
		if(HUDSlotIsUsed(HUD_SCORE_1))
			RemoveHUD(HUD_SCORE_1);
	
	//删除击杀数量HUD.
	if(g_iShowKillNumber <= 0)
		if(HUDSlotIsUsed(HUD_MID_BOX))
			RemoveHUD(HUD_MID_BOX);
	
	//删除累计数量HUD.
	if(g_iShowKillNumber <= 0)
		if(HUDSlotIsUsed(HUD_FAR_RIGHT))
			RemoveHUD(HUD_FAR_RIGHT);

	//删除运行时间HUD.
	if(g_iShowRunningTime <= 0)
		if(HUDSlotIsUsed(HUD_SCORE_TITLE))
			RemoveHUD(HUD_SCORE_TITLE);
	
	//删除当前时间HUD.
	if(g_iShowServerTime <= 0)
		if(HUDSlotIsUsed(HUD_MID_TOP))
			RemoveHUD(HUD_MID_TOP);

	//删除玩家数量HUD.
	if(g_iPlayersNumber <= 0)
		if(HUDSlotIsUsed(HUD_SCORE_4))
			RemoveHUD(HUD_SCORE_4);
	
	//删除服名HUD.
	if(g_iShowServerName <= 0)
		if(HUDSlotIsUsed(HUD_LEFT_TOP))
			RemoveHUD(HUD_LEFT_TOP);
	
	/* 以下是排行榜相关HUD. */
	//删除玩家状态HUD.
	if(HUDSlotIsUsed(HUD_LEFT_BOT))
		RemoveHUD(HUD_LEFT_BOT);
	
	//删除击杀数量HUD.
	if(HUDSlotIsUsed(HUD_MID_BOT))
		RemoveHUD(HUD_MID_BOT);

	//删除爆头数量HUD.
	if(HUDSlotIsUsed(HUD_RIGHT_TOP))
		RemoveHUD(HUD_RIGHT_TOP);

	//删除玩家血量HUD.
	if(HUDSlotIsUsed(HUD_SCORE_3))
		RemoveHUD(HUD_SCORE_3);

	//删除友伤统计HUD.
	if(HUDSlotIsUsed(HUD_SCORE_2))
		RemoveHUD(HUD_SCORE_2);
		
	//删除玩家名字HUD.
	if(HUDSlotIsUsed(HUD_RIGHT_BOT))
		RemoveHUD(HUD_RIGHT_BOT);
}

//显示指定HUD.
void IsShowAllHUD()
{
	//显示仿CS击杀提示.
	if(g_iReportLine > 0)
		IsDeathMessage();
	//显示服务器时间.
	if(g_iShowServerTime > 0)
		IsShowServerTime();
	//显示运行的时间.
	if(g_iShowRunningTime > 0)
		IsShowRunningTime();
	//显示累计击杀数.
	if(g_iShowKillNumber > 0)
		IsCumulativeStatistics();
	//显示连接,闲置,旁观,特感和幸存者数量.
	if(g_iPlayersNumber > 0)
		IsPlayersNumber();
	//显示服务器名字.
	if(g_iShowServerName > 0)
		IsShowServerName();
	//显示服务器人数.
	if(g_iShowServerNumber > 0)
		IsShowServersNumber();
	//显示击杀特感排行榜.
	if(g_iInfoRanking > 0)
		IsKillLeaderboards();
}

//显示仿CS击杀提示.
void IsDeathMessage()
{
	HUDSetLayout(HUD_FAR_LEFT, HUD_FLAG_ALIGN_RIGHT|HUD_FLAG_NOBG|HUD_FLAG_TEXT, g_sDeathInfo);
	HUDPlace(HUD_FAR_LEFT,0.00,0.15,1.0,0.20);
}

//显示服务器名字.
void IsShowServerName()
{
	HUDSetLayout(HUD_LEFT_TOP, HUD_FLAG_ALIGN_CENTER|HUD_FLAG_NOBG|HUD_FLAG_TEXT|HUD_FLAG_BLINK, GetHostName());
	HUDPlace(HUD_LEFT_TOP, 0.00,0.03, 1.0,0.03);
}

//显示当前和总人数.
void IsShowServersNumber()
{
	char g_sTotal[256];
	FormatEx(g_sTotal, sizeof(g_sTotal), "(%d/%d)", g_iPlayerNum, GetMaxPlayers());
	HUDSetLayout(HUD_SCORE_1, HUD_FLAG_ALIGN_CENTER|HUD_FLAG_NOBG|HUD_FLAG_TEXT, g_sTotal);
	HUDPlace(HUD_SCORE_1,0.00,0.00,1.0,0.03);
}

//显示击杀特感排行榜.
void IsKillLeaderboards()
{
	if (g_bShowHUD || g_iTypeRanking == 0 || GetPlayersMaxNumber(2, false) <= 0)//没有幸存者或禁用时直接返回，不执行后面的操作.
		return;
	
	int temp[4], iMax[4], ranking_count = 1, assister_count, iHudCoord;
	int[][] assisters = new int[MaxClients][5];//更改为动态大小的数组.
	
	char g_sData[6][Array][128], g_sInfo[6][256];
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			int iBot = IsClientIdle(i);

			if (iBot != 0 && IsClientConnected(i) && !IsClientInGame(iBot) || g_iFakeRanking != 0 && IsFakeClient(iBot == 0 ? i : iBot))//这里判断玩家是否在游戏中或是否显示电脑幸存者.
				continue;

			assisters[assister_count][0] = !iBot ? i : iBot;
			assisters[assister_count][1] = GetSurvivorHP(i);
			assisters[assister_count][2] = g_iKillSpecial[!iBot ? i : iBot];
			assisters[assister_count][3] = g_iHeadSpecial[!iBot ? i : iBot];
			assisters[assister_count][4] = g_iDmgHealth[!iBot ? i : iBot] > 9999 ? 9999 : g_iDmgHealth[!iBot ? i : iBot];
			assister_count+=1;
		}
	}
	
	//以最大击杀数排序.
	SortCustom2D(assisters, assister_count, ClientValue2DSortDesc);

	for (int z = 0; z < sizeof(g_sData); z++)
		strcopy(g_sData[z][0], sizeof(g_sData[][]), g_sTitle[z]);
	
	for (int x = 0; x < g_iInfoRanking; x++)
	{
		int j = x + 1;
		int client	= assisters[x][0];
		int iHealth	= assisters[x][1];
		int iKill	= assisters[x][2];
		int iHead	= assisters[x][3];
		int iDmg	= assisters[x][4];
		
		if (IsValidClient(client))//因为要显示闲置玩家的数据,所以这里不要判断团队.
		{
			int Player = iGetBotOfIdlePlayer(client);
			strcopy(g_sData[0][j], sizeof(g_sData[][]), GetSurvivorStatus(Player != 0 ? Player : client));
			IntToString(iHealth,  g_sData[1][j], sizeof(g_sData[][]));
			IntToString(iKill, g_sData[2][j], sizeof(g_sData[][]));
			IntToString(iHead, g_sData[3][j], sizeof(g_sData[][]));
			IntToString(iDmg,  g_sData[4][j], sizeof(g_sData[][]));
			strcopy(g_sData[5][j], sizeof(g_sData[][]), GetTrueName(Player != 0 ? Player : client));
			ranking_count += 1;
		}
	}
	for (int k = 1; k < 4; k++)
		temp[k] = strlen(g_sData[k + 1][1]);

	for (int j = 1; j < ranking_count; j++)
		for (int y = 0; y < 4; y++)
			if(strlen(g_sData[y + 1][j]) > temp[y])
				temp[y] = strlen(g_sData[y + 1][j]);
	
	//这里必须重新循环,不然数字不能对齐.
	for (int y = 1; y < ranking_count; y++)
	{
		for (int h = 0; h < 4; h++)
		{
			iMax[h] = temp[h] - strlen(g_sData[h + 1][y]);

			if(iMax[h] > 0)
				Format(g_sData[h + 1][y], sizeof(g_sData[][]), "%s%s", GetAddSpacesMax(iMax[h], " "),  g_sData[h + 1][y]);//这里不能使用FormatEx
		}
	}
	
	//这里判断是否显示友伤.
	g_bDmgHealth = false;

	switch (g_iHurtRanking)
	{
		case 1:
		{
			for (int p = 1; p < ranking_count; p++)
				if (StringToInt(g_sData[4][p]) > 0)
				{
					g_bDmgHealth = true;
					break;
				}
		}
		case 2:
			g_bDmgHealth = true;
	}

	for (int y = 0; y < sizeof(g_sData); y++)
		ImplodeStrings(g_sData[y], sizeof(g_sData[]), "\n", g_sInfo[y], sizeof(g_sInfo[]));//打包字符串.
	
	if(g_iTypeRanking & SurvivorsState)
	{
		HUDSetLayout(HUD_LEFT_BOT,HUD_FLAG_ALIGN_LEFT|HUD_FLAG_NOBG|HUD_FLAG_TEAM_SURVIVORS|HUD_FLAG_TEXT, g_sInfo[0]);
		HUDPlace(HUD_LEFT_BOT, iCoord[iHudCoord],0.03,1.0,0.35);
		iHudCoord += 1;
	}
	if(g_iTypeRanking & SurvivorsKill)
	{
		HUDSetLayout(HUD_MID_BOT,HUD_FLAG_ALIGN_LEFT|HUD_FLAG_NOBG|HUD_FLAG_TEAM_SURVIVORS|HUD_FLAG_TEXT, g_sInfo[1]);
		HUDPlace(HUD_MID_BOT, iCoord[iHudCoord],0.03,1.0,0.35);
		iHudCoord += 1;
	}
	if(g_iTypeRanking & SurvivorsHead)
	{
		HUDSetLayout(HUD_RIGHT_TOP,HUD_FLAG_ALIGN_LEFT|HUD_FLAG_NOBG|HUD_FLAG_TEAM_SURVIVORS|HUD_FLAG_TEXT, g_sInfo[2]);
		HUDPlace(HUD_RIGHT_TOP, iCoord[iHudCoord],0.03,1.0,0.35);
		iHudCoord += 1;
	}
	if ((g_iTypeRanking & SurvivorsHealth))
	{
		HUDSetLayout(HUD_SCORE_3,HUD_FLAG_ALIGN_LEFT|HUD_FLAG_NOBG|HUD_FLAG_TEAM_SURVIVORS|HUD_FLAG_TEXT, g_sInfo[3]);
		HUDPlace(HUD_SCORE_3, iCoord[iHudCoord],0.03,1.0,0.35);
		iHudCoord += 1;
	}
	if(g_iTypeRanking & SurvivorsDmgHp && g_bDmgHealth)
	{
		HUDSetLayout(HUD_SCORE_2,HUD_FLAG_ALIGN_LEFT|HUD_FLAG_NOBG|HUD_FLAG_TEAM_SURVIVORS|HUD_FLAG_TEXT, g_sInfo[4]);
		HUDPlace(HUD_SCORE_2, iCoord[iHudCoord],0.03,1.0,0.35);
		iHudCoord += 1;
	}
	if(g_iTypeRanking & SurvivorsName)
	{
		HUDSetLayout(HUD_RIGHT_BOT,HUD_FLAG_ALIGN_LEFT|HUD_FLAG_NOBG|HUD_FLAG_TEAM_SURVIVORS|HUD_FLAG_TEXT, g_sInfo[5]);
		HUDPlace(HUD_RIGHT_BOT, iCoord[iHudCoord],0.03,1.0,0.35);
		iHudCoord += 1;
	}
}

int ClientValue2DSortDesc(int[] elem1, int[] elem2, const int[][] array, Handle hndl)
{
	if (elem1[2] > elem2[2])
		return -1;
	else if (elem2[2] > elem1[2])
		return 1;
	return 0;
}
/*
//获取玩家状态.
int GetSurvivorsStatus()
{
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && !IsPlayerState(i))
			return 1;//有倒地的和挂边的生还者置顶显示.
	return 2;//以击杀数量排序.
}
*/
void IsPlayersNumber()
{
	char g_sLine[64];
	FormatEx(g_sLine, sizeof(g_sLine), "连接:%d 闲置:%d 旁观:%d 特感:%d/%d 幸存:%d/%d", 
	GetConnectionNumber(), GetPlayersStateNumber(1, true), GetPlayersStateNumber(1, false), GetPlayersMaxNumber(3, true), GetPlayersMaxNumber(3, false), GetPlayersMaxNumber(2, true), GetPlayersMaxNumber(2, false));
	HUDSetLayout(HUD_SCORE_4, HUD_FLAG_ALIGN_LEFT|HUD_FLAG_NOBG|HUD_FLAG_TEXT, g_sLine);
	HUDPlace(HUD_SCORE_4,0.00,0.00,1.0,0.03);
}

//显示服务器时间.
void IsShowServerTime()
{
	char g_sDate[64], g_sTime[128];
	FormatTime(g_sDate, sizeof(g_sDate), "%Y-%m-%d %H:%M:%S");
	FormatEx(g_sTime, sizeof(g_sTime), "%s 星期%s", g_sDate, IsWeekName());
	HUDSetLayout(HUD_MID_TOP, HUD_FLAG_ALIGN_RIGHT|HUD_FLAG_NOBG|HUD_FLAG_TEXT, g_sTime);
	HUDPlace(HUD_MID_TOP,0.00,0.00,1.0,0.03);
}

//显示击杀数量.
void IsCumulativeStatistics()
{
	int temp[2];
	char g_sStatistics[2][128];
	for (int i = 0; i < sizeof(temp); i++)
		temp[i] = GetCharacterSize(g_iCumulativeTotal[i]) - GetCharacterSize(g_iChapterTotal[i]);
	FormatEx(g_sStatistics[0], sizeof(g_sStatistics[]), "累计:特感:%d 丧尸:%d", g_iCumulativeTotal[1], g_iCumulativeTotal[0]);
	FormatEx(g_sStatistics[1], sizeof(g_sStatistics[]), "章节:特感:%s%d 丧尸:%s%d", GetAddSpacesMax(temp[1], "0"), g_iChapterTotal[1], GetAddSpacesMax(temp[0], "0"), g_iChapterTotal[0]);
	HUDSetLayout(HUD_MID_BOX, HUD_FLAG_ALIGN_RIGHT|HUD_FLAG_NOBG|HUD_FLAG_TEXT, g_sStatistics[0]);
	HUDPlace(HUD_MID_BOX,0.00,0.03,1.0,0.03);
	HUDSetLayout(HUD_FAR_RIGHT, HUD_FLAG_ALIGN_RIGHT|HUD_FLAG_NOBG|HUD_FLAG_TEXT, g_sStatistics[1]);
	HUDPlace(HUD_FAR_RIGHT,0.00,0.06,1.0,0.03);
}

//显示运行时间.
void IsShowRunningTime()
{
	char g_sChapter[128];
	FormatEx(g_sChapter, sizeof(g_sChapter), "运行:%s", StandardizeTime(g_fMapRunTime));
	HUDSetLayout(HUD_SCORE_TITLE, HUD_FLAG_ALIGN_RIGHT|HUD_FLAG_NOBG|HUD_FLAG_TEXT, g_sChapter);
	HUDPlace(HUD_SCORE_TITLE,0.00,0.09,1.0,0.03);
}

//填入对应数量的内容.
char[] GetAddSpacesMax(int Value, char[] sContent)
{
	char g_sBlank[64];
	
	if(Value > 0)
	{
		char g_sFill[32][64];
		if(Value > sizeof(g_sFill))
			Value = sizeof(g_sFill);
		for (int i = 0; i < Value; i++)
			strcopy(g_sFill[i], sizeof(g_sFill[]), sContent);
		ImplodeStrings(g_sFill, sizeof(g_sFill), "", g_sBlank, sizeof(g_sBlank));//打包字符串.
	}
	return g_sBlank;
}

//返回对应的内容.
char[] GetTrueName(int client)
{
	char g_sName[14];//因为字符限制,显示8行只能限制到14个字符.
	int Bot = IsClientIdle(client);
	
	if(Bot != 0)
		FormatEx(g_sName, sizeof(g_sName), "闲置:%N", Bot);
	else
		GetClientName(client, g_sName, sizeof(g_sName));
	return g_sName;
}

//https://forums.alliedmods.net/showthread.php?t=288686
char[] StandardizeTime(float g_fRunTime)
{
	int iTime[4];
	char sName[128], sTime[4][32];
	float fTime[3] = {86400.0, 3600.0, 60.0};
	float remainder = GetEngineTime() - g_fRunTime;
	
	iTime[0] = RoundToFloor(remainder / fTime[0]);
	remainder = remainder - float(iTime[0]) * fTime[0];
	iTime[1] = RoundToFloor(remainder / fTime[1]);
	remainder = remainder - float(iTime[1]) * fTime[1];
	iTime[2] = RoundToFloor(remainder / fTime[2]);
	remainder = remainder - float(iTime[2]) * fTime[2];
	iTime[3] = RoundToFloor(remainder);

	for (int i = 0; i < sizeof(sTime); i++)
		if(iTime[i] > 0)
			FormatEx(sTime[i], sizeof(sTime[]), "%d%s", iTime[i], sDate[i]);
	ImplodeStrings(sTime, sizeof(sTime), "", sName, sizeof(sName));//打包字符串.
	return sName;
}

//返回当前星期几.
char[] IsWeekName()
{
	char g_sWeek[8];
	FormatTime(g_sWeek, sizeof(g_sWeek), "%u");
	return g_sWeekName[StringToInt(g_sWeek) - 1];
}

//返回玩家状态.
char[] GetSurvivorStatus(int client)
{
	char g_sStatus[8];
	if(GetEntProp(client, Prop_Send, "m_currentReviveCount") >= g_iMaxReviveCount)//判断是否黑白.
	{
		if (!IsPlayerAlive(client))
			strcopy(g_sStatus, sizeof(g_sStatus), "死亡");
		else
			strcopy(g_sStatus, sizeof(g_sStatus), GetSurvivorHP(client) < g_iSurvivorHealth ? "濒死" : g_iMaxReviveCount <= 0 ? "正常" : "黑白");
	}
	else
		if (!IsPlayerAlive(client))
			strcopy(g_sStatus, sizeof(g_sStatus), "死亡");
		else if (IsPlayerFallen(client))
			strcopy(g_sStatus, sizeof(g_sStatus), "倒地");
		else if (IsPlayerFalling(client))
			strcopy(g_sStatus, sizeof(g_sStatus), "挂边");
		else
			strcopy(g_sStatus, sizeof(g_sStatus), GetSurvivorHP(client) < g_iSurvivorHealth ? g_iMaxReviveCount <= 0 ? "濒死" : "瘸腿" : "正常");
	return g_sStatus;
}

//返回服务器名字.
char[] GetHostName()
{
	char g_sHostName[256];
	g_hHostName.GetString(g_sHostName, sizeof(g_sHostName));
	return g_sHostName;
}

//返回字符串实际大小.
int GetCharacterSize(int g_iSize)
{
	char sChapter[64];
	IntToString(g_iSize, sChapter, sizeof(sChapter));//格式化int类型为char类型.
	return strlen(sChapter);
}

//幸存者总血量.
int GetSurvivorHP(int client)
{
	int HP = GetClientHealth(client) + GetPlayerTempHealth(client);
	return IsPlayerAlive(client) ? HP > 999 ? 999 : HP : 0;//如果幸存者血量大于999就显示为999
}

//幸存者虚血量.
int GetPlayerTempHealth(int client)
{
    static Handle painPillsDecayCvar = null;
    if (painPillsDecayCvar == null)
    {
        painPillsDecayCvar = FindConVar("pain_pills_decay_rate");
        if (painPillsDecayCvar == null)
            return -1;
    }

    int tempHealth = RoundToCeil(GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * GetConVarFloat(painPillsDecayCvar))) - 1;
    return tempHealth < 0 ? 0 : tempHealth;
}

//获取正在连接的玩家数量.
int GetConnectionNumber()
{
	int count = 0;
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientConnected(i) && !IsClientInGame(i) && !IsFakeClient(i))
			count += 1;
	
	return count;
}

//获取闲置或旁观者数量.
int GetPlayersStateNumber(int iTeam, bool bClientTeam)
{
	int count = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == iTeam)
		{
			if (bClientTeam)
			{
				if (iGetBotOfIdlePlayer(i))
					count += 1;
			}
			else
			{
				if (!iGetBotOfIdlePlayer(i))
					count += 1;
			}
		}
	}
	return count;
}

//获取特感或幸存者数量.
int GetPlayersMaxNumber(int iTeam, bool bSurvive)
{
	int count = 0;
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && GetClientTeam(i) == iTeam)
			if (bSurvive)
			{
				if(IsPlayerAlive(i))
					count += 1;
			}
			else
				count += 1;
	
	return count;
}

//返回最大人数.
int GetMaxPlayers()
{
	int g_iMaxcl;
	Handle invalid = null;
	Handle downtownrun = FindConVar("l4d_maxplayers");
	Handle toolzrun = FindConVar("sv_maxplayers");
	if (downtownrun != (invalid))
	{
		int downtown = (GetConVarInt(FindConVar("l4d_maxplayers")));
		
		if (downtown >= 1)
			g_iMaxcl = (GetConVarInt(FindConVar("l4d_maxplayers")));
	}
	if (toolzrun != (invalid))
	{
		int toolz = (GetConVarInt(FindConVar("sv_maxplayers")));
		if (toolz >= 1)
			g_iMaxcl = (GetConVarInt(FindConVar("sv_maxplayers")));
	}
	if (downtownrun == (invalid) && toolzrun == (invalid))
		g_iMaxcl = (MaxClients);
	return g_iMaxcl;
}

//返回闲置玩家对应的电脑.
int iGetBotOfIdlePlayer(int client)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 2 && IsClientIdle(i) == client)
			return i;
	}
	return 0;
}

//返回电脑幸存者对应的玩家.
int IsClientIdle(int client)
{
	if (!HasEntProp(client, Prop_Send, "m_humanSpectatorUserID"))
		return 0;

	return GetClientOfUserId(GetEntProp(client, Prop_Send, "m_humanSpectatorUserID"));
}

//正常状态.
stock bool IsPlayerState(int client)
{
	return !GetEntProp(client, Prop_Send, "m_isIncapacitated") && !GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
}

//挂边状态.
bool IsPlayerFalling(int client)
{
	return GetEntProp(client, Prop_Send, "m_isIncapacitated") && GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
}

//倒地状态.
bool IsPlayerFallen(int client)
{
	return GetEntProp(client, Prop_Send, "m_isIncapacitated") && !GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
}

//判断玩家有效.
bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}