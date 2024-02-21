/**
 * =============================================================================
 * Copyright https://steamcommunity.com/id/dr_lex/
 *
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <www.sourcemod.net/license.php>.
 *
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <adminmenu>
#include <localizer>
#include <nativevotes>

TopMenu hTopMenuHandle;

char sg_file[160];
char sg_file2[160];
char sMode[32];
char sBuffer[128];
char sBuffer2[128];
char sName[256];
char sNum[64];
char sDisplayTitle[128];
int iNum;
int iText;

Localizer loc;

public Plugin myinfo = 
{
	name = "[l4d2] List of missions",
	author = "dr.lex (Exclusive Coop-17)",
	description = "Automatic reading of all available campaigns",
	version = "1.3",
	url = ""
};

public void OnPluginStart()
{
	loc = new Localizer(LC_INSTALL_MODE_FULLCACHE); 
	
	RegConsoleCmd("sm_map_list", CMD_Maps, "更换三方图");
	RegAdminCmd("sm_map_list_update", CMD_MLU, ADMFLAG_UNBAN, "");
	RegConsoleCmd("sm_votedlc", CMD_VoteDlc, "", 0);
	
	BuildPath(Path_SM, sg_file, sizeof(sg_file)-1, "data/buffer.txt");
	BuildPath(Path_SM, sg_file2, sizeof(sg_file2)-1, "data/maps_list_missions.txt");
	
	TopMenu hTop_Menu;
	if (LibraryExists("adminmenu") && ((hTop_Menu = GetAdminTopMenu()) != null))
	{
		OnAdminMenuReady(hTop_Menu);
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnAdminMenuReady(Handle topmenu)
{
	if (topmenu == hTopMenuHandle)
	{
		return;
	}
	
	hTopMenuHandle = view_as<TopMenu>(topmenu);
	TopMenuObject ServerCmdCategory = hTopMenuHandle.FindCategory(ADMINMENU_SERVERCOMMANDS);
	if (ServerCmdCategory != INVALID_TOPMENUOBJECT)
	{
		hTopMenuHandle.AddItem("sm_map_list", AdminMenu_Maps, ServerCmdCategory, "sm_map_list", ADMFLAG_UNBAN);
	}
}

public void AdminMenu_Maps(TopMenu Top_Menu, TopMenuAction action, TopMenuObject object_id, int param, char[] Buffer, int maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption: Format(Buffer, maxlength, "List of Missions");
		case TopMenuAction_SelectOption: CMD_Maps(param, 0);
	}
}

public Action CMD_MLU(int client, int args)
{
	ConVar g_Mode = FindConVar("mp_gamemode");
	GetConVarString(g_Mode, sMode, sizeof(sMode));
	
	HxDelMissionsList(sg_file);
	HxDelMissionsList(sg_file2);
	HxUpdateMissionsList();
	return Plugin_Handled;
}

stock void HxDelMissionsList(char [] sFile)
{
	if (FileExists(sFile))
	{
		DeleteFile(sFile);
	}
}

stock void HxDeletAll(char [] sFile)
{
	File hFile = OpenFile(sFile, "w");
	if (hFile != null)
	{
		delete hFile;
	}
}

stock void HxUpdateMissionsList()
{
	char dirName[256];
	Format(dirName, sizeof(dirName), "addons/sourcemod/data");
	CreateDirectory(dirName, 511);
	
	DirectoryListing dirList = OpenDirectory("missions", true, NULL_STRING);
	if (dirList != null)
	{
		iNum = 0;
		FileType type;
		
		while (dirList.GetNext(sBuffer, sizeof(sBuffer), type))
		{
			if (type == FileType_File)
			{
				char sPath[128];
				Format(sPath, sizeof(sPath), "missions/%s", sBuffer);
				File f = OpenFile(sPath, "rt", true, NULL_STRING);
				if (f)
				{
					char sText[256];
					while (!f.EndOfFile() && f.ReadLine(sText, sizeof(sText)))
					{
						TrimString(sText);
						char sPath3[256];
						Format(sPath3, sizeof(sPath3), "addons/sourcemod/data/buffer.txt");
						File hFile = OpenFile(sPath3, "at");
						WriteFileLine(hFile, sText);
						delete hFile;
					}
					delete f;
				}
				
				if (StrContains(sBuffer, "campaign", true) != -1 || StrEqual(sBuffer, "credits.txt") || StrEqual(sBuffer, "holdoutchallenge.txt") || StrEqual(sBuffer, "holdouttraining.txt") || StrEqual(sBuffer, "parishdash.txt") || StrEqual(sBuffer, "shootzones.txt") || StrEqual(sBuffer, "jtsm.txt"))
				{
					if (StrContains(sBuffer, "campaign", true) != -1)
					{
						SaveBaseDate(0, sBuffer);
					}
				}
				else
				{
					SaveBaseDate(1, sBuffer);
				}
				HxDeletAll(sg_file);
			}
		}
	}
	delete dirList;
	
	HxDelMissionsList(sg_file);
}

stock void SaveBaseDate(int option, char[] sBuf)
{	
	KeyValues hGM = new KeyValues("missions");
	hGM.ImportFromFile(sg_file);
	
	char sMapText[256];
	char sMapName[256];
	
	hGM.GetString("DisplayTitle", sDisplayTitle, sizeof(sDisplayTitle)-1, "");
	if (StrEqual(sDisplayTitle, ""))
	{
		Format(sDisplayTitle, sizeof(sDisplayTitle), "Unknown");
	}
	
	hGM.GetString("Name", sName, sizeof(sName)-1, "");
	if (StrEqual(sName, ""))
	{
		Format(sName, sizeof(sName), "Unknown");
	}
	
	if (hGM.JumpToKey("modes"))
	{
		if (hGM.JumpToKey(sMode))
		{			
			KeyValues hGM2 = new KeyValues("missions");
			hGM2.ImportFromFile(sg_file2);
			
			hGM2.JumpToKey("List", true);
			switch (option)
			{
				case 0:
				{
					hGM2.JumpToKey("Valve", true);
					Format(sNum, sizeof(sNum), "%s", sBuf[8]);
					ReplaceString(sNum, sizeof(sNum), ".txt", "");
				}
				case 1:
				{
					hGM2.JumpToKey("DLC", true);
					iNum += 1;
					Format(sNum, sizeof(sNum), "%i", iNum);
				}
			}
			
			int iL = hGM2.GetNum("Total", 0);
			iL += 1;
			hGM2.SetNum("Total", iL);
			
			hGM2.SetString(sNum, sDisplayTitle);
			
			hGM2.Rewind();
			hGM2.JumpToKey("Missions", true);
			hGM2.JumpToKey(sDisplayTitle, true);
			hGM2.SetString("Name", sName);
			
			int i = 1;
			int l = 1;
			while (i <= l)
			{
				Format(sNum, sizeof(sNum), "%i", i);
				if (hGM.JumpToKey(sNum))
				{
					l += 1;
					hGM.GetString("Map", sMapText, sizeof(sMapText)-1, "");
					if (StrEqual(sMapText, ""))
					{
						Format(sMapText, sizeof(sMapText), "Unknown");
					}
					
					hGM.GetString("DisplayName", sMapName, sizeof(sMapName)-1, "");
					if (StrEqual(sMapName, ""))
					{
						Format(sMapName, sizeof(sMapName), "Unknown");
					}
					
					hGM2.JumpToKey(sNum, true);
					hGM2.SetString("Map", sMapText);
					hGM2.SetString("DisplayName", sMapName);
					hGM2.GoBack();
					
					hGM.GoBack();
				}
				i += 1;
			}
			
			hGM2.Rewind();
			hGM2.ExportToFile(sg_file2);
			delete hGM2;
		}
	}
	delete hGM;
}

//=========================================================
//=========================================================
//=========================================================

public Action CMD_Maps(int client, int args)
{
	if (client)
	{
		KeyValues hGM = new KeyValues("missions");
		hGM.ImportFromFile(sg_file2);
		if (hGM.JumpToKey("List"))
		{
			if (hGM.JumpToKey("DLC"))
			{
				iNum = 1;
			}
			else
			{
				if (hGM.JumpToKey("Valve"))
				{
					iNum = 0;
				}
				else
				{
					iNum = 2;
				}
			}
		}
		else
		{
			iNum = 2;
		}
		
		switch (iNum)
		{
			case 0: MissionsMenuList(client, 0);
			case 1: MissionsMenu(client);
			case 2:
			{
				CMD_MLU(client, 0);
				CMD_Maps(client, 0);
			}
		}
	}
	return Plugin_Handled;
}

public Action MissionsMenu(int client)
{
	if (client)
	{
		Menu menu = new Menu(MissionsMenuHandler);
		menu.SetTitle("List of Missions");
		menu.AddItem("1", "Missions (Valve)");
		menu.AddItem("2", "DLC: Missions (Workshop)");
		menu.ExitButton = false;
		menu.Display(client, 30);
	}
	return Plugin_Handled;
}

public int MissionsMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			char sInfo[16];
			menu.GetItem(param2, sInfo, sizeof(sInfo));
			if (strcmp(sInfo, "1") == 0)
			{
				MissionsMenuList(param1, 0);
			}
			if (strcmp(sInfo, "2") == 0)
			{
				MissionsMenuList(param1, 1);
			}		
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && hTopMenuHandle)
			{
				hTopMenuHandle.Display(param1, TopMenuPosition_LastCategory);
			}
		}
	}
	return 0;
}

public Action MissionsMenuList(int client, iKey)
{
	if (client)
	{
		sName[0] = '\0';
		switch (iKey)
		{
			case 0: sName = "Valve";
			case 1: sName = "DLC";
		}
		
		iText = iKey;
		
		KeyValues hGM = new KeyValues("missions");
		hGM.ImportFromFile(sg_file2);
		if (hGM.JumpToKey("List"))
		{
			if (hGM.JumpToKey(sName))
			{
				int iList = hGM.GetNum("Total", 0);
				
				Menu menu = new Menu(MissionsMenuListHandler);
				
				Format(sBuffer, sizeof(sBuffer)-1, "List of Missions (%s)", sName);
				menu.SetTitle(sBuffer);
				
				char sT[128];
				
				int i = 1;
				while (i <= iList)
				{
					Format(sNum, sizeof(sNum), "%i", i);
					hGM.GetString(sNum, sT, sizeof(sT)-1, "");
					switch (iText)
					{
						case 0: loc.PhraseTranslateToLang(sT, sBuffer, sizeof(sBuffer), client, _, _, sT);
						case 1: Format(sBuffer, sizeof(sBuffer)-1, "%s", sT);
					}
					
					menu.AddItem(sNum, sBuffer);
					
					i += 1;
				}
				
				if (iNum == 1)
				{
					menu.ExitBackButton = true;
				}
				menu.ExitButton = false;
				menu.Display(client, 30);
			}
		}
		delete hGM;
	}
	return Plugin_Handled;
}

public int MissionsMenuListHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			char sInfo[64];
			menu.GetItem(param2, sInfo, sizeof(sInfo));
			MissionsMenuListNum(param1, sInfo);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				CMD_Maps(param1, 0);
			}
		}
	}
	return 0;
}

stock void MissionsMenuListNum(int client, char[] iq_campaigns)
{
	KeyValues hGM = new KeyValues("missions");
	hGM.ImportFromFile(sg_file2);
	if (hGM.JumpToKey("List"))
	{
		if (hGM.JumpToKey(sName))
		{
			hGM.GetString(iq_campaigns, sDisplayTitle, sizeof(sDisplayTitle)-1, "");
			hGM.Rewind();
		}
		hGM.Rewind();
		
		Menu menu = new Menu(MissionsMenuListNumHandler);
		switch (iText)
		{
			case 0:
			{
				loc.PhraseTranslateToLang(sDisplayTitle, sBuffer2, sizeof(sBuffer2), client, _, _, sDisplayTitle);
				Format(sBuffer, sizeof(sBuffer)-1, "%s [Maps]", sBuffer2);
			}
			case 1: Format(sBuffer, sizeof(sBuffer)-1, "%s [Maps]", sDisplayTitle);
		}

		menu.SetTitle(sBuffer);
		
		if (hGM.JumpToKey("Missions"))
		{
			if (hGM.JumpToKey(sDisplayTitle))
			{
				char sMapText[128];
				char sDisplayNameText[128];
				
				int i = 1;
				int l = 1;
				while (i <= l)
				{
					Format(sNum, sizeof(sNum), "%i", i);
					if (hGM.JumpToKey(sNum))
					{
						l += 1;
						
						hGM.GetString("Map", sMapText, sizeof(sMapText)-1, "");
						hGM.GetString("DisplayName", sDisplayNameText, sizeof(sDisplayNameText)-1, "");
						
						switch (iText)
						{
							case 0:
							{
								loc.PhraseTranslateToLang(sDisplayNameText, sBuffer2, sizeof(sBuffer2), client, _, _, sDisplayNameText);
								Format(sBuffer, sizeof(sBuffer)-1, "Map %s [%s]", sBuffer2, sMapText);
							}
							case 1: Format(sBuffer, sizeof(sBuffer)-1, "Map %s [%s]", sDisplayNameText, sMapText);
						}
						
						menu.AddItem(sNum, sBuffer);
						hGM.GoBack();
					}
					i += 1;
				}
			}
		}
		
		menu.ExitBackButton = true;
		menu.ExitButton = false;
		menu.Display(client, 30);
	}
	delete hGM;
}

public int MissionsMenuListNumHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			char sInfo[32];
			menu.GetItem(param2, sInfo, sizeof(sInfo));
			int iN = StringToInt(sInfo);
			CampaignNumMap(param1, iN, 0);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				MissionsMenuList(param1, iText);
			}
		}
	}
	return 0;
}

stock void CampaignNumMap(int client, int iMaps, int iVote)
{
	if (client)
	{
		KeyValues hGM = new KeyValues("missions");
		hGM.ImportFromFile(sg_file2);
		if (hGM.JumpToKey("Missions"))
		{
			if (hGM.JumpToKey(sDisplayTitle))
			{
				Format(sNum, sizeof(sNum), "%i", iMaps);
				if (hGM.JumpToKey(sNum))
				{
					hGM.GetString("Map", sBuffer, sizeof(sBuffer)-1, "");
					hGM.GetString("DisplayName", sBuffer2, sizeof(sBuffer2)-1, "");
					NativeVote vote = new NativeVote(YesNoHandler, NativeVotesType_Custom_YesNo);
					vote.Initiator = client;
					vote.SetDetails("将地图更换为%s（%s m%s - %s）", sBuffer, sDisplayTitle, sNum, sBuffer2);
					vote.DisplayVoteToAll(30);
					/*switch (iVote)
					{
						case 0:
						{
						
						#if defined _l4d2_changelevel_included
							L4D2_ChangeLevel(sBuffer);
						#else
							ServerCommand("changelevel %s", sBuffer);
						#endif
						}
						case 1: FakeClientCommand(client, "callvote changelevel %s", sBuffer);
					}*/
				}
			}
		}
		delete hGM;
	}
}

