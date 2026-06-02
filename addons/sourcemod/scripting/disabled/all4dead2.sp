/*
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.	If not, see <http://www.gnu.org/licenses/>.
*/

/*
All4Dead - A modification for the game Left4Dead
Copyright 2009 James Richardson
Copyright 2020 Harry Potter
*/

#pragma semicolon 1
#pragma newdecls required

// Define constants
#define PLUGIN_NAME					"All4Dead"
#define PLUGIN_TAG					"[A4D]"
#define PLUGIN_VERSION				"3.4"
#define MENU_DISPLAY_TIME		15

// Include necessary files
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
// Make the admin menu optional
#undef REQUIRE_PLUGIN
#include <adminmenu>
// Make the left4dhooks optional
#include <left4dhooks>

// Create ConVar Handles
ConVar notify_players, zombies_increment, always_force_bosses, refresh_zombie_location = null;
ConVar director_force_tank, director_force_witch, director_panic_forever, sb_all_bot_team,
	z_mega_mob_size, z_mob_spawn_max_size, z_mob_spawn_min_size;

// Menu handlers
TopMenu top_menu;
TopMenu admin_menu;
TopMenuObject spawn_special_infected_menu;
TopMenuObject spawn_uncommon_infected_menu;
TopMenuObject spawn_weapons_menu;
TopMenuObject spawn_melee_weapons_menu;
TopMenuObject spawn_items_menu;
TopMenuObject director_menu;
TopMenuObject config_menu;

// Other stuff
bool currently_spawning = false;
char change_zombie_model_to[128] = "";
float last_zombie_spawn_location[3];
Handle refresh_timer = null;
int last_zombie_spawned = 0;
bool automatic_placement = true;
bool g_bSpawnWitchBride;

// Global variables to hold menu position
int g_iSpecialInfectedMenuPosition[MAXPLAYERS+1];
int g_iUInfectedMenuPosition[MAXPLAYERS+1];
int g_iItemMenuPosition[MAXPLAYERS+1];
int g_iWeaponMenuPosition[MAXPLAYERS+1];
int g_iMeleeMenuPosition[MAXPLAYERS+1];

#define ZOMBIESPAWN_Attempts 6

#define	MAX_WEAPONS2		29
static char g_sWeaponModels2[MAX_WEAPONS2][] =
{
	"models/w_models/weapons/w_pistol_B.mdl",
	"models/w_models/weapons/w_desert_eagle.mdl",
	"models/w_models/weapons/w_rifle_m16a2.mdl",
	"models/w_models/weapons/w_rifle_ak47.mdl",
	"models/w_models/weapons/w_rifle_sg552.mdl",
	"models/w_models/weapons/w_desert_rifle.mdl",
	"models/w_models/weapons/w_autoshot_m4super.mdl",
	"models/w_models/weapons/w_shotgun_spas.mdl",
	"models/w_models/weapons/w_shotgun.mdl",
	"models/w_models/weapons/w_pumpshotgun_A.mdl",
	"models/w_models/weapons/w_smg_uzi.mdl",
	"models/w_models/weapons/w_smg_a.mdl",
	"models/w_models/weapons/w_smg_mp5.mdl",
	"models/w_models/weapons/w_sniper_mini14.mdl",
	"models/w_models/weapons/w_sniper_awp.mdl",
	"models/w_models/weapons/w_sniper_military.mdl",
	"models/w_models/weapons/w_sniper_scout.mdl",
	"models/w_models/weapons/w_m60.mdl",
	"models/w_models/weapons/w_grenade_launcher.mdl",
	"models/weapons/melee/w_chainsaw.mdl",
	"models/w_models/weapons/w_eq_molotov.mdl",
	"models/w_models/weapons/w_eq_pipebomb.mdl",
	"models/w_models/weapons/w_eq_bile_flask.mdl",
	"models/w_models/weapons/w_eq_painpills.mdl",
	"models/w_models/weapons/w_eq_adrenaline.mdl",
	"models/w_models/weapons/w_eq_Medkit.mdl",
	"models/w_models/weapons/w_eq_defibrillator.mdl",
	"models/w_models/weapons/w_eq_explosive_ammopack.mdl",
	"models/w_models/weapons/w_eq_incendiary_ammopack.mdl",
};

#define MODEL_COLA			"models/w_models/weapons/w_cola.mdl"
#define MODEL_GNOME			"models/props_junk/gnome.mdl"

// Infected models
#define MODEL_SMOKER "models/infected/smoker.mdl"
#define MODEL_BOOMER "models/infected/boomer.mdl"
#define MODEL_HUNTER "models/infected/hunter.mdl"
#define MODEL_SPITTER "models/infected/spitter.mdl"
#define MODEL_JOCKEY "models/infected/jockey.mdl"
#define MODEL_CHARGER "models/infected/charger.mdl"
#define MODEL_TANK "models/infected/hulk.mdl"

// Signature call
static Handle hCreateSmoker = null;
#define NAME_CreateSmoker "NextBotCreatePlayerBot<Smoker>"
static Handle hCreateBoomer = null;
#define NAME_CreateBoomer "NextBotCreatePlayerBot<Boomer>"
static Handle hCreateHunter = null;
#define NAME_CreateHunter "NextBotCreatePlayerBot<Hunter>"
static Handle hCreateSpitter = null;
#define NAME_CreateSpitter "NextBotCreatePlayerBot<Spitter>"
static Handle hCreateJockey = null;
#define NAME_CreateJockey "NextBotCreatePlayerBot<Jockey>"
static Handle hCreateCharger = null;
#define NAME_CreateCharger "NextBotCreatePlayerBot<Charger>"
static Handle hCreateTank = null;
#define NAME_CreateTank "NextBotCreatePlayerBot<Tank>"

/// Metadata for the mod - used by SourceMod
public Plugin myinfo = {
	name = PLUGIN_NAME,
	author = "James Richardson (grandwazir) & HarryPotter",
	description = "Enables admins to have control over the AI Director and spawn all weapons, melee, items, special infected, and Uncommon Infected without using sv_cheats 1",
	version = PLUGIN_VERSION,
	url = "https://github.com/fbef0102/L4D2-Plugins/tree/master/all4dead2"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	EngineVersion test = GetEngineVersion();
	
	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	
	return APLRes_Success; 
}

/// Create plugin Convars, register all our commands and hook any events we need. View the generated all4dead.cfg file for a list of generated Convars.
public void OnPluginStart() {
	GetGameData();

	director_force_tank = FindConVar("director_force_tank");
	director_force_witch = FindConVar("director_force_witch");
	director_panic_forever = FindConVar("director_panic_forever");
	sb_all_bot_team = FindConVar("sb_all_bot_team");
	z_mega_mob_size = FindConVar("z_mega_mob_size");
	z_mob_spawn_max_size = FindConVar("z_mob_spawn_max_size");
	z_mob_spawn_min_size = FindConVar("z_mob_spawn_min_size");
	
	always_force_bosses = CreateConVar("a4d_always_force_bosses", "0", "Whether or not bosses will be forced to spawn all the time.", FCVAR_NOTIFY);
	notify_players = CreateConVar("a4d_notify_players", "1", "Whether or not we announce changes in game.", FCVAR_NOTIFY);	
	zombies_increment = CreateConVar("a4d_zombies_to_add", "10", "The amount of zombies to add when an admin requests more zombies.", FCVAR_NOTIFY, true, 10.0, true, 100.0);
	refresh_zombie_location = CreateConVar("a4d_refresh_zombie_location", "20.0", "The amount of time in seconds between location refreshes. Used only for placing uncommon infected automatically.", FCVAR_NOTIFY, true, 5.0, true, 30.0);
	// Register all spawning commands
	RegAdminCmd("a4d_spawn_infected", Command_SpawnInfected, ADMFLAG_ROOT);
	RegAdminCmd("a4d_spawn_uinfected", Command_SpawnUInfected, ADMFLAG_ROOT);
	RegAdminCmd("a4d_spawn_item", Command_SpawnItem, ADMFLAG_ROOT);
	RegAdminCmd("a4d_spawn_weapon", Command_SpawnItem, ADMFLAG_ROOT);
	// Director commands
	RegAdminCmd("a4d_force_panic", Command_ForcePanic, ADMFLAG_ROOT);
	RegAdminCmd("a4d_panic_forever", Command_PanicForever, ADMFLAG_ROOT);	
	RegAdminCmd("a4d_force_tank", Command_ForceTank, ADMFLAG_ROOT);
	RegAdminCmd("a4d_force_witch", Command_ForceWitch, ADMFLAG_ROOT);
	RegAdminCmd("a4d_continuous_bosses", Command_AlwaysForceBosses, ADMFLAG_ROOT);
	RegAdminCmd("a4d_add_zombies", Command_AddZombies, ADMFLAG_ROOT);	
	// Config settings
	RegAdminCmd("a4d_enable_notifications", Command_EnableNotifications, ADMFLAG_ROOT);
	RegAdminCmd("a4d_reset_to_defaults", Command_ResetToDefaults, ADMFLAG_ROOT);
	// RegAdminCmd("a4d_debug_teleport", Command_TeleportToZombieSpawn, ADMFLAG_CHEATS);
	// Hook events
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("tank_spawn", Event_BossSpawn, EventHookMode_PostNoCopy);
	HookEvent("witch_spawn", Event_BossSpawn, EventHookMode_PostNoCopy);

	// Create location refresh timer
	refresh_timer = CreateTimer(refresh_zombie_location.FloatValue, Timer_RefreshLocation, _, TIMER_REPEAT);
	// If the Admin menu has been loaded start adding stuff to it
	if (LibraryExists("adminmenu") && ((top_menu = GetAdminTopMenu()) != null))
		OnAdminMenuReady(top_menu);

	//AutoExecConfig(true, "all4dead2");	
}

