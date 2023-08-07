#include <sourcemod>

#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

#define DEFAULT_COUNT 3
#define MIN_COUNT 3
#define MAX_COUNT 5

#define DEFAULT_INTERVAL 850.0
#define MIN_INTERVAL 250.0
#define MAX_INTERVAL 2000.0

int counts[2];

public Plugin:myinfo = 
{
	name = "[L4D2] Countdown",
	author = "Altair Sossai",
	description = "Allows players to create a countdown in chat",
	version = "1.0",
	url = "https://github.com/altair-sossai/l4d2-zone-server"
}

public OnPluginStart()
{
    RegConsoleCmd("sm_countdown", CountdownCmd);
}

public Action CountdownCmd(int client, int args)
{
    int team = GetClientTeam(client);
    int index = team - 2;

    if (!IsValidTeam(team) || counts[index] > 0)
        return Plugin_Handled;

    int count = DEFAULT_COUNT;
    float interval = DEFAULT_INTERVAL;

    if (args >= 1)
    {
        char countArg[32];
        GetCmdArg(1, countArg, sizeof(countArg));
        count = StringToInt(countArg)
    }

    if (args >= 2)
    {
        char intervalArg[32];
        GetCmdArg(2, intervalArg, sizeof(intervalArg));
        interval = StringToFloat(intervalArg)
    }

    if (!IsValidCount(count) || !IsValidInterval(interval))
    {
        PrintToChat(client, "\x04Usage:\x01 !countdown \x04<count> <interval>");
        PrintToChat(client, "\x04<count>:\x01 between %d - %d", MIN_COUNT, MAX_COUNT);
        PrintToChat(client, "\x04<interval>:\x01 between %.0f - %.0f", MIN_INTERVAL, MAX_INTERVAL);
        return Plugin_Handled;
    }

    counts[index] = count;
    
    PrintStart(team, client);
    CreateTimer(interval / 1000.0, CountdownTimer, team, TIMER_REPEAT);

    return Plugin_Handled;
}

public Action CountdownTimer(Handle timer, int team)
{
    int index = team - 2;
    int count = counts[index];

    if (count < 0)
        return Plugin_Stop;

    PrintCount(team, count);
    
    counts[index] = count - 1;

    return Plugin_Continue;
}

stock void PrintStart(int team, int requester)
{
    char name[64];  
    GetClientName(requester, name, sizeof(name));

    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) != team)
            continue;

        PrintToChat(client, "\x04%s\x01 started a countdown!", name);
    }
}

stock void PrintCount(int team, int count)
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) != team)
            continue;

        if (count == 0)
            PrintToChat(client, "\x04NOW!!!");
        else
            PrintToChat(client, "\x01%d...", count);
    }
}

stock bool IsValidCount(int count)
{
    return count >= MIN_COUNT && count <= MAX_COUNT;
}

stock bool IsValidInterval(float interval)
{
    return interval >= MIN_INTERVAL && interval <= MAX_INTERVAL;
}

stock bool IsValidTeam(int team)
{
    return team == TEAM_SURVIVOR || team == TEAM_INFECTED;
}