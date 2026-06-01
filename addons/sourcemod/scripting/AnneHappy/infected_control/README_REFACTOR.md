# infected_control.sp 重构后说明书

本文档描述 `infected_control.sp` 重构后的源码结构、运行流程、兼容边界、验证方式和后续优化方向。目标是让后续维护时能快速定位模块，也方便继续评估下一轮改进。

## 1. 重构目标

本轮重构遵循以下边界：

- 内部代码标识符统一使用英文。
- 注释保留中文，清理生成式/变更日志式注释。
- 保持现有 CVar 名称，避免破坏已部署配置文件。
- 删除确认无调用的死代码。
- Nav 调试代码默认不进入生产编译，通过 `DEBUG_NAV` 条件编译启用。
- 用 Docker 内的 `spcomp` 环境验证默认编译，另行验证 `DEBUG_NAV=1` 编译。

本轮重构重点是结构拆分和风险清理，不主动改变刷特算法的主行为。

## 2. 当前源码结构

入口文件：

- `infected_control.sp`：插件入口、生命周期、事件绑定、管理命令、native/forward、全局状态声明、SDK 初始化。

模块目录：

- `infected_control/*.inc`：按职责拆分的实现模块。

当前规模：

- `infected_control.sp`：约 618 行。
- include 模块：23 个文件，约 5887 行。

### 2.1 主文件职责

`infected_control.sp` 现在主要保留这些内容：

- `Plugin myinfo`
- `AskPluginLoad2`
- `OnPluginStart`
- `OnPluginEnd`
- `OnMapEnd`
- 可选库状态维护
- 管理命令注册
- 事件 hook
- 全局状态/缓存声明
- include 顺序维护
- `Debug_Print` / `LogMsg`
- `InitSDK_FromGamedata`

刷点核心、波控制、SI 上限、Nav 缓存、Nav 分桶、KV 持久化等逻辑已经移入 include 模块。

### 2.2 include 顺序

主文件当前按依赖顺序 include：

```sourcepawn
#include "infected_control/nav_types.inc"
#include "infected_control/spawn_score_types.inc"
#include "infected_control/utils.inc"
#include "infected_control/config.inc"
#include "infected_control/runtime_state.inc"
#include "infected_control/queue.inc"
#include "infected_control/class_queue.inc"
#include "infected_control/client_state.inc"
#include "infected_control/visibility.inc"
#include "infected_control/anti_baiter.inc"
#include "infected_control/si_cap.inc"
#include "infected_control/spawn_score.inc"
#include "infected_control/path_cache.inc"
#include "infected_control/survivor_flow.inc"
#include "infected_control/spawn_memory.inc"
#include "infected_control/nav_cache.inc"
#include "infected_control/nav_persist.inc"
#include "infected_control/nav_buckets.inc"
#include "infected_control/wave_control.inc"
#include "infected_control/spawn_core.inc"
#include "infected_control/spawn_attempts.inc"
#include "infected_control/teleport_monitor.inc"
```

后续新增模块时需要注意 SourcePawn 没有独立编译单元，include 顺序就是可见性顺序。

## 3. 模块职责

