import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/proposta.dart';
import '../models/proposta_chat_message.dart';
import '../models/proposta_versao.dart';
import '../services/api_client.dart';
import '../services/propostas_service.dart';
import '../widgets/conversys_app_bar.dart';
import 'notificacoes_screen.dart';

class PropostaDetalheScreen extends StatefulWidget {
  final ApiClient apiClient;
  final int propostaId;

  const PropostaDetalheScreen({
    super.key,
    required this.apiClient,
    required this.propostaId,
  });

  @override
  State<PropostaDetalheScreen> createState() => _PropostaDetalheScreenState();
}

class _PropostaDetalheScreenState extends State<PropostaDetalheScreen> {
  late final PropostasService _service;

  PropostaDetalhe? _detalhe;
  List<PropostaChatMessage> _chat = const [];
  List<PropostaVersao> _versoes = const [];

  bool _loading = true;
  String? _error;
  bool _salvando = false;
  bool _gerandoVersao = false;
  bool _uploadingAnexo = false;

  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _validadeController = TextEditingController();

  final _chatController = TextEditingController();
  bool _enviandoMsg = false;

  @override
  void initState() {
    super.initState();
    _service = PropostasService(widget.apiClient);
    _carregarTudo();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _validadeController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _carregarTudo() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detalhe = await _service.obterDetalhe(widget.propostaId);
      final chat = await _service.listarChat(widget.propostaId);
      final versoes = await _service.listarVersoes(widget.propostaId);

      if (!mounted) return;
      setState(() {
        _detalhe = detalhe;
        _chat = chat;
        _versoes = versoes;
        _tituloController.text = detalhe.titulo;
        _descricaoController.text = detalhe.descricao;
        _validadeController.text = detalhe.dataValidade ?? '';
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

  String _buildMediaUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final base = ApiClient.baseUrl;
    if (path.startsWith('/')) {
      return '$base$path';
    }
    return '$base/$path';
  }

  Future<void> _abrirArquivo(String? path) async {
    final url = _buildMediaUrl(path);
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o arquivo.')),
      );
    }
  }

  String _arquivoNome(String? path) {
    if (path == null || path.isEmpty) return 'Arquivo';
    final parts = path.split('/');
    return parts.isNotEmpty ? parts.last : 'Arquivo';
  }