public void OnMapStart() {
	// Precache uncommon infected models
	PrecacheModel("models/infected/common_male_riot.mdl", true);
	PrecacheModel("models/infected/common_male_ceda.mdl", true);
	PrecacheModel("models/infected/common_male_clown.mdl", true);
	PrecacheModel("models/infected/common_male_mud.mdl", true);
	PrecacheModel("models/infected/common_male_roadcrew.mdl", true);
	PrecacheModel("models/infected/common_male_jimmy.mdl", true);
	PrecacheModel("models/infected/common_male_fallen_survivor.mdl", true);
	
	PrecacheModel(MODEL_SMOKER);
	PrecacheModel(MODEL_BOOMER);
	PrecacheModel(MODEL_HUNTER);
	PrecacheModel(MODEL_SPITTER);
	PrecacheModel(MODEL_JOCKEY);
	PrecacheModel(MODEL_CHARGER);
	PrecacheModel(MODEL_TANK);

	int max = MAX_WEAPONS2;
	for( int i = 0; i < max; i++ )
	{
		PrecacheModel(g_sWeaponModels2[i], true);
	}

	PrecacheModel(MODEL_GNOME, true);
	PrecacheModel(MODEL_COLA, true);
	
	char mapbuf[32];
	GetCurrentMap(mapbuf, sizeof(mapbuf));	
	if(strcmp(mapbuf, "c6m1_riverbank") == 0)
		g_bSpawnWitchBride = true;
	else
		g_bSpawnWitchBride = false;
}

public void OnPluginEnd() {
	CloseHandle(refresh_timer);
}

/**
 * <summary>
 * 	Fired when a player is spawned and gives that player maximum health. This	
 * 	is to fix an issue where entities created through z_spawn have random amount 
 * 	of health
 * </summary>
 * <remarks>
 * 	This callback will only affect players on the infected team. It also only 
 * 	occurs when the global currently_spawning is true. It automatically resets
 * 	currently_spawning to false once the health has been given.
 * </remarks>
 * <seealso>
 * 	Command_SpawnInfected
 * </seealso>
*/
public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	/* If something spawns and we have just requested something to spawn - assume it is the same thing and make sure it has max health */
	if (GetClientTeam(client) == 3 && currently_spawning) {
		StripAndExecuteClientCommand(client, "give", "health");
		LogAction(0, -1, "[NOTICE] Given full health to client %L that (hopefully) was spawned by A4D.", client);
		// We have added health to the thing we have spawned so turn ourselves off
		currently_spawning = false;	
	}
}
/**
 * <summary>
 * 	Fired when a boss has been spawned (witch or tank) and sets director_force_tank/
 * 	director_force_witch to false if necessary.
 * </summary>
 * <remarks>
 * 	Forcing the director to spawn bosses is the most natural way for them to enter
 * 	the game. However the game does not toggle these ConVars off once a boss has 
 * 	been spawned. This leads to odd behavior such as four tanks on one map. This callback
 * 	ensures that if a4d_continuous_bosses is false we set the relevent director ConVar back
 * 	to false once the boss has been spawned.
 * </remarks>
 * <seealso>
 * 	Command_ForceTank
 * 	Command_ForceWitch
 * 	Command_SpawnBossesContinuously
 * </seealso>
*/
public void Event_BossSpawn(Event event, const char[] name, bool dontBroadcast) {
	if (always_force_bosses.BoolValue == false)
		if (strcmp(name, "tank_spawn") == 0 && director_force_tank.BoolValue)
			Do_ForceTank(0, false);
		else if (strcmp(name, "witch_spawn") == 0 && director_force_witch.BoolValue)
			Do_ForceWitch(0, false);
}

/// Register our menus with SourceMod
public void OnAdminMenuReady(Handle menu) {
	// Stop this method being called twice
	if (menu == admin_menu)
		return;
	admin_menu = view_as<TopMenu>(menu);
	// Add a category to the SourceMod menu called "All4Dead Commands"
	AddToTopMenu(admin_menu, "All4Dead Commands", TopMenuObject_Category, Menu_CategoryHandler, INVALID_TOPMENUOBJECT);
	// Get a handle for the catagory we just added so we can add items to it
	TopMenuObject a4d_menu = FindTopMenuCategory(admin_menu, "All4Dead Commands");
	// Don't attempt to add items to the category if for some reason the catagory doesn't exist
	if (a4d_menu == INVALID_TOPMENUOBJECT) 
		return;
	// The order that items are added to menus has no relation to the order that they appear. Items are sorted alphabetically automatically.
	// Assign the menus to global values so we can easily check what a menu is when it is chosen.
	director_menu = AddToTopMenu(admin_menu, "a4d_director_menu", TopMenuObject_Item, Menu_TopItemHandler, a4d_menu, "a4d_director_menu", ADMFLAG_ROOT);
	config_menu = AddToTopMenu(admin_menu, "a4d_config_menu", TopMenuObject_Item, Menu_TopItemHandler, a4d_menu, "a4d_config_menu", ADMFLAG_ROOT);
	spawn_special_infected_menu = AddToTopMenu(admin_menu, "a4d_spawn_special_infected_menu", TopMenuObject_Item, Menu_TopItemHandler, a4d_menu, "a4d_spawn_special_infected_menu", ADMFLAG_ROOT);
	spawn_melee_weapons_menu = AddToTopMenu(admin_menu, "a4d_spawn_melee_weapons_menu", TopMenuObject_Item, Menu_TopItemHandler, a4d_menu, "a4d_spawn_melee_weapons_menu", ADMFLAG_ROOT);
	spawn_weapons_menu = AddToTopMenu(admin_menu, "a4d_spawn_weapons_menu", TopMenuObject_Item, Menu_TopItemHandler, a4d_menu, "a4d_spawn_weapons_menu", ADMFLAG_ROOT);
	spawn_items_menu = AddToTopMenu(admin_menu, "a4d_spawn_items_menu", TopMenuObject_Item, Menu_TopItemHandler, a4d_menu, "a4d_spawn_items_menu", ADMFLAG_ROOT);
	spawn_uncommon_infected_menu = AddToTopMenu(admin_menu, "a4d_spawn_uncommon_infected_menu", TopMenuObject_Item, Menu_TopItemHandler, a4d_menu, "a4d_spawn_uncommon_infected_menu", ADMFLAG_ROOT);
}

public void OnEntityCreated(int entity, const char[] classname) {
	// If the last thing that was spawned as a zombie then store that entity
	// for future use
	if (strcmp(classname, "infected", false) == 0) {
		last_zombie_spawned = entity;
		if (currently_spawning && strcmp(change_zombie_model_to, "") != 0) {
			currently_spawning = false;
			SetEntityModel(entity, change_zombie_model_to);
			change_zombie_model_to = "";
		}
	}	
}

public Action Timer_RefreshLocation(Handle timer) {
	if (!IsValidEntity(last_zombie_spawned) || !IsValidEdict(last_zombie_spawned)) return Plugin_Continue;
	char class_name[128];
	GetEdictClassname(last_zombie_spawned, class_name, 128);
	if (strcmp(class_name, "infected") != 0) return Plugin_Continue;
	GetEntityAbsOrigin(last_zombie_spawned, last_zombie_spawn_location);
	return Plugin_Continue;
}


public Action Timer_TeleportZombie(Handle timer, any entity) {
	TeleportEntity(entity, last_zombie_spawn_location, NULL_VECTOR, NULL_VECTOR);
	// PrintToChatAll("Zombie being teleported to int location");

	return Plugin_Continue;
}

/// Handles the top level "All4Dead" category and how it is displayed on the core admin menu
public int Menu_CategoryHandler(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int client, char[] buffer, int maxlength) {
	if (action == TopMenuAction_DisplayTitle)
		Format(buffer, maxlength, "All4Dead Commands:");
	else if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "All4Dead Commands");

	return 0;
}
/// Handles what happens someone opens the "All4Dead" category from the menu.
public int Menu_TopItemHandler(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int client, char[] buffer, int maxlength) {
/* When an item is displayed to a player tell the menu to Format the item */
	if (action == TopMenuAction_DisplayOption) {
		if (object_id == director_menu)
			Format(buffer, maxlength, "Director Commands");
		else if (object_id == spawn_special_infected_menu)
			Format(buffer, maxlength, "Spawn Special Infected");
		else if (object_id == spawn_uncommon_infected_menu)
			Format(buffer, maxlength, "Spawn Uncommon Infected");
		else if (object_id == spawn_melee_weapons_menu)
			Format(buffer, maxlength, "Spawn Melee Weapons");
		else if (object_id == spawn_weapons_menu)
			Format(buffer, maxlength, "Spawn Weapons");
		else if (object_id == spawn_items_menu)
			Format(buffer, maxlength, "Spawn Items");
		else if (object_id == config_menu)
			Format(buffer, maxlength, "Configuration Options");
	} else if (action == TopMenuAction_SelectOption) {
		if (object_id == director_menu)
			Menu_CreateDirectorMenu(client, false);
		else if (object_id == spawn_special_infected_menu)
			Menu_CreateSpecialInfectedMenu(client, false);
		else if (object_id == spawn_uncommon_infected_menu)
			Menu_CreateUInfectedMenu(client, false);
		else if (object_id == spawn_melee_weapons_menu)
			Menu_CreateMeleeWeaponMenu(client, false);
		else if (object_id == spawn_weapons_menu)
			Menu_CreateWeaponMenu(client, false);
		else if (object_id == spawn_items_menu)
			Menu_CreateItemMenu(client, false);
		else if (object_id == config_menu)
			Menu_CreateConfigMenu(client, false);
	}

	return 0;
}

