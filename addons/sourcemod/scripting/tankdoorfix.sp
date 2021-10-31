#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define VERSION "2.0"

bool
	bLateLoad,
	tankInPlay;

float
	nextTankPunchAllowed[MAXPLAYERS+1];

int
	tankClassIndex;

ArrayList
	aBreakableDoors;

public Plugin myinfo = 
{
	name = "TankDoorFix",
	author = "PP(R)TH: Dr. Gregory House",
	description = "This should at some point fix the case in which the tank misses the door he's supposed to destroy by using his punch",
	version = VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=225087"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	switch (GetEngineVersion())
	{
		case Engine_Left4Dead: tankClassIndex = 5;
		case Engine_Left4Dead2: tankClassIndex = 8;
		default:
		{
			strcopy(error, err_max, "This plugin only supports L4D(2).");
			return APLRes_SilentFailure;
		}
	}
	
	bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	aBreakableDoors = new ArrayList();
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("tank_spawn", Event_TankSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	
	CreateConVar("tankdoorfix_version", VERSION, "TankDoorFix Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	if (bLateLoad)
	{
		Timer_RoundStart(null);
		Timer_TankInPlayCheck(null);
	}
	
	//RegConsoleCmd("sm_uei", uei);
}

/*public Action uei(int a, int b)
{
	float angles[3];
	GetClientEyeAngles(a, angles);
	GetAngleVectors(angles, angles, NULL_VECTOR, NULL_VECTOR);
	PrintToChat(a, "%.1f %.1f %.1f", angles[0], angles[1], angles[2]);
}*/

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	if (!tankInPlay)
		return;
	
	if (!IsClientInGame(client) || GetClientTeam(client) != 3)
		return;
	
	if (GetEntProp(client, Prop_Send, "m_zombieClass") != tankClassIndex)
		return;
	
	if (!IsPlayerAlive(client))
		return;
	
	if (~buttons & IN_ATTACK)
		return;
	
	int iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (iWeapon == -1)
		return;
	
	float fNow = GetGameTime(), fWeaponIdle = GetEntPropFloat(iWeapon, Prop_Send, "m_flTimeWeaponIdle");
	if (fNow < fWeaponIdle <= fNow + 1.0 && nextTankPunchAllowed[client] <= fNow)
	{
		nextTankPunchAllowed[client] = fNow + 2.0;
		
		static ConVar tank_windup_time = null;
		if (tank_windup_time == null)
			tank_windup_time = FindConVar("tank_windup_time");
		
		CreateTimer(tank_windup_time.FloatValue, Timer_DoorCheck, GetClientUserId(client));
	}
}

public Action Timer_DoorCheck(Handle timer, int clientUserID)
{
	int client = GetClientOfUserId(clientUserID);
	
	if (!client)
		return;
	
	float clientPos[3], doorPos[3];
	GetClientAbsOrigin(client, clientPos);
	
	float minDist = 10000.0;
	
	int door = -1;
	for (int i = 0; i < aBreakableDoors.Length; ++i)
	{
		int ent = EntRefToEntIndex(aBreakableDoors.Get(i));
		if (!IsValidEdict(ent))
		{
			aBreakableDoors.Erase(i--);
			continue;
		}
		
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", doorPos);
		
		float dist = GetVectorDistance(clientPos, doorPos, true);
		if (dist <= minDist)
		{
			minDist = dist;
			door = ent;
		}
	}
	
	if (door == -1)
		return;
	
	static ConVar tank_swing_arc = null;
	if (tank_swing_arc == null)
	{
		tank_swing_arc = FindConVar("tank_swing_arc");
	}
	
	float offs[2];
	GetPlayerAimOffset(client, door, offs);
	
	//PrintToChat(client, "horizon: %f, vertical: %f", offs[0], offs[1]);
	//float ang[3];
	//GetEntPropVector(door, Prop_Send, "m_angRotation", ang);
	//PrintToChat(client, "door rotation: %f, vertical: %f", ang[0], ang[1], ang[2]);
	
	float sqradius = tank_swing_arc.FloatValue * tank_swing_arc.FloatValue * 0.25;
	if (offs[0] * offs[0] <= sqradius && offs[1] * offs[1] <= sqradius)
	{
		//PrintToChat(client, "IsLookingAtBreakableDoor: %i", door);
		SDKHooks_TakeDamage(door, GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"), client, 1200.0, DMG_CLUB);
	}
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	tankInPlay = false;
	CreateTimer(1.0, Timer_RoundStart, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_RoundStart(Handle timer)
{
	int ent = MaxClients+1;
	while ((ent = FindEntityByClassname(ent, "prop_door_rotating")) != INVALID_ENT_REFERENCE)
		aBreakableDoors.Push(EntIndexToEntRef(ent));
}

public void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
	tankInPlay = true;
	nextTankPunchAllowed[GetClientOfUserId(event.GetInt("userid"))] = GetGameTime() + 0.8;
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (client > 0 && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == tankClassIndex)
	{
		CreateTimer(0.1, Timer_TankInPlayCheck);
	}
}

public Action Timer_TankInPlayCheck(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if ( IsClientInGame(i)
		  && GetClientTeam(i) == 3
		  && GetEntProp(i, Prop_Send, "m_zombieClass") == tankClassIndex
		  && IsPlayerAlive(i)
		) {
			tankInPlay = true;
			return;
		}
	}
	tankInPlay = false;
}

// https://github.com/brxce/Gauntlet/blob/834b09b238e67d8f8d4ba52efb822a1baf31bdbc/addons/sourcemod/scripting/AI_HardSI.sp#L215
/**
	Calculates how much a player's aim is off another player
	@return: horizontal and vertical aim offsets in degrees
	@attacker: considers this player's eye angles
	@target: considers this player's position
	Adapted from code written by Guren with help from Javalia
**/
stock void GetPlayerAimOffset( int client, int target, float result[2] ) {
	if( !IsClientInGame(client) || !target || !IsValidEntity(target) )
		return;
	
	bool isTargetClient = (target <= MaxClients) && IsClientInGame(target) && IsPlayerAlive(target);
	
	float clientPos[3], targetPos[3];
	float horizonVector[3], verticalVector[3], directVector[3];
	
	// Get the unit vector representing the player's aim
	GetClientEyeAngles(client, horizonVector);
	verticalVector = horizonVector;
	horizonVector[0] = horizonVector[2] = 0.0; // Restrict pitch and roll, consider yaw only (angles on horizontal plane)
	verticalVector[1] = verticalVector[2] = 0.0; // Restrict yaw and roll, consider pitch only (angles on vertical plane)
	GetAngleVectors(horizonVector, horizonVector, NULL_VECTOR, NULL_VECTOR); // extract the forward vector[3]
	GetAngleVectors(verticalVector, NULL_VECTOR, NULL_VECTOR, verticalVector); // extract the up vector[3]
	NormalizeVector(horizonVector, horizonVector); // convert into unit vector
	NormalizeVector(verticalVector, verticalVector); // convert into unit vector
	
	//PrintToChat(client, "plane: %.1f %.1f %.1f", horizonVector[0], horizonVector[1], horizonVector[2]);
	//PrintToChat(client, "vertical: %.1f %.1f %.1f", verticalVector[0], verticalVector[1], verticalVector[2]);
	
	// Get the unit vector representing the vector between target and player
	isTargetClient ? GetClientAbsOrigin(target, targetPos) : GetEntPropVector(target, Prop_Send, "m_vecOrigin", targetPos); 
	GetClientAbsOrigin(client, clientPos);
	clientPos[2] = targetPos[2] = 0.0; // Restrict to XY coordinates
	MakeVectorFromPoints(clientPos, targetPos, directVector);
	NormalizeVector(directVector, directVector);
	
	// Calculate the angle between the two unit vectors
	result[0] = RadToDeg(ArcCosine(GetVectorDotProduct(horizonVector, directVector)));
	result[1] = 90.0 - RadToDeg(ArcCosine(GetVectorDotProduct(verticalVector, directVector)));
}