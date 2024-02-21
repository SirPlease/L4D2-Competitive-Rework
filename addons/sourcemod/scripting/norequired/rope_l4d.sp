#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <readyup>
#include <l4d2util_infected>
//#include <sdktools_functions>

#define Pai 3.14159265358979323846 
#define ZOMBIECLASS_SMOKER	1
#define ZOMBIECLASS_BOOMER	2
#define ZOMBIECLASS_HUNTER	3
#define ZOMBIECLASS_SPITTER	4
#define ZOMBIECLASS_JOCKEY	5
#define ZOMBIECLASS_CHARGER	6 

#define PARTICLE_BLOOD		"blood_impact_headshot_01"
#define SOUND_FIRE "player/smoker/miss/smoker_reeltonguein_01.wav"
 
#define MODEL_W_PIPEBOMB "models/w_models/weapons/w_eq_pipebomb.mdl"
#define particle_smoker_tongue "smoker_tongue"

new ZOMBIECLASS_TANK=	5;
new GameMode;
new L4D2Version;

#define state_none 0
#define state_shot 1

new bool:HaveAutoGun[MAXPLAYERS+1];
new bool:g_rope_enabled[MAXPLAYERS+1];

new g_rope_state[MAXPLAYERS+1];
new Float:g_rope_length[MAXPLAYERS+1];

new Float:g_last_time[MAXPLAYERS+1];
new bool:g_rope_target[MAXPLAYERS+1];
new bool:g_rope_free[MAXPLAYERS+1];
new g_rope_ent[MAXPLAYERS+1][3];
new Float:g_target_postion [MAXPLAYERS+1][3];

new g_last_button[MAXPLAYERS+1];
new Float:g_hurt_time [MAXPLAYERS+1];
new Float:g_jump_time [MAXPLAYERS+1];

new Handle:l4d_rope_count;
new Handle:l4d_rope_damage; 
new Handle:l4d_rope_distance ;
new Handle:l4d_rope_drop_from_witch ;
new Handle:l4d_rope_drop_from_tank ;
 

new g_PointHurt = 0;
new g_iVelocity = 0;
public Plugin:myinfo = 
{
	name = "rope",
	author = " pan xiao hai",
	description = " ",
	version = "1.0",
	url = "http://forums.alliedmods.net"
}
public OnPluginStart()
{ 	 
	GameCheck(); 	
	
	if(!L4D2Version)return;
	
	HookEvent("player_spawn", player_spawn);	
	HookEvent("player_death", player_death); 

	HookEvent("player_bot_replace", player_bot_replace );	  
	HookEvent("bot_player_replace", bot_player_replace );	
 

	HookEvent("round_start", round_end);
	HookEvent("round_end", round_end);
	HookEvent("finale_win", round_end);
	HookEvent("mission_lost", round_end);
	HookEvent("map_transition", round_end);	
	
	HookEvent("witch_killed", witch_killed ); 
	HookEvent("tank_killed", tank_killed );	
	
	
	RegConsoleCmd("sm_rope", sm_rope);
	
	g_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]");
	
 	//l4d_rope_count = CreateConVar("l4d_rope_count", "100", " count", FCVAR_PLUGIN);
	l4d_rope_damage = CreateConVar("l4d_rope_damage", "10", " damage", FCVAR_PLUGIN);
 	l4d_rope_distance = CreateConVar("l4d_rope_distance", "900.0", "range", FCVAR_PLUGIN);
 
	l4d_rope_drop_from_witch = CreateConVar("l4d_rope_drop_from_witch", "0.0", " ", FCVAR_PLUGIN);
 	l4d_rope_drop_from_tank = CreateConVar("l4d_rope_drop_from_tank", "0.0", "", FCVAR_PLUGIN);
	
	AutoExecConfig(true, "rope_l4d");  
}
public OnMapStart()
{
	ResetAllState();
	
	PrecacheModel(MODEL_W_PIPEBOMB);
	PrecacheSound(SOUND_FIRE); 
	
	PrecacheParticle(PARTICLE_BLOOD);

		
	PrecacheParticle(particle_smoker_tongue);

 
} 

public Action:round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	ResetAllState();
}
 
public Action:round_end(Handle:event, const String:name[], bool:dontBroadcast)
{  
	ResetAllState();
} 
ResetAllState( )
{	
	g_PointHurt=0; 
	for(new i=1; i<=MaxClients; i++)
	{
		ResetClientState(i); 
	}
} 
ResetClientState(client)
{
	g_rope_enabled[client]=false;
	g_rope_state[client]=state_none;
	g_rope_ent[client][0]=0;
	g_rope_ent[client][1]=0;
	g_rope_ent[client][2]=0;
}

