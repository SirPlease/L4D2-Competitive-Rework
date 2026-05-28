import { getLocale, initI18n, setLocale, t } from './i18n.js';

const tauriInvoke = window.__TAURI__?.core?.invoke;
const CONFIG_PATH_OVERRIDE_KEY = "configPathOverride";
const UPDATE_CHECK_CACHE_KEY = "lastAutoUpdateCheckAt";
const UPDATE_CHECK_INTERVAL_MS = 12 * 60 * 60 * 1000;
const PING_MINI_WINDOW_MS = 5 * 60 * 1000;
const PING_DETAIL_MIN_WINDOW_MS = 5 * 60 * 1000;
const PING_MAX_CONNECT_GAP_MS = 45 * 1000;
const SELECTED_REFRESH_DEFAULT_SECS = 5;
const BROADCAST_REFRESH_INTERVAL_MS = 10 * 1000;
const ANNE_PLAYER_STATS_BASE_URL = "https://anne.trygek.com/stats/ranking/player.php";

const state = {
  tab: "servers",
  configPath: "",
  lists: null,
  allRows: [],
  rows: [],
  group: null,
  search: "",
  onlyWithPlayers: false,
  onlyEmpty: false,
  hideTimeout: true,
  selectedSourcebans: null,
  busy: false,
  apiToken: null,
  apiBaseUrl: "",
  autoCheckUpdate: true,
  anneStatsEnabled: true,
  rconPasswords: {},
  rconPasswordSaved: false,
  themeMode: "light",
  accentColor: "#0f766e",
  steamUser: null,
  inspectorOpen: false,
  selectedAddress: null,
  selectedSocket: null,
  inspectorTab: "players",
  sortKey: "players",
  sortDesc: true,
  autoRefreshTimer: null,
  broadcastRefreshTimer: null,
  autoRefreshEmptySecs: 120,
  autoRefreshActiveSecs: 30,
  autoRefreshSelectedSecs: SELECTED_REFRESH_DEFAULT_SECS,
  timeZone: "system",
  pingHistory: new Map(),
  appStartedAt: Date.now(),
  broadcastSending: false,
  broadcastHistory: [],
  broadcastHistoryInFlight: false,
  lastFullRefreshAt: 0,
  lastActiveRefreshAt: 0,
  lastSelectedRefreshAt: 0,
  refreshInFlight: false,
  refreshSeq: 0
};

const naturalCollator = new Intl.Collator(undefined, {
  numeric: true,
  sensitivity: "base",
});

const TIME_ZONE_OPTIONS = [
  { value: "system", zh: "跟随系统时区", en: "Use system time zone" },
  { value: "Asia/Shanghai", zh: "上海 / 北京", en: "Shanghai / Beijing" },
  { value: "Asia/Hong_Kong", zh: "香港", en: "Hong Kong" },
  { value: "Asia/Taipei", zh: "台北", en: "Taipei" },
  { value: "Asia/Tokyo", zh: "东京", en: "Tokyo" },
  { value: "Asia/Seoul", zh: "首尔", en: "Seoul" },
  { value: "Asia/Singapore", zh: "新加坡", en: "Singapore" },
  { value: "Asia/Bangkok", zh: "曼谷", en: "Bangkok" },
  { value: "Asia/Dubai", zh: "迪拜", en: "Dubai" },
  { value: "Europe/London", zh: "伦敦", en: "London" },
  { value: "Europe/Berlin", zh: "柏林", en: "Berlin" },
  { value: "Europe/Moscow", zh: "莫斯科", en: "Moscow" },
  { value: "America/New_York", zh: "纽约", en: "New York" },
  { value: "America/Chicago", zh: "芝加哥", en: "Chicago" },
  { value: "America/Denver", zh: "丹佛", en: "Denver" },
  { value: "America/Los_Angeles", zh: "洛杉矶", en: "Los Angeles" },
  { value: "America/Vancouver", zh: "温哥华", en: "Vancouver" },
  { value: "Australia/Sydney", zh: "悉尼", en: "Sydney" },
  { value: "Pacific/Auckland", zh: "奥克兰", en: "Auckland" },
  { value: "UTC", zh: "协调世界时", en: "UTC" },
];

const $ = (selector) => document.querySelector(selector);
const $$ = (selector) => Array.from(document.querySelectorAll(selector));

async function invoke(command, args = {}) {
  if (tauriInvoke) {
    return tauriInvoke(command, args);
  }
  // No mock fallback for all new commands to keep it clean.
  return Promise.resolve(null);
}

function summarizeRows(rows) {
  const groups = new Map();
  let online = 0;
  let players = 0;
  for (const row of rows) {
    if (!row.error) online += 1;
    players += row.players;
    for (const group of row.groups) {
      groups.set(group, (groups.get(group) ?? 0) + 1);
    }
  }
  return {
    total: rows.length,
    online,
    players,
    groups: Array.from(groups.entries()),
  };
}

function setBusy(value, labelKey = "btnRefresh") {
  state.busy = value;
  $("#refreshBtn").disabled = false;
  $("#refreshBtn").textContent = value ? t("statusRefreshing") : t(labelKey);
}

function setRefreshButtonBusy(value, labelKey = "btnRefresh") {
  $("#refreshBtn").disabled = false;
  $("#refreshBtn").textContent = value ? t("statusRefreshing") : t(labelKey);
}

function setStatus(message) {
  $("#statusLine").textContent = message;
}

function compactPath(path) {
  if (!path) return t("configNotSet");
  if (path.length <= 44) return path;
  return `${path.slice(0, 18)}...${path.slice(-22)}`;
}

function uiLocaleFromConfig(value) {
  const normalized = String(value || "").replace("-", "_");
  return normalized === "en_US" ? "en_US" : "zh_CN";
}

function configLanguageFromLocale(value) {
  return value === "en_US" ? "en-US" : "zh-CN";
}

function boolText(value) {
  return value ? t("yes") : t("no");
}

function clampRefreshSeconds(value, fallback, min) {
  const seconds = Number.parseInt(value, 10);
  if (!Number.isFinite(seconds)) return fallback;
  return Math.max(min, seconds);
}

function normalizeTimeZone(value) {
  const trimmed = String(value || "").trim();
  if (!trimmed || /^(system|local|auto)$/i.test(trimmed)) return "system";
  try {
    new Intl.DateTimeFormat(undefined, { timeZone: trimmed }).format(new Date());
    return trimmed;
  } catch {
    return "system";
  }
}

function systemTimeZone() {
  return Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC";
}

function timeZoneOffsetMinutes(timeZone, date = new Date()) {
  try {
    const parts = new Intl.DateTimeFormat("en-US", {
      timeZone,
      hour12: false,
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
      second: "2-digit",
    }).formatToParts(date);
    const values = Object.fromEntries(parts.map((part) => [part.type, part.value]));
    const utcMillis = Date.UTC(
      Number(values.year),
      Number(values.month) - 1,
      Number(values.day),
      Number(values.hour) % 24,
      Number(values.minute),
      Number(values.second),
    );
    return Math.round((utcMillis - date.getTime()) / 60000);
  } catch {
    return 0;
  }
}

function formatGmtOffset(timeZone) {
  const minutes = timeZoneOffsetMinutes(timeZone);
  if (minutes === 0) return "GMT+0";
  const sign = minutes >= 0 ? "+" : "-";
  const absolute = Math.abs(minutes);
  const hours = Math.floor(absolute / 60);
  const rest = absolute % 60;
  return rest ? `GMT${sign}${hours}:${String(rest).padStart(2, "0")}` : `GMT${sign}${hours}`;
}

function timeZoneOptionLabel(option) {
  const locale = getLocale();
  const name = locale === "en_US" ? option.en : option.zh;
  if (option.value === "system") {
    const zone = systemTimeZone();
    return `${name} (${zone}, ${formatGmtOffset(zone)})`;
  }
  return `${name} (${option.value}, ${formatGmtOffset(option.value)})`;
}

function timeZoneHintText(value) {
  const zone = normalizeTimeZone(value);
  if (zone === "system") {
    const systemZone = systemTimeZone();
    return getLocale() === "en_US"
      ? `Current system: ${systemZone}, about ${formatGmtOffset(systemZone)}`
      : `当前系统：${systemZone}，约 ${formatGmtOffset(systemZone)}`;
  }
  return getLocale() === "en_US"
    ? `Selected: ${zone}, about ${formatGmtOffset(zone)}`
    : `已选择：${zone}，约 ${formatGmtOffset(zone)}`;
}

function populateTimeZoneOptions() {
  const select = $("#timeZoneInput");
  if (!select) return;
  const selected = normalizeTimeZone(state.timeZone);
  select.replaceChildren();
  const hasSelected = TIME_ZONE_OPTIONS.some((option) => option.value === selected);
  const options = hasSelected || selected === "system"
    ? TIME_ZONE_OPTIONS
    : [{ value: selected, zh: selected, en: selected }, ...TIME_ZONE_OPTIONS];
  for (const option of options) {
    const element = document.createElement("option");
    element.value = option.value;
    element.textContent = timeZoneOptionLabel(option);
    select.append(element);
  }
  select.value = selected;
}

