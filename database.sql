-- Adminer 4.8.1 MySQL 5.7.41 dump

SET NAMES utf8;
SET time_zone = '+00:00';
SET foreign_key_checks = 0;

DROP TABLE IF EXISTS `ip2country`;
CREATE TABLE `ip2country` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `begin_ip_num` int(11) unsigned NOT NULL,
  `end_ip_num` int(11) unsigned NOT NULL,
  `country_code` varchar(4) NOT NULL,
  `country_name` varchar(128) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `begin_ip_num` (`begin_ip_num`,`end_ip_num`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `ip2country_blocks`;
CREATE TABLE `ip2country_blocks` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `begin_ip_num` int(11) unsigned NOT NULL,
  `end_ip_num` int(11) unsigned NOT NULL,
  `loc_id` int(11) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `beginend` (`begin_ip_num`,`end_ip_num`) USING BTREE,
  KEY `loc_id` (`loc_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `ip2country_locations`;
CREATE TABLE `ip2country_locations` (
  `loc_id` int(11) unsigned NOT NULL,
  `country_code` varchar(4) NOT NULL,
  `loc_region` varchar(128) NOT NULL,
  `loc_city` tinyblob NOT NULL,
  `latitude` double NOT NULL,
  `longitude` double NOT NULL,
  PRIMARY KEY (`loc_id`),
  KEY `country_code` (`country_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


SET NAMES utf8mb4;

DROP TABLE IF EXISTS `lilac_detections`;
CREATE TABLE `lilac_detections` (
  `name` varchar(128) CHARACTER SET utf8mb4 NOT NULL,
  `steamid` varchar(32) CHARACTER SET utf8mb4 NOT NULL,
  `ip` varchar(16) CHARACTER SET utf8mb4 NOT NULL,
  `cheat` varchar(50) CHARACTER SET utf8mb4 NOT NULL,
  `timestamp` int(11) NOT NULL,
  `detection` int(11) NOT NULL,
  `pos1` float NOT NULL,
  `pos2` float NOT NULL,
  `pos3` float NOT NULL,
  `ang1` float NOT NULL,
  `ang2` float NOT NULL,
  `ang3` float NOT NULL,
  `map` varchar(128) CHARACTER SET utf8mb4 NOT NULL,
  `team` int(11) NOT NULL,
  `weapon` varchar(64) CHARACTER SET utf8mb4 NOT NULL,
  `data1` float NOT NULL,
  `data2` float NOT NULL,
  `latency_inc` float NOT NULL,
  `latency_out` float NOT NULL,
  `loss_inc` float NOT NULL,
  `loss_out` float NOT NULL,
  `choke_inc` float NOT NULL,
  `choke_out` float NOT NULL,
  `connection_ticktime` float NOT NULL,
  `game_ticktime` float NOT NULL,
  `lilac_version` varchar(20) CHARACTER SET utf8mb4 NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `maps`;
CREATE TABLE `maps` (
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `gamemode` int(1) NOT NULL DEFAULT '0',
  `custom` bit(1) NOT NULL DEFAULT b'0',
  `playtime_nor` int(11) NOT NULL DEFAULT '0',
  `playtime_adv` int(11) NOT NULL DEFAULT '0',
  `playtime_exp` int(11) NOT NULL DEFAULT '0',
  `restarts_nor` int(11) NOT NULL DEFAULT '0',
  `restarts_adv` int(11) NOT NULL DEFAULT '0',
  `restarts_exp` int(11) NOT NULL DEFAULT '0',
  `points_nor` int(11) NOT NULL DEFAULT '0',
  `points_adv` int(11) NOT NULL DEFAULT '0',
  `points_exp` int(11) NOT NULL DEFAULT '0',
  `points_infected_nor` int(11) NOT NULL DEFAULT '0',
  `points_infected_adv` int(11) NOT NULL DEFAULT '0',
  `points_infected_exp` int(11) NOT NULL DEFAULT '0',
  `kills_nor` int(11) NOT NULL DEFAULT '0',
  `kills_adv` int(11) NOT NULL DEFAULT '0',
  `kills_exp` int(11) NOT NULL DEFAULT '0',
  `survivor_kills_nor` int(11) NOT NULL DEFAULT '0',
  `survivor_kills_adv` int(11) NOT NULL DEFAULT '0',
  `survivor_kills_exp` int(11) NOT NULL DEFAULT '0',
  `infected_win_nor` int(11) NOT NULL DEFAULT '0',
  `infected_win_adv` int(11) NOT NULL DEFAULT '0',
  `infected_win_exp` int(11) NOT NULL DEFAULT '0',
  `survivors_win_nor` int(11) NOT NULL DEFAULT '0',
  `survivors_win_adv` int(11) NOT NULL DEFAULT '0',
  `survivors_win_exp` int(11) NOT NULL DEFAULT '0',
  `infected_smoker_damage_nor` bigint(20) NOT NULL DEFAULT '0',
  `infected_smoker_damage_adv` bigint(20) NOT NULL DEFAULT '0',
  `infected_smoker_damage_exp` bigint(20) NOT NULL DEFAULT '0',
  `infected_jockey_damage_nor` bigint(20) NOT NULL DEFAULT '0',
  `infected_jockey_damage_adv` bigint(20) NOT NULL DEFAULT '0',
  `infected_jockey_damage_exp` bigint(20) NOT NULL DEFAULT '0',
  `infected_jockey_ridetime_nor` double NOT NULL DEFAULT '0',
  `infected_jockey_ridetime_adv` double NOT NULL DEFAULT '0',
  `infected_jockey_ridetime_exp` double NOT NULL DEFAULT '0',
  `infected_charger_damage_nor` bigint(20) NOT NULL DEFAULT '0',
  `infected_charger_damage_adv` bigint(20) NOT NULL DEFAULT '0',
  `infected_charger_damage_exp` bigint(20) NOT NULL DEFAULT '0',
  `infected_tank_damage_nor` bigint(20) NOT NULL DEFAULT '0',
  `infected_tank_damage_adv` bigint(20) NOT NULL DEFAULT '0',
  `infected_tank_damage_exp` bigint(20) NOT NULL DEFAULT '0',
  `infected_boomer_vomits_nor` int(11) NOT NULL DEFAULT '0',
  `infected_boomer_vomits_adv` int(11) NOT NULL DEFAULT '0',
  `infected_boomer_vomits_exp` int(11) NOT NULL DEFAULT '0',
  `infected_boomer_blinded_nor` int(11) NOT NULL DEFAULT '0',
  `infected_boomer_blinded_adv` int(11) NOT NULL DEFAULT '0',
  `infected_boomer_blinded_exp` int(11) NOT NULL DEFAULT '0',
  `infected_spitter_damage_nor` int(11) NOT NULL DEFAULT '0',
  `infected_spitter_damage_adv` int(11) NOT NULL DEFAULT '0',
  `infected_spitter_damage_exp` int(11) NOT NULL DEFAULT '0',
  `infected_spawn_1_nor` int(11) NOT NULL DEFAULT '0' COMMENT 'Spawn as Smoker',
  `infected_spawn_1_adv` int(11) NOT NULL DEFAULT '0' COMMENT 'Spawn as Smoker',
  `infected_spawn_1_exp` int(11) NOT NULL DEFAULT '0' COMMENT 'Spawn as Smoker',
  `infected_spawn_2_nor` int(11) NOT NULL DEFAULT '0' COMMENT 'Spawn as Boomer',
  `infected_spawn_2_adv` int(11) NOT NULL DEFAULT '0' COMMENT 'Spawn as Boomer',
  `infected_spawn_2_exp` int(11) NOT NULL DEFAULT '0' COMMENT 'Spawn as Boomer',
  `infected_spawn_3_nor` int(11) NOT NULL DEFAULT '0' COMMENT 'Spawn as Hunter',
  `infected_spawn_3_adv` int(11) NOT NULL DEFAULT '0' COMMENT 'Spawn as Hunter',
  `infected_spawn_3_exp` int(11) NOT NULL DEFAULT '0' COMMENT 'Spawn as Hunter',
  `infected_spawn_4_nor` int(11) NOT NULL DEFAULT '0' COMMENT 'Spawn as Spitter',
  `infected_spawn_4_adv` int(11) NOT NULL DEFAULT '0' COMMENT 'Spawn as Spitter',
  `infected_spawn_4_exp` int(11) NOT NULL DEFAULT '0' COMMENT 'Spawn as Spitter',
  `infected_spawn_5_nor` int(11) NOT NULL DEFAULT '0' COMMENT 'Spawn as Jockey',
  `infected_spawn_5_adv` int(11) NOT NULL DEFAULT '0' COMMENT 'Spawn as Jockey',
  `infected_spawn_5_exp` int(11) NOT NULL DEFAULT '0' COMMENT 'Spawn as Jockey',
  `infected_spawn_6_nor` int(11) NOT NULL DEFAULT '0' COMMENT 'Spawn as Charger',
  `infected_spawn_6_adv` int(11) NOT NULL DEFAULT '0' COMMENT 'Spawn as Charger',
  `infected_spawn_6_exp` int(11) NOT NULL DEFAULT '0' COMMENT 'Spawn as Charger',
  `infected_spawn_8_nor` int(11) NOT NULL DEFAULT '0' COMMENT 'Spawn as Tank',
  `infected_spawn_8_adv` int(11) NOT NULL DEFAULT '0' COMMENT 'Spawn as Tank',
  `infected_spawn_8_exp` int(11) NOT NULL DEFAULT '0' COMMENT 'Spawn as Tank',
  `infected_hunter_pounce_counter_nor` int(11) NOT NULL DEFAULT '0',
  `infected_hunter_pounce_counter_adv` int(11) NOT NULL DEFAULT '0',
  `infected_hunter_pounce_counter_exp` int(11) NOT NULL DEFAULT '0',
  `infected_hunter_pounce_damage_nor` int(11) NOT NULL DEFAULT '0',
  `infected_hunter_pounce_damage_adv` int(11) NOT NULL DEFAULT '0',
  `infected_hunter_pounce_damage_exp` int(11) NOT NULL DEFAULT '0',
  `infected_tanksniper_nor` int(11) NOT NULL DEFAULT '0',
  `infected_tanksniper_adv` int(11) NOT NULL DEFAULT '0',
  `infected_tanksniper_exp` int(11) NOT NULL DEFAULT '0',
  `caralarm_nor` int(11) NOT NULL DEFAULT '0',
  `caralarm_adv` int(11) NOT NULL DEFAULT '0',
  `caralarm_exp` int(11) NOT NULL DEFAULT '0',
  `jockey_rides_nor` int(11) NOT NULL DEFAULT '0',
  `jockey_rides_adv` int(11) NOT NULL DEFAULT '0',
  `jockey_rides_exp` int(11) NOT NULL DEFAULT '0',
  `charger_impacts_nor` int(11) NOT NULL DEFAULT '0',
  `charger_impacts_adv` int(11) NOT NULL DEFAULT '0',
  `charger_impacts_exp` int(11) NOT NULL DEFAULT '0',
  `mutation` varchar(64) NOT NULL DEFAULT '',
  PRIMARY KEY (`name`,`gamemode`,`mutation`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `players`;
CREATE TABLE `players` (
  `steamid` varchar(255) CHARACTER SET utf8mb4 NOT NULL,
  `name` tinyblob NOT NULL,
  `lastontime` varchar(255) CHARACTER SET utf8mb4 NOT NULL,
  `lastgamemode` int(1) NOT NULL DEFAULT '0',
  `lastannemode` int(1) NOT NULL DEFAULT '0',
  `ip` varchar(16) CHARACTER SET utf8mb4 NOT NULL DEFAULT '0.0.0.0',
  `playtime` int(11) NOT NULL DEFAULT '0' COMMENT 'Playtime in Coop',
  `playtime_versus` int(11) NOT NULL DEFAULT '0' COMMENT 'Playtime in Versus',
  `playtime_realism` int(11) NOT NULL DEFAULT '0' COMMENT 'Playtime in Realism',
  `playtime_survival` int(11) NOT NULL DEFAULT '0' COMMENT 'Playtime in Survival',
  `playtime_scavenge` int(11) NOT NULL DEFAULT '0' COMMENT 'Playtime in Scavenge',
  `playtime_realismversus` int(11) NOT NULL DEFAULT '0' COMMENT 'Playtime in Realism',
  `points` int(11) NOT NULL DEFAULT '0',
  `points_realism` int(11) NOT NULL DEFAULT '0',
  `points_survival` int(11) NOT NULL DEFAULT '0',
  `points_survivors` int(11) NOT NULL DEFAULT '0',
  `points_infected` int(11) NOT NULL DEFAULT '0',
  `points_scavenge_survivors` int(11) NOT NULL DEFAULT '0',
  `points_scavenge_infected` int(11) NOT NULL DEFAULT '0',
  `points_realism_survivors` int(11) NOT NULL DEFAULT '0',
  `points_realism_infected` int(11) NOT NULL DEFAULT '0',
  `kills` int(11) NOT NULL DEFAULT '0',
  `melee_kills` int(11) NOT NULL DEFAULT '0',
  `headshots` int(11) NOT NULL DEFAULT '0',
  `kill_infected` int(11) NOT NULL DEFAULT '0',
  `kill_hunter` int(11) NOT NULL DEFAULT '0',
  `kill_smoker` int(11) NOT NULL DEFAULT '0',
  `kill_boomer` int(11) NOT NULL DEFAULT '0',
  `kill_spitter` int(11) NOT NULL DEFAULT '0',
  `kill_jockey` int(11) NOT NULL DEFAULT '0',
  `kill_charger` int(11) NOT NULL DEFAULT '0',
  `versus_kills_survivors` int(11) NOT NULL DEFAULT '0',
  `scavenge_kills_survivors` int(11) NOT NULL DEFAULT '0',
  `realism_kills_survivors` int(11) NOT NULL DEFAULT '0',
  `jockey_rides` int(11) NOT NULL DEFAULT '0',
  `charger_impacts` int(11) NOT NULL DEFAULT '0',
  `award_pills` int(11) NOT NULL DEFAULT '0',
  `award_adrenaline` int(11) NOT NULL DEFAULT '0',
  `award_fincap` int(11) NOT NULL DEFAULT '0' COMMENT 'Friendly incapacitation',
  `award_medkit` int(11) NOT NULL DEFAULT '0',
  `award_defib` int(11) NOT NULL DEFAULT '0',
  `award_charger` int(11) NOT NULL DEFAULT '0',
  `award_jockey` int(11) NOT NULL DEFAULT '0',
  `award_hunter` int(11) NOT NULL DEFAULT '0',
  `award_smoker` int(11) NOT NULL DEFAULT '0',
  `award_protect` int(11) NOT NULL DEFAULT '0',
  `award_revive` int(11) NOT NULL DEFAULT '0',
  `award_rescue` int(11) NOT NULL DEFAULT '0',
  `award_campaigns` int(11) NOT NULL DEFAULT '0',
  `award_tankkill` int(11) NOT NULL DEFAULT '0',
  `award_tankkillnodeaths` int(11) NOT NULL DEFAULT '0',
  `award_allinsafehouse` int(11) NOT NULL DEFAULT '0',
  `award_friendlyfire` int(11) NOT NULL DEFAULT '0',
  `award_teamkill` int(11) NOT NULL DEFAULT '0',
  `award_left4dead` int(11) NOT NULL DEFAULT '0',
  `award_letinsafehouse` int(11) NOT NULL DEFAULT '0',
  `award_witchdisturb` int(11) NOT NULL DEFAULT '0',
  `award_pounce_perfect` int(11) NOT NULL DEFAULT '0',
  `award_pounce_nice` int(11) NOT NULL DEFAULT '0',
  `award_perfect_blindness` int(11) NOT NULL DEFAULT '0',
  `award_infected_win` int(11) NOT NULL DEFAULT '0',
  `award_scavenge_infected_win` int(11) NOT NULL DEFAULT '0',
  `award_bulldozer` int(11) NOT NULL DEFAULT '0',
  `award_survivor_down` int(11) NOT NULL DEFAULT '0',
  `award_ledgegrab` int(11) NOT NULL DEFAULT '0',
  `award_gascans_poured` int(11) NOT NULL DEFAULT '0',
  `award_upgrades_added` int(11) NOT NULL DEFAULT '0',
  `award_matador` int(11) NOT NULL DEFAULT '0',
  `award_witchcrowned` int(11) NOT NULL DEFAULT '0',
  `award_scatteringram` int(11) NOT NULL DEFAULT '0',
  `infected_spawn_1` int(11) NOT NULL DEFAULT '0' COMMENT 'Spawned as Smoker',
  `infected_spawn_2` int(11) NOT NULL DEFAULT '0' COMMENT 'Spawned as Boomer',
  `infected_spawn_3` int(11) NOT NULL DEFAULT '0' COMMENT 'Spawned as Hunter',
  `infected_spawn_4` int(11) NOT NULL DEFAULT '0' COMMENT 'Spawned as Spitter',
  `infected_spawn_5` int(11) NOT NULL DEFAULT '0' COMMENT 'Spawned as Jockey',
  `infected_spawn_6` int(11) NOT NULL DEFAULT '0' COMMENT 'Spawned as Charger',
  `infected_spawn_8` int(11) NOT NULL DEFAULT '0' COMMENT 'Spawned as Tank',
  `infected_boomer_vomits` int(11) NOT NULL DEFAULT '0',
  `infected_boomer_blinded` int(11) NOT NULL DEFAULT '0',
  `infected_hunter_pounce_counter` int(11) NOT NULL DEFAULT '0',
  `infected_hunter_pounce_dmg` int(11) NOT NULL DEFAULT '0',
  `infected_smoker_damage` int(11) NOT NULL DEFAULT '0',
  `infected_jockey_damage` int(11) NOT NULL DEFAULT '0',
  `infected_jockey_ridetime` double NOT NULL DEFAULT '0',
  `infected_charger_damage` int(11) NOT NULL DEFAULT '0',
  `infected_tank_damage` int(11) NOT NULL DEFAULT '0',
  `infected_tanksniper` int(11) NOT NULL DEFAULT '0',
  `infected_spitter_damage` int(11) NOT NULL DEFAULT '0',
  `mutations_kills_survivors` int(11) NOT NULL DEFAULT '0',
  `playtime_mutations` int(11) NOT NULL DEFAULT '0',
  `points_mutations` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`steamid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `RPG`;
CREATE TABLE `RPG` (
  `steamid` varchar(255) CHARACTER SET utf8mb4 NOT NULL,
  `MELEE_DATA` int(10) NOT NULL DEFAULT '0',
  `BLOOD_DATA` int(10) NOT NULL DEFAULT '0',
  `HAT` int(10) NOT NULL DEFAULT '0',
  `GLOW` int(10) NOT NULL DEFAULT '0',
  `SKIN` int(10) NOT NULL DEFAULT '0',
  `RECOIL` int(10) NOT NULL DEFAULT '0',
  `CHATTAG` varchar(128) CHARACTER SET utf8mb4 DEFAULT NULL,
  `hitsound_cfg` tinyint(4) NOT NULL DEFAULT '0',
  `hitsound_overlay` tinyint(4) NOT NULL DEFAULT '0',
  PRIMARY KEY (`steamid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `rpgdamage`;
CREATE TABLE `rpgdamage` (
  `steamid` varchar(255) NOT NULL,
  `enable` tinyint(4) NOT NULL DEFAULT '0',
  `see_others` tinyint(4) NOT NULL DEFAULT '1',
  `share_scope` tinyint(4) NOT NULL DEFAULT '0',
  `size` float NOT NULL DEFAULT '5',
  `gap` float NOT NULL DEFAULT '5',
  `alpha` int(11) NOT NULL DEFAULT '70',
  `xoff` float NOT NULL DEFAULT '20',
  `yoff` float NOT NULL DEFAULT '10',
  `showdist` float NOT NULL DEFAULT '1500',
  `summode` tinyint(4) NOT NULL DEFAULT '1',
  `sg_merge` tinyint(4) NOT NULL DEFAULT '1',
  PRIMARY KEY (`steamid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


DROP TABLE IF EXISTS `server_settings`;
CREATE TABLE `server_settings` (
  `sname` varchar(64) CHARACTER SET utf8mb4 NOT NULL,
  `svalue` blob,
  PRIMARY KEY (`sname`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `l4d_server_status`;
CREATE TABLE `l4d_server_status` (
  `server_id` varchar(128) CHARACTER SET utf8mb4 NOT NULL,
  `hostname` varchar(128) CHARACTER SET utf8mb4 NOT NULL DEFAULT '',
  `players` int(11) NOT NULL DEFAULT '0',
  `updated_at` int(11) NOT NULL DEFAULT '0',
  `enabled` tinyint(4) NOT NULL DEFAULT '1',
  PRIMARY KEY (`server_id`),
  KEY `updated_at` (`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


DROP TABLE IF EXISTS `settings`;
CREATE TABLE `settings` (
  `steamid` varchar(255) CHARACTER SET utf8mb4 NOT NULL,
  `mute` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`steamid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `timedmaps`;
CREATE TABLE `timedmaps` (
  `map` varchar(255) CHARACTER SET utf8mb4 NOT NULL,
  `gamemode` int(1) unsigned NOT NULL,
  `difficulty` int(1) unsigned NOT NULL,
  `steamid` varchar(255) CHARACTER SET utf8mb4 NOT NULL,
  `plays` int(11) NOT NULL,
  `time` double NOT NULL,
  `players` int(2) NOT NULL,
  `modified` datetime NOT NULL,
  `created` date NOT NULL,
  `mutation` varchar(64) CHARACTER SET utf8mb4 NOT NULL DEFAULT '',
  `mode` int(1) unsigned NOT NULL DEFAULT '0',
  `sinum` int(1) unsigned NOT NULL DEFAULT '0',
  `sitime` int(1) unsigned NOT NULL DEFAULT '0',
  `usebuy` int(1) unsigned NOT NULL DEFAULT '0',
  `auto` int(1) unsigned NOT NULL DEFAULT '0',
  `anneversion` varchar(64) CHARACTER SET utf8mb4 NOT NULL DEFAULT 'None',
  PRIMARY KEY (`map`,`gamemode`,`difficulty`,`steamid`,`time`,`mutation`,`mode`,`sinum`,`sitime`,`usebuy`,`anneversion`,`auto`,`players`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `sb_admins`;
CREATE TABLE `sb_admins` (
  `aid` int(6) NOT NULL AUTO_INCREMENT,
  `user` varchar(64) NOT NULL,
  `authid` varchar(64) NOT NULL DEFAULT '',
  `password` varchar(128) NOT NULL,
  `gid` int(6) NOT NULL,
  `email` varchar(128) NOT NULL,
  `validate` varchar(128) DEFAULT NULL,
  `extraflags` int(10) NOT NULL,
  `immunity` int(10) NOT NULL DEFAULT '0',
  `srv_group` varchar(128) DEFAULT NULL,
  `srv_flags` varchar(64) DEFAULT NULL,
  `srv_password` varchar(128) DEFAULT NULL,
  `lastvisit` int(11) DEFAULT NULL,
  PRIMARY KEY (`aid`),
  UNIQUE KEY `user` (`user`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


DROP TABLE IF EXISTS `sb_admins_servers_groups`;
CREATE TABLE `sb_admins_servers_groups` (
  `admin_id` int(10) NOT NULL,
  `group_id` int(10) NOT NULL,
  `srv_group_id` int(10) NOT NULL,
  `server_id` int(10) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


DROP TABLE IF EXISTS `sb_banlog`;
CREATE TABLE `sb_banlog` (
  `sid` int(6) NOT NULL,
  `time` int(11) NOT NULL,
  `name` varchar(128) NOT NULL,
  `bid` int(6) NOT NULL,
  PRIMARY KEY (`sid`,`time`,`bid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


DROP TABLE IF EXISTS `sb_bans`;
CREATE TABLE `sb_bans` (
  `bid` int(6) NOT NULL AUTO_INCREMENT,
  `ip` varchar(32) DEFAULT NULL,
  `authid` varchar(64) NOT NULL DEFAULT '',
  `name` varchar(128) NOT NULL DEFAULT 'unnamed',
  `created` int(11) NOT NULL DEFAULT '0',
  `ends` int(11) NOT NULL DEFAULT '0',
  `length` int(10) NOT NULL DEFAULT '0',
  `reason` text NOT NULL,
  `aid` int(6) NOT NULL DEFAULT '0',
  `adminIp` varchar(32) NOT NULL DEFAULT '',
  `sid` int(6) NOT NULL DEFAULT '0',
  `country` varchar(4) DEFAULT NULL,
  `RemovedBy` int(8) DEFAULT NULL,
  `RemoveType` varchar(3) DEFAULT NULL,
  `RemovedOn` int(10) DEFAULT NULL,
  `type` tinyint(4) NOT NULL DEFAULT '0',
  `ureason` text,
  PRIMARY KEY (`bid`),
  KEY `sid` (`sid`),
  KEY `type_authid` (`type`,`authid`),
  KEY `type_ip` (`type`,`ip`),
  FULLTEXT KEY `reason` (`reason`),
  FULLTEXT KEY `authid_2` (`authid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


DROP TABLE IF EXISTS `sb_comments`;
CREATE TABLE `sb_comments` (
  `cid` int(6) NOT NULL AUTO_INCREMENT,
  `bid` int(6) NOT NULL,
  `type` varchar(1) NOT NULL,
  `aid` int(6) NOT NULL,
  `commenttxt` longtext NOT NULL,
  `added` int(11) NOT NULL,
  `editaid` int(6) DEFAULT NULL,
  `edittime` int(11) DEFAULT NULL,
  KEY `cid` (`cid`),
  FULLTEXT KEY `commenttxt` (`commenttxt`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


DROP TABLE IF EXISTS `sb_comms`;
CREATE TABLE `sb_comms` (
  `bid` int(6) NOT NULL AUTO_INCREMENT,
  `authid` varchar(64) NOT NULL,
  `name` varchar(128) NOT NULL DEFAULT 'unnamed',
  `created` int(11) NOT NULL DEFAULT '0',
  `ends` int(11) NOT NULL DEFAULT '0',
  `length` int(10) NOT NULL DEFAULT '0',
  `reason` text NOT NULL,
  `aid` int(6) NOT NULL DEFAULT '0',
  `adminIp` varchar(32) NOT NULL DEFAULT '',
  `sid` int(6) NOT NULL DEFAULT '0',
  `RemovedBy` int(8) DEFAULT NULL,
  `RemoveType` varchar(3) DEFAULT NULL,
  `RemovedOn` int(11) DEFAULT NULL,
  `type` tinyint(4) NOT NULL DEFAULT '0' COMMENT '1 - Mute, 2 - Gag',
  `ureason` text,
  PRIMARY KEY (`bid`),
  KEY `sid` (`sid`),
  KEY `type` (`type`),
  KEY `RemoveType` (`RemoveType`),
  KEY `authid` (`authid`),
  KEY `created` (`created`),
  KEY `aid` (`aid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


DROP TABLE IF EXISTS `sb_demos`;
CREATE TABLE `sb_demos` (
  `demid` int(6) NOT NULL,
  `demtype` varchar(1) NOT NULL,
  `filename` varchar(128) NOT NULL,
  `origname` varchar(128) NOT NULL,
  PRIMARY KEY (`demid`,`demtype`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


DROP TABLE IF EXISTS `sb_groups`;
CREATE TABLE `sb_groups` (
  `gid` int(6) NOT NULL AUTO_INCREMENT,
  `type` smallint(6) NOT NULL DEFAULT '0',
  `name` varchar(128) NOT NULL DEFAULT 'unnamed',
  `flags` int(10) NOT NULL,
  PRIMARY KEY (`gid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


DROP TABLE IF EXISTS `sb_log`;
CREATE TABLE `sb_log` (
  `lid` int(11) NOT NULL AUTO_INCREMENT,
  `type` enum('m','w','e') NOT NULL,
  `title` varchar(512) NOT NULL,
  `message` text NOT NULL,
  `function` text NOT NULL,
  `query` text NOT NULL,
  `aid` int(11) NOT NULL,
  `host` text NOT NULL,
  `created` int(11) NOT NULL,
  PRIMARY KEY (`lid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


DROP TABLE IF EXISTS `sb_login_tokens`;
CREATE TABLE `sb_login_tokens` (
  `jti` varchar(16) NOT NULL,
  `secret` varchar(64) NOT NULL,
  `lastAccessed` int(11) NOT NULL,
  PRIMARY KEY (`jti`),
  UNIQUE KEY `secret` (`secret`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


DROP TABLE IF EXISTS `sb_mods`;
CREATE TABLE `sb_mods` (
  `mid` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(128) NOT NULL,
  `icon` varchar(128) NOT NULL,
  `modfolder` varchar(64) NOT NULL,
  `steam_universe` tinyint(4) NOT NULL DEFAULT '0',
  `enabled` tinyint(4) NOT NULL DEFAULT '1',
  PRIMARY KEY (`mid`),
  UNIQUE KEY `modfolder` (`modfolder`),
  UNIQUE KEY `name` (`name`),
  KEY `steam_universe` (`steam_universe`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


DROP TABLE IF EXISTS `sb_overrides`;
CREATE TABLE `sb_overrides` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` enum('command','group') NOT NULL,
  `name` varchar(32) NOT NULL,
  `flags` varchar(30) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `type` (`type`,`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


DROP TABLE IF EXISTS `sb_protests`;
CREATE TABLE `sb_protests` (
  `pid` int(6) NOT NULL AUTO_INCREMENT,
  `bid` int(6) NOT NULL,
  `datesubmitted` int(11) NOT NULL,
  `reason` text NOT NULL,
  `email` varchar(128) NOT NULL,
  `archiv` tinyint(1) DEFAULT '0',
  `archivedby` int(11) DEFAULT NULL,
  `pip` varchar(64) NOT NULL,
  PRIMARY KEY (`pid`),
  KEY `bid` (`bid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


DROP TABLE IF EXISTS `sb_servers`;
CREATE TABLE `sb_servers` (
  `sid` int(6) NOT NULL AUTO_INCREMENT,
  `ip` varchar(64) NOT NULL,
  `port` int(5) NOT NULL,
  `rcon` varchar(64) NOT NULL,
  `modid` int(10) NOT NULL,
  `enabled` tinyint(4) NOT NULL DEFAULT '1',
  PRIMARY KEY (`sid`),
  UNIQUE KEY `ip` (`ip`,`port`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


DROP TABLE IF EXISTS `sb_servers_groups`;
CREATE TABLE `sb_servers_groups` (
  `server_id` int(10) NOT NULL,
  `group_id` int(10) NOT NULL,
  PRIMARY KEY (`server_id`,`group_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


DROP TABLE IF EXISTS `sb_settings`;
CREATE TABLE `sb_settings` (
  `setting` varchar(128) NOT NULL,
  `value` text NOT NULL,
  UNIQUE KEY `setting` (`setting`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


DROP TABLE IF EXISTS `sb_srvgroups`;
CREATE TABLE `sb_srvgroups` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `flags` varchar(30) NOT NULL,
  `immunity` int(10) unsigned NOT NULL,
  `name` varchar(120) NOT NULL,
  `groups_immune` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


DROP TABLE IF EXISTS `sb_srvgroups_overrides`;
CREATE TABLE `sb_srvgroups_overrides` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `group_id` smallint(5) unsigned NOT NULL,
  `type` enum('command','group') NOT NULL,
  `name` varchar(32) NOT NULL,
  `access` enum('allow','deny') NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `group_id` (`group_id`,`type`,`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


DROP TABLE IF EXISTS `sb_submissions`;
CREATE TABLE `sb_submissions` (
  `subid` int(6) NOT NULL AUTO_INCREMENT,
  `submitted` int(11) NOT NULL,
  `ModID` int(6) NOT NULL,
  `SteamId` varchar(64) NOT NULL DEFAULT 'unnamed',
  `name` varchar(128) NOT NULL,
  `email` varchar(128) NOT NULL,
  `reason` text NOT NULL,
  `ip` varchar(64) NOT NULL,
  `subname` varchar(128) DEFAULT NULL,
  `sip` varchar(64) DEFAULT NULL,
  `archiv` tinyint(1) DEFAULT '0',
  `archivedby` int(11) DEFAULT NULL,
  `server` tinyint(3) DEFAULT NULL,
  PRIMARY KEY (`subid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- 2025-09-27 04:08:16
