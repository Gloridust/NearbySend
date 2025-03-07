use std::fs::File;
use std::io::{Read, Seek, SeekFrom, Write};
use std::path::Path;

// 默认块大小
pub const DEFAULT_CHUNK_SIZE: usize = 64 * 1024; // 64KB

// 文件分块器
pub struct FileChunker {
    file: File,
    chunk_size: usize,
    file_size: u64,
    current_position: u64,
}

impl FileChunker {
    // 创建新的文件分块器
    pub fn new(file_path: &str, chunk_size: Option<usize>) -> Result<Self, String> {
        let file = File::open(file_path).map_err(|e| format!("Failed to open file: {}", e))?;
        let file_size = file.metadata().map_err(|e| format!("Failed to get file metadata: {}", e))?.len();
        
        Ok(Self {
            file,
            chunk_size: chunk_size.unwrap_or(DEFAULT_CHUNK_SIZE),
            file_size,
            current_position: 0,
        })
    }
    
    // 获取文件大小
    pub fn file_size(&self) -> u64 {
        self.file_size
    }
    
    // 获取当前位置
    pub fn current_position(&self) -> u64 {
        self.current_position
    }
    
    // 获取进度百分比
    pub fn progress_percentage(&self) -> f64 {
        if self.file_size == 0 {
            return 100.0;
        }
        
        (self.current_position as f64 / self.file_size as f64) * 100.0
    }
    
    // 是否已完成
    pub fn is_complete(&self) -> bool {
        self.current_position >= self.file_size
    }
    
    // 读取下一个块
    pub fn next_chunk(&mut self) -> Result<Option<Vec<u8>>, String> {
        if self.is_complete() {
            return Ok(None);
        }
        
        let mut buffer = vec![0u8; self.chunk_size];
        
        // 设置文件位置
        self.file.seek(SeekFrom::Start(self.current_position)).map_err(|e| format!("Failed to seek file: {}", e))?;
        
        // 读取数据
        let bytes_read = self.file.read(&mut buffer).map_err(|e| format!("Failed to read file: {}", e))?;
        
        if bytes_read == 0 {
            return Ok(None);
        }
        
        // 更新位置
        self.current_position += bytes_read as u64;
        
        // 调整缓冲区大小
        buffer.truncate(bytes_read);
        
        Ok(Some(buffer))
    }
    
    // 重置位置
    pub fn reset(&mut self) -> Result<(), String> {
        self.current_position = 0;
        self.file.seek(SeekFrom::Start(0)).map_err(|e| format!("Failed to seek file: {}", e))?;
        Ok(())
    }
}

// 文件组装器
pub struct FileAssembler {
    file: File,
    file_path: String,
    expected_size: u64,
    current_size: u64,
}

impl FileAssembler {
    // 创建新的文件组装器
    pub fn new(file_path: &str, expected_size: u64) -> Result<Self, String> {
        // 确保目录存在
        if let Some(parent) = Path::new(file_path).parent() {
            if !parent.exists() {
                std::fs::create_dir_all(parent).map_err(|e| format!("Failed to create directory: {}", e))?;
            }
        }
        
        let file = File::create(file_path).map_err(|e| format!("Failed to create file: {}", e))?;
        
        Ok(Self {
            file,
            file_path: file_path.to_string(),
            expected_size,
            current_size: 0,
        })
    }
    
    // 获取预期大小
    pub fn expected_size(&self) -> u64 {
        self.expected_size
    }
    
    // 获取当前大小
    pub fn current_size(&self) -> u64 {
        self.current_size
    }
    
    // 获取进度百分比
    pub fn progress_percentage(&self) -> f64 {
        if self.expected_size == 0 {
            return 100.0;
        }
        
        (self.current_size as f64 / self.expected_size as f64) * 100.0
    }
    
    // 是否已完成
    pub fn is_complete(&self) -> bool {
        self.current_size >= self.expected_size
    }
    
    // 写入块
    pub fn write_chunk(&mut self, chunk: &[u8], position: Option<u64>) -> Result<(), String> {
        if let Some(pos) = position {
            // 设置文件位置
            self.file.seek(SeekFrom::Start(pos)).map_err(|e| format!("Failed to seek file: {}", e))?;
        }
        
        // 写入数据
        self.file.write_all(chunk).map_err(|e| format!("Failed to write to file: {}", e))?;
        
        // 更新大小
        self.current_size += chunk.len() as u64;
        
        Ok(())
    }
    
    // 完成组装
    pub fn finish(self) -> Result<String, String> {
        // 关闭文件
        drop(self.file);
        
        // 检查大小
        if self.current_size != self.expected_size {
            return Err(format!("File size mismatch: expected {}, got {}", self.expected_size, self.current_size));
        }
        
        Ok(self.file_path)
    }
}
