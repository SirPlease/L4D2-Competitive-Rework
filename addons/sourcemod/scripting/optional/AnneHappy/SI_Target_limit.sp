#pragma newdecls required
#define DEBUG 0
#define ZC_SMOKER		1
#define ZC_BOOMER		2
#define ZC_HUNTER		3
#define ZC_SPITTER		4
#define ZC_JOCKEY		5
#define ZC_CHARGER		6
#define ZC_TANK			8
#define ENABLE_SMOKER			(1 << 0)		
#define ENABLE_BOOMER			(1 << 1)		
#define ENABLE_HUNTER			(1 << 2)		
#define ENABLE_SPITTER			(1 << 3)		
#define ENABLE_JOCKEY			(1 << 4)		
#define ENABLE_CHARGER			(1 << 5)		
#define ENABLE_TANK				(1 << 6)		
#if (DEBUG)
char sLogFile[PLATFORM_MAX_PATH] = "addons/sourcemod/logs/SITargetLimit.txt";
#endif
/**/
#pragma semicolon 1
#include <sourcemod>
#include <left4dhooks>
#undef REQUIRE_PLUGIN
#include <l4d_target_override>


#define PLUGIN_VERSION "1.4"
ConVar	
	g_hPluginEnable,
	g_hSI_enable_option,
	g_hLimit_auto,
	g_hLimit_manual,
	g_hSILimit;
char
	g_sLogPath[PLATFORM_MAX_PATH];
bool 
	g_bPluginEnable = true,
	g_bDetectRushMan = false;
int 
	g_iSI_enable_option = 0,
	g_iLimit_auto = 0,
	g_iLimit_manual = 0,
	g_iSILimit = 0;
enum struct PlayerStruct{
	int targetLimit;
	void PlayerStruct(){
		if(g_iLimit_auto){
			int temp = GetMobileSurvivorNum();
			if(temp < 1) temp = 1;
			this.targetLimit = (g_iSILimit / temp) + 1;
			this.target_override_set(this.targetLimit);
		}
			
		else{
			this.targetLimit = g_iLimit_manual;
		}
	}
	void SetTargetLimit(int number){
		if(g_iLimit_auto){
			if(g_bDetectRushMan){
				this.targetLimit = g_iSILimit;
			}else{
				this.targetLimit = number;
			}	
			this.target_override_set(this.targetLimit);		
		}
		else
		{
			this.targetLimit = g_iLimit_manual;
			this.target_override_set(this.targetLimit);
		}
	}
	void target_override_set(int num){
		for(int i = 0; i < 7; i++){
			if(CheckSIOption(i)){
				L4D_TargetOverride_SetOption(view_as<TARGET_SI_INDEX>(i), INDEX_TARGETED, num);
				//Debug_Print("所有启用特感target值更改为 %d", L4D_TargetOverride_GetOption(view_as<TARGET_SI_INDEX>(i), INDEX_TARGETED));
			}	
			else{
				L4D_TargetOverride_SetOption(view_as<TARGET_SI_INDEX>(i), INDEX_TARGETED, 0);
				//Debug_Print("所有不启用特感target值更改为 %d", L4D_TargetOverride_GetOption(view_as<TARGET_SI_INDEX>(i), INDEX_TARGETED));
			}
		}
	}
}

PlayerStruct player[MAXPLAYERS + 1];
bool infected[MAXPLAYERS + 1];
public Plugin myinfo =
{
	name = "SI target limit",
	author = "东",
	description = "限制单个玩家被特感选为目标的最大数量",
	version = PLUGIN_VERSION,
	url = "https://github.com/fantasylidong/"
}
/*
Changelog
2022.9.20
1.4 适配infected_control的跑男针对
1.3 适配l4d_target_override
1.0 初始版本发布
*/

//针对来自infected_control的跑男检测特殊处理
forward void OnDetectRushman(int DetectRushMan);
public void OnDetectRushman(int DetectRushman){
	Debug_Print("跑男状态改变，当前状态为：%d", DetectRushman);
	if(DetectRushman){
		g_bDetectRushMan = true;
		for(int i = 0; i < MAXPLAYERS +1; i++)
		{
			player[i].SetTargetLimit(g_iSILimit);
		}	
	}else
	{
		g_bDetectRushMan = false;
		int temp = GetMobileSurvivorNum();
		if(temp < 1) temp = 1;
		int normalSur = (g_iSILimit / temp) + 1;
		for(int i = 0; i < MAXPLAYERS +1; i++){
			player[i].SetTargetLimit(normalSur);
		}
	}
}

