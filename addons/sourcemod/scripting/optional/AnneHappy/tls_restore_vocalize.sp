#include <sourcemod>
#include <sdktools>
#include <sceneprocessor>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.2.1"

public Plugin myinfo = 
{
	name = "Restore Blocked Vocalize",
	author = "Forgetest",
	description = "Annoyments outside TLS are back.",
	version = PLUGIN_VERSION,
	url = "you"
};

#define NULL_VOCALIZE (view_as<Vocalize>(-1))
enum Vocalize
{
	Vocal_PlayerLaugh,
	Vocal_PlayerTaunt,
	Vocal_Playerdeath
};

static const char g_szVocalizeNames[Vocalize][] = 
{
	"PlayerLaugh", "PlayerTaunt", "Playerdeath"
};

#define SC_NONE (view_as<SurvivorCharacter>(-1))
enum SurvivorCharacter
{
	SC_NICK,
	SC_ROCHELLE,
	SC_COACH,
	SC_ELLIS,
	SC_BILL,
	SC_ZOEY,
	SC_LOUIS,
	SC_FRANCIS
};

#define SURVIVOR_CHARACTER_COUNT 8

// Models for each of the characters
static const char g_szSurvivorModels[SurvivorCharacter][] =
{
	"models/survivors/survivor_gambler.mdl",
	"models/survivors/survivor_producer.mdl",
	"models/survivors/survivor_coach.mdl",
	"models/survivors/survivor_mechanic.mdl",
	"models/survivors/survivor_namvet.mdl",
	"models/survivors/survivor_teenangst.mdl",
	"models/survivors/survivor_manager.mdl",
	"models/survivors/survivor_biker.mdl"
};

/**
 *  Voices
 */
#define MAX_NICK_LAUGH 17
#define MAX_NICK_TAUNT 9
#define MAX_NICK_SCREAM 7

#define MAX_ROCHELLE_LAUGH 17
#define MAX_ROCHELLE_TAUNT 8
#define MAX_ROCHELLE_SCREAM 2

#define MAX_COACH_LAUGH 23
#define MAX_COACH_TAUNT 8
#define MAX_COACH_SCREAM 2

#define MAX_ELLIS_LAUGH 19
#define MAX_ELLIS_TAUNT 8
#define MAX_ELLIS_SCREAM 6

#define MAX_BILL_LAUGH 14
#define MAX_BILL_TAUNT 5
#define MAX_BILL_SCREAM 8

#define MAX_ZOEY_LAUGH 21
#define MAX_ZOEY_TAUNT 16
#define MAX_ZOEY_SCREAM 11

#define MAX_LOUIS_LAUGH 19
#define MAX_LOUIS_TAUNT 8
#define MAX_LOUIS_SCREAM 6

#define MAX_FRANCIS_LAUGH 15
#define MAX_FRANCIS_TAUNT 10
#define MAX_FRANCIS_SCREAM 10

static const int g_iMaxVoices[Vocalize][SurvivorCharacter] = 
{
	{
		MAX_NICK_LAUGH, MAX_ROCHELLE_LAUGH, MAX_COACH_LAUGH, MAX_ELLIS_LAUGH,
		MAX_BILL_LAUGH, MAX_ZOEY_LAUGH, MAX_LOUIS_LAUGH, MAX_FRANCIS_LAUGH
	},
	
	{
		MAX_NICK_TAUNT, MAX_ROCHELLE_TAUNT, MAX_COACH_TAUNT, MAX_ELLIS_TAUNT,
		MAX_BILL_TAUNT, MAX_ZOEY_TAUNT, MAX_LOUIS_TAUNT, MAX_FRANCIS_TAUNT
	},
	
	{
		MAX_NICK_SCREAM, MAX_ROCHELLE_SCREAM, MAX_COACH_SCREAM, MAX_ELLIS_SCREAM,
		MAX_BILL_SCREAM, MAX_ZOEY_SCREAM, MAX_LOUIS_SCREAM, MAX_FRANCIS_SCREAM
	}
};

