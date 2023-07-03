#include <sourcemod>
#include <readyup>
#include <left4dhooks>

#define L4D2_TEAM_SURVIVOR 2
#define L4D2_TEAM_INFECTED 3

ArrayList queue;

public Plugin myinfo =
{
	name = "L4D2 - Queue",
	author = "Altair Sossai",
	description = "Arranges players in a queue, showing who are the next players who should play",
	version = "1.0.0",
	url = "https://github.com/altair-sossai/l4d2-zone-server"
};

public void OnPluginStart()
{
	queue = new ArrayList(ByteCountToCells(64));

	RegConsoleCmd("sm_fila", PrintQueueCmd);
}

public Action PrintQueueCmd(int client, int args)
{
	PrintQueue(client);

	return Plugin_Handled;
}

public void OnClientPutInServer(int client)
{
	Enqueue(client);
}

public void OnRoundIsLive()
{
	RequeuePlayers();
}

public void L4D2_OnEndVersusModeRound_Post(int client)
{
	UnqueueAllDisconnected();
	RequeuePlayers();
	PrintQueue(0);
}

void Enqueue(int client)
{
	if (!IsClientInGame(client) || IsFakeClient(client))
		return;

	char steamId[64];
	GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));

	if (strlen(steamId) == 0 || strcmp(steamId, "BOT") == 0)
		return;

	int index = queue.FindString(steamId);
	if (index != -1)
		return;

	queue.PushString(steamId);
}

void RequeuePlayers()
{
	char steamId[64];

	for (int i = 0; i < queue.Length; )
	{
		queue.GetString(i, steamId, sizeof(steamId));

		int client = GetClientUsingSteamId(steamId);
		if (client == -1)
		{
			i++;
			continue;
		}

		int team = GetClientTeam(client);
		if (team != L4D2_TEAM_SURVIVOR && team != L4D2_TEAM_INFECTED)
		{
			i++;
			continue;
		}

		queue.Erase(i);
	}

	for (int client = 1; client <= MaxClients; client++) 
		Enqueue(client);
}

void UnqueueAllDisconnected()
{
	char steamId[64];

	for (int i = 0; i < queue.Length; )
	{
		queue.GetString(i, steamId, sizeof(steamId));

		if (GetClientUsingSteamId(steamId) != -1)
		{
			i++;
			continue;
		}

		queue.Erase(i);
	}
}

int GetClientUsingSteamId(const char[] steamId) 
{
    char current[64];
   
    for (int client = 1; client <= MaxClients; client++) 
    {
        if (!IsClientInGame(client) || IsFakeClient(client))
            continue;
        
        GetClientAuthId(client, AuthId_Steam2, current, sizeof(current));     
        
        if (strcmp(steamId, current) == 0)
            return client;
    }
    
    return -1;
}

void PrintQueue(int target)
{
	if (queue.Length == 0)
		return;

	char output[1024];
	char steamId[64];

	for (int i = 0, position = 1; i < queue.Length; i++)
	{
		queue.GetString(i, steamId, sizeof(steamId));

		int client = GetClientUsingSteamId(steamId);
		if (client == -1)
			continue;

		int team = GetClientTeam(client);
		if (team == L4D2_TEAM_SURVIVOR || team == L4D2_TEAM_INFECTED)
			continue;

		if (position == 1)
			FormatEx(output, sizeof(output), "\x04Fila: \x03%dº \x01%N", position, client);
		else
			Format(output, sizeof(output), "%s\x01, \x03%dº \x01%N", output, position, client);

		position++;
	}

	if (target == 0)
		PrintToChatAll(output);
	else
		PrintToChat(target, output);
}