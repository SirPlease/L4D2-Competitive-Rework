/**
* Copyright (C) 2024 LuxLuma
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <https://www.gnu.org/licenses/>.
**/

#if defined _lux_library_included
#endinput
#endif
#define _lux_library_included

#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#tryinclude <left4dhooks_anim>
#tryinclude <left4dhooks_silver>
#tryinclude <left4dhooks_stocks>

#define LUX_LIBRARY_VERSION "0.5.8"

#define GIMMEDATA "lux_library"

//l4d2
#define DMG_FULLGIB	(1 << 24)

enum OS_Type
{
	OS_Unknown = -2,
	OS_invalid = -1,
	OS_windows = 0,
	OS_linux,
	OS_mac
}

static stock void GetGameData(Handle &hGamedata)
{
	hGamedata = LoadGameConfigFile(GIMMEDATA);
	if(hGamedata == null) 
		LogError("Failed to load \"%s.txt\" gamedata.", GIMMEDATA);
}

/**
 * Returns the OS of the server.
 * Note: Pass null to use gamedata from lux_library
 *
 * @param hGamedata		Handle to the gamedata file to get the OS type from.
 *
 * @return			Windows, Linux, or Mac
 * @error			Invalid or unknown OS type.
 **/
stock OS_Type GetOSType(Handle &hGamedata=null)
{
	static OS_Type os = OS_Unknown;
	if(os == OS_Unknown)
	{
		if(hGamedata == null)
		{
			GetGameData(hGamedata);
		}
		
		os = view_as<OS_Type>(GameConfGetOffset(hGamedata, "OS"));
		delete hGamedata;
	}
	return os;
}

/**
 * An alternative to TeleportEntity that maintains lerped movement client-side when setting an entity's new origin.
 * Note: Does not account for parented entities, uses world space.
 *
 * @param iEntity 		Entity index to set new origin of.
 * @param vec			New origin of the entity.
 *
 * @return			True on success, false on failure.
 * @error			Invalid entity index, signature for function not found, or SDKCall failed.
 **/
stock bool SetAbsOrigin(int iEntity, const float vec[3])
{
	static Handle hSDKCall;
	if(hSDKCall == null)
	{
		Handle hGamedata;
		GetGameData(hGamedata);
		
		StartPrepSDKCall(SDKCall_Entity);
		if(PrepSDKCall_SetFromConf(hGamedata, SDKConf_Signature, "CBaseEntity::SetAbsOrigin"))
		{
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Pointer);
			hSDKCall = EndPrepSDKCall();
			if(hSDKCall == null)
				LogError("Unable to prep SDKCall 'CBaseEntity::SetAbsOrigin'");
		}
		else
		{
			LogError("Error finding the 'CBaseEntity::SetAbsOrigin' signature.");
		}
		delete hGamedata;
		if(hSDKCall == null)
			return false;
	}
	SDKCall(hSDKCall, iEntity, vec);
	return true;
}

/**
 * An alternative to TeleportEntity that maintains lerped movement client-side when setting an entity's new velocity.
 * Note: Does not account for parented entities, uses world space.
 * Note: Does not overwrite "m_vecBaseVelocity".
 *
 * @param iEntity 		Entity index to set new velocity of.
 * @param vec			Velocity to apply to entity.
 *
 * @return			True on success, false on failure.
 * @error			Invalid entity index, signature for function not found, or SDKCall failed.
 **/
stock bool SetAbsVelocity(int iEntity, const float vec[3])
{
	static Handle hSDKCall;
	if(hSDKCall == null)
	{
		Handle hGamedata;
		GetGameData(hGamedata);
		
		StartPrepSDKCall(SDKCall_Entity);
		if(PrepSDKCall_SetFromConf(hGamedata, SDKConf_Signature, "CBaseEntity::SetAbsVelocity"))
		{
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Pointer);
			hSDKCall = EndPrepSDKCall();
			if(hSDKCall == null)
				LogError("Unable to prep SDKCall 'CBaseEntity::SetAbsVelocity'");
		}
		else
		{
			LogError("Error finding the 'CBaseEntity::SetAbsVelocity' signature.");
		}
		delete hGamedata;
		if(hSDKCall == null)
			return false;
	}
	SDKCall(hSDKCall, iEntity, vec);
	return true;
}

/**
 * An alternative to TeleportEntity that maintains lerped movement client-side when setting an entity's new angles.
 * Note: Does not account for parented entities, uses world space.
 *
 * @param iEntity 		Entity index to set new angles of.
 * @param vec			New angles of the entity.
 *
 * @return			True on success, false on failure.
 * @error			Invalid entity index, signature for function not found, or SDKCall failed.
 **/
stock bool SetAbsAngles(int iEntity, const float vec[3])
{
	static Handle hSDKCall;
	if(hSDKCall == null)
	{
		Handle hGamedata;
		GetGameData(hGamedata);
		
		StartPrepSDKCall(SDKCall_Entity);		
		if(PrepSDKCall_SetFromConf(hGamedata, SDKConf_Signature, "CBaseEntity::SetAbsAngles"))
		{
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Pointer);
			hSDKCall = EndPrepSDKCall();
			if(hSDKCall == null)
				LogError("Unable to prep SDKCall 'CBaseEntity::SetAbsAngles'");
		}
		else
		{
			LogError("Error finding the 'CBaseEntity::SetAbsAngles' signature.");
		}
		delete hGamedata;
		if(hSDKCall == null)
			return false;
	}
	SDKCall(hSDKCall, iEntity, vec);
	return true;
}

/**
 * Copies the origin and angles vectors for world space attachment index location.
 *
 * @param iEntity		Entity index to get origin and angles vectors of.
 * @param attachmentName	Name of the attachment.
 * @param vecOrigin		Vector to store origin in.
 * @param vecAngles		Vector to store angles in.
 *
 * @return			True if attachment vectors were copied, false otherwise.
 * @error			Invalid entity index or invalid attachment name.
 **/
stock bool GetAttachmentVectors(int iEntity, char[] attachmentName, float vecOrigin[3], float vecAngles[3])
{
	int iAttachmentName = LookupAttachment(iEntity, attachmentName);
	if(iAttachmentName == 0)
		return false;
	GetAttachment(iEntity, iAttachmentName, vecOrigin, vecAngles);
	return true;
}

/**
 * Looks up an entity's attachment index via its name.
 *
 * @param iEntity		Entity index of the attachment.
 * @param attachmentName	Name of the attachment.
 *
 * @return			Attachment index, 0 for not found.
 * @error			Invalid entity index, invalid attachment name,
 *					signature for function not found, or SDKCall failed.
 **/
stock int LookupAttachment(int iEntity, char[] attachmentName)
{
	static Handle hSDKCall;
	if(hSDKCall == null)
	{
		Handle hGamedata;
		GetGameData(hGamedata);
		
		StartPrepSDKCall(SDKCall_Entity);
		if(PrepSDKCall_SetFromConf(hGamedata, SDKConf_Signature, "CBaseAnimating::LookupAttachment"))
		{
			PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
			hSDKCall = EndPrepSDKCall();
			if(hSDKCall == null)
				LogError("Unable to prep 'CBaseAnimating::LookupAttachment'");
		}
		else
		{
			LogError("Error finding the 'CBaseAnimating::LookupAttachment' signature.");
		}
		delete hGamedata;
		if(hSDKCall == null)
			return 0;
	}
	return SDKCall(hSDKCall, iEntity, attachmentName);
}


/**
 * Overloaded SDKCall->CBaseAnimating::GetAttachment(int a1, int a2, float *a3, float *a4)
 * Copies the origin and angles vectors for world space attachment index location.
 * Note: Invalid attachments point to entitiy origin.
 *
 * @param iEntity 		Entity index to get attachment of.
 * @param iAttachment		Attachment index on model.
 * @param vecOrigin		Vector to store origin in.
 * @param vecAngles		Vector to store angles in.
 *
 * @return			True if attachment vectors were copied, false otherwise.
 * @error			Invalid entity index or invalid attachment name,
 *					signature for function not found, or SDKCall failed.
 **/