public void OnRoundLiveCountdownPre(){
	for(int i=1; i<MaxClients; i++){
		if (IsClientInGame(i)) StopRope(i);
	}
	ResetAllState();
}

public void OnRoundIsLivePre(){
	OnRoundLiveCountdownPre();
}

public Action:sm_rope(client,args)
{
	if (!IsInReady()){
		AdminId id = GetUserAdmin(client);
		if (!GetAdminFlag(id, Admin_Generic)) {
			PrintToChat(client, "游戏已经开始了!");
			return Plugin_Handled;
		}
	}
	if(client>0 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		if (IsInfectedGhost(client)) {
			PrintToChat(client, "你不能在灵魂状态使用绳子");
			return Plugin_Handled;
		}
		if(g_rope_enabled[client])
		{
			DisableRope(client); 
		}
		else
		{
			EnableRope(client);
		}
	}
}
GiveRope(client)
{
	if(!g_rope_enabled[client])
	{
		EnableRope(client); 
	}
}

public Action:witch_killed(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{ 
	new witchid = GetEventInt(h_Event, "witchid");
	new attacker = GetClientOfUserId(GetEventInt(h_Event, "userid"));	
	if(witchid>0 && attacker>0)
	{
		if(GetRandomFloat(0.0, 100.0)<GetConVarFloat(l4d_rope_drop_from_witch))
		{
			PrintToChatAll("Give %N a rope for killing witch", attacker);
			GiveRope(attacker);
		}
	}
	return Plugin_Handled;
}
public Action:tank_killed(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{ 
	new victim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	if(victim>0 && attacker>0)
	{
		if(GetRandomFloat(0.0, 100.0)<GetConVarFloat(l4d_rope_drop_from_tank))
		{
			PrintToChatAll("Give %N a rope for killing tank", attacker);
			GiveRope(attacker);
		}
	} 
}

public player_bot_replace(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(Spawn_Event, "player"));
	new bot = GetClientOfUserId(GetEventInt(Spawn_Event, "bot"));   
	if(g_rope_enabled[client])
	{
		DisableRope(client);
	}
	ResetClientState(client);
	ResetClientState(bot);

}
public bot_player_replace(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(Spawn_Event, "player"));
	new bot = GetClientOfUserId(GetEventInt(Spawn_Event, "bot"));  
	if(g_rope_enabled[client])
	{
		DisableRope(client);
	}
	ResetClientState(client);
	ResetClientState(bot);
  
}
public Action:player_spawn(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));  
	ResetClientState(client);
	 	
}
 

public Action:player_death(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{

	new dead_player = GetClientOfUserId(GetEventInt(hEvent, "userid")); 
	
	if(dead_player>0)
	{
		if(g_rope_enabled[dead_player])
		{
			DisableRope(dead_player);
		}
	
	} 

	if(dead_player>0)
	{
		for(new i=1; i<=MaxClients; i++)
		{
			if(g_rope_enabled[i] && g_rope_target[i]==dead_player)
			{
				g_rope_target[i]=0;
				StopRope(i);
			}
		}
		
	} 

}


public Action:player_hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new  attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new  victim = GetClientOfUserId(GetEventInt(event, "userid"));  
}

DisableRope(client)
{
	if(!g_rope_enabled[client])return;
	g_rope_enabled[client]=false;
	
	StopRope(client);
	PrintToChat(client, "you have disabled rope"); 
}
EnableRope(client)
{

	if(g_rope_enabled[client])return;
	g_rope_enabled[client]=true;
	g_rope_state[client]=state_none;
	
	PrintToChatAll("%N 启用了绳子",client);
	 
	PrintToChat(client, "你启用了绳子, 使用瞄准键来使用");
	PrintToChat(client, "在空中使用shift和ctrl来控制长度");


}

