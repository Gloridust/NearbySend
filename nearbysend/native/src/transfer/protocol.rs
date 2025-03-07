use crate::api::FileTransfer;
use crate::api::TransferStatus;
use crate::connection::wifi_direct::{send_data, receive_data};
use serde::{Deserialize, Serialize};
use std::fs::File;
use std::io::{Read, Write};
use std::path::Path;
use std::sync::{Arc, Mutex};
use tokio::time;
use uuid::Uuid;

// 传输消息类型
#[derive(Serialize, Deserialize, Debug)]
enum TransferMessage {
    // 传输请求
    TransferRequest {
        id: String,
        file_name: String,
        file_size: u64,
    },
    // 传输响应
    TransferResponse {
        id: String,
        accepted: bool,
    },
    // 数据块
    DataChunk {
        id: String,
        chunk_index: u32,
        data: Vec<u8>,
        is_last: bool,
    },
    // 确认接收
    ChunkAck {
        id: String,
        chunk_index: u32,
    },
    // 传输完成
    TransferComplete {
        id: String,
        success: bool,
    },
}

// 全局传输状态
lazy_static::lazy_static! {
    static ref CURRENT_TRANSFERS: Arc<Mutex<Vec<FileTransfer>>> = Arc::new(Mutex::new(Vec::new()));
}

// 发送文件
pub async fn send_file(file_path: &str) -> Result<String, String> {
    // 检查文件是否存在
    let path = Path::new(file_path);
    if !path.exists() {
        return Err(format!("File not found: {}", file_path));
    }
    
    // 获取文件信息
    let file_name = path.file_name()
        .ok_or_else(|| "Invalid file name".to_string())?
        .to_string_lossy()
        .to_string();
    
    let file_size = std::fs::metadata(path)
        .map_err(|e| format!("Failed to get file metadata: {}", e))?
        .len();
    
    // 创建传输ID
    let transfer_id = Uuid::new_v4().to_string();
    
    // 创建传输对象
    let transfer = FileTransfer {
        id: transfer_id.clone(),
        file_name: file_name.clone(),
        file_size,
        transferred_bytes: 0,
        status: TransferStatus::Pending,
    };
    
    // 添加到传输列表
    {
        let mut transfers = CURRENT_TRANSFERS.lock().map_err(|e| e.to_string())?;
        transfers.push(transfer);
    }
    
    // 创建传输请求
    let request = TransferMessage::TransferRequest {
        id: transfer_id.clone(),
        file_name,
        file_size,
    };
    
    // 序列化请求
    let request_data = serde_json::to_vec(&request).map_err(|e| e.to_string())?;
    
    // 发送请求
    send_data(&request_data).await?;
    
    // 更新传输状态
    update_transfer_status(&transfer_id, TransferStatus::Connecting)?;
    
    // 等待响应
    let response_data = receive_data(1024).await?;
    let response: TransferMessage = serde_json::from_slice(&response_data).map_err(|e| e.to_string())?;
    
    match response {
        TransferMessage::TransferResponse { id, accepted } if id == transfer_id => {
            if accepted {
                // 开始传输文件
                tokio::spawn(async move {
                    if let Err(e) = send_file_chunks(file_path, &transfer_id).await {
                        log::error!("Failed to send file: {}", e);
                        if let Err(e) = update_transfer_status(&transfer_id, TransferStatus::Failed) {
                            log::error!("Failed to update transfer status: {}", e);
                        }
                    }
                });
                
                Ok(transfer_id)
            } else {
                update_transfer_status(&transfer_id, TransferStatus::Failed)?;
                Err("Transfer rejected by receiver".to_string())
            }
        }
        _ => {
            update_transfer_status(&transfer_id, TransferStatus::Failed)?;
            Err("Invalid response from receiver".to_string())
        }
    }
}

