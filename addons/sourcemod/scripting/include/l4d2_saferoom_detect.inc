/*
  Check if entity is in a saferoom
  returns bool (errors/incorrect data returns false)
*/
native SAFEDETECT_IsEntityInStartSaferoom(entity);
native SAFEDETECT_IsEntityInEndSaferoom(entity);

/*
  Check if player (client) is in a saferoom
  returns bool (errors/incorrect data returns false)
*/
native SAFEDETECT_IsPlayerInStartSaferoom(client);
native SAFEDETECT_IsPlayerInEndSaferoom(client);