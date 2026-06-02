#if defined _l4d_stats_admin_menu_included
	#endinput
#endif
#define _l4d_stats_admin_menu_included

// SourceMod 管理菜单入口和清库菜单。

// Load our categories and menus

public OnAdminMenuReady(Handle:TopMenu1)
{
	// Block us from being called twice
	if (TopMenu1 == RankAdminMenu)
		return;
/*
	RankAdminMenu = TopMenu;

	// Add a category to the SourceMod menu called "Player Stats"
	AddToTopMenu(RankAdminMenu, "玩家排名系统", TopMenuObject_Category, ClearRankCategoryHandler, INVALID_TOPMENUOBJECT);

	// Get a handle for the catagory we just added so we can add items to it
	new TopMenuObject:statscommands = FindTopMenuCategory(RankAdminMenu, "玩家排名系统");

	// Don't attempt to add items to the catagory if for some reason the catagory doesn't exist
	if (statscommands == INVALID_TOPMENUOBJECT)
		return;

	// The order that items are added to menus has no relation to the order that they appear. Items are sorted alphabetically automatically
	// Assign the menus to global values so we can easily check what a menu is when it is chosen
	MenuClearPlayers = AddToTopMenu(RankAdminMenu, "清除某个玩家统计记录", TopMenuObject_Item, ClearRankTopItemHandler, statscommands, "sm_rank_admin_clearplayers", ADMFLAG_ROOT);
	MenuClearMaps = AddToTopMenu(RankAdminMenu, "清除所有地图统计", TopMenuObject_Item, ClearRankTopItemHandler, statscommands, "sm_rank_admin_clearallmaps", ADMFLAG_ROOT);
	MenuClearAll = AddToTopMenu(RankAdminMenu, "清除所有", TopMenuObject_Item, ClearRankTopItemHandler, statscommands, "sm_rank_admin_clearall", ADMFLAG_ROOT);
	MenuClearTimedMaps = AddToTopMenu(RankAdminMenu, "清除所有地图时间统计数据", TopMenuObject_Item, ClearRankTopItemHandler, statscommands, "sm_rank_admin_cleartimedmaps", ADMFLAG_ROOT);
	MenuRemoveCustomMaps = AddToTopMenu(RankAdminMenu, "清除自定义地图", TopMenuObject_Item, ClearRankTopItemHandler, statscommands, "sm_rank_admin_removecustom", ADMFLAG_ROOT);
	MenuCleanPlayers = AddToTopMenu(RankAdminMenu, "清除玩家数据", TopMenuObject_Item, ClearRankTopItemHandler, statscommands, "sm_rank_admin_removeplayers", ADMFLAG_ROOT);
	MenuClear = AddToTopMenu(RankAdminMenu, "管理员清除", TopMenuObject_Item, ClearRankTopItemHandler, statscommands, "sm_rank_admin_clear", ADMFLAG_ROOT);
	*/
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
		RankAdminMenu = INVALID_HANDLE;
	if ( StrEqual(name, "rpg") ) { g_brpgAvailable = false; }
}

public void OnAllPluginsLoaded()
{
	g_brpgAvailable = LibraryExists("rpg");
}


public void OnLibraryAdded(const char[] name)
{
    if ( StrEqual(name, "rpg") ) { g_brpgAvailable = true; }
}
// This handles the top level "Player Stats" category and how it is displayed on the core admin menu

public ClearRankCategoryHandler(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, client, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "玩家排名系统");
	else if (action == TopMenuAction_DisplayTitle)
		Format(buffer, maxlength, "玩家排名系统");
}

public Action:Menu_CreateClearMenu(client, args)
{
	new Handle:menu = CreateMenu(Menu_CreateClearMenuHandler);

	SetMenuTitle(menu, "清除:");
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);

	AddMenuItem(menu, "cps", "清除正在游玩玩家的记录");
	AddMenuItem(menu, "ctm", "清除已记录的地图时间数据");

	DisplayMenu(menu, client, 30);

	return Plugin_Handled;
}

public Menu_CreateClearMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			switch (param2)
			{
				case 0:
				{
					DisplayClearPanel(param1);
				}
				case 1:
				{
					Menu_CreateClearTMMenu(param1, 0);
				}
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && RankAdminMenu != INVALID_HANDLE)
				DisplayTopMenu(RankAdminMenu, param1, TopMenuPosition_LastCategory);
		}
	}
}

