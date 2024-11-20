// Changelog:
//
// 2.0 (robex):
//     - Code rework, cleaned up old sourcemod functions
//     - Allow limiting individual melees, to limit them with l4d_wlimits_add
//       use names in MeleeWeaponNames array (l4d2util_constants.inc)
//

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colors>
#define L4D2UTIL_STOCKS_ONLY 1
#include <l4d2util>

#define GAMEDATA_FILE				"l4d_wlimits"
#define GAMEDATA_USE_AMMO			"CWeaponAmmoSpawn_Use"
#define SOUND_NAME					"player/suit_denydevice.wav"

// enum struct LimitInfo
// {
// 	ArrayList weapons;
// 	int limit;
// 	int give_ammo;
// }
// ArrayList g_LimitInfoList;
// StringMap g_WeaponLimitMap;

enum struct LimitArrayEntry
{
	int LAE_iLimit;
	int LAE_iGiveAmmo;
	int LAE_WeaponArray[WEPID_SIZE / 32 + 1];
	int LAE_MeleeArray[WEPID_MELEES_SIZE / 32 + 1];
}

int
	g_iLastPrintTickCount[MAXPLAYERS + 1],
	g_iWeaponAlreadyGiven[MAXPLAYERS + 1][MAX_EDICTS];

Handle
	hSDKGiveDefaultAmmo;

ArrayList
	hLimitArray;

bool
	bIsLocked;

StringMap
	hMeleeWeaponNamesTrie = null;

public Plugin myinfo =
{
	name = "L4D Weapon Limits",
	author = "CanadaRox, Stabby, Forgetest, A1m`, robex",
	description = "Restrict weapons individually or together",
	version = "2.2.3",
	url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public void OnPluginStart()
{
	LoadTranslation("l4d_weapon_limits.phrases");
	InitSDKCall();
	L4D2Weapons_Init();

	LimitArrayEntry arrayEntry;

	hLimitArray = new ArrayList(sizeof(arrayEntry));

	hMeleeWeaponNamesTrie = new StringMap();

	for (int i = 0; i < WEPID_MELEES_SIZE; i++) {
		hMeleeWeaponNamesTrie.SetValue(MeleeWeaponNames[i], i);
	}

	RegServerCmd("l4d_wlimits_add", AddLimit_Cmd, "Add a weapon limit");
	RegServerCmd("l4d_wlimits_lock", LockLimits_Cmd, "Locks the limits to improve search speeds");
	RegServerCmd("l4d_wlimits_clear", ClearLimits_Cmd, "Clears all weapon limits (limits must be locked to be cleared)");

	HookEvent("round_start", ClearUp, EventHookMode_PostNoCopy);

	// For debug
	/*for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i)) {
			continue;
		}

		OnClientPutInServer(i);
	}*/
}

void InitSDKCall()
{
	/* Preparing SDK Call */
	Handle hConf = LoadGameConfigFile(GAMEDATA_FILE);

	if (hConf == null) {
		SetFailState("Gamedata missing: %s", GAMEDATA_FILE);
	}

	StartPrepSDKCall(SDKCall_Entity);

	if (!PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, GAMEDATA_USE_AMMO)) {
		SetFailState("Gamedata missing signature: %s", GAMEDATA_USE_AMMO);
	}

	// Client that used the ammo spawn
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	hSDKGiveDefaultAmmo = EndPrepSDKCall();

	if (hSDKGiveDefaultAmmo == null) {
		SetFailState("Failed to finish SDKCall setup: %s", GAMEDATA_USE_AMMO);
	}

	delete hConf;
}

public void OnMapStart()
{
	PrecacheSound(SOUND_NAME);

	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i)) OnClientPutInServer(i);
	}
}

void ClearUp(Event hEvent, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++) {
		g_iLastPrintTickCount[i] = 0;
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponCanUse, Hook_WeaponCanUse);
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_WeaponCanUse, Hook_WeaponCanUse);
}

