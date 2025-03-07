use thiserror::Error;

#[derive(Error, Debug)]
pub enum Error {
    #[error("设备发现错误: {0}")]
    Discovery(String),

    #[error("连接错误: {0}")]
    Connection(String),

    #[error("传输错误: {0}")]
    Transfer(String),

    #[error("IO错误: {0}")]
    Io(#[from] std::io::Error),

    #[error("蓝牙错误: {0}")]
    Bluetooth(String),

    #[error("序列化错误: {0}")]
    Serialization(#[from] serde_json::Error),

    #[error("未知错误: {0}")]
    Unknown(String),
}

impl From<btleplug::Error> for Error {
    fn from(err: btleplug::Error) -> Self {
        Error::Bluetooth(err.to_string())
    }
}

impl From<quinn::ConnectError> for Error {
    fn from(err: quinn::ConnectError) -> Self {
        Error::Connection(err.to_string())
    }
}

impl From<quinn::WriteError> for Error {
    fn from(err: quinn::WriteError) -> Self {
        Error::Transfer(err.to_string())
    }
} 