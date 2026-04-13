import 'package:flutter/material.dart';

import '../models/cliente.dart';
import '../services/clientes_service.dart';
import '../services/api_client.dart';
import '../services/propostas_service.dart';
import '../widgets/conversys_app_bar.dart';
import 'notificacoes_screen.dart';

class PropostasCopilotScreen extends StatefulWidget {
  final ApiClient apiClient;

  const PropostasCopilotScreen({super.key, required this.apiClient});

  @override
  State<PropostasCopilotScreen> createState() => _PropostasCopilotScreenState();
}

class _PropostasCopilotScreenState extends State<PropostasCopilotScreen> {
  late final PropostasService _service;
  late final ClientesService _clientesService;

  List<Cliente> _clientes = const [];
  Cliente? _clienteSelecionado;

  bool _loadingClientes = true;
  String? _error;

  final _perguntaController = TextEditingController();

  bool _consultando = false;

  final List<_CopilotMsg> _mensagens = [];
  final List<PropostasCopilotSugestao> _sugestoes = [];

  bool _loadingSugestoes = false;

  @override
  void initState() {
    super.initState();
    _service = PropostasService(widget.apiClient);
    _clientesService = ClientesService(widget.apiClient);
    _carregarClientes();
  }

  @override
  void dispose() {
    _perguntaController.dispose();
    super.dispose();
  }

  Future<void> _carregarClientes() async {
    setState(() {
      _loadingClientes = true;
      _error = null;
    });
    try {
      final clients = await _clientesService.listarClientes();
      if (!mounted) return;
      setState(() {
        _clientes = clients;
        _clienteSelecionado = clients.isNotEmpty ? clients.first : null;
      });
      await _carregarSugestoes();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _loadingClientes = false);
    }
  }

  Future<void> _carregarSugestoes() async {
    final clienteId = _clienteSelecionado?.id;
    setState(() => _loadingSugestoes = true);
    try {
      final lista = await _service.buscarSugestoesCopilot(clienteId: clienteId);
      if (!mounted) return;
      setState(() {
        _sugestoes
          ..clear()
          ..addAll(lista);
      });
    } catch (_) {
      // Silencioso: sugestões são secundárias.
    } finally {
      if (!mounted) return;
      setState(() => _loadingSugestoes = false);
    }
  }

  Future<void> _perguntar() async {
    if (_consultando) return;

    final conteudo = _perguntaController.text.trim();
    if (conteudo.isEmpty) return;

    final clienteId = _clienteSelecionado?.id;

    setState(() {
      _consultando = true;
      _mensagens.add(_CopilotMsg.user(conteudo));
      _mensagens.add(_CopilotMsg.thinking());
    });
    _perguntaController.clear();

    try {
      final resp = await _service.perguntarCopilot(
        clienteId: clienteId,
        mensagem: conteudo,
      );

      if (!mounted) return;

      setState(() {
        // remove placeholder thinking (último)
        if (_mensagens.isNotEmpty && _mensagens.last.isThinking) {
          _mensagens.removeLast();
        }
        _mensagens.add(_CopilotMsg.bot(resp));
      });

      // Atualiza sugestões após cada interação (como no front).
      await _carregarSugestoes();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (_mensagens.isNotEmpty && _mensagens.last.isThinking) {
          _mensagens.removeLast();
        }
        _mensagens.add(
          _CopilotMsg.bot(
            'Não consegui falar com o Copilot de Propostas agora. Verifique o backend e tente novamente.\n\nDetalhe: $e',
          ),
        );
      });
    } finally {
      if (!mounted) return;
      setState(() => _consultando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF020617);
    const cardColor = Color(0xFF0B1220);
    const cardBorder = Color(0xFF1E293B);

    return Scaffold(
      appBar: conversysAppBar(
        'Copilot de Propostas',
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
                    'Copilot de Propostas',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Combine serviços, parcerias e histórico do cliente para montar propostas.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 14),
                  if (_loadingClientes)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else ...[
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Erro ao carregar clientes: $_error',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    DropdownButtonFormField<Cliente>(
                      value: _clienteSelecionado,
                      dropdownColor: cardColor,
                      decoration: const InputDecoration(
                        labelText: 'Cliente (contexto)',
                        border: OutlineInputBorder(),
                      ),
                      items: _clientes
                          .map(
                            (c) => DropdownMenuItem<Cliente>(
                              value: c,
                              child: Text(
                                c.nome,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) async {
                        if (value == null) return;
                        setState(() => _clienteSelecionado = value);
                        await _carregarSugestoes();
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: ListView.separated(
                itemCount: _mensagens.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final m = _mensagens[index];
                  final isUser = m.role == _CopilotRole.user;
                  final bubbleColor = isUser
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.8)
                      : Colors.white.withOpacity(0.06);

                  return Align(
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 320),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.12)),
                      ),
                      child: m.isThinking
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Pensando...',
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            )
                          : Text(
                              m.content,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),

            // Input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _perguntaController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Pergunta para o Copilot',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _consultando ? null : () => _perguntar(),
                  icon: _consultando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: const Text('Enviar'),
                ),
              ],
            ),

            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.list_alt, size: 18, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text(
                        'Sugestões recentes',
                        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _loadingSugestoes ? null : () => _carregarSugestoes(),
                        child: _loadingSugestoes
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Recarregar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_sugestoes.isEmpty)
                    Text(
                      _loadingSugestoes
                          ? 'Carregando sugestões...'
                          : 'As sugestões aparecerão aqui conforme você usar o Copilot.',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    )
                  else
                    ..._sugestoes.take(6).map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.10)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      s.titulo,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  if (s.valorEstimado != null)
                                    Text(
                                      s.valorEstimado!.toString(),
                                      style: const TextStyle(
                                        color: Colors.greenAccent,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _CopilotRole { user, bot }

class _CopilotMsg {
  final _CopilotRole role;
  final String content;
  final bool isThinking;

  const _CopilotMsg({
    required this.role,
    required this.content,
    required this.isThinking,
  });

  bool get isUser => role == _CopilotRole.user;

  static _CopilotMsg user(String content) =>
      _CopilotMsg(role: _CopilotRole.user, content: content, isThinking: false);

  static _CopilotMsg bot(String content) =>
      _CopilotMsg(role: _CopilotRole.bot, content: content, isThinking: false);

  static _CopilotMsg thinking() =>
      const _CopilotMsg(role: _CopilotRole.bot, content: '', isThinking: true);
}

