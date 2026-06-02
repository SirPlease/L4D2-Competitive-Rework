#pragma semicolon 1
#pragma newdecls required

#define VERSION	"0.2"

#include <sourcemod>
#include <sourcescramble> // https://github.com/nosoop/SMExt-SourceScramble

#define MAX_PATCH	4
#define ALWAYS		1
#define NEVER		2

MemoryPatch g_mPatchs[MAX_PATCH][3];
ConVar g_cvPatchs[MAX_PATCH];

static const char g_sPatchNames[MAX_PATCH][] =
{
	"convert_leap",
	"crouch_pounce",
	"bonus_damage",
	"pounce_interrupt",
};

public Plugin myinfo =
{
	name = "L4D2 hunter patch",
	author = "fdxx",
	description = "Patched some hunter function.",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=337071"
}

public void OnPluginStart()
{
	InitGameData();

	CreateConVar("l4d2_hunter_patch_version", VERSION, "Version", FCVAR_NOTIFY | FCVAR_DONTRECORD);

	g_cvPatchs[0] = CreateConVar("l4d2_hunter_patch_convert_leap", "0", "Whether convert leap to pounce.\n0=game default, 1=always, 2=never.", FCVAR_NONE);
	g_cvPatchs[1] = CreateConVar("l4d2_hunter_patch_crouch_pounce", "0", "While on the ground, Whether need press crouch button to pounce.\n0=game default, 1=always, 2=never.", FCVAR_NONE);
	g_cvPatchs[2] = CreateConVar("l4d2_hunter_patch_bonus_damage", "0", "Whether enable bonus pounce damage.\n0=game default, 1=always, 2=never.", FCVAR_NONE);
	g_cvPatchs[3] = CreateConVar("l4d2_hunter_patch_pounce_interrupt", "0", "Whether enable pounce interrupt.\n0=game default, 1=always, 2=never.", FCVAR_NONE);

	AutoExecConfig(true, "l4d2_hunter_patch");

	RegAdminCmd("sm_hunter_patch_print_cvars", Cmd_PrintCvars, ADMFLAG_ROOT);
	HookEvent("lunge_pounce", Event_LungePounce);
}

public void OnConfigsExecuted()
{
	static bool shit;
	if (shit) return;
	shit = true;

	SetPatch();

	for (int i = 0; i < MAX_PATCH; i++)
	{
		g_cvPatchs[i].AddChangeHook(OnConVarChanged);
	}
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	SetPatch();
}

void SetPatch()
{
	int iValue;

	for (int i = 0; i < MAX_PATCH; i++)
	{
		g_mPatchs[i][ALWAYS].Disable();
		g_mPatchs[i][NEVER].Disable();

		iValue = g_cvPatchs[i].IntValue;

		if (iValue == 1 || iValue == 2)
		{
			if (!g_mPatchs[i][iValue].Enable())
			{
				SetFailState("g_mPatchs[%i][%i] Enable failed.", i, iValue);
			}
		}
	}
}

Action Cmd_PrintCvars(int client, int args)
{
	ReplyToCommand(client, "l4d2_hunter_patch_convert_leap = %i", g_cvPatchs[0].IntValue);
	ReplyToCommand(client, "l4d2_hunter_patch_crouch_pounce = %i", g_cvPatchs[1].IntValue);
	ReplyToCommand(client, "l4d2_hunter_patch_bonus_damage = %i", g_cvPatchs[2].IntValue);
	ReplyToCommand(client, "l4d2_hunter_patch_pounce_interrupt = %i", g_cvPatchs[3].IntValue);

	return Plugin_Handled;
}

void InitGameData()
{
	GameData hGameData = new GameData("l4d2_hunter_patch");
	if (hGameData == null)
		SetFailState("Failed to load \"l4d2_hunter_patch.txt\" gamedata.");

	char sName[128];
	for (int i = 0; i < MAX_PATCH; i++)
	{
		FormatEx(sName, sizeof(sName), "%s_%s", g_sPatchNames[i], "always");
		g_mPatchs[i][ALWAYS] = MemoryPatch.CreateFromConf(hGameData, sName);
		if (!g_mPatchs[i][ALWAYS].Validate())
			SetFailState("Verify patch: %s failed.", sName);

		FormatEx(sName, sizeof(sName), "%s_%s", g_sPatchNames[i], "never");
		g_mPatchs[i][NEVER] = MemoryPatch.CreateFromConf(hGameData, sName);
		if (!g_mPatchs[i][NEVER].Validate())
			SetFailState("Verify patch: %s failed.", sName);
	}

	delete hGameData;
}

// Fixed crash in CTerrorPlayer::OnPouncedOnSurvivor function when the server is empty.
// HookEvent so that the function always returns a valid event pointer when CreateEvent.
// If there are other plugins already hooked 'lunge_pounce' event, it can also prevent crashes.
/*
IGameEvent *event = gameeventmanager->CreateEvent( "lunge_pounce" );
if ( event )
{
	...
}
if ( CTerrorGameRules::HasPlayerControlledZombies() )
{
	...
	event->SetInt("damage", dmg ); // NULL pointer crash
}
*/
void Event_LungePounce(Event event, const char[] name, bool dontBroadcast)
{
}