public Action:Menu_CreateClearTMMenu(client, args)
{
	new Handle:menu = CreateMenu(Menu_CreateClearTMMenuHandler);

	SetMenuTitle(menu, "清除已记录的地图:");
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);

	AddMenuItem(menu, "ctma",  "所有");
	AddMenuItem(menu, "ctmc",  "战役");
	AddMenuItem(menu, "ctmsu", "生存");
	AddMenuItem(menu, "ctmr",  "写实");
	AddMenuItem(menu, "ctmm",  "突变");

	DisplayMenu(menu, client, 30);

	return Plugin_Handled;
}

public Menu_CreateClearTMMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			switch (param2)
			{
				case 0:
				{
					DisplayYesNoPanel(param1, "你想清除地图记录数据统计吗?", ClearTMAllPanelHandler);
				}
				case 1:
				{
					DisplayYesNoPanel(param1, "你想清除所有战役游戏模式的地图记录统计吗?", ClearTMCoopPanelHandler);
				}
				case 2:
				{
					DisplayYesNoPanel(param1, "你想清除所有生存的地图记录统计吗?", ClearTMSurvivalPanelHandler);
				}
				case 3:
				{
					DisplayYesNoPanel(param1, "你想清除所有写实游戏模式的地图记录统计吗?", ClearTMRealismPanelHandler);
				}
				case 4:
				{
					DisplayYesNoPanel(param1, "你想清除所有突变游戏模式的地图记录统计吗?", ClearTMMutationsPanelHandler);
				}
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && RankAdminMenu != INVALID_HANDLE)
			{
				DisplayTopMenu(RankAdminMenu, param1, TopMenuPosition_LastCategory);
			}
		}
	}
}

// This deals with what happens someone opens the "Player Stats" category from the menu
public ClearRankTopItemHandler(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, client, String:buffer[], maxlength)
{
	// When an item is displayed to a player tell the menu to format the item
	if (action == TopMenuAction_DisplayOption)
	{
		if (object_id == MenuClearPlayers)
		{
			Format(buffer, maxlength, "清除玩家");
		}
		else if (object_id == MenuClearMaps)
		{
			Format(buffer, maxlength, "清除地图");
		}
		else if (object_id == MenuClearAll)
		{
			Format(buffer, maxlength, "清除所有");
		}
		else if (object_id == MenuClearTimedMaps)
		{
			Format(buffer, maxlength, "清除已经记录的时间");
		}
		else if (object_id == MenuRemoveCustomMaps)
		{
			Format(buffer, maxlength, "移除三方地图统计");
		}
		else if (object_id == MenuCleanPlayers)
		{
			Format(buffer, maxlength, "清除玩家");
		}
		else if (object_id == MenuClear)
		{
			Format(buffer, maxlength, "更多");
		}
	}

	// When an item is selected do the following
	else if (action == TopMenuAction_SelectOption)
	{
		if (object_id == MenuClearPlayers)
		{
			DisplayYesNoPanel(client, "你真的想清除这个玩家的玩家记录吗?", ClearPlayersPanelHandler);
		}
		else if (object_id == MenuClearMaps)
		{
			DisplayYesNoPanel(client, "你真的想清除这个玩家的所有地图的统计记录吗?", ClearMapsPanelHandler);
		}
		else if (object_id == MenuClearAll)
		{
			DisplayYesNoPanel(client, "你真的想清除所有玩家的统计记录吗?", ClearAllPanelHandler);
		}
		else if (object_id == MenuClearTimedMaps)
		{
			DisplayYesNoPanel(client, "你真的想清除所有玩家的地图纪律吗?", ClearTMAllPanelHandler);
		}
		else if (object_id == MenuRemoveCustomMaps)
		{
			DisplayYesNoPanel(client, "你真的想去除这张三方地图的统计吗?", RemoveCustomMapsPanelHandler);
		}
		else if (object_id == MenuCleanPlayers)
		{
			DisplayYesNoPanel(client, "你真的想清除这名玩家的游玩记录吗?", CleanPlayersPanelHandler);
		}
		else if (object_id == MenuClear)
		{
			Menu_CreateClearMenu(client, 0);
		}
	}
}
