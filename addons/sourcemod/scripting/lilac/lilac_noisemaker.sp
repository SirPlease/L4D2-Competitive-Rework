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

/* Delet dis! */
#if defined TF2C
	#endinput
#endif

static int noisemaker_type[MAXPLAYERS + 1];
static int noisemaker_entity[MAXPLAYERS + 1];
static int noisemaker_entity_prev[MAXPLAYERS + 1];
static int noisemaker_detection[MAXPLAYERS + 1];

void lilac_noisemaker_reset_client(int client)
{
	noisemaker_type[client] = 0;
	noisemaker_entity[client] = 0;
	noisemaker_entity_prev[client] = 0;
	noisemaker_detection[client] = 0;
}

public Action event_inventoryupdate(Event event, const char[] name, bool dontBroadcast)
{
	int client;

	client = GetClientOfUserId(GetEventInt(event, "userid", 0));
	check_inventory_for_noisemaker(client);

	return Plugin_Continue;
}

void check_inventory_for_noisemaker(int client)
{
	char classname[32];
	int type;

	if (!is_player_valid(client))
		return;

	noisemaker_type[client] = NOISEMAKER_TYPE_NONE;
	noisemaker_entity_prev[client] = noisemaker_entity[client];
	noisemaker_entity[client] = 0;

	for (int i = MaxClients + 1; i < GetEntityCount(); i++) {
		if (!IsValidEdict(i))
			continue;

		if (GetEntPropEnt(i, Prop_Data, "m_hOwnerEntity") != client)
			continue;

		GetEntityClassname(i, classname, sizeof(classname));

		if (!StrEqual(classname, "tf_wearable", false))
			continue;

		type = get_entity_noisemaker_type(GetEntProp(i, Prop_Send, "m_iItemDefinitionIndex"));

		if (type) {
			noisemaker_type[client] = type;
			noisemaker_entity[client] = i;
			return;
		}
	}
}

static int get_entity_noisemaker_type(int itemindex)
{
	switch (itemindex) {
	case 280: return NOISEMAKER_TYPE_LIMITED; /* Black cat. */
	case 281: return NOISEMAKER_TYPE_LIMITED; /* Gremlin. */
	case 282: return NOISEMAKER_TYPE_LIMITED; /* Werewolf. */
	case 283: return NOISEMAKER_TYPE_LIMITED; /* Witch. */
	case 284: return NOISEMAKER_TYPE_LIMITED; /* Banshee. */
	case 286: return NOISEMAKER_TYPE_LIMITED; /* Crazy Laugh. */
	case 288: return NOISEMAKER_TYPE_LIMITED; /* Stabby. */
	case 362: return NOISEMAKER_TYPE_LIMITED; /* Bell. */
	case 364: return NOISEMAKER_TYPE_LIMITED; /* Gong. */
	case 365: return NOISEMAKER_TYPE_LIMITED; /* Koto. */
	case 493: return NOISEMAKER_TYPE_LIMITED; /* Fireworks. */
	case 542: return NOISEMAKER_TYPE_LIMITED; /* Vuvuzela. */

	case 536: return NOISEMAKER_TYPE_UNLIMITED; /* Birthday. */
	case 673: return NOISEMAKER_TYPE_UNLIMITED; /* Winter 2011. */
	}

	return NOISEMAKER_TYPE_NONE;
}

public Action OnClientCommandKeyValues(int client, KeyValues kv)
{
	char command[64];
	KvGetSectionName(kv, command, sizeof(command));

	if (ggame != GAME_TF2)
		return Plugin_Continue;

	if (!icvar[CVAR_ENABLE] || !icvar[CVAR_NOISEMAKER_SPAM])
		return Plugin_Continue;

	if (noisemaker_type[client] != NOISEMAKER_TYPE_LIMITED)
		return Plugin_Continue;

	if (noisemaker_entity_prev[client] != noisemaker_entity[client]) {
		noisemaker_entity_prev[client] = noisemaker_entity[client];
		noisemaker_detection[client] = 0;
	}

	if (StrEqual(command, "+use_action_slot_item_server", false)
		|| StrEqual(command, "-use_action_slot_item_server", false)) {

		/* Since this reacts to both + and -,
		 * and the maximum is 25 uses per noisemaker,
		 * detect the double of that + a buffer of 10. */
		if (++noisemaker_detection[client] > 60)
			lilac_detected_noisemaker(client);
	}

	return Plugin_Continue;
}

static void lilac_detected_noisemaker(int client)
{
	if (playerinfo_banned_flags[client][CHEAT_NOISEMAKER_SPAM])
		return;

	if (lilac_forward_allow_cheat_detection(client, CHEAT_NOISEMAKER_SPAM) == false)
		return;

	playerinfo_banned_flags[client][CHEAT_NOISEMAKER_SPAM] = true;

	lilac_forward_client_cheat(client, CHEAT_NOISEMAKER_SPAM);

	if (icvar[CVAR_LOG]) {
		lilac_log_setup_client(client);
		Format(line_buffer, sizeof(line_buffer), "%s is suspected of using unlimited noisemaker cheats.", line_buffer);

		lilac_log(true);

		if (icvar[CVAR_LOG_EXTRA])
			lilac_log_extra(client);
	}
	database_log(client, "noisemaker", DATABASE_LOG_ONLY);

	/* Enable this later if no false positives are reported. */
	/* lilac_ban_client(client, CHEAT_NOISEMAKER_SPAM); */
}
