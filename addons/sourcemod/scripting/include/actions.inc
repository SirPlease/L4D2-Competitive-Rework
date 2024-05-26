#if defined _actions_included
 #endinput
#endif

#define _actions_included

#define ACTION_NAME_LENGTH 32

#tryinclude <version>

#include <actions_processors>
#include <actions_constructor>

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

enum ActionComponent
{
	INVALID_COMPONENT
};

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

/**
 * @brief Called for every action
 *
 * @param action 	Self explanatory
 *
 * @noreturn
 */
typedef ActionsIteratorCallback = function void (BehaviorAction action);

typeset ActionComponentFn
{
	/**
	 * @brief Called for requesting initial action as first action of component/behavior
	 *
	 * @param component		Action component handle
	 * @param entity		Entity index
	 * 
	 * @return				Initial action
	 */
	function BehaviorAction(ActionComponent component, int entity);

	/**
	 * @brief Base component callback definition
	 *
	 * @param component		Action component handle
	 * @param entity		Entity index
	 *
	 * @noreturn
	 */
	function void(ActionComponent component, int entity);

	/**
	 * @brief Update component callback definition
	 *
	 * @param component		Action component handle
	 * @param entity		Entity index
	 *
	 * @return				Plugin_Continue to ignore, Plugin_Handled to block update
	 */
	function Action(ActionComponent component, int entity);
}

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

	/**
 	* @brief Gets action user data 
 	*
 	* @param key			Key for data 
 	* @param data			Variable for stored data
 	*
	* @error				Invalid action passed
 	* @return				True if data exists, false otherwise
 	*/
	public static native bool GetActionUserData(BehaviorAction action, const char[] key, any &data);

	/**
 	* @brief Gets action user data vector
 	*
 	* @param key			Key for data 
 	* @param vec			Vector to store to
 	*
	* @error				Invalid action passed
 	* @return				True if data exists, false otherwise
 	*/
	public static native bool GetActionUserDataVector(BehaviorAction action, const char[] key, float vec[3]);

	/**
 	* @brief Gets action user data string
 	*
 	* @param key			Key for data 
 	* @param buffer			Buffer to store to
 	* @param length			Buffer length
 	*
	* @error				Invalid action passed
 	* @return				True if data exists, false otherwise
 	*/
	public static native bool GetActionUserDataString(BehaviorAction action, const char[] key, char[] buffer, int length);

	/**
 	* @brief Sets action user data 
 	* @remark Data persists until the action is destroyed
 	* @remark Data is still usable in OnActionDestroyed callback
 	*
 	* @param key			Key to store data at 
 	* @param data			Data to store
 	*
	* @error				Invalid action passed
 	* @noreturn		
 	*/
	public static native void SetActionUserData(BehaviorAction action, const char[] key, any data);

	/**
 	* @brief Sets action user data vector
 	* @remark Data persists until the action is destroyed
 	* @remark Data is still usable in OnActionDestroyed callback
 	*
 	* @param key			Key to store data at 
 	* @param data			Data to store
 	* @param vec			Vector to store
 	*
	* @error				Invalid action passed
 	* @noreturn		
 	*/
	public static native void SetActionUserDataVector(BehaviorAction action, const char[] key, const float vec[3]);

	/**
 	* @brief Sets action user data vector
 	* @remark Data persists until the action is destroyed
 	* @remark Data is still usable in OnActionDestroyed callback
 	*
 	* @param key			Key to store data at 
 	* @param data			Data to store
 	* @param string			String to store
 	*
	* @error				Invalid action passed
 	* @noreturn		
 	*/
	public static native void SetActionUserDataString(BehaviorAction action, const char[] key, const char[] string);

	/**
 	* @brief Gets action user data with identity
 	* @remark Data persists until the plugin who owns data is unloaded
 	* @remark Data is still usable in OnActionDestroyed callback
	*
 	* @param key			Key for data 
 	* @param data			Variable for stored data
 	*
 	* @return				True if data exists, false otherwise
 	*/
	public static native bool GetActionUserDataIdentity(BehaviorAction action, const char[] key, any &data);

	/**
 	* @brief Gets action user data with identity (vector)
 	* @remark Data persists until the plugin who owns data is unloaded
 	* @remark Data is still usable in OnActionDestroyed callback
	*
 	* @param key			Key for data 
 	* @param vector			Variable for stored data
 	*
 	* @return				True if data exists, false otherwise
 	*/
	public static native bool GetActionUserDataIdentityVector(BehaviorAction action, const char[] key, float vector[3]);

	/**
 	* @brief Gets action user data with identity (string)
 	* @remark Data persists until the plugin who owns data is unloaded
 	* @remark Data is still usable in OnActionDestroyed callback
	*
 	* @param key			Key for data 
 	* @param buffer			Variable for stored data
 	* @param length			Length of buffer
 	*
 	* @return				True if data exists, false otherwise
 	*/
	public static native bool GetActionUserDataIdentityString(BehaviorAction action, const char[] key, char[] buffer, int length);

	/**
 	* @brief Sets action user data with identity
 	* @remark Data persists until the plugin who owns data is unloaded
 	* @remark Data is still usable in OnActionDestroyed callback
	*
 	* @param key			Key to store data at 
 	* @param data			Data to store
 	*
 	* @noreturn	
 	*/
	public static native void SetActionUserDataIdentity(BehaviorAction action, const char[] key, any data);

	/**
 	* @brief Sets action user data with identity (vector)
 	* @remark Data persists until the plugin who owns data is unloaded
 	* @remark Data is still usable in OnActionDestroyed callback
	*
 	* @param key			Key to store data at 
 	* @param vector			Vector to store
 	*
 	* @noreturn	
 	*/
	public static native void SetActionUserDataIdentityVector(BehaviorAction action, const char[] key, const float vector[3]);

	/**
 	* @brief Sets action user data with identity (vector)
 	* @remark Data persists until the plugin who owns data is unloaded
 	* @remark Data is still usable in OnActionDestroyed callback
	*
 	* @param key			Key to store data at 
 	* @param string			String to store
 	*
 	* @noreturn	
 	*/
	public static native void SetActionUserDataIdentityString(BehaviorAction action, const char[] key, const char[] string);
}

