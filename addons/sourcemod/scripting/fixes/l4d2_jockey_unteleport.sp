#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <colors>
#define VICTIM_CHECK_INTERVAL 0.1
#define DEBUG 1
#if (DEBUG)
char sLogFile[PLATFORM_MAX_PATH] = "addons/sourcemod/logs/jockey_unteleport.txt";
#endif

enum L4D2Team
{
	L4D2Team_None = 0,
	L4D2Team_Spectator,
	L4D2Team_Survivor,
	L4D2Team_Infected
}

Handle jockeyRideCheck_Timer[MAXPLAYERS];
float victimPrevPos[MAXPLAYERS][3];
int jockeyVictim[MAXPLAYERS];

public Plugin:myinfo =
{
	name = "Jockey Unteleport",
	author = "Krevik, larrybrains",
	description = "Teleports a survivor back into the map if they are randomly teleported outside or inside of the map while jockeyed.",
	version = "2.0",
	url = "kether.pl"
};

public OnPluginStart()
{
	HookEvent("jockey_ride", Event_JockeyRide);
	HookEvent("jockey_ride_end", Event_JockeyRideEnd);
	HookEvent("jockey_killed", Event_JockeyDeath);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
	HookEvent("round_end", Event_RoundEnd);
}

public void OnMapStart()
{
	for(int i =0; i < MAXPLAYERS; i++){
		jockeyRideCheck_Timer[i] = null;
		jockeyVictim[i] = -1;
		victimPrevPos[i][0] = 0.0;
		victimPrevPos[i][1] = 0.0;
		victimPrevPos[i][2] = 0.0;
	}
}

public Action Event_RoundEnd(Event h_Event, const char[] s_Name, bool b_DontBroadcast)
{
	for(int i =0; i < MAXPLAYERS; i++){
		if(jockeyRideCheck_Timer[i] != null)
		delete jockeyRideCheck_Timer[i];
		jockeyVictim[i] = -1;
	}
	return Plugin_Continue;
}

public Action Event_JockeyDeath(Event h_Event, const char[] s_Name, bool b_DontBroadcast)
{
	int jockey = GetClientOfUserId(GetEventInt(h_Event, "userid"));
	delete jockeyRideCheck_Timer[jockey];
	jockeyVictim[jockey] = -1;
	return Plugin_Continue;
}

public Action Event_JockeyRideEnd(Event h_Event, const char[] s_Name, bool b_DontBroadcast)
{
	int jockey = GetClientOfUserId(GetEventInt(h_Event, "userid"));
	delete jockeyRideCheck_Timer[jockey];
	jockeyVictim[jockey] = -1;
	return Plugin_Continue;
}

