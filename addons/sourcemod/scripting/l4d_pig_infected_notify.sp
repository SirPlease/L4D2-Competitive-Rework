#include <sourcemod>
#include <sdktools>
#include <colors>
#include "include/sdkhooks.inc"
#undef REQUIRE_PLUGIN

#pragma semicolon 1
#define MAXENTITIES 2048
#define GAMEDATA_FILE "staggersolver"
new Handle:g_hGameConf;
new Handle:g_hIsStaggering;
static bool:surkillboomerboomtank,tankstumblebydoor,tankkillboomerboomhimself,boomerboomtank;
new surclient;
new Tankclient;
#define IsWitch(%0) (g_bIsWitch[%0])
new		bool:	g_bIsWitch[MAXENTITIES];							// Membership testing for fast witch checking

public Plugin:myinfo = 
{
	name = "l4d 豬隊友提示",
	author = "Harry Potter",
	description = "Show who the god teammate boom the Tank, Tank use which weapon(car,pounch,rock) to kill teammates S.I. and Witch , player open door to stun tank",
	version = "2.5",
	url = "myself"
}

public OnPluginStart()
{
	g_hGameConf = LoadGameConfigFile(GAMEDATA_FILE);
	if (g_hGameConf == INVALID_HANDLE)
		SetFailState("[Stagger Solver] Could not load game config file.");

	StartPrepSDKCall(SDKCall_Player);

	if (!PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "IsStaggering"))
		SetFailState("[Stagger Solver] Could not find signature IsStaggering.");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hIsStaggering = EndPrepSDKCall();
	if (g_hIsStaggering == INVALID_HANDLE)
		SetFailState("[Stagger Solver] Failed to load signature IsStaggering");

	CloseHandle(g_hGameConf);
	
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("door_open", Event_DoorOpen);
	HookEvent("door_close", Event_DoorClose);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("witch_killed", Event_WitchKilled);
	HookEvent("witch_spawn", Event_WitchSpawn);
}
public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{	
	surkillboomerboomtank = false;
	tankstumblebydoor = false;
	tankkillboomerboomhimself = false;
	boomerboomtank = false;
}

public Event_DoorOpen(Handle:event, const String:name[], bool:dontBroadcast)
{
	Tankclient = GetTankClient();
	if(Tankclient == -1)	return;
	
	new Surplayer = GetClientOfUserId(GetEventInt(event, "userid"));
	if(Surplayer<=0||!IsClientConnected(Surplayer) || !IsClientInGame(Surplayer)) return;
	//PrintToChatAll("%N open door",Surplayer);
	CreateTimer(0.75, Timer_TankStumbleByDoorCheck, Surplayer);//tank stumble check
}

public Event_DoorClose(Handle:event, const String:name[], bool:dontBroadcast)
{
	Tankclient = GetTankClient();
	if(Tankclient == -1)	return;
	
	new Surplayer = GetClientOfUserId(GetEventInt(event, "userid"));
	if(Surplayer<=0||!IsClientConnected(Surplayer) || !IsClientInGame(Surplayer)) return;
	//PrintToChatAll("%N close door",Surplayer);
	CreateTimer(0.75, Timer_TankStumbleByDoorCheck, Surplayer);//tank stumble check
}

