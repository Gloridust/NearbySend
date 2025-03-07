import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nearbysend/app/routes/app_router.dart';
import 'package:nearbysend/shared/constants/app_constants.dart';

/// 应用主页面
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NearbySend'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go(AppRoutes.settings),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 60,
              backgroundColor: Colors.blue,
              child: Icon(
                Icons.send_to_mobile,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              '快速传输文件',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '无需连接同一网络，即可快速传输文件',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 60),
            ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('发现设备'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
              ),
              onPressed: () => context.go(AppRoutes.deviceDiscovery),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              icon: const Icon(Icons.file_open),
              label: const Text('选择文件'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
              ),
              onPressed: () {
                // 显示文件选择器
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('请先发现设备再选择文件'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 