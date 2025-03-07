import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nearbysend/core/models/device.dart';
import 'package:nearbysend/core/models/file_transfer.dart';
import 'package:nearbysend/features/device_discovery/domain/device_discovery_service.dart';
import 'package:nearbysend/features/file_transfer/domain/file_transfer_service.dart';

/// 设备名称提供者
final deviceNameProvider = Provider.family<String, String>((ref, deviceId) {
  final deviceDiscoveryService = ref.read(deviceDiscoveryServiceProvider);
  final devices = deviceDiscoveryService._discoveredDevices;
  final device = devices.firstWhere(
    (d) => d.id == deviceId,
    orElse: () => Device(
      id: deviceId,
      name: '未知设备',
      type: DeviceType.unknown,
      address: '',
    ),
  );
  return device.name;
});

/// 文件传输状态提供者
final fileTransferProvider = AsyncNotifierProvider<FileTransferNotifier, List<FileTransfer>>(() {
  return FileTransferNotifier();
});

/// 文件传输状态管理
class FileTransferNotifier extends AsyncNotifier<List<FileTransfer>> {
  late final FileTransferService _transferService;

  @override
  Future<List<FileTransfer>> build() async {
    _transferService = ref.read(fileTransferServiceProvider);
    return [];
  }

  /// 初始化文件传输
  Future<void> initialize(String deviceId) async {
    state = const AsyncValue.loading();
    
    try {
      // 连接到设备
      final deviceDiscoveryService = ref.read(deviceDiscoveryServiceProvider);
      final connected = await deviceDiscoveryService.connectToDevice(deviceId);
      
      if (!connected) {
        state = AsyncValue.error('无法连接到设备', StackTrace.current);
        return;
      }
      
      // 初始化传输服务
      await _transferService.initialize(deviceId);
      
      // 监听传输状态变化
      _transferService.transfersStream.listen((transfers) {
        state = AsyncValue.data(transfers);
      });
      
      state = AsyncValue.data([]);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// 发送文件
  Future<void> sendFile(String filePath, String fileName) async {
    try {
      final file = File(filePath);
      final fileSize = await file.length();
      
      await _transferService.sendFile(filePath, fileName, fileSize);
    } catch (e) {
      // 处理错误
    }
  }

  /// 取消传输
  Future<void> cancelTransfer(String transferId) async {
    await _transferService.cancelTransfer(transferId);
  }

  /// 暂停传输
  Future<void> pauseTransfer(String transferId) async {
    await _transferService.pauseTransfer(transferId);
  }

  /// 恢复传输
  Future<void> resumeTransfer(String transferId) async {
    await _transferService.resumeTransfer(transferId);
  }

  /// 清理资源
  void dispose() {
    _transferService.dispose();
  }
} 