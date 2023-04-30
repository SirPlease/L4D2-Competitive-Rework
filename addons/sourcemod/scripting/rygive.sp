#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define GAMEDATA			"rygive"
#define NAME_CreateSmoker	"NextBotCreatePlayerBot<Smoker>"
#define NAME_CreateBoomer	"NextBotCreatePlayerBot<Boomer>"
#define NAME_CreateHunter	"NextBotCreatePlayerBot<Hunter>"
#define NAME_CreateSpitter	"NextBotCreatePlayerBot<Spitter>"
#define NAME_CreateJockey	"NextBotCreatePlayerBot<Jockey>"
#define NAME_CreateCharger	"NextBotCreatePlayerBot<Charger>"
#define NAME_CreateTank		"NextBotCreatePlayerBot<Tank>"

StringMap
	g_smSteamIDs,
	g_smMeleeTrans;

ArrayList
	g_aMeleeScripts;

Handle
	g_hSDK_CTerrorPlayer_RoundRespawn,
	g_hSDK_SurvivorBot_SetHumanSpectator,
	g_hSDK_CTerrorPlayer_TakeOverBot,
	g_hSDK_CTerrorPlayer_CleanupPlayerState,
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
	g_iCurrentPage[MAXPLAYERS + 1],
	g_iOff_m_nFallenSurvivors,
	g_iOff_m_FallenSurvivorTimer;

static const int
	g_iTargetTeam[4] = {
		0,
		1,
		2,
		3
	};

float
	g_fSpeedUp[MAXPLAYERS + 1];

bool
	g_bDebug,
	g_bRespawnPZ,
	g_bWeaponHandling;

char
	g_sNamedItem[MAXPLAYERS + 1][64];

static const char
	g_sTargetTeam[4][] = {
		"闲置(仅生还)",
		"观众",
		"生还",
		"感染"
	},
	g_sZombieClass[7][] = {
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
}

public void OnLibraryRemoved(const char[] name) {
	if (strcmp(name, "WeaponHandling") == 0)
		g_bWeaponHandling = false;
}

native bool CZ_RespawnPZ(int client, int zombieClass);
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	MarkNativeAsOptional("CZ_RespawnPZ");
	return APLRes_Success;
}

public void OnAllPluginsLoaded() {
	g_bRespawnPZ = GetFeatureStatus(FeatureType_Native, "CZ_RespawnPZ") == FeatureStatus_Available;
}

public Plugin myinfo = {
	name = "Give Item Menu",
	description = "Gives Item Menu",
	author = "Ryanx, sorallll",
	version = "1.2.1",
};

public void OnPluginStart() {
	vInitData();
	g_smSteamIDs = new StringMap();
	g_smMeleeTrans = new StringMap();
	g_aMeleeScripts = new ArrayList(64);

	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
	RegAdminCmd("sm_rygive", cmdRygive, ADMFLAG_ROOT, "rygive");

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
}

public void OnPluginEnd() {
	vStatsConditionPatch(false);
}

public void OnClientDisconnect(int client) {
	g_fSpeedUp[client] = 1.0;
}

public void OnClientPostAdminCheck(int client) {
	if (!g_bDebug || IsFakeClient(client) || CheckCommandAccess(client, "", ADMFLAG_ROOT))
		return;

	char sSteamID[32];
	GetClientAuthId(client, AuthId_Steam2, sSteamID, sizeof sSteamID);
	bool bAllowed;
	if (!g_smSteamIDs.GetValue(sSteamID, bAllowed))
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

	vGetMeleeWeaponsStringTable();
}

void vGetMeleeWeaponsStringTable() {
	g_aMeleeScripts.Clear();

	int iTable = FindStringTable("meleeweapons");
	if (iTable != INVALID_STRING_TABLE) {
		int iNum = GetStringTableNumStrings(iTable);
		char sMeleeName[64];
		for (int i; i < iNum; i++) {
			ReadStringTable(iTable, i, sMeleeName, sizeof sMeleeName);
			g_aMeleeScripts.PushString(sMeleeName);
		}
	}
}

void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if ((!client || !IsFakeClient(client)) && !bRealPlayerExist(client)) {
		g_smSteamIDs.Clear();
		g_bDebug = false;
	}
}

bool bRealPlayerExist(int iExclude = 0) {
	for (int client = 1; client <= MaxClients; client++) {
		if (client != iExclude && IsClientConnected(client) && !IsFakeClient(client))
			return true;
	}
	return false;
}

