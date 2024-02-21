/*
 *	V2.4.8
 *
 *	1:增加SteamId获取失败的玩家列表.
 *
 */

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

#define PLUGIN_VERSION	"2.4.10"	//版本号.
#define DefaultPassword	"12345678"	//默认密码.
#define DefaultSteamId	"STEAM_1:1:00000000"	//默认SteamId.

int g_iBlockCmdsCount;

char sKvPath[PLATFORM_MAX_PATH], g_sData[4][128], g_sBlockCmds[32][64], g_sSteamId[512], g_sInfo[128], g_sPassword[64], g_sAuthority[32] = "99:z";//添加管理员时的权限.

ArrayList LineArray, SiteArray, ListArray, FailArray;

public Plugin myinfo = 
{
	name        = "admins_simple",
	author      = "豆瓣酱な",
	description = "添加或删除admins_simple.ini文件里的SteamId.",
	version     = "PLUGIN_VERSION",
	url         = "N/A"
};

public void OnPluginStart()
{
	BuildPath(Path_SM, sKvPath, sizeof(sKvPath), "configs/l4d2_admins_simple.cfg");
	IsReadFileValues();

	RegConsoleCmd("sm_root", Command_AdminMenu, "打开添加或删除管理员菜单.");

	LineArray = new ArrayList(ByteCountToCells(128));//在线的管理员(设置字符串大小).
	SiteArray = new ArrayList(ByteCountToCells(128));//离线的管理员(设置字符串大小).
	ListArray = new ArrayList(ByteCountToCells(128));//非管理员玩家(设置字符串大小).
	FailArray = new ArrayList(ByteCountToCells(128));//非管理员玩家(设置字符串大小).
}
public void OnConfigsExecuted()
{
	IsReadFileValues();
}

void IsReadFileValues()
{
	KeyValues kv = new KeyValues("Values");
	if (!FileExists(sKvPath))
	{
		File file = OpenFile(sKvPath, "w");
		if (!file)
			LogError("无法读取文件: \"%s\"", sKvPath);
		// 写入内容.
		kv.SetString("Password", GetRandomPassword());
		kv.SetString("SteamId", DefaultSteamId);
		// 返回上一页.
		kv.Rewind();
		// 把内容写入文件.
		kv.ExportToFile(sKvPath);
		delete file;
	}
	else if (kv.ImportFromFile(sKvPath)) //文件存在就导入kv数据,false=文件存在但是读取失败.
	{
		// 获取Kv文本内信息写入变量中.
		kv.GetString("Password", g_sPassword, sizeof(g_sPassword), DefaultPassword);
		kv.GetString("SteamId", g_sSteamId, sizeof(g_sSteamId), DefaultSteamId);

		if((g_sSteamId[0] == '\0' || (strcmp(g_sSteamId, DefaultSteamId, false) == 0) && strcmp(g_sPassword, DefaultPassword, false) == 0))//没有指定或是默认SteamId并且是默认密码则删除文件,然后重新创建文件并写入随机密码.
		{
			DataPack hPack = new DataPack();
			hPack.WriteString(GetRandomPassword());//写入随机密码.
			hPack.WriteString(DefaultSteamId);//写入默认SteamId.
			RequestFrame(IsWriteData, hPack);
			
		}
		else
			GetReadFileValues();//拆分字符串.
	}
	delete kv;
}

void IsWriteData(DataPack hPack)
{
	hPack.Reset();
	char sData[2][32];
	for (int i = 0; i < sizeof(sData); i++)
		hPack.ReadString(sData[i], sizeof(sData[]));
	KeyValues kv = new KeyValues("Values");
	if (FileExists(sKvPath))
	{
		File file = OpenFile(sKvPath, "w");
		if (!file)
			LogError("无法读取文件: \"%s\"", sKvPath);
		// 写入内容.
		kv.SetString("Password", sData[0]);
		kv.SetString("SteamId", sData[1]);
		// 返回上一页.
		kv.Rewind();
		// 把内容写入文件.
		kv.ExportToFile(sKvPath);
		delete file;
		strcopy(g_sPassword, sizeof(g_sPassword), sData[0]);//把新密码写入密码字符串.
	}
	delete hPack;
}

