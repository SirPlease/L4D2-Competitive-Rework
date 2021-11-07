#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <caster_system>
#define MAX_SPEED 2

new bool:readyUpIsAvailable;

public Plugin:myinfo =
{
    name = "Caster Assister",
    author = "CanadaRox, Sir",
    description = "Allows spectators to control their own specspeed and move vertically",
    version = "2.2",
    url = ""
};

new Float:currentMulti[MAXPLAYERS+1] = { 1.0, ... };
new Float:currentIncrement[MAXPLAYERS+1] = { 0.1, ... };
new Float:verticalIncrement[MAXPLAYERS+1] = { 10.0, ... };

public OnPluginStart()
{
    RegConsoleCmd("sm_set_specspeed_multi", SetSpecspeed_Cmd);
    RegConsoleCmd("sm_set_specspeed_increment", SetSpecspeedIncrement_Cmd);
    RegConsoleCmd("sm_increase_specspeed", IncreaseSpecspeed_Cmd);
    RegConsoleCmd("sm_decrease_specspeed", DecreaseSpecspeed_Cmd);
    RegConsoleCmd("sm_set_vertical_increment", SetVerticalIncrement_Cmd);

    HookEvent("player_team", PlayerTeam_Event);
}

public OnAllPluginsLoaded()
{
    readyUpIsAvailable = LibraryExists("caster_system");
}

public OnLibraryRemoved(const String:name[])
{
    if (StrEqual(name, "caster_system"))
    {
        readyUpIsAvailable = false;
    }
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "caster_system"))
    {
        readyUpIsAvailable = true;
    }
}

public OnClientPutInServer(client)
{
    if (readyUpIsAvailable && IsClientCaster(client))
    {
        FakeClientCommand(client, "sm_spechud");
    }
}

public PlayerTeam_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
    new team = GetEventInt(event, "team");
    if (team == 1)
    {
        new client = GetClientOfUserId(GetEventInt(event, "userid"));
        SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", currentMulti[client]);
    }
}

public Action:SetSpecspeed_Cmd(client, args)
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
    decl String:buffer[10];
    GetCmdArg(1, buffer, sizeof(buffer));
    new Float:newVal = StringToFloat(buffer);
    if (IsSpeedValid(newVal)) {
        SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", newVal);
        currentMulti[client] = newVal;
    }
    return Plugin_Handled;
}

public Action:SetSpecspeedIncrement_Cmd(client, args)
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
    decl String:buffer[10];
    GetCmdArg(1, buffer, sizeof(buffer));
    currentIncrement[client] = StringToFloat(buffer);
    return Plugin_Handled;
}

public Action:IncreaseSpecspeed_Cmd(client, args)
{
    if (GetClientTeam(client) != 1)
    {
        return Plugin_Handled;
    }

    IncreaseSpecspeed(client, currentIncrement[client]);
    return Plugin_Handled;
}

public Action:DecreaseSpecspeed_Cmd(client, args)
{
    if (GetClientTeam(client) != 1)
    {
        return Plugin_Handled;
    }

    IncreaseSpecspeed(client, -currentIncrement[client]);
    return Plugin_Handled;
}

stock IncreaseSpecspeed(client, Float:difference)
{
    new Float:curVal = GetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue");
    if (IsSpeedValid(curVal + difference)) {
        SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", curVal + difference);
        currentMulti[client] = curVal + difference;
    }
}

public Action:SetVerticalIncrement_Cmd(client, args)
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
    decl String:buffer[10];
    GetCmdArg(1, buffer, sizeof(buffer));
    verticalIncrement[client] = StringToFloat(buffer);
    return Plugin_Handled;
}

public Action:OnPlayerRunCmd(client, &buttons)
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
