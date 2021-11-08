#include <sourcemod>
#include <sdktools>

#define DEBUG 0

#define L4DBUILD 1

#define LEFT4FRAMEWORK_GAMEDATA "left4dhooks.l4d2" // left4dhooks
#define SECTION_NAME "CTerrorPlayer::GetRunTopSpeed" // left4dhooks

//#define LEFT4FRAMEWORK_GAMEDATA "left4downtown.l4d2" // left4downtown
//#define SECTION_NAME "CTerrorPlayer_GetRunTopSpeed" // left4downtown

public Plugin:myinfo =
{
	name = "Simple Anti-Bunnyhop",
	author = "CanadaRox, ProdigySim, blodia, CircleSquared, robex",
	description = "Stops bunnyhops by restricting speed when a player lands on the ground to their MaxSpeed",
	version = "0.3",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

new Handle:hCvarEnable;
#if defined(L4DBUILD)
new Handle:hCvarSIExcept;
new Handle:hCvarSurvivorExcept;
new Handle:g_hGetRunTopSpeed;
#endif

public OnPluginStart()
{
	LoadSDK();
	hCvarEnable = CreateConVar("simple_antibhop_enable", "1", "Enable or disable the Simple Anti-Bhop plugin");
#if defined(L4DBUILD)
	hCvarSIExcept = CreateConVar("bhop_except_si_flags", "0", "Bitfield for exempting SI in anti-bhop functionality. From least significant: Smoker, Boomer, Hunter, Spitter, Jockey, Charger, Tank");
	hCvarSurvivorExcept = CreateConVar("bhop_allow_survivor", "0", "Allow Survivors to bhop while plugin is enabled");
#endif
}

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

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (!IsValidClient(client) || IsFakeClient(client))
		return Plugin_Continue;

	static Float:LeftGroundMaxSpeed[MAXPLAYERS + 1];

	if(!GetConVarBool(hCvarEnable))
		return Plugin_Continue;

	if (IsPlayerAlive(client)) {
#if defined(L4DBUILD)
		if (GetClientTeam(client) == 3) {
			new class = GetEntProp(client, Prop_Send, "m_zombieClass");
			// tank
			if (class == 8) {
				--class;
			}
			class--;
			new except = GetConVarInt(hCvarSIExcept);
			if (class >= 0 && class <= 6 && ((1 << class) & except)) {
				// Skipping calculation for This SI based on exception rules
				return Plugin_Continue;
			}
		}
		if (GetClientTeam(client) == 2) {
			if (GetConVarBool(hCvarSurvivorExcept)) {
				return Plugin_Continue;
			}
		}
#endif

		new ClientFlags = GetEntityFlags(client);
		if (ClientFlags & FL_ONGROUND) {
			if (LeftGroundMaxSpeed[client] != -1.0) {

				new Float:CurVelVec[3];
				GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", CurVelVec);

				if (GetVectorLength(CurVelVec) > LeftGroundMaxSpeed[client]) {
#if DEBUG
					PrintToChat(client, "Speed: %f {%.02f, %.02f, %.02f}, MaxSpeed: %f", GetVectorLength(CurVelVec), CurVelVec[0], CurVelVec[1], CurVelVec[2], LeftGroundMaxSpeed[client]);
#endif
					NormalizeVector(CurVelVec, CurVelVec);
					ScaleVector(CurVelVec, LeftGroundMaxSpeed[client]);
					TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, CurVelVec);
				}
				LeftGroundMaxSpeed[client] = -1.0;
			}
		} else if (LeftGroundMaxSpeed[client] == -1.0) {
			LeftGroundMaxSpeed[client] = SDKCall(g_hGetRunTopSpeed, client);
		}
	}

	return Plugin_Continue;
} 

stock bool:IsValidClient(client)
{ 
	if (client <= 0 || client > MaxClients || !IsClientConnected(client)) {
		return false; 
	}
	return IsClientInGame(client); 
}
