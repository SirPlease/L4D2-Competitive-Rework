#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>
#include <sdkhooks>
#include <readyup>
 
#define Pai 3.14159265358979323846 
#define DEBUG false

#define ViewMode_None 0
#define ViewMode_FellowF18 1
#define ViewMode_Teleport 2

#define State_None 0
#define State_Landing 1
#define State_Fly 2

#define ZOMBIECLASS_SURVIVOR	9
#define ZOMBIECLASS_SMOKER	1
#define ZOMBIECLASS_BOOMER	2
#define ZOMBIECLASS_HUNTER	3
#define ZOMBIECLASS_SPITTER	4
#define ZOMBIECLASS_JOCKEY	5
#define ZOMBIECLASS_CHARGER	6

#define PARTICLE_MUZZLE_FLASH		"weapon_muzzle_flash_pistol"  
#define PARTICLE_WEAPON_TRACER		"weapon_tracers_explosive" 
#define PARTICLE_BOMBEXPLODE		"weapon_grenadelauncher"
#define PARTICLE_BLOOD		"blood_gore_arterial_drip"
#define PARTICLE_IMPACT		"impact_incendiary_fire"

#define SOUND_SHOT		"weapons/50cal/50cal_shoot.wav"  
#define SOUND_BOMBEXPLODE		"weapons/grenade_launcher/grenadefire/grenade_launcher_explode_1.wav"  
#define SOUND_BOMBDROP		"weapons/grenade_launcher/grenadefire/grenade_launcher_fire_1.wav"  
#define SOUND_FLAME		"ambient/gas/steam2.wav"  
#define MODEL_W_PIPEBOMB "models/w_models/weapons/w_eq_pipebomb.mdl"

#define MODEL_F18 "models/f18/f18_sb.mdl"  //"models/f18/f18_sb.mdl" "models/c2m5_helicopter_extraction/c2m5_helicopter_small.mdl"
#define MODEL_F182 "models/missiles/f18_agm65maverick.mdl"

#define MODEL_MISSILE "models/w_models/weapons/w_HE_grenade.mdl"

new g_anim=0;

new ZOMBIECLASS_TANK=	5;
 
new GameMode;
new L4D2Version;
new g_ghostoffest;
new g_sprite;
new g_iVelocity ;
new g_offsNextPrimaryAttack; 

new F18FirstRun[MAXPLAYERS+1]; 

new F18Ent[MAXPLAYERS+1]; 
new F18ModelEnt[MAXPLAYERS+1]; 
new F18Camera[MAXPLAYERS+1]; 
new F18Flame[MAXPLAYERS+1][6]; 
new Float:F18UpDir[MAXPLAYERS+1][3]; 
new Float:F18FrontDir[MAXPLAYERS+1][3]; 
new Float:ClientAngle[MAXPLAYERS+1][3]; 
new State[MAXPLAYERS+1]; 
new ViewMode[MAXPLAYERS+1]; 
new FirstPersonMode[MAXPLAYERS+1]; 
new LastButton[MAXPLAYERS+1]; 
new Float:LastTime[MAXPLAYERS+1]; 


new Float:Roll[MAXPLAYERS+1]; 
new Float:RollSpeed[MAXPLAYERS+1]; 
new Float:Pitch[MAXPLAYERS+1]; 
new Float:PitchSpeed[MAXPLAYERS+1]; 
new Float:Yaw[MAXPLAYERS+1]; 
new Float:YawSpeed[MAXPLAYERS+1]; 

new Float:ModelRoll[MAXPLAYERS+1]; 
new Float:ModelPitch[MAXPLAYERS+1]; 
new Float:ModelYaw[MAXPLAYERS+1];

new Float:F18Speed[MAXPLAYERS+1]; 
 
new Float:F18LastPos[MAXPLAYERS+1][3]; 

new F18Bullet[MAXPLAYERS+1]; 
new F18Bomb[MAXPLAYERS+1]; 
new Float:F18BombTime[MAXPLAYERS+1];
new Float:F18ShotTime[MAXPLAYERS+1];

new F18Missle[MAXPLAYERS+1]; 
new Float:F18MissleTime[MAXPLAYERS+1];

new F18SoundVolume[MAXPLAYERS+1]; 
 
new Float:F18MaxSpeed=350.0;
new Float:F18MinSpeed=40.0;
new Float:F18ShotIntervual=0.05;
new Float:F18BombIntervual=1.0;
new Float:F18MissileIntervual=1.0;
new g_PointHurt=0;
 

new Handle:l4d_uav_enable ;  
new Handle:l4d_uav_team ; 
new Handle:l4d_uav_maxuser ; 
new Handle:l4d_uav_teleport ;

new Handle:l4d_uav_gundamage ;
new Handle:l4d_uav_bombdamage ;

new Handle:l4d_uav_bulletcount;
new Handle:l4d_uav_bombcount;
new Handle:l4d_uav_bombradius;

new Handle:l4d_uav_size;
public Plugin:myinfo = 
{
	name = "uav",
	author = "Pan Xiaohai",
	description = "l4d2 only",
	version = "1.01",	
}
Float:GetModelScale()
{
	new Float:modelScale=GetConVarFloat(l4d_uav_size);
	if(modelScale<1.0)modelScale=1.0;
	if(modelScale>5.5)modelScale=5.5;
	return modelScale;
}
public OnPluginStart()
{
	GameCheck(); 	
	if(!L4D2Version)return;
 	g_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]");	
	g_offsNextPrimaryAttack = FindSendPropOffs("CBaseCombatWeapon","m_flNextPrimaryAttack");
	
	l4d_uav_enable = CreateConVar("l4d_uav_enable", "2", "  0:disable, 1:enable in coop mode, 2: enable in all mode ", FCVAR_PLUGIN);
	l4d_uav_team = CreateConVar("l4d_uav_team", "1", "  1:enable for survivor and infected, 2:enable for survivor, 3:enable for infected ", FCVAR_PLUGIN);	
	l4d_uav_maxuser = CreateConVar("l4d_uav_maxuser", "8", "how many people can use it", FCVAR_PLUGIN);	
	l4d_uav_teleport = CreateConVar("l4d_uav_teleport", "0", "0:disable 1:enable teleport to teamate", FCVAR_PLUGIN);	
	
	l4d_uav_gundamage=CreateConVar("l4d_uav_gundamage", "20.0", "damage of machine gun", FCVAR_PLUGIN);	
	l4d_uav_bombdamage=CreateConVar("l4d_uav_bombdamage", "100.0", "damage of bomb", FCVAR_PLUGIN);	
	l4d_uav_bombradius=CreateConVar("l4d_uav_bombradius", "200.0", "damage radius of bomb", FCVAR_PLUGIN);	

	l4d_uav_bulletcount=CreateConVar("l4d_uav_bulletcount", "1500", "count of bullet", FCVAR_PLUGIN);	
	l4d_uav_bombcount=CreateConVar("l4d_uav_bombcount", "80", "count of bomb", FCVAR_PLUGIN);	
	
	l4d_uav_size=CreateConVar("l4d_uav_size", "4.0", "f18 size [1.0. 5.0]", FCVAR_PLUGIN);	
	
	AutoExecConfig(true, "l4d2_uav"); 
 
	g_ghostoffest=FindSendPropInfo("CTerrorPlayer", "m_isGhost");
	
	RegConsoleCmd("sm_f18", sm_f18); 
	//RegConsoleCmd("sm_test", sm_test); 
	
	HookEvent("player_bot_replace", player_bot_replace );	 
 
	HookEvent("round_start", round_end);
	HookEvent("round_end", round_end);
	HookEvent("finale_win", round_end);
	HookEvent("mission_lost", round_end);
	HookEvent("map_transition", round_end);	
	
	ResetAllState();
}

public void OnRoundLiveCountdownPre(){
	for (int i=1; i<=MaxClients; i++){
		Stop(i); 
	}
}

