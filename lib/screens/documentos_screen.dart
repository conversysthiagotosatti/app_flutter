import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/contrato.dart';
import '../models/contrato_arquivo.dart';
import '../services/api_client.dart';
import '../services/contratos_service.dart';
import '../services/contrato_arquivos_service.dart';
import '../widgets/conversys_app_bar.dart';
import 'notificacoes_screen.dart';

class DocumentosScreen extends StatefulWidget {
  final ApiClient apiClient;

  const DocumentosScreen({super.key, required this.apiClient});

  @override
  State<DocumentosScreen> createState() => _DocumentosScreenState();
}

class _DocumentosScreenState extends State<DocumentosScreen> {
  late final ContratosService _contratosService;
  late final ContratoArquivosService _arquivosService;

  Future<List<Contrato>>? _contratosFuture;
  Future<List<ContratoArquivo>>? _arquivosFuture;

  Contrato? _contratoSelecionado;
  bool _gerandoPdf = false;

  static const _tipoLabels = {
    'CONTRATO_PRINCIPAL': 'Contrato Principal',
    'PROPOSTA_TECNICA': 'Proposta Técnica',
    'ADITIVO': 'Aditivo',
    'ANEXO': 'Anexo',
    'OUTRO': 'Outro',
  };

  @override
  void initState() {
    super.initState();
    _contratosService = ContratosService(widget.apiClient);
    _arquivosService = ContratoArquivosService(widget.apiClient);
    _contratosFuture = _contratosService.listarContratos();
  }

  String _formatBytes(int? bytes) {
    if (bytes == null || bytes <= 0) return '—';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
  }

  String _buildMediaUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final base = ApiClient.baseUrl;
    if (path.startsWith('/')) {
      return '$base$path';
    }
    return '$base/$path';
  }

  Future<void> _carregarArquivos(Contrato contrato) async {
    setState(() {
      _contratoSelecionado = contrato;
      _arquivosFuture = _arquivosService.listar(contrato.id);
    });
  }

  Future<void> _abrirUrl(String? path) async {
    final url = _buildMediaUrl(path);
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o documento.')),
      );
    }
  }

  Future<void> _gerarPdf() async {
    final contrato = _contratoSelecionado;
    if (contrato == null) return;

    setState(() => _gerandoPdf = true);
    try {
      await _arquivosService.gerarPdfVersao(contrato.id);
      await _carregarArquivos(contrato);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao gerar PDF: $e')));
    } finally {
      if (mounted) {
        setState(() => _gerandoPdf = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: conversysAppBar(
        context,
        'Documentos do contrato',
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
            return const Center(child: Text('Nenhum contrato encontrado.'));
          }

          _contratoSelecionado ??= contratos.first;
          _arquivosFuture ??= _arquivosService.listar(_contratoSelecionado!.id);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<Contrato>(
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
                          if (value == null) return;
                          _carregarArquivos(value);
                        },
                        decoration: const InputDecoration(
                          labelText: 'Contrato',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _gerandoPdf ? null : () => _gerarPdf(),
                      icon: _gerandoPdf
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
                          : const Icon(Icons.picture_as_pdf_outlined),
                      label: Text(
                        _gerandoPdf ? 'Gerando...' : 'Gerar PDF (nova versão)',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: FutureBuilder<List<ContratoArquivo>>(
                    future: _arquivosFuture,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snap.hasError) {
                        return Center(
                          child: Text(
                            'Erro ao carregar documentos: ${snap.error}',
                          ),
                        );
                      }

                      final arquivos = snap.data ?? [];
                      if (arquivos.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.insert_drive_file_outlined,
                                size: 40,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text('Nenhum arquivo enviado.'),
                              SizedBox(height: 4),
                              Text(
                                'Use "Analisar com IA" para enviar um documento.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: arquivos.length,
                        itemBuilder: (context, index) {
                          final arq = arquivos[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.redAccent,
                                  child: Icon(
                                    Icons.picture_as_pdf,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  arq.nomeOriginal,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        Chip(
                                          label: Text(
                                            _tipoLabels[arq.tipo] ?? arq.tipo,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        Text(
                                          'v${arq.versao}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        if (arq.tamanhoBytes != null)
                                          Text(
                                            _formatBytes(arq.tamanhoBytes),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        if (arq.extraidoEm != null)
                                          Text(
                                            'Extraído em '
                                            '${arq.extraidoEm!.day.toString().padLeft(2, '0')}/'
                                            '${arq.extraidoEm!.month.toString().padLeft(2, '0')}/'
                                            '${arq.extraidoEm!.year}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (arq.mimeType != null)
                                      Text(
                                        arq.mimeType!,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    if (arq.sha256 != null)
                                      Text(
                                        'SHA256: ${arq.sha256}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.download),
                                  onPressed: () => _abrirUrl(arq.url),
                                  tooltip: 'Abrir / baixar',
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
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
