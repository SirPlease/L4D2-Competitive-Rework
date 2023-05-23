//Based off retsam code but i have done a complete rewrite with new ffunctions  and more features

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

native int LMC_GetClientOverlayModel(int iClient);

#define PLUGIN_VERSION "2.0.2"

static ConVar hCvar_Enabled;
static ConVar hCvar_GlowEnabled;
static ConVar hCvar_GlowColour;
static ConVar hCvar_GlowRange;
static ConVar hCvar_GlowFlash;
static ConVar hCvar_NoticeType;
static ConVar hCvar_TeamNoticeType;
static ConVar hCvar_HintRange;
static ConVar hCvar_HintTime;
static ConVar hCvar_HintColour;


static bool bEnabled = false;
static bool bGlowEnabled = false;
static int iGlowColour;
static int iGlowRange = 1800;
static int iGlowFlash = 30;
static int iNoticeType = 2;
static int iTeamNoticeType = 2;
static int iHintRange = 600;
static float fHintTime = 5.0;
static char sHintColour[32];

static char sCharName[32];
static bool bGlow[MAXPLAYERS+1] = {false, ...};

static bool bLMC_Available = false;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2");
		return APLRes_SilentFailure;
	}
	MarkNativeAsOptional("LMC_GetClientOverlayModel");
	return APLRes_Success;
}

public void OnAllPluginsLoaded()
{
	bLMC_Available = LibraryExists("LMCCore");
}

public void OnLibraryAdded(const char[] sName)
{
	if(StrEqual(sName, "LMCCore"))
		bLMC_Available = true;
}

public void OnLibraryRemoved(const char[] sName)
{
	if(StrEqual(sName, "LMCCore"))
		bLMC_Available = false;
}

public Plugin myinfo =
{
	name = "LMC_Black_and_White_Notifier",
	author = "Lux",
	description = "Notify people when player is black and white Using LMC model if any",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2449184#post2449184"
}