function naturalCompare(left, right) {
  return naturalCollator.compare(String(left || ""), String(right || ""));
}

function normalizeThemeMode(value) {
  return ["light", "dark", "custom"].includes(value) ? value : "light";
}

function isHexColor(value) {
  return /^#[0-9a-f]{6}$/i.test(String(value || ""));
}

function darkenHex(value, amount = 0.18) {
  if (!isHexColor(value)) return "#0b5f59";
  const parts = [1, 3, 5].map((index) => parseInt(value.slice(index, index + 2), 16));
  const darkened = parts.map((part) => Math.max(0, Math.round(part * (1 - amount))));
  return `#${darkened.map((part) => part.toString(16).padStart(2, "0")).join("")}`;
}

function applyTheme(mode = state.themeMode, accent = state.accentColor) {
  state.themeMode = normalizeThemeMode(mode);
  state.accentColor = isHexColor(accent) ? accent : "#0f766e";
  document.body.dataset.theme = state.themeMode === "dark" ? "dark" : "light";
  if (state.themeMode === "custom") {
    document.body.style.setProperty("--accent", state.accentColor);
    document.body.style.setProperty("--accent-strong", darkenHex(state.accentColor));
  } else {
    document.body.style.removeProperty("--accent");
    document.body.style.removeProperty("--accent-strong");
  }
  const themeSelect = $("#themeSelect");
  const colorInput = $("#customAccentInput");
  if (themeSelect) themeSelect.value = state.themeMode;
  if (colorInput) {
    colorInput.value = state.accentColor;
  }
}

function syncConfigPathUI() {
  const input = $("#configPathInput");
  const hint = $("#configPathHint");
  if (input) input.value = state.configPath || "";
  if (hint) hint.textContent = compactPath(state.configPath);
}

function syncAutoRefreshInputs() {
  const empty = $("#autoRefreshEmptyInput");
  const active = $("#autoRefreshActiveInput");
  const selected = $("#autoRefreshSelectedInput");
  if (empty) empty.value = state.autoRefreshEmptySecs;
  if (active) active.value = state.autoRefreshActiveSecs;
  if (selected) selected.value = state.autoRefreshSelectedSecs;
}

function syncTimeZoneInput() {
  populateTimeZoneOptions();
  const input = $("#timeZoneInput");
  const hint = $("#timeZoneHint");
  if (input) input.value = state.timeZone || "system";
  if (hint) hint.textContent = timeZoneHintText(state.timeZone);
}

function hasSavedRconPassword(address = state.selectedAddress) {
  return Boolean(
    address
    && Object.prototype.hasOwnProperty.call(state.rconPasswords || {}, address)
    && state.rconPasswords[address]
  );
}

function savedRconPassword(address = state.selectedAddress) {
  return hasSavedRconPassword(address) ? state.rconPasswords[address] : "";
}

function syncRconPasswordControls(address = state.selectedAddress) {
  const passwordInput = $("#rconPassword");
  const saveInput = $("#saveRconPasswordInput");
  const saved = hasSavedRconPassword(address);
  state.rconPasswordSaved = saved;
  if (passwordInput) passwordInput.value = savedRconPassword(address);
  if (saveInput) saveInput.checked = saved;
}

function appendTextCell(row, value, className = "") {
  const cell = document.createElement("td");
  if (className) cell.className = className;
  cell.textContent = value === null || value === undefined || value === "" ? "-" : String(value);
  row.append(cell);
  return cell;
}

function annePlayerStatsUrl(player) {
  const steamId = String(player?.steam_id || player?.steamid || "").trim();
  if (!steamId || player?.points === null || player?.points === undefined) return null;
  return `${ANNE_PLAYER_STATS_BASE_URL}?steamid=${encodeURIComponent(steamId)}`;
}

function appendPlayerNameCell(row, player) {
  const cell = document.createElement("td");
  const name = player?.name ? String(player.name) : "-";
  const statsUrl = annePlayerStatsUrl(player);
  if (!statsUrl) {
    cell.textContent = name;
    row.append(cell);
    return cell;
  }

  const link = document.createElement("a");
  link.className = "player-stats-link";
  link.href = statsUrl;
  link.title = t("openPlayerStats");
  link.addEventListener("click", (event) => {
    event.preventDefault();
    openExternalUrl(statsUrl);
  });

  const label = document.createElement("span");
  label.className = "player-stats-name";
  label.textContent = name;
  link.append(label, createExternalLinkIcon());
  cell.append(link);
  row.append(cell);
  return cell;
}

function createExternalLinkIcon() {
  const svg = createSvgElement("svg", {
    viewBox: "0 0 24 24",
    class: "player-stats-icon",
    "aria-hidden": "true",
    focusable: "false",
  });
  svg.append(
    createSvgElement("path", {
      d: "M7 17 17 7M9 7h8v8",
      fill: "none",
      stroke: "currentColor",
      "stroke-width": "2",
      "stroke-linecap": "round",
      "stroke-linejoin": "round",
    })
  );
  return svg;
}

function appendEmptyRow(tbody, colSpan, message) {
  tbody.replaceChildren();
  const row = document.createElement("tr");
  const cell = document.createElement("td");
  cell.colSpan = colSpan;
  cell.className = "empty";
  cell.textContent = message;
  row.append(cell);
  tbody.append(row);
}

function formatDuration(seconds) {
  const totalSeconds = Math.max(0, Number(seconds) || 0);
  const minutes = Math.round(totalSeconds / 60);
  if (minutes < 60) return `${minutes}m`;
  const hours = Math.floor(minutes / 60);
  const rest = minutes % 60;
  return rest ? `${hours}h ${rest}m` : `${hours}h`;
}

function formatPlaytime(minutes) {
  if (minutes === null || minutes === undefined) return "-";
  const totalMinutes = Math.max(0, Number(minutes) || 0);
  if (totalMinutes < 60) return `${Math.round(totalMinutes)}m`;
  const hours = totalMinutes / 60;
  if (hours < 100) return `${hours.toFixed(1)}h`;
  return `${Math.round(hours)}h`;
}

function formatOptionalNumber(value) {
  return value === null || value === undefined ? "-" : String(value);
}

function formatPpm(value) {
  return value === null || value === undefined ? "-" : Number(value).toFixed(2);
}

async function openExternalUrl(url) {
  if (!tauriInvoke) {
    window.open(url, "_blank", "noopener,noreferrer");
    return;
  }
  try {
    await invoke("open_url", { url });
  } catch {
    window.open(url, "_blank", "noopener,noreferrer");
  }
}

function parseCvarNames(value) {
  const names = value
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);
  return names.length > 0 ? names : null;
}

function serverHistoryKey(rowOrAddress) {
  if (typeof rowOrAddress === "string") return rowOrAddress || "";
  return rowOrAddress?.socket || rowOrAddress?.address || "";
}

function prunePingHistory(now = Date.now()) {
  const maxAge = Math.max(PING_MINI_WINDOW_MS, now - state.appStartedAt);
  const cutoff = now - maxAge;
  for (const [key, points] of state.pingHistory.entries()) {
    const kept = points.filter((point) => point.t >= cutoff);
    if (kept.length > 0) state.pingHistory.set(key, kept);
    else state.pingHistory.delete(key);
  }
}

function recordPingHistory(rows, sampledAt = Date.now()) {
  for (const row of rows) {
    const key = serverHistoryKey(row);
    if (row?.ping_ms === null || row?.ping_ms === undefined) continue;
    const ping = Number(row?.ping_ms);
    if (!key || !Number.isFinite(ping) || ping < 0 || row.error) continue;
    const points = state.pingHistory.get(key) || [];
    const last = points[points.length - 1];
    if (last && sampledAt - last.t < 800) {
      last.ping = ping;
    } else {
      points.push({ t: sampledAt, ping });
    }
    state.pingHistory.set(key, points);
  }
  prunePingHistory(sampledAt);
}

function pingHistoryForServer(serverOrKey, windowMs = null) {
  const key = serverHistoryKey(serverOrKey);
  const points = state.pingHistory.get(key) || [];
  if (!windowMs) return points;
  const cutoff = Date.now() - windowMs;
  return points.filter((point) => point.t >= cutoff);
}

function timeAgoLabel(timestamp) {
  const diffSeconds = Math.max(0, Math.round((Date.now() - timestamp) / 1000));
  if (diffSeconds < 60) return `${diffSeconds}s`;
  const minutes = Math.round(diffSeconds / 60);
  if (minutes < 60) return `${minutes}m`;
  const hours = Math.floor(minutes / 60);
  const rest = minutes % 60;
  return rest ? `${hours}h ${rest}m` : `${hours}h`;
}

function pingStats(points) {
  if (!points.length) return null;
  const values = points.map((point) => point.ping);
  const min = Math.min(...values);
  const max = Math.max(...values);
  const avg = values.reduce((sum, value) => sum + value, 0) / values.length;
  return { min, max, avg, latest: values[values.length - 1], count: values.length };
}

function createSvgElement(name, attrs = {}) {
  const element = document.createElementNS("http://www.w3.org/2000/svg", name);
  for (const [key, value] of Object.entries(attrs)) {
    element.setAttribute(key, String(value));
  }
  return element;
}

