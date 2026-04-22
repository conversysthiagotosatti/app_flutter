import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/helpdesk_chamados_service.dart';
import '../widgets/conversys_app_bar.dart';
import 'helpdesk_chamado_detalhe_screen.dart';
import 'helpdesk_nova_solicitacao_sheet.dart';
import 'notificacoes_screen.dart';

class HelpdeskChamadosScreen extends StatefulWidget {
  final ApiClient apiClient;

  const HelpdeskChamadosScreen({super.key, required this.apiClient});

  @override
  State<HelpdeskChamadosScreen> createState() => _HelpdeskChamadosScreenState();
}

class _HelpdeskChamadosScreenState extends State<HelpdeskChamadosScreen> {
  late final HelpdeskChamadosService _service;
  late Future<List<Chamado>> _future;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _service = HelpdeskChamadosService(widget.apiClient);
    _future = _service.listar();
  }

  Future<void> _recarregar() async {
    setState(() {
      _future = _service.listar(search: _search.isNotEmpty ? _search : null);
    });
  }

  void _abrirNovoChamado() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: HelpdeskNovaSolicitacaoSheet(
          apiClient: widget.apiClient,
          onCreated: () {
            Navigator.of(ctx).pop();
            _recarregar();
          },
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    final s = status.toUpperCase();
    if (s == 'ABERTO') return Colors.blue;
    if (s == 'EM_ATENDIMENTO') return Colors.orange;
    if (s == 'AGUARDANDO') return Colors.amber;
    if (s == 'RESOLVIDO' || s == 'FECHADO') {
      return Colors.green;
    }
    if (s == 'CANCELADO') return Colors.red;
    return Colors.grey;
  }

  Color _prioridadeColor(String prioridade) {
    final p = prioridade.toUpperCase();
    if (p == 'CRITICA') return Colors.red;
    if (p == 'ALTA') return Colors.orange;
    if (p == 'MEDIA') return Colors.blue;
    if (p == 'BAIXA') return Colors.grey;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: conversysAppBar(
        context,
        'Helpdesk Â· Chamados',
        onNotificationsTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NotificacoesScreen(apiClient: widget.apiClient),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirNovoChamado,
        icon: const Icon(Icons.add),
        label: const Text('Novo chamado'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Buscar por tÃ­tulo ou ID...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {
                  _search = value;
                });
                _recarregar();
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _recarregar,
              child: FutureBuilder<List<Chamado>>(
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
                            'Erro ao carregar chamados: ${snapshot.error}',
                          ),
                        ),
                      ],
                    );
                  }
                  final chamados = snapshot.data ?? const [];
                  if (chamados.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 80),
                        Center(child: Text('Nenhum chamado encontrado.')),
                      ],
                    );
                  }
                  return ListView.separated(
                    itemCount: chamados.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final c = chamados[index];
                      final statusColor = _statusColor(c.status);
                      final prioridadeColor = _prioridadeColor(c.prioridade);

                      final solicitanteNome =
                          (c.solicitanteDetalhes?['first_name'] ?? '') +
                          ' ' +
                          (c.solicitanteDetalhes?['last_name'] ?? '');

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: statusColor.withOpacity(0.1),
                          foregroundColor: statusColor,
                          child: Text(
                            c.id.toString(),
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                        title: Text(
                          c.titulo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    c.status,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: statusColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: prioridadeColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    c.prioridade,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: prioridadeColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (solicitanteNome.trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  solicitanteNome,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => HelpdeskChamadoDetalheScreen(
                                apiClient: widget.apiClient,
                                chamado: c,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
