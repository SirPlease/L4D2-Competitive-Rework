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

#define NATIVE_EXISTS(%0)   (GetFeatureStatus(FeatureType_Native, %0) == FeatureStatus_Available)
#define UPDATE_URL          "https://raw.githubusercontent.com/J-Tanzanite/Little-Anti-Cheat/master/updatefile.txt"

#define CMD_LENGTH   330

#define GAME_UNKNOWN   0
#define GAME_TF2       1
#define GAME_CSS       2
#define GAME_CSGO      3
#define GAME_DODS      4
#define GAME_L4D2      5
#define GAME_L4D       6

/* In case anyone wants to change this later on in a pull request or whatever,
 * DON'T DON'T DON'T DON'T DON'T DON'T DON'T DON'T DON'T DON'T DON'T!!!
 * ...  DON'T...
 * These values cannot be changed due to forwards,
 *     changing them will cause issues for other plugins.
 * You can add new stuff, but not change the number of anything here. */
#define CHEAT_ANGLES             0
#define CHEAT_CHATCLEAR          1
#define CHEAT_CONVAR             2
#define CHEAT_NOLERP             3
#define CHEAT_BHOP               4
#define CHEAT_AIMBOT             5
#define CHEAT_AIMLOCK            6
#define CHEAT_ANTI_DUCK_DELAY    7
#define CHEAT_NOISEMAKER_SPAM    8
#define CHEAT_MACRO              9 /* Macros aren't actually cheats, but are forwarded as such. */
#define CHEAT_NEWLINE_NAME      10
#define CHEAT_MAX               11

#define CVAR_ENABLE                 0
#define CVAR_WELCOME                1
#define CVAR_SB                     2
#define CVAR_MA                     3
#define CVAR_LOG                    4
#define CVAR_LOG_EXTRA              5
#define CVAR_LOG_MISC               6
#define CVAR_LOG_DATE               7
#define CVAR_BAN                    8
#define CVAR_BAN_LENGTH             9
#define CVAR_BAN_LANGUAGE          10
#define CVAR_CHEAT_WARN            11
#define CVAR_ANGLES                12
#define CVAR_PATCH_ANGLES          13
#define CVAR_CHAT                  14
#define CVAR_CONVAR                15
#define CVAR_NOLERP                16
#define CVAR_BHOP                  17
#define CVAR_AIMBOT                18
#define CVAR_AIMBOT_AUTOSHOOT      19
#define CVAR_AIMLOCK               20
#define CVAR_AIMLOCK_LIGHT         21
#define CVAR_ANTI_DUCK_DELAY       22
#define CVAR_NOISEMAKER_SPAM       23
#define CVAR_BACKTRACK_PATCH       24
#define CVAR_BACKTRACK_TOLERANCE   25
#define CVAR_MAX_PING              26
#define CVAR_MAX_PING_SPEC         27
#define CVAR_MAX_LERP              28
#define CVAR_MACRO                 29
#define CVAR_MACRO_WARNING         30
#define CVAR_MACRO_DEAL_METHOD     31
#define CVAR_MACRO_MODE            32
#define CVAR_FILTER_NAME           33
#define CVAR_FILTER_CHAT           34
#define CVAR_LOSS_FIX              35
#define CVAR_AUTO_UPDATE           36
#define CVAR_SOURCEIRC             37
#define CVAR_DATABASE              38
#define CVAR_MAX                   39

#define BHOP_INDEX_MIN     0
#define BHOP_INDEX_JUMP    1
#define BHOP_INDEX_MAX     2
#define BHOP_INDEX_TOTAL   3
#define BHOP_INDEX_AIR     4
#define BHOP_MAX           5

#define BHOP_MODE_DISABLED     0
#define BHOP_MODE_RESERVED_1   1
#define BHOP_MODE_RESERVED_2   2
#define BHOP_MODE_CUSTOM       3
#define BHOP_MODE_LOW          4
#define BHOP_MODE_MEDIUM       5
#define BHOP_MODE_HIGH         6

#define NOISEMAKER_TYPE_NONE        0
#define NOISEMAKER_TYPE_LIMITED     1
#define NOISEMAKER_TYPE_UNLIMITED   2

#define MACRO_LOG_LENGTH   200

#define MACRO_AUTOJUMP    0
#define MACRO_AUTOSHOOT   1
#define MACRO_ARRAY       2

