/*

This version of Boss Percents was designed to work with my custom Ready Up plugin. 
It's designed so when boss percentages are changed, it will edit the already existing
Ready Up footer, rather then endlessly stacking them ontop of one another.

It was also created so that my Witch Toggler plugin can properly display if the witch is disabled 
or not on both the ready up menu aswell as when using the !boss commands.

I tried my best to comment everything so it can be very easy to understand what's going on. Just in case you want to 
do some personalization for your server or config. It will also come in handy if somebody finds a bug and I need to figure
out what's going on :D Kinda makes my other plugins look bad huh :/

*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <builtinvotes>
#include <left4dhooks>
#include <colors>
#define L4D2UTIL_STOCKS_ONLY
#include <l4d2util_rounds>
#undef REQUIRE_PLUGIN
#include <confogl>
#include <readyup>

#define PLUGIN_VERSION "3.2.4a"

public Plugin myinfo =
{
	name = "[L4D2] Boss Percents/Vote Boss Hybrid",
	author = "Spoon, Forgetest",
	version = PLUGIN_VERSION,
	description = "Displays Boss Flows on Ready-Up and via command. Remade for NextMod.",
	url = "https://github.com/spoon-l4d2"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("SetTankDisabled", Native_SetTankDisabled); 				// Other plugins can use this to set the tank as "disabled" on the ready up, and when the !boss command is used - YOU NEED TO SET THIS EVERY MAP
	CreateNative("SetWitchDisabled", Native_SetWitchDisabled); 				// Other plugins can use this to set the witch as "disabled" on the ready up, and when the !boss command is used - YOU NEED TO SET THIS EVERY MAP
	CreateNative("UpdateBossPercents", Native_UpdateBossPercents); 			// Used for other plugins to update the boss percentages
	CreateNative("IsStaticWitchMap", Native_IsStaticWitchMap); 				// Used for other plugins to check if the current map contains a static witch spawn
	CreateNative("IsStaticTankMap", Native_IsStaticTankMap); 				// Used for other plugins to check if the current map contains a static tank spawn
	CreateNative("GetStoredTankPercent", Native_GetStoredTankPercent); 		// Used for other plugins to get the stored tank percent
	CreateNative("GetStoredWitchPercent", Native_GetStoredWitchPercent); 	// Used for other plugins to get the stored witch percent
	CreateNative("GetReadyUpFooterIndex", Native_GetReadyUpFooterIndex); 	// Used for other plugins to get the ready footer index of the boss percents
	CreateNative("RefreshBossPercentReadyUp", Native_RefreshReadyUp); 		// Used for other plugins to refresh the boss percents on the ready up
	CreateNative("IsDarkCarniRemix", Native_IsDarkCarniRemix); 				// Used for other plugins to check if the current map is Dark Carnival: Remix (It tends to break things when it comes to bosses)
	RegPluginLibrary("l4d_boss_percent");
	return APLRes_Success;
}

// ConVars
ConVar g_hCvarGlobalPercent;											// Determines if Percents will be displayed to entire team when boss percentage command is used
ConVar g_hCvarTankPercent; 												// Determines if Tank Percents will be displayed on ready-up and when boss percentage command is used
ConVar g_hCvarWitchPercent; 											// Determines if Witch Percents will be displayed on ready-up and when boss percentage command is used
ConVar g_hCvarBossVoting; 												// Determines if boss voting will be enabled

// ConVar Storages
bool g_bCvarGlobalPercent;
bool g_bCvarTankPercent;
bool g_bCvarWitchPercent;

// Handles
//ConVar g_hVsBossBuffer; 												// Boss Buffer
ConVar g_hVsBossFlowMin; 												// Boss Flow Min
ConVar g_hVsBossFlowMax; 												// Boss Flow Max
StringMap g_hStaticTankMaps; 											// Stores All Static Tank Maps
StringMap g_hStaticWitchMaps; 											// Stores All Static Witch Maps
GlobalForward g_forwardUpdateBosses;
Handle g_hUpdateFooterTimer;

// Variables
bool g_ReadyUpAvailable; 												// Is Ready-Up plugin loaded?
int g_iReadyUpFooterIndex; 												// Stores the index of our boss percentage string on the ready-up menu footer
bool g_bReadyUpFooterAdded;												// Stores if our ready-up footer has been added yet
char g_sCurrentMap[64]; 												// Stores the current map name
bool g_bWitchDisabled;													// Stores if another plugin has disabled the witch
bool g_bTankDisabled;													// Stores if another plugin has disabled the tank

// Dark Carnival: Remix Work Around Variables
bool g_bIsRemix; 														// Stores if the current map is Dark Carnival: Remix. So we don't have to keep checking via IsDKR()
//int g_idkrwaAmount; 													// Stores the amount of times the DKRWorkaround method has been executed. We only want to execute it twice, one to get the tank percentage, and a second time to get the witch percentage.
int g_fDKRFirstRoundTankPercent; 										// Stores the Tank percent from the first half of a DKR map. Used so we can set the 2nd half to the same percent
int g_fDKRFirstRoundWitchPercent; 										// Stores the Witch percent from the first half of a DKR map. Used so we can set the 2nd half to the same percent
//bool g_bDKRFirstRoundBossesSet; 										// Stores if the first round of DKR boss percentages have been set

// Boss Voting Variables
Handle bv_hVote;														// Our boss vote handle
bool bv_bWitch;															// Stores if the Witch percent will change
bool bv_bTank;															// Stores if the Tank percent will change
int bv_iTank;															// Where we will keep our requested Tank percentage
int bv_iWitch;															// Where we will keep our requested Witch percentage

// Percent Variables
int g_fWitchPercent;													// Stores current Witch Percent
int g_fTankPercent;														// Stores current Tank Percent
char g_sWitchString[80];
char g_sTankString[80];

public void OnPluginStart()
{
	// Variable Setting
	//g_hVsBossBuffer = FindConVar("versus_boss_buffer"); // Get the boss buffer
	g_hVsBossFlowMin = FindConVar("versus_boss_flow_min"); // Get boss flow min
	g_hVsBossFlowMax = FindConVar("versus_boss_flow_max"); // Get boss flow max
	g_hStaticWitchMaps = new StringMap(); // Create list of static witch maps
	g_hStaticTankMaps = new StringMap(); // Create list of static tank maps
	
	// Forwards
	g_forwardUpdateBosses = new GlobalForward("OnUpdateBosses", ET_Event);

	// ConVars
	g_hCvarGlobalPercent = CreateConVar("l4d_global_percent", "0", "Display boss percentages to entire team when using commands"); // Sets if Percents will be displayed to entire team when boss percentage command is used
	g_hCvarTankPercent = CreateConVar("l4d_tank_percent", "1", "Display Tank flow percentage in chat"); // Sets if Tank Percents will be displayed on ready-up and when boss percentage command is used
	g_hCvarWitchPercent = CreateConVar("l4d_witch_percent", "1", "Display Witch flow percentage in chat"); // Sets if Witch Percents will be displayed on ready-up and when boss percentage command is used
	g_hCvarBossVoting = CreateConVar("l4d_boss_vote", "1", "Enable boss voting"); // Sets if boss voting is enabled or disabled

	g_hCvarGlobalPercent.AddChangeHook(OnConVarChanged);
	g_hCvarTankPercent.AddChangeHook(OnConVarChanged);
	g_hCvarWitchPercent.AddChangeHook(OnConVarChanged);
	
	GetCvars();
	
	// Commands
	RegConsoleCmd("sm_boss", BossCmd); // Used to see percentages of both bosses
	RegConsoleCmd("sm_tank", BossCmd); // Used to see percentages of both bosses
	RegConsoleCmd("sm_witch", BossCmd); // Used to see percentages of both bosses
	RegConsoleCmd("sm_voteboss", VoteBossCmd); // Allows players to vote for custom boss spawns
	RegConsoleCmd("sm_bossvote", VoteBossCmd); // Allows players to vote for custom boss spawns
	
	// Admin Commands
	RegAdminCmd("sm_ftank", ForceTankCommand, ADMFLAG_BAN);
	RegAdminCmd("sm_fwitch", ForceWitchCommand, ADMFLAG_BAN);
	
	// Server Commands
	RegServerCmd("static_witch_map", StaticWitchMap_Command); // Server command that is used to store static witch maps
	RegServerCmd("static_tank_map", StaticTankMap_Command); // Server command that is used to store static tank maps

	// Hooks/Events
	HookEvent("player_left_start_area", LeftStartAreaEvent, EventHookMode_PostNoCopy); // Called when a player has left the saferoom
	HookEvent("round_start", RoundStartEvent, EventHookMode_PostNoCopy); // When a new round starts (2 rounds in 1 map -- this should be called twice a map)
	HookEvent("player_say", DKRWorkaround, EventHookMode_Post); // Called when a message is sent in chat. Used to grab the Dark Carnival: Remix boss percentages.
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bCvarGlobalPercent = g_hCvarGlobalPercent.BoolValue;
	g_bCvarTankPercent = g_hCvarTankPercent.BoolValue;
	g_bCvarWitchPercent = g_hCvarWitchPercent.BoolValue;
}

/* ========================================================
// ====================== Section #1 ======================
// ======================= Natives ========================
// ========================================================
 *
 * This section contains all the methods that other plugins 
 * can use.
 *
 * vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
*/

