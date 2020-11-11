/*
Scene Processor
Copyright (C) 2011-2014  Buster "Mr. Zero" Nielsen

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

/* Includes */
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <sceneprocessor>

/* Plugin Information */
public Plugin:myinfo = 
{
	name           = "Scene Processor",
	author         = "Buster \"Mr. Zero\" Nielsen",
	description    = "Provides forwards and natives for manipulation of scenes",
	version        = SCENEPROCESSOR_VERSION,
	url            = "https://forums.alliedmods.net/showthread.php?t=241585"
}

/* Globals */
#define MAXENTITIES	2048

#define DEBUG 0
#define DEBUG_TAG "SceneProcessor"

#define USE_VERSION_CONVAR 1
#define CONVAR_VERSION_NAME "sceneprocessor_version"
#define CONVAR_VERSION_VALUE SCENEPROCESSOR_VERSION
#define CONVAR_VERSION_DESC "Version of Scene Processor SourceMod plugin"

/* Borrowed from L4DStocks ( https://code.google.com/p/l4dstocks/ ) */
enum L4DTeam
{
    L4DTeam_Unassigned              = 0,
    L4DTeam_Spectator               = 1,
    L4DTeam_Survivor                = 2,
    L4DTeam_Infected                = 3
}

#define DEFAULT_SCENE_IS_IN_FAKE_POST_SPAWN false
#define DEFAULT_SCENE_START_TIMESTAMP 0.0
#define DEFAULT_SCENE_ACTOR 0
#define DEFAULT_SCENE_INITIATOR 0
#define DEFAULT_SCENE_FILE "\0"
#define DEFAULT_SCENE_VOCALIZE "\0"

#define SCENE_CLASSNAME "instanced_scripted_scene"

new bool:g_IsL4D1

#define MAP_START_TIME_STAMP_OFFSET 2.0 /* Over time the time stamp becomes more unreliable and therefore we add as much
					 * offset the vocalize command accepts. Tested to work for at least 6+ hours. */
new Float:g_MapStartTimeStamp

#define CONVAR_JAILBREAK_VOCALIZE_COMMAND_NAME "sceneprocessor_jailbreak_vocalize"
#define CONVAR_JAILBREAK_VOCALIZE_COMMAND_VALUE "1"
#define CONVAR_JAILBREAK_VOCALIZE_COMMAND_DESC "Whether the vocalize command will function once again as it did in L4D1, allowing players to type vocalize commands into their console. 0 = Disallow, 1 = Allow"
new bool:g_IsJailBreakingVocalizeCommand

new bool:g_IsInGame[MAXPLAYERS + 1]
new g_PlayingScene[MAXPLAYERS + 1]

#define VOCALIZE_COMMAND "vocalize"
#define VOCALIZE_COMMAND_L4D1_FORMATTING "%s %s"
#define VOCALIZE_COMMAND_L4D2_FORMATTING "%s %s #%s%s" /* L4D2 contains time since map start to prevent vocalization binds. 
							* Completely pointless when players can make a custom .vpk containing the voice
							* mouse menus. GG Valve. Time to jailbreak it. */
#define VOCALIZE_SMARTLOOK_STRING "smartlook"
#define VOCALIZE_SMARTLOOK_TIMESTAMP "auto"
new String:g_VocalizeString[MAXPLAYERS + 1][MAX_VOCALIZE_LENGTH]
new g_VocalizeTick[MAXPLAYERS + 1]
new bool:g_VocalizeGotInitiator[MAXPLAYERS + 1]
new g_VocalizeInitiator[MAXPLAYERS + 1]
new Float:g_VocalizePreDelay[MAXPLAYERS + 1]
new Float:g_VocalizePitch[MAXPLAYERS + 1]

new Handle:g_FwdOnSceneStageChanged
new Handle:g_FwdOnVocalizeCommand

new bool:g_HasAnySceneToProcess
new Handle:g_SceneStack

#define VOCALIZE_MIN_TICK_SPACING 10 	/* If a Survivor was cancelled in mid scene, vocalize command does not seem to 
					 * accept any vocalizes for a short while. However manually spamming a vocalize
					 * key, cancelling the scene over and over again, works just fine.
					 * Pressing a vocalize key right after the "Cancel" input have been sent to the
					 * scene also stops working. It may all be related to "Cancel" input forcing
					 * a cooldown of sorts. 10 seems to be the magic number, anything lower
					 * and it might not work. Sadly there is what feels like a huge pause, 1/3 of a
					 * second before the vocalize of the next line begins. Can't do much about it */
#define VOCALIZEARRAY_ARRAY_SIZE 6
#define VOCALIZEARRAY_INDEX_CLIENT 0
#define VOCALIZEARRAY_INDEX_VOCALIZE 1
#define VOCALIZEARRAY_INDEX_PREDELAY 2
#define VOCALIZEARRAY_INDEX_PITCH 3
#define VOCALIZEARRAY_INDEX_INITIATOR 4
#define VOCALIZEARRAY_INDEX_TICK 5

