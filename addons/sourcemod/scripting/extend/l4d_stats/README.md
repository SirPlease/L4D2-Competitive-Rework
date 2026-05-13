# l4d_stats 模块说明

`../l4d_stats.sp` 现在只负责加载 SourceMod 依赖、常量/状态和各业务模块。新增功能时优先放进对应 `.inc`，不要再把逻辑堆回主文件。

## 模块边界

- `constants.inc`：固定常量、数据库表达式、声音资源名。
- `state.inc`：全局状态、ConVar 句柄、计数器和缓存数组。
- `api.inc`：对外 native、forward、Top100 分数缓存。
- `plugin_start.inc`：`OnPluginStart`、ConVar 创建、事件注册、命令注册。
- `admin_menu.inc`：SourceMod 管理菜单和清库入口。
- `lifecycle.inc`：地图启动、玩家连接/断开、ConVar 变化回调。
- `rounds.inc`：回合开始/结束、游戏模式显示名。
- `persistence.inc`：数据库连接、玩家/地图插入、基础查询、持久化更新。
- `timers.inc`：周期更新、状态结束、友伤统计、洗牌投票定时器。
- `events_players.inc`：个人事件，比如击杀、治疗、倒地、友伤、物品使用。
- `events_team.inc`：团队事件，比如过关、团灭、控人、Witch、成就、L4D2 特有事件。
- `commands_menus.inc`：聊天命令、控制台命令、排行榜和地图时间菜单。
- `stats_rules.inc`：计分规则、模式判断、结算、状态重置、感染者/幸存者辅助。
- `output_rank_timing.inc`：聊天输出、地图计时、队伍洗牌工具、MOTD 和 Anne 模式辅助。
- `stats_players.inc`：统一人类玩家/队伍判断。
- `stats_score.inc`：统一按模式选择积分列并给玩家发分。
- `new_player_bonus.inc`：带新人完成关卡奖励。
- `no_buy_bonus.inc`：从 `rpg.sp` 迁移来的不使用B数过关额外积分。
- `score_log.inc`：每次积分加减流水、原因上下文和自动建表。
- `quarter_rank.inc`：季度积分榜、季度切换清分和季度 native 缓存。

## 新增奖励的建议入口

1. 如果只是给某个玩家加分，优先调用 `Stats_AwardClientScore(client, score)`。
2. 如果要按当前模式写入 `players` 表的正确积分列，使用 `Stats_GetPointsColumnForTeam`。
3. 如果奖励需要判断真人/幸存者/感染者，使用 `Stats_IsValidHumanClient`、`Stats_IsSurvivorHuman`、`Stats_IsInfectedHuman`。
4. 新的独立奖励建议单独建一个 `xxx_bonus.inc`，在 `l4d_stats.sp` 的通用工具模块区域 include，并在 `plugin_start.inc` 里创建对应 ConVar。
5. 事件触发点优先放在 `events_players.inc` 或 `events_team.inc`，不要把事件逻辑放进工具模块。
6. 如果新增奖励没有走 `Stats_AwardClientScore`，在调用 `AddScore` 前先调用 `ScoreLog_SetContext("reason", "formula")`，让流水表能显示来源。

## 带新人奖励

默认配置：

```cfg
l4d_stats_newbie_bonus_enable 1
l4d_stats_newbie_bonus_playtime 4320
l4d_stats_newbie_bonus_maxpoints 200000
l4d_stats_newbie_bonus_first_multiplier 1.1
l4d_stats_newbie_bonus_extra_multiplier 0.2
l4d_stats_newbie_bonus_max_multiplier 0.0
```

当前逻辑：累计游玩时间低于阈值且总分低于阈值的幸存者视为新人；默认是游玩时间 `< 4320` 分钟且总分 `< 200000`。新人本身不吃带新倍率，非新人幸存者按新人数量获得倍率。默认 1 名新人 x1.1，2 名 x1.3，3 名 x1.5，倍率计算后对最终分数向上取整。

当前接入的得分入口：安全屋过关、救援关完成、小僵尸定时结算、控救/拉人、倒地拉起、给药丸、给肾上腺素、电击器复活、医疗包治疗、保护队友。

## 不使用B数过关奖励

默认配置：

```cfg
l4d_stats_nobuy_bonus_enable 1
l4d_stats_nobuy_bonus_5si 200
l4d_stats_nobuy_bonus_6si 500
l4d_stats_nobuy_bonus_7si 800
l4d_stats_nobuy_bonus_8si 1100
l4d_stats_nobuy_bonus_9si 1500
l4d_stats_nobuy_bonus_10si 2000
l4d_stats_nobuy_bonus_hardcore_multiplier 1.3
```

当前逻辑：安全屋过关时，如果 RPG 插件存在、该局有效、没有使用B数、当前是 AnneHappy 模式，则给幸存者额外过关积分；高级人机或关闭 tank 连跳时不发。RPG 插件只维护 `INDEX_USEBUY` / `INDEX_VALID` 状态，不再直接写积分表。

## 季度积分榜

默认开启：

```cfg
l4d_stats_quarter_rank_enable 1
```

插件会自动创建 `%sscore_quarter` 表。所有走 `AddScore` 的分数都会同时进入总榜和当前季度榜；季度 key 格式是 `YYYYQ`，例如 `20262` 表示 2026 年第 2 季度。检测到季度切换时，当前季度榜会自动清零并进入新季度。玩家进服提示、排名面板、季度 Top10 和季度排名变化提示都会显示当前季度。

玩家命令：

```cfg
sm_top10q
sm_qtop10
sm_quartertop10
```

对外 native 已加入 `addons/sourcemod/scripting/include/l4dstats.inc`：

```sourcepawn
native int l4dstats_GetClientQuarterScore(int client);
native int l4dstats_GetClientQuarterRank(int client);
native int l4dstats_GetCurrentQuarter();
native int l4dstats_IsQuarterTopPlayer(int client, int ranklimit);
```

## 积分流水

默认开启：

```cfg
l4d_stats_scorelog_enable 1
```

插件连接数据库后会自动创建 `%sscore_log` 表；`database.sql` 里也有默认 `score_log` 结构。每次 `AddScore` 都会写入一条流水，字段包含玩家、地图、模式、难度、队伍、分数变化、变化后的本图分、原因、公式上下文、RPG 局有效状态、是否使用B数、当前新人数量和带新倍率。

常用排查 SQL：

```sql
SELECT created, map, reason, score, score_after, formula
FROM score_log
WHERE steamid = 'STEAM_1:1:xxxx'
ORDER BY id DESC
LIMIT 100;

SELECT steamid, name, reason, COUNT(*) AS times, SUM(score) AS total_score
FROM score_log
WHERE created >= UNIX_TIMESTAMP() - 86400
GROUP BY steamid, name, reason
ORDER BY total_score DESC;
```
