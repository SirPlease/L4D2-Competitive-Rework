#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <readyup>
#include <left4dhooks>
#include <l4d2util_infected>

int g_iVelocity;
int GameMode;
int L4D2Version;

#define PARTICLE_MUZZLE_FLASH		"weapon_muzzle_flash_autoshotgun"
#define PARTICLE_WEAPON_TRACER		"weapon_tracers_50cal"
#define PARTICLE_BOMBEXPLODE		"weapon_grenadelauncher"
#define PARTICLE_BLOOD				"blood_gore_arterial_drip"

#define SOUND_ENGINE				"vehicles/airboat/fan_blade_fullthrottle_loop1.wav"
#define SOUND_SHOT					"weapons/50cal/50cal_shoot.wav"
#define SOUND_BOMBEXPLODE			"weapons/grenade_launcher/grenadefire/grenade_launcher_explode_1.wav"
#define SOUND_BOMBDROP				"weapons/grenade_launcher/grenadefire/grenade_launcher_fire_1.wav"
#define SOUND_FLAME					"ambient/gas/steam2.wav"
#define MODEL_W_VOMITJAR			"models/w_models/weapons/w_eq_bile_flask.mdl"
#define MODEL_HELICOPTER			"models/props_vehicles/helicopter_rescue.mdl"
#define MODEL_MISSILE				"models/missiles/f18_agm65maverick.mdl"

ConVar l4d2_helicopter_size;
ConVar l4d2_helicopter_gun_accuracy;
ConVar l4d2_helicopter_gun_damage;
ConVar l4d2_helicopter_password;
ConVar l4d2_helicopter_chance_tankdrop;
ConVar l4d2_helicopter_speed;
ConVar l4d2_helicopter_fuel;
ConVar l4d2_helicopter_bullet;
ConVar l4d2_helicopter_bomb;
ConVar l4d2_helicopter_range;

int LastButton[MAXPLAYERS+1];
int LastFlag[MAXPLAYERS+1];
float LastTime[MAXPLAYERS+1];

int g_PointHurt=0;
int g_offsNextPrimaryAttack=0;
int g_iActiveWO=0;

public Plugin myinfo =
{
	name = "L4D(2) Helicopter Gunship",
	author = "Pan Xiaohai - Modded by SilverShot",
	description = "Turn in to a helicopter! Then bomb, gun down, and fly thru the apocalypse!",
	version = "1.9h",
	url = "https://forums.alliedmods.net/showthread.php?t=170809&page=5"
}

public void OnPluginStart()
{
	GameCheck();
	if(!L4D2Version)return;
	if(GameMode==2)return;
	
	l4d2_helicopter_size = CreateConVar("l4d2_helicopter_size", "1.0", "Helicopter size [0.5, 2.0]");
	l4d2_helicopter_speed = CreateConVar("l4d2_helicopter_speed", "325.0", "Flight speed [100.0, 500.0]");
	l4d2_helicopter_gun_accuracy = CreateConVar("l4d2_helicopter_gun_accuracy", "0.5", "Machine gun accuracy [0.0, 1.0]");
	l4d2_helicopter_gun_damage = CreateConVar("l4d2_helicopter_gun_damage", "0.5", "Machine gun bullet damage [1.0, 200.0]");
	l4d2_helicopter_password = CreateConVar("l4d2_helicopter_password", "", "Type !h 'password' in chat");
	l4d2_helicopter_chance_tankdrop = CreateConVar("l4d2_helicopter_chance_tankdrop", "0.0", "Chance of a helicopter spawn when tank dies [0.0, 100.0]");
	l4d2_helicopter_fuel= CreateConVar("l4d2_helicopter_fuel", "2000.0", "Fuel amount in seconds [1.0, 2000.0]");
	l4d2_helicopter_bullet = CreateConVar("l4d2_helicopter_bullet", "9999", "Machine gun ammo amount [100.0, 1600.0]");
	l4d2_helicopter_bomb = CreateConVar("l4d2_helicopter_bomb", "400", "Bomb ammo amount [100.0, 400.0]");
	l4d2_helicopter_range = CreateConVar("l4d2_helicopter_range", "9000.0", "Max distance you can fly from your team [100.0, 1600.0]");

	AutoExecConfig(true, "l4d2_helicopter");
	
	HookEvent("tank_killed", tank_killed);
	HookEvent("player_spawn", player_spawn);
	HookEvent("player_death", player_death);
	HookEvent("player_bot_replace", player_bot_replace);	  
	HookEvent("bot_player_replace", bot_player_replace); 	
	HookEvent("player_team", player_changed_team); 
	HookEvent("round_start", round_start);
	HookEvent("round_end", round_end);
	HookEvent("map_transition", map_transition, EventHookMode_Pre);

	RegConsoleCmd("sm_h", sm_h);

	ResetAllState();

	g_iVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
	g_offsNextPrimaryAttack = FindSendPropInfo("CBaseCombatWeapon", "m_flNextPrimaryAttack");
	g_iActiveWO = FindSendPropInfo("CBaseCombatCharacter","m_hActiveWeapon");

	g_PointHurt=0;
}

public void OnRoundLiveCountdownPre(){
	RemoveHelicopterAll();
	ResetAllState();
}

public void OnRoundIsLivePre(){
	OnRoundLiveCountdownPre();
}
int DummyEnt[MAXPLAYERS+1];
int HelicopterEnt[MAXPLAYERS+1];
int HelicopterEnt_other[MAXPLAYERS+1];
int Bullet[MAXPLAYERS+1];
int Bomb[MAXPLAYERS+1];
int Info[MAXPLAYERS+1][4];

float Pitch[MAXPLAYERS+1];
float Roll[MAXPLAYERS+1];
float Gravity[MAXPLAYERS+1];
float Fuel[MAXPLAYERS+1];
float LastPos[MAXPLAYERS+1][3];
float MaxSpeed[MAXPLAYERS+1];
float BombTime[MAXPLAYERS+1];
float ShotTime[MAXPLAYERS+1];
float RangeCheckTime[MAXPLAYERS+1];
float AloneStartTime[MAXPLAYERS+1];