new bool:g_HasAnyVocalizeCommandsToProcess
new Handle:g_VocalizeArray

enum SceneData
{
	SceneStages:SceneData_Stage,
	bool:SceneData_IsInFakePostSpawn,
	Float:SceneData_StartTimeStamp,
	SceneData_Actor,
	SceneData_Initiator,
	String:SceneData_File[MAX_SCENEFILE_LENGTH],
	String:SceneData_Vocalize[MAX_VOCALIZE_LENGTH],
	Float:SceneData_PreDelay,
	Float:SceneData_Pitch
}

new g_SceneDataArray[MAXENTITIES + 1][SceneData]

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	if (!IsDedicatedServer())
	{
		strcopy(error, err_max, "This plugin only support dedicated servers")
		return APLRes_Failure
	}
	
	new EngineVersion:engine = GetEngineVersion()
	if (engine == Engine_Left4Dead)
	{
		g_IsL4D1 = true
	}
	else if (engine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "This plugin only support Left 4 Dead & Left 4 Dead 2")
		return APLRes_Failure
	}
	
	CreateNative("GetSceneStage", N_GetSceneStage)
	CreateNative("GetSceneStartTimeStamp", N_GetSceneStartTimeStamp)
	CreateNative("GetActorFromScene", N_GetSceneActor)
	CreateNative("GetSceneFromActor", N_GetActorScene)
	CreateNative("GetSceneInitiator", N_GetSceneInitiator)
	CreateNative("GetSceneFile", N_GetSceneFile)
	CreateNative("GetSceneVocalize", N_GetSceneVocalize)
	CreateNative("GetScenePreDelay", N_GetScenePreDelay)
	CreateNative("SetScenePreDelay", N_SetScenePreDelay)
	CreateNative("GetScenePitch", N_GetScenePitch)
	CreateNative("SetScenePitch", N_SetScenePitch)
	CreateNative("CancelScene", N_CancelScene)
	CreateNative("PerformScene", N_PerformScene)
	CreateNative("PerformSceneEx", N_PerformSceneEx)
	
	RegPluginLibrary(SCENEPROCESSOR_LIBRARY)
	
	return APLRes_Success
}

public OnPluginStart()
{
	g_SceneStack = CreateStack()
	g_VocalizeArray = CreateArray(MAX_VOCALIZE_LENGTH)
	
	for (new i = 1; i <= MAXENTITIES; i++)
	{
		SceneData_SetStage(i, SceneStages:0)
	}
	
	for (new i = 1; i <= MAXPLAYERS; i++)
	{
		ResetClientVocalizeData(i)
	}
	
	g_FwdOnSceneStageChanged = CreateGlobalForward("OnSceneStageChanged", ET_Ignore, Param_Cell, Param_Cell)
	g_FwdOnVocalizeCommand = CreateGlobalForward("OnVocalizeCommand", ET_Hook, Param_Cell, Param_String, Param_Cell)
	
	if (!g_IsL4D1)
	{
		new Handle:convar = CreateConVar(CONVAR_JAILBREAK_VOCALIZE_COMMAND_NAME, CONVAR_JAILBREAK_VOCALIZE_COMMAND_VALUE, CONVAR_JAILBREAK_VOCALIZE_COMMAND_DESC, FCVAR_NONE)
		HookConVarChange(convar, OnJailBreakConVarChanged)
		g_IsJailBreakingVocalizeCommand = GetConVarBool(convar)
	}
	
#if USE_VERSION_CONVAR
	CreateConVar(CONVAR_VERSION_NAME, CONVAR_VERSION_VALUE, CONVAR_VERSION_DESC, FCVAR_NONE | FCVAR_NOTIFY)
#endif
	
	AddCommandListener(OnVocalize_Command, VOCALIZE_COMMAND)
}

public OnJailBreakConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_IsJailBreakingVocalizeCommand = GetConVarBool(convar)
}

public OnAllPluginsLoaded()
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			g_IsInGame[client] = true
		}
	}
}

public OnMapStart()
{
	g_MapStartTimeStamp = GetGameTime()
}

public OnMapEnd()
{
	g_HasAnySceneToProcess = false
	g_HasAnyVocalizeCommandsToProcess = false
	
	while (!IsStackEmpty(g_SceneStack))
	{
		PopStack(g_SceneStack)
	}
	
	ClearArray(g_VocalizeArray)
	
	for (new i = 1; i <= MAXENTITIES; i++)
	{
		SceneData_SetStage(i, SceneStages:0)
	}
	
	for (new i = 1; i <= MAXPLAYERS; i++)
	{
		g_PlayingScene[i] = INVALID_ENT_REFERENCE
	}
}

public OnClientPutInServer(client)
{
	if (client == 0)
	{
		return
	}
	
	g_IsInGame[client] = true
}

