import 'package:flutter/material.dart';

import '../../models/contrato_tarefa.dart';
import '../../services/api_client.dart';
import '../../services/contrato_tarefas_service.dart';
import '../tarefa_detalhe_screen.dart';

class TarefasTab extends StatefulWidget {
  final ApiClient apiClient;

  const TarefasTab({super.key, required this.apiClient});

  @override
  State<TarefasTab> createState() => _TarefasTabState();
}

class _TarefasTabState extends State<TarefasTab> {
  late final ContratoTarefasService _service;
  late Future<List<ContratoTarefa>> _future;

  static const _statusOrder = [
    'ABERTA',
    'EM_ANDAMENTO',
    'CONCLUIDA',
    'CANCELADA',
  ];

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
        return const Color(0xFF94A3B8); // slate-400
      case 'EM_ANDAMENTO':
        return const Color(0xFF3B82F6); // blue-500
      case 'CONCLUIDA':
        return const Color(0xFF00A651); // conversys green
      case 'CANCELADA':
        return const Color(0xFFEF4444); // red-500
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

  @override
  void initState() {
    super.initState();
    _service = ContratoTarefasService(widget.apiClient);
    _future = _service.listar();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ContratoTarefa>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Erro ao carregar tarefas: ${snapshot.error}'),
          );
        }

        final tarefas = snapshot.data ?? [];
        if (tarefas.isEmpty) {
          return const Center(child: Text('Nenhuma tarefa encontrada.'));
        }

        // Agrupa por status para montar as colunas do Kanban.
        final Map<String, List<ContratoTarefa>> porStatus = {
          for (final s in _statusOrder) s: <ContratoTarefa>[],
        };
        for (final t in tarefas) {
          final status =
              _statusOrder.contains(t.status) ? t.status : 'ABERTA';
          porStatus[status]!.add(t);
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final colunaAltura = constraints.maxHeight;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _statusOrder.map((status) {
                  final items = porStatus[status]!;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _buildStatusColumn(
                      context,
                      status: status,
                      tarefas: items,
                      altura: colunaAltura,
                    ),
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusColumn(
    BuildContext context, {
    required String status,
    required List<ContratoTarefa> tarefas,
    required double altura,
  }) {
    final color = _statusColor(status);
    final label = _statusLabel(status);

    return SizedBox(
      width: 260,
      height: altura,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  tarefas.length.toString(),
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: tarefas.isEmpty
                ? Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade200,
                        style: BorderStyle.solid,
                      ),
                      color: Colors.grey.shade50,
                    ),
                    child: Text(
                      status == 'CANCELADA'
                          ? 'Arraste tarefas para cá.'
                          : 'Nenhuma tarefa nesta coluna.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey.shade500),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 4, right: 4),
                    itemCount: tarefas.length,
                    itemBuilder: (context, index) {
                      final t = tarefas[index];
                      return _buildTaskCard(context, t, color);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    ContratoTarefa tarefa,
    Color statusColor,
  ) {
    final prioridade = tarefa.prioridade;
    final prioridadeCor = _prioridadeColor(prioridade);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TarefaDetalheScreen(
                apiClient: widget.apiClient,
                tarefa: tarefa,
              ),
            ),
          );
          // Sempre recarrega o Kanban ao voltar do detalhe
          setState(() {
            _future = _service.listar();
          });
        },
        child: Card(
          elevation: 1.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border(
                left: BorderSide(
                  color: statusColor,
                  width: 3,
                ),
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: Colors.grey.shade100,
                      ),
                      child: Text(
                        '#${tarefa.id}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (prioridade != null && prioridade.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: prioridadeCor.withOpacity(0.08),
                        ),
                        child: Text(
                          prioridade,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: prioridadeCor,
                          ),
                        ),
                      ),
                    const Spacer(),
                    if (tarefa.geradaPorIa)
                      const Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: Color(0xFF22C55E),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  tarefa.titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (tarefa.descricao != null &&
                    tarefa.descricao!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      tarefa.descricao!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey.shade700),
                    ),
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (tarefa.responsavelSugerido != null &&
                        tarefa.responsavelSugerido!.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 14,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tarefa.responsavelSugerido!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    if (tarefa.horasPrevistas != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${tarefa.horasPrevistas!.toStringAsFixed(1)} h',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