public Action sm_h(int client, int args)
{
	if (!IsInReady()){
		AdminId id = GetUserAdmin(client)
		if (!GetAdminFlag(id, Admin_Generic)) {
			PrintToChat(client, "游戏已经开始了!");
			return Plugin_Handled;
		}
	}else{
		PrintToChat(client, "Ctrl+E 离开直升机 | E 显示HUD");
	}
 	if(client>0 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		if (IsInfectedGhost(client) && !IsInReady()) {
			PrintToChat(client, "你不能在灵魂状态使用直升机");
			return Plugin_Handled;
		}

		if(DummyEnt[client] && EntRefToEntIndex(DummyEnt[client]) != INVALID_ENT_REFERENCE)
		{
			RemoveHelicopter(client);
		}
		
		else
		{
			char password[20]="";
			char arg[20];
			l4d2_helicopter_password.GetString(password, sizeof(password));
			GetCmdArg(1, arg, sizeof(arg));
			if(StrEqual(arg, password))CreateHelicopter(client, -1);
			else PrintHintText(client, "Password Is Incorrect");
		}
	}
	return Plugin_Handled;
}

void CreateHelicopter(int client, int infoIndex)
{
	if(DummyEnt[client] && EntRefToEntIndex(DummyEnt[client]) != INVALID_ENT_REFERENCE)
	{
		RemoveHelicopter(client);
	}
	
	float modelScale=l4d2_helicopter_size.FloatValue;
	if(modelScale<1.0)modelScale=1.0;
	else if(modelScale>2.0)modelScale=2.0;
	modelScale = GetRandomFloat(1.0, 2.0);
	
	if(IsValidClient(client))
	{
		float ang[3];
		float pos[3];

		GetClientAbsAngles(client, ang);
		GetClientAbsOrigin(client, pos);
		ang[0]=0.0;

		int dummy=CreateEntityByName("vomitjar_projectile");
		DispatchKeyValue(dummy, "model", MODEL_W_VOMITJAR);
		SetEntProp(dummy, Prop_Data, "m_CollisionGroup", 2);

		char tname[20];
		Format(tname, 20, "target%d", client);
		DispatchKeyValue(client, "targetname", tname);

		SetVariantString(tname);
		AcceptEntityInput(dummy, "SetParent",dummy, dummy, 0);

		SetVector(pos, 0.0, 0.0, 0.0);
		SetVector(ang, 0.0, 0.0, 0.0);
		TeleportEntity(dummy, pos, ang, NULL_VECTOR);

		DispatchSpawn(dummy);
		VisiblePlayer(dummy, false);

		SetEntPropVector(dummy, Prop_Send, "m_angRotation", ang);

		int ment=CreateEntityByName("prop_dynamic");
		DispatchKeyValue(ment, "model", MODEL_HELICOPTER);
		SetEntProp(ment, Prop_Data, "m_CollisionGroup", 2);
		SetEntPropFloat(ment, Prop_Send,"m_flModelScale",modelScale*0.12);

		DispatchSpawn(ment);

		Format(tname, 20, "target%d", dummy);
		DispatchKeyValue(dummy, "targetname", tname);
		SetVariantString(tname);
		AcceptEntityInput(ment, "SetParent",ment, ment, 0);
		SetVector(pos, -0.0, 0.0, 0.0);
		SetVector(ang, 0.0, 0.0, 0.0);
		TeleportEntity(ment, pos, NULL_VECTOR,NULL_VECTOR);

		SetEntPropVector(ment, Prop_Send, "m_angRotation", ang);

		DispatchKeyValueFloat(ment, "fademindist", 10000.0);
		DispatchKeyValueFloat(ment, "fademaxdist", 20000.0);
		DispatchKeyValueFloat(ment, "fadescale", 0.0);

		SetVariantString("3ready");
		AcceptEntityInput(ment, "SetAnimation");
		SetEntPropFloat(ment, Prop_Send, "m_flPlaybackRate", 0.3);

		SetEntityMoveType(dummy, MOVETYPE_NONE);
		SetEntityMoveType(ment, MOVETYPE_NONE);

		VisiblePlayer(client,false);
		GotoThirdPerson(client);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
		DummyEnt[client]=EntIndexToEntRef(dummy);
		HelicopterEnt[client]=EntIndexToEntRef(ment);
		HelicopterEnt_other[client]=CreateModel(client);
		MaxSpeed[client]=l4d2_helicopter_speed.FloatValue;
		Pitch[client]=0.0;
		Roll[client]=0.0;
		EmitSoundToAll(SOUND_ENGINE, dummy, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.6, SNDPITCH_NORMAL, -1, pos, NULL_VECTOR, true, 0.0);

		RangeCheckTime[client]=0.0;
		AloneStartTime[client]=GetEngineTime();

		LastTime[client]=GetEngineTime();
		LastButton[client]=0;
		LastFlag[client]=0;
		GetClientAbsOrigin(client, LastPos[client]);

		if(infoIndex<0)
		{
			Fuel[client]=l4d2_helicopter_fuel.FloatValue;
			Bullet[client]=l4d2_helicopter_bullet.IntValue;
			Bomb[client]=l4d2_helicopter_bomb.IntValue;
		}
		
		else
		{
			Bullet[client]=Info[infoIndex][1];
			Bomb[client]=Info[infoIndex][2];
			Fuel[client]=Info[infoIndex][3]*1.0;
		}
		
		ShotTime[client]=0.0;
		BombTime[client]=0.0;

		SDKUnhook(client, SDKHook_PreThink, PreThink);
		SDKHook(client, SDKHook_PreThink, PreThink);
		
		SDKUnhook(client, SDKHook_PostThinkPost, PostThinkPost);
		SDKHook(client, SDKHook_PostThinkPost, PostThinkPost);
		
		SDKUnhook(client, SDKHook_SetTransmit, OnSetTransmitClient);
		
		SDKUnhook(HelicopterEnt[client], SDKHook_SetTransmit, OnSetTransmitModel);		
		SDKHook(HelicopterEnt[client], SDKHook_SetTransmit, OnSetTransmitModel);
		
		SDKUnhook(HelicopterEnt_other[client], SDKHook_SetTransmit, OnSetTransmitModel_Other);
		SDKHook(HelicopterEnt_other[client], SDKHook_SetTransmit, OnSetTransmitModel_Other);
	}
}

