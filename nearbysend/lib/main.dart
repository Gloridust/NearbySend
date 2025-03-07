import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nearbysend/screens/send_screen.dart';
import 'package:nearbysend/screens/settings_screen.dart';
import 'package:nearbysend/theme/app_theme.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

/// 主应用
class MyApp extends StatelessWidget {
  /// 构造函数
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NearbySend',
      theme: AppTheme.lightTheme,
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// 主屏幕
class MainScreen extends StatefulWidget {
  /// 构造函数
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  /// 当前页面索引
  int _currentIndex = 0;
  
  /// 页面列表
  final List<Widget> _pages = [
    const SendScreen(),
    const SettingsScreen(),
  ];
  
  /// 页面标题
  final List<String> _titles = [
    '发送文件',
    '设置',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.send),
            label: '发送',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}
