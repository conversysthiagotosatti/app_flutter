import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/helpdesk_chamados_service.dart';
import '../widgets/conversys_app_bar.dart';
import 'notificacoes_screen.dart';
import 'helpdesk_chamado_detalhe_screen.dart';

class HelpdeskChamadosScreen extends StatefulWidget {
  final ApiClient apiClient;

  const HelpdeskChamadosScreen({
    super.key,
    required this.apiClient,
  });

  @override
  State<HelpdeskChamadosScreen> createState() =>
      _HelpdeskChamadosScreenState();
}

class _HelpdeskChamadosScreenState extends State<HelpdeskChamadosScreen> {
  late final HelpdeskChamadosService _service;
  late Future<List<Chamado>> _future;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _service = HelpdeskChamadosService(widget.apiClient);
    _future = _service.listar();
  }

  Future<void> _recarregar() async {
    setState(() {
      _future = _service.listar(
        search: _search.isNotEmpty ? _search : null,
      );
    });
  }

  void _abrirNovoChamado() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: _NovoChamadoSheet(
          apiClient: widget.apiClient,
          onCreated: () {
            Navigator.of(ctx).pop();
            _recarregar();
          },
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    final s = status.toUpperCase();
    if (s == 'ABERTO') return Colors.blue;
    if (s == 'EM_ATENDIMENTO') return Colors.orange;
    if (s == 'AGUARDANDO') return Colors.amber;
    if (s == 'RESOLVIDO' || s == 'FECHADO') {
      return Colors.green;
    }
    if (s == 'CANCELADO') return Colors.red;
    return Colors.grey;
  }

  Color _prioridadeColor(String prioridade) {
    final p = prioridade.toUpperCase();
    if (p == 'CRITICA') return Colors.red;
    if (p == 'ALTA') return Colors.orange;
    if (p == 'MEDIA') return Colors.blue;
    if (p == 'BAIXA') return Colors.grey;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: conversysAppBar(
        'Helpdesk · Chamados',
        onNotificationsTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  NotificacoesScreen(apiClient: widget.apiClient),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirNovoChamado,
        icon: const Icon(Icons.add),
        label: const Text('Novo chamado'),
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Buscar por título ou ID...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {
                  _search = value;
                });
                _recarregar();
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _recarregar,
              child: FutureBuilder<List<Chamado>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (snapshot.hasError) {
                    return ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Erro ao carregar chamados: ${snapshot.error}',
                          ),
                        ),
                      ],
                    );
                  }
                  final chamados = snapshot.data ?? const [];
                  if (chamados.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 80),
                        Center(
                          child: Text(
                            'Nenhum chamado encontrado.',
                          ),
                        ),
                      ],
                    );
                  }
                  return ListView.separated(
                    itemCount: chamados.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final c = chamados[index];
                      final statusColor = _statusColor(c.status);
                      final prioridadeColor =
                          _prioridadeColor(c.prioridade);

                      final solicitanteNome =
                          (c.solicitanteDetalhes?['first_name'] ??
                                  '') +
                              ' ' +
                              (c.solicitanteDetalhes?['last_name'] ??
                                  '');

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: statusColor.withOpacity(0.1),
                          foregroundColor: statusColor,
                          child: Text(
                            c.id.toString(),
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                        title: Text(
                          c.titulo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius:
                                        BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    c.status,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: statusColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: prioridadeColor
                                        .withOpacity(0.1),
                                    borderRadius:
                                        BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    c.prioridade,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: prioridadeColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (solicitanteNome.trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  solicitanteNome,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  HelpdeskChamadoDetalheScreen(
                                apiClient: widget.apiClient,
                                chamado: c,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NovoChamadoSheet extends StatefulWidget {
  final ApiClient apiClient;
  final VoidCallback onCreated;

  const _NovoChamadoSheet({
    required this.apiClient,
    required this.onCreated,
  });

  @override
  State<_NovoChamadoSheet> createState() => _NovoChamadoSheetState();
}

class _NovoChamadoSheetState extends State<_NovoChamadoSheet> {
  late final HelpdeskChamadosService _service;
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _solicitanteNomeController = TextEditingController();

  List<Map<String, dynamic>> _gruposSolucao = const [];
  List<Map<String, dynamic>> _categorias = const [];
  List<Map<String, dynamic>> _servicos = const [];
  List<Map<String, dynamic>> _tiposChamado = const [];
  List<Map<String, dynamic>> _areas = const [];
  List<Map<String, dynamic>> _impactos = const [];
  List<Map<String, dynamic>> _clientes = const [];
  List<Map<String, dynamic>> _contratos = const [];
  List<Map<String, dynamic>> _templates = const [];
  List<Map<String, dynamic>> _itensConfiguracao = const [];

  int? _grupoSolucaoId;
  String _prioridade = 'MEDIA';
  int? _categoriaId;
  int? _servicoId;
  int? _tipoChamadoId;
  int? _areaId;
  int? _impactoId;
  int? _clienteId;
  int? _contratoId;
  int? _templateId;
  int? _itemConfiguracaoId;

  bool _carregandoOpcoes = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _service = HelpdeskChamadosService(widget.apiClient);
    _carregarOpcoes();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _solicitanteNomeController.dispose();
    super.dispose();
  }

  Future<void> _carregarOpcoes() async {
    setState(() {
      _carregandoOpcoes = true;
    });
    try {
      final resultados = await Future.wait([
        _service.listarGruposSolucao(),
        _service.listarCategorias(),
        _service.listarServicos(),
        _service.listarTiposChamado(),
        _service.listarAreas(),
        _service.listarImpactos(),
        _service.listarClientesHd(),
        _service.listarContratosHd(),
        _service.listarTemplates(),
        _service.listarItensConfiguracao(),
      ]);
      if (!mounted) return;
      setState(() {
        _gruposSolucao = resultados[0];
        _categorias = resultados[1];
        _servicos = resultados[2];
        _tiposChamado = resultados[3];
        _areas = resultados[4];
        _impactos = resultados[5];
        _clientes = resultados[6];
        _contratos = resultados[7];
        _templates = resultados[8];
        _itensConfiguracao = resultados[9];
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Erro ao carregar opções do helpdesk.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _carregandoOpcoes = false;
        });
      }
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
    });
    try {
      await _service.criar(
        titulo: _tituloController.text,
        descricao: _descricaoController.text,
        grupoSolucaoId: _grupoSolucaoId,
        prioridade: _prioridade,
        categoriaId: _categoriaId,
        servicoId: _servicoId,
        tipoChamadoId: _tipoChamadoId,
        areaId: _areaId,
        impactoId: _impactoId,
        clienteId: _clienteId,
        contratoId: _contratoId,
        templateId: _templateId,
        itemConfiguracaoId: _itemConfiguracaoId,
        solicitanteNome: _solicitanteNomeController.text,
      );
      if (!mounted) return;
      widget.onCreated();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chamado criado com sucesso.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao criar chamado: $e'),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho "Nova Solicitação"
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color:
                          Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    ),
                    child: Icon(
                      Icons.headset_mic,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nova Solicitação',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Complete os detalhes para processamento imediato',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (_carregandoOpcoes)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Faixa "Modo Atendente"
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 16,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Modo Atendente — Preencha a classificação para o roteamento e SLA corretos.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.orange[800],
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Card de título / descrição
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: Colors.grey.shade50,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _tituloController,
                        decoration: const InputDecoration(
                          labelText: 'Título ou Resumo da Ocorrência',
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(fontSize: 16),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe um título';
                          }
                          return null;
                        },
                      ),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descricaoController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText:
                              'Descreva detalhadamente o problema ou solicitação...',
                          border: InputBorder.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Duas colunas: Classificação / Contexto do solicitante
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 520;
                  final fields = <Widget>[
                    // Classificação
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Classificação',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            value: _grupoSolucaoId,
                            decoration: const InputDecoration(
                              labelText: 'Grupo / Fila',
                              border: OutlineInputBorder(),
                            ),
                            items: _gruposSolucao
                                .map(
                                  (g) => DropdownMenuItem<int>(
                                    value: g['id'] as int,
                                    child: Text(
                                      g['nome']?.toString() ?? 'Grupo',
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _grupoSolucaoId = value;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _prioridade,
                            decoration: const InputDecoration(
                              labelText: 'Prioridade',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'CRITICA',
                                child: Text('Crítica'),
                              ),
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
                              setState(() {
                                _prioridade = value ?? 'MEDIA';
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            value: _categoriaId,
                            decoration: const InputDecoration(
                              labelText: 'Categoria',
                              border: OutlineInputBorder(),
                            ),
                            items: _categorias
                                .map(
                                  (c) => DropdownMenuItem<int>(
                                    value: c['id'] as int,
                                    child: Text(
                                      c['nome']?.toString() ?? 'Categoria',
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _categoriaId = value;
                                _servicoId = null;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            value: _servicoId,
                            decoration: const InputDecoration(
                              labelText: 'Serviço',
                              border: OutlineInputBorder(),
                            ),
                            items: _servicos
                                .where((s) =>
                                    _categoriaId == null ||
                                    s['categoria'] == _categoriaId)
                                .map(
                                  (s) => DropdownMenuItem<int>(
                                    value: s['id'] as int,
                                    child: Text(
                                      s['nome']?.toString() ?? 'Serviço',
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _servicoId = value;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            value: _tipoChamadoId,
                            decoration: const InputDecoration(
                              labelText: 'Tipo de chamado',
                              border: OutlineInputBorder(),
                            ),
                            items: _tiposChamado
                                .map(
                                  (t) => DropdownMenuItem<int>(
                                    value: t['id'] as int,
                                    child: Text(
                                      t['nome']?.toString() ?? 'Tipo',
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _tipoChamadoId = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Contexto do solicitante
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Contexto do solicitante',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            value: _clienteId,
                            decoration: const InputDecoration(
                              labelText: 'Cliente',
                              border: OutlineInputBorder(),
                            ),
                            items: _clientes
                                .map(
                                  (c) => DropdownMenuItem<int>(
                                    value: c['id'] as int,
                                    child: Text(
                                      c['nome']?.toString() ?? 'Cliente',
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _clienteId = value;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            value: _contratoId,
                            decoration: const InputDecoration(
                              labelText: 'Contrato',
                              border: OutlineInputBorder(),
                            ),
                            items: _contratos
                                .map(
                                  (c) => DropdownMenuItem<int>(
                                    value: c['id'] as int,
                                    child: Text(
                                      (c['numero']
                                                      ?.toString()
                                                      ?.isNotEmpty ??
                                              false)
                                          ? c['numero'].toString()
                                          : (c['descricao']?.toString() ??
                                              'Contrato'),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _contratoId = value;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _solicitanteNomeController,
                            decoration: const InputDecoration(
                              labelText: 'Solicitante (contato)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            value: _areaId,
                            decoration: const InputDecoration(
                              labelText: 'Área',
                              border: OutlineInputBorder(),
                            ),
                            items: _areas
                                .map(
                                  (a) => DropdownMenuItem<int>(
                                    value: a['id'] as int,
                                    child: Text(
                                      a['nome']?.toString() ?? 'Área',
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _areaId = value;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            value: _impactoId,
                            decoration: const InputDecoration(
                              labelText: 'Impacto',
                              border: OutlineInputBorder(),
                            ),
                            items: _impactos
                                .map(
                                  (i) => DropdownMenuItem<int>(
                                    value: i['id'] as int,
                                    child: Text(
                                      i['nome']?.toString() ?? 'Impacto',
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _impactoId = value;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            value: _itemConfiguracaoId,
                            decoration: const InputDecoration(
                              labelText: 'Item de configuração',
                              border: OutlineInputBorder(),
                            ),
                            items: _itensConfiguracao
                                .map(
                                  (ci) => DropdownMenuItem<int>(
                                    value: ci['id'] as int,
                                    child: Text(
                                      ci['nome']?.toString() ?? 'Item',
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _itemConfiguracaoId = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ];

                  if (isWide) {
                    return Row(children: fields);
                  }
                  return Column(
                    children: [
                      fields[0],
                      const SizedBox(height: 16),
                      fields[2],
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () {
                            Navigator.of(context).pop();
                          },
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _saving ? null : _salvar,
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Criar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

