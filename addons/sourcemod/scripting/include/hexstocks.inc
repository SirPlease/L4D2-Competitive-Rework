#if defined _hexstocks_included
#endinput
#endif
#define _hexstocks_included

#define MAX_ENTITIES 2048

#include <sourcemod>
#include <sdktools>

#undef REQUIRE_EXTENSIONS
#include <cstrike>
#define REQUIRE_EXTENSIONS

/*
INCLUDE MERGE OF MYSTOCKS(shanpu)teamgames-stocks/menu-stocks(KissLick) & some other!
*/

//Easy loops
#pragma deprecated Dont use macro loops
#define LoopClients(%1) for (int %1 = 1; %1 <= MaxClients; %1++) if (IsClientInGame(%1))
#pragma deprecated Dont use macro loops
#define LoopValidClients(%1,%2,%3) for (int %1 = 1; %1 <= MaxClients; %1++) if (IsValidClient(%1,%2,%3))

/*************************************** CLIENT ***************************/


/**
* Check if for a valid client
*
*
* @param client				Client Index
* @param AllowBots				Allow Bots?
* @param AllowDead				Allow Dead players?
* @noreturn
*/
stock bool IsValidClient(int client, bool AllowBots = false, bool AllowDead = false)
{
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !AllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!AllowDead && !IsPlayerAlive(client)))
	{
		return false;
	}
	return true;
}

/**
* Checks if user flags (Root is always true)
*
*
* @param client			Client Index
* @param flags				Flags to check, enter comma to separate flags.
* @return					True if client has the flags, false otherwise.
*/
stock bool CheckAdminFlag(int client, const char[] flags)
{
	int iCount = 0;
	char sflagNeed[22][8], sflagFormat[64];
	bool bEntitled = false;
	
	Format(sflagFormat, sizeof(sflagFormat), flags);
	ReplaceString(sflagFormat, sizeof(sflagFormat), " ", "");
	iCount = ExplodeString(sflagFormat, ",", sflagNeed, sizeof(sflagNeed), sizeof(sflagNeed[]));
	
	for (int i = 0; i < iCount; i++)
	{
		if ((GetUserFlagBits(client) & ReadFlagString(sflagNeed[i])) || (GetUserFlagBits(client) & ADMFLAG_ROOT))
		{
			bEntitled = true;
			break;
		}
	}
	
	return bEntitled;
}

/**
* Checks if user flags
*
*
* @param client			Client Index
* @param flags				Flags to check, enter comma to separate flags.
* @return					True if client has the flags, false otherwise.
*/
stock bool CheckAdminFlagEx(int client, const char[] flags)
{
	int iCount = 0;
	char sflagNeed[22][8], sflagFormat[64];
	bool bEntitled = false;
	
	Format(sflagFormat, sizeof(sflagFormat), flags);
	ReplaceString(sflagFormat, sizeof(sflagFormat), " ", "");
	iCount = ExplodeString(sflagFormat, ",", sflagNeed, sizeof(sflagNeed), sizeof(sflagNeed[]));
	
	for (int i = 0; i < iCount; i++)
	{
		if ((GetUserFlagBits(client) & ReadFlagString(sflagNeed[i]) == ReadFlagString(sflagNeed[i])))
		{
			bEntitled = true;
			break;
		}
	}
	
	return bEntitled;
}



/**
* Returs the client's current weapon
*
* @param client			Client Index
* @return				Weapon Index or -1 if not found
*/
stock int GetClientActiveWeapon(int client)
{
	return GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
}


/**
* Get the target client
*
* @param client			Client Index
* @param argnum			Number of the arg
* @return					Client Index or -1 on failure.
*/
stock int GetTarget(int client, int argnum)
{
	char sTarget[32];
	
	GetCmdArg(argnum, sTarget, sizeof(sTarget));
	return FindTarget(client, sTarget);
}


/**
* Get player count of a team
*
* @param team				Team (-1 for total)
* @param alive				Count only alive players?
* @return					Team Count
*/
stock int GetAliveTeamCount(int team = -1, bool alive = true)
{
	int count = 0;
	for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i) && (IsPlayerAlive(i) || !alive) && (GetClientTeam(i) == team || team == -1))
		count++;
	
	return count;
}



