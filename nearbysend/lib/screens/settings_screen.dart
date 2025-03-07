import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  /// 设备名称
  String _deviceName = '';
  
  /// 下载路径
  String _downloadPath = '';
  
  /// 是否自动接收文件
  bool _autoReceive = false;
  
  /// 是否显示通知
  bool _showNotifications = true;
  
  /// 是否保持屏幕常亮
  bool _keepScreenOn = false;
  
  /// 是否使用蓝牙
  bool _useBluetooth = true;
  
  /// 是否使用WiFi
  bool _useWifi = true;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  /// 加载设置
  Future<void> _loadSettings() async {
    // 获取设备名称
    final deviceName = await _getDeviceName();
    
    // 获取下载路径
    final downloadPath = await _getDownloadPath();
    
    // 更新状态
    setState(() {
      _deviceName = deviceName;
      _downloadPath = downloadPath;
    });
  }
  
  /// 获取设备名称
  Future<String> _getDeviceName() async {
    if (Platform.isAndroid) {
      return 'Android设备';
    } else if (Platform.isIOS) {
      return 'iOS设备';
    } else if (Platform.isMacOS) {
      return 'Mac设备';
    } else if (Platform.isWindows) {
      return 'Windows设备';
    } else {
      return '未知设备';
    }
  }
  
  /// 获取下载路径
  Future<String> _getDownloadPath() async {
    try {
      Directory? directory;
      
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
      
      return directory?.path ?? '未知路径';
    } catch (e) {
      return '未知路径';
    }
  }
  
  /// 更改设备名称
  Future<void> _changeDeviceName() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        String name = _deviceName;
        
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
            controller: TextEditingController(text: _deviceName),
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
      setState(() {
        _deviceName = result;
      });
      
      // 保存设备名称
      // 在实际实现中，应该调用Rust API保存设备名称
    }
  }
  
  /// 更改下载路径
  Future<void> _changeDownloadPath() async {
    // 在实际实现中，应该使用文件选择器选择下载路径
    // 这里只是一个模拟实现
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        String path = _downloadPath;
        
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
            controller: TextEditingController(text: _downloadPath),
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
      setState(() {
        _downloadPath = result;
      });
      
      // 保存下载路径
      // 在实际实现中，应该调用Rust API保存下载路径
    }
  }

  @override
  Widget build(BuildContext context) {
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
                subtitle: Text(_deviceName),
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
                subtitle: Text(_downloadPath),
                trailing: const Icon(Icons.folder),
                onTap: _changeDownloadPath,
              ),
              
              // 自动接收文件
              SwitchListTile(
                title: const Text('自动接收文件'),
                subtitle: const Text('自动接收来自已知设备的文件'),
                value: _autoReceive,
                onChanged: (value) {
                  setState(() {
                    _autoReceive = value;
                  });
                },
              ),
              
              // 使用蓝牙
              SwitchListTile(
                title: const Text('使用蓝牙'),
                subtitle: const Text('使用蓝牙发现设备'),
                value: _useBluetooth,
                onChanged: (value) {
                  setState(() {
                    _useBluetooth = value;
                  });
                },
              ),
              
              // 使用WiFi
              SwitchListTile(
                title: const Text('使用WiFi'),
                subtitle: const Text('使用WiFi发现设备'),
                value: _useWifi,
                onChanged: (value) {
                  setState(() {
                    _useWifi = value;
                  });
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
                value: _showNotifications,
                onChanged: (value) {
                  setState(() {
                    _showNotifications = value;
                  });
                },
              ),
              
              // 保持屏幕常亮
              SwitchListTile(
                title: const Text('保持屏幕常亮'),
                subtitle: const Text('传输过程中保持屏幕常亮'),
                value: _keepScreenOn,
                onChanged: (value) {
                  setState(() {
                    _keepScreenOn = value;
                  });
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
