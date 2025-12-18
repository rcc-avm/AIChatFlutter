import 'package:flutter/material.dart';

enum NavigationTab {
  chat,
  profile,
  tokenStats,
  expenseChart,
  history,
}

class NavigationProvider with ChangeNotifier {
  NavigationTab _currentTab = NavigationTab.chat;
  final Map<NavigationTab, bool> _hasUnreadContent = {
    NavigationTab.chat: false,
    NavigationTab.profile: false,
    NavigationTab.tokenStats: false,
    NavigationTab.expenseChart: false,
    NavigationTab.history: false,
  };

  // Геттеры
  NavigationTab get currentTab => _currentTab;
  bool hasUnreadContent(NavigationTab tab) => _hasUnreadContent[tab] ?? false;

  // Смена текущей вкладки
  void setCurrentTab(NavigationTab tab) {
    if (_currentTab != tab) {
      _currentTab = tab;
      // Сбрасываем флаг непрочитанного контента при переходе на вкладку
      _hasUnreadContent[tab] = false;
      notifyListeners();
    }
  }

  // Установка флага непрочитанного контента
  void setUnreadContent(NavigationTab tab, {bool value = true}) {
    if (_hasUnreadContent[tab] != value) {
      _hasUnreadContent[tab] = value;
      notifyListeners();
    }
  }

  // Получение названия вкладки
  String getTabTitle(NavigationTab tab) {
    switch (tab) {
      case NavigationTab.chat:
        return 'Чат';
      case NavigationTab.profile:
        return 'Профиль';
      case NavigationTab.tokenStats:
        return 'Статистика токенов';
      case NavigationTab.expenseChart:
        return 'Расходы';
      case NavigationTab.history:
        return 'История';
    }
  }

  // Получение иконки вкладки
  IconData getTabIcon(NavigationTab tab) {
    switch (tab) {
      case NavigationTab.chat:
        return Icons.chat;
      case NavigationTab.profile:
        return Icons.person;
      case NavigationTab.tokenStats:
        return Icons.bar_chart;
      case NavigationTab.expenseChart:
        return Icons.timeline;
      case NavigationTab.history:
        return Icons.history;
    }
  }

  // Проверка доступности вкладки
  bool isTabEnabled(NavigationTab tab) {
    // Здесь можно добавить логику проверки доступности вкладок
    // Например, некоторые вкладки могут быть недоступны без авторизации
    return true;
  }
}