#define AUTO_EXEC true
public void OnPluginStart()
{
	CreateConVar("lmc_bwnotice_version", PLUGIN_VERSION, "黑白发光插件版本.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	hCvar_Enabled = CreateConVar("lmc_blackandwhite", "1", "启用幸存者黑白提示? 0=禁用,1=启用.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCvar_GlowEnabled = CreateConVar("lmc_glow", "1", "启用幸存者黑白发光. 0=禁用,1=启用.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCvar_GlowColour = CreateConVar("lmc_glowcolour", "0 0 255", "设置幸存者黑白后的发光颜色(0 0 255=蓝色).", FCVAR_NOTIFY);
	hCvar_GlowRange = CreateConVar("lmc_glowrange", "800.0", "黑白发光的幸存者最大的可视距离.", FCVAR_NOTIFY, true, 1.0);
	hCvar_GlowFlash = CreateConVar("lmc_glowflash", "20", "黑白状态下的幸存者血量低于多少时黑白光环开始闪烁. 0=禁用.", FCVAR_NOTIFY, true, 0.0);
	hCvar_NoticeType = CreateConVar("lmc_noticetype", "1", "幸存者黑白后的通知类型. 0= 关闭, 1=聊天窗, 2=屏幕中下, 3=暗示类提示(需要玩家自己打开游戏提示).", FCVAR_NOTIFY, true, 0.0, true, 3.0);
	hCvar_TeamNoticeType = CreateConVar("lmc_teamnoticetype", "0", "幸存者黑白后通知给谁. 0=幸存者, 1=感染者, 2=幸存者和感染者.", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	hCvar_HintRange = CreateConVar("lmc_hintrange", "1200", "使用暗示类黑白提示时幸存者队友能看见提示消息的距离. 最小值1, 最大值9999.", FCVAR_NOTIFY, true, 1.0, true, 9999.0);
	hCvar_HintTime = CreateConVar("lmc_hinttime", "10.0", "黑白消息的提示持续时间/秒. 最小值1, 最大值20.", FCVAR_NOTIFY, true, 1.0, true, 20.0);
	hCvar_HintColour = CreateConVar("lmc_hintcolour", "0 0 255", "屏幕中间类或暗示类黑白提示的字体颜色(0 0 255=蓝色).", FCVAR_NOTIFY);
	
	HookEvent("revive_success", eReviveSuccess);
	HookEvent("heal_success", eHealSuccess);
	HookEvent("player_death", ePlayerDeath);
	HookEvent("player_spawn", ePlayerSpawn);
	HookEvent("player_team", eTeamChange);
	HookEvent("pills_used", eItemUsedPill);
	HookEvent("adrenaline_used", eItemUsed);
	
	HookConVarChange(hCvar_Enabled, eConvarChanged);
	HookConVarChange(hCvar_GlowEnabled, eConvarChanged);
	HookConVarChange(hCvar_GlowColour, eConvarChanged);
	HookConVarChange(hCvar_GlowRange, eConvarChanged);
	HookConVarChange(hCvar_GlowFlash, eConvarChanged);
	HookConVarChange(hCvar_NoticeType, eConvarChanged);
	HookConVarChange(hCvar_TeamNoticeType, eConvarChanged);
	HookConVarChange(hCvar_HintRange, eConvarChanged);
	HookConVarChange(hCvar_HintTime, eConvarChanged);
	HookConVarChange(hCvar_HintColour, eConvarChanged);

	//监听give命令.
	AddCommandListener(CommandListener, "give");
	
	#if AUTO_EXEC
	AutoExecConfig(true, "LMC_Black_and_White_Notifier");
	#endif
	CvarsChanged();
	
}


public Action CommandListener(int client, const char[] command, int args)
{
	if(args > 0)
	{
		char buffer[8];
		GetCmdArg(1, buffer, sizeof(buffer));

		if(strcmp(buffer, "health") == 0)
			RequestFrame(IsResetCount, GetClientUserId(client));
	}
	return Plugin_Continue;
}

void IsResetCount(any client)
{
	if((client = GetClientOfUserId(client)))
	{
		if(GetEntProp(client, Prop_Send, "m_currentReviveCount") < GetMaxReviveCount())
		{
			static int iEntity;
			iEntity = -1;
			if(bGlowEnabled)
			{
				bGlow[client] = false;
				if(bLMC_Available)
				{
					iEntity = LMC_GetClientOverlayModel(client);
					if(iEntity > MaxClients)
					{
						ResetGlows(iEntity);
					}
					else
					{
						ResetGlows(client);
					}
				}
				else
				{
					ResetGlows(client);
				}
			}
		}
	}
}

public void OnMapStart()
{
	CvarsChanged();
}

public void eConvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	CvarsChanged();
}

void CvarsChanged()
{
	bEnabled = GetConVarInt(hCvar_Enabled) > 0;
	bGlowEnabled = GetConVarInt(hCvar_GlowEnabled) > 0;
	char sGlowColour[13];
	GetConVarString(hCvar_GlowColour, sGlowColour, sizeof(sGlowColour));
	iGlowColour = GetColor(sGlowColour);
	iGlowRange = GetConVarInt(hCvar_GlowRange);
	iGlowFlash = GetConVarInt(hCvar_GlowFlash);
	iNoticeType = GetConVarInt(hCvar_NoticeType);
	iTeamNoticeType = GetConVarInt(hCvar_TeamNoticeType);
	iHintRange = GetConVarInt(hCvar_HintRange);
	fHintTime = GetConVarFloat(hCvar_HintTime);
	GetConVarString(hCvar_HintColour, sHintColour, sizeof(sHintColour));
}

public void eReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
	if(!bEnabled)
		return;
	
	if(!GetEventBool(event, "lastlife"))
		return;
	
	static int iClient;
	iClient = GetClientOfUserId(GetEventInt(event, "subject"));
	
	if(iClient < 1 || iClient > MaxClients)
		return;
	
	if(!IsClientInGame(iClient) || !IsPlayerAlive(iClient))
		return;
	
	static int iEntity;
	iEntity = -1;
	
	if(bGlowEnabled)
	{
		bGlow[iClient] = true;
		if(bLMC_Available)
		{
			iEntity = LMC_GetClientOverlayModel(iClient);
			if(iEntity > MaxClients)
			{
				SetEntProp(iEntity, Prop_Send, "m_iGlowType", 3);
				SetEntProp(iEntity, Prop_Send, "m_glowColorOverride", iGlowColour);
				SetEntProp(iEntity, Prop_Send, "m_nGlowRange", iGlowRange);
				
			}
			else
			{
				SetEntProp(iClient, Prop_Send, "m_iGlowType", 3);
				SetEntProp(iClient, Prop_Send, "m_glowColorOverride", iGlowColour);
				SetEntProp(iClient, Prop_Send, "m_nGlowRange", iGlowRange);
			}
		}
		else
		{
			SetEntProp(iClient, Prop_Send, "m_iGlowType", 3);
			SetEntProp(iClient, Prop_Send, "m_glowColorOverride", iGlowColour);
			SetEntProp(iClient, Prop_Send, "m_nGlowRange", iGlowRange);
		}
	}
	
	GetModelName(iClient, iEntity);
	
	switch(iTeamNoticeType)
	{
		case 0:
		{
			for(int i = 1; i <= MaxClients;i++)
			{
				if(!IsClientInGame(i) || GetClientTeam(iClient) != 2 || IsFakeClient(i) || i == iClient)
					continue;
				
				if(iNoticeType == 1)
					PrintToChat(i, "\x04[提示]\x03%s\x04(\x03%s\x04)\x05已黑白,需要治疗.", GetTrueName(iClient), sCharName);
				if(iNoticeType == 2)
					PrintHintText(i, "[提示] %s(%s) 已黑白,需要治疗.", GetTrueName(iClient), sCharName);
				if(iNoticeType == 3)
					DirectorHint(iClient, i);
			}
			
		}
		case 1:
		{
			for(int i = 1; i <= MaxClients;i++)
			{
				if(!IsClientInGame(i) || GetClientTeam(iClient) != 3 || IsFakeClient(i))
					continue;
				
				if(iNoticeType == 1)
					PrintToChat(i, "\x04[提示]\x03%s\x04(\x03%s\x04)\x05已黑白,需要治疗.", GetTrueName(iClient), sCharName);
				if(iNoticeType == 2)
					PrintHintText(i, "[提示] %s(%s) 已黑白,需要治疗.", GetTrueName(iClient), sCharName);
				if(iNoticeType == 3)
					PrintHintText(i, "[提示] %s(%s) 已黑白,需要治疗.", GetTrueName(iClient), sCharName);
			}
		}
		case 2:
		{
			for(int i = 1; i <= MaxClients;i++)
			{
				if(!IsClientInGame(i) || IsFakeClient(i) || i == iClient)
					continue;
				
				if(iNoticeType == 1)
					PrintToChat(i, "\x04[提示]\x03%s\x04(\x03%s\x04)\x05已黑白,需要治疗.", GetTrueName(iClient), sCharName);
				if(iNoticeType == 2)
					PrintHintText(i, "[提示] %s(%s) 已黑白,需要治疗.", GetTrueName(iClient), sCharName);
				if(GetClientTeam(i) !=2)
				{
					PrintHintText(i, "[提示] %s(%s) 已黑白,需要治疗.", GetTrueName(iClient), sCharName);
					continue;
				}
				if(iNoticeType == 3)
					DirectorHint(iClient, i);
			}
		}
	}
}

public void eHealSuccess(Event event, const char[] name, bool dontBroadcast)
{
	if(!bEnabled)
		return;
	
	static int iClient;
	iClient = GetClientOfUserId(GetEventInt(event, "subject"));
	
	if(iClient < 1 || iClient > MaxClients)
		return;
	
	if(!IsClientInGame(iClient) || !IsPlayerAlive(iClient))
		return;
	
	if(!bGlow[iClient])
		return;
	
	static int iEntity;
	iEntity = -1;
	if(bGlowEnabled)
	{
		bGlow[iClient] = false;
		if(bLMC_Available)
		{
			iEntity = LMC_GetClientOverlayModel(iClient);
			if(iEntity > MaxClients)
			{
				ResetGlows(iEntity);
			}
			else
			{
				ResetGlows(iClient);
			}
		}
		else
		{
			ResetGlows(iClient);
		}
	}
	
	GetModelName(iClient, iEntity);
	static int iHealer;
	iHealer = GetClientOfUserId(GetEventInt(event, "userid"));
	
	switch(iTeamNoticeType)
	{
		case 0:
		{
			for(int i = 1; i <= MaxClients;i++)
			{
				if(!IsClientInGame(i) || GetClientTeam(iClient) != 2 || IsFakeClient(i) || i == iClient || i == iHealer)
					continue;
				
				if(iNoticeType == 1)
					if(iClient != iHealer)
						PrintToChat(i, "\x04[提示]\x03%s\x04(\x03%s\x04)\x05已接受治疗,不再黑白.", GetTrueName(iClient), sCharName);
					else
						PrintToChat(i, "\x04[提示]\x03%s\x04(\x03%s\x04)\x05治疗了自己,不再黑白.", GetTrueName(iClient), sCharName);
				
				if(iNoticeType == 2)
					if(iClient != iHealer)
						PrintHintText(i, "[提示] %s(%s) 已接受治疗,不再黑白.", GetTrueName(iClient), sCharName);
					else
						PrintHintText(i, "[提示] %s(%s) 治疗了自己,不再黑白.", GetTrueName(iClient), sCharName);
				
				if(iNoticeType == 3)
					DirectorHintAll(iClient, iHealer, i);
			}
		}
		case 1:
		{
			for(int i = 1; i <= MaxClients;i++)
			{
				if(!IsClientInGame(i) || GetClientTeam(iClient) != 3 || IsFakeClient(i) || i == iClient || i == iHealer)
					continue;
				
				if(iNoticeType == 1)
					if(iClient != iHealer)
						PrintToChat(i, "\x04[提示]\x03%s\x04(\x03%s\x04)\x05已接受治疗,不再黑白.", GetTrueName(iClient), sCharName);
					else
						PrintToChat(i, "\x04[提示]\x03%s\x04(\x03%s\x04)\x05治疗了自己,不再黑白.", GetTrueName(iClient), sCharName);
				
				if(iNoticeType == 2)
					if(iClient != iHealer)
						PrintHintText(i, "[提示] %s(%s) 已接受治疗,不再黑白.", GetTrueName(iClient), sCharName);
					else
						PrintHintText(i, "[提示] %s(%s) 治疗了自己,不再黑白.", GetTrueName(iClient), sCharName);
				
				if(iNoticeType == 3)
					if(iClient != iHealer)
						PrintHintText(i, "[提示] %s(%s) 已接受治疗,不再黑白.", GetTrueName(iClient), sCharName);
					else
						PrintHintText(i, "[提示] %s(%s) 治疗了自己,不再黑白.", GetTrueName(iClient), sCharName);
			}
		}
		case 2:
		{
			for(int i = 1; i <= MaxClients;i++)
			{
				if(!IsClientInGame(i) || IsFakeClient(i) || i == iClient || i == iHealer)
					continue;
				
				if(iNoticeType == 1)
					if(iClient != iHealer)
						PrintToChat(i, "\x04[提示]\x03%s\x04(\x03%s\x04)\x05已接受治疗,不再黑白.", GetTrueName(iClient), sCharName);
					else
						PrintToChat(i, "\x04[提示]\x03%s\x04(\x03%s\x04)\x05治疗了自己,不再黑白.", GetTrueName(iClient), sCharName);
				
				if(iNoticeType == 2)
					if(iClient != iHealer)
						PrintHintText(i, "[提示] %s(%s) 已接受治疗,不再黑白.", GetTrueName(iClient), sCharName);
					else
						PrintHintText(i, "[提示] %s(%s) 治疗了自己,不再黑白.", GetTrueName(iClient), sCharName);
				
				if(GetClientTeam(i) !=2)
					if(iClient != iHealer)
					{
						PrintHintText(i, "[提示] %s(%s) 已接受治疗,不再黑白.", GetTrueName(iClient), sCharName);
						continue;
					}
					else
					{
						PrintHintText(i, "[提示] %s(%s) 治疗了自己,不再黑白.", GetTrueName(iClient), sCharName);
						continue;
					}
				if(iNoticeType == 3)
					DirectorHintAll(iClient, iHealer, i);
			}
		}
	}
}

public void ePlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if(!bEnabled)
		return;
	
	static int iClient;
	iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(iClient < 1 || iClient > MaxClients)
		return;
	
	if(!IsClientInGame(iClient) || GetClientTeam(iClient) != 2)
		return;
	
	if(!bGlow[iClient])
		return;
	
	bGlow[iClient] = false;
	
	if(bLMC_Available)
	{
		static int iEntity;
		iEntity = LMC_GetClientOverlayModel(iClient);
		if(iEntity > MaxClients)
		{
			ResetGlows(iEntity);
		}
		else
		{
			ResetGlows(iClient);
		}
	}
	else
	{
		ResetGlows(iClient);
	}
}

