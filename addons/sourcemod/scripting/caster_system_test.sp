#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <colors>

#undef REQUIRE_PLUGIN
#include <caster_system>
#define REQUIRE_PLUGIN

#define STEAMID2_LENGTH 32
#define PREFIX_TEST		"[{olive}Test{default}]"

bool
	g_bLateload,
	g_bCasterSystem;

enum eTypeList
{
	kCaster = 0,
	kWhite	= 1,
	kSQL	= 2
}

enum L4DTeam
{
	L4DTeam_Unassigned = 0,
	L4DTeam_Spectator  = 1,
	L4DTeam_Survivor   = 2,
	L4DTeam_Infected   = 3
}

public Plugin g_myInfo = {
	name		= "L4D2 Caster System Test",
	author		= "lechuga",
	description = "Testing native and forward",
	version		= "1.0",
	url			= "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErr_max)
{
	g_bLateload = bLate;
	return APLRes_Success;
}

public void OnAllPluginsLoaded()
{
	g_bCasterSystem = LibraryExists("caster_system");
}

public void OnLibraryAdded(const char[] sPluginName)
{
	if (StrEqual(sPluginName, "caster_system"))
		g_bCasterSystem = true;
}

public void OnLibraryRemoved(const char[] sPluginName)
{
	if (StrEqual(sPluginName, "caster_system"))
		g_bCasterSystem = false;
}

public void OnPluginStart()
{
	vLoadTranslation("common.phrases");
	vLoadTranslation("caster_system.phrases");

	RegConsoleCmd("sm_tcaster", aTcasterRegCmd, "Registers a player to the caster list");
	RegConsoleCmd("sm_tcaster_rm", aTcasterRemoveCmd, "Removes a player from the caster list");

	RegConsoleCmd("sm_tcaster_wl", aTwhitelistRegCmd, "Adds a player to the whitelist");
	RegConsoleCmd("sm_tcaster_wl_rm", aTwhitelistRemoveCmd, "Removes a player from the whitelist");

	if (!g_bLateload)
		return;

	g_bCasterSystem = LibraryExists("caster_system");
}

Action aTcasterRegCmd(int iClient, int iArgs)
{
	if (!g_bCasterSystem)
	{
		CPrintToChatAll("%s {red}Caster System{default} is not loaded", PREFIX_TEST);
		return Plugin_Handled;
	}

	ReplySource eRsCmd = GetCmdReplySource();
	if (iArgs == 0)
	{
		if (eRsCmd == SM_REPLY_TO_CHAT && iClient != SERVER_INDEX)
			vDisplayRegMenu(iClient, kCaster);
		else
			CReplyToCommand(iClient, "%s %t: sm_tcaster <#userid|name|steamid>", PREFIX_TEST, "Use");
		return Plugin_Handled;
	}

	char szArguments[64];
	GetCmdArgString(szArguments, sizeof(szArguments));

	char szArg[STEAMID2_LENGTH];
	BreakString(szArguments, szArg, sizeof(szArg));

	vProcessReg(iClient, szArg, kCaster);

	return Plugin_Handled;
}

Action aTwhitelistRegCmd(int iClient, int iArgs)
{
	if (!g_bCasterSystem)
	{
		CPrintToChatAll("%s {red}Caster System{default} is not loaded", PREFIX_TEST);
		return Plugin_Handled;
	}

	ReplySource eRsCmd = GetCmdReplySource();
	if (iArgs == 0)
	{
		if (eRsCmd == SM_REPLY_TO_CHAT && iClient != SERVER_INDEX)
			vDisplayRegMenu(iClient, kWhite);
		else
			CReplyToCommand(iClient, "%s %t: sm_tcaster_wl <#userid|name|steamid>", PREFIX_TEST, "Use");
		return Plugin_Handled;
	}

	char szArguments[64];
	GetCmdArgString(szArguments, sizeof(szArguments));

	char szArg[STEAMID2_LENGTH];
	BreakString(szArguments, szArg, sizeof(szArg));

	vProcessReg(iClient, szArg, kWhite);

	return Plugin_Handled;
}

/**
 * Processes the registration of a client based on the provided argument.
 *
 * @param iClient       The client index who initiated the registration.
 * @param szArg         The argument provided for registration, which can be a Steam ID or a target name.
 * @param eTypeList     The type list enumeration specifying the type of registration.
 *
 * If the provided argument is a Steam ID, the client is registered directly using the Steam ID.
 * If the provided argument is a target name, the function attempts to find the target client and register them.
 * If the target client is not found or their Steam ID cannot be retrieved, an error message is sent to the client.
 */
void vProcessReg(int iClient, const char[] szArg, eTypeList eList)
{
	if (bIsSteamId(szArg))
	{
		vRegister(iClient, NO_INDEX, szArg, szArg, eList, kAuth);
		return;
	}

	int iTarget = FindTarget(iClient, szArg, true, false);
	if (iTarget == NO_INDEX)
		return;

	char szAuthId[STEAMID2_LENGTH];
	if (!GetClientAuthId(iTarget, AuthId_Steam2, szAuthId, sizeof(szAuthId)))
	{
		CReplyToCommand(iClient, "%t %t", "Prefix", "AuthIdError", szAuthId);
		return;
	}

	char szName[16];
	GetClientName(iTarget, szName, sizeof(szName));
	vRegister(iClient, iTarget, szAuthId, szName, eList, kClient);
}

void vDisplayRegMenu(int iClient, eTypeList eList)
{
	Menu hMenu;
	hMenu = new Menu(iRegMenuHandler);
	char szTitle[100];
	Format(szTitle, sizeof(szTitle), "%t", "MenuPlayersList");
	hMenu.SetTitle(szTitle);
	vListTargets(hMenu, eList);

	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

/**
 * Populates a menu with a list of clients based on the specified type list.
 *
 * @param hMenu        The menu handle to which the clients will be added.
 * @param eTypeList    The type of list to populate (e.g., kCaster, kWhite).
 *
 * This function iterates through all connected clients and adds them to the provided menu.
 * It constructs an identifier for each client and appends the specified type list to it.
 * Depending on the type list, it checks if the client is a caster or in the whitelist and
 * adds them to the menu accordingly, disabling the item if they meet the criteria.
 *
 * The function skips clients that are not connected, are fake clients, or if their name or
 * Steam ID cannot be retrieved.
 */
void vListTargets(Menu hMenu, eTypeList eList)
{
	char szName[64], szBuffer[16], szAuthId[STEAMID2_LENGTH];
	int	 iUserId;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientConnected(i) || IsFakeClient(i))
			continue;

		if (!GetClientName(i, szName, sizeof(szName)))
			continue;

		if (!GetClientAuthId(i, AuthId_Steam2, szAuthId, sizeof(szAuthId)))
			continue;

		// Construct an identifier and add the eTypeList to it
		iUserId = GetClientUserId(i);
		Format(szBuffer, sizeof(szBuffer), "%d:%d", iUserId, view_as<int>(eList));

		bool bIsCaster = (eList == kCaster) ? bCaster(kClient, kGet, i, szAuthId) : bCasterWhitelist(kClient, kGet, i, szAuthId);
		hMenu.AddItem(szBuffer, szName, bIsCaster ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	}
}

public int iRegMenuHandler(Menu hMenu, MenuAction eAction, int iClient, int iItem)
{
	switch (eAction)
	{
		case MenuAction_Select:
		{
			char szInfo[32], szName[32];
			int	 iUserId, iTarget;

			hMenu.GetItem(iItem, szInfo, sizeof(szInfo), _, szName, sizeof(szName));

			char szPart1[16], szPart2[16];
			int	 iIndex;

			iIndex = SplitString(szInfo, ":", szPart1, sizeof(szPart1));
			if (iIndex != -1)
				SplitString(szInfo[iIndex], ":", szPart2, sizeof(szPart2));

			int iPart1		= StringToInt(szPart1);
			int iPart2		= StringToInt(szPart2);

			iUserId			= iPart1;
			eTypeList eList = view_as<eTypeList>(iPart2);

			if ((iTarget = GetClientOfUserId(iUserId)) == SERVER_INDEX)
				CPrintToChat(iClient, "%t %t", "Prefix", "Player no longer available");
			else if (!CanUserTarget(iClient, iTarget))
				CPrintToChat(iClient, "%t %t", "Prefix", "Unable to target");
			else
			{
				char szAuthId[STEAMID2_LENGTH];
				if (!GetClientAuthId(iTarget, AuthId_Steam2, szAuthId, sizeof(szAuthId)))
				{
					CReplyToCommand(iClient, "%t %t", "Prefix", "AuthIdError", szAuthId);
					return 0;
				}

				char szTargetName[16];
				GetClientName(iTarget, szTargetName, sizeof(szTargetName));

				vRegister(iClient, iTarget, szAuthId, szTargetName, eList, kClient);
			}
		}
		case MenuAction_End:
		{
			delete hMenu;
		}
	}
	return 0;
}

/**
 * Registers a client or target with the specified type and ID.
 *
 * @param iClient       The client index initiating the registration.
 * @param iTarget       The target index to be registered.
 * @param szAuthId      The authentication ID of the target.
 * @param szDisplayName The display name of the target.
 * @param eTypeList     The type list indicating the registration type.
 * @param eTypeID       The type ID for the registration.
 */
void vRegister(int iClient, int iTarget, const char[] szAuthId, const char[] szDisplayName, eTypeList eList, eTypeID eId)
{
	bool bIndex = (eId == kClient);
	bool bFound = false;

	switch (eList)
	{
		case kCaster:
			bFound = bIndex ? bCaster(eId, kGet, iTarget, szAuthId) : bCaster(eId, kGet, NO_INDEX, szAuthId);
		case kWhite:
			bFound = bIndex ? bCasterWhitelist(eId, kGet, iTarget, szAuthId) : bCasterWhitelist(eId, kGet, NO_INDEX, szAuthId);
	}

	if (bFound)
	{
		CReplyToCommand(iClient, "%t %t", "Prefix", eList == kCaster ? "CasterFound" : "WhitelistFound", szDisplayName);
		return;
	}

	switch (eList)
	{
		case kCaster:
			bCaster(eId, kSet, iTarget, szAuthId);
		case kWhite:
			bCasterWhitelist(eId, kSet, iTarget, szAuthId);
	}
}

Action aTcasterRemoveCmd(int iClient, int iArgs)
{
	ReplySource eRsCmd = GetCmdReplySource();
	if (iArgs == 0)
	{
		if (eRsCmd == SM_REPLY_TO_CHAT && iClient != SERVER_INDEX)
			vDisplayRemoveMenu(iClient, kCaster);
		else
			CReplyToCommand(iClient, "%t %t: sm_tcaster_rm <#userid|name|steamid>", "Prefix", "Use");
		return Plugin_Handled;
	}

	char szArguments[64];
	GetCmdArgString(szArguments, sizeof(szArguments));

	char szArg[STEAMID2_LENGTH];
	BreakString(szArguments, szArg, sizeof(szArg));

	vProcessRemove(iClient, szArg, kCaster);
	return Plugin_Handled;
}

Action aTwhitelistRemoveCmd(int iClient, int iArgs)
{
	ReplySource eRsCmd = GetCmdReplySource();
	if (iArgs == 0)
	{
		if (eRsCmd == SM_REPLY_TO_CHAT && iClient != SERVER_INDEX)
			vDisplayRemoveMenu(iClient, kWhite);
		else
			CReplyToCommand(iClient, "%t %t: sm_tcaster_wl_rm <#userid|name|steamid>", "Prefix", "Use");
		return Plugin_Handled;
	}

	char szArguments[64];
	GetCmdArgString(szArguments, sizeof(szArguments));

	char szArg[STEAMID2_LENGTH];
	BreakString(szArguments, szArg, sizeof(szArg));

	vProcessRemove(iClient, szArg, kWhite);
	return Plugin_Handled;
}

/**
 * Processes the removal of a client from a specified list.
 *
 * @param iClient The client index initiating the removal.
 * @param szArg The argument provided, which can be a Steam ID or a target name.
 * @param eList The list type from which the client should be removed.
 *
 * If the provided argument is a Steam ID, it directly calls the removal function.
 * Otherwise, it attempts to find the target client by name and retrieves their Steam ID.
 * If the Steam ID retrieval fails, it sends an error message to the initiating client.
 * Finally, it calls the removal function with the appropriate parameters.
 */
void vProcessRemove(int iClient, const char[] szArg, eTypeList eList)
{
	if (bIsSteamId(szArg))
	{
		vRemove(iClient, NO_INDEX, szArg, szArg, eList, kAuth);
		return;
	}

	int iTarget = FindTarget(iClient, szArg, true, false);
	if (iTarget == NO_INDEX)
		return;

	char szAuthId[STEAMID2_LENGTH];
	if (!GetClientAuthId(iTarget, AuthId_Steam2, szAuthId, sizeof(szAuthId)))
	{
		CReplyToCommand(iClient, "%t %t", "Prefix", "AuthIdError", szAuthId);
		return;
	}

	char szName[16];
	GetClientName(iTarget, szName, sizeof(szName));
	vRemove(iClient, iTarget, szAuthId, szName, eList, kClient);
}

/**
 * Removes a client from the specified list.
 *
 * @param iClient       The client index who initiated the removal.
 * @param iTarget       The client index of the target to remove.
 * @param szAuthId      The Steam ID of the target client.
 * @param szDisplayName The display name of the target client.
 * @param eList         The type list from which the client should be removed.
 * @param eId           The type ID to determine the removal operation.
 *
 * The function constructs a message to display to the initiating client and the target client.
 * It then calls the removal function with the appropriate parameters based on the type list.
 * If the removal operation fails, an error message is sent to the initiating client.
 */
void vRemove(int iClient, int iTarget, const char[] szAuthId, const char[] szDisplayName, eTypeList eList, eTypeID eId)
{
	bool bIndex = (iTarget > SERVER_INDEX);
	bool bFound = false;

	switch (eList)
	{
		case kCaster:
			bFound = bIndex ? bCaster(eId, kGet, iTarget, szAuthId) : bCaster(eId, kGet, NO_INDEX, szAuthId);
		case kWhite:
			bFound = bIndex ? bCasterWhitelist(eId, kGet, iTarget, szAuthId) : bCasterWhitelist(eId, kGet, NO_INDEX, szAuthId);
	}

	if (!bFound)
	{
		CReplyToCommand(iClient, "%t %t", "Prefix", eList == kCaster ? "CasterNoFound" : "WhitelistNoFound", szDisplayName);
		return;
	}

	switch (eList)
	{
		case kCaster:
			bCaster(eId, kRem, iTarget, szAuthId);
		case kWhite:
			bCasterWhitelist(eId, kRem, iTarget, szAuthId);
	}
}

void vDisplayRemoveMenu(int iClient, eTypeList eList)
{
	char szTitle[100];
	switch (eList)
	{
		case kCaster:
			Format(szTitle, sizeof(szTitle), "%T", "MenuCastersList", iClient);
		case kWhite:
			Format(szTitle, sizeof(szTitle), "%T", "MenuWhitelistList", iClient);
	}

	Menu hMenu = new Menu(iMenuRemove);
	hMenu.SetTitle(szTitle);
	vRemoveTargets(hMenu, eList, iClient);

	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

/**
 * Removes targets from the specified menu based on the given type list.
 *
 * @param hMenu        The menu handle to which the targets will be added.
 * @param eList        The type list to determine which targets to remove.
 * @param iClient      The client index who initiated the removal.
 *
 * This function iterates through all connected clients, checks if they match
 * the criteria specified by the type list, and adds them to the menu if they do.
 * If no targets are found, a message indicating no targets to remove is added
 * to the menu.
 */
void vRemoveTargets(Menu hMenu, eTypeList eList, int iClient)
{
	char
		szName[64],
		szInfo[16],
		szAuthId[STEAMID2_LENGTH];

	bool
		bFound;

	int
		iTargets = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientConnected(i) || IsFakeClient(i))
			continue;

		if (!GetClientName(i, szName, sizeof(szName)))
			continue;

		if (!GetClientAuthId(i, AuthId_Steam2, szAuthId, sizeof(szAuthId)))
			continue;

		Format(szInfo, sizeof(szInfo), "%d:%d", GetClientUserId(i), view_as<int>(eList));

		switch (eList)
		{
			case kCaster:
				bFound = bCaster(kClient, kGet, i, szAuthId);
			case kWhite:
				bFound = bCasterWhitelist(kClient, kGet, i, szAuthId);
		}

		if (bFound)
		{
			hMenu.AddItem(szInfo, szName);
			iTargets++;
		}
	}

	if (iTargets == 0)
	{
		char szMsj[64];
		Format(szMsj, sizeof(szMsj), "%T", "NoTargetsToRemove", iClient);
		hMenu.AddItem("", szMsj, ITEMDRAW_DISABLED);
	}
}

