import 'package:uuid/uuid.dart';

/// 文件传输状态枚举
enum TransferStatus {
  pending,    // 等待中
  inProgress, // 传输中
  completed,  // 已完成
  failed,     // 失败
  canceled,   // 已取消
  paused,     // 已暂停
}

/// 传输方向枚举
enum TransferDirection {
  sending,   // 发送
  receiving, // 接收
}

/// 文件传输模型
class FileTransfer {
  /// 传输ID
  final String id;
  
  /// 文件名
  final String fileName;
  
  /// 文件路径
  final String filePath;
  
  /// 文件大小（字节）
  final int fileSize;
  
  /// 传输进度（0.0 - 1.0）
  final double progress;
  
  /// 传输状态
  final TransferStatus status;
  
  /// 传输方向
  final TransferDirection direction;
  
  /// 目标设备ID
  final String deviceId;
  
  /// 错误信息（如果有）
  final String? error;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 完成时间
  final DateTime? completedAt;

  const FileTransfer({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.progress,
    required this.status,
    required this.direction,
    required this.deviceId,
    this.error,
    required this.createdAt,
    this.completedAt,
  });

  /// 创建新的传输任务
  factory FileTransfer.create({
    required String fileName,
    required String filePath,
    required int fileSize,
    required TransferDirection direction,
    required String deviceId,
  }) {
    return FileTransfer(
      id: const Uuid().v4(),
      fileName: fileName,
      filePath: filePath,
      fileSize: fileSize,
      progress: 0.0,
      status: TransferStatus.pending,
      direction: direction,
      deviceId: deviceId,
      createdAt: DateTime.now(),
    );
  }

  /// 从JSON创建传输任务
  factory FileTransfer.fromJson(Map<String, dynamic> json) {
    return FileTransfer(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      filePath: json['filePath'] as String,
      fileSize: json['fileSize'] as int,
      progress: json['progress'] as double,
      status: TransferStatus.values.firstWhere(
        (e) => e.toString() == 'TransferStatus.${json['status']}',
      ),
      direction: TransferDirection.values.firstWhere(
        (e) => e.toString() == 'TransferDirection.${json['direction']}',
      ),
      deviceId: json['deviceId'] as String,
      error: json['error'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'fileSize': fileSize,
      'progress': progress,
      'status': status.toString().split('.').last,
      'direction': direction.toString().split('.').last,
      'deviceId': deviceId,
      'error': error,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  /// 创建一个新的传输任务实例，但更新部分属性
  FileTransfer copyWith({
    String? id,
    String? fileName,
    String? filePath,
    int? fileSize,
    double? progress,
    TransferStatus? status,
    TransferDirection? direction,
    String? deviceId,
    String? error,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return FileTransfer(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      direction: direction ?? this.direction,
      deviceId: deviceId ?? this.deviceId,
      error: error ?? this.error,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// 更新进度
  FileTransfer updateProgress(double newProgress) {
    return copyWith(
      progress: newProgress,
      status: newProgress >= 1.0 ? TransferStatus.completed : TransferStatus.inProgress,
      completedAt: newProgress >= 1.0 ? DateTime.now() : null,
    );
  }

  /// 标记为失败
  FileTransfer markAsFailed(String errorMessage) {
    return copyWith(
      status: TransferStatus.failed,
      error: errorMessage,
    );
  }

  /// 标记为取消
  FileTransfer markAsCanceled() {
    return copyWith(
      status: TransferStatus.canceled,
    );
  }

  /// 标记为暂停
  FileTransfer markAsPaused() {
    return copyWith(
      status: TransferStatus.paused,
    );
  }

  /// 标记为继续
  FileTransfer markAsResumed() {
    return copyWith(
      status: TransferStatus.inProgress,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FileTransfer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 