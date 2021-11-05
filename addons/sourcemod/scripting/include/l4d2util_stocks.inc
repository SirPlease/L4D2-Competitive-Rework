#if defined l4d2util_stocks_inc_
	#endinput
#endif
#define l4d2util_stocks_inc_

#include <l4d2util_constants>

//Author - A1m`

stock bool IsValidClientIndex(int client)
{
	return (client > 0 && client <= MaxClients);
}

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

stock int L4D2Util_IntToPercentInt(int iVar, int iVarMax)
{
	if (iVar > iVarMax) {
		return 100;
	} else if (iVar < 1) {
		return 0;
	}
	
	return RoundToNearest((float(iVar) / float(iVarMax)) * 100.0);
}

stock float L4D2Util_IntToPercentFloat(int iVar, int iVarMax)
{
	if (iVar > iVarMax) {
		return 100.0;
	} else if (iVar < 1) {
		return 0.0;
	}
	
	return ((float(iVar) / float(iVarMax)) * 100.0);
}

stock float L4D2Util_FloatToPercentFloat(float iVar, float iVarMax)
{
	if (iVar > iVarMax) {
		return 100.0;
	} else if (iVar < 1) {
		return 0.0;
	}
	
	return ((iVar / iVarMax) * 100.0);
}

stock int L4D2Util_FloatToPercentInt(float iVar, float iVarMax)
{
	if (iVar > iVarMax) {
		return 100;
	} else if (iVar < 1) {
		return 0;
	}
	
	return RoundToNearest((iVar / iVarMax) * 100.0);
}

stock void String_ToLower(char[] str, const int MaxSize)
{
	int iSize = strlen(str); //Сounts string length to zero terminator

	for (int i = 0; i < iSize && i < MaxSize; i++) { //more security, so that the cycle is not endless
		if (IsCharUpper(str[i])) {
			str[i] = CharToLower(str[i]);
		}
	}

	str[iSize] = '\0';
}

stock void HitgroupToString(int iHitGroup, char[] sDestination, const int iMaxLength)
{
	char sBuffer[32] = "GENERIC";
	switch (iHitGroup) {
		case HITGROUP_GENERIC: { //0
			sBuffer = "generic";
		}
		case HITGROUP_HEAD: { //1
			sBuffer = "head";
		}
		case HITGROUP_CHEST: { //2
			sBuffer = "chest";
		}
		case HITGROUP_STOMACH: { //3
			sBuffer = "stomach";
		}
		case HITGROUP_LEFTARM: { //4
			sBuffer = "left arm";
		}
		case HITGROUP_RIGHTARM: { //5
			sBuffer = "right arm";
		}
		case HITGROUP_LEFTLEG: { //6
			sBuffer = "left leg";
		}
		case HITGROUP_RIGHTLEG: { //7
			sBuffer = "right leg";
		}
		case HITGROUP_GEAR: { //10
			sBuffer = "gear";
		}
	}

	strcopy(sDestination, iMaxLength, sBuffer);
}
