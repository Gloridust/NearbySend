import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nearbysend/app/app.dart';

void main() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 使用Riverpod作为状态管理
  runApp(
    const ProviderScope(
      child: NearbySendApp(),
    ),
  );
} 