StartRope(client)
{
	if(g_rope_state[client]!=state_none)return;
	
	new Float:pos[3];
	new Float:angle[3];
	new Float:hitpos[3];
	GetClientEyePosition(client, pos);
	GetClientEyeAngles(client , angle);	
 
	new target=GetEnt(client, pos,angle, hitpos ); 
	if(GetVectorDistance(pos, hitpos)>GetConVarFloat(l4d_rope_distance))
	{
		PrintHintText(client, "It is too far");
		return;
	}
	g_rope_length[client]=GetVectorDistance(pos, hitpos);
	g_rope_free[client]=true;
		
	new ent1=g_rope_ent[client][0];
	new ent2=g_rope_ent[client][1];
	new ent3=g_rope_ent[client][2];

	if(IsEnt(ent1))
	{
		RemoveEdict(ent1);
		g_rope_ent[client][0]=0;
	}
	if(IsEnt(ent2))
	{
		RemoveEdict(ent2);
		g_rope_ent[client][1]=0;
	}
	if(IsEnt(ent3))
	{
		RemoveEdict(ent2);
		g_rope_ent[client][2]=0;
	}
	
	
	g_hurt_time[client]=GetEngineTime()-1.0;
	g_last_time[client]=GetEngineTime()-0.01;
	g_jump_time[client]=GetEngineTime()-0.5;
	
	g_rope_state[client]=state_shot; 
	CreateRope(client,target, pos, hitpos ,0  ); 
	CopyVector(hitpos,g_target_postion[client]);
	
	if(target>0 && target<=MaxClients)PrintHintText(client, "Rope Hooked %N", target);
	EmitSoundToAll(SOUND_FIRE, 0,  SNDCHAN_WEAPON, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, pos, NULL_VECTOR, true, 0.0);

	//PrintToChatAll("StartRope");
}
StopRope(client)
{
	if(g_rope_state[client]!=state_shot)return;
	g_rope_state[client]=state_none;
	
	
	new ent1=g_rope_ent[client][0];
	new ent2=g_rope_ent[client][1];
	
	new Float:pos[3];
	if(IsEnt(ent1))
	{
		AcceptEntityInput(ent1, "ClearParent");  
		//GetEntPropVector(ent1, Prop_Send, "m_vecOrigin", pos);		
		TeleportEntity(ent1, pos, pos, NULL_VECTOR);	
	}
	if(IsEnt(ent2))
	{
		AcceptEntityInput(ent2, "ClearParent");  
		TeleportEntity(ent2, pos, pos, NULL_VECTOR);	
	}	
	
	
	new particle=g_rope_ent[client][2];
	if(IsEnt(particle))
	{
		AcceptEntityInput(particle, "stop");  
	}
	
	g_rope_ent[client][0]=0;
	g_rope_ent[client][1]=0;
	g_rope_ent[client][2]=0;
	
	//SetEntityGravity(client, 1.0);

	//PrintToChatAll("StopRope");
}

CreateDummyEnt()
{
	new ent = CreateEntityByName("prop_dynamic_override");//	 pipe_bomb_projectile
	SetEntityModel(ent, MODEL_W_PIPEBOMB);	 // MODEL_W_PIPEBOMB
	DispatchSpawn(ent);  
	SetEntityMoveType(ent, MOVETYPE_NONE);   
	SetEntProp(ent, Prop_Send, "m_CollisionGroup", 2);   
	SetEntityRenderMode(ent, RenderMode:3);
	SetEntityRenderColor(ent, 0,0, 0,0);	
	return ent;
}

CreateRope(client, target, Float:pos[3], Float:endpos[3],  index=0)
{  

	
 	new Float:pos[3];
	new Float:angle[3];
	
	new dummy_target = CreateDummyEnt();
	new dummy_source = CreateDummyEnt();
	
	if(IsInfectedTeam(target) || IsSurvivorTeam(target))
	{
		
		SetVector(pos, 0.0, 0.0, 50.0);	
		AttachEnt(target, dummy_target, "", pos, angle);
		SetVector(pos, 0.0, 0.0, 0.0);	
		g_rope_target[client]=target;
	}
	else
	{	
		g_rope_target[client]=0;
		TeleportEntity(dummy_target, endpos, NULL_VECTOR, NULL_VECTOR);
	}
	
	SetVector(pos,   10.0,  0.0, 0.0); 
	AttachEnt(client, dummy_source, "armL", pos, angle);
	
	//TeleportEntity(dummy_source, pos, NULL_VECTOR, NULL_VECTOR);
		
	decl String:dummy_target_name[64];
	decl String:dummy_source_name[64];
	Format(dummy_target_name, sizeof(dummy_target_name), "target%d", dummy_target);
	Format(dummy_source_name, sizeof(dummy_source_name), "target%d", dummy_source);
	DispatchKeyValue(dummy_target, "targetname", dummy_target_name);
	DispatchKeyValue(dummy_source, "targetname", dummy_source_name);
	
	new particle = CreateEntityByName("info_particle_system");

	DispatchKeyValue(particle, "effect_name", particle_smoker_tongue);
	DispatchKeyValue(particle, "cpoint1", dummy_target_name);
	
	DispatchSpawn(particle);
	ActivateEntity(particle); 
	
	SetVector(pos, 0.0, 0.0, 0.0);	
	AttachEnt(dummy_source, particle, "", pos, angle);
	
	AcceptEntityInput(particle, "start");  
	
	g_rope_ent[client][0]=dummy_target;
	g_rope_ent[client][1]=dummy_source;
	g_rope_ent[client][2]=particle; 
 
}

