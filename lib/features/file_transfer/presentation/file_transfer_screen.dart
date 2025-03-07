import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nearbysend/features/file_transfer/presentation/providers/file_transfer_provider.dart';
import 'package:nearbysend/features/file_transfer/presentation/widgets/file_transfer_item.dart';
import 'package:nearbysend/shared/widgets/error_view.dart';
import 'package:nearbysend/shared/widgets/loading_view.dart';

/// 文件传输页面
class FileTransferScreen extends ConsumerStatefulWidget {
  final String deviceId;

  const FileTransferScreen({
    super.key,
    required this.deviceId,
  });

  @override
  ConsumerState<FileTransferScreen> createState() => _FileTransferScreenState();
}

class _FileTransferScreenState extends ConsumerState<FileTransferScreen> {
  @override
  void initState() {
    super.initState();
    // 初始化文件传输
    Future.microtask(() => ref.read(fileTransferProvider.notifier).initialize(widget.deviceId));
  }

  @override
  void dispose() {
    // 清理资源
    ref.read(fileTransferProvider.notifier).dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transferState = ref.watch(fileTransferProvider);
    final deviceName = ref.watch(deviceNameProvider(widget.deviceId));

    return Scaffold(
      appBar: AppBar(
        title: Text('与 $deviceName 传输'),
      ),
      body: transferState.when(
        data: (transfers) {
          if (transfers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.file_copy,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '没有传输任务',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '点击下方按钮选择文件进行传输',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: transfers.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final transfer = transfers[index];
              return FileTransferItem(transfer: transfer);
            },
          );
        },
        loading: () => const LoadingView(message: '正在连接设备...'),
        error: (error, stackTrace) => ErrorView(
          message: '连接失败: $error',
          onRetry: () => ref.read(fileTransferProvider.notifier).initialize(widget.deviceId),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickAndSendFile,
        icon: const Icon(Icons.send),
        label: const Text('发送文件'),
      ),
    );
  }

  /// 选择并发送文件
  Future<void> _pickAndSendFile() async {
    final result = await FilePicker.platform.pickFiles();
    
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.path != null) {
        await ref.read(fileTransferProvider.notifier).sendFile(file.path!, file.name);
      }
    }
  }
} 