static const char g_szNickLaughs[][] =
{
	"scenes/gambler/laughter01.vcd",
	"scenes/gambler/laughter02.vcd",
	"scenes/gambler/laughter03.vcd",
	"scenes/gambler/laughter04.vcd",
	"scenes/gambler/laughter05.vcd",
	"scenes/gambler/laughter06.vcd",
	"scenes/gambler/laughter07.vcd",
	"scenes/gambler/laughter08.vcd",
	"scenes/gambler/laughter09.vcd",
	"scenes/gambler/laughter10.vcd",
	"scenes/gambler/laughter11.vcd",
	"scenes/gambler/laughter12.vcd",
	"scenes/gambler/laughter13.vcd",
	"scenes/gambler/laughter14.vcd",
	"scenes/gambler/laughter15.vcd",
	"scenes/gambler/laughter16.vcd",
	"scenes/gambler/laughter17.vcd"
};

static const char g_szNickTaunts[][] =
{
	"scenes/gambler/taunt01.vcd",
	"scenes/gambler/taunt02.vcd",
	"scenes/gambler/taunt03.vcd",
	"scenes/gambler/taunt04.vcd",
	"scenes/gambler/taunt05.vcd",
	"scenes/gambler/taunt06.vcd",
	"scenes/gambler/taunt07.vcd",
	"scenes/gambler/taunt08.vcd",
	"scenes/gambler/taunt09.vcd"
};

static const char g_szNickScreams[][] =
{
	"scenes/gambler/deathscream01.vcd",
	"scenes/gambler/deathscream02.vcd",
	"scenes/gambler/deathscream03.vcd",
	"scenes/gambler/deathscream04.vcd",
	"scenes/gambler/deathscream05.vcd",
	"scenes/gambler/deathscream06.vcd",
	"scenes/gambler/deathscream07.vcd"
};


static const char g_szRochelleLaughs[][] =
{
	"scenes/producer/laughter01.vcd",
	"scenes/producer/laughter02.vcd",
	"scenes/producer/laughter03.vcd",
	"scenes/producer/laughter04.vcd",
	"scenes/producer/laughter05.vcd",
	"scenes/producer/laughter06.vcd",
	"scenes/producer/laughter07.vcd",
	"scenes/producer/laughter08.vcd",
	"scenes/producer/laughter09.vcd",
	"scenes/producer/laughter10.vcd",
	"scenes/producer/laughter11.vcd",
	"scenes/producer/laughter12.vcd",
	"scenes/producer/laughter13.vcd",
	"scenes/producer/laughter14.vcd",
	"scenes/producer/laughter15.vcd",
	"scenes/producer/laughter16.vcd",
	"scenes/producer/laughter17.vcd"
};

static const char g_szRochelleTaunts[][] =
{
	"scenes/producer/taunt01.vcd",
	"scenes/producer/taunt02.vcd",
	"scenes/producer/taunt03.vcd",
	"scenes/producer/taunt04.vcd",
	"scenes/producer/taunt05.vcd",
	"scenes/producer/taunt06.vcd",
	"scenes/producer/taunt07.vcd",
	"scenes/producer/taunt08.vcd"
};

static const char g_szRochelleScreams[][] =
{
	"scenes/producer/deathscream01.vcd",
	"scenes/producer/deathscream02.vcd"
};


