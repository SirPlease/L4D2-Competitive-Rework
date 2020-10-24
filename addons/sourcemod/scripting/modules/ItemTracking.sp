#include <sourcemod>
#include <sdktools>

// Item lists for tracking/decoding/etc
enum ItemList {
	IL_PainPills,
	IL_Adrenaline,
	// Not sure we need these.
	//IL_FirstAid,
	//IL_Defib,  
	IL_PipeBomb,
	IL_Molotov,
	IL_VomitJar
};
static Handle:g_hItemListTrie;



// Names for cvars, kv, descriptions
// [ItemIndex][shortname=0,fullname=1,spawnname=2]
enum ItemNames {	
	IN_shortname,	
	IN_longname, 	
	IN_officialname, 	
	IN_modelname 
};

static const String:g_sItemNames[ItemList][ItemNames][] =
{
	{ "pills", "pain pills", "pain_pills", "painpills" },
	{ "adrenaline", "adrenaline shots", "adrenaline", "pipebomb" },
	// { "kits", "first aid kits", "first_aid_kit", "medkit" },
	// { "defib", "defibrillators", "defibrillator", "defibrillator" },
	{ "pipebomb", "pipe bombs", "pipe_bomb", "pipebomb" },
	{ "molotov", "molotovs", "molotov", "molotov" },
	{ "vomitjar", "bile bombs", "vomitjar", "bile_flask" }
};

// Settings for item limiting.
enum ItemLimitSettings
{
	Handle:cvar,
	limitnum
};

// For spawn entires adt_array
enum ItemTracking {
	IT_entity,
	Float:IT_origins,
	Float:IT_origins1,
	Float:IT_origins2,
	Float:IT_angles,
	Float:IT_angles1,
	Float:IT_angles2
};


static Handle:g_hCvarEnabled;
static Handle:g_hCvarConsistentSpawns;
static Handle:g_hCvarMapSpecificSpawns;
// ADT Array Handle for actual item spawns
static Handle:g_hItemSpawns[ItemList];
// CVAR Handle Array for item limits
static Handle:g_hCvarLimits[ItemList];
// Current item limits array
static g_iItemLimits[ItemList];
// Is round 1 over?
static bool:g_bIsRound1Over;

static g_iSaferoomCount[2];
static Handle:g_hSurvivorLimit;
static g_iSurvivorLimit;

static bool:IsModuleEnabled() { return IsPluginEnabled() && GetConVarBool(g_hCvarEnabled); }

static bool:UseConsistentSpawns() { return GetConVarBool(g_hCvarConsistentSpawns); }

static GetMapInfoMode() { return GetConVarInt(g_hCvarMapSpecificSpawns); }

public IT_OnModuleStart()
{
	decl String:sNameBuf[64];
	decl String:sCvarDescBuf[256];
	
	g_hCvarEnabled = CreateConVarEx("enable_itemtracking", "0", "Enable the itemtracking module");
	g_hCvarConsistentSpawns = CreateConVarEx("itemtracking_savespawns", "0", "Keep item spawns the same on both rounds");
	g_hCvarMapSpecificSpawns = CreateConVarEx("itemtracking_mapspecific", "0", "Change how mapinfo.txt overrides work. 0 = ignore mapinfo.txt, 1 = allow limit reduction, 2 = allow limit increases,");
	
	// Create itemlimit cvars
	for(new i = 0; i < _:ItemList; i++)
	{
		Format(sNameBuf, sizeof(sNameBuf), "%s_limit", g_sItemNames[i][IN_shortname]);
		Format(sCvarDescBuf, sizeof(sCvarDescBuf), "Limits the number of %s on each map. -1: no limit; >=0: limit to cvar value", g_sItemNames[i][IN_longname]);
		g_hCvarLimits[i] = CreateConVarEx(sNameBuf, "-1", sCvarDescBuf);
	}
		
	// Create name translation trie
	g_hItemListTrie = CreateItemListTrie();
	
	
	// Create item spawns array;
	for (new i = 0; i < _:ItemList; i++)
	{
		g_hItemSpawns[i] = CreateArray(_:ItemTracking); 
	}
	
	
	HookEvent("round_start", _IT_RoundStartEvent, EventHookMode_PostNoCopy);
	HookEvent("round_end", _IT_RoundEndEvent, EventHookMode_PostNoCopy);
	g_hSurvivorLimit = FindConVar("survivor_limit");
	g_iSurvivorLimit = GetConVarInt(g_hSurvivorLimit);
	HookConVarChange(g_hSurvivorLimit, _IT_SurvivorLimit_Change);
}