public void ePlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if(!bEnabled)
		return;
	
	static int iClient;
	iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(iClient < 1 || iClient > MaxClients)
		return;
	
	if(!IsClientInGame(iClient) || GetClientTeam(iClient) != 2)
		return;

	if(GetMaxReviveCount() <= 0)
		return;
		
	if(GetEntProp(iClient, Prop_Send, "m_currentReviveCount") < GetMaxReviveCount())
	{
		if(bLMC_Available)
		{
			static int iEntity;
			iEntity = LMC_GetClientOverlayModel(iClient);
			if(iEntity > MaxClients)
			{
				ResetGlows(iEntity);
			}
			else
			{
				ResetGlows(iClient);
			}
		}
		else
		{
			ResetGlows(iClient);
		}
		bGlow[iClient] = false;
		return;
	}
	
	
	bGlow[iClient] = true;
	if(bLMC_Available)
	{
		static int iEntity;
		iEntity = LMC_GetClientOverlayModel(iClient);
		if(iEntity > MaxClients)
		{
			SetEntProp(iEntity, Prop_Send, "m_iGlowType", 3);
			SetEntProp(iEntity, Prop_Send, "m_glowColorOverride", iGlowColour);
			SetEntProp(iEntity, Prop_Send, "m_nGlowRange", iGlowRange);
			
		}
		else
		{
			SetEntProp(iClient, Prop_Send, "m_iGlowType", 3);
			SetEntProp(iClient, Prop_Send, "m_glowColorOverride", iGlowColour);
			SetEntProp(iClient, Prop_Send, "m_nGlowRange", iGlowRange);
		}
	}
	else
	{
		SetEntProp(iClient, Prop_Send, "m_iGlowType", 3);
		SetEntProp(iClient, Prop_Send, "m_glowColorOverride", iGlowColour);
		SetEntProp(iClient, Prop_Send, "m_nGlowRange", iGlowRange);
	}
}