static const char g_szCoachLaughs[][] =
{
	"scenes/coach/laughter01.vcd",
	"scenes/coach/laughter02.vcd",
	"scenes/coach/laughter03.vcd",
	"scenes/coach/laughter04.vcd",
	"scenes/coach/laughter05.vcd",
	"scenes/coach/laughter06.vcd",
	"scenes/coach/laughter07.vcd",
	"scenes/coach/laughter08.vcd",
	"scenes/coach/laughter09.vcd",
	"scenes/coach/laughter10.vcd",
	"scenes/coach/laughter11.vcd",
	"scenes/coach/laughter12.vcd",
	"scenes/coach/laughter13.vcd",
	"scenes/coach/laughter14.vcd",
	"scenes/coach/laughter15.vcd",
	"scenes/coach/laughter16.vcd",
	"scenes/coach/laughter17.vcd",
	"scenes/coach/laughter18.vcd",
	"scenes/coach/laughter19.vcd",
	"scenes/coach/laughter20.vcd",
	"scenes/coach/laughter21.vcd",
	"scenes/coach/laughter22.vcd",
	"scenes/coach/laughter23.vcd"
};

static const char g_szCoachTaunts[][] =
{
	"scenes/coach/taunt01.vcd",
	"scenes/coach/taunt02.vcd",
	"scenes/coach/taunt03.vcd",
	"scenes/coach/taunt04.vcd",
	"scenes/coach/taunt05.vcd",
	"scenes/coach/taunt06.vcd",
	"scenes/coach/taunt07.vcd",
	"scenes/coach/taunt08.vcd"
};

static const char g_szCoachScreams[][] =
{
	"scenes/coach/deathscream01.vcd",
	"scenes/coach/deathscream02.vcd",
	"scenes/coach/deathscream03.vcd",
	"scenes/coach/deathscream04.vcd",
	"scenes/coach/deathscream05.vcd",
	"scenes/coach/deathscream06.vcd",
	"scenes/coach/deathscream07.vcd",
	"scenes/coach/deathscream08.vcd",
	"scenes/coach/deathscream09.vcd"
};


static const char g_szEllisLaughs[][] =
{
	"scenes/mechanic/laughter01.vcd",
	"scenes/mechanic/laughter02.vcd",
	"scenes/mechanic/laughter03.vcd",
	"scenes/mechanic/laughter04.vcd",
	"scenes/mechanic/laughter05.vcd",
	"scenes/mechanic/laughter06.vcd",
	"scenes/mechanic/laughter07.vcd",
	"scenes/mechanic/laughter08.vcd",
	"scenes/mechanic/laughter09.vcd",
	"scenes/mechanic/laughter10.vcd",
	"scenes/mechanic/laughter11.vcd",
	"scenes/mechanic/laughter12.vcd",
	"scenes/mechanic/laughter13.vcd",
	"scenes/mechanic/laughter13a.vcd",
	"scenes/mechanic/laughter13b.vcd",
	"scenes/mechanic/laughter13c.vcd",
	"scenes/mechanic/laughter13d.vcd",
	"scenes/mechanic/laughter13e.vcd",
	"scenes/mechanic/laughter14.vcd",
};

static const char g_szEllisTaunts[][] =
{
	"scenes/mechanic/taunt01.vcd",
	"scenes/mechanic/taunt02.vcd",
	"scenes/mechanic/taunt03.vcd",
	"scenes/mechanic/taunt04.vcd",
	"scenes/mechanic/taunt05.vcd",
	"scenes/mechanic/taunt06.vcd",
	"scenes/mechanic/taunt07.vcd",
	"scenes/mechanic/taunt08.vcd"
};

static const char g_szEllisScreams[][] =
{
	"scenes/mechanic/deathscream01.vcd",
	"scenes/mechanic/deathscream02.vcd",
	"scenes/mechanic/deathscream03.vcd",
	"scenes/mechanic/deathscream04.vcd",
	"scenes/mechanic/deathscream05.vcd",
	"scenes/mechanic/deathscream06.vcd"
};


static const char g_szBillLaughs[][] =
{
	"scenes/namvet/laughter01.vcd",
	"scenes/namvet/laughter02.vcd",
	"scenes/namvet/laughter03.vcd",
	"scenes/namvet/laughter04.vcd",
	"scenes/namvet/laughter05.vcd",
	"scenes/namvet/laughter06.vcd",
	"scenes/namvet/laughter07.vcd",
	"scenes/namvet/laughter08.vcd",
	"scenes/namvet/laughter09.vcd",
	"scenes/namvet/laughter10.vcd",
	"scenes/namvet/laughter11.vcd",
	"scenes/namvet/laughter12.vcd",
	"scenes/namvet/laughter13.vcd",
	"scenes/namvet/laughter14.vcd"
};

