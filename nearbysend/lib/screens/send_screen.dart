import 'dart:io';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nearbysend/models/device.dart';
import 'package:nearbysend/models/transfer.dart';
import 'package:nearbysend/services/providers.dart';
import 'package:nearbysend/theme/app_theme.dart';
import 'package:nearbysend/utils/permissions.dart';
import 'package:nearbysend/widgets/device_card.dart';
import 'package:nearbysend/widgets/file_item.dart';
import 'package:nearbysend/widgets/transfer_progress.dart';

/// 选择的文件列表提供者
final selectedFilesProvider = StateProvider<List<String>>((ref) => []);

/// 是否正在扫描提供者
final isScanningProvider = StateProvider<bool>((ref) => false);

/// 是否正在传输提供者
final isTransferringProvider = StateProvider<bool>((ref) => false);

/// 发送页面
class SendScreen extends ConsumerStatefulWidget {
  /// 构造函数
  const SendScreen({super.key});

  @override
  ConsumerState<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends ConsumerState<SendScreen> {
  /// 传输列表
  final List<FileTransfer> _transfers = [];
  
  /// 传输计时器列表
  final List<Timer> _timers = [];
  
  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }
  
  @override
  void dispose() {
    // 取消所有计时器
    for (final timer in _timers) {
      timer.cancel();
    }
    super.dispose();
  }
  
  /// 检查权限
  Future<void> _checkPermissions() async {
    final hasPermissions = await PermissionUtils.requestPermissions();
    if (!hasPermissions) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('需要权限才能使用此应用'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } else {
      _startScanning();
    }
  }
  
  /// 开始扫描设备
  void _startScanning() {
    ref.read(isScanningProvider.notifier).state = true;
    
    // 调用桥接服务开始扫描
    ref.read(bridgeServiceProvider).startScanning().then((_) {
      if (mounted) {
        ref.read(isScanningProvider.notifier).state = false;
      }
    });
  }
  