AttachEnt(owner, ent, String:positon[]="medkit", Float:pos[3]=NULL_VECTOR,Float:ang[3]=NULL_VECTOR)
{
	decl String:tname[64];
	Format(tname, sizeof(tname), "target%d", owner);
	DispatchKeyValue(owner, "targetname", tname); 		
	DispatchKeyValue(ent, "parentname", tname);
	
	SetVariantString(tname);
	AcceptEntityInput(ent, "SetParent",ent, ent, 0); 	
	if(strlen(positon)!=0)
	{
		SetVariantString(positon); 
		AcceptEntityInput(ent, "SetParentAttachment");
	}
	TeleportEntity(ent, pos, ang, NULL_VECTOR);
}

IsEnt(ent)
{
	if(ent>0 && IsValidEdict(ent) && IsValidEntity(ent))
	{
		return true;
	}
	return false;
}

Glow(client, bool:glow)
{
	if(L4D2Version)
	{
		if (client>0 && IsClientInGame(client) && IsPlayerAlive(client))
		{
			if(glow)
			{
				SetEntProp(client, Prop_Send, "m_iGlowType", 3 ); //3
				SetEntProp(client, Prop_Send, "m_nGlowRange", 0 ); //0
				SetEntProp(client, Prop_Send, "m_glowColorOverride", 256*100); //1	
			}
			else 
			{
				SetEntProp(client, Prop_Send, "m_iGlowType", 0 ); //3
				SetEntProp(client, Prop_Send, "m_nGlowRange", 0 ); //0
				SetEntProp(client, Prop_Send, "m_glowColorOverride", 0); //1	
			}
			
		
		}
	
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(!g_rope_enabled[client])return Plugin_Continue; 
	
	
	new bool:start_rope= ((buttons & IN_ZOOM) && !(g_last_button[client] & IN_ZOOM));
	if(start_rope)
	{
		if(g_rope_state[client]==state_none)StartRope(client);
		else StopRope(client);
	}	
	
	if(g_rope_state[client]==state_shot)
	{

		new last_button=g_last_button[client];
		new Float:engine_time= GetEngineTime();
		
		new Float:duration=engine_time-g_last_time[client];
		if(duration>1.0)duration=1.0;
		else if(duration<=0.0)duration=0.01;
		g_last_time[client] = engine_time; 
		
	
		new target=g_rope_target[client];
		new Float:target_position[3];
		
		new bool:on_ground=false;
		if(GetEntityFlags(client) & FL_ONGROUND)
		{
			on_ground=true; 
		}
		
		new Float:client_angle[3];
		GetClientEyeAngles(client, client_angle);  
		 
		new Float:client_eye_position[3];
		GetClientEyePosition(client, client_eye_position);
		
		if(on_ground && GetVectorDistance(client_eye_position, g_target_postion[client])>GetConVarFloat(l4d_rope_distance))
		{
			PrintHintText(client, "Rope is too long");
			StopRope(client);
			
			return Plugin_Continue;
		}
		
		if(IsEnt(target))
		{
			
			GetEntPropVector(target, Prop_Send, "m_vecOrigin", target_position);
			target_position[2]+=50.0;
			CopyVector(target_position, g_target_postion[client] );	
		}
		else
		{
			
			g_rope_target[client]=0;
			if(target>0)
			{
				StopRope(client);
				return Plugin_Continue;
			}
			target=0; 
			CopyVector(g_target_postion[client], target_position);	
		} 
		

		

		
		new Float:dir[3];
		//drag target
		new bool:press_drag=(buttons & IN_SPEED);
		if(target>0 && press_drag)
		{
			GetAngleVectors(client_angle, dir, NULL_VECTOR, NULL_VECTOR);
		 
			NormalizeVector(dir, dir);
			ScaleVector(dir, 90.0);
			AddVectors(dir, client_eye_position,client_eye_position);	
			
			new Float:force[3];
			SubtractVectors(target_position, client_eye_position, force);
			new Float:rope_length=GetVectorLength(force);
			g_rope_length[client]=rope_length;
			
			NormalizeVector(force, force); 
 
			new Float:drag_force=300.0;
			if(rope_length<50.0)drag_force=rope_length;
			
			ScaleVector(force, -1.0*drag_force);
			TeleportEntity(target, NULL_VECTOR, NULL_VECTOR,force);
			
			new bool:hurt_target=false;
			if(engine_time-g_hurt_time[client]>0.1)
			{
				hurt_target=true;
				g_hurt_time[client]=engine_time;
			}
			
			if(hurt_target)
			{
				float dmgper = 1.0;
				if (GetClientTeam(target) == L4D2Team_Survivor){
					dmgper = 0.2;
				}
				DoPointHurtForInfected(target, client, GetConVarFloat(l4d_rope_damage) * dmgper);
				new Float:angle[3];
				ScaleVector(force, -1.0);
				GetVectorAngles(force, angle);
				ShowParticle(target_position, angle, PARTICLE_BLOOD, 0.1);
			 
			}	
			
		} 
		else if(target==0)
		{ 
			new Float:target_distacne=GetVectorDistance(target_position, client_eye_position);
			//g_rope_length[client]=rope_length;
			if(on_ground)
			{
				on_ground=true; 
				SetEntityGravity(client, 1.0);
			}
			
			if(on_ground)
			{
				g_rope_length[client]=target_distacne; 
				g_rope_free[client]=true;
			}
			else
			{
				
			}
 
			
			if(!on_ground && (buttons & IN_SPEED))
			{
				g_rope_length[client]-=360.0 * duration; 
				if(g_rope_length[client]<20.0) g_rope_length[client]=20.0;
				g_rope_free[client]=false;
				
			}
			if(!on_ground && (buttons & IN_DUCK))
			{
				g_rope_length[client]+=350.0 * duration; 
				//if(g_rope_length[client]<30.0) g_rope_length[client]=30.0;
				g_rope_free[client]=false;
			} 
			
			if(!g_rope_free[client])
			{
				
				new Float:diff=target_distacne-g_rope_length[client];
				if(diff>20.0)
				{
					if((client_eye_position[2]<target_position[2]))g_rope_length[client]=target_distacne-20.0;
					diff=20.0;
				}
				if(diff>0)
				{
					//SetEntityGravity(client, 1.0);
					new Float:grivaty_dir[3];
					grivaty_dir[2]=-1.0;
				
								 	
					new Float:drag_dir[3];
					SubtractVectors(target_position, client_eye_position,drag_dir);
					NormalizeVector(drag_dir, drag_dir); 
					
					new Float:add_force_dir[3];
					AddVectors(grivaty_dir,drag_dir,add_force_dir);
					NormalizeVector(add_force_dir, add_force_dir); 
					
					
					new Float:client_vel[3];
					GetEntDataVector(client, g_iVelocity, client_vel);
					

					
					new Float:plane[3];
					CopyVector(drag_dir, plane);
					//GetVectorCrossProduct(client_vel, drag_dir, plane);
					
					new Float:vel_on_plane[3];
					GetProjection(plane, client_vel, vel_on_plane); 
			 		
					
					
					new Float:factor=diff/20.0;
					
					ScaleVector(drag_dir, factor*350.0);
					//ScaleVector(client_vel, 1.0-factor);
					
					new Float:new_vel[3];
					AddVectors(vel_on_plane,drag_dir,new_vel); 
	 	
					if(client_eye_position[2]<target_position[2])
					{
						TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, new_vel);
					}
				 		
					if((buttons & IN_JUMP) && !(last_button & IN_JUMP) && engine_time-g_jump_time[client]>1.0)
					{
						g_jump_time[client]=engine_time;
						new Float:dir[3];
						GetAngleVectors(client_angle, dir, NULL_VECTOR, NULL_VECTOR); 
						NormalizeVector(dir, dir);
						
						grivaty_dir[2]=1.0;
						AddVectors(dir,grivaty_dir,dir);
						//dir[2]=1.0;
						NormalizeVector(dir, dir);
						ScaleVector(dir, 3000.0);
						TeleportEntity(client, NULL_VECTOR, NULL_VECTOR,dir);
						g_rope_length[client]+=10.0;
					}
				} 
				else 
				{
					//SetEntityGravity(client, 1.0);
				}
					
			}
			else
			{
				if(GetVectorDistance(target_position, client_eye_position)>GetConVarFloat(l4d_rope_distance))
				{
					StopRope(client);
					return Plugin_Continue;
				}
			}

			CheckSpeed(client);		
			
		}
		/*
		
			GetAngleVectors(client_angle, dir, NULL_VECTOR, NULL_VECTOR);
		 
			NormalizeVector(dir, dir);
			ScaleVector(dir, 110.0);
			AddVectors(dir, client_eye_position,client_eye_position);	
			
			new Float:force[3];
			SubtractVectors(target_position, client_eye_position, force);
			new Float:dis=GetVectorLength(force);
			NormalizeVector(force, force); 
			
			new Float:grivaty_force[3];
			grivaty_force[2]=-0.5;
			
			AddVectors(force,grivaty_force,force);
			NormalizeVector(force, force); 			
		
		new Float:force[3];
		SubtractVectors(target_position, client_eye_position, force);
		new Float:dis=GetVectorLength(force);
		NormalizeVector(force, force); 
		
		new Float:grivaty_force[3];
		grivaty_force[2]=-0.5;
		
		AddVectors(force,grivaty_force,force);
		NormalizeVector(force, force); 
		
		
		new Float:f=300.0;
		if(dis<50.0)f=dis;
		if(buttons & IN_SPEED)
		{
			if(target>0)
			{
				ScaleVector(force, -1.0*f);
				TeleportEntity(target, NULL_VECTOR, NULL_VECTOR,force);
			}
			else
			{
				ScaleVector(force, 1.0*f);
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR,force);
			}	
			
			new bool:hurt_target=false;
			if(engine_time-g_hurt_time[client]>0.1)
			{
				hurt_target=true;
				g_hurt_time[client]=engine_time;
			}
			
			if(target>0 && hurt_target)
			{
				if(IsInfectedTeam(target))
				{ 
					DoPointHurtForInfected(target, client, GetConVarFloat(l4d_rope_damage));
					new Float:angle[3];
					ScaleVector(force, -1.0);
					GetVectorAngles(force, angle);
					ShowParticle(target_position, angle, PARTICLE_BLOOD, 0.1);
				}
			}			
		}
		else
		{
			 
			CheckSpeed(client);			
			if(target>0 && IsSurvivorTeam(target))
			{
				CheckSpeed(target);
			}
			if(!(GetEdictFlags(client) & FL_ONGROUND) && ((buttons & IN_JUMP) && !(last_button & IN_JUMP)))
			{
				GetAngleVectors(client_angle, dir, NULL_VECTOR, NULL_VECTOR);
				dir[2]=0.0;
				NormalizeVector(dir, dir);
				dir[2]=1.0;
				NormalizeVector(dir, dir);
				ScaleVector(dir, 400.0);
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR,dir);
				//StopRope(client);
			}
			 
		} 
		*/
	}

	
	g_last_button[client]=buttons;
	return Plugin_Continue;
}
CheckSpeed(client)
{
	decl Float:velocity[3];
	GetEntDataVector(client, g_iVelocity, velocity);
	new Float:vel=GetVectorLength(velocity);
	if(vel>500.0)
	{
		NormalizeVector(velocity, velocity);
		ScaleVector(velocity, 500.0);
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR,velocity);
	}
}
bool:IsPrimaryWeapon(client)
{
	decl String:weapon_name[50];
	GetClientWeapon(client, weapon_name, 50);


	new ent=GetPlayerWeaponSlot(client, 0);
	if(ent<=0)return false;
	
	decl String:primary_name[50];
	GetEdictClassname(ent, primary_name, 50);
	if(StrEqual( weapon_name, primary_name) )return true;

	return false;
}
GetEnemyPostion(entity, Float:position[3])
{
	if(entity<=MaxClients) GetClientAbsOrigin(entity, position);
	else GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
	position[2]+=35.0; 
}

