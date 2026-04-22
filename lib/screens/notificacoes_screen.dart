import 'package:flutter/material.dart';

import '../models/notificacao.dart';
import '../services/api_client.dart';
import '../services/notificacoes_service.dart';
import '../l10n/app_localizations.dart';
import '../widgets/conversys_app_bar.dart';

class NotificacoesScreen extends StatefulWidget {
  final ApiClient apiClient;

  const NotificacoesScreen({super.key, required this.apiClient});

  @override
  State<NotificacoesScreen> createState() => _NotificacoesScreenState();
}

class _NotificacoesScreenState extends State<NotificacoesScreen> {
  late final NotificacoesService _service;
  late Future<List<Notificacao>> _future;

  @override
  void initState() {
    super.initState();
    _service = NotificacoesService(widget.apiClient);
    _future = _service.listar();
  }

  Future<void> _recarregar() async {
    setState(() {
      _future = _service.listar();
    });
  }

  Future<void> _marcarComoLida(Notificacao n) async {
    try {
      await _service.marcarComoLida(n.id);
      await _recarregar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao marcar notificação como lida: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: conversysAppBar(
        context,
        AppLocalizations.of(context)!.notifications,
      ),
      body: RefreshIndicator(
        onRefresh: _recarregar,
        child: FutureBuilder<List<Notificacao>>(
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
                      'Erro ao carregar notificações: ${snapshot.error}',
                    ),
                  ),
                ],
              );
            }

            final notificacoes = snapshot.data ?? [];
            if (notificacoes.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Você não tem notificações no momento.'),
                  ),
                ],
              );
            }

            return ListView.builder(
              itemCount: notificacoes.length,
              itemBuilder: (context, index) {
                final n = notificacoes[index];
                final lida = n.lida;
                return ListTile(
                  leading: Icon(
                    lida ? Icons.notifications_none : Icons.notifications_active,
                    color: lida
                        ? Colors.grey
                        : Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    n.titulo,
                    style: TextStyle(
                      fontWeight: lida ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n.mensagem),
                      if (n.criadaEm != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${n.criadaEm!.day.toString().padLeft(2, '0')}/'
                            '${n.criadaEm!.month.toString().padLeft(2, '0')}/'
                            '${n.criadaEm!.year} '
                            '${n.criadaEm!.hour.toString().padLeft(2, '0')}:'
                            '${n.criadaEm!.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  ),
                  trailing: lida
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.done),
                          tooltip: 'Marcar como lida',
                          onPressed: () => _marcarComoLida(n),
                        ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

