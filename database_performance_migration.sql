ALTER TABLE chat.chat_log
  ADD INDEX idx_chat_log_date (`date`),
  ALGORITHM=INPLACE,
  LOCK=NONE;

ALTER TABLE l4d2stats.timedmaps
  ADD INDEX idx_timedmaps_filter_time (`anneversion`, `sinum`, `sitime`, `usebuy`, `auto`, `mode`, `time`),
  ADD INDEX idx_timedmaps_filter_players_time (`anneversion`, `sinum`, `sitime`, `usebuy`, `auto`, `mode`, `players`, `time`),
  ALGORITHM=INPLACE,
  LOCK=NONE;

-- MySQL 5.7 cannot apply this generated-column change with ALGORITHM=INPLACE.
-- Run this in a maintenance window, or use an online schema migration tool.
ALTER TABLE l4d2stats.players
  ADD COLUMN totalpoints INT AS (`points` + `points_survivors` + `points_infected` + `points_realism` + `points_survival` + `points_scavenge_survivors` + `points_scavenge_infected` + `points_realism_survivors` + `points_realism_infected` + `points_mutations`) STORED,
  ADD COLUMN totalplaytime INT AS (`playtime` + `playtime_versus` + `playtime_realism` + `playtime_survival` + `playtime_scavenge` + `playtime_realismversus` + `playtime_mutations`) STORED,
  ADD INDEX idx_players_totalpoints (`totalpoints`),
  ADD INDEX idx_players_totalplaytime (`totalplaytime`),
  ALGORITHM=COPY;