public void  OnPluginStart()
{
	g_hPluginEnable = CreateConVar("SI_target_enable", "1", "是否开启插件", 0, true, 0.0, true, 1.0);//Plugin Enable
	g_hSI_enable_option = CreateConVar("SI_enable_option", "22", "控制不同特感是否开启此项功能（1smoker，2boomer，4hunter，……，总共7个，把这些值相加的最终结果）.", 0, true, 0.0, true, 127.0);//1,2,4,8,16,32,64 add to enable different SI enable option
	g_hLimit_auto = CreateConVar("SI_target_limit_auto", "1", "服务器是否自动根据特感数量限定值来限制最大目标数量[Auto = (max / 正常生还者数量)向下取整 +1].", 0, true, 0.0, true, 1.0);//Auto Set target limit
	g_hLimit_manual = CreateConVar("SI_target_limit_manual", "3", "服务器不自动情况下手动限制最大目标的值.", 0, false, 0.0, false, 0.0);//If Auto disable, use manual value to control target limit
	g_hSILimit = FindConVar("l4d_infected_limit");
	BuildPath(Path_SM, g_sLogPath, sizeof(g_sLogPath), "logs/SI_Target_limit.log");
	
	// HookEvents
	HookEvent("player_spawn", evt_PlayerSpawn);
	//用来检测可活动的生还者数量，动态修改
	//detect alive survivor
	HookEvent("player_death", evt_PlayerDeath);
	//HookEvent("infected_death", evt_InfectedDeath);
	HookEvent("revive_success", evt_PlayerRevive);
	HookEvent("player_incapacitated", evt_PlayerIncap);
	//创建的Cvar值变化处理
	g_hLimit_auto.AddChangeHook(ConVarChanged_Cvars);
	g_hLimit_manual.AddChangeHook(ConVarChanged_Cvars);
	g_hSI_enable_option.AddChangeHook(ConVarChanged_Cvars);
	g_hPluginEnable.AddChangeHook(ConVarChanged_Cvars);
	g_hSILimit.AddChangeHook(ConVarChanged_Cvars);
	
	GetCvars();
	StructInit();
	//AutoExecConfig(true, "RestrictedGameModes");
}

public void OnPluginEnd(){
	clear_target_option();
}

public void clear_target_option(){
		for(int i = 0; i < 7; i++){
			L4D_TargetOverride_SetOption(view_as<TARGET_SI_INDEX>(i), INDEX_TARGETED, 0);
			//Debug_Print("所有不启用特感target值更改为 %d", L4D_TargetOverride_GetOption(view_as<TARGET_SI_INDEX>(i), INDEX_TARGETED));
		}
	}

//创建Native函数给其他插件使用
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	//API
	RegPluginLibrary("si_target_limit");
	
	CreateNative("GetClientTargetNum", Native_GetClientTargetNum);
	CreateNative("IsClientReachLimit", Native_IsClientReachLimit);
	
	return APLRes_Success;
}



