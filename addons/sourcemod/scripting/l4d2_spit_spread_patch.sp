#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <left4dhooks>
#include <dhooks>
#include <sourcescramble>
#include <collisionhook>

#define PLUGIN_VERSION "1.5"

public Plugin myinfo = 
{
	name = "[L4D2] Spit Spread Patch",
	author = "Forgetest",
	description = "Fix various spit spread issues.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
};

#define GAMEDATA_FILE "l4d2_spit_spread_patch"
#define KEY_DETONATE "CSpitterProjectile::Detonate"
#define KEY_EVENT_KILLED "CTerrorPlayer::Event_Killed"
#define KEY_DETONATE_FLAG_PATCH "CSpitterProjectile::Detonate__TraceFlag_patch"
#define KEY_SPREAD_FLAG_PATCH "CInferno::Spread__TraceFlag_patch"
#define KEY_SPREAD_PASS_PATCH "CInferno::Spread__PassEnt_patch"
#define KEY_TRACEHEIGHT_PATCH "CTerrorPlayer::Event_Killed__TraceHeight_patch"
#define KEY_SPAWNATTRIBUTES "TerrorNavArea::m_spawnAttributes"

MemoryBlock g_hAlloc_TraceHeight;

ConVar g_cvSaferoomSpread, g_cvTraceHeight;
StringMap g_smNoSpreadMaps, g_smNoDetonatable;
int g_iSaferoomSpread;

// TerrorNavArea
// Bitflags for TerrorNavArea.SpawnAttributes
enum
{
	TERROR_NAV_EMPTY = 2,
	TERROR_NAV_STOP = 4,
	TERROR_NAV_FINALE = 0x40,
	TERROR_NAV_BATTLEFIELD = 0x100,
	TERROR_NAV_PLAYER_START = 0x80,
	TERROR_NAV_IGNORE_VISIBILITY = 0x200,
	TERROR_NAV_NOT_CLEARABLE = 0x400,
	TERROR_NAV_CHECKPOINT = 0x800,
	TERROR_NAV_OBSCURED = 0x1000,
	TERROR_NAV_NO_MOBS = 0x2000,
	TERROR_NAV_THREAT = 0x4000,
	TERROR_NAV_NOTHREAT = 0x80000,
	TERROR_NAV_LYINGDOWN = 0x100000,
	TERROR_NAV_RESCUE_CLOSET = 0x10000,
	TERROR_NAV_RESCUE_VEHICLE = 0x8000
}
int g_iOffs_SpawnAttributes;

methodmap TerrorNavArea {
	property int m_spawnAttributes {
		public get() { return LoadFromAddress(view_as<Address>(this) + view_as<Address>(g_iOffs_SpawnAttributes), NumberType_Int32); }
	}
	property float m_flow {
		public get() { return L4D2Direct_GetTerrorNavAreaFlow(view_as<Address>(this)); }
	}
}
#define NULL_NAV_AREA view_as<TerrorNavArea>(0)