function pingChartSegments(points, { width, height, paddingX = 0, paddingY = 0, start, end }) {
  if (points.length < 2) return [];
  const values = points.map((point) => point.ping);
  let min = Math.min(...values);
  let max = Math.max(...values);
  const spread = Math.max(16, max - min);
  min = Math.max(0, min - spread * 0.25);
  max = max + spread * 0.25;
  const innerWidth = Math.max(1, width - paddingX * 2);
  const innerHeight = Math.max(1, height - paddingY * 2);
  const span = Math.max(1, end - start);
  const sorted = [...points].sort((a, b) => a.t - b.t);
  const segments = [];
  let current = [];
  const toPoint = (point) => {
    const x = paddingX + ((point.t - start) / span) * innerWidth;
    const y = paddingY + (1 - ((point.ping - min) / Math.max(1, max - min))) * innerHeight;
    return {
      ...point,
      x: Math.max(paddingX, Math.min(width - paddingX, x)),
      y: Math.max(paddingY, Math.min(height - paddingY, y)),
    };
  };

  sorted.forEach((point, index) => {
    if (index > 0 && point.t - sorted[index - 1].t > PING_MAX_CONNECT_GAP_MS && current.length) {
      segments.push(current);
      current = [];
    }
    current.push(toPoint(point));
  });
  if (current.length) segments.push(current);
  return segments;
}

function pointsToPath(points) {
  return points
    .map((point, index) => `${index === 0 ? "M" : "L"}${point.x.toFixed(1)} ${point.y.toFixed(1)}`)
    .join(" ");
}

function createMiniPingChart(server) {
  const width = 92;
  const height = 26;
  const svg = createSvgElement("svg", {
    class: "ping-mini-chart",
    viewBox: `0 0 ${width} ${height}`,
    role: "img",
    "aria-label": "ping history",
  });
  const now = Date.now();
  const start = now - PING_MINI_WINDOW_MS;
  const points = pingHistoryForServer(server, PING_MINI_WINDOW_MS);
  svg.append(createSvgElement("rect", { x: 0, y: 0, width, height, rx: 4, class: "ping-chart-bg" }));
  if (points.length < 2) {
    svg.append(createSvgElement("line", { x1: 8, y1: height - 7, x2: width - 8, y2: height - 7, class: "ping-chart-empty-line" }));
    return svg;
  }
  const segments = pingChartSegments(points, { width, height, paddingX: 5, paddingY: 4, start, end: now });
  for (const segment of segments) {
    if (segment.length >= 2) {
      svg.append(createSvgElement("path", { d: pointsToPath(segment), class: "ping-chart-line" }));
    } else {
      const point = segment[0];
      svg.append(createSvgElement("circle", { cx: point.x.toFixed(1), cy: point.y.toFixed(1), r: 1.8, class: "ping-chart-dot muted" }));
    }
  }
  const flattened = segments.flat();
  const latest = flattened[flattened.length - 1];
  if (latest) {
    svg.append(createSvgElement("circle", { cx: latest.x.toFixed(1), cy: latest.y.toFixed(1), r: 2.1, class: "ping-chart-dot" }));
  }
  return svg;
}

function createDetailPingChart(serverKey) {
  const width = 560;
  const height = 260;
  const svg = createSvgElement("svg", {
    class: "ping-detail-chart",
    viewBox: `0 0 ${width} ${height}`,
    role: "img",
    "aria-label": "server ping history",
  });
  const now = Date.now();
  const start = Math.min(state.appStartedAt, now - PING_DETAIL_MIN_WINDOW_MS);
  const points = pingHistoryForServer(serverKey).filter((point) => point.t >= start);
  const chartLeft = 48;
  const chartRight = 14;
  const chartTop = 18;
  const chartBottom = 34;
  const chartWidth = width - chartLeft - chartRight;
  const chartHeight = height - chartTop - chartBottom;

  svg.append(createSvgElement("rect", { x: 0, y: 0, width, height, rx: 7, class: "ping-detail-bg" }));
  for (let i = 0; i <= 4; i += 1) {
    const y = chartTop + (chartHeight / 4) * i;
    svg.append(createSvgElement("line", { x1: chartLeft, y1: y.toFixed(1), x2: width - chartRight, y2: y.toFixed(1), class: "ping-grid-line" }));
  }
  for (let i = 0; i <= 4; i += 1) {
    const x = chartLeft + (chartWidth / 4) * i;
    svg.append(createSvgElement("line", { x1: x.toFixed(1), y1: chartTop, x2: x.toFixed(1), y2: chartTop + chartHeight, class: "ping-grid-line vertical" }));
  }

  if (points.length < 2) {
    const text = createSvgElement("text", { x: width / 2, y: height / 2, "text-anchor": "middle", class: "ping-empty-text" });
    text.textContent = t("pingNoHistory");
    svg.append(text);
    return svg;
  }

  const values = points.map((point) => point.ping);
  let min = Math.min(...values);
  let max = Math.max(...values);
  const spread = Math.max(16, max - min);
  min = Math.max(0, Math.floor(min - spread * 0.25));
  max = Math.ceil(max + spread * 0.25);
  const yLabels = [max, Math.round((max + min) / 2), min];
  yLabels.forEach((value, index) => {
    const y = index === 0 ? chartTop + 4 : index === 1 ? chartTop + chartHeight / 2 + 4 : chartTop + chartHeight + 4;
    const text = createSvgElement("text", { x: 10, y: y.toFixed(1), class: "ping-axis-text" });
    text.textContent = `${value}ms`;
    svg.append(text);
  });

  const startText = createSvgElement("text", { x: chartLeft, y: height - 12, class: "ping-axis-text" });
  startText.textContent = `-${timeAgoLabel(start)}`;
  svg.append(startText);
  const endText = createSvgElement("text", { x: width - chartRight, y: height - 12, "text-anchor": "end", class: "ping-axis-text" });
  endText.textContent = "now";
  svg.append(endText);

  const segments = pingChartSegments(points, {
    width,
    height,
    paddingX: chartLeft,
    paddingY: chartTop,
    start,
    end: now,
  }).map((segment) => segment.map((point) => {
    const x = chartLeft + ((point.t - start) / Math.max(1, now - start)) * chartWidth;
    const y = chartTop + (1 - ((point.ping - min) / Math.max(1, max - min))) * chartHeight;
    return {
      ...point,
      x: Math.max(chartLeft, Math.min(width - chartRight, x)),
      y: Math.max(chartTop, Math.min(chartTop + chartHeight, y)),
    };
  }));

  for (const segment of segments) {
    if (segment.length >= 2) {
      const fillPath = `${pointsToPath(segment)} L${segment[segment.length - 1].x.toFixed(1)} ${chartTop + chartHeight} L${segment[0].x.toFixed(1)} ${chartTop + chartHeight} Z`;
      svg.append(createSvgElement("path", { d: fillPath, class: "ping-detail-fill" }));
      svg.append(createSvgElement("path", { d: pointsToPath(segment), class: "ping-detail-line" }));
    } else {
      const point = segment[0];
      svg.append(createSvgElement("circle", { cx: point.x.toFixed(1), cy: point.y.toFixed(1), r: 2.8, class: "ping-detail-dot muted" }));
    }
  }
  const flattened = segments.flat();
  const latest = flattened[flattened.length - 1];
  if (latest) {
    svg.append(createSvgElement("circle", { cx: latest.x.toFixed(1), cy: latest.y.toFixed(1), r: 4, class: "ping-detail-dot" }));
  }
  return svg;
}

function renderPingHistoryPanel() {
  const root = $("#insPing");
  if (!root) return;
  root.replaceChildren();
  const key = state.selectedSocket || state.selectedAddress;
  const points = pingHistoryForServer(key);
  const stats = pingStats(points);
  const summary = document.createElement("div");
  summary.className = "ping-history-summary";
  const items = [
    [t("pingLatest"), stats ? `${Math.round(stats.latest)}ms` : "-"],
    [t("pingAverage"), stats ? `${Math.round(stats.avg)}ms` : "-"],
    [t("pingMinMax"), stats ? `${Math.round(stats.min)} / ${Math.round(stats.max)}ms` : "-"],
    [t("pingSamples"), stats ? String(stats.count) : "0"],
  ];
  for (const [label, value] of items) {
    const item = document.createElement("div");
    const labelNode = document.createElement("span");
    labelNode.textContent = label;
    const valueNode = document.createElement("strong");
    valueNode.textContent = value;
    item.append(labelNode, valueNode);
    summary.append(item);
  }
  const note = document.createElement("p");
  note.className = "ping-history-note";
  note.textContent = t("pingHistoryNote");
  root.append(summary, createDetailPingChart(key), note);
}

function tagClassName(tag) {
  const normalized = String(tag).toLowerCase();
  if (normalized === "anne") return "server-tag anne-tag";
  if (normalized.includes("confogl") || normalized.includes("zonemod")) return "server-tag mode-tag";
  return "server-tag";
}