public IT_OnMapStart()
{
	for (new i; i < _:ItemList; i++) g_iItemLimits[i] = GetConVarInt(g_hCvarLimits[i]);
	if (GetMapInfoMode())
	{
		decl itemlimit;
		new Handle:kOverrideLimits = CreateKeyValues("ItemLimits");
		CopyMapSubsection(kOverrideLimits, "ItemLimits");
		for (new i = 0; i < _:ItemList; i++)
		{
			itemlimit = GetConVarInt(g_hCvarLimits[i]);
			new temp = KvGetNum(kOverrideLimits, g_sItemNames[i][IN_officialname], itemlimit);
			if (((g_iItemLimits[i] > temp) && (GetMapInfoMode() & 1)) || ((g_iItemLimits[i] < temp) && (GetMapInfoMode() & 2)))
			{
				g_iItemLimits[i] = temp;
			}
			ClearArray(g_hItemSpawns[i]);
		}
		CloseHandle(kOverrideLimits);
	}
	g_bIsRound1Over = false;
}

public _IT_RoundEndEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bIsRound1Over = true;
}

public _IT_RoundStartEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_iSaferoomCount[START_SAFEROOM - 1] = 0;
	g_iSaferoomCount[END_SAFEROOM - 1] = 0;
	// Mapstart happens after round_start most of the time, so we need to wait for g_bIsRound1Over.
	// Plus, we don't want to have conflicts with EntityRemover.
	CreateTimer(1.0, IT_RoundStartTimer);
}

public Action:IT_RoundStartTimer(Handle:timer)
{
	if(!g_bIsRound1Over)
	{
		// Round1
		if(IsModuleEnabled())
		{
			EnumAndElimSpawns();
		}
	}
	else
	{
		// Round2
		if(IsModuleEnabled())
		{
			if(UseConsistentSpawns())
			{
				GenerateStoredSpawns();
			}
			else
			{
				EnumAndElimSpawns(); 
			}
		}
	}
	return Plugin_Handled;
}

public _IT_SurvivorLimit_Change(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_iSurvivorLimit = StringToInt(newValue);
}

static EnumAndElimSpawns()
{
	if(IsDebugEnabled())
	{
		LogMessage("[IT] Resetting g_iSaferoomCount and Enumerating and eliminating spawns...");
	}
	EnumerateSpawns();
	RemoveToLimits();
}

static GenerateStoredSpawns()
{
	KillRegisteredItems();
	SpawnItems();
}

// For 3.0 rounds library
/* public L4D2_OnRealRoundStart(roundNum)
{
	if(roundNum == 1)
	{
		EnumerateSpawns();
		RemoveToLimits();
	}
	else
	{
		// We kill off all items we recognize.
		// Unlimited items will be replaced, limited items will be spawned,
		// and killed items will stay killed
		KillRegisteredItems();
		// Spawn up the same items that existed in round 1
		SpawnItems();
	}

}*/

// Produces the lookup trie for weapon spawn entities
//		to translate to our ADT array of spawns
static Handle:CreateItemListTrie()
{
	new Handle:mytrie = CreateTrie();
	SetTrieValue(mytrie, "weapon_pain_pills_spawn", IL_PainPills);
	SetTrieValue(mytrie, "weapon_pain_pills", IL_PainPills);
	SetTrieValue(mytrie, "weapon_adrenaline_spawn", IL_Adrenaline);
	SetTrieValue(mytrie, "weapon_adrenaline", IL_Adrenaline);
	SetTrieValue(mytrie, "weapon_pipe_bomb_spawn", IL_PipeBomb);
	SetTrieValue(mytrie, "weapon_pipe_bomb", IL_PipeBomb);
	SetTrieValue(mytrie, "weapon_molotov_spawn", IL_Molotov);
	SetTrieValue(mytrie, "weapon_molotov", IL_Molotov);
	SetTrieValue(mytrie, "weapon_vomitjar_spawn", IL_VomitJar);
	SetTrieValue(mytrie, "weapon_vomitjar", IL_VomitJar);
	return mytrie;
}

