# infected_control 原版与重构版差异总结

生成时间：2026-05-28  
对比基准：

- 原版：`HEAD:addons/sourcemod/scripting/AnneHappy/infected_control.sp`
- 重构版：当前工作区 `addons/sourcemod/scripting/AnneHappy/infected_control.sp` 与 `addons/sourcemod/scripting/AnneHappy/infected_control/*.inc`
- 编译产物：`addons/sourcemod/plugins/optional/AnneHappy/infected_control.smx`

## 结论先看

这次不是单纯“小改刷特参数”，而是把原来约 `5111` 行的单文件插件拆成主入口 + `24` 个 include 模块。主文件现在约 `620` 行，模块总量约 `6443` 行。重构后的插件保留原本 fdxx NavArea 刷点、Flow 分桶、最大距离兜底、死亡 CD、传送监督、跑男检测等主干能力，同时新增 AI 难度联动策略、重做 anti-baiter、加入若干性能预算和兼容别名。

按你最新校准，默认难度标尺已经改成：

- `4 专家 = 当前/原版基准`
- `5 极限 = 比当前更难`
- `1-3 = 都比当前简单`

刷点距离甜点默认不再被难度强行推远或拉近；每类特感仍使用自己的原始甜点距离，难度只调评分宽度。

## 文件结构差异

### 原版

原版所有主要逻辑都在：

```text
addons/sourcemod/scripting/AnneHappy/infected_control.sp
```

原文件内同时包含：

- 插件生命周期
- CVar 创建/刷新
- 运行时状态
- 队列
- SI 选类
- 波控制
- 传送监督
- NavArea methodmap
- Nav 分桶与 KV 缓存
- 刷点评分
- 刷点扫描
- 路径缓存
- Nav 调试命令

好处是单文件直观；坏处是依赖关系混在一起，任何行为改动都容易碰到几千行上下文。

### 重构版

主文件现在只保留入口和胶水：

```text
addons/sourcemod/scripting/AnneHappy/infected_control.sp
```

新增模块目录：

```text
addons/sourcemod/scripting/AnneHappy/infected_control/
```

模块职责：

| 文件 | 主要职责 |
| --- | --- |
| `utils.inc` | 通用常量与 Clamp/Float 工具 |
| `config.inc` | CVar 创建、缓存、hook、兼容别名 |
| `difficulty_strategy.inc` | AI 难度档位转刷特策略 |
| `runtime_state.inc` | `State` 和 `Queues` 运行状态 |
| `queue.inc` | 普通刷特队列和传送队列基础操作 |
| `class_queue.inc` | SI 选类、死亡 CD、支援特感解锁 |
| `client_state.inc` | 生还/特感状态判断、距离工具 |
| `visibility.inc` | 可视性 trace 和视线过滤 |
| `anti_baiter.inc` | 反蹲点、跑男检测、压力状态机 |
| `si_cap.inc` | SI 上限读取、全猎/全牛覆盖、状态重算 |
| `spawn_score_types.inc` | 刷点评分调试结构 |
| `spawn_score.inc` | 距离/高度/Flow/分散度评分 |
| `path_cache.inc` | Nav 路径可达性缓存 |
| `survivor_flow.inc` | 生还进度、Flow fallback、目标选择 |
| `spawn_memory.inc` | 最近刷点、Nav 冷却、扇区分散 |
| `nav_types.inc` | NavArea methodmap 与 flags |
| `nav_cache.inc` | NavArea 全量缓存、NavID 映射、采样 |
| `nav_persist.inc` | Nav 分桶 KV 缓存读写 |
| `nav_buckets.inc` | Flow 分桶构建、动态桶窗口、扫描顺序 |
| `wave_control.inc` | 波控制、下一波判定、暂停恢复 |
| `spawn_core.inc` | 候选点过滤与评分主入口 |
| `spawn_attempts.inc` | 普通刷出与传送刷出尝试 |
| `teleport_monitor.inc` | 1 秒传送监督 |
| `nav_debug.inc` | Nav 调试命令 |

## 保持不变的对外接口

这些东西仍然保持：

- plugin library：`infected_control`
- native：`GetNextSpawnTime`
- forward：`OnDetectRushman`
- 管理命令：
  - `sm_startspawn`
  - `sm_stopspawn`
  - `sm_rebuildnavcache`
  - `sm_navpeek`
  - `sm_np`
  - `sm_navtest`
  - `sm_nt`
