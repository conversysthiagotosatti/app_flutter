import 'package:flutter/material.dart';

import '../models/contrato.dart';
import '../models/epico.dart';
import '../services/api_client.dart';
import '../services/contratos_service.dart';
import '../services/epicos_service.dart';
import '../widgets/conversys_app_bar.dart';
import 'notificacoes_screen.dart';

class CadastrarEpicoScreen extends StatefulWidget {
  final ApiClient apiClient;

  const CadastrarEpicoScreen({super.key, required this.apiClient});

  @override
  State<CadastrarEpicoScreen> createState() => _CadastrarEpicoScreenState();
}

class _CadastrarEpicoScreenState extends State<CadastrarEpicoScreen> {
  late final ContratosService _contratosService;
  late final EpicosService _epicosService;

  Future<List<Contrato>>? _contratosFuture;
  Future<List<Epico>>? _epicosFuture;

  Contrato? _contratoSelecionado;
  Epico? _epicoSelecionado;

  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _contratosService = ContratosService(widget.apiClient);
    _epicosService = EpicosService(widget.apiClient);
    _contratosFuture = _contratosService.listarContratos();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  void _carregarEpicosParaContrato(Contrato contrato) {
    setState(() {
      _contratoSelecionado = contrato;
      _epicoSelecionado = null;
      _tituloController.clear();
      _descricaoController.clear();
      _epicosFuture = _epicosService.listar(contratoId: contrato.id);
    });
  }

  void _selecionarEpico(Epico epico) {
    setState(() {
      _epicoSelecionado = epico;
      _tituloController.text = epico.titulo;
      _descricaoController.text = epico.descricao ?? '';
    });
  }

  void _novoEpico() {
    setState(() {
      _epicoSelecionado = null;
      _tituloController.clear();
      _descricaoController.clear();
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
      if (_epicoSelecionado == null) {
        await _epicosService.criar(
          contratoId: contrato.id,
          titulo: _tituloController.text.trim(),
          descricao: _descricaoController.text.trim().isEmpty
              ? null
              : _descricaoController.text.trim(),
        );
      } else {
        await _epicosService.atualizar(
          id: _epicoSelecionado!.id,
          titulo: _tituloController.text.trim(),
          descricao: _descricaoController.text.trim(),
        );
      }

      _carregarEpicosParaContrato(contrato);
      _novoEpico();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar épico: $e'),
        ),
      );
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
    return Scaffold(
      appBar: conversysAppBar(
        'Épicos do contrato',
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
                    _carregarEpicosParaContrato(value);
                  },
                  decoration: const InputDecoration(
                    labelText: 'Contrato',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Row(
                    children: [
                      // Lista de épicos
                      Expanded(
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Épicos cadastrados',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _novoEpico,
                                      child: const Text('Novo épico'),
                                    ),
                                  ],
                                ),
                                const Divider(height: 8),
                                Expanded(
                                  child: FutureBuilder<List<Epico>>(
                                    future: _epicosFuture,
                                    builder: (context, snap) {
                                      if (snap.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                          child:
                                              CircularProgressIndicator(),
                                        );
                                      }
                                      if (snap.hasError) {
                                        return Center(
                                          child: Text(
                                              'Erro ao carregar épicos: ${snap.error}'),
                                        );
                                      }
                                      final epicos = snap.data ?? [];
                                      if (epicos.isEmpty) {
                                        return const Center(
                                          child: Text(
                                            'Nenhum épico cadastrado para este contrato.',
                                            textAlign: TextAlign.center,
                                          ),
                                        );
                                      }
                                      return ListView.separated(
                                        itemCount: epicos.length,
                                        separatorBuilder: (_, __) =>
                                            const Divider(height: 1),
                                        itemBuilder: (context, index) {
                                          final e = epicos[index];
                                          final selecionado =
                                              _epicoSelecionado?.id ==
                                                  e.id;
                                          return ListTile(
                                            title: Text(e.titulo),
                                            subtitle: e.descricao != null &&
                                                    e.descricao!
                                                        .isNotEmpty
                                                ? Text(
                                                    e.descricao!,
                                                    maxLines: 2,
                                                    overflow: TextOverflow
                                                        .ellipsis,
                                                  )
                                                : null,
                                            trailing: Text(
                                              e.status,
                                              style: const TextStyle(
                                                fontSize: 11,
                                              ),
                                            ),
                                            selected: selecionado,
                                            onTap: () =>
                                                _selecionarEpico(e),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Formulário
                      Expanded(
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _epicoSelecionado == null
                                        ? 'Novo épico'
                                        : 'Editar épico',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  const SizedBox(height: 16),
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
                                      decoration:
                                          const InputDecoration(
                                        labelText: 'Descrição (opcional)',
                                        border: OutlineInputBorder(),
                                        alignLabelWithHint: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: FilledButton(
                                      onPressed:
                                          _salvando ? null : _salvar,
                                      child: _salvando
                                          ? const SizedBox(
                                              height: 18,
                                              width: 18,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                            Color>(
                                                        Colors.white),
                                              ),
                                            )
                                          : Text(_epicoSelecionado ==
                                                  null
                                              ? 'Criar épico'
                                              : 'Salvar alterações'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

