#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <colors>

#define GAMEDATA "l4d2_si_ability"

#define DURATION_OFFSET 4
#define TIMESTAMP_OFFSET 8

#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

int 
	m_tongueDragDamageTimerDuration,
	m_tongueDragDamageTimerTimeStamp;

ConVar 
	tongue_drag_damage_interval,
	tongue_drag_first_damage_interval,
	tongue_drag_first_damage;

public Plugin myinfo =
{
	name = "L4D2 Smoker Drag Damage Interval",
	author = "Visor, Sir, A1m`",
	description = "Implements a native-like cvar that should've been there out of the box",
	version = "1.0",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	InitGameData();

	HookEvent("tongue_grab", OnTongueGrab);
	
	char value[32];
	ConVar tongue_choke_damage_interval = FindConVar("tongue_choke_damage_interval");
	tongue_choke_damage_interval.GetString(value, sizeof(value));
	
	tongue_drag_damage_interval = CreateConVar("tongue_drag_damage_interval", value, "How often the drag does damage.");
	tongue_drag_first_damage_interval = CreateConVar("tongue_drag_first_damage_interval", "-1.0", "After how many seconds do we apply our first tick of damage? | 0.0 to Disable.");
	tongue_drag_first_damage = CreateConVar("tongue_drag_first_damage", "3.0", "How much damage do we apply on the first tongue hit? | Only applies when first_damage_interval is used");

	ConVar tongue_choke_damage_amount = FindConVar("tongue_choke_damage_amount");
	tongue_choke_damage_amount.AddChangeHook(tongue_choke_damage_amount_ValueChanged);
}

void InitGameData()
{
	Handle hGamedata = LoadGameConfigFile(GAMEDATA);

	if (!hGamedata) {
		SetFailState("Gamedata '%s.txt' missing or corrupt.", GAMEDATA);
	}
	
	int m_tongueDragDamageTimer = GameConfGetOffset(hGamedata, "CTerrorPlayer->m_tongueDragDamageTimer");
	if (m_tongueDragDamageTimer == -1) {
		SetFailState("Failed to get offset 'CTerrorPlayer->m_tongueDragDamageTimer'.");
	}
	
	m_tongueDragDamageTimerDuration = m_tongueDragDamageTimer + DURATION_OFFSET;
	m_tongueDragDamageTimerTimeStamp = m_tongueDragDamageTimer + TIMESTAMP_OFFSET;

	delete hGamedata;
}

public void tongue_choke_damage_amount_ValueChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	SetConVarInt(convar, 1); // hack-hack: game tries to change this cvar for some reason, can't be arsed so HARDCODETHATSHIT
}

public void OnTongueGrab(Event hEvent, const char[] name, bool dontBroadcast)
{
	int userid = hEvent.GetInt("victim");
	int client = GetClientOfUserId(userid);
	float fFirst = tongue_drag_first_damage_interval.FloatValue;

	if (fFirst < 0.0) {
		FixDragInterval(client, userid);
		return;
	}
	
	SetDragDamageInterval(client, tongue_drag_first_damage_interval);
	CreateTimer(fFirst, FirstDamage, userid, TIMER_FLAG_NO_MAPCHANGE);
}

void FixDragInterval(int client, int userid)
{
	SetDragDamageInterval(client, tongue_drag_damage_interval);

	float fTimerUpdate = tongue_drag_damage_interval.FloatValue + 0.1;
	CreateTimer(fTimerUpdate, FixDragIntervalTimer, userid, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action FirstDamage(Handle hTimer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (client > 0 && GetClientTeam(client) == TEAM_SURVIVOR && IsSurvivorBeingDragged(client)) {
		int iAttacker = GetEntPropEnt(client, Prop_Send, "m_tongueOwner");
		if (IsClientInGame(iAttacker) && GetClientTeam(iAttacker) == TEAM_INFECTED) {
			float fDamage = tongue_drag_first_damage.FloatValue - 1.0;
			SDKHooks_TakeDamage(client, iAttacker, iAttacker, fDamage);
		}

		FixDragInterval(client, userid);
		return Plugin_Continue;
	}
	
	return Plugin_Continue;
}

public Action FixDragIntervalTimer(Handle hTimer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (client > 0 && GetClientTeam(client) == TEAM_SURVIVOR && IsSurvivorBeingDragged(client)) {
		SetDragDamageInterval(client, tongue_drag_damage_interval);
		return Plugin_Continue;
	}
	return Plugin_Stop;
}

void SetDragDamageInterval(int client, ConVar hConvar)
{
	float fCvarValue = hConvar.FloatValue;
	float fTimeStamp = GetGameTime() + fCvarValue;
	
	SetEntDataFloat(client, m_tongueDragDamageTimerDuration, fCvarValue); //duration
	SetEntDataFloat(client, m_tongueDragDamageTimerTimeStamp, fTimeStamp); //timestamp
}

bool IsSurvivorBeingDragged(int client)
{
	return ((GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0) && !IsSurvivorBeingChoked(client));
}

bool IsSurvivorBeingChoked(int client)
{
	return (GetEntProp(client, Prop_Send, "m_isHangingFromTongue") > 0);
}
