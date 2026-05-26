use anne_server_browser::{
    add_tauri_manual_server, delete_tauri_sourcebans, load_tauri_config_lists,
    load_tauri_server_rows, open_tauri_steam_connect, save_tauri_sourcebans, tauri_config_path,
    tauri_delete_manual_server, tauri_query_players, tauri_run_rcon, tauri_read_cvars,
    tauri_fetch_network_info, tauri_check_update, tauri_api_me, tauri_steam_login_start,
    tauri_steam_login_poll, tauri_api_logout, tauri_send_broadcast,
    tauri_load_broadcast_history, tauri_load_global_players, tauri_save_api_config,
    TauriConfigLists, TauriServerQuery, TauriServerRows, TauriSourceBansInput,
    TauriDeleteManualServerRequest, TauriPlayerInfo, TauriRconRequest,
    TauriCvarRequest, TauriCvarEntry, TauriNetworkInfo, TauriUpdateInfo,
    TauriApiUser, TauriLoginStart, TauriLoginPollRequest, TauriLoginResult,
    TauriBroadcastRequest, TauriBroadcastMessage, TauriGlobalPlayer,
    TauriSaveApiConfigRequest,
};

#[tauri::command]
fn config_path() -> String {
    tauri_config_path()
}

#[tauri::command]
fn load_config_lists(path: Option<String>) -> Result<TauriConfigLists, String> {
    load_tauri_config_lists(path)
}

#[tauri::command]
fn refresh_servers(query: TauriServerQuery) -> Result<TauriServerRows, String> {
    load_tauri_server_rows(query)
}

#[tauri::command]
fn add_manual_server(
    path: Option<String>,
    group: String,
    server: String,
) -> Result<TauriConfigLists, String> {
    add_tauri_manual_server(path, group, server)
}

#[tauri::command]
fn delete_manual_server(req: TauriDeleteManualServerRequest) -> Result<TauriConfigLists, String> {
    tauri_delete_manual_server(req)
}

#[tauri::command]
fn save_sourcebans(input: TauriSourceBansInput) -> Result<TauriConfigLists, String> {
    save_tauri_sourcebans(input)
}

#[tauri::command]
fn delete_sourcebans(path: Option<String>, index: usize) -> Result<TauriConfigLists, String> {
    delete_tauri_sourcebans(path, index)
}

#[tauri::command]
fn open_steam_connect(address: String) -> Result<(), String> {
    open_tauri_steam_connect(address)
}

#[tauri::command]
fn query_players(config_path: Option<String>, address: String) -> Result<Vec<TauriPlayerInfo>, String> {
    tauri_query_players(config_path, address)
}

#[tauri::command]
fn run_rcon(req: TauriRconRequest) -> Result<String, String> {
    tauri_run_rcon(req)
}

#[tauri::command]
fn read_cvars(req: TauriCvarRequest) -> Result<Vec<TauriCvarEntry>, String> {
    tauri_read_cvars(req)
}

#[tauri::command]
fn fetch_network_info(address: String, ip: String) -> Result<TauriNetworkInfo, String> {
    tauri_fetch_network_info(address, ip)
}

#[tauri::command]
fn check_update() -> Result<TauriUpdateInfo, String> {
    tauri_check_update()
}

#[tauri::command]
fn api_me(base_url: String, token: String) -> Result<TauriApiUser, String> {
    tauri_api_me(base_url, token)
}

#[tauri::command]
fn steam_login_start(base_url: String) -> Result<TauriLoginStart, String> {
    tauri_steam_login_start(base_url)
}

#[tauri::command]
fn steam_login_poll(req: TauriLoginPollRequest) -> Result<Option<TauriLoginResult>, String> {
    tauri_steam_login_poll(req)
}

#[tauri::command]
fn api_logout(base_url: String, token: String) -> Result<(), String> {
    tauri_api_logout(base_url, token)
}

#[tauri::command]
fn send_broadcast(req: TauriBroadcastRequest) -> Result<String, String> {
    tauri_send_broadcast(req)
}

#[tauri::command]
fn load_broadcast_history(base_url: String, token: String) -> Result<Vec<TauriBroadcastMessage>, String> {
    tauri_load_broadcast_history(base_url, token)
}

#[tauri::command]
fn load_global_players(base_url: String, token: String, config_path: Option<String>) -> Result<Vec<TauriGlobalPlayer>, String> {
    tauri_load_global_players(base_url, token, config_path)
}

#[tauri::command]
fn save_api_config(req: TauriSaveApiConfigRequest) -> Result<(), String> {
    tauri_save_api_config(req)
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
            open_steam_connect,
            query_players,
            run_rcon,
            read_cvars,
            fetch_network_info,
            check_update,
            api_me,
            steam_login_start,
            steam_login_poll,
            api_logout,
            send_broadcast,
            load_broadcast_history,
            load_global_players,
            save_api_config,
        ])
        .run(tauri::generate_context!())
        .expect("failed to run Anne刷服器");
}
