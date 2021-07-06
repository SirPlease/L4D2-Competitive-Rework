#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define DEBUG				0
#define NUM_SI_CLASSES		6
#define DOMINATORS_DEFAULT	53

#define GAMEDATA_FILE "l4d2_dominators"

bool
	IsCvarHooked = false;

int
	g_iDominators = DOMINATORS_DEFAULT;

Address
	g_pDominatorsAddress = Address_Null;

ConVar
	g_hCvarDominators = null;

public Plugin myinfo = 
{
	name = "Dominators Control",
	author = "vintik",	//update syntax A1m`, fixed work on windows
	description = "Changes bIsDominator flag for infected classes. Allows to have native-order quad-caps.",
	version = "1.2",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
}

public void OnPluginStart()
{
	CheckGame();
	InitGameData();

	g_hCvarDominators = CreateConVar(
		"l4d2_dominators", 
		"53",
		"Which infected class is considered as dominator (bitmask: 1 - smoker, 2 - boomer, 4 - hunter, 8 - spitter, 16 - jockey, 32 - charger)", 
		_, true, 0.0, true, 63.0); //32+16+8+4+2+1=63

	int iCvarValue = g_hCvarDominators.IntValue;
	if (!IsValidCvarValue(iCvarValue)) {
		g_hCvarDominators.SetInt(DOMINATORS_DEFAULT);
		iCvarValue = DOMINATORS_DEFAULT;
	}
	
	if (g_iDominators != iCvarValue) {
		g_iDominators = iCvarValue;
		SetDominators();
	}
	
	g_hCvarDominators.AddChangeHook(OnCvarDominatorsChange);
	IsCvarHooked = true;
}

void CheckGame()
{
	char sGame[256];
	GetGameFolderName(sGame, sizeof(sGame));
	if (strcmp(sGame, "left4dead2", false) != 0) {
		SetFailState("Plugin 'Dominators Control' supports Left 4 Dead 2 only!");
	}
}

void InitGameData()
{
	Handle hDamedata  = LoadGameConfigFile(GAMEDATA_FILE);
	if (!hDamedata) {
		SetFailState("%s gamedata missing or corrupt", GAMEDATA_FILE);
	}

	g_pDominatorsAddress = GameConfGetAddress(hDamedata , "bIsDominator");
	if (!g_pDominatorsAddress) {
		SetFailState("Can't find 'bIsDominator' signature!");
	}
	
	#if DEBUG
	PrintToServer("[DEBUG] bIsDominator's signature is found. Address: %08x", g_pDominatorsAddress);
	#endif
	
	delete hDamedata;
}

public void OnPluginEnd()
{
	if (IsCvarHooked) {
		g_hCvarDominators.RemoveChangeHook(OnCvarDominatorsChange);
	}

	g_iDominators = DOMINATORS_DEFAULT;
	SetDominators();
}

public void OnCvarDominatorsChange(ConVar hCvar, const char[] sOldVal, const char[] sNewVal)
{
	int iNewVal = StringToInt(sNewVal);
	if (iNewVal == g_iDominators) {
		return;
	}
	
	if (IsValidCvarValue(iNewVal)) {
		g_iDominators = iNewVal;
		#if DEBUG
		PrintToServer("[DEBUG] sm_dominators changed to %d", g_iDominators);
		#endif
		SetDominators();
	} else {
		PrintToServer("[SM] Incorrect value of 'sm_dominators'! min: 0, max: %d", (1 << NUM_SI_CLASSES) - 1);
		hCvar.SetString(sOldVal);
	}
}

bool IsValidCvarValue(int iValue)
{
	return ((iValue >= 0) && (iValue < (1 << NUM_SI_CLASSES)));
}

void SetDominators()
{
	for (int  i = 0; i < NUM_SI_CLASSES; i++) {
		bool bIsDominator = (((1 << i) & g_iDominators) != 0);
		#if DEBUG
		int ReadByte = LoadFromAddress(g_pDominatorsAddress + view_as<Address>(i), NumberType_Int8);
		#endif
		
		StoreToAddress(g_pDominatorsAddress + view_as<Address>(i), view_as<int>(bIsDominator), NumberType_Int8);
		
		#if DEBUG
		int ReadSetByte = LoadFromAddress(g_pDominatorsAddress + view_as<Address>(i), NumberType_Int8);
		PrintToServer("[DEBUG] Class %d is %sdominator now. ReadByte: %x. SetByte: %x", i, bIsDominator ? "" : "NOT ", ReadByte, ReadSetByte);
		#endif
	}
}
