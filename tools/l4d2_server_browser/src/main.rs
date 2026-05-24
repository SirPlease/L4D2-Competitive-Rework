#![cfg_attr(
    all(target_os = "windows", not(debug_assertions)),
    windows_subsystem = "windows"
)]

use clap::{Parser, ValueEnum};
use eframe::egui;
use regex::Regex;
use reqwest::blocking::Client;
use serde::{Deserialize, Serialize};
use std::collections::{BTreeMap, BTreeSet, HashMap, HashSet, VecDeque};
use std::env;
use std::fs;
use std::io::{self, Read, Write};
use std::net::{Ipv4Addr, SocketAddr, SocketAddrV4, TcpStream, ToSocketAddrs, UdpSocket};
use std::path::{Path, PathBuf};
use std::sync::{
    mpsc::{self, Receiver, Sender},
    Arc, Mutex,
};
use std::thread;
use std::time::{Duration, Instant};

const DEFAULT_MASTER: &str = "hl2master.steampowered.com:27011";
const DEFAULT_FILTER: &str = "\\appid\\550";
const DEFAULT_MASTER_GROUP: &str = "Steam Master";
const DEFAULT_CONFIG_FILE: &str = "l4d2-browser.toml";
const USER_AGENT: &str = "l4d2-server-browser/0.4";
const UPDATE_REPO: &str = "fantasylidong/CompetitiveWithAnne";
const UPDATE_TAG_PREFIX: &str = "l4d2-browser-v";
const DEFAULT_API_BASE_URL: &str = "https://anne.trygek.com";

fn main() {
    if let Err(err) = run() {
        eprintln!("error: {err}");
        std::process::exit(1);
    }
}

fn run() -> Result<(), String> {
    let open_gui_by_default = env::args_os().len() == 1;
    let cli = Cli::parse();
    if cli.gui || open_gui_by_default {
        let config_path = cli.config.clone().unwrap_or_else(default_gui_config_path);
        return start_gui(cli, config_path);
    }

    let config = load_config(cli.config.as_ref())?.unwrap_or_default();
    let (settings, manual_groups, subscriptions) = build_runtime(&cli, config)?;
    let rows = load_server_rows(&settings, &manual_groups, &subscriptions)?;

    if settings.json {
        print_json(&rows)?;
    } else {
        print_table(&rows);
    }

    Ok(())
}

fn default_gui_config_path() -> PathBuf {
    #[cfg(target_os = "windows")]
    {
        if let Some(appdata) = env::var_os("APPDATA") {
            return PathBuf::from(appdata)
                .join("L4D2 Server Browser")
                .join(DEFAULT_CONFIG_FILE);
        }
        if let Some(profile) = env::var_os("USERPROFILE") {
            return PathBuf::from(profile)
                .join("AppData")
                .join("Roaming")
                .join("L4D2 Server Browser")
                .join(DEFAULT_CONFIG_FILE);
        }
    }

    #[cfg(target_os = "macos")]
    {
        if let Some(home) = env::var_os("HOME") {
            return PathBuf::from(home)
                .join("Library")
                .join("Application Support")
                .join("L4D2 Server Browser")
                .join(DEFAULT_CONFIG_FILE);
        }
    }

    #[cfg(all(unix, not(target_os = "macos")))]
    {
        if let Some(xdg_config_home) = env::var_os("XDG_CONFIG_HOME") {
            return PathBuf::from(xdg_config_home)
                .join("l4d2-server-browser")
                .join(DEFAULT_CONFIG_FILE);
        }
        if let Some(home) = env::var_os("HOME") {
            return PathBuf::from(home)
                .join(".config")
                .join("l4d2-server-browser")
                .join(DEFAULT_CONFIG_FILE);
        }
    }

    PathBuf::from(DEFAULT_CONFIG_FILE)
}

#[derive(Parser, Debug, Clone)]
#[command(name = "l4d2-server-browser")]
#[command(about = "Left 4 Dead 2 server browser with groups and SourceBans subscriptions.")]
struct Cli {
    #[arg(long)]
    config: Option<PathBuf>,

    #[arg(long)]
    gui: bool,

    #[arg(long)]
    master: Option<String>,

    #[arg(long)]
    master_group: Option<String>,

    #[arg(long)]
    region: Option<String>,

    #[arg(long)]
    filter: Option<String>,

    #[arg(long)]
    extra_filter: Vec<String>,

    #[arg(long)]
    limit: Option<usize>,

    #[arg(long)]
    jobs: Option<usize>,

    #[arg(long)]
    master_timeout_ms: Option<u64>,

    #[arg(long)]
    server_timeout_ms: Option<u64>,

    #[arg(long)]
    http_timeout_ms: Option<u64>,

    #[arg(long, value_enum)]
    sort: Option<SortKey>,

    #[arg(long)]
    min_players: Option<u8>,

    #[arg(long)]
    name: Option<String>,

    #[arg(long)]
    map: Option<String>,

    #[arg(long)]
    only_group: Option<String>,

    #[arg(long)]
    group: Vec<String>,

    #[arg(long)]
    sourcebans: Vec<String>,

    #[arg(long)]
    sourcebans_url: Vec<String>,

    #[arg(long)]
    no_master: bool,

    #[arg(long)]
    no_info: bool,

    #[arg(long)]
    json: bool,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, ValueEnum)]
enum SortKey {
    Players,
    Ping,
    Name,
    Map,
    Address,
    Group,
}

#[derive(Debug, Clone)]
struct RuntimeSettings {
    master_enabled: bool,
    master: String,
    master_group: String,
    region: u8,
    filter: String,
    limit: usize,
    jobs: usize,
    master_timeout: Duration,
    server_timeout: Duration,
    http_timeout: Duration,
    sort: SortKey,
    min_players: Option<u8>,
    name_filter: Option<String>,
    map_filter: Option<String>,
    group_filter: Option<String>,
    no_info: bool,
    json: bool,
}

impl Default for RuntimeSettings {
    fn default() -> Self {
        Self {
            master_enabled: true,
            master: DEFAULT_MASTER.to_owned(),
            master_group: DEFAULT_MASTER_GROUP.to_owned(),
            region: 0xFF,
            filter: DEFAULT_FILTER.to_owned(),
            limit: 100,
            jobs: 32,
            master_timeout: Duration::from_millis(2500),
            server_timeout: Duration::from_millis(800),
            http_timeout: Duration::from_millis(10_000),
            sort: SortKey::Players,
            min_players: None,
            name_filter: None,
            map_filter: None,
            group_filter: None,
            no_info: false,
            json: false,
        }
    }
}

impl RuntimeSettings {
    fn apply_file_master(&mut self, master: Option<FileMaster>) -> Result<(), String> {
        let Some(master) = master else {
            return Ok(());
        };

        if let Some(enabled) = master.enabled {
            self.master_enabled = enabled;
        }
        if let Some(address) = master.address {
            self.master = non_empty(address, "master.address")?;
        }
        if let Some(group) = master.group {
            self.master_group = non_empty(group, "master.group")?;
        }
        if let Some(region) = master.region {
            self.region = parse_region(&region)?;
        }
        if let Some(filter) = master.filter {
            self.filter = filter;
        }
        for extra in master.extra_filter {
            self.filter.push_str(&extra);
        }
        if let Some(limit) = master.limit {
            self.limit = positive(limit, "master.limit")?;
        }

        Ok(())
    }

    fn apply_cli(&mut self, cli: &Cli) -> Result<(), String> {
        if cli.no_master {
            self.master_enabled = false;
        }
        if let Some(master) = &cli.master {
            self.master = non_empty(master.clone(), "--master")?;
        }
        if let Some(group) = &cli.master_group {
            self.master_group = non_empty(group.clone(), "--master-group")?;
        }
        if let Some(region) = &cli.region {
            self.region = parse_region(region)?;
        }
        if let Some(filter) = &cli.filter {
            self.filter = filter.clone();
        }
        for extra in &cli.extra_filter {
            self.filter.push_str(extra);
        }
        if let Some(limit) = cli.limit {
            self.limit = positive(limit, "--limit")?;
        }
        if let Some(jobs) = cli.jobs {
            self.jobs = positive(jobs, "--jobs")?;
        }
        if let Some(ms) = cli.master_timeout_ms {
            self.master_timeout = Duration::from_millis(positive(ms, "--master-timeout-ms")?);
        }
        if let Some(ms) = cli.server_timeout_ms {
            self.server_timeout = Duration::from_millis(positive(ms, "--server-timeout-ms")?);
        }
        if let Some(ms) = cli.http_timeout_ms {
            self.http_timeout = Duration::from_millis(positive(ms, "--http-timeout-ms")?);
        }
        if let Some(sort) = cli.sort {
            self.sort = sort;
        }
        self.min_players = cli.min_players;
        self.name_filter = cli.name.as_ref().map(|value| value.to_lowercase());
        self.map_filter = cli.map.as_ref().map(|value| value.to_lowercase());
        self.group_filter = cli.only_group.as_ref().map(|value| value.to_lowercase());
        self.no_info = cli.no_info;
        self.json = cli.json;

        Ok(())
    }
}

fn build_runtime(
    cli: &Cli,
    config: BrowserConfig,
) -> Result<
    (
        RuntimeSettings,
        Vec<ManualGroup>,
        Vec<SourceBansSubscription>,
    ),
    String,
> {
    let mut settings = RuntimeSettings::default();
    let mut manual_groups = Vec::new();
    let mut subscriptions = Vec::new();

    settings.apply_file_master(config.master)?;
    manual_groups.extend(
        config
            .groups
            .into_iter()
            .map(ManualGroup::try_from)
            .collect::<Result<Vec<_>, _>>()?,
    );
    subscriptions.extend(
        config
            .sourcebans
            .into_iter()
            .map(SourceBansSubscription::try_from)
            .collect::<Result<Vec<_>, _>>()?,
    );

    settings.apply_cli(cli)?;
    manual_groups.extend(
        cli.group
            .iter()
            .map(|value| parse_cli_group(value))
            .collect::<Result<Vec<_>, _>>()?,
    );
    subscriptions.extend(
        cli.sourcebans
            .iter()
            .map(|value| parse_cli_subscription(value))
            .collect::<Result<Vec<_>, _>>()?,
    );
    subscriptions.extend(cli.sourcebans_url.iter().map(|url| SourceBansSubscription {
        name: sourcebans_group_name(url),
        url: url.to_owned(),
    }));

    Ok((settings, manual_groups, subscriptions))
}

fn load_server_rows(
    settings: &RuntimeSettings,
    manual_groups: &[ManualGroup],
    subscriptions: &[SourceBansSubscription],
) -> Result<Vec<ServerRow>, String> {
    let registry = collect_sources(settings, manual_groups, subscriptions)?;
    if registry.is_empty() {
        return Err("no server addresses found from master, groups, or subscriptions".to_owned());
    }

    let endpoints: Vec<_> = registry
        .into_values()
        .map(|entry| Endpoint {
            display: entry.display,
            socket: entry.socket,
            groups: entry.groups.into_iter().collect(),
        })
        .collect();

    let mut rows = if settings.no_info {
        endpoints
            .into_iter()
            .map(|endpoint| ServerRow {
                endpoint,
                info: None,
                ping: None,
                error: None,
            })
            .collect()
    } else {
        query_servers(endpoints, settings.server_timeout, settings.jobs)
    };

    rows = apply_filters(rows, settings);
    sort_rows(&mut rows, settings.sort);
    Ok(rows)
}

#[derive(Debug, Clone, Deserialize, Serialize, Default)]
struct BrowserConfig {
    #[serde(default)]
    gui: GuiConfig,
    #[serde(default)]
    updater: UpdaterConfig,
    #[serde(default)]
    api: ApiConfig,
    #[serde(default)]
    master: Option<FileMaster>,
    #[serde(default)]
    groups: Vec<FileGroup>,
    #[serde(default)]
    sourcebans: Vec<FileSourceBans>,
}

#[derive(Debug, Clone, Deserialize, Serialize, Default)]
struct GuiConfig {
    #[serde(default)]
    language: GuiLanguage,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
struct ApiConfig {
    #[serde(default = "default_api_base_url")]
    base_url: String,
    #[serde(default)]
    token: Option<String>,
}

impl Default for ApiConfig {
    fn default() -> Self {
        Self {
            base_url: default_api_base_url(),
            token: None,
        }
    }
}

fn default_api_base_url() -> String {
    DEFAULT_API_BASE_URL.to_owned()
}

#[derive(Debug, Clone, Deserialize, Serialize)]
struct UpdaterConfig {
    #[serde(default = "default_update_auto_check")]
    auto_check: bool,
}

impl Default for UpdaterConfig {
    fn default() -> Self {
        Self {
            auto_check: default_update_auto_check(),
        }
    }
}

fn default_update_auto_check() -> bool {
    true
}

#[derive(Debug, Clone, Copy, Deserialize, Serialize, PartialEq, Eq)]
enum GuiLanguage {
    #[serde(rename = "zh-CN", alias = "zh-cn", alias = "zh")]
    ZhCn,
    #[serde(rename = "en-US", alias = "en-us", alias = "en")]
    EnUs,
}

impl Default for GuiLanguage {
    fn default() -> Self {
        Self::ZhCn
    }
}

impl GuiLanguage {
    const ALL: [Self; 2] = [Self::ZhCn, Self::EnUs];

    fn display_name(self) -> &'static str {
        match self {
            Self::ZhCn => "简体中文",
            Self::EnUs => "English",
        }
    }

    fn text(self, key: TextKey) -> &'static str {
        match self {
            Self::ZhCn => match key {
                TextKey::AppTitle => "电信服刷服器",
                TextKey::RefreshServers => "刷新服务器",
                TextKey::Language => "语言",
                TextKey::AddServer => "添加服务器",
                TextKey::Group => "分组",
                TextKey::ServerAddress => "服务器地址",
                TextKey::SaveServer => "保存服务器",
                TextKey::SourceBansSubscription => "SourceBans 订阅",
                TextKey::SubscriptionName => "订阅名称",
                TextKey::PageUrl => "页面 URL",
                TextKey::SaveSubscription => "保存订阅",
                TextKey::Rcon => "RCON",
                TextKey::RconPassword => "RCON 密码",
                TextKey::Command => "命令",
                TextKey::RunCommand => "执行命令",
                TextKey::CvarRules => "CVAR / Rules",
                TextKey::OptionalRconPassword => "RCON 密码，可空",
                TextKey::CvarNamesHelp => "CVAR 名称，逗号分隔；公开 rules 可留空",
                TextKey::ServerList => "服务器列表",
                TextKey::HeaderGroup => "分组",
                TextKey::HeaderAddress => "地址",
                TextKey::HeaderPing => "延迟",
                TextKey::HeaderPlayers => "人数",
                TextKey::HeaderMap => "地图",
                TextKey::HeaderVac => "VAC",
                TextKey::HeaderNameOrError => "服务器名 / 错误",
                TextKey::WaitingRefresh => "等待刷新",
                TextKey::Querying => "查询中...",
                TextKey::SavingServer => "保存服务器中...",
                TextKey::SavingSubscription => "保存订阅中...",
                TextKey::RunningCommand => "执行中...",
                TextKey::Reading => "读取中...",
                TextKey::ServerSaved => "服务器已保存",
                TextKey::SubscriptionSaved => "SourceBans 订阅已保存",
                TextKey::LanguageSaved => "语言设置已保存",
                TextKey::NotQueried => "未查询",
                TextKey::ManualServerList => "已保存服务器",
                TextKey::SubscriptionList => "已保存订阅",
                TextKey::NewSubscription => "新建订阅",
                TextKey::UpdateSubscription => "更新订阅",
                TextKey::DeleteSubscription => "删除订阅",
                TextKey::SubscriptionDeleted => "SourceBans 订阅已删除",
                TextKey::SelectedServer => "已选择服务器",
                TextKey::NoServerSelected => "未选择服务器",
                TextKey::RefreshRules => "刷新 Rules",
                TextKey::CheckUpdates => "检查更新",
                TextKey::CheckingUpdates => "正在检查更新...",
                TextKey::OpenDownloadPage => "打开下载页",
                TextKey::AutoUpdate => "自动检查更新",
                TextKey::CurrentVersion => "当前版本",
                TextKey::PlayerList => "玩家列表",
                TextKey::RefreshPlayers => "刷新玩家",
                TextKey::NoPlayers => "没有公开玩家数据",
                TextKey::FilterEmpty => "空房",
                TextKey::FilterHasPlayers => "有人",
                TextKey::FilterHideTimeout => "隐藏超时",
                TextKey::GlobalPlayersTab => "全服在线玩家",
                TextKey::BroadcastTab => "全服消息",
                TextKey::SettingsTab => "首选项",
                TextKey::ActivePlayers => "活动玩家",
                TextKey::SearchPlaceholder => "实时过滤服务器（名称/地图/分组）...",
                TextKey::TotalServers => "总服务器",
                TextKey::ConnectGame => "一键连接",
                TextKey::CvarSearchPlaceholder => "搜索 CVAR / 规则变量名...",
                TextKey::GlobalPlayerSearchPlaceholder => "搜索在线玩家昵称...",
                TextKey::ApiBaseUrl => "AnneWeb API 地址",
                TextKey::SteamLogin => "Steam 登录",
                TextKey::Logout => "退出登录",
                TextKey::BroadcastMessage => "全服消息内容",
                TextKey::SendBroadcast => "发送全服消息",
            },
            Self::EnUs => match key {
                TextKey::AppTitle => "Telecom Server Browser",
                TextKey::RefreshServers => "Refresh servers",
                TextKey::Language => "Language",
                TextKey::AddServer => "Add server",
                TextKey::Group => "Group",
                TextKey::ServerAddress => "Server address",
                TextKey::SaveServer => "Save server",
                TextKey::SourceBansSubscription => "SourceBans subscription",
                TextKey::SubscriptionName => "Subscription name",
                TextKey::PageUrl => "Page URL",
                TextKey::SaveSubscription => "Save subscription",
                TextKey::Rcon => "RCON",
                TextKey::RconPassword => "RCON password",
                TextKey::Command => "Command",
                TextKey::RunCommand => "Run command",
                TextKey::CvarRules => "CVAR / Rules",
                TextKey::OptionalRconPassword => "RCON password, optional",
                TextKey::CvarNamesHelp => {
                    "CVAR names, comma-separated; leave empty for public rules"
                }
                TextKey::ServerList => "Server list",
                TextKey::HeaderGroup => "Group",
                TextKey::HeaderAddress => "Address",
                TextKey::HeaderPing => "Ping",
                TextKey::HeaderPlayers => "Players",
                TextKey::HeaderMap => "Map",
                TextKey::HeaderVac => "VAC",
                TextKey::HeaderNameOrError => "Server name / Error",
                TextKey::WaitingRefresh => "Waiting to refresh",
                TextKey::Querying => "Querying...",
                TextKey::SavingServer => "Saving server...",
                TextKey::SavingSubscription => "Saving subscription...",
                TextKey::RunningCommand => "Running...",
                TextKey::Reading => "Reading...",
                TextKey::ServerSaved => "Server saved",
                TextKey::SubscriptionSaved => "SourceBans subscription saved",
                TextKey::LanguageSaved => "Language setting saved",
                TextKey::NotQueried => "not queried",
                TextKey::ManualServerList => "Saved servers",
                TextKey::SubscriptionList => "Saved subscriptions",
                TextKey::NewSubscription => "New subscription",
                TextKey::UpdateSubscription => "Update subscription",
                TextKey::DeleteSubscription => "Delete subscription",
                TextKey::SubscriptionDeleted => "SourceBans subscription deleted",
                TextKey::SelectedServer => "Selected server",
                TextKey::NoServerSelected => "No server selected",
                TextKey::RefreshRules => "Refresh Rules",
                TextKey::CheckUpdates => "Check updates",
                TextKey::CheckingUpdates => "Checking updates...",
                TextKey::OpenDownloadPage => "Open download page",
                TextKey::AutoUpdate => "Auto-check updates",
                TextKey::CurrentVersion => "Current version",
                TextKey::PlayerList => "Players",
                TextKey::RefreshPlayers => "Refresh players",
                TextKey::NoPlayers => "No public player data",
                TextKey::FilterEmpty => "Empty Only",
                TextKey::FilterHasPlayers => "Has Players",
                TextKey::FilterHideTimeout => "Hide Timeouts",
                TextKey::GlobalPlayersTab => "All Server Players",
                TextKey::BroadcastTab => "Broadcast",
                TextKey::SettingsTab => "Settings",
                TextKey::ActivePlayers => "Active Players",
                TextKey::SearchPlaceholder => "Filter servers (name/map/group)...",
                TextKey::TotalServers => "Total Servers",
                TextKey::ConnectGame => "Connect Game",
                TextKey::CvarSearchPlaceholder => "Filter CVAR names...",
                TextKey::GlobalPlayerSearchPlaceholder => "Search player name...",
                TextKey::ApiBaseUrl => "AnneWeb API URL",
                TextKey::SteamLogin => "Steam login",
                TextKey::Logout => "Logout",
                TextKey::BroadcastMessage => "Broadcast message",
                TextKey::SendBroadcast => "Send broadcast",
            },
        }
    }

    fn config_file_status(self, path: &Path) -> String {
        match self {
            Self::ZhCn => format!("配置文件：{}", path.display()),
            Self::EnUs => format!("Config file: {}", path.display()),
        }
    }

    fn server_count_status(self, count: usize) -> String {
        match self {
            Self::ZhCn => format!("共 {count} 个服务器"),
            Self::EnUs => format!("{count} servers"),
        }
    }

    fn refresh_failed_status(self, err: &str) -> String {
        match self {
            Self::ZhCn => format!("刷新失败：{err}"),
            Self::EnUs => format!("Refresh failed: {err}"),
        }
    }

    fn save_server_failed_status(self, err: &str) -> String {
        match self {
            Self::ZhCn => format!("保存服务器失败：{err}"),
            Self::EnUs => format!("Failed to save server: {err}"),
        }
    }

    fn save_subscription_failed_status(self, err: &str) -> String {
        match self {
            Self::ZhCn => format!("保存订阅失败：{err}"),
            Self::EnUs => format!("Failed to save subscription: {err}"),
        }
    }

    fn save_language_failed_status(self, err: &str) -> String {
        match self {
            Self::ZhCn => format!("保存语言设置失败：{err}"),
            Self::EnUs => format!("Failed to save language setting: {err}"),
        }
    }

    fn delete_subscription_failed_status(self, err: &str) -> String {
        match self {
            Self::ZhCn => format!("删除订阅失败：{err}"),
            Self::EnUs => format!("Failed to delete subscription: {err}"),
        }
    }

    fn update_available_status(self, latest: &str) -> String {
        match self {
            Self::ZhCn => format!("发现新版本：{latest}"),
            Self::EnUs => format!("Update available: {latest}"),
        }
    }

    fn up_to_date_status(self) -> String {
        match self {
            Self::ZhCn => "已是最新版本".to_owned(),
            Self::EnUs => "You are up to date".to_owned(),
        }
    }

    fn update_check_failed_status(self, err: &str) -> String {
        match self {
            Self::ZhCn => format!("检查更新失败：{err}"),
            Self::EnUs => format!("Update check failed: {err}"),
        }
    }

    fn rcon_failed_output(self, err: &str) -> String {
        match self {
            Self::ZhCn => format!("RCON 失败：{err}"),
            Self::EnUs => format!("RCON failed: {err}"),
        }
    }

    fn cvar_failed_output(self, err: &str) -> String {
        match self {
            Self::ZhCn => format!("读取失败：{err}"),
            Self::EnUs => format!("Read failed: {err}"),
        }
    }
}

