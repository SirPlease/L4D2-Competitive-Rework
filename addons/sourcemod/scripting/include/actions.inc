#if defined _actions_included
 #endinput
#endif

#define _actions_included

#define ACTION_NAME_LENGTH 32

enum QueryResultType
{
	ANSWER_NO,
	ANSWER_YES,
	ANSWER_UNDEFINED
};

enum ActionResultType
{ 
	CONTINUE,			// continue executing this action next frame - nothing has changed
	CHANGE_TO,			// change actions next frame
	SUSPEND_FOR,		// put the current action on hold for the new action
	DONE,				// this action has finished, resume suspended action
	SUSTAIN,			// for use with event handlers - a way to say "It's important to keep doing what I'm doing"
};

enum EventResultPriorityType
{
	RESULT_NONE,		// no result
	RESULT_TRY,			// use this result, or toss it out, either is ok
	RESULT_IMPORTANT,	// try extra-hard to use this result
	RESULT_CRITICAL		// this result must be used - emit an error if it can't be
};

enum BehaviorAction
{
	INVALID_ACTION
};

/**
 * @brief Callback called for every entity action.
 *
 * @param action		Action address
 *
 * @noreturn
 */
typedef ActionsIteratorCallback = function void (BehaviorAction action);

/**
 * @brief Called whenever action is created
 *
 * @param action			Created action address
 * @param actor				Actor of the action
 * @param name				Name of the action
 *
 * @noreturn
 */
forward void OnActionCreated( BehaviorAction action, int actor, const char[] name );

/**
 * @brief Called whenever action is destroyed
 * @note  You are in action destructor!
 *
 * @param action			Destroyed action address
 * @param actor				Actor of the action
 * @param name				Name of the action
 *
 * @noreturn
 */
forward void OnActionDestroyed( BehaviorAction action, int actor, const char[] name );

methodmap ActionResult
{
	/**
 	* @brief Gets action result reason
 	*
 	* @param destination		Buffer to store reason
 	* @param maxlength			Length of the buffer
 	*
 	* @noreturn
 	*/
	public native void GetReason( char[] destination, int maxlength );

	/**
 	* @brief Sets action result reason
 	*
 	* @param reason			String with reason
 	*
 	* @noreturn
 	*/
	public native void SetReason( const char[] reason );
	
	/**
 	* @brief Property to get/set result type
 	*
 	* @return					Result type (see ActionResultType)
 	*/
	property ActionResultType type
	{
		public native get();
		public native set(ActionResultType type);
	}
	
	/**
 	* @brief Property to get/set result action
 	*
 	* @return					Result action
 	*/
	property BehaviorAction action
	{
		public native get();
		public native set(BehaviorAction action);
	}
	
	/**
 	* @brief Checks if result is requesting change
 	*
 	* @return					true if it is requesting, false otherwise
 	*/
	public bool IsRequestingChange()
	{
		ActionResultType type = this.type;
		
		return (type == CHANGE_TO || type == SUSPEND_FOR || type == DONE);
	}
}

methodmap ActionDesiredResult < ActionResult
{
	/**
 	* @brief Property to get/set result priority
 	*
 	* @return					Result priority
 	*/
	property EventResultPriorityType priority
	{
		public native get();
		public native set(EventResultPriorityType priority);
	}
}