public void eTeamChange(Event event, const char[] name, bool dontBroadcast)
{
	if(!bEnabled)
		return;
	
	static int iClient;
	iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(iClient < 1 || iClient > MaxClients)
		return;
	
	if(!IsClientInGame(iClient) || GetClientTeam(iClient) != 2 || !IsPlayerAlive(iClient))
		return;
	
	if(bLMC_Available)
	{
		static int iEntity;
		iEntity = LMC_GetClientOverlayModel(iClient);
		if(iEntity > MaxClients)
		{
			SetEntProp(iEntity, Prop_Send, "m_iGlowType", 0);
			SetEntProp(iEntity, Prop_Send, "m_glowColorOverride", 0);
			SetEntProp(iEntity, Prop_Send, "m_nGlowRange", 0);
			SetEntProp(iEntity, Prop_Send, "m_bFlashing", 0, 1);
		}
		else
		{
			SetEntProp(iClient, Prop_Send, "m_iGlowType", 0);
			SetEntProp(iClient, Prop_Send, "m_glowColorOverride", 0);
			SetEntProp(iClient, Prop_Send, "m_nGlowRange", 0);
			SetEntProp(iClient, Prop_Send, "m_bFlashing", 0, 1);
		}
	}
	else
	{
		SetEntProp(iClient, Prop_Send, "m_iGlowType", 0);
		SetEntProp(iClient, Prop_Send, "m_glowColorOverride", 0);
		SetEntProp(iClient, Prop_Send, "m_nGlowRange", 0);
		SetEntProp(iClient, Prop_Send, "m_bFlashing", 0, 1);
	}
	
}


