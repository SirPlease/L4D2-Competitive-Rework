#![cfg_attr(
    all(target_os = "windows", not(debug_assertions)),
    windows_subsystem = "windows"
)]

use anne_server_browser::{
    add_tauri_manual_server, delete_tauri_sourcebans, load_tauri_config_lists,
    load_tauri_server_rows, open_tauri_steam_connect, open_tauri_url, refresh_tauri_sourcebans,
    save_tauri_sourcebans, tauri_api_logout, tauri_api_me, tauri_check_update, tauri_config_path,
    tauri_delete_manual_server, tauri_fetch_network_info, tauri_install_update,
    tauri_load_broadcast_history, tauri_load_global_players, tauri_query_players, tauri_read_cvars,
    tauri_run_rcon, tauri_save_api_config, tauri_save_gui_settings, tauri_save_rcon_password,
    tauri_send_broadcast, tauri_steam_login_poll, tauri_steam_login_start, TauriApiUser,
    TauriBroadcastHistoryRequest, TauriBroadcastHistoryResult, TauriBroadcastMessage,
    TauriBroadcastRequest, TauriConfigLists, TauriCvarEntry,
    TauriCvarRequest, TauriDeleteManualServerRequest, TauriGlobalPlayer, TauriGuiSettingsRequest,
    TauriInstallUpdateRequest, TauriInstallUpdateResult, TauriLoginPollRequest, TauriLoginResult,
    TauriLoginStart, TauriNetworkInfo, TauriPlayerInfo, TauriRconRequest, TauriSaveApiConfigRequest,
    TauriSaveRconPasswordRequest, TauriServerQuery, TauriServerRows, TauriSourceBansInput, TauriUpdateInfo,
};

async fn run_blocking<T, F>(task: F) -> Result<T, String>
where
    T: Send + 'static,
    F: FnOnce() -> Result<T, String> + Send + 'static,
{
    tauri::async_runtime::spawn_blocking(task)
        .await
        .map_err(|err| format!("background task failed: {err}"))?
}

#[tauri::command]
fn config_path() -> String {
    tauri_config_path()
}

#[tauri::command]
async fn load_config_lists(path: Option<String>) -> Result<TauriConfigLists, String> {
    run_blocking(move || load_tauri_config_lists(path)).await
}

#[tauri::command]
async fn refresh_servers(query: TauriServerQuery) -> Result<TauriServerRows, String> {
    run_blocking(move || load_tauri_server_rows(query)).await
}

#[tauri::command]
async fn add_manual_server(
    path: Option<String>,
    group: String,
    server: String,
) -> Result<TauriConfigLists, String> {
    run_blocking(move || add_tauri_manual_server(path, group, server)).await
}

#[tauri::command]
async fn delete_manual_server(
    req: TauriDeleteManualServerRequest,
) -> Result<TauriConfigLists, String> {
    run_blocking(move || tauri_delete_manual_server(req)).await
}

#[tauri::command]
async fn save_sourcebans(input: TauriSourceBansInput) -> Result<TauriConfigLists, String> {
    run_blocking(move || save_tauri_sourcebans(input)).await
}

#[tauri::command]
async fn delete_sourcebans(path: Option<String>, index: usize) -> Result<TauriConfigLists, String> {
    run_blocking(move || delete_tauri_sourcebans(path, index)).await
}

#[tauri::command]
async fn refresh_sourcebans(path: Option<String>) -> Result<TauriConfigLists, String> {
    run_blocking(move || refresh_tauri_sourcebans(path)).await
}

#[tauri::command]
fn open_steam_connect(address: String) -> Result<(), String> {
    open_tauri_steam_connect(address)
}

#[tauri::command]
fn open_url(url: String) -> Result<(), String> {
    open_tauri_url(url)
}

#[tauri::command]
async fn query_players(
    config_path: Option<String>,
    address: String,
) -> Result<Vec<TauriPlayerInfo>, String> {
    run_blocking(move || tauri_query_players(config_path, address)).await
}