typeset ActionHandler
{
	/* OnStart, OnSuspend, OnResume */
	function Action (BehaviorAction action, int actor, BehaviorAction priorAction, ActionResult result);

	/* OnUpdate */
	function Action (BehaviorAction action, int actor, float interval, ActionResult result);

	/* OnEnd */
	function void (BehaviorAction action, int actor, BehaviorAction priorAction, ActionResult result);

	/* InitialContainedAction */
	function Action (BehaviorAction action, int actor, BehaviorAction& action);

	/* OnLeaveGround, OnLandOnGround, OnDrop, OnShoved, OnBlinded, OnHitByVomitJar, OnCommandAttack */
	function Action (BehaviorAction action, int actor, int entity, ActionDesiredResult result);

	/* OnContact */
	function Action (BehaviorAction action, int actor, int entity, Address trace, ActionDesiredResult result);

	/* OnMoveToSuccess */
	function Action (BehaviorAction action, int actor, Address path, ActionDesiredResult result);
	
	/* OnMoveToFailure */
	function Action (BehaviorAction action, int actor, Address path, any type, ActionDesiredResult result);

	/* OnStuck, OnUnStuck, OnPostureChanged, OnIgnite, OnModelChanged, OnEnteredSpit, OnCommandAssault, OnCommandResume  */
	function Action (BehaviorAction action, int actor, ActionDesiredResult result);

	/* OnAnimationActivityComplete, OnAnimationActivityInterrupted */
	function Action (BehaviorAction action, int actor, int activity, ActionDesiredResult result);

	/* OnAnimationEvent */
	function Action (BehaviorAction action, int actor, Address animevent, ActionDesiredResult result);

	/* OnInjured, OnKilled */
	function Action (BehaviorAction action, int actor, Address takedamageinfo, ActionDesiredResult result);

	/* OnOtherKilled */
	function Action (BehaviorAction action, int actor, int other, Address takedamageinfo, ActionDesiredResult result);

	/* OnSight, OnLostSight, OnThreatChanged */
	function Action (BehaviorAction action, int actor, int entity, ActionDesiredResult result);

	/* OnSound */
	function Action (BehaviorAction action, int actor, int entity, const float pos[3], Address keyvalues, ActionDesiredResult result);

	/* OnSpokeConcept */
	function Action (BehaviorAction action, int actor, int who, Address concept, Address response, Address unknown, ActionDesiredResult result);
	
	/* OnNavAreaChanged */
	function Action (BehaviorAction action, int actor, Address newArea, Address oldArea, ActionDesiredResult result);
	
	/* OnPickUp */
	function Action (BehaviorAction action, int actor, int entity, int giver, ActionDesiredResult result);

	/* OnCommandApproachVector */
	function Action (BehaviorAction action, int actor, const float pos[3], float range, ActionDesiredResult result);

	/* OnCommandApproachEntity */
	function Action (BehaviorAction action, int actor, int goal, ActionDesiredResult result);

	/* OnCommandRetreat */
	function Action (BehaviorAction action, int actor, int threat, float range, ActionDesiredResult result);

	/* OnCommandPause */
	function Action (BehaviorAction action, int actor, float duration, ActionDesiredResult result);

	/* OnCommandString */
	function Action (BehaviorAction action, int actor, const char[] command, ActionDesiredResult result);

	/* IsAbleToBlockMovementOf */
	function Action (BehaviorAction action, int actor, Address nextbot, ActionDesiredResult result);

	/* OnTerritoryContested, OnTerritoryCaptured, OnTerritoryLost */
	function Action (BehaviorAction action, int actor, int territory);

	/* OnWin, OnLose */
	function Action (BehaviorAction action, int actor);

	/* OnWeaponFired */
	function Action (BehaviorAction action, int actor, int who, int weapon);

	/* OnActorEmoted */
	function Action (BehaviorAction action, int actor, int emoter, int emote);
}

typeset ActionContextualHandler
{
	/* ShouldPickUp, IsHindrance*/
	function Action (BehaviorAction action, Address nextbot, int entity, QueryResultType& result);
	
	/* ShouldHurry, ShouldRetreat */
	function Action (BehaviorAction action, Address nextbot, QueryResultType& result);

	/* ShouldAttack */
	function Action (BehaviorAction action, Address nextbot, Address knownEntity, QueryResultType& result);

	/* SelectTargetPoint */
	function Action (BehaviorAction action, Address nextbot, int entity, float vec[3]);

	/* IsPositionAllowed */
	function Action (BehaviorAction action, Address nextbot, float vec[3], QueryResultType& result);
	
	/* QueryCurrentPath */
	function Action (BehaviorAction action, Address nextbot, Address& path);
	
	/* SelectMoreDangerousThreat */
	function Action (BehaviorAction action, Address nextbot, int entity, Address threat1, Address threat2, Address& knownEntity);
}