public int YesNoHandler(NativeVote vote, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			vote.Close();
		}
		
		case MenuAction_VoteCancel:
		{
			if (param1 == VoteCancel_NoVotes)
			{
				vote.DisplayFail(NativeVotesFail_NotEnoughVotes);
			}
			else
			{
				vote.DisplayFail(NativeVotesFail_Generic);
			}
		}
		
		case MenuAction_VoteEnd:
		{
			if (param1 == NATIVEVOTES_VOTE_NO)
			{
				vote.DisplayFail(NativeVotesFail_Loses);
			}
			else
			{
				vote.DisplayPass("地图即将更换!");
				// Do something because it passed
				switch (0)
					{
						case 0:
						{
							ServerCommand("sm_map %s", sBuffer);
						}
						case 1: {
							int client;
							for (int i = 1; i <= MaxClients; i++){
								if (IsClientInGame(i)) client = i;
								break;
							}
							FakeClientCommand(client, "callvote changelevel %s", sBuffer);
						}
					}
			}
		}
	}
	return 0;
}

//====================================

public Action CMD_VoteDlc(int client, int args)
{
	if (client)
	{
		ConVar g_Mode = FindConVar("mp_gamemode");
		GetConVarString(g_Mode, sMode, sizeof(sMode));
	
		KeyValues hGM = new KeyValues("missions");
		hGM.ImportFromFile(sg_file2);
		if (hGM.JumpToKey("List"))
		{
			if (hGM.JumpToKey("DLC"))
			{
				int iList = hGM.GetNum("Total", 0);
				if (iList >= 1)
				{
					Menu menu = new Menu(MenuHandlerDlcCampaignVote);
					menu.SetTitle("List of DLC:Companies (Vote)");
			
					int i = 1;
					while (i <= iList)
					{
						Format(sNum, sizeof(sNum), "%i", i);
						char sNameDlc[128];
						hGM.GetString(sNum, sNameDlc, sizeof(sNameDlc)-1, "");
						
						menu.AddItem(sNum, sNameDlc);
						i += 1;
					}
					
					menu.ExitButton = false;
					menu.Display(client, 30);
				}
			}
		}
		delete hGM;
	}
	return Plugin_Handled;
}

