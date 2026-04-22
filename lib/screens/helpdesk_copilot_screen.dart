import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../services/api_client.dart';
import '../services/copilot_service.dart';
import '../services/helpdesk_chamados_service.dart';
import '../widgets/conversys_app_bar.dart';
import 'notificacoes_screen.dart';

/// Alinhado ao portal: `CopilotHelpdesk.tsx` + `askHelpdeskCopilot`.
enum _AgentStatus { idle, thinking, executing, online, error }

class _ChatMessage {
  final String id;
  final bool isUser;
  final String content;
  final DateTime timestamp;
  final bool isThinking;

  _ChatMessage({
    required this.id,
    required this.isUser,
    required this.content,
    required this.timestamp,
    this.isThinking = false,
  });
}

class _PromptItem {
  final String label;
  final String prompt;

  const _PromptItem({required this.label, required this.prompt});
}

class _PromptCategory {
  final String title;
  final List<_PromptItem> items;

  const _PromptCategory({required this.title, required this.items});
}

/// Mesmos textos de `HELPDESK_PROMPTS` em `PromptLibraryMenu.tsx`.
const _helpdeskPromptLibrary = <_PromptCategory>[
  _PromptCategory(
    title: 'Visão geral & fila',
    items: [
      _PromptItem(
        label: 'Chamados abertos',
        prompt:
            'Consultar status dos chamados em aberto, filas e possíveis gargalos para o cliente ativo.',
      ),
      _PromptItem(
        label: 'Resumo executivo',
        prompt:
            'Resumir a situação do help desk: volumes por status, prioridades críticas e tendência.',
      ),
      _PromptItem(
        label: 'Próximos passos',
        prompt:
            'Sugira próximos passos operacionais com base nos chamados ativos e no SLA.',
      ),
    ],
  ),
  _PromptCategory(
    title: 'SLA & risco',
    items: [
      _PromptItem(
        label: 'Risco de SLA',
        prompt:
            'Analisar risco de SLA nos chamados ativos e destacar os mais críticos.',
      ),
      _PromptItem(
        label: 'Chamados em atraso',
        prompt:
            'Quais chamados estão em risco ou violando SLA de resposta ou resolução?',
      ),
    ],
  ),
  _PromptCategory(
    title: 'Atendimento',
    items: [
      _PromptItem(
        label: 'Resposta sugerida',
        prompt:
            'Gerar resposta automática profissional para o chamado em contexto, em tom neutro e objetivo.',
      ),
      _PromptItem(
        label: 'Resumir conversa',
        prompt:
            'Resumir a conversa do chamado em contexto para handoff ou nota interna.',
      ),
      _PromptItem(
        label: 'Problema recorrente',
        prompt:
            'Detectar se há padrão ou problema recorrente relacionado aos chamados recentes.',
      ),
    ],
  ),
];

/// `QUICK_SUGGESTIONS` em `CopilotHelpdesk.tsx`.
const _quickSuggestions = <({String label, String prompt})>[
  (
    label: 'Status abertos',
    prompt:
        'Consultar status dos chamados em aberto e possíveis gargalos de fila.',
  ),
  (
    label: 'Risco de SLA',
    prompt: 'Analisar risco de SLA nos chamados ativos do cliente.',
  ),
  (
    label: 'Recorrência',
    prompt:
        'Detectar problema recorrente ou padrões nos chamados recentes.',
  ),
];

class HelpdeskCopilotScreen extends StatefulWidget {
  final ApiClient apiClient;

  /// Contexto do chamado selecionado (portal: `selectedChamadoId`).
  final int? chamadoId;

  const HelpdeskCopilotScreen({
    super.key,
    required this.apiClient,
    this.chamadoId,
  });

  @override
  State<HelpdeskCopilotScreen> createState() =>
      _HelpdeskCopilotScreenState();
}

class _HelpdeskCopilotScreenState extends State<HelpdeskCopilotScreen> {
  late final CopilotService _copilot;
  late final HelpdeskChamadosService _hd;

  final _input = TextEditingController();
  final _scroll = ScrollController();

  final List<_ChatMessage> _messages = [];
  bool _processing = false;
  _AgentStatus _agent = _AgentStatus.idle;
  bool _expanded = false;

  int? _clienteId;
  String _clienteNome = 'Sem cliente';