public void OnPluginStart()
{
	GameData conf = new GameData(GAMEDATA_FILE);
	if (!conf) SetFailState("Missing gamedata \""...GAMEDATA_FILE..."\"");
	
	g_iOffs_SpawnAttributes = conf.GetOffset(KEY_SPAWNATTRIBUTES);
	if (g_iOffs_SpawnAttributes == -1) SetFailState("Missing offset \""...KEY_SPAWNATTRIBUTES..."\"");
	
	MemoryPatch hPatch = MemoryPatch.CreateFromConf(conf, KEY_DETONATE_FLAG_PATCH);
	if (!hPatch.Enable()) SetFailState("Failed to enable patch \""...KEY_DETONATE_FLAG_PATCH..."\"");
	
	hPatch = MemoryPatch.CreateFromConf(conf, KEY_SPREAD_FLAG_PATCH);
	if (!hPatch.Enable()) SetFailState("Failed to enable patch \""...KEY_SPREAD_FLAG_PATCH..."\"");
	
	hPatch = MemoryPatch.CreateFromConf(conf, KEY_SPREAD_FLAG_PATCH..."2");
	if (!hPatch.Enable()) SetFailState("Failed to enable patch \""...KEY_SPREAD_FLAG_PATCH..."2"..."\"");
	
	hPatch = MemoryPatch.CreateFromConf(conf, KEY_SPREAD_PASS_PATCH);
	if (!hPatch.Enable()) SetFailState("Failed to enable patch \""...KEY_SPREAD_PASS_PATCH..."\"");
	
	hPatch = MemoryPatch.CreateFromConf(conf, KEY_SPREAD_PASS_PATCH..."2");
	if (!hPatch.Enable()) SetFailState("Failed to enable patch \""...KEY_SPREAD_PASS_PATCH..."2"..."\"");
	
	hPatch = MemoryPatch.CreateFromConf(conf, KEY_TRACEHEIGHT_PATCH);
	if (!hPatch.Enable()) SetFailState("Failed to enable patch \""...KEY_TRACEHEIGHT_PATCH..."\"");
	
	g_hAlloc_TraceHeight = new MemoryBlock(4);
	g_hAlloc_TraceHeight.StoreToOffset(0, LoadFromAddress(hPatch.Address + view_as<Address>(4), NumberType_Int32), NumberType_Int32);
	StoreToAddress(hPatch.Address + view_as<Address>(4), view_as<int>(g_hAlloc_TraceHeight.Address), NumberType_Int32);
	
	DynamicDetour hDetour = DynamicDetour.FromConf(conf, KEY_DETONATE);
	if (!hDetour.Enable(Hook_Pre, DTR_OnDetonate_Pre))
		SetFailState("Failed to pre-detour \""...KEY_DETONATE..."\"");
	if (!hDetour.Enable(Hook_Post, DTR_OnDetonate_Post))
		SetFailState("Failed to post-detour \""...KEY_DETONATE..."\"");
	
	delete conf;
	
	g_cvSaferoomSpread = CreateConVar(
							"l4d2_spit_spread_saferoom",
							"1",
							"Decides how the spit should spread in saferoom area.\n"
						...	"0 = No spread, 1 = Spread on intro start area, 2 = Spread on every map.",
							FCVAR_NOTIFY|FCVAR_SPONLY,
							true, 0.0, true, 2.0);
	
	g_cvTraceHeight = CreateConVar(
							"l4d2_deathspit_trace_height",
							"240.0",
							"Decides the height the game trace will try to test for death spits.\n"
						...	"240.0 = Default trace length.",
							FCVAR_NOTIFY|FCVAR_SPONLY,
							true, 0.0);
	
	g_cvTraceHeight.AddChangeHook(OnTraceHeightConVarChanged);
	OnTraceHeightConVarChanged(g_cvTraceHeight, "", "");
	
	g_smNoSpreadMaps = new StringMap();
	RegServerCmd("spit_spread_saferoom_except", SetSaferoomSpitSpreadException);
	
	g_smNoDetonatable = new StringMap();
	g_smNoDetonatable.SetValue("infected", 0);
	g_smNoDetonatable.SetValue("trigger_finale", 0);
}

void OnTraceHeightConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_hAlloc_TraceHeight.StoreToOffset(0, view_as<int>(convar.FloatValue), NumberType_Int32);
}

Action SetSaferoomSpitSpreadException(int args)
{
	if (args != 1)
	{
		PrintToServer("[SM] Usage: spit_spread_saferoom_except <map>");
		return Plugin_Handled;
	}
	
	char map[64];
	GetCmdArg(1, map, sizeof(map));
	String_ToLower(map, sizeof(map));
	g_smNoSpreadMaps.SetValue(map, false);
	
	return Plugin_Handled;
}

