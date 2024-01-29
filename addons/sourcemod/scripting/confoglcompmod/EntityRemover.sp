#if defined __entity_remover_included
	#endinput
#endif
#define __entity_remover_included

#define ER_MODULE_NAME				"EntityRemover"

#define DEBUG_ER					false

#define ER_KV_ACTION_KILL			1

#define ER_KV_PROPTYPE_INT			1
#define ER_KV_PROPTYPE_FLOAT		2
#define ER_KV_PROPTYPE_BOOL			3
#define ER_KV_PROPTYPE_STRING		4

#define ER_KV_CONDITION_EQUAL		1
#define ER_KV_CONDITION_NEQUAL		2
#define ER_KV_CONDITION_LESS		3
#define ER_KV_CONDITION_GREAT		4
#define ER_KV_CONDITION_CONTAINS	5

static bool
	ER_bDebugEnabled = DEBUG_ER,
	ER_bKillParachutist = true,
	ER_bReplaceGhostHurt = false;

static ConVar
	ER_hKillParachutist = null,
	ER_hReplaceGhostHurt = null;

static KeyValues
	kERData = null;

void ER_OnModuleStart()
{
	ER_hKillParachutist = CreateConVarEx("remove_parachutist", "1", "Removes the parachutist from c3m2", _, true, 0.0, true, 1.0);
	ER_hReplaceGhostHurt = CreateConVarEx( \
		"disable_ghost_hurt", \
		"0", \
		"Replaces all trigger_ghost_hurt with trigger_hurt, blocking ghost spawns from dying.", \
		_, true, 0.0, true, 1.0 \
	);

	ER_bKillParachutist = ER_hKillParachutist.BoolValue;
	ER_bReplaceGhostHurt = ER_hReplaceGhostHurt.BoolValue;

	ER_hKillParachutist.AddChangeHook(ER_ConVarChange);
	ER_hReplaceGhostHurt.AddChangeHook(ER_ConVarChange);

	ER_KV_Load();

	RegAdminCmd("confogl_erdata_reload", ER_KV_CmdReload, ADMFLAG_CONFIG);

	HookEvent("round_start", ER_RoundStart_Event, EventHookMode_PostNoCopy);
}

static void ER_ConVarChange(ConVar hConvar, const char[] sOldValue, const char[] sNewValue)
{
	ER_bKillParachutist = ER_hKillParachutist.BoolValue;
	ER_bReplaceGhostHurt = ER_hReplaceGhostHurt.BoolValue;
}

void ER_OnModuleEnd()
{
	ER_KV_Close();
}

static void ER_KV_Close()
{
	if (kERData != null) {
		delete kERData;
		kERData = null;
	}
}

static void ER_KV_Load()
{
	char sNameBuff[PLATFORM_MAX_PATH], sDescBuff[256], sValBuff[32];

	if (ER_bDebugEnabled || IsDebugEnabled()) {
		LogMessage("[%s] Loading EntityRemover KeyValues", ER_MODULE_NAME);
	}

	kERData = new KeyValues("EntityRemover");

	BuildConfigPath(sNameBuff, sizeof(sNameBuff), "entityremove.txt"); //Build our filepath

	if (!kERData.ImportFromFile(sNameBuff)) {
		Debug_LogError(ER_MODULE_NAME, "Couldn't load EntityRemover data!");
		ER_KV_Close();
		return;
	}

	// Create cvars for all entity removes
	if (ER_bDebugEnabled || IsDebugEnabled()) {
		LogMessage("[%s] Creating entry CVARs", ER_MODULE_NAME);
	}

	kERData.GotoFirstSubKey();

	do {
		kERData.GotoFirstSubKey();

		do {
			kERData.GetString("cvar", sNameBuff, sizeof(sNameBuff));
			kERData.GetString("cvar_desc", sDescBuff, sizeof(sDescBuff));
			kERData.GetString("cvar_val", sValBuff, sizeof(sValBuff));

			CreateConVarEx(sNameBuff, sValBuff, sDescBuff);

			if (ER_bDebugEnabled || IsDebugEnabled()) {
				LogMessage("[%s] Creating CVAR %s", ER_MODULE_NAME, sNameBuff);
			}

		} while(kERData.GotoNextKey());

		kERData.GoBack();
	} while(kERData.GotoNextKey());

	kERData.Rewind();
}

