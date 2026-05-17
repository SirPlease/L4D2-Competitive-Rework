# AnneHappy 动态 AI 难度

## PPM 分档

PPM 从 `l4d_stats` 获取。当前默认使用总积分 / 总游玩分钟数，避免本季度“先记分、后记时长”导致季度 PPM 偏高。等下个完整季度数据可信后，可以打开 `ah_ai_dynamic_use_quarter_stats 1`：每个真人生还者季度样本达到 5 小时时使用季度积分 / 季度游玩分钟数，否则回退总积分 / 总游玩分钟数。

插件调用的是 `l4d_stats.smx` 暴露的 native：

- `l4dstats_GetClientScore(client)`
- `l4dstats_GetClientPlayTime(client)`
- `l4dstats_GetClientQuarterScore(client)`
- `l4dstats_GetClientQuarterPlayTime(client)`

只统计当前在生还者队伍的真人玩家，忽略 Bot 和没有有效游玩时间的数据。最终队伍 PPM 使用所有玩家“采用后的积分总和 / 采用后的分钟总和”。

定档时机：

- 每回合 `round_start` 后先应用简单难度作为保底，然后立即尝试自动定档。
- 如果 `l4d_stats` 数据还没加载完成，会在安全门内按间隔重试。
- 一旦定档成功，本回合锁定该难度，出门后不会再动态变化。
- `player_left_start_area` 只负责锁定兜底状态：如果出门前仍未读到统计数据，本回合保持简单难度。

默认分档：

| 难度 | PPM 条件 | 说明 |
| --- | --- | --- |
| 1 简单 | `< 30.89` | 低压档，降低速度和进攻行为强度 |
| 2 普通 | `30.89 <= PPM < 43.23` | 标准偏低 |
| 3 困难 | `43.23 <= PPM < 63.70` | 标准偏高 |
| 4 专家 | `63.70 <= PPM < 77.57` | 当前 AnneHappy 专家强度 |
| 5 极限 | `>= 77.57` | 参考 `cfg/vote/hard_on.cfg` 的高压 AI/Tank 属性 |

可调 cvar：

插件默认 cvar 配置已生成在：

`cfg/sourcemod/annehappy_dynamic_ai_difficulty.cfg`

| Cvar | 默认值 | 说明 |
| --- | --- | --- |
| `ah_ai_dynamic_enable` | `1` | 是否启用动态难度 |
| `ah_ai_dynamic_check_interval` | `5.0` | 回合定档前，从 `l4d_stats` 重试检查平均 PPM 的间隔 |
| `ah_ai_dynamic_ppm_normal` | `30.89` | 进入普通难度阈值 |
| `ah_ai_dynamic_ppm_hard` | `43.23` | 进入困难难度阈值 |
| `ah_ai_dynamic_ppm_expert` | `63.70` | 进入专家难度阈值 |
| `ah_ai_dynamic_ppm_extreme` | `77.57` | 进入极限难度阈值 |
| `ah_ai_dynamic_threshold_mode` | `1` | 阈值来源：`0=固定 cfg`，`1=读取数据库每日分位阈值` |
| `ah_ai_dynamic_threshold_db_config` | `l4dstats` | 每日阈值表所在数据库配置名，对应 `databases.cfg` |
| `ah_ai_dynamic_threshold_table` | `ai_dynamic_ppm_thresholds` | 每日阈值表名 |
| `ah_ai_dynamic_threshold_max_age` | `172800` | 数据库阈值最大有效秒数；默认 2 天，过期回退固定 cfg |
| `ah_ai_dynamic_fixed_level` | `0` | `0=自动`，`1-5=固定简单/普通/困难/专家/极限` |
| `ah_ai_dynamic_config` | `configs/AnneHappy/dynamic_ai_difficulty.cfg` | 每档难度的特感/Tank cvar 配置文件，相对 `addons/sourcemod` |
| `ah_ai_dynamic_use_quarter_stats` | `0` | 是否启用季度 PPM 优先；当前季度数据失真，默认关闭 |
| `ah_ai_dynamic_quarter_min_minutes` | `300` | 启用季度 PPM 时，玩家季度样本低于该分钟数则回退总积分 PPM |
| `ah_ai_dynamic_announce` | `1` | 调档时聊天提示 |
| `ah_ai_dynamic_debug` | `0` | 输出调试日志 |

