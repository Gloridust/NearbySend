import 'package:flutter/material.dart';
import 'package:nearbysend/core/models/file_transfer.dart';

/// 文件传输项组件
class FileTransferItem extends StatelessWidget {
  final FileTransfer transfer;

  const FileTransferItem({
    super.key,
    required this.transfer,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildFileIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transfer.fileName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatFileSize(transfer.fileSize),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusIcon(),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: transfer.progress,
              backgroundColor: Colors.grey[200],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getStatusText(),
                  style: TextStyle(
                    color: _getStatusColor(),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${(transfer.progress * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建文件图标
  Widget _buildFileIcon() {
    IconData iconData;
    Color iconColor;

    if (transfer.fileName.endsWith('.pdf')) {
      iconData = Icons.picture_as_pdf;
      iconColor = Colors.red;
    } else if (transfer.fileName.endsWith('.jpg') || 
               transfer.fileName.endsWith('.jpeg') || 
               transfer.fileName.endsWith('.png')) {
      iconData = Icons.image;
      iconColor = Colors.blue;
    } else if (transfer.fileName.endsWith('.mp4') || 
               transfer.fileName.endsWith('.mov')) {
      iconData = Icons.video_file;
      iconColor = Colors.purple;
    } else if (transfer.fileName.endsWith('.mp3') || 
               transfer.fileName.endsWith('.wav')) {
      iconData = Icons.audio_file;
      iconColor = Colors.orange;
    } else {
      iconData = Icons.insert_drive_file;
      iconColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  /// 构建状态图标
  Widget _buildStatusIcon() {
    IconData iconData;
    Color iconColor;

    switch (transfer.status) {
      case TransferStatus.completed:
        iconData = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case TransferStatus.failed:
        iconData = Icons.error;
        iconColor = Colors.red;
        break;
      case TransferStatus.canceled:
        iconData = Icons.cancel;
        iconColor = Colors.orange;
        break;
      case TransferStatus.paused:
        iconData = Icons.pause_circle;
        iconColor = Colors.amber;
        break;
      default:
        iconData = Icons.sync;
        iconColor = Colors.blue;
        break;
    }

    return Icon(
      iconData,
      color: iconColor,
    );
  }

  /// 获取状态文本
  String _getStatusText() {
    switch (transfer.status) {
      case TransferStatus.pending:
        return '等待中';
      case TransferStatus.inProgress:
        return '传输中';
      case TransferStatus.completed:
        return '已完成';
      case TransferStatus.failed:
        return '失败';
      case TransferStatus.canceled:
        return '已取消';
      case TransferStatus.paused:
        return '已暂停';
    }
  }

  /// 获取状态颜色
  Color _getStatusColor() {
    switch (transfer.status) {
      case TransferStatus.completed:
        return Colors.green;
      case TransferStatus.failed:
        return Colors.red;
      case TransferStatus.canceled:
        return Colors.orange;
      case TransferStatus.paused:
        return Colors.amber;
      default:
        return Colors.blue;
    }
  }

  /// 格式化文件大小
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
} 