#if defined  _skilldetect_included_
        #endinput
#endif
#define _skilldetect_included_


/**
 *  Called whenever a true skeet with shotgun is done.
 *
 *  @param  int     survivor    the survivor client that performed the feat
 *  @param  int     hunter      the infected client that underwent it
 */
forward OnSkeet( survivor, hunter );

/**
 *  Called whenever a true melee-skeet is done.
 *
 *  @param  int     survivor    the survivor client that performed the feat
 *  @param  int     hunter      the infected client that underwent it
 */
forward OnSkeetMelee( survivor, hunter );

/**
 *  Called whenever a direct grenade launcher hit on a hunter connects.
 *
 *  @param  int     survivor    the survivor client that performed the feat
 *  @param  int     hunter      the infected client that underwent it
 */
forward OnSkeetGL( survivor, hunter );
  
/**
 *  Called whenever a true skeeting sniper headshot landed.
 *
 *  @param  int     survivor    the survivor client that performed the feat
 *  @param  int     hunter      the infected client that underwent it
 */
forward OnSkeetSniper( survivor, hunter );

/**
 *  Called whenever a pouncing hunter got killed with shotgun
 *  when it wasn't a true skeet (chipped hunter).
 *
 *  @param  int     survivor    the survivor client that performed the feat
 *  @param  int     hunter      the infected client that underwent it
 *  @param  int     damage      damage done in the killing hit
 *  @param  bool    isOverKill  true if it would've been a skeet if the hunter hadn't been chipped
 */
forward OnSkeetHurt( survivor, hunter, damage, bool:isOverkill );

/**
 *  Called whenever a pouncing hunter got killed with melee
 *  when it wasn't a true skeet (chipped hunter).
 *
 *  @param  int     survivor    the survivor client that performed the feat
 *  @param  int     hunter      the infected client that underwent it
 *  @param  int     damage      damage done in the killing hit
 *  @param  bool    isOverKill  true if it would've been a skeet if the hunter hadn't been chipped
 */  
forward OnSkeetMeleeHurt( survivor, hunter, damage, bool:isOverkill );

/**
 *  Called whenever a pouncing hunter got killed with a sniper headshot
 *  when it wasn't a true skeet (chipped hunter).
 *
 *  @param  int     survivor    the survivor client that performed the feat
 *  @param  int     hunter      the infected client that underwent it
 *  @param  int     damage      damage done in the killing hit
 *  @param  bool    isOverKill  true if it would've been a skeet if the hunter hadn't been chipped
 */  
forward OnSkeetSniperHurt( survivor, hunter, damage, bool:isOverkill );

/**
 *  Called whenever a hunter is deadstopped (pouncing => m2'd).
 *
 *  @param  int     survivor    the survivor client that performed the feat
 *  @param  int     hunter      the infected client that underwent it
 */  
forward OnHunterDeadstop( survivor, hunter );

/**
 *  Called whenever a boomer is killed that didn't land on anyone,
 *  and didn't explode on anyone either.
 *
 *  @param  int     survivor    the survivor client that killed the boomer
 *  @param  int     boomer      the infected client that got popped
 *  @param  int     shoveCount  the amount of times the boomer got shoved, if any
 *  @param  Float   timeAlive   the time, in seconds, that the boomer lived
 */  
forward OnBoomerPop( survivor, boomer, shoveCount, Float:timeAlive );
  
/**
 *  Called whenever a charger is fully melee-leveled (no chip).
 *  This is also called when the melee hit would've leveled if not chipped!
 *
 *  @param  int     survivor    the survivor client that performed the feat
 *  @param  int     charger     the infected client that underwent it
 */
forward OnChargerLevel( survivor, charger );

/**
 *  Called whenever a charger is melee-leveled after being chipped.
 *  Only called when the melee wouldn't have killed an unchipped charger.
 *
 *  @param  int     survivor    the survivor client that performed the feat
 *  @param  int     charger     the infected client that underwent it
 *  @param  int     damage      damage done in the killing hit
 */