| 文件 | 职责 |
| --- | --- |
| `utils.inc` | 通用常量与工具函数，例如 `SI_COUNT`、`ZC_TANK`、`FLOAT_EULER`、`ClampFloat`、`ClampInt`、`Clamp01`。 |
| `config.inc` | CVar 创建、缓存刷新、权重解析、配置变更 hook。 |
| `runtime_state.inc` | 运行时状态 `State`，包括刷特计时、存活特感、目标生还者、传送计数、跑男状态等。 |
| `queue.inc` | 普通刷特队列和传送队列的基础操作。 |
| `class_queue.inc` | 特感选类、稀缺度优先、死亡 CD、队列补位、上限闸门。 |
| `client_state.inc` | 玩家/特感/生还者状态判断，以及常用距离查询。 |
| `visibility.inc` | 生还者视线检测、trace 过滤、目标是否可见。 |
| `anti_baiter.inc` | 反挂机、跑男检测、提前开波、跑男 forward 触发。 |
| `si_cap.inc` | SI 上限读取、存活数回算、全猎/全牛模式覆盖、比赛状态重置。 |
| `spawn_score_types.inc` | 刷点评分调试结构体定义。 |
| `spawn_score.inc` | 四因子刷点评分：距离、高度、Flow、分散度。 |
| `path_cache.inc` | Nav 路径可达性缓存与清理。 |
| `survivor_flow.inc` | 生还者进度计算、Flow fallback、目标生还者选择。 |
| `spawn_memory.inc` | 最近刷点、Nav 冷却、扇区分散度、低点高度查询。 |
| `nav_types.inc` | `NavArea` methodmap 和 NavArea 原生字段访问封装。 |
| `nav_cache.inc` | NavArea 全量缓存、NavID 到 index 映射、中心点/高度采样。 |
| `nav_persist.inc` | Nav 分桶 KV 缓存加载与保存。 |
| `nav_buckets.inc` | Flow 分桶构建、动态桶窗口、桶扫描顺序、重建命令。 |
| `wave_control.inc` | 刷特波控制、窗口检查、暂停/恢复定时器。 |
| `spawn_core.inc` | NavArea 刷点核心、候选点评估、桶模式和全图模式入口。 |
| `spawn_attempts.inc` | 普通刷出和传送刷出的尝试逻辑、成功后的状态更新。 |
| `teleport_monitor.inc` | 1 秒传送监督 tick，处理超时、跑男快通道、Smoker 技能限制。 |
| `nav_debug.inc` | Nav 调试命令，默认 stub，`DEBUG_NAV` 编译时启用完整实现。 |

## 4. 核心运行流程

### 4.1 插件启动

`OnPluginStart` 的主要顺序：

1. `gCV.Create()` 创建并缓存 CVar。
2. `gQ.Create()` 初始化普通队列和传送队列。
3. `gST.Reset()` 初始化运行时状态。
4. `InitSDK_FromGamedata()` 加载 NavArea SDK/偏移。
5. `BuildNavIdIndexMap()` 构建 NavID 到数组 index 的映射。
6. `BuildNavBuckets()` 加载或构建 Flow 分桶。
7. `RecalcSiCapFromAlive(true)` 初始化 SI 上限和存活数。
8. 初始化 Nav 冷却、最近刷点、路径缓存、死亡 CD。
9. 注册管理命令、事件、native 和 forward。

### 4.2 刷特波控制

常规刷特链路：

```text
Timer_SpawnFirstWave
  -> StartWave
  -> Timer_CheckSpawnWindow
  -> TryNormalSpawnOnce
  -> FindSpawnPosViaNavArea
  -> SpawnCore_EvaluateNavCandidate
```

波控制由 `wave_control.inc` 负责：

- `StartWave()`：刷新 SI 上限、选择目标生还者、补队列、创建窗口检查 timer。
- `Timer_CheckSpawnWindow()`：在窗口内持续尝试刷出，满足数量或超时后结束。
- `Timer_StartNewWave()`：到达下一波间隔后启动新一轮。
- `PauseSpawnTimer()` / `UnpauseSpawnTimer()`：配合 pause 插件记录和恢复倒计时。

### 4.3 选类与队列

选类由 `class_queue.inc` 负责：

- 基于 `gST.siAlive[]` 和 `gST.siCap[]` 计算缺口。
- 使用稀缺度优先策略补队列。
- Respect `inf_EnableSIoption` 位掩码。
- 处理死亡 CD：
  - `inf_DeathCooldownKiller`
  - `inf_DeathCooldownSupport`
  - `inf_DeathCooldown_BypassAfter`
  - `inf_DeathCooldown_Underfill`
