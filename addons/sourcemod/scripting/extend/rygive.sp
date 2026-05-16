#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
//#include <sdktools>
//#include <sdkhooks>
#include <left4dhooks>
#undef REQUIRE_PLUGIN
#include <rpg>

#define PLUGIN_NAME				"Give Item Menu"
#define PLUGIN_AUTHOR			"sorallll"
#define PLUGIN_DESCRIPTION		"多功能插件"
#define PLUGIN_VERSION			"1.2.3"
#define PLUGIN_URL				""

#define GAMEDATA				"rygive"
#define NAME_CreateSmoker		"NextBotCreatePlayerBot<Smoker>"
#define NAME_CreateBoomer		"NextBotCreatePlayerBot<Boomer>"
#define NAME_CreateHunter		"NextBotCreatePlayerBot<Hunter>"
#define NAME_CreateSpitter		"NextBotCreatePlayerBot<Spitter>"
#define NAME_CreateJockey		"NextBotCreatePlayerBot<Jockey>"
#define NAME_CreateCharger		"NextBotCreatePlayerBot<Charger>"
#define NAME_CreateTank			"NextBotCreatePlayerBot<Tank>"

StringMap
	g_smSteamIDs,
	g_smMeleeTrans;

ArrayList
	g_aMeleeScripts;

Handle
	g_hSDK_TerrorNavMesh_GetLastCheckpoint,
	g_hSDK_Checkpoint_GetLargestArea,
	g_hSDK_NextBotCreatePlayerBot_Smoker,
	g_hSDK_NextBotCreatePlayerBot_Boomer,
	g_hSDK_NextBotCreatePlayerBot_Hunter,
	g_hSDK_NextBotCreatePlayerBot_Spitter,
	g_hSDK_NextBotCreatePlayerBot_Jockey,
	g_hSDK_NextBotCreatePlayerBot_Charger,
	g_hSDK_NextBotCreatePlayerBot_Tank;

Address
	g_pZombieManager,
	g_pStatsCondition;

int
	g_iFunction[MAXPLAYERS + 1],
	g_iSelection[MAXPLAYERS + 1],
	g_iOff_m_nFallenSurvivors,
	g_iOff_m_FallenSurvivorTimer;

static const int
	g_iTargetTeam[] = {
		0,
		1,
		2,
		3
	};

float
	g_fSpeedUp[MAXPLAYERS + 1] = {1.0, ...};

bool
	g_bLateLoad,
	g_bDebugMode,
	g_bWeaponHandling,
	g_bRPG,
	g_bGodMode[MAXPLAYERS + 1],
	g_bIgnoreAbility[MAXPLAYERS + 1];

char
	g_sNamedItem[MAXPLAYERS + 1][64];

static const char
	g_sTargetTeam[][] = {
		"闲置(仅生还)",
		"观众",
		"生还",
		"感染"
	},
	g_sZombieClass[][] = {
		"smoker",
		"boomer",
		"hunter",
		"spitter",
		"jockey", 
		"charger",
		"tank"
	},
	g_sMeleeModels[][] = {
		"models/weapons/melee/v_fireaxe.mdl",
		"models/weapons/melee/w_fireaxe.mdl",
		"models/weapons/melee/v_frying_pan.mdl",
		"models/weapons/melee/w_frying_pan.mdl",
		"models/weapons/melee/v_machete.mdl",
		"models/weapons/melee/w_machete.mdl",
		"models/weapons/melee/v_bat.mdl",
		"models/weapons/melee/w_bat.mdl",
		"models/weapons/melee/v_crowbar.mdl",
		"models/weapons/melee/w_crowbar.mdl",
		"models/weapons/melee/v_cricket_bat.mdl",
		"models/weapons/melee/w_cricket_bat.mdl",
		"models/weapons/melee/v_tonfa.mdl",
		"models/weapons/melee/w_tonfa.mdl",
		"models/weapons/melee/v_katana.mdl",
		"models/weapons/melee/w_katana.mdl",
		"models/weapons/melee/v_electric_guitar.mdl",
		"models/weapons/melee/w_electric_guitar.mdl",
		"models/v_models/v_knife_t.mdl",
		"models/w_models/weapons/w_knife_t.mdl",
		"models/weapons/melee/v_golfclub.mdl",
		"models/weapons/melee/w_golfclub.mdl",
		"models/weapons/melee/v_shovel.mdl",
		"models/weapons/melee/w_shovel.mdl",
		"models/weapons/melee/v_pitchfork.mdl",
		"models/weapons/melee/w_pitchfork.mdl",
		"models/weapons/melee/v_riotshield.mdl",
		"models/weapons/melee/w_riotshield.mdl"
	},
	g_sSpecialModels[][] = {
		"models/infected/smoker.mdl",
		"models/infected/boomer.mdl",
		"models/infected/hunter.mdl",
		"models/infected/spitter.mdl",
		"models/infected/jockey.mdl",
		"models/infected/charger.mdl",
		"models/infected/hulk.mdl",
		"models/infected/witch.mdl",
		"models/infected/witch_bride.mdl"
	},
	g_sUncommonModels[][] = {
		"models/infected/common_male_riot.mdl",
		"models/infected/common_male_ceda.mdl",
		"models/infected/common_male_clown.mdl",
		"models/infected/common_male_mud.mdl",
		"models/infected/common_male_roadcrew.mdl",
		"models/infected/common_male_jimmy.mdl",
		"models/infected/common_male_fallen_survivor.mdl",
	},
	g_sMeleeName[][] = {
		"fireaxe",			//斧头
		"frying_pan",		//平底锅
		"machete",			//砍刀
		"baseball_bat",		//棒球棒
		"crowbar",			//撬棍
		"cricket_bat",		//球拍
		"tonfa",			//警棍
		"katana",			//武士刀
		"electric_guitar",	//吉他
		"knife",			//小刀
		"golfclub",			//高尔夫球棍
		"shovel",			//铁铲
		"pitchfork",		//草叉
		"riotshield",		//盾牌
	};

enum L4D2WeaponType {
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

public void OnLibraryAdded(const char[] name) {
	if (strcmp(name, "WeaponHandling") == 0)
		g_bWeaponHandling = true;
	if (strcmp(name, "rpg") == 0)
		g_bRPG = true;
}

public void OnLibraryRemoved(const char[] name) {
	if (strcmp(name, "WeaponHandling") == 0)
		g_bWeaponHandling = false;
	if (strcmp(name, "WeaponHandling") == 0)
		g_bRPG = false;
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	g_bLateLoad = late;
	return APLRes_Success;
}

public void OnAllPluginsLoaded() {
	g_pZombieManager = L4D_GetPointer(POINTER_ZOMBIEMANAGER);
}

public Plugin myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public void OnPluginStart() {
	InitData();

	g_smSteamIDs = new StringMap();
	g_smMeleeTrans = new StringMap();
	g_aMeleeScripts = new ArrayList(ByteCountToCells(64));

	CreateConVar("rygive_version", PLUGIN_VERSION, "Give Item Menu plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
	RegAdminCmd("sm_rygive", cmdRygive, ADMFLAG_CHAT, "rygive");

	g_smMeleeTrans.SetString("fireaxe", "斧头");
	g_smMeleeTrans.SetString("frying_pan", "平底锅");
	g_smMeleeTrans.SetString("machete", "砍刀");
	g_smMeleeTrans.SetString("baseball_bat", "棒球棒");
	g_smMeleeTrans.SetString("crowbar", "撬棍");
	g_smMeleeTrans.SetString("cricket_bat", "球拍");
	g_smMeleeTrans.SetString("tonfa", "警棍");
	g_smMeleeTrans.SetString("katana", "武士刀");
	g_smMeleeTrans.SetString("electric_guitar", "电吉他");
	g_smMeleeTrans.SetString("knife", "小刀");
	g_smMeleeTrans.SetString("golfclub", "高尔夫球棍");
	g_smMeleeTrans.SetString("shovel", "铁铲");
	g_smMeleeTrans.SetString("pitchfork", "草叉");
	g_smMeleeTrans.SetString("riotshield", "盾牌");
	g_smMeleeTrans.SetString("riot_shield", "盾牌");

	if (g_bLateLoad) {
		for (int i = 1; i <= MaxClients; i++) {
       	    if (IsClientInGame(i))
			    OnClientPutInServer(i);
        }
	}
}

public void OnPluginEnd() {
	StatsConditionPatch(false);
}

public void OnClientDisconnect(int client) {
	g_fSpeedUp[client] = 1.0;
	g_bGodMode[client] = false;
	g_bIgnoreAbility[client] = false;
}

public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

Action OnTakeDamage(int victim) {
	if (!g_bGodMode[victim])
		return Plugin_Continue;

	return Plugin_Handled;
}

public void OnClientPostAdminCheck(int client) {
	if (!g_bDebugMode || IsFakeClient(client))
		return;

	if (CheckCommandAccess(client, "", ADMFLAG_ROOT))
		return;

	char sSteamID[32];
	GetClientAuthId(client, AuthId_Steam2, sSteamID, sizeof sSteamID);
	bool allow;
	if (!g_smSteamIDs.GetValue(sSteamID, allow))
		KickClient(client, "服务器调试中...");
}

public void OnMapStart() {
	int i;
	for (; i < sizeof g_sMeleeModels; i++) {
		if (!IsModelPrecached(g_sMeleeModels[i]))
			PrecacheModel(g_sMeleeModels[i], true);
	}

	for (i = 0; i < sizeof g_sSpecialModels; i++) {
		if (!IsModelPrecached(g_sSpecialModels[i]))
			PrecacheModel(g_sSpecialModels[i], true);
	}
	
	for (i = 0; i < sizeof g_sUncommonModels; i++) {
		if (!IsModelPrecached(g_sUncommonModels[i]))
			PrecacheModel(g_sUncommonModels[i], true);
	}

	char buffer[64];
	for (i = 0; i < sizeof g_sMeleeName; i++) {
		FormatEx(buffer, sizeof buffer, "scripts/melee/%s.txt", g_sMeleeName[i]);
		if (!IsGenericPrecached(buffer))
			PrecacheGeneric(buffer, true);
	}

	GetMeleeStringTable();
}

void GetMeleeStringTable() {
	g_aMeleeScripts.Clear();
	int table = FindStringTable("meleeweapons");
	if (table != INVALID_STRING_TABLE) {
		int num = GetStringTableNumStrings(table);
		char melee[64];
		for (int i; i < num; i++) {
			ReadStringTable(table, i, melee, sizeof melee);
			g_aMeleeScripts.PushString(melee);
		}
	}
}

void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast) {
	if (!g_bDebugMode)
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client && IsFakeClient(client))
		return;

	if (RealPlayerExist(client))
		return;

	g_bDebugMode = false;
	g_smSteamIDs.Clear();
}

