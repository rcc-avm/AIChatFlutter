class AuthData {
  final String apiKey;
  final String pin;
  final String provider; // 'openrouter' или 'vsegpt'

  AuthData({
    required this.apiKey,
    required this.pin,
    required this.provider,
  });

  // Преобразование в Map для сохранения в базе данных
  Map<String, dynamic> toMap() {
    return {
      'api_key': apiKey,
      'pin': pin,
      'provider': provider,
    };
  }

  // Создание объекта из Map
  factory AuthData.fromMap(Map<String, dynamic> map) {
    return AuthData(
      apiKey: map['api_key'],
      pin: map['pin'],
      provider: map['provider'],
    );
  }

  // Определение провайдера по формату ключа
  static String determineProvider(String apiKey) {
    if (apiKey.startsWith('sk-or-vv-')) {
      return 'vsegpt';
    } else if (apiKey.startsWith('sk-or-v1-')) {
      return 'openrouter';
    } else {
      throw Exception('Неподдерживаемый формат ключа API');
    }
  }

  // Генерация PIN-кода
  static String generatePin() {
    // Генерация случайного 4-значного числа
    final pin = (1000 + DateTime.now().millisecondsSinceEpoch % 9000)
        .toString()
        .padLeft(4, '0');
    return pin;
  }
}
