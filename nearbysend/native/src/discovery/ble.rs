use btleplug::api::{Central, Manager as _, Peripheral as _, ScanFilter};
use btleplug::platform::{Adapter, Manager, Peripheral};
use futures::stream::StreamExt;
use std::error::Error;
use std::sync::{Arc, Mutex};
use std::time::Duration;
use tokio::sync::mpsc;
use tokio::time;
use uuid::Uuid;

// NearbySend服务UUID
const NEARBYSEND_SERVICE_UUID: &str = "00001234-0000-1000-8000-00805f9b34fb";

// BLE设备结构体
#[derive(Clone, Debug)]
pub struct BleDevice {
    pub id: String,
    pub name: String,
    pub peripheral: Arc<Peripheral>,
}

// 全局设备列表
lazy_static::lazy_static! {
    static ref DISCOVERED_DEVICES: Arc<Mutex<Vec<BleDevice>>> = Arc::new(Mutex::new(Vec::new()));
    static ref DISCOVERY_RUNNING: Arc<Mutex<bool>> = Arc::new(Mutex::new(false));
}

// 启动BLE设备发现
pub async fn start_ble_discovery() -> Result<(), String> {
    // 检查是否已经在运行
    {
        let mut running = DISCOVERY_RUNNING.lock().map_err(|e| e.to_string())?;
        if *running {
            return Ok(());
        }
        *running = true;
    }

    // 清空设备列表
    {
        let mut devices = DISCOVERED_DEVICES.lock().map_err(|e| e.to_string())?;
        devices.clear();
    }

    // 创建通道用于接收发现的设备
    let (tx, mut rx) = mpsc::channel(10);

    // 在后台运行设备发现
    tokio::spawn(async move {
        if let Err(e) = discover_devices(tx).await {
            log::error!("BLE discovery error: {:?}", e);
        }

        // 发现结束后，更新状态
        if let Ok(mut running) = DISCOVERY_RUNNING.lock() {
            *running = false;
        }
    });

    // 处理发现的设备
    tokio::spawn(async move {
        while let Some(device) = rx.recv().await {
            if let Ok(mut devices) = DISCOVERED_DEVICES.lock() {
                // 检查设备是否已存在
                if !devices.iter().any(|d| d.id == device.id) {
                    devices.push(device);
                }
            }
        }
    });

    Ok(())
}

// 停止BLE设备发现
pub fn stop_ble_discovery() -> Result<(), String> {
    let mut running = DISCOVERY_RUNNING.lock().map_err(|e| e.to_string())?;
    *running = false;
    Ok(())
}

// 获取已发现的设备列表
pub fn get_discovered_devices() -> Result<Vec<BleDevice>, String> {
    let devices = DISCOVERED_DEVICES.lock().map_err(|e| e.to_string())?;
    Ok(devices.clone())
}

// 内部设备发现函数
async fn discover_devices(tx: mpsc::Sender<BleDevice>) -> Result<(), Box<dyn Error>> {
    // 获取BLE适配器
    let manager = Manager::new().await?;
    let adapters = manager.adapters().await?;
    
    if adapters.is_empty() {
        return Err("No Bluetooth adapters found".into());
    }
    
    let adapter = adapters.into_iter().next().unwrap();
    
    // 开始扫描
    adapter.start_scan(ScanFilter::default()).await?;
    log::info!("BLE scanning started");
    
    // 设置服务UUID
    let service_uuid = Uuid::parse_str(NEARBYSEND_SERVICE_UUID)?;
    
    // 监听发现的设备
    let mut events = adapter.events().await?;
    
    // 设置超时
    let timeout = time::sleep(Duration::from_secs(30));
    tokio::pin!(timeout);
    
    loop {
        tokio::select! {
            _ = &mut timeout => {
                log::info!("BLE scanning timeout");
                break;
            }
            event = events.next() => {
                if let Some(event) = event {
                    if let btleplug::api::CentralEvent::DeviceDiscovered(id) = event {
                        if let Ok(peripheral) = adapter.peripheral(&id).await {
                            if let Ok(properties) = peripheral.properties().await {
                                if let Some(properties) = properties {
                                    if let Some(name) = properties.local_name {
                                        // 创建设备对象
                                        let device = BleDevice {
                                            id: id.to_string(),
                                            name,
                                            peripheral: Arc::new(peripheral),
                                        };
                                        
                                        // 发送到通道
                                        if tx.send(device).await.is_err() {
                                            log::error!("Failed to send device to channel");
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            // 检查是否应该停止
            _ = async {
                loop {
                    if let Ok(running) = DISCOVERY_RUNNING.lock() {
                        if !*running {
                            return;
                        }
                    }
                    time::sleep(Duration::from_millis(100)).await;
                }
            } => {
                log::info!("BLE scanning stopped");
                break;
            }
        }
    }
    
    // 停止扫描
    adapter.stop_scan().await?;
    log::info!("BLE scanning completed");
    
    Ok(())
}
