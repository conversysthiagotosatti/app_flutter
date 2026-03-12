import 'package:flutter/material.dart';

import '../models/contrato_tarefa.dart';
import '../services/api_client.dart';
import '../services/contrato_tarefas_service.dart';
import '../services/timers_service.dart';

class TarefasApontamentoScreen extends StatefulWidget {
  final ApiClient apiClient;
  final DateTime data;

  const TarefasApontamentoScreen({
    super.key,
    required this.apiClient,
    required this.data,
  });

  @override
  State<TarefasApontamentoScreen> createState() =>
      _TarefasApontamentoScreenState();
}

class _TarefasApontamentoScreenState extends State<TarefasApontamentoScreen> {
  late final ContratoTarefasService _tarefasService;
  late final TimersService _timersService;

  List<ContratoTarefa> _tarefas = const [];
  ContratoTarefa? _tarefaSelecionada;

  final _horasController = TextEditingController();
  final _descricaoController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tarefasService = ContratoTarefasService(widget.apiClient);
    _timersService = TimersService(widget.apiClient);
    _carregarTarefas();
  }

  @override
  void dispose() {
    _horasController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _carregarTarefas() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final itens = await _tarefasService.listar();
      if (!mounted) return;
      setState(() {
        _tarefas = itens;
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

  Future<void> _salvar() async {
    if (_tarefaSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione uma tarefa.'),
        ),
      );
      return;
    }
    final horas = double.tryParse(
      _horasController.text.replaceAll(',', '.'),
    );
    if (horas == null || horas <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe um número de horas válido.'),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });
    try {
      await _timersService.lancarHorasManual(
        tarefaId: _tarefaSelecionada!.id,
        horas: horas,
        descricao: _descricaoController.text,
        data: widget.data,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Apontamento registrado com sucesso.'),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao lançar horas: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final dataLabel =
        '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo apontamento'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data: $dataLabel',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Erro ao carregar tarefas: $_error',
                        style:
                            const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  DropdownButtonFormField<ContratoTarefa>(
                    value: _tarefaSelecionada,
                    decoration: const InputDecoration(
                      labelText: 'Tarefa',
                      border: OutlineInputBorder(),
                    ),
                    items: _tarefas
                        .map(
                          (t) => DropdownMenuItem<ContratoTarefa>(
                            value: t,
                            child: Text(
                              '#${t.id} · ${t.titulo}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _tarefaSelecionada = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _horasController,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Horas (ex: 1.5)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descricaoController,
                    decoration: const InputDecoration(
                      labelText: 'Descrição (opcional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _salvar,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Registrar apontamento'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

