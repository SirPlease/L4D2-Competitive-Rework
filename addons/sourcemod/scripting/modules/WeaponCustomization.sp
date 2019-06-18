#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

new Handle:WC_hLimitCount;

new WC_iLimitCount = 1;
new WC_iLastWeapon = -1;
new WC_iLastClient = -1;
new String:WC_sLastWeapon[64];

public WC_OnModuleStart()
{
	WC_hLimitCount = CreateConVarEx("limit_sniper", "1", "Limits the maximum number of sniping rifles at one time to this number", 0, true, 0.0, true, 4.0);
	HookConVarChange(WC_hLimitCount, WC_ConVarChange);
	
	WC_iLimitCount = GetConVarInt(WC_hLimitCount);
	
	HookEvent("player_use", WC_PlayerUse_Event);
	HookEvent("weapon_drop", WC_WeaponDrop_Event);
}

public WC_ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	WC_iLimitCount = GetConVarInt(WC_hLimitCount);
}

public Action:WC_WeaponDrop_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!IsPluginEnabled()) return;
	WC_iLastWeapon = GetEventInt(event, "propid");
	WC_iLastClient = GetClientOfUserId(GetEventInt(event, "userid"));
	GetEventString(event, "item", WC_sLastWeapon, sizeof(WC_sLastWeapon));
	
}

public Action:WC_PlayerUse_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!IsPluginEnabled()) return;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	new primary = GetPlayerWeaponSlot(client, 0);
	if (!IsValidEdict(primary)) return;
	
	decl String:primary_name[64];
	GetEdictClassname(primary, primary_name, sizeof(primary_name));
	
	if (StrEqual(primary_name, "weapon_hunting_rifle") || StrEqual(primary_name, "weapon_sniper_military") || StrEqual(primary_name, "weapon_sniper_awp") || StrEqual(primary_name, "weapon_sniper_scout") || StrEqual(primary_name, "weapon_rifle_sg552"))
	{
		if (SniperCount(client) >= WC_iLimitCount)
		{
			if (IsValidEdict(primary))
			{
				RemovePlayerItem(client, primary);
				CPrintToChatAll("{blue}[{default}Confogl{blue}] {default}Maximum {blue}%d {olive}sniping rifle(s) {default}is enforced.", WC_iLimitCount);
			}
			
			if (WC_iLastClient == client)
			{
				if (IsValidEdict(WC_iLastWeapon))
				{
					AcceptEntityInput(WC_iLastWeapon, "Kill");
					new flags = GetCommandFlags("give");
					SetCommandFlags("give", flags ^ FCVAR_CHEAT);
					
					decl String:sTemp[64];
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

SniperCount(client)
{
	new count = 0;
	for (new i = 0; i < 4; i++)
	{
		new index = GetSurvivorIndex(i);
		if (index != client && index != 0 && IsClientConnected(index))
		{
			new ent = GetPlayerWeaponSlot(index, 0);
			if (IsValidEdict(ent))
			{
				decl String:temp[64];
				GetEdictClassname(ent, temp, sizeof(temp));
				if (StrEqual(temp, "weapon_hunting_rifle") || StrEqual(temp, "weapon_sniper_military") || StrEqual(temp, "weapon_sniper_awp") || StrEqual(temp, "weapon_sniper_scout") || StrEqual(temp, "weapon_rifle_sg552")) count++;
			}
		}
	}
	return count;
}