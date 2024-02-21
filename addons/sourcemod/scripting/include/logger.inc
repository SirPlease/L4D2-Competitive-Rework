/*
 * @Author: 夜羽真白/Sir.P
 * @Date: 2023-05-23 00:03 周二
 * @Type: Left 4 Dead 2 Plugin
 * @Description: 日志记录对象
 * @URL: https://github.com/GlowingTree880/L4D2_LittlePlugins & https://github.com/PencilMario/L4D2-Not0721Here-CoopSvPlugins
 */

/**
 * 使用方法与原版有一定区别：
 * Logger 在 new 时可传入1-2个参数：名称和类型
 * 类型默认为LoggerType_SourcemodLog，可设置为LoggerType_NewLogFile
 * 有5个输出级别：debug/info/warning/error/critical
 * 可以通过设置忽略级别来忽略指定级别以下的log信息,默认为info,即不输出debug log
 * 默认最多32个logger，可以通过修改MAX_LOGGER来增加（？你真用得着这么多？）
 * 
 * 可在 https://github.com/PencilMario/L4D2-Not0721Here-CoopSvPlugins/blob/main/addons/sourcemod/scripting/logger_test.sp 查看示例
 */

#if defined _logger_included
 #endinput
#endif
#define _logger_included

#define MAX_LOGGER 32
#define MAX_LOGGERNAME_LENGTH 64
#define MAX_LOG_LINE 512


enum LoggerType{
    // 保存在log/L********.log，warning以上保存在error_L********.log
    LoggerType_SourcemodLog = 0,
    // 保存在log/[LogObjectData[this.index].LogName].log
    LoggerType_NewLogFile,
};

enum LogType {
    LogType_Debug = 0,
    LogType_Info,
    LogType_Warning,
    LogType_Error,
    LogType_Critical,
    LogType_Size
}

char LogTypeStr[LogType_Size][] = {
    "Debug",
    "Info",
    "Warning",
    "Error",
    "CRITICAL"
}
enum LogSlot {
    Logger_SlotFree = 0,
    Logger_SlotUsing = 1
}
enum struct LogObjectData{
    LoggerType LogObjectType
    LogType Ignore_Level
    char LogName[MAX_LOGGERNAME_LENGTH]
    char PreFix[32]
}

LogSlot LoggerIndex[MAX_LOGGER];
LogObjectData LoggerData[MAX_LOGGER];