forward OnChargerLevelHurt( survivor, charger, damage );

/**
 *  Called whenever a witch was crowned without her being angered first.
 *
 *  @param  int     survivor    the survivor client that performed the feat
 *  @param  int     damage      damage done in the killing hit
 */
forward OnWitchCrown( survivor, damage );

/**
 *  Called whenever a witch gets crowned after she got angered/triggered.
 *  This is referred to (depending on the community) as a 'draw crown' or 'remote'.
 *
 *  @param  int     survivor    the survivor client that performed the feat
 *  @param  int     damage      damage done in the killing hit
 *  @param  int     chipdamage  damage done to the witch before she got crowned
 */
forward OnWitchCrownHurt( survivor, damage, chipdamage );

/**
 *  Called whenever a survivor melee-cuts a smoker tongue that was aimed for them.
 *
 *  @param  int     survivor    the survivor client that performed the feat
 *  @param  int     smoker      the infected client that underwent it
 */
forward OnTongueCut( survivor, smoker );

/**
 *  Called whenever a survivor frees himself from a smoker that grabbed them,
 *  either by killing it or by shoving.
 *
 *  @param  int     survivor    the survivor client that performed the feat
 *  @param  int     smoker      the infected client that underwent it
 *  @param  bool    withShove   true if the self-clear was by a shove/m2
 */
forward OnSmokerSelfClear( survivor, smoker, bool:withShove );
  
/**
 *  Called whenever a survivor shoots/melees a tank rock out of the air.
 *
 *  Note: the tank param might be unreliable due to the nature of the
 *  tracking. Don't do anything srs bsns with it.
 *
 *  @param  int     survivor    the survivor client that performed the feat
 *  @param  int     tank        the infected client that underwent it
 */
forward OnTankRockSkeeted( survivor, tank );

/**
 *  Called whenever a tank lands a rock on a survivor.
 *
 *  Note: the tank param might be unreliable due to the nature of the
 *  tracking. Don't do anything srs bsns with it.
 *
 *  @param  int     tank        the infected client that performed the feat
 *  @param  int     survivor    the survivor client that underwent it
 */
forward OnTankRockEaten( tank, survivor );

/**
 *  Called whenever a hunter lands a high-pounce on a survivor.
 *
 *  @param  int     hunter              the infected client that performed the feat
 *  @param  int     survivor            the survivor client that underwent it
 *  @param  int     actualDamage        the actual damage the pounce did to the survivor
 *  @param  Float   calculatedDamage    how much damage (going by pounceannounce parameters) the pounce would be expected to do
 *  @param  Float   height              the vertical distance between the pounce origin and its landing
 *  @param  bool    reportedHigh        whether skill_detect considers it a high pounce for reporting purposes
 */
forward OnHunterHighPounce( hunter, survivor, actualDamage, Float:calculatedDamage, Float:height, bool:reportedHigh );

/**
 *  Called whenever a jockey lands a high-pounce on a survivor.
 * 
 *  Note: due to the nature of the tracking, it only gets the height right if a jockey actually
 *  jumped or pounced from his perch. If they simple walk off and land, it may be incorrect.
 *
 *  @param  int     jockey          the infected client that performed the feat
 *  @param  int     survivor        the survivor client that underwent it
 *  @param  Float   height          the vertical distance between the pounce origin and its landing
 *  @param  bool    reportedHigh    whether skill_detect considers it a high pounce for reporting purposes
 */
forward OnJockeyHighPounce( jockey, victim, Float:height, bool:reportedHigh );

