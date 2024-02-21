public void OnDatabaseConnected(Database database, const char[] error, any data)
{
        if(database == null || error[0])
                SetFailState("Database failure: %s", error);

        db = database;
        char databaseType[16];
        db.Driver.GetIdentifier(databaseType, sizeof(databaseType));

        if(StrEqual(databaseType, "sqlite", false))
        {
                SQL_TQuery(db, OnDatabaseStructureCreated, "CREATE TABLE IF NOT EXISTS 'rebanner_fingerprints' (fingerprint TEXT PRIMARY KEY, steamid2 TEXT, is_banned INTEGER, banned_duration INTEGER, banned_timestamp INTEGER, ip TEXT)", TableType_Fingerprints);
                SQL_TQuery(db, OnDatabaseStructureCreated, "CREATE TABLE IF NOT EXISTS 'rebanner_steamids' (steamid2 TEXT PRIMARY KEY, fingerprint TEXT)", TableType_SteamIDs);
                SQL_TQuery(db, OnDatabaseStructureCreated, "CREATE TABLE IF NOT EXISTS 'rebanner_ips' (ip TEXT PRIMARY KEY, fingerprint TEXT)", TableType_IPs);
        }
        else
        {
                SQL_TQuery(db, OnDatabaseStructureCreated, "CREATE TABLE IF NOT EXISTS `rebanner_fingerprints` (fingerprint VARCHAR(70), steamid2 VARCHAR(70), is_banned TINYINT(1), banned_duration INT, banned_timestamp INT, ip VARCHAR(70), PRIMARY KEY (fingerprint))", TableType_Fingerprints);
                SQL_TQuery(db, OnDatabaseStructureCreated, "CREATE TABLE IF NOT EXISTS `rebanner_steamids` (steamid2 VARCHAR(70), fingerprint VARCHAR(70), PRIMARY KEY (steamid2))", TableType_SteamIDs);
                SQL_TQuery(db, OnDatabaseStructureCreated, "CREATE TABLE IF NOT EXISTS `rebanner_ips` (ip VARCHAR(70), fingerprint VARCHAR(70), PRIMARY KEY (ip))", TableType_IPs);                
        }
}

public void OnDatabaseStructureCreated(Handle owner, Handle hndl, const char[] error, TableType initType)
{
        if(error[0])
                SetFailState("Database creation failure: %s", error);   

        switch(initType)
        {
                case TableType_Fingerprints:
                {
                        db.Query(ParseDatabaseRecords, "SELECT fingerprint, steamid2, is_banned, banned_duration, banned_timestamp, ip FROM rebanner_fingerprints", TableType_Fingerprints);
                }
                case TableType_SteamIDs:
                {
                        db.Query(ParseDatabaseRecords, "SELECT steamid2, fingerprint FROM rebanner_steamids", TableType_SteamIDs);
                }
                case TableType_IPs:
                {
                        db.Query(ParseDatabaseRecords, "SELECT ip, fingerprint FROM rebanner_ips", TableType_IPs);
                }
        }
}

public void ParseDatabaseRecords(Database dtb, DBResultSet results, const char[] error, TableType tableType)
{
        if(error[0])
                SetFailState("Failed to parse database: %s", error);  

        while(results.FetchRow())
        {
                switch(tableType)
                {
                        case TableType_Fingerprints:
                        {
                                DataPack pack = new DataPack();
                                char fingerprint[128], steamIds[128], ips[128];             

                                results.FetchString(0, fingerprint, sizeof(fingerprint));  //fp itself
                                results.FetchString(1, steamIds, sizeof(steamIds));  //steamid 
                                pack.WriteString(steamIds);

                                bool isBanned = view_as<bool>(results.FetchInt(2));

                                pack.WriteCell(isBanned); //is_banned, bool
                                pack.WriteCell(results.FetchInt(3)); //banned_duration, int
                                pack.WriteCell(results.FetchInt(4)); //banned_timestamp, int
                                results.FetchString(5, ips, sizeof(ips));
                                pack.WriteString(ips);
                                fingerprintTable.SetValue(fingerprint, pack);
                                char key[16];
                                IntToString(fingerprintCounter, key, sizeof(key));
                                if(isBanned)
                                        bannedFingerprints.SetString(fingerprint, "");                                                       

                        }
                        case TableType_SteamIDs:
                        {
                                char fingerprint[128], steamId[32];             
                                results.FetchString(0, steamId, sizeof(steamId));  //steamID2
                                results.FetchString(1, fingerprint, sizeof(fingerprint));  //fingerprint string
                                steamIDToFingerprintTable.SetString(steamId, fingerprint);
                        }
                        case TableType_IPs:
                        {
                                if(!shouldCheckIP.BoolValue)
                                        return;

                                char fingerprint[128], ip[64];             

                                results.FetchString(0, ip, sizeof(ip));  //IP address
                                results.FetchString(1, fingerprint, sizeof(fingerprint));  //fingerprint string
                                ipToFingerprintTable.SetString(ip, fingerprint);
                        }
                }
        }
        if(tableType == TableType_IPs)
                globalLocked = false;
}