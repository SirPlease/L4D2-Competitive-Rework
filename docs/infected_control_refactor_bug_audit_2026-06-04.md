# infected_control 重构后 bug 审计报告（2026-06-04）

## 审查范围

本次重新审查的是重构后的刷特插件：

- `addons/sourcemod/scripting/optional/AnneHappy/infected_control.sp`
- `addons/sourcemod/scripting/optional/AnneHappy/infected_control/*.inc`
- 相关说明文档：`docs/infected_control_refactor_diff_2026-05-29.md`、`docs/infected_control_spawn_timing_audit_2026-06-03.md`

审查重点是刷特生命周期、波控制、队列、特感找位、评分权重、难度联动、anti-baiter、跑男与传送监督。下面按严重度列出。

## 结论

重构后的主流程是清晰的：`StartWave -> OnGameFrame -> MaintainSpawnQueueOnce -> TryNormalSpawnOnce/TryTeleportSpawnOnce -> FindSpawnPosViaNavArea -> DoSpawnAt`。难度 floor、anti-baiter 不能绕过 floor、Nav 分桶高度缓存兜底这些最近修正方向也基本成立。

但当前源码里仍有几个会影响实战刷特的 bug。最关键的是成功刷出后状态计数可能被重复增加，6 特配置下可能只实际刷出约 3 只就被 `totalSI >= limit` 误判卡住。

## Findings

### P1：成功刷出后 `totalSI/siAlive` 可能被重复计数

位置：

- `addons/sourcemod/scripting/optional/AnneHappy/infected_control/spawn_attempts.inc:90-97`
- `addons/sourcemod/scripting/optional/AnneHappy/infected_control/spawn_attempts.inc:183-185`
- `addons/sourcemod/scripting/optional/AnneHappy/infected_control/spawn_attempts.inc:272-273`
- `addons/sourcemod/scripting/optional/AnneHappy/infected_control.sp:551-567`

问题：

`DoSpawnAt()` 调用 `L4D2_SpawnSpecial()` 成功后立刻执行 `RecalcSiCapFromAlive(false)`。如果新特感此时已经在客户端列表里，`RecalcSiCapFromAlive()` 会把它计入 `gST.siAlive[]` 和 `gST.totalSI`。随后普通刷特和传送刷特成功分支又手动执行：

```sourcepawn
gST.siAlive[want - 1]++;
gST.totalSI++;
```

后果：

- `gST.totalSI` 可能比实际场上特感多。
- `OnGameFrame()` 会因为 `gST.totalSI >= gCV.iSiLimit` 提前停止刷特。
- 6 特上限下，最坏体感可能变成实际 3 只左右就被状态误判为 6 只。
- `DifficultyStrategy_IsLowSiPressure()`、anti-baiter 压力窗口、队列补位都会被错误总数影响。

建议：

二选一，保持一个状态来源即可：

- 方案 A：`DoSpawnAt()` 保留 `RecalcSiCapFromAlive(false)`，删除所有成功分支里的手动 `siAlive++ / totalSI++`。
- 方案 B：`DoSpawnAt()` 不做 `RecalcSiCapFromAlive(false)`，由调用方手动维护，并在需要时统一重算。

更稳的是方案 A，因为它以真实场上客户端为准。

### P2：`ResetMatchState()` 未清空 `siAlive[]`，重复调用会累加旧状态

位置：

- `addons/sourcemod/scripting/optional/AnneHappy/infected_control/si_cap.inc:7-27`
- `addons/sourcemod/scripting/optional/AnneHappy/infected_control.sp:342-347`
- `addons/sourcemod/scripting/optional/AnneHappy/infected_control.sp:401`

问题：

`ResetMatchState()` 只清了 `gST.totalSI`，没有像 `RecalcSiCapFromAlive()` 那样先清空 `gST.siAlive[]`：

```sourcepawn
gST.totalSI = 0;
// 缺少：for (int i = 0; i < SI_COUNT; i++) gST.siAlive[i] = 0;
```

后果：

当 `sm_startspawn` 或安全屋重置路径在已有状态后再次调用时，`siAlive[]` 会在旧值基础上继续加。虽然 `StartWave()` 后会重算一次，但中间的 `ReadSiCap()`、强制全猎/全牛模式、调试输出和部分外部 native 读数可能出现错误。

建议：

在 `ResetMatchState()` 开头补齐：

```sourcepawn
for (int i = 0; i < SI_COUNT; i++) gST.siAlive[i] = 0;
```

### P2：传送队列队首达到限类时会堵住整个传送队列

