#if defined _l4d2_lagcomp_manager_included
 #endinput
#endif
#define _l4d2_lagcomp_manager_included

enum LagCompensationType
{
	LAG_COMPENSATE_BOUNDS,
	LAG_COMPENSATE_HITBOXES,
	LAG_COMPENSATE_HITBOXES_ALONG_RAY,
};

native void L4D2_LagComp_StartLagCompensation(
	int player,
	LagCompensationType lagCompensationType,
	const float weaponPos[3] = NULL_VECTOR,
	const float weaponAngles[3] = NULL_VECTOR,
	float weaponRange = 0.0 );

native void L4D2_LagComp_FinishLagCompensation(int player);
native void L4D2_LagComp_AddAdditionalEntity(int entity);
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