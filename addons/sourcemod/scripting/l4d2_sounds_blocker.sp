/*


L4D2 Sounds Blocker allows you to block any sound of your choice easily.
It also has presets so you can disable all of the annoying sounds without having to add them yourself.
If we added a sound to our presets that you don't want removed--no problem you can easily whitelist it!

''''''''''''''''''''''
'Adding Custom Sounds'
''''''''''''''''''''''

To add a custom sound, simply add the following to your config's .cfg files:

ssb_custom_path "<sound path>"

Example:

ssb_custom_path "player/survivor/swing/Swish_WeaponSwing_Swipe6.wav"

'''''''''''''''''''''
'Whitelisting Sounds'
'''''''''''''''''''''

To whitelist a sound, simply add the folowing to one of your config's .cfg files:

ssb_whitelist_path "<sound path>"

Example:

ssb_whitelist_path "player/survivor/swing/Swish_WeaponSwing_Swipe6.wav"

''''''''
'Notes:'
''''''''
* Please use forward slashes when specifying a sound file path.
* You don't need to put 'sound/' in front of the sound file path. Simply just put <firstfolder>/...
********
NOT ALL SOUNDS WILL BE BLOCKED!!! Some sounds are client-side only, for example gun shots.


*/


#include <sourcemod>
#include <sdktools>

// Convars
new Handle:h_FireWorks = INVALID_HANDLE;
new Handle:h_Coaster = INVALID_HANDLE;
new Handle:h_CarAlarms = INVALID_HANDLE;
new Handle:h_Alarms = INVALID_HANDLE;
new Handle:h_Horde = INVALID_HANDLE;
new Handle:h_MiscVehicles = INVALID_HANDLE;
new Handle:h_Generators = INVALID_HANDLE;
new Handle:h_AmbientExplosions = INVALID_HANDLE;
new Handle:h_Lifts = INVALID_HANDLE;
new Handle:h_Laughs = INVALID_HANDLE;

new String:a_customSoundPaths[255][255];
new String:a_whitelistSoundPaths[255][255];

public Plugin:myinfo =
{
	name = "L4D2 Various Sounds Blocker",
	description = "Blocks out more annoying sounds and allows the option for blocking custom sounds. Designed for NextMod Config.",
	author = "Spoon",
	version = "1.3.1",
	url = "https://github.com/spoon-l4d2/"
};

public OnPluginStart()
{
	h_FireWorks = CreateConVar("ssb_block_fireworks", "1", "Enable/Disable Firework Sound Blocking");
	h_Coaster = CreateConVar("ssb_block_coaster", "1", "Enable/Disable Coaster Sound Blocking");
	h_CarAlarms = CreateConVar("ssb_block_car_alarms", "1", "Enable/Disable Car Alarm Sound Blocking");
	h_Alarms = CreateConVar("ssb_block_alarms", "1", "Enable/Disable Alarm Sound Blocking");
	h_Horde = CreateConVar("ssb_block_horde", "1", "Enable/Disable Horde Sound Blocking");
	h_MiscVehicles = CreateConVar("ssb_block_misc_vehicles", "1", "Enable/Disable Misc Vechile Sound Blocking (I.E Parish Map 4 Tractor, Dead Air Finale Air Plane, Etc.");
	h_Generators = CreateConVar("ssb_block_generators", "1", "Enable/Disable Generator Sound Blocking");
	h_AmbientExplosions = CreateConVar("ssb_block_ambient_explosions", "1", "Enable/Disable Ambient Explosion Sound Blocking");
	h_Lifts = CreateConVar("ssb_block_lifts", "1", "Enable/Disable lift Sound Blocking");
	h_Laughs = CreateConVar("ssb_block_laughs", "1", "Enable/Disable laugh Sound Blocking");
	
	RegServerCmd("ssb_custom_path", CustomPath_Cmd); // Simply put this command in one of your .cfg files along with the custom sound path. Ex: ssb_custom_path "player/survivor/swing/Swish_WeaponSwing_Swipe6"
	RegServerCmd("ssb_whitelist_path", WhitelistPath_Cmd); // Simply put this command in one of your .cfg files along with the custom sound path. Ex: ssb_whitelist_path "player/survivor/swing/Swish_WeaponSwing_Swipe6"
	
	AddNormalSoundHook(OnNormalSound);
	AddAmbientSoundHook(OnAmbientSound);
}

// ------ Whitelist/Custom ------

public Action:WhitelistPath_Cmd(args)
{
	new String:path[255];
	GetCmdArg(1, path, sizeof(path));
	a_whitelistSoundPaths[CountValidItemsInArray(a_whitelistSoundPaths)] = path;
}

public Action:CustomPath_Cmd(args)
{
	new String:path[255];
	GetCmdArg(1, path, sizeof(path));
	a_customSoundPaths[CountValidItemsInArray(a_customSoundPaths)] = path;
}

// ------ Sound Blocking ------

public Action:OnNormalSound(clients[64], &numClients, String:sample[256], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	return checkSound(sample);
}

public Action:OnAmbientSound(String:sample[256], &entity, &Float:volume, &level, &pitch, Float:pos[3], &flags, &Float:delay)
{
	return checkSound(sample);
}