  Future<void> _salvarDetalhes() async {
    final detalhe = _detalhe;
    if (detalhe == null) return;

    setState(() => _salvando = true);
    try {
      await _service.atualizarProposta(widget.propostaId, {
        'titulo': _tituloController.text.trim(),
        'descricao': _descricaoController.text.trim(),
        'data_validade': _validadeController.text.trim().isEmpty
            ? null
            : _validadeController.text.trim(),
      });
      if (!mounted) return;
      await _carregarTudo();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proposta atualizada com sucesso.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _salvando = false);
    }
  }

  Future<void> _fecharContrato() async {
    setState(() {});
    try {
      await _service.fecharPropostaContrato(widget.propostaId);
      if (!mounted) return;
      await _carregarTudo();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao fechar contrato: $e')),
      );
    }
  }

  Future<void> _rejeitarProposta() async {
    setState(() {});
    try {
      await _service.rejeitarProposta(widget.propostaId);
      if (!mounted) return;
      await _carregarTudo();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao rejeitar proposta: $e')),
      );
    }
  }

  Future<void> _enviarMensagem() async {
    if (_enviandoMsg) return;
    final conteudo = _chatController.text.trim();
    if (conteudo.isEmpty) return;

    setState(() => _enviandoMsg = true);
    try {
      await _service.enviarChat(
        propostaId: widget.propostaId,
        tipo: 'comentario',
        conteudo: conteudo,
      );
      _chatController.clear();
      if (!mounted) return;
      final chat = await _service.listarChat(widget.propostaId);
      setState(() => _chat = chat);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar mensagem: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _enviandoMsg = false);
    }
  }

  Future<void> _adicionarItem() async {
    final detalhe = _detalhe;
    if (detalhe == null) return;

    final servicos = await _service.listarServicos();

    int? servicoId;
    num quantidade = 1;
    String precoUnitario = '';

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Adicionar item'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      value: servicoId,
                      decoration: const InputDecoration(
                        labelText: 'Serviço',
                        border: OutlineInputBorder(),
                      ),
                      items: servicos
                          .map(
                            (s) => DropdownMenuItem<int>(
                              value: s.id,
                              child: Text('${s.nome} (${s.precoBase})'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        final chosen = servicos.firstWhere((x) => x.id == v);
                        setStateDialog(() {
                          servicoId = v;
                          precoUnitario = chosen.precoBase;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantidade',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) {
                        quantidade = num.tryParse(v) ?? 1;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Preço unitário',
                        border: OutlineInputBorder(),
                      ),
                      controller: TextEditingController(text: precoUnitario),
                      onChanged: (v) => precoUnitario = v,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (servicoId == null) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Selecione um serviço.')),
                      );
                      return;
                    }
                    final q = quantidade <= 0 ? 1 : quantidade;
                    final preco = precoUnitario.trim().isEmpty ? '0' : precoUnitario.trim();
                    Navigator.of(ctx).pop();
                    try {
                      await _service.criarItem(
                        propostaId: widget.propostaId,
                        servicoId: servicoId!,
                        quantidade: q,
                        precoUnitario: preco,
                      );
                      if (!mounted) return;
                      await _carregarTudo();
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erro ao adicionar item: $e')),
                      );
                    }
                  },
                  child: const Text('Adicionar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _adicionarProduto() async {
    String nome = '';
    num quantidade = 1;
    String valorUnitario = '';

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Adicionar produto'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Nome',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => nome = v,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantidade',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => quantidade = num.tryParse(v) ?? 1,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Valor unitário',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => valorUnitario = v,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    final n = nome.trim();
                    if (n.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Informe o nome do produto.')),
                      );
                      return;
                    }
                    final vu = valorUnitario.trim().isEmpty ? '0' : valorUnitario.trim();
                    Navigator.of(ctx).pop();
                    try {
                      await _service.criarProduto(
                        propostaId: widget.propostaId,
                        nome: n,
                        quantidade: quantidade <= 0 ? 1 : quantidade,
                        valorUnitario: vu,
                      );
                      if (!mounted) return;
                      await _carregarTudo();
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erro ao adicionar produto: $e')),
                      );
                    }
                  },
                  child: const Text('Adicionar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _gerarVersao() async {
    if (_gerandoVersao) return;
    setState(() => _gerandoVersao = true);
    try {
      await _service.gerarVersao(widget.propostaId);
      if (!mounted) return;
      await _carregarTudo();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar versão: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _gerandoVersao = false);
    }
  }

  Future<void> _uploadAnexo() async {
    if (_uploadingAnexo) return;
    setState(() => _uploadingAnexo = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );
      final file = result?.files.firstOrNull;
      if (file == null) return;

      await _service.uploadAnexo(
        propostaId: widget.propostaId,
        arquivo: file,
      );
      if (!mounted) return;
      await _carregarTudo();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar anexo: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _uploadingAnexo = false);
    }
  }

  Future<void> _excluirAnexo(int anexoId) async {
    try {
      await _service.excluirAnexo(anexoId);
      if (!mounted) return;
      await _carregarTudo();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir anexo: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF020617);
    const cardColor = Color(0xFF0B1220);
    const cardBorder = Color(0xFF1E293B);

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: conversysAppBar(
          'Proposta #${widget.propostaId}',
          onNotificationsTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => NotificacoesScreen(apiClient: widget.apiClient),
              ),
            );
          },
        ),
        backgroundColor: background,
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Text(
                      'Erro ao carregar proposta: $_error',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  )
                : _detalhe == null
                    ? const Center(child: Text('Proposta não encontrada.'))
                    : Column(
                        children: [
                          TabBar(
                            isScrollable: true,
                            tabs: const [
                              Tab(text: 'Detalhes'),
                              Tab(text: 'Chat'),
                              Tab(text: 'Itens'),
                              Tab(text: 'Produtos'),
                              Tab(text: 'Versões'),
                              Tab(text: 'Anexos'),
                            ],
                          ),
                          Expanded(
                            child: TabBarView(
                              children: [
                                // Detalhes
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: ListView(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: cardColor,
                                          border: Border.all(color: cardBorder),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _detalhe!.titulo,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 18,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Status: ${_detalhe!.status} • Valor: ${_detalhe!.valorTotal}',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            TextField(
                                              controller: _tituloController,
                                              style: const TextStyle(color: Colors.white),
                                              decoration: const InputDecoration(
                                                labelText: 'Título',
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            TextField(
                                              controller: _descricaoController,
                                              style: const TextStyle(color: Colors.white),
                                              decoration:
                                                  const InputDecoration(
                                                labelText: 'Descrição',
                                                border: OutlineInputBorder(),
                                              ),
                                              minLines: 3,
                                              maxLines: 5,
                                            ),
                                            const SizedBox(height: 12),
                                            TextField(
                                              controller: _validadeController,
                                              style: const TextStyle(color: Colors.white),
                                              decoration:
                                                  const InputDecoration(
                                                labelText: 'Validade (YYYY-MM-DD)',
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: FilledButton.icon(
                                                    onPressed: _salvando ? null : () => _salvarDetalhes(),
                                                    icon: _salvando
                                                        ? const SizedBox(
                                                            width: 16,
                                                            height: 16,
                                                            child: CircularProgressIndicator(strokeWidth: 2),
                                                          )
                                                        : const Icon(Icons.save_outlined),
                                                    label: const Text('Salvar'),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: OutlinedButton.icon(
                                                    onPressed: () => _fecharContrato(),
                                                    icon: const Icon(Icons.check_circle_outline),
                                                    label: const Text('Fechar contrato'),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: OutlinedButton.icon(
                                                    onPressed: () => _rejeitarProposta(),
                                                    icon: const Icon(Icons.cancel_outlined),
                                                    label: const Text('Rejeitar'),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Chat
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: ListView.separated(
                                          itemCount: _chat.length,
                                          separatorBuilder: (_, __) =>
                                              const SizedBox(height: 8),
                                          itemBuilder: (context, index) {
                                            final m = _chat[index];
                                            final isBot = m.autorTipo != 'interno';
                                            return Align(
                                              alignment: isBot
                                                  ? Alignment.centerLeft
                                                  : Alignment.centerRight,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: isBot
                                                      ? Colors.white.withOpacity(0.06)
                                                      : Theme.of(context)
                                                          .colorScheme
                                                          .primary
                                                          .withOpacity(0.35),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  border: Border.all(
                                                    color: Colors.white.withOpacity(0.12),
                                                  ),
                                                ),
                                                padding:
                                                    const EdgeInsets.all(12),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      m.autorNome,
                                                      style: const TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      m.conteudo,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      m.criadoEm,
                                                      style: const TextStyle(
                                                        color: Colors.white54,
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _chatController,
                                              style: const TextStyle(color: Colors.white),
                                              decoration:
                                                  const InputDecoration(
                                                labelText: 'Mensagem',
                                                border: OutlineInputBorder(),
                                              ),
                                              maxLines: 3,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          FilledButton.icon(
                                            onPressed: _enviandoMsg ? null : () => _enviarMensagem(),
                                            icon: _enviandoMsg
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
                                      const SizedBox(height: 8),
                                    ],
                                  ),
                                ),

                                // Itens
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Itens (${(_detalhe!.itens ?? const []).length})',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const Spacer(),
                                          IconButton(
                                            onPressed: _adicionarItem,
                                            icon: const Icon(Icons.add_circle_outline),
                                            tooltip: 'Adicionar item',
                                            color: Colors.blue[200],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Expanded(
                                        child: ListView.separated(
                                          itemCount:
                                              _detalhe!.itens?.length ?? 0,
                                          separatorBuilder: (_, __) =>
                                              const SizedBox(height: 10),
                                          itemBuilder: (context, index) {
                                            final item = _detalhe!.itens![index];
                                            return Container(
                                              decoration: BoxDecoration(
                                                color: cardColor,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                    color: cardBorder),
                                              ),
                                              padding: const EdgeInsets.all(14),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.servicoNome ??
                                                        'Serviço #${item.servico}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    'Qtd: ${item.quantidade} • Unit: ${item.precoUnitario}',
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      if ((_detalhe!.itens ?? const []).isEmpty)
                                        const Text(
                                          'Nenhum item ainda. Toque em + para adicionar.',
                                          style: TextStyle(color: Colors.white54),
                                        ),
                                    ],
                                  ),
                                ),

                                // Produtos
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Produtos (${(_detalhe!.produtos ?? const []).length})',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const Spacer(),
                                          IconButton(
                                            onPressed: _adicionarProduto,
                                            icon: const Icon(Icons.add_circle_outline),
                                            tooltip: 'Adicionar produto',
                                            color: Colors.blue[200],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Expanded(
                                        child: ListView.separated(
                                          itemCount:
                                              _detalhe!.produtos?.length ?? 0,
                                          separatorBuilder: (_, __) =>
                                              const SizedBox(height: 10),
                                          itemBuilder: (context, index) {
                                            final produto =
                                                _detalhe!.produtos![index];
                                            return Container(
                                              decoration: BoxDecoration(
                                                color: cardColor,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                    color: cardBorder),
                                              ),
                                              padding: const EdgeInsets.all(14),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    produto.nome,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    'Qtd: ${produto.quantidade} • Unit: ${produto.valorUnitario}',
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      if ((_detalhe!.produtos ?? const []).isEmpty)
                                        const Text(
                                          'Nenhum produto ainda. Toque em + para adicionar.',
                                          style: TextStyle(color: Colors.white54),
                                        ),
                                    ],
                                  ),
                                ),

                                // Versões
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Versões (${_versoes.length})',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const Spacer(),
                                          FilledButton.icon(
                                            onPressed: _gerandoVersao ? null : () => _gerarVersao(),
                                            icon: _gerandoVersao
                                                ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child: CircularProgressIndicator(strokeWidth: 2),
                                                  )
                                                : const Icon(Icons.refresh),
                                            label: Text(_gerandoVersao ? 'Gerando...' : 'Gerar versão'),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Expanded(
                                        child: ListView.separated(
                                          itemCount: _versoes.length,
                                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                                          itemBuilder: (context, index) {
                                            final v = _versoes[index];
                                            return Container(
                                              decoration: BoxDecoration(
                                                color: cardColor,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                    color: cardBorder),
                                              ),
                                              padding: const EdgeInsets.all(14),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Versão ${v.versao}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    'Criado em: ${v.criadoEm}',
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Anexos
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Anexos (${(_detalhe!.anexos ?? const []).length})',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const Spacer(),
                                          IconButton(
                                            onPressed: _uploadingAnexo ? null : () => _uploadAnexo(),
                                            icon: const Icon(Icons.upload_file_outlined),
                                            tooltip: 'Adicionar anexo',
                                            color: Colors.blue[200],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Expanded(
                                        child: ListView.separated(
                                          itemCount:
                                              _detalhe!.anexos?.length ?? 0,
                                          separatorBuilder: (_, __) =>
                                              const SizedBox(height: 10),
                                          itemBuilder: (context, index) {
                                            final a = _detalhe!.anexos![index];
                                            final nome = _arquivoNome(a.arquivo);
                                            return Container(
                                              decoration: BoxDecoration(
                                                color: cardColor,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: cardBorder,
                                                ),
                                              ),
                                              padding: const EdgeInsets.all(14),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          nome,
                                                          maxLines: 2,
                                                          overflow:
                                                              TextOverflow.ellipsis,
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontWeight: FontWeight.w700,
                                                            fontSize: 13,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 6),
                                                        Text(
                                                          'Criado em: ${a.criadoEm}',
                                                          style: const TextStyle(
                                                            color: Colors.white70,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  IconButton(
                                                    onPressed: () => _abrirArquivo(a.arquivo),
                                                    icon: const Icon(Icons.open_in_new),
                                                    tooltip: 'Abrir',
                                                    color: Colors.blue[200],
                                                  ),
                                                  IconButton(
                                                    onPressed: () => _excluirAnexo(a.id),
                                                    icon: const Icon(Icons.delete_outline),
                                                    tooltip: 'Excluir',
                                                    color: Colors.red[300],
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      if ((_detalhe!.anexos ?? const []).isEmpty)
                                        const Text(
                                          'Nenhum anexo ainda.',
                                          style: TextStyle(color: Colors.white54),
                                        ),
                                    ],
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

extension _FirstOrNullExt<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