bool RealPlayerExist(int exclude) {
	for (int client = 1; client <= MaxClients; client++) {
		if (client != exclude && IsClientConnected(client) && !IsFakeClient(client))
			return true;
	}
	return false;
}

Action cmdRygive(int client, int args) {
	if (!client || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Handled;

	Rygive(client);
	return Plugin_Handled;
}

void Rygive(int client) {
	Menu menu = new Menu(Rygive_MenuHandler);
	menu.SetTitle("多功能插件:");
	menu.AddItem("w", "武器");
	menu.AddItem("i", "物品");
	menu.AddItem("z", "感染");
	menu.AddItem("m", "杂项");
	menu.AddItem("t", "团队控制");
	if (g_bWeaponHandling && GetClientImmunityLevel(client) > 90)
		menu.AddItem("c", "武器操纵性");

	if (GetClientImmunityLevel(client) > 98)
		menu.AddItem("d", !g_bDebugMode ? "开启调试模式" : "关闭调试模式");

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int GetClientImmunityLevel(int client) {
	char sSteamID[32];
	GetClientAuthId(client, AuthId_Steam2, sSteamID, sizeof sSteamID);
	AdminId admin = FindAdminByIdentity(AUTHMETHOD_STEAM, sSteamID);
	if (admin == INVALID_ADMIN_ID)
		return -999;

	return admin.ImmunityLevel;
}

int Rygive_MenuHandler(Menu menu, MenuAction action, int client, int param2) {
	switch (action) {
		case MenuAction_Select: {
			char item[2];
			menu.GetItem(param2, item, sizeof item);
			switch (item[0]) {
				case 'w':
					Weapon(client);

				case 'i':
					Item(client, 0);

				case 'z':
					Infected(client, 0);

				case 'm':
					Miscell(client, 0);

				case 't':
					SwitchTeam(client, 0);

				case 'c':
					SpeedUp(client, 0);

				case 'd':
					DebugMode(client);
			}
				
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

void Weapon(int client) {
	Menu menu = new Menu(Weapons_MenuHandler);
	menu.SetTitle("武器");
	menu.AddItem("", "枪械");
	menu.AddItem("", "近战");
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int Weapons_MenuHandler(Menu menu, MenuAction action, int client, int param2) {
	switch (action) {
		case MenuAction_Select: {
			g_iSelection[client] = menu.Selection;
			switch (param2) {
				case 0:
					Gun(client, 0);

				case 1:
					Melee(client, 0);
			}
		}

		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack)
				Rygive(client);
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

void Gun(int client, int item) {
	Menu menu = new Menu(Gun_MenuHandler);
	menu.SetTitle("枪械");
	menu.AddItem("pistol", "手枪");
	menu.AddItem("pistol_magnum", "马格南");
	menu.AddItem("chainsaw", "电锯");
	menu.AddItem("smg", "UZI微冲");
	menu.AddItem("smg_mp5", "MP5");
	menu.AddItem("smg_silenced", "MAC微冲");
	menu.AddItem("pumpshotgun", "木喷");
	menu.AddItem("shotgun_chrome", "铁喷");
	menu.AddItem("rifle", "M16步枪");
	menu.AddItem("rifle_ak47", "AK47");
	menu.AddItem("rifle_sg552", "SG552");
	menu.AddItem("rifle_desert", "三连步枪");
	menu.AddItem("autoshotgun", "一代连喷");
	menu.AddItem("shotgun_spas", "二代连喷");
	menu.AddItem("hunting_rifle", "木狙");
	menu.AddItem("sniper_military", "军狙");
	menu.AddItem("sniper_scout", "鸟狙");
	menu.AddItem("sniper_awp", "AWP");
	menu.AddItem("rifle_m60", "M60");
	menu.AddItem("grenade_launcher", "榴弹发射器");
	menu.ExitBackButton = true;
	menu.DisplayAt(client, item, MENU_TIME_FOREVER);
}

int Gun_MenuHandler(Menu menu, MenuAction action, int client, int param2) {
	switch (action) {
		case MenuAction_Select: {
			char item[64];
			menu.GetItem(param2, item, sizeof item);
			g_iFunction[client] = 1;
			g_iSelection[client] = menu.Selection;
			FormatEx(g_sNamedItem[client], sizeof g_sNamedItem, "give %s", item);
			ShowAliveSur(client);
		}

		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack)
				Weapon(client);
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

void Melee(int client, int item) {
	Menu menu = new Menu(Melee_MenuHandler);
	menu.SetTitle("近战");

	char melee[64];
	char trans[64];
	int count = g_aMeleeScripts.Length;
	for (int i; i < count; i++) {
		g_aMeleeScripts.GetString(i, melee, sizeof melee);
		if (!g_smMeleeTrans.GetString(melee, trans, sizeof trans))
			strcopy(trans, sizeof trans, melee);

		menu.AddItem(melee, trans);
	}
	menu.ExitBackButton = true;
	menu.DisplayAt(client, item, MENU_TIME_FOREVER);
}

int Melee_MenuHandler(Menu menu, MenuAction action, int client, int param2) {
	switch (action) {
		case MenuAction_Select: {
			char item[64];
			menu.GetItem(param2, item, sizeof item);
			g_iFunction[client] = 2;
			g_iSelection[client] = menu.Selection;
			FormatEx(g_sNamedItem[client], sizeof g_sNamedItem, "give %s", item);
			ShowAliveSur(client);
		}

		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack)
				Weapon(client);
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

void Item(int client, int item) {
	Menu menu = new Menu(Item_MenuHandler);
	menu.SetTitle("物品");
	menu.AddItem("health", "生命值");
	menu.AddItem("molotov", "燃烧瓶");
	menu.AddItem("pipe_bomb", "管状炸弹");
	menu.AddItem("vomitjar", "胆汁瓶");
	menu.AddItem("first_aid_kit", "医疗包");
	menu.AddItem("defibrillator", "电击器");
	if(GetClientImmunityLevel(client) > 90){
		menu.AddItem("upgradepack_incendiary", "燃烧弹药包");
		menu.AddItem("upgradepack_explosive", "高爆弹药包");
	}
	menu.AddItem("adrenaline", "肾上腺素");
	menu.AddItem("pain_pills", "止痛药");
	menu.AddItem("gascan", "汽油桶");
	menu.AddItem("propanetank", "煤气罐");
	menu.AddItem("oxygentank", "氧气瓶");
	menu.AddItem("fireworkcrate", "烟花箱");
	menu.AddItem("cola_bottles", "可乐瓶");
	menu.AddItem("gnome", "圣诞老人");
	menu.AddItem("ammo", "普通弹药");
	if(GetClientImmunityLevel(client) > 90){
		menu.AddItem("incendiary_ammo", "燃烧弹药");
		menu.AddItem("explosive_ammo", "高爆弹药");
	}
	menu.AddItem("laser_sight", "激光瞄准器");
	menu.ExitBackButton = true;
	menu.DisplayAt(client, item, MENU_TIME_FOREVER);
}

int Item_MenuHandler(Menu menu, MenuAction action, int client, int param2) {
	switch (action) {
		case MenuAction_Select: {
			char item[64];
			menu.GetItem(param2, item, sizeof item);
			g_iFunction[client] = 3;
			g_iSelection[client] = menu.Selection;

			if (param2 < 17)
				FormatEx(g_sNamedItem[client], sizeof g_sNamedItem, "give %s", item);
			else
				FormatEx(g_sNamedItem[client], sizeof g_sNamedItem, "upgrade_add %s", item);
				
			ShowAliveSur(client);
		}
	
		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack)
				Rygive(client);
		}

		case MenuAction_End:
			delete menu;	
	}

	return 0;
}

void Infected(int client, int item) {
	Menu menu = new Menu(Infected_MenuHandler);
	menu.SetTitle("感染");
	menu.AddItem("Smoker", "Smoker");
	menu.AddItem("Boomer", "Boomer");
	menu.AddItem("Hunter", "Hunter");
	menu.AddItem("Spitter", "Spitter");
	menu.AddItem("Jockey", "Jockey");
	menu.AddItem("Charger", "Charger");
	if(GetClientImmunityLevel(client) > 90){
		menu.AddItem("Tank", "Tank");
		menu.AddItem("Witch", "Witch");
		menu.AddItem("Witch_Bride", "婚纱Witch");
	}
	menu.AddItem("7", "普通僵尸");
	menu.AddItem("0", "Riot");
	menu.AddItem("1", "Ceda");
	menu.AddItem("2", "Clown");
	menu.AddItem("3", "Mudmen");
	menu.AddItem("4", "Roadworker");
	menu.AddItem("5", "Jimmie Gibbs");
	menu.AddItem("6", "Fallen Survivor");
	menu.ExitBackButton = true;
	menu.DisplayAt(client, item, MENU_TIME_FOREVER);
}

int Infected_MenuHandler(Menu menu, MenuAction action, int client, int param2) {
	switch (action) {
		case MenuAction_Select: {
			char item[32];
			menu.GetItem(param2, item, sizeof item);
			int kicked;
			if (GetClientCount(false) >= MaxClients - 1) {
				PrintToChat(client, "尝试踢出死亡的感染机器人...");
				kicked = KickDeadInfectedBots(client);
			}

			if (!kicked)
				CreateInfected(client, item);
			else {
				DataPack pack = new DataPack();
				pack.WriteCell(client);
				pack.WriteString(item);
				RequestFrame(NextFrame_CreateInfected, pack);
			}

			Infected(client, menu.Selection);
		}

		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack)
				Rygive(client);
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

int KickDeadInfectedBots(int client) {
	int kickedBots;
	for (int loopClient = 1; loopClient <= MaxClients; loopClient++) {
		if (!IsClientInGame(loopClient) || GetClientTeam(client) != 3 || !IsFakeClient(loopClient) || IsPlayerAlive(loopClient))
			continue;

		KickClient(loopClient);
		kickedBots++;
	}

	if (kickedBots > 0)
		PrintToChat(client, "Kicked %i bots.", kickedBots);

	return kickedBots;
}

void NextFrame_CreateInfected(DataPack pack) {
	pack.Reset();
	char buffer[32];
	int client = pack.ReadCell();
	pack.ReadString(buffer, sizeof buffer);
	delete pack;

	CreateInfected(client, buffer);
}

//https://github.com/ProdigySim/DirectInfectedSpawn
int CreateInfected(int client, const char[] zombie) {
	float vEnd[3];
	if (!GetTeleportEndPoint(client, vEnd))
		return -1;
	PrintToChatAll("\x03管理员\x01[\x05%N\x01]刷出一只\x05%s", client, zombie);
	return _CreateInfected(zombie, vEnd, NULL_VECTOR);
}

int _CreateInfected(const char[] zombie, const float vPos[3], const float vAng[3]) {
	int ent = -1;
	if (strncmp(zombie, "Witch", 5, false) == 0) {
		ent = CreateEntityByName("witch");
		if (ent == -1)
			return -1;

		TeleportEntity(ent, vPos, vAng, NULL_VECTOR);
		DispatchSpawn(ent);
		L4D_RPG_SetGlobalValue(INDEX_VALID, false);

		if (strlen(zombie) > 5)
			SetEntityModel(ent, g_sSpecialModels[8]);
	}
	else if (strcmp(zombie, "Smoker", false) == 0) {
		ent = SDKCall(g_hSDK_NextBotCreatePlayerBot_Smoker, "Smoker");
		if (ent == -1)
			return -1;
		
		//SetEntityModel(ent, g_sSpecialModels[0]);
		InitializeSpecial(ent, vPos, vAng);
	}
	else if (strcmp(zombie, "Boomer", false) == 0) {
		ent = SDKCall(g_hSDK_NextBotCreatePlayerBot_Boomer, "Boomer");
		if (ent == -1)
			return -1;
		
		//SetEntityModel(ent, g_sSpecialModels[1]);
		InitializeSpecial(ent, vPos, vAng);
	}
	else if (strcmp(zombie, "Hunter", false) == 0) {
		ent = SDKCall(g_hSDK_NextBotCreatePlayerBot_Hunter, "Hunter");
		if (ent == -1)
			return -1;
		
		//SetEntityModel(ent, g_sSpecialModels[2]);
		InitializeSpecial(ent, vPos, vAng);
	}
	else if (strcmp(zombie, "Spitter", false) == 0) {
		ent = SDKCall(g_hSDK_NextBotCreatePlayerBot_Spitter, "Spitter");
		if (ent == -1)
			return -1;
		
		//SetEntityModel(ent, g_sSpecialModels[3]);
		InitializeSpecial(ent, vPos, vAng);
	}
	else if (strcmp(zombie, "Jockey", false) == 0) {
		ent = SDKCall(g_hSDK_NextBotCreatePlayerBot_Jockey, "Jockey");
		if (ent == -1)
			return -1;
		
		//SetEntityModel(ent, g_sSpecialModels[4]);
		InitializeSpecial(ent, vPos, vAng);
	}
	else if (strcmp(zombie, "Charger", false) == 0) {
		ent = SDKCall(g_hSDK_NextBotCreatePlayerBot_Charger, "Charger");
		if (ent == -1)
			return -1;
	
		//SetEntityModel(ent, g_sSpecialModels[5]);
		InitializeSpecial(ent, vPos, vAng);
	}
	else if (strcmp(zombie, "Tank", false) == 0) {
		ent = SDKCall(g_hSDK_NextBotCreatePlayerBot_Tank, "Tank");
		if (ent == -1)
			return -1;

		//SetEntityModel(ent, g_sSpecialModels[6]);
		InitializeSpecial(ent, vPos, vAng);
	}
	else {
		ent = CreateEntityByName("infected");
		if (ent == -1)
			return -1;
		
		int pos = StringToInt(zombie);
		if (pos < 7)
			SetEntityModel(ent, g_sUncommonModels[pos]);

		SetEntProp(ent, Prop_Data, "m_nNextThinkTick", RoundToNearest(GetGameTime() / GetTickInterval()) + 5);
		TeleportEntity(ent, vPos, vAng, NULL_VECTOR);

		if (pos != 6) {
			DispatchSpawn(ent);
			ActivateEntity(ent);
		}
		else {
			int m_nFallenSurvivor = LoadFromAddress(g_pZombieManager + view_as<Address>(g_iOff_m_nFallenSurvivors), NumberType_Int32);
			float m_timestamp = view_as<float>(LoadFromAddress(g_pZombieManager + view_as<Address>(g_iOff_m_FallenSurvivorTimer) + view_as<Address>(8), NumberType_Int32));
			StoreToAddress(g_pZombieManager + view_as<Address>(g_iOff_m_nFallenSurvivors), 0, NumberType_Int32);
			StoreToAddress(g_pZombieManager + view_as<Address>(g_iOff_m_FallenSurvivorTimer) + view_as<Address>(8), view_as<int>(0.0), NumberType_Int32);
			DispatchSpawn(ent);
			ActivateEntity(ent);
			StoreToAddress(g_pZombieManager + view_as<Address>(g_iOff_m_nFallenSurvivors), m_nFallenSurvivor + LoadFromAddress(g_pZombieManager + view_as<Address>(g_iOff_m_nFallenSurvivors), NumberType_Int32), NumberType_Int32);
			StoreToAddress(g_pZombieManager + view_as<Address>(g_iOff_m_FallenSurvivorTimer) + view_as<Address>(8), view_as<int>(m_timestamp), NumberType_Int32);
		}
	}

	return ent;
}

void InitializeSpecial(int ent, const float vPos[3], const float vAng[3]) {
	ChangeClientTeam(ent, 3);
	SetEntProp(ent, Prop_Send, "m_usSolidFlags", 16);
	SetEntProp(ent, Prop_Send, "movetype", 2);
	SetEntProp(ent, Prop_Send, "deadflag", 0);
	SetEntProp(ent, Prop_Send, "m_lifeState", 0);
	SetEntProp(ent, Prop_Send, "m_iObserverMode", 0);
	SetEntProp(ent, Prop_Send, "m_iPlayerState", 0);
	SetEntProp(ent, Prop_Send, "m_zombieState", 0);
	DispatchSpawn(ent);
	TeleportEntity(ent, vPos, vAng, NULL_VECTOR);
}

void Miscell(int client, int item) {
	Menu menu = new Menu(Miscell_MenuHandler);
	menu.SetTitle("杂项");
	menu.AddItem("a", "倒地");
	menu.AddItem("b", "剥夺");
	menu.AddItem("c", "复活");
	if(GetClientImmunityLevel(client) > 99)
		menu.AddItem("d", "传送");
	menu.AddItem("e", "友伤");
	if(GetClientImmunityLevel(client) > 90)
		menu.AddItem("f", "伤害免疫");
	menu.AddItem("g", "召唤尸潮");
	menu.AddItem("h", "剔除所有Bot");
	menu.AddItem("i", "处死所有特感");
	if(GetClientImmunityLevel(client) > 90)
		menu.AddItem("j", "特感控制免疫");
	if(GetClientImmunityLevel(client) > 90)
		menu.AddItem("k", "处死所有生还");
	if(GetClientImmunityLevel(client) >= 90)
		menu.AddItem("l", "传送所有生还到起点");
	if(GetClientImmunityLevel(client) > 99)
	menu.AddItem("m", "传送所有生还到终点");
	menu.ExitBackButton = true;
	menu.DisplayAt(client, item, MENU_TIME_FOREVER);
}

int Miscell_MenuHandler(Menu menu, MenuAction action, int client, int param2) {
	switch (action) {
		case MenuAction_Select: {
			char item[2];
			menu.GetItem(param2, item, sizeof item);
			g_iSelection[client] = menu.Selection;

			switch (item[0]) {
				case 'a':
					IncapSur(client, 0);
				case 'b':
					StripSlot(client, 0);
				case 'c':
					RespawnPlayer(client, 0);
				case 'd':
					TeleportPlayer(client, 0);
				case 'e':
					SetFriendlyFire(client);
				case 'f':
					GodMode(client, 0);
				case 'g':
					ForcePanicEvent(client);
				case 'h':
					KickAllSurBot(client);
				case 'i':
					SlayAllSI(client);
				case 'j':
					IgnoreAbility(client, 0);
				case 'k':
					SlayAllSur(client);
				case 'l':
					WarpAllSurToStartArea(client);
				case 'm':
					WarpAllSurToCheckpoint(client);
			}
		}

		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack)
				Rygive(client);
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

void IncapSur(int client, int item) {
	char info[12];
	char disp[MAX_NAME_LENGTH];
	Menu menu = new Menu(IncapSur_MenuHandler);
	menu.SetTitle("目标玩家");
	menu.AddItem("a", "所有");
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i))
			continue;
	
		FormatEx(info, sizeof info, "%d", GetClientUserId(i));
		FormatEx(disp, sizeof disp, "%N", i);
		menu.AddItem(info, disp);
	}
	menu.ExitBackButton = true;
	menu.DisplayAt(client, item, MENU_TIME_FOREVER);
}

int IncapSur_MenuHandler(Menu menu, MenuAction action, int client, int param2) {
	switch (action) {
		case MenuAction_Select: {
			char item[12];
			menu.GetItem(param2, item, sizeof item);
			if (item[0] == 'a') {
				for (int i = 1; i <= MaxClients; i++)
					Incap(i);
						
				Miscell(client, 0);
			}
			else {
				int target = GetClientOfUserId(StringToInt(item));
				if (target && IsClientInGame(target))
					Incap(target);

				IncapSur(client, menu.Selection);
			}
		}

		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack)
				Miscell(client, 0);
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

void Incap(int client) {
	if (IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && !L4D_IsPlayerIncapacitated(client)) {
		static ConVar cv;
		if (!cv)
			cv = FindConVar("survivor_max_incapacitated_count");

		int val = cv.IntValue;
		if (GetEntProp(client, Prop_Send, "m_currentReviveCount") >= val) {
			SetEntProp(client, Prop_Send, "m_currentReviveCount", val - 1);
			SetEntProp(client, Prop_Send, "m_isGoingToDie", 0);
			SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);
			StopSound(client, SNDCHAN_STATIC, "player/heartbeatloop.wav");
		}
		IncapPlayer(client);
	}
}

void IncapPlayer(int client)  {
	bool last = g_bGodMode[client];
	g_bGodMode[client] = false;
	Vulnerable(client);
	SetEntityHealth(client, 1);
	L4D_SetPlayerTempHealth(client, 0);
	SDKHooks_TakeDamage(client, 0, 0, 100.0);
	g_bGodMode[client] = last;
}

void Vulnerable(int client) {
	static int m_invulnerabilityTimer = -1;
	if (m_invulnerabilityTimer == -1)
		m_invulnerabilityTimer = FindSendPropInfo("CTerrorPlayer", "m_noAvoidanceTimer") - 12;

	SetEntDataFloat(client, m_invulnerabilityTimer + 4, 0.0);
	SetEntDataFloat(client, m_invulnerabilityTimer + 8, 0.0);
}

void StripSlot(int client, int item) {
	char info[12];
	char disp[MAX_NAME_LENGTH];
	Menu menu = new Menu(StripSlot_MenuHandler);
	menu.SetTitle("目标玩家");
	menu.AddItem("a", "所有");
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i))
			continue;
	
		FormatEx(info, sizeof info, "%d", GetClientUserId(i));
		FormatEx(disp, sizeof disp, "%N", i);
		menu.AddItem(info, disp);
	}
	menu.ExitBackButton = true;
	menu.DisplayAt(client, item, MENU_TIME_FOREVER);
}

int StripSlot_MenuHandler(Menu menu, MenuAction action, int client, int param2) {
	switch (action) {
		case MenuAction_Select: {
			char item[12];
			menu.GetItem(param2, item, sizeof item);
			if (item[0] == 'a') {
				for (int i = 1; i <= MaxClients; i++) {
					if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
						L4D_RemoveAllWeapons(i);
				}
				Miscell(client, 0);
			}
			else {
				int target = GetClientOfUserId(StringToInt(item));
				if (target && IsClientInGame(target)) {
					SlotSelect(client, target);
					g_iSelection[client] = menu.Selection;
				}
			}
		}

		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack)
				Miscell(client, 0);
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

void SlotSelect(int client, int target) {
	char cls[32];
	char info[32];
	char str[2][16];
	Menu menu = new Menu(SlotSelect_MenuHandler);
	menu.SetTitle("目标装备");
	FormatEx(str[0], sizeof str[], "%d", GetClientUserId(target));
	strcopy(str[1], sizeof str[], "a");
	ImplodeStrings(str, sizeof str, "|", info, sizeof info);
	menu.AddItem(info, "所有装备");

	int ent;
	for (int i; i < 5; i++) {
		if ((ent = GetPlayerWeaponSlot(target, i)) == -1)
			continue;

		FormatEx(str[1], sizeof str[], "%d", i);
		ImplodeStrings(str, sizeof str, "|", info, sizeof info);
		GetEntityClassname(ent, cls, sizeof cls);
		if (strcmp(cls, "weapon_melee") == 0) {
			GetEntPropString(ent, Prop_Data, "m_strMapSetScriptName", cls, sizeof cls);
			if (cls[0] == '\0') {
				// 防爆警察掉落的警棍m_strMapSetScriptName为空字符串 (感谢little_froy的提醒)
				char ModelName[128];
				GetEntPropString(ent, Prop_Data, "m_ModelName", ModelName, sizeof ModelName);
				if (strcmp(ModelName, "models/weapons/melee/v_tonfa.mdl") == 0)
					strcopy(cls, sizeof cls, "tonfa");
			}
			g_smMeleeTrans.GetString(cls, cls, sizeof cls);
		}

		menu.AddItem(info, cls);
	}
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int SlotSelect_MenuHandler(Menu menu, MenuAction action, int client, int param2) {
	switch (action) {
		case MenuAction_Select: {
			char item[32];
			char info[2][16];
			menu.GetItem(param2, item, sizeof item);
			ExplodeString(item, "|", info, sizeof info, sizeof info[]);
			int target = GetClientOfUserId(StringToInt(info[0]));
			if (target && IsClientInGame(target)) {
				if (info[1][0] == 'a') {
					L4D_RemoveAllWeapons(target);
					StripSlot(client, g_iSelection[client]);
				}
				else {
					L4D_RemoveWeaponSlot(target, view_as<L4DWeaponSlot>(StringToInt(info[1])));
					SlotSelect(client, target);
				}
			}
		}

		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack)
				StripSlot(client, g_iSelection[client]);
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

void RespawnPlayer(int client, int item) {
	char info[12];
	char disp[MAX_NAME_LENGTH];
	Menu menu = new Menu(RespawnPlayer_MenuHandler);
	menu.SetTitle("目标玩家");
	menu.AddItem("s", "所有生还者");

	int team;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && ((team = GetClientTeam(i)) == 2 || (team == 3 && !IsFakeClient(i))) && !IsPlayerAlive(i)) {
			FormatEx(info, sizeof info, "%d", GetClientUserId(i));
			FormatEx(disp, sizeof disp, "%s - %N", g_sTargetTeam[team], i);
			menu.AddItem(info, disp);
		}
	}
	menu.ExitBackButton = true;
	menu.DisplayAt(client, item, MENU_TIME_FOREVER);
}

int RespawnPlayer_MenuHandler(Menu menu, MenuAction action, int client, int param2) {
	switch (action) {
		case MenuAction_Select: {
			char item[12];
			menu.GetItem(param2, item, sizeof item);
			if (item[0] == 's') {
					for (int i = 1; i <= MaxClients; i++) {
						if (!IsClientInGame(i) || GetClientTeam(i) != 2 || IsPlayerAlive(i))
							continue;
			
						StatsConditionPatch(true);
						L4D_RespawnPlayer(i);
						StatsConditionPatch(false);
						TeleportToSurvivor(i);
					}
					Miscell(client, 0);
			}
			else {
				int target = GetClientOfUserId(StringToInt(item));
				if (target && IsClientInGame(target) && !IsPlayerAlive(target)) {
					switch (GetClientTeam(target)) {
						case 2: {
							StatsConditionPatch(true);
							L4D_RespawnPlayer(target);
							StatsConditionPatch(false);
							TeleportToSurvivor(target);
							RespawnPlayer(client, menu.Selection);
						}

						case 3:
							SelectClassMenu(client, target, 0);
					}
				}
			}
			if(g_bRPG) L4D_RPG_SetGlobalValue(INDEX_VALID, false);
		}

		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack)
				Miscell(client, 0);
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

void SelectClassMenu(int client, int target, int item) {
	char info[32];
	char str[2][16];
	Menu menu = new Menu(SelectClass_MenuHandler);
	menu.SetTitle("目标特感类型");
	FormatEx(str[0], sizeof str[], "%d", GetClientUserId(target));
	for (int i; i < 7; i++) {
		FormatEx(str[1], sizeof str[], "%d", i);
		ImplodeStrings(str, sizeof str, "|", info, sizeof info);
		menu.AddItem(info, g_sZombieClass[i]);
	}
	menu.ExitButton = true;
	menu.ExitBackButton = false;
	menu.DisplayAt(client, item, MENU_TIME_FOREVER);
}

int SelectClass_MenuHandler(Menu menu, MenuAction action, int client, int param2) {
	switch (action) {
		case MenuAction_Select: {
			char item[32];
			menu.GetItem(param2, item, sizeof item);
			char info[2][16];
			ExplodeString(item, "|", info, sizeof info, sizeof info[]);
			int target = GetClientOfUserId(StringToInt(info[0]));
			if (target && IsClientInGame(target) && !IsFakeClient(target)) {
				if (GetClientTeam(target) == 3 && !IsPlayerAlive(target))
					RespawnPZ(target, StringToInt(info[1]));

				SelectClassMenu(client, target, menu.Selection);
			}
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

void RespawnPZ(int client, int zombieClass) {
	L4D_State_Transition(client, STATE_GHOST);
	L4D_SetClass(client, zombieClass != 6 ? zombieClass + 1 : 8);
}

void TeleportToSurvivor(int client) {
	int target = 1;
	ArrayList al_clients = new ArrayList(2);

	for (; target <= MaxClients; target++) {
		if (target == client || !IsClientInGame(target) || GetClientTeam(target) != 2 || !IsPlayerAlive(target))
			continue;
	
		al_clients.Set(al_clients.Push(!L4D_IsPlayerIncapacitated(target) ? 0 : !L4D_IsPlayerHangingFromLedge(target) ? 1 : 2), target, 1);
	}

	if (!al_clients.Length)
		target = 0;
	else {
		al_clients.Sort(Sort_Descending, Sort_Integer);

		target = al_clients.Length - 1;
		target = al_clients.Get(GetRandomInt(al_clients.FindValue(al_clients.Get(target, 0)), target), 1);
	}

	delete al_clients;

	if (target) {
		ForceCrouch(client);
		float vPos[3];
		GetClientAbsOrigin(target, vPos);
		TeleportEntity(client, vPos, NULL_VECTOR, NULL_VECTOR);
	}

	char buffer[64];
	g_aMeleeScripts.GetString(GetRandomInt(0, g_aMeleeScripts.Length - 1), buffer, sizeof buffer);
	Format(buffer, sizeof buffer, "give %s", buffer);
	CheatCommand(client, buffer);
	CheatCommand(client, "give smg");
}

void SetFriendlyFire(int client) {
	Menu menu = new Menu(SetFriendlyFire_MenuHandler);
	menu.SetTitle("友伤");
	menu.AddItem("999", "恢复默认");
	menu.AddItem("0.0", "0.0(简单)");
	menu.AddItem("0.1", "0.1(普通)");
	menu.AddItem("0.2", "0.2");
	menu.AddItem("0.3", "0.3(困难)");
	menu.AddItem("0.4", "0.4");
	menu.AddItem("0.5", "0.5(专家)");
	menu.AddItem("0.6", "0.6");
	menu.AddItem("0.7", "0.7");
	menu.AddItem("0.8", "0.8");
	menu.AddItem("0.9", "0.9");
	menu.AddItem("1.0", "1.0");
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int SetFriendlyFire_MenuHandler(Menu menu, MenuAction action, int client, int param2) {
	switch (action) {
		case MenuAction_Select: {
			char item[12];
			menu.GetItem(param2, item, sizeof item);
			switch (param2) {
				case 0: {
					FindConVar("survivor_friendly_fire_factor_easy").RestoreDefault();
					FindConVar("survivor_friendly_fire_factor_normal").RestoreDefault();
					FindConVar("survivor_friendly_fire_factor_hard").RestoreDefault();
					FindConVar("survivor_friendly_fire_factor_expert").RestoreDefault();
					PrintToChat(client, "友伤系数已被重置为默认值");
				}

				default: {
					float fPercent = StringToFloat(item);
					FindConVar("survivor_friendly_fire_factor_easy").SetFloat(fPercent);
					FindConVar("survivor_friendly_fire_factor_normal").SetFloat(fPercent);
					FindConVar("survivor_friendly_fire_factor_hard").SetFloat(fPercent);
					FindConVar("survivor_friendly_fire_factor_expert").SetFloat(fPercent);
					PrintToChat(client, "\x01友伤系数已被设置为 \x04%.1f", fPercent);
				}
			}
			Miscell(client, 0);
		}
	
		case MenuAction_Cancel:{
			if (param2 == MenuCancel_ExitBack)
				Miscell(client, 0);
		}
	
		case MenuAction_End:
			delete menu;
	}

	return 0;
}

void TeleportPlayer(int client, int item) {
	char info[12];
	char disp[MAX_NAME_LENGTH];
	Menu menu = new Menu(TeleportPlayer_MenuHandler);
	menu.SetTitle("传送谁");
	menu.AddItem("s", "所有生还者");
	menu.AddItem("i", "所有感染者");
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && IsPlayerAlive(i)) {
			FormatEx(info, sizeof info, "%d", GetClientUserId(i));
			FormatEx(disp, sizeof disp, "%N", i);
			menu.AddItem(info, disp);
		}
	}
	menu.ExitBackButton = true;
	menu.DisplayAt(client, item, MENU_TIME_FOREVER);
}

int TeleportPlayer_MenuHandler(Menu menu, MenuAction action, int client, int param2) {
	switch (action) {
		case MenuAction_Select: {
			char item[12];
			menu.GetItem(param2, item, sizeof item);
			g_iSelection[client] = menu.Selection;
			TeleportTarget(client, item);
		}
	
		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack)
				Miscell(client, 0);
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

void TeleportTarget(int client, const char[] sTarget) {
	char info[32];
	char str[2][16];
	char disp[MAX_NAME_LENGTH];
	Menu menu = new Menu(iTeleportTarget_MenuHandler);
	menu.SetTitle("传送到哪里");
	strcopy(str[0], sizeof str[], sTarget);
	strcopy(str[1], sizeof str[], "c");
	ImplodeStrings(str, sizeof str, "|", info, sizeof info);
	menu.AddItem(info, "鼠标指针处");
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && IsPlayerAlive(i)) {
			FormatEx(str[1], sizeof str[], "%d", GetClientUserId(i));
			ImplodeStrings(str, sizeof str, "|", info, sizeof info);
			FormatEx(disp, sizeof disp, "%N", i);
			menu.AddItem(info, disp);
		}
	}
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int iTeleportTarget_MenuHandler(Menu menu, MenuAction action, int client, int param2)
{
	switch (action) {
		case MenuAction_Select: {
			char item[32];
			menu.GetItem(param2, item, sizeof item);
			char info[2][16];
			bool allow;
			float vOrigin[3];
			ExplodeString(item, "|", info, sizeof info, sizeof info[]);
			int victim = GetClientOfUserId(StringToInt(info[0]));
			int targetTeam;
			if (info[0][0] == 's')
				targetTeam = 2;
			else if (info[0][0] == 'i')
				targetTeam = 3;
			else if (victim && IsClientInGame(victim))
				targetTeam = GetClientTeam(victim);

			if (info[1][0] == 'c')
				allow = GetTeleportEndPoint(client, vOrigin);
			else {
				int target = GetClientOfUserId(StringToInt(info[1]));
				if (target && IsClientInGame(target)) {
					GetClientAbsOrigin(target, vOrigin);
					allow = true;
				}
			}

			if (allow) {
				if (victim) {
					ForceCrouch(victim);
					TeleportFix(victim);
					TeleportEntity(victim, vOrigin, NULL_VECTOR, NULL_VECTOR);
				}
				else {
					switch (targetTeam) {
						case 2: {
							for (int i = 1; i <= MaxClients; i++) {
								if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i)) {
									ForceCrouch(i);
									TeleportFix(i);
									TeleportEntity(i, vOrigin, NULL_VECTOR, NULL_VECTOR);
								}
							}
						}
							
						case 3: {
							for (int i = 1; i <= MaxClients; i++) {
								if (IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i)) {
									ForceCrouch(i);
									TeleportEntity(i, vOrigin, NULL_VECTOR, NULL_VECTOR);
								}
							}
						}
					}
				}
			}
			else if (info[1][0] == 'c')
				PrintToChat(client, "获取准心处位置失败! 请重新尝试.");
	
			TeleportPlayer(client, g_iSelection[client]);
		}
	
		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack)
				TeleportPlayer(client, g_iSelection[client]);
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

void ForceCrouch(int client) {
	SetEntProp(client, Prop_Send, "m_bDucked", 1);
	SetEntProp(client, Prop_Send, "m_fFlags", GetEntProp(client, Prop_Send, "m_fFlags")|FL_DUCKING);
}

bool GetTeleportEndPoint(int client, float vPos[3]) {
	float vAng[3];
	GetClientEyeAngles(client, vAng);
	GetClientEyePosition(client, vPos);

	Handle hndl = TR_TraceRayFilterEx(vPos, vAng, MASK_PLAYERSOLID, RayType_Infinite, TraceEntityFilter);
	if (TR_DidHit(hndl)) {
		float vEnd[3];
		TR_GetEndPosition(vEnd, hndl);
		delete hndl;

		float vVec[3];
		MakeVectorFromPoints(vPos, vEnd, vVec);

		float vDown[3];
		float dist = GetVectorLength(vVec);
		while (dist > 0.0) {
			hndl = TR_TraceHullFilterEx(vEnd, vEnd, view_as<float>({-16.0, -16.0, 0.0}), view_as<float>({16.0, 16.0, 72.0}), MASK_PLAYERSOLID, TraceEntityFilter);
			if (!TR_DidHit(hndl)) {
				delete hndl;
				vPos = vEnd;
				return true;
			}

			delete hndl;

			dist -= 35.0;
			if (dist <= 0.0)
				break;

			NormalizeVector(vVec, vVec);
			ScaleVector(vVec, dist);
			AddVectors(vPos, vVec, vEnd);

			vDown[0] = vEnd[0];
			vDown[1] = vEnd[1];
			vDown[2] = vEnd[2] - 100000.0;
			hndl = TR_TraceHullFilterEx(vEnd, vDown, view_as<float>({-16.0, -16.0, 0.0}), view_as<float>({16.0, 16.0, 72.0}), MASK_PLAYERSOLID, TraceEntityFilter);
			if (TR_DidHit(hndl))
				TR_GetEndPosition(vEnd, hndl);
			else {
				dist -= 35.0;
				if (dist <= 0.0) {
					delete hndl;
					break;
				}

				NormalizeVector(vVec, vVec);
				ScaleVector(vVec, dist);
				AddVectors(vPos, vVec, vEnd);
			}

			delete hndl;
		}
	}

	delete hndl;
	GetClientAbsOrigin(client, vPos);
	return true;
}

bool TraceEntityFilter(int entity, int contentsMask) {
	if (!entity || entity > MaxClients) {
		static char cls[5];
		GetEdictClassname(entity, cls, sizeof cls);
		return cls[3] != 'e' && cls[3] != 'c';
	}

	return false;
}

void TeleportFix(int client) {
	if (GetClientTeam(client) != 2)
		return;

	SetEntityMoveType(client, MOVETYPE_WALK);
	SetEntProp(client, Prop_Send, "m_fFlags", GetEntProp(client, Prop_Send, "m_fFlags") & ~FL_FROZEN);

	if (L4D_IsPlayerHangingFromLedge(client))
		L4D_ReviveSurvivor(client);
	else {
		int attacker = L4D2_GetInfectedAttacker(client);
		if (attacker > 0 && IsClientInGame(attacker) && IsPlayerAlive(attacker)) {
			L4D_CleanupPlayerState(attacker);
			ForcePlayerSuicide(attacker);
		}
	}
}

void GodMode(int client, int item) {
	char info[12];
	char disp[MAX_NAME_LENGTH];
	Menu menu = new Menu(GodMode_MenuHandler);
	menu.SetTitle("目标玩家");
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == 2) {
			FormatEx(info, sizeof info, "%d", GetClientUserId(i));
			FormatEx(disp, sizeof disp, "[%s] - %N", g_bGodMode[i] ? "●" : "○", i);
			menu.AddItem(info, disp);
		}
	}
	menu.ExitBackButton = true;
	menu.DisplayAt(client, item, MENU_TIME_FOREVER);
}

int GodMode_MenuHandler(Menu menu, MenuAction action, int client, int param2) {
	switch (action) {
		case MenuAction_Select: {
			char item[12];
			menu.GetItem(param2, item, sizeof item);
			int target = GetClientOfUserId(StringToInt(item));
			if (target && IsClientInGame(target)) {
				g_bGodMode[target] = !g_bGodMode[target];
				PrintToChat(client, "\x04已%s \x05%N \x01的伤害免疫", g_bGodMode[target] ? "启用" : "禁用", target);
			}
			else
				PrintToChat(client, "目标玩家已失效");

			GodMode(client, menu.Selection);
		}

		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack)
				Miscell(client, g_iSelection[client]);
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

void ForcePanicEvent(int client) {
	L4D_ResetMobTimer();
	L4D_ForcePanicEvent();
	Miscell(client, g_iSelection[client]);
}

void KickAllSurBot(int client) {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 2)
			KickClient(i);
	}
	Miscell(client, g_iSelection[client]);
}

void SlayAllSI(int client) {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i))
			ForcePlayerSuicide(i);
	}
	if(g_bRPG) L4D_RPG_SetGlobalValue(INDEX_VALID, false);
	Miscell(client, g_iSelection[client]);
}