methodmap ActionsManager
{
	/**
 	* @brief Creates action template with given name
	* @note  Use this to create your own actions
 	*
 	* @param name			New action name
 	*
 	* @return				Action address
 	*/
	public static native BehaviorAction Create( const char[] name );
	
	/**
 	* @brief Allocates memory with given size
	* @note  Use this with game action constructor to create game actions 
 	*
 	* @param size			Size to allocate
 	*
 	* @return				Allocated memory start address
 	*/
	public static native BehaviorAction Allocate( int size );
	
	/**
 	* @brief Deallocates memory
	* @note  Actually used only for deallocating actions
 	*
 	* @param action			Action to deallocate
 	*
 	* @noreturn
 	*/
	public static native void Deallocate( BehaviorAction action );
	
	/**
 	* @brief Used to iterate over all entity actions
 	*
 	* @param entity			Entity index
 	* @param callback		Iterator callback 
 	*
 	* @return				Number of actions entity has
 	*/
	public static native int Iterator( int entity, ActionsIteratorCallback callback = INVALID_FUNCTION );
	
	/**
 	* @brief Returns entity action with given name
 	*
 	* @param entity			Entity index
 	* @param name			Action name to find 
 	*
 	* @return				Action address, INVALID_ACTION if not found
 	*/
	public static native BehaviorAction GetAction( int entity, const char[] name );
}

