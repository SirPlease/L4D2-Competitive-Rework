#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools_client>
#include <builtinvotes>
#include <colors>
#include <left4dhooks>

#define DEBUG_SQL		0
#define DEBUG_VALUE		0
#define DEBUG_API		0

#define PLUGIN_VERSION	"2.0"
#define STEAMID2_LENGTH 32

enum eTypeID
{
	kClient = 0,
	kAuth	= 1,
}

enum eTypeAction
{
	kGet = 0,
	kSet = 1,
	kRem = 2
}

enum eTypeList
{
	kCaster = 0,
	kWhite	= 1,
	kSQL	= 2
}

StringMap
	g_smCaster,
	g_smWhitelist,
	g_smSpecInmunity;

ConVar
	g_cvAddonsEnable,
	g_cvKickSpecInmunity,
	g_cvSefRegEnable,
	g_cvSQLEnable,
	g_cvSQLServerID,
	g_cvWhitelistEnable;

bool
	g_bSQLConnected,
	g_bSQLTableExists;

enum eSQLDriver
{
	kMySQL	= 0,
	kSQLite = 1,
}

Database
	g_hDatabase;

eSQLDriver
	g_iSQLDriver;

int
	g_iDummy;

char
	g_szTable[] = "caster_whitelist";

GlobalForward
	g_gfOnCaster,
	g_gfOffCaster;

