import 'dart:io';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nearbysend/models/device.dart';
import 'package:nearbysend/models/transfer.dart';
import 'package:nearbysend/theme/app_theme.dart';
import 'package:nearbysend/utils/permissions.dart';
import 'package:nearbysend/widgets/device_card.dart';
import 'package:nearbysend/widgets/file_item.dart';
import 'package:nearbysend/widgets/transfer_progress.dart';

/// 发送页面
class SendScreen extends ConsumerStatefulWidget {
  /// 构造函数
  const SendScreen({super.key});

  @override
  ConsumerState<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends ConsumerState<SendScreen> {
  /// 选择的文件列表
  final List<String> _selectedFiles = [];
  
  /// 发现的设备列表
  final List<Device> _discoveredDevices = [];
  
  /// 传输列表
  final List<FileTransfer> _transfers = [];
  
  /// 是否正在扫描
  bool _isScanning = false;
  
  /// 是否正在传输
  bool _isTransferring = false;
  
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
    setState(() {
      _isScanning = true;
      
      // 模拟设备发现
      _discoveredDevices.clear();
      _discoveredDevices.addAll([
        const Device(
          id: '1',
          name: 'iPhone 13',
          deviceType: DeviceType.ios,
        ),
        const Device(
          id: '2',
          name: 'MacBook Pro',
          deviceType: DeviceType.macos,
        ),
        const Device(
          id: '3',
          name: 'Pixel 6',
          deviceType: DeviceType.android,
        ),
        const Device(
          id: '4',
          name: 'Surface Laptop',
          deviceType: DeviceType.windows,
        ),
      ]);
    });
    
    // 模拟扫描完成
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    });
  }
  
  /// 选择文件
  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );
      
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          for (final file in result.files) {
            if (file.path != null && !_selectedFiles.contains(file.path)) {
              _selectedFiles.add(file.path!);
            }
          }
        });
      }
    } catch (e) {
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
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }
  
  /// 连接到设备
  void _connectToDevice(Device device) {
    // 检查是否已选择文件
    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先选择要发送的文件'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }
    
    // 更新设备连接状态
    setState(() {
      final index = _discoveredDevices.indexWhere((d) => d.id == device.id);
      if (index != -1) {
        _discoveredDevices[index] = device.copyWith(isConnected: true);
      }
      
      // 模拟传输
      _isTransferring = true;
      
      // 为每个文件创建传输
      for (int i = 0; i < _selectedFiles.length; i++) {
        final file = File(_selectedFiles[i]);
        final transfer = FileTransfer(
          id: 'transfer_${device.id}_$i',
          fileName: file.uri.pathSegments.last,
          fileSize: file.lengthSync(),
          status: TransferStatus.connecting,
        );
        
        _transfers.add(transfer);
        
        // 模拟传输进度
        _simulateTransfer(transfer, i);
      }
    });
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
              _isTransferring = false;
              
              // 断开设备连接
              for (int i = 0; i < _discoveredDevices.length; i++) {
                _discoveredDevices[i] = _discoveredDevices[i].copyWith(
                  isConnected: false,
                );
              }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('发送文件'),
        actions: [
          // 刷新按钮
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isScanning ? null : _startScanning,
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
                if (_selectedFiles.isEmpty)
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
                      itemCount: _selectedFiles.length,
                      itemBuilder: (context, index) {
                        return FileItem(
                          filePath: _selectedFiles[index],
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
                      if (_isScanning)
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
                  child: _discoveredDevices.isEmpty
                      ? Center(
                          child: Text(
                            _isScanning ? '正在扫描...' : '未发现设备',
                            style: TextStyle(
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.8,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _discoveredDevices.length,
                          itemBuilder: (context, index) {
                            final device = _discoveredDevices[index];
                            return DeviceCard(
                              device: device,
                              onTap: _isTransferring
                                  ? null
                                  : () => _connectToDevice(device),
                            );
                          },
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
