import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/helpdesk_chamados_service.dart';
import '../widgets/conversys_app_bar.dart';
import 'notificacoes_screen.dart';

class HelpdeskChamadoDetalheScreen extends StatefulWidget {
  final ApiClient apiClient;
  final Chamado chamado;

  const HelpdeskChamadoDetalheScreen({
    super.key,
    required this.apiClient,
    required this.chamado,
  });

  @override
  State<HelpdeskChamadoDetalheScreen> createState() =>
      _HelpdeskChamadoDetalheScreenState();
}

class _HelpdeskChamadoDetalheScreenState
    extends State<HelpdeskChamadoDetalheScreen>
    with SingleTickerProviderStateMixin {
  late final HelpdeskChamadosService _service;
  late TabController _tabController;

  Map<String, dynamic>? _dados;
  List<dynamic> _mensagens = const [];
  List<dynamic> _historico = const [];
  List<dynamic> _apontamentos = const [];

  bool _loading = true;
  String? _error;

  final _mensagemController = TextEditingController();
  bool _enviandoMsg = false;

  @override
  void initState() {
    super.initState();
    _service = HelpdeskChamadosService(widget.apiClient);
    _tabController = TabController(length: 4, vsync: this);
    _carregarTudo();
  }

  @override
  void dispose() {
    _mensagemController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _carregarTudo() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.apiClient.get('/api/helpdesk/chamados/${widget.chamado.id}/'),
        widget.apiClient
            .get('/api/helpdesk/chamados/${widget.chamado.id}/mensagens/'),
        widget.apiClient
            .get('/api/helpdesk/chamados/${widget.chamado.id}/historico/'),
        widget.apiClient
            .get('/api/helpdesk/chamados/${widget.chamado.id}/apontamentos/'),
      ]);

      if (!mounted) return;

      Map<String, dynamic>? decodeMap(int index) {
        final resp = results[index];
        if (resp.statusCode != 200) return null;
        final decoded = jsonDecode(resp.body);
        return decoded is Map<String, dynamic> ? decoded : null;
      }

      List<dynamic> decodeList(int index) {
        final resp = results[index];
        if (resp.statusCode != 200) return const [];
        final decoded = jsonDecode(resp.body);
        if (decoded is List) return decoded;
        if (decoded is Map<String, dynamic> &&
            decoded['results'] is List) {
          return decoded['results'] as List<dynamic>;
        }
        return const [];
      }

      setState(() {
        _dados = decodeMap(0);
        _mensagens = decodeList(1);
        _historico = decodeList(2);
        _apontamentos = decodeList(3);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
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

  String _formatDateTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year.toString().substring(2)} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  Future<void> _enviarMensagem() async {
    final texto = _mensagemController.text.trim();
    if (texto.isEmpty || _enviandoMsg) return;
    setState(() {
      _enviandoMsg = true;
    });
    try {
      await widget.apiClient.post(
        '/api/helpdesk/chamados/${widget.chamado.id}/add_mensagem/',
        body: {
          'conteudo': texto,
          'tipo_autor': 'SOLICITANTE',
        },
      );
      _mensagemController.clear();
      await _carregarTudo();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao enviar mensagem: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _enviandoMsg = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dados = _dados;
    final status = dados?['status']?.toString() ?? widget.chamado.status;
    final prioridade =
        dados?['prioridade']?.toString() ?? widget.chamado.prioridade;
    final statusColor = _statusColor(status);
    final prioridadeColor = _prioridadeColor(prioridade);

    final solicitante = dados?['solicitante_detalhes'] as Map?;
    final responsavel = dados?['atendente_detalhes'] as Map?;
    final slaHoras = dados?['sla_horas']?.toString();
    final criadoEm = dados?['criado_em']?.toString() ??
        widget.chamado.criadoEm;

    return Scaffold(
      appBar: conversysAppBar(
        'Ticket #${widget.chamado.id}',
        onNotificationsTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  NotificacoesScreen(apiClient: widget.apiClient),
            ),
          );
        },
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Erro ao carregar chamado: $_error'),
                  ),
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.white, Color(0xFFEFF3FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Chip(
                                label: Text('Ticket #${widget.chamado.id}'),
                              ),
                              Chip(
                                label: Text(status),
                                backgroundColor:
                                    statusColor.withOpacity(0.1),
                                labelStyle: TextStyle(color: statusColor),
                              ),
                              Chip(
                                label: Text(prioridade),
                                backgroundColor:
                                    prioridadeColor.withOpacity(0.1),
                                labelStyle:
                                    TextStyle(color: prioridadeColor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            dados?['titulo']?.toString() ??
                                widget.chamado.titulo,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (dados?['descricao'] != null &&
                              (dados!['descricao'] as String)
                                  .trim()
                                  .isNotEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 8, right: 8),
                              child: Text(
                                dados['descricao'] as String,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium,
                              ),
                            ),
                          const SizedBox(height: 16),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _infoPill(
                                  icon: Icons.person_outline,
                                  label: 'Solicitante',
                                  value: solicitante != null
                                      ? '${solicitante['first_name'] ?? ''} ${solicitante['last_name'] ?? ''}'
                                          .trim()
                                      : '-',
                                ),
                                const SizedBox(width: 8),
                                _infoPill(
                                  icon: Icons.support_agent,
                                  label: 'Responsável',
                                  value: responsavel != null
                                      ? '${responsavel['first_name'] ?? ''} ${responsavel['last_name'] ?? ''}'
                                          .trim()
                                      : 'Aguardando...',
                                ),
                                const SizedBox(width: 8),
                                _infoPill(
                                  icon: Icons.calendar_today_outlined,
                                  label: 'Abertura',
                                  value: _formatDateTime(criadoEm),
                                ),
                                const SizedBox(width: 8),
                                _infoPill(
                                  icon: Icons.timer_outlined,
                                  label: 'SLA estimado',
                                  value:
                                      slaHoras != null ? '$slaHoras h' : '-',
                                  highlight: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    TabBar(
                      controller: _tabController,
                      labelColor:
                          Theme.of(context).colorScheme.primary,
                      tabs: const [
                        Tab(text: 'Discussão'),
                        Tab(text: 'Workflow'),
                        Tab(text: 'Horas'),
                        Tab(text: 'Ações'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildDiscussaoTab(),
                          _buildWorkflowTab(),
                          _buildHorasTab(),
                          _buildAcoesTab(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _infoPill({
    required IconData icon,
    required String label,
    required String value,
    bool highlight = false,
  }) {
    final color = highlight ? Colors.orange : Colors.grey.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: highlight ? Colors.orange.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight
              ? Colors.orange.withOpacity(0.4)
              : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              Text(
                value.isEmpty ? '-' : value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiscussaoTab() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _mensagens.length,
            itemBuilder: (context, index) {
              final m =
                  _mensagens[index] as Map<String, dynamic>;
              final autor = m['autor_detalhes'] as Map?;
              final conteudo =
                  (m['conteudo'] ?? '').toString();
              final criadoEm =
                  (m['criado_em'] ?? '').toString();
              final tipoAutor =
                  (m['tipo_autor'] ?? '').toString();
              final isCliente =
                  tipoAutor == 'SOLICITANTE';

              return Align(
                alignment: isCliente
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isCliente
                        ? Colors.blue.shade50
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            autor != null
                                ? '${autor['first_name'] ?? ''} ${autor['last_name'] ?? ''}'
                                    .trim()
                                : tipoAutor,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _formatDateTime(criadoEm),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        conteudo,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _mensagemController,
                  decoration: const InputDecoration(
                    hintText: 'Escreva sua mensagem...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  minLines: 1,
                  maxLines: 3,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _enviandoMsg ? null : _enviarMensagem,
                icon: _enviandoMsg
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send),
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkflowTab() {
    if (_historico.isEmpty) {
      return const Center(
        child: Text('Nenhum histórico disponível.'),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _historico.length,
      itemBuilder: (context, index) {
        final h =
            _historico[index] as Map<String, dynamic>;
        final statusNovo =
            (h['status_novo'] ?? '').toString();
        final criadoEm =
            (h['criado_em'] ?? '').toString();
        final usuario =
            h['usuario_detalhes'] as Map?;

        return ListTile(
          leading: const Icon(Icons.history),
          title: Text(statusNovo),
          subtitle: Text(
            '${usuario != null ? '${usuario['first_name'] ?? ''} ${usuario['last_name'] ?? ''}'.trim() : ''}\n${_formatDateTime(criadoEm)}',
          ),
          isThreeLine: true,
        );
      },
    );
  }

  Widget _buildHorasTab() {
    if (_apontamentos.isEmpty) {
      return const Center(
        child: Text('Nenhum apontamento de horas.'),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _apontamentos.length,
      itemBuilder: (context, index) {
        final a =
            _apontamentos[index] as Map<String, dynamic>;
        final horas = a['horas']?.toString() ?? '0';
        final descricao =
            (a['descricao'] ?? '').toString();
        final data =
            (a['data'] ?? a['criado_em'] ?? '').toString();

        return ListTile(
          leading: const Icon(Icons.timer_outlined),
          title: Text('$horas h'),
          subtitle: Text(
            '${_formatDateTime(data)}\n$descricao',
          ),
          isThreeLine: true,
        );
      },
    );
  }

  Widget _buildAcoesTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Ações de gestão avançadas (assumir, transferir, mudar status) '
          'podem ser adicionadas aqui, usando os mesmos endpoints '
          'que o painel web.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