void IgnoreAbility(int client, int item) {
	char info[12];
	char disp[MAX_NAME_LENGTH];
	Menu menu = new Menu(IgnoreAbility_MenuHandler);
	menu.SetTitle("目标玩家");
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == 2) {
			FormatEx(info, sizeof info, "%d", GetClientUserId(i));
			FormatEx(disp, sizeof disp, "[%s] - %N", g_bIgnoreAbility[i] ? "●" : "○", i);
			menu.AddItem(info, disp);
		}
	}
	menu.ExitBackButton = true;
	menu.DisplayAt(client, item, MENU_TIME_FOREVER);
}

int IgnoreAbility_MenuHandler(Menu menu, MenuAction action, int client, int param2) {
	switch (action) {
		case MenuAction_Select: {
			char item[12];
			menu.GetItem(param2, item, sizeof item);
			int target = GetClientOfUserId(StringToInt(item));
			if (target && IsClientInGame(target)) {
				g_bIgnoreAbility[target] = !g_bIgnoreAbility[target];
				PrintToChat(client, "\x04已%s \x05%N \x01的特感控制免疫", g_bIgnoreAbility[target] ? "启用" : "禁用", target);
			}
			else
				PrintToChat(client, "目标玩家已失效");

			IgnoreAbility(client, menu.Selection);
		}

		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack)
				Miscell(client, g_iSelection[client]);
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

void SlayAllSur(int client) {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
			ForcePlayerSuicide(i);
	}
	Miscell(client, g_iSelection[client]);
}