- 核心基础 CVar：
  - `l4d_infected_limit`
  - `versus_special_respawn_interval`
  - `inf_SpawnDistanceMin`
  - `inf_SpawnDistanceMax`
  - `inf_TeleportDistanceMin`
  - `inf_TeleportSi`
  - `inf_TeleportCheckTime`
  - `inf_EnableSIoption`
  - `inf_AllChargerMode`
  - `inf_AllHunterMode`
  - `inf_EnableAutoSpawnTime`
  - `inf_IgnoreIncappedSurvivorSight`
  - `inf_AddDamageToSmoker`

## 行为差异总览

| 模块 | 原版行为 | 重构后行为 |
| --- | --- | --- |
| 文件结构 | 单文件 `infected_control.sp` | 主文件 + include 模块 |
| 波间隔判定 | 基本按固定半间隔思路开始判定 | 由 AI 难度策略表决定，专家等于原版，极限更早，低档更晚 |
| AI 难度联动 | 不读 `ah_ai_dynamic_current_level` | 读取当前 AI 档位，驱动波判定、低存活补波阈值、候选预算、距离评分宽度 |
| 刷点甜点距离 | 按特感类型固定比例 | 默认仍按特感类型固定比例，不按难度整体远/近偏移 |
| 距离评分宽度 | 固定 | 低档更宽容，专家/极限保持基准，避免拖慢刷出 |
| anti-baiter | 原代码没有完整压力状态机 | 新增 Grace/Observe/Pressure/Recover 状态机，识别打完特感后占点等复活 |
| 跑男处理 | 有跑男检测/forward | 保留，并与 anti-baiter 的目标选择整合 |
| 传送监督 | 1 秒 tick，不可见超时传送 | 保留，并支持跑男/anti-bait 快速传送、出生宽限、Smoker 技能未就绪保护 |
| 刷点候选预算 | 固定 TopK 约 `12` | `inf_spawn_candidate_budget` + 难度 bonus，专家/极限默认 `8`，不随高难增加压力 |
| Flow 桶活特限制 | 每个候选点可重复扫描场上 SI | 加短 TTL 计数缓存，减少重复扫描 |
| 帧思考间隔 | 固定 `0.02s` | 空闲 `0.05s`，有刷特/传送工作时 `0.02s` |
| `inf_spawn_bucket_ratio` 默认 | `50.0`，但 bounds 是 `0..1`，实际会裁剪成 `1.0` | 默认改为 `0.50`，语义明确为 50% |
| 旧配置兼容 | 没有 `inf_AntiBaitMode` / `inf_TeleportDistance` | 补了兼容别名，旧 cfg 继续生效 |
| Nav 调试 | 原版调试命令在单文件内完整编译 | 当前 `nav_debug.inc` 默认完整编译，仍可用 |

## AI 难度联动

新增模块：

```text
infected_control/difficulty_strategy.inc
```

读取：

```text
ah_ai_dynamic_current_level
```

如果动态 AI 难度插件没定档或没加载，则使用：

```text
inf_ai_difficulty_fallback_level 3
```

### 默认策略表

| CVar | 默认值 | 意义 |
| --- | --- | --- |
| `inf_ai_difficulty_link` | `1` | 是否启用 AI 难度联动 |
| `inf_ai_difficulty_fallback_level` | `3` | 未定档时使用哪一档 |
| `inf_ai_wave_check_ratio` | `0.90 0.80 0.65 0.50 0.35` | 1-5 档开始判定下一波的时间比例 |
| `inf_ai_wave_floor_ratio` | `1.35 1.25 1.12 1.00 1.00` | 1-5 档普通补波最早时间比例，代码层也钳制不低于设定刷新间隔 |
| `inf_ai_wave_low_si_ratio` | `0.12 0.20 0.27 0.34 0.50` | 存活 SI 低于多少比例时允许补波 |
| `inf_ai_dist_sweet_offset` | `0 0 0 0 0` | 默认不改每类特感的甜点距离 |
| `inf_ai_dist_width_scale` | `1.25 1.15 1.08 1.00 1.00` | 距离评分宽度倍率 |
| `inf_ai_spawn_budget_bonus` | `-3 -2 -1 0 0` | 候选预算按档增减，专家/极限不加预算 |

