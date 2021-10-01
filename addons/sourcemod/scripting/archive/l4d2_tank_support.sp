//This plugin has been replaced by 'l4d2_tank_props_glow'

#include <sourcemod>
#include <left4dhooks>
#include <sdktools>
#include <sdkhooks>
#include <colors>
#include <l4d2lib>

new OUR_COLOR[3];
new bool:bVision[MAXPLAYERS + 1];
new bool:bTankAlive;

new Handle:g_ArrayHittableClones;
new Handle:g_ArrayHittables;

enum L4D2GlowType 
{ 
	L4D2Glow_None = 0, 
	L4D2Glow_OnUse, 
	L4D2Glow_OnLookAt, 
	L4D2Glow_Constant 
} 

public OnPluginStart()
{
	OUR_COLOR[0] = 255;
	OUR_COLOR[1] = 255;
	OUR_COLOR[2] = 255;
	// Setup Clone Array
	g_ArrayHittableClones = CreateArray(32);
	g_ArrayHittables = CreateArray(32);

	// Hook First Tank
	HookEvent("tank_spawn", TankSpawnEvent);

	// Clear Vision, just in case.
	HookEvent("player_team", ClearVisionEvent);

	// Clean Arrays.
	HookEvent("tank_killed", ClearArrayEvent);
	HookEvent("round_start", ClearArrayEvent);
	HookEvent("round_end", ClearArrayEvent);
}

public OnPluginEnd() KillClones(true);

public ClearArrayEvent(Handle:event, const String:name[], bool:dontBroadcast) KillClones(true);

public ClearVisionEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client && IsClientInGame(client) && bVision[client])
	{
		bVision[client] = false;
	}
}

public L4D2_OnTankPassControl(oldTank, newTank, passCount)
{
	KillClones(false);
	bVision[newTank] = true;
	if (bTankAlive) RecreateHittableClones();
}

public TankSpawnEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new tank = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsFakeClient(tank)) 
	{
		KillClones(true);
		return;
	}

	if (!bTankAlive) 
	{
		HookProps();
		bTankAlive = true;
	}
}

public CreateClone(any:entity)
{
	decl Float:vOrigin[3];
	decl Float:vAngles[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vOrigin);
	GetEntPropVector(entity, Prop_Data, "m_angRotation", vAngles); 
	decl String:entityModel[PLATFORM_MAX_PATH];
	GetEntPropString(entity, Prop_Data, "m_ModelName", entityModel, sizeof(entityModel)); 
	new clone=0;
	clone = CreateEntityByName("prop_dynamic_override"); //prop_dynamic
	SetEntityModel(clone, entityModel);
	DispatchSpawn(clone);

	TeleportEntity(clone, vOrigin, vAngles, NULL_VECTOR); 
	SetEntProp(clone, Prop_Send, "m_CollisionGroup", 0);
	SetEntProp(clone, Prop_Send, "m_nSolidType", 0);
	
	SetVariantString("!activator");
	AcceptEntityInput(clone, "SetParent", entity);

	return clone;
}

public TankHittablePunched(const String:output[], caller, activator, Float:delay)
{
	new iEntity = caller;
	new clone = CreateClone(iEntity);
	if (clone > 0)
	{
		PushArrayCell(g_ArrayHittableClones, clone);
		PushArrayCell(g_ArrayHittables, iEntity);
		MakeEntityVisible(clone, false);
		SDKHook(clone, SDKHook_SetTransmit, CloneTransmit);
		L4D2_SetEntGlow(clone, L4D2Glow_Constant, 3250, 250, OUR_COLOR, false);
	}
}

public RecreateHittableClones()
{
	new ArraySize = GetArraySize(g_ArrayHittables);
	if (ArraySize > 0)
	{
		for (new i = 0; i < ArraySize; i++)
		{
			new storedEntity = GetArrayCell(g_ArrayHittables, i);
			if (IsValidEntity(storedEntity))
			{
				new clone = CreateClone(storedEntity);
				if (clone > 0)
				{
					PushArrayCell(g_ArrayHittableClones, clone);
					MakeEntityVisible(clone, false);
					SDKHook(clone, SDKHook_SetTransmit, CloneTransmit);
					L4D2_SetEntGlow(clone, L4D2Glow_Constant, 3250, 250, OUR_COLOR, false);
				}
			}
		}
	}
}

public Action:CloneTransmit(entity, client)
{
	if (bVision[client])
	{
		// Showing Clone
		return Plugin_Continue;
	}
	return Plugin_Handled;
}

stock KillClones(bool:both)
{
	// 1. Loop through Array.
	// 2. Unhook Clones safely and then Kill them.
	// 3. Empty Array.
	new ArraySize = GetArraySize(g_ArrayHittableClones);
	for (new i = 0; i < ArraySize; i++)
	{
		new storedEntity = GetArrayCell(g_ArrayHittableClones, i);
		if (IsValidEntity(storedEntity))
		{
			SDKUnhook(storedEntity, SDKHook_SetTransmit, CloneTransmit);
			AcceptEntityInput(storedEntity, "Kill");
		}
	}
	ClearArray(g_ArrayHittableClones);
	if (both) { ClearArray(g_ArrayHittables); bTankAlive = false ; }

	// 4. Reset bVision
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && bVision[i])
		{
			bVision[i] = false;
		}
	}
}

