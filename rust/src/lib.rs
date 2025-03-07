use std::sync::Arc;

mod discovery;
mod connection;
mod transfer;
mod error;

pub use error::Error;
pub type Result<T> = std::result::Result<T, Error>;

/// 核心引擎结构体
pub struct Engine {
    discovery: Arc<discovery::Discovery>,
    connection: Arc<connection::Connection>,
    transfer: Arc<transfer::Transfer>,
}

impl Engine {
    /// 创建新的引擎实例
    pub fn new() -> Result<Self> {
        Ok(Self {
            discovery: Arc::new(discovery::Discovery::new()?),
            connection: Arc::new(connection::Connection::new()?),
            transfer: Arc::new(transfer::Transfer::new()?),
        })
    }

    /// 开始设备发现
    pub async fn start_discovery(&self) -> Result<()> {
        self.discovery.start().await
    }

    /// 停止设备发现
    pub async fn stop_discovery(&self) -> Result<()> {
        self.discovery.stop().await
    }

    /// 连接到设备
    pub async fn connect_to_device(&self, device_id: &str) -> Result<()> {
        self.connection.connect(device_id).await
    }

    /// 发送文件
    pub async fn send_file(&self, path: &str, device_id: &str) -> Result<()> {
        self.transfer.send_file(path, device_id).await
    }

    /// 接收文件
    pub async fn receive_file(&self, device_id: &str) -> Result<String> {
        self.transfer.receive_file(device_id).await
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_engine_creation() {
        let engine = Engine::new().expect("Failed to create engine");
        assert!(engine.start_discovery().await.is_ok());
    }
}