## 6 特 16 秒对比表

假设：

- `l4d_infected_limit = 6`
- `versus_special_respawn_interval = 16`
- `inf_spawn_candidate_budget = 8`
- `inf_SpawnDistanceMin = 250`
- `inf_SpawnDistanceMax = 1500`
- span = `1250`

### 波节奏与性能预算

| 项目 | 原版/当前专家基准 | 简单 | 普通 | 困难 | 专家 | 极限 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 开始判定时间 | 8.0s | 14.4s | 12.8s | 10.4s | 8.0s | 5.6s |
| 普通补波最早时间 | 16.0s | 21.6s | 20.0s | 17.9s | 16.0s | 16.0s |
| 低存活补波阈值 | 约 2 特 | 0 特 | 1 特 | 1 特 | 2 特 | 3 特 |
| 候选评分预算 | 原版固定约 12；专家当前 8 | 5 | 6 | 7 | 8 | 8 |
| 距离评分宽度倍率 | 1.00 | 1.25 | 1.15 | 1.08 | 1.00 | 1.00 |
| 距离甜点偏移 | 0 | 0 | 0 | 0 | 0 | 0 |

说明：

- “开始判定时间”不是一定马上刷；只是从这个时间点后开始看是否满足补波条件。
- “普通补波最早时间”是常规补波下限。
- anti-baiter 可以在“开始判定时间”之后识别蹲点等刷，但普通补波不低于设定刷新时间。
- 专家档按你的校准等于当前基准；极限更早开始判定，但不靠提前普通补波、加候选预算或缩窄距离宽度来制造压力。

### 特感距离甜点

默认不再按难度强行推远/拉近。每类特感继续用原版比例：

| 特感 | 甜点比例 | 甜点距离 | 原版宽度 | 简单宽度 | 普通宽度 | 困难宽度 | 专家宽度 | 极限宽度 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Boomer | 25% | 562.5 | 275 | 344 | 316 | 297 | 275 | 275 |
| Hunter | 45% | 812.5 | 350 | 438 | 403 | 378 | 350 | 350 |
| Smoker | 60% | 1000 | 375 | 469 | 431 | 405 | 375 | 375 |
| Spitter | 40% | 750 | 312.5 | 391 | 359 | 337.5 | 312.5 | 312.5 |
| Jockey | 35% | 687.5 | 300 | 375 | 345 | 324 | 300 | 300 |
| Charger | 38% | 725 | 325 | 406 | 374 | 351 | 325 | 325 |

含义：

- 低难度不是把特感统一放远，而是让距离评分更宽松，避免“只有很精确的点才高分”。
- 极限不是把所有特感拉脸，也不缩窄距离宽度；它保留专家基准，避免因为候选点更难达标导致刷出变慢。
- 如果以后要微调，优先改每类特感的甜点比例，而不是改全局偏移。

## anti-baiter 新逻辑

新增状态：

```text
Off -> Grace -> Observe -> Pressure -> Recover
```

进入 Pressure 要同时满足：

1. anti-baiter 开启。
2. 不在暂停、Tank、半数以上倒地/死亡、全员被控等保护场景。
3. 过了波开始后的宽限期，默认 `inf_antibait_grace 8.0`。
4. 一段时间没有推进，默认 `inf_antibait_window 12.0` 秒。
5. 进入压力窗口：场上有足够活特，或已经有待刷/待传送队列，或已经到达可判定下一波窗口。
6. 生还是一个互相覆盖的整体队形：硬抱团看 `inf_antibait_cluster_dist 650.0`；软队形还会看整体跨度、平均最近队友距离和是否断成多个小组。

退出或缓和：

- 平均或最高 Flow 进度推进至少 `inf_antibait_progress_pct 2`。
- 或队伍分散到能被各个击破：有人离最近队友太远、整体跨度过大、或队伍断成多个小组。
- 进入 Recover 后等待 `inf_antibait_recover 4.0` 秒，再回到 Observe。

Action：