Action cmdRygive(int client, int args) {
	if (!client || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Handled;

	vRygive(client);
	return Plugin_Handled;
}

void vRygive(int client) {
	Menu menu = new Menu(iRygive_MenuHandler);
	menu.SetTitle("- 多功能插件 -");
	menu.AddItem("w", "武器");
	menu.AddItem("i", "物品");
	menu.AddItem("z", "感染");
	menu.AddItem("m", "杂项");
	menu.AddItem("t", "团队控制");
	if (g_bWeaponHandling)
		menu.AddItem("c", "武器操纵性");
	if (iGetClientImmunityLevel(client) > 98) {
		if (g_bDebug == false)
			menu.AddItem("d", "开启调试模式");
		else
			menu.AddItem("d", "关闭调试模式");
	}
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int iGetClientImmunityLevel(int client) {
	char sSteamID[32];
	GetClientAuthId(client, AuthId_Steam2, sSteamID, sizeof sSteamID);
	AdminId admin = FindAdminByIdentity(AUTHMETHOD_STEAM, sSteamID);
	if (admin == INVALID_ADMIN_ID)
		return -999;

	return admin.ImmunityLevel;
}

int iRygive_MenuHandler(Menu menu, MenuAction action, int client, int param2) {
	switch (action) {
		case MenuAction_Select: {
			char sItem[2];
			menu.GetItem(param2, sItem, sizeof sItem);
			switch (sItem[0]) {
				case 'w':
					vWeapons(client);
				case 'i':
					vItems(client, 0);
				case 'z':
					vInfecteds(client, 0);
				case 'm':
					vMisc(client, 0);
				case 't':
					vTeamSwitch(client, 0);
				case 'c':
					vWeaponSpeed(client, 0);
				case 'd':
					vDebugMode(client);
			}
				
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

void vWeapons(int client) {
	Menu menu = new Menu(iWeapons_MenuHandler);
	menu.SetTitle("武器");
	menu.AddItem("0", "枪械");
	menu.AddItem("1", "近战");
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int iWeapons_MenuHandler(Menu menu, MenuAction action, int client, int param2) {
	switch (action) {
		case MenuAction_Select: {
			g_iCurrentPage[client] = menu.Selection;
			switch (param2) {
				case 0:
					vGuns(client, 0);
				case 1:
					vMelees(client, 0);
			}
		}

		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack)
				vRygive(client);
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

void vGuns(int client, int item) {
	Menu menu = new Menu(iGuns_MenuHandler);
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
	menu.AddItem("rifle_desert", "三连步枪");
	menu.AddItem("rifle_ak47", "AK47");
	menu.AddItem("rifle_sg552", "SG552");
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

int iGuns_MenuHandler(Menu menu, MenuAction action, int client, int param2) {
	switch (action) {
		case MenuAction_Select: {
			char sItem[64];
			menu.GetItem(param2, sItem, sizeof sItem);
			g_iFunction[client] = 1;
			g_iCurrentPage[client] = menu.Selection;
			FormatEx(g_sNamedItem[client], sizeof g_sNamedItem, "give %s", sItem);
			vShowAliveSur(client);
		}

		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack)
				vWeapons(client);
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

void vMelees(int client, int item) {
	Menu menu = new Menu(iMelees_MenuHandler);
	menu.SetTitle("近战");

	char sMelee[64];
	char sTrans[64];
	int iLength = g_aMeleeScripts.Length;
	for (int i; i < iLength; i++) {
		g_aMeleeScripts.GetString(i, sMelee, sizeof sMelee);
		if (!g_smMeleeTrans.GetString(sMelee, sTrans, sizeof sTrans))
			strcopy(sTrans, sizeof sTrans, sMelee);

		menu.AddItem(sMelee, sTrans);
	}
	menu.ExitBackButton = true;
	menu.DisplayAt(client, item, MENU_TIME_FOREVER);
}

int iMelees_MenuHandler(Menu menu, MenuAction action, int client, int param2) {
	switch (action) {
		case MenuAction_Select: {
			char sItem[64];
			menu.GetItem(param2, sItem, sizeof sItem);
			g_iFunction[client] = 2;
			g_iCurrentPage[client] = menu.Selection;
			FormatEx(g_sNamedItem[client], sizeof g_sNamedItem, "give %s", sItem);
			vShowAliveSur(client);
		}

		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack)
				vWeapons(client);
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

void vItems(int client, int item) {
	Menu menu = new Menu(iItems_MenuHandler);
	menu.SetTitle("物品");
	menu.AddItem("health", "生命值");
	menu.AddItem("molotov", "燃烧瓶");
	menu.AddItem("pipe_bomb", "管状炸弹");
	menu.AddItem("vomitjar", "胆汁瓶");
	menu.AddItem("first_aid_kit", "医疗包");
	menu.AddItem("defibrillator", "电击器");
	menu.AddItem("upgradepack_incendiary", "燃烧弹药包");
	menu.AddItem("upgradepack_explosive", "高爆弹药包");
	menu.AddItem("adrenaline", "肾上腺素");
	menu.AddItem("pain_pills", "止痛药");
	menu.AddItem("gascan", "汽油桶");
	menu.AddItem("propanetank", "煤气罐");
	menu.AddItem("oxygentank", "氧气瓶");
	menu.AddItem("fireworkcrate", "烟花箱");
	menu.AddItem("cola_bottles", "可乐瓶");
	menu.AddItem("gnome", "圣诞老人");
	menu.AddItem("ammo", "普通弹药");
	menu.AddItem("incendiary_ammo", "燃烧弹药");
	menu.AddItem("explosive_ammo", "高爆弹药");
	menu.AddItem("laser_sight", "激光瞄准器");
	menu.ExitBackButton = true;
	menu.DisplayAt(client, item, MENU_TIME_FOREVER);
}

int iItems_MenuHandler(Menu menu, MenuAction action, int client, int param2) {
	switch (action) {
		case MenuAction_Select: {
			char sItem[64];
			menu.GetItem(param2, sItem, sizeof sItem);
			g_iFunction[client] = 3;
			g_iCurrentPage[client] = menu.Selection;

			if (param2 < 17)
				FormatEx(g_sNamedItem[client], sizeof g_sNamedItem, "give %s", sItem);
			else
				FormatEx(g_sNamedItem[client], sizeof g_sNamedItem, "upgrade_add %s", sItem);
				
			vShowAliveSur(client);
		}
	
		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack)
				vRygive(client);
		}

		case MenuAction_End:
			delete menu;	
	}

	return 0;
}

void vInfecteds(int client, int item) {
	Menu menu = new Menu(iInfectedsMenuHandler);
	menu.SetTitle("感染");
	menu.AddItem("Smoker", "Smoker");
	menu.AddItem("Boomer", "Boomer");
	menu.AddItem("Hunter", "Hunter");
	menu.AddItem("Spitter", "Spitter");
	menu.AddItem("Jockey", "Jockey");
	menu.AddItem("Charger", "Charger");
	menu.AddItem("Tank", "Tank");
	menu.AddItem("Witch", "Witch");
	menu.AddItem("Witch_Bride", "Bride Witch");
	menu.AddItem("7", "Common");
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

int iInfectedsMenuHandler(Menu menu, MenuAction action, int client, int param2) {
	switch (action) {
		case MenuAction_Select: {
			char sItem[32];
			menu.GetItem(param2, sItem, sizeof sItem);
			int iKicked;
			if (GetClientCount(false) >= (MaxClients - 1)) {
				PrintToChat(client, "尝试踢出死亡的感染机器人...");
				iKicked = iKickDeadInfectedBots(client);
			}

			if (!iKicked)
				iCreateInfectedWithParams(client, sItem);
			else {
				DataPack dPack = new DataPack();
				dPack.WriteCell(client);
				dPack.WriteString(sItem);
				RequestFrame(OnNextFrame_CreateInfected, dPack);
			}
			vInfecteds(client, menu.Selection);
		}

		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack)
				vRygive(client);
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

int iKickDeadInfectedBots(int client) {
	int iKickedBots;
	for (int iLoopClient = 1; iLoopClient <= MaxClients; iLoopClient++) {
		if (!IsClientInGame(iLoopClient) || GetClientTeam(client) != 3 || !IsFakeClient(iLoopClient) || IsPlayerAlive(iLoopClient))
			continue;

		KickClient(iLoopClient);
		iKickedBots++;
	}

	if (iKickedBots > 0)
		PrintToChat(client, "Kicked %i bots.", iKickedBots);

	return iKickedBots;
}

void OnNextFrame_CreateInfected(DataPack dPack) {
	dPack.Reset();
	int client = dPack.ReadCell();
	char sZombie[32];
	dPack.ReadString(sZombie, sizeof sZombie);
	delete dPack;

	iCreateInfectedWithParams(client, sZombie);
}

//https://github.com/ProdigySim/DirectInfectedSpawn
int iCreateInfectedWithParams(int client, const char[] sZombie) {
	float vEnd[3];
	if (!bGetDirectionEndPoint(client, vEnd))
		return -1;

	return iCreateInfected(sZombie, vEnd, NULL_VECTOR);
}

int iCreateInfected(const char[] sZombie, const float vPos[3], const float vAng[3]) {
	int iZombie = -1;
	if (strncmp(sZombie, "Witch", 5, false) == 0) {
		iZombie = CreateEntityByName("witch");
		if (iZombie == -1)
			return -1;

		if (strlen(sZombie) > 5)
			SetEntityModel(iZombie, g_sSpecialModels[8]);

		TeleportEntity(iZombie, vPos, vAng, NULL_VECTOR);
		DispatchSpawn(iZombie);
	}
	else if (strcmp(sZombie, "Smoker", false) == 0) {
		iZombie = SDKCall(g_hSDK_NextBotCreatePlayerBot_Smoker, "Smoker");
		if (iZombie == -1)
			return -1;
		
		//SetEntityModel(iZombie, g_sSpecialModels[0]);
		vInitializeSpecial(iZombie, vPos, vAng);
	}
	else if (strcmp(sZombie, "Boomer", false) == 0) {
		iZombie = SDKCall(g_hSDK_NextBotCreatePlayerBot_Boomer, "Boomer");
		if (iZombie == -1)
			return -1;
		
		//SetEntityModel(iZombie, g_sSpecialModels[1]);
		vInitializeSpecial(iZombie, vPos, vAng);
	}
	else if (strcmp(sZombie, "Hunter", false) == 0) {
		iZombie = SDKCall(g_hSDK_NextBotCreatePlayerBot_Hunter, "Hunter");
		if (iZombie == -1)
			return -1;
		
		//SetEntityModel(iZombie, g_sSpecialModels[2]);
		vInitializeSpecial(iZombie, vPos, vAng);
	}
	else if (strcmp(sZombie, "Spitter", false) == 0) {
		iZombie = SDKCall(g_hSDK_NextBotCreatePlayerBot_Spitter, "Spitter");
		if (iZombie == -1)
			return -1;
		
		//SetEntityModel(iZombie, g_sSpecialModels[3]);
		vInitializeSpecial(iZombie, vPos, vAng);
	}
	else if (strcmp(sZombie, "Jockey", false) == 0) {
		iZombie = SDKCall(g_hSDK_NextBotCreatePlayerBot_Jockey, "Jockey");
		if (iZombie == -1)
			return -1;
		
		//SetEntityModel(iZombie, g_sSpecialModels[4]);
		vInitializeSpecial(iZombie, vPos, vAng);
	}
	else if (strcmp(sZombie, "Charger", false) == 0) {
		iZombie = SDKCall(g_hSDK_NextBotCreatePlayerBot_Charger, "Charger");
		if (iZombie == -1)
			return -1;
	
		//SetEntityModel(iZombie, g_sSpecialModels[5]);
		vInitializeSpecial(iZombie, vPos, vAng);
	}
	else if (strcmp(sZombie, "Tank", false) == 0) {
		iZombie = SDKCall(g_hSDK_NextBotCreatePlayerBot_Tank, "Tank");
		if (iZombie == -1)
			return -1;

		//SetEntityModel(iZombie, g_sSpecialModels[6]);
		vInitializeSpecial(iZombie, vPos, vAng);
	}
	else {
		iZombie = CreateEntityByName("infected");
		if (iZombie == -1)
			return -1;
		
		int iPos = StringToInt(sZombie);
		if (iPos < 7)
			SetEntityModel(iZombie, g_sUncommonModels[iPos]);

		SetEntProp(iZombie, Prop_Data, "m_nNextThinkTick", RoundToNearest(GetGameTime() / GetTickInterval()) + 5);
		TeleportEntity(iZombie, vPos, vAng, NULL_VECTOR);

		if (iPos != 6)
			DispatchSpawn(iZombie);
		else {
			int m_nFallenSurvivor = LoadFromAddress(g_pZombieManager + view_as<Address>(g_iOff_m_nFallenSurvivors), NumberType_Int32);
			float m_timestamp = view_as<float>(LoadFromAddress(g_pZombieManager + view_as<Address>(g_iOff_m_FallenSurvivorTimer) + view_as<Address>(8), NumberType_Int32));
			StoreToAddress(g_pZombieManager + view_as<Address>(g_iOff_m_nFallenSurvivors), 0, NumberType_Int32);
			StoreToAddress(g_pZombieManager + view_as<Address>(g_iOff_m_FallenSurvivorTimer) + view_as<Address>(8), view_as<int>(0.0), NumberType_Int32);
			DispatchSpawn(iZombie);
			StoreToAddress(g_pZombieManager + view_as<Address>(g_iOff_m_nFallenSurvivors), m_nFallenSurvivor + LoadFromAddress(g_pZombieManager + view_as<Address>(g_iOff_m_nFallenSurvivors), NumberType_Int32), NumberType_Int32);
			StoreToAddress(g_pZombieManager + view_as<Address>(g_iOff_m_FallenSurvivorTimer) + view_as<Address>(8), view_as<int>(m_timestamp), NumberType_Int32);
		}
	}

	return iZombie;
}

void vInitializeSpecial(int iZombie, const float vPos[3], const float vAng[3]) {
	ChangeClientTeam(iZombie, 3);
	SetEntProp(iZombie, Prop_Send, "m_usSolidFlags", 16);
	SetEntProp(iZombie, Prop_Send, "movetype", 2);
	SetEntProp(iZombie, Prop_Send, "deadflag", 0);
	SetEntProp(iZombie, Prop_Send, "m_lifeState", 0);
	SetEntProp(iZombie, Prop_Send, "m_iObserverMode", 0);
	SetEntProp(iZombie, Prop_Send, "m_iPlayerState", 0);
	SetEntProp(iZombie, Prop_Send, "m_zombieState", 0);
	DispatchSpawn(iZombie);
	TeleportEntity(iZombie, vPos, vAng, NULL_VECTOR);
}

void vMisc(int client, int item) {
	Menu menu = new Menu(iMisc_MenuHandler);
	menu.SetTitle("杂项");
	menu.AddItem("a", "倒地");
	menu.AddItem("b", "剥夺");
	menu.AddItem("c", "复活");
	menu.AddItem("d", "传送");
	menu.AddItem("e", "友伤");
	menu.AddItem("f", "召唤尸潮");
	menu.AddItem("g", "剔除所有Bot");
	menu.AddItem("h", "处死所有特感");
	menu.AddItem("i", "处死所有生还");
	menu.AddItem("j", "传送所有生还到起点");
	menu.AddItem("k", "传送所有生还到终点");
	menu.ExitBackButton = true;
	menu.DisplayAt(client, item, MENU_TIME_FOREVER);
}

int iMisc_MenuHandler(Menu menu, MenuAction action, int client, int param2) {
	switch (action) {
		case MenuAction_Select: {
			char sItem[2];
			menu.GetItem(param2, sItem, sizeof sItem);
			g_iCurrentPage[client] = menu.Selection;

			switch (sItem[0]) {
				case 'a':
					vIncapSurvivor(client, 0);
				case 'b':
					vStripWeapon(client, 0);
				case 'c':
					vRespawnPlayer(client, 0);
				case 'd':
					vTeleportPlayer(client, 0);
				case 'e':
					vSetFriendlyFire(client);
				case 'f':
					vForcePanicEvent(client);
				case 'g':
					vKickAllSurBot(client);
				case 'h':
					vSlayAllInfected(client);
				case 'i':
					vSlayAllSurvivor(client);
				case 'j':
					vWarpAllSurToStartArea();
				case 'k':
					vWarpAllSurToCheckpoint();
			}
		}

		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack)
				vRygive(client);
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

void vIncapSurvivor(int client, int item) {
	char sUID[12];
	char sName[MAX_NAME_LENGTH];
	Menu menu = new Menu(iIncapSur_MenuHandler);
	menu.SetTitle("目标玩家");
	menu.AddItem("a", "所有");
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i)) {
			FormatEx(sUID, sizeof sUID, "%d", GetClientUserId(i));
			FormatEx(sName, sizeof sName, "%N", i);
			menu.AddItem(sUID, sName);
		}
	}
	menu.ExitBackButton = true;
	menu.DisplayAt(client, item, MENU_TIME_FOREVER);
}

int iIncapSur_MenuHandler(Menu menu, MenuAction action, int client, int param2) {
	switch (action) {
		case MenuAction_Select: {
			char sItem[12];
			menu.GetItem(param2, sItem, sizeof sItem);
			if (sItem[0] == 'a') {
				for (int i = 1; i <= MaxClients; i++)
					vIncap(i);
						
				vMisc(client, 0);
			}
			else {
				int target = GetClientOfUserId(StringToInt(sItem));
				if (target)
					vIncap(target);

				vIncapSurvivor(client, menu.Selection);
			}
		}

		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack)
				vMisc(client, 0);
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

void vIncap(int client) {
	if (IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && !GetEntProp(client, Prop_Send, "m_isIncapacitated")) {
		int iSurvivoMaxInc = FindConVar("survivor_max_incapacitated_count").IntValue;
		if (GetEntProp(client, Prop_Send, "m_currentReviveCount") >= iSurvivoMaxInc) {
			SetEntProp(client, Prop_Send, "m_currentReviveCount", iSurvivoMaxInc - 1);
			SetEntProp(client, Prop_Send, "m_isGoingToDie", 0);
			SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);
			StopSound(client, SNDCHAN_STATIC, "player/heartbeatloop.wav");
		}
		vIncapPlayer(client);
	}
}

void vIncapPlayer(int client)  {
	SetEntityHealth(client, 1);
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
	SDKHooks_TakeDamage(client, 0, 0, 100.0);
}

void vStripWeapon(int client, int item) {
	char sUID[12];
	char sName[MAX_NAME_LENGTH];
	Menu menu = new Menu(iStripWeapon_MenuHandler);
	menu.SetTitle("目标玩家");
	menu.AddItem("a", "所有");
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i)) {
			FormatEx(sUID, sizeof sUID, "%d", GetClientUserId(i));
			FormatEx(sName, sizeof sName, "%N", i);
			menu.AddItem(sUID, sName);
		}
	}
	menu.ExitBackButton = true;
	menu.DisplayAt(client, item, MENU_TIME_FOREVER);
}

int iStripWeapon_MenuHandler(Menu menu, MenuAction action, int client, int param2) {
	switch (action) {
		case MenuAction_Select: {
			char sItem[12];
			menu.GetItem(param2, sItem, sizeof sItem);
			if (sItem[0] == 'a') {
				for (int i = 1; i <= MaxClients; i++) {
					if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
						vDeletePlayerSlotAll(i);
				}
				vMisc(client, 0);
			}
			else {
				int target = GetClientOfUserId(StringToInt(sItem));
				if (target && IsClientInGame(target)) {
					vSlotSlect(client, target);
					g_iCurrentPage[client] = menu.Selection;
				}
			}
		}

		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack)
				vMisc(client, 0);
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

void vSlotSlect(int client, int target) {
	char sCls[32];
	char sInfo[32];
	char sUID[2][16];
	Menu menu = new Menu(iSlotSlect_MenuHandler);
	menu.SetTitle("目标装备");
	FormatEx(sUID[0], sizeof sUID[], "%d", GetClientUserId(target));
	strcopy(sUID[1], sizeof sUID[], "a");
	ImplodeStrings(sUID, 2, "|", sInfo, sizeof sInfo);
	menu.AddItem(sInfo, "所有装备");
	int weapon;
	for (int i; i < 5; i++) {
		weapon = GetPlayerWeaponSlot(target, i);
		if (weapon > MaxClients && IsValidEntity(weapon)) {
			FormatEx(sUID[1], sizeof sUID[], "%d", i);
			ImplodeStrings(sUID, 2, "|", sInfo, sizeof sInfo);
			GetEntityClassname(weapon, sCls, sizeof sCls);
			menu.AddItem(sInfo, sCls[7]);
		}	
	}
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int iSlotSlect_MenuHandler(Menu menu, MenuAction action, int client, int param2) {
	switch (action) {
		case MenuAction_Select: {
			char sItem[32];
			char sInfo[2][16];
			menu.GetItem(param2, sItem, sizeof sItem);
			ExplodeString(sItem, "|", sInfo, 2, 16);
			int target = GetClientOfUserId(StringToInt(sInfo[0]));
			if (target && IsClientInGame(target)) {
				if (sInfo[1][0] == 'a') {
					vDeletePlayerSlotAll(target);
					vStripWeapon(client, g_iCurrentPage[client]);
				}
				else {
					vDeletePlayerSlot(target, StringToInt(sInfo[1]));
					vSlotSlect(client, target);
				}
			}
		}

		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack)
				vStripWeapon(client, g_iCurrentPage[client]);
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

void vDeletePlayerSlot(int client, int iSlot) {
	iSlot = GetPlayerWeaponSlot(client, iSlot);
	if (iSlot > MaxClients) {
		RemovePlayerItem(client, iSlot);
		RemoveEdict(iSlot);
	}
}

void vDeletePlayerSlotAll(int client) {
	for (int i; i < 5; i++)
		vDeletePlayerSlot(client, i);
}

void vRespawnPlayer(int client, int item) {
	char sUID[12];
	char sName[MAX_NAME_LENGTH];
	Menu menu = new Menu(iRespawnPlayer_MenuHandler);
	menu.SetTitle("目标玩家");
	menu.AddItem("s", "所有生还者");

	int iTeam;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && ((iTeam = GetClientTeam(i)) == 2 || (iTeam == 3 && !IsFakeClient(i))) && !IsPlayerAlive(i)) {
			FormatEx(sUID, sizeof sUID, "%d", GetClientUserId(i));
			FormatEx(sName, sizeof sName, "%s - %N", g_sTargetTeam[iTeam], i);
			menu.AddItem(sUID, sName);
		}
	}
	menu.ExitBackButton = true;
	menu.DisplayAt(client, item, MENU_TIME_FOREVER);
}

int iRespawnPlayer_MenuHandler(Menu menu, MenuAction action, int client, int param2) {
	switch (action) {
		case MenuAction_Select: {
			char sItem[12];
			menu.GetItem(param2, sItem, sizeof sItem);
			if (sItem[0] == 's') {
					for (int i = 1; i <= MaxClients; i++) {
						if (IsClientInGame(i) && GetClientTeam(i) == 2 && !IsPlayerAlive(i)) {
							vStatsConditionPatch(true);
							SDKCall(g_hSDK_CTerrorPlayer_RoundRespawn, i);
							vStatsConditionPatch(false);
							vTeleportToSurvivor(i);
						}
					}
					vMisc(client, 0);
			}
			else {
				int target = GetClientOfUserId(StringToInt(sItem));
				if (target && IsClientInGame(target) && !IsPlayerAlive(target)) {
					switch (GetClientTeam(target)) {
						case 2: {
							vStatsConditionPatch(true);
							SDKCall(g_hSDK_CTerrorPlayer_RoundRespawn, target);
							vStatsConditionPatch(false);
							vTeleportToSurvivor(target);
							vRespawnPlayer(client, menu.Selection);
						}

						case 3:
							vSelectClassMenu(client, target, 0);
					}
				}
			}
		}

		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack)
				vMisc(client, 0);
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

void vSelectClassMenu(int client, int target, int item) {
	char sInfo[32];
	char sUID[2][16];
	Menu menu = new Menu(iSelectClass_MenuHandler);
	menu.SetTitle("目标特感类型");
	FormatEx(sUID[0], sizeof sUID[], "%d", GetClientUserId(target));
	for (int i; i < 7; i++) {
		FormatEx(sUID[1], sizeof sUID[], "%d", i);
		ImplodeStrings(sUID, 2, "|", sInfo, sizeof sInfo);
		menu.AddItem(sInfo, g_sZombieClass[i]);
	}
	menu.ExitButton = true;
	menu.ExitBackButton = false;
	menu.DisplayAt(client, item, MENU_TIME_FOREVER);
}

int iSelectClass_MenuHandler(Menu menu, MenuAction action, int client, int param2) {
	switch (action) {
		case MenuAction_Select: {
			char sItem[32];
			menu.GetItem(param2, sItem, sizeof sItem);
			char sInfo[2][16];
			ExplodeString(sItem, "|", sInfo, 2, 16);
			int target = GetClientOfUserId(StringToInt(sInfo[0]));
			if (target && IsClientInGame(target) && !IsFakeClient(target)) {
				if (GetClientTeam(target) == 3 && !IsPlayerAlive(target))
					vRespawnPZ(target, StringToInt(sInfo[1]));

				vSelectClassMenu(client, target, menu.Selection);
			}
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

void vRespawnPZ(int client, int zombieClass) {
	if (g_bRespawnPZ)
		CZ_RespawnPZ(client, zombieClass != 6 ? zombieClass + 1 : 8);
	else {
		char sCmd[64];
		FormatEx(sCmd, sizeof sCmd, "z_spawn_old %s", g_sZombieClass[zombieClass]);

		int i = 1;
		bool[] bGhost = new bool[MaxClients];
		bool[] bLifeState = new bool[MaxClients];
		for (; i <= MaxClients; i++) {
			if (i == client || !IsClientInGame(i) || IsFakeClient(i) || GetClientTeam(i) != 3)
				continue;

			if (GetEntProp(i, Prop_Send, "m_isGhost")) {
				bGhost[i] = true;
				SetEntProp(i, Prop_Send, "m_isGhost", 0);
			}
			else if (!IsPlayerAlive(i)) {
				bLifeState[i] = true;
				SetEntProp(i, Prop_Send, "m_lifeState", 0);
			}
		}
	
		vCheatCommand(client, sCmd);

		for (i = 1; i <= MaxClients; i++) {
			if (bGhost[i])
				SetEntProp(i, Prop_Send, "m_isGhost", 1);

			if (bLifeState[i])
				SetEntProp(i, Prop_Send, "m_lifeState", 1);
		}
	}
}

void vTeleportToSurvivor(int client, bool bRandom = true) {
	int iSurvivor = 1;
	ArrayList aClients = new ArrayList(2);

	for (; iSurvivor <= MaxClients; iSurvivor++) {
		if (iSurvivor == client || !IsClientInGame(iSurvivor) || GetClientTeam(iSurvivor) != 2 || !IsPlayerAlive(iSurvivor))
			continue;
	
		aClients.Set(aClients.Push(!GetEntProp(iSurvivor, Prop_Send, "m_isIncapacitated") ? 0 : !GetEntProp(iSurvivor, Prop_Send, "m_isHangingFromLedge") ? 1 : 2), iSurvivor, 1);
	}

	if (!aClients.Length)
		iSurvivor = 0;
	else {
		aClients.Sort(Sort_Descending, Sort_Integer);

		if (!bRandom)
			iSurvivor = aClients.Get(aClients.Length - 1, 1);
		else {
			iSurvivor = aClients.Length - 1;
			iSurvivor = aClients.Get(GetRandomInt(aClients.FindValue(aClients.Get(iSurvivor, 0)), iSurvivor), 1);
		}
	}

	delete aClients;

	if (iSurvivor) {
		vForceCrouch(client);
		float vPos[3];
		GetClientAbsOrigin(iSurvivor, vPos);
		TeleportEntity(client, vPos, NULL_VECTOR, NULL_VECTOR);
	}

	char sScriptName[64];
	g_aMeleeScripts.GetString(GetRandomInt(0, g_aMeleeScripts.Length - 1), sScriptName, sizeof sScriptName);
	Format(sScriptName, sizeof sScriptName, "give %s", sScriptName);
	vCheatCommand(client, sScriptName);
	vCheatCommand(client, "give smg");
}

void vSetFriendlyFire(int client) {
	Menu menu = new Menu(iSetFriendlyFire_MenuHandler);
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

int iSetFriendlyFire_MenuHandler(Menu menu, MenuAction action, int client, int param2)
{
	switch (action) {
		case MenuAction_Select: {
			char sItem[12];
			menu.GetItem(param2, sItem, sizeof sItem);
			switch (param2) {
				case 0: {
					FindConVar("survivor_friendly_fire_factor_easy").RestoreDefault();
					FindConVar("survivor_friendly_fire_factor_normal").RestoreDefault();
					FindConVar("survivor_friendly_fire_factor_hard").RestoreDefault();
					FindConVar("survivor_friendly_fire_factor_expert").RestoreDefault();
					PrintToChat(client, "友伤系数已被重置为默认值");
				}

				default: {
					float fPercent = StringToFloat(sItem);
					FindConVar("survivor_friendly_fire_factor_easy").SetFloat(fPercent);
					FindConVar("survivor_friendly_fire_factor_normal").SetFloat(fPercent);
					FindConVar("survivor_friendly_fire_factor_hard").SetFloat(fPercent);
					FindConVar("survivor_friendly_fire_factor_expert").SetFloat(fPercent);
					PrintToChat(client, "\x01友伤系数已被设置为 \x04%.1f", fPercent);
				}
			}
			vMisc(client, 0);
		}
	
		case MenuAction_Cancel:{
			if (param2 == MenuCancel_ExitBack)
				vMisc(client, 0);
		}
	
		case MenuAction_End:
			delete menu;
	}

	return 0;
}

void vTeleportPlayer(int client, int item) {
	char sUID[12];
	char sName[MAX_NAME_LENGTH];
	Menu menu = new Menu(iTeleportPlayer_MenuHandler);
	menu.SetTitle("传送谁");
	menu.AddItem("s", "所有生还者");
	menu.AddItem("i", "所有感染者");
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && IsPlayerAlive(i)) {
			FormatEx(sUID, sizeof sUID, "%d", GetClientUserId(i));
			FormatEx(sName, sizeof sName, "%N", i);
			menu.AddItem(sUID, sName);
		}
	}
	menu.ExitBackButton = true;
	menu.DisplayAt(client, item, MENU_TIME_FOREVER);
}

int iTeleportPlayer_MenuHandler(Menu menu, MenuAction action, int client, int param2) {
	switch (action) {
		case MenuAction_Select:
		{
			char sItem[12];
			menu.GetItem(param2, sItem, sizeof sItem);
			g_iCurrentPage[client] = menu.Selection;
			vTeleportTarget(client, sItem);
		}
	
		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack)
				vMisc(client, 0);
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

void vTeleportTarget(int client, const char[] sTarget) {
	char sInfo[32];
	char sUID[2][16];
	char sName[MAX_NAME_LENGTH];
	Menu menu = new Menu(iTeleportTarget_MenuHandler);
	menu.SetTitle("传送到哪里");
	strcopy(sUID[0], sizeof sUID[], sTarget);
	strcopy(sUID[1], sizeof sUID[], "c");
	ImplodeStrings(sUID, 2, "|", sInfo, sizeof sInfo);
	menu.AddItem(sInfo, "鼠标指针处");
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && IsPlayerAlive(i)) {
			FormatEx(sUID[1], sizeof sUID[], "%d", GetClientUserId(i));
			ImplodeStrings(sUID, 2, "|", sInfo, sizeof sInfo);
			FormatEx(sName, sizeof sName, "%N", i);
			menu.AddItem(sInfo, sName);
		}
	}
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int iTeleportTarget_MenuHandler(Menu menu, MenuAction action, int client, int param2)
{
	switch (action) {
		case MenuAction_Select: {
			char sItem[32];
			menu.GetItem(param2, sItem, sizeof sItem);
			char sInfo[2][16];
			bool bAllowTeleport;
			float vOrigin[3];
			ExplodeString(sItem, "|", sInfo, 2, 16);
			int victim = GetClientOfUserId(StringToInt(sInfo[0]));
			int iTargetTeam;
			if (sInfo[0][0] == 's')
				iTargetTeam = 2;
			else if (sInfo[0][0] == 'i')
				iTargetTeam = 3;
			else if (victim && IsClientInGame(victim))
				iTargetTeam = GetClientTeam(victim);

			if (sInfo[1][0] == 'c')
				bAllowTeleport = bGetSpawnEndPoint(client, vOrigin);
			else {
				int target = GetClientOfUserId(StringToInt(sInfo[1]));
				if (target && IsClientInGame(target)) {
					GetClientAbsOrigin(target, vOrigin);
					bAllowTeleport = true;
				}
			}

			if (bAllowTeleport) {
				if (victim) {
					vForceCrouch(victim);
					vTeleportFix(victim);
					TeleportEntity(victim, vOrigin, NULL_VECTOR, NULL_VECTOR);
				}
				else {
					switch (iTargetTeam) {
						case 2: {
							for (int i = 1; i <= MaxClients; i++) {
								if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i)) {
									vForceCrouch(i);
									vTeleportFix(i);
									TeleportEntity(i, vOrigin, NULL_VECTOR, NULL_VECTOR);
								}
							}
						}
							
						case 3: {
							for (int i = 1; i <= MaxClients; i++) {
								if (IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i)) {
									vForceCrouch(i);
									TeleportEntity(i, vOrigin, NULL_VECTOR, NULL_VECTOR);
								}
							}
						}
					}
				}
			}
			else if (sInfo[1][0] == 'c')
				PrintToChat(client, "获取准心处位置失败! 请重新尝试.");
	
			vTeleportPlayer(client, g_iCurrentPage[client]);
		}
	
		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack)
				vTeleportPlayer(client, g_iCurrentPage[client]);
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

void vForceCrouch(int client) {
	SetEntProp(client, Prop_Send, "m_bDucked", 1);
	SetEntProp(client, Prop_Send, "m_fFlags", GetEntProp(client, Prop_Send, "m_fFlags")|FL_DUCKING);
}

//https://forums.alliedmods.net/showthread.php?p=2693455
bool bGetSpawnEndPoint(int client, float vSpawnVec[3]) {
	float vEnd[3], vEye[3];
	if (bGetDirectionEndPoint(client, vEnd)) {
		GetClientEyePosition(client, vEye);
		vScaleVectorDirection(vEye, vEnd, 0.1);
		if (bGetNonCollideEndPoint(client, vEnd, vSpawnVec))
			return true;
	}

	GetClientAbsOrigin(client, vSpawnVec);
	return true;
}

void vScaleVectorDirection(float vStart[3], float vEnd[3], float fMultiple) {
	float vDir[3];
	MakeVectorFromPoints(vStart, vEnd, vDir);
	ScaleVector(vDir, fMultiple);
	AddVectors(vEnd, vDir, vEnd);
}

bool bGetDirectionEndPoint(int client, float vEnd[3])
{
	float vDir[3], vPos[3];
	GetClientEyeAngles(client, vDir);
	GetClientEyePosition(client, vPos);
	Handle hTrace = TR_TraceRayFilterEx(vPos, vDir, MASK_PLAYERSOLID_BRUSHONLY, RayType_Infinite, bTraceEntityFilter);
	if (TR_DidHit(hTrace)) {
		TR_GetEndPosition(vEnd, hTrace);
		delete hTrace;
		return true;
	}

	delete hTrace;
	return false;
}

bool bGetNonCollideEndPoint(int client, float vEnd[3], float vNonCol[3], bool bEye = true) {// similar to bGetDirectionEndPoint, but with respect to player size
	float vStart[3];
	if (bEye) {
		GetClientEyePosition(client, vStart);
		if (bIsPlayerStuckPos(vStart)) {// If we attempting to spawn from stucked position, let's start our hull trace from the middle of the ray in hope there are no collision
			float vMid[3];
			AddVectors(vStart, vEnd, vMid);
			ScaleVector(vMid, 0.5);
			vStart = vMid;
		}
	}
	else
		GetClientAbsOrigin(client, vStart);

	Handle hTrace = TR_TraceHullFilterEx(vStart, vEnd, view_as<float>({-16.0, -16.0, 0.0}), view_as<float>({16.0, 16.0, 72.0}), MASK_PLAYERSOLID_BRUSHONLY, bTraceEntityFilter);
	if (TR_DidHit(hTrace)) {
		TR_GetEndPosition(vNonCol, hTrace);
		if (bEye && bIsPlayerStuckPos(vNonCol))
			bGetNonCollideEndPoint(client, vEnd, vNonCol, false); // if eyes position doesn't allow to build reliable TraceHull, repeat from the feet (client's origin)
		delete hTrace;
		return true;
	}
	delete hTrace;
	return false;
}

bool bIsPlayerStuckPos(const float vPos[3]) {// check if the position applicable to respawn a client of a given size without collision
	bool bHit;
	Handle hTrace = TR_TraceHullFilterEx(vPos, vPos, view_as<float>({-16.0, -16.0, 0.0}), view_as<float>({16.0, 16.0, 72.0}), MASK_PLAYERSOLID_BRUSHONLY, bTraceEntityFilter);
	bHit = TR_DidHit(hTrace);
	delete hTrace;
	return bHit;
}

bool bTraceEntityFilter(int entity, int contentsMask) {
	if (entity <= MaxClients)
		return false;

	static char classname[9];
	GetEntityClassname(entity, classname, sizeof classname);
	if ((classname[0] == 'i' && strcmp(classname[1], "nfected") == 0) || (classname[0] == 'w' && strcmp(classname[1], "itch") == 0))
		return false;

	return true;
}

void vTeleportFix(int client) {
	if (GetClientTeam(client) != 2)
		return;

	SetEntityMoveType(client, MOVETYPE_WALK);
	SetEntProp(client, Prop_Send, "m_fFlags", GetEntProp(client, Prop_Send, "m_fFlags") & ~FL_FROZEN);

	if (GetEntProp(client, Prop_Send, "m_isHangingFromLedge"))
		vRunScript("GetPlayerFromUserID(%d).ReviveFromIncap()", GetClientUserId(client));
	else {
		int attacker = L4D2_GetInfectedAttacker(client);
		if (attacker > 0 && IsClientInGame(attacker) && IsPlayerAlive(attacker)) {
			SDKCall(g_hSDK_CTerrorPlayer_CleanupPlayerState, attacker);
			ForcePlayerSuicide(attacker);
		}
	}
}

void vRunScript(const char[] sCode, any ...) 
{
	/**
	* Run a VScript (Credit to Timocop)
	*
	* @param sCode		Magic
	* @return void
	*/

	static int iScriptLogic = INVALID_ENT_REFERENCE;
	if (iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic)) {
		iScriptLogic = EntIndexToEntRef(CreateEntityByName("logic_script"));
		if (iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic)) 
			SetFailState("Could not create 'logic_script'");

		DispatchSpawn(iScriptLogic);
	}

	char buffer[512];
	VFormat(buffer, sizeof buffer, sCode, 2);
	SetVariantString(buffer);
	AcceptEntityInput(iScriptLogic, "RunScriptCode");
}

int L4D2_GetInfectedAttacker(int client) {
	int attacker;

	/* Charger */
	attacker = GetEntPropEnt(client, Prop_Send, "m_pummelAttacker");
	if (attacker > 0)
		return attacker;

	attacker = GetEntPropEnt(client, Prop_Send, "m_carryAttacker");
	if (attacker > 0)
		return attacker;

	/* Hunter */
	attacker = GetEntPropEnt(client, Prop_Send, "m_pounceAttacker");
	if (attacker > 0)
		return attacker;

	/* Smoker */
	attacker = GetEntPropEnt(client, Prop_Send, "m_tongueOwner");
	if (attacker > 0)
		return attacker;

	/* Jockey */
	attacker = GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker");
	if (attacker > 0)
		return attacker;

	return -1;
}

void vForcePanicEvent(int client) {
	vExecuteCheatCommand("director_force_panic_event");
	vMisc(client, g_iCurrentPage[client]);
}

void vKickAllSurBot(int client) {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 2)
			KickClient(i);
	}
	vMisc(client, g_iCurrentPage[client]);
}

void vSlayAllInfected(int client) {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i))
			ForcePlayerSuicide(i);
	}
	vMisc(client, g_iCurrentPage[client]);
}

