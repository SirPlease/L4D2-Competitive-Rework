import { getLocale, initI18n, setLocale, t } from './i18n.js';

const tauriInvoke = window.__TAURI__?.core?.invoke;
const CONFIG_PATH_OVERRIDE_KEY = "configPathOverride";
const UPDATE_CHECK_CACHE_KEY = "lastAutoUpdateCheckAt";
const UPDATE_CHECK_INTERVAL_MS = 12 * 60 * 60 * 1000;

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
  autoRefreshEmptySecs: 120,
  autoRefreshActiveSecs: 30,
  autoRefreshSelectedSecs: 10,
  timeZone: "system",
  broadcastSending: false,
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
  const input = $("#timeZoneInput");
  if (input) input.value = state.timeZone || "system";
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

function parseCvarNames(value) {
  const names = value
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);
  return names.length > 0 ? names : null;
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
    state.autoRefreshSelectedSecs = clampRefreshSeconds(lists.auto_refresh_selected_secs, 10, 3);
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
  if (tab === "broadcast") loadBroadcastHistory();
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
    state.autoRefreshSelectedSecs = clampRefreshSeconds(state.lists.auto_refresh_selected_secs, 10, 3);
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
    state.allRows = silent ? mergeSilentRefreshRows(nextRows, Array.isArray(sockets)) : nextRows;
    if (!silent) {
      const now = Date.now();
      state.lastFullRefreshAt = now;
      state.lastActiveRefreshAt = now;
      state.lastSelectedRefreshAt = now;
    }
    syncConfigPathUI();
    applyServerFiltersAndRender();
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
  if (!state.selectedSocket) return null;
  return state.allRows.some((row) => serverRowKey(row) === state.selectedSocket)
    ? state.selectedSocket
    : null;
}

function startAutoRefreshLoop() {
  if (state.autoRefreshTimer) clearInterval(state.autoRefreshTimer);
  state.lastFullRefreshAt = Date.now();
  state.lastActiveRefreshAt = Date.now();
  state.lastSelectedRefreshAt = Date.now();
  state.autoRefreshTimer = setInterval(() => {
    if (state.tab !== "servers" || state.busy) return;
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
    pingCell.textContent = server.ping_ms === null ? "-" : `${server.ping_ms}ms`;

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
      state.selectedSocket = server.socket;
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
        appendTextCell(tr, p.name);
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
      appendTextCell(tr, p.name);
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
    await loadBroadcastHistory();
  } catch (e) {
    setStatus(`${t("broadcastSendFailed")}: ${e}`);
  } finally {
    state.broadcastSending = false;
    sendButton.disabled = false;
  }
}

async function loadBroadcastHistory() {
  const tbody = $("#broadcastRows");
  try {
    appendEmptyRow(tbody, 3, t("broadcastLoading"));
    const msgs = await invoke("load_broadcast_history", {
      req: { base_url: state.apiBaseUrl, token: state.apiToken || "", time_zone: state.timeZone }
    });
    if (!msgs || msgs.length === 0) {
      appendEmptyRow(tbody, 3, t("emptyResult"));
      return;
    }
    tbody.replaceChildren();
    for (const m of msgs) {
      const tr = document.createElement("tr");
      appendTextCell(tr, m.sent_at_display || m.sent_at);
      appendTextCell(tr, m.sender_name);
      appendTextCell(tr, m.message);
      tbody.append(tr);
    }
  } catch (e) {
    appendEmptyRow(tbody, 3, String(e));
  }
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
    else if (state.tab === "broadcast") loadBroadcastHistory();
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
    state.autoRefreshSelectedSecs = clampRefreshSeconds(e.currentTarget.value, 10, 3);
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
      if (state.tab === "broadcast") loadBroadcastHistory();
    } catch (error) {
      setStatus(`${t("saveFailed")}: ${error}`);
    }
  });
}

async function boot() {
  initI18n();
  $("#languageSelect").value = getLocale();
  applyTheme();
  
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
    await refreshServers();
    await autoCheckUpdateIfDue();
    startAutoRefreshLoop();
    
  } catch (error) {
    setStatus(`${t("initFailed")}: ${error}`);
  }
}

boot();
