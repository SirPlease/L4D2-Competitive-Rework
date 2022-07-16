#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
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

StringMap
	g_hTrieNameToGenderIndex = null;

ConVar
	g_hCvarSurvivorLimit = null;

public Plugin myinfo =
{
	name = "Infected Flow Warp",
	author = "CanadaRox, A1m`",
	description = "Allows infected to warp to survivors based on their flow",
	version = "2.0",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	InitTrie();

	g_hCvarSurvivorLimit = FindConVar("survivor_limit");

	RegConsoleCmd("sm_warpto", WarpTo_Cmd, "Warps to the specified survivor");
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

public Action WarpTo_Cmd(int iClient, int iArgs)
{
	if (iClient == 0) {
		ReplyToCommand(iClient, "%s This command is not available for the server!", PLUGIN_TAG);
		return Plugin_Handled;
	}

	if (GetClientTeam(iClient) != L4D2Team_Infected
		|| GetEntProp(iClient, Prop_Send, "m_isGhost", 1) < 1
		|| !IsPlayerAlive(iClient)
	) {
		PrintToChat(iClient, "%s This command is only available for \x04infected\x01 ghosts.", PLUGIN_TAG_COLOR);
		return Plugin_Handled;
	}

	if (iArgs != 1) {
		// Left4Dhooks functional or Left4Downtown2 by A1m`
		int fMaxFlowSurvivor = L4D_GetHighestFlowSurvivor();

		if (fMaxFlowSurvivor < 1
			|| fMaxFlowSurvivor > MaxClients
			|| GetClientTeam(fMaxFlowSurvivor) != L4D2Team_Survivor
			|| !IsPlayerAlive(fMaxFlowSurvivor)
		) {
			PrintToChat(iClient, "%s No \x04survivor\x01 player could be found!", PLUGIN_TAG_COLOR);
			return Plugin_Handled;
		}

		TeleportToSurvivor(iClient, fMaxFlowSurvivor);
		return Plugin_Handled;
	}

	char sBuffer[9];
	GetCmdArg(1, sBuffer, sizeof(sBuffer));

	if (IsStringNumeric(sBuffer, sizeof(sBuffer))) {
		int iSurvivorFlowRank = StringToInt(sBuffer);

		if (iSurvivorFlowRank > 0 && iSurvivorFlowRank <= g_hCvarSurvivorLimit.IntValue) {
			int iSurvivorIndex = GetSurvivorOfFlowRank(iSurvivorFlowRank);

			if (iSurvivorIndex == 0) {
				PrintToChat(iClient, "%s No \x04survivor\x01 player could be found!", PLUGIN_TAG_COLOR);

				return Plugin_Handled;
			}

			TeleportToSurvivor(iClient, iSurvivorIndex);

			return Plugin_Handled;
		}

		char sCmdName[18];
		GetCmdArg(0, sCmdName, sizeof(sCmdName));

		PrintToChat(iClient, "%s You entered an \x04invalid\x01 survivor index!", PLUGIN_TAG_COLOR);
		PrintToChat(iClient, "%s Usage: \x04%s\x01 <1 - %d>", PLUGIN_TAG_COLOR, sCmdName, g_hCvarSurvivorLimit.IntValue);

		return Plugin_Handled;
	}

	int iGender = 0;
	String_ToLower(sBuffer, sizeof(sBuffer));

	if (!g_hTrieNameToGenderIndex.GetValue(sBuffer, iGender)) {
		char sCmdName[18];
		GetCmdArg(0, sCmdName, sizeof(sCmdName));

		PrintToChat(iClient, "%s You entered the \x04wrong\x01 survivor name!", PLUGIN_TAG_COLOR);
		PrintToChat(iClient, "%s Usage: \x04%s\x01 <survivor name> ", PLUGIN_TAG_COLOR, sCmdName);

		return Plugin_Handled;
	}

	int iSurvivorCount = 0;
	int iSurvivorIndex = GetGenderOfSurvivor(iGender, iSurvivorCount);

	if (iSurvivorCount == 0) {
		PrintToChat(iClient, "%s No \x04survivor\x01 player could be found!", PLUGIN_TAG_COLOR);
		return Plugin_Handled;
	}

	if (iSurvivorIndex == 0) {
		PrintToChat(iClient, "%s The \x04survivor\x01 you specified was \x04not found\x01!", PLUGIN_TAG_COLOR);
		return Plugin_Handled;
	}

	TeleportToSurvivor(iClient, iSurvivorIndex);

	return Plugin_Handled;
}

void TeleportToSurvivor(int iInfected, int iSurvivor)
{
	//~Prevent people from spawning and then warp to survivor
	SetEntProp(iInfected, Prop_Send, "m_ghostSpawnState", SPAWNFLAG_TOOCLOSE);

	float fPosition[3], fAnglestarget[3];
	GetClientAbsOrigin(iSurvivor, fPosition);
	GetClientAbsAngles(iSurvivor, fAnglestarget);

	TeleportEntity(iInfected, fPosition, fAnglestarget, NULL_VECTOR);
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
