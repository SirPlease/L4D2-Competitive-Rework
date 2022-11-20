#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <left4dhooks>
#include <l4d2util_constants>

#define PLUGIN_TAG					"[GhostWarp]"
#define PLUGIN_TAG_COLOR			"\x01[\x03GhostWarp\x01]"

#if SOURCEMOD_V_MINOR > 9
enum struct eSurvFlow
{
	int eiSurvivorIndex;
	float efSurvivorFlow;
}
#else
enum eSurvFlow
{
	eiSurvivorIndex,
	Float:efSurvivorFlow
};
#endif

enum
{
	eAllowCommand	= (1 << 0),
	eAllowButton	= (1 << 1),

	eAllowAll		= (1 << 0)|(1 << 1)
};

int
	g_iLastTargetSurvivor[MAXPLAYERS + 1] = {0, ...};

float
	g_fGhostWarpDelay[MAXPLAYERS + 1] = {0.0, ...};

StringMap
	g_hTrieNameToGenderIndex = null;

ConVar
	g_hCvarSurvivorLimit = null,
	g_hCvarGhostWarpDelay = null,
	g_hCvarGhostWarpFlag = null;

public Plugin myinfo =
{
	name = "Infected Warp",
	author = "Confogl Team, CanadaRox, A1m`",
	description = "Allows infected to warp to survivors",
	version = "2.4",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	InitTrie();

	g_hCvarGhostWarpFlag = CreateConVar( \
		"l4d2_ghost_warp_flag", \
		"3", \
		"Enable|Disable ghost warp. 0 - disable, 1 - enable warp via command 'sm_warpto', 2 - enable warp via button 'IN_ATTACK2', 3 - enable all.", \
		_, true, 0.0, true, float(eAllowAll)
	);

	g_hCvarGhostWarpDelay = CreateConVar( \
		"l4d2_ghost_warp_delay", \
		"0.45", \
		"After how many seconds can ghost warp be reused. 0.0 - delay disabled (maximum delay 120 seconds).", \
		_, true, 0.0, true, 120.0
	);

	g_hCvarSurvivorLimit = FindConVar("survivor_limit");

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);

	RegConsoleCmd("sm_warptosurvivor", Cmd_WarpToSurvivor);
	RegConsoleCmd("sm_warpto", Cmd_WarpToSurvivor);
	RegConsoleCmd("sm_warp", Cmd_WarpToSurvivor);
}

void InitTrie()
{
	g_hTrieNameToGenderIndex = new StringMap();

	g_hTrieNameToGenderIndex.SetValue("nick", L4D2Gender_Gambler);
	g_hTrieNameToGenderIndex.SetValue("rochelle", L4D2Gender_Producer);
	g_hTrieNameToGenderIndex.SetValue("coach", L4D2Gender_Coach);
	g_hTrieNameToGenderIndex.SetValue("ellis", L4D2Gender_Mechanic);

	g_hTrieNameToGenderIndex.SetValue("bill", L4D2Gender_Nanvet);
	g_hTrieNameToGenderIndex.SetValue("zoey", L4D2Gender_TeenGirl);
	g_hTrieNameToGenderIndex.SetValue("louis", L4D2Gender_Manager);
	g_hTrieNameToGenderIndex.SetValue("francis", L4D2Gender_Biker);
}

public void Event_RoundStart(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	// GetGameTime (gpGlobals->curtime) starts from scratch every map.
	// Let's clean this up

	for (int iClient = 1; iClient <= MaxClients; iClient++) {
		g_iLastTargetSurvivor[iClient] = 0;
		g_fGhostWarpDelay[iClient] = 0.0;
	}
}