public OnClientDisconnect(client)
{
	if (client == 0)
	{
		return
	}
	
	g_IsInGame[client] = false
	g_PlayingScene[client] = INVALID_ENT_REFERENCE
}

public Action:OnVocalize_Command(client, const String:command[], argc)
{
	if (client <= 0 || client > MaxClients || !g_IsInGame[client] || argc == 0)
	{
		return Plugin_Continue
	}
	
	if (!g_IsL4D1 && argc != 2)
	{
		if (g_IsJailBreakingVocalizeCommand)
		{
			decl String:vocalize[128]
			GetCmdArg(1, vocalize, sizeof(vocalize))
			JailbreakVocalize(client, vocalize)
		}
		
		return Plugin_Handled
	}
	
#if DEBUG
	decl String:debugVocalize[128]
	GetCmdArgString(debugVocalize, sizeof(debugVocalize))
	static debugLastTick[MAXPLAYERS + 1]
	new debugTick = GetGameTickCount()
	Debug_PrintText("OnVocalize")
	Debug_PrintText(" - Vocalize \"%s\"", debugVocalize)
	Debug_PrintText(" - Tick %d (prev %d, diff %d)", debugTick, debugLastTick[client], debugTick - debugLastTick[client])
	debugLastTick[client] = debugTick
#endif
	
	decl String:vocalize[128]
	GetCmdArg(1, vocalize, sizeof(vocalize))
	new tick = GetGameTickCount()
	
	if (!g_VocalizeGotInitiator[client] || (g_VocalizeTick[client] > 0 && g_VocalizeTick[client] != tick))
	{
		g_VocalizeInitiator[client] = client
		
		// Automated smartlook uses 'auto' as map time stamp
		// Sorry L4D1 users out there, I can't detect if smartlook was automated for L4D1
		if (!g_IsL4D1 && argc > 1 && StrEqual(vocalize, VOCALIZE_SMARTLOOK_STRING, false))
		{
			decl String:time[32]
			GetCmdArg(2, time, sizeof(time))
			if (StrEqual(time, VOCALIZE_SMARTLOOK_TIMESTAMP, false))
			{
				g_VocalizeInitiator[client] = SCENE_INITIATOR_WORLD
			}
		}
	}
	
	strcopy(g_VocalizeString[client], MAX_VOCALIZE_LENGTH, vocalize)
	g_VocalizeTick[client] = tick
	
	new Action:result = Plugin_Continue
	Call_StartForward(g_FwdOnVocalizeCommand)
	Call_PushCell(client)
	Call_PushString(vocalize)
	Call_PushCell(g_VocalizeInitiator[client])
	Call_Finish(result)
	
	return (result == Plugin_Stop ? Plugin_Handled : Plugin_Continue)
}

public OnEntityCreated(entity, const String:classname[])
{
	if (entity <= 0 || entity > MAXENTITIES)
	{
		return
	}
	
	if (StrEqual(classname, SCENE_CLASSNAME))
	{
		SDKHook(entity, SDKHook_SpawnPost, OnPostSceneSpawn)
		SceneData_SetStage(entity, SceneStage_Created)
	}
}

public OnEntityDestroyed(entity)
{
	if (entity <= 0 || entity > MAXENTITIES)
	{
		return
	}
	
	new SceneStages:sceneStage = SceneData_GetStage(entity)
	if (sceneStage != SceneStages:0)
	{
		// For all intent and purposes, scene killed is the same as scene completion
		// The game automatically clean up all finished scenes
		
		if (sceneStage == SceneStage_Started)
		{
			SceneData_SetStage(entity, SceneStage_Completion)
		}
		
		SceneData_SetStage(entity, SceneStage_Killed)
		
		for (new actor = 1; actor <= MaxClients; actor++)
		{
			if (g_PlayingScene[actor] != entity)
			{
				continue
			}
			
			g_PlayingScene[actor] = INVALID_ENT_REFERENCE
			break
		}
	}
	
	SceneData_SetStage(entity, SceneStages:0)
}