void WarpAllSurToStartArea(int client) {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
			CheatCommand(i, "warp_to_start_area");
	}
	Miscell(client, g_iSelection[client]);
}

void WarpAllSurToCheckpoint(int client) {
	if (g_hSDK_TerrorNavMesh_GetLastCheckpoint && g_hSDK_Checkpoint_GetLargestArea) {
		Address pLastCheckpoint = SDKCall(g_hSDK_TerrorNavMesh_GetLastCheckpoint, L4D_GetPointer(POINTER_NAVMESH));
		if (pLastCheckpoint) {
			int navArea = SDKCall(g_hSDK_Checkpoint_GetLargestArea, pLastCheckpoint);
			if (navArea) {
				float vPos[3];
				for (int i = 1; i <= MaxClients; i++) {
					if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i)) {
						L4D_FindRandomSpot(navArea, vPos);
						TeleportEntity(i, vPos, NULL_VECTOR, NULL_VECTOR);
					}
				}
				if(g_bRPG) L4D_RPG_SetGlobalValue(INDEX_USEBUY, true);
				if(g_bRPG) L4D_RPG_SetGlobalValue(INDEX_VALID, false);
				Miscell(client, g_iSelection[client]);
				return;
			}
		}
	}
	ExecuteCommand("warp_all_survivors_to_checkpoint");
	Miscell(client, g_iSelection[client]);
}

