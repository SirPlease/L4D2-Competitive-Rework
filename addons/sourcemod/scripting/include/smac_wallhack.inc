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
#if defined _smac_wallhack_included
  #endinput
#endif
#define _smac_wallhack_included

/**
 * Sets whether to ignore a client from visibility tests.
 * Processing time for anti-wallhack will decrease with every ignored client.
 *
 * @param client		Client index.
 * @param bIgnore		If true, client will not undergo visibility tests. If false, results in default behavior.
 * @noreturn
 * @error				If the client is not InGame or the index is invalid.
 */
native void SMAC_WH_SetClientIgnore(int client, bool bIgnore);

/**
 * Returns whether a client is ignored from visibility tests.
 *
 * @param client		Client index.
 * @return				True if client is ignored from visibility tests, false otherwise.
 * @error				If the client is not connected or the index is invalid.
 */
native bool SMAC_WH_GetClientIgnore(int client);


public SharedPlugin:__pl_smac_wallhack = 
{
    name = "smac_wallhack",
    file = "smac_wallhack.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_smac_wallhack_SetNTVOptional()
{
    MarkNativeAsOptional("SMAC_WH_SetClientIgnore");
    MarkNativeAsOptional("SMAC_WH_GetClientIgnore");
}
#endif
