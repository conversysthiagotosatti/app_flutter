import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/copilot_service.dart';
import '../widgets/conversys_app_bar.dart';
import 'notificacoes_screen.dart';

class HelpdeskCopilotScreen extends StatefulWidget {
  final ApiClient apiClient;

  const HelpdeskCopilotScreen({
    super.key,
    required this.apiClient,
  });

  @override
  State<HelpdeskCopilotScreen> createState() =>
      _HelpdeskCopilotScreenState();
}

class _HelpdeskCopilotScreenState
    extends State<HelpdeskCopilotScreen> {
  late final CopilotService _copilotService;

  final _perguntaController = TextEditingController();
  String? _resposta;
  bool _consultando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _copilotService = CopilotService(widget.apiClient);
  }

  @override
  void dispose() {
    _perguntaController.dispose();
    super.dispose();
  }

  Future<void> _perguntar() async {
    final pergunta = _perguntaController.text.trim();
    if (pergunta.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite uma pergunta.'),
        ),
      );
      return;
    }

    setState(() {
      _consultando = true;
      _resposta = null;
      _error = null;
    });
    try {
      final resposta =
          await _copilotService.perguntarHelpdesk(
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
                    'Copilot de Helpdesk',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Faça perguntas sobre filas, SLA, atendentes e tickets abertos. '
                    'O Copilot analisa os dados de helpdesk do cliente atual.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Erro: $_error',
                        style: const TextStyle(
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  TextField(
                    controller: _perguntaController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Digite sua pergunta de helpdesk',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          _consultando ? null : _perguntar,
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
                      label: const Text(
                        'Perguntar ao Copilot',
                      ),
                    ),
                  ),
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
                          style: TextStyle(
                            color: Colors.white54,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Text(
                          _resposta!,
                          style: const TextStyle(
                            color: Colors.white,
                          ),
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