命令：

| 命令 | 说明 |
| --- | --- |
| `sm_aippm` | 查看当前积分、时间、PPM、难度 |
| `sm_aidiff <0-5>` | 管理员切换模式；`0=自动`，`1-5=固定难度` |
| `sm_aidiff_reload` | 重新读取配置文件，并把当前难度重新应用一次 |

## 每日分位阈值

推荐流程是网页或 cron 每天凌晨 4 点计算一次 PPM 分位数，然后写入数据库；插件只读取 `id=1` 这一行，不在游戏内跑排行榜大查询。读取失败、数据为空或超过 `ah_ai_dynamic_threshold_max_age` 时，插件回退使用 cfg 里的固定阈值。

分位映射：

| 难度 | 数据库字段 |
| --- | --- |
| 简单/普通分界 | `ppm_p60` |
| 普通/困难分界 | `ppm_p75` |
| 困难/专家分界 | `ppm_p90` |
| 专家/极限分界 | `ppm_p95` |

插件会自动建表，也可以提前建：

```sql
CREATE TABLE IF NOT EXISTS ai_dynamic_ppm_thresholds (
  id TINYINT UNSIGNED NOT NULL DEFAULT 1,
  source VARCHAR(32) NOT NULL DEFAULT 'daily',
  sample_count INT NOT NULL DEFAULT 0,
  ppm_p60 FLOAT NOT NULL DEFAULT 30.89,
  ppm_p75 FLOAT NOT NULL DEFAULT 43.23,
  ppm_p90 FLOAT NOT NULL DEFAULT 63.70,
  ppm_p95 FLOAT NOT NULL DEFAULT 77.57,
  updated_at INT NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

网页/cron 算完后写入：

```sql
INSERT INTO ai_dynamic_ppm_thresholds
  (id, source, sample_count, ppm_p60, ppm_p75, ppm_p90, ppm_p95, updated_at)
VALUES
  (1, 'mixed_5h', 7379, 30.89, 43.23, 63.70, 77.57, UNIX_TIMESTAMP())
ON DUPLICATE KEY UPDATE
  source = VALUES(source),
  sample_count = VALUES(sample_count),
  ppm_p60 = VALUES(ppm_p60),
  ppm_p75 = VALUES(ppm_p75),
  ppm_p90 = VALUES(ppm_p90),
  ppm_p95 = VALUES(ppm_p95),
  updated_at = VALUES(updated_at);