// Infected spawning functions

/// Creates the infected spawning menu when it is selected from the top menu and displays it to the client.
public void Menu_CreateSpecialInfectedMenu(int client, int args) {
	Menu menu;
	menu = new Menu(Menu_SpawnSInfectedHandler);
	 
	menu.SetTitle("Spawn Special Infected");
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	if (automatic_placement)
		menu.AddItem("ap", "Disable automatic placement");
	else 
		menu.AddItem("ap", "Enable automatic placement");
	menu.AddItem("st", "Spawn a tank");
	if (GetClientImmunityLevel(client) > 98)
		menu.AddItem("sw", "Spawn a witch");
	menu.AddItem("sb", "Spawn a boomer");
	menu.AddItem("sh", "Spawn a hunter");
	menu.AddItem("ss", "Spawn a smoker");
	menu.AddItem("sp", "Spawn a spitter");
	menu.AddItem("sj", "Spawn a jockey");
	menu.AddItem("sc", "Spawn a charger");
	menu.AddItem("sb", "Spawn a mob");
	menu.DisplayAt(client, g_iSpecialInfectedMenuPosition[client], MENU_TIME_FOREVER);
}
/// Handles callbacks from a client using the spawning menu.
public int Menu_SpawnSInfectedHandler(Menu menu, MenuAction action, int cindex, int itempos) {
	// When a player selects an item do this.		
	if (action == MenuAction_Select) {
		switch (itempos) {
			case 0:
				if (automatic_placement) 
					Do_EnableAutoPlacement(cindex, false); 
				else
					Do_EnableAutoPlacement(cindex, true);
			case 1:
				Do_SpawnInfected(cindex, "tank");
			case 2:
				Do_SpawnWitch(cindex, automatic_placement);
			case 3:
				Do_SpawnInfected(cindex, "boomer");
			case 4:
				Do_SpawnInfected(cindex, "hunter");
			case 5:
				Do_SpawnInfected(cindex, "smoker");
			case 6:
				Do_SpawnInfected(cindex, "spitter");
			case 7:
				Do_SpawnInfected(cindex, "jockey");
			case 8:
				Do_SpawnInfected(cindex, "charger");
			case 9:
				Do_SpawnInfected_Old(cindex, "mob", false);
		}
		g_iSpecialInfectedMenuPosition[cindex] = menu.Selection;
		// If none of the above matches show the menu again
		Menu_CreateSpecialInfectedMenu(cindex, false);
	// If someone closes the menu - close the menu
	} else if (action == MenuAction_End)
		delete menu;
	// If someone presses 'back' (8), return to main All4Dead menu */
	else if (action == MenuAction_Cancel)
		if (itempos == MenuCancel_ExitBack && admin_menu != null)
			admin_menu.Display( cindex, TopMenuPosition_LastCategory);

	return 0;
}

/// Creates the infected spawning menu when it is selected from the top menu and displays it to the client.
public Action Menu_CreateUInfectedMenu(int client, int args) {
	Menu menu = new Menu(Menu_SpawnUInfectedHandler);
	menu.SetTitle("Spawn Uncommon Infected");
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	if (automatic_placement)
		menu.AddItem("ap", "Disable automatic placement");
	else 
		menu.AddItem("ap", "Enable automatic placement");
	menu.AddItem("s1", "Spawn a riot zombie");
	menu.AddItem("s2", "Spawn a ceda zombie");
	menu.AddItem("s3", "Spawn a clown zombie");
	menu.AddItem("s4", "Spawn a mudmen zombie");
	menu.AddItem("s5", "Spawn a roadworker zombie");
	menu.AddItem("s6", "Spawn a jimmie gibbs zombie");
	menu.AddItem("s7", "Spawn a fallen survivor zombie");
	menu.DisplayAt(client, g_iUInfectedMenuPosition[client], MENU_TIME_FOREVER);
	return Plugin_Handled;
}
/// Handles callbacks from a client using the spawning menu.
public int Menu_SpawnUInfectedHandler(Menu menu, MenuAction action, int cindex, int itempos) {
	// When a player selects an item do this.		
	if (action == MenuAction_Select) {
		switch (itempos) {
			case 0:
				if (automatic_placement) 
					Do_EnableAutoPlacement(cindex, false); 
				else
					Do_EnableAutoPlacement(cindex, true);
			case 1:
				Do_SpawnUncommonInfected(cindex, 0);
			case 2:
				Do_SpawnUncommonInfected(cindex, 1);
			case 3:
				Do_SpawnUncommonInfected(cindex, 2);
			case 4:
				Do_SpawnUncommonInfected(cindex, 3);
			case 5:
				Do_SpawnUncommonInfected(cindex, 4);
			case 6:
				Do_SpawnUncommonInfected(cindex, 5);
			case 7:
				Do_SpawnUncommonInfected(cindex, 6);
		}
		g_iUInfectedMenuPosition[cindex] = menu.Selection;
		// If none of the above matches show the menu again
		Menu_CreateUInfectedMenu(cindex, false);
	// If someone closes the menu - close the menu
	} else if (action == MenuAction_End)
		delete menu;
	// If someone presses 'back' (8), return to main All4Dead menu */
	else if (action == MenuAction_Cancel)
		if (itempos == MenuCancel_ExitBack && admin_menu != null)
			admin_menu.Display( cindex, TopMenuPosition_LastCategory);
	
	return 0;
}

/// Sourcemod Action for the SpawnInfected command.
public Action Command_SpawnInfected(int client, int args) { 
	if (client == 0)
	{
		PrintToServer("[TS] This Command cannot be used by server.");
		return Plugin_Handled;
	}

	if (args < 1) {
		ReplyToCommand(client, "Usage: a4d_spawn_infected <infected_type> (does not work for uncommon infected, use a4d_spawn_uinfected instead)"); 
	} else {
		char type[16];
		GetCmdArg(1, type, sizeof(type));
		if (strcmp(type, "zombie") == 0)
			Do_SpawnInfected_Old(client, "zombie", true);
		else if(strcmp(type, "mob") == 0)
			Do_SpawnInfected_Old(client, "mob", false);
		else if(strcmp(type, "witch") == 0)
			Do_SpawnWitch(client, automatic_placement);
		else
			Do_SpawnInfected(client, type);
	}
	return Plugin_Handled;
}

/// Sourcemod Action for the SpawnUncommonInfected command.
public Action Command_SpawnUInfected(int client, int args) { 
	if (args < 1) {
		ReplyToCommand(client, "Usage: a4d_spawn_uinfected <riot|ceda|clown|mud|roadcrew|jimmy>"); 
	} else {
		char type[32];
		GetCmdArg(1, type, sizeof(type));
		int number;
		if (strcmp(type, "riot", false) == 0) number = 0;
		else if (strcmp(type, "ceda", false) == 0) number = 1;
		else if (strcmp(type, "clown", false) == 0) number = 2;
		else if (strcmp(type, "mud", false) == 0) number = 3;
		else if (strcmp(type, "roadcrew", false) == 0) number = 4;
		else if (strcmp(type, "jimmy", false) == 0) number = 5;
		else if (strcmp(type, "fallen", false) == 0) number = 6;
		Do_SpawnUncommonInfected(client, number);
	}
	return Plugin_Handled;
}

