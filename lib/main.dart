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
    // Paleta alinhada com o front web (front-jyra / Conversys brand):
    // - Fundo claro: #f8fafc
    // - Superfícies: #ffffff
    // - Primário (accent): #005AFF
    // - Primário escuro: #0047cc
    // - Texto principal: #0f172a
    // - Texto secundário: #64748b
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: const Color(0xFF005AFF),
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFE5EFFF),
      onPrimaryContainer: const Color(0xFF03122F),
      secondary: const Color(0xFF03122F),
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFF062254),
      onSecondaryContainer: Colors.white,
      tertiary: const Color(0xFFEC4899),
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFFFE4F3),
      onTertiaryContainer: const Color(0xFF4A0626),
      error: const Color(0xFFEF4444),
      onError: Colors.white,
      errorContainer: const Color(0xFFFFE4E4),
      onErrorContainer: const Color(0xFF7F1D1D),
      background: const Color(0xFFF8FAFC),
      onBackground: const Color(0xFF0F172A),
      surface: Colors.white,
      onSurface: const Color(0xFF0F172A),
      surfaceVariant: const Color(0xFFE2E8F0),
      onSurfaceVariant: const Color(0xFF64748B),
      outline: const Color(0xFFCBD5E1),
      outlineVariant: const Color(0xFFE2E8F0),
      shadow: Colors.black.withOpacity(0.12),
      scrim: Colors.black54,
      inverseSurface: const Color(0xFF03122F),
      onInverseSurface: const Color(0xFFF8FAFC),
      inversePrimary: const Color(0xFFAECBFF),
    );

    return MaterialApp(
      title: 'Conversys',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: colorScheme.background,
        fontFamily: 'Inter',
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.secondary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: colorScheme.surface,
          indicatorColor: colorScheme.primary.withOpacity(0.08),
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
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

