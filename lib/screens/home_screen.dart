import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/api_client.dart';
import '../utils/module_order.dart';
import '../widgets/conversys_app_bar.dart';
import '../widgets/language_picker_button.dart';
import '../widgets/permitted_cliente_selector.dart';
import 'assets_control_module_screen.dart';
import 'despesas_module_screen.dart';
import 'em_desenvolvimento_screen.dart';
import 'helpdesk_module_screen.dart';
import 'marketplace_module_screen.dart';
import 'notificacoes_screen.dart';
import 'propostas_module_screen.dart';
import 'tabs/clientes_tab.dart';
import 'tarefas_module_screen.dart';

bool _moduleRawIsExpenseModule(Object? raw) {
  final nome = (raw is Map && raw['nome'] is String)
      ? raw['nome'] as String
      : '';
  final lower = nome.toLowerCase();
  return lower.contains('despesa') || lower.contains('expense');
}

class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;
  late final ApiClient _client;
  List<dynamic>? _modules;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _client = ApiClient();
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

  @override
  Widget build(BuildContext context) {
    final modules = _modules;
    final l10n = AppLocalizations.of(context)!;

    // Se não houver módulos salvos, mantém o menu padrão fixo.
    if (modules == null || modules.isEmpty) {
      final tabs = [
        ClientesTab(apiClient: _client),
        // Aba "Contratos" e "Tarefas" mostram o módulo de tarefas
        TarefasModuleScreen(apiClient: _client),
        TarefasModuleScreen(apiClient: _client),
      ];
      // Enquanto os módulos carregam, `initialIndex` pode ser o índice do grid
      // (muitos itens); o shell fixo só tem 3 abas.
      final shellIndex = _currentIndex.clamp(0, tabs.length - 1);

      return Scaffold(
        appBar: conversysAppBar(
          context,
          l10n.appTitle,
          userAccountMenuApiClient: _client,
          onNotificationsTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => NotificacoesScreen(apiClient: _client),
              ),
            );
          },
          extraActions: const [
            LanguagePickerIconButton(),
          ],
        ),
        body: tabs[shellIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: shellIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.business),
              label: l10n.navClients,
            ),
            NavigationDestination(
              icon: const Icon(Icons.description),
              label: l10n.navContracts,
            ),
            NavigationDestination(
              icon: const Icon(Icons.check_circle_outline),
              label: l10n.navTasks,
            ),
          ],
        ),
      );
    }

    // Menu de rodapé baseado nos módulos do backend (mesma ordem do portal web).
    final orderedModules = orderModulesLikeWeb(modules);
    final views = <Widget>[];

    for (final raw in orderedModules) {
      final nome = (raw is Map && raw['nome'] is String)
          ? raw['nome'] as String
          : l10n.moduleDefaultName;
      final lower = nome.toLowerCase();

      Widget page;
      if (lower.contains('cliente')) {
        page = ClientesTab(apiClient: _client);
      } else if (lower.contains('proposta')) {
        page = PropostasModuleScreen(apiClient: _client);
      } else if (lower.contains('despesa') || lower.contains('expense')) {
        page = DespesasModuleScreen(apiClient: _client);
      } else if (lower.contains('asset') ||
          lower.contains('patrim') ||
          lower.contains('invent')) {
        page = AssetsControlModuleScreen(apiClient: _client);
      } else if (lower.contains('marketplace')) {
        page = MarketplaceModuleScreen(apiClient: _client);
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
              l10n.moduleUnavailable(nome),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }

      views.add(page);
    }

    final safeIndex = _currentIndex.clamp(0, views.length - 1);
    final showExpenseCompanyPicker = safeIndex < orderedModules.length &&
        _moduleRawIsExpenseModule(orderedModules[safeIndex]);

    return Scaffold(
      appBar: conversysAppBar(
        context,
        l10n.appTitle,
        userAccountMenuApiClient: _client,
        onNotificationsTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NotificacoesScreen(apiClient: _client),
            ),
          );
        },
        extraActions: const [
          LanguagePickerIconButton(),
        ],
        subtitle: showExpenseCompanyPicker
            ? PermittedClienteSelector(apiClient: _client)
            : null,
      ),
      body: views[safeIndex],
    );
  }
}
