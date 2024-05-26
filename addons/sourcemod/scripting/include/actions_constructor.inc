#if defined _actions_constructor_included
 #endinput
#endif

#define _actions_constructor_included

enum ACPassFlags
{
	ACPass_ByVal	= (1 << 0),		/**< Passing by value */
	ACPass_ByRef	= (1 << 1),		/**< Passing by reference */
	ACPass_Dtor		= (1 << 2),		/**< Object has a destructor */
	ACPass_Ctor		= (1 << 3),		/**< Object has a constructor */
	ACPass_Assignop	= (1 << 4),		/**< Object has an assignment operator */
	ACPass_Copyctor	= (1 << 5),		/**< Object has non-trivial copy constructor */
	ACPass_Unalign	= (1 << 6)		/**< Object contains unaligned fields */
}

enum ACPassType
{
	ACType_Basic,			/**< Plain old register data (pointers, integers) */
	ACType_Float,			/**< Floating point data */
	ACType_Object,			/**< Object or structure */
}

enum ACEncoder { ACEncoder_None = 0 }

public ACEncoder g_entityEncoder; 
public ACEncoder g_vectorEncoder; 

methodmap ActionConstructor < Handle
{	
	/**
 	* @brief Creates new action constructor handle
 	*
 	* @param size		Action size in bytes
 	*
 	* @return 			New handle on success, null otherwise
 	*/
	public native ActionConstructor(int size = 0);

	/**
 	* @brief Setup constructor function definition from gamedata
	* @remark Important! Avoid name collision between gamedata's.
 	*
 	* @param gamedata	Gamedata handle to read from
 	* @param key		Constructor name in gamedata
 	*
 	* @return 			New handle on success, null otherwise
 	*/
	public static native ActionConstructor SetupFromConf(Handle gamedata, const char[] key);

	/**
 	* @brief Sets constructor call address from gamedata
 	*
 	* @param gamedata	Gamedata handle to read from
 	* @param key		Address name in gamedata
 	*
 	* @return 			true on success, false otherwise
 	*/
	public native bool AddressFromConf(Handle gamedata, const char[] key);

	/**
 	* @brief Sets constructor call address from gamedata by signature
 	*
 	* @param gamedata	Gamedata handle to read from
 	* @param key		Signature name in gamedata
 	*
 	* @return 			true on success, false otherwise
 	*/
	public native bool SignatureFromConf(Handle gamedata, const char[] key);

	/**
 	* @brief Adds a parameter to constructor for further call
 	* @remark Encoders can transform arbitary data to valve params (eg. entity index -> CBaseEntity)
	*	
 	* @param passType	Param type (see ACPassType)
	* @param flags 		Param flags (see ACPassFlags) 
 	* @param encoder	Param encoder
 	*
 	* @return 			true on success, false otherwise
 	*/
	public native bool AddParameter(ACPassType passType, ACPassFlags flags = ACPass_ByVal, ACEncoder encoder = ACEncoder_None);

	/**
 	* @brief Finishes constructor handle.
	* @remark Consider this as EndPrepSDKCall() but only for ActionConstructor
	*
 	* @return 	true on success, false otherwise
 	*/
	public native bool Finish();

	/**
 	* @brief Executes constructor
	*
 	* @return 	BehaviorAction on success, INVALID_ACTION otherwise   	
 	*/
	public native BehaviorAction Execute(any ...);

	/**
 	* @brief Property to get/set action size
 	*
 	* @return	Action size
 	*/
	property int Size
	{
		public native get();
		public native set(int size);
	}
}

#if !defined REQUIRE_EXTENSIONS
public void __ext_actions_constructor_SetNTVOptional()
{
	MarkNativeAsOptional("ActionConstructor.ActionConstructor");
	MarkNativeAsOptional("ActionConstructor.SetupFromConf");
	MarkNativeAsOptional("ActionConstructor.AddressFromConf");
	MarkNativeAsOptional("ActionConstructor.SignatureFromConf");
	MarkNativeAsOptional("ActionConstructor.AddParameter");
	MarkNativeAsOptional("ActionConstructor.Finish");
	MarkNativeAsOptional("ActionConstructor.Execute");
	MarkNativeAsOptional("ActionConstructor.Size");
}
#endif 