stock bool GetAttachment(int iEntity, int iAttachment, float vecOrigin[3], float vecAngles[3])
{
	static Handle hSDKCall;
	if(hSDKCall == null)
	{
		Handle hGamedata;
		GetGameData(hGamedata);
		
		StartPrepSDKCall(SDKCall_Entity);
		if(PrepSDKCall_SetFromConf(hGamedata, SDKConf_Signature, "CBaseAnimating::GetAttachment"))
		{
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK);
			PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK);
			hSDKCall = EndPrepSDKCall();
			if(hSDKCall == null)
				LogError("Unable to prep 'CBaseAnimating::GetAttachment'");
		}
		else
		{
			LogError("Error finding the 'CBaseAnimating::GetAttachment' signature.");
		}
		delete hGamedata;
		if(hSDKCall == null)
			return false;
	}
	SDKCall(hSDKCall, iEntity, iAttachment, vecOrigin, vecAngles);
	return true;
}

/**
 * Checks whether a given position is in water.
 * Note: Mostly works, but some brushes seem to have water in their contents.
 * Warning: Currently broken and unreliable.
 *
 * @param vecOrigin		Position to check for.
 *
 * @return			True if position is located in the water, false otherwise.
 **/
stock bool IsPositionInWater(float vecOrigin[3])
{
	Handle hTrace = TR_TraceRayEx(vecOrigin, vecOrigin, CONTENTS_WATER, RayType_EndPoint);
	bool bSolid = TR_StartSolid(hTrace);
	delete hTrace;
	return bSolid;
}

/**
 * Sets DSP effect post audio FX.
 *
 * @param iClient			Client index of the player.
 * @param flDelay			Delay before sending effect.
 * @param dspEffectType		DSP effect type see "scripts/dsp_presets.txt"
 *
 * @error			Invalid client index.
 **/
stock void Terror_SetPendingDspEffect(int iClient, float flDelay, int dspEffectType)
{
	static EngineVersion IsEngine;
	if(IsEngine == Engine_Unknown)
		IsEngine = GetEngineVersion();

	// Get CountdownTimer address
	static int timerAddress = -1;
	if(timerAddress == -1)
	{
		if(IsEngine == Engine_Left4Dead2)
			timerAddress = FindSendPropInfo("CTerrorPlayer", "m_iBloodyHandsLevel") + 8;
		else
			timerAddress = FindSendPropInfo("CTerrorPlayer", "m_bloodyHandsPercent") + 4;
	}

	//timerAddress + 4 = Duration
	//timerAddress + 8 = TimeStamp
	SetEntDataFloat(iClient, timerAddress + 4, flDelay);
	SetEntDataFloat(iClient, timerAddress + 8, GetGameTime() + flDelay);
	SetEntData(iClient, timerAddress + 12, dspEffectType);
}

/**
 * Sets the adrenaline effect duration of a survivor.
 *
 * @param iClient		Client index of the survivor.
 * @param flDuration		Duration of the adrenaline effect.
 *
 * @error			Invalid client index.
 **/
// L4D2 only.
stock void Terror_SetAdrenalineTime(int iClient, float flDuration)
{
	// Get CountdownTimer address
	static int timerAddress = -1;
	if(timerAddress == -1)
	{
		timerAddress = FindSendPropInfo("CTerrorPlayer", "m_bAdrenalineActive") - 12;
	}
	
	//timerAddress + 4 = Duration
	//timerAddress + 8 = TimeStamp
	SetEntDataFloat(iClient, timerAddress + 4, flDuration);
	SetEntDataFloat(iClient, timerAddress + 8, GetGameTime() + flDuration);
	SetEntProp(iClient, Prop_Send, "m_bAdrenalineActive", (flDuration <= 0.0 ? 0 : 1), 1);
}

/**
 * Returns the remaining duration of a survivor's adrenaline effect.
 *
 * @param iClient		Client index of the survivor.
 *
 * @return 			Remaining duration or -1.0 if there's no effect.
 * @error			Invalid client index.
 **/
// L4D2 only.
stock float Terror_GetAdrenalineTime(int iClient)
{
	// Get CountdownTimer address
	static int timerAddress = -1;
	if(timerAddress == -1)
	{
		timerAddress = FindSendPropInfo("CTerrorPlayer", "m_bAdrenalineActive") - 12;
	}
	
	if(GetEntProp(iClient, Prop_Send, "m_bAdrenalineActive", 1) < 1)
		return -1.0;
	
	//timerAddress + 8 = TimeStamp
	float flGameTime = GetGameTime();
	float flTime = GetEntDataFloat(iClient, timerAddress + 8);
	if(flTime <= flGameTime)
		return -1.0;
	
	return flTime - flGameTime;
}

/**
 * Calls CTerrorPlayer::OnRevivedByDefibrillator()
 *
 * @param iRevivee 		Client index be revived.
 * @param iReviver		Client index who revived can be same as revivee.
 * @param iDeathModel		Death model index, dead survivor model (survivor_death_model).
 *
 * @return			True if revive was successful false otherwise.
 * @error			Invalid entity index or invalid attachment name,
 *					signature for function not found, or SDKCall failed.
 **/
stock bool Terror_ReviveDeathModel(int iRevivee, int iReviver, int iDeathModel)
{
	static Handle hSDKCall;
	if(hSDKCall == null)
	{
		Handle hGamedata;
		GetGameData(hGamedata);
		
		StartPrepSDKCall(SDKCall_Player);
		if(PrepSDKCall_SetFromConf(hGamedata, SDKConf_Signature, "CTerrorPlayer::OnRevivedByDefibrillator"))
		{
			PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
			PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
			hSDKCall = EndPrepSDKCall();
			if(hSDKCall == null)
				LogError("Unable to prep 'CTerrorPlayer::OnRevivedByDefibrillator'");
		}
		else
		{
			LogError("Error finding the 'CTerrorPlayer::OnRevivedByDefibrillator' signature.");
		}
		delete hGamedata;
		if(hSDKCall == null)
			return false;
	}
	SDKCall(hSDKCall, iRevivee, iReviver, iDeathModel);
	return true;
}

/**
 * Create a physics explosion that does not affect players.
 *
 * @param vecOrigin		Origin of the explosion.
 * @param iMagnitude		Magnitude of the explosion limit of 100, explode more than once for more power.
 * @param flRadius		Radius of the explosion.
 * @param bDamage		True to damage props, false otherwise.
 * @param flInnerRadius		If not zero, the LOS is calculated from a point intersecting this sphere.
 *
 * @error			Failed to create explosion.
 **/
stock void PhysicsExplode(float vecOrigin[3], int iMagnitude, float flRadius, bool bDamage=false, float flInnerRadius=0.0)
{
	static int iBoom = INVALID_ENT_REFERENCE;
	
	if(iBoom == INVALID_ENT_REFERENCE || !IsValidEntity(iBoom))
	{
		iBoom = EntIndexToEntRef(CreateEntityByName("env_physexplosion"));
		if(iBoom == INVALID_ENT_REFERENCE)
			return;
	
		DispatchKeyValue(iBoom, "spawnflags", "0");
		DispatchSpawn(iBoom);
	}
	
	if(bDamage)
	{
		DispatchKeyValue(iBoom, "spawnflags", "8");
	}
	else
	{
		DispatchKeyValue(iBoom, "spawnflags", "9");
	}
	
	char sBuf[32];
	IntToString(iMagnitude, sBuf, sizeof(sBuf));
	DispatchKeyValue(iBoom, "magnitude", sBuf);
	
	IntToString(RoundFloat(flRadius), sBuf, sizeof(sBuf));
	DispatchKeyValue(iBoom, "radius", sBuf);
	DispatchKeyValueFloat(iBoom, "inner_radius", flInnerRadius);

	TeleportEntity(iBoom, vecOrigin, NULL_VECTOR, NULL_VECTOR);

	AcceptEntityInput(iBoom, "Explode");
	RemoveEntity(iBoom);
}

///////////////////////////////////////Temp ents

/**
 * Sets up an invisible explosion to push client-side physics.
 * Note: The grenade launcher uses this to push bodies and other objects.
 * Note: Left 4 Dead 2 only.
 *
 * @param vecOrigin		Origin of the explosion in world space.
 * @param flRadius		Radius of the explosion.
 * @param flMagnitude		Magnitude of the explosion.
 *
 * @error			Invalid effect index.
 **/