int CreateModel(int client)
{
	float modelScale=l4d2_helicopter_size.FloatValue;

	if(modelScale<1.0)modelScale=0.75;
	if(modelScale>=1.0)modelScale=1.0;
	else if(modelScale>=2.0)modelScale=2.0;
	modelScale*=1.3;

	float ang[3];
	float pos[3];

	int ment=CreateEntityByName("prop_dynamic");
	DispatchKeyValue(ment, "model", MODEL_HELICOPTER);
	SetEntProp(ment, Prop_Data, "m_CollisionGroup", 2);
	SetEntPropFloat(ment, Prop_Send,"m_flModelScale",modelScale*0.12);

	DispatchSpawn(ment);
	char tname[20];
	Format(tname, 20, "target%d", client);
	DispatchKeyValue(client, "targetname", tname);
	SetVariantString(tname);
	AcceptEntityInput(ment, "SetParent",ment, ment, 0);

	SetVector(pos, -0.0, 0.0, 0.0);
	SetVector(ang, 0.0, 0.0, 0.0);
	TeleportEntity(ment, pos, NULL_VECTOR,NULL_VECTOR);

	SetEntPropVector(ment, Prop_Send, "m_angRotation", ang);

	DispatchKeyValueFloat(ment, "fademindist", 10000.0);
	DispatchKeyValueFloat(ment, "fademaxdist", 20000.0);
	DispatchKeyValueFloat(ment, "fadescale", 0.0);

	SetVariantString("3ready");
	AcceptEntityInput(ment, "SetAnimation");
	SetEntPropFloat(ment, Prop_Send, "m_flPlaybackRate", 0.3);
	SetEntityMoveType(ment, MOVETYPE_NOCLIP);

	return EntIndexToEntRef(ment);
}

void RemoveHelicopter(int client)
{
	if(client>0 && DummyEnt[client] && EntRefToEntIndex(DummyEnt[client]) != INVALID_ENT_REFERENCE)
	{
		if(IsClientInGame(client))
		{
			SDKUnhook(client, SDKHook_SetTransmit, OnSetTransmitClient);
			SDKUnhook(client, SDKHook_PostThinkPost, PostThinkPost);
			SDKUnhook(client, SDKHook_PreThink, PreThink);
			GotoFirstPerson(client);
			VisiblePlayer(client, true);
			SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
			SetEntityMoveType(client, MOVETYPE_WALK);
			SetEntityGravity(client, 1.0);
			SetEntProp(client, Prop_Send, "m_iHideHUD", 2048);
			
			SetEntProp(client, Prop_Send, "m_iGlowType", 0);
			SetEntProp(client, Prop_Send, "m_nGlowRange", 0);
			SetEntProp(client, Prop_Send, "m_glowColorOverride",0);
		}
		
		StopSound(DummyEnt[client], SNDCHAN_AUTO,SOUND_ENGINE);

		AcceptEntityInput(DummyEnt[client], "ClearParent");
		DispatchKeyValue(DummyEnt[client], "classname", "weapon_pistol");
		AcceptEntityInput(DummyEnt[client], "kill");
 	}

	if(IsValidEnt(HelicopterEnt[client]))
	{
		StopSound(HelicopterEnt[client], SNDCHAN_AUTO,SOUND_ENGINE);
		SDKUnhook(HelicopterEnt[client], SDKHook_SetTransmit, OnSetTransmitModel);
		AcceptEntityInput(HelicopterEnt[client], "kill");
	}
	
	if(IsValidEnt(HelicopterEnt_other[client]))
	{
		SDKUnhook(HelicopterEnt_other[client], SDKHook_SetTransmit, OnSetTransmitModel_Other);
		AcceptEntityInput(HelicopterEnt_other[client], "kill");
	}

	DummyEnt[client]=0;
	HelicopterEnt[client]=0;
	HelicopterEnt_other[client]=0;
}

void DropHelicopter(int client)
{
	float ang[3];
	float pos[3];

	GetClientAbsAngles(client, ang);
	GetClientAbsOrigin(client, pos);
	pos[2]+=20.0;
	ang[0]=0.0;
	int dummy=CreateEntityByName("vomitjar_projectile");
	DispatchKeyValue(dummy, "model", MODEL_W_VOMITJAR);
	SetEntProp(dummy, Prop_Data, "m_CollisionGroup", 2);
	SetEntityMoveType(dummy, MOVETYPE_FLYGRAVITY);
	SetEntityGravity(dummy, 0.1);
	DispatchSpawn(dummy);
	TeleportEntity(dummy, pos, ang, NULL_VECTOR);
	VisiblePlayer(dummy, false);

	int ment=CreateModel(client);
	DispatchSpawn(ment);
	char tname[20];
	Format(tname, 20, "target%d", dummy);
	DispatchKeyValue(dummy, "targetname", tname);
	SetVariantString(tname);
	AcceptEntityInput(ment, "SetParent",ment, ment, 0);

	SetVector(pos, -0.0, 0.0, 0.0);
	SetVector(ang, 0.0, 0.0, 0.0);
	TeleportEntity(ment, pos, ang,NULL_VECTOR);
	SetEntityMoveType(ment, MOVETYPE_NOCLIP);

	SetVariantString("3ready");
	AcceptEntityInput(ment, "SetAnimation");
	SetEntPropFloat(ment, Prop_Send, "m_flPlaybackRate", 0.3);

	int button=CreateButton(dummy);
	SetEntPropFloat(button, Prop_Send, "m_fadeMaxDist", dummy*1.0);

	EmitSoundToAll(SOUND_ENGINE, dummy, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.6, SNDPITCH_NORMAL, -1, pos, NULL_VECTOR, true, 0.0);

	int index=-1;
 	for(int i=0; i<=MaxClients; i++)
	{
		if(Info[i][0]==0 || EntRefToEntIndex(Info[i][0]) == INVALID_ENT_REFERENCE)
		{
			index=i;
			break;
		}
	}

	if(index>=0)
	{
		Info[index][0]=EntIndexToEntRef(dummy);
		Info[index][1]=Bullet[client];
		Info[index][2]=Bomb[client];
		Info[index][3]=RoundFloat(Fuel[client]);
	}
}

void LostControl(int client)
{
	if(client>0 && DummyEnt[client] && EntRefToEntIndex(DummyEnt[client]) != INVALID_ENT_REFERENCE)
	{
		RemoveHelicopter(client);
		//DropHelicopter(client);
	}
	SDKUnhook(client, SDKHook_PreThink, PreThink);
	SDKUnhook(client, SDKHook_PostThinkPost, PostThinkPost);
	SDKUnhook(client, SDKHook_SetTransmit, OnSetTransmitClient);
}

stock bool IsClientAndInGame(int index)
{
	return (index > 0 && index <= MaxClients && IsClientInGame(index));
}


public void PreThink(int client)
{	
	if(!IsClientAndInGame(client)) {
		LostControl(client); 
		return;
	}
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		float time=GetEngineTime();
		float intervual=time-LastTime[client];
		if(intervual<0.01)intervual=0.01;
		else if(intervual>0.1)intervual=0.1;
		int button=GetClientButtons(client);
		int flag=GetEntityFlags(client);
		Fly(client,button, flag, intervual, time);
		LastTime[client]=time;
		LastButton[client]=button;
		LastFlag[client]=flag;
	}

	else
	{
		LostControl(client);
	}
}

