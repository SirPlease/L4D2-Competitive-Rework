#if defined _infected_control_queue_included
    #endinput
#endif
#define _infected_control_queue_included

// 队列的唯一写入口。保留 gST.*QueueSize 字段作为兼容缓存，但每次操作后立即同步。
void Queue_SyncSizes()
{
    gST.spawnQueueSize = (gQ.spawn != null) ? gQ.spawn.Length : 0;
    gST.teleportQueueSize = (gQ.teleport != null) ? gQ.teleport.Length : 0;
}

int SpawnQueue_Length()
{
    return (gQ.spawn != null) ? gQ.spawn.Length : 0;
}

bool SpawnQueue_Peek(int &zc)
{
    if (gQ.spawn == null || gQ.spawn.Length <= 0)
    {
        zc = 0;
        Queue_SyncSizes();
        return false;
    }

    zc = gQ.spawn.Get(0);
    Queue_SyncSizes();
    return true;
}

void SpawnQueue_Push(int zc)
{
    if (gQ.spawn == null)
        gQ.spawn = new ArrayList();

    gQ.spawn.Push(zc);
    Queue_SyncSizes();
}

bool SpawnQueue_DropHead(int &zc)
{
    if (!SpawnQueue_Peek(zc))
        return false;

    gQ.spawn.Erase(0);
    Queue_SyncSizes();
    return true;
}

bool SpawnQueue_RotateHead(int &zc)
{
    if (!SpawnQueue_DropHead(zc))
        return false;

    gQ.spawn.Push(zc);
    Queue_SyncSizes();
    return true;
}

int TeleportQueue_Length()
{
    return (gQ.teleport != null) ? gQ.teleport.Length : 0;
}

bool TeleportQueue_Peek(int &zc)
{
    if (gQ.teleport == null || gQ.teleport.Length <= 0)
    {
        zc = 0;
        Queue_SyncSizes();
        return false;
    }

    zc = gQ.teleport.Get(0);
    Queue_SyncSizes();
    return true;
}

void TeleportQueue_Push(int zc)
{
    if (gQ.teleport == null)
        gQ.teleport = new ArrayList();

    gQ.teleport.Push(zc);
    Queue_SyncSizes();
}

bool TeleportQueue_DropHead(int &zc)
{
    if (!TeleportQueue_Peek(zc))
        return false;

    gQ.teleport.Erase(0);
    Queue_SyncSizes();
    return true;
}
