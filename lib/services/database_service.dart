// Импорт основных классов Flutter
import 'package:flutter/foundation.dart';
// Импорт утилит для работы с путями
import 'package:path/path.dart';
// Импорт основного пакета для работы с SQLite
import 'package:sqflite/sqflite.dart';
// Импорт модели сообщения
import '../models/message.dart';

// Класс сервиса для работы с базой данных
class DatabaseService {
  // Единственный экземпляр класса (Singleton)
  static final DatabaseService _instance = DatabaseService._internal();
  // Экземпляр базы данных
  Database? _db;
  // Название таблицы
  static const String _tableName = 'messages';
  // Флаг инициализации
  bool _initialized = false;

  // Фабричный метод для получения экземпляра
  factory DatabaseService() {
    return _instance;
  }

  // Приватный конструктор для реализации Singleton
  DatabaseService._internal();

  // Метод инициализации базы данных
  Future<void> _initDatabase() async {
    if (_initialized) return;

    try {
      if (kIsWeb) {
        // На веб-платформе используем in-memory базу данных
        _db = await openDatabase(
          ':memory:',
          version: 1,
          onCreate: _onCreate,
        );
      } else {
        // На остальных платформах используем файловую базу данных
        final dbPath = await getDatabasesPath();
        final path = join(dbPath, 'chat_cache.db');
        _db = await openDatabase(
          path,
          version: 1,
          onCreate: _onCreate,
        );
      }
      _initialized = true;
    } catch (e) {
      debugPrint('Error initializing database: $e');
      rethrow;
    }
  }

  // Метод создания таблицы
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content TEXT NOT NULL,
        is_user INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        model_id TEXT,
        tokens INTEGER,
        cost REAL
      )
    ''');
  }

  // Метод получения экземпляра базы данных
  Future<Database> _getDatabase() async {
    if (!_initialized) {
      await _initDatabase();
    }
    return _db!;
  }

  // Метод сохранения сообщения
  Future<void> saveMessage(ChatMessage message) async {
    try {
      final db = await _getDatabase();
      await db.insert(
        _tableName,
        {
          'content': message.content,
          'is_user': message.isUser ? 1 : 0,
          'timestamp': message.timestamp.toIso8601String(),
          'model_id': message.modelId,
          'tokens': message.tokens,
          'cost': message.cost,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error saving message: $e');
    }
  }

  // Метод получения сообщений
  Future<List<ChatMessage>> getMessages({int limit = 50}) async {
    try {
      final db = await _getDatabase();
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        orderBy: 'timestamp ASC',
        limit: limit,
      );

      return List.generate(maps.length, (i) {
        return ChatMessage(
          content: maps[i]['content'] as String,
          isUser: maps[i]['is_user'] == 1,
          timestamp: DateTime.parse(maps[i]['timestamp'] as String),
          modelId: maps[i]['model_id'] as String?,
          tokens: maps[i]['tokens'] as int?,
          cost: maps[i]['cost'] as double?,
        );
      });
    } catch (e) {
      debugPrint('Error getting messages: $e');
      return [];
    }
  }

  // Метод очистки истории
  Future<void> clearHistory() async {
    try {
      final db = await _getDatabase();
      await db.delete(_tableName);
    } catch (e) {
      debugPrint('Error clearing history: $e');
    }
  }

  // Метод получения статистики
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final db = await _getDatabase();

      final totalMessagesResult =
          await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
      final totalMessages = Sqflite.firstIntValue(totalMessagesResult) ?? 0;

      final totalTokensResult = await db.rawQuery(
          'SELECT SUM(tokens) as total FROM $_tableName WHERE tokens IS NOT NULL');
      final totalTokens = Sqflite.firstIntValue(totalTokensResult) ?? 0;

      final modelStats = await db.rawQuery('''
        SELECT 
          model_id,
          COUNT(*) as message_count,
          SUM(tokens) as total_tokens
        FROM $_tableName 
        WHERE model_id IS NOT NULL 
        GROUP BY model_id
      ''');

      final modelUsage = <String, Map<String, int>>{};
      for (final stat in modelStats) {
        final modelId = stat['model_id'] as String;
        modelUsage[modelId] = {
          'count': stat['message_count'] as int,
          'tokens': stat['total_tokens'] as int? ?? 0,
        };
      }

      return {
        'total_messages': totalMessages,
        'total_tokens': totalTokens,
        'model_usage': modelUsage,
      };
    } catch (e) {
      debugPrint('Error getting statistics: $e');
      return {
        'total_messages': 0,
        'total_tokens': 0,
        'model_usage': {},
      };
    }
  }
}
