import 'dart:async';
import 'dart:io';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nearbysend/core/models/device.dart';
import 'package:nearbysend/shared/constants/app_constants.dart';
import 'package:permission_handler/permission_handler.dart';

/// 设备发现服务提供者
final deviceDiscoveryServiceProvider = Provider<DeviceDiscoveryService>((ref) {
  return DeviceDiscoveryService();
});

/// 设备发现服务
class DeviceDiscoveryService {
  final FlutterBlue _flutterBlue = FlutterBlue.instance;
  NearbyService? _nearbyService;
  
  final List<Device> _discoveredDevices = [];
  final StreamController<List<Device>> _devicesStreamController = StreamController<List<Device>>.broadcast();
  
  Stream<List<Device>> get devicesStream => _devicesStreamController.stream;
  
  /// 请求必要的权限
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final locationStatus = await Permission.location.request();
      final bluetoothStatus = await Permission.bluetooth.request();
      final bluetoothConnectStatus = await Permission.bluetoothConnect.request();
      final bluetoothScanStatus = await Permission.bluetoothScan.request();
      
      return locationStatus.isGranted && 
             bluetoothStatus.isGranted && 
             bluetoothConnectStatus.isGranted && 
             bluetoothScanStatus.isGranted;
    } else if (Platform.isIOS) {
      final bluetoothStatus = await Permission.bluetooth.request();
      return bluetoothStatus.isGranted;
    }
    
    return true;
  }
  
  /// 开始设备发现
  Future<List<Device>> startDiscovery() async {
    _discoveredDevices.clear();
    
    // 初始化NearbyService
    _nearbyService = NearbyService();
    await _nearbyService?.init(
      serviceType: AppConstants.serviceId,
      strategy: Strategy.P2P_CLUSTER,
      callback: (isRunning) async {
        if (isRunning) {
          await _nearbyService?.startAdvertisingPeer();
          await _nearbyService?.startBrowsingForPeers();
        }
      },
    );
    
    // 监听设备发现
    _nearbyService?.stateChangedSubscription?.onData((data) {
      final device = _convertToDevice(data);
      
      if (data.state == SessionState.connected) {
        // 设备已连接
        final index = _discoveredDevices.indexWhere((d) => d.id == device.id);
        if (index >= 0) {
          _discoveredDevices[index] = device.copyWith(isConnected: true);
        } else {
          _discoveredDevices.add(device.copyWith(isConnected: true));
        }
      } else if (data.state == SessionState.notConnected) {
        // 发现新设备
        if (!_discoveredDevices.any((d) => d.id == device.id)) {
          _discoveredDevices.add(device);
        }
      }
      
      _devicesStreamController.add(_discoveredDevices);
    });
    
    // 同时使用蓝牙扫描
    await _startBluetoothScan();
    
    // 等待一段时间以收集设备
    await Future.delayed(const Duration(seconds: 5));
    
    return _discoveredDevices;
  }
  
  /// 停止设备发现
  Future<void> stopDiscovery() async {
    await _nearbyService?.stopBrowsingForPeers();
    await _nearbyService?.stopAdvertisingPeer();
    await _flutterBlue.stopScan();
  }
  
  /// 连接到设备
  Future<bool> connectToDevice(String deviceId) async {
    final device = _discoveredDevices.firstWhere(
      (d) => d.id == deviceId,
      orElse: () => throw Exception('设备未找到'),
    );
    
    try {
      final discoveredDevice = _nearbyService?.devices.firstWhere(
        (d) => d.deviceId == deviceId,
      );
      
      if (discoveredDevice != null) {
        await _nearbyService?.invitePeer(
          deviceID: discoveredDevice.deviceId,
          deviceName: discoveredDevice.deviceName,
        );
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// 开始蓝牙扫描
  Future<void> _startBluetoothScan() async {
    // 开始蓝牙扫描
    await _flutterBlue.startScan(timeout: const Duration(seconds: 10));
    
    // 监听扫描结果
    _flutterBlue.scanResults.listen((results) {
      for (ScanResult result in results) {
        if (result.device.name.isNotEmpty) {
          final device = Device(
            id: result.device.id.id,
            name: result.device.name,
            type: _getDeviceTypeFromName(result.device.name),
            address: result.device.id.id,
            isConnected: false,
          );
          
          if (!_discoveredDevices.any((d) => d.id == device.id)) {
            _discoveredDevices.add(device);
            _devicesStreamController.add(_discoveredDevices);
          }
        }
      }
    });
  }
  
  /// 将NearbyDevice转换为Device模型
  Device _convertToDevice(DeviceInfo info) {
    return Device(
      id: info.deviceId,
      name: info.deviceName,
      type: _getDeviceTypeFromName(info.deviceName),
      address: info.deviceId,
      isConnected: info.state == SessionState.connected,
    );
  }
  
  /// 根据设备名称猜测设备类型
  DeviceType _getDeviceTypeFromName(String name) {
    name = name.toLowerCase();
    
    if (name.contains('iphone') || name.contains('ipad') || name.contains('ipod')) {
      return DeviceType.ios;
    } else if (name.contains('mac')) {
      return DeviceType.macos;
    } else if (name.contains('windows') || name.contains('pc')) {
      return DeviceType.windows;
    } else if (name.contains('linux')) {
      return DeviceType.linux;
    } else {
      return DeviceType.android; // 默认为Android
    }
  }
  
  /// 销毁服务
  void dispose() {
    _devicesStreamController.close();
    _nearbyService?.stopBrowsingForPeers();
    _nearbyService?.stopAdvertisingPeer();
    _flutterBlue.stopScan();
  }
} 