char[] GetRandomPassword()
{
	char sPassword[64];
	char[][] sRandom = new char[strlen(DefaultPassword)][32];
	for (int i = 0; i < strlen(DefaultPassword); i++)
		IntToString(GetRandomInt(1, 9),	sRandom[i], 32);
	ImplodeStrings(sRandom, strlen(DefaultPassword), "", sPassword, sizeof(sPassword));//打包字符串.
	return sPassword;
}

void GetReadFileValues()
{
	if(strcmp(g_sSteamId, DefaultSteamId, false) != 0)//对比字符串.
	{
		g_iBlockCmdsCount = ReplaceString(g_sSteamId, sizeof(g_sSteamId), ";", ";", false);
		ExplodeString(g_sSteamId, ";", g_sBlockCmds, g_iBlockCmdsCount + 1, sizeof(g_sBlockCmds[]));
	}
}

public Action OnClientSayCommand(int client, const char[] commnad, const char[] args)
{
	if(strlen(args) <= 1 || strncmp(commnad, "say", 3, false) != 0)
		return Plugin_Continue;

	if(StrContains(args, g_sPassword) != -1 || StrContains(args, "root") != -1)
		return Plugin_Handled;//阻止玩家输入的指令显示出来,预防憨憨萌新把密码显示到聊天窗.
	
	return Plugin_Continue;
}

public Action Command_AdminMenu(int client, int args)
{
	Command_AdminList(client, args);
	return Plugin_Handled;
}

void Command_AdminList(int client, int args)
{
	if(strcmp(g_sSteamId, DefaultSteamId, false) != 0)//对比字符串.
	{
		if(IsAcquirePlayerRights(GetSteamId(client)))
			IsEditAdministrator(client, 0);
		else
			PrintToChat(client, "\x04[提示]\x05请确认已填入正确的SteamId(你的ID为:%s).", GetSteamId(client));
	}
	else
	{
		switch (args)
		{
			case 0:
			{
				PrintToChat(client, "\x04[提示]\x05指令用法:sm_root空格+密码(或者指定SteamId的玩家使用该指令).");
				PrintToChat(client, "\x04[提示]\x05文件路径:*/addons/sourcemod/configs/l4d2_admins_simple.cfg");
			}
			case 1:
			{
				char arg[64];
				GetCmdArgString(arg, sizeof(arg));
				if (StrEqual(arg, g_sPassword, false))
					IsEditAdministrator(client, 0);
				else
					PrintToChat(client, "\x04[提示]\x05你输入的密码有误,请重新输入.");
			}
		}
	}
}

bool IsAcquirePlayerRights(char[] SteamId)
{
	for (int i = 0; i <= g_iBlockCmdsCount; i++)
		if (StrEqual(g_sBlockCmds[i], SteamId, false))
			return true;
	return false;
}

