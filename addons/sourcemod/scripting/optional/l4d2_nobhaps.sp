#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <l4d2util_constants>
//#define LEFT4FRAMEWORK_GAMEDATA_ONLY 1
//#include <left4framework>

#define DEBUG 0

#define NEW_METHOD_GET_MAX_SPEED 1 // 0 - old

#define LEFT4FRAMEWORK_GAMEDATA "left4dhooks.l4d2" // left4dhooks
#define SECTION_NAME "CTerrorPlayer::GetRunTopSpeed"

int
	g_iCvarSIExcept = 0;

bool
	g_bCvarEnable = false,
	g_bCvarSurvivorExcept = false;

float
	g_fLeftGroundMaxSpeed[MAXPLAYERS + 1] = {0.0, ...};

ConVar
	g_hCvarEnable = null,
	g_hCvarSIExcept = null,
	g_hCvarSurvivorExcept = null;

#if NEW_METHOD_GET_MAX_SPEED
Handle
	g_hGetRunTopSpeed = null;
#endif

public Plugin myinfo =
{
	name = "Simple Anti-Bunnyhop",
	author = "CanadaRox, ProdigySim, blodia, CircleSquared, robex, A1m`",
	description = "Stops bunnyhops by restricting speed when a player lands on the ground to their MaxSpeed",
	version = "0.5.1",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
#if NEW_METHOD_GET_MAX_SPEED
	LoadSDK();
#endif

	g_hCvarEnable = CreateConVar( \
		"simple_antibhop_enable", \
		"1", \
		"Enable or disable the Simple Anti-Bhop plugin (0 - disable, 1 - enable).", \
		_, true, 0.0, true, 1.0 \
	);

	// 1 - smoker, 2 - boomer, 4 - hunter, 8 - spitter, 16 - jockey, 32 - charger, 64 - tank
	// 1 + 2 + 4 + 8 + 16 + 32 + 64 = 127 full flag
	// Exmaple 1: 1 + 4 = 5 - allow bhop for smoker and hunter.
	// Exmaple 2: 1 + 2 + 4 + 8 + 16 + 32 = 63 - allow bhop for all classes, except for the tank.
	g_hCvarSIExcept = CreateConVar( \
		"bhop_except_si_flags", \
		"0", \
		"Bitfield for exempting SI in anti-bhop functionality. \
		1 - smoker, 2 - boomer, 4 - hunter, 8 - spitter, 16 - jockey, 32 - charger, 64 - tank.", \
		_, true, 0.0, true, 127.0 \
	);

	g_hCvarSurvivorExcept = CreateConVar( \
		"bhop_allow_survivor", \
		"0", \
		"Allow Survivors to bhop while plugin is enabled (1 - allow, 0 - block).", \
		_, true, 0.0, true, 1.0 \
	);

	CvarsToType();

	g_hCvarEnable.AddChangeHook(Cvars_Changed);
	g_hCvarSIExcept.AddChangeHook(Cvars_Changed);
	g_hCvarSurvivorExcept.AddChangeHook(Cvars_Changed);

	RegConsoleCmd("sm_check_bhop", Cmd_CheckBhop);
}

#if NEW_METHOD_GET_MAX_SPEED
void LoadSDK()
{
	Handle hGameData = LoadGameConfigFile(LEFT4FRAMEWORK_GAMEDATA);
	if (hGameData == null) {
		SetFailState("Could not load gamedata/%s.txt", LEFT4FRAMEWORK_GAMEDATA);
	}

	StartPrepSDKCall(SDKCall_Player);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, SECTION_NAME)) {
		SetFailState("Function '%s' not found", SECTION_NAME);
	}

	PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_Plain);

	g_hGetRunTopSpeed = EndPrepSDKCall();
	if (g_hGetRunTopSpeed == null) {
		SetFailState("Function '%s' found, but something went wrong", SECTION_NAME);
	}

	delete hGameData;
}
#endif

