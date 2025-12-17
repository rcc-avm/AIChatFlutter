// Скрипт для просмотра последних сообщений из базы данных
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  // Инициализация для Linux
  if (Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final dbPath = await getDatabasesPath();
  final dbFile = p.join(dbPath, 'chat_cache.db');

  if (!File(dbFile).existsSync()) {
    print('База данных не найдена: $dbFile');
    return;
  }

  print('Подключаемся к базе данных: $dbFile');

  try {
    final db = await openReadOnlyDatabase(dbFile);

    // Получаем последние 10 сообщений
    final messages = await db.query(
      'messages',
      orderBy: 'timestamp DESC',
      limit: 10,
    );

    print('\n=== ПОСЛЕДНИЕ 10 СООБЩЕНИЙ ===\n');

    for (var msg in messages.reversed) {
      final id = msg['id'];
      final isUser = msg['is_user'] == 1;
      final content = msg['content'] as String?;
      final timestamp = msg['timestamp'];
      final modelId = msg['model_id'];
      final tokens = msg['tokens'];
      final cost = msg['cost'];

      print('ID: $id | ${isUser ? 'ПОЛЬЗОВАТЕЛЬ' : 'AI'}');
      print('Модель: $modelId | Токены: $tokens | Стоимость: $cost');
      print('Время: $timestamp');
      print(
          'Сообщение: ${content != null && content.length > 100 ? '${content.substring(0, 100)}...' : content}');
      print('-' * 50);
    }

    // Статистика
    final totalCount = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM messages')) ??
        0;
    print('\nВсего сообщений в базе: $totalCount');

    final userCount = Sqflite.firstIntValue(await db
            .rawQuery('SELECT COUNT(*) FROM messages WHERE is_user = 1')) ??
        0;
    final aiCount = Sqflite.firstIntValue(await db
            .rawQuery('SELECT COUNT(*) FROM messages WHERE is_user = 0')) ??
        0;

    print('Из них пользователь спросил: $userCount');
    print('AI ответило: $aiCount');

    await db.close();
  } catch (e) {
    print('Ошибка при чтении базы данных: $e');
  }
}
