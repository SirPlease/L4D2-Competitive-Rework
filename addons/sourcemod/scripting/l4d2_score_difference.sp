#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <colors>
#include <left4dhooks>

#undef REQUIRE_PLUGIN

#tryinclude <l4d_info_editor>
#if !defined _info_editor_included
 native void InfoEditor_GetString(int pThis, const char[] keyname, char[] dest, int destLen);
#endif

#tryinclude <confogl>
#if !defined _confogl_Included
 native int LGO_BuildConfigPath(char[] buffer, int maxlength, const char[] sFileName);
#endif

#define PLUGIN_VERSION "1.5.1"

public Plugin myinfo = 
{
	name = "[L4D & 2] Score Difference",
	author = "Forgetest, vikingo12",
	description = "ez",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
};

#define ABS(%0) (((%0) < 0) ? -(%0) : (%0))

float g_flDelay;
bool g_bLeft4Dead2;
char g_sNextMap[64];
int g_iMapDistance, g_iNextMapDistance, g_iNextMapInfoDistance;

#define TRANSLATION_FILE "l4d2_score_difference.phrases"
void LoadPluginTranslations()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "translations/"...TRANSLATION_FILE...".txt");
	if (!FileExists(sPath))
	{
		SetFailState("Missing translation \""...TRANSLATION_FILE..."\"");
	}
	LoadTranslations(TRANSLATION_FILE);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	switch (GetEngineVersion())
	{
		case Engine_Left4Dead: g_bLeft4Dead2 = false;
		case Engine_Left4Dead2: g_bLeft4Dead2 = true;
		default:
		{
			strcopy(error, err_max, "Plugin supports L4D & 2 only");
			return APLRes_SilentFailure;
		}
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadPluginTranslations();
	
	ConVar cv = CreateConVar("l4d2_scorediff_print_delay", "5.0", "Delay in printing score difference.", FCVAR_SPONLY|FCVAR_NOTIFY, true, 0.0);
	OnConVarChanged(cv, "", "");
	cv.AddChangeHook(OnConVarChanged);
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flDelay = convar.FloatValue;
}

public void L4D_OnFirstSurvivorLeftSafeArea_Post(int client)
{
	g_iMapDistance = L4D_GetVersusMaxCompletionScore();
}

public void OnMapEnd()
{
	g_iNextMapDistance = 0;
	g_sNextMap[0] = '\0';
	g_iNextMapInfoDistance = 0;
}

public void OnGetMissionInfo(int pThis)
{
	if (!g_bLeft4Dead2)
		return;
	
	int iNextChapter = L4D_GetCurrentChapter() + 1;
	char buffer[64], ret[64];
	
	if (g_iNextMapDistance == 0)
	{
		FormatEx(buffer, sizeof(buffer), "modes/versus/%i/VersusCompletionScore", iNextChapter);
		InfoEditor_GetString(pThis, buffer, ret, sizeof(ret));
		
		g_iNextMapDistance = StringToInt(ret);
	}
	
	if (g_sNextMap[0] == '\0')
	{
		if (GetFeatureStatus(FeatureType_Native, "LGO_BuildConfigPath") == FeatureStatus_Available)
		{
			FormatEx(buffer, sizeof(buffer), "modes/versus/%i/Map", iNextChapter);
			InfoEditor_GetString(pThis, buffer, g_sNextMap, sizeof(g_sNextMap));
			
			KeyValues kv = new KeyValues("MapInfo");
			LGO_BuildConfigPath(buffer, sizeof(buffer), "mapinfo.txt");
			if (kv.ImportFromFile(buffer) && kv.JumpToKey(g_sNextMap))
			{
				g_iNextMapInfoDistance = kv.GetNum("map_distance", 0);
			}
			
			delete kv;
		}
	}
}

public void L4D2_OnEndVersusModeRound_Post()
{
	if (g_iNextMapInfoDistance != 0)
	{
		g_iNextMapDistance = g_iNextMapInfoDistance;
	}
	else if (g_iNextMapDistance == 0)
	{
		int iNextChapter = L4D_GetCurrentChapter() + 1;
		int iMaxChapters = L4D_GetMaxChapters();
		
		if (iNextChapter <= iMaxChapters)
		{
			if (iMaxChapters <= 5)
			{
				g_iNextMapDistance = 800 - 100 * (iMaxChapters - iNextChapter);
			}
			else
			{
				g_iNextMapDistance = 400 + 100 * (iNextChapter - 1);
			}
		}
	}
	
	if (InSecondHalfOfRound())
	{
		if (g_flDelay >= 0.1)
			CreateTimer(g_flDelay, Timer_PrintDifference, _, TIMER_FLAG_NO_MAPCHANGE);
		else
			Timer_PrintDifference(null);
	}
	else
	{
		if (g_flDelay >= 0.1)
			CreateTimer(g_flDelay, Timer_PrintComeback, _, TIMER_FLAG_NO_MAPCHANGE);
		else
			Timer_PrintComeback(null);
	}
}