public Action:Timer_TankStumbleByDoorCheck(Handle:timer, any:client)
{
	if(Tankclient<0 || !IsClientConnected(Tankclient) ||!IsClientInGame(Tankclient)) return;
	//PrintToChatAll("判定");
	if (SDKCall(g_hIsStaggering, Tankclient) && !surkillboomerboomtank && !tankstumblebydoor && !tankkillboomerboomhimself && !boomerboomtank)//tank在暈眩 by door
	{
		CPrintToChatAll("{green}[提示] {olive}%N {default}用門 暈眩 {green}Tank{default}.",client);
		tankstumblebydoor = true;
		CreateTimer(3.0,COLD_DOWN,_);
	}
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if( IsWitch(GetEventInt(event, "attackerentid")) && victim != 0 && IsClientConnected(victim) && IsClientInGame(victim) && GetClientTeam(victim) == 3 )
	{
		if(!IsFakeClient(victim))//真人特感 player
			CPrintToChatAll("{green}[提示]{default} {red}妹子 {default}使出 {olive}天馬流星拳 {default}打死 隊友.");
		else
			CPrintToChatAll("{green}[提示]{default} {red}妹子 {default}使出 {olive}天馬流星拳 {default}打死 AI隊友.");
		
		return;
	}
	
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	decl String:weapon[15];
	GetEventString(event, "weapon", weapon, sizeof(weapon));//殺死人的武器名稱
	decl String:victimname[8];
	GetEventString(event, "victimname", victimname, sizeof(victimname));
	//PrintToChatAll("attacker: %d - victim: %d - weapon:%s - victimname:%s",attacker,victim,weapon,victimname);
	if((attacker == 0 || attacker == victim)
	&& victim != 0 && IsClientConnected(victim) && IsClientInGame(victim) && GetClientTeam(victim) == 3)//特感自殺
	{
		decl String:kill_weapon[20];
		if(StrEqual(weapon,"entityflame")||StrEqual(weapon,"env_fire"))//地圖的自然火
			kill_weapon = "玩火自焚";
		else if(StrEqual(weapon,"inferno"))//玩家丟的火
			return;
		else if(StrEqual(weapon,"trigger_hurt"))//跳樓 跳海 碰到不知明物體死掉
			kill_weapon = "自殺";
		else if(StrEqual(weapon,"prop_physics")||StrEqual(weapon, "prop_car_alarm"))//玩車殺死自己
			kill_weapon = "玩車自爆";
		else if(StrEqual(weapon,"pipe_bomb")||StrEqual(weapon,"prop_fuel_barr"))//自然的爆炸(土製炸彈 砲彈 瓦斯罐)
			kill_weapon = "被炸死";
		else if(StrEqual(weapon,"world"))//玩家使用指令kill 殺死特感
			return;
		else kill_weapon = "自我爆☆殺";//卡住了 由伺服器自動處死特感
			
		if(GetEntProp(victim, Prop_Send, "m_zombieClass") == 8)//Tank suicide
		{
			if(!IsFakeClient(victim))//真人SI player
				CPrintToChatAll("{green}[提示] {green}Tank {olive}%s {default}了.",kill_weapon);
			else
				CPrintToChatAll("{green}[提示] {green}Tank {olive}%s {default}了.",kill_weapon);
		}
		else if(GetEntProp(victim, Prop_Send, "m_zombieClass") == 2)
			CreateTimer(0.2, Timer_BoomerSuicideCheck, victim);//boomer suicide check	
		else
			if(!IsFakeClient(victim))//真人SI player
				CPrintToChatAll("{green}[提示] {red}%N{default} {olive}%s {default}了.",victim,kill_weapon);
			else
				CPrintToChatAll("{green}[提示] {red}%N{default} {olive}%s {default}了.",victim,kill_weapon);
	
		return;
	}
	else if (attacker==0 && victim == 0 && StrEqual(victimname,"Witch"))
	{
		CPrintToChatAll("{green}[提示] {red}妹子{default} {olive}歸天 {default}了.");
	}
	
	Tankclient = GetTankClient();
	if(Tankclient == -1)	return;
	
	if( StrEqual(victimname,"Witch") && PlayerIsTank(attacker) )
	{
		decl String:Tank_weapon[15];
		if(StrEqual(weapon,"tank_claw"))
			Tank_weapon = "One-Punch";
		else if(StrEqual(weapon,"tank_rock"))
			Tank_weapon = "玉石俱焚";
		else if(StrEqual(weapon,"prop_physics"))
			Tank_weapon = "Car-Flying";
		
		if(!IsFakeClient(attacker))//真人Tank player
			CPrintToChatAll("{green}[提示] Tank {default}使出 {olive}%s {default}星爆氣流斬 {red}妹子{default}.",Tank_weapon);
		else
			CPrintToChatAll("{green}[提示] Tank {default}使出 {olive}%s {default}星爆氣流斬 {red}妹子{default}.",Tank_weapon);
		
		return;
	}
	
	if ( victim == 0 || !IsClientConnected(victim)||!IsClientInGame(victim)) return;
	new victimteam = GetClientTeam(victim);
	new victimzombieclass = GetEntProp(victim, Prop_Send, "m_zombieClass");
		
	if (victimteam == 3)//infected dead
	{	
		if(attacker != 0 && IsClientConnected(attacker) && IsClientInGame(attacker))//someone kill infected
		{
			new attackerteam = GetClientTeam(attacker);
			if(attackerteam == 2 && victimzombieclass == 2)//sur kill Boomer
			{
				surclient = attacker;
				CreateTimer(0.2, Timer_SurKillBoomerCheck, victim);//sur kill Boomer check	
			}
			else if (PlayerIsTank(attacker))//Tank kill infected
			{
				decl String:Tank_weapon[22];
				//Tank weapon
				if(StrEqual(weapon,"tank_claw"))
					Tank_weapon = "拍";
				else if(StrEqual(weapon,"tank_rock"))
					Tank_weapon = "砸";
				else if(StrEqual(weapon,"prop_physics"))
					Tank_weapon = "玩車殺";
				else if(StrEqual(weapon, "prop_car_alarm"))
					Tank_weapon = "玩警報車殺";
					
				//Tank kill boomer
				if(victimzombieclass == 2)
				{
					new Handle:h_Pack;
					CreateDataTimer(0.2,Timer_TankKillBoomerCheck,h_Pack);//tank kill Boomer check
					WritePackCell(h_Pack, victim);
					WritePackString(h_Pack, Tank_weapon);
				}
				else if(victimzombieclass == 1||victimzombieclass == 3 ||victimzombieclass == 4 ||victimzombieclass == 5||victimzombieclass == 6)//Tank kill teammates S.I. (Hunter,Smoker,Jockey,Spitter,Charger)	
				{
					if(!IsFakeClient(victim))//真人SI player
						CPrintToChatAll("{green}[提示] {green}Tank {olive}%s死 {default}隊友.",Tank_weapon);
					else
						CPrintToChatAll("{green}[提示] {green}Tank {olive}%s死 {default}AI隊友.",Tank_weapon);
				}
			}
		}
	}
}
public Action:Timer_SurKillBoomerCheck(Handle:timer, any:client)
{
	if(Tankclient<0 || !IsClientConnected(Tankclient) ||!IsClientInGame(Tankclient)) return;
	if(client<0 || !IsClientConnected(client) ||!IsClientInGame(client)) return;
	if(SDKCall(g_hIsStaggering, Tankclient) && !surkillboomerboomtank && !tankstumblebydoor && !tankkillboomerboomhimself && !boomerboomtank)//tank在暈眩
	{
		if(!IsFakeClient(client))//真人boomer player
			CPrintToChatAll("{green}[提示] {olive}%N {default}殺死 {red}%N{default}'s 肥宅 炸暈 {green}Tank{default}.",surclient, client);
		else
			CPrintToChatAll("{green}[提示] {olive}%N {default}殺死 {red}AI {default}肥宅 炸暈 {green}Tank{default}.",surclient);
		surkillboomerboomtank=true;
		CreateTimer(3.0,COLD_DOWN,_);
	}
}

