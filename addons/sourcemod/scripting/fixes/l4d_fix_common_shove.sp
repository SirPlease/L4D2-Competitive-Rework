#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks_anim>
#include <actions>

#define PLUGIN_VERSION "1.4.1"

public Plugin myinfo = 
{
	name = "[L4D & 2] Fix Common Shove",
	author = "Forgetest",
	description = "Fix commons being immune to shoves when crouching, falling and landing.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins",
}

#define GAMEDATA_FILE "l4d_fix_common_shove"

Handle g_hCall_MyNextBotPointer;
Handle g_hCall_GetBodyInterface;
Handle g_hCall_GetLocomotionInterface;
Handle g_hCall_SetDesiredPosture;

int g_iOffs_ZombieBotLocomotion__m_ladder;

enum ActivityType 
{ 
	MOTION_CONTROLLED_XY	= 0x0001,	// XY position and orientation of the bot is driven by the animation.
	MOTION_CONTROLLED_Z		= 0x0002,	// Z position of the bot is driven by the animation.
	ACTIVITY_UNINTERRUPTIBLE= 0x0004,	// activity can't be changed until animation finishes
	ACTIVITY_TRANSITORY		= 0x0008,	// a short animation that takes over from the underlying animation momentarily, resuming it upon completion
	ENTINDEX_PLAYBACK_RATE	= 0x0010,	// played back at different rates based on entindex
};

enum PostureType
{
	STAND,
	CROUCH,
	SIT,
	CRAWL,
	LIE
};

INextBot MyNextBotPointer(int entity)
{
	return SDKCall(g_hCall_MyNextBotPointer, entity);
}

methodmap INextBot
{
	public ZombieBotBody GetBodyInterface() {
		return SDKCall(g_hCall_GetBodyInterface, this);
	}

	public ZombieBotLocomotion GetLocomotionInterface() {
		return SDKCall(g_hCall_GetLocomotionInterface, this);
	}
}

methodmap ZombieBotBody
{
	public void SetDesiredPosture(PostureType posture) {
		SDKCall(g_hCall_SetDesiredPosture, this, posture);
	}

	property int m_activity {
		public get() { return LoadFromAddress(view_as<Address>(this) + view_as<Address>(80), NumberType_Int32); }
		public set(int act) { StoreToAddress(view_as<Address>(this) + view_as<Address>(80), act, NumberType_Int32); }
	}
	
	property ActivityType m_activityType {
		public get() { return LoadFromAddress(view_as<Address>(this) + view_as<Address>(84), NumberType_Int32); }
		public set(ActivityType flags) { StoreToAddress(view_as<Address>(this) + view_as<Address>(84), flags, NumberType_Int32); }
	}
}

methodmap ZombieBotLocomotion
{
	property Address m_ladder {
		public get() { return LoadFromAddress(view_as<Address>(this) + view_as<Address>(g_iOffs_ZombieBotLocomotion__m_ladder), NumberType_Int32); }
		public set(Address p) { StoreToAddress(view_as<Address>(this) + view_as<Address>(g_iOffs_ZombieBotLocomotion__m_ladder), p, NumberType_Int32); }
	}
}

enum
{
	SHOVE_CROUCHING	= 1,
	SHOVE_FALLING	= (1 << 1),
	SHOVE_LANDING	= (1 << 2),
	SHOVE_CLIMBING	= (1 << 3),
};

int g_iShoveFlag;

enum PendingShoveState
{
	PendingShove_Invalid = 0,
	PendingShove_Yes,
	PendingShove_Callback,
};

public void OnPluginStart()
{
	GameData gd = new GameData(GAMEDATA_FILE);
	if (!gd)
		SetFailState("Missing gamedata \""...GAMEDATA_FILE..."\"");
	
	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(gd, SDKConf_Signature, "ZombieBotBody::SetDesiredPosture"))
		SetFailState("Missing signature \"ZombieBotBody::SetDesiredPosture\"");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	g_hCall_SetDesiredPosture = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Entity);
	if (!PrepSDKCall_SetFromConf(gd, SDKConf_Virtual, "CBaseEntity::MyNextBotPointer"))
		SetFailState("Missing signature \"CBaseEntity::MyNextBotPointer\"");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hCall_MyNextBotPointer = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(gd, SDKConf_Virtual, "INextBot::GetBodyInterface"))
		SetFailState("Missing signature \"INextBot::GetBodyInterface\"");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hCall_GetBodyInterface = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(gd, SDKConf_Virtual, "INextBot::GetLocomotionInterface"))
		SetFailState("Missing signature \"INextBot::GetLocomotionInterface\"");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hCall_GetLocomotionInterface = EndPrepSDKCall();

	g_iOffs_ZombieBotLocomotion__m_ladder = gd.GetOffset("ZombieBotLocomotion::m_ladder");
	
	delete gd;
	
	CreateConVarHook("l4d_common_shove_flag",
					"15",
					"Flag for fixing common shove.\n"
				...	"1 = Crouch, 2 = Falling, 4 = Landing, 8 = Climbing",
					FCVAR_CHEAT,
					true, 0.0, false, 15.0,
					CvarChg_ShoveFlag);
}

void CvarChg_ShoveFlag(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iShoveFlag = convar.IntValue;
}

public void OnActionCreated(BehaviorAction action, int actor, const char[] name)
{
	if (name[0] == 'I' && strcmp(name, "InfectedShoved") == 0)
	{
		action.OnStart = InfectedShoved_OnStart;
		action.OnShoved = InfectedShoved_OnShoved;
		action.OnLandOnGroundPost = InfectedShoved_OnLandOnGroundPost;
	}
}