位置：

- `addons/sourcemod/scripting/optional/AnneHappy/infected_control/spawn_attempts.inc:238-242`
- `addons/sourcemod/scripting/optional/AnneHappy/infected_control.sp:559-563`

问题：

`TryTeleportSpawnOnce()` 只看传送队列队首：

```sourcepawn
if (gST.totalSI >= gCV.iSiLimit || HasReachedLimit(want))
    return;
```

当队首类别暂时达到限类时，函数直接返回，不丢弃也不旋转队首。`OnGameFrame()` 发现传送队列非空后又会优先调用传送刷特并 `return`，普通刷特也会被跳过。

后果：

- 一个不可刷的传送队首可以阻塞后面的可刷传送项。
- 普通刷特队列也可能被传送队列优先级挡住。
- 该问题会被 P1 的重复计数放大。

建议：

对传送队列做类似普通队列的处理：

- 总数已满时返回即可。
- 队首类别达到限类时，先 `RecalcSiCapFromAlive(false)` 再判断。
- 仍不可刷时旋转队首或丢弃过期项，避免永久堵塞。

### P2/P3：6t16s 简单档低存活阈值与文档不一致

位置：

- `addons/sourcemod/scripting/optional/AnneHappy/infected_control/difficulty_strategy.inc:39-58`
- `docs/infected_control_refactor_diff_2026-05-29.md`

问题：

文档写 6 特时简单档低存活补波阈值是 `0 特`。但代码逻辑是：

```sourcepawn
int threshold = RoundToFloor(float(gCV.iSiLimit) * ratio);
if (threshold < 1)
    threshold = 1;
```

默认 `inf_ai_wave_low_si_ratio` 简单档为 `0.12`，6 特时 `RoundToFloor(6 * 0.12) = 0`，随后被强制抬到 `1`。

实际 6t16s 阈值：

| 难度 | 低存活比例 | 源码实际阈值 |
| --- | ---: | ---: |
| 1 简单 | 0.12 | 1 特 |
| 2 普通 | 0.20 | 1 特 |
| 3 困难 | 0.27 | 1 特 |
| 4 专家 | 0.34 | 2 特 |
| 5 极限 | 0.50 | 3 特 |

建议：

如果设计目标是简单档必须清到 `0` 才补波，删除或调整 `threshold < 1` 的强制抬高逻辑。如果设计目标是“只要 ratio > 0 就至少 1 特”，更新文档。

### P2/P3：`nb_assault` 的 bypass helper 实际没有 bypass cheat flag

位置：

- `addons/sourcemod/scripting/optional/AnneHappy/infected_control/spawn_attempts.inc:104-114`
- `addons/sourcemod/scripting/optional/AnneHappy/infected_control/spawn_attempts.inc:188`
- `addons/sourcemod/scripting/optional/AnneHappy/infected_control/spawn_attempts.inc:222`

问题：

函数名叫 `BypassAndExecuteCommand`，但实现只是：

```sourcepawn
if (!CheatsOn()) return;
ServerCommand("%s", cmd);
```

这不是 bypass，而是要求 `sv_cheats=1`。项目里其他插件的同名思路会临时移除 `FCVAR_CHEAT`，再用 `FakeClientCommand()` 执行。

后果：

若线上默认 `sv_cheats=0`，刷出成功后不会触发 `nb_assault`，AI 进攻启动可能变慢，影响“刷出来但不压”的体感。

建议：

改为临时清 `FCVAR_CHEAT` 后通过有效生还者执行，或明确删除该调用并确认不需要 `nb_assault`。

### P3：`inf_antibait_debug` 在 `inf_DebugMode=0` 时不会输出

位置：

- `addons/sourcemod/scripting/optional/AnneHappy/infected_control/anti_baiter.inc:68-75`
- `addons/sourcemod/scripting/optional/AnneHappy/infected_control.sp:321-328`

问题：

`AntiBait_Debug()` 允许 `gCV.bAntiBaitDebug` 单独打开，但实际仍调用 `Debug_Print()`。`Debug_Print()` 开头会在 `inf_DebugMode <= 0` 时直接 return。

后果：

设置 `inf_antibait_debug 1` 但不设置 `inf_DebugMode` 时，看不到 anti-baiter 状态转换日志。

建议：

`AntiBait_Debug()` 在 `bAntiBaitDebug` 开启时直接 `LogToFile()`，不要再被 `Debug_Print()` 总开关吞掉。

### P3：生还者进度 fallback 没有在换图/回合重置

位置：

