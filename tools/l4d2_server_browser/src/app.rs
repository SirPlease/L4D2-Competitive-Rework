use chrono::{DateTime, Local, NaiveDateTime, TimeZone as _, Utc};
use chrono_tz::Tz;
use clap::{Parser, ValueEnum};
use eframe::egui;
use regex::Regex;
use reqwest::blocking::{Client, Response};
use reqwest::StatusCode;
use serde::{Deserialize, Serialize};
use std::collections::{hash_map::DefaultHasher, BTreeMap, BTreeSet, HashMap, HashSet, VecDeque};
use std::env;
use std::fs;
use std::hash::{Hash, Hasher};
use std::io::{self, Read, Write};
use std::net::{Ipv4Addr, SocketAddr, SocketAddrV4, TcpStream, ToSocketAddrs, UdpSocket};
use std::path::{Path, PathBuf};
use std::sync::{
    mpsc::{self, Receiver, Sender},
    Arc, Mutex, OnceLock,
};
use std::thread;
use std::time::{Duration, Instant};

const DEFAULT_MASTER: &str = "hl2master.steampowered.com:27011";
const DEFAULT_FILTER: &str = "\\appid\\550";
const DEFAULT_MASTER_GROUP: &str = "Steam Master";
const APP_NAME: &str = "Anne刷服器";
const DEFAULT_CONFIG_FILE: &str = "anne-server-browser.toml";
const USER_AGENT: &str = concat!("AnneServerBrowser/", env!("CARGO_PKG_VERSION"));
const UPDATE_REPO: &str = "fantasylidong/CompetitiveWithAnne";
const UPDATE_TAG_PREFIX: &str = "Anne刷服器-v";
const DEFAULT_API_BASE_URL: &str = "https://anne.trygek.com";
const SYSTEM_TIME_ZONE_VALUE: &str = "system";
const ONLINE_STATS_CACHE_TTL: Duration = Duration::from_secs(60);
const ONLINE_STATS_AUTH_CACHE_TTL: Duration = Duration::from_secs(60);
const ONLINE_STATS_ANON_CACHE_TTL: Duration = Duration::from_secs(600);
const TAURI_PLAYER_CACHE_TTL: Duration = Duration::from_secs(60);
const ONLINE_STATS_PAGE_LIMIT: usize = 512;
const A2S_PROBE_MARKER: &[u8] = b"\0ANNE_A2S_PROBE";

pub fn run_main() {
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
            let base = PathBuf::from(appdata);
            return existing_or_new_config_path(
                base.join(APP_NAME).join(DEFAULT_CONFIG_FILE),
                base.join("L4D2 Server Browser").join("l4d2-browser.toml"),
            );
        }
        if let Some(profile) = env::var_os("USERPROFILE") {
            let base = PathBuf::from(profile).join("AppData").join("Roaming");
            return existing_or_new_config_path(
                base.join(APP_NAME).join(DEFAULT_CONFIG_FILE),
                base.join("L4D2 Server Browser").join("l4d2-browser.toml"),
            );
        }
    }

    #[cfg(target_os = "macos")]
    {
        if let Some(home) = env::var_os("HOME") {
            let base = PathBuf::from(home)
                .join("Library")
                .join("Application Support");
            return existing_or_new_config_path(
                base.join(APP_NAME).join(DEFAULT_CONFIG_FILE),
                base.join("L4D2 Server Browser").join("l4d2-browser.toml"),
            );
        }
    }

    #[cfg(all(unix, not(target_os = "macos")))]
    {
        if let Some(xdg_config_home) = env::var_os("XDG_CONFIG_HOME") {
            let base = PathBuf::from(xdg_config_home);
            return existing_or_new_config_path(
                base.join("anne-server-browser").join(DEFAULT_CONFIG_FILE),
                base.join("l4d2-server-browser").join("l4d2-browser.toml"),
            );
        }
        if let Some(home) = env::var_os("HOME") {
            let base = PathBuf::from(home).join(".config");
            return existing_or_new_config_path(
                base.join("anne-server-browser").join(DEFAULT_CONFIG_FILE),
                base.join("l4d2-server-browser").join("l4d2-browser.toml"),
            );
        }
    }

    PathBuf::from(DEFAULT_CONFIG_FILE)
}

fn existing_or_new_config_path(new_path: PathBuf, old_path: PathBuf) -> PathBuf {
    if !new_path.exists() && old_path.exists() {
        old_path
    } else {
        new_path
    }
}

#[derive(Parser, Debug, Clone)]
#[command(name = "Anne刷服器")]
#[command(about = "Left 4 Dead 2 server browser with groups and web page subscriptions.")]
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

    #[arg(long, alias = "subscription")]
    sourcebans: Vec<String>,

    #[arg(long, alias = "subscription-url")]
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
    a2s_probe: bool,
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
            server_timeout: Duration::from_millis(1500),
            http_timeout: Duration::from_millis(10_000),
            sort: SortKey::Players,
            min_players: None,
            name_filter: None,
            map_filter: None,
            group_filter: None,
            no_info: false,
            json: false,
            a2s_probe: false,
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
        self.a2s_probe = master.a2s_probe;

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
    manual_groups.extend(config.groups.into_iter().filter_map(|g| {
        match ManualGroup::try_from(g) {
            Ok(group) => Some(group),
            Err(err) => {
                eprintln!("warning: skipped invalid group: {err}");
                None
            }
        }
    }));
    subscriptions.extend(config.sourcebans.into_iter().filter_map(|s| {
        match SourceBansSubscription::try_from(s) {
            Ok(sub) => Some(sub),
            Err(err) => {
                eprintln!("warning: skipped invalid subscription: {err}");
                None
            }
        }
    }));

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
        name: subscription_group_name(url),
        url: url.to_owned(),
        text: String::new(),
        servers: Vec::new(),
        a2s_probe: false,
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
            drop_on_timeout: entry.drop_on_timeout,
            a2s_probe: entry.a2s_probe,
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
    if !settings.no_info {
        rows.retain(|row| !(row.endpoint.drop_on_timeout && row.info.is_none()));
    }

    rows = apply_filters(rows, settings);
    sort_rows(&mut rows, settings.sort);
    Ok(rows)
}

fn load_selected_server_rows(
    settings: &RuntimeSettings,
    sockets: &[String],
    a2s_probe_sockets: &[String],
) -> Result<Vec<ServerRow>, String> {
    let a2s_probe_sockets = a2s_probe_sockets
        .iter()
        .map(|socket| socket.trim().to_owned())
        .filter(|socket| !socket.is_empty())
        .collect::<BTreeSet<_>>();
    let mut seen = BTreeSet::new();
    let endpoints = sockets
        .iter()
        .filter_map(|socket| {
            let input = socket.trim();
            let socket = resolve_ipv4(input).ok()?;
            if !seen.insert(socket) {
                return None;
            }
            let resolved = socket.to_string();
            Some(Endpoint {
                display: resolved.clone(),
                socket,
                groups: Vec::new(),
                drop_on_timeout: false,
                a2s_probe: settings.a2s_probe
                    || a2s_probe_sockets.contains(input)
                    || a2s_probe_sockets.contains(&resolved),
            })
        })
        .collect::<Vec<_>>();

    if endpoints.is_empty() {
        return Ok(Vec::new());
    }

    Ok(query_servers(
        endpoints,
        settings.server_timeout,
        settings.jobs,
    ))
}

#[derive(Debug, Clone, Deserialize, Serialize)]
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

const DEFAULT_ANNE_SUBSCRIPTION_URL: &str = "https://anne.trygek.com/bans/index.php?p=servers";

impl Default for BrowserConfig {
    fn default() -> Self {
        Self {
            gui: GuiConfig::default(),
            updater: UpdaterConfig::default(),
            api: ApiConfig::default(),
            master: None,
            groups: Vec::new(),
            sourcebans: vec![FileSourceBans {
                name: "Anne电信服".to_owned(),
                url: DEFAULT_ANNE_SUBSCRIPTION_URL.to_owned(),
                text: String::new(),
                servers: Vec::new(),
                a2s_probe: true,
            }],
        }
    }
}

fn parse_config_text(text: &str, path: &Path) -> Result<BrowserConfig, String> {
    let mut config: BrowserConfig = toml::from_str(text)
        .map_err(|err| format!("failed to parse config {}: {err}", path.display()))?;
    apply_default_anne_subscription_probe(&mut config);
    Ok(config)
}

fn apply_default_anne_subscription_probe(config: &mut BrowserConfig) {
    for subscription in &mut config.sourcebans {
        if is_default_anne_subscription(subscription) {
            subscription.a2s_probe = true;
        }
    }
}

fn is_default_anne_subscription(subscription: &FileSourceBans) -> bool {
    is_default_anne_subscription_url(&subscription.url)
}

fn is_default_anne_subscription_url(url: &str) -> bool {
    normalize_subscription_url(url)
        .map(|url| url.as_str() == DEFAULT_ANNE_SUBSCRIPTION_URL)
        .unwrap_or(false)
}

#[derive(Debug, Clone, Deserialize, Serialize, Default)]
struct GuiConfig {
    #[serde(default)]
    language: GuiLanguage,
    #[serde(default = "default_true")]
    anne_stats: bool,
    // Kept for compatibility with older config files. The Tauri UI writes
    // per-server passwords to rcon_passwords instead.
    #[serde(default)]
    rcon_password: Option<String>,
    #[serde(default)]
    rcon_passwords: BTreeMap<String, String>,
    #[serde(default = "default_theme_mode")]
    theme_mode: String,
    #[serde(default = "default_accent_color")]
    accent_color: String,
    #[serde(default = "default_auto_refresh_empty_secs")]
    auto_refresh_empty_secs: u64,
    #[serde(default = "default_auto_refresh_active_secs")]
    auto_refresh_active_secs: u64,
    #[serde(default = "default_auto_refresh_selected_secs")]
    auto_refresh_selected_secs: u64,
    #[serde(default = "default_time_zone")]
    time_zone: String,
}

fn default_true() -> bool {
    true
}

fn default_theme_mode() -> String {
    "light".to_owned()
}

fn default_accent_color() -> String {
    "#0f766e".to_owned()
}

fn default_auto_refresh_empty_secs() -> u64 {
    120
}

fn default_auto_refresh_active_secs() -> u64 {
    30
}

fn default_auto_refresh_selected_secs() -> u64 {
    5
}

fn default_time_zone() -> String {
    SYSTEM_TIME_ZONE_VALUE.to_owned()
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
                TextKey::AppTitle => APP_NAME,
                TextKey::RefreshServers => "刷新服务器",
                TextKey::Language => "语言",
                TextKey::AddServer => "添加服务器",
                TextKey::Group => "分组",
                TextKey::ServerAddress => "服务器地址",
                TextKey::SaveServer => "保存服务器",
                TextKey::SourceBansSubscription => "网页订阅",
                TextKey::SubscriptionName => "订阅名称",
                TextKey::PageUrl => "页面 URL（可选）",
                TextKey::PastedSubscriptionText => "粘贴 HTML / 文本（可选）",
                TextKey::A2sProbe => "电信 Anne 服",
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
                TextKey::HeaderAddress => "IP",
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
                TextKey::SubscriptionSaved => "网页订阅已保存",
                TextKey::LanguageSaved => "语言设置已保存",
                TextKey::NotQueried => "未查询",
                TextKey::ManualServerList => "已保存服务器",
                TextKey::SubscriptionList => "已保存订阅",
                TextKey::NewSubscription => "新建订阅",
                TextKey::RefreshSubscriptions => "刷新订阅",
                TextKey::UpdateSubscription => "保存修改",
                TextKey::DeleteSubscription => "删除订阅",
                TextKey::SubscriptionDeleted => "网页订阅已删除",
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
                TextKey::NetworkInfo => "网络信息",
                TextKey::ResolveNetwork => "重新解析",
                TextKey::IpAddress => "解析 IP",
                TextKey::NetworkOperator => "运营商",
                TextKey::Organization => "组织",
                TextKey::Asn => "ASN",
                TextKey::Region => "地区",
                TextKey::CvarSearchPlaceholder => "搜索 CVAR / 规则变量名...",
                TextKey::GlobalPlayerSearchPlaceholder => "搜索在线玩家昵称...",
                TextKey::ApiBaseUrl => "AnneWeb API 地址",
                TextKey::TimeZone => "时区",
                TextKey::SteamLogin => "Steam 登录",
                TextKey::Logout => "退出登录",
                TextKey::BroadcastMessage => "全服消息内容",
                TextKey::SendBroadcast => "发送全服消息",
                TextKey::BroadcastHistory => "最近一小时全服消息",
                TextKey::RefreshHistory => "刷新历史",
            },
            Self::EnUs => match key {
                TextKey::AppTitle => APP_NAME,
                TextKey::RefreshServers => "Refresh servers",
                TextKey::Language => "Language",
                TextKey::AddServer => "Add server",
                TextKey::Group => "Group",
                TextKey::ServerAddress => "Server address",
                TextKey::SaveServer => "Save server",
                TextKey::SourceBansSubscription => "Web page subscription",
                TextKey::SubscriptionName => "Subscription name",
                TextKey::PageUrl => "Page URL (optional)",
                TextKey::PastedSubscriptionText => "Pasted HTML / text (optional)",
                TextKey::A2sProbe => "Telecom Anne server",
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
                TextKey::HeaderAddress => "IP",
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
                TextKey::SubscriptionSaved => "Web page subscription saved",
                TextKey::LanguageSaved => "Language setting saved",
                TextKey::NotQueried => "not queried",
                TextKey::ManualServerList => "Saved servers",
                TextKey::SubscriptionList => "Saved subscriptions",
                TextKey::NewSubscription => "New subscription",
                TextKey::RefreshSubscriptions => "Refresh subscriptions",
                TextKey::UpdateSubscription => "Save changes",
                TextKey::DeleteSubscription => "Delete subscription",
                TextKey::SubscriptionDeleted => "Web page subscription deleted",
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
                TextKey::NetworkInfo => "Network",
                TextKey::ResolveNetwork => "Resolve again",
                TextKey::IpAddress => "Resolved IP",
                TextKey::NetworkOperator => "ISP",
                TextKey::Organization => "Organization",
                TextKey::Asn => "ASN",
                TextKey::Region => "Region",
                TextKey::CvarSearchPlaceholder => "Filter CVAR names...",
                TextKey::GlobalPlayerSearchPlaceholder => "Search player name...",
                TextKey::ApiBaseUrl => "AnneWeb API URL",
                TextKey::TimeZone => "Time zone",
                TextKey::SteamLogin => "Steam login",
                TextKey::Logout => "Logout",
                TextKey::BroadcastMessage => "Broadcast message",
                TextKey::SendBroadcast => "Send broadcast",
                TextKey::BroadcastHistory => "Last Hour Messages",
                TextKey::RefreshHistory => "Refresh history",
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

    fn network_resolving_status(self) -> String {
        match self {
            Self::ZhCn => "正在解析服务器 IP 和网络信息...".to_owned(),
            Self::EnUs => "Resolving server IP and network info...".to_owned(),
        }
    }

    fn network_failed_status(self, err: &str) -> String {
        match self {
            Self::ZhCn => format!("网络信息解析失败：{err}"),
            Self::EnUs => format!("Network lookup failed: {err}"),
        }
    }
}

fn gui_language_code(language: GuiLanguage) -> &'static str {
    match language {
        GuiLanguage::ZhCn => "zh-CN",
        GuiLanguage::EnUs => "en-US",
    }
}

fn parse_gui_language_setting(value: &str) -> Result<GuiLanguage, String> {
    match value.trim().replace('_', "-").to_ascii_lowercase().as_str() {
        "zh" | "zh-cn" => Ok(GuiLanguage::ZhCn),
        "en" | "en-us" => Ok(GuiLanguage::EnUs),
        _ => Err(format!("invalid GUI language: {value}")),
    }
}

fn normalize_time_zone_setting(value: &str) -> String {
    let value = value.trim();
    if value.is_empty()
        || value.eq_ignore_ascii_case("system")
        || value.eq_ignore_ascii_case("local")
        || value.eq_ignore_ascii_case("auto")
    {
        return SYSTEM_TIME_ZONE_VALUE.to_owned();
    }

    if value.parse::<Tz>().is_ok() {
        value.to_owned()
    } else {
        SYSTEM_TIME_ZONE_VALUE.to_owned()
    }
}

fn parse_broadcast_utc_time(value: &str) -> Option<DateTime<Utc>> {
    let value = value.trim();
    if value.is_empty() {
        return None;
    }

    if let Ok(datetime) = DateTime::parse_from_rfc3339(value) {
        return Some(datetime.with_timezone(&Utc));
    }

    for format in [
        "%Y-%m-%d %H:%M:%S",
        "%Y-%m-%dT%H:%M:%S",
        "%Y-%m-%d %H:%M:%S%.f",
        "%Y-%m-%dT%H:%M:%S%.f",
    ] {
        if let Ok(naive) = NaiveDateTime::parse_from_str(value, format) {
            return Some(Utc.from_utc_datetime(&naive));
        }
    }

    None
}

fn format_broadcast_time(value: &str, time_zone: &str) -> String {
    let Some(utc_time) = parse_broadcast_utc_time(value) else {
        return value.to_owned();
    };

    let time_zone = normalize_time_zone_setting(time_zone);
    if time_zone == SYSTEM_TIME_ZONE_VALUE {
        utc_time
            .with_timezone(&Local)
            .format("%Y-%m-%d %H:%M:%S %:z")
            .to_string()
    } else if let Ok(tz) = time_zone.parse::<Tz>() {
        utc_time
            .with_timezone(&tz)
            .format("%Y-%m-%d %H:%M:%S %Z")
            .to_string()
    } else {
        value.to_owned()
    }
}

fn split_server_tags(value: &str) -> Vec<String> {
    let mut seen = HashSet::new();
    let mut tags = Vec::new();
    for tag in value
        .split(|ch: char| ch == ',' || ch == ';' || ch.is_whitespace())
        .map(str::trim)
        .filter(|tag| !tag.is_empty())
    {
        let normalized = tag.to_ascii_lowercase();
        if seen.insert(normalized) {
            tags.push(tag.to_owned());
        }
    }
    tags
}

fn server_info_has_tag(info: &ServerInfo, tag: &str) -> bool {
    let wanted = tag.to_ascii_lowercase();
    info.keywords
        .as_deref()
        .map(split_server_tags)
        .unwrap_or_default()
        .into_iter()
        .any(|item| item.to_ascii_lowercase() == wanted)
}

