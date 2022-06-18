#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <left4dhooks>
#include <dhooks>
#include <sourcescramble>

#define PLUGIN_VERSION "1.3"

public Plugin myinfo = 
{
	name = "[L4D2] Rock Trace Unblock",
	author = "Forgetest",
	description = "Prevent hunter/jockey/coinciding survivor from blocking the rock radius check.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
};

#define GAMEDATA_FILE "l4d2_rock_trace_unblock"
#define KEY_BOUNCETOUCH "CTankRock::BounceTouch"
#define KEY_PATCH_FOREACHPLAYER "CTankRock::ProximityThink__No_ForEachPlayer"

ConVar z_tank_rock_radius;
float g_fRockRadiusSquared;

ConVar
	g_cvFlags,
	g_cvJockeyFix;

int
	g_iFlags;

Handle
	g_hSDKCall_BounceTouch;

DynamicHook
	g_hDHook_BounceTouch;

MemoryPatch
	g_hPatch_ForEachPlayer;

void LoadSDK()
{
	Handle conf = LoadGameConfigFile(GAMEDATA_FILE);
	if (!conf) SetFailState("Missing gamedata \""...GAMEDATA_FILE..."\"");
	
	g_hPatch_ForEachPlayer = MemoryPatch.CreateFromConf(conf, KEY_PATCH_FOREACHPLAYER);
	if (!g_hPatch_ForEachPlayer.Validate())
		SetFailState("Missing MemPatch setup for \""...KEY_PATCH_FOREACHPLAYER..."\"");
	
	StartPrepSDKCall(SDKCall_Entity);
	if (!PrepSDKCall_SetFromConf(conf, SDKConf_Virtual, KEY_BOUNCETOUCH))
		SetFailState("Missing offset \""...KEY_BOUNCETOUCH..."\"");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKCall_BounceTouch = EndPrepSDKCall();
	if (!g_hSDKCall_BounceTouch)
		SetFailState("Failed to prepare SDKCall of \""...KEY_BOUNCETOUCH..."\"");
	
	g_hDHook_BounceTouch = DynamicHook.FromConf(conf, KEY_BOUNCETOUCH);
	if (!g_hDHook_BounceTouch)
		SetFailState("Missing dhook setup for \""...KEY_BOUNCETOUCH..."\"");
	
	delete conf;
}

public void OnPluginStart()
{
	LoadSDK();
	
	g_cvFlags = CreateConVar(
					"l4d2_rock_trace_unblock_flag",
					"5",
					"Prevent SI from blocking the rock radius check.\n"\
				...	"1 = Unblock from all standing SI, 2 = Unblock from pounced, 4 = Unblock from jockeyed, 7 = All, 0 = Disable.",
					FCVAR_NOTIFY|FCVAR_SPONLY,
					true, 0.0, true, 7.0);
	
	g_cvJockeyFix = CreateConVar(
					"l4d2_rock_jockey_dismount",
					"1",
					"Force jockey to dismount the survivor who eats rock.\n"\
				...	"1 = Enable, 0 = Disable.",
					FCVAR_NOTIFY|FCVAR_SPONLY,
					true, 0.0, true, 1.0);
	
	z_tank_rock_radius = FindConVar("z_tank_rock_radius");
	z_tank_rock_radius.AddChangeHook(OnConVarChanged);
	g_cvFlags.AddChangeHook(OnConVarChanged);
	GetCvars();
}

public void OnConfigsExecuted()
{
	GetCvars();
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_iFlags = g_cvFlags.IntValue;
	ApplyPatch(g_iFlags > 0);
	
	g_fRockRadiusSquared = z_tank_rock_radius.FloatValue * z_tank_rock_radius.FloatValue;
	if (L4D2_HasConfigurableDifficultySetting())
	{
		static ConVar z_difficulty = null;
		if (z_difficulty == null)
			z_difficulty = FindConVar("z_difficulty");
		
		char buffer[16];
		z_difficulty.GetString(buffer, sizeof(buffer));
		if (strcmp(buffer, "Easy", false) == 0)
			g_fRockRadiusSquared *= 0.75;
	}
}

void ApplyPatch(bool patch)
{
	if (patch)
		g_hPatch_ForEachPlayer.Enable();
	else
		g_hPatch_ForEachPlayer.Disable();
}

public Action L4D_TankRock_OnRelease(int tank, int rock, float vecPos[3], float vecAng[3], float vecVel[3], float vecRot[3])
{
	if (g_iFlags)
		SDKHook(rock, SDKHook_Think, SDK_OnThink);
	
	if (g_cvJockeyFix.BoolValue)
		g_hDHook_BounceTouch.HookEntity(Hook_Post, rock, DHook_OnBounceTouch_Post);
	
	return Plugin_Continue;
}

