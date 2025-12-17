import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/auth_data.dart';
import '../api/openrouter_client.dart';

class AuthService {
  static const String _tableName = 'auth';
  static const String _keyPrefsKey = 'api_key';
  static const String _pinPrefsKey = 'pin';
  static const String _providerPrefsKey = 'provider';

  late final SharedPreferences _prefs;
  Database? _db;
  bool _initialized = false;

  AuthService._();

  // Фабричный метод для создания экземпляра сервиса
  static Future<AuthService> create() async {
    final service = AuthService._();
    await service._init();
    return service;
  }

  Future<void> _init() async {
    if (_initialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();

      if (!kIsWeb) {
        final dbPath = await getDatabasesPath();
        final path = join(dbPath, 'auth.db');
        _db = await openDatabase(
          path,
          version: 1,
          onCreate: (Database db, int version) async {
            await db.execute('''
              CREATE TABLE $_tableName (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                api_key TEXT NOT NULL,
                pin TEXT NOT NULL,
                provider TEXT NOT NULL
              )
            ''');
          },
        );
      }

      _initialized = true;
    } catch (e) {
      debugPrint('Error initializing AuthService: $e');
      rethrow;
    }
  }

  // Проверка наличия сохраненных данных авторизации
  Future<bool> hasAuthData() async {
    try {
      if (kIsWeb) {
        return _prefs.containsKey(_keyPrefsKey);
      } else {
        if (_db == null) return false;
        final result = await _db!.query(_tableName, limit: 1);
        return result.isNotEmpty;
      }
    } catch (e) {
      debugPrint('Error checking auth data: $e');
      return false;
    }
  }

  // Получение сохраненных данных авторизации
  Future<AuthData?> getAuthData() async {
    try {
      if (kIsWeb) {
        final apiKey = _prefs.getString(_keyPrefsKey);
        final pin = _prefs.getString(_pinPrefsKey);
        final provider = _prefs.getString(_providerPrefsKey);
        if (apiKey == null || pin == null || provider == null) return null;
        return AuthData(apiKey: apiKey, pin: pin, provider: provider);
      } else {
        if (_db == null) return null;
        final result = await _db!.query(_tableName, limit: 1);
        if (result.isEmpty) return null;
        return AuthData.fromMap(result.first);
      }
    } catch (e) {
      debugPrint('Error getting auth data: $e');
      return null;
    }
  }

  // Сохранение данных авторизации
  Future<void> saveAuthData(AuthData data) async {
    try {
      if (kIsWeb) {
        await _prefs.setString(_keyPrefsKey, data.apiKey);
        await _prefs.setString(_pinPrefsKey, data.pin);
        await _prefs.setString(_providerPrefsKey, data.provider);
      } else {
        if (_db == null) return;
        await _db!.delete(_tableName); // Удаляем старые данные
        await _db!.insert(_tableName, data.toMap());
      }
    } catch (e) {
      debugPrint('Error saving auth data: $e');
      rethrow;
    }
  }

  // Удаление данных авторизации
  Future<void> clearAuthData() async {
    try {
      if (kIsWeb) {
        await _prefs.remove(_keyPrefsKey);
        await _prefs.remove(_pinPrefsKey);
        await _prefs.remove(_providerPrefsKey);
      } else {
        if (_db == null) return;
        await _db!.delete(_tableName);
      }
    } catch (e) {
      debugPrint('Error clearing auth data: $e');
      rethrow;
    }
  }

  // Проверка валидности API ключа
  Future<bool> validateApiKey(String apiKey) async {
    try {
      final client = OpenRouterClient(
        apiKey: apiKey,
        baseUrl: apiKey.startsWith('sk-or-vv-')
            ? 'https://api.vsetgpt.ru/v1'
            : 'https://openrouter.ai/api/v1',
      );
      final balance = await client.getBalance();
      return balance.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Проверка PIN-кода
  Future<bool> validatePin(String pin) async {
    final authData = await getAuthData();
    return authData?.pin == pin;
  }

  // Инициализация новой авторизации
  Future<AuthData> initializeAuth(String apiKey) async {
    // Проверяем валидность ключа
    if (!await validateApiKey(apiKey)) {
      throw Exception('Недействительный ключ API или отсутствует баланс');
    }

    // Определяем провайдера и генерируем PIN
    final provider = AuthData.determineProvider(apiKey);
    final pin = AuthData.generatePin();

    // Создаем и сохраняем данные авторизации
    final authData = AuthData(
      apiKey: apiKey,
      pin: pin,
      provider: provider,
    );
    await saveAuthData(authData);

    return authData;
  }
}
