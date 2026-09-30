#if defined _l4d_pellet_spread_customizer_included_
	#endinput
#endif
#define _l4d_pellet_spread_customizer_included_

/**
 * @brief Called whenever a weapon is about to fire bullets.
 * @remarks Determine whether the first bullet should be affected by ScatterYaw/Pitch.
 * @remarks Bullet that's affected by ScatterYaw/Pitch is called pellet hereinafter.
 * @note Called in pre-detour of function "CTerrorGun::FireBullet".
 * @note Has no effect if either ScatterYaw/Pitch is not configured for this weapon.
 * 
 * @param weapon		Weapon entity index
 *
 * @return				Plugin_Handled to force the first bullet acting as a pellet,
 * 						Plugin_Continue otherwise.
 */
forward Action L4D_OnPelletFirstBullet(int weapon);

/**
 * @brief Called whenever generating spread values for a pellet.
 * @remarks Spread -> how far from the center, SpreadDir -> circular angle.
 * @remarks By default the actual output for spread is ranged in [-x, x], for angle it is [0, 180].
 * @note Negative values are accepted, for the opposite direction.
 * @note "nMaxPellets" adds 1 if "L4D_OnPelletFirstBullet" returns Plugin_Handled.
 * @note Called in post-detour of function "SharedRandomFloat", the same frame later "L4D_OnPelletFirstBullet".
 * 
 * @param weapon		Weapon entity index
 * @param spread/angle	Spread value
 * @param nPellet		Current pellet number (starting from 1)
 * @param nMaxPellets	Max pellet number
 *
 * @return				Plugin_Changed to change to the exact value,
 * 						Plugin_Continue to leave it randomly generated.
 */
forward Action L4D_OnPelletSpread(int weapon, float &spread, int nPellet, int nMaxPellets);
forward Action L4D_OnPelletSpreadDir(int weapon, float &angle, int nPellet, int nMaxPellets);



public SharedPlugin __pl_l4d_pellet_spread_customizer = 
{
	name = "l4d_pellet_spread_customizer",
	file = "l4d_pellet_spread_customizer.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};
