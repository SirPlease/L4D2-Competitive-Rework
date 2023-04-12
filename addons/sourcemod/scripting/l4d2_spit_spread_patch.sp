#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <left4dhooks>
#include <dhooks>
#include <sourcescramble>
#include <collisionhook>

#define PLUGIN_VERSION "1.20"

public Plugin myinfo = 
{
	name = "[L4D2] Spit Spread Patch",
	author = "Forgetest",
	description = "Fix various spit spread issues.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
};

//======================================================================================================
// GameData specific
//======================================================================================================

#define GAMEDATA_FILE "l4d2_spit_spread_patch"
#define KEY_DETONATE "CSpitterProjectile::Detonate"
#define KEY_SOLIDMASK "CSpitterProjectile::PhysicsSolidMaskForEntity"
#define KEY_EVENT_KILLED "CTerrorPlayer::Event_Killed"
#define KEY_DETONATE_FLAG_PATCH "CSpitterProjectile::Detonate__TraceFlag_patch"
#define KEY_SPREAD_FLAG_PATCH "CInferno::Spread__TraceFlag_patch"
#define KEY_SPREAD_PASS_PATCH "CInferno::Spread__PassEnt_patch"
#define KEY_TRACEHEIGHT_PATCH "CTerrorPlayer::Event_Killed__TraceHeight_patch"

//======================================================================================================
// clean methodmap
//======================================================================================================

methodmap TerrorNavArea {
	public TerrorNavArea(const float vPos[3]) {
		return view_as<TerrorNavArea>(L4D_GetNearestNavArea(vPos));
	}
	public bool Valid() {
		return this != view_as<TerrorNavArea>(0);
	}
	public bool HasSpawnAttributes(int bits) {
		return (this.m_spawnAttributes & bits) == bits;
	}
	property int m_spawnAttributes {
		public get() { return L4D_GetNavArea_SpawnAttributes(view_as<Address>(this)); }
	}
}

//======================================================================================================
// helper identifier
//======================================================================================================

int g_iDetonateObj = -1;
ArrayList g_aDetonatePuddles;

//======================================================================================================
// spread configuration
//======================================================================================================

enum
{
	SAFEROOM_SPREAD_OFF,
	SAFEROOM_SPREAD_INTRO,
	SAFEROOM_SPREAD_ALL
};

int g_iCvarSaferoomSpread, g_iSaferoomSpread, g_iMaxFlames;
bool g_bWaterCollision;
float g_flTraceHeight, g_flPropDamage;

StringMap g_smNoSpreadMaps;

StringMap g_smFilterClasses;

//======================================================================================================

