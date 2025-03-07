/// 设备模型类
class Device {
  /// 设备唯一标识符
  final String id;
  
  /// 设备名称
  final String name;
  
  /// 设备类型
  final DeviceType type;
  
  /// 设备地址（可能是IP或蓝牙地址）
  final String address;
  
  /// 是否已连接
  final bool isConnected;

  const Device({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    this.isConnected = false,
  });

  /// 从JSON创建设备实例
  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as String,
      name: json['name'] as String,
      type: DeviceType.values.firstWhere(
        (e) => e.toString() == 'DeviceType.${json['type']}',
        orElse: () => DeviceType.unknown,
      ),
      address: json['address'] as String,
      isConnected: json['isConnected'] as bool? ?? false,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'address': address,
      'isConnected': isConnected,
    };
  }

  /// 创建一个新的设备实例，但更新部分属性
  Device copyWith({
    String? id,
    String? name,
    DeviceType? type,
    String? address,
    bool? isConnected,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      address: address ?? this.address,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Device && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 设备类型枚举
enum DeviceType {
  android,
  ios,
  windows,
  macos,
  linux,
  unknown,
} 