/**
 * <summary>
 * 	Spawns one of the specified infected using the z_spawn command. 
 * </summary>
 * <param name="type">
 * 	The type of infected to spawn
 * </param>
 * <remarks>
 * 	The infected will spawn either at the crosshair of the spawning player
 * 	or at a location automatically decided by the AI Director if auto_placement
 * 	is true. Automatically falls back to a fake client if the client requesting
 * 	the action is the console.
 * </remarks>
*/
void Do_SpawnInfected(int client, const char[] type) {
	if(client == 0)
	{
		return;
	}
	
	if(RealFreePlayersOnInfected())
	{
		Do_SpawnInfected_Old(client, type, false);
		return;
	}

	int zombieclass;
	if (strcmp(type, "tank") == 0)
		zombieclass = 8;
	else if (strcmp(type, "smoker") == 0)
		zombieclass = 1;
	else if (strcmp(type, "boomer") == 0)
		zombieclass = 2;
	else if (strcmp(type, "hunter") == 0)
		zombieclass = 3;
	else if (strcmp(type, "spitter") == 0)
		zombieclass = 4;
	else if (strcmp(type, "jockey") == 0)
		zombieclass = 5;
	else if (strcmp(type, "charger") == 0)
		zombieclass = 6;

	float vPos[3], vAng[3] = {0.0, 0.0, 0.0};
	if (automatic_placement == true)
	{
		if(L4D_GetRandomPZSpawnPosition(L4D_GetHighestFlowSurvivor(), zombieclass, 5, vPos) == false)
		{
			PrintToChat(client, "[TS] Couldn't find a valid spawn position for S.I. in 5 tries");
			return;
		}
	}
	else
	{
		if( !SetTeleportEndPoint(client, vPos, vAng) ) {
			PrintToChat(client, "[TS] Can not spawn, please try again.");
			return;
		}
	}

	bool bSpawnSuccessful = false;
	int bot = 0;
	switch(zombieclass)
	{
		case 1:
		{
			bot = SDKCall(hCreateSmoker, "Smoker Bot");
			if (IsValidClient(bot))
			{
				SetEntityModel(bot, MODEL_SMOKER);
				bSpawnSuccessful = true;
			}	
		}
		case 2:
		{
			bot = SDKCall(hCreateBoomer, "Boomer Bot");
			if (IsValidClient(bot))
			{
				SetEntityModel(bot, MODEL_BOOMER);
				bSpawnSuccessful = true;
			}		
		}
		case 3:
		{
			bot = SDKCall(hCreateHunter, "Hunter Bot");
			if (IsValidClient(bot))
			{
				SetEntityModel(bot, MODEL_HUNTER);
				bSpawnSuccessful = true;
			}	
		}
		case 4:
		{
			bot = SDKCall(hCreateSpitter, "Spitter Bot");
			if (IsValidClient(bot))
			{
				SetEntityModel(bot, MODEL_SPITTER);
				bSpawnSuccessful = true;
			}	
		}
		case 5:
		{
			bot = SDKCall(hCreateJockey, "Jockey Bot");
			if (IsValidClient(bot))
			{
				SetEntityModel(bot, MODEL_JOCKEY);
				bSpawnSuccessful = true;
			}		
		}
		case 6:
		{
			bot = SDKCall(hCreateCharger, "Charger Bot");
			if (IsValidClient(bot))
			{
				SetEntityModel(bot, MODEL_CHARGER);
				bSpawnSuccessful = true;
			}		
		}
		case 8:
		{
			bot = SDKCall(hCreateTank, "Tank Bot");
			if (IsValidClient(bot))
			{
				SetEntityModel(bot, MODEL_TANK);
				bSpawnSuccessful = true;
			}	
		}		
	}

	if (bSpawnSuccessful)
	{
		ChangeClientTeam(bot, 3);
		SetEntProp(bot, Prop_Send, "m_usSolidFlags", 16);
		SetEntProp(bot, Prop_Send, "movetype", 2);
		SetEntProp(bot, Prop_Send, "deadflag", 0);
		SetEntProp(bot, Prop_Send, "m_lifeState", 0);
		SetEntProp(bot, Prop_Send, "m_iObserverMode", 0);
		SetEntProp(bot, Prop_Send, "m_iPlayerState", 0);
		SetEntProp(bot, Prop_Send, "m_zombieState", 0);
		DispatchSpawn(bot);
		ActivateEntity(bot);
		TeleportEntity(bot, vPos, NULL_VECTOR, NULL_VECTOR); //移動到相同位置

		char feedback[64];
		Format(feedback, sizeof(feedback), "A %s has been spawned", type);
		NotifyPlayers(client, feedback);
		LogAction(client, -1, "[NOTICE]: (%L) has spawned a %s", client, type);
	}
}

void Do_SpawnInfected_Old(int client, const char[] type, bool spawning_uncommon ) {

	char arguments[16];
	char feedback[64];
	Format(feedback, sizeof(feedback), "A %s has been spawned", type);
	if (automatic_placement == true && !spawning_uncommon)
		Format(arguments, sizeof(arguments), "%s %s", type, "auto");
	else
		Format(arguments, sizeof(arguments), "%s", type);
	// If we are spawning an uncommon
	if (spawning_uncommon)
		currently_spawning = true;
	// If we are spawning from the console make sure we force auto placement on	
	if (client == 0) {
		Format(arguments, sizeof(arguments), "%s %s", type, "auto");
		StripAndExecuteClientCommand(Misc_GetAnyClient(), "z_spawn_old", arguments);
	} else if (spawning_uncommon && automatic_placement == true) {
		currently_spawning = false;
		int zombie = CreateEntityByName("infected");
		SetEntityModel(zombie, change_zombie_model_to);
		int ticktime = RoundToNearest( GetGameTime() / GetTickInterval()  ) + 5;
		SetEntProp(zombie, Prop_Data, "m_nNextThinkTick", ticktime);
		DispatchSpawn(zombie);
		ActivateEntity(zombie);
		TeleportEntity(zombie, last_zombie_spawn_location, NULL_VECTOR, NULL_VECTOR);
		NotifyPlayers(client, feedback);
		LogAction(client, -1, "[NOTICE]: (%L) has spawned a %s", client, type);
		return;
	} else {
		StripAndExecuteClientCommand(client, "z_spawn_old", arguments);
	}
	NotifyPlayers(client, feedback);
	LogAction(client, -1, "[NOTICE]: (%L) has spawned a %s", client, type);
	//PrintToChatAll("Spawned a %s with automatic placement %b and uncommon %b", type, automatic_placement, spawning_uncommon);
}

void Do_SpawnWitch(const int client, const bool bAutoSpawn)
{
	float vPos[3], vAng[3] = {0.0, 0.0, 0.0};
	if (bAutoSpawn) {
		if(L4D_GetRandomPZSpawnPosition(L4D_GetHighestFlowSurvivor(),7,ZOMBIESPAWN_Attempts,vPos) == false) {
			PrintToChat(client, "[TS] Can't spawn witch in %d tries at this moment.", ZOMBIESPAWN_Attempts);
			return;
		}
	} 
	else {
		if( !SetTeleportEndPoint(client, vPos, vAng) ) {
			PrintToChat(client, "[TS] Can not spawn, please try again.");
			return;
		}
	}

	if( g_bSpawnWitchBride ) {
		L4D2_SpawnWitchBride(vPos,NULL_VECTOR);
	}
	else {
		L4D2_SpawnWitch(vPos,NULL_VECTOR);
	}
}

void Do_SpawnUncommonInfected(int client, int type) {
	char model[128];
	switch (type) {
		case 0:
			Format(model, sizeof(model), "models/infected/common_male_riot.mdl");
		case 1:
			Format(model, sizeof(model), "models/infected/common_male_ceda.mdl");
		case 2:
			Format(model, sizeof(model), "models/infected/common_male_clown.mdl");
		case 3:
			Format(model, sizeof(model), "models/infected/common_male_mud.mdl");
		case 4:
			Format(model, sizeof(model), "models/infected/common_male_roadcrew.mdl");
		case 5:
			Format(model, sizeof(model), "models/infected/common_male_jimmy.mdl");
		case 6:
			Format(model, sizeof(model), "models/infected/common_male_fallen_survivor.mdl");
	}
	change_zombie_model_to = model;
	Do_SpawnInfected_Old(client, "zombie", true);
}
/// Sourcemod Action for the Do_EnableAutoPlacement command.
public Action Command_EnableAutoPlacement(int client, int args) {
	if (args < 1) {
		ReplyToCommand(client, "Usage: a4d_enable_auto_placement <0|1>");
		return Plugin_Handled;
	}
	char value[16];
	GetCmdArg(1, value, sizeof(value));
	if (strcmp(value, "0") == 0)
		Do_EnableAutoPlacement(client, false);		
	else
		Do_EnableAutoPlacement(client, true);
	return Plugin_Handled;
}
/**
 * <summary>
 * 	Allows (or disallows) the AI Director to place spawned infected automatically.
 * </summary>
 * <remarks>
 * 	If this is enabled the director will place mobs outside the players sight so 
 * 	it will not look like they are magically appearing. This only affects zombies
 * 	spawned through z_spawn.
 * </remarks>
*/
void Do_EnableAutoPlacement(int client, bool value) {
	automatic_placement = value;
	if (value == true)
		NotifyPlayers(client, "Automatic placement of spawned infected has been enabled.");
	else
		NotifyPlayers(client, "Automatic placement of spawned infected has been disabled.");
	//LogAction(client, -1, "(%L) set %s to %i", client, "a4d_automatic_placement", value);	
}

// Item spawning functions

/// Creates the item spawning menu when it is selected from the top menu and displays it to the client */
public Action Menu_CreateItemMenu(int client, int args) {
	Menu menu = new Menu(Menu_SpawnItemsHandler);
	menu.SetTitle("Spawn Items");
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.AddItem("sd", "Spawn a defibrillator");
	menu.AddItem("sm", "Spawn a medkit");
	menu.AddItem("sp", "Spawn some pills");
	menu.AddItem("sa", "Spawn some adrenaline");
	menu.AddItem("sv", "Spawn a molotov");
	menu.AddItem("sb", "Spawn a pipe bomb");
	menu.AddItem("sb", "Spawn a bile jar");
	menu.AddItem("sg", "Spawn a gas tank");
	menu.AddItem("st", "Spawn a firework");
	menu.AddItem("so", "Spawn a propane tank");
	menu.AddItem("sa", "Spawn an oxygen tank");
	menu.AddItem("si", "Spawn an ammo pile");
	menu.AddItem("sn", "Spawn laser sight pack");
	menu.AddItem("se", "Spawn incendiary ammo");
	menu.AddItem("sf", "Spawn explosive ammo");
	menu.AddItem("sg", "Spawn a gnome");
	menu.AddItem("sh", "Spawn cola bottles");
	menu.DisplayAt( client, g_iItemMenuPosition[client], MENU_TIME_FOREVER);
	return Plugin_Handled;
}
/// Handles callbacks from a client using the spawn item menu.
public int Menu_SpawnItemsHandler(Menu menu, MenuAction action, int cindex, int itempos) {
	if (action == MenuAction_Select) {
		switch (itempos) {
			case 0: {
				Do_SpawnItem(cindex, "defibrillator");
			} case 1: {
				Do_SpawnItem(cindex, "first_aid_kit");
			} case 2: {
				Do_SpawnItem(cindex, "pain_pills");
			} case 3: {
				Do_SpawnItem(cindex, "adrenaline");
			} case 4: {
				Do_SpawnItem(cindex, "molotov");
			} case 5: {
				Do_SpawnItem(cindex, "pipe_bomb");
			} case 6: {
				Do_SpawnItem(cindex, "vomitjar");
			} case 7: {
				Do_SpawnItem(cindex, "gascan");
			} case 8: {
				Do_SpawnItem(cindex, "fireworkcrate");
			} case 9: {
				Do_SpawnItem(cindex, "propanetank");
			} case 10: {
				Do_SpawnItem(cindex, "oxygentank");
			} case 11: {
				float location[3];
				if (!Misc_TraceClientViewToLocation(cindex, location)) {
					GetClientAbsOrigin(cindex, location);
				}
				Do_CreateEntity(cindex, "weapon_ammo_spawn", "models/props/terror/ammo_stack.mdl", location, false);
			} case 12: {
				float location[3];
				if (!Misc_TraceClientViewToLocation(cindex, location)) {
					GetClientAbsOrigin(cindex, location);
				}
				Do_CreateEntity(cindex, "upgrade_laser_sight", "PROVIDED", location, false);
			} case 13: {
				Do_SpawnItem(cindex, "weapon_upgradepack_incendiary");
			} case 14: {
				Do_SpawnItem(cindex, "weapon_upgradepack_explosive");	
			} case 15: {
				Do_SpawnItem(cindex, "gnome");	
			} case 16: {
				Do_SpawnItem(cindex, "cola_bottles");	
			}
		}
		g_iItemMenuPosition[cindex] = menu.Selection;
		Menu_CreateItemMenu(cindex, false);
	} else if (action == MenuAction_End) {
		delete menu;
	} else if (action == MenuAction_Cancel) {
		if (itempos == MenuCancel_ExitBack && admin_menu != null)
			admin_menu.Display( cindex, TopMenuPosition_LastCategory);
	}

	return 0;
}
/// Sourcemod Action for the Do_SpawnItem command.
public Action Command_SpawnItem(int client, int args) { 
	if (args < 1) {
		ReplyToCommand(client, "Usage: a4d_spawn_item <item_type>");
	} else {
		char type[16];
		GetCmdArg(1, type, sizeof(type));
		Do_SpawnItem(client, type);
	}
	return Plugin_Handled;
}

