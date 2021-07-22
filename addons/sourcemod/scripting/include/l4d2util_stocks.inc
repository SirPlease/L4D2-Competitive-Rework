#if defined l4d2util_stocks_inc_
	#endinput
#endif
#define l4d2util_stocks_inc_

stock int L4D2Util_GetMin(int a, int b)
{
	return (a < b) ? a : b;
}

stock int L4D2Util_GetMax(int a, int b)
{
	return (a > b) ? a : b;
}

stock float L4D2Util_GetMinFloat(float a, float b)
{
	return (a < b) ? a : b;
}

stock float L4D2Util_GetMaxFloat(float a, float b)
{
	return (a > b) ? a : b;
}

stock float L4D2Util_ClampFloat(float inc, float low, float high)
{
	return (inc > high) ? high : ((inc < low) ? low : inc);
}

stock int L4D2Util_Clamp(int inc, int low, int high)
{
	return (inc > high) ? high : ((inc < low) ? low : inc);
}

stock bool L4D2Util_IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients);
}

/* Unsafe functions
stock any L4D2Utill_GetMin(any a, any b)
{
	return (a < b) ? a : b;
}

stock any L4D2Utill_GetMax(any a, any b)
{
	return (a > b) ? a : b;
}
*/