methodmap Logger __nullable__
{
    /**
     * Logger 构建函数
     * 
     * @param name 该Logger的文件名，不包含后缀。
     *             只在LoggerType_NewLogFile中有作用
     * @param logtype Logger的记录位置，参见LoggerType
     */
    public Logger(const char[] name, LoggerType logtype = LoggerType_SourcemodLog)
    {   
        Logger r;
        int created = -1;
        for (int i = 0; i < MAX_LOGGER; i++)
        {
            if (LoggerIndex[i] == Logger_SlotFree){
                r = view_as<Logger>(i);
                LoggerIndex[i] = Logger_SlotUsing;
                created = i;
                break;
            }
        }
        if (created == -1) SetFailState("[Logger] 该插件已经无法创建更多的Logger");
        r.LogObjectType = logtype;
        r.SetLogName(name);
        r.IgnoreLevel = LogType_Info;
        r.SetLogPrefix("");
        LogMessage("[Logger] 创建了一个新logger：index: %i name: %s", created, name);
        return r;
    }
    /**
     * 向log目标文件写入一行信息
     * 
     * @param message 写入的信息
     */
    public void lograw(const char[] message, any ...)
    {
        char buffer[MAX_LOG_LINE];
        VFormat(buffer, sizeof(buffer), message, 3);
        if (this.LogObjectType == LoggerType_NewLogFile) this.WritetoLogFileRaw(buffer)
        else LogMessage(buffer);
    }

    /**
     * 如果log文件不存在，创建log并写入message
     * 
     * @note 只对LoggerType_NewLogFile有效
     * @param message 写入的信息
     */
    public void logfirst(const char[] message, any ...)
    {
        char logpath[PLATFORM_MAX_PATH];
        BuildPath(Path_SM, logpath, sizeof(logpath), "logs/%s.log", LoggerData[this.index].LogName);
        if( FileExists(logpath) == true ) return;
        char buffer[MAX_LOG_LINE];
        VFormat(buffer, sizeof(buffer), message, 3);
        if (this.LogObjectType == LoggerType_NewLogFile) this.lograw(buffer);
        else this.warning("[Logger] LoggerType_SourcemodLog类型的Logger对象试图调用logfirst()");
    }
    /**
     * 向log目标文件写入一条debug记录
     *   
     * @note LoggerType_SourcemodLog将不会包括log等级记录
     * @param message 写入的信息
     */
    public void debug(const char[] message, any ...)
    {
        if (view_as<LogType>(this.IgnoreLevel) > view_as<LogType>(LogType_Debug)) return;
        char buffer[MAX_LOG_LINE];
        VFormat(buffer, sizeof(buffer), message, 3);
        if (this.LogObjectType == LoggerType_NewLogFile) this.WritetoLogFile(LogType_Debug, buffer);
        else LogMessage(buffer);
    }
    /**
     * 向log目标文件写入一条info记录
     * 
     * @note LoggerType_SourcemodLog将不会包括log等级记录
     * @param message 写入的信息
     */
    public void info(const char[] message, any ...)
    {
        if (view_as<LogType>(this.IgnoreLevel) > view_as<LogType>(LogType_Info)) return;
        char buffer[MAX_LOG_LINE];
        VFormat(buffer, sizeof(buffer), message, 3);
        if (this.LogObjectType == LoggerType_NewLogFile) this.WritetoLogFile(LogType_Info, buffer)
        else LogMessage(buffer);
    }
    /**
     * 向log目标文件写入一条warning记录并打印到服务器控制台
     * 
     * @note LoggerType_SourcemodLog将不会包括log等级记录
     * @param message 写入的信息
     */
    public void warning(const char[] message, any ...)
    {
        if (view_as<LogType>(this.IgnoreLevel) > view_as<LogType>(LogType_Warning)) return;
        char buffer[MAX_LOG_LINE];
        VFormat(buffer, sizeof(buffer), message, 3);
        PrintToServer("[%s]%s",LogTypeStr[LogType_Warning], buffer);
        if (this.LogObjectType == LoggerType_NewLogFile) this.WritetoLogFile(LogType_Warning, buffer)
        else LogError(buffer);
    }  
    /**
     * 向log目标文件写入一条error记录并打印到服务器控制台
     * 
     * @note LoggerType_SourcemodLog将不会包括log等级记录
     * @param message 写入的信息
     */
    public void error(const char[] message, any ...)
    {
        if (view_as<LogType>(this.IgnoreLevel) > view_as<LogType>(LogType_Error)) return;
        char buffer[MAX_LOG_LINE];
        VFormat(buffer, sizeof(buffer), message, 3);
        PrintToServer("[%s]%s",LogTypeStr[LogType_Error],buffer);
        if (this.LogObjectType == LoggerType_NewLogFile) this.WritetoLogFile(LogType_Error, buffer)
        else LogError(buffer);
    }    
    /**
     * 向log目标文件写入一条critical记录并打印到服务器控制台
     * 
     * @note LoggerType_SourcemodLog将不会包括log等级记录
     * @param message 写入的信息
     */
    public void critical(const char[] message, any ...)
    {
        if (view_as<LogType>(this.IgnoreLevel) > view_as<LogType>(LogType_Critical)) return;
        char buffer[MAX_LOG_LINE];
        VFormat(buffer, sizeof(buffer), message, 3);
        PrintToServer("[%s]%s",LogTypeStr[LogType_Critical],buffer);
        if (this.LogObjectType == LoggerType_NewLogFile) this.WritetoLogFile(LogType_Critical, buffer)
        else LogError(buffer);
    }

    /**
     * 设置当前logger的目标文件
     * 
     * @note 只对LoggerType_NewLogFile有作用
     * @param name 文件名（不包括扩展名
     */

    public void SetLogName(const char[] name){
        Format(LoggerData[this.index].LogName, MAX_LOGGERNAME_LENGTH, "%s", name) 
    }

    /**
     * 删除log文件
     * 
     * @note 只对LoggerType_NewLogFile有作用
     * @return 如果成功则为 true，如果失败或文件未立即删除或logger类型不正确则为 false。
     */
    public bool DelLogFile(){
        if (this.LogObjectType != LoggerType_NewLogFile) return false;
        char logpath[PLATFORM_MAX_PATH];
        BuildPath(Path_SM, logpath, sizeof(logpath), "logs/%s.log", LoggerData[this.index].LogName);
        return DeleteFile(logpath);
    }
    /** 
     * 设置每次记录时的前缀
     * 
     * @param prefix 前缀
     */
    public void SetLogPrefix(const char[] prefix){
        Format(LoggerData[this.index].PreFix, MAX_LOGGERNAME_LENGTH, "%s", prefix) 
    }

    // logger对象的数据索引
    property int index{
        public get() { return view_as<int>(this); }
    }

    // 忽略等级，低于该级别将不会处理
    property LogType IgnoreLevel
    {
        public get() { return LoggerData[this.index].Ignore_Level;}
        public set(LogType value) { LoggerData[this.index].Ignore_Level = value;}
    }

    // log文件的大小(byte) 只对LoggerType_NewLogFile有效
    property int FileSize{
        public get() {
            if (this.LogObjectType == LoggerType_NewLogFile){
                char logpath[PLATFORM_MAX_PATH];
                BuildPath(Path_SM, logpath, sizeof(logpath), "logs/%s.log", LoggerData[this.index].LogName);
                return FileSize(logpath);
            }
            return -1;
        }
    }

    // 保存位置
    property LoggerType LogObjectType
    {
        public get() { return LoggerData[this.index].LogObjectType;}
        public set(LoggerType value) { LoggerData[this.index].LogObjectType = value;}
    }
    
    

    public void WritetoLogFile(LogType logtype, const char[] message)
    {
        char logpath[PLATFORM_MAX_PATH];
        //char buffer[MAX_LOG_LINE];
        BuildPath(Path_SM, logpath, sizeof(logpath), "logs/%s.log", LoggerData[this.index].LogName);
        Handle file = OpenFile(logpath, "at");

        if (file == null) {
            PrintToServer("[logger] 无法打开文件：%s", logpath);
            LogError("[logger] 无法打开文件：%s", logpath);
            return;
        }

        char time[64];
        FormatTime(time, sizeof(time), "%Y-%m-%d %H:%M:%S", GetTime());
        WriteFileLine(file, "[%s] [%s]: %s%s", time, LogTypeStr[logtype], LoggerData[this.index].PreFix, message);
        CloseHandle(file);
    }

    public void WritetoLogFileRaw(const char[] message)
    {
        char logpath[PLATFORM_MAX_PATH];
        BuildPath(Path_SM, logpath, sizeof(logpath), "logs/%s.log", LoggerData[this.index].LogName);
        Handle file = OpenFile(logpath, "at");

        if (file == null) {
            PrintToServer("[logger] 无法打开文件：%s", logpath);
            LogError("[logger] 无法打开文件：%s", logpath);
            return;
        }

        WriteFileLine(file, "%s", message);
        CloseHandle(file);
    }
}