public int iMenuRemove(Menu hMenu, MenuAction eAction, int iClient, int iItem)
{
	if (eAction == MenuAction_Select)
	{
		char
			szInfo[32],
			szName[32],
			szPart1[16],
			szPart2[16];

		int
			iIndex,
			iUserId,
			iTarget;

		eTypeList
			eList;

		hMenu.GetItem(iItem, szInfo, sizeof(szInfo), _, szName, sizeof(szName));

		iIndex = SplitString(szInfo, ":", szPart1, sizeof(szPart1));
		SplitString(szInfo[iIndex], ":", szPart2, sizeof(szPart2));

		iUserId = StringToInt(szPart1);
		eList	= view_as<eTypeList>(StringToInt(szPart2));

		if ((iTarget = GetClientOfUserId(iUserId)) == SERVER_INDEX)
			CPrintToChat(iClient, "%t %t", "Prefix", "Player no longer available");
		else
		{
			char szAuthId[STEAMID2_LENGTH];
			if (!GetClientAuthId(iTarget, AuthId_Steam2, szAuthId, sizeof(szAuthId)))
			{
				CReplyToCommand(iClient, "%t %t", "Prefix", "AuthIdError", szAuthId);
				return 0;
			}

			vRemove(iClient, iTarget, szAuthId, szName, eList, kClient);
		}
	}
	else if (eAction == MenuAction_End)
		delete hMenu;
	return 0;
}

