#if defined _sceneprocessor_included
 #endinput
#endif
#define _sceneprocessor_included

#define SCENEPROCESSOR_VERSION "1.0.1"
#define SCENEPROCESSOR_LIBRARY "sceneprocessor"

#define MAX_SCENEFILE_LENGTH	PLATFORM_MAX_PATH // Maximum length of scene files
#define MAX_VOCALIZE_LENGTH	128 // Maximum length of vocalize strings

#define SCENE_INITIATOR_WORLD	0	/* All scenes created by the map (such as landmarks, "Down this way", "Through here") 
					 * and by the game (such as team mate actions, "Let me heal you up", "Help I'm falling")
					 * are marked as started by the world, or entity index 0. */
#define SCENE_INITIATOR_PLUGIN	-1	/* All scenes started by the Scene Processor are by default marked as started by plugin or
					 * entity index -1. This can be changed in the PerformScene function call. */

#define DEFAULT_SCENE_PREDELAY 0.0	/* By default all scenes occur the instant they are created */
#define DEFAULT_SCENE_PITCH 1.0		/* By default all scenes have a pitch of 1.0, or as they are normally heard. 2.0 will make
					 * it sounds twice as fast but in a high pitched voice. 0.5 will be half the normal speed 
					 * and with low pitched voice. */

enum SceneStages
{
	SceneStage_Created = 1,		/* When scene is created. Contains no information about the scene that is about to
					 * be played out. Guaranteed to occur. */
	
	SceneStage_Spawned,		/* When scene is spawned. Everything is filled in but the pre-delay! Change scene
					 * pitch and pre-delay here. */
	
	SceneStage_SpawnedPost,		/* Post scene spawned frame. Pre-delay is now filled out. Pre-delay can be changed
					 * here if the scene originally has a pre-delay greater than 0.0. */
	
	SceneStage_Started,		/* When scene is started. Time stamp is set. */
	
	SceneStage_Cancelled,		/* When scene is cancelled. Happens if the Survivor was interrupted by another scene
					 * or the scene was cancelled post starting. */
	
	SceneStage_Completion,		/* When scene is completed. Happens if the Survivor gets to fully perform the scene
					 * with no interruptions or cancellation. Entity index is no longer valid but
					 * information is retained. */
	
	SceneStage_Killed		/* When scene is killed. Entity index is no longer valid but information is retained
					 * until end of forward. Guaranteed to occur */
}

/**
 * Called on scene stage changed.
 *
 * @param scene		Scene entity index.
 * @param stage		SceneStages value.
 * @noreturn
 */
forward OnSceneStageChanged(scene, SceneStages:stage);

/**
 * Called on vocalize command send.
 *
 * @remarks See SCENE_INITIATOR_WORLD and SCENE_INITIATOR_PLUGIN for 
 * non-client initiated vocalizes.
 *
 * @param client	Index of player sending vocalize command.
 * @param vocalize	String of what player wish to vocalize, as typed.
 * @param initiator	Index of entity initiated vocalize command.
 * @return		Plugin_Stop to stop vocalize command.
 *			Plugin_Continue to allow vocalize command.
 */
forward Action:OnVocalizeCommand(client, const String:vocalize[], initiator);

/**
 * Returns scene stage.
 *
 * @param scene		Scene entity index.
 * @return		SceneStages value or 0 if scene is not valid.
 */
native SceneStages:GetSceneStage(scene);

/**
 * Returns whether scene is valid as a scene.
 *
 * @remarks The scene entity index may still be invalid.
 *
 * @param scene		Scene entity index.
 * @return		True if a valid scene, false otherwise.
 */
stock bool:IsValidScene(scene)
{
	return GetSceneStage(scene) != SceneStages:0
}

/**
 * Returns scene start time stamp, in engine time.
 *
 * @param scene		Scene entity index.
 * @return		Scene start engine time stamp. 0.0 if the scene has not started yet.
 */
native Float:GetSceneStartTimeStamp(scene);

/**
 * Returns scene actor.
 *
 * @param scene		Scene entity index.
 * @return		Actor of the scene. 0 if no one is playing it.
 */
native GetActorFromScene(scene);

/**
 * Returns actor's scene.
 *
 * @remarks Only returns scene if it is currently being played out.
 *
 * @param actor		Client index of actor.
 * @return		Scene entity index. INVALID_ENT_REFERENCE if actor currently aren't playing.
 */
native GetSceneFromActor(actor);

/**
 * Returns whether actor is already playing a scene.
 *
 * @param actor		Client index of actor.
 * @return		True if actor is busy, false otherwise.
 */
stock bool:IsActorBusy(actor)
{
	return GetSceneFromActor(actor) != INVALID_ENT_REFERENCE
}

/**
 * Returns scene initiator.
 *
 * @remarks See SCENE_INITIATOR_WORLD and SCENE_INITIATOR_PLUGIN for automated
 * scenes.
 *
 * @param scene		Scene entity index.
 * @return		Initiator of the scene.
 */
