import 'package:flutter/material.dart';

import '../models/cliente.dart';
import '../models/subcliente.dart';
import '../services/api_client.dart';
import '../services/clientes_service.dart';
import '../services/helpdesk_chamados_service.dart';

/// Bottom sheet **Nova Solicitação** alinhado ao `HelpdeskNewTicketModal.tsx` do portal ambiente-conversys.
class HelpdeskNovaSolicitacaoSheet extends StatefulWidget {
  final ApiClient apiClient;
  final VoidCallback onCreated;

  const HelpdeskNovaSolicitacaoSheet({
    super.key,
    required this.apiClient,
    required this.onCreated,
  });

  @override
  State<HelpdeskNovaSolicitacaoSheet> createState() =>
      _HelpdeskNovaSolicitacaoSheetState();
}

class _HelpdeskNovaSolicitacaoSheetState
    extends State<HelpdeskNovaSolicitacaoSheet> {
  late final HelpdeskChamadosService _hd;
  late final ClientesService _clientes;

  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _solicitanteNomeController = TextEditingController();

  Map<String, dynamic>? _me;
  bool _loadingBootstrap = true;

  List<Map<String, dynamic>> _gruposSolucao = const [];
  List<Map<String, dynamic>> _areas = const [];
  List<Map<String, dynamic>> _servicos = const [];
  List<Map<String, dynamic>> _tiposChamado = const [];
  List<Map<String, dynamic>> _impactos = const [];
  List<Cliente> _clientesCadastro = const [];
  List<Map<String, dynamic>> _contratosCliente = const [];
  List<Subcliente> _subclientesLista = const [];
  List<Map<String, dynamic>> _templates = const [];
  List<Map<String, dynamic>> _itensConfiguracao = const [];

  bool _loadingContratos = false;
  bool _loadingSubclientes = false;

  int? _grupoSolucaoId;
  String _prioridade = 'MEDIA';
  int? _categoriaId;
  int? _servicoId;
  int? _tipoChamadoId;
  int? _areaId;
  int? _impactoId;
  int? _clienteConversysId;
  int? _contratoId;
  int? _templateId;
  int? _itemConfiguracaoId;
  int? _subclienteIdSelecionado;

  bool _saving = false;

  bool get _isCliente {
    final t = (_me?['tipo_usuario'] as String?) ?? '';
    return t.toUpperCase() == 'CLIENTE';
  }

  @override
  void initState() {
    super.initState();
    _hd = HelpdeskChamadosService(widget.apiClient);
    _clientes = ClientesService(widget.apiClient);
    _bootstrap();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _solicitanteNomeController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() => _loadingBootstrap = true);
    try {
      final meFut = _hd.fetchAuthMe();
      final listsFut = Future.wait([
        _hd.listarGruposSolucao(),
        _hd.listarAreas(),
        _hd.listarServicos(),
        _hd.listarTiposChamado(),
        _hd.listarImpactos(),
        _hd.listarTemplates(),
        _hd.listarItensConfiguracao(),
      ]);
      _me = await meFut;
      final r = await listsFut;
      final clis = await _clientes.listarClientes();
      if (!mounted) return;
      setState(() {
        _gruposSolucao = r[0] as List<Map<String, dynamic>>;
        _areas = r[1] as List<Map<String, dynamic>>;
        _servicos = r[2] as List<Map<String, dynamic>>;
        _tiposChamado = r[3] as List<Map<String, dynamic>>;
        _impactos = r[4] as List<Map<String, dynamic>>;
        _templates = r[5] as List<Map<String, dynamic>>;
        _itensConfiguracao = r[6] as List<Map<String, dynamic>>;
        _clientesCadastro = clis;
      });
      if (_isCliente) {
        await _prepararContextoCliente();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar formulário: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingBootstrap = false);
    }
  }

  Future<void> _prepararContextoCliente() async {
    final mids = _me?['memberships'] as List<dynamic>?;
    if (mids == null || mids.isEmpty) return;
    final m0 = mids.first;
    if (m0 is! Map<String, dynamic>) return;
    final cid = m0['cliente_id'];
    if (cid is! int) return;
    try {
      final subs = await _clientes.listarSubclientes(cid);
      if (!mounted) return;
      setState(() {
        _subclientesLista = subs;
        if (subs.length == 1) {
          _subclienteIdSelecionado = subs.first.id;
        } else {
          final subM = m0['subcliente_id'];
          if (subM is int &&
              subs.any((s) => s.id == subM)) {
            _subclienteIdSelecionado = subM;
          }
        }
      });
    } catch (_) {}
  }

  Future<void> _onClienteConversysChanged(int? id) async {
    setState(() {
      _clienteConversysId = id;
      _contratoId = null;
      _subclienteIdSelecionado = null;
      _contratosCliente = const [];
      _subclientesLista = const [];
    });
    if (id == null) return;
    setState(() {
      _loadingContratos = true;
      _loadingSubclientes = true;
    });
    try {
      final contratos = await _hd.listarContratosHd(clienteConversysId: id);
      final subs = await _clientes.listarSubclientes(id);
      if (!mounted) return;
      int? subPick;
      if (subs.length == 1) {
        subPick = subs.first.id;
      } else if (subs.length > 1) {
        final mids = _me?['memberships'] as List<dynamic>?;
        if (mids != null) {
          for (final raw in mids) {
            if (raw is Map<String, dynamic> &&
                raw['cliente_id'] == id &&
                raw['subcliente_id'] != null) {
              final sid = raw['subcliente_id'] as int;
              if (subs.any((s) => s.id == sid)) {
                subPick = sid;
                break;
              }
            }
          }
        }
      }
      setState(() {
        _contratosCliente = contratos;
        _subclientesLista = subs;
        _subclienteIdSelecionado = subPick;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _contratosCliente = const [];
          _subclientesLista = const [];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingContratos = false;
          _loadingSubclientes = false;
        });
      }
    }
  }

  void _onAreaChanged(int? id) {
    setState(() {
      _areaId = id;
      _categoriaId = null;
      _servicoId = null;
    });
  }

  void _onTemplateChanged(int? id) {
    setState(() {
      _templateId = id;
      if (id == null) return;
      Map<String, dynamic>? tmpl;
      for (final t in _templates) {
        if (t['id'] == id) {
          tmpl = t;
          break;
        }
      }
      if (tmpl == null) return;
      final desc = tmpl['descricao'] as String?;
      if (desc != null && desc.isNotEmpty) {
        _descricaoController.text = desc;
      }
      final cat = tmpl['categoria'];
      if (cat is int) {
        _categoriaId = cat;
      } else if (cat is num) {
        _categoriaId = cat.toInt();
      }
      final srv = tmpl['servico'];
      if (srv is int) {
        _servicoId = srv;
      } else if (srv is num) {
        _servicoId = srv.toInt();
      }
      final tipo = tmpl['tipo'];
      if (tipo is int) {
        _tipoChamadoId = tipo;
      } else if (tipo is num) {
        _tipoChamadoId = tipo.toInt();
      }
    });
  }

  List<Map<String, dynamic>> get _servicosFiltrados {
    if (_categoriaId == null) return _servicos;
    return _servicos
        .where((s) => s['categoria'] == _categoriaId)
        .toList();
  }

  bool get _exigeEscolhaSubcliente =>
      !_isCliente &&
      _clienteConversysId != null &&
      _subclientesLista.length > 1;

  bool get _subclienteEscolhaOk =>
      !_exigeEscolhaSubcliente || _subclienteIdSelecionado != null;

  int? _subclienteParaApi() {
    if (_isCliente) {
      if (_subclientesLista.length == 1) {
        return _subclientesLista.first.id;
      }
      return _subclienteIdSelecionado;
    }
    if (_subclienteIdSelecionado != null) {
      return _subclienteIdSelecionado;
    }
    if (_subclientesLista.length == 1) {
      return _subclientesLista.first.id;
    }
    final mids = _me?['memberships'] as List<dynamic>?;
    final cid = _clienteConversysId;
    if (mids != null && cid != null) {
      for (final raw in mids) {
        if (raw is Map<String, dynamic> &&
            raw['cliente_id'] == cid &&
            raw['subcliente_id'] is int) {
          return raw['subcliente_id'] as int;
        }
      }
    }
    return null;
  }

  String? _subclienteNomeResumoCliente() {
    if (_subclientesLista.length == 1) {
      return _subclientesLista.first.nome;
    }
    final mids = _me?['memberships'] as List<dynamic>?;
    if (mids == null || mids.isEmpty) return null;
    final m0 = mids.first;
    if (m0 is Map<String, dynamic>) {
      final n = m0['subcliente_nome'] as String?;
      if (n != null && n.trim().isNotEmpty) return n.trim();
    }
    return null;
  }

  bool get _canSave {
    if (_tituloController.text.trim().isEmpty) return false;
    if (_servicoId == null || _tipoChamadoId == null) return false;
    if (_isCliente) return true;
    return _grupoSolucaoId != null &&
        _clienteConversysId != null &&
        _subclienteEscolhaOk &&
        _areaId != null;
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_canSave) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Preencha os campos obrigatórios (área, cliente, filial se houver, serviço, tipo, fila).',
          ),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _hd.criar(
        titulo: _tituloController.text,
        descricao: _descricaoController.text,
        grupoSolucaoId: _isCliente ? null : _grupoSolucaoId,
        prioridade: _prioridade,
        categoriaId: _categoriaId,
        servicoId: _servicoId,
        tipoChamadoId: _tipoChamadoId,
        areaId: _isCliente ? null : _areaId,
        impactoId: _impactoId,
        clienteConversysId: _isCliente ? null : _clienteConversysId,
        contratoId: _contratoId,
        templateId: _templateId,
        subclienteId: _subclienteParaApi(),
        solicitanteNome: _isCliente ? null : _solicitanteNomeController.text,
      );
      if (!mounted) return;
      widget.onCreated();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chamado criado com sucesso.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: Colors.black54,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    ),
                    child: Icon(
                      Icons.headset_mic,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nova Solicitação',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Preencha os detalhes e a equipe Help Desk vai ajudar!',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (_loadingBootstrap)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (!_isCliente)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.4)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.shield_outlined, size: 18, color: Colors.orange[800]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Modo Atendente / Backoffice — Preencha a classificação exata do problema para o cálculo e inicialização correta de SLAs.',
                          style: TextStyle(fontSize: 12, color: Colors.orange[900]),
                        ),
                      ),
                    ],
                  ),
                ),
              if (!_isCliente && _templates.isNotEmpty) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  value: _templateId,
                  decoration: const InputDecoration(
                    labelText: 'Usar template',
                    border: OutlineInputBorder(),
                    helperText: 'Auto-preenche descrição, categoria e serviço',
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('—'),
                    ),
                    ..._templates.map(
                      (t) => DropdownMenuItem<int?>(
                        value: t['id'] as int,
                        child: Text(
                          (t['nome'] ?? t['descricao'] ?? 'Template #${t['id']}')
                              .toString(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: _onTemplateChanged,
                ),
              ],
              const SizedBox(height: 16),
              _sectionTitle('1. Contexto & usuário'),
              if (!_isCliente) ...[
                DropdownButtonFormField<int>(
                  value: _areaId,
                  decoration: const InputDecoration(
                    labelText: 'Área de atendimento *',
                    border: OutlineInputBorder(),
                  ),
                  items: _areas
                      .map(
                        (a) => DropdownMenuItem<int>(
                          value: a['id'] as int,
                          child: Text(
                            (a['nome'] ?? a['descricao'] ?? 'Área').toString(),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _onAreaChanged,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _clienteConversysId,
                  decoration: const InputDecoration(
                    labelText: 'Cliente (empresa) *',
                    border: OutlineInputBorder(),
                  ),
                  items: _clientesCadastro
                      .map(
                        (c) => DropdownMenuItem<int>(
                          value: c.id,
                          child: Text(c.nome, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => _onClienteConversysChanged(v),
                ),
                if (_clienteConversysId != null) ...[
                  const SizedBox(height: 8),
                  if (_loadingSubclientes)
                    const LinearProgressIndicator(minHeight: 2)
                  else if (_subclientesLista.length > 1)
                    DropdownButtonFormField<int>(
                      value: _subclienteIdSelecionado,
                      decoration: const InputDecoration(
                        labelText: 'Subcliente (filial) *',
                        border: OutlineInputBorder(),
                      ),
                      items: _subclientesLista
                          .map(
                            (s) => DropdownMenuItem<int>(
                              value: s.id,
                              child: Text(s.nome, overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _subclienteIdSelecionado = v),
                    )
                  else
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Subcliente (filial)',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      subtitle: Text(
                        _subclientesLista.isEmpty
                            ? '— Matriz ou sem filial cadastrada'
                            : _subclientesLista.first.nome,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _solicitanteNomeController,
                  decoration: const InputDecoration(
                    labelText: 'Solicitante final (nome)',
                    hintText: 'Quem relatou? (ex.: João da Silva)',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_clienteConversysId != null) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    value: _contratoId,
                    decoration: InputDecoration(
                      labelText: 'Contrato vinculado',
                      border: const OutlineInputBorder(),
                      suffix: _loadingContratos
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('—'),
                      ),
                      ..._contratosCliente.map(
                        (c) => DropdownMenuItem<int?>(
                          value: c['id'] as int,
                          child: Text(
                            (c['numero']?.toString().isNotEmpty ?? false)
                                ? c['numero'].toString()
                                : (c['descricao'] ?? 'Contrato #${c['id']}')
                                    .toString(),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _contratoId = v),
                  ),
                ],
              ] else ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey.shade300,
                    child: const Icon(Icons.person, color: Colors.white70),
                  ),
                  title: const Text(
                    'Solicitante',
                    style: TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                  subtitle: const Text(
                    'Você (usuário logado)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.place_outlined, color: Colors.blue[700]),
                  title: const Text(
                    'Subcliente (filial)',
                    style: TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                  subtitle: Text(
                    _subclienteNomeResumoCliente() ??
                        '— Matriz ou não vinculado no seu perfil',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _sectionTitle('2. Classificação do chamado'),
              DropdownButtonFormField<int>(
                value: _servicoId,
                decoration: const InputDecoration(
                  labelText: 'Serviço afetado *',
                  border: OutlineInputBorder(),
                ),
                items: _servicosFiltrados
                    .map(
                      (s) => DropdownMenuItem<int>(
                        value: s['id'] as int,
                        child: Text(
                          (s['nome'] ?? s['descricao'] ?? 'Serviço').toString(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _servicoId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _tipoChamadoId,
                decoration: const InputDecoration(
                  labelText: 'Tipo de solicitação *',
                  border: OutlineInputBorder(),
                ),
                items: _tiposChamado
                    .map(
                      (t) => DropdownMenuItem<int>(
                        value: t['id'] as int,
                        child: Text(
                          (t['nome'] ?? t['descricao'] ?? 'Tipo').toString(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _tipoChamadoId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                value: _impactoId,
                decoration: const InputDecoration(
                  labelText: 'Impacto',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('—'),
                  ),
                  ..._impactos.map(
                    (i) => DropdownMenuItem<int?>(
                      value: i['id'] as int,
                      child: Text(
                        (i['nome'] ?? i['descricao'] ?? 'Impacto').toString(),
                      ),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _impactoId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _prioridade,
                decoration: const InputDecoration(
                  labelText: 'Prioridade estimada *',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'CRITICA', child: Text('Crítica')),
                  DropdownMenuItem(value: 'ALTA', child: Text('Alta')),
                  DropdownMenuItem(value: 'MEDIA', child: Text('Média')),
                  DropdownMenuItem(value: 'BAIXA', child: Text('Baixa')),
                ],
                onChanged: (v) =>
                    setState(() => _prioridade = v ?? 'MEDIA'),
              ),
              const SizedBox(height: 16),
              _sectionTitle('3. Ativos & equipamentos (opcional)'),
              DropdownButtonFormField<int?>(
                value: _itemConfiguracaoId,
                decoration: const InputDecoration(
                  labelText: 'Equipamento associado',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('—'),
                  ),
                  ..._itensConfiguracao.map(
                    (ci) => DropdownMenuItem<int?>(
                      value: ci['id'] as int,
                      child: Text(
                        (ci['nome'] ?? ci['descricao'] ?? 'Item').toString(),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _itemConfiguracaoId = v),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Se o equipamento não estiver na lista, informe modelo e número de série na descrição.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _sectionTitle('4. Detalhes do chamado'),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: Colors.grey.shade50,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _tituloController,
                        decoration: const InputDecoration(
                          labelText: 'Resumo / título *',
                          hintText:
                              'Ex.: Impressora não liga, Wi‑Fi instável…',
                          border: InputBorder.none,
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Informe um título' : null,
                      ),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descricaoController,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          hintText:
                              'Descreva o cenário, erros, série do equipamento (se não listado), etc.',
                          border: InputBorder.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!_isCliente) ...[
                const SizedBox(height: 16),
                _sectionTitle('Avançado: encaminhamento (backoffice)'),
                DropdownButtonFormField<int>(
                  value: _grupoSolucaoId,
                  decoration: const InputDecoration(
                    labelText: 'Fila / grupo solucionador *',
                    border: OutlineInputBorder(),
                  ),
                  items: _gruposSolucao
                      .map(
                        (g) => DropdownMenuItem<int>(
                          value: g['id'] as int,
                          child: Text(
                            (g['nome'] ?? 'Grupo').toString(),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _grupoSolucaoId = v),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: (_saving || !_canSave) ? null : _salvar,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Abrir solicitação'),
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
