//Weapon Skin Enabler
//Version: 1
//https://github.com/Derpduck/L4D2-Comp-Stripper-Rework

printl("\nWeapon Skin Enabler Initialized\n")

function InitializeSkins()
{
	//Classnames for weapon types to reskin
	//Select which entity types will be reskinned, using order above
	g_ReskinItems <- array(1,			"weapon_melee_spawn")
	g_ReskinItemsEnabled <- array(1,	true)
	g_ReskinItems.append(				"weapon_melee")
	g_ReskinItemsEnabled.append(		true)
	g_ReskinItems.append(				"weapon_spawn")
	g_ReskinItemsEnabled.append(		true)
	g_ReskinItems.append(				"weapon_pistol_magnum_spawn")
	g_ReskinItemsEnabled.append(		true)
	
	//Index weapons to apply skins to
	g_WeaponSkinModels <- array(1, null) //Weapon models to search for
	g_WeaponSkinEnabled <- array(1, null) //Enable skin changing for this weapon
	g_WeaponSkinChance <- array(1, null) //Chance of applying a skin out of 100
	g_WeaponSkinCount <- array(1, null) //Number of weapons to reskin per model, -1 = all
	g_WeaponSkinRange <- array(1, null) //Number of skins available to choose from for the model, 0 = Only use base skin

	//Crowbar
	g_WeaponSkinModels.append("models/weapons/melee/w_crowbar.mdl")
	g_WeaponSkinEnabled.append(true)
	g_WeaponSkinChance.append(5)
	g_WeaponSkinCount.append(1)
	g_WeaponSkinRange.append(1)
	//Cricket Bat
	g_WeaponSkinModels.append("models/weapons/melee/w_cricket_bat.mdl")
	g_WeaponSkinEnabled.append(true)
	g_WeaponSkinChance.append(5)
	g_WeaponSkinCount.append(1)
	g_WeaponSkinRange.append(1)
	//Magnum Pistol
	g_WeaponSkinModels.append("models/w_models/weapons/w_desert_eagle.mdl")
	g_WeaponSkinEnabled.append(true)
	g_WeaponSkinChance.append(5)
	g_WeaponSkinCount.append(1)
	g_WeaponSkinRange.append(2)

	//Remove null values at 0 index
	g_WeaponSkinModels.remove(0)
	g_WeaponSkinEnabled.remove(0)
	g_WeaponSkinChance.remove(0)
	g_WeaponSkinCount.remove(0)
	g_WeaponSkinRange.remove(0)
}


//TODO: Optimize array usage
//Prevent ApplyWeaponSkins from picking the same weapon more than once if count is greater than 1
//Allow custom range of skin values to be used

//Index all weapon spawns of classname on the map and apply re-skins
function SetWeaponSkins()
{
	local weaponArray = array(1, null)
	
	//Index weapon spawns of valid models
	for (local items = 0; items < g_ReskinItems.len(); items++)
	{
		if (g_ReskinItemsEnabled[items] == true)
		{
			local weaponSpawns = null;
			while (weaponSpawns = Entities.FindByClassname(weaponSpawns, g_ReskinItems[items]))
			{
				//Check if the weapon model is on the list of re-skinnable weapons
				local weaponModel = weaponSpawns.GetModelName();
				
				//Check each weapon model to reskin in order
				for (local i = 0; i < g_WeaponSkinModels.len(); i++)
				{
					local weaponIndex = g_WeaponSkinModels.find(weaponModel)
					//Found a valid weapon
					if (weaponIndex == i)
					{
						//Add weapon to list
						weaponArray.append(weaponSpawns)
						
						if (developer() > 0)
						{
							printl("Found: " + weaponModel + " at: " + weaponSpawns.GetOrigin() + " // ID: " + weaponSpawns)
						}
					}
				}
			}
		}
	}
	
	//Go through newly indexed weapons and apply a skin to them by model
	weaponArray.remove(0)
	for (local iModel = 0; iModel < g_WeaponSkinModels.len(); iModel++)
	{
		//Filter array to only weapons of the current model
		local currentWeapon = weaponArray.filter(function(index, value, model = g_WeaponSkinModels[iModel])
		{
			return (value.GetModelName() == model);
		})
		
		//If weapons of this type exist on the map, apply skins
		if (currentWeapon.len() > 0)
		{
			if (developer() > 0)
			{
				printl("Applying skins to weapon: " + g_WeaponSkinModels[iModel])
			}
			
			//Determine number of weapons to reskin
			local applyCount = g_WeaponSkinCount[iModel]
			if (applyCount == -1)
			{
				for (local iCount = 0; iCount < currentWeapon.len(); iCount++)
				{
					//Determine chance to spawn
					if (GetWeaponSkinChance(iModel) == true)
					{
						//Weapon rolled to change skin
						ApplyWeaponSkins(currentWeapon, iCount, iModel)
					}
				}
			}
			else
			{
				//Pick a random weapon to apply a skin to, up to the count provided 
				for (local iCount = 0; iCount < applyCount; iCount++)
				{
					//Determine chance to spawn
					if (GetWeaponSkinChance(iModel) == true)
					{
						//Weapon rolled to change skin
						ApplyWeaponSkins(currentWeapon, RandomInt(0, currentWeapon.len()-1), iModel)
					}
				}
			}
		}
	}
}

//Roll RNG to see if a weapon skin will spawn for given model
function GetWeaponSkinChance(i)
{
	local changeSkin = false
	
	//Roll number between 1 and chance given
	local skinRoll = RandomInt(1, 100)
	
	//Value landed on the chance, allow that weapon to be re-skinned
	if (skinRoll <= g_WeaponSkinChance[i])
	{
		changeSkin = true
	}
	else
	{
		changeSkin = false
	}
	
	if (developer() > 0)
	{
		printl("Weapon: " + g_WeaponSkinModels[i] + " // Chance: " + g_WeaponSkinChance[i] + " // Rolled: " + skinRoll + " // Result: " + changeSkin)
	}
	
	return changeSkin;
}

//Apply weapon skins to item spawns
function ApplyWeaponSkins(currentWeapon, i, iModel)
{
	//Pick random skin within range
	local randomSkin = 0
	if (g_WeaponSkinRange[iModel] != 0)
	{
		randomSkin = RandomInt(1, g_WeaponSkinRange[iModel])
	}
	
	//Apply skin
	NetProps.SetPropInt(currentWeapon[i], "m_nSkin", randomSkin)
	NetProps.SetPropInt(currentWeapon[i], "m_nWeaponSkin", randomSkin)
	
	if (developer() > 0)
	{
		printl("Re-skinned weapon at: " + currentWeapon[i].GetOrigin() + " with skin: " + randomSkin)
	}
}

//Remove skins from all weapons of classname
function RemoveWeaponSkins()
{
	//Go through list of weapons we can apply skins to and set them to default
	for (local items = 0; items < g_ReskinItems.len(); items++)
	{
		if (g_ReskinItemsEnabled[items] == true)
		{
			local weaponSpawns = null;
			while (weaponSpawns = Entities.FindByClassname(weaponSpawns, g_ReskinItems[items]))
			{
				//Found weapon, remove skin
				NetProps.SetPropInt(weaponSpawns, "m_nSkin", 0)
				NetProps.SetPropInt(weaponSpawns, "m_nWeaponSkin", 0)
			}
		}
	}
}


//Run script
InitializeSkins()
SetWeaponSkins()