static Action ER_KV_CmdReload(int client, int args)
{
	if (!IsPluginEnabled()) {
		return Plugin_Continue;
	}

	ReplyToCommand(client, "[ER] Reloading EntityRemoveData");
	ER_KV_Reload();

	return Plugin_Handled;
}

static void ER_KV_Reload()
{
	ER_KV_Close();
	ER_KV_Load();
}

static bool ER_KV_TestCondition(int lhsval, int rhsval, int condition)
{
	switch (condition) {
		case ER_KV_CONDITION_EQUAL: {
			return (lhsval == rhsval);
		}
		case ER_KV_CONDITION_NEQUAL: {
			return (lhsval != rhsval);
		}
		case ER_KV_CONDITION_LESS: {
			return (lhsval < rhsval);
		}
		case ER_KV_CONDITION_GREAT: {
			return (lhsval > rhsval);
		}
	}

	return false;
}

static bool ER_KV_TestConditionFloat(float lhsval, float rhsval, int condition)
{
	switch (condition) {
		case ER_KV_CONDITION_EQUAL: {
			return (lhsval == rhsval);
		}
		case ER_KV_CONDITION_NEQUAL: {
			return (lhsval != rhsval);
		}
		case ER_KV_CONDITION_LESS: {
			return (lhsval < rhsval);
		}
		case ER_KV_CONDITION_GREAT: {
			return (lhsval > rhsval);
		}
	}

	return false;
}

static bool ER_KV_TestConditionString(const char[] lhsval, const char[] rhsval, int condition)
{
	switch (condition) {
		case ER_KV_CONDITION_EQUAL: {
			return (strcmp(lhsval, rhsval) == 0);
		}
		case ER_KV_CONDITION_NEQUAL: {
			return (strcmp(lhsval, rhsval) != 0);
		}
		case ER_KV_CONDITION_CONTAINS: {
			return (StrContains(lhsval, rhsval) != -1);
		}
	}

	return false;
}

// Returns true if the entity is still alive (not killed)
static bool ER_KV_ParseEntity(KeyValues kEntry, int iEntity)
{
	char sBuffer[64], mapname[64];

	// Check CVAR for this entry
	kEntry.GetString("cvar", sBuffer, sizeof(sBuffer));

	if (strlen(sBuffer) && !(FindConVarEx(sBuffer).BoolValue)) {
		return true;
	}

	// Check MapName for this entry
	GetCurrentMap(mapname, sizeof(mapname));

	kEntry.GetString("map", sBuffer, sizeof(sBuffer));
	if (strlen(sBuffer) && StrContains(sBuffer, mapname) == -1) {
		return true;
	}

	kEntry.GetString("excludemap", sBuffer, sizeof(sBuffer));
	if (strlen(sBuffer) && StrContains(sBuffer, mapname) != -1) {
		return true;
	}

	// Do property check for this entry
	kEntry.GetString("property", sBuffer, sizeof(sBuffer));
	if (strlen(sBuffer)) {
		int proptype = kEntry.GetNum("proptype");

		switch (proptype) {
			case ER_KV_PROPTYPE_INT, ER_KV_PROPTYPE_BOOL: {
				int rhsval = kEntry.GetNum("propval");
				PropType prop_type = view_as<PropType>(kEntry.GetNum("propdata"));
				int lhsval = GetEntProp(iEntity, prop_type, sBuffer);

				if (!ER_KV_TestCondition(lhsval, rhsval, kEntry.GetNum("condition"))) {
					return true;
				}
			}
			case ER_KV_PROPTYPE_FLOAT: {
				float rhsval = kEntry.GetFloat("propval");
				PropType prop_type = view_as<PropType>(kEntry.GetNum("propdata"));
				float lhsval = GetEntPropFloat(iEntity, prop_type, sBuffer);

				if (!ER_KV_TestConditionFloat(lhsval, rhsval, kEntry.GetNum("condition"))) {
					return true;
				}
			}
			case ER_KV_PROPTYPE_STRING: {
				char rhsval[64], lhsval[64];
				kEntry.GetString("propval", rhsval, sizeof(rhsval));
				PropType prop_type = view_as<PropType>(kEntry.GetNum("propdata"));
				GetEntPropString(iEntity, prop_type, sBuffer, lhsval, sizeof(lhsval));

				if (!ER_KV_TestConditionString(lhsval, rhsval, kEntry.GetNum("condition"))) {
					return true;
				}
			}
		}
	}

	int iAction = kEntry.GetNum("action");
	return (ER_KV_TakeAction(iAction, iEntity));
}