Action AddLimit_Cmd(int args)
{
	if (bIsLocked) {
		PrintToServer("Limits have been locked !");

		return Plugin_Handled;
	}

	if (args < 3) {
		PrintToServer("Usage: l4d_wlimits_add <limit> <ammo> <weapon1> <weapon2> ... <weaponN>\nAmmo: -1: Given for primary weapon spawns only, 0: no ammo given ever, else: ammo always given !");

		return Plugin_Handled;
	}

	char sTempBuff[ENTITY_MAX_NAME_LENGTH];
	GetCmdArg(1, sTempBuff, sizeof(sTempBuff));

	int wepid, meleeid;

	LimitArrayEntry newEntry;

	newEntry.LAE_iLimit = StringToInt(sTempBuff);
	GetCmdArg(2, sTempBuff, sizeof(sTempBuff));
	newEntry.LAE_iGiveAmmo = StringToInt(sTempBuff);

	for (int i = 3; i <= args; ++i) {
		GetCmdArg(i, sTempBuff, sizeof(sTempBuff));

		wepid = WeaponNameToId(sTempBuff);

		// @Forgetest: Fix incorrectly counting generic melees with an entry of melee names only.
		if (wepid != WEPID_NONE) {
			AddBitMask(newEntry.LAE_WeaponArray, wepid);
		}

		// assume it's a melee
		if (wepid == WEPID_NONE) {
			if (hMeleeWeaponNamesTrie.GetValue(sTempBuff, meleeid)) {
				AddBitMask(newEntry.LAE_MeleeArray, meleeid);
			}
		}
	}

	hLimitArray.PushArray(newEntry, sizeof(newEntry));

	return Plugin_Handled;
}

Action LockLimits_Cmd(int args)
{
	if (bIsLocked) {
		PrintToServer("Weapon limits already locked !");
	} else {
		bIsLocked = true;

		PrintToServer("Weapon limits locked !");
	}

	return Plugin_Handled;
}

Action ClearLimits_Cmd(int args)
{
	if (!bIsLocked) {
		return Plugin_Handled;
	}

	bIsLocked = false;

	PrintToServer("[L4D Weapon Limits] Weapon limits cleared!");

	if (hLimitArray != null) {
		hLimitArray.Clear();
	}

	return Plugin_Handled;
}

Action Hook_WeaponCanUse(int client, int weapon)
{
	// TODO: There seems to be an issue that this hook will be constantly called
	//       when client with no weapon on equivalent slot just eyes or walks on it.
	//       If the weapon meets limit, client will have the warning spamming unexpectedly.

	if (GetClientTeam(client) != L4D2Team_Survivor || !bIsLocked) {
		return Plugin_Continue;
	}

	int wepid = IdentifyWeapon(weapon);
	int is_melee = (wepid == WEPID_MELEE);
	int meleeid = 0;
	if (is_melee) {
		meleeid = IdentifyMeleeWeapon(weapon);
	}
	int wep_slot = GetSlotFromWeaponId(wepid);

	int player_weapon = GetPlayerWeaponSlot(client, wep_slot);
	int player_wepid = IdentifyWeapon(player_weapon);
	/*int player_meleeid = 0;
	if (player_wepid == WEPID_MELEE) {
		player_meleeid = IdentifyMeleeWeapon(player_weapon);
	}*/

	int iSize = hLimitArray.Length;

	LimitArrayEntry arrayEntry;

	for (int i = 0; i < iSize; i++) {
		hLimitArray.GetArray(i, arrayEntry, sizeof(arrayEntry));

		if (is_melee) {
			int specificMeleeCount = GetMeleeCount(arrayEntry.LAE_MeleeArray);
			int allMeleeCount = GetWeaponCount(arrayEntry.LAE_WeaponArray);

			int isSpecificMeleeLimited = isWeaponLimited(arrayEntry.LAE_MeleeArray, meleeid);
			int isAllMeleeLimited = isWeaponLimited(arrayEntry.LAE_WeaponArray, wepid);

			if (isSpecificMeleeLimited && specificMeleeCount >= arrayEntry.LAE_iLimit) {
				denyWeapon(wep_slot, arrayEntry, weapon, client);
				return Plugin_Handled;
			}

			if (isAllMeleeLimited && allMeleeCount >= arrayEntry.LAE_iLimit) {
				// dont deny swapping melees when theres only a limit on global melees
				if (player_wepid != WEPID_MELEE) {
					denyWeapon(wep_slot, arrayEntry, weapon, client);
					return Plugin_Handled;
				}
			}
		} else {
			// is weapon about to be picked up limited and over the limit?
			if (isWeaponLimited(arrayEntry.LAE_WeaponArray, wepid) && GetWeaponCount(arrayEntry.LAE_WeaponArray) >= arrayEntry.LAE_iLimit) {
				// is currently held weapon limited?
				if (!player_wepid || wepid == player_wepid || !isWeaponLimited(arrayEntry.LAE_WeaponArray, player_wepid)) {
					denyWeapon(wep_slot, arrayEntry, weapon, client);
					return Plugin_Handled;
				}
			}
		}
	}

	return Plugin_Continue;
}