function renderServerTags(server) {
  const tags = Array.isArray(server.tags) ? [...server.tags] : [];
  if (server.is_anne && !tags.some((tag) => String(tag).toLowerCase() === "anne")) {
    tags.unshift("Anne");
  }
  if (tags.length === 0) return null;

  const wrap = document.createElement("div");
  wrap.className = "server-tags";
  wrap.title = server.sv_tags ? `sv_tags: ${server.sv_tags}` : "";
  for (const tag of tags.slice(0, 6)) {
    const badge = document.createElement("span");
    badge.className = tagClassName(tag);
    badge.textContent = tag;
    wrap.append(badge);
  }
  if (tags.length > 6) {
    const more = document.createElement("span");
    more.className = "server-tag";
    more.textContent = `+${tags.length - 6}`;
    wrap.append(more);
  }
  return wrap;
}

async function saveGuiSettings(partial) {
  const req = {
    config_path: state.configPath || null,
    language: null,
    update_auto_check: null,
    anne_stats: null,
    theme_mode: null,
    accent_color: null,
    auto_refresh_empty_secs: null,
    auto_refresh_active_secs: null,
    auto_refresh_selected_secs: null,
    time_zone: null,
    ...partial,
  };
  const lists = await invoke("save_gui_settings", { req });
  if (lists) {
    state.lists = lists;
    state.configPath = lists.config_path;
    state.apiBaseUrl = lists.api_base_url;
    state.apiToken = lists.api_token || state.apiToken;
    state.autoCheckUpdate = lists.update_auto_check !== false;
    state.anneStatsEnabled = lists.anne_stats !== false;
    state.themeMode = normalizeThemeMode(lists.theme_mode);
    state.accentColor = isHexColor(lists.accent_color) ? lists.accent_color : state.accentColor;
    state.autoRefreshEmptySecs = clampRefreshSeconds(lists.auto_refresh_empty_secs, 120, 15);
    state.autoRefreshActiveSecs = clampRefreshSeconds(lists.auto_refresh_active_secs, 30, 5);
    state.autoRefreshSelectedSecs = clampRefreshSeconds(lists.auto_refresh_selected_secs, SELECTED_REFRESH_DEFAULT_SECS, 3);
    state.timeZone = normalizeTimeZone(lists.time_zone);
    state.rconPasswords = lists.rcon_passwords || {};
    applyTheme();
    syncAutoRefreshInputs();
    syncTimeZoneInput();
    syncConfigPathUI();
    syncRconPasswordControls();
  }
}

async function saveRconPassword(password, address = state.selectedAddress) {
  if (!address) return;
  const lists = await invoke("save_rcon_password", {
    req: {
      config_path: state.configPath || null,
      address,
      password: password ? password : null,
    },
  });
  if (lists) {
    state.lists = lists;
    state.configPath = lists.config_path;
    state.rconPasswords = lists.rcon_passwords || {};
    syncConfigPathUI();
    syncRconPasswordControls(address);
  }
}

function setTab(tab) {
  state.tab = tab;
  $$(".nav-item").forEach((button) => {
    button.classList.toggle("active", button.dataset.tab === tab);
  });
  $$(".view").forEach(v => v.classList.remove("active"));
  $(`#${tab}View`).classList.add("active");
  
  const titleMap = {
    servers: "navServers",
    globalPlayers: "navGlobalPlayers",
    broadcast: "navBroadcast",
    subscriptions: "navSubscriptions",
    settings: "navSettings"
  };
  $("#viewTitle").textContent = t(titleMap[tab]);
  $("#refreshBtn").style.display = (tab === "servers" || tab === "globalPlayers" || tab === "broadcast") ? "" : "none";

  if (tab === "globalPlayers") loadGlobalPlayers();
  if (tab === "broadcast") loadBroadcastHistory({ showLoading: state.broadcastHistory.length === 0 });
}

async function loadConfigLists() {
  try {
    state.lists = await invoke("load_config_lists", { path: state.configPath || null });
    if (!state.lists) return;
    state.configPath = state.lists.config_path;
    state.apiBaseUrl = state.lists.api_base_url;
    state.apiToken = state.lists.api_token || localStorage.getItem("apiToken") || null;
    state.autoCheckUpdate = state.lists.update_auto_check !== false;
    state.anneStatsEnabled = state.lists.anne_stats !== false;
    state.rconPasswords = state.lists.rcon_passwords || {};
    state.themeMode = normalizeThemeMode(state.lists.theme_mode);
    state.accentColor = isHexColor(state.lists.accent_color) ? state.lists.accent_color : "#0f766e";
    state.autoRefreshEmptySecs = clampRefreshSeconds(state.lists.auto_refresh_empty_secs, 120, 15);
    state.autoRefreshActiveSecs = clampRefreshSeconds(state.lists.auto_refresh_active_secs, 30, 5);
    state.autoRefreshSelectedSecs = clampRefreshSeconds(state.lists.auto_refresh_selected_secs, SELECTED_REFRESH_DEFAULT_SECS, 3);
    state.timeZone = normalizeTimeZone(state.lists.time_zone);
    const locale = uiLocaleFromConfig(state.lists.gui_language);
    setLocale(locale);
    applyTheme();
    syncConfigPathUI();
    $("#apiBaseUrlInput").value = state.apiBaseUrl;
    $("#languageSelect").value = locale;
    $("#autoUpdateInput").checked = state.autoCheckUpdate;
    $("#anneStatsInput").checked = state.anneStatsEnabled;
    syncAutoRefreshInputs();
    syncTimeZoneInput();
    syncRconPasswordControls();
    renderSubscriptions();
    renderManualServers();
    
    if (state.lists.api_token) {
      localStorage.setItem("apiToken", state.lists.api_token);
    }
    if (state.apiToken && state.apiBaseUrl) {
      try {
        const user = await invoke("api_me", { baseUrl: state.apiBaseUrl, token: state.apiToken });
        state.steamUser = user;
        updateSteamUserUI();
      } catch (err) {
        state.apiToken = null;
        localStorage.removeItem("apiToken");
        updateSteamUserUI();
      }
    } else {
      updateSteamUserUI();
    }
  } catch (err) {
    console.error(err);
  }
}

function rowMatchesSearch(row, search) {
  if (!search) return true;
  const haystack = [
    row.name,
    row.map,
    row.address,
    row.socket,
    row.group_label,
    row.status,
    row.sv_tags,
    ...(row.tags || []),
    ...(row.groups || []),
  ].join(" ").toLowerCase();
  return haystack.includes(search);
}

function baseFilteredRows() {
  const search = state.search.trim().toLowerCase();
  return [...state.allRows].filter((row) => {
    if (state.hideTimeout && row.error) return false;
    if (state.onlyWithPlayers && !(row.players > 0)) return false;
    if (state.onlyEmpty && (row.error || row.players !== 0)) return false;
    return rowMatchesSearch(row, search);
  });
}

function applyServerFiltersAndRender() {
  let rows = baseFilteredRows();
  const groups = summarizeRows(rows).groups;
  if (state.group) {
    rows = rows.filter((row) => (row.groups || []).includes(state.group));
  }
  state.rows = rows;
  sortRowsClientSide();
  renderMetrics(summarizeRows(state.rows));
  renderGroups(groups);
  renderServerRows();
  if (state.tab === "servers") {
    setStatus(`${t("navServers")} : ${state.rows.length}`);
  }
}

function serverRowKey(row) {
  return row?.socket || row?.address || "";
}

function mergeServerRows(nextRows) {
  const nextByKey = new Map(nextRows.map((row) => [serverRowKey(row), row]));
  const merged = state.allRows.map((row) => {
    const next = nextByKey.get(serverRowKey(row));
    if (!next) return row;
    return {
      ...row,
      ...next,
      address: row.address || next.address,
      socket: row.socket || next.socket,
      groups: Array.isArray(row.groups) && row.groups.length ? row.groups : next.groups,
      group_label: row.group_label || next.group_label,
      steam_url: row.steam_url || next.steam_url,
    };
  });
  const existing = new Set(merged.map(serverRowKey));
  for (const row of nextRows) {
    if (!existing.has(serverRowKey(row))) merged.push(row);
  }
  return merged;
}

function mergeSilentRefreshRows(nextRows, partial = false) {
  const rows = partial ? mergeServerRows(nextRows) : nextRows;
  const previousRows = new Map(state.allRows.map((row) => [serverRowKey(row), row]));
  return rows.map((row) => {
    const key = serverRowKey(row);
    const previous = key ? previousRows.get(key) : null;
    if (!row.error || !previous || previous.error) return row;
    return {
      ...previous,
      address: row.address,
      socket: row.socket,
      groups: row.groups,
      group_label: row.group_label,
      steam_url: row.steam_url,
      status: previous.status || row.status,
    };
  });
}

