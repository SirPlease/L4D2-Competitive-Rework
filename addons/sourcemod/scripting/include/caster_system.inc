#if defined _caster_system_included
 #endinput
#endif
#define _caster_system_included

enum eTypeID
{
	kClient = 0,
	kAuth	= 1,
}

enum eTypeAction
{
	kGet = 0,
	kSet = 1,
	kRem = 2
}

/**
 * @brief Add, checks or remove a user from the Casters list.
 *
 * @param eTypeID       Defines how the client will be identified.
 * @param eTypeAction   What action will be taken.
 * @param iClient       Required only if eTypeID is kClient, otherwise set it to -1.
 * @param szAuthId      Required only if eTypeID is kAuth, otherwise it is not necessary to define it.
 * @return              True if the client or AuthID is a caster (for Get action), false otherwise.
 */
native bool bCaster(eTypeID eID, eTypeAction eAction, int iClient = -1, const char[] szAuthId = "");

/**
 * @brief Add, checks or remove a user from the Casters whitelist.
 *
 * @param eTypeID       Defines how the client will be identified.
 * @param eTypeAction   What action will be taken.
 * @param iClient       Required only if eTypeID is kClient, otherwise set it to -1.
 * @param szAuthId      Required only if eTypeID is kAuth, otherwise it is not necessary to define it.
 * @return              True if the action was successful, false otherwise.
 */
native bool bCasterWhitelist(eTypeID eID, eTypeAction eAction, int iClient = -1, const char[] szAuthId = "");

/**
 * @brief Add, checks or remove a user from the spectator immunity list.
 *
 * @param eTypeID       Defines how the client will be identified.
 * @param eTypeAction   What action will be taken.
 * @param iClient       Required only if eTypeID is kClient, otherwise set it to -1.
 * @param szAuthId      Required only if eTypeID is kAuth, otherwise it is not necessary to define it.
 * @return              True if the client has spectator immunity, false otherwise.
 */
native bool bKickSpecInmunity(eTypeID eID, eTypeAction eAction, int iClient = -1, const char[] szAuthId = "");

/**
 * @brief Called when a client is added to the caster list.
 *
 * @param eTypeID       Defines how the client will be identified.
 * @param iClient       It will be defined only if eTypeID is kClient.
 * @param szAuthId      It will be defined only if eTypeID is kAuth.
 */
forward void OnCaster(eTypeID eID, int iClient, const char[] szAuthId);

/**
 * @brief Called when a client is removed to the caster list.
 *
 * @param eTypeID       Defines how the client will be identified.
 * @param iClient       It will be defined only if eTypeID is kClient.
 * @param szAuthId      It will be defined only if eTypeID is kAuth.
 */
forward void OffCaster(eTypeID eID, int iClient, const char[] szAuthId);

public SharedPlugin __pl_caster_system =
{
	name = "caster_system",
	file = "caster_system.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_caster_system_SetNTVOptional()
{
	MarkNativeAsOptional("bCaster");
	MarkNativeAsOptional("bCasterWhitelist");
	MarkNativeAsOptional("bKickSpecInmunity");
}
#endif