public void OnCaster(eTypeID eID, int iClient, const char[] szAuthId)
{
	switch (eID)
	{
		case kClient:
		{
			LogMessage("[OnCaster] eTypeID: %d | iClient: %N", eID, iClient);
			CPrintToChatAll("%s {blue}%N{default} was registered as a caster", PREFIX_TEST, iClient);
		}
		case kAuth:
		{
			LogMessage("[OnCaster] eTypeID: %d | szAuthId: %s", eID, szAuthId);
			CPrintToChatAll("%s {blue}%s{default} was registered as a caster", PREFIX_TEST, szAuthId);
		}
	}
}

public void OffCaster(eTypeID eID, int iClient, const char[] szAuthId)
{
	switch (eID)
	{
		case kClient:
		{
			LogMessage("[OffCaster] eTypeID: %d | iClient: %N", eID, iClient);
			CPrintToChatAll("%s {red}%N{default} was removed from the casters list", PREFIX_TEST, iClient);
		}
		case kAuth:
		{
			LogMessage("[OffCaster] eTypeID: %d | szAuthId: %s", eID, szAuthId);
			CPrintToChatAll("%s {red}%s{default} was removed from the casters list", PREFIX_TEST, szAuthId);
		}
	}
}

/**
 * Returns the clients team using L4DTeam.
 *
 * @param client		Player's index.
 * @return				Current L4DTeam of player.
 * @error				Invalid client index.
 */
