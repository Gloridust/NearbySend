import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nearbysend/features/settings/domain/settings_service.dart';
import 'package:path_provider/path_provider.dart';

/// 设置状态提供者
final settingsProvider = NotifierProvider<SettingsNotifier, Settings>(() {
  return SettingsNotifier();
});

/// 设置状态管理
class SettingsNotifier extends Notifier<Settings> {
  late final SettingsService _settingsService;

  @override
  Settings build() {
    _settingsService = ref.read(settingsServiceProvider);
    return _settingsService.getSettings();
  }

  /// 更新设备名称
  Future<void> updateDeviceName(String name) async {
    state = state.copyWith(deviceName: name);
    await _settingsService.saveSettings(state);
  }

  /// 更新是否可被发现
  Future<void> updateIsDiscoverable(bool value) async {
    state = state.copyWith(isDiscoverable: value);
    await _settingsService.saveSettings(state);
  }

  /// 更新是否自动接收文件
  Future<void> updateAutoAcceptFiles(bool value) async {
    state = state.copyWith(autoAcceptFiles: value);
    await _settingsService.saveSettings(state);
  }

  /// 更新是否仅接受来自已知设备的文件
  Future<void> updateOnlyAcceptFromKnownDevices(bool value) async {
    state = state.copyWith(onlyAcceptFromKnownDevices: value);
    await _settingsService.saveSettings(state);
  }

  /// 更新是否加密传输
  Future<void> updateEncryptTransfers(bool value) async {
    state = state.copyWith(encryptTransfers: value);
    await _settingsService.saveSettings(state);
  }

  /// 更新是否仅在充电时传输大文件
  Future<void> updateTransferLargeFilesOnlyWhenCharging(bool value) async {
    state = state.copyWith(transferLargeFilesOnlyWhenCharging: value);
    await _settingsService.saveSettings(state);
  }

  /// 更新下载路径
  Future<void> updateDownloadPath(String path) async {
    state = state.copyWith(downloadPath: path);
    await _settingsService.saveSettings(state);
  }
}

/// 设置模型
class Settings {
  /// 设备名称
  final String deviceName;
  
  /// 是否可被发现
  final bool isDiscoverable;
  
  /// 是否自动接收文件
  final bool autoAcceptFiles;
  
  /// 是否仅接受来自已知设备的文件
  final bool onlyAcceptFromKnownDevices;
  
  /// 是否加密传输
  final bool encryptTransfers;
  
  /// 是否仅在充电时传输大文件
  final bool transferLargeFilesOnlyWhenCharging;
  
  /// 下载路径
  final String downloadPath;

  const Settings({
    required this.deviceName,
    required this.isDiscoverable,
    required this.autoAcceptFiles,
    required this.onlyAcceptFromKnownDevices,
    required this.encryptTransfers,
    required this.transferLargeFilesOnlyWhenCharging,
    required this.downloadPath,
  });

  /// 默认设置
  factory Settings.defaults() {
    return Settings(
      deviceName: Platform.localHostname,
      isDiscoverable: true,
      autoAcceptFiles: false,
      onlyAcceptFromKnownDevices: true,
      encryptTransfers: true,
      transferLargeFilesOnlyWhenCharging: true,
      downloadPath: '/Downloads',
    );
  }

  /// 从JSON创建设置
  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      deviceName: json['deviceName'] as String? ?? Platform.localHostname,
      isDiscoverable: json['isDiscoverable'] as bool? ?? true,
      autoAcceptFiles: json['autoAcceptFiles'] as bool? ?? false,
      onlyAcceptFromKnownDevices: json['onlyAcceptFromKnownDevices'] as bool? ?? true,
      encryptTransfers: json['encryptTransfers'] as bool? ?? true,
      transferLargeFilesOnlyWhenCharging: json['transferLargeFilesOnlyWhenCharging'] as bool? ?? true,
      downloadPath: json['downloadPath'] as String? ?? '/Downloads',
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'deviceName': deviceName,
      'isDiscoverable': isDiscoverable,
      'autoAcceptFiles': autoAcceptFiles,
      'onlyAcceptFromKnownDevices': onlyAcceptFromKnownDevices,
      'encryptTransfers': encryptTransfers,
      'transferLargeFilesOnlyWhenCharging': transferLargeFilesOnlyWhenCharging,
      'downloadPath': downloadPath,
    };
  }

  /// 创建一个新的设置实例，但更新部分属性
  Settings copyWith({
    String? deviceName,
    bool? isDiscoverable,
    bool? autoAcceptFiles,
    bool? onlyAcceptFromKnownDevices,
    bool? encryptTransfers,
    bool? transferLargeFilesOnlyWhenCharging,
    String? downloadPath,
  }) {
    return Settings(
      deviceName: deviceName ?? this.deviceName,
      isDiscoverable: isDiscoverable ?? this.isDiscoverable,
      autoAcceptFiles: autoAcceptFiles ?? this.autoAcceptFiles,
      onlyAcceptFromKnownDevices: onlyAcceptFromKnownDevices ?? this.onlyAcceptFromKnownDevices,
      encryptTransfers: encryptTransfers ?? this.encryptTransfers,
      transferLargeFilesOnlyWhenCharging: transferLargeFilesOnlyWhenCharging ?? this.transferLargeFilesOnlyWhenCharging,
      downloadPath: downloadPath ?? this.downloadPath,
    );
  }
} 