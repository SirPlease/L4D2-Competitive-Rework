/*
	Little Anti-Cheat
	Copyright (C) 2018-2021 J_Tanzanite

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

Database lil_db;
char sql_buffer[1500]; // it's probably bigger than what you need, but better be safe than sorry I guess

void Database_OnConfigExecuted()
{
	if (lil_db)
		return;
	char db_name[64];
	GetConVarString(cvar[CVAR_DATABASE], db_name, sizeof(db_name));
	if (db_name[0] == '\0' || IsCharSpace(db_name[0])) // convar is empty
		return;
	if (!SQL_CheckConfig(db_name)) {
		LogError("Database config '%s' doesn't exist in databases.cfg", db_name);
		return;
	}
	Database.Connect(OnDatabaseConnected, db_name);
}

public void OnDatabaseConnected(Database db, const char[] error, any data)
{
	if (!db) {
		LogError("Couldn't connect to the database. Please verify your config.");
		return;
	}
	
	lil_db = db;
	
	if(!SQL_SetCharset(lil_db,"utf8mb4"))
	{
		LogError("Failed to update encoding to utf8mb4: %s", error);
		return;
	}
	
	InitDatabase();
}

void InitDatabase()
{
	// SQLite syntax, but seems valid for MySQL too
	strcopy(sql_buffer, sizeof(sql_buffer), "CREATE TABLE IF NOT EXISTS lilac_detections("
												... "name varchar(128) NOT NULL, " // Honestly, you can deal with less bytes. 32 is fine too, but since you shouldn't have a ton of detections, that should be okay.
												... "steamid varchar(32) NOT NULL, "
												... "ip varchar(16) NOT NULL, "
												... "cheat varchar(50) NOT NULL, "
												... "timestamp INTEGER NOT NULL, "
												... "detection INTEGER NOT NULL, "
												... "pos1 FLOAT NOT NULL, "
												... "pos2 FLOAT NOT NULL, "
												... "pos3 FLOAT NOT NULL, "
												... "ang1 FLOAT NOT NULL, "
												... "ang2 FLOAT NOT NULL, "
												... "ang3 FLOAT NOT NULL, "
												... "map varchar(128) NOT NULL, "
												... "team INTEGER NOT NULL, "
												... "weapon varchar(64) NOT NULL, "
												... "data1 FLOAT NOT NULL, "
												... "data2 FLOAT NOT NULL, "
												... "latency_inc FLOAT NOT NULL, "
												... "latency_out FLOAT NOT NULL, "
												... "loss_inc FLOAT NOT NULL, "
												... "loss_out FLOAT NOT NULL, "
												... "choke_inc FLOAT NOT NULL, "
												... "choke_out FLOAT NOT NULL, "
												... "connection_ticktime FLOAT NOT NULL, "
												... "game_ticktime FLOAT NOT NULL, "
												... "lilac_version varchar(20) NOT NULL)");
	lil_db.Query(OnDatabaseInit, sql_buffer);
}

public void OnDatabaseInit(Database db, DBResultSet results, const char[] error, any data)
{
	if (error[0] != '\0') {
		LogError("Database initation query failed (%s)", error);
		delete lil_db;
	}
}

// Logs a row to the LilAC's database if it exists.
// @param client		Client index.
// @param cheat			Cheat name.
// @param detection		Detection number or sanction: DATABASE_BAN, DATABASE_KICK, DATABASE_LOG_ONLY
// @param data1			Additional data to pass as a float. You can convert integers to float.
// @param data2			Additional data to pass as a float. You can convert integers to float.
void database_log(int client, char[] cheat, int detection=DATABASE_BAN, float data1=0.0, float data2=0.0)
{
	if (!lil_db)
		return;
	
	char steamid[32], ip[16], map[128], weapon[64];
	float pos[3], ang[3];
	
	char name[MAX_NAME_LENGTH];
	if (!GetClientName(client, name, sizeof(name)))
		strcopy(name, sizeof(name), "<no name>");
	else {
		TrimString(name);
		if (strlen(name) >= 128) // prevents exploits: don't exceed 127 characters else some names could break the query
			strcopy(name, sizeof(name), "<no name>");
	}
	
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid), true);
	GetClientIP(client, ip, sizeof(ip), true);

	GetClientAbsOrigin(client, pos);
	GetCurrentMap(map, sizeof(map));
	GetClientWeapon(client, weapon, sizeof(weapon));

	get_player_log_angles(client, 0, true, ang);
	
	lil_db.Format(sql_buffer, sizeof(sql_buffer), "INSERT INTO lilac_detections("
												... "name, "
												... "steamid, "
												... "ip, "
												... "cheat, "
												... "timestamp, "
												... "detection, " // detection '0' means a ban, '-1' means a kick. Everything else is a detection number.
												... "pos1, "
												... "pos2, "
												... "pos3, "
												... "ang1, "
												... "ang2, "
												... "ang3, "
												... "map, "
												... "team, "
												... "weapon, "
												... "data1, "
												... "data2, "
												... "latency_inc, "
												... "latency_out, "
												... "loss_inc, "
												... "loss_out, "
												... "choke_inc, "
												... "choke_out, "
												... "connection_ticktime, "
												... "game_ticktime, "
												... "lilac_version) "
												... "VALUES("
												... "'%s', "
												... "'%s', "
												... "'%s', "
												... "'%s', "
												... "'%i', "
												... "'%i', "
												... "'%.0f', "
												... "'%.0f', "
												... "'%.0f', "
												... "'%.5f', "
												... "'%.5f', "
												... "'%.5f', "
												... "'%s', "
												... "'%i', "
												... "'%s', "
												... "'%f', "
												... "'%f', "
												... "'%f', "
												... "'%f', "
												... "'%f', "
												... "'%f', "
												... "'%f', "
												... "'%f', "
												... "'%f', "
												... "'%f', "
												... "'%s')",
												name,
												steamid,
												ip,
												cheat,
												GetTime(),
												detection,
												pos[0],
												pos[1],
												pos[2],
												ang[0],
												ang[1],
												ang[2],
												map,
												GetClientTeam(client),
												weapon,
												data1,
												data2,
												GetClientAvgLatency(client, NetFlow_Incoming),
												GetClientAvgLatency(client, NetFlow_Outgoing),
												GetClientAvgLoss(client, NetFlow_Incoming),
												GetClientAvgLoss(client, NetFlow_Outgoing),
												GetClientAvgChoke(client, NetFlow_Incoming),
												GetClientAvgChoke(client, NetFlow_Outgoing),
												GetClientTime(client),
												GetGameTime(),
												PLUGIN_VERSION);
	lil_db.Query(OnDetectionInserted, sql_buffer);
}

public void OnDetectionInserted(Database db, DBResultSet results, const char[] error, any data)
{
	if (error[0] != '\0')
		LogError("Detection insertion query failed (%s)", error);
}