public Action Event_JockeyRide(Event h_Event, const char[] name, bool dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(h_Event, "victim"));
	int jockey = GetClientOfUserId(GetEventInt(h_Event, "userid"));

	if (IsClientInGame(victim) && GetClientTeam(victim) == 2 && IsPlayerAlive(victim))
	{
		jockeyVictim[jockey] = victim;
		GetClientAbsOrigin(victim, victimPrevPos[victim]);

		if(jockeyRideCheck_Timer[jockey] == null){
			jockeyRideCheck_Timer[jockey] = CreateTimer(VICTIM_CHECK_INTERVAL, CheckVictimPosition_Timer, victim, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	return Plugin_Continue;
}

public void Event_PlayerDeath(Event hEvent, const char[] name, bool dontBroadcast)
{

	static int client, attacker;
	client = GetClientOfUserId(hEvent.GetInt("userid"));
	attacker = GetClientOfUserId(hEvent.GetInt("attacker"));
	if (client != 0) {
		if (client == jockeyVictim[attacker]) {
			jockeyVictim[attacker] = -1;
			delete jockeyRideCheck_Timer[attacker];
		}
	}
}

public void Event_PlayerDisconnect(Event hEvent, const char[] name, bool dontBroadcast)
{

	static int client;
	client = GetClientOfUserId(hEvent.GetInt("userid"));
	if (client != 0) {
		for(int i = 0; i < MAXPLAYERS; i++){
			if (client == jockeyVictim[i]) {
				jockeyVictim[i] = -1;
				delete jockeyRideCheck_Timer[i];
			}
		}
	}
}

public Action CheckVictimPosition_Timer(Handle timer, any victim)
{
	static bool isOutsideWorld;
	static float newVictimPos[3];
	
	if (IsClientInGame(victim) && GetClientTeam(victim) == 2 && IsPlayerAlive(victim))
	{
		GetClientAbsOrigin(victim, newVictimPos);
		isOutsideWorld = TR_PointOutsideWorld(newVictimPos);
		
		if ( !isOutsideWorld && (isPrevPositionEmpty(victim) || (!isPrevPositionEmpty(victim) && planarDistance(victimPrevPos[victim], newVictimPos) < 500.0 )) )
		{
			victimPrevPos[victim] = newVictimPos;
		}
	}
	
	if (IsClientInGame(victim) && GetClientTeam(victim) == 2 && IsPlayerAlive(victim))
	{
		GetClientAbsOrigin(victim, newVictimPos);
		isOutsideWorld = TR_PointOutsideWorld(newVictimPos);
		
		if(isOutsideWorld || (!isPrevPositionEmpty(victim) && planarDistance(victimPrevPos[victim], newVictimPos) > 500.0 )){
			TeleportToPreviousPosition(victim);
		}
	}
	return Plugin_Continue;
}

float planarDistance(float pos1[3], float pos2[3]){
	float distance = GetVectorDistance(pos2,pos1,false);
	//SquareRoot(Pow((FloatAbs(pos2X-pos1X)),2)+Pow((FloatAbs(pos2Z-pos1Z)),2));
	return distance;
}

bool isPrevPositionEmpty(int victim){
	if(victimPrevPos[victim][0] == 0 && victimPrevPos[victim][1] == 0 && victimPrevPos[victim][2] == 0){
		return true;
	}else{
		return false;
	}
}

void TeleportToPreviousPosition(int victim){
	char map[128];
	GetCurrentMap(map,sizeof(map));
	TeleportEntity(victim, victimPrevPos[victim], NULL_VECTOR, NULL_VECTOR);
	CPrintToChatAll("{blue}[虚空猴修复]{default} 传送回了被虚空猴传送的%N.", victim);
	Debug_Print("虚空猴修复log: 当前地图：%s, 将%N传回位置为 %f %f %f", map, victim, victimPrevPos[victim][0], victimPrevPos[victim][1], victimPrevPos[victim][2]);
}

stock void TeleportToNearestSurvivor(int victim)
{
	float distanceToNearestSurv = 1000.0;
	int resultClientIndex = 1;
	for (new i = 1; i <= MaxClients; i++)
	{
			if (IsSurvivor(i) && !IsIncapped(i) && !IsPlayerLedged(i) && i!=victim)
			{
				if (IsPlayerAlive(i))
				{
					float actualSurvivorPosition[3];
					GetClientAbsOrigin(i, actualSurvivorPosition);
					float newDistance = GetVectorDistance(actualSurvivorPosition, victimPrevPos[victim]);
					if(newDistance < distanceToNearestSurv){
						distanceToNearestSurv = newDistance;
						resultClientIndex=i;
					}
				}
			}
	}
	
	float destinationPos[3];
	GetClientAbsOrigin(resultClientIndex, destinationPos);

	if (IsClientInGame(resultClientIndex) && IsPlayerAlive(resultClientIndex))
	{
		TeleportEntity(victim, destinationPos, NULL_VECTOR, NULL_VECTOR);
	}

}

bool:IsSurvivor(client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

bool:IsIncapped(client)
{
	return bool:GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

bool:IsPlayerLedged(client)
{
	return bool:(GetEntProp(client, Prop_Send, "m_isHangingFromLedge") | GetEntProp(client, Prop_Send, "m_isFallingFromLedge"));
}

stock void Debug_Print(char[] format, any ...)
{
	#if (DEBUG)
	{
		char sBuffer[512];
		VFormat(sBuffer, sizeof(sBuffer), format, 2);
		Format(sBuffer, sizeof(sBuffer), "[%s] %s", "DEBUG", sBuffer);
	//	PrintToChatAll(sBuffer);
		PrintToConsoleAll(sBuffer);
		PrintToServer(sBuffer);
		LogToFile(sLogFile, sBuffer);
	}
	#endif
}