public void PostThinkPost(int client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client) && DummyEnt[client] && EntRefToEntIndex(DummyEnt[client]) != INVALID_ENT_REFERENCE)
	{
		int button=GetClientButtons(client);
		if((button & IN_USE))SetEntProp(client, Prop_Send, "m_iHideHUD",2048);
		else SetEntProp(client, Prop_Send, "m_iHideHUD", 64);

		SetEntProp(client, Prop_Send, "m_iAddonBits", 0);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
		SetEntityMoveType(client, MOVETYPE_FLYGRAVITY);
		int weapon= GetEntDataEnt2(client, g_iActiveWO);
		if(weapon>0)
		{
			float flNextPrimaryAttack = GetEntDataFloat(weapon, g_offsNextPrimaryAttack);
			SetEntDataFloat(weapon, g_offsNextPrimaryAttack, flNextPrimaryAttack+1.0,true);
		}
		SetEntProp(client, Prop_Send, "m_iGlowType", 3);
		SetEntProp(client, Prop_Send, "m_nGlowRange", 0);
		SetEntProp(client, Prop_Send, "m_glowColorOverride", 1);
	}
}

public Action OnSetTransmitClient (int polit, int client)
{
	if(polit!=client)
		return Plugin_Handled;
	return Plugin_Continue;
}

public Action OnSetTransmitModel (int model, int client)
{	
	if(HelicopterEnt[client] && EntRefToEntIndex(HelicopterEnt[client]) == model)
		return Plugin_Continue;
	return Plugin_Handled;
}

public Action OnSetTransmitModel_Other (int model, int client)
{	
	if(HelicopterEnt_other[client] && EntRefToEntIndex(HelicopterEnt_other[client]) == model) 
		return Plugin_Handled;
	return Plugin_Continue;
}