Action Timer_PrintComeback(Handle timer)
{
	int iSurvCampaignScore = GetCampaignScore(L4D2_TeamNumberToTeamIndex(2));
	int iInfCampaignScore = GetCampaignScore(L4D2_TeamNumberToTeamIndex(3));
	
	int iTotalDifference = ABS(iSurvCampaignScore - iInfCampaignScore);
	
	if (TranslationPhraseExists("Announce_Survivor"))
		CPrintToChatAll("%t", "Announce_Survivor", iSurvCampaignScore);
	
	if (TranslationPhraseExists("Announce_Infected"))
		CPrintToChatAll("%t", "Announce_Infected", iInfCampaignScore);
	
	if (g_bLeft4Dead2)
	{
		if (iTotalDifference <= g_iMapDistance)
		{
			if (TranslationPhraseExists("Announce_ComebackWithDistance"))
				CPrintToChatAll("%t", "Announce_ComebackWithDistance", iTotalDifference);
		}
		else
		{
			if (TranslationPhraseExists("Announce_ComebackWithBonus"))
				CPrintToChatAll("%t", "Announce_ComebackWithBonus", g_iMapDistance, iTotalDifference - g_iMapDistance);
		}
	}
	else
	{
		if (TranslationPhraseExists("Announce_ComebackWithBonus_L4D1"))
			CPrintToChatAll("%t", "Announce_ComebackWithBonus_L4D1", iTotalDifference);
	}
	
	return Plugin_Stop;
}

Action Timer_PrintDifference(Handle timer)
{
	int iSurvRoundScore = GetChapterScore(L4D2_TeamNumberToTeamIndex(2));
	int iInfRoundScore = GetChapterScore(L4D2_TeamNumberToTeamIndex(3));
	int iSurvCampaignScore = GetCampaignScore(L4D2_TeamNumberToTeamIndex(2));
	int iInfCampaignScore = GetCampaignScore(L4D2_TeamNumberToTeamIndex(3));
	
	int iRoundDifference = ABS(iSurvRoundScore - iInfRoundScore);
	int iTotalDifference = ABS(iSurvCampaignScore - iInfCampaignScore);
	
	if (iRoundDifference != iTotalDifference) 
	{
		CPrintToChatAll("%t", "Announce_Chapter", iRoundDifference);
		CPrintToChatAll("%t", "Announce_Total", iTotalDifference);
	}
	else 
	{
		CPrintToChatAll("%t", "Announce_ElseChapter", iRoundDifference);
	}
	
	if (TranslationPhraseExists("Announce_Survivor"))
		CPrintToChatAll("%t", "Announce_Survivor", iSurvCampaignScore);
	
	if (TranslationPhraseExists("Announce_Infected"))
		CPrintToChatAll("%t", "Announce_Infected", iInfCampaignScore);
	
	if (g_bLeft4Dead2)
	{
		if (!L4D_IsMissionFinalMap() && g_iNextMapDistance > 0)
		{
			if (iTotalDifference <= g_iNextMapDistance)
			{
				if (TranslationPhraseExists("Announce_ComebackWithDistance"))
					CPrintToChatAll("%t", "Announce_ComebackWithDistance", iTotalDifference);
			}
			else
			{
				if (TranslationPhraseExists("Announce_ComebackWithBonus"))
					CPrintToChatAll("%t", "Announce_ComebackWithBonus", g_iNextMapDistance, iTotalDifference - g_iNextMapDistance);
			}
		}
	}
	else
	{
		if (TranslationPhraseExists("Announce_ComebackWithBonus_L4D1"))
			CPrintToChatAll("%t", "Announce_ComebackWithBonus_L4D1", iTotalDifference);
	}
	
	return Plugin_Stop;
}

int GetChapterScore(int team)
{
	if (!g_bLeft4Dead2)
	{
		switch (team)
		{
		case 0:
			{
				return GameRules_GetProp("m_iVersusMapScoreTeam1", _, L4D_GetCurrentChapter() - 1);
			}
		case 1:
			{
				return GameRules_GetProp("m_iVersusMapScoreTeam2", _, L4D_GetCurrentChapter() - 1);
			}
		}
	}
	
	return GameRules_GetProp("m_iChapterScore", _, team);
}

int GetCampaignScore(int team)
{
	return GameRules_GetProp("m_iCampaignScore", _, team);
}

int InSecondHalfOfRound()
{
	return GameRules_GetProp("m_bInSecondHalfOfRound");
}

stock int L4D2_TeamNumberToTeamIndex(int team)
{
    return (team - 2) ^ GameRules_GetProp("m_bAreTeamsFlipped");
}
