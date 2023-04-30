#if defined _l4d2_ems_hud_included
 #endinput
#endif
#define _l4d2_ems_hud_included

// ====================================================================================================
// "L4D2 EMS HUD Functions" by "sorallll"
//	Version: 1.0.5
// ====================================================================================================

#include <sdktools>

#define HUD_LEFT_TOP	0
#define HUD_LEFT_BOT	1
#define HUD_MID_TOP		2
#define HUD_MID_BOT		3
#define HUD_RIGHT_TOP	4
#define HUD_RIGHT_BOT	5
#define HUD_TICKER		6
#define HUD_FAR_LEFT	7
#define HUD_FAR_RIGHT	8
#define HUD_MID_BOX		9
#define HUD_SCORE_TITLE	10
#define HUD_SCORE_1		11
#define HUD_SCORE_2		12
#define HUD_SCORE_3		13
#define HUD_SCORE_4		14

#define MAX_SIZE_HUD	15

// custom flags for background, time, alignment, which team, pre or postfix, etc
#define HUD_FLAG_PRESTR			(1<<0)	//	do you want a string/value pair to start(pre) or end(post) with the static string (default is PRE)
#define HUD_FLAG_POSTSTR		(1<<1)	//	ditto
#define HUD_FLAG_BEEP			(1<<2)	//	Makes a countdown timer blink
#define HUD_FLAG_BLINK			(1<<3)  //	do you want this field to be blinking
#define HUD_FLAG_AS_TIME		(1<<4)	//	to do..
#define HUD_FLAG_COUNTDOWN_WARN	(1<<5)	//	auto blink when the timer gets under 10 seconds
#define HUD_FLAG_NOBG			(1<<6) 	//	dont draw the background box for this UI element
#define HUD_FLAG_ALLOWNEGTIMER	(1<<7) 	//	by default Timers stop on 0:00 to avoid briefly going negative over network, this keeps that from happening
#define HUD_FLAG_ALIGN_LEFT		(1<<8) 	//	Left justify this text
#define HUD_FLAG_ALIGN_CENTER	(1<<9)	//	Center justify this text
#define HUD_FLAG_ALIGN_RIGHT	(3<<8)	//	Right justify this text
#define HUD_FLAG_TEAM_SURVIVORS	(1<<10) //	only show to the survivor team
#define HUD_FLAG_TEAM_INFECTED	(1<<11) //	only show to the special infected team
#define HUD_FLAG_TEAM_MASK		(3<<10) //	link HUD_FLAG_TEAM_SURVIVORS and HUD_FLAG_TEAM_INFECTED
#define HUD_FLAG_UNKNOWN1		(1<<12)	//	?
#define HUD_FLAG_TEXT			(1<<13)	//	?
#define HUD_FLAG_NOTVISIBLE		(1<<14) //	if you want to keep the slot data but keep it from displaying

/**
 * 启用HUD绘制.
 * 在OnMapStart()函数内部启用即可.	
 */
stock void EnableHUD() {
	GameRules_SetProp("m_bChallengeModeActive", true, _, _, true);
}

/**
 * Passes a table that defines your in-game HUD to the engine.
 * From there on, you can modify the table to cause changes.
 * Though often you wont, you will instead use a dataval entry to define a simple lambda that
 * returns the up-to-date value to the HUD system.
*/
/**
 * Passes a table that defines your in-game HUD to the engine.
 *
 * @param slot			HUD slot.
 * @param flags			flags(出于某些未知原因需要添加HUD_FLAG_TEXT falg才能正常绘制)..
 * @param dataval		used for data of destination string buffer.
 * @param ...			Variable number of format parameters.
 * @noreturn
 * @error				Invalid HUD slot.
 */
stock void HUDSetLayout(int slot, int flags, const char[] dataval, any ...) {
	static char str[128];
	VFormat(str, sizeof str, dataval, 4);

	GameRules_SetProp("m_iScriptedHUDFlags", flags, _, slot, true);
	GameRules_SetPropString("m_szScriptedHUDStringSet", str, true, slot);
}

/**
 * Note:HUDPlace(slot,x,y,w,h): moves the given HUD slot to the XY position specified, with new W and H.
 * This is for doing occasional highlight/make a point type things,
 * or small changes to layout w/o having to build a new .res to put in a VPK.
 * We suspect if you want to do a super fancy HUD you will want to create your own hudscriptedmode.res file,
 * just making sure to use the same element naming conventions so you can still talk to them from script.
 * x,y,w,h are all 0.0-1.0 screen relative coordinates (actually, a bit smaller than the screen, but anyway).
 * So a box near middle might be set as (0.4,0.45,0.2,0.1) or so.
 */
/**
 * Place a slot in game.
 *
 * @param slot			HUD slot.
 * @param x				screen x position.
 * @param y				screen y position.
 * @param width			screen slot width.
 * @param height		screen slot height.
 * @noreturn
 * @error				Invalid HUD slot.
 */
stock void HUDPlace(int slot, float x, float y, float width, float height) {
	GameRules_SetPropFloat("m_fScriptedHUDPosX", x, slot, true);
	GameRules_SetPropFloat("m_fScriptedHUDPosY", y, slot, true);
	GameRules_SetPropFloat("m_fScriptedHUDWidth", width, slot, true);
	GameRules_SetPropFloat("m_fScriptedHUDHeight", height, slot, true);
}

/**
 * Removes a slot from game.
 *
 * @param slot			HUD slot.
 * @noreturn
 * @error				Invalid HUD slot.
 */
stock void RemoveHUD(int slot) {
	GameRules_SetProp("m_iScriptedHUDInts", 0, _, slot, true);
	GameRules_SetPropFloat("m_fScriptedHUDFloats", 0.0, slot, true);
	GameRules_SetProp("m_iScriptedHUDFlags", HUD_FLAG_NOTVISIBLE, _, slot, true);
	GameRules_SetPropFloat("m_fScriptedHUDPosX", 0.0, slot, true);
	GameRules_SetPropFloat("m_fScriptedHUDPosY", 0.0, slot, true);
	GameRules_SetPropFloat("m_fScriptedHUDWidth", 0.0, slot, true);
	GameRules_SetPropFloat("m_fScriptedHUDHeight", 0.0, slot, true);
	GameRules_SetPropString("m_szScriptedHUDStringSet", "", true, slot);
}

/**
 * Returns if a Slot is Used
 *
 * @param slot			HUD slot.
 * @return				True if a Slot is Used, false otherwise.
 * @error				Invalid HUD slot.
 */
stock bool HUDSlotIsUsed(int slot) {
	static char str[128];
	return !!GameRules_GetPropString("m_szScriptedHUDStringSet", str, sizeof str, slot);
}

/**
 * Remove All slot from game.
 */
stock void RemoveAllHUD() {
	for (int slot; slot < MAX_SIZE_HUD; slot++)
		RemoveHUD(slot);
}