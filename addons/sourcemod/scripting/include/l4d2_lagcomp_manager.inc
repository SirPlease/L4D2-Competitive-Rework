#if defined _l4d2_lagcomp_manager_included
 #endinput
#endif
#define _l4d2_lagcomp_manager_included

/**
 * @brief Called whenever CTerrorPlayer::WantsLagCompensationOnEntity(CBaseEntity const*, CUserCmd const*, CBitVec<2048> const*) is invoked
 * @remarks Use along with "L4D2_LagComp_StartLagCompensation" if you find lagcomp doesn't work.
 *
 * @param client			The client that is asked
 * @param entity			The entity that the client checks on
 * @param result			Whether to lag compensate on entity, also the original result from function call
 * @param buttons			The client buttons
 * @param impulse			The client impulse
 *
 * @return					Plugin_Handled to override result, Plugin_Continue otherwise
 */
forward Action L4D2_LagComp_OnWantsLagCompensationOnEntity(int client, int entity, bool &result, int buttons, int impulse);

enum LagCompensationType
{
	LAG_COMPENSATE_BOUNDS,
	LAG_COMPENSATE_HITBOXES,
	LAG_COMPENSATE_HITBOXES_ALONG_RAY,
};

/**
 * @brief Starts built-in lag compensation on players.
 * @remarks Make sure the player is running a command or an error will be thrown.
 * @remarks Lag compensated entities may be changed to different origins, angles, bounds.
 * @remarks Must be paired with "L4D2_LagComp_FinishLagCompensation"
 *
 * @param player				The player to start lag compensation
 * @param lagCompensationType	The type of lag compensation
 * @param weaponPos				Unknown.
 * @param weaponAngles			Unknown.
 * @param weaponRange			Unknown.
 *
 * @noreturn
 */
native void L4D2_LagComp_StartLagCompensation(
	int player,
	LagCompensationType lagCompensationType,
	const float weaponPos[3] = NULL_VECTOR,
	const float weaponAngles[3] = NULL_VECTOR,
	float weaponRange = 0.0 );

/**
 * @brief Finishes built-in lag compensation on players.
 * @remarks Lag compensated entities may be changed to different origins, angles, bounds.
 * @remarks Must be paired with "L4D2_LagComp_StartLagCompensation"
 *
 * @param player				The player to finish lag compensation
 *
 * @noreturn
 */
native void L4D2_LagComp_FinishLagCompensation(int player);

/**
 * @brief Adds entities for lag compensation.
 * @remarks Lag compensated entities may be changed to different origins, angles, bounds.
 *
 * @param entity				The entity to be lag compensated
 *
 * @noreturn
 */
native void L4D2_LagComp_AddAdditionalEntity(int entity);

/**
 * @brief Removes entities from lag compensation.
 * @remarks Lag compensated entities may be changed to different origins, angles, bounds.
 *
 * @param entity				The entity to be lag compensated
 *
 * @noreturn
 */
native void L4D2_LagComp_RemoveAdditionalEntity(int entity);

public SharedPlugin __pl_l4d2_lagcomp_manager =
{
	name = "l4d2_lagcomp_manager",
	file = "l4d2_lagcomp_manager.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_l4d2_lagcomp_manager_SetNTVOptional()
{
	MarkNativeAsOptional("L4D2_LagComp_StartLagCompensation");
	MarkNativeAsOptional("L4D2_LagComp_FinishLagCompensation");
	MarkNativeAsOptional("L4D2_LagComp_AddAdditionalEntity");
	MarkNativeAsOptional("L4D2_LagComp_RemoveAdditionalEntity");
}
#endif