IsEnemyVisible(client, infected, Float:client_position[3])
{	

 	new Float:angle[3];
	new Float:enemy_position[3];
	if(infected<=MaxClients) GetClientAbsOrigin(infected, enemy_position);
	else GetEntPropVector(infected, Prop_Send, "m_vecOrigin", enemy_position);
	enemy_position[2]+=35.0; 
	if(GetVectorDistance(enemy_position, client_position)>GetConVarFloat(l4d_rope_distance))return 0;
	
	SubtractVectors(enemy_position, client_position, angle);
	GetVectorAngles(angle, angle); 
	new Handle:trace=TR_TraceRayFilterEx(client_position, angle, MASK_ALL, RayType_Infinite, TraceRayDontHitSelf, client); 	 

	new newenemy=0;
	 
	if(TR_DidHit(trace))
	{		 

		newenemy=TR_GetEntityIndex(trace);  		
	}
	CloseHandle(trace); 
	if(newenemy==0)return 0;
	if(newenemy == infected)return infected;

	if(IsInfectedTeam(newenemy))
	{
		return newenemy;
	}	
	return 0;
}

GetClientFrontEnemy(client, Float:client_postion[3], Float:range)
{
	new enemy_id=GetClientAimTarget(client, false);

	if(IsInfectedTeam(enemy_id)) 
	{
		new Float:enemy_position[3];
		GetEntPropVector(enemy_id, Prop_Send, "m_vecOrigin", enemy_position);
		return enemy_id;
	}
	return 0;
}
Float:GetRange(enemy_id, Float:human_position[3], Float:enemy_position[3])
{		
	GetEntPropVector(enemy_id, Prop_Send, "m_vecOrigin", enemy_position);
	enemy_position[2]+=50.0;
	new Float:dis=GetVectorDistance(enemy_position, human_position);
	
	return dis;
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

GameCheck()
{
	decl String:GameName[16];
	GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));
	PrintToChatAll("mp_gamemode = %s", GameName);
	
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
	L4D2Version=!!L4D2Version;
}

