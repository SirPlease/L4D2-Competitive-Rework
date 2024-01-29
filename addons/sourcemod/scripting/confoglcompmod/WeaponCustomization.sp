#if defined __weapon_customization_included
	#endinput
#endif
#define __weapon_customization_included

#define WC_MODULE_NAME			"WeaponCustomization"

static const char sSniperNames[][] =
{
	"weapon_hunting_rifle",
	"weapon_sniper_military",
	"weapon_sniper_awp",
	"weapon_sniper_scout",
	"weapon_rifle_sg552"
};

static char
	WC_sLastWeapon[64] = "\0";

static int
	WC_iLimitCount = 1,
	WC_iLastWeapon = -1,
	WC_iLastClient = -1;

static ConVar
	WC_hLimitCount = null;

void WC_OnModuleStart()
{
	WC_hLimitCount = CreateConVarEx("limit_sniper", "1", "Limits the maximum number of sniping rifles at one time to this number", _, true, 0.0, true, 4.0);

	WC_iLimitCount = WC_hLimitCount.IntValue;
	WC_hLimitCount.AddChangeHook(WC_ConVarChange);

	HookEvent("player_use", WC_PlayerUse_Event);
	HookEvent("weapon_drop", WC_WeaponDrop_Event);
}

static void WC_ConVarChange(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	WC_iLimitCount = WC_hLimitCount.IntValue;
}

static void WC_WeaponDrop_Event(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	if (!IsPluginEnabled()) {
		return;
	}

	WC_iLastWeapon = hEvent.GetInt("propid");
	WC_iLastClient = GetClientOfUserId(hEvent.GetInt("userid"));
	hEvent.GetString("item", WC_sLastWeapon, sizeof(WC_sLastWeapon));
}

static void WC_PlayerUse_Event(Event hEvent, const char[] sEventName, bool bDontBroadcast)
{
	if (!IsPluginEnabled()) {
		return;
	}

	int client = GetClientOfUserId(hEvent.GetInt("userid"));

	int primary = GetPlayerWeaponSlot(client, L4D2WeaponSlot_Primary);
	if (primary < 1 || !IsValidEdict(primary)) {
		return;
	}

	char primary_name[MAX_ENTITY_NAME_LENGTH];
	GetEdictClassname(primary, primary_name, sizeof(primary_name));

	if (IsValidSniper(primary_name)) {
		if (SniperCount(client) >= WC_iLimitCount) {
			RemovePlayerItem(client, primary);
			//PrintToChat(client, "\x01[\x05Confogl\x01] Maximum \x04%d \x01sniping rifle(s) is enforced.", WC_iLimitCount);
			CPrintToChat(client, "{blue}[{default}Confogl{blue}]{default} Maximum {blue}%d {olive}sniping rifle(s) {default}is enforced.", WC_iLimitCount);

			if (WC_iLastClient == client) {
				if (WC_iLastWeapon > 0 && IsValidEdict(WC_iLastWeapon)) {
					KillEntity(WC_iLastWeapon);

					int flags = GetCommandFlags("give");
					SetCommandFlags("give", flags ^ FCVAR_CHEAT);

					char sTemp[64];
					Format(sTemp, sizeof(sTemp), "give %s", WC_sLastWeapon);
					FakeClientCommand(client, sTemp);

					SetCommandFlags("give", flags);
				}
			}
		}
	}

	WC_iLastWeapon = -1;
	WC_iLastClient = -1;
	WC_sLastWeapon[0] = 0;
}

static int SniperCount(int client)
{
	char temp[MAX_ENTITY_NAME_LENGTH];
	int count = 0, index = 0, ent = 0;

	for (int i = 0; i < 4; i++) {
		index = GetSurvivorIndex(i);

		if (index != client && index != 0 && IsClientConnected(index)) {
			ent = GetPlayerWeaponSlot(index, L4D2WeaponSlot_Primary);

			if (ent > 0 && IsValidEdict(ent)) {
				GetEdictClassname(ent, temp, sizeof(temp));

				if (IsValidSniper(temp)) {
					count++;
				}
			}
		}
	}

	return count;
}

static bool IsValidSniper(const char[] sWeaponName)
{
	for (int i = 0; i < sizeof(sSniperNames); i++) {
		if (strcmp(sWeaponName, sSniperNames[i], true) == 0) {
			return true;
		}
	}

	return false;
}
