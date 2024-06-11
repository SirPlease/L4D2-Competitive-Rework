#if defined _actions_listeners_included
 #endinput
#endif

#define _actions_listeners_included

methodmap ActionProcessor
{
};

native bool __action_setlistener(any action, ActionProcessor processor, Function fn, bool post);
native bool __action_removelistener(any action, ActionProcessor processor, Function fn, bool post);

public ActionProcessor __action_processor_OnStart;
public ActionProcessor __action_processor_Update;
public ActionProcessor __action_processor_OnEnd;
public ActionProcessor __action_processor_OnSuspend;
public ActionProcessor __action_processor_OnResume;
public ActionProcessor __action_processor_InitialContainedAction;
public ActionProcessor __action_processor_OnLeaveGround;
public ActionProcessor __action_processor_OnLandOnGround;
public ActionProcessor __action_processor_OnContact;
public ActionProcessor __action_processor_OnMoveToSuccess;
public ActionProcessor __action_processor_OnMoveToFailure;
public ActionProcessor __action_processor_OnStuck;
public ActionProcessor __action_processor_OnUnStuck;
public ActionProcessor __action_processor_OnPostureChanged;
public ActionProcessor __action_processor_OnAnimationActivityComplete;
public ActionProcessor __action_processor_OnAnimationActivityInterrupted;
public ActionProcessor __action_processor_OnAnimationEvent;
public ActionProcessor __action_processor_OnIgnite;
public ActionProcessor __action_processor_OnInjured;
public ActionProcessor __action_processor_OnKilled;
public ActionProcessor __action_processor_OnOtherKilled;
public ActionProcessor __action_processor_OnSight;
public ActionProcessor __action_processor_OnLostSight;
public ActionProcessor __action_processor_OnThreatChanged;
public ActionProcessor __action_processor_OnSound;
public ActionProcessor __action_processor_OnSpokeConcept;
public ActionProcessor __action_processor_OnNavAreaChanged;
public ActionProcessor __action_processor_OnModelChanged;
public ActionProcessor __action_processor_OnPickUp;
public ActionProcessor __action_processor_OnDrop;
public ActionProcessor __action_processor_OnShoved;
public ActionProcessor __action_processor_OnBlinded;
public ActionProcessor __action_processor_OnEnteredSpit;
public ActionProcessor __action_processor_OnHitByVomitJar;
public ActionProcessor __action_processor_OnCommandAttack;
public ActionProcessor __action_processor_OnCommandAssault;
public ActionProcessor __action_processor_OnCommandRetreat;
public ActionProcessor __action_processor_OnCommandPause;
public ActionProcessor __action_processor_OnCommandResume;
public ActionProcessor __action_processor_OnCommandString;
public ActionProcessor __action_processor_IsAbleToBlockMovementOf;
public ActionProcessor __action_processor_ShouldPickUp;
public ActionProcessor __action_processor_ShouldHurry;
public ActionProcessor __action_processor_IsHindrance;
public ActionProcessor __action_processor_ShouldRetreat;
public ActionProcessor __action_processor_ShouldAttack;
public ActionProcessor __action_processor_SelectTargetPoint;
public ActionProcessor __action_processor_IsPositionAllowed;
public ActionProcessor __action_processor_QueryCurrentPath;
public ActionProcessor __action_processor_SelectMoreDangerousThreat;
public ActionProcessor __action_processor_OnCommandApproachByEntity;
public ActionProcessor __action_processor_OnCommandApproachByVector;
public ActionProcessor __action_processor_OnActorEmoted;
public ActionProcessor __action_processor_OnTerritoryContested;
public ActionProcessor __action_processor_OnTerritoryCaptured;
public ActionProcessor __action_processor_OnTerritoryLost;
public ActionProcessor __action_processor_OnWeaponFired;
public ActionProcessor __action_processor_OnWin;
public ActionProcessor __action_processor_OnLose;