// Returns true if the entity is still alive (not killed)
static bool ER_KV_TakeAction(int action, int iEntity)
{
	switch (action) {
		case ER_KV_ACTION_KILL: {
			if (ER_bDebugEnabled || IsDebugEnabled()) {
				LogMessage("[%s]     Killing!", ER_MODULE_NAME);
			}

			KillEntity(iEntity);

			return false;
		}
		default: {
			Debug_LogError(ER_MODULE_NAME, "ParseEntity Encountered bad action!");
		}
	}

	return true;
}

static bool ER_KillParachutist(int ent)
{
	char buf[32];
	GetCurrentMap(buf, sizeof(buf));

	if (strcmp(buf, "c3m2_swamp") == 0) {
		GetEntPropString(ent, Prop_Data, "m_iName", buf, sizeof(buf));

		if (!strncmp(buf, "parachute_", 10)) {
			KillEntity(ent);

			return true;
		}
	}

	return false;
}

static bool ER_ReplaceTriggerHurtGhost(int ent)
{
	char buf[MAX_ENTITY_NAME_LENGTH];
	GetEdictClassname(ent, buf, sizeof(buf));

	if (strcmp(buf, "trigger_hurt_ghost") == 0) {
		// Replace trigger_hurt_ghost with trigger_hurt
		int replace = CreateEntityByName("trigger_hurt");
		if (replace == -1) {
			Debug_LogError(ER_MODULE_NAME, "Could not create trigger_hurt entity!");
			return false;
		}

		// Get modelname
		char model[PLATFORM_MAX_PATH];
		GetEntPropString(ent, Prop_Data, "m_ModelName", model, sizeof(model));

		// Get position and rotation
		float pos[3], ang[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		GetEntPropVector(ent, Prop_Send, "m_angRotation", ang);

		// Kill the old one
		KillEntity(ent);

		// Set the values for the new one
		DispatchKeyValue(replace, "StartDisabled", "0");
		DispatchKeyValue(replace, "spawnflags", "67");
		DispatchKeyValue(replace, "damagetype", "32");
		DispatchKeyValue(replace, "damagemodel", "0");
		DispatchKeyValue(replace, "damagecap", "10000");
		DispatchKeyValue(replace, "damage", "10000");
		DispatchKeyValue(replace, "model", model);

		DispatchKeyValue(replace, "filtername", "filter_infected");

		// Spawn the new one
		TeleportEntity(replace, pos, ang, NULL_VECTOR);
		DispatchSpawn(replace);
		ActivateEntity(replace);

		return true;
	}

	return false;
}

static void ER_RoundStart_Event(Event hEvent, const char[] sEventName, bool bdontBroadcast)
{
	if (!IsPluginEnabled()) {
		return;
	}

	CreateTimer(0.3, ER_RoundStart_Timer, _, TIMER_FLAG_NO_MAPCHANGE);
}

static Action ER_RoundStart_Timer(Handle hTimer)
{
	char sBuffer[MAX_ENTITY_NAME_LENGTH];
	if (ER_bDebugEnabled || IsDebugEnabled()) {
		LogMessage("[%s] Starting RoundStart Event", ER_MODULE_NAME);
	}

	if (kERData != null) {
		kERData.Rewind();
	}

	int iEntCount = GetEntityCount();

	for (int ent = (MaxClients + 1); ent <= iEntCount; ent++) {
		if (!IsValidEdict(ent)) {
			continue;
		}

		GetEdictClassname(ent, sBuffer, sizeof(sBuffer));

		if (ER_bKillParachutist && ER_KillParachutist(ent)) {
			//empty
		} else if (ER_bReplaceGhostHurt && ER_ReplaceTriggerHurtGhost(ent)) {
			//empty
		} else if (kERData != null && kERData.JumpToKey(sBuffer)) {
			if (ER_bDebugEnabled || IsDebugEnabled()) {
				LogMessage("[%s] Dealing with an instance of %s", ER_MODULE_NAME, sBuffer);
			}

			kERData.GotoFirstSubKey();

			do {
				// Parse each entry for this entity's classname
				// Stop if we run out of entries or we have killed the entity
				if (!ER_KV_ParseEntity(kERData, ent)) {
					break;
				}
			} while (kERData.GotoNextKey());

			kERData.Rewind();
		}
	}

	return Plugin_Stop;
}
