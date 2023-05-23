#include <sourcemod>
#include <sdkhooks>
#include <colors>
#define L4D2UTIL_STOCKS_ONLY
#include <l4d2util>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.8"

public Plugin myinfo = 
{
	name = "L4D2 Tank Facts Announce",
	author = "Forgetest (credit to Griffin and Blade)",
	description = "Announce damage dealt to survivors by tank",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
};

// TODO:
// Use ArrayList to keep individual attacks since Tank won't create massive data.
// In this way more flexible info is allowed.
enum struct TankAttack_s
{
	int Punch;
	int Rock;
	int Hittable;
	
	void Init() {
		this.Punch = this.Rock = this.Hittable = 0;
	}
}
static TankAttack_s g_TankAttack;

enum struct AttackResult_s
{
	int Incap;
	int Death;
	int TotalDamage;
	
	void Init() {
		this.Incap = this.Death = this.TotalDamage = 0;
	}
}
static AttackResult_s g_TankResult;


static int			g_iTankClient						= 0;
static int			g_iPlayerLastHealth[MAXPLAYERS+1]	= {0, ...};
static bool			g_bAnnounceTankFacts				= false;
static bool			g_bTankInPlay						= false;
static float		g_fTankSpawnTime					= 0.0;
static char			g_sLastHumanTankName[MAX_NAME_LENGTH] = "";

static bool			g_bLateLoad							= false;

static ConVar		director_tank_lottery_selection_time = null;


public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_Max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

#define TRANSLATION_FILE "l4d2_tank_facts_announce.phrases"
void LoadPluginTranslations()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "translations/"...TRANSLATION_FILE...".txt");
	if (!FileExists(sPath))
	{
		SetFailState("Missing translation \""...TRANSLATION_FILE..."\"");
	}
	LoadTranslations(TRANSLATION_FILE);
}

public void OnPluginStart()
{
	LoadPluginTranslations();
	
	HookEvent("round_start", Event_OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_OnRoundEnd, EventHookMode_PostNoCopy);
	
	HookEvent("tank_spawn", Event_OnTankSpawn);
	HookEvent("player_hurt", Event_OnPlayerHurt);
	HookEvent("player_incapacitated_start", Event_PlayerIncapStart);
	HookEvent("player_death", Event_PlayerKilled);
	
	director_tank_lottery_selection_time = FindConVar("director_tank_lottery_selection_time");
	
	if (g_bLateLoad)
	{
		for (int i = 1; i <= MaxClients; i++)
			if (IsClientInGame(i)) OnClientPutInServer(i);
	}
}

void Event_OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	ClearStuff();
}

void Event_OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bAnnounceTankFacts) PrintTankSkill();
	ClearStuff();
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	
	if (g_bTankInPlay && !IsFakeClient(client) && client == g_iTankClient)
	{
		CreateTimer(0.1, Timer_CheckTank, client); // Use a delayed timer due to bugs where the tank passes to another player
	}
}

Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!g_bTankInPlay) return Plugin_Continue;
	
	if (!IsValidEntity(victim) || !IsValidEntity(attacker) || !IsValidEdict(inflictor)) return Plugin_Continue;
	
	if (!attacker || attacker > MaxClients) return Plugin_Continue;
	
	if (!IsSurvivor(victim) || !IsTank(attacker)) return Plugin_Continue;
	
	//char classname[64];
	//GetEdictClassname(inflictor, classname, sizeof(classname));
	
	if (attacker == g_iTankClient /*|| IsTankHittable(classname)*/)
	{
		int playerHealth = GetSurvivorPermanentHealth(victim) + GetSurvivorTemporaryHealth(victim);
		if (RoundToFloor(damage) >= playerHealth)
		{
			/* Store HP only when the damage is greater than this, so we can turn to IncapStart for Damage record */
			g_iPlayerLastHealth[victim] = playerHealth;
		}
	}
		
	return Plugin_Continue;
}

// TODO: Support for multiple tanks
void Event_OnTankSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_iTankClient = client;
	
	// In case the tank control becomes AI, keep his name first.
	if (!IsFakeClient(client)) GetClientName(client, g_sLastHumanTankName, sizeof(g_sLastHumanTankName));
	
	if (g_bTankInPlay) return;
	
	g_bTankInPlay = true;
	g_bAnnounceTankFacts = true;
	g_fTankSpawnTime = GetGameTime() + director_tank_lottery_selection_time.FloatValue;
}

void Event_OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bTankInPlay) return;
	
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if (!victim || !IsSurvivor(victim) || IsIncapacitated(victim)) return;
	
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	
	char weapon[64];
	event.GetString("weapon", weapon, sizeof(weapon));
	
	if (attacker != g_iTankClient) return;
	
	int dmg = event.GetInt("dmg_health");
	if (dmg > 0)
	{
		if (StrEqual(weapon, "tank_claw")) {
			g_TankAttack.Punch++;
		} else if (StrEqual(weapon, "tank_rock")) {
			g_TankAttack.Rock++;
		//} else if (IsTankHittable(weapon)) {
		} else { // workaround due to "l4d2_hittable_control" setting 'inflictor' to 0 for hittables
			g_TankAttack.Hittable++;
		}
		
		g_TankResult.TotalDamage += dmg;
	}
}