// Allows other plugins to update boss percentages
public int Native_UpdateBossPercents(Handle plugin, int numParams){
	CreateTimer(0.1, GetBossPercents);
	UpdateReadyUpFooter(0.2);
}

// Allows other plugins to check if the current map contains a static witch spawn
public int Native_IsStaticWitchMap(Handle plugin, int numParams){
	return IsStaticWitchMap();
}

// Allows other plugins to check if the current map contains a static tank spawn
public int Native_IsStaticTankMap(Handle plugin, int numParams){
	return IsStaticTankMap();
}

// Used for other plugins to check if the current map is Dark Carnival: Remix (It tends to break things when it comes to bosses)
public int Native_IsDarkCarniRemix(Handle plugin, int numParams){
	return g_bIsRemix;
}

// Other plugins can use this to set the witch as "disabled" on the ready up, and when the !boss command is used
// YOU NEED TO SET THIS EVERY MAP
public int Native_SetWitchDisabled(Handle plugin, int numParams){
	g_bWitchDisabled = view_as<bool>(GetNativeCell(1));
	UpdateReadyUpFooter();
}

// Other plugins can use this to set the tank as "disabled" on the ready up, and when the !boss command is used
// YOU NEED TO SET THIS EVERY MAP
public int Native_SetTankDisabled(Handle plugin, int numParams){
	g_bTankDisabled = view_as<bool>(GetNativeCell(1));
	UpdateReadyUpFooter();
}

// Used for other plugins to get the stored witch percent
public int Native_GetStoredWitchPercent(Handle plugin, int numParams){
	return g_fWitchPercent;
}

// Used for other plugins to get the stored tank percent
public int Native_GetStoredTankPercent(Handle plugin, int numParams){
	return g_fTankPercent;
}

// Used for other plugins to get the ready footer index of the boss percents
public int Native_GetReadyUpFooterIndex(Handle plugin, int numParams){
	if (g_ReadyUpAvailable) return g_iReadyUpFooterIndex;
	else return -1;
}

// Used for other plugins to refresh the boss percents on the ready up
public int Native_RefreshReadyUp(Handle plugin, int numParams){
	if (g_ReadyUpAvailable) {
		UpdateReadyUpFooter();
		return true;
	}
	else return false;
}

/* ========================================================
// ====================== Section #2 ======================
// ==================== Ready Up Check ====================
// ========================================================
 *
 * This section makes sure that the Ready Up plugin is loaded.
 * 
 * It's needed to make sure we can actually add to the Ready
 * Up menu, or if we should just diplay percentages in chat.
 *
 * vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
*/

public void OnAllPluginsLoaded()
{
	g_ReadyUpAvailable = LibraryExists("readyup");
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "readyup")) g_ReadyUpAvailable = false;
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "readyup")) g_ReadyUpAvailable = true;
}

/* ========================================================
// ====================== Section #3 ======================
// ======================== Events ========================
// ========================================================
 *
 * This section is where all of our events will be. Just to
 * make things easier to keep track of.
 *
 * vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
*/

