import 'package:flutter/material.dart';

import '../services/api_client.dart';
import 'analisar_ia_screen.dart';
import 'cadastrar_epico_screen.dart';
import 'nova_tarefa_screen.dart';
import 'documentos_screen.dart';
import 'relatorios_screen.dart';
import 'dashboard_screen.dart';
import 'tabs/tarefas_tab.dart';
import 'tarefas_calendario_screen.dart';
import 'tarefas_copilot_screen.dart';

class TarefasModuleScreen extends StatelessWidget {
  final ApiClient apiClient;

  const TarefasModuleScreen({super.key, required this.apiClient});

  void _openKanban(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('Kanban de tarefas'),
          ),
          body: TarefasTab(apiClient: apiClient),
        ),
      ),
    );
  }

  void _openAnalisarIa(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnalisarIaScreen(apiClient: apiClient),
      ),
    );
  }

  void _openCadastrarEpico(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CadastrarEpicoScreen(apiClient: apiClient),
      ),
    );
  }

  void _openNovaTarefa(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NovaTarefaScreen(apiClient: apiClient),
      ),
    );
  }

  void _openPlaceholder(BuildContext context, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(title),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Tela "$title" ainda não foi implementada no app mobile.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openDocumentos(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DocumentosScreen(apiClient: apiClient),
      ),
    );
  }

  void _openRelatorios(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RelatoriosScreen(apiClient: apiClient),
      ),
    );
  }

  void _openDashboard(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DashboardScreen(apiClient: apiClient),
      ),
    );
  }

  void _openCalendario(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TarefasCalendarioScreen(apiClient: apiClient),
      ),
    );
  }

  void _openCopilot(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TarefasCopilotScreen(apiClient: apiClient),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF020617);
    const cardColor = Color(0xFF0B1220);
    const cardBorder = Color(0xFF1E293B);
    const iconBg = Color(0xFF0F172A);
    const labelColor = Colors.white;

    final options = [
      (
        'Dashboard',
        Icons.dashboard_outlined,
        (BuildContext ctx) => _openDashboard(ctx),
      ),
      (
        'Calendário',
        Icons.calendar_today_outlined,
        (BuildContext ctx) => _openCalendario(ctx),
      ),
      (
        'Copilot IA',
        Icons.bolt,
        (BuildContext ctx) => _openCopilot(ctx),
      ),
      (
        'Analisar com IA',
        Icons.auto_awesome,
        (BuildContext ctx) => _openAnalisarIa(ctx),
      ),
      (
        'Cadastrar Épico',
        Icons.layers,
        (BuildContext ctx) => _openCadastrarEpico(ctx),
      ),
      (
        'Nova tarefa',
        Icons.add_circle_outline,
        (BuildContext ctx) => _openNovaTarefa(ctx),
      ),
      (
        'Kanban',
        Icons.view_kanban,
        (BuildContext ctx) => _openKanban(ctx),
      ),
      (
        'Relatórios',
        Icons.bar_chart,
        (BuildContext ctx) => _openRelatorios(ctx),
      ),
      (
        'Documentos',
        Icons.description_outlined,
        (BuildContext ctx) => _openDocumentos(ctx),
      ),
    ];

    return Container(
      color: background,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: options.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 4 / 3,
          ),
          itemBuilder: (context, index) {
            final (label, icon, onTap) = options[index];
            return InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => onTap(context),
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cardBorder),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, size: 20, color: Colors.blue[200]),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      label,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: labelColor,
                          ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

