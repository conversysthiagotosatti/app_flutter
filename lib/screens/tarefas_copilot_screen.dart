import 'package:flutter/material.dart';

import '../models/contrato.dart';
import '../services/api_client.dart';
import '../services/contratos_service.dart';
import '../services/copilot_service.dart';
import '../widgets/conversys_app_bar.dart';
import 'notificacoes_screen.dart';

class TarefasCopilotScreen extends StatefulWidget {
  final ApiClient apiClient;

  const TarefasCopilotScreen({super.key, required this.apiClient});

  @override
  State<TarefasCopilotScreen> createState() => _TarefasCopilotScreenState();
}

class _TarefasCopilotScreenState extends State<TarefasCopilotScreen> {
  late final ContratosService _contratosService;
  late final CopilotService _copilotService;

  List<Contrato> _contratos = const [];
  Contrato? _contratoSelecionado;

  final _perguntaController = TextEditingController();
  String? _resposta;
  bool _loadingContratos = true;
  bool _consultando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _contratosService = ContratosService(widget.apiClient);
    _copilotService = CopilotService(widget.apiClient);
    _carregarContratos();
  }

  @override
  void dispose() {
    _perguntaController.dispose();
    super.dispose();
  }

  Future<void> _carregarContratos() async {
    setState(() {
      _loadingContratos = true;
      _error = null;
    });
    try {
      final itens = await _contratosService.listarContratos();
      if (!mounted) return;
      setState(() {
        _contratos = itens;
        if (itens.isNotEmpty) {
          _contratoSelecionado = itens.first;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingContratos = false;
        });
      }
    }
  }

  Future<void> _perguntar() async {
    if (_contratoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um contrato para o Copilot.')),
      );
      return;
    }
    final pergunta = _perguntaController.text.trim();
    if (pergunta.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Digite uma pergunta.')));
      return;
    }

    setState(() {
      _consultando = true;
      _resposta = null;
      _error = null;
    });
    try {
      final resposta = await _copilotService.perguntar(
        contratoId: _contratoSelecionado!.id,
        mensagem: pergunta,
      );
      if (!mounted) return;
      setState(() {
        _resposta = resposta;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _consultando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF020617);
    const cardColor = Color(0xFF0B1220);
    const cardBorder = Color(0xFF1E293B);

    return Scaffold(
      appBar: conversysAppBar(
        context,
        'Copilot de tarefas',
        onNotificationsTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NotificacoesScreen(apiClient: widget.apiClient),
            ),
          );
        },
      ),
      backgroundColor: background,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pergunte ao Copilot sobre suas tarefas',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selecione um contrato de projetos e faça perguntas sobre tarefas, épicos e andamento.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  if (_loadingContratos)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  else ...[
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Erro ao carregar contratos: $_error',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    DropdownButtonFormField<Contrato>(
                      initialValue: _contratoSelecionado,
                      dropdownColor: cardColor,
                      decoration: const InputDecoration(
                        labelText: 'Contrato',
                        border: OutlineInputBorder(),
                      ),
                      items: _contratos
                          .map(
                            (c) => DropdownMenuItem<Contrato>(
                              value: c,
                              child: Text(
                                '#${c.id} · ${c.titulo}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _contratoSelecionado = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _perguntaController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Digite sua pergunta',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _consultando ? null : _perguntar,
                        icon: _consultando
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.bolt),
                        label: const Text('Perguntar ao Copilot'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorder),
                ),
                padding: const EdgeInsets.all(16),
                child: _resposta == null
                    ? const Center(
                        child: Text(
                          'Aguardando pergunta...',
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Text(
                          _resposta!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