/**
* Get random player of a team
*
*
* @param team				Team, -1 for any.
* @param True				True to include only alive players.
* @return					A random client index.
*/
stock int GetRandomPlayer(int team = -1, bool OnlyAlive = true)
{
	int[] clients = new int[MaxClients];
	int clientCount;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && (team == -1 || GetClientTeam(i) == team) && (!OnlyAlive || !IsPlayerAlive(i)))
		{
			clients[clientCount++] = i;
		}
	}
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount - 1)];
	
}

/**
* Set a client player model and arms.
* This functions precaches the models.
*
* @param model				Model path.
* @param arms				Arms path.
* @noreturn
*/
stock void SetPlayerModelAndArms(int client, const char model[PLATFORM_MAX_PATH], const char arms[PLATFORM_MAX_PATH])
{
	if (!IsModelPrecached(model))
		PrecacheModel(model);
		
	if (!IsModelPrecached(arms))
		PrecacheModel(arms)
		
	SetEntPropString(client, Prop_Send, "m_szArmsModel", arms);
	
	DataPack data = new DataPack();
	data.WriteCell(GetClientUserId(client));
	data.WriteString(model);
	RequestFrame(Frame_SetModel, data);
}

#define DEFAULT_MODEL "models/player/tm_anarchist.mdl"

/**
* Set a client player arms.
* This functions precaches the models.
*
* @param model				Model path.
* @param arms				Arms path.
* @noreturn
*/
stock void SetPlayerArms(int client, const char arms[PLATFORM_MAX_PATH])
{
	if (!IsModelPrecached(DEFAULT_MODEL))
		PrecacheModel(DEFAULT_MODEL);
		
	if (!IsModelPrecached(arms))
		PrecacheModel(arms);
		
	char sOldModel[PLATFORM_MAX_PATH];
	GetEntityModel(client, sOldModel);
	
	SetEntityModel(client, DEFAULT_MODEL);
	SetEntPropString(client, Prop_Send, "m_szArmsModel", arms);
	
	DataPack data = new DataPack();
	data.WriteCell(GetClientUserId(client));
	data.WriteString(sOldModel);
	RequestFrame(Frame_SetModel, data);
}

static stock void Frame_SetModel(DataPack data)
{
	data.Reset();
	char sModel[PLATFORM_MAX_PATH];
	int client = GetClientOfUserId(data.ReadCell());
	if (!client)
	{
		delete data;
		return;
	}
	data.ReadString(sModel, sizeof sModel);
	SetEntityModel(client, sModel);
	delete data;
}

stock int GetFov(int client)
{
	return GetEntProp(client, Prop_Send, "m_iFOV");
}

stock void SetFov(int client, int fov)
{
	SetEntProp(client, Prop_Send, "m_iFOV", fov);
}
/*********************************** NUMBERS *****************************/

/**
* Checks if an number is even
*
*
* @param num				Number to check
* @return					True if number is even, false otherwise.
*/
stock bool IsEven(int num)
{
	return (num & 1) == 0;
}

/**
* Checks if an number is odd
*
*
* @param num				Number to check
* @return					True if number is odd, false otherwise.
*/
stock bool IsOdd(int num)
{
	return (num & 1) == 1;
}

/**
* Get the client aim position.
*
*
* @param client				Client Index
* @param pos				Position vector
* @param mask				Custom TraceRay mask
*
* @return					True if the trace did it, false otherwise.
*/
stock bool GetClientAimPosition(int client, float pos[3], int mask = MASK_SOLID)
{
	float vPos[3];
	float vAng[3];
	
	GetClientEyePosition(client, vPos);
	GetClientEyeAngles(client, vAng);
	
	TR_TraceRayFilter(vPos, vAng, mask, RayType_Infinite, Filter_NoSelf, client);
	if (!TR_DidHit())
		return false;
	
	TR_GetEndPosition(pos);
	return true;
}