- `addons/sourcemod/scripting/optional/AnneHappy/infected_control/survivor_flow.inc:18-22`
- `addons/sourcemod/scripting/optional/AnneHappy/infected_control/survivor_flow.inc:322-329`

问题：

`g_LastGoodSurPct` 和 `g_LastGoodSurPctTime` 是 `survivor_flow.inc` 内的静态状态，但 `StopAll()`、`OnMapEnd()`、`Event_RoundStart()` 没有重置它们。

后果：

如果新图或新回合开局时所有 flow 暂时获取失败，fallback 可能沿用上一轮/上一图的进度百分比。由于 `GetGameTime()` 通常按地图时间计算，换图后旧时间戳还可能误判为未过期。

建议：

增加 `ResetSurvivorFlowFallback()`，在 round start、map end、StopAll 中清：

```sourcepawn
g_LastGoodSurPct = -1;
g_LastGoodSurPctTime = 0.0;
InvalidateBucketShareCache();
```

### P3：`GetSectorCenter()` 首选目标未检查存活

位置：

- `addons/sourcemod/scripting/optional/AnneHappy/infected_control/spawn_memory.inc:183-188`

问题：

函数首段只判断 `IsValidSurvivor(targetSur)`，没有判断 `IsPlayerAlive(targetSur)`。如果 `gST.targetSurvivor` 已经死亡但还在游戏中，扇区中心会用死亡目标的位置。

后果：

这不会直接导致刷点越界，因为 `FindSpawnPosViaNavArea()` 的 centerBucket、refEyeZ、path 检查另有存活判断；但会影响扇区分散度中心和最近刷点记忆，导致刷点分散偏向错误位置。

建议：

首段改成：

```sourcepawn
if (IsValidSurvivor(targetSur) && IsPlayerAlive(targetSur))
```

### P3：权重“0 值兜底”注释与实现不一致

位置：

- `addons/sourcemod/scripting/optional/AnneHappy/infected_control/config.inc:681-711`

问题：

注释写“CVar 值不足或为 0 时回退到 1.0”，但代码是在解析 CVar 之前先把旧缓存里的 `<=0` 改成 `1.0`，随后又把 CVar 里的 `0` 解析回数组。也就是说显式写 `0` 仍会让权重为 0。

后果：

如果维护者相信注释，以为 `0` 会兜底，实际可能把某个评分因子禁用。

建议：

决定语义后统一：

- 若允许 `0` 禁用权重，修改注释。
- 若不允许 `0`，解析后再做一次 `<=0 -> 1.0`。

### 已修正：评分权重 CVar 描述顺序已对齐源码 enum 顺序

位置：

- `addons/sourcemod/scripting/optional/AnneHappy/infected_control/spawn_score_types.inc:6-14`
- `addons/sourcemod/scripting/optional/AnneHappy/infected_control/config.inc:349-352`

记录：

源码 enum 顺序是：

```text
1 Smoker, 2 Boomer, 3 Hunter, 4 Spitter, 5 Jockey, 6 Charger
```

`Refresh()` 解析权重时按 `i+1` 写入数组，所以实际解析顺序是 `(S,B,H,P,J,C)`。CVar 描述已改为 `(S,B,H,P,J,C)`。

剩余注意：

调 `inf_score_w_*` 时按 Smoker、Boomer、Hunter、Spitter、Jockey、Charger 顺序填写。

## 已核对但未判为 bug 的点

- `CreateTimer(0.1, Timer_StartNewWave)` 本身不是节奏 bug；真正 floor 由 `DifficultyStrategy_CanStartNormalWave()` 控制。
- `AntiBait_ShouldStartWaveByLatest()` 和 `AntiBait_ShouldStartWaveEarly()` 内部都要求 `DifficultyStrategy_CanStartNormalWave()`，因此 Pressure 默认不会绕过普通补波下限。
- Nav cache 读取时新增的 `zMin/zMax` 冗余更新是合理兜底，能防止旧 KV 缺少 `bucket_zrange` 时高度范围失效。
- `PassRealPositionCheck()` 在所有进度获取失败时放行，是为了避免 flow 异常地图卡死刷特；这是取舍，不是 bug。

## 建议修复顺序

1. 先修 P1 重复计数，否则后续所有节奏和上限判断都不可靠。
2. 修 `ResetMatchState()` 清零和传送队列头阻塞。
3. 对齐 6t16s 低存活阈值文档与代码。
4. 再处理 `nb_assault`、anti-bait debug、fallback reset、扇区中心这些体感和诊断问题。
