/*
	SourceMod Anti-Cheat
	Copyright (C) 2011-2016 SMAC Development Team
	Copyright (C) 2007-2011 CodingDirect LLC

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#if defined _smac_included
	#endinput
#endif
#define _smac_included

#include <smac_stocks>

/* Globals */
#define SMAC_VERSION    "0.8.7.3"
#define SMAC_URL        "https://github.com/Silenci0/SMAC"
#define SMAC_AUTHOR     "SMAC Development Team"
#define SMAC_MOD_ERROR  "This module will not work for this mod and should be removed."

enum GameType
{
	Game_Unknown = 0,
	Game_CSS,
	Game_TF2,
	Game_DODS,
	Game_INS,
	Game_L4D,
	Game_L4D2,
	Game_HL2DM,
	Game_FOF,
	Game_HL2CTF,
	Game_HIDDEN,
	Game_ND,
	Game_CSGO,
	Game_ZPS,
	Game_ZMR,
	Game_BM
};

enum DetectionType
{
	Detection_Unknown = 0,

	// smac_aimbot
	Detection_Aimbot = 100,

	// smac_autotrigger
	Detection_AutoTrigger = 200,

	// smac_client
	Detection_NameChangeSpam = 300,

	// smac_commands
	Detection_CommandSpamming = 400,
	Detection_BannedCommand,

	// smac_cvars
	Detection_CvarViolation = 500,

	// smac_eyetest
	Detection_UserCmdReuse = 600,
	Detection_UserCmdTamperingTickcount,
	Detection_UserCmdTamperingButtons,
	Detection_Eyeangles,

	// smac_speedhack
	Detection_Speedhack = 700,

	// smac_spinhack
	Detection_Spinhack = 800,

	// smac_eac_banlist
	Detection_GlobalBanned_EAC = 900,

	// smac_esea_banlist
	Detection_GlobalBanned_ESEA = 1000,

	// smac_hl2dm_fixes
	Detection_GravityGunExploit = 1100,
};

/* Natives */
native GameType SMAC_GetGameType();
native void SMAC_Log(const char[] format, any ...);
native void SMAC_LogAction(int client, const char[] format, any ...);
native void SMAC_Ban(int client, const char[] reason, any ...);
native void SMAC_PrintAdminNotice(const char[] format, any ...);
native ConVar SMAC_CreateConVar(const char[] name, const char[] defaultValue, const char[] description="",int flags = 0, bool hasMin = false, float min = 0.0, bool hasMax = false, float max = 0.0);
native Action SMAC_CheatDetected(int client, DetectionType type = Detection_Unknown, Handle info = INVALID_HANDLE);

/* Forwards */
forward Action SMAC_OnCheatDetected(int client, const char[] module, DetectionType type, Handle info);

public SharedPlugin __pl_smac =
{
	name = "smac",
	file = "smac.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_smac_SetNTVOptional()
{
	MarkNativeAsOptional("SMAC_GetGameType");
	MarkNativeAsOptional("SMAC_Log");
	MarkNativeAsOptional("SMAC_LogAction");
	MarkNativeAsOptional("SMAC_Ban");
	MarkNativeAsOptional("SMAC_PrintAdminNotice");
	MarkNativeAsOptional("SMAC_CreateConVar");
	MarkNativeAsOptional("SMAC_CheatDetected");
}
#endif
