import 'package:flutter/foundation.dart';

/// 设备类型枚举
enum DeviceType {
  android,
  ios,
  macos,
  windows,
  unknown,
}

/// 设备模型
class Device {
  /// 设备ID
  final String id;
  
  /// 设备名称
  final String name;
  
  /// 设备类型
  final DeviceType deviceType;
  
  /// 是否已连接
  final bool isConnected;
  
  /// 构造函数
  const Device({
    required this.id,
    required this.name,
    required this.deviceType,
    this.isConnected = false,
  });
  
  /// 复制并修改
  Device copyWith({
    String? id,
    String? name,
    DeviceType? deviceType,
    bool? isConnected,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      deviceType: deviceType ?? this.deviceType,
      isConnected: isConnected ?? this.isConnected,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Device &&
        other.id == id &&
        other.name == name &&
        other.deviceType == deviceType &&
        other.isConnected == isConnected;
  }
  
  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        deviceType.hashCode ^
        isConnected.hashCode;
  }
}

/// 设备扩展方法
extension DeviceExtension on Device {
  /// 获取设备类型图标
  String get iconPath {
    switch (deviceType) {
      case DeviceType.android:
        return 'assets/icons/android.png';
      case DeviceType.ios:
        return 'assets/icons/ios.png';
      case DeviceType.macos:
        return 'assets/icons/macos.png';
      case DeviceType.windows:
        return 'assets/icons/windows.png';
      case DeviceType.unknown:
      default:
        return 'assets/icons/device.png';
    }
  }

  /// 获取设备类型名称
  String get deviceTypeName {
    switch (deviceType) {
      case DeviceType.android:
        return 'Android';
      case DeviceType.ios:
        return 'iOS';
      case DeviceType.macos:
        return 'macOS';
      case DeviceType.windows:
        return 'Windows';
      case DeviceType.unknown:
      default:
        return '未知设备';
    }
  }
}