public Action:Timer_TankKillBoomerCheck(Handle:timer, Handle:h_Pack)
{
	if(Tankclient<0 || !IsClientConnected(Tankclient) ||!IsClientInGame(Tankclient)) return;
	decl String:Tank_weapon[128];
	new client;
	
	ResetPack(h_Pack);
	client = ReadPackCell(h_Pack);
	if(client<0 || !IsClientConnected(client) ||!IsClientInGame(client)) return;
	ReadPackString(h_Pack, Tank_weapon, sizeof(Tank_weapon));
	
	if(SDKCall(g_hIsStaggering, Tankclient) && !surkillboomerboomtank && !tankstumblebydoor && !tankkillboomerboomhimself && !boomerboomtank)//tank在暈眩
	{
		if(!IsFakeClient(client))//真人SI player
			CPrintToChatAll("{green}[提示] {green}Tank {olive}%s死 {red}%N{default}'s 肥宅 炸暈 {default}自己.",Tank_weapon,client);
		else	
			CPrintToChatAll("{green}[提示] {green}Tank {olive}%s死 {red}AI {default}肥宅 炸暈 {default}自己.",Tank_weapon);
		tankkillboomerboomhimself = true;
		CreateTimer(3.0,COLD_DOWN,_);
	}
	else
	{
		if(!IsFakeClient(client))//真人SI player
			CPrintToChatAll("{green}[提示] {green}Tank {olive}%s死 {default}肥宅.",Tank_weapon);
		else
			CPrintToChatAll("{green}[提示] {green}Tank {olive}%s死 {default}AI肥宅.",Tank_weapon);
	}
}