void IsEditAdministrator(int client, int index)
{
	DumpAdminCache(AdminCache_Admins, true);//刷新管理员.
	LineArray.Clear();//清除数组内容.
	SiteArray.Clear();//清除数组内容.
	ListArray.Clear();//清除数组内容.
	FailArray.Clear();//清除数组内容.
	GetAdminLists();//获取文件列表.
	GetPlayerLists();//获取玩家列表.
	int iNum[4];
	iNum[0] = LineArray.Length;
	iNum[1] = SiteArray.Length;
	iNum[2] = ListArray.Length;
	iNum[3] = FailArray.Length;
	char sList[128], sInfo[128], sData[sizeof(g_sData)][128];

	Menu menu = new Menu(MenuAdminListHandler);
	menu.SetTitle("添加或删除管理员:\n▬▬▬▬▬▬▬▬▬▬▬▬▬");
	//在线的管理员.
	if(iNum[0])
	{
		//LineArray.Sort(Sort_Ascending, Sort_String);//对数组进行升序排序(排序按照文本类型进行).
		//LineArray.Sort(Sort_Descending, Sort_String);//对数组进行降序排序(排序按照文本类型进行).
		for (int i = 0; i < iNum[0]; i++)
		{
			LineArray.GetString(i, sInfo, sizeof(sInfo));
			ExplodeString(sInfo, "|", sData, sizeof(sData), sizeof(sData[]));//拆分字符串.
			//ImplodeStrings(sData, sizeof(sData), "|", sInfo, sizeof(sInfo));//打包字符串.
			FormatEx(sList, sizeof(sList), "%s|%s|%s", sData[1], sData[3], sData[0][0] != '\0' ? GetPlayerName(sData[2]) : sData[2]);
			menu.AddItem(sInfo, sList);
		}
	}
	//离线的管理员.
	if(iNum[1])
	{
		//SiteArray.Sort(Sort_Ascending, Sort_String);//对数组进行升序排序(排序按照文本类型进行).
		//SiteArray.Sort(Sort_Descending, Sort_String);//对数组进行降序排序(排序按照文本类型进行).
		for (int i = 0; i < iNum[1]; i++)
		{
			SiteArray.GetString(i, sInfo, sizeof(sInfo));
			ExplodeString(sInfo, "|", sData, sizeof(sData), sizeof(sData[]));//拆分字符串.
			//ImplodeStrings(sData, sizeof(sData), "|", sInfo, sizeof(sInfo));//打包字符串.
			FormatEx(sList, sizeof(sList), "%s|%s|%s", sData[1], sData[3], sData[0][0] != '\0' ? sData[0] : sData[2]);
			menu.AddItem(sInfo, sList);
		}
	}
	//非管理员玩家.
	if(iNum[2])
	{
		//ListArray.Sort(Sort_Ascending, Sort_String);//对数组进行升序排序(排序按照文本类型进行).
		//ListArray.Sort(Sort_Descending, Sort_String);//对数组进行降序排序(排序按照文本类型进行).
		for (int i = 0; i < iNum[2]; i++)
		{
			ListArray.GetString(i, sInfo, sizeof(sInfo));
			ExplodeString(sInfo, "|", sData, sizeof(sData), sizeof(sData[]));//拆分字符串.
			//ImplodeStrings(sData, sizeof(sData), "|", sInfo, sizeof(sInfo));//打包字符串.
			FormatEx(sList, sizeof(sList), "%s|%s|%s", sData[1], sData[3], sData[0]);
			menu.AddItem(sInfo, sList);
		}
	}
	//获取失败的玩家.
	if(iNum[3])
	{
		//FailArray.Sort(Sort_Ascending, Sort_String);//对数组进行升序排序(排序按照文本类型进行).
		//FailArray.Sort(Sort_Descending, Sort_String);//对数组进行降序排序(排序按照文本类型进行).
		for (int i = 0; i < iNum[3]; i++)
		{
			FailArray.GetString(i, sInfo, sizeof(sInfo));
			ExplodeString(sInfo, "|", sData, sizeof(sData), sizeof(sData[]));//拆分字符串.
			//ImplodeStrings(sData, sizeof(sData), "|", sInfo, sizeof(sInfo));//打包字符串.
			FormatEx(sList, sizeof(sList), "%s|%s|%s", sData[1], sData[3], sData[0]);
			menu.AddItem(sInfo, sList);
		}
	}
	
	menu.ExitButton = true;//默认值:true,设置为:false,则不显示退出选项.
	menu.DisplayAt(client, index, MENU_TIME_FOREVER);
}