// Predelay can be set here to change original delay however can not be captured as the game sets the delay in next frame
// Scene filename can not be changed post spawning (Or rather changes are not applied)
// "OnCompletion" never fires for "instanced_scripted_scene"
public OnPostSceneSpawn(entity)
{
	new actor = GetEntPropEnt(entity, Prop_Data, "m_hOwner")
	SceneData_SetActor(entity, actor)
	
	decl String:file[MAX_SCENEFILE_LENGTH]
	GetEntPropString(entity, Prop_Data, "m_iszSceneFile", file, MAX_SCENEFILE_LENGTH)
	SceneData_SetFile(entity, file)
	
	SceneData_SetPitch(entity, GetEntPropFloat(entity, Prop_Data, "m_fPitch"))
	
	if (actor > 0 && actor <= MaxClients)
	{
		if (g_VocalizeTick[actor] == GetGameTickCount())
		{
			SceneData_SetVocalize(entity, g_VocalizeString[actor])
			SceneData_SetInitiator(entity, g_VocalizeInitiator[actor])
			SceneData_SetPreDelay(entity, g_VocalizePreDelay[actor])
			SceneData_SetPitch(entity, g_VocalizePitch[actor])
		}
		
		ResetClientVocalizeData(actor)
	}
	
	SetEntPropFloat(entity, Prop_Data, "m_fPitch", SceneData_GetPitch(entity))
	SetEntPropFloat(entity, Prop_Data, "m_flPreDelay", SceneData_GetPreDelay(entity))
	
	PushStackCell(g_SceneStack, entity)
	g_HasAnySceneToProcess = true
	
	HookSingleEntityOutput(entity, "OnStart", OnSceneStart_EntOutput)
	HookSingleEntityOutput(entity, "OnCanceled", OnSceneCanceled_EntOutput)
	
	SceneData_SetStage(entity, SceneStage_Spawned)
}

static stock ResetClientVocalizeData(client)
{
	g_VocalizeTick[client] = 0
	g_VocalizeString[client] = "\0"
	g_VocalizeGotInitiator[client] = false
	g_VocalizeInitiator[client] = SCENE_INITIATOR_WORLD
	g_VocalizePreDelay[client] = DEFAULT_SCENE_PREDELAY
	g_VocalizePitch[client] = DEFAULT_SCENE_PITCH
}

/*
 * "instanced_scripted_scene" shares the same netclass, CSceneEntity, as "logic_choreographed_scene"
 * Dead or otherwise empty values
 * m_iszResponseContext		- Always empty string, whether talker files, player initiated or automated smartlook
 * m_bAutomated			- Always return 0, whether talker files or player initiated
 * m_hNotifySceneCompletion	- Neither entity or ref. Datamaps says 0 bytes
 * m_hActivator			- Entity ref, always return -1, whether talker files or player initiated
 */
public OnGameFrame()
{
	if (g_HasAnySceneToProcess)
	{
		decl scene
		while (!IsStackEmpty(g_SceneStack))
		{
			PopStackCell(g_SceneStack, scene)
			
			if (scene <= 0 || scene > MAXENTITIES || !IsValidEntity(scene))
			{
				continue
			}
			
			// Changed stage from spawned, most likely because the scene have started already or been cancelled
			if (SceneData_GetStage(scene) != SceneStage_Spawned)
			{
				continue
			}
			
			// Predelay can only be caught in OnGameFrame, 1 frame later after spawning. OnSceneStart resets it to 0.0.
			SceneData_SetPreDelay(scene, GetEntPropFloat(scene, Prop_Data, "m_flPreDelay"))
			
			SceneData_SetIsInFakePostSpawn(scene, false)
			SceneData_SetStage(scene, SceneStage_SpawnedPost)
		}
		g_HasAnySceneToProcess = false
	}
	
	if (g_HasAnyVocalizeCommandsToProcess)
	{
		new arraySize = GetArraySize(g_VocalizeArray)
		new currentTick = GetGameTickCount()
		decl client
		decl String:vocalize[MAX_VOCALIZE_LENGTH]
		decl Float:preDelay
		decl Float:pitch
		decl initiator
		decl tick
		
		for (new i = 0; i < arraySize; i += VOCALIZEARRAY_ARRAY_SIZE)
		{
			tick = GetArrayCell(g_VocalizeArray, i + VOCALIZEARRAY_INDEX_TICK)
			
			if (currentTick != tick)
			{
				continue
			}
			
			client = GetArrayCell(g_VocalizeArray, i + VOCALIZEARRAY_INDEX_CLIENT)
			GetArrayString(g_VocalizeArray, i + VOCALIZEARRAY_INDEX_VOCALIZE, vocalize, MAX_VOCALIZE_LENGTH)
			preDelay = Float:GetArrayCell(g_VocalizeArray, i + VOCALIZEARRAY_INDEX_PREDELAY)
			pitch = Float:GetArrayCell(g_VocalizeArray, i + VOCALIZEARRAY_INDEX_PITCH)
			initiator = GetArrayCell(g_VocalizeArray, i + VOCALIZEARRAY_INDEX_INITIATOR)
			
			Scene_Perform(client, vocalize, _, preDelay, pitch, initiator, true)
			
			for (new j = 0; j < VOCALIZEARRAY_ARRAY_SIZE; j++)
			{
				RemoveFromArray(g_VocalizeArray, i)
				arraySize--
			}
		}
		
		if (arraySize <= 0)
		{
			ClearArray(g_VocalizeArray)
			g_HasAnyVocalizeCommandsToProcess = false
		}
	}
}