/**
* Get the client aim target.
*
*
* @param client				Client Index
* @param mask				Custom TraceRay mask
*
* @return					The entity index or -1 if none is found.
*/
stock int GetClientAimTarget2(int client, int mask = MASK_SOLID)
{
	float vPos[3];
	float vAng[3];
	
	GetClientEyePosition(client, vPos);
	GetClientEyeAngles(client, vAng);
	
	TR_TraceRayFilter(vPos, vAng, mask, RayType_Infinite, Filter_NoSelf, client);
	
	return TR_GetEntityIndex();
}

public bool Filter_NoSelf(int entity, int contentsMask, any data)
{
	return entity != data;
}
 
stock bool IsClientInView(int viewer, int target, float fMaxDistance=0.0, float fThreshold=0.73)
{
	// Retrieve view and target eyes position
	float fViewPos[3];  
	float fViewAng[3];  
	float fViewDir[3];

	float fTargetPos[3];
	float fTargetDir[3];
	float fDistance[3];

	GetClientEyePosition(viewer, fViewPos);
	GetClientEyeAngles(viewer, fViewAng);
	GetClientEyePosition(target, fTargetPos);

	// Calculate view direction
	fViewAng[0] = fViewAng[2] = 0.0;
	GetAngleVectors(fViewAng, fViewDir, NULL_VECTOR, NULL_VECTOR);

	// Calculate distance to viewer to see if it can be seen.
	fDistance[0] = fTargetPos[0]-fViewPos[0];
	fDistance[1] = fTargetPos[1]-fViewPos[1];
	fDistance[2] = 0.0;
	if (fMaxDistance != 0.0)
	{
		if (((fDistance[0]*fDistance[0])+(fDistance[1]*fDistance[1])) >= (fMaxDistance*fMaxDistance))
			return false;
	}

	// Check dot product. If it's negative, that means the viewer is facing
	// backwards to the target.
	NormalizeVector(fDistance, fTargetDir);
	if (GetVectorDotProduct(fViewDir, fTargetDir) < fThreshold)
		return false;

	// Now check if there are no obstacles in between through raycasting
	Handle trace = TR_TraceRayFilterEx(fViewPos, fTargetPos, MASK_PLAYERSOLID_BRUSHONLY, RayType_EndPoint, ClientViewsFilter);
	if (TR_DidHit(trace))
	{
		delete trace;
		return false;
	}
	delete trace;

	// Done, it's visible
	return true;
}

stock bool ClientViewsFilter(int entity, int mask, any junk)
{
	if (entity >= 1 && entity <= MaxClients) 
		return false;

	return true;
}
/********************************** WEAPONS ********************************/


/**
* Strip All Weapons & the knife slot twice for taser
*
*
* @param client				Client Index
* @noreturn
*/
stock void StripAllPlayerWeapons(int client)
{
	int weapon;
	int index;
	
	while((weapon = GetNextWeapon(client, index)) != -1)
	{
		CS_DropWeapon(client, weapon, false, true);
		RemoveEdict(weapon);
	}
}

/**
* Gives an Item to a client with custom ammos
*
* @param client			Client Index
* @param weapon			Weapon Name
* @param clip				Ammo ammount in the clip
* @param ammo				Total ammo ammount
* @return					Entity Index
*/
stock int GivePlayerItemAmmo(int client, const char[] weapon, int clip = -1, int ammo = -1)
{
	int weaponEnt = GivePlayerItem(client, weapon);
	
	SetPlayerWeaponAmmo(client, weaponEnt, clip, ammo);
	
	return weaponEnt;
}

/**
* Set ammo account for a weapon
*
* @param client			Client Index
* @param weapon			Weapon Index
* @param clip				Ammo ammount in the clip
* @param ammo				Total ammo ammount
* @noreturn
*/
stock void SetPlayerWeaponAmmo(int client, int weaponEnt, int clip = -1, int ammo = -1)
{
	#pragma unused client

	if (weaponEnt == INVALID_ENT_REFERENCE || !IsValidEdict(weaponEnt))
		return;
		
	if (clip != -1)
		SetEntProp(weaponEnt, Prop_Data, "m_iClip1", clip);
			 
	//TODO FIXED GIVEN AMMOS
	if (ammo != -1)
	{
		SetEntProp(weaponEnt, Prop_Send, "m_iPrimaryReserveAmmoCount", ammo);
		SetEntProp(weaponEnt, Prop_Send, "m_iSecondaryReserveAmmoCount", ammo);
	}
}