| CVar | 默认 | 效果 |
| --- | ---: | --- |
| `inf_antibait_action` | `2` | `0=只记录/调试`，`1=限制最晚开波`，`2=再加不可见 SI 快速传送` |
| `inf_antibait_force_after` | `25.0` | Pressure 持续多久后允许请求提前开波 |
| `inf_antibait_fast_tp` | `1.5` | Pressure 下不可见 SI 的快速传送阈值 |
| `inf_antibait_latest_scale` | `1.50` | 简单档最晚开波倍率基准 |
| `inf_antibait_latest_scale_step` | `0.10` | 档位越高，最晚开波倍率越接近基础间隔 |

### 例子

6 特上限，4 名生还在楼梯口抱团等刷：

- 最大队友间距约 300，小于 650。
- 12 秒内平均/最高进度都没涨 2%。
- 场上可能已经没活特，但 `lastSpawnSecs` 到达可判定窗口，或队列里已有待刷特。
- 当前不在 Tank、暂停、全员被控等保护场景。

结果：进入 Pressure。若 `inf_antibait_action 2`，不可见 SI 可以按 `1.5s` 阈值走快速传送重刷，逼生还推进或拉开。

反例 1：生还停了，但 1 人离最近队友超过 `inf_antibait_isolate_dist 950`。

结果：认为队伍已经有可被单抓的人，不进入 Pressure 或从 Pressure 进入 Recover。

反例 2：4 人分成 2+2，两组之间相隔 1200。

结果：即使每组内部靠得近，也会按多个小组处理，认为能被各个击破，不继续 anti-bait 压力。

反例 3：生还抱团，但每隔几秒稳定推进 2%。

结果：更新基线，不进入 Pressure。

反例 4：Tank 在场或半数以上倒地/死亡。

结果：anti-baiter 被保护条件挡住，不加压。

## 跑男逻辑

跑男和 anti-baiter 是两条相关但不同的逻辑：

- 跑男：最高进度玩家领先中位数至少 `inf_antibait_runner_gap_pct 12`，并且 `inf_antibait_runner_near_dist 1200` 内没有队友。
- anti-baiter：队伍停滞，并且仍是互相覆盖的整体站位，且进入活特/待刷/可判定刷新压力窗口。

跑男被识别后：

- 仍会触发 `OnDetectRushman`。
- `ChooseTargetSurvivor()` 会优先选择跑男作为刷点目标。
- 跑男状态下传送监督可以使用 `inf_TeleportRunnerFast 1.5` 的快通道。

## 性能变化

### 已做

| 点 | 原版 | 重构后 |
| --- | --- | --- |
| 帧思考间隔 | 固定 `0.02` | 空闲 `inf_FrameThinkStep 0.05`；有待刷/传送工作时 `inf_FrameThinkStepActive 0.02` |
| 候选评分数量 | 固定 TopK 约 `12` | `inf_spawn_candidate_budget 8` + 难度 bonus；高难不加预算 |
| Flow 桶 SI 计数 | 候选点评估时可能重复扫描活 SI | `inf_BucketCountCacheTTL 0.20` 缓存短时间结果 |
| Path cache | 已有 PathPenalty 缓存 | 保留，按波/地图清理 |
| Nav 分桶缓存 | 已有 KV 缓存 | 保留 |

### 影响

- 专家/极限档当前默认候选评分预算从原版约 `12` 降到 `8`，减少刷点扫描压力。
- 简单/普通/困难进一步降低预算，低压局优先省 CPU。
- 空闲时 `FrameThinkStep` 从 `0.02` 到 `0.05`；有待补波、待刷队列或传送队列时仍用 `0.02`，避免活特感刷得慢。
- 桶计数 TTL 很短，主要减少同一轮候选点重复扫描，不长期缓存战场状态。

## CVar 差异

### 新增 CVar