#[tauri::command]
async fn run_rcon(req: TauriRconRequest) -> Result<String, String> {
    run_blocking(move || tauri_run_rcon(req)).await
}

#[tauri::command]
async fn read_cvars(req: TauriCvarRequest) -> Result<Vec<TauriCvarEntry>, String> {
    run_blocking(move || tauri_read_cvars(req)).await
}

#[tauri::command]
async fn fetch_network_info(address: String, ip: String) -> Result<TauriNetworkInfo, String> {
    run_blocking(move || tauri_fetch_network_info(address, ip)).await
}

#[tauri::command]
async fn check_update() -> Result<TauriUpdateInfo, String> {
    run_blocking(tauri_check_update).await
}

#[tauri::command]
async fn install_update(req: TauriInstallUpdateRequest) -> Result<TauriInstallUpdateResult, String> {
    run_blocking(move || tauri_install_update(req)).await
}

#[tauri::command]
fn exit_app() {
    std::process::exit(0);
}

#[tauri::command]
async fn api_me(base_url: String, token: String) -> Result<TauriApiUser, String> {
    run_blocking(move || tauri_api_me(base_url, token)).await
}

#[tauri::command]
async fn steam_login_start(base_url: String) -> Result<TauriLoginStart, String> {
    run_blocking(move || tauri_steam_login_start(base_url)).await
}

#[tauri::command]
async fn steam_login_poll(req: TauriLoginPollRequest) -> Result<Option<TauriLoginResult>, String> {
    run_blocking(move || tauri_steam_login_poll(req)).await
}

#[tauri::command]
async fn api_logout(base_url: String, token: String) -> Result<(), String> {
    run_blocking(move || tauri_api_logout(base_url, token)).await
}

#[tauri::command]
async fn send_broadcast(req: TauriBroadcastRequest) -> Result<TauriBroadcastMessage, String> {
    run_blocking(move || tauri_send_broadcast(req)).await
}

#[tauri::command]
async fn load_broadcast_history(
    req: TauriBroadcastHistoryRequest,
) -> Result<TauriBroadcastHistoryResult, String> {
    run_blocking(move || tauri_load_broadcast_history(req)).await
}

#[tauri::command]
async fn load_global_players(
    base_url: String,
    token: String,
    force_stats: Option<bool>,
    config_path: Option<String>,
) -> Result<Vec<TauriGlobalPlayer>, String> {
    run_blocking(move || {
        tauri_load_global_players(base_url, token, force_stats.unwrap_or(false), config_path)
    })
    .await
}

#[tauri::command]
async fn save_api_config(req: TauriSaveApiConfigRequest) -> Result<(), String> {
    run_blocking(move || tauri_save_api_config(req)).await
}

#[tauri::command]
async fn save_gui_settings(req: TauriGuiSettingsRequest) -> Result<TauriConfigLists, String> {
    run_blocking(move || tauri_save_gui_settings(req)).await
}

#[tauri::command]
async fn save_rcon_password(req: TauriSaveRconPasswordRequest) -> Result<TauriConfigLists, String> {
    run_blocking(move || tauri_save_rcon_password(req)).await
}

fn main() {
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![
            config_path,
            load_config_lists,
            refresh_servers,
            add_manual_server,
            delete_manual_server,
            save_sourcebans,
            delete_sourcebans,
            refresh_sourcebans,
            open_steam_connect,
            open_url,
            query_players,
            run_rcon,
            read_cvars,
            fetch_network_info,
            check_update,
            install_update,
            exit_app,
            api_me,
            steam_login_start,
            steam_login_poll,
            api_logout,
            send_broadcast,
            load_broadcast_history,
            load_global_players,
            save_api_config,
            save_gui_settings,
            save_rcon_password,
        ])
        .run(tauri::generate_context!())
        .expect("failed to run Anne刷服器");
}