void vSlayAllSurvivor(int client) {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
			ForcePlayerSuicide(i);
	}
	vMisc(client, g_iCurrentPage[client]);
}

void vWarpAllSurToStartArea() {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
			vCheatCommand(i, "warp_to_start_area");
	}
}

void vWarpAllSurToCheckpoint() {
	vExecuteCheatCommand("warp_all_survivors_to_checkpoint");
}

void vExecuteCheatCommand(const char[] sCommand, const char[] sValue = "") {
	int iCmdFlags = GetCommandFlags(sCommand);
	SetCommandFlags(sCommand, iCmdFlags & ~FCVAR_CHEAT);
	ServerCommand("%s %s", sCommand, sValue);
	ServerExecute();
	SetCommandFlags(sCommand, iCmdFlags);
}

void vTeamSwitch(int client, int item) {
	char sUID[12];
	char sInfo[PLATFORM_MAX_PATH];
	Menu menu = new Menu(iTeamSwitch_MenuHandler);
	menu.SetTitle("目标玩家");

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i)) {
			FormatEx(sUID, sizeof sUID, "%d", GetClientUserId(i));
			FormatEx(sInfo, sizeof sInfo, "%N", i);
			switch (GetClientTeam(i)) {
				case 1:
					Format(sInfo, sizeof sInfo, "%s - %s", iGetBotOfIdlePlayer(i) ? "闲置" : "观众", sInfo);

				case 2:
					Format(sInfo, sizeof sInfo, "生还 - %s", sInfo);
					
				case 3:
					Format(sInfo, sizeof sInfo, "感染 - %s", sInfo);
			}

			menu.AddItem(sUID, sInfo);
		}
	}
	menu.ExitBackButton = true;
	menu.DisplayAt(client, item, MENU_TIME_FOREVER);
}