/**
* Gives an Item to a client removing the current weapon
*
* @param client			Client Index
* @param weapon
* @return					Itea Index
*/
stock int GivePlayerItemRemove(int client, const char[] weapon, int slot)
{
	int weaponEnt = GetPlayerWeaponSlot(client, slot);
	if (weaponEnt != -1)
	{
		RemovePlayerItem(client, weaponEnt);
		AcceptEntityInput(weaponEnt, "Kill");
	}
	return GivePlayerItem(client, weapon);
}



// Easy precache & prepare download for models (icons)
stock void PrecacheModelAnyDownload(char[] sModel)
{
	if (strlen(sModel) == 0)
		return;
	
	#if defined _smartdm_include
	Downloader_AddFileToDownloadsTable(sModel);
	#else
	AddFileToDownloadsTable(sModel);
	#endif
	PrecacheModel(sModel, true);
}

//Adaption for smlib
stock int GetNextWeapon(int client, int &weaponIndex) 
{ 
    static int weaponsOffset = -1; 
    if (weaponsOffset == -1) 
        weaponsOffset = FindDataMapInfo(client, "m_hMyWeapons"); 
     
    int offset = weaponsOffset + (weaponIndex * 4); 
     
    int weapon; 
    while (weaponIndex < 48)  
    { 
        weaponIndex++; 
         
        weapon = GetEntDataEnt2(client, offset); 
         
        if (IsValidEdict(weapon))  
            return weapon; 
         
        offset += 4; 
    } 
     
    return -1; 
} 

stock bool HasWeapon(int client, const char[] classname) 
{ 
    int index; 
    int weapon; 
    char sName[64]; 
     
    while((weapon = GetNextWeapon(client, index)) != -1) 
    { 
        GetEdictClassname(weapon, sName, sizeof(sName)); 
        if (StrEqual(sName, classname)) 
            return true; 
    } 
    return false; 
}

stock int GetWeaponByClassname(int client, const char[] classname)
{
    int index; 
    int weapon; 
    char sName[64]; 
     
    while((weapon = GetNextWeapon(client, index)) != -1) 
    { 
        GetEdictClassname(weapon, sName, sizeof(sName)); 
        if (StrEqual(sName, classname)) 
            return weapon; 
    } 
    return -1; 
}
/****************************** COMMAND ARGS **************************/


/**
* Retrives a command argument given its index as int, from the console or server command
*
* @param argnum			Arg number
* @return					Int Value of Arg
*/
#if SOURCEMOD_V_MINOR < 11
stock int GetCmdArgInt(int argnum)
{
	char value[256];
	GetCmdArg(argnum, value, sizeof(value));
	return StringToInt(value);
}
#endif

/**
* Retrives a command argument given its index as float, from the console or server command
*
* @param argnum			Arg number
* @return					Float Value of Arg
*/
#if SOURCEMOD_V_MINOR < 11
stock float GetCmdArgFloat(int argnum)
{
	char value[256];
	GetCmdArg(argnum, value, sizeof(value));
	return StringToFloat(value);
}
#endif

/**
* Retrives a command argument given its index as bool, from the console or server command
*
* @param argnum			Arg number
* @return					Bool Value of Arg
*/
stock bool GetCmdArgBool(int argnum)
{
	char value[256];
	GetCmdArg(argnum, value, sizeof(value));
	return view_as<bool>(StringToInt(value));
}

/********************************** CVARS **************************************/

/**
* Easy silent change of ConVars - Boolean
*
*
* @param cvarName				Name of cvar
* @param value					New value of cvar
* @noreturn
*/
stock void SetCvar(char[] cvarName, int value)
{
	ConVar IntCvar = FindConVar(cvarName);
	if (IntCvar == null)return;
	
	int flags = IntCvar.Flags;
	flags &= ~FCVAR_NOTIFY;
	IntCvar.Flags = flags;
	IntCvar.IntValue = value;
	
	flags |= FCVAR_NOTIFY;
	IntCvar.Flags = flags;
}