public OnSceneStart_EntOutput(const String:output[], caller, activator, Float:delay)
{
	if (caller <= 0 || caller > MAXENTITIES || !IsValidEntity(caller))
	{
		return
	}
	
	decl String:file[MAX_SCENEFILE_LENGTH]
	SceneData_GetFile(caller, file, MAX_SCENEFILE_LENGTH)
	if (strlen(file) == 0)
	{
		return
	}
	
	SceneData_SetStartTimeStamp(caller, GetEngineTime())
	
	if (SceneData_GetStage(caller) == SceneStage_Spawned)
	{
		SceneData_SetIsInFakePostSpawn(caller, true)
		SceneData_SetStage(caller, SceneStage_SpawnedPost)
	}
	
	if (SceneData_GetStage(caller) == SceneStage_SpawnedPost)
	{
		new actor = SceneData_GetActor(caller)
		if (actor > 0 && actor <= MaxClients && g_IsInGame[actor])
		{
			g_PlayingScene[actor] = caller
		}
		
		SceneData_SetStage(caller, SceneStage_Started)
	}
}

public OnSceneCanceled_EntOutput(const String:output[], caller, activator, Float:delay)
{
	if (caller <= 0 || caller > MAXENTITIES || !IsValidEntity(caller))
	{
		return
	}
	
	for (new actor = 1; actor <= MaxClients; actor++)
	{
		if (g_PlayingScene[actor] == caller)
		{
			g_PlayingScene[actor] = INVALID_ENT_REFERENCE
			break
		}
	}
	
	SceneData_SetStage(caller, SceneStage_Cancelled)
}

static stock SceneStages:SceneData_GetStage(scene)
{
	return g_SceneDataArray[scene][SceneData_Stage]
}

public N_GetSceneStage(Handle:plugin, numParams)
{
	if (numParams == 0)
	{
		return _:0
	}
	
	new scene = GetNativeCell(1)
	if (scene <= 0 || scene > MAXENTITIES)
	{
		return _:0
	}
	
	return _:SceneData_GetStage(scene)
}

static stock SceneData_SetStage(scene, SceneStages:stage)
{
	g_SceneDataArray[scene][SceneData_Stage] = stage
	
	if (stage != SceneStages:0)
	{
		/* Uncomment for debug data galore */
// #if DEBUG
		// Debug_PrintText("OnSceneStageChanged -- Tick %d / Time %f", GetGameTickCount(), GetEngineTime())
		// Debug_PrintText(" - Scene: %d", scene)
		// Debug_PrintText(" - Stage: %d", stage)
		// Debug_PrintText(" - Start Time Stamp: %f", SceneData_GetStartTimeStamp(scene))
		
		// new debugOwner = SceneData_GetActor(scene)
		// new String:debugOwnerName[MAX_NAME_LENGTH + 1]
		// Format(debugOwnerName, sizeof(debugOwnerName), "Console")
		// if (debugOwner > 0 && debugOwner <= MaxClients && IsClientInGame(debugOwner))
		// {
			// GetClientName(debugOwner, debugOwnerName, sizeof(debugOwnerName))
		// }
		// Debug_PrintText(" - Actor: %s (%d)", debugOwnerName, debugOwner)
		
		// new debugInitiator = SceneData_GetInitiator(scene)
		// new String:debugInitiatorName[MAX_NAME_LENGTH + 1]
		// Format(debugInitiatorName, sizeof(debugInitiatorName), "WORLD")
		// if (debugInitiator > 0 && debugInitiator <= MaxClients && IsClientInGame(debugInitiator))
		// {
			// GetClientName(debugInitiator, debugInitiatorName, sizeof(debugInitiatorName))
		// }
		// else if (debugInitiator == SCENE_INITIATOR_PLUGIN)
		// {
			// Format(debugInitiatorName, sizeof(debugInitiatorName), "PLUGIN")
		// }
		// Debug_PrintText(" - Initiator: %s (%d)", debugInitiatorName, debugInitiator)
		
		// decl String:debugFile[MAX_SCENEFILE_LENGTH]
		// SceneData_GetFile(scene, debugFile, MAX_SCENEFILE_LENGTH)
		// Debug_PrintText(" - File: \"%s\"", debugFile)
		
		// decl String:debugVocalize[MAX_VOCALIZE_LENGTH]
		// SceneData_GetVocalize(scene, debugVocalize, MAX_VOCALIZE_LENGTH)
		// Debug_PrintText(" - Vocalize: \"%s\"", debugVocalize)
		
		// Debug_PrintText(" - Predelay: %f", SceneData_GetPreDelay(scene))
		// Debug_PrintText(" - Pitch: %f", SceneData_GetPitch(scene))
// #endif
		Call_StartForward(g_FwdOnSceneStageChanged)
		Call_PushCell(scene)
		Call_PushCell(stage)
		Call_Finish()
	}
	else
	{
		SceneData_SetIsInFakePostSpawn(scene, DEFAULT_SCENE_IS_IN_FAKE_POST_SPAWN)
		SceneData_SetStartTimeStamp(scene, DEFAULT_SCENE_START_TIMESTAMP)
		SceneData_SetActor(scene, DEFAULT_SCENE_ACTOR)
		SceneData_SetInitiator(scene, DEFAULT_SCENE_INITIATOR)
		SceneData_SetFile(scene, DEFAULT_SCENE_FILE)
		SceneData_SetVocalize(scene, DEFAULT_SCENE_VOCALIZE)
		SceneData_SetPreDelay(scene, DEFAULT_SCENE_PREDELAY)
		SceneData_SetPitch(scene, DEFAULT_SCENE_PITCH)
	}
}