- 支援特感解锁逻辑：
  - `inf_support_unlock_killers`
  - `inf_support_unlock_ratio`
  - `inf_support_unlock_grace`

### 4.4 刷点评估

刷点入口在 `spawn_core.inc`：

- `FindSpawnPosViaNavArea(...)`：根据配置决定使用 Flow 分桶还是全图 NavArea 扫描。
- `SpawnCore_EvaluateNavCandidate(...)`：统一评估单个 NavArea 候选点。

候选点主要过滤/评分顺序：

1. NavArea 有效性。
2. Nav 冷却。
3. Nav flags。
4. Flow 进度和 badflow 处理。
5. 与生还者距离环。
6. 最近刷点分散度。
7. 位置采样和卡壳检测。
8. 生还者可视性。
9. Nav 路径可达性。
10. 四因子评分。
11. TopK 或 first-fit 选择。

桶模式和非桶模式现在共用 `SpawnCore_EvaluateNavCandidate`，减少重复逻辑。保留的行为差异是：

- 桶模式允许 mapped badflow 轻度参与评分。
- 非桶模式仍更保守地拒绝 badflow。

### 4.5 Nav 分桶与缓存

Nav 相关模块拆为三层：

- `nav_cache.inc`：内存层，负责 NavArea 数组、NavID 映射、中心点和高度采样。
- `nav_buckets.inc`：算法层，负责 Flow 分桶、动态窗口、桶扫描顺序。
- `nav_persist.inc`：持久化层，负责 KV 缓存读写。

启动时流程：

```text
BuildNavIdIndexMap
  -> EnsureNavAreasCache

BuildNavBuckets
  -> TryLoadBucketsFromCache
  -> 若缓存不可用则扫描 NavArea 构建
  -> SaveBucketsToCache
```

`sm_rebuildnavcache` 会清理当前缓存并重新构建。

### 4.6 传送监督

传送监督入口是 `teleport_monitor.inc` 的 `Timer_TeleportTick`，每秒执行一次。

主要规则：

- 尊重 `inf_TeleportSi`。
- 尊重出生宽限 `inf_TeleportSpawnGrace`。
- 跑男状态下使用更短阈值：
  - `inf_TeleportRunnerFast`
  - `inf_antibait_fast_tp`
- Smoker 技能未就绪时不会传送。
- Smoker 技能未就绪时仍会累计 tick 计数，避免日志/计数停住。
- 达到阈值且不可见时，加入传送队列。

传送刷出链路：

```text
Timer_TeleportTick
  -> TeleportQueue_PushTail
  -> TryTeleportSpawnOnce
  -> FindSpawnPosViaNavArea
```

### 4.7 反挂机与跑男检测

`anti_baiter.inc` 负责：

- 统计团队进度。
- 判断是否有人显著领先。
- 记录跑男 index。
- 触发 `OnDetectRushman` forward。
- 根据压力和最晚开波时间决定是否提前启动刷特波。

对外 forward 保持：

```sourcepawn
forward void OnDetectRushman(int client);
```

对外 native 保持：

```sourcepawn
native float GetNextSpawnTime();
```

## 5. 行为变化与兼容性

### 5.1 保持兼容的部分

- 所有现有 CVar 名称保持不变。
- 管理命令保持：
  - `sm_startspawn`
  - `sm_stopspawn`
  - `sm_rebuildnavcache`
  - `sm_navpeek`
  - `sm_np`
  - `sm_navtest`
  - `sm_nt`
- library 名称保持：
  - `infected_control`
- native 保持：
  - `GetNextSpawnTime`
- forward 保持：
  - `OnDetectRushman`

### 5.2 有意修正的行为

#### `inf_spawn_bucket_ratio` 默认值

`inf_spawn_bucket_ratio` 的默认值从 `50.0` 改为 `0.50`。

原因：

- 该 CVar 的 bounds 是 `0.0 .. 1.0`。
- 原默认值 `50.0` 会被 ConVar bounds 裁剪为 `1.0`。
- 当前语义更像 0 到 1 的比例，因此默认值改为 `0.50`。

