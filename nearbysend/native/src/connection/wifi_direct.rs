use std::error::Error;
use std::net::{IpAddr, SocketAddr, TcpListener, TcpStream};
use std::sync::{Arc, Mutex};
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::{TcpListener as TokioTcpListener, TcpStream as TokioTcpStream};
use tokio::sync::mpsc;
use tokio::time::{self, Duration};

// 连接状态枚举
#[derive(Clone, Debug, PartialEq)]
pub enum ConnectionStatus {
    Disconnected,
    Connecting,
    Connected,
    Failed,
}

// 全局连接状态
lazy_static::lazy_static! {
    static ref CONNECTION_STATUS: Arc<Mutex<ConnectionStatus>> = Arc::new(Mutex::new(ConnectionStatus::Disconnected));
    static ref CURRENT_CONNECTION: Arc<Mutex<Option<TokioTcpStream>>> = Arc::new(Mutex::new(None));
}

// 连接到设备
pub async fn connect_to_device(ip_address: IpAddr, port: u16) -> Result<(), String> {
    // 更新连接状态
    {
        let mut status = CONNECTION_STATUS.lock().map_err(|e| e.to_string())?;
        *status = ConnectionStatus::Connecting;
    }

    // 创建Socket地址
    let socket_addr = SocketAddr::new(ip_address, port);

    // 尝试连接
    match TokioTcpStream::connect(socket_addr).await {
        Ok(stream) => {
            // 更新连接状态
            {
                let mut status = CONNECTION_STATUS.lock().map_err(|e| e.to_string())?;
                *status = ConnectionStatus::Connected;
            }

            // 保存连接
            {
                let mut connection = CURRENT_CONNECTION.lock().map_err(|e| e.to_string())?;
                *connection = Some(stream);
            }

            log::info!("Connected to device at {}:{}", ip_address, port);
            Ok(())
        }
        Err(e) => {
            // 更新连接状态
            {
                let mut status = CONNECTION_STATUS.lock().map_err(|e| e.to_string())?;
                *status = ConnectionStatus::Failed;
            }

            log::error!("Failed to connect to device: {}", e);
            Err(format!("Failed to connect to device: {}", e))
        }
    }
}

// 断开连接
pub fn disconnect() -> Result<(), String> {
    // 更新连接状态
    {
        let mut status = CONNECTION_STATUS.lock().map_err(|e| e.to_string())?;
        *status = ConnectionStatus::Disconnected;
    }

    // 清除连接
    {
        let mut connection = CURRENT_CONNECTION.lock().map_err(|e| e.to_string())?;
        *connection = None;
    }

    log::info!("Disconnected from device");
    Ok(())
}

// 获取连接状态
pub fn get_connection_status() -> Result<ConnectionStatus, String> {
    let status = CONNECTION_STATUS.lock().map_err(|e| e.to_string())?;
    Ok(status.clone())
}

// 启动监听服务器
pub async fn start_server(port: u16) -> Result<u16, String> {
    // 创建监听器
    let listener = match TokioTcpListener::bind(format!("0.0.0.0:{}", port)).await {
        Ok(listener) => listener,
        Err(_) => {
            // 如果指定端口不可用，尝试使用随机端口
            TokioTcpListener::bind("0.0.0.0:0").await.map_err(|e| e.to_string())?
        }
    };

    // 获取实际端口
    let actual_port = listener.local_addr().map_err(|e| e.to_string())?.port();
    log::info!("Server started on port {}", actual_port);

    // 在后台处理连接
    tokio::spawn(async move {
        while let Ok((stream, addr)) = listener.accept().await {
            log::info!("New connection from {}", addr);

            // 更新连接状态
            if let Ok(mut status) = CONNECTION_STATUS.lock() {
                *status = ConnectionStatus::Connected;
            }

            // 保存连接
            if let Ok(mut connection) = CURRENT_CONNECTION.lock() {
                *connection = Some(stream);
            }

            // 处理连接...
        }
    });

    Ok(actual_port)
}

// 发送数据
pub async fn send_data(data: &[u8]) -> Result<(), String> {
    // 获取当前连接
    let mut stream = {
        let connection = CURRENT_CONNECTION.lock().map_err(|e| e.to_string())?;
        match &*connection {
            Some(stream) => stream.clone(),
            None => return Err("No active connection".to_string()),
        }
    };

    // 发送数据
    stream.write_all(data).await.map_err(|e| e.to_string())?;
    log::info!("Sent {} bytes of data", data.len());

    Ok(())
}

// 接收数据
pub async fn receive_data(max_size: usize) -> Result<Vec<u8>, String> {
    // 获取当前连接
    let mut stream = {
        let connection = CURRENT_CONNECTION.lock().map_err(|e| e.to_string())?;
        match &*connection {
            Some(stream) => stream.clone(),
            None => return Err("No active connection".to_string()),
        }
    };

    // 接收数据
    let mut buffer = vec![0u8; max_size];
    let n = stream.read(&mut buffer).await.map_err(|e| e.to_string())?;
    buffer.truncate(n);

    log::info!("Received {} bytes of data", n);

    Ok(buffer)
}
