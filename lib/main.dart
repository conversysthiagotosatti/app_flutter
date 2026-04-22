import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'l10n/app_locale_controller.dart';
import 'l10n/app_locale_scope.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/modules_screen.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ConversysRoot());
}

class ConversysRoot extends StatefulWidget {
  const ConversysRoot({super.key});

  @override
  State<ConversysRoot> createState() => _ConversysRootState();
}

class _ConversysRootState extends State<ConversysRoot> {
  final AppLocaleController _locale = AppLocaleController();

  @override
  void initState() {
    super.initState();
    _locale.addListener(_onLocale);
    _locale.loadSaved();
  }

  void _onLocale() => setState(() {});

  @override
  void dispose() {
    _locale.removeListener(_onLocale);
    _locale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      surface: Colors.white,
      onSurface: const Color(0xFF0F172A),
      surfaceContainerHighest: const Color(0xFFE2E8F0),
      onSurfaceVariant: const Color(0xFF64748B),
      outline: const Color(0xFFCBD5E1),
      outlineVariant: const Color(0xFFE2E8F0),
      shadow: Colors.black.withOpacity(0.12),
      scrim: Colors.black54,
      inverseSurface: const Color(0xFF03122F),
      onInverseSurface: const Color(0xFFF8FAFC),
      inversePrimary: const Color(0xFFAECBFF),
    );

    return ListenableBuilder(
      listenable: _locale,
      builder: (context, _) {
        return MaterialApp(
          onGenerateTitle: (ctx) => AppLocalizations.of(ctx)!.appTitle,
          debugShowCheckedModeBanner: false,
          locale: _locale.localeOverride,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          localeResolutionCallback: (deviceLocale, supported) {
            if (_locale.localeOverride != null) {
              for (final l in supported) {
                if (l.languageCode == _locale.localeOverride!.languageCode) {
                  return l;
                }
              }
              return const Locale('pt');
            }
            for (final l in supported) {
              if (l.languageCode == deviceLocale?.languageCode) {
                return l;
              }
            }
            return const Locale('pt');
          },
          theme: ThemeData(
            colorScheme: colorScheme,
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
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
          builder: (context, child) {
            return AppLocaleScope(
              notifier: _locale,
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const _AuthGate(),
        );
      },
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