fn is_anne_server_info(info: &ServerInfo) -> bool {
    is_anne_server_name(&info.name) || server_info_has_tag(info, "anne")
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
    PastedSubscriptionText,
    A2sProbe,
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
    RefreshSubscriptions,
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
    NetworkInfo,
    ResolveNetwork,
    IpAddress,
    NetworkOperator,
    Organization,
    Asn,
    Region,
    CvarSearchPlaceholder,
    GlobalPlayerSearchPlaceholder,
    ApiBaseUrl,
    TimeZone,
    SteamLogin,
    Logout,
    BroadcastMessage,
    SendBroadcast,
    BroadcastHistory,
    RefreshHistory,
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
    #[serde(default, skip_serializing_if = "is_false")]
    a2s_probe: bool,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
struct FileGroup {
    name: String,
    servers: Vec<String>,
    #[serde(default, skip_serializing_if = "is_false")]
    a2s_probe: bool,
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    a2s_probe_servers: Vec<String>,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
struct FileSourceBans {
    name: String,
    #[serde(default, skip_serializing_if = "String::is_empty")]
    url: String,
    #[serde(default, skip_serializing_if = "String::is_empty")]
    text: String,
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    servers: Vec<String>,
    #[serde(default, skip_serializing_if = "is_false")]
    a2s_probe: bool,
}

#[derive(Debug, Clone)]
struct ManualGroup {
    name: String,
    servers: Vec<String>,
    a2s_probe: bool,
    a2s_probe_servers: BTreeSet<String>,
}

#[derive(Debug, Clone)]
struct SourceBansSubscription {
    name: String,
    url: String,
    text: String,
    servers: Vec<String>,
    a2s_probe: bool,
}

impl TryFrom<FileGroup> for ManualGroup {
    type Error = String;

    fn try_from(value: FileGroup) -> Result<Self, Self::Error> {
        Ok(Self {
            name: non_empty(value.name, "groups.name")?,
            servers: value.servers,
            a2s_probe: value.a2s_probe,
            a2s_probe_servers: value.a2s_probe_servers.into_iter().collect(),
        })
    }
}

impl TryFrom<FileSourceBans> for SourceBansSubscription {
    type Error = String;

    fn try_from(value: FileSourceBans) -> Result<Self, Self::Error> {
        let url = value.url.trim().to_owned();
        let text = value.text.trim().to_owned();
        let servers = value.servers;
        if url.is_empty() && text.is_empty() && servers.is_empty() {
            return Err(
                "sourcebans.url or sourcebans.text or sourcebans.servers cannot be empty"
                    .to_owned(),
            );
        }

        Ok(Self {
            name: non_empty(value.name, "sourcebans.name")?,
            url,
            text,
            servers,
            a2s_probe: value.a2s_probe,
        })
    }
}

fn load_config(path: Option<&PathBuf>) -> Result<Option<BrowserConfig>, String> {
    let Some(path) = path else {
        return Ok(None);
    };

    let text = fs::read_to_string(path)
        .map_err(|err| format!("failed to read config {}: {err}", path.display()))?;
    parse_config_text(&text, path).map(Some)
}

fn load_config_or_default(path: &PathBuf) -> Result<BrowserConfig, String> {
    match fs::read_to_string(path) {
        Ok(text) => parse_config_text(&text, path),
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

    Ok(ManualGroup {
        name,
        servers,
        a2s_probe: false,
        a2s_probe_servers: BTreeSet::new(),
    })
}

fn parse_cli_subscription(value: &str) -> Result<SourceBansSubscription, String> {
    let (name, url) = split_name_value(value, "--sourcebans")?;
    Ok(SourceBansSubscription {
        name,
        url,
        text: String::new(),
        servers: Vec::new(),
        a2s_probe: false,
    })
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
                            add_endpoint(
                                &mut registry,
                                with_a2s_probe(endpoint, settings.a2s_probe),
                                &settings.master_group,
                                false,
                            );
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
        let probe_servers = group
            .a2s_probe_servers
            .iter()
            .map(|server| server.trim().to_owned())
            .filter(|server| !server.is_empty())
            .collect::<BTreeSet<_>>();
        for server in &group.servers {
            match resolve_endpoint(server) {
                Ok(endpoint) => {
                    let resolved = endpoint.socket.to_string();
                    let a2s_probe = group.a2s_probe
                        || probe_servers.contains(server.trim())
                        || probe_servers.contains(&resolved);
                    add_endpoint(
                        &mut registry,
                        with_a2s_probe(endpoint, a2s_probe),
                        &group.name,
                        false,
                    )
                }
                Err(err) => eprintln!("warning: skipped {} in group {}: {err}", server, group.name),
            }
        }
    }

    for subscription in subscriptions {
        let drop_on_timeout = subscription_drops_timeout_servers(subscription);

        // Use cached servers if available, otherwise fetch from URL/text
        let addresses = if !subscription.servers.is_empty() {
            Ok(subscription.servers.clone())
        } else {
            fetch_web_subscription(subscription, settings.http_timeout)
        };

        match addresses {
            Ok(addresses) => {
                for address in addresses {
                    match resolve_endpoint(&address) {
                        Ok(endpoint) => add_endpoint(
                            &mut registry,
                            with_a2s_probe(endpoint, subscription.a2s_probe),
                            &subscription.name,
                            drop_on_timeout,
                        ),
                        Err(err) => eprintln!(
                            "warning: skipped {} from subscription {}: {err}",
                            address, subscription.name
                        ),
                    }
                }
            }
            Err(err) => eprintln!(
                "warning: web page subscription {} failed: {err}",
                subscription.url
            ),
        }
    }

    Ok(registry)
}

fn is_false(value: &bool) -> bool {
    !*value
}

fn with_a2s_probe(mut endpoint: Endpoint, a2s_probe: bool) -> Endpoint {
    endpoint.a2s_probe = a2s_probe;
    endpoint
}

#[derive(Debug, Clone)]
struct RegistryEntry {
    display: String,
    socket: SocketAddrV4,
    groups: BTreeSet<String>,
    drop_on_timeout: bool,
    a2s_probe: bool,
}

#[derive(Debug, Clone)]
struct Endpoint {
    display: String,
    socket: SocketAddrV4,
    groups: Vec<String>,
    drop_on_timeout: bool,
    a2s_probe: bool,
}

fn add_endpoint(
    registry: &mut HashMap<SocketAddrV4, RegistryEntry>,
    endpoint: Endpoint,
    group: &str,
    drop_on_timeout: bool,
) {
    let endpoint_probe = endpoint.a2s_probe;
    let entry = registry
        .entry(endpoint.socket)
        .or_insert_with(|| RegistryEntry {
            display: endpoint.display,
            socket: endpoint.socket,
            groups: BTreeSet::new(),
            drop_on_timeout,
            a2s_probe: endpoint_probe,
        });
    if !drop_on_timeout {
        entry.drop_on_timeout = false;
    }
    if !entry.a2s_probe {
        entry.a2s_probe = endpoint_probe;
    }
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
                        drop_on_timeout: false,
                        a2s_probe: false,
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

fn fetch_web_subscription(
    subscription: &SourceBansSubscription,
    timeout: Duration,
) -> Result<Vec<String>, String> {
    if !subscription.text.trim().is_empty() {
        return extract_pasted_subscription(&subscription.text, &subscription.name);
    }

    if subscription.url.trim().is_empty() {
        return Err(format!(
            "subscription {} requires a page URL or pasted text",
            subscription.name
        ));
    }

    let url = normalize_subscription_url(&subscription.url)?;
    let client = Client::builder()
        .timeout(timeout)
        .user_agent(USER_AGENT)
        .build()
        .map_err(|err| err.to_string())?;
    let body = fetch_subscription_body(&client, url.clone())?;
    let mut addresses = Vec::new();
    let mut seen_addresses = BTreeSet::new();
    add_subscription_addresses(&body, &mut addresses, &mut seen_addresses)?;
    let mut data_urls = extract_subscription_data_urls(&url, &body)?;

    if let Ok(resources) = extract_linked_subscription_resources(&url, &body) {
        for resource_url in resources.into_iter().take(16) {
            let Ok(resource_body) = fetch_subscription_body(&client, resource_url) else {
                continue;
            };
            add_subscription_addresses(&resource_body, &mut addresses, &mut seen_addresses)?;
            data_urls.extend(extract_subscription_data_urls(&url, &resource_body)?);
        }
    }

    let mut seen_data_urls = BTreeSet::new();
    for data_url in data_urls
        .into_iter()
        .filter(|url| {
            let key = url.as_str().to_owned();
            seen_data_urls.insert(key)
        })
        .take(16)
    {
        let Ok(data_body) = fetch_subscription_body(&client, data_url) else {
            continue;
        };
        add_subscription_addresses(&data_body, &mut addresses, &mut seen_addresses)?;
    }

    if addresses.is_empty() {
        if let Some(reason) = detect_subscription_blocker(&body) {
            return Err(format!("no server addresses found at {url}: {reason}"));
        }
        Err(format!("no server addresses found at {url}"))
    } else {
        Ok(addresses)
    }
}

fn extract_pasted_subscription(body: &str, name: &str) -> Result<Vec<String>, String> {
    let mut addresses = Vec::new();
    let mut seen_addresses = BTreeSet::new();
    add_subscription_addresses(body, &mut addresses, &mut seen_addresses)?;

    if addresses.is_empty() {
        if let Some(reason) = detect_subscription_blocker(body) {
            return Err(format!(
                "no server addresses found in pasted text {name}: {reason}"
            ));
        }
        Err(format!("no server addresses found in pasted text {name}"))
    } else {
        Ok(addresses)
    }
}

fn add_subscription_addresses(
    body: &str,
    addresses: &mut Vec<String>,
    seen: &mut BTreeSet<String>,
) -> Result<(), String> {
    for address in extract_subscription_addresses(body)? {
        if seen.insert(address.clone()) {
            addresses.push(address);
        }
    }
    Ok(())
}

fn fetch_subscription_body(client: &Client, url: reqwest::Url) -> Result<String, String> {
    let response = client.get(url).send().map_err(|err| err.to_string())?;
    let status = response.status();
    let final_url = response.url().clone();
    let headers = response.headers().clone();
    let body = response.text().map_err(|err| err.to_string())?;

    if !status.is_success() {
        if let Some(reason) = detect_subscription_response_blocker(&headers, &body) {
            return Err(format!(
                "subscription request blocked at {final_url}: HTTP {status}; {reason}"
            ));
        }
        return Err(format!(
            "subscription request failed at {final_url}: HTTP {status}"
        ));
    }

    Ok(body)
}

fn normalize_subscription_url(input: &str) -> Result<reqwest::Url, String> {
    let mut url = parse_subscription_url(input)?;

    if has_sourcebans_servers_page(&url) {
        return Ok(url);
    }
    if !looks_like_sourcebans_url(&url) {
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

fn parse_subscription_url(input: &str) -> Result<reqwest::Url, String> {
    let input = input.trim();
    let parse_input = if input.contains("://") {
        input.to_owned()
    } else {
        format!("https://{input}")
    };
    reqwest::Url::parse(&parse_input).map_err(|err| format!("invalid URL {input}: {err}"))
}

fn has_sourcebans_servers_page(url: &reqwest::Url) -> bool {
    url.query_pairs()
        .any(|(key, value)| key.eq_ignore_ascii_case("p") && value.eq_ignore_ascii_case("servers"))
}

fn looks_like_sourcebans_url(url: &reqwest::Url) -> bool {
    let path = url.path().trim_matches('/').to_ascii_lowercase();
    path == "bans" || path.contains("sourcebans") || path.starts_with("bans/")
}

fn subscription_drops_timeout_servers(subscription: &SourceBansSubscription) -> bool {
    if !subscription.text.trim().is_empty() {
        return true;
    }

    parse_subscription_url(&subscription.url)
        .map(|url| !looks_like_sourcebans_url(&url))
        .unwrap_or(true)
}

fn extract_linked_subscription_resources(
    base_url: &reqwest::Url,
    body: &str,
) -> Result<Vec<reqwest::Url>, String> {
    let body = decode_minimal_text_entities(body);
    let resource_re =
        Regex::new(r#"(?is)<(?:script|link)\b[^>]*\b(?:src|href)\s*=\s*["']([^"']+)["']"#)
            .map_err(|err| err.to_string())?;
    let mut seen = BTreeSet::new();
    let mut resources = Vec::new();

    for capture in resource_re.captures_iter(&body) {
        let Some(raw) = capture.get(1) else {
            continue;
        };
        let Ok(url) = base_url.join(raw.as_str().trim()) else {
            continue;
        };
        if !same_origin(base_url, &url) || !is_subscription_resource(&url) {
            continue;
        }
        let key = url.as_str().to_owned();
        if seen.insert(key) {
            resources.push(url);
        }
    }

    Ok(resources)
}

fn extract_subscription_data_urls(
    base_url: &reqwest::Url,
    body: &str,
) -> Result<Vec<reqwest::Url>, String> {
    let body = decode_minimal_text_entities(body);
    let url_re = Regex::new(
        r#"(?i)["'`](/api/(?:all|servers?|server-list|status|list)[A-Za-z0-9_./?=&%-]*)["'`]"#,
    )
    .map_err(|err| err.to_string())?;
    let mut seen = BTreeSet::new();
    let mut urls = Vec::new();

    for capture in url_re.captures_iter(&body) {
        let Some(raw) = capture.get(1) else {
            continue;
        };
        let value = raw.as_str().trim();
        if value.contains('{') || value.contains('}') {
            continue;
        }
        let Ok(url) = base_url.join(value) else {
            continue;
        };
        if !same_origin(base_url, &url) {
            continue;
        }
        let key = url.as_str().to_owned();
        if seen.insert(key) {
            urls.push(url);
        }
    }

    Ok(urls)
}

fn same_origin(left: &reqwest::Url, right: &reqwest::Url) -> bool {
    left.scheme() == right.scheme()
        && left.host_str() == right.host_str()
        && left.port_or_known_default() == right.port_or_known_default()
}

fn is_subscription_resource(url: &reqwest::Url) -> bool {
    let path = url.path().to_ascii_lowercase();
    [".js", ".json", ".txt", ".csv"]
        .iter()
        .any(|suffix| path.ends_with(suffix))
}

fn extract_subscription_addresses(body: &str) -> Result<Vec<String>, String> {
    let body = decode_minimal_text_entities(body);
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

fn detect_subscription_response_blocker(
    headers: &reqwest::header::HeaderMap,
    body: &str,
) -> Option<&'static str> {
    if headers
        .get("x-vercel-mitigated")
        .and_then(|value| value.to_str().ok())
        .map_or(false, |value| value.eq_ignore_ascii_case("challenge"))
    {
        return Some(
            "site returned Vercel challenge; non-browser subscription requests are blocked",
        );
    }

    detect_subscription_blocker(body)
}

fn detect_subscription_blocker(body: &str) -> Option<&'static str> {
    if body.contains("Vercel Security Checkpoint") || body.contains("We're verifying your browser")
    {
        Some("site returned Vercel challenge; non-browser subscription requests are blocked")
    } else {
        None
    }
}

fn decode_minimal_text_entities(value: &str) -> String {
    value
        .replace("&amp;", "&")
        .replace("&#38;", "&")
        .replace("&#x26;", "&")
        .replace("&colon;", ":")
        .replace("&#58;", ":")
        .replace("&#x3a;", ":")
        .replace("&#x3A;", ":")
        .replace(r"\/", "/")
        .replace(r"\:", ":")
        .replace(r"\u002f", "/")
        .replace(r"\u002F", "/")
        .replace(r"\u003a", ":")
        .replace(r"\u003A", ":")
        .replace(r"\x3a", ":")
        .replace(r"\x3A", ":")
        .replace("%2F", "/")
        .replace("%2f", "/")
        .replace("%3A", ":")
        .replace("%3a", ":")
}

fn subscription_group_name(url: &str) -> String {
    let parse_input = if url.contains("://") {
        url.to_owned()
    } else {
        format!("https://{url}")
    };

    reqwest::Url::parse(&parse_input)
        .ok()
        .and_then(|url| url.host_str().map(|host| format!("Web:{host}")))
        .unwrap_or_else(|| "Web".to_owned())
}

fn resolve_endpoint(input: &str) -> Result<Endpoint, String> {
    let address = normalize_endpoint_input(input)?;
    let socket =
        resolve_ipv4(&address).map_err(|err| format!("failed to resolve {address}: {err}"))?;

    Ok(Endpoint {
        display: address,
        socket,
        groups: Vec::new(),
        drop_on_timeout: false,
        a2s_probe: false,
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

            let row = match query_server_info(
                endpoint.socket,
                timeout,
                endpoint.a2s_probe,
            ) {
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
    a2s_probe: bool,
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
    let mut buf = [0u8; 4096];
    let mut last_error = None;
    for _ in 0..3 {
        let request = build_a2s_info_request(None, a2s_probe);
        socket.send(&request).map_err(|err| err.to_string())?;
        let size = match socket.recv(&mut buf) {
            Ok(size) => size,
            Err(err) => {
                last_error = Some(err);
                continue;
            }
        };
        let packet = &buf[..size];

        if let Some(challenge) = parse_challenge(packet) {
            let request = build_a2s_info_request(Some(challenge), a2s_probe);
            socket.send(&request).map_err(|err| err.to_string())?;
            let size = match socket.recv(&mut buf) {
                Ok(size) => size,
                Err(err) => {
                    last_error = Some(err);
                    continue;
                }
            };
            let info = parse_server_info(&buf[..size])?;
            return Ok((info, started.elapsed()));
        }

        let info = parse_server_info(packet)?;
        return Ok((info, started.elapsed()));
    }

    Err(last_error
        .map(|err| err.to_string())
        .unwrap_or_else(|| "A2S_INFO 查询无响应".to_owned()))
}

fn build_a2s_info_request(challenge: Option<[u8; 4]>, a2s_probe: bool) -> Vec<u8> {
    let mut request = Vec::from(&b"\xFF\xFF\xFF\xFFTSource Engine Query\0"[..]);
    if let Some(challenge) = challenge {
        request.extend_from_slice(&challenge);
    }
    append_a2s_probe(&mut request, a2s_probe);
    request
}

fn append_a2s_probe(request: &mut Vec<u8>, a2s_probe: bool) {
    if !a2s_probe {
        return;
    }
    request.extend_from_slice(A2S_PROBE_MARKER);
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
            cmp_natural_ci(&name_key(a), &name_key(b))
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

#[derive(Debug, PartialEq, Eq)]
enum NaturalToken {
    Text(String),
    Number { value: u128, digits: usize },
}

fn cmp_natural_ci(left: &str, right: &str) -> std::cmp::Ordering {
    let left_tokens = natural_tokens(left);
    let right_tokens = natural_tokens(right);

    for (left, right) in left_tokens.iter().zip(right_tokens.iter()) {
        let ordering = match (left, right) {
            (NaturalToken::Text(left), NaturalToken::Text(right)) => left.cmp(right),
            (
                NaturalToken::Number {
                    value: left_value,
                    digits: left_digits,
                },
                NaturalToken::Number {
                    value: right_value,
                    digits: right_digits,
                },
            ) => left_value
                .cmp(right_value)
                .then_with(|| left_digits.cmp(right_digits)),
            (NaturalToken::Number { .. }, NaturalToken::Text(_)) => std::cmp::Ordering::Less,
            (NaturalToken::Text(_), NaturalToken::Number { .. }) => std::cmp::Ordering::Greater,
        };

        if ordering != std::cmp::Ordering::Equal {
            return ordering;
        }
    }

    left_tokens.len().cmp(&right_tokens.len())
}

fn natural_tokens(value: &str) -> Vec<NaturalToken> {
    let value = value.to_lowercase();
    let mut tokens = Vec::new();
    let mut current = String::new();
    let mut current_is_digit: Option<bool> = None;

    for ch in value.chars() {
        let is_digit = ch.is_ascii_digit();
        if current_is_digit == Some(is_digit) || current_is_digit.is_none() {
            current.push(ch);
            current_is_digit = Some(is_digit);
            continue;
        }

        push_natural_token(&mut tokens, &current, current_is_digit.unwrap_or(false));
        current.clear();
        current.push(ch);
        current_is_digit = Some(is_digit);
    }

    if !current.is_empty() {
        push_natural_token(&mut tokens, &current, current_is_digit.unwrap_or(false));
    }

    tokens
}

fn push_natural_token(tokens: &mut Vec<NaturalToken>, value: &str, is_digit: bool) {
    if is_digit {
        tokens.push(NaturalToken::Number {
            value: value.parse::<u128>().unwrap_or(u128::MAX),
            digits: value.len(),
        });
    } else {
        tokens.push(NaturalToken::Text(value.to_owned()));
    }
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
        "{:<48} {:<20} {:>7} {:>7} {:>4} {:<22} {:<4} {:<7} {}",
        "name", "group", "ping", "players", "bots", "map", "vac", "access", "address"
    );
    println!("{}", "-".repeat(153));

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
                    "{:<48} {:<20} {:>7} {:>7} {:>4} {:<22} {:<4} {:<7} {}",
                    clip(&info.name, 48),
                    groups,
                    ping,
                    players,
                    info.bots,
                    clip(&info.map, 22),
                    vac,
                    access,
                    row.endpoint.display
                );
            }
            None => {
                let error = row.error.as_deref().unwrap_or("not queried");
                println!(
                    "{:<48} {:<20} {:>7} {:>7} {:>4} {:<22} {:<4} {:<7} {}",
                    clip(error, 48),
                    groups,
                    "-",
                    "-",
                    "-",
                    "-",
                    "-",
                    "-",
                    row.endpoint.display
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
    a2s_probe: bool,
}

#[derive(Clone)]
struct AddSourceBansRequest {
    name: String,
    url: String,
    text: String,
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

#[derive(Clone)]
struct BroadcastHistoryRequest {
    base_url: String,
    token: String,
    time_zone: String,
}

#[derive(Clone)]
struct BroadcastHistoryResult {
    messages: Vec<BroadcastHistoryMessage>,
    auth_type: String,
    cache_ttl: Duration,
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
    drop_on_timeout: bool,
    #[serde(skip)]
    last_queried: Option<std::time::Instant>,
    #[serde(skip)]
    a2s_probe: bool,
}

fn server_group_counts(rows: &[ServerRowPayload]) -> Vec<(String, usize)> {
    let mut counts = BTreeMap::new();
    for row in rows {
        for group in &row.groups {
            *counts.entry(group.clone()).or_insert(0usize) += 1;
        }
    }
    counts.into_iter().collect()
}

fn subscription_source_label(subscription: &FileSourceBans, language: GuiLanguage) -> String {
    let server_count = subscription.servers.len();

    if !subscription.text.trim().is_empty() {
        let chars = subscription.text.chars().count();
        let mut label = match language {
            GuiLanguage::ZhCn => format!("粘贴文本（{chars} 字符）"),
            GuiLanguage::EnUs => format!("Pasted text ({chars} chars)"),
        };
        append_a2s_probe_label(&mut label, subscription.a2s_probe, language);
        return label;
    }

    let mut label = if subscription.url.trim().is_empty() {
        match language {
            GuiLanguage::ZhCn => "未设置来源".to_owned(),
            GuiLanguage::EnUs => "No source set".to_owned(),
        }
    } else {
        subscription.url.clone()
    };

    if server_count > 0 {
        let suffix = match language {
            GuiLanguage::ZhCn => format!(" · 已缓存 {server_count} 个服务器"),
            GuiLanguage::EnUs => format!(" · {server_count} cached servers"),
        };
        label.push_str(&suffix);
    }

    append_a2s_probe_label(&mut label, subscription.a2s_probe, language);
    label
}

fn append_a2s_probe_label(label: &mut String, a2s_probe: bool, language: GuiLanguage) {
    if !a2s_probe {
        return;
    }
    let suffix = match language {
        GuiLanguage::ZhCn => " · 准确延迟",
        GuiLanguage::EnUs => " · Accurate ping",
    };
    label.push_str(suffix);
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
    steam_id: Option<String>,
    points: Option<i32>,
    playtime_mins: Option<i32>,
    ppm: Option<f32>,
    quarter_points: Option<i32>,
}

#[derive(Clone)]
struct ManualServerEntry {
    group: String,
    server: String,
    a2s_probe: bool,
}

#[derive(Clone, Default)]
struct GuiConfigLists {
    manual_servers: Vec<ManualServerEntry>,
    sourcebans: Vec<FileSourceBans>,
}

#[derive(Clone, Serialize)]
pub struct TauriManualServer {
    index: usize,
    group: String,
    server: String,
    a2s_probe: bool,
}

#[derive(Clone, Serialize)]
pub struct TauriSourceBans {
    index: usize,
    name: String,
    url: String,
    a2s_probe: bool,
    source_label: String,
    server_count: usize,
}

#[derive(Clone, Serialize)]
pub struct TauriConfigLists {
    config_path: String,
    manual_servers: Vec<TauriManualServer>,
    sourcebans: Vec<TauriSourceBans>,
    api_base_url: String,
    api_token: Option<String>,
    gui_language: String,
    update_auto_check: bool,
    anne_stats: bool,
    rcon_password: Option<String>,
    rcon_passwords: BTreeMap<String, String>,
    theme_mode: String,
    accent_color: String,
    auto_refresh_empty_secs: u64,
    auto_refresh_active_secs: u64,
    auto_refresh_selected_secs: u64,
    time_zone: String,
}

#[derive(Clone, Deserialize)]
pub struct TauriSourceBansInput {
    config_path: Option<String>,
    index: Option<usize>,
    name: String,
    url: String,
    text: String,
}

#[derive(Clone, Deserialize)]
pub struct TauriServerQuery {
    config_path: Option<String>,
    search: Option<String>,
    group: Option<String>,
    only_with_players: Option<bool>,
    only_empty: Option<bool>,
    hide_timeout: Option<bool>,
    limit: Option<usize>,
    sockets: Option<Vec<String>>,
    a2s_probe_sockets: Option<Vec<String>>,
}

#[derive(Clone, Serialize)]
pub struct TauriServerSummary {
    total: usize,
    online: usize,
    players: u32,
    groups: Vec<(String, usize)>,
}

#[derive(Clone, Serialize)]
pub struct TauriServerRow {
    address: String,
    socket: String,
    groups: Vec<String>,
    group_label: String,
    a2s_probe: bool,
    name: String,
    map: String,
    ping_ms: Option<u64>,
    players: u8,
    max_players: u8,
    bots: u8,
    vac: bool,
    sv_tags: Option<String>,
    tags: Vec<String>,
    error: Option<String>,
    status: String,
    steam_url: String,
    is_anne: bool,
}

#[derive(Clone, Serialize)]
pub struct TauriServerRows {
    config_path: String,
    rows: Vec<TauriServerRow>,
    summary: TauriServerSummary,
}

pub fn tauri_config_path() -> String {
    default_gui_config_path().display().to_string()
}

pub fn load_tauri_config_lists(config_path: Option<String>) -> Result<TauriConfigLists, String> {
    let path = tauri_path(config_path);
    let lists = load_gui_config_lists(&path)?;
    let config = load_config_or_default(&path)?;
    let gui_language = config.gui.language;

    Ok(TauriConfigLists {
        config_path: path.display().to_string(),
        manual_servers: lists
            .manual_servers
            .into_iter()
            .enumerate()
            .map(|(index, entry)| TauriManualServer {
                index,
                group: entry.group,
                server: entry.server,
                a2s_probe: entry.a2s_probe,
            })
            .collect(),
        sourcebans: lists
            .sourcebans
            .into_iter()
            .enumerate()
            .map(|(index, subscription)| TauriSourceBans {
                index,
                name: subscription.name.clone(),
                url: subscription.url.clone(),
                a2s_probe: subscription.a2s_probe,
                source_label: subscription_source_label(&subscription, gui_language),
                server_count: subscription.servers.len(),
            })
            .collect(),
        api_base_url: config.api.base_url,
        api_token: config.api.token,
        gui_language: gui_language_code(gui_language).to_owned(),
        update_auto_check: config.updater.auto_check,
        anne_stats: config.gui.anne_stats,
        rcon_password: config.gui.rcon_password.clone(),
        rcon_passwords: config.gui.rcon_passwords.clone(),
        theme_mode: config.gui.theme_mode.clone(),
        accent_color: config.gui.accent_color.clone(),
        auto_refresh_empty_secs: config.gui.auto_refresh_empty_secs,
        auto_refresh_active_secs: config.gui.auto_refresh_active_secs,
        auto_refresh_selected_secs: config.gui.auto_refresh_selected_secs,
        time_zone: normalize_time_zone_setting(&config.gui.time_zone),
    })
}

pub fn load_tauri_server_rows(query: TauriServerQuery) -> Result<TauriServerRows, String> {
    let path = tauri_path(query.config_path.clone());
    let config = load_config_or_default(&path)?;
    let mut settings = RuntimeSettings::default();
    settings.apply_file_master(config.master.clone())?;
    settings.limit = query.limit.unwrap_or(settings.limit).max(1);
    settings.sort = SortKey::Players;

    let manual_groups = config
        .groups
        .clone()
        .into_iter()
        .filter_map(|group| ManualGroup::try_from(group).ok())
        .collect::<Vec<_>>();
    let subscriptions = config
        .sourcebans
        .clone()
        .into_iter()
        .filter_map(|subscription| SourceBansSubscription::try_from(subscription).ok())
        .collect::<Vec<_>>();
    let rows = if let Some(sockets) = query.sockets.as_deref() {
        load_selected_server_rows(
            &settings,
            sockets,
            query.a2s_probe_sockets.as_deref().unwrap_or(&[]),
        )?
    } else {
        load_server_rows(&settings, &manual_groups, &subscriptions)?
    };
    let mut payload = server_rows_payload(&rows)
        .into_iter()
        .map(tauri_server_row)
        .collect::<Vec<_>>();

    if query.only_with_players.unwrap_or(false) {
        payload.retain(|row| row.players > 0);
    }
    if query.only_empty.unwrap_or(false) {
        payload.retain(|row| row.error.is_none() && row.players == 0);
    }
    if query.hide_timeout.unwrap_or(false) {
        payload.retain(|row| row.error.is_none());
    }
    if let Some(search) = query
        .search
        .as_deref()
        .map(str::trim)
        .filter(|value| !value.is_empty())
    {
        let search = search.to_lowercase();
        payload.retain(|row| {
            row.name.to_lowercase().contains(&search)
                || row.map.to_lowercase().contains(&search)
                || row.address.to_lowercase().contains(&search)
                || row.socket.to_lowercase().contains(&search)
                || row
                    .tags
                    .iter()
                    .any(|tag| tag.to_lowercase().contains(&search))
                || row
                    .groups
                    .iter()
                    .any(|group| group.to_lowercase().contains(&search))
        });
    }

    let groups = tauri_server_summary(&payload).groups;
    if let Some(group) = query.group.as_deref().map(str::trim).filter(|value| {
        !value.is_empty() && *value != "全部服务器" && !value.eq_ignore_ascii_case("all")
    }) {
        payload.retain(|row| row.groups.iter().any(|item| item == group));
    }

    prefetch_tauri_player_cache(&config, &payload);

    let mut summary = tauri_server_summary(&payload);
    summary.groups = groups;
    Ok(TauriServerRows {
        config_path: path.display().to_string(),
        rows: payload,
        summary,
    })
}

pub fn add_tauri_manual_server(
    config_path: Option<String>,
    group: String,
    server: String,
    a2s_probe: Option<bool>,
) -> Result<TauriConfigLists, String> {
    let path = tauri_path(config_path.clone());
    add_server_to_config(
        &path,
        AddServerRequest {
            group,
            server,
            a2s_probe: a2s_probe.unwrap_or(false),
        },
    )?;
    load_tauri_config_lists(config_path)
}

pub fn save_tauri_sourcebans(input: TauriSourceBansInput) -> Result<TauriConfigLists, String> {
    let path = tauri_path(input.config_path.clone());
    let request = AddSourceBansRequest {
        name: input.name,
        url: input.url,
        text: input.text,
    };
    if let Some(index) = input.index {
        update_sourcebans_in_config(&path, index, request)?;
    } else {
        add_sourcebans_to_config(&path, request)?;
    }
    load_tauri_config_lists(input.config_path)
}

pub fn delete_tauri_sourcebans(
    config_path: Option<String>,
    index: usize,
) -> Result<TauriConfigLists, String> {
    let path = tauri_path(config_path.clone());
    delete_sourcebans_from_config(&path, index)?;
    load_tauri_config_lists(config_path)
}

pub fn refresh_tauri_sourcebans(config_path: Option<String>) -> Result<TauriConfigLists, String> {
    let path = tauri_path(config_path.clone());
    refresh_all_subscriptions_in_config(&path)?;
    load_tauri_config_lists(config_path)
}

pub fn open_tauri_steam_connect(address: String) -> Result<(), String> {
    launch_steam_connect(&address);
    Ok(())
}

fn tauri_path(config_path: Option<String>) -> PathBuf {
    config_path
        .filter(|value| !value.trim().is_empty())
        .map(PathBuf::from)
        .unwrap_or_else(default_gui_config_path)
}

fn tauri_server_row(row: ServerRowPayload) -> TauriServerRow {
    let name = row
        .info
        .as_ref()
        .map(|info| info.name.clone())
        .unwrap_or_else(|| row.error.clone().unwrap_or_else(|| "等待刷新".to_owned()));
    let map = row
        .info
        .as_ref()
        .map(|info| info.map.clone())
        .unwrap_or_else(|| "-".to_owned());
    let players = row.info.as_ref().map(|info| info.players).unwrap_or(0);
    let max_players = row.info.as_ref().map(|info| info.max_players).unwrap_or(0);
    let bots = row.info.as_ref().map(|info| info.bots).unwrap_or(0);
    let vac = row.info.as_ref().map(|info| info.vac).unwrap_or(false);
    let sv_tags = row.info.as_ref().and_then(|info| info.keywords.clone());
    let tags = sv_tags
        .as_deref()
        .map(split_server_tags)
        .unwrap_or_default();
    let status = if row.error.is_some() {
        "超时".to_owned()
    } else if players > 0 {
        "有人".to_owned()
    } else {
        "空服".to_owned()
    };
    let group_label = row.groups.join(" / ");
    let steam_url = format!("steam://connect/{}", row.socket);
    let is_anne = row
        .info
        .as_ref()
        .map(is_anne_server_info)
        .unwrap_or_else(|| is_anne_server_name(&name));

    TauriServerRow {
        address: row.address,
        socket: row.socket,
        groups: row.groups,
        group_label,
        a2s_probe: row.a2s_probe,
        name,
        map,
        ping_ms: row.ping_ms,
        players,
        max_players,
        bots,
        vac,
        sv_tags,
        tags,
        error: row.error,
        status,
        steam_url,
        is_anne,
    }
}

fn tauri_server_summary(rows: &[TauriServerRow]) -> TauriServerSummary {
    let mut groups = BTreeMap::new();
    let mut online = 0usize;
    let mut players = 0u32;

    for row in rows {
        if row.error.is_none() {
            online += 1;
        }
        players += row.players as u32;
        for group in &row.groups {
            *groups.entry(group.clone()).or_insert(0usize) += 1;
        }
    }

    TauriServerSummary {
        total: rows.len(),
        online,
        players,
        groups: groups.into_iter().collect(),
    }
}

// ── New Tauri public API ──────────────────────────────────────────────────────

#[derive(Clone, Serialize)]
pub struct TauriPlayerInfo {
    pub name: String,
    pub score: i32,
    pub duration_secs: f32,
    pub steam_id: Option<String>,
    pub points: Option<i32>,
    pub playtime_mins: Option<i32>,
    pub ppm: Option<f32>,
    pub quarter_points: Option<i32>,
}

#[derive(Clone, Deserialize)]
pub struct TauriRconRequest {
    pub config_path: Option<String>,
    pub address: String,
    pub password: String,
    pub command: String,
    pub timeout_ms: Option<u64>,
}

#[derive(Clone, Serialize)]
pub struct TauriCvarEntry {
    pub name: String,
    pub value: String,
}

#[derive(Clone, Deserialize)]
pub struct TauriCvarRequest {
    pub config_path: Option<String>,
    pub address: String,
    pub password: Option<String>,
    pub names: Option<Vec<String>>,
    pub timeout_ms: Option<u64>,
}

#[derive(Clone, Serialize)]
pub struct TauriNetworkInfo {
    pub address: String,
    pub ip: String,
    pub country: String,
    pub region: String,
    pub city: String,
    pub isp: String,
    pub org: String,
    pub asn: String,
}

#[derive(Clone, Serialize)]
pub struct TauriUpdateInfo {
    pub latest_version: String,
    pub html_url: String,
    pub available: bool,
    pub current_version: String,
    pub download_url: Option<String>,
    pub download_name: Option<String>,
}

#[derive(Clone, Deserialize)]
pub struct TauriInstallUpdateRequest {
    pub url: String,
    pub file_name: Option<String>,
}

#[derive(Clone, Serialize)]
pub struct TauriInstallUpdateResult {
    pub message: String,
    pub should_exit: bool,
}

#[derive(Clone, Serialize)]
pub struct TauriApiUser {
    pub steam_id: String,
    pub steam_name: String,
    pub avatar: String,
    pub is_admin: bool,
}

#[derive(Clone, Serialize)]
pub struct TauriLoginStart {
    pub user_code: String,
    pub verification_url: String,
    pub expires_in: u64,
    pub interval: u64,
    pub device_code: String,
}

#[derive(Clone, Deserialize)]
pub struct TauriLoginPollRequest {
    pub base_url: String,
    pub device_code: String,
}

#[derive(Clone, Serialize)]
pub struct TauriLoginResult {
    pub token: String,
    pub steam_name: String,
    pub steam_id: String,
    pub avatar: String,
    pub is_admin: bool,
}

#[derive(Clone, Serialize)]
pub struct TauriGlobalPlayer {
    pub name: String,
    pub server_name: String,
    pub server_address: String,
    pub score: i32,
    pub duration_secs: f32,
    pub steam_id: Option<String>,
    pub points: Option<i32>,
    pub playtime_mins: Option<i32>,
    pub ppm: Option<f32>,
    pub quarter_points: Option<i32>,
}

#[derive(Clone, Serialize)]
pub struct TauriBroadcastMessage {
    pub id: u64,
    pub message: String,
    pub sender_name: String,
    pub sent_at: String,
    pub sent_at_display: String,
}

#[derive(Clone, Serialize)]
pub struct TauriBroadcastHistoryResult {
    pub messages: Vec<TauriBroadcastMessage>,
    pub anonymous: bool,
    pub cache_ttl_secs: u64,
}

#[derive(Clone, Deserialize)]
pub struct TauriBroadcastRequest {
    pub base_url: String,
    pub token: String,
    pub message: String,
    pub time_zone: Option<String>,
}

#[derive(Clone, Deserialize)]
pub struct TauriBroadcastHistoryRequest {
    pub base_url: String,
    pub token: String,
    pub time_zone: Option<String>,
}

#[derive(Clone, Deserialize)]
pub struct TauriSaveApiConfigRequest {
    pub config_path: Option<String>,
    pub base_url: String,
    pub token: Option<String>,
}

#[derive(Clone, Deserialize)]
pub struct TauriSaveRconPasswordRequest {
    pub config_path: Option<String>,
    pub address: String,
    pub password: Option<String>,
}

#[derive(Clone, Deserialize)]
pub struct TauriGuiSettingsRequest {
    pub config_path: Option<String>,
    pub language: Option<String>,
    pub update_auto_check: Option<bool>,
    pub anne_stats: Option<bool>,
    pub theme_mode: Option<String>,
    pub accent_color: Option<String>,
    pub auto_refresh_empty_secs: Option<u64>,
    pub auto_refresh_active_secs: Option<u64>,
    pub auto_refresh_selected_secs: Option<u64>,
    pub time_zone: Option<String>,
}

#[derive(Clone, Deserialize)]
pub struct TauriDeleteManualServerRequest {
    pub config_path: Option<String>,
    pub group: String,
    pub server: String,
}

pub fn tauri_delete_manual_server(
    req: TauriDeleteManualServerRequest,
) -> Result<TauriConfigLists, String> {
    let path = tauri_path(req.config_path.clone());
    delete_server_from_config(&path, &req.group, &req.server)?;
    load_tauri_config_lists(req.config_path)
}

fn cached_tauri_players(address: &str) -> Option<Vec<TauriPlayerInfo>> {
    let cache = tauri_player_cache().lock().ok()?;
    let entry = cache.get(address)?;
    if entry.fetched_at.elapsed() < TAURI_PLAYER_CACHE_TTL {
        Some(entry.players.clone())
    } else {
        None
    }
}

fn store_tauri_players(address: &str, players: Vec<TauriPlayerInfo>) {
    if let Ok(mut cache) = tauri_player_cache().lock() {
        cache.insert(
            address.to_owned(),
            CachedTauriPlayers {
                fetched_at: Instant::now(),
                players,
            },
        );
    }
}

fn player_info_to_tauri(player: PlayerInfo) -> TauriPlayerInfo {
    TauriPlayerInfo {
        name: player.name,
        score: player.score,
        duration_secs: player.duration,
        steam_id: player.steam_id,
        points: player.points,
        playtime_mins: player.playtime_mins,
        ppm: player.ppm,
        quarter_points: player.quarter_points,
    }
}

fn query_tauri_players_uncached(
    config: &BrowserConfig,
    address: &str,
    is_anne_server: Option<bool>,
) -> Result<Vec<TauriPlayerInfo>, String> {
    let endpoint = resolve_endpoint(address)?;
    let timeout = Duration::from_millis(2500);
    let mut players = query_server_players(endpoint.socket, timeout)?;
    if config.gui.anne_stats {
        let is_anne_server = is_anne_server.unwrap_or_else(|| {
            query_server_info(endpoint.socket, Duration::from_millis(1500), false)
                .map(|(info, _)| is_anne_server_info(&info))
                .unwrap_or(false)
        });
        if is_anne_server && !config.api.base_url.trim().is_empty() {
            let cache = tauri_online_stats_cache();
            let token = config.api.token.as_deref().unwrap_or("");
            let _ = refresh_online_player_stats_cache(&config.api.base_url, token, cache, false);
            let _ = apply_cached_player_stats(&config.api.base_url, token, cache, &mut players);
        }
    }
    Ok(players.into_iter().map(player_info_to_tauri).collect())
}

fn prefetch_tauri_player_cache(config: &BrowserConfig, rows: &[TauriServerRow]) {
    let queue = rows
        .iter()
        .filter(|row| row.error.is_none() && row.players > 0)
        .map(|row| (row.address.clone(), row.is_anne))
        .collect::<VecDeque<_>>();
    if queue.is_empty() {
        return;
    }

    let config = config.clone();
    let _ = thread::spawn(move || {
        let queue = Arc::new(Mutex::new(queue));
        let config = Arc::new(config);
        let mut workers = Vec::new();
        let worker_count = queue
            .lock()
            .map(|queue| queue.len())
            .unwrap_or(0)
            .min(16)
            .max(1);
        for _ in 0..worker_count {
            let queue = Arc::clone(&queue);
            let config = Arc::clone(&config);
            workers.push(thread::spawn(move || loop {
                let item = {
                    let Ok(mut queue) = queue.lock() else {
                        break;
                    };
                    queue.pop_front()
                };
                let Some((address, is_anne_server)) = item else {
                    break;
                };
                if cached_tauri_players(&address).is_some() {
                    continue;
                }
                if let Ok(players) =
                    query_tauri_players_uncached(&config, &address, Some(is_anne_server))
                {
                    store_tauri_players(&address, players);
                }
            }));
        }
        for worker in workers {
            let _ = worker.join();
        }
    });
}

pub fn tauri_query_players(
    config_path: Option<String>,
    address: String,
) -> Result<Vec<TauriPlayerInfo>, String> {
    if let Some(players) = cached_tauri_players(&address) {
        return Ok(players);
    }
    let path = tauri_path(config_path);
    let config = load_config_or_default(&path)?;
    let players = query_tauri_players_uncached(&config, &address, None)?;
    store_tauri_players(&address, players.clone());
    Ok(players)
}

pub fn tauri_run_rcon(req: TauriRconRequest) -> Result<String, String> {
    let timeout = Duration::from_millis(req.timeout_ms.unwrap_or(5000).max(500));
    rcon_command(&req.address, &req.password, &req.command, timeout)
}

pub fn tauri_read_cvars(req: TauriCvarRequest) -> Result<Vec<TauriCvarEntry>, String> {
    let payload = read_cvars(CvarRequest {
        address: req.address,
        password: req.password,
        names: req.names,
        timeout_ms: req.timeout_ms,
    })?;
    Ok(payload
        .values
        .into_iter()
        .map(|(name, value)| TauriCvarEntry { name, value })
        .collect())
}

pub fn tauri_fetch_network_info(address: String, ip: String) -> Result<TauriNetworkInfo, String> {
    let info = fetch_server_network_info(&address, &ip)?;
    Ok(TauriNetworkInfo {
        address: info.address,
        ip: info.ip,
        country: info.country,
        region: info.region,
        city: info.city,
        isp: info.isp,
        org: info.org,
        asn: info.asn,
    })
}

pub fn tauri_check_update() -> Result<TauriUpdateInfo, String> {
    let info = check_latest_release()?;
    Ok(TauriUpdateInfo {
        latest_version: info.latest_version,
        html_url: info.html_url,
        available: info.available,
        current_version: env!("CARGO_PKG_VERSION").to_owned(),
        download_url: info.download_url,
        download_name: info.download_name,
    })
}

pub fn tauri_install_update(
    req: TauriInstallUpdateRequest,
) -> Result<TauriInstallUpdateResult, String> {
    download_and_launch_portable_update(req)
}

pub fn tauri_api_me(base_url: String, token: String) -> Result<TauriApiUser, String> {
    let user = api_me(&base_url, &token)?;
    Ok(TauriApiUser {
        steam_id: user.steam_id,
        steam_name: user.name,
        avatar: user.avatar,
        is_admin: user.is_admin,
    })
}

pub fn tauri_steam_login_start(base_url: String) -> Result<TauriLoginStart, String> {
    let client = api_client(Duration::from_secs(10))?;
    let start_url = api_url(&base_url, "/api/auth/device_start.php")?;
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
    Ok(TauriLoginStart {
        user_code: start.user_code,
        verification_url: start.verification_url,
        expires_in: start.expires_in,
        interval: start.interval,
        device_code: start.device_code,
    })
}

pub fn tauri_steam_login_poll(
    req: TauriLoginPollRequest,
) -> Result<Option<TauriLoginResult>, String> {
    let client = api_client(Duration::from_secs(15))?;
    let poll_url = api_url(&req.base_url, "/api/auth/device_poll.php")?;
    let response: DevicePollResponse = response_json(
        client
            .post(poll_url)
            .json(&serde_json::json!({ "device_code": req.device_code }))
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
        return Ok(Some(TauriLoginResult {
            token,
            steam_name: user.name,
            steam_id: user.steam_id,
            avatar: user.avatar,
            is_admin: user.is_admin,
        }));
    }

    if response.error.as_deref() == Some("authorization_pending")
        || response.status.as_deref() == Some("authorization_pending")
    {
        return Ok(None);
    }

    Err(response
        .message
        .or(response.error)
        .unwrap_or_else(|| "Steam login failed".to_owned()))
}

pub fn tauri_api_logout(base_url: String, token: String) -> Result<(), String> {
    api_logout(&base_url, &token)
}

pub fn tauri_send_broadcast(req: TauriBroadcastRequest) -> Result<TauriBroadcastMessage, String> {
    let time_zone = normalize_time_zone_setting(req.time_zone.as_deref().unwrap_or(""));
    let result = api_broadcast(BroadcastRequest {
        base_url: req.base_url,
        token: req.token,
        message: req.message,
    })?;
    let created_at = result
        .message_row
        .as_ref()
        .map(|message| message.created_at.as_str())
        .or(result.created_at.as_deref())
        .unwrap_or("");
    Ok(TauriBroadcastMessage {
        id: result.id.unwrap_or(0),
        message: result
            .message_row
            .as_ref()
            .map(|message| message.message.clone())
            .unwrap_or_else(|| result.message.unwrap_or_else(|| "已发送".to_owned())),
        sender_name: result
            .message_row
            .as_ref()
            .map(|message| message.name.clone())
            .or(result.sender_name)
            .unwrap_or_default(),
        sent_at: created_at.to_owned(),
        sent_at_display: format_broadcast_time(created_at, &time_zone),
    })
}

pub fn tauri_load_broadcast_history(
    req: TauriBroadcastHistoryRequest,
) -> Result<TauriBroadcastHistoryResult, String> {
    let time_zone = normalize_time_zone_setting(req.time_zone.as_deref().unwrap_or(""));
    let result = api_broadcast_history(BroadcastHistoryRequest {
        base_url: req.base_url,
        token: req.token,
        time_zone: time_zone.clone(),
    })?;
    let messages = result
        .messages
        .into_iter()
        .map(|m| TauriBroadcastMessage {
            id: m.id,
            message: m.message,
            sender_name: m.name,
            sent_at_display: format_broadcast_time(&m.created_at, &time_zone),
            sent_at: m.created_at,
        })
        .collect();
    Ok(TauriBroadcastHistoryResult {
        messages,
        anonymous: result.auth_type != "steam",
        cache_ttl_secs: result.cache_ttl.as_secs(),
    })
}

pub fn tauri_load_global_players(
    base_url: String,
    token: String,
    force_stats: bool,
    config_path: Option<String>,
) -> Result<Vec<TauriGlobalPlayer>, String> {
    let path = tauri_path(config_path);
    let mut config = load_config_or_default(&path)?;
    let mut settings = RuntimeSettings::default();
    settings.apply_file_master(config.master.clone())?;
    settings.limit = 500;
    settings.sort = SortKey::Players;

    let manual_groups = config
        .groups
        .clone()
        .into_iter()
        .filter_map(|group| ManualGroup::try_from(group).ok())
        .collect::<Vec<_>>();
    let subscriptions = config
        .sourcebans
        .clone()
        .into_iter()
        .filter_map(|subscription| SourceBansSubscription::try_from(subscription).ok())
        .collect::<Vec<_>>();

    let rows = load_server_rows(&settings, &manual_groups, &subscriptions)?;
    let api_base = if base_url.trim().is_empty() {
        config.api.base_url.clone()
    } else {
        base_url.clone()
    };
    let api_token = if token.trim().is_empty() {
        config.api.token.clone().unwrap_or_default()
    } else {
        token
    };
    config.api.base_url = api_base.clone();
    config.api.token = non_empty(api_token.clone(), "api_token").ok();

    let servers_to_query = rows
        .iter()
        .filter_map(|row| {
            let info = row.info.as_ref()?;
            Some((
                row.endpoint.display.clone(),
                info.name.clone(),
                is_anne_server_info(info),
            ))
        })
        .collect::<Vec<_>>();

    if servers_to_query.is_empty() {
        return Ok(Vec::new());
    }

    if config.gui.anne_stats
        && !api_base.trim().is_empty()
        && servers_to_query.iter().any(|(_, _, is_anne)| *is_anne)
    {
        let cache = tauri_online_stats_cache();
        let _ = refresh_online_player_stats_cache(&api_base, &api_token, cache, force_stats);
    }

    let config = Arc::new(config);
    let queue = Arc::new(Mutex::new(VecDeque::from(servers_to_query)));
    let result = Arc::new(Mutex::new(Vec::new()));
    let worker_count = queue
        .lock()
        .map(|queue| queue.len())
        .unwrap_or(0)
        .min(16)
        .max(1);
    let mut workers = Vec::new();

    for _ in 0..worker_count {
        let queue = Arc::clone(&queue);
        let result = Arc::clone(&result);
        let config = Arc::clone(&config);
        workers.push(thread::spawn(move || loop {
            let item = {
                let Ok(mut queue) = queue.lock() else {
                    break;
                };
                queue.pop_front()
            };
            let Some((server_address, server_name, is_anne_server)) = item else {
                break;
            };

            let players = if let Some(players) = cached_tauri_players(&server_address) {
                players
            } else {
                let Ok(players) =
                    query_tauri_players_uncached(&config, &server_address, Some(is_anne_server))
                else {
                    continue;
                };
                store_tauri_players(&server_address, players.clone());
                players
            };
            let Ok(mut result) = result.lock() else {
                break;
            };
            for p in players {
                if p.name.trim().is_empty() {
                    continue;
                }
                result.push(TauriGlobalPlayer {
                    name: p.name,
                    server_name: server_name.clone(),
                    server_address: server_address.clone(),
                    score: p.score,
                    duration_secs: p.duration_secs,
                    steam_id: p.steam_id,
                    points: p.points,
                    playtime_mins: p.playtime_mins,
                    ppm: p.ppm,
                    quarter_points: p.quarter_points,
                });
            }
        }));
    }

    for worker in workers {
        let _ = worker.join();
    }

    let mut result = Arc::try_unwrap(result)
        .map_err(|_| "global player result still shared".to_owned())?
        .into_inner()
        .map_err(|_| "global player result lock poisoned".to_owned())?;
    result.sort_by(|a, b| {
        b.duration_secs
            .partial_cmp(&a.duration_secs)
            .unwrap_or(std::cmp::Ordering::Equal)
    });
    Ok(result)
}

pub fn tauri_save_rcon_password(
    req: TauriSaveRconPasswordRequest,
) -> Result<TauriConfigLists, String> {
    let path = tauri_path(req.config_path.clone());
    let mut config = load_config_or_default(&path)?;
    let address = req.address.trim();
    if address.is_empty() {
        return Err("server address is required".to_owned());
    }
    if let Some(password) = req.password {
        let password = password.trim().to_owned();
        if password.is_empty() {
            config.gui.rcon_passwords.remove(address);
        } else {
            config
                .gui
                .rcon_passwords
                .insert(address.to_owned(), password);
        }
    } else {
        config.gui.rcon_passwords.remove(address);
    }
    save_config(&path, &config)?;
    load_tauri_config_lists(Some(path.display().to_string()))
}

pub fn tauri_save_api_config(req: TauriSaveApiConfigRequest) -> Result<(), String> {
    let path = tauri_path(req.config_path);
    save_api_config_to_config(&path, &req.base_url, req.token.as_deref())
}

pub fn tauri_save_gui_settings(req: TauriGuiSettingsRequest) -> Result<TauriConfigLists, String> {
    let path = tauri_path(req.config_path.clone());
    let mut config = load_config_or_default(&path)?;
    if let Some(language) = req.language {
        config.gui.language = parse_gui_language_setting(&language)?;
    }
    if let Some(auto_check) = req.update_auto_check {
        config.updater.auto_check = auto_check;
    }
    if let Some(anne_stats) = req.anne_stats {
        config.gui.anne_stats = anne_stats;
    }
    if let Some(theme_mode) = req.theme_mode {
        let theme_mode = theme_mode.trim();
        if matches!(theme_mode, "light" | "dark" | "custom") {
            config.gui.theme_mode = theme_mode.to_owned();
        }
    }
    if let Some(accent_color) = req.accent_color {
        let accent_color = accent_color.trim();
        if accent_color.starts_with('#') && accent_color.len() == 7 {
            config.gui.accent_color = accent_color.to_owned();
        }
    }
    if let Some(seconds) = req.auto_refresh_empty_secs {
        config.gui.auto_refresh_empty_secs = seconds.max(15);
    }
    if let Some(seconds) = req.auto_refresh_active_secs {
        config.gui.auto_refresh_active_secs = seconds.max(5);
    }
    if let Some(seconds) = req.auto_refresh_selected_secs {
        config.gui.auto_refresh_selected_secs = seconds.max(3);
    }
    if let Some(time_zone) = req.time_zone {
        config.gui.time_zone = normalize_time_zone_setting(&time_zone);
    }
    save_config(&path, &config)?;
    load_tauri_config_lists(Some(path.display().to_string()))
}

#[derive(Clone)]
struct UpdateInfo {
    latest_version: String,
    html_url: String,
    available: bool,
    download_url: Option<String>,
    download_name: Option<String>,
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
    steam_id: Option<String>,
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
    sender_name: Option<String>,
    created_at: Option<String>,
    message_row: Option<BroadcastHistoryMessage>,
    error: Option<String>,
    daily_limit: Option<i32>,
    daily_used: Option<i32>,
    daily_remaining: Option<i32>,
    points: Option<i32>,
    unlimited: Option<bool>,
}

#[derive(Clone, Debug, Deserialize)]
struct ApiBroadcastHistoryResponse {
    ok: bool,
    messages: Vec<BroadcastHistoryMessage>,
    cache_ttl: Option<u64>,
    auth_type: Option<String>,
    message: Option<String>,
    error: Option<String>,
}

#[derive(Clone, Debug, Deserialize)]
struct BroadcastHistoryMessage {
    id: u64,
    created_at: String,
    server: String,
    port: i32,
    steamid: String,
    name: String,
    message: String,
}

#[derive(Clone, Debug, Deserialize)]
struct OnlinePlayersResponse {
    ok: bool,
    players: Vec<PlayerStats>,
    cache_ttl: Option<u64>,
    limit: Option<usize>,
    offset: Option<usize>,
    has_more: Option<bool>,
    message: Option<String>,
    error: Option<String>,
}

#[derive(Clone, Debug, Deserialize)]
struct PlayerStats {
    #[serde(default)]
    steamid: String,
    name: String,
    total_points: i32,
    playtime_minutes: i32,
    ppm: f32,
    quarter_points: i32,
    #[serde(default)]
    updated: i64,
}

#[derive(Default)]
struct OnlineStatsCache {
    base_url: String,
    token_key: String,
    fetched_at: Option<Instant>,
    max_age: Duration,
    stats: HashMap<String, PlayerStats>,
}

type SharedOnlineStatsCache = Arc<Mutex<OnlineStatsCache>>;

static TAURI_ONLINE_STATS_CACHE: OnceLock<SharedOnlineStatsCache> = OnceLock::new();

fn tauri_online_stats_cache() -> &'static SharedOnlineStatsCache {
    TAURI_ONLINE_STATS_CACHE.get_or_init(|| Arc::new(Mutex::new(OnlineStatsCache::default())))
}

#[derive(Clone)]
struct CachedTauriPlayers {
    fetched_at: Instant,
    players: Vec<TauriPlayerInfo>,
}

type SharedTauriPlayerCache = Arc<Mutex<HashMap<String, CachedTauriPlayers>>>;

static TAURI_PLAYER_CACHE: OnceLock<SharedTauriPlayerCache> = OnceLock::new();

fn tauri_player_cache() -> &'static SharedTauriPlayerCache {
    TAURI_PLAYER_CACHE.get_or_init(|| Arc::new(Mutex::new(HashMap::new())))
}

#[derive(Clone, Debug)]
struct ServerNetworkInfo {
    address: String,
    ip: String,
    country: String,
    region: String,
    city: String,
    isp: String,
    org: String,
    asn: String,
}

#[derive(Clone, Debug, Deserialize)]
struct IpApiResponse {
    status: String,
    message: Option<String>,
    country: Option<String>,
    #[serde(rename = "regionName")]
    region_name: Option<String>,
    city: Option<String>,
    isp: Option<String>,
    org: Option<String>,
    #[serde(rename = "as")]
    asn: Option<String>,
    query: Option<String>,
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
    Players(String, Result<(Vec<PlayerInfo>, bool), String>),
    GlobalPlayers(Result<(Vec<GlobalPlayerEntry>, bool), String>),
    OnlineStatsRefresh(Result<(), String>),
    DeleteServer(Result<(), String>),
    ApiMe(Result<ApiUser, String>),
    SteamLoginStarted(Result<DeviceStartResponse, String>),
    SteamLoginFinished(Result<ApiLoginSession, String>),
    Broadcast(Result<ApiBroadcastResponse, String>),
    BroadcastHistory(Result<BroadcastHistoryResult, String>),
    ServerUpdate(String, Result<ServerRowPayload, String>),
    NetworkInfo(String, Result<ServerNetworkInfo, String>),
    SubscriptionRefresh(Result<(), String>),
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
    anne_stats_enabled: bool,
    update_status: String,
    update_url: Option<String>,
    server_status: String,
    config_status: String,
    group_name: String,
    server_address: String,
    server_a2s_probe: bool,
    sourcebans_name: String,
    sourcebans_url: String,
    sourcebans_text: String,
    rcon_address: String,
    rcon_password: String,
    rcon_command_text: String,
    rcon_output: String,
    cvar_address: String,
    cvar_password: String,
    cvar_names: String,
    cvar_output: String,
    player_output: String,
    selected_server_network: Option<ServerNetworkInfo>,
    network_info_cache: HashMap<String, ServerNetworkInfo>,
    network_info_status: String,
    // 新增 UI 交互状态
    ui_search_query: String,
    ui_group_filter: Option<String>,
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
    online_stats_cache: SharedOnlineStatsCache,
    online_stats_refreshing: bool,
    online_stats_last_attempt: Option<Instant>,
    api_base_url: String,
    api_token: String,
    api_user: Option<ApiUser>,
    api_status: String,
    steam_login_in_progress: bool,
    broadcast_message: String,
    broadcast_output: String,
    broadcast_sending: bool,
    broadcast_history: Vec<BroadcastHistoryMessage>,
    broadcast_history_status: String,
    broadcast_history_querying: bool,
    time_zone: String,
}

fn app_bg() -> egui::Color32 {
    egui::Color32::from_rgb(245, 247, 251)
}

fn surface_color() -> egui::Color32 {
    egui::Color32::from_rgb(255, 255, 255)
}

fn surface_alt_color() -> egui::Color32 {
    egui::Color32::from_rgb(248, 250, 252)
}

fn border_color() -> egui::Color32 {
    egui::Color32::from_rgb(226, 232, 240)
}

fn input_border_color() -> egui::Color32 {
    egui::Color32::from_rgb(148, 163, 184)
}

fn text_primary_color() -> egui::Color32 {
    egui::Color32::from_rgb(15, 23, 42)
}

fn text_muted_color() -> egui::Color32 {
    egui::Color32::from_rgb(100, 116, 139)
}

fn accent_color() -> egui::Color32 {
    egui::Color32::from_rgb(37, 99, 235)
}

fn sidebar_bg_color() -> egui::Color32 {
    egui::Color32::from_rgb(15, 23, 42)
}

fn sidebar_hover_color() -> egui::Color32 {
    egui::Color32::from_rgb(30, 41, 59)
}

fn success_color() -> egui::Color32 {
    egui::Color32::from_rgb(22, 163, 74)
}

fn warning_color() -> egui::Color32 {
    egui::Color32::from_rgb(217, 119, 6)
}

fn danger_color() -> egui::Color32 {
    egui::Color32::from_rgb(220, 38, 38)
}

fn modern_card<R>(
    ui: &mut egui::Ui,
    add_contents: impl FnOnce(&mut egui::Ui) -> R,
) -> egui::InnerResponse<R> {
    egui::Frame::canvas(ui.style())
        .fill(surface_color())
        .stroke(egui::Stroke::new(1.0, border_color()))
        .corner_radius(egui::CornerRadius::same(10))
        .inner_margin(egui::Margin::same(14))
        .show(ui, add_contents)
}

fn stat_card(ui: &mut egui::Ui, label: &str, value: String, color: egui::Color32) {
    modern_card(ui, |ui| {
        ui.set_min_width(154.0);
        ui.label(
            egui::RichText::new(label)
                .size(12.0)
                .color(text_muted_color()),
        );
        ui.add_space(4.0);
        ui.heading(egui::RichText::new(value).size(20.0).strong().color(color));
    });
}

fn player_metric_chip(ui: &mut egui::Ui, label: &str, value: String, color: egui::Color32) {
    egui::Frame::canvas(ui.style())
        .fill(surface_alt_color())
        .stroke(egui::Stroke::new(1.0, border_color()))
        .corner_radius(egui::CornerRadius::same(8))
        .inner_margin(egui::Margin::symmetric(10, 7))
        .show(ui, |ui| {
            ui.set_min_width(88.0);
            ui.label(
                egui::RichText::new(label)
                    .size(11.0)
                    .color(text_muted_color()),
            );
            ui.add_space(2.0);
            ui.label(egui::RichText::new(value).strong().color(color));
        });
}

fn nav_button(ui: &mut egui::Ui, selected: bool, label: &str) -> egui::Response {
    let fill = if selected {
        egui::Color32::WHITE
    } else {
        sidebar_hover_color()
    };
    let stroke = if selected {
        egui::Stroke::new(1.0, egui::Color32::WHITE)
    } else {
        egui::Stroke::new(1.0, egui::Color32::from_rgb(51, 65, 85))
    };
    let text_color = if selected {
        accent_color()
    } else {
        egui::Color32::from_rgb(226, 232, 240)
    };

    ui.add_sized(
        [ui.available_width(), 40.0],
        egui::Button::new(egui::RichText::new(label).strong().color(text_color))
            .fill(fill)
            .stroke(stroke)
            .corner_radius(egui::CornerRadius::same(10)),
    )
}

fn primary_button(label: &str) -> egui::Button<'_> {
    egui::Button::new(
        egui::RichText::new(label)
            .strong()
            .color(egui::Color32::WHITE),
    )
    .fill(accent_color())
    .stroke(egui::Stroke::new(1.0, accent_color()))
    .corner_radius(egui::CornerRadius::same(8))
}

fn anne_window_icon(size: u32) -> egui::IconData {
    let size = size.max(16);
    let mut rgba = Vec::with_capacity((size * size * 4) as usize);
    let radius = size as f32 * 0.18;

    for y in 0..size {
        for x in 0..size {
            let px = x as f32 + 0.5;
            let py = y as f32 + 0.5;
            let cx = px.clamp(radius, size as f32 - radius);
            let cy = py.clamp(radius, size as f32 - radius);
            let inside = (px - cx).powi(2) + (py - cy).powi(2) <= radius.powi(2);

            if !inside {
                rgba.extend_from_slice(&[0, 0, 0, 0]);
                continue;
            }

            let fx = px / size as f32;
            let fy = py / size as f32;
            // Gradient background: top #2563EB -> bottom #1D4ED8
            let t = fy;
            let bg_r = (37.0 + (29.0 - 37.0) * t) as u8;
            let bg_g = (99.0 + (78.0 - 99.0) * t) as u8;
            let bg_b = (235.0 + (216.0 - 235.0) * t) as u8;

            let s = size as f32;
            let stroke_w = (s * 0.045).max(1.5);
            let half_w = stroke_w / s;

            // Letter 'A' shape
            let apex_x = 0.50;
            let apex_y = 0.18;
            let base_y = 0.82;
            let base_left = 0.22;
            let base_right = 0.78;
            let bar_y = 0.58;

            // Left leg: apex -> bottom-left
            let leg_t = if fy >= apex_y && fy <= base_y {
                (fy - apex_y) / (base_y - apex_y)
            } else {
                -1.0
            };
            let left_leg = apex_x + (base_left - apex_x) * leg_t;
            let right_leg = apex_x + (base_right - apex_x) * leg_t;

            let on_left_leg = leg_t >= 0.0 && (fx - left_leg).abs() < half_w;
            let on_right_leg = leg_t >= 0.0 && (fx - right_leg).abs() < half_w;

            // Horizontal bar
            let bar_t = (bar_y - apex_y) / (base_y - apex_y);
            let bar_left = apex_x + (base_left - apex_x) * bar_t;
            let bar_right = apex_x + (base_right - apex_x) * bar_t;
            let on_bar = (fy - bar_y).abs() < half_w && fx >= bar_left && fx <= bar_right;

            if on_left_leg || on_right_leg || on_bar {
                rgba.extend_from_slice(&[255, 255, 255, 255]);
            } else {
                rgba.extend_from_slice(&[bg_r, bg_g, bg_b, 255]);
            }
        }
    }

    egui::IconData {
        rgba,
        width: size,
        height: size,
    }
}

fn draw_anne_logo(ui: &mut egui::Ui, size: f32) {
    let (rect, _response) = ui.allocate_exact_size(egui::vec2(size, size), egui::Sense::hover());
    let painter = ui.painter_at(rect);
    painter.rect_filled(rect, egui::CornerRadius::same(8), accent_color());

    let point = |x: f32, y: f32| {
        egui::pos2(
            rect.left() + x * rect.width(),
            rect.top() + y * rect.height(),
        )
    };
    let stroke = egui::Stroke::new((size * 0.07).max(2.0), egui::Color32::WHITE);
    // Letter 'A': left leg, right leg, horizontal bar
    for (a, b) in [
        ((0.50, 0.18), (0.22, 0.82)), // left leg
        ((0.50, 0.18), (0.78, 0.82)), // right leg
        ((0.33, 0.58), (0.67, 0.58)), // bar
    ] {
        painter.line_segment([point(a.0, a.1), point(b.0, b.1)], stroke);
    }
}

fn apply_modern_theme(ctx: &egui::Context) {
    let mut style = (*ctx.style()).clone();

    style.spacing.item_spacing = egui::vec2(10.0, 8.0);
    style.spacing.button_padding = egui::vec2(12.0, 7.0);
    style.spacing.scroll = egui::style::ScrollStyle::solid();
    style.spacing.window_margin = egui::Margin::same(10);

    let mut visuals = egui::Visuals::light();

    visuals.panel_fill = app_bg();
    visuals.window_fill = surface_color();
    visuals.faint_bg_color = surface_alt_color();
    visuals.widgets.noninteractive.bg_fill = surface_color();
    visuals.widgets.noninteractive.bg_stroke = egui::Stroke::new(1.0, border_color());
    visuals.widgets.noninteractive.fg_stroke = egui::Stroke::new(1.0, text_primary_color());

    visuals.text_edit_bg_color = Some(surface_color());

    visuals.widgets.inactive.bg_fill = surface_alt_color();
    visuals.widgets.inactive.bg_stroke = egui::Stroke::new(1.25, input_border_color());
    visuals.widgets.inactive.fg_stroke = egui::Stroke::new(1.0, text_primary_color());
    visuals.widgets.inactive.corner_radius = egui::CornerRadius::same(8);

    visuals.widgets.hovered.bg_fill = egui::Color32::from_rgb(239, 246, 255);
    visuals.widgets.hovered.bg_stroke =
        egui::Stroke::new(1.5, egui::Color32::from_rgb(96, 165, 250));
    visuals.widgets.hovered.fg_stroke = egui::Stroke::new(1.0, accent_color());
    visuals.widgets.hovered.corner_radius = egui::CornerRadius::same(8);

    visuals.widgets.active.bg_fill = accent_color();
    visuals.widgets.active.bg_stroke = egui::Stroke::new(1.0, accent_color());
    visuals.widgets.active.fg_stroke =
        egui::Stroke::new(1.0, egui::Color32::from_rgb(255, 255, 255));
    visuals.widgets.active.corner_radius = egui::CornerRadius::same(8);

    visuals.selection.bg_fill = egui::Color32::from_rgb(191, 219, 254);
    visuals.selection.stroke = egui::Stroke::new(1.0, accent_color());

    visuals.extreme_bg_color = egui::Color32::from_rgb(241, 245, 249);
    visuals.hyperlink_color = accent_color();
    visuals.warn_fg_color = warning_color();
    visuals.error_fg_color = danger_color();

    style.visuals = visuals;
    ctx.set_style(style);
}

fn start_gui(cli: Cli, config_path: PathBuf) -> Result<(), String> {
    let language = initial_gui_language(&config_path);
    let title = language.text(TextKey::AppTitle).to_owned();
    let options = eframe::NativeOptions {
        viewport: egui::ViewportBuilder::default()
            .with_title(title.clone())
            .with_inner_size([1180.0, 760.0])
            .with_icon(Arc::new(anne_window_icon(128))),
        ..Default::default()
    };

    eframe::run_native(
        &title,
        options,
        Box::new(move |cc| {
            apply_modern_theme(&cc.egui_ctx);
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
            gui_sort: SortKey::Name,
            gui_sort_desc: false,
            updater_auto_check: initial_config.updater.auto_check,
            anne_stats_enabled: initial_config.gui.anne_stats,
            update_status: String::new(),
            update_url: None,
            server_status: language.text(TextKey::WaitingRefresh).to_owned(),
            config_status: String::new(),
            group_name: match language {
                GuiLanguage::ZhCn => "我的服务器".to_owned(),
                GuiLanguage::EnUs => "My servers".to_owned(),
            },
            server_address: String::new(),
            server_a2s_probe: false,
            sourcebans_name: match language {
                GuiLanguage::ZhCn => "网页订阅".to_owned(),
                GuiLanguage::EnUs => "Web subscription".to_owned(),
            },
            sourcebans_url: String::new(),
            sourcebans_text: String::new(),
            rcon_address: String::new(),
            rcon_password: String::new(),
            rcon_command_text: "status".to_owned(),
            rcon_output: String::new(),
            cvar_address: String::new(),
            cvar_password: String::new(),
            cvar_names: "hostname,sv_tags,mp_gamemode".to_owned(),
            cvar_output: String::new(),
            player_output: String::new(),
            selected_server_network: None,
            network_info_cache: HashMap::new(),
            network_info_status: String::new(),
            ui_search_query: String::new(),
            ui_group_filter: None,
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
            online_stats_cache: Arc::new(Mutex::new(OnlineStatsCache::default())),
            online_stats_refreshing: false,
            online_stats_last_attempt: None,
            api_base_url: initial_config.api.base_url,
            api_token: initial_config.api.token.unwrap_or_default(),
            api_user: None,
            api_status: String::new(),
            steam_login_in_progress: false,
            broadcast_message: String::new(),
            broadcast_output: String::new(),
            broadcast_sending: false,
            broadcast_history: Vec::new(),
            broadcast_history_status: String::new(),
            broadcast_history_querying: false,
            time_zone: normalize_time_zone_setting(&initial_config.gui.time_zone),
        };
        app.config_status = app.language.config_file_status(&app.config_path);
        app.refresh_config_lists();
        app.refresh_servers();
        app.refresh_subscriptions_background();
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
                    if let Some(index) = self.servers.iter().position(|r| r.address == address) {
                        if result.is_err() && self.servers[index].drop_on_timeout {
                            self.servers.remove(index);
                            if self.selected_server.as_deref() == Some(address.as_str()) {
                                self.selected_server = None;
                                self.selected_server_players.clear();
                                self.player_output =
                                    self.language.text(TextKey::NoServerSelected).to_owned();
                            }
                            self.server_status =
                                self.language.server_count_status(self.servers.len());
                            continue;
                        }

                        let row = &mut self.servers[index];
                        match result {
                            Ok(new_payload) => {
                                row.ping_ms = new_payload.ping_ms;
                                row.info = new_payload.info;
                                row.error = new_payload.error;
                                row.a2s_probe = new_payload.a2s_probe;
                            }
                            Err(err) => {
                                row.error = Some(err);
                            }
                        }
                        row.last_queried = Some(std::time::Instant::now());
                    }
                }
                GuiMessage::NetworkInfo(address, result) => {
                    let is_selected = self.selected_server.as_deref() == Some(address.as_str());
                    match result {
                        Ok(info) => {
                            self.network_info_cache.insert(address, info.clone());
                            if is_selected {
                                self.selected_server_network = Some(info);
                                self.network_info_status.clear();
                            }
                        }
                        Err(err) if is_selected => {
                            self.selected_server_network = None;
                            self.network_info_status = self.language.network_failed_status(&err);
                        }
                        Err(_) => {}
                    }
                }
                GuiMessage::SubscriptionRefresh(result) => {
                    match result {
                        Ok(()) => {
                            // Subscriptions updated in config, reload everything
                            self.refresh_servers();
                            self.refresh_config_lists();
                        }
                        Err(err) => {
                            eprintln!("warning: background subscription refresh failed: {err}");
                        }
                    }
                }
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
                        self.sourcebans_text.clear();
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
                GuiMessage::Players(address, result) => match result {
                    Ok((players, stats_ok)) => {
                        if self.selected_server.as_deref() != Some(address.as_str()) {
                            continue;
                        }
                        self.selected_server_players = players.clone();
                        self.player_output = format_player_payload(&players, self.language);
                        if !stats_ok && !players.is_empty() {
                            self.player_output.push_str(match self.language {
                                GuiLanguage::ZhCn => "\n[警告] 积分数据获取失败",
                                GuiLanguage::EnUs => "\n[Warning] Failed to fetch player stats",
                            });
                        }
                    }
                    Err(err) => {
                        if self.selected_server.as_deref() != Some(address.as_str()) {
                            continue;
                        }
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
                                    GuiLanguage::ZhCn => " | [警告] 积分数据获取失败",
                                    GuiLanguage::EnUs => " | [Warning] Stats fetch failed",
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
                GuiMessage::OnlineStatsRefresh(result) => {
                    self.online_stats_refreshing = false;
                    if result.is_ok() {
                        self.apply_cached_stats_to_selected_players();
                        self.apply_cached_stats_to_global_players();
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
                    let mut should_refresh_history = false;
                    self.broadcast_output = match result {
                        Ok(response) if response.ok => match self.language {
                            GuiLanguage::ZhCn => {
                                should_refresh_history = true;
                                let usage = if response.unlimited.unwrap_or(false) {
                                    "今日次数：不受限制".to_owned()
                                } else {
                                    format!(
                                        "今日次数：已用 {}/{}，剩余 {}",
                                        response.daily_used.unwrap_or_default(),
                                        response.daily_limit.unwrap_or_default(),
                                        response.daily_remaining.unwrap_or_default()
                                    )
                                };
                                format!(
                                    "发送完成，已写入全服消息队列 #{}：{}\n{}\n总积分：{}",
                                    response.id.unwrap_or_default(),
                                    response.message.unwrap_or_default(),
                                    usage,
                                    format_optional_number(response.points)
                                )
                            }
                            GuiLanguage::EnUs => {
                                should_refresh_history = true;
                                let usage = if response.unlimited.unwrap_or(false) {
                                    "Daily quota: unlimited".to_owned()
                                } else {
                                    format!(
                                        "Daily quota: used {}/{}, remaining {}",
                                        response.daily_used.unwrap_or_default(),
                                        response.daily_limit.unwrap_or_default(),
                                        response.daily_remaining.unwrap_or_default()
                                    )
                                };
                                format!(
                                    "Sent. Broadcast queued #{}: {}\n{}\nTotal points: {}",
                                    response.id.unwrap_or_default(),
                                    response.message.unwrap_or_default(),
                                    usage,
                                    format_optional_number(response.points)
                                )
                            }
                        },
                        Ok(response) => response
                            .error
                            .or(response.message)
                            .unwrap_or_else(|| "broadcast failed".to_owned()),
                        Err(err) => err,
                    };
                    if should_refresh_history {
                        self.refresh_broadcast_history();
                    }
                }
                GuiMessage::BroadcastHistory(result) => {
                    self.broadcast_history_querying = false;
                    match result {
                        Ok(result) => {
                            let anonymous = result.auth_type != "steam";
                            let cache_ttl = result.cache_ttl.as_secs();
                            self.broadcast_history = result.messages;
                            self.broadcast_history_status = match self.language {
                                GuiLanguage::ZhCn => format!(
                                    "最近一小时 {} 条消息 | {}读取缓存 {} 秒",
                                    self.broadcast_history.len(),
                                    if anonymous { "匿名" } else { "登录" },
                                    cache_ttl
                                ),
                                GuiLanguage::EnUs => format!(
                                    "{} messages in the last hour | {} cache {}s",
                                    self.broadcast_history.len(),
                                    if anonymous { "anonymous" } else { "logged-in" },
                                    cache_ttl
                                ),
                            };
                        }
                        Err(err) => {
                            self.broadcast_history.clear();
                            self.broadcast_history_status = match self.language {
                                GuiLanguage::ZhCn => format!("获取全服消息历史失败：{err}"),
                                GuiLanguage::EnUs => {
                                    format!("Failed to fetch broadcast history: {err}")
                                }
                            };
                        }
                    }
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

    /// Refresh subscription URLs in the background and update cached servers in config.
    /// After completion, triggers a full server refresh with the new data.
    fn refresh_subscriptions_background(&mut self) {
        let tx = self.tx.clone();
        let config_path = self.config_path.clone();
        thread::spawn(move || {
            let result = refresh_all_subscriptions_in_config(&config_path);
            let _ = tx.send(GuiMessage::SubscriptionRefresh(result));
        });
    }

    fn maybe_refresh_online_stats_cache(&mut self) {
        if self.online_stats_refreshing || !self.anne_stats_enabled {
            return;
        }

        let now = Instant::now();
        if self
            .online_stats_last_attempt
            .is_some_and(|attempt| now.duration_since(attempt) < ONLINE_STATS_CACHE_TTL)
        {
            return;
        }

        if !online_stats_cache_needs_refresh(
            &self.api_base_url,
            &self.api_token,
            &self.online_stats_cache,
        ) {
            return;
        }

        self.online_stats_refreshing = true;
        self.online_stats_last_attempt = Some(now);
        let tx = self.tx.clone();
        let api_base_url = self.api_base_url.clone();
        let api_token = self.api_token.clone();
        let cache = Arc::clone(&self.online_stats_cache);
        thread::spawn(move || {
            let result =
                refresh_online_player_stats_cache(&api_base_url, &api_token, &cache, false);
            let _ = tx.send(GuiMessage::OnlineStatsRefresh(result));
        });
    }

    fn selected_server_name(&self) -> Option<&str> {
        let selected = self.selected_server.as_deref()?;
        self.servers
            .iter()
            .find(|row| row.address == selected)
            .and_then(|row| row.info.as_ref())
            .map(|info| info.name.as_str())
    }

    fn selected_server_is_anne(&self) -> bool {
        self.selected_server_name()
            .map(is_anne_server_name)
            .unwrap_or(false)
    }

    fn apply_cached_stats_to_selected_players(&mut self) {
        if self.selected_server_players.is_empty() || !self.selected_server_is_anne() {
            return;
        }

        let mut players = self.selected_server_players.clone();
        if apply_cached_player_stats(
            &self.api_base_url,
            &self.api_token,
            &self.online_stats_cache,
            &mut players,
        ) {
            self.selected_server_players = players;
            self.player_output =
                format_player_payload(&self.selected_server_players, self.language);
        }
    }

    fn apply_cached_stats_to_global_players(&mut self) {
        if self.global_players.is_empty() {
            return;
        }

        let mut players = self.global_players.clone();
        if apply_cached_global_anne_player_stats(
            &self.api_base_url,
            &self.api_token,
            &self.online_stats_cache,
            &mut players,
        ) {
            self.global_players = players;
        }
    }

    fn refresh_global_players(&mut self) {
        if self.global_players_querying {
            return;
        }
        self.maybe_refresh_online_stats_cache();
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
        let api_token = self.api_token.clone();
        let online_stats_cache = Arc::clone(&self.online_stats_cache);

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
                                        steam_id: None,
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
            let _ = apply_cached_global_anne_player_stats(
                &api_base_url,
                &api_token,
                &online_stats_cache,
                &mut final_results,
            );
            final_results.sort_by(|a, b| {
                b.duration
                    .partial_cmp(&a.duration)
                    .unwrap_or(std::cmp::Ordering::Equal)
            });
            let _ = tx.send(GuiMessage::GlobalPlayers(Ok((final_results, true))));
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

    fn show_broadcast_composer_card(&mut self, ui: &mut egui::Ui) {
        modern_card(ui, |ui| {
            ui.horizontal_wrapped(|ui| {
                ui.heading(self.text(TextKey::BroadcastTab));
                ui.label(
                    egui::RichText::new(match self.language {
                        GuiLanguage::ZhCn => "Steam 登录后发送普通全服聊天消息",
                        GuiLanguage::EnUs => "Send global chat after Steam login",
                    })
                    .color(text_muted_color()),
                );
            });
            ui.separator();
            ui.label(self.text(TextKey::ApiBaseUrl));
            let response = ui.add(
                egui::TextEdit::singleline(&mut self.api_base_url).desired_width(f32::INFINITY),
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

            ui.horizontal_wrapped(|ui| {
                if ui
                    .add_enabled(
                        !self.steam_login_in_progress,
                        primary_button(self.text(TextKey::SteamLogin)),
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
            ui.horizontal(|ui| {
                ui.label(self.text(TextKey::TimeZone));
                let response = ui.add(
                    egui::TextEdit::singleline(&mut self.time_zone)
                        .desired_width(220.0)
                        .hint_text(match self.language {
                            GuiLanguage::ZhCn => "system 或 Asia/Shanghai",
                            GuiLanguage::EnUs => "system or Asia/Shanghai",
                        }),
                );
                if response.lost_focus() && response.changed() {
                    let normalized = normalize_time_zone_setting(&self.time_zone);
                    if normalized != self.time_zone {
                        self.time_zone = normalized;
                    }
                    if let Err(err) = save_time_zone_to_config(&self.config_path, &self.time_zone) {
                        self.broadcast_history_status = match self.language {
                            GuiLanguage::ZhCn => format!("保存时区失败：{err}"),
                            GuiLanguage::EnUs => format!("Failed to save time zone: {err}"),
                        };
                    }
                }
            });
            ui.label(
                egui::RichText::new(match self.language {
                    GuiLanguage::ZhCn => "历史消息时间会按此时区显示；system 表示跟随本机时区。",
                    GuiLanguage::EnUs => {
                        "History timestamps use this time zone; system follows this computer."
                    }
                })
                .color(text_muted_color()),
            );
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
                    primary_button(if self.broadcast_sending {
                        match self.language {
                            GuiLanguage::ZhCn => "后台发送中...",
                            GuiLanguage::EnUs => "Sending...",
                        }
                    } else {
                        self.text(TextKey::SendBroadcast)
                    }),
                )
                .clicked()
            {
                self.send_broadcast();
            }

            if !self.broadcast_output.is_empty() {
                ui.separator();
                ui.add(
                    egui::TextEdit::multiline(&mut self.broadcast_output)
                        .desired_rows(6)
                        .desired_width(f32::INFINITY)
                        .code_editor(),
                );
            }
        });
    }

    fn show_broadcast_history_card(&mut self, ui: &mut egui::Ui) {
        modern_card(ui, |ui| {
            ui.horizontal_wrapped(|ui| {
                ui.heading(self.text(TextKey::BroadcastHistory));
                if ui
                    .add_enabled(
                        !self.broadcast_history_querying,
                        egui::Button::new(self.text(TextKey::RefreshHistory)),
                    )
                    .clicked()
                {
                    self.refresh_broadcast_history();
                }
            });
            ui.label(egui::RichText::new(&self.broadcast_history_status).color(text_muted_color()));
            ui.separator();

            if self.broadcast_history.is_empty() {
                ui.label(
                    egui::RichText::new(match self.language {
                        GuiLanguage::ZhCn => "暂无最近一小时全服消息。",
                        GuiLanguage::EnUs => "No messages in the last hour.",
                    })
                    .color(text_muted_color()),
                );
                return;
            }

            egui::ScrollArea::vertical()
                .max_height(360.0)
                .auto_shrink([false, false])
                .show(ui, |ui| {
                    for message in &self.broadcast_history {
                        egui::Frame::canvas(ui.style())
                            .fill(surface_alt_color())
                            .stroke(egui::Stroke::new(1.0, border_color()))
                            .corner_radius(egui::CornerRadius::same(8))
                            .inner_margin(egui::Margin::same(10))
                            .show(ui, |ui| {
                                ui.horizontal_wrapped(|ui| {
                                    ui.label(
                                        egui::RichText::new(&message.name)
                                            .strong()
                                            .color(text_primary_color()),
                                    );
                                    ui.label(
                                        egui::RichText::new(format_broadcast_time(
                                            &message.created_at,
                                            &self.time_zone,
                                        ))
                                        .color(text_muted_color()),
                                    );
                                });
                                ui.label(
                                    egui::RichText::new(format!(
                                        "#{} / {} / {}{}",
                                        message.id,
                                        message.steamid,
                                        message.server,
                                        if message.port > 0 {
                                            format!(":{}", message.port)
                                        } else {
                                            String::new()
                                        }
                                    ))
                                    .size(11.0)
                                    .color(text_muted_color()),
                                );
                                ui.add_space(4.0);
                                ui.label(&message.message);
                            });
                        ui.add_space(8.0);
                    }
                });
        });
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

        let message = self.broadcast_message.trim().to_owned();
        if message.is_empty() {
            self.broadcast_output = match self.language {
                GuiLanguage::ZhCn => "全服消息内容不能为空。".to_owned(),
                GuiLanguage::EnUs => "Broadcast message cannot be empty.".to_owned(),
            };
            return;
        }

        self.broadcast_sending = true;
        self.broadcast_output = self.language.text(TextKey::RunningCommand).to_owned();
        self.broadcast_message.clear();
        let tx = self.tx.clone();
        let request = BroadcastRequest {
            base_url: self.api_base_url.clone(),
            token: self.api_token.clone(),
            message,
        };
        thread::spawn(move || {
            let result = api_broadcast(request);
            let _ = tx.send(GuiMessage::Broadcast(result));
        });
    }

    fn refresh_broadcast_history(&mut self) {
        if self.broadcast_history_querying {
            return;
        }

        self.broadcast_history_querying = true;
        self.broadcast_history_status = match self.language {
            GuiLanguage::ZhCn => "正在获取最近一小时全服消息...".to_owned(),
            GuiLanguage::EnUs => "Fetching messages from the last hour...".to_owned(),
        };

        let tx = self.tx.clone();
        let request = BroadcastHistoryRequest {
            base_url: self.api_base_url.clone(),
            token: self.api_token.clone(),
            time_zone: self.time_zone.clone(),
        };
        thread::spawn(move || {
            let result = api_broadcast_history(request);
            let _ = tx.send(GuiMessage::BroadcastHistory(result));
        });
    }

    fn save_server(&mut self) {
        self.config_status = self.language.text(TextKey::SavingServer).to_owned();
        let tx = self.tx.clone();
        let path = self.config_path.clone();
        let input = AddServerRequest {
            group: self.group_name.clone(),
            server: self.server_address.clone(),
            a2s_probe: self.server_a2s_probe,
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
            text: self.sourcebans_text.clone(),
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
            text: self.sourcebans_text.clone(),
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

    fn show_sourcebans_list_card(&mut self, ui: &mut egui::Ui) {
        modern_card(ui, |ui| {
            ui.horizontal_wrapped(|ui| {
                ui.heading(self.text(TextKey::SubscriptionList));
                if ui.button(self.text(TextKey::NewSubscription)).clicked() {
                    self.selected_sourcebans = None;
                    self.sourcebans_name = match self.language {
                        GuiLanguage::ZhCn => "网页订阅".to_owned(),
                        GuiLanguage::EnUs => "Web subscription".to_owned(),
                    };
                    self.sourcebans_url.clear();
                    self.sourcebans_text.clear();
                }
                if ui
                    .add_enabled(
                        !self.sourcebans_entries.is_empty(),
                        egui::Button::new(self.text(TextKey::RefreshSubscriptions)),
                    )
                    .clicked()
                {
                    self.refresh_servers();
                }
                if ui
                    .add_enabled(
                        self.selected_sourcebans.is_some(),
                        egui::Button::new(self.text(TextKey::DeleteSubscription)),
                    )
                    .clicked()
                {
                    self.delete_sourcebans();
                }
            });
            ui.separator();

            if self.sourcebans_entries.is_empty() {
                ui.label(
                    egui::RichText::new(match self.language {
                        GuiLanguage::ZhCn => "还没有保存网页订阅。",
                        GuiLanguage::EnUs => "No web page subscriptions saved.",
                    })
                    .color(text_muted_color()),
                );
                return;
            }

            let mut clicked_subscription = None;
            egui::ScrollArea::vertical()
                .max_height(260.0)
                .auto_shrink([false, false])
                .show(ui, |ui| {
                    for (index, subscription) in self.sourcebans_entries.iter().enumerate() {
                        let selected = self.selected_sourcebans == Some(index);
                        let label = egui::RichText::new(&subscription.name).strong();
                        let source_label = subscription_source_label(subscription, self.language);
                        if ui
                            .selectable_label(selected, label)
                            .on_hover_text(&source_label)
                            .clicked()
                        {
                            clicked_subscription = Some(index);
                        }
                        ui.label(
                            egui::RichText::new(source_label)
                                .size(11.0)
                                .color(text_muted_color()),
                        );
                        ui.add_space(6.0);
                    }
                });

            if let Some(index) = clicked_subscription {
                self.selected_sourcebans = Some(index);
                if let Some(subscription) = self.sourcebans_entries.get(index) {
                    self.sourcebans_name = subscription.name.clone();
                    self.sourcebans_url = subscription.url.clone();
                    self.sourcebans_text = subscription.text.clone();
                }
            }
        });
    }

    fn show_sourcebans_editor_card(&mut self, ui: &mut egui::Ui) {
        modern_card(ui, |ui| {
            ui.heading(self.text(TextKey::SourceBansSubscription));
            ui.label(
                egui::RichText::new(match self.language {
                    GuiLanguage::ZhCn => "填 URL 会抓取公开页面；粘贴 HTML / 文本时会直接从文本里提取 IP:端口、域名:端口或 steam://connect 地址。保存后只保留解析出的服务器地址，不会存储原始文本。",
                    GuiLanguage::EnUs => {
                        "Use a URL for public pages, or paste HTML/text to extract IP:port, host:port, or steam://connect addresses. Only extracted addresses are saved, raw text is discarded."
                    }
                })
                .color(text_muted_color()),
            );
            ui.add_space(8.0);

            ui.label(self.text(TextKey::SubscriptionName));
            ui.add(
                egui::TextEdit::singleline(&mut self.sourcebans_name).desired_width(f32::INFINITY),
            );
            ui.label(self.text(TextKey::PageUrl));
            ui.add(
                egui::TextEdit::singleline(&mut self.sourcebans_url).desired_width(f32::INFINITY),
            );

            ui.add_space(4.0);
            ui.label(self.text(TextKey::PastedSubscriptionText));

            // Truncate display for very long pasted text to avoid UI freeze
            let text_len = self.sourcebans_text.len();
            const MAX_DISPLAY_LEN: usize = 50_000;
            if text_len > MAX_DISPLAY_LEN {
                let truncated_chars = self.sourcebans_text.chars().count();
                ui.label(
                    egui::RichText::new(match self.language {
                        GuiLanguage::ZhCn => format!("⚠ 文本过长（{truncated_chars} 字符），仅显示前 {MAX_DISPLAY_LEN} 字节。保存后将自动解析并清空原始文本。"),
                        GuiLanguage::EnUs => format!("⚠ Text too long ({truncated_chars} chars), showing first {MAX_DISPLAY_LEN} bytes. Raw text will be parsed and discarded on save."),
                    })
                    .color(egui::Color32::from_rgb(255, 180, 80)),
                );
                let preview: String = self.sourcebans_text.chars().take(5000).collect();
                let mut preview_display = preview;
                egui::ScrollArea::vertical()
                    .id_salt("sourcebans_text_scroll")
                    .max_height(200.0)
                    .auto_shrink([false, false])
                    .show(ui, |ui| {
                        ui.add(
                            egui::TextEdit::multiline(&mut preview_display)
                                .desired_rows(6)
                                .desired_width(f32::INFINITY)
                                .code_editor()
                                .interactive(false),
                        );
                    });
            } else {
                egui::ScrollArea::vertical()
                    .id_salt("sourcebans_text_scroll")
                    .max_height(200.0)
                    .auto_shrink([false, false])
                    .show(ui, |ui| {
                        ui.add(
                            egui::TextEdit::multiline(&mut self.sourcebans_text)
                                .desired_rows(6)
                                .desired_width(f32::INFINITY)
                                .code_editor(),
                        );
                    });
            }

            ui.add_space(8.0);
            let save_label = if self.selected_sourcebans.is_some() {
                self.text(TextKey::UpdateSubscription)
            } else {
                self.text(TextKey::SaveSubscription)
            };
            ui.horizontal_wrapped(|ui| {
                if ui.add(primary_button(save_label)).clicked() {
                    self.update_sourcebans();
                }
                let chars = self.sourcebans_text.chars().count();
                if chars > 0 {
                    ui.label(
                        egui::RichText::new(match self.language {
                            GuiLanguage::ZhCn => format!("已粘贴 {chars} 个字符"),
                            GuiLanguage::EnUs => format!("{chars} pasted chars"),
                        })
                        .color(text_muted_color()),
                    );
                }
            });
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
        self.cvar_address = address.clone();

        if changed {
            self.read_network_info(address, false);
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
        let api_token = self.api_token.clone();
        let online_stats_cache = Arc::clone(&self.online_stats_cache);
        let should_apply_cached_stats = self.selected_server_is_anne();
        if should_apply_cached_stats {
            self.maybe_refresh_online_stats_cache();
        }
        thread::spawn(move || {
            let result = resolve_endpoint(&address).and_then(|endpoint| {
                let mut players =
                    query_server_players(endpoint.socket, Duration::from_millis(4500))?;
                if should_apply_cached_stats {
                    let _ = apply_cached_player_stats(
                        &api_base_url,
                        &api_token,
                        &online_stats_cache,
                        &mut players,
                    );
                }
                Ok((players, true))
            });

            let _ = tx.send(GuiMessage::Players(address, result));
        });
    }

    fn read_network_info(&mut self, address: String, force: bool) {
        if !force {
            if let Some(info) = self.network_info_cache.get(&address).cloned() {
                self.selected_server_network = Some(info);
                self.network_info_status.clear();
                return;
            }
        }

        self.selected_server_network = None;
        self.network_info_status = self.language.network_resolving_status();

        let tx = self.tx.clone();
        thread::spawn(move || {
            let result = resolve_endpoint(&address).and_then(|endpoint| {
                fetch_server_network_info(&address, &endpoint.socket.ip().to_string())
            });
            let _ = tx.send(GuiMessage::NetworkInfo(address, result));
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
                SortKey::Name => cmp_natural_ci(&server_payload_name(a), &server_payload_name(b)),
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

    fn save_anne_stats_config(&mut self) {
        if let Err(err) = save_anne_stats_to_config(&self.config_path, self.anne_stats_enabled) {
            eprintln!("warning: failed to save anne stats config: {err}");
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
                servers_to_query.push((row.address.clone(), row.a2s_probe));
            }
        }

        for (address, a2s_probe) in servers_to_query {
            let tx = self.tx.clone();
            thread::spawn(move || {
                if let Ok(endpoint) = resolve_endpoint(&address) {
                    let result = match query_server_info(
                        endpoint.socket,
                        Duration::from_millis(2500),
                        a2s_probe,
                    ) {
                        Ok((info, ping)) => Ok(ServerRowPayload {
                            address: address.clone(),
                            socket: endpoint.socket.to_string(),
                            groups: Vec::new(),
                            ping_ms: Some(ping.as_millis() as u64),
                            info: Some(info),
                            error: None,
                            drop_on_timeout: false,
                            last_queried: Some(std::time::Instant::now()),
                            a2s_probe: a2s_probe,
                        }),
                        Err(err) => Err(err),
                    };
                    let _ = tx.send(GuiMessage::ServerUpdate(address, result));
                }
            });
        }

        self.maybe_refresh_online_stats_cache();

        ctx.request_repaint_after(Duration::from_secs(1));

        // 1. 顶部面板 Top Bar
        egui::TopBottomPanel::top("top_bar")
            .frame(egui::Frame {
                fill: surface_color(),
                inner_margin: egui::Margin::symmetric(16, 10),
                stroke: egui::Stroke::new(1.0, border_color()),
                ..Default::default()
            })
            .show(ctx, |ui| {
                ui.horizontal(|ui| {
                    let page_title = match self.current_nav {
                        NavTab::Servers => self.text(TextKey::ServerList),
                        NavTab::GlobalPlayers => self.text(TextKey::GlobalPlayersTab),
                        NavTab::Broadcast => self.text(TextKey::BroadcastTab),
                        NavTab::AddServer => self.text(TextKey::AddServer),
                        NavTab::SourceBans => self.text(TextKey::SourceBansSubscription),
                        NavTab::Settings => self.text(TextKey::SettingsTab),
                    };
                    ui.heading(
                        egui::RichText::new(page_title)
                            .size(22.0)
                            .strong()
                            .color(text_primary_color()),
                    );
                    ui.add_space(10.0);

                    if ui
                        .add(primary_button(self.text(TextKey::RefreshServers)))
                        .clicked()
                    {
                        self.refresh_servers();
                    }

                    ui.separator();

                    ui.label(
                        egui::RichText::new(self.text(TextKey::Language)).color(text_muted_color()),
                    );
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
                    ui.label(
                        egui::RichText::new(format!(
                            "{} {}",
                            self.text(TextKey::CurrentVersion),
                            env!("CARGO_PKG_VERSION")
                        ))
                        .color(text_muted_color()),
                    );
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
                ui.add_space(4.0);
                ui.horizontal(|ui| {
                    ui.label(
                        egui::RichText::new(&self.config_status)
                            .size(12.0)
                            .color(text_muted_color()),
                    );
                    if !self.update_status.is_empty() {
                        ui.separator();
                        ui.label(
                            egui::RichText::new(&self.update_status)
                                .size(12.0)
                                .color(warning_color()),
                        );
                    }
                });
            });

        // 2. 左侧导航面板 Sidebar Pane
        egui::SidePanel::left("navigation_panel")
            .resizable(false)
            .default_width(238.0)
            .frame(egui::Frame {
                fill: sidebar_bg_color(),
                inner_margin: egui::Margin::symmetric(14, 16),
                stroke: egui::Stroke::NONE,
                ..Default::default()
            })
            .show(ctx, |ui| {
                ui.vertical(|ui| {
                    ui.spacing_mut().item_spacing = egui::vec2(0.0, 10.0);

                    ui.horizontal(|ui| {
                        draw_anne_logo(ui, 36.0);
                        ui.vertical(|ui| {
                            ui.label(
                                egui::RichText::new(self.text(TextKey::AppTitle))
                                    .size(17.0)
                                    .strong()
                                    .color(egui::Color32::WHITE),
                            );
                            ui.label(
                                egui::RichText::new("Left 4 Dead 2")
                                    .size(11.0)
                                    .color(egui::Color32::from_rgb(148, 163, 184)),
                            );
                        });
                    });
                    ui.add_space(12.0);

                    let servers_label = match self.language {
                        GuiLanguage::ZhCn => "服务器浏览器",
                        GuiLanguage::EnUs => "Server Browser",
                    };
                    if nav_button(ui, self.current_nav == NavTab::Servers, servers_label).clicked()
                    {
                        self.current_nav = NavTab::Servers;
                    }

                    let players_label = match self.language {
                        GuiLanguage::ZhCn => "全服在线玩家",
                        GuiLanguage::EnUs => "All Server Players",
                    };
                    if nav_button(ui, self.current_nav == NavTab::GlobalPlayers, players_label)
                        .clicked()
                    {
                        self.current_nav = NavTab::GlobalPlayers;
                        self.refresh_global_players();
                    }

                    let broadcast_label = match self.language {
                        GuiLanguage::ZhCn => "全服消息",
                        GuiLanguage::EnUs => "Broadcast",
                    };
                    if nav_button(ui, self.current_nav == NavTab::Broadcast, broadcast_label)
                        .clicked()
                    {
                        self.current_nav = NavTab::Broadcast;
                        self.refresh_broadcast_history();
                    }

                    let add_server_label = match self.language {
                        GuiLanguage::ZhCn => "+ 添加服务器",
                        GuiLanguage::EnUs => "+ Add Server",
                    };
                    if nav_button(ui, self.current_nav == NavTab::AddServer, add_server_label)
                        .clicked()
                    {
                        self.current_nav = NavTab::AddServer;
                        self.config_status = self.language.config_file_status(&self.config_path);
                    }

                    let sourcebans_label = match self.language {
                        GuiLanguage::ZhCn => "网页订阅",
                        GuiLanguage::EnUs => "Web Sub",
                    };
                    if nav_button(ui, self.current_nav == NavTab::SourceBans, sourcebans_label)
                        .clicked()
                    {
                        self.current_nav = NavTab::SourceBans;
                        self.config_status = self.language.config_file_status(&self.config_path);
                    }

                    let settings_label = match self.language {
                        GuiLanguage::ZhCn => "首选项设置",
                        GuiLanguage::EnUs => "Preferences",
                    };
                    if nav_button(ui, self.current_nav == NavTab::Settings, settings_label)
                        .clicked()
                    {
                        self.current_nav = NavTab::Settings;
                    }

                    let sponsor_label = match self.language {
                        GuiLanguage::ZhCn => "赞助支持",
                        GuiLanguage::EnUs => "Sponsor Anne",
                    };
                    ui.add_space(8.0);
                    ui.separator();
                    ui.add_space(4.0);
                    if ui
                        .add_sized(
                            [ui.available_width(), 34.0],
                            egui::Button::new(
                                egui::RichText::new(sponsor_label)
                                    .strong()
                                    .color(egui::Color32::WHITE),
                            )
                            .fill(egui::Color32::from_rgb(37, 99, 235))
                            .stroke(egui::Stroke::new(
                                1.0,
                                egui::Color32::from_rgb(96, 165, 250),
                            ))
                            .corner_radius(egui::CornerRadius::same(8)),
                        )
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
                .width_range(300.0..=1200.0)
                .frame(egui::Frame {
                    fill: app_bg(),
                    inner_margin: egui::Margin::same(12),
                    stroke: egui::Stroke::new(1.0, border_color()),
                    ..Default::default()
                })
                .show(ctx, |ui| {
                    ui.vertical(|ui| {
                        ui.spacing_mut().item_spacing = egui::vec2(0.0, 10.0);

                        let mut refresh_network_info = false;
                        egui::Frame::canvas(ui.style())
                            .fill(surface_color())
                            .stroke(egui::Stroke::new(1.0, border_color()))
                            .corner_radius(egui::CornerRadius::same(8))
                            .inner_margin(egui::Margin::same(14))
                            .show(ui, |ui| {
                                ui.vertical(|ui| {
                                    ui.label(
                                        egui::RichText::new(self.text(TextKey::SelectedServer))
                                            .size(12.0)
                                            .color(text_muted_color()),
                                    );
                                    ui.heading(
                                        egui::RichText::new(&address).monospace().size(18.0),
                                    );

                                    if ui
                                        .button(
                                            egui::RichText::new(self.text(TextKey::ConnectGame))
                                                .strong(),
                                        )
                                        .clicked()
                                    {
                                        launch_steam_connect(&address);
                                    }

                                    ui.add_space(8.0);
                                    ui.separator();
                                    ui.add_space(4.0);

                                    ui.horizontal(|ui| {
                                        ui.label(
                                            egui::RichText::new(self.text(TextKey::NetworkInfo))
                                                .strong()
                                                .color(text_primary_color()),
                                        );
                                        ui.with_layout(
                                            egui::Layout::right_to_left(egui::Align::Center),
                                            |ui| {
                                                if ui
                                                    .small_button(
                                                        self.text(TextKey::ResolveNetwork),
                                                    )
                                                    .clicked()
                                                {
                                                    refresh_network_info = true;
                                                }
                                            },
                                        );
                                    });

                                    if let Some(info) = self
                                        .selected_server_network
                                        .as_ref()
                                        .filter(|info| info.address.as_str() == address.as_str())
                                    {
                                        egui::Grid::new("selected_server_network_grid")
                                            .striped(true)
                                            .num_columns(2)
                                            .spacing(egui::vec2(12.0, 4.0))
                                            .show(ui, |ui| {
                                                ui.label(
                                                    egui::RichText::new(
                                                        self.text(TextKey::IpAddress),
                                                    )
                                                    .color(text_muted_color()),
                                                );
                                                ui.monospace(display_network_field(&info.ip));
                                                ui.end_row();

                                                ui.label(
                                                    egui::RichText::new(
                                                        self.text(TextKey::NetworkOperator),
                                                    )
                                                    .color(text_muted_color()),
                                                );
                                                ui.label(display_network_field(&info.isp));
                                                ui.end_row();

                                                ui.label(
                                                    egui::RichText::new(
                                                        self.text(TextKey::Organization),
                                                    )
                                                    .color(text_muted_color()),
                                                );
                                                ui.label(display_network_field(&info.org));
                                                ui.end_row();

                                                ui.label(
                                                    egui::RichText::new(self.text(TextKey::Asn))
                                                        .color(text_muted_color()),
                                                );
                                                ui.monospace(display_network_field(&info.asn));
                                                ui.end_row();

                                                ui.label(
                                                    egui::RichText::new(self.text(TextKey::Region))
                                                        .color(text_muted_color()),
                                                );
                                                ui.label(format_network_location(info));
                                                ui.end_row();
                                            });
                                    } else if !self.network_info_status.is_empty() {
                                        ui.label(
                                            egui::RichText::new(&self.network_info_status)
                                                .color(text_muted_color()),
                                        );
                                    }
                                });
                            });
                        if refresh_network_info {
                            self.read_network_info(address.clone(), true);
                        }

                        egui::Frame::canvas(ui.style())
                            .fill(surface_color())
                            .stroke(egui::Stroke::new(1.0, border_color()))
                            .corner_radius(egui::CornerRadius::same(8))
                            .inner_margin(egui::Margin::same(14))
                            .show(ui, |ui| {
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
                                            if ui
                                                .button(self.text(TextKey::RefreshPlayers))
                                                .clicked()
                                            {
                                                self.read_players();
                                            }
                                        });

                                        if self.selected_server_players.is_empty() {
                                            ui.add(egui::Label::new(
                                                egui::RichText::new(&self.player_output)
                                                    .monospace(),
                                            ));
                                        } else {
                                            egui::ScrollArea::both().id_salt("inspector_players_scroll").show(ui, |ui| {
                                                for p in &self.selected_server_players {
                                                    egui::Frame::canvas(ui.style())
                                                        .fill(surface_color())
                                                        .stroke(egui::Stroke::new(
                                                            1.0,
                                                            border_color(),
                                                        ))
                                                        .corner_radius(egui::CornerRadius::same(8))
                                                        .inner_margin(egui::Margin::same(10))
                                                        .show(ui, |ui| {
                                                            ui.horizontal(|ui| {
                                                                ui.label(
                                                                    egui::RichText::new(&p.name)
                                                                        .strong()
                                                                        .color(text_primary_color()),
                                                                );
                                                                ui.label(
                                                                    egui::RichText::new(format!(
                                                                        "#{}",
                                                                        p.index
                                                                    ))
                                                                    .color(text_muted_color()),
                                                                );
                                                            });
                                                            ui.add_space(6.0);
                                                            ui.horizontal_wrapped(|ui| {
                                                                player_metric_chip(
                                                                    ui,
                                                                    match self.language {
                                                                        GuiLanguage::ZhCn => {
                                                                            "本局分数"
                                                                        }
                                                                        GuiLanguage::EnUs => {
                                                                            "Session score"
                                                                        }
                                                                    },
                                                                    format_optional_number(Some(
                                                                        p.score,
                                                                    )),
                                                                    accent_color(),
                                                                );
                                                                player_metric_chip(
                                                                    ui,
                                                                    match self.language {
                                                                        GuiLanguage::ZhCn => {
                                                                            "本局时间"
                                                                        }
                                                                        GuiLanguage::EnUs => {
                                                                            "Session time"
                                                                        }
                                                                    },
                                                                    format_duration_seconds(
                                                                        p.duration,
                                                                    ),
                                                                    text_primary_color(),
                                                                );
                                                                player_metric_chip(
                                                                    ui,
                                                                    match self.language {
                                                                        GuiLanguage::ZhCn => {
                                                                            "总积分"
                                                                        }
                                                                        GuiLanguage::EnUs => {
                                                                            "Total points"
                                                                        }
                                                                    },
                                                                    format_optional_number(
                                                                        p.points,
                                                                    ),
                                                                    success_color(),
                                                                );
                                                                player_metric_chip(
                                                                    ui,
                                                                    match self.language {
                                                                        GuiLanguage::ZhCn => {
                                                                            "总时长"
                                                                        }
                                                                        GuiLanguage::EnUs => {
                                                                            "Total time"
                                                                        }
                                                                    },
                                                                    format_playtime_minutes(
                                                                        p.playtime_mins,
                                                                        self.language,
                                                                    ),
                                                                    text_primary_color(),
                                                                );
                                                                player_metric_chip(
                                                                    ui,
                                                                    "PPM",
                                                                    p.ppm
                                                                        .map(|ppm| {
                                                                            format!("{ppm:.2}")
                                                                        })
                                                                        .unwrap_or_else(|| {
                                                                            "-".to_owned()
                                                                        }),
                                                                    warning_color(),
                                                                );
                                                                player_metric_chip(
                                                                    ui,
                                                                    match self.language {
                                                                        GuiLanguage::ZhCn => {
                                                                            "季度分"
                                                                        }
                                                                        GuiLanguage::EnUs => {
                                                                            "Quarter"
                                                                        }
                                                                    },
                                                                    format_optional_number(
                                                                        p.quarter_points,
                                                                    ),
                                                                    accent_color(),
                                                                );
                                                            });
                                                        });
                                                    ui.add_space(8.0);
                                                }
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
                                                .button(self.text(TextKey::RunCommand))
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
                                            if ui.button(self.text(TextKey::RefreshRules)).clicked()
                                            {
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
                                            ui.label(match self.language {
                                                GuiLanguage::ZhCn => "搜索",
                                                GuiLanguage::EnUs => "Search",
                                            });
                                            ui.add(
                                                egui::TextEdit::singleline(
                                                    &mut self.cvar_search_query,
                                                )
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
                                                                egui::RichText::new(v)
                                                                    .color(text_muted_color()),
                                                            ));
                                                            ui.label("");
                                                        } else {
                                                            ui.label(
                                                                egui::RichText::new(k).strong(),
                                                            );
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
                });
        }

        // 4. 中央面板 Central Panel
        egui::CentralPanel::default()
            .frame(egui::Frame {
                fill: app_bg(),
                inner_margin: egui::Margin::same(16),
                ..Default::default()
            })
            .show(ctx, |ui| match self.current_nav {
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
                        ui.spacing_mut().item_spacing = egui::vec2(12.0, 0.0);
                        stat_card(
                            ui,
                            self.text(TextKey::ActivePlayers),
                            format!("{active_players} / {total_slots}"),
                            accent_color(),
                        );
                        stat_card(
                            ui,
                            self.text(TextKey::TotalServers),
                            total_servers.to_string(),
                            text_primary_color(),
                        );
                        stat_card(
                            ui,
                            match self.language {
                                GuiLanguage::ZhCn => "低延迟 (≤50ms)",
                                GuiLanguage::EnUs => "Low Ping (≤50ms)",
                            },
                            low_ping_count.to_string(),
                            success_color(),
                        );
                    });

                    ui.add_space(8.0);

                    let mut clicked_server = None;
                    modern_card(ui, |ui| {
                        let search_placeholder = self.text(TextKey::SearchPlaceholder);
                        let filter_has_players_label = self.text(TextKey::FilterHasPlayers);
                        let filter_empty_label = self.text(TextKey::FilterEmpty);
                        let filter_hide_timeout_label = self.text(TextKey::FilterHideTimeout);
                        ui.horizontal(|ui| {
                            ui.label(match self.language {
                                GuiLanguage::ZhCn => "搜索",
                                GuiLanguage::EnUs => "Search",
                            });
                            ui.add(
                                egui::TextEdit::singleline(&mut self.ui_search_query)
                                    .hint_text(search_placeholder)
                                    .desired_width(280.0),
                            );

                            ui.separator();

                            if ui
                                .checkbox(&mut self.ui_filter_has_players, filter_has_players_label)
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
                            ui.checkbox(
                                &mut self.ui_filter_hide_timeout,
                                filter_hide_timeout_label,
                            );
                        });

                        let group_counts = server_group_counts(&self.servers);
                        let selected_group_missing = match self.ui_group_filter.as_deref() {
                            Some(group_filter) => {
                                !group_counts.iter().any(|(group, _)| group == group_filter)
                            }
                            None => false,
                        };
                        if selected_group_missing {
                            self.ui_group_filter = None;
                        }
                        ui.horizontal_wrapped(|ui| {
                            ui.label(match self.language {
                                GuiLanguage::ZhCn => "分组",
                                GuiLanguage::EnUs => "Group",
                            });
                            let all_servers_label = match self.language {
                                GuiLanguage::ZhCn => "全部服务器",
                                GuiLanguage::EnUs => "All servers",
                            };
                            if ui
                                .selectable_label(
                                    self.ui_group_filter.is_none(),
                                    format!("{all_servers_label} ({})", self.servers.len()),
                                )
                                .clicked()
                            {
                                self.ui_group_filter = None;
                            }
                            for (group, count) in &group_counts {
                                let selected =
                                    self.ui_group_filter.as_deref() == Some(group.as_str());
                                if ui
                                    .selectable_label(selected, format!("{group} ({count})"))
                                    .clicked()
                                {
                                    self.ui_group_filter = Some(group.clone());
                                }
                            }
                        });

                        ui.separator();

                        let mut filtered_servers = self.servers.clone();

                        if let Some(group_filter) = &self.ui_group_filter {
                            filtered_servers
                                .retain(|row| row.groups.iter().any(|group| group == group_filter));
                        }

                        if !self.ui_search_query.trim().is_empty() {
                            let query = self.ui_search_query.to_lowercase();
                            filtered_servers.retain(|row| {
                                let group_match =
                                    row.groups.iter().any(|g| g.to_lowercase().contains(&query));
                                let addr_match = row.address.to_lowercase().contains(&query);
                                let name_match = if let Some(info) = &row.info {
                                    info.name.to_lowercase().contains(&query)
                                        || info.map.to_lowercase().contains(&query)
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
                            ui.label(format!(
                                "({})",
                                self.language.server_count_status(filtered_servers.len())
                            ));
                        });

                        ui.add_space(4.0);

                        egui::ScrollArea::both()
                            .auto_shrink([false, false])
                            .show(ui, |ui| {
                                egui::Grid::new("servers_grid")
                                    .striped(true)
                                    .min_col_width(70.0)
                                    .show(ui, |ui| {
                                        if ui
                                            .button(sort_label(
                                                self.text(TextKey::HeaderNameOrError),
                                                self.gui_sort,
                                                self.gui_sort_desc,
                                                SortKey::Name,
                                            ))
                                            .clicked()
                                        {
                                            self.set_sort(SortKey::Name);
                                        }
                                        if ui
                                            .button(sort_label(
                                                self.text(TextKey::HeaderGroup),
                                                self.gui_sort,
                                                self.gui_sort_desc,
                                                SortKey::Group,
                                            ))
                                            .clicked()
                                        {
                                            self.set_sort(SortKey::Group);
                                        }
                                        if ui
                                            .button(sort_label(
                                                self.text(TextKey::HeaderPing),
                                                self.gui_sort,
                                                self.gui_sort_desc,
                                                SortKey::Ping,
                                            ))
                                            .clicked()
                                        {
                                            self.set_sort(SortKey::Ping);
                                        }
                                        if ui
                                            .button(sort_label(
                                                self.text(TextKey::HeaderPlayers),
                                                self.gui_sort,
                                                self.gui_sort_desc,
                                                SortKey::Players,
                                            ))
                                            .clicked()
                                        {
                                            self.set_sort(SortKey::Players);
                                        }
                                        if ui
                                            .button(sort_label(
                                                self.text(TextKey::HeaderMap),
                                                self.gui_sort,
                                                self.gui_sort_desc,
                                                SortKey::Map,
                                            ))
                                            .clicked()
                                        {
                                            self.set_sort(SortKey::Map);
                                        }
                                        ui.strong(self.text(TextKey::HeaderVac));
                                        if ui
                                            .button(sort_label(
                                                self.text(TextKey::HeaderAddress),
                                                self.gui_sort,
                                                self.gui_sort_desc,
                                                SortKey::Address,
                                            ))
                                            .clicked()
                                        {
                                            self.set_sort(SortKey::Address);
                                        }
                                        ui.end_row();

                                        for row in &filtered_servers {
                                            let selected = self.selected_server.as_deref()
                                                == Some(row.address.as_str());
                                            let (players_text, fraction) = if let Some(info) =
                                                &row.info
                                            {
                                                let fraction = if info.max_players == 0 {
                                                    0.0
                                                } else {
                                                    info.players as f32 / info.max_players as f32
                                                };
                                                (
                                                    format!(
                                                        "{}/{}",
                                                        info.players, info.max_players
                                                    ),
                                                    fraction,
                                                )
                                            } else {
                                                ("-".to_owned(), 0.0)
                                            };

                                            let map = row
                                                .info
                                                .as_ref()
                                                .map(|info| info.map.clone())
                                                .unwrap_or_else(|| "-".to_owned());

                                            let vac_text = if let Some(info) = &row.info {
                                                if info.vac {
                                                    match self.language {
                                                        GuiLanguage::ZhCn => "是",
                                                        GuiLanguage::EnUs => "Yes",
                                                    }
                                                } else {
                                                    match self.language {
                                                        GuiLanguage::ZhCn => "否",
                                                        GuiLanguage::EnUs => "No",
                                                    }
                                                }
                                            } else {
                                                "-"
                                            };
                                            let vac_color = if let Some(info) = &row.info {
                                                if info.vac {
                                                    success_color()
                                                } else {
                                                    text_muted_color()
                                                }
                                            } else {
                                                text_muted_color()
                                            };

                                            let name = if let Some(info) = &row.info {
                                                info.name.clone()
                                            } else {
                                                row.error.clone().unwrap_or_else(|| {
                                                    self.text(TextKey::NotQueried).to_owned()
                                                })
                                            };

                                            let ping_text = row
                                                .ping_ms
                                                .map(|v| format!("{v} ms"))
                                                .unwrap_or_else(|| "超时".to_owned());
                                            let ping_color = match row.ping_ms {
                                                None => danger_color(),
                                                Some(ping) => {
                                                    if ping < 50 {
                                                        success_color()
                                                    } else if ping < 120 {
                                                        warning_color()
                                                    } else {
                                                        egui::Color32::from_rgb(249, 115, 22)
                                                    }
                                                }
                                            };

                                            let mut row_clicked =
                                                ui.selectable_label(selected, &name).clicked();

                                            row_clicked |= ui
                                                .add(
                                                    egui::Label::new(egui::RichText::new(
                                                        row.groups.join(","),
                                                    ))
                                                    .sense(egui::Sense::click()),
                                                )
                                                .clicked();

                                            row_clicked |= ui
                                                .add(
                                                    egui::Label::new(
                                                        egui::RichText::new(ping_text)
                                                            .color(ping_color),
                                                    )
                                                    .sense(egui::Sense::click()),
                                                )
                                                .clicked();

                                            let player_color = if fraction >= 0.8 {
                                                egui::Color32::from_rgb(249, 115, 22)
                                            } else if fraction > 0.0 {
                                                success_color()
                                            } else {
                                                text_muted_color()
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

                                            row_clicked |= ui
                                                .add(
                                                    egui::Label::new(egui::RichText::new(map))
                                                        .sense(egui::Sense::click()),
                                                )
                                                .clicked();

                                            row_clicked |= ui
                                                .add(
                                                    egui::Label::new(
                                                        egui::RichText::new(vac_text)
                                                            .color(vac_color),
                                                    )
                                                    .sense(egui::Sense::click()),
                                                )
                                                .clicked();

                                            row_clicked |= ui
                                                .add(
                                                    egui::Label::new(
                                                        egui::RichText::new(&row.address)
                                                            .monospace(),
                                                    )
                                                    .sense(egui::Sense::click()),
                                                )
                                                .clicked();

                                            if row_clicked {
                                                clicked_server = Some(row.address.clone());
                                            }
                                            ui.end_row();
                                        }
                                    });
                            });
                    });

                    if let Some(address) = clicked_server {
                        self.select_server(address);
                    }
                }
                NavTab::GlobalPlayers => {
                    let global_player_search_placeholder =
                        self.text(TextKey::GlobalPlayerSearchPlaceholder);
                    egui::Frame::canvas(ui.style())
                        .fill(surface_color())
                        .stroke(egui::Stroke::new(1.0, border_color()))
                        .corner_radius(egui::CornerRadius::same(8))
                        .inner_margin(egui::Margin::same(16))
                        .show(ui, |ui| {
                            ui.horizontal(|ui| {
                                ui.heading(self.text(TextKey::GlobalPlayersTab));
                                ui.with_layout(
                                    egui::Layout::right_to_left(egui::Align::Center),
                                    |ui| {
                                        if ui
                                            .add_enabled(
                                                !self.global_players_querying,
                                                egui::Button::new(
                                                    self.text(TextKey::RefreshPlayers),
                                                ),
                                            )
                                            .clicked()
                                        {
                                            self.refresh_global_players();
                                        }
                                    },
                                );
                            });
                            ui.add_space(4.0);
                            ui.label(
                                egui::RichText::new(&self.global_players_status)
                                    .color(text_muted_color()),
                            );
                            ui.add_space(8.0);
                            ui.horizontal(|ui| {
                                ui.label(match self.language {
                                    GuiLanguage::ZhCn => "搜索",
                                    GuiLanguage::EnUs => "Search",
                                });
                                ui.add(
                                    egui::TextEdit::singleline(
                                        &mut self.global_player_search_query,
                                    )
                                    .hint_text(global_player_search_placeholder)
                                    .desired_width(360.0),
                                );
                            });
                        });

                    let mut filtered_players = self.global_players.clone();
                    if !self.global_player_search_query.trim().is_empty() {
                        let query = self.global_player_search_query.to_lowercase();
                        filtered_players.retain(|p| {
                            p.name.to_lowercase().contains(&query)
                                || p.server_name.to_lowercase().contains(&query)
                                || p.server_address.to_lowercase().contains(&query)
                        });
                    }

                    ui.add_space(12.0);

                    let active_servers_count = self
                        .global_players
                        .iter()
                        .map(|p| &p.server_address)
                        .collect::<HashSet<_>>()
                        .len();
                    let matched_stats_count = self
                        .global_players
                        .iter()
                        .filter(|p| p.points.is_some())
                        .count();

                    ui.horizontal(|ui| {
                        ui.spacing_mut().item_spacing = egui::vec2(12.0, 0.0);
                        for (label, value, color) in [
                            (
                                match self.language {
                                    GuiLanguage::ZhCn => "在线玩家",
                                    GuiLanguage::EnUs => "Online players",
                                },
                                self.global_players.len().to_string(),
                                accent_color(),
                            ),
                            (
                                match self.language {
                                    GuiLanguage::ZhCn => "有人的服务器",
                                    GuiLanguage::EnUs => "Active servers",
                                },
                                active_servers_count.to_string(),
                                success_color(),
                            ),
                            (
                                match self.language {
                                    GuiLanguage::ZhCn => "已匹配统计",
                                    GuiLanguage::EnUs => "Stats matched",
                                },
                                matched_stats_count.to_string(),
                                warning_color(),
                            ),
                        ] {
                            egui::Frame::canvas(ui.style())
                                .fill(surface_color())
                                .stroke(egui::Stroke::new(1.0, border_color()))
                                .corner_radius(egui::CornerRadius::same(8))
                                .inner_margin(egui::Margin::symmetric(14, 10))
                                .show(ui, |ui| {
                                    ui.set_min_width(150.0);
                                    ui.label(
                                        egui::RichText::new(label)
                                            .size(11.0)
                                            .color(text_muted_color()),
                                    );
                                    ui.heading(
                                        egui::RichText::new(value).size(18.0).strong().color(color),
                                    );
                                });
                        }
                    });

                    ui.add_space(12.0);

                    egui::Frame::canvas(ui.style())
                        .fill(surface_color())
                        .stroke(egui::Stroke::new(1.0, border_color()))
                        .corner_radius(egui::CornerRadius::same(8))
                        .inner_margin(egui::Margin::same(12))
                        .show(ui, |ui| {
                            ui.horizontal(|ui| {
                                ui.heading(match self.language {
                                    GuiLanguage::ZhCn => "玩家明细",
                                    GuiLanguage::EnUs => "Player details",
                                });
                                ui.label(format!("({})", filtered_players.len()));
                            });
                            ui.separator();
                            egui::ScrollArea::both()
                                .id_salt("global_players_table_scroll")
                                .auto_shrink([false, false])
                                .show(ui, |ui| {
                                    egui::Grid::new("global_players_table_grid")
                                        .striped(true)
                                        .min_col_width(65.0)
                                        .show(ui, |ui| {
                                            ui.strong(match self.language {
                                                GuiLanguage::ZhCn => "玩家昵称",
                                                GuiLanguage::EnUs => "Player Name",
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
                                            ui.strong(match self.language {
                                                GuiLanguage::ZhCn => "所在服务器",
                                                GuiLanguage::EnUs => "Server",
                                            });
                                            ui.end_row();

                                            for p in &filtered_players {
                                                ui.label(egui::RichText::new(&p.name).strong());
                                                ui.label(format_optional_number(Some(p.score)));
                                                ui.label(format_duration_seconds(p.duration));

                                                ui.label(format_optional_number(p.points));

                                                ui.label(format_playtime_minutes(
                                                    p.playtime_mins,
                                                    self.language,
                                                ));

                                                let ppm_str = match p.ppm {
                                                    Some(val) => format!("{val:.2}"),
                                                    None => "-".to_owned(),
                                                };
                                                ui.label(ppm_str);
                                                ui.label(format_optional_number(p.quarter_points));

                                                let btn = egui::Button::new(format!(
                                                    "{} {}",
                                                    self.text(TextKey::ConnectGame),
                                                    p.server_name
                                                ))
                                                .frame(false);
                                                if ui
                                                    .add(btn)
                                                    .on_hover_text(format!(
                                                        "双击或点击连入：{}",
                                                        p.server_address
                                                    ))
                                                    .clicked()
                                                {
                                                    launch_steam_connect(&p.server_address);
                                                }
                                                ui.end_row();
                                            }
                                        });
                                });
                        });
                }
                NavTab::Broadcast => {
                    if ui.available_width() < 900.0 {
                        self.show_broadcast_composer_card(ui);
                        ui.add_space(12.0);
                        self.show_broadcast_history_card(ui);
                    } else {
                        ui.columns(2, |columns| {
                            self.show_broadcast_composer_card(&mut columns[0]);
                            self.show_broadcast_history_card(&mut columns[1]);
                        });
                    }
                }
                NavTab::AddServer => {
                    modern_card(ui, |ui| {
                        ui.heading(self.text(TextKey::AddServer));
                        ui.horizontal(|ui| {
                            ui.label(self.text(TextKey::Group));
                            ui.add(
                                egui::TextEdit::singleline(&mut self.group_name)
                                    .desired_width(120.0),
                            );
                            ui.label(self.text(TextKey::ServerAddress));
                            ui.add(
                                egui::TextEdit::singleline(&mut self.server_address)
                                    .desired_width(200.0),
                            );
                            let a2s_probe_label = self.text(TextKey::A2sProbe).to_owned();
                            ui.checkbox(&mut self.server_a2s_probe, a2s_probe_label)
                                .on_hover_text(match self.language {
                                    GuiLanguage::ZhCn => {
                                        "勾选后，这台手动服务器会发送带探测标记的 A2S 包。"
                                    }
                                    GuiLanguage::EnUs => {
                                        "When enabled, this manual server sends the marked A2S probe packet."
                                    }
                                });
                            if ui
                                .add(primary_button(self.text(TextKey::SaveServer)))
                                .clicked()
                            {
                                self.save_server();
                            }
                        });
                    });

                    ui.add_space(12.0);
                    self.show_sourcebans_editor_card(ui);

                    ui.add_space(12.0);
                    modern_card(ui, |ui| {
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
                                            ui.label(if entry.a2s_probe {
                                                self.text(TextKey::A2sProbe)
                                            } else {
                                                "-"
                                            });
                                            if ui
                                                .button(match self.language {
                                                    GuiLanguage::ZhCn => "删除",
                                                    GuiLanguage::EnUs => "Delete",
                                                })
                                                .clicked()
                                            {
                                                delete_entry = Some((
                                                    entry.group.clone(),
                                                    entry.server.clone(),
                                                ));
                                            }
                                            ui.end_row();
                                        }
                                    });
                                if let Some((group, server)) = delete_entry {
                                    self.delete_server(group, server);
                                }
                            }
                        });
                    });
                }
                NavTab::SourceBans => {
                    self.show_sourcebans_list_card(ui);
                }
                NavTab::Settings => {
                    modern_card(ui, |ui| {
                        ui.heading(self.text(TextKey::SettingsTab));
                        ui.label(
                            egui::RichText::new(&self.config_status).color(text_muted_color()),
                        );

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
                            ui.label(self.text(TextKey::TimeZone));
                            let response = ui.add(
                                egui::TextEdit::singleline(&mut self.time_zone)
                                    .desired_width(220.0)
                                    .hint_text(match self.language {
                                        GuiLanguage::ZhCn => "system 或 Asia/Shanghai",
                                        GuiLanguage::EnUs => "system or Asia/Shanghai",
                                    }),
                            );
                            if response.lost_focus() && response.changed() {
                                let normalized = normalize_time_zone_setting(&self.time_zone);
                                if normalized != self.time_zone {
                                    self.time_zone = normalized;
                                }
                                if let Err(err) =
                                    save_time_zone_to_config(&self.config_path, &self.time_zone)
                                {
                                    self.config_status = match self.language {
                                        GuiLanguage::ZhCn => format!("保存时区失败：{err}"),
                                        GuiLanguage::EnUs => {
                                            format!("Failed to save time zone: {err}")
                                        }
                                    };
                                }
                            }
                        });

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
                        if ui
                            .checkbox(&mut self.updater_auto_check, auto_update_label)
                            .changed()
                        {
                            self.save_updater_config();
                        }

                        let anne_stats_label = match self.language {
                            GuiLanguage::ZhCn => "启用 Anne 服在线玩家数据",
                            GuiLanguage::EnUs => "Enable Anne server online player stats",
                        };
                        if ui
                            .checkbox(&mut self.anne_stats_enabled, anne_stats_label)
                            .changed()
                        {
                            self.save_anne_stats_config();
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
                    });
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

fn display_network_field(value: &str) -> &str {
    if value.trim().is_empty() {
        "-"
    } else {
        value
    }
}

fn format_network_location(info: &ServerNetworkInfo) -> String {
    let parts = [&info.country, &info.region, &info.city]
        .into_iter()
        .map(|part| part.trim())
        .filter(|part| !part.is_empty())
        .collect::<Vec<_>>();

    if parts.is_empty() {
        "-".to_owned()
    } else {
        parts.join(" / ")
    }
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
        let marker = if desc { "DESC" } else { "ASC" };
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
            group.servers.push(server.clone());
        }
        if input.a2s_probe {
            add_a2s_probe_server(group, &server);
        } else {
            remove_a2s_probe_server(group, &server);
        }
    } else {
        let mut a2s_probe_servers = Vec::new();
        if input.a2s_probe {
            a2s_probe_servers.push(server.clone());
        }
        config.groups.push(FileGroup {
            name: group_name,
            servers: vec![server],
            a2s_probe: false,
            a2s_probe_servers,
        });
    }

    save_config(path, &config)
}

fn add_a2s_probe_server(group: &mut FileGroup, server: &str) {
    if !group
        .a2s_probe_servers
        .iter()
        .any(|existing| existing == server)
    {
        group.a2s_probe_servers.push(server.to_owned());
    }
}

fn remove_a2s_probe_server(group: &mut FileGroup, server: &str) {
    group.a2s_probe_servers.retain(|existing| existing != server);
}

fn delete_server_from_config(path: &PathBuf, group: &str, server: &str) -> Result<(), String> {
    let mut config = load_config_or_default(path)?;
    let mut found = false;

    for g in config.groups.iter_mut() {
        if g.name == group {
            let before = g.servers.len();
            g.servers.retain(|s| s != server);
            g.a2s_probe_servers.retain(|s| s != server);
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
    let (url, servers) = resolve_subscription_servers(&input)?;
    let a2s_probe = is_default_anne_subscription_url(&url);
    let mut config = load_config_or_default(path)?;

    if let Some(subscription) = config
        .sourcebans
        .iter_mut()
        .find(|subscription| subscription.name == name)
    {
        subscription.url = url;
        subscription.text = String::new();
        subscription.servers = servers;
        subscription.a2s_probe = a2s_probe;
    } else {
        config.sourcebans.push(FileSourceBans {
            name,
            url,
            text: String::new(),
            servers,
            a2s_probe,
        });
    }

    save_config(path, &config)
}

fn update_sourcebans_in_config(
    path: &PathBuf,
    index: usize,
    input: AddSourceBansRequest,
) -> Result<(), String> {
    let name = non_empty(input.name.trim().to_owned(), "name")?;
    let (url, servers) = resolve_subscription_servers(&input)?;
    let a2s_probe = is_default_anne_subscription_url(&url);
    let mut config = load_config_or_default(path)?;
    let Some(subscription) = config.sourcebans.get_mut(index) else {
        return Err(format!("sourcebans index {index} does not exist"));
    };

    subscription.name = name;
    subscription.url = url;
    subscription.text = String::new();
    subscription.servers = servers;
    subscription.a2s_probe = a2s_probe;
    save_config(path, &config)
}

/// Parse text/URL at save time and return (url_to_keep, extracted_servers).
/// The raw text is NOT stored — only the extracted server addresses are kept.
fn resolve_subscription_servers(
    input: &AddSourceBansRequest,
) -> Result<(String, Vec<String>), String> {
    let url = input.url.trim();
    let text = input.text.trim();

    if url.is_empty() && text.is_empty() {
        return Err("subscription requires a page URL or pasted text".to_owned());
    }

    // If text is provided, parse it immediately to extract server addresses
    if !text.is_empty() {
        let servers = extract_pasted_subscription(text, &input.name)?;
        let url = if url.is_empty() {
            String::new()
        } else {
            normalize_subscription_url(url)?.to_string()
        };
        return Ok((url, servers));
    }

    // If only URL is provided, fetch and parse it now
    let normalized_url = normalize_subscription_url(url)?;
    let sub = SourceBansSubscription {
        name: input.name.clone(),
        url: normalized_url.to_string(),
        text: String::new(),
        servers: Vec::new(),
        a2s_probe: is_default_anne_subscription_url(normalized_url.as_str()),
    };
    let servers = fetch_web_subscription(&sub, Duration::from_secs(15))?;
    Ok((normalized_url.to_string(), servers))
}

fn delete_sourcebans_from_config(path: &PathBuf, index: usize) -> Result<(), String> {
    let mut config = load_config_or_default(path)?;
    if index >= config.sourcebans.len() {
        return Err(format!("sourcebans index {index} does not exist"));
    }

    config.sourcebans.remove(index);
    save_config(path, &config)
}

/// Re-fetch all URL-based subscriptions and update cached server addresses in config.
fn refresh_all_subscriptions_in_config(path: &PathBuf) -> Result<(), String> {
    let mut config = load_config_or_default(path)?;
    let mut any_updated = false;

    for sub_config in config.sourcebans.iter_mut() {
        let url = sub_config.url.trim();
        if url.is_empty() {
            continue;
        }

        let sub = SourceBansSubscription {
            name: sub_config.name.clone(),
            url: url.to_owned(),
            text: String::new(),
            servers: Vec::new(),
            a2s_probe: sub_config.a2s_probe,
        };

        match fetch_web_subscription(&sub, Duration::from_secs(15)) {
            Ok(servers) if !servers.is_empty() => {
                sub_config.servers = servers;
                sub_config.text = String::new();
                any_updated = true;
            }
            Ok(_) => {
                eprintln!(
                    "warning: subscription {} returned no servers, keeping cache",
                    sub_config.name
                );
            }
            Err(err) => {
                eprintln!(
                    "warning: failed to refresh subscription {}: {err}, keeping cache",
                    sub_config.name
                );
            }
        }
    }

    if any_updated {
        save_config(path, &config)?;
    }
    Ok(())
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

fn save_anne_stats_to_config(path: &PathBuf, enabled: bool) -> Result<(), String> {
    let mut config = load_config_or_default(path)?;
    config.gui.anne_stats = enabled;
    save_config(path, &config)
}

fn save_time_zone_to_config(path: &PathBuf, time_zone: &str) -> Result<(), String> {
    let mut config = load_config_or_default(path)?;
    config.gui.time_zone = normalize_time_zone_setting(time_zone);
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
            let probe_servers = group
                .a2s_probe_servers
                .iter()
                .map(|server| server.trim().to_owned())
                .filter(|server| !server.is_empty())
                .collect::<BTreeSet<_>>();
            group.servers.iter().map(move |server| ManualServerEntry {
                group: group.name.clone(),
                server: server.clone(),
                a2s_probe: group.a2s_probe
                    || probe_servers.contains(server.trim())
                    || normalize_endpoint_input(server)
                        .ok()
                        .and_then(|address| resolve_ipv4(&address).ok())
                        .map(|socket| probe_servers.contains(&socket.to_string()))
                        .unwrap_or(false),
            })
        })
        .collect();

    Ok(GuiConfigLists {
        manual_servers,
        sourcebans: config.sourcebans,
    })
}

#[derive(Deserialize)]
struct GitHubTag {
    name: String,
}

#[derive(Clone, Debug)]
struct ReleaseAsset {
    name: String,
    download_url: String,
}

fn check_latest_release() -> Result<UpdateInfo, String> {
    let client = Client::builder()
        .timeout(Duration::from_millis(10_000))
        .build()
        .map_err(|err| format!("failed to build update client: {err}"))?;
    let tag_name = match fetch_latest_update_tag_from_atom(&client, "releases.atom", "release feed")
    {
        Ok(tag) => tag,
        Err(release_feed_err) => {
            match fetch_latest_update_tag_from_atom(&client, "tags.atom", "tag feed") {
                Ok(tag) => tag,
                Err(tag_feed_err) => fetch_latest_update_tag(&client).map_err(|api_err| {
                    format!(
                        "failed to check latest release: {release_feed_err}; tag feed failed: {tag_feed_err}; API fallback failed: {api_err}"
                    )
                })?,
            }
        }
    };
    let html_url = format!("https://github.com/{UPDATE_REPO}/releases/tag/{tag_name}");
    let assets = fetch_release_assets(&client, &tag_name).unwrap_or_default();
    let selected_asset = select_portable_update_asset(&assets);

    let latest_version = release_tag_version(&tag_name).to_owned();
    let available = is_version_newer(&latest_version, env!("CARGO_PKG_VERSION"));

    Ok(UpdateInfo {
        latest_version,
        html_url,
        available,
        download_url: selected_asset
            .as_ref()
            .map(|asset| asset.download_url.clone()),
        download_name: selected_asset.map(|asset| asset.name),
    })
}

fn fetch_latest_update_tag_from_atom(
    client: &Client,
    feed_path: &str,
    label: &str,
) -> Result<String, String> {
    let url = format!("https://github.com/{UPDATE_REPO}/{feed_path}");
    let text = client
        .get(&url)
        .header("User-Agent", USER_AGENT)
        .send()
        .map_err(|err| format!("failed to request {label}: {err}"))?
        .error_for_status()
        .map_err(|err| format!("{label} request failed: {err}"))?
        .text()
        .map_err(|err| format!("failed to read {label}: {err}"))?;
    latest_update_tag_from_release_feed(&text)
        .ok_or_else(|| format!("{label} did not contain an update release"))
}

fn fetch_latest_update_tag(client: &Client) -> Result<String, String> {
    let url = format!("https://api.github.com/repos/{UPDATE_REPO}/tags?per_page=100");
    let text = client
        .get(&url)
        .header("User-Agent", USER_AGENT)
        .send()
        .map_err(|err| format!("failed to request release tags: {err}"))?
        .error_for_status()
        .map_err(|err| format!("release tags request failed: {err}"))?
        .text()
        .map_err(|err| format!("failed to read release tags: {err}"))?;
    let tags: Vec<GitHubTag> =
        serde_json::from_str(&text).map_err(|err| format!("failed to parse tag list: {err}"))?;
    tags.into_iter()
        .filter(|tag| is_update_release_tag(&tag.name))
        .max_by(|left, right| {
            compare_versions(
                release_tag_version(&left.name),
                release_tag_version(&right.name),
            )
        })
        .map(|tag| tag.name)
        .ok_or_else(|| format!("no v* or {UPDATE_TAG_PREFIX}* update release found"))
}

fn fetch_release_assets(client: &Client, tag_name: &str) -> Result<Vec<ReleaseAsset>, String> {
    let url = format!("https://github.com/{UPDATE_REPO}/releases/expanded_assets/{tag_name}");
    let text = client
        .get(&url)
        .header("User-Agent", USER_AGENT)
        .send()
        .map_err(|err| format!("failed to request release assets: {err}"))?
        .error_for_status()
        .map_err(|err| format!("release assets request failed: {err}"))?
        .text()
        .map_err(|err| format!("failed to read release assets: {err}"))?;
    parse_release_assets(&text)
}

fn parse_release_assets(html: &str) -> Result<Vec<ReleaseAsset>, String> {
    let pattern = Regex::new(
        r#"(?s)<a[^>]+href="([^"]+/releases/download/[^"]+)"[^>]*>.*?<span[^>]+class="[^"]*Truncate-text text-bold[^"]*"[^>]*>([^<]+)</span>"#,
    )
    .map_err(|err| err.to_string())?;
    let mut assets = Vec::new();
    for captures in pattern.captures_iter(html) {
        let Some(href) = captures.get(1).map(|value| value.as_str()) else {
            continue;
        };
        let Some(name) = captures.get(2).map(|value| value.as_str()) else {
            continue;
        };
        if name.eq_ignore_ascii_case("source code") {
            continue;
        }
        let download_url = if href.starts_with("https://") {
            href.to_owned()
        } else {
            format!("https://github.com{href}")
        };
        assets.push(ReleaseAsset {
            name: decode_html_entities(name),
            download_url,
        });
    }
    Ok(assets)
}

fn decode_html_entities(value: &str) -> String {
    value
        .replace("&amp;", "&")
        .replace("&lt;", "<")
        .replace("&gt;", ">")
        .replace("&quot;", "\"")
        .replace("&#39;", "'")
}

fn select_portable_update_asset(assets: &[ReleaseAsset]) -> Option<ReleaseAsset> {
    let target = portable_update_target_key();
    let mut candidates = assets
        .iter()
        .filter(|asset| {
            let name = asset.name.to_ascii_lowercase();
            name.contains(target) && (name.ends_with(".zip") || name.ends_with(".tar.gz"))
        })
        .cloned()
        .collect::<Vec<_>>();
    candidates.sort_by(|left, right| {
        asset_update_score(&right.name).cmp(&asset_update_score(&left.name))
    });
    candidates.into_iter().next()
}

fn portable_update_target_key() -> &'static str {
    #[cfg(target_os = "windows")]
    {
        "x86_64-pc-windows-msvc"
    }
    #[cfg(all(target_os = "macos", target_arch = "aarch64"))]
    {
        "aarch64-apple-darwin"
    }
    #[cfg(all(target_os = "macos", not(target_arch = "aarch64")))]
    {
        "x86_64-apple-darwin"
    }
    #[cfg(target_os = "linux")]
    {
        "x86_64-unknown-linux-gnu"
    }
}

fn asset_update_score(name: &str) -> u8 {
    let name = name.to_ascii_lowercase();
    if name.ends_with(".zip") {
        3
    } else if name.ends_with(".tar.gz") {
        2
    } else {
        1
    }
}

fn latest_update_tag_from_release_feed(feed: &str) -> Option<String> {
    let tag_pattern = Regex::new(r#"/releases/tag/([^<\s"']+)"#).ok()?;
    tag_pattern
        .captures_iter(feed)
        .filter_map(|captures| captures.get(1).map(|value| value.as_str()))
        .filter_map(decode_release_tag)
        .filter(|tag| is_update_release_tag(tag))
        .max_by(|left, right| {
            compare_versions(release_tag_version(left), release_tag_version(right))
        })
}

fn decode_release_tag(value: &str) -> Option<String> {
    let mut output = Vec::with_capacity(value.len());
    let mut bytes = value.as_bytes().iter().copied().peekable();
    while let Some(byte) = bytes.next() {
        if byte == b'%' {
            let high = bytes.next()?;
            let low = bytes.next()?;
            let high = hex_value(high)?;
            let low = hex_value(low)?;
            output.push(high << 4 | low);
        } else {
            output.push(byte);
        }
    }
    String::from_utf8(output).ok()
}

fn hex_value(byte: u8) -> Option<u8> {
    match byte {
        b'0'..=b'9' => Some(byte - b'0'),
        b'a'..=b'f' => Some(byte - b'a' + 10),
        b'A'..=b'F' => Some(byte - b'A' + 10),
        _ => None,
    }
}

fn is_update_release_tag(tag: &str) -> bool {
    tag.starts_with(UPDATE_TAG_PREFIX)
        || tag
            .strip_prefix('v')
            .map(is_semver_tag_version)
            .unwrap_or_else(|| is_semver_tag_version(tag))
}

fn is_semver_tag_version(value: &str) -> bool {
    let core = value
        .split(|ch| ch == '-' || ch == '+')
        .next()
        .unwrap_or(value);
    let parts = core.split('.').collect::<Vec<_>>();
    (2..=3).contains(&parts.len())
        && parts
            .iter()
            .all(|part| !part.is_empty() && part.chars().all(|ch| ch.is_ascii_digit()))
}

fn release_tag_version(tag: &str) -> &str {
    tag.strip_prefix(UPDATE_TAG_PREFIX)
        .or_else(|| tag.strip_prefix('v'))
        .unwrap_or(tag)
}

fn compare_versions(left: &str, right: &str) -> std::cmp::Ordering {
    let left_parts = version_parts(left);
    let right_parts = version_parts(right);
    let max_len = left_parts.len().max(right_parts.len()).max(1);

    for index in 0..max_len {
        let left_part = *left_parts.get(index).unwrap_or(&0);
        let right_part = *right_parts.get(index).unwrap_or(&0);
        match left_part.cmp(&right_part) {
            std::cmp::Ordering::Equal => {}
            ordering => return ordering,
        }
    }

    std::cmp::Ordering::Equal
}

fn is_version_newer(latest: &str, current: &str) -> bool {
    compare_versions(latest, current) == std::cmp::Ordering::Greater
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
            drop_on_timeout: row.endpoint.drop_on_timeout,
            last_queried: Some(std::time::Instant::now()),
            a2s_probe: row.endpoint.a2s_probe,
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
            steam_id: None,
            points: None,
            playtime_mins: None,
            ppm: None,
            quarter_points: None,
        });
    }

    Ok(players)
}

fn fetch_server_network_info(address: &str, ip: &str) -> Result<ServerNetworkInfo, String> {
    const IP_API_FIELDS: &str = "status,message,country,regionName,city,isp,org,as,query";

    let client = api_client(Duration::from_secs(8))?;
    let url = reqwest::Url::parse(&format!("http://ip-api.com/json/{ip}"))
        .map_err(|err| format!("failed to build IP lookup URL: {err}"))?;
    let response: IpApiResponse = response_json(
        client
            .get(url)
            .query(&[("fields", IP_API_FIELDS), ("lang", "zh-CN")])
            .send()
            .map_err(|err| format!("failed to query IP network info: {err}"))?,
    )?;

    if response.status != "success" {
        return Err(response
            .message
            .unwrap_or_else(|| "IP lookup failed".to_owned()));
    }

    Ok(ServerNetworkInfo {
        address: address.to_owned(),
        ip: response.query.unwrap_or_else(|| ip.to_owned()),
        country: response.country.unwrap_or_default(),
        region: response.region_name.unwrap_or_default(),
        city: response.city.unwrap_or_default(),
        isp: response.isp.unwrap_or_default(),
        org: response.org.unwrap_or_default(),
        asn: response.asn.unwrap_or_default(),
    })
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

fn is_retryable_status(status: StatusCode) -> bool {
    status == StatusCode::REQUEST_TIMEOUT
        || status == StatusCode::TOO_MANY_REQUESTS
        || status.is_server_error()
}

fn send_api_request_with_retry<F>(
    label: &str,
    attempts: usize,
    mut send: F,
) -> Result<Response, String>
where
    F: FnMut() -> reqwest::Result<Response>,
{
    let attempts = attempts.max(1);
    let mut last_error = String::new();

    for attempt in 1..=attempts {
        match send() {
            Ok(response) => {
                if attempt < attempts && is_retryable_status(response.status()) {
                    last_error = format!("API HTTP {}", response.status());
                } else {
                    return Ok(response);
                }
            }
            Err(err) => {
                let retryable = err.is_timeout() || err.is_connect() || err.is_request();
                last_error = if err.is_timeout() {
                    "request timed out".to_owned()
                } else if err.is_connect() {
                    "connection failed".to_owned()
                } else {
                    err.to_string()
                };
                if !retryable || attempt >= attempts {
                    return Err(format!(
                        "{label} failed after {attempt} attempt(s): {last_error}"
                    ));
                }
            }
        }

        thread::sleep(Duration::from_millis(250 * attempt as u64));
    }

    Err(format!(
        "{label} failed after {attempts} attempt(s): {last_error}"
    ))
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
    let response = send_api_request_with_retry("send broadcast", 3, || {
        client
            .post(url.clone())
            .bearer_auth(&request.token)
            .json(&serde_json::json!({ "message": message }))
            .send()
    })?;
    response_json(response)
}

fn api_broadcast_history(
    request: BroadcastHistoryRequest,
) -> Result<BroadcastHistoryResult, String> {
    let _time_zone = normalize_time_zone_setting(&request.time_zone);
    let client = api_client(Duration::from_secs(10))?;
    let url = api_url(&request.base_url, "/api/server/broadcast_history.php")?;
    let response = send_api_request_with_retry("query broadcast history", 3, || {
        let mut builder = client
            .get(url.clone())
            .query(&[("since", "3600"), ("limit", "120")]);
        if !request.token.trim().is_empty() {
            builder = builder.bearer_auth(&request.token);
        }
        builder.send()
    })?;
    let response: ApiBroadcastHistoryResponse = response_json(response)?;

    if response.ok {
        Ok(BroadcastHistoryResult {
            messages: response.messages,
            auth_type: response.auth_type.unwrap_or_else(|| {
                if request.token.trim().is_empty() {
                    "anonymous".to_owned()
                } else {
                    "steam".to_owned()
                }
            }),
            cache_ttl: if request.token.trim().is_empty() {
                Duration::from_secs(600)
            } else {
                Duration::from_secs(response.cache_ttl.unwrap_or(60).max(60))
            },
        })
    } else {
        Err(response
            .message
            .or(response.error)
            .unwrap_or_else(|| "broadcast history API failed".to_owned()))
    }
}

fn normalized_player_name(name: &str) -> String {
    name.trim().to_lowercase()
}

fn is_anne_server_name(name: &str) -> bool {
    name.trim_start().to_ascii_lowercase().starts_with("anne")
}

fn api_token_key(token: &str) -> String {
    let token = token.trim();
    if token.is_empty() {
        "anonymous".to_owned()
    } else {
        let mut hasher = DefaultHasher::new();
        token.hash(&mut hasher);
        format!("token:{:016x}", hasher.finish())
    }
}

fn online_stats_cache_ttl(token: &str, value: Option<u64>) -> Duration {
    if token.trim().is_empty() {
        return ONLINE_STATS_ANON_CACHE_TTL;
    }

    let _ = value;
    ONLINE_STATS_AUTH_CACHE_TTL
}

fn merge_player_stats(stats: &mut HashMap<String, PlayerStats>, players: Vec<PlayerStats>) {
    for player in players {
        let key = normalized_player_name(&player.name);
        if key.is_empty() {
            continue;
        }

        let should_insert = stats
            .get(&key)
            .map(|existing: &PlayerStats| player.updated > existing.updated)
            .unwrap_or(true);
        if should_insert {
            stats.insert(key, player);
        }
    }
}

fn fetch_online_player_stats(
    base_url: &str,
    token: &str,
) -> Result<(HashMap<String, PlayerStats>, Duration), String> {
    let client = api_client(Duration::from_secs(15))?;
    let url = api_url(base_url, "/api/player/online.php")?;
    let mut stats = HashMap::new();
    let mut cache_ttl = ONLINE_STATS_CACHE_TTL;
    let mut offset = 0usize;
    let page_session = format!(
        "{}:{}",
        std::process::id(),
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .map(|duration| duration.as_nanos())
            .unwrap_or_default()
    );

    for _ in 0..4 {
        let limit = ONLINE_STATS_PAGE_LIMIT
            .saturating_sub(offset)
            .clamp(1, ONLINE_STATS_PAGE_LIMIT);
        let limit_text = limit.to_string();
        let offset_text = offset.to_string();
        let mut request = client.get(url.clone()).query(&[
            ("since", "120"),
            ("limit", limit_text.as_str()),
            ("offset", offset_text.as_str()),
            ("page_session", page_session.as_str()),
        ]);
        if !token.trim().is_empty() {
            request = request.bearer_auth(token);
        }

        let raw_response = request
            .send()
            .map_err(|err| format!("failed to query online player stats: {err}"))?;
        if token.trim().is_empty() && raw_response.status() == StatusCode::UNAUTHORIZED {
            return Ok((stats, ONLINE_STATS_ANON_CACHE_TTL));
        }
        let response: OnlinePlayersResponse = response_json(raw_response)?;

        if !response.ok {
            return Err(response
                .message
                .or(response.error)
                .unwrap_or_else(|| "online player stats API failed".to_owned()));
        }

        let returned_len = response.players.len();
        let api_limit = response.limit.unwrap_or(returned_len);
        let response_offset = response.offset.unwrap_or(offset);
        let has_more = response
            .has_more
            .unwrap_or(api_limit > 0 && returned_len >= api_limit);
        let previous_count = stats.len();
        cache_ttl = online_stats_cache_ttl(token, response.cache_ttl);
        merge_player_stats(&mut stats, response.players);
        let added_new_stats = stats.len() > previous_count;

        if returned_len == 0
            || !has_more
            || response_offset.saturating_add(returned_len) >= ONLINE_STATS_PAGE_LIMIT
        {
            break;
        }
        if !added_new_stats && offset > 0 {
            break;
        }
        offset = response_offset.saturating_add(returned_len);
    }

    Ok((stats, cache_ttl))
}

fn online_stats_cache_needs_refresh(
    base_url: &str,
    token: &str,
    cache: &SharedOnlineStatsCache,
) -> bool {
    let Ok(cache) = cache.lock() else {
        return false;
    };
    !online_stats_cache_is_fresh(&cache, base_url, token)
}

fn online_stats_cache_is_fresh(cache: &OnlineStatsCache, base_url: &str, token: &str) -> bool {
    cache.base_url == base_url
        && cache.token_key == api_token_key(token)
        && cache
            .fetched_at
            .map(|fetched_at| fetched_at.elapsed() < cache.max_age)
            .unwrap_or(false)
}

fn cached_online_player_stats(
    base_url: &str,
    token: &str,
    cache: &SharedOnlineStatsCache,
) -> Option<HashMap<String, PlayerStats>> {
    let Ok(cache) = cache.lock() else {
        return None;
    };
    if online_stats_cache_is_fresh(&cache, base_url, token) {
        Some(cache.stats.clone())
    } else {
        None
    }
}

fn refresh_online_player_stats_cache(
    base_url: &str,
    token: &str,
    cache: &SharedOnlineStatsCache,
    force: bool,
) -> Result<(), String> {
    if !force && !online_stats_cache_needs_refresh(base_url, token, cache) {
        return Ok(());
    }

    let (stats, max_age) = fetch_online_player_stats(base_url, token)?;
    let mut cache = cache
        .lock()
        .map_err(|_| "online stats cache lock poisoned".to_owned())?;
    cache.base_url = base_url.to_owned();
    cache.token_key = api_token_key(token);
    cache.fetched_at = Some(Instant::now());
    cache.max_age = max_age;
    cache.stats = stats;
    Ok(())
}

fn apply_player_stats(player: &mut PlayerInfo, stats: &HashMap<String, PlayerStats>) {
    if let Some(stat) = stats.get(&normalized_player_name(&player.name)) {
        player.steam_id = non_empty(stat.steamid.trim().to_owned(), "steamid").ok();
        player.points = Some(stat.total_points);
        player.playtime_mins = Some(stat.playtime_minutes);
        player.ppm = Some(stat.ppm);
        player.quarter_points = Some(stat.quarter_points);
    }
}

fn apply_global_player_stats(player: &mut GlobalPlayerEntry, stats: &HashMap<String, PlayerStats>) {
    if let Some(stat) = stats.get(&normalized_player_name(&player.name)) {
        player.steam_id = non_empty(stat.steamid.trim().to_owned(), "steamid").ok();
        player.points = Some(stat.total_points);
        player.playtime_mins = Some(stat.playtime_minutes);
        player.ppm = Some(stat.ppm);
        player.quarter_points = Some(stat.quarter_points);
    }
}

fn apply_cached_player_stats(
    base_url: &str,
    token: &str,
    cache: &SharedOnlineStatsCache,
    players: &mut [PlayerInfo],
) -> bool {
    let Some(stats) = cached_online_player_stats(base_url, token, cache) else {
        return false;
    };

    for player in players {
        apply_player_stats(player, &stats);
    }
    true
}

fn apply_cached_global_anne_player_stats(
    base_url: &str,
    token: &str,
    cache: &SharedOnlineStatsCache,
    players: &mut [GlobalPlayerEntry],
) -> bool {
    if !players
        .iter()
        .any(|player| is_anne_server_name(&player.server_name))
    {
        return true;
    }

    let Some(stats) = cached_online_player_stats(base_url, token, cache) else {
        return false;
    };

    for player in players {
        if is_anne_server_name(&player.server_name) {
            apply_global_player_stats(player, &stats);
        }
    }
    true
}

fn is_fake_dns_ipv4(ip: &Ipv4Addr) -> bool {
    let octets = ip.octets();
    octets[0] == 198 && matches!(octets[1], 18 | 19)
}

fn split_host_port(address: &str) -> Option<(&str, u16)> {
    let (host, port) = address.rsplit_once(':')?;
    let port = port.parse::<u16>().ok()?;
    let host = host.trim().trim_start_matches('[').trim_end_matches(']');
    if host.is_empty() {
        None
    } else {
        Some((host, port))
    }
}

fn resolve_public_ipv4(address: &str, timeout: Duration) -> Option<SocketAddrV4> {
    let normalized = normalize_endpoint_input(address).ok()?;
    let (host, port) = split_host_port(&normalized)?;
    if let Ok(ip) = host.parse::<Ipv4Addr>() {
        return Some(SocketAddrV4::new(ip, port));
    }

    let client = api_client(timeout).ok()?;
    let mut url = reqwest::Url::parse("https://dns.alidns.com/resolve").ok()?;
    url.query_pairs_mut()
        .append_pair("name", host)
        .append_pair("type", "A");
    let value: serde_json::Value = response_json(client.get(url).send().ok()?).ok()?;
    if value.get("Status").and_then(|status| status.as_i64()) != Some(0) {
        return None;
    }

    let answers = value.get("Answer")?.as_array()?;
    for answer in answers {
        if answer.get("type").and_then(|value| value.as_u64()) != Some(1) {
            continue;
        }
        let Some(data) = answer.get("data").and_then(|value| value.as_str()) else {
            continue;
        };
        let Ok(ip) = data.parse::<Ipv4Addr>() else {
            continue;
        };
        if !is_fake_dns_ipv4(&ip) {
            return Some(SocketAddrV4::new(ip, port));
        }
    }

    None
}

fn steam_connect_address(address: &str) -> String {
    let normalized = match normalize_endpoint_input(address) {
        Ok(address) => address,
        Err(_) => return address.trim().to_owned(),
    };

    match resolve_endpoint(&normalized) {
        Ok(endpoint) if is_fake_dns_ipv4(endpoint.socket.ip()) => {
            resolve_public_ipv4(&normalized, Duration::from_millis(1800))
                .unwrap_or(endpoint.socket)
                .to_string()
        }
        Ok(endpoint) => endpoint.socket.to_string(),
        Err(_) => resolve_public_ipv4(&normalized, Duration::from_millis(1800))
            .map(|socket| socket.to_string())
            .unwrap_or(normalized),
    }
}

fn launch_steam_connect(address: &str) {
    let connect_address = steam_connect_address(address);
    let url = format!("steam://connect/{connect_address}");
    launch_url(&url);
}

fn launch_url(url: &str) {
    #[cfg(target_os = "windows")]
    {
        use std::os::windows::process::CommandExt;
        let _ = std::process::Command::new("cmd")
            .args(["/c", "start", "", url])
            .creation_flags(0x08000000)
            .spawn();
    }
    #[cfg(target_os = "macos")]
    {
        let _ = std::process::Command::new("open").arg(url).spawn();
    }
    #[cfg(target_os = "linux")]
    {
        let _ = std::process::Command::new("xdg-open").arg(url).spawn();
    }
}

pub fn open_tauri_url(url: String) -> Result<(), String> {
    let trimmed = url.trim();
    let parsed = reqwest::Url::parse(trimmed).map_err(|err| format!("invalid URL: {err}"))?;
    if !matches!(parsed.scheme(), "http" | "https") {
        return Err("only http and https URLs can be opened".to_owned());
    }
    launch_url(parsed.as_str());
    Ok(())
}

fn download_and_launch_portable_update(
    req: TauriInstallUpdateRequest,
) -> Result<TauriInstallUpdateResult, String> {
    let parsed =
        reqwest::Url::parse(req.url.trim()).map_err(|err| format!("invalid URL: {err}"))?;
    if !matches!(parsed.scheme(), "http" | "https") {
        return Err("only http and https update URLs can be downloaded".to_owned());
    }

    let file_name = req
        .file_name
        .as_deref()
        .map(safe_update_file_name)
        .filter(|name| !name.is_empty())
        .unwrap_or_else(|| {
            parsed
                .path_segments()
                .and_then(|mut segments| segments.next_back())
                .map(safe_update_file_name)
                .filter(|name| !name.is_empty())
                .unwrap_or_else(|| "Anne刷服器-update.zip".to_owned())
        });

    let update_dir = env::temp_dir().join(format!(
        "anne-server-browser-update-{}",
        chrono::Utc::now().timestamp()
    ));
    fs::create_dir_all(&update_dir).map_err(|err| format!("failed to create update dir: {err}"))?;
    let archive_path = update_dir.join(file_name);

    let client = api_client(Duration::from_secs(120))?;
    let mut response = client
        .get(parsed)
        .header("User-Agent", USER_AGENT)
        .send()
        .map_err(|err| format!("failed to download update: {err}"))?
        .error_for_status()
        .map_err(|err| format!("update download failed: {err}"))?;
    let mut file = fs::File::create(&archive_path)
        .map_err(|err| format!("failed to create update file: {err}"))?;
    io::copy(&mut response, &mut file).map_err(|err| format!("failed to save update: {err}"))?;
    drop(file);

    launch_portable_update(&archive_path, &update_dir)
}

fn safe_update_file_name(value: &str) -> String {
    value
        .chars()
        .map(|ch| match ch {
            '/' | '\\' | ':' | '*' | '?' | '"' | '<' | '>' | '|' => '_',
            _ => ch,
        })
        .collect::<String>()
        .trim()
        .to_owned()
}

fn launch_portable_update(
    archive_path: &Path,
    update_dir: &Path,
) -> Result<TauriInstallUpdateResult, String> {
    #[cfg(target_os = "windows")]
    {
        launch_windows_portable_update(archive_path, update_dir)
    }
    #[cfg(target_os = "macos")]
    {
        launch_macos_portable_update(archive_path, update_dir)
    }
    #[cfg(target_os = "linux")]
    {
        launch_linux_portable_update(archive_path, update_dir)
    }
}

#[cfg(target_os = "windows")]
fn launch_windows_portable_update(
    archive_path: &Path,
    update_dir: &Path,
) -> Result<TauriInstallUpdateResult, String> {
    use std::os::windows::process::CommandExt;

    let current_exe =
        env::current_exe().map_err(|err| format!("failed to locate current exe: {err}"))?;
    let app_dir = current_exe
        .parent()
        .ok_or_else(|| "failed to locate app directory".to_owned())?
        .to_path_buf();
    let extract_dir = update_dir.join("extracted");
    let script_path = update_dir.join("apply-update.ps1");
    let script = format!(
        r#"
$ErrorActionPreference = "Stop"
$archive = {archive}
$extract = {extract}
$target = {target}
$exe = {exe}
$pidToWait = {pid}
if ($pidToWait -gt 0) {{
  while (Get-Process -Id $pidToWait -ErrorAction SilentlyContinue) {{
    Start-Sleep -Milliseconds 500
  }}
}}
if (Test-Path $extract) {{ Remove-Item -LiteralPath $extract -Recurse -Force }}
New-Item -ItemType Directory -Path $extract -Force | Out-Null
Expand-Archive -LiteralPath $archive -DestinationPath $extract -Force
$root = Get-ChildItem -LiteralPath $extract | Where-Object {{ $_.PSIsContainer }} | Select-Object -First 1
if ($null -eq $root) {{ throw "更新包内没有可替换目录" }}
Get-ChildItem -LiteralPath $root.FullName -Force | ForEach-Object {{
  Copy-Item -LiteralPath $_.FullName -Destination $target -Recurse -Force
}}
Start-Process -FilePath $exe -WorkingDirectory $target
"#,
        archive = ps_quote_path(archive_path),
        extract = ps_quote_path(&extract_dir),
        target = ps_quote_path(&app_dir),
        exe = ps_quote_path(&current_exe),
        pid = std::process::id(),
    );
    fs::write(&script_path, script)
        .map_err(|err| format!("failed to write update script: {err}"))?;
    let script_arg = script_path.display().to_string();
    std::process::Command::new("powershell")
        .args([
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            &script_arg,
        ])
        .creation_flags(0x08000000)
        .spawn()
        .map_err(|err| format!("failed to start update script: {err}"))?;
    Ok(TauriInstallUpdateResult {
        message: "更新包已下载，程序退出后会自动替换并重新启动。".to_owned(),
        should_exit: true,
    })
}

#[cfg(target_os = "windows")]
fn ps_quote_path(path: &Path) -> String {
    format!("'{}'", path.display().to_string().replace('\'', "''"))
}

#[cfg(target_os = "macos")]
fn launch_macos_portable_update(
    archive_path: &Path,
    update_dir: &Path,
) -> Result<TauriInstallUpdateResult, String> {
    let extract_dir = update_dir.join("extracted");
    fs::create_dir_all(&extract_dir)
        .map_err(|err| format!("failed to create extract dir: {err}"))?;
    let archive_arg = archive_path.display().to_string();
    let extract_arg = extract_dir.display().to_string();
    std::process::Command::new("tar")
        .args(["-xzf", &archive_arg, "-C", &extract_arg])
        .status()
        .map_err(|err| format!("failed to extract update: {err}"))
        .and_then(|status| {
            if status.success() {
                Ok(())
            } else {
                Err(format!("update extract failed with status {status}"))
            }
        })?;
    std::process::Command::new("open")
        .arg(&extract_dir)
        .spawn()
        .map_err(|err| format!("failed to open extracted update: {err}"))?;
    Ok(TauriInstallUpdateResult {
        message: format!("更新包已下载并解压到 {}", extract_dir.display()),
        should_exit: false,
    })
}

#[cfg(target_os = "linux")]
fn launch_linux_portable_update(
    archive_path: &Path,
    update_dir: &Path,
) -> Result<TauriInstallUpdateResult, String> {
    let extract_dir = update_dir.join("extracted");
    fs::create_dir_all(&extract_dir)
        .map_err(|err| format!("failed to create extract dir: {err}"))?;
    let archive_arg = archive_path.display().to_string();
    let extract_arg = extract_dir.display().to_string();
    std::process::Command::new("tar")
        .args(["-xzf", &archive_arg, "-C", &extract_arg])
        .status()
        .map_err(|err| format!("failed to extract update: {err}"))
        .and_then(|status| {
            if status.success() {
                Ok(())
            } else {
                Err(format!("update extract failed with status {status}"))
            }
        })?;
    std::process::Command::new("xdg-open")
        .arg(&extract_dir)
        .spawn()
        .map_err(|err| format!("failed to open extracted update: {err}"))?;
    Ok(TauriInstallUpdateResult {
        message: format!("更新包已下载并解压到 {}", extract_dir.display()),
        should_exit: false,
    })
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
    fn extracts_subscription_addresses() {
        let html = r#"
            <a href="steam://connect/51.79.176.131:27015">connect</a>
            <td>51.79.176.131:27025</td>
            <a href='steam://connect/example.org:27015/password'>host</a>
            <td>coop.l4d2zone.pl:27015</td>
            <span>escaped.example.org\u003a27016</span>
            <span>steam:\/\/connect\/10.0.0.2:27017</span>
        "#;

        let addresses = extract_subscription_addresses(html).expect("addresses");
        assert!(addresses.contains(&"51.79.176.131:27015".to_owned()));
        assert!(addresses.contains(&"51.79.176.131:27025".to_owned()));
        assert!(addresses.contains(&"example.org:27015".to_owned()));
        assert!(addresses.contains(&"coop.l4d2zone.pl:27015".to_owned()));
        assert!(addresses.contains(&"escaped.example.org:27016".to_owned()));
        assert!(addresses.contains(&"10.0.0.2:27017".to_owned()));
    }

    #[test]
    fn extracts_subscription_addresses_from_json_payload() {
        let json = r#"{"server":{"address":"45.125.45.95:28001"}}"#;
        let addresses = extract_subscription_addresses(json).expect("addresses");
        assert!(addresses.contains(&"45.125.45.95:28001".to_owned()));
    }

    #[test]
    fn extracts_pasted_subscription_addresses() {
        let text = r#"
            steam://connect/45.125.45.95:28001
            hbbgp.trygek.com:31001
        "#;
        let addresses = extract_pasted_subscription(text, "Pasted").expect("addresses");
        assert_eq!(
            addresses,
            vec![
                "45.125.45.95:28001".to_owned(),
                "hbbgp.trygek.com:31001".to_owned()
            ]
        );
    }

    #[test]
    fn steam_connect_address_uses_resolved_ipv4() {
        assert_eq!(
            steam_connect_address("45.125.45.95:28001"),
            "45.125.45.95:28001"
        );
    }

    #[test]
    fn detects_fake_dns_ipv4_range() {
        assert!(is_fake_dns_ipv4(&Ipv4Addr::new(198, 18, 0, 12)));
        assert!(is_fake_dns_ipv4(&Ipv4Addr::new(198, 19, 255, 255)));
        assert!(!is_fake_dns_ipv4(&Ipv4Addr::new(103, 39, 67, 29)));
    }

    #[test]
    fn normalizes_sourcebans_root_url() {
        let url = normalize_subscription_url("https://example.com/sourcebans").expect("url");
        assert_eq!(
            url.as_str(),
            "https://example.com/sourcebans/index.php?p=servers"
        );
    }

    #[test]
    fn preserves_generic_subscription_url() {
        let url = normalize_subscription_url("https://www.kitasoda.com/#/serverList").expect("url");
        assert_eq!(url.as_str(), "https://www.kitasoda.com/#/serverList");
    }

    #[test]
    fn generic_subscription_drops_timeout_servers() {
        let generic = SourceBansSubscription {
            name: "Kita".to_owned(),
            url: "https://www.kitasoda.com/#/serverList".to_owned(),
            text: String::new(),
            servers: Vec::new(),
            a2s_probe: false,
        };
        assert!(subscription_drops_timeout_servers(&generic));

        let sourcebans = SourceBansSubscription {
            name: "Anne".to_owned(),
            url: "https://anne.trygek.com/bans/index.php?p=servers".to_owned(),
            text: String::new(),
            servers: Vec::new(),
            a2s_probe: false,
        };
        assert!(!subscription_drops_timeout_servers(&sourcebans));
    }

    #[test]
    fn detects_vercel_security_checkpoint() {
        let body = "<title>Vercel Security Checkpoint</title>";
        assert_eq!(
            detect_subscription_blocker(body),
            Some("site returned Vercel challenge; non-browser subscription requests are blocked")
        );
    }

    #[test]
    fn detects_vercel_mitigation_header() {
        let mut headers = reqwest::header::HeaderMap::new();
        headers.insert(
            "x-vercel-mitigated",
            reqwest::header::HeaderValue::from_static("challenge"),
        );
        assert_eq!(
            detect_subscription_response_blocker(&headers, ""),
            Some("site returned Vercel challenge; non-browser subscription requests are blocked")
        );
    }

    #[test]
    fn naturally_sorts_numbered_server_names() {
        assert_eq!(
            cmp_natural_ci("电信服 2", "电信服 10"),
            std::cmp::Ordering::Less
        );
        assert_eq!(
            cmp_natural_ci("电信服 40", "电信服 3"),
            std::cmp::Ordering::Greater
        );
    }

    #[test]
    fn extracts_same_origin_subscription_data_urls() {
        let base = reqwest::Url::parse("http://heimiao520.cn/").expect("url");
        let js = r#"
            const all = "/api/all";
            const servers = "/api/servers?region=cn";
            const rank = "/api/rank/name/foo";
            const top = `/api/top/${kind}`;
            const external = "https://other.example/api/all";
        "#;

        let data_urls = extract_subscription_data_urls(&base, js).expect("data urls");
        let urls = data_urls.iter().map(|url| url.as_str()).collect::<Vec<_>>();
        assert_eq!(
            urls,
            vec![
                "http://heimiao520.cn/api/all",
                "http://heimiao520.cn/api/servers?region=cn",
            ]
        );
    }

    #[test]
    fn extracts_same_origin_subscription_resources() {
        let base = reqwest::Url::parse("https://www.kitasoda.com/#/serverList").expect("url");
        let html = r#"
            <script defer src="build/bundle.4d6786dee3cc5ca77387.js"></script>
            <script src="https://other.example/app.js"></script>
            <link href="/build/bundle.css" rel="stylesheet">
            <link href="/data/servers.json" rel="preload">
        "#;

        let resources = extract_linked_subscription_resources(&base, html).expect("resources");
        let urls = resources.iter().map(|url| url.as_str()).collect::<Vec<_>>();
        assert_eq!(
            urls,
            vec![
                "https://www.kitasoda.com/build/bundle.4d6786dee3cc5ca77387.js",
                "https://www.kitasoda.com/data/servers.json",
            ]
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
    fn normalizes_time_zone_setting() {
        assert_eq!(normalize_time_zone_setting(""), "system");
        assert_eq!(normalize_time_zone_setting("local"), "system");
        assert_eq!(
            normalize_time_zone_setting("Asia/Shanghai"),
            "Asia/Shanghai"
        );
        assert_eq!(normalize_time_zone_setting("Bad/Zone"), "system");
    }

    #[test]
    fn formats_broadcast_time_in_configured_zone() {
        assert_eq!(
            format_broadcast_time("2026-05-27 12:34:56", "UTC"),
            "2026-05-27 12:34:56 UTC"
        );
        assert_eq!(
            format_broadcast_time("2026-05-27 12:34:56", "Asia/Shanghai"),
            "2026-05-27 20:34:56 CST"
        );
    }

    #[test]
    fn compares_release_versions() {
        assert_eq!(release_tag_version("Anne刷服器-v0.5.1"), "0.5.1");
        assert_eq!(release_tag_version("v0.5.0"), "0.5.0");
        assert!(is_update_release_tag("Anne刷服器-v0.5.0"));
        assert!(is_update_release_tag("v0.5.0"));
        assert!(is_update_release_tag("0.5.0"));
        assert!(!is_update_release_tag(
            "CompetitiveWithAnne-stable-release-2026-05-09"
        ));
        assert!(is_version_newer("0.5.0", "0.4.0"));
        assert!(is_version_newer("0.4.1", "0.4.0"));
        assert!(!is_version_newer("0.4.0", "0.4.0"));
        assert!(!is_version_newer("0.3.9", "0.4.0"));
    }

    #[test]
    fn extracts_latest_release_tag_from_atom_feed() {
        let feed = r#"
            <feed>
              <entry>
                <link href="https://github.com/fantasylidong/CompetitiveWithAnne/releases/tag/Anne%E5%88%B7%E6%9C%8D%E5%99%A8-v0.8.0"/>
              </entry>
              <entry>
                <link href="https://github.com/fantasylidong/CompetitiveWithAnne/releases/tag/Anne%E5%88%B7%E6%9C%8D%E5%99%A8-v0.9.1"/>
              </entry>
              <entry>
                <link href="https://github.com/fantasylidong/CompetitiveWithAnne/releases/tag/CompetitiveWithAnne-stable-release-2026-05-09"/>
              </entry>
            </feed>
        "#;

        assert_eq!(
            latest_update_tag_from_release_feed(feed).as_deref(),
            Some("Anne刷服器-v0.9.1")
        );
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
