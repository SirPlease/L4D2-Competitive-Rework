#if defined _ThirdPersonShoulder_Detect_included
	#endinput
#endif
#define _ThirdPersonShoulder_Detect_included

/**
*	@param 	iClient			Client Index.
*	@param 	bIsThirdPerson	true = Is in thirdperson shoulder, false otherwise.
*/
forward void TP_OnThirdPersonChanged(int iClient, bool bIsThirdPerson);

