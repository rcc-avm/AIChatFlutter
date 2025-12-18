import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';

class ExpenseChartScreen extends StatefulWidget {
  const ExpenseChartScreen({super.key});

  @override
  State<ExpenseChartScreen> createState() => _ExpenseChartScreenState();
}

class _ExpenseChartScreenState extends State<ExpenseChartScreen> {
  List<Map<String, dynamic>> _expenseData = [];
  bool _isLoading = false;
  double _totalCost = 0.0;

  @override
  void initState() {
    super.initState();
    _loadExpenseData();
  }

  Future<void> _loadExpenseData() async {
    setState(() => _isLoading = true);
    try {
      final chatProvider = context.read<ChatProvider>();
      await Future.delayed(
          const Duration(milliseconds: 500)); // Simulate loading

      // Group messages by day and calculate daily costs
      final Map<String, Map<String, dynamic>> dailyData = {};

      for (final message in chatProvider.messages) {
        if (message.cost != null && message.cost! > 0) {
          final date = message.timestamp.toLocal();
          final dayKey =
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

          if (!dailyData.containsKey(dayKey)) {
            dailyData[dayKey] = {
              'date': dayKey,
              'cost': 0.0,
              'tokens': 0,
              'messages': 0,
              'displayDate':
                  '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}',
            };
          }

          dailyData[dayKey]!['cost'] =
              dailyData[dayKey]!['cost']! + message.cost!;
          dailyData[dayKey]!['tokens'] =
              dailyData[dayKey]!['tokens']! + (message.tokens ?? 0);
          dailyData[dayKey]!['messages'] = dailyData[dayKey]!['messages']! + 1;
        }
      }

      _expenseData = dailyData.values.toList();
      _expenseData
          .sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

      _totalCost =
          _expenseData.fold<double>(0, (sum, day) => sum + day['cost']!);
    } catch (e) {
      // Handle error silently
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.read<ChatProvider>();
    final isVsetgpt = chatProvider.baseUrl?.contains('vsegpt.ru') == true;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF262626),
        title: const Text('Расходы по дням'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadExpenseData,
            tooltip: 'Обновить данные',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _expenseData.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.timeline,
                        size: 64,
                        color: Colors.blue.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Нет данных о расходах',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Отправьте несколько сообщений,\nчтобы увидеть статистику расходов',
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
                    // Total cost card
                    Card(
                      color: const Color(0xFF262626),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Общие расходы',
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
                                  'Всего дней',
                                  _expenseData.length.toString(),
                                  Icons.calendar_today,
                                  Colors.blue,
                                ),
                                _buildStatItem(
                                  'Всего сообщений',
                                  _expenseData
                                      .fold<int>(
                                          0,
                                          (sum, day) =>
                                              sum + (day['messages'] as int))
                                      .toString(),
                                  Icons.message,
                                  Colors.green,
                                ),
                                _buildStatItem(
                                  'Общие расходы',
                                  _totalCost < 0.001
                                      ? isVsetgpt
                                          ? '<0.001₽'
                                          : '<\$0.001'
                                      : isVsetgpt
                                          ? '${_totalCost.toStringAsFixed(3)}₽'
                                          : '\$${_totalCost.toStringAsFixed(3)}',
                                  Icons.attach_money,
                                  Colors.amber,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Daily expenses list
                    ..._expenseData.map((dayData) {
                      final dayCost = dayData['cost']!;
                      return Card(
                        color: const Color(0xFF262626),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          leading: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dayData['displayDate']!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${dayData['messages']} сообщ.',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${dayData['tokens']} токенов',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    LinearProgressIndicator(
                                      value: dayCost / _totalCost,
                                      backgroundColor: Colors.white12,
                                      color: Colors.blue,
                                      minHeight: 6,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dayCost < 0.001
                                    ? isVsetgpt
                                        ? '<0.001₽'
                                        : '<\$0.001'
                                    : isVsetgpt
                                        ? '${dayCost.toStringAsFixed(3)}₽'
                                        : '\$${dayCost.toStringAsFixed(3)}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${((dayCost / _totalCost) * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
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
          style: const TextStyle(
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
