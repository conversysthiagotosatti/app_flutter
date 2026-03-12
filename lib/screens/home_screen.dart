import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../widgets/conversys_app_bar.dart';
import 'em_desenvolvimento_screen.dart';
import 'helpdesk_module_screen.dart';
import 'notificacoes_screen.dart';
import 'tabs/clientes_tab.dart';
import 'tabs/contratos_tab.dart';
import 'tabs/tarefas_tab.dart';
import 'tarefas_module_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;
  late final ApiClient _client;
  late final AuthService _authService;
  List<dynamic>? _modules;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _client = ApiClient();
    _authService = AuthService(_client);
    _loadModules();
  }

  Future<void> _loadModules() async {
    final mods = await _client.loadModules();
    if (!mounted) return;
    setState(() {
      _modules = mods;
      if (mods != null && mods.isNotEmpty) {
        final maxIndex = mods.length - 1;
        if (_currentIndex > maxIndex) {
          _currentIndex = 0;
        }
      }
    });
  }

  IconData _iconForModule(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('cliente')) return Icons.business;
    if (lower.contains('contrato')) return Icons.description_outlined;
    if (lower.contains('tarefa') ||
        lower.contains('board') ||
        lower.contains('projeto')) {
      return Icons.check_circle_outline;
    }
    if (lower.contains('helpdesk') || lower.contains('help desk')) {
      return Icons.support_agent;
    }
    if (lower.contains('zabbix') || lower.contains('observa')) {
      return Icons.shield;
    }
    return Icons.apps;
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final modules = _modules;

    // Se não houver módulos salvos, mantém o menu padrão fixo.
    if (modules == null || modules.isEmpty) {
      final tabs = [
        ClientesTab(apiClient: _client),
        // Aba "Contratos" e "Tarefas" mostram o módulo de tarefas
        TarefasModuleScreen(apiClient: _client),
        TarefasModuleScreen(apiClient: _client),
      ];

      return Scaffold(
        appBar: conversysAppBar(
          'Conversys',
          onNotificationsTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => NotificacoesScreen(apiClient: _client),
              ),
            );
          },
          extraActions: [
            IconButton(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              tooltip: 'Sair',
            ),
          ],
        ),
        body: tabs[_currentIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.business),
              label: 'Clientes',
            ),
            NavigationDestination(
              icon: Icon(Icons.description),
              label: 'Contratos',
            ),
            NavigationDestination(
              icon: Icon(Icons.check_circle_outline),
              label: 'Tarefas',
            ),
          ],
        ),
      );
    }

    // Menu de rodapé baseado nos módulos do backend.
    final views = <Widget>[];
    final destinations = <NavigationDestination>[];

    for (final raw in modules) {
      final nome = (raw is Map && raw['nome'] is String)
          ? raw['nome'] as String
          : 'Módulo';
      final lower = nome.toLowerCase();

      Widget page;
      if (lower.contains('cliente')) {
        page = ClientesTab(apiClient: _client);
      } else if (lower.contains('helpdesk') ||
          lower.contains('help desk') ||
          lower.contains('observa') ||
          lower.contains('zabbix') ||
          lower.contains('contratos ai') ||
          lower.contains('contrato ai') ||
          lower.contains('contratos')) {
        // módulo Helpdesk abre um submenu próprio;
        // Observabilidade/Zabbix e Contratos ainda mostram "Em Desenvolvimento"
        if (lower.contains('helpdesk') || lower.contains('help desk')) {
          page = HelpdeskModuleScreen(apiClient: _client);
        } else {
          page = EmDesenvolvimentoScreen(titulo: nome);
        }
      } else if (lower.contains('tarefa') ||
          lower.contains('board') ||
          lower.contains('projeto')) {
        // módulos de tarefas/board/projetos usam o módulo de tarefas
        page = TarefasModuleScreen(apiClient: _client);
      } else {
        page = Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Módulo "$nome" ainda não está disponível no app mobile.',
              textAlign: TextAlign.center,
            ),
          ),
        );
      }

      views.add(page);
      destinations.add(
        NavigationDestination(
          icon: Icon(_iconForModule(nome)),
          label: nome,
        ),
      );
    }

    final safeIndex =
        _currentIndex.clamp(0, views.length - 1);

    return Scaffold(
      appBar: conversysAppBar(
        'Conversys',
        onNotificationsTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NotificacoesScreen(apiClient: _client),
            ),
          );
        },
        extraActions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
          ),
        ],
      ),
      body: views[safeIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: destinations,
      ),
    );
  }
}

