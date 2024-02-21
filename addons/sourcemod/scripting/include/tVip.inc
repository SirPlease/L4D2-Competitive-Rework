/*
**
*/
#if defined _tVip_included
 #endinput
#endif
#define _tVip_included


/**
 * Grant vip to a client.
 *
 * @param admin  		Admin that set VIP.
 * @param client 		Client that will recive VIP.
 * @param duration		Vip duration.
 * @param format 		Time format, 1 = Minutes - 0 = Month.
 * @noreturn
 * @error				Invalid client/admin Index or invalid format.
 */
native void tVip_GrantVip(int client, int admin, int duration, int format = 1);



/**
 * Delete Vip from database.
 *
 * @param SteamId  		Client SteamID.
 * @noreturn
 */
native void tVip_DeleteVip(char SteamId[20]);

native tVip_isVip(int client);


/**
 * Forward on Client pre loaded - Vip is about to be loaded
 *
 * @param2 -> int client
 *
 */
forward void tVip_OnClientLoadedPre(int client);


/**
 * Forward on Client post loaded - Vip for client has loaded and is set in flags
 *
 * @param2 -> int client
 *
 */
forward void tVip_OnClientLoadedPost(int client);