public Action:Timer_BoomerSuicideCheck(Handle:timer, any:client)
{	
	if(client<0 || !IsClientConnected(client) ||!IsClientInGame(client)) return;
	
	Tankclient = GetTankClient();
	if(Tankclient<0 || !IsClientConnected(Tankclient) ||!IsClientInGame(Tankclient))
	{
		if(!IsFakeClient(client))//真人boomer player
			CPrintToChatAll("{green}[提示] {red}%N{default}'s 肥宅 爆炸了.",client);
		else
			CPrintToChatAll("{green}[提示] {red}AI {default}肥宅 爆炸了.");
		return;
	}
	
	if (SDKCall(g_hIsStaggering, Tankclient) && !surkillboomerboomtank && !tankstumblebydoor && !tankkillboomerboomhimself && !boomerboomtank)//tank在暈眩
	{
		if(!IsFakeClient(client))//真人boomer player
			CPrintToChatAll("{green}[提示] {default}神隊友 {red}%N{default}'s 肥宅 炸暈 {green}Tank{default}.",client);
		else
			CPrintToChatAll("{green}[提示] {default}神{red}AI {default}肥宅 炸暈 {green}Tank{default}.");
		boomerboomtank = true;
		CreateTimer(3.0,COLD_DOWN,_);
	}
	else
	{
		if(!IsFakeClient(client))//真人boomer player
			CPrintToChatAll("{green}[提示] {red}%N{default}'s 肥宅 爆炸了.",client);
		else
			CPrintToChatAll("{green}[提示] {red}AI {default}肥宅 爆炸了.");
	}
}

static GetTankClient()
{
	for (new client = 1; client <= MaxClients; client++)
		if(	PlayerIsTank(client) )//Tank player
			return  client;
	return -1;
}

stock bool:PlayerIsTank(client)
{
	if(client != 0 && IsClientConnected(client) && IsClientInGame(client) && IsInfectedAlive(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 8) 
		return true;
	return false;
}

public Action:COLD_DOWN(Handle:timer,any:client)
{
	surkillboomerboomtank = false;
	tankstumblebydoor = false;
	tankkillboomerboomhimself = false;
	boomerboomtank = false;
}

public Event_WitchKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bIsWitch[GetEventInt(event, "witchid")] = false;
	
}

public Event_WitchSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bIsWitch[GetEventInt(event, "witchid")] = true;
}
public OnMapStart()
{
	for (new i = MaxClients + 1; i < MAXENTITIES; i++) g_bIsWitch[i] = false;
}
stock bool:IsInfectedAlive(client)
{
	return GetEntProp(client, Prop_Send, "m_iHealth") > 1;
}