public Plugin g_myInfo = {
	name		= "L4D2 Caster System",
	author		= "CanadaRox, Forgetest, lechuga",
	description = "Standalone caster handler.",
	version		= PLUGIN_VERSION,
	url			= "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] szError, int iErrMax)
{
	g_gfOnCaster  = CreateGlobalForward("OnCaster", ET_Ignore, Param_Cell, Param_Cell, Param_String);
	g_gfOffCaster = CreateGlobalForward("OffCaster", ET_Ignore, Param_Cell, Param_Cell, Param_String);

	CreateNative("bCaster", iCasterNative);
	CreateNative("bCasterWhitelist", iWhitelistNative);
	CreateNative("bKickSpecInmunity", iInmunityNative);

	RegPluginLibrary("caster_system");
	return APLRes_Success;
}

public void OnPluginStart()
{
	vLoadTranslation("common.phrases");
	vLoadTranslation("caster_system.phrases");

	g_smCaster		 = new StringMap();
	g_smWhitelist	 = new StringMap();
	g_smSpecInmunity = new StringMap();

	CreateConVar("caster_version", PLUGIN_VERSION, "Caster System Version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_cvWhitelistEnable	 = CreateConVar("caster_whitelist", "1", "Enable Whitelist, if deactivated, everyone will be able to register as a caster", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvSefRegEnable	 = CreateConVar("caster_selfreg", "1", "Enables self-registration, it is limited to the user being registered on the whitelist.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvKickSpecInmunity = CreateConVar("caster_kickspecs_inmunity", "1", "Enable Kick Spec Inmunity", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvAddonsEnable	 = CreateConVar("caster_addons", "1", "Enable caster addons", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvSQLEnable		 = CreateConVar("caster_sql", "0", "Enable Whitelist SQL", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvSQLServerID		 = CreateConVar("caster_sql_serverid", "0", "Server ID, if it is set to 0 it will be disabled", FCVAR_NOTIFY, true, 0.0);

	g_cvSQLEnable.AddChangeHook(vOnSQLSettingChanged);
	g_cvAddonsEnable.AddChangeHook(vOnAddonsSettingChanged);

	RegAdminCmd("sm_caster", aCasterRegCmd, ADMFLAG_BAN, "Registers a player to the caster list");
	RegAdminCmd("sm_caster_ls", aCasterListCmd, ADMFLAG_BAN, "Prints the list of casters");
	RegAdminCmd("sm_caster_rm", aCasterRemoveCmd, ADMFLAG_BAN, "Removes a player from the caster list");
	RegAdminCmd("sm_caster_rs", aCasterResetCmd, ADMFLAG_BAN, "Clears the entire caster list");

	RegAdminCmd("sm_caster_wl", aWhitelistRegCmd, ADMFLAG_BAN, "Adds a player to the whitelist");
	RegAdminCmd("sm_caster_wl_ls", aWhitelistListCmd, ADMFLAG_BAN, "Prints the whitelist");
	RegAdminCmd("sm_caster_wl_rm", aWhitelistRemoveCmd, ADMFLAG_BAN, "Removes a player from the whitelist");
	RegAdminCmd("sm_caster_wl_rs", aWhitelistResetCmd, ADMFLAG_BAN, "Clears the entire whitelist");

	RegAdminCmd("sm_caster_sql", aSQLRegCmd, ADMFLAG_BAN, "Adds a player to the database whitelist");
	RegAdminCmd("sm_caster_sql_ls", aSQLListCmd, ADMFLAG_BAN, "Downloads and prints the database whitelist");
	RegAdminCmd("sm_caster_sql_rm", aSQLRemoveCmd, ADMFLAG_BAN, "Removes a player from the database whitelist");
	RegAdminCmd("sm_caster_sql_rs", aSQLResetCmd, ADMFLAG_BAN, "Clears the entire database whitelist");
	RegAdminCmd("sm_caster_sql_cache", aSQLCacheCmd, ADMFLAG_BAN, "Downloads the database whitelist");

	RegConsoleCmd("sm_cast", aSelfRegCastCmd, "Registers the calling player as a caster");
	RegConsoleCmd("sm_uncast", aSelfRemoveCastCmd, "Deregister yourself as a caster or allow admins to deregister other players");
	RegConsoleCmd("sm_kickspecs", aKickSpecsCmd, "Let's vote to kick those Spectators!");

	HookEvent("player_team", vPlayerTeamEvent);

	AutoExecConfig(true, "caster_system");
}

// ========================
//  Natives
// ========================

/**
 * @brief Add, checks or remove a user from the Casters list.
 *
 * @param eTypeID       Defines how the client will be identified.
 * @param eTypeAction   What action will be taken.
 * @param iClient       Required only if eTypeID is kClient, otherwise set it to -1.
 * @param szAuthId      Required only if eTypeID is kAuth, otherwise it is not necessary to define it.
 * @return              True if the client or AuthID is a caster (for Get action), false otherwise.
 */
int iCasterNative(Handle hPlugin, int iNumParams)
{
	eTypeID		eID		= GetNativeCell(1);
	eTypeAction eAction = GetNativeCell(2);
	int			iTarget = GetNativeCell(3);
	char		szAuthId[STEAMID2_LENGTH];
	GetNativeString(4, szAuthId, sizeof(szAuthId));

#if DEBUG_API
	LogMessage("[iCasterNative] eTypeID: %d | eTypeAction: %d | iClient: %d | szAuthId: %s", eID, eAction, iTarget, szAuthId);
#endif

	switch (eAction)
	{
		case kGet:
			return g_smCaster.GetValue(szAuthId, g_iDummy);
		case kSet:
		{
			switch (eID)
			{
				case kClient:
				{
					char szName[32];
					GetClientName(iTarget, szName, sizeof(szName));
					vRegister(SERVER_INDEX, iTarget, szAuthId, szName, kCaster, eID, SM_REPLY_TO_CONSOLE);
				}
				case kAuth:
					vRegister(SERVER_INDEX, NO_INDEX, szAuthId, szAuthId, kCaster, eID, SM_REPLY_TO_CONSOLE);
			}
		}
		case kRem:
		{
			switch (eID)
			{
				case kClient:
				{
					char szName[32];
					GetClientName(iTarget, szName, sizeof(szName));
					vRemove(SERVER_INDEX, iTarget, szAuthId, szName, kCaster, eID, SM_REPLY_TO_CONSOLE);
				}
				case kAuth:
					vRemove(SERVER_INDEX, NO_INDEX, szAuthId, szAuthId, kCaster, eID, SM_REPLY_TO_CONSOLE);
			}
		}
	}
	return 1;
}

/**
 * @brief Add, checks or remove a user from the Casters whitelist.
 *
 * @param eTypeID       Defines how the client will be identified.
 * @param eTypeAction   What action will be taken.
 * @param iClient       Required only if eTypeID is kClient, otherwise set it to -1.
 * @param szAuthId      Required only if eTypeID is kAuth, otherwise it is not necessary to define it.
 * @return              True if the action was successful, false otherwise.
 */
int iWhitelistNative(Handle hPlugin, int iNumParams)
{
	eTypeID		eID		= GetNativeCell(1);
	eTypeAction eAction = GetNativeCell(2);
	int			iTarget = GetNativeCell(3);
	char		szAuthId[STEAMID2_LENGTH];
	GetNativeString(4, szAuthId, sizeof(szAuthId));

#if DEBUG_API
	LogMessage("[iWhitelistNative] eTypeID: %d | eTypeAction: %d | iClient: %d | szAuthId: %s", eID, eAction, iTarget, szAuthId);
#endif

	switch (eAction)
	{
		case kGet:
			return g_smCaster.GetValue(szAuthId, g_iDummy);
		case kSet:
		{
			switch (eID)
			{
				case kClient:
				{
					char szName[32];
					GetClientName(iTarget, szName, sizeof(szName));
					vRegister(SERVER_INDEX, iTarget, szAuthId, szName, kWhite, eID, SM_REPLY_TO_CONSOLE);
				}
				case kAuth:
					vRegister(SERVER_INDEX, NO_INDEX, szAuthId, szAuthId, kWhite, eID, SM_REPLY_TO_CONSOLE);
			}
		}
		case kRem:
		{
			switch (eID)
			{
				case kClient:
				{
					char szName[32];
					GetClientName(iTarget, szName, sizeof(szName));
					vRegister(SERVER_INDEX, iTarget, szAuthId, szName, kWhite, eID, SM_REPLY_TO_CONSOLE);
				}
				case kAuth:
					vRemove(SERVER_INDEX, NO_INDEX, szAuthId, szAuthId, kWhite, eID, SM_REPLY_TO_CONSOLE);
			}
		}
	}
	return 1;
}

/**
 * @brief Add, checks or remove a user from the spectator immunity list.
 *
 * @param eTypeID       Defines how the client will be identified.
 * @param eTypeAction   What action will be taken.
 * @param iClient       Required only if eTypeID is kClient, otherwise set it to -1.
 * @param szAuthId      Required only if eTypeID is kAuth, otherwise it is not necessary to define it.
 * @return              True if the client has spectator immunity, false otherwise.
 */
int iInmunityNative(Handle hPlugin, int iNumParams)
{
	if (!g_cvKickSpecInmunity.BoolValue)
		return 0;

	eTypeID		eID		= GetNativeCell(1);
	eTypeAction eAction = GetNativeCell(2);
	int			iTarget = GetNativeCell(3);
	char		szAuthId[STEAMID2_LENGTH];
	GetNativeString(4, szAuthId, sizeof(szAuthId));
	bool bInmunity;

#if DEBUG_API
	LogMessage("[iInmunityNative] eTypeID: %d | eTypeAction: %d | iClient: %d | szAuthId: %s", eID, eAction, iTarget, szAuthId);
#endif

	switch (eID)
	{
		case kClient:
			bInmunity = bSpecInmunity(kClient, iTarget);
		case kAuth:
			bInmunity = bSpecInmunity(kAuth, NO_INDEX, szAuthId);
	}

	switch (eAction)
	{
		case kGet:
			return bInmunity;
		case kSet:
		{
			if (bInmunity)
				return 0;

			switch (eID)
			{
				case kClient:
				{
					char szClientAuthId[STEAMID2_LENGTH];
					GetClientAuthId(iTarget, AuthId_Steam2, szClientAuthId, sizeof(szClientAuthId));
					return g_smSpecInmunity.SetValue(szClientAuthId, true);
				}
				case kAuth:
					return g_smSpecInmunity.SetValue(szAuthId, true);
			}
		}
		case kRem:
		{
			if (bInmunity)
				return 0;

			switch (eID)
			{
				case kClient:
				{
					char szClientAuthId[STEAMID2_LENGTH];
					GetClientAuthId(iTarget, AuthId_Steam2, szClientAuthId, sizeof(szClientAuthId));
					return g_smSpecInmunity.Remove(szClientAuthId);
				}
				case kAuth:
					return g_smSpecInmunity.Remove(szAuthId);
			}
		}
	}
	return 1;
}

// ========================
//  Caster Addons
// ========================

void vOnSQLSettingChanged(ConVar cvar, const char[] szOldValue, const char[] szNewValue)
{
	if (g_cvSQLEnable.BoolValue)
	{
		if (g_hDatabase != null)
			delete g_hDatabase;

		OnConfigsExecuted();
	}
	else
	{
		if (g_hDatabase == null)
			return;

		delete g_hDatabase;
	}
}

void vOnAddonsSettingChanged(ConVar cvar, const char[] szOldValue, const char[] szNewValue)
{
	bool bDisable  = (StringToInt(szNewValue) != 0);
	bool bPrevious = (StringToInt(szOldValue) != 0);

	if (bDisable == bPrevious)
		return;

	ArrayList hCastersList = (bDisable) ? new ArrayList() : null;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;

		if (!bCaster(kClient, i))
			continue;

		if (bDisable)
		{
			CPrintToChat(i, "%t %t", "Prefix", "ForbidAddons");
			CPrintToChat(i, "%t %t", "Prefix", "Reconnect");
			hCastersList.Push(GetClientUserId(i));
		}
		else
		{
			CPrintToChat(i, "%t %t", "Prefix", "AllowAddons");
			CPrintToChat(i, "%t %t", "Prefix", "CasterReconnect");
		}
	}

	if (bDisable)
	{
		if (hCastersList.Length > 0)
			CreateTimer(3.0, aReconnectCastersTimer, hCastersList, TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE);
		else
			delete hCastersList;
	}
}

Action aReconnectCastersTimer(Handle hTimer, ArrayList aCasterList)
{
	int iSize = aCasterList.Length;
	for (int i = 0; i < iSize; i++)
	{
		int iClient = GetClientOfUserId(aCasterList.Get(i));
		if (iClient > SERVER_INDEX)
			ReconnectClient(iClient);
	}

	return Plugin_Stop;
}

public Action L4D2_OnClientDisableAddons(const char[] szAuthId)
{
	return (!g_cvAddonsEnable.BoolValue && bCaster(kAuth, SERVER_INDEX, szAuthId)) ? Plugin_Handled : Plugin_Continue;
}

void vPlayerTeamEvent(Event event, const char[] szName, bool bDontBroadcast)
{
	if (view_as<L4DTeam>(event.GetInt("team")) == L4DTeam_Spectator)
		return;

	int iUserId = event.GetInt("userid");
	CreateTimer(1.0, aCasterCheck, iUserId, TIMER_FLAG_NO_MAPCHANGE);
}

Action aCasterCheck(Handle hTimer, int iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	if (!iClient || !IsClientInGame(iClient))
		return Plugin_Stop;

	if (!bCaster(kClient, iClient))
		return Plugin_Stop;

	if (L4D_GetClientTeam(iClient) == L4DTeam_Spectator)
		return Plugin_Stop;

	CPrintToChat(iClient, "%t %t", "Prefix", "CasterPlay");
	CPrintToChat(iClient, "%t %t", "Prefix", "UseNoCast");
	ChangeClientTeam(iClient, view_as<int>(L4DTeam_Spectator));

	return Plugin_Stop;
}

// ========================
//  Caster
// ========================

Action aCasterRegCmd(int iClient, int iArgs)
{
	ReplySource eRsCmd = GetCmdReplySource();
	if (iArgs == 0)
	{
		if (eRsCmd == SM_REPLY_TO_CHAT && iClient != SERVER_INDEX)
			vDisplayRegMenu(iClient, kCaster);
		else
			CReplyToCommand(iClient, "%t %t: sm_caster <#userid|name|steamid>", "Prefix", "Use");
		return Plugin_Handled;
	}

	char szArguments[64];
	GetCmdArgString(szArguments, sizeof(szArguments));

	char szArg[STEAMID2_LENGTH];
	BreakString(szArguments, szArg, sizeof(szArg));

	vProcessReg(iClient, szArg, kCaster, eRsCmd);

	return Plugin_Handled;
}

void vProcessReg(int iClient, const char[] szArg, eTypeList eList, ReplySource eRsCmd)
{
	if (bIsSteamId(szArg))
	{
		vRegister(iClient, NO_INDEX, szArg, szArg, eList, kAuth, eRsCmd);
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
	vRegister(iClient, iTarget, szAuthId, szName, eList, kClient, eRsCmd);
}

/**
 * Registers a client as a caster or whitelist member.
 *
 * @param iClient       The client index of the player issuing the command.
 * @param iTarget       The client index of the target player.
 * @param szAuthId      The authentication ID of the target player.
 * @param szDisplayName The display name of the target player.
 * @param eList         The type of list to register the player.
 * @param eID           The type of identification to use for the target player.
 * @param eRsCmd        The reply source for the command.
 */
void vRegister(int iClient, int iTarget, const char[] szAuthId, const char[] szDisplayName, eTypeList eList, eTypeID eID, ReplySource eRsCmd)
{
#if DEBUG_VALUE
	LogMessage("[vRegister] iClient: %d | iTarget: %d | szAuthId: %s | szDisplayName: %s | eTypeList: %d | eTypeID %d | eRsCmd: %d", iClient, iTarget, szAuthId, szDisplayName, eList, eID, eRsCmd);
#endif

	char
		szRegMsg[128],
		szRegFromMsg[128];

	switch (eList)
	{
		case kCaster:
		{
			if (g_smCaster.GetValue(szAuthId, g_iDummy))
			{
				CReplyToCommand(iClient, "%t %t", "Prefix", "CasterFound", szDisplayName);
				return;
			}
			Format(szRegMsg, sizeof(szRegMsg), "%T", "CasterReg", iClient, szDisplayName);
			if (eID == kClient)
				Format(szRegFromMsg, sizeof(szRegFromMsg), "%T", "CasterRegFrom", iTarget, iClient);
		}
		case kWhite:
		{
			if (g_smWhitelist.GetValue(szAuthId, g_iDummy))
			{
				CReplyToCommand(iClient, "%t %t", "Prefix", "WhitelistFound", szDisplayName);
				return;
			}
			Format(szRegMsg, sizeof(szRegMsg), "%T", "WhitelistReg", iClient, szDisplayName);
			if (eID == kClient)
				Format(szRegFromMsg, sizeof(szRegFromMsg), "%T", "WhitelistRegFrom", iTarget, iClient);
		}
		case kSQL:
		{
			char szQuery[256];
			g_hDatabase.Format(szQuery, sizeof(szQuery), "SELECT authid FROM `%s` WHERE authid = '%s'", g_szTable, szAuthId);

#if DEBUG_SQL
			LogMessage("[vRegister] Query: %s", szQuery);
#endif
			int
				iUserId,
				iTargetUserId;

			if (iClient != SERVER_INDEX)
				iUserId = GetClientUserId(iClient);

			if (iTarget != NO_INDEX)
				iTargetUserId = GetClientUserId(iTarget);

			DataPack pDataPack = new DataPack();
			pDataPack.WriteCell(iUserId);
			pDataPack.WriteCell(iTargetUserId);
			pDataPack.WriteString(szAuthId);
			pDataPack.WriteCell(eID);
			pDataPack.WriteCell(eRsCmd);

			SQL_TQuery(g_hDatabase, vSQLRegCallback, szQuery, pDataPack);
			return;
		}
	}

	switch (eList)
	{
		case kCaster:
		{
			if (!g_smCaster.SetValue(szAuthId, true))
			{
				CReplyToCommand(iClient, "%t %t", "Prefix", "CasterRegError", szAuthId);
				return;
			}

#if DEBUG_API
			LogMessage("[forward OnCaster] eTypeID: %d | iClient: %d | szAuthId: %s", eID, iTarget, szAuthId);
#endif

			Call_StartForward(g_gfOnCaster);
			Call_PushCell(eID);
			Call_PushCell(iTarget);
			Call_PushString(szAuthId);
			Call_Finish();
		}
		case kWhite:
		{
			if (!g_smWhitelist.SetValue(szAuthId, true))
			{
				CReplyToCommand(iClient, "%t %t", "Prefix", "WhitelistRegError", szAuthId);
				return;
			}
		}
	}

	CReplyToCommand(iClient, "%t %s", "Prefix", szRegMsg);

	if (eID == kAuth)
		return;

	if ((L4D_GetClientTeam(iTarget) != L4DTeam_Spectator) && (eList == kCaster))
		ChangeClientTeam(iTarget, view_as<int>(L4DTeam_Spectator));

	CPrintToChat(iTarget, "%t %s", "Prefix", szRegFromMsg);

	if (eList == kCaster)
		CPrintToChat(iTarget, "%t %t", "Prefix", "CasterReconnect");
}

void vDisplayRegMenu(int iClient, eTypeList eList)
{
	char szTitle[100];
	Format(szTitle, sizeof(szTitle), "%t", "MenuPlayersList");
	Menu hMenu = new Menu(iRegMenuHandler);
	hMenu.SetTitle(szTitle);
	vListTargets(hMenu, eList);

	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

/**
 * Populates a menu with a list of targets based on the specified list type.
 *
 * @param hMenu        The menu handle to which the targets will be added.
 * @param eTypeList    The type of list to determine the target selection criteria.
 *
 * The function iterates through all connected clients and adds them to the menu.
 * It skips fake clients and clients that cannot be identified by name or Steam ID.
 * Depending on the list type, it checks if the client is in the caster or whitelist.
 * If the client is found in the respective list, the menu item is added as disabled.
 * Otherwise, the menu item is added as enabled.
 */
void vListTargets(Menu hMenu, eTypeList eList)
{
	char
		szName[64],
		szInfo[16],
		szAuthId[STEAMID2_LENGTH];

	bool
		bFound;

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
				bFound = g_smCaster.GetValue(szAuthId, g_iDummy);
			case kWhite, kSQL:
				bFound = g_smWhitelist.GetValue(szAuthId, g_iDummy);
		}

		if (bFound)
			hMenu.AddItem(szInfo, szName, ITEMDRAW_DISABLED);
		else
			hMenu.AddItem(szInfo, szName);
	}
}

public int iRegMenuHandler(Menu hMenu, MenuAction eAction, int iClient, int iItem)
{
	switch (eAction)
	{
		case MenuAction_Select:
		{
			char
				szInfo[32],
				szName[32];

			int
				iUserId,
				iTarget;

			eTypeList eList;

			hMenu.GetItem(iItem, szInfo, sizeof(szInfo), _, szName, sizeof(szName));

			char szParts[2][8];
			ExplodeString(szInfo, ":", szParts, 2, 4);

			iUserId = StringToInt(szParts[0]);
			eList	= view_as<eTypeList>(StringToInt(szParts[1]));

			if ((iTarget = GetClientOfUserId(iUserId)) == SERVER_INDEX)
				CPrintToChat(iClient, "%t %t", "Prefix", "Player no longer available");
			else
			{
				char szAuthId[STEAMID2_LENGTH];
				if (!GetClientAuthId(iTarget, AuthId_Steam2, szAuthId, sizeof(szAuthId)))
				{
					CReplyToCommand(iClient, "%t %t", "Prefix", "AuthIdError", szAuthId);
					return Plugin_Handled;
				}

				vRegister(iClient, iTarget, szAuthId, szName, eList, kClient, SM_REPLY_TO_CHAT);
			}
		}
		case MenuAction_End:
			delete hMenu;
	}
	return 0;
}

Action aCasterListCmd(int iClient, int iArgs)
{
	return aListCmd(iClient, kCaster);
}

Action aListCmd(int iClient, eTypeList type)
{
	PrintListPrinted(iClient);

	switch (type)
	{
		case kCaster:
		{
			StringMapSnapshot hSnapshot = g_smCaster.Snapshot();
			PrintSnapshotList(iClient, hSnapshot, "/***********[Casters]***********\\", ">* Total Casters: %i");
		}
		case kWhite:
		{
			StringMapSnapshot hSnapshot = g_smWhitelist.Snapshot();
			PrintSnapshotList(iClient, hSnapshot, "/***********[Whitelist]***********\\", ">* Total Whitelist: %i");
		}
		case kSQL:
		{
			if (!g_cvSQLEnable.BoolValue)
			{
				CReplyToCommand(iClient, "%t %t", "Prefix", "SQLDisabled");
				return Plugin_Handled;
			}
			if (!g_bSQLConnected)
			{
				CReplyToCommand(iClient, "%t %t", "Prefix", "SQLNoConnect");
				return Plugin_Handled;
			}

			char szQuery[256];
			g_hDatabase.Format(szQuery, sizeof(szQuery), "SELECT authid, serverid FROM `%s`", g_szTable);

#if DEBUG_SQL
			LogMessage("[aListCmd] Query: %s", szQuery);
#endif

			DataPack pDataPack = new DataPack();
			pDataPack.WriteCell(iClient);
			SQL_TQuery(g_hDatabase, vSQLListCallback, szQuery, pDataPack);
		}
	}

	return Plugin_Handled;
}

void PrintSnapshotList(int iClient, StringMapSnapshot hSnapshot, const char[] sHeader, const char[] sTotalLabel)
{
	PrintToConsole(iClient, sHeader);

	char szAuthID[128];
	int
		iLen = hSnapshot.Length,
		iTarget;
	for (int i = 0; i < iLen; i++)
	{
		hSnapshot.GetKey(i, szAuthID, sizeof(szAuthID));
		iTarget = GetClientOfAuthID(szAuthID);

		if (iTarget == NO_INDEX)
			PrintToConsole(iClient, "AuthID: %s", szAuthID);
		else
			PrintToConsole(iClient, "AuthID: %s [%N]", szAuthID, iTarget);
	}
	PrintToConsole(iClient, sTotalLabel, iLen);

	delete hSnapshot;
}

void PrintListPrinted(int iClient)
{
	if (GetCmdReplySource() == SM_REPLY_TO_CONSOLE || iClient == SERVER_INDEX)
		return;

	CPrintToChat(iClient, "%t %t", "Prefix", "ListPrinted");
}

Action aCasterResetCmd(int iClient, int iArgs)
{
	g_smCaster.Clear();
	CReplyToCommand(iClient, "%t %t", "Prefix", "CasterReset");
	return Plugin_Handled;
}

Action aCasterRemoveCmd(int iClient, int iArgs)
{
	ReplySource eRsCmd = GetCmdReplySource();
	if (iArgs == 0)
	{
		if (eRsCmd == SM_REPLY_TO_CHAT && iClient != SERVER_INDEX)
			vDisplayRemoveMenu(iClient, kCaster);
		else
			CReplyToCommand(iClient, "%t %t: sm_caster_rm <#userid|name|steamid>", "Prefix", "Use");
		return Plugin_Handled;
	}

	char szArguments[64];
	GetCmdArgString(szArguments, sizeof(szArguments));

	char szArg[STEAMID2_LENGTH];
	BreakString(szArguments, szArg, sizeof(szArg));

	vProcessRemove(iClient, szArg, kCaster, eRsCmd);
	return Plugin_Handled;
}

/**
 * Processes the removal of a client from a specified list.
 *
 * @param iClient The client index initiating the removal.
 * @param szArg The argument provided, which can be a Steam ID or a target name.
 * @param eList The list type from which the client should be removed.
 * @param eRsCmd The reply source for the command.
 */
void vProcessRemove(int iClient, const char[] szArg, eTypeList eList, ReplySource eRsCmd)
{
	if (bIsSteamId(szArg))
	{
		vRemove(iClient, NO_INDEX, szArg, szArg, eList, kAuth, eRsCmd);
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
	vRemove(iClient, iTarget, szAuthId, szName, eList, kClient, eRsCmd);
}

/**
 * Removes a client from a specified list and sends appropriate messages.
 *
 * @param iClient       The client index who initiated the removal.
 * @param iTarget       The target client index to be removed.
 * @param szAuthId      The authentication ID of the target client.
 * @param szDisplayName The display name of the target client.
 * @param eList         The list type from which the client is to be removed.
 * @param eID           The type of identification to use for the target client.
 * @param eRsCmd        The reply source for the command.
 */
void vRemove(int iClient, int iTarget, const char[] szAuthId, const char[] szDisplayName, eTypeList eList, eTypeID eID, ReplySource eRsCmd)
{
#if DEBUG_VALUE
	LogMessage("[vRegister] iClient: %d | iTarget: %d | szAuthId: %s | szDisplayName: %s | eTypeList: %d | eTypeID %d | eRsCmd: %d", iClient, iTarget, szAuthId, szDisplayName, eList, eID, eRsCmd);
#endif

	char
		szRemoveMsg[128],
		szRemoveFromMsg[128];

	switch (eList)
	{
		case kCaster:
		{
			if (!g_smCaster.GetValue(szAuthId, g_iDummy))
			{
				CReplyToCommand(iClient, "%t %t", "Prefix", "CasterNoFound", szDisplayName);
				return;
			}
			Format(szRemoveMsg, sizeof(szRemoveMsg), "%T", "CasterRemove", iClient, szDisplayName);
			if (eID == kClient)
				Format(szRemoveFromMsg, sizeof(szRemoveFromMsg), "%T", "CasterRemoveFrom", iTarget, iClient);
		}
		case kWhite:
		{
			if (!g_smWhitelist.GetValue(szAuthId, g_iDummy))
			{
				CReplyToCommand(iClient, "%t %t", "Prefix", "WhitelistNoFound", szDisplayName);
				return;
			}
			Format(szRemoveMsg, sizeof(szRemoveMsg), "%T", "WhitelistRemove", iClient, szDisplayName);
			if (eID == kClient)
				Format(szRemoveFromMsg, sizeof(szRemoveFromMsg), "%T", "WhitelistRemoveFrom", iTarget, iClient);
		}
		case kSQL:
		{
			char szQuery[256];
			g_hDatabase.Format(szQuery, sizeof(szQuery), "SELECT authid FROM `%s` WHERE authid = '%s'", g_szTable, szAuthId);

#if DEBUG_SQL
			LogMessage("[vRemove] Query: %s", szQuery);
#endif
			int
				iUserId,
				iTargetUserId;

			if (iClient != SERVER_INDEX)
				iUserId = GetClientUserId(iClient);

			if (iTarget != NO_INDEX)
				iTargetUserId = GetClientUserId(iTarget);

			DataPack pDataPack = new DataPack();
			pDataPack.WriteCell(iUserId);
			pDataPack.WriteCell(iTargetUserId);
			pDataPack.WriteString(szAuthId);
			pDataPack.WriteCell(eID);
			pDataPack.WriteCell(eRsCmd);

			SQL_TQuery(g_hDatabase, vSQLRemoveCallback, szQuery, pDataPack);
			return;
		}
	}

	switch (eList)
	{
		case kCaster:
		{
			if (!g_smCaster.Remove(szAuthId))
			{
				CReplyToCommand(iClient, "%t %t", "Prefix", "CasterRemoveError", szAuthId);
				return;
			}

#if DEBUG_API
			LogMessage("[forward OffCaster] eTypeID: %d | iClient: %d | szAuthId: %s", eID, iTarget, szAuthId);
#endif

			Call_StartForward(g_gfOffCaster);
			Call_PushCell(eID);
			Call_PushCell(iTarget);
			Call_PushString(szAuthId);
			Call_Finish();

			if (eID == kClient)
				CreateTimer(3.0, aReconnectTimer, iTarget);
		}
		case kWhite:
		{
			if (!g_smWhitelist.Remove(szAuthId))
			{
				CReplyToCommand(iClient, "%t %t", "Prefix", "WhitelistRemoveError", szAuthId);
				return;
			}
		}
	}

	CReplyToCommand(iClient, "%t %s", "Prefix", szRemoveMsg);

	if (eID == kAuth)
		return;

	CPrintToChat(iTarget, "%t %s", "Prefix", szRemoveFromMsg);
}

void vDisplayRemoveMenu(int iClient, eTypeList eList)
{
	char szTitle[100];
	switch (eList)
	{
		case kCaster:
			Format(szTitle, sizeof(szTitle), "%T", "MenuCastersList", iClient);
		case kWhite, kSQL:
			Format(szTitle, sizeof(szTitle), "%T", "MenuWhitelistList", iClient);
	}

	Menu hMenu = new Menu(iMenuRemoveHandler);
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
				bFound = g_smCaster.GetValue(szAuthId, g_iDummy);
			case kWhite, kSQL:
				bFound = g_smWhitelist.GetValue(szAuthId, g_iDummy);
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

public int iMenuRemoveHandler(Menu hMenu, MenuAction eAction, int iClient, int iItem)
{
	if (eAction == MenuAction_Select)
	{
		char
			szInfo[32],
			szName[32];

		int
			iUserId,
			iTarget;

		eTypeList eList;

		hMenu.GetItem(iItem, szInfo, sizeof(szInfo), _, szName, sizeof(szName));

		char szParts[2][8];
		ExplodeString(szInfo, ":", szParts, 2, 4);

		iUserId = StringToInt(szParts[0]);
		eList	= view_as<eTypeList>(StringToInt(szParts[1]));

		if ((iTarget = GetClientOfUserId(iUserId)) == SERVER_INDEX)
			CPrintToChat(iClient, "%t %t", "Prefix", "Player no longer available");
		else
		{
			char szAuthId[STEAMID2_LENGTH];
			if (!GetClientAuthId(iTarget, AuthId_Steam2, szAuthId, sizeof(szAuthId)))
			{
				CReplyToCommand(iClient, "%t %t", "Prefix", "AuthIdError", szAuthId);
				return Plugin_Handled;
			}

			vRemove(iClient, iTarget, szAuthId, szName, eList, kClient, SM_REPLY_TO_CHAT);
		}
	}
	else if (eAction == MenuAction_End)
		delete hMenu;
	return 0;
}

// ========================
//  Whitelist
// ========================

Action aWhitelistRegCmd(int iClient, int iArgs)
{
	ReplySource eRsCmd = GetCmdReplySource();
	if (iArgs == 0)
	{
		if (eRsCmd == SM_REPLY_TO_CHAT && iClient != SERVER_INDEX)
			vDisplayRegMenu(iClient, kWhite);
		else
			CReplyToCommand(iClient, "%t %t: sm_caster_wl <#userid|name|steamid>", "Prefix", "Use");
		return Plugin_Handled;
	}

	char szArguments[64];
	GetCmdArgString(szArguments, sizeof(szArguments));

	char szArg[STEAMID2_LENGTH];
	BreakString(szArguments, szArg, sizeof(szArg));

	vProcessReg(iClient, szArg, kWhite, eRsCmd);

	return Plugin_Handled;
}

Action aWhitelistListCmd(int iClient, int iArgs)
{
	return aListCmd(iClient, kWhite);
}

Action aWhitelistResetCmd(int iClient, int iArgs)
{
	g_smWhitelist.Clear();
	CReplyToCommand(iClient, "%t %t", "Prefix", "WhitelistReset");
	return Plugin_Handled;
}

Action aWhitelistRemoveCmd(int iClient, int iArgs)
{
	ReplySource eRsCmd = GetCmdReplySource();
	if (iArgs == 0)
	{
		if (eRsCmd == SM_REPLY_TO_CHAT && iClient != SERVER_INDEX)
			vDisplayRemoveMenu(iClient, kWhite);
		else
			CReplyToCommand(iClient, "%t %t: sm_caster_wl_rm <#userid|name|steamid>", "Prefix", "Use");
		return Plugin_Handled;
	}

	char szArguments[64];
	GetCmdArgString(szArguments, sizeof(szArguments));

	char szArg[STEAMID2_LENGTH];
	BreakString(szArguments, szArg, sizeof(szArg));

	vProcessRemove(iClient, szArg, kWhite, eRsCmd);
	return Plugin_Handled;
}

// ========================
//  SQL
// ========================

Action aSQLRegCmd(int iClient, int iArgs)
{
	if (!g_cvSQLEnable.BoolValue)
	{
		CReplyToCommand(iClient, "%t %t", "Prefix", "SQLDisabled");
		return Plugin_Handled;
	}

	if (!g_bSQLConnected)
	{
		CReplyToCommand(iClient, "%t %t", "Prefix", "SQLNoConnect");
		return Plugin_Handled;
	}

	ReplySource eRsCmd = GetCmdReplySource();
	if (iArgs == 0)
	{
		if (eRsCmd == SM_REPLY_TO_CHAT && iClient != SERVER_INDEX)
			vDisplayRegMenu(iClient, kSQL);
		else
			CReplyToCommand(iClient, "%t %t: sm_caster_sql <#userid|name|steamid>", "Prefix", "Use");
		return Plugin_Handled;
	}

	char szArguments[64];
	GetCmdArgString(szArguments, sizeof(szArguments));

	char szArg[STEAMID2_LENGTH];
	BreakString(szArguments, szArg, sizeof(szArg));

	vProcessReg(iClient, szArg, kSQL, eRsCmd);

	return Plugin_Handled;
}

void vSQLRegCallback(Handle hDatabase, Handle hResult, const char[] szError, any data)
{
	DataPack pDataPack = view_as<DataPack>(data);
	char	 szAuthId[STEAMID2_LENGTH];

	int
		iClient,
		iTarget,
		iUserId,
		iTargetUserId;

	pDataPack.Reset();
	iUserId		  = pDataPack.ReadCell(),
	iTargetUserId = pDataPack.ReadCell();
	pDataPack.ReadString(szAuthId, sizeof(szAuthId));
	eTypeID		eID	   = pDataPack.ReadCell();
	ReplySource eRsCmd = pDataPack.ReadCell();
	delete pDataPack;

	if (iUserId != SERVER_INDEX)
		iClient = GetClientOfUserId(iUserId);

	if (iTargetUserId != NO_INDEX)
		iTarget = GetClientOfUserId(iTargetUserId);

	SetCmdReplySource(eRsCmd);
	if (hResult == null)
	{
		LogError("[vSQLRegCallback] %s", "SQLError", LANG_SERVER, szError);
		CReplyToCommand(iClient, "%t %t", "Prefix", "SQLError");
		return;
	}

	if (SQL_FetchRow(hResult))
	{
		CReplyToCommand(iClient, "%t %t", "Prefix", "SQLFound", szAuthId);
		delete hResult;
		return;
	}
	delete hResult;

	char szQuery[256];
	g_hDatabase.Format(szQuery, sizeof(szQuery), "INSERT INTO `%s` (authid, serverid) VALUES ('%s', %d)", g_szTable, szAuthId, g_cvSQLServerID.IntValue);

#if DEBUG_SQL
	LogMessage("[vSQLRegCallback] Query: %s", szQuery);
#endif

	if (!SQL_FastQuery(g_hDatabase, szQuery))
	{
		LogError("[vSQLRegCallback] %s", "SQLError", LANG_SERVER, szError);
		CReplyToCommand(iClient, "%t %t", "Prefix", "SQLError");
		return;
	}

	switch (eID)
	{
		case kClient:
		{
			char szName[16];
			GetClientName(iTarget, szName, sizeof(szName));

			if (!g_smWhitelist.SetValue(szAuthId, 1))
				CReplyToCommand(iClient, "%t %t", "Prefix", "WhitelistRegError", szName);
			else
			{
				CReplyToCommand(iClient, "%t %t", "Prefix", "SQLReg", szName);
				CReplyToCommand(iTarget, "%t %t", "Prefix", "SQLRegFrom", iClient);
			}
		}
		case kAuth:
		{
			if (!g_smWhitelist.SetValue(szAuthId, 1))
				CReplyToCommand(iClient, "%t %t", "Prefix", "WhitelistRegError", szAuthId);
			else
				CReplyToCommand(iClient, "%t %t", "Prefix", "SQLReg", szAuthId);
		}
	}
}

Action aSQLListCmd(int iClient, int iArgs)
{
	return aListCmd(iClient, kSQL);
}

void vSQLListCallback(Handle hDatabase, Handle hResult, const char[] szError, any data)
{
	DataPack pDataPack = view_as<DataPack>(data);
	pDataPack.Reset();
	int iClient = pDataPack.ReadCell();
	delete pDataPack;

	if (hResult == null)
	{
		char szErrorMsg[128];
		Format(szErrorMsg, sizeof(szErrorMsg), "%T: %s", "SQLError", LANG_SERVER, szError);

		CPrintToChat(iClient, "%t %t", "Prefix", "SQLError");
		CRemoveTags(szErrorMsg, sizeof(szErrorMsg));
		LogError("[vSQLListCallback] %s", szErrorMsg);
		return;
	}

	PrintToConsole(iClient, "/***********[Whitelist SQL]***********/");
	int iCount = 0;

	while (SQL_FetchRow(hResult))
	{
		char szAuthId[STEAMID2_LENGTH];
		SQL_FetchString(hResult, 0, szAuthId, sizeof(szAuthId));
		int iServerId = SQL_FetchInt(hResult, 1);
		PrintToConsole(iClient, "AuthID: %s | ServerID: %d", szAuthId, iServerId);
		iCount++;
	}

	PrintToConsole(iClient, ">* Total Casters: %d", iCount);

	delete hResult;
}

Action aSQLRemoveCmd(int iClient, int iArgs)
{
	if (!g_cvSQLEnable.BoolValue)
	{
		CReplyToCommand(iClient, "%t %t", "Prefix", "SQLDisabled");
		return Plugin_Handled;
	}

	if (!g_bSQLConnected)
	{
		CReplyToCommand(iClient, "%t %t", "Prefix", "SQLNoConnect");
		return Plugin_Handled;
	}

	ReplySource eRsCmd = GetCmdReplySource();
	if (iArgs == 0)
	{
		if (eRsCmd == SM_REPLY_TO_CHAT && iClient != SERVER_INDEX)
			vDisplayRemoveMenu(iClient, kSQL);
		else
			CReplyToCommand(iClient, "%t %t: sm_caster_sql_rm <#userid|name|steamid>", "Prefix", "Use");
		return Plugin_Handled;
	}

	char szArguments[64];
	GetCmdArgString(szArguments, sizeof(szArguments));

	char szArg[STEAMID2_LENGTH];
	BreakString(szArguments, szArg, sizeof(szArg));

	vProcessRemove(iClient, szArg, kSQL, eRsCmd);

	return Plugin_Handled;
}

public void vSQLRemoveCallback(Handle hDatabase, Handle hResult, const char[] szError, any data)
{
	DataPack pDataPack = view_as<DataPack>(data);
	char	 szAuthId[STEAMID2_LENGTH];

	int
		iClient,
		iTarget,
		iUserId,
		iTargetUserId;

	pDataPack.Reset();
	iUserId		  = pDataPack.ReadCell(),
	iTargetUserId = pDataPack.ReadCell();
	pDataPack.ReadString(szAuthId, sizeof(szAuthId));
	eTypeID		eID	   = pDataPack.ReadCell();
	ReplySource eRsCmd = pDataPack.ReadCell();
	delete pDataPack;

	if (iUserId != SERVER_INDEX)
		iClient = GetClientOfUserId(iUserId);

	if (iTargetUserId != NO_INDEX)
		iTarget = GetClientOfUserId(iTargetUserId);

	SetCmdReplySource(eRsCmd);
	if (hResult == null)
	{
		LogError("[vSQLRemoveCallback] %s", "SQLError", LANG_SERVER, szError);
		CReplyToCommand(iClient, "%t %t", "Prefix", "SQLError");
		return;
	}

	if (!SQL_FetchRow(hResult))
	{
		CReplyToCommand(iClient, "%t %t", "Prefix", "SQLNoFound", szAuthId);
		delete hResult;
		return;
	}

	delete hResult;

	char szQuery[256];
	g_hDatabase.Format(szQuery, sizeof(szQuery), "DELETE FROM `%s` WHERE authid = '%s'", g_szTable, szAuthId);

#if DEBUG_SQL
	LogMessage("[vSQLRemoveCallback] Query: %s", szQuery);
#endif

	if (!SQL_FastQuery(g_hDatabase, szQuery))
	{
		LogError("[vSQLRemoveCallback] %s", "SQLError", LANG_SERVER, szError);
		CReplyToCommand(iClient, "%t %t", "Prefix", "SQLError");
		return;
	}

	switch (eID)
	{
		case kClient:
		{
			char szName[16];
			GetClientName(iTarget, szName, sizeof(szName));

			if (!g_smWhitelist.Remove(szAuthId))
			{
				CReplyToCommand(iClient, "%t %t", "Prefix", "WhitelistRemoveError", szName);
				return;
			}

			CReplyToCommand(iClient, "%t %t", "Prefix", "SQLRemoved", szName);
			CReplyToCommand(iTarget, "%t %t", "Prefix", "SQLRemovedFrom", iClient);
		}
		case kAuth:
		{
			if (!g_smWhitelist.Remove(szAuthId))
			{
				CReplyToCommand(iClient, "%t %t", "Prefix", "WhitelistRemoveError", szAuthId);
				return;
			}
			CReplyToCommand(iClient, "%t %t", "Prefix", "SQLRemoved", szAuthId);
		}
	}
}

Action aSQLResetCmd(int iClient, int iArgs)
{
	if (!g_cvSQLEnable.BoolValue)
	{
		CReplyToCommand(iClient, "%t %t", "Prefix", "SQLDisabled");
		return Plugin_Handled;
	}

	if (!g_bSQLConnected)
	{
		CReplyToCommand(iClient, "%t %t", "Prefix", "SQLNoConnect");
		return Plugin_Handled;
	}

	char szQuery[64];
	g_hDatabase.Format(szQuery, sizeof(szQuery), "DELETE FROM `%s`", g_szTable);

#if DEBUG_SQL
	LogMessage("[aSQLResetCmd] Query: %s", szQuery);
#endif

	if (!SQL_FastQuery(g_hDatabase, szQuery))
	{
		logErrorSQL(g_hDatabase, szQuery, "aSQLResetCmd");
		CReplyToCommand(iClient, "%t %t", "Prefix", "SQLQueryError");
		return Plugin_Handled;
	}

	CReplyToCommand(iClient, "%t %t", "Prefix", "SQLResetSuccess");
	return Plugin_Handled;
}

Action aSQLCacheCmd(int iClient, int iArgs)
{
	if (!g_cvSQLEnable.BoolValue)
	{
		CReplyToCommand(iClient, "%t %t", "Prefix", "SQLDisabled");
		return Plugin_Handled;
	}

	if (!g_bSQLConnected)
	{
		CReplyToCommand(iClient, "%t %t", "Prefix", "SQLNoConnect");
		return Plugin_Handled;
	}

	DataPack pDataPack = new DataPack();
	pDataPack.WriteCell(GetClientUserId(iClient));

	vQueryWhitelist(pDataPack);
	CReplyToCommand(iClient, "%t %t", "Prefix", "SQLCacheSuccess");
	return Plugin_Handled;
}

// ========================
//  Self
// ========================

Action aSelfRegCastCmd(int iClient, int iArgs)
{
	bool bIsAdmin = (GetUserAdmin(iClient) != INVALID_ADMIN_ID);
	if (iArgs != 0)
	{
		if (!bIsAdmin)
		{
			CReplyToCommand(iClient, "%t %t", "Prefix", "SelfRegNoAdmin");
			return Plugin_Handled;
		}

		char szArguments[256];
		GetCmdArgString(szArguments, sizeof(szArguments));
		FakeClientCommandEx(iClient, "sm_caster %s", szArguments);
		return Plugin_Handled;
	}

	if (iClient == SERVER_INDEX)
	{
		CReplyToCommand(iClient, "%t %t: sm_cast <#userid|name|steamid>", "Prefix", "Use");
		return Plugin_Handled;
	}

	if (!g_cvSefRegEnable.BoolValue && !bIsAdmin)
	{
		CPrintToChat(iClient, "%t %t", "Prefix", "SelfRegDisabled");
		return Plugin_Handled;
	}

	char szAuthId[STEAMID2_LENGTH];
	GetClientAuthId(iClient, AuthId_Steam2, szAuthId, sizeof(szAuthId));

	if (g_cvWhitelistEnable)
	{
		if (g_smWhitelist.Size == 0 && !bIsAdmin)
		{
			CPrintToChat(iClient, "%t %t", "Prefix", "WhitelistEmpty");
			return Plugin_Handled;
		}

		if (!g_smWhitelist.GetValue(szAuthId, g_iDummy) && !bIsAdmin)
		{
			CPrintToChat(iClient, "%t %t", "Prefix", "SelfRegWhitelistNotFound");
			return Plugin_Handled;
		}
	}

	if (g_smCaster.GetValue(szAuthId, g_iDummy))
	{
		CReplyToCommand(iClient, "%t %t", "Prefix", "SelfRegCasterFound");
		return Plugin_Handled;
	}

	if (!g_smCaster.SetValue(szAuthId, true))
	{
		CReplyToCommand(iClient, "%t %t", "Prefix", "CasterRegError", szAuthId);
		return Plugin_Handled;
	}

	if (L4D_GetClientTeam(iClient) != L4DTeam_Spectator)
		ChangeClientTeam(iClient, view_as<int>(L4DTeam_Spectator));

#if DEBUG_API
	LogMessage("[forward OnCaster] eTypeID: %d | iClient: %d | szAuthId: %s", kClient, iClient, szAuthId);
#endif

	Call_StartForward(g_gfOnCaster);
	Call_PushCell(kClient);
	Call_PushCell(iClient);
	Call_PushString(szAuthId);
	Call_Finish();

	CPrintToChat(iClient, "%t %t", "Prefix", "SelfRegSuccess");
	CPrintToChat(iClient, "%t %t", "Prefix", "CasterReconnect");
	return Plugin_Handled;
}

Action aSelfRemoveCastCmd(int iClient, int iArgs)
{
	if (iArgs == 0)
	{
		if (iClient == SERVER_INDEX)
		{
			CReplyToCommand(iClient, "%t %t: sm_uncast <#userid|name|steamid>", "Prefix", "Use");
			return Plugin_Handled;
		}

		char szAuthId[STEAMID2_LENGTH];
		GetClientAuthId(iClient, AuthId_Steam2, szAuthId, sizeof(szAuthId));

		char szName[16];
		GetClientName(iClient, szName, sizeof(szName));

		if (!g_smCaster.GetValue(szAuthId, g_iDummy))
		{
			CReplyToCommand(iClient, "%t %t", "Prefix", "CasterNoFound", szName);
			return Plugin_Handled;
		}

		CPrintToChat(iClient, "%t %t", "Prefix", "Reconnect");
		g_smCaster.Remove(szAuthId);

#if DEBUG_API
		LogMessage("[forward OffCaster] eTypeID: %d | iClient: %d | szAuthId: %s", kClient, iClient, szAuthId);
#endif

		Call_StartForward(g_gfOffCaster);
		Call_PushCell(kClient);
		Call_PushCell(iClient);
		Call_PushString(szAuthId);
		Call_Finish();

		CreateTimer(3.0, aReconnectTimer, iClient);
		return Plugin_Handled;
	}

	if (g_smCaster.Size == 0)
	{
		CPrintToChat(iClient, "%t %t", "Prefix", "CasterEmpty");
		return Plugin_Handled;
	}

	AdminId aAdminId = GetUserAdmin(iClient);
	if (aAdminId == INVALID_ADMIN_ID || !GetAdminFlag(aAdminId, Admin_Ban))	   // Check for specific admin flag
	{
		CReplyToCommand(iClient, "%t %t", "Prefix", "UnRegCasterNonAdmin");
		return Plugin_Handled;
	}

	char szArguments[256];
	GetCmdArgString(szArguments, sizeof(szArguments));
	FakeClientCommandEx(iClient, "sm_caster_rm %s", szArguments);
	return Plugin_Handled;
}

Action aReconnectTimer(Handle timer, int client)
{
	if (IsClientConnected(client))
		ReconnectClient(client);

	return Plugin_Stop;
}

// ========================
//  SQL
// ========================
public void OnConfigsExecuted()
{
	if (!g_cvSQLEnable.BoolValue)
		return;

	vConnectDB("castersystem", g_szTable);

	DataPack pDataPack = new DataPack();
	pDataPack.WriteCell(SERVER_INDEX);
	pDataPack.WriteCell(SM_REPLY_TO_CONSOLE);

	vQueryWhitelist(pDataPack);
}

public void OnPluginEnd()
{
	if (!g_cvSQLEnable.BoolValue)
		return;

	if (g_hDatabase == null)
		return;

	delete g_hDatabase;
}

void vQueryWhitelist(DataPack pDataPack)
{
	if (g_hDatabase == null)
		return;

	char szQuery[64];
	g_hDatabase.Format(szQuery, sizeof(szQuery), "SELECT * FROM `%s`", g_szTable);

#if DEBUG_SQL
	LogMessage("[vQueryWhitelist] Query: %s", szQuery);
#endif

	SQL_TQuery(g_hDatabase, vSQLCallback, szQuery, pDataPack);
}

public void vSQLCallback(Handle hDatabase, Handle hResult, const char[] szError, any data)
{
	DataPack pDataPack = view_as<DataPack>(data);
	pDataPack.Reset();
	int iUserId = pDataPack.ReadCell();
	int iClient = GetClientOfUserId(iUserId);
	delete pDataPack;

	if (hResult == null)
	{
		char szErrorMsg[128];
		Format(szErrorMsg, sizeof(szErrorMsg), "%T: %s", "SQLError", LANG_SERVER, szError);

		if (iClient == SERVER_INDEX)
			CReplyToCommand(iClient, "%t %t", "Prefix", "SQLError");
		else
			CPrintToChat(iClient, "%t %t", "Prefix", "SQLError");

		CRemoveTags(szErrorMsg, sizeof(szErrorMsg));
		LogError("[vSQLCallback] %s", szErrorMsg);
		return;
	}

	g_smWhitelist.Clear();
	while (SQL_FetchRow(hResult))
	{
		char szAuthId[STEAMID2_LENGTH];
		SQL_FetchString(hResult, 1, szAuthId, sizeof(szAuthId));

		if (!g_smWhitelist.SetValue(szAuthId, 1))
		{
			if (iClient == SERVER_INDEX)
				CReplyToCommand(iClient, "%t %t", "Prefix", "WhitelistRegError", szAuthId);
			else
				CPrintToChat(iClient, "%t %t", "Prefix", "WhitelistRegError", szAuthId);
		}
	}

	delete hResult;
}

// ========================
//  Kick Specs
// ========================

Action aKickSpecsCmd(int iClient, int iArgs)
{
	AdminId aAdminId = GetUserAdmin(iClient);
	if (aAdminId != INVALID_ADMIN_ID && GetAdminFlag(aAdminId, Admin_Ban))
	{
		CreateTimer(2.0, aTimerKickSpecs);
		CPrintToChatAll("%t %t", "Prefix", "KickSpecsAdmin", iClient);
		return Plugin_Handled;
	}

	if (L4D_GetClientTeam(iClient) == L4DTeam_Spectator)
	{
		CPrintToChat(iClient, "%t %t", "Prefix", "KickSpecsVoteSpec");
		return Plugin_Handled;
	}

	vStartKickSpecsVote(iClient);
	return Plugin_Handled;
}

// ========================
//  Vote
// ========================

void vStartKickSpecsVote(int iClient)
{
	if (IsBuiltinVoteInProgress())
	{
		CPrintToChat(iClient, "%t %t", "Prefix", "VoteInProgress");
		return;
	}
	if (CheckBuiltinVoteDelay() > 0)
	{
		CPrintToChat(iClient, "%t %t", "Prefix", "VoteDelay", CheckBuiltinVoteDelay());
		return;
	}

	Handle hVote = CreateBuiltinVote(vVoteActionHandler, BuiltinVoteType_Custom_YesNo,
									 BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);

	char   szBuffer[128];
	FormatEx(szBuffer, sizeof(szBuffer), "%T", "KickSpecsVoteTitle", LANG_SERVER);
	SetBuiltinVoteArgument(hVote, szBuffer);
	SetBuiltinVoteInitiator(hVote, iClient);
	SetBuiltinVoteResultCallback(hVote, vKickSpecsVoteResultHandler);

	int iTotal		= 0;
	int[] aiPlayers = new int[MaxClients];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || L4D_GetClientTeam(iClient) == L4DTeam_Spectator)
			continue;
		aiPlayers[iTotal++] = i;
	}
	DisplayBuiltinVote(hVote, aiPlayers, iTotal, FindConVar("sv_vote_timer_duration").IntValue);

	FakeClientCommand(iClient, "Vote Yes");
}

void vVoteActionHandler(Handle hVote, BuiltinVoteAction eAction, int iParam1, int iParam2)
{
	switch (eAction)
	{
		case BuiltinVoteAction_End:
		{
			CloseHandle(hVote);
		}
		case BuiltinVoteAction_Cancel:
		{
			DisplayBuiltinVoteFail(hVote, BuiltinVoteFail_Generic);
		}
	}
}

void vKickSpecsVoteResultHandler(Handle hVote, int iNumVotes, int iNumClients, const int[][] aiClientInfo, int iNumItems, const int[][] aiItemInfo)
{
	for (int i = 0; i < iNumItems; i++)
	{
		if (aiItemInfo[i][BUILTINVOTEINFO_ITEM_INDEX] == BUILTINVOTES_VOTE_YES)
		{
			if (aiItemInfo[i][BUILTINVOTEINFO_ITEM_VOTES] > (iNumClients / 2))
			{
				char szBuffer[64];
				FormatEx(szBuffer, sizeof(szBuffer), "%T", "KickSpecsVoteSuccess", LANG_SERVER);
				DisplayBuiltinVotePass(hVote, szBuffer);

				float fDelay = FindConVar("sv_vote_command_delay").FloatValue;
				CreateTimer(fDelay, aTimerKickSpecs);
				return;
			}
		}
	}

	DisplayBuiltinVoteFail(hVote, BuiltinVoteFail_Loses);
}

Action aTimerKickSpecs(Handle hTimer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;
		if (L4D_GetClientTeam(i) != L4DTeam_Spectator)
			continue;
		if (bCaster(kClient, i))
			continue;
		if (GetUserAdmin(i) != INVALID_ADMIN_ID)
			continue;
		if (bSpecInmunity(kClient, i))
			continue;
		KickClient(i, "%t", "KickSpecsReason");
	}

	return Plugin_Stop;
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

/**
 * Checks if a client or an AuthID is a caster.
 *
 * @param etType       The type of identifier being used (kClient or kAuth).
 * @param iClient      The client index (optional, default is 0).
 * @param szAuthId     The AuthID string (optional, default is an empty string).
 * @return             True if the client or AuthID is a caster, false otherwise.
 */
bool bCaster(eTypeID eID, int iClient = 0, const char[] szAuthId = "")
{
	switch (eID)
	{
		case kClient:
		{
			char szClientAuthId[STEAMID2_LENGTH];
			GetClientAuthId(iClient, AuthId_Steam2, szClientAuthId, sizeof(szClientAuthId));
			return g_smCaster.GetValue(szClientAuthId, g_iDummy);
		}
		case kAuth:
		{
			return g_smCaster.GetValue(szAuthId, g_iDummy);
		}
	}
	return false;
}

/**
 * Checks if a client or an AuthID has spectator immunity.
 *
 * @param eTypeID     The type of identifier being used (kClient or kAuth).
 * @param iClient     The client index (only used if eTypeID is kClient).
 * @param szAuthId    The AuthID string (only used if eTypeID is kAuth).
 * @return            True if the client or AuthID has spectator immunity, false otherwise.
 */
bool bSpecInmunity(eTypeID eID, int iClient = 0, const char[] szAuthId = "")
{
	switch (eID)
	{
		case kClient:
		{
			char szClientAuthId[STEAMID2_LENGTH];
			GetClientAuthId(iClient, AuthId_Steam2, szClientAuthId, sizeof(szClientAuthId));
			return g_smSpecInmunity.GetValue(szClientAuthId, g_iDummy);
		}
		case kAuth:
		{
			return g_smSpecInmunity.GetValue(szAuthId, g_iDummy);
		}
	}
	return false;
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

	int iPos2 = FindCharInString(szAuthId, ':', iPos1 + 1);
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
 * Connects to the database using the specified configuration name.
 *
 * @param szConfigName The name of the database configuration to use for the connection.
 *
 * This function checks if the specified database configuration exists. If it does not,
 * it logs an error message and sets the global variable `g_bSQLConnected` to false.
 * If the configuration exists, it attempts to connect to the database using the provided
 * configuration name and calls the `vConnectCallback` function upon completion.
 */
stock void vConnectDB(char[] szConfigName, char[] szTable = "")
{
	if (!SQL_CheckConfig(szConfigName))
	{
		g_bSQLConnected = false;
		return;
	}

	if (szTable[0] == '\0')
	{
		Database.Connect(vConnectCallback, szConfigName);
		return;
	}

	DataPack pDataPack = new DataPack();
	pDataPack.WriteString(szTable);
	Database.Connect(vConnectCallback, szConfigName, pDataPack);
}

/**
 * Callback function for handling database connection.
 *
 * @param hDatabase  The database connection object.
 * @param szError     The error message if the connection failed.
 * @param pData      Additional data passed to the callback.
 *
 * This function is called when a connection to the database is attempted.
 * It logs the success or failure of the connection, sets the database charset to UTF-8,
 * and determines the SQL driver being used. It also checks if table exists.
 */
stock void vConnectCallback(Database hDatabase, const char[] szError, any pData)
{
	if (hDatabase == null)
	{
		g_bSQLConnected = false;
		return;
	}

	if (szError[0] != '\0')
	{
		g_bSQLConnected = false;
		return;
	}

	g_bSQLConnected = true;
	g_hDatabase		= hDatabase;

	char szDriver[64];
	SQL_ReadDriver(hDatabase, szDriver, sizeof(szDriver));

	if (StrEqual(szDriver, "mysql"))
	{
		g_iSQLDriver = kMySQL;
		hDatabase.SetCharset("utf8");
	}
	else if (StrEqual(szDriver, "sqlite"))
		g_iSQLDriver = kSQLite;

	if (pData == 0)
		return;

	char	 szTable[64];
	DataPack pDataPack = view_as<DataPack>(pData);

	pDataPack.Reset();
	pDataPack.ReadString(szTable, sizeof(szTable));
	delete pDataPack;
	g_bSQLTableExists = bTableExists(szTable);

	if (!g_bSQLTableExists)
		vCreateSQL();
}

/**
 * Creates the SQL table if it does not already exist.
 * The table structure depends on the SQL driver being used (MySQL or SQLite).
 *
 * MySQL:
 * - Table name: g_szTable
 * - Columns:
 *   - `id`: INT, AUTO_INCREMENT, PRIMARY KEY
 *   - `authid`: VARCHAR(64), NOT NULL, DEFAULT '', COMMENT 'Client in the whitelistList'
 *   - `serverid`: INT, NOT NULL, DEFAULT 0, COMMENT 'Server identification'
 *
 * SQLite:
 * - Table name: g_szTable
 * - Columns:
 *   - `id`: INTEGER, PRIMARY KEY AUTOINCREMENT
 *   - `authid`: TEXT, NOT NULL, DEFAULT ''
 *   - `serverid`: INTEGER, NOT NULL, DEFAULT 0
 *
 * If the table creation fails, an error is logged.
 * If the table is created successfully, a message is printed to the server.
 *
 * @return void
 */
void vCreateSQL()
{
	char szQuery[600];
	switch (g_iSQLDriver)
	{
		case kMySQL:
		{
			g_hDatabase.Format(szQuery, sizeof(szQuery),
							   "CREATE TABLE IF NOT EXISTS `%s` ( \
				`id` INT AUTO_INCREMENT PRIMARY KEY, \
				`authid` VARCHAR(64) NOT NULL DEFAULT '' COMMENT 'Client in the whitelistList', \
				`serverid` INT NOT NULL DEFAULT 0 COMMENT 'Server identification' \
				) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci",
							   g_szTable);
		}
		case kSQLite:
		{
			g_hDatabase.Format(szQuery, sizeof(szQuery),
							   "CREATE TABLE IF NOT EXISTS `%s` ( \
				`id` INTEGER PRIMARY KEY AUTOINCREMENT, \
				`authid` TEXT NOT NULL DEFAULT '' \
				`serverid` INTEGER NOT NULL DEFAULT 0, \
				)",
							   g_szTable);
		}
	}

#if DEBUG_SQL
	LogMessage("[CreateSQL] Table created: %s", g_szTable);
#endif

	if (!SQL_FastQuery(g_hDatabase, szQuery))
	{
		logErrorSQL(g_hDatabase, szQuery, "CreateSQL");
		return;
	}

	g_bSQLTableExists = true;
}

/**
 * Checks if a table exists in the database.
 *
 * @param szTable       The name of the table to check.
 * @return              True if the table exists, false otherwise.
 */
stock bool bTableExists(const char[] szTable)
{
	char szQuery[255];

	switch (g_iSQLDriver)
	{
		case kMySQL:
			g_hDatabase.Format(szQuery, sizeof(szQuery), "SHOW TABLES LIKE '%s'", szTable);
		case kSQLite:
			g_hDatabase.Format(szQuery, sizeof(szQuery), "SELECT name FROM sqlite_master WHERE type='table' AND name='%s'", szTable);
	}

#if DEBUG_SQL
	LogMessage("[bTableExists] Query: %s", szQuery);
#endif

	DBResultSet hQueryTableExists = SQL_Query(g_hDatabase, szQuery);
	if (hQueryTableExists == null)
		return false;

	bool bExists = hQueryTableExists.FetchRow();
	delete hQueryTableExists;

	return bExists;
}

/**
 * Logs SQL errors and the corresponding query that caused the error.
 *
 * @param db        The database connection handle.
 * @param sQuery    The SQL query that failed.
 * @param sName     The name of the source or context where the error occurred.
 */
void logErrorSQL(Database pDb, const char[] szQuery, const char[] szName)
{
	char szSQLError[250];
	SQL_GetError(pDb, szSQLError, sizeof(szSQLError));
	LogError("[%s] SQL failed: %s", szName, szSQLError);
	LogError("[%s] Query dump: %s", szName, szQuery);
}

/**
 * Retrieves the client index of a player based on their Steam2 Auth ID.
 *
 * @param szAuthId      The Steam2 Auth ID of the player to search for.
 * @return              The client index of the player if found, otherwise NO_INDEX.
 */
int GetClientOfAuthID(const char[] szAuthId)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;

		char szClientAuthId[STEAMID2_LENGTH];
		GetClientAuthId(i, AuthId_Steam2, szClientAuthId, sizeof(szClientAuthId));

		if (StrEqual(szClientAuthId, szAuthId))
			return i;
	}
	return NO_INDEX;
}