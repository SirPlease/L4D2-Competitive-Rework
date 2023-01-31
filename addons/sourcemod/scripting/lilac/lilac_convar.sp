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


/* Basic query list. */
static char query_list[][] = {
	"sv_cheats",
	"r_drawothermodels",
	"mat_wireframe",
	"snd_show",
	"snd_visualize",
	"mat_proxy",
	"r_drawmodelstatsoverlay",
	"r_shadowwireframe",
	"r_showenvcubemap",
	"r_drawrenderboxes",
	"r_modelwireframedecal"
};

static int query_index[MAXPLAYERS + 1];
static int query_failed[MAXPLAYERS + 1];

void lilac_convar_reset_client(int client)
{
	query_index[client] = 0;
	query_failed[client] = 0;
}

public Action timer_query(Handle timer)
{
	if (!icvar[CVAR_ENABLE] || !icvar[CVAR_CONVAR])
		return Plugin_Continue;

	/* sv_cheats recently changed or is set to 1, abort. */
	if (GetTime() < time_sv_cheats || sv_cheats)
		return Plugin_Continue;

	for (int i = 1; i <= MaxClients; i++) {
		if (!is_player_valid(i) || IsFakeClient(i))
			continue;

		/* Player recently joined, wait before querying. */
		if (GetClientTime(i) < 60.0)
			continue;

		/* Don't query already banned players. */
		if (playerinfo_banned_flags[i][CHEAT_CONVAR])
			continue;

		/* Only increments query index if the player
		 * has responded to the last one. */
		if (!query_failed[i]) {
			if (++query_index[i] >= 11)
				query_index[i] = 0;
		}

		QueryClientConVar(i, query_list[query_index[i]], query_reply, 0);

		if (++query_failed[i] > QUERY_MAX_FAILURES) {
			if (icvar[CVAR_LOG_MISC]) {
				lilac_log_setup_client(i);
				Format(line_buffer, sizeof(line_buffer),
					"%s was kicked for failing to respond to %d queries in %.0f seconds.",
					line_buffer, QUERY_MAX_FAILURES,
					QUERY_TIMER * QUERY_MAX_FAILURES);

				lilac_log(true);

				if (icvar[CVAR_LOG_EXTRA] == 2)
					lilac_log_extra(i);
			}
			database_log(i, "cvar_query_failure", DATABASE_KICK, float(QUERY_MAX_FAILURES), QUERY_TIMER * QUERY_MAX_FAILURES);

			KickClient(i, "[Lilac] %T", "kick_query_failure", i);
		}
	}

	return Plugin_Continue;
}

public void query_reply(QueryCookie cookie, int client, ConVarQueryResult result,
			const char[] cvarName, const char[] cvarValue, any value)
{
	/* Player NEEDS to answer the query. */
	if (result != ConVarQuery_Okay)
		return;

	/* Client did respond to the query request, move on to the next convar. */
	query_failed[client] = 0;

	/* Any response the server may recieve may also be faulty, ignore. */
	if (GetTime() < time_sv_cheats || sv_cheats)
		return;

	/* Already banned. */
	if (playerinfo_banned_flags[client][CHEAT_CONVAR])
		return;

	int val = StringToInt(cvarValue);

	/* Check for invalid convar responses.
	 * Other than drawothermodels, a value of non-zero is invalid. */
	if (StrEqual("r_drawothermodels", cvarName, false) && val == 1)
		return;
	else if (val == 0)
		return;

	if (lilac_forward_allow_cheat_detection(client, CHEAT_CONVAR) == false)
		return;

	lilac_forward_client_cheat(client, CHEAT_CONVAR);

	if (icvar[CVAR_LOG]) {
		lilac_log_setup_client(client);
		Format(line_buffer, sizeof(line_buffer),
			"%s was detected and banned for an invalid ConVar (%s %s).",
			line_buffer, cvarName, cvarValue);

		lilac_log(true);

		if (icvar[CVAR_LOG_EXTRA])
			lilac_log_extra(client);
	}
	database_log(client, "cvar_invalid", DATABASE_BAN);

	playerinfo_banned_flags[client][CHEAT_CONVAR] = true;
	lilac_ban_client(client, CHEAT_CONVAR);
}
