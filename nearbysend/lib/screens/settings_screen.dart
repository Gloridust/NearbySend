import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nearbysend/services/providers.dart';
import 'package:nearbysend/theme/app_theme.dart';
import 'package:path_provider/path_provider.dart';

/// 设置页面
class SettingsScreen extends ConsumerStatefulWidget {
  /// 构造函数
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    // 初始化桥接服务
    ref.read(bridgeServiceProvider).initialize();
  }
  
  /// 更改设备名称
  Future<void> _changeDeviceName() async {
    final currentName = await ref.read(bridgeServiceProvider).getDeviceName();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        String name = currentName;
        
        return AlertDialog(
          title: const Text('更改设备名称'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '设备名称',
              hintText: '请输入设备名称',
            ),
            onChanged: (value) {
              name = value;
            },
            controller: TextEditingController(text: currentName),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, name),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
    
    if (result != null && result.isNotEmpty) {
      // 保存设备名称
      await ref.read(bridgeServiceProvider).setDeviceName(result);
      // 刷新设备名称提供者
      ref.refresh(deviceNameProvider);
    }
  }
  
  /// 更改下载路径
  Future<void> _changeDownloadPath() async {
    final currentPath = await ref.read(bridgeServiceProvider).getDownloadPath();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        String path = currentPath;
        
        return AlertDialog(
          title: const Text('更改下载路径'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '下载路径',
              hintText: '请输入下载路径',
            ),
            onChanged: (value) {
              path = value;
            },
            controller: TextEditingController(text: currentPath),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, path),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
    
    if (result != null && result.isNotEmpty) {
      // 保存下载路径
      await ref.read(bridgeServiceProvider).setDownloadPath(result);
      // 刷新下载路径提供者
      ref.refresh(downloadPathProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceNameAsync = ref.watch(deviceNameProvider);
    final downloadPathAsync = ref.watch(downloadPathProvider);
    final autoReceive = ref.watch(autoReceiveProvider);
    final showNotifications = ref.watch(showNotificationsProvider);
    final keepScreenOn = ref.watch(keepScreenOnProvider);
    final useBluetooth = ref.watch(useBluetoothProvider);
    final useWifi = ref.watch(useWifiProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          // 设备信息
          _buildSection(
            title: '设备信息',
            children: [
              // 设备名称
              ListTile(
                title: const Text('设备名称'),
                subtitle: deviceNameAsync.when(
                  data: (name) => Text(name),
                  loading: () => const Text('加载中...'),
                  error: (error, stackTrace) => Text('加载失败: $error'),
                ),
                trailing: const Icon(Icons.edit),
                onTap: _changeDeviceName,
              ),
              
              // 设备类型
              ListTile(
                title: const Text('设备类型'),
                subtitle: Text(Platform.operatingSystem),
                enabled: false,
              ),
              
              // 系统版本
              ListTile(
                title: const Text('系统版本'),
                subtitle: Text(Platform.operatingSystemVersion),
                enabled: false,
              ),
            ],
          ),
          
          // 传输设置
          _buildSection(
            title: '传输设置',
            children: [
              // 下载路径
              ListTile(
                title: const Text('下载路径'),
                subtitle: downloadPathAsync.when(
                  data: (path) => Text(path),
                  loading: () => const Text('加载中...'),
                  error: (error, stackTrace) => Text('加载失败: $error'),
                ),
                trailing: const Icon(Icons.folder),
                onTap: _changeDownloadPath,
              ),
              
              // 自动接收文件
              SwitchListTile(
                title: const Text('自动接收文件'),
                subtitle: const Text('自动接收来自已知设备的文件'),
                value: autoReceive,
                onChanged: (value) {
                  ref.read(autoReceiveProvider.notifier).state = value;
                },
              ),
              
              // 使用蓝牙
              SwitchListTile(
                title: const Text('使用蓝牙'),
                subtitle: const Text('使用蓝牙发现设备'),
                value: useBluetooth,
                onChanged: (value) {
                  ref.read(useBluetoothProvider.notifier).state = value;
                },
              ),
              
              // 使用WiFi
              SwitchListTile(
                title: const Text('使用WiFi'),
                subtitle: const Text('使用WiFi发现设备'),
                value: useWifi,
                onChanged: (value) {
                  ref.read(useWifiProvider.notifier).state = value;
                },
              ),
            ],
          ),
          
          // 通用设置
          _buildSection(
            title: '通用设置',
            children: [
              // 显示通知
              SwitchListTile(
                title: const Text('显示通知'),
                subtitle: const Text('显示传输通知'),
                value: showNotifications,
                onChanged: (value) {
                  ref.read(showNotificationsProvider.notifier).state = value;
                },
              ),
              
              // 保持屏幕常亮
              SwitchListTile(
                title: const Text('保持屏幕常亮'),
                subtitle: const Text('传输过程中保持屏幕常亮'),
                value: keepScreenOn,
                onChanged: (value) {
                  ref.read(keepScreenOnProvider.notifier).state = value;
                },
              ),
            ],
          ),
          
          // 关于
          _buildSection(
            title: '关于',
            children: [
              // 版本
              const ListTile(
                title: Text('版本'),
                subtitle: Text('1.0.0'),
                enabled: false,
              ),
              
              // 开源许可
              ListTile(
                title: const Text('开源许可'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // 显示开源许可
                  showLicensePage(
                    context: context,
                    applicationName: 'NearbySend',
                    applicationVersion: '1.0.0',
                    applicationLegalese: '© 2023 NearbySend',
                  );
                },
              ),
              
              // 隐私政策
              ListTile(
                title: const Text('隐私政策'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // 显示隐私政策
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('隐私政策'),
                        content: const SingleChildScrollView(
                          child: Text(
                            'NearbySend不会收集任何个人信息。'
                            '所有传输的文件都是点对点的，不会经过任何服务器。'
                            '设备名称和其他设置仅保存在本地设备上。',
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('关闭'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// 构建设置分区
  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 分区标题
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        
        // 分区内容
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppTheme.dividerColor),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}