/**
 *  Called whenever a charger lands a death-charge on a survivor.
 *  This is called for killing the grabbed survivor, but also the ones that get impact-bumped
 *  and fall to their deaths.
 * 
 *  Note: due to the nature of the tracking, there may be places that are technically death-
 *  charge spots, but not detected by the plugin. Example: the sidewalk next to the fence near
 *  the lower roof on Dead Air 1; the Death Toll 4 out-of-map deathcharge near the start
 *  saferoom.
 *
 *  @param  int     charger     the infected client that performed the feat
 *  @param  int     survivor    the survivor client that underwent it
 *  @param  Float   height      the vertical distance between the grab and the survivor's death spot
 *  @param  Float   distance    the full vector distance between the grab and the survivor's death spot
 *  @param  bool    wasCarried  true if the survivor was the one that the charger grabbed
 */
forward OnDeathCharge( charger, survivor, Float:height, Float:distance, bool:wasCarried );
  
/**
 *  Called whenever a survivor clears a teammate from a special infected pin.
 * 
 *  Note: timeB is only appliccable for smokers and chargers. For smokers it shows the
 *  time from the tongue connecting to the clear. For chargers from the charge-grab to
 *  the clear. For jockeys and hunters, timeB will always be -1.0.
 *
 *  timeA is the time, for charger, from start of pummeling till clear (-1.0 if they 
 *  never started pummeling). For smokers, this is the time from the survivor being
 *  fully reigned in to the smoker (-1.0 if the tongue was broken before that).
 *
 *  @param  int     clearer     the survivor client that performed the clear
 *  @param  int     pinner      the pinning infected client that got cleared (shoved off or killed)
 *  @param  int     pinvictim   the pinned survivor that was saved
 *  @param  int     zombieClass the class (ZC_SMOKER - ZC_CHARGER) of the pinner
 *  @param  Float   timeA       time from pin till clear in seconds, -1 if never
 *  @param  Float   timeB       for charger/smoker: time from grab/tongue connect to clear
 *  @param  bool    withShove   true if the clear was done by shove/m2
 */
forward OnSpecialClear( clearer, pinner, pinvictim, zombieClass, Float:timeA, Float:timeB, bool:withShove );

/**
 *  Called whenever a boomer is done vomiting, and landed his vomit on one
 *  or more survivors.
 *
 *  Note: this does not include or fire for boomers exploding, only vomits.
 *
 *  @param  int     boomer      the infected client that performed the feat
 *  @param  int     amount      the amount of survivors vomited on
 */
forward OnBoomerVomitLanded( boomer, amount );

/**
 *  Called whenever a survivor shoves a special infected (any kind).
 *
 *  @param  int     survivor      the survivor client that performed the feat
 *  @param  int     infected      the infected client that underwent it
 *  @param  int     zombieClass   the class type of the infected shoved
 */
forward OnSpecialShoved( survivor, infected, zombieClass );

/**
 *  Called whenever a survivor lands any number of bunnyhops in a row. Called
 *  afterwards.
 *
 *  @param  int     survivor      the survivor client that performed the feat
 *  @param  int     streak        the amount of hops in a row
 *  @param  Float   maxVelocity   the highest speed during any jump or jump apex
 */
forward OnBunnyHopStreak( survivor, streak, Float:maxVelocity );

/**
 *  Called whenever a car alarm is triggered (by a survivor).
 *
 *  @param  int     survivor      the survivor client that triggered the alarm (-1 or 0 if unknown)
 *  @param  int     infected      if > 0: the infected client that assisted in triggering it (boomer, smoker, jockey or charger)
 *  @param  int     reason        the reason for triggering (see CarAlarmTriggerType)
 */
forward OnCarAlarmTriggered( survivor, infected, CarAlarmTriggerReason:reason );



/**
 *  CarAlarmTriggerReason: the 'reason' parameter in OnCarAlarmTriggered() forward
 */
enum CarAlarmTriggerReason
{
    CarAlarmTrigger_Unknown,
    CarAlarmTrigger_Hit,
    CarAlarmTrigger_Touched,
    CarAlarmTrigger_Explosion,
    CarAlarmTrigger_Boomer
};



public SharedPlugin:__pl_skilldetect =
{
	name = "skill_detect",
	file = "l4d2_skill_detect.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};