#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>

#define PLUGIN_VERSION "1.0"

public Plugin myinfo = 
{
	name = "[L4D2] Steady Boost",
	author = "Forgetest",
	description = "Prevent forced sliding when landing at head of enemies.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
};

#define GAMEDATA_FILE "l4d2_steady_boost"

int g_iFlags;

void AssertFail(bool test, const char[] error)
{
	if (!test) SetFailState("%s", error);
}

public void OnPluginStart()
{
	GameData conf = new GameData(GAMEDATA_FILE);
	AssertFail(conf != null, "Missing gamedata \""...GAMEDATA_FILE..."\"");
	
	DynamicDetour hDetour = DynamicDetour.FromConf(conf, "CTerrorGameMovement::CheckStacking");
	AssertFail(hDetour != null && hDetour.Enable(Hook_Pre, DTR_OnCheckStacking),
			"Failed to detour \""..."CTerrorGameMovement::CheckStacking"..."\"");
	
	delete hDetour;
	delete conf;
	
	ConVar cv = CreateConVar("l4d2_steady_boost_flags",
								"3",
								"Set which teams can perform steady boost.\n"\
							...	"1 = Survivors, 2 = Infected, 3 = All, 0 = Disabled",
								FCVAR_SPONLY,
								true, 0.0, true, 3.0);
	OnConVarChanged(cv, "", "");
	cv.AddChangeHook(OnConVarChanged);
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iFlags = convar.IntValue;
}

// TODO: Client prediction fix
MRESReturn DTR_OnCheckStacking(DHookParam hParams)
{
	if (!g_iFlags)
		return MRES_Ignored;
	
	int client = hParams.GetObjectVar(1, 2064, ObjectValueType_CBaseEntityPtr);
	if (client == -1 || !IsClientInGame(client))
		return MRES_Ignored;
	
	int team = GetClientTeam(client);
	if ((team - 1) & ~g_iFlags)
		return MRES_Ignored;
	
	int ground = GetEntPropEnt(client, Prop_Send, "m_hGroundEntity");
	if (ground <= 0 || ground > MaxClients)
		return MRES_Ignored;
	
	if (GetClientTeam(ground) == team) // do we need this?
		return MRES_Ignored;
	
	return MRES_Supercede;
}