void LoadSDK()
{
	Handle conf = LoadGameConfigFile(GAMEDATA_FILE);
	if (!conf) SetFailState("Missing gamedata \""...GAMEDATA_FILE..."\"");
	
	if (!MemoryPatch.CreateFromConf(conf, KEY_DETONATE_FLAG_PATCH).Enable()) SetFailState("Failed to enable patch \""...KEY_DETONATE_FLAG_PATCH..."\"");
	if (!MemoryPatch.CreateFromConf(conf, KEY_SPREAD_FLAG_PATCH).Enable()) SetFailState("Failed to enable patch \""...KEY_SPREAD_FLAG_PATCH..."\"");
	if (!MemoryPatch.CreateFromConf(conf, KEY_SPREAD_FLAG_PATCH..."2").Enable()) SetFailState("Failed to enable patch \""...KEY_SPREAD_FLAG_PATCH..."2"..."\"");
	if (!MemoryPatch.CreateFromConf(conf, KEY_SPREAD_PASS_PATCH).Enable()) SetFailState("Failed to enable patch \""...KEY_SPREAD_PASS_PATCH..."\"");
	if (!MemoryPatch.CreateFromConf(conf, KEY_SPREAD_PASS_PATCH..."2").Enable()) SetFailState("Failed to enable patch \""...KEY_SPREAD_PASS_PATCH..."2"..."\"");
	
	MemoryPatch hPatch = MemoryPatch.CreateFromConf(conf, KEY_TRACEHEIGHT_PATCH);
	if (!hPatch.Enable()) SetFailState("Failed to enable patch \""...KEY_TRACEHEIGHT_PATCH..."\"");
	
	// replace with custom memory
	StoreToAddress(hPatch.Address + view_as<Address>(4), GetAddressOfCell(g_flTraceHeight), NumberType_Int32);
	
	DynamicDetour hDetour = DynamicDetour.FromConf(conf, KEY_DETONATE);
	if (!hDetour)
		SetFailState("Missing detour setup of \""...KEY_DETONATE..."\"");
	if (!hDetour.Enable(Hook_Pre, DTR_OnDetonate_Pre))
		SetFailState("Failed to pre-detour \""...KEY_DETONATE..."\"");
	if (!hDetour.Enable(Hook_Post, DTR_OnDetonate_Post))
		SetFailState("Failed to post-detour \""...KEY_DETONATE..."\"");
	
	delete hDetour;
	
	hDetour = DynamicDetour.FromConf(conf, KEY_SOLIDMASK);
	if (!hDetour)
		SetFailState("Missing detour setup of \""...KEY_SOLIDMASK..."\"");
	if (!hDetour.Enable(Hook_Post, DTR_OnPhysicsSolidMaskForEntity_Post))
		SetFailState("Failed to post-detour \""...KEY_SOLIDMASK..."\"");
	
	delete hDetour;
	
	/**
	 * Spit configuration: class
	 * 
	 * Trace doesn't touch these classes.
	 */
	g_smFilterClasses = new StringMap();
	
	char buffer[64], buffer2[64];
	for( int i = 1;
		FormatEx(buffer, sizeof(buffer), "SpitFilterClass%i", i)
		&& GameConfGetKeyValue(conf, buffer, buffer, sizeof(buffer));
		++i )
	{
		g_smFilterClasses.SetValue(buffer, 0);
		PrintToServer("[SpitPatch] Read \"SpitFilterClass\" (%s)", buffer);
	}
	
	/**
	 * Spread configuration: class
	 * 
	 * (== 0)	-> No spread (2 flames)
	 * (>= 2)	-> Custom flames
	 */
	int maxflames;
	for( int i = 1;
		FormatEx(buffer, sizeof(buffer), "SpreadFilterClass%i", i)
		&& GameConfGetKeyValue(conf, buffer, buffer, sizeof(buffer))
		&& FormatEx(buffer2, sizeof(buffer2), "SpreadFilterClass%i_maxflames", i)
		&& GameConfGetKeyValue(conf, buffer2, buffer2, sizeof(buffer2));
		++i )
	{
		maxflames = StringToInt(buffer2);
		maxflames = maxflames >= 2 ? maxflames : 2; // indeed clamped to [2, cvarMaxFlames], a part here
		g_smFilterClasses.SetValue(buffer, maxflames);
		PrintToServer("[SpitPatch] Read \"SpreadFilterClass\" (%s) [maxflames = %i]", buffer, maxflames);
	}
	
	delete conf;
}

public void OnPluginStart()
{
	LoadSDK();
	
	CreateConVarHook("l4d2_spit_spread_saferoom",
					"0",
					"Decides how the spit should spread in saferoom area.\n"
				...	"0 = No spread, 1 = Spread on intro start area, 2 = Spread on every map.",
					FCVAR_NOTIFY|FCVAR_SPONLY,
					true, 0.0, true, 2.0,
					CvarChange_SaferoomSpread);
	
	CreateConVarHook("l4d2_deathspit_trace_height",
					"240.0",
					"Decides the height the game trace will try to test for death spits.\n"
				...	"240.0 = Default trace length.",
					FCVAR_NOTIFY|FCVAR_SPONLY,
					true, 0.0, false, 0.0,
					CvarChange_TraceHeight);
	
	CreateConVarHook("l4d2_spit_max_flames",
					"10",
					"Decides the max puddles a normal spit will create.\n"
				...	"Minimum = 2, Game default = 10.",
					FCVAR_NOTIFY|FCVAR_SPONLY,
					true, 2.0, false, 0.0,
					CvarChange_MaxFlames);
	
	CreateConVarHook("l4d2_spit_water_collision",
					"0",
					"Decides whether the spit projectile will collide with water.\n"
				...	"0 = No collision, 1 = Enable collision.",
					FCVAR_NOTIFY|FCVAR_SPONLY,
					true, 0.0, true, 1.0,
					CvarChange_WaterCollision);
	
	CreateConVarHook("l4d2_spit_prop_damage",
					"10.0",
					"Amount of damage done to props that projectile bounces on.\n"
				...	"0 = No damage.",
					FCVAR_NOTIFY|FCVAR_SPONLY,
					true, 0.0, false, 0.0,
					CvarChange_PropDamage);
	
	g_smNoSpreadMaps = new StringMap();
	RegServerCmd("spit_spread_saferoom_except", Cmd_SetSaferoomSpitSpreadException);
	
	g_aDetonatePuddles = new ArrayList();
	
	HookEvent("round_start", Event_RoundStart);
}

void CvarChange_SaferoomSpread(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iCvarSaferoomSpread = convar.IntValue;
	RequestFrame(OnMapStart);
}

void CvarChange_TraceHeight(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flTraceHeight = convar.FloatValue;
}