// Called when a new map is loaded
public void OnMapStart()
{

	// Get Current Map
	GetCurrentMap(g_sCurrentMap, sizeof(g_sCurrentMap));
	
	// Check if the current map is part of the Dark Carnival: Remix Campaign -- and save it
	g_bIsRemix = IsDKR();
	
}

// Called when a map ends 
public void OnMapEnd()
{
	// Reset Variables
	g_fDKRFirstRoundTankPercent = -1;
	g_fDKRFirstRoundWitchPercent = -1;
	g_fWitchPercent = -1;
	g_fTankPercent = -1;
	//g_bDKRFirstRoundBossesSet = false;
	//g_idkrwaAmount = 0;
	g_bTankDisabled = false;
	g_bWitchDisabled = false;
}

/* Called when survivors leave the saferoom
 * If the Ready Up plugin is not available, we use this. 
 * It will print boss percents upon survivors leaving the saferoom.
*/
public void LeftStartAreaEvent(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_ReadyUpAvailable) {
		PrintBossPercents();
		
		// If it's the first round of a Dark Carnival: Remix map, we want to save our boss percentages so we can set them next round
		if (g_bIsRemix && !InSecondHalfOfRound()) {
			g_fDKRFirstRoundTankPercent = g_fTankPercent;
			g_fDKRFirstRoundWitchPercent = g_fWitchPercent;
		}
	}
	
}

/* Called when the round goes live (Requires Ready Up Plugin)
 * If the Ready Up plugin is available, we use this.
 * It will print boss percents after all players are ready and the round goes live.
*/
public void OnRoundIsLive()
{
	PrintBossPercents();
	
	// If it's the first round of a Dark Carnival: Remix map, we want to save our boss percentages so we can set them next round
	if (g_bIsRemix && !InSecondHalfOfRound()) {
		g_fDKRFirstRoundTankPercent = g_fTankPercent;
		g_fDKRFirstRoundWitchPercent = g_fWitchPercent;
	}
}

/* Called when a new round starts (twice each map)
 * Here we will need to refresh the boss percents.
*/
public void RoundStartEvent(Event event, const char[] name, bool dontBroadcast)
{	
	// Reset Ready Up Variables
	g_bReadyUpFooterAdded = false;
	g_iReadyUpFooterIndex = -1;
	
	// Check if the current map is part of the Dark Carnival: Remix Campaign -- and save it
	//g_bIsRemix = IsDKR();
	
	// Find percentages and update readyup footer
	CreateTimer(5.0, GetBossPercents);
	UpdateReadyUpFooter(6.0);
}

/* ========================================================
// ====================== Section #4 ======================
// ================== Static Map Control ==================
// ========================================================
 *
 * This section is where all of our methods that have to due
 * with Static Boss Spawn maps will go.
 *
 * vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
*/

// Server Command - When it is executed it will add a static witch map name to a list.
public Action StaticWitchMap_Command(int args)
{
	char mapname[64];
	GetCmdArg(1, mapname, sizeof(mapname));
	SetTrieValue(g_hStaticWitchMaps, mapname, true);
}

// Server Command - When it is executed it will add a static tank map name to a list.
public Action StaticTankMap_Command(int args)
{
	char mapname[64];
	GetCmdArg(1, mapname, sizeof(mapname));
	SetTrieValue(g_hStaticTankMaps, mapname, true);
}

// Checks the static witch map list to see if the current map contains a static witch spawn
bool IsStaticWitchMap()
{
	bool tempValue;
	return GetTrieValue(g_hStaticWitchMaps, g_sCurrentMap, tempValue);
}

// Checks the static tank map list to see if the current map contains a static tank spawn
bool IsStaticTankMap()
{
	bool tempValue;
	return GetTrieValue(g_hStaticTankMaps, g_sCurrentMap, tempValue);
}

/* ========================================================
// ====================== Section #5 ======================
// ============ Dark Carnival: Remix Workaround ===========
// ========================================================
 *
 * This section is where all of our DKR work around stuff
 * well be kept. DKR has it's own boss flow "randomizer"
 * and therefore needs to be set as a static map to avoid
 * having 2 tanks on the map. Because of this, we need to 
 * do a few extra steps to determine the boss spawn percents.
 *
 * vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
*/

// Check if the current map name is equal to and of the Dark Carnival: Remix map names
bool IsDKR()
{
	if (StrEqual(g_sCurrentMap, "dkr_m1_motel", true) || StrEqual(g_sCurrentMap, "dkr_m2_carnival", true) || StrEqual(g_sCurrentMap, "dkr_m3_tunneloflove", true) || StrEqual(g_sCurrentMap, "dkr_m4_ferris", true) || StrEqual(g_sCurrentMap, "dkr_m5_stadium", true))
	{
		return true;
	}
	return false;
	
}

// Finds a percentage from a string
int GetPercentageFromText(const char[] text)
{
	// Check to see if text contains '%' - Store the index if it does
	int index = StrContains(text, "%", false);
	
	// If the index isn't -1 (No '%' found) then find the percentage
	if (index > -1) {
		char sBuffer[12]; // Where our percentage will be kept.
		
		// If the 3rd character before the '%' symbol is a number it's 100%.
		if (IsCharNumeric(text[index-3])) {
			return 100;
		}
		
		// Check to see if the characters that are 1 and 2 characters before our '%' symbol are numbers
		if (IsCharNumeric(text[index-2]) && IsCharNumeric(text[index-1])) {
		
			// If both characters are numbers combine them into 1 string
			Format(sBuffer, sizeof(sBuffer), "%c%c", text[index-2], text[index-1]);
			
			// Convert our string to an int
			return StringToInt(sBuffer);
		}
	}
	
	// Couldn't find a percentage
	return -1;
}

/*
 *
 * On Dark Carnival: Remix there is a script to display custom boss percentages to users via chat.
 * We can "intercept" this message and read the boss percentages from the message.
 * From there we can add them to our Ready Up menu and to our !boss commands
 *
 */
