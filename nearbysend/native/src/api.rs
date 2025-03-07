use crate::discovery::ble::BleDevice;
use flutter_rust_bridge::frb;
use std::sync::Arc;

// 导出模块
pub use crate::discovery::ble::start_ble_discovery;
pub use crate::discovery::ble::stop_ble_discovery;
pub use crate::discovery::mdns::start_mdns_discovery;
pub use crate::discovery::mdns::stop_mdns_discovery;
pub use crate::connection::wifi_direct::connect_to_device;
pub use crate::transfer::protocol::send_file;
pub use crate::transfer::protocol::receive_file;

// 设备结构体
#[frb(dart_metadata=("freezed"))]
#[derive(Clone, Debug)]
pub struct Device {
    pub id: String,
    pub name: String,
    pub device_type: DeviceType,
    pub is_connected: bool,
}

// 设备类型枚举
#[frb(dart_metadata=("freezed"))]
#[derive(Clone, Debug)]
pub enum DeviceType {
    Android,
    IOS,
    MacOS,
    Windows,
    Unknown,
}

// 文件传输状态枚举
#[frb(dart_metadata=("freezed"))]
#[derive(Clone, Debug)]
pub enum TransferStatus {
    Pending,
    Connecting,
    Transferring,
    Completed,
    Failed,
}

// 文件传输结构体
#[frb(dart_metadata=("freezed"))]
#[derive(Clone, Debug)]
pub struct FileTransfer {
    pub id: String,
    pub file_name: String,
    pub file_size: u64,
    pub transferred_bytes: u64,
    pub status: TransferStatus,
}

// 初始化函数
pub fn initialize() -> Result<(), String> {
    // 初始化日志
    env_logger::init();
    log::info!("NearbySend Rust backend initialized");
    Ok(())
}

// 获取设备名称
pub fn get_device_name() -> String {
    match std::env::consts::OS {
        "macos" => {
            // 在macOS上获取计算机名称
            let output = std::process::Command::new("scutil")
                .args(["--get", "ComputerName"])
                .output();
            
            match output {
                Ok(output) if output.status.success() => {
                    String::from_utf8_lossy(&output.stdout).trim().to_string()
                }
                _ => "MacOS Device".to_string(),
            }
        }
        "android" => "Android Device".to_string(),
        "ios" => "iOS Device".to_string(),
        "windows" => "Windows Device".to_string(),
        _ => "Unknown Device".to_string(),
    }
}

// 测试函数
pub fn greet(name: String) -> String {
    format!("Hello, {}! Welcome to NearbySend", name)
}