static stock SceneData_SetIsInFakePostSpawn(scene, bool:fake)
{
	g_SceneDataArray[scene][SceneData_IsInFakePostSpawn] = fake
}

static stock bool:SceneData_InFakePostSpawn(scene)
{
	return g_SceneDataArray[scene][SceneData_IsInFakePostSpawn]
}

static stock Float:SceneData_GetStartTimeStamp(scene)
{
	return g_SceneDataArray[scene][SceneData_StartTimeStamp]
}

public N_GetSceneStartTimeStamp(Handle:plugin, numParams)
{
	if (numParams == 0)
	{
		return _:0.0
	}
	
	new scene = GetNativeCell(1)
	if (!IsValidScene(scene))
	{
		return _:0.0
	}
	
	return _:SceneData_GetStartTimeStamp(scene)
}

static stock SceneData_SetStartTimeStamp(scene, Float:timeStamp)
{
	g_SceneDataArray[scene][SceneData_StartTimeStamp] = timeStamp
}

static stock SceneData_GetActor(scene)
{
	return g_SceneDataArray[scene][SceneData_Actor]
}

public N_GetSceneActor(Handle:plugin, numParams)
{
	if (numParams == 0)
	{
		return _:0
	}
	
	new scene = GetNativeCell(1)
	if (!IsValidScene(scene))
	{
		return _:0
	}
	
	return SceneData_GetActor(scene)
}

public N_GetActorScene(Handle:plugin, numParams)
{
	if (numParams == 0)
	{
		return _:INVALID_ENT_REFERENCE
	}
	
	new actor = GetNativeCell(1)
	if (actor <= 0 || actor > MaxClients || !IsClientInGame(actor))
	{
		return _:INVALID_ENT_REFERENCE
	}
	
	return _:g_PlayingScene[actor]
}

static stock SceneData_SetActor(scene, actor)
{
	g_SceneDataArray[scene][SceneData_Actor] = actor
}

static stock SceneData_GetInitiator(scene)
{
	return g_SceneDataArray[scene][SceneData_Initiator]
}

public N_GetSceneInitiator(Handle:plugin, numParams)
{
	if (numParams == 0)
	{
		return _:0
	}
	
	new scene = GetNativeCell(1)
	if (!IsValidScene(scene))
	{
		return _:0
	}
	
	return SceneData_GetInitiator(scene)
}

static stock SceneData_SetInitiator(scene, initiator)
{
	g_SceneDataArray[scene][SceneData_Initiator] = initiator
}

static stock SceneData_GetFile(scene, String:dest[], len)
{
	return strcopy(dest, len, g_SceneDataArray[scene][SceneData_File])
}

public N_GetSceneFile(Handle:plugin, numParams)
{
	if (numParams != 3)
	{
		return _:0
	}
	
	new scene = GetNativeCell(1)
	if (!IsValidScene(scene))
	{
		return _:0
	}
	
	new len = GetNativeCell(3)
	new bytesWritten
	SetNativeString(2, g_SceneDataArray[scene][SceneData_File], len, _, bytesWritten)
	return bytesWritten
}

static stock SceneData_SetFile(scene, const String:file[])
{
	strcopy(g_SceneDataArray[scene][SceneData_File], MAX_SCENEFILE_LENGTH, file)
}

static stock SceneData_GetVocalize(scene, String:dest[], len)
{
	return strcopy(dest, len, g_SceneDataArray[scene][SceneData_Vocalize])
}

public N_GetSceneVocalize(Handle:plugin, numParams)
{
	if (numParams != 3)
	{
		return _:0
	}
	
	new scene = GetNativeCell(1)
	if (!IsValidScene(scene))
	{
		return _:0
	}
	
	new len = GetNativeCell(3)
	new bytesWritten
	SetNativeString(2, g_SceneDataArray[scene][SceneData_Vocalize], len, _, bytesWritten)
	return bytesWritten
}

static stock SceneData_SetVocalize(scene, const String:vocalize[])
{
	strcopy(g_SceneDataArray[scene][SceneData_Vocalize], MAX_VOCALIZE_LENGTH, vocalize)
}

static stock Float:SceneData_GetPreDelay(scene)
{
	return g_SceneDataArray[scene][SceneData_PreDelay]
}