static const char g_szBillTaunts[][] =
{
	"scenes/namvet/taunt01.vcd",
	"scenes/namvet/taunt02.vcd",
	"scenes/namvet/taunt07.vcd",
	"scenes/namvet/taunt08.vcd",
	"scenes/namvet/taunt09.vcd"
};

static const char g_szBillScreams[][] =
{
	"scenes/namvet/deathscream01.vcd",
	"scenes/namvet/deathscream02.vcd",
	"scenes/namvet/deathscream03.vcd",
	"scenes/namvet/deathscream04.vcd",
	"scenes/namvet/deathscream05.vcd",
	"scenes/namvet/deathscream06.vcd",
	"scenes/namvet/deathscream07.vcd",
	"scenes/namvet/deathscream08.vcd"
};


static const char g_szZoeyLaughs[][] =
{
	"scenes/teengirl/laughter01.vcd",
	"scenes/teengirl/laughter02.vcd",
	"scenes/teengirl/laughter03.vcd",
	"scenes/teengirl/laughter04.vcd",
	"scenes/teengirl/laughter05.vcd",
	"scenes/teengirl/laughter06.vcd",
	"scenes/teengirl/laughter07.vcd",
	"scenes/teengirl/laughter08.vcd",
	"scenes/teengirl/laughter09.vcd",
	"scenes/teengirl/laughter10.vcd",
	"scenes/teengirl/laughter11.vcd",
	"scenes/teengirl/laughter12.vcd",
	"scenes/teengirl/laughter13.vcd",
	"scenes/teengirl/laughter14.vcd",
	"scenes/teengirl/laughter15.vcd",
	"scenes/teengirl/laughter16.vcd",
	"scenes/teengirl/laughter17.vcd",
	"scenes/teengirl/laughter18.vcd",
	"scenes/teengirl/laughter19.vcd",
	"scenes/teengirl/laughter20.vcd",
	"scenes/teengirl/laughter21.vcd"
};

static const char g_szZoeyTaunts[][] =
{
	"scenes/teengirl/taunt02.vcd",
	"scenes/teengirl/taunt13.vcd",
	"scenes/teengirl/taunt18.vcd",
	"scenes/teengirl/taunt19.vcd",
	"scenes/teengirl/taunt20.vcd",
	"scenes/teengirl/taunt21.vcd",
	"scenes/teengirl/taunt24.vcd",
	"scenes/teengirl/taunt25.vcd",
	"scenes/teengirl/taunt26.vcd",
	"scenes/teengirl/taunt28.vcd",
	"scenes/teengirl/taunt29.vcd",
	"scenes/teengirl/taunt30.vcd",
	"scenes/teengirl/taunt31.vcd",
	"scenes/teengirl/taunt34.vcd",
	"scenes/teengirl/taunt35.vcd",
	"scenes/teengirl/taunt39.vcd"
};

static const char g_szZoeyScreams[][] =
{
	"scenes/teengirl/deathscream01.vcd",
	"scenes/teengirl/deathscream02.vcd",
	"scenes/teengirl/deathscream03.vcd",
	"scenes/teengirl/deathscream04.vcd",
	"scenes/teengirl/deathscream05.vcd",
	"scenes/teengirl/deathscream06.vcd",
	"scenes/teengirl/deathscream07.vcd",
	"scenes/teengirl/deathscream08.vcd",
	"scenes/teengirl/deathscream09.vcd",
	"scenes/teengirl/deathscream10.vcd",
	"scenes/teengirl/deathscream11.vcd"
};


