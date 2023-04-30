#if defined _WeaponHandling_included
#endinput
#endif
#define _WeaponHandling_included

/*
*	A typical example of stacking modifiers from different plugins is ->	speedmodifier = speedmodifier * yourmodifier
*	Example to overwrite modifiers placed before ->							speedmodifier = yourmodifier
*/

enum L4D2WeaponType 
{
	L4D2WeaponType_Unknown = 0,
	L4D2WeaponType_Pistol,
	L4D2WeaponType_Magnum,
	L4D2WeaponType_Rifle,
	L4D2WeaponType_RifleAk47,
	L4D2WeaponType_RifleDesert,
	L4D2WeaponType_RifleM60,
	L4D2WeaponType_RifleSg552,
	L4D2WeaponType_HuntingRifle,
	L4D2WeaponType_SniperAwp,
	L4D2WeaponType_SniperMilitary,
	L4D2WeaponType_SniperScout,
	L4D2WeaponType_SMG,
	L4D2WeaponType_SMGSilenced,
	L4D2WeaponType_SMGMp5,
	L4D2WeaponType_Autoshotgun,
	L4D2WeaponType_AutoshotgunSpas,
	L4D2WeaponType_Pumpshotgun,
	L4D2WeaponType_PumpshotgunChrome,
	L4D2WeaponType_Molotov,
	L4D2WeaponType_Pipebomb,
	L4D2WeaponType_FirstAid,
	L4D2WeaponType_Pills,
	L4D2WeaponType_Gascan,
	L4D2WeaponType_Oxygentank,
	L4D2WeaponType_Propanetank,
	L4D2WeaponType_Vomitjar,
	L4D2WeaponType_Adrenaline,
	L4D2WeaponType_Chainsaw,
	L4D2WeaponType_Defibrilator,
	L4D2WeaponType_GrenadeLauncher,
	L4D2WeaponType_Melee,
	L4D2WeaponType_UpgradeFire,
	L4D2WeaponType_UpgradeExplosive,
	L4D2WeaponType_BoomerClaw,
	L4D2WeaponType_ChargerClaw,
	L4D2WeaponType_HunterClaw,
	L4D2WeaponType_JockeyClaw,
	L4D2WeaponType_SmokerClaw,
	L4D2WeaponType_SpitterClaw,
	L4D2WeaponType_TankClaw,
	L4D2WeaponType_Gnome
}

/*
*	Fires for melee weapons
*	
*	@Param	client			Client Index
*	@Param	weapon			Weapon Index
*	@Param	speedmodifier	Current swing speed modifier, change this to manipulate swing speed e.g. 2.0 = 2x speed
*	
*	@noreturn
*/
forward void WH_OnMeleeSwing(int client, int weapon, float &speedmodifier);

/*
*	Fires for throwables
*	e.g. when about to throw pipebomb 
*	
*	@Param	client			Client Index
*	@Param	weapon			Weapon Index
*	@Param	weapontype		Weapon Type
*	@Param	speedmodifier	Current throw speed modifier, change this to manipulate throw speed e.g. 2.0 = 2x speed
*	
*	@noreturn
*/
forward void WH_OnStartThrow(int client, int weapon, L4D2WeaponType weapontype, float &speedmodifier);

/*
*	Fires for throwables
*	e.g. when winding up to throw pipebomb
*	
*	@Param	client			Client Index
*	@Param	weapon			Weapon Index
*	@Param	weapontype		Weapon Type
*	@Param	speedmodifier	Current windup speed modifier, change this to manipulate windup speed e.g. 2.0 = 2x speed
*	
*	@noreturn
*/
forward void WH_OnReadyingThrow(int client, int weapon, L4D2WeaponType weapontype, float &speedmodifier);

/*
*	@Param	client			Client Index
*	@Param	weapon			Weapon Index
*	@Param	weapontype		Weapon Type
*	@Param	speedmodifier	Current reload speed modifier, change this to manipulate reload speed e.g. 2.0 = 2x speed
*	
*	@noreturn
*/
forward void WH_OnReloadModifier(int client, int weapon, L4D2WeaponType weapontype, float &speedmodifier);

/*
*	
*	@Param	client			Client Index
*	@Param	weapon			Weapon Index
*	@Param	weapontype		Weapon Type
*	@Param	speedmodifier	Current rate of fire speed modifier, change this to manipulate rate of fire e.g. 2.0 = 2x speed
*	
*	@noreturn
*/
forward void WH_OnGetRateOfFire(int client, int weapon, L4D2WeaponType weapontype, float &speedmodifier);

/*
*	Does not trigger for chainsaw, gascan, propane, oxygentank, fireworks and gnome.
*	
*	@Param	client			Client Index
*	@Param	weapon			Weapon Index
*	@Param	weapontype		Weapon Type
*	@Param	speedmodifier	Current deploy speed modifier, change this to manipulate deploy speed e.g. 2.0 = 2x speed
*	
*	@noreturn
*/
forward void WH_OnDeployModifier(int client, int weapon, L4D2WeaponType weapontype, float &speedmodifier);