public void DKRWorkaround(Event event, const char[] name, bool dontBroadcast)
{
	// If the current map is not part of the Dark Carnival: Remix campaign, don't continue
	if (!g_bIsRemix) return;
	
	// Check if the function has already ran more than twice this map
	//if (g_bDKRFirstRoundBossesSet || InSecondHalfOfRound()) return;
	
	// Check if the message is not from a user (Which means its from the map script)
	int UserID = GetEventInt(event, "userid", 0);
	if (!UserID/* && !InSecondHalfOfRound()*/)
	{
	
		// Get the message text
		char sBuffer[128];
		GetEventString(event, "text", sBuffer, sizeof(sBuffer), "");
		
		// If the message contains "The Tank" we can try to grab the Tank Percent from it
		if (StrContains(sBuffer, "The Tank", false) > -1)
		{	
			// Create a new int and find the percentage
			int percentage;
			percentage = GetPercentageFromText(sBuffer);
			
			// If GetPercentageFromText didn't return -1 that means it returned our boss percentage.
			// So, if it did return -1, something weird happened, set our boss to 0 for now.
			if (percentage > -1) {
				g_fTankPercent = percentage;
			} else {
				g_fTankPercent = 0;					
			} 
			
			g_fDKRFirstRoundTankPercent = g_fTankPercent;
		}
		
		// If the message contains "The Witch" we can try to grab the Witch Percent from it
		if (StrContains(sBuffer, "The Witch", false) > -1)
		{
			// Create a new int and find the percentage
			int percentage;
			percentage = GetPercentageFromText(sBuffer);
			
			// If GetPercentageFromText didn't return -1 that means it returned our boss percentage.
			// So, if it did return -1, something weird happened, set our boss to 0 for now.
			if (percentage > -1){
				g_fWitchPercent = percentage;
			
			} else {
				g_fWitchPercent = 0;
			}
			
			g_fDKRFirstRoundWitchPercent = g_fWitchPercent;
		}
		
		// Increase the amount of times we've done this function. We only want to do it twice. Once for each boss, for each map.
		//g_idkrwaAmount = g_idkrwaAmount + 1;
		
		// Check if both bosses have already been set 
		//if (g_idkrwaAmount > 1)
		//{
			// This function has been executed two or more times, so we should be done here for this map.
		//	g_bDKRFirstRoundBossesSet = true;
		//}
		
		ProcessBossString();
		UpdateReadyUpFooter();
	}
}

/* ========================================================
// ====================== Section #6 ======================
// ================= Percent Updater/Saver ================
// ========================================================
 *
 * This section is where we will save our boss percents and
 * where we will call the methods to update our boss percents
 *
 * vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
*/

// This method will return the Tank flow for a specified round
stock float GetTankFlow(int round)
{
	return L4D2Direct_GetVSTankFlowPercent(round)/* -
		( GetConVarFloat(g_hVsBossBuffer) / L4D2Direct_GetMapMaxFlowDistance() )*/;
}

stock float GetWitchFlow(int round)
{
	return L4D2Direct_GetVSWitchFlowPercent(round)/* -
		( GetConVarFloat(g_hVsBossBuffer) / L4D2Direct_GetMapMaxFlowDistance() )*/;
}

/* 
 *
 * This method will find the current boss percents and will
 * save them to our boss percent variables.
 * This method will be called upon every new round
 *
 */
public Action GetBossPercents(Handle timer)
{
	// We need to do things a little differently if it's Dark Carnival: Remix
	if (g_bIsRemix)
	{
		// Our boss percents should be set for us via the Workaround method on round one - so lets skip it
		if (InSecondHalfOfRound()) 
		{
			// When the first round begines, this variables are set. So, we can just copy them for our second round.
			g_fWitchPercent = g_fDKRFirstRoundWitchPercent;
			g_fTankPercent = g_fDKRFirstRoundTankPercent;
			
		}
		else 
		{
			// Bosses cannot be changed on Dark Carnival: Remix maps. Unless they are completely disabled. So, we need to check if that's the case here
			
			//if (g_bDKRFirstRoundBossesSet)
			//{
				// If the Witch is not set to spawn this round, set it's percentage to 0
				if (!L4D2Direct_GetVSWitchToSpawnThisRound(0))
				{
					// Not quite enough yet. We also want to check if the flow is 0
					if ((GetWitchFlow(0) * 100.0) < 1) 
					{
						// One last check
							if (g_bWitchDisabled)
								g_fWitchPercent = 0;				
					}
				}
				else 
				{
					// The boss must have been re-enabled :)
					g_fWitchPercent = g_fDKRFirstRoundWitchPercent;
				}
				
				// If the Tank is not set to spawn this round, set it's percentage to 0
				if (!L4D2Direct_GetVSTankToSpawnThisRound(0))
				{
					// Not quite enough yet. We also want to check if the flow is 0
					if ((GetTankFlow(0) * 100) < 1) 
					{
						// One last check
							if (g_bTankDisabled)
								g_fTankPercent = 0;		
					}
				}
				else 
				{
					// The boss must have been re-enabled :)
					g_fTankPercent = g_fDKRFirstRoundTankPercent;
				}
			//}
		}
	} 
	else 
	{
		// This will be any map besides Remix
		if (InSecondHalfOfRound()) 
		{

			// We're in the second round
			
			// If the witch flow isn't already 0 from the first round then get the round 2 witch flow
			if (g_fWitchPercent != 0)
				g_fWitchPercent = RoundToNearest(GetWitchFlow(1) * 100.0);
				
			// If the tank flow isn't already 0 from the first round then get the round 2 tank flow
			if (g_fTankPercent != 0)
				g_fTankPercent = RoundToNearest(GetTankFlow(1) * 100.0);
				
		}
		else 
		{
		
			// We're in the first round.
			
			// Set our boss percents to 0 - If bosses are not set to spawn this round, they will remain 0
			g_fWitchPercent = 0;
			g_fTankPercent = 0;
		
			// If the Witch is set to spawn this round. Find the witch flow and set it as our witch percent
			if (L4D2Direct_GetVSWitchToSpawnThisRound(0))
			{
				g_fWitchPercent = RoundToNearest(GetWitchFlow(0) * 100.0);
			}
			
			// If the Tank is set to spawn this round. Find the witch flow and set it as our witch percent
			if (L4D2Direct_GetVSTankToSpawnThisRound(0))
			{
				g_fTankPercent = RoundToNearest(GetTankFlow(0) * 100.0);
			}
			
		}
	}
	
	// Finally build up our string for effiency, yea.
	ProcessBossString();
}

/* 
 *
 * This method will update the ready up footer with our
 * current boss percntages
 * This method will be called upon every new round
 *
 */
