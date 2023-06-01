#define PLUGIN_VERSION		"1.0.1"
#define PLUGIN_PREFIX		"l4d_"
#define PLUGIN_NAME			"supply_indicator"
#define PLUGIN_NAME_FULL	"[L4D & L4D2] Supply Indicator"
#define PLUGIN_DESCRIPTION	"glows and reports map supplies count by species"
#define PLUGIN_AUTHOR		"NoroHime"
#define PLUGIN_LINK			"https://forums.alliedmods.net/showthread.php?t=342096"

/**
 *	Changes
 *	
 *	v0.1 (7-March-2023)
 *		- pre release
 *	v1.0 (8-March-2023)
 *		- just released
 *	v1.0.1 (8-March-2023, 2nd time)
 *		- fix player delay authorize not trigger supplie report, usually happen on listen server
 *		- make message dont print to bot
 *		- optimize performance about reports to all (reduce an order of magnitude)
 *		- command support trigger by console
 */

/**
 *	Credits
 *		- request and idea - コクシムソウ
 *		- referenced library Left 4 DHooks Direct
 *		- referenced library SMLib (String_EndsWith)
 */


#pragma newdecls required
#pragma semicolon 1

#define MAX_MESSAGE_LENGTH	(254 * 4)
#include <sdkhooks>

public Plugin myinfo = {
	name =			PLUGIN_NAME_FULL,
	author =		PLUGIN_AUTHOR,
	description =	PLUGIN_DESCRIPTION,
	version =		PLUGIN_VERSION,
	url = 			PLUGIN_LINK
};

int iSupplyEntity [2048];
int bIsSupplySpawner [2048];
bool hasTranslations;
bool bLateLoad;
bool bRoundStarted;
EngineVersion ENGINE;

ConVar cSupplies;	int iSupplies;
ConVar cReports;	int iReports;
ConVar cAccess;		int iAccess;
ConVar cAnnounce;	int iAnnounce;
ConVar cGlow;		int iGlow;
ConVar cGlowFlash;	bool bGlowFlash;
ConVar cPile;		int iPile;
ConVar cGlowSpecies;int iGlowSpecies;


public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {

	if (late)
		bLateLoad = true;

	ENGINE = GetEngineVersion();

	return APLRes_Success;
}