async function refreshServers({ silent = false, sockets = null } = {}) {
  state.refreshInFlight = true;
  state.busy = true;
  const seq = ++state.refreshSeq;
  if (!silent) {
    setRefreshButtonBusy(true);
    setStatus(t("statusRefreshing"));
  }
  try {
    const payload = await invoke("refresh_servers", {
      query: {
        config_path: state.configPath || null,
        limit: 300,
        sockets,
      },
    });
    if (!payload) return; // For mock safety
    if (seq !== state.refreshSeq) return;
    state.configPath = payload.config_path;
    const nextRows = Array.isArray(payload.rows) ? payload.rows : [];
    recordPingHistory(nextRows);
    state.allRows = silent ? mergeSilentRefreshRows(nextRows, Array.isArray(sockets)) : nextRows;
    if (!silent) {
      const now = Date.now();
      state.lastFullRefreshAt = now;
      state.lastActiveRefreshAt = now;
      state.lastSelectedRefreshAt = now;
    }
    syncConfigPathUI();
    applyServerFiltersAndRender();
    if (state.inspectorOpen && state.inspectorTab === "ping") {
      renderPingHistoryPanel();
    }
  } catch (error) {
    if (!silent) setStatus(`Error: ${error}`);
  } finally {
    if (seq === state.refreshSeq) {
      state.refreshInFlight = false;
      state.busy = false;
      if (!silent) setRefreshButtonBusy(false);
    }
  }
}

function activeServerSockets() {
  return state.allRows
    .filter((row) => !row.error && (row.players || 0) > 0)
    .map(serverRowKey)
    .filter(Boolean);
}

function selectedServerSocket() {
  const selected = state.selectedSocket || state.selectedAddress;
  if (!selected) return null;
  return state.allRows.some((row) => serverRowKey(row) === selected)
    ? selected
    : null;
}

function startAutoRefreshLoop() {
  if (state.autoRefreshTimer) clearInterval(state.autoRefreshTimer);
  state.lastFullRefreshAt = Date.now();
  state.lastActiveRefreshAt = Date.now();
  state.lastSelectedRefreshAt = Date.now();
  state.autoRefreshTimer = setInterval(() => {
    if (state.busy) return;
    const now = Date.now();
    const selected = selectedServerSocket();
    const selectedDue = selected && now - state.lastSelectedRefreshAt >= state.autoRefreshSelectedSecs * 1000;
    const activeDue = now - state.lastActiveRefreshAt >= state.autoRefreshActiveSecs * 1000;
    const fullDue = now - state.lastFullRefreshAt >= state.autoRefreshEmptySecs * 1000;

    if (fullDue) {
      state.lastFullRefreshAt = now;
      state.lastActiveRefreshAt = now;
      state.lastSelectedRefreshAt = now;
      refreshServers({ silent: true });
      return;
    }

    if (activeDue) {
      const sockets = activeServerSockets();
      if (selectedDue && selected && !sockets.includes(selected)) sockets.push(selected);
      state.lastActiveRefreshAt = now;
      if (sockets.length > 0) {
        if (selectedDue) state.lastSelectedRefreshAt = now;
        refreshServers({ silent: true, sockets });
        return;
      }
    }

    if (selectedDue) {
      state.lastSelectedRefreshAt = now;
      refreshServers({ silent: true, sockets: [selected] });
    }
  }, 1000);
}

function sortRowsClientSide() {
  state.rows.sort((a, b) => {
    let cmp = 0;
    if (state.sortKey === "name") cmp = naturalCompare(a.name, b.name);
    else if (state.sortKey === "address") cmp = naturalCompare(a.address, b.address);
    else if (state.sortKey === "players") cmp = (a.players || 0) - (b.players || 0);
    else if (state.sortKey === "ping") cmp = (a.ping_ms || 9999) - (b.ping_ms || 9999);
    else if (state.sortKey === "map") cmp = naturalCompare(a.map, b.map);
    else if (state.sortKey === "group") cmp = naturalCompare(a.group_label, b.group_label);
    
    return state.sortDesc ? -cmp : cmp;
  });
}

function handleSortClick(key) {
  if (state.sortKey === key) {
    state.sortDesc = !state.sortDesc;
  } else {
    state.sortKey = key;
    state.sortDesc = (key === "players");
  }
  sortRowsClientSide();
  renderServerRows();
}

function renderMetrics(summary) {
  $("#metricTotal").textContent = summary.total;
  $("#metricOnline").textContent = summary.online;
  $("#metricPlayers").textContent = summary.players;
}

function renderGroups(groups) {
  const root = $("#groupTabs");
  root.replaceChildren();
  const all = document.createElement("button");
  all.type = "button";
  all.className = `group-chip ${!state.group ? "active" : ""}`;
  all.textContent = t("allServers");
  all.addEventListener("click", () => {
    state.group = null;
    applyServerFiltersAndRender();
  });
  root.append(all);

  for (const [name, count] of groups) {
    const button = document.createElement("button");
    button.type = "button";
    button.className = `group-chip ${state.group === name ? "active" : ""}`;
    button.textContent = `${name} ${count}`;
    button.addEventListener("click", () => {
      state.group = name;
      applyServerFiltersAndRender();
    });
    root.append(button);
  }
}

function renderServerRows() {
  const tbody = $("#serverRows");
  tbody.replaceChildren();
  if (state.rows.length === 0) {
    const row = document.createElement("tr");
    const cell = document.createElement("td");
    cell.colSpan = 8;
    cell.className = "empty";
    cell.textContent = t("noServers");
    row.append(cell);
    tbody.append(row);
    return;
  }

  for (const server of state.rows) {
    const row = document.createElement("tr");
    if (state.selectedAddress === server.address) {
      row.classList.add("selected");
    }

    const nameCell = document.createElement("td");
    const name = document.createElement("span");
    name.className = "server-name";
    name.title = server.name;
    name.textContent = server.name;
    const status = document.createElement("span");
    status.className = `server-status ${
      server.error ? "timeout" : server.players > 0 ? "" : "empty"
    }`;
    status.textContent = server.error ? t("statusTimeout") : server.players > 0 ? t("statusActive") : t("statusEmpty");
    nameCell.append(name, status);
    const tags = renderServerTags(server);
    if (tags) nameCell.append(tags);

    const addressCell = document.createElement("td");
    addressCell.className = "mono";
    addressCell.textContent = server.address;

    const playersCell = document.createElement("td");
    playersCell.textContent = `${server.players}/${server.max_players}`;

    const pingCell = document.createElement("td");
    const pingWrap = document.createElement("div");
    pingWrap.className = "ping-cell";
    const pingText = document.createElement("span");
    pingText.textContent = server.ping_ms === null || server.ping_ms === undefined ? "-" : `${server.ping_ms}ms`;
    pingWrap.append(pingText, createMiniPingChart(server));
    pingCell.append(pingWrap);

    const mapCell = document.createElement("td");
    mapCell.textContent = server.map || "-";

    const groupCell = document.createElement("td");
    groupCell.textContent = server.group_label || "-";

    const vacCell = document.createElement("td");
    vacCell.textContent = boolText(server.vac);

    const actionCell = document.createElement("td");
    const connect = document.createElement("button");
    connect.type = "button";
    connect.textContent = t("btnConnect");
    connect.addEventListener("click", (e) => {
      e.stopPropagation();
      openSteam(server.socket);
    });
    actionCell.append(connect);

    row.append(
      nameCell,
      addressCell,
      playersCell,
      pingCell,
      mapCell,
      groupCell,
      vacCell,
      actionCell,
    );

    row.addEventListener("click", () => {
      state.selectedAddress = server.address;
      state.selectedSocket = server.socket || server.address;
      state.lastSelectedRefreshAt = 0;
      openInspector(server.name, server.address);
      renderServerRows(); // re-render to update selected class
    });

    tbody.append(row);
  }
}

// ----- Inspector Logic -----

function openInspector(name, address) {
  state.inspectorOpen = true;
  state.selectedAddress = address;
  $("#inspectorPanel").style.display = "flex";
  $("#inspectorTitle").textContent = name;
  syncRconPasswordControls(address);
  $("#insPlayersRows").replaceChildren();
  appendEmptyRow($("#insPlayersRows"), 7, t("statusRefreshing"));
  $("#insCvarRows").replaceChildren();
  renderPingHistoryPanel();
  refreshInspector();
}

function closeInspector() {
  state.inspectorOpen = false;
  state.selectedAddress = null;
  state.selectedSocket = null;
  $("#inspectorPanel").style.display = "none";
  renderServerRows();
}

function setInspectorTab(tab) {
  state.inspectorTab = tab;
  $$(".ins-tab").forEach(b => b.classList.toggle("active", b.dataset.ins === tab));
  $$(".ins-view").forEach(v => v.classList.remove("active"));
  $(`#ins${tab.charAt(0).toUpperCase() + tab.slice(1)}`).classList.add("active");
  $("#rconAuthControls").hidden = !(tab === "rcon" || tab === "cvar");
  refreshInspector();
}