int iTeamSwitch_MenuHandler(Menu menu, MenuAction action, int client, int param2) {
	switch (action) {
		case MenuAction_Select: {
			char sItem[12];
			menu.GetItem(param2, sItem, sizeof sItem);
			g_iCurrentPage[client] = menu.Selection;

			int target = GetClientOfUserId(StringToInt(sItem));
			if (target && IsClientInGame(target))
				vSwitchPlayerTeam(client, target);
			else
				PrintToChat(client, "目标玩家不在游戏中");
		}

		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack)
				vRygive(client);
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

void vSwitchPlayerTeam(int client, int target) {
	char sUID[2][16];
	char sInfo[32];
	Menu menu = new Menu(iSwitchPlayerTeam_MenuHandler);
	menu.SetTitle("目标队伍");
	FormatEx(sUID[0], sizeof sUID[], "%d", GetClientUserId(target));

	int iTeam;
	if (!iGetBotOfIdlePlayer(target))
		iTeam = GetClientTeam(target);

	for (int i; i < 4; i++) {
		if (iTeam == i || (iTeam != 2 && i == 0))
			continue;

		IntToString(g_iTargetTeam[i], sUID[1], sizeof sUID[]);
		ImplodeStrings(sUID, 2, "|", sInfo, sizeof sInfo);
		menu.AddItem(sInfo, g_sTargetTeam[i]);
	}

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int iSwitchPlayerTeam_MenuHandler(Menu menu, MenuAction action, int client, int param2) {
	switch (action) {
		case MenuAction_Select: {
			char sItem[12];
			menu.GetItem(param2, sItem, sizeof sItem);
			char sInfo[2][16];
			ExplodeString(sItem, "|", sInfo, 2, 16);
			int target = GetClientOfUserId(StringToInt(sInfo[0]));
			if (target && IsClientInGame(target)) {
				int iOnTeam;
				if (!iGetBotOfIdlePlayer(target))
					iOnTeam = GetClientTeam(target);

				int iTargetTeam = StringToInt(sInfo[1]);
				if (iOnTeam != iTargetTeam) {
					switch (iTargetTeam) {
						case 0: {
							if (iOnTeam == 2)
								vGoAFKTimer(target, 0.0);
							else
								PrintToChat(client, "只有生还者才能进行闲置");
						}

						case 1: {
							if (iOnTeam == 0)
								SDKCall(g_hSDK_CTerrorPlayer_TakeOverBot, target, true);

							ChangeClientTeam(target, iTargetTeam);
						}

						case 2:
							vChangeTeamToSurvivor(target, iOnTeam);

						case 3:
							ChangeClientTeam(target, iTargetTeam);
					}
				}
				else
					PrintToChat(client, "玩家已在目标队伍中");
						
				vTeamSwitch(client, g_iCurrentPage[client]);
			}
			else
				PrintToChat(client, "目标玩家不在游戏中");
		}
	
		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack)
				vTeamSwitch(client, g_iCurrentPage[client]);
		}
	
		case MenuAction_End:
			delete menu;
	}

	return 0;
}