//API
public int Native_GetClientTargetNum(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (client < 1 || client > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	if (!IsClientConnected(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
	}
	//Debug_Print("GetClientTargetNum Native called");
	
	return L4D_TargetOverride_GetValue(client, view_as<VALUE_OPTION_INDEX>(VALUE_INDEX_TOTAL));
}

public int Native_IsClientReachLimit(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (client < 1 || client > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	if (!IsClientConnected(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
	}
	//Debug_Print("IsClientReachLimit Native被调用");
	//Debug_Print("IsClientReachLimit Native called");
	return IsReachLimit(client);
}

// 事件 event
public void evt_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(IsValidClient(client) && GetClientTeam(client) == 3){
		infected[client] = view_as<bool>(CheckSIOption(GetEntProp(client, Prop_Send, "m_zombieClass")));
	}
}

public void evt_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(IsValidClient(client) ){
		if(GetClientTeam(client) == 2){
			int temp = GetMobileSurvivorNum();
			if(temp < 1) temp = 1;
			int normalSur = (g_iSILimit / temp) + 1;
			for(int i = 0; i < MAXPLAYERS +1; i++){
				player[i].SetTargetLimit(normalSur);
			}	
		}
		if(GetClientTeam(client) == 3 && infected[client]){
			infected[client] = false;
		}
	}
	
}
/*
public void evt_InfectedDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("infected_id"));
	if(IsValidClient(client) && GetClientTeam(client) == 3 && infected[client].enable){
		if(infected[client].target > 0){
			if( player[infected[client].target].targetSum > 0 ){
				player[infected[client].target].targetSum --;
				Debug_Print("%N 已死亡，原来的目标 %N 上限减1 为 %d(%d)", client, infected[client].target, player[infected[client].target].targetSum, player[infected[client].target].targetLimit);
			}
		}	
		else{
				Debug_Print("%N 已死亡，无目标", client);
		}	
		
		infected[client].target = -1;
		infected[client].enable = false;
	}
	
}
*/

public void evt_PlayerRevive(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	if(IsValidClient(client) && GetClientTeam(client) == 2){
		int temp = GetMobileSurvivorNum();
		if(temp < 1) temp = 1;
		int normalSur = (g_iSILimit / temp) + 1;
		for(int i = 0; i < MAXPLAYERS +1; i++){
			player[i].SetTargetLimit(normalSur);
		}
	}
}

public void evt_PlayerIncap(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(IsValidClient(client) && GetClientTeam(client) == 2){
		int temp = GetMobileSurvivorNum();
		if(temp < 1) temp = 1;
		int normalSur = (g_iSILimit / temp) + 1;
		for(int i = 0; i < MAXPLAYERS +1; i++){
			player[i].SetTargetLimit(normalSur);
		}
	}
}


//Check SI enable option
public int CheckSIOption(int iZombieClass){
    switch (iZombieClass)
    {
        case 1:
        {
            return 1 << 0 & g_iSI_enable_option;
        }
        case 2:
        {
            return 1 << 1 & g_iSI_enable_option;
        }
        case 3:
        {
            return 1 << 2 & g_iSI_enable_option;
        }
        case 4:
        {
            return 1 << 3 & g_iSI_enable_option;
        }
        case 5:
        {
            return 1 << 4 & g_iSI_enable_option;
        }
        case 6:
        {
            return 1 << 5 & g_iSI_enable_option;
        }
        case 0:
        {
            return 1 << 6 & g_iSI_enable_option;
        }
		case 8:
        {
            return 1 << 6 & g_iSI_enable_option;
        }
    }
    return 0;
}

// *********************
//		获取Cvar值 GetCvar
// *********************
void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

//Init Struct
public void StructInit(){
	for(int i = 0; i < MAXPLAYERS + 1; i++)
	{
		player[i].PlayerStruct();
		infected[i] = false;
	}
	g_bDetectRushMan = false;
}

public void OnMapEnd()
{
	//GetCvars();
	StructInit();
}

public void OnMapStart()
{
	//GetCvars();
	StructInit();
}
public Action L4D_OnFirstSurvivorLeftSafeArea(int client){
	//GetCvars();
    StructInit();
	
    return Plugin_Continue;
}
/*
//SI choose another target, delete originalTarget limit
public void deleteOrginalTarget(int specialInfected){
	//将特感原来的目标的targetSum减1 original target minus 1
	if(infected[specialInfected].target > 0 && player[infected[specialInfected].target].targetSum > 0){
		Debug_Print("%N 原来的目标为 %N[%N] (%d/%d)[%d]", specialInfected, \
														infected[specialInfected].target, \
														L4D_TargetOverride_GetValue(specialInfected, view_as<VALUE_OPTION_INDEX>(VALUE_INDEX_VICTIM)), \
														player[infected[specialInfected].target].targetSum, \
														player[infected[specialInfected].target].targetLimit);
		player[infected[specialInfected].target].targetSum --;
		//清除当前特感的值
		infected[specialInfected].target = -1;
	}
}


//Deal with SI change target
//特感选择目标，对对应特感进行处理
public Action L4D2_OnChooseVictim(int specialInfected, int &curTarget){
	if(IsValidClient(specialInfected) && GetClientTeam(specialInfected) == 3 && g_bPluginEnable && infected[specialInfected].enable && infected[specialInfected].target != curTarget){
		if(IsValidClient(curTarget) && GetClientTeam(curTarget) == 2){
			//如果转换的目标已经达到限制
			if(player[curTarget].IsReachLimit()){
				//如果原来有目标，保持原来目标不变
				if(infected[specialInfected].target > 0 && !player[infected[specialInfected].target].IsReachLimit()){
					int temp = infected[specialInfected].target;
					Debug_Print("%N 选择的目标 %N 已经到达上限 %d(%d) 个，切换为目标未满的原目标 %N %d(%d)", specialInfected, curTarget, player[curTarget].targetSum, player[curTarget].targetLimit, temp, player[temp].targetSum, player[temp].targetLimit);
					curTarget = infected[specialInfected].target;
					return Plugin_Changed;
				}
				//如果没有其他目标，获取其他没达到目标限制的正常生还者分给这个特感
				int temp = GetRandomMobileSurvivor(curTarget, true);
				//没有这样的人了，依旧用调用的切换对象
				if(temp == 0)
				{
					//curTarget = temp;
					deleteOrginalTarget(specialInfected);
					player[curTarget].targetSum ++;
					infected[specialInfected].target = curTarget;
					Debug_Print("%N 已经没有可选择的目标,选择默认目标 %N %d(%d)", specialInfected, curTarget, player[curTarget].targetSum, player[curTarget].targetLimit);
					return Plugin_Continue;
				//有，切换目标
				}else{	
					deleteOrginalTarget(specialInfected);
					infected[specialInfected].target = temp;
					player[temp].targetSum ++;
					Debug_Print("%N 选择的目标 %N 已经到达上限 %d(%d) 个，将目标更换为 %N %d(%d)", specialInfected, curTarget, player[curTarget].targetSum, player[curTarget].targetLimit, temp, player[temp].targetSum, player[temp].targetLimit);
					curTarget = temp;
					return Plugin_Changed;
				}			
			}else{
				deleteOrginalTarget(specialInfected);
				player[curTarget].targetSum ++;				
				infected[specialInfected].target = curTarget;
				Debug_Print("%N 选择目标为%N %d(%d)", specialInfected, curTarget, player[curTarget].targetSum, player[curTarget].targetLimit);
			}
		}
	}
	return Plugin_Continue;
}

public Action L4D_OnTargetOverride(int specialInfected, int &curTarget, int order){
	if(IsValidClient(specialInfected) && GetClientTeam(specialInfected) == 3 && g_bPluginEnable && infected[specialInfected].enable && infected[specialInfected].target != curTarget){
		if(IsValidClient(curTarget) && GetClientTeam(curTarget) == 2){
			//如果转换的目标已经达到限制
			if(player[curTarget].IsReachLimit()){
				//如果原来有目标，保持原来目标不变
				if(infected[specialInfected].target > 0 && !player[infected[specialInfected].target].IsReachLimit()){
					int temp = infected[specialInfected].target;
					Debug_Print("%N 选择的目标 %N 已经到达上限 (%d/%d)[%d/%d] 个，切换为目标未满的原目标 %N[%N] (%d/%d)[%d/%d]", specialInfected, \
																													curTarget, \
																													player[curTarget].targetSum, \
																													player[curTarget].targetLimit, \
																													L4D_TargetOverride_GetValue(curTarget, view_as<VALUE_OPTION_INDEX>(VALUE_INDEX_TOTAL)), \
																													temp, \
																													L4D_TargetOverride_GetValue(specialInfected, view_as<VALUE_OPTION_INDEX>(VALUE_INDEX_VICTIM)), \
																													player[temp].targetSum, \
																													player[temp].targetLimit,  \
																													L4D_TargetOverride_GetValue(temp, view_as<VALUE_OPTION_INDEX>(VALUE_INDEX_TOTAL)));
					curTarget = infected[specialInfected].target;
					return Plugin_Changed;
				}
				//如果没有其他目标，获取其他没达到目标限制的正常生还者分给这个特感
				int temp = GetRandomMobileSurvivor(curTarget, true);
				//没有这样的人了，依旧用调用的切换对象
				if(temp == 0)
				{
					//curTarget = temp;
					deleteOrginalTarget(specialInfected);
					player[curTarget].targetSum ++;
					infected[specialInfected].target = curTarget;
					Debug_Print("%N 已经没有可选择的目标,选择默认目标 %N (%d/%d)[%d]", specialInfected, \
																					curTarget, \
																					player[curTarget].targetSum, \
																					player[curTarget].targetLimit,  \
																					L4D_TargetOverride_GetValue(curTarget, view_as<VALUE_OPTION_INDEX>(VALUE_INDEX_TOTAL)));
					return Plugin_Continue;
				//有，切换目标
				}else{	
					deleteOrginalTarget(specialInfected);
					infected[specialInfected].target = temp;
					player[temp].targetSum ++;
					Debug_Print("%N 选择的目标 %N 已经到达上限 (%d/%d)[%d] 个，将目标更换为 %N (%d/%d)[%d]", specialInfected, \
																										curTarget, \
																										player[curTarget].targetSum, \
																										player[curTarget].targetLimit,  \
																										L4D_TargetOverride_GetValue(curTarget, view_as<VALUE_OPTION_INDEX>(VALUE_INDEX_TOTAL)), \
																										temp, \
																										player[temp].targetSum, \
																										player[temp].targetLimit, \
																										L4D_TargetOverride_GetValue(temp, view_as<VALUE_OPTION_INDEX>(VALUE_INDEX_TOTAL)));
					curTarget = temp;
					return Plugin_Changed;
				}			
			}else{
				deleteOrginalTarget(specialInfected);
				player[curTarget].targetSum ++;				
				infected[specialInfected].target = curTarget;
				Debug_Print("%N 选择目标为%N (%d/%d)[%d]", specialInfected, curTarget, player[curTarget].targetSum, player[curTarget].targetLimit, \
															L4D_TargetOverride_GetValue(curTarget, view_as<VALUE_OPTION_INDEX>(VALUE_INDEX_TOTAL)));
			}
		}
	}
	return Plugin_Continue;
}
*/
//不再对目标进行处理，只进行track
#if (DEBUG)
public Action L4D_OnTargetOverride(int specialInfected, int &curTarget, int order){
	if(IsValidClient(specialInfected) && GetClientTeam(specialInfected) == 3 && g_bPluginEnable && infected[specialInfected]){
		if(IsValidClient(curTarget) && GetClientTeam(curTarget) == 2){			
			//Debug_Print("%N 选择目标为%N (%d/%d)", specialInfected, curTarget, L4D_TargetOverride_GetValue(curTarget, view_as<VALUE_OPTION_INDEX>(VALUE_INDEX_TOTAL)), player[curTarget].targetLimit);
		}
	}
	return Plugin_Continue;
}
#endif

//随机获得一个未达到目标限制的正常生还者
stock int GetRandomMobileSurvivor(int excluse = -1, bool CheckLimit = false)
{
	int survivors[16] = {0}, index = 0;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientConnected(client) && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && !L4D_IsPlayerIncapacitated(client) && client != excluse)
		{
			if(CheckLimit && IsReachLimit(client))
				continue;
			survivors[index] = client;
			index += 1;
		}
	}
	if (index > 0)
	{
		return survivors[GetRandomInt(0, index - 1)];
	}
	return 0;
}