// L4D2 only.
stock void TE_SetupExplodeForce(float vecOrigin[3], float flRadius, float flMagnitude)
{
	static int iEffectIndex = INVALID_STRING_INDEX;
	if(iEffectIndex < 0)
	{
		iEffectIndex = __FindStringIndex2(FindStringTable("EffectDispatch"), "ExplosionForce");
		if(iEffectIndex == INVALID_STRING_INDEX)
			SetFailState("Unable to find EffectDispatch/ExplosionForce index");
		
	}
	
	TE_Start("EffectDispatch");
	TE_WriteNum("m_iEffectName", iEffectIndex);
	TE_WriteFloat("m_vOrigin.x", vecOrigin[0]);
	TE_WriteFloat("m_vOrigin.y", vecOrigin[1]);
	TE_WriteFloat("m_vOrigin.z", vecOrigin[2]);
	TE_WriteFloat("m_flRadius", flRadius);
	TE_WriteFloat("m_flMagnitude", flMagnitude);
}

/**
 * Creates a clientside physics prop.
 *
 * @param vecOrigin		Origin of the prop in world space.
 * @param iPrecacheModel	Stringtable index of the prop.
 * @param vecModelAngles	Angles of the prop.
 * @param vecVelocity		Velocity used by explosion for pushing the prop.
 * @param iFlags		Flags to apply to the prop. Note: A value of "1" applies auto-despawn, unsupported models will despawn next client tick.
 * @param iEffects		Effects to apply to the prop.
 * @param iSkin			Skin of the prop's model.
 * @param RGB			Color of the prop's model.
 **/
stock void TE_SetupPhysicsProp(float vecModelOrigin[3], 
								int iPrecacheModel, 
								float vecModelAngles[3]={0.0, ...}, 
								float vecVelocity[3]={0.0, ...}, 
								int iFlags=0,
								int iEffects=0,
								int iSkin=0,
								int RGB[3]={255, ...})
{
	TE_Start("physicsprop");
	TE_WriteVector("m_vecOrigin", vecModelOrigin);
	TE_WriteFloat("m_angRotation[0]", vecModelAngles[0]);
	TE_WriteFloat("m_angRotation[1]", vecModelAngles[1]);
	TE_WriteFloat("m_angRotation[2]", vecModelAngles[2]);
	TE_WriteVector("m_vecVelocity", vecVelocity);
	TE_WriteNum("m_nModelIndex", iPrecacheModel);
	TE_WriteNum("m_nFlags", iFlags);
	TE_WriteNum("m_nEffects", iEffects);
	TE_WriteNum("r", RGB[0]);
	TE_WriteNum("g", RGB[1]);
	TE_WriteNum("b", RGB[2]);
}

/**
 * Sets up a dynamic light.
 * Note: Only one can exist client-side per tick. New lights will replace old ones.
 *
 * @param vecOrigin		Origin of the light in world space.
 * @param RGB			Color of the light.
 * @param flRadius		Radius of the light.
 * @param flTime		Time until the light despawns.
 * @param flDecay		Radius decay speed of the light.
 * @param exponent		Brightness of the light.
 *
 * @return			True on success, false on failure.
 **/
stock void TE_SetupDynamicLight(float vecOrigin[3], int RGB[3], float flRadius, float flTime, float flDecay=0.0, int exponent=0)
{
	TE_Start("Dynamic Light");
	
	TE_WriteVector("m_vecOrigin", vecOrigin);
	TE_WriteNum("r", RGB[0]);
	TE_WriteNum("g", RGB[1]);
	TE_WriteNum("b", RGB[2]);
	TE_WriteNum("exponent", exponent);
	TE_WriteFloat("m_fRadius", flRadius);
	TE_WriteFloat("m_fTime", flTime);
	TE_WriteFloat("m_fDecay", flDecay);
}

/**
 * Sets up a particle effect's attachment.
 *
 * @param iParticleIndex 	Particle index.
 * @param sAttachmentName	Name of attachment.
 * @param iEntIndex		Entity index of the particle.
 * @param bFollow		True to make the particle follow attachment points, false otherwise.
 *
 * @error			Invalid effect index.
 **/
stock void TE_SetupParticleAttachment(int iParticleIndex, int iAttachmentIndex, int iEntIndex, bool bFollow=false)
{
	static float vecDummy[3]={0.0, 0.0, 0.0};
	static EngineVersion IsEngine;
	if(IsEngine == Engine_Unknown)
		IsEngine = GetEngineVersion();
	
	TE_Start("EffectDispatch");
	
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vOrigin.x"	:"m_vOrigin[0]", vecDummy[0]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vOrigin.y"	:"m_vOrigin[1]", vecDummy[1]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vOrigin.z"	:"m_vOrigin[2]", vecDummy[2]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vStart.x"	:"m_vStart[0]", vecDummy[0]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vStart.y"	:"m_vStart[1]", vecDummy[1]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vStart.z"	:"m_vStart[2]", vecDummy[2]);

	static int iEffectIndex = INVALID_STRING_INDEX;
	if(iEffectIndex < 0)
	{
		iEffectIndex = __FindStringIndex2(FindStringTable("EffectDispatch"), "ParticleEffect");
		if(iEffectIndex == INVALID_STRING_INDEX)
			SetFailState("Unable to find EffectDispatch/ParticleEffect indexes");
	}

	TE_WriteNum("m_iEffectName", iEffectIndex);
	TE_WriteNum("m_nHitBox", iParticleIndex);
	TE_WriteNum("entindex", iEntIndex);
	TE_WriteNum("m_nAttachmentIndex", iAttachmentIndex);
	TE_WriteNum("m_fFlags", 1);	//needed for attachments to work


	TE_WriteVector("m_vAngles", vecDummy);
	TE_WriteFloat("m_flMagnitude", 0.0);
	TE_WriteFloat("m_flScale", 1.0);
	TE_WriteFloat("m_flRadius", 0.0);
	
	if(IsEngine == Engine_Left4Dead2)
	{
		TE_WriteNum("m_nDamageType", bFollow ? 5 : 4);
	}
	else
	{
		TE_WriteNum("m_nDamageType", bFollow ? 4 : 3);
	}
}

/**
 * Sets up a particle effect.
 * Note: Particles that need an ending point to show do not use particle angles usually.
 * Warning: Looping particles will last forever with no known way of removing them.
 *
 * @param iParticleIndex 	Particle index.
 * @param vecParticleStartPos	Starting point of the particle in world space.
 * @param vecParticleEndPos	Ending point of the particle in world space.
 * @param vecParticleAngles	Angles of the particle.
 * @param iEntity	Entity owner if entity dies so does particle.
 *
 * @error			Invalid effect index.
 **/
stock void TE_SetupParticle(int iParticleIndex, float vecParticleStartPos[3], float vecParticleEndPos[3]={0.0, 0.0, 0.0}, float vecParticleAngles[3]={0.0, 0.0, 0.0}, int iEntity=0)
{
	static EngineVersion IsEngine;
	if(IsEngine == Engine_Unknown)
		IsEngine = GetEngineVersion();
	
	TE_Start("EffectDispatch");
	
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vOrigin.x"	:"m_vOrigin[0]", vecParticleStartPos[0]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vOrigin.y"	:"m_vOrigin[1]", vecParticleStartPos[1]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vOrigin.z"	:"m_vOrigin[2]", vecParticleStartPos[2]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vStart.x"	:"m_vStart[0]", vecParticleEndPos[0]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vStart.y"	:"m_vStart[1]", vecParticleEndPos[1]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vStart.z"	:"m_vStart[2]", vecParticleEndPos[2]);

	static int iEffectIndex = INVALID_STRING_INDEX;
	if(iEffectIndex < 0)
	{
		iEffectIndex = __FindStringIndex2(FindStringTable("EffectDispatch"), "ParticleEffect");
		if(iEffectIndex == INVALID_STRING_INDEX)
			SetFailState("Unable to find EffectDispatch/ParticleEffect indexes");

	}

	TE_WriteNum("m_iEffectName", iEffectIndex);
	TE_WriteNum("m_nHitBox", iParticleIndex);

	TE_WriteNum("entindex", iEntity);
	TE_WriteNum("m_nAttachmentIndex", 0);
	TE_WriteNum("m_fFlags", 0);
	
	TE_WriteVector("m_vAngles", vecParticleAngles);
	
	TE_WriteFloat("m_flMagnitude", 0.0);
	TE_WriteFloat("m_flScale", 1.0);
	TE_WriteFloat("m_flRadius", 0.0);
	TE_WriteNum("m_nDamageType", 0);
}

/**
 * Sets up a particle effect to follow an entity's origin (0, 0, 0).
 *
 * @param iParticleIndex 	Particle index.
 * @param iEntIndex		Entity index to follow.
 * @param vecParticleAngles	Angles of the particle.
 *
 * @error			Invalid effect index.
 **/
