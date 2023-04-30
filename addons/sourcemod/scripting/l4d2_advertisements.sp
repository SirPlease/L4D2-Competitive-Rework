#pragma semicolon 1
//強制1.7以後的新語法
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

#define PL_VERSION    "0.6"
#define CVAR_DISABLED "OFF"
#define CVAR_ENABLED  "ON"

public Plugin myinfo =
{
	name        = "Advertisements",
	author      = "Tsunami",
	description = "Display advertisements",
	version     = PL_VERSION,
	url         = "http://www.tsunami-productions.nl"
};

int g_iFrames                 = 0;
int g_iTickrate;
bool g_bTickrate          = true;
float g_flTime;
Handle g_hAdvertisements  = null;
Handle g_hCenterAd[MAXPLAYERS + 1];
ConVar g_hEnabled;
ConVar g_hFile;
ConVar g_hInterval;
Handle g_hTimer;
Handle QmFile = null;
char sFile[256];
char sPath[256];

static int g_iSColors[4]             = {1,               3,              3,           4};
static int g_iTColors[13][3]         = {{255, 255, 255}, {255, 0, 0},    {0, 255, 0}, {0, 0, 255}, {255, 255, 0}, {255, 0, 255}, {0, 255, 255}, {255, 128, 0}, {255, 0, 128}, {128, 255, 0}, {0, 255, 128}, {128, 0, 255}, {0, 128, 255}};
static char g_sSColors[4][13]  = {"{DEFAULT}",     "{LIGHTGREEN}", "{TEAM}",    "{GREEN}"};
static char g_sTColors[13][12] = {"{WHITE}",       "{RED}",        "{GREEN}",   "{BLUE}",    "{YELLOW}",    "{PURPLE}",    "{CYAN}",      "{ORANGE}",    "{PINK}",      "{OLIVE}",     "{LIME}",      "{VIOLET}",    "{LIGHTBLUE}"};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	MarkNativeAsOptional("GetUserMessageType");
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("sm_advertisements_version", PL_VERSION, "彩色广告插件的版本.", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hEnabled        = CreateConVar("sm_advertisements_enabled",  "1",                  "启用彩色广告插件? 0=禁用, 1=启用.");
	g_hFile           = CreateConVar("sm_advertisements_file",     "l4d2_advertisements.txt", "设置广告文本的文件名称(主机在控制台输入 sm_advertisements_reload 重新加载广告文本).");
	g_hInterval       = CreateConVar("sm_advertisements_interval", "90",                 "设置播放广告的循环时间间隔/秒.");
	HookConVarChange(g_hInterval, ConVarChange_Interval);
	AutoExecConfig(true, "l4d2_advertisements");
	RegServerCmd("sm_advertisements_reload", Command_ReloadAds, "Reload the advertisements");
}