void UpdateReadyUpFooter(float interval = 0.1)
{
	static float fPrevTime = 0.0;
	
	if (fPrevTime == 0.0)
		fPrevTime = GetEngineTime();
	
	float fTime = GetEngineTime() + interval;
	if (fTime < fPrevTime)
		return;
	
	fPrevTime = fTime;
	
	if (g_hUpdateFooterTimer == null)
		g_hUpdateFooterTimer = CreateTimer(interval, Timer_UpdateReadyUpFooter);
}

public Action Timer_UpdateReadyUpFooter(Handle timer) 
{
	g_hUpdateFooterTimer = null;
	
	// Check to see if Ready Up plugin is available
	if (g_ReadyUpAvailable) 
	{
		// Create some variables
		char p_sTankString[32]; // Private Variable - Where our formatted Tank string will be kept
		char p_sWitchString[32]; // Private Variable - Where our formatted Witch string will be kept
		bool p_bStaticTank; // Private Variable - Stores if current map contains static tank spawn
		bool p_bStaticWitch; // Private Variable - Stores if current map contains static witch spawn
		char p_sNewFooter[65]; // Private Variable - Where our new footer string will be kept

		
		// Check if the current map is from Dark Carnival: Remix
		if (!g_bIsRemix)
		{
			p_bStaticTank = IsStaticTankMap();
			p_bStaticWitch = IsStaticWitchMap();
		}

		// Format our Tank String
		if (g_fTankPercent > 0) // If Tank percent is not 0
		{
			Format(p_sTankString, sizeof(p_sTankString), "Tank: %d%%", g_fTankPercent);
		}
		else if (g_bTankDisabled) // If another plugin has disabled the tank
		{
			Format(p_sTankString, sizeof(p_sTankString), "Tank: Disabled");
		}
		else if (p_bStaticTank) // If current map contains static Tank
		{
			Format(p_sTankString, sizeof(p_sTankString), "Tank: Static Spawn");
		}
		else // There is no Tank (Flow = 0)
		{
			Format(p_sTankString, sizeof(p_sTankString), "Tank: None");
		}
		
		// Format our Witch String
		if (g_fWitchPercent > 0) // If Witch percent is not 0
		{
			Format(p_sWitchString, sizeof(p_sWitchString), "Witch: %d%%", g_fWitchPercent);
		}
		else if (g_bWitchDisabled) // If another plugin has disabled the witch
		{
			Format(p_sWitchString, sizeof(p_sWitchString), "Witch: Disabled");
		}
		else if (p_bStaticWitch) // If current map contains static Witch
		{
			Format(p_sWitchString, sizeof(p_sWitchString), "Witch: Static Spawn");
		}
		else // There is no Witch (Flow = 0)
		{
			Format(p_sWitchString, sizeof(p_sWitchString), "Witch: None");
		}
		
		// Combine our Tank and Witch strings together
		if (g_bCvarWitchPercent && g_bCvarTankPercent) // Display Both Tank and Witch Percent
		{
			Format(p_sNewFooter, sizeof(p_sNewFooter), "%s, %s", p_sTankString, p_sWitchString);
		}
		else if (g_bCvarWitchPercent) // Display just Witch Percent
		{
			Format(p_sNewFooter, sizeof(p_sNewFooter), "%s", p_sWitchString);
		}
		else if (g_bCvarTankPercent) // Display just Tank Percent
		{
			Format(p_sNewFooter, sizeof(p_sNewFooter), "%s", p_sTankString);
		}	
		
		// Check to see if the Ready Up footer has already been added 
		if (g_bReadyUpFooterAdded) 
		{
			// Ready Up footer already exists, so we can just edit it.
			EditFooterStringAtIndex(g_iReadyUpFooterIndex, p_sNewFooter);
		}
		else
		{
			// Ready Up footer hasn't been added yet. Must be the start of a new round! Lets add it.
			g_iReadyUpFooterIndex = AddStringToReadyFooter(p_sNewFooter);
			g_bReadyUpFooterAdded = true;
		}
	}
}

/* ========================================================
// ====================== Section #7 ======================
// ======================= Commands =======================
// ========================================================
 *
 * This is where all of our boss commands will go
 *
 * vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
*/

public Action BossCmd(int client, int args)
{
	// Show our boss percents
	if (client)
	{
		PrintBossPercents(client);
		RequestFrame(PrintCurrent, GetClientUserId(client));
	}
}

public void PrintCurrent(int userid) {
	int client = GetClientOfUserId(userid);
	if (client) FakeClientCommand(client, "say /current");
}

void ProcessBossString()
{
	// Create some variables
	bool p_bStaticTank; // Private Variable - Stores if current map contains static tank spawn
	bool p_bStaticWitch; // Private Variable - Stores if current map contains static witch spawn

		
	// Check if the current map is from Dark Carnival: Remix
	if (!g_bIsRemix)
	{
		// Not part of the Dark Carnival: Remix Campaign -- Check to see if map contains static boss spawns - and store it to a bool variable
		p_bStaticTank = IsStaticTankMap();
		p_bStaticWitch = IsStaticWitchMap();
	}
	
	// Format String For Tank
	if (g_fTankPercent > 0) // If Tank percent is not equal to 0
	{
		Format(g_sTankString, sizeof(g_sTankString), "<{olive}Tank{default}> {red}%d%%", g_fTankPercent);
	}  
	else if (g_bTankDisabled) // If another plugin has disabled the tank
	{
		Format(g_sTankString, sizeof(g_sTankString), "<{olive}Tank{default}> {red}Disabled");
	} 
	else if (p_bStaticTank) // If current map has static Tank spawn
	{
		Format(g_sTankString, sizeof(g_sTankString), "<{olive}Tank{default}> {red}Static Spawn");
	} 
	else // There is no Tank
	{
		Format(g_sTankString, sizeof(g_sTankString), "<{olive}Tank{default}> {red}None");
	}
	
	// Format String For Witch
	if (g_fWitchPercent > 0) // If Witch percent is not equal to 0
	{
		Format(g_sWitchString, sizeof(g_sWitchString), "<{olive}Witch{default}> {red}%d%%", g_fWitchPercent);
	}  
	else if (g_bWitchDisabled) // If another plugin has disabled the witch
	{
		Format(g_sWitchString, sizeof(g_sWitchString), "<{olive}Witch{default}> {red}Disabled");
	} 
	else if (p_bStaticWitch) // If current map has static Witch spawn
	{
		Format(g_sWitchString, sizeof(g_sWitchString), "<{olive}Witch{default}> {red}Static Spawn");
	} 
	else // There is no Witch
	{
		Format(g_sWitchString, sizeof(g_sWitchString), "<{olive}Witch{default}> {red}None");
	}
}

