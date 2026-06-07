#if defined _infected_control_difficulty_strategy_included
    #endinput
#endif
#define _infected_control_difficulty_strategy_included

// AI 难度插件只负责定档并发布 ah_ai_dynamic_current_level。
// 刷特插件在这里把 1..5 档转换成“波节奏 / 刷点甜区 / 性能预算”的策略参数。

int DifficultyStrategy_GetLevel()
{
    int level = 0;

    if (gCV.AiDifficultyLevel == null)
        gCV.AiDifficultyLevel = FindConVar("ah_ai_dynamic_current_level");

    if (gCV.bAiDifficultyLink && gCV.AiDifficultyLevel != null)
        level = gCV.AiDifficultyLevel.IntValue;

    if (level <= 0)
        level = gCV.iAiDifficultyFallbackLevel;

    return ClampInt(level, 1, AI_DIFFICULTY_LEVELS);
}

float DifficultyStrategy_GetWaveCheckDelay()
{
    int level = DifficultyStrategy_GetLevel();
    float delay = gCV.fAiWaveCheckTime[level];
    if (gCV.fSiInterval <= 1.0)
        return FloatMax(0.0, gCV.fSiInterval);

    return ClampFloat(delay, 1.0, gCV.fSiInterval);
}

stock float DifficultyStrategy_GetWaveFloorDelay()
{
    int level = DifficultyStrategy_GetLevel();
    float delay = gCV.fSiInterval * gCV.fAiWaveFloorRatio[level];
    return FloatMax(gCV.fSiInterval, delay);
}

stock int DifficultyStrategy_GetLowSiThreshold()
{
    int level = DifficultyStrategy_GetLevel();
    float ratio = gCV.fAiWaveLowSiRatio[level];
    if (ratio <= 0.0 || gCV.iSiLimit <= 0)
        return 0;

    int threshold = RoundToFloor(float(gCV.iSiLimit) * ratio);
    if (threshold < 1)
        threshold = 1;
    if (threshold > gCV.iSiLimit)
        threshold = gCV.iSiLimit;
    return threshold;
}

stock bool DifficultyStrategy_IsLowSiPressure()
{
    int threshold = DifficultyStrategy_GetLowSiThreshold();
    return threshold > 0 && gST.totalSI <= threshold;
}

float DifficultyStrategy_GetDistSweetOffset()
{
    return gCV.fAiDistSweetOffset[DifficultyStrategy_GetLevel()];
}

float DifficultyStrategy_GetDistWidthScale()
{
    return gCV.fAiDistWidthScale[DifficultyStrategy_GetLevel()];
}

int DifficultyStrategy_GetCandidateBudget()
{
    int level = DifficultyStrategy_GetLevel();
    int budget = gCV.iSpawnCandidateBudget + RoundToNearest(gCV.fAiSpawnBudgetBonus[level]);
    return ClampInt(budget, 1, 24);
}

bool DifficultyStrategy_CanEvaluateWave()
{
    return float(gST.lastSpawnSecs) >= DifficultyStrategy_GetWaveCheckDelay();
}

float DifficultyStrategy_GetConfiguredWaveDelay()
{
    return gCV.fSiInterval;
}

bool DifficultyStrategy_CanStartConfiguredWave()
{
    return float(gST.lastSpawnSecs) >= DifficultyStrategy_GetConfiguredWaveDelay();
}

stock bool DifficultyStrategy_CanStartNormalWave()
{
    return float(gST.lastSpawnSecs) >= DifficultyStrategy_GetWaveFloorDelay();
}