//返回总的正常生还者个数
stock int GetMobileSurvivorNum()
{
	int survivors[16] = {0}, index = 0;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientConnected(client) && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && !L4D_IsPlayerIncapacitated(client))
		{
			survivors[index] = client;
			index += 1;
		}
	}
	return index;
}


void GetCvars()
{
	g_bPluginEnable = GetConVarBool(g_hPluginEnable);
	g_iSI_enable_option = GetConVarInt(g_hSI_enable_option);
	g_iLimit_auto = GetConVarInt(g_hLimit_auto);
	g_iLimit_manual = GetConVarInt(g_hLimit_manual);
	g_iSILimit = GetConVarInt(g_hSILimit);
}


// 判断是否有效玩家 id，有效返回 true，无效返回 false
stock bool IsValidClient(int client)
{
	if (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client))
	{
		return true;
	}
	else
	{
		return false;
	}
}
stock bool IsReachLimit(int client){
		return L4D_TargetOverride_GetValue(client, view_as<VALUE_OPTION_INDEX>(VALUE_INDEX_TOTAL)) >= player[client].targetLimit;
	}

stock void Debug_Print(char[] format, any ...)
{
	#if (DEBUG)
	{
		char sTime[32];
		FormatTime(sTime, sizeof(sTime), "%I-%M-%S", GetTime()); 
		char sBuffer[512];
		VFormat(sBuffer, sizeof(sBuffer), format, 2);
		Format(sBuffer, sizeof(sBuffer), "[%s] %s: %s", "DEBUG", sTime, sBuffer);
	//	PrintToChatAll(sBuffer);
		PrintToConsoleAll(sBuffer);
		PrintToServer(sBuffer);
		LogToFile(sLogFile, sBuffer);
	}
	#endif
}