void PrintBossPercents(int client = 0)
{
	// Print Messages to client
	
	int teamflag = 0;
	
	if (!client)
	{
		teamflag = (1 << 4) - 2; // without team 0
	}
	else if (g_bCvarGlobalPercent)
	{
		int team = GetClientTeam(client);
		if (team > 1)
			teamflag = (1 << team);
	}
	
	if (g_bCvarTankPercent)
	{
		if (teamflag > 0)
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i) && (teamflag & (1 << GetClientTeam(i))))
					CPrintToChat(i, g_sTankString);
			}
		}
		else
		{
			CPrintToChat(client, g_sTankString);
		}
	}
	if (g_bCvarWitchPercent)
	{
		if (teamflag > 0)
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i) && (teamflag & (1 << GetClientTeam(i))))
					CPrintToChat(i, g_sWitchString);
			}
		}
		else
		{
			CPrintToChat(client, g_sWitchString);
		}
	}
}

/* ========================================================
// ====================== Section #8 ======================
// ====================== Boss Votin ======================
// ========================================================
 *
 *
 *
 * vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
*/

public Action UpdatedForward(Handle timer)
{
	Call_StartForward(g_forwardUpdateBosses);
	Call_Finish();
}

bool IsInteger(const char[] buffer)
{
	// negative check
	if ( !IsCharNumeric(buffer[0]) && buffer[0] != '-' )
		return false;
	
	int len = strlen(buffer);
	for (int i = 1; i < len; i++)
	{
		if ( !IsCharNumeric(buffer[i]) )
			return false;
	}

	return true;
}

bool RunVoteChecks(int client)
{
	if (g_bIsRemix)
	{
		CPrintToChat(client, "{blue}<{green}BossVote{blue}>{default} Boss voting is not available on this map.");
		return false;
	}
	if (!IsInReady())
	{
		CPrintToChat(client, "{blue}<{green}BossVote{blue}>{default} Boss voting is only available during ready up.");
		return false;
	}
	if (InSecondHalfOfRound())
	{
		CPrintToChat(client, "{blue}<{green}BossVote{blue}>{default} Boss voting is only available during the first round of a map.");
		return false;
	}
	if (GetClientTeam(client) == 1)
	{
		CPrintToChat(client, "{blue}<{green}BossVote{blue}>{default} Boss voting is not available for spectators.");
		return false;
	}
	if (!IsNewBuiltinVoteAllowed())
	{
		CPrintToChat(client, "{blue}<{green}BossVote{blue}>{default} Boss Vote cannot be called right now...");
		return false;
	}
	return true;
}

public Action VoteBossCmd(int client, int args)
{
	if (!GetConVarBool(g_hCvarBossVoting)) return;
	if (!RunVoteChecks(client)) return;
	if (args != 2)
	{
		CPrintToChat(client, "{blue}<{green}BossVote{blue}>{default} Usage: !voteboss {olive}<{default}tank{olive}> <{default}witch{olive}>{default}.");
		CPrintToChat(client, "{blue}<{green}BossVote{blue}>{default} Use {default}\"{blue}0{default}\" for {olive}No Spawn{default}, \"{blue}-1{default}\" for {olive}Ignorance.");
		return;
	}
	
	// Get all non-spectating players
	int iNumPlayers;
	int[] iPlayers = new int[MaxClients];
	for (int i=1; i<=MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || (GetClientTeam(i) == 1))
		{
			continue;
		}
		iPlayers[iNumPlayers++] = i;
	}
	
	// Get Requested Boss Percents
	char bv_sTank[8];
	char bv_sWitch[8];
	GetCmdArg(1, bv_sTank, 8);
	GetCmdArg(2, bv_sWitch, 8);
	
	bv_iTank = -1;
	bv_iWitch = -1;
	
	// Make sure the args are actual numbers
	if (!IsInteger(bv_sTank) || !IsInteger(bv_sWitch))
	{
		CPrintToChat(client, "{blue}<{green}BossVote{blue}>{default} Percentages are {olive}invalid{default}.");
		return;
	}
	
	// Check to make sure static bosses don't get changed
	if (!IsStaticTankMap())
	{
		bv_bTank = (bv_iTank = StringToInt(bv_sTank)) > 0;
	}
	else
	{
		bv_bTank = false;
		CPrintToChat(client, "{blue}<{green}BossVote{blue}>{default} Tank spawn is static and can not be changed on this map.");
	}
	
	if (!IsStaticWitchMap())
	{
		bv_bWitch = (bv_iWitch = StringToInt(bv_sWitch)) > 0;
	}
	else
	{
		bv_bWitch = false;
		CPrintToChat(client, "{blue}<{green}BossVote{blue}>{default} Witch spawn is static and can not be changed on this map.");
	}
	
	// Check if percent is within limits
	if (!ValidateFlow(bv_iTank, bv_iWitch, bv_bTank, bv_bWitch))
	{
		CPrintToChat(client, "{blue}<{green}BossVote{blue}>{default} Percentages are {blue}banned{default}.");
		return;
	}
	
	char bv_voteTitle[64];
	
	// Set vote title
	if (bv_bTank && bv_bWitch)	// Both Tank and Witch can be changed 
	{
		Format(bv_voteTitle, 64, "Set Tank to: %s and Witch to: %s?", bv_sTank, bv_sWitch);
	}
	else if (bv_bTank)	// Only Tank can be changed
	{
		if (bv_iWitch == 0)
		{
			Format(bv_voteTitle, 64, "Set Tank to: %s and Witch to: Disabled?", bv_sTank);
		}
		else
		{
			Format(bv_voteTitle, 64, "Set Tank to: %s?", bv_sTank);
		}
	}
	else if (bv_bWitch) // Only Witch can be changed
	{
		if (bv_iTank == 0)
		{
			Format(bv_voteTitle, 64, "Set Tank to: Disabled and Witch to: %s?", bv_sWitch);
		}
		else
		{
			Format(bv_voteTitle, 64, "Set Witch to: %s?", bv_sWitch);
		}
	}
	else // Neither can be changed... ok...
	{
		if (bv_iTank == 0 && bv_iWitch == 0)
		{
			Format(bv_voteTitle, 64, "Set Bosses to: Disabled?");
		}
		else if (bv_iTank == 0)
		{
			Format(bv_voteTitle, 64, "Set Tank to: Disabled?");
		}
		else if (bv_iWitch == 0)
		{
			Format(bv_voteTitle, 64, "Set Witch to: Disabled?");
		}
		else // Probably not.
		{
			return;
		}
	}
	
	// Start the vote!
	bv_hVote = CreateBuiltinVote(BossVoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);
	SetBuiltinVoteArgument(bv_hVote, bv_voteTitle);
	SetBuiltinVoteInitiator(bv_hVote, client);
	SetBuiltinVoteResultCallback(bv_hVote, BossVoteResultHandler);
	DisplayBuiltinVote(bv_hVote, iPlayers, iNumPlayers, 20);
	FakeClientCommand(client, "Vote Yes");
}

