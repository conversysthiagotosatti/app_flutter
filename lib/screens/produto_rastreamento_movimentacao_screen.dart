import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/local_estoque.dart';
import '../models/motivo_movimentacao.dart';
import '../models/movimentacao_rastreamento.dart';
import '../models/rastreamento_serial.dart';
import '../services/api_client.dart';
import '../services/estoque_service.dart';
import 'produto_serial_scan_screen.dart';

/// Consulta por serial/QR, catálogo, histórico e registro de movimentação (API estoque).
class ProdutoRastreamentoMovimentacaoScreen extends StatefulWidget {
  final ApiClient apiClient;

  const ProdutoRastreamentoMovimentacaoScreen({
    super.key,
    required this.apiClient,
  });

  @override
  State<ProdutoRastreamentoMovimentacaoScreen> createState() =>
      _ProdutoRastreamentoMovimentacaoScreenState();
}

class _ProdutoRastreamentoMovimentacaoScreenState
    extends State<ProdutoRastreamentoMovimentacaoScreen> {
  late final EstoqueService _service;
  final _serialCtrl = TextEditingController();
  final _localDestinoCtrl = TextEditingController();
  final _detalhesCtrl = TextEditingController();
  final _catalogSearchCtrl = TextEditingController();

  bool _loadingBusca = false;
  bool _loadingCatalogo = false;
  bool _loadingHistorico = false;
  bool _loadingMotivos = true;
  bool _salvandoMov = false;
  String? _error;

  RastreamentoSerialInfo? _produto;
  List<MovimentacaoRastreamentoItem> _historico = [];
  List<MotivoMovimentacaoItem> _motivos = [];
  List<LocalEstoqueItem> _locais = [];
  List<RastreamentoSerialInfo> _catalogo = [];

  int? _motivoId;

  bool get _canQr {
    if (kIsWeb) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return true;
      default:
        return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _service = EstoqueService(widget.apiClient);
    _carregarMotivos();
  }

  @override
  void dispose() {
    _serialCtrl.dispose();
    _localDestinoCtrl.dispose();
    _detalhesCtrl.dispose();
    _catalogSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarMotivos() async {
    setState(() {
      _loadingMotivos = true;
      _error = null;
    });
    try {
      final m = await _service.listarMotivos();
      if (!mounted) return;
      setState(() {
        _motivos = m;
        _motivoId = m.length == 1 ? m.first.id : _motivoId;
      });
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _error = AppLocalizations.of(context)!.motivesLoadError('$e'),
      );
    } finally {
      if (mounted) setState(() => _loadingMotivos = false);
    }
  }

  Future<void> _definirProduto(RastreamentoSerialInfo p) async {
    setState(() {
      _produto = p;
      _serialCtrl.text = p.numeroSerial;
      _error = null;
      _localDestinoCtrl.clear();
      _motivoId = _motivos.length == 1 ? _motivos.first.id : null;
    });
    await _refreshHistoricoELocais();
  }

  Future<void> _refreshHistoricoELocais() async {
    final p = _produto;
    if (p == null) return;
    setState(() {
      _loadingHistorico = true;
    });
    try {
      final hist = await _service.listarMovimentacoes(p.id);
      final loc = await _service.listarLocais(clienteId: p.clienteId);
      if (!mounted) return;
      setState(() {
        _historico = hist;
        _locais = loc;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loadingHistorico = false);
    }
  }

  Future<void> _buscarSerial([String? raw]) async {
    final serial = serialFromQrOrText(raw ?? _serialCtrl.text);
    if (serial.isEmpty) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context)!.serialRequired;
        _produto = null;
      });
      return;
    }
    _serialCtrl.text = serial;
    setState(() {
      _loadingBusca = true;
      _error = null;
    });
    try {
      final p = await _service.buscarPorSerial(serial);
      if (!mounted) return;
      await _definirProduto(p);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _produto = null;
        _historico = [];
        _locais = [];
      });
    } finally {
      if (mounted) setState(() => _loadingBusca = false);
    }
  }

  Future<void> _abrirQr() async {
    final raw = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ProdutoSerialScanScreen()),
    );
    if (raw == null || raw.isEmpty || !mounted) return;
    await _buscarSerial(raw);
  }

  Future<void> _carregarCatalogo() async {
    setState(() {
      _loadingCatalogo = true;
      _error = null;
    });
    try {
      final list = await _service.listarCatalogo(
        search: _catalogSearchCtrl.text,
        limit: 80,
      );
      if (!mounted) return;
      setState(() => _catalogo = list);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loadingCatalogo = false);
    }
  }

  Future<void> _registrarMovimentacao() async {
    final p = _produto;
    if (p == null) return;
    final mid = _motivoId;
    final l10n = AppLocalizations.of(context)!;
    if (mid == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.selectMotive)));
      return;
    }
    final dest = _localDestinoCtrl.text.trim();
    if (dest.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.destinationRequired)));
      return;
    }
    setState(() => _salvandoMov = true);
    try {
      final atualizado = await _service.movimentar(
        rastreamentoId: p.id,
        motivoId: mid,
        localDestino: dest,
        detalhes: _detalhesCtrl.text,
      );
      if (!mounted) return;
      setState(() {
        _produto = atualizado;
        _detalhesCtrl.clear();
      });
      await _refreshHistoricoELocais();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.movementSaved)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _salvandoMov = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const bg = Color(0xFF020617);
    const card = Color(0xFF0B1220);
    const border = Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: Colors.white,
        title: Text(l10n.stockTrackingTitle),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (_produto != null) {
            await _refreshHistoricoELocais();
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.stockTrackingIntro,
                style: TextStyle(color: Colors.blueGrey[200], fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _serialCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: l10n.serialNumber,
                  hintText: l10n.enterSerialHint,
                  labelStyle: const TextStyle(color: Colors.white70),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _buscarSerial(),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _loadingBusca ? null : () => _buscarSerial(),
                      icon: _loadingBusca
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search),
                      label: Text(l10n.search),
                    ),
                  ),
                  if (_canQr) ...[
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: _loadingBusca ? null : _abrirQr,
                      tooltip: l10n.readQrCode,
                      icon: const Icon(Icons.qr_code_scanner),
                    ),
                  ],
                ],
              ),
              if (!_canQr)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.qrOnlyMobile,
                    style: TextStyle(color: Colors.blueGrey[300], fontSize: 12),
                  ),
                ),
              const SizedBox(height: 24),
              _CatalogoCard(
                l10n: l10n,
                cardColor: card,
                borderColor: border,
                controller: _catalogSearchCtrl,
                loading: _loadingCatalogo,
                itens: _catalogo,
                onBuscar: _carregarCatalogo,
                onSelecionar: (p) => _definirProduto(p),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              ],
              if (_loadingMotivos)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (_produto != null) ...[
                const SizedBox(height: 20),
                _ProdutoCard(
                  l10n: l10n,
                  info: _produto!,
                  cardColor: card,
                  borderColor: border,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.movementHistory,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (_loadingHistorico)
                  const Center(child: CircularProgressIndicator())
                else if (_historico.isEmpty)
                  Text(
                    l10n.noMovementsYet,
                    style: TextStyle(color: Colors.blueGrey[300]),
                  )
                else
                  ..._historico.map((m) => _HistoricoTile(l10n: l10n, item: m)),
                const SizedBox(height: 20),
                Text(
                  l10n.newMovement,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (_motivos.isEmpty)
                  Text(
                    l10n.motivesAdminHint,
                    style: TextStyle(color: Colors.amber[200]),
                  )
                else
                  DropdownButtonFormField<int>(
                    initialValue:
                        _motivoId != null &&
                            _motivos.any((m) => m.id == _motivoId)
                        ? _motivoId
                        : null,
                    dropdownColor: card,
                    decoration: InputDecoration(
                      labelText: l10n.motive,
                      labelStyle: const TextStyle(color: Colors.white70),
                      border: const OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                    ),
                    hint: Text(
                      l10n.selectOption,
                      style: const TextStyle(color: Colors.white54),
                    ),
                    items: _motivos
                        .map(
                          (m) => DropdownMenuItem(
                            value: m.id,
                            child: Text(
                              m.nome,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _motivoId = v),
                  ),
                if (_locais.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.registeredLocationsHint,
                    style: TextStyle(color: Colors.blueGrey[300], fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _locais
                        .map(
                          (l) => ActionChip(
                            label: Text(l.nome),
                            onPressed: () {
                              setState(() {
                                _localDestinoCtrl.text = l.nome;
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _localDestinoCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: l10n.destinationLocation,
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _detalhesCtrl,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l10n.observationsOptional,
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: (_salvandoMov || _motivos.isEmpty)
                      ? null
                      : _registrarMovimentacao,
                  icon: _salvandoMov
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.move_to_inbox),
                  label: Text(l10n.registerMovement),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatalogoCard extends StatelessWidget {
  final AppLocalizations l10n;
  final Color cardColor;
  final Color borderColor;
  final TextEditingController controller;
  final bool loading;
  final List<RastreamentoSerialInfo> itens;
  final VoidCallback onBuscar;
  final void Function(RastreamentoSerialInfo) onSelecionar;

  const _CatalogoCard({
    required this.l10n,
    required this.cardColor,
    required this.borderColor,
    required this.controller,
    required this.loading,
    required this.itens,
    required this.onBuscar,
    required this.onSelecionar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.catalogTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: l10n.catalogFilterHint,
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => onBuscar(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: loading ? null : onBuscar,
                icon: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
              ),
            ],
          ),
          if (itens.isNotEmpty) ...[
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: itens.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final p = itens[i];
                  return ListTile(
                    dense: true,
                    title: Text(
                      p.numeroSerial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      [
                        if (p.clienteNome != null) p.clienteNome!,
                        if (p.unidadeEstoque.isNotEmpty) p.unidadeEstoque,
                      ].join(' · '),
                      style: TextStyle(
                        color: Colors.blueGrey[200],
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.white54,
                    ),
                    onTap: () => onSelecionar(p),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProdutoCard extends StatelessWidget {
  final AppLocalizations l10n;
  final RastreamentoSerialInfo info;
  final Color cardColor;
  final Color borderColor;

  const _ProdutoCard({
    required this.l10n,
    required this.info,
    required this.cardColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.selectedProduct,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          _line(l10n.serialLabel, info.numeroSerial),
          if (info.clienteNome != null && info.clienteNome!.isNotEmpty)
            _line(l10n.client, info.clienteNome!),
          if (info.subclienteNome != null && info.subclienteNome!.isNotEmpty)
            _line(l10n.subclient, info.subclienteNome!),
          if (info.unidadeEstoque.isNotEmpty)
            _line(l10n.currentLocation, info.unidadeEstoque),
        ],
      ),
    );
  }

  Widget _line(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              k,
              style: TextStyle(color: Colors.blueGrey[300], fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoricoTile extends StatelessWidget {
  final AppLocalizations l10n;
  final MovimentacaoRastreamentoItem item;

  const _HistoricoTile({required this.l10n, required this.item});

  @override
  Widget build(BuildContext context) {
    final quando = item.criadoEm != null
        ? '${item.criadoEm!.day.toString().padLeft(2, '0')}/${item.criadoEm!.month.toString().padLeft(2, '0')}/${item.criadoEm!.year}'
        : '—';
    return Card(
      color: const Color(0xFF0F172A),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          item.motivoNome,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          [
            quando,
            if (item.localOrigem.isNotEmpty)
              '${l10n.movementFrom} ${item.localOrigem}',
            '→ ${item.localDestino}',
            if (item.detalhes.isNotEmpty) item.detalhes,
            if (item.criadoPorNome != null)
              l10n.movementAuthor(item.criadoPorNome!),
          ].join('\n'),
          style: TextStyle(color: Colors.blueGrey[200], fontSize: 12),
        ),
      ),
    );
  }
}
