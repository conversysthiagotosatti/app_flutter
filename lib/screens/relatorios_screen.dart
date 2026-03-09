import 'package:flutter/material.dart';

import '../models/relatorio_tarefas_meta.dart';
import '../services/api_client.dart';
import '../services/relatorios_service.dart';
import '../widgets/conversys_app_bar.dart';
import 'notificacoes_screen.dart';
import 'relatorio_detalhe_screen.dart';

class RelatoriosScreen extends StatefulWidget {
  final ApiClient apiClient;

  const RelatoriosScreen({super.key, required this.apiClient});

  @override
  State<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends State<RelatoriosScreen> {
  late final RelatoriosService _service;
  late Future<List<RelatorioTarefasMeta>> _future;

  @override
  void initState() {
    super.initState();
    _service = RelatoriosService(widget.apiClient);
    _future = _service.listar();
  }

  Future<void> _recarregar() async {
    setState(() {
      _future = _service.listar();
    });
  }

  void _abrirDetalhe(RelatorioTarefasMeta meta) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RelatorioDetalheScreen(
          apiClient: widget.apiClient,
          meta: meta,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: conversysAppBar(
        'Relatórios de tarefas',
        onNotificationsTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  NotificacoesScreen(apiClient: widget.apiClient),
            ),
          );
        },
      ),
      body: RefreshIndicator(
        onRefresh: _recarregar,
        child: FutureBuilder<List<RelatorioTarefasMeta>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Erro ao carregar relatórios: ${snapshot.error}',
                    ),
                  ),
                ],
              );
            }

            final all = snapshot.data ?? [];
            // apenas relatórios ativos, como no front web
            final items = all.where((r) => r.ativo).toList();

            if (items.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Nenhum relatório de tarefas ativo configurado.',
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  leading: const Icon(Icons.bar_chart),
                  title: Text(item.nome),
                  subtitle: item.descricao.isNotEmpty
                      ? Text(
                          item.descricao,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _abrirDetalhe(item),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