static const char g_szLouisLaughs[][] =
{
	"scenes/manager/laughter01.vcd",
	"scenes/manager/laughter02.vcd",
	"scenes/manager/laughter03.vcd",
	"scenes/manager/laughter04.vcd",
	"scenes/manager/laughter05.vcd",
	"scenes/manager/laughter06.vcd",
	"scenes/manager/laughter07.vcd",
	"scenes/manager/laughter08.vcd",
	"scenes/manager/laughter09.vcd",
	"scenes/manager/laughter10.vcd",
	"scenes/manager/laughter11.vcd",
	"scenes/manager/laughter12.vcd",
	"scenes/manager/laughter13.vcd",
	"scenes/manager/laughter14.vcd",
	"scenes/manager/laughter15.vcd",
	"scenes/manager/laughter16.vcd",
	"scenes/manager/laughter17.vcd",
	"scenes/manager/laughter18.vcd",
	"scenes/manager/laughter19.vcd",
	"scenes/manager/laughter20.vcd",
	"scenes/manager/laughter21.vcd"
};

static const char g_szLouisTaunts[][] =
{
	"scenes/manager/taunt01.vcd",
	"scenes/manager/taunt02.vcd",
	"scenes/manager/taunt03.vcd",
	"scenes/manager/taunt04.vcd",
	"scenes/manager/taunt05.vcd",
	"scenes/manager/taunt06.vcd",
	"scenes/manager/taunt07.vcd",
	"scenes/manager/taunt08.vcd",
	"scenes/manager/taunt09.vcd",
	"scenes/manager/taunt10.vcd"
};

static const char g_szLouisScreams[][] =
{
	"scenes/manager/deathscream01.vcd",
	"scenes/manager/deathscream02.vcd",
	"scenes/manager/deathscream03.vcd",
	"scenes/manager/deathscream04.vcd",
	"scenes/manager/deathscream05.vcd",
	"scenes/manager/deathscream06.vcd",
	"scenes/manager/deathscream07.vcd",
	"scenes/manager/deathscream08.vcd",
	"scenes/manager/deathscream09.vcd",
	"scenes/manager/deathscream10.vcd"
};


static const char g_szFrancisLaughs[][] =
{
	"scenes/biker/laughter01.vcd",
	"scenes/biker/laughter02.vcd",
	"scenes/biker/laughter03.vcd",
	"scenes/biker/laughter04.vcd",
	"scenes/biker/laughter05.vcd",
	"scenes/biker/laughter06.vcd",
	"scenes/biker/laughter07.vcd",
	"scenes/biker/laughter08.vcd",
	"scenes/biker/laughter09.vcd",
	"scenes/biker/laughter10.vcd",
	"scenes/biker/laughter11.vcd",
	"scenes/biker/laughter12.vcd",
	"scenes/biker/laughter13.vcd",
	"scenes/biker/laughter14.vcd",
	"scenes/biker/laughter15.vcd"
};

static const char g_szFrancisTaunts[][] =
{
	"scenes/biker/taunt01.vcd",
	"scenes/biker/taunt02.vcd",
	"scenes/biker/taunt03.vcd",
	"scenes/biker/taunt04.vcd",
	"scenes/biker/taunt05.vcd",
	"scenes/biker/taunt06.vcd",
	"scenes/biker/taunt07.vcd",
	"scenes/biker/taunt08.vcd",
	"scenes/biker/taunt09.vcd",
	"scenes/biker/taunt10.vcd"
};

static const char g_szFrancisScreams[][] =
{
	"scenes/biker/deathscream01.vcd",
	"scenes/biker/deathscream02.vcd",
	"scenes/biker/deathscream03.vcd",
	"scenes/biker/deathscream04.vcd",
	"scenes/biker/deathscream05.vcd",
	"scenes/biker/deathscream06.vcd",
	"scenes/biker/deathscream07.vcd",
	"scenes/biker/deathscream08.vcd",
	"scenes/biker/deathscream09.vcd",
	"scenes/biker/deathscream10.vcd"
};


