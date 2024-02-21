#if defined _smrespawn_included_
  #endinput
#endif
#define _smrespawn_included_

enum // team overrides
{
	SPAWN_IN_TEAM_DEFAULT = -1,		// Respawns player in his current team. If he is spectator, the survivor team is selected by default.
	SPAWN_IN_TEAM_SURVIVOR = 2,		// Respawns player in survivor team.
	SPAWN_IN_TEAM_INFECTED = 3		// Respawns player in infected team.
}

enum SPAWN_POSITION
{
	SPAWN_POSITION_ORIGIN 		= 1,	// Teleports player to client's origin. If client's origin is impossible to calculate (e.g. dead or index == 0),
										// it uses any other client's origin from the same team.
	SPAWN_POSITION_CROSSHAIR 	= 2,	// Teleports player at client's crosshair
	SPAWN_POSITION_VECTOR 		= 4,	// Teleports player to the provided vector.
	SPAWN_POSITION_SAFEROOM		= 8,	// Teleports player to the saferoom.
	SPAWN_POSITION_CONVAR 		= 16,	// Position is based on "l4d_sm_respawn_position" ConVar.
	
	SPAWN_POSITION_TAKEOVER_BOT 				= 32,	// Takeover a free (or his own) bot instead of respawning, if possible. Otherwise, the player will be respawned normally.
	SPAWN_POSITION_TELEPORT_EVEN_IF_TAKEOVER 	= 64	// Teleport player to the specified position even if respawn happened as a takeover bot.
}

/**
 * Respawns the player.
 *
 * @param iTarget			Target who you want to respawn.
 * @param iClient			(optional) Specify it if e.g. you want to respawn target at this client's crosshair or origin.
 * @param eOverridePosition	(optional) Specify it to use a specific teleport rule - see enum "SPAWN_POSITION".
 * @param iOverrideTeam		(optional) Specify it to force assigning player to a specific team. Default value is SPAWN_IN_TEAM_DEFAULT (-1).
 * @param vOrigin[3]		(optional) Position where you want target to be spawned. Applicable with SPAWN_POSITION_VECTOR flag only.
  *
 * @error					Wrong number of arguments.
 * @return					true, if target is successfully respawned.
 */
native int SM_Respawn(
	int iTarget,
	int iClient = 0,
	SPAWN_POSITION eOverridePosition = SPAWN_POSITION_CONVAR,
	int iOverrideTeam = SPAWN_IN_TEAM_DEFAULT,
	float vOrigin[3] = {0.0, 0.0, 0.0});

public SharedPlugin __pl_smrespawn =
{
	name = "[L4D & L4D2] SM Respawn",
	file = "l4d_sm_respawn.smx",
	#if defined REQUIRE_PLUGIN
	required = 1
	#else
	required = 0
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_smrespawn_SetNTVOptional()
{
	MarkNativeAsOptional("SM_Respawn");
}
#endif