void vChangeTeamToSurvivor(int client, int iTeam) {
	if (GetEntProp(client, Prop_Send, "m_isGhost"))
		SetEntProp(client, Prop_Send, "m_isGhost", 0);

	if (iTeam != 1)
		ChangeClientTeam(client, 1);

	int iBot;
	if ((iBot = iGetBotOfIdlePlayer(client))) {
		SDKCall(g_hSDK_CTerrorPlayer_TakeOverBot, client, true);
		return;
	}
	else
		iBot = iGetAnyValidAliveSurvivorBot();

	if (iBot) {
		SDKCall(g_hSDK_SurvivorBot_SetHumanSpectator, iBot, client);
		SDKCall(g_hSDK_CTerrorPlayer_TakeOverBot, client, true);
	}
	else
		ChangeClientTeam(client, 2);
}

int iGetAnyValidAliveSurvivorBot() {
	for (int i = 1; i <= MaxClients; i++) {
		if (bIsValidAliveSurvivorBot(i)) 
			return i;
	}
	return 0;
}

bool bIsValidAliveSurvivorBot(int client) {
	return IsClientInGame(client) && !IsClientInKickQueue(client) && IsFakeClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && !iGetIdlePlayerOfBot(client);
}

int iGetBotOfIdlePlayer(int client) {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 2 && iGetIdlePlayerOfBot(i) == client)
			return i;
	}
	return 0;
}

