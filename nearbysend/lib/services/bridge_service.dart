import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:nearbysend/models/device.dart';
import 'package:nearbysend/models/transfer.dart';

/// 桥接服务
class BridgeService {
  /// 单例实例
  static final BridgeService _instance = BridgeService._internal();

  /// 工厂构造函数
  factory BridgeService() => _instance;

  /// 内部构造函数
  BridgeService._internal();

  /// 设备流控制器
  final _deviceStreamController = StreamController<List<Device>>.broadcast();

  /// 传输流控制器
  final _transferStreamController = StreamController<List<FileTransfer>>.broadcast();

  /// 设备流
  Stream<List<Device>> get deviceStream => _deviceStreamController.stream;

  /// 传输流
  Stream<List<FileTransfer>> get transferStream => _transferStreamController.stream;

  /// 初始化
  Future<void> initialize() async {
    // 在实际实现中，这里应该调用Rust API初始化
    debugPrint('初始化桥接服务');
  }

  /// 开始扫描设备
  Future<void> startScanning() async {
    // 在实际实现中，这里应该调用Rust API开始扫描
    debugPrint('开始扫描设备');

    // 获取真实设备信息
    final devices = await _discoverRealDevices();
    _deviceStreamController.add(devices);
  }

  /// 发现真实设备
  Future<List<Device>> _discoverRealDevices() async {
    final devices = <Device>[];
    
    // 获取本机设备信息
    final localDevice = await _getLocalDevice();
    devices.add(localDevice);
    
    // 在实际实现中，这里应该通过BLE和mDNS发现其他设备
    // 目前我们只添加本机设备用于演示
    
    debugPrint('发现了 ${devices.length} 个设备');
    return devices;
  }
  
  /// 获取本机设备信息
  Future<Device> _getLocalDevice() async {
    // 获取设备名称
    final name = await getDeviceName();
    
    // 获取设备类型
    DeviceType deviceType;
    if (Platform.isAndroid) {
      deviceType = DeviceType.android;
    } else if (Platform.isIOS) {
      deviceType = DeviceType.ios;
    } else if (Platform.isMacOS) {
      deviceType = DeviceType.macos;
    } else if (Platform.isWindows) {
      deviceType = DeviceType.windows;
    } else {
      deviceType = DeviceType.unknown;
    }
    
    // 创建本机设备
    return Device(
      id: 'local_device',
      name: '$name (本机)',
      deviceType: deviceType,
      isConnected: false,
    );
  }

  /// 停止扫描设备
  Future<void> stopScanning() async {
    // 在实际实现中，这里应该调用Rust API停止扫描
    debugPrint('停止扫描设备');
  }

  /// 连接到设备
  Future<void> connectToDevice(Device device) async {
    // 在实际实现中，这里应该调用Rust API连接到设备
    debugPrint('连接到设备: ${device.name}');
  }

  /// 断开设备连接
  Future<void> disconnectDevice(Device device) async {
    // 在实际实现中，这里应该调用Rust API断开设备连接
    debugPrint('断开设备连接: ${device.name}');
  }

  /// 发送文件
  Future<String> sendFile(Device device, String filePath) async {
    // 在实际实现中，这里应该调用Rust API发送文件
    debugPrint('发送文件: $filePath 到设备: ${device.name}');

    // 返回传输ID
    return 'transfer_${device.id}_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// 获取设备名称
  Future<String> getDeviceName() async {
    // 尝试获取真实设备名称
    try {
      if (Platform.isAndroid) {
        // Android设备名称
        return 'Android设备';
      } else if (Platform.isIOS) {
        // iOS设备名称
        return 'iOS设备';
      } else if (Platform.isMacOS) {
        // macOS设备名称
        final result = await Process.run('scutil', ['--get', 'ComputerName']);
        if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
          return result.stdout.toString().trim();
        }
        return 'Mac设备';
      } else if (Platform.isWindows) {
        // Windows设备名称
        final result = await Process.run('hostname', []);
        if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
          return result.stdout.toString().trim();
        }
        return 'Windows设备';
      }
    } catch (e) {
      debugPrint('获取设备名称失败: $e');
    }
    
    // 默认设备名称
    return 'NearbySend设备';
  }

  /// 设置设备名称
  Future<void> setDeviceName(String name) async {
    // 在实际实现中，这里应该调用Rust API设置设备名称
    debugPrint('设置设备名称: $name');
  }

  /// 获取下载路径
  Future<String> getDownloadPath() async {
    try {
      if (Platform.isAndroid) {
        // Android下载路径
        final directory = await getExternalStorageDirectory();
        return directory?.path ?? '/storage/emulated/0/Download';
      } else if (Platform.isIOS) {
        // iOS下载路径
        final directory = await getApplicationDocumentsDirectory();
        return '${directory.path}/Downloads';
      } else if (Platform.isMacOS) {
        // macOS下载路径 - 使用用户的下载目录
        final homeDir = Platform.environment['HOME'];
        if (homeDir != null) {
          final downloadDir = '$homeDir/Downloads';
          return downloadDir;
        }
      } else if (Platform.isWindows) {
        // Windows下载路径 - 使用用户的下载目录
        final homeDir = Platform.environment['USERPROFILE'];
        if (homeDir != null) {
          final downloadDir = '$homeDir\\Downloads';
          return downloadDir;
        }
      }
    } catch (e) {
      debugPrint('获取下载路径失败: $e');
    }
    
    // 默认下载路径 - 临时目录
    final tempDir = await Directory.systemTemp.createTemp('nearbysend_downloads_');
    return tempDir.path;
  }
  
  /// 获取外部存储目录
  Future<Directory?> getExternalStorageDirectory() async {
    if (Platform.isAndroid) {
      try {
        // 模拟Android外部存储目录
        return Directory('/storage/emulated/0/Download');
      } catch (e) {
        debugPrint('获取Android外部存储目录失败: $e');
      }
    }
    return null;
  }
  
  /// 获取应用文档目录
  Future<Directory> getApplicationDocumentsDirectory() async {
    if (Platform.isIOS) {
      try {
        // 模拟iOS应用文档目录
        return Directory('/var/mobile/Containers/Data/Application/Documents');
      } catch (e) {
        debugPrint('获取iOS应用文档目录失败: $e');
      }
    }
    
    // 默认目录
    final homeDir = Platform.environment['HOME'] ?? '/';
    return Directory('$homeDir/Documents');
  }

  /// 设置下载路径
  Future<void> setDownloadPath(String path) async {
    // 在实际实现中，这里应该调用Rust API设置下载路径
    debugPrint('设置下载路径: $path');
  }

  /// 释放资源
  void dispose() {
    _deviceStreamController.close();
    _transferStreamController.close();
  }
}