public void LMC_OnClientModelApplied(int iClient, int iEntity, const char sModel[PLATFORM_MAX_PATH], int bBaseReattach)
{
	if(!IsClientInGame(iClient) || GetClientTeam(iClient) != 2)
		return;
	
	if(!bGlow[iClient])
		return;
	
	SetEntProp(iEntity, Prop_Send, "m_iGlowType", GetEntProp(iClient, Prop_Send, "m_iGlowType"));
	SetEntProp(iEntity, Prop_Send, "m_glowColorOverride", GetEntProp(iClient, Prop_Send, "m_glowColorOverride"));
	SetEntProp(iEntity, Prop_Send, "m_nGlowRange", GetEntProp(iClient, Prop_Send, "m_glowColorOverride"));
	SetEntProp(iEntity, Prop_Send, "m_bFlashing", GetEntProp(iClient, Prop_Send, "m_bFlashing", 1), 1);
	
	SetEntProp(iClient, Prop_Send, "m_iGlowType", 0);
	SetEntProp(iClient, Prop_Send, "m_glowColorOverride", 0);
	SetEntProp(iClient, Prop_Send, "m_nGlowRange", 0);
	SetEntProp(iClient, Prop_Send, "m_bFlashing", 0, 1);
}

public void LMC_OnClientModelDestroyed(int iClient, int iEntity)
{
	if(!IsClientInGame(iClient) || !IsPlayerAlive(iClient) || GetClientTeam(iClient) != 2)
		return;
	
	if(!IsValidEntity(iEntity))
		return;
	
	if(!bGlow[iClient])
		return;
	
	SetEntProp(iClient, Prop_Send, "m_iGlowType", GetEntProp(iEntity, Prop_Send, "m_iGlowType"));
	SetEntProp(iClient, Prop_Send, "m_glowColorOverride", GetEntProp(iEntity, Prop_Send, "m_glowColorOverride"));
	SetEntProp(iClient, Prop_Send, "m_nGlowRange", GetEntProp(iEntity, Prop_Send, "m_glowColorOverride"));
	SetEntProp(iClient, Prop_Send, "m_bFlashing", GetEntProp(iEntity, Prop_Send, "m_bFlashing", 1), 1);
}