stock void TE_SetupParticleFollowEntity(int iParticleIndex, int iEntIndex, float vecParticleAngles[3]={0.0, 0.0, 0.0})
{
	static float vecDummy[3]={0.0, 0.0, 0.0};
	static EngineVersion IsEngine;
	if(IsEngine == Engine_Unknown)
		IsEngine = GetEngineVersion();
	
	TE_Start("EffectDispatch");
	
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vOrigin.x"	:"m_vOrigin[0]", vecDummy[0]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vOrigin.y"	:"m_vOrigin[1]", vecDummy[1]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vOrigin.z"	:"m_vOrigin[2]", vecDummy[2]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vStart.x"	:"m_vStart[0]", vecDummy[0]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vStart.y"	:"m_vStart[1]", vecDummy[1]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vStart.z"	:"m_vStart[2]", vecDummy[2]);

	static int iEffectIndex = INVALID_STRING_INDEX;
	if(iEffectIndex < 0)
	{
		iEffectIndex = __FindStringIndex2(FindStringTable("EffectDispatch"), "ParticleEffect");
		if(iEffectIndex == INVALID_STRING_INDEX)
			SetFailState("Unable to find EffectDispatch/ParticleEffect indexes");
	}

	TE_WriteNum("m_iEffectName", iEffectIndex);
	TE_WriteNum("m_nHitBox", iParticleIndex);
	TE_WriteNum("entindex", iEntIndex);
	TE_WriteNum("m_nAttachmentIndex", 0);
	TE_WriteNum("m_fFlags", 1);


	TE_WriteVector("m_vAngles", vecParticleAngles);
	TE_WriteFloat("m_flMagnitude", 0.0);
	TE_WriteFloat("m_flScale", 1.0);
	TE_WriteFloat("m_flRadius", 0.0);
	
	TE_WriteNum("m_nDamageType", 1);
}

/**
 * Sets up a particle effect to follow an entity's origin (0, 0, 0) while maintaining offset.
 * Note: Left 4 Dead 2 only maintains offset from the world origin of the parent, which is
 *	not reliable since this is not a server side entity, so lag can miscalculate the offset.
 *
 * @param iParticleIndex 	Particle index.
 * @param iEntIndex		Entity index to follow.
 * @param vecParticleStartPos	Starting point to maintain offset from.
 * @param vecParticleAngles	Angles of the particle.
 *
 * @error			Invalid effect index.
 **/
// L4D2 only.
stock void TE_SetupParticleFollowEntity_MaintainOffset(int iParticleIndex, int iEntIndex, float vecParticleStartPos[3], float vecParticleAngles[3]={0.0, 0.0, 0.0})
{
	static float vecDummy[3]={0.0, 0.0, 0.0};
	static EngineVersion IsEngine;
	if(IsEngine == Engine_Unknown)
		IsEngine = GetEngineVersion();
	
	TE_Start("EffectDispatch");
	
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vOrigin.x"	:"m_vOrigin[0]", vecParticleStartPos[0]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vOrigin.y"	:"m_vOrigin[1]", vecParticleStartPos[1]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vOrigin.z"	:"m_vOrigin[2]", vecParticleStartPos[2]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vStart.x"	:"m_vStart[0]", vecDummy[0]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vStart.y"	:"m_vStart[1]", vecDummy[1]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vStart.z"	:"m_vStart[2]", vecDummy[2]);

	static int iEffectIndex = INVALID_STRING_INDEX;
	if(iEffectIndex < 0)
	{
		iEffectIndex = __FindStringIndex2(FindStringTable("EffectDispatch"), "ParticleEffect");
		if(iEffectIndex == INVALID_STRING_INDEX)
			SetFailState("Unable to find EffectDispatch/ParticleEffect indexes");
	}

	TE_WriteNum("m_iEffectName", iEffectIndex);
	TE_WriteNum("m_nHitBox", iParticleIndex);
	TE_WriteNum("entindex", iEntIndex);
	TE_WriteNum("m_nAttachmentIndex", 0);
	TE_WriteNum("m_fFlags", 1);


	TE_WriteVector("m_vAngles", vecParticleAngles);
	TE_WriteFloat("m_flMagnitude", 0.0);
	TE_WriteFloat("m_flScale", 1.0);
	TE_WriteFloat("m_flRadius", 0.0);
	
	TE_WriteNum("m_nDamageType", 3);
}

/**
 * Set up particle that attaches to points on a model that is predefined in particle i think.
 *
 * @param iParticleIndex 	Particle index.
 * @param iEntIndex		Entity index to attach.
 * @param vecParticleStartPos	Starting point valve uses it
 *
 * @error			Invalid effect index.
 **/
stock void TE_SetupParticle_ControlPoints(int iParticleIndex, int iEntIndex, float vecParticleStartPos[3])
{
	static float vecDummy[3]={0.0, 0.0, 0.0};
	static EngineVersion IsEngine;
	if(IsEngine == Engine_Unknown)
		IsEngine = GetEngineVersion();
	
	TE_Start("EffectDispatch");
	
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vOrigin.x"	:"m_vOrigin[0]", vecParticleStartPos[0]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vOrigin.y"	:"m_vOrigin[1]", vecParticleStartPos[1]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vOrigin.z"	:"m_vOrigin[2]", vecParticleStartPos[2]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vStart.x"	:"m_vStart[0]", vecDummy[0]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vStart.y"	:"m_vStart[1]", vecDummy[1]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vStart.z"	:"m_vStart[2]", vecDummy[2]);

	static int iEffectIndex = INVALID_STRING_INDEX;
	if(iEffectIndex < 0)
	{
		iEffectIndex = __FindStringIndex2(FindStringTable("EffectDispatch"), "ParticleEffect");
		if(iEffectIndex == INVALID_STRING_INDEX)
			SetFailState("Unable to find EffectDispatch/ParticleEffect indexes");
	}

	TE_WriteNum("m_iEffectName", iEffectIndex);
	TE_WriteNum("m_nHitBox", iParticleIndex);
	TE_WriteNum("entindex", iEntIndex);
	TE_WriteNum("m_nAttachmentIndex", 255);
	TE_WriteNum("m_fFlags", 1);


	TE_WriteVector("m_vAngles", vecDummy);
	TE_WriteFloat("m_flMagnitude", 0.0);
	TE_WriteFloat("m_flScale", 1.0);
	TE_WriteFloat("m_flRadius", 0.0);
	
	TE_WriteNum("m_nDamageType", 0);
}

/**
 * Sets up a particle effect via its name to follow an entity's origin (0, 0, 0).
 *
 * @param sParticleName 	Name of the particle.
 * @param iEntIndex		Entity index to follow.
 * @param vecParticleAngles	Angles of the particle.
 *
 * @return			True on success, false on failure.
 * @error			Invalid particle stringtable index.
 **/
stock bool TE_SetupParticleFollowEntity_Name(char[] sParticleName, int iEntIndex, float vecParticleAngles[3]={0.0, 0.0, 0.0})
{
	int iParticleStringIndex = GetParticleIndex(sParticleName);
	if(iParticleStringIndex == INVALID_STRING_INDEX)
	{
		return false;
	}
	TE_SetupParticleFollowEntity(iParticleStringIndex, iEntIndex, vecParticleAngles);
	return true;
}

/**
 * Sets up a particle effect via its name to follow an entity's origin (0, 0, 0) while maintaining offset.
 * Note: Left 4 Dead 2 only maintains offset from the world origin of the parent, which is
 *	not reliable since this is not a server side entity, so lag can miscalculate the offset.
 *
 * @param sParticleName 	Name of the particle.
 * @param iEntIndex		Entity index to follow.
 * @param vecParticleStartPos	Starting point to maintain offset from.
 * @param vecParticleAngles	Angles of the particle.
 *
 * @return			True on success, false on failure.
 * @error			Invalid particle stringtable index.
 **/
stock bool TE_SetupParticleFollowEntity_MaintainOffset_Name(char[] sParticleName, int iEntIndex, float vecParticleStartPos[3], float vecParticleAngles[3]={0.0, 0.0, 0.0})
{
	int iParticleStringIndex = GetParticleIndex(sParticleName);
	if(iParticleStringIndex == INVALID_STRING_INDEX)
	{
		return false;
	}
	TE_SetupParticleFollowEntity_MaintainOffset(iParticleStringIndex, iEntIndex, vecParticleStartPos, vecParticleAngles);
	return true;
}

