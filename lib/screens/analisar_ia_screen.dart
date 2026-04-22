import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/contrato.dart';
import '../services/api_client.dart';
import '../services/contratos_service.dart';
import '../widgets/conversys_app_bar.dart';
import 'notificacoes_screen.dart';

class AnalisarIaScreen extends StatefulWidget {
  final ApiClient apiClient;

  const AnalisarIaScreen({super.key, required this.apiClient});

  @override
  State<AnalisarIaScreen> createState() => _AnalisarIaScreenState();
}

class _AnalisarIaScreenState extends State<AnalisarIaScreen> {
  late final ContratosService _contratosService;
  Future<List<Contrato>>? _contratosFuture;
  Contrato? _contratoSelecionado;
  PlatformFile? _arquivo;
  String _tipo = 'CONTRATO_PRINCIPAL';
  String _versao = '';
  bool _enviando = false;
  int? _clausulasGravadas;

  @override
  void initState() {
    super.initState();
    _contratosService = ContratosService(widget.apiClient);
    _contratosFuture = _contratosService.listarContratos();
  }

  Future<void> _selecionarPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _arquivo = result.files.first;
        _clausulasGravadas = null;
      });
    }
  }

  Future<void> _enviar() async {
    if (_contratoSelecionado == null || _arquivo == null) return;

    setState(() {
      _enviando = true;
      _clausulasGravadas = null;
    });

    try {
      // 1) Envia PDF para /contratos/{id}/analisar-pdf/
      final uri = Uri.parse(
        '${ApiClient.baseUrl}/api/contratos/${_contratoSelecionado!.id}/analisar-pdf/',
      );

      final request = http.MultipartRequest('POST', uri);
      final headers = await widget.apiClient.buildAuthHeaders(json: false);
      request.headers.addAll(headers);

      // Para Web precisamos usar bytes; em mobile podemos usar o path.
      if (kIsWeb) {
        final bytes = _arquivo!.bytes;
        if (bytes == null) {
          throw Exception('Não foi possível ler o conteúdo do PDF.');
        }
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: _arquivo!.name,
            contentType: MediaType('application', 'pdf'),
          ),
        );
      } else {
        final path = _arquivo!.path;
        if (path == null) {
          throw Exception('Caminho do arquivo não disponível.');
        }
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            path,
            contentType: MediaType('application', 'pdf'),
          ),
        );
      }
      request.fields['tipo'] = _tipo;
      if (_versao.trim().isNotEmpty) {
        request.fields['versao'] = _versao.trim();
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode != 200) {
        throw Exception('Erro ao analisar PDF (${response.statusCode})');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final clausulas =
          data['extraido']?['clausulas_count'] ??
          data['clausulas_gravadas'] ??
          0;

      // 2) Gera tarefas automaticamente (como no front web)
      await widget.apiClient.post(
        '/api/contratos/${_contratoSelecionado!.id}/gerar-tarefas/',
        body: {'substituir': true},
      );

      setState(() {
        _clausulasGravadas = clausulas as int? ?? 0;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao analisar PDF: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _enviando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: conversysAppBar(
        context,
        'Analisar contrato com IA',
        onNotificationsTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NotificacoesScreen(apiClient: widget.apiClient),
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
              child: Text('Nenhum contrato encontrado para análise.'),
            );
          }

          _contratoSelecionado ??= contratos.first;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<Contrato>(
                  initialValue: _contratoSelecionado,
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
                    setState(() {
                      _contratoSelecionado = value;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Contrato',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _selecionarPdf,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.04),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.picture_as_pdf_outlined, size: 28),
                        const SizedBox(height: 8),
                        Text(
                          _arquivo != null
                              ? _arquivo!.name
                              : 'Toque para selecionar o PDF do contrato',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _tipo,
                        items: const [
                          DropdownMenuItem(
                            value: 'CONTRATO_PRINCIPAL',
                            child: Text('Contrato Principal'),
                          ),
                          DropdownMenuItem(
                            value: 'PROPOSTA_TECNICA',
                            child: Text('Proposta Técnica'),
                          ),
                          DropdownMenuItem(
                            value: 'ADITIVO',
                            child: Text('Aditivo'),
                          ),
                          DropdownMenuItem(
                            value: 'ANEXO',
                            child: Text('Anexo'),
                          ),
                          DropdownMenuItem(
                            value: 'OUTRO',
                            child: Text('Outro'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _tipo = value;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Tipo do documento',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 100,
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Versão',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => _versao = value,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_clausulasGravadas != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Cláusulas extraídas: $_clausulasGravadas\n'
                      'As tarefas foram regeneradas com base nessas cláusulas.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _enviando || _arquivo == null
                        ? null
                        : () => _enviar(),
                    icon: _enviando
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.cloud_upload_outlined),
                    label: Text(
                      _enviando
                          ? 'Enviando e analisando...'
                          : 'Enviar e analisar',
                    ),
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
