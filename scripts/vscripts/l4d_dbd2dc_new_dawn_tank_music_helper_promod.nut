// Used to convert Dead Before Dawn: DC's finale to a gauntlet.
// Refer to the corresponding stripper file.

if (!Director.IsTankInPlay())
{
	// There is assumed to be a generic_ambient entity named 'tank_music'
	// that was started when this script was initially kicked off.
	// Kill the music now.
	EntFire( "tank_music", "StopSound", 0 );
	
	// Kill the timer that keeps firing this script.
	EntFire( "tank_music_timer", "Disable", 0 );

}