void ExecuteCommand(const char[] command, const char[] value = "") {
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	ServerCommand("%s %s", command, value);
	ServerExecute();
	SetCommandFlags(command, flags);
}

void SwitchTeam(int client, int item) {
	char info[12];
	char disp[PLATFORM_MAX_PATH];
	Menu menu = new Menu(SwitchTeam_MenuHandler);
	menu.SetTitle("目标玩家");

	for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;
	
		FormatEx(info, sizeof info, "%d", GetClientUserId(i));
		FormatEx(disp, sizeof disp, "%N", i);
		switch (GetClientTeam(i)) {
			case 1:
				Format(disp, sizeof disp, "%s - %s", GetBotOfIdlePlayer(i) ? "闲置" : "观众", disp);

			case 2:
				Format(disp, sizeof disp, "生还 - %s", disp);
					
			case 3:
				Format(disp, sizeof disp, "感染 - %s", disp);
		}

		menu.AddItem(info, disp);
	}
	menu.ExitBackButton = true;
	menu.DisplayAt(client, item, MENU_TIME_FOREVER);
}

int SwitchTeam_MenuHandler(Menu menu, MenuAction action, int client, int param2) {
	switch (action) {
		case MenuAction_Select: {
			char item[12];
			menu.GetItem(param2, item, sizeof item);
			g_iSelection[client] = menu.Selection;

			int target = GetClientOfUserId(StringToInt(item));
			if (target && IsClientInGame(target))
				SwitchPlayerTeam(client, target);
			else
				PrintToChat(client, "目标玩家已失效");
		}

		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack)
				Rygive(client);
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

void SwitchPlayerTeam(int client, int target) {
	char info[32];
	char str[2][16];
	Menu menu = new Menu(SwitchPlayerTeam_MenuHandler);
	menu.SetTitle("目标队伍");
	FormatEx(str[0], sizeof str[], "%d", GetClientUserId(target));

	int team;
	if (!GetBotOfIdlePlayer(target))
		team = GetClientTeam(target);

	for (int i; i < sizeof g_iTargetTeam; i++) {
		if (team == i || (team != 2 && i == 0))
			continue;

		IntToString(g_iTargetTeam[i], str[1], sizeof str[]);
		ImplodeStrings(str, sizeof str, "|", info, sizeof info);
		menu.AddItem(info, g_sTargetTeam[i]);
	}

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int SwitchPlayerTeam_MenuHandler(Menu menu, MenuAction action, int client, int param2) {
	switch (action) {
		case MenuAction_Select: {
			char item[12];
			menu.GetItem(param2, item, sizeof item);
			char info[2][16];
			ExplodeString(item, "|", info, sizeof info, sizeof info[]);
			int target = GetClientOfUserId(StringToInt(info[0]));
			if (target && IsClientInGame(target)) {
				int team;
				if (!GetBotOfIdlePlayer(target))
					team = GetClientTeam(target);

				int targetTeam = StringToInt(info[1]);
				if (team != targetTeam) {
					switch (targetTeam) {
						case 0: {
							if (team == 2)
								GoAFKTimer(target, 0.0);
							else
								PrintToChat(client, "只有生还者才能进行闲置");
						}

						case 1: {
							if (team == 0)
								L4D_TakeOverBot(target);

							ChangeClientTeam(target, targetTeam);
						}

						case 2:
							{
								if(IsSuivivorTeamFull())
									PrintToChat(client, "生还已满");
								else
									ChangeTeamToSurvivor(target, team);
							}

						case 3:
							{
								if(IsInfectTeamFull())
									PrintToChat(client, "感染者已满");
								else
									ChangeClientTeam(target, targetTeam);
							}
					}
				}
				else
					PrintToChat(client, "玩家已在目标队伍中");
						
				SwitchTeam(client, g_iSelection[client]);
			}
			else
				PrintToChat(client, "目标玩家已失效");
		}
	
		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack)
				SwitchTeam(client, g_iSelection[client]);
		}
	
		case MenuAction_End:
			delete menu;
	}

	return 0;
}

