/*
	This program is free software: you can redistribute it and/or modify it under
	the terms of the GNU General Public License as published by the Free Software
	Foundation, either version 3 of the License, or (at your option) any later
	version.

	This program is distributed in the hope that it will be useful, but WITHOUT ANY
	WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
	PARTICULAR PURPOSE.  See the GNU General Public License for more details.

	You should have received a copy of the GNU General Public License along with
	this program.  If not, see <http://www.gnu.org/licenses/>.

	SourcePawn is Copyright (C) 2006-2008 AlliedModders LLC.  All rights reserved. 
	SourceMod is Copyright (C) 2006-2008 AlliedModders LLC.  All rights reserved. 
	Pawn and SMALL are Copyright (C) 1997-2008 ITB CompuPhase. 
	Source is Copyright (C) Valve Corporation. 

	Valve, the Valve logo, Left 4 Dead, Left 4 Dead 2, Steam, and the Steam
	logo are trademarks and/or registered trademarks of Valve Corporation.
	All other trademarks are property of their respective owners.
*/
/* *
 * =============================================================================
 * lgofnoc.inc 
 * LGOFNOC (C)2011 Confogl Team
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

/**
 * @brief Called when a matchmode has been triggered, before plugins have been
 * 		unloaded/reloaded.
 * @remarks This will fire on the server's "main" plugins, before they are unloaded
 * 
 * @param config  The name of the config being used for the match
 * @noreturn
 */
forward LGO_OnMatchModeStart_PrePlugins(const String:config[]);

/**
 * @brief Called when matchmode is started, after plugins have been loaded,
 * 		but before lgofnoc_once execution or map restart
 * @remarks Just to tell plugins they're about to start a match on a given config
 *
 * @param config  The name of the config being used for the match
 * @noreturn
 */
forward LGO_OnMatchModeStart(const String:config[]);

/**
 * @brief Tells if a lgofnoc match is currently running
 * @remarks Formerly IsPluginEnabled() internally
 * 
 * @return 	True if matchmode is loaded, false otherwise
 */
native bool:LGO_IsMatchModeLoaded();

/**
 * @brief Start matchmode on a given config.
 * @remarks Acts like "sm_forcematch" command, will unload existing match if one is running
 *
 * @param config The name of the config to load for the match
 * @return true if the config was found and matchmode loading starts, false if config not found.
 */
native bool:LGO_StartMatch(const String:config[]);

/**
 * @brief End the current matchmode
 * @remarks Acts like "sm_resetmatch" command.
 *
 * @param restartMap Whether or not to restart the map after unloading matchmode.
 * @noreturn
 */
native LGO_EndMatch(bool:restartMap=true);

/**
 * @brief Build a filepath relative to the current running config.
 * @remarks Should produce a path in cfg/lgofnoc/CONFIG/ or addons/sourcemod/configs/lgofnoc
 * 
 * @param buffer	Buffer to write the path to
 * @param maxlength	Buffer size
 * @param sFileName	Name of the file to look for in the config
 * @noreturn
 */
native LGO_BuildConfigPath(String:buffer[], maxlength, const String:sFileName[]);

/**
 * @brief Execute a cfg file for the current config
 * @remarks Should execute the named .cfg in cfg/ or cfg/lgofnoc/CURRENT_CONFIG/
 * 
 * @param sFileName	Name of the cfg file to execute
 * @noreturn
 */
native LGO_ExecuteConfigCfg(const String:sFileName[]);

/**
 * @brief Tells if map data is available
 * @remarks Map data should be available when any map is loaded, after OnMapStart()
 * 
 * @return 	True if map data is available, false if it is not.
 */
native bool:LGO_IsMapDataAvailable();

/**
 * @brief Get an Int value from the MapInfo keyvalues for the current map with a specific key
 * @remarks Mapinfo keyvalues is used to store static data about maps
 * 
 * @param key		Key to read the value from
 * @param defvalue	Default value to return if key is not found (default 0)
 * @return			Integer value for given key, or defvalue if key is not found
 */
native LGO_GetMapValueInt(const String:key[], const defvalue=0);

/**
 * @brief Get a Float value from the MapInfo keyvalues for the current map with a specific key
 * @remarks Mapinfo keyvalues is used to store static data about maps
 * 
 * @param key		Key to read the value from
 * @param defvalue	Default value to return if key is not found (default 0.0)
 * @return			Float value for given key, or defvalue if key is not found
 */
native Float:LGO_GetMapValueFloat(const String:key[], const Float:defvalue=0.0);

/**
 * @brief Get a Vector from the MapInfo keyvalues for the current map with a specific key
 * @remarks Mapinfo keyvalues is used to store static data about maps
 * 
 * @param key		Key to read the value from
 * @param vector	Vector to store the result in
 * @param defvalue	Default value to use if key is not found (default NULL_VECTOR)
 * @noreturn
 */
native LGO_GetMapValueVector(const String:key[], Float:vector[3], const Float:defvalue[3]=NULL_VECTOR);

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
native LGO_GetMapValueString(const String:key[], String:value[], maxlength, const String:defvalue[]="");

/**
 * @brief Copy a Subsection from the MapInfo keyvalues for the current map
 * @remarks Mapinfo keyvalues is used to store static data about maps
 * 
 * @param kv		KeyValues Handle to copy to
 * @param section	Name of the section to copy
 * @noreturn
 */
native LGO_CopyMapSubsection(Handle:kv, const String:section[]);

public SharedPlugin:__pl_lgofnoc = 
{
	name = "lgofnoc",
	file = "lgofnoc.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};
 
public __pl_lgofnoc_SetNTVOptional()
{
	MarkNativeAsOptional("LGO_IsMatchModeLoaded");
	MarkNativeAsOptional("LGO_StartMatch");
	MarkNativeAsOptional("LGO_EndMatch");
	MarkNativeAsOptional("LGO_BuildConfigPath");
	MarkNativeAsOptional("LGO_ExecuteConfigCfg");
	MarkNativeAsOptional("LGO_IsMapDataAvailable");
	MarkNativeAsOptional("LGO_GetMapValueInt");
	MarkNativeAsOptional("LGO_GetMapValueFloat");
	MarkNativeAsOptional("LGO_GetMapValueVector");
	MarkNativeAsOptional("LGO_GetMapValueString");
	MarkNativeAsOptional("LGO_CopyMapSubsection");	
}

	