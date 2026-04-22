import 'package:flutter/material.dart';

import '../models/cliente.dart';
import '../models/proposta_resumo.dart';
import '../services/clientes_service.dart';
import '../services/api_client.dart';
import '../services/propostas_service.dart';
import '../widgets/conversys_app_bar.dart';
import 'notificacoes_screen.dart';
import 'proposta_detalhe_screen.dart';

class PropostasListaScreen extends StatefulWidget {
  final ApiClient apiClient;

  const PropostasListaScreen({super.key, required this.apiClient});

  @override
  State<PropostasListaScreen> createState() => _PropostasListaScreenState();
}

class _PropostasListaScreenState extends State<PropostasListaScreen> {
  late final PropostasService _propostasService;
  late final ClientesService _clientesService;

  bool _loading = true;
  String? _error;
  List<PropostaResumo> _propostas = const [];

  @override
  void initState() {
    super.initState();
    _propostasService = PropostasService(widget.apiClient);
    _clientesService = ClientesService(widget.apiClient);
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final lista = await _propostasService.listarResumo();
      if (!mounted) return;
      setState(() {
        _propostas = lista;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _abrirNovaProposta() async {
    final clientsFuture = _clientesService.listarClientes();
    final tituloController = TextEditingController();
    final descricaoController = TextEditingController();
    final validadeController = TextEditingController();
    String tipoProposta = 'comercial';
    int? selectedClienteId;

    // ignore: use_build_context_synchronously
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (context, setStateModal) {
              return FutureBuilder<List<Cliente>>(
                future: clientsFuture,
                builder: (context, snap) {
                  final clients = snap.data ?? const <Cliente>[];
                  final isBusy =
                      snap.connectionState == ConnectionState.waiting;

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.add_circle_outline, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'Incluir Proposta',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (isBusy)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else ...[
                          DropdownButtonFormField<int>(
                            initialValue: selectedClienteId,
                            dropdownColor: const Color(0xFF0B1220),
                            decoration: const InputDecoration(
                              labelText: 'Cliente',
                              border: OutlineInputBorder(),
                            ),
                            items: clients
                                .map(
                                  (c) => DropdownMenuItem<int>(
                                    value: c.id,
                                    child: Text(
                                      c.nome,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setStateModal(() => selectedClienteId = value);
                            },
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: tituloController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Título',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: descricaoController,
                            style: const TextStyle(color: Colors.white),
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Descrição',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: validadeController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Validade (YYYY-MM-DD)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: tipoProposta,
                            dropdownColor: const Color(0xFF0B1220),
                            decoration: const InputDecoration(
                              labelText: 'Tipo',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'comercial',
                                child: Text('Comercial'),
                              ),
                              DropdownMenuItem(
                                value: 'tecnica',
                                child: Text('Técnica'),
                              ),
                              DropdownMenuItem(
                                value: 'contrato',
                                child: Text('Contrato'),
                              ),
                              DropdownMenuItem(
                                value: 'memoria_calculo',
                                child: Text('Memória de Cálculo'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setStateModal(() => tipoProposta = value);
                            },
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () async {
                                final titulo = tituloController.text.trim();
                                final descricao = descricaoController.text
                                    .trim();
                                if (selectedClienteId == null) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                      content: Text('Selecione um cliente.'),
                                    ),
                                  );
                                  return;
                                }
                                if (titulo.isEmpty) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                      content: Text('Informe o título.'),
                                    ),
                                  );
                                  return;
                                }

                                Navigator.of(ctx).pop();
                                try {
                                  final created = await _propostasService
                                      .criarProposta(
                                        clienteId: selectedClienteId!,
                                        titulo: titulo,
                                        descricao: descricao,
                                        dataValidade:
                                            validadeController.text
                                                .trim()
                                                .isEmpty
                                            ? null
                                            : validadeController.text.trim(),
                                        tipoProposta: tipoProposta,
                                      );
                                  if (!mounted) return;
                                  await _carregar();
                                  if (!mounted) return;
                                  // Abre detalhe da proposta criada.
                                  // ignore: use_build_context_synchronously
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => PropostaDetalheScreen(
                                        apiClient: widget.apiClient,
                                        propostaId: created.id,
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Erro ao criar proposta: $e',
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.save_outlined),
                              label: const Text('Criar'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF020617);

    return Scaffold(
      appBar: conversysAppBar(
        context,
        'Propostas',
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
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Text(
                  'Erro ao carregar propostas: $_error',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              )
            : _propostas.isEmpty
            ? const Center(child: Text('Nenhuma proposta encontrada.'))
            : ListView.separated(
                itemCount: _propostas.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final p = _propostas[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PropostaDetalheScreen(
                            apiClient: widget.apiClient,
                            propostaId: p.id,
                          ),
                        ),
                      );
                      // Ao voltar, recarrega (mesmo padrão do Kanban).
                      await _carregar();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B1220),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF1E293B)),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.titulo,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Cliente: ${p.clienteNome ?? p.cliente}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Código: ${p.codigoInterno ?? "—"}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Valor: ${p.valorTotal}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  p.status,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (p.dataValidade != null &&
                              p.dataValidade!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Validade: ${p.dataValidade}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirNovaProposta,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