StringMap g_hSurvMdlTrie;

public void OnPluginStart()
{
	InitSurvivorModelTrie();
}

public void OnMapStart()
{
	int i;
	for (i = 0; i < MAX_NICK_LAUGH; ++i) {
		PrecacheGeneric(g_szNickLaughs[i], true);
	}
	for (i = 0; i < MAX_NICK_TAUNT; ++i) {
		PrecacheGeneric(g_szNickTaunts[i], true);
	}
	for (i = 0; i < MAX_NICK_SCREAM; ++i) {
		PrecacheGeneric(g_szNickScreams[i], true);
	}
	for (i = 0; i < MAX_ROCHELLE_LAUGH; ++i) {
		PrecacheGeneric(g_szRochelleLaughs[i], true);
	}
	for (i = 0; i < MAX_ROCHELLE_TAUNT; ++i) {
		PrecacheGeneric(g_szRochelleTaunts[i], true);
	}
	for (i = 0; i < MAX_ROCHELLE_SCREAM; ++i) {
		PrecacheGeneric(g_szRochelleScreams[i], true);
	}
	for (i = 0; i < MAX_COACH_LAUGH; ++i) {
		PrecacheGeneric(g_szCoachLaughs[i], true);
	}
	for (i = 0; i < MAX_COACH_TAUNT; ++i) {
		PrecacheGeneric(g_szCoachTaunts[i], true);
	}
	for (i = 0; i < MAX_COACH_SCREAM; ++i) {
		PrecacheGeneric(g_szCoachScreams[i], true);
	}
	for (i = 0; i < MAX_ELLIS_LAUGH; ++i) {
		PrecacheGeneric(g_szEllisLaughs[i], true);
	}
	for (i = 0; i < MAX_ELLIS_TAUNT; ++i) {
		PrecacheGeneric(g_szEllisTaunts[i], true);
	}
	for (i = 0; i < MAX_ELLIS_SCREAM; ++i) {
		PrecacheGeneric(g_szEllisScreams[i], true);
	}
	for (i = 0; i < MAX_BILL_LAUGH; ++i) {
		PrecacheGeneric(g_szBillLaughs[i], true);
	}
	for (i = 0; i < MAX_BILL_TAUNT; ++i) {
		PrecacheGeneric(g_szBillTaunts[i], true);
	}
	for (i = 0; i < MAX_BILL_SCREAM; ++i) {
		PrecacheGeneric(g_szBillScreams[i], true);
	}
	for (i = 0; i < MAX_ZOEY_LAUGH; ++i) {
		PrecacheGeneric(g_szZoeyLaughs[i], true);
	}
	for (i = 0; i < MAX_ZOEY_TAUNT; ++i) {
		PrecacheGeneric(g_szZoeyTaunts[i], true);
	}
	for (i = 0; i < MAX_ZOEY_SCREAM; ++i) {
		PrecacheGeneric(g_szZoeyScreams[i], true);
	}
	for (i = 0; i < MAX_LOUIS_LAUGH; ++i) {
		PrecacheGeneric(g_szLouisLaughs[i], true);
	}
	for (i = 0; i < MAX_LOUIS_TAUNT; ++i) {
		PrecacheGeneric(g_szLouisTaunts[i], true);
	}
	for (i = 0; i < MAX_LOUIS_SCREAM; ++i) {
		PrecacheGeneric(g_szLouisScreams[i], true);
	}
	for (i = 0; i < MAX_FRANCIS_LAUGH; ++i) {
		PrecacheGeneric(g_szFrancisLaughs[i], true);
	}
	for (i = 0; i < MAX_FRANCIS_TAUNT; ++i) {
		PrecacheGeneric(g_szFrancisTaunts[i], true);
	}
	for (i = 0; i < MAX_FRANCIS_SCREAM; ++i) {
		PrecacheGeneric(g_szFrancisScreams[i], true);
	}
}
public Action OnVocalizeCommand(int client, const char[] vocalize, int initiator)
{
	if (!IsSurvivor(client) || !IsPlayerAlive(client)) return;
	
	if (IsActorBusy(client)) return;
	
	Vocalize emVocalize = IdentifyVocalize(vocalize);
	if (emVocalize == NULL_VOCALIZE) return;
	
	SurvivorCharacter emCharacter = IdentifySurvivor(client);
	if (emCharacter == SC_NONE) return;

	DataPack dp = new DataPack();
	dp.WriteCell(client);
	dp.WriteCell(emVocalize);
	dp.WriteCell(emCharacter);
	RequestFrame(Delay_Vocalize, dp);
}