/**
 * Sets up a particle effect via a name.
 * Note: Particles that need an ending point to show do not use particle angles usually.
 * Warning: Looping particles will last forever with no known way of removing them.
 *
 * @param sParticleName		Name of the particle.
 * @param vecParticleStartPos	Starting point of the particle in world space.
 * @param vecParticleEndPos	Ending point of the particle in world space.
 * @param vecParticleAngles	Angles of the particle.
 * @param iEntity	Entity owner if entity dies so does particle.
 *
 * @return			True on success, false on failure.
 * @error			Invalid effect index.
 **/
stock bool TE_SetupParticle_Name(char[] sParticleName, float vecParticleStartPos[3], float vecParticleEndPos[3]={0.0, 0.0, 0.0}, float vecParticleAngles[3]={0.0, 0.0, 0.0}, int iEntity=0)
{
	int iParticleStringIndex = GetParticleIndex(sParticleName);
	if(iParticleStringIndex == INVALID_STRING_INDEX)
	{
		return false;
	}
	TE_SetupParticle(iParticleStringIndex, vecParticleStartPos, vecParticleEndPos, vecParticleAngles, iEntity);
	return true;
}

/**
 * Sets up a particle effect's attachment via a name.
 * Note: Only follows entities that have attachment points.
 * Warning: This function does not validate if the attachment is valid.
 *
 * @param sParticleName		Name of the particle.
 * @param sAttachmentName	Name of the attachment.
 * @param iEntIndex		Entity index of the particle.
 * @param bFollow		True to make the particle follow attachment points, false otherwise.
 *
 * @return			True on success, false on failure.
 * @error			Invalid particle stringtable index.
 **/
stock bool TE_SetupParticleAttachment_Names(char[] sParticleName, char[] sAttachmentName, int iEntIndex, bool bFollow=false)
{
	int iParticleStringIndex = GetParticleIndex(sParticleName);
	if(iParticleStringIndex == INVALID_STRING_INDEX)
	{
		return false;
	}
	int iAttachmentIndex = LookupAttachment(iEntIndex, sAttachmentName);
	TE_SetupParticleAttachment(iParticleStringIndex, iAttachmentIndex, iEntIndex, bFollow);
	return true;
}

/**
 * Stops all particle effects emitted on an entity, such as attachment followers.
 * Note: Currently no way to target particles.
 *
 * @param iEntIndex		Entity index to stop all particles from emitting on.
 *
 * @error			Invalid effect index.
 **/
stock void TE_SetupStopAllParticles(int iEntIndex)
{
	static float vecDummy[3]={0.0, 0.0, 0.0};
	static EngineVersion IsEngine;
	if(IsEngine == Engine_Unknown)
		IsEngine = GetEngineVersion();
	
	TE_Start("EffectDispatch");
	
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vOrigin.x"	:"m_vOrigin[0]", vecDummy[0]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vOrigin.y"	:"m_vOrigin[1]", vecDummy[1]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vOrigin.z"	:"m_vOrigin[2]", vecDummy[2]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vStart.x"	:"m_vStart[0]", vecDummy[0]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vStart.y"	:"m_vStart[1]", vecDummy[1]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vStart.z"	:"m_vStart[2]", vecDummy[2]);

	static int iEffectIndex = INVALID_STRING_INDEX;
	if(iEffectIndex < 0)
	{
		iEffectIndex = __FindStringIndex2(FindStringTable("EffectDispatch"), "ParticleEffectStop");
		if(iEffectIndex == INVALID_STRING_INDEX)
			SetFailState("Unable to find EffectDispatch/ParticleEffectStop indexes");
	}

	TE_WriteNum("m_iEffectName", iEffectIndex);
	TE_WriteNum("m_nHitBox", 0);

	TE_WriteNum("entindex", iEntIndex);
	TE_WriteNum("m_nAttachmentIndex", 0);
	TE_WriteNum("m_fFlags", 1);
	TE_WriteVector("m_vAngles", vecDummy);
	TE_WriteFloat("m_flMagnitude", 0.0);
	TE_WriteFloat("m_flScale", 0.0);
	TE_WriteFloat("m_flRadius", 0.0);
	TE_WriteNum("m_nDamageType", 0);
}

/**
 * Sets up tracer sound for client-side.
 * Note: Uses client-side ray from two points to play wizz sound.
 * Note: Wizz sound is directional.
 *
 * @param vecParticleStartPos	Starting position of the sound in world space.
 * @param vecParticleEndPos	Ending position of the sound in world space.
 *
 * @error			Invalid effect index.
 **/
stock void TE_SetupTracerSound(float vecParticleStartPos[3], float vecParticleEndPos[3])
{
	static float vecDummy[3]={0.0, 0.0, 0.0};
	static EngineVersion IsEngine;
	if(IsEngine == Engine_Unknown)
		IsEngine = GetEngineVersion();
	
	TE_Start("EffectDispatch");
	
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vOrigin.x"	:"m_vOrigin[0]", vecParticleStartPos[0]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vOrigin.y"	:"m_vOrigin[1]", vecParticleStartPos[1]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vOrigin.z"	:"m_vOrigin[2]", vecParticleStartPos[2]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vStart.x"	:"m_vStart[0]", vecParticleEndPos[0]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vStart.y"	:"m_vStart[1]", vecParticleEndPos[1]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vStart.z"	:"m_vStart[2]", vecParticleEndPos[2]);

	static int iEffectIndex = INVALID_STRING_INDEX;
	if(iEffectIndex < 0)
	{
		iEffectIndex = __FindStringIndex2(FindStringTable("EffectDispatch"), "TracerSound");
		if(iEffectIndex == INVALID_STRING_INDEX)
			SetFailState("Unable to find EffectDispatch/TracerSound indexes");

	}

	TE_WriteNum("m_iEffectName", iEffectIndex);
	TE_WriteNum("m_nHitBox", 0);

	TE_WriteNum("entindex", 0);
	TE_WriteNum("m_nAttachmentIndex", 0);
	
	TE_WriteNum("m_fFlags", 1);
	
	TE_WriteVector("m_vAngles", vecDummy);
	
	TE_WriteFloat("m_flMagnitude", 0.0);
	TE_WriteFloat("m_flScale", 0.0);
	TE_WriteFloat("m_flRadius", 0.0);
	TE_WriteNum("m_nDamageType", 0);
}

/**
 * Credit: Dysphie for decal example
 * Note to apply to static props pass 0(world) to iTarget and iHitbox is used for static prop index TR_GetHitBoxIndex() to trace it.
 *
 * @param vecOrigin 		Origin of the decal in world space.
 * @param vecStart 		Starting point of the decal's origin.
 * @param iTarget 		Entity index of the target to splash the decal on.
 * @param iHitbox 		Hitbox or bodygroup to apply decal on. (Only required for static props.)
 * @param iDecalIndex		Decal index in the decal stringtable.
 **/
stock void TE_SetupEntityDecal(float vecOrigin[3], float vecStart[3], int iTarget, int iHitbox=0, int iPrecacheDecal)
{
	TE_Start("Entity Decal");
	TE_WriteVector("m_vecOrigin", vecOrigin);
	TE_WriteVector("m_vecStart", vecStart);
	TE_WriteNum("m_nEntity", iTarget);
	TE_WriteNum("m_nHitbox", iHitbox);
	TE_WriteNum("m_nIndex", iPrecacheDecal);
}

/**
 * Credit: Dysphie for decal example
 * Sets up a world decal.
 *
 * @param vecOrigin 		Origin of the decal in world space.
 * @param iDecalIndex		Decal index in the decal stringtable,
 **/
stock void TE_SetupWorldDecal(float vecOrigin[3], int iPrecacheDecal)
{
	TE_Start("World Decal");
	TE_WriteVector("m_vecOrigin", vecOrigin);
	TE_WriteNum("m_nIndex", iPrecacheDecal);
}

/**
 * Sets up a decal from a traceray.
 *
 * @param hTR 				Pass traceray handle or INVALID_HANDLE to use global trace result.
 * @param sDecalName		Name of the decal.
 *
 * @return				true if decal was setup false otherwise.
 * @error				Invaid Handle.
 **/