| CVar | 默认 | 说明 |
| --- | --- | --- |
| `inf_AntiBaitMode` | `1` | 旧配置兼容别名；与 `inf_antibait_enable` 同时为真才启用 |
| `inf_TeleportDistance` | `400.0` | 旧配置兼容别名；若旧值不是默认 400，则优先生效 |
| `inf_FrameThinkStep` | `0.05` | 空闲刷特队列帧思考间隔 |
| `inf_FrameThinkStepActive` | `0.02` | 有待补波/待刷/待传送时的帧思考间隔 |
| `inf_spawn_candidate_budget` | `8` | 单次刷点候选预算 |
| `inf_BucketCountCacheTTL` | `0.20` | Flow 桶活 SI 计数缓存 TTL |
| `inf_ai_difficulty_link` | `1` | 是否联动 AI 难度 |
| `inf_ai_difficulty_fallback_level` | `3` | AI 难度缺失/未定档时策略档 |
| `inf_ai_wave_check_ratio` | `0.90 0.80 0.65 0.50 0.35` | 开始判定下一波比例 |
| `inf_ai_wave_floor_ratio` | `1.35 1.25 1.12 1.00 1.00` | 普通补波最早比例，不低于设定刷新间隔 |
| `inf_ai_wave_low_si_ratio` | `0.12 0.20 0.27 0.34 0.50` | 低存活补波阈值比例 |
| `inf_ai_dist_sweet_offset` | `0 0 0 0 0` | 距离甜点偏移；默认不动 |
| `inf_ai_dist_width_scale` | `1.25 1.15 1.08 1.00 1.00` | 距离评分宽度倍率 |
| `inf_ai_spawn_budget_bonus` | `-3 -2 -1 0 0` | 按难度加减候选预算 |
| `inf_antibait_enable` | `1` | 新 anti-baiter 主开关 |
| `inf_antibait_grace` | `8.0` | 每波后观察宽限 |
| `inf_antibait_window` | `12.0` | 停滞判断窗口 |
| `inf_antibait_progress_pct` | `2` | 认为有推进的 Flow 百分比 |
| `inf_antibait_min_si_ratio` | `0.50` | 进入 Pressure 的活 SI 压力比例 |
| `inf_antibait_force_after` | `25.0` | Pressure 后多久允许提前开波 |
| `inf_antibait_recover` | `4.0` | Recover 持续时间 |
| `inf_antibait_action` | `2` | anti-baiter 行为等级 |
| `inf_antibait_runner_gap_pct` | `12` | 跑男领先中位数阈值 |
| `inf_antibait_runner_near_dist` | `1200.0` | 跑男附近队友距离 |
| `inf_antibait_fast_tp` | `1.5` | Pressure 快速传送阈值 |
| `inf_antibait_latest_scale` | `1.50` | 最晚开波倍率基准 |
| `inf_antibait_latest_scale_step` | `0.10` | 难度越高倍率越低 |
| `inf_antibait_cluster_dist` | `650.0` | 抱团判断距离 |
| `inf_antibait_team_dist` | `1300.0` | 整体跨度超过该值时认为可被拆开攻击 |
| `inf_antibait_pair_dist` | `700.0` | 队形连通/最近队友距离阈值 |
| `inf_antibait_isolate_dist` | `950.0` | 单人离最近队友超过该值时释放 anti-bait 压力 |
| `inf_antibait_debug` | `0` | anti-baiter 调试日志 |

### 默认值有意变更

| CVar | 原版默认 | 重构后默认 | 原因 |
| --- | ---: | ---: | --- |
| `inf_spawn_bucket_ratio` | `50.0` | `0.50` | 该 CVar bounds 是 `0..1`，原默认 50 会被裁剪成 1.0；新默认明确为 50% |

## 刷点核心差异

原版 `FindSpawnPosViaNavArea` 内部同时处理桶模式与非桶模式，候选点评估逻辑有重复。

重构后拆出：

```text
SpawnCore_EvaluateNavCandidate(...)
```

桶模式和非桶模式共用候选过滤/评分流程，减少重复判断。当前主要过滤顺序：

1. Nav 冷却
2. Nav index 合法性
3. Nav flags
4. Flow 异常与 mapped badflow
5. 距离环
6. 最近刷点分散度
7. 真实位置检查
8. 卡壳检测
9. 可视性
10. Path 可达性
11. Flow 桶活 SI 占比
12. 四因子评分
13. 分数下限

评分因子仍是：

- 距离
- 高度
- Flow
- 分散度

新增/保留调试字段：

- `flowBase`
- `flowPenalty`
- `sweet`
- `width`
- `rawBadFlow`

## 传送监督差异

保留 1 秒 tick，但现在逻辑更明确：

