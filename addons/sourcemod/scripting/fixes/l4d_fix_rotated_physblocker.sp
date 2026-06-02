#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

public Plugin myinfo = 
{
	name = "[L4D & 2] Entity VPhysics Solver",
	author = "Forgetest",
	description = "Fix rotated \"env_physics_blockers\" blocking Tank hittables.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins",
}

enum struct SDKCallParamsWrapper {
	SDKType type;
	SDKPassMethod pass;
	int decflags;
	int encflags;
}

methodmap GameDataWrapper < GameData {
	public GameDataWrapper(const char[] file) {
		GameData gd = new GameData(file);
		if (!gd) SetFailState("Missing gamedata \"%s\"", file);
		return view_as<GameDataWrapper>(gd);
	}
	public Handle CreateSDKCallOrFail(
			SDKCallType type,
			SDKFuncConfSource src,
			const char[] name,
			const SDKCallParamsWrapper[] params = {},
			int numParams = 0,
			bool hasReturnValue = false,
			const SDKCallParamsWrapper ret = {}) {
		static const char k_sSDKFuncConfSource[SDKFuncConfSource][] = { "offset", "signature", "address" };
		Handle result;
		StartPrepSDKCall(type);
		if (!PrepSDKCall_SetFromConf(this, src, name))
			SetFailState("Missing %s \"%s\"", k_sSDKFuncConfSource[src], name);
		for (int i = 0; i < numParams; ++i)
			PrepSDKCall_AddParameter(params[i].type, params[i].pass, params[i].decflags, params[i].encflags);
		if (hasReturnValue)
			PrepSDKCall_SetReturnInfo(ret.type, ret.pass, ret.decflags, ret.encflags);
		if (!(result = EndPrepSDKCall()))
			SetFailState("Failed to prep sdkcall \"%s\"", name);
		return result;
	}
}

Handle g_Call_PhysDisableEntityCollisions;
bool g_bPostProcess;

public void OnPluginStart()
{
	GameDataWrapper gd = new GameDataWrapper("l4d_fix_rotated_physblocker");

	SDKCallParamsWrapper params[] = {
		{SDKType_CBaseEntity, SDKPass_Pointer},
		{SDKType_CBaseEntity, SDKPass_Pointer},
	};
	g_Call_PhysDisableEntityCollisions = gd.CreateSDKCallOrFail(SDKCall_Static, SDKConf_Signature, "PhysDisableEntityCollisions", params, sizeof(params));

	delete gd;

	HookEvent("round_start_pre_entity", Event_round_start_pre_entity);
	HookEvent("round_start", Event_round_start);
}

public void OnMapStart() // late load
{
	if (!g_bPostProcess)
	{
		ProcessPhysicsBlockers();
		g_bPostProcess = true;
	}
}

void Event_round_start_pre_entity(Event event, const char[] name, bool dontBroadcast)
{
	g_bPostProcess = false;
}

void Event_round_start(Event event, const char[] name, bool dontBroadcast)
{
	ProcessPhysicsBlockers();
	g_bPostProcess = true;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!g_bPostProcess)
		return;
	
	if (classname[0] == 'e' && !strcmp(classname, "env_physics_blocker"))
	{
		RequestFrame(NextFrame_BlockerCreated, EntIndexToEntRef(entity));
	}
	else if (classname[0] == 'p' && (!strcmp(classname, "prop_physics") || !strcmp(classname, "prop_car_alarm")))
	{
		RequestFrame(NextFrame_HittableCreated, EntIndexToEntRef(entity));
	}
}

void NextFrame_BlockerCreated(int ref)
{
	if (!IsValidEdict(ref) || GetEntProp(ref, Prop_Data, "m_nBlockType") == 4 || GetEntityMoveType(ref) != MOVETYPE_VPHYSICS)
		return;
	
	int entity = EntRefToEntIndex(ref);

	ArrayList list = CollectTankHittables();
	DisableVPhysicsAgainstList(entity, list);
	delete list;
}

void NextFrame_HittableCreated(int ref)
{
	if (!IsValidEdict(ref))
		return;
	
	int entity = EntRefToEntIndex(ref);

	ArrayList list = CollectPhysBlockers();
	DisableVPhysicsAgainstList(entity, list);
	delete list;
}

void ProcessPhysicsBlockers()
{
	ArrayList blockers = CollectPhysBlockers();
	ArrayList physprops = CollectTankHittables();

	for (int i = blockers.Length-1; i >= 0; --i)
	{
		DisableVPhysicsAgainstList(blockers.Get(i), physprops);
	}

	PrintToServer("Found %d rotated blockers, %d tank hittables", blockers.Length, physprops.Length);

	delete blockers;
	delete physprops;
}

void DisableVPhysicsAgainstList(int entity, ArrayList list)
{
	for (int i = list.Length-1; i >= 0; --i)
	{
		PhysDisableEntityCollisions(entity, list.Get(i));
	}
}

ArrayList CollectPhysBlockers()
{
	ArrayList list = new ArrayList();

	int entity = MaxClients+1;
	while ((entity = FindEntityByClassname(entity, "env_physics_blocker")) != INVALID_ENT_REFERENCE)
	{
		if (GetEntProp(entity, Prop_Data, "m_nBlockType") != 4 && GetEntityMoveType(entity) == MOVETYPE_VPHYSICS)
		{
			list.Push(entity);
		}
	}

	return list;
}

ArrayList CollectTankHittables()
{
	ArrayList list = new ArrayList();

	int entity = MaxClients+1;
	while ((entity = FindEntityByClassname(entity, "prop_physics")) != INVALID_ENT_REFERENCE)
	{
		list.Push(entity);
	}

	entity = MaxClients+1;
	while ((entity = FindEntityByClassname(entity, "prop_car_alarm")) != INVALID_ENT_REFERENCE)
	{
		list.Push(entity);
	}

	return list;
}

void PhysDisableEntityCollisions(int ent1, int ent2)
{
	SDKCall(g_Call_PhysDisableEntityCollisions, ent1, ent2);
}