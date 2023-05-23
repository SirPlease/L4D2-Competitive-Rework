// AtomicStryker, foxhound27, HarryPotter @ 2010-2022

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

#define PLUGIN_VERSION "1.3.1"
#define STRINGLENGTH_CLASSES 64
#define L4D2_WEPID_VOMITJAR           25
#define CLASSNAME_VOMITJAR            "vomitjar_projectile"

float TRACE_TOLERANCE = 25.0;
float BILE_POS_HEIGHT_FIX = 70.0;
int ZOMBIECLASS_BOOMER = 2;
int L4D2Team_Survivors = 2;
int L4D2Team_Infected = 3;
char ENTPROP_ZOMBIE_CLASS[] = "m_zombieClass";
char ENTPROP_IS_GHOST[] = "m_isGhost";
char CLASS_BILEJAR[] = "vomitjar_projectile";
char CLASS_ZOMBIE[] = "infected";
char CLASS_WITCH[] = "witch";

ConVar cvar_BoomerDeath, cvar_VomitJar, cvar_BoomerDeath_Radius, cvar_VomitJar_Radius, cvar_VomitJarSurvivorHP;
#define MAXENTITIES                   2048
static int    ge_iType[MAXENTITIES+1];

public Plugin myinfo = 
{
	name = "L4D2 Bile the World",
	author = "AtomicStryker, HarryPotter",
	description = "Vomit Jars hit Survivors, Boomer Explosions slime Infected",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1237748"
}

public void OnPluginStart()
{
	HookEvent("player_death", event_PlayerDeath);

	cvar_BoomerDeath = CreateConVar("l4d2_bile_the_world_boomer_death", "1", "如果为1，则胖子爆炸后将会喷到特感、女巫、坦克和小僵尸.", FCVAR_NOTIFY, true, 0.0, true, 1.0); 
	cvar_BoomerDeath_Radius = CreateConVar("l4d2_bile_the_world_boomer_death_radius", "250", "胖子死亡后喷发胆汁的范围", FCVAR_NOTIFY, true, 0.0); 
	cvar_VomitJar = CreateConVar("l4d2_bile_the_world_vomit_jar", "1", "如果为1，则生还者被胆汁砸到后也会被胆汁糊脸", FCVAR_NOTIFY, true, 0.0, true, 1.0); 
	cvar_VomitJar_Radius = CreateConVar("l4d2_bile_the_world_vomit_jar_radius", "150", "胆汁范围", FCVAR_NOTIFY, true, 0.0); 
	cvar_VomitJarSurvivorHP = CreateConVar("l4d2_bile_the_world_vomit_teammate_hp", "30", "当生还者被胆汁砸中后扣多少血 (0=关)", FCVAR_NOTIFY, true, 0.0); 
	
	GetCvars();
	cvar_BoomerDeath.AddChangeHook(ConVarChanged_Cvars);
	cvar_BoomerDeath_Radius.AddChangeHook(ConVarChanged_Cvars);
	cvar_VomitJar.AddChangeHook(ConVarChanged_Cvars);
	cvar_VomitJar_Radius.AddChangeHook(ConVarChanged_Cvars);
	cvar_VomitJarSurvivorHP.AddChangeHook(ConVarChanged_Cvars);

	//Autoconfig for plugin
	AutoExecConfig(true, "l4d2_biletheworld");
}

public void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

bool g_bBoomerDeath, g_bVomitJar;
float g_fBoomerDeath_Radius, g_fVomitJar_Radius, g_fVomitJarSurvivorHP;
void GetCvars()
{
	g_bBoomerDeath = cvar_BoomerDeath.BoolValue;
	g_fBoomerDeath_Radius = cvar_BoomerDeath_Radius.FloatValue;
	g_bVomitJar = cvar_VomitJar.BoolValue;
	g_fVomitJar_Radius = cvar_VomitJar_Radius.FloatValue;
	g_fVomitJarSurvivorHP = cvar_VomitJarSurvivorHP.FloatValue;
}

public void event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bBoomerDeath == false) return;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client) || GetClientTeam(client) != L4D2Team_Infected || GetEntProp(client, Prop_Send, ENTPROP_ZOMBIE_CLASS) != ZOMBIECLASS_BOOMER)
	{
		return;
	}
	
	float pos[3];
	GetClientEyePosition(client, pos);

	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (!attacker || !IsClientInGame(attacker))
	{
		VomitSplash(true, pos, client);
	}
	else
	{
		VomitSplash(true, pos, attacker);
	}
}

void HurtEntity(int victim, int client, float damage)
{
	SDKHooks_TakeDamage(victim, client, client, damage, DMG_SLASH);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!IsValidEntityIndex(entity))
		return;

	if (g_bVomitJar == false) return;

	if (StrEqual(classname, CLASSNAME_VOMITJAR))
	{
		SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost);
	}
}

public void OnSpawnPost(int entity)
{
	if( !IsValidEntity(entity) ) return;
	 
	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");

	if(client <= 0 || !IsClientInGame(client)) 
		return;
		
	ge_iType[entity] = GetClientUserId(client);
	//PrintToChatAll("OnSpawnPost() %N throws a bilejar", client);
}