methodmap BehaviorAction
{
	public BehaviorAction(any action)
	{
		return view_as<BehaviorAction>(action);
	}

	/**
 	* @brief Stores pending event result
	* @note This is almost same as changing result via event handler but this one violates semantics
 	*
 	* @param type			Result type (See ActionResultType)
 	* @param action			Action 
 	* @param priority		Priority 
 	* @param reason			Reason 
 	*
	* @error				Invalid action passed
 	* @noreturn
 	*/
	public native void StorePendingEventResult( ActionResultType type = CONTINUE, BehaviorAction action = INVALID_ACTION, EventResultPriorityType priority = RESULT_TRY, const char[] reason = NULL_STRING );
	
	/**
 	* @brief Gets action name 
 	*
 	* @param destination	Buffer to store name 
 	* @param maxlength		Buffer length
 	*
	* @error				Invalid action passed
 	* @return				Number of bytes written?
 	*/
	public native int GetName( char[] destination, int maxlength = ACTION_NAME_LENGTH );

	/**
 	* @brief Continue executing this action 
 	*
	* @error				Invalid action passed
 	*/
	public native Action Continue();

	/**
 	* @brief Change to new action
 	*
 	* @param action			Action to change to 
 	* @param reason			Reason for a changing
	*
	* @error				Invalid action passed
 	*/
	public native Action ChangeTo(BehaviorAction action, const char[] reason = NULL_STRING);

	/**
 	* @brief Suspend the current action for the new action 
	*
 	* @param action			Action what will suspend us 
 	* @param reason			Reason for a suspending
	*
	* @error				Invalid action passed
 	*/
	public native Action SuspendFor(BehaviorAction action, const char[] reason = NULL_STRING);

	/**
 	* @brief Finish current action
	*
 	* @param reason			Reason why we finished
 	*
	* @error				Invalid action passed
 	*/
	public native Action Done(const char[] reason = NULL_STRING);

	/**
 	* @brief Continue executing this action 
 	*
 	* @param priority 		Priority to use this result
	*
	* @error				Invalid action passed
 	*/
	public native Action TryContinue(EventResultPriorityType priority = RESULT_TRY);

	/**
 	* @brief Change to new action
 	*
 	* @param action			Action to change to 
 	* @param priority 		Priority to use this result
 	* @param reason			Reason for a changing
	*
	* @error				Invalid action passed
 	*/
	public native Action TryChangeTo(BehaviorAction action, EventResultPriorityType priority = RESULT_TRY, const char[] reason = NULL_STRING);

	/**
 	* @brief Suspend the current action for the new action 
	*
 	* @param action			Action what will suspend us 
 	* @param priority 		Priority to use this result
 	* @param reason			Reason for a suspending
	*
	* @error				Invalid action passed
 	*/
	public native Action TrySuspendFor(BehaviorAction action, EventResultPriorityType priority = RESULT_TRY, const char[] reason = NULL_STRING);

	/**
 	* @brief Finish current action 
	*
 	* @param priority 		Priority to use this result
 	* @param reason			Reason why we finished
 	*
	* @error				Invalid action passed
 	*/
	public native Action TryDone(EventResultPriorityType priority = RESULT_TRY, const char[] reason = NULL_STRING);

	/**
 	* @brief Simple wrapper to get action data 
 	*
 	* @param int			Offset to data 
 	* @param type			How many bytes read (See NumberType)
 	*
 	* @return				Stored data
 	*/
	public any Get( int offset, NumberType type = NumberType_Int32 )
	{
		return view_as<any>(LoadFromAddress(view_as<Address>(this) + view_as<Address>(offset), type));
	}
	
	/**
 	* @brief Simple wrapper to set action data 
 	*
 	* @param int			Offset to data 
 	* @param data			Data to set
 	* @param type			How many bytes set (See NumberType)
 	*
 	* @noreturn
 	*/
 #if SOURCEMOD_V_MINOR < 11
	public void Set( int offset, any data, NumberType type = NumberType_Int32 )
	{
		StoreToAddress(view_as<Address>(this) + view_as<Address>(offset), data, type);
	}
 #else
	public void Set( int offset, any data, NumberType type = NumberType_Int32, bool updateMemAccess = false )
	{
		StoreToAddress(view_as<Address>(this) + view_as<Address>(offset), data, type, updateMemAccess);
	}
 #endif	
	// ====================================================================================================
	// ACTION PROPERTIES
	// ====================================================================================================
	
	/**
 	* @brief Property to get/set parent action
 	*
 	* @return				Parent action 
 	*/
	property BehaviorAction Parent
	{
		public native get();
	}
	
	/**
 	* @brief Property to get/set child action
 	*
 	* @return				Child action
 	*/
	property BehaviorAction Child
	{
		public native get();
	}
	
	/**
 	* @brief Property to get/set "under" action
	* @note if we are suspender then this will return a suspended action
 	*
 	* @return				Under action
 	*/
	property BehaviorAction Under
	{
		public native get();
	}
	
	/**
 	* @brief Property to get/set "above" action
	* @note if we are suspended action then this will return a suspender
 	*
 	* @return				Above action
 	*/
	property BehaviorAction Above
	{
		public native get();
	}
	
	/**
 	* @brief Property to get actor of action
 	* @note  returns 0 if action hasn't been started yet
	* 
 	* @return				Action actor
 	*/
	property int Actor
	{
		public native get();
	}
	
	/**
 	* @brief Property to get/set suspended state of action
	* 
 	* @return				true if suspended, false otherwise
 	*/
	property bool IsSuspended
	{
		public native get();
		public native set(bool suspended);
	}
	
	/**
 	* @brief Property to get/set started state of action
	* @note if this returns true then OnStart handled has already been called 
	* 
 	* @return				true if started, false otherwise
 	*/
	property bool IsStarted
	{
		public native get();
		public native set(bool started);
	}
	
	// ====================================================================================================
	// ACTION PRE CONTEXTUAL HANDLERS
	// ====================================================================================================

	property ActionContextualHandler ShouldPickUp
	{
		public native set(ActionContextualHandler func);
	}

	property ActionContextualHandler ShouldHurry
	{
		public native set(ActionContextualHandler func);
	}

	property ActionContextualHandler IsHindrance
	{
		public native set(ActionContextualHandler func);
	}

	property ActionContextualHandler SelectTargetPoint
	{
		public native set(ActionContextualHandler func);
	}

	property ActionContextualHandler IsPositionAllowed
	{
		public native set(ActionContextualHandler func);
	}

	property ActionContextualHandler QueryCurrentPath
	{
		public native set(ActionContextualHandler func);
	}

	property ActionContextualHandler SelectMoreDangerousThreat
	{
		public native set(ActionContextualHandler func);
	}

	property ActionContextualHandler ShouldRetreat
	{
		public native set(ActionContextualHandler func);
	}

	property ActionContextualHandler ShouldAttack
	{
		public native set(ActionContextualHandler func);
	}

	// ====================================================================================================
	// ACTION POST CONTEXTUAL HANDLERS
	// ====================================================================================================

	property ActionContextualHandler ShouldPickUpPost
	{
		public native set(ActionContextualHandler func);
	}

	property ActionContextualHandler ShouldHurryPost
	{
		public native set(ActionContextualHandler func);
	}

	property ActionContextualHandler IsHindrancePost
	{
		public native set(ActionContextualHandler func);
	}

	property ActionContextualHandler SelectTargetPointPost
	{
		public native set(ActionContextualHandler func);
	}

	property ActionContextualHandler IsPositionAllowedPost
	{
		public native set(ActionContextualHandler func);
	}

	property ActionContextualHandler QueryCurrentPathPost
	{
		public native set(ActionContextualHandler func);
	}

	property ActionContextualHandler SelectMoreDangerousThreatPost
	{
		public native set(ActionContextualHandler func);
	}
	property ActionContextualHandler ShouldRetreatPost
	{
		public native set(ActionContextualHandler func);
	}
	
	property ActionContextualHandler ShouldAttackPost
	{
		public native set(ActionContextualHandler func);
	}

	// ====================================================================================================
	// ACTION PRE EVENT HANDLERS
	// ====================================================================================================

	property ActionHandler OnStart
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnUpdate
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnEnd
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnSuspend
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnResume
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnInitialContainedAction
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnLeaveGround
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnLandOnGround
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnContact
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnMoveToSuccess
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnMoveToFailure
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnStuck
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnUnStuck
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnPostureChanged
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnAnimationActivityComplete
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnAnimationActivityInterrupted
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnAnimationEvent
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnIgnite
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnInjured
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnKilled
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnOtherKilled
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnSight
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnLostSight
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnThreatChanged
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnSound
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnSpokeConcept
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnNavAreaChanged
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnModelChanged
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnPickUp
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnShoved
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnBlinded
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnEnteredSpit
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnHitByVomitJar
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnCommandAttack
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnCommandAssault
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnCommandApproachV
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnCommandApproachE
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnCommandRetreat
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnCommandPause
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnCommandResume
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnCommandString
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler IsAbleToBlockMovementOf
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnTerritoryContested
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnTerritoryCaptured
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnTerritoryLost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnWin
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnWeaponFired
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnActorEmoted
	{
		public native set(ActionHandler func);
	}

	// ====================================================================================================
	// ACTION POST EVENT HANDLERS
	// ====================================================================================================
	
	property ActionHandler OnStartPost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnUpdatePost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnEndPost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnSuspendPost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnResumePost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnInitialContainedActionPost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnLeaveGroundPost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnLandOnGroundPost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnContactPost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnMoveToSuccessPost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnMoveToFailurePost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnStuckPost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnUnStuckPost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnPostureChangedPost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnAnimationActivityCompletePost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnAnimationActivityInterruptedPost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnAnimationEventPost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnIgnitePost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnInjuredPost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnKilledPost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnOtherKilledPost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnSightPost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnLostSightPost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnThreatChangedPost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnSoundPost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnSpokeConceptPost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnNavAreaChangedPost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnModelChangedPost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnPickUpPost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnShovedPost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnBlindedPost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnEnteredSpitPost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnHitByVomitJarPost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnCommandAttackPost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnCommandAssaultPost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnCommandApproachVPost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnCommandApproachEPost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnCommandRetreatPost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnCommandPausePost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnCommandResumePost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnCommandStringPost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler IsAbleToBlockMovementOfPost
	{
		public native set(ActionHandler func);
	}

		property ActionHandler OnTerritoryContestedPost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnTerritoryCapturedPost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnTerritoryLostPost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnWinPost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnWeaponFiredPost
	{
		public native set(ActionHandler func);
	}
	
	property ActionHandler OnActorEmotedPost
	{
		public native set(ActionHandler func);
	}
};

