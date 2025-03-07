import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nearbysend/features/device_discovery/presentation/device_discovery_screen.dart';
import 'package:nearbysend/features/file_transfer/presentation/file_transfer_screen.dart';
import 'package:nearbysend/features/settings/presentation/settings_screen.dart';
import 'package:nearbysend/shared/widgets/home_screen.dart';

/// 路由名称常量
class AppRoutes {
  static const home = '/';
  static const deviceDiscovery = '/device-discovery';
  static const fileTransfer = '/file-transfer';
  static const settings = '/settings';
}

/// 路由提供者
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.deviceDiscovery,
        builder: (context, state) => const DeviceDiscoveryScreen(),
      ),
      GoRoute(
        path: AppRoutes.fileTransfer,
        builder: (context, state) {
          final deviceId = state.queryParameters['deviceId'] ?? '';
          return FileTransferScreen(deviceId: deviceId);
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('路由错误: ${state.error}'),
      ),
    ),
  );
}); 