//判断生还是否已经满人
stock bool IsSuivivorTeamFull() 
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && IsFakeClient(i))
		{
			return false;
		}
	}
	return true;
}

//判断特感是否已经满人
stock bool IsInfectTeamFull() 
{
	int count = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 3)
		{
			count ++;
		}
	}
	if(count >= FindConVar("z_max_player_zombies").IntValue){
		return true;
	}		
	else
	{
		return false;
	}
}

void ChangeTeamToSurvivor(int client, int team) {
	if (GetEntProp(client, Prop_Send, "m_isGhost"))
		SetEntProp(client, Prop_Send, "m_isGhost", 0);

	if (team != 1)
		ChangeClientTeam(client, 1);

	if (GetBotOfIdlePlayer(client)) {
		L4D_TakeOverBot(client);
		return;
	}

	int bot = FindAliveSurBot();
	if (bot) {
		L4D_SetHumanSpec(bot, client);
		L4D_TakeOverBot(client);
	}
	else
		ChangeClientTeam(client, 2);
}

int FindAliveSurBot() {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsAliveSurBot(i)) 
			return i;
	}
	return 0;
}

bool IsAliveSurBot(int client) {
	return IsClientInGame(client) && !IsClientInKickQueue(client) && IsFakeClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && !GetIdlePlayerOfBot(client);
}

int GetBotOfIdlePlayer(int client) {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 2 && GetIdlePlayerOfBot(i) == client)
			return i;
	}
	return 0;
}

int GetIdlePlayerOfBot(int client) {
	if (!HasEntProp(client, Prop_Send, "m_humanSpectatorUserID"))
		return 0;

	return GetClientOfUserId(GetEntProp(client, Prop_Send, "m_humanSpectatorUserID"));
}

void SpeedUp(int client, int item) {
	Menu menu = new Menu(SpeedUp_MenuHandler);
	menu.SetTitle("倍率");
	menu.AddItem("1.0", "1.0(恢复默认)");
	menu.AddItem("1.1", "1.1x");
	menu.AddItem("1.2", "1.2x");
	menu.AddItem("1.3", "1.3x");
	menu.AddItem("1.4", "1.4x");
	menu.AddItem("1.5", "1.5x");
	menu.AddItem("1.6", "1.6x");
	menu.AddItem("1.7", "1.7x");
	menu.AddItem("1.8", "1.8x");
	menu.AddItem("1.9", "1.9x");
	menu.AddItem("2.0", "2.0x");
	menu.AddItem("2.1", "2.1x");
	menu.AddItem("2.2", "2.2x");
	menu.AddItem("2.3", "2.3x");
	menu.AddItem("2.4", "2.4x");
	menu.AddItem("2.5", "2.5x");
	menu.AddItem("2.6", "2.6x");
	menu.AddItem("2.7", "2.7x");
	menu.AddItem("2.8", "2.8x");
	menu.AddItem("2.9", "2.9x");
	menu.AddItem("3.0", "3.0x");
	menu.AddItem("3.1", "3.1x");
	menu.AddItem("3.2", "3.2x");
	menu.AddItem("3.3", "3.3x");
	menu.AddItem("3.4", "3.4x");
	menu.AddItem("3.5", "3.5x");
	menu.ExitBackButton = true;
	menu.DisplayAt(client, item, MENU_TIME_FOREVER);
}

int SpeedUp_MenuHandler(Menu menu, MenuAction action, int client, int param2) {
	switch (action) {
		case MenuAction_Select: {
			char item[12];
			menu.GetItem(param2, item, sizeof item);
			g_iSelection[client] = menu.Selection;
			WeaponSpeedUp(client, item);
		}

		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack)
				Rygive(client);
		}
	
		case MenuAction_End:
			delete menu;
	}

	return 0;
}

void WeaponSpeedUp(int client, const char[] speedUp) {
	char info[32];
	char str[2][16];
	char disp[MAX_NAME_LENGTH];
	Menu menu = new Menu(WeaponSpeedUp_MenuHandler);
	menu.SetTitle("目标玩家");
	strcopy(str[0], sizeof str[], speedUp);
	strcopy(str[1], sizeof str[], "a");
	ImplodeStrings(str, sizeof str, "|", info, sizeof info);
	menu.AddItem(info, "所有");
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			FormatEx(str[1], sizeof str[], "%d", GetClientUserId(i));
			FormatEx(disp, sizeof disp, "[%.1fx] - %N", g_fSpeedUp[i], i);
			ImplodeStrings(str, sizeof str, "|", info, sizeof info);
			menu.AddItem(info, disp);
		}
	}
	if(g_bRPG) L4D_RPG_SetGlobalValue(INDEX_VALID, false);
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int WeaponSpeedUp_MenuHandler(Menu menu, MenuAction action, int client, int param2) {
	switch (action) {
		case MenuAction_Select: {
			char item[12];
			menu.GetItem(param2, item, sizeof item);
			char info[2][16];
			ExplodeString(item, "|", info, sizeof info, sizeof info[]);
			float fSpeedUp = StringToFloat(info[0]);
			if (info[1][0] == 'a') {
				for (int i = 1; i <= MaxClients; i++) {
					if (IsClientInGame(i))
						g_fSpeedUp[i] = fSpeedUp;
				}
				PrintToChat(client, "\x05所有玩家 \x01的武器操纵性已被设置为 \x04%.1fx", fSpeedUp);
				Rygive(client);
			}
			else {
				int target = GetClientOfUserId(StringToInt(info[1]));
				if (target && IsClientInGame(target)) {
						g_fSpeedUp[target] = fSpeedUp;
						PrintToChat(client, "\x05%N \x01的武器操纵性已被设置为 \x04%.1fx", target, fSpeedUp);
				}
				else
					PrintToChat(client, "目标玩家已失效");
						
				SpeedUp(client, g_iSelection[client]);
			}
		}

		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack)
				SpeedUp(client, g_iSelection[client]);
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

void DebugMode(int client) {
	if (g_bDebugMode) {
		g_bDebugMode = false;
		g_smSteamIDs.Clear();
		ReplyToCommand(client, "调试模式已关闭.");
	}
	else {
		char sSteamID[32];
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i) && !IsFakeClient(i)) {
				if (GetClientAuthId(i, AuthId_Steam2, sSteamID, sizeof sSteamID))
					g_smSteamIDs.SetValue(sSteamID, true, true);
			}
		}

		g_bDebugMode = true;
		ReplyToCommand(client, "调试模式已开启.");
	}
	
	Rygive(client);
}

