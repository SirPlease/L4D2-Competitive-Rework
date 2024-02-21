#if defined _sourcebanspp_included
public void SBPP_OnBanPlayer(int iAdmin, int iTarget, int iTime, const char[] sReason)
{
      processBanEvent(iTarget, iTime);
}
#endif

void processBanEvent(int client, int time)
{
        char query[512], steamid[64];
        GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
        char logMessage[128];
        Format(logMessage, sizeof(logMessage), "Processing ban event of %N", client);
        WriteLog(logMessage, LogLevel_Bans);
        if(steamIDToFingerprintTable.ContainsKey(steamid))
        {
                char fingerprint[128];
                steamIDToFingerprintTable.GetString(steamid, fingerprint, sizeof(fingerprint));
                Format(query, sizeof(query), "UPDATE rebanner_fingerprints SET banned_duration = %i, banned_timestamp = %i, is_banned = 1 WHERE fingerprint = '%s'", time, GetTime(), fingerprint);
                db.Query(OnBanClient_Query_Finished, query, time);
                bannedFingerprints.SetString(fingerprint, "", false);
        }
}

public Action OnBanClient(int client, int time, int flags, const char[] reason, const char[] kick_message, const char[] command, any source)
{
        processBanEvent(client, time);
        return Plugin_Continue;
}

public void OnBanClient_Query_Finished(Database dtb, DBResultSet results, const char[] error, int duration)
{
        char logMessage[128];
        Format(logMessage, sizeof(logMessage), "Successfully flagged as banned. Duration is %i", duration);
        WriteLog(logMessage, LogLevel_Bans);
}

void RemoveBanRecordIfExists(int client)
{
        if(currentUserId != GetClientUserId(client))
        {
                currentUserId = INVALID_USERID;
                clientQueueState[client] = QueueState_Ignore;
                globalLocked = false;
                return;
        }
        char steamid[64];
        GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
        if(!steamIDToFingerprintTable.ContainsKey(steamid))
                return;

        char fingerpint[128];
        steamIDToFingerprintTable.GetString(steamid, fingerpint, sizeof(fingerpint));
        if(!bannedFingerprints.ContainsKey(fingerpint))
                return;

        bannedFingerprints.Remove(fingerpint);
        char logMessage[128];
        Format(logMessage, sizeof(logMessage), "Removing ban flag of %N", client);
        WriteLog(logMessage, LogLevel_Bans);
        char query[512];
        Format(query, sizeof(query), "UPDATE rebanner_fingerprints SET is_banned = 0, banned_duration = 0, banned_timestamp = 0 WHERE fingerprint = '%s'", fingerpint);
        db.Query(ClientBanRecordRemoved, query);
}

public void ClientBanRecordRemoved(Database dtb, DBResultSet results, const char[] error, any data)
{
        if(error[0])
                SetFailState("Failed to remove ban from database: %s", error); 
}