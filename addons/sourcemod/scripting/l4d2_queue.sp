#include <sourcemod>
#include <readyup>
#include <left4dhooks>

#define L4D2_TEAM_SURVIVOR 2
#define L4D2_TEAM_INFECTED 3

public Plugin myinfo =
{
	name = "L4D2 - Queue",
	author = "Altair Sossai",
	description = "Arranges players in a queue, showing who are the next players who should play",
	version = "1.0.0",
	url = "https://github.com/altair-sossai/l4d2-zone-server"
};

ArrayList queue;

public void OnPluginStart()
{
	queue = CreateArray(64);

	RegConsoleCmd("sm_fila", PrintQueueCmd);
}

public Action PrintQueueCmd(int client, int args)
{
	PrintQueue(client);

	return Plugin_Handled;
}

public OnClientPutInServer(int client)
{
	AddToQueue(client);
}

public void OnClientDisconnect_Post(int client)
{
	RemoveFromQueue(client);
}

public void OnRoundIsLive()
{
    MovePlayersToTheEndOfTheQueue();
}

public void L4D2_OnEndVersusModeRound_Post()
{
	MovePlayersToTheEndOfTheQueue();
	PrintQueue(0);
}

void MovePlayersToTheEndOfTheQueue()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || IsFakeClient(client))
			continue;

		int index = queue.FindValue(client);
		if (index == -1)
		{
			queue.Push(client);
			continue;
		}

		int team = GetClientTeam(client);
		if (team == L4D2_TEAM_SURVIVOR || team == L4D2_TEAM_INFECTED)
		{
			queue.Erase(index);
			queue.Push(client);
		}
	}
}

void AddToQueue(int client)
{
	if (!IsClientInGame(client) || IsFakeClient(client) || queue.FindValue(client) != -1)
		return;

	queue.Push(client);
}

void RemoveFromQueue(int client)
{
	int index = queue.FindValue(client);
	if (index == -1)
		return;

	queue.Erase(index);
}

void PrintQueue(int client)
{
	if (queue.Length == 0)
		return;

	char output[1024];

	for (int i = 0, position = 1; i < queue.Length; i++)
	{
		int currentClient = queue.Get(i);

		if (!IsClientInGame(currentClient) || IsFakeClient(currentClient))
			continue;

		int team = GetClientTeam(currentClient);
		if (team == L4D2_TEAM_SURVIVOR || team == L4D2_TEAM_INFECTED)
			continue;

		if (position == 1)
			FormatEx(output, sizeof(output), "\x04Fila: \x03%dº \x01%N", position, currentClient);
		else
			Format(output, sizeof(output), "%s\x01, \x03%dº \x01%N", output, position, currentClient);

		position++
	}

	if (client == 0)
		PrintToChatAll(output);
	else
		PrintToChat(client, output);
}