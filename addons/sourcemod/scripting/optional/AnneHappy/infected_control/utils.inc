#if defined _infected_control_utils_included
    #endinput
#endif
#define _infected_control_utils_included

// 通用常量集中在这里，避免各模块各自维护魔法数字。
#define SI_COUNT                  6
#define ZC_TANK                   8
#define MAX_SURVIVOR_SLOTS        MAXPLAYERS + 1
#define FINALE_STAGE_ESCAPE       18
#define DIRECTOR_FALLBACK_TRIES   48
#define MIN_TELEPORT_SECONDS      0.8
#define FLOAT_EULER               2.71828182845904523536
#define AI_DIFFICULTY_LEVELS      5
#define AI_LEVEL_SLOTS            6

stock float FloatMax(float a, float b)
{
    return (a > b) ? a : b;
}

stock float FloatMin(float a, float b)
{
    return (a < b) ? a : b;
}

stock float ClampFloat(float value, float minValue, float maxValue)
{
    if (value < minValue) return minValue;
    if (value > maxValue) return maxValue;
    return value;
}

stock int ClampInt(int value, int minValue, int maxValue)
{
    if (value < minValue) return minValue;
    if (value > maxValue) return maxValue;
    return value;
}

stock float Clamp01(float value)
{
    return ClampFloat(value, 0.0, 1.0);
}