//获取文件列表.
void GetAdminLists()
{
	char sFileName[PLATFORM_MAX_PATH], line[512];
	BuildPath(Path_SM, sFileName, sizeof(sFileName), "configs/admins_simple.ini");
	
	File file = OpenFile(sFileName, "rt");
	if (file)
	{
		while (!file.EndOfFile())
		{
			if (!file.ReadLine(line, sizeof(line)))
				break;

			if(strncmp(line, "\"", 1, false) != 0 || strncmp(line, "/", 1, false) == 0 || strncmp(line, "/", 2, false) == 0)
				continue;
			
			char sBlock[8][128], sMerge[2][128];
			int g_iCount = ReplaceString(line, sizeof(line), "\"", "\"", false);
			ExplodeString(line, "\"", sBlock, g_iCount + 1, sizeof(sBlock[]));//拆分字符串.
			for (int i = 0; i <= g_iCount; i++)
				TrimString(sBlock[i]);
			
			ExplodeString(sBlock[4], "//", sMerge, sizeof(sMerge), sizeof(sMerge[]));//拆分字符串.
			strcopy(g_sData[0], sizeof(g_sData[]), sMerge[1]);
			strcopy(g_sData[1], sizeof(g_sData[]), GetAdminStatus(sBlock[1]) ? "在线" : "离线");
			strcopy(g_sData[2], sizeof(g_sData[]), sBlock[1]);
			strcopy(g_sData[3], sizeof(g_sData[]), sBlock[3]);
			ImplodeStrings(g_sData, sizeof(g_sData), "|", g_sInfo, sizeof(g_sInfo));//打包字符串.
			if(GetAdminStatus(sBlock[1]))
				LineArray.PushString(g_sInfo);
			else
				SiteArray.PushString(g_sInfo);
		}
	}
	file.Close();
}
//获取玩家列表.
void GetPlayerLists()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			char sName[32], sSteamId[32];
			GetClientName(i, sName, sizeof(sName));

			if(GetClientAuthId(i, AuthId_Steam2, sSteamId, sizeof(sSteamId)))
			{
				if(!GetPlayerStatus(sSteamId))
				{
					strcopy(g_sData[0], sizeof(g_sData[]), sName);
					strcopy(g_sData[1], sizeof(g_sData[]), "添加");
					strcopy(g_sData[2], sizeof(g_sData[]), sSteamId);
					strcopy(g_sData[3], sizeof(g_sData[]), g_sAuthority);
					ImplodeStrings(g_sData, sizeof(g_sData), "|", g_sInfo, sizeof(g_sInfo));//打包字符串.
					ListArray.PushString(g_sInfo);
				}
				
			}
			else
			{
				strcopy(g_sData[0], sizeof(g_sData[]), sName);
				strcopy(g_sData[1], sizeof(g_sData[]), "失败");
				strcopy(g_sData[2], sizeof(g_sData[]), sSteamId);
				strcopy(g_sData[3], sizeof(g_sData[]), g_sAuthority);
				ImplodeStrings(g_sData, sizeof(g_sData), "|", g_sInfo, sizeof(g_sInfo));//打包字符串.
				FailArray.PushString(g_sInfo);
			}
		}
	}
}
//判断游戏里的玩家是否已是管理员.
bool GetPlayerStatus(char[] sSteamId)
{
	int iNum[2];
	iNum[0] = LineArray.Length;
	iNum[1] = SiteArray.Length;
	char sData[128], sInfo[sizeof(g_sData)][128];

	if(iNum[0])
	{
		for (int i = 0; i < iNum[0]; i++) 
		{
			LineArray.GetString(i, sData, sizeof(sData));
			ExplodeString(sData, "|", sInfo, sizeof(sInfo), sizeof(sInfo[]));//拆分字符串.
			
			if(strcmp(sInfo[2], sSteamId, false) == 0)//对比字符串.
				return true;
		}
	}
	if(iNum[1])
	{
		for (int i = 0; i < iNum[1]; i++) 
		{
			SiteArray.GetString(i, sData, sizeof(sData));
			ExplodeString(sData, "|", sInfo, sizeof(sInfo), sizeof(sInfo[]));//拆分字符串.
			
			if(strcmp(sInfo[2], sSteamId, false) == 0)//对比字符串.
				return true;
		}
	}
	return false;
}