public Action Cmd_WarpToSurvivor(int iClient, int iArgs)
{
	if (iClient == 0) {
		ReplyToCommand(iClient, "%s This command is not available for the server!", PLUGIN_TAG);
		return Plugin_Handled;
	}

	if (!(g_hCvarGhostWarpFlag.IntValue & eAllowCommand)) {
		PrintToChat(iClient, "%s This command is \x04disabled\x01 now.", PLUGIN_TAG_COLOR);
		return Plugin_Handled;
	}

	if (GetClientTeam(iClient) != L4D2Team_Infected
		|| GetEntProp(iClient, Prop_Send, "m_isGhost", 1) < 1
		|| !IsPlayerAlive(iClient)
	) {
		return Plugin_Handled;
	}

	if (g_fGhostWarpDelay[iClient] >= GetGameTime()) {
		PrintToChat(iClient, "%s You can't use this command that often, wait another \x04%.01f\x01 sec.", PLUGIN_TAG_COLOR, g_fGhostWarpDelay[iClient] - GetGameTime());
		return Plugin_Handled;
	}

	if (iArgs < 1) {
		if (!WarpToRandomSurvivor(iClient, g_iLastTargetSurvivor[iClient])) {
			PrintToChat(iClient, "%s No \x04survivors\x01 found!", PLUGIN_TAG_COLOR);
		}

		return Plugin_Handled;
	}

	char sBuffer[9];
	GetCmdArg(1, sBuffer, sizeof(sBuffer));

	if (IsStringNumeric(sBuffer, sizeof(sBuffer))) {
		int iSurvivorFlowRank = StringToInt(sBuffer);

		if (iSurvivorFlowRank > 0 && iSurvivorFlowRank <= g_hCvarSurvivorLimit.IntValue) {
			int iSurvivorIndex = GetSurvivorOfFlowRank(iSurvivorFlowRank);

			if (iSurvivorIndex == 0) {
				PrintToChat(iClient, "%s No \x04survivors\x01 found!", PLUGIN_TAG_COLOR);

				return Plugin_Handled;
			}

			TeleportToSurvivor(iClient, iSurvivorIndex);

			return Plugin_Handled;
		}

		bool bWarp = WarpToRandomSurvivor(iClient, g_iLastTargetSurvivor[iClient]);

		char sCmdName[18];
		GetCmdArg(0, sCmdName, sizeof(sCmdName));

		PrintToChat(iClient, "%s You entered an \x04invalid\x01 survivor index!%s", PLUGIN_TAG_COLOR, (!bWarp) ? "" : " Teleport to a \x04random\x01 survivor!");
		PrintToChat(iClient, "%s Usage: \x04%s\x01 <1 - %d>", PLUGIN_TAG_COLOR, sCmdName, g_hCvarSurvivorLimit.IntValue);

		return Plugin_Handled;
	}

	int iGender = 0;
	String_ToLower(sBuffer, sizeof(sBuffer));

	if (!g_hTrieNameToGenderIndex.GetValue(sBuffer, iGender)) {
		bool bWarp = WarpToRandomSurvivor(iClient, g_iLastTargetSurvivor[iClient]);

		char sCmdName[18];
		GetCmdArg(0, sCmdName, sizeof(sCmdName));

		PrintToChat(iClient, "%s You entered the \x04wrong\x01 survivor name!%s", PLUGIN_TAG_COLOR, (!bWarp) ? "" : " Teleport to a \x04random\x01 survivor!");
		PrintToChat(iClient, "%s Usage: \x04%s\x01 <survivor name> ", PLUGIN_TAG_COLOR, sCmdName);

		return Plugin_Handled;
	}

	int iSurvivorCount = 0;
	int iSurvivorIndex = GetGenderOfSurvivor(iGender, iSurvivorCount);

	if (iSurvivorCount == 0) {
		PrintToChat(iClient, "%s No \x04survivors\x01 found!", PLUGIN_TAG_COLOR);
		return Plugin_Handled;
	}

	if (iSurvivorIndex == 0) {
		PrintToChat(iClient, "%s The \x04survivor\x01 you specified was \x04not found\x01!", PLUGIN_TAG_COLOR);
		return Plugin_Handled;
	}

	TeleportToSurvivor(iClient, iSurvivorIndex);

	return Plugin_Handled;
}

public void L4D_OnEnterGhostState(int iClient)
{
	if (!(g_hCvarGhostWarpFlag.IntValue & eAllowButton)) {
		return;
	}

	g_iLastTargetSurvivor[iClient] = 0;
	g_fGhostWarpDelay[iClient] = 0.0;

	SDKUnhook(iClient, SDKHook_PostThinkPost, Hook_OnPostThinkPost);
	SDKHook(iClient, SDKHook_PostThinkPost, Hook_OnPostThinkPost);
}