static void GetModelName(int iClient, int iEntity)
{
	static char sModel[64];
	if(!IsValidEntity(iEntity))
	{
		GetEntPropString(iClient, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
		
		if(StrContains(sModel, "teenangst", false) > 0)
		strcopy(sCharName, sizeof(sCharName), "Zoey");
		else if(StrContains(sModel, "biker", false) > 0)
		strcopy(sCharName, sizeof(sCharName), "Francis");
		else if(StrContains(sModel, "manager", false) > 0)
		strcopy(sCharName, sizeof(sCharName), "Louis");
		else if(StrContains(sModel, "namvet", false) > 0)
		strcopy(sCharName, sizeof(sCharName), "Bill");
		else if(StrContains(sModel, "producer", false) > 0)
		strcopy(sCharName, sizeof(sCharName), "Rochelle");
		else if(StrContains(sModel, "mechanic", false) > 0)
		strcopy(sCharName, sizeof(sCharName), "Ellis");
		else if(StrContains(sModel, "coach", false) > 0)
		strcopy(sCharName, sizeof(sCharName), "Coach");
		else if(StrContains(sModel, "gambler", false) > 0)
		strcopy(sCharName, sizeof(sCharName), "Nick");
		else if(StrContains(sModel, "adawong", false) > 0)
		strcopy(sCharName, sizeof(sCharName), "AdaWong");
		else
		strcopy(sCharName, sizeof(sCharName), "Unknown");
	}
	else if(IsValidEntity(iEntity))
	{
		GetEntPropString(iEntity, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
		
		if(StrContains(sModel, "Bride", false) > 0)
		strcopy(sCharName, sizeof(sCharName), "Witch Bride");
		else if(StrContains(sModel, "Witch", false) > 0)
		strcopy(sCharName, sizeof(sCharName), "Witch");
		else if(StrContains(sModel, "hulk", false) > 0)
		strcopy(sCharName, sizeof(sCharName), "Tank");
		else if(StrContains(sModel, "boomer", false) > 0)
		strcopy(sCharName, sizeof(sCharName), "Boomer");
		else if(StrContains(sModel, "boomette", false) > 0)
		strcopy(sCharName, sizeof(sCharName), "Female Boomer");
		else if(StrContains(sModel, "hunter", false) > 0)
		strcopy(sCharName, sizeof(sCharName), "Hunter");
		else if(StrContains(sModel, "smoker", false) > 0)
		strcopy(sCharName, sizeof(sCharName), "Smoker");
		else if(StrContains(sModel, "teenangst", false) > 0)
		strcopy(sCharName, sizeof(sCharName), "Zoey");
		else if(StrContains(sModel, "biker", false) > 0)
		strcopy(sCharName, sizeof(sCharName), "Francis");
		else if(StrContains(sModel, "manager", false) > 0)
		strcopy(sCharName, sizeof(sCharName), "Louis");
		else if(StrContains(sModel, "namvet", false) > 0)
		strcopy(sCharName, sizeof(sCharName), "Bill");
		else if(StrContains(sModel, "producer", false) > 0)
		strcopy(sCharName, sizeof(sCharName), "Rochelle");
		else if(StrContains(sModel, "mechanic", false) > 0)
		strcopy(sCharName, sizeof(sCharName), "Ellis");
		else if(StrContains(sModel, "coach", false) > 0)
		strcopy(sCharName, sizeof(sCharName), "Coach");
		else if(StrContains(sModel, "gambler", false) > 0)
		strcopy(sCharName, sizeof(sCharName), "Nick");
		else if(StrContains(sModel, "adawong", false) > 0)
		strcopy(sCharName, sizeof(sCharName), "AdaWong");
		else if(StrContains(sModel, "rescue", false) > 0)
		strcopy(sCharName, sizeof(sCharName), "Chopper Pilot");
		else if(StrContains(sModel, "common", false) > 0)
		strcopy(sCharName, sizeof(sCharName), "Infected");
		else
		strcopy(sCharName, sizeof(sCharName), "Unknown");
	}
}

static void DirectorHint(int iClient, int i)
{
	static int iEntity;
	iEntity = CreateEntityByName("env_instructor_hint");
	if(iEntity == -1)
		return;
	
	static char sValues[51];
	FormatEx(sValues, sizeof(sValues), "hint%d", iClient);
	DispatchKeyValue(iClient, "targetname", sValues);
	DispatchKeyValue(iEntity, "hint_target", sValues);
	
	FormatEx(sValues, sizeof(sValues), "%i", iHintRange);
	DispatchKeyValue(iEntity, "hint_range", sValues);
	DispatchKeyValue(iEntity, "hint_icon_onscreen", "icon_alert");
	
	FormatEx(sValues, sizeof(sValues), "%f", fHintTime);
	DispatchKeyValue(iEntity, "hint_timeout", sValues);
	
	FormatEx(sValues, sizeof(sValues), "%s(%s) 已黑白,需要治疗", GetTrueName(iClient), sCharName);
	DispatchKeyValue(iEntity, "hint_caption", sValues);
	DispatchKeyValue(iEntity, "hint_color", sHintColour);
	DispatchSpawn(iEntity);
	AcceptEntityInput(iEntity, "ShowHint", i);
	
	FormatEx(sValues, sizeof(sValues), "OnUser1 !self:Kill::%f:1", fHintTime);
	SetVariantString(sValues);
	AcceptEntityInput(iEntity, "AddOutput");
	AcceptEntityInput(iEntity, "FireUser1");
}

static void DirectorHintAll(int iClient, int iHealer, int i)
{
	static int iEntity;
	iEntity = CreateEntityByName("env_instructor_hint");
	if(iEntity == -1)
		return;
	
	static char sValues[62];
	FormatEx(sValues, sizeof(sValues), "hint%d", i);
	DispatchKeyValue(i, "targetname", sValues);
	DispatchKeyValue(iEntity, "hint_target", sValues);
	
	DispatchKeyValue(iEntity, "hint_range", "0.1");
	DispatchKeyValue(iEntity, "hint_icon_onscreen", "icon_info");
	
	FormatEx(sValues, sizeof(sValues), "%f", fHintTime);
	DispatchKeyValue(iEntity, "hint_timeout", sValues);
	
	if(iClient == iHealer)
		FormatEx(sValues, sizeof(sValues), "%s(%s) 治疗了自己,不再黑白.", GetTrueName(iClient), sCharName);
	else
		FormatEx(sValues, sizeof(sValues), "%s(%s) 已接受治疗,不再黑白.", GetTrueName(iClient), sCharName);
	
	DispatchKeyValue(iEntity, "hint_caption", sValues);
	DispatchKeyValue(iEntity, "hint_color", sHintColour);
	DispatchSpawn(iEntity);
	AcceptEntityInput(iEntity, "ShowHint", i);
	
	FormatEx(sValues, sizeof(sValues), "OnUser1 !self:Kill::%f:1", fHintTime);
	SetVariantString(sValues);
	AcceptEntityInput(iEntity, "AddOutput");
	AcceptEntityInput(iEntity, "FireUser1");
}

//silvers colour converter
int GetColor(char sTemp[13])
{
	char sColors[3][4];
	ExplodeString(sTemp, " ", sColors, 3, 4);
	
	int color;
	color = StringToInt(sColors[0]);
	color += 256 * StringToInt(sColors[1]);
	color += 65536 * StringToInt(sColors[2]);
	return color;
}

public void OnClientPutInServer(int iClient)
{
	SDKHook(iClient, SDKHook_OnTakeDamage, eOnTakeDamage);
}

public Action eOnTakeDamage(int iVictim, int &iAttacker, int &iInflictor, float &fDamage, int &iDamagetype)
{
	if(!bEnabled)
		return Plugin_Continue;
	
	if(iVictim < 1 || iVictim > MaxClients)
		return Plugin_Continue;
	
	if(!IsClientInGame(iVictim) || GetClientTeam(iVictim) != 2)
		return Plugin_Continue;
	
	if(!bGlow[iVictim])
		return Plugin_Continue;
	
	static int iEntity;
	iEntity = -1;
	
	if(bLMC_Available)
		iEntity = LMC_GetClientOverlayModel(iVictim);
	
	
	if(L4D_GetPlayerTempHealth(iVictim) + GetEntProp(iVictim, Prop_Send, "m_iHealth") <= iGlowFlash)
	{
		if(bLMC_Available)
		{
			if(iEntity > MaxClients)
			{
				SetEntProp(iEntity, Prop_Send, "m_bFlashing", 1, 1);
				return Plugin_Continue;
			}
			else
			{
				SetEntProp(iVictim, Prop_Send, "m_bFlashing", 1, 1);
				return Plugin_Continue;
			}
		}
		SetEntProp(iVictim, Prop_Send, "m_bFlashing", 1, 1);
		
	}
	else
	{
		if(bLMC_Available)
		{
			if(iEntity > MaxClients)
			{
				SetEntProp(iEntity, Prop_Send, "m_bFlashing", 0, 1);
				return Plugin_Continue;
			}
			else
			{
				SetEntProp(iVictim, Prop_Send, "m_bFlashing", 0, 1);
				return Plugin_Continue;
			}
		}
		SetEntProp(iVictim, Prop_Send, "m_bFlashing", 0, 1);
	}
	return Plugin_Continue;
}

static int L4D_GetPlayerTempHealth(int client)
{
	static Handle painPillsDecayCvar = null;
	if (painPillsDecayCvar == null)
	{
		painPillsDecayCvar = FindConVar("pain_pills_decay_rate");
		if (painPillsDecayCvar == null)
		{
			return -1;
		}
	}
	
	int tempHealth = RoundToCeil(GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * GetConVarFloat(painPillsDecayCvar))) - 1;
	return tempHealth < 0 ? 0 : tempHealth;
}
static int GetMaxReviveCount()
{
	static Handle hMaxReviveCount = null;
	if (hMaxReviveCount == null)
	{
		hMaxReviveCount = FindConVar("survivor_max_incapacitated_count");
		if (hMaxReviveCount == null)
		{
			return -1;
		}
	}
	
	return GetConVarInt(hMaxReviveCount);
}

public void eItemUsedPill(Event event, const char[] name, bool dontBroadcast)
{
	if(!bEnabled)
		return;
	
	static int iClient;
	iClient = GetClientOfUserId(GetEventInt(event, "subject"));
	
	if(iClient < 1 || iClient > MaxClients)
		return;
	
	if(!IsClientInGame(iClient) || GetClientTeam(iClient) != 2 || !IsPlayerAlive(iClient))
		return;
	
	if(!bGlow[iClient])
		return;
	
	static int iEntity;
	iEntity = -1;
	if(bLMC_Available)
		iEntity = LMC_GetClientOverlayModel(iClient);
	
	if(L4D_GetPlayerTempHealth(iClient) + GetEntProp(iClient, Prop_Send, "m_iHealth") <= iGlowFlash)
	{
		if(bLMC_Available)
		{
			if(iEntity > MaxClients)
			{
				SetEntProp(iEntity, Prop_Send, "m_bFlashing", 1, 1);
				return;
			}
			else
			{
				SetEntProp(iClient, Prop_Send, "m_bFlashing", 1, 1);
				return;
			}
		}
		SetEntProp(iClient, Prop_Send, "m_bFlashing", 1, 1);
		
	}
	else
	{
		if(bLMC_Available)
		{
			if(iEntity > MaxClients)
			{
				SetEntProp(iEntity, Prop_Send, "m_bFlashing", 0, 1);
				return;
			}
			else
			{
				SetEntProp(iClient, Prop_Send, "m_bFlashing", 0, 1);
				return;
			}
		}
		SetEntProp(iClient, Prop_Send, "m_bFlashing", 0, 1);
	}
}

public void eItemUsed(Event event, const char[] name, bool dontBroadcast)
{
	if(!bEnabled)
		return;
	
	static int iClient;
	iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(iClient < 1 || iClient > MaxClients)
		return;
	
	if(!IsClientInGame(iClient) || GetClientTeam(iClient) != 2 || !IsPlayerAlive(iClient))
		return;
	
	if(!bGlow[iClient])
		return;
	
	static int iEntity;
	iEntity = -1;
	if(bLMC_Available)
		iEntity = LMC_GetClientOverlayModel(iClient);
	
	if(L4D_GetPlayerTempHealth(iClient) + GetEntProp(iClient, Prop_Send, "m_iHealth") <= iGlowFlash)
	{
		if(bLMC_Available)
		{
			if(iEntity > MaxClients)
			{
				SetEntProp(iEntity, Prop_Send, "m_bFlashing", 1, 1);
				return;
			}
			else
			{
				SetEntProp(iClient, Prop_Send, "m_bFlashing", 1, 1);
				return;
			}
		}
		SetEntProp(iClient, Prop_Send, "m_bFlashing", 1, 1);
		
	}
	else
	{
		if(bLMC_Available)
		{
			if(iEntity > MaxClients)
			{
				SetEntProp(iEntity, Prop_Send, "m_bFlashing", 0, 1);
				return;
			}
			else
			{
				SetEntProp(iClient, Prop_Send, "m_bFlashing", 0, 1);
				return;
			}
		}
		SetEntProp(iClient, Prop_Send, "m_bFlashing", 0, 1);
	}
}

static void ResetGlows(int iEntity)
{
	SetEntProp(iEntity, Prop_Send, "m_iGlowType", 0);
	SetEntProp(iEntity, Prop_Send, "m_glowColorOverride", 0);
	SetEntProp(iEntity, Prop_Send, "m_nGlowRange", 0);
	SetEntProp(iEntity, Prop_Send, "m_bFlashing", 0, 1);
}

char[] GetTrueName(int client)
{
	char g_sName[32];
	int Bot = IsClientIdle(client);
	
	if(Bot != 0)
		Format(g_sName, sizeof(g_sName), "闲置:%N", Bot);
	else
		GetClientName(client, g_sName, sizeof(g_sName));
	return g_sName;
}

int IsClientIdle(int client) {
	if (!HasEntProp(client, Prop_Send, "m_humanSpectatorUserID"))
		return 0;

	return GetClientOfUserId(GetEntProp(client, Prop_Send, "m_humanSpectatorUserID"));
}