native GetSceneInitiator(scene);

/**
 * Returns scene file.
 *
 * @param scene		Scene entity index.
 * @param dest		Destination string buffer to copy to.
 * @param len		Destination buffer length (includes null terminator).
 * @return		Number of bytes written
 */
native GetSceneFile(scene, String:dest[], len);

/**
 * Returns scene vocalize.
 *
 * @remarks Will only contain the vocalize string if the scene was started by
 * the client them self. Otherwise empty.
 *
 * @param scene		Scene entity index.
 * @param dest		Destination string buffer to copy to.
 * @param len		Destination buffer length (includes null terminator).
 * @return		Number of bytes written
 */
native GetSceneVocalize(scene, String:dest[], len);

/**
 * Returns scene pre-delay.
 *
 * @remarks Sadly pre-delay is first fetched on SceneStage_SpawnedPost where
 * altering the pre-delay with SetScenePreDelay might already be too late.
 *
 * @param scene		Scene entity index.
 * @return		Scene pre-delay in seconds.
 */
native Float:GetScenePreDelay(scene);

/**
 * Sets scene pre-delay.
 *
 * @remarks Pre-delay can be set on SceneStage_Spawned and sometimes (!) on 
 * SceneStage_SpawnedPost depending on whether the scene originally has a 
 * pre-delay. Once SceneStage_Started fires pre-delay is no longer obeyed.
 *
 * @param scene		Scene entity index.
 * @param preDelay	Scene pre-delay in seconds.
 * @noreturn
 */
native SetScenePreDelay(scene, Float:preDelay);

/**
 * Returns scene pitch.
 *
 * @param scene		Scene entity index.
 * @return		Scene pitch.
 */
native Float:GetScenePitch(scene);

/**
 * Sets scene pitch
 *
 * @remarks Scene pitch can be set on SceneStage_Spawned and 
 * SceneStage_SpawnedPost. Setting pitch post spawning results in weird
 * settings such as some clients hearing 1.13 as double as fast instead of 2.0.
 *
 * @param scene		Scene entity index.
 * @param pitch		Scene pitch.
 * @noreturn
 */
native SetScenePitch(scene, Float:pitch);

/**
 * Cancels scene.
 *
 * @remarks Can be used at all scene stages. Scene is validated before sending
 * the cancel input.
 *
 * @param scene		Scene entity index.
 * @noreturn
 */
native CancelScene(scene);

/**
 * Performs a scene.
 *
 * @remarks Scene file is used before vocalize string however vocalize string
 * is still saved to scene entity index and can be retrieved for later usage.
 * If vocalize string is used, it is delayed for a short while in order to
 * work if used inside of OnSceneStageChanged. See PerformSceneEx to avoid 
 * this delay.
 *
 * @param client	Client index.
 * @param vocalize	Vocalize string.
 * @param file		Scene file.
 * @param preDelay	Scene pre-delay.
 * @param pitch		Scene pitch.
 * @param initiator	Initiator of the scene.
 * @noreturn
 */
native PerformScene(client, const String:vocalize[], const String:file[] = "", Float:preDelay = DEFAULT_SCENE_PREDELAY, Float:pitch = DEFAULT_SCENE_PITCH, initiator = SCENE_INITIATOR_PLUGIN);

/**
 * Performs a scene.
 *
 * @remarks Works the same way as PerformScene however there is no delay when
 * using vocalize string. Not recommend to use inside OnSceneStageChanged if 
 * vocalizes needs to get through.
 *
 * @param client	Client index.
 * @param vocalize	Vocalize string.
 * @param file		Scene file.
 * @param preDelay	Scene pre-delay.
 * @param pitch		Scene pitch.
 * @param initiator	Initiator of the scene.
 * @noreturn
 */
native PerformSceneEx(client, const String:vocalize[], const String:file[] = "", Float:preDelay = DEFAULT_SCENE_PREDELAY, Float:pitch = DEFAULT_SCENE_PITCH, initiator = SCENE_INITIATOR_PLUGIN);

public SharedPlugin:__pl_sceneproces = 
{
	name = "sceneprocessor",
	file = "sceneprocessor.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_sceneproces_SetNTVOptional()
{
	MarkNativeAsOptional("GetSceneStage");
	MarkNativeAsOptional("GetSceneStartTimeStamp");
	MarkNativeAsOptional("GetActorFromScene");
	MarkNativeAsOptional("GetSceneFromActor");
	MarkNativeAsOptional("GetSceneInitiator");
	MarkNativeAsOptional("GetSceneFile");
	MarkNativeAsOptional("GetSceneVocalize");
	MarkNativeAsOptional("GetScenePreDelay");
	MarkNativeAsOptional("SetScenePreDelay");
	MarkNativeAsOptional("GetScenePitch");
	MarkNativeAsOptional("SetScenePitch");
	MarkNativeAsOptional("CancelScene");
	MarkNativeAsOptional("PerformScene");
	MarkNativeAsOptional("PerformSceneEx");
}
#endif