/**
* Easy silent change of ConVars - Floats
*
*
* @param cvarName				Name of cvar
* @param value					New value of cvar
* @noreturn
*/
stock void SetCvarFloat(char[] cvarName, float value)
{
	ConVar FloatCvar = FindConVar(cvarName);
	if (FloatCvar == null)return;
	
	int flags = FloatCvar.Flags;
	flags &= ~FCVAR_NOTIFY;
	FloatCvar.Flags = flags;
	FloatCvar.FloatValue = value;
	
	flags |= FCVAR_NOTIFY;
	FloatCvar.Flags = flags;
}



/**
* Easy silent change of ConVars - Strings
*
*
* @param cvarName				Name of cvar
* @param value					New value of cvar
* @noreturn
*/
stock void SetCvarString(char[] cvarName, char[] value)
{
	ConVar StringCvar = FindConVar(cvarName);
	if (StringCvar == null)return;
	
	int flags = StringCvar.Flags;
	flags &= ~FCVAR_NOTIFY;
	StringCvar.Flags = flags;
	StringCvar.SetString(value);
	
	flags |= FCVAR_NOTIFY;
	StringCvar.Flags = flags;
}


/********************************************** ENTITIES *********************************************/


/**
* Checks if a entity or edict is valid and not a client
*
*
* @param cvarName				Name of cvar
* @param value					New value of cvar
* @noreturn
*/
stock bool IsValidEnt(int ent)
{
	if (ent == INVALID_ENT_REFERENCE || ent <= MaxClients || !IsValidEntity(ent) || !IsValidEdict(ent))
	{
		return false;
	}
	return true;
}

/**
* Sets an entity's speed
*
* @param entity			Entity Index
* @param speed				Speed to set
* @noreturn
*/
stock void SetEntitySpeed(int entity, float speed = 1.0)
{
	SetEntPropFloat(entity, Prop_Data, "m_flLaggedMovementValue", speed);
}

/**
* Gets an entity's Speed
*
* @param entity			Entity Index
* @return					Amount of Speed
*/
stock float GetEntitySpeed(int entity)
{
	return GetEntPropFloat(entity, Prop_Data, "m_flLaggedMovementValue");
}

/**
* Gets an entity's name
*
* @param entity			Entity Index
*
* @noreturn				
*/
stock void GetEntityName(int entity, char[] name, int maxlen)
{	
	GetEntPropString(entity, Prop_Data, "m_iName", name, maxlen);
}

/**
* Sets an entity's name
*
* @param entity			Entity Index
* @param format			Formatting rules.
* @param ...			Variable number of format parameters.
* @noreturn				
*/
stock void SetEntityName(int entity, char[] format, any...)
{
	char sName[128];
	VFormat(sName, sizeof(sName), format, 3);
	
	SetEntPropString(entity, Prop_Data, "m_iName", sName);
}

/**
* Get an entity origin
*
* @param entity		Entity index.
* @param origin		Vector to store origin.
* @noreturn
*/
stock void GetEntityOrigin(int entity, float origin[3])
{
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
}

/**
* Get an entity angles
*
* @param entity		Entity index.
* @param origin		Vector to store origin.
* @noreturn
*/
stock void GetEntityAngles(int entity, float angles[3])
{
	GetEntPropVector(entity, Prop_Data, "m_angRotation", angles);
}

/**
* Get an entity model
*
* @param entity		Entity index.
* @param origin		String to store model.
* @noreturn
*/
stock void GetEntityModel(int entity, char model[PLATFORM_MAX_PATH])
{
	GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
}

/********************************** MISC *********************************/

/** Reset client Render Color
*
* @param client				Client Index
* @noreturn
*/
stock void ResetRenderColor(int client)
{
	SetEntityRenderColor(client, 255, 255, 255, 255);
}


/**
* Appends a new item to the end of a menu with a format.
*
* @param menu				Menu Handle.
* @param info				Item information string.
* @param display			Default item display string.
* @param style				Drawing style flags.  Anything other than DEFAULT or
* @param format			Formatting rules
* @param ...				Variable number of format parameters
* @return					True on success, false on failure.
* @error					Invalid Handle or item limit reached.
*/
stock bool AddMenuItemFormat(Handle menu, const char[] info, int style = ITEMDRAW_DEFAULT, const char[] format, any...)
{
	char display[128];
	VFormat(display, sizeof(display), format, 5);
	
	return AddMenuItem(menu, info, display, style);
}


