import 'package:flutter/material.dart';
import 'package:nearbysend/models/device.dart';
import 'package:nearbysend/theme/app_theme.dart';

/// 设备卡片组件
class DeviceCard extends StatelessWidget {
  /// 设备信息
  final Device device;
  
  /// 点击回调
  final VoidCallback? onTap;
  
  /// 构造函数
  const DeviceCard({
    super.key,
    required this.device,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: device.isConnected
            ? const BorderSide(color: AppTheme.primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 设备图标
              Icon(
                _getDeviceIcon(),
                size: 48,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 12),
              
              // 设备名称
              Text(
                device.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              
              // 设备类型
              Text(
                device.deviceTypeName,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              
              // 连接状态
              if (device.isConnected) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '已连接',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  /// 获取设备图标
  IconData _getDeviceIcon() {
    switch (device.deviceType) {
      case DeviceType.android:
        return Icons.phone_android;
      case DeviceType.ios:
        return Icons.phone_iphone;
      case DeviceType.macos:
        return Icons.laptop_mac;
      case DeviceType.windows:
        return Icons.laptop_windows;
      case DeviceType.unknown:
      default:
        return Icons.devices_other;
    }
  }
}