  @override
  void initState() {
    super.initState();
    _copilot = CopilotService(widget.apiClient);
    _hd = HelpdeskChamadosService(widget.apiClient);
    _input.addListener(() {
      if (mounted) setState(() {});
    });
    _loadClienteContext();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadClienteContext() async {
    final id = await widget.apiClient.loadAuthClienteId();
    final nome = await widget.apiClient.loadAuthClienteNome();
    if (id != null && nome != null && nome.isNotEmpty) {
      if (mounted) {
        setState(() {
          _clienteId = id;
          _clienteNome = nome;
        });
      }
      return;
    }
    try {
      final me = await _hd.fetchAuthMe();
      final mem = me['memberships'];
      if (mem is List && mem.isNotEmpty) {
        final first = mem.first;
        if (first is Map<String, dynamic>) {
          final cid = first['cliente_id'];
          final n = first['cliente_nome']?.toString() ?? '';
          int? parsed;
          if (cid is int) {
            parsed = cid;
          } else if (cid is num) {
            parsed = cid.toInt();
          }
          if (parsed != null && n.isNotEmpty) {
            await widget.apiClient.saveAuthClienteContext(
              clienteId: parsed,
              clienteNome: n,
            );
            if (mounted) {
              setState(() {
                _clienteId = parsed;
                _clienteNome = n;
              });
            }
          }
        }
      }
    } catch (_) {
      /* mantém "Sem cliente" */
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  String _statusLabel() {
    switch (_agent) {
      case _AgentStatus.idle:
        return 'Standby';
      case _AgentStatus.thinking:
        return 'Analisando...';
      case _AgentStatus.executing:
        return 'Processando...';
      case _AgentStatus.online:
        return 'Online';
      case _AgentStatus.error:
        return 'Offline';
    }
  }

  Color _statusDot() {
    switch (_agent) {
      case _AgentStatus.error:
        return Colors.redAccent;
      case _AgentStatus.thinking:
      case _AgentStatus.executing:
        return Colors.pinkAccent;
      case _AgentStatus.online:
      case _AgentStatus.idle:
        return _messages.isNotEmpty ? Colors.pinkAccent : const Color(0xFF005AFF);
    }
  }

  Future<void> _send(String text) async {
    final t = text.trim();
    if (t.isEmpty || _processing) return;

    final now = DateTime.now();
    final userId = 'u-${now.millisecondsSinceEpoch}';
    final thinkId = 't-${now.millisecondsSinceEpoch}';

    setState(() {
      _messages.add(
        _ChatMessage(
          id: userId,
          isUser: true,
          content: t,
          timestamp: now,
        ),
      );
      _messages.add(
        _ChatMessage(
          id: thinkId,
          isUser: false,
          content: '',
          timestamp: now,
          isThinking: true,
        ),
      );
      _processing = true;
      _agent = _AgentStatus.thinking;
    });
    _input.clear();
    _scrollToEnd();

    try {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() => _agent = _AgentStatus.executing);

      final res = await _copilot.askHelpdeskCopilot(
        mensagem: t,
        clienteId: _clienteId,
        chamadoId: widget.chamadoId,
      );

      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) => m.id == thinkId);
        _messages.add(
          _ChatMessage(
            id: 'a-${DateTime.now().millisecondsSinceEpoch}',
            isUser: false,
            content: res.answer.isEmpty
                ? 'Sem resposta do servidor.'
                : res.answer,
            timestamp: DateTime.now(),
          ),
        );
        _agent = _AgentStatus.online;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) => m.id == thinkId);
        _messages.add(
          _ChatMessage(
            id: 'e-${DateTime.now().millisecondsSinceEpoch}',
            isUser: false,
            content:
                'Não foi possível conectar ao Copilot Helpdesk. ${e.toString().replaceFirst('Exception: ', '')}',
            timestamp: DateTime.now(),
          ),
        );
        _agent = _AgentStatus.error;
      });
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
      _scrollToEnd();
    }
  }

  void _openPromptLibrary() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0B1220),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Biblioteca de prompts',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              for (final cat in _helpdeskPromptLibrary) ...[
                Text(
                  cat.title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                for (final it in cat.items)
                  ListTile(
                    dense: true,
                    title: Text(
                      it.label,
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() => _input.text = it.prompt);
                    },
                  ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        );
      },
    );
  }

  String _relativeTime(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inSeconds < 60) return 'agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} h';
    return '${diff.inDays} d';
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF020617);
    const cardColor = Color(0xFF0B1220);
    const cardBorder = Color(0xFF1E293B);
    const headerBlue = Color(0xFF005AFF);

    return Scaffold(
      backgroundColor: background,
      appBar: conversysAppBar(
        context,
        'Helpdesk · Copilot',
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            decoration: const BoxDecoration(
              color: headerBlue,
              border: Border(
                bottom: BorderSide(color: Color(0xFF1E3A5F)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.headset_mic, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Help Desk Copilot',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _statusDot(),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _statusLabel(),
                            style: TextStyle(
                              color: _agent == _AgentStatus.error
                                  ? Colors.red.shade200
                                  : Colors.white.withValues(alpha: 0.85),
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            ' · ',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 11,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _clienteNome,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 11,
                              ),
                            ),
                          ),
                          if (widget.chamadoId != null) ...[
                            Text(
                              ' · ',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.3),
                                fontSize: 11,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '#${widget.chamadoId}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                  tooltip: 'Limpar conversa',
                  onPressed: _processing
                      ? null
                      : () {
                          setState(() {
                            _messages.clear();
                            _agent = _AgentStatus.idle;
                          });
                        },
                ),
                IconButton(
                  icon: Icon(
                    _expanded ? Icons.unfold_less : Icons.unfold_more,
                    color: Colors.white70,
                  ),
                  tooltip: _expanded ? 'Reduzir' : 'Expandir',
                  onPressed: () =>
                      setState(() => _expanded = !_expanded),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: background,
              padding: _expanded
                  ? const EdgeInsets.symmetric(horizontal: 4)
                  : EdgeInsets.zero,
              child: _messages.isEmpty && !_processing
                  ? Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: headerBlue.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.headset_mic,
                                color: headerBlue,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Assistente de Help Desk',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Analise chamados, SLA, filas e sugestões de resposta. '
                              'O contexto do cliente (e do chamado aberto, se houver) '
                              'é enviado automaticamente.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: _quickSuggestions
                                  .map(
                                    (s) => ActionChip(
                                      label: Text(s.label),
                                      onPressed: () {
                                        setState(() => _input.text = s.prompt);
                                      },
                                      backgroundColor: cardColor,
                                      side: const BorderSide(
                                        color: cardBorder,
                                      ),
                                      labelStyle: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, i) {
                        final msg = _messages[i];
                        final isUser = msg.isUser;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisAlignment: isUser
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isUser) ...[
                                _avatarBot(msg.isThinking),
                                const SizedBox(width: 10),
                              ],
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: isUser
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: isUser
                                            ? const Color(0xFF1E3A5F)
                                            : cardColor,
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(16),
                                          topRight: const Radius.circular(16),
                                          bottomLeft: Radius.circular(
                                            isUser ? 16 : 4,
                                          ),
                                          bottomRight: Radius.circular(
                                            isUser ? 4 : 16,
                                          ),
                                        ),
                                        border: Border.all(
                                          color: isUser
                                              ? Colors.transparent
                                              : cardBorder,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                        child: msg.isThinking
                                            ? Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white54,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Text(
                                                    _agent ==
                                                            _AgentStatus
                                                                .executing
                                                        ? 'Consultando IA e RAG...'
                                                        : 'Analisando...',
                                                    style: const TextStyle(
                                                      color: Colors.white54,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : isUser
                                                ? SelectableText(
                                                    msg.content,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 13,
                                                    ),
                                                  )
                                                : MarkdownBody(
                                                    data: msg.content,
                                                    selectable: true,
                                                    styleSheet:
                                                        MarkdownStyleSheet(
                                                      p: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 13,
                                                        height: 1.35,
                                                      ),
                                                      code: TextStyle(
                                                        color: Colors.cyan
                                                            .shade100,
                                                        fontFamily:
                                                            'monospace',
                                                        fontSize: 12,
                                                      ),
                                                      codeblockDecoration:
                                                          BoxDecoration(
                                                        color: Colors.black26,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                      h1: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 18,
                                                      ),
                                                      h2: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                      ),
                                                      listBullet: const TextStyle(
                                                        color: Colors.white70,
                                                      ),
                                                    ),
                                                  ),
                                      ),
                                    ),
                                    if (!msg.isThinking) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _relativeTime(msg.timestamp),
                                            style: const TextStyle(
                                              color: Colors.white38,
                                              fontSize: 10,
                                            ),
                                          ),
                                          if (!isUser) ...[
                                            const SizedBox(width: 8),
                                            InkWell(
                                              onTap: () {
                                                Clipboard.setData(
                                                  ClipboardData(
                                                    text: msg.content,
                                                  ),
                                                );
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Copiado',
                                                    ),
                                                    duration: Duration(
                                                      seconds: 1,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: const Text(
                                                'Copiar',
                                                style: TextStyle(
                                                  color: Color(0xFF005AFF),
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isUser) ...[
                                const SizedBox(width: 10),
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF1E3A5F),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.bolt,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
          Material(
            color: cardColor,
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: cardBorder),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        IconButton(
                          onPressed: _processing ? null : _openPromptLibrary,
                          icon: const Icon(Icons.menu_book_outlined),
                          color: Colors.white54,
                          tooltip: 'Biblioteca de prompts',
                        ),
                        Expanded(
                          child: TextField(
                            controller: _input,
                            minLines: 1,
                            maxLines: 5,
                            enabled: !_processing,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'Pergunte sobre chamados, SLA, filas ou peça uma resposta sugerida...',
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 13,
                              ),
                              filled: true,
                              fillColor: background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide:
                                    const BorderSide(color: cardBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide:
                                    const BorderSide(color: cardBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: headerBlue.withValues(alpha: 0.6),
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _send(_input.text),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton.filled(
                          onPressed: _processing ||
                                  _input.text.trim().isEmpty
                              ? null
                              : () => _send(_input.text),
                          icon: _processing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send),
                          style: IconButton.styleFrom(
                            backgroundColor: headerBlue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 11,
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Pipeline NLP + RAG (ai_helpdesk)',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarBot(bool thinking) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: thinking
            ? Colors.pink.shade50.withValues(alpha: 0.15)
            : const Color(0xFF005AFF),
        shape: BoxShape.circle,
        border: thinking
            ? Border.all(color: Colors.pink.shade200.withValues(alpha: 0.4))
            : null,
      ),
      child: Icon(
        Icons.smart_toy_outlined,
        size: 18,
        color: thinking ? Colors.pinkAccent : Colors.white,
      ),
    );
  }
}
