#if defined _hl_gangs_included
	#endinput
#endif
#define _hl_gangs_included

native bool Gangs_HasGang(int client);
native void Gangs_GetGangName(int client, char[] buffer, int maxlen);
