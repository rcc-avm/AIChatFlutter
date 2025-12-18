import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/settings_section.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Map<String, bool> _expandedSections = {
    'general': true,
    'chat': true,
    'interface': true,
    'advanced': false,
  };

  void _toggleSection(String section) {
    setState(() {
      _expandedSections[section] = !(_expandedSections[section] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF262626),
        title: const Text('Настройки'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          if (settings.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (settings.error != null) {
            return Center(
              child: Text(
                'Ошибка загрузки настроек: ${settings.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Общие настройки
              SettingsSection(
                title: 'Общие',
                isExpanded: _expandedSections['general'] ?? true,
                onToggle: () => _toggleSection('general'),
                children: [
                  SettingsDropdown<String>(
                    title: 'Язык',
                    value: settings.language,
                    items: const [
                      DropdownMenuItem(value: 'ru', child: Text('Русский')),
                      DropdownMenuItem(value: 'en', child: Text('English')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        settings.updateSetting('language', value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SettingsSwitch(
                    title: 'Автоматическое обновление',
                    subtitle:
                        'Автоматически проверять и устанавливать обновления',
                    value: settings.autoUpdate,
                    onChanged: (value) {
                      settings.updateSetting('auto_update', value);
                    },
                  ),
                ],
              ),

              // Настройки чата
              SettingsSection(
                title: 'Чат',
                isExpanded: _expandedSections['chat'] ?? true,
                onToggle: () => _toggleSection('chat'),
                children: [
                  SettingsDropdown<String>(
                    title: 'Модель по умолчанию',
                    value: settings.defaultModel,
                    items: const [
                      DropdownMenuItem(
                        value: 'gpt-3.5-turbo',
                        child: Text('GPT-3.5 Turbo'),
                      ),
                      DropdownMenuItem(
                        value: 'claude-3-sonnet',
                        child: Text('Claude 3 Sonnet'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        settings.updateSetting('default_model', value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SettingsSlider(
                    title: 'Максимальное количество токенов',
                    value: settings.maxTokens.toDouble(),
                    min: 100,
                    max: 4000,
                    divisions: 39,
                    labelFormatter: (value) => value.toInt().toString(),
                    onChanged: (value) {
                      settings.updateSetting('max_tokens', value.toInt());
                    },
                  ),
                  const SizedBox(height: 16),
                  SettingsSlider(
                    title: 'Температура',
                    subtitle: 'Влияет на креативность ответов',
                    value: settings.temperature,
                    min: 0,
                    max: 2,
                    divisions: 20,
                    labelFormatter: (value) => value.toStringAsFixed(1),
                    onChanged: (value) {
                      settings.updateSetting('temperature', value);
                    },
                  ),
                  const SizedBox(height: 16),
                  SettingsSwitch(
                    title: 'Сохранение истории',
                    value: settings.saveHistory,
                    onChanged: (value) {
                      settings.updateSetting('save_history', value);
                    },
                  ),
                ],
              ),

              // Настройки интерфейса
              SettingsSection(
                title: 'Интерфейс',
                isExpanded: _expandedSections['interface'] ?? true,
                onToggle: () => _toggleSection('interface'),
                children: [
                  SettingsDropdown<String>(
                    title: 'Тема',
                    value: settings.theme,
                    items: const [
                      DropdownMenuItem(value: 'dark', child: Text('Тёмная')),
                      DropdownMenuItem(value: 'light', child: Text('Светлая')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        settings.updateSetting('theme', value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SettingsSlider(
                    title: 'Размер шрифта',
                    value: settings.fontSize.toDouble(),
                    min: 12,
                    max: 24,
                    divisions: 12,
                    labelFormatter: (value) => value.toInt().toString(),
                    onChanged: (value) {
                      settings.updateSetting('ui.font_size', value.toInt());
                    },
                  ),
                  const SizedBox(height: 16),
                  SettingsSwitch(
                    title: 'Анимации',
                    value: settings.animationsEnabled,
                    onChanged: (value) {
                      settings.updateSetting('ui.animations_enabled', value);
                    },
                  ),
                  const SizedBox(height: 16),
                  SettingsSwitch(
                    title: 'Компактный режим',
                    value: settings.compactMode,
                    onChanged: (value) {
                      settings.updateSetting('ui.compact_mode', value);
                    },
                  ),
                ],
              ),

              // Расширенные настройки
              SettingsSection(
                title: 'Расширенные',
                isExpanded: _expandedSections['advanced'] ?? false,
                onToggle: () => _toggleSection('advanced'),
                children: [
                  SettingsSwitch(
                    title: 'Режим отладки',
                    value: settings.debugMode,
                    onChanged: (value) {
                      settings.updateSetting('advanced.debug_mode', value);
                    },
                  ),
                  const SizedBox(height: 16),
                  SettingsDropdown<String>(
                    title: 'Уровень логирования',
                    value: settings.logLevel,
                    items: const [
                      DropdownMenuItem(value: 'INFO', child: Text('INFO')),
                      DropdownMenuItem(value: 'DEBUG', child: Text('DEBUG')),
                      DropdownMenuItem(
                          value: 'WARNING', child: Text('WARNING')),
                      DropdownMenuItem(value: 'ERROR', child: Text('ERROR')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        settings.updateSetting('advanced.log_level', value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SettingsSlider(
                    title: 'Размер кэша',
                    subtitle: 'Максимальное количество сохраненных сообщений',
                    value: settings.cacheSize.toDouble(),
                    min: 50,
                    max: 500,
                    divisions: 9,
                    labelFormatter: (value) => value.toInt().toString(),
                    onChanged: (value) {
                      settings.updateSetting(
                          'advanced.cache_size', value.toInt());
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final storedContext = context;
                      final confirmed = await showDialog<bool>(
                        context: storedContext,
                        builder: (context) => AlertDialog(
                          title: const Text('Очистить историю'),
                          content: const Text(
                            'Вы уверены, что хотите удалить всю историю сообщений? Это действие нельзя отменить.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Отмена'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Очистить'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        try {
                          final chatProvider =
                              storedContext.read<ChatProvider>();
                          await chatProvider.clearHistory();
                          ScaffoldMessenger.of(storedContext).showSnackBar(
                            const SnackBar(
                              content: Text('История сообщений очищена'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(storedContext).showSnackBar(
                            SnackBar(
                              content: Text('Ошибка: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Очистить историю сообщений'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Очищает все сохраненные сообщения из локальной базы данных',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
