import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/relatorio_tarefas_meta.dart';
import '../services/api_client.dart';
import '../services/relatorios_service.dart';
import '../widgets/conversys_app_bar.dart';
import 'notificacoes_screen.dart';

class RelatorioDetalheScreen extends StatefulWidget {
  final ApiClient apiClient;
  final RelatorioTarefasMeta meta;

  const RelatorioDetalheScreen({
    super.key,
    required this.apiClient,
    required this.meta,
  });

  @override
  State<RelatorioDetalheScreen> createState() =>
      _RelatorioDetalheScreenState();
}

class _RelatorioDetalheScreenState extends State<RelatorioDetalheScreen> {
  late final RelatoriosService _service;

  bool _loading = true;
  String? _error;
  dynamic _rawData;
  List<Map<String, dynamic>> _rows = const [];
  List<String> _columns = const [];

  @override
  void initState() {
    super.initState();
    _service = RelatoriosService(widget.apiClient);
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _service.carregarDadosEndpoint(widget.meta);
      final rows = _deriveRows(data);
      final columns = _deriveColumns(rows);

      setState(() {
        _rawData = data;
        _rows = rows;
        _columns = columns;
      });
    } catch (e) {
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

  List<Map<String, dynamic>> _deriveRows(dynamic value) {
    if (value is List) {
      return value.whereType<Map<String, dynamic>>().toList();
    }
    if (value is Map<String, dynamic>) {
      final results = value['results'];
      if (results is List) {
        return results.whereType<Map<String, dynamic>>().toList();
      }
      final items = value['items'];
      if (items is List) {
        return items.whereType<Map<String, dynamic>>().toList();
      }
      for (final entry in value.entries) {
        if (entry.value is List) {
          final list = (entry.value as List)
              .whereType<Map<String, dynamic>>()
              .toList();
          if (list.isNotEmpty) {
            return list;
          }
        }
      }
    }
    return const [];
  }

  List<String> _deriveColumns(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return const [];
    final set = <String>{};
    for (final row in rows) {
      set.addAll(row.keys);
    }
    final list = set.toList();
    list.sort();
    return list;
  }

  String _formatCellValue(dynamic value) {
    if (value == null || value == '') return '—';
    if (value is num || value is bool || value is String) {
      return value.toString();
    }
    try {
      return jsonEncode(value);
    } catch (_) {
      return value.toString();
    }
  }

  void _exportCsvToClipboard() {
    if (_rows.isEmpty || _columns.isEmpty) return;

    final header = _columns.join(';');
    final body = _rows.map((row) {
      return _columns.map((col) {
        final value = row[col];
        if (value == null) return '';
        if (value is Map || value is List) {
          final encoded = jsonEncode(value).replaceAll('"', '""');
          return encoded;
        }
        return value.toString().replaceAll(';', ',');
      }).join(';');
    }).join('\n');

    final csv = '$header\n$body';
    Clipboard.setData(ClipboardData(text: csv));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('CSV copiado para a área de transferência.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meta = widget.meta;

    return Scaffold(
      appBar: conversysAppBar(
        meta.nome,
        onNotificationsTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  NotificacoesScreen(apiClient: widget.apiClient),
            ),
          );
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meta.nome,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (meta.descricao.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            meta.descricao,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      if (meta.endpointApi.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Endpoint: ${meta.endpointApi}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontSize: 11),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: _rows.isEmpty || _columns.isEmpty
                          ? null
                          : _exportCsvToClipboard,
                      child: const Text(
                        'Exportar CSV',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 4),
                    OutlinedButton(
                      onPressed: _carregar,
                      child: const Text(
                        'Recarregar',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _buildBody(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
    if (_rows.isEmpty || _columns.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Nenhum dado retornado pelo relatório.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: _columns
                    .map(
                      (c) => DataColumn(
                        label: Text(
                          c,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                rows: _rows
                    .map(
                      (row) => DataRow(
                        cells: _columns
                            .map(
                              (c) => DataCell(
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minWidth: 80,
                                    maxWidth: 200,
                                  ),
                                  child: Text(
                                    _formatCellValue(row[c]),
                                    style: const TextStyle(fontSize: 11),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 3,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
        ExpansionTile(
          title: const Text(
            'Ver JSON bruto do relatório',
            style: TextStyle(fontSize: 12),
          ),
          children: [
            SizedBox(
              height: 200,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(8),
                child: Text(
                  const JsonEncoder.withIndent('  ').convert(_rawData),
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