void CvarChange_MaxFlames(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iMaxFlames = convar.IntValue;
}

void CvarChange_WaterCollision(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bWaterCollision = convar.BoolValue;
}

void CvarChange_PropDamage(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_flPropDamage = convar.FloatValue;
}

Action Cmd_SetSaferoomSpitSpreadException(int args)
{
	if (args != 1)
	{
		PrintToServer("[SM] Usage: spit_spread_saferoom_except <map>");
		return Plugin_Handled;
	}
	
	char map[64];
	GetCmdArg(1, map, sizeof(map));
	String_ToLower(map, sizeof(map));
	g_smNoSpreadMaps.SetValue(map, 0);
	
	PrintToServer("[SpitPatch] Set spread exception on \"%s\"", map);
	return Plugin_Handled;
}

//======================================================================================================

public void OnMapStart()
{
	g_iSaferoomSpread = g_iCvarSaferoomSpread; // global default
	
	char sCurrentMap[64];
	GetCurrentMapLower(sCurrentMap, sizeof(sCurrentMap));
	g_smNoSpreadMaps.GetValue(sCurrentMap, g_iSaferoomSpread); // forbidden map
	
	if (g_iSaferoomSpread)
	{
		if (g_iCvarSaferoomSpread == SAFEROOM_SPREAD_INTRO && !L4D_IsFirstMapInScenario()) // intro map
		{
			g_iSaferoomSpread = SAFEROOM_SPREAD_OFF;
		}
	}
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_aDetonatePuddles.Clear();
}

//======================================================================================================

public void OnEntityCreated(int entity, const char[] classname)
{
	if (classname[0] == 'i' && strcmp(classname, "insect_swarm") == 0)
	{
		SDKHook(entity, SDKHook_SpawnPost, SDK_OnSpawnPost);
	}
	else if (classname[0] == 's' && strcmp(classname, "spitter_projectile") == 0)
	{
		SDKHook(entity, SDKHook_SpawnPost, SDK_OnSpawnPost_Projectile);
	}
}

void SDK_OnSpawnPost(int entity)
{
	if (g_iDetonateObj != -1)
	{
		g_aDetonatePuddles.Push(EntIndexToEntRef(entity));
	}
	
	SDKHook(entity, SDKHook_Think, SDK_OnThink);
}

void SDK_OnSpawnPost_Projectile(int entity)
{
	SDKHook(entity, SDKHook_Touch, SDK_OnTouch);
}

Action SDK_OnTouch(int entity, int other)
{
	if (g_flPropDamage == 0.0)
		return Plugin_Continue;
	
	if (other <= MaxClients)
		return Plugin_Continue;
	
	SDKHooks_TakeDamage(other, entity, GetEntPropEnt(entity, Prop_Send, "m_hThrower"), g_flPropDamage, DMG_CLUB);
	return Plugin_Continue;
}