public void OnMapStart()
{
	g_iSaferoomSpread = g_cvSaferoomSpread.IntValue;
	
	char sCurrentMap[64];
	GetCurrentMapLower(sCurrentMap, sizeof(sCurrentMap));
	g_smNoSpreadMaps.GetValue(sCurrentMap, g_iSaferoomSpread);
	
	if (g_iSaferoomSpread)
	{
		if (g_cvSaferoomSpread.IntValue == 1 && !L4D_IsFirstMapInScenario())
		{
			g_iSaferoomSpread = 0;
		}
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (classname[6] == '_' && strcmp(classname, "insect_swarm") == 0)
	{
		SDKHook(entity, SDKHook_SpawnPost, SDK_OnSpawnPost);
	}
}

void SDK_OnSpawnPost(int entity)
{
	SDKHook(entity, SDKHook_Think, SDK_OnThink);
}

Action SDK_OnThink(int entity)
{
	static int m_fireSpread = -1;
	if (m_fireSpread == -1)
		m_fireSpread = FindSendPropInfo("CInsectSwarm", "m_fireCount") + 356;
	
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if (owner != -1 && GetEntProp(owner, Prop_Send, "m_zombieClass") == 4 && IsPlayerAlive(owner))
	{
		if (GetEntData(entity, m_fireSpread, 4) == 2) // 2 -> don't spread (likely)
		{
			float vPos[3];
			GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPos);
			
			TerrorNavArea nav = view_as<TerrorNavArea>(L4D_GetNearestNavArea(vPos));
			
			if (!g_iSaferoomSpread)
			{
				if (nav == NULL_NAV_AREA || ~nav.m_spawnAttributes & TERROR_NAV_CHECKPOINT) // not saferoom
				{
					SetEntData(entity, m_fireSpread, 10, 4); // 10 -> spit spread (likely)
				}
			}
			else // allow saferoom spread
			{
				if (g_iSaferoomSpread != 1 || nav.m_flow / L4D2Direct_GetMapMaxFlowDistance() < 0.2) // every map OR start saferoom
				{
					SetEntData(entity, m_fireSpread, 10, 4); // 10 -> spit spread (likely)
				}
			}
		}
	}
	else
	{
		float vPos[3];
		GetEntPropVector(owner, Prop_Send, "m_vecOrigin", vPos);
		vPos[2] += 10.0;
		
		Handle tr = TR_TraceRayFilterEx(vPos, view_as<float>({90.0, 0.0, 0.0}), MASK_SHOT, RayType_Infinite, TraceRayFilter_NoPlayers, entity);
		if (TR_DidHit(tr))
		{
			vPos[2] -= 10.0;
			
			float vEnd[3];
			TR_GetEndPosition(vEnd, tr);
			
			// NOTE:
			//
			// What is invisible death spit? As far as I know it's an issue where the game
			// traces for solid surfaces within certain height, but regardless of the hitting result.
			// If the trace misses, the death spit will have its origin set to the trace end.
			// And if it's at a height over "46.0" units, it becomes invisible in the air.
			// Or, if the trace hits Survivors, the death spit is on their head, still invisible.
			//
			// Let's say the "46.0" is the extra range.
			//
			// Given a case where the spitter jumps at a height greater than the trace length and dies,
			// the death spit will set to be feets above the ground, but it would try to teleport itself
			// to the surface within units of the extra range.
			// 
			// Then here comes a mystery, that is how it works like this as I didn't manage to find out,
			// and it seems not utilizing trace either.
			// Moreever, thanks to @nikita1824 letting me know that invisible death spit is still there,
			// it really seems like the self-teleporting is kinda the same as the death spit traces,
			// which means it doesn't go through Survivors, thus invisible death spit.
			//
			// So finally, I have to use `TeleportEntity` on the puddle to prevent this.
			
			if (vPos[2] - vEnd[2] >= g_cvTraceHeight.FloatValue + 46.0)
			{
				// TODO: remove entity to avoid confusion due to sound?
				SetEntProp(entity, Prop_Send, "m_fireCount", 1);
				L4D2Direct_SetInfernoMaxFlames(entity, 1);
			}
			else
			{
				TeleportEntity(entity, vEnd, NULL_VECTOR, NULL_VECTOR);
			}
		}
		
		delete tr;
	}
	
	SDKUnhook(entity, SDKHook_Think, SDK_OnThink);
	return Plugin_Continue;
}

bool TraceRayFilter_NoPlayers(int entity, int contentsMask, any self)
{
	return entity != self && (!entity || entity > MaxClients);
}

int g_iDetonateObj = -1;
MRESReturn DTR_OnDetonate_Pre(int pThis)
{
	g_iDetonateObj = pThis;
	return MRES_Ignored;
}

MRESReturn DTR_OnDetonate_Post(int pThis)
{
	g_iDetonateObj = -1;
	return MRES_Ignored;
}

public Action CH_PassFilter(int touch, int pass, bool &result)
{
	static char cls[64], touch_cls[64];
	
	// 1. (pass = projectile): detonate
	// 2. (pass = spitter): death spit
	// 3. (pass = insect_swarm): spit spread
	
	if( pass == g_iDetonateObj
		|| (pass <= MaxClients && GetClientTeam(pass) == 3 && GetEntProp(pass, Prop_Send, "m_zombieClass") == 4 && !IsPlayerAlive(pass))
		|| (GetEdictClassname(pass, cls, sizeof(cls)) && strcmp(cls, "insect_swarm") == 0) )
	{
		if (touch > MaxClients)
		{
			GetEdictClassname(touch, touch_cls, sizeof(touch_cls));
			if (!g_smNoDetonatable.ContainsKey(touch_cls))
				return Plugin_Continue;
		}
		
		result = false;
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

stock int GetCurrentMapLower(char[] buffer, int maxlength)
{
	int bytes = GetCurrentMap(buffer, maxlength);
	String_ToLower(buffer, maxlength);
	return bytes;
}

stock void String_ToLower(char[] buffer, int maxlength)
{
	int len = strlen(buffer); //Сounts string length to zero terminator

	for (int i = 0; i < len && i < maxlength; i++) { //more security, so that the cycle is not endless
		if (IsCharUpper(buffer[i])) {
			buffer[i] = CharToLower(buffer[i]);
		}
	}

	buffer[len] = '\0';
}