public void Delay_Vocalize(DataPack dp)
{
	dp.Reset();
	
	int client = dp.ReadCell();
	Vocalize emVocalize = dp.ReadCell();
	SurvivorCharacter emCharacter = dp.ReadCell();
	
	char szVoiceFile[PLATFORM_MAX_PATH];
	PickVoice(szVoiceFile, sizeof(szVoiceFile), emVocalize, emCharacter);
	if (FileExists(szVoiceFile, true))
	{
		PerformScene(client, g_szVocalizeNames[emVocalize], szVoiceFile);
	}
	else
	{
		LogError("[VocalRestore] Unable to open scene file (%s)", szVoiceFile);
	}
	
	delete dp;
}

void PickVoice(char[] szFile, int maxlength, Vocalize emVocalize, SurvivorCharacter emCharacter)
{
	int max = g_iMaxVoices[emVocalize][emCharacter];
	int rndPick = Math_GetRandomInt(0, max-1);
	
	switch (emVocalize)
	{
		case Vocal_PlayerLaugh:
		{
			switch (emCharacter)
			{
				case SC_NICK:		strcopy(szFile, maxlength, g_szNickLaughs[rndPick]);
				case SC_ROCHELLE:	strcopy(szFile, maxlength, g_szRochelleLaughs[rndPick]);
				case SC_COACH:		strcopy(szFile, maxlength, g_szCoachLaughs[rndPick]);
				case SC_ELLIS:		strcopy(szFile, maxlength, g_szEllisLaughs[rndPick]);
				case SC_BILL:		strcopy(szFile, maxlength, g_szBillLaughs[rndPick]);
				case SC_ZOEY:		strcopy(szFile, maxlength, g_szZoeyLaughs[rndPick]);
				case SC_LOUIS:		strcopy(szFile, maxlength, g_szLouisLaughs[rndPick]);
				case SC_FRANCIS:	strcopy(szFile, maxlength, g_szFrancisLaughs[rndPick]);
			}
		}
		case Vocal_PlayerTaunt:
		{
			switch (emCharacter)
			{
				case SC_NICK:		strcopy(szFile, maxlength, g_szNickTaunts[rndPick]);
				case SC_ROCHELLE:	strcopy(szFile, maxlength, g_szRochelleTaunts[rndPick]);
				case SC_COACH:		strcopy(szFile, maxlength, g_szCoachTaunts[rndPick]);
				case SC_ELLIS:		strcopy(szFile, maxlength, g_szEllisTaunts[rndPick]);
				case SC_BILL:		strcopy(szFile, maxlength, g_szBillTaunts[rndPick]);
				case SC_ZOEY:		strcopy(szFile, maxlength, g_szZoeyTaunts[rndPick]);
				case SC_LOUIS:		strcopy(szFile, maxlength, g_szLouisTaunts[rndPick]);
				case SC_FRANCIS:	strcopy(szFile, maxlength, g_szFrancisTaunts[rndPick]);
			}
		}
		case Vocal_Playerdeath:
		{
			switch (emCharacter)
			{
				case SC_NICK:		strcopy(szFile, maxlength, g_szNickScreams[rndPick]);
				case SC_ROCHELLE:	strcopy(szFile, maxlength, g_szRochelleScreams[rndPick]);
				case SC_COACH:		strcopy(szFile, maxlength, g_szCoachScreams[rndPick]);
				case SC_ELLIS:		strcopy(szFile, maxlength, g_szEllisScreams[rndPick]);
				case SC_BILL:		strcopy(szFile, maxlength, g_szBillScreams[rndPick]);
				case SC_ZOEY:		strcopy(szFile, maxlength, g_szZoeyScreams[rndPick]);
				case SC_LOUIS:		strcopy(szFile, maxlength, g_szLouisScreams[rndPick]);
				case SC_FRANCIS:	strcopy(szFile, maxlength, g_szFrancisScreams[rndPick]);
			}
		}
	}
}

