import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nearbysend/app/routes/app_router.dart';
import 'package:nearbysend/features/device_discovery/presentation/providers/device_discovery_provider.dart';
import 'package:nearbysend/shared/widgets/error_view.dart';
import 'package:nearbysend/shared/widgets/loading_view.dart';

/// 设备发现页面
class DeviceDiscoveryScreen extends ConsumerStatefulWidget {
  const DeviceDiscoveryScreen({super.key});

  @override
  ConsumerState<DeviceDiscoveryScreen> createState() => _DeviceDiscoveryScreenState();
}

class _DeviceDiscoveryScreenState extends ConsumerState<DeviceDiscoveryScreen> {
  @override
  void initState() {
    super.initState();
    // 页面加载时开始设备发现
    Future.microtask(() => ref.read(deviceDiscoveryProvider.notifier).startDiscovery());
  }

  @override
  void dispose() {
    // 页面销毁时停止设备发现
    ref.read(deviceDiscoveryProvider.notifier).stopDiscovery();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceDiscoveryState = ref.watch(deviceDiscoveryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('发现设备'),
      ),
      body: deviceDiscoveryState.when(
        data: (devices) {
          if (devices.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '未发现设备',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '请确保附近设备已开启并可被发现',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              return ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.devices),
                ),
                title: Text(device.name),
                subtitle: Text(device.id),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // 导航到文件传输页面
                  context.go(
                    '${AppRoutes.fileTransfer}?deviceId=${device.id}',
                  );
                },
              );
            },
          );
        },
        loading: () => const LoadingView(message: '正在搜索附近设备...'),
        error: (error, stackTrace) => ErrorView(
          message: '设备发现失败: $error',
          onRetry: () => ref.read(deviceDiscoveryProvider.notifier).startDiscovery(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.read(deviceDiscoveryProvider.notifier).startDiscovery(),
        tooltip: '刷新',
        child: const Icon(Icons.refresh),
      ),
    );
  }
} 