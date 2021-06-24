#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "Simple Anti-Bunnyhop",
	author = "CanadaRox, ProdigySim, blodia, CircleSquared, robex",
	description = "Stops bunnyhops by restricting speed when a player lands a perfect bhop",
	version = "1.0",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};


#define DEBUG 0

#define MIN_JUMP_TIME 0.500

new Handle:hCvarEnable;
new Handle:hCvarSIExcept;
new Handle:hCvarSurvivorExcept;
new Handle:hCvarConsecutiveHopsSI;

int consecutiveBhops = 0;

public OnPluginStart()
{
	hCvarEnable = CreateConVar("simple_antibhop_enable", "1", "Enable or disable the Simple Anti-Bhop plugin");
	hCvarSIExcept = CreateConVar("bhop_except_si_flags", "0", "Bitfield for exempting SI in anti-bhop functionality. From least significant: Smoker, Boomer, Hunter, Spitter, Jockey, Charger, Tank");
	hCvarSurvivorExcept = CreateConVar("bhop_allow_survivor", "0", "Allow Survivors to bhop while plugin is enabled");
	hCvarConsecutiveHopsSI = CreateConVar("bhop_consecutive_hops_si", "0", "How many consecutive bhops to allow for non-exempt SI");
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (!IsValidClient(client) || IsFakeClient(client))
		return Plugin_Continue;

	if (!GetConVarBool(hCvarEnable))
		return Plugin_Continue;

	if (!IsPlayerAlive(client))
		return Plugin_Continue;

	if (GetClientTeam(client) == 3) {
		new class = GetEntProp(client, Prop_Send, "m_zombieClass");
		// tank is class 8 but we want to make it 7 to match bitfield
		if (class == 8) {
			class--;
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

	static int iPrevButtons[MAXPLAYERS + 1];
	static float fCheckTime[MAXPLAYERS + 1];

	bool bhopDetected = false;
	new ClientFlags = GetEntityFlags(client);

	if (!(buttons & IN_JUMP) && (ClientFlags & FL_ONGROUND) && fCheckTime[client] > 0.0) {
		fCheckTime[client] = 0.0;
	}

	if ((buttons & IN_JUMP) && !(iPrevButtons[client] & IN_JUMP)) {
		if (ClientFlags & FL_ONGROUND) {
			float fGameTime = GetGameTime();

			if (fCheckTime[client] > 0.0 && fGameTime > fCheckTime[client]) {
				consecutiveBhops++;
#if DEBUG
				PrintToChat(client, "Bhop detected, consecutive hops: %d", consecutiveBhops);
#endif
				bhopDetected = true;
			} else {
				consecutiveBhops = 0;
				fCheckTime[client] = fGameTime + MIN_JUMP_TIME;
			}
		} else {
			consecutiveBhops = 0;
			fCheckTime[client] = 0.0;
		}
	}

	iPrevButtons[client] = buttons;

	int allowedConsecHops = GetConVarInt(hCvarConsecutiveHopsSI);
	if (bhopDetected && consecutiveBhops > allowedConsecHops) {
		float CurVelVec[3];
		float maxSpeed = GetEntPropFloat(client, Prop_Data, "m_flMaxspeed");

		GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", CurVelVec);

		if (GetVectorLength(CurVelVec) > maxSpeed) {
#if DEBUG
			PrintToChat(client, "Speed: %f {%.02f, %.02f, %.02f}, MaxSpeed: %f", GetVectorLength(CurVelVec), CurVelVec[0], CurVelVec[1], CurVelVec[2], maxSpeed);
#endif
			NormalizeVector(CurVelVec, CurVelVec);
			ScaleVector(CurVelVec, maxSpeed);
			SetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", CurVelVec);
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
