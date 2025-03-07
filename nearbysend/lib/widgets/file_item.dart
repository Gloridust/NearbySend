import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nearbysend/theme/app_theme.dart';

/// 文件项组件
class FileItem extends StatelessWidget {
  /// 文件路径
  final String filePath;
  
  /// 文件名
  final String? fileName;
  
  /// 文件大小
  final int? fileSize;
  
  /// 删除回调
  final VoidCallback? onDelete;
  
  /// 构造函数
  const FileItem({
    super.key,
    required this.filePath,
    this.fileName,
    this.fileSize,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final file = File(filePath);
    final name = fileName ?? file.uri.pathSegments.last;
    final size = fileSize ?? file.lengthSync();
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // 文件图标
            Icon(
              _getFileIcon(name),
              size: 40,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 12),
            
            // 文件信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 文件名
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // 文件大小
                  Text(
                    _formatFileSize(size),
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            
            // 删除按钮
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.close),
                color: AppTheme.textSecondaryColor,
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
  
  /// 获取文件图标
  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'wmv':
      case 'flv':
      case 'mkv':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
      case 'ogg':
      case 'flac':
      case 'm4a':
        return Icons.audio_file;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return Icons.folder_zip;
      case 'txt':
      case 'md':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }
  
  /// 格式化文件大小
  String _formatFileSize(int size) {
    const int kb = 1024;
    const int mb = kb * 1024;
    const int gb = mb * 1024;
    
    if (size < kb) {
      return '$size B';
    } else if (size < mb) {
      return '${(size / kb).toStringAsFixed(1)} KB';
    } else if (size < gb) {
      return '${(size / mb).toStringAsFixed(1)} MB';
    } else {
      return '${(size / gb).toStringAsFixed(1)} GB';
    }
  }
}