/**
 * <summary>
 * 	Spawns one of the specified type of item using the give command. 
 * </summary>
 * <param name="type">
 * 	The type of item to spawn
 * </param>
 * <remarks>
 * 	The infected will spawn either at the crosshair of the spawning player
 * 	or at a location automatically decided by the AI Director if auto_placement
 * 	is true. Slightly misleadingly named this function is used for both items and weapons.
 * </remarks>
*/
void Do_SpawnItem(int client, const char[] type) {
	char feedback[64];
	Format(feedback, sizeof(feedback), "A %s has been spawned", type);
	if (client == 0) {
		ReplyToCommand(client, "Can not use this command from the console."); 
	} else {
		StripAndExecuteClientCommand(client, "give", type);
		NotifyPlayers(client, feedback);
		LogAction(client, -1, "[NOTICE]: (%L) has spawned a %s", client, type);
	}
}

void Do_CreateEntity(int client, const char[] name, const char[] model, float location[3], const bool zombie) {
	int entity = CreateEntityByName(name);
	if (strcmp(model, "PROVIDED") != 0)
		SetEntityModel(entity, model);
	DispatchSpawn(entity);
	if (zombie) {
		int ticktime = RoundToNearest( GetGameTime() / GetTickInterval() ) + 5;
		SetEntProp(zombie, Prop_Data, "m_nNextThinkTick", ticktime);
		location[2] -= 25.0; // reduce the 'drop' effect
	}
	// Starts animation on whatever we spawned - necessary for mobs
	ActivateEntity(entity);
	// Teleport the entity to the client's crosshair
	TeleportEntity(entity, location, NULL_VECTOR, NULL_VECTOR);
	LogAction(client, -1, "[NOTICE]: (%L) has created a %s (%s)", client, name, model);
}

// Weapon Spawning functions

/// Creates the weapon spawning menu when it is selected from the top menu and displays it to the client.
public Action Menu_CreateWeaponMenu(int client, int args) {
	Menu menu = new Menu(Menu_SpawnWeaponHandler);
	menu.SetTitle("Spawn Weapons");
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	
	menu.AddItem("s1", "Spawn a pistol");
	menu.AddItem("s2", "Spawn a magnum");
	menu.AddItem("s3", "Spawn a pumpshotgun");
	menu.AddItem("s4", "Spawn a shotgun chrome");
	menu.AddItem("s5", "Spawn a sub machine gun");
	menu.AddItem("s6", "Spawn a silenced smg");
	menu.AddItem("s7", "Spawn a mp5");
	menu.AddItem("s8", "Spawn an assault rifle");
	menu.AddItem("s9", "Spawn a sg552 rifle");
	menu.AddItem("s0", "Spawn an AK74");
	menu.AddItem("sa", "Spawn a desert rifle");
	menu.AddItem("sb", "Spawn a shotgun spas");
	menu.AddItem("sc", "Spawn an auto shotgun");
	menu.AddItem("sd", "Spawn a hunting rifle");
	menu.AddItem("se", "Spawn a military sniper");
	menu.AddItem("sf", "Spawn a scout");
	menu.AddItem("sg", "Spawn an awp");
	menu.AddItem("sh", "Spawn a grenade launcher");
	menu.AddItem("si", "Spawn a m60");
	menu.DisplayAt( client,  g_iWeaponMenuPosition[client], MENU_TIME_FOREVER);
	return Plugin_Handled;
}
/// Handles callbacks from a client using the spawn weapon menu.
public int Menu_SpawnWeaponHandler(Menu menu, MenuAction action, int cindex, int itempos) {
	if (action == MenuAction_Select) {
		switch (itempos) {
			case 0: {
				Do_SpawnItem(cindex, "pistol");
			} case 1: {
				Do_SpawnItem(cindex, "pistol_magnum");
			} case 2: {
				Do_SpawnItem(cindex, "pumpshotgun");
			} case 3: {
				Do_SpawnItem(cindex, "shotgun_chrome");
			} case 4: {
				Do_SpawnItem(cindex, "smg");
			} case 5: {
				Do_SpawnItem(cindex, "smg_silenced");
			} case 6: {
				Do_SpawnItem(cindex, "smg_mp5"); 
			} case 7: {
				Do_SpawnItem(cindex, "rifle");
			} case 8: {
				Do_SpawnItem(cindex, "rifle_sg552");
			} case 9: {
				Do_SpawnItem(cindex, "rifle_ak47");
			} case 10: {
				Do_SpawnItem(cindex, "rifle_desert");
			} case 11: {
				Do_SpawnItem(cindex, "shotgun_spas");
			} case 12: {
				Do_SpawnItem(cindex, "autoshotgun");
			} case 13: {
				Do_SpawnItem(cindex, "hunting_rifle");
			} case 14: {
				Do_SpawnItem(cindex, "sniper_military");
			} case 15: {
				Do_SpawnItem(cindex, "sniper_scout");
			} case 16: {
				Do_SpawnItem(cindex, "sniper_awp");
			} case 17: {
				Do_SpawnItem(cindex, "grenade_launcher");
			} case 18: {
				Do_SpawnItem(cindex, "rifle_m60");
			}
		}
		g_iWeaponMenuPosition[cindex] = menu.Selection;
		Menu_CreateWeaponMenu(cindex, false);
	} else if (action == MenuAction_End)
		delete menu;
	/* If someone presses 'back' (8), return to main All4Dead menu */
	else if (action == MenuAction_Cancel)
		if (itempos == MenuCancel_ExitBack && admin_menu != null)
			admin_menu.Display( cindex, TopMenuPosition_LastCategory);

	return 0;
}

/// Creates the melee weapon spawning menu when it is selected from the top menu and displays it to the client.
public Action Menu_CreateMeleeWeaponMenu(int client, int args) {
	Menu menu = new Menu(Menu_SpawnMeleeWeaponHandler);
	menu.SetTitle("Spawn Melee Weapons");
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	
	menu.AddItem("ma", "Spawn a baseball bat");
	menu.AddItem("mb", "Spawn a chainsaw");
	menu.AddItem("mc", "Spawn a cricket bat");
	menu.AddItem("md", "Spawn a crowbar");
	menu.AddItem("me", "Spawn an electric guitar");
	menu.AddItem("mf", "Spawn a fire axe");
	menu.AddItem("mg", "Spawn a frying pan");
	menu.AddItem("mh", "Spawn a katana");
	menu.AddItem("mi", "Spawn a machete");
	menu.AddItem("mj", "Spawn a police baton");
	menu.AddItem("mk", "Spawn a knife");
	menu.AddItem("ml", "Spawn a golf club");
	menu.AddItem("mm", "Spawn a pitchfork");
	menu.AddItem("mn", "Spawn a shovel");
	
	menu.DisplayAt( client, g_iMeleeMenuPosition[client], MENU_TIME_FOREVER);
	return Plugin_Handled;
}
/// Handles callbacks from a client using the spawn weapon menu.
public int Menu_SpawnMeleeWeaponHandler(Menu menu, MenuAction action, int cindex, int itempos) {
	if (action == MenuAction_Select) {
		switch (itempos) {
			case 0: {
				Do_SpawnItem(cindex, "baseball_bat");
			} case 1: {
				Do_SpawnItem(cindex, "chainsaw");
			} case 2: {
				Do_SpawnItem(cindex, "cricket_bat");
			} case 3: {
				Do_SpawnItem(cindex, "crowbar");
			} case 4: {
				Do_SpawnItem(cindex, "electric_guitar");
			} case 5: {
				Do_SpawnItem(cindex, "fireaxe");
			} case 6: {
				Do_SpawnItem(cindex, "frying_pan");
			} case 7: {
				Do_SpawnItem(cindex, "katana");
			} case 8: {
				Do_SpawnItem(cindex, "machete");
			} case 9: {
				Do_SpawnItem(cindex, "tonfa");
			} case 10: {
				Do_SpawnItem(cindex, "knife");
			} case 11: {
				Do_SpawnItem(cindex, "golfclub");
			} case 12: {
				Do_SpawnItem(cindex, "pitchfork");
			} case 13: {
				Do_SpawnItem(cindex, "shovel");
			} 
			
		}
		g_iMeleeMenuPosition[cindex] = menu.Selection;
		Menu_CreateMeleeWeaponMenu(cindex, false);
	} else if (action == MenuAction_End)
		delete menu;
	/* If someone presses 'back' (8), return to main All4Dead menu */
	else if (action == MenuAction_Cancel)
		if (itempos == MenuCancel_ExitBack && admin_menu != null)
			admin_menu.Display( cindex, TopMenuPosition_LastCategory);

	return 0;
}