Vocalize IdentifyVocalize(const char[] szVocalize)
{
	if (strcmp(szVocalize, g_szVocalizeNames[Vocal_PlayerLaugh]) == 0) {
		return Vocal_PlayerLaugh;
	} else if (strcmp(szVocalize, g_szVocalizeNames[Vocal_PlayerTaunt]) == 0) {
		return Vocal_PlayerTaunt;
	} else if (strcmp(szVocalize, g_szVocalizeNames[Vocal_Playerdeath]) == 0) {
		return Vocal_Playerdeath;
	}
	return NULL_VOCALIZE;
}

/**
 * Initializes internal structure necessary for IdentifySurvivor() function
 * @remark It is recommended that you run this function on plugin start, but not necessary
 *
 * @noreturn
 */
stock void InitSurvivorModelTrie()
{
    g_hSurvMdlTrie = new StringMap();
    for(int i = 0; i < SURVIVOR_CHARACTER_COUNT; i++)
    {
        g_hSurvMdlTrie.SetValue(g_szSurvivorModels[view_as<SurvivorCharacter>(i)], i);
    }
}

/**
 * Identifies a client's survivor character based on their current model.
 * @remark SC_NONE on errors
 *
 * @param client                Survivor client to identify
 * @return SurvivorCharacter    index identifying the survivor, or SC_NONE if not identified.
 */
stock SurvivorCharacter IdentifySurvivor(int client)
{
    if (!client || !IsClientInGame(client) || !IsSurvivor(client))
    {
        return SC_NONE;
    }
    static char clientModel[42];
    GetClientModel(client, clientModel, sizeof(clientModel));
    return ClientModelToSC(clientModel);
}

/**
 * Identifies the survivor character corresponding to a player model.
 * @remark SC_NONE on errors, uses SurvivorModelTrie
 *
 * @param model                 Player model to identify
 * @return SurvivorCharacter    index identifying the model, or SC_NONE if not identified.
 */
stock SurvivorCharacter ClientModelToSC(const char[] model)
{
    if (g_hSurvMdlTrie == null)
    {
        InitSurvivorModelTrie();
    }
    SurvivorCharacter sc;
    if (GetTrieValue(g_hSurvMdlTrie, model, sc))
    {
        return sc;
    }
    return SC_NONE;
}

/**
 * Returns a random, uniform Integer number in the specified (inclusive) range.
 * This is safe to use multiple times in a function.
 * The seed is set automatically for each plugin.
 * Rewritten by MatthiasVance, thanks.
 *
 * @param min			Min value used as lower border
 * @param max			Max value used as upper border
 * @return				Random Integer number between min and max
 */
#define SIZE_OF_INT         2147483647 // without 0
stock int Math_GetRandomInt(int min, int max)
{
    int random = GetURandomInt();

    if (random == 0) {
        random++;
    }

    return RoundToCeil(float(random) / (float(SIZE_OF_INT) / float(max - min + 1))) + min - 1;
}

/**
 * Returns true if the player is currently on the survivor team. 
 *
 * @param client client ID
 * @return bool
 */
stock bool IsSurvivor(int client)
{
	return GetClientTeam(client) == 2;
}