#[derive(Debug, Clone, Copy)]
enum TextKey {
    AppTitle,
    RefreshServers,
    Language,
    AddServer,
    Group,
    ServerAddress,
    SaveServer,
    SourceBansSubscription,
    SubscriptionName,
    PageUrl,
    SaveSubscription,
    Rcon,
    RconPassword,
    Command,
    RunCommand,
    CvarRules,
    OptionalRconPassword,
    CvarNamesHelp,
    ServerList,
    HeaderGroup,
    HeaderAddress,
    HeaderPing,
    HeaderPlayers,
    HeaderMap,
    HeaderVac,
    HeaderNameOrError,
    WaitingRefresh,
    Querying,
    SavingServer,
    SavingSubscription,
    RunningCommand,
    Reading,
    ServerSaved,
    SubscriptionSaved,
    LanguageSaved,
    NotQueried,
    ManualServerList,
    SubscriptionList,
    NewSubscription,
    UpdateSubscription,
    DeleteSubscription,
    SubscriptionDeleted,
    SelectedServer,
    NoServerSelected,
    RefreshRules,
    CheckUpdates,
    CheckingUpdates,
    OpenDownloadPage,
    AutoUpdate,
    CurrentVersion,
    PlayerList,
    RefreshPlayers,
    NoPlayers,
    FilterEmpty,
    FilterHasPlayers,
    FilterHideTimeout,
    GlobalPlayersTab,
    BroadcastTab,
    SettingsTab,
    ActivePlayers,
    SearchPlaceholder,
    TotalServers,
    ConnectGame,
    CvarSearchPlaceholder,
    GlobalPlayerSearchPlaceholder,
    ApiBaseUrl,
    SteamLogin,
    Logout,
    BroadcastMessage,
    SendBroadcast,
}

#[derive(Debug, Clone, Deserialize, Serialize, Default)]
struct FileMaster {
    enabled: Option<bool>,
    address: Option<String>,
    group: Option<String>,
    region: Option<String>,
    filter: Option<String>,
    #[serde(default)]
    extra_filter: Vec<String>,
    limit: Option<usize>,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
struct FileGroup {
    name: String,
    servers: Vec<String>,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
struct FileSourceBans {
    name: String,
    url: String,
}

#[derive(Debug, Clone)]
struct ManualGroup {
    name: String,
    servers: Vec<String>,
}

#[derive(Debug, Clone)]
struct SourceBansSubscription {
    name: String,
    url: String,
}

impl TryFrom<FileGroup> for ManualGroup {
    type Error = String;

    fn try_from(value: FileGroup) -> Result<Self, Self::Error> {
        Ok(Self {
            name: non_empty(value.name, "groups.name")?,
            servers: value.servers,
        })
    }
}

impl TryFrom<FileSourceBans> for SourceBansSubscription {
    type Error = String;

