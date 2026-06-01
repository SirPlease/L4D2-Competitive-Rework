#if defined _infected_control_spawn_score_types_included
    #endinput
#endif
#define _infected_control_spawn_score_types_included

enum SIClass
{
    SI_None    = 0,
    SI_Smoker  = 1,
    SI_Boomer  = 2,
    SI_Hunter  = 3,
    SI_Spitter = 4,
    SI_Jockey  = 5,
    SI_Charger = 6
};

// 单次最终入选刷点的评分快照（只打印最终点）
enum struct SpawnScoreDbg
{
    float total;
    float dist;
    float hght;
    float flow;
    float flowBase;
    float flowPenalty;
    float dispRaw;
    float dispScaled;
    float penK;

    float dminEye;
    float ringEff;
    float slack;
    float sweet;
    float width;

    int candBucket;
    int centerBucket;
    int deltaFlow;
    int sector;
    int areaIdx;
    bool rawBadFlow;

    float pos[3];
}