stock bool TE_SetupDecal_FromTrace(Handle hTR=INVALID_HANDLE, char[] sDecalName)
{
	if(!TR_DidHit(hTR))
		return false;
	
	int iSurf = TR_GetSurfaceFlags(hTR);
	if((iSurf & SURF_NODECALS) || (iSurf & SURF_NODRAW) || (iSurf & SURF_SKY))
	{
		return false;
	}
	
	int iPrecacheDecal = GetDecalIndex(sDecalName);
	if(iPrecacheDecal == INVALID_STRING_TABLE)
		return false;
	
	float vecStart[3];
	float vecEnd[3];
	int iTarget = TR_GetEntityIndex(hTR);
	int iHitbox = TR_GetHitBoxIndex(hTR);
	TR_GetStartPosition(hTR, vecStart);
	TR_GetEndPosition(vecEnd, hTR);
	
	if(iTarget == 0)
	{
		if(iHitbox)
		{
			TE_SetupEntityDecal(vecEnd, vecStart, iTarget, iHitbox, iPrecacheDecal);
		}
		else
		{
			TE_SetupWorldDecal(vecEnd, iPrecacheDecal);
		}
	}
	else
	{
		TE_SetupEntityDecal(vecEnd, vecStart, iTarget, iHitbox, iPrecacheDecal);
	}
	return true;
}

/**
 * Gets a Decal index or late precaches it.
 * Note: Cache decal in OnMapStart() with PrecacheDecal to avoid them spewing errors.
 *
 * @param sDecalName		Name of the particle system.
 *
 * @return			The decal index or INVALID_STRING_INDEX on error.
 * @error			Invalid decal stringtable index.
 **/
stock int GetDecalIndex(char[] sDecalName)
{
	int iDecalIndex;
	if(!IsDecalPrecached(sDecalName))
	{
		iDecalIndex = PrecacheDecal(sDecalName);
		
#if !defined DISABLE_PRINT_PRECACHE_ERRORS
		if(iDecalIndex == INVALID_STRING_INDEX)
		{
			LogError("Unable to late precache of decal '%s'", sDecalName);
		}
		else
		{
			LogError("Late precache of decal '%s'", sDecalName);
		}
#endif

	}
	else
	{
		iDecalIndex = PrecacheDecal(sDecalName);
	}
	return iDecalIndex;
}


/**
 * Gets a particle system index or late precaches it.
 * Note: Cache particle systems in OnMapStart() with Precache_Particle_System to avoid them spewing errors.
 *
 * @param sParticleName		Name of the particle system.
 *
 * @return			The particle system index or INVALID_STRING_INDEX on error.
 * @error			Invalid particle stringtable index.
 **/
stock int GetParticleIndex(char[] sParticleName)
{
	static int iParticleTableid = INVALID_STRING_TABLE;
	if(iParticleTableid == INVALID_STRING_TABLE)
	{
		iParticleTableid = FindStringTable("ParticleEffectNames");
		if(iParticleTableid == INVALID_STRING_TABLE)
			SetFailState("Failed to find 'ParticleEffectNames' stringtable.");
	}
	
	int iParticleStringIndex = __FindStringIndex2(iParticleTableid, sParticleName);
	if(iParticleStringIndex == INVALID_STRING_INDEX)
	{
		iParticleStringIndex = __PrecacheParticleSystem(sParticleName);
		
#if !defined DISABLE_PRINT_PRECACHE_ERRORS
		if(iParticleStringIndex == INVALID_STRING_INDEX)
		{
			LogError("Unable to late precache of particle '%s'", sParticleName);
		}
		else
		{
			LogError("Late precache of particle '%s'", sParticleName);
		}
#endif
	
	}
	return iParticleStringIndex;
}

//Credit smlib https://github.com/bcserv/smlib
/**
 * Rewrite of FindStringIndex, which failed to work correctly in previous tests.
 * Searches for the index of a given string in a stringtable. 
 *
 * @param tableidx		Stringtable index.
 * @param str			String to find.
 * @return			The string index or INVALID_STRING_INDEX on error.
 **/
static stock int __FindStringIndex2(int tableidx, const char[] str)
{
	static char buf[1024];

	int numStrings = GetStringTableNumStrings(tableidx);
	for (int i=0; i < numStrings; i++) {
		ReadStringTable(tableidx, i, buf, sizeof(buf));
		
		if (StrEqual(buf, str)) {
			return i;
		}
	}
	
	return INVALID_STRING_INDEX;
}

//Credit smlib https://github.com/bcserv/smlib
/**
 * Precaches the given particle system.
 * Note: It's best to call this OnMapStart().
 * Note: Code based on Rochellecrab's, thanks.
 *
 * @param particleSystem	Name of the particle system to precache.
 * @return			The particle system index or INVALID_STRING_INDEX on error.
 **/
static stock int __PrecacheParticleSystem(const char[] particleSystem)
{
	static int particleEffectNames = INVALID_STRING_TABLE;

	if (particleEffectNames == INVALID_STRING_TABLE) {
		if ((particleEffectNames = FindStringTable("ParticleEffectNames")) == INVALID_STRING_TABLE) {
			return INVALID_STRING_INDEX;
		}
	}

	int index = __FindStringIndex2(particleEffectNames, particleSystem);
	if (index == INVALID_STRING_INDEX) 
	{
		int numStrings = GetStringTableNumStrings(particleEffectNames);
		if (numStrings >= GetStringTableMaxStrings(particleEffectNames)) 
		{
			return INVALID_STRING_INDEX;
		}

		AddToStringTable(particleEffectNames, particleSystem);
		index = numStrings;
	}

	return index;
}

/**
 * A wrapper function for SMLib's PrecacheParticleSystem to avoid include collisions.
 *
 * @param particlesystem	Name of the particle system to precache.
 *
 * @return			The particle system index or INVALID_STRING_INDEX on error.
 **/
stock int Precache_Particle_System(const char[] particleSystem)
{
	return __PrecacheParticleSystem(particleSystem);
}

/**
 * Get an entity's world space origin.
 * Note: Not all entities may support "CollisionProperty" for getting the center.
 * (https://github.com/LuxLuma/l4d2_structs/blob/master/collision_property.h)
 *
 * @param iEntity 		Entity index to get origin of.
 * @param vecOrigin		Vector to store origin in.
 * @param bCenter		True to get world space center, false otherwise.
 *
 * @error			Invalid entity index.
 **/
stock void GetAbsOrigin(int iEntity, float vecOrigin[3], bool bCenter=false)
{
	GetEntPropVector(iEntity, Prop_Data, "m_vecAbsOrigin", vecOrigin);

	if(bCenter)
	{
		float vecMins[3];
		float vecMaxs[3];
		GetEntPropVector(iEntity, Prop_Send, "m_vecMins", vecMins);
		GetEntPropVector(iEntity, Prop_Send, "m_vecMaxs", vecMaxs);

		vecOrigin[0] += (vecMins[0] + vecMaxs[0]) * 0.5;
		vecOrigin[1] += (vecMins[1] + vecMaxs[1]) * 0.5;
		vecOrigin[2] += (vecMins[2] + vecMaxs[2]) * 0.5;
	}
}


///////////////////////////////////////Sound


/**
 * level boost in some games maybe clamed, e.g. l4d max seems to be 150
 * pitch is clamed between 1-200, this maybe different between games.
 * sndChannel static sound wont be replaced, however if overflowed it wont play any sound until static sounds have finished.
 *
 * @param sample		sound file path.
 * @param origin		origin to emit sound from.
 * @param entity		entity to emit sound from.
 * @param level		sound level attenuation, the wav sound it's self matters.
 * @param pitch		sound pitch.
 * @param sndChannel		sound channel.
 * @param rangeMin		players within the min range sound wont be mixed.
 * @param rangeCurve		range curve until max mix can be achieved.
 * @param levelBoost		add level boost to mixed sounds max rangeCurve will apply levelBoost, half will apply half levelBoost.
 * @param exponent		exponent value to multiply, logarithmic.
 *
 * @error			Invalid client index.
 **/
stock void EmitMixedAmbientSoundToAll(const char[] sample,
				 const float origin[3] = NULL_VECTOR,
				 int entity = SOUND_FROM_PLAYER,
				 int level = SNDLEVEL_NORMAL,
				 int pitch = SNDPITCH_NORMAL,
				 int sndChannel = SNDCHAN_AUTO,
				 float rangeMin,
				 float rangeCurve=1500.0,
				 int levelBoost=0,
				 float exponent=1.0)
{
	for(int i = 1; i <= MaxClients; ++i)
	{
		if(!IsClientInGame(i) || IsFakeClient(i))
			continue;
		
		EmitMixedAmbientSound(i, sample, origin, entity, level, pitch, sndChannel, rangeMin, rangeCurve, levelBoost, exponent);
	}
}

