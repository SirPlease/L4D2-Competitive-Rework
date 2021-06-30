#include <sourcemod>
#include <colors>
#undef REQUIRE_PLUGIN
#include <readyup>
#define REQUIRE_PLUGIN

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0.4"

public Plugin myinfo =
{
    name = "Special Infected Class Announce",
    author = "Tabun, Forgetest",
    description = "Report what SI classes are up when the round starts.",
    version = PLUGIN_VERSION,
    url = "none"
}

#define ZC_SMOKER               1
#define ZC_BOOMER               2
#define ZC_HUNTER               3
#define ZC_SPITTER              4
#define ZC_JOCKEY               5
#define ZC_CHARGER              6
#define ZC_WITCH                7
#define ZC_TANK                 8

#define TEAM_SPECTATOR			1
#define TEAM_SURVIVOR			2
#define TEAM_INFECTED			3

#define MAXSPAWNS               8

#define CHAT_FLAG        (1 << 0)
#define HINT_FLAG        (1 << 1)

static const char g_csSIClassName[][] =
{
    "",
    "Smoker",
    "(Boomer)",
    "Hunter",
    "(Spitter)",
    "Jockey",
    "Charger",
    "",
    ""
};

Handle
	g_hAddFooterTimer;
	
ConVar
	g_hCvarFooter,
	g_hCvarPrint;
	
bool
	g_bRoundStarted,
	g_bAllowFooter,
	g_bMessagePrinted;

public void OnPluginStart()
{
	g_hCvarFooter	= CreateConVar(	"si_announce_ready_footer",
									"1",
									"Enable si class string be added to readyup panel as footer (if available).",
									FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	g_hCvarPrint	= CreateConVar(	"si_announce_print",
									"1",
									"Decide where the plugin prints the announce. (0: Disable, 1: Chat, 2: Hint, 3: Chat and Hint)",
									FCVAR_NOTIFY, true, 0.0, true, 3.0);
									
	HookEvent("round_start", view_as<EventHook>(Event_RoundStart), EventHookMode_PostNoCopy);
	HookEvent("round_end", view_as<EventHook>(Event_RoundEnd), EventHookMode_PostNoCopy);
	HookEvent("player_left_start_area", Event_PlayerLeftStartArea, EventHookMode_Post);
	HookEvent("player_team", Event_PlayerTeam);
}

public void OnMapEnd()
{
	g_bRoundStarted = false;
}

void ProcessReadyupFooter()
{
	if( GetFeatureStatus(FeatureType_Native, "AddStringToReadyFooter") == FeatureStatus_Available )
	{
		g_hAddFooterTimer = CreateTimer(7.0, UpdateReadyUpFooter, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void Event_RoundStart()
{
	g_bMessagePrinted = false;
	g_bRoundStarted = true;
	
	if (g_hCvarFooter.BoolValue)
	{
		g_bAllowFooter = true;
		ProcessReadyupFooter();
	}
	else
	{
		g_bAllowFooter = false;
	}
}

public void Event_RoundEnd()
{
	g_bRoundStarted = false;
}

public void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bAllowFooter) return;
	
	if (!g_bRoundStarted) return;
	
	if (g_hAddFooterTimer != null) return;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client) return;
	
	if (event.GetInt("team") == TEAM_INFECTED)
	{
		g_hAddFooterTimer = CreateTimer(1.0, UpdateReadyUpFooter, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action UpdateReadyUpFooter(Handle timer)
{
	g_hAddFooterTimer = null;
	
	if (!IsInfectedTeamFullAlive() || !g_bAllowFooter)
		return;
	
	char msg[65];
	if (ProcessSIString(msg, sizeof(msg), true))
		g_bAllowFooter = !(AddStringToReadyFooter(msg) != -1);
}

public void OnRoundIsLive()
{
	if (g_hCvarPrint.IntValue == 0)
		return;
	
	// announce SI classes up now
	char msg[128];
	if (ProcessSIString(msg, sizeof(msg)))
	{
		AnnounceSIClasses(msg);
		g_bMessagePrinted = true;
	}
}

public void Event_PlayerLeftStartArea(Event event, const char[] name, bool dontBroadcast)
{
	// if no readyup, use this as the starting event
	if (!g_bMessagePrinted) {
		char msg[128];
		if (ProcessSIString(msg, sizeof(msg)) && g_hCvarPrint.IntValue != 0)
			AnnounceSIClasses(msg);
			
		// no matter printed or not, we won't bother the game since survivor leaves saferoom.
		g_bMessagePrinted = true;
	}
}

#define COLOR_PARAM "%s{red}%s{default}"
#define NORMA_PARAM "%s%s"

bool ProcessSIString(char[] msg, int maxlength, bool footer = false)
{
	// get currently active SI classes
	int iSpawns;
	int iSpawnClass[MAXSPAWNS];
	
	for (int i = 1; i <= MaxClients && iSpawns < MAXSPAWNS; i++) {
		if (!IsClientInGame(i) || GetClientTeam(i) != TEAM_INFECTED || !IsPlayerAlive(i)) { continue; }
		
		iSpawnClass[iSpawns] = GetEntProp(i, Prop_Send, "m_zombieClass");
		
		if (iSpawnClass[iSpawns] != ZC_WITCH && iSpawnClass[iSpawns] != ZC_TANK)
			iSpawns++;
	}
	
	// found nothing :/
	if (!iSpawns) {
		return false;
	}
    
	strcopy(msg, maxlength, footer ? "SI: " : "Special Infected: ");
	
	int printFlags = g_hCvarPrint.IntValue;
	bool useColor = !footer && (printFlags & CHAT_FLAG);
	
	// format classes, according to amount of spawns found
	for (int i = 0; i < iSpawns; i++) {
		if (i) StrCat(msg, maxlength, ", ");
		
		Format(	msg,
				maxlength,
				(useColor ? COLOR_PARAM : NORMA_PARAM),
				msg,
				g_csSIClassName[iSpawnClass[i]]
		);
	}
	
	return true;
}

void AnnounceSIClasses(const char[] Message)
{
	char temp[128];
	
	int printFlags = g_hCvarPrint.IntValue;
	if (printFlags & HINT_FLAG)
	{
		strcopy(temp, sizeof temp, Message);
		CRemoveTags(temp, sizeof temp);
	}
	
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i) || GetClientTeam(i) == TEAM_INFECTED || (IsFakeClient(i) && !IsClientSourceTV(i))) { continue; }

		if (printFlags & CHAT_FLAG) CPrintToChat(i, Message);
		if (printFlags & HINT_FLAG) PrintHintText(i, temp);
    }
}

stock bool IsInfectedTeamFullAlive()
{
	static ConVar cMaxZombies;
	if (!cMaxZombies) cMaxZombies = FindConVar("z_max_player_zombies");
	
	int players = 0;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_INFECTED && IsPlayerAlive(i)) players++;
	}
	return players == cMaxZombies.IntValue;
}