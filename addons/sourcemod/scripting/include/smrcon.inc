#if defined _smrcon_included
 #endinput
#endif
#define _smrcon_included

/**
 * @brief Called when an RCon session auth is processed
 *
 * @param rconId	RCon listener ID, unique per session.
 * @param address	Originating IP address.
 * @param password	Password sent by RCon client.
 * @param allow		True to grant auth, false otherwise.
 * @return 			Plugin_Changed to use given allow value, Plugin_Continue to let engine process.
 */
forward Action SMRCon_OnAuth(int rconId, const char[] address, const char[] password, bool &allow);

/**
 * @brief Called when an RCon command is processed.
 *
 * @note Rejection here does not count as a bad password attempt;
 *       however, the RCon log line will be annotated in the form
 *       of 'command (rejected) "%s"' rather than just 'command "%s"'
 *
 * @param rconId	RCon listener ID, unique per session.
 * @param address	Originating IP address.
 * @param command	Command sent by RCon client.
 * @param allow		True to allow command to be processed, false otherwise.
 * @return 			Plugin_Changed to use given allow value, Plugin_Continue to let engine process.
 */
forward Action SMRCon_OnCommand(int rconId, const char[] address, const char[] command, bool &allow);

/**
 * @brief Called when an RCon session is disconnected.
 *
 * @param rconId	RCon listener ID, unique per session.
 */
forward void SMRCon_OnDisconnect(int rconId);

/**
 * @brief Called when an RCon log line is written
 *
 * @param rconId	RCon listener ID, unique per session.
 * @param address	Originating IP address.
 * @param logdata	Log data (usually either "Bad Password" or "command"
 *                  followed by the command.
 * @return			Plugin_Continue to log, Plugin_Handled to block.
 */
forward Action SMRCon_OnLog(int rconId, const char[] address, const char[] logdata);

/**
 * @brief Determines whether current server command originated from an RCon session.
 *
 * @return 			True if command originated from RCon session, false if from console or not in server command callback.
 */
native bool SMRCon_IsCmdFromRCon();


/** Do Not Edit Below This Line **/

public Extension __ext_smrcon =
{
	name = "smrcon",
	file = "smrcon.ext",
#if defined AUTOLOAD_EXTENSIONS
	autoload = 1,
#else
	autoload = 0,
#endif
#if defined REQUIRE_EXTENSIONS
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_EXTENSIONS
public void __ext_smrcon_SetNTVOptional()
{
	MarkNativeAsOptional("SMRCon_IsCmdFromRCon");
}
#endif