typeset ActionHandler
{
	/* OnStart, OnSuspend, OnResume */
	function Action (any action, int actor, any priorAction, ActionResult result);

	/* OnUpdate */
	function Action (any action, int actor, float interval, ActionResult result);

	/* OnEnd */
	function void (any action, int actor, any priorAction, ActionResult result);

	/* InitialContainedAction */
	function Action (any action, int actor, any& child);

	/* OnLeaveGround, OnLandOnGround, OnDrop, OnShoved, OnBlinded, OnHitByVomitJar, OnCommandAttack */
	function Action (any action, int actor, int entity, ActionDesiredResult result);

	/* OnContact */
	function Action (any action, int actor, int entity, Address trace, ActionDesiredResult result);

	/* OnMoveToSuccess */
	function Action (any action, int actor, Address path, ActionDesiredResult result);
	
	/* OnMoveToFailure */
	function Action (any action, int actor, Address path, any type, ActionDesiredResult result);

	/* OnStuck, OnUnStuck, OnPostureChanged, OnIgnite, OnModelChanged, OnEnteredSpit, OnCommandAssault, OnCommandResume  */
	function Action (any action, int actor, ActionDesiredResult result);

	/* OnAnimationActivityComplete, OnAnimationActivityInterrupted */
	function Action (any action, int actor, int activity, ActionDesiredResult result);

	/* OnAnimationEvent */
	function Action (any action, int actor, Address animevent, ActionDesiredResult result);

	/* OnInjured, OnKilled */
	function Action (any action, int actor, Address takedamageinfo, ActionDesiredResult result);

	/* OnOtherKilled */
	function Action (any action, int actor, int other, Address takedamageinfo, ActionDesiredResult result);

	/* OnSight, OnLostSight, OnThreatChanged */
	function Action (any action, int actor, int entity, ActionDesiredResult result);

	/* OnSound */
	function Action (any action, int actor, int entity, const float pos[3], Address keyvalues, ActionDesiredResult result);

	/* OnSpokeConcept */
	function Action (any action, int actor, int who, Address concept, Address response, Address unknown, ActionDesiredResult result);
	
	/* OnNavAreaChanged */
	function Action (any action, int actor, Address newArea, Address oldArea, ActionDesiredResult result);
	
	/* OnPickUp */
	function Action (any action, int actor, int entity, int giver, ActionDesiredResult result);

	/* OnCommandApproachVector */
	function Action (any action, int actor, const float pos[3], float range, ActionDesiredResult result);

	/* OnCommandApproachEntity */
	function Action (any action, int actor, int goal, ActionDesiredResult result);

	/* OnCommandRetreat */
	function Action (any action, int actor, int threat, float range, ActionDesiredResult result);

	/* OnCommandPause */
	function Action (any action, int actor, float duration, ActionDesiredResult result);

	/* OnCommandString */
	function Action (any action, int actor, const char[] command, ActionDesiredResult result);

	/* IsAbleToBlockMovementOf */
	function Action (any action, int actor, Address nextbot, ActionDesiredResult result);

	/* OnTerritoryContested, OnTerritoryCaptured, OnTerritoryLost */
	function Action (any action, int actor, int territory);

	/* OnWin, OnLose */
	function Action (any action, int actor);

	/* OnWeaponFired */
	function Action (any action, int actor, int who, int weapon);

	/* OnActorEmoted */
	function Action (any action, int actor, int emoter, int emote);
}

typeset ActionContextualHandler
{
	/* ShouldPickUp, IsHindrance*/
	function Action (any action, Address nextbot, int entity, QueryResultType& result);
	
	/* ShouldHurry, ShouldRetreat */
	function Action (any action, Address nextbot, QueryResultType& result);

	/* ShouldAttack */
	function Action (any action, Address nextbot, Address knownEntity, QueryResultType& result);

	/* SelectTargetPoint */
	function Action (any action, Address nextbot, int entity, float vec[3]);

	/* IsPositionAllowed */
	function Action (any action, Address nextbot, float vec[3], QueryResultType& result);
	
	/* QueryCurrentPath */
	function Action (any action, Address nextbot, Address& path);
	
	/* SelectMoreDangerousThreat */
	function Action (any action, Address nextbot, int entity, Address threat1, Address threat2, Address& knownEntity);
}