public int MenuHandlerDlcCampaignVote(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			char sInfo[32];
			menu.GetItem(param2, sInfo, sizeof(sInfo));
			CampaignNumDlcVote(param1, sInfo);
		}
	}
	return 0;
}

stock void CampaignNumDlcVote(int client, char[] iq_campaigns)
{
	KeyValues hGM = new KeyValues("missions");
	hGM.ImportFromFile(sg_file2);
	if (hGM.JumpToKey("List"))
	{
		char sNameDlc[128];
		if (hGM.JumpToKey("DLC"))
		{
			hGM.GetString(iq_campaigns, sNameDlc, sizeof(sNameDlc)-1, "");
			hGM.Rewind();
		}
		hGM.Rewind();
		
		if (hGM.JumpToKey("Missions"))
		{
			if (hGM.JumpToKey(sNameDlc))
			{
				if (StrEqual(sMode, "coop") || StrEqual(sMode, "versus"))
				{
					char sNameKey[128];
					hGM.GetString("Name", sNameKey, sizeof(sNameKey)-1, "");
					FakeClientCommand(client, "callvote ChangeMission %s", sNameKey);
				}
				else
				{
					char sMapText[128];
					char sDisplayNameText[128];
					
					Menu menu = new Menu(MenuHandlerDlcVoteMode);
					menu.SetTitle("%s [Maps]", sNameDlc);
					
					int i = 1;
					int l = 1;
					while (i <= l)
					{
						Format(sNum, sizeof(sNum), "%i", i);
						if (hGM.JumpToKey(sNum))
						{
							l += 1;
							
							hGM.GetString("Map", sMapText, sizeof(sMapText)-1, "");
							hGM.GetString("DisplayName", sDisplayNameText, sizeof(sDisplayNameText)-1, "");
							
							Format(sBuffer, sizeof(sBuffer)-1, "Map #%i: %s [%s]", i, sDisplayNameText, sMapText);
							menu.AddItem(sNum, sBuffer);
							hGM.GoBack();
						}
						i += 1;
					}
					
					menu.ExitBackButton = true;
					menu.ExitButton = false;
					menu.Display(client, 30);
				}
			}
		}
	}
	delete hGM;
}

stock int MenuHandlerDlcVoteMode(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			char sInfo[32];
			menu.GetItem(param2, sInfo, sizeof(sInfo));
			int iN = StringToInt(sInfo);
			CampaignNumMap(param1, iN, 1);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				CMD_VoteDlc(param1, 0);
			}
		}
	}
	return 0;
}