/**
 * level boost in some games maybe clamed, e.g. l4d max seems to be 150
 * pitch is clamed between 1-200, this maybe different between games.
 * sndChannel static sound wont be replaced, however if overflowed it wont play any sound until static sounds have finished.
 *
 * @param sample		sound file path.
 * @param origin		origin to emit sound from.
 * @param entity		entity to emit sound from.
 * @param level		sound level attenuation, the wav sound it's self matters.
 * @param pitch		sound pitch.
 * @param sndChannel		sound channel.
 * @param rangeMin		players within the min range sound wont be mixed.
 * @param rangeCurve		range curve until max mix can be achieved, sample2 is played when 2x this value.
 * @param levelBoost		add level boost to mixed sounds max rangeCurve will apply levelBoost, half will apply half levelBoost.
 * @param exponent		exponent value to multiply, logarithmic.
 * @param sample2		sound file path.
 * @param level2		sound level attenuation.
 * @param pitch2		sound pitch.
 *
 * @error			Invalid client index.
 **/
stock void EmitMixedAmbientSoundToAll_FallBack(const char[] sample,
				 const float origin[3] = NULL_VECTOR,
				 int entity = SOUND_FROM_PLAYER,
				 int level = SNDLEVEL_NORMAL,
				 int pitch = SNDPITCH_NORMAL,
				 int sndChannel = SNDCHAN_AUTO,
				 float rangeMin,
				 float rangeCurve=1500.0,
				 int levelBoost=0,
				 float exponent=1.0,
				 const char[] sample2,
				 int level2 = SNDLEVEL_NORMAL,
				 int pitch2 = SNDPITCH_NORMAL)
{
	for(int i = 1; i <= MaxClients; ++i)
	{
		if(!IsClientInGame(i) || IsFakeClient(i))
			continue;
		
		EmitMixedAmbientSound_FallBack(i, sample, origin, entity, level, pitch, sndChannel, rangeMin, rangeCurve, levelBoost, exponent, sample2, level2, pitch2);
	}
}

/**
 * level boost in some games maybe clamed, e.g. l4d max seems to be 150
 * pitch is clamed between 1-200, this maybe different between games.
 * sndChannel static sound wont be replaced, however if overflowed it wont play any sound until static sounds have finished.
 *
 * @param client		client index.
 * @param sample		sound file path.
 * @param origin		origin to emit sound from.
 * @param entity		entity to emit sound from.
 * @param level		sound level attenuation, the wav sound it's self matters.
 * @param pitch		sound pitch.
 * @param sndChannel		sound channel.
 * @param rangeMin		players within the min range sound wont be mixed.
 * @param rangeCurve		range curve until max mix can be achieved.
 * @param levelBoost		add level boost to mixed sounds max rangeCurve will apply levelBoost, half will apply half levelBoost.
 * @param exponent		exponent value to multiply, logarithmic.
 *
 * @error			Invalid client index.
 **/
stock void EmitMixedAmbientSound(int client, const char[] sample,
				 const float origin[3] = NULL_VECTOR,
				 int entity = SOUND_FROM_PLAYER,
				 int level = SNDLEVEL_NORMAL,
				 int pitch = SNDPITCH_NORMAL,
				 int sndChannel = SNDCHAN_AUTO,
				 float rangeMin,
				 float rangeCurve=1500.0,
				 int levelBoost=0,
				 float exponent=1.0)
{
	static float vecEyePos[3];
	int newPitch;
	float flDist;
	float flDistPercent;
	float flDistMulti;
	int DistLevelBoost;
	int viewEnt = -1;
	
	viewEnt = GetEntPropEnt(client, Prop_Send, "m_hViewEntity");
	if(viewEnt > 0)
	{
		GetAbsOrigin(viewEnt, vecEyePos);
	}
	else
	{
		GetClientEyePosition(client, vecEyePos);
	}
	flDist = GetVectorDistance(origin, vecEyePos);
	
	if(rangeCurve == 0.0)
	{
		LogError("RangeCurve == 0.0");
		return;
	}
	
	flDist = (flDist - rangeMin < 0.0 ? 0.0 : flDist - rangeMin);
	flDistPercent = (flDist / rangeCurve);
	flDistMulti = (flDistPercent * 2) * exponent;
	newPitch = pitch;
	
	if(flDistMulti > 1.0)
	{
		newPitch = RoundToNearest(newPitch / (flDistMulti > 2.0 ? 2.0 : flDistMulti));
	}
	
	DistLevelBoost = RoundToNearest((flDistPercent * exponent) * levelBoost);
	if(DistLevelBoost > levelBoost)
		DistLevelBoost = levelBoost;
	
	EmitSoundToClient(client, sample, entity, sndChannel, level + DistLevelBoost, _, _, newPitch, _, origin);
}

/**
 * level boost in some games maybe clamed, e.g. l4d max seems to be 150
 * pitch is clamed between 1-200, this maybe different between games.
 * sndChannel static sound wont be replaced, however if overflowed it wont play any sound until static sounds have finished.
 *
 * @param client		client index.
 * @param sample		sound file path.
 * @param origin		origin to emit sound from.
 * @param entity		entity to emit sound from.
 * @param level		sound level attenuation, the wav sound it's self matters.
 * @param pitch		sound pitch.
 * @param sndChannel		sound channel.
 * @param rangeMin		players within the min range sound wont be mixed.
 * @param rangeCurve		range curve until max mix can be achieved, sample2 is played when 2x this value.
 * @param levelBoost		add level boost to mixed sounds max rangeCurve will apply levelBoost, half will apply half levelBoost.
 * @param exponent		exponent value to multiply, logarithmic.
 * @param sample2		sound file path.
 * @param level2		sound level attenuation.
 * @param pitch2		sound pitch.
 *
 * @error			Invalid client index.
 **/
