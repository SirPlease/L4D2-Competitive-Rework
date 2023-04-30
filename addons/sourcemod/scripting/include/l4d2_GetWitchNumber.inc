#if defined _EvilWitchNumber
 #endinput
#endif
#define _EvilWitchNumber

/**
 * @根据女巫ID返回编号.
 *
 * @param iWitchid			传入女巫实体ID.
 *
 * @return					返回女巫的自定义编号,没有则返回-1.
 */
native int GetWitchNumber(int iWitchid);