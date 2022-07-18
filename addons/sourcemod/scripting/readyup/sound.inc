#if defined _readyup_sound_included
 #endinput
#endif
#define _readyup_sound_included

#define SECRET_SOUND "level/gnomeftw.wav"
#define DEFAULT_NOTIFY_SOUND "buttons/button14.wav"
#define DEFAULT_COUNTDOWN_SOUND "weapons/hegrenade/beep.wav"
#define DEFAULT_LIVE_SOUND "ui/survival_medal.wav"
#define DEFAULT_AUTOSTART_SOUND "ui/buttonrollover.wav"

#define MAX_CHUCKLE_SOUNDS 5
static const char s_chuckleSound[MAX_CHUCKLE_SOUNDS][] =
{
	"/npc/moustachio/strengthattract01.wav",
	"/npc/moustachio/strengthattract02.wav",
	"/npc/moustachio/strengthattract05.wav",
	"/npc/moustachio/strengthattract06.wav",
	"/npc/moustachio/strengthattract09.wav"
};

static char
	s_notifySound[PLATFORM_MAX_PATH],
	s_countdownSound[PLATFORM_MAX_PATH],
	s_liveSound[PLATFORM_MAX_PATH],
	s_autoStartSound[PLATFORM_MAX_PATH];

void PrecacheSounds()
{
	char szPath[PLATFORM_MAX_PATH];
	
	l4d_ready_notify_sound.GetString(s_notifySound, sizeof(s_notifySound));
	l4d_ready_countdown_sound.GetString(s_countdownSound, sizeof(s_countdownSound));
	l4d_ready_live_sound.GetString(s_liveSound, sizeof(s_liveSound));
	l4d_ready_autostart_sound.GetString(s_autoStartSound, sizeof(s_autoStartSound));
	
	FormatEx(szPath, sizeof(szPath), "sound/%s", s_notifySound);
	if (!FileExists(szPath, true)) {
		strcopy(s_notifySound, sizeof(s_notifySound), DEFAULT_NOTIFY_SOUND);
	}
	
	FormatEx(szPath, sizeof(szPath), "sound/%s", s_countdownSound);
	if (!FileExists(szPath, true)) {
		strcopy(s_countdownSound, sizeof(s_countdownSound), DEFAULT_COUNTDOWN_SOUND);
	}
	
	FormatEx(szPath, sizeof(szPath), "sound/%s", s_liveSound);
	if (!FileExists(szPath, true)) {
		strcopy(s_liveSound, sizeof(s_liveSound), DEFAULT_LIVE_SOUND);
	}
	
	FormatEx(szPath, sizeof(szPath), "sound/%s", s_autoStartSound);
	if (!FileExists(szPath, true)) {
		strcopy(s_autoStartSound, sizeof(s_autoStartSound), DEFAULT_AUTOSTART_SOUND);
	}
	
	PrecacheSound(SECRET_SOUND);
	PrecacheSound(s_notifySound);
	PrecacheSound(s_countdownSound);
	PrecacheSound(s_liveSound);
	PrecacheSound(s_autoStartSound);
	for (int i = 0; i < MAX_CHUCKLE_SOUNDS; i++)
	{
		PrecacheSound(s_chuckleSound[i]);
	}
}

void PlayLiveSound()
{
	if (l4d_ready_enable_sound.BoolValue)
	{
		if (l4d_ready_chuckle.BoolValue)
		{
			EmitSoundToAll(s_chuckleSound[GetRandomInt(0,MAX_CHUCKLE_SOUNDS-1)], .volume = 0.5);
		}
		else { EmitSoundToAll(s_liveSound, .volume = 0.5); }
	}
}

void PlayCountdownSound()
{
	if (l4d_ready_enable_sound.BoolValue)
	{
		EmitSoundToAll(s_countdownSound, .volume = 0.5);
	}
}

void PlayAutoStartSound()
{
	if (l4d_ready_enable_sound.BoolValue)
	{
		EmitSoundToAll(s_autoStartSound, .volume = 0.7);
	}
}

void PlayNotifySound()
{
	if (l4d_ready_enable_sound.BoolValue)
	{
		EmitSoundToAll(s_notifySound);
	}
}

// ========================
// :D
// ========================

// :D
static Handle
	blockSecretSpam[MAXPLAYERS+1];

void DoSecrets(int client)
{
	if (GetClientTeam(client) == L4D2Team_Survivor && !blockSecretSpam[client])
	{
		int particle = CreateEntityByName("info_particle_system");
		if (particle == -1) return;
		
		float pos[3];
		GetClientAbsOrigin(client, pos);
		
		pos[2] += 80;
		
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		
		DispatchKeyValue(particle, "effect_name", "achieved");
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		
		CreateTimer(5.0, killParticle, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
		
		EmitSoundToAll(SECRET_SOUND, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5);
		CreateTimer(2.5, killSound);
		
		blockSecretSpam[client] = CreateTimer(5.0, SecretSpamDelay, client);
	}
	PrintCenterTextAll("\x42\x4f\x4e\x45\x53\x41\x57\x20\x49\x53\x20\x52\x45\x41\x44\x59\x21");
}

static Action SecretSpamDelay(Handle timer, int client)
{
	blockSecretSpam[client] = null;
	return Plugin_Stop;
}

static Action killParticle(Handle timer, int entRef)
{
	int entity = EntRefToEntIndex(entRef);
	if (entity > 0 && IsValidEdict(entity))
	{
		RemoveEntity(entity);
	}
	return Plugin_Stop;
}

static Action killSound(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && !IsFakeClient(i))
			StopSound(i, SNDCHAN_AUTO, SECRET_SOUND);
	
	return Plugin_Stop;
}