void ShowAliveSur(int client) {
	char info[12];
	char disp[MAX_NAME_LENGTH];
	Menu menu = new Menu(ShowAliveSur_MenuHandler);
	menu.SetTitle("目标玩家");
	menu.AddItem("a", "所有");
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i)) {
			FormatEx(info, sizeof info, "%d", GetClientUserId(i));
			FormatEx(disp, sizeof disp, "%N", i);
			menu.AddItem(info, disp);
		}
	}
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int ShowAliveSur_MenuHandler(Menu menu, MenuAction action, int client, int param2) {
	switch (action) {
		case MenuAction_Select: {
			char item[12];
			menu.GetItem(param2, item, sizeof item);
			if (item[0] == 'a') {
				for (int i = 1; i <= MaxClients; i++) {
					if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
						CheatCommand(i, g_sNamedItem[client]);
				}
			}
			else
				CheatCommand(GetClientOfUserId(StringToInt(item)), g_sNamedItem[client]);
			
			if(g_bRPG){
				if(IsAnne() == 1)
					L4D_RPG_SetGlobalValue(INDEX_USEBUY, true);
				else if(IsAnne() == 2)
					L4D_RPG_SetGlobalValue(INDEX_VALID, true);
			}
			PageExitBack(client, g_iFunction[client], g_iSelection[client]);
		}

		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack)
				PageExitBack(client, g_iFunction[client], g_iSelection[client]);
		}
	
		case MenuAction_End:
			delete menu;
	}

	return 0;
}

stock int IsAnne(){
	char plugin_name[1024];
	ConVar cvar_mode;
	if(cvar_mode == null && FindConVar("l4d_ready_cfg_name"))
	{
		cvar_mode = FindConVar("l4d_ready_cfg_name");
	}
	if(cvar_mode == null) return 0;
	GetConVarString(cvar_mode, plugin_name, sizeof(plugin_name));
	if(StrContains(plugin_name, "AnneHappy", false) != -1)
	{
		if(StrContains(plugin_name, "HardCore", false) != -1)
			return 2;
		else
			return 1;
	}else
	{
		return 0;
	}
}

void PageExitBack(int client, int func, int item) {
	switch (func) {
		case 1:
			Gun(client, item);
		case 2:
			Melee(client, item);
		case 3:
			Item(client, item);
	}
}

void ReloadAmmo(int client) {
	int weapon = GetPlayerWeaponSlot(client, 0);
	if (weapon <= MaxClients || !IsValidEntity(weapon))
		return;

	int m_iPrimaryAmmoType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	if (m_iPrimaryAmmoType == -1)
		return;

	char cls[32];
	GetEntityClassname(weapon, cls, sizeof cls);
	if (strcmp(cls, "weapon_rifle_m60") == 0) {
		static ConVar cM60;
		if (!cM60)
			cM60 = FindConVar("ammo_m60_max");

		SetEntProp(weapon, Prop_Send, "m_iClip1", L4D2_GetIntWeaponAttribute(cls, L4D2IWA_ClipSize));
		SetEntProp(client, Prop_Send, "m_iAmmo", cM60.IntValue, _, m_iPrimaryAmmoType);
	}
	else if (strcmp(cls, "weapon_grenade_launcher") == 0) {
		static ConVar cGrenadelau;
		if (!cGrenadelau)
			cGrenadelau = FindConVar("ammo_grenadelauncher_max");

		SetEntProp(weapon, Prop_Send, "m_iClip1", L4D2_GetIntWeaponAttribute(cls, L4D2IWA_ClipSize));
		SetEntProp(client, Prop_Send, "m_iAmmo", cGrenadelau.IntValue, _, m_iPrimaryAmmoType);
	}
}

void CheatCommand(int client, const char[] command) {
	if (!client || !IsClientInGame(client))
		return;

	char cmd[32];
	if (SplitString(command, " ", cmd, sizeof cmd) == -1)
		strcopy(cmd, sizeof cmd, command);

	if (strcmp(cmd, "give") == 0 && strcmp(command[5], "health") == 0) {
		int attacker = L4D2_GetInfectedAttacker(client);
		if (attacker > 0 && IsClientInGame(attacker) && IsPlayerAlive(attacker)) {
			L4D_CleanupPlayerState(attacker);
			ForcePlayerSuicide(attacker);
		}
	}
	if (strcmp(cmd, "give") == 0 && (strcmp(command[5], "health") == 0 || strcmp(command[5], "first_") == 0 || strcmp(command[5], "defibr") == 0 || strcmp(command[5], "adrena") == 0 || strcmp(command[5], "pain_p") == 0) && (g_bRPG && L4D_RPG_GetGlobalValue(INDEX_VALID))) 
	{
		L4D_RPG_SetGlobalValue(INDEX_VALID, false);
		PrintToChatAll("\x01管理员使用回血或刷回血道具功能，此局将无法再获得特感分和额外过关分数");
	}

	int bits = GetUserFlagBits(client);
	int flags = GetCommandFlags(cmd);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	SetCommandFlags(cmd, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, command);
	SetUserFlagBits(client, bits);
	SetCommandFlags(cmd, flags);
	
	if (strcmp(cmd, "give") == 0) {
		if (strcmp(command[5], "health") == 0)
			L4D_SetPlayerTempHealth(client, 0); //防止有虚血时give health会超过100血
		else if (strcmp(command[5], "ammo") == 0)
			ReloadAmmo(client); //榴弹发射器加子弹
	}
}

void GoAFKTimer(int client, float flDuration) {
	static int m_GoAFKTimer = -1;
	if (m_GoAFKTimer == -1)
		m_GoAFKTimer = FindSendPropInfo("CTerrorPlayer", "m_lookatPlayer") - 12;

	SetEntDataFloat(client, m_GoAFKTimer + 4, flDuration);
	SetEntDataFloat(client, m_GoAFKTimer + 8, GetGameTime() + flDuration);
}

void InitData() {
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof sPath, "gamedata/%s.txt", GAMEDATA);
	if (!FileExists(sPath))
		SetFailState("\n==========\nMissing required file: \"%s\".\n==========", sPath);

	GameData hGameData = new GameData(GAMEDATA);
	if (!hGameData)
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	g_iOff_m_nFallenSurvivors = hGameData.GetOffset("m_nFallenSurvivors");
	if (g_iOff_m_nFallenSurvivors == -1)
		SetFailState("Failed to find offset: m_nFallenSurvivors");

	g_iOff_m_FallenSurvivorTimer = hGameData.GetOffset("m_FallenSurvivorTimer");
	if (g_iOff_m_FallenSurvivorTimer == -1)
		SetFailState("Failed to find offset: m_FallenSurvivorTimer");

	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "TerrorNavMesh::GetLastCheckpoint"))
		LogError("Failed to find signature: \"TerrorNavMesh::GetLastCheckpoint\"");
	else {
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		if (!(g_hSDK_TerrorNavMesh_GetLastCheckpoint = EndPrepSDKCall()))
			LogError("Failed to create SDKCall: \"TerrorNavMesh::GetLastCheckpoint\"");
	}

	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "Checkpoint::GetLargestArea"))
		LogError("Failed to find signature: \"Checkpoint::GetLargestArea\"");
	else {
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		if (!(g_hSDK_Checkpoint_GetLargestArea = EndPrepSDKCall()))
			LogError("Failed to create SDKCall: \"Checkpoint::GetLargestArea\"");
	}

	Address pReplaceWithBot = hGameData.GetAddress("NextBotCreatePlayerBot.jumptable");
	if (pReplaceWithBot != Address_Null && LoadFromAddress(pReplaceWithBot, NumberType_Int8) == 0x68)
		PrepWindowsCreateBotCalls(pReplaceWithBot);
	else
		PrepLinuxCreateBotCalls(hGameData);

	InitPatchs(hGameData);

	delete hGameData;
}

void InitPatchs(GameData hGameData = null) {
	int iOffset = hGameData.GetOffset("RoundRespawn_Offset");
	if (iOffset == -1)
		SetFailState("Failed to find offset: RoundRespawn_Offset");

	int iByteMatch = hGameData.GetOffset("RoundRespawn_Byte");
	if (iByteMatch == -1)
		SetFailState("Failed to find byte: RoundRespawn_Byte");

	g_pStatsCondition = hGameData.GetMemSig("CTerrorPlayer::RoundRespawn");
	if (!g_pStatsCondition)
		SetFailState("Failed to find address: CTerrorPlayer::RoundRespawn");
	
	g_pStatsCondition += view_as<Address>(iOffset);
	int iByteOrigin = LoadFromAddress(g_pStatsCondition, NumberType_Int8);
	if (iByteOrigin != iByteMatch)
		SetFailState("Failed to load 'CTerrorPlayer::RoundRespawn', byte mis-match @ %d (0x%02X != 0x%02X)", iOffset, iByteOrigin, iByteMatch);
}

//https://forums.alliedmods.net/showthread.php?t=323220
void StatsConditionPatch(bool patch) {
	static bool patched;
	if (!patched && patch) {
		patched = true;
		StoreToAddress(g_pStatsCondition, 0xEB, NumberType_Int8);
	}
	else if (patched && !patch)  {
		patched = false;
		StoreToAddress(g_pStatsCondition, 0x75, NumberType_Int8);
	}
}

void LoadStringFromAdddress(Address pAddr, char[] buffer, int maxlength) {
	int i;
	char val;
	while (i < maxlength) {
		val = LoadFromAddress(pAddr + view_as<Address>(i), NumberType_Int8);
		if (val == 0) {
			buffer[i] = '\0';
			break;
		}
		buffer[i++] = val;
	}
	buffer[maxlength - 1] = '\0';
}

Handle PrepCreateBotCallFromAddress(StringMap SiFuncHashMap, const char[] SIName) {
	Address pAddr;
	StartPrepSDKCall(SDKCall_Static);
	if (!SiFuncHashMap.GetValue(SIName, pAddr) || !PrepSDKCall_SetAddress(pAddr))
		SetFailState("Unable to find NextBotCreatePlayer<%s> address in memory.", SIName);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	return EndPrepSDKCall();	
}

