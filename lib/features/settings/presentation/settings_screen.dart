import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nearbysend/features/settings/presentation/providers/settings_provider.dart';

/// 设置页面
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          const _SectionHeader(title: '通用设置'),
          SwitchListTile(
            title: const Text('自动接收文件'),
            subtitle: const Text('自动接受来自已知设备的文件'),
            value: settings.autoAcceptFiles,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateAutoAcceptFiles(value);
            },
          ),
          SwitchListTile(
            title: const Text('仅在充电时传输大文件'),
            subtitle: const Text('当文件大于100MB时，仅在设备充电时传输'),
            value: settings.transferLargeFilesOnlyWhenCharging,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateTransferLargeFilesOnlyWhenCharging(value);
            },
          ),
          ListTile(
            title: const Text('下载位置'),
            subtitle: Text(settings.downloadPath),
            trailing: const Icon(Icons.folder),
            onTap: () {
              // 选择下载位置
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('此功能尚未实现'),
                ),
              );
            },
          ),
          const Divider(),
          
          const _SectionHeader(title: '连接设置'),
          SwitchListTile(
            title: const Text('可被发现'),
            subtitle: const Text('允许其他设备发现您的设备'),
            value: settings.isDiscoverable,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateIsDiscoverable(value);
            },
          ),
          ListTile(
            title: const Text('设备名称'),
            subtitle: Text(settings.deviceName),
            trailing: const Icon(Icons.edit),
            onTap: () {
              _showDeviceNameDialog(context, ref, settings.deviceName);
            },
          ),
          const Divider(),
          
          const _SectionHeader(title: '安全设置'),
          SwitchListTile(
            title: const Text('仅接受来自已知设备的文件'),
            subtitle: const Text('仅接受来自您之前连接过的设备的文件'),
            value: settings.onlyAcceptFromKnownDevices,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateOnlyAcceptFromKnownDevices(value);
            },
          ),
          SwitchListTile(
            title: const Text('加密传输'),
            subtitle: const Text('使用端到端加密保护文件传输'),
            value: settings.encryptTransfers,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateEncryptTransfers(value);
            },
          ),
          const Divider(),
          
          const _SectionHeader(title: '关于'),
          ListTile(
            title: const Text('版本'),
            subtitle: const Text('1.0.0'),
          ),
          ListTile(
            title: const Text('开源许可'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // 显示开源许可
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('此功能尚未实现'),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// 显示设备名称编辑对话框
  void _showDeviceNameDialog(BuildContext context, WidgetRef ref, String currentName) {
    final controller = TextEditingController(text: currentName);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('编辑设备名称'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: '设备名称',
              hintText: '输入设备名称',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  ref.read(settingsProvider.notifier).updateDeviceName(newName);
                }
                Navigator.pop(context);
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }
}

/// 设置分区标题
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
} 