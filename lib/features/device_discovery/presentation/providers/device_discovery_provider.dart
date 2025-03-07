import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nearbysend/core/models/device.dart';
import 'package:nearbysend/features/device_discovery/domain/device_discovery_service.dart';

/// 设备发现状态提供者
final deviceDiscoveryProvider = AsyncNotifierProvider<DeviceDiscoveryNotifier, List<Device>>(() {
  return DeviceDiscoveryNotifier();
});

/// 设备发现状态管理
class DeviceDiscoveryNotifier extends AsyncNotifier<List<Device>> {
  late final DeviceDiscoveryService _discoveryService;

  @override
  Future<List<Device>> build() async {
    _discoveryService = ref.read(deviceDiscoveryServiceProvider);
    return [];
  }

  /// 开始设备发现
  Future<void> startDiscovery() async {
    state = const AsyncValue.loading();
    
    try {
      // 请求必要的权限
      final hasPermissions = await _discoveryService.requestPermissions();
      if (!hasPermissions) {
        state = AsyncValue.error('权限被拒绝', StackTrace.current);
        return;
      }
      
      // 开始设备发现
      final devices = await _discoveryService.startDiscovery();
      state = AsyncValue.data(devices);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// 停止设备发现
  Future<void> stopDiscovery() async {
    try {
      await _discoveryService.stopDiscovery();
    } catch (e) {
      // 忽略停止时的错误
    }
  }

  /// 连接到设备
  Future<bool> connectToDevice(String deviceId) async {
    try {
      final success = await _discoveryService.connectToDevice(deviceId);
      if (success) {
        // 更新设备连接状态
        state = AsyncValue.data(
          state.value!.map((device) {
            if (device.id == deviceId) {
              return device.copyWith(isConnected: true);
            }
            return device;
          }).toList(),
        );
      }
      return success;
    } catch (e) {
      return false;
    }
  }
} 