public checkSound(String:sample[256]) {
	new returnValue = 3;
	new freeWilly = true;
	
	// Fireworks
	if (ConVarBoolValue(h_FireWorks)) {
		if (StrContains(sample, "firewerks", true) > -1)
		{
			return checkWhitelist(sample);
		}
	}
	
	// Laughs
	if (ConVarBoolValue(h_Laughs)) {
		if (((StrContains(sample, "laugh", true) > -1) && !(StrContains(sample, "not_a_", true) > -1)))
		{
			return checkWhitelist(sample);
		}
	}
	
	// Coaster
	if (ConVarBoolValue(h_Coaster)) {
		if ((StrContains(sample, "coaster", true) > -1) || (StrContains(sample, "loud/climb_", true) > -1) || (StrContains(sample, "downhill", true) > -1))
		{
			return checkWhitelist(sample);
		}
	}
	
	// Car Alarms
	if (ConVarBoolValue(h_CarAlarms)) {
		if ((StrContains(sample, "car_alarm", true) > -1))
		{
			return checkWhitelist(sample);
		}
	}
	
	// Other Alarms
	if (ConVarBoolValue(h_Alarms)) {
		if ((StrContains(sample, "alarm1", true) > -1) || (StrContains(sample, "rackmove1", true) > -1) || (StrContains(sample, "perimeter_alarm", true) > -1) || (StrContains(sample, "churchbell_begin_loop", true) > -1))
		{
			return checkWhitelist(sample);
		}
	}
	
	// Horde
	if (ConVarBoolValue(h_Horde)) {
		if (StrContains(sample, "mega_mob_incoming", true) > -1)
		{
			return checkWhitelist(sample);
		}
	}
	
	// Misc Vehicles -- There's a lot :D
	if (ConVarBoolValue(h_MiscVehicles)) {
		if ((StrContains(sample, "chainlink_fence_open", true) > -1) || (StrContains(sample, "riverbarge_", true) > -1) || ((StrContains(sample, "van_inside", true) > -1) && !(StrContains(sample, "_start", true))) || (StrContains(sample, "tractor", true) > -1) || (StrContains(sample, "airport_rough_crash", true) > -1) || (StrContains(sample, "fuel_truck", true) > -1) || (StrContains(sample, "c130", true) > -1) || (StrContains(sample, "jet", true) > -1) || (StrContains(sample, "c1_intro_chopper_leave", true) > -1))
		{
			return checkWhitelist(sample);
		}
	}
	
	// Generator
	if (ConVarBoolValue(h_Generators)) {
		if ((StrContains(sample, "generator", true) > -1) && !(StrContains(sample, "_stop", true) > -1) && !(StrContains(sample, "_sputter", true) > -1) && !(StrContains(sample, "nostart_loop", true) > -1))
		{
			return checkWhitelist(sample);
		}
	}
	
	// Ambient Explosions
	if (ConVarBoolValue(h_AmbientExplosions)) {
		if (((StrContains(sample, "explode_", true) > -1) && !(StrContains(sample, "player", true) > -1)) || (StrContains(sample, "timeddebris_", true) > -1) || (StrContains(sample, "timeddebris_", true) > -1) || (StrContains(sample, "bombing_run", true) > -1) || (StrContains(sample, "bridge_destruct_swt_01", true) > -1))
		{
			return checkWhitelist(sample);
		}
	}
	
	// Lifts / Event
	if (ConVarBoolValue(h_Lifts)) {
		if ((StrContains(sample, "c6_bridgelower_seg01", true) > -1) || (StrContains(sample, "garage_lift_loop", true) > -1) || (StrContains(sample, "floodgate", true) > -1))
		{
			return checkWhitelist(sample);
		}
	}
	
	// Custom
	new itemsInArray = CountValidItemsInArray(a_customSoundPaths) + 1;
	if (itemsInArray > 0) {
		for (new i = 0; i < itemsInArray; i++) {
			if (StrContains(sample, ")", false) > -1) {
				ReplaceString(sample, sizeof(sample), ")", "", false);
			}
			if (StrEqual(sample, a_customSoundPaths[i], false)) {
				return checkWhitelist(sample);
			}
		}
	}

	if (freeWilly == true) return 0;
	return returnValue;
}

// ------ Misc Methods ------

public CountValidItemsInArray(String:array[255][255]) {
	new val = 0;
	for (new i = 0; i<sizeof(array); i++){
		if ((StrEqual(array[i], "\0", false)) && (StrEqual(array[i], "", false))) {
			continue;
		} else {
			val = val + 1;
		}
	}
	return val;
}

public checkWhitelist(String:sample[256]){
	new itemsInArray = CountValidItemsInArray(a_whitelistSoundPaths) + 1;	
	if (itemsInArray > 0) {
		for (new i = 0; i < itemsInArray; i++){
			if (StrContains(a_whitelistSoundPaths[i], sample, false) > -1) {
				return 0;
			}
		}
	}
	return 3;
}

public bool:ConVarBoolValue(Handle:cvar) {
	new value = GetConVarInt(cvar);
	if (value == 1) {
		return true;
	} else {
		return false;
	}
}