async function refreshInspector() {
  if (!state.inspectorOpen || !state.selectedAddress) return;
  const address = state.selectedAddress;
  
  if (state.inspectorTab === "players") {
    const tbody = $("#insPlayersRows");
    appendEmptyRow(tbody, 7, t("statusRefreshing"));
    try {
      const players = await invoke("query_players", { configPath: state.configPath, address });
      if (state.selectedAddress !== address || state.inspectorTab !== "players") return;
      if (!players || players.length === 0) {
        appendEmptyRow(tbody, 7, t("noPlayers"));
        return;
      }
      tbody.replaceChildren();
      for (const p of players) {
        const tr = document.createElement("tr");
        appendPlayerNameCell(tr, p);
        appendTextCell(tr, p.score);
        appendTextCell(tr, formatDuration(p.duration_secs));
        appendTextCell(tr, formatOptionalNumber(p.points));
        appendTextCell(tr, formatPlaytime(p.playtime_mins));
        appendTextCell(tr, formatPpm(p.ppm));
        appendTextCell(tr, formatOptionalNumber(p.quarter_points));
        tbody.append(tr);
      }
    } catch (e) {
      if (state.selectedAddress !== address || state.inspectorTab !== "players") return;
      appendEmptyRow(tbody, 7, String(e));
    }
  } else if (state.inspectorTab === "ping") {
    renderPingHistoryPanel();
  } else if (state.inspectorTab === "cvar") {
    const tbody = $("#insCvarRows");
    try {
      const password = $("#rconPassword").value.trim() || null;
      const names = parseCvarNames($("#cvarNames").value);
      const cvars = await invoke("read_cvars", {
        req: { config_path: state.configPath, address, password, names, timeout_ms: 2500 }
      });
      if (state.selectedAddress !== address || state.inspectorTab !== "cvar") return;
      if (!cvars || cvars.length === 0) {
        appendEmptyRow(tbody, 2, t("emptyResult"));
        return;
      }
      tbody.replaceChildren();
      for (const c of cvars) {
        const tr = document.createElement("tr");
        appendTextCell(tr, c.name, "mono");
        appendTextCell(tr, c.value);
        tbody.append(tr);
      }
    } catch (e) {
      if (state.selectedAddress !== address || state.inspectorTab !== "cvar") return;
      appendEmptyRow(tbody, 2, String(e));
    }
  } else if (state.inspectorTab === "network") {
    try {
      // Assuming socket address is 'ip:port'
      const ip = state.selectedSocket ? state.selectedSocket.split(":")[0] : address.split(":")[0];
      const net = await invoke("fetch_network_info", { address, ip });
      if (state.selectedAddress !== address || state.inspectorTab !== "network") return;
      $("#netIp").textContent = net.ip;
      $("#netCountry").textContent = [net.country, net.region, net.city].filter(Boolean).join(" - ") || "-";
      $("#netIsp").textContent = net.isp;
      $("#netOrg").textContent = net.org || "-";
      $("#netAsn").textContent = net.asn || "-";
    } catch (e) {
      console.error(e);
    }
  }
}

async function sendRcon() {
  const password = $("#rconPassword").value.trim();
  const command = $("#rconCommand").value;
  if (!password || !command || !state.selectedAddress) return;
  
  const term = $("#rconTerminal");
  term.textContent += `\n> ${command}\n`;
  try {
    if ($("#saveRconPasswordInput").checked) {
      await saveRconPassword(password, state.selectedAddress);
    }
    const res = await invoke("run_rcon", { req: {
      config_path: state.configPath,
      address: state.selectedAddress,
      password,
      command,
      timeout_ms: 5000
    }});
    term.textContent += res + "\n";
  } catch (e) {
    term.textContent += `Error: ${e}\n`;
  }
  term.scrollTop = term.scrollHeight;
  $("#rconCommand").value = "";
}


// ----- Subscriptions & Manual Servers -----

function renderSubscriptions() {
  const list = $("#subscriptionList");
  list.replaceChildren();
  const items = state.lists?.sourcebans ?? [];
  if (items.length === 0) {
    const empty = document.createElement("div");
    empty.className = "empty";
    empty.textContent = t("noSubscriptions");
    list.append(empty);
    return;
  }
  for (const item of items) {
    const button = document.createElement("button");
    button.type = "button";
    button.className = `subscription-item ${
      state.selectedSourcebans === item.index ? "active" : ""
    }`;
    const title = document.createElement("strong");
    title.textContent = item.name;
    const detail = document.createElement("span");
    detail.textContent = item.source_label;
    button.append(title, detail);
    button.addEventListener("click", () => selectSubscription(item));
    list.append(button);
  }
}

function renderManualServers() {
  const list = $("#manualList");
  list.replaceChildren();
  const items = state.lists?.manual_servers ?? [];
  if (items.length === 0) {
    const empty = document.createElement("div");
    empty.className = "empty";
    empty.textContent = t("noManualServers");
    list.append(empty);
    return;
  }
  for (const item of items) {
    const row = document.createElement("div");
    row.className = "manual-item";
    
    const info = document.createElement("div");
    const title = document.createElement("strong");
    title.textContent = item.server;
    const detail = document.createElement("span");
    detail.textContent = item.group;
    info.append(title, detail);
    
    const delBtn = document.createElement("button");
    delBtn.className = "danger";
    delBtn.textContent = t("btnDelete");
    delBtn.addEventListener("click", async () => {
      try {
        state.lists = await invoke("delete_manual_server", { req: {
          config_path: state.configPath,
          group: item.group,
          server: item.server
        }});
        renderManualServers();
        refreshServers({ silent: true });
      } catch (e) {
        setStatus(`${t("deleteFailed")}: ${e}`);
      }
    });
    
    row.style.display = "flex";
    row.style.justifyContent = "space-between";
    row.style.alignItems = "center";
    
    row.append(info, delBtn);
    list.append(row);
  }
}

function selectSubscription(item) {
  state.selectedSourcebans = item.index;
  $("#subscriptionEditorTitle").textContent = t("editSubscription");
  $("#subscriptionNameInput").value = item.name;
  $("#subscriptionUrlInput").value = item.url;
  $("#subscriptionTextInput").value = "";
  $("#deleteSubscriptionBtn").disabled = false;
  renderSubscriptions();
}

function clearSubscriptionEditor() {
  state.selectedSourcebans = null;
  $("#subscriptionEditorTitle").textContent = t("newSubscription");
  $("#subscriptionNameInput").value = t("defaultGroup");
  $("#subscriptionUrlInput").value = "";
  $("#subscriptionTextInput").value = "";
  $("#deleteSubscriptionBtn").disabled = true;
  renderSubscriptions();
}

async function saveSubscription() {
  const input = {
    config_path: state.configPath || null,
    index: state.selectedSourcebans,
    name: $("#subscriptionNameInput").value.trim(),
    url: $("#subscriptionUrlInput").value.trim(),
    text: $("#subscriptionTextInput").value,
  };
  if (!input.name) return;
  try {
    state.lists = await invoke("save_sourcebans", { input });
    state.configPath = state.lists.config_path;
    $("#subscriptionTextInput").value = "";
    renderSubscriptions();
    setStatus(t("statusSaved"));
    refreshServers({ silent: true });
  } catch (error) {
    setStatus(`${t("saveFailed")}: ${error}`);
  }
}

async function deleteSubscription() {
  if (state.selectedSourcebans === null) return;
  try {
    state.lists = await invoke("delete_sourcebans", {
      path: state.configPath || null,
      index: state.selectedSourcebans,
    });
    clearSubscriptionEditor();
    renderSubscriptions();
    setStatus(t("statusDeleted"));
    refreshServers({ silent: true });
  } catch (error) {
    setStatus(`${t("deleteFailed")}: ${error}`);
  }
}

async function refreshSubscriptions() {
  const button = $("#refreshSubscriptionsBtn");
  button.disabled = true;
  button.textContent = t("refreshingWebSubscriptions");
  setStatus(t("refreshingWebSubscriptions"));
  try {
    state.lists = await invoke("refresh_sourcebans", { path: state.configPath || null });
    state.configPath = state.lists.config_path;
    syncConfigPathUI();
    renderSubscriptions();
    setStatus(t("webSubscriptionsRefreshed"));
    await refreshServers({ silent: true });
  } catch (error) {
    setStatus(`${t("refreshWebSubscriptionsFailed")}: ${error}`);
  } finally {
    button.disabled = false;
    button.textContent = t("refreshWebSubscriptions");
  }
}

async function addManualServer() {
  const group = $("#manualGroupInput").value.trim();
  const server = $("#manualServerInput").value.trim();
  if (!group || !server) return;
  try {
    state.lists = await invoke("add_manual_server", {
      path: state.configPath || null,
      group,
      server,
    });
    $("#manualServerInput").value = "";
    renderManualServers();
    setStatus(t("statusAdded"));
    refreshServers({ silent: true });
  } catch (error) {
    setStatus(`${t("addFailed")}: ${error}`);
  }
}

// ----- Steam Auth & API -----

async function startSteamLogin() {
  const baseUrl = $("#apiBaseUrlInput").value.trim();
  if (!baseUrl) return;
  state.apiBaseUrl = baseUrl;
  
  try {
    const start = await invoke("steam_login_start", { baseUrl });
    await invoke("save_api_config", { req: { config_path: state.configPath, base_url: baseUrl, token: state.apiToken } });
    $("#steamLoginModal").style.display = "block";
    $("#steamLoginUrl").href = start.verification_url;
    $("#steamLoginUrl").textContent = start.verification_url;
    $("#steamLoginCode").textContent = start.user_code;
    window.open(start.verification_url, "_blank");
    
    pollSteamLogin(baseUrl, start.device_code, start.expires_in, start.interval);
  } catch (e) {
    $("#apiStatusMessage").textContent = `${t("loginStartFailed")}: ${e}`;
  }
}

