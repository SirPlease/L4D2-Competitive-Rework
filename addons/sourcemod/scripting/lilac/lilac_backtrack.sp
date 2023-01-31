/*
	Little Anti-Cheat
	Copyright (C) 2018-2023 J_Tanzanite

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

static int prev_tickcount[MAXPLAYERS + 1];
static int diff_tickcount[MAXPLAYERS + 1];
static float time_timeout[MAXPLAYERS + 1];

void lilac_backtrack_reset_client(int client)
{
	prev_tickcount[client] = 0;
	diff_tickcount[client] = 0;
	time_timeout[client] = 0.0;
}

void lilac_backtrack_store_tickcount(int client, int tickcount)
{
	static int tmp[MAXPLAYERS + 1];

	prev_tickcount[client] = tmp[client];
	tmp[client] = tickcount;
}

int lilac_backtrack_patch(int client, int tickcount)
{
	/* Skip players who recently teleported. */
	if (playerinfo_time_teleported[client] + 2.0 > GetGameTime())
		return tickcount;

	if (lilac_valid_tickcount(client, tickcount) == false
		&& lilac_is_player_in_backtrack_timeout(client) == false)
		lilac_set_client_in_backtrack_timeout(client);

	if (lilac_is_player_in_backtrack_timeout(client)
		&& icvar[CVAR_BACKTRACK_PATCH])
		return lilac_lock_tickcount(client);

	return tickcount;
}

static int lilac_lock_tickcount(int client)
{
	int ping, tick;

	ping = RoundToNearest(GetClientAvgLatency(client, NetFlow_Outgoing) / GetTickInterval());
	tick = diff_tickcount[client] + (GetGameTickCount() - ping);

	/* Never return higher than server tickcount.
	 * Other than that, lock the tickcount to the player's
	 * previous value for the durration of the patch.
	 * This patch method shouldn't affect legit laggy players as much. */
	return ((tick > GetGameTickCount()) ? GetGameTickCount() : tick);
}

static bool lilac_valid_tickcount(int client, int tickcount)
{
	return (intabs((prev_tickcount[client] + 1) - tickcount) <= icvar[CVAR_BACKTRACK_TOLERANCE]);
}

static void lilac_set_client_in_backtrack_timeout(int client)
{
	/* Set the player in backtrack timeout for 1.1 seconds. */
	time_timeout[client] = GetGameTime() + 1.1;

	/* Lock value. */
	diff_tickcount[client] = (prev_tickcount[client] - (GetGameTickCount() - RoundToNearest(GetClientAvgLatency(client, NetFlow_Outgoing) / GetTickInterval()))) + 1;

	/* Clamp the value due to floating point errors and network variability. */
	if (diff_tickcount[client] > time_to_ticks(0.2) - 3)
		diff_tickcount[client] = time_to_ticks(0.2) - 3;
	else if (diff_tickcount[client] < ((time_to_ticks(0.2) * -1) + 3))
		diff_tickcount[client] = (time_to_ticks(0.2) * -1) + 3;
}

static bool lilac_is_player_in_backtrack_timeout(int client)
{
	return (GetGameTime() < time_timeout[client]);
}