Action SDK_OnThink(int entity)
{
	float vPos[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPos);
	
	// Check if in water first
	float flDepth = GetDepthBeneathWater(vPos);
	if (flDepth > 0.0)
	{
		vPos[2] += flDepth;
		TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
	}
	
	int index = g_aDetonatePuddles.FindValue(EntIndexToEntRef(entity));
	if (index != -1)
	{
		g_aDetonatePuddles.Erase(index);
		
		int maxflames = g_iMaxFlames;
		if (L4D2Direct_GetInfernoMaxFlames(entity) == 2)
		{
			// check if max flames customized
			int parent = GetEntPropEnt(entity, Prop_Data, "m_pParent");
			char cls[64];
			if (parent != -1 && GetEdictClassname(parent, cls, sizeof(cls)))
			{
				if (g_smFilterClasses.GetValue(cls, parent) && parent != 0)
				{
					maxflames = parent <= maxflames ? parent : maxflames;
				}
			}
			
			TerrorNavArea nav = TerrorNavArea(vPos);
			if (nav.Valid() && nav.HasSpawnAttributes(NAV_SPAWN_CHECKPOINT))
			{
				bool isStart = nav.HasSpawnAttributes(NAV_SPAWN_PLAYER_START);
				if (!IsSaferoomSpreadAllowed(isStart))
				{
					maxflames = 2;
					CreateTimer(0.3, Timer_FixInvisibleSpit, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
		L4D2Direct_SetInfernoMaxFlames(entity, maxflames);
	}
	else
	{
		if (flDepth == 0.0) // Check if invisbile spit
		{
			float vEnd[3];
			vEnd[0] = vPos[0];
			vEnd[1] = vPos[1];
			vEnd[2] = vPos[2] - 46.0;
			
			Handle tr = TR_TraceRayFilterEx(vPos, vEnd, MASK_SHOT|MASK_WATER, RayType_EndPoint, TraceRayFilter_NoPlayers, entity);
			
			// NOTE:
			//
			// v1.18:
			// Seems something to do with "CNavMesh::GetNearestNavArea" called in
			// "CInferno::CreateFire" that teleports the puddle to there.
			//
			//========================================================================================
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
			
			if (!TR_DidHit(tr))
			{
				RemoveEntity(entity);
			}
			else
			{
				TR_GetEndPosition(vEnd, tr);
				TeleportEntity(entity, vEnd, NULL_VECTOR, NULL_VECTOR);
				CreateTimer(0.3, Timer_FixInvisibleSpit, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
			}
			
			delete tr;
		}
	}
	
	SDKUnhook(entity, SDKHook_Think, SDK_OnThink);
	return Plugin_Continue;
}

bool TraceRayFilter_NoPlayers(int entity, int contentsMask, any self)
{
	return entity != self && (!entity || entity > MaxClients);
}

Action Timer_FixInvisibleSpit(Handle timer, int entRef)
{
	int entity = EntRefToEntIndex(entRef);
	if (IsValidEdict(entity))
	{
		// Big chance that puddles with max 2 flames get the latter one invisible.
		if (GetEntProp(entity, Prop_Send, "m_fireCount") == 2)
		{
			SetEntProp(entity, Prop_Send, "m_fireCount", 1);
			L4D2Direct_SetInfernoMaxFlames(entity, 1);
		}
	}
	return Plugin_Stop;
}

float GetDepthBeneathWater(const float vecStart[3])
{
	static const float MAX_WATER_DEPTH = 300.0;
	
	float vecEnd[3];
	
	vecEnd[0] = vecStart[0];
	vecEnd[1] = vecStart[1];
	vecEnd[2] = vecStart[2] + MAX_WATER_DEPTH;
	
	float flFraction = 0.0;
	
	Handle tr = TR_TraceRayFilterEx(vecStart, vecEnd, MASK_WATER, RayType_EndPoint, TraceRayFilter_NoPlayers, -1);
	if (TR_StartSolid(tr))
	{
		flFraction = TR_GetFractionLeftSolid(tr);
	}
	delete tr;
	
	return flFraction * MAX_WATER_DEPTH;
}

bool IsSaferoomSpreadAllowed(bool isStartSaferoom)
{
	if (L4D2_IsScavengeMode() || L4D_IsSurvivalMode())
		return g_iSaferoomSpread != SAFEROOM_SPREAD_OFF;
	
	if (g_iSaferoomSpread == SAFEROOM_SPREAD_ALL)
		return true;
	
	if (g_iSaferoomSpread == SAFEROOM_SPREAD_INTRO && isStartSaferoom)
		return true;
	
	return false;
}

//======================================================================================================

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
	
	if (pass > MaxClients)
	{
		// (pass = projectile): detonate
		if (pass != g_iDetonateObj) 
		{
			// (pass = insect_swarm): spit spread
			if (!GetEdictClassname(pass, cls, sizeof(cls)) || strcmp(cls, "insect_swarm") != 0)
				return Plugin_Continue;
		}
	}
	else if (pass > 0)
	{
		// (pass = spitter): death spit
		if (!IsClientInGame(pass))
			return Plugin_Continue;
		
		if (IsPlayerAlive(pass))
			return Plugin_Continue;
		
		if (GetClientTeam(pass) != 3)
			return Plugin_Continue;
		
		if (GetEntProp(pass, Prop_Send, "m_zombieClass") != 4)
			return Plugin_Continue;
	}
	else // world, always collide
	{
		return Plugin_Continue;
	}
	
	if (touch > MaxClients) // check for filter classes
	{
		GetEdictClassname(touch, touch_cls, sizeof(touch_cls));
		
		// non-filtered or a spread configuration
		if (!g_smFilterClasses.GetValue(touch_cls, touch) || touch != 0)
		{
			// don't spread on weapons
			if (strncmp(touch_cls, "weapon_", 7) != 0)
				return Plugin_Continue;
		}
	}
	
	result = false;
	return Plugin_Handled;
}

//======================================================================================================

MRESReturn DTR_OnPhysicsSolidMaskForEntity_Post(DHookReturn hReturn)
{
	if (!g_bWaterCollision)
		return MRES_Ignored;
	
	hReturn.Value |= MASK_WATER;
	return MRES_Supercede;
}

//======================================================================================================

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

stock int GetCurrentMapLower(char[] buffer, int maxlength)
{
	int bytes = GetCurrentMap(buffer, maxlength);
	String_ToLower(buffer, maxlength);
	return bytes;
}

// l4d2util_stocks.inc
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