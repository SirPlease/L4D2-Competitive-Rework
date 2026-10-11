#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "3.0"

#define TEAM_SURVIVOR 2

#define MAX_MELEE_CLASSES 32
#define MELEE_CLASS_LENGTH 64
#define MAX_RANDOM_SPAWNS 32

// Custom-list weapons: string-table prefix to match, paired with its cvar name suffix.
static const char g_sCustomMeleeClass[][] =
{
	"baseball_bat",
	"cricket_bat",
	"crowbar",
	"electric_guitar",
	"fireaxe",
	"frying_pan",
	"golfclub",
	"hunting_knife",
	"katana",
	"machete",
	"riotshield",
	"tonfa"
};

static const char g_sCustomMeleeCvarSuffix[][] =
{
	"BaseballBat",
	"CricketBat",
	"Crowbar",
	"ElecGuitar",
	"FireAxe",
	"FryingPan",
	"GolfClub",
	"Knife",
	"Katana",
	"Machete",
	"RiotShield",
	"Tonfa"
};

static const char g_sPrecacheModels[][] =
{
	"models/weapons/melee/v_bat.mdl",
	"models/weapons/melee/v_cricket_bat.mdl",
	"models/weapons/melee/v_crowbar.mdl",
	"models/weapons/melee/v_electric_guitar.mdl",
	"models/weapons/melee/v_fireaxe.mdl",
	"models/weapons/melee/v_frying_pan.mdl",
	"models/weapons/melee/v_golfclub.mdl",
	"models/weapons/melee/v_katana.mdl",
	"models/weapons/melee/v_machete.mdl",
	"models/weapons/melee/v_tonfa.mdl",
	"models/weapons/melee/w_bat.mdl",
	"models/weapons/melee/w_cricket_bat.mdl",
	"models/weapons/melee/w_crowbar.mdl",
	"models/weapons/melee/w_electric_guitar.mdl",
	"models/weapons/melee/w_fireaxe.mdl",
	"models/weapons/melee/w_frying_pan.mdl",
	"models/weapons/melee/w_golfclub.mdl",
	"models/weapons/melee/w_katana.mdl",
	"models/weapons/melee/w_machete.mdl",
	"models/weapons/melee/w_tonfa.mdl",
	"models/w_models/weapons/w_sniper_scout.mdl",
	"models/v_models/v_snip_scout.mdl"
};

static const char g_sPrecacheScripts[][] =
{
	"scripts/melee/baseball_bat.txt",
	"scripts/melee/cricket_bat.txt",
	"scripts/melee/crowbar.txt",
	"scripts/melee/electric_guitar.txt",
	"scripts/melee/fireaxe.txt",
	"scripts/melee/frying_pan.txt",
	"scripts/melee/golfclub.txt",
	"scripts/melee/katana.txt",
	"scripts/melee/machete.txt",
	"scripts/melee/tonfa.txt"
};

ConVar
	g_cvEnabled,
	g_cvRandom,
	g_cvRandomAmount,
	g_cvCustomMeleeCount[sizeof(g_sCustomMeleeClass)],
	g_cvGameMode;

Handle g_hSpawnTimer;

bool g_bSpawnedMelee;

int g_iMeleeClassCount;
char g_sMeleeClass[MAX_MELEE_CLASSES][MELEE_CLASS_LENGTH];

// Random picks from the first half, replayed in the second half of a versus round
// so both teams get the same saferoom melee set.
int g_iSavedSpawns[MAX_RANDOM_SPAWNS];
int g_iSavedSpawnCount;

public Plugin myinfo =
{
	name = "Melee In The Saferoom",
	author = "N3wton",
	description = "Spawns a selection of melee weapons in the saferoom, at the start of each round.",
	version = PLUGIN_VERSION
};

