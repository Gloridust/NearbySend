import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nearbysend/models/device.dart';
import 'package:nearbysend/models/transfer.dart';
import 'package:nearbysend/services/bridge_service.dart';

/// 桥接服务提供者
final bridgeServiceProvider = Provider<BridgeService>((ref) {
  final service = BridgeService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

/// 设备列表提供者
final devicesProvider = StreamProvider<List<Device>>((ref) {
  final bridgeService = ref.watch(bridgeServiceProvider);
  return bridgeService.deviceStream;
});

/// 传输列表提供者
final transfersProvider = StreamProvider<List<FileTransfer>>((ref) {
  final bridgeService = ref.watch(bridgeServiceProvider);
  return bridgeService.transferStream;
});

/// 设备名称提供者
final deviceNameProvider = FutureProvider<String>((ref) async {
  final bridgeService = ref.watch(bridgeServiceProvider);
  return await bridgeService.getDeviceName();
});

/// 下载路径提供者
final downloadPathProvider = FutureProvider<String>((ref) async {
  final bridgeService = ref.watch(bridgeServiceProvider);
  return await bridgeService.getDownloadPath();
});

/// 是否自动接收文件提供者
final autoReceiveProvider = StateProvider<bool>((ref) => false);

/// 是否显示通知提供者
final showNotificationsProvider = StateProvider<bool>((ref) => true);

/// 是否保持屏幕常亮提供者
final keepScreenOnProvider = StateProvider<bool>((ref) => false);

/// 是否使用蓝牙提供者
final useBluetoothProvider = StateProvider<bool>((ref) => true);

/// 是否使用WiFi提供者
final useWifiProvider = StateProvider<bool>((ref) => true);

/// 平台类型提供者
final platformTypeProvider = Provider<DeviceType>((ref) {
  if (Platform.isAndroid) {
    return DeviceType.android;
  } else if (Platform.isIOS) {
    return DeviceType.ios;
  } else if (Platform.isMacOS) {
    return DeviceType.macos;
  } else if (Platform.isWindows) {
    return DeviceType.windows;
  } else {
    return DeviceType.unknown;
  }
}); 