注意：

- CVar 名称未改变。
- 已部署 cfg 如果显式写了 `50.0`，仍会被 SourceMod 的 bounds 裁剪为 `1.0`。
- 如果需要兼容“历史上 50 表示 50%”的写法，需要下一轮专门做兼容解析或迁移提示。

#### Nav 调试命令条件编译

`nav_debug.inc` 默认只编译命令 stub：

- `sm_navpeek`
- `sm_np`
- `sm_navtest`
- `sm_nt`

默认模式下执行会提示：

```text
[IC] Nav 调试命令未编译；需要时请用 DEBUG_NAV 重新编译。
```

完整调试功能需要使用 `DEBUG_NAV=1` 编译。

#### Smoker 传送计数修正

Smoker 技能未就绪时以前会导致传送计数/日志节奏异常。现在技能未就绪仍会累计 tick，仅在技能可用后才允许进入传送队列。

#### 固定 8 人数组扩展

若干固定长度为 8 的生还者候选数组已改为 `MAX_SURVIVOR_SLOTS`，避免 8 人以上场景被静默截断。

#### 死代码删除

确认未使用的旧函数 `GetLowestSurvivorFootZ()` 已删除，保留实际使用的 `TryGetLowestSurvivorFootZ(...)`。

## 6. 编译方式

### 6.1 默认生产编译

在仓库根目录执行：

```bash
scripts/spcomp-docker.sh addons/sourcemod/scripting/AnneHappy/infected_control.sp /tmp/infected_control.smx
```

已验证通过。

当前唯一 warning 来自 SourceMod 自带 include：

```text
sourcemod/include/halflife.inc: CreateDialog is marked as deprecated
```

该 warning 不是插件代码引入。

### 6.2 Nav 调试编译

在 `addons/sourcemod/scripting` 目录执行：

```bash
./spcomp AnneHappy/infected_control.sp \
  -iinclude \
  -isourcemod/include \
  -iconfoglcompmod/include \
  -iarchive/include \
  -iarchive/includes \
  -iAnneHappy \
  -ireadyup \
  -iinclude/multicolors \
  -iinclude/ripext \
  DEBUG_NAV=1 \
  -o/tmp/infected_control_debug.smx
```

已验证通过，同样只有外部 deprecated warning。

## 7. 回归检查清单

建议服务器实测时按下面顺序检查：

- 插件能正常加载，`infected_control` library 注册正常。
- `GetNextSpawnTime` native 返回值正常。
- `OnDetectRushman` forward 能在跑男检测触发时回调。
- `sm_startspawn` 能重置刷特时钟并启动刷特。
- `sm_stopspawn` 能停止刷特和清理 timer。
- `sm_rebuildnavcache` 能重建当前地图 Nav 分桶缓存。
- 默认编译下 `sm_navpeek` / `sm_navtest` 给出未编译提示。
- `DEBUG_NAV=1` 编译下 `sm_navpeek` / `sm_navtest` 可正常显示调试信息。
- 普通刷出路径能成功刷出 SI。
- 传送监督能对超时不可见 SI 入队传送。
- Smoker 技能未就绪时不会被强行传送。
- pause / unpause 后刷特倒计时能恢复。
- 全猎模式 `inf_AllHunterMode` 正常覆盖 cap。
- 全牛模式 `inf_AllChargerMode` 正常覆盖 cap，并在插件结束时恢复 Charger CVar。
- Nav 分桶缓存能在换图后正确清理和重建。
- Path cache 不跨地图残留。

## 8. 已知风险与需要确认的问题

### 8.1 历史配置别名

当前代码只保持现有源码内创建的 CVar 名称。需要确认是否有历史 cfg 使用过旧名字，例如：

- `inf_TeleportDistance`
- `inf_AntiBaitMode`