void CvarsToType()
{
	g_bCvarEnable = g_hCvarEnable.BoolValue;
	g_iCvarSIExcept = g_hCvarSIExcept.IntValue;
	g_bCvarSurvivorExcept = g_hCvarSurvivorExcept.BoolValue;
}

void Cvars_Changed(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	CvarsToType();
}

Action Cmd_CheckBhop(int iClient, int iArgs)
{
	if (!g_bCvarEnable) {
		ReplyToCommand(iClient, "Bunnyhop is allowed for everyone!");
		return Plugin_Handled;
	}

	ReplyToCommand(iClient, "Bunnyhop is %s for survivors!", (g_bCvarSurvivorExcept) ? "allowed" : "blocked");

	for (int i = view_as<int>(L4D2Infected_Smoker); i <= view_as<int>(L4D2Infected_Tank); i++) {
		if (i == view_as<int>(L4D2Infected_Witch)) {
			continue;
		}

		ReplyToCommand(iClient, "[Infected] Bunnyhop is %s for %s zombie class!", (IsAllowBhopZClass(i)) ? "allowed" : "blocked", L4D2_InfectedNames[i]);
	}

	return Plugin_Handled;
}

public Action OnPlayerRunCmd(int iClient, int& iButtons, int& iImpulse, float fVel[3], float fAngles[3], \
								int& iWeapon, int& iSubtype, int& iCmdNum, int& iTickcount, int& iSeed, int iMouse[2])
{
	if (!g_bCvarEnable || IsFakeClient(iClient) || !IsPlayerAlive(iClient)) {
		return Plugin_Continue;
	}

	switch (GetClientTeam(iClient)) {
		case L4D2Team_Survivor: {
			if (g_bCvarSurvivorExcept) {
				return Plugin_Continue;
			}
		}
		case L4D2Team_Infected: {
			int iZClass = GetEntProp(iClient, Prop_Send, "m_zombieClass");
			if (IsAllowBhopZClass(iZClass)) {
				return Plugin_Continue;
			}
		}
		default: {
			return Plugin_Continue;
		}
	}

	if (GetEntityFlags(iClient) & FL_ONGROUND) {
		if (g_fLeftGroundMaxSpeed[iClient] != -1.0) {
			float CurVelVec[3];
			GetEntPropVector(iClient, Prop_Data, "m_vecAbsVelocity", CurVelVec);

			if (GetVectorLength(CurVelVec) > g_fLeftGroundMaxSpeed[iClient]) {
				#if DEBUG
					PrintToChat(iClient, "Speed: %f {%.02f, %.02f, %.02f}, MaxSpeed: %f", \
											GetVectorLength(CurVelVec), CurVelVec[0], CurVelVec[1], CurVelVec[2], g_fLeftGroundMaxSpeed[iClient]);
				#endif

				NormalizeVector(CurVelVec, CurVelVec);
				ScaleVector(CurVelVec, g_fLeftGroundMaxSpeed[iClient]);
				TeleportEntity(iClient, NULL_VECTOR, NULL_VECTOR, CurVelVec);
			}
			g_fLeftGroundMaxSpeed[iClient] = -1.0;
		}
	} else if (g_fLeftGroundMaxSpeed[iClient] == -1.0) {
		#if NEW_METHOD_GET_MAX_SPEED
			g_fLeftGroundMaxSpeed[iClient] = SDKCall(g_hGetRunTopSpeed, iClient);
		#else
			g_fLeftGroundMaxSpeed[iClient] = GetEntPropFloat(iClient, Prop_Data, "m_flMaxspeed");
		#endif
	}

	return Plugin_Continue;
}

bool IsAllowBhopZClass(int iZClass)
{
	if (iZClass == view_as<int>(L4D2Infected_Tank)) {
		iZClass--;
	}
	iZClass--;

	if (iZClass >= view_as<int>(L4D2Infected_Common)
		&& iZClass <= view_as<int>(L4D2Infected_Charger)
		&& ((1 << iZClass) & g_iCvarSIExcept)
	) {
		// Skipping calculation for This SI based on exception rules
		return true;
	}

	return false;
}