void Fly(int client, int button, int flag, float intervual, float time)
{
	int dummy=DummyEnt[client];
	int modelEnt=HelicopterEnt[client];
	if(!IsValidEnt(modelEnt)) return;

	float clientAngle[3];
	float modelAng[3];
 	GetEntPropVector(modelEnt, Prop_Send, "m_angRotation", modelAng);
 	GetClientEyeAngles(client, clientAngle);

	modelAng[0]=0.0-clientAngle[0];
	modelAng[1]=0.0;

	float clientPos[3];
	float temp[3];
	float volicity[3];
	float pushForce[3];
	float pushForceVertical[3];
	float liftForce=50.0;
	float speedLimit=MaxSpeed[client];
	float fuelUsed=intervual;
	float gravity=0.001;
	float gravityNormal=0.001;
	GetEntDataVector(client, g_iVelocity, volicity);

	GetClientAbsOrigin(client, clientPos);
	CopyVector(clientPos,LastPos[client]);
	clientAngle[0]=0.0;

	SetVector(pushForce, 0.0, 0.0, 0.0);
	SetVector(pushForceVertical, 0.0, 0.0, 0.0);
	bool up=false;
	bool down=false;
	bool speed=false;
	bool move=false;
	float pitch=0.0;
	float roll=0.0;

	if((button & IN_JUMP))
	{
		SetVector(pushForceVertical, 0.0, 0.0, 1.5);
		up=true;

		if(gravity>0.0)gravity=-0.01;
		gravity=Gravity[client]-1.0*intervual;
	}

	if((button & IN_DUCK) && !up)
	{
		SetVector(pushForceVertical, 0.0, 0.0, -2.0);
		down=true;
		if(gravity<0.0)gravity=0.01;
		gravity=Gravity[client]+1.0*intervual;
	}
	
	if(button & IN_FORWARD)
	{
		GetAngleVectors(clientAngle, temp, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(temp,temp);
		AddVectors(pushForce,temp,pushForce);
		move=true;
		pitch=1.0;
	}
	
	else if(button & IN_BACK)
	{
		GetAngleVectors(clientAngle, temp, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(temp,temp);
		SubtractVectors(pushForce, temp, pushForce);
		move=true;
		pitch=-1.0;
	}
	
	if(button & IN_MOVELEFT)
	{
		GetAngleVectors(clientAngle, NULL_VECTOR, temp, NULL_VECTOR);
		NormalizeVector(temp,temp);
		SubtractVectors(pushForce,temp,pushForce);
		move=true;
		roll=-1.0;
	}

	else if(button & IN_MOVERIGHT)
	{
		GetAngleVectors(clientAngle, NULL_VECTOR, temp, NULL_VECTOR);
		NormalizeVector(temp,temp);
		AddVectors(pushForce,temp,pushForce);
		roll=1.0;
	}

	if((button & IN_SPEED))
	{
		speed=true;
	}

	if(move && up)
	{
		ScaleVector(pushForceVertical, 0.3);
		ScaleVector(pushForce, 1.5);
	}

	if(speed || up || down)
	{
		fuelUsed*=3.0;
		speedLimit*=1.5;
		liftForce*=2.0;
	}
	
	AddVectors(pushForceVertical,pushForce,pushForce);
	NormalizeVector(pushForce, pushForce);
	ScaleVector(pushForce,liftForce*intervual);
	if(!(up || down))
	{
		if(FloatAbs(volicity[2])>40.0)gravity=volicity[2]*intervual;
		else gravity=gravityNormal;
	}
	
	float v=GetVectorLength(volicity);
	{
		if(gravity>0.5)gravity=0.5;
		if(gravity<-0.5)gravity=-0.5;

		if(speed && !(up || down))
		{
			volicity[2]*=0.8;
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, volicity);
		}

		else if(v>speedLimit)
		{
			NormalizeVector(volicity,volicity);
			ScaleVector(volicity, speedLimit);
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, volicity);

		}
		SetEntityGravity(client, gravity);
		Gravity[client]=gravity;
	}
	
	Fuel[client]-=fuelUsed;

	if(pitch==0.0)
	{
		if(Pitch[client]>0.0)pitch=-1.0;
		else if(Pitch[client]<0.0)pitch=1.0;
		else pitch=0.0;
		if(FloatAbs(Pitch[client])<5.0)
		{
			Pitch[client]=0.0;
			pitch=0.0;
		}
	}

	else
	{
		if(Pitch[client]>0.0 && pitch<0.0)pitch=-3.0;
		else if(Pitch[client]<0.0 && pitch>0.0)pitch=3.0;
	}
	
	Pitch[client]+=pitch*30.0*intervual;
	if(Pitch[client]>30.0)Pitch[client]=30.0;
	else if(Pitch[client]<-35.0)Pitch[client]=-35.0;

	if(roll==0.0)
	{
		if(Roll[client]>0.0)roll=-1.0;
		else if(Roll[client]<0.0)roll=1.0;
		else roll=0.0;
		if(FloatAbs(Roll[client])<5.0)
		{
			Roll[client]=0.0;
			roll=0.0;
		}
	}

	else
	{
		if(Roll[client]>0.0 && roll<0.0)roll=-3.0;
		else if(Roll[client]<0.0 && roll>0.0)roll=3.0;
	}
	
	Roll[client]+=roll*60.0*intervual;
	if(Roll[client]>35.0)Roll[client]=35.0;
	else if(Roll[client]<-35.0)Roll[client]=-35.0;

	bool shot1=false;
	bool shot2=false;
	bool shot3=false;
	
	if(button & IN_ATTACK)
	{
		if(time>ShotTime[client])
		{
			ShotTime[client]=time+0.037;
			if(Bullet[client]>0)
			{
				Bullet[client]--;
				shot1=true;
			}
		}
	}

	if(button & IN_ATTACK2)
	{
		if(time>BombTime [client])
		{
			BombTime[client]=time+1.0;
			if(Bomb[client]>0)
			{
				Bomb[client]--;
				shot2=true;
			}
		}
	}

	else if(button & IN_ZOOM)
	{
		if(time>BombTime [client])
		{
			BombTime[client]=time+1.0;
			if(Bomb[client]>0)
			{
				Bomb[client]--;
				shot3=true;
			}
		}
	}

	if((flag & FL_ONGROUND))
	{
		modelAng[2]=0.0;
		shot1=shot2=shot3=false;
		SetVector(volicity, 0.0, 0.0, 100.0);
		if(button & IN_JUMP)
		{
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR,volicity);
			SetEntityGravity(client, -0.5);
		}
		else
		{
			SetEntityGravity(client, 1.0);
		}
	}

	else
	{
		modelAng[0]+=Pitch[client];
		modelAng[2]=Roll[client];
	}

	if((button & IN_USE) && (button & IN_DUCK))
	{
		LostControl(client);
		return;
	}
	
	GetClientEyeAngles(client, clientAngle);

	float zero[3];
	SetVector(zero, 0.0, 0.0, 0.0);
	if(dummy && EntRefToEntIndex(dummy) != INVALID_ENT_REFERENCE)
		TeleportEntity(dummy, zero, zero, NULL_VECTOR);
	TeleportEntity(modelEnt, zero, zero, NULL_VECTOR);
	SetEntPropVector(modelEnt, Prop_Send, "m_angRotation", modelAng);
	if(HelicopterEnt_other[client] && EntRefToEntIndex(HelicopterEnt_other[client]) != INVALID_ENT_REFERENCE)
	{
		modelAng[0]=Pitch[client];
		modelAng[1]=clientAngle[1];
		TeleportEntity(HelicopterEnt_other[client], zero, zero, NULL_VECTOR);
		SetEntPropVector(HelicopterEnt_other[client], Prop_Send, "m_angRotation", modelAng);
	}

	if(shot1)
	{
		float clientEyePos[3];
		GetClientEyePosition(client, clientEyePos);
		Shot(client, clientPos,clientEyePos, clientAngle);
	}

	if(shot2 || shot3)
	{
		float clientEyePos[3];
		GetClientEyePosition(client, clientEyePos);
		DropBomb(client, clientPos,clientEyePos, clientAngle, shot3);
	}

	int m_pounceAttacker=GetEntProp(client, Prop_Send, "m_pounceAttacker");
	int m_tongueOwner=GetEntProp(client, Prop_Send, "m_tongueOwner");
	int m_isIncapacitated=GetEntProp(client, Prop_Send, "m_isIncapacitated", 1);
	int m_isHangingFromLedge=GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1);

	int m_pummelAttacker=GetEntProp(client, Prop_Send, "m_pummelAttacker", 1);
	int m_jockeyAttacker=GetEntProp(client, Prop_Send, "m_jockeyAttacker", 1);
	if(m_pounceAttacker>0 || m_tongueOwner>0 || m_isHangingFromLedge>0 || m_isIncapacitated>0 || m_pummelAttacker>0 || m_jockeyAttacker>0)
	{
		LostControl(client);
		return;
	}

	if((button & IN_USE))
	{
		if(Fuel[client]<0.0)Fuel[client]=-1.0;
		PrintHintText(client, "Bullets %d \nBombs %d \nFuel %d", Bullet[client], Bomb[client], RoundFloat(Fuel[client]));
	}

	if(Fuel[client]<0.0)
	{
		SetEntityGravity(client, 1.0);
	}

	if(time-RangeCheckTime[client]>1.0)
	{
		RangeCheckTime[client]=time;
		if(IsAlone(client))
		{
			int tick=RoundFloat(8.0-(time-AloneStartTime[client]));
			if(tick<0)tick=0;
			PrintHintText(client, "Chopper Too Far From Team! %d", tick);
		}
		
		else
		{
			AloneStartTime[client]=time;
		}
	}

	if(time-AloneStartTime[client]>=8.0)
	{
		SetEntityGravity(client, 1.0);
	}
}

bool IsAlone(int client)
{
	l4d2_helicopter_range.FloatValue;
	GetClientTeam(client);
	return false;/*
	float pos[3];
	float pos2[3];
	GetClientEyePosition(client, pos);

	float range=l4d2_helicopter_range.FloatValue;
	float Min=9999.0
 	for(int i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i)==2  && client!=i)
		{
			if(IsPlayerAlive(i))
			{
				GetClientEyePosition(i, pos2);
				float dis=GetVectorDistance(pos, pos2);
				if(dis<Min)
				{
					Min=dis;
				}
			}
		}
	}

	if(Min>range)return true;
	return false;*/
}

void Shot(int client, float helpos[3], float clientEyePos[3], float clientAngle[3])
{
	float hitpos[3];
	float gunpos[3];
	float pos[3];
	float angle[3];
	float right[3];
	float dir[3];

	CopyVector(helpos, pos);
	GetHitPos(client, clientEyePos, clientAngle, hitpos);

	GetAngleVectors(clientAngle, NULL_VECTOR, right, NULL_VECTOR);
	CopyVector(right, gunpos);
	bool leftgun=Bullet[client]%2==0;
 	if(leftgun)ScaleVector(gunpos, 20.0);
	else ScaleVector(gunpos, -20.0);
	AddVectors(pos, gunpos, gunpos);

	SubtractVectors(hitpos, gunpos, dir);
	NormalizeVector(dir,dir);

	float acc=l4d2_helicopter_gun_accuracy.FloatValue;
	if(acc<0.0)acc=0.0;

	acc=0.005+acc*0.018;

	dir[0]+=GetRandomFloat(-1.0, 1.0)*acc;
	dir[1]+=GetRandomFloat(-1.0, 1.0)*acc;
	dir[2]+=GetRandomFloat(-1.0, 1.0)*acc;
	GetVectorAngles(dir, angle);

	FireBullet(client, gunpos, angle, hitpos);
	ShowTrack(gunpos, hitpos);

	ShowMuzzleFlash(gunpos, clientAngle);

	EmitSoundToAll(SOUND_SHOT, DummyEnt[client], SNDCHAN_WEAPON, SNDLEVEL_NORMAL, SND_NOFLAGS,1.0, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
}

void GetHitPos(int client, float pos[3], float ang[3], float hitpos[3])
{
	Handle trace= TR_TraceRayFilterEx(pos, ang, MASK_SHOT, RayType_Infinite, TraceRayDontHitSelfAndSurvivor, client);
	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(hitpos, trace);
	}
	delete trace;
}