// Fixing an error when compiling in sourcemod 1.9
void AddBitMask(int[] iMask, int iWeaponId)
{
	iMask[iWeaponId / 32] |= (1 << (iWeaponId % 32));
}

int isWeaponLimited(const int[] mask, int wepid)
{
	return (mask[wepid / 32] & (1 << (wepid % 32)));
}

void denyWeapon(int wep_slot, LimitArrayEntry arrayEntry, int weapon, int client)
{
	if ((wep_slot == 0 && arrayEntry.LAE_iGiveAmmo == -1) || arrayEntry.LAE_iGiveAmmo != 0) {
		GiveDefaultAmmo(client);
	}

	// Notify the client only when they are attempting to pick this up
	// in which way spamming gets avoided due to auto-pick-up checking left since Counter:Strike.

	//g_iWeaponAlreadyGiven - if the weapon is given by another plugin, the player will not press the use key
	//g_iLastPrintTickCount - sometimes there is a double seal in one frame because the player touches the weapon and presses a use key
	int iWeaponRef = EntIndexToEntRef(weapon);
	int iLastTick = GetGameTickCount();
	int iButtonPressed = GetEntProp(client, Prop_Data, "m_afButtonPressed");

	if ((g_iWeaponAlreadyGiven[client][weapon] != iWeaponRef || iButtonPressed & IN_USE)
		&& g_iLastPrintTickCount[client] != iLastTick
	) {
		//CPrintToChat(client, "{blue}[{default}Weapon Limits{blue}]{default} This weapon group has reached its max of {green}%d", arrayEntry.LAE_iLimit);
		CPrintToChat(client, "%t %t", "Tag", "Full", arrayEntry.LAE_iLimit);
		EmitSoundToClient(client, SOUND_NAME);

		g_iWeaponAlreadyGiven[client][weapon] = iWeaponRef;
		g_iLastPrintTickCount[client] = iLastTick;
	}
}

int GetWeaponCount(const int[] mask)
{
	int count, wepid;

	for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i) || GetClientTeam(i) != L4D2Team_Survivor || !IsPlayerAlive(i)) {
			continue;
		}

		for (int j = 0; j < L4D2WeaponSlot_Size; ++j) {
			wepid = IdentifyWeapon(GetPlayerWeaponSlot(i, j));

			if (isWeaponLimited(mask, wepid)) {
				count++;
			}
		}

		// @Forgetest
		// Lucky that "incap" prop is reset before function "OnRevive" restores secondary
		// so no concern about player failing to get their secondary back
		if (IsIncapacitated(i) || IsHangingFromLedge(i)) {
			wepid = IdentifyWeapon(GetPlayerSecondaryWeaponRestore(i));

			if (isWeaponLimited(mask, wepid)) {
				count++;
			}
		}
	}

	return count;
}

int GetMeleeCount(const int[] mask)
{
	int count, meleeid;

	for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i) || GetClientTeam(i) != L4D2Team_Survivor || !IsPlayerAlive(i)) {
			continue;
		}

		meleeid = IdentifyMeleeWeapon(GetPlayerWeaponSlot(i, L4D2WeaponSlot_Secondary));
		if (meleeid != WEPID_MELEE_NONE) {
			if (isWeaponLimited(mask, meleeid)) {
				count++;
			}
		}

		// @Forgetest
		// Lucky that "incap" prop is reset before function "OnRevive" restores secondary
		// so no concern about player failing to get their secondary back
		if (IsIncapacitated(i) || IsHangingFromLedge(i)) {
			meleeid = IdentifyMeleeWeapon(GetPlayerSecondaryWeaponRestore(i));

			if (meleeid != WEPID_MELEE_NONE) {
				if (isWeaponLimited(mask, meleeid)) {
					count++;
				}
			}
		}
	}

	return count;
}

void GiveDefaultAmmo(int client)
{
	// @Forgetest NOTE:
	// Previously the plugin seems to cache an index of one ammo pile in current map, and is supposed to use it here.
	// For some reason, the caching never runs, and the code is completely wrong either.
	// Therefore, it has been consistently using an SDKCall like below ('0' should've been the index of ammo pile).
	// However, since it actually has worked without error and crash for a long time, I would decide to leave it still.
	// If your server suffers from this, please try making use of the functions commented below.

	SDKCall(hSDKGiveDefaultAmmo, 0, client);
}