- 出生后 `inf_TeleportSpawnGrace 2.5` 秒内不传送。
- Smoker 技能未就绪时跳过传送，但保留 tick 计数和日志节奏。
- 跑男可用 `inf_TeleportRunnerFast 1.5`。
- anti-baiter Pressure 下可用 `inf_antibait_fast_tp 1.5`。
- 真正传送时会更新活 SI 数、失效桶计数缓存、加入传送刷出队列。

## Nav 调试差异

当前 `nav_debug.inc` 仍编译完整 `sm_navpeek` / `sm_navtest` 功能，没有默认 stub 化。

`sm_navtest` 现在可以打印：

- 冷却
- flags
- Flow / mapped Flow
- 距离
- 位置关系
- 分散度
- 卡壳
- 可视性
- Path
- 距离/高度/Flow/分散度评分明细
- 最终能否生成

## 兼容与风险

### 已处理

- 旧配置 `inf_AntiBaitMode` 已补 alias。
- 旧配置 `inf_TeleportDistance` 已补 alias。
- `inf_spawn_bucket_ratio` 默认值修正为 `0.50`。
- 编译产物已更新。

### 仍需实服观察

| 风险点 | 说明 |
| --- | --- |
| 专家档候选预算从 12 到 8 | 降低 CPU，但极端地图可能降低刷点质量；可调 `inf_spawn_candidate_budget` |
| `FrameThinkStep 0.05` / `FrameThinkStepActive 0.02` | 空闲省 CPU，活特工作保持原响应；需观察 idle/active 切换是否符合实服节奏 |
| anti-baiter 阈值 | `cluster_dist 650`、`team_dist 1300`、`pair_dist 700`、`isolate_dist 950`、`window 12` 需要实战校准 |
| `inf_spawn_bucket_ratio 0.50` | 如果过去依赖被裁剪后的 1.0 行为，需要显式设成 `1.0` |
| 旧 cfg 是否还有其他未创建 CVar | 当前只发现并兼容了 `inf_AntiBaitMode` / `inf_TeleportDistance` |

## 回滚/调参建议

如果服务器压力不稳：

```cfg
sm_cvar inf_FrameThinkStep 0.08
sm_cvar inf_FrameThinkStepActive 0.03
sm_cvar inf_spawn_candidate_budget 6
sm_cvar inf_BucketCountCacheTTL 0.30
```

如果刷点质量下降：

```cfg
sm_cvar inf_spawn_candidate_budget 12
sm_cvar inf_FrameThinkStepActive 0.02
```

如果 anti-baiter 太凶：

```cfg
sm_cvar inf_antibait_window 18
sm_cvar inf_antibait_force_after 35
sm_cvar inf_antibait_team_dist 1000
sm_cvar inf_antibait_isolate_dist 800
```

如果 anti-baiter 太软：

```cfg
sm_cvar inf_antibait_window 8
sm_cvar inf_antibait_force_after 15
sm_cvar inf_antibait_cluster_dist 800
sm_cvar inf_antibait_team_dist 1500
```

如果要完全回到专家/当前节奏基准：

```cfg
sm_cvar inf_ai_difficulty_link 0
sm_cvar inf_ai_difficulty_fallback_level 4
```

如果只关 anti-baiter：

```cfg
sm_cvar inf_antibait_enable 0
```

或旧配置：

```cfg
sm_cvar inf_AntiBaitMode 0
```

## 验证记录

编译命令：

```bash
cd addons/sourcemod/scripting
./spcomp AnneHappy/infected_control.sp -iinclude -iAnneHappy -o../plugins/optional/AnneHappy/infected_control.smx
```

结果：

- 编译通过。
- 只有 SourceMod 自带 `halflife.inc` 的 deprecated warning：
  - `CreateDialog is marked as deprecated`
- 产物已写入：
  - `addons/sourcemod/plugins/optional/AnneHappy/infected_control.smx`

## 明早重点看什么

1. 先看“6 特 16 秒对比表”，确认专家档是否符合你认为的当前基准。
2. 再看 anti-baiter 的例子，确认它是否真的针对“抱团等刷”而不是惩罚正常慢推。
3. 看性能变化里的三个旋钮：
   - `inf_FrameThinkStep`
   - `inf_spawn_candidate_budget`
   - `inf_BucketCountCacheTTL`
4. 看风险表，决定实服第一轮是保守上线还是直接按默认跑。
