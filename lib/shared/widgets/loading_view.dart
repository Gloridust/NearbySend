import 'package:flutter/material.dart';

/// 通用加载视图
class LoadingView extends StatelessWidget {
  final String message;

  const LoadingView({
    super.key,
    this.message = '加载中...',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
} 