void DropBomb(int client, float helpos[3], float clientEyePos[3], float clientAngle[3], bool missile)
{
	float pos[3];
	float dir[3];
	float hitpos[3];

	SetVector(pos, 0.0, 0.0, -30.0);
	AddVectors(helpos, pos, pos);

	int ent=0;
	if(missile)
	{
		GetHitPos(client, clientEyePos, clientAngle, hitpos);
		SubtractVectors(hitpos, pos, dir);
		NormalizeVector(dir, dir);

		ent=CreateGLprojectile(client, pos, dir, 900.0, 0.01);
	}

	else
	{
		GetAngleVectors(clientAngle, dir, NULL_VECTOR, NULL_VECTOR);
		dir[2]=0.0;
		ent=CreateGLprojectile(client, pos, dir, 500.0, 1.0);
	}
	SDKHook(ent, SDKHook_StartTouch, BombTouch);

	EmitSoundToAll(SOUND_BOMBDROP, 0, SNDCHAN_WEAPON, SNDLEVEL_NORMAL, SND_NOFLAGS,1.0, SNDPITCH_NORMAL, -1, pos, NULL_VECTOR, true, 0.0);
}

public void BombTouch(int ent, int other)
{
	SDKUnhook(ent, SDKHook_StartTouch, BombTouch);
	float pos[3];
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
	int client = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
	AcceptEntityInput(ent, "kill");
	Explode(client, pos, 200.0, 100.0);
}

void Explode(int client, float pos[3], float radius = 160.0, float damage = 100.0)
{
	if (GetClientTeam(client) == L4D2Team_Infected){
		damage = damage * 0.07;
	}
	int push = CreateEntityByName("point_push");
  	DispatchKeyValueFloat (push, "magnitude",damage*2.0);
	DispatchKeyValueFloat (push, "radius", radius);
  	SetVariantString("spawnflags 24");
	AcceptEntityInput(push, "AddOutput");
 	DispatchSpawn(push);
	TeleportEntity(push, pos, NULL_VECTOR, NULL_VECTOR);
 	AcceptEntityInput(push, "Enable");
	CreateTimer(0.5, DeletePushForce, EntIndexToEntRef(push));

	int entity = CreateEntityByName("env_explosion");
	char sTemp[64]
	FloatToString(damage*2.0, sTemp, sizeof(sTemp));
	DispatchKeyValue(entity, "DamageForce", sTemp);
	DispatchKeyValue(entity, "iMagnitude", sTemp);
	DispatchKeyValue(entity, "spawnflags", "1916");
	FloatToString(radius, sTemp, sizeof(sTemp));
	DispatchKeyValue(entity, "iRadiusOverride", sTemp);
	DispatchSpawn(entity);
	TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
	SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
	AcceptEntityInput(entity, "Explode");

	ShowParticle(pos, NULL_VECTOR, PARTICLE_BOMBEXPLODE, 0.1);
	EmitSoundToAll(SOUND_BOMBEXPLODE, 0, SNDCHAN_WEAPON, SNDLEVEL_NORMAL, SND_NOFLAGS,1.0, SNDPITCH_NORMAL, -1, pos, NULL_VECTOR, true, 0.0);
}

int CreateGLprojectile(int client, float pos[3], float dir[3], float volicity = 500.0, float gravity = 1.0)
{
	float v[3];
	CopyVector(dir, v);
	NormalizeVector(v,v);
	ScaleVector(v, volicity);
	int ent=CreateEntityByName("grenade_launcher_projectile");
	DispatchKeyValue(ent, "model", MODEL_MISSILE);
	SetEntityGravity(ent, gravity);
	TeleportEntity(ent, pos, NULL_VECTOR, v);
	SetEntPropFloat(ent, Prop_Send,"m_flModelScale", 4.0);
	SetEntProp(ent, Prop_Data, "m_iHammerID", 2467737);
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	DispatchSpawn(ent);
	SetEntProp(ent, Prop_Send, "m_iGlowType", 3);
	SetEntProp(ent, Prop_Send, "m_nGlowRange", 0);
	SetEntProp(ent, Prop_Send, "m_nGlowRangeMin", 10);

	SetEntPropFloat(ent, Prop_Send, "m_fadeMinDist", 10000.0);
	SetEntPropFloat(ent, Prop_Send, "m_fadeMaxDist", 20000.0);
	return EntIndexToEntRef(ent);
}

int FireBullet(int client, float pos[3], float angle[3], float hitpos[3])
{
	Handle trace= TR_TraceRayFilterEx(pos, angle, MASK_SHOT, RayType_Infinite, TraceRayDontHitSelfAndSurvivor, client);
	int ent=0;
	bool hit=false;
	bool alive=false;
	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(hitpos, trace);
		ent=TR_GetEntityIndex(trace);
		hit=true;
		if(ent>0)
		{
			char classname[64];
			GetEdictClassname(ent, classname, 64);

			if(ent >=1 && ent<=MaxClients)
			{
				if(GetClientTeam(ent)==2) {}
				alive=true;
			}
			else if(StrContains(classname, "door")!=-1){}
			else if(StrContains(classname, "infected")!=-1){alive=true;}
			else ent=0;
		}
	}	
	delete trace;
	
	if(ent>0)
	{
		DoPointHurtForInfected(ent, client);
	}

	if(alive)
	{
		float Direction[3];
		GetAngleVectors(angle, Direction, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(Direction, -1.0);
		GetVectorAngles(Direction,Direction);
		ShowParticle(hitpos, Direction, PARTICLE_BLOOD, 0.1);
	}

	else if(hit)
	{
		float Direction[3];
		Direction[0] = GetRandomFloat(-1.0, 1.0);
		Direction[1] = GetRandomFloat(-1.0, 1.0);
		Direction[2] = GetRandomFloat(-1.0, 1.0);
		TE_SetupSparks(hitpos,Direction,1,3);
		TE_SendToAll();
	}
	return ent;
}

