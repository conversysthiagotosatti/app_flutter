import 'package:flutter/material.dart';

import '../models/contrato_tarefa.dart';
import '../models/contrato_tarefa_log.dart';
import '../services/api_client.dart';
import '../services/contrato_tarefas_service.dart';
import '../widgets/conversys_app_bar.dart';
import 'notificacoes_screen.dart';

class TarefaDetalheScreen extends StatefulWidget {
  final ApiClient apiClient;
  final ContratoTarefa tarefa;

  const TarefaDetalheScreen({
    super.key,
    required this.apiClient,
    required this.tarefa,
  });

  @override
  State<TarefaDetalheScreen> createState() => _TarefaDetalheScreenState();
}

class _TarefaDetalheScreenState extends State<TarefaDetalheScreen> {
  late final ContratoTarefasService _service;

  late ContratoTarefa _tarefa;
  bool _salvando = false;
  bool _carregandoLogs = false;
  List<ContratoTarefaLog> _logs = const [];

  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();

  static const _statusOrder = [
    'ABERTA',
    'EM_ANDAMENTO',
    'CONCLUIDA',
    'CANCELADA',
  ];

  static const _prioridades = ['ALTA', 'MEDIA', 'BAIXA'];

  @override
  void initState() {
    super.initState();
    _service = ContratoTarefasService(widget.apiClient);
    _tarefa = widget.tarefa;
    _tituloController.text = _tarefa.titulo;
    _descricaoController.text = _tarefa.descricao ?? '';
    _carregarLogs();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'ABERTA':
        return 'Aberta';
      case 'EM_ANDAMENTO':
        return 'Em Andamento';
      case 'CONCLUIDA':
        return 'Concluída';
      case 'CANCELADA':
        return 'Cancelada';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ABERTA':
        return const Color(0xFF94A3B8);
      case 'EM_ANDAMENTO':
        return const Color(0xFF3B82F6);
      case 'CONCLUIDA':
        return const Color(0xFF00A651);
      case 'CANCELADA':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  Color _prioridadeColor(String? prioridade) {
    switch (prioridade) {
      case 'ALTA':
        return const Color(0xFFEF4444);
      case 'MEDIA':
        return const Color(0xFFEAB308);
      case 'BAIXA':
        return const Color(0xFF22C55E);
      default:
        return const Color(0xFFCBD5E1);
    }
  }

  Future<void> _carregarLogs() async {
    setState(() {
      _carregandoLogs = true;
    });
    try {
      final data = await _service.listarLogs(_tarefa.id);
      if (!mounted) return;
      setState(() {
        _logs = data;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao carregar atividade da tarefa.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _carregandoLogs = false;
        });
      }
    }
  }

  Future<void> _salvarCampos({
    String? titulo,
    String? descricao,
    String? status,
    String? prioridade,
  }) async {
    setState(() {
      _salvando = true;
    });
    try {
      final atualizada = await _service.atualizar(
        _tarefa.id,
        titulo: titulo,
        descricao: descricao,
        status: status,
        prioridade: prioridade,
      );
      if (!mounted) return;
      setState(() {
        _tarefa = atualizada;
        _tituloController.text = _tarefa.titulo;
        _descricaoController.text = _tarefa.descricao ?? '';
      });
      await _carregarLogs();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar tarefa: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _salvando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(_tarefa.status);

    return Scaffold(
      appBar: conversysAppBar(
        context,
        'Tarefa #${_tarefa.id}',
        onNotificationsTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NotificacoesScreen(apiClient: widget.apiClient),
            ),
          );
        },
      ),
      body: Column(
        children: [
          if (_salvando) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabeçalho: status + prioridade
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: statusColor.withOpacity(0.08),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          _statusLabel(_tarefa.status),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_tarefa.prioridade != null &&
                          _tarefa.prioridade!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: _prioridadeColor(
                              _tarefa.prioridade,
                            ).withOpacity(0.08),
                          ),
                          child: Text(
                            _tarefa.prioridade!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _prioridadeColor(_tarefa.prioridade),
                            ),
                          ),
                        ),
                      const Spacer(),
                      if (_tarefa.geradaPorIa)
                        const Icon(
                          Icons.auto_awesome,
                          size: 18,
                          color: Color(0xFF22C55E),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Título
                  TextField(
                    controller: _tituloController,
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (value) {
                      if (value.trim().isEmpty) return;
                      _salvarCampos(titulo: value.trim());
                    },
                  ),
                  const SizedBox(height: 12),

                  // Descrição
                  TextField(
                    controller: _descricaoController,
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                    onEditingComplete: () {
                      _salvarCampos(descricao: _descricaoController.text);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Status e prioridade
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _tarefa.status,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(),
                          ),
                          items: _statusOrder
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(_statusLabel(s)),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null || value == _tarefa.status) {
                              return;
                            }
                            _salvarCampos(status: value);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _tarefa.prioridade,
                          decoration: const InputDecoration(
                            labelText: 'Prioridade',
                            border: OutlineInputBorder(),
                          ),
                          items: _prioridades
                              .map(
                                (p) =>
                                    DropdownMenuItem(value: p, child: Text(p)),
                              )
                              .toList(),
                          onChanged: (value) {
                            _salvarCampos(prioridade: value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Detalhes
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detalhes',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          _detailRow('Contrato', '#${_tarefa.contrato}'),
                          if (_tarefa.clausula != null)
                            _detailRow('Cláusula', '#${_tarefa.clausula}'),
                          if (_tarefa.epico != null)
                            _detailRow(
                              'Épico',
                              _tarefa.epicoTitulo ?? '#${_tarefa.epico}',
                            ),
                          _detailRow(
                            'Criado em',
                            _formatDateTime(_tarefa.criadoEm),
                          ),
                          _detailRow(
                            'Atualizado em',
                            _formatDateTime(_tarefa.atualizadoEm),
                          ),
                          _detailRow(
                            'Previsão início',
                            _tarefa.dataInicioPrevista != null
                                ? _formatDate(_tarefa.dataInicioPrevista!)
                                : '—',
                          ),
                          _detailRow(
                            'Horas previstas',
                            _tarefa.horasPrevistas != null
                                ? '${_tarefa.horasPrevistas} h'
                                : '—',
                          ),
                          if (_tarefa.responsavelSugerido != null &&
                              _tarefa.responsavelSugerido!.isNotEmpty)
                            _detailRow(
                              'Resp. sugerido',
                              _tarefa.responsavelSugerido!,
                            ),
                          if (_tarefa.prazoDiasSugerido != null)
                            _detailRow(
                              'Prazo sugerido',
                              '${_tarefa.prazoDiasSugerido} dias',
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Atividade (logs)
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Atividade',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.refresh, size: 18),
                                tooltip: 'Recarregar',
                                onPressed: _carregarLogs,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_carregandoLogs)
                            const Padding(
                              padding: EdgeInsets.all(8),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          else if (_logs.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(
                                'Nenhuma atividade registrada.',
                                style: TextStyle(fontSize: 12),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _logs.length,
                              itemBuilder: (context, index) {
                                final log = _logs[index];
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  title: Text(
                                    log.detalhe ?? log.acao,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  subtitle: Text(
                                    '${log.usuarioNome ?? ''} '
                                    '• ${_formatDateTime(log.criadoEm)}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d/$m/$y';
  }

  String _formatDateTime(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min';
  }
}