public void OnPluginStart() {

	CreateConVar			(PLUGIN_NAME, PLUGIN_VERSION,					"Version of " ... PLUGIN_NAME_FULL, FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cSupplies =		CreateConVar(PLUGIN_NAME ... "_supplies", "-1",			"supplies to indicate, 1=vomit jar 2=pipe bomb 4=molotov\n8=first aid 16=defibrillator 32=adrenaline 64=pain pills 128=laser -1=All \nadd numbers together you want.", FCVAR_NOTIFY);
	cReports =		CreateConVar(PLUGIN_NAME ... "_reports", "-1",			"report event, 1=player join 2=item spawn 4=item picked 8=item pick broadcast -1=all, add numbers together you want.", FCVAR_NOTIFY);
	cAccess =		CreateConVar(PLUGIN_NAME ... "_access", "n",			"admin flag to access command and receives query results,\nn=cheats, empty=everyone, see more in /configs/admin_levels.cfg", FCVAR_NOTIFY);
	cAnnounce =		CreateConVar(PLUGIN_NAME ... "_announce", "18",			"announce types, 1=console 2=chat 4=center 8=hint 16=text included phrase 'MapLeft'", FCVAR_NOTIFY);
	cGlow =			CreateConVar(PLUGIN_NAME ... "_glow", "1000",			"l4d2 only, apply glow to supplies, -1=disabled 1000=1000 units range 0=infinity range", FCVAR_NOTIFY);
	cGlowFlash =	CreateConVar(PLUGIN_NAME ... "_glow_flash", "1",		"l4d2 only, does glow flashing", FCVAR_NOTIFY);
	cPile =			CreateConVar(PLUGIN_NAME ... "_pile", "-1",				"how handle infinity supply pile, 1=count as 1 0=not count -1=count as infinity", FCVAR_NOTIFY);
	cGlowSpecies =	CreateConVar(PLUGIN_NAME ... "_glow_species", "-1",		"l4d2 only, glow species, same as *_supplies", FCVAR_NOTIFY);

	AutoExecConfig(true, PLUGIN_PREFIX ... PLUGIN_NAME);
	// OnConfigsExecuted is async, must fetch manually
	ApplyCvars();

	cSupplies.AddChangeHook(OnConVarChanged);
	cReports.AddChangeHook(OnConVarChanged);  
	cAccess.AddChangeHook(OnConVarChanged);
	cAnnounce.AddChangeHook(OnConVarChanged);
	cGlow.AddChangeHook(OnConVarChanged);
	cGlowFlash.AddChangeHook(OnConVarChanged);
	cPile.AddChangeHook(OnConVarChanged);
	cGlowSpecies.AddChangeHook(OnConVarChanged);

	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("map_transition", OnRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("finale_vehicle_leaving", OnRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("mission_lost", OnRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("round_end", OnRoundEnd, EventHookMode_PostNoCopy);

	RegConsoleCmd("sm_supplies", CommandSupplies, "sm_supplies [override *_supplies] //report count of supplies");
	RegConsoleCmd("sm_si", CommandSupplies, "sm_si [override *_supplies] //report count of supplies");

	// load translation phrases file
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "translations/" ... PLUGIN_PREFIX ... PLUGIN_NAME ... ".phrases.txt");
	hasTranslations = FileExists(path);
	if (hasTranslations)
		LoadTranslations(PLUGIN_PREFIX ... PLUGIN_NAME ... ".phrases");
	else
		LogError("not translations file %s found yet, please check install guide for %s", PLUGIN_PREFIX ... PLUGIN_NAME ... ".phrases.txt", PLUGIN_NAME_FULL);

	LoadTranslations("core.phrases");

	// Late Load
	if (bLateLoad) {

		bRoundStarted = true;
		char classname[32];
		for (int i = MaxClients + 1; i < 2048; i++)
			if (IsValidEntity(i)) {
				GetEntityClassname(i, classname, sizeof(classname));
				OnEntityCreated(i, classname);
			}

		for (int i = 1; i <= MaxClients; i++)
			if (IsClientInGame(i) && IsClientAuthorized(i))
				OnClientPostAdminCheck(i);

		bLateLoad = false;
	}
}

enum {
	SUPPLY_VOMITJAR =	(1 << 0),
	SUPPLY_PIPEBOMB =	(1 << 1),
	SUPPLY_MOLOTOV =	(1 << 2),
	SUPPLY_FIRSTAID =	(1 << 3),
	SUPPLY_DEFIB =		(1 << 4),
	SUPPLY_ADRENALINE =	(1 << 5),
	SUPPLY_PAINPILLS =	(1 << 6),
	SUPPLY_LASERSIGHT =	(1 << 7),
	SUPLLY_MAXSIZE = 	8
}

enum {
	REPORT_JOIN =			(1 << 0),
	REPORT_SPAWN =			(1 << 1),
	REPORT_PICK =			(1 << 2),
	REPORT_PICK_BROADCAST =	(1 << 3),
}

void ApplyCvars() {

	static char sBuffer[128];
	iSupplies = cSupplies.IntValue;
	iReports = cReports.IntValue;
	cAccess.GetString(sBuffer, sizeof(sBuffer));
	iAccess = sBuffer[0] ? ReadFlagString(sBuffer) : 0;
	iAnnounce = cAnnounce.IntValue;
	iGlow = cGlow.IntValue;
	bGlowFlash = cGlowFlash.BoolValue;
	iPile = cPile.IntValue;
	iGlowSpecies = cGlowSpecies.IntValue;
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}

public void OnConfigsExecuted() {
	ApplyCvars();
}

void OnRoundStart(Event event, const char[] name, bool dontBroadcast) {
	bRoundStarted = true;
}

void OnRoundEnd(Event event, const char[] name, bool dontBroadcast) {
	bRoundStarted = false;
}

public void OnEntityCreated(int entity, const char[] classname) {

	if (2048 > entity > MaxClients) {

		if (iSupplies & SUPPLY_VOMITJAR && StartsWith(classname, "weapon_vomitjar"))
			iSupplyEntity[entity] = SUPPLY_VOMITJAR;

		if (iSupplies & SUPPLY_PIPEBOMB && StartsWith(classname, "weapon_pipe_bomb"))
			iSupplyEntity[entity] = SUPPLY_PIPEBOMB;

		if (iSupplies & SUPPLY_MOLOTOV && StartsWith(classname, "weapon_molotov"))
			iSupplyEntity[entity] = SUPPLY_MOLOTOV;

		if (iSupplies & SUPPLY_FIRSTAID && StartsWith(classname, "weapon_first_aid_kit"))
			iSupplyEntity[entity] = SUPPLY_FIRSTAID;

		if (iSupplies & SUPPLY_DEFIB && StartsWith(classname, "weapon_defibrillator"))
			iSupplyEntity[entity] = SUPPLY_DEFIB;

		if (iSupplies & SUPPLY_ADRENALINE && StartsWith(classname, "weapon_adrenaline"))
			iSupplyEntity[entity] = SUPPLY_ADRENALINE;

		if (iSupplies & SUPPLY_PAINPILLS && StartsWith(classname, "weapon_pain_pills"))
			iSupplyEntity[entity] = SUPPLY_PAINPILLS;

		if (iSupplies & SUPPLY_LASERSIGHT && StartsWith(classname, "upgrade_laser_sight"))
			iSupplyEntity[entity] = SUPPLY_LASERSIGHT;

		if (iSupplyEntity[entity]) {

			if (EndsWith(classname, "_spawn"))
				bIsSupplySpawner[entity] = true;

			if (bLateLoad)
				OnSupplySpawnedFrame(entity);
			else
				SDKHook(entity, SDKHook_SpawnPost, OnSupplySpawned);

			SDKHook(entity, SDKHook_Use, OnSupplyPicking);
		}
	}
}

Action OnSupplyPicking(int entity, int activator, int caller, UseType type, float value) {

	if (iGlow >= 0 && ENGINE == Engine_Left4Dead2 && iGlowSpecies & iSupplyEntity[entity])
		L4D2_SetEntityGlow_Type(entity, L4D2Glow_None);

	if (iReports & REPORT_PICK && iSupplyEntity[entity]) {

		DataPack data = new DataPack();

		if (iReports & REPORT_PICK && iReports & REPORT_PICK_BROADCAST == 0 && 0 < caller <= MaxClients  && !IsFakeClient(caller) && HasPermission(caller, iAccess))

			data.WriteCell(GetClientUserId(caller));

		else if (iReports & REPORT_PICK_BROADCAST)

			data.WriteCell(TARGET_ALL);

		else {

			delete data;
			return Plugin_Continue;
		}

		data.WriteCell(iSupplyEntity[entity]);

		RequestFrame(ReportSupplyFrame, data);
	}

	return Plugin_Continue;
}

void ReportSupplyFrame(DataPack data) {

	data.Reset();

	int client = data.ReadCell(),
		species = data.ReadCell();

	delete data;

	if (client == TARGET_ALL)

		ReportSupply(TARGET_ALL, species);

	else {

		client = GetClientOfUserId(client);

		if (0 < client <= MaxClients)
			ReportSupply(client, species);
	}
}

public void OnEntityDestroyed(int entity) {

	if (2048 > entity > MaxClients) {

		iSupplyEntity[entity] = 0;
		bIsSupplySpawner[entity] = false;
	}
}

void OnSupplySpawned(int entity) {
	RequestFrame(OnSupplySpawnedFrame, EntIndexToEntRef(entity));
}

void OnSupplySpawnedFrame(int entity) {

	entity = EntRefToEntIndex(entity);

	if (entity != INVALID_ENT_REFERENCE && GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity") == INVALID_ENT_REFERENCE) {

		static int white[3] = {255, 255, 255};

		if (iSupplies & iSupplyEntity[entity] == 0)
			return;

		if (iGlow >= 0 && ENGINE == Engine_Left4Dead2 && iGlowSpecies & iSupplyEntity[entity]) {

			L4D2_SetEntityGlow_Range(entity, iGlow);
			L4D2_SetEntityGlow_MinRange(entity, 0);
			L4D2_SetEntityGlow_Color(entity, white);
			L4D2_SetEntityGlow_Type(entity, L4D2Glow_Constant);

			if (bGlowFlash)
				L4D2_SetEntityGlow_Flashing(entity, true);
		}

		if ( bRoundStarted && iReports & REPORT_SPAWN && !bLateLoad && !bIsSupplySpawner[entity])
			ReportSupply(0, iSupplyEntity[entity]);
	}
}

void ReportSupply(int client, int species) {

	static char message[MAX_MESSAGE_LENGTH];

	int remaining[SUPLLY_MAXSIZE];

	for (int s = 0; s < SUPLLY_MAXSIZE; s++)
		if (species & iSupplies & (1 << s)) {
			remaining[s] = GetSupplyCount((1 << s));
		}

	if (client == TARGET_ALL) {

		for (int i = 1; i <= MaxClients; i++)

			if (IsClientInGame(i) && !IsFakeClient(i) && HasPermission(i, iAccess)) {

				SetGlobalTransTarget(i);

				if (iAnnounce & (1 << 4))
					FormatEx(message, sizeof(message), "%t", "MapLeft");
				else
					message = "{white}";

				for (int s = 0; s < SUPLLY_MAXSIZE; s++)
					if (species & iSupplies & (1 << s))
						FormatBySpecie((1 << s), message, sizeof(message), remaining[s]);
			}

	} else {

		SetGlobalTransTarget(client);

		if (iAnnounce & (1 << 4))
			FormatEx(message, sizeof(message), "%t", "MapLeft");
		else
			message = "{white}";

		for (int s = 0; s < SUPLLY_MAXSIZE; s++)
			if (species & iSupplies & (1 << s))
				FormatBySpecie((1 << s), message, sizeof(message), remaining[s]);
	}

	Announce(client, iAnnounce, "%s", message);
}

void FormatBySpecie(int specie, char[] message, int maxLength, int remaining) {

	static char phrase[32];

	bool hasInfinity = false;

	if (remaining < 0) {
		remaining = - (remaining + 1);
		hasInfinity = true;
	}

	if (hasInfinity) {

		if (iPile == -1)
			FormatEx(phrase, sizeof(phrase), "%t", "Infinity");
		else
			FormatEx(phrase, sizeof(phrase), "%d{white}(%t{white})", remaining, "Infinity");
	} else
		FormatEx(phrase, sizeof(phrase), "%d", remaining);

	switch (specie) {
		case SUPPLY_VOMITJAR :
			Format(message, maxLength, "%s%t", message, "VomitJar", phrase);
		case SUPPLY_PIPEBOMB :
			Format(message, maxLength, "%s%t", message, "PipeBomb", phrase);
		case SUPPLY_MOLOTOV :
			Format(message, maxLength, "%s%t", message, "Molotov", phrase);
		case SUPPLY_FIRSTAID :
			Format(message, maxLength, "%s%t", message, "FirstAid", phrase);
		case SUPPLY_DEFIB :
			Format(message, maxLength, "%s%t", message, "Defibrillator", phrase);
		case SUPPLY_ADRENALINE :
			Format(message, maxLength, "%s%t", message, "Adrenaline", phrase);
		case SUPPLY_PAINPILLS :
			Format(message, maxLength, "%s%t", message, "PainPills", phrase);
		case SUPPLY_LASERSIGHT :
			Format(message, maxLength, "%s%t", message, "LaserSight", phrase);
	}
}

/**
 * @param specie		supply specie (SUPPLY_*)
 * @return				count of specie, -9: 8 and has infinity
 */
int GetSupplyCount(int specie) {

	int count = 0;
	bool hasInfinity = false;

	for (int entity = MaxClients + 1; entity < 2048; entity++) {

		if (iSupplyEntity[entity] == specie) {

			if (bIsSupplySpawner[entity]) {

				int left = GetSpawnerCount(entity);

				if (left < 0) {

					hasInfinity = true;

					switch (iPile) {
						case 0, -1:
							continue;
						default :
							count += iPile;
					}
				} else
					count += left;

			} else if (GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity") == INVALID_ENT_REFERENCE)
				count++;
		}
	}

	return hasInfinity ? -count -1 : count;
}

int GetSpawnerCount(int entity) {

	// unlimited count like ammo pile
	if (GetEntProp(entity, Prop_Data, "m_spawnflags") & (1 << 3))

		return -1;

	else if (HasEntProp(entity, Prop_Data, "m_itemCount"))

		return GetEntProp(entity, Prop_Data, "m_itemCount");

	return 0;
}

bool HasPermission(int client, int flag) {

	if (client && flag)
		return view_as<bool>(GetUserFlagBits(client) & (ADMFLAG_ROOT | flag));

	return true;
}

Action CommandSupplies(int client, int args) {

	if (!HasPermission(client, iAccess)) {
		ReplyToCommand(client, "%t", "No Access");
		return Plugin_Handled;
	}

	ReportSupply(client, args > 0 ? GetCmdArgInt(1) : iSupplies);

	return Plugin_Handled;
}

public void OnClientPostAdminCheck(int client) {

	if (HasPermission(client, iAccess) && iReports & REPORT_JOIN)
		ReportSupply(client, iSupplies);
}

///////////////////////////
// Stocks Below			//
/////////////////////////


stock bool StartsWith(const char[] str, const char[] substr) {
	return strncmp(str, substr, strlen(substr) -1, true) == 0;
}

stock bool EndsWith(const char[] str, const char[] substr) {
	int n_str = strlen(str) - 1,
		n_substr = strlen(substr) - 1;

	while (n_str != 0 && n_substr != 0) {

		if (str[n_str--] != substr[n_substr--]) {
			return false;
		}
	}
	return true;
}

enum {
	TARGET_INFECTEDS =	-32,
	TARGET_SURVIVORS,
	TARGET_ALL,
	TARGET_SERVER = LANG_SERVER,
}

enum {
	MSG_CONSOLE =		(1 << 0),
	MSG_CHAT =			(1 << 1),
	MSG_CENTER =		(1 << 2),
	MSG_HINT =			(1 << 3),
}

void Announce(int target, int type, const char[] format, any ...) {

	if (!type)
		return;

	static ArrayList targets;

	if (!targets)
		targets = new ArrayList();

	targets.Clear();

	if ( (1 <= target <= MaxClients) )

		targets.Push(target);

	else {

		switch (target) {

			case TARGET_SERVER :
				targets.Push(0);

			case TARGET_ALL : {

				for (int client = 1; client <= MaxClients; client++)
					if (IsClientInGame(client))
						targets.Push(client);

				targets.Push(0);
			}

			case TARGET_SURVIVORS, TARGET_INFECTEDS : 
				for (int client = 1; client <= MaxClients; client++)
					if (IsClientInGame(client) && GetClientTeam(client) == (target == TARGET_SURVIVORS ? 2 : 3))
						targets.Push(client);
		}
	}

	for (int i = 0; i < targets.Length; i++) {

		int client = targets.Get(i);

		static char message[MAX_MESSAGE_LENGTH];

		SetGlobalTransTarget(client);

		// only print console for host
		if (client == TARGET_SERVER)
			type = MSG_CONSOLE;

		// process color tag message first
		if (type & MSG_CHAT) {
			VFormat(message, sizeof(message), format, 4);
			ApplyColorTag(message, sizeof(message));
			PrintToChat(client, "%s", message);
		}

		// process non-color message if still things to do
		if (type & MSG_CHAT != MSG_CHAT) {

			// refetch from argument
			VFormat(message, sizeof(message), format, 4);
			RemoveColorTag(message, sizeof(message));

			if (type & MSG_CONSOLE) {

				if (client == 0)
					PrintToServer("%s", message);
				else
					PrintToConsole(client, "%s", message);
			}

			if (type & MSG_CENTER)
				PrintCenterText(client, "%s", message);

			if (type & MSG_HINT)
				PrintHintText(client, "%s", message);
		}
	}
}

void ApplyColorTag(char[] message, int maxLen) {

	ReplaceString(message, maxLen, "{white}", "\x01", false);
	ReplaceString(message, maxLen, "{default}", "\x01", false);
	ReplaceString(message, maxLen, "{cyan}", "\x03", false);
	ReplaceString(message, maxLen, "{lightgreen}", "\x03", false);
	ReplaceString(message, maxLen, "{orange}", "\x04", false);
	ReplaceString(message, maxLen, "{olive}", "\x04", false);
	ReplaceString(message, maxLen, "{green}", "\x05", false);
}

void RemoveColorTag(char[] message, int maxLen) {

	ReplaceString(message, maxLen, "{white}", "", false);
	ReplaceString(message, maxLen, "{default}", "", false);
	ReplaceString(message, maxLen, "{cyan}", "", false);
	ReplaceString(message, maxLen, "{lightgreen}", "", false);
	ReplaceString(message, maxLen, "{orange}", "", false);
	ReplaceString(message, maxLen, "{olive}", "", false);
	ReplaceString(message, maxLen, "{green}", "", false);
}

enum L4D2GlowType
{
	L4D2Glow_None					= 0,
	L4D2Glow_OnUse					= 1,
	L4D2Glow_OnLookAt				= 2,
	L4D2Glow_Constant				= 3
}


/**
 * Set entity glow type.
 *
 * @param entity		Entity index.
 * @parma type			Glow type.
 * @noreturn
 * @error				Invalid entity index or entity does not support glow.
 */
// L4D2 only.
stock void L4D2_SetEntityGlow_Type(int entity, L4D2GlowType type)
{
	SetEntProp(entity, Prop_Send, "m_iGlowType", type);
}

/**
 * Set entity glow range.
 *
 * @param entity		Entity index.
 * @parma range			Glow range.
 * @noreturn
 * @error				Invalid entity index or entity does not support glow.
 */
// L4D2 only.
stock void L4D2_SetEntityGlow_Range(int entity, int range)
{
	SetEntProp(entity, Prop_Send, "m_nGlowRange", range);
}

/**
 * Set entity glow min range.
 *
 * @param entity		Entity index.
 * @parma minRange		Glow min range.
 * @noreturn
 * @error				Invalid entity index or entity does not support glow.
 */
// L4D2 only.
stock void L4D2_SetEntityGlow_MinRange(int entity, int minRange)
{
	SetEntProp(entity, Prop_Send, "m_nGlowRangeMin", minRange);
}

/**
 * Set entity glow color.
 *
 * @param entity		Entity index.
 * @parma colorOverride	Glow color, RGB.
 * @noreturn
 * @error				Invalid entity index or entity does not support glow.
 */
// L4D2 only.
stock void L4D2_SetEntityGlow_Color(int entity, int colorOverride[3])
{
	SetEntProp(entity, Prop_Send, "m_glowColorOverride", colorOverride[0] + (colorOverride[1] * 256) + (colorOverride[2] * 65536));
}

/**
 * Set entity glow flashing state.
 *
 * @param entity		Entity index.
 * @parma flashing		Whether glow will be flashing.
 * @noreturn
 * @error				Invalid entity index or entity does not support glow.
 */
// L4D2 only.
stock void L4D2_SetEntityGlow_Flashing(int entity, bool flashing)
{
	SetEntProp(entity, Prop_Send, "m_bFlashing", flashing);
}