stock L4DTeam L4D_GetClientTeam(int client)
{
	int team = GetClientTeam(client);
	return view_as<L4DTeam>(team);
}

/**
 * @brief Checks if a given string is a valid Steam ID.
 *
 * This function verifies if the provided string follows the format of a Steam ID.
 * A valid Steam ID should start with "STEAM_" and contain two colons separating
 * three numerical components.
 *
 * @param szAuthId The string to be checked.
 * @return True if the string is a valid Steam ID, false otherwise.
 */
bool bIsSteamId(const char[] szAuthId)
{
	if (strlen(szAuthId) == 0)
		return false;

	if (StrContains(szAuthId, "STEAM_") != 0)
		return false;

	int iPos1 = FindCharInString(szAuthId, ':');
	if (iPos1 == NO_INDEX)
		return false;

	int iPos2 = FindCharInString(szAuthId, ':', view_as<bool>(iPos1 + 1));
	if (iPos2 == NO_INDEX)
		return false;

	char szUniverse[8];
	char szAuth[8];
	char szAccount[16];

	int	 iLenUniverse = iPos1 - 6;
	if (iLenUniverse <= 0 || iLenUniverse >= sizeof(szUniverse))
		return false;

	for (int i = 0; i < iLenUniverse; i++)
	{
		szUniverse[i] = szAuthId[6 + i];
	}
	szUniverse[iLenUniverse] = '\0';

	int iLenAuth			 = iPos2 - iPos1 - 1;
	if (iLenAuth <= 0 || iLenAuth >= sizeof(szAuth))
		return false;

	for (int i = 0; i < iLenAuth; i++)
	{
		szAuth[i] = szAuthId[iPos1 + 1 + i];
	}
	szAuth[iLenAuth] = '\0';

	int iLenAccount	 = strlen(szAuthId) - iPos2 - 1;
	if (iLenAccount <= 0 || iLenAccount >= sizeof(szAccount))
		return false;

	for (int i = 0; i < iLenAccount; i++)
	{
		szAccount[i] = szAuthId[iPos2 + 1 + i];
	}
	szAccount[iLenAccount] = '\0';

	if (!bIsInteger(szUniverse) || !bIsInteger(szAuth) || !bIsInteger(szAccount))
		return false;

	return true;
}

/**
 * @brief Checks if the given string represents an integer.
 *
 * This function iterates through each character of the input string and
 * verifies if all characters are numeric.
 *
 * @param szString The string to be checked.
 * @return True if the string represents an integer, false otherwise.
 */
bool bIsInteger(const char[] szString)
{
	int iLen = strlen(szString);
	for (int i = 0; i < iLen; i++)
	{
		if (!IsCharNumeric(szString[i]))
			return false;
	}
	return true;
}

/**
 * Check if the translation file exists
 *
 * @param szTranslation   Translation name.
 * @noreturn
 */
stock void vLoadTranslation(const char[] szTranslation)
{
	char szPath[PLATFORM_MAX_PATH],
		szName[64];

	Format(szName, sizeof(szName), "translations/%s.txt", szTranslation);
	BuildPath(Path_SM, szPath, sizeof(szPath), szName);
	if (!FileExists(szPath))
		SetFailState("Missing translation file %s.txt", szTranslation);

	LoadTranslations(szTranslation);
}