    fn try_from(value: FileSourceBans) -> Result<Self, Self::Error> {
        Ok(Self {
            name: non_empty(value.name, "sourcebans.name")?,
            url: non_empty(value.url, "sourcebans.url")?,
        })
    }
}

fn load_config(path: Option<&PathBuf>) -> Result<Option<BrowserConfig>, String> {
    let Some(path) = path else {
        return Ok(None);
    };

    let text = fs::read_to_string(path)
        .map_err(|err| format!("failed to read config {}: {err}", path.display()))?;
    let config = toml::from_str(&text)
        .map_err(|err| format!("failed to parse config {}: {err}", path.display()))?;
    Ok(Some(config))
}

fn load_config_or_default(path: &PathBuf) -> Result<BrowserConfig, String> {
    match fs::read_to_string(path) {
        Ok(text) => toml::from_str(&text)
            .map_err(|err| format!("failed to parse config {}: {err}", path.display())),
        Err(err) if err.kind() == io::ErrorKind::NotFound => Ok(BrowserConfig::default()),
        Err(err) => Err(format!("failed to read config {}: {err}", path.display())),
    }
}

fn save_config(path: &PathBuf, config: &BrowserConfig) -> Result<(), String> {
    if let Some(parent) = path.parent() {
        if !parent.as_os_str().is_empty() {
            fs::create_dir_all(parent).map_err(|err| {
                format!(
                    "failed to create config directory {}: {err}",
                    parent.display()
                )
            })?;
        }
    }

    let text = toml::to_string_pretty(config)
        .map_err(|err| format!("failed to serialize config: {err}"))?;
    fs::write(path, text).map_err(|err| format!("failed to write config {}: {err}", path.display()))
}

fn non_empty(value: String, field: &str) -> Result<String, String> {
    if value.trim().is_empty() {
        Err(format!("{field} cannot be empty"))
    } else {
        Ok(value)
    }
}

fn positive<T>(value: T, field: &str) -> Result<T, String>
where
    T: PartialEq + From<u8> + Copy,
{
    if value == T::from(0) {
        Err(format!("{field} must be greater than zero"))
    } else {
        Ok(value)
    }
}

fn parse_cli_group(value: &str) -> Result<ManualGroup, String> {
    let (name, servers) = split_name_value(value, "--group")?;
    let servers = servers
        .split(|ch| ch == ',' || ch == ';' || ch == ' ')
        .filter(|part| !part.trim().is_empty())
        .map(|part| part.trim().to_owned())
        .collect::<Vec<_>>();

    if servers.is_empty() {
        return Err("--group requires at least one server address".to_owned());
    }

    Ok(ManualGroup { name, servers })
}

fn parse_cli_subscription(value: &str) -> Result<SourceBansSubscription, String> {
    let (name, url) = split_name_value(value, "--sourcebans")?;
    Ok(SourceBansSubscription { name, url })
}

fn split_name_value(value: &str, flag: &str) -> Result<(String, String), String> {
    let (name, value) = value
        .split_once('=')
        .ok_or_else(|| format!("{flag} must use NAME=VALUE"))?;
    let name = non_empty(name.trim().to_owned(), flag)?;
    let value = non_empty(value.trim().to_owned(), flag)?;
    Ok((name, value))
}

fn parse_region(value: &str) -> Result<u8, String> {
    match value.to_ascii_lowercase().as_str() {
        "us-east" | "useast" => Ok(0x00),
        "us-west" | "uswest" => Ok(0x01),
        "south-america" | "southamerica" => Ok(0x02),
        "europe" => Ok(0x03),
        "asia" => Ok(0x04),
        "australia" => Ok(0x05),
        "middle-east" | "middleeast" => Ok(0x06),
        "africa" => Ok(0x07),
        "all" | "rest" | "world" => Ok(0xFF),
        _ => value
            .parse::<u8>()
            .map_err(|_| format!("invalid region: {value}")),
    }
}

fn collect_sources(
    settings: &RuntimeSettings,
    manual_groups: &[ManualGroup],
    subscriptions: &[SourceBansSubscription],
) -> Result<HashMap<SocketAddrV4, RegistryEntry>, String> {
    let mut registry = HashMap::new();

    if settings.master_enabled {
        match resolve_ipv4(&settings.master) {
            Ok(master_addr) => {
                let master = MasterClient {
                    addr: master_addr,
                    timeout: settings.master_timeout,
                };
                match master.fetch(settings.region, &settings.filter, settings.limit) {
                    Ok(endpoints) => {
                        for endpoint in endpoints {
                            add_endpoint(&mut registry, endpoint, &settings.master_group);
                        }
                    }
                    Err(err) => eprintln!("warning: master server query failed: {err}"),
                }
            }
            Err(err) => eprintln!(
                "warning: failed to resolve master server {}: {err}",
                settings.master
            ),
        }
    }

    for group in manual_groups {
        for server in &group.servers {
            match resolve_endpoint(server) {
                Ok(endpoint) => add_endpoint(&mut registry, endpoint, &group.name),
                Err(err) => eprintln!("warning: skipped {} in group {}: {err}", server, group.name),
            }
        }
    }

    for subscription in subscriptions {
        match fetch_sourcebans_subscription(subscription, settings.http_timeout) {
            Ok(addresses) => {
                for address in addresses {
                    match resolve_endpoint(&address) {
                        Ok(endpoint) => add_endpoint(&mut registry, endpoint, &subscription.name),
                        Err(err) => eprintln!(
                            "warning: skipped {} from SourceBans {}: {err}",
                            address, subscription.url
                        ),
                    }
                }
            }
            Err(err) => eprintln!(
                "warning: SourceBans subscription {} failed: {err}",
                subscription.url
            ),
        }
    }

    Ok(registry)
}

#[derive(Debug, Clone)]
struct RegistryEntry {
    display: String,
    socket: SocketAddrV4,
    groups: BTreeSet<String>,
}

#[derive(Debug, Clone)]
struct Endpoint {
    display: String,
    socket: SocketAddrV4,
    groups: Vec<String>,
}

fn add_endpoint(
    registry: &mut HashMap<SocketAddrV4, RegistryEntry>,
    endpoint: Endpoint,
    group: &str,
) {
    let entry = registry
        .entry(endpoint.socket)
        .or_insert_with(|| RegistryEntry {
            display: endpoint.display,
            socket: endpoint.socket,
            groups: BTreeSet::new(),
        });
    entry.groups.insert(group.to_owned());
}

#[derive(Debug, Clone)]
struct ServerRow {
    endpoint: Endpoint,
    info: Option<ServerInfo>,
    ping: Option<Duration>,
    error: Option<String>,
}

#[derive(Debug, Clone, Serialize)]
struct ServerInfo {
    protocol: u8,
    name: String,
    map: String,
    folder: String,
    game: String,
    app_id: u16,
    players: u8,
    max_players: u8,
    bots: u8,
    server_type: char,
    environment: char,
    private: bool,
    vac: bool,
    version: String,
    port: Option<u16>,
    steam_id: Option<u64>,
    spectator_port: Option<u16>,
    spectator_name: Option<String>,
    keywords: Option<String>,
    game_id: Option<u64>,
}

struct MasterClient {
    addr: SocketAddrV4,
    timeout: Duration,
}

impl MasterClient {
    fn fetch(&self, region: u8, filter: &str, limit: usize) -> io::Result<Vec<Endpoint>> {
        let socket = UdpSocket::bind("0.0.0.0:0")?;
        socket.set_read_timeout(Some(self.timeout))?;
        socket.set_write_timeout(Some(self.timeout))?;

        let mut cursor = "0.0.0.0:0".to_owned();
        let mut results = Vec::new();
        let mut seen = HashSet::new();
        let mut pages = 0usize;

        while results.len() < limit {
            pages += 1;
            if pages > 10_000 {
                break;
            }

            let request = build_master_request(region, &cursor, filter);
            socket.send_to(&request, SocketAddr::V4(self.addr))?;

            let mut buf = [0u8; 1500];
            let size = match socket.recv_from(&mut buf) {
                Ok((size, _from)) => size,
                Err(err)
                    if err.kind() == io::ErrorKind::WouldBlock
                        || err.kind() == io::ErrorKind::TimedOut =>
                {
                    if results.is_empty() {
                        return Err(err);
                    }
                    break;
                }
                Err(err) => return Err(err),
            };

            let page = parse_master_response(&buf[..size])
                .map_err(|err| io::Error::new(io::ErrorKind::InvalidData, err))?;
            if page.is_empty() {
                break;
            }

            let mut advanced = false;
            for addr in page {
                cursor = addr.to_string();
                advanced = true;

                if seen.insert(addr) {
                    results.push(Endpoint {
                        display: addr.to_string(),
                        socket: addr,
                        groups: Vec::new(),
                    });
                    if results.len() >= limit {
                        break;
                    }
                }
            }

            if !advanced {
                break;
            }
        }

        Ok(results)
    }
}

fn build_master_request(region: u8, cursor: &str, filter: &str) -> Vec<u8> {
    let mut request = Vec::with_capacity(3 + cursor.len() + filter.len());
    request.push(0x31);
    request.push(region);
    request.extend_from_slice(cursor.as_bytes());
    request.push(0);
    request.extend_from_slice(filter.as_bytes());
    request.push(0);
    request
}

fn parse_master_response(packet: &[u8]) -> Result<Vec<SocketAddrV4>, String> {
    let offset = if packet.len() >= 6
        && packet.starts_with(&[0xFF, 0xFF, 0xFF, 0xFF])
        && packet[4] == 0x66
    {
        6
    } else {
        return Err("invalid master server response header".to_owned());
    };

    let mut addrs = Vec::new();
    for chunk in packet[offset..].chunks_exact(6) {
        let ip = Ipv4Addr::new(chunk[0], chunk[1], chunk[2], chunk[3]);
        let port = u16::from_be_bytes([chunk[4], chunk[5]]);

        if ip == Ipv4Addr::new(0, 0, 0, 0) && port == 0 {
            continue;
        }

        addrs.push(SocketAddrV4::new(ip, port));
    }

    Ok(addrs)
}

fn fetch_sourcebans_subscription(
    subscription: &SourceBansSubscription,
    timeout: Duration,
) -> Result<Vec<String>, String> {
    let url = normalize_sourcebans_url(&subscription.url)?;
    let client = Client::builder()
        .timeout(timeout)
        .user_agent(USER_AGENT)
        .build()
        .map_err(|err| err.to_string())?;
    let body = client
        .get(url.clone())
        .send()
        .map_err(|err| err.to_string())?
        .error_for_status()
        .map_err(|err| err.to_string())?
        .text()
        .map_err(|err| err.to_string())?;
    let addresses = extract_sourcebans_addresses(&body)?;

    if addresses.is_empty() {
        Err(format!("no server addresses found at {url}"))
    } else {
        Ok(addresses)
    }
}

fn normalize_sourcebans_url(input: &str) -> Result<reqwest::Url, String> {
    let input = input.trim();
    let parse_input = if input.contains("://") {
        input.to_owned()
    } else {
        format!("https://{input}")
    };
    let mut url =
        reqwest::Url::parse(&parse_input).map_err(|err| format!("invalid URL {input}: {err}"))?;
    let has_servers_page = url
        .query_pairs()
        .any(|(key, value)| key.eq_ignore_ascii_case("p") && value.eq_ignore_ascii_case("servers"));

    if has_servers_page {
        return Ok(url);
    }

    if !url.path().ends_with(".php") {
        let mut path = url.path().trim_end_matches('/').to_owned();
        path.push_str("/index.php");
        url.set_path(&path);
    }
    url.query_pairs_mut().append_pair("p", "servers");
    Ok(url)
}

fn extract_sourcebans_addresses(body: &str) -> Result<Vec<String>, String> {
    let body = decode_minimal_html_entities(body);
    let connect_re =
        Regex::new(r#"(?i)steam://connect/([^"'<>\s]+)"#).map_err(|err| err.to_string())?;
    let ip_re = Regex::new(
        r#"\b((?:(?:25[0-5]|2[0-4]\d|1?\d?\d)\.){3}(?:25[0-5]|2[0-4]\d|1?\d?\d)):(\d{2,5})\b"#,
    )
    .map_err(|err| err.to_string())?;
    let host_re = Regex::new(r#"\b([A-Za-z0-9][A-Za-z0-9.-]*\.[A-Za-z]{2,})(?::)(\d{2,5})\b"#)
        .map_err(|err| err.to_string())?;

    let mut seen = BTreeSet::new();
    for capture in connect_re.captures_iter(&body) {
        if let Some(raw) = capture.get(1) {
            let address = raw
                .as_str()
                .split('/')
                .next()
                .unwrap_or(raw.as_str())
                .to_owned();
            seen.insert(address);
        }
    }

    for capture in ip_re.captures_iter(&body) {
        let port = capture
            .get(2)
            .and_then(|value| value.as_str().parse::<u16>().ok());
        if port.is_some() {
            seen.insert(format!("{}:{}", &capture[1], &capture[2]));
        }
    }

    for capture in host_re.captures_iter(&body) {
        let port = capture
            .get(2)
            .and_then(|value| value.as_str().parse::<u16>().ok());
        if port.is_some() {
            seen.insert(format!("{}:{}", &capture[1], &capture[2]));
        }
    }

    Ok(seen.into_iter().collect())
}

fn decode_minimal_html_entities(value: &str) -> String {
    value
        .replace("&amp;", "&")
        .replace("&#38;", "&")
        .replace("&#x26;", "&")
        .replace("&colon;", ":")
        .replace("&#58;", ":")
        .replace("&#x3a;", ":")
        .replace("&#x3A;", ":")
}

fn sourcebans_group_name(url: &str) -> String {
    let parse_input = if url.contains("://") {
        url.to_owned()
    } else {
        format!("https://{url}")
    };

    reqwest::Url::parse(&parse_input)
        .ok()
        .and_then(|url| url.host_str().map(|host| format!("SourceBans:{host}")))
        .unwrap_or_else(|| "SourceBans".to_owned())
}

fn resolve_endpoint(input: &str) -> Result<Endpoint, String> {
    let address = normalize_endpoint_input(input)?;
    let socket =
        resolve_ipv4(&address).map_err(|err| format!("failed to resolve {address}: {err}"))?;

    Ok(Endpoint {
        display: address,
        socket,
        groups: Vec::new(),
    })
}

fn normalize_endpoint_input(input: &str) -> Result<String, String> {
    let mut value = input.trim();
    if let Some(rest) = value.strip_prefix("steam://connect/") {
        value = rest.split('/').next().unwrap_or(rest);
    }

    if value.is_empty() {
        return Err("server address cannot be empty".to_owned());
    }
    if !value.contains(':') {
        return Err("server address must include a port, for example 1.2.3.4:27015".to_owned());
    }

    Ok(value.to_owned())
}

fn resolve_ipv4(input: &str) -> io::Result<SocketAddrV4> {
    input
        .to_socket_addrs()?
        .find_map(|addr| match addr {
            SocketAddr::V4(addr) => Some(addr),
            SocketAddr::V6(_) => None,
        })
        .ok_or_else(|| io::Error::new(io::ErrorKind::NotFound, "no IPv4 address found"))
}

fn query_servers(endpoints: Vec<Endpoint>, timeout: Duration, jobs: usize) -> Vec<ServerRow> {
    if endpoints.is_empty() {
        return Vec::new();
    }

    let queue: VecDeque<_> = endpoints.into_iter().collect();
    let queue = Arc::new(Mutex::new(queue));
    let results = Arc::new(Mutex::new(Vec::new()));
    let worker_count = jobs.min(queue.lock().expect("queue poisoned").len()).max(1);

    let mut workers = Vec::with_capacity(worker_count);
    for _ in 0..worker_count {
        let queue = Arc::clone(&queue);
        let results = Arc::clone(&results);

        workers.push(thread::spawn(move || loop {
            let next = {
                let mut queue = queue.lock().expect("queue poisoned");
                queue.pop_front()
            };

            let endpoint = match next {
                Some(endpoint) => endpoint,
                None => break,
            };

            let row = match query_server_info(endpoint.socket, timeout) {
                Ok((info, ping)) => ServerRow {
                    endpoint,
                    info: Some(info),
                    ping: Some(ping),
                    error: None,
                },
                Err(error) => ServerRow {
                    endpoint,
                    info: None,
                    ping: None,
                    error: Some(error),
                },
            };

            results.lock().expect("results poisoned").push(row);
        }));
    }

    for worker in workers {
        let _ = worker.join();
    }

    let mut results = results.lock().expect("results poisoned");
    std::mem::take(&mut *results)
}

fn query_server_info(
    addr: SocketAddrV4,
    timeout: Duration,
) -> Result<(ServerInfo, Duration), String> {
    let socket = UdpSocket::bind("0.0.0.0:0").map_err(|err| err.to_string())?;
    socket
        .set_read_timeout(Some(timeout))
        .map_err(|err| err.to_string())?;
    socket
        .set_write_timeout(Some(timeout))
        .map_err(|err| err.to_string())?;
    socket
        .connect(SocketAddr::V4(addr))
        .map_err(|err| err.to_string())?;

    let started = Instant::now();
    let request = build_a2s_info_request(None);
    socket.send(&request).map_err(|err| err.to_string())?;

    let mut buf = [0u8; 4096];
    let size = socket.recv(&mut buf).map_err(|err| err.to_string())?;
    let packet = &buf[..size];

    if let Some(challenge) = parse_challenge(packet) {
        let request = build_a2s_info_request(Some(challenge));
        socket.send(&request).map_err(|err| err.to_string())?;
        let size = socket.recv(&mut buf).map_err(|err| err.to_string())?;
        let info = parse_server_info(&buf[..size])?;
        return Ok((info, started.elapsed()));
    }

    let info = parse_server_info(packet)?;
    Ok((info, started.elapsed()))
}

fn build_a2s_info_request(challenge: Option<[u8; 4]>) -> Vec<u8> {
    let mut request = Vec::from(&b"\xFF\xFF\xFF\xFFTSource Engine Query\0"[..]);
    if let Some(challenge) = challenge {
        request.extend_from_slice(&challenge);
    }
    request
}

fn parse_challenge(packet: &[u8]) -> Option<[u8; 4]> {
    if packet.len() >= 9 && packet.starts_with(&[0xFF, 0xFF, 0xFF, 0xFF]) && packet[4] == 0x41 {
        Some([packet[5], packet[6], packet[7], packet[8]])
    } else {
        None
    }
}

fn parse_server_info(packet: &[u8]) -> Result<ServerInfo, String> {
    if packet.len() >= 4 && packet.starts_with(&[0xFE, 0xFF, 0xFF, 0xFF]) {
        return Err("split A2S_INFO response is not supported".to_owned());
    }

    if packet.len() < 5 || !packet.starts_with(&[0xFF, 0xFF, 0xFF, 0xFF]) || packet[4] != 0x49 {
        return Err("invalid A2S_INFO response".to_owned());
    }

    let mut reader = PacketReader::new(&packet[5..]);
    let protocol = reader.u8()?;
    let name = reader.string()?;
    let map = reader.string()?;
    let folder = reader.string()?;
    let game = reader.string()?;
    let app_id = reader.u16_le()?;
    let players = reader.u8()?;
    let max_players = reader.u8()?;
    let bots = reader.u8()?;
    let server_type = reader.u8()? as char;
    let environment = reader.u8()? as char;
    let private = reader.u8()? != 0;
    let vac = reader.u8()? != 0;
    let version = reader.string()?;

    let mut info = ServerInfo {
        protocol,
        name,
        map,
        folder,
        game,
        app_id,
        players,
        max_players,
        bots,
        server_type,
        environment,
        private,
        vac,
        version,
        port: None,
        steam_id: None,
        spectator_port: None,
        spectator_name: None,
        keywords: None,
        game_id: None,
    };

    if reader.remaining() > 0 {
        let edf = reader.u8()?;
        if edf & 0x80 != 0 {
            info.port = Some(reader.u16_le()?);
        }
        if edf & 0x10 != 0 {
            info.steam_id = Some(reader.u64_le()?);
        }
        if edf & 0x40 != 0 {
            info.spectator_port = Some(reader.u16_le()?);
            info.spectator_name = Some(reader.string()?);
        }
        if edf & 0x20 != 0 {
            info.keywords = Some(reader.string()?);
        }
        if edf & 0x01 != 0 {
            info.game_id = Some(reader.u64_le()?);
        }
    }

    Ok(info)
}

struct PacketReader<'a> {
    packet: &'a [u8],
    pos: usize,
}

impl<'a> PacketReader<'a> {
    fn new(packet: &'a [u8]) -> Self {
        Self { packet, pos: 0 }
    }

    fn remaining(&self) -> usize {
        self.packet.len().saturating_sub(self.pos)
    }

    fn u8(&mut self) -> Result<u8, String> {
        if self.remaining() < 1 {
            return Err("unexpected end of packet".to_owned());
        }
        let value = self.packet[self.pos];
        self.pos += 1;
        Ok(value)
    }

    fn u16_le(&mut self) -> Result<u16, String> {
        let bytes = self.take(2)?;
        Ok(u16::from_le_bytes([bytes[0], bytes[1]]))
    }

    fn i32_le(&mut self) -> Result<i32, String> {
        let bytes = self.take(4)?;
        Ok(i32::from_le_bytes([bytes[0], bytes[1], bytes[2], bytes[3]]))
    }

    fn f32_le(&mut self) -> Result<f32, String> {
        let bytes = self.take(4)?;
        Ok(f32::from_le_bytes([bytes[0], bytes[1], bytes[2], bytes[3]]))
    }

    fn u64_le(&mut self) -> Result<u64, String> {
        let bytes = self.take(8)?;
        Ok(u64::from_le_bytes([
            bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
        ]))
    }

    fn string(&mut self) -> Result<String, String> {
        let start = self.pos;
        let end = self.packet[start..]
            .iter()
            .position(|byte| *byte == 0)
            .map(|offset| start + offset)
            .ok_or_else(|| "unterminated string in packet".to_owned())?;

        self.pos = end + 1;
        Ok(String::from_utf8_lossy(&self.packet[start..end]).into_owned())
    }

    fn take(&mut self, count: usize) -> Result<&'a [u8], String> {
        if self.remaining() < count {
            return Err("unexpected end of packet".to_owned());
        }
        let start = self.pos;
        self.pos += count;
        Ok(&self.packet[start..start + count])
    }
}

fn apply_filters(rows: Vec<ServerRow>, settings: &RuntimeSettings) -> Vec<ServerRow> {
    rows.into_iter()
        .filter(|row| {
            if let Some(needle) = &settings.group_filter {
                let matched = row
                    .endpoint
                    .groups
                    .iter()
                    .any(|group| group.to_lowercase().contains(needle));
                if !matched {
                    return false;
                }
            }

            let Some(info) = &row.info else {
                return settings.min_players.is_none()
                    && settings.name_filter.is_none()
                    && settings.map_filter.is_none();
            };

            if let Some(min_players) = settings.min_players {
                if info.players < min_players {
                    return false;
                }
            }

            if let Some(needle) = &settings.name_filter {
                if !info.name.to_lowercase().contains(needle) {
                    return false;
                }
            }

            if let Some(needle) = &settings.map_filter {
                if !info.map.to_lowercase().contains(needle) {
                    return false;
                }
            }

            true
        })
        .collect()
}

fn sort_rows(rows: &mut [ServerRow], sort: SortKey) {
    match sort {
        SortKey::Players => rows.sort_by(|a, b| {
            players(b)
                .cmp(&players(a))
                .then_with(|| max_players(b).cmp(&max_players(a)))
                .then_with(|| ping_ms(a).cmp(&ping_ms(b)))
                .then_with(|| address_key(a).cmp(&address_key(b)))
        }),
        SortKey::Ping => rows.sort_by(|a, b| {
            ping_ms(a)
                .cmp(&ping_ms(b))
                .then_with(|| players(b).cmp(&players(a)))
                .then_with(|| address_key(a).cmp(&address_key(b)))
        }),
        SortKey::Name => rows.sort_by(|a, b| {
            name_key(a)
                .cmp(&name_key(b))
                .then_with(|| address_key(a).cmp(&address_key(b)))
        }),
        SortKey::Map => rows.sort_by(|a, b| {
            map_key(a)
                .cmp(&map_key(b))
                .then_with(|| players(b).cmp(&players(a)))
                .then_with(|| address_key(a).cmp(&address_key(b)))
        }),
        SortKey::Address => rows.sort_by(|a, b| address_key(a).cmp(&address_key(b))),
        SortKey::Group => rows.sort_by(|a, b| {
            group_key(a)
                .cmp(&group_key(b))
                .then_with(|| players(b).cmp(&players(a)))
                .then_with(|| address_key(a).cmp(&address_key(b)))
        }),
    }
}

fn players(row: &ServerRow) -> u8 {
    row.info.as_ref().map(|info| info.players).unwrap_or(0)
}

fn max_players(row: &ServerRow) -> u8 {
    row.info.as_ref().map(|info| info.max_players).unwrap_or(0)
}

fn ping_ms(row: &ServerRow) -> u128 {
    row.ping.map(|ping| ping.as_millis()).unwrap_or(u128::MAX)
}

fn name_key(row: &ServerRow) -> String {
    row.info
        .as_ref()
        .map(|info| info.name.to_lowercase())
        .unwrap_or_else(|| "~".to_owned())
}

fn map_key(row: &ServerRow) -> String {
    row.info
        .as_ref()
        .map(|info| info.map.to_lowercase())
        .unwrap_or_else(|| "~".to_owned())
}

fn group_key(row: &ServerRow) -> String {
    row.endpoint.groups.join(",").to_lowercase()
}

fn address_key(row: &ServerRow) -> String {
    row.endpoint.socket.to_string()
}

fn print_table(rows: &[ServerRow]) {
    if rows.is_empty() {
        println!("no servers matched");
        return;
    }

    println!(
        "{:<20} {:<21} {:>7} {:>7} {:>4} {:<22} {:<4} {:<7} {}",
        "group", "address", "ping", "players", "bots", "map", "vac", "access", "name"
    );
    println!("{}", "-".repeat(126));

    for row in rows {
        let groups = clip(&row.endpoint.groups.join(","), 20);
        match &row.info {
            Some(info) => {
                let ping = row
                    .ping
                    .map(|duration| duration.as_millis().to_string())
                    .unwrap_or_else(|| "-".to_owned());
                let players = format!("{}/{}", info.players, info.max_players);
                let vac = if info.vac { "yes" } else { "no" };
                let access = if info.private { "private" } else { "public" };

                println!(
                    "{:<20} {:<21} {:>7} {:>7} {:>4} {:<22} {:<4} {:<7} {}",
                    groups,
                    row.endpoint.display,
                    ping,
                    players,
                    info.bots,
                    clip(&info.map, 22),
                    vac,
                    access,
                    clip(&info.name, 48)
                );
            }
            None => {
                let error = row.error.as_deref().unwrap_or("not queried");
                println!(
                    "{:<20} {:<21} {:>7} {:>7} {:>4} {:<22} {:<4} {:<7} {}",
                    groups,
                    row.endpoint.display,
                    "-",
                    "-",
                    "-",
                    "-",
                    "-",
                    "-",
                    clip(error, 48)
                );
            }
        }
    }
}

fn clip(value: &str, width: usize) -> String {
    let mut chars = value.chars();
    let clipped: String = chars.by_ref().take(width).collect();
    if chars.next().is_some() && width > 3 {
        let mut clipped: String = value.chars().take(width - 3).collect();
        clipped.push_str("...");
        clipped
    } else {
        clipped
    }
}

#[derive(Serialize)]
struct JsonRow<'a> {
    address: &'a str,
    socket: String,
    groups: &'a [String],
    ping_ms: Option<u64>,
    info: &'a Option<ServerInfo>,
    error: &'a Option<String>,
}

fn print_json(rows: &[ServerRow]) -> Result<(), String> {
    let payload = rows
        .iter()
        .map(|row| JsonRow {
            address: &row.endpoint.display,
            socket: row.endpoint.socket.to_string(),
            groups: &row.endpoint.groups,
            ping_ms: row.ping.map(|ping| ping.as_millis() as u64),
            info: &row.info,
            error: &row.error,
        })
        .collect::<Vec<_>>();
    let json = serde_json::to_string_pretty(&payload).map_err(|err| err.to_string())?;
    println!("{json}");
    Ok(())
}

#[derive(Clone)]
struct AddServerRequest {
    group: String,
    server: String,
}

#[derive(Clone)]
struct AddSourceBansRequest {
    name: String,
    url: String,
}

#[derive(Clone)]
struct RconCommandRequest {
    address: String,
    password: String,
    command: String,
    timeout_ms: Option<u64>,
}

#[derive(Clone)]
struct CvarRequest {
    address: String,
    password: Option<String>,
    names: Option<Vec<String>>,
    timeout_ms: Option<u64>,
}

#[derive(Clone)]
struct ApiLoginRequest {
    base_url: String,
}

#[derive(Clone)]
struct BroadcastRequest {
    base_url: String,
    token: String,
    message: String,
}

#[derive(Clone, Serialize)]
struct ServerRowPayload {
    address: String,
    socket: String,
    groups: Vec<String>,
    ping_ms: Option<u64>,
    info: Option<ServerInfo>,
    error: Option<String>,
    #[serde(skip)]
    last_queried: Option<std::time::Instant>,
}

#[derive(Clone, Serialize)]
struct CvarPayload {
    source: String,
    values: BTreeMap<String, String>,
}

#[derive(Clone, Serialize)]
struct PlayerInfo {
    index: u8,
    name: String,
    score: i32,
    duration: f32,
    points: Option<i32>,
    playtime_mins: Option<i32>,
    ppm: Option<f32>,
    quarter_points: Option<i32>,
}

#[derive(Clone)]
struct ManualServerEntry {
    group: String,
    server: String,
}

#[derive(Clone, Default)]
struct GuiConfigLists {
    manual_servers: Vec<ManualServerEntry>,
    sourcebans: Vec<FileSourceBans>,
}

#[derive(Clone)]
struct UpdateInfo {
    latest_version: String,
    html_url: String,
    available: bool,
}

#[derive(Clone, Copy, PartialEq, Eq)]
enum NavTab {
    Servers,
    GlobalPlayers,
    Broadcast,
    AddServer,
    SourceBans,
    Settings,
}

#[derive(Clone, Copy, PartialEq, Eq)]
enum InspectorTab {
    Players,
    Rcon,
    Cvars,
}

#[derive(Clone, Debug)]
struct GlobalPlayerEntry {
    name: String,
    score: i32,
    duration: f32,
    server_name: String,
    server_address: String,
    points: Option<i32>,
    playtime_mins: Option<i32>,
    ppm: Option<f32>,
    quarter_points: Option<i32>,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
struct ApiUser {
    steam_id: String,
    name: String,
    #[serde(default)]
    avatar: String,
    #[serde(default)]
    is_admin: bool,
}

#[derive(Clone, Debug, Deserialize)]
struct DeviceStartResponse {
    ok: bool,
    device_code: String,
    user_code: String,
    verification_url: String,
    expires_in: u64,
    interval: u64,
}

#[derive(Clone, Debug)]
struct ApiLoginSession {
    token: String,
    user: ApiUser,
}

#[derive(Clone, Debug, Deserialize)]
struct ApiMeResponse {
    ok: bool,
    user: Option<ApiUser>,
    message: Option<String>,
}

#[derive(Clone, Debug, Deserialize)]
struct DevicePollResponse {
    ok: bool,
    status: Option<String>,
    access_token: Option<String>,
    user: Option<ApiUser>,
    error: Option<String>,
    message: Option<String>,
}

#[derive(Clone, Debug, Deserialize)]
struct ApiBroadcastResponse {
    ok: bool,
    id: Option<u64>,
    message: Option<String>,
    error: Option<String>,
}

#[derive(Clone, Debug, Deserialize)]
struct PlayerStatsBatchResponse {
    ok: bool,
    results: Vec<PlayerStatsLookup>,
}

#[derive(Clone, Debug, Deserialize)]
struct PlayerStatsLookup {
    ok: bool,
    query: String,
    player: Option<PlayerStats>,
}

#[derive(Clone, Debug, Deserialize)]
struct PlayerStats {
    total_points: i32,
    playtime_minutes: i32,
    ppm: f32,
    quarter_points: i32,
}

enum GuiMessage {
    Servers(Result<Vec<ServerRowPayload>, String>),
    ConfigLists(Result<GuiConfigLists, String>),
    AddServer(Result<(), String>),
    AddSourceBans(Result<(), String>),
    UpdateSourceBans(Result<(), String>),
    DeleteSourceBans(Result<(), String>),
    UpdateCheck(Result<UpdateInfo, String>),
    Rcon(Result<String, String>),
    Cvars(Result<CvarPayload, String>),
    Players(Result<(Vec<PlayerInfo>, bool), String>),
    GlobalPlayers(Result<(Vec<GlobalPlayerEntry>, bool), String>),
    DeleteServer(Result<(), String>),
    ApiMe(Result<ApiUser, String>),
    SteamLoginStarted(Result<DeviceStartResponse, String>),
    SteamLoginFinished(Result<ApiLoginSession, String>),
    Broadcast(Result<ApiBroadcastResponse, String>),
    ServerUpdate(String, Result<ServerRowPayload, String>),
}

struct NativeGuiApp {
    cli: Cli,
    config_path: PathBuf,
    language: GuiLanguage,
    current_nav: NavTab,
    inspector_tab: InspectorTab,
    tx: Sender<GuiMessage>,
    rx: Receiver<GuiMessage>,
    servers: Vec<ServerRowPayload>,
    manual_servers: Vec<ManualServerEntry>,
    sourcebans_entries: Vec<FileSourceBans>,
    selected_sourcebans: Option<usize>,
    selected_server: Option<String>,
    gui_sort: SortKey,
    gui_sort_desc: bool,
    updater_auto_check: bool,
    update_status: String,
    update_url: Option<String>,
    server_status: String,
    config_status: String,
    group_name: String,
    server_address: String,
    sourcebans_name: String,
    sourcebans_url: String,
    rcon_address: String,
    rcon_password: String,
    rcon_command_text: String,
    rcon_output: String,
    cvar_address: String,
    cvar_password: String,
    cvar_names: String,
    cvar_output: String,
    player_output: String,
    // 新增 UI 交互状态
    ui_search_query: String,
    ui_filter_empty: bool,
    ui_filter_has_players: bool,
    ui_filter_hide_timeout: bool,
    save_rcon_password: bool,
    cvar_search_query: String,
    global_player_search_query: String,
    global_players: Vec<GlobalPlayerEntry>,
    global_players_status: String,
    global_players_querying: bool,
    selected_server_players: Vec<PlayerInfo>,
    api_base_url: String,
    api_token: String,
    api_user: Option<ApiUser>,
    api_status: String,
    steam_login_in_progress: bool,
    broadcast_message: String,
    broadcast_output: String,
    broadcast_sending: bool,
}

fn apply_dark_theme(ctx: &egui::Context) {
    let mut style = (*ctx.style()).clone();

    style.spacing.item_spacing = egui::vec2(12.0, 10.0);
    style.spacing.button_padding = egui::vec2(10.0, 6.0);
    style.spacing.scroll = egui::style::ScrollStyle::solid();

    let mut visuals = egui::Visuals::dark();

    visuals.panel_fill = egui::Color32::from_rgb(11, 15, 25);
    visuals.window_fill = egui::Color32::from_rgb(17, 24, 39);
    visuals.widgets.noninteractive.bg_fill = egui::Color32::from_rgb(17, 24, 39);
    visuals.widgets.noninteractive.bg_stroke =
        egui::Stroke::new(1.0, egui::Color32::from_rgb(31, 41, 55));

    visuals.widgets.inactive.bg_fill = egui::Color32::from_rgb(31, 41, 55);
    visuals.widgets.inactive.bg_stroke =
        egui::Stroke::new(1.0, egui::Color32::from_rgb(55, 65, 81));
    visuals.widgets.inactive.fg_stroke =
        egui::Stroke::new(1.0, egui::Color32::from_rgb(248, 250, 252));
    visuals.widgets.inactive.corner_radius = egui::CornerRadius::same(6);

    visuals.widgets.hovered.bg_fill = egui::Color32::from_rgb(79, 70, 229);
    visuals.widgets.hovered.bg_stroke =
        egui::Stroke::new(1.0, egui::Color32::from_rgb(99, 102, 241));
    visuals.widgets.hovered.fg_stroke =
        egui::Stroke::new(1.0, egui::Color32::from_rgb(255, 255, 255));
    visuals.widgets.hovered.corner_radius = egui::CornerRadius::same(6);

    visuals.widgets.active.bg_fill = egui::Color32::from_rgb(99, 102, 241);
    visuals.widgets.active.bg_stroke =
        egui::Stroke::new(1.0, egui::Color32::from_rgb(129, 140, 248));
    visuals.widgets.active.fg_stroke =
        egui::Stroke::new(1.0, egui::Color32::from_rgb(255, 255, 255));
    visuals.widgets.active.corner_radius = egui::CornerRadius::same(6);

    visuals.selection.bg_fill = egui::Color32::from_rgb(99, 102, 241);
    visuals.selection.stroke = egui::Stroke::new(1.0, egui::Color32::from_rgb(255, 255, 255));

    visuals.extreme_bg_color = egui::Color32::from_rgb(3, 7, 18);

    style.visuals = visuals;
    ctx.set_style(style);
}

fn start_gui(cli: Cli, config_path: PathBuf) -> Result<(), String> {
    let language = initial_gui_language(&config_path);
    let options = eframe::NativeOptions {
        viewport: egui::ViewportBuilder::default().with_inner_size([1180.0, 760.0]),
        ..Default::default()
    };
    let title = language.text(TextKey::AppTitle).to_owned();

    eframe::run_native(
        &title,
        options,
        Box::new(move |cc| {
            apply_dark_theme(&cc.egui_ctx);
            install_cjk_fonts(&cc.egui_ctx);
            Ok(Box::new(NativeGuiApp::new(cli, config_path, language)))
        }),
    )
    .map_err(|err| format!("failed to start native GUI: {err}"))
}

fn initial_gui_language(config_path: &Path) -> GuiLanguage {
    load_config_or_default(&config_path.to_path_buf())
        .map(|config| config.gui.language)
        .unwrap_or_default()
}

fn install_cjk_fonts(ctx: &egui::Context) {
    let Some((font_name, font_bytes)) = load_first_cjk_font() else {
        return;
    };

    let mut fonts = egui::FontDefinitions::default();
    fonts.font_data.insert(
        font_name.clone(),
        Arc::new(egui::FontData::from_owned(font_bytes)),
    );

    if let Some(family) = fonts.families.get_mut(&egui::FontFamily::Proportional) {
        family.insert(0, font_name.clone());
    }
    if let Some(family) = fonts.families.get_mut(&egui::FontFamily::Monospace) {
        family.push(font_name);
    }

    ctx.set_fonts(fonts);
}

fn load_first_cjk_font() -> Option<(String, Vec<u8>)> {
    for path in cjk_font_candidates() {
        if let Ok(bytes) = fs::read(&path) {
            if !bytes.is_empty() {
                let name = path
                    .file_stem()
                    .and_then(|stem| stem.to_str())
                    .unwrap_or("system-cjk")
                    .to_owned();
                return Some((name, bytes));
            }
        }
    }
    None
}

fn cjk_font_candidates() -> Vec<PathBuf> {
    let mut candidates = Vec::new();

    #[cfg(target_os = "windows")]
    {
        let fonts_dir = env::var_os("WINDIR")
            .map(PathBuf::from)
            .unwrap_or_else(|| PathBuf::from(r"C:\Windows"))
            .join("Fonts");
        candidates.extend([
            fonts_dir.join("msyh.ttc"),
            fonts_dir.join("simhei.ttf"),
            fonts_dir.join("simsun.ttc"),
            fonts_dir.join("Deng.ttf"),
            fonts_dir.join("NotoSansCJK-Regular.ttc"),
        ]);
    }

    #[cfg(target_os = "macos")]
    {
        candidates.extend([
            PathBuf::from("/System/Library/Fonts/PingFang.ttc"),
            PathBuf::from("/System/Library/Fonts/STHeiti Light.ttc"),
            PathBuf::from("/System/Library/Fonts/Supplemental/Songti.ttc"),
            PathBuf::from("/System/Library/Fonts/Supplemental/Arial Unicode.ttf"),
        ]);
    }

    #[cfg(all(unix, not(target_os = "macos")))]
    {
        candidates.extend([
            PathBuf::from("/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"),
            PathBuf::from("/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.otf"),
            PathBuf::from("/usr/share/fonts/truetype/noto/NotoSansCJK-Regular.ttc"),
            PathBuf::from("/usr/share/fonts/truetype/wqy/wqy-microhei.ttc"),
            PathBuf::from("/usr/share/fonts/truetype/arphic/uming.ttc"),
        ]);
    }

    candidates
}

impl NativeGuiApp {
    fn new(cli: Cli, config_path: PathBuf, language: GuiLanguage) -> Self {
        let initial_config = load_config_or_default(&config_path).unwrap_or_default();
        let (tx, rx) = mpsc::channel();
        let mut app = Self {
            cli,
            config_path,
            language,
            current_nav: NavTab::Servers,
            inspector_tab: InspectorTab::Players,
            tx,
            rx,
            servers: Vec::new(),
            manual_servers: Vec::new(),
            sourcebans_entries: Vec::new(),
            selected_sourcebans: None,
            selected_server: None,
            gui_sort: SortKey::Ping,
            gui_sort_desc: false,
            updater_auto_check: initial_config.updater.auto_check,
            update_status: String::new(),
            update_url: None,
            server_status: language.text(TextKey::WaitingRefresh).to_owned(),
            config_status: String::new(),
            group_name: match language {
                GuiLanguage::ZhCn => "我的服务器".to_owned(),
                GuiLanguage::EnUs => "My servers".to_owned(),
            },
            server_address: String::new(),
            sourcebans_name: "SourceBans".to_owned(),
            sourcebans_url: String::new(),
            rcon_address: String::new(),
            rcon_password: String::new(),
            rcon_command_text: "status".to_owned(),
            rcon_output: String::new(),
            cvar_address: String::new(),
            cvar_password: String::new(),
            cvar_names: "hostname,sv_tags,mp_gamemode".to_owned(),
            cvar_output: String::new(),
            player_output: String::new(),
            ui_search_query: String::new(),
            ui_filter_empty: false,
            ui_filter_has_players: false,
            ui_filter_hide_timeout: false,
            save_rcon_password: false,
            cvar_search_query: String::new(),
            global_player_search_query: String::new(),
            global_players: Vec::new(),
            global_players_status: String::new(),
            global_players_querying: false,
            selected_server_players: Vec::new(),
            api_base_url: initial_config.api.base_url,
            api_token: initial_config.api.token.unwrap_or_default(),
            api_user: None,
            api_status: String::new(),
            steam_login_in_progress: false,
            broadcast_message: String::new(),
            broadcast_output: String::new(),
            broadcast_sending: false,
        };
        app.config_status = app.language.config_file_status(&app.config_path);
        app.refresh_config_lists();
        app.refresh_servers();
        if !app.api_token.trim().is_empty() {
            app.refresh_api_user();
        }
        if app.updater_auto_check {
            app.check_updates();
        }
        app
    }