methodmap BehaviorActionListeners
{	
    // ====================================================================================================
	// ACTION PRE EVENT HANDLERS
	// ====================================================================================================

	property ActionHandler OnStart
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnStart, func, false);
		}
	}
	property ActionHandler Update
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_Update, func, false);
		}
	}
	property ActionHandler OnEnd
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnEnd, func, false);
		}
	}
	property ActionHandler OnSuspend
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnSuspend, func, false);
		}
	}
	property ActionHandler OnResume
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnResume, func, false);
		}
	}
	property ActionHandler InitialContainedAction
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_InitialContainedAction, func, false);
		}
	}
	property ActionHandler OnLeaveGround
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnLeaveGround, func, false);
		}
	}
	property ActionHandler OnLandOnGround
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnLandOnGround, func, false);
		}
	}
	property ActionHandler OnContact
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnContact, func, false);
		}
	}
	property ActionHandler OnMoveToSuccess
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnMoveToSuccess, func, false);
		}
	}
	property ActionHandler OnMoveToFailure
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnMoveToFailure, func, false);
		}
	}
	property ActionHandler OnStuck
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnStuck, func, false);
		}
	}
	property ActionHandler OnUnStuck
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnUnStuck, func, false);
		}
	}
	property ActionHandler OnPostureChanged
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnPostureChanged, func, false);
		}
	}
	property ActionHandler OnAnimationActivityComplete
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnAnimationActivityComplete, func, false);
		}
	}
	property ActionHandler OnAnimationActivityInterrupted
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnAnimationActivityInterrupted, func, false);
		}
	}
	property ActionHandler OnAnimationEvent
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnAnimationEvent, func, false);
		}
	}
	property ActionHandler OnIgnite
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnIgnite, func, false);
		}
	}
	property ActionHandler OnInjured
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnInjured, func, false);
		}
	}
	property ActionHandler OnKilled
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnKilled, func, false);
		}
	}
	property ActionHandler OnOtherKilled
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnOtherKilled, func, false);
		}
	}
	property ActionHandler OnSight
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnSight, func, false);
		}
	}
	property ActionHandler OnLostSight
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnLostSight, func, false);
		}
	}
	property ActionHandler OnThreatChanged
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnThreatChanged, func, false);
		}
	}
	property ActionHandler OnSound
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnSound, func, false);
		}
	}
	property ActionHandler OnSpokeConcept
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnSpokeConcept, func, false);
		}
	}
	property ActionHandler OnNavAreaChanged
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnNavAreaChanged, func, false);
		}
	}
	property ActionHandler OnModelChanged
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnModelChanged, func, false);
		}
	}
	property ActionHandler OnPickUp
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnPickUp, func, false);
		}
	}
	property ActionHandler OnDrop
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnDrop, func, false);
		}
	}
	property ActionHandler OnShoved
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnShoved, func, false);
		}
	}
	property ActionHandler OnBlinded
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnBlinded, func, false);
		}
	}
	property ActionHandler OnEnteredSpit
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnEnteredSpit, func, false);
		}
	}
	property ActionHandler OnHitByVomitJar
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnHitByVomitJar, func, false);
		}
	}
	property ActionHandler OnCommandAttack
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnCommandAttack, func, false);
		}
	}
	property ActionHandler OnCommandAssault
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnCommandAssault, func, false);
		}
	}
	property ActionHandler OnCommandRetreat
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnCommandRetreat, func, false);
		}
	}
	property ActionHandler OnCommandPause
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnCommandPause, func, false);
		}
	}
	property ActionHandler OnCommandResume
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnCommandResume, func, false);
		}
	}
	property ActionHandler OnCommandString
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnCommandString, func, false);
		}
	}
	property ActionHandler IsAbleToBlockMovementOf
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_IsAbleToBlockMovementOf, func, false);
		}
	}
	property ActionHandler OnCommandApproachByEntity
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnCommandApproachByEntity, func, false);
		}
	}
	property ActionHandler OnCommandApproachByVector
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnCommandApproachByVector, func, false);
		}
	}
	property ActionHandler OnActorEmoted
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnActorEmoted, func, false);
		}
	}
	property ActionHandler OnTerritoryContested
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnTerritoryContested, func, false);
		}
	}
	property ActionHandler OnTerritoryCaptured
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnTerritoryCaptured, func, false);
		}
	}
	property ActionHandler OnTerritoryLost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnTerritoryLost, func, false);
		}
	}
	property ActionHandler OnWeaponFired
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnWeaponFired, func, false);
		}
	}
	property ActionHandler OnWin
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnWin, func, false);
		}
	}
	property ActionHandler OnLose
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnLose, func, false);
		}
	}
	
    // ====================================================================================================
	// ACTION PRE CONTEXTUAL HANDLERS
	// ====================================================================================================

	property ActionContextualHandler ShouldPickUp
	{
		public set(ActionContextualHandler func)
		{
			__action_setlistener(this, __action_processor_ShouldPickUp, func, false);
		}
	}
	property ActionContextualHandler ShouldHurry
	{
		public set(ActionContextualHandler func)
		{
			__action_setlistener(this, __action_processor_ShouldHurry, func, false);
		}
	}
	property ActionContextualHandler IsHindrance
	{
		public set(ActionContextualHandler func)
		{
			__action_setlistener(this, __action_processor_IsHindrance, func, false);
		}
	}
	property ActionContextualHandler ShouldRetreat
	{
		public set(ActionContextualHandler func)
		{
			__action_setlistener(this, __action_processor_ShouldRetreat, func, false);
		}
	}
	property ActionContextualHandler ShouldAttack
	{
		public set(ActionContextualHandler func)
		{
			__action_setlistener(this, __action_processor_ShouldAttack, func, false);
		}
	}
	property ActionContextualHandler SelectTargetPoint
	{
		public set(ActionContextualHandler func)
		{
			__action_setlistener(this, __action_processor_SelectTargetPoint, func, false);
		}
	}
	property ActionContextualHandler IsPositionAllowed
	{
		public set(ActionContextualHandler func)
		{
			__action_setlistener(this, __action_processor_IsPositionAllowed, func, false);
		}
	}
	property ActionContextualHandler QueryCurrentPath
	{
		public set(ActionContextualHandler func)
		{
			__action_setlistener(this, __action_processor_QueryCurrentPath, func, false);
		}
	}
	property ActionContextualHandler SelectMoreDangerousThreat
	{
		public set(ActionContextualHandler func)
		{
			__action_setlistener(this, __action_processor_SelectMoreDangerousThreat, func, false);
		}
	}

    // ====================================================================================================
	// ACTION POST EVENT HANDLERS
	// ====================================================================================================

	property ActionHandler OnStartPost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnStart, func, true);
		}
	}
	property ActionHandler UpdatePost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_Update, func, true);
		}
	}
	property ActionHandler OnEndPost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnEnd, func, true);
		}
	}
	property ActionHandler OnSuspendPost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnSuspend, func, true);
		}
	}
	property ActionHandler OnResumePost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnResume, func, true);
		}
	}
	property ActionHandler InitialContainedActionPost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_InitialContainedAction, func, true);
		}
	}
	property ActionHandler OnLeaveGroundPost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnLeaveGround, func, true);
		}
	}
	property ActionHandler OnLandOnGroundPost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnLandOnGround, func, true);
		}
	}
	property ActionHandler OnContactPost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnContact, func, true);
		}
	}
	property ActionHandler OnMoveToSuccessPost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnMoveToSuccess, func, true);
		}
	}
	property ActionHandler OnMoveToFailurePost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnMoveToFailure, func, true);
		}
	}
	property ActionHandler OnStuckPost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnStuck, func, true);
		}
	}
	property ActionHandler OnUnStuckPost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnUnStuck, func, true);
		}
	}
	property ActionHandler OnPostureChangedPost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnPostureChanged, func, true);
		}
	}
	property ActionHandler OnAnimationActivityCompletePost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnAnimationActivityComplete, func, true);
		}
	}
	property ActionHandler OnAnimationActivityInterruptedPost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnAnimationActivityInterrupted, func, true);
		}
	}
	property ActionHandler OnAnimationEventPost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnAnimationEvent, func, true);
		}
	}
	property ActionHandler OnIgnitePost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnIgnite, func, true);
		}
	}
	property ActionHandler OnInjuredPost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnInjured, func, true);
		}
	}
	property ActionHandler OnKilledPost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnKilled, func, true);
		}
	}
	property ActionHandler OnOtherKilledPost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnOtherKilled, func, true);
		}
	}
	property ActionHandler OnSightPost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnSight, func, true);
		}
	}
	property ActionHandler OnLostSightPost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnLostSight, func, true);
		}
	}
	property ActionHandler OnThreatChangedPost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnThreatChanged, func, true);
		}
	}
	property ActionHandler OnSoundPost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnSound, func, true);
		}
	}
	property ActionHandler OnSpokeConceptPost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnSpokeConcept, func, true);
		}
	}
	property ActionHandler OnNavAreaChangedPost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnNavAreaChanged, func, true);
		}
	}
	property ActionHandler OnModelChangedPost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnModelChanged, func, true);
		}
	}
	property ActionHandler OnPickUpPost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnPickUp, func, true);
		}
	}
	property ActionHandler OnDropPost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnDrop, func, true);
		}
	}
	property ActionHandler OnShovedPost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnShoved, func, true);
		}
	}
	property ActionHandler OnBlindedPost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnBlinded, func, true);
		}
	}
	property ActionHandler OnEnteredSpitPost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnEnteredSpit, func, true);
		}
	}
	property ActionHandler OnHitByVomitJarPost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnHitByVomitJar, func, true);
		}
	}
	property ActionHandler OnCommandAttackPost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnCommandAttack, func, true);
		}
	}
	property ActionHandler OnCommandAssaultPost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnCommandAssault, func, true);
		}
	}
	property ActionHandler OnCommandRetreatPost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnCommandRetreat, func, true);
		}
	}
	property ActionHandler OnCommandPausePost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnCommandPause, func, true);
		}
	}
	property ActionHandler OnCommandResumePost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnCommandResume, func, true);
		}
	}
	property ActionHandler OnCommandStringPost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnCommandString, func, true);
		}
	}
	property ActionHandler IsAbleToBlockMovementOfPost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_IsAbleToBlockMovementOf, func, true);
		}
	}
	property ActionHandler OnCommandApproachByEntityPost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnCommandApproachByEntity, func, true);
		}
	}
	property ActionHandler OnCommandApproachByVectorPost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnCommandApproachByVector, func, true);
		}
	}
	property ActionHandler OnActorEmotedPost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnActorEmoted, func, true);
		}
	}
	property ActionHandler OnTerritoryContestedPost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnTerritoryContested, func, true);
		}
	}
	property ActionHandler OnTerritoryCapturedPost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnTerritoryCaptured, func, true);
		}
	}
	property ActionHandler OnTerritoryLostPost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnTerritoryLost, func, true);
		}
	}
	property ActionHandler OnWeaponFiredPost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnWeaponFired, func, true);
		}
	}
	property ActionHandler OnWinPost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnWin, func, true);
		}
	}
	property ActionHandler OnLosePost
	{
		public set(ActionHandler func)
		{
			__action_setlistener(this, __action_processor_OnLose, func, true);
		}
	}
	
    // ====================================================================================================
	// ACTION POST CONTEXTUAL HANDLERS
	// ====================================================================================================

	property ActionContextualHandler ShouldPickUpPost
	{
		public set(ActionContextualHandler func)
		{
			__action_setlistener(this, __action_processor_ShouldPickUp, func, true);
		}
	}
	property ActionContextualHandler ShouldHurryPost
	{
		public set(ActionContextualHandler func)
		{
			__action_setlistener(this, __action_processor_ShouldHurry, func, true);
		}
	}
	property ActionContextualHandler IsHindrancePost
	{
		public set(ActionContextualHandler func)
		{
			__action_setlistener(this, __action_processor_IsHindrance, func, true);
		}
	}
	property ActionContextualHandler ShouldRetreatPost
	{
		public set(ActionContextualHandler func)
		{
			__action_setlistener(this, __action_processor_ShouldRetreat, func, true);
		}
	}
	property ActionContextualHandler ShouldAttackPost
	{
		public set(ActionContextualHandler func)
		{
			__action_setlistener(this, __action_processor_ShouldAttack, func, true);
		}
	}
	property ActionContextualHandler SelectTargetPointPost
	{
		public set(ActionContextualHandler func)
		{
			__action_setlistener(this, __action_processor_SelectTargetPoint, func, true);
		}
	}
	property ActionContextualHandler IsPositionAllowedPost
	{
		public set(ActionContextualHandler func)
		{
			__action_setlistener(this, __action_processor_IsPositionAllowed, func, true);
		}
	}
	property ActionContextualHandler QueryCurrentPathPost
	{
		public set(ActionContextualHandler func)
		{
			__action_setlistener(this, __action_processor_QueryCurrentPath, func, true);
		}
	}
	property ActionContextualHandler SelectMoreDangerousThreatPost
	{
		public set(ActionContextualHandler func)
		{
			__action_setlistener(this, __action_processor_SelectMoreDangerousThreat, func, true);
		}
	}


    /* This is for backwards compatibility */
    /* For some reason in previous versions I named them incorrectly */

    property ActionHandler OnUpdate
    {
    	public set(ActionHandler func)
    	{
    		__action_setlistener(this, __action_processor_Update, func, false);
    	}
    }

    property ActionHandler OnUpdatePost
    {
    	public set(ActionHandler func)
    	{
    		__action_setlistener(this, __action_processor_Update, func, true);
    	}
    }

	property ActionHandler OnInitialContainedAction
    {
    	public set(ActionHandler func)
    	{
    		__action_setlistener(this, __action_processor_InitialContainedAction, func, false);
    	}
    }
	
    property ActionHandler OnInitialContainedActionPost
    {
    	public set(ActionHandler func)
    	{
    		__action_setlistener(this, __action_processor_InitialContainedAction, func, true);
    	}
    }
}