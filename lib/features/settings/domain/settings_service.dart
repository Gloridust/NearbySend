import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nearbysend/features/settings/presentation/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 设置服务提供者
final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

/// 设置服务
class SettingsService {
  static const String _settingsKey = 'app_settings';
  
  /// 获取设置
  Settings getSettings() {
    try {
      final prefs = SharedPreferences.getInstance();
      final settingsJson = prefs.then((prefs) => prefs.getString(_settingsKey));
      
      if (settingsJson == null) {
        return Settings.defaults();
      }
      
      return Settings.fromJson(jsonDecode(settingsJson as String));
    } catch (e) {
      // 如果出错，返回默认设置
      return Settings.defaults();
    }
  }
  
  /// 保存设置
  Future<void> saveSettings(Settings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(settings.toJson());
      
      await prefs.setString(_settingsKey, settingsJson);
    } catch (e) {
      // 处理保存错误
    }
  }
} 