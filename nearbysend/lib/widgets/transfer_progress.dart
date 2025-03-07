import 'package:flutter/material.dart';
import 'package:nearbysend/models/transfer.dart';
import 'package:nearbysend/theme/app_theme.dart';

/// 传输进度组件
class TransferProgress extends StatelessWidget {
  /// 文件传输信息
  final FileTransfer transfer;
  
  /// 传输开始时间
  final DateTime? startTime;
  
  /// 取消回调
  final VoidCallback? onCancel;
  
  /// 构造函数
  const TransferProgress({
    super.key,
    required this.transfer,
    this.startTime,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 文件名和状态
            Row(
              children: [
                Expanded(
                  child: Text(
                    transfer.fileName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // 状态标签
                _buildStatusLabel(),
              ],
            ),
            
            // 目标路径
            if (transfer.targetPath != null) ...[
              const SizedBox(height: 4),
              Text(
                '保存至: ${transfer.targetPath}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            
            const SizedBox(height: 12),
            
            // 进度条
            if (transfer.status == TransferStatus.transferring)
              LinearProgressIndicator(
                value: transfer.progressPercentage / 100,
                backgroundColor: AppTheme.backgroundColor,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
              ),
            const SizedBox(height: 12),
            
            // 传输信息
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 文件大小信息
                Text(
                  '${_formatBytes(transfer.transferredBytes)} / ${transfer.fileSizeText}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                
                // 传输速度
                if (transfer.status == TransferStatus.transferring && startTime != null)
                  Text(
                    _getSpeedText(),
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
              ],
            ),
            
            // 取消按钮
            if (transfer.status == TransferStatus.transferring && onCancel != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.cancel, size: 16),
                  label: const Text('取消'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// 构建状态标签
  Widget _buildStatusLabel() {
    late Color color;
    late IconData icon;
    
    switch (transfer.status) {
      case TransferStatus.pending:
        color = AppTheme.warningColor;
        icon = Icons.hourglass_empty;
        break;
      case TransferStatus.connecting:
        color = AppTheme.warningColor;
        icon = Icons.sync;
        break;
      case TransferStatus.transferring:
        color = AppTheme.primaryColor;
        icon = Icons.sync;
        break;
      case TransferStatus.completed:
        color = AppTheme.successColor;
        icon = Icons.check_circle;
        break;
      case TransferStatus.failed:
        color = AppTheme.errorColor;
        icon = Icons.error;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            transfer.statusText,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 格式化字节数
  String _formatBytes(int bytes) {
    const int kb = 1024;
    const int mb = kb * 1024;
    const int gb = mb * 1024;
    
    if (bytes < kb) {
      return '$bytes B';
    } else if (bytes < mb) {
      return '${(bytes / kb).toStringAsFixed(1)} KB';
    } else if (bytes < gb) {
      return '${(bytes / mb).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / gb).toStringAsFixed(1)} GB';
    }
  }
  
  /// 获取传输速度文本
  String _getSpeedText() {
    if (startTime == null) return '';
    
    final elapsed = DateTime.now().difference(startTime!);
    return transfer.getSpeedText(elapsed);
  }
}