methodmap ActionComponent < Handle
{
	/**
 	* @brief Creates ActionComponent derived from IIntention/INextBotComponent 
	* @remark Used as holder for behavior 
	*
 	* @param entity				Who owns the component
 	* @param fnInitialAction  	Callback to initiate action
 	* @param fnUpdate  			Heavyweight algorithms, invoked less often
 	* @param fnUpkeep  			Lightweight maintenance, invoked frequently
	* @param fnReset			Whenver reset was requested
 	*
 	* @return 					New handle to component 
 	*/
	public native ActionComponent(int entity, ActionComponentFn fnInitialAction = INVALID_FUNCTION, 
												ActionComponentFn fnUpdate = INVALID_FUNCTION, 
												ActionComponentFn fnUpkeep = INVALID_FUNCTION, 
												ActionComponentFn fnReset = INVALID_FUNCTION, 
												const char[] name = NULL_STRING);

	/**
 	* @brief Gets behavior name
	*
	* @param buffer 			Buffer to store name
	* @param maxlength			Max buffer length
	* 
 	* @return 					Number of written bytes
 	*/
	public native int GetName(char[] buffer, int maxlength);

	/**
 	* @brief Sets behavior name
	*
	* @param name 				New behavior name
	* 
 	* @noreturn
 	*/
	public native void SetName(char[] name);

	/**
 	* @brief Returns current behavior action
	* 
 	* @return Current action
 	*/
	property BehaviorAction CurrentAction
	{
		public native get();
	}

	/**
 	* @brief Returns component physical address
	* 
 	*/
	property any Address
	{
		public native get();
	}

	/**
 	* @brief Returns component actor
	* @remark Returns 0 if component is inactive
	* 
 	*/
	property int Actor
	{
		public native get();
	}
	
	/**
 	* @brief Update callback setter
	* 
 	* @noreturn
 	*/
	property ActionComponentFn Update
	{
		public native set(ActionComponentFn fn);
	}

	/**
 	* @brief Upkeep callback setter
	* 
 	* @noreturn
 	*/
	property ActionComponentFn Upkeep
	{
		public native set(ActionComponentFn fn);
	}

	/**
 	* @brief Reset callback setter
	* 
 	* @noreturn
 	*/
	property ActionComponentFn Reset
	{
		public native set(ActionComponentFn fn);
	}
}