stock MakeEntityVisible(ent, bool:visible=true)
{
	if(visible)
	{
		SetEntityRenderMode(ent, RENDER_NORMAL);
		SetEntityRenderColor(ent, 255, 255, 255, 255);         
	}
	else
	{
		SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
		SetEntityRenderColor(ent, 0, 0, 0, 0);
	} 
}

stock HookProps()
{
	new iEntity = -1;
	 
	while ((iEntity = FindEntityByClassname(iEntity, "prop_physics")) != -1) 
	{
		if (IsTankHittable(iEntity)) 
		{
			HookSingleEntityOutput(iEntity, "OnHitByTank", TankHittablePunched, true);
		}
	}
	 
	iEntity = -1;
	 
	while ((iEntity = FindEntityByClassname(iEntity, "prop_car_alarm")) != -1) 
	{
		HookSingleEntityOutput(iEntity, "OnHitByTank", TankHittablePunched, true);
	}
}

/**
 * Is the tank able to punch the entity with the tank? 
 *
 * @param iEntity entity ID
 * @return bool
 */
stock bool:IsTankHittable(iEntity) {
	if (!IsValidEntity(iEntity)) {
		return false;
	}
	
	decl String:className[64];
	
	GetEdictClassname(iEntity, className, sizeof(className));
	if ( StrEqual(className, "prop_physics") ) {
		if ( GetEntProp(iEntity, Prop_Send, "m_hasTankGlow", 1) ) {
			return true;
		}
	}
	else if ( StrEqual(className, "prop_car_alarm") ) {
		return true;
	}
	
	return false;
}

/**
 * Set entity glow type.
 *
 * @param entity        Entity index.
 * @parma type            Glow type.
 * @noreturn
 * @error                Invalid entity index or entity does not support glow.
 */
stock L4D2_SetEntGlow_Type(entity, L4D2GlowType:type)
{
	SetEntProp(entity, Prop_Send, "m_iGlowType", _:type);
}

/**
 * Set entity glow range.
 *
 * @param entity        Entity index.
 * @parma range            Glow range.
 * @noreturn
 * @error                Invalid entity index or entity does not support glow.
 */
stock L4D2_SetEntGlow_Range(entity, range)
{
	SetEntProp(entity, Prop_Send, "m_nGlowRange", range);
}

/**
 * Set entity glow min range.
 *
 * @param entity        Entity index.
 * @parma minRange        Glow min range.
 * @noreturn
 * @error                Invalid entity index or entity does not support glow.
 */
stock L4D2_SetEntGlow_MinRange(entity, minRange)
{
	SetEntProp(entity, Prop_Send, "m_nGlowRangeMin", minRange);
}

/**
 * Set entity glow color.
 *
 * @param entity        Entity index.
 * @parma colorOverride    Glow color, RGB.
 * @noreturn
 * @error                Invalid entity index or entity does not support glow.
 */
stock L4D2_SetEntGlow_ColorOverride(entity, colorOverride[3])
{
	SetEntProp(entity, Prop_Send, "m_glowColorOverride", colorOverride[0] + (colorOverride[1] * 256) + (colorOverride[2] * 65536));
}

/**
 * Set entity glow flashing state.
 *
 * @param entity        Entity index.
 * @parma flashing        Whether glow will be flashing.
 * @noreturn
 * @error                Invalid entity index or entity does not support glow.
 */
stock L4D2_SetEntGlow_Flashing(entity, bool:flashing)
{
	SetEntProp(entity, Prop_Send, "m_bFlashing", _:flashing);
}

/**
 * Set entity glow. This is consider safer and more robust over setting each glow
 * property on their own because glow offset will be check first.
 *
 * @param entity        Entity index.
 * @parma type            Glow type.
 * @param range            Glow max range, 0 for unlimited.
 * @param minRange        Glow min range.
 * @param colorOverride Glow color, RGB.
 * @param flashing        Whether the glow will be flashing.
 * @return                True if glow was set, false if entity does not support
 *                        glow.
 */
stock bool:L4D2_SetEntGlow(entity, L4D2GlowType:type, range, minRange, colorOverride[3], bool:flashing)
{
	decl String:netclass[128];
	GetEntityNetClass(entity, netclass, 128);

	new offset = FindSendPropInfo(netclass, "m_iGlowType");
	if (offset < 1)
	{
		return false;    
	}

	L4D2_SetEntGlow_Type(entity, type);
	L4D2_SetEntGlow_Range(entity, range);
	L4D2_SetEntGlow_MinRange(entity, minRange);
	L4D2_SetEntGlow_ColorOverride(entity, colorOverride);
	L4D2_SetEntGlow_Flashing(entity, flashing);
	return true;
}

stock bool:L4D2_SetEntGlowOverride(entity, colorOverride[3])
{
	decl String:netclass[128];
	GetEntityNetClass(entity, netclass, 128);

	new offset = FindSendPropInfo(netclass, "m_iGlowType");
	if (offset < 1)
	{
		return false;    
	}

	L4D2_SetEntGlow_ColorOverride(entity, colorOverride);
	return true;
}