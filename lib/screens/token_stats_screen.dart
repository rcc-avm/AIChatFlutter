import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';

class TokenStatsScreen extends StatefulWidget {
  const TokenStatsScreen({super.key});

  @override
  State<TokenStatsScreen> createState() => _TokenStatsScreenState();
}

class _TokenStatsScreenState extends State<TokenStatsScreen> {
  Map<String, Map<String, dynamic>> _stats = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final chatProvider = context.read<ChatProvider>();
      await Future.delayed(
          const Duration(milliseconds: 500)); // Simulate loading

      // Calculate stats from messages
      _stats = chatProvider.messages.fold<Map<String, Map<String, dynamic>>>(
        {},
        (map, message) {
          if (message.modelId != null) {
            if (!map.containsKey(message.modelId)) {
              map[message.modelId!] = {
                'count': 0,
                'tokens': 0,
                'cost': 0.0,
                'name': message.modelId,
              };
            }
            map[message.modelId]!['count'] =
                map[message.modelId]!['count']! + 1;
            if (message.tokens != null) {
              map[message.modelId]!['tokens'] =
                  map[message.modelId]!['tokens']! + message.tokens!;
            }
            if (message.cost != null) {
              map[message.modelId]!['cost'] =
                  map[message.modelId]!['cost']! + message.cost!;
            }
          }
          return map;
        },
      );
    } catch (e) {
      // Handle error silently
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF262626),
        title: const Text('Статистика токенов'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
            tooltip: 'Обновить статистику',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stats.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bar_chart,
                        size: 64,
                        color: Colors.blue.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Нет данных для статистики',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Отправьте несколько сообщений,\nчтобы увидеть статистику',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      color: const Color(0xFF262626),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Общая статистика',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildStatItem(
                                  'Всего сообщений',
                                  _stats.values
                                      .fold<int>(
                                          0,
                                          (sum, model) =>
                                              sum + (model['count'] as int))
                                      .toString(),
                                  Icons.message,
                                  Colors.blue,
                                ),
                                _buildStatItem(
                                  'Всего токенов',
                                  _stats.values
                                      .fold<int>(
                                          0,
                                          (sum, model) =>
                                              sum + (model['tokens'] as int))
                                      .toString(),
                                  Icons.data_usage,
                                  Colors.green,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._stats.entries.map((entry) {
                      final modelStats = entry.value;
                      return Card(
                        color: const Color(0xFF262626),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          leading: Icon(
                            Icons.model_training,
                            color: Colors.amber,
                          ),
                          title: Text(
                            entry.key,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'Сообщений: ${modelStats['count']}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Токенов: ${modelStats['tokens']}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              Consumer<ChatProvider>(
                                builder: (context, chatProvider, child) {
                                  final isVsetgpt = chatProvider.baseUrl
                                          ?.contains('vsegpt.ru') ==
                                      true;
                                  return Text(
                                    modelStats['cost']! < 1e-8
                                        ? isVsetgpt
                                            ? 'Стоимость: <0.001₽'
                                            : 'Стоимость: <\$0.001'
                                        : isVsetgpt
                                            ? 'Стоимость: ${modelStats['cost']!.toStringAsFixed(3)}₽'
                                            : 'Стоимость: \$${modelStats['cost']!.toStringAsFixed(3)}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          trailing: Icon(
                            Icons.trending_up,
                            color: Colors.green,
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