  /// 选择文件
  Future<void> _pickFiles() async {
    try {
      print('开始选择文件...');
      
      // 使用FilePicker选择文件，允许所有类型
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        dialogTitle: '选择要发送的文件',
        allowedExtensions: null,
        withData: false,
        withReadStream: true,
        lockParentWindow: true,
        onFileLoading: (FilePickerStatus status) {
          print('文件选择状态: $status');
        },
      );
      
      print('文件选择结果: $result');
      
      if (result != null && result.files.isNotEmpty) {
        final selectedFiles = ref.read(selectedFilesProvider);
        final newFiles = <String>[];
        
        for (final file in result.files) {
          if (file.path != null && !selectedFiles.contains(file.path)) {
            newFiles.add(file.path!);
            print('添加文件: ${file.path}');
          } else if (file.path != null) {
            print('文件已在列表中: ${file.path}');
          }
        }
        
        if (newFiles.isNotEmpty) {
          ref.read(selectedFilesProvider.notifier).state = [...selectedFiles, ...newFiles];
          print('已选择 ${newFiles.length} 个文件');
          
          // 显示成功消息
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('已选择 ${newFiles.length} 个文件'),
                backgroundColor: AppTheme.successColor,
              ),
            );
          }
        } else if (result.files.isNotEmpty) {
          // 所有选择的文件都已在列表中
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('所选文件已在列表中'),
                backgroundColor: AppTheme.warningColor,
              ),
            );
          }
        }
      } else {
        print('未选择文件');
      }
    } catch (e) {
      print('选择文件失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('选择文件失败: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
  
  /// 删除选择的文件
  void _removeFile(int index) {
    final selectedFiles = ref.read(selectedFilesProvider);
    final newFiles = List<String>.from(selectedFiles);
    newFiles.removeAt(index);
    ref.read(selectedFilesProvider.notifier).state = newFiles;
  }
  
  /// 连接到设备
  Future<void> _connectToDevice(Device device) async {
    // 检查是否已选择文件
    final selectedFiles = ref.read(selectedFilesProvider);
    if (selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先选择要发送的文件'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }
    
    // 更新传输状态
    ref.read(isTransferringProvider.notifier).state = true;
    
    try {
      // 获取平台特定的下载路径
      final downloadPath = await ref.read(bridgeServiceProvider).getDownloadPath();
      print('使用下载路径: $downloadPath');
      
      // 连接到设备
      await ref.read(bridgeServiceProvider).connectToDevice(device);
      
      // 为每个文件创建传输
      for (int i = 0; i < selectedFiles.length; i++) {
        final file = File(selectedFiles[i]);
        final fileName = file.uri.pathSegments.last;
        final targetPath = '$downloadPath/$fileName';
        
        print('文件将保存到: $targetPath');
        
        final transfer = FileTransfer(
          id: 'transfer_${device.id}_$i',
          fileName: fileName,
          fileSize: file.lengthSync(),
          status: TransferStatus.connecting,
          targetPath: targetPath, // 添加目标路径
        );
        
        setState(() {
          _transfers.add(transfer);
        });
        
        // 模拟传输进度
        _simulateTransfer(transfer, i);
      }
    } catch (e) {
      print('连接设备或准备传输失败: $e');
      ref.read(isTransferringProvider.notifier).state = false;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('连接失败: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
  
  /// 模拟传输进度
  void _simulateTransfer(FileTransfer transfer, int delay) {
    Future.delayed(Duration(seconds: delay), () {
      if (!mounted) return;
      
      // 更新状态为传输中
      setState(() {
        final index = _transfers.indexWhere((t) => t.id == transfer.id);
        if (index != -1) {
          _transfers[index] = transfer.copyWith(
            status: TransferStatus.transferring,
          );
        }
      });
      
      // 模拟进度更新
      int progress = 0;
      const interval = 100; // 更新间隔（毫秒）
      
      // 创建定时器
      final timer = Timer.periodic(const Duration(milliseconds: interval), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        
        progress += 2;
        if (progress <= 100) {
          setState(() {
            final index = _transfers.indexWhere((t) => t.id == transfer.id);
            if (index != -1) {
              final current = _transfers[index];
              final newBytes = (current.fileSize * progress / 100).round();
              
              _transfers[index] = current.copyWith(
                transferredBytes: newBytes,
              );
            }
          });
        } else {
          // 传输完成
          setState(() {
            final index = _transfers.indexWhere((t) => t.id == transfer.id);
            if (index != -1) {
              _transfers[index] = _transfers[index].copyWith(
                transferredBytes: _transfers[index].fileSize,
                status: TransferStatus.completed,
              );
            }
            
            // 检查是否所有传输都已完成
            final allCompleted = _transfers.every((t) => 
              t.status == TransferStatus.completed || 
              t.status == TransferStatus.failed
            );
            
            if (allCompleted) {
              ref.read(isTransferringProvider.notifier).state = false;
            }
          });
          
          timer.cancel();
        }
      });
      
      // 添加到计时器列表
      _timers.add(timer);
    });
  }
  
  /// 取消传输
  void _cancelTransfer(String transferId) {
    setState(() {
      final index = _transfers.indexWhere((t) => t.id == transferId);
      if (index != -1) {
        _transfers[index] = _transfers[index].copyWith(
          status: TransferStatus.failed,
        );
      }
    });
  }
  
  /// 清除已完成的传输
  void _clearCompletedTransfers() {
    setState(() {
      _transfers.removeWhere((t) => 
        t.status == TransferStatus.completed || 
        t.status == TransferStatus.failed
      );
    });
  }
  
  /// 将文件复制到目标路径
  Future<void> _copyFileToTargetPath(FileTransfer transfer) async {
    if (transfer.targetPath == null) return;
    
    try {
      // 获取源文件路径
      final selectedFiles = ref.read(selectedFilesProvider);
      final sourceFilePath = selectedFiles.firstWhere(
        (path) => path.endsWith(transfer.fileName),
        orElse: () => '',
      );
      
      if (sourceFilePath.isEmpty) {
        print('未找到源文件: ${transfer.fileName}');
        return;
      }
      
      // 获取目标目录路径
      final targetPath = transfer.targetPath!;
      final lastSeparator = Platform.isWindows 
          ? targetPath.lastIndexOf('\\') 
          : targetPath.lastIndexOf('/');
      
      if (lastSeparator == -1) {
        print('无效的目标路径: $targetPath');
        return;
      }
      
      final targetDirPath = targetPath.substring(0, lastSeparator);
      
      // 创建目标目录
      final targetDir = Directory(targetDirPath);
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
      
      // 复制文件
      final sourceFile = File(sourceFilePath);
      final targetFile = File(targetPath);
      
      // 检查源文件是否存在
      if (!await sourceFile.exists()) {
        print('源文件不存在: $sourceFilePath');
        return;
      }
      
      // 检查目标文件是否已存在
      if (await targetFile.exists()) {
        // 如果目标文件已存在，先删除它
        await targetFile.delete();
      }
      
      try {
        // 尝试复制文件
        await sourceFile.copy(targetFile.path);
        print('文件已复制到: ${targetFile.path}');
        
        // 在macOS上，尝试打开目标文件所在的文件夹
        if (Platform.isMacOS) {
          await Process.run('open', [targetDirPath]);
        } else if (Platform.isWindows) {
          await Process.run('explorer', [targetDirPath]);
        }
      } catch (e) {
        print('复制文件失败，尝试使用备用方法: $e');
        
        // 备用方法：读取源文件内容并写入目标文件
        final bytes = await sourceFile.readAsBytes();
        await targetFile.writeAsBytes(bytes);
        print('使用备用方法复制文件成功: ${targetFile.path}');
      }
    } catch (e) {
      print('复制文件失败: $e');
      
      // 更新传输状态为失败
      final index = _transfers.indexWhere((t) => t.id == transfer.id);
      if (index != -1 && mounted) {
        setState(() {
          _transfers[index] = _transfers[index].copyWith(
            status: TransferStatus.failed,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isScanning = ref.watch(isScanningProvider);
    final isTransferring = ref.watch(isTransferringProvider);
    final selectedFiles = ref.watch(selectedFilesProvider);
    final devicesAsync = ref.watch(devicesProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('发送文件'),
        actions: [
          // 刷新按钮
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isScanning ? null : _startScanning,
            tooltip: '刷新设备',
          ),
          
          // 清除按钮
          if (_transfers.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.cleaning_services),
              onPressed: _clearCompletedTransfers,
              tooltip: '清除已完成',
            ),
        ],
      ),
      body: Column(
        children: [
          // 文件选择区域
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题
                const Text(
                  '选择文件',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                // 文件列表
                if (selectedFiles.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.dividerColor),
                    ),
                    child: Center(
                      child: Text(
                        '未选择文件',
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.dividerColor),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: selectedFiles.length,
                      itemBuilder: (context, index) {
                        return FileItem(
                          filePath: selectedFiles[index],
                          onDelete: () => _removeFile(index),
                        );
                      },
                    ),
                  ),
                
                // 选择文件按钮
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ElevatedButton.icon(
                    onPressed: _pickFiles,
                    icon: const Icon(Icons.add),
                    label: const Text('选择文件'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 设备列表
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Text(
                        '附近的设备',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      // 扫描指示器
                      if (isScanning)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                
                // 设备网格
                Expanded(
                  child: devicesAsync.when(
                    data: (devices) {
                      if (devices.isEmpty) {
                        return Center(
                          child: Text(
                            isScanning ? '正在扫描...' : '未发现设备',
                            style: TextStyle(
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        );
                      }
                      
                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: devices.length,
                        itemBuilder: (context, index) {
                          final device = devices[index];
                          return DeviceCard(
                            device: device,
                            onTap: isTransferring
                                ? null
                                : () => _connectToDevice(device),
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, stackTrace) => Center(
                      child: Text(
                        '加载设备失败: $error',
                        style: TextStyle(
                          color: AppTheme.errorColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 传输进度
          if (_transfers.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题
                  const Text(
                    '传输进度',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // 传输列表
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _transfers.length,
                    itemBuilder: (context, index) {
                      final transfer = _transfers[index];
                      return TransferProgress(
                        transfer: transfer,
                        startTime: DateTime.now().subtract(
                          const Duration(seconds: 5),
                        ),
                        onCancel: transfer.status == TransferStatus.transferring
                            ? () => _cancelTransfer(transfer.id)
                            : null,
                      );
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