    fn handle_messages(&mut self, ctx: &egui::Context) {
        while let Ok(message) = self.rx.try_recv() {
            match message {
                GuiMessage::Servers(result) => match result {
                    Ok(rows) => {
                        self.server_status = self.language.server_count_status(rows.len());
                        self.servers = rows;
                        self.sort_gui_servers();
                    }
                    Err(err) => self.server_status = self.language.refresh_failed_status(&err),
                },
                GuiMessage::ServerUpdate(address, result) => {
                    if let Some(row) = self.servers.iter_mut().find(|r| r.address == address) {
                        match result {
                            Ok(new_payload) => {
                                row.ping_ms = new_payload.ping_ms;
                                row.info = new_payload.info;
                                row.error = new_payload.error;
                            }
                            Err(err) => {
                                row.error = Some(err);
                            }
                        }
                        row.last_queried = Some(std::time::Instant::now());
                    }
                },
                GuiMessage::ConfigLists(result) => match result {
                    Ok(lists) => {
                        self.manual_servers = lists.manual_servers;
                        self.sourcebans_entries = lists.sourcebans;
                        if self
                            .selected_sourcebans
                            .is_some_and(|index| index >= self.sourcebans_entries.len())
                        {
                            self.selected_sourcebans = None;
                        }
                    }
                    Err(err) => {
                        self.config_status = self.language.refresh_failed_status(&err);
                    }
                },
                GuiMessage::AddServer(result) => match result {
                    Ok(()) => {
                        self.config_status = self.language.text(TextKey::ServerSaved).to_owned();
                        self.refresh_config_lists();
                        self.refresh_servers();
                    }
                    Err(err) => {
                        self.config_status = self.language.save_server_failed_status(&err);
                    }
                },
                GuiMessage::AddSourceBans(result) => match result {
                    Ok(()) => {
                        self.config_status =
                            self.language.text(TextKey::SubscriptionSaved).to_owned();
                        self.refresh_config_lists();
                        self.refresh_servers();
                    }
                    Err(err) => {
                        self.config_status = self.language.save_subscription_failed_status(&err);
                    }
                },
                GuiMessage::UpdateSourceBans(result) => match result {
                    Ok(()) => {
                        self.config_status =
                            self.language.text(TextKey::SubscriptionSaved).to_owned();
                        self.refresh_config_lists();
                        self.refresh_servers();
                    }
                    Err(err) => {
                        self.config_status = self.language.save_subscription_failed_status(&err);
                    }
                },
                GuiMessage::DeleteSourceBans(result) => match result {
                    Ok(()) => {
                        self.config_status =
                            self.language.text(TextKey::SubscriptionDeleted).to_owned();
                        self.selected_sourcebans = None;
                        self.sourcebans_name.clear();
                        self.sourcebans_url.clear();
                        self.refresh_config_lists();
                        self.refresh_servers();
                    }
                    Err(err) => {
                        self.config_status = self.language.delete_subscription_failed_status(&err);
                    }
                },
                GuiMessage::DeleteServer(result) => match result {
                    Ok(()) => {
                        self.config_status = match self.language {
                            GuiLanguage::ZhCn => "服务器已删除".to_owned(),
                            GuiLanguage::EnUs => "Server deleted".to_owned(),
                        };
                        self.refresh_config_lists();
                        self.refresh_servers();
                    }
                    Err(err) => {
                        self.config_status = match self.language {
                            GuiLanguage::ZhCn => format!("删除服务器失败: {}", err),
                            GuiLanguage::EnUs => format!("Failed to delete server: {}", err),
                        };
                    }
                },
                GuiMessage::UpdateCheck(result) => match result {
                    Ok(info) => {
                        self.update_url = Some(info.html_url);
                        self.update_status = if info.available {
                            self.language.update_available_status(&info.latest_version)
                        } else {
                            self.language.up_to_date_status()
                        };
                    }
                    Err(err) => {
                        self.update_url = None;
                        self.update_status = self.language.update_check_failed_status(&err);
                    }
                },
                GuiMessage::Rcon(result) => {
                    self.rcon_output =
                        result.unwrap_or_else(|err| self.language.rcon_failed_output(&err));
                }
                GuiMessage::Cvars(result) => {
                    self.cvar_output = match result {
                        Ok(payload) => format_cvar_payload(&payload),
                        Err(err) => self.language.cvar_failed_output(&err),
                    };
                }
                GuiMessage::Players(result) => match result {
                    Ok((players, stats_ok)) => {
                        self.selected_server_players = players.clone();
                        self.player_output = format_player_payload(&players, self.language);
                        if !stats_ok && !players.is_empty() {
                            self.player_output.push_str(match self.language {
                                GuiLanguage::ZhCn => "\n⚠ 积分数据获取失败",
                                GuiLanguage::EnUs => "\n⚠ Failed to fetch player stats",
                            });
                        }
                    }
                    Err(err) => {
                        self.selected_server_players.clear();
                        self.player_output = err;
                    }
                },
                GuiMessage::GlobalPlayers(result) => {
                    self.global_players_querying = false;
                    match result {
                        Ok((players, stats_ok)) => {
                            self.global_players = players;
                            let active_servers_count = self
                                .global_players
                                .iter()
                                .map(|p| &p.server_address)
                                .collect::<std::collections::HashSet<_>>()
                                .len();
                            self.global_players_status = match self.language {
                                GuiLanguage::ZhCn => format!(
                                    "共 {} 个在线玩家，分布在 {} 个服务器",
                                    self.global_players.len(),
                                    active_servers_count
                                ),
                                GuiLanguage::EnUs => format!(
                                    "{} players online across {} servers",
                                    self.global_players.len(),
                                    active_servers_count
                                ),
                            };
                            if !stats_ok && !self.global_players.is_empty() {
                                self.global_players_status.push_str(match self.language {
                                    GuiLanguage::ZhCn => " | ⚠ 积分数据获取失败",
                                    GuiLanguage::EnUs => " | ⚠ Stats fetch failed",
                                });
                            }
                        }
                        Err(err) => {
                            self.global_players.clear();
                            self.global_players_status = match self.language {
                                GuiLanguage::ZhCn => format!("抓取玩家失败: {}", err),
                                GuiLanguage::EnUs => format!("Failed to query players: {}", err),
                            };
                        }
                    }
                }
                GuiMessage::ApiMe(result) => match result {
                    Ok(user) => {
                        self.api_status = match self.language {
                            GuiLanguage::ZhCn => format!(
                                "已登录：{}{}",
                                user.name,
                                if user.is_admin { "（管理员）" } else { "" }
                            ),
                            GuiLanguage::EnUs => format!(
                                "Logged in: {}{}",
                                user.name,
                                if user.is_admin { " (admin)" } else { "" }
                            ),
                        };
                        self.api_user = Some(user);
                    }
                    Err(err) => {
                        self.api_user = None;
                        self.api_status = err;
                    }
                },
                GuiMessage::SteamLoginStarted(result) => match result {
                    Ok(start) => {
                        self.api_status = match self.language {
                            GuiLanguage::ZhCn => format!(
                                "已打开 Steam 授权页面，登录码：{}，等待授权...",
                                start.user_code
                            ),
                            GuiLanguage::EnUs => format!(
                                "Opened Steam authorization page, code: {}, waiting...",
                                start.user_code
                            ),
                        };
                        ctx.open_url(egui::OpenUrl::new_tab(start.verification_url));
                    }
                    Err(err) => {
                        self.steam_login_in_progress = false;
                        self.api_status = err;
                    }
                },
                GuiMessage::SteamLoginFinished(result) => {
                    self.steam_login_in_progress = false;
                    match result {
                        Ok(session) => {
                            self.api_token = session.token;
                            self.api_user = Some(session.user.clone());
                            if let Err(err) = save_api_config_to_config(
                                &self.config_path,
                                &self.api_base_url,
                                Some(&self.api_token),
                            ) {
                                self.api_status = err;
                            } else {
                                self.api_status = match self.language {
                                    GuiLanguage::ZhCn => format!(
                                        "Steam 登录成功：{}{}",
                                        session.user.name,
                                        if session.user.is_admin {
                                            "（管理员）"
                                        } else {
                                            ""
                                        }
                                    ),
                                    GuiLanguage::EnUs => format!(
                                        "Steam login succeeded: {}{}",
                                        session.user.name,
                                        if session.user.is_admin {
                                            " (admin)"
                                        } else {
                                            ""
                                        }
                                    ),
                                };
                            }
                        }
                        Err(err) => {
                            self.api_status = err;
                        }
                    }
                }
                GuiMessage::Broadcast(result) => {
                    self.broadcast_sending = false;
                    self.broadcast_output = match result {
                        Ok(response) if response.ok => match self.language {
                            GuiLanguage::ZhCn => format!(
                                "已写入全服消息队列 #{}：{}",
                                response.id.unwrap_or_default(),
                                response.message.unwrap_or_default()
                            ),
                            GuiLanguage::EnUs => format!(
                                "Broadcast queued #{}: {}",
                                response.id.unwrap_or_default(),
                                response.message.unwrap_or_default()
                            ),
                        },
                        Ok(response) => response
                            .error
                            .or(response.message)
                            .unwrap_or_else(|| "broadcast failed".to_owned()),
                        Err(err) => err,
                    };
                }
            }
            ctx.request_repaint();
        }
    }

    fn refresh_servers(&mut self) {
        self.server_status = self.language.text(TextKey::Querying).to_owned();
        let tx = self.tx.clone();
        let cli = self.cli.clone();
        let config_path = self.config_path.clone();
        thread::spawn(move || {
            let result = load_config_or_default(&config_path)
                .and_then(|config| build_runtime(&cli, config))
                .and_then(|(settings, manual_groups, subscriptions)| {
                    load_server_rows(&settings, &manual_groups, &subscriptions)
                })
                .map(|rows| server_rows_payload(&rows));
            let _ = tx.send(GuiMessage::Servers(result));
        });
    }

    fn refresh_global_players(&mut self) {
        if self.global_players_querying {
            return;
        }
        self.global_players_querying = true;
        self.global_players_status = match self.language {
            GuiLanguage::ZhCn => "正在获取全服在线玩家数据...".to_owned(),
            GuiLanguage::EnUs => "Querying all server players...".to_owned(),
        };
        self.global_players.clear();

        let tx = self.tx.clone();
        let servers_to_query = self
            .servers
            .iter()
            .filter(|row| row.info.is_some())
            .map(|row| {
                let name = row
                    .info
                    .as_ref()
                    .map(|i| i.name.clone())
                    .unwrap_or_default();
                (row.address.clone(), name)
            })
            .collect::<Vec<_>>();

        let api_base_url = self.api_base_url.clone();

        thread::spawn(move || {
            if servers_to_query.is_empty() {
                let _ = tx.send(GuiMessage::GlobalPlayers(Ok((Vec::new(), true))));
                return;
            }

            let queue = Arc::new(Mutex::new(VecDeque::from(servers_to_query)));
            let results = Arc::new(Mutex::new(Vec::new()));
            let mut workers = Vec::new();

            for _ in 0..16 {
                let queue = Arc::clone(&queue);
                let results = Arc::clone(&results);
                let worker = thread::spawn(move || loop {
                    let item = {
                        let mut q = queue.lock().unwrap();
                        q.pop_front()
                    };
                    let Some((addr_str, server_name)) = item else {
                        break;
                    };

                    if let Ok(socket_addr) = resolve_endpoint(&addr_str) {
                        if let Ok(players) =
                            query_server_players(socket_addr.socket, Duration::from_millis(2500))
                        {
                            let mut res = results.lock().unwrap();
                            for p in players {
                                if !p.name.trim().is_empty() {
                                    res.push(GlobalPlayerEntry {
                                        name: p.name,
                                        score: p.score,
                                        duration: p.duration,
                                        server_name: server_name.clone(),
                                        server_address: addr_str.clone(),
                                        points: None,
                                        playtime_mins: None,
                                        ppm: None,
                                        quarter_points: None,
                                    });
                                }
                            }
                        }
                    }
                });
                workers.push(worker);
            }

            for w in workers {
                let _ = w.join();
            }

            let mut final_results = Arc::try_unwrap(results).unwrap().into_inner().unwrap();
            let stats_ok = enrich_global_players_with_api_stats(&api_base_url, &mut final_results);
            final_results.sort_by(|a, b| {
                b.duration
                    .partial_cmp(&a.duration)
                    .unwrap_or(std::cmp::Ordering::Equal)
            });
            let _ = tx.send(GuiMessage::GlobalPlayers(Ok((final_results, stats_ok))));
        });
    }