int iGetIdlePlayerOfBot(int client) {
	if (!HasEntProp(client, Prop_Send, "m_humanSpectatorUserID"))
		return 0;

	return GetClientOfUserId(GetEntProp(client, Prop_Send, "m_humanSpectatorUserID"));
}

void vWeaponSpeed(int client, int item) {
	Menu menu = new Menu(iWeaponSpeed_MenuHandler);
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

int iWeaponSpeed_MenuHandler(Menu menu, MenuAction action, int client, int param2) {
	switch (action) {
		case MenuAction_Select: {
			char sItem[12];
			menu.GetItem(param2, sItem, sizeof sItem);
			g_iCurrentPage[client] = menu.Selection;
			vWeaponSpeedUp(client, sItem);
		}

		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack)
				vRygive(client);
		}
	
		case MenuAction_End:
			delete menu;
	}

	return 0;
}

void vWeaponSpeedUp(int client, const char[] sSpeedUp) {
	char sInfo[32];
	char sUID[2][16];
	char sName[MAX_NAME_LENGTH];
	Menu menu = new Menu(iWeaponSpeedUp_MenuHandler);
	menu.SetTitle("目标玩家");
	strcopy(sUID[0], sizeof sUID[], sSpeedUp);
	strcopy(sUID[1], sizeof sUID[], "a");
	ImplodeStrings(sUID, 2, "|", sInfo, sizeof sInfo);
	menu.AddItem(sInfo, "所有");
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			FormatEx(sUID[1], sizeof sUID[], "%d", GetClientUserId(i));
			FormatEx(sName, sizeof sName, "(%.1fx)%N", g_fSpeedUp[i], i);
			ImplodeStrings(sUID, 2, "|", sInfo, sizeof sInfo);
			menu.AddItem(sInfo, sName);
		}
	}
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int iWeaponSpeedUp_MenuHandler(Menu menu, MenuAction action, int client, int param2) {
	switch (action) {
		case MenuAction_Select: {
			char sItem[12];
			menu.GetItem(param2, sItem, sizeof sItem);
			char sInfo[2][16];
			ExplodeString(sItem, "|", sInfo, 2, 16);
			float fSpeedUp = StringToFloat(sInfo[0]);
			if (sInfo[1][0] == 'a') {
				for (int i = 1; i <= MaxClients; i++) {
					if (IsClientInGame(i))
						g_fSpeedUp[i] = fSpeedUp;
				}
				PrintToChat(client, "\x05所有玩家 \x01的武器操纵性已被设置为 \x04%.1fx", fSpeedUp);
				vRygive(client);
			}
			else {
				int target = GetClientOfUserId(StringToInt(sInfo[1]));
				if (target && IsClientInGame(target)) {
						g_fSpeedUp[target] = fSpeedUp;
						PrintToChat(client, "\x05%N \x01的武器操纵性已被设置为 \x04%.1fx", target, fSpeedUp);
				}
				else
					PrintToChat(client, "目标玩家不在游戏中");
						
				vWeaponSpeed(client, g_iCurrentPage[client]);
			}
		}

		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack)
				vWeaponSpeed(client, g_iCurrentPage[client]);
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

void vDebugMode(int client) {
	if (g_bDebug) {
		g_smSteamIDs.Clear();
			
		g_bDebug = false;
		ReplyToCommand(client, "调试模式已关闭.");
	}
	else {
		char sSteamID[32];
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i) && !IsFakeClient(i)) {
				GetClientAuthId(i, AuthId_Steam2, sSteamID, sizeof sSteamID);
				g_smSteamIDs.SetValue(sSteamID, true, true);
			}
		}
		
		g_bDebug = true;
		ReplyToCommand(client, "调试模式已开启.");
	}
	
	vRygive(client);
}