/**
*
* @param LogFile		Buffer to store the path
* @param FileName		File to write the log in
* @param FolderName	Directory/Folder to write the logs in
* @noreturn
*/
stock void SetLogFile(char LogFile[PLATFORM_MAX_PATH], char[] FileName, char[] FolderName)
{
	char sDate[12];
	FormatTime(sDate, sizeof(sDate), "%y-%m-%d");
	Format(LogFile, sizeof(LogFile), "logs/%s/%s-%s.log", FolderName, FileName, sDate);
	
	BuildPath(Path_SM, LogFile, sizeof(LogFile), LogFile);
}


/**
 * Same as OpenFile but if the file does not exist is before created.
 *
 * @param file			File to open.
 * @param mode			Open mode.
 * @param use_valve_fs  If true, the Valve file system will be used instead.
 *                      This can be used to find files existing in valve
 *						search paths, rather than solely files existing directly
 *						in the gamedir.
 * @param valve_path_id	If use_valve_fs, a search path from gameinfo or NULL_STRING for all search paths.
 * @return				A File handle, or null if the file could not be opened.
 */
stock File OpenFileEx(const char[] file, const char[] mode, bool use_valve_fs = false, const char[] valve_path_id = "GAME")
{
	if (!FileExists(file))
	{
		File hFile = OpenFile(file, "w");
		hFile.Close();
	}
	return OpenFile(file, mode, use_valve_fs, valve_path_id);
}

/**
 * Creates a directry if it doesn't exists with 509(775) permissions.
 *
 * @param path		Directory path
 *
 * @return	true if the directory was created, false otherwise.
 */
stock bool CreateDirectoryEx(const char[] path)
{
	if (DirExists(path))
		return false;
	
	return CreateDirectory(path, 509);
}

/**
* Kills a Timer and reset its Handle to null
*
* @param timer		 Timer Handle to kill
* @noreturn
*/
#pragma deprecated Use `delete timer` instead
stock void StopTimer(Handle &timer)
{
	if (timer != null)
	{
		timer.Close();
		timer = null;
	}
}

/**
* Returns if warmup is in progress
*
* @return		True if it is, false otherwise
*/
stock bool IsWarmup()
{
	return (GameRules_GetProp("m_bWarmupPeriod") == 1);
}


// Easy precache & prepare download for sounds
stock void PrecacheSoundAnyDownload(const char[] sSound)
{
	char sBuffer[256];
	PrecacheSound(sSound);
	Format(sBuffer, sizeof(sBuffer), "sound/%s", sSound);
	AddFileToDownloadsTable(sBuffer);
} 

#if defined DEBUG
bool bSendServer = false;
bool bSendConsole = true;
bool bSendChat = true;
bool bLog = true;

char sLogFile[PLATFORM_MAX_PATH] = "addons/sourcemod/logs/hexlogs.txt";
char sPrefix[32] = "[DEBUG]";
#endif

stock bool Debug_Setup(bool server = false, bool console = true, bool chat = true, bool log = true)
{
	#if defined DEBUG
	bSendServer = server;
	bSendConsole = console;
	bSendChat = chat;
	bLog = log
	return true;
	#else
	#pragma unused server
	#pragma unused console
	#pragma unused chat
	#pragma unused log
	return false;
	#endif
}

stock bool Debug_Prefix(const char[] prefix)
{
	#if defined DEBUG
	strcopy(sPrefix, sizeof(sPrefix), prefix);
	return true;
	#else
	#pragma unused prefix
	return false;
	#endif
}
stock bool Debug_Print(char[] format, any ...)
{
	#if defined DEBUG
	char sBuffer[512];
	VFormat(sBuffer, sizeof(sBuffer), format, 2);
	Format(sBuffer, sizeof(sBuffer), "[%s] %s", sPrefix, sBuffer);

	if (bSendServer)
		PrintToServer(sBuffer);
	
	if (bSendConsole)
		PrintToConsoleAll(sBuffer);
		
	if (bSendChat)
		PrintToChatAll(sBuffer);
		
	if (bLog)
		LogToFile(sLogFile, sBuffer);
		
	return true;
	#else
	#pragma unused format
	return false;
	#endif
}