async function pollSteamLogin(baseUrl, deviceCode, expires, interval) {
  const endTime = Date.now() + (expires * 1000);
  
  while (Date.now() < endTime) {
    await new Promise(r => setTimeout(r, interval * 1000));
    if ($("#steamLoginModal").style.display === "none") break; // Cancelled
    
    try {
      const res = await invoke("steam_login_poll", { req: { base_url: baseUrl, device_code: deviceCode }});
      if (res) { // Success
        state.apiToken = res.token;
        state.steamUser = {
          steam_id: res.steam_id,
          steam_name: res.steam_name,
          avatar: res.avatar,
          is_admin: res.is_admin
        };
        localStorage.setItem("apiToken", res.token);
        $("#steamLoginModal").style.display = "none";
        updateSteamUserUI();
        
        await invoke("save_api_config", { req: { config_path: state.configPath, base_url: baseUrl, token: res.token } });
        return;
      }
    } catch (e) {
      $("#apiStatusMessage").textContent = `${t("pollFailed")}: ${e}`;
      break;
    }
  }
  $("#steamLoginModal").style.display = "none";
}

async function logoutApi() {
  if (!state.apiToken) return;
  try {
    await invoke("api_logout", { baseUrl: state.apiBaseUrl, token: state.apiToken });
  } catch (e) {} // ignore
  
  state.apiToken = null;
  state.steamUser = null;
  localStorage.removeItem("apiToken");
  await invoke("save_api_config", { req: { config_path: state.configPath, base_url: state.apiBaseUrl, token: null } });
  updateSteamUserUI();
}

function updateSteamUserUI() {
  if (state.steamUser) {
    $("#steamUserInfo").style.display = "flex";
    $("#steamAvatar").src = state.steamUser.avatar;
    $("#steamName").textContent = state.steamUser.steam_name;
    $("#steamLoginBtn").style.display = "none";
    $("#steamLogoutBtn").style.display = "inline-block";
    $("#apiStatusMessage").textContent = t("loggedIn");
  } else {
    $("#steamUserInfo").style.display = "none";
    $("#steamLoginBtn").style.display = "inline-block";
    $("#steamLogoutBtn").style.display = "none";
    $("#apiStatusMessage").textContent = "";
  }
}

// ----- Global Players -----

async function loadGlobalPlayers() {
  const tbody = $("#globalPlayerRows");
  try {
    const players = await invoke("load_global_players", {
      baseUrl: state.apiBaseUrl,
      token: state.apiToken || "",
      configPath: state.configPath
    });
    if (!players || players.length === 0) {
      appendEmptyRow(tbody, 9, t("noPlayers"));
      return;
    }
    tbody.replaceChildren();
    for (const p of players) {
      const tr = document.createElement("tr");
      appendPlayerNameCell(tr, p);
      appendTextCell(tr, p.server_name);
      appendTextCell(tr, p.score);
      appendTextCell(tr, formatDuration(p.duration_secs));
      appendTextCell(tr, formatOptionalNumber(p.points));
      appendTextCell(tr, formatPlaytime(p.playtime_mins));
      appendTextCell(tr, formatPpm(p.ppm));
      appendTextCell(tr, formatOptionalNumber(p.quarter_points));
      const actionCell = document.createElement("td");
      const connect = document.createElement("button");
      connect.type = "button";
      connect.textContent = t("btnConnect");
      connect.addEventListener("click", () => openSteam(p.server_address));
      actionCell.append(connect);
      tr.append(actionCell);
      tbody.append(tr);
    }
  } catch (e) {
    appendEmptyRow(tbody, 9, String(e));
  }
}

// ----- Broadcast -----

async function sendBroadcastMessage() {
  if (state.broadcastSending) return;
  const input = $("#broadcastInput");
  const sendButton = $("#broadcastSendBtn");
  const msg = input.value.trim();
  if (!msg) return;
  if (!state.apiToken) {
    setStatus(t("loginRequired"));
    return;
  }
  input.value = "";
  state.broadcastSending = true;
  sendButton.disabled = true;
  setStatus(t("broadcastSending"));
  try {
    const res = await invoke("send_broadcast", { req: { base_url: state.apiBaseUrl, token: state.apiToken, message: msg } });
    setStatus(`${t("statusBroadcastSent")}: ${res}`);
    await loadBroadcastHistory({ showLoading: false, force: true });
  } catch (e) {
    setStatus(`${t("broadcastSendFailed")}: ${e}`);
  } finally {
    state.broadcastSending = false;
    sendButton.disabled = false;
  }
}

function renderBroadcastHistory(messages = state.broadcastHistory) {
  const tbody = $("#broadcastRows");
  if (!messages || messages.length === 0) {
    appendEmptyRow(tbody, 3, t("emptyResult"));
    return;
  }
  tbody.replaceChildren();
  for (const m of messages) {
    const tr = document.createElement("tr");
    appendTextCell(tr, m.sent_at_display || m.sent_at);
    appendTextCell(tr, m.sender_name);
    appendTextCell(tr, m.message);
    tbody.append(tr);
  }
}

async function loadBroadcastHistory({ showLoading = true, force = false } = {}) {
  const tbody = $("#broadcastRows");
  if (state.broadcastHistoryInFlight && !force) return;
  if (!state.apiBaseUrl) {
    if (showLoading) appendEmptyRow(tbody, 3, t("configNotSet"));
    return;
  }
  state.broadcastHistoryInFlight = true;
  try {
    if (showLoading && state.broadcastHistory.length === 0) {
      appendEmptyRow(tbody, 3, t("broadcastLoading"));
    }
    const msgs = await invoke("load_broadcast_history", {
      req: { base_url: state.apiBaseUrl, token: state.apiToken || "", time_zone: state.timeZone }
    });
    state.broadcastHistory = Array.isArray(msgs) ? msgs : [];
    renderBroadcastHistory();
  } catch (e) {
    if (showLoading || state.broadcastHistory.length === 0) {
      appendEmptyRow(tbody, 3, String(e));
    }
  } finally {
    state.broadcastHistoryInFlight = false;
  }
}

function startBroadcastRefreshLoop() {
  if (state.broadcastRefreshTimer) clearInterval(state.broadcastRefreshTimer);
  state.broadcastRefreshTimer = setInterval(() => {
    loadBroadcastHistory({ showLoading: false });
  }, BROADCAST_REFRESH_INTERVAL_MS);
}

async function checkUpdate() {
  try {
    $("#checkUpdateBtn").disabled = true;
    $("#updateStatusMessage").textContent = t("checkingUpdate");
    const info = await invoke("check_update");
    if (info.available) {
      $("#updateStatusMessage").textContent = t("updateAvailable", { latest: info.latest_version, current: info.current_version });
    } else {
      $("#updateStatusMessage").textContent = t("updateCurrent", { current: info.current_version });
    }
  } catch (e) {
    $("#updateStatusMessage").textContent = `${t("updateFailed")}: ${e}`;
  } finally {
    $("#checkUpdateBtn").disabled = false;
  }
}

async function autoCheckUpdateIfDue() {
  if (!state.autoCheckUpdate) return;
  const lastChecked = Number(localStorage.getItem(UPDATE_CHECK_CACHE_KEY) || 0);
  if (Date.now() - lastChecked < UPDATE_CHECK_INTERVAL_MS) return;
  localStorage.setItem(UPDATE_CHECK_CACHE_KEY, String(Date.now()));
  await checkUpdate();
}

async function applyConfigPathOverride() {
  const value = $("#configPathInput").value.trim();
  if (value) {
    state.configPath = value;
    localStorage.setItem(CONFIG_PATH_OVERRIDE_KEY, value);
  } else {
    localStorage.removeItem(CONFIG_PATH_OVERRIDE_KEY);
    state.configPath = tauriInvoke ? await invoke("config_path") : "";
  }
  syncConfigPathUI();
  await loadConfigLists();
  await refreshServers({ silent: true });
  setStatus(t("statusSaved"));
}

async function resetConfigPathOverride() {
  localStorage.removeItem(CONFIG_PATH_OVERRIDE_KEY);
  state.configPath = tauriInvoke ? await invoke("config_path") : "";
  syncConfigPathUI();
  await loadConfigLists();
  await refreshServers({ silent: true });
  setStatus(t("statusSaved"));
}

async function openSteam(address) {
  try {
    await invoke("open_steam_connect", { address });
  } catch {
    window.location.href = `steam://connect/${address}`;
  }
}

