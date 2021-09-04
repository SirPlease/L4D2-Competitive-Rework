/* *
 * =============================================================================
 * Confogl.inc 
 * Confogl (C)2011 Confogl Team
 * =============================================================================
 *
 * This file is part of the Confogl competitive L4D2 plugin suite.
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, Confogl Team gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, Confogl Team grants
 * this exception to all derivative works. Confogl defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 */
#if defined _confogl_Included
	#endinput
#endif
#define _confogl_Included

/* Forwards */

/**
 * @brief Called when matchmode is fully loaded, before map restart.
 * @remarks Called just before confogl_plugins.cfg executes
 * 
 * @noreturn
 */
forward void LGO_OnMatchModeLoaded();

/**
 * @brief Called when matchmode is un-loaded, before map restart.
 * @remarks Plugins are unloaded immediately after this call finishes
 * 
 * @noreturn
 */
forward void LGO_OnMatchModeUnloaded();

/* NATIVES */

/**
 * @brief Tells if a confogl match is currently running
 * @remarks Formerly IsPluginEnabled() internally
 * 
 * @return 	True if matchmode is loaded, false otherwise
 */
native bool LGO_IsMatchModeLoaded();

/**
 * @brief Build a filepath relative to the current running config.
 * @remarks Should produce a path in cfg/cfgogl/CONFIG/ or addons/sourcemod/configs/confogl
 * 
 * @param buffer	Buffer to write the path to
 * @param maxlength	Buffer size
 * @param sFileName	Name of the file to look for in the config
 * @noreturn
 */
native void LGO_BuildConfigPath(char[] buffer, int maxlength, const char[] sFileName);

/**
 * @brief Execute a cfg file for the current config
 * @remarks Should execute the named .cfg in cfg/ or cfg/cfgogl/CURRENT_CONFIG/
 * 
 * @param sFileName	Name of the cfg file to execute
 * @noreturn
 */
native void LGO_ExecuteConfigCfg(const char[] sFileName);

/**
 * @brief Tells if map data is available
 * @remarks Map data should be available when any map is loaded, after OnMapStart()
 * 
 * @return 	True if map data is available, false if it is not.
 */
native bool LGO_IsMapDataAvailable();

/**
 * @brief Get an Int value from the MapInfo keyvalues for the current map with a specific key
 * @remarks Mapinfo keyvalues is used to store static data about maps
 * 
 * @param key		Key to read the value from
 * @param defvalue	Default value to return if key is not found (default 0)
 * @return			Integer value for given key, or defvalue if key is not found
 */
native int LGO_GetMapValueInt(const char[] key, const int defvalue = 0);

/**
 * @brief Get a Float value from the MapInfo keyvalues for the current map with a specific key
 * @remarks Mapinfo keyvalues is used to store static data about maps
 * 
 * @param key		Key to read the value from
 * @param defvalue	Default value to return if key is not found (default 0.0)
 * @return			Float value for given key, or defvalue if key is not found
 */
native float LGO_GetMapValueFloat(const char[] key, const float defvalue = 0.0);

/**
 * @brief Get a Vector from the MapInfo keyvalues for the current map with a specific key
 * @remarks Mapinfo keyvalues is used to store static data about maps
 * 
 * @param key		Key to read the value from
 * @param vector	Vector to store the result in
 * @param defvalue	Default value to use if key is not found (default NULL_VECTOR)
 * @noreturn
 */
native void LGO_GetMapValueVector(const char[] key, float vector[3], const float defvalue[3] = NULL_VECTOR);

/**
 * @brief Get a String from the MapInfo keyvalues for the current map with a specific key
 * @remarks Mapinfo keyvalues is used to store static data about maps
 * 
 * @param key		Key to read the value from
 * @param value		String to store the result in
 * @param maxlength Maximum length to write to the value String buffer
 * @param defvalue	Default value to use if key is not found (default "")
 * @noreturn
 */
native void LGO_GetMapValueString(const char[] key, char[] value, int maxlength, const char[] defvalue = "");

/**
 * @brief Copy a Subsection from the MapInfo keyvalues for the current map
 * @remarks Mapinfo keyvalues is used to store static data about maps
 * 
 * @param kv		KeyValues Handle to copy to
 * @param section	Name of the section to copy
 * @noreturn
 */
native void LGO_CopyMapSubsection(KeyValues kv, const char[] section);

public SharedPlugin __pl_confogl = 
{
	name = "confogl",
	file = "confoglcompmod.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_confogl_SetNTVOptional()
{
	MarkNativeAsOptional("LGO_BuildConfigPath");
	MarkNativeAsOptional("LGO_ExecuteConfigCfg");
	MarkNativeAsOptional("LGO_IsMapDataAvailable");
	MarkNativeAsOptional("LGO_GetMapValueInt");
	MarkNativeAsOptional("LGO_GetMapValueFloat");
	MarkNativeAsOptional("LGO_GetMapValueVector");
	MarkNativeAsOptional("LGO_GetMapValueString");
	MarkNativeAsOptional("LGO_CopyMapSubsection");
	MarkNativeAsOptional("LGO_IsMatchModeLoaded");
}
#endif
