#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>
#include <sdkhooks>
#include <actions>
#include <l4d2util>

#define PLUGIN_VERSION "3.0"

public Plugin myinfo =
{
	name = "[L4D2] Uncommon Adjustment",
	author = "Forgetest",
	description = "Custom adjustments to uncommon infected.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
};

methodmap GameDataWrapper < GameData {
	public GameDataWrapper(const char[] file) {
		GameData gd = new GameData(file);
		if (!gd) SetFailState("Missing gamedata \"%s\"", file);
		return view_as<GameDataWrapper>(gd);
	}
	public DynamicDetour CreateDetourOrFail(
			const char[] name,
			DHookCallback preHook = INVALID_FUNCTION,
			DHookCallback postHook = INVALID_FUNCTION) {
		DynamicDetour hSetup = DynamicDetour.FromConf(this, name);
		if (!hSetup)
			SetFailState("Missing detour setup \"%s\"", name);
		if (preHook != INVALID_FUNCTION && !hSetup.Enable(Hook_Pre, preHook))
			SetFailState("Failed to pre-detour \"%s\"", name);
		if (postHook != INVALID_FUNCTION && !hSetup.Enable(Hook_Post, postHook))
			SetFailState("Failed to post-detour \"%s\"", name);
		return hSetup;
	}
}

enum
{
	INFECTED_FLAG_RESERVED_WANDERER		= 0x1,
	INFECTED_FLAG_FIRE_IMMUNE			= 0x2,		// CEDA
	INFECTED_FLAG_CRAWL_RUN				= 0x4,		// mudman
	INFECTED_FLAG_UNDISTRACTABLE		= 0x8,		// workman
	INFECTED_FLAG_FALLEN_SURVIVOR		= 0x10,
	INFECTED_FLAG_RIOTCOP_ARMOR			= 0x20,
	INFECTED_FLAG_ALLOW_AMBUSH			= 0x40,		// Removed after first shoved
	INFECTED_FLAG_AMBIENT_MOB			= 0x80,

	INFECTED_FLAG_NO_ATTRACT			= 0x100,	// Do not create "info_goal_infected_chase"
	INFECTED_FLAG_WITCH_BLOCK_CLIMB		= 0x200,	// Block climbing when wandering around
	INFECTED_FLAG_FALLEN_FLEE			= 0x400,
	INFECTED_FLAG_HEADSHOT_ONLY			= 0x800,	// "cm_HeadshotOnly"

	INFECTED_FLAG_CANT_SEE_SURVIVORS	= 0x2000,
	INFECTED_FLAG_CANT_HEAR_SURVIVORS	= 0x4000,
	INFECTED_FLAG_CANT_FEEL_SURVIVORS	= 0x8000,
};

ConVar z_health;

int g_iUncommonAttract;
int g_iRoadworkerSense;
int g_iJimmySense;
float g_flHealthScale;
float g_flJimmyHealthScale;
int g_iFallenEquipments;
bool g_bRiotcopArmor;
bool g_bMudmanCrouch;
bool g_bMudmanSplatter;
bool g_bJimmySplatter;

int g_iOffs_m_nInfectedFlags;