Action InfectedShoved_OnStart(BehaviorAction action, int actor, any priorAction, ActionResult result)
{
	if (MyNextBotPointer(actor).GetBodyInterface().m_activity == L4D2_ACT_TERROR_FALL) // falling check
	{
		if (g_iShoveFlag & SHOVE_FALLING)
		{
			result.type = CONTINUE; // do not exit
			
			action.SetUserData("state", PendingShove_Yes); // for later use in "InfectedShoved_OnLandOnGroundPost"
			
			float direction[3], pos[3];
			direction[0] = action.Get(56, NumberType_Int32);
			direction[1] = action.Get(60, NumberType_Int32);
			direction[2] = action.Get(64, NumberType_Int32);
			GetEntPropVector(actor, Prop_Data, "m_vecAbsOrigin", pos);
			SubtractVectors(direction, pos, direction);
			
			action.SetUserDataVector("direction", direction);
			
			// almost certain that shove does nothing at the moment, just skip it
			return Plugin_Handled; 
		}
		
		return Plugin_Continue;
	}
	
	INextBot nb = MyNextBotPointer(actor);
	if (g_iShoveFlag & SHOVE_CROUCHING)
	{
		nb.GetBodyInterface().SetDesiredPosture(STAND); // force standing to activate shoves
	}

	if (g_iShoveFlag & SHOVE_CLIMBING)
	{
		nb.GetLocomotionInterface().m_ladder = Address_Null;
	}
	
	if (g_iShoveFlag & SHOVE_LANDING
	  || (g_iShoveFlag & SHOVE_FALLING && action.GetUserData("state") == PendingShove_Callback))
	{
		ForceActivityInterruptible(actor); // if they happen to land on ground at the time, override
	}
	
	if (action.GetUserData("state") == PendingShove_Callback)
	{
		float direction[3], pos[3];
		action.GetUserDataVector("direction", direction);
		GetEntPropVector(actor, Prop_Data, "m_vecAbsOrigin", pos);
		AddVectors(pos, direction, pos);
		
		action.Set(56, pos[0], NumberType_Int32);
		action.Set(60, pos[1], NumberType_Int32);
		action.Set(64, pos[2], NumberType_Int32);
	}
	
	return Plugin_Continue;
}

Action InfectedShoved_OnShoved(BehaviorAction action, int actor, int entity, ActionDesiredResult result)
{
	if (GetEntPropEnt(actor, Prop_Data, "m_hGroundEntity") != -1) // falling check
	{
		if (g_iShoveFlag & SHOVE_CROUCHING)
		{
			MyNextBotPointer(actor).GetBodyInterface().SetDesiredPosture(STAND); // force standing to activate shoves
		}
	}
	
	return Plugin_Continue;
}

Action InfectedShoved_OnLandOnGroundPost(BehaviorAction action, int actor, int entity, ActionDesiredResult result)
{
	if (~g_iShoveFlag & SHOVE_FALLING || action.GetUserData("state") != PendingShove_Yes)
		return Plugin_Continue;
	
	action.IsStarted = false; // trick the action into calling OnStart as if actor get shoved this frame
	action.SetUserData("state", PendingShove_Callback);
	
	ForceActivityInterruptible(actor); // if they happen to land on ground at the time, override
	
	return Plugin_Handled;
}

bool ForceActivityInterruptible(int infected)
{
	ZombieBotBody body = MyNextBotPointer(infected).GetBodyInterface();
	
	if (L4D_IsEngineLeft4Dead1()) // perhaps unnecessary
	{
		switch (body.m_activity)
		{
			case L4D1_ACT_TERROR_JUMP_LANDING,
				L4D1_ACT_TERROR_JUMP_LANDING_HARD,
				L4D1_ACT_TERROR_JUMP_LANDING_NEUTRAL,
				L4D1_ACT_TERROR_JUMP_LANDING_HARD_NEUTRAL: { }
			default: { return false; }
		}
	}
	else
	{
		switch (body.m_activity)
		{
			case L4D2_ACT_TERROR_JUMP_LANDING,
				L4D2_ACT_TERROR_JUMP_LANDING_HARD,
				L4D2_ACT_TERROR_JUMP_LANDING_NEUTRAL,
				L4D2_ACT_TERROR_JUMP_LANDING_HARD_NEUTRAL: { }
			default: { return false; }
		}
	}
	
	body.m_activityType &= ~ACTIVITY_UNINTERRUPTIBLE;
	return true;
}

stock bool IsInfected(int entity)
{
	if (entity > MaxClients && IsValidEdict(entity))
	{
		char cls[64];
		GetEdictClassname(entity, cls, sizeof(cls));
		return strcmp(cls, "infected") == 0;
	}
	return false;
}

ConVar CreateConVarHook(const char[] name,
	const char[] defaultValue,
	const char[] description="",
	int flags=0,
	bool hasMin=false, float min=0.0,
	bool hasMax=false, float max=0.0,
	ConVarChanged callback)
{
	ConVar cv = CreateConVar(name, defaultValue, description, flags, hasMin, min, hasMax, max);
	
	Call_StartFunction(INVALID_HANDLE, callback);
	Call_PushCell(cv);
	Call_PushNullString();
	Call_PushNullString();
	Call_Finish();
	
	cv.AddChangeHook(callback);
	
	return cv;
}