Action SDK_OnThink(int entity)
{
	static float vOrigin[3], vLastOrigin[3], vPos[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vOrigin);
	
	static int m_vLastPosition = -1;
	if (m_vLastPosition == -1)
		m_vLastPosition = FindSendPropInfo("CBaseCSGrenadeProjectile", "m_vInitialVelocity") + 24;
	
	GetEntDataVector(entity, m_vLastPosition, vLastOrigin);
	
	static Handle tr;
	static DataPack dp;
	
	// Serves as a List for ignored entities in traces
	dp = new DataPack();
	dp.WriteCell(entity); // always self-ignored
	DataPackPos pos = dp.Position;
	
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i))
			continue;
		
		if (L4D_IsPlayerIncapacitated(i) || L4D_IsPlayerHangingFromLedge(i))
			continue;
		
		GetAbsOrigin(i, vPos, true);
		ComputeClosestPoint(vLastOrigin, vOrigin, vPos, vOrigin);
		if (GetVectorDistance(vOrigin, vPos, true) < g_fRockRadiusSquared)
		{
			dp.Position = pos;
			dp.WriteCell(i);
			
			// See if there's any obstracle in the way
			tr = TR_TraceRayFilterEx(vOrigin, vPos, MASK_SOLID, RayType_EndPoint, ProximityThink_TraceFilterList, dp);
			
			if (!TR_DidHit(tr) && TR_GetFraction(tr) >= 1.0)
			{
				// Maybe "TeleportEntity" does the same, let it be.
				SetAbsOrigin(entity, vOrigin);
				
				// For consistency with game, hunters on them are killed first.
				int hunter = GetEntPropEnt(i, Prop_Send, "m_pounceAttacker");
				if (hunter != -1)
				{
					BounceTouch(entity, hunter);
				}
				BounceTouch(entity, i);
				
				// Radius check succeeded in landing someone, exit the loop.
				delete tr;
				break;
			}
			
			delete tr;
		}
	}
	
	delete dp;
	
	return Plugin_Continue;
}

/**
 * @brief Valve's built-in function to get the closest point to potential rock victims.
 *
 * @param vLastPos		Last recorded position of moving object.
 * @param vPos			Current position of moving object.
 * @param vTargetPos	Target position to test.
 * @param result		Vector to store the result.
 * 
 * @return				True if the closest point (for this moment), false otherwise.
 */

bool ComputeClosestPoint(const float vLastPos[3], const float vPos[3], const float vTargetPos[3], float result[3])
{
	float vLastToTarget[3], vLastToPos[3];
	MakeVectorFromPoints(vLastPos, vTargetPos, vLastToTarget);
	MakeVectorFromPoints(vLastPos, vPos, vLastToPos);
	
	float fSpeed = NormalizeVector(vLastToPos, vLastToPos);
	float fDot = GetVectorDotProduct(vLastToTarget, vLastToPos);
	
	if (fDot >= 0.0)
	{
		if (fDot <= fSpeed)
		{
			ScaleVector(vLastToPos, fDot);
			AddVectors(vLastPos, vLastToPos, result);
			return true;
		}
		else
		{
			result = vPos;
			return false;
		}
	}
	else // seems to potentially risk a hit, for tiny performance?
	{
		result = vLastPos;
		return false;
	}
}

bool ProximityThink_TraceFilterList(int entity, int contentsMask, DataPack dp)
{
	dp.Reset();
	if (entity == dp.ReadCell() || entity == dp.ReadCell())
		return false;
	
	if (entity > 0 && entity <= MaxClients)
	{
		// This should not be possible. Radius check runs every think
		// and survivor in between must be the first victim.
		// The only exception is that multiple survivors are coinciding
		// (like at a corner), and this trace will end up with an "obstracle".
		// Treated as a bug here, no options.
		if (GetClientTeam(entity) == 2)
		{
			return false;
		}
		
		switch (GetEntProp(entity, Prop_Send, "m_zombieClass"))
		{
			case 3:
			{
				if (GetEntPropEnt(entity, Prop_Send, "m_pounceVictim") != -1)
				{
					return !(g_iFlags & 2);
				}
			}
			case 5:
			{
				if (GetEntPropEnt(entity, Prop_Send, "m_jockeyVictim") != -1)
				{
					return !(g_iFlags & 4);
				}
			}
		}
		
		if (g_iFlags & 1)
		{
			return false;
		}
	}
	
	return true;
}

MRESReturn DHook_OnBounceTouch_Post(int pThis, DHookReturn hReturn, DHookParam hParams)
{
	int client = -1;
	if (!hParams.IsNull(1))
		client = hParams.Get(1);
	
	if( client > 0 && client <= MaxClients
		&& GetClientTeam(client) == 2
		&& !L4D_IsPlayerIncapacitated(client) )
	{
		int jockey = GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker");
		if (jockey != -1)
		{
			Dismount(jockey);
		}
	}
	
	return MRES_Ignored;
}

void BounceTouch(int rock, int client)
{
	SDKCall(g_hSDKCall_BounceTouch, rock, client);
}

void Dismount(int client)
{
	int flags = GetCommandFlags("dismount");
	SetCommandFlags("dismount", flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "dismount");
	SetCommandFlags("dismount", flags);
}