function bindEvents() {
  $$(".nav-item").forEach((button) => {
    button.addEventListener("click", () => setTab(button.dataset.tab));
  });
  
  $("#refreshBtn").addEventListener("click", () => {
    if (state.tab === "servers") refreshServers();
    else if (state.tab === "globalPlayers") loadGlobalPlayers();
    else if (state.tab === "broadcast") loadBroadcastHistory({ showLoading: true, force: true });
  });
  
  $("#onlyPlayersInput").addEventListener("change", (event) => {
    state.onlyWithPlayers = event.currentTarget.checked;
    if (state.onlyWithPlayers) {
      state.onlyEmpty = false;
      $("#onlyEmptyInput").checked = false;
    }
    applyServerFiltersAndRender();
  });
  $("#onlyEmptyInput").addEventListener("change", (event) => {
    state.onlyEmpty = event.currentTarget.checked;
    if (state.onlyEmpty) {
      state.onlyWithPlayers = false;
      $("#onlyPlayersInput").checked = false;
    }
    applyServerFiltersAndRender();
  });
  $("#hideTimeoutInput").addEventListener("change", (event) => {
    state.hideTimeout = event.currentTarget.checked;
    applyServerFiltersAndRender();
  });
  let searchTimer = 0;
  $("#searchInput").addEventListener("input", (event) => {
    state.search = event.currentTarget.value;
    clearTimeout(searchTimer);
    searchTimer = setTimeout(applyServerFiltersAndRender, 120);
  });
  
  // Settings
  $("#refreshSubscriptionsBtn").addEventListener("click", refreshSubscriptions);
  $("#newSubscriptionBtn").addEventListener("click", clearSubscriptionEditor);
  $("#saveSubscriptionBtn").addEventListener("click", saveSubscription);
  $("#deleteSubscriptionBtn").addEventListener("click", deleteSubscription);
  $("#addManualBtn").addEventListener("click", addManualServer);
  $("#applyConfigPathBtn").addEventListener("click", async () => {
    try {
      await applyConfigPathOverride();
    } catch (error) {
      setStatus(`${t("saveFailed")}: ${error}`);
    }
  });
  $("#resetConfigPathBtn").addEventListener("click", async () => {
    try {
      await resetConfigPathOverride();
    } catch (error) {
      setStatus(`${t("saveFailed")}: ${error}`);
    }
  });
  
  // Sort
  $$("th.sortable").forEach(th => {
    th.addEventListener("click", () => handleSortClick(th.dataset.sort));
  });
  
  // Inspector
  $("#closeInspectorBtn").addEventListener("click", closeInspector);
  $$(".ins-tab").forEach(tab => {
    tab.addEventListener("click", () => setInspectorTab(tab.dataset.ins));
  });
  $("#rconSendBtn").addEventListener("click", sendRcon);
  $("#rconCommand").addEventListener("keypress", (e) => {
    if (e.key === 'Enter') sendRcon();
  });
  $("#cvarRefreshBtn").addEventListener("click", refreshInspector);
  $("#saveRconPasswordInput").addEventListener("change", async (e) => {
    try {
      if (e.currentTarget.checked) {
        await saveRconPassword($("#rconPassword").value.trim(), state.selectedAddress);
      } else {
        await saveRconPassword(null, state.selectedAddress);
      }
      e.currentTarget.checked = state.rconPasswordSaved;
      setStatus(t("statusSaved"));
    } catch (error) {
      e.currentTarget.checked = state.rconPasswordSaved;
      setStatus(`${t("saveFailed")}: ${error}`);
    }
  });
  $("#rconPassword").addEventListener("change", async (e) => {
    if (!$("#saveRconPasswordInput").checked) return;
    try {
      await saveRconPassword(e.currentTarget.value.trim(), state.selectedAddress);
      setStatus(t("statusSaved"));
    } catch (error) {
      setStatus(`${t("saveFailed")}: ${error}`);
    }
  });
  
  // Steam
  $("#steamLoginBtn").addEventListener("click", startSteamLogin);
  $("#steamLogoutBtn").addEventListener("click", logoutApi);
  $("#checkUpdateBtn").addEventListener("click", checkUpdate);
  $("#apiBaseUrlInput").addEventListener("change", async (e) => {
    state.apiBaseUrl = e.currentTarget.value.trim();
    try {
      await invoke("save_api_config", {
        req: { config_path: state.configPath, base_url: state.apiBaseUrl, token: state.apiToken }
      });
      setStatus(t("statusSaved"));
    } catch (error) {
      setStatus(`${t("saveFailed")}: ${error}`);
    }
  });
  
  // Broadcast
  $("#broadcastSendBtn").addEventListener("click", sendBroadcastMessage);
  
  // i18n
  $("#languageSelect").addEventListener("change", async (e) => {
    const locale = e.target.value;
    setLocale(locale);
    syncTimeZoneInput();
    try {
      await saveGuiSettings({ language: configLanguageFromLocale(locale) });
      setStatus(t("statusSaved"));
    } catch (error) {
      setStatus(`${t("saveFailed")}: ${error}`);
    }
  });
  $("#autoUpdateInput").addEventListener("change", async (e) => {
    state.autoCheckUpdate = e.currentTarget.checked;
    try {
      await saveGuiSettings({ update_auto_check: state.autoCheckUpdate });
      setStatus(t("statusSaved"));
    } catch (error) {
      setStatus(`${t("saveFailed")}: ${error}`);
    }
  });
  $("#themeSelect").addEventListener("change", async (e) => {
    state.themeMode = normalizeThemeMode(e.currentTarget.value);
    applyTheme();
    try {
      await saveGuiSettings({ theme_mode: state.themeMode, accent_color: state.accentColor });
      setStatus(t("statusSaved"));
    } catch (error) {
      setStatus(`${t("saveFailed")}: ${error}`);
    }
  });
  $("#customAccentInput").addEventListener("input", (e) => {
    state.accentColor = e.currentTarget.value;
    if (state.themeMode !== "custom") {
      state.themeMode = "custom";
    }
    applyTheme();
  });
  $("#customAccentInput").addEventListener("change", async (e) => {
    state.accentColor = e.currentTarget.value;
    if (state.themeMode !== "custom") {
      state.themeMode = "custom";
    }
    applyTheme();
    try {
      await saveGuiSettings({ theme_mode: state.themeMode, accent_color: state.accentColor });
      setStatus(t("statusSaved"));
    } catch (error) {
      setStatus(`${t("saveFailed")}: ${error}`);
    }
  });
  $("#anneStatsInput").addEventListener("change", async (e) => {
    state.anneStatsEnabled = e.currentTarget.checked;
    try {
      await saveGuiSettings({ anne_stats: state.anneStatsEnabled });
      setStatus(t("statusSaved"));
      if (state.inspectorOpen && state.inspectorTab === "players") refreshInspector();
      if (state.tab === "globalPlayers") loadGlobalPlayers();
    } catch (error) {
      setStatus(`${t("saveFailed")}: ${error}`);
    }
  });
  $("#autoRefreshEmptyInput").addEventListener("change", async (e) => {
    state.autoRefreshEmptySecs = clampRefreshSeconds(e.currentTarget.value, 120, 15);
    e.currentTarget.value = state.autoRefreshEmptySecs;
    try {
      await saveGuiSettings({ auto_refresh_empty_secs: state.autoRefreshEmptySecs });
      startAutoRefreshLoop();
      setStatus(t("statusSaved"));
    } catch (error) {
      setStatus(`${t("saveFailed")}: ${error}`);
    }
  });
  $("#autoRefreshActiveInput").addEventListener("change", async (e) => {
    state.autoRefreshActiveSecs = clampRefreshSeconds(e.currentTarget.value, 30, 5);
    e.currentTarget.value = state.autoRefreshActiveSecs;
    try {
      await saveGuiSettings({ auto_refresh_active_secs: state.autoRefreshActiveSecs });
      startAutoRefreshLoop();
      setStatus(t("statusSaved"));
    } catch (error) {
      setStatus(`${t("saveFailed")}: ${error}`);
    }
  });
  $("#autoRefreshSelectedInput").addEventListener("change", async (e) => {
    state.autoRefreshSelectedSecs = clampRefreshSeconds(e.currentTarget.value, SELECTED_REFRESH_DEFAULT_SECS, 3);
    e.currentTarget.value = state.autoRefreshSelectedSecs;
    try {
      await saveGuiSettings({ auto_refresh_selected_secs: state.autoRefreshSelectedSecs });
      startAutoRefreshLoop();
      setStatus(t("statusSaved"));
    } catch (error) {
      setStatus(`${t("saveFailed")}: ${error}`);
    }
  });
  $("#timeZoneInput").addEventListener("change", async (e) => {
    state.timeZone = normalizeTimeZone(e.currentTarget.value);
    e.currentTarget.value = state.timeZone;
    try {
      await saveGuiSettings({ time_zone: state.timeZone });
      setStatus(t("statusSaved"));
      loadBroadcastHistory({ showLoading: state.tab === "broadcast", force: true });
    } catch (error) {
      setStatus(`${t("saveFailed")}: ${error}`);
    }
  });
}

async function boot() {
  initI18n();
  $("#languageSelect").value = getLocale();
  applyTheme();
  syncTimeZoneInput();
  
  bindEvents();
  clearSubscriptionEditor();
  try {
    const configOverride = localStorage.getItem(CONFIG_PATH_OVERRIDE_KEY);
    if (configOverride) {
      state.configPath = configOverride;
    } else if (tauriInvoke) {
      state.configPath = await invoke("config_path");
    }
    syncConfigPathUI();
    await loadConfigLists();
    await loadBroadcastHistory({ showLoading: false, force: true });
    await refreshServers();
    await autoCheckUpdateIfDue();
    startAutoRefreshLoop();
    startBroadcastRefreshLoop();
    
  } catch (error) {
    setStatus(`${t("initFailed")}: ${error}`);
  }
}

boot();