public void OnPluginStart()
{
	if (GetEngineVersion() != Engine_Left4Dead2) {
		SetFailState("Melee In The Saferoom is only supported on Left 4 Dead 2.");
	}

	g_cvGameMode = FindConVar("mp_gamemode");

	CreateConVar("l4d2_MITSR_Version", PLUGIN_VERSION, "The version of Melee In The Saferoom", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_cvEnabled = CreateConVar("l4d2_MITSR_Enabled", "1", "Should the plugin be enabled");
	g_cvRandom = CreateConVar("l4d2_MITSR_Random", "1", "Spawn Random Weapons (1) or custom list (0)");
	g_cvRandomAmount = CreateConVar("l4d2_MITSR_Amount", "8", "Number of weapons to spawn if l4d2_MITSR_Random is 1");

	char sName[64], sDescription[128];
	for (int i = 0; i < sizeof(g_sCustomMeleeClass); i++) {
		FormatEx(sName, sizeof(sName), "l4d2_MITSR_%s", g_sCustomMeleeCvarSuffix[i]);
		FormatEx(sDescription, sizeof(sDescription), "Number of %s to spawn (l4d2_MITSR_Random must be 0)", g_sCustomMeleeClass[i]);
		g_cvCustomMeleeCount[i] = CreateConVar(sName, "1", sDescription);
	}

	HookEvent("round_start", Event_RoundStart);

	RegAdminCmd("sm_melee", Command_SMMelee, ADMFLAG_KICK, "Lists all melee weapons spawnable in the current campaign");
}

public void OnMapStart()
{
	g_hSpawnTimer = null;
	g_bSpawnedMelee = false;
	g_iMeleeClassCount = 0;
	g_iSavedSpawnCount = 0;

	for (int i = 0; i < sizeof(g_sPrecacheModels); i++) {
		PrecacheModel(g_sPrecacheModels[i], true);
	}

	for (int i = 0; i < sizeof(g_sPrecacheScripts); i++) {
		PrecacheGeneric(g_sPrecacheScripts[i], true);
	}

	// NextMod hands out scouts through weapon customization; spawning one here
	// forces the weapon into the precache table before any late conversion.
	int iScout = CreateEntityByName("weapon_sniper_scout");
	if (iScout != -1) {
		DispatchSpawn(iScout);
		RemoveEdict(iScout);
	}
}

public void OnMapEnd()
{
	g_hSpawnTimer = null;
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_cvEnabled.BoolValue) {
		return;
	}

	g_bSpawnedMelee = false;
	GetMeleeClasses();

	delete g_hSpawnTimer;
	g_hSpawnTimer = CreateTimer(1.0, Timer_SpawnMelee, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_SpawnMelee(Handle timer)
{
	if (g_bSpawnedMelee) {
		g_hSpawnTimer = null;
		return Plugin_Stop;
	}

	if (g_iMeleeClassCount == 0) {
		GetMeleeClasses();
		if (g_iMeleeClassCount == 0) {
			return Plugin_Continue;
		}
	}

	int iClient = GetAnySurvivor();
	if (iClient == 0) {
		return Plugin_Continue;
	}

	float fPosition[3], fAngle[3];
	GetClientAbsOrigin(iClient, fPosition);
	fPosition[2] += 20.0;
	fAngle[0] = 90.0;

	if (g_cvRandom.BoolValue) {
		SpawnRandomList(fPosition, fAngle);
	} else {
		SpawnCustomList(fPosition, fAngle);
	}

	g_bSpawnedMelee = true;
	g_hSpawnTimer = null;
	return Plugin_Stop;
}

Action Command_SMMelee(int client, int args)
{
	if (g_iMeleeClassCount == 0) {
		GetMeleeClasses();
	}

	ReplyToCommand(client, "[MITSR] %d melee classes available:", g_iMeleeClassCount);
	for (int i = 0; i < g_iMeleeClassCount; i++) {
		ReplyToCommand(client, "%d : %s", i, g_sMeleeClass[i]);
	}

	return Plugin_Handled;
}

void SpawnRandomList(const float fPosition[3], const float fAngle[3])
{
	if (IsVersus() && InSecondHalfOfRound() && g_iSavedSpawnCount > 0) {
		for (int i = 0; i < g_iSavedSpawnCount; i++) {
			SpawnMelee(g_sMeleeClass[g_iSavedSpawns[i]], fPosition, fAngle);
		}
		return;
	}

	int iAmount = g_cvRandomAmount.IntValue;
	if (iAmount > MAX_RANDOM_SPAWNS) {
		iAmount = MAX_RANDOM_SPAWNS;
	}

	g_iSavedSpawnCount = 0;

	for (int i = 0; i < iAmount; i++) {
		int iPick = GetRandomInt(0, g_iMeleeClassCount - 1);
		SpawnMelee(g_sMeleeClass[iPick], fPosition, fAngle);
		g_iSavedSpawns[g_iSavedSpawnCount++] = iPick;
	}
}

void SpawnCustomList(const float fPosition[3], const float fAngle[3])
{
	char sScriptName[MELEE_CLASS_LENGTH];

	for (int i = 0; i < sizeof(g_sCustomMeleeClass); i++) {
		int iCount = g_cvCustomMeleeCount[i].IntValue;
		if (iCount < 1) {
			continue;
		}

		// Skip weapons the current campaign doesn't offer instead of
		// substituting an arbitrary entry from the string table.
		if (!GetScriptName(g_sCustomMeleeClass[i], sScriptName, sizeof(sScriptName))) {
			continue;
		}

		for (int j = 0; j < iCount; j++) {
			SpawnMelee(sScriptName, fPosition, fAngle);
		}
	}
}

void SpawnMelee(const char[] sScriptName, const float fBasePosition[3], const float fBaseAngle[3])
{
	float fPosition[3], fAngle[3];
	fPosition = fBasePosition;
	fAngle = fBaseAngle;

	fPosition[0] += GetRandomFloat(-10.0, 10.0);
	fPosition[1] += GetRandomFloat(-10.0, 10.0);
	fPosition[2] += GetRandomFloat(0.0, 10.0);
	fAngle[1] = GetRandomFloat(0.0, 360.0);

	int iMelee = CreateEntityByName("weapon_melee");
	if (iMelee == -1) {
		return;
	}

	DispatchKeyValue(iMelee, "melee_script_name", sScriptName);
	DispatchSpawn(iMelee);
	TeleportEntity(iMelee, fPosition, fAngle, NULL_VECTOR);
}

void GetMeleeClasses()
{
	g_iMeleeClassCount = 0;

	int iTable = FindStringTable("MeleeWeapons");
	if (iTable == INVALID_STRING_TABLE) {
		return;
	}

	int iCount = GetStringTableNumStrings(iTable);
	if (iCount > MAX_MELEE_CLASSES) {
		iCount = MAX_MELEE_CLASSES;
	}

	for (int i = 0; i < iCount; i++) {
		ReadStringTable(iTable, i, g_sMeleeClass[i], MELEE_CLASS_LENGTH);
	}

	g_iMeleeClassCount = iCount;
}

bool GetScriptName(const char[] sClass, char[] sScriptName, int iLength)
{
	for (int i = 0; i < g_iMeleeClassCount; i++) {
		if (StrContains(g_sMeleeClass[i], sClass, false) == 0) {
			strcopy(sScriptName, iLength, g_sMeleeClass[i]);
			return true;
		}
	}

	return false;
}

int GetAnySurvivor()
{
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsPlayerAlive(i)) {
			return i;
		}
	}

	return 0;
}

bool InSecondHalfOfRound()
{
	return view_as<bool>(GameRules_GetProp("m_bInSecondHalfOfRound"));
}

bool IsVersus()
{
	char sGameMode[32];
	g_cvGameMode.GetString(sGameMode, sizeof(sGameMode));

	return StrContains(sGameMode, "versus", false) != -1;
}
