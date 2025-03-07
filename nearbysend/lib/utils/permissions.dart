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
    try {
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
    } catch (e) {
      print('请求Android权限失败: $e');
      return false;
    }
  }
  
  /// 请求iOS权限
  static Future<bool> _requestIOSPermissions() async {
    try {
      // 请求蓝牙权限
      final bluetooth = await Permission.bluetooth.request();
      
      // 请求位置权限（蓝牙扫描需要）
      final location = await Permission.location.request();
      
      // 请求照片权限
      final photos = await Permission.photos.request();
      
      // 检查权限是否已授予
      return bluetooth.isGranted && location.isGranted && photos.isGranted;
    } catch (e) {
      print('请求iOS权限失败: $e');
      return false;
    }
  }
  
  /// 请求macOS权限
  static Future<bool> _requestMacOSPermissions() async {
    // macOS通常不需要显式请求权限，但可能需要蓝牙权限
    // 由于macOS上的权限API限制，我们在这里直接返回true
    print('macOS不需要显式请求权限');
    return true;
  }
  
  /// 请求Windows权限
  static Future<bool> _requestWindowsPermissions() async {
    // Windows通常不需要显式请求权限
    return true;
  }
  
  /// 检查蓝牙权限
  static Future<bool> checkBluetoothPermission() async {
    try {
      if (Platform.isAndroid) {
        return await Permission.bluetoothScan.isGranted &&
            await Permission.bluetoothConnect.isGranted &&
            await Permission.bluetoothAdvertise.isGranted;
      } else if (Platform.isIOS) {
        return await Permission.bluetooth.isGranted;
      }
      
      // 在macOS和Windows上，我们假设蓝牙权限已授予
      return true;
    } catch (e) {
      print('检查蓝牙权限失败: $e');
      return false;
    }
  }
  
  /// 检查位置权限
  static Future<bool> checkLocationPermission() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        return await Permission.location.isGranted;
      }
      
      // 在macOS和Windows上，我们假设位置权限已授予
      return true;
    } catch (e) {
      print('检查位置权限失败: $e');
      return false;
    }
  }
  
  /// 检查存储权限
  static Future<bool> checkStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        return await Permission.storage.isGranted;
      } else if (Platform.isIOS) {
        return await Permission.photos.isGranted;
      }
      
      // 在macOS和Windows上，我们假设存储权限已授予
      return true;
    } catch (e) {
      print('检查存储权限失败: $e');
      return false;
    }
  }
}
