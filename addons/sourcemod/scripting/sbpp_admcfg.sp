// *************************************************************************
//  This file is part of SourceBans++.
//
//  Copyright (C) 2014-2016 SourceBans++ Dev Team <https://github.com/sbpp>
//
//  SourceBans++ is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, per version 3 of the License.
//
//  SourceBans++ is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with SourceBans++. If not, see <http://www.gnu.org/licenses/>.
//
//  This file is based off work(s) covered by the following copyright(s):
//
//   SourceMod Admin File Reader Plugin
//   Copyright (C) 2004-2008 AlliedModders LLC
//   Licensed under GNU GPL version 3
//   Page: <http://www.sourcemod.net/>
//
// *************************************************************************

#pragma semicolon 1

#include <sourcemod>

#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 7
public Plugin:myinfo =
#else
public Plugin myinfo =
#endif
{
	name = "SourceBans++: Admin Config Loader",
	author = "AlliedModders LLC, SourceBans++ Dev Team",
	description = "Reads Admin Files",
	version = "1.6.4",
	url = "https://sbpp.github.io"
};


/** Various parsing globals */
#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 7
new bool:g_LoggedFileName = false; /* Whether or not the file name has been logged */
new g_ErrorCount = 0; /* Current error count */
new g_IgnoreLevel = 0; /* Nested ignored section count, so users can screw up files safely */
new g_CurrentLine = 0; /* Current line we're on */
new String:g_Filename[PLATFORM_MAX_PATH]; /* Used for error messages */
#else
bool g_LoggedFileName = false; /* Whether or not the file name has been logged */
int g_ErrorCount = 0; /* Current error count */
int g_IgnoreLevel = 0; /* Nested ignored section count, so users can screw up files safely */
int g_CurrentLine = 0; /* Current line we're on */
char g_Filename[PLATFORM_MAX_PATH]; /* Used for error messages */
#endif

#include "sbpp_admcfg/sbpp_admin_groups.sp"
#include "sbpp_admcfg/sbpp_admin_users.sp"

#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 7
public OnRebuildAdminCache(AdminCachePart:part)
#else
public void OnRebuildAdminCache(AdminCachePart part)
#endif
{
	if (part == AdminCache_Groups) {
		ReadGroups();
	} else if (part == AdminCache_Admins) {
		ReadUsers();
	}
}

#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 7
ParseError(const String:format[], any:...)
#else
void ParseError(const char[] format, any...)
#endif
{
	#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 7
	decl String:buffer[512];
	#else
	char buffer[512];
	#endif

	if (!g_LoggedFileName)
	{
		LogError("Error(s) Detected Parsing %s", g_Filename);
		g_LoggedFileName = true;
	}

	VFormat(buffer, sizeof(buffer), format, 2);

	LogError(" (line %d) %s", g_CurrentLine, buffer);

	g_ErrorCount++;
}

void InitGlobalStates()
{
	g_ErrorCount = 0;
	g_IgnoreLevel = 0;
	g_CurrentLine = 0;
	g_LoggedFileName = false;
}