    fn refresh_config_lists(&mut self) {
        let tx = self.tx.clone();
        let config_path = self.config_path.clone();
        thread::spawn(move || {
            let result = load_gui_config_lists(&config_path);
            let _ = tx.send(GuiMessage::ConfigLists(result));
        });
    }

    fn refresh_api_user(&mut self) {
        if self.api_token.trim().is_empty() {
            return;
        }

        let tx = self.tx.clone();
        let base_url = self.api_base_url.clone();
        let token = self.api_token.clone();
        thread::spawn(move || {
            let result = api_me(&base_url, &token);
            let _ = tx.send(GuiMessage::ApiMe(result));
        });
    }

    fn start_steam_login(&mut self) {
        if self.steam_login_in_progress {
            return;
        }

        self.steam_login_in_progress = true;
        self.api_status = match self.language {
            GuiLanguage::ZhCn => "正在创建 Steam 登录请求...".to_owned(),
            GuiLanguage::EnUs => "Creating Steam login request...".to_owned(),
        };
        let tx = self.tx.clone();
        let request = ApiLoginRequest {
            base_url: self.api_base_url.clone(),
        };
        thread::spawn(move || {
            let result = steam_device_login(request, tx.clone());
            let _ = tx.send(GuiMessage::SteamLoginFinished(result));
        });
    }

    fn logout_api(&mut self) {
        let old_token = self.api_token.clone();
        self.api_token.clear();
        self.api_user = None;
        self.api_status = match self.language {
            GuiLanguage::ZhCn => "已退出登录".to_owned(),
            GuiLanguage::EnUs => "Logged out".to_owned(),
        };
        let _ = save_api_config_to_config(&self.config_path, &self.api_base_url, None);
        if !old_token.trim().is_empty() {
            let base_url = self.api_base_url.clone();
            thread::spawn(move || {
                let _ = api_logout(&base_url, &old_token);
            });
        }
    }

    fn send_broadcast(&mut self) {
        if self.broadcast_sending {
            return;
        }
        if self.api_token.trim().is_empty() {
            self.broadcast_output = match self.language {
                GuiLanguage::ZhCn => "请先 Steam 登录。".to_owned(),
                GuiLanguage::EnUs => "Please login with Steam first.".to_owned(),
            };
            return;
        }

        self.broadcast_sending = true;
        self.broadcast_output = self.language.text(TextKey::RunningCommand).to_owned();
        let tx = self.tx.clone();
        let request = BroadcastRequest {
            base_url: self.api_base_url.clone(),
            token: self.api_token.clone(),
            message: self.broadcast_message.clone(),
        };
        thread::spawn(move || {
            let result = api_broadcast(request);
            let _ = tx.send(GuiMessage::Broadcast(result));
        });
    }

    fn save_server(&mut self) {
        self.config_status = self.language.text(TextKey::SavingServer).to_owned();
        let tx = self.tx.clone();
        let path = self.config_path.clone();
        let input = AddServerRequest {
            group: self.group_name.clone(),
            server: self.server_address.clone(),
        };
        thread::spawn(move || {
            let result = add_server_to_config(&path, input);
            let _ = tx.send(GuiMessage::AddServer(result));
        });
    }

    fn delete_server(&mut self, group: String, server: String) {
        let tx = self.tx.clone();
        let path = self.config_path.clone();
        thread::spawn(move || {
            let result = delete_server_from_config(&path, &group, &server);
            let _ = tx.send(GuiMessage::DeleteServer(result));
        });
    }

    fn save_sourcebans(&mut self) {
        self.config_status = self.language.text(TextKey::SavingSubscription).to_owned();
        let tx = self.tx.clone();
        let path = self.config_path.clone();
        let input = AddSourceBansRequest {
            name: self.sourcebans_name.clone(),
            url: self.sourcebans_url.clone(),
        };
        thread::spawn(move || {
            let result = add_sourcebans_to_config(&path, input);
            let _ = tx.send(GuiMessage::AddSourceBans(result));
        });
    }

    fn update_sourcebans(&mut self) {
        let Some(index) = self.selected_sourcebans else {
            self.save_sourcebans();
            return;
        };

        self.config_status = self.language.text(TextKey::SavingSubscription).to_owned();
        let tx = self.tx.clone();
        let path = self.config_path.clone();
        let input = AddSourceBansRequest {
            name: self.sourcebans_name.clone(),
            url: self.sourcebans_url.clone(),
        };
        thread::spawn(move || {
            let result = update_sourcebans_in_config(&path, index, input);
            let _ = tx.send(GuiMessage::UpdateSourceBans(result));
        });
    }

    fn delete_sourcebans(&mut self) {
        let Some(index) = self.selected_sourcebans else {
            return;
        };

        let tx = self.tx.clone();
        let path = self.config_path.clone();
        thread::spawn(move || {
            let result = delete_sourcebans_from_config(&path, index);
            let _ = tx.send(GuiMessage::DeleteSourceBans(result));
        });
    }

    fn run_rcon(&mut self) {
        if self.rcon_address.trim().is_empty() {
            self.rcon_output = self.language.text(TextKey::NoServerSelected).to_owned();
            return;
        }

        self.rcon_output = self.language.text(TextKey::RunningCommand).to_owned();
        let tx = self.tx.clone();
        let input = RconCommandRequest {
            address: self.rcon_address.clone(),
            password: self.rcon_password.clone(),
            command: self.rcon_command_text.clone(),
            timeout_ms: Some(2500),
        };
        thread::spawn(move || {
            let timeout = Duration::from_millis(input.timeout_ms.unwrap_or(2500).max(1));
            let result = rcon_command(&input.address, &input.password, &input.command, timeout);
            let _ = tx.send(GuiMessage::Rcon(result));
        });
    }

    fn read_cvars(&mut self) {
        if self.cvar_address.trim().is_empty() {
            self.cvar_output = self.language.text(TextKey::NoServerSelected).to_owned();
            return;
        }

        self.cvar_output = self.language.text(TextKey::Reading).to_owned();
        let tx = self.tx.clone();
        let names = self
            .cvar_names
            .split(',')
            .map(|name| name.trim().to_owned())
            .filter(|name| !name.is_empty())
            .collect::<Vec<_>>();
        let input = CvarRequest {
            address: self.cvar_address.clone(),
            password: if self.cvar_password.trim().is_empty() {
                None
            } else {
                Some(self.cvar_password.clone())
            },
            names: Some(names),
            timeout_ms: Some(4500),
        };
        thread::spawn(move || {
            let result = read_cvars(input);
            let _ = tx.send(GuiMessage::Cvars(result));
        });
    }

    fn select_server(&mut self, address: String) {
        let changed = self.selected_server.as_deref() != Some(address.as_str());
        self.selected_server = Some(address.clone());
        self.rcon_address = address.clone();
        self.cvar_address = address;

        if changed {
            self.read_cvars();
            self.read_players();
        }
    }

    fn read_players(&mut self) {
        let Some(address) = self.selected_server.clone() else {
            self.player_output = self.language.text(TextKey::NoServerSelected).to_owned();
            return;
        };

        self.player_output = self.language.text(TextKey::Reading).to_owned();
        let tx = self.tx.clone();
        let api_base_url = self.api_base_url.clone();
        thread::spawn(move || {
            let result = resolve_endpoint(&address).and_then(|endpoint| {
                let mut players =
                    query_server_players(endpoint.socket, Duration::from_millis(4500))?;
                let stats_ok = enrich_players_with_api_stats(&api_base_url, &mut players);
                Ok((players, stats_ok))
            });

            let _ = tx.send(GuiMessage::Players(result));
        });
    }

    fn set_sort(&mut self, sort: SortKey) {
        if self.gui_sort == sort {
            self.gui_sort_desc = !self.gui_sort_desc;
        } else {
            self.gui_sort = sort;
            self.gui_sort_desc = matches!(sort, SortKey::Players);
        }
        self.sort_gui_servers();
    }

    fn sort_gui_servers(&mut self) {
        let sort = self.gui_sort;
        let desc = self.gui_sort_desc;
        self.servers.sort_by(|a, b| {
            let ordering = match sort {
                SortKey::Players => server_payload_players(a)
                    .cmp(&server_payload_players(b))
                    .then_with(|| server_payload_ping(a).cmp(&server_payload_ping(b))),
                SortKey::Ping => server_payload_ping(a)
                    .cmp(&server_payload_ping(b))
                    .then_with(|| server_payload_players(b).cmp(&server_payload_players(a))),
                SortKey::Name => server_payload_name(a).cmp(&server_payload_name(b)),
                SortKey::Map => server_payload_map(a).cmp(&server_payload_map(b)),
                SortKey::Address => a.address.cmp(&b.address),
                SortKey::Group => a.groups.join(",").cmp(&b.groups.join(",")),
            };
            if desc {
                ordering.reverse()
            } else {
                ordering
            }
        });
    }

    fn check_updates(&mut self) {
        self.update_status = self.language.text(TextKey::CheckingUpdates).to_owned();
        let tx = self.tx.clone();
        thread::spawn(move || {
            let result = check_latest_release();
            let _ = tx.send(GuiMessage::UpdateCheck(result));
        });
    }

    fn save_gui_language(&mut self) {
        match save_gui_language_to_config(&self.config_path, self.language) {
            Ok(()) => self.config_status = self.language.text(TextKey::LanguageSaved).to_owned(),
            Err(err) => self.config_status = self.language.save_language_failed_status(&err),
        }
    }

    fn save_updater_config(&mut self) {
        if let Err(err) = save_updater_config_to_config(&self.config_path, self.updater_auto_check)
        {
            self.update_status = self.language.update_check_failed_status(&err);
        }
    }

