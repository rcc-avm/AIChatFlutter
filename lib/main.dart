// Импорт основных виджетов Flutter
import 'package:flutter/material.dart';
// Импорт пакета для работы с .env файлами
import 'package:flutter_dotenv/flutter_dotenv.dart';
// Импорт пакета для локализации приложения
import 'package:flutter_localizations/flutter_localizations.dart';
// Импорт пакета для работы с провайдерами состояния
import 'package:provider/provider.dart';
// Импорт кастомного провайдера для управления состоянием чата
import 'providers/chat_provider.dart';
// Импорт экранов
import 'screens/auth_screen.dart';

// Основная точка входа в приложение
void main() async {
  try {
    // Инициализация Flutter биндингов
    WidgetsFlutterBinding.ensureInitialized();

    // Настройка обработки ошибок Flutter
    FlutterError.onError = (FlutterErrorDetails details) {
      debugPrint('Flutter error: ${details.exception}');
      debugPrint('Stack trace: ${details.stack}');
    };

    // Загрузка переменных окружения из .env файла
    await dotenv.load(fileName: ".env");
    debugPrint('Environment loaded');
    debugPrint('API Key present: ${dotenv.env['OPENROUTER_API_KEY'] != null}');
    debugPrint('Base URL: ${dotenv.env['BASE_URL']}');

    // Создание провайдера
    final chatProvider = await ChatProvider.create().catchError((e) {
      debugPrint('Error creating ChatProvider: $e');
      // Если ошибка связана с отсутствием авторизации, это нормально
      if (e.toString().contains('Не найдены данные авторизации')) {
        return ChatProvider.create();
      }
      throw e; // Используем throw вместо rethrow вне catch блока
    });

    // Запуск приложения
    runApp(
      AppRoot(
        chatProvider: chatProvider,
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('Error starting app: $e');
    debugPrint('Stack trace: $stackTrace');
    runApp(ErrorApp(error: e.toString()));
  }
}

// Виджет для отображения ошибок приложения
class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Error starting app: $error',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

// Корневой виджет приложения
class AppRoot extends StatelessWidget {
  final ChatProvider chatProvider;

  const AppRoot({
    super.key,
    required this.chatProvider,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: chatProvider,
      child: MaterialApp(
        builder: (context, child) {
          return ScrollConfiguration(
            behavior: ScrollBehavior(),
            child: child!,
          );
        },
        title: 'AI Chat',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ru', 'RU'),
        supportedLocales: const [
          Locale('ru', 'RU'),
          Locale('en', 'US'),
        ],
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: _buildTheme(),
        home: const AuthScreen(),
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF1E1E1E),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF262626),
        foregroundColor: Colors.white,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 16,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
