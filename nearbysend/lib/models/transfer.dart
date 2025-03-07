import 'package:flutter/foundation.dart';

/// 传输状态枚举
enum TransferStatus {
  pending,
  connecting,
  transferring,
  completed,
  failed,
}

/// 文件传输模型
class FileTransfer {
  /// 传输ID
  final String id;
  
  /// 文件名
  final String fileName;
  
  /// 文件大小（字节）
  final int fileSize;
  
  /// 已传输字节数
  final int transferredBytes;
  
  /// 传输状态
  final TransferStatus status;
  
  /// 目标保存路径
  final String? targetPath;
  
  /// 构造函数
  const FileTransfer({
    required this.id,
    required this.fileName,
    required this.fileSize,
    this.transferredBytes = 0,
    this.status = TransferStatus.pending,
    this.targetPath,
  });
  
  /// 复制并修改
  FileTransfer copyWith({
    String? id,
    String? fileName,
    int? fileSize,
    int? transferredBytes,
    TransferStatus? status,
    String? targetPath,
  }) {
    return FileTransfer(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      transferredBytes: transferredBytes ?? this.transferredBytes,
      status: status ?? this.status,
      targetPath: targetPath ?? this.targetPath,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is FileTransfer &&
        other.id == id &&
        other.fileName == fileName &&
        other.fileSize == fileSize &&
        other.transferredBytes == transferredBytes &&
        other.status == status &&
        other.targetPath == targetPath;
  }
  
  @override
  int get hashCode {
    return id.hashCode ^
        fileName.hashCode ^
        fileSize.hashCode ^
        transferredBytes.hashCode ^
        status.hashCode ^
        targetPath.hashCode;
  }
}

/// 文件传输扩展方法
extension FileTransferExtension on FileTransfer {
  /// 获取传输进度百分比
  double get progressPercentage {
    if (fileSize == 0) return 0;
    return (transferredBytes / fileSize) * 100;
  }

  /// 获取传输状态文本
  String get statusText {
    switch (status) {
      case TransferStatus.pending:
        return '等待中';
      case TransferStatus.connecting:
        return '连接中';
      case TransferStatus.transferring:
        return '传输中 (${progressPercentage.toStringAsFixed(1)}%)';
      case TransferStatus.completed:
        return '已完成';
      case TransferStatus.failed:
        return '失败';
    }
  }

  /// 获取文件大小文本
  String get fileSizeText {
    const int kb = 1024;
    const int mb = kb * 1024;
    const int gb = mb * 1024;

    if (fileSize < kb) {
      return '$fileSize B';
    } else if (fileSize < mb) {
      return '${(fileSize / kb).toStringAsFixed(1)} KB';
    } else if (fileSize < gb) {
      return '${(fileSize / mb).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSize / gb).toStringAsFixed(1)} GB';
    }
  }

  /// 获取传输速度文本
  String getSpeedText(Duration elapsed) {
    if (elapsed.inSeconds == 0) return '0 KB/s';
    
    final bytesPerSecond = transferredBytes / elapsed.inSeconds;
    const int kb = 1024;
    const int mb = kb * 1024;
    
    if (bytesPerSecond < kb) {
      return '${bytesPerSecond.toStringAsFixed(1)} B/s';
    } else if (bytesPerSecond < mb) {
      return '${(bytesPerSecond / kb).toStringAsFixed(1)} KB/s';
    } else {
      return '${(bytesPerSecond / mb).toStringAsFixed(1)} MB/s';
    }
  }
}