methodmap BehaviorAction < BehaviorActionListeners
{
	public BehaviorAction(any action)
	{
		return view_as<BehaviorAction>(action);
	}

	/**
 	* @brief Gets action name 
 	*
 	* @param destination	Buffer to store name 
 	* @param maxlength		Buffer length
 	*
	* @error				Invalid action passed or invalid runtime result
 	* @return				Number of bytes written?
 	*/
	public native int GetName( char[] destination, int maxlength = ACTION_NAME_LENGTH );

	/**
 	* @brief Continue executing this action 
 	*
	* @error				Invalid action passed or invalid runtime result
 	*/
	public native Action Continue();

	/**
 	* @brief Change to new action
 	*
 	* @param action			Action to change to 
 	* @param reason			Reason for a changing
	*
	* @error				Invalid action passed or invalid runtime result
 	*/
	public native Action ChangeTo(BehaviorAction action, const char[] reason = NULL_STRING);

	/**
 	* @brief Suspend the current action for the new action 
	*
 	* @param action			Action what will suspend us 
 	* @param reason			Reason for a suspending
	*
	* @error				Invalid action passed or invalid runtime result
 	*/
	public native Action SuspendFor(BehaviorAction action, const char[] reason = NULL_STRING);

	/**
 	* @brief Finish current action
	*
 	* @param reason			Reason why we finished
 	*
	* @error				Invalid action passed or invalid runtime result
 	*/
	public native Action Done(const char[] reason = NULL_STRING);

	/**
 	* @brief Continue executing this action 
 	*
 	* @param priority 		Priority to use this result
	*
	* @error				Invalid action passed or invalid runtime result
 	*/
	public native Action TryContinue(EventResultPriorityType priority = RESULT_TRY);

	/**
 	* @brief Change to new action
 	*
 	* @param action			Action to change to 
 	* @param priority 		Priority to use this result
 	* @param reason			Reason for a changing
	*
	* @error				Invalid action passed or invalid runtime result
 	*/
	public native Action TryChangeTo(BehaviorAction action, EventResultPriorityType priority = RESULT_TRY, const char[] reason = NULL_STRING);

	/**
 	* @brief Suspend the current action for the new action 
	*
 	* @param action			Action what will suspend us 
 	* @param priority 		Priority to use this result
 	* @param reason			Reason for a suspending
	*
	* @error				Invalid action passed or invalid runtime result
 	*/
	public native Action TrySuspendFor(BehaviorAction action, EventResultPriorityType priority = RESULT_TRY, const char[] reason = NULL_STRING);

	/**
 	* @brief Finish current action 
	*
 	* @param priority 		Priority to use this result
 	* @param reason			Reason why we finished
 	*
	* @error				Invalid action passed or invalid runtime result
 	*/
	public native Action TryDone(EventResultPriorityType priority = RESULT_TRY, const char[] reason = NULL_STRING);

	/**
 	* @brief Sustain current action 
	*
 	* @param priority 		Priority to use this result
 	* @param reason			Reason why we sustain
 	*
	* @error				Invalid action passed or invalid runtime result
 	*/
	public native Action TryToSustain(EventResultPriorityType priority = RESULT_TRY, const char[] reason = NULL_STRING);
	
	/**
 	* @brief Gets action user data 
	* @remark Doesn't check if data exists 
 	* @remark Data persists until the action is destroyed
 	* @remark Data is still usable in OnActionDestroyed callback
 	*
 	* @param key			Key for data
 	*
	* @error				Invalid action passed
 	* @return				Stored data
 	*/
	public any GetUserData(const char[] key)
	{
		int data;
		ActionsManager.GetActionUserData(this, key, data);
		return data;
	}

	/**
 	* @brief Gets action user data (vector)
	* @remark Doesn't check if data exists 
 	* @remark Data persists until the action is destroyed
 	* @remark Data is still usable in OnActionDestroyed callback
 	*
 	* @param key			Key for data
 	* @param out			Out vector
 	*
	* @error				Invalid action passed
 	* @noreturn				
 	*/
	public void GetUserDataVector(const char[] key, float out[3])
	{
		ActionsManager.GetActionUserDataVector(this, key, out);
	}

	/**
 	* @brief Gets action user data (string)
	* @remark Doesn't check if data exists 
 	* @remark Data persists until the action is destroyed
 	* @remark Data is still usable in OnActionDestroyed callback
 	*
 	* @param key			Key for data
 	* @param buffer			Out buffer
	* @param length 		Buffer length
 	*
	* @error				Invalid action passed
 	* @noreturn				
 	*/
	public void GetUserDataString(const char[] key, char[] buffer, int length)
	{
		ActionsManager.GetActionUserDataString(this, key, buffer, length);
	}

	/**
 	* @brief Sets action user data 
 	* @remark Data persists until the action is destroyed
 	* @remark Data is still usable in OnActionDestroyed callback
 	*
 	* @param key			Key to store data at 
 	* @param data			Data to store
 	*
	* @error				Invalid action passed
 	* @noreturn	
 	*/
	public void SetUserData(const char[] key, any data)
	{
		ActionsManager.SetActionUserData(this, key, data);
	}

	/**
 	* @brief Sets action user data (vector)
 	* @remark Data persists until the action is destroyed
 	* @remark Data is still usable in OnActionDestroyed callback
 	*
 	* @param key			Key to store data at 
 	* @param vector			Vector to store
 	*
	* @error				Invalid action passed
 	* @noreturn	
 	*/
	public void SetUserDataVector(const char[] key, const float vector[3])
	{
		ActionsManager.SetActionUserDataVector(this, key, vector);
	}

	/**
 	* @brief Sets action user data (vector)
 	* @remark Data persists until the action is destroyed
 	* @remark Data is still usable in OnActionDestroyed callback
 	*
 	* @param key			Key to store data at 
 	* @param string			String to store
 	*
	* @error				Invalid action passed
 	* @noreturn	
 	*/
	public void SetUserDataString(const char[] key, const char[] string)
	{
		ActionsManager.SetActionUserDataString(this, key, string);
	}

	/**
 	* @brief Gets action user data with identity
	* @remark Doesn't check if data exists 
 	* @remark Data persists until the plugin who owns data is unloaded
 	* @remark Data is still usable in OnActionDestroyed callback
	*
 	* @param key			Key for data
 	*
	* @error				Invalid action passed
 	* @return				Stored data
 	*/
	public any GetUserDataIdentity(const char[] key)
	{
		int data;
		ActionsManager.GetActionUserDataIdentity(this, key, data);
		return data;
	}

	/**
 	* @brief Gets action user data (vector)
	* @remark Doesn't check if data exists 
 	* @remark Data persists until the plugin who owns data is unloaded
 	* @remark Data is still usable in OnActionDestroyed callback
 	*
 	* @param key			Key for data
 	* @param out			Out vector
 	*
	* @error				Invalid action passed
 	* @noreturn				
 	*/
	public void GetUserDataIdentityVector(const char[] key, float out[3])
	{
		ActionsManager.GetActionUserDataIdentityVector(this, key, out);
	}

	/**
 	* @brief Gets action user data (string)
	* @remark Doesn't check if data exists 
 	* @remark Data persists until the plugin who owns data is unloaded
 	* @remark Data is still usable in OnActionDestroyed callback
 	*
 	* @param key			Key for data
 	* @param buffer			Out buffer
	* @param length 		Buffer length
 	*
	* @error				Invalid action passed
 	* @noreturn				
 	*/
	public void GetUserDataIdentityString(const char[] key, char[] buffer, int length)
	{
		ActionsManager.GetActionUserDataIdentityString(this, key, buffer, length);
	}

	/**
 	* @brief Sets action user data with identity
 	* @remark Data persists until the plugin who owns data is unloaded
 	* @remark Data is still usable in OnActionDestroyed callback
	*
 	* @param key			Key to store data at 
 	* @param data			Data to store
 	*
 	* @noreturn	
 	*/
	public void SetUserDataIdentity(const char[] key, any data)
	{
		ActionsManager.SetActionUserDataIdentity(this, key, data);
	}

	/**
 	* @brief Sets action user data with identity
 	* @remark Data persists until the plugin who owns data is unloaded
 	* @remark Data is still usable in OnActionDestroyed callback
 	*
 	* @param key			Key to store data at 
 	* @param vector			Vector to store
 	*
	* @error				Invalid action passed
 	* @noreturn	
 	*/
	public void SetUserDataIdentityVector(const char[] key, const float vector[3])
	{
		ActionsManager.SetActionUserDataIdentityVector(this, key, vector);
	}

	/**
 	* @brief Sets action user data with identity
 	* @remark Data persists until the plugin who owns data is unloaded
 	* @remark Data is still usable in OnActionDestroyed callback
 	*
 	* @param key			Key to store data at 
 	* @param string			String to store
 	*
	* @error				Invalid action passed
 	* @noreturn	
 	*/
	public void SetUserDataIdentityString(const char[] key, const char[] string)
	{
		ActionsManager.SetActionUserDataIdentityString(this, key, string);
	}

	/**
 	* @brief Simple wrapper to get action data 
 	*
 	* @param offset			Offset to data 
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
 	* @param offset			Offset to data 
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

 	/**
 	* @brief Stores a vector at specified offset
 	*
 	* @param offset			Offset to data 
 	* @param vec			Vector to set from
 	*
 	* @noreturn
 	*/
	public void SetVector( int offset, const float vec[3] )
	{
		this.Set(offset, vec[0], NumberType_Int32);
		this.Set(offset + 4, vec[1], NumberType_Int32);
		this.Set(offset + 8, vec[2], NumberType_Int32);
	}
	
 	/**
 	* @brief Loads a vector at specified offset
 	*
 	* @param offset			Offset to data 
 	* @param out			Vector to load to
 	*
 	* @noreturn
 	*/
	public void GetVector( int offset, float out[3] )
	{
		out[0] = view_as<float>(this.Get(offset, NumberType_Int32));
		out[1] = view_as<float>(this.Get(offset + 4, NumberType_Int32));
		out[2] = view_as<float>(this.Get(offset + 8, NumberType_Int32));
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
	* @error				Invalid action passed or invalid runtime result
 	* @noreturn
 	*/
	#pragma deprecated This function is deprecated. Does nothing.
	public native void StorePendingEventResult( ActionResultType type = CONTINUE, BehaviorAction action = INVALID_ACTION, EventResultPriorityType priority = RESULT_TRY, const char[] reason = NULL_STRING );
	
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
	* @note if this returns true then OnStart handled has already been called or is about to be called next frame
	* 
 	* @return				true if started, false otherwise
 	*/
	property bool IsStarted
	{
		public native get();
		public native set(bool started);
	}
}

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
	MarkNativeAsOptional("ActionComponent.ActionComponent");
	MarkNativeAsOptional("ActionComponent.Update");
	MarkNativeAsOptional("ActionComponent.Upkeep");
	MarkNativeAsOptional("ActionComponent.Reset");
	MarkNativeAsOptional("ActionComponent.GetName");
	MarkNativeAsOptional("ActionComponent.SetName");
	MarkNativeAsOptional("ActionComponent.Address");
	MarkNativeAsOptional("ActionComponent.Actor");

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

	MarkNativeAsOptional("ActionsManager.GetActionUserData");
	MarkNativeAsOptional("ActionsManager.SetActionUserData");
	MarkNativeAsOptional("ActionsManager.GetActionUserDataIdentity");
	MarkNativeAsOptional("ActionsManager.SetActionUserDataIdentity");

	MarkNativeAsOptional("BehaviorAction.Continue");
	MarkNativeAsOptional("BehaviorAction.ChangeTo");
	MarkNativeAsOptional("BehaviorAction.SuspendFor");
	MarkNativeAsOptional("BehaviorAction.Done");

	MarkNativeAsOptional("BehaviorAction.TryContinue");
	MarkNativeAsOptional("BehaviorAction.TryChangeTo");
	MarkNativeAsOptional("BehaviorAction.TrySuspendFor");
	MarkNativeAsOptional("BehaviorAction.TryDone");
	MarkNativeAsOptional("BehaviorAction.TryToSustain");
	
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

	MarkNativeAsOptional("__action_setlistener");
	MarkNativeAsOptional("__action_removelistener");

	__ext_actions_constructor_SetNTVOptional();
}
#endif 