static KillRegisteredItems()
{
	decl ItemList:itemindex;
	new psychonic = GetEntityCount();
	for(new i =0; i <= psychonic; i++)
	{
		if(IsValidEntity(i))
		{
			itemindex = GetItemIndexFromEntity(i);
			if(itemindex >= ItemList:0 /* && !IsEntityInSaferoom(i) */ )
			{
				if (IsEntityInSaferoom(i, START_SAFEROOM) && g_iSaferoomCount[START_SAFEROOM - 1] < g_iSurvivorLimit)
				{
					g_iSaferoomCount[START_SAFEROOM - 1]++;
				}
				else if (IsEntityInSaferoom(i, END_SAFEROOM) && g_iSaferoomCount[END_SAFEROOM - 1] < g_iSurvivorLimit)
				{
					g_iSaferoomCount[END_SAFEROOM - 1]++;
				}
				else
				{
					// Kill items we're tracking;
					if(!AcceptEntityInput(i, "kill"))
					{
						LogError("[IT] Error killing instance of item %s", g_sItemNames[itemindex][IN_longname]);
					}
				}
			}
		}
	}
}

static SpawnItems()
{
	decl curitem[ItemTracking];
	decl Float:origins[3], Float:angles[3];
	new arrsize;
	new itement;
	decl String:sModelname[PLATFORM_MAX_PATH];
	new WeaponIDs:wepid;
	for(new itemidx = 0; itemidx < _:ItemList; itemidx++)
	{
		Format(sModelname, sizeof(sModelname), "models/w_models/weapons/w_eq_%s.mdl", g_sItemNames[itemidx][IN_modelname]);
		arrsize = GetArraySize(g_hItemSpawns[itemidx]);
		for(new idx = 0; idx < arrsize; idx++)
		{
			GetArrayArray(g_hItemSpawns[itemidx], idx, curitem[0]);
			GetSpawnOrigins(origins, curitem);
			GetSpawnAngles(angles, curitem);
			wepid = GetWeaponIDFromItemList(ItemList:itemidx);
			if(IsDebugEnabled())
			{
				LogMessage("[IT] Spawning an instance of item %s (%d, wepid %d), number %d, at %.02f %.02f %.02f", 
				g_sItemNames[itemidx][IN_officialname], itemidx, wepid, idx, origins[0], origins[1], origins[2]);
			}
			itement = CreateEntityByName("weapon_spawn");
			SetEntProp(itement, Prop_Send, "m_weaponID", wepid);
			SetEntityModel(itement, sModelname);
			DispatchKeyValue(itement, "count", "1");
			TeleportEntity(itement, origins, angles, NULL_VECTOR);
			DispatchSpawn(itement);
			SetEntityMoveType(itement,MOVETYPE_NONE);
		}
	}
}

static EnumerateSpawns()
{
	new ItemList:itemindex;
	decl curitem[ItemTracking], Float:origins[3], Float:angles[3];
	new psychonic = GetEntityCount();
	for(new i =0; i <= psychonic; i++)
	{
		if(IsValidEntity(i))
		{
			itemindex = GetItemIndexFromEntity(i);
			if(itemindex >= ItemList:0 /* && !IsEntityInSaferoom(i) */ )
			{
				if (IsEntityInSaferoom(i, START_SAFEROOM))
				{
					if(g_iSaferoomCount[START_SAFEROOM - 1] < g_iSurvivorLimit)
						g_iSaferoomCount[START_SAFEROOM - 1]++;
					else if(!AcceptEntityInput(i, "kill"))
						LogError("[IT] Error killing instance of item %s", g_sItemNames[itemindex][IN_longname]);
				}
				else if (IsEntityInSaferoom(i, END_SAFEROOM)) 
				{
					if(g_iSaferoomCount[END_SAFEROOM - 1] < g_iSurvivorLimit)
						g_iSaferoomCount[END_SAFEROOM - 1]++;
					else if(!AcceptEntityInput(i, "kill"))
						LogError("[IT] Error killing instance of item %s", g_sItemNames[itemindex][IN_longname]);
				}
				else
				{
					new mylimit = GetItemLimit(itemindex);
					if(IsDebugEnabled())
					{
						LogMessage("[IT] Found an instance of item %s (%d), with limit %d", g_sItemNames[itemindex][IN_longname], itemindex, mylimit);
					}
					// Item limit is zero, justkill it as we find it
					if(!mylimit)
					{
						if(IsDebugEnabled())
						{
							LogMessage("[IT] Killing spawn");
						}
						if(!AcceptEntityInput(i, "kill"))
						{
							LogError("[IT] Error killing instance of item %s", g_sItemNames[itemindex][IN_longname]);
						}
					}
					else 
					{
						// Store entity, angles, origin
						curitem[IT_entity]=i;
						GetEntPropVector(i, Prop_Send, "m_vecOrigin", origins);
						GetEntPropVector(i, Prop_Send, "m_angRotation", angles);
						if(IsDebugEnabled())
						{
							LogMessage("[IT] Saving spawn #%d at %.02f %.02f %.02f", GetArraySize(g_hItemSpawns[itemindex]), origins[0], origins[1], origins[2]);
						}
						SetSpawnOrigins(origins, curitem);
						SetSpawnAngles(angles, curitem);
						
						// Push this instance onto our array for that item
						PushArrayArray(g_hItemSpawns[itemindex], curitem[0]);
					}
				}
			}
		}
	}
}