public void BossVoteActionHandler(Handle vote, BuiltinVoteAction action, int param1, int param2)
{
	switch (action)
	{
		case BuiltinVoteAction_End:
		{
			bv_hVote = INVALID_HANDLE;
			CloseHandle(vote);
		}
		case BuiltinVoteAction_Cancel:
		{
			DisplayBuiltinVoteFail(vote, view_as<BuiltinVoteFailReason>(param1));
		}
	}
}

public void BossVoteResultHandler(Handle vote, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
	for (int i=0; i<num_items; i++)
	{
		if (item_info[i][BUILTINVOTEINFO_ITEM_INDEX] == BUILTINVOTES_VOTE_YES)
		{
			if (item_info[i][BUILTINVOTEINFO_ITEM_VOTES] > (num_clients / 2))
			{
			
				// One last ready-up check.
				if (!IsInReady())  {
					DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
					CPrintToChatAll("{blue}<{green}BossVote{blue}>{default} Spawns can only be set during ready up.");
					return;
				}
				
				if (bv_bTank && bv_bWitch)	// Both Tank and Witch can be changed 
				{
					DisplayBuiltinVotePass(vote, "Setting Boss Spawns...");
				}
				else if (bv_bTank)	// Only Tank can be changed -- Witch must be static
				{
					DisplayBuiltinVotePass(vote, "Setting Tank Spawn...");
				}
				else if (bv_bWitch) // Only Witch can be changed -- Tank must be static
				{
					DisplayBuiltinVotePass(vote, "Setting Witch Spawn...");
				}
				else // Neither can be changed... ok...
				{
					DisplayBuiltinVotePass(vote, "Setting Boss Disabled...");
				}
				
				SetTankPercent(bv_iTank);
				SetWitchPercent(bv_iWitch);
				
				// Update our shiz yo
				CreateTimer(0.1, GetBossPercents);
				UpdateReadyUpFooter(0.2);
				
				// Forward da message man :)
				Call_StartForward(g_forwardUpdateBosses);
				Call_Finish();
				
				return;
			}
		}
	}
	
	// Vote Failed
	DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
	return;
}

// credit to SirPlease
bool ValidateFlow(int iTankFlow = -1,
				int iWitchFlow = -1,
				bool bCheckTank = false,
				bool bCheckWitch = false)
{
	int iBossMinFlow = RoundToCeil(GetConVarFloat(g_hVsBossFlowMin) * 100);
	int iBossMaxFlow = RoundToFloor(GetConVarFloat(g_hVsBossFlowMax) * 100);
	
	// mapinfo override
	iBossMinFlow = LGO_GetMapValueInt("versus_boss_flow_min", iBossMinFlow);
	iBossMaxFlow = LGO_GetMapValueInt("versus_boss_flow_max", iBossMaxFlow);

	if (bCheckTank)
	{
		if (iTankFlow < iBossMinFlow || iBossMaxFlow < iTankFlow)
			return false;
		
		int iMinBanFlow = LGO_GetMapValueInt("tank_ban_flow_min", 101);
		int iMaxBanFlow = LGO_GetMapValueInt("tank_ban_flow_max", 101);
		int iMinBanFlowB = LGO_GetMapValueInt("tank_ban_flow_min_b", 101);
		int iMaxBanFlowB = LGO_GetMapValueInt("tank_ban_flow_max_b", 101);
		int iMinBanFlowC = LGO_GetMapValueInt("tank_ban_flow_min_c", 101);
		int iMaxBanFlowC = LGO_GetMapValueInt("tank_ban_flow_max_c", 101);
		
		if ((iMinBanFlow <= iTankFlow <= iMaxBanFlow)
		|| (iMinBanFlowB <= iTankFlow <= iMaxBanFlowB)
		|| (iMinBanFlowC <= iTankFlow <= iMaxBanFlowC))
			return false;
	}
	
	if (bCheckWitch)
	{
		iBossMinFlow = LGO_GetMapValueInt("witch_flow_min", iBossMinFlow);
		iBossMaxFlow = LGO_GetMapValueInt("witch_flow_max", iBossMaxFlow);
		
		if (iWitchFlow < iBossMinFlow || iBossMaxFlow < iWitchFlow)
			return false;
	}
	
	// Any boss change is requested and passes validation
	// Any boss disabling is requested
	return bCheckTank || bCheckWitch || iTankFlow == 0 || iWitchFlow == 0;
}

void SetWitchPercent(int percent)
{
	if (IsStaticWitchMap())
		return;
	
	if (percent == -1)
		return;
	
	g_bWitchDisabled = (percent == 0);
	
	if (percent == 0)
	{
		L4D2Direct_SetVSWitchFlowPercent(0, 0.0);
		L4D2Direct_SetVSWitchFlowPercent(1, 0.0);
		L4D2Direct_SetVSWitchToSpawnThisRound(0, false);
		L4D2Direct_SetVSWitchToSpawnThisRound(1, false);
	}
	else if (percent == 100)
	{
		L4D2Direct_SetVSWitchFlowPercent(0, 1.0);
		L4D2Direct_SetVSWitchFlowPercent(1, 1.0);
		L4D2Direct_SetVSWitchToSpawnThisRound(0, true);
		L4D2Direct_SetVSWitchToSpawnThisRound(1, true);
	}
	else
	{
		float p_newPercent = (float(percent)/100);
		L4D2Direct_SetVSWitchFlowPercent(0, p_newPercent);
		L4D2Direct_SetVSWitchFlowPercent(1, p_newPercent);
		L4D2Direct_SetVSWitchToSpawnThisRound(0, true);
		L4D2Direct_SetVSWitchToSpawnThisRound(1, true);
	}
}