GetLookPosition(client, Float:pos[3], Float:angle[3], Float:hitpos[3])
{
	
	new Handle:trace=TR_TraceRayFilterEx(pos, angle, MASK_ALL, RayType_Infinite, TraceRayDontHitSelf, client); 

	if(TR_DidHit(trace))
	{		
	
		TR_GetEndPosition(hitpos, trace);
		
	}
	CloseHandle(trace);  
	
}

ScanEnemy(client, infected, Float:client_postion[3], Float:angle)
{	

	new Float:angle_vec[3] ;
	new Float:postion[3];
	CopyVector(client_postion,postion);
	postion[2]-=20.0;

	angle_vec[0]=angle_vec[1]=angle_vec[2]=0.0;
	angle_vec[1]=angle;
	//GetEntPropVector(ent, Prop_Send, "m_vecOrigin", hitpos);
	//PrintToChatAll("%f %f", dir[0], dir[1]);
	new Handle:trace=TR_TraceRayFilterEx(postion, angle_vec, MASK_SHOT, RayType_Infinite, TraceRayDontHitSelfAndHuman, infected); 	 
	
	new newenemy=0;
	if(TR_DidHit(trace))
	{		 
		newenemy=TR_GetEntityIndex(trace); 
	} 
	CloseHandle(trace); 
	if(!IsInfectedTeam(newenemy))newenemy=0;
	return newenemy;
}
public bool:TraceRayDontHitSelfAndHuman(entity, mask, any:data)
{
	if(entity == data) 
	{
		return false; 
	} 
	if(entity<=MaxClients && entity>0)
	{
		if(IsClientInGame(entity) && IsPlayerAlive(entity) && GetClientTeam(entity)==2)
		{
			return false; 
		}
	}
	return true;
} 
public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	if(entity == data) 
	{
		return false; 
	} 
	
	return true;
} 
bool:IsVisible(Float:pos1[3], Float:pos2[3], infected)
{	
 	
	new Handle:trace=TR_TraceRayFilterEx(pos1, pos2, MASK_SHOT, RayType_EndPoint, TraceRayDontHitAlive, infected); 	 
	
	new ent=0;
	if(TR_DidHit(trace))
	{		 
		ent=TR_GetEntityIndex(trace); 
	}
	CloseHandle(trace); 

	if(ent>0)return false;
	return true;
		
}
public bool:TraceRayDontHitAlive(entity, mask, any:data)
{
	if(entity==0)return false;
	if(entity == data) 
	{
		return false; 
	} 
	if(entity<=MaxClients && entity>0)
	{
		return false;  
	}
	else 
	{
		decl String:classname[32];
		GetEdictClassname(entity, classname,32);
		if(StrEqual(classname, "infected", true) || StrEqual(classname, "witch", true) )
		{
			return false;  
		}
	}
	return true;
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
new String:N[20];
DoPointHurtForInfected(victim, attacker=0,  Float:damage=0.0)
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
				DispatchKeyValueFloat(g_PointHurt,"Damage", damage);
				DispatchKeyValue(g_PointHurt,"DamageType","-2130706430");
				AcceptEntityInput(g_PointHurt,"Hurt",(attacker>0)?attacker:-1);
			}
		}
		else g_PointHurt=CreatePointHurt();
	}
	else g_PointHurt=CreatePointHurt();
}

