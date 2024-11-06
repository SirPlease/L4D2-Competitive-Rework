#if defined l4d2util_inc_
	#endinput
#endif
#define l4d2util_inc_

#include <l4d2util_stocks>
#include <l4d2util_constants>
#include <l4d2util_infected>
#include <l4d2util_rounds>
#include <l4d2util_survivors>
#include <l4d2util_tanks>
#include <l4d2util_weapons>

stock void L4D2_GetTeamName(int team, char[] name, int maxlen)
{
	strcopy(name, maxlen, L4D2_TeamName[team]);
}

stock void L4D2_GetSurvivorModelName(int size, char[] name, int maxlen)
{
	strcopy(name, maxlen, g_sSurvivorModels[size]);
}