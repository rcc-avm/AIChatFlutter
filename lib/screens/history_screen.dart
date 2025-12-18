import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/message.dart';
import '../providers/chat_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ChatMessage> _filteredMessages = [];
  bool _showUserOnly = false;
  bool _showAIOnly = false;
  String? _selectedModel;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadMessages();
      }
    });
  }

  void _loadMessages() {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final chatProvider = context.read<ChatProvider>();
      final allMessages = List<ChatMessage>.from(chatProvider.messages);
      _applyFilters(allMessages);
    } catch (e) {
      // Handle error silently
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters(List<ChatMessage> allMessages) {
    List<ChatMessage> filtered = allMessages;

    // Apply user/AI filter
    if (_showUserOnly) {
      filtered = filtered.where((msg) => msg.isUser).toList();
    } else if (_showAIOnly) {
      filtered = filtered.where((msg) => !msg.isUser).toList();
    }

    // Apply model filter
    if (_selectedModel != null) {
      filtered =
          filtered.where((msg) => msg.modelId == _selectedModel).toList();
    }

    // Sort by timestamp descending (newest first)
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    setState(() => _filteredMessages = filtered);
  }

  List<String> _getAvailableModels() {
    final chatProvider = context.read<ChatProvider>();
    final models = <String>{};

    for (final msg in chatProvider.messages) {
      if (msg.modelId != null) {
        models.add(msg.modelId!);
      }
    }

    return models.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.read<ChatProvider>();
    final availableModels = _getAvailableModels();
    final totalMessages = chatProvider.messages.length;
    final totalUserMessages =
        chatProvider.messages.where((msg) => msg.isUser).length;
    final totalAIMessages =
        chatProvider.messages.where((msg) => !msg.isUser).length;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF262626),
        title: const Text('История сообщений'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
            tooltip: 'Обновить историю',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter controls
          Card(
            color: const Color(0xFF262626),
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Фильтры',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ToggleButtons(
                          isSelected: [
                            !(_showUserOnly || _showAIOnly),
                            _showUserOnly,
                            _showAIOnly
                          ],
                          onPressed: (index) {
                            setState(() {
                              _showUserOnly = index == 1;
                              _showAIOnly = index == 2;
                            });
                            _loadMessages();
                          },
                          borderRadius: BorderRadius.circular(8),
                          borderColor: Colors.blue,
                          selectedBorderColor: Colors.blue,
                          fillColor: Colors.blue.withOpacity(0.2),
                          children: const [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('Все'),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('Пользователь'),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('AI'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (availableModels.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      value: _selectedModel,
                      onChanged: (value) {
                        setState(() => _selectedModel = value);
                        _loadMessages();
                      },
                      decoration: const InputDecoration(
                        labelText: 'Модель',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      dropdownColor: const Color(0xFF262626),
                      style: const TextStyle(color: Colors.white),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Все модели'),
                        ),
                        ...availableModels.map((model) {
                          return DropdownMenuItem(
                            value: model,
                            child: Text(model),
                          );
                        }).toList(),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Stats summary
          Card(
            color: const Color(0xFF262626),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                      'Всего', totalMessages.toString(), Icons.message),
                  _buildStatItem('Пользователь', totalUserMessages.toString(),
                      Icons.person),
                  _buildStatItem(
                      'AI', totalAIMessages.toString(), Icons.smart_toy),
                ],
              ),
            ),
          ),

          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMessages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 64,
                              color: Colors.blue.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Нет сообщений',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _showUserOnly
                                  ? 'Пользовательские сообщения не найдены'
                                  : _showAIOnly
                                      ? 'Ответы AI не найдены'
                                      : 'История сообщений пуста',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _filteredMessages.length,
                        separatorBuilder: (context, index) => const Divider(
                          height: 1,
                          color: Color(0xFF333333),
                        ),
                        itemBuilder: (context, index) {
                          final message = _filteredMessages[index];
                          return _buildMessageItem(message);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
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
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMessageItem(ChatMessage message) {
    return Container(
      color: message.isUser ? const Color(0xFF2A2A2A) : const Color(0xFF262626),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    message.isUser ? Icons.person : Icons.smart_toy,
                    color: message.isUser ? Colors.blue : Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    message.isUser ? 'Пользователь' : 'AI',
                    style: TextStyle(
                      color: message.isUser ? Colors.blue : Colors.green,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                _formatTimestamp(message.timestamp),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (message.modelId != null) ...[
            const SizedBox(height: 4),
            Text(
              'Модель: ${message.modelId}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
          if (message.tokens != null || message.cost != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                if (message.tokens != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      'Токены: ${message.tokens}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (message.cost != null)
                  Text(
                    'Стоимость: ${message.cost!.toStringAsFixed(6)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text(
            message.content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate =
        DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      return 'Сегодня ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Вчера ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day.toString().padLeft(2, '0')}.${timestamp.month.toString().padLeft(2, '0')} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