stock void EmitMixedAmbientSound_FallBack(int client, const char[] sample,
				 const float origin[3] = NULL_VECTOR,
				 int entity = SOUND_FROM_PLAYER,
				 int level = SNDLEVEL_NORMAL,
				 int pitch = SNDPITCH_NORMAL,
				 int sndChannel = SNDCHAN_AUTO,
				 float rangeMin,
				 float rangeCurve=1500.0,
				 int levelBoost=0,
				 float exponent=1.0,
				 const char[] sample2,
				 int level2 = SNDLEVEL_NORMAL,
				 int pitch2 = SNDPITCH_NORMAL)
{
	static float vecEyePos[3];
	int newPitch;
	float flDist;
	float flDistPercent;
	float flDistMulti;
	int DistLevelBoost;
	int viewEnt = -1;

	viewEnt = GetEntPropEnt(client, Prop_Send, "m_hViewEntity");
	if(viewEnt > 0)
	{
		GetAbsOrigin(viewEnt, vecEyePos);
	}
	else
	{
		GetClientEyePosition(client, vecEyePos);
	}
	flDist = GetVectorDistance(origin, vecEyePos);
	
	if(rangeCurve == 0.0)
	{
		LogError("RangeCurve == 0.0");
		return;
	}
	
	flDist = (flDist - rangeMin < 0.0 ? 0.0 : flDist - rangeMin);
	flDistPercent = (flDist / rangeCurve);
	flDistMulti = (flDistPercent * 2) * exponent;
	
	if(flDistMulti >= 2.0)
	{
		EmitSoundToClient(client, sample2, entity, sndChannel, level2, _, _, pitch2, _, origin);
		return;
	}
	
	newPitch = pitch;
	if(flDistMulti > 1.0)
	{
		newPitch = RoundToNearest(newPitch / (flDistMulti > 2.0 ? 2.0 : flDistMulti));
	}
	
	DistLevelBoost = RoundToNearest((flDistPercent * exponent) * levelBoost);
	if(DistLevelBoost > levelBoost)
		DistLevelBoost = levelBoost;
	
	EmitSoundToClient(client, sample, entity, sndChannel, level + DistLevelBoost, _, _, newPitch, _, origin);
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////Legacy Particle Stock///////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Creates a tempent particle.
 *
 * @param iParticleIndex	Particle index location in the "ParticleEffectNames" stringtable.
 * @param iEntIndex		Entity index to attach particle to.
 * @param fDelay		Delay for the TE_SendToAll function.
 * @param SendToAll		True to send to all clients, false otherwise. You must call the send function yourself if sending to specific clients.
 * @param sParticleName		Name of the particle to find the index with. Only used if the particle index is invalid.
 * @param iAttachmentIndex	Attachment index of the particle. Decompile the model to retrieve this value.
 * @param fParticleAngles	Angles of the particle. Usually effects particles that have no gravity.
 * @param iFlags		Flags of the particle. Note: A value of "1" is required for attachment points and damage types.
 * @param iDamageType		The damage type of the particle. (Used in impact effect dispatches and attachment points need to be set to use.)
 * @param fMagnitude		The magnitude of the particle. (Needs testing; used in pipe bomb blast.)
 * @param fScale		The scale of the particle (doesn't apply to most particles). (Needs testing.)
 *
 * @return			True on success, false on failure.
 * @error			Invalid effect index or invalid particle stringtable index.
 **/
#pragma deprecated Used for backwards compatibility.
stock bool L4D_TE_Create_Particle(float fParticleStartPos[3]={0.0, 0.0, 0.0}, 
								float fParticleEndPos[3]={0.0, 0.0, 0.0}, 
								int iParticleIndex=-1, 
								int iEntIndex=0,
								float fDelay=0.0,
								bool SendToAll=true,
								char sParticleName[64]="",
								int iAttachmentIndex=0,
								float fParticleAngles[3]={0.0, 0.0, 0.0}, 
								int iFlags=0,
								int iDamageType=0,
								float fMagnitude=0.0,
								float fScale=1.0,
								float fRadius=0.0)
{
	TE_Start("EffectDispatch");
	
	static EngineVersion IsEngine;
	if(IsEngine == Engine_Unknown)
		IsEngine = GetEngineVersion();
	
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vOrigin.x"	:"m_vOrigin[0]", fParticleStartPos[0]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vOrigin.y"	:"m_vOrigin[1]", fParticleStartPos[1]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vOrigin.z"	:"m_vOrigin[2]", fParticleStartPos[2]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vStart.x"	:"m_vStart[0]", fParticleEndPos[0]);//end point usually for bulletparticles or ropes
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vStart.y"	:"m_vStart[1]", fParticleEndPos[1]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vStart.z"	:"m_vStart[2]", fParticleEndPos[2]);
	
	static int iEffectIndex = INVALID_STRING_INDEX;
	if(iEffectIndex < 0)
	{
		iEffectIndex = __FindStringIndex2(FindStringTable("EffectDispatch"), "ParticleEffect");
		if(iEffectIndex == INVALID_STRING_INDEX)
			SetFailState("Unable to find EffectDispatch/ParticleEffect indexes");
		
	}
	
	TE_WriteNum("m_iEffectName", iEffectIndex);
	
	if(iParticleIndex < 0)
	{
		static int iParticleStringIndex = INVALID_STRING_INDEX;
		iParticleStringIndex = __FindStringIndex2(FindStringTable("ParticleEffectNames"), sParticleName);
		if(iParticleStringIndex == INVALID_STRING_INDEX)
			return false;
		
		TE_WriteNum("m_nHitBox", iParticleStringIndex);
	}
	else
		TE_WriteNum("m_nHitBox", iParticleIndex);
	
	TE_WriteNum("entindex", iEntIndex);
	TE_WriteNum("m_nAttachmentIndex", iAttachmentIndex);
	
	TE_WriteVector("m_vAngles", fParticleAngles);
	
	TE_WriteNum("m_fFlags", iFlags);
	TE_WriteFloat("m_flMagnitude", fMagnitude);// saw this being used in pipebomb needs testing what it does probs shaking screen?
	TE_WriteFloat("m_flScale", fScale);
	TE_WriteFloat("m_flRadius", fRadius);// saw this being used in pipebomb needs testing what it does probs shaking screen?
	TE_WriteNum("m_nDamageType", iDamageType);// this shit is required dunno why for attachpoint emitting valve probs named it wrong
	
	if(SendToAll)
		TE_SendToAll(fDelay);
	
	return true;
}

/**
 * Stops a tempent particle.
 *
 * @param fParticleStartPos	Starting position of the particle.
 * @param fParticleEndPos	Ending position of the particle.
 * @param iParticleIndex	Particle index location in the "ParticleEffectNames" stringtable.
 * @param iEntIndex		Entity index to attach particle to.
 * @param fDelay		Delay for the TE_SendToAll function.
 * @param SendToAll		True to send to all clients, false otherwise. You must call the send function yourself if sending to specific clients.
 * @param sParticleName		Name of the particle to find the index with. Only used if the particle index is invalid.
 * @param iAttachmentIndex	Attachment index of the particle. Decompile the model to retrieve this value.
 * @param fParticleAngles	Angles of the particle. Usually effects particles that have no gravity.
 * @param iFlags		Flags of the particle.
 * @param iDamageType		The damage type of the particle. (Used in impact effect dispatches and attachment points need to be set to use.)
 * @param fMagnitude		The magnitude of the particle. (Needs testing; used in pipe bomb blast.)
 * @param fScale		The scale of the particle (doesn't apply to most particles). (Needs testing.)
 * @param fRadius		The radius of the particle.
 *
 * @return			True on success, false on failure.
 * @error			Invalid effect index or invalid particle stringtable index.
 **/
#pragma deprecated Used only for backwards compatibility.
stock bool L4D_TE_Stop_Particle(float fParticleStartPos[3]={0.0, 0.0, 0.0},
								float fParticleEndPos[3]={0.0, 0.0, 0.0},
								int iParticleIndex=-1,
								int iEntIndex=0,
								float fDelay=0.0,
								bool SendToAll=true,
								char sParticleName[64]="",
								int iAttachmentIndex=0,
								float fParticleAngles[3]={0.0, 0.0, 0.0},
								int iFlags=0,
								int iDamageType=0,
								float fMagnitude=0.0,
								float fScale=1.0,
								float fRadius=0.0)
{
	TE_Start("EffectDispatch");
	
	static EngineVersion IsEngine;
	if(IsEngine == Engine_Unknown)
		IsEngine = GetEngineVersion();
	
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vOrigin.x"	:"m_vStart[0]", fParticleStartPos[0]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vOrigin.y"	:"m_vStart[1]", fParticleStartPos[1]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vOrigin.z"	:"m_vStart[2]", fParticleStartPos[2]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vStart.x"	:"m_vOrigin[0]", fParticleEndPos[0]);//end point usually for bulletparticles or ropes
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vStart.y"	:"m_vOrigin[1]", fParticleEndPos[1]);
	TE_WriteFloat(IsEngine == Engine_Left4Dead2 ? "m_vStart.z"	:"m_vOrigin[2]", fParticleEndPos[2]);

	static int iEffectIndex = INVALID_STRING_INDEX;
	if(iEffectIndex < 0)
	{
		iEffectIndex = __FindStringIndex2(FindStringTable("EffectDispatch"), "ParticleEffectStop");
		if(iEffectIndex == INVALID_STRING_INDEX)
			SetFailState("Unable to find EffectDispatch/ParticleEffectStop indexes");

	}

	TE_WriteNum("m_iEffectName", iEffectIndex);

	if(iParticleIndex < 0)
	{
		static int iParticleStringIndex = INVALID_STRING_INDEX;
		iParticleStringIndex = __FindStringIndex2(FindStringTable("ParticleEffectNames"), sParticleName);
		if(iParticleStringIndex == INVALID_STRING_INDEX)
			return false;

		TE_WriteNum("m_nHitBox", iParticleStringIndex);
	}
	else
		TE_WriteNum("m_nHitBox", iParticleIndex);

	TE_WriteNum("entindex", iEntIndex);
	TE_WriteNum("m_nAttachmentIndex", iAttachmentIndex);

	TE_WriteVector("m_vAngles", fParticleAngles);

	TE_WriteNum("m_fFlags", iFlags);
	TE_WriteFloat("m_flMagnitude", fMagnitude);// saw this being used in pipebomb needs testing what it does probs shaking screen?
	TE_WriteFloat("m_flScale", fScale);
	TE_WriteFloat("m_flRadius", fRadius);// saw this being used in pipebomb needs testing what it does probs shaking screen?
	TE_WriteNum("m_nDamageType", iDamageType);// this shit is required dunno why for attachpoint emitting valve probs named it wrong

	if(SendToAll)
		TE_SendToAll(fDelay);

	return true;
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////