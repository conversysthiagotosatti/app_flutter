import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/marketplace.dart';
import '../services/api_client.dart';
import '../services/marketplace_service.dart';
import '../widgets/conversys_app_bar.dart';
import 'notificacoes_screen.dart';

class _ClienteOption {
  final int id;
  final String nome;

  _ClienteOption({required this.id, required this.nome});
}

/// Marketplace (portal: `MarketplacePage` + `MarketplaceClienteCreditoPage`).
class MarketplaceModuleScreen extends StatefulWidget {
  final ApiClient apiClient;

  const MarketplaceModuleScreen({super.key, required this.apiClient});

  @override
  State<MarketplaceModuleScreen> createState() => _MarketplaceModuleScreenState();
}

class _MarketplaceModuleScreenState extends State<MarketplaceModuleScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final MarketplaceService _svc;

  List<_ClienteOption> _clientes = [];
  int? _clienteId;
  bool _loadingClients = true;
  String? _clientErr;

  List<MarketplaceGrupo> _grupos = [];
  int? _grupoSelecionadoId;
  List<MarketplaceProduto> _produtos = [];
  bool _loadingGrupos = false;
  bool _loadingProdutos = false;
  String? _catalogErr;
  int? _acquiringProductId;

  MarketplaceSaldoCliente? _saldo;
  List<MarketplaceCestaItem> _cesta = [];
  List<MarketplaceMovimentacaoFinanceira> _movs = [];
  bool _loadingCredits = false;
  String? _creditsErr;
  final _creditoValor = TextEditingController();
  bool _submittingCredito = false;

  void _onTabChanged() {
    if (_tabs.indexIsChanging) return;
    if (_tabs.index != 1) return;
    final c = _clienteId;
    if (c != null) _reloadCredits(c);
  }

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(_onTabChanged);
    _svc = MarketplaceService(widget.apiClient);
    _bootstrap();
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
    _creditoValor.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loadingClients = true;
      _clientErr = null;
    });
    try {
      final r = await widget.apiClient.get('/api/auth/me/clients/');
      if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
      final decoded = jsonDecode(r.body);
      if (decoded is! List) throw Exception('Lista inválida');
      final opts = <_ClienteOption>[];
      for (final e in decoded) {
        if (e is! Map<String, dynamic>) continue;
        final id = e['cliente_id'];
        final nome = e['cliente_nome']?.toString() ?? '';
        int? cid;
        if (id is int) {
          cid = id;
        } else if (id is num) {
          cid = id.toInt();
        }
        if (cid != null && nome.isNotEmpty) {
          opts.add(_ClienteOption(id: cid, nome: nome));
        }
      }
      final saved = await widget.apiClient.loadAuthClienteId();
      int? pick = saved;
      if (pick != null && !opts.any((o) => o.id == pick)) pick = null;
      pick ??= opts.isNotEmpty ? opts.first.id : null;
      if (!mounted) return;
      setState(() {
        _clientes = opts;
        _clienteId = pick;
        _loadingClients = false;
      });
      await _reloadGrupos();
      if (pick != null) await _reloadCredits(pick);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingClients = false;
        _clientErr = e.toString();
      });
    }
  }

  Future<void> _reloadGrupos() async {
    setState(() {
      _loadingGrupos = true;
      _catalogErr = null;
    });
    try {
      final list = await _svc.fetchGruposCatalogo();
      if (!mounted) return;
      setState(() {
        _grupos = list;
        _loadingGrupos = false;
        if (_grupoSelecionadoId != null &&
            !list.any((g) => g.id == _grupoSelecionadoId)) {
          _grupoSelecionadoId = null;
          _produtos = [];
        }
      });
      if (_grupoSelecionadoId != null) {
        await _reloadProdutos(_grupoSelecionadoId!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingGrupos = false;
        _catalogErr = e.toString();
      });
    }
  }

  Future<void> _reloadProdutos(int grupoId) async {
    setState(() => _loadingProdutos = true);
    try {
      final list = await _svc.fetchProdutosPorGrupo(grupoId);
      if (!mounted) return;
      setState(() {
        _produtos = list;
        _loadingProdutos = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingProdutos = false;
        _catalogErr = e.toString();
      });
    }
  }

  Future<void> _reloadCredits(int cid) async {
    setState(() {
      _loadingCredits = true;
      _creditsErr = null;
    });
    try {
      final saldo = await _svc.fetchSaldoCliente(cid);
      final cesta = await _svc.fetchCestaItens(cid);
      final movs = await _svc.fetchMovimentacoes(cid);
      if (!mounted) return;
      setState(() {
        _saldo = saldo;
        _cesta = cesta;
        _movs = movs;
        _loadingCredits = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingCredits = false;
        _creditsErr = e.toString();
      });
    }
  }

  String _brl(String? value) {
    final n = double.tryParse(value ?? '');
    if (n == null) return '—';
    return NumberFormat.currency(locale: 'pt_BR', symbol: r'R$').format(n);
  }

  String _fmtDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return DateFormat.yMMMd().format(d.toLocal());
  }

  String _fmtDateTime(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return DateFormat.yMd().add_Hm().format(d.toLocal());
  }

  String _periodo(AppLocalizations l10n, String? codigo) {
    switch (codigo) {
      case 'DIARIO':
        return l10n.marketplacePeriodoDIARIO;
      case 'MENSAL':
        return l10n.marketplacePeriodoMENSAL;
      case 'ANUAL':
        return l10n.marketplacePeriodoANUAL;
      case 'POR_SEGUNDO':
        return l10n.marketplacePeriodoPOR_SEGUNDO;
      case 'POR_HORA':
        return l10n.marketplacePeriodoPOR_HORA;
      default:
        return codigo ?? '—';
    }
  }

  Map<int, List<MarketplaceProduto>> _produtosPorSubgrupo() {
    final map = <int, List<MarketplaceProduto>>{};
    for (final p in _produtos) {
      map.putIfAbsent(p.subgrupo, () => []).add(p);
    }
    for (final e in map.entries) {
      e.value.sort(
        (a, b) => a.descricaoCurta.toLowerCase().compareTo(
              b.descricaoCurta.toLowerCase(),
            ),
      );
    }
    return map;
  }

  Future<void> _adquirir(MarketplaceProduto p, AppLocalizations l10n) async {
    final cid = _clienteId;
    if (cid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.marketplaceAcquireNeedClient)),
      );
      return;
    }
    if (!p.ativo) return;
    setState(() => _acquiringProductId = p.id);
    try {
      final item = await _svc.adquirirProduto(
        clienteId: cid,
        catalogoProdutoId: p.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${l10n.marketplaceAcquireSuccessIntro} '
            '${l10n.marketplaceAcquireVigenciaStart}: ${_fmtDate(item.vigenciaInicio)}. '
            '${l10n.marketplaceAcquireVigenciaEnd}: ${_fmtDate(item.vigenciaFim)}.',
          ),
        ),
      );
      await _reloadCredits(cid);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _acquiringProductId = null);
    }
  }

  Future<void> _submitCredito(AppLocalizations l10n) async {
    final cid = _clienteId;
    if (cid == null) return;
    final raw = _creditoValor.text.trim().replaceAll(',', '.');
    final n = double.tryParse(raw);
    if (n == null || n <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.marketplaceCreditsInvalidAmount)),
      );
      return;
    }
    final valor = n.toStringAsFixed(2);
    setState(() => _submittingCredito = true);
    try {
      await _svc.adicionarCredito(
        clienteId: cid,
        valor: valor,
        descricao: '',
      );
      _creditoValor.clear();
      await _reloadCredits(cid);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submittingCredito = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const bg = Color(0xFF020617);

    return Scaffold(
      backgroundColor: bg,
      appBar: conversysAppBar(
        context,
        l10n.marketplaceModuleTitle,
        userAccountMenuApiClient: widget.apiClient,
        onNotificationsTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NotificacoesScreen(apiClient: widget.apiClient),
            ),
          );
        },
      ),
      body: _loadingClients
          ? const Center(child: CircularProgressIndicator())
          : _clientes.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _clientErr ?? l10n.marketplaceCreditsNoClient,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: _clienteId,
                              decoration: InputDecoration(
                                labelText: l10n.expenseSelectClient,
                                labelStyle: const TextStyle(color: Colors.white54),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              dropdownColor: const Color(0xFF0B1220),
                              style: const TextStyle(color: Colors.white),
                              items: _clientes
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c.id,
                                      child: Text(
                                        c.nome,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (id) async {
                                if (id == null) return;
                                await widget.apiClient.saveAuthClienteContext(
                                  clienteId: id,
                                  clienteNome: _clientes
                                      .firstWhere((e) => e.id == id)
                                      .nome,
                                );
                                setState(() => _clienteId = id);
                                await _reloadCredits(id);
                              },
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              await _reloadGrupos();
                              final cid = _clienteId;
                              if (cid != null) await _reloadCredits(cid);
                            },
                            icon: const Icon(Icons.refresh, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    TabBar(
                      controller: _tabs,
                      labelColor: Colors.tealAccent,
                      unselectedLabelColor: Colors.white54,
                      tabs: [
                        Tab(text: l10n.marketplaceTabCatalog),
                        Tab(text: l10n.marketplaceTabCredits),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabs,
                        children: [
                          _buildCatalogTab(l10n),
                          _buildCreditsTab(l10n),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildCatalogTab(AppLocalizations l10n) {
    if (_loadingGrupos) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_catalogErr != null && _grupos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.marketplaceErrorTitle,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _catalogErr!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: _reloadGrupos,
                child: Text(l10n.marketplaceRetry),
              ),
            ],
          ),
        ),
      );
    }

    if (_grupoSelecionadoId == null) {
      if (_grupos.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.marketplaceEmptyTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.marketplaceEmpty,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
        );
      }
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.marketplaceSubtitle,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ..._grupos.map((g) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: const Color(0xFF0B1220),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    setState(() => _grupoSelecionadoId = g.id);
                    await _reloadProdutos(g.id);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                g.nome,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Text(
                              g.ativo
                                  ? l10n.marketplaceBadgeActive
                                  : l10n.marketplaceInactive,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: g.ativo
                                    ? Colors.greenAccent
                                    : Colors.white38,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          g.descricao.isEmpty
                              ? l10n.marketplaceNoDescription
                              : g.descricao,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${g.subgrupos.length} ${l10n.marketplaceSubgroupsCount}',
                          style: const TextStyle(
                            color: Colors.tealAccent,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      );
    }

    final gid = _grupoSelecionadoId;
    if (gid != null && !_grupos.any((g) => g.id == gid)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _grupoSelecionadoId = null;
          _produtos = [];
        });
      });
      return const Center(child: CircularProgressIndicator());
    }
    final grupo = _grupos.firstWhere((g) => g.id == _grupoSelecionadoId);
    final subs = [...grupo.subgrupos]..sort(
        (a, b) => a.ordem != b.ordem
            ? a.ordem.compareTo(b.ordem)
            : a.nome.compareTo(b.nome),
      );
    final porSub = _produtosPorSubgrupo();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _grupoSelecionadoId = null;
                  _produtos = [];
                });
              },
              icon: const Icon(Icons.chevron_left, color: Colors.white70),
              label: Text(
                l10n.marketplaceBackGroups,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                grupo.nome,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (_clienteId == null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l10n.marketplaceAcquireNeedClient,
              style: const TextStyle(color: Colors.amber, fontSize: 12),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          l10n.marketplaceGroupDetailIntro,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 16),
        if (_loadingProdutos)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
        else if (subs.isEmpty)
          Text(
            l10n.marketplaceEmptySubgroups,
            style: const TextStyle(color: Colors.white54),
          )
        else
          ...subs.map((s) {
            final produtos = porSub[s.id] ?? [];
            return Card(
              color: const Color(0xFF0B1220),
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.nome,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          s.ativo
                              ? l10n.marketplaceBadgeActive
                              : l10n.marketplaceInactive,
                          style: TextStyle(
                            fontSize: 10,
                            color: s.ativo
                                ? Colors.greenAccent
                                : Colors.white38,
                          ),
                        ),
                      ],
                    ),
                    if (s.descricao.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          s.descricao,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    if (produtos.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          l10n.marketplaceEmptyProducts,
                          style: const TextStyle(color: Colors.white38),
                        ),
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            const Color(0xFF0F172A),
                          ),
                          dataTextStyle: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          columns: [
                            DataColumn(label: Text(l10n.marketplaceTableColProduct)),
                            DataColumn(label: Text(l10n.marketplaceTableColDescription)),
                            DataColumn(label: Text(l10n.marketplaceTableColValue)),
                            DataColumn(label: Text(l10n.marketplaceTableColPeriod)),
                            DataColumn(label: Text(l10n.marketplaceTableColStatus)),
                            DataColumn(label: Text(l10n.marketplaceTableColAction)),
                          ],
                          rows: produtos.map((p) {
                            final temPreco = p.precoValorAtual != null &&
                                p.precoValorAtual!.isNotEmpty;
                            final canAcquire = p.ativo && _clienteId != null;
                            final acquiring = _acquiringProductId == p.id;
                            return DataRow(
                              cells: [
                                DataCell(Text(p.descricaoCurta)),
                                DataCell(
                                  SizedBox(
                                    width: 160,
                                    child: Text(
                                      p.descricaoLonga.trim().isEmpty
                                          ? '—'
                                          : p.descricaoLonga,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    temPreco
                                        ? _brl(p.precoValorAtual)
                                        : '—',
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    temPreco
                                        ? _periodo(l10n, p.precoPeriodo)
                                        : '—',
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    p.ativo
                                        ? l10n.marketplaceBadgeActive
                                        : l10n.marketplaceInactive,
                                  ),
                                ),
                                DataCell(
                                  FilledButton(
                                    onPressed: (!canAcquire || acquiring)
                                        ? null
                                        : () => _adquirir(p, l10n),
                                    style: FilledButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                    ),
                                    child: acquiring
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            l10n.marketplaceAcquireButton,
                                            style:
                                                const TextStyle(fontSize: 11),
                                          ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildCreditsTab(AppLocalizations l10n) {
    final cid = _clienteId;
    if (cid == null) {
      return Center(
        child: Text(
          l10n.marketplaceCreditsNoClient,
          style: const TextStyle(color: Colors.white54),
        ),
      );
    }
    if (_loadingCredits) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_creditsErr != null && _saldo == null && _cesta.isEmpty && _movs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.marketplaceCreditsLoadError,
                style: const TextStyle(color: Colors.redAccent),
              ),
              const SizedBox(height: 8),
              Text(
                _creditsErr!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => _reloadCredits(cid),
                child: Text(l10n.marketplaceRetry),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.marketplaceCreditsTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        _section(
          l10n.marketplaceCreditsBalance,
          Text(
            _brl(_saldo?.creditoDisponivel ?? '0'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _section(
          l10n.marketplaceCreditsBasket,
          _cesta.isEmpty
              ? Text(
                  l10n.marketplaceCreditsBasketEmpty,
                  style: const TextStyle(color: Colors.white54),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      DataColumn(label: Text(l10n.marketplaceCreditsBasketColProduct)),
                      DataColumn(label: Text(l10n.marketplaceCreditsBasketColStart)),
                      DataColumn(label: Text(l10n.marketplaceCreditsBasketColEnd)),
                      DataColumn(label: Text(l10n.marketplaceCreditsBasketColAcquired)),
                    ],
                    rows: _cesta.map((row) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              row.produtoDescricaoCurta?.trim().isNotEmpty == true
                                  ? row.produtoDescricaoCurta!
                                  : '— (#${row.catalogoProduto})',
                            ),
                          ),
                          DataCell(Text(_fmtDate(row.vigenciaInicio))),
                          DataCell(Text(_fmtDate(row.vigenciaFim))),
                          DataCell(Text(_fmtDateTime(row.criadoEm))),
                        ],
                      );
                    }).toList(),
                  ),
                ),
        ),
        const SizedBox(height: 16),
        _section(
          l10n.marketplaceCreditsAddSection,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _creditoValor,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: l10n.marketplaceCreditsAmount,
                  labelStyle: const TextStyle(color: Colors.white54),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _submittingCredito
                    ? null
                    : () => _submitCredito(l10n),
                child: Text(
                  _submittingCredito
                      ? l10n.marketplaceCreditsSubmitting
                      : l10n.marketplaceCreditsSubmit,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.marketplaceCreditsHistory,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _movs.isEmpty
            ? Text(
                l10n.marketplaceCreditsEmptyHistory,
                style: const TextStyle(color: Colors.white54),
              )
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text(l10n.marketplaceCreditsTableDate)),
                    DataColumn(label: Text(l10n.marketplaceCreditsTableType)),
                    DataColumn(label: Text(l10n.marketplaceCreditsTableAmount)),
                    DataColumn(label: Text(l10n.marketplaceCreditsTableAfter)),
                    DataColumn(label: Text(l10n.marketplaceCreditsTableDesc)),
                  ],
                  rows: _movs.map((m) {
                    return DataRow(
                      cells: [
                        DataCell(Text(_fmtDateTime(m.criadoEm))),
                        DataCell(
                          Text(
                            m.tipo == 'ENTRADA'
                                ? l10n.marketplaceCreditsTypeIn
                                : l10n.marketplaceCreditsTypeOut,
                            style: TextStyle(
                              color: m.tipo == 'ENTRADA'
                                  ? Colors.greenAccent
                                  : Colors.orangeAccent,
                            ),
                          ),
                        ),
                        DataCell(Text(_brl(m.valor))),
                        DataCell(Text(_brl(m.saldoAposMovimento))),
                        DataCell(
                          SizedBox(
                            width: 140,
                            child: Text(
                              m.descricao.isEmpty ? '—' : m.descricao,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
      ],
    );
  }

  Widget _section(String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
