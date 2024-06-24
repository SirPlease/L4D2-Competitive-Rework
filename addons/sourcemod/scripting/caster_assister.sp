#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <caster_system>
#define MAX_SPEED 2

bool readyUpIsAvailable;

public Plugin myinfo =
{
    name = "Caster Assister",
    author = "CanadaRox, Sir",
    description = "Allows spectators to control their own specspeed and move vertically",
    version = "2.2",
    url = ""
};

float currentMulti[MAXPLAYERS+1] = { 1.0, ... };
float currentIncrement[MAXPLAYERS+1] = { 0.1, ... };
float verticalIncrement[MAXPLAYERS+1] = { 10.0, ... };

public void OnPluginStart()
{
    RegConsoleCmd("sm_set_specspeed_multi", SetSpecspeed_Cmd);
    RegConsoleCmd("sm_set_specspeed_increment", SetSpecspeedIncrement_Cmd);
    RegConsoleCmd("sm_increase_specspeed", IncreaseSpecspeed_Cmd);
    RegConsoleCmd("sm_decrease_specspeed", DecreaseSpecspeed_Cmd);
    RegConsoleCmd("sm_set_vertical_increment", SetVerticalIncrement_Cmd);

    HookEvent("player_team", PlayerTeam_Event);
}

public void OnAllPluginsLoaded()
{
    readyUpIsAvailable = LibraryExists("caster_system");
}

public void OnLibraryRemoved(const char[] name)
{
    if (StrEqual(name, "caster_system"))
    {
        readyUpIsAvailable = false;
    }
}

public void OnLibraryAdded(const char[] name)
{
    if (StrEqual(name, "caster_system"))
    {
        readyUpIsAvailable = true;
    }
}

public void OnClientPutInServer(int client)
{
    if (readyUpIsAvailable && IsClientCaster(client))
    {
        FakeClientCommand(client, "sm_spechud");
    }
}

void PlayerTeam_Event(Event event, const char[] name, bool dontBroadcast)
{
    int team = event.GetInt("team");
    if (team == 1)
    {
        int client = GetClientOfUserId(event.GetInt("userid"));
        SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", currentMulti[client]);
    }
}

Action SetSpecspeed_Cmd(int client, int args)
{
    if (GetClientTeam(client) != 1)
    {
        return Plugin_Handled;
    }

    if (args != 1)
    {
        ReplyToCommand(client, "Usage: sm_set_specspeed_multi # (default: 1.0)");
        return Plugin_Handled;
    }
    char buffer[10];
    GetCmdArg(1, buffer, sizeof(buffer));
    float newVal = StringToFloat(buffer);
    if (IsSpeedValid(newVal)) {
        SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", newVal);
        currentMulti[client] = newVal;
    }
    return Plugin_Handled;
}

Action SetSpecspeedIncrement_Cmd(int client, int args)
{
    if (GetClientTeam(client) != 1)
    {
        return Plugin_Handled;
    }

    if (args != 1)
    {
        ReplyToCommand(client, "Usage: sm_set_specspeed_increment # (default: 0.1)");
        return Plugin_Handled;
    }
    char buffer[10];
    GetCmdArg(1, buffer, sizeof(buffer));
    currentIncrement[client] = StringToFloat(buffer);
    return Plugin_Handled;
}

Action IncreaseSpecspeed_Cmd(int client, int args)
{
    if (GetClientTeam(client) != 1)
    {
        return Plugin_Handled;
    }

    IncreaseSpecspeed(client, currentIncrement[client]);
    return Plugin_Handled;
}

Action DecreaseSpecspeed_Cmd(int client, int args)
{
    if (GetClientTeam(client) != 1)
    {
        return Plugin_Handled;
    }

    IncreaseSpecspeed(client, -currentIncrement[client]);
    return Plugin_Handled;
}

stock void IncreaseSpecspeed(int client, float difference)
{
    float curVal = GetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue");
    if (IsSpeedValid(curVal + difference)) {
        SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", curVal + difference);
        currentMulti[client] = curVal + difference;
    }
}

Action SetVerticalIncrement_Cmd(int client, int args)
{
    if (GetClientTeam(client) != 1)
    {
        return Plugin_Handled;
    }

    if (args != 1)
    {
        ReplyToCommand(client, "Usage: sm_set_vertical_increment # (default: 10.0)");
        return Plugin_Handled;
    }
    char buffer[10];
    GetCmdArg(1, buffer, sizeof(buffer));
    verticalIncrement[client] = StringToFloat(buffer);
    return Plugin_Handled;
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	if (IsValidClient(client) && GetClientTeam(client) == 1)
	{
		if (buttons & IN_USE)
		{
			MoveUp(client, verticalIncrement[client]);
		}
		else if (buttons & IN_RELOAD)
		{
			MoveUp(client, -verticalIncrement[client]);
		}
	}

	return Plugin_Continue;
}

bool IsSpeedValid(float speed)
{
	return (speed >= 0 && speed <= MAX_SPEED);
}

void MoveUp(int client, float distance)
{
	float origin[3];
	GetClientAbsOrigin(client, origin);
	origin[2] += distance;
	TeleportEntity(client, origin, NULL_VECTOR, NULL_VECTOR);
}

bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client));
}