void ShowMuzzleFlash(float pos[3], float angle[3])
{
 	int particle = CreateEntityByName("info_particle_system");
	DispatchKeyValue(particle, "effect_name", PARTICLE_MUZZLE_FLASH);
	DispatchSpawn(particle);
	ActivateEntity(particle);
	TeleportEntity(particle, pos, angle, NULL_VECTOR);
	AcceptEntityInput(particle, "start");
	CreateTimer(0.01, DeleteParticles, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
}

void ShowTrack(float pos[3], float endpos[3])
{
 	char temp[16]="";
	int target = CreateEntityByName("info_particle_target");
	Format(temp, 64, "cptarget%d", target);
	DispatchKeyValue(target, "targetname", temp);
	TeleportEntity(target, endpos, NULL_VECTOR, NULL_VECTOR);
	ActivateEntity(target);

	int particle = CreateEntityByName("info_particle_system");
	DispatchKeyValue(particle, "effect_name", PARTICLE_WEAPON_TRACER);
	DispatchKeyValue(particle, "cpoint1", temp);
	DispatchSpawn(particle);
	ActivateEntity(particle);
	TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(particle, "start");
	CreateTimer(0.01, DeleteParticletargets, EntIndexToEntRef(target), TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.01, DeleteParticles, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
}

bool IsValidEnt(int ent)
{
	if(ent && EntRefToEntIndex(ent) != INVALID_ENT_REFERENCE)
		return true;
	return false;
}

void CopyVector(float source[3], float target[3])
{
	target[0]=source[0];
	target[1]=source[1];
	target[2]=source[2];
}

void SetVector(float target[3], float x, float y, float z)
{
	target[0]=x;
	target[1]=y;
	target[2]=z;
}

bool IsValidClient(int client, int team = 0, bool includeBot = true, bool alive = true)
{
	if(client>0 && client<=MaxClients)
	{
		if(IsClientInGame(client))
		{
			if(GetClientTeam(client)!=team && team!=0)return false;
			if(IsFakeClient(client) && !includeBot)return false;
			if(!IsPlayerAlive(client) && alive)return false;
			return true;
		}
	}
	return false;
}

public Action tank_killed(Event hEvent, const char[] strName, bool DontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	if(client>0 && client<=MaxClients)
	{
		float c=l4d2_helicopter_chance_tankdrop.FloatValue;
		if(GetRandomFloat(0.0, 100.0)<=c) {
			Fuel[client]=l4d2_helicopter_fuel.FloatValue;
			Bullet[client]=l4d2_helicopter_bullet.IntValue;
			Bomb[client]=l4d2_helicopter_bomb.IntValue;
			DropHelicopter(client);
		}
	}
	return Plugin_Continue;
}
public void L4D_OnEnterGhostState(int client){
	LostControl(client);
	ResetClientState(client);
}
public void player_changed_team(Event Spawn_Event, const char[] Spawn_Name, bool Spawn_Broadcast)
{
	int client = GetClientOfUserId(Spawn_Event.GetInt("userid"));
	LostControl(client);
	ResetClientState(client);
}

public void player_bot_replace(Event Spawn_Event, const char[] Spawn_Name, bool Spawn_Broadcast)
{
	int client = GetClientOfUserId(Spawn_Event.GetInt("player"));
	int bot = GetClientOfUserId(Spawn_Event.GetInt("bot"));

	LostControl(client);
	RemoveHelicopter(bot);
	ResetClientState(client);
	ResetClientState(bot);
}

public void bot_player_replace(Event Spawn_Event, const char[] Spawn_Name, bool Spawn_Broadcast)
{
	int client = GetClientOfUserId(Spawn_Event.GetInt("player"));
	int bot = GetClientOfUserId(Spawn_Event.GetInt("bot"));
	ResetClientState(client);
	ResetClientState(bot);
}

public Action player_spawn(Event hEvent, const char[] strName, bool DontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	ResetClientState(client);
	
	return Plugin_Continue;
}

public Action player_death(Event hEvent, const char[] strName, bool DontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	LostControl(client);
	ResetClientState(client);
	
	return Plugin_Continue;
}

public Action round_start(Event event, const char[] name, bool dontBroadcast)
{
	ResetAllState();
	
	return Plugin_Continue;
}

public Action round_end(Event event, const char[] name, bool dontBroadcast)
{
	RemoveHelicopterAll();
	ResetAllState();
	
	return Plugin_Continue;
}

public Action map_transition(Event event, const char[] name, bool dontBroadcast)
{
	RemoveHelicopterAll();
	ResetAllState();
	
	return Plugin_Continue;
}

public void OnPluginEnd()
{
	RemoveHelicopterAll();
}

void ResetClientState(int client)
{
	DummyEnt[client]=0;
	HelicopterEnt[client]=0;
	HelicopterEnt_other[client]=0;
}

void RemoveHelicopterAll()
{
	for(int i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			RemoveHelicopter(i);
		}
	}
}

void ResetAllState()
{
	g_PointHurt=0;

	for(int i=1; i<=MaxClients; i++)
	{
		ResetClientState(i);
	}
}

public void OnMapStart()
{
	if(L4D2Version)
	{
		PrecacheModel(MODEL_W_VOMITJAR);
		PrecacheModel(MODEL_HELICOPTER);
		PrecacheModel(MODEL_MISSILE);
		PrecacheSound(SOUND_FLAME, true);
		PrecacheSound(SOUND_ENGINE, true);
		PrecacheSound(SOUND_SHOT, true);
		PrecacheSound(SOUND_BOMBEXPLODE, true);
		PrecacheSound(SOUND_BOMBDROP, true);
		PrecacheParticle(PARTICLE_BOMBEXPLODE);
		PrecacheParticle(PARTICLE_WEAPON_TRACER);
		PrecacheParticle(PARTICLE_MUZZLE_FLASH);
		PrecacheParticle(PARTICLE_BLOOD);
 	}
	ResetAllState();
}

public void PrecacheParticle(char[] particlename)
{
	int particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(0.01, DeleteParticles, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action DeleteParticles(Handle timer, any particle)
{
	if (EntRefToEntIndex(particle) != INVALID_ENT_REFERENCE) {
		AcceptEntityInput(particle, "stop");
		AcceptEntityInput(particle, "kill");
	}
	return Plugin_Continue;
}

public Action DeleteParticletargets(Handle timer, any target)
{
	if (EntRefToEntIndex(target) != INVALID_ENT_REFERENCE) {
		AcceptEntityInput(target, "stop");
		AcceptEntityInput(target, "kill");
	}
	return Plugin_Continue;
}

public int ShowParticle(float pos[3], float ang[3], char[] particlename, float time)
{
	int particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchSpawn(particle);
		ActivateEntity(particle);
		TeleportEntity(particle, pos, ang, NULL_VECTOR);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, DeleteParticles, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
		return particle;
	}
	return 0;
}

void GameCheck()
{
	char GameName[16];
	FindConVar("mp_gamemode").GetString(GameName, sizeof(GameName));

	if (StrEqual(GameName, "survival", false))
		GameMode = 3;
	else if (StrEqual(GameName, "versus", false) || StrEqual(GameName, "teamversus", false) || StrEqual(GameName, "scavenge", false) || StrEqual(GameName, "teamscavenge", false))
		GameMode = 2;
	else if (StrEqual(GameName, "coop", false) || StrEqual(GameName, "realism", false))
		GameMode = 1;
	else
	{
		GameMode = 0;
 	}
	
	GetGameFolderName(GameName, sizeof(GameName));
	if (StrEqual(GameName, "left4dead2", false))
	{
		L4D2Version=true;
	}

	else
	{
		L4D2Version=false;
	}
	GameMode+=0;
}

void VisiblePlayer(int client, bool visible = true)
{
	if(visible)
	{
		SetEntityRenderMode(client, RENDER_NORMAL);
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}

	else
	{
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, 0, 0, 0, 0);
	}
}

void GotoThirdPerson(int client)
{
	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0);
	SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
}