static RemoveToLimits()
{
	new curlimit;
	decl curitem[ItemTracking];
	for(new itemidx = 0; itemidx < _:ItemList; itemidx++)
	{
		curlimit = GetItemLimit(ItemList:itemidx);
		if (curlimit >0)
		{
			// Kill off item spawns until we've reduced the item to the limit
			while(GetArraySize(g_hItemSpawns[itemidx]) > curlimit)
			{
				// Pick a random
				new killidx = GetURandomIntRange(0, GetArraySize(g_hItemSpawns[itemidx])-1);
				if(IsDebugEnabled())
				{
					LogMessage("[IT] Killing randomly chosen %s (%d) #%d", g_sItemNames[itemidx][IN_longname], itemidx, killidx);
				}
				GetArrayArray(g_hItemSpawns[itemidx], killidx, curitem[0]);
				if(IsValidEntity(curitem[IT_entity]) && !AcceptEntityInput(curitem[IT_entity], "kill"))
				{
					LogError("[IT] Error killing instance of item %s", g_sItemNames[itemidx][IN_longname]);
				}
				RemoveFromArray(g_hItemSpawns[itemidx],killidx);
			}
		}
		// If limit is 0, they're already dead. If it's negative, we kill nothing.
	}
}

static SetSpawnOrigins(const Float:buf[3], spawn[ItemTracking])
{
	spawn[IT_origins]=buf[0];
	spawn[IT_origins1]=buf[1];
	spawn[IT_origins2]=buf[2];
}

static SetSpawnAngles(const Float:buf[3], spawn[ItemTracking])
{
	spawn[IT_angles]=buf[0];
	spawn[IT_angles1]=buf[1];
	spawn[IT_angles2]=buf[2];
}

static GetSpawnOrigins(Float:buf[3], const spawn[ItemTracking])
{
	buf[0]=spawn[IT_origins];
	buf[1]=spawn[IT_origins1];
	buf[2]=spawn[IT_origins2];
}

static GetSpawnAngles(Float:buf[3], const spawn[ItemTracking])
{
	buf[0]=spawn[IT_angles];
	buf[1]=spawn[IT_angles1];
	buf[2]=spawn[IT_angles2];
}

static GetItemLimit(ItemList:itemidx)
{
	return g_iItemLimits[itemidx];
}


static WeaponIDs:GetWeaponIDFromItemList(ItemList:id)
{
	switch(id)
	{
		case IL_PainPills:
		{
			return WEPID_PAIN_PILLS;
		}
		case IL_Adrenaline:
		{
			return  WEPID_ADRENALINE;
		}		
		case IL_PipeBomb:
		{
			return WEPID_PIPE_BOMB;
		}
		case IL_Molotov:
		{
			return WEPID_MOLOTOV;
		}
		case IL_VomitJar:
		{
			return WEPID_VOMITJAR;
		}
		default:
		{
		
		}
	}
	return WeaponIDs:-1;
}

static ItemList:GetItemIndexFromEntity(entity)
{
	static String:classname[128];
	new ItemList:index;
	GetEdictClassname(entity, classname, sizeof(classname));
	if(GetTrieValue(g_hItemListTrie, classname, index))
	{
		return index;
	}
	
	if(StrEqual(classname, "weapon_spawn") || StrEqual(classname, "weapon_item_spawn"))
	{
		new WeaponIDs:id = WeaponIDs:GetEntProp(entity, Prop_Send, "m_weaponID");
		switch(id)
		{
			case WEPID_VOMITJAR:
			{
				return IL_VomitJar;
			}
			case WEPID_PIPE_BOMB:
			{
				return IL_PipeBomb;
			}
			case WEPID_MOLOTOV:
			{
				return IL_Molotov;
			}
			case WEPID_PAIN_PILLS:
			{
				return IL_PainPills;
			}
			case WEPID_ADRENALINE:
			{
				return IL_Adrenaline;
			}
			default:
			{
			
			}
		}
	}
	
	return ItemList:-1;
}