```

## 难度配置文件

每档特感/Tank 属性已经移到：

`addons/sourcemod/configs/AnneHappy/dynamic_ai_difficulty.cfg`

格式为 SourceMod KeyValues：

```text
"AnneHappyDynamicAIDifficulty"
{
    "level1"
    {
        "ai_smoker3_bhop" "1"
        "ai_SmokerBhopSpeed" "70"
    }

    "level2"
    {
        "ai_smoker3_bhop" "1"
        "ai_SmokerBhopSpeed" "90"
    }
}
```

插件定档后只读取对应的 `level1` / `level2` / `level3` / `level4` / `level5` 节点，把里面的键名当作 cvar、值当作 cvar 值应用。不存在的 cvar 会被忽略；开启 `ah_ai_dynamic_debug 1` 后会在日志里提示。

改完配置后可以执行 `sm_aidiff_reload` 热重载当前难度；下一回合也会自动读取最新配置。

## 分档主要改动的属性

插件不修改刷特数量、刷新间隔、章节刷特配置、刷点距离、传送距离或 Nav 桶参数。`l4d_infected_limit`、`versus_special_respawn_interval`、`inf_SpawnDistanceMin` 等仍由当前章节/配置固定控制。

### 特感和 Tank AI 强化

从简单到极限逐步增强，但非极限档尽量保持同一套基础行为，不再用大量开关差异制造难度。

- Tank：所有档都开启 AITank3 连跳和无视野连跳，主要区分停跳距离、连跳加速度、最大速度、空中修正角度。`ai_TankSneakTime` 和旧的 `ai_TankAirAngleRestrict` 不属于当前 `ai_tank3.smx`，已经从配置移除。
- Boomer：所有档都开启连跳和转视角，主要区分连跳速度与转视角帧数；专家保持 15 帧，极限为 10 帧。
- Charger：所有档都开启连跳，主要区分 `ai_ChagrerBhopSpeed`。
- Spitter：所有档都开启连跳，主要区分 `ai_SpitterBhopSpeed`。
- Jockey：所有档都开启连跳，主要区分连跳速度和行为复杂度。`ai_JockeyAllowInterControl` 全档固定为 `0`，抢控目标由 `target_override` 控制。
- Hunter：主要区分基础飞扑空速和低飞角度。简单档垂直角度更大，Hunter 更容易飞高，给玩家更多空爆窗口；越难越低飞。
- Smoker：所有档都开启连跳和无视野连跳，主要区分连跳速度、左右偏角、无视野角度和空中速度修正角度。越难空中修正阈值越小，修正更早介入。

`cfg/vote/hard_on.cfg` 里属于投票/样本或刷点节奏的项目没有加入动态难度：`sm_veterans_*` 不是特感/Tank 行为属性，`inf_TeleportCheckTime` 属于传送检查节奏。

## 五档对比

| 属性组 | 简单 `<30.89` | 普通 `30.89-43.23` | 困难 `43.23-63.70` | 专家 `63.70-77.57` | 极限 `>=77.57` |
| --- | --- | --- | --- | --- | --- |
| 反应时间 | 远距 5.0 / 近距 0.5 | 5.0 / 0.5 | 5.0 / 0.5 | 5.0 / 0.5 | 0.0 / 0.0 |
| Hunter/Jockey 空速 | 700 / 700 | 750 / 750 | 800 / 800 | 850 / 850 | 900 / 900 |
| Hunter 垂直角度 | 12，更容易飞高 | 10 | 8 | 7 | 6 |
| Smoker 连跳 | 开启，速度 70，修正角 70 | 速度 90，修正角 60 | 速度 105，修正角 55 | 速度 120，修正角 50 | 速度 150，修正角 45 |
| Jockey | 速度 50，低骗推 | 速度 60，低复杂度 | 速度 70，中复杂度 | 速度 80，高复杂度 | 速度 150，更远启动和更高骗推 |
| Spitter | 连跳速度 45 | 65 | 85 | 100 | 250 |
| Charger | 连跳速度 45 | 60 | 75 | 90 | 150 |
| Boomer | 速度 70，30 帧转目标 | 95，25 帧 | 125，20 帧 | 150，15 帧 | 250，10 帧 |
| Tank | 停跳 220，最大速 700，修正角 60 | 190 / 800 / 55 | 160 / 900 / 50 | 135 / 1000 / 45 | 100 / 1100 / 45 |

## confogl_plugins.cfg 中 ai 开头插件的 ConVar

### `ai_smoker3.smx`

`ai_smoker3_bhop`, `ai_smoker3_bhop_no_vision`, `ai_SmokerBhopSpeed`, `ai_smoker3_bhop_min_speed`, `ai_smoker3_bhop_max_speed`, `ai_smoker3_bhop_min_dist`, `ai_smoker3_bhop_max_dist`, `ai_smoker3_bhop_side_minang`, `ai_smoker3_bhop_side_maxang`, `_ai_smoker3_bhop_nvis_maxang`, `ai_smoker3_airvec_modify_degree`, `ai_smoker3_airvec_modify_degree_max`, `ai_smoker3_airvec_modify_interval`, `ai_smoker3_imm_pull`, `ai_smoker3_pull_back_vision`, `ai_smoker3_anti_retreat`, `ai_smoker3_move2_newtar_interval`, `ai_smoker3_stop_warn_snd`, `ai_smoker3_plugin_name`, `ai_smoker3_log_level`

### `ai_hunter_2.smx`

`ai_hunter_fast_pounce_distance`, `ai_hunter_vertical_angle`, `ai_hunter_angle_mean`, `ai_hunter_angle_std`, `ai_hunter_straight_pounce_distance`, `ai_hunter_aim_offset`, `ai_hunter_no_sight_pounce_range`, `ai_hunter_back_vision`, `ai_hunter_melee_first`, `ai_hunter_high_pounce`, `ai_hunter_wall_detect_distance`, `ai_hunter_angle_diff`

### `ai_jockey_2.smx`

`ai_JockeyBhopSpeed`, `ai_JockeyStartHopDistance`, `ai_JockeyStumbleRadius`, `ai_JockeySpecialJumpAngle`, `ai_JockeySpecialJumpChance`, `ai_jockeyNoActionChance`, `ai_JockeyAllowInterControl`, `ai_JockeyBackVision`

### `ai_spitter_2.smx`

`ai_SpitterBhop`, `ai_SpitterBhopSpeed`, `ai_SpitterTarget`, `ai_SpitterPinnedPr`, `ai_SpiiterDieAfterSpit`

### `ai_charger_2.smx`

`ai_ChargerBhop`, `ai_ChagrerBhopSpeed`, `ai_ChargerChargeDistance`, `ai_ChargerExtraTargetDistance`, `ai_ChargerAimOffset`, `ai_ChargerMeleeAvoid`, `ai_ChargerMeleeDamage`, `ai_ChargerTarget`, `ai_ChargerChargeHeightDiff`

### `ai_boomer_2.smx`

`ai_BoomerBhop`, `ai_BoomerBhopSpeed`, `ai_BoomerUpVision`, `ai_BoomerTurnVision`, `ai_BoomerForceBile`, `ai_BoomerBileFindRange`, `ai_BoomerTurnInterval`, `ai_BoomerDegreeForceBile`, `ai_BoomerAutoFrame`

### `ai_tank3.smx`

`ai_tank3_enable`, `ai_tank_bhop`, `ai_Tank_StopDistance`, `ai_tank3_bhop_max_dist`, `ai_tank3_bhop_min_speed`, `ai_tank3_bhop_max_speed`, `ai_tank3_bhop_impulse`, `ai_tank3_bhop_no_vision`, `_ai_tank3_bhop_nvis_maxang`, `ai_tank3_airvec_modify_degree`, `ai_tank3_airvec_modify_degree_max`, `ai_tank3_airvec_modify_interval`, `ai_tank3_throw_min_dist`, `ai_tank3_throw_max_dist`, `ai_tank3_climb_anim_rate`, `ai_tank3_low_climb_anim_rate`, `ai_tank3_ladder_climb_rate`, `ai_tank3_rock_target_adjust`, `ai_tank3_back_fist`, `ai_tank3_back_fist_range`, `ai_tank3_back_fist_max_spd`, `ai_tank3_punch_lock_vision`, `ai_tank3_jump_rock`, `ai_tank3_back_fist_window`, `ai_tank3_head_block_enable`, `ai_tank3_head_block_time`, `ai_tank3_head_block_vertical`, `ai_tank3_head_block_horizontal`, `ai_tank3_head_block_ignore_time`, `ai_tank3_head_block_force_rock_time`, `ai_tank3_head_block_force_rock_range`, `ai_tank3_head_block_force_rock_release_h`, `ai_tank3_head_block_force_rock_release_v`, `ai_tank3_plugin_name`, `ai_tank3_log_level`

第 4 档保持当前专家强度；第 5 档参考 `cfg/vote/hard_on.cfg` 作为极限强度，并只调整特感和 Tank 的行为属性。