stock StringMap CreateWeaponClassnameHashMap(StringMap hWeaponClassnameHashMap)
{
	hWeaponClassnameHashMap = CreateTrie();
	hWeaponClassnameHashMap.SetValue("weapon_pistol", L4D2WeaponType_Pistol);
	hWeaponClassnameHashMap.SetValue("weapon_pistol_magnum", L4D2WeaponType_Magnum);
	hWeaponClassnameHashMap.SetValue("weapon_rifle", L4D2WeaponType_Rifle);
	hWeaponClassnameHashMap.SetValue("weapon_rifle_ak47", L4D2WeaponType_RifleAk47);
	hWeaponClassnameHashMap.SetValue("weapon_rifle_desert", L4D2WeaponType_RifleDesert);
	hWeaponClassnameHashMap.SetValue("weapon_rifle_m60", L4D2WeaponType_RifleM60);
	hWeaponClassnameHashMap.SetValue("weapon_rifle_sg552", L4D2WeaponType_RifleSg552);
	hWeaponClassnameHashMap.SetValue("weapon_hunting_rifle", L4D2WeaponType_HuntingRifle);
	hWeaponClassnameHashMap.SetValue("weapon_sniper_awp", L4D2WeaponType_SniperAwp);
	hWeaponClassnameHashMap.SetValue("weapon_sniper_military", L4D2WeaponType_SniperMilitary);
	hWeaponClassnameHashMap.SetValue("weapon_sniper_scout", L4D2WeaponType_SniperScout);
	hWeaponClassnameHashMap.SetValue("weapon_smg", L4D2WeaponType_SMG);
	hWeaponClassnameHashMap.SetValue("weapon_smg_silenced", L4D2WeaponType_SMGSilenced);
	hWeaponClassnameHashMap.SetValue("weapon_smg_mp5", L4D2WeaponType_SMGMp5);
	hWeaponClassnameHashMap.SetValue("weapon_autoshotgun", L4D2WeaponType_Autoshotgun);
	hWeaponClassnameHashMap.SetValue("weapon_shotgun_spas", L4D2WeaponType_AutoshotgunSpas);
	hWeaponClassnameHashMap.SetValue("weapon_pumpshotgun", L4D2WeaponType_Pumpshotgun);
	hWeaponClassnameHashMap.SetValue("weapon_shotgun_chrome", L4D2WeaponType_PumpshotgunChrome);
	hWeaponClassnameHashMap.SetValue("weapon_molotov", L4D2WeaponType_Molotov);
	hWeaponClassnameHashMap.SetValue("weapon_pipe_bomb", L4D2WeaponType_Pipebomb);
	hWeaponClassnameHashMap.SetValue("weapon_first_aid_kit", L4D2WeaponType_FirstAid);
	hWeaponClassnameHashMap.SetValue("weapon_pain_pills", L4D2WeaponType_Pills);
	hWeaponClassnameHashMap.SetValue("weapon_gascan", L4D2WeaponType_Gascan);
	hWeaponClassnameHashMap.SetValue("weapon_oxygentank", L4D2WeaponType_Oxygentank);
	hWeaponClassnameHashMap.SetValue("weapon_propanetank", L4D2WeaponType_Propanetank);
	hWeaponClassnameHashMap.SetValue("weapon_vomitjar", L4D2WeaponType_Vomitjar);
	hWeaponClassnameHashMap.SetValue("weapon_adrenaline", L4D2WeaponType_Adrenaline);
	hWeaponClassnameHashMap.SetValue("weapon_chainsaw", L4D2WeaponType_Chainsaw);
	hWeaponClassnameHashMap.SetValue("weapon_defibrillator", L4D2WeaponType_Defibrilator);
	hWeaponClassnameHashMap.SetValue("weapon_grenade_launcher", L4D2WeaponType_GrenadeLauncher);
	hWeaponClassnameHashMap.SetValue("weapon_melee", L4D2WeaponType_Melee);
	hWeaponClassnameHashMap.SetValue("weapon_upgradepack_incendiary", L4D2WeaponType_UpgradeFire);
	hWeaponClassnameHashMap.SetValue("weapon_upgradepack_explosive", L4D2WeaponType_UpgradeExplosive);
	hWeaponClassnameHashMap.SetValue("weapon_boomer_claw", L4D2WeaponType_BoomerClaw);
	hWeaponClassnameHashMap.SetValue("weapon_charger_claw", L4D2WeaponType_ChargerClaw);
	hWeaponClassnameHashMap.SetValue("weapon_hunter_claw", L4D2WeaponType_HunterClaw);
	hWeaponClassnameHashMap.SetValue("weapon_jockey_claw", L4D2WeaponType_JockeyClaw);
	hWeaponClassnameHashMap.SetValue("weapon_smoker_claw", L4D2WeaponType_SmokerClaw);
	hWeaponClassnameHashMap.SetValue("weapon_spitter_claw", L4D2WeaponType_SpitterClaw);
	hWeaponClassnameHashMap.SetValue("weapon_tank_claw", L4D2WeaponType_TankClaw);
	hWeaponClassnameHashMap.SetValue("weapon_gnome", L4D2WeaponType_Gnome);
	return hWeaponClassnameHashMap;
}

stock L4D2WeaponType GetWeaponTypeFromClassname(const char[] sClassname)
{
	static StringMap hWeaponClassnameHashMap;
	
	if(hWeaponClassnameHashMap == INVALID_HANDLE)
		hWeaponClassnameHashMap = CreateWeaponClassnameHashMap(hWeaponClassnameHashMap);
	
	static L4D2WeaponType WeaponType;
	if(!hWeaponClassnameHashMap.GetValue(sClassname, WeaponType))
		return L4D2WeaponType_Unknown;
	
	return WeaponType;
}


public SharedPlugin __pl_WeaponHandling = 
{
	name = "WeaponHandling",
	file = "WeaponHandling.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_WeaponHandling_SetNTVOptional()
{
	
}
#endif