public Action:round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	ResetAllState();
}
public player_bot_replace(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{	 
	new client = GetClientOfUserId(GetEventInt(Spawn_Event, "player"));
	new bot = GetClientOfUserId(GetEventInt(Spawn_Event, "bot")); 
	Stop(client); 
}
public Action:sm_test(client,args)
{	
	if(State[client]!=State_None)
	{
		PrintToChat(client, "amin %d", g_anim);
		SetEntProp(F18ModelEnt[client], Prop_Send, "m_nSequence" ,g_anim); 
		SetEntPropFloat(F18ModelEnt[client], Prop_Send, "m_flPlaybackRate" ,1.0);
		g_anim++;
	}
}
public Action:sm_f18(client,args)
{
	if (!IsInReady()){
		PrintToChat(client, "游戏已经开始");
		return;
	}
	if(CanUse(client) )
	{
		if(GetUserCount()<GetConVarInt(l4d_uav_maxuser))	Start(client);
		else PrintToChat(client, "There are too many f18 operators", GetConVarInt(l4d_uav_maxuser));
	}
}
GetUserCount()
{
	new count=0;
	for(new i=1; i<=MaxClients; i++)
	{
		if(State[i]!=State_None)count++;		 
	}
	return count;
}
bool:CanUse(client)
{
	new mode=GetConVarInt(l4d_uav_enable);
	if(mode==0)return false;
	if(mode==1 && GameMode==2)return false;
	if(client>0 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		new team=GetConVarInt(l4d_uav_team);
		if(GetClientTeam(client)==2)
		{
			if(team==1 || team==2)
			{
				return true;
			}
		}
		else
		{
			if(team==1 || team==3)
			{
				if( GetEntData(client, g_ghostoffest, 1))	return false;
				else return true;
				
			}
		}
	}
	return false;
}
ResetAllState()
{
	g_PointHurt=0; 
	for(new i=1; i<=MaxClients; i++)
	{
		F18FirstRun[i]=1;
		State[i]=State_None;
		F18Bullet[i]=GetConVarInt(l4d_uav_bulletcount);
		F18Bomb[i]=GetConVarInt(l4d_uav_bombcount);
		F18Missle[i]=20;
		SDKUnhook( i, SDKHook_PreThink,  PreThink); 
		F18Ent[i]=0;
		if(IsClientInGame(i))
		{
			SetClientViewEntity(i, i);			
			//if(FirstPersonMode[i]==0)GotoFirstPerson(i);
			if(IsPlayerAlive(i))SetEntityMoveType(i, MOVETYPE_WALK);
		}
		FirstPersonMode[i]=0;
	}
}
public PreThink(client)
{
	if(client>0 && F18Ent[client]>0 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		new Float:time=GetEngineTime( );
		new Float:intervual=time-LastTime[client]; 
		new button=GetClientButtons(client); 
		TrackF18(client, button , time, intervual); 
		LastTime[client]=time; 
		LastButton[client]=button;	 
	}
	else
	{
		Stop(client);
	}

}
/*
public OnGameFrame()
{
	
	if(GetClientButtons(1) & IN_USE)
	{
		new m=GetEntProp(1, Prop_Send, "m_nSequence" );
		new all_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]");
		decl Float:velocity[3];
		GetEntDataVector(1, all_iVelocity, velocity);
		new Float:playrate = GetEntPropFloat(1, Prop_Send, "m_flPlaybackRate");	
		PrintToChatAll("vec %f seq %d", GetVectorLength(velocity), m);
	}
}
*/
  
Stop(client, bool:teleport=false)
{
	if(State[client]!=State_None)
	{
		PrintToChat(client, "Stop f18");		
		SDKUnhook( client, SDKHook_PreThink,  PreThink); 
		
		State[client]=State_None;		
		StopSound(F18Ent[client], SNDCHAN_AUTO, SOUND_FLAME);	
		SetClientViewEntity(client, client);
		SetEntityMoveType(client, MOVETYPE_WALK);
		if(FirstPersonMode[client]==0)GotoFirstPerson(client);
		FirstPersonMode[client]=1;
		if(F18Ent[client]>0 &&IsValidEntity(F18Ent[client]) && IsValidEdict(F18Ent[client]))RemoveEdict(F18Ent[client]);
		F18Ent[client]=0;
		if(teleport && GetConVarInt(l4d_uav_teleport)==1)
		{
			new bool:b=false;
			for(new i=1; i<=MaxClients; i++)
			{
				if(IsClientInGame(i) && IsPlayerAlive(i))
				{
					new Float:pos[3];
					GetClientAbsOrigin(i, pos);
					if(GetVectorDistance(pos,F18LastPos[client])<500.0)
					{
						TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
						b=true;
						break;
					}
				}
			}
			if(!b)
			{
				PrintHintText(client, "You can teleport to your teamate if your uav is close to them");
			}
		}
	}
}
new g_count=0;
Start(client)
{
	if(State[client]!=State_None)return;
	new ent=CreateF18(client);
	SDKUnhook( client, SDKHook_PreThink,  PreThink); 
	SDKHook( client, SDKHook_PreThink,  PreThink);  
	
	new Float:time=GetEngineTime();	
	new c=CreateCamera(ent, client); 
	
	F18Camera[client]=c;
	Roll[client]=0.0;
	Pitch[client]=0.0; 
	Yaw[client]=0.0;
	ModelRoll[client]=0.0;
	ModelPitch[client]=0.0; 
	ModelYaw[client]=0.0;
	F18Ent[client]=ent;
	LastButton[client]=0;
	RollSpeed[client]=0.0;
	PitchSpeed[client]=0.0;
	YawSpeed[client]=0.0;
	F18Speed[client]=F18MinSpeed;
	F18SoundVolume[client]=1;
	ViewMode[client]=ViewMode_FellowF18;
	FirstPersonMode[client]=1;
	LastTime[client]=time;
	F18ShotTime[client]=time;

	F18BombTime[client]=time;
	
	
	F18MissleTime[client]=time;
	
	SetVector(F18UpDir[client], 0.0, 0.0, 1.0); 
	State[client]=State_Fly;
	SetEntityMoveType(client, MOVETYPE_NONE);
	SetSound(client, 0.5);
	SetClientViewEntity(client, c);
	new g_count=0;
	PrintToChat(client, "\x03按下 \x04换弹键 \x03改变操控模式");
	PrintToChat(client, "\x03按下 \x04使用键 \x03退出, \x04Ctrl \x03或 \x04Space \x03控制油门");
	PrintHintText(client, "按下换弹键改变操控模式");

	if(F18FirstRun[client]==1)
	{
		F18Bullet[client]=GetConVarInt(l4d_uav_bulletcount);
		F18Bomb[client]=GetConVarInt(l4d_uav_bombcount);
	}
	F18FirstRun[client]=0;
	
}
SetSound(client, Float:volume)
{
	if(client>0 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		new Float:pos[3];
		GetClientEyePosition(client, pos);
		if(volume>1.0)volume=1.0;
		if(volume<0.1)volume=0.1;
		StopSound(F18Ent[client], SNDCHAN_AUTO, SOUND_FLAME);	
		EmitSoundToAll(SOUND_FLAME, F18Ent[client],  SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS,volume, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	}
}

TrackF18(client, button ,Float:time, Float:intervual)
{
	g_count++;
	new Float:pitch=0.0;
	new Float:roll=0.0;
	new Float:yaw=0.0;
	decl Float:f18Angle[3];
	decl Float:f18ModelAngle[3];
	decl Float:clientAngle[3];
	decl Float:f18pos[3];
	decl Float:f18velocity[3];
	decl Float:velocity[3];
	decl Float:f18newvelocity[3];
	decl Float:temp[3];
	decl Float:up[3];
 
	decl Float:f18front[3];
	decl Float:f18up[3];
	decl Float:f18right[3];
	decl Float:f18front2[3];
	decl Float:f18up2[3];
	decl Float:f18right2[3];
	SetVector(up, 0.0, 0.0, 1.0);
 
	new ent=F18Ent[client];
	new modelent=F18ModelEnt[client]; 
	
	if(button & IN_USE)
	{  
		Stop(client, true);
		return;
	}
	if(button & IN_MOVELEFT)
	{  
		if((button & IN_SPEED) && FirstPersonMode[client])yaw=1.0;
		else roll=-1.0;		 
	}
	if(button & IN_MOVERIGHT)
	{
		if((button & IN_SPEED) && FirstPersonMode[client])yaw=-1.0;
		else roll=1.0;		
	}
	if(button & IN_FORWARD)
	{ 
		pitch=-1.0;
		
	}
	else if(button & IN_BACK)
	{
		pitch=1.0;
	}
	new Float:speed=0.0;
	if(button & IN_JUMP)
	{
		speed=1.0;
	}
	else if(button & IN_DUCK)
	{
		speed=-1.0;
	}
	new bool:shot1=false;
	new bool:shot2=false;
	if(button & IN_ATTACK)
	{
		if(time>F18ShotTime[client])
		{			 
			F18ShotTime[client]=time+F18ShotIntervual;			
			if(F18Bullet[client]>0)
			{
				F18Bullet[client]--;
				shot1=true;			
			}		
		}
	}
	if(button & IN_ATTACK2)
	{
		if(time>F18BombTime [client])
		{			 
			F18BombTime[client]=time+F18BombIntervual;
			if(F18Bomb[client]>0)
			{
				F18Bomb[client]--;
				shot2=true;			
			}
		}
	}
	ProcessViewMode(client, button);
	
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", f18pos); 
	GetClientEyeAngles(client, clientAngle);	
	

	new Float:droll=0.0;
	new Float:dpitch=0.0;
	new Float:dyaw=0.0;
	

	if(FirstPersonMode[client] || (button & IN_SPEED))
	{	
		F18Speed[client]+=100.0*speed*intervual;
		if(F18Speed[client]>F18MaxSpeed)F18Speed[client]=F18MaxSpeed;
		if(F18Speed[client]<F18MinSpeed)F18Speed[client]=F18MinSpeed; 
		
		CopyVector(F18FrontDir[client], f18velocity); 
		NormalizeVector(f18velocity,f18velocity);  
		
		ProcessModelPitchRoll(client, roll, pitch, yaw, intervual, ClientAngle[client], clientAngle);

		ProcessPitchRoll(client, roll, pitch, yaw, intervual, droll, dpitch, dyaw,ClientAngle[client], clientAngle);
		CopyVector(clientAngle,ClientAngle[client]);
		

		GetProjection(f18velocity, F18UpDir[client], f18up); 
		
		GetVectorCrossProduct(f18velocity, f18up, f18right );
		NormalizeVector(f18up,f18up);
		NormalizeVector(f18right,f18right);
		CopyVector(f18up, f18up2);
		CopyVector(f18right, f18right2);
		
		RotateVector(f18velocity, f18up, droll/180.0*Pai, f18up);
		NormalizeVector(f18up,f18up); 

		
		CopyVector(f18up,F18UpDir[client]);
		ScaleVector(f18up, PitchSpeed[client]*intervual*2.0);
		AddVectors(f18velocity, f18up, f18newvelocity);	
		ScaleVector(f18right, (0.0-YawSpeed[client])*intervual*0.5);
		AddVectors(f18newvelocity, f18right, f18newvelocity);	
		//ShowDir(0, f18pos, f18right, 0.06);
		NormalizeVector(f18newvelocity, f18newvelocity);
		ScaleVector(f18newvelocity, F18Speed[client]);
		CopyVector(f18newvelocity, F18FrontDir[client]); 
		
		 
		GetEntDataVector(ent, g_iVelocity, velocity);	 
		SubtractVectors(f18newvelocity, velocity, temp);
		ScaleVector(temp, 2.0*intervual);
		AddVectors(velocity,temp,velocity);
 
 
		GetProjection(f18velocity,up, temp);
		new Float:a=GetAngleWithSign(f18velocity, temp, F18UpDir[client])*180.0/Pai;
		Roll[client]=0.0-a;
		if(Roll[client]>10000.0)Roll[client]=10000.0;
		if(Roll[client]<-10000.0)Roll[client]=-10000.0;
			 
		GetVectorAngles(f18velocity,f18Angle);
		f18Angle[2]=Roll[client]; 
		
		TeleportEntity(ent,NULL_VECTOR , f18Angle , velocity); 
		SetVector(f18ModelAngle, ModelPitch[client], ModelYaw[client], ModelRoll[client]);
		TeleportEntity(modelent, NULL_VECTOR, f18ModelAngle , NULL_VECTOR);
		if(ViewMode[client]==ViewMode_Teleport)
		{
			TeleportEntity(client,f18pos , NULL_VECTOR , NULL_VECTOR); 
		}
		if(shot1)Shot(client, F18LastPos[client], f18newvelocity, f18up2, f18right2, velocity, intervual);
		if(shot2)Bomb(client, F18LastPos[client], f18newvelocity, f18up2, f18right2, velocity, intervual );
	}
	if(!FirstPersonMode[client])
	{
		if(!(button & IN_SPEED))
		{	
			if(button & IN_FORWARD)
			{
				speed=1.0;
			}
			else if(button &IN_BACK)
			{
				speed=-1.0;
			}
			F18Speed[client]+=100.0*speed*intervual;
			if(F18Speed[client]>F18MaxSpeed)F18Speed[client]=F18MaxSpeed;
			if(F18Speed[client]<F18MinSpeed)F18Speed[client]=F18MinSpeed; 
			decl Float:targetdir[3];
			decl Float:targetdirproj[3];
			CopyVector(F18FrontDir[client], f18front); 
			new bool:z=false;
			 
			GetProjection(f18front, F18UpDir[client], f18up);  			 
			GetProjection(f18front, up, temp); 
			 
			//PrintToChatAll("up %f %f %f %f", f18up[0], f18up[1], f18up[2], GetVectorLength(f18up));
			if(GetVectorLength(f18up)<0.1)
			{
				//CopyVector(up, f18up); 
			}
			GetVectorCrossProduct(f18front, f18up, f18right );
			NormalizeVector(f18right,f18right);
		 
			GetAngleVectors(clientAngle,targetdir, NULL_VECTOR, NULL_VECTOR);
			NormalizeVector(targetdir,targetdir); 
			
			GetProjection(f18front, targetdir, targetdirproj); 
			NormalizeVector(targetdirproj,targetdirproj);
			NormalizeVector(f18up,f18up); 
			
			new Float:trunforce=GetAngle(f18front, targetdir)*180.0/Pai;
			new Float:ang=GetAngleWithSign(f18front, f18up, targetdirproj)*180.0/Pai;	
			new Float:N=GetAngle(targetdir, f18newvelocity)*180.0/Pai;
			//PrintToChatAll("N %f", N);
			new bool:balance=false;
			if(N>20.0)
			{
				//PrintToChatAll("trunforce %f ang %f",trunforce, ang );
				
				new bool:pitchup;
				if(FloatAbs(ang)>(90.0+0.0))
				{
					//PrintToChatAll("pitch down");
					pitchup=false;
					//ang=0.0-ang;
					//ScaleVector(targetdirproj, -1.0);
				}
				else
				{
					//PrintToChatAll("pitch up");
					pitchup=true;
				}
				
			
				
				////////////////////////////////////////////////////////////roll
				new Float:MaxRollSpeed=300.0;			
				droll= 0.0-FloatSign(ang);		 
				 
				new Float:f;
				f=ang;
				if(droll==0.0)droll=0.0;
				else if(droll>0.0)droll=MaxRollSpeed*intervual;
				else droll=-1.0*MaxRollSpeed*intervual;
				
				
				if(FloatAbs(ang)>3.0 )
				{
					RotateVector(f18front, f18up, droll*Pai/180.0, f18up2); 	
					RotateVector(f18front, f18right, droll*Pai/180.0, f18right2); 	
					NormalizeVector(f18up2,f18up2);
					NormalizeVector(f18right2,f18right2);
					f=GetAngleWithSign(f18front, f18up2, targetdirproj);				
				}			
				else
				{
					CopyVector(f18right,f18right2);
					CopyVector(f18up,f18up2);
				}
				if(FloatSign(f)!=FloatSign(ang) || FloatAbs(ang)<=5.0 || FloatAbs(droll*Pai/180.0)>=FloatAbs(ang))
				{
					CopyVector(targetdirproj,f18up2);
					GetVectorCrossProduct(f18front, f18up2, f18right2 );
					NormalizeVector(f18up2,f18up2);
					NormalizeVector(f18right2,f18right2); 
					
				}  
		 
				CopyVector(f18front,f18front2);		 
				
			}
			else
			{
				CopyVector(targetdir,f18newvelocity); 
				CopyVector(targetdir,f18front2);
				GetProjection(f18front2, f18up, f18up2); 
				balance=true; 
			} 
			CopyVector(targetdir,f18newvelocity);
			ScaleVector(f18newvelocity, F18Speed[client]);		
				
				 
			GetEntDataVector(ent, g_iVelocity, f18velocity);	 
			SubtractVectors(f18newvelocity, f18velocity, temp);
			ScaleVector(temp, 2.0*intervual);
			AddVectors(f18velocity,temp,f18newvelocity); 
			NormalizeVector(f18newvelocity, f18newvelocity);
			ScaleVector(f18newvelocity, F18Speed[client]);		
			if( balance )
			{
				ang=GetRollAngle(f18front2, f18up2, up, temp ); 
				if( FloatAbs(ang)>5.0)
				{
					droll= -4.0*FloatSign(ang);
					//ShowDir(0,f18front2, f18up2, 0.06);
					RotateVector(f18front2, f18up2, droll*Pai/180.0, f18up2); 	
					RotateVector(f18front2, f18right2, droll*Pai/180.0, f18right2); 	
					NormalizeVector(f18up2,f18up2);
					NormalizeVector(f18right2,f18right2);	 
				}
				else
				{ 
					CopyVector(f18up,f18up2);
					CopyVector(f18right,f18right2); 
				}
			}
			 
			
			CopyVector(f18up2, F18UpDir[client]);
			CopyVector(f18front2, F18FrontDir[client]);
			
			ang=GetRollAngle(f18front2, f18up2, up, temp); 
			Roll[client]=ang;			
			GetVectorAngles(f18front,f18Angle);
			f18Angle[2]=Roll[client]; 
			CheckAngle(f18Angle);  
				
			
			CopyVector(f18newvelocity,F18FrontDir[client]);
			NormalizeVector(F18FrontDir[client],F18FrontDir[client]);
			 
			TeleportEntity(ent,NULL_VECTOR , f18Angle , f18newvelocity); 
			SetVector(f18ModelAngle, 0.0, 0.0, 0.0);
			TeleportEntity(modelent, NULL_VECTOR, f18ModelAngle , NULL_VECTOR);
			if(shot1)Shot(client, F18LastPos[client], f18front2, f18up2, f18right2, f18newvelocity, intervual );
			if(shot2)Bomb(client, F18LastPos[client], f18front2, f18up2, f18right2, f18newvelocity, intervual );
		}
	} 	
	CopyVector(f18pos, F18LastPos[client]);
	ProcessSound(client);
	
	if(speed!=0.0 || shot1 || shot2)PrintCenterText(client, "throttle %d%% \nbullet %d\nbomb %d", RoundFloat(((F18Speed[client]-F18MinSpeed)/(F18MaxSpeed-F18MinSpeed)+0.2)*100.0) , F18Bullet[client], F18Bomb[client]);
	HitCheck(client, f18pos,velocity, temp);	 
	 
}
Bomb(client, Float:f18pos[3], Float:f18front[3], Float:f18up[3], Float:f18right[3], Float:f18vel[3], Float:intervual )
{	
 
	decl Float:pos[3]; 
	decl Float:angle[3]; 
	decl Float:temp[3]; 
 
	 
	CopyVector(f18pos, pos);
	SetVector(temp, 0.0, 0.0, 1.0);
	NormalizeVector(temp, temp);
	ScaleVector(temp, -10.0);
	AddVectors(pos, temp, pos);
	
	new ent=CreateGLprojectile(client, pos, f18front, GetVectorLength(f18vel)+500.0, 1.0); 
	SDKHook(ent, SDKHook_StartTouch , BombTouch);
	
	EmitSoundToAll(SOUND_BOMBDROP, 0,  SNDCHAN_WEAPON, SNDLEVEL_NORMAL, SND_NOFLAGS,1.0, SNDPITCH_NORMAL, -1, f18pos, NULL_VECTOR, true, 0.0);
 	
}
public BombTouch(ent, other)
{	 
	SDKUnhook(ent, SDKHook_StartTouch, BombTouch);
	decl Float:pos[3];
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos); 
	AcceptEntityInput(ent, "kill");
	Explode(pos, GetConVarFloat(l4d_uav_bombradius), GetConVarFloat(l4d_uav_bombdamage));
}
Explode(Float:pos[3], Float:radius=200.0, Float:damage=100.0)
{
	new pointHurt = CreateEntityByName("point_hurt");    	
 	DispatchKeyValueFloat(pointHurt, "Damage", damage);        
	DispatchKeyValueFloat(pointHurt, "DamageRadius", radius);   
	if(L4D2Version)	DispatchKeyValue(pointHurt, "DamageType", "64"); 
	else DispatchKeyValue(pointHurt, "DamageType", "64"); 
 	DispatchKeyValue(pointHurt, "DamageDelay", "0.0");   
	DispatchSpawn(pointHurt);
	TeleportEntity(pointHurt, pos, NULL_VECTOR, NULL_VECTOR);  
	AcceptEntityInput(pointHurt, "Hurt");    
	CreateTimer(0.1, DeletePointHurt, pointHurt); 
 
	new push = CreateEntityByName("point_push");         
  	DispatchKeyValueFloat (push, "magnitude",damage*2.0);                     
	DispatchKeyValueFloat (push, "radius", radius);                     
  	SetVariantString("spawnflags 24");                     
	AcceptEntityInput(push, "AddOutput");
 	DispatchSpawn(push);   
	TeleportEntity(push, pos, NULL_VECTOR, NULL_VECTOR);  
 	AcceptEntityInput(push, "Enable");
	CreateTimer(0.5, DeletePushForce, push); 
	
	
	ShowParticle(pos, NULL_VECTOR,  PARTICLE_BOMBEXPLODE, 0.1);	
	EmitSoundToAll(SOUND_BOMBEXPLODE, 0,  SNDCHAN_WEAPON, SNDLEVEL_NORMAL, SND_NOFLAGS,1.0, SNDPITCH_NORMAL, -1, pos, NULL_VECTOR, true, 0.0);
 		
}
Float:GetRollAngle(Float:f18front[3],Float:f18up[3], Float:up[3],Float:temp[3])
{
	GetProjection(f18front,up, temp);
	//CopyVector(up, temp);
	new Float:ang=0.0-GetAngleWithSign(f18front, temp, f18up)*180.0/Pai;
	return ang;
}
RotateVector2(Float:vec[3], Float:to[3], Float:alfa, Float:result[3])
{
	decl Float:v[3];
	decl Float:d[3];
	CopyVector(vec,v);
	CopyVector(to,d);
	NormalizeVector(v,v);
}
Float:FloatSign(Float:f)
{
	if(f==0.0)return 0.0;
	else if(f>0.0)return 1.0;
	else return -1.0;
}
CheckAngle(Float:angle[3])
{
	for(new i=0; i<3; i++)
	{
		if(angle[i]>10000.0)angle[i]=10000.0;
		else if(angle[i]<-10000.0)angle[i]=-10000.0;	
	}
}
Shot(client, Float:f18pos[3], Float:f18front[3], Float:f18up[3], Float:f18right[3], Float:f18vel[3], Float:intervual )
{	
	
	decl Float:gunpos1[3]; 
	decl Float:gunpos2[3]; 
	decl Float:pos[3]; 
	decl Float:angle[3]; 
	decl Float:angle1[3]; 
	decl Float:angle2[3]; 
	decl Float:temp[3]; 
 
	 
	CopyVector(f18pos, pos);
	
	new Float:witch=8.0+(GetModelScale()-1.0)*4.0;
	
	CopyVector(f18right, gunpos1);
	CopyVector(f18right, gunpos2);
	ScaleVector(gunpos1, witch);
	ScaleVector(gunpos2, 0.0-witch); 
	
	AddVectors(pos, gunpos1, gunpos1);
	AddVectors(pos, gunpos2, gunpos2);
	
	
	CopyVector(f18front, angle);
	new Float:acc=0.015;
	angle[0]+=GetRandomFloat(-1.0, 1.0)*acc;
	angle[1]+=GetRandomFloat(-1.0, 1.0)*acc;
	angle[2]+=GetRandomFloat(-1.0, 1.0)*acc;
	GetVectorAngles(angle, angle1); 
 
	CopyVector(f18front, angle); 
	angle[0]+=GetRandomFloat(-1.0, 1.0)*acc;
	angle[1]+=GetRandomFloat(-1.0, 1.0)*acc;
	angle[2]+=GetRandomFloat(-1.0, 1.0)*acc;
	GetVectorAngles(angle, angle2); 
	 
	 
	decl Float:hitpos1[3]; 
	decl Float:hitpos2[3]; 
	
	new victim1=FireBullet(client, gunpos1, angle1, hitpos1);
	new victim2=FireBullet(client, gunpos2, angle2, hitpos2);
	ShowTrack(client, gunpos1, hitpos1);
	ShowTrack(client, gunpos2, hitpos2);
	
	ShowMuzzleFlash(client,gunpos1, angle, 0);
	ShowMuzzleFlash(client,gunpos2, angle, 1); 
	
	EmitSoundToAll(SOUND_SHOT, F18Ent[client],  SNDCHAN_WEAPON, SNDLEVEL_NORMAL, SND_NOFLAGS,1.0, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
 	
}
CreateGLprojectile(client, Float:pos[3], Float:dir[3], Float:volicity=1000.0, Float:gravity=0.01)
{
	decl Float:v[3];
	CopyVector(dir, v);
	NormalizeVector(v,v);
	ScaleVector(v, volicity);
	new ent=CreateEntityByName("grenade_launcher_projectile");
	//SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client)	;	
	DispatchKeyValue(ent, "model", MODEL_MISSILE); 
	SetEntityGravity(ent, gravity);
	//IgniteEntity(ent, 10.0);
	TeleportEntity(ent, pos, NULL_VECTOR, v);
	DispatchSpawn(ent);  
	SetEntPropFloat(ent, Prop_Send,"m_flModelScale", GetModelScale()*1.5);
	
	SetEntProp(ent, Prop_Send, "m_iGlowType", 3);
	SetEntProp(ent, Prop_Send, "m_nGlowRange", 0);
	SetEntProp(ent, Prop_Send, "m_nGlowRangeMin", 10);
	SetEntProp(ent, Prop_Send, "m_glowColorOverride", 255);
	

	SetEntPropFloat(ent, Prop_Send, "m_fadeMinDist", 10000.0); 
	SetEntPropFloat(ent, Prop_Send, "m_fadeMaxDist", 20000.0); 	
	return ent;
}
FireBullet(client, Float:pos[3], Float:angle[3], Float:hitpos[3])
{
	new Handle:trace= TR_TraceRayFilterEx(pos, angle, MASK_SHOT, RayType_Infinite, TraceRayDontHitSelfAndSurvivor, client); 
	new ent=0;
	new bool:hit=false;
	new bool:alive=false;
	if(TR_DidHit(trace))
	{			
		 
		TR_GetEndPosition(hitpos, trace);
		ent=TR_GetEntityIndex(trace);
		hit=true;
		if(ent>0)
		{			
			decl String:classname[64];
			GetEdictClassname(ent, classname, 64);	
			
			if(ent >=1 && ent<=MaxClients)
			{
				if(GetClientTeam(ent)==2) {}
				alive=true;
			}
			if(StrContains(classname, "ladder")!=-1){ent=0;}
			else if(StrContains(classname, "door")!=-1){  }
			else if(StrContains(classname, "infected")!=-1){ alive=true;} 			
		} 
	}
	CloseHandle(trace); 
	if(ent>0)
	{
		DoPointHurtForInfected(ent, client);
	}
	if(alive)
	{		
		decl Float:Direction[3];
		GetAngleVectors(angle, Direction, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(Direction, -1.0);
		GetVectorAngles(Direction,Direction);
		ShowParticle(hitpos, Direction, PARTICLE_BLOOD, 0.1);
	}	
	else if(hit)
	{
		decl Float:Direction[3];
		Direction[0] = GetRandomFloat(-1.0, 1.0);
		Direction[1] = GetRandomFloat(-1.0, 1.0);
		Direction[2] = GetRandomFloat(-1.0, 1.0);
		TE_SetupSparks(hitpos,Direction,1,3);
		TE_SendToAll();
	}
	return ent;
}

HitCheck(client, Float:f18pos[3],  Float:velocity[3],Float:temp[3])
{
	CopyVector(velocity, temp);
	NormalizeVector(temp, temp);
}
ProcessPitchRoll(client, Float:roll, Float:pitch, Float:yaw, Float:intervual, &Float:droll,  &Float:dpitch, &Float:dyaw, Float:oldangle[3], Float:newangle[3])
{	
	new Float:roolSpeed2=2.0;
	new Float:roolSpeed=180.0;
	if(roll!=0.0)
	{		 
		if(RollSpeed[client]*roll>0.0)RollSpeed[client]+=roolSpeed2*roll*intervual;
		else RollSpeed[client]+=3.0*roolSpeed2*roll*intervual;
	}
	else
	{		
		if(RollSpeed[client]>0.0)
		{
			RollSpeed[client]-=roolSpeed2*intervual;
			if(RollSpeed[client]<0.0)RollSpeed[client]=0.0;
		}
		else if(RollSpeed[client]<0.0)
		{
			RollSpeed[client]+=roolSpeed2*intervual;
			if(RollSpeed[client]>0.0)RollSpeed[client]=0.0;
		}

	}
	if(RollSpeed[client]>1.0)RollSpeed[client]=1.0;
	if(RollSpeed[client]<-1.0)RollSpeed[client]=-1.0;
	Roll[client]+=roolSpeed*RollSpeed[client]*intervual;
	droll=roolSpeed*RollSpeed[client]*intervual;
	
	new Float:pitchSpeed2=2.0;
	new Float:pitchSpeed=180.0;
	
	if(pitch==0.0)
	{
		if(ViewMode[client]!=ViewMode_None && FirstPersonMode[client]==1)
		{
			new Float:f=oldangle[0]-newangle[0];
			if(f==0.0)pitch=0.0;
			else if(f>0.0)pitch=1.0;
			else pitch=-1.0;			 
			PitchSpeed[client]+=FloatAbs(f)*1.5*pitch*intervual;
		}
 	}		
	else 
	{
		//PrintToChatAll("%d", RollSpeed[client]*pitch>0.0);
		if(PitchSpeed[client]*pitch>0.0)PitchSpeed[client]+=pitchSpeed2*pitch*intervual;
		else PitchSpeed[client]+=3.0*pitchSpeed2*pitch*intervual;
	}
	if(pitch==0.0)
	{		
		if(PitchSpeed[client]>0.0)
		{
			PitchSpeed[client]-=pitchSpeed2*intervual;
			if(PitchSpeed[client]<0.0)PitchSpeed[client]=0.0;
		}
		else if(PitchSpeed[client]<0.0)
		{
			PitchSpeed[client]+=pitchSpeed2*intervual;
			if(PitchSpeed[client]>0.0)PitchSpeed[client]=0.0;
		}
	}
	if(PitchSpeed[client]>1.0)PitchSpeed[client]=1.0;
	if(PitchSpeed[client]<-1.0)PitchSpeed[client]=-1.0;
	Pitch[client]+=pitchSpeed*PitchSpeed[client]*intervual;
	dpitch=pitchSpeed*PitchSpeed[client]*intervual;	
	
	new Float:yawSpeed2=2.0;
	new Float:yawSpeed=180.0;
	
	if(yaw==0.0)
	{
		if(ViewMode[client]!=ViewMode_None && FirstPersonMode[client]==1)
		{
			new Float:f=newangle[1]-oldangle[1];
			if(f==0.0)yaw=0.0;
			else if(f>0.0)yaw=1.0;
			else yaw=-1.0;
			f=FloatAbs(f);
			if(f>10.0)f=10.0;
			YawSpeed[client]+=yawSpeed2*  f *yaw*intervual;
		}
 	}		
	else 
	{
		//PrintToChatAll("%d", RollSpeed[client]*pitch>0.0);
		if(YawSpeed[client]*pitch>0.0)YawSpeed[client]+=yawSpeed2*yaw*intervual;
		else YawSpeed[client]+=3.0*yawSpeed2*yaw*intervual;
	}
	if(yaw==0.0)
	{		
		if(YawSpeed[client]>0.0)
		{
			YawSpeed[client]-=yawSpeed*intervual;
			if(YawSpeed[client]<0.0)YawSpeed[client]=0.0;
		}
		else if(YawSpeed[client]<0.0)
		{
			YawSpeed[client]+=yawSpeed*intervual;
			if(YawSpeed[client]>0.0)YawSpeed[client]=0.0;
		}
	}
	if(YawSpeed[client]>1.0)YawSpeed[client]=1.0;
	if(YawSpeed[client]<-1.0)YawSpeed[client]=-1.0;
	Yaw[client]+=yawSpeed*YawSpeed[client]*intervual;
	dyaw=yawSpeed*YawSpeed[client]*intervual;	

}
ProcessModelPitchRoll(client, Float:roll, Float:pitch, Float:yaw, Float:intervual,Float:oldangle[3], Float:newangle[3])
{
	new Float:roolSpeed=100.0;
	ModelRoll[client]+=roolSpeed*roll*intervual;
	if(ModelRoll[client]>20.0)ModelRoll[client]=20.0;
	if(ModelRoll[client]<-20.0)ModelRoll[client]=-20.0;
	if(roll==0.0)
	{		
		if(ModelRoll[client]>0.0)
		{
			ModelRoll[client]-=roolSpeed*intervual;
			if(ModelRoll[client]<0.0)ModelRoll[client]=0.0;
		}
		else if(ModelRoll[client]<0.0)
		{
			ModelRoll[client]+=roolSpeed*intervual;
			if(ModelRoll[client]>0.0)ModelRoll[client]=0.0;
		}
	}
	
	pitch=0.0-pitch;
	new Float:pitchSpeed=30.0;
	if(pitch==0.0)
	{
		if(ViewMode[client]!=ViewMode_None && FirstPersonMode[client]==1)
		{
			new Float:f=newangle[0]-oldangle[0];			 
			if(f==0.0)pitch=0.0;
			else if(f>0.0)pitch=1.0;
			else pitch=-1.0;
			if(pitch!=0.0)	PitchSpeed[client]+=FloatAbs( f)*pitch*intervual;			
			ModelPitch[client]+=0.5*pitchSpeed*FloatAbs(f)*pitch*intervual;
		
		}
	}
	else 
	{
		ModelPitch[client]+=pitchSpeed*pitch*intervual;

	}
	if(ModelPitch[client]>15.0)ModelPitch[client]=15.0;
	if(ModelPitch[client]<-25.0)ModelPitch[client]=-25.0;
	if(pitch==0.0)
	{		
		if(ModelPitch[client]>0.0)
		{
			ModelPitch[client]-=pitchSpeed*intervual;
			if(ModelPitch[client]<0.0)ModelPitch[client]=0.0;
		}
		else if(ModelPitch[client]<0.0)
		{
			ModelPitch[client]+=pitchSpeed*intervual;
			if(ModelPitch[client]>0.0)ModelPitch[client]=0.0;
		}
	}	
	
	new Float:yawSpeed=30.0;
	if(yaw==0.0)
	{
		if(ViewMode[client]!=ViewMode_None && FirstPersonMode[client]==1)
		{
			new Float:f=oldangle[1]-oldangle[1];
			if(f==0.0)yaw=0.0;
			else if(f>0.0)yaw=1.0;
			else yaw=-1.0;
			f=FloatAbs( f);
			if(f>10.0)f=10.0;
			ModelYaw[client]+=0.1*yawSpeed*f*yaw*intervual; 
		}
 	}
	else
	{
		ModelYaw[client]+=yawSpeed*yaw*intervual;
	}
	if(ModelYaw[client]>15.0)ModelYaw[client]=15.0;
	if(ModelYaw[client]<-15.0)ModelYaw[client]=-15.0;
	if(yaw==0.0)
	{		
		if(ModelYaw[client]>0.0)
		{
			ModelYaw[client]-=yawSpeed*intervual;
			if(ModelYaw[client]<0.0)ModelYaw[client]=0.0;
		}
		else if(ModelYaw[client]<0.0)
		{
			ModelYaw[client]+=yawSpeed*intervual;
			if(ModelYaw[client]>0.0)ModelYaw[client]=0.0;
		}
	}	
 
}
ProcessViewMode(client, button)
{
	if((button & IN_ZOOM) && !(LastButton[client] & IN_ZOOM))
	{ 
		ViewMode[client]++;
		if(ViewMode[client]>ViewMode_FellowF18)ViewMode[client]=ViewMode_None;
		if(ViewMode[client]==ViewMode_None)
		{	
			SetClientViewEntity(client, client); 
			SetEntityMoveType(client, MOVETYPE_WALK);
			PrintHintText(client, "Mode 1, Normal view");
		}
		else if(ViewMode[client]==ViewMode_FellowF18)
		{
			SetClientViewEntity(client, F18Camera[client]); 
			SetEntityMoveType(client, MOVETYPE_WALK);
			PrintHintText(client, "Mode 2, Plane view");
		}
		else if(ViewMode[client]==ViewMode_Teleport)
		{
			SetClientViewEntity(client, F18Camera[client]); 
			SetEntityMoveType(client, MOVETYPE_NOCLIP);
			PrintHintText(client, "Mode 3, You are inside the plane");
		}
	}
	if((button & IN_RELOAD) && !(LastButton[client] & IN_RELOAD))
	{ 
		
		if(FirstPersonMode[client]==0)
		{
			FirstPersonMode[client]=1;
			GotoFirstPerson(client);
			PrintHintText(client, "First Person Mode - keyboard control");
			if(ViewMode[client]==ViewMode_FellowF18)
			{
				SetClientViewEntity(client, F18Camera[client]);
			}
			else if(ViewMode[client]==ViewMode_Teleport)
			{
				SetClientViewEntity(client, F18Camera[client]); 
			}
		}
		else
		{
			FirstPersonMode[client]=0;
			GotoThirdPerson(client);
			PrintHintText(client, "Third Person Mode - mouse control");
			if(ViewMode[client]==ViewMode_FellowF18)
			{
				SetClientViewEntity(client, F18Ent[client]);
			}
			else if(ViewMode[client]==ViewMode_Teleport)
			{
				SetClientViewEntity(client, F18Ent[client]); 
			}
		}
	}
	new flag=GetEntityFlags(client);  //FL_ONGROUND	
	if(flag & FL_ONGROUND)  
	{
		if(ViewMode[client]!=ViewMode_Teleport)
		{
			SetEntityMoveType(client, MOVETYPE_NONE);
		}
	}
}
ProcessSound(client)
{
	new Float:v=F18Speed[client]-F18MinSpeed;
	v=v/(F18MaxSpeed-F18MinSpeed);
	v=v*10.0;
	new volume=RoundFloat(v)+1;
	if(volume!=F18SoundVolume[client])
	{
		SetSound(client, F18SoundVolume[client]*0.05+0.5);
		F18SoundVolume[client]=volume;
	}
}
CreateF18(client)
{

	decl Float:pos[3];
	decl Float:angle[3];
	decl Float:vol[3];
	GetClientEyePosition(client, pos);
	GetClientEyeAngles(client, angle);
	CopyVector(angle,ClientAngle[client]);
	new ent = 0;
 
 
	ent = CreateEntityByName("pipe_bomb_projectile");	 
	SetEntityModel(ent, MODEL_W_PIPEBOMB); 

	//SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client)	;	
	DispatchSpawn(ent);  
	
	GetAngleVectors(angle, vol, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(vol, F18MinSpeed);
	TeleportEntity(ent, pos, angle, vol);
	CopyVector(vol,F18FrontDir[client]);
	ActivateEntity(ent);  
	SetEntityGravity(ent, 0.01); 
	SetEntityMoveType(ent, MOVETYPE_FLY);   
	SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
	SetEntityRenderColor(ent, 0, 0, 0, 0);
	CopyVector(pos, F18LastPos[client]);
	
	new ment=CreateEntityByName("prop_dynamic");
 
	new String:tname[20];
	Format(tname, 20, "missile%d", ent);
	DispatchKeyValue(ent, "targetname", tname); 		
	DispatchKeyValue(ment, "parentname", tname);
	DispatchKeyValue(ment, "model", MODEL_F18); 
	DispatchSpawn(ment);  
	SetVector(angle, 0.0, 0.0, 0.0);
	TeleportEntity(ment, pos, angle, NULL_VECTOR);
	SetVariantString(tname);
	AcceptEntityInput(ment, "SetParent",ment, ment, 0); 
 
	SetEntProp(ent, Prop_Data, "m_takedamage", 0, 1);
	SetEntProp(ment, Prop_Data, "m_takedamage", 0, 1);  
	SetEntityMoveType(ment, MOVETYPE_NOCLIP);   
	F18ModelEnt[client]=ment;
	
	AttachFlame(client, ent, F18Flame[client]);
	SetEntPropFloat(ment, Prop_Send,"m_flModelScale", GetModelScale());
	
	SetEntProp(ment, Prop_Send, "m_iGlowType", 3);
	SetEntProp(ment, Prop_Send, "m_nGlowRange", 0);
	SetEntProp(ment, Prop_Send, "m_nGlowRangeMin", 700);
	new red=0;
	new gree=151;
	new blue=0;
	SetEntProp(ment, Prop_Send, "m_glowColorOverride", red + (gree * 256) + (blue* 65536));
	

	SetEntPropFloat(ment, Prop_Send, "m_fadeMinDist", 10000.0); 
	SetEntPropFloat(ment, Prop_Send, "m_fadeMaxDist", 20000.0); 	
	return ent;
}
AttachFlame( client, ent, flames[ ] )
{
	client=client+0;
	decl String:flame_name[128];
	Format(flame_name, sizeof(flame_name), "missile%d", ent);
	new flame = CreateEntityByName("env_steam");
	DispatchKeyValue( ent,"targetname", flame_name);
	DispatchKeyValue(flame,"parentname", flame_name);
	DispatchKeyValue(flame,"SpawnFlags", "1");
	DispatchKeyValue(flame,"Type", "0");
 
	DispatchKeyValue(flame,"InitialState", "1");
	DispatchKeyValue(flame,"Spreadspeed", "1");
	DispatchKeyValue(flame,"Speed", "250");
	DispatchKeyValue(flame,"Startsize", "1");
	DispatchKeyValue(flame,"EndSize", "6");
	DispatchKeyValue(flame,"Rate", "555");
	DispatchKeyValue(flame,"RenderColor", "10 52 99"); 
	DispatchKeyValue(flame,"JetLength", "15"); 
	DispatchKeyValue(flame,"RenderAmt", "180");
	
	DispatchSpawn(flame);	 
	SetVariantString(flame_name);
	AcceptEntityInput(flame, "SetParent", flame, flame, 0);
	
	new Float:origin[3];
	SetVector(origin,  -5.0*GetModelScale(),1.3*GetModelScale(),  -1.0);
	decl Float:ang[3];
	SetVector(ang, 180.0, 0.0, 0.0); 
	TeleportEntity(flame, origin, ang,NULL_VECTOR);	
	AcceptEntityInput(flame, "TurnOff");
	
 
	new flame2 = CreateEntityByName("env_steam");
	DispatchKeyValue( ent,"targetname", flame_name);
	DispatchKeyValue(flame2,"parentname", flame_name);
	DispatchKeyValue(flame2,"SpawnFlags", "1");
	DispatchKeyValue(flame2,"Type", "0");
 
	DispatchKeyValue(flame2,"InitialState", "1");
	DispatchKeyValue(flame2,"Spreadspeed", "1");
	DispatchKeyValue(flame2,"Speed", "250");
	DispatchKeyValue(flame2,"Startsize", "1");
	DispatchKeyValue(flame2,"EndSize", "6");
	DispatchKeyValue(flame2,"Rate", "555");
	DispatchKeyValue(flame2,"RenderColor", "10 52 99"); 
	DispatchKeyValue(flame2,"JetLength", "15"); 
	DispatchKeyValue(flame2,"RenderAmt", "180");
	
	SetVector(origin,  -5.0*GetModelScale(),-1.3*GetModelScale(),  -1.0);
	DispatchSpawn(flame2);	 
	SetVariantString(flame_name);
	AcceptEntityInput(flame2, "SetParent", flame2, flame2, 0);
	TeleportEntity(flame2, origin, ang,NULL_VECTOR);
	AcceptEntityInput(flame2, "TurnOff"); 
	flames[0]=flame;
	flames[1]=flame2; 
}
//code from "DJ_WEST"
CreateCamera(i_Witch ,client)
{
	decl i_Camera, Float:f_Origin[3], Float:f_Angles[3], Float:f_Forward[3], String:s_TargetName[32];
	
	GetEntPropVector(i_Witch, Prop_Send, "m_vecOrigin", f_Origin);
	GetEntPropVector(i_Witch, Prop_Send, "m_angRotation", f_Angles);
	
	i_Camera = CreateEntityByName("prop_dynamic_override");
	if (IsValidEdict(i_Camera))
	{
		GetAngleVectors(f_Angles, f_Forward, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(f_Forward, f_Forward);
		ScaleVector(f_Forward, -25.0*GetModelScale()); //-25
		AddVectors(f_Forward, f_Origin, f_Origin);
		f_Origin[2] += 6.0*GetModelScale(); //6.0
		FormatEx(s_TargetName, sizeof(s_TargetName), "camera%d", i_Witch);
		DispatchKeyValue(i_Camera, "model", MODEL_W_PIPEBOMB);
		DispatchKeyValue(i_Witch, "targetname", s_TargetName);
		DispatchKeyValueVector(i_Camera, "origin", f_Origin);
		//f_Angles[0] = 45.0;
		//f_Angles[1] = -0.0;
		//f_Angles[2] = 0.0;
		GetClientEyeAngles(client, f_Angles);
		DispatchKeyValueVector(i_Camera, "angles", f_Angles);
		DispatchKeyValue(i_Camera, "parentname", s_TargetName);
		DispatchSpawn(i_Camera);
		SetVariantString(s_TargetName);
		AcceptEntityInput(i_Camera, "SetParent");
		AcceptEntityInput(i_Camera, "DisableShadow");
		ActivateEntity(i_Camera);
		SetEntityRenderMode(i_Camera, RENDER_TRANSCOLOR);
		SetEntityRenderColor(i_Camera, 0, 0, 0, 0);
		SetEntityMoveType(i_Camera, MOVETYPE_NOCLIP);   
		return i_Camera;
	}
	
	return 0;
}
bool:IsVilidPlayer(client)
{
	if(client>0 && IsClientInGame(client) && IsPlayerAlive(client))return true;
	else return false;
}

new g_ShotThroughWall=2;
public bool:TraceRayDontHitSelfAndF18(entity, mask, any:data)
{
	if(entity == data) 
	{
		return false; 
	}
	else if(data>=1 && data<=MaxClients)
	{
		if(State[data]!=State_None)
		{
			if(entity==F18Ent[data])return false;
			if(entity==F18ModelEnt[data])return false;
		}
	}
	return true;
}
public bool:TraceRayDontHitSelfAndSurvivor(entity, mask, any:data)
{
	if(entity == data) 
	{
		return false; 
	}
	if(entity>=1 && entity<=MaxClients)
	{
		if(GetClientTeam(entity)==2)
		{
			return false;
		}
	}
	if(data>=1 && data<=MaxClients)
	{
		if(State[data]!=State_None)
		{
			if(entity==F18Ent[data])return false;
			if(entity==F18ModelEnt[data])return false;
		}
	}
	return true;
}
PrintVector(String:s[], Float:target[3])
{
	PrintToChatAll("%s - %f %f %f", s, target[0], target[1], target[2]); 
}
CopyVector(Float:source[3], Float:target[3])
{
	target[0]=source[0];
	target[1]=source[1];
	target[2]=source[2];
}
SetVector(Float:target[3], Float:x, Float:y, Float:z)
{
	target[0]=x;
	target[1]=y;
	target[2]=z;
}
public bool:DontHitSelf(entity, mask, any:data)
{
	if(entity == data) 
	{
		return false; 
	}
	return true;
}
//draw line between pos1 and pos2
ShowLaser(colortype,Float:pos1[3], Float:pos2[3], Float:life=10.0,  Float:width1=1.0, Float:width2=11.0)
{
	decl color[4];
	if(colortype==1)
	{
		color[0] = 200; 
		color[1] = 0;
		color[2] = 0;
		color[3] = 230; 
	}
	else if(colortype==2)
	{
		color[0] = 0; 
		color[1] = 200;
		color[2] = 0;
		color[3] = 230; 
	}
	else if(colortype==3)
	{
		color[0] = 0; 
		color[1] = 0;
		color[2] = 200;
		color[3] = 230; 
	}
	else 
	{
		color[0] = 200; 
		color[1] = 200;
		color[2] = 200;
		color[3] = 230; 		
	}

	
	TE_SetupBeamPoints(pos1, pos2, g_sprite, 0, 0, 0, life, width1, width2, 1, 0.0, color, 0);
	TE_SendToAll();
}
//draw line between pos1 and pos2
ShowPos(color, Float:pos1[3], Float:pos2[3],Float:life=10.0, Float:length=200.0, Float:width1=1.0, Float:width2=4.0)
{
	decl Float:t[3];
	if(length!=0.0)
	{
		SubtractVectors(pos2, pos1, t);	 
		NormalizeVector(t,t);
		ScaleVector(t, length);
		AddVectors(pos1, t,t);
	}
	else 
	{
		CopyVector(pos2,t);
	}
	ShowLaser(color,pos1, t, life,   width1, width2);
}
//draw line start from pos, the line's drection is dir.
ShowDir(color,Float:pos[3], Float:dir[3],Float:life=10.0, Float:length=200.0, Float:width1=1.0, Float:width2=4.0)
{
	decl Float:pos2[3];
	CopyVector(dir, pos2);
	NormalizeVector(pos2,pos2);
	ScaleVector(pos2, length);
	AddVectors(pos, pos2,pos2);
	ShowLaser(color,pos, pos2, life,   width1, width2);
}
//draw line start from pos, the line's angle is angle.
ShowAngle(color,Float:pos[3], Float:angle[3],Float:life=10.0, Float:length=200.0, Float:width1=1.0, Float:width2=4.0)
{
	decl Float:pos2[3];
	GetAngleVectors(angle, pos2, NULL_VECTOR, NULL_VECTOR);
 
	NormalizeVector(pos2,pos2);
	ScaleVector(pos2, length);
	AddVectors(pos, pos2,pos2);
	ShowLaser(color,pos, pos2, life, width1, width2);
}
Float:AngleCovert(Float:angle)
{
	return angle/180.0*Pai;
}
/* 
* angle between x1 and x2
*/
Float:GetAngle(Float:x1[3], Float:x2[3])
{
	return ArcCosine(GetVectorDotProduct(x1, x2)/(GetVectorLength(x1)*GetVectorLength(x2)));
}
/* 
* Signed angle  between x1 and x2
*/
Float:GetAngleWithSign(Float:n[3], Float:v1[3], Float:v2[3] )
{
	decl Float:t[3];
	GetVectorCrossProduct(v1, n, t);
	NormalizeVector(t, t);
	new Float:s=GetAngle(t, v2);
	new Float:r=0.0;
	if(s<Pai/2.0)
	{
		r=GetAngle(v1, v2);
	}
	else
	{
		r=0.0-GetAngle(v1, v2);
	}
	return r;
}
/* 
* get vector t's projection on a plane, the plane's normal vector is n, r is the result
*/
GetProjection(Float:n[3], Float:t[3], Float:r[3])
{
	new Float:A=n[0];
	new Float:B=n[1];
	new Float:C=n[2];
	
	new Float:a=t[0];
	new Float:b=t[1];
	new Float:c=t[2];
	
	new Float:tt=(A*A+B*B+C*C);
	if(tt!=0.0)
	{
		new Float:p=-1.0*(A*a+B*b+C*c)/tt;
		r[0]=A*p+a;
		r[1]=B*p+b;
		r[2]=C*p+c; 
	}
	//AddVectors(p, r, r);
}
/* 
* rotate vector vec around vector direction alfa degrees
*/
RotateVector(Float:direction[3], Float:vec[3], Float:alfa, Float:result[3])
{
  /*
   on rotateVector (v, u, alfa)
  -- rotates vector v around u alfa degrees
  -- returns rotated vector 
  -----------------------------------------
  u.normalize()
  alfa = alfa*pi()/180 -- alfa in rads
  uv = u.cross(v)
  vect = v + sin (alfa) * uv + 2*power(sin(alfa/2), 2) * (u.cross(uv))
  return vect
	end
   */
   	decl Float:v[3];
	CopyVector(vec,v);
	
	decl Float:u[3];
	CopyVector(direction,u);
	NormalizeVector(u,u);
	
	decl Float:uv[3];
	GetVectorCrossProduct(u,v,uv);
	
	decl Float:sinuv[3];
	CopyVector(uv, sinuv);
	ScaleVector(sinuv, Sine(alfa));
	
	decl Float:uuv[3];
	GetVectorCrossProduct(u,uv,uuv);
	ScaleVector(uuv, 2.0*Pow(Sine(alfa*0.5), 2.0));	
	
	AddVectors(v, sinuv, result);
	AddVectors(result, uuv, result);
	
 
} 
GameCheck()
{
	decl String:GameName[16];
	GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));
	
	
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
		ZOMBIECLASS_TANK=8;
		L4D2Version=true;
	}	
	else
	{
		ZOMBIECLASS_TANK=5;
		L4D2Version=false;
	}
 
}
public OnMapStart()
{
 
	if(L4D2Version)
	{
		g_sprite = PrecacheModel("materials/sprites/laserbeam.vmt");	
		PrecacheModel(MODEL_W_PIPEBOMB);
		PrecacheModel(MODEL_F18);
		PrecacheModel(MODEL_F182);
		PrecacheModel(MODEL_MISSILE);
		PrecacheSound(SOUND_FLAME, true);
		PrecacheSound(SOUND_SHOT, true);	
		PrecacheSound(SOUND_BOMBEXPLODE, true);
		PrecacheSound(SOUND_BOMBDROP, true);
		PrecacheParticle(PARTICLE_BOMBEXPLODE);
		PrecacheParticle(PARTICLE_WEAPON_TRACER);
		PrecacheParticle(PARTICLE_MUZZLE_FLASH);
		PrecacheParticle(PARTICLE_BLOOD);
		PrecacheParticle(PARTICLE_IMPACT);
	}
	else
	{
		g_sprite = PrecacheModel("materials/sprites/laser.vmt");	
		 
	}

}
 
 

public PrecacheParticle(String:particlename[])
{
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(0.01, DeleteParticles, particle, TIMER_FLAG_NO_MAPCHANGE);
	} 
}
public Action:DeleteParticles(Handle:timer, any:particle)
{
	 if (IsValidEntity(particle))
	 {
		 decl String:classname[64];
		 GetEdictClassname(particle, classname, sizeof(classname));
		 if (StrEqual(classname, "info_particle_system", false))
			{
				AcceptEntityInput(particle, "stop");
				AcceptEntityInput(particle, "kill");
				RemoveEdict(particle);
				 
			}
	 }
}
public Action:DeleteParticletargets(Handle:timer, any:target)
{
	 if (IsValidEntity(target))
	 {
		 decl String:classname[64];
		 GetEdictClassname(target, classname, sizeof(classname));
		 if (StrEqual(classname, "info_particle_target", false))
			{
				AcceptEntityInput(target, "stop");
				AcceptEntityInput(target, "kill");
				RemoveEdict(target);
				 
			}
	 }
}
public ShowParticle(Float:pos[3], Float:ang[3],String:particlename[], Float:time)
{
 new particle = CreateEntityByName("info_particle_system");
 if (IsValidEdict(particle))
 {
		
		DispatchKeyValue(particle, "effect_name", particlename); 
		DispatchSpawn(particle);
		ActivateEntity(particle);
		
		
		TeleportEntity(particle, pos, ang, NULL_VECTOR);
		AcceptEntityInput(particle, "start");		
		CreateTimer(time, DeleteParticles, particle, TIMER_FLAG_NO_MAPCHANGE);
		return particle;
 }  
 return 0;
}
public Action:DeletePushForce(Handle:timer, any:ent)
{
	 if (ent> 0 && IsValidEntity(ent) && IsValidEdict(ent))
	 {
		 decl String:classname[64];
		 GetEdictClassname(ent, classname, sizeof(classname));
		 if (StrEqual(classname, "point_push", false))
				{
 					AcceptEntityInput(ent, "Disable");
					AcceptEntityInput(ent, "Kill"); 
					RemoveEdict(ent);
				}
	 }
}
public Action:DeletePointHurt(Handle:timer, any:ent)
{
	 if (ent> 0 && IsValidEntity(ent) && IsValidEdict(ent))
	 {
		 decl String:classname[64];
		 GetEdictClassname(ent, classname, sizeof(classname));
		 if (StrEqual(classname, "point_hurt", false))
				{
					AcceptEntityInput(ent, "Kill"); 
					RemoveEdict(ent);
				}
		 }

}
ShowMuzzleFlash(client, Float:pos[3],  Float:angle[3], index)
{  
 	new particle = CreateEntityByName("info_particle_system");
	DispatchKeyValue(particle, "effect_name", PARTICLE_MUZZLE_FLASH); 
	DispatchSpawn(particle);
	ActivateEntity(particle); 
	TeleportEntity(particle, pos, angle, NULL_VECTOR);
	AcceptEntityInput(particle, "start");	
	CreateTimer(0.01, DeleteParticles, particle, TIMER_FLAG_NO_MAPCHANGE);
	
}
ShowTrack(client, Float:pos[3], Float:endpos[3] )
{  
 	decl String:temp[16]="";		
	new target = CreateEntityByName("info_particle_target");
	Format(temp, 64, "cptarget%d", target);
	DispatchKeyValue(target, "targetname", temp);	
	TeleportEntity(target, endpos, NULL_VECTOR, NULL_VECTOR); 
	ActivateEntity(target); 
	
	new particle = CreateEntityByName("info_particle_system");
	DispatchKeyValue(particle, "effect_name", PARTICLE_WEAPON_TRACER);
	DispatchKeyValue(particle, "cpoint1", temp);
	DispatchSpawn(particle);
	ActivateEntity(particle); 
	TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(particle, "start");	
	CreateTimer(0.01, DeleteParticletargets, target, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.01, DeleteParticles, particle, TIMER_FLAG_NO_MAPCHANGE);
}
CreatePointHurt()
{
	new pointHurt=CreateEntityByName("point_hurt");
	if(pointHurt)
	{

		DispatchKeyValue(pointHurt,"Damage","10");
		DispatchKeyValue(pointHurt,"DamageType","2");
		DispatchSpawn(pointHurt);
	}
	return pointHurt;
}
new String:N[10];
DoPointHurtForInfected(victim, attacker=0)
{
	if(g_PointHurt > 0)
	{
		if(IsValidEdict(g_PointHurt))
		{
			if(victim>0 && IsValidEdict(victim))
			{		
				Format(N, 20, "target%d", victim);
				DispatchKeyValue(victim,"targetname", N);
				DispatchKeyValue(g_PointHurt,"DamageTarget", N);
				//DispatchKeyValue(g_PointHurt,"classname","");
				DispatchKeyValueFloat(g_PointHurt,"Damage", GetConVarFloat(l4d_uav_gundamage));
				DispatchKeyValue(g_PointHurt,"DamageType","-2130706430");
				AcceptEntityInput(g_PointHurt,"Hurt",(attacker>0)?attacker:-1);
			}
		}
		else g_PointHurt=CreatePointHurt();
	}
	else g_PointHurt=CreatePointHurt();
}
 
GotoThirdPerson(client)
{
	ClientCommand(client, "thirdpersonshoulder");
	ClientCommand(client, "c_thirdpersonshoulderoffset 0");
	ClientCommand(client, "c_thirdpersonshoulderaimdist 720");
	if(GetModelScale()<=1.5)ClientCommand(client, "c_thirdpersonshoulderheight  13");
	else if(GetModelScale()<=2.5)ClientCommand(client, "c_thirdpersonshoulderheight  25");
	else if(GetModelScale()<=3.5)ClientCommand(client, "c_thirdpersonshoulderheight  30");
	else if(GetModelScale()<=5.5)ClientCommand(client, "c_thirdpersonshoulderheight  45");
	
	ClientCommand(client, "cam_ideallag 0");
	if(GetModelScale()<=1.5)ClientCommand(client, "cam_idealdist 0");
	else if(GetModelScale()<=2.5)ClientCommand(client, "cam_idealdist 70");
	else if(GetModelScale()<=3.5)ClientCommand(client, "cam_idealdist 90");
	else if(GetModelScale()<=5.5)ClientCommand(client, "cam_idealdist 110");
}

GotoFirstPerson(client)
{
	ClientCommand(client, "thirdpersonshoulder");
	ClientCommand(client, "c_thirdpersonshoulder 0");
} 
Cheatcommand(client, String:cmd[])
{ 
	new flags = GetCommandFlags(cmd);	
	SetCommandFlags(cmd, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s", cmd );
	SetCommandFlags(cmd, flags); 
}