public void OnMapStart()
{
	ParseAds();
	
	g_hTimer = CreateTimer(GetConVarInt(g_hInterval) * 1.0, Timer_DisplayAds, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public void OnConfigsExecuted()
{
	ParseAds();
}

public void OnGameFrame()
{
	if(g_bTickrate)
	{
		g_iFrames++;
		
		float flTime = GetEngineTime();
		if(flTime >= g_flTime)
		{
			if(g_iFrames == g_iTickrate)
			{
				g_bTickrate = false;
			}
			else
			{
				g_iTickrate = g_iFrames;
				g_iFrames   = 0;    
				g_flTime    = flTime + 1.0;
			}
		}
	}
}

public void ConVarChange_Interval(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(g_hTimer)
		KillTimer(g_hTimer);
	
	g_hTimer = CreateTimer(GetConVarInt(g_hInterval) * 1.0, Timer_DisplayAds, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public int Handler_DoNothing(Handle menu, MenuAction action, int param1, int param2)
{
	return 0;
}

public Action Command_ReloadAds(int args)
{
	ParseAds();
	return Plugin_Handled;
}

public Action Timer_DisplayAds(Handle timer)
{
	if(!GetConVarBool(g_hEnabled))
		return Plugin_Continue;
	
	AdminFlag fFlagList[16];
	char sBuffer[256];
	char sFlags[16];
	char sText[256];
	char sType[6];
	KvGetString(g_hAdvertisements, "type",  sType,  sizeof(sType));
	KvGetString(g_hAdvertisements, "text",  sText,  sizeof(sText));
	KvGetString(g_hAdvertisements, "flags", sFlags, sizeof(sFlags), "none");
	
	if(!KvGotoNextKey(g_hAdvertisements))
	{
		KvRewind(g_hAdvertisements);
		KvGotoFirstSubKey(g_hAdvertisements);
	}
	
	bool bAdmins = StrEqual(sFlags, "");
	bool bFlags = !StrEqual(sFlags, "none");
	if(bFlags)
		FlagBitsToArray(ReadFlagString(sFlags), fFlagList, sizeof(fFlagList));
	
	if(StrContains(sText, "{CURRENTMAP}") != -1)
	{
		GetCurrentMap(sBuffer, sizeof(sBuffer));
		ReplaceString(sText, sizeof(sText), "{CURRENTMAP}", sBuffer);
	}
	
	if(StrContains(sText, "{DATE}")       != -1)
	{
		FormatTime(sBuffer, sizeof(sBuffer), "%m/%d/%Y");
		ReplaceString(sText, sizeof(sText), "{DATE}",       sBuffer);
	}
	
	if(StrContains(sText, "{TICKRATE}")   != -1)
	{
		IntToString(g_iTickrate, sBuffer, sizeof(sBuffer));
		ReplaceString(sText, sizeof(sText), "{TICKRATE}",   sBuffer);
	}
	
	if(StrContains(sText, "{TIME}")       != -1)
	{
		FormatTime(sBuffer, sizeof(sBuffer), "%I:%M:%S%p");
		ReplaceString(sText, sizeof(sText), "{TIME}",       sBuffer);
	}
	
	if(StrContains(sText, "{TIME24}")     != -1)
	{
		FormatTime(sBuffer, sizeof(sBuffer), "%H:%M:%S");
		ReplaceString(sText, sizeof(sText), "{TIME24}",     sBuffer);
	}
	
	if(StrContains(sText, "{TIMELEFT}")   != -1)
	{
		int iMins;
		int iSecs;
		int iTimeLeft;
		
		if(GetMapTimeLeft(iTimeLeft) && iTimeLeft > 0)
		{
			iMins = iTimeLeft / 60;
			iSecs = iTimeLeft % 60;
		}
		
		Format(sBuffer, sizeof(sBuffer), "%d:%02d", iMins, iSecs);
		ReplaceString(sText, sizeof(sText), "{TIMELEFT}",   sBuffer);
	}
	
	if(StrContains(sText, "\\n")          != -1)
	{
		Format(sBuffer, sizeof(sBuffer), "%c", 13);
		ReplaceString(sText, sizeof(sText), "\\n",          sBuffer);
	}
	
	Handle hConVar;
	char sConVar[64];
	char sName[64];
	
	int iStart = StrContains(sText, "{BOOL:");
	while(iStart != -1)
	{
		int iEnd = StrContains(sText[iStart + 6], "}");
		if(iEnd != -1)
		{
			strcopy(sConVar, iEnd + 1, sText[iStart + 6]);
			Format(sName, sizeof(sName), "{BOOL:%s}", sConVar);
			
			if((hConVar = FindConVar(sConVar)))
				ReplaceString(sText, sizeof(sText), sName, GetConVarBool(hConVar) ? CVAR_ENABLED : CVAR_DISABLED);
		}
		
		int iStart2 = StrContains(sText[iStart + 1], "{BOOL:") + iStart + 1;
		if(iStart == iStart2)
			break;
		
		iStart = iStart2;
	}
	
	iStart = StrContains(sText, "{");
	while(iStart != -1)
	{
		int iEnd = StrContains(sText[iStart + 1], "}");
		if(iEnd != -1)
		{
			strcopy(sConVar, iEnd + 1, sText[iStart + 1]);
			Format(sName, sizeof(sName), "{%s}", sConVar);
			
			if((hConVar = FindConVar(sConVar)))
			{
				GetConVarString(hConVar, sBuffer, sizeof(sBuffer));
				ReplaceString(sText, sizeof(sText), sName, sBuffer);
			}
		}
		
		int iStart2 = StrContains(sText[iStart + 1], "{") + iStart + 1;
		if (iStart == iStart2)
		{
			break;
		}
		else
		{
			iStart = iStart2;
		}
	}
	
	if(StrContains(sType, "C") != -1)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i) && ((!bAdmins && !(bFlags && HasFlag(i, fFlagList))) || bAdmins && (GetUserFlagBits(i) & (ADMFLAG_GENERIC|ADMFLAG_ROOT))))
			{
				PrintCenterText(i, sText);
				
				Handle hCenterAd;
				g_hCenterAd[i] = CreateDataTimer(1.0, Timer_CenterAd, hCenterAd, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
				WritePackCell(hCenterAd,   i);
				WritePackString(hCenterAd, sText);
			}
		}
	}
	if(StrContains(sType, "H") != -1)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i) && ((!bAdmins && !(bFlags && HasFlag(i, fFlagList))) || bAdmins && (GetUserFlagBits(i) & (ADMFLAG_GENERIC|ADMFLAG_ROOT))))
				PrintHintText(i, sText);
		}
	}
	if(StrContains(sType, "M") != -1)
	{
		Handle hPl = CreatePanel();
		DrawPanelText(hPl, sText);
		SetPanelCurrentKey(hPl, 10);
		
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i) &&
			   ((!bAdmins && !(bFlags && HasFlag(i, fFlagList))) ||
			    bAdmins && (GetUserFlagBits(i) & (ADMFLAG_GENERIC|ADMFLAG_ROOT))))
				SendPanelToClient(hPl, i, Handler_DoNothing, 10);
		}
		CloseHandle(hPl);
	}
	if(StrContains(sType, "S") != -1)
	{
		char sColor[4];
		int iTeamColors = StrContains(sText, "{TEAM}");
		Format(sText, sizeof(sText), "%c%c%c%s", 1, 11, 1, sText);
		
		for(int c = 0; c < sizeof(g_iSColors); c++)
		{
			if(StrContains(sText, g_sSColors[c]))
			{
				Format(sColor, sizeof(sColor), "%c", g_iSColors[c]);
				ReplaceString(sText, sizeof(sText), g_sSColors[c], sColor);
			}
		}
		
		if(iTeamColors == -1)
		{
			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && !IsFakeClient(i) &&
				   ((!bAdmins && !(bFlags && HasFlag(i, fFlagList))) ||
				    bAdmins && (GetUserFlagBits(i) & (ADMFLAG_GENERIC|ADMFLAG_ROOT))))
					PrintToChat(i, sText);
			}
		}
		else
		{
			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && !IsFakeClient(i) &&
				   ((!bAdmins && !(bFlags && HasFlag(i, fFlagList))) ||
				    bAdmins && (GetUserFlagBits(i) & (ADMFLAG_GENERIC|ADMFLAG_ROOT))))
					SayText2(i, sText);
			}
		}
	}
	if(StrContains(sType, "T") != -1)
	{
		char sColor[16];
		int iColor = -1, iPos = BreakString(sText, sColor, sizeof(sColor));
		
		for(int i = 0; i < sizeof(g_sTColors); i++)
		{
			if(StrEqual(sColor, g_sTColors[i]))
				iColor = i;
		}
		
		if(iColor == -1)
		{
			iPos     = 0;
			iColor   = 0;
		}
		
		Handle hKv = CreateKeyValues("Stuff", "title", sText[iPos]);
		KvSetColor(hKv, "color", g_iTColors[iColor][0], g_iTColors[iColor][1], g_iTColors[iColor][2], 255);
		KvSetNum(hKv,   "level", 1);
		KvSetNum(hKv,   "time",  10);
		
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i) &&
			   ((!bAdmins && !(bFlags && HasFlag(i, fFlagList))) ||
			    bAdmins && (GetUserFlagBits(i) & (ADMFLAG_GENERIC|ADMFLAG_ROOT))))
				CreateDialog(i, hKv, DialogType_Msg);
		}
		
		CloseHandle(hKv);
	}
	return Plugin_Continue;
}

