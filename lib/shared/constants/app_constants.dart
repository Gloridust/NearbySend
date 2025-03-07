/// 应用常量
class AppConstants {
  // 应用名称
  static const appName = 'NearbySend';
  
  // 服务标识符
  static const serviceId = 'com.nearbysend.service';
  
  // 蓝牙服务UUID
  static const serviceUuid = '00001234-0000-1000-8000-00805f9b34fb';
  
  // 文件传输端口
  static const transferPort = 45678;
  
  // 设备发现超时时间（秒）
  static const discoveryTimeout = 30;
  
  // 文件传输块大小
  static const transferChunkSize = 1024 * 1024; // 1MB
  
  // 最大重试次数
  static const maxRetries = 3;
} 