// Additional director commands

/// Creates the director commands menu when it is selected from the top menu and displays it to the client.
public void Menu_CreateDirectorMenu(int client, int args) {
	Menu menu = new Menu(Menu_DirectorMenuHandler);
	menu.SetTitle("Director Commands");
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.AddItem("fp", "Force a panic event to start");
	if (director_panic_forever.BoolValue) { menu.AddItem("pf", "End non-stop panic events"); } else { menu.AddItem("pf", "Force non-stop panic events"); }
	if (director_force_tank.BoolValue) { menu.AddItem("ft", "Director controls if a tank spawns this round"); } else { menu.AddItem("ft", "Force a tank to spawn this round"); }
	if (director_force_witch.BoolValue) { menu.AddItem("fw", "Director controls if a witch spawns this round"); } else { menu.AddItem("fw", "Force a witch to spawn this round"); }
	if (always_force_bosses.BoolValue) { menu.AddItem("fd", "Stop bosses spawning continuously"); } else { menu.AddItem("fw", "Force bosses to spawn continuously"); }
	menu.AddItem("mz", "Add more zombies to the horde");	
	menu.Display( client, MENU_TIME_FOREVER);
}
/// Handles callbacks from a client using the director commands menu.
public int Menu_DirectorMenuHandler(Menu menu, MenuAction action, int cindex, int itempos) {
	if (action == MenuAction_Select) {
		switch (itempos) {
			case 0: {
				Do_ForcePanic(cindex);
			} case 1: {
				if (director_panic_forever.BoolValue) 
					Do_PanicForever(cindex, false); 
				else
					Do_PanicForever(cindex, true);
			} case 2: {
				if (director_force_tank.BoolValue)
					Do_ForceTank(cindex, false); 
				else
					Do_ForceTank(cindex, true);
			} case 3: {
				if (director_force_witch.BoolValue) 
					Do_ForceWitch(cindex, false);
				else
					Do_ForceWitch(cindex, true);
			}  case 4: {
				if (always_force_bosses.BoolValue)
					Do_AlwaysForceBosses(cindex, false); 
				else
					Do_AlwaysForceBosses(cindex, true);
			} case 5: {
				Do_AddZombies(cindex, zombies_increment.IntValue);
			} 
		}
		Menu_CreateDirectorMenu(cindex, false);
	} else if (action == MenuAction_End) {
		delete menu;
	} else if (action == MenuAction_Cancel) {
		if (itempos == MenuCancel_ExitBack && admin_menu != null)
			admin_menu.Display( cindex, TopMenuPosition_LastCategory);
	}

	return 0;
}

/// Sourcemod Action for the AlwaysForceBosses command.
public Action Command_AlwaysForceBosses(int client, int args) {
	if (args < 1) { 
		ReplyToCommand(client, "Usage: a4d_always_force_bosses <0|1>"); 
		return Plugin_Handled;
	}
	char value[2];
	GetCmdArg(1, value, sizeof(value));
	if (strcmp(value, "0") == 0)
		Do_AlwaysForceBosses(client, false);		
	else
		Do_AlwaysForceBosses(client, true);
	return Plugin_Handled;
}
/**
 * <summary>
 * 	Do not revert director_force_tank and director_force_witch when a boss spawns.
 * </summary>
 * <remarks>
 * 	This has the effect of continously spawning bosses when either force_tank
 * 	or force_witch is enabled.
 * </remarks>
*/
void Do_AlwaysForceBosses(int client, bool value) {
	SetConVarBool(always_force_bosses, value);
	if (value == true)
		NotifyPlayers(client, "Bosses will now spawn continuously.");
	else
		NotifyPlayers(client, "Bosses will now longer spawn continuously.");
}

/// Sourcemod Action for the Do_ForcePanic command.
public Action Command_ForcePanic(int client, int args) { 
	Do_ForcePanic(client);
	return Plugin_Handled;
}
/**
 * <summary>
 * 	This command forces the AI director to start a panic event
 * </summary>
 * <remarks>
 * 	A panic event is the same as a cresendo event, like pushing a button which calls
 * 	the lift in No Mercy. The director will not start more than one panic event at once.
 * </remarks>
*/
void Do_ForcePanic(int client) {
	if (client == 0)
		StripAndExecuteClientCommand(Misc_GetAnyClient(), "director_force_panic_event", "");
	else
		StripAndExecuteClientCommand(client, "director_force_panic_event", "");
	NotifyPlayers(client, "The zombies are coming!");	
	LogAction(client, -1, "[NOTICE]: (%L) executed %s", client, "a4d_force_panic");
}
/// Sourcemod Action for the Do_PanicForever command.
public Action Command_PanicForever(int client, int args) {
	if (args < 1) { 
		ReplyToCommand(client, "Usage: a4d_panic_forever <0|1>"); 
		return Plugin_Handled;
	}
	char value[2];
	GetCmdArg(1, value, sizeof(value));
	if (strcmp(value, "0") == 0)
		Do_PanicForever(client, false);
	else
		Do_PanicForever(client, true);
	return Plugin_Handled;
}
/**
 * <summary>
 * 	This command forces the AI director to start a panic event endlessly, 
 * 	one after each other.
 * </summary>
 * <remarks>
 * 	This does not trigger a panic event. If you are intending for endless panic
 * 	events to start straight away use this and then Do_ForcePanic. 
 * </remarks>
 * <seealso>
 * 	Do_ForcePanic
 * </seealso>
*/
void Do_PanicForever(int client, bool value) {
	StripAndChangeServerConVarBool(client, director_panic_forever, value);
	if (value == true)
		NotifyPlayers(client, "Endless panic events have started.");
	else
		NotifyPlayers(client, "Endless panic events have ended.");
}
/// Sourcemod Action for the Do_ForceTank command.
public Action Command_ForceTank(int client, int args) {
	if (args < 1) { 
		ReplyToCommand(client, "Usage: a4d_force_tank <0|1>"); 
		return Plugin_Handled; 
	}
	
	char value[2];
	GetCmdArg(1, value, sizeof(value));

	if (strcmp(value, "0") == 0)
		Do_ForceTank(client, false);	
	else 
		Do_ForceTank(client, true);
	return Plugin_Handled;
}

void Do_ForceTank(int client, bool value) {
	StripAndChangeServerConVarBool(client, director_force_tank, value);
	if (value == true)
		NotifyPlayers(client, "A tank is guaranteed to spawn this round");
	else
		NotifyPlayers(client, "A tank is no longer guaranteed to spawn this round");
}
/// Sourcemod Action for the Do_ForceWitch command.
public Action Command_ForceWitch(int client, int args) {
	if (args < 1) { 
		ReplyToCommand(client, "Usage: a4d_force_witch <0|1>"); 
		return Plugin_Handled;
	}
	char value[2];
	GetCmdArg(1, value, sizeof(value));
	if (strcmp(value, "0") == 0)
		Do_ForceWitch(client, false);
	else 
		Do_ForceWitch(client, true);
	return Plugin_Handled;
}

void Do_ForceWitch(int client, bool value) {
	StripAndChangeServerConVarBool(client, director_force_witch, value);
	if (value == true)
		NotifyPlayers(client, "A witch is guaranteed to spawn this round");	
	else 
		NotifyPlayers(client, "A witch is no longer guaranteed to spawn this round");
}


/// Sourcemod Action for the AddZombies command.
public Action Command_AddZombies(int client, int args) {
	if (args < 1) { 
		ReplyToCommand(client, "Usage: a4d_add_zombies <0..99>"); 
		return Plugin_Handled;
	}
	char value[4];
	GetCmdArg(1, value, sizeof(value));
	int zombies = StringToInt(value);
	Do_AddZombies(client, zombies);
	return Plugin_Handled;
}
/**
 * <summary>
 * 	The director will spawn more zombies in the mobs and mega mobs.
 * </summary>
 * <remarks>
 * 	Make sure to not put silly values in for this as it may cause severe performance problems.
 * 	You can reset all settings back to their defaults by calling a4d_reset_to_defaults.
 * </remarks>
*/
void Do_AddZombies(int client, int zombies_to_add) {
	int new_zombie_total = zombies_to_add + z_mega_mob_size.IntValue;
	StripAndChangeServerConVarInt(client, z_mega_mob_size, new_zombie_total);
	new_zombie_total = zombies_to_add + z_mob_spawn_max_size.IntValue;
	StripAndChangeServerConVarInt(client, z_mob_spawn_max_size, new_zombie_total);
	new_zombie_total = zombies_to_add + z_mob_spawn_min_size.IntValue;
	StripAndChangeServerConVarInt(client, z_mob_spawn_min_size, new_zombie_total);
	NotifyPlayers(client, "The horde grows larger.");
}

// Configuration commands

