import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/chat_provider.dart';
import 'main_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pinController = TextEditingController();
  final _apiKeyController = TextEditingController();
  late final AuthService _authService;
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _hasAuth = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _initializeAuth() async {
    try {
      _authService = await AuthService.create();
      _hasAuth = await _authService.hasAuthData();
      setState(() => _isInitialized = true);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _handlePinSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final isValid = await _authService.validatePin(_pinController.text);
      if (!isValid) {
        setState(() => _error = 'Неверный PIN');
        return;
      }

      if (mounted) {
        // Пересоздаем ChatProvider с новыми данными авторизации
        final newProvider = await ChatProvider.create();
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ChangeNotifierProvider.value(
                value: newProvider,
                child: const MainScreen(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleApiKeySubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authData =
          await _authService.initializeAuth(_apiKeyController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'PIN-код для входа: ${authData.pin}',
              style: const TextStyle(fontSize: 16),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 10),
          ),
        );
        // Пересоздаем ChatProvider с новыми данными авторизации
        final newProvider = await ChatProvider.create();
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ChangeNotifierProvider.value(
                value: newProvider,
                child: const MainScreen(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleReset() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _authService.clearAuthData();
      setState(() => _hasAuth = false);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.chat,
                  size: 64,
                  color: Colors.blue,
                ),
                const SizedBox(height: 32),
                if (_error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (_hasAuth) ...[
                  TextFormField(
                    controller: _pinController,
                    decoration: const InputDecoration(
                      labelText: 'Введите PIN',
                      filled: true,
                      fillColor: Color(0xFF333333),
                      border: OutlineInputBorder(),
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите PIN';
                      }
                      if (value.length != 4) {
                        return 'PIN должен состоять из 4 цифр';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handlePinSubmit,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Войти'),
                  ),
                  TextButton(
                    onPressed: _isLoading ? null : _handleReset,
                    child: const Text('Сбросить ключ'),
                  ),
                ] else ...[
                  TextFormField(
                    controller: _apiKeyController,
                    decoration: const InputDecoration(
                      labelText: 'Введите ключ API',
                      filled: true,
                      fillColor: Color(0xFF333333),
                      border: OutlineInputBorder(),
                      labelStyle: TextStyle(color: Colors.white70),
                      helperText:
                          'Ключ должен начинаться с sk-or-v1- или sk-or-vv-',
                      helperStyle: TextStyle(color: Colors.white70),
                    ),
                    style: const TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите ключ API';
                      }
                      if (!value.startsWith('sk-or-v1-') &&
                          !value.startsWith('sk-or-vv-')) {
                        return 'Неверный формат ключа';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleApiKeySubmit,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Продолжить'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