void PrepWindowsCreateBotCalls(Address pJumpTableAddr) {
	StringMap hashMap = new StringMap();
	// We have the address of the jump table, starting at the first PUSH instruction of the
	// PUSH mem32 (5 bytes)
	// CALL rel32 (5 bytes)
	// JUMP rel8 (2 bytes)
	// repeated pattern.
	
	// Each push is pushing the address of a string onto the stack. Let's grab these strings to identify each case.
	// "Hunter" / "Smoker" / etc.
	for (int i; i < 7; i++) {
		// 12 bytes in PUSH32, CALL32, JMP8.
		Address pCaseBase = pJumpTableAddr + view_as<Address>(i * 12);
		Address pSIStringAddr = view_as<Address>(LoadFromAddress(pCaseBase + view_as<Address>(1), NumberType_Int32));
		char SIName[32];
		LoadStringFromAdddress(pSIStringAddr, SIName, sizeof SIName);

		Address pFuncRefAddr = pCaseBase + view_as<Address>(6); // 2nd byte of call, 5+1 byte offset.
		int funcRelOffset = LoadFromAddress(pFuncRefAddr, NumberType_Int32);
		Address pCallOffsetBase = pCaseBase + view_as<Address>(10); // first byte of next instruction after the CALL instruction
		Address pNextBotCreatePlayerBotTAddr = pCallOffsetBase + view_as<Address>(funcRelOffset);
		PrintToServer("Found NextBotCreatePlayerBot<%s>() @ %08x", SIName, pNextBotCreatePlayerBotTAddr);
		hashMap.SetValue(SIName, pNextBotCreatePlayerBotTAddr);
	}

	g_hSDK_NextBotCreatePlayerBot_Smoker = PrepCreateBotCallFromAddress(hashMap, "Smoker");
	if (!g_hSDK_NextBotCreatePlayerBot_Smoker)
		SetFailState("Cannot initialize %s SDKCall, address lookup failed.", NAME_CreateSmoker);

	g_hSDK_NextBotCreatePlayerBot_Boomer = PrepCreateBotCallFromAddress(hashMap, "Boomer");
	if (!g_hSDK_NextBotCreatePlayerBot_Boomer)
		SetFailState("Cannot initialize %s SDKCall, address lookup failed.", NAME_CreateBoomer);

	g_hSDK_NextBotCreatePlayerBot_Hunter = PrepCreateBotCallFromAddress(hashMap, "Hunter");
	if (!g_hSDK_NextBotCreatePlayerBot_Hunter)
		SetFailState("Cannot initialize %s SDKCall, address lookup failed.", NAME_CreateHunter);

	g_hSDK_NextBotCreatePlayerBot_Spitter = PrepCreateBotCallFromAddress(hashMap, "Spitter");
	if (!g_hSDK_NextBotCreatePlayerBot_Spitter)
		SetFailState("Cannot initialize %s SDKCall, address lookup failed.", NAME_CreateSpitter);
	
	g_hSDK_NextBotCreatePlayerBot_Jockey = PrepCreateBotCallFromAddress(hashMap, "Jockey");
	if (!g_hSDK_NextBotCreatePlayerBot_Jockey)
		SetFailState("Cannot initialize %s SDKCall, address lookup failed.", NAME_CreateJockey);

	g_hSDK_NextBotCreatePlayerBot_Charger = PrepCreateBotCallFromAddress(hashMap, "Charger");
	if (!g_hSDK_NextBotCreatePlayerBot_Charger)
		SetFailState("Cannot initialize %s SDKCall, address lookup failed.", NAME_CreateCharger);

	g_hSDK_NextBotCreatePlayerBot_Tank = PrepCreateBotCallFromAddress(hashMap, "Tank");
	if (!g_hSDK_NextBotCreatePlayerBot_Tank)
		SetFailState("Cannot initialize %s SDKCall, address lookup failed.", NAME_CreateTank);
}

void PrepLinuxCreateBotCalls(GameData hGameData = null) {
	StartPrepSDKCall(SDKCall_Static);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, NAME_CreateSmoker))
		SetFailState("Failed to find signature: %s", NAME_CreateSmoker);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	g_hSDK_NextBotCreatePlayerBot_Smoker = EndPrepSDKCall();
	if (!g_hSDK_NextBotCreatePlayerBot_Smoker)
		SetFailState("Failed to create SDKCall: %s", NAME_CreateSmoker);
	
	StartPrepSDKCall(SDKCall_Static);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, NAME_CreateBoomer))
		SetFailState("Failed to find signature: %s", NAME_CreateBoomer);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	g_hSDK_NextBotCreatePlayerBot_Boomer = EndPrepSDKCall();
	if (!g_hSDK_NextBotCreatePlayerBot_Boomer)
		SetFailState("Failed to create SDKCall: %s", NAME_CreateBoomer);
		
	StartPrepSDKCall(SDKCall_Static);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, NAME_CreateHunter))
		SetFailState("Failed to find signature: %s", NAME_CreateHunter);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	g_hSDK_NextBotCreatePlayerBot_Hunter = EndPrepSDKCall();
	if (!g_hSDK_NextBotCreatePlayerBot_Hunter)
		SetFailState("Failed to create SDKCall: %s", NAME_CreateHunter);
	
	StartPrepSDKCall(SDKCall_Static);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, NAME_CreateSpitter))
		SetFailState("Failed to find signature: %s", NAME_CreateSpitter);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	g_hSDK_NextBotCreatePlayerBot_Spitter = EndPrepSDKCall();
	if (!g_hSDK_NextBotCreatePlayerBot_Spitter)
		SetFailState("Failed to create SDKCall: %s", NAME_CreateSpitter);
	
	StartPrepSDKCall(SDKCall_Static);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, NAME_CreateJockey))
		SetFailState("Failed to find signature: %s", NAME_CreateJockey);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	g_hSDK_NextBotCreatePlayerBot_Jockey = EndPrepSDKCall();
	if (!g_hSDK_NextBotCreatePlayerBot_Jockey)
		SetFailState("Failed to create SDKCall: %s", NAME_CreateJockey);
		
	StartPrepSDKCall(SDKCall_Static);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, NAME_CreateCharger))
		SetFailState("Failed to find signature: %s", NAME_CreateCharger);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	g_hSDK_NextBotCreatePlayerBot_Charger = EndPrepSDKCall();
	if (!g_hSDK_NextBotCreatePlayerBot_Charger)
		SetFailState("Failed to create SDKCall: %s", NAME_CreateCharger);
		
	StartPrepSDKCall(SDKCall_Static);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, NAME_CreateTank))
		SetFailState("Failed to find signature: %s", NAME_CreateTank);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	g_hSDK_NextBotCreatePlayerBot_Tank = EndPrepSDKCall();
	if (!g_hSDK_NextBotCreatePlayerBot_Tank)
		SetFailState("Failed to create SDKCall: %s", NAME_CreateTank);
}

public Action L4D_OnGrabWithTongue(int victim, int attacker) {
	if (!g_bIgnoreAbility[victim])
		return Plugin_Continue;
/*	//处死即将控人的Smoker
	if (attacker > 0 && attacker < MaxClients && IsClientInGame(attacker))
		ForcePlayerSuicide(attacker);*/

	return Plugin_Handled;
}

public Action L4D_OnPouncedOnSurvivor(int victim, int attacker) {
	if (!g_bIgnoreAbility[victim])
		return Plugin_Continue;
/*	//处死即将控人的Hunter
	if (attacker > 0 && attacker < MaxClients && IsClientInGame(attacker))
		ForcePlayerSuicide(attacker);*/

	return Plugin_Handled;
}

public Action L4D2_OnJockeyRide(int victim, int attacker) {
	if (!g_bIgnoreAbility[victim])
		return Plugin_Continue;
/*	//处死即将控人的Jockey
	if (attacker > 0 && attacker < MaxClients && IsClientInGame(attacker))
		ForcePlayerSuicide(attacker);*/

	return Plugin_Handled;
}

public Action L4D2_OnStartCarryingVictim(int victim, int attacker) {
	if (!g_bIgnoreAbility[victim])
		return Plugin_Continue;
/*	//处死即将控人的Charger
	if (attacker > 0 && attacker < MaxClients && IsClientInGame(attacker))
		ForcePlayerSuicide(attacker);*/

	return Plugin_Handled;
}

public Action L4D2_OnPummelVictim(int attacker, int victim) {
	if (!g_bIgnoreAbility[victim])
		return Plugin_Continue;
/*	//处死即将控人的Charger
	if (attacker > 0 && attacker < MaxClients && IsClientInGame(attacker))
		ForcePlayerSuicide(attacker);*/

	// from "left4dhooks_test.sp"
	DataPack pack = new DataPack();
	RequestFrame(OnPummelTeleport, pack);
	pack.WriteCell(GetClientUserId(victim));
	pack.WriteCell(GetClientUserId(attacker));

	// To block the stumble animation, uncomment and use the following 2 lines:
	AnimHookEnable(victim, OnPummelOnAnimPre, INVALID_FUNCTION);
	CreateTimer(0.3, Timer_OnPummelResetAnim, GetClientUserId(victim));

	return Plugin_Handled;
}

// To fix getting stuck use this:
void OnPummelTeleport(DataPack pack) {
	pack.Reset();
	int victim = pack.ReadCell();
	int attacker = pack.ReadCell();
	delete pack;

	victim = GetClientOfUserId(victim);
	if (!victim || !IsClientInGame(victim))
		return;

	attacker = GetClientOfUserId(attacker);
	if (!attacker || !IsClientInGame(attacker))
		return;

	SetVariantString("!activator");
	AcceptEntityInput(victim, "SetParent", attacker);
	TeleportEntity(victim, view_as<float>({50.0, 0.0, 0.0}), NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(victim, "ClearParent");
}

// To block the stumble animation use the next two functions:
Action OnPummelOnAnimPre(int client, int &anim) {
	if (anim == L4D2_ACT_TERROR_SLAMMED_WALL || anim == L4D2_ACT_TERROR_SLAMMED_GROUND) {
		anim = L4D2_ACT_STAND;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

Action Timer_OnPummelResetAnim(Handle timer, int client) {
	if ((client = GetClientOfUserId(client)))
		AnimHookDisable(client, OnPummelOnAnimPre);

	return Plugin_Continue;
}

// ====================================================================================================
//					WEAPON HANDLING
// ====================================================================================================
public void WH_OnMeleeSwing(int client, int weapon, float &speedmodifier) {
	speedmodifier = SpeedModifier(client, speedmodifier); //send speedmodifier to be modified
}

public void WH_OnStartThrow(int client, int weapon, L4D2WeaponType weapontype, float &speedmodifier) {
	speedmodifier = SpeedModifier(client, speedmodifier);
}

public void WH_OnReadyingThrow(int client, int weapon, L4D2WeaponType weapontype, float &speedmodifier) {
	speedmodifier = SpeedModifier(client, speedmodifier);
}

public void WH_OnReloadModifier(int client, int weapon, L4D2WeaponType weapontype, float &speedmodifier) {
	speedmodifier = SpeedModifier(client, speedmodifier);
}

public void WH_OnGetRateOfFire(int client, int weapon, L4D2WeaponType weapontype, float &speedmodifier) {
	switch (weapontype) {
		case L4D2WeaponType_Rifle, L4D2WeaponType_RifleSg552, L4D2WeaponType_SMG, L4D2WeaponType_RifleAk47, L4D2WeaponType_SMGMp5, L4D2WeaponType_SMGSilenced, L4D2WeaponType_RifleM60:
			return;
	}

	speedmodifier = SpeedModifier(client, speedmodifier);
}

public void WH_OnDeployModifier(int client, int weapon, L4D2WeaponType weapontype, float &speedmodifier) {
	speedmodifier = SpeedModifier(client, speedmodifier);
}

float SpeedModifier(int client, float speedmodifier) {
	if (g_fSpeedUp[client] > 1.0)
		speedmodifier = speedmodifier * g_fSpeedUp[client];// multiply current modifier to not overwrite any existing modifiers already

	return speedmodifier;
}