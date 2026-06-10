-- Adminer 4.8.1 MySQL 5.7.44-log dump

SET NAMES utf8;
SET time_zone = '+00:00';
SET foreign_key_checks = 0;

USE `Anne`;

SET NAMES utf8mb4;

DROP TABLE IF EXISTS `AnneServer`;
CREATE TABLE `AnneServer` (
  `AnneIP` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `AnneNAME` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `AnneTICK` int(10) NOT NULL,
  PRIMARY KEY (`AnneIP`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `cdk`;
CREATE TABLE `cdk` (
  `Type` int(11) NOT NULL,
  `Denomination` int(11) NOT NULL,
  `Uuid` text NOT NULL,
  `IsUsed` tinyint(1) NOT NULL,
  `CreateTime` datetime NOT NULL,
  `UsedTime` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


DROP TABLE IF EXISTS `infected`;
CREATE TABLE `infected` (
  `number` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `health` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `speed` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `slowspeed` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `damage1` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `damage2` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `bhop` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `teleport` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `anneset` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `l4d2`;
CREATE TABLE `l4d2` (
  `steam_id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `steam_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `LELVEL_DATA` int(10) NOT NULL,
  `EXPERIENCE_DATA` int(10) NOT NULL,
  `MELEE_DATA` int(10) NOT NULL,
  `BLOOD_DATA` int(10) NOT NULL,
  `INFECTED_DATA` int(10) NOT NULL,
  `MONEY_DATA` int(10) NOT NULL,
  `STATUS` int(11) NOT NULL DEFAULT '0',
  `Str_DATA` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `End_DATA` int(11) NOT NULL,
  `Health_DATA` int(11) NOT NULL,
  `Agi_DATA` int(11) NOT NULL,
  `StatusPoint_DATA` int(11) NOT NULL,
  PRIMARY KEY (`steam_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


DROP TABLE IF EXISTS `l4d3`;
CREATE TABLE `l4d3` (
  `steam_id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `steam_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `LELVEL_DATA` int(10) NOT NULL,
  `EXPERIENCE_DATA` int(10) NOT NULL,
  `MELEE_DATA` int(10) NOT NULL,
  `BLOOD_DATA` int(10) NOT NULL,
  `INFECTED_DATA` int(10) NOT NULL,
  `MONEY_DATA` int(10) NOT NULL,
  `STATUS` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`steam_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


DROP TABLE IF EXISTS `ServerIP`;
CREATE TABLE `ServerIP` (
  `AnneIP` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `AnneNAME` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `AnneTICK` int(10) NOT NULL,
  `Version` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`AnneIP`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `stats_presistence`;
CREATE TABLE `stats_presistence` (
  `steam_id` bigint(20) NOT NULL,
  `exp` int(11) NOT NULL,
  `level` int(11) NOT NULL,
  `currency` int(11) NOT NULL,
  `heal_when_kill` int(11) NOT NULL,
  `common` int(11) NOT NULL,
  `smoker` int(11) NOT NULL,
  `boomer` int(11) NOT NULL,
  `hunter` int(11) NOT NULL,
  `spitter` int(11) NOT NULL,
  `jockey` int(11) NOT NULL,
  `charger` int(11) NOT NULL,
  `witch` int(11) NOT NULL,
  `tank` int(11) NOT NULL,
  `help` int(11) NOT NULL,
  PRIMARY KEY (`steam_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


DROP TABLE IF EXISTS `weapon`;
CREATE TABLE `weapon` (
  `number` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `weapon` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `damage` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `scatterpitch` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `scatteryaw` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `spreadpershot` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `maxmovespread` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `rangemod` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `reloadtime` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


USE `chat`;

DROP TABLE IF EXISTS `anne_global_chat`;
CREATE TABLE `anne_global_chat` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime NOT NULL,
  `server` varchar(126) NOT NULL,
  `port` int(11) NOT NULL DEFAULT '0',
  `steamid` varchar(32) NOT NULL,
  `name` varchar(128) NOT NULL,
  `message` varchar(255) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_anne_global_chat_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


DROP TABLE IF EXISTS `anne_global_chat_titles`;
CREATE TABLE `anne_global_chat_titles` (
  `steamid` varchar(32) NOT NULL,
  `title` varchar(64) NOT NULL,
  PRIMARY KEY (`steamid`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


DROP TABLE IF EXISTS `anne_global_chat_usage`;
CREATE TABLE `anne_global_chat_usage` (
  `steamid` varchar(32) NOT NULL,
  `usage_date` date NOT NULL,
  `used_count` int(10) unsigned NOT NULL DEFAULT '0',
  `last_used_at` datetime NOT NULL,
  PRIMARY KEY (`steamid`,`usage_date`) USING BTREE,
  KEY `idx_anne_global_chat_usage_date` (`usage_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


DROP TABLE IF EXISTS `anne_lfg_chat_usage`;
CREATE TABLE `anne_lfg_chat_usage` (
  `steamid` varchar(32) NOT NULL,
  `usage_date` date NOT NULL,
  `used_count` int(10) unsigned NOT NULL DEFAULT '0',
  `last_used_at` datetime NOT NULL,
  PRIMARY KEY (`steamid`,`usage_date`) USING BTREE,
  KEY `idx_anne_lfg_chat_usage_date` (`usage_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


DROP TABLE IF EXISTS `chat_log`;
CREATE TABLE `chat_log` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `date` datetime DEFAULT NULL,
  `map` varchar(128) NOT NULL,
  `steamid` varchar(21) NOT NULL,
  `name` varchar(128) NOT NULL,
  `message_style` tinyint(2) DEFAULT '0',
  `message` varchar(126) NOT NULL,
  `server` varchar(126) DEFAULT NULL,
  `port` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_chat_log_date` (`date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


USE `l4d2stats`;

DROP TABLE IF EXISTS `ai_dynamic_ppm_thresholds`;
CREATE TABLE `ai_dynamic_ppm_thresholds` (
  `id` tinyint(3) unsigned NOT NULL DEFAULT '1',
  `source` varchar(32) NOT NULL DEFAULT 'daily',
  `sample_count` int(11) NOT NULL DEFAULT '0',
  `ppm_p60` float NOT NULL DEFAULT '30.89',
  `ppm_p75` float NOT NULL DEFAULT '43.23',
  `ppm_p90` float NOT NULL DEFAULT '63.7',
  `ppm_p95` float NOT NULL DEFAULT '77.57',
  `updated_at` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


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


DROP TABLE IF EXISTS `l4d_peak_state`;
CREATE TABLE `l4d_peak_state` (
  `state_key` varchar(64) NOT NULL,
  `hold_until` int(11) NOT NULL DEFAULT '0',
  `updated_at` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`state_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


DROP TABLE IF EXISTS `l4d_server_status`;
CREATE TABLE `l4d_server_status` (
  `address_key` varchar(160) NOT NULL,
  `server_id` varchar(128) NOT NULL,
  `hostname` varchar(128) NOT NULL DEFAULT '',
  `ip` varchar(64) NOT NULL DEFAULT '',
  `port` int(11) NOT NULL DEFAULT '0',
  `players` int(11) NOT NULL DEFAULT '0',
  `updated_at` int(11) NOT NULL DEFAULT '0',
  `enabled` tinyint(4) NOT NULL DEFAULT '1',
  `is_good_server` tinyint(4) NOT NULL DEFAULT '0',
  PRIMARY KEY (`address_key`),
  KEY `server_id` (`server_id`),
  KEY `updated_at` (`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


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
  `totalpoints` int(11) GENERATED ALWAYS AS ((((((((((`points` + `points_survivors`) + `points_infected`) + `points_realism`) + `points_survival`) + `points_scavenge_survivors`) + `points_scavenge_infected`) + `points_realism_survivors`) + `points_realism_infected`) + `points_mutations`)) STORED,
  `totalplaytime` int(11) GENERATED ALWAYS AS (((((((`playtime` + `playtime_versus`) + `playtime_realism`) + `playtime_survival`) + `playtime_scavenge`) + `playtime_realismversus`) + `playtime_mutations`)) STORED,
  PRIMARY KEY (`steamid`),
  KEY `idx_lastontime` (`lastontime`),
  KEY `idx_players_totalpoints` (`totalpoints`),
  KEY `idx_players_totalplaytime` (`totalplaytime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `player_blocks`;
CREATE TABLE `player_blocks` (
  `blocker` varchar(32) NOT NULL,
  `blocked` varchar(32) NOT NULL,
  `created_at` int(11) NOT NULL,
  PRIMARY KEY (`blocker`,`blocked`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


DROP TABLE IF EXISTS `player_mode_stats`;
CREATE TABLE `player_mode_stats` (
  `steamid` varchar(64) NOT NULL,
  `mode_id` tinyint(4) NOT NULL,
  `anne_mode` tinyint(4) NOT NULL DEFAULT '0',
  `points` int(11) NOT NULL DEFAULT '0',
  `playtime` int(11) NOT NULL DEFAULT '0',
  `kills` int(11) NOT NULL DEFAULT '0',
  `headshots` int(11) NOT NULL DEFAULT '0',
  `updated` int(10) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`steamid`,`mode_id`,`anne_mode`),
  KEY `mode_ppm` (`mode_id`,`anne_mode`,`playtime`,`points`),
  KEY `mode_kpm` (`mode_id`,`anne_mode`,`playtime`,`kills`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


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
  `hitsound_head` tinyint(4) NOT NULL DEFAULT '0',
  `hitsound_hit` tinyint(4) NOT NULL DEFAULT '0',
  `hitsound_kill` tinyint(4) NOT NULL DEFAULT '0',
  `hiticon_head` tinyint(4) NOT NULL DEFAULT '0',
  `hiticon_hit` tinyint(4) NOT NULL DEFAULT '0',
  `hiticon_kill` tinyint(4) NOT NULL DEFAULT '0',
  `hitsound_si_only` tinyint(4) NOT NULL DEFAULT '0',
  `hiticon_si_only` tinyint(4) NOT NULL DEFAULT '0',
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


DROP TABLE IF EXISTS `score_log`;
CREATE TABLE `score_log` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `created` int(11) NOT NULL,
  `steamid` varchar(64) NOT NULL,
  `name` varchar(128) NOT NULL,
  `map` varchar(128) NOT NULL,
  `gamemode` int(2) NOT NULL DEFAULT '0',
  `difficulty` varchar(32) NOT NULL DEFAULT '',
  `team` int(2) NOT NULL DEFAULT '0',
  `score` int(11) NOT NULL DEFAULT '0',
  `score_after` int(11) NOT NULL DEFAULT '0',
  `reason` varchar(64) NOT NULL DEFAULT 'unknown',
  `formula` varchar(255) NOT NULL DEFAULT '',
  `round_valid` tinyint(1) NOT NULL DEFAULT '0',
  `usebuy` tinyint(1) NOT NULL DEFAULT '0',
  `newbie_count` int(4) NOT NULL DEFAULT '0',
  `newbie_multiplier` double NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  KEY `steamid_created` (`steamid`,`created`),
  KEY `reason_created` (`reason`,`created`),
  KEY `map_created` (`map`,`created`),
  KEY `score_created` (`score`,`created`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


DROP TABLE IF EXISTS `score_quarter`;
CREATE TABLE `score_quarter` (
  `steamid` varchar(64) NOT NULL,
  `quarter_key` int(8) NOT NULL DEFAULT '0',
  `points` int(11) NOT NULL DEFAULT '0',
  `playtime` int(11) NOT NULL DEFAULT '0',
  `updated` int(11) NOT NULL DEFAULT '0',
  `points_coop` int(11) NOT NULL DEFAULT '0',
  `points_survivors` int(11) NOT NULL DEFAULT '0',
  `points_infected` int(11) NOT NULL DEFAULT '0',
  `points_survival` int(11) NOT NULL DEFAULT '0',
  `points_realism` int(11) NOT NULL DEFAULT '0',
  `points_scavenge_survivors` int(11) NOT NULL DEFAULT '0',
  `points_scavenge_infected` int(11) NOT NULL DEFAULT '0',
  `points_realism_survivors` int(11) NOT NULL DEFAULT '0',
  `points_realism_infected` int(11) NOT NULL DEFAULT '0',
  `points_mutations` int(11) NOT NULL DEFAULT '0',
  `kills` int(11) NOT NULL DEFAULT '0',
  `headshots` int(11) NOT NULL DEFAULT '0',
  `melee_kills` int(11) NOT NULL DEFAULT '0',
  `kill_infected` int(11) NOT NULL DEFAULT '0',
  `kill_hunter` int(11) NOT NULL DEFAULT '0',
  `kill_smoker` int(11) NOT NULL DEFAULT '0',
  `kill_boomer` int(11) NOT NULL DEFAULT '0',
  `kill_spitter` int(11) NOT NULL DEFAULT '0',
  `kill_jockey` int(11) NOT NULL DEFAULT '0',
  `kill_charger` int(11) NOT NULL DEFAULT '0',
  `award_medkit` int(11) NOT NULL DEFAULT '0',
  `award_pills` int(11) NOT NULL DEFAULT '0',
  `award_adrenaline` int(11) NOT NULL DEFAULT '0',
  `award_revive` int(11) NOT NULL DEFAULT '0',
  `award_defib` int(11) NOT NULL DEFAULT '0',
  `award_rescue` int(11) NOT NULL DEFAULT '0',
  `award_protect` int(11) NOT NULL DEFAULT '0',
  `award_friendlyfire` int(11) NOT NULL DEFAULT '0',
  `award_teamkill` int(11) NOT NULL DEFAULT '0',
  `award_fincap` int(11) NOT NULL DEFAULT '0',
  `award_left4dead` int(11) NOT NULL DEFAULT '0',
  `award_letinsafehouse` int(11) NOT NULL DEFAULT '0',
  `award_witchdisturb` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`steamid`),
  KEY `quarter_points` (`quarter_key`,`points`),
  KEY `points` (`points`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


DROP TABLE IF EXISTS `score_quarter_history`;
CREATE TABLE `score_quarter_history` (
  `quarter_key` int(10) unsigned NOT NULL,
  `rank_num` smallint(5) unsigned NOT NULL,
  `steamid` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `points` int(11) NOT NULL DEFAULT '0',
  `archived_at` int(10) unsigned NOT NULL,
  `playtime` int(11) NOT NULL DEFAULT '0',
  `points_coop` int(11) NOT NULL DEFAULT '0',
  `points_survivors` int(11) NOT NULL DEFAULT '0',
  `points_infected` int(11) NOT NULL DEFAULT '0',
  `points_survival` int(11) NOT NULL DEFAULT '0',
  `points_realism` int(11) NOT NULL DEFAULT '0',
  `points_scavenge_survivors` int(11) NOT NULL DEFAULT '0',
  `points_scavenge_infected` int(11) NOT NULL DEFAULT '0',
  `points_realism_survivors` int(11) NOT NULL DEFAULT '0',
  `points_realism_infected` int(11) NOT NULL DEFAULT '0',
  `points_mutations` int(11) NOT NULL DEFAULT '0',
  `kills` int(11) NOT NULL DEFAULT '0',
  `headshots` int(11) NOT NULL DEFAULT '0',
  `melee_kills` int(11) NOT NULL DEFAULT '0',
  `kill_infected` int(11) NOT NULL DEFAULT '0',
  `kill_hunter` int(11) NOT NULL DEFAULT '0',
  `kill_smoker` int(11) NOT NULL DEFAULT '0',
  `kill_boomer` int(11) NOT NULL DEFAULT '0',
  `kill_spitter` int(11) NOT NULL DEFAULT '0',
  `kill_jockey` int(11) NOT NULL DEFAULT '0',
  `kill_charger` int(11) NOT NULL DEFAULT '0',
  `award_medkit` int(11) NOT NULL DEFAULT '0',
  `award_pills` int(11) NOT NULL DEFAULT '0',
  `award_adrenaline` int(11) NOT NULL DEFAULT '0',
  `award_revive` int(11) NOT NULL DEFAULT '0',
  `award_defib` int(11) NOT NULL DEFAULT '0',
  `award_rescue` int(11) NOT NULL DEFAULT '0',
  `award_protect` int(11) NOT NULL DEFAULT '0',
  `award_friendlyfire` int(11) NOT NULL DEFAULT '0',
  `award_teamkill` int(11) NOT NULL DEFAULT '0',
  `award_fincap` int(11) NOT NULL DEFAULT '0',
  `award_left4dead` int(11) NOT NULL DEFAULT '0',
  `award_letinsafehouse` int(11) NOT NULL DEFAULT '0',
  `award_witchdisturb` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`quarter_key`,`rank_num`),
  UNIQUE KEY `quarter_steamid` (`quarter_key`,`steamid`),
  KEY `quarter_points` (`quarter_key`,`points`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


DROP TABLE IF EXISTS `server_settings`;
CREATE TABLE `server_settings` (
  `sname` varchar(64) CHARACTER SET utf8mb4 NOT NULL,
  `svalue` blob,
  PRIMARY KEY (`sname`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


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
  PRIMARY KEY (`map`,`gamemode`,`difficulty`,`steamid`,`time`,`mutation`,`mode`,`sinum`,`sitime`,`usebuy`,`anneversion`,`auto`,`players`),
  KEY `idx_steamid` (`steamid`),
  KEY `idx_timedmaps_filter_time` (`anneversion`,`sinum`,`sitime`,`usebuy`,`auto`,`mode`,`time`),
  KEY `idx_timedmaps_filter_players_time` (`anneversion`,`sinum`,`sitime`,`usebuy`,`auto`,`mode`,`players`,`time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `timedmap_runs`;
CREATE TABLE `timedmap_runs` (
  `run_id` varchar(64) NOT NULL,
  `map` varchar(255) CHARACTER SET utf8mb4 NOT NULL,
  `gamemode` int(1) unsigned NOT NULL,
  `difficulty` int(1) unsigned NOT NULL,
  `steamid` varchar(255) CHARACTER SET utf8mb4 NOT NULL,
  `time` double NOT NULL,
  `players` int(2) NOT NULL,
  `mutation` varchar(64) CHARACTER SET utf8mb4 NOT NULL DEFAULT '',
  `mode` int(1) unsigned NOT NULL DEFAULT '0',
  `sinum` int(1) unsigned NOT NULL DEFAULT '0',
  `sitime` int(1) unsigned NOT NULL DEFAULT '0',
  `usebuy` int(1) unsigned NOT NULL DEFAULT '0',
  `auto` int(1) unsigned NOT NULL DEFAULT '0',
  `anneversion` varchar(64) CHARACTER SET utf8mb4 NOT NULL DEFAULT 'None',
  `created` datetime NOT NULL,
  `modified` datetime NOT NULL,
  PRIMARY KEY (`run_id`,`steamid`),
  KEY `idx_timedmap_runs_filter_time` (`map`,`mode`,`difficulty`,`sinum`,`sitime`,`usebuy`,`anneversion`,`time`),
  KEY `idx_timedmap_runs_steamid` (`steamid`,`modified`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