public N_GetScenePreDelay(Handle:plugin, numParams)
{
	if (numParams == 0)
	{
		return _:0.0
	}
	
	new scene = GetNativeCell(1)
	if (!IsValidScene(scene))
	{
		return _:0.0
	}
	
	return _:SceneData_GetPreDelay(scene)
}

static stock SceneData_SetPreDelay(scene, Float:preDelay)
{
	g_SceneDataArray[scene][SceneData_PreDelay] = preDelay
}

public N_SetScenePreDelay(Handle:plugin, numParams)
{
	if (numParams != 2)
	{
		return
	}
	
	new scene = GetNativeCell(1)
	if (!IsValidScene(scene))
	{
		return
	}
	
	new Float:preDelay = GetNativeCell(2)
	SceneData_SetPreDelay(scene, preDelay)
	SetEntPropFloat(scene, Prop_Data, "m_flPreDelay", preDelay)
}

static stock Float:SceneData_GetPitch(scene)
{
	return g_SceneDataArray[scene][SceneData_Pitch]
}

public N_GetScenePitch(Handle:plugin, numParams)
{
	if (numParams == 0)
	{
		return _:0.0
	}
	
	new scene = GetNativeCell(1)
	if (!IsValidScene(scene))
	{
		return _:0.0
	}
	
	return _:SceneData_GetPitch(scene)
}

static stock SceneData_SetPitch(scene, Float:pitch)
{
	g_SceneDataArray[scene][SceneData_Pitch] = pitch
}

public N_SetScenePitch(Handle:plugin, numParams)
{
	if (numParams != 2)
	{
		return
	}
	
	new scene = GetNativeCell(1)
	if (!IsValidScene(scene))
	{
		return
	}
	
	new Float:pitch = GetNativeCell(2)
	SceneData_SetPreDelay(scene, pitch)
	SetEntPropFloat(scene, Prop_Data, "m_fPitch", pitch)
}

public N_CancelScene(Handle:plugin, numParams)
{
	if (numParams == 0)
	{
		return
	}
	
	new scene = GetNativeCell(1)
	if (scene <= 0 || scene > MAXENTITIES)
	{
		return
	}
	
	new SceneStages:sceneStage = SceneData_GetStage(scene)
	if (sceneStage == SceneStages:0)
	{
		return
	}
	else if (sceneStage == SceneStage_Started || (sceneStage == SceneStage_SpawnedPost && SceneData_InFakePostSpawn(scene)))
	{
		AcceptEntityInput(scene, "Cancel") // Cancel input can only be used post the start input send
	}
	else if (sceneStage != SceneStage_Cancelled && sceneStage != SceneStage_Completion && sceneStage != SceneStage_Killed)
	{
		AcceptEntityInput(scene, "Kill") 	/* Happens a frame later and Survivor sadly goes quiet if already in another scene.
							 * Not sure how to fix this. Need a way to prevent the Start input being send to 
							 * scenes */
		// RemoveEdict(scene) // This kills the server
	}
}

Scene_Perform(client, const String:vocalize[], const String:file[] = "", Float:preDelay = DEFAULT_SCENE_PREDELAY, Float:pitch = DEFAULT_SCENE_PITCH, initiator = SCENE_INITIATOR_PLUGIN, bool:vocalizeNow = false)
{
	if (strlen(file) > 0 && FileExists(file, true))
	{
		new scene = CreateEntityByName(SCENE_CLASSNAME)
		DispatchKeyValue(scene, "SceneFile", file)
		
		SetEntPropEnt(scene, Prop_Data, "m_hOwner", client)
		SceneData_SetActor(scene, client)
		SetEntPropFloat(scene, Prop_Data, "m_flPreDelay", preDelay)
		SceneData_SetPreDelay(scene, preDelay)
		SetEntPropFloat(scene, Prop_Data, "m_fPitch", pitch)
		SceneData_SetPitch(scene, pitch)
		
		SceneData_SetInitiator(scene, initiator)
		SceneData_SetVocalize(scene, vocalize)
		
		DispatchSpawn(scene)
		ActivateEntity(scene)
		AcceptEntityInput(scene, "Start", client, client)
	}
	else if (strlen(vocalize) > 0)
	{
		if (vocalizeNow)
		{
			g_VocalizeInitiator[client] = initiator
			g_VocalizeGotInitiator[client] = true
			g_VocalizePreDelay[client] = preDelay
			g_VocalizePitch[client] = pitch
			
			if (g_IsL4D1)
			{
				FakeClientCommandEx(client, VOCALIZE_COMMAND_L4D1_FORMATTING, VOCALIZE_COMMAND, vocalize)
			}
			else
			{
				JailbreakVocalize(client, vocalize)
			}
		}
		else
		{
			PushArrayCell(g_VocalizeArray, client)
			PushArrayString(g_VocalizeArray, vocalize)
			PushArrayCell(g_VocalizeArray, preDelay)
			PushArrayCell(g_VocalizeArray, pitch)
			PushArrayCell(g_VocalizeArray, initiator)
			PushArrayCell(g_VocalizeArray, GetGameTickCount() + VOCALIZE_MIN_TICK_SPACING - 1)
			g_HasAnyVocalizeCommandsToProcess = true
		}
	}
}