int MenuAdminListHandler(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[128], sInfo[sizeof(g_sData)][128];
			if(menu.GetItem(itemNum, sItem, sizeof(sItem)))
			{
				ExplodeString(sItem, "|", sInfo, sizeof(sInfo), sizeof(sInfo[]));//拆分字符串.

				if(strcmp(sInfo[1], "失败", false) == 0)
				{
					IsEditAdministrator(client, 0);
					PrintToChat(client, "\x04[提示]\x03%s\x05的SteamId获取失败(\x04Id为\x05:\x03%s\x05),不可添加.", sInfo[0], sInfo[2]);
				}
				else
					IsConfirmAction(client, sItem, menu.Selection);
			}
		}
		case MenuAction_End:
			delete menu;
	}
	return 0;
}

void IsConfirmAction(int client, char[] sItem, int g_iSelection)
{
	char line[128], sInfo[256], sPack[2][128], sData[sizeof(g_sData)][128];
	ExplodeString(sItem, "|", sData, sizeof(sData), sizeof(sData[]));//拆分字符串.
	Menu menu = new Menu(Menu_HandlerFunction);
	FormatEx(line, sizeof(line), "确认%s[%s]的权限[%s]?", strcmp(sData[1], "添加", false) == 0 ? "添加" : "删除", sData[0][0] != '\0' ? sData[0] : sData[2], sData[3]);
	strcopy(sPack[0], sizeof(sPack[]), sItem);
	IntToString(g_iSelection, sPack[1], sizeof(sPack[]));
	ImplodeStrings(sPack, sizeof(sPack), "‖", sInfo, sizeof(sInfo));//打包字符串.
	SetMenuTitle(menu, "%s", line);
	menu.AddItem(sInfo, "确认");
	menu.AddItem(sInfo, "返回");
	menu.ExitButton = false;//默认值:true,设置为:false,则不显示退出选项.
	//menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int Menu_HandlerFunction(Menu menu, MenuAction action, int client, int itemNum)
{
	switch(action)
	{
		case MenuAction_End:
			delete menu;
		case MenuAction_Select:
		{
			char sItem[256];
			if(menu.GetItem(itemNum, sItem, sizeof(sItem)))
			{
				char sInfo[2][256];
				ExplodeString(sItem, "‖", sInfo, sizeof(sInfo), sizeof(sInfo[]));//拆分字符串.
				if(itemNum <= 0)
					IsAddSteamIdAdmin(client, sInfo[0], StringToInt(sInfo[1]));
				else
					IsEditAdministrator(client, StringToInt(sInfo[1]));
			}
		}
	}
	return 0;
}
//写入管理员.
void IsAddSteamIdAdmin(int client, char[] sItem, int g_iSelection)
{
	char sInfo[sizeof(g_sData)][128];
	ExplodeString(sItem, "|", sInfo, sizeof(sInfo), sizeof(sInfo[]));//拆分字符串.
	char szFilePath[PLATFORM_MAX_PATH], szFileCopyPath[PLATFORM_MAX_PATH], szLine[256];
	BuildPath(Path_SM, szFilePath, sizeof(szFilePath), "configs/admins_simple.ini");
	
	if(strcmp(sInfo[1], "添加", false) == 0)
	{
		//用户可能会把文件最后一行的空行删除,所以写入管理员之前重新写一遍该文件.
		FormatEx(szFileCopyPath, sizeof(szFileCopyPath), "%s.copy", szFilePath);
		File fFile 		= OpenFile(szFilePath, "rt");
		File fTempFile	= OpenFile(szFileCopyPath, "wt");
		
		while(!fFile.EndOfFile())
		{
			if(!fFile.ReadLine(szLine, sizeof(szLine)))
				continue;

			TrimString(szLine);//整理字符串前后的空格.

			if(szLine[0] == '\0')//如果当前行是空行.
				continue;//如果是空行则不写入.
				
			fTempFile.WriteLine(szLine);
		}
		delete fFile;
		delete fTempFile;
		DeleteFile(szFilePath);//删除指定的文件
		RenameFile(szFilePath, szFileCopyPath);//重新命名文件
		//这里使用下一帧写入管理员.
		DataPack hPack = new DataPack();
		hPack.WriteCell(client);
		hPack.WriteCell(g_iSelection);
		hPack.WriteString(sItem);
		RequestFrame(IsWriteLine, hPack);
	}
	else
	{
		FormatEx(szFileCopyPath, sizeof(szFileCopyPath), "%s.copy", szFilePath);
		File fFile 		= OpenFile(szFilePath, "rt");
		File fTempFile	= OpenFile(szFileCopyPath, "wt");
		int target = GetPlayerUserId(sInfo[2]);

		while(!fFile.EndOfFile())
		{
			if(!fFile.ReadLine(szLine, sizeof(szLine)))
				continue;

			TrimString(szLine);

			if(StrContains(szLine, sInfo[0]) == -1)//对比字符串.
			{
				fTempFile.WriteLine(szLine);
				if(IsValidClient(target))// && client != target
					PrintHintText(target, "已删除你的管理员[%s].", sInfo[3]);
			}
		}
		delete fFile;
		delete fTempFile;
		DeleteFile(szFilePath);//删除指定的文件
		RenameFile(szFilePath, szFileCopyPath);//重新命名文件
		IsEditAdministrator(client, g_iSelection);//重新打开菜单.
	}
}

void IsWriteLine(DataPack hPack)
{
	char sItem[128], sInfo[sizeof(g_sData)][128];
	hPack.Reset();
	int  client = hPack.ReadCell();
	int  g_iSelection = hPack.ReadCell();
	hPack.ReadString(sItem, sizeof(sItem));
	ExplodeString(sItem, "|", sInfo, sizeof(sInfo), sizeof(sInfo[]));//拆分字符串.

	char szFilePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szFilePath, sizeof(szFilePath), "configs/admins_simple.ini");
	File fFile = OpenFile(szFilePath, "at");
	fFile.WriteLine("\"%s\"	\"%s\"	//%s", sInfo[2], sInfo[3], sInfo[0]);
	int target = GetPlayerUserId(sInfo[2]);
	if(IsValidClient(target))// && client != target
		PrintHintText(target, "已添加你为管理员[%s].", sInfo[3]);
	delete fFile;
	delete hPack;
	IsEditAdministrator(client, g_iSelection);//重新打开菜单.
}
/*
bool AcquirePlayerRights(char[] SteamId)
{
	for (int i = 0; i <= g_iBlockCmdsCount; i++)
		if (StrEqual(g_sBlockCmds[i], SteamId, false))
			return true;
	return false;
}
*/
bool GetAdminStatus(char[] sSteamId)
{
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && !IsFakeClient(i))
			if(strcmp(sSteamId, GetSteamId(i), false) == 0)
				return true;
	
	return false;
}

int GetPlayerUserId(char[] sSteamId)
{
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && !IsFakeClient(i))
			if(strcmp(sSteamId, GetSteamId(i), false) == 0)
				return i;
			
	return 0;
}

char[] GetPlayerName(char[] sSteamId)
{
	char sPlayerName[32];
	FormatEx(sPlayerName, sizeof(sPlayerName), "%N", GetPlayerUserId(sSteamId));
	return sPlayerName;
}

char[] GetSteamId(int client)
{
	char SteamId[32];
	GetClientAuthId(client, AuthId_Steam2, SteamId, sizeof(SteamId));
	return SteamId;
}

//判断玩家有效.
bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}