void vShowAliveSur(int client) {
	char sUID[12];
	char sName[MAX_NAME_LENGTH];
	Menu menu = new Menu(ShowAliveSur_MenuHandler);
	menu.SetTitle("目标玩家");
	menu.AddItem("a", "所有");
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i)) {
			FormatEx(sUID, sizeof sUID, "%d", GetClientUserId(i));
			FormatEx(sName, sizeof sName, "%N", i);
			menu.AddItem(sUID, sName);
		}
	}
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int ShowAliveSur_MenuHandler(Menu menu, MenuAction action, int client, int param2) {
	switch (action) {
		case MenuAction_Select: {
			char sItem[12];
			menu.GetItem(param2, sItem, sizeof sItem);
			if (sItem[0] == 'a') {
				for (int i = 1; i <= MaxClients; i++) {
					if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
						vCheatCommand(i, g_sNamedItem[client]);
				}
			}
			else
				vCheatCommand(GetClientOfUserId(StringToInt(sItem)), g_sNamedItem[client]);

			vPageExitBackSwitch(client, g_iFunction[client], g_iCurrentPage[client]);
		}

		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack)
				vPageExitBackSwitch(client, g_iFunction[client], g_iCurrentPage[client]);
		}
	
		case MenuAction_End:
			delete menu;
	}

	return 0;
}

void vPageExitBackSwitch(int client, int iFunction, int item) {
	switch (iFunction) {
		case 1:
			vGuns(client, item);
		case 2:
			vMelees(client, item);
		case 3:
			vItems(client, item);
	}
}

void vReloadAmmo(int client) {
	int weapon = GetPlayerWeaponSlot(client, 0);
	if (weapon <= MaxClients || !IsValidEntity(weapon))
		return;

	int m_iPrimaryAmmoType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	if (m_iPrimaryAmmoType == -1)
		return;

	char sWeapon[32];
	GetEntityClassname(weapon, sWeapon, sizeof sWeapon);
	if (strcmp(sWeapon[7], "grenade_launcher") == 0) {
		static ConVar hAmmoGrenadelau;
		if (hAmmoGrenadelau == null)
			hAmmoGrenadelau = FindConVar("ammo_grenadelauncher_max");

		SetEntProp(client, Prop_Send, "m_iAmmo", hAmmoGrenadelau.IntValue, _, m_iPrimaryAmmoType);
	}
}

void vCheatCommand(int client, const char[] sCommand) {
	if (!client || !IsClientInGame(client))
		return;

	char sCmd[32];
	if (SplitString(sCommand, " ", sCmd, sizeof sCmd) == -1)
		strcopy(sCmd, sizeof sCmd, sCommand);

	if (strcmp(sCmd, "give") == 0 && strcmp(sCommand[5], "health") == 0) {
		int attacker = L4D2_GetInfectedAttacker(client);
		if (attacker > 0 && IsClientInGame(attacker) && IsPlayerAlive(attacker)) {
			SDKCall(g_hSDK_CTerrorPlayer_CleanupPlayerState, attacker);
			ForcePlayerSuicide(attacker);
		}
	}

	int iFlagBits, iCmdFlags;
	iFlagBits = GetUserFlagBits(client);
	iCmdFlags = GetCommandFlags(sCmd);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	SetCommandFlags(sCmd, iCmdFlags & ~FCVAR_CHEAT);
	FakeClientCommand(client, sCommand);
	SetUserFlagBits(client, iFlagBits);
	SetCommandFlags(sCmd, iCmdFlags);
	
	if (strcmp(sCmd, "give") == 0) {
		if (strcmp(sCommand[5], "health") == 0)
			SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0); //防止有虚血时give health会超过100血
		else if (strcmp(sCommand[5], "ammo") == 0)
			vReloadAmmo(client); //榴弹发射器加子弹
	}
}