如果这些名字在现服配置里仍存在，但代码不再创建，就需要决定是否补兼容别名、迁移脚本，或明确弃用。

### 8.2 `inf_spawn_bucket_ratio` 历史语义

当前已将默认值修正为 `0.50`。需要确认现服配置是否有人写：

```text
inf_spawn_bucket_ratio 50
```

如果有，实际运行会被 bounds 裁剪为 `1.0`。这可能和管理员心里的“50%”不一致。

### 8.3 SI class 索引仍未彻底统一

当前仍有部分数组使用 0 到 5 存储 1 到 6 的 SI class：

- `gST.siAlive[]`
- `gST.siCap[]`
- `g_LastDeathTime[]`

访问时仍需要 `zc - 1`。

这轮没有改成 `[7]` 且 0 号位闲置，是因为改动面大，容易引入行为回归。后续可以单独做一轮“SI 索引统一”。

### 8.4 `Config` 仍然偏大

`config.inc` 已保留现有 `Config` enum struct，仍承担 CVar 句柄和缓存字段两种职责。后续可以按功能域分组，但这会带来较大命名和访问路径变更。

### 8.5 Nav 调试命令是否要完全隐藏

当前默认生产编译仍注册 `sm_navpeek` / `sm_navtest`，只是执行时提示调试功能未编译。

可选策略：

- 保持现状：命令存在，提示清楚。
- 完全条件注册：生产环境不注册这些命令。

需要按实际管理习惯决定。

### 8.6 Path cache 仍无容量上限

`path_cache.inc` 当前以波/地图清理为主，仍没有 TTL 或最大容量限制。大地图长时间运行时仍可能增长，需要后续观察或加上限。

## 9. 后续优化路线

### Phase A：配置兼容审计

目标：

- 对比现服 cfg 和当前源码 CVar。
- 找出旧名、废弃名、未创建名。
- 决定是否补 alias 或写迁移说明。

收益：

- 降低部署后“配置没生效”的风险。

### Phase B：SI 索引统一

目标：

- 将 SI class 相关数组统一改为 `[7]`。
- 0 号位闲置，1 到 6 直接对应 SI class。
- 删除大部分 `zc - 1`。

风险：

- 涉及选类、死亡 CD、存活统计、cap 计算、刷出成功路径。
- 建议单独做，并配合大量编译和实服回归。

### Phase C：Config 分组

目标：

- 将配置按功能域分组：
  - spawn
  - teleport
  - scoring
  - nav
  - antibait
  - support
- 降低 `Config` 的 god-object 感。

风险：

- 内部访问路径会变化。
- 需要保证 CVar 名称完全不变。

### Phase D：Path cache 容量和 TTL

目标：

- 给路径可达性缓存增加最大容量。
- 给缓存项增加 TTL。
- 保留地图/波级清理。

收益：

- 降低长时间运行时的内存增长风险。

### Phase E：可视性短期缓存

目标：

- 对同一帧或短时间内相同候选点/生还者组合的 trace 结果做缓存。

收益：

- 减少刷点扫描中的 trace ray 次数。

风险：

- 可视性变化快，缓存 TTL 必须很短。

### Phase F：脚本化验证

目标：

- 增加一键编译脚本：
  - 默认生产编译。
  - `DEBUG_NAV=1` 编译。
  - 搜索旧标识符/旧注释标记。

收益：

- 后续改动更容易在提交前自检。

## 10. 审查重点

建议优先确认这些点：

1. `inf_spawn_bucket_ratio` 是否接受从 `50.0` 改为 `0.50` 的默认值修正。
2. Nav 调试命令默认保留 stub 是否符合使用习惯。
3. 是否存在现服历史 cfg 使用了当前代码没有创建的旧 CVar 名称。
4. 下一轮是否优先做 SI 索引统一，还是先做配置兼容审计。
5. 是否需要把 `Config` 分组作为下一轮重构目标，还是先保持稳定观察。