public void Hook_OnPostThinkPost(int iClient)
{
	int iPressButtons = GetEntProp(iClient, Prop_Data, "m_afButtonPressed");

	// Key 'IN_RELOAD' was used in plugin 'confoglcompmod', do we need it?
	if (!(iPressButtons & IN_ATTACK2)/* && !(iPressButtons & IN_RELOAD)*/) {
		return;
	}

	// For some reason, the game resets button 'IN_ATTACK2' for infected ghosts at some point.
	// So we need spam protection.
	if (g_fGhostWarpDelay[iClient] >= GetGameTime()) {
		//PrintToChat(iClient, "%s You can't use this command that often, wait another \x04%.01f\x01 sec.", PLUGIN_TAG_COLOR, g_fGhostWarpDelay[iClient] - GetGameTime());
		return;
	}

	if (GetClientTeam(iClient) != L4D2Team_Infected
		|| GetEntProp(iClient, Prop_Send, "m_isGhost", 1) < 1
		|| !IsPlayerAlive(iClient)
	) {
		SDKUnhook(iClient, SDKHook_PostThinkPost, Hook_OnPostThinkPost);
		g_iLastTargetSurvivor[iClient] = 0;

		return;
	}

	// We didn't find any survivors, is the round over?
	if (!WarpToRandomSurvivor(iClient, g_iLastTargetSurvivor[iClient])) {
		SDKUnhook(iClient, SDKHook_PostThinkPost, Hook_OnPostThinkPost);
		g_iLastTargetSurvivor[iClient] = 0;
	}
}

bool WarpToRandomSurvivor(int iInfected, int iLastWarpSurvivor)
{
	int iRandomSurvivor = GetRandSurvivor(iLastWarpSurvivor);

	if (iRandomSurvivor == 0) {
		return false;
	}

	TeleportToSurvivor(iInfected, iRandomSurvivor);

	return true;
}

int GetRandSurvivor(int iExceptSurvivor = 0)
{
	int iSurvivorIndex[MAXPLAYERS + 1], iSuvivorCount = 0, iSuvivorTotalCount = 0;

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == L4D2Team_Survivor && IsPlayerAlive(i)) {
			iSuvivorTotalCount++;

			if (iExceptSurvivor > 0 && iExceptSurvivor == i) {
				continue;
			}

			iSurvivorIndex[iSuvivorCount++] = i;
		}
	}

	// If all the survivors died
	if (iSuvivorTotalCount == 0) {
		return 0;
	}

	// If there is only 1 survivor left, which we did not include in the array
	if (iSuvivorCount == 0) {
		return iExceptSurvivor;
	}

	int iRandInt = GetURandomInt() % iSuvivorCount;
	return (iSurvivorIndex[iRandInt]);
}

void TeleportToSurvivor(int iInfected, int iSurvivor)
{
	//~Prevent people from spawning and then warp to survivor
	SetEntProp(iInfected, Prop_Send, "m_ghostSpawnState", SPAWNFLAG_TOOCLOSE);

	float fPosition[3], fAnglestarget[3];
	GetClientAbsOrigin(iSurvivor, fPosition);
	GetClientAbsAngles(iSurvivor, fAnglestarget);

	TeleportEntity(iInfected, fPosition, fAnglestarget, NULL_VECTOR);

	g_iLastTargetSurvivor[iInfected] = iSurvivor;
	g_fGhostWarpDelay[iInfected] = GetGameTime() + g_hCvarGhostWarpDelay.FloatValue;
}

int GetGenderOfSurvivor(int iGender, int &iSurvivorCount)
{
	for (int iClient = 1; iClient <= MaxClients; iClient++) {
		if (IsClientInGame(iClient) && GetClientTeam(iClient) == L4D2Team_Survivor && IsPlayerAlive(iClient)) {
			iSurvivorCount++;

			if (GetEntProp(iClient, Prop_Send, "m_Gender") == iGender) {
				return iClient;
			}
		}
	}

	return 0;
}