// ====================================================================================================
// PL NTV
// ====================================================================================================

public Extension __ext_actions = 
{
    name = "Actions",
    file = "actions.ext",
    autoload = 1,
#if defined REQUIRE_EXTENSIONS
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_EXTENSIONS
public void __ext_actions_SetNTVOptional()
{
	MarkNativeAsOptional("ActionResult.GetReason");
	MarkNativeAsOptional("ActionResult.SetReason");
	MarkNativeAsOptional("ActionResult.type.get");
	MarkNativeAsOptional("ActionResult.type.set");
	MarkNativeAsOptional("ActionResult.action.get");
	MarkNativeAsOptional("ActionResult.action.set");
	MarkNativeAsOptional("ActionDesiredResult.priority.get");
	MarkNativeAsOptional("ActionDesiredResult.priority.set");
	MarkNativeAsOptional("ActionsManager.Create");
	MarkNativeAsOptional("ActionsManager.Allocate");
	MarkNativeAsOptional("ActionsManager.Deallocate");
	MarkNativeAsOptional("ActionsManager.Iterator");
	MarkNativeAsOptional("ActionsManager.GetAction");

	MarkNativeAsOptional("BehaviorAction.Continue");
	MarkNativeAsOptional("BehaviorAction.ChangeTo");
	MarkNativeAsOptional("BehaviorAction.SuspendFor");
	MarkNativeAsOptional("BehaviorAction.Done");
	MarkNativeAsOptional("BehaviorAction.TryContinue");
	MarkNativeAsOptional("BehaviorAction.TryChangeTo");
	MarkNativeAsOptional("BehaviorAction.TrySuspendFor");
	MarkNativeAsOptional("BehaviorAction.TryDone");
	
	MarkNativeAsOptional("BehaviorAction.StorePendingEventResult");
	MarkNativeAsOptional("BehaviorAction.GetName");
	MarkNativeAsOptional("BehaviorAction.Parent.get");
	MarkNativeAsOptional("BehaviorAction.Child.get");
	MarkNativeAsOptional("BehaviorAction.Under.get");
	MarkNativeAsOptional("BehaviorAction.Above.get");
	MarkNativeAsOptional("BehaviorAction.Actor.get");
	MarkNativeAsOptional("BehaviorAction.IsSuspended.get");
	MarkNativeAsOptional("BehaviorAction.IsSuspended.set");
	MarkNativeAsOptional("BehaviorAction.IsStarted.get");
	MarkNativeAsOptional("BehaviorAction.IsStarted.set");
	MarkNativeAsOptional("BehaviorAction.OnStart.set");
	MarkNativeAsOptional("BehaviorAction.OnUpdate.set");
	MarkNativeAsOptional("BehaviorAction.OnEnd.set");
	MarkNativeAsOptional("BehaviorAction.OnSuspend.set");
	MarkNativeAsOptional("BehaviorAction.OnResume.set");
	MarkNativeAsOptional("BehaviorAction.OnInitialContainedAction.set");
	MarkNativeAsOptional("BehaviorAction.OnLeaveGround.set");
	MarkNativeAsOptional("BehaviorAction.OnLandOnGround.set");
	MarkNativeAsOptional("BehaviorAction.OnContact.set");
	MarkNativeAsOptional("BehaviorAction.OnMoveToSuccess.set");
	MarkNativeAsOptional("BehaviorAction.OnMoveToFailure.set");
	MarkNativeAsOptional("BehaviorAction.OnStuck.set");
	MarkNativeAsOptional("BehaviorAction.OnUnStuck.set");
	MarkNativeAsOptional("BehaviorAction.OnPostureChanged.set");
	MarkNativeAsOptional("BehaviorAction.OnAnimationActivityComplete.set");
	MarkNativeAsOptional("BehaviorAction.OnAnimationActivityInterrupted.set");
	MarkNativeAsOptional("BehaviorAction.OnAnimationEvent.set");
	MarkNativeAsOptional("BehaviorAction.OnIgnite.set");
	MarkNativeAsOptional("BehaviorAction.OnInjured.set");
	MarkNativeAsOptional("BehaviorAction.OnKilled.set");
	MarkNativeAsOptional("BehaviorAction.OnOtherKilled.set");
	MarkNativeAsOptional("BehaviorAction.OnSight.set");
	MarkNativeAsOptional("BehaviorAction.OnLostSight.set");
	MarkNativeAsOptional("BehaviorAction.OnThreatChanged.set");
	MarkNativeAsOptional("BehaviorAction.OnSound.set");
	MarkNativeAsOptional("BehaviorAction.OnSpokeConcept.set");
	MarkNativeAsOptional("BehaviorAction.OnNavAreaChanged.set");
	MarkNativeAsOptional("BehaviorAction.OnModelChanged.set");
	MarkNativeAsOptional("BehaviorAction.OnPickUp.set");
	MarkNativeAsOptional("BehaviorAction.OnShoved.set");
	MarkNativeAsOptional("BehaviorAction.OnBlinded.set");
	MarkNativeAsOptional("BehaviorAction.OnEnteredSpit.set");
	MarkNativeAsOptional("BehaviorAction.OnHitByVomitJar.set");
	MarkNativeAsOptional("BehaviorAction.OnCommandAttack.set");
	MarkNativeAsOptional("BehaviorAction.OnCommandAssault.set");
	MarkNativeAsOptional("BehaviorAction.OnCommandApproachV.set");
	MarkNativeAsOptional("BehaviorAction.OnCommandApproachE.set");
	MarkNativeAsOptional("BehaviorAction.OnCommandRetreat.set");
	MarkNativeAsOptional("BehaviorAction.OnCommandPause.set");
	MarkNativeAsOptional("BehaviorAction.OnCommandResume.set");
	MarkNativeAsOptional("BehaviorAction.OnCommandString.set");
	MarkNativeAsOptional("BehaviorAction.IsAbleToBlockMovementOf.set");
	MarkNativeAsOptional("BehaviorAction.ShouldPickUp.set");
	MarkNativeAsOptional("BehaviorAction.ShouldHurry.set");
	MarkNativeAsOptional("BehaviorAction.IsHindrance.set");
	MarkNativeAsOptional("BehaviorAction.SelectTargetPoint.set");
	MarkNativeAsOptional("BehaviorAction.IsPositionAllowed.set");
	MarkNativeAsOptional("BehaviorAction.QueryCurrentPath.set");
	MarkNativeAsOptional("BehaviorAction.SelectMoreDangerousThreat.set");
	MarkNativeAsOptional("BehaviorAction.OnTerritoryCaptured.set");
	MarkNativeAsOptional("BehaviorAction.OnTerritoryLost.set");
	MarkNativeAsOptional("BehaviorAction.OnWin.set");
	MarkNativeAsOptional("BehaviorAction.OnWeaponFired.set");
	MarkNativeAsOptional("BehaviorAction.OnActorEmoted.set");
	MarkNativeAsOptional("BehaviorAction.ShouldRetreat.set");
	MarkNativeAsOptional("BehaviorAction.ShouldAttack.set");
	
	MarkNativeAsOptional("BehaviorAction.OnStartPost.set");
	MarkNativeAsOptional("BehaviorAction.OnUpdatePost.set");
	MarkNativeAsOptional("BehaviorAction.OnEndPost.set");
	MarkNativeAsOptional("BehaviorAction.OnSuspendPost.set");
	MarkNativeAsOptional("BehaviorAction.OnResumePost.set");
	MarkNativeAsOptional("BehaviorAction.OnInitialContainedActionPost.set");
	MarkNativeAsOptional("BehaviorAction.OnLeaveGroundPost.set");
	MarkNativeAsOptional("BehaviorAction.OnLandOnGroundPost.set");
	MarkNativeAsOptional("BehaviorAction.OnContactPost.set");
	MarkNativeAsOptional("BehaviorAction.OnMoveToSuccessPost.set");
	MarkNativeAsOptional("BehaviorAction.OnMoveToFailurePost.set");
	MarkNativeAsOptional("BehaviorAction.OnStuckPost.set");
	MarkNativeAsOptional("BehaviorAction.OnUnStuckPost.set");
	MarkNativeAsOptional("BehaviorAction.OnPostureChangedPost.set");
	MarkNativeAsOptional("BehaviorAction.OnAnimationActivityCompletePost.set");
	MarkNativeAsOptional("BehaviorAction.OnAnimationActivityInterruptedPost.set");
	MarkNativeAsOptional("BehaviorAction.OnAnimationEventPost.set");
	MarkNativeAsOptional("BehaviorAction.OnIgnitePost.set");
	MarkNativeAsOptional("BehaviorAction.OnInjuredPost.set");
	MarkNativeAsOptional("BehaviorAction.OnKilledPost.set");
	MarkNativeAsOptional("BehaviorAction.OnOtherKilledPost.set");
	MarkNativeAsOptional("BehaviorAction.OnSightPost.set");
	MarkNativeAsOptional("BehaviorAction.OnLostSightPost.set");
	MarkNativeAsOptional("BehaviorAction.OnThreatChangedPost.set");
	MarkNativeAsOptional("BehaviorAction.OnSoundPost.set");
	MarkNativeAsOptional("BehaviorAction.OnSpokeConceptPost.set");
	MarkNativeAsOptional("BehaviorAction.OnNavAreaChangedPost.set");
	MarkNativeAsOptional("BehaviorAction.OnModelChangedPost.set");
	MarkNativeAsOptional("BehaviorAction.OnPickUpPost.set");
	MarkNativeAsOptional("BehaviorAction.OnShovedPost.set");
	MarkNativeAsOptional("BehaviorAction.OnBlindedPost.set");
	MarkNativeAsOptional("BehaviorAction.OnEnteredSpitPost.set");
	MarkNativeAsOptional("BehaviorAction.OnHitByVomitJarPost.set");
	MarkNativeAsOptional("BehaviorAction.OnCommandAttackPost.set");
	MarkNativeAsOptional("BehaviorAction.OnCommandAssaultPost.set");
	MarkNativeAsOptional("BehaviorAction.OnCommandApproachVPost.set");
	MarkNativeAsOptional("BehaviorAction.OnCommandApproachEPost.set");
	MarkNativeAsOptional("BehaviorAction.OnCommandRetreatPost.set");
	MarkNativeAsOptional("BehaviorAction.OnCommandPausePost.set");
	MarkNativeAsOptional("BehaviorAction.OnCommandResumePost.set");
	MarkNativeAsOptional("BehaviorAction.IsAbleToBlockMovementOfPost.set");
	MarkNativeAsOptional("BehaviorAction.ShouldPickUpPost.set");
	MarkNativeAsOptional("BehaviorAction.ShouldHurryPost.set");
	MarkNativeAsOptional("BehaviorAction.IsHindrancePost.set");
	MarkNativeAsOptional("BehaviorAction.SelectTargetPointPost.set");
	MarkNativeAsOptional("BehaviorAction.IsPositionAllowedPost.set");
	MarkNativeAsOptional("BehaviorAction.QueryCurrentPathPost.set");
	MarkNativeAsOptional("BehaviorAction.SelectMoreDangerousThreatPost.set");
	MarkNativeAsOptional("BehaviorAction.OnTerritoryCapturedPost.set");
	MarkNativeAsOptional("BehaviorAction.OnTerritoryLostPost.set");
	MarkNativeAsOptional("BehaviorAction.OnWinPost.set");
	MarkNativeAsOptional("BehaviorAction.OnWeaponFiredPost.set");
	MarkNativeAsOptional("BehaviorAction.OnActorEmotedPost.set");
	MarkNativeAsOptional("BehaviorAction.ShouldRetreatPost.set");
	MarkNativeAsOptional("BehaviorAction.ShouldAttackPost.set");
}
#endif 