public Action Timer_CenterAd(Handle timer, Handle pack)
{
	char sText[256];
	static int iCount          = 0;
	
	ResetPack(pack);
	int iClient            = ReadPackCell(pack);
	ReadPackString(pack, sText, sizeof(sText));
	
	if(IsClientInGame(iClient) && ++iCount < 5)
	{
		PrintCenterText(iClient, sText);
		
		return Plugin_Continue;
	}
	else
	{
		iCount               = 0;
		g_hCenterAd[iClient] = null;
		
		return Plugin_Stop;
	}
}

void ParseAds()
{
	if(g_hAdvertisements)
		CloseHandle(g_hAdvertisements);
		
	g_hAdvertisements = CreateKeyValues("Advertisements");
	
	GetConVarString(g_hFile, sFile, sizeof(sFile));
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/%s", sFile);
	
	//判断是否有文件
	if (FileExists(sPath))
	{
		//读取数据
		FileToKeyValues(g_hAdvertisements, sPath);
		KvGotoFirstSubKey(g_hAdvertisements);
	}
	else
	{
		//在控制台输出。游戏中看不到
		PrintToServer("[提示]未发现广告文本文件%s,生成中...", sPath);
		l4d2_sPath();
	}
}

/// 广告文本文件自动生成
public void l4d2_sPath()
{
	QmFile = OpenFile(sPath, "w");
	
	WriteFileLine(QmFile, "\"Advertisements\"");
	WriteFileLine(QmFile, "{");
	
	WriteFileLine(QmFile, "	\"1\"");
	WriteFileLine(QmFile, "	{");
	WriteFileLine(QmFile, "		\"type\"	\"S\"");
	WriteFileLine(QmFile, "		\"text\"	\"{GREEN}[公告]{TEAM}欢迎加入玩家联机群,QQ群号:{GREEN}620707089\"");
	WriteFileLine(QmFile, "	}");
	
	WriteFileLine(QmFile, "	\"2\"");
	WriteFileLine(QmFile, "	{");
	WriteFileLine(QmFile, "		\"type\"	\"S\"");
	WriteFileLine(QmFile, "		\"text\"	\"{GREEN}[公告]{TEAM}欢迎加入玩家联机群,QQ群号:{GREEN}620707089\"");
	WriteFileLine(QmFile, "	}");
	
	WriteFileLine(QmFile, "	\"3\"");
	WriteFileLine(QmFile, "	{");
	WriteFileLine(QmFile, "		\"type\"	\"S\"");
	WriteFileLine(QmFile, "		\"text\"	\"{GREEN}[公告]{TEAM}欢迎加入玩家联机群,QQ群号:{GREEN}620707089\"");
	WriteFileLine(QmFile, "	}");
	
	WriteFileLine(QmFile, "	\"4\"");
	WriteFileLine(QmFile, "	{");
	WriteFileLine(QmFile, "		\"type\"	\"S\"");
	WriteFileLine(QmFile, "		\"text\"	\"{GREEN}[公告]{TEAM}欢迎加入玩家联机群,QQ群号:{GREEN}620707089\"");
	WriteFileLine(QmFile, "	}");
	
	WriteFileLine(QmFile, "}");
	
	delete QmFile;
}

void SayText2(int to, const char[] message)
{
	Handle hBf = StartMessageOne("SayText2", to);
	if(!hBf)
		return;
	
#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 5
	if(GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf)
	{
		PbSetBool(hBf,   "chat",     true);
		PbSetInt(hBf,    "ent_idx",  to);
		PbSetString(hBf, "msg_name", message);
		PbAddString(hBf, "params",   "");
		PbAddString(hBf, "params",   "");
		PbAddString(hBf, "params",   "");
		PbAddString(hBf, "params",   "");
	}
	else
	{
#endif
		BfWriteByte(hBf,   to);
		BfWriteByte(hBf,   true);
		BfWriteString(hBf, message);
#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 5
	}
#endif
	EndMessage();
}

bool HasFlag(int iClient, AdminFlag fFlagList[16])
{
	int iFlags = GetUserFlagBits(iClient);
	if(iFlags & ADMFLAG_ROOT)
		return true;
	
	for(int i = 0; i < sizeof(fFlagList); i++)
	{
		if(iFlags & FlagToBit(fFlagList[i]))
			return true;
	}
	
	return false;
}