public N_PerformScene(Handle:plugin, numParams)
{
	if (numParams < 2)
	{
		return
	}
	
	new client = GetNativeCell(1)
	if (client <= 0 || client > MaxClients || !g_IsInGame[client] || L4DTeam:GetClientTeam(client) != L4DTeam_Survivor || !IsPlayerAlive(client))
	{
		return
	}
	
	new String:vocalize[MAX_VOCALIZE_LENGTH]
	new String:file[MAX_SCENEFILE_LENGTH]
	new Float:preDelay = DEFAULT_SCENE_PREDELAY
	new Float:pitch = DEFAULT_SCENE_PITCH
	new initiator = SCENE_INITIATOR_PLUGIN
	
	if (GetNativeString(2, vocalize, MAX_VOCALIZE_LENGTH) != SP_ERROR_NONE)
	{
		ThrowNativeError(0, "Failed to get \"vocalize\" parameter to perform scene!")
		return
	}
	
	if (numParams >= 3)
	{
		if (GetNativeString(3, file, MAX_SCENEFILE_LENGTH) != SP_ERROR_NONE)
		{
			ThrowNativeError(0, "Failed to get \"file\" parameter to perform scene!")
			return
		}
	}
	
	if (numParams >= 4)
	{
		preDelay = GetNativeCell(4)
	}
	
	if (numParams >= 5)
	{
		pitch = GetNativeCell(5)
	}
	
	if (numParams >= 5)
	{
		initiator = GetNativeCell(6)
	}
	
	Scene_Perform(client, vocalize, file, preDelay, pitch, initiator)
}

public N_PerformSceneEx(Handle:plugin, numParams)
{
	if (numParams < 2)
	{
		return
	}
	
	new client = GetNativeCell(1)
	if (client <= 0 || client > MaxClients || !g_IsInGame[client] || L4DTeam:GetClientTeam(client) != L4DTeam_Survivor || !IsPlayerAlive(client))
	{
		return
	}
	
	new String:vocalize[MAX_VOCALIZE_LENGTH]
	new String:file[MAX_SCENEFILE_LENGTH]
	new Float:preDelay = DEFAULT_SCENE_PREDELAY
	new Float:pitch = DEFAULT_SCENE_PITCH
	new initiator = SCENE_INITIATOR_PLUGIN
	
	if (GetNativeString(2, vocalize, MAX_VOCALIZE_LENGTH) != SP_ERROR_NONE)
	{
		ThrowNativeError(0, "Failed to get \"vocalize\" parameter to perform scene!")
		return
	}
	
	if (numParams >= 3)
	{
		if (GetNativeString(3, file, MAX_SCENEFILE_LENGTH) != SP_ERROR_NONE)
		{
			ThrowNativeError(0, "Failed to get \"file\" parameter to perform scene!")
			return
		}
	}
	
	if (numParams >= 4)
	{
		preDelay = GetNativeCell(4)
	}
	
	if (numParams >= 5)
	{
		pitch = GetNativeCell(5)
	}
	
	if (numParams >= 5)
	{
		initiator = GetNativeCell(6)
	}
	
	Scene_Perform(client, vocalize, file, preDelay, pitch, initiator, true)
}

static stock JailbreakVocalize(client, const String:vocalize[])
{
	// Vocalize command is formatted as "vocalize string #%.2f" or "vocalize PlayerThanks #23395"
	// Map time is formatted as "#%.2f" without period
	decl String:buffer[2][32];
	FloatToString((GetGameTime() - g_MapStartTimeStamp) + MAP_START_TIME_STAMP_OFFSET, buffer[0], 32) // Fill buffer[0] with time since map start
	ExplodeString(buffer[0], ".", buffer, 2, 32) // Explode buffer[0] to remove the period
	Format(buffer[1], 2, "%s\0", buffer[1][0]) // Fix buffer[1] to only contain the last 2 digits of map time
	FakeClientCommandEx(client, VOCALIZE_COMMAND_L4D2_FORMATTING, VOCALIZE_COMMAND, vocalize, buffer[0], buffer[1]) // Resend the vocalize command with map time
}

#if DEBUG
stock Debug_PrintText(const String:format[], any:...)
{
	decl String:buffer[256]
	VFormat(buffer, sizeof(buffer), format, 2)
	
	LogMessage(buffer)
	
	new AdminId:adminId
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || IsFakeClient(client))
		{
			continue
		}
		
		adminId = GetUserAdmin(client)
		if (adminId == INVALID_ADMIN_ID || !GetAdminFlag(adminId, Admin_Root))
		{
			continue
		}
		
		PrintToChat(client, "[%s] %s", DEBUG_TAG, buffer)
	}
}
#endif
