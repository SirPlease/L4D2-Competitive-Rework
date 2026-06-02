#pragma semicolon 1
#pragma newdecls required

#include <clientprefs>
#include <colors>
#include <sdktools>
#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <readyup>
#include <pause>

/**
 * @section voice flags.
 */
#if !defined VOICE_NORMAL
#define VOICE_NORMAL     0  /**< Allow the client to listen and speak normally. */
#define VOICE_MUTED      1  /**< Mutes the client from speaking to everyone. */
#define VOICE_SPEAKALL   2  /**< Allow the client to speak to everyone. */
#define VOICE_LISTENALL  4  /**< Allow the client to listen to everyone. */
#define VOICE_TEAM       8  /**< Allow the client to always speak to team, even when dead. */
#define VOICE_LISTENTEAM 16 /**< Allow the client to always hear teammates, including dead ones. */
#endif

#define DEBUG 0

enum L4D2_Team
{
	L4D2Team_None = 0,
	L4D2Team_Spectator,
	L4D2Team_Survivor,
	L4D2Team_Infected,

	L4D2Team_Size    // 4 size
};

ConVar
	g_hAllTalk;
bool
	g_bReadyup,
	g_bPause;
Menu
	g_hMenu = null;
Handle
	g_hCookieStatus;

public Plugin myinfo =
{
	name        = "SpecListener",
	author      = "waertf, bear, bman, lechuga",
	description = "Allows spectator listen others team voice for l4d",
	version     = "3.0",
	url         = "http://forums.alliedmods.net/showthread.php?t=95474"
}

public void OnLibraryAdded(const char[] name)
{
	if (strcmp(name, "readyup") == 0)
	{
		g_bReadyup = true;
	}
	if (strcmp(name, "pause") == 0)
	{
		g_bPause = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (strcmp(name, "readyup") == 0)
	{
		g_bReadyup = false;
	}
	if (strcmp(name, "pause") == 0)
	{
		g_bPause = false;
	}
}

public void OnPluginStart()
{
	LoadTranslations("SpecListener.phrases");
	HookEvent("player_team", Event_PlayerTeam);
	g_hAllTalk = FindConVar("sv_alltalk");
	HookConVarChange(g_hAllTalk, OnConvarChange_Alltalk);

	RegConsoleCmd("sm_listen", PanelHear);
	g_hCookieStatus = RegClientCookie("sm_listen_status", "Listening status", CookieAccess_Public);
}

public Action PanelHear(int iClient, int iArgs)
{
	if (IsConsoleClient(iClient))
	{
		return Plugin_Handled;
	}
	else if(GetClientTeam(iClient) != view_as<int>(L4D2Team_Spectator))
	{
		CPrintToChat(iClient, "%t %t", "Tag", "OnlySpec");
		return Plugin_Handled;
	}

	if(iArgs == 0)
	{
		if (g_bReadyup)
		{
			ReadyUpMenu(iClient, "sm_hide");
		}
		if(g_bPause)
		{
			PauseMenu(iClient, "sm_hide");
		}

		g_hMenu = new Menu(Menu_Listener);
		g_hMenu.SetTitle(PanelTitle());
		g_hMenu.AddItem("true", PanelEnable());
		g_hMenu.AddItem("false", PanelDisable());
		g_hMenu.AddItem("status", PanelStatus());
		g_hMenu.ExitButton = true;
		g_hMenu.Display(iClient, MENU_TIME_FOREVER);
	}
	else if(iArgs == 1)
	{
		char sMessage[MAX_NAME_LENGTH];
		GetCmdArg(1, sMessage, sizeof(sMessage));

		if (StrEqual(sMessage, "enable", false))
		{
			SetClientListeningFlags(iClient, VOICE_LISTENALL);
			SetCookie(iClient, true);
			CPrintToChat(iClient, "%t %t", "Tag", "Enable");
		}
		else if(StrEqual(sMessage, "disable", false))
		{
			SetClientListeningFlags(iClient, VOICE_NORMAL);
			SetCookie(iClient, false);
			CPrintToChat(iClient, "%t %t", "Tag", "Disable");
		}
		else if(StrEqual(sMessage, "status", false))
		{
			ListenStatus(iClient);
		}
		else
		{
			CPrintToChat(iClient, "%t", "Usage");
		}
	}
	return Plugin_Handled;
}

public int Menu_Listener(Handle hMenu, MenuAction iAction, int iClient, int iIndex)
{
	switch (iAction)
	{
		case MenuAction_Select:
		{
			switch (iIndex)
			{
				case 0:
				{
					SetClientListeningFlags(iClient, VOICE_LISTENALL);
					SetCookie(iClient, true);
					if (g_bReadyup)
					{
						ReadyUpMenu(iClient, "sm_show");
					}
					if(g_bPause)
					{
						PauseMenu(iClient, "sm_show");
					}
					CPrintToChat(iClient, "%t %t", "Tag", "Enable");
				}
				case 1:
				{
					SetClientListeningFlags(iClient, VOICE_NORMAL);
					SetCookie(iClient, false);
					if (g_bReadyup)
					{
						ReadyUpMenu(iClient, "sm_show");
					}
					if(g_bPause)
					{
						PauseMenu(iClient, "sm_show");
					}
					CPrintToChat(iClient, "%t %t", "Tag", "Disable");
				}
				case 2:
				{
					if (g_bReadyup)
					{
						ReadyUpMenu(iClient, "sm_show");
					}
					if(g_bPause)
					{
						PauseMenu(iClient, "sm_show");
					}
					ListenStatus(iClient);
				}
			}
#if DEBUG
			PrintToChat(iClient, "%t", "SpecListener_SelectedItemFoundInfo", iIndex, found, info);
#endif
		}
		case MenuAction_Cancel:
		{
			if (g_bReadyup)
			{
				ReadyUpMenu(iClient, "sm_show");
			}
			if(g_bPause)
			{
				PauseMenu(iClient, "sm_show");
			}
#if DEBUG
			PrintToChat(iClient, "%t", "SpecListener_ClientMenuCancelledReason", iClient, iIndex);
#endif
		}
	}
	return 0;
}

public void Event_PlayerTeam(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int iclient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	int iteam   = GetEventInt(hEvent, "team");
	if (IsValidClientIndex(iclient) || IsValidClient(iclient))
	{
		switch (iteam)
		{
			case view_as<int>(L4D2Team_Spectator):
			{
				if(GetCookie(iclient))
				{
					SetClientListeningFlags(iclient, VOICE_LISTENALL);
				}
#if DEBUG
				PrintToChat(iclient, "%t", "SpecListener_Enabled");
				PrintToChat(iclient, "%t", "SpecListener_Cookie", GetCookie(iclient));
#endif
			}
			case view_as<int>(L4D2Team_Survivor):
			{
				SetClientListeningFlags(iclient, VOICE_NORMAL);
#if DEBUG
				PrintToChat(iclient, "%t", "SpecListener_Disable");
#endif
			}
			case view_as<int>(L4D2Team_Infected):
			{
				SetClientListeningFlags(iclient, VOICE_NORMAL);
#if DEBUG
				PrintToChat(iclient, "%t", "SpecListener_Disable");
#endif
			}
		}
	}
}

public void OnConvarChange_Alltalk(Handle cvar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 0)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && GetClientTeam(i) == view_as<int>(L4D2Team_Spectator))
			{
				SetClientListeningFlags(i, VOICE_LISTENALL);
#if DEBUG
				PrintToChat(i, "%t", "SpecListener_ReEnableListenAllTalk");
#endif
			}
		}
	}
}