stock bool Debug_PrintVector(float vec[3])
{
	#if defined DEBUG
	char sVector[64];
	const char[][] points = {"x", "y", "z"};
	for (int i = 0; i < sizeof(vec), i++)
	{
		Format(sVector, sizeof(sVector), "%s | %c: %2.f", points[i], vec[i]);
	}
	
	if (bSendServer)
		PrintToServer(sVector);
	
	if (bSendConsole)
		PrintToConsoleAll(sVector);
		
	if (bSendChat)
		PrintToChatAll(sVector);
		
	if (bLog)
		LogToFile(sLogFile, sVector);
		
	return true;
	#else
	#pragma unused vec
	return false;
	#endif
}

/**
* Spawn a particle effect.
*
* @param effect		Effect name
* @return			Particle entity index.
*/
stock int CreateParticle(const char[] effect, float pos[3])
{
	int ent = CreateEntityByName("info_particle_system");
	if (ent == -1)
	{
		LogError("Failed to create info_particle_system");
		return -1;
	}

	TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
	DispatchKeyValue(ent, "effect_name", effect);
	SetVariantString("!activator");
	DispatchSpawn(ent);
	ActivateEntity(ent);
	AcceptEntityInput(ent, "Start");


	SetParticleFlags(ent);
	return ent;
}

/**
* Spawn a particle effect parented with the client index.
*
* @param client		Client index.
* @param effect		Effect name
* @return			Particle entity index.
*/
stock int AddParticlesToPlayer(int client, const char[] effect)
{
	int ent = CreateEntityByName("info_particle_system");
	if (ent == -1)
	{
		LogError("Failed to create info_particle_system");
		return -1;
	}
	float vPos[3];
	GetEntityOrigin(client, vPos);
	TeleportEntity(ent, vPos, NULL_VECTOR, NULL_VECTOR);

	DispatchKeyValue(ent, "effect_name", effect);
	SetVariantString("!activator");
	AcceptEntityInput(ent, "SetParent", client, ent);
	DispatchSpawn(ent);
	ActivateEntity(ent);
	AcceptEntityInput(ent, "Start");

	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	SetParticleFlags(ent);
	return ent;
}

/**
* Precache a particle system. (.pcf file without particles/)
*
* @param particleSytem	Particle System.
* @return				Particle system index.
*/
stock int PrecacheParticleSystem(const char[] particleSystem)
{
    static int particleEffectNames = INVALID_STRING_TABLE;

    if (particleEffectNames == INVALID_STRING_TABLE) 
    {
    	particleEffectNames = FindStringTable("ParticleEffectNames")
        if (particleEffectNames == INVALID_STRING_TABLE) 
        {
        	LogError("Unable to find `ParticleEffectNames` string table");
        	return -1;
        }
    }

    int index = FindStringIndex2(particleEffectNames, particleSystem);
    if (index == INVALID_STRING_INDEX) 
    {
        int numStrings = GetStringTableNumStrings(particleEffectNames);
        if (numStrings >= GetStringTableMaxStrings(particleEffectNames)) 
        {
        	LogError("`ParticleEffectNames` max size exceeded");
        	return -1;
        }
        
        AddToStringTable(particleEffectNames, particleSystem);
        index = numStrings;
    }
    
    return index;
}


/**
* Returns the index of a text in a string table. 
*
* @param tableidx		String table id.
* @param str			String to find.
* @return				The index of the matched string or if none -1.
*/
stock int FindStringIndex2(int tableidx, const char[] str)
{
    char buf[1024];
    
    int numStrings = GetStringTableNumStrings(tableidx);
    for (int i=0; i < numStrings; i++) 
    {
        ReadStringTable(tableidx, i, buf, sizeof(buf));
        
        if (StrEqual(buf, str)) {
            return i;
        }
    }
    
    return INVALID_STRING_INDEX;
}

public void SetParticleFlags(int edict) 
{ 
    if (GetEdictFlags(edict) & FL_EDICT_ALWAYS) 
    { 
        SetEdictFlags(edict, (GetEdictFlags(edict) ^ FL_EDICT_ALWAYS)); 
    } 
} 
