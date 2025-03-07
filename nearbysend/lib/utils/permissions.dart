import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

/// 权限工具类
class PermissionUtils {
  /// 请求所需权限
  static Future<bool> requestPermissions() async {
    // 根据平台请求不同的权限
    if (Platform.isAndroid) {
      return await _requestAndroidPermissions();
    } else if (Platform.isIOS) {
      return await _requestIOSPermissions();
    } else if (Platform.isMacOS) {
      return await _requestMacOSPermissions();
    } else if (Platform.isWindows) {
      return await _requestWindowsPermissions();
    }
    
    return false;
  }
  
  /// 请求Android权限
  static Future<bool> _requestAndroidPermissions() async {
    // 请求蓝牙权限
    final bluetoothScan = await Permission.bluetoothScan.request();
    final bluetoothConnect = await Permission.bluetoothConnect.request();
    final bluetoothAdvertise = await Permission.bluetoothAdvertise.request();
    
    // 请求位置权限（蓝牙扫描需要）
    final location = await Permission.location.request();
    
    // 请求存储权限
    final storage = await Permission.storage.request();
    
    // 请求WiFi权限
    final nearbyWifiDevices = await Permission.nearbyWifiDevices.request();
    
    // 检查权限是否已授予
    return bluetoothScan.isGranted &&
        bluetoothConnect.isGranted &&
        bluetoothAdvertise.isGranted &&
        location.isGranted &&
        storage.isGranted &&
        nearbyWifiDevices.isGranted;
  }
  
  /// 请求iOS权限
  static Future<bool> _requestIOSPermissions() async {
    // 请求蓝牙权限
    final bluetooth = await Permission.bluetooth.request();
    
    // 请求位置权限（蓝牙扫描需要）
    final location = await Permission.location.request();
    
    // 请求照片权限
    final photos = await Permission.photos.request();
    
    // 检查权限是否已授予
    return bluetooth.isGranted && location.isGranted && photos.isGranted;
  }
  
  /// 请求macOS权限
  static Future<bool> _requestMacOSPermissions() async {
    // macOS通常不需要显式请求权限，但可能需要蓝牙权限
    final bluetooth = await Permission.bluetooth.request();
    
    // 检查权限是否已授予
    return bluetooth.isGranted;
  }
  
  /// 请求Windows权限
  static Future<bool> _requestWindowsPermissions() async {
    // Windows通常不需要显式请求权限
    return true;
  }
  
  /// 检查蓝牙权限
  static Future<bool> checkBluetoothPermission() async {
    if (Platform.isAndroid) {
      return await Permission.bluetoothScan.isGranted &&
          await Permission.bluetoothConnect.isGranted &&
          await Permission.bluetoothAdvertise.isGranted;
    } else {
      return await Permission.bluetooth.isGranted;
    }
  }
  
  /// 检查位置权限
  static Future<bool> checkLocationPermission() async {
    return await Permission.location.isGranted;
  }
  
  /// 检查存储权限
  static Future<bool> checkStoragePermission() async {
    if (Platform.isAndroid) {
      return await Permission.storage.isGranted;
    } else if (Platform.isIOS) {
      return await Permission.photos.isGranted;
    }
    
    return true;
  }
}
