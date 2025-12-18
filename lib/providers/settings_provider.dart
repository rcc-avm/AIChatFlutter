import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SettingsProvider with ChangeNotifier {
  Map<String, dynamic> _settings = {};
  bool _isLoading = true;
  String? _error;

  SettingsProvider._();

  // Геттеры для настроек
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get settings => Map.unmodifiable(_settings);

  // Геттеры для конкретных настроек
  String get theme => _settings['theme'] ?? 'dark';
  String get defaultModel => _settings['default_model'] ?? 'gpt-3.5-turbo';
  int get maxTokens => _settings['max_tokens'] ?? 1000;
  double get temperature => _settings['temperature'] ?? 0.7;
  bool get saveHistory => _settings['save_history'] ?? true;
  bool get autoUpdate => _settings['auto_update'] ?? false;
  bool get backupEnabled => _settings['backup_enabled'] ?? true;
  int get backupInterval => _settings['backup_interval'] ?? 24;
  bool get metricsCollection => _settings['metrics_collection'] ?? true;
  String get language => _settings['language'] ?? 'en';

  // Геттеры для UI настроек
  int get fontSize => _settings['ui']?['font_size'] ?? 16;
  bool get animationsEnabled => _settings['ui']?['animations_enabled'] ?? true;
  bool get compactMode => _settings['ui']?['compact_mode'] ?? false;

  // Геттеры для расширенных настроек
  bool get debugMode => _settings['advanced']?['debug_mode'] ?? false;
  String get logLevel => _settings['advanced']?['log_level'] ?? 'INFO';
  int get cacheSize => _settings['advanced']?['cache_size'] ?? 100;
  int get timeout => _settings['advanced']?['timeout'] ?? 30;

  // Фабричный метод для создания провайдера
  static Future<SettingsProvider> create() async {
    final provider = SettingsProvider._();
    await provider._loadSettings();
    return provider;
  }

  // Загрузка настроек
  Future<void> _loadSettings() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final String jsonString =
          await rootBundle.loadString('app_settings.json');
      _settings = json.decode(jsonString);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error loading settings: $e');
    }
  }

  // Обновление настроек
  Future<void> updateSettings(Map<String, dynamic> newSettings) async {
    try {
      _settings = {..._settings, ...newSettings};
      notifyListeners();
      await _saveSettings();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('Error updating settings: $e');
    }
  }

  // Обновление конкретной настройки
  Future<void> updateSetting(String key, dynamic value) async {
    try {
      if (key.contains('.')) {
        final keys = key.split('.');
        var current = _settings;
        for (var i = 0; i < keys.length - 1; i++) {
          current = current[keys[i]] ??= {};
        }
        current[keys.last] = value;
      } else {
        _settings[key] = value;
      }
      notifyListeners();
      await _saveSettings();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('Error updating setting: $e');
    }
  }

  // Сохранение настроек
  Future<void> _saveSettings() async {
    try {
      final String jsonString = json.encode(_settings);
      // TODO: Реализовать сохранение в файл
      debugPrint('Settings would be saved: $jsonString');
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('Error saving settings: $e');
    }
  }

  // Сброс настроек
  Future<void> resetSettings() async {
    try {
      await _loadSettings();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('Error resetting settings: $e');
    }
  }
}