bool IsValidClient(int iClient)
{
	if (!IsClientConnected(iClient))
	{
		return false;
	}
	if(IsFakeClient(iClient))
	{
		return false;
	}
	if(!IsClientInGame(iClient))
	{
		return false;
	}
	if(!IsClientSourceTV(iClient))
	{
		return false;
	}
	return true;
}

stock bool IsValidClientIndex(int iClient)
{
	return (iClient > 0 && iClient <= MaxClients);
}

stock bool IsConsoleClient(int iClient)
{
	return (iClient == 0);
}

public void ReadyUpMenu(int iClient, char[] sConVar)
{
	if (IsInReady())
	{
		FakeClientCommand(iClient, sConVar);
#if DEBUG
		PrintToChat(iClient, "%t", "SpecListener_Executed", sConVar);
#endif
	}
}

public void PauseMenu(int iClient, char[] sConVar)
{
	if (IsInPause())
	{
		FakeClientCommand(iClient, sConVar);
#if DEBUG
		PrintToChat(iClient, "%t", "SpecListener_Executed", sConVar);
#endif
	}
}

public void ListenStatus(int iClient)
{
	int iFlags = GetClientListeningFlags(iClient);

	if(iFlags == VOICE_LISTENALL)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "Enable");
	}
	else if(iFlags == VOICE_NORMAL)
	{
		CPrintToChat(iClient, "%t %t", "Tag", "Disable");
	}
	else
	{
		CPrintToChat(iClient, "%t %t", "Tag", "ErrorFlags");
	}
}

public void SetCookie(int iClient, bool bLintenValue)
{	
	if (AreClientCookiesCached(iClient))
	{
		char sCookieValue[2];
		IntToString(bLintenValue, sCookieValue, sizeof(sCookieValue));
		SetClientCookie(iClient, g_hCookieStatus, sCookieValue);
	} 
	else
	{
		CPrintToChat(iClient, "%t %t", "Tag", "ErrorCookie");
	}
}

public bool GetCookie(int iClient)
{
	if (AreClientCookiesCached(iClient))
	{
		char sCookieValue[2];
		GetClientCookie(iClient, g_hCookieStatus, sCookieValue, sizeof(sCookieValue));
		if(StrEqual(sCookieValue, "0", false))
		{
			return false;
		}
		else if(StrEqual(sCookieValue, "1", false))
		{
			return true;
		}
	}
	else
	{
		CPrintToChat(iClient, "%t %t", "Tag", "ErrorCookie");
	}
	return true;
}

char[] PanelTitle()
{
	char buffer[32];
	Format(buffer, sizeof(buffer), "%T", "PanelTitle", LANG_SERVER);
	return buffer;
}

char[] PanelEnable()
{
	char buffer[32];
	Format(buffer, sizeof(buffer), "%T", "PanelEnable", LANG_SERVER);
	return buffer;
}

char[] PanelDisable()
{
	char buffer[32];
	Format(buffer, sizeof(buffer), "%T", "PanelDisable", LANG_SERVER);
	return buffer;
}

char[] PanelStatus()
{
	char buffer[32];
	Format(buffer, sizeof(buffer), "%T", "PanelStatus", LANG_SERVER);
	return buffer;
}