void GotoFirstPerson(int client)
{
	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", -1);
	SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
}

public bool TraceRayDontHitSelfAndSurvivor(int entity, int mask, any data)
{
	if(entity == data)
	{
		return false;
	}

	if(entity>=1 && entity<=MaxClients)
	{
		/*if(GetClientTeam(entity)==2)
		{
			return false;
		}*/
	}
	return true;
}

int CreatePointHurt()
{
	int pointHurt=CreateEntityByName("point_hurt");
	if(pointHurt)
	{
		DispatchKeyValue(pointHurt, "Damage", "10");
		DispatchKeyValue(pointHurt, "DamageType", "2");
		DispatchSpawn(pointHurt);
	}
	return EntIndexToEntRef(pointHurt);
}

void DoPointHurtForInfected(int victim, int attacker = 0)
{
	char sTargetName[20];
	if(g_PointHurt && EntRefToEntIndex(g_PointHurt) != INVALID_ENT_REFERENCE)
	{
		if(victim>0 && IsValidEdict(victim))
		{
			float dmg;
			if (IsClientAndInGame(victim)){
				if (GetClientTeam(victim)==L4D2Team_Survivor){
					dmg = l4d2_helicopter_gun_damage.FloatValue/2.0;
				}else{
					dmg = l4d2_helicopter_gun_damage.FloatValue;
				}
			}
			else dmg = 10.0
			Format(sTargetName, 20, "target%d", victim);
			DispatchKeyValue(victim,"targetname", sTargetName);
			DispatchKeyValue(g_PointHurt, "DamageTarget", sTargetName);
			DispatchKeyValueFloat(g_PointHurt, "Damage", dmg);
			DispatchKeyValue(g_PointHurt, "DamageType", "-2130706430");
			AcceptEntityInput(g_PointHurt, "Hurt", (attacker>0)?attacker:-1);
		}
	}
	else g_PointHurt=CreatePointHurt();
}

public Action DeletePushForce(Handle timer, any entity)
{
	entity = EntRefToEntIndex(entity);
	if(entity != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(entity, "Disable");
		AcceptEntityInput(entity, "Kill");
	}
	return Plugin_Continue;
}

int CreateButton(int entity)
{
	char sTemp[16];
	int button;
	bool type=false;
	if(type) button = CreateEntityByName("func_button");
	else button = CreateEntityByName("func_button_timed");

	Format(sTemp, sizeof(sTemp), "target%d", button);
	DispatchKeyValue(entity, "targetname", sTemp);
	DispatchKeyValue(button, "glow", sTemp);
	DispatchKeyValue(button, "rendermode", "3");
	if(type)
	{
		DispatchKeyValue(button, "spawnflags", "1025");
		DispatchKeyValue(button, "wait", "1");
	}

	else
	{
		DispatchKeyValue(button, "spawnflags", "0");
		DispatchKeyValue(button, "auto_disable", "1");
		Format(sTemp, sizeof(sTemp), "%f", 5.0);
		DispatchKeyValue(button, "use_time", sTemp);
	}
	
	DispatchSpawn(button);
	AcceptEntityInput(button, "Enable");
	ActivateEntity(button);

	Format(sTemp, sizeof(sTemp), "ft%d", button);
	DispatchKeyValue(entity, "targetname", sTemp);
	SetVariantString(sTemp);
	AcceptEntityInput(button, "SetParent", button, button, 0);
	TeleportEntity(button, view_as<float> ({0.0, 0.0, 0.0}), NULL_VECTOR, NULL_VECTOR);

	SetEntProp(button, Prop_Send, "m_nSolidType", 0, 1);
	SetEntProp(button, Prop_Send, "m_usSolidFlags", 4, 2);

	float vMins[3] = {-5.0, -5.0, -5.0}, vMaxs[3] = {5.0, 5.0, 5.0};
	SetEntPropVector(button, Prop_Send, "m_vecMins", vMins);
	SetEntPropVector(button, Prop_Send, "m_vecMaxs", vMaxs);

	if(L4D2Version)
	{
		SetEntProp(button, Prop_Data, "m_CollisionGroup", 1);
		SetEntProp(button, Prop_Send, "m_CollisionGroup", 1);
	}

	if(type)
	{
		HookSingleEntityOutput(button, "OnPressed", OnPressed);
	}

	else
	{
		SetVariantString("OnTimeUp !self:Enable::1:-1");
		AcceptEntityInput(button, "AddOutput");
		HookSingleEntityOutput(button, "OnTimeUp", OnPressed);
	}
	return button;
}

public void OnPressed(const char[] output, int caller, int activator, float delay)
{
	float f=GetEntPropFloat(caller, Prop_Send, "m_fadeMaxDist");
	int ent=RoundFloat(f);
	StopSound(ent, SNDCHAN_AUTO,SOUND_ENGINE);
	AcceptEntityInput(ent, "kill");
	int index=-1;
	for(int i=0; i<=MaxClients; i++)
	{
		if(Info[i][0]==EntIndexToEntRef(ent))
		{
			Info[i][0]=0;
			index=i;
			break;
		}
	}
	CreateHelicopter(activator, index);
}