#if SOURCEMOD_V_MINOR > 9
int GetSurvivorOfFlowRank(int iRank)
{
	int iArrayIndex = iRank - 1;

	eSurvFlow strSurvArray;
	ArrayList hFlowArray = new ArrayList(sizeof(strSurvArray));

	for (int iClient = 1; iClient <= MaxClients; iClient++) {
		if (IsClientInGame(iClient) && GetClientTeam(iClient) == L4D2Team_Survivor && IsPlayerAlive(iClient)) {
			strSurvArray.eiSurvivorIndex = iClient;
			strSurvArray.efSurvivorFlow = L4D2Direct_GetFlowDistance(iClient);

			hFlowArray.PushArray(strSurvArray, sizeof(strSurvArray));
		}
	}

	int iArraySize = hFlowArray.Length;
	if (iArraySize < 1) {
		return 0;
	}

	hFlowArray.SortCustom(sortFunc);

	if (iArrayIndex >= iArraySize) {
		iArrayIndex = iArraySize - 1;
	}

	hFlowArray.GetArray(iArrayIndex, strSurvArray, sizeof(strSurvArray));

	hFlowArray.Clear();
	delete hFlowArray;

	return strSurvArray.eiSurvivorIndex;
}

public int sortFunc(int iIndex1, int iIndex2, Handle hArray, Handle hndl)
{
	eSurvFlow strSurvArray1;
	eSurvFlow strSurvArray2;

	GetArrayArray(hArray, iIndex1, strSurvArray1, sizeof(strSurvArray1));
	GetArrayArray(hArray, iIndex2, strSurvArray2, sizeof(strSurvArray2));

	if (strSurvArray1.efSurvivorFlow > strSurvArray2.efSurvivorFlow) {
		return -1;
	} else if (strSurvArray1.efSurvivorFlow < strSurvArray2.efSurvivorFlow) {
		return 1;
	} else {
		return 0;
	}
}
#else
int GetSurvivorOfFlowRank(int iRank)
{
	int iArrayIndex = iRank - 1;

	eSurvFlow strSurvArray[eSurvFlow];
	ArrayList hFlowArray = new ArrayList(sizeof(strSurvArray));

	for (int iClient = 1; iClient <= MaxClients; iClient++) {
		if (IsClientInGame(iClient) && GetClientTeam(iClient) == L4D2Team_Survivor && IsPlayerAlive(iClient)) {
			strSurvArray[eiSurvivorIndex] = iClient;
			strSurvArray[efSurvivorFlow] = L4D2Direct_GetFlowDistance(iClient);

			hFlowArray.PushArray(strSurvArray[0], sizeof(strSurvArray));
		}
	}

	int iArraySize = hFlowArray.Length;
	if (iArraySize < 1) {
		return 0;
	}

	SortADTArrayCustom(hFlowArray, sortFunc);

	if (iArrayIndex >= iArraySize) {
		iArrayIndex = iArraySize - 1;
	}

	hFlowArray.GetArray(iArrayIndex, strSurvArray[0], sizeof(strSurvArray));

	hFlowArray.Clear();
	delete hFlowArray;

	return strSurvArray[eiSurvivorIndex];
}

public int sortFunc(int iIndex1, int iIndex2, Handle hArray, Handle hndl)
{
	eSurvFlow strSurvArray1[eSurvFlow];
	eSurvFlow strSurvArray2[eSurvFlow];

	GetArrayArray(hArray, iIndex1, strSurvArray1[0], sizeof(strSurvArray1));
	GetArrayArray(hArray, iIndex2, strSurvArray2[0], sizeof(strSurvArray2));

	if (strSurvArray1[efSurvivorFlow] > strSurvArray2[efSurvivorFlow]) {
		return -1;
	} else if (strSurvArray1[efSurvivorFlow] < strSurvArray2[efSurvivorFlow]) {
		return 1;
	} else {
		return 0;
	}
}
#endif

bool IsStringNumeric(const char[] sString, const int MaxSize)
{
	int iSize = strlen(sString); //Сounts string length to zero terminator

	for (int i = 0; i < iSize && i < MaxSize; i++) { //more security, so that the cycle is not endless
		if (sString[i] < '0' || sString[i] > '9') {
			return false;
		}
	}

	return true;
}

void String_ToLower(char[] str, const int MaxSize)
{
	int iSize = strlen(str); //Сounts string length to zero terminator

	for (int i = 0; i < iSize && i < MaxSize; i++) { //more security, so that the cycle is not endless
		if (IsCharUpper(str[i])) {
			str[i] = CharToLower(str[i]);
		}
	}

	str[iSize] = '\0';
}