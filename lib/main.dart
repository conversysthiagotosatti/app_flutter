import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/modules_screen.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const ConversysApp());
}

class ConversysApp extends StatelessWidget {
  const ConversysApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'Conversys',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  late final ApiClient _apiClient;
  late final AuthService _authService;
  bool _checking = true;
  bool _loggedIn = false;
  List<dynamic>? _modules;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    _authService = AuthService(_apiClient);
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final loggedIn = await _authService.isLoggedIn();
    List<dynamic>? modules;
    if (loggedIn) {
      modules = await _apiClient.loadModules();
    }
    if (!mounted) return;
    setState(() {
      _loggedIn = loggedIn;
      _modules = modules;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loggedIn) {
      if (_modules != null && _modules!.isNotEmpty) {
        return ModulesScreen(modules: _modules!);
      }
      return const HomeScreen();
    }
    return const LoginScreen();
  }
}