void SetTankPercent(int percent)
{
	if (IsStaticTankMap())
		return;
	
	if (percent == -1)
		return;
		
	g_bTankDisabled = (percent == 0);
	
	if (percent == 0)
	{
		L4D2Direct_SetVSTankFlowPercent(0, 0.0);
		L4D2Direct_SetVSTankFlowPercent(1, 0.0);
		L4D2Direct_SetVSTankToSpawnThisRound(0, false);
		L4D2Direct_SetVSTankToSpawnThisRound(1, false);
	}
	else if (percent == 100)
	{
		L4D2Direct_SetVSTankFlowPercent(0, 1.0);
		L4D2Direct_SetVSTankFlowPercent(1, 1.0);
		L4D2Direct_SetVSTankToSpawnThisRound(0, true);
		L4D2Direct_SetVSTankToSpawnThisRound(1, true);
	}
	else
	{
		float p_newPercent = (float(percent)/100);
		L4D2Direct_SetVSTankFlowPercent(0, p_newPercent);
		L4D2Direct_SetVSTankFlowPercent(1, p_newPercent);
		L4D2Direct_SetVSTankToSpawnThisRound(0, true);
		L4D2Direct_SetVSTankToSpawnThisRound(1, true);
	}
}

/* ========================================================
// ====================== Section #9 ======================
// ==================== Admin Commands ====================
// ========================================================
 *
 * Where the admin commands for setting boss spawns will go
 *
 * vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
*/

public Action ForceTankCommand(int client, int args)
{
	if (!GetConVarBool(g_hCvarBossVoting)) return;
	if (g_bIsRemix)
	{
		CPrintToChat(client, "{blue}<{green}BossVote{blue}>{default} Command not available on this map.");
		return;
	}
	
	if (IsStaticTankMap())
	{
		CPrintToChat(client, "{blue}<{green}BossVote{blue}>{default} Tank spawn is static and can not be changed on this map.");
		return;
	}
	
	if (!IsInReady())
	{
		CPrintToChat(client, "{blue}<{green}BossVote{blue}>{default} Command can only be used during ready up.");
		return;
	}
	
	// Get Requested Tank Percent
	char bv_sTank[32];
	GetCmdArg(1, bv_sTank, 32);
	
	// Make sure the cmd argument is a number
	if (!IsInteger(bv_sTank))
		return;
	
	// Convert it to in int boy
	int p_iRequestedPercent = StringToInt(bv_sTank);
	
	if (p_iRequestedPercent < 0)
	{
		CPrintToChat(client, "{blue}<{green}BossVote{blue}>{default} Percentage is {blue}invalid{default}.");
		return;
	}
	
	// Check if percent is within limits
	if (!ValidateFlow(p_iRequestedPercent, _, p_iRequestedPercent > 0))
	{
		CPrintToChat(client, "{blue}<{green}BossVote{blue}>{default} Percentage is {blue}banned{default}.");
		return;
	}
	
	// Set the boss
	SetTankPercent(p_iRequestedPercent);
	
	// Let everybody know
	char clientName[32];
	GetClientName(client, clientName, sizeof(clientName));
	CPrintToChatAll("{blue}<{green}BossVote{blue}>{default} Tank spawn set to {olive}%i%%{default} by Admin {blue}%s{default}.", p_iRequestedPercent, clientName);
	
	// Update our shiz yo
	CreateTimer(0.1, GetBossPercents);
	UpdateReadyUpFooter(0.2);
	
	// Forward da message man :)
	CreateTimer(0.5, UpdatedForward);
	return;
}

public Action ForceWitchCommand(int client, int args)
{
	if (!GetConVarBool(g_hCvarBossVoting)) return;
	if (g_bIsRemix)
	{
		CPrintToChat(client, "{blue}<{green}BossVote{blue}>{default} Command not available on this map.");
		return;
	}
	
	if (IsStaticWitchMap())
	{
		CPrintToChat(client, "{blue}<{green}BossVote{blue}>{default} Witch spawn is static and can not be changed on this map.");
		return;
	}
	
	if (!IsInReady())
	{
		CPrintToChat(client, "{blue}<{green}BossVote{blue}>{default} Command can only be used during ready up.");
		return;
	}
	
	// Get Requested Witch Percent
	char bv_sWitch[32];
	GetCmdArg(1, bv_sWitch, 32);
	
	// Make sure the cmd argument is a number
	if (!IsInteger(bv_sWitch))
		return;
	
	// Convert it to in int boy
	int p_iRequestedPercent = StringToInt(bv_sWitch);
	
	if (p_iRequestedPercent < 0)
	{
		CPrintToChat(client, "{blue}<{green}BossVote{blue}>{default} Percentage is {blue}invalid{default}.");
		return;
	}
	
	// Check if percent is within limits
	if (!ValidateFlow(_, p_iRequestedPercent, _, p_iRequestedPercent > 0))
	{
		CPrintToChat(client, "{blue}<{green}BossVote{blue}>{default} Percentage is {olive}banned{default}.");
		return;
	}
	
	// Set the boss
	SetWitchPercent(p_iRequestedPercent);
	
	// Let everybody know
	char clientName[32];
	GetClientName(client, clientName, sizeof(clientName));
	CPrintToChatAll("{blue}<{green}BossVote{blue}>{default} Witch spawn set to {olive}%i%%{default} by Admin {blue}%s{default}.", p_iRequestedPercent, clientName);
	
	// Update our shiz yo
	CreateTimer(0.1, GetBossPercents);
	UpdateReadyUpFooter(0.2);
	
	// Forward da message man :)
	CreateTimer(0.5, UpdatedForward);
	return;
}