public void OnEntityDestroyed(int entity)
{
	if (!IsValidEntityIndex(entity)) return;
	
	if (g_bVomitJar == false) return;

	char class[STRINGLENGTH_CLASSES];
	GetEdictClassname(entity, class, sizeof(class));
	
	if (strcmp(class, CLASS_BILEJAR) != 0) return;
	
	float pos[3];
	SetClientEyePosition(entity, pos);
	pos[2] += BILE_POS_HEIGHT_FIX;
	
	int client = ge_iType[entity];
	ge_iType[entity] = 0;
	client = GetClientOfUserId(client);

	//PrintToChatAll("OnEntityDestroyed() %N throws a bilejar", client);
	VomitSplash(false, pos, client);
}

void VomitSplash(bool BoomerDeath, float pos[3], int client)
{		
	float targetpos[3];
	if(client <= 0 || client > MaxClients || !IsClientInGame(client)) client = 0;
	
	if (BoomerDeath)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || GetClientTeam(i) != L4D2Team_Infected || !IsPlayerAlive(i) || GetEntProp(i, Prop_Send, ENTPROP_IS_GHOST) != 0)
			{
				continue;
			}
			
			GetClientEyePosition(i, targetpos);
			if (GetVectorDistance(pos, targetpos) > g_fBoomerDeath_Radius || !IsVisibleTo(pos, targetpos))
			{
				continue;
			}
			
			L4D2_CTerrorPlayer_OnHitByVomitJar(i, (client == 0) ? i : client);
		}

		if(client == 0) return;

		char class[STRINGLENGTH_CLASSES];
		int maxents = GetMaxEntities();
		for (int i = MaxClients+1; i <= maxents; i++)
		{
			if (!IsValidEdict(i)) continue;
			GetEdictClassname(i, class, sizeof(class));
			
			if (strcmp(class, CLASS_ZOMBIE) != 0 && strcmp(class, CLASS_WITCH) != 0) continue;
			
			SetClientEyePosition(i, targetpos);
			if (GetVectorDistance(pos, targetpos) > g_fBoomerDeath_Radius || !IsVisibleTo(pos, targetpos))
			{
				continue;
			}
			
			L4D2_Infected_OnHitByVomitJar(i, client);
		}
	}
	else
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || GetClientTeam(i) != L4D2Team_Survivors || !IsPlayerAlive(i))
			{
				continue;
			}
			
			GetClientEyePosition(i, targetpos);
			if (GetVectorDistance(pos, targetpos) > g_fVomitJar_Radius || !IsVisibleTo(pos, targetpos))
			{
				continue;
			}
			
			L4D_CTerrorPlayer_OnVomitedUpon(i, (client == 0) ? i : client);
			if(client > 0 && GetClientTeam(client) == L4D2Team_Survivors && i!=client) HurtEntity(client, client, g_fVomitJarSurvivorHP);
		}
	}
}

bool IsVisibleTo(float position[3], float targetposition[3])
{
	float vAngles[3], vLookAt[3];
	
	MakeVectorFromPoints(position, targetposition, vLookAt); // compute vector from start to target
	GetVectorAngles(vLookAt, vAngles); // get angles from vector for trace
	
	// execute Trace
	Handle trace = TR_TraceRayFilterEx(position, vAngles, MASK_SHOT, RayType_Infinite, _TraceFilter);
	bool isVisible = false;
	if (TR_DidHit(trace))
	{
		float vStart[3];
		TR_GetEndPosition(vStart, trace); // retrieve our trace endpoint
		
		if ((GetVectorDistance(position, vStart, false) + TRACE_TOLERANCE) >= GetVectorDistance(position, targetposition))
		{
			isVisible = true; // if trace ray lenght plus tolerance equal or bigger absolute distance, you hit the target
		}
	}
	else
	{
		LogError("Tracer Bug: Player-Zombie Trace did not hit anything, WTF");
		isVisible = true;
	}
	delete trace;
	return isVisible;
}

public bool _TraceFilter(int entity, int contentsMask)
{
	if (!entity || !IsValidEntity(entity)) // dont let WORLD, or invalid entities be hit
	{
		return false;
	}
	
	return true;
}

//entity abs origin code from here
//http://forums.alliedmods.net/showpost.php?s=e5dce96f11b8e938274902a8ad8e75e9&p=885168&postcount=3
void SetClientEyePosition(int entity, float origin[3])
{
	if (entity && IsValidEntity(entity) && (GetEntSendPropOffs(entity, "m_vecOrigin") != -1) && (GetEntSendPropOffs(entity, "m_vecMins") != -1) && (GetEntSendPropOffs(entity, "m_vecMaxs") != -1))
	{
		float mins[3], maxs[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
		GetEntPropVector(entity, Prop_Send, "m_vecMins", mins);
		GetEntPropVector(entity, Prop_Send, "m_vecMaxs", maxs);
		
		origin[0] += (mins[0] + maxs[0]) * 0.5;
		origin[1] += (mins[1] + maxs[1]) * 0.5;
		origin[2] += (mins[2] + maxs[2]) * 0.5;
	}
}

bool IsValidEntityIndex(int entity)
{
    return (MaxClients+1 <= entity <= GetMaxEntities());
}