/*stock int FindAmmoSpawn()
{
	int entity = FindEntityByClassname(MaxClients+1, "weapon_ammo_spawn");
	if (entity != -1)
	{
		return entity;
	}
	//We have to make an ammo pile!
	return MakeAmmoPile();
}

stock int MakeAmmoPile()
{
	int ammo = CreateEntityByName("weapon_ammo_spawn");
	DispatchSpawn(ammo);
	LogMessage("No ammo pile found, creating one: %d", iAmmoPile);
	return ammo;
}*/

int GetPlayerSecondaryWeaponRestore(int client)
{
	static int s_iOffs_m_hSecondaryWeaponRestore = -1;
	if (s_iOffs_m_hSecondaryWeaponRestore == -1)
		s_iOffs_m_hSecondaryWeaponRestore = FindSendPropInfo("CTerrorPlayer", "m_iVersusTeam") - 20;

	return GetEntDataEnt2(client, s_iOffs_m_hSecondaryWeaponRestore);
}

/* @A1m`:
When the player touches the weapon, then this code from the plugin is called every frame,
in the event that the player's primary slot is not occupied, so we get a print in the chat every frame.

#0  0xed80ea26 in CTerrorPlayer::Weapon_CanUse(CBaseCombatWeapon*) ()
   from /home/l4d2user/steamcmd/l4d2/left4dead2/bin/server_srv.so
#1  0xed3e92f2 in CTerrorWeapon::CanPlayerTouch(CCSPlayer*) ()
   from /home/l4d2user/steamcmd/l4d2/left4dead2/bin/server_srv.so
#2  0xed3f0a63 in CTerrorWeapon::DefaultTouch(CBaseEntity*) ()
   from /home/l4d2user/steamcmd/l4d2/left4dead2/bin/server_srv.so
#3  0xed47bddd in CBaseEntity::Touch(CBaseEntity*) () from /home/l4d2user/steamcmd/l4d2/left4dead2/bin/server_srv.so
#4  0xed2f318d in CBaseEntity::PhysicsMarkEntityAsTouched(CBaseEntity*) ()
   from /home/l4d2user/steamcmd/l4d2/left4dead2/bin/server_srv.so
#5  0xed2f3326 in CBaseEntity::PhysicsMarkEntitiesAsTouching(CBaseEntity*, CGameTrace&) ()
   from /home/l4d2user/steamcmd/l4d2/left4dead2/bin/server_srv.so
#6  0xed541a01 in CServerGameEnts::MarkEntitiesAsTouching(edict_t*, edict_t*) ()
   from /home/l4d2user/steamcmd/l4d2/left4dead2/bin/server_srv.so
#7  0xf7395866 in SV_SolidMoved(edict_t*, ICollideable*, Vector const*, bool) ()
   from /home/l4d2user/steamcmd/l4d2/bin/engine_srv.so
#8  0xed28d3ed in CBaseEntity::PhysicsTouchTriggers(Vector const*) ()
   from /home/l4d2user/steamcmd/l4d2/left4dead2/bin/server_srv.so
#9  0xed572a4f in CMoveHelperServer::ProcessImpacts() () from /home/l4d2user/steamcmd/l4d2/left4dead2/bin/server_srv.so
#10 0xed645566 in CPlayerMove::RunCommand(CBasePlayer*, CUserCmd*, IMoveHelper*) ()
   from /home/l4d2user/steamcmd/l4d2/left4dead2/bin/server_srv.so
#11 0xef092d66 in __SourceHook_MFHCls_RunCommand::Func (this=<optimized out>, p1=<optimized out>,
    p2=<optimized out>, p3=<optimized out>) at /home/java/cpp/usercmd_fix/extension.cpp:34
#12 0xed623d93 in CBasePlayer::PlayerRunCommand(CUserCmd*, IMoveHelper*) ()
   from /home/l4d2user/steamcmd/l4d2/left4dead2/bin/server_srv.so
#13 0xed4da327 in CCSPlayer::PlayerRunCommand(CUserCmd*, IMoveHelper*) ()
   from /home/l4d2user/steamcmd/l4d2/left4dead2/bin/server_srv.so
#14 0xed84b1e0 in CTerrorPlayer::PlayerRunCommand(CUserCmd*, IMoveHelper*) ()
   from /home/l4d2user/steamcmd/l4d2/left4dead2/bin/server_srv.so
#15 0xeeea7147 in __SourceHook_MFHCls_PlayerRunCmdHook::Func (this=<optimized out>, p1=<optimized out>,
    p2=<optimized out>) at /home/java/cpp/1.9-sourcemod/extensions/sdktools/hooks.cpp:50
#16 0xed638907 in CBasePlayer::PhysicsSimulate() () from /home/l4d2user/steamcmd/l4d2/left4dead2/bin/server_srv.so
#17 0xed60cc92 in Physics_SimulateEntity(CBaseEntity*) () from /home/l4d2user/steamcmd/l4d2/left4dead2/bin/server_srv.so
#18 0xed60d1c1 in Physics_RunThinkFunctions(bool) () from /home/l4d2user/steamcmd/l4d2/left4dead2/bin/server_srv.so
#19 0xed544e57 in CServerGameDLL::GameFrame(bool) () from /home/l4d2user/steamcmd/l4d2/left4dead2/bin/server_srv.so
#20 0xf007fb1e in __SourceHook_FHCls_IServerGameDLLGameFramefalse::Func(bool) ()
   from /home/l4d2user/steamcmd/l4d2/left4dead2/addons/sourcemod01/bin/sourcemod.2.l4d2.so
#21 0xffffaa78 in ?? ()

#define WEAPONTYPE_PISTOL 1

bool CTerrorWeapon::CanPlayerTouch(CCSPlayer *pOther)
{
	if ( !pOther )
		return false;

	if ( !IsASurvivorTeam(pOther->GetTeamNumber( pOther )) || !pOther->IsAlive()) )
		return false;

	if ( GetWeaponID() == WEAPONTYPE_PISTOL )
	{
		CWeaponCSBase* pWeapon = pPlayer->GetCSWeapon( WEAPONTYPE_PISTOL );

		if ( pWeapon == NULL || pWeapon->IsDualWielding() )
			return false;
	}
	else
	{
		int weaponSlot = GetSlot();

		if ( pOther->Weapon_GetSlot( weaponSlot )) && !pOther->IsBot() )
			return false;

		if ( pOther->IsPlayer() && !pOther->Weapon_CanUse( this ) )
			return false;
	}

	CTerrorPlayer* pDropPlayer = GetDroppingPlayer();
	if ( !pDropPlayer )
		return false;

	if ( !pDropPlayer->IsPlayer() )
		return false;

	if ( pOther == pDropPlayer )
		return false;

	//m_hDropTarget - the name was invented, i do not know how correctly
	//Check CTerrorWeapon::GetDropTarget..
	//Offset 6044 (linux)
	if ( pOther == m_hDropTarget.Get() )
		return false;

	return true;
}

void CTerrorWeapon::DefaultTouch(CBasePlayer *pOther)
{
	// if it's not a player, ignore
	CBasePlayer *pPlayer = ToBasePlayer( pOther );
	if ( !pPlayer )
		return;

	//GetSolidFlags() ?
	bool v2 = (*((_WORD *)this + 218) >> 2) & 1; //1B4h
	if ( pOther == (CBasePlayer *)GetOwner() || v2 )
	{
		DevWarning("Touching our own weapons\n");
	}
	else if ( CanPlayerTouch(pOther) )
	{
		CBaseCombatWeapon::DefaultTouch(this, pOther);

		if ( pOther == GetPlayerOwner() )
		{
			CBasePlayer* pDropPlayer = ToBasePlayer( GetDroppingPlayer() );

			if ( pDropPlayer && pOther != pDropPlayer )
			{
				//m_hDropTarget - the name was invented, i do not know how correctly
				//Check CTerrorWeapon::GetDropTarget..
				//Offset 6044 (linux)
				CBasePlayer *pDropTarget = m_hDropTarget.Get();
	
				if ( pDropTarget && pOther == pDropTarget )
				{
					pOther->OnGivenWeapon(this);
				}
			}
		}
	}
}
*/

/**
 * Check if the translation file exists
 *
 * @param translation	Translation name.
 * @noreturn
 */
stock void LoadTranslation(const char[] translation)
{
	char
		sPath[PLATFORM_MAX_PATH],
		sName[64];

	Format(sName, sizeof(sName), "translations/%s.txt", translation);
	BuildPath(Path_SM, sPath, sizeof(sPath), sName);
	if (!FileExists(sPath))
		SetFailState("Missing translation file %s.txt", translation);

	LoadTranslations(translation);
}