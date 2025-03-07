import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nearbysend/core/models/file_transfer.dart';
import 'package:nearbysend/shared/constants/app_constants.dart';
import 'package:path_provider/path_provider.dart';

/// 文件传输服务提供者
final fileTransferServiceProvider = Provider<FileTransferService>((ref) {
  return FileTransferService();
});

/// 文件传输服务
class FileTransferService {
  NearbyService? _nearbyService;
  String? _currentDeviceId;
  
  final List<FileTransfer> _transfers = [];
  final StreamController<List<FileTransfer>> _transfersStreamController = StreamController<List<FileTransfer>>.broadcast();
  
  Stream<List<FileTransfer>> get transfersStream => _transfersStreamController.stream;
  
  /// 初始化传输服务
  Future<void> initialize(String deviceId) async {
    _currentDeviceId = deviceId;
    
    // 监听文件接收
    _nearbyService?.dataReceivedSubscription?.onData((data) {
      _handleDataReceived(data);
    });
  }
  
  /// 发送文件
  Future<void> sendFile(String filePath, String fileName, int fileSize) async {
    if (_currentDeviceId == null || _nearbyService == null) {
      throw Exception('传输服务未初始化');
    }
    
    // 创建传输任务
    final transfer = FileTransfer.create(
      fileName: fileName,
      filePath: filePath,
      fileSize: fileSize,
      direction: TransferDirection.sending,
      deviceId: _currentDeviceId!,
    );
    
    _transfers.add(transfer);
    _notifyTransfersChanged();
    
    try {
      // 读取文件
      final file = File(filePath);
      final fileBytes = await file.readAsBytes();
      
      // 分块发送
      const chunkSize = AppConstants.transferChunkSize;
      final totalChunks = (fileBytes.length / chunkSize).ceil();
      
      // 发送文件元数据
      final metaData = {
        'type': 'file_meta',
        'transferId': transfer.id,
        'fileName': fileName,
        'fileSize': fileSize,
        'totalChunks': totalChunks,
      };
      
      await _nearbyService?.sendMessage(
        _currentDeviceId!,
        metaData.toString(),
      );
      
      // 分块发送文件
      for (var i = 0; i < totalChunks; i++) {
        final start = i * chunkSize;
        final end = min((i + 1) * chunkSize, fileBytes.length);
        final chunk = fileBytes.sublist(start, end);
        
        // 发送块数据
        final chunkData = {
          'type': 'file_chunk',
          'transferId': transfer.id,
          'chunkIndex': i,
          'data': chunk,
        };
        
        await _nearbyService?.sendMessage(
          _currentDeviceId!,
          chunkData.toString(),
        );
        
        // 更新进度
        final progress = (i + 1) / totalChunks;
        _updateTransferProgress(transfer.id, progress);
        
        // 模拟网络延迟
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      // 发送完成通知
      final completeData = {
        'type': 'file_complete',
        'transferId': transfer.id,
      };
      
      await _nearbyService?.sendMessage(
        _currentDeviceId!,
        completeData.toString(),
      );
      
      // 标记为完成
      _updateTransferProgress(transfer.id, 1.0);
    } catch (e) {
      // 标记为失败
      _updateTransferStatus(transfer.id, TransferStatus.failed, error: e.toString());
    }
  }
  
  /// 取消传输
  Future<void> cancelTransfer(String transferId) async {
    final index = _transfers.indexWhere((t) => t.id == transferId);
    if (index >= 0) {
      final transfer = _transfers[index];
      _transfers[index] = transfer.markAsCanceled();
      _notifyTransfersChanged();
      
      // 发送取消通知
      if (_currentDeviceId != null && _nearbyService != null) {
        final cancelData = {
          'type': 'file_cancel',
          'transferId': transferId,
        };
        
        await _nearbyService?.sendMessage(
          _currentDeviceId!,
          cancelData.toString(),
        );
      }
    }
  }
  
  /// 暂停传输
  Future<void> pauseTransfer(String transferId) async {
    final index = _transfers.indexWhere((t) => t.id == transferId);
    if (index >= 0) {
      final transfer = _transfers[index];
      _transfers[index] = transfer.markAsPaused();
      _notifyTransfersChanged();
      
      // 发送暂停通知
      if (_currentDeviceId != null && _nearbyService != null) {
        final pauseData = {
          'type': 'file_pause',
          'transferId': transferId,
        };
        
        await _nearbyService?.sendMessage(
          _currentDeviceId!,
          pauseData.toString(),
        );
      }
    }
  }
  
  /// 恢复传输
  Future<void> resumeTransfer(String transferId) async {
    final index = _transfers.indexWhere((t) => t.id == transferId);
    if (index >= 0) {
      final transfer = _transfers[index];
      _transfers[index] = transfer.markAsResumed();
      _notifyTransfersChanged();
      
      // 发送恢复通知
      if (_currentDeviceId != null && _nearbyService != null) {
        final resumeData = {
          'type': 'file_resume',
          'transferId': transferId,
        };
        
        await _nearbyService?.sendMessage(
          _currentDeviceId!,
          resumeData.toString(),
        );
      }
    }
  }
  
  /// 处理接收到的数据
  void _handleDataReceived(dynamic data) {
    try {
      final Map<String, dynamic> message = data;
      final type = message['type'] as String;
      
      switch (type) {
        case 'file_meta':
          _handleFileMetadata(message);
          break;
        case 'file_chunk':
          _handleFileChunk(message);
          break;
        case 'file_complete':
          _handleFileComplete(message);
          break;
        case 'file_cancel':
          _handleFileCancel(message);
          break;
        case 'file_pause':
          _handleFilePause(message);
          break;
        case 'file_resume':
          _handleFileResume(message);
          break;
      }
    } catch (e) {
      // 处理解析错误
    }
  }
  
  /// 处理文件元数据
  Future<void> _handleFileMetadata(Map<String, dynamic> message) async {
    final transferId = message['transferId'] as String;
    final fileName = message['fileName'] as String;
    final fileSize = message['fileSize'] as int;
    final totalChunks = message['totalChunks'] as int;
    
    // 创建临时文件
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/$fileName';
    
    // 创建传输任务
    final transfer = FileTransfer.create(
      fileName: fileName,
      filePath: filePath,
      fileSize: fileSize,
      direction: TransferDirection.receiving,
      deviceId: _currentDeviceId!,
    );
    
    _transfers.add(transfer);
    _notifyTransfersChanged();
  }
  
  /// 处理文件块
  Future<void> _handleFileChunk(Map<String, dynamic> message) async {
    final transferId = message['transferId'] as String;
    final chunkIndex = message['chunkIndex'] as int;
    final data = message['data'] as List<int>;
    
    final index = _transfers.indexWhere((t) => t.id == transferId);
    if (index >= 0) {
      final transfer = _transfers[index];
      
      // 写入文件块
      final file = File(transfer.filePath);
      final raf = await file.open(mode: FileMode.append);
      await raf.writeFrom(data);
      await raf.close();
      
      // 更新进度
      final totalChunks = (transfer.fileSize / AppConstants.transferChunkSize).ceil();
      final progress = (chunkIndex + 1) / totalChunks;
      _updateTransferProgress(transferId, progress);
    }
  }
  
  /// 处理文件完成
  void _handleFileComplete(Map<String, dynamic> message) {
    final transferId = message['transferId'] as String;
    _updateTransferProgress(transferId, 1.0);
  }
  
  /// 处理文件取消
  void _handleFileCancel(Map<String, dynamic> message) {
    final transferId = message['transferId'] as String;
    _updateTransferStatus(transferId, TransferStatus.canceled);
  }
  
  /// 处理文件暂停
  void _handleFilePause(Map<String, dynamic> message) {
    final transferId = message['transferId'] as String;
    _updateTransferStatus(transferId, TransferStatus.paused);
  }
  
  /// 处理文件恢复
  void _handleFileResume(Map<String, dynamic> message) {
    final transferId = message['transferId'] as String;
    _updateTransferStatus(transferId, TransferStatus.inProgress);
  }
  
  /// 更新传输进度
  void _updateTransferProgress(String transferId, double progress) {
    final index = _transfers.indexWhere((t) => t.id == transferId);
    if (index >= 0) {
      final transfer = _transfers[index];
      _transfers[index] = transfer.updateProgress(progress);
      _notifyTransfersChanged();
    }
  }
  
  /// 更新传输状态
  void _updateTransferStatus(String transferId, TransferStatus status, {String? error}) {
    final index = _transfers.indexWhere((t) => t.id == transferId);
    if (index >= 0) {
      final transfer = _transfers[index];
      
      switch (status) {
        case TransferStatus.failed:
          _transfers[index] = transfer.markAsFailed(error ?? '未知错误');
          break;
        case TransferStatus.canceled:
          _transfers[index] = transfer.markAsCanceled();
          break;
        case TransferStatus.paused:
          _transfers[index] = transfer.markAsPaused();
          break;
        case TransferStatus.inProgress:
          _transfers[index] = transfer.markAsResumed();
          break;
        default:
          _transfers[index] = transfer.copyWith(status: status);
          break;
      }
      
      _notifyTransfersChanged();
    }
  }
  
  /// 通知传输状态变化
  void _notifyTransfersChanged() {
    _transfersStreamController.add(_transfers);
  }
  
  /// 清理资源
  void dispose() {
    _transfersStreamController.close();
  }
} 