void vGoAFKTimer(int client, float flDuration) {
	static int m_GoAFKTimer = -1;
	if (m_GoAFKTimer == -1)
		m_GoAFKTimer = FindSendPropInfo("CTerrorPlayer", "m_lookatPlayer") - 12;

	SetEntDataFloat(client, m_GoAFKTimer + 4, flDuration);
	SetEntDataFloat(client, m_GoAFKTimer + 8, GetGameTime() + flDuration);
}

void vInitData() {
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof sPath, "gamedata/%s.txt", GAMEDATA);
	if (!FileExists(sPath))
		SetFailState("\n==========\nMissing required file: \"%s\".\n==========", sPath);

	GameData hGameData = new GameData(GAMEDATA);
	if (!hGameData)
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	g_pZombieManager = hGameData.GetAddress("ZombieManager");
	if (!g_pZombieManager)
		SetFailState("Failed to find address: ZombieManager");

	g_iOff_m_nFallenSurvivors = hGameData.GetOffset("m_nFallenSurvivors");
	if (g_iOff_m_nFallenSurvivors== -1)
		SetFailState("Failed to find offset: m_nFallenSurvivors");

	g_iOff_m_FallenSurvivorTimer = hGameData.GetOffset("m_FallenSurvivorTimer");
	if (g_iOff_m_FallenSurvivorTimer== -1)
		SetFailState("Failed to find offset: m_FallenSurvivorTimer");

	StartPrepSDKCall(SDKCall_Player);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::RoundRespawn"))
		SetFailState("Failed to find signature: CTerrorPlayer::RoundRespawn");
	g_hSDK_CTerrorPlayer_RoundRespawn = EndPrepSDKCall();
	if (!g_hSDK_CTerrorPlayer_RoundRespawn)
		SetFailState("Failed to create SDKCall: CTerrorPlayer::RoundRespawn");

	StartPrepSDKCall(SDKCall_Player);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "SurvivorBot::SetHumanSpectator"))
		SetFailState("Failed to find signature: SurvivorBot::SetHumanSpectator");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	g_hSDK_SurvivorBot_SetHumanSpectator = EndPrepSDKCall();
	if (!g_hSDK_SurvivorBot_SetHumanSpectator)
		SetFailState("Failed to create SDKCall: SurvivorBot::SetHumanSpectator");
	
	StartPrepSDKCall(SDKCall_Player);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::TakeOverBot"))
		SetFailState("Failed to find signature: CTerrorPlayer::TakeOverBot");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	g_hSDK_CTerrorPlayer_TakeOverBot = EndPrepSDKCall();
	if (!g_hSDK_CTerrorPlayer_TakeOverBot)
		SetFailState("Failed to create SDKCall: CTerrorPlayer::TakeOverBot");

	StartPrepSDKCall(SDKCall_Player);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::CleanupPlayerState"))
		SetFailState("Failed to find signature: CTerrorPlayer::CleanupPlayerState");
	g_hSDK_CTerrorPlayer_CleanupPlayerState = EndPrepSDKCall();
	if (!g_hSDK_CTerrorPlayer_CleanupPlayerState)
		SetFailState("Failed to create SDKCall: CTerrorPlayer::CleanupPlayerState");

	Address pReplaceWithBot = hGameData.GetAddress("NextBotCreatePlayerBot.jumptable");
	if (pReplaceWithBot != Address_Null && LoadFromAddress(pReplaceWithBot, NumberType_Int8) == 0x68)
		vPrepWindowsCreateBotCalls(pReplaceWithBot); // We're on L4D2 and linux
	else
		vPrepLinuxCreateBotCalls(hGameData);

	vInitPatchs(hGameData);

	delete hGameData;
}

void vInitPatchs(GameData hGameData = null) {
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
void vStatsConditionPatch(bool bPatch) {
	static bool bPatched;
	if (!bPatched && bPatch) {
		bPatched = true;
		StoreToAddress(g_pStatsCondition, 0xEB, NumberType_Int8);
	}
	else if (bPatched && !bPatch)  {
		bPatched = false;
		StoreToAddress(g_pStatsCondition, 0x75, NumberType_Int8);
	}
}

void vLoadStringFromAdddress(Address pAddr, char[] buffer, int maxlength) {
	int i;
	char val;
	while (i < maxlength) {
		val = LoadFromAddress(pAddr + view_as<Address>(i), NumberType_Int8);
		if (val == 0) {
			buffer[i] = '\0';
			break;
		}
		buffer[i] = val;
		i++;
	}
	buffer[maxlength - 1] = '\0';
}

Handle hPrepCreateBotCallFromAddress(StringMap aSiFuncHashMap, const char[] sSIName) {
	Address pAddr;
	StartPrepSDKCall(SDKCall_Static);
	if (!aSiFuncHashMap.GetValue(sSIName, pAddr) || !PrepSDKCall_SetAddress(pAddr))
		SetFailState("Unable to find NextBotCreatePlayer<%s> address in memory.", sSIName);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBasePlayer, SDKPass_Pointer);
	return EndPrepSDKCall();	
}

void vPrepWindowsCreateBotCalls(Address pJumpTableAddr) {
	StringMap aInfectedHashMap = new StringMap();
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
		char sSIName[32];
		vLoadStringFromAdddress(pSIStringAddr, sSIName, sizeof sSIName);

		Address pFuncRefAddr = pCaseBase + view_as<Address>(6); // 2nd byte of call, 5+1 byte offset.
		int oFuncRelOffset = LoadFromAddress(pFuncRefAddr, NumberType_Int32);
		Address pCallOffsetBase = pCaseBase + view_as<Address>(10); // first byte of next instruction after the CALL instruction
		Address pNextBotCreatePlayerBotTAddr = pCallOffsetBase + view_as<Address>(oFuncRelOffset);
		PrintToServer("Found NextBotCreatePlayerBot<%s>() @ %08x", sSIName, pNextBotCreatePlayerBotTAddr);
		aInfectedHashMap.SetValue(sSIName, pNextBotCreatePlayerBotTAddr);
	}

	g_hSDK_NextBotCreatePlayerBot_Smoker = hPrepCreateBotCallFromAddress(aInfectedHashMap, "Smoker");
	if (!g_hSDK_NextBotCreatePlayerBot_Smoker)
		SetFailState("Cannot initialize %s SDKCall, address lookup failed.", NAME_CreateSmoker);

	g_hSDK_NextBotCreatePlayerBot_Boomer = hPrepCreateBotCallFromAddress(aInfectedHashMap, "Boomer");
	if (!g_hSDK_NextBotCreatePlayerBot_Boomer)
		SetFailState("Cannot initialize %s SDKCall, address lookup failed.", NAME_CreateBoomer);

	g_hSDK_NextBotCreatePlayerBot_Hunter = hPrepCreateBotCallFromAddress(aInfectedHashMap, "Hunter");
	if (!g_hSDK_NextBotCreatePlayerBot_Hunter)
		SetFailState("Cannot initialize %s SDKCall, address lookup failed.", NAME_CreateHunter);

	g_hSDK_NextBotCreatePlayerBot_Spitter = hPrepCreateBotCallFromAddress(aInfectedHashMap, "Spitter");
	if (!g_hSDK_NextBotCreatePlayerBot_Spitter)
		SetFailState("Cannot initialize %s SDKCall, address lookup failed.", NAME_CreateSpitter);
	
	g_hSDK_NextBotCreatePlayerBot_Jockey = hPrepCreateBotCallFromAddress(aInfectedHashMap, "Jockey");
	if (!g_hSDK_NextBotCreatePlayerBot_Jockey)
		SetFailState("Cannot initialize %s SDKCall, address lookup failed.", NAME_CreateJockey);

	g_hSDK_NextBotCreatePlayerBot_Charger = hPrepCreateBotCallFromAddress(aInfectedHashMap, "Charger");
	if (!g_hSDK_NextBotCreatePlayerBot_Charger)
		SetFailState("Cannot initialize %s SDKCall, address lookup failed.", NAME_CreateCharger);

	g_hSDK_NextBotCreatePlayerBot_Tank = hPrepCreateBotCallFromAddress(aInfectedHashMap, "Tank");
	if (!g_hSDK_NextBotCreatePlayerBot_Tank)
		SetFailState("Cannot initialize %s SDKCall, address lookup failed.", NAME_CreateTank);
}

void vPrepLinuxCreateBotCalls(GameData hGameData = null) {
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