void Event_PlayerIncapStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bTankInPlay) return;
	
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if (!victim || !IsSurvivor(victim)) return;
	
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	
	char weapon[64];
	event.GetString("weapon", weapon, sizeof(weapon));
	
	if (StrEqual(weapon, "tank_claw")) {
		g_TankAttack.Punch++;
	} else if (StrEqual(weapon, "tank_rock")) {
		g_TankAttack.Rock++;
	//} else if (IsTankHittable(weapon)) {
	} else if (attacker == g_iTankClient) { // workaround due to "l4d2_hittable_control" setting 'inflictor' to 0 for hittables
		g_TankAttack.Hittable++;
	}
	
	g_TankResult.Incap++;
	if (attacker == g_iTankClient) g_TankResult.TotalDamage += g_iPlayerLastHealth[victim];
}

void Event_PlayerKilled(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bTankInPlay) return;
	
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if (!victim) return;
	
	if (IsSurvivor(victim))
	{
		g_TankResult.Death++;
	}
	else if (victim == g_iTankClient)
	{
		CreateTimer(0.1, Timer_CheckTank, victim);
	}
}

Action Timer_CheckTank(Handle timer, int oldtankclient)
{
	if (g_iTankClient != oldtankclient) return Plugin_Stop; // Tank passed

	int tankclient = FindTankClient(-1);
	if (tankclient && tankclient != oldtankclient)
	{
		g_iTankClient = tankclient;
		return Plugin_Stop;
	}

	if (g_bAnnounceTankFacts) PrintTankSkill();
	
	ClearStuff();
	
	return Plugin_Stop;
}

void PrintTankSkill()
{
	int tankclient = GetTankClient();
	if (!tankclient) return;
	
	char name[MAX_NAME_LENGTH];
	if (IsFakeClient(tankclient))
	{
		if (g_sLastHumanTankName[0] != '\0')
			Format(name, sizeof(name), "AI [%s]", g_sLastHumanTankName);
		else Format(name, sizeof(name), "AI");
	}
	else GetClientName(tankclient, name, sizeof(name));
	
	int duration = RoundToFloor(GetGameTime() - g_fTankSpawnTime);
	
	DataPack dp;
	CreateDataTimer(3.0, Timer_PrintToChat, dp, TIMER_FLAG_NO_MAPCHANGE);
	
	dp.WriteString(name);
	dp.WriteCell(duration / 60);
	dp.WriteCell(duration % 60);
	dp.WriteCellArray(g_TankAttack, sizeof(g_TankAttack));
	dp.WriteCellArray(g_TankResult, sizeof(g_TankResult));
}

Action Timer_PrintToChat(Handle timer, DataPack dp)
{
	dp.Reset();
	
	// CSayText appears to be async or via text stream?, whatever it costs random amount of time.
	// For unknown reason stacking color tags can slow certain processing of message.
	// To print messages in a proper order, extra tags should be added in front.
	
	char name[MAX_NAME_LENGTH];
	dp.ReadString(name, sizeof(name));
	
	int minutes = dp.ReadCell();
	int seconds = dp.ReadCell();
	
	TankAttack_s attack;
	AttackResult_s result;
	dp.ReadCellArray(attack, 3);
	dp.ReadCellArray(result, 3);
	
	// [!] Facts of the Tank (AI)
	// > Punch: 4 / Rock: 2 / Hittable: 0
	// > Incap: 1 / Death: 0 from Survivors
	// > Duration: 1min 7s / Total Damage: 144
	
	CPrintToChatAll("%t", "Announce_Title", name);
	CPrintToChatAll("%t", "Announce_TankAttack", attack.Punch, attack.Rock, attack.Hittable);
	CPrintToChatAll("%t", "Announce_AttackResult", result.Incap, result.Death);
	if (minutes > 0)
		CPrintToChatAll("%t", "Announce_Summary_WithMinute", minutes, seconds, result.TotalDamage);
	else
		CPrintToChatAll("%t", "Announce_Summary_WithoutMinute", seconds, result.TotalDamage);
	
	// Since the DataTimer would auto-close handles passed,
	// here we've just done.
	
	return Plugin_Stop;
}

void ClearStuff()
{
	g_iTankClient = 0;
	g_bTankInPlay = false;
	g_bAnnounceTankFacts = false;
	g_fTankSpawnTime = 0.0;
	strcopy(g_sLastHumanTankName, sizeof(g_sLastHumanTankName), "");
	
	g_TankAttack.Init();
	g_TankResult.Init();
	
	for (int i = 1; i <= MaxClients; i++)
	{
		g_iPlayerLastHealth[i] = 0;
	}
}


/* Stocks */

stock int GetTankClient()
{
	if (!g_bTankInPlay) return 0;

	int tankclient = g_iTankClient;

	if (!IsClientInGame(tankclient)) // If tank somehow is no longer in the game (kicked, hence events didn't fire)
	{
		tankclient = FindTankClient(-1); // find the tank client
		if (!tankclient) return 0;
		g_iTankClient = tankclient;
	}

	return tankclient;
}