#define ACTION_SHOT   1

#define QUERY_MAX_FAILURES   24
#define QUERY_TIMEOUT        30
#define QUERY_TIMER          5.0

#define AIMLOCK_BAN_MIN   5

#define AIMBOT_BAN_MIN           5
#define AIMBOT_MAX_TOTAL_DELTA   (180.0 * 2.5)
#define AIMBOT_FLAG_REPEAT       (1 << 0)
#define AIMBOT_FLAG_AUTOSHOOT    (1 << 1)
#define AIMBOT_FLAG_SNAP         (1 << 2)
#define AIMBOT_FLAG_SNAP2        (1 << 3)

#define STRFLAG_NEWLINE          (1 << 0) /* Carriage return or Newline. */
#define STRFLAG_WIDE_CHAR_SPAM   (1 << 1) /* Lots of wide character spam. */

#define DATABASE_BAN 0
#define DATABASE_KICK -1
#define DATABASE_LOG_ONLY -2

#define PLUGIN_NAME      "[Lilac] Little Anti-Cheat"
#define PLUGIN_AUTHOR    "J_Tanzanite"
#define PLUGIN_DESC      "An opensource Anti-Cheat"
#define PLUGIN_VERSION   "1.7.4"
#define PLUGIN_URL       "https://github.com/J-Tanzanite/Little-Anti-Cheat"

/* Convars. */
Convar hcvar[CVAR_MAX]; /* ConVar = built in SourceMod  |  Convar = kidfearless's convar_class */
int icvar[CVAR_MAX];
int sv_cheats = 0;
int time_sv_cheats = 0;
int force_disable_bhop = 0;

/* Banlength overwrite. */
int ban_length_overwrite[CHEAT_MAX];

/* Database. */
Database lil_db;
char sql_buffer[1500]; /* It's probably bigger than what you need, but better be safe than sorry I guess. */
char db_name[64]; /* Database config name from hcvar[CVAR_DATABASE]. */

/* Misc. */
int ggame;
int tick_rate;
int macro_max;
int bhop_settings[BHOP_MAX];
int bhop_settings_min[BHOP_MAX];

char line_buffer[2048];
char dateformat[512] = "%Y/%m/%d %H:%M:%S";
char log_file[PLATFORM_MAX_PATH];
float max_angles[3] = {89.01, 0.0, 50.01};
Handle forwardhandle = INVALID_HANDLE;
Handle forwardhandleban = INVALID_HANDLE;
Handle forwardhandleallow = INVALID_HANDLE;

/* External plugins. */
bool sourcebans_exist = false;
bool sourcebanspp_exist = false;
bool materialadmin_exist = false;

/* Logging.
 * Todo: Might wanna move a lot of this variables to
 * their own files if they are only used there.
 * Just so the code gets a lot cleaner. */
int playerinfo_index[MAXPLAYERS + 1];
int playerinfo_buttons[MAXPLAYERS + 1][CMD_LENGTH];
int playerinfo_actions[MAXPLAYERS + 1][CMD_LENGTH];
int playerinfo_aimlock_sus[MAXPLAYERS + 1];
int playerinfo_aimlock[MAXPLAYERS + 1];
float playerinfo_time_bumpercart[MAXPLAYERS + 1];
float playerinfo_time_teleported[MAXPLAYERS + 1];
float playerinfo_time_aimlock[MAXPLAYERS + 1];
float playerinfo_time_process_aimlock[MAXPLAYERS + 1];
float playerinfo_angles[MAXPLAYERS + 1][CMD_LENGTH][3];
float playerinfo_time_usercmd[MAXPLAYERS + 1][CMD_LENGTH];
float playerinfo_time_forward[MAXPLAYERS + 1][CHEAT_MAX];
bool playerinfo_banned_flags[MAXPLAYERS + 1][CHEAT_MAX];


/* Forward declarations so we don't need third-party include files. */

#define MA_BAN_STEAM  1

native Function IRC_MsgFlaggedChannels(const char[] flag, const char[] format, any:...);
native Function MABanPlayer(int iClient, int iTarget, int iType, int iTime, char[] sReason);
native Function SBBanPlayer(int client, int target, int time, const char[] reason);
native Function SBPP_BanPlayer(int iAdmin, int iTarget, int iTime, const char[] sReason);
native Function Updater_AddPlugin(const char[] url);
native Function Updater_RemovePlugin();