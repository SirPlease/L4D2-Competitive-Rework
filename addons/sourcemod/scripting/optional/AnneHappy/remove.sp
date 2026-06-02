#pragma semicolon 1
#pragma newdecls required

// 头文件
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

public Plugin myinfo = 
{
	name 			= "Remove Kits or replace kits and remove defib",
	author 			= "Caibiii, 夜羽真白, 东",
	description 	= "开局删除(非救援)或者替换(救援)已经缓存在地图上的急救包,让药的数量刚好为confogl_pills_limit的值或者l4d2_remove_pillsLimit的值",
	version 		= "2022.12.22",
	url 			= "https://github.com/fantasylidong/CompetitiveWithAnne"
}

ConVar pillsLimit;

public void OnPluginStart()
{
	HookEvent("round_start", evt_RoundStart, EventHookMode_Pre);
	if(FindConVar("confogl_pills_limit"))
	{
		pillsLimit = FindConVar("confogl_pills_limit");
	}		
	else
	{
		CreateConVar("l4d2_remove_pillsLimit", "4", "限制药最多出现数量");
	}
}

public void evt_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(3.0, RoundStartTimer);
}

public Action RoundStartTimer(Handle timer)
{
	RemoveOrReplaceKits();
	return Plugin_Continue;
}

public Action RemoveOrReplaceKits()
{
	int pillsCount = 0;
	ArrayList arrPills = new ArrayList(1);
	ArrayList arrMed = new ArrayList(1);
	ArrayList arrDef = new ArrayList(1);
	for (int entity = 1; entity <= GetEntityCount(); entity++)
	{
		if (IsValidEntity(entity) && IsValidEdict(entity))
		{
			char entityname[128];
			GetEdictClassname(entity, entityname, sizeof(entityname));
			if (strcmp(entityname, "weapon_spawn") == 0)
			{
				if (GetEntProp(entity, Prop_Data, "m_weaponID") == 12)
				{
					arrMed.Push(entity);
				}
				if (GetEntProp(entity, Prop_Data, "m_weaponID") == 15)
				{
					arrPills.Push(entity);
				}		
				if (GetEntProp(entity, Prop_Data, "m_weaponID") == 24)
				{
					arrDef.Push(entity);
				}
			}
			else
			{
				if (strcmp(entityname, "weapon_first_aid_kit_spawn") == 0)
				{
					arrMed.Push(entity);
				}
				if (strcmp(entityname, "weapon_pain_pills_spawn") == 0)
				{
					arrPills.Push(entity);
				}
				if (strcmp(entityname, "weapon_defibrillator_spawn") == 0)
				{
					arrDef.Push(entity);
				}
			}
		}
	}
	if(L4D_IsMissionFinalMap())
	{
		while(arrMed.Length)
		{
			if(pillsCount >= pillsLimit.IntValue)
			{
				RemoveItem(arrMed.Get(0));
			}	
			else
			{
				ReplaceItem(arrMed.Get(0));
				pillsCount ++;
			}
			arrMed.Erase(0);
		}
		while(arrPills.Length)
		{
			if(pillsCount >= pillsLimit.IntValue)
			{
				RemoveItem(arrPills.Get(0));
			}	
			else
			{
				ReplaceItem(arrPills.Get(0));
				pillsCount ++;
			}
			arrPills.Erase(0);
		}
	}
	else
	{
		while(arrPills.Length)
		{
			if(pillsCount > pillsLimit.IntValue)
			{
				RemoveItem(arrPills.Get(0));
			}	
			else
			{
				ReplaceItem(arrPills.Get(0));
				pillsCount ++;
			}
			arrPills.Erase(0);
		}
		while(arrMed.Length)
		{
			if(pillsCount > pillsLimit.IntValue)
			{
				RemoveItem(arrMed.Get(0));
			}	
			else
			{
				ReplaceItem(arrMed.Get(0));
				pillsCount ++;
			}
			arrMed.Erase(0);
		}
	}
	while(arrDef.Length)
	{
		if(pillsCount > pillsLimit.IntValue)
		{
			RemoveItem(arrDef.Get(0));
		}	
		else
		{
			ReplaceItem(arrDef.Get(0));
			pillsCount ++;
		}
		arrDef.Erase(0);
	}
	delete arrDef, arrPills, arrMed;
	return Plugin_Continue;
}

stock int GetPillsCount()
{
	int pillsCount = 0;
	for (int entity = 1; entity <= GetEntityCount(); entity++)
	{
		if (IsValidEntity(entity) && IsValidEdict(entity))
		{
			char entityname[128];
			GetEdictClassname(entity, entityname, sizeof(entityname));
			if (strcmp(entityname, "weapon_spawn") == 0)
			{
				if (GetEntProp(entity, Prop_Data, "m_weaponID") == 15)
				{
					pillsCount++;
				}

			}
			else
			{
				if (strcmp(entityname, "weapon_pain_pills_spawn") == 0)
				{
					pillsCount++;
				}
			}
		}
	}
	return pillsCount;
}

public Action ReplaceKits()
{
	for (int entity = 1; entity <= GetEntityCount(); entity++)
	{
		if (IsValidEntity(entity) && IsValidEdict(entity))
		{
			char entityname[128];
			GetEdictClassname(entity, entityname, sizeof(entityname));
			if (strcmp(entityname, "weapon_spawn") == 0)
			{
				if (GetEntProp(entity, Prop_Data, "m_weaponID") == 12)
				{
					ReplaceItem(entity);
				}
				if (GetEntProp(entity, Prop_Data, "m_weaponID") == 24)
				{
					RemoveItem(entity);
				}
			}
			else
			{
				if (strcmp(entityname, "weapon_first_aid_kit_spawn") == 0)
				{
					ReplaceItem(entity);
				}
				if (strcmp(entityname, "weapon_defibrillator_spawn") == 0)
				{
					RemoveItem(entity);
				}
			}
		}
	}
	return Plugin_Continue;
}

void ReplaceItem(int entity)
{
	float fPos[3], fAngles[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", fPos);
	GetEntPropVector(entity, Prop_Data, "m_angRotation", fAngles);
	// 获取原来位置医疗包的位置与角度，先清除原来位置的医疗包
	RemoveEdict(entity);
	int iPills = CreateEntityByName("weapon_spawn");
	SetEntProp(iPills, Prop_Data, "m_weaponID", 15);
	DispatchKeyValue(iPills, "count", "1");
	TeleportEntity(iPills, fPos, fAngles, NULL_VECTOR);
	DispatchSpawn(iPills);
	SetEntityMoveType(iPills, MOVETYPE_NONE);
}

void RemoveItem(int entity)
{
	RemoveEdict(entity);
}