// 接收文件
pub async fn receive_file(save_dir: &str) -> Result<String, String> {
    // 接收传输请求
    let request_data = receive_data(1024).await?;
    let request: TransferMessage = serde_json::from_slice(&request_data).map_err(|e| e.to_string())?;
    
    match request {
        TransferMessage::TransferRequest { id, file_name, file_size } => {
            // 创建传输对象
            let transfer = FileTransfer {
                id: id.clone(),
                file_name: file_name.clone(),
                file_size,
                transferred_bytes: 0,
                status: TransferStatus::Pending,
            };
            
            // 添加到传输列表
            {
                let mut transfers = CURRENT_TRANSFERS.lock().map_err(|e| e.to_string())?;
                transfers.push(transfer);
            }
            
            // 创建保存路径
            let save_path = Path::new(save_dir).join(&file_name);
            
            // 创建响应
            let response = TransferMessage::TransferResponse {
                id: id.clone(),
                accepted: true,
            };
            
            // 序列化响应
            let response_data = serde_json::to_vec(&response).map_err(|e| e.to_string())?;
            
            // 发送响应
            send_data(&response_data).await?;
            
            // 更新传输状态
            update_transfer_status(&id, TransferStatus::Transferring)?;
            
            // 开始接收文件
            tokio::spawn(async move {
                if let Err(e) = receive_file_chunks(&id, save_path.to_string_lossy().to_string()).await {
                    log::error!("Failed to receive file: {}", e);
                    if let Err(e) = update_transfer_status(&id, TransferStatus::Failed) {
                        log::error!("Failed to update transfer status: {}", e);
                    }
                }
            });
            
            Ok(id)
        }
        _ => Err("Invalid request from sender".to_string()),
    }
}

// 发送文件块
async fn send_file_chunks(file_path: &str, transfer_id: &str) -> Result<(), String> {
    // 打开文件
    let mut file = File::open(file_path).map_err(|e| format!("Failed to open file: {}", e))?;
    
    // 获取文件大小
    let file_size = file.metadata().map_err(|e| format!("Failed to get file metadata: {}", e))?.len();
    
    // 更新传输状态
    update_transfer_status(transfer_id, TransferStatus::Transferring)?;
    
    // 设置块大小
    const CHUNK_SIZE: usize = 64 * 1024; // 64KB
    
    // 创建缓冲区
    let mut buffer = vec![0u8; CHUNK_SIZE];
    let mut transferred: u64 = 0;
    let mut chunk_index: u32 = 0;
    
    // 循环发送文件块
    loop {
        // 读取文件块
        let n = file.read(&mut buffer).map_err(|e| format!("Failed to read file: {}", e))?;
        
        if n == 0 {
            // 文件已读取完毕
            break;
        }
        
        // 是否为最后一块
        let is_last = transferred + n as u64 >= file_size;
        
        // 创建数据块消息
        let chunk = TransferMessage::DataChunk {
            id: transfer_id.to_string(),
            chunk_index,
            data: buffer[..n].to_vec(),
            is_last,
        };
        
        // 序列化数据块
        let chunk_data = serde_json::to_vec(&chunk).map_err(|e| e.to_string())?;
        
        // 发送数据块
        send_data(&chunk_data).await?;
        
        // 等待确认
        let ack_data = receive_data(1024).await?;
        let ack: TransferMessage = serde_json::from_slice(&ack_data).map_err(|e| e.to_string())?;
        
        match ack {
            TransferMessage::ChunkAck { id, chunk_index: ack_index } if id == transfer_id && ack_index == chunk_index => {
                // 更新传输进度
                transferred += n as u64;
                update_transfer_progress(transfer_id, transferred)?;
                
                // 增加块索引
                chunk_index += 1;
                
                // 如果是最后一块，发送传输完成消息
                if is_last {
                    let complete = TransferMessage::TransferComplete {
                        id: transfer_id.to_string(),
                        success: true,
                    };
                    
                    let complete_data = serde_json::to_vec(&complete).map_err(|e| e.to_string())?;
                    send_data(&complete_data).await?;
                    
                    // 更新传输状态
                    update_transfer_status(transfer_id, TransferStatus::Completed)?;
                    
                    break;
                }
            }
            _ => {
                return Err("Invalid acknowledgment from receiver".to_string());
            }
        }
    }
    
    Ok(())
}

