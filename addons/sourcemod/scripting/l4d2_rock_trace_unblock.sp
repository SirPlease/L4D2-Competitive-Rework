#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <left4dhooks>
#include <dhooks>
#include <sourcescramble>

#define PLUGIN_VERSION "1.7"

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
	g_cvJockeyFix,
	g_cvHurtCapper;

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
				...	"1 = Unblock from all standing SI, 2 = Unblock from pounced, 4 = Unblock from jockeyed, 8 = Unblock from pummelled, 15 = All, 0 = Disable.",
					FCVAR_NOTIFY|FCVAR_SPONLY,
					true, 0.0, true, 15.0);
	
	g_cvJockeyFix = CreateConVar(
					"l4d2_rock_jockey_dismount",
					"1",
					"Force jockey to dismount the survivor who eats rock.\n"\
				...	"1 = Enable, 0 = Disable.",
					FCVAR_NOTIFY|FCVAR_SPONLY,
					true, 0.0, true, 1.0);
	
	g_cvHurtCapper = CreateConVar(
					"l4d2_rock_hurt_capper",
					"5",
					"Hurt cappers before landing their victims.\n"\
				...	"1 = Hurt hunter, 2 = Hurt jockey, 4 = Hurt charger, 7 = All, 0 = Disable.",
					FCVAR_NOTIFY|FCVAR_SPONLY,
					true, 0.0, true, 7.0);
	
	z_tank_rock_radius = FindConVar("z_tank_rock_radius");
	z_tank_rock_radius.AddChangeHook(OnConVarChanged);
	g_cvFlags.AddChangeHook(OnConVarChanged);
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
	//if (L4D2_HasConfigurableDifficultySetting())
	{
		static ConVar z_difficulty = null;
		if (z_difficulty == null)
			z_difficulty = FindConVar("z_difficulty");
		
		char buffer[16];
		z_difficulty.GetString(buffer, sizeof(buffer));
		if (strcmp(buffer, "Easy", false) == 0)
			g_fRockRadiusSquared *= 0.5625; // 0.75 ^ 2
	}
}

void ApplyPatch(bool patch)
{
	if (patch)
		g_hPatch_ForEachPlayer.Enable();
	else
		g_hPatch_ForEachPlayer.Disable();
}

public void L4D_TankRock_OnRelease_Post(int tank, int rock, const float vecPos[3], const float vecAng[3], const float vecVel[3], const float vecRot[3])
{
	if (g_iFlags)
		SDKHook(rock, SDKHook_Think, SDK_OnThink);
	
	if (g_cvJockeyFix.BoolValue)
		g_hDHook_BounceTouch.HookEntity(Hook_Post, rock, DHook_OnBounceTouch_Post);
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
				
				// Hurt attackers first, based on flag setting
				HurtCappers(entity, i);
				
				// Confirm landing
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
 * @brief Valve's built-in function to compute close point to potential rock victims.
 *
 * @param vLeft			Last recorded position of moving object.
 * @param vRight		Current position of moving object.
 * @param vPos			Target position to test.
 * @param result		Vector to store the result.
 * 
 * @return				True if the closest point, false otherwise.
 */

bool ComputeClosestPoint(const float vLeft[3], const float vRight[3], const float vPos[3], float result[3])
{
	static float vLTarget[3], vLine[3];
	MakeVectorFromPoints(vLeft, vPos, vLTarget);
	MakeVectorFromPoints(vLeft, vRight, vLine);
	
	static float fLength, fDot;
	fLength = NormalizeVector(vLine, vLine);
	fDot = GetVectorDotProduct(vLTarget, vLine);
	
	/**
	 *       * (T)
	 *      /|
	 *     / |
	 *    L==P====R
	 *
	 *  L, R -> Line
	 *  T -> Target
	 *  P -> result point
	 */
	
	if (fDot >= 0.0) // (-pi/2 < θ < pi/2)
	{
		if (fDot <= fLength) // We can find a P on the line
		{
			ScaleVector(vLine, fDot);
			AddVectors(vLeft, vLine, result);
			return true;
		}
		else // Too far from T
		{
			result = vPos;
			return false;
		}
	}
	else // seems to potentially risk a hit, for tiny performance?
	{
		result = vLeft;
		return false;
	}
}

bool ProximityThink_TraceFilterList(int entity, int contentsMask, DataPack dp)
{
	dp.Reset();
	if (entity == dp.ReadCell() || entity == dp.ReadCell())
		return false;
	
	if (entity > 0 && entity <= MaxClients && IsClientInGame(entity))
	{
		/**
		 * NOTE:
		 *
		 * This should not be possible as radius check runs every think
		 * and survivors in between must be prior to be targeted.
		 *
		 * As far as I know, the only exception is that multiple survivors
		 * are coinciding (like at a corner), and obstracle tracing ends up
		 * with "true", kinda false positive.
		 *
		 * Treated as a bug here, no options.
		 */
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
			case 6:
			{
				if (GetEntPropEnt(entity, Prop_Send, "m_pummelVictim") != -1)
				{
					return !(g_iFlags & 8);
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

void HurtCappers(int rock, int client)
{
	int flag = g_cvHurtCapper.IntValue;
	
	if (flag & 1) // hunter
	{
		int hunter = GetEntPropEnt(client, Prop_Send, "m_pounceAttacker");
		if (hunter != -1)
		{
			BounceTouch(rock, hunter);
			return;
		}
	}
	
	if (flag & 2) // jockey
	{
		int jockey = GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker");
		if (jockey != -1)
		{
			BounceTouch(rock, jockey);
			return;
		}
	}
	
	if (flag & 4) // charger
	{
		int charger = GetEntPropEnt(client, Prop_Send, "m_pummelAttacker");
		if (charger != -1)
		{
			BounceTouch(rock, charger);
			return;
		}
	}
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