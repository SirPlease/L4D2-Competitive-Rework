#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>

#define PLUGIN_VERSION "1.3"

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
	
	DynamicDetour hDetour = DynamicDetour.FromConf(conf, "CBaseEntity::SetGroundEntity");
	AssertFail(hDetour != null && hDetour.Enable(Hook_Pre, DTR_OnSetGroundEntity),
			"Failed to detour \""..."CBaseEntity::SetGroundEntity"..."\"");
	
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
MRESReturn DTR_OnSetGroundEntity(int entity, DHookParam hParams)
{
	if (!g_iFlags)
		return MRES_Ignored;
	
	if (entity <= 0 || entity > MaxClients || !IsClientInGame(entity))
		return MRES_Ignored;
	
	int team = GetClientTeam(entity);
	if ((team - 1) & ~g_iFlags)
		return MRES_Ignored;
	
	int ground = -1;
	if (!hParams.IsNull(1))
		ground = hParams.Get(1);
	
	if (ground <= 0 || ground > MaxClients)
		return MRES_Ignored;
	
	// if (GetClientTeam(ground) == team) // do we need this?
	//	return MRES_Ignored;
	
	if (IsPouncing(GetEntPropEnt(entity, Prop_Send, "m_customAbility")))
		return MRES_Ignored;
	
	SetEntPropEnt(entity, Prop_Send, "m_hGroundEntity", 0);
	return MRES_Supercede;
}

bool IsPouncing(int ability)
{
	if (!IsValidEdict(ability))
		return false;
	
	static char cls[64];
	if (!GetEdictClassname(ability, cls, sizeof(cls)))
		return false;
	
	if (cls[8] != 'l') // match "leap" "lunge"
		return false;
	
	if (cls[9] == 'e')
		return GetEntPropFloat(ability, Prop_Send, "m_nextActivationTimer", 1) <= GetGameTime();
	
	if (cls[9] == 'u')
		return !!GetEntProp(ability, Prop_Send, "m_isLunging", 1);
	
	return false;
}