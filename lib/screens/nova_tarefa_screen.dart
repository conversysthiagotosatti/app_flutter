import 'package:flutter/material.dart';

import '../models/contrato.dart';
import '../models/epico.dart';
import '../models/contrato_tarefa.dart';
import '../services/api_client.dart';
import '../services/contratos_service.dart';
import '../services/epicos_service.dart';
import '../services/contrato_tarefas_service.dart';
import '../widgets/conversys_app_bar.dart';
import 'notificacoes_screen.dart';

class NovaTarefaScreen extends StatefulWidget {
  final ApiClient apiClient;

  const NovaTarefaScreen({super.key, required this.apiClient});

  @override
  State<NovaTarefaScreen> createState() => _NovaTarefaScreenState();
}

class _NovaTarefaScreenState extends State<NovaTarefaScreen> {
  late final ContratosService _contratosService;
  late final EpicosService _epicosService;
  late final ContratoTarefasService _tarefasService;

  Future<List<Contrato>>? _contratosFuture;
  Future<List<Epico>>? _epicosFuture;

  Contrato? _contratoSelecionado;
  Epico? _epicoSelecionado;

  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _horasController = TextEditingController();
  DateTime? _dataInicioPrevista;
  String _prioridade = 'MEDIA';
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _contratosService = ContratosService(widget.apiClient);
    _epicosService = EpicosService(widget.apiClient);
    _tarefasService = ContratoTarefasService(widget.apiClient);
    _contratosFuture = _contratosService.listarContratos();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _horasController.dispose();
    super.dispose();
  }

  void _carregarEpicos(Contrato contrato) {
    setState(() {
      _contratoSelecionado = contrato;
      _epicoSelecionado = null;
      _epicosFuture = _epicosService.listar(contratoId: contrato.id);
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final contrato = _contratoSelecionado;
    if (contrato == null) return;

    setState(() {
      _salvando = true;
    });

    try {
      final horas = double.tryParse(
        _horasController.text.replaceAll(',', '.'),
      );

      await _tarefasService.criar(
        contratoId: contrato.id,
        titulo: _tituloController.text.trim(),
        descricao: _descricaoController.text.trim().isEmpty
            ? null
            : _descricaoController.text.trim(),
        prioridade: _prioridade,
        dataInicioPrevista: _dataInicioPrevista,
        horasPrevistas: horas,
        epicoId: _epicoSelecionado?.id,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar tarefa: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _salvando = false;
        });
      }
    }
  }

  Future<void> _selecionarData() async {
    final hoje = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataInicioPrevista ?? hoje,
      firstDate: hoje.subtract(const Duration(days: 365)),
      lastDate: hoje.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _dataInicioPrevista = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: conversysAppBar(
        'Nova tarefa',
        onNotificationsTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  NotificacoesScreen(apiClient: widget.apiClient),
            ),
          );
        },
      ),
      body: FutureBuilder<List<Contrato>>(
        future: _contratosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar contratos: ${snapshot.error}'),
            );
          }

          final contratos = snapshot.data ?? [];
          if (contratos.isEmpty) {
            return const Center(
              child: Text('Nenhum contrato encontrado.'),
            );
          }

          _contratoSelecionado ??= contratos.first;
          _epicosFuture ??=
              _epicosService.listar(contratoId: _contratoSelecionado!.id);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<Contrato>(
                    value: _contratoSelecionado,
                    items: contratos
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(
                              c.titulo,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      _carregarEpicos(value);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Contrato',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Row(
                      children: [
                        // Lado esquerdo: Épico e dados adicionais
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FutureBuilder<List<Epico>>(
                                future: _epicosFuture,
                                builder: (context, snap) {
                                  Widget child;
                                  if (snap.connectionState ==
                                      ConnectionState.waiting) {
                                    child = const Text(
                                        'Carregando épicos...');
                                  } else if (snap.hasError) {
                                    child = Text(
                                      'Erro ao carregar épicos: ${snap.error}',
                                    );
                                  } else {
                                    final epicos = snap.data ?? [];
                                    child = DropdownButtonFormField<Epico>(
                                      value: _epicoSelecionado,
                                      items: [
                                        const DropdownMenuItem<Epico>(
                                          value: null,
                                          child: Text('Nenhum épico'),
                                        ),
                                        ...epicos.map(
                                          (e) => DropdownMenuItem(
                                            value: e,
                                            child: Text(
                                              e.titulo,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _epicoSelecionado = value;
                                        });
                                      },
                                      decoration: const InputDecoration(
                                        labelText: 'Épico (opcional)',
                                        border: OutlineInputBorder(),
                                      ),
                                    );
                                  }
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      child,
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: _horasController,
                                        keyboardType:
                                            TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                        decoration:
                                            const InputDecoration(
                                          labelText: 'Horas previstas',
                                          hintText: 'Ex: 4.0',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      InkWell(
                                        onTap: _selecionarData,
                                        child: InputDecorator(
                                          decoration:
                                              const InputDecoration(
                                            labelText:
                                                'Previsão de início',
                                            border: OutlineInputBorder(),
                                          ),
                                          child: Text(
                                            _dataInicioPrevista == null
                                                ? 'Selecione uma data'
                                                : '${_dataInicioPrevista!.day.toString().padLeft(2, '0')}/'
                                                    '${_dataInicioPrevista!.month.toString().padLeft(2, '0')}/'
                                                    '${_dataInicioPrevista!.year}',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      DropdownButtonFormField<String>(
                                        value: _prioridade,
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'ALTA',
                                            child: Text('Alta'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'MEDIA',
                                            child: Text('Média'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'BAIXA',
                                            child: Text('Baixa'),
                                          ),
                                        ],
                                        onChanged: (value) {
                                          if (value == null) return;
                                          setState(() {
                                            _prioridade = value;
                                          });
                                        },
                                        decoration:
                                            const InputDecoration(
                                          labelText: 'Prioridade',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Lado direito: título e descrição
                        Expanded(
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _tituloController,
                                decoration: const InputDecoration(
                                  labelText: 'Título *',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null ||
                                      value.trim().isEmpty) {
                                    return 'Informe o título';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _descricaoController,
                                  maxLines: null,
                                  expands: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Descrição',
                                    border: OutlineInputBorder(),
                                    alignLabelWithHint: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: _salvando ? null : _salvar,
                      child: _salvando
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Criar tarefa'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

