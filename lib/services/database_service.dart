// Импорт основных классов Flutter
import 'package:flutter/foundation.dart';
// Импорт модели сообщения
import '../models/message.dart';

// Для не‑веб-платформ импортируем sqflite и path
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sqflite;

// Класс сервиса для работы с базой данных
class DatabaseService {
  // Единственный экземпляр класса (Singleton)
  static final DatabaseService _instance = DatabaseService._internal();
  // Экземпляр базы данных (на веб-платформе не используется)
  dynamic _db;
  // Название таблицы
  static const String _tableName = 'messages';
  // Флаг инициализации
  bool _initialized = false;
  // На веб-платформе храним сообщения в памяти
  List<Map<String, dynamic>> _webMessages = [];

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
        // На веб-платформе используем in‑memory хранилище
        _db = null; // не используется
        _initialized = true;
      } else {
        // На остальных платформах используем файловую базу данных
        final dbPath = await sqflite.getDatabasesPath();
        final dbFullPath = path.join(dbPath, 'chat_cache.db');
        _db = await sqflite.openDatabase(
          dbFullPath,
          version: 1,
          onCreate: _onCreate,
        );
        _initialized = true;
      }
    } catch (e) {
      debugPrint('Error initializing database: $e');
      rethrow;
    }
  }

  // Метод создания таблицы (только для не‑веб)
  Future<void> _onCreate(sqflite.Database db, int version) async {
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
  Future<dynamic> _getDatabase() async {
    if (!_initialized) {
      await _initDatabase();
    }
    return _db;
  }

  // Метод сохранения сообщения
  Future<void> saveMessage(ChatMessage message) async {
    try {
      if (kIsWeb) {
        // На веб‑платформе добавляем сообщение в список
        _webMessages.add({
          'content': message.content,
          'is_user': message.isUser ? 1 : 0,
          'timestamp': message.timestamp.toIso8601String(),
          'model_id': message.modelId,
          'tokens': message.tokens,
          'cost': message.cost,
        });
      } else {
        final db = await _getDatabase() as sqflite.Database;
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
          conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      debugPrint('Error saving message: $e');
    }
  }

  // Метод получения сообщений
  Future<List<ChatMessage>> getMessages({int limit = 50}) async {
    try {
      if (kIsWeb) {
        // На веб‑платформе возвращаем сообщения из памяти
        final messages = _webMessages
            .map((map) => ChatMessage(
                  content: map['content'] as String,
                  isUser: map['is_user'] == 1,
                  timestamp: DateTime.parse(map['timestamp'] as String),
                  modelId: map['model_id'] as String?,
                  tokens: map['tokens'] as int?,
                  cost: map['cost'] as double?,
                ))
            .toList();
        // Сортируем по времени (старые первыми)
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        return messages.length > limit ? messages.sublist(0, limit) : messages;
      } else {
        final db = await _getDatabase() as sqflite.Database;
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
      }
    } catch (e) {
      debugPrint('Error getting messages: $e');
      return [];
    }
  }

  // Метод очистки истории
  Future<void> clearHistory() async {
    try {
      if (kIsWeb) {
        _webMessages.clear();
      } else {
        final db = await _getDatabase() as sqflite.Database;
        await db.delete(_tableName);
      }
    } catch (e) {
      debugPrint('Error clearing history: $e');
    }
  }

  // Метод получения статистики
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      if (kIsWeb) {
        final totalMessages = _webMessages.length;
        int totalTokens = 0;
        final modelUsage = <String, Map<String, int>>{};
        for (final msg in _webMessages) {
          final modelId = msg['model_id'] as String?;
          if (modelId != null) {
            modelUsage.putIfAbsent(modelId, () => {'count': 0, 'tokens': 0});
            modelUsage[modelId]!['count'] = modelUsage[modelId]!['count']! + 1;
            final tokens = msg['tokens'] as int? ?? 0;
            modelUsage[modelId]!['tokens'] =
                modelUsage[modelId]!['tokens']! + tokens;
            totalTokens += tokens;
          }
        }
        return {
          'total_messages': totalMessages,
          'total_tokens': totalTokens,
          'model_usage': modelUsage,
        };
      } else {
        final db = await _getDatabase() as sqflite.Database;

        final totalMessagesResult =
            await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
        final totalMessages =
            sqflite.Sqflite.firstIntValue(totalMessagesResult) ?? 0;

        final totalTokensResult = await db.rawQuery(
            'SELECT SUM(tokens) as total FROM $_tableName WHERE tokens IS NOT NULL');
        final totalTokens =
            sqflite.Sqflite.firstIntValue(totalTokensResult) ?? 0;

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
      }
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