    fn text(&self, key: TextKey) -> &'static str {
        self.language.text(key)
    }
}

impl eframe::App for NativeGuiApp {
    fn update(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {
        self.handle_messages(ctx);

        let now = std::time::Instant::now();
        let mut servers_to_query = Vec::new();
        for row in &mut self.servers {
            let elapsed = row
                .last_queried
                .map(|t| now.duration_since(t).as_secs())
                .unwrap_or(u64::MAX);
            let is_populated = row.info.as_ref().map_or(false, |info| info.players > 0);

            let needs_update = if is_populated {
                elapsed >= 10
            } else {
                elapsed >= 60
            };

            if needs_update {
                row.last_queried = Some(now);
                servers_to_query.push(row.address.clone());
            }
        }

        for address in servers_to_query {
            let tx = self.tx.clone();
            thread::spawn(move || {
                if let Ok(endpoint) = resolve_endpoint(&address) {
                    let result = match query_server_info(endpoint.socket, Duration::from_millis(2500)) {
                        Ok((info, ping)) => Ok(ServerRowPayload {
                            address: address.clone(),
                            socket: endpoint.socket.to_string(),
                            groups: Vec::new(),
                            ping_ms: Some(ping.as_millis() as u64),
                            info: Some(info),
                            error: None,
                            last_queried: Some(std::time::Instant::now()),
                        }),
                        Err(err) => Err(err),
                    };
                    let _ = tx.send(GuiMessage::ServerUpdate(address, result));
                }
            });
        }

        ctx.request_repaint_after(Duration::from_secs(1));

        // 1. 顶部面板 Top Bar
        egui::TopBottomPanel::top("top_bar").show(ctx, |ui| {
            ui.horizontal(|ui| {
                ui.heading(self.text(TextKey::AppTitle));
                ui.separator();

                if ui.button(self.text(TextKey::RefreshServers)).clicked() {
                    self.refresh_servers();
                }

                ui.separator();

                ui.label(self.text(TextKey::Language));
                let mut selected_language = self.language;
                egui::ComboBox::from_id_salt("gui_language")
                    .selected_text(selected_language.display_name())
                    .show_ui(ui, |ui| {
                        for language in GuiLanguage::ALL {
                            ui.selectable_value(
                                &mut selected_language,
                                language,
                                language.display_name(),
                            );
                        }
                    });
                if selected_language != self.language {
                    self.language = selected_language;
                    self.save_gui_language();
                    ctx.send_viewport_cmd(egui::ViewportCommand::Title(
                        self.text(TextKey::AppTitle).to_owned(),
                    ));
                }

                ui.separator();
                ui.label(format!(
                    "{} {}",
                    self.text(TextKey::CurrentVersion),
                    env!("CARGO_PKG_VERSION")
                ));
                let auto_update_label = self.text(TextKey::AutoUpdate);
                if ui
                    .checkbox(&mut self.updater_auto_check, auto_update_label)
                    .changed()
                {
                    self.save_updater_config();
                }
                if ui.button(self.text(TextKey::CheckUpdates)).clicked() {
                    self.check_updates();
                }
                if let Some(url) = self.update_url.clone() {
                    if ui.button(self.text(TextKey::OpenDownloadPage)).clicked() {
                        ctx.open_url(egui::OpenUrl::new_tab(url));
                    }
                }
            });
            ui.horizontal(|ui| {
                ui.label(
                    egui::RichText::new(&self.config_status)
                        .size(11.0)
                        .color(egui::Color32::from_rgb(148, 163, 184)),
                );
                if !self.update_status.is_empty() {
                    ui.separator();
                    ui.label(
                        egui::RichText::new(&self.update_status)
                            .size(11.0)
                            .color(egui::Color32::from_rgb(234, 179, 8)),
                    );
                }
            });
        });

        // 2. 左侧导航面板 Sidebar Pane
        egui::SidePanel::left("navigation_panel")
            .resizable(false)
            .default_width(220.0)
            .show(ctx, |ui| {
                ui.vertical(|ui| {
                    ui.spacing_mut().item_spacing = egui::vec2(0.0, 10.0);
                    ui.add_space(8.0);

                    let servers_label = match self.language {
                        GuiLanguage::ZhCn => "🌐 服务器浏览器",
                        GuiLanguage::EnUs => "🌐 Server Browser",
                    };
                    if ui
                        .selectable_value(
                            &mut self.current_nav,
                            NavTab::Servers,
                            egui::RichText::new(servers_label).strong(),
                        )
                        .clicked()
                    {
                        // Clicked servers
                    }

                    let players_label = match self.language {
                        GuiLanguage::ZhCn => "👥 全服在线玩家",
                        GuiLanguage::EnUs => "👥 All Server Players",
                    };
                    if ui
                        .selectable_value(
                            &mut self.current_nav,
                            NavTab::GlobalPlayers,
                            egui::RichText::new(players_label).strong(),
                        )
                        .clicked()
                    {
                        self.refresh_global_players();
                    }

                    let broadcast_label = match self.language {
                        GuiLanguage::ZhCn => "📣 全服消息",
                        GuiLanguage::EnUs => "📣 Broadcast",
                    };
                    let _ = ui.selectable_value(
                        &mut self.current_nav,
                        NavTab::Broadcast,
                        egui::RichText::new(broadcast_label).strong(),
                    );

                    let add_server_label = match self.language {
                        GuiLanguage::ZhCn => "➕ 添加服务器",
                        GuiLanguage::EnUs => "➕ Add Server",
                    };
                    if ui
                        .selectable_value(
                            &mut self.current_nav,
                            NavTab::AddServer,
                            egui::RichText::new(add_server_label).strong(),
                        )
                        .clicked()
                    {
                        self.config_status = self.language.config_file_status(&self.config_path);
                    }

                    let sourcebans_label = match self.language {
                        GuiLanguage::ZhCn => "🔗 SourceBans 订阅",
                        GuiLanguage::EnUs => "🔗 SourceBans Sub",
                    };
                    if ui
                        .selectable_value(
                            &mut self.current_nav,
                            NavTab::SourceBans,
                            egui::RichText::new(sourcebans_label).strong(),
                        )
                        .clicked()
                    {
                        self.config_status = self.language.config_file_status(&self.config_path);
                    }

                    let settings_label = match self.language {
                        GuiLanguage::ZhCn => "⚙️ 首选项设置",
                        GuiLanguage::EnUs => "⚙️ Preferences",
                    };
                    let _ = ui.selectable_value(
                        &mut self.current_nav,
                        NavTab::Settings,
                        egui::RichText::new(settings_label).strong(),
                    );

                    let sponsor_label = match self.language {
                        GuiLanguage::ZhCn => "💖 赞赞赞助支持",
                        GuiLanguage::EnUs => "💖 Sponsor Anne",
                    };
                    ui.add_space(10.0);
                    if ui
                        .selectable_label(false, egui::RichText::new(sponsor_label).strong())
                        .clicked()
                    {
                        ctx.open_url(egui::OpenUrl::new_tab("https://anne.trygek.com/sponsor/"));
                    }
                });
            });

        // 3. 右侧属性面板 Inspector Pane
        let mut show_inspector = false;
        if self.current_nav == NavTab::Servers && self.selected_server.is_some() {
            show_inspector = true;
        }

        if show_inspector {
            let address = self.selected_server.clone().unwrap();
            egui::SidePanel::right("inspector_panel")
                .resizable(true)
                .default_width(450.0)
                .width_range(300.0..=650.0)
                .show(ctx, |ui| {
                    ui.vertical(|ui| {
                        ui.spacing_mut().item_spacing = egui::vec2(0.0, 8.0);

                        ui.heading(self.text(TextKey::SelectedServer));
                        ui.monospace(&address);

                        let connect_link = format!("steam://connect/{}", address);
                        if ui
                            .button(
                                egui::RichText::new(format!(
                                    "🎮 {}",
                                    self.text(TextKey::ConnectGame)
                                ))
                                .strong(),
                            )
                            .clicked()
                        {
                            ctx.open_url(egui::OpenUrl::same_tab(connect_link));
                        }

                        ui.separator();

                        let players_tab_label = self.text(TextKey::PlayerList);
                        let rcon_tab_label = self.text(TextKey::Rcon);
                        let cvars_tab_label = self.text(TextKey::CvarRules);
                        ui.horizontal(|ui| {
                            ui.selectable_value(
                                &mut self.inspector_tab,
                                InspectorTab::Players,
                                players_tab_label,
                            );
                            ui.selectable_value(
                                &mut self.inspector_tab,
                                InspectorTab::Rcon,
                                rcon_tab_label,
                            );
                            ui.selectable_value(
                                &mut self.inspector_tab,
                                InspectorTab::Cvars,
                                cvars_tab_label,
                            );
                        });
                        ui.separator();

                        match self.inspector_tab {
                            InspectorTab::Players => {
                                ui.horizontal(|ui| {
                                    ui.heading(self.text(TextKey::PlayerList));
                                    if ui.button(self.text(TextKey::RefreshPlayers)).clicked() {
                                        self.read_players();
                                    }
                                });

                                if self.selected_server_players.is_empty() {
                                    ui.add(egui::Label::new(
                                        egui::RichText::new(&self.player_output).monospace(),
                                    ));
                                } else {
                                    egui::ScrollArea::vertical().show(ui, |ui| {
                                        egui::Grid::new("selected_players_grid")
                                            .striped(true)
                                            .min_col_width(55.0)
                                            .show(ui, |ui| {
                                                ui.strong("#");
                                                ui.strong(match self.language {
                                                    GuiLanguage::ZhCn => "名字",
                                                    GuiLanguage::EnUs => "Name",
                                                });
                                                ui.strong(match self.language {
                                                    GuiLanguage::ZhCn => "本局分数",
                                                    GuiLanguage::EnUs => "Session Score",
                                                });
                                                ui.strong(match self.language {
                                                    GuiLanguage::ZhCn => "本局时间",
                                                    GuiLanguage::EnUs => "Session Time",
                                                });
                                                ui.strong(match self.language {
                                                    GuiLanguage::ZhCn => "总积分",
                                                    GuiLanguage::EnUs => "Total Points",
                                                });
                                                ui.strong(match self.language {
                                                    GuiLanguage::ZhCn => "总时长",
                                                    GuiLanguage::EnUs => "Total Time",
                                                });
                                                ui.strong("PPM");
                                                ui.strong(match self.language {
                                                    GuiLanguage::ZhCn => "季度分",
                                                    GuiLanguage::EnUs => "Quarter",
                                                });
                                                ui.end_row();

                                                for p in &self.selected_server_players {
                                                    ui.label(p.index.to_string());
                                                    ui.label(&p.name);
                                                    ui.label(format_optional_number(Some(p.score)));
                                                    ui.label(format_duration_seconds(p.duration));
                                                    ui.label(format_optional_number(p.points));
                                                    ui.label(format_playtime_minutes(
                                                        p.playtime_mins,
                                                        self.language,
                                                    ));
                                                    ui.label(
                                                        p.ppm
                                                            .map(|ppm| format!("{ppm:.2}"))
                                                            .unwrap_or_else(|| "-".to_owned()),
                                                    );
                                                    ui.label(format_optional_number(
                                                        p.quarter_points,
                                                    ));
                                                    ui.end_row();
                                                }
                                            });
                                    });
                                }
                            }
                            InspectorTab::Rcon => {
                                ui.heading(self.text(TextKey::Rcon));
                                ui.label(self.text(TextKey::RconPassword));
                                ui.horizontal(|ui| {
                                    ui.add(
                                        egui::TextEdit::singleline(&mut self.rcon_password)
                                            .password(true)
                                            .desired_width(260.0),
                                    );
                                    ui.checkbox(
                                        &mut self.save_rcon_password,
                                        match self.language {
                                            GuiLanguage::ZhCn => "保存",
                                            GuiLanguage::EnUs => "Save",
                                        },
                                    );
                                });

                                ui.label(self.text(TextKey::Command));
                                ui.text_edit_singleline(&mut self.rcon_command_text);

                                ui.horizontal(|ui| {
                                    if ui
                                        .button(format!("⌨ {}", self.text(TextKey::RunCommand)))
                                        .clicked()
                                    {
                                        self.run_rcon();
                                    }
                                    if ui.button("status").clicked() {
                                        self.rcon_command_text = "status".to_owned();
                                        self.run_rcon();
                                    }
                                    if ui.button("meta list").clicked() {
                                        self.rcon_command_text = "meta list".to_owned();
                                        self.run_rcon();
                                    }
                                });

                                ui.separator();
                                egui::ScrollArea::vertical().show(ui, |ui| {
                                    ui.add(
                                        egui::TextEdit::multiline(&mut self.rcon_output)
                                            .desired_rows(15)
                                            .desired_width(f32::INFINITY)
                                            .code_editor(),
                                    );
                                });
                            }
                            InspectorTab::Cvars => {
                                ui.horizontal(|ui| {
                                    ui.heading(self.text(TextKey::CvarRules));
                                    if ui.button(self.text(TextKey::RefreshRules)).clicked() {
                                        self.read_cvars();
                                    }
                                });

                                ui.label(self.text(TextKey::OptionalRconPassword));
                                ui.add(
                                    egui::TextEdit::singleline(&mut self.cvar_password)
                                        .password(true)
                                        .desired_width(ui.available_width()),
                                );
                                ui.label(self.text(TextKey::CvarNamesHelp));
                                ui.add(
                                    egui::TextEdit::singleline(&mut self.cvar_names)
                                        .desired_width(ui.available_width()),
                                );

                                ui.separator();

                                let cvar_search_placeholder =
                                    self.text(TextKey::CvarSearchPlaceholder);
                                ui.horizontal(|ui| {
                                    ui.label("🔍");
                                    ui.add(
                                        egui::TextEdit::singleline(&mut self.cvar_search_query)
                                            .hint_text(cvar_search_placeholder)
                                            .desired_width(ui.available_width()),
                                    );
                                });

                                let mut kv_pairs = Vec::new();
                                for line in self.cvar_output.lines() {
                                    if let Some(pos) = line.find(" = ") {
                                        let key = line[..pos].trim();
                                        let val = line[pos + 3..].trim();
                                        kv_pairs.push((key, val));
                                    } else {
                                        kv_pairs.push(("", line));
                                    }
                                }

                                if !self.cvar_search_query.trim().is_empty() {
                                    let query = self.cvar_search_query.to_lowercase();
                                    kv_pairs.retain(|(k, v)| {
                                        k.to_lowercase().contains(&query)
                                            || v.to_lowercase().contains(&query)
                                    });
                                }

                                egui::ScrollArea::vertical().show(ui, |ui| {
                                    egui::Grid::new("cvars_table_grid")
                                        .striped(true)
                                        .min_col_width(80.0)
                                        .show(ui, |ui| {
                                            for (k, v) in kv_pairs {
                                                if k.is_empty() {
                                                    ui.add(egui::Label::new(
                                                        egui::RichText::new(v).color(
                                                            egui::Color32::from_rgb(148, 163, 184),
                                                        ),
                                                    ));
                                                    ui.label("");
                                                } else {
                                                    ui.label(egui::RichText::new(k).strong());
                                                    ui.monospace(v);
                                                }
                                                ui.end_row();
                                            }
                                        });
                                });
                            }
                        }
                    });
                });
        }

        // 4. 中央面板 Central Panel
        egui::CentralPanel::default().show(ctx, |ui| {
            match self.current_nav {
                NavTab::Servers => {
                    let total_servers = self.servers.len();
                    let mut active_players = 0;
                    let mut total_slots = 0;
                    let mut low_ping_count = 0;

                    for s in &self.servers {
                        if let Some(info) = &s.info {
                            active_players += info.players as usize;
                            total_slots += info.max_players as usize;
                        }
                        if let Some(ping) = s.ping_ms {
                            if ping < 50 {
                                low_ping_count += 1;
                            }
                        }
                    }

                    ui.horizontal(|ui| {
                        ui.spacing_mut().item_spacing = egui::vec2(16.0, 0.0);

                        egui::Frame::canvas(ui.style())
                            .fill(egui::Color32::from_rgb(17, 24, 39))
                            .stroke(egui::Stroke::new(1.0, egui::Color32::from_rgb(31, 41, 55)))
                            .corner_radius(egui::CornerRadius::same(8))
                            .inner_margin(egui::Margin::symmetric(14, 10))
                            .show(ui, |ui| {
                                ui.vertical(|ui| {
                                    ui.label(egui::RichText::new(self.text(TextKey::ActivePlayers)).size(11.0).color(egui::Color32::from_rgb(148, 163, 184)));
                                    ui.heading(egui::RichText::new(format!("{active_players} / {total_slots}")).size(18.0).strong().color(egui::Color32::from_rgb(248, 250, 252)));
                                });
                            });

                        egui::Frame::canvas(ui.style())
                            .fill(egui::Color32::from_rgb(17, 24, 39))
                            .stroke(egui::Stroke::new(1.0, egui::Color32::from_rgb(31, 41, 55)))
                            .corner_radius(egui::CornerRadius::same(8))
                            .inner_margin(egui::Margin::symmetric(14, 10))
                            .show(ui, |ui| {
                                ui.vertical(|ui| {
                                    ui.label(egui::RichText::new(self.text(TextKey::TotalServers)).size(11.0).color(egui::Color32::from_rgb(148, 163, 184)));
                                    ui.heading(egui::RichText::new(format!("{total_servers}")).size(18.0).strong().color(egui::Color32::from_rgb(248, 250, 252)));
                                });
                            });

                        egui::Frame::canvas(ui.style())
                            .fill(egui::Color32::from_rgb(17, 24, 39))
                            .stroke(egui::Stroke::new(1.0, egui::Color32::from_rgb(31, 41, 55)))
                            .corner_radius(egui::CornerRadius::same(8))
                            .inner_margin(egui::Margin::symmetric(14, 10))
                            .show(ui, |ui| {
                                ui.vertical(|ui| {
                                    let low_ping_label = match self.language {
                                        GuiLanguage::ZhCn => "低延迟 (≤50ms)",
                                        GuiLanguage::EnUs => "Low Ping (≤50ms)",
                                    };
                                    ui.label(egui::RichText::new(low_ping_label).size(11.0).color(egui::Color32::from_rgb(148, 163, 184)));
                                    ui.heading(egui::RichText::new(format!("{low_ping_count}")).size(18.0).strong().color(egui::Color32::from_rgb(34, 197, 94)));
                                });
                            });
                    });

                    ui.add_space(8.0);

                    let search_placeholder = self.text(TextKey::SearchPlaceholder);
                    let filter_has_players_label = self.text(TextKey::FilterHasPlayers);
                    let filter_empty_label = self.text(TextKey::FilterEmpty);
                    let filter_hide_timeout_label = self.text(TextKey::FilterHideTimeout);
                    ui.horizontal(|ui| {
                        ui.label(egui::RichText::new("🔍").size(15.0));
                        ui.add(
                            egui::TextEdit::singleline(&mut self.ui_search_query)
                                .hint_text(search_placeholder)
                                .desired_width(280.0),
                        );

                        ui.separator();

                        if ui
                            .checkbox(
                                &mut self.ui_filter_has_players,
                                filter_has_players_label,
                            )
                            .changed()
                            && self.ui_filter_has_players
                        {
                            self.ui_filter_empty = false;
                        }
                        if ui
                            .checkbox(&mut self.ui_filter_empty, filter_empty_label)
                            .changed()
                            && self.ui_filter_empty
                        {
                            self.ui_filter_has_players = false;
                        }
                        ui.checkbox(&mut self.ui_filter_hide_timeout, filter_hide_timeout_label);
                    });

                    ui.separator();

                    let mut filtered_servers = self.servers.clone();

                    if !self.ui_search_query.trim().is_empty() {
                        let query = self.ui_search_query.to_lowercase();
                        filtered_servers.retain(|row| {
                            let group_match = row.groups.iter().any(|g| g.to_lowercase().contains(&query));
                            let addr_match = row.address.to_lowercase().contains(&query);
                            let name_match = if let Some(info) = &row.info {
                                info.name.to_lowercase().contains(&query) || info.map.to_lowercase().contains(&query)
                            } else {
                                false
                            };
                            group_match || addr_match || name_match
                        });
                    }

                    if self.ui_filter_has_players {
                        filtered_servers.retain(|row| {
                            row.info.as_ref().map(|i| i.players > 0).unwrap_or(false)
                        });
                    }
                    if self.ui_filter_empty {
                        filtered_servers.retain(|row| {
                            row.info.as_ref().map(|i| i.players == 0).unwrap_or(false)
                        });
                    }
                    if self.ui_filter_hide_timeout {
                        filtered_servers.retain(|row| row.info.is_some());
                    }

                    ui.horizontal(|ui| {
                        ui.heading(self.text(TextKey::ServerList));
                        ui.label(format!("({})", self.language.server_count_status(filtered_servers.len())));
                    });

                    ui.add_space(4.0);

                    let mut clicked_server = None;

                    egui::ScrollArea::both()
                        .auto_shrink([false, false])
                        .show(ui, |ui| {
                            egui::Grid::new("servers_grid")
                                .striped(true)
                                .min_col_width(70.0)
                                .show(ui, |ui| {
                                    if ui.button(sort_label(self.text(TextKey::HeaderGroup), self.gui_sort, self.gui_sort_desc, SortKey::Group)).clicked() {
                                        self.set_sort(SortKey::Group);
                                    }
                                    if ui.button(sort_label(self.text(TextKey::HeaderAddress), self.gui_sort, self.gui_sort_desc, SortKey::Address)).clicked() {
                                        self.set_sort(SortKey::Address);
                                    }
                                    if ui.button(sort_label(self.text(TextKey::HeaderPing), self.gui_sort, self.gui_sort_desc, SortKey::Ping)).clicked() {
                                        self.set_sort(SortKey::Ping);
                                    }
                                    if ui.button(sort_label(self.text(TextKey::HeaderPlayers), self.gui_sort, self.gui_sort_desc, SortKey::Players)).clicked() {
                                        self.set_sort(SortKey::Players);
                                    }
                                    if ui.button(sort_label(self.text(TextKey::HeaderMap), self.gui_sort, self.gui_sort_desc, SortKey::Map)).clicked() {
                                        self.set_sort(SortKey::Map);
                                    }
                                    ui.strong(self.text(TextKey::HeaderVac));
                                    if ui.button(sort_label(self.text(TextKey::HeaderNameOrError), self.gui_sort, self.gui_sort_desc, SortKey::Name)).clicked() {
                                        self.set_sort(SortKey::Name);
                                    }
                                    ui.end_row();

                                    for row in &filtered_servers {
                                        let selected = self.selected_server.as_deref() == Some(row.address.as_str());
                                        let (players_text, fraction) = if let Some(info) = &row.info {
                                            let fraction = if info.max_players == 0 {
                                                0.0
                                            } else {
                                                info.players as f32 / info.max_players as f32
                                            };
                                            (format!("{}/{}", info.players, info.max_players), fraction)
                                        } else {
                                            ("-".to_owned(), 0.0)
                                        };

                                        let map = row.info.as_ref().map(|info| info.map.clone()).unwrap_or_else(|| "-".to_owned());

                                        let vac_text = if let Some(info) = &row.info {
                                            if info.vac { "🛡 Yes" } else { "No" }
                                        } else {
                                            "-"
                                        };
                                        let vac_color = if let Some(info) = &row.info {
                                            if info.vac { egui::Color32::from_rgb(34, 197, 94) } else { egui::Color32::from_rgb(148, 163, 184) }
                                        } else {
                                            egui::Color32::from_rgb(148, 163, 184)
                                        };

                                        let name = if let Some(info) = &row.info {
                                            info.name.clone()
                                        } else {
                                            row.error.clone().unwrap_or_else(|| self.text(TextKey::NotQueried).to_owned())
                                        };

                                        let ping_text = row.ping_ms.map(|v| format!("{v} ms")).unwrap_or_else(|| "超时".to_owned());
                                        let ping_color = match row.ping_ms {
                                            None => egui::Color32::from_rgb(239, 68, 68),
                                            Some(ping) => {
                                                if ping < 50 {
                                                    egui::Color32::from_rgb(34, 197, 94)
                                                } else if ping < 120 {
                                                    egui::Color32::from_rgb(234, 179, 8)
                                                } else {
                                                    egui::Color32::from_rgb(249, 115, 22)
                                                }
                                            }
                                        };

                                        let mut row_clicked = ui.selectable_label(selected, row.groups.join(",")).clicked();

                                        row_clicked |= ui.add(egui::Label::new(egui::RichText::new(&row.address).monospace()).sense(egui::Sense::click())).clicked();

                                        row_clicked |= ui.add(egui::Label::new(egui::RichText::new(ping_text).color(ping_color)).sense(egui::Sense::click())).clicked();

                                        let player_color = if fraction >= 0.8 {
                                            egui::Color32::from_rgb(249, 115, 22)
                                        } else if fraction > 0.0 {
                                            egui::Color32::from_rgb(34, 197, 94)
                                        } else {
                                            egui::Color32::from_rgb(148, 163, 184)
                                        };
                                        row_clicked |= ui
                                            .add(
                                                egui::Label::new(
                                                    egui::RichText::new(players_text)
                                                        .color(player_color),
                                                )
                                                .sense(egui::Sense::click()),
                                            )
                                            .clicked();

                                        row_clicked |= ui.add(egui::Label::new(egui::RichText::new(map)).sense(egui::Sense::click())).clicked();

                                        row_clicked |= ui.add(egui::Label::new(egui::RichText::new(vac_text).color(vac_color)).sense(egui::Sense::click())).clicked();

                                        row_clicked |= ui.add(egui::Label::new(egui::RichText::new(name)).sense(egui::Sense::click())).clicked();

                                        if row_clicked {
                                            clicked_server = Some(row.address.clone());
                                        }
                                        ui.end_row();
                                    }
                                });
                        });

                    if let Some(address) = clicked_server {
                        self.select_server(address);
                    }
                }
                NavTab::GlobalPlayers => {
                    ui.horizontal(|ui| {
                        ui.heading(self.text(TextKey::GlobalPlayersTab));
                        if ui.button(self.text(TextKey::RefreshPlayers)).clicked() {
                            self.refresh_global_players();
                        }
                    });

                    ui.label(&self.global_players_status);

                    ui.separator();

                    let global_player_search_placeholder =
                        self.text(TextKey::GlobalPlayerSearchPlaceholder);
                    ui.horizontal(|ui| {
                        ui.label("🔍");
                        ui.add(
                            egui::TextEdit::singleline(&mut self.global_player_search_query)
                                .hint_text(global_player_search_placeholder)
                                .desired_width(280.0),
                        );
                    });

                    let mut filtered_players = self.global_players.clone();
                    if !self.global_player_search_query.trim().is_empty() {
                        let query = self.global_player_search_query.to_lowercase();
                        filtered_players.retain(|p| {
                            p.name.to_lowercase().contains(&query) || p.server_name.to_lowercase().contains(&query)
                        });
                    }

                    ui.horizontal_top(|ui| {
                        ui.vertical(|ui| {
                            ui.set_width(240.0);
                            egui::Frame::canvas(ui.style())
                                .fill(egui::Color32::from_rgb(17, 24, 39))
                                .stroke(egui::Stroke::new(1.0, egui::Color32::from_rgb(31, 41, 55)))
                                .corner_radius(egui::CornerRadius::same(8))
                                .inner_margin(egui::Margin::same(16))
                                .show(ui, |ui| {
                                    ui.vertical(|ui| {
                                        ui.label(egui::RichText::new("全服在线玩家统计").strong().size(14.0));
                                        ui.add_space(8.0);

                                        ui.label(format!("全服在线玩家总数: {}", self.global_players.len()));

                                        let active_servers_count = self.global_players.iter()
                                            .map(|p| &p.server_address)
                                            .collect::<std::collections::HashSet<_>>()
                                            .len();
                                        ui.label(format!("有玩家的服务器数: {active_servers_count}"));

                                        ui.add_space(10.0);
                                        ui.label(egui::RichText::new("提示：在右侧列表选中玩家后，可查看玩家所在服务器并一键连入！").size(11.0).color(egui::Color32::from_rgb(148, 163, 184)));
                                    });
                                });
                        });

                        ui.add_space(16.0);

                        ui.vertical(|ui| {
                            egui::ScrollArea::both().id_salt("global_players_table_scroll").show(ui, |ui| {
                                egui::Grid::new("global_players_table_grid")
                                    .striped(true)
                                        .min_col_width(65.0)
                                        .show(ui, |ui| {
                                            ui.strong(match self.language { GuiLanguage::ZhCn => "玩家昵称", GuiLanguage::EnUs => "Player Name" });
                                            ui.strong(match self.language { GuiLanguage::ZhCn => "本局分数", GuiLanguage::EnUs => "Session Score" });
                                            ui.strong(match self.language { GuiLanguage::ZhCn => "本局时间", GuiLanguage::EnUs => "Session Time" });
                                            ui.strong(match self.language { GuiLanguage::ZhCn => "总积分", GuiLanguage::EnUs => "Total Points" });
                                            ui.strong(match self.language { GuiLanguage::ZhCn => "总时长", GuiLanguage::EnUs => "Total Time" });
                                        ui.strong("PPM");
                                        ui.strong(match self.language { GuiLanguage::ZhCn => "季度分", GuiLanguage::EnUs => "Quarter" });
                                        ui.strong(match self.language { GuiLanguage::ZhCn => "所在服务器", GuiLanguage::EnUs => "Server" });
                                        ui.end_row();

                                        for p in &filtered_players {
                                            ui.label(egui::RichText::new(&p.name).strong());
                                            ui.label(format_optional_number(Some(p.score)));
                                            ui.label(format_duration_seconds(p.duration));

                                            ui.label(format_optional_number(p.points));

                                            ui.label(format_playtime_minutes(p.playtime_mins, self.language));

                                            let ppm_str = match p.ppm {
                                                Some(val) => format!("{val:.2}"),
                                                None => "-".to_owned(),
                                            };
                                            ui.label(ppm_str);
                                            ui.label(format_optional_number(p.quarter_points));

                                            let connect_link = format!("steam://connect/{}", p.server_address);
                                            let btn = egui::Button::new(format!("🎮 {}", p.server_name)).frame(false);
                                            if ui.add(btn).on_hover_text(format!("双击或点击连入：{}", p.server_address)).clicked() {
                                                ctx.open_url(egui::OpenUrl::same_tab(connect_link));
                                            }
                                            ui.end_row();
                                        }
                                    });
                            });
                        });
                    });
                }
                NavTab::Broadcast => {
                    ui.heading(self.text(TextKey::BroadcastTab));
                    ui.horizontal(|ui| {
                        ui.label(self.text(TextKey::ApiBaseUrl));
                        let response = ui.add(
                            egui::TextEdit::singleline(&mut self.api_base_url)
                                .desired_width(320.0),
                        );
                        if response.changed() {
                            let _ = save_api_config_to_config(
                                &self.config_path,
                                &self.api_base_url,
                                if self.api_token.trim().is_empty() {
                                    None
                                } else {
                                    Some(&self.api_token)
                                },
                            );
                        }
                    });

                    ui.horizontal(|ui| {
                        if ui
                            .add_enabled(
                                !self.steam_login_in_progress,
                                egui::Button::new(self.text(TextKey::SteamLogin)),
                            )
                            .clicked()
                        {
                            self.start_steam_login();
                        }
                        if ui
                            .add_enabled(
                                !self.api_token.trim().is_empty(),
                                egui::Button::new(self.text(TextKey::Logout)),
                            )
                            .clicked()
                        {
                            self.logout_api();
                        }
                    });

                    if let Some(user) = &self.api_user {
                        ui.label(match self.language {
                            GuiLanguage::ZhCn => format!(
                                "当前账号：{} / {}{}",
                                user.name,
                                user.steam_id,
                                if user.is_admin { " / 管理员" } else { "" }
                            ),
                            GuiLanguage::EnUs => format!(
                                "Current user: {} / {}{}",
                                user.name,
                                user.steam_id,
                                if user.is_admin { " / admin" } else { "" }
                            ),
                        });
                    }
                    if !self.api_status.is_empty() {
                        ui.label(&self.api_status);
                    }

                    ui.separator();
                    ui.label(self.text(TextKey::BroadcastMessage));
                    ui.add(
                        egui::TextEdit::multiline(&mut self.broadcast_message)
                            .desired_rows(4)
                            .desired_width(f32::INFINITY),
                    );
                    if ui
                        .add_enabled(
                            !self.broadcast_sending,
                            egui::Button::new(self.text(TextKey::SendBroadcast)),
                        )
                        .clicked()
                    {
                        self.send_broadcast();
                    }

                    ui.separator();
                    ui.add(
                        egui::TextEdit::multiline(&mut self.broadcast_output)
                            .desired_rows(10)
                            .desired_width(f32::INFINITY)
                            .code_editor(),
                    );
                }
                NavTab::AddServer => {
                    ui.heading(self.text(TextKey::AddServer));
                    ui.horizontal(|ui| {
                        ui.label(self.text(TextKey::Group));
                        ui.add(egui::TextEdit::singleline(&mut self.group_name).desired_width(120.0));
                        ui.label(self.text(TextKey::ServerAddress));
                        ui.add(egui::TextEdit::singleline(&mut self.server_address).desired_width(200.0));
                        if ui.button(self.text(TextKey::SaveServer)).clicked() {
                            self.save_server();
                        }
                    });

                    ui.separator();
                    ui.heading(self.text(TextKey::ManualServerList));

                    egui::ScrollArea::vertical().show(ui, |ui| {
                        if self.manual_servers.is_empty() {
                            ui.label("-");
                        } else {
                            let mut delete_entry: Option<(String, String)> = None;
                            egui::Grid::new("manual_servers_grid")
                                .striped(true)
                                .min_col_width(120.0)
                                .show(ui, |ui| {
                                    for entry in &self.manual_servers {
                                        ui.label(egui::RichText::new(&entry.group).strong());
                                        ui.monospace(&entry.server);
                                        if ui.button("❌").clicked() {
                                            delete_entry = Some((entry.group.clone(), entry.server.clone()));
                                        }
                                        ui.end_row();
                                    }
                                });
                            if let Some((group, server)) = delete_entry {
                                self.delete_server(group, server);
                            }
                        }
                    });
                }
                NavTab::SourceBans => {
                    ui.heading(self.text(TextKey::SubscriptionList));

                    let mut clicked_subscription = None;
                    for (index, subscription) in self.sourcebans_entries.iter().enumerate() {
                        let selected = self.selected_sourcebans == Some(index);
                        if ui.selectable_label(selected, &subscription.name).on_hover_text(&subscription.url).clicked() {
                            clicked_subscription = Some(index);
                        }
                    }

                    if let Some(index) = clicked_subscription {
                        self.selected_sourcebans = Some(index);
                        if let Some(subscription) = self.sourcebans_entries.get(index) {
                            self.sourcebans_name = subscription.name.clone();
                            self.sourcebans_url = subscription.url.clone();
                        }
                    }

                    ui.horizontal(|ui| {
                        if ui.button(self.text(TextKey::NewSubscription)).clicked() {
                            self.selected_sourcebans = None;
                            self.sourcebans_name = "SourceBans".to_owned();
                            self.sourcebans_url.clear();
                        }
                        if ui.add_enabled(self.selected_sourcebans.is_some(), egui::Button::new(self.text(TextKey::DeleteSubscription))).clicked() {
                            self.delete_sourcebans();
                        }
                    });

                    ui.separator();
                    ui.heading(self.text(TextKey::SourceBansSubscription));
                    ui.label(self.text(TextKey::SubscriptionName));
                    ui.text_edit_singleline(&mut self.sourcebans_name);
                    ui.label(self.text(TextKey::PageUrl));
                    ui.text_edit_singleline(&mut self.sourcebans_url);

                    let save_label = if self.selected_sourcebans.is_some() {
                        self.text(TextKey::UpdateSubscription)
                    } else {
                        self.text(TextKey::SaveSubscription)
                    };
                    if ui.button(save_label).clicked() {
                        self.update_sourcebans();
                    }
                }
                NavTab::Settings => {
                    ui.heading(self.text(TextKey::SettingsTab));
                    ui.label(&self.config_status);

                    ui.separator();

                    ui.horizontal(|ui| {
                        ui.label(self.text(TextKey::ApiBaseUrl));
                        if ui
                            .add(
                                egui::TextEdit::singleline(&mut self.api_base_url)
                                    .desired_width(320.0),
                            )
                            .changed()
                        {
                            let _ = save_api_config_to_config(
                                &self.config_path,
                                &self.api_base_url,
                                if self.api_token.trim().is_empty() {
                                    None
                                } else {
                                    Some(&self.api_token)
                                },
                            );
                        }
                    });
                    ui.horizontal(|ui| {
                        if ui
                            .add_enabled(
                                !self.steam_login_in_progress,
                                egui::Button::new(self.text(TextKey::SteamLogin)),
                            )
                            .clicked()
                        {
                            self.start_steam_login();
                        }
                        if ui
                            .add_enabled(
                                !self.api_token.trim().is_empty(),
                                egui::Button::new(self.text(TextKey::Logout)),
                            )
                            .clicked()
                        {
                            self.logout_api();
                        }
                    });
                    if !self.api_status.is_empty() {
                        ui.label(&self.api_status);
                    }

                    ui.separator();

                    ui.horizontal(|ui| {
                        ui.label(self.text(TextKey::Language));
                        let mut selected_language = self.language;
                        egui::ComboBox::from_id_salt("settings_gui_language")
                            .selected_text(selected_language.display_name())
                            .show_ui(ui, |ui| {
                                for language in GuiLanguage::ALL {
                                    ui.selectable_value(
                                        &mut selected_language,
                                        language,
                                        language.display_name(),
                                    );
                                }
                            });
                        if selected_language != self.language {
                            self.language = selected_language;
                            self.save_gui_language();
                            ctx.send_viewport_cmd(egui::ViewportCommand::Title(
                                self.text(TextKey::AppTitle).to_owned(),
                            ));
                        }
                    });

                    ui.add_space(10.0);

                    let auto_update_label = self.text(TextKey::AutoUpdate);
                    if ui.checkbox(&mut self.updater_auto_check, auto_update_label).changed() {
                        self.save_updater_config();
                    }

                    ui.horizontal(|ui| {
                        if ui.button(self.text(TextKey::CheckUpdates)).clicked() {
                            self.check_updates();
                        }
                        if let Some(url) = self.update_url.clone() {
                            if ui.button(self.text(TextKey::OpenDownloadPage)).clicked() {
                                ctx.open_url(egui::OpenUrl::new_tab(url));
                            }
                        }
                    });

                    if !self.update_status.is_empty() {
                        ui.label(&self.update_status);
                    }
                }
            }
        });
    }
}

fn format_cvar_payload(payload: &CvarPayload) -> String {
    let mut output = payload.source.clone();
    for (name, value) in &payload.values {
        output.push('\n');
        output.push_str(name);
        output.push_str(" = ");
        output.push_str(value);
    }
    output
}

fn format_player_payload(players: &[PlayerInfo], language: GuiLanguage) -> String {
    if players.is_empty() {
        return language.text(TextKey::NoPlayers).to_owned();
    }

    let mut output = String::from("#  score  time     name");
    for player in players {
        output.push('\n');
        output.push_str(&format!(
            "{:<2} {:>6} {:>7}  {}",
            player.index,
            format_optional_number(Some(player.score)),
            format_duration_seconds(player.duration),
            player.name
        ));
    }
    output
}

fn format_duration_seconds(seconds: f32) -> String {
    let total = seconds.max(0.0) as u64;
    let minutes = total / 60;
    let seconds = total % 60;
    format!("{minutes}:{seconds:02}")
}

fn format_optional_number(value: Option<i32>) -> String {
    let Some(value) = value else {
        return "-".to_owned();
    };
    let s = value.to_string();
    let mut result = String::new();
    for (index, ch) in s.chars().rev().enumerate() {
        if index > 0 && index % 3 == 0 && ch != '-' {
            result.push(',');
        }
        result.push(ch);
    }
    result.chars().rev().collect()
}

fn format_playtime_minutes(mins: Option<i32>, lang: GuiLanguage) -> String {
    let Some(minutes) = mins else {
        return "-".to_owned();
    };
    if minutes < 60 {
        match lang {
            GuiLanguage::ZhCn => format!("{minutes}分钟"),
            GuiLanguage::EnUs => format!("{minutes}m"),
        }
    } else {
        let hours = minutes / 60;
        let rem_mins = minutes % 60;
        if hours < 24 {
            match lang {
                GuiLanguage::ZhCn => format!("{hours}小时{rem_mins}分"),
                GuiLanguage::EnUs => format!("{hours}h {rem_mins}m"),
            }
        } else {
            let days = hours / 24;
            let rem_hours = hours % 24;
            match lang {
                GuiLanguage::ZhCn => format!("{days}天{rem_hours}小时"),
                GuiLanguage::EnUs => format!("{days}d {rem_hours}h"),
            }
        }
    }
}

fn sort_label(label: &str, active: SortKey, desc: bool, key: SortKey) -> String {
    if active == key {
        let marker = if desc { "↓" } else { "↑" };
        format!("{label} {marker}")
    } else {
        label.to_owned()
    }
}

fn server_payload_players(row: &ServerRowPayload) -> u8 {
    row.info.as_ref().map(|info| info.players).unwrap_or(0)
}

fn server_payload_ping(row: &ServerRowPayload) -> u64 {
    row.ping_ms.unwrap_or(u64::MAX)
}

fn server_payload_name(row: &ServerRowPayload) -> String {
    row.info
        .as_ref()
        .map(|info| info.name.to_lowercase())
        .unwrap_or_else(|| row.error.clone().unwrap_or_default().to_lowercase())
}

fn server_payload_map(row: &ServerRowPayload) -> String {
    row.info
        .as_ref()
        .map(|info| info.map.to_lowercase())
        .unwrap_or_default()
}

fn add_server_to_config(path: &PathBuf, input: AddServerRequest) -> Result<(), String> {
    let group_name = non_empty(input.group.trim().to_owned(), "group")?;
    let server = normalize_endpoint_input(&input.server)?;
    let mut config = load_config_or_default(path)?;

    if let Some(group) = config
        .groups
        .iter_mut()
        .find(|group| group.name == group_name)
    {
        if !group.servers.iter().any(|existing| existing == &server) {
            group.servers.push(server);
        }
    } else {
        config.groups.push(FileGroup {
            name: group_name,
            servers: vec![server],
        });
    }

    save_config(path, &config)
}

fn delete_server_from_config(path: &PathBuf, group: &str, server: &str) -> Result<(), String> {
    let mut config = load_config_or_default(path)?;
    let mut found = false;

    for g in config.groups.iter_mut() {
        if g.name == group {
            let before = g.servers.len();
            g.servers.retain(|s| s != server);
            if g.servers.len() < before {
                found = true;
            }
        }
    }

    config.groups.retain(|g| !g.servers.is_empty());

    if !found {
        return Err(format!("server {} not found in group {}", server, group));
    }

    save_config(path, &config)
}

fn add_sourcebans_to_config(path: &PathBuf, input: AddSourceBansRequest) -> Result<(), String> {
    let name = non_empty(input.name.trim().to_owned(), "name")?;
    let url = normalize_sourcebans_url(&input.url)?.to_string();
    let mut config = load_config_or_default(path)?;

    if let Some(subscription) = config
        .sourcebans
        .iter_mut()
        .find(|subscription| subscription.name == name)
    {
        subscription.url = url;
    } else {
        config.sourcebans.push(FileSourceBans { name, url });
    }

    save_config(path, &config)
}

fn update_sourcebans_in_config(
    path: &PathBuf,
    index: usize,
    input: AddSourceBansRequest,
) -> Result<(), String> {
    let name = non_empty(input.name.trim().to_owned(), "name")?;
    let url = normalize_sourcebans_url(&input.url)?.to_string();
    let mut config = load_config_or_default(path)?;
    let Some(subscription) = config.sourcebans.get_mut(index) else {
        return Err(format!("sourcebans index {index} does not exist"));
    };

    subscription.name = name;
    subscription.url = url;
    save_config(path, &config)
}

fn delete_sourcebans_from_config(path: &PathBuf, index: usize) -> Result<(), String> {
    let mut config = load_config_or_default(path)?;
    if index >= config.sourcebans.len() {
        return Err(format!("sourcebans index {index} does not exist"));
    }

    config.sourcebans.remove(index);
    save_config(path, &config)
}

fn save_gui_language_to_config(path: &PathBuf, language: GuiLanguage) -> Result<(), String> {
    let mut config = load_config_or_default(path)?;
    config.gui.language = language;
    save_config(path, &config)
}

fn save_updater_config_to_config(path: &PathBuf, auto_check: bool) -> Result<(), String> {
    let mut config = load_config_or_default(path)?;
    config.updater.auto_check = auto_check;
    save_config(path, &config)
}

fn save_api_config_to_config(
    path: &PathBuf,
    base_url: &str,
    token: Option<&str>,
) -> Result<(), String> {
    let mut config = load_config_or_default(path)?;
    config.api.base_url = non_empty(base_url.trim().to_owned(), "api.base_url")?;
    config.api.token = token
        .map(str::trim)
        .filter(|token| !token.is_empty())
        .map(str::to_owned);
    save_config(path, &config)
}

fn load_gui_config_lists(path: &PathBuf) -> Result<GuiConfigLists, String> {
    let config = load_config_or_default(path)?;
    let manual_servers = config
        .groups
        .iter()
        .flat_map(|group| {
            group.servers.iter().map(|server| ManualServerEntry {
                group: group.name.clone(),
                server: server.clone(),
            })
        })
        .collect();

    Ok(GuiConfigLists {
        manual_servers,
        sourcebans: config.sourcebans,
    })
}

#[derive(Deserialize)]
struct GitHubRelease {
    tag_name: String,
    html_url: String,
}

fn check_latest_release() -> Result<UpdateInfo, String> {
    let url = format!("https://api.github.com/repos/{UPDATE_REPO}/releases?per_page=100");
    let client = Client::builder()
        .timeout(Duration::from_millis(10_000))
        .build()
        .map_err(|err| format!("failed to build update client: {err}"))?;
    let text = client
        .get(&url)
        .header("User-Agent", USER_AGENT)
        .send()
        .map_err(|err| format!("failed to request latest release: {err}"))?
        .error_for_status()
        .map_err(|err| format!("latest release request failed: {err}"))?
        .text()
        .map_err(|err| format!("failed to read latest release: {err}"))?;
    let releases: Vec<GitHubRelease> = serde_json::from_str(&text)
        .map_err(|err| format!("failed to parse latest release list: {err}"))?;
    let release = releases
        .into_iter()
        .find(|release| release.tag_name.starts_with(UPDATE_TAG_PREFIX))
        .ok_or_else(|| format!("no {UPDATE_TAG_PREFIX} release found"))?;
    let latest_version = release_tag_version(&release.tag_name).to_owned();
    let available = is_version_newer(&latest_version, env!("CARGO_PKG_VERSION"));

    Ok(UpdateInfo {
        latest_version,
        html_url: release.html_url,
        available,
    })
}

fn release_tag_version(tag: &str) -> &str {
    tag.strip_prefix(UPDATE_TAG_PREFIX)
        .or_else(|| tag.strip_prefix('v'))
        .unwrap_or(tag)
}

fn is_version_newer(latest: &str, current: &str) -> bool {
    let latest_parts = version_parts(latest);
    let current_parts = version_parts(current);
    let max_len = latest_parts.len().max(current_parts.len()).max(1);

    for index in 0..max_len {
        let latest_part = *latest_parts.get(index).unwrap_or(&0);
        let current_part = *current_parts.get(index).unwrap_or(&0);
        if latest_part > current_part {
            return true;
        }
        if latest_part < current_part {
            return false;
        }
    }

    false
}

fn version_parts(version: &str) -> Vec<u64> {
    version
        .split(|ch: char| !(ch.is_ascii_digit()))
        .filter(|part| !part.is_empty())
        .filter_map(|part| part.parse::<u64>().ok())
        .collect()
}

fn server_rows_payload(rows: &[ServerRow]) -> Vec<ServerRowPayload> {
    rows.iter()
        .map(|row| ServerRowPayload {
            address: row.endpoint.display.clone(),
            socket: row.endpoint.socket.to_string(),
            groups: row.endpoint.groups.clone(),
            ping_ms: row.ping.map(|ping| ping.as_millis() as u64),
            info: row.info.clone(),
            error: row.error.clone(),
            last_queried: Some(std::time::Instant::now()),
        })
        .collect()
}

#[derive(Debug)]
struct RconPacket {
    id: i32,
    kind: i32,
    body: String,
}

fn rcon_command(
    address: &str,
    password: &str,
    command: &str,
    timeout: Duration,
) -> Result<String, String> {
    let password = non_empty(password.trim().to_owned(), "rcon password")?;
    let command = non_empty(command.trim().to_owned(), "rcon command")?;
    let endpoint = resolve_endpoint(address)?;
    let socket = SocketAddr::V4(endpoint.socket);
    let mut stream = TcpStream::connect_timeout(&socket, timeout)
        .map_err(|err| format!("failed to connect RCON {}: {err}", endpoint.display))?;
    stream
        .set_read_timeout(Some(timeout))
        .map_err(|err| err.to_string())?;
    stream
        .set_write_timeout(Some(timeout))
        .map_err(|err| err.to_string())?;

    write_rcon_packet(&mut stream, 1, 3, &password)?;
    let mut authed = false;
    for _ in 0..8 {
        let packet = read_rcon_packet(&mut stream)?;
        if packet.id == -1 {
            return Err("RCON auth failed".to_owned());
        }
        if packet.id == 1 && packet.kind == 2 {
            authed = true;
            break;
        }
    }
    if !authed {
        return Err("RCON auth response timed out".to_owned());
    }

    write_rcon_packet(&mut stream, 2, 2, &command)?;
    write_rcon_packet(&mut stream, 3, 0, "")?;

    let mut output = String::new();
    for _ in 0..64 {
        match read_rcon_packet(&mut stream) {
            Ok(packet) if packet.id == 3 => break,
            Ok(packet) if packet.id == 2 => output.push_str(&packet.body),
            Ok(packet) if packet.id == -1 => return Err("RCON command rejected".to_owned()),
            Ok(packet) => output.push_str(&packet.body),
            Err(err) if !output.is_empty() => {
                output.push_str(&format!("\n[read stopped: {err}]"));
                break;
            }
            Err(err) => return Err(err),
        }
    }

    Ok(output)
}

fn write_rcon_packet(stream: &mut TcpStream, id: i32, kind: i32, body: &str) -> Result<(), String> {
    let size = 4 + 4 + body.len() + 2;
    if size > i32::MAX as usize {
        return Err("RCON packet too large".to_owned());
    }

    stream
        .write_all(&(size as i32).to_le_bytes())
        .and_then(|_| stream.write_all(&id.to_le_bytes()))
        .and_then(|_| stream.write_all(&kind.to_le_bytes()))
        .and_then(|_| stream.write_all(body.as_bytes()))
        .and_then(|_| stream.write_all(&[0, 0]))
        .map_err(|err| err.to_string())
}

fn read_rcon_packet(stream: &mut TcpStream) -> Result<RconPacket, String> {
    let mut size_buf = [0u8; 4];
    stream
        .read_exact(&mut size_buf)
        .map_err(|err| err.to_string())?;
    let size = i32::from_le_bytes(size_buf);
    if !(10..=1_048_576).contains(&size) {
        return Err(format!("invalid RCON packet size: {size}"));
    }

    let mut payload = vec![0u8; size as usize];
    stream
        .read_exact(&mut payload)
        .map_err(|err| err.to_string())?;
    let id = i32::from_le_bytes([payload[0], payload[1], payload[2], payload[3]]);
    let kind = i32::from_le_bytes([payload[4], payload[5], payload[6], payload[7]]);
    let body_end = payload.len().saturating_sub(2);
    let body = String::from_utf8_lossy(&payload[8..body_end]).into_owned();
    Ok(RconPacket { id, kind, body })
}

fn read_cvars(input: CvarRequest) -> Result<CvarPayload, String> {
    let timeout = Duration::from_millis(input.timeout_ms.unwrap_or(2500).max(1));
    let names = input
        .names
        .unwrap_or_default()
        .into_iter()
        .map(|name| name.trim().to_owned())
        .filter(|name| !name.is_empty())
        .collect::<Vec<_>>();

    if let Some(password) = input
        .password
        .filter(|password| !password.trim().is_empty())
    {
        if names.is_empty() {
            return Err("RCON CVAR read requires at least one cvar name".to_owned());
        }

        let mut values = BTreeMap::new();
        for name in names {
            let output = rcon_command(&input.address, &password, &name, timeout)?;
            values.insert(name, output);
        }
        return Ok(CvarPayload {
            source: "rcon".to_owned(),
            values,
        });
    }

    let endpoint = resolve_endpoint(&input.address)?;
    let mut values = query_server_rules(endpoint.socket, timeout)?;
    if !names.is_empty() {
        let wanted = names
            .into_iter()
            .map(|name| name.to_lowercase())
            .collect::<HashSet<_>>();
        values.retain(|name, _| wanted.contains(&name.to_lowercase()));
    }

    Ok(CvarPayload {
        source: "a2s_rules".to_owned(),
        values,
    })
}

fn query_server_rules(
    addr: SocketAddrV4,
    timeout: Duration,
) -> Result<BTreeMap<String, String>, String> {
    let packet = a2s_exchange(
        addr,
        timeout,
        &build_a2s_rules_request([0xFF, 0xFF, 0xFF, 0xFF]),
        "A2S_RULES",
    )?;

    if let Some(challenge) = parse_challenge(&packet) {
        let packet = a2s_exchange(
            addr,
            timeout,
            &build_a2s_rules_request(challenge),
            "A2S_RULES",
        )?;
        return parse_rules_response(&packet);
    }

    parse_rules_response(&packet)
}

fn build_a2s_rules_request(challenge: [u8; 4]) -> Vec<u8> {
    let mut request = Vec::from(&b"\xFF\xFF\xFF\xFFV"[..]);
    request.extend_from_slice(&challenge);
    request
}

fn query_server_players(addr: SocketAddrV4, timeout: Duration) -> Result<Vec<PlayerInfo>, String> {
    let packet = a2s_exchange(
        addr,
        timeout,
        &build_a2s_player_request([0xFF, 0xFF, 0xFF, 0xFF]),
        "A2S_PLAYER",
    )?;

    if let Some(challenge) = parse_challenge(&packet) {
        let packet = a2s_exchange(
            addr,
            timeout,
            &build_a2s_player_request(challenge),
            "A2S_PLAYER",
        )?;
        return parse_player_response(&packet);
    }

    parse_player_response(&packet)
}

fn build_a2s_player_request(challenge: [u8; 4]) -> Vec<u8> {
    let mut request = Vec::from(&b"\xFF\xFF\xFF\xFFU"[..]);
    request.extend_from_slice(&challenge);
    request
}

fn a2s_exchange(
    addr: SocketAddrV4,
    timeout: Duration,
    request: &[u8],
    label: &str,
) -> Result<Vec<u8>, String> {
    let socket = UdpSocket::bind("0.0.0.0:0").map_err(|err| err.to_string())?;
    socket
        .set_read_timeout(Some(timeout))
        .map_err(|err| err.to_string())?;
    socket
        .set_write_timeout(Some(timeout))
        .map_err(|err| err.to_string())?;

    let mut last_error = None;
    for _ in 0..2 {
        socket
            .send_to(request, SocketAddr::V4(addr))
            .map_err(|err| format!("{label} request failed: {err}"))?;

        let mut buf = [0u8; 8192];
        match socket.recv_from(&mut buf) {
            Ok((size, from)) if from == SocketAddr::V4(addr) => return Ok(buf[..size].to_vec()),
            Ok((_size, _from)) => continue,
            Err(err) => last_error = Some(err),
        }
    }

    let err = last_error
        .map(|err| err.to_string())
        .unwrap_or_else(|| "no matching response".to_owned());
    Err(format!(
        "{label} 查询无响应；服务器可能屏蔽了公开查询、UDP 被防火墙拦截，或该查询需要用 RCON 兜底。底层错误：{err}"
    ))
}

fn parse_rules_response(packet: &[u8]) -> Result<BTreeMap<String, String>, String> {
    if packet.len() >= 4 && packet.starts_with(&[0xFE, 0xFF, 0xFF, 0xFF]) {
        return Err("split A2S_RULES response is not supported".to_owned());
    }
    if packet.len() < 7 || !packet.starts_with(&[0xFF, 0xFF, 0xFF, 0xFF]) || packet[4] != 0x45 {
        return Err("invalid A2S_RULES response".to_owned());
    }

    let mut reader = PacketReader::new(&packet[5..]);
    let count = reader.u16_le()? as usize;
    let mut values = BTreeMap::new();
    for _ in 0..count {
        if reader.remaining() == 0 {
            break;
        }
        let name = reader.string()?;
        let value = reader.string()?;
        values.insert(name, value);
    }

    Ok(values)
}

fn parse_player_response(packet: &[u8]) -> Result<Vec<PlayerInfo>, String> {
    if packet.len() >= 4 && packet.starts_with(&[0xFE, 0xFF, 0xFF, 0xFF]) {
        return Err("split A2S_PLAYER response is not supported".to_owned());
    }
    if packet.len() < 6 || !packet.starts_with(&[0xFF, 0xFF, 0xFF, 0xFF]) || packet[4] != 0x44 {
        return Err("invalid A2S_PLAYER response".to_owned());
    }

    let mut reader = PacketReader::new(&packet[5..]);
    let count = reader.u8()? as usize;
    let mut players = Vec::with_capacity(count);
    for _ in 0..count {
        if reader.remaining() == 0 {
            break;
        }
        players.push(PlayerInfo {
            index: reader.u8()?,
            name: reader.string()?,
            score: reader.i32_le()?,
            duration: reader.f32_le()?,
            points: None,
            playtime_mins: None,
            ppm: None,
            quarter_points: None,
        });
    }

    Ok(players)
}

fn api_client(timeout: Duration) -> Result<Client, String> {
    Client::builder()
        .timeout(timeout)
        .user_agent(USER_AGENT)
        .build()
        .map_err(|err| format!("failed to build API client: {err}"))
}

fn api_url(base_url: &str, path: &str) -> Result<reqwest::Url, String> {
    let base = base_url.trim();
    let base = if base.contains("://") {
        base.to_owned()
    } else {
        format!("https://{base}")
    };
    let parsed =
        reqwest::Url::parse(&base).map_err(|err| format!("invalid API URL {base}: {err}"))?;
    parsed
        .join(path)
        .map_err(|err| format!("invalid API path {path}: {err}"))
}

fn response_json<T: for<'de> Deserialize<'de>>(
    response: reqwest::blocking::Response,
) -> Result<T, String> {
    let status = response.status();
    let text = response
        .text()
        .map_err(|err| format!("failed to read API response: {err}"))?;
    if !status.is_success() {
        return Err(
            api_error_message(&text).unwrap_or_else(|| format!("API HTTP {status}: {text}"))
        );
    }
    serde_json::from_str(&text)
        .map_err(|err| format!("failed to parse API response: {err}: {text}"))
}

fn api_error_message(text: &str) -> Option<String> {
    let value: serde_json::Value = serde_json::from_str(text).ok()?;
    value
        .get("message")
        .and_then(|v| v.as_str())
        .or_else(|| value.get("error").and_then(|v| v.as_str()))
        .map(str::to_owned)
}

fn api_me(base_url: &str, token: &str) -> Result<ApiUser, String> {
    let client = api_client(Duration::from_secs(10))?;
    let url = api_url(base_url, "/api/auth/me.php")?;
    let response: ApiMeResponse = response_json(
        client
            .get(url)
            .bearer_auth(token)
            .send()
            .map_err(|err| format!("failed to query API user: {err}"))?,
    )?;
    if response.ok {
        response
            .user
            .ok_or_else(|| "API did not return user".to_owned())
    } else {
        Err(response
            .message
            .unwrap_or_else(|| "API user query failed".to_owned()))
    }
}

fn api_logout(base_url: &str, token: &str) -> Result<(), String> {
    let client = api_client(Duration::from_secs(10))?;
    let url = api_url(base_url, "/api/auth/logout.php")?;
    let _value: serde_json::Value = response_json(
        client
            .post(url)
            .bearer_auth(token)
            .json(&serde_json::json!({}))
            .send()
            .map_err(|err| format!("failed to logout API session: {err}"))?,
    )?;
    Ok(())
}

fn steam_device_login(
    request: ApiLoginRequest,
    tx: Sender<GuiMessage>,
) -> Result<ApiLoginSession, String> {
    let client = api_client(Duration::from_secs(10))?;
    let start_url = api_url(&request.base_url, "/api/auth/device_start.php")?;
    let start: DeviceStartResponse = response_json(
        client
            .post(start_url)
            .json(&serde_json::json!({}))
            .send()
            .map_err(|err| format!("failed to start Steam login: {err}"))?,
    )?;
    if !start.ok {
        return Err("Steam login start failed".to_owned());
    }

    let _ = tx.send(GuiMessage::SteamLoginStarted(Ok(start.clone())));
    let poll_url = api_url(&request.base_url, "/api/auth/device_poll.php")?;
    let started = Instant::now();
    let expires = Duration::from_secs(start.expires_in.max(1));
    let interval = Duration::from_secs(start.interval.clamp(1, 10));

    loop {
        if started.elapsed() > expires {
            return Err("Steam login expired".to_owned());
        }
        thread::sleep(interval);

        let response: DevicePollResponse = response_json(
            client
                .post(poll_url.clone())
                .json(&serde_json::json!({ "device_code": start.device_code }))
                .send()
                .map_err(|err| format!("failed to poll Steam login: {err}"))?,
        )?;

        if response.ok {
            let token = response
                .access_token
                .ok_or_else(|| "API did not return access token".to_owned())?;
            let user = response
                .user
                .ok_or_else(|| "API did not return Steam user".to_owned())?;
            return Ok(ApiLoginSession { token, user });
        }

        if response.error.as_deref() == Some("authorization_pending")
            || response.status.as_deref() == Some("authorization_pending")
        {
            continue;
        }

        return Err(response
            .message
            .or(response.error)
            .unwrap_or_else(|| "Steam login failed".to_owned()));
    }
}

fn api_broadcast(request: BroadcastRequest) -> Result<ApiBroadcastResponse, String> {
    let message = non_empty(request.message.trim().to_owned(), "message")?;
    let client = api_client(Duration::from_secs(15))?;
    let url = api_url(&request.base_url, "/api/server/broadcast.php")?;
    response_json(
        client
            .post(url)
            .bearer_auth(request.token)
            .json(&serde_json::json!({ "message": message }))
            .send()
            .map_err(|err| format!("failed to send broadcast: {err}"))?,
    )
}

fn fetch_player_stats_batch(
    base_url: &str,
    queries: &[String],
) -> Result<HashMap<String, PlayerStats>, String> {
    if queries.is_empty() {
        return Ok(HashMap::new());
    }

    let client = api_client(Duration::from_secs(15))?;
    let url = api_url(base_url, "/api/player/stats_batch.php")?;
    
    let mut stats = HashMap::new();

    for chunk in queries.chunks(100) {
        let response: PlayerStatsBatchResponse = response_json(
            client
                .post(url.clone())
                .json(&serde_json::json!({ "queries": chunk }))
                .send()
                .map_err(|err| format!("failed to query player stats chunk: {err}"))?,
        )?;

        if !response.ok {
            return Err("player stats API failed".to_owned());
        }

        for result in response.results {
            if result.ok {
                if let Some(player) = result.player {
                    stats.insert(result.query.to_lowercase(), player);
                }
            }
        }
    }

    Ok(stats)
}

fn enrich_players_with_api_stats(base_url: &str, players: &mut [PlayerInfo]) -> bool {
    let queries = players
        .iter()
        .map(|player| player.name.trim().to_owned())
        .filter(|name| !name.is_empty())
        .collect::<BTreeSet<_>>()
        .into_iter()
        .collect::<Vec<_>>();
    let Ok(stats) = fetch_player_stats_batch(base_url, &queries) else {
        return false;
    };

    for player in players {
        if let Some(stat) = stats.get(&player.name.to_lowercase()) {
            player.points = Some(stat.total_points);
            player.playtime_mins = Some(stat.playtime_minutes);
            player.ppm = Some(stat.ppm);
            player.quarter_points = Some(stat.quarter_points);
        }
    }
    true
}

fn enrich_global_players_with_api_stats(base_url: &str, players: &mut [GlobalPlayerEntry]) -> bool {
    let queries = players
        .iter()
        .map(|player| player.name.trim().to_owned())
        .filter(|name| !name.is_empty())
        .collect::<BTreeSet<_>>()
        .into_iter()
        .collect::<Vec<_>>();
    let Ok(stats) = fetch_player_stats_batch(base_url, &queries) else {
        return false;
    };

    for player in players {
        if let Some(stat) = stats.get(&player.name.to_lowercase()) {
            player.points = Some(stat.total_points);
            player.playtime_mins = Some(stat.playtime_minutes);
            player.ppm = Some(stat.ppm);
            player.quarter_points = Some(stat.quarter_points);
        }
    }
    true
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_master_response() {
        let packet = [
            0xFF, 0xFF, 0xFF, 0xFF, 0x66, 0x0A, 1, 2, 3, 4, 0x69, 0x87, 0, 0, 0, 0, 0, 0,
        ];

        let addrs = parse_master_response(&packet).expect("valid master response");
        assert_eq!(
            addrs,
            vec![SocketAddrV4::new(Ipv4Addr::new(1, 2, 3, 4), 27015)]
        );
    }

    #[test]
    fn parses_a2s_info_response() {
        let mut packet = Vec::new();
        packet.extend_from_slice(&[0xFF, 0xFF, 0xFF, 0xFF, 0x49, 17]);
        packet.extend_from_slice(b"Anne Test\0");
        packet.extend_from_slice(b"c2m1_highway\0");
        packet.extend_from_slice(b"left4dead2\0");
        packet.extend_from_slice(b"Left 4 Dead 2\0");
        packet.extend_from_slice(&550u16.to_le_bytes());
        packet.extend_from_slice(&[8, 8, 0, b'd', b'l', 0, 1]);
        packet.extend_from_slice(b"2.2.4.6\0");
        packet.push(0xA0);
        packet.extend_from_slice(&27015u16.to_le_bytes());
        packet.extend_from_slice(b"anne,confogl\0");

        let info = parse_server_info(&packet).expect("valid A2S_INFO response");
        assert_eq!(info.protocol, 17);
        assert_eq!(info.name, "Anne Test");
        assert_eq!(info.map, "c2m1_highway");
        assert_eq!(info.app_id, 550);
        assert_eq!(info.players, 8);
        assert_eq!(info.max_players, 8);
        assert!(info.vac);
        assert_eq!(info.port, Some(27015));
        assert_eq!(info.keywords.as_deref(), Some("anne,confogl"));
    }

    #[test]
    fn extracts_sourcebans_addresses() {
        let html = r#"
            <a href="steam://connect/51.79.176.131:27015">connect</a>
            <td>51.79.176.131:27025</td>
            <a href='steam://connect/example.org:27015/password'>host</a>
            <td>coop.l4d2zone.pl:27015</td>
        "#;

        let addresses = extract_sourcebans_addresses(html).expect("addresses");
        assert!(addresses.contains(&"51.79.176.131:27015".to_owned()));
        assert!(addresses.contains(&"51.79.176.131:27025".to_owned()));
        assert!(addresses.contains(&"example.org:27015".to_owned()));
        assert!(addresses.contains(&"coop.l4d2zone.pl:27015".to_owned()));
    }

    #[test]
    fn normalizes_sourcebans_root_url() {
        let url = normalize_sourcebans_url("https://example.com/sourcebans").expect("url");
        assert_eq!(
            url.as_str(),
            "https://example.com/sourcebans/index.php?p=servers"
        );
    }

    #[test]
    fn parses_gui_language() {
        let config: BrowserConfig =
            toml::from_str("[gui]\nlanguage = \"en-US\"\n").expect("valid config");
        assert_eq!(config.gui.language, GuiLanguage::EnUs);

        let config: BrowserConfig =
            toml::from_str("[gui]\nlanguage = \"zh\"\n").expect("valid config");
        assert_eq!(config.gui.language, GuiLanguage::ZhCn);
    }

    #[test]
    fn compares_release_versions() {
        assert_eq!(release_tag_version("l4d2-browser-v0.5.1"), "0.5.1");
        assert!(is_version_newer("0.5.0", "0.4.0"));
        assert!(is_version_newer("0.4.1", "0.4.0"));
        assert!(!is_version_newer("0.4.0", "0.4.0"));
        assert!(!is_version_newer("0.3.9", "0.4.0"));
    }

    #[test]
    fn parses_rules_response() {
        let mut packet = Vec::new();
        packet.extend_from_slice(&[0xFF, 0xFF, 0xFF, 0xFF, 0x45]);
        packet.extend_from_slice(&2u16.to_le_bytes());
        packet.extend_from_slice(b"hostname\0Anne Server\0");
        packet.extend_from_slice(b"sv_tags\0confogl,anne\0");

        let rules = parse_rules_response(&packet).expect("valid rules");
        assert_eq!(
            rules.get("hostname").map(String::as_str),
            Some("Anne Server")
        );
        assert_eq!(
            rules.get("sv_tags").map(String::as_str),
            Some("confogl,anne")
        );
    }

    #[test]
    fn parses_player_response() {
        let mut packet = Vec::new();
        packet.extend_from_slice(&[0xFF, 0xFF, 0xFF, 0xFF, 0x44, 1]);
        packet.push(0);
        packet.extend_from_slice(b"Anne\0");
        packet.extend_from_slice(&42i32.to_le_bytes());
        packet.extend_from_slice(&125.0f32.to_le_bytes());

        let players = parse_player_response(&packet).expect("valid players");
        assert_eq!(players.len(), 1);
        assert_eq!(players[0].name, "Anne");
        assert_eq!(players[0].score, 42);
        assert_eq!(format_duration_seconds(players[0].duration), "2:05");
    }
}
