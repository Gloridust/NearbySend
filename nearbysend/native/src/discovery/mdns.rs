use mdns_sd::{ServiceDaemon, ServiceEvent, ServiceInfo};
use std::collections::HashMap;
use std::net::IpAddr;
use std::sync::{Arc, Mutex};
use std::time::Duration;
use tokio::time;

// NearbySend服务类型
const SERVICE_TYPE: &str = "_nearbysend._tcp.local.";

// mDNS设备结构体
#[derive(Clone, Debug)]
pub struct MdnsDevice {
    pub id: String,
    pub name: String,
    pub ip_address: IpAddr,
    pub port: u16,
    pub device_type: String,
}

// 全局设备列表
lazy_static::lazy_static! {
    static ref DISCOVERED_MDNS_DEVICES: Arc<Mutex<Vec<MdnsDevice>>> = Arc::new(Mutex::new(Vec::new()));
    static ref MDNS_DISCOVERY_RUNNING: Arc<Mutex<bool>> = Arc::new(Mutex::new(false));
    static ref MDNS_SERVICE: Arc<Mutex<Option<ServiceDaemon>>> = Arc::new(Mutex::new(None));
}

// 启动mDNS设备发现
pub fn start_mdns_discovery() -> Result<(), String> {
    // 检查是否已经在运行
    {
        let mut running = MDNS_DISCOVERY_RUNNING.lock().map_err(|e| e.to_string())?;
        if *running {
            return Ok(());
        }
        *running = true;
    }

    // 清空设备列表
    {
        let mut devices = DISCOVERED_MDNS_DEVICES.lock().map_err(|e| e.to_string())?;
        devices.clear();
    }

    // 创建mDNS服务
    let mdns = ServiceDaemon::new().map_err(|e| e.to_string())?;
    
    // 创建浏览器
    let receiver = mdns.browse(SERVICE_TYPE).map_err(|e| e.to_string())?;

    // 保存服务实例
    {
        let mut service = MDNS_SERVICE.lock().map_err(|e| e.to_string())?;
        *service = Some(mdns);
    }

    // 在后台处理发现的设备
    tokio::spawn(async move {
        while let Ok(event) = receiver.recv() {
            match event {
                ServiceEvent::ServiceResolved(info) => {
                    log::info!("mDNS service resolved: {:?}", info);
                    
                    // 获取设备信息
                    if let Some(ip_address) = info.get_addresses().first() {
                        let port = info.get_port();
                        let fullname = info.get_fullname();
                        let id = fullname.to_string();
                        
                        // 获取设备名称和类型
                        let properties = info.get_properties();
                        let name = properties.get("name").cloned().unwrap_or_else(|| "Unknown Device".to_string());
                        let device_type = properties.get("device_type").cloned().unwrap_or_else(|| "unknown".to_string());
                        
                        // 创建设备对象
                        let device = MdnsDevice {
                            id,
                            name,
                            ip_address: *ip_address,
                            port,
                            device_type,
                        };
                        
                        // 添加到设备列表
                        if let Ok(mut devices) = DISCOVERED_MDNS_DEVICES.lock() {
                            // 检查设备是否已存在
                            if !devices.iter().any(|d| d.id == device.id) {
                                devices.push(device);
                            }
                        }
                    }
                }
                ServiceEvent::ServiceRemoved(service_type, fullname) => {
                    log::info!("mDNS service removed: {} {}", service_type, fullname);
                    
                    // 从设备列表中移除
                    if let Ok(mut devices) = DISCOVERED_MDNS_DEVICES.lock() {
                        devices.retain(|d| d.id != fullname);
                    }
                }
                _ => {}
            }
            
            // 检查是否应该停止
            if let Ok(running) = MDNS_DISCOVERY_RUNNING.lock() {
                if !*running {
                    break;
                }
            }
        }
        
        log::info!("mDNS discovery stopped");
    });

    Ok(())
}

// 停止mDNS设备发现
pub fn stop_mdns_discovery() -> Result<(), String> {
    let mut running = MDNS_DISCOVERY_RUNNING.lock().map_err(|e| e.to_string())?;
    *running = false;
    
    // 关闭mDNS服务
    {
        let mut service = MDNS_SERVICE.lock().map_err(|e| e.to_string())?;
        *service = None;
    }
    
    Ok(())
}

// 获取已发现的设备列表
pub fn get_discovered_mdns_devices() -> Result<Vec<MdnsDevice>, String> {
    let devices = DISCOVERED_MDNS_DEVICES.lock().map_err(|e| e.to_string())?;
    Ok(devices.clone())
}

// 注册本机为可发现设备
pub fn register_device(name: &str, port: u16) -> Result<(), String> {
    // 获取mDNS服务
    let service = {
        let service = MDNS_SERVICE.lock().map_err(|e| e.to_string())?;
        match &*service {
            Some(service) => service.clone(),
            None => {
                // 如果服务不存在，创建一个新的
                let mdns = ServiceDaemon::new().map_err(|e| e.to_string())?;
                let mut service = MDNS_SERVICE.lock().map_err(|e| e.to_string())?;
                *service = Some(mdns.clone());
                mdns
            }
        }
    };
    
    // 创建服务信息
    let mut properties = HashMap::new();
    properties.insert("name".to_string(), name.to_string());
    
    // 添加设备类型
    let device_type = match std::env::consts::OS {
        "macos" => "macos",
        "android" => "android",
        "ios" => "ios",
        "windows" => "windows",
        _ => "unknown",
    };
    properties.insert("device_type".to_string(), device_type.to_string());
    
    // 创建服务信息
    let service_info = ServiceInfo::new(
        SERVICE_TYPE,
        name,
        name,
        "",
        port,
        properties,
    ).map_err(|e| e.to_string())?;
    
    // 注册服务
    service.register(service_info).map_err(|e| e.to_string())?;
    
    log::info!("Device registered with mDNS: {}", name);
    
    Ok(())
}
