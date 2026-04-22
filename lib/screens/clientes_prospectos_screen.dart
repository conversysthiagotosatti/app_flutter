import 'package:flutter/material.dart';

import '../models/cliente.dart';
import '../models/subcliente.dart';
import '../services/api_client.dart';
import '../services/clientes_service.dart';
import '../widgets/conversys_app_bar.dart';
import 'notificacoes_screen.dart';

class ClientesProspectosScreen extends StatefulWidget {
  final ApiClient apiClient;

  const ClientesProspectosScreen({super.key, required this.apiClient});

  @override
  State<ClientesProspectosScreen> createState() =>
      _ClientesProspectosScreenState();
}

class _ClientesProspectosScreenState extends State<ClientesProspectosScreen> {
  late final ClientesService _service;

  bool _loading = true;
  String? _error;
  List<Cliente> _clientes = const [];

  @override
  void initState() {
    super.initState();
    _service = ClientesService(widget.apiClient);
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.listarClientes();
      if (!mounted) return;
      setState(() => _clientes = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _buildMediaUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final base = ApiClient.baseUrl;
    if (path.startsWith('/')) return '$base$path';
    return '$base/$path';
  }

  Future<void> _abrirModal({required bool isEdit, Cliente? cliente}) async {
    final nomeController = TextEditingController(text: cliente?.nome ?? '');
    final documentoController = TextEditingController(
      text: cliente?.documento ?? '',
    );
    final emailController = TextEditingController(text: cliente?.email ?? '');
    final telefoneController = TextEditingController(
      text: cliente?.telefone ?? '',
    );

    bool isProspecto = cliente?.isProspecto ?? true;
    bool contaAtiva = cliente?.ativo ?? true;

    final nomeInicial = nomeController.text.trim();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              backgroundColor: const Color(0xFF020617),
              title: Text(
                isEdit
                    ? 'Editar Cliente / Prospecto'
                    : 'Novo Cliente / Prospecto',
                style: const TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 320,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nomeController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Nome',
                          labelStyle: TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: documentoController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Documento (CNPJ/CPF)',
                          labelStyle: TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: telefoneController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Telefone',
                          labelStyle: TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: emailController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          labelStyle: TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        value: isProspecto,
                        onChanged: (v) {
                          if (v == null) return;
                          setStateModal(() => isProspecto = v);
                        },
                        title: const Text(
                          'Marcar como prospecto (ainda sem compras)',
                          style: TextStyle(color: Colors.white),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: Colors.blue,
                        checkColor: Colors.black,
                      ),
                      if (isEdit) ...[
                        const SizedBox(height: 4),
                        SwitchListTile(
                          value: contaAtiva,
                          onChanged: (v) => setStateModal(() => contaAtiva = v),
                          title: const Text(
                            'Conta ativa no sistema',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: const Text(
                            'Desative para ocultar o cliente sem apagar o cadastro.',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    Future<void> handleSave() async {
                      final nome = nomeController.text.trim();
                      if (nome.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Informe o nome.')),
                        );
                        return;
                      }
                      try {
                        if (isEdit && cliente != null) {
                          await _service.atualizarCliente(
                            id: cliente.id,
                            nome: nome,
                            documento: documentoController.text.trim().isEmpty
                                ? null
                                : documentoController.text.trim(),
                            email: emailController.text.trim().isEmpty
                                ? null
                                : emailController.text.trim(),
                            telefone: telefoneController.text.trim().isEmpty
                                ? null
                                : telefoneController.text.trim(),
                            isProspecto: isProspecto,
                            ativo: contaAtiva,
                          );
                        } else {
                          await _service.criarCliente(
                            nome: nome,
                            documento: documentoController.text.trim().isEmpty
                                ? null
                                : documentoController.text.trim(),
                            email: emailController.text.trim().isEmpty
                                ? null
                                : emailController.text.trim(),
                            telefone: telefoneController.text.trim().isEmpty
                                ? null
                                : telefoneController.text.trim(),
                            isProspecto: isProspecto,
                          );
                        }
                        if (!context.mounted) return;
                        Navigator.of(ctx).pop();
                        await _carregar();
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro ao salvar: $e')),
                        );
                      }
                    }

                    handleSave();
                  },
                  child: Text(
                    isEdit && nomeInicial.isNotEmpty
                        ? 'Salvar alterações'
                        : 'Criar cliente',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _abrirPainelSubclientes(Cliente cliente) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _SubclientesDialog(
        service: _service,
        cliente: cliente,
        onListaClienteChanged: _carregar,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF020617);

    return Scaffold(
      appBar: conversysAppBar(
        context,
        'Clientes / Prospectos',
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Base de clientes e prospects para propostas',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _loading
                      ? null
                      : () {
                          _abrirModal(isEdit: false, cliente: null);
                        },
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Novo Cliente / Prospecto'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Text(
                        'Erro ao carregar: $_error',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    )
                  : _clientes.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhum cliente cadastrado ainda. Toque em "Novo Cliente / Prospecto" para começar.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _clientes.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: Colors.white12),
                      itemBuilder: (context, index) {
                        final c = _clientes[index];
                        final isProspecto = c.isProspecto;
                        return ListTile(
                          onTap: () {
                            _abrirModal(isEdit: true, cliente: c);
                          },
                          leading: CircleAvatar(
                            backgroundColor: Colors.white.withOpacity(0.06),
                            child: ClipOval(
                              child:
                                  c.logotipo != null && c.logotipo!.isNotEmpty
                                  ? Image.network(
                                      _buildMediaUrl(c.logotipo),
                                      width: 36,
                                      height: 36,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Text(
                                              c.nome.isNotEmpty
                                                  ? c.nome[0].toUpperCase()
                                                  : '?',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            );
                                          },
                                    )
                                  : Text(
                                      c.nome.isNotEmpty
                                          ? c.nome[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                          title: Text(
                            c.nome,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                [
                                  if (c.telefone != null &&
                                      c.telefone!.isNotEmpty)
                                    c.telefone!,
                                  if (c.email != null && c.email!.isNotEmpty)
                                    c.email!,
                                  if (c.documento != null &&
                                      c.documento!.isNotEmpty)
                                    c.documento!,
                                ].join(' • '),
                                style: const TextStyle(color: Colors.white70),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (!c.ativo)
                                const Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Conta inativa',
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Subclientes (filiais)',
                                icon: const Icon(
                                  Icons.corporate_fare,
                                  color: Colors.white54,
                                ),
                                onPressed: () => _abrirPainelSubclientes(c),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isProspecto
                                      ? Colors.amberAccent.withOpacity(0.15)
                                      : Colors.greenAccent.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: isProspecto
                                        ? Colors.amberAccent.withOpacity(0.4)
                                        : Colors.greenAccent.withOpacity(0.4),
                                  ),
                                ),
                                child: Text(
                                  isProspecto ? 'Prospecto' : 'Cliente',
                                  style: TextStyle(
                                    color: isProspecto
                                        ? Colors.amberAccent
                                        : Colors.greenAccent,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            // Placeholder para manter o layout confortável
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SubclientesDialog extends StatefulWidget {
  final ClientesService service;
  final Cliente cliente;
  final Future<void> Function() onListaClienteChanged;

  const _SubclientesDialog({
    required this.service,
    required this.cliente,
    required this.onListaClienteChanged,
  });

  @override
  State<_SubclientesDialog> createState() => _SubclientesDialogState();
}

class _SubclientesDialogState extends State<_SubclientesDialog> {
  late Future<List<Subcliente>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Subcliente>> _load() =>
      widget.service.listarSubclientes(widget.cliente.id);

  void _reload() {
    setState(() => _future = _load());
  }

  Future<void> _modalSubcliente({Subcliente? existente}) async {
    final nome = TextEditingController(text: existente?.nome ?? '');
    final cnpj = TextEditingController(text: existente?.cnpj ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF020617),
        title: Text(
          existente == null ? 'Novo subcliente' : 'Editar subcliente',
          style: const TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nome,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cnpj,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'CNPJ',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final n = nome.text.trim();
    if (n.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o nome do subcliente.')),
      );
      return;
    }
    try {
      if (existente == null) {
        await widget.service.criarSubcliente(
          widget.cliente.id,
          nome: n,
          cnpj: cnpj.text.trim(),
        );
      } else {
        await widget.service.atualizarSubcliente(
          widget.cliente.id,
          existente.id,
          nome: n,
          cnpj: cnpj.text.trim(),
        );
      }
      _reload();
      await widget.onListaClienteChanged();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF020617),
      title: Text(
        'Subclientes — ${widget.cliente.nome}',
        style: const TextStyle(color: Colors.white),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 360,
        child: FutureBuilder<List<Subcliente>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Text(
                'Erro: ${snap.error}',
                style: const TextStyle(color: Colors.redAccent),
              );
            }
            final list = snap.data ?? const <Subcliente>[];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  onPressed: () => _modalSubcliente(),
                  icon: const Icon(Icons.add),
                  label: const Text('Novo subcliente'),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: list.isEmpty
                      ? const Center(
                          child: Text(
                            'Nenhum subcliente cadastrado.',
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : ListView.separated(
                          itemCount: list.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1, color: Colors.white12),
                          itemBuilder: (context, i) {
                            final s = list[i];
                            return ListTile(
                              title: Text(
                                s.nome,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: s.cnpj.isNotEmpty
                                  ? Text(
                                      s.cnpj,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    )
                                  : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.white54,
                                    ),
                                    onPressed: () =>
                                        _modalSubcliente(existente: s),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          backgroundColor: const Color(
                                            0xFF020617,
                                          ),
                                          title: const Text(
                                            'Excluir subcliente?',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          content: Text(
                                            'Remover "${s.nome}"?',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, false),
                                              child: const Text('Cancelar'),
                                            ),
                                            FilledButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, true),
                                              child: const Text('Excluir'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm != true || !mounted) return;
                                      try {
                                        await widget.service.excluirSubcliente(
                                          widget.cliente.id,
                                          s.id,
                                        );
                                        _reload();
                                        await widget.onListaClienteChanged();
                                      } catch (e) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text('Erro: $e')),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar', style: TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }
}