stock SetupProgressBar(client, Float:time)
{
	//KillProgressBar(client);
	//SetEntPropEnt(client, Prop_Send, "m_reviveOwner", -1);
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", time);
	//SetEntPropEnt(client, Prop_Send, "m_reviveOwner", client);
	//SetEntPropEnt(client, Prop_Send, "m_reviveTarget", client);

}

stock KillProgressBar(client)
{
	//SetEntPropEnt(client, Prop_Send, "m_reviveOwner", -1);
	//SetEntityMoveType(client, MOVETYPE_WALK);
	//SetEntPropEnt(client, Prop_Send, "m_reviveTarget", 0);
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
	//SetEntPropEnt(client, Prop_Send, "m_reviveOwner", 0);
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

 
GlowEnt(ent, bool:glow)
{
	if(L4D2Version)
	{
		if (ent>0 && IsValidEdict(ent) && IsValidEntity(ent))
		{
			if(glow)
			{
				SetEntProp(ent, Prop_Send, "m_iGlowType", 3 ); //3
				SetEntProp(ent, Prop_Send, "m_nGlowRange", 0 ); //0
				SetEntProp(ent, Prop_Send, "m_glowColorOverride", 256*100); //1	
			}
			else 
			{
				SetEntProp(ent, Prop_Send, "m_iGlowType", 0 ); //3
				SetEntProp(ent, Prop_Send, "m_nGlowRange", 0 ); //0
				SetEntProp(ent, Prop_Send, "m_glowColorOverride", 0); //1	
			}
			
		
		}
	
	}
}


GetEnt(client, Float:pos[3], Float:angle[3], Float:hitpos[3])
{

	new Handle:trace= TR_TraceRayFilterEx(pos, angle, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelf2, client); 
	new ent=-1;
 
	if(TR_DidHit(trace))
	{			
		ent=0;
		TR_GetEndPosition(hitpos, trace);
		ent=TR_GetEntityIndex(trace);
		 
		if(ent>0)
		{			
			decl String:classname[64];
			GetEdictClassname(ent, classname, 64);		 	
			decl String:mclassname[64];
			//GetEntPropString(ent, Prop_Data, "m_ModelName", mclassname, sizeof(mclassname));
			//PrintToChat(client, "%s %s", classname, mclassname); 
		} 
	}
	CloseHandle(trace); 
	if(ent>0)
	{ 
	}
	return ent;
}
public bool:TraceRayDontHitSelf2 (entity, mask, any:data)
{
	if(entity<=0)return false;
	if(entity == data) 
	{
		return false; 
	}
	
	return true;
}

bool:IsInfectedTeam(ent)
{
	if(ent>0)
	{		 
		if(ent<=MaxClients)
		{
			if(IsClientInGame(ent) && IsPlayerAlive(ent) && GetClientTeam(ent)==3)
			{
				new class = GetEntProp(ent, Prop_Send, "m_zombieClass"); 
				if(class==ZOMBIECLASS_TANK)return false;
				return true;
			}
		}
		return false;
		/*
		else if(IsValidEntity(ent) && IsValidEdict(ent))
		{
			
			decl String:classname[32];
			GetEdictClassname(ent, classname,32);
			
			if(StrEqual(classname, "infected", true) || StrEqual(classname, "witch", true) )
			{
				return true;
			}
		}*/
	} 
	return false;
}
 
bool:IsSurvivorTeam(ent)
{
	if(ent>0)
	{		 
		if(ent<=MaxClients)
		{
			if(IsClientInGame(ent) && IsPlayerAlive(ent) && GetClientTeam(ent)==2)
			{
				return true;
			}
		}
	
	} 
	return false;
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
	new Float:t[3];
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
	
	new Float:p=-1.0*(A*a+B*b+C*c)/(A*A+B*B+C*C);
	r[0]=A*p+a;
	r[1]=B*p+b;
	r[2]=C*p+c; 
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