public void OnPluginStart()
{
	GameDataWrapper gd = new GameDataWrapper("l4d2_uncommon_adjustment");
	delete gd.CreateDetourOrFail("InfectedAttack::OnPunch", DTR_OnPunch, DTR_OnPunch_Post);
	delete gd.CreateDetourOrFail("CTerrorPlayer::QueueScreenBloodSplatter", DTR_QueueScreenBloodSplatter);
	delete gd;

	z_health = FindConVar("z_health");
	
	CreateConVarHook("l4d2_uncommon_attract",
						"3",
						"Set whether clowns and Jimmy gibbs Jr. can attract zombies.\n"
					...	"0 = Neither, 1 = Clowns, 2 = Jimmy gibs Jr., 3 = Both",
						FCVAR_NONE,
						true, 0.0, true, 3.0,
						UncommonAttract_ConVarChanged);
	
	CreateConVarHook("l4d2_roadworker_sense_flag",
						"0",
						"Set whether road workers can hear and/or smell, so they will react to certain attractions.\n"
					...	"0 = Neither, 1 = Hear (pipe bombs, clowns), 2 = Smell (vomit jars), 3 = Both",
						FCVAR_NONE,
						true, 0.0, true, 3.0,
						RoadworkerSense_ConVarChanged);
	
	CreateConVarHook("l4d2_jimmy_sense_flag",
						"0",
						"Set whether Jimmy gibbs Jr. can hear and/or smell, so they will react to certain attractions.\n"
					...	"0 = Neither, 1 = Hear (pipe bombs, clowns), 2 = Smell (vomit jars), 3 = Both",
						FCVAR_NONE,
						true, 0.0, true, 3.0,
						JimmySense_ConVarChanged);
	
	CreateConVarHook("l4d2_uncommon_health_multiplier",
						"3.0",
						"How many the uncommon health is scaled by.\n"
					...	"Doesn't apply to Jimmy gibs Jr., fallen survivors and Riot Cops.",
						FCVAR_NONE,
						true, 0.0, false, 0.0,
						UncommonHealthScale_ConVarChanged);
	
	CreateConVarHook("l4d2_jimmy_health_multiplier",
						"20.0",
						"How many the health of Jimmy gibbs Jr. is scaled by.",
						FCVAR_NONE,
						true, 0.0, false, 0.0,
						JimmyHealthScale_ConVarChanged);
	
	CreateConVarHook("l4d2_fallen_equipments",
						"15",
						"Set what items a fallen survivor can equip.\n"
					...	"1 = Molotov, 2 = Pipebomb, 4 = Pills, 8 = Medkit, 15 = All, 0 = Nothing",
						FCVAR_NONE,
						true, 0.0, true, 15.0,
						FallenEquipments_ConVarChanged);
	
	CreateConVarHook("l4d2_riotcop_armor",
						"1",
						"Set whether riotcop has armor that prevents damages in front.",
						FCVAR_NONE,
						true, 0.0, true, 1.0,
						RiotcopArmor_ConVarChanged);
	
	CreateConVarHook("l4d2_mudman_crouch_run",
						"1",
						"Set whether mudman can crouch while running.",
						FCVAR_NONE,
						true, 0.0, true, 1.0,
						MudmanCrouch_ConVarChanged);
	
	CreateConVarHook("l4d2_mudman_screen_splatter",
						"1",
						"Set whether mudman can blind your screen.",
						FCVAR_NONE,
						true, 0.0, true, 1.0,
						MudmanSplatter_ConVarChanged);
	
	CreateConVarHook("l4d2_jimmy_screen_splatter",
						"1",
						"Set whether Jimmy gibbs Jr. can blind your screen.",
						FCVAR_NONE,
						true, 0.0, true, 1.0,
						JimmySplatter_ConVarChanged);
	
	g_iOffs_m_nInfectedFlags = FindSendPropInfo("Infected", "m_nFallenFlags") - 4;
}

void UncommonAttract_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iUncommonAttract = convar.IntValue;
}

void RoadworkerSense_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iRoadworkerSense = convar.IntValue;
}

void JimmySense_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iJimmySense = convar.IntValue;
}

void UncommonHealthScale_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flHealthScale = convar.FloatValue;
}

void JimmyHealthScale_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flJimmyHealthScale = convar.FloatValue;
}

void FallenEquipments_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iFallenEquipments = convar.IntValue;
}

void RiotcopArmor_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bRiotcopArmor = convar.BoolValue;
}

void MudmanCrouch_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bMudmanCrouch = convar.BoolValue;
}

void MudmanSplatter_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bMudmanSplatter = convar.BoolValue;
}

void JimmySplatter_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bJimmySplatter = convar.BoolValue;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (classname[0] == 'i')
	{
		if (strcmp(classname, "infected") == 0)
		{
			SDKHook(entity, SDKHook_SpawnPost, SDK_OnSpawn_Post);
		}
		else if (strcmp(classname, "info_goal_infected_chase") == 0)
		{
			SDKHook(entity, SDKHook_Think, SDK_OnThink_Once);
		}
	}
}

Action SDK_OnThink_Once(int entity)
{
	SDKUnhook(entity, SDKHook_Think, SDK_OnThink_Once);
	return __OnThink(entity);
}

Action __OnThink(int entity)
{
	int parent = GetEntPropEnt(entity, Prop_Data, "m_pParent");
	if (!IsValidEntity(parent))
		return Plugin_Continue;
	
	bool bDisableAttraction = false;
	switch (GetGender(parent))
	{
	case L4D2Gender_Clown:
		{
			bDisableAttraction = (g_iUncommonAttract & 1) == 0;
		}
	case L4D2Gender_Jimmy:
		{
			bDisableAttraction = (g_iUncommonAttract & 2) == 0;
		}
	}
	
	if (bDisableAttraction)
	{
		AcceptEntityInput(entity, "Disable");
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

void SDK_OnSpawn_Post(int entity)
{
	if (!IsValidEdict(entity))
		return;
	
	int gender = GetGender(entity);
	if (gender < L4D2Gender_Ceda || gender > L4D2Gender_Jimmy)
		return;
	
	switch (gender)
	{
	case L4D2Gender_Fallen:
		{
			int flags = GetEntProp(entity, Prop_Send, "m_nFallenFlags");
			SetEntProp(entity, Prop_Send, "m_nFallenFlags", flags & g_iFallenEquipments);
		}
	case L4D2Gender_Crawler:
		{
			if (!g_bMudmanCrouch)
				RemoveInfectedFlags(entity, INFECTED_FLAG_CRAWL_RUN);
		}
	case L4D2Gender_Riot_Control:
		{
			if (!g_bRiotcopArmor)
				RemoveInfectedFlags(entity, INFECTED_FLAG_RIOTCOP_ARMOR);
		}
	case L4D2Gender_Jimmy:
		{
			int iHealth = RoundToFloor(z_health.FloatValue * g_flJimmyHealthScale); // classic cast to int
			ResetEntityHealth(entity, iHealth);
		}
	default:
		{
			int iHealth = RoundToFloor(z_health.FloatValue * g_flHealthScale); // classic cast to int
			ResetEntityHealth(entity, iHealth);
		}
	}
}

public void OnActionCreated(BehaviorAction action, int owner, const char[] name)
{
	switch (name[0])
	{
	case 'I':
		{
			if (strncmp(name, "Infected", 8) != 0)
				return;
			
			if (strcmp(name[8], "Attack") != 0 && strcmp(name[8], "Alert") != 0 && strcmp(name[8], "Wander") != 0)
				return;
			
			if (~GetInfectedFlags(owner) & 8)
				return;
			
			action.OnSound = OnSound;
			action.OnSoundPost = OnSoundPost;
		}
	}
}

bool g_bShouldRestore = false;
Action OnSound(BehaviorAction action, int actor, int entity, const float pos[3], Address keyvalues, ActionDesiredResult result)
{
	int gender = GetGender(actor);
	
	bool bCanHear = false;
	bool bCanSmell = false;
	switch (gender)
	{
	case L4D2Gender_Undistractable: // road worker
		{
			bCanHear = (g_iRoadworkerSense & 1) != 0;
			bCanSmell = (g_iRoadworkerSense & 2) != 0;
		}
	case L4D2Gender_Jimmy:
		{
			bCanHear = (g_iJimmySense & 1) != 0;
			bCanSmell = (g_iJimmySense & 2) != 0;
		}
	}
	
	char cls[64];
	GetEdictClassname(entity, cls, sizeof(cls));
	
	if (strcmp(cls, "info_goal_infected_chase") == 0 && GetEntPropEnt(entity, Prop_Data, "m_pParent") == -1)
	{
		// Vomit jar attracts zombies the same way pipe bomb does.
		// But the attraction source won't move as pipe bomb's travelling,
		// so the parent isn't set and it tells what the attraction is.
		if (!bCanSmell)
			return Plugin_Continue;
	}
	else
	{
		// Any other actual **sounds**.
		if (!bCanHear)
			return Plugin_Continue;
	}
	
	RemoveInfectedFlags(actor, INFECTED_FLAG_UNDISTRACTABLE);
	g_bShouldRestore = true;
	
	return Plugin_Continue;
}

Action OnSoundPost(BehaviorAction action, int actor, int entity, const float pos[3], Address keyvalues, ActionDesiredResult result)
{
	if (g_bShouldRestore)
	{
		AddInfectedFlags(actor, INFECTED_FLAG_UNDISTRACTABLE);
		g_bShouldRestore = false;
	}
	
	return Plugin_Continue;
}

bool g_bBlockSplatter = false;
MRESReturn DTR_OnPunch(Address pThis, DHookParam hParams)
{
	int infected = hParams.Get(1);

	switch (GetGender(infected))
	{
	case L4D2Gender_Crawler:
		{
			if (g_bMudmanSplatter)
				return MRES_Ignored;
		}
	
	case L4D2Gender_Jimmy:
		{
			if (g_bJimmySplatter)
				return MRES_Ignored;
		}
	}

	g_bBlockSplatter = true;
	return MRES_Ignored;	
}

MRESReturn DTR_OnPunch_Post(Address pThis, DHookParam hParams)
{
	g_bBlockSplatter = false;
	return MRES_Ignored;
}

MRESReturn DTR_QueueScreenBloodSplatter(int client, DHookParam hParams)
{
	return g_bBlockSplatter ? MRES_Supercede : MRES_Ignored;
}

void AddInfectedFlags(int entity, int flags)
{
	SetInfectedFlags(entity, GetInfectedFlags(entity) | flags);
}

void RemoveInfectedFlags(int entity, int flags)
{
	SetInfectedFlags(entity, GetInfectedFlags(entity) & ~flags);
}

int GetInfectedFlags(int entity)
{
	return GetEntData(entity, g_iOffs_m_nInfectedFlags);
}

void SetInfectedFlags(int entity, int flags)
{
	SetEntData(entity, g_iOffs_m_nInfectedFlags, flags);
}

void ResetEntityHealth(int entity, int health)
{
	if (health < 1)
		health = 1;
	
	SetEntProp(entity, Prop_Data, "m_iMaxHealth", health);
	SetEntProp(entity, Prop_Data, "m_iHealth", health);
}

ConVar CreateConVarHook(const char[] name,
	const char[] defaultValue,
	const char[] description="",
	int flags=0,
	bool hasMin=false, float min=0.0,
	bool hasMax=false, float max=0.0,
	ConVarChanged callback)
{
	ConVar cv = CreateConVar(name, defaultValue, description, flags, hasMin, min, hasMax, max);
	
	Call_StartFunction(INVALID_HANDLE, callback);
	Call_PushCell(cv);
	Call_PushNullString();
	Call_PushNullString();
	Call_Finish();
	
	cv.AddChangeHook(callback);
	
	return cv;
}
