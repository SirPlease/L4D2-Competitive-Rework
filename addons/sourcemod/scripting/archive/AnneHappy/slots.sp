#pragma newdecls required
/**/
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"
#define MAX_LINE_WIDTH 64
ConVar g_hCVarMinAllowedSlots;
ConVar g_hCVarMaxAllowedSlots;
ConVar g_hCVarCurrentMaxSlots;
ConVar MaxPlayer;
int g_iCVarMinAllowedSlots,g_iCVarMaxAllowedSlots,CurrentMaxSlots,iMaxPlayer;
public Plugin myinfo =
{
	name = "服务器位置插件",
	author = "东",
	description = "设置服务器位置",
	version = PLUGIN_VERSION,
	url = "http://sb.trygek.com:18443"
}
public void  OnPluginStart()
{
//	LoadTranslations("menu_shop.phrases.txt");
	g_hCVarMinAllowedSlots = CreateConVar("sm_slot_vote_min", "1", "可投票的最小位置 (这个值必须比 sm_slot_vote_max小).", 0, true, 1.0, true, 32.0);
	g_hCVarMaxAllowedSlots = CreateConVar("sm_slot_vote_max", "12", "可投票的最大位置 (这个值必须比sm_slot_vote_min大).", 0, true, 1.0, true, 32.0);
	g_hCVarCurrentMaxSlots = CreateConVar("sm_slot_start", "8", "启动服务器时的默认位置数量", 0, true, 1.0, true, 32.0);
	MaxPlayer=FindConVar("sv_maxplayers");
	MaxPlayer.AddChangeHook(ConVarChanged_Cvars);
	g_hCVarMinAllowedSlots.AddChangeHook(ConVarChanged_Cvars);
	g_hCVarMaxAllowedSlots.AddChangeHook(ConVarChanged_Cvars);
	RegConsoleCmd("sm_slots", SetSlots, "设置服务器位置");
	GetCvars();
	AutoExecConfig(true, "slots");
}
// *********************
//		获取Cvar值
// *********************
void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}
void GetCvars()
{
	CurrentMaxSlots=g_hCVarCurrentMaxSlots.IntValue;
	iMaxPlayer=MaxPlayer.IntValue;
	g_iCVarMinAllowedSlots = g_hCVarMinAllowedSlots.IntValue;
	g_iCVarMaxAllowedSlots = g_hCVarMaxAllowedSlots.IntValue;
	compare();
}
void compare(){
	if(CurrentMaxSlots!=iMaxPlayer){
		ServerCommand("sv_maxplayers %d",CurrentMaxSlots);
	ServerCommand("sv_visiblemaxplayers %d",CurrentMaxSlots);
	}
}
//设置服务器位置动作
public Action SetSlots(int client,int args)
{
	if(args!=1){
		ReplyToCommand(client,"\x03错误参数，位置只能设置为%d-%d，使用方式为!slots 7(你想要的位置数)",g_iCVarMinAllowedSlots,g_iCVarMaxAllowedSlots);
		return Plugin_Handled;
	}
	if(client==0||(IsValidClient(client) && IsPlayerAlive(client))){
		char arg[32];
	GetCmdArg(1,arg,sizeof(arg));
	int slots=StringToInt(arg);
	if(slots<g_iCVarMinAllowedSlots||slots>g_iCVarMaxAllowedSlots){
		ReplyToCommand(client,"\x03错误参数，位置只能设置为%d-%d，使用方式为!slots 7(你想要的位置数)",g_iCVarMinAllowedSlots,g_iCVarMaxAllowedSlots);
			return Plugin_Handled;
	}
	CurrentMaxSlots=slots;
	SetConVarInt(g_hCVarCurrentMaxSlots,slots);
	ServerCommand("sv_maxplayers %d",slots);
	ServerCommand("sv_visiblemaxplayers %d",slots);
	if(slots>4){
		ReplyToCommand(client,"\x03超过匹配限制人数，当前服务器大厅匹配由大厅管理插件处理，人数限制更改为:%d.",slots);
	}else{
		ReplyToCommand(client,"\x03未超过匹配限制人数，当前服务器人数限制更改为:%d.",slots);
	}
	}
	else{
		PrintToChatAll("\x03不是生还者无法设置位置");
	}
	return Plugin_Handled;
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