// 接收文件块
async fn receive_file_chunks(transfer_id: &str, save_path: String) -> Result<(), String> {
    // 创建文件
    let mut file = File::create(&save_path).map_err(|e| format!("Failed to create file: {}", e))?;
    
    // 更新传输状态
    update_transfer_status(transfer_id, TransferStatus::Transferring)?;
    
    let mut transferred: u64 = 0;
    let mut expected_chunk_index: u32 = 0;
    
    // 循环接收文件块
    loop {
        // 接收数据块
        let chunk_data = receive_data(1024 * 1024).await?; // 允许接收更大的数据块
        let chunk: TransferMessage = serde_json::from_slice(&chunk_data).map_err(|e| e.to_string())?;
        
        match chunk {
            TransferMessage::DataChunk { id, chunk_index, data, is_last } if id == transfer_id => {
                if chunk_index != expected_chunk_index {
                    return Err(format!("Unexpected chunk index: expected {}, got {}", expected_chunk_index, chunk_index));
                }
                
                // 写入文件
                file.write_all(&data).map_err(|e| format!("Failed to write to file: {}", e))?;
                
                // 更新传输进度
                transferred += data.len() as u64;
                update_transfer_progress(transfer_id, transferred)?;
                
                // 发送确认
                let ack = TransferMessage::ChunkAck {
                    id: transfer_id.to_string(),
                    chunk_index,
                };
                
                let ack_data = serde_json::to_vec(&ack).map_err(|e| e.to_string())?;
                send_data(&ack_data).await?;
                
                // 增加期望的块索引
                expected_chunk_index += 1;
                
                // 如果是最后一块，等待传输完成消息
                if is_last {
                    let complete_data = receive_data(1024).await?;
                    let complete: TransferMessage = serde_json::from_slice(&complete_data).map_err(|e| e.to_string())?;
                    
                    match complete {
                        TransferMessage::TransferComplete { id, success } if id == transfer_id && success => {
                            // 更新传输状态
                            update_transfer_status(transfer_id, TransferStatus::Completed)?;
                            
                            // 关闭文件
                            drop(file);
                            
                            break;
                        }
                        _ => {
                            return Err("Invalid completion message from sender".to_string());
                        }
                    }
                }
            }
            TransferMessage::TransferComplete { id, success } if id == transfer_id => {
                if success {
                    // 更新传输状态
                    update_transfer_status(transfer_id, TransferStatus::Completed)?;
                    
                    // 关闭文件
                    drop(file);
                    
                    break;
                } else {
                    return Err("Transfer failed".to_string());
                }
            }
            _ => {
                return Err("Invalid message from sender".to_string());
            }
        }
    }
    
    Ok(())
}

// 更新传输状态
fn update_transfer_status(transfer_id: &str, status: TransferStatus) -> Result<(), String> {
    let mut transfers = CURRENT_TRANSFERS.lock().map_err(|e| e.to_string())?;
    
    for transfer in transfers.iter_mut() {
        if transfer.id == transfer_id {
            transfer.status = status;
            return Ok(());
        }
    }
    
    Err(format!("Transfer not found: {}", transfer_id))
}

// 更新传输进度
fn update_transfer_progress(transfer_id: &str, transferred_bytes: u64) -> Result<(), String> {
    let mut transfers = CURRENT_TRANSFERS.lock().map_err(|e| e.to_string())?;
    
    for transfer in transfers.iter_mut() {
        if transfer.id == transfer_id {
            transfer.transferred_bytes = transferred_bytes;
            return Ok(());
        }
    }
    
    Err(format!("Transfer not found: {}", transfer_id))
}

// 获取当前传输列表
pub fn get_transfers() -> Result<Vec<FileTransfer>, String> {
    let transfers = CURRENT_TRANSFERS.lock().map_err(|e| e.to_string())?;
    Ok(transfers.clone())
}