/// Creates the configuration commands menu when it is selected from the top menu and displays it to the client.
public Action Menu_CreateConfigMenu(int client, int args) {
	Menu menu = new Menu(Menu_ConfigCommandsHandler);
	menu.SetTitle("Configuration Commands");
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	if (notify_players.BoolValue) { menu.AddItem("pn", "Disable player notifications"); } else { menu.AddItem("pn", "Enable player notifications"); }
	menu.AddItem("rs", "Restore all settings to game defaults now");
	menu.Display( client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}
/// Handles callbacks from a client using the configuration menu.
public int Menu_ConfigCommandsHandler(Menu menu, MenuAction action, int cindex, int itempos) {
	
	if (action == MenuAction_Select) {
		switch (itempos) {
			case 0: {
				if (notify_players.BoolValue)
					Do_EnableNotifications(cindex, false); 
				else
					Do_EnableNotifications(cindex, true); 
			} case 1: {
				Do_ResetToDefaults(cindex);
			}
		}
		Menu_CreateConfigMenu(cindex, false);
	} else if (action == MenuAction_End) {
		delete menu;
	} else if (action == MenuAction_Cancel) {
		if (itempos == MenuCancel_ExitBack && admin_menu != null)
			admin_menu.Display( cindex, TopMenuPosition_LastCategory);
	}

	return 0;
}

/// Sourcemod Action for the Do_EnableNotifications command.
public Action Command_EnableNotifications(int client, int args) {
	if (args < 1) { 
		ReplyToCommand (client, "Usage: a4d_enable_notifications <0|1>"); 
		return Plugin_Handled;
	}
	char value[2];
	GetCmdArg(1, value, sizeof(value));
	if (strcmp(value, "0") == 0) 
		Do_EnableNotifications(client, false);		
	else
		Do_EnableNotifications(client, true);
	return Plugin_Handled;
}
/**
 * <summary>
 * 	Enable (or disable) in game notifications of all4dead actions.
 * </summary>
 * <remarks>
 * 	When enabled notifications honour sm_activity settings.
 * </remarks>
*/
void Do_EnableNotifications(int client, bool value) {
	SetConVarBool(notify_players, value);
	NotifyPlayers(client, "Player notifications have now been enabled.");
	LogAction(client, -1, "(%L) set %s to %i", client, "a4d_notify_players", value);	
}
/// Sourcemod Action for the Do_ResetToDefaults command.
public Action Command_ResetToDefaults(int client, int args) {
	Do_ResetToDefaults(client);
	return Plugin_Handled;
}
/// Resets all ConVars to their default settings.
void Do_ResetToDefaults(int client) {
	Do_ForceTank(client, false);
	Do_ForceWitch(client, false);
	Do_PanicForever(client, false);
	StripAndChangeServerConVarInt(client, z_mega_mob_size, 50);
	StripAndChangeServerConVarInt(client, z_mob_spawn_max_size, 30);
	StripAndChangeServerConVarInt(client, z_mob_spawn_min_size, 10);
	NotifyPlayers(client, "Restored the default settings.");
	LogAction(client, -1, "(%L) executed %s", client, "a4d_reset_to_defaults");
}

/// Sourcemod Action for the Do_EnableAllBotTeam command.
public Action Command_EnableAllBotTeams(int client, int args) {
	if (args < 1) { 
		ReplyToCommand(client, "Usage: a4d_enable_all_bot_teams <0|1>"); 
		return Plugin_Handled;
	}

	char value[2];
	GetCmdArg(1, value, sizeof(value));

	if (strcmp(value, "0") == 0)
		Do_EnableAllBotTeam(client, false);	
	else
		Do_EnableAllBotTeam(client, true);
	return Plugin_Handled;
}
/// Allow an all bot survivor team
void Do_EnableAllBotTeam(int client, bool value) {
	StripAndChangeServerConVarBool(client, sb_all_bot_team, value);
	if (value == true)
		NotifyPlayers(client, "Allowing an all bot survivor team.");	
	else
		NotifyPlayers(client, "We now require at least one human survivor before the game can start.");
}

// Helper functions

/// Wrapper for ShowActivity2 in case we want to change how this works later on
void NotifyPlayers(int client, const char[] message) {
	if (notify_players.BoolValue)
		ShowActivity2(client, PLUGIN_TAG, message);
}
/// Strip and change a ConVarBool to another value. This allows modification of otherwise cheat-protected ConVars.
void StripAndChangeServerConVarBool(int client, ConVar convar, bool value) {
	char command[32];
	convar.GetName(command,32);
	convar.SetBool(value, false, false);
	LogAction(client, -1, "[NOTICE]: (%L) set %s to %i", client, command, value);	
}
/// Strip and execute a client command. This 'fakes' a client calling a specfied command. Can be used to call cheat-protected commands.
void StripAndExecuteClientCommand(int client, const char[] command, const char[] arguments) {
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
}
/// Strip and change a ConVarInt to another value. This allows modification of otherwise cheat-protected ConVars.
void StripAndChangeServerConVarInt(int client, ConVar convar, int value) {
	char command[32];
	convar.GetName(command,32);
	convar.SetInt(value, false, false);
	LogAction(client, -1, "[NOTICE]: (%L) set %s to %i", client, command, value);	
}
// Gets a client ID to allow various commands to be called as console
int Misc_GetAnyClient() {
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			// PrintToChatAll("Using client %L for command", i);
			return i;
		}
	}
	return 0;
}



bool Misc_TraceClientViewToLocation(int client, float location[3]) {
	float vAngles[3], vOrigin[3];
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	// PrintToChatAll("Running Code %f %f %f | %f %f %f", vOrigin[0], vOrigin[1], vOrigin[2], vAngles[0], vAngles[1], vAngles[2]);
	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitSelf, client);
	if(TR_DidHit(trace)) {
		TR_GetEndPosition(location, trace);
		CloseHandle(trace);
		// PrintToChatAll("Collision at %f %f %f", location[0], location[1], location[2]);
		return true;
	}
	CloseHandle(trace);
	return false;
}

public bool TraceRayDontHitSelf(int entity, int mask, any data) {
	if(entity == data) { // Check if the TraceRay hit the itself.
		return false; // Don't let the entity be hit
	}
	return true; // It didn't hit itself
}

public void GetEntityAbsOrigin(int entity, float origin[3]) {
	float mins[3], maxs[3];
	GetEntPropVector(entity,Prop_Send,"m_vecOrigin",origin);
	GetEntPropVector(entity,Prop_Send,"m_vecMins",mins);
	GetEntPropVector(entity,Prop_Send,"m_vecMaxs",maxs);
	
	origin[0] += (mins[0] + maxs[0]) * 0.5;
	origin[1] += (mins[1] + maxs[1]) * 0.5;
	origin[2] += (mins[2] + maxs[2]) * 0.5;
}

public Action kickbot(Handle timer, any client)
{
	if (IsClientInGame(client) && (!IsClientInKickQueue(client)))
	{
		if (IsFakeClient(client)) KickClient(client);
	}

	return Plugin_Continue;
}

// ====================================================================================================
//					POSITION
// ====================================================================================================
float GetGroundHeight(float vPos[3])
{
	float vAng[3]; Handle trace = TR_TraceRayFilterEx(vPos, view_as<float>({ 90.0, 0.0, 0.0 }), MASK_ALL, RayType_Infinite, _TraceFilter);
	if( TR_DidHit(trace) )
		TR_GetEndPosition(vAng, trace);

	delete trace;
	return vAng[2];
}

// Taken from "[L4D2] Weapon/Zombie Spawner"
// By "Zuko & McFlurry"
bool SetTeleportEndPoint(int client, float vPos[3], float vAng[3])
{
	GetClientEyePosition(client, vPos);
	GetClientEyeAngles(client, vAng);

	Handle trace = TR_TraceRayFilterEx(vPos, vAng, MASK_SHOT, RayType_Infinite, _TraceFilter);

	if( TR_DidHit(trace) )
	{
		float vNorm[3];
		float degrees = vAng[1];
		TR_GetEndPosition(vPos, trace);

		GetGroundHeight(vPos);
		vPos[2] += 1.0;

		TR_GetPlaneNormal(trace, vNorm);
		GetVectorAngles(vNorm, vAng);

		if( vNorm[2] == 1.0 )
		{
			vAng[0] = 0.0;
			vAng[1] = degrees + 180;
		}
		else
		{
			if( degrees > vAng[1] )
				degrees = vAng[1] - degrees;
			else
				degrees = degrees - vAng[1];
			vAng[0] += 90.0;
			RotateYaw(vAng, degrees + 180);
		}
	}
	else
	{
		delete trace;
		return false;
	}

	vAng[1] += 90.0;
	vAng[2] -= 90.0;
	delete trace;
	return true;
}

public bool _TraceFilter(int entity, int contentsMask)
{
	return entity > MaxClients || !entity;
}

void RotateYaw(float angles[3], float degree)
{
	float direction[3], normal[3];
	GetAngleVectors(angles, direction, NULL_VECTOR, normal);

	float sin = Sine(degree * 0.01745328);	 // Pi/180
	float cos = Cosine(degree * 0.01745328);
	float a = normal[0] * sin;
	float b = normal[1] * sin;
	float c = normal[2] * sin;
	float x = direction[2] * b + direction[0] * cos - direction[1] * c;
	float y = direction[0] * c + direction[1] * cos - direction[2] * a;
	float z = direction[1] * a + direction[2] * cos - direction[0] * b;
	direction[0] = x;
	direction[1] = y;
	direction[2] = z;

	GetVectorAngles(direction, angles);

	float up[3];
	GetVectorVectors(direction, NULL_VECTOR, up);

	float roll = GetAngleBetweenVectors(up, normal, direction);
	angles[2] += roll;
}

//---------------------------------------------------------
// calculate the angle between 2 vectors
// the direction will be used to determine the sign of angle (right hand rule)
// all of the 3 vectors have to be normalized
//---------------------------------------------------------
float GetAngleBetweenVectors(const float vector1[3], const float vector2[3], const float direction[3])
{
	float vector1_n[3], vector2_n[3], direction_n[3], cross[3];
	NormalizeVector(direction, direction_n);
	NormalizeVector(vector1, vector1_n);
	NormalizeVector(vector2, vector2_n);
	float degree = ArcCosine(GetVectorDotProduct(vector1_n, vector2_n )) * 57.29577951;   // 180/Pi
	GetVectorCrossProduct(vector1_n, vector2_n, cross);

	if( GetVectorDotProduct( cross, direction_n ) < 0.0 )
		degree *= -1.0;

	return degree;
}

bool RealFreePlayersOnInfected ()
{
	for (int i=1;i<=MaxClients;i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 3 && (IsPlayerGhost(i) || !IsPlayerAlive(i)))
				return true;
	}
	return false;
}

bool IsPlayerGhost (int client)
{
	if (GetEntProp(client, Prop_Send, "m_isGhost"))
		return true;
	return false;
}

Handle hGameConf;
void GetGameData()
{
	hGameConf = LoadGameConfigFile("all4dead2");
	if( hGameConf != null )
	{
		PrepSDKCall();
	}
	else
	{
		SetFailState("Unable to find all4dead2.txt gamedata file.");
	}
	delete hGameConf;
}

void PrepSDKCall()
{
	//find create bot signature
	Address replaceWithBot = GameConfGetAddress(hGameConf, "NextBotCreatePlayerBot.jumptable");
	if (replaceWithBot != Address_Null && LoadFromAddress(replaceWithBot, NumberType_Int8) == 0x68) {
		// We're on L4D2 and linux
		PrepWindowsCreateBotCalls(replaceWithBot);
	}
	else
	{
		PrepL4D2CreateBotCalls();
	}
}

void LoadStringFromAdddress(Address addr, char[] buffer, int maxlength) {
	int i = 0;
	while(i < maxlength) {
		char val = LoadFromAddress(addr + view_as<Address>(i), NumberType_Int8);
		if(val == 0) {
			buffer[i] = 0;
			break;
		}
		buffer[i] = val;
		i++;
	}
	buffer[maxlength - 1] = 0;
}

Handle PrepCreateBotCallFromAddress(Handle hSiFuncTrie, const char[] siName) {
	Address addr;
	StartPrepSDKCall(SDKCall_Static);
	if (!GetTrieValue(hSiFuncTrie, siName, addr) || !PrepSDKCall_SetAddress(addr))
	{
		SetFailState("Unable to find NextBotCreatePlayer<%s> address in memory.", siName);
		return null;
	}
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	return EndPrepSDKCall();	
}

void PrepWindowsCreateBotCalls(Address jumpTableAddr) {
	Handle hInfectedFuncs = CreateTrie();
	// We have the address of the jump table, starting at the first PUSH instruction of the
	// PUSH mem32 (5 bytes)
	// CALL rel32 (5 bytes)
	// JUMP rel8 (2 bytes)
	// repeated pattern.
	
	// Each push is pushing the address of a string onto the stack. Let's grab these strings to identify each case.
	// "Hunter" / "Smoker" / etc.
	for(int i = 0; i < 7; i++) {
		// 12 bytes in PUSH32, CALL32, JMP8.
		Address caseBase = jumpTableAddr + view_as<Address>(i * 12);
		Address siStringAddr = view_as<Address>(LoadFromAddress(caseBase + view_as<Address>(1), NumberType_Int32));
		static char siName[32];
		LoadStringFromAdddress(siStringAddr, siName, sizeof(siName));

		Address funcRefAddr = caseBase + view_as<Address>(6); // 2nd byte of call, 5+1 byte offset.
		int funcRelOffset = LoadFromAddress(funcRefAddr, NumberType_Int32);
		Address callOffsetBase = caseBase + view_as<Address>(10); // first byte of next instruction after the CALL instruction
		Address nextBotCreatePlayerBotTAddr = callOffsetBase + view_as<Address>(funcRelOffset);
		//PrintToServer("Found NextBotCreatePlayerBot<%s>() @ %08x", siName, nextBotCreatePlayerBotTAddr);
		SetTrieValue(hInfectedFuncs, siName, nextBotCreatePlayerBotTAddr);
	}

	hCreateSmoker = PrepCreateBotCallFromAddress(hInfectedFuncs, "Smoker");
	if (hCreateSmoker == null)
	{ SetFailState("Cannot initialize %s SDKCall, address lookup failed.", NAME_CreateSmoker); return; }

	hCreateBoomer = PrepCreateBotCallFromAddress(hInfectedFuncs, "Boomer");
	if (hCreateBoomer == null)
	{ SetFailState("Cannot initialize %s SDKCall, address lookup failed.", NAME_CreateBoomer); return; }

	hCreateHunter = PrepCreateBotCallFromAddress(hInfectedFuncs, "Hunter");
	if (hCreateHunter == null)
	{ SetFailState("Cannot initialize %s SDKCall, address lookup failed.", NAME_CreateHunter); return; }

	hCreateTank = PrepCreateBotCallFromAddress(hInfectedFuncs, "Tank");
	if (hCreateTank == null)
	{ SetFailState("Cannot initialize %s SDKCall, address lookup failed.", NAME_CreateTank); return; }
	
	hCreateSpitter = PrepCreateBotCallFromAddress(hInfectedFuncs, "Spitter");
	if (hCreateSpitter == null)
	{ SetFailState("Cannot initialize %s SDKCall, address lookup failed.", NAME_CreateSpitter); return; }
	
	hCreateJockey = PrepCreateBotCallFromAddress(hInfectedFuncs, "Jockey");
	if (hCreateJockey == null)
	{ SetFailState("Cannot initialize %s SDKCall, address lookup failed.", NAME_CreateJockey); return; }

	hCreateCharger = PrepCreateBotCallFromAddress(hInfectedFuncs, "Charger");
	if (hCreateCharger == null)
	{ SetFailState("Cannot initialize %s SDKCall, address lookup failed.", NAME_CreateCharger); return; }
}

void PrepL4D2CreateBotCalls() {
	StartPrepSDKCall(SDKCall_Static);
	if (!PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, NAME_CreateSpitter))
	{ SetFailState("Unable to find %s signature in gamedata file.", NAME_CreateSpitter); return; }
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	hCreateSpitter = EndPrepSDKCall();
	if (hCreateSpitter == null)
	{ SetFailState("Cannot initialize %s SDKCall, signature is broken.", NAME_CreateSpitter); return; }
	
	StartPrepSDKCall(SDKCall_Static);
	if (!PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, NAME_CreateJockey))
	{ SetFailState("Unable to find %s signature in gamedata file.", NAME_CreateJockey); return; }
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	hCreateJockey = EndPrepSDKCall();
	if (hCreateJockey == null)
	{ SetFailState("Cannot initialize %s SDKCall, signature is broken.", NAME_CreateJockey); return; }
	
	StartPrepSDKCall(SDKCall_Static);
	if (!PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, NAME_CreateCharger))
	{ SetFailState("Unable to find %s signature in gamedata file.", NAME_CreateCharger); return; }
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	hCreateCharger = EndPrepSDKCall();
	if (hCreateCharger == null)
	{ SetFailState("Cannot initialize %s SDKCall, signature is broken.", NAME_CreateCharger); return; }

	StartPrepSDKCall(SDKCall_Static);
	if (!PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, NAME_CreateSmoker))
	{ SetFailState("Unable to find %s signature in gamedata file.", NAME_CreateSmoker); return; }
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	hCreateSmoker = EndPrepSDKCall();
	if (hCreateSmoker == null)
	{ SetFailState("Cannot initialize %s SDKCall, signature is broken.", NAME_CreateSmoker); return; }
	
	StartPrepSDKCall(SDKCall_Static);
	if (!PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, NAME_CreateBoomer))
	{ SetFailState("Unable to find %s signature in gamedata file.", NAME_CreateBoomer); return; }
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	hCreateBoomer = EndPrepSDKCall();
	if (hCreateBoomer == null)
	{ SetFailState("Cannot initialize %s SDKCall, signature is broken.", NAME_CreateBoomer); return; }
	
	StartPrepSDKCall(SDKCall_Static);
	if (!PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, NAME_CreateHunter))
	{ SetFailState("Unable to find %s signature in gamedata file.", NAME_CreateHunter); return; }
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	hCreateHunter = EndPrepSDKCall();
	if (hCreateHunter == null)
	{ SetFailState("Cannot initialize %s SDKCall, signature is broken.", NAME_CreateHunter); return; }
	
	StartPrepSDKCall(SDKCall_Static);
	if (!PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, NAME_CreateTank))
	{ SetFailState("Unable to find %s signature in gamedata file.", NAME_CreateTank); return; }
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	hCreateTank = EndPrepSDKCall();
	if (hCreateTank == null)
	{ SetFailState("Cannot initialize %s SDKCall, signature is broken.", NAME_CreateTank); return; }
}

bool IsValidClient(int client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	return true;
}
stock int GetClientImmunityLevel(int client) {
	char sSteamID[32];
	GetClientAuthId(client, AuthId_Steam2, sSteamID, sizeof sSteamID);
	AdminId admin = FindAdminByIdentity(AUTHMETHOD_STEAM, sSteamID);
	if (admin == INVALID